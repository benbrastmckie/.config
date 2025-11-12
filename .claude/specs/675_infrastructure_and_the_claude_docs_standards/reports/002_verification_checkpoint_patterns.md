# Verification Checkpoint Patterns and Best Practices

## Metadata
- **Date**: 2025-11-11
- **Agent**: research-specialist
- **Topic**: Verification Checkpoint Patterns in .claude/ Infrastructure
- **Report Type**: Codebase analysis and pattern recognition
- **Complexity Level**: 2

## Executive Summary

Verification checkpoints are a critical infrastructure pattern in .claude/ orchestration commands that ensure 100% file creation reliability through fail-fast detection and diagnostic reporting. The pattern consists of three components: (1) path pre-calculation before agent invocation, (2) mandatory verification after file operations using standardized helper functions, and (3) detailed diagnostic output on failure. The verification-helpers.sh library provides `verify_file_created()` and `verify_state_variable()` functions that achieve 90% token reduction at checkpoints through concise success reporting (single ✓ character) and comprehensive failure diagnostics (38+ line reports). Integration with error-handling.sh and workflow-state-machine.sh enables state-aware error recovery with retry tracking (max 2 retries per state).

## 1. Purpose and Architecture

### 1.1 Primary Purpose

Verification checkpoints serve three critical functions:

1. **Fail-Fast Detection**: Immediately expose file creation failures rather than discovering them at workflow end
2. **Agent Accountability**: Verify agents created expected artifacts at expected paths
3. **Diagnostic Context**: Provide actionable troubleshooting when verification fails

**Reference**: `.claude/docs/concepts/patterns/verification-fallback.md:1-59`

### 1.2 Architectural Components

The verification checkpoint pattern integrates three library systems:

#### verification-helpers.sh (Primary Verification Library)
- **Location**: `.claude/lib/verification-helpers.sh` (371 lines)
- **Functions**:
  - `verify_file_created()` - File existence and content verification
  - `verify_state_variable()` - Single state variable verification
  - `verify_state_variables()` - Multiple state variable verification
- **Token Efficiency**: 90% reduction (3,150 tokens saved per workflow)
  - Success: Single ✓ character
  - Failure: 38-line diagnostic with Expected vs Actual, directory analysis, troubleshooting commands

**Reference**: `.claude/lib/verification-helpers.sh:1-371`

#### error-handling.sh (Error Recovery Integration)
- **Location**: `.claude/lib/error-handling.sh` (875 lines)
- **Function**: `handle_state_error()` - State-aware error handler with 5-component diagnostic format
- **Retry Tracking**: Max 2 retries per state (lines 820-823)
- **Components**:
  1. What failed
  2. Expected state/behavior
  3. Diagnostic commands
  4. Context (workflow, state, paths)
  5. Recommended action

**Reference**: `.claude/lib/error-handling.sh:740-851`

#### workflow-state-machine.sh (State Persistence)
- **Location**: `.claude/lib/workflow-state-machine.sh` (23,563 bytes)
- **Integration**: Completed states array persistence (lines 87-150)
- **Pattern**: GitHub Actions-style state files with JSON serialization
- **Atomic Operations**: Two-phase commit for state transitions

**Reference**: `.claude/lib/workflow-state-machine.sh:1-150`

### 1.3 Why Verification Checkpoints Matter

**Problem Solved**: Silent file creation failures cascade through multi-phase workflows.

**Before Pattern** (6-8/10 success rate):
```
Phase 1: Research → Agent believes file created
Phase 2: Planning → Reads report (SUCCESS)
Phase 3: Implementation → Reads plan (SUCCESS)
Phase 4: Testing → Reads implementation (FAILURE - file missing)
  ❌ Implementation log not found

Diagnosis time: 15 minutes reviewing logs
Root cause: Phase 3 agent tool failed silently
```

**After Pattern** (10/10 success rate):
```
Phase 1: Research → Agent creates report
  ✓ VERIFICATION: Report exists (15420 bytes)
Phase 2: Planning → Reads report (SUCCESS)
  ✓ VERIFICATION: Plan exists (8932 bytes)
Phase 3: Implementation → Reads plan (SUCCESS)
  ❌ VERIFICATION: Implementation log missing
  [38-line diagnostic with fix commands]

Diagnosis time: Immediate (verification checkpoint logs exact failure)
```

