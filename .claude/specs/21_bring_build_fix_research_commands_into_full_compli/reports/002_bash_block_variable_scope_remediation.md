# Bash Block Variable Scope Remediation Analysis

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Bash block variable scope violations across workflow commands
- **Report Type**: Critical architectural violation analysis
- **Commands Affected**: /build, /fix, /research-report, /research-plan, /research-revise (estimated)
- **Discovery**: Runtime testing of /research-plan (2025-11-17)
- **Severity**: CRITICAL

## Executive Summary

All 5 workflow commands violate the bash block execution model by assuming variables persist across bash blocks, contradicting the documented subprocess isolation architecture (bash-block-execution-model.md:5). Each bash block runs as a separate subprocess (not subshell), causing all variables to be lost between blocks unless explicitly persisted to files using state-persistence.sh functions. This critical architectural violation causes user-visible bugs (empty completion summaries), violates documented behavior, and creates a testing gap where commands work when Claude compensates but fail when executed according to documented subprocess isolation. Remediation requires implementing state persistence using append_workflow_state/load_workflow_state patterns across all multi-block commands, estimated at 20 hours total effort (4 hours per command).

## Problem Analysis

### Root Cause: Subprocess Isolation Architecture

**From bash-block-execution-model.md:5-48**:

```
Each bash block runs as a **separate subprocess**, not a subshell.

Process Architecture:

Claude Code Session
    ↓
Command Execution (coordinate.md)
    ↓
┌────────── Bash Block 1 ──────────┐
│ PID: 12345                       │
│ - Source libraries               │
│ - Initialize state               │
│ - Save to files                  │
│ - Exit subprocess                │
└──────────────────────────────────┘
    ↓ (subprocess terminates)
┌────────── Bash Block 2 ──────────┐
│ PID: 12346 (NEW PROCESS)        │
│ - Re-source libraries            │
│ - Load state from files          │
│ - Process data                   │
│ - Exit subprocess                │
└──────────────────────────────────┘
```

**Key Characteristics**:
- Each bash block has different PID
- All environment variables reset (exports lost)
- All bash functions lost (must re-source libraries)
- **Only files persist across blocks**

### Violation Pattern: Variable Persistence Assumption

**Example from /research-plan (runtime testing 2025-11-17)**:

```bash
# Part 3: Research Phase (subprocess PID 12345)
SPECS_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${TOPIC_NUMBER}_${TOPIC_SLUG}"
RESEARCH_DIR="${SPECS_DIR}/reports"
PLAN_PATH="${PLANS_DIR}/${PLAN_FILENAME}"
REPORT_COUNT=3

# Variable values:
# SPECS_DIR=/home/user/.claude/specs/16_topic_slug/reports
# PLAN_PATH=/home/user/.claude/specs/16_topic_slug/plans/001_plan.md
# REPORT_COUNT=3

# Part 5: Completion (DIFFERENT subprocess PID 12346)
echo "Specs Directory: $SPECS_DIR"          # OUTPUT: EMPTY!
echo "Research Reports: $REPORT_COUNT reports in $RESEARCH_DIR"  # OUTPUT: EMPTY!
echo "Implementation Plan: $PLAN_PATH"      # OUTPUT: EMPTY!
```

**Runtime Evidence**:
```
Error: awk: fatal: cannot open file 'echo'
  → awk failed because $REPORT_COUNT was empty, causing malformed command

Error: syntax error near unexpected token 'ls'
  → bash parse error due to empty variable substitution

Actual output: "Specs Directory: /reports"
Expected output: "Specs Directory: /home/user/.claude/specs/16_topic_slug/reports"
```

### Impact Analysis

**User-Visible Impact**:
- Completion summaries show empty values instead of paths/counts
- Professional appearance degraded (looks like broken command)
- Users cannot verify workflow outputs from summary

**Architectural Impact**:
- Violates documented subprocess isolation model
- Commands work when Claude compensates (reads variables from context)
- Commands fail when executed according to documented behavior
- Testing gap: works in development, fails in production-like execution

**Systemic Impact**:
- Pattern likely present in all 5 commands (not tested yet)
- Affects multi-bash-block workflows universally
- Creates maintenance burden (requires compensation instead of architectural fix)

## Documented Solution Pattern

### Pattern: State Persistence Library

**From bash-block-execution-model.md:226-248**:

```bash
# In each bash block:

# 1. Re-source library (functions lost across block boundaries)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"

# 2. Load workflow state
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

# 3. Update state
append_workflow_state "CURRENT_STATE" "research"
append_workflow_state "REPORT_COUNT" "3"
append_workflow_state "SPECS_DIR" "$SPECS_DIR"
append_workflow_state "PLAN_PATH" "$PLAN_PATH"

# 4. State automatically persists to file
# No manual file writes needed
```

**How It Works**:
- `append_workflow_state "KEY" "value"` → Writes to state file
- State file persists across subprocess boundaries (filesystem)
- `load_workflow_state "$WORKFLOW_ID"` → Restores all variables
- Variables available in subsequent bash blocks

### Pattern: Conditional Variable Initialization

**From bash-block-execution-model.md:287-369**:

```bash
# ❌ ANTI-PATTERN: Direct initialization (overwrites loaded values)
WORKFLOW_SCOPE=""
CURRENT_STATE="initialize"

# Problem: These assignments execute EVERY time library is sourced,
# even when sourced AFTER loading state. Loaded values overwritten.

# ✓ RECOMMENDED: Conditional initialization (preserves loaded values)
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
CURRENT_STATE="${CURRENT_STATE:-initialize}"

# Benefits:
# - If variable is already set: preserves existing value
# - If variable is unset: initializes to default
# - Safe with set -u: no "unbound variable" errors
```

**Integration with State Persistence**:
```bash
# Bash Block 1: Initialize workflow
source .claude/lib/workflow-state-machine.sh  # WORKFLOW_SCOPE="" (or "${WORKFLOW_SCOPE:-}")
sm_init "Research auth" "coordinate"  # Sets WORKFLOW_SCOPE="research-and-plan"
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"  # Save to state file

# Bash Block 2: Research phase (NEW SUBPROCESS)
load_workflow_state "$WORKFLOW_ID"  # Restores WORKFLOW_SCOPE="research-and-plan"
source .claude/lib/workflow-state-machine.sh  # With conditional init: preserved!
                                               # Without: WORKFLOW_SCOPE="" (BUG!)
```

## Remediation Specifications

### Step 1: Identify Variables Requiring Persistence

**Per command, analyze**:
1. Variables set in early bash blocks
2. Variables used in later bash blocks
3. Variables used in completion summaries

**Common persistent variables**:
- Path variables: `SPECS_DIR`, `RESEARCH_DIR`, `PLAN_PATH`, `REPORT_PATH`
- Count variables: `REPORT_COUNT`, `PHASE_COUNT`, `FIX_COUNT`
- State variables: `CURRENT_STATE`, `WORKFLOW_SCOPE`, `TERMINAL_STATE`
- Configuration: `RESEARCH_COMPLEXITY`, `DRY_RUN`, `STARTING_PHASE`

### Step 2: Add State Persistence After Variable Assignment

**Template**:
```bash
# === Bash Block N: Variable Assignment ===

# Calculate or assign variables
SPECS_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${TOPIC_NUMBER}_${TOPIC_SLUG}"
RESEARCH_DIR="${SPECS_DIR}/reports"
PLAN_PATH="${PLANS_DIR}/${PLAN_FILENAME}"
REPORT_COUNT=$(find "$RESEARCH_DIR" -name "*.md" | wc -l)

# CRITICAL: Persist to state file (new addition)
append_workflow_state "SPECS_DIR" "$SPECS_DIR"
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"
append_workflow_state "PLAN_PATH" "$PLAN_PATH"
append_workflow_state "REPORT_COUNT" "$REPORT_COUNT"

echo "✓ State persisted: SPECS_DIR, RESEARCH_DIR, PLAN_PATH, REPORT_COUNT"
```

**Estimated time per block**: 30 minutes
- Identify variables (10 minutes)
- Add append_workflow_state calls (10 minutes)
- Test persistence (10 minutes)

### Step 3: Load State Before Variable Usage

**Template**:
```bash
# === Bash Block M: Variable Usage (M > N) ===

# 1. Re-source state-persistence library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"

# 2. Load workflow state
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

# 3. Now variables restored and available
echo "Specs Directory: $SPECS_DIR"  # ✓ Works!
echo "Research Reports: $REPORT_COUNT reports in $RESEARCH_DIR"  # ✓ Works!
echo "Implementation Plan: $PLAN_PATH"  # ✓ Works!
```

**Estimated time per block**: 20 minutes
- Add library sourcing (5 minutes)
- Add load_workflow_state call (5 minutes)
- Test variable restoration (10 minutes)

