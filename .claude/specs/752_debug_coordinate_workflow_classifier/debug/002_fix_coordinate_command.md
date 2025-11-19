# Fix: Coordinate Command State Persistence (P0)

## Executive Summary

**Problem**: After workflow-classifier agent completes, coordinate.md expects CLASSIFICATION_JSON in state but doesn't extract it from Task tool output.

**Solution**: Add bash block immediately after Task invocation to:
1. Extract classification JSON from agent response signal
2. Save to state using append_workflow_state()
3. Verify save successful before proceeding

**Priority**: P0 (Critical - Required for coordinate to work)

**Estimated Time**: 30 minutes

**Dependencies**: Requires Fix 001 (workflow-classifier.md) applied first

---

## Root Cause

Current coordinate.md flow (lines 190-276):

```markdown
## Phase 0.1: Workflow Classification

Task {
  # ... invoke workflow-classifier agent ...
}

USE the Bash tool:

```bash
# Lines 217-276: Load state and expect CLASSIFICATION_JSON to exist
load_workflow_state "$WORKFLOW_ID"

if [ -z "${CLASSIFICATION_JSON:-}" ]; then
  # ERROR: Agent didn't save CLASSIFICATION_JSON
  handle_state_error "CRITICAL: workflow-classifier agent did not save..." 1
fi
```
```

**Problem**: There's a **gap** between Task invocation (line 213) and state loading (line 259). The Task output contains the classification JSON, but coordinate.md never extracts and saves it.

---

## Files to Modify

### File: `/home/benjamin/.config/.claude/commands/coordinate.md`

**Section**: Phase 0.1: Workflow Classification (lines 190-213)

**Change Type**: Insert new bash block between Task invocation and state loading

---

## Step-by-Step Fix Instructions

### Step 1: Backup Current File

```bash
cd /home/benjamin/.config
cp .claude/commands/coordinate.md .claude/commands/coordinate.md.backup
```

**Verification**:
```bash
ls -la .claude/commands/coordinate.md*
# Should show both original and backup
```

---

### Step 2: Locate Insertion Point

**Find this section** (around line 190-213):

```markdown
## Phase 0.1: Workflow Classification

**EXECUTE NOW**: USE the Task tool to invoke workflow-classifier agent:

Task {
  subagent_type: "general-purpose"
  description: "Classify workflow intent for orchestration"
  model: "haiku"
  timeout: 30000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/workflow-classifier.md

    **Workflow-Specific Context**:
    - Workflow Description: $SAVED_WORKFLOW_DESC
    - Command Name: coordinate

    **CRITICAL**: Return structured JSON classification.

    Execute classification following all guidelines in behavioral file.
    Return: CLASSIFICATION_COMPLETE: {JSON classification object}
  "
}

USE the Bash tool:
```

**Insertion Point**: AFTER line 213 (`}`) and BEFORE line 215 (`USE the Bash tool:`)

---

### Step 3: Insert State Extraction Bash Block

**New Section to Insert** (insert after line 213):

```markdown

**IMMEDIATELY AFTER Task completes**, extract classification from agent response:

**CRITICAL INSTRUCTION FOR COORDINATOR (Claude)**:
The workflow-classifier agent returns a signal in this format:
```
CLASSIFICATION_COMPLETE: {JSON classification object}
```

You MUST:
1. Parse the Task tool output above
2. Extract the JSON object after "CLASSIFICATION_COMPLETE: "
3. Substitute it in the bash block below where it says `<EXTRACT_FROM_TASK_OUTPUT>`
4. Then execute the bash block

**EXECUTE NOW**: USE the Bash tool:

```bash
#!/usr/bin/env bash
set +H  # Disable history expansion
set -euo pipefail

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Load state persistence library
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/error-handling.sh"

# Re-load workflow state ID
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
if [ ! -f "$COORDINATE_STATE_ID_FILE" ]; then
  echo "ERROR: State ID file not found: $COORDINATE_STATE_ID_FILE" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")

# Load existing state
load_workflow_state "$WORKFLOW_ID"

# CRITICAL: Extract classification JSON from agent response above
# The workflow-classifier agent returns: CLASSIFICATION_COMPLETE: {JSON object}
# Claude must parse the Task output and substitute the JSON here
#
# COORDINATOR: Replace <EXTRACT_FROM_TASK_OUTPUT> with the actual JSON
# from the Task tool's response signal above
CLASSIFICATION_JSON='<EXTRACT_FROM_TASK_OUTPUT>'