**Reference**: `.claude/docs/concepts/patterns/verification-fallback.md:397-434`

## 2. Core Functions and Usage Patterns

### 2.1 verify_file_created() - File Verification

#### Function Signature
```bash
verify_file_created <file_path> <item_desc> <phase_name>
```

#### Parameters
- `file_path` (required): Absolute path to file that should exist
- `item_desc` (required): Human-readable description (e.g., "Research report")
- `phase_name` (required): Phase identifier for error messages (e.g., "Phase 1")

#### Return Values
- `0` - File exists and has content (success)
- `1` - File missing or empty (failure)

#### Output Behavior

**Success Path** (90% token reduction):
```bash
verify_file_created "$REPORT_PATH" "Research report" "Phase 1"
# Output: ✓
# Return: 0
```

**Failure Path** (38-line diagnostic):
```
✗ ERROR [Phase 1]: Research report verification failed

Expected vs Actual:
  Expected path: /path/to/report.md
  Expected filename: 001_report.md

  Status: File does not exist

Directory Analysis:
  Parent directory: /path/to/reports
  Directory status: ✓ Exists (3 files)

  Files found in directory:
     - 002_other.md (size: 1024, modified: Nov 11 10:30)
     - 003_another.md (size: 2048, modified: Nov 11 10:35)

  Possible causes:
    1. Agent created descriptive filename instead of generic name
    2. Dynamic path discovery executed after verification
    3. State persistence incomplete (REPORT_PATHS array not populated)

TROUBLESHOOTING:
  1. List actual files created:
     Command: ls -la /path/to/reports

  2. Check agent completion signals:
     Command: grep -r "REPORT_CREATED:" "${CLAUDE_PROJECT_DIR}/.claude/tmp/"

  3. Verify dynamic discovery executed:
     Command: grep -A 10 "Dynamic Report Path Discovery" ...
```

**Reference**: `.claude/lib/verification-helpers.sh:73-170`

### 2.2 verify_state_variable() - Single Variable Verification

#### Function Signature
```bash
verify_state_variable <var_name>
```

#### Parameters
- `var_name` (required): Variable name to verify (without $ prefix)

#### Dependencies
- Requires `STATE_FILE` environment variable to be set
- Expects state file format: `export VAR_NAME="value"`

#### Usage Pattern
```bash
# After state initialization
verify_state_variable "WORKFLOW_SCOPE" || {
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not persisted to state" 1
}
```

#### Common Use Cases

**1. After sm_init() - Verify critical workflow variables**
```bash
sm_init "$WORKFLOW_DESCRIPTION" "coordinate"
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
verify_state_variable "WORKFLOW_SCOPE" || exit 1
```

**Location**: `.claude/commands/coordinate.md:155-157`

**2. After conditional variable assignment - research-and-revise scope**
```bash
if [ -n "${EXISTING_PLAN_PATH:-}" ]; then
  append_workflow_state "EXISTING_PLAN_PATH" "$EXISTING_PLAN_PATH"
  verify_state_variable "EXISTING_PLAN_PATH" || exit 1
fi
```

**Location**: `.claude/commands/coordinate.md:163-166`

**3. After array export - verify count variable**
```bash
append_workflow_state "REPORT_PATHS_COUNT" "$REPORT_PATHS_COUNT"
verify_state_variable "REPORT_PATHS_COUNT" || {
  handle_state_error "CRITICAL: REPORT_PATHS_COUNT not persisted" 1
}
```

**Location**: `.claude/commands/coordinate.md:237-239`

**Reference**: `.claude/lib/verification-helpers.sh:223-280`

### 2.3 verify_state_variables() - Multiple Variable Verification

#### Function Signature
```bash
verify_state_variables <state_file> <var_name_1> [var_name_2] ...
```

#### Parameters
- `state_file` (required): Path to workflow state file
- `var_names` (variadic): List of variable names to verify

#### Output Behavior

**Success** (concise):
```bash
verify_state_variables "$STATE_FILE" REPORT_PATHS_COUNT REPORT_PATH_0 REPORT_PATH_1
# Output: ✓
# Return: 0
```

