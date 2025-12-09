# Implementation Plan: /revise Command Workflow State Fix

## Metadata

**Date**: 2025-12-09
**Feature**: Fix /revise command hard barrier enforcement to prevent workflow bypass and ensure mandatory agent delegation
**Status**: [COMPLETE]
**Estimated Hours**: 4-6 hours
**Standards File**: /home/benjamin/.config/CLAUDE.md
**Research Reports**:
- [Root Cause Analysis](/home/benjamin/.config/.claude/specs/035_revise_command_workflow_state_fix/reports/001-root-cause-analysis.md)
- [Standards Compliance Fix](/home/benjamin/.config/.claude/specs/035_revise_command_workflow_state_fix/reports/002-standards-compliance-fix.md)

## Problem Statement

The `/revise` command workflow was bypassed when the agent skipped mandatory state machine initialization and research/planning phases, making direct Edit tool calls instead. This violated the hard barrier pattern that enforces mandatory agent delegation through structural bash verification blocks.

**Root Cause**: Missing structural enforcement mechanisms (imperative Task directives, path pre-calculation, fail-fast verification blocks) that would make workflow bypass structurally impossible.

**Impact**:
- Research phase bypassed entirely (no research reports created)
- State machine never initialized or transitioned
- No checkpoint reporting or error logging
- Backup file never created before plan modifications
- Architectural separation of concerns violated

## Solution Overview

Implement the **Hard Barrier Pattern** (3-block Na/Nb/Nc sequence) proven in `/create-plan` command:

1. **Imperative Task Directives**: Add "**EXECUTE NOW**: USE the Task tool..." to all Task invocations
2. **Path Pre-Calculation**: Calculate expected artifact paths BEFORE agent invocation
3. **Hard Barrier Validation**: Add verification blocks with fail-fast (exit 1) on missing artifacts
4. **Enhanced Error Logging**: Log all verification failures for queryable debugging

## Architecture Changes

### Current Structure (Bypassed)
```
Block 1: Args capture (bash) ✓
Block 2: Validation (bash) ✓
Block 3: State init (bash) ✗ SKIPPED
Block 4a: Research setup (bash) ✗ SKIPPED
Block 4b: Research exec (Task) ✗ SKIPPED
Block 4c: Research verify (bash) ✗ SKIPPED
```

### Target Structure (Enforced)
```
Block 1: Args capture (bash) ✓
Block 2: Validation (bash) ✓
Block 3: State init (bash) ✓
Block 3a: State verification (bash) ✓ [NEW BARRIER]
Block 4a: Research path pre-calc (bash) ✓
Block 4b: Research exec (Task) ✓ [IMPERATIVE DIRECTIVE]
Block 4c: Research verify (bash) ✓ [FAIL-FAST]
Block 5a: Plan path pre-calc (bash) ✓
Block 5b: Plan exec (Task) ✓ [IMPERATIVE DIRECTIVE]
Block 5c: Plan verify (bash) ✓ [FAIL-FAST]
```

---

## Phase 1: Add State Machine Hard Barrier Validation [COMPLETE]

**Objective**: Prevent workflow progression without state machine initialization

**Success Criteria**:
- [x] New Block 3a validation block added after Block 3
- [x] State ID file existence validated with fail-fast exit
- [x] State file existence validated with fail-fast exit
- [x] Error logging integrated for state validation failures
- [x] Checkpoint reporting added for successful validation

### Tasks

#### Task 1.1: Create Block 3a State Verification Block
**File**: `.claude/commands/revise.md`
**Location**: After Block 3 (State Machine Initialization)

Add new validation block:
```markdown
## Block 3a: State Machine Initialization Verification

**HARD BARRIER**: Validate state machine initialized before proceeding to research phase.

```bash
set +H

# Re-source libraries (three-tier sourcing pattern)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Cannot load state-persistence library" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}

# Load workflow ID from file
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/revise_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  log_command_error \
    "/revise" \
    "unknown" \
    "$USER_ARGS" \
    "state_error" \
    "HARD BARRIER FAILED: State ID file not found" \
    "bash_block_3a" \
    "$(jq -n --arg expected "$STATE_ID_FILE" '{expected_file: $expected}')"

  echo "ERROR: HARD BARRIER FAILED - State machine not initialized" >&2
  echo "DIAGNOSTIC: Block 3 should have created $STATE_ID_FILE" >&2
  echo "CAUSE: State machine initialization was skipped or failed" >&2
  exit 1