# Validate JSON before saving
if ! echo "$CLASSIFICATION_JSON" | jq empty 2>/dev/null; then
  echo "" >&2
  echo "❌ ERROR: Invalid JSON in classification result" >&2
  echo "" >&2
  echo "Received from workflow-classifier agent:" >&2
  echo "$CLASSIFICATION_JSON" >&2
  echo "" >&2
  echo "Expected format: CLASSIFICATION_COMPLETE: {valid JSON object}" >&2
  echo "" >&2
  exit 1
fi

# Save to state
append_workflow_state "CLASSIFICATION_JSON" "$CLASSIFICATION_JSON"

# Verify saved successfully
load_workflow_state "$WORKFLOW_ID"
if [ -z "${CLASSIFICATION_JSON:-}" ]; then
  echo "" >&2
  echo "❌ ERROR: Failed to save CLASSIFICATION_JSON to state" >&2
  echo "" >&2
  echo "Diagnostic:" >&2
  echo "  - append_workflow_state was called" >&2
  echo "  - But variable not present after reload" >&2
  echo "  - State file: $STATE_FILE" >&2
  echo "" >&2
  exit 1
fi

echo "✓ Classification saved to state successfully"
echo "  Workflow type: $(echo "$CLASSIFICATION_JSON" | jq -r '.workflow_type')"
echo "  Research complexity: $(echo "$CLASSIFICATION_JSON" | jq -r '.research_complexity')"
echo "  Topics: $(echo "$CLASSIFICATION_JSON" | jq -r '.research_topics | length')"
```

```

**Manual Edit Required**:

1. Open coordinate.md in your editor:
   ```bash
   code /home/benjamin/.config/.claude/commands/coordinate.md
   # Or: vim /home/benjamin/.config/.claude/commands/coordinate.md
   ```

2. Navigate to line 213 (end of Task tool block)

3. Insert the new section shown above

4. Save the file

---

### Step 4: Update Error Message in Existing Validation

**Find this section** (around lines 265-276, will shift after insertion):

```bash
# FAIL-FAST VALIDATION: Classification must exist in state
if [ -z "${CLASSIFICATION_JSON:-}" ]; then
  handle_state_error "CRITICAL: workflow-classifier agent did not save CLASSIFICATION_JSON to state

Diagnostic:
  - Agent was instructed to save classification via append_workflow_state
  - Expected: append_workflow_state \"CLASSIFICATION_JSON\" \"\$CLASSIFICATION_JSON\"
  - Check agent's bash execution in previous response
  - State file: \$STATE_FILE (loaded via load_workflow_state at line 220)

This is a critical bug. The workflow cannot proceed without classification data." 1
fi
```

**Replace with** (updated error message):

```bash
# FAIL-FAST VALIDATION: Classification must exist in state (redundant check)
# This should never fail if previous bash block succeeded
if [ -z "${CLASSIFICATION_JSON:-}" ]; then
  handle_state_error "CRITICAL: CLASSIFICATION_JSON missing from state despite extraction block

Diagnostic:
  - Classification should have been extracted and saved in previous bash block
  - This error indicates bash block state persistence failed
  - State file: \$STATE_FILE (loaded via load_workflow_state)
  - Check previous bash block execution for errors

This is a critical bug in state persistence." 1
fi
```

**Why This Change**: The error message now reflects the new architecture (extraction in coordinate, not agent).

---

### Step 5: Verify Changes

**Check 1: New Bash Block Present**

```bash
grep -n "EXTRACT_FROM_TASK_OUTPUT" /home/benjamin/.config/.claude/commands/coordinate.md

# Should return: Line number where new block inserted
# Example: 230:CLASSIFICATION_JSON='<EXTRACT_FROM_TASK_OUTPUT>'
```

**Check 2: Two Bash Blocks in Phase 0.1**

```bash
sed -n '/^## Phase 0.1: Workflow Classification/,/^## Phase 0.2/p' \
  /home/benjamin/.config/.claude/commands/coordinate.md | \
  grep -c "USE the Bash tool:"

# Should return: 2
# - First: New extraction block
# - Second: Existing state loading block
```

**Check 3: File Still Valid Markdown**

```bash
# Check for syntax issues
grep -n '```bash' /home/benjamin/.config/.claude/commands/coordinate.md | wc -l
grep -n '```$' /home/benjamin/.config/.claude/commands/coordinate.md | wc -l

# Should be equal (every opening has closing backticks)
```

**Check 4: Error Message Updated**

```bash
grep -n "workflow-classifier agent did not save CLASSIFICATION_JSON" \
  /home/benjamin/.config/.claude/commands/coordinate.md

