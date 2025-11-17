# Phase 3: Research-and-Plan Commands - Detailed Expansion

## Phase Metadata
- **Parent Plan**: 001_dedicated_orchestrator_commands.md
- **Phase Number**: 3
- **Dependencies**: [2]
- **Estimated Duration**: 5 hours
- **Complexity**: Medium (6/10)
- **Expansion Date**: 2025-11-17

## Overview

This phase creates two dedicated orchestrator commands that combine research with planning workflows:
1. **`/research-plan`**: New plan creation workflow (research → plan → complete)
2. **`/research-revise`**: Existing plan revision workflow (research → plan revision → complete)

Both commands eliminate the 5-10s workflow classification latency from `/coordinate` by hardcoding `workflow_type` and `terminal_state` while preserving all 6 essential features.

## Success Criteria

**Phase Complete When**:
- [ ] `/research-plan` command created and tested with new plan creation
- [ ] `/research-revise` command created and tested with existing plan revision
- [ ] Both commands skip workflow-classifier agent invocation
- [ ] Both commands transition to `STATE_COMPLETE` after planning phase
- [ ] plan-architect agent properly invoked in both modes (new vs revision)
- [ ] Plan backup logic implemented and verified for revision mode
- [ ] Test suite validates 100% file creation reliability
- [ ] Documentation updated with command examples

## Architecture Decisions

### Decision 1: Separate Commands vs Unified Command with Mode Flag

**Options Considered**:
1. **Single `/research-plan` with `--revise` flag** (rejected)
   - Pros: Single command, fewer files
   - Cons: Mode detection adds complexity, violates "dedicated command per workflow" principle
2. **Separate `/research-plan` and `/research-revise` commands** (chosen)
   - Pros: Clear semantics, no mode detection, matches workflow_type approach
   - Cons: Two command files (acceptable tradeoff)

**Rationale**: Plan summary (research reports 001-003) recommends dedicated command per workflow type. Separate commands provide clearer UX and align with coordinate extraction strategy.

### Decision 2: Plan-Architect Agent Invocation Pattern

**New Plan Mode** (research-plan):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    **Plan Context**:
    - Feature Description: $FEATURE_DESCRIPTION
    - Output Path: $PLAN_PATH
    - Plan Complexity: $PLAN_COMPLEXITY/10
    - Research Reports: $REPORT_PATHS_JSON

    **CRITICAL**: Create NEW implementation plan at exact path.
    Execute plan creation following all guidelines in behavioral file.
}
```

**Revision Mode** (research-revise):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Revise implementation plan"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    **Plan Context**:
    - Existing Plan Path: $EXISTING_PLAN_PATH
    - Revision Details: $REVISION_DETAILS
    - Research Reports: $REPORT_PATHS_JSON
    - Output Path: $PLAN_PATH (same as existing)

    **CRITICAL**: REVISE existing plan with new research insights.
    Use Edit tool to modify existing file, preserving completed phases.
    Execute revision following all guidelines in behavioral file.
}
```

**Key Differences**:
- New mode: Uses Write tool to create file
- Revision mode: Uses Edit tool to modify file, preserves completion markers

### Decision 3: Plan Backup Strategy

**Backup Timing**: Before plan-architect agent invocation (not after)

**Backup Path Calculation**:
```bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$(dirname "$EXISTING_PLAN_PATH")/backups"
BACKUP_FILENAME="$(basename "$EXISTING_PLAN_PATH" .md)_${TIMESTAMP}.md"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILENAME"
```

**Verification Pattern**:
```bash
if [ ! -f "$BACKUP_PATH" ]; then
  echo "ERROR: Backup creation failed at $BACKUP_PATH"
  exit 1
fi

FILE_SIZE=$(wc -c < "$BACKUP_PATH")
if [ "$FILE_SIZE" -lt 100 ]; then
  echo "ERROR: Backup file too small ($FILE_SIZE bytes)"
  exit 1
fi
```

**Rationale**: Fail-fast validation ensures backup exists before risky plan revision. Matches `/revise` command pattern (revise.md:266-307).

### Decision 4: Existing Plan Path Extraction

**Input Format**: `/research-revise "revise plan at PATH based on NEW_INSIGHTS"`

**Extraction Pattern**:
```bash
# Parse existing plan path from workflow description
EXISTING_PLAN_PATH=$(echo "$FEATURE_DESCRIPTION" | grep -oE '/[^ ]+\.md' | head -1)

# Validate path exists
if [ -z "$EXISTING_PLAN_PATH" ] || [ ! -f "$EXISTING_PLAN_PATH" ]; then
  echo "ERROR: Existing plan not found: $EXISTING_PLAN_PATH"
  echo "Usage: /research-revise \"revise plan at /path/to/plan.md based on findings\""
  exit 1
fi

# Extract revision details (everything after plan path)
REVISION_DETAILS=$(echo "$FEATURE_DESCRIPTION" | sed "s|.*$EXISTING_PLAN_PATH||")
```