fi

WORKFLOW_ID=$(cat "$STATE_ID_FILE")

# Validate state file exists
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/data/state/revise_${WORKFLOW_ID}.state"
if [ ! -f "$STATE_FILE" ]; then
  log_command_error \
    "/revise" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "HARD BARRIER FAILED: State file not found" \
    "bash_block_3a" \
    "$(jq -n --arg expected "$STATE_FILE" '{expected_file: $expected}')"

  echo "ERROR: HARD BARRIER FAILED - State file not found: $STATE_FILE" >&2
  echo "DIAGNOSTIC: Block 3 should have initialized state machine" >&2
  exit 1
fi

echo "[CHECKPOINT] Hard barrier passed: State machine initialized"
echo "Workflow ID: $WORKFLOW_ID"
echo "State file: $STATE_FILE"
```
```

---

## Phase 2: Implement Research Phase Hard Barrier Pattern [COMPLETE]

**Objective**: Enforce mandatory research-specialist delegation with path pre-calculation and fail-fast verification

**Success Criteria**:
- [x] Block 4a calculates EXPECTED_REPORT_PATH before Task invocation
- [x] Block 4b uses imperative directive pattern ("**EXECUTE NOW**: USE the Task tool...")
- [x] Block 4c validates report at exact pre-calculated path (not searching)
- [x] Block 4c exits 1 on missing or invalid reports
- [x] Error logging captures all verification failures

### Tasks

#### Task 2.1: Add Path Pre-Calculation to Block 4a
**File**: `.claude/commands/revise.md`
**Location**: Block 4a (Research Phase Setup), after line 617

Add path pre-calculation:
```bash
# Pre-calculate expected report path (Hard Barrier Pattern)
EXPECTED_REPORT_PATH="${RESEARCH_DIR}/${REVISION_NUMBER}-${REVISION_TOPIC_SLUG}.md"

# Validate path is absolute
if [[ ! "$EXPECTED_REPORT_PATH" =~ ^/ ]]; then
  log_command_error "/revise" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" \
    "EXPECTED_REPORT_PATH is not absolute" \
    "bash_block_4a" \
    "$(jq -n --arg path "$EXPECTED_REPORT_PATH" '{calculated_path: $path}')"
  echo "ERROR: Expected report path is not absolute: $EXPECTED_REPORT_PATH" >&2
  exit 1
fi

# Persist for verification block
append_workflow_state "EXPECTED_REPORT_PATH" "$EXPECTED_REPORT_PATH"

echo "Pre-calculated expected report path: $EXPECTED_REPORT_PATH"
```

#### Task 2.2: Update Block 4b with Imperative Task Directive
**File**: `.claude/commands/revise.md`
**Location**: Block 4b (Research Phase Execution), line 640

**BEFORE** (instructional text pattern):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research revision insights for ${REVISION_DETAILS}"
  prompt: "..."
}
```

**AFTER** (imperative directive pattern):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research revision insights for ${REVISION_DETAILS} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are conducting research for: revise workflow

    **Workflow-Specific Context**:
    - Research Topic: Plan revision insights for: ${REVISION_DETAILS}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Output Directory: ${RESEARCH_DIR}
    - Output Path: ${EXPECTED_REPORT_PATH}
    - Workflow Type: research-and-revise
    - Existing Plan: ${EXISTING_PLAN_PATH}

    **CRITICAL**: You MUST write the research report to the EXACT path specified above.
    The orchestrator has pre-calculated this path and will validate it exists after you return.
    Do NOT derive or calculate your own path.

    Execute research according to behavioral guidelines and return completion signal:
    REPORT_CREATED: ${EXPECTED_REPORT_PATH}
  "
}
```

#### Task 2.3: Replace Block 4c with Fail-Fast Verification
**File**: `.claude/commands/revise.md`
**Location**: Block 4c (Research Phase Verification), line 667