# Should return: No matches (old error message removed)

grep -n "CLASSIFICATION_JSON missing from state despite extraction block" \
  /home/benjamin/.config/.claude/commands/coordinate.md

# Should return: Line number (new error message present)
```

---

### Step 6: Understand the Extraction Pattern

**How This Works**:

1. **Task Tool Execution**:
   ```
   Task {
     # Invokes workflow-classifier agent
   }
   ```

   Agent response:
   ```
   I've analyzed the workflow description...

   CLASSIFICATION_COMPLETE: {"workflow_type":"research-only","confidence":0.95,...}
   ```

2. **Coordinator (Claude) Responsibility**:
   - Claude sees the Task tool output
   - Claude parses the `CLASSIFICATION_COMPLETE:` signal
   - Claude extracts the JSON object after the colon
   - Claude substitutes it in the next bash block

3. **Bash Block Execution**:
   ```bash
   # Before Claude substitutes:
   CLASSIFICATION_JSON='<EXTRACT_FROM_TASK_OUTPUT>'

   # After Claude substitutes:
   CLASSIFICATION_JSON='{"workflow_type":"research-only","confidence":0.95,...}'
   ```

4. **State Persistence**:
   ```bash
   append_workflow_state "CLASSIFICATION_JSON" "$CLASSIFICATION_JSON"
   # → Appends to state file
   # → Available in subsequent bash blocks
   ```

**Key Insight**: This pattern leverages Claude's ability to parse previous tool outputs and substitute values in subsequent tool calls.

---

## Testing Instructions

### Test 1: Simple Research Workflow

```bash
cd /home/benjamin/.config

# Invoke coordinate with simple research description
/coordinate "research authentication patterns"
```

**Expected Outcome**:
```
✓ Workflow description captured to /home/benjamin/.claude/tmp/...
✓ State machine pre-initialization complete...
✓ Classification saved to state successfully
  Workflow type: research-only
  Research complexity: 2
  Topics: 3
✓ Workflow classification complete: type=research-only, complexity=2
...
```

**Failure Modes**:
- JSON extraction fails → Check Task output format
- JSON validation fails → Check jq parsing
- State save fails → Check append_workflow_state call
- State reload fails → Check load_workflow_state call

---

### Test 2: Full Implementation Workflow

```bash
/coordinate "implement user registration feature with email verification"
```

**Expected Outcome**:
```
...
✓ Classification saved to state successfully
  Workflow type: full-implementation
  Research complexity: 3
  Topics: 4
...
```

---

### Test 3: Debug Workflow

```bash
/coordinate "debug the login form validation error"
```

**Expected Outcome**:
```
...
✓ Classification saved to state successfully
  Workflow type: debug-only
  Research complexity: 1
  Topics: 2
...
```

---

## Edge Cases to Test

### Edge Case 1: Quoted Keywords

Description: `"research the 'implement' command documentation"`

**Expected**: `workflow_type: "research-only"` (doesn't confuse keyword matching)

---

### Edge Case 2: Complex JSON with Nested Quotes

Agent returns JSON with nested quotes:
```json
{
  "workflow_type": "research-only",
  "research_topics": [
    {
      "name": "Topic with \"quotes\"",
      "description": "Description with 'apostrophes'"
    }
  ]
}
```

**Expected**: JSON validation passes, escaping handled correctly

---

### Edge Case 3: Multi-Line JSON (Pretty-Printed)

If agent returns pretty-printed JSON (unlikely with Haiku):
```json
{
  "workflow_type": "research-only",
  "confidence": 0.95
}
```

**Expected**: Bash variable assignment may fail (newlines in CLASSIFICATION_JSON='...')

**Mitigation**: Agent typically returns minified JSON (single line)

---

## Why This Fix Works

### Execution Flow After Fix

```
┌─────────────────────────────────────────────────────────┐
│ Phase 0.1: Workflow Classification                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ 1. Task Tool Invocation (coordinate.md line 195-213)   │
│    ┌────────────────────────────────────────┐          │
│    │ Task { invoke workflow-classifier }    │          │
│    │ Agent returns:                         │          │
│    │ CLASSIFICATION_COMPLETE: {JSON}        │          │
│    └────────────────┬───────────────────────┘          │
│                     │                                    │
│                     ▼                                    │
│ 2. Coordinator Parsing (Claude)                         │
│    ┌────────────────────────────────────────┐          │
│    │ - Read Task output                     │          │
│    │ - Extract JSON after signal            │          │
│    │ - Prepare for substitution             │          │
│    └────────────────┬───────────────────────┘          │
│                     │                                    │
│                     ▼                                    │
│ 3. NEW: State Extraction Block (line ~215-260)         │
│    ┌────────────────────────────────────────┐          │
│    │ ```bash                                │          │
│    │ # Claude substitutes JSON here         │          │
│    │ CLASSIFICATION_JSON='{...actual...}'   │          │
│    │ # Validate with jq                     │          │
│    │ # Save to state                        │          │
│    │ append_workflow_state "CLASSIF..." "..." │        │
│    │ # Verify save                          │          │
│    │ load_workflow_state "$WORKFLOW_ID"     │          │
│    │ echo "✓ Saved successfully"            │          │
│    │ ```                                    │          │
│    └────────────────┬───────────────────────┘          │
│                     │                                    │
│                     ▼                                    │
│ 4. State Loading Block (line ~261-318)                 │
│    ┌────────────────────────────────────────┐          │
│    │ ```bash                                │          │
│    │ # Load state (CLASSIFICATION_JSON now  │          │
│    │ # available from previous block)       │          │
│    │ load_workflow_state "$WORKFLOW_ID"     │          │
│    │ # Validation (redundant but safe)      │          │
│    │ if [ -z "$CLASSIFICATION_JSON" ]; ...  │          │
│    │ # Parse JSON fields                    │          │
│    │ WORKFLOW_TYPE=$(echo ... | jq ...)     │          │
│    │ # Initialize state machine             │          │
│    │ sm_init ...                            │          │
│    │ ```                                    │          │
│    └────────────────────────────────────────┘          │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## Rollback Plan