**Failure** (detailed diagnostic):
```
✗ ERROR: State variable verification failed
   Expected: 3 variables in state file
   Found: 2 variables

MISSING VARIABLES:
  ❌ REPORT_PATH_1

DIAGNOSTIC INFORMATION:
  - State file: /path/to/state.sh
  - File size: 1024 bytes
  - Variables in file: 2

TROUBLESHOOTING:
  1. Check append_workflow_state() was called for each variable
  2. Verify set +H directive present (prevents bad substitution)
  3. Check file permissions on state file directory

State file contents (first 20 lines):
  export REPORT_PATHS_COUNT="2"
  export REPORT_PATH_0="/path/to/report_0.md"
```

#### Usage Pattern in /coordinate
```bash
# Build variable list
VARS_TO_CHECK=("REPORT_PATHS_COUNT")
for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
  VARS_TO_CHECK+=("REPORT_PATH_$i")
done

# Concise verification
echo -n "Verifying state persistence ($((REPORT_PATHS_COUNT + 1)) vars): "
if verify_state_variables "$STATE_FILE" "${VARS_TO_CHECK[@]}"; then
  echo " verified"
else
  handle_state_error "State persistence verification failed" 1
fi
```

**Location**: `.claude/commands/coordinate.md:268-283`

**Reference**: `.claude/lib/verification-helpers.sh:302-370`

## 3. When and Where to Place Verification Checkpoints

### 3.1 Mandatory Checkpoint Locations

#### After Agent Invocations (File Creation Expected)
```bash
# 1. Invoke agent via Task tool
Task {
  prompt: "Read: .claude/agents/research-specialist.md
           Output: $REPORT_PATH
           Return: REPORT_CREATED: <path>"
}

# 2. MANDATORY VERIFICATION immediately after
verify_file_created "$REPORT_PATH" "Research report" "Phase 1" || {
  handle_state_error "Research report not created" 1
}
```

**Example Location**: `/coordinate` research phase (lines 490-520)

#### After State Persistence Operations
```bash
# 1. Append to state
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"

# 2. MANDATORY VERIFICATION immediately after
verify_state_variable "WORKFLOW_SCOPE" || {
  handle_state_error "WORKFLOW_SCOPE not persisted" 1
}
```

**Example Location**: `/coordinate` initialization (lines 155-157)

#### After Array Exports to State
```bash
# 1. Export array elements individually
for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
  append_workflow_state "REPORT_PATH_$i" "${REPORT_PATHS[$i]}"
done
append_workflow_state "REPORT_PATHS_COUNT" "$REPORT_PATHS_COUNT"

# 2. MANDATORY VERIFICATION for all variables
verify_state_variables "$STATE_FILE" "${VARS_TO_CHECK[@]}" || {
  handle_state_error "State persistence verification failed" 1
}
```

**Example Location**: `/coordinate` initialization (lines 268-283)

### 3.2 Checkpoint Timing (Relative to Library Sourcing)

**CRITICAL PATTERN**: verification-helpers.sh MUST be sourced BEFORE verification functions are called.

#### Correct Pattern (Bash Block Execution Model)
```bash
# Bash Block N
# Re-source libraries (functions lost across bash block boundaries)
source "${LIB_DIR}/verification-helpers.sh"

# NOW verification functions are available
verify_file_created "$REPORT_PATH" "Report" "Phase 1"
```

**Location**: `/coordinate` research phase (lines 337-338)

#### Why Re-Sourcing is Required

**Subprocess Isolation Constraint**: Each bash block runs in separate process.

**Consequence**: Function definitions don't persist across blocks.

**Solution**: Re-source library at start of each bash block that uses verification functions.

**Reference**: `.claude/docs/concepts/bash-block-execution-model.md:273-283`

### 3.3 Verified Pattern from /coordinate

The `/coordinate` command demonstrates canonical checkpoint placement:

#### Phase 0 (Initialization)
```bash
# Line 155: After sm_init()
verify_state_variable "WORKFLOW_SCOPE"

# Line 164: After conditional EXISTING_PLAN_PATH assignment
verify_state_variable "EXISTING_PLAN_PATH"

# Line 237: After REPORT_PATHS_COUNT export
verify_state_variable "REPORT_PATHS_COUNT"

# Lines 268-283: After all REPORT_PATH_N exports
verify_state_variables "$STATE_FILE" "${VARS_TO_CHECK[@]}"
```

#### Phase 1 (Research)
```bash
# After agent invocations complete (dynamic discovery pattern)
# Lines 490-520: Verify all discovered report files exist
```