**BEFORE** (weak verification):
```bash
# Count new reports created (may already have existing reports)
NEW_REPORT_COUNT=$(find "$RESEARCH_DIR" -name '*.md' -type f -newer "$EXISTING_PLAN_PATH" 2>/dev/null | wc -l)

if [ "$NEW_REPORT_COUNT" -eq 0 ]; then
  echo "WARNING: No new research reports created"
  echo "NOTE: Proceeding with plan revision using existing reports"
fi
```

**AFTER** (fail-fast verification):
```bash
# Re-source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || exit 1

# Load workflow state
WORKFLOW_ID=$(cat "${CLAUDE_PROJECT_DIR}/.claude/tmp/revise_state_id.txt")
load_workflow_state "$WORKFLOW_ID" false

echo "Expected report path: $EXPECTED_REPORT_PATH"

# HARD BARRIER: Report file MUST exist at pre-calculated path
if [ ! -f "$EXPECTED_REPORT_PATH" ]; then
  # Enhanced diagnostics: Search for file in alternate locations
  REPORT_NAME=$(basename "$EXPECTED_REPORT_PATH")
  FOUND_FILES=$(find "$RESEARCH_DIR" -name "$REPORT_NAME" 2>/dev/null || true)

  if [ -n "$FOUND_FILES" ]; then
    echo "ERROR: HARD BARRIER FAILED - Report at wrong location" >&2
    echo "Expected: $EXPECTED_REPORT_PATH" >&2
    echo "Found at:" >&2
    echo "$FOUND_FILES" | while read -r file; do
      echo "  - $file" >&2
    done
    log_command_error "/revise" "$WORKFLOW_ID" "$USER_ARGS" \
      "agent_error" \
      "research-specialist created report at wrong location" \
      "bash_block_4c" \
      "$(jq -n --arg expected "$EXPECTED_REPORT_PATH" --arg found "$FOUND_FILES" \
         '{expected: $expected, found: $found}')"
  else
    echo "ERROR: HARD BARRIER FAILED - Report file not found anywhere" >&2
    echo "Expected: $EXPECTED_REPORT_PATH" >&2
    echo "Search directory: $RESEARCH_DIR" >&2
    log_command_error "/revise" "$WORKFLOW_ID" "$USER_ARGS" \
      "agent_error" \
      "research-specialist failed to create report file" \
      "bash_block_4c" \
      "$(jq -n --arg expected "$EXPECTED_REPORT_PATH" --arg dir "$RESEARCH_DIR" \
         '{expected: $expected, search_dir: $dir}')"
  fi

  echo "DIAGNOSTIC: research-specialist agent should have created report in Block 4b" >&2
  echo "RECOVERY: Re-run /revise command, check research-specialist logs" >&2
  exit 1
fi

# Validate report is not empty
REPORT_SIZE=$(wc -c < "$EXPECTED_REPORT_PATH" 2>/dev/null || echo 0)
if [ "$REPORT_SIZE" -lt 100 ]; then
  log_command_error "/revise" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" \
    "Report file too small ($REPORT_SIZE bytes)" \
    "bash_block_4c" \
    "$(jq -n --argjson size "$REPORT_SIZE" '{size_bytes: $size}')"
  echo "ERROR: Report file suspiciously small: $REPORT_SIZE bytes" >&2
  exit 1
fi

echo "[CHECKPOINT] Hard barrier passed: Research report validated"
echo "Report size: $REPORT_SIZE bytes"
echo "Report path: $EXPECTED_REPORT_PATH"
```

---

## Phase 3: Implement Plan Revision Phase Hard Barrier Pattern [COMPLETE]

**Objective**: Enforce mandatory plan-architect delegation with backup path pre-calculation and fail-fast verification

**Success Criteria**:
- [x] Block 5a calculates BACKUP_PATH before Task invocation
- [x] Block 5b uses imperative directive pattern with revision-specific prompt
- [x] Block 5c validates backup exists AND plan was modified
- [x] Block 5c exits 1 if plan identical to backup (no modifications made)
- [x] Error logging captures plan revision failures

### Tasks

#### Task 3.1: Add Backup Path Pre-Calculation to Block 5a
**File**: `.claude/commands/revise.md`
**Location**: Block 5a (Plan Revision Phase Setup)

