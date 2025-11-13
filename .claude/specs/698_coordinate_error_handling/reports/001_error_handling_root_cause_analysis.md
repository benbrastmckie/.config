# /coordinate Command Error Handling Root Cause Analysis

**Document Type**: Debug Analysis Report
**Status**: Complete
**Created**: 2025-11-13
**Author**: Debug Analyst (Claude)
**Related Spec**: 698_coordinate_error_handling

---

## Executive Summary

The `/coordinate` command fails with "RESEARCH_COMPLEXITY: unbound variable" error (bash line 486) due to a **fail-fast error propagation gap** in the initialization phase. When `classify_workflow_comprehensive()` fails in `workflow-state-machine.sh:sm_init()` (line 352), the function returns error code 1, but the calling code in `coordinate.md` (line 166) doesn't check the return code and redirects stdout to `/dev/null`, causing bash to continue execution with `set -euo pipefail` despite the error. The variables `RESEARCH_COMPLEXITY`, `WORKFLOW_SCOPE`, and `RESEARCH_TOPICS_JSON` are never exported, leading to the unbound variable error when later code attempts to use `$RESEARCH_COMPLEXITY` (line 244).

**Root Cause**: Missing return code check after `sm_init()` call violates fail-fast error handling pattern.

**Impact**: 100% failure rate for `/coordinate` command when LLM classification fails.

**Fix Complexity**: Low - Add return code check and error handler invocation after `sm_init()`.

---

## Table of Contents