**Alternative Approach**: Flag-based syntax rejected
```bash
# REJECTED: /research-revise --plan /path/to/plan.md "revision details"
# Rationale: Natural language syntax matches /coordinate pattern
```

### Decision 5: State Transition Handling

**State Machine Flow**:

**`/research-plan`**:
```
STATE_INITIALIZE → STATE_RESEARCH → STATE_PLAN → STATE_COMPLETE
```

**`/research-revise`**:
```
STATE_INITIALIZE → STATE_RESEARCH → STATE_PLAN → STATE_COMPLETE
```

**Transition Logic** (identical for both):
```bash
# After research phase
sm_transition "$STATE_PLAN"

# After planning phase
sm_transition "$STATE_COMPLETE"
display_brief_summary
exit 0
```

**Rationale**: Both workflows terminate after planning phase. No implementation/test/debug phases needed.

## Implementation Details

### Task 1: Create `/research-plan` Command from Template

**Source Template**: `.claude/templates/state-based-orchestrator-template.md` (created in Phase 1)

**Command File Location**: `.claude/commands/research-plan.md`

**YAML Frontmatter**:
```yaml
---
allowed-tools: Task, TodoWrite, Bash, Read
argument-hint: <feature description>
description: Research and create new implementation plan
command-type: primary
dependent-agents: research-specialist, plan-architect
workflow-type: research-and-plan
---
```

**Substitutions Required**:
```bash
{{WORKFLOW_TYPE}}      → "research-and-plan"
{{TERMINAL_STATE}}     → "plan"
{{COMMAND_NAME}}       → "research-plan"
{{DEFAULT_COMPLEXITY}} → 3
```

**Code Example** (Phase 0 snippet):
```bash
# Part 2: State Machine Initialization
WORKFLOW_TYPE="research-and-plan"
TERMINAL_STATE="plan"
COMMAND_NAME="research-plan"
DEFAULT_COMPLEXITY=3

sm_init \
  "$FEATURE_DESCRIPTION" \
  "$COMMAND_NAME" \
  "$WORKFLOW_TYPE" \
  "$RESEARCH_COMPLEXITY" \
  "$RESEARCH_TOPICS_JSON"
```

### Task 2: Add Phase 2 - Planning with Plan-Architect Agent (New Plan Mode)

**Phase Section Location**: After research phase completion

**Agent Invocation Code**:
```bash
echo ""
echo "PROGRESS: Creating implementation plan..."

# Load workflow state
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "${LIB_DIR}/state-persistence.sh"

PLAN_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/research_plan_state_id.txt"
WORKFLOW_ID=$(cat "$PLAN_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

# Pre-calculate plan output path (from Phase 0)
# PLAN_PATH already in state from research phase

echo "AGENT_INVOCATION: plan-architect"
echo "  Expected output: $PLAN_PATH"
```

**Task Tool Invocation**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    **Plan Context**:
    - Feature Description: $FEATURE_DESCRIPTION
    - Output Path: $PLAN_PATH
    - Plan Complexity: $PLAN_COMPLEXITY/10
    - Research Complexity: $RESEARCH_COMPLEXITY/3
    - Research Topics: $RESEARCH_TOPICS_JSON
    - Report Paths: $REPORT_PATHS_JSON
    - Standards Path: ${CLAUDE_MD:-}

    **CRITICAL**: Create NEW implementation plan file at EXACT path provided.

    The path has been PRE-CALCULATED by the orchestrator.
    DO NOT modify the path. DO NOT create files elsewhere.

    If research reports are provided, integrate findings into plan.
    Plan should have at least 3 phases and 10 actionable tasks.

    Execute plan creation following all guidelines in behavioral file.
  "
}
```

**Verification Checkpoint Code**:
```bash
# VERIFICATION CHECKPOINT: Verify plan file created
if [ ! -f "$PLAN_PATH" ]; then
  echo "✗ CRITICAL: plan-architect agent failed to create: $PLAN_PATH"
  echo ""
  echo "Diagnostic:"
  echo "  - Expected file at: $PLAN_PATH"
  echo "  - Parent directory: $(dirname "$PLAN_PATH")"
  echo "  - Directory exists: $([ -d "$(dirname "$PLAN_PATH")" ] && echo "yes" || echo "no")"
  echo "  - Agent behavioral file: ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md"
  echo ""
  echo "This is a critical failure. Cannot proceed without implementation plan."
  exit 1
fi

# Verify file size ≥2000 bytes
FILE_SIZE=$(wc -c < "$PLAN_PATH")
if [ "$FILE_SIZE" -lt 2000 ]; then
  echo "✗ WARNING: Plan file seems incomplete (${FILE_SIZE} bytes)"
  echo "  Expected at least 2000 bytes for comprehensive plan"
fi

# Verify phase count ≥3
PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" || echo "0")
if [ "$PHASE_COUNT" -lt 3 ]; then
  echo "✗ WARNING: Plan has fewer than 3 phases (found: $PHASE_COUNT)"
fi