If this fix causes issues:

```bash
cd /home/benjamin/.config

# Restore from backup
cp .claude/commands/coordinate.md.backup .claude/commands/coordinate.md

# Verify restoration
diff .claude/commands/coordinate.md.backup .claude/commands/coordinate.md
# Should show: No differences

echo "✓ Rollback complete"
```

---

## Alternative Implementation (If Substitution Fails)

If Claude cannot parse and substitute the JSON from Task output, use this fallback:

**Replace the extraction bash block with inline classification**:

```bash
# FALLBACK: Inline classification (if Task output parsing fails)
# Use keyword matching instead of LLM classification

WORKFLOW_DESC_LOWER=$(echo "$SAVED_WORKFLOW_DESC" | tr '[:upper:]' '[:lower:]')

# Detect workflow type
if echo "$WORKFLOW_DESC_LOWER" | grep -qE "(^| )(debug|fix)( |$)"; then
  WORKFLOW_TYPE="debug-only"
elif echo "$WORKFLOW_DESC_LOWER" | grep -qE "(^| )(revise|update plan)( |$)"; then
  WORKFLOW_TYPE="research-and-revise"
elif echo "$WORKFLOW_DESC_LOWER" | grep -qE "(^| )(plan|design)( |$)"; then
  WORKFLOW_TYPE="research-and-plan"
elif echo "$WORKFLOW_DESC_LOWER" | grep -qE "(^| )(implement|build|create)( |$)"; then
  WORKFLOW_TYPE="full-implementation"
else
  WORKFLOW_TYPE="research-only"
fi

# Build minimal classification JSON
CLASSIFICATION_JSON=$(jq -n \
  --arg wt "$WORKFLOW_TYPE" \
  '{workflow_type: $wt, confidence: 0.8, research_complexity: 2, research_topics: []}')

append_workflow_state "CLASSIFICATION_JSON" "$CLASSIFICATION_JSON"
```

**Trade-off**: Loses semantic analysis accuracy, but guarantees state persistence works.

---

## Success Criteria

- [ ] New bash block inserted after Task invocation (line ~213)
- [ ] Bash block loads state persistence library
- [ ] Bash block extracts CLASSIFICATION_JSON (with substitution marker)
- [ ] Bash block validates JSON with jq
- [ ] Bash block saves to state with append_workflow_state()
- [ ] Bash block verifies save successful
- [ ] Bash block outputs success message with JSON fields
- [ ] Error message updated in existing validation block
- [ ] File syntax valid (opening/closing backticks match)
- [ ] Backup created before changes

**Completion Signal**: When all criteria met, proceed to testing.

---

**Fix Status**: READY TO APPLY
**Created**: 2025-11-17
**Spec**: 752_debug_coordinate_workflow_classifier
**Debug Artifact**: 002_fix_coordinate_command.md
**Priority**: P0 (Critical)
**Dependencies**: Fix 001 (workflow-classifier.md must be applied first)
**Blocks**: Fix 003, Fix 004 (testing requires this fix working)