**Reference**: `.claude/commands/coordinate.md:155-283,487-520`

## 4. Relationship to Error Handling and State Machine

### 4.1 Integration with handle_state_error()

Verification checkpoints typically chain to `handle_state_error()` on failure:

```bash
verify_state_variable "WORKFLOW_SCOPE" || {
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not persisted to state after sm_init" 1
}
```

**handle_state_error() provides 5-component diagnostic format**:

1. **What failed**: `✗ ERROR in state 'initialize': WORKFLOW_SCOPE not persisted`
2. **Expected behavior**: State machine initialization should save scope to state file
3. **Diagnostic commands**: `cat "$STATE_FILE"`, `bash -n workflow-state-machine.sh`
4. **Context**: Workflow description, scope, current state, topic path
5. **Recommended action**: Fix issue and retry (with retry count 1/2)

**Reference**: `.claude/lib/error-handling.sh:760-851`

### 4.2 Retry Tracking via State Machine

`handle_state_error()` increments retry counter per state:

```bash
# From error-handling.sh:820-823
RETRY_COUNT_VAR="RETRY_COUNT_${current_state}"
RETRY_COUNT=$(eval echo "\${${RETRY_COUNT_VAR}:-0}")
RETRY_COUNT=$((RETRY_COUNT + 1))
append_workflow_state "$RETRY_COUNT_VAR" "$RETRY_COUNT"
```

**Max Retry Enforcement** (lines 826-833):
```bash
if [ $RETRY_COUNT -ge 2 ]; then
  echo "Max retries (2) reached for state '$current_state'"
  echo "Workflow cannot proceed automatically"
else
  echo "Retry $RETRY_COUNT/2 available for state '$current_state'"
fi
```

**Reference**: `.claude/lib/error-handling.sh:820-841`

### 4.3 State Persistence Dependencies

Verification checkpoints depend on state persistence infrastructure:

#### Dependency Chain
```
verify_state_variable()
  ↓ requires
STATE_FILE environment variable
  ↓ set by
init_workflow_state()
  ↓ from
state-persistence.sh
  ↓ sourced by
coordinate.md initialization block
```

#### State File Format Dependency
```bash
# verify_state_variable() expects this exact format:
grep -q "^export ${var_name}=" "$STATE_FILE"

# append_workflow_state() produces this format:
echo "export ${key}=\"${value}\"" >> "$STATE_FILE"
```

**Critical**: Grep pattern `^export VAR_NAME=` matches state file format.

**Bug History**: Spec 644 discovered grep pattern mismatch (`^VAR_NAME=` failed to match `export VAR_NAME=`).

**Reference**: `.claude/specs/644_current_command_implementation_identify/reports/001_current_command_implementation_identify/002_verification_checkpoint_bug_patterns.md:1-100`

## 5. Token Reduction Benefits (90% at Checkpoints)

### 5.1 Quantified Metrics

**Per-Checkpoint Reduction**:
- **Before pattern** (inline verification): 38 lines × 6 tokens/line = 228 tokens
- **After pattern** (verify_file_created success): 1 character = 1 token
- **Reduction**: 227 tokens (99.6% on success path)

**Per-Workflow Reduction** (14 checkpoints typical):
- **Before**: 14 checkpoints × 228 tokens = 3,192 tokens
- **After**: 14 checkpoints × 1 token (success) = 14 tokens
- **Reduction**: 3,178 tokens (99.6%)

**Reference**: `.claude/lib/verification-helpers.sh:27-28`

### 5.2 Success vs Failure Output Asymmetry

The pattern achieves token reduction through **output asymmetry**:

**Success Path** (99% of cases):
- Single ✓ character
- No newline (allows multiple checks on one line: `✓✓✓`)
- Return code 0

**Failure Path** (1% of cases):
- 38-line diagnostic (Expected vs Actual, directory analysis, troubleshooting)
- Return code 1
- Workflow terminates (no additional context consumed)

**Design Rationale**: Successes should be silent, failures should be verbose.

**Reference**: `.claude/lib/verification-helpers.sh:78-170`

### 5.3 Comparison to Inline Verification