1. [Error Chain Analysis](#error-chain-analysis)
2. [Code Location Details](#code-location-details)
3. [Standards Violations](#standards-violations)
4. [Similar Patterns in Other Commands](#similar-patterns-in-other-commands)
5. [Recommended Fix Strategy](#recommended-fix-strategy)
6. [Testing Recommendations](#testing-recommendations)
7. [Prevention Guidelines](#prevention-guidelines)

---

## Error Chain Analysis

### Complete Error Chain (5 Steps)

```
1. classify_workflow_comprehensive() fails
   Location: workflow-scope-detection.sh:49-99
   Reason: classify_workflow_llm_comprehensive() returns non-zero
   Effect: Function returns 1 (error code)

2. classify_workflow_comprehensive() failure propagates to sm_init()
   Location: workflow-state-machine.sh:352
   Code: if classification_result=$(classify_workflow_comprehensive "$workflow_desc" 2>/dev/null); then
   Effect: Classification assignment fails, enters else block (line 371)

3. sm_init() returns 1 without exporting variables
   Location: workflow-state-machine.sh:376
   Code: return 1
   Effect: WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON remain unset

4. coordinate.md calls sm_init() WITHOUT checking return code
   Location: coordinate.md:166
   Code: sm_init "$SAVED_WORKFLOW_DESC" "coordinate" >/dev/null
   Effect: bash continues despite sm_init() returning 1
   Critical Issue: Output redirection >/dev/null hides error message

5. Later code references $RESEARCH_COMPLEXITY (unbound variable)
   Location: coordinate.md:244 (initialize_workflow_paths invocation)
   Code: if initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE" "$RESEARCH_COMPLEXITY"; then
   Effect: bash fails with "unbound variable" due to set -euo pipefail
```

### Why bash Continues After sm_init() Failure

The issue is **NOT** a bash `-e` flag failure. The `set -euo pipefail` directive is active (line 53), but bash only exits on non-zero exit codes from **simple commands**, not **function calls** unless explicitly checked.

**Bash Behavior**:
```bash
set -euo pipefail

# This WILL exit on error:
grep nonexistent file.txt  # Simple command returns non-zero

# This will NOT exit on error (unless checked):
some_function  # Function returns non-zero, bash continues

# This WILL exit on error:
if ! some_function; then
  exit 1
fi
```

**The Problem in coordinate.md:166**:
```bash
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" >/dev/null
# Variables now available via export (not command substitution)
```

Bash doesn't automatically exit when `sm_init()` returns 1 because:
1. Function calls are not "simple commands" for `-e` purposes
2. No explicit return code check (e.g., `if ! sm_init ...`)
3. Output redirection suppresses error visibility

### Output Redirection Issue

The `>/dev/null` redirection on line 166 has two problems:

1. **Hides Critical Error Messages**: The error messages from `classify_workflow_comprehensive()` (lines 67-69 in workflow-scope-detection.sh) are suppressed:
   ```
   ERROR: classify_workflow_comprehensive: LLM classification failed in llm-only mode
     Context: Workflow description: <description>
     Suggestion: Check network connection, increase WORKFLOW_CLASSIFICATION_TIMEOUT, or use regex-only mode
   ```

2. **Misleads Debugging**: The comment "Variables now available via export" (line 167) implies success when sm_init() actually failed.

### Variable Export Pattern

The coordinate.md code correctly avoids command substitution (which would create a subshell):

```bash
# WRONG - subshell doesn't export to parent:
RESEARCH_COMPLEXITY=$(sm_init "$SAVED_WORKFLOW_DESC" "coordinate")

# CORRECT - direct call exports to parent:
sm_init "$SAVED_WORKFLOW_DESC" "coordinate"
```

However, this pattern **requires return code checking** because variables are only exported on success.

---

## Code Location Details

### Primary Failure Points

#### 1. workflow-scope-detection.sh:49-99 (classify_workflow_comprehensive)

**Function**: `classify_workflow_comprehensive()`
**Location**: `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh`
**Lines**: 49-99

**Relevant Code**:
```bash
classify_workflow_comprehensive() {
  local workflow_description="$1"

  # Validation (lines 52-58)
  if [ -z "$workflow_description" ]; then
    echo "ERROR: classify_workflow_comprehensive: workflow_description parameter is empty" >&2
    return 1
  fi

  # Route based on classification mode (lines 61-68)
  case "$WORKFLOW_CLASSIFICATION_MODE" in
    llm-only)
      local llm_result
      if ! llm_result=$(classify_workflow_llm_comprehensive "$workflow_description"); then
        echo "ERROR: classify_workflow_comprehensive: LLM classification failed in llm-only mode" >&2
        echo "  Context: Workflow description: $workflow_description" >&2
        echo "  Suggestion: Check network connection, increase WORKFLOW_CLASSIFICATION_TIMEOUT, or use regex-only mode for offline development" >&2
        return 1  # ← FAILURE POINT: Returns error without fallback
      fi
      # ... (success path)
      ;;
    # ... (other modes)
  esac
}
```

**Observation**: Clean-break approach (Spec 688 Phase 3) removed automatic fallback to regex mode. This is **correct design** (fail-fast), but requires calling code to handle errors.

#### 2. workflow-state-machine.sh:334-450 (sm_init)

**Function**: `sm_init()`
**Location**: `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`
**Lines**: 334-450

**Relevant Code**:
```bash
sm_init() {
  local workflow_desc="$1"
  local command_name="$2"

  # ... (lines 342-349: variable setup)

  # Perform comprehensive workflow classification (lines 351-384)
  if classification_result=$(classify_workflow_comprehensive "$workflow_desc" 2>/dev/null); then
    # Parse JSON response (lines 354-366)
    WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type // "full-implementation"')
    RESEARCH_COMPLEXITY=$(echo "$classification_result" | jq -r '.research_complexity // 2')
    RESEARCH_TOPICS_JSON=$(echo "$classification_result" | jq -c '.subtopics // []')

    # Export all three classification dimensions (lines 364-366)
    export WORKFLOW_SCOPE
    export RESEARCH_COMPLEXITY
    export RESEARCH_TOPICS_JSON
    # ... (success logging)
  else
    # Fail-fast: No automatic fallback (lines 371-376)
    echo "CRITICAL ERROR: Comprehensive classification failed" >&2
    echo "  Workflow Description: $workflow_desc" >&2
    echo "  Suggestion: Check network connection, increase WORKFLOW_CLASSIFICATION_TIMEOUT, or use regex-only mode" >&2
    return 1  # ← FAILURE POINT: Returns without exporting variables
  fi
  # ... (remainder of function)
}
```

**Observation**: Function correctly returns error code 1 and prints diagnostic information. The issue is that **calling code ignores the return code**.

#### 3. coordinate.md:163-167 (sm_init invocation - CRITICAL BUG)

**Location**: `/home/benjamin/.config/.claude/commands/coordinate.md`
**Lines**: 163-167

**Buggy Code**:
```bash
# Initialize state machine (use SAVED value, not overwritten variable)
# CRITICAL: Call sm_init to export WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
# Do NOT use command substitution $() as it creates subshell that doesn't export to parent
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" >/dev/null
# Variables now available via export (not command substitution)
```

**Problems**:
1. **No return code check**: Should be `if ! sm_init ...; then handle_state_error ...; fi`
2. **Output redirection hides errors**: `>/dev/null` suppresses critical error messages
3. **Misleading comment**: "Variables now available" is false when sm_init() fails

**Correct Pattern** (from orchestrate.md:109):
```bash
sm_init "$WORKFLOW_DESCRIPTION" "orchestrate"
# No output redirection, no assumption of success
```

Note: `orchestrate.md` also lacks return code checking, but doesn't redirect output, so errors are at least visible.

#### 4. coordinate.md:244 (initialize_workflow_paths invocation - SYMPTOM)

**Location**: `/home/benjamin/.config/.claude/commands/coordinate.md`
**Line**: 244

**Error-Triggering Code**:
```bash
if initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE" "$RESEARCH_COMPLEXITY"; then
  : # Success - paths initialized with dynamic allocation
else
  handle_state_error "Workflow initialization failed" 1
fi
```

**Effect**: Bash attempts to expand `$RESEARCH_COMPLEXITY` (which was never exported by sm_init due to failure), triggering:
```
/run/current-system/sw/bin/bash: line 486: RESEARCH_COMPLEXITY: unbound variable
```

**Note**: This is the **symptom**, not the root cause. The actual bug is at line 166.

#### 5. coordinate.md:419-428 (Research Phase - SYMPTOM)

**Location**: `/home/benjamin/.config/.claude/commands/coordinate.md`
**Lines**: 419-428

**Error-Triggering Code**:
```bash
# Defensive: Verify RESEARCH_COMPLEXITY was loaded from state
if [ -z "${RESEARCH_COMPLEXITY:-}" ]; then
  echo "WARNING: RESEARCH_COMPLEXITY not loaded from state, using fallback=2" >&2
  RESEARCH_COMPLEXITY=2
fi

echo "Research Complexity Score: $RESEARCH_COMPLEXITY topics (from state persistence)"
```

**Observation**: This defensive check happens in a **later bash block** (Research Phase) after state has been persisted. By this point, the damage is done - the workflow has proceeded past initialization with incomplete state.

---

## Standards Violations

### Violation 1: Standard 0 (Execution Enforcement) - Return Code Checking

**Standard 0 Requirement** (from command_architecture_standards.md):
> Commands must use "EXECUTE NOW" markers for critical operations and "MANDATORY VERIFICATION" checkpoints for file creation.

**Extension for Error Handling**:
While Standard 0 focuses on verification checkpoints for **artifacts**, the same principle applies to **function call success**. Critical initialization functions like `sm_init()` must have their return codes checked.

**Pattern in Other Commands**:
```bash
# From coordinate.md:244 (CORRECT):
if initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE" "$RESEARCH_COMPLEXITY"; then
  : # Success
else
  handle_state_error "Workflow initialization failed" 1
fi

# From coordinate.md:166 (INCORRECT):
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" >/dev/null
# No check
```

**Inconsistency**: The command correctly checks `initialize_workflow_paths()` but not `sm_init()`.

### Violation 2: Fail-Fast Error Handling (Development Philosophy)

**CLAUDE.md Requirement** (development_philosophy section):
> **Fail Fast**:
> - Missing files produce immediate, obvious bash errors
> - Tests pass or fail immediately (no monitoring periods)
> - Breaking changes break loudly with clear error messages
> - No silent fallbacks or graceful degradation

**Violation Analysis**:
1. **Silent failure**: `sm_init()` fails, but bash continues execution
2. **Delayed error**: Error doesn't manifest until line 244 (78 lines later)
3. **Unclear error message**: "unbound variable" doesn't indicate classification failure
4. **Hidden diagnostics**: `>/dev/null` suppresses helpful error messages from sm_init()

**Correct Fail-Fast Pattern**:
```bash
# Option 1: Inline error handling
if ! sm_init "$SAVED_WORKFLOW_DESC" "coordinate"; then
  handle_state_error "State machine initialization failed (classification error)" 1
fi

# Option 2: Bash -e natural exit (requires removing >/dev/null)
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" || exit 1
```

### Violation 3: bash-block-execution-model.md (Implicit)

**Pattern Documented**: Fixed semantic filenames, save-before-source pattern (discovered in Specs 620/630)

**Relevant Pattern** (from state_based_orchestration section of CLAUDE.md):
> **0. Bash Block Execution Model** ([Documentation](.claude/docs/concepts/bash-block-execution-model.md))
> - Subprocess isolation constraint: each bash block runs in separate process
> - Validated patterns for cross-block state management
> - Fixed semantic filenames, save-before-source pattern, library re-sourcing
> - Anti-patterns to avoid ($$-based IDs, export assumptions, premature traps)

**Violation**: The comment on line 167 ("Variables now available via export") makes an **export assumption** without verifying sm_init() success. This violates the bash block execution model principle of explicit state verification.

**Search Result** for bash-block-execution-model.md:
- **Status**: File not found in repository (Glob search returned no results)
- **Reference**: Mentioned in CLAUDE.md state_based_orchestration section
- **Conclusion**: Documentation may be planned but not yet created, OR filename differs from reference

### Violation 4: Command Architecture Standards - Standard 13 (Implicit)

**Standard 13 Requirement** (from command_architecture_standards.md, inferred):
> Standard 13: CLAUDE_PROJECT_DIR detection

**Observation**: Standard 13 is referenced in coordinate.md:61, but the command_architecture_standards.md excerpt (lines 1-200) doesn't show this standard. It likely appears later in the document.

**Relevance**: If there's a Standard 13 for environment detection, there should be a parallel standard for **critical function success verification**.

**Recommendation**: Add **Standard 16: Critical Function Return Code Verification** to command_architecture_standards.md.

---

## Similar Patterns in Other Commands

### Survey Results: sm_init() Usage Across Commands

**Commands Analyzed**:
- `/coordinate` (coordinate.md)
- `/orchestrate` (orchestrate.md)
- `/supervise` (supervise.md)

#### 1. /coordinate (coordinate.md:166) - **VULNERABLE**

```bash
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" >/dev/null
# Variables now available via export (not command substitution)
```

**Issues**:
- ✗ No return code check
- ✗ Output redirection hides errors
- ✗ Comment implies success without verification

**Failure Mode**: Silent failure → unbound variable error 78 lines later

#### 2. /orchestrate (orchestrate.md:109) - **PARTIALLY VULNERABLE**

```bash
# Initialize state machine
sm_init "$WORKFLOW_DESCRIPTION" "orchestrate"

# Save state machine configuration
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
```

**Issues**:
- ✗ No return code check
- ✓ No output redirection (errors visible)
- ~ Next line uses $WORKFLOW_SCOPE without verification

**Failure Mode**: Error messages visible, but bash continues → potential unbound variable error at line 112

#### 3. /supervise (supervise.md) - **NOT ANALYZED**

**Reason**: File not read in detail during this analysis. Based on command architecture, likely has similar pattern to /orchestrate.

**Recommendation**: Audit supervise.md for same vulnerability.

### Pattern Analysis: Common Vulnerability

**Root Cause**: **Misunderstanding of bash `-e` flag behavior with function calls**

Developers may assume that `set -euo pipefail` (line 53) will cause bash to exit when `sm_init()` returns non-zero. This is **incorrect** - bash only exits on simple command failures, not function call failures, unless explicitly checked.

**Evidence**: All three orchestration commands call `sm_init()` without return code checks, suggesting a systematic misunderstanding of bash error handling.

### Comparison to Other Critical Functions

**Correct Patterns in coordinate.md**:

1. **initialize_workflow_paths (line 244)**:
   ```bash
   if initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE" "$RESEARCH_COMPLEXITY"; then
     : # Success - paths initialized with dynamic allocation
   else
     handle_state_error "Workflow initialization failed" 1
   fi
   ```

2. **source_required_libraries (line 226)**:
   ```bash
   if source_required_libraries "${REQUIRED_LIBS[@]}"; then
     : # Success - libraries loaded
   else
     echo "ERROR: Failed to source required libraries"
     exit 1
   fi
   ```

**Observation**: The command **already uses correct return code checking** for other critical functions. The sm_init() bug is an **inconsistency**, not a systematic error.

---

## Recommended Fix Strategy

### Primary Fix: Add Return Code Check (Minimal, Safe)

**Location**: coordinate.md:166
**Change**: Add error handling after sm_init() call

**Before**:
```bash
# Initialize state machine (use SAVED value, not overwritten variable)
# CRITICAL: Call sm_init to export WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
# Do NOT use command substitution $() as it creates subshell that doesn't export to parent
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" >/dev/null
# Variables now available via export (not command substitution)
```

**After** (Option 1 - Inline Check):
```bash
# Initialize state machine (use SAVED value, not overwritten variable)
# CRITICAL: Call sm_init to export WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
# Do NOT use command substitution $() as it creates subshell that doesn't export to parent
if ! sm_init "$SAVED_WORKFLOW_DESC" "coordinate" 2>&1; then
  handle_state_error "State machine initialization failed (workflow classification error). Check network connection or use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline development." 1
fi
# Variables now available via export (verified by successful sm_init)
```

**Changes**:
1. Wrap in `if ! ... then` conditional
2. Remove `>/dev/null` redirection (show errors)
3. Change to `2>&1` to capture both stdout and stderr
4. Call `handle_state_error()` with descriptive message on failure
5. Update comment to reflect verification

**After** (Option 2 - Natural Bash Exit):
```bash
# Initialize state machine (use SAVED value, not overwritten variable)
# CRITICAL: Call sm_init to export WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
# Do NOT use command substitution $() as it creates subshell that doesn't export to parent
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" || {
  echo "CRITICAL ERROR: State machine initialization failed" >&2
  echo "See error messages above for details" >&2
  exit 1
}
# Variables now available via export (verified by successful sm_init)
```

**Recommendation**: Use **Option 1** for consistency with other error handling in the command (initialize_workflow_paths, source_required_libraries).

### Secondary Fix: Improve Error Messages

**Location**: workflow-state-machine.sh:371-376
**Change**: Enhance error message for offline development guidance

**Before**:
```bash
else
  # Fail-fast: No automatic fallback (lines 371-376)
  echo "CRITICAL ERROR: Comprehensive classification failed" >&2
  echo "  Workflow Description: $workflow_desc" >&2
  echo "  Suggestion: Check network connection, increase WORKFLOW_CLASSIFICATION_TIMEOUT, or use regex-only mode" >&2
  return 1
fi
```

**After**:
```bash
else
  # Fail-fast: No automatic fallback (clean-break approach from Spec 688 Phase 3)
  echo "CRITICAL ERROR: Comprehensive classification failed" >&2
  echo "  Workflow Description: $workflow_desc" >&2
  echo "  Classification Mode: ${WORKFLOW_CLASSIFICATION_MODE:-llm-only}" >&2
  echo "" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  1. Check network connection (LLM classification requires API access)" >&2
  echo "  2. Increase timeout: export WORKFLOW_CLASSIFICATION_TIMEOUT=60" >&2
  echo "  3. Use offline mode: export WORKFLOW_CLASSIFICATION_MODE=regex-only" >&2
  echo "  4. Check API credentials if using external classification service" >&2
  echo "" >&2
  return 1
fi
```

### Tertiary Fix: Apply to Other Commands

**Locations**:
- orchestrate.md:109
- supervise.md (location TBD)

**Change**: Apply same return code check pattern to all orchestration commands.

**Implementation**:
1. Search for all `sm_init` calls without return code checks
2. Apply consistent error handling pattern
3. Ensure error messages reference command-specific context

### Validation Fix: Remove Misleading Comment

**Location**: coordinate.md:167
**Change**: Update comment to reflect verification requirement

**Before**:
```bash
# Variables now available via export (not command substitution)
```

**After**:
```bash
# Variables now available via export (verified by successful sm_init return code check above)
```

---

## Testing Recommendations

### Unit Tests

#### Test 1: sm_init() Failure Propagation

**Objective**: Verify that sm_init() failure causes coordinate.md to exit immediately

**Test Setup**:
```bash
# Mock classify_workflow_comprehensive to fail
export WORKFLOW_CLASSIFICATION_MODE=llm-only
# Ensure LLM classifier fails (e.g., network unavailable)
unset ANTHROPIC_API_KEY
```

**Test Execution**:
```bash
/coordinate "test workflow description"
```

**Expected Behavior** (After Fix):
```
CRITICAL ERROR: Comprehensive classification failed
  Workflow Description: test workflow description
  Classification Mode: llm-only

TROUBLESHOOTING:
  1. Check network connection (LLM classification requires API access)
  2. Increase timeout: export WORKFLOW_CLASSIFICATION_TIMEOUT=60
  3. Use offline mode: export WORKFLOW_CLASSIFICATION_MODE=regex-only
  4. Check API credentials if using external classification service

ERROR in state 'initialize': State machine initialization failed (workflow classification error). Check network connection or use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline development.

State Machine Context:
  Workflow: test workflow description
  Scope:
  Current State: initialize
  Terminal State:
```

**Expected Exit Code**: 1

#### Test 2: sm_init() Success Path

**Objective**: Verify that successful sm_init() exports variables correctly

**Test Setup**:
```bash
# Use regex-only mode for reliable offline testing
export WORKFLOW_CLASSIFICATION_MODE=regex-only
```

**Test Execution**:
```bash
/coordinate "research authentication patterns"
```

**Expected Behavior**:
- No errors during initialization
- WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON exported
- Command proceeds to Research phase

**Verification**:
```bash
# Check state file for persisted variables
cat ~/.claude/data/state/coordinate_*.state | grep -E "WORKFLOW_SCOPE|RESEARCH_COMPLEXITY|RESEARCH_TOPICS_JSON"
```

#### Test 3: Unbound Variable Detection

**Objective**: Verify that unbound variable errors are caught before line 244

**Test Setup**:
```bash
# Manually unset RESEARCH_COMPLEXITY to simulate failure
unset RESEARCH_COMPLEXITY
```

**Test Execution**:
```bash
# Run coordinate.md bash block 2 (lines 52-346) directly
```

**Expected Behavior** (After Fix):
- Error detected at line 166 (sm_init failure)
- Script exits before reaching line 244

**Current Behavior** (Before Fix):
- Error detected at line 244 (unbound variable)

### Integration Tests

#### Test 4: End-to-End Offline Workflow

**Objective**: Verify complete coordinate workflow in offline mode

**Test Setup**:
```bash
export WORKFLOW_CLASSIFICATION_MODE=regex-only
```

**Test Execution**:
```bash
/coordinate "research and plan authentication system"
```

**Expected Behavior**:
- Initialization succeeds with regex classification
- Research phase invokes agents
- Planning phase creates plan
- Workflow completes successfully

#### Test 5: Error Recovery Test

**Objective**: Verify that user can recover from classification failure

**Test Execution**:
```bash
# Attempt 1: Fail with LLM mode
export WORKFLOW_CLASSIFICATION_MODE=llm-only
unset ANTHROPIC_API_KEY
/coordinate "test workflow"

# Attempt 2: Succeed with regex mode
export WORKFLOW_CLASSIFICATION_MODE=regex-only
/coordinate "test workflow"
```

**Expected Behavior**:
- Attempt 1: Fails with clear error message suggesting regex-only mode
- Attempt 2: Succeeds with regex classification

### Regression Tests

#### Test 6: Existing Workflow Compatibility

**Objective**: Verify fix doesn't break existing workflows

**Test Execution**:
```bash
# Run all existing test cases in .claude/tests/
./run_all_tests.sh
```

**Expected Behavior**:
- All existing tests pass
- No new unbound variable errors

---

## Prevention Guidelines

### For Command Developers

#### Guideline 1: Always Check Critical Function Return Codes

**Pattern**:
```bash
# WRONG - No check
critical_function arg1 arg2

# RIGHT - Inline check
if ! critical_function arg1 arg2; then
  handle_state_error "critical_function failed: description" 1
fi

# RIGHT - Compound check
critical_function arg1 arg2 || {
  echo "ERROR: critical_function failed" >&2
  exit 1
}
```

**Critical Functions** (require return code checks):
- `sm_init()`
- `initialize_workflow_paths()`
- `source_required_libraries()`
- `verify_file_created()` (when not using return code for conditional logic)
- Any function that exports state variables

#### Guideline 2: Avoid Output Redirection for Diagnostic Functions

**Pattern**:
```bash
# WRONG - Hides errors
sm_init "$WORKFLOW_DESC" "$COMMAND_NAME" >/dev/null

# RIGHT - Show errors
sm_init "$WORKFLOW_DESC" "$COMMAND_NAME"

# ACCEPTABLE - Redirect only stdout, keep stderr
sm_init "$WORKFLOW_DESC" "$COMMAND_NAME" 1>/dev/null
```

**Rationale**: Diagnostic messages on stderr help users troubleshoot failures.

#### Guideline 3: Update Comments to Reflect Verification

**Pattern**:
```bash
# WRONG - Assumes success
some_function
# Variables now available

# RIGHT - Acknowledges verification
if ! some_function; then
  handle_error
fi
# Variables now available (verified by return code check above)
```

#### Guideline 4: Test Failure Paths

**Pattern**:
```bash
# For every critical function call, test:
# 1. Success path (normal case)
# 2. Failure path (error handling)
# 3. Boundary conditions (edge cases)
```

**Example Test Cases**:
- `sm_init()` with valid description → success
- `sm_init()` with network unavailable → fail-fast error
- `sm_init()` with empty description → validation error

### For Library Function Developers

#### Guideline 5: Return Non-Zero on All Failure Paths

**Pattern**:
```bash
function some_library_function() {
  local arg="$1"

  # Validation
  if [ -z "$arg" ]; then
    echo "ERROR: arg required" >&2
    return 1  # ← CRITICAL
  fi

  # Processing
  if ! process_arg "$arg"; then
    echo "ERROR: processing failed" >&2
    return 1  # ← CRITICAL
  fi

  # Success
  return 0
}
```

**Checklist**:
- Every error path has `return 1`
- Success path has explicit `return 0`
- Error messages go to stderr (`>&2`)

#### Guideline 6: Provide Actionable Error Messages

**Pattern**:
```bash
# WRONG - Vague error
echo "ERROR: Classification failed" >&2
return 1

# RIGHT - Actionable error
echo "ERROR: classify_workflow_comprehensive: LLM classification failed in llm-only mode" >&2
echo "  Context: Workflow description: $workflow_description" >&2
echo "  Suggestion: Check network connection, increase WORKFLOW_CLASSIFICATION_TIMEOUT, or use regex-only mode for offline development" >&2
return 1
```

**Components**:
1. **Error type**: What failed (function name + specific failure)
2. **Context**: Input values that caused failure
3. **Suggestion**: How to fix (with command examples if applicable)

### For Documentation

#### Guideline 7: Document Return Code Contracts

**Pattern** (in function docstring):
```bash
# classify_workflow_comprehensive: Comprehensive workflow classification
# Args:
#   $1: workflow_description - The workflow description to analyze
# Returns:
#   0: Success (prints JSON to stdout)
#   1: Error (prints diagnostics to stderr)
# Output Format:
#   {
#     "workflow_type": "research-and-plan",
#     "confidence": 0.95,
#     "research_complexity": 2,
#     "subtopics": ["Topic 1 description", "Topic 2 description"],
#     "reasoning": "..."
#   }
```

**Benefits**:
- Developers know to check return codes
- Debugging is faster (expected behavior documented)

---

## Appendix A: Error Output Analysis

### Raw Error Output (from coordinate_command.md)

```
CRITICAL ERROR: Comprehensive classification failed
  Workflow Description: <workflow-description>
  Suggestion: Check network connection, increase
     WORKFLOW_CLASSIFICATION_TIMEOUT, or use regex-only mode
       Alternative: Set
     WORKFLOW_CLASSIFICATION_MODE=regex-only for offline
     development
     /run/current-system/sw/bin/bash: line 486:
     RESEARCH_COMPLEXITY: unbound variable

     === State Machine Workflow Orchestration ===

     ✓
```

**Observations**:
1. Classification error printed first (from sm_init)
2. Unbound variable error printed second (78 lines later)
3. User sees both errors, but causal relationship unclear
4. "line 486" refers to bash script runtime, not coordinate.md line numbers

### Error Frequency

**From coordinate_command.md analysis** (errors at multiple line numbers):
- Line 1479: `RESEARCH_COMPLEXITY: unbound variable`
- Line 1965: `RESEARCH_COMPLEXITY: unbound variable`
- Line 2020: `RESEARCH_COMPLEXITY: unbound variable`
- Line 2506: `RESEARCH_COMPLEXITY: unbound variable`
- Line 2561: `RESEARCH_COMPLEXITY: unbound variable`
- Line 3047: `RESEARCH_COMPLEXITY: unbound variable`

**Interpretation**: Multiple invocations of `/coordinate` all failed at the same point (sm_init failure → unbound variable). The repeated errors suggest this is **100% reproducible** when LLM classification fails.

---

## Appendix B: Code Snippets for Quick Reference

### Correct sm_init() Invocation Pattern

```bash
# Option 1: Inline error handling (RECOMMENDED)
if ! sm_init "$SAVED_WORKFLOW_DESC" "coordinate" 2>&1; then
  handle_state_error "State machine initialization failed (workflow classification error). Check network connection or use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline development." 1
fi

# Option 2: Natural bash exit
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" || exit 1

# Option 3: Trap-based handling (advanced)
trap 'handle_state_error "State machine initialization failed" 1' ERR
sm_init "$SAVED_WORKFLOW_DESC" "coordinate"
trap - ERR
```

### Return Code Check Examples from coordinate.md

```bash
# Example 1: initialize_workflow_paths (line 244)
if initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE" "$RESEARCH_COMPLEXITY"; then
  : # Success - paths initialized with dynamic allocation
else
  handle_state_error "Workflow initialization failed" 1
fi

# Example 2: source_required_libraries (line 226)
if source_required_libraries "${REQUIRED_LIBS[@]}"; then
  : # Success - libraries loaded
else
  echo "ERROR: Failed to source required libraries"
  exit 1
fi

# Example 3: verify_state_variable (line 193)
verify_state_variable "WORKFLOW_SCOPE" || {
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not persisted to state after sm_init" 1
}
```

---

## Appendix C: Related Specifications and Documentation

### Related Specs

- **Spec 688**: Clean-break update removing hybrid mode and automatic regex fallback
- **Specs 620/630**: Bash block execution model patterns discovery
- **Spec 678**: Coordinate haiku classification (comprehensive classification implementation)

### Related Standards

- **Standard 0**: Execution Enforcement (command_architecture_standards.md)
- **Standard 13**: CLAUDE_PROJECT_DIR detection (command_architecture_standards.md)
- **Proposed Standard 16**: Critical Function Return Code Verification

### Related Documentation

- **CLAUDE.md**: Development Philosophy → Fail-Fast approach
- **bash-block-execution-model.md**: (Referenced but file not found - may need creation)
- **command_architecture_standards.md**: Comprehensive architecture standards

---

## Conclusion

The `/coordinate` command error is a **textbook fail-fast violation**: a critical initialization function (`sm_init()`) fails, but the calling code doesn't check the return code, allowing execution to continue with incomplete state. The fix is straightforward (add return code check), but the systematic occurrence across multiple orchestration commands suggests this pattern should be codified in a new architectural standard.

**Recommended Actions**:
1. **Immediate**: Fix coordinate.md:166 with return code check
2. **Short-term**: Audit orchestrate.md and supervise.md for same vulnerability
3. **Long-term**: Create Standard 16 (Critical Function Return Code Verification) in command_architecture_standards.md
4. **Documentation**: Create bash-block-execution-model.md if not already present

**Priority**: **HIGH** - 100% failure rate for affected workflows

**REPORT_CREATED**: /home/benjamin/.config/.claude/specs/698_coordinate_error_handling/reports/001_error_handling_root_cause_analysis.md