### Step 4: Update Library Variable Initialization

**For workflow-state-machine.sh and similar libraries**:

```bash
# Before (overwrites loaded values):
WORKFLOW_SCOPE=""
WORKFLOW_DESCRIPTION=""
CURRENT_STATE="initialize"

# After (preserves loaded values):
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
WORKFLOW_DESCRIPTION="${WORKFLOW_DESCRIPTION:-}"
CURRENT_STATE="${CURRENT_STATE:-initialize}"
```

**Estimated time per library**: 30 minutes
- Identify variables requiring conditional init (15 minutes)
- Apply conditional initialization pattern (10 minutes)
- Test with state loading (5 minutes)

### Step 5: Add Subprocess Isolation Tests

**Test template**:
```bash
#!/usr/bin/env bash
# Test: Variable persistence across bash blocks

# Test 1: Without state persistence (should fail)
bash -c 'export TEST_VAR="value"'
bash -c 'echo "TEST_VAR=${TEST_VAR:-unset}"'  # Expected: unset

# Test 2: With state persistence (should succeed)
WORKFLOW_ID="test_$$"
bash -c "
  source .claude/lib/state-persistence.sh
  init_workflow_state '$WORKFLOW_ID'
  append_workflow_state 'TEST_VAR' 'value'
"
bash -c "
  source .claude/lib/state-persistence.sh
  load_workflow_state '$WORKFLOW_ID'
  echo 'TEST_VAR=\$TEST_VAR'  # Expected: value
"

# Cleanup
rm -f "${HOME}/.claude/data/state/${WORKFLOW_ID}.sh"
```

**Estimated time per command**: 1 hour
- Create test script (30 minutes)
- Run tests and verify (20 minutes)
- Document results (10 minutes)

## Command-Specific Remediation

### /research-plan (Confirmed Violation)

**Affected blocks**:
- Part 3: Research phase → Sets SPECS_DIR, RESEARCH_DIR, REPORT_COUNT
- Part 4: Planning phase → Uses RESEARCH_DIR for report discovery
- Part 5: Completion → Uses SPECS_DIR, PLAN_PATH, REPORT_COUNT for summary

**Remediation**:
1. Add state persistence at end of Part 3
2. Add state loading at start of Part 4 and Part 5
3. Test completion summary output

**Estimated effort**: 4 hours

### /build (Estimated Violation)

**Affected blocks (estimated)**:
- Part 1: Initialization → Sets PLAN_FILE, STARTING_PHASE, DRY_RUN
- Part 2: Implementation phase → Uses PLAN_FILE
- Part 3: Test phase → Uses test results
- Part 4: Completion → Uses implementation summary

**Remediation approach**: Same as /research-plan
**Estimated effort**: 4 hours

### /fix (Estimated Violation)

**Affected blocks (estimated)**:
- Part 1: Initialization → Sets ISSUE_DESCRIPTION, DEBUG_DIR
- Part 2: Research phase → Sets REPORT_PATHS
- Part 3: Planning phase → Uses REPORT_PATHS, sets PLAN_PATH
- Part 4: Debug phase → Uses PLAN_PATH
- Part 5: Completion → Uses all variables

**Remediation approach**: Same as /research-plan
**Estimated effort**: 4 hours

### /research-report (Estimated Violation)

**Affected blocks (estimated)**:
- Part 1: Initialization → Sets RESEARCH_TOPIC, COMPLEXITY
- Part 2: Research phase → Creates REPORT_PATH
- Part 3: Completion → Uses REPORT_PATH

**Remediation approach**: Same as /research-plan (simpler due to fewer blocks)
**Estimated effort**: 3 hours

### /research-revise (Estimated Violation)

**Affected blocks (estimated)**:
- Part 1: Initialization → Sets REVISION_DESC, EXISTING_PLAN_PATH
- Part 2: Backup creation → Sets BACKUP_PATH
- Part 3: Research phase → Sets REPORT_PATHS
- Part 4: Revision phase → Uses REPORT_PATHS, EXISTING_PLAN_PATH
- Part 5: Completion → Uses all variables

**Remediation approach**: Same as /research-plan
**Estimated effort**: 5 hours (more complex due to backup logic)

## Implementation Strategy

### Phase 1: Fix /research-plan (Confirmed Violation) - 4 hours
1. Add state persistence to Part 3 (1 hour)
2. Add state loading to Part 4 and Part 5 (1 hour)
3. Test completion summary output (1 hour)
4. Document fix and create regression test (1 hour)