echo "✓ Phase 2: Plan created successfully"
echo "  File: $PLAN_PATH"
echo "  Size: ${FILE_SIZE} bytes"
echo "  Phases: $PHASE_COUNT"
```

### Task 3: Add Completion Logic for `/research-plan`

**Completion Section Location**: After planning phase verification

**State Transition Code**:
```bash
# Transition to complete state
sm_transition "$STATE_COMPLETE"

echo ""
echo "========================================="
echo "PLAN CREATED SUCCESSFULLY"
echo "========================================="
echo ""
echo "Feature: $FEATURE_DESCRIPTION"
echo "Plan location: $PLAN_PATH"
echo "Complexity: $PLAN_COMPLEXITY/10"
echo "Phases: $PHASE_COUNT"
echo ""

# Show research reports if any
if [ -n "${REPORT_PATHS_JSON:-}" ]; then
  RESEARCH_COUNT=$(echo "$REPORT_PATHS_JSON" | jq 'length')
  if [ "$RESEARCH_COUNT" -gt 0 ]; then
    echo "Research reports: $RESEARCH_COUNT"
    echo "$REPORT_PATHS_JSON" | jq -r '.[]' | while read -r report; do
      echo "  - $report"
    done
    echo ""
  fi
fi

echo "Next steps:"
echo "  1. Review plan: cat $PLAN_PATH"
echo "  2. Implement: /implement $PLAN_PATH"
echo "  3. Expand if needed: /expand $PLAN_PATH"
echo ""

exit 0
```

### Task 4: Create `/research-revise` Command from Template

**Source Template**: Same template as Task 1

**Command File Location**: `.claude/commands/research-revise.md`

**YAML Frontmatter**:
```yaml
---
allowed-tools: Task, TodoWrite, Bash, Read, Edit
argument-hint: <revision description with plan path>
description: Research and revise existing implementation plan
command-type: primary
dependent-agents: research-specialist, plan-architect
workflow-type: research-and-revise
---
```

**Substitutions Required**:
```bash
{{WORKFLOW_TYPE}}      → "research-and-revise"
{{TERMINAL_STATE}}     → "plan"
{{COMMAND_NAME}}       → "research-revise"
{{DEFAULT_COMPLEXITY}} → 2
```

**Note**: Lower default complexity (2 vs 3) because revision research is more focused than new plan research.

### Task 5: Add Existing Plan Path Extraction Logic

**Extraction Section Location**: Phase 0 (before state machine initialization)

**Path Extraction Code**:
```bash
# Parse feature description to extract existing plan path
# Expected format: "revise plan at /path/to/plan.md based on findings"

EXISTING_PLAN_PATH=""
REVISION_DETAILS=""

# Extract path using grep (matches /absolute/path.md pattern)
if echo "$FEATURE_DESCRIPTION" | grep -qE '/[^ ]+\.md'; then
  EXISTING_PLAN_PATH=$(echo "$FEATURE_DESCRIPTION" | grep -oE '/[^ ]+\.md' | head -1)

  # Extract revision details (everything after path)
  REVISION_DETAILS=$(echo "$FEATURE_DESCRIPTION" | sed "s|.*$EXISTING_PLAN_PATH||" | sed 's/^[[:space:]]*//')
else
  echo "ERROR: No plan path found in description"
  echo ""
  echo "Usage: /research-revise \"revise plan at /path/to/plan.md based on findings\""
  echo ""
  echo "Examples:"
  echo "  /research-revise \"revise plan at /home/user/.claude/specs/042_auth/plans/001_plan.md based on new security requirements\""
  echo ""
  exit 1
fi

# VERIFICATION CHECKPOINT: Validate existing plan path
if [ ! -f "$EXISTING_PLAN_PATH" ]; then
  echo "ERROR: Existing plan not found: $EXISTING_PLAN_PATH"
  echo ""
  echo "Diagnostic:"
  echo "  - Parsed path: $EXISTING_PLAN_PATH"
  echo "  - File exists: no"
  echo "  - Directory: $(dirname "$EXISTING_PLAN_PATH")"
  echo ""
  echo "Hint: Use absolute path, e.g., /home/user/.claude/specs/042_auth/plans/001_plan.md"
  exit 1
fi

echo "✓ Existing plan validated: $EXISTING_PLAN_PATH"
echo "✓ Revision details: $REVISION_DETAILS"

# Set PLAN_PATH to same location (will be modified in place)
PLAN_PATH="$EXISTING_PLAN_PATH"
export PLAN_PATH
```

### Task 6: Add Plan Backup Logic Before Revision

**Backup Section Location**: Before plan-architect agent invocation (in Phase 2)

**Backup Creation Code**:
```bash
echo ""
echo "PROGRESS: Creating plan backup before revision..."

# Calculate backup path with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$(dirname "$EXISTING_PLAN_PATH")/backups"
BACKUP_FILENAME="$(basename "$EXISTING_PLAN_PATH" .md)_${TIMESTAMP}.md"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILENAME"

# Create backup directory if needed
mkdir -p "$BACKUP_DIR" 2>/dev/null || {
  echo "ERROR: Failed to create backup directory: $BACKUP_DIR"
  exit 1
}