Enhance existing block to pre-calculate backup path:
```bash
# Pre-calculate backup path (Hard Barrier Pattern)
BACKUP_DIR="${SPECS_DIR}/backups"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
PLAN_BASENAME=$(basename "$EXISTING_PLAN_PATH" .md)
BACKUP_PATH="${BACKUP_DIR}/${PLAN_BASENAME}_backup_${TIMESTAMP}.md"

# Validate backup path is absolute
if [[ ! "$BACKUP_PATH" =~ ^/ ]]; then
  log_command_error "/revise" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" \
    "BACKUP_PATH is not absolute" \
    "bash_block_5a" \
    "$(jq -n --arg path "$BACKUP_PATH" '{calculated_path: $path}')"
  echo "ERROR: Backup path is not absolute: $BACKUP_PATH" >&2
  exit 1
fi

# Persist for verification block
append_workflow_state "BACKUP_PATH" "$BACKUP_PATH"

echo "Pre-calculated backup path: $BACKUP_PATH"
```

#### Task 3.2: Update Block 5b with Imperative Task Directive
**File**: `.claude/commands/revise.md`
**Location**: Block 5b (Plan Revision Phase Execution), line 1070

**BEFORE** (incomplete directive):
```markdown
**CRITICAL BARRIER**: This section invokes the plan-architect agent via Task tool.

Task {
  subagent_type: "general-purpose"
  description: "Revise implementation plan"
  prompt: "..."
}
```

**AFTER** (complete imperative directive):
```markdown
**CRITICAL BARRIER**: This section invokes the plan-architect agent via Task tool. The Task invocation is MANDATORY and CANNOT be bypassed.

**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Revise implementation plan based on ${REVISION_DETAILS} with mandatory file modification"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are revising an implementation plan for: revise workflow

    **Workflow-Specific Context**:
    - Existing Plan Path: ${EXISTING_PLAN_PATH}
    - Backup Path: ${BACKUP_PATH}
    - Revision Details: ${REVISION_DETAILS}
    - Research Reports: ${REPORT_PATHS_JSON}
    - Workflow Type: research-and-revise
    - Operation Mode: plan revision
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}

    **Project Standards** (from CLAUDE.md):
    ${FORMATTED_STANDARDS}

    **CRITICAL INSTRUCTIONS FOR PLAN REVISION**:
    1. Use STEP 1-REV → STEP 2-REV → STEP 3-REV → STEP 4-REV workflow (revision flow)
    2. Create backup at ${BACKUP_PATH} BEFORE making any changes
    3. Use Edit tool (NEVER Write) for all modifications to existing plan file
    4. Preserve all [COMPLETE] phases unchanged (do not modify completed work)
    5. Update plan metadata (Date, Estimated Hours, Phase count) to reflect revisions

    Execute plan revision according to behavioral guidelines and return completion signal:
    PLAN_REVISED: ${EXISTING_PLAN_PATH}
  "
}
```

#### Task 3.3: Enhance Block 5c with Backup and Modification Verification
**File**: `.claude/commands/revise.md`
**Location**: Block 5c (Plan Revision Phase Verification)

