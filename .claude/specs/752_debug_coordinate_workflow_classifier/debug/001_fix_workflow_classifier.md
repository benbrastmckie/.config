# Fix: Workflow Classifier Agent State Persistence (P0)

## Executive Summary

**Problem**: The workflow-classifier agent has contradictory configuration:
- Frontmatter declares `allowed-tools: None` (line 2)
- Body instructs agent to execute bash commands (lines 530-587)
- This contradiction causes agent to skip state persistence, breaking the coordinate command

**Solution**: Remove impossible state persistence instructions from agent behavioral file. State persistence will be moved to coordinate.md.

**Priority**: P0 (Critical - Blocking all coordinate workflows)

**Estimated Time**: 15 minutes

---

## Root Cause

The workflow-classifier agent cannot save CLASSIFICATION_JSON to workflow state because:

1. **Agent Configuration** (`/home/benjamin/.config/.claude/agents/workflow-classifier.md` lines 1-7):
   ```yaml
   ---
   allowed-tools: None
   description: Fast semantic workflow classification for orchestration commands
   model: haiku
   ---
   ```

2. **State Persistence Instructions** (lines 530-587):
   ```markdown
   ## CRITICAL - MANDATORY STATE PERSISTENCE

   **EXECUTE IMMEDIATELY** after completing classification:

   USE the Bash tool:

   ```bash
   #!/usr/bin/env bash
   # ... state persistence code ...
   append_workflow_state "CLASSIFICATION_JSON" "$CLASSIFICATION_JSON"
   ```
   ```

3. **The Contradiction**:
   - `allowed-tools: None` means agent **cannot** use Bash tool
   - Instructions say agent **must** use Bash tool
   - Agent returns classification JSON but **never executes bash block**
   - Coordinate command fails when CLASSIFICATION_JSON missing from state

---

## Files to Modify

### File 1: `/home/benjamin/.config/.claude/agents/workflow-classifier.md`

**Changes Required**:
1. Delete lines 530-587 (entire state persistence section)
2. Update agent description to clarify scope

---

## Step-by-Step Fix Instructions

### Step 1: Backup Current File

```bash
cd /home/benjamin/.config
cp .claude/agents/workflow-classifier.md .claude/agents/workflow-classifier.md.backup
```

**Verification**:
```bash
ls -la .claude/agents/workflow-classifier.md*
# Should show both original and backup file
```

---

### Step 2: Remove State Persistence Section

**Location**: Lines 530-587 in workflow-classifier.md

**Current Code** (TO BE DELETED):

```markdown
## CRITICAL - MANDATORY STATE PERSISTENCE

**AFTER** generating the classification JSON, you MUST save it to workflow state for the coordinate command to load in the next bash block.

**EXECUTE IMMEDIATELY** after completing classification:

USE the Bash tool:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Load state persistence library
source "$CLAUDE_PROJECT_DIR/.claude/lib/state-persistence.sh"

# Load workflow state ID
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
if [ ! -f "$COORDINATE_STATE_ID_FILE" ]; then
  echo "ERROR: State ID file not found: $COORDINATE_STATE_ID_FILE" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")

# Save classification JSON to state (REQUIRED - coordinate command will fail without this)
# Replace the JSON below with your actual classification result
CLASSIFICATION_JSON='<INSERT_YOUR_CLASSIFICATION_JSON_HERE>'

# Validate JSON before saving
if ! echo "$CLASSIFICATION_JSON" | jq empty 2>/dev/null; then
  echo "ERROR: Invalid JSON in classification result" >&2
  exit 1
fi

# Save to state
append_workflow_state "CLASSIFICATION_JSON" "$CLASSIFICATION_JSON"

# Verify saved successfully
load_workflow_state "$WORKFLOW_ID"
if [ -z "${CLASSIFICATION_JSON:-}" ]; then
  echo "ERROR: Failed to save CLASSIFICATION_JSON to state" >&2
  exit 1
fi

echo "✓ Classification saved to state successfully"
```

**IMPORTANT**: Replace `<INSERT_YOUR_CLASSIFICATION_JSON_HERE>` with your actual classification JSON object.

After saving to state, return the completion signal:

Return format: `CLASSIFICATION_COMPLETE: {JSON object}`
```

**Deletion Command**:

```bash
cd /home/benjamin/.config

# Delete lines 530-587 (58 lines total)
sed -i '530,587d' .claude/agents/workflow-classifier.md
```

**Alternative** (if sed fails):

Use your preferred editor to manually delete lines 530-587:
```bash
vim .claude/agents/workflow-classifier.md
# In vim: :530,587d
# Or use visual mode: go to line 530 (530G), then d58j

# Or with VS Code:
code .claude/agents/workflow-classifier.md
# Select lines 530-587 and delete
```

---

### Step 3: Update Agent Description

**Location**: After the deletion, the agent behavioral file should end with the checklist section (originally around line 520-529).

**Optional Enhancement**: Add clarifying note about agent scope.

**Find this section** (around line 520):

```markdown
- [ ] STEP 4: JSON output formatted correctly
  - [ ] Completion signal present
  - [ ] Valid JSON structure
  - [ ] All required fields present

**YOU MUST complete all steps before returning your response.**
```

**Add after it**:

```markdown

---

## Agent Scope

This agent is responsible for **classification only**. State persistence is handled by the calling command (coordinate.md).

**Your responsibilities**:
1. Analyze workflow description
2. Generate classification JSON
3. Return `CLASSIFICATION_COMPLETE: {JSON}` signal

**NOT your responsibility**:
- State persistence (handled by coordinate.md)
- Workflow execution
- File system operations