#### Inline Verification (Old Pattern)
```bash
# 38 lines of code repeated at every checkpoint
if [ -f "$REPORT_PATH" ] && [ -s "$REPORT_PATH" ]; then
  echo "✓ Report file exists: $REPORT_PATH"
  FILE_SIZE=$(stat -f%z "$REPORT_PATH" 2>/dev/null || stat -c%s "$REPORT_PATH")
  echo "  File size: $FILE_SIZE bytes"
else
  echo "ERROR: Report file not found"
  echo "  Expected path: $REPORT_PATH"
  echo "  Expected filename: $(basename "$REPORT_PATH")"

  DIR="$(dirname "$REPORT_PATH")"
  if [ -d "$DIR" ]; then
    echo "  Directory exists: $DIR"
    FILE_COUNT=$(ls -1 "$DIR" 2>/dev/null | wc -l)
    echo "  Files in directory: $FILE_COUNT"

    if [ "$FILE_COUNT" -gt 0 ]; then
      echo "  Recent files:"
      ls -lht "$DIR" | head -6 | tail -n +2 | while IFS= read -r line; do
        filename=$(echo "$line" | awk '{print $NF}')
        size=$(echo "$line" | awk '{print $5}')
        date=$(echo "$line" | awk '{print $6, $7, $8}')
        echo "    - $filename (size: $size, modified: $date)"
      done
    fi
  else
    echo "  Directory does not exist: $DIR"
    echo "  Fix: mkdir -p $DIR"
  fi

  echo ""
  echo "TROUBLESHOOTING:"
  echo "  1. List actual files: ls -la $DIR"
  echo "  2. Check agent signals: grep -r 'REPORT_CREATED:' ..."
  echo "  3. Check state: cat \$STATE_FILE"

  exit 1
fi
```

**Token Cost**: 228 tokens per checkpoint

#### Function-Based Verification (New Pattern)
```bash
verify_file_created "$REPORT_PATH" "Research report" "Phase 1" || exit 1
```

**Token Cost**: 1 token on success (✓), 228 tokens on failure

**Reduction**: 227 tokens per success checkpoint (99.6%)

## 6. Integration with State Machine Error Handling

### 6.1 State-Aware Error Messages

`handle_state_error()` provides context-aware diagnostics based on `CURRENT_STATE`:

```bash
case "$current_state" in
  research)
    echo "  - All research agents should complete successfully"
    echo "  - All report files created in \$TOPIC_PATH/reports/"
    ;;
  plan)
    echo "  - Implementation plan created successfully"
    echo "  - Plan file created in \$TOPIC_PATH/plans/"
    ;;
  implement|test|debug|document)
    echo "  - State '$current_state' should complete without errors"
    echo "  - Workflow should transition to next valid state"
    ;;
esac
```

**Reference**: `.claude/lib/error-handling.sh:772-788`

### 6.2 Workflow Context in Error Reports

Error messages include full workflow context:

```bash
echo "Context:"
echo "  - Workflow: ${WORKFLOW_DESCRIPTION:-<not set>}"
echo "  - Scope: ${WORKFLOW_SCOPE:-<not set>}"
echo "  - Current State: $current_state"
echo "  - Terminal State: ${TERMINAL_STATE:-<not set>}"
echo "  - Topic Path: ${TOPIC_PATH:-<not set>}"
```

**Benefits**:
- User knows exact workflow that failed
- Scope clarifies expected terminal state
- Topic path enables artifact inspection

**Reference**: `.claude/lib/error-handling.sh:805-811`

### 6.3 Retry Counter Integration

Verification failures increment state-specific retry counters:

```bash
# From handle_state_error()
RETRY_COUNT_VAR="RETRY_COUNT_${current_state}"
RETRY_COUNT=$(eval echo "\${${RETRY_COUNT_VAR}:-0}")
RETRY_COUNT=$((RETRY_COUNT + 1))
append_workflow_state "$RETRY_COUNT_VAR" "$RETRY_COUNT"
```

**Saved to State**: `export RETRY_COUNT_research="1"`

**Persists Across**: Bash block boundaries (via state-persistence.sh)

**Enforces**: Max 2 retries per state before escalation

**Reference**: `.claude/lib/error-handling.sh:820-823`

## 7. Common Patterns and Anti-Patterns

### 7.1 Correct Patterns

#### Pattern 1: Immediate Verification After File Creation
```bash
# CORRECT: Verify immediately after agent invocation
Task { /* invoke research-specialist */ }

verify_file_created "$REPORT_PATH" "Research report" "Phase 1" || {
  handle_state_error "Research report not created" 1
}
```