Add comprehensive verification:
```bash
# Re-source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || exit 1

# Load workflow state
WORKFLOW_ID=$(cat "${CLAUDE_PROJECT_DIR}/.claude/tmp/revise_state_id.txt")
load_workflow_state "$WORKFLOW_ID" false

echo "Expected backup path: $BACKUP_PATH"

# HARD BARRIER: Backup file MUST exist
if [ ! -f "$BACKUP_PATH" ]; then
  log_command_error "/revise" "$WORKFLOW_ID" "$USER_ARGS" \
    "agent_error" \
    "plan-architect failed to create backup before modification" \
    "bash_block_5c" \
    "$(jq -n --arg expected "$BACKUP_PATH" '{expected_backup: $expected}')"

  echo "ERROR: HARD BARRIER FAILED - Backup not found: $BACKUP_PATH" >&2
  echo "DIAGNOSTIC: plan-architect must create backup in STEP 1-REV" >&2
  exit 1
fi

# Validate plan was actually modified (not identical to backup)
if cmp -s "$EXISTING_PLAN_PATH" "$BACKUP_PATH"; then
  log_command_error "/revise" "$WORKFLOW_ID" "$USER_ARGS" \
    "agent_error" \
    "plan-architect created backup but made no modifications to plan" \
    "bash_block_5c" \
    "$(jq -n --arg plan "$EXISTING_PLAN_PATH" --arg backup "$BACKUP_PATH" \
       '{plan_path: $plan, backup_path: $backup, status: "identical"}')"

  echo "ERROR: HARD BARRIER FAILED - Plan unchanged after revision" >&2
  echo "DIAGNOSTIC: Plan file identical to backup (no modifications made)" >&2
  exit 1
fi

# Validate plan file size is reasonable
PLAN_SIZE=$(wc -c < "$EXISTING_PLAN_PATH" 2>/dev/null || echo 0)
if [ "$PLAN_SIZE" -lt 500 ]; then
  log_command_error "/revise" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" \
    "Revised plan suspiciously small ($PLAN_SIZE bytes)" \
    "bash_block_5c" \
    "$(jq -n --argjson size "$PLAN_SIZE" '{plan_size_bytes: $size}')"
  echo "ERROR: Revised plan too small: $PLAN_SIZE bytes" >&2
  exit 1
fi

echo "[CHECKPOINT] Hard barrier passed: Plan revision validated"
echo "Backup path: $BACKUP_PATH"
echo "Plan path: $EXISTING_PLAN_PATH"
echo "Plan size: $PLAN_SIZE bytes"
```

---

## Phase 4: Validation and Testing [COMPLETE]

**Objective**: Verify hard barrier enforcement prevents workflow bypass

**Success Criteria**:
- [x] Task invocation linter passes (0 violations)
- [x] Hard barrier compliance validator passes (100% compliance)
- [x] Integration test validates full workflow execution
- [x] Negative test confirms bypass prevention
- [x] Error logging integration confirmed

### Tasks

#### Task 4.1: Run Task Invocation Pattern Linter
**Command**:
```bash
bash .claude/scripts/lint-task-invocation-pattern.sh .claude/commands/revise.md
```

**Expected Output**: 0 violations (all Task blocks have imperative directives)

**Validation Targets**:
- Block 4b: Has "**EXECUTE NOW**: USE the Task tool..." directive
- Block 5b: Has "**EXECUTE NOW**: USE the Task tool..." directive
- No naked Task blocks without imperative directives
- No instructional text patterns without Task invocation

#### Task 4.2: Run Hard Barrier Compliance Validator
**Command**:
```bash
bash .claude/scripts/validate-hard-barrier-compliance.sh --command revise --verbose
```

**Expected Output**: 100% compliance

**Validation Targets**:
- Na/Nb/Nc block structure present for both research and plan phases
- CRITICAL BARRIER labels present on all Execute blocks
- Fail-fast verification (exit 1) present in all Verify blocks
- Path pre-calculation present in all Setup blocks

#### Task 4.3: Create Integration Test
**File**: `.claude/tests/integration/test_revise_hard_barriers.sh`

**Test Scenario**:
```bash
#!/usr/bin/env bash

# Test: /revise command hard barrier enforcement

set -euo pipefail

# Setup test environment
TEST_PLAN="/tmp/test_revise_plan.md"
echo "# Test Plan" > "$TEST_PLAN"

# Test 1: Validate state machine barrier
# (Simulate Block 3 failure - state ID file missing)
rm -f "${CLAUDE_PROJECT_DIR}/.claude/tmp/revise_state_id.txt"

# Run command - should fail at Block 3a
if /revise "revise plan at $TEST_PLAN based on test requirements"; then
  echo "FAIL: Block 3a did not prevent progression with missing state ID"
  exit 1
fi

# Test 2: Validate research barrier
# (Simulate Block 4b failure - report not created)
# Create state ID file but delete expected report path
echo "test_workflow_123" > "${CLAUDE_PROJECT_DIR}/.claude/tmp/revise_state_id.txt"

# Mock research-specialist to skip file creation
# Run command - should fail at Block 4c
if /revise "revise plan at $TEST_PLAN based on test requirements"; then
  echo "FAIL: Block 4c did not prevent progression with missing report"
  exit 1
fi

# Test 3: Validate plan revision barrier
# (Simulate Block 5b failure - no backup created)
# Mock plan-architect to skip backup creation
# Run command - should fail at Block 5c
if /revise "revise plan at $TEST_PLAN based on test requirements"; then
  echo "FAIL: Block 5c did not prevent progression with missing backup"
  exit 1
fi

echo "PASS: All hard barriers enforced successfully"
```