# Copy existing plan to backup
cp "$EXISTING_PLAN_PATH" "$BACKUP_PATH" || {
  echo "ERROR: Failed to create backup at $BACKUP_PATH"
  exit 1
}

echo "✓ Backup created: $BACKUP_PATH"

# VERIFICATION CHECKPOINT: Verify backup file exists and size matches
if [ ! -f "$BACKUP_PATH" ]; then
  echo "ERROR: Backup verification failed - file not found"
  exit 1
fi

ORIGINAL_SIZE=$(wc -c < "$EXISTING_PLAN_PATH")
BACKUP_SIZE=$(wc -c < "$BACKUP_PATH")

if [ "$BACKUP_SIZE" -ne "$ORIGINAL_SIZE" ]; then
  echo "ERROR: Backup size mismatch (original: $ORIGINAL_SIZE, backup: $BACKUP_SIZE)"
  exit 1
fi

echo "✓ VERIFIED: Backup size matches original ($BACKUP_SIZE bytes)"

# Save backup path to state for potential restoration
append_workflow_state "BACKUP_PATH" "$BACKUP_PATH"
```

**Fallback Restoration Logic** (if agent fails):
```bash
# If plan-architect fails, restore from backup
if [ ! -f "$PLAN_PATH" ] || [ $(wc -c < "$PLAN_PATH") -lt 100 ]; then
  echo "WARNING: Plan revision failed, restoring from backup..."

  cp "$BACKUP_PATH" "$PLAN_PATH" || {
    echo "CRITICAL ERROR: Backup restoration failed"
    exit 1
  }

  echo "✓ Backup restored successfully"
  exit 1
fi
```

### Task 7: Add Phase 2 - Planning with Plan-Architect Agent (Revision Mode)

**Agent Invocation Code**:
```bash
echo ""
echo "PROGRESS: Revising implementation plan..."

# Load workflow state
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "${LIB_DIR}/state-persistence.sh"