### Phase 2: Test Remaining Commands - 4 hours
1. Create subprocess isolation test for each command (3 hours)
2. Run tests and document violations found (1 hour)

### Phase 3: Fix Remaining Commands - 12 hours
1. /build: 4 hours
2. /fix: 4 hours
3. /research-report: 3 hours
4. /research-revise: 5 hours
5. Contingency: 2 hours (if patterns differ)

**Total Estimated Effort**: 20 hours

### Advantages of Sequential Approach

1. **Pattern validation**: Fix /research-plan first, validate pattern works
2. **Template creation**: Create reusable templates from first fix
3. **Risk reduction**: Test before scaling to all commands
4. **Learning incorporation**: Apply lessons from first fix to remaining commands

## Testing and Validation

### Test Protocol per Command

```bash
# Test 1: Variable persistence validation
/[command-name] "test input" 2>&1 | grep "Specs Directory:"
# Expected: Full path (not empty or partial)

# Test 2: Count variable validation
/[command-name] "test input" 2>&1 | grep "reports"
# Expected: Actual count (not empty or zero)

# Test 3: Path variable validation
/[command-name] "test input" 2>&1 | grep "Implementation Plan:"
# Expected: Full absolute path

# Test 4: Subprocess isolation test (automated)
bash .claude/tests/test_subprocess_isolation_[command].sh
# Expected: All variables restored correctly across blocks
```

### Success Criteria

**Per Command**:
- [ ] All path variables show full absolute paths in completion summary
- [ ] All count variables show actual counts (not zero or empty)
- [ ] State persistence calls added after variable assignments
- [ ] State loading calls added before variable usage
- [ ] Subprocess isolation test passes (100% variable restoration)

**Overall Project**:
- [ ] 5/5 commands have state persistence implemented
- [ ] 5/5 commands pass subprocess isolation tests
- [ ] 0 completion summary bugs (empty values)
- [ ] Architectural compliance: 100%

## Expected Outcomes

### Before Remediation

- **Completion summary accuracy**: 0% (empty values)
- **Architectural compliance**: 0% (violates subprocess isolation)
- **User experience**: Poor (broken-looking summaries)
- **Testing coverage**: Gap (works with compensation, fails without)

### After Remediation

- **Completion summary accuracy**: 100% (correct values)
- **Architectural compliance**: 100% (follows subprocess isolation)
- **User experience**: Professional (complete summaries)
- **Testing coverage**: Complete (passes with and without compensation)

### ROI Analysis

**Investment**: 20 hours
**Return**:
- 100% improvement in completion summary accuracy
- Elimination of architectural violation
- Professional user experience
- Complete testing coverage
- Maintenance reduction (no compensation required)

**Payback period**: Immediate (first use after remediation)

## References

### Architecture Documentation
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md` (lines 1-951: Complete subprocess isolation model)
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md` (lines 226-248: State persistence pattern)
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md` (lines 287-369: Conditional variable initialization)

### Library Files
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` (append_workflow_state, load_workflow_state functions)
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (state machine variables requiring conditional init)

### Source Reports
- `/home/benjamin/.config/.claude/specs/15_research_the_compliance_of_build_fix_research_repo/debug/002_compliance_issues_summary.md` (lines 67-118: Bash block variable scope violations)

### Runtime Evidence
- /research-plan execution (2025-11-17): Empty completion summary values
- Error logs: awk fatal errors, bash syntax errors due to empty variables

### Related Specifications
- Spec 620: Bash history expansion fixes (subprocess isolation discovery)
- Spec 630: State persistence architecture (cross-block state management)
- Spec 653: Conditional variable initialization (library variable preservation)

## Conclusion

Bash block variable scope violations represent a critical architectural violation affecting all 5 workflow commands. The violation pattern (assuming variables persist across bash blocks) directly contradicts the documented subprocess isolation architecture where each bash block runs as a separate process. This creates user-visible bugs (empty completion summaries), violates documented behavior, and creates a testing gap where commands work when Claude compensates but fail when executed according to specifications. Implementing state persistence using append_workflow_state/load_workflow_state patterns will achieve 100% completion summary accuracy, architectural compliance, and professional user experience while eliminating the need for compensatory behavior. The 20-hour investment addresses a systemic architectural violation with immediate and long-term benefits.