**Execution**:
```bash
automation_type: automated
validation_method: programmatic
skip_allowed: false
artifact_outputs:
  - test_revise_hard_barriers.log
  - test_revise_hard_barriers.xml (JUnit format)
```

#### Task 4.4: Create Negative Test (Bypass Prevention)
**File**: `.claude/tests/integration/test_revise_bypass_prevention.sh`

**Test Scenario**:
```bash
#!/usr/bin/env bash

# Test: Verify /revise cannot bypass research/planning phases

set -euo pipefail

TEST_PLAN="/tmp/test_bypass_plan.md"
echo "# Test Plan" > "$TEST_PLAN"

# Attempt to bypass workflow by:
# 1. Running command with valid arguments
# 2. Monitoring for direct Edit tool calls without research-specialist delegation

OUTPUT=$(/revise "revise plan at $TEST_PLAN based on simple change" 2>&1)

# Check for bypass indicators
if echo "$OUTPUT" | grep -q "Since this is a simple, focused revision"; then
  echo "FAIL: Agent attempted workflow bypass (justification text detected)"
  exit 1
fi

if echo "$OUTPUT" | grep -q "can make the edit directly"; then
  echo "FAIL: Agent bypassed research-specialist delegation"
  exit 1
fi

# Check for hard barrier checkpoints
if ! echo "$OUTPUT" | grep -q "\[CHECKPOINT\] Hard barrier passed: State machine initialized"; then
  echo "FAIL: State machine barrier not executed"
  exit 1
fi

if ! echo "$OUTPUT" | grep -q "\[CHECKPOINT\] Hard barrier passed: Research report validated"; then
  echo "FAIL: Research barrier not executed"
  exit 1
fi

if ! echo "$OUTPUT" | grep -q "\[CHECKPOINT\] Hard barrier passed: Plan revision validated"; then
  echo "FAIL: Plan revision barrier not executed"
  exit 1
fi

echo "PASS: Workflow bypass prevention validated"
```

#### Task 4.5: Validate Error Logging Integration
**Command**:
```bash
# Trigger a verification failure
/revise "revise plan at /nonexistent/plan.md based on test" 2>&1

# Query error log
/errors --command /revise --since 5m --limit 1
```

**Expected Output**:
- Error logged with type `agent_error` or `validation_error`
- Error message contains "HARD BARRIER FAILED"
- Error context includes expected artifact path
- Diagnostic information included (e.g., "Block 4c should have...")

---

## Phase 5: Documentation Updates [COMPLETE]

**Objective**: Document hard barrier implementation and troubleshooting guidance

**Success Criteria**:
- [x] Command guide updated with hard barrier pattern notes
- [x] Troubleshooting section added for verification failures
- [x] CLAUDE.md updated with enforcement mechanism cross-references
- [x] Pattern documentation includes /revise as case study

### Tasks

#### Task 5.1: Update revise-command-guide.md
**File**: `.claude/docs/guides/commands/revise-command-guide.md`

**Sections to Add**:

1. **Hard Barrier Architecture** section:
```markdown
## Hard Barrier Architecture

The /revise command implements the 3-block hard barrier pattern to enforce mandatory agent delegation:

- **Block 3a**: State machine initialization verification (prevents progression without state)
- **Block 4a-4c**: Research phase hard barrier (Na: setup, Nb: execute, Nc: verify)
- **Block 5a-5c**: Plan revision phase hard barrier (Na: setup, Nb: execute, Nc: verify)

Each verification block performs fail-fast validation with `exit 1` on missing artifacts.
```