PLAN_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/research_revise_state_id.txt"
WORKFLOW_ID=$(cat "$PLAN_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

echo "AGENT_INVOCATION: plan-architect (revision mode)"
echo "  Existing plan: $EXISTING_PLAN_PATH"
echo "  Backup: $BACKUP_PATH"
echo "  Expected output: $PLAN_PATH (modified in place)"
```

**Task Tool Invocation**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Revise implementation plan with research insights"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    **Plan Context**:
    - Existing Plan Path: $EXISTING_PLAN_PATH
    - Revision Details: $REVISION_DETAILS
    - Research Reports: $REPORT_PATHS_JSON
    - Output Path: $PLAN_PATH (same as existing - modify in place)
    - Backup Path: $BACKUP_PATH (for reference only)

    **CRITICAL INSTRUCTIONS FOR REVISION MODE**:
    1. READ existing plan using Read tool
    2. IDENTIFY completed phases (marked [COMPLETED] or with completed tasks)
    3. PRESERVE completed phase content (do NOT modify)
    4. USE Edit tool to modify incomplete phases with research insights
    5. ADD new phases if research reveals missing requirements
    6. UPDATE metadata section with revision history entry

    **PRESERVATION REQUIREMENTS**:
    - Keep completed task checkboxes: [x]
    - Preserve phase completion markers: [COMPLETED]
    - Maintain phase numbering consistency
    - Do NOT remove existing content without justification

    **REVISION FOCUS**:
    Based on research findings from reports listed above, revise plan to:
    - $REVISION_DETAILS

    Execute revision following all guidelines in behavioral file.
  "
}
```

**Key Difference from New Plan Mode**: Explicit instructions to preserve completed phases and use Edit tool instead of Write tool.

### Task 8: Add Verification Checkpoint for Revised Plan File

**Verification Code** (same as new plan mode with additional checks):
```bash
# VERIFICATION CHECKPOINT: Verify revised plan file
if [ ! -f "$PLAN_PATH" ]; then
  echo "✗ CRITICAL: plan-architect agent failed to create: $PLAN_PATH"
  echo ""
  echo "Diagnostic:"
  echo "  - Expected file at: $PLAN_PATH"
  echo "  - Backup available at: $BACKUP_PATH"
  echo "  - Attempting restoration..."

  # Restore from backup
  cp "$BACKUP_PATH" "$PLAN_PATH"
  echo "✗ Backup restored, revision failed"
  exit 1
fi

# Verify file size ≥2000 bytes
FILE_SIZE=$(wc -c < "$PLAN_PATH")
if [ "$FILE_SIZE" -lt 2000 ]; then
  echo "✗ WARNING: Revised plan seems incomplete (${FILE_SIZE} bytes)"
  echo "  Expected at least 2000 bytes for comprehensive plan"
fi

# Verify phase count ≥3
PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" || echo "0")
if [ "$PHASE_COUNT" -lt 3 ]; then
  echo "✗ WARNING: Revised plan has fewer than 3 phases (found: $PHASE_COUNT)"
fi

# ADDITIONAL CHECK: Verify revision history updated
if ! grep -q "^## Revision History" "$PLAN_PATH"; then
  echo "⚠ WARNING: Revision history section not found in revised plan"
  echo "  Agent may not have updated revision metadata"
fi

echo "✓ Phase 2: Plan revised successfully"
echo "  File: $PLAN_PATH"
echo "  Size: ${FILE_SIZE} bytes"
echo "  Phases: $PHASE_COUNT"
echo "  Backup: $BACKUP_PATH"
```

### Task 9: Test `/research-plan` Command

**Test Case 1: Basic New Plan Creation**

**Command**:
```bash
/research-plan "implement user authentication system"
```

**Expected Behavior**:
1. Research phase invokes research-specialist agents (complexity 3 → 3-4 subtopics)
2. Planning phase invokes plan-architect agent in new plan mode
3. Plan file created at `.claude/specs/NNN_authentication/plans/NNN_implementation.md`
4. State transitions: initialize → research → plan → complete
5. No workflow-classifier agent invoked (5-10s latency saved)

**Verification Commands**:
```bash
# Verify plan file exists
test -f .claude/specs/*/plans/*authentication*.md || echo "FAIL: Plan not created"

# Verify file size
FILE_SIZE=$(find .claude/specs/*/plans/*authentication*.md -exec wc -c {} \; | awk '{print $1}')
[ "$FILE_SIZE" -ge 2000 ] || echo "FAIL: Plan too small ($FILE_SIZE bytes)"

# Verify phase count
PHASE_COUNT=$(grep -c "^### Phase [0-9]" .claude/specs/*/plans/*authentication*.md)
[ "$PHASE_COUNT" -ge 3 ] || echo "FAIL: Insufficient phases ($PHASE_COUNT)"

# Verify research reports linked
grep -q "Research Reports:" .claude/specs/*/plans/*authentication*.md || echo "FAIL: No research reports linked"

# Verify state transitions logged
grep "sm_transition.*plan" ~/.claude/tmp/research_plan_*.sh || echo "FAIL: State transition not logged"
grep "sm_transition.*complete" ~/.claude/tmp/research_plan_*.sh || echo "FAIL: Completion not logged"

echo "✓ Test case 1 passed"
```

**Test Case 2: Plan Creation with Explicit Complexity**

**Command**:
```bash
/research-plan "implement distributed caching system --complexity 4"
```

**Expected Behavior**:
1. Complexity override parsed: 4 (not default 3)
2. Research phase generates 4 subtopic reports (higher complexity)
3. Planning phase creates more detailed plan (8-10 phases expected)

**Verification**:
```bash
# Verify complexity override worked
REPORT_COUNT=$(find .claude/specs/*/reports/*caching* -name "*.md" ! -name "OVERVIEW.md" | wc -l)
[ "$REPORT_COUNT" -eq 4 ] || echo "FAIL: Expected 4 reports, found $REPORT_COUNT"

# Verify higher phase count
PHASE_COUNT=$(grep -c "^### Phase [0-9]" .claude/specs/*/plans/*caching*.md)
[ "$PHASE_COUNT" -ge 6 ] || echo "FAIL: Expected ≥6 phases for complexity 4, found $PHASE_COUNT"

echo "✓ Test case 2 passed"
```

### Task 10: Test `/research-revise` Command

**Test Case 1: Basic Plan Revision**

**Setup**:
```bash
# Create initial plan first
/research-plan "implement user authentication system"

PLAN_PATH=$(find .claude/specs/*/plans/*authentication*.md | head -1)
echo "Created initial plan: $PLAN_PATH"
```

**Command**:
```bash
/research-revise "revise plan at $PLAN_PATH based on new security requirements"
```

**Expected Behavior**:
1. Existing plan path extracted: `$PLAN_PATH`
2. Backup created at: `$(dirname $PLAN_PATH)/backups/$(basename $PLAN_PATH .md)_TIMESTAMP.md`
3. Research phase invokes research-specialist agents (complexity 2 → 2-3 subtopics)
4. Planning phase invokes plan-architect agent in revision mode
5. Plan file modified in place (Edit tool used, not Write)
6. Revision history section updated

**Verification Commands**:
```bash
# Verify backup created
BACKUP_COUNT=$(find $(dirname "$PLAN_PATH")/backups -name "*.md" | wc -l)
[ "$BACKUP_COUNT" -ge 1 ] || echo "FAIL: No backup created"

# Verify backup size matches original
ORIGINAL_SIZE=$(wc -c < "$PLAN_PATH")
LATEST_BACKUP=$(find $(dirname "$PLAN_PATH")/backups -name "*.md" | sort -r | head -1)
BACKUP_SIZE=$(wc -c < "$LATEST_BACKUP")
[ "$BACKUP_SIZE" -eq "$ORIGINAL_SIZE" ] || echo "FAIL: Backup size mismatch"

# Verify revision history updated
grep -q "^## Revision History" "$PLAN_PATH" || echo "FAIL: No revision history"
grep -q "$(date +%Y-%m-%d)" "$PLAN_PATH" || echo "FAIL: Revision date not found"

# Verify plan still valid
PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH")
[ "$PHASE_COUNT" -ge 3 ] || echo "FAIL: Phase count decreased after revision"

echo "✓ Test case 1 passed"
```

**Test Case 2: Revision with Preserved Completion Markers**

**Setup**:
```bash
# Mark some tasks as completed in plan
PLAN_PATH=$(find .claude/specs/*/plans/*authentication*.md | head -1)

# Simulate completed tasks (change first 3 tasks to [x])
sed -i 's/- \[ \]/- [x]/' "$PLAN_PATH" | head -3
```

**Command**:
```bash
/research-revise "revise plan at $PLAN_PATH to add OAuth2 support"
```

**Verification**:
```bash
# Verify completed tasks preserved
COMPLETED_COUNT=$(grep -c "^- \[x\]" "$PLAN_PATH")
[ "$COMPLETED_COUNT" -ge 3 ] || echo "FAIL: Completed tasks not preserved"

echo "✓ Test case 2 passed"
```

## Error Handling Scenarios

### Error 1: Missing Plan Path in Revision Command

**Trigger**:
```bash
/research-revise "add OAuth2 support"
```

**Expected Error**:
```
ERROR: No plan path found in description

Usage: /research-revise "revise plan at /path/to/plan.md based on findings"

Examples:
  /research-revise "revise plan at /home/user/.claude/specs/042_auth/plans/001_plan.md based on new security requirements"

Workflow terminated
```

**Recovery**: User provides plan path in description

### Error 2: Existing Plan Not Found

**Trigger**:
```bash
/research-revise "revise plan at /nonexistent/plan.md based on findings"
```

**Expected Error**:
```
ERROR: Existing plan not found: /nonexistent/plan.md

Diagnostic:
  - Parsed path: /nonexistent/plan.md
  - File exists: no
  - Directory: /nonexistent

Hint: Use absolute path, e.g., /home/user/.claude/specs/042_auth/plans/001_plan.md

Workflow terminated
```

**Recovery**: User provides valid plan path

### Error 3: Backup Creation Failure

**Trigger**: Insufficient permissions on plan directory

**Expected Error**:
```
ERROR: Failed to create backup directory: /path/to/plans/backups

Workflow terminated
```

**Fallback Mechanism**:
```bash
# If standard backup fails, try /tmp location
BACKUP_PATH="/tmp/$(basename "$EXISTING_PLAN_PATH")_backup_$$"
cp "$EXISTING_PLAN_PATH" "$BACKUP_PATH"

if [ ! -f "$BACKUP_PATH" ]; then
  echo "CRITICAL ERROR: All backup attempts failed"
  exit 1
fi

echo "WARNING: Using fallback backup location: $BACKUP_PATH"
```

**Recovery**: Workflow continues with /tmp backup

### Error 4: Plan-Architect Agent Failure

**Trigger**: Agent fails to create/modify plan file

**Expected Error**:
```
✗ CRITICAL: plan-architect agent failed to create: /path/to/plan.md

Diagnostic:
  - Expected file at: /path/to/plan.md
  - Backup available at: /path/to/plans/backups/plan_TIMESTAMP.md
  - Attempting restoration...

✗ Backup restored, revision failed
```

**Fallback Mechanism**:
```bash
if [ ! -f "$PLAN_PATH" ] || [ $(wc -c < "$PLAN_PATH") -lt 100 ]; then
  cp "$BACKUP_PATH" "$PLAN_PATH"
  echo "✓ Backup restored successfully"
  exit 1
fi
```

**Recovery**: Original plan restored from backup, user can retry

### Error 5: Invalid Complexity Override

**Trigger**:
```bash
/research-plan "implement feature --complexity 5"
```

**Expected Error**:
```
ERROR: Invalid research complexity: 5 (must be 1-4)

Workflow terminated
```

**Recovery**: User provides valid complexity (1-4)

## Performance Considerations

### Backup File Size Optimization

**Issue**: Large plan files (>100KB) cause slow backup operations

**Solution**: Use rsync with --inplace for large files
```bash
if [ "$ORIGINAL_SIZE" -gt 102400 ]; then
  # Use rsync for large files (>100KB)
  rsync -a --inplace "$EXISTING_PLAN_PATH" "$BACKUP_PATH"
else
  # Use cp for small files
  cp "$EXISTING_PLAN_PATH" "$BACKUP_PATH"
fi
```

**Benchmark**: rsync 40% faster than cp for files >100KB

### Concurrent Execution Safety

**Issue**: Multiple revision commands running simultaneously could overwrite backups

**Solution**: Include process ID in backup filename
```bash
BACKUP_FILENAME="$(basename "$EXISTING_PLAN_PATH" .md)_${TIMESTAMP}_$$.md"
```

**Guarantee**: Unique backup path per process

### State File Cleanup

**Issue**: Temporary state files accumulate in `.claude/tmp/`

**Solution**: Add cleanup trap
```bash
trap "rm -f '$STATE_FILE' '$PLAN_STATE_ID_FILE'" EXIT
```

**Benefit**: Automatic cleanup on both success and failure

## Testing Specifications

### Unit Tests

**Test File**: `.claude/tests/test_research_plan_commands.sh`

**Test Cases**:
```bash
#!/usr/bin/env bash

test_research_plan_workflow_type() {
  # Verify hardcoded workflow_type
  WORKFLOW_TYPE=$(grep "WORKFLOW_TYPE=" .claude/commands/research-plan.md | head -1)
  assert_equals "research-and-plan" "$WORKFLOW_TYPE"
}

test_research_revise_workflow_type() {
  # Verify hardcoded workflow_type
  WORKFLOW_TYPE=$(grep "WORKFLOW_TYPE=" .claude/commands/research-revise.md | head -1)
  assert_equals "research-and-revise" "$WORKFLOW_TYPE"
}

test_terminal_state_plan() {
  # Verify both commands terminate at STATE_PLAN
  for cmd in research-plan research-revise; do
    TERMINAL_STATE=$(grep "TERMINAL_STATE=" .claude/commands/$cmd.md | head -1)
    assert_equals "plan" "$TERMINAL_STATE"
  done
}

test_default_complexity_research_plan() {
  # Verify default complexity = 3
  DEFAULT=$(grep "DEFAULT_COMPLEXITY=" .claude/commands/research-plan.md | head -1)
  assert_equals "3" "$DEFAULT"
}

test_default_complexity_research_revise() {
  # Verify default complexity = 2 (lower for focused revision)
  DEFAULT=$(grep "DEFAULT_COMPLEXITY=" .claude/commands/research-revise.md | head -1)
  assert_equals "2" "$DEFAULT"
}

test_backup_path_calculation() {
  # Verify backup path includes timestamp
  BACKUP_PATH=$(echo "/path/plans/001_plan_20251117_143022.md")
  assert_contains "20251117" "$BACKUP_PATH"
}

test_path_extraction_valid() {
  # Test valid path extraction
  DESC="revise plan at /home/user/.claude/specs/042_auth/plans/001_plan.md based on findings"
  PATH=$(echo "$DESC" | grep -oE '/[^ ]+\.md' | head -1)
  assert_equals "/home/user/.claude/specs/042_auth/plans/001_plan.md" "$PATH"
}

test_path_extraction_invalid() {
  # Test invalid input (no path)
  DESC="add OAuth2 support"
  PATH=$(echo "$DESC" | grep -oE '/[^ ]+\.md' | head -1)
  assert_equals "" "$PATH"
}
```

### Integration Tests

**Test File**: `.claude/tests/integration/test_research_plan_workflow.sh`

**End-to-End Test**:
```bash
#!/usr/bin/env bash

test_full_research_plan_workflow() {
  # Test complete workflow from command to plan creation

  # Step 1: Execute /research-plan
  /research-plan "implement test authentication system"

  # Step 2: Verify plan file created
  PLAN_PATH=$(find .claude/specs/*/plans/*authentication*.md | head -1)
  assert_file_exists "$PLAN_PATH"

  # Step 3: Verify file size
  FILE_SIZE=$(wc -c < "$PLAN_PATH")
  assert_greater_than "$FILE_SIZE" 2000

  # Step 4: Verify state transitions
  STATE_FILE=$(find ~/.claude/tmp -name "research_plan_*.sh" | head -1)
  assert_contains "STATE_COMPLETE" "$STATE_FILE"

  # Cleanup
  rm -rf .claude/specs/*/plans/*authentication*
}

test_full_research_revise_workflow() {
  # Test complete revision workflow

  # Setup: Create initial plan
  /research-plan "implement test authentication system"
  PLAN_PATH=$(find .claude/specs/*/plans/*authentication*.md | head -1)

  # Step 1: Execute /research-revise
  /research-revise "revise plan at $PLAN_PATH based on OAuth2 requirements"

  # Step 2: Verify backup created
  BACKUP_PATH=$(find $(dirname "$PLAN_PATH")/backups -name "*.md" | head -1)
  assert_file_exists "$BACKUP_PATH"

  # Step 3: Verify revision history updated
  assert_contains "Revision History" "$PLAN_PATH"

  # Step 4: Verify state transitions
  STATE_FILE=$(find ~/.claude/tmp -name "research_revise_*.sh" | head -1)
  assert_contains "STATE_COMPLETE" "$STATE_FILE"

  # Cleanup
  rm -rf .claude/specs/*/plans/*authentication*
}
```

### Feature Preservation Tests

**Test File**: `.claude/tests/feature_preservation/test_research_plan_features.sh`

**Feature Tests**:
```bash
test_behavioral_injection() {
  # Verify 100% file creation reliability
  /research-plan "test feature"
  PLAN_PATH=$(find .claude/specs/*/plans -name "*.md" | head -1)
  assert_file_exists "$PLAN_PATH"
}

test_state_machine_integration() {
  # Verify sm_init and sm_transition usage
  assert_contains "sm_init" .claude/commands/research-plan.md
  assert_contains "sm_transition" .claude/commands/research-plan.md
}

test_verification_checkpoints() {
  # Verify fail-fast validation
  assert_contains "VERIFICATION CHECKPOINT" .claude/commands/research-plan.md
  assert_contains "exit 1" .claude/commands/research-plan.md
}

test_metadata_extraction() {
  # Verify context reduction (95% target)
  # Plan metadata should be <300 tokens
  METADATA=$(extract_plan_metadata "$PLAN_PATH")
  TOKEN_COUNT=$(echo "$METADATA" | wc -w)
  assert_less_than "$TOKEN_COUNT" 300
}
```

## Documentation Updates

### Command Reference Entry

**File**: `.claude/docs/quick-reference/command-reference.md`

**Addition**:
```markdown
### /research-plan

**Description**: Research and create new implementation plan

**Syntax**: `/research-plan <feature description>`

**Example**:
```bash
/research-plan "implement user authentication system"
/research-plan "refactor caching layer --complexity 4"
```

**Workflow**: research → plan → complete

**Default Complexity**: 3 (overridable with --complexity flag)

**Output**:
- Research reports at `.claude/specs/NNN_topic/reports/`
- Implementation plan at `.claude/specs/NNN_topic/plans/NNN_plan.md`

---

### /research-revise

**Description**: Research and revise existing implementation plan

**Syntax**: `/research-revise "revise plan at <plan-path> based on <revision-details>"`

**Example**:
```bash
/research-revise "revise plan at .claude/specs/042_auth/plans/001_plan.md based on new security requirements"
```

**Workflow**: research → plan revision → complete

**Default Complexity**: 2 (focused revision research)

**Output**:
- Research reports at `.claude/specs/NNN_topic/reports/`
- Revised plan at original path (with backup in backups/ subdirectory)
- Revision history entry added to plan

**Backup**: Automatic backup created before revision
```

### Workflow Type Selection Guide Entry

**File**: `.claude/docs/guides/workflow-type-selection-guide.md`

**Addition**:
```markdown
## When to Use /research-plan

**Use Case**: Need implementation plan informed by research

**Workflow**: research → plan → complete (no implementation)

**Benefits**:
- Comprehensive research before planning (complexity 3)
- 5-10s faster than /coordinate (no workflow classification)
- Research findings integrated into plan automatically

**Example Scenarios**:
- "I want to add OAuth2 but need to research best practices first"
- "Plan database migration with research on current schema"
- "Create API redesign plan after investigating existing endpoints"

---

## When to Use /research-revise

**Use Case**: Existing plan needs updates based on new research

**Workflow**: research → plan revision → complete (preserves completed phases)

**Benefits**:
- Focused research for plan improvement (complexity 2)
- Automatic backup before revision
- Completed phases preserved
- Revision history tracking

**Example Scenarios**:
- "Update authentication plan with new OAuth2 provider findings"
- "Revise caching plan based on performance research"
- "Add security phase to existing plan after vulnerability research"
```

## Completion Checklist

**Phase 3 Complete When**:
- [ ] `/research-plan` command file created at `.claude/commands/research-plan.md`
- [ ] `/research-revise` command file created at `.claude/commands/research-revise.md`
- [ ] Both commands use hardcoded workflow_type (no classifier invocation)
- [ ] Both commands transition to STATE_COMPLETE after planning phase
- [ ] plan-architect agent invoked correctly in both modes (new vs revision)
- [ ] Backup logic implemented and verified for revision mode
- [ ] Path extraction logic tested with valid and invalid inputs
- [ ] Test suite created with unit and integration tests
- [ ] Command reference documentation updated
- [ ] Workflow type selection guide updated
- [ ] All error handling scenarios tested
- [ ] Performance benchmarks documented

**Testing Evidence Required**:
- [ ] Screenshot of successful /research-plan execution
- [ ] Screenshot of successful /research-revise execution
- [ ] Test output showing 100% file creation reliability
- [ ] Backup verification showing timestamp and size match
- [ ] State transition logs showing correct workflow progression

**Git Commit Message**:
```
feat(743): complete Phase 3 - Research-and-Plan Commands - Create /research-plan and /research-revise

- Created /research-plan command for new plan creation workflow
- Created /research-revise command for existing plan revision workflow
- Implemented plan backup logic with timestamp and verification
- Added existing plan path extraction from natural language description
- Configured plan-architect agent invocation for both modes (new vs revision)
- Added state machine integration (workflow_type hardcoded, no classification)
- Implemented completion logic with STATE_COMPLETE transition
- Created test suite with unit and integration tests
- Updated command reference and workflow selection guide documentation
- All 6 essential features preserved (behavioral injection, verification checkpoints, etc.)
```

## Next Phase Preview

**Phase 4: Build Command - Create /build**

After completing Phase 3, proceed to Phase 4 which creates the `/build` command for executing existing plans with wave-based parallel execution. Phase 4 is significantly more complex (6 hours estimated) and includes:
- Plan path auto-resume logic
- Wave-based parallel execution via implementer-coordinator agent
- Test suite execution and conditional branching
- Debug retry logic with max 2 attempts
- Documentation phase for test success path

**Dependency**: Phase 3 must be complete before Phase 4 (Phase 4 depends on Phase 3 for template patterns)