This design ensures single-responsibility and avoids execution context issues.
```

**Manual Edit Required**: Use your editor to add this section.

---

### Step 4: Verify Changes

**Check 1: File Length**

```bash
wc -l .claude/agents/workflow-classifier.md

# Before: ~587 lines
# After: ~529 lines (58 lines removed)
# With optional enhancement: ~545 lines
```

**Check 2: No Bash Tool References**

```bash
grep -n "USE the Bash tool" .claude/agents/workflow-classifier.md

# Should return: No matches
# If matches found: Deletion failed, try again
```

**Check 3: Completion Signal Still Present**

```bash
grep -n "CLASSIFICATION_COMPLETE" .claude/agents/workflow-classifier.md

# Should return: Multiple matches (in examples and instructions)
# Verify line with: Return format: `CLASSIFICATION_COMPLETE: {JSON object}`
```

**Check 4: Frontmatter Unchanged**

```bash
head -7 .claude/agents/workflow-classifier.md

# Should show:
# ---
# allowed-tools: None
# description: Fast semantic workflow classification for orchestration commands
# model: haiku
# model-justification: Classification is fast, deterministic task requiring <5s response time
# fallback-model: sonnet-4.5
# ---
```

---

### Step 5: Test Agent in Isolation

**Create test invocation**:

```bash
cd /home/benjamin/.config

# Test that agent can still classify without state persistence
cat > /tmp/test_classifier.txt << 'EOF'
Read and follow ALL behavioral guidelines from:
/home/benjamin/.config/.claude/agents/workflow-classifier.md

**Workflow-Specific Context**:
- Workflow Description: research authentication patterns
- Command Name: coordinate

**CRITICAL**: Return structured JSON classification.

Execute classification following all guidelines in behavioral file.
Return: CLASSIFICATION_COMPLETE: {JSON classification object}
EOF

echo "✓ Test prompt created at /tmp/test_classifier.txt"
echo "  Manually invoke workflow-classifier agent with this prompt to verify it works"
```

**Expected Behavior**:
- Agent analyzes "research authentication patterns"
- Agent returns: `CLASSIFICATION_COMPLETE: {"workflow_type":"research-only",...}`
- Agent does **NOT** attempt to save to state (no bash execution)

**Failure Modes**:
- Agent tries to execute bash block → Check deletion was complete
- Agent returns error about state persistence → Check instructions removed
- Agent doesn't return classification → Check behavioral guidelines intact

---

## Why This Fix Works

### Before Fix (Broken Architecture)

```
┌─────────────────────────────────────┐
│ coordinate.md                       │
│ - Invokes Task tool                 │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ workflow-classifier agent           │
│ - allowed-tools: None               │ ← Cannot use Bash
│ - Instructions: USE Bash tool       │ ← Contradictory!
│ - Generates classification JSON     │
│ - Returns CLASSIFICATION_COMPLETE   │
│ - SKIPS bash block (impossible)     │ ← STATE NOT SAVED
└─────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ coordinate.md (next bash block)     │
│ - load_workflow_state()             │
│ - Expects CLASSIFICATION_JSON       │ ← ERROR: Variable missing
│ - FAILS with unbound variable       │
└─────────────────────────────────────┘
```

### After Fix (Correct Architecture)

```
┌─────────────────────────────────────┐
│ coordinate.md                       │
│ - Invokes Task tool                 │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ workflow-classifier agent           │
│ - allowed-tools: None               │ ← Simplified scope
│ - Instructions: Return JSON only    │ ← Single responsibility
│ - Generates classification JSON     │
│ - Returns CLASSIFICATION_COMPLETE   │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ coordinate.md (bash block)          │
│ - Extract JSON from Task output     │ ← Coordinator responsibility
│ - append_workflow_state()           │ ← STATE SAVED
│ - Verify save successful            │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ coordinate.md (next bash block)     │
│ - load_workflow_state()             │
│ - CLASSIFICATION_JSON available     │ ← SUCCESS
│ - Continue workflow                 │
└─────────────────────────────────────┘
```

---

## Rollback Plan

If this fix causes issues:

```bash
cd /home/benjamin/.config

# Restore from backup
cp .claude/agents/workflow-classifier.md.backup .claude/agents/workflow-classifier.md

# Verify restoration
diff .claude/agents/workflow-classifier.md.backup .claude/agents/workflow-classifier.md
# Should show: No differences

echo "✓ Rollback complete"
```

---

## Next Steps

After applying this fix:

1. **Apply Fix 002**: Update coordinate.md to extract classification from Task output
2. **Test Integration**: Run `/coordinate "research test"` to verify end-to-end flow
3. **Apply Fix 003**: Add validation to load_workflow_state() for better diagnostics
4. **Apply Fix 004**: Create comprehensive test suite

**Note**: This fix alone will NOT make coordinate work. You MUST also apply Fix 002 (coordinate.md changes) for complete resolution.

---

## Success Criteria

- [ ] Lines 530-587 deleted from workflow-classifier.md
- [ ] No "USE the Bash tool" references remain
- [ ] Agent frontmatter unchanged (allowed-tools: None)
- [ ] Optional: Agent scope clarification added
- [ ] Backup created before changes
- [ ] File compiles/loads without errors
- [ ] Agent can still generate classification JSON

**Completion Signal**: When all criteria met, proceed to Fix 002.

---

**Fix Status**: READY TO APPLY
**Created**: 2025-11-17
**Spec**: 752_debug_coordinate_workflow_classifier
**Debug Artifact**: 001_fix_workflow_classifier.md
**Priority**: P0 (Critical)
**Dependencies**: None (can apply independently)
**Blocks**: Fix 002 (coordinate.md requires this fix first)