**Why Correct**: Fail-fast at exact failure point.

#### Pattern 2: Source Libraries Before Verification
```bash
# CORRECT: Re-source at bash block start
source "${LIB_DIR}/verification-helpers.sh"

verify_file_created "$REPORT_PATH" "Report" "Phase 1"
```

**Why Correct**: Functions available in current subprocess.

#### Pattern 3: Chain to handle_state_error()
```bash
# CORRECT: State-aware error handling
verify_state_variable "WORKFLOW_SCOPE" || {
  handle_state_error "WORKFLOW_SCOPE not persisted" 1
}
```

**Why Correct**: Provides 5-component diagnostic + retry tracking.

### 7.2 Anti-Patterns

#### Anti-Pattern 1: Verification Without Fallback
```bash
# WRONG: Detects failure but doesn't handle it
verify_file_created "$REPORT_PATH" "Report" "Phase 1"
# [File not found]
# [Workflow continues anyway]
```

**Why Wrong**: Silent failure - next phase fails with unclear error.

**Fix**: Chain to error handler via `|| exit 1` or `|| handle_state_error`.

#### Anti-Pattern 2: Late Path Calculation
```bash
# WRONG: Path calculated during agent execution
Task {
  prompt: "Research topic and save report somewhere in specs/"
}

# [Agent decides path - orchestrator doesn't know where to verify]
verify_file_created "$UNKNOWN_PATH" "Report" "Phase 1"
```

**Why Wrong**: Cannot verify unknown path.

**Fix**: Pre-calculate all paths before agent invocation.

#### Anti-Pattern 3: Verification Before Library Sourcing
```bash
# WRONG: Function not available
verify_file_created "$REPORT_PATH" "Report" "Phase 1"
# bash: verify_file_created: command not found

source "${LIB_DIR}/verification-helpers.sh"
```

**Why Wrong**: Subprocess isolation - function undefined.

**Fix**: Source library before calling functions.

**Reference**: `.claude/docs/concepts/bash-block-execution-model.md:416-441`

#### Anti-Pattern 4: Inline Exit Without State Error Handler
```bash
# WRONG: No retry tracking, no workflow context
verify_file_created "$REPORT_PATH" "Report" "Phase 1" || exit 1
```

**Why Wrong**: User gets no context, no retry counter, no state saved.

**Fix**: Use `handle_state_error()` for state-aware errors:
```bash
verify_file_created "$REPORT_PATH" "Report" "Phase 1" || {
  handle_state_error "Research report not created" 1
}
```

## 8. How Other Orchestration Commands Handle This

### 8.1 /coordinate (Production-Ready Pattern)

**Status**: Fully implemented verification checkpoints with state machine integration.

**Key Checkpoints**:
1. Line 155: `verify_state_variable "WORKFLOW_SCOPE"`
2. Line 164: `verify_state_variable "EXISTING_PLAN_PATH"` (conditional)
3. Line 237: `verify_state_variable "REPORT_PATHS_COUNT"`
4. Lines 268-283: `verify_state_variables` for all REPORT_PATH_N variables
5. Lines 490-520: File creation verification after research agents

**Integration**: All checkpoints chain to `handle_state_error()` for state-aware recovery.

**Reference**: `.claude/commands/coordinate.md:155-520`

### 8.2 /supervise (State Machine Transition)

**Status**: Migrated from phase-based to state-based (Nov 2025), verification pattern simplified.

**Pattern**: Direct Task tool invocation without explicit verification checkpoints in current version.

**Agent Delegation**: Relies on agent behavioral files to ensure file creation.

**Verification**: Implicit via state machine transitions (state transition fails if required files missing).

**Reference**: `.claude/commands/supervise.md:1-422`

### 8.3 /orchestrate (Experimental Features)

**Status**: In development, inconsistent checkpoint implementation.

**Pattern**: Similar to /coordinate but with additional dashboard tracking and PR automation features.

**Verification**: Uses verification-helpers.sh functions but checkpoint placement varies.

**Recommendation**: Use /coordinate for production workflows pending /orchestrate stabilization.

**Reference**: `.claude/commands/orchestrate.md:1-100`

## 9. Dependencies and Library Sourcing Order

### 9.1 Required Library Stack

Verification checkpoints require this sourcing order:

```bash
# 1. Project directory detection (first)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/detect-project-dir.sh"

# 2. State persistence (required by verification and error handling)
source "${LIB_DIR}/state-persistence.sh"

# 3. Workflow state machine (provides CURRENT_STATE for error handler)
source "${LIB_DIR}/workflow-state-machine.sh"

# 4. Error handling (provides handle_state_error)
source "${LIB_DIR}/error-handling.sh"

# 5. Verification helpers (provides verify_file_created, verify_state_variable)
source "${LIB_DIR}/verification-helpers.sh"
```

**Reference**: `.claude/commands/coordinate.md:330-337`

### 9.2 Cross-Block Re-Sourcing Pattern

Each bash block must re-source libraries:

```bash
# Bash Block 1 (Initialization)
source "${LIB_DIR}/verification-helpers.sh"
verify_state_variable "WORKFLOW_SCOPE"

# --- Bash block boundary (subprocess terminates) ---

# Bash Block 2 (Research)
# CRITICAL: Re-source library
source "${LIB_DIR}/verification-helpers.sh"
verify_file_created "$REPORT_PATH" "Report" "Phase 1"
```

**Why Required**: Bash block execution model - each block runs in separate process.

**Reference**: `.claude/docs/concepts/bash-block-execution-model.md:273-283`

### 9.3 Source Guards Prevent Duplication

Libraries use source guards to make re-sourcing safe:

```bash
# From verification-helpers.sh:11-14
if [ -n "${VERIFICATION_HELPERS_SOURCED:-}" ]; then
  return 0
fi
export VERIFICATION_HELPERS_SOURCED=1
```

**Benefit**: Re-sourcing same library in one subprocess is harmless.

**Reference**: `.claude/lib/verification-helpers.sh:11-14`

## 10. Recommendations

### 10.1 For New Orchestration Commands

1. **Always use verification-helpers.sh functions** - Don't implement inline verification
2. **Place checkpoints immediately after file operations** - Fail-fast at exact failure point
3. **Chain to handle_state_error() for state-aware recovery** - Provides retry tracking and workflow context
4. **Pre-calculate all paths before agent invocations** - Enables verification at known locations
5. **Re-source libraries at start of each bash block** - Subprocess isolation requires re-sourcing

### 10.2 For Existing Commands

1. **Audit checkpoint placement** - Ensure verification after every file creation
2. **Verify library sourcing order** - state-persistence → state-machine → error-handling → verification-helpers
3. **Check retry counter integration** - handle_state_error() should track retries per state
4. **Test failure paths** - Verify diagnostic output provides actionable troubleshooting

### 10.3 For Agent Behavioral Files

1. **Document expected file paths in agent prompts** - Pre-calculated paths injected via behavioral injection
2. **Return completion signals** - `REPORT_CREATED: /absolute/path/to/report.md`
3. **Use Write tool for file creation** - Don't rely on Bash tool echoing to files
4. **Verify file creation in agent steps** - Agent-level verification before returning

## References

### Implementation Files
- `.claude/lib/verification-helpers.sh` - Core verification functions (371 lines)
- `.claude/lib/error-handling.sh` - State-aware error handler (875 lines, handle_state_error at 740-851)
- `.claude/lib/workflow-state-machine.sh` - State machine with retry tracking (23,563 bytes)
- `.claude/lib/state-persistence.sh` - GitHub Actions-style state files (14,157 bytes)

### Working Examples
- `.claude/commands/coordinate.md` - Production-ready checkpoint pattern (lines 155-520)
- `.claude/commands/supervise.md` - State machine transition example (422 lines)

### Documentation
- `.claude/docs/concepts/patterns/verification-fallback.md` - Complete pattern documentation (448 lines)
- `.claude/docs/concepts/bash-block-execution-model.md` - Subprocess isolation constraints (273-441)
- `.claude/docs/guides/coordinate-command-guide.md` - /coordinate usage and checkpoint patterns (1438+ lines)

### Bug Analysis
- `.claude/specs/644_current_command_implementation_identify/reports/001_current_command_implementation_identify/002_verification_checkpoint_bug_patterns.md` - Grep pattern mismatch analysis (100+ lines)
- `.claude/specs/584_fix_coordinate_export_persistence/plans/001_fix_export_persistence.md` - Subprocess isolation fix (839 lines)