2. **Troubleshooting Verification Failures** section:
```markdown
## Troubleshooting Verification Failures

### State Machine Barrier (Block 3a)

**Error**: "HARD BARRIER FAILED - State machine not initialized"

**Cause**: Block 3 did not execute or failed to create state ID file

**Recovery**:
1. Check Block 3 output for errors
2. Verify state-persistence.sh library sourced successfully
3. Re-run command from beginning

### Research Barrier (Block 4c)

**Error**: "HARD BARRIER FAILED - Report file not found anywhere"

**Cause**: research-specialist agent did not create report at expected path

**Recovery**:
1. Query error log: `/errors --command /revise --since 1h`
2. Check research-specialist was invoked (look for Block 4b output)
3. Verify EXPECTED_REPORT_PATH was calculated correctly in Block 4a
4. Re-run command with increased verbosity

### Plan Revision Barrier (Block 5c)

**Error**: "HARD BARRIER FAILED - Plan unchanged after revision"

**Cause**: plan-architect created backup but made no modifications

**Recovery**:
1. Check plan-architect output for revision logic
2. Verify revision details are clear and actionable
3. Manually inspect plan to confirm changes needed
4. Re-run with more specific revision instructions
```

#### Task 5.2: Update CLAUDE.md Command Reference
**File**: `/home/benjamin/.config/CLAUDE.md`
**Section**: `<!-- SECTION: project_commands -->`

Add cross-reference to enforcement mechanisms:
```markdown
**Command Execution Standards**:
- All orchestrator commands use hard barrier pattern for agent delegation
- Task invocations use imperative directives ("**EXECUTE NOW**: USE the Task tool...")
- Verification blocks enforce fail-fast policy (exit 1 on missing artifacts)
- See [Hard Barrier Subagent Delegation Pattern](.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md)
```

#### Task 5.3: Update Hard Barrier Pattern Documentation
**File**: `.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md`

Add /revise as Case Study:
```markdown
## Case Study: /revise Command

The /revise command implements dual hard barriers for research and plan revision phases:

**Research Phase Hard Barrier (Blocks 4a-4c)**:
- Block 4a: Pre-calculates `EXPECTED_REPORT_PATH` from revision details
- Block 4b: Invokes research-specialist with imperative directive and path contract
- Block 4c: Validates report at exact path, exits 1 if missing or too small

**Plan Revision Phase Hard Barrier (Blocks 5a-5c)**:
- Block 5a: Pre-calculates `BACKUP_PATH` with timestamp
- Block 5b: Invokes plan-architect with backup path contract
- Block 5c: Validates backup exists AND plan was modified, exits 1 if unchanged

**Key Success Factor**: Path pre-calculation enables exact validation (not searching), making bypass structurally impossible.
```

---

## Dependencies

**External Dependencies**:
- None (all changes internal to .claude/ infrastructure)

**Internal Dependencies**:
- Phase 2 depends on Phase 1 (state machine must be validated before research phase)
- Phase 3 depends on Phase 2 (research must complete before plan revision)
- Phase 4 depends on Phases 1-3 (tests validate all hard barriers)

**Library Dependencies**:
- `state-persistence.sh` (already integrated)
- `error-handling.sh` (already integrated)
- `workflow-state-machine.sh` (already integrated)

---

## Testing Strategy

### Unit Testing
- **Linter Validation**: Verify Task invocation patterns comply with standards
- **Compliance Check**: Verify Na/Nb/Nc structure present for all agent delegations

### Integration Testing
- **Full Workflow Test**: Execute /revise end-to-end and validate all checkpoints
- **Bypass Prevention Test**: Verify hard barriers prevent skipping workflow phases
- **Error Logging Test**: Confirm failures queryable via /errors command

### Negative Testing
- **Missing State File**: Verify Block 3a exits 1 when state not initialized
- **Missing Research Report**: Verify Block 4c exits 1 when report not created
- **Missing Backup**: Verify Block 5c exits 1 when backup not created
- **Unchanged Plan**: Verify Block 5c exits 1 when plan identical to backup

### Automation Compliance
All tests use non-interactive testing standard:
- `automation_type: automated`
- `validation_method: programmatic`
- `skip_allowed: false`
- `artifact_outputs: [test_results.xml, test_logs.txt]`

---

## Rollout Plan

### Pre-Deployment
1. Run linter validation on modified command file
2. Run compliance check for hard barrier pattern
3. Execute unit tests for path calculation logic

### Deployment
1. Apply changes to `.claude/commands/revise.md`
2. Validate file syntax (no markdown or bash errors)
3. Run integration tests in isolated environment

### Post-Deployment
1. Execute full workflow test with real plan
2. Monitor error log for verification failures
3. Query `/errors --command /revise` to confirm logging
4. Update documentation with lessons learned

### Rollback Plan
If hard barriers cause false positives:
1. Revert to previous revise.md version
2. Analyze error logs for root cause
3. Adjust path calculation logic or verification thresholds
4. Re-test before re-deployment

---

## Success Metrics

### Functional Metrics
- **Bypass Prevention**: 100% of workflow executions invoke research-specialist and plan-architect (no direct edits)
- **Error Detection**: 100% of verification failures logged to error log
- **Checkpoint Reporting**: All 3 hard barrier checkpoints appear in command output

### Compliance Metrics
- **Linter Score**: 0 violations in `lint-task-invocation-pattern.sh`
- **Compliance Score**: 100% in `validate-hard-barrier-compliance.sh`
- **Test Pass Rate**: 100% (all integration and negative tests pass)

### Quality Metrics
- **False Positive Rate**: <5% (verification blocks reject valid artifacts)
- **False Negative Rate**: 0% (verification blocks allow missing artifacts)
- **Error Log Utility**: 100% of failures queryable via `/errors`

---

## Risk Assessment

### High Risk
**Risk**: Hard barrier false positives block valid workflow executions
**Mitigation**: Enhanced diagnostics in verification blocks (search alternate locations, report findings)
**Contingency**: Add diagnostic mode flag to skip verification for debugging

### Medium Risk
**Risk**: Path calculation logic doesn't match agent output paths
**Mitigation**: Path pre-calculation uses same logic as agents, contract enforced via prompt
**Contingency**: Add path validation utility function shared by command and agent

### Low Risk
**Risk**: Performance degradation from additional verification blocks
**Mitigation**: Verification blocks are lightweight (file existence checks, minimal I/O)
**Contingency**: None needed (verification overhead <100ms per phase)

---

## Maintenance Notes

### Future Enhancements
1. **Automated Compliance Testing**: Add pre-commit hook for hard barrier pattern validation
2. **Path Validation Utility**: Extract path calculation logic into shared library function
3. **Agent Contract Schema**: Formalize path contract format for agent invocations
4. **Enhanced Diagnostics**: Add debug mode for verbose verification output

### Known Limitations
1. **Manual Backup Cleanup**: Backup files accumulate in backups/ directory (no automatic cleanup)
2. **Single Research Report**: Current implementation supports one revision report per invocation
3. **No Partial Success Mode**: Verification is all-or-nothing (no graceful degradation)

### Deprecation Notes
None - This implementation introduces new features without deprecating existing functionality

---

## References

### Standards Documents
- [Command Authoring Standards](/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md)
- [Hard Barrier Subagent Delegation Pattern](/home/benjamin/.config/.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md)
- [Non-Interactive Testing Standard](/home/benjamin/.config/.claude/docs/reference/standards/non-interactive-testing-standard.md)
- [Error Handling Pattern](/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md)

### Reference Implementations
- [/create-plan Command](/home/benjamin/.config/.claude/commands/create-plan.md) - Working hard barrier implementation
- [/lean-plan Command](/home/benjamin/.config/.claude/commands/lean-plan.md) - Topic naming hard barrier example

### Research Reports
- [Root Cause Analysis](/home/benjamin/.config/.claude/specs/035_revise_command_workflow_state_fix/reports/001-root-cause-analysis.md)
- [Standards Compliance Fix](/home/benjamin/.config/.claude/specs/035_revise_command_workflow_state_fix/reports/002-standards-compliance-fix.md)

### Related Issues
- Spec 876: Bash conditional negation fixes (similar pattern violations)
- Spec 794: Output formatting standards (checkpoint reporting)
- Spec 756: Command execution directives (Task invocation patterns)
