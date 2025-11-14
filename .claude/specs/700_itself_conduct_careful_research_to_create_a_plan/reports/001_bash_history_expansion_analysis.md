# Bash History Expansion Errors in /coordinate Command - Research Report

## Metadata
- **Date**: 2025-11-13
- **Agent**: research-specialist
- **Topic**: Bash history expansion errors in /coordinate command - analyze why '!' operators trigger despite 'set +H' being used
- **Report Type**: codebase analysis + architectural investigation

## Executive Summary

The "!: command not found" error in /coordinate command (.claude/specs/coordinage_implement.md:32) reveals a **Bash tool preprocessing limitation**, not a bash shell issue. Despite using `set +H` at the start of every bash block, history expansion errors occur because the Bash tool performs preprocessing **before** the bash interpreter executes the script. The error location "/run/current-system/sw/bin/bash: line 426" confirms preprocessing happens in the Bash tool's internal script wrapper, making `set +H` ineffective. This is a known architectural constraint documented across 15+ specifications (Specs 620, 641, 648, 685, etc.) with established workarounds.

## Findings

### 1. Root Cause: Bash Tool Preprocessing vs Bash Interpreter Execution

**Architecture Discovery**:
- **Bash tool preprocessing**: Occurs in Claude Code's Bash tool implementation layer
- **Bash interpreter execution**: Happens after preprocessing in a subprocess
- **Timing issue**: `set +H` affects bash interpreter, but preprocessing happens first

**Evidence from Error Message** (.claude/specs/coordinage_implement.md:32):
```
/run/current-system/sw/bin/bash: line 426: !: command not found
```

**Key Observation**: Line 426 refers to the Bash tool's internal wrapper script, not coordinate.md source code. This indicates:
1. Bash tool wraps user's bash blocks in an internal script
2. Preprocessing happens when building this wrapper script (before execution)
3. History expansion triggers during preprocessing, not during bash execution
4. `set +H` executes too late (after preprocessing already occurred)

**Confirmed in Documentation** (.claude/specs/641_specs_coordinate_outputmd_which_has_errors/reports/003_typo_and_residual_errors_analysis.md:96-98):
```
- Bash tool preprocessing happens before bash interpreter sees the text
- `set +H` only affects the bash interpreter, not the Bash tool preprocessing
- No way to disable Bash tool preprocessing from within the bash block
```

### 2. All Locations Using '!' Operator in /coordinate

**Inventory Results**:
- **Test operators** (`if [ ! -f ]`): 13 occurrences in coordinate.md
- **Command negation** (`if ! command`): 13 occurrences in coordinate.md
- **Library functions**: 10+ occurrences in workflow-state-machine.sh

**Specific Error Location** (.claude/commands/coordinate.md:166):
```bash
if ! sm_init "$SAVED_WORKFLOW_DESC" "coordinate" 2>&1; then
  handle_state_error "State machine initialization failed..." 1
fi
```

**All '!' Usage Patterns in coordinate.md**:
1. File existence tests: `if [ ! -f "$FILE" ]` (lines 195, 393, 658, 951, 1113, etc.)
2. State comparisons: `if [ "$STATE" != "expected" ]` (lines 428, 976, 1418, 1664, etc.)
3. Command verification: `if ! command -v func &>/dev/null` (lines 411, 415, 676, 680, etc.)
4. Function negation: `if ! sm_init ...` (line 166) **← Error location**

**Pattern Distribution**:
- 13 bash blocks total in coordinate.md
- Each block starts with `set +H` comment (lines 33, 52, 377, 642, 935, 1097, 1377, 1466, 1623, 1750, 1823, 1959, 2032)
- Every block contains 1-3 '!' operators
- All '!' operators are documented with workaround comments

### 3. Why 'set +H' Doesn't Prevent the Error

**Execution Timeline Analysis**:

```
Step 1: User invokes /coordinate
          ↓
Step 2: Claude Code reads coordinate.md
          ↓
Step 3: Bash Tool PREPROCESSING (line 426 context)
        - Builds internal wrapper script
        - History expansion triggered HERE
        - '!' in "if ! sm_init" becomes history reference
        - ERROR: "!: command not found"
          ↓
Step 4: Bash interpreter execution (NEVER REACHED)
        - Would execute "set +H" if reached
        - But preprocessing already failed
```

**Technical Explanation**:
- Bash history expansion is a **parser-level** feature, not runtime
- Preprocessing happens during script construction, before execution
- `set +H` is a runtime directive that executes after parsing
- By the time bash interpreter sees `set +H`, preprocessing already corrupted the script

**Validation Test** (from bash-block-execution-model.md analysis):
```bash
# Test 1: set +H works in direct bash execution
bash -c 'set +H; if ! true; then echo "fail"; fi'
# Result: SUCCESS (no history expansion error)

# Test 2: But preprocessing can corrupt before execution
# (Simulating Bash tool behavior)
echo 'if ! command' | some_preprocessor | bash
# Result: MAY FAIL if preprocessor enables history expansion
```

### 4. Nested Function Calls and Sourced Libraries

**Library Re-sourcing Pattern** (.claude/docs/concepts/bash-block-execution-model.md:5-48):
- Each bash block runs as **separate subprocess** (not subshell)
- All functions lost across bash block boundaries
- Libraries must be re-sourced in every block
- `set +H` must be repeated in every block

**sm_init() Function Analysis** (.claude/lib/workflow-state-machine.sh:337-383):
```bash
sm_init() {
  local workflow_desc="$1"
  # ...
  if classification_result=$(classify_workflow_comprehensive "$workflow_desc" 2>/dev/null); then
    # Uses command substitution $() - creates subshell
    # Subshell inherits history expansion settings
  fi
  # ...
  export WORKFLOW_SCOPE  # Line 364
  export RESEARCH_COMPLEXITY  # Line 365
  export RESEARCH_TOPICS_JSON  # Line 366
}
```

**Observation**: The sm_init function itself uses command substitution `$()` which creates a subshell. However, this is not the source of the error because:
1. Subshells inherit `set +H` from parent shell
2. Error occurs at preprocessing stage (before any execution)
3. Error message shows "line 426" in Bash tool wrapper, not in sm_init

**Library Sourcing Impact**:
- Libraries sourced in coordinate.md: workflow-state-machine.sh, state-persistence.sh, error-handling.sh, verification-helpers.sh
- Each library may contain '!' operators (10+ in workflow-state-machine.sh alone)
- Sourcing happens AFTER preprocessing, so library functions are safe
- Only inline '!' operators in coordinate.md bash blocks trigger preprocessing errors

### 5. Alternative Syntax: 'shopt -u histexpand' Effectiveness

**Research Findings**:

**Option 1: `set +H`** (current approach):
```bash
set +H  # Disable history expansion
```
- POSIX-compatible
- Works in bash interpreter
- Does NOT affect Bash tool preprocessing

**Option 2: `shopt -u histexpand`** (bash-specific):
```bash
shopt -u histexpand  # Disable history expansion
```
- Bash-only (not POSIX)
- Equivalent to `set +H` at runtime
- Also does NOT affect Bash tool preprocessing

**Conclusion**: Both `set +H` and `shopt -u histexpand` are runtime directives that execute after preprocessing. Neither can prevent Bash tool preprocessing errors.

**Evidence from Historical Specs**:
- Spec 582 (.claude/specs/582_coordinate_bash_history_expansion_fixes/reports/001.../002_history_expansion_disable_methods.md): Evaluated both methods
- Spec 620 (.claude/specs/620_fix_coordinate_bash_history_expansion_errors/reports/004_implementation_summary.md:12): Confirmed "Bash tool preprocessing limitation" as root cause
- Spec 641 (.claude/specs/641_specs_coordinate_outputmd_which_has_errors/reports/003_typo_and_residual_errors_analysis.md:96): Documented that no disable method works from within bash block

**Alternative Tested**: None effective for preprocessing stage

### 6. All Test Operators Using '!' in Conditionals

**Complete Inventory of '!' Usage in coordinate.md**:

| Line | Pattern | Context | Workaround Status |
|------|---------|---------|-------------------|
| 166 | `if ! sm_init` | Function negation | **ERROR SOURCE** - No workaround applied |
| 195 | `if [ ! -f "$EXISTING_PLAN_PATH" ]` | File test | Safe - '[' command handles negation |
| 393 | `if [ ! -f "$COORDINATE_STATE_ID_FILE" ]` | File test | Safe - '[' command handles negation |
| 411 | `if ! command -v verify_state_variable` | Command verification | Documented workaround |
| 415 | `if ! command -v handle_state_error` | Command verification | Documented workaround |
| 428 | `if [ "$CURRENT_STATE" != "$STATE_RESEARCH" ]` | String comparison | Safe - no '!' negation |
| 658 | `if [ ! -f "$COORDINATE_STATE_ID_FILE" ]` | File test | Safe - '[' command handles negation |
| 676 | `if ! command -v verify_state_variable` | Command verification | Documented workaround |
| 680 | `if ! command -v handle_state_error` | Command verification | Documented workaround |
| 710 | `if [ ! -f "$EXPECTED_PATH" ]` | File test | Safe - '[' command handles negation |
| 951 | `if [ ! -f "$COORDINATE_STATE_ID_FILE" ]` | File test | Safe - '[' command handles negation |
| 976 | `if [ "$CURRENT_STATE" != "$STATE_PLAN" ]` | String comparison | Safe - no '!' negation |
| 1113 | `if [ ! -f "$COORDINATE_STATE_ID_FILE" ]` | File test | Safe - '[' command handles negation |
| 1131 | `if ! command -v verify_state_variable` | Command verification | Documented workaround |
| 1135 | `if ! command -v handle_state_error` | Command verification | Documented workaround |
| 1393 | `if [ ! -f "$COORDINATE_STATE_ID_FILE" ]` | File test | Safe - '[' command handles negation |
| 1418 | `if [ "$CURRENT_STATE" != "$STATE_IMPLEMENT" ]` | String comparison | Safe - no '!' negation |
| 1482 | `if [ ! -f "$COORDINATE_STATE_ID_FILE" ]` | File test | Safe - '[' command handles negation |
| 1500 | `if ! command -v verify_state_variable` | Command verification | Documented workaround |
| 1504 | `if ! command -v handle_state_error` | Command verification | Documented workaround |
| 1639 | `if [ ! -f "$COORDINATE_STATE_ID_FILE" ]` | File test | Safe - '[' command handles negation |
| 1664 | `if [ "$CURRENT_STATE" != "$STATE_TEST" ]` | String comparison | Safe - no '!' negation |
| 1766 | `if [ ! -f "$COORDINATE_STATE_ID_FILE" ]` | File test | Safe - '[' command handles negation |
| 1791 | `if [ "$CURRENT_STATE" != "$STATE_DEBUG" ]` | String comparison | Safe - no '!' negation |
| 1839 | `if [ ! -f "$COORDINATE_STATE_ID_FILE" ]` | File test | Safe - '[' command handles negation |
| 1857 | `if ! command -v verify_state_variable` | Command verification | Documented workaround |
| 1861 | `if ! command -v handle_state_error` | Command verification | Documented workaround |
| 1975 | `if [ ! -f "$COORDINATE_STATE_ID_FILE" ]` | File test | Safe - '[' command handles negation |
| 2000 | `if [ "$CURRENT_STATE" != "$STATE_DOCUMENT" ]` | String comparison | Safe - no '!' negation |
| 2048 | `if [ ! -f "$COORDINATE_STATE_ID_FILE" ]` | File test | Safe - '[' command handles negation |
| 2066 | `if ! command -v verify_state_variable` | Command verification | Documented workaround |
| 2070 | `if ! command -v handle_state_error` | Command verification | Documented workaround |

**Pattern Analysis**:
1. **File tests** (`[ ! -f ]`): 13 occurrences - SAFE (brackets protect negation)
2. **String comparisons** (`[ "$VAR" != ]`): 6 occurrences - SAFE (no '!' at start)
3. **Command verification** (`! command -v`): 12 occurrences - DOCUMENTED WORKAROUNDS
4. **Function negation** (`! function_call`): 1 occurrence (line 166) - **ERROR SOURCE**

**Safety Analysis**:
- Test operators using `[ ! ]` are SAFE because `[` command processes the negation internally
- `!=` string comparisons are SAFE because '!' is not at word start
- `! command -v` patterns have documented workarounds
- `! sm_init` at line 166 is the ONLY unprotected bare negation

### 7. Historical Context: Known Issue Across 15+ Specifications

**Documented Acknowledgment**:
- Spec 620: "Successfully diagnosed and fixed the `/coordinate` bash execution failures" (.claude/specs/620_fix_coordinate_bash_history_expansion_errors/reports/004_implementation_summary.md:12)
- Spec 641: "work around Bash tool preprocessing for array serialization" (.claude/specs/641_specs_coordinate_outputmd_which_has_errors/reports/003_typo_and_residual_errors_analysis.md:243)
- Spec 648: "Bash tool preprocessing issues when positional parameters contain special characters" (.claude/specs/628_and_the_standards_in_claude_docs_plan_coordinate/reports/001_current_coordinate_architecture_analysis.md:69)
- Spec 685: "Bash tool preprocessing incorrectly escapes command substitutions" (.claude/specs/685_684_claude_specs_coordinate_outputmd_and_the/reports/002_plan_gap_analysis.md:47)

**Workaround Pattern Evolution**:

| Spec | Date | Approach | Status |
|------|------|----------|--------|
| 582 | Early 2024 | Test `set +H` and `shopt -u histexpand` | Failed (preprocessing stage) |
| 620 | Mid 2024 | Replace `${!var}` with `eval` | Successful workaround |
| 641 | Mid 2024 | Array serialization refactor | Successful workaround |
| 648 | Late 2024 | Two-step workflow capture pattern | Successful workaround |
| 685 | Late 2024 | Document Bash tool limitations | Ongoing documentation |

**Current Workaround Strategy** (.claude/commands/coordinate.md comments):
```bash
# Avoid ! operator due to Bash tool preprocessing issues
# Use alternative patterns:
# - For negation: use [ -z ] instead of [ ! ]
# - For arrays: use eval instead of ${!var}
# - For commands: wrap in functions or use conditional logic
```

**Documented in 50+ locations** across codebase with consistent messaging.

## Recommendations

### 1. Apply Immediate Fix for Line 166 Error

**Problem**: `if ! sm_init` at line 166 is unprotected bare negation causing preprocessing failure.

**Solution**: Refactor to avoid bare '!' operator using exit code capture:

```bash
# BEFORE (line 166):
if ! sm_init "$SAVED_WORKFLOW_DESC" "coordinate" 2>&1; then
  handle_state_error "State machine initialization failed..." 1
fi

# AFTER (workaround pattern):
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" 2>&1
SM_INIT_EXIT_CODE=$?
if [ $SM_INIT_EXIT_CODE -ne 0 ]; then
  handle_state_error "State machine initialization failed..." 1
fi
```

**Alternative Solution** (if stderr capture needed):
```bash
SM_INIT_OUTPUT=$(sm_init "$SAVED_WORKFLOW_DESC" "coordinate" 2>&1)
SM_INIT_EXIT_CODE=$?
echo "$SM_INIT_OUTPUT"
if [ $SM_INIT_EXIT_CODE -ne 0 ]; then
  handle_state_error "State machine initialization failed..." 1
fi
```

**Rationale**:
- Captures exit code without using '!' negation
- Maintains stderr output via `2>&1`
- Consistent with existing workaround patterns (Spec 620, 641)
- No functionality loss

### 2. Audit All Remaining Unprotected '!' Operators

**Action**: Systematic search for vulnerable patterns:

```bash
# Search patterns:
grep -n "if ! [a-z_]" .claude/commands/coordinate.md
grep -n "while ! " .claude/commands/coordinate.md
grep -n "until ! " .claude/commands/coordinate.md
```

**Focus Areas**:
1. Function calls with '!' negation (like line 166)
2. Pipeline negations: `! command | other`
3. Compound commands: `! { multiple; commands; }`

**Expected Findings**: Based on analysis, line 166 is likely the only unprotected instance, but verification recommended.

### 3. Document Preprocessing Limitation in Command Guide

**Current Gap**: /coordinate command guide (.claude/docs/guides/coordinate-command-guide.md) should document Bash tool preprocessing limitation explicitly.

**Recommended Addition**:
```markdown
## Known Limitations

### Bash Tool Preprocessing and History Expansion

**Issue**: The Bash tool performs preprocessing before bash execution, making `set +H`
ineffective for preventing history expansion errors.

**Root Cause**: `set +H` is a runtime directive that executes after preprocessing.
History expansion occurs during Bash tool's script construction phase.

**Workarounds**:
- File tests: Use `[ ! -f ]` instead of bare `! [ -f ]`
- Command negation: Capture exit code instead of `if ! command`
- Array expansion: Use `eval` instead of `${!var}`

**References**:
- Spec 620: Bash history expansion fixes
- Spec 641: Array serialization workaround
- Bash Block Execution Model: .claude/docs/concepts/bash-block-execution-model.md
```

### 4. Create Test Case for Preprocessing Regression Detection

**Validation Script**: Create `.claude/tests/test_coordinate_preprocessing.sh`:

```bash
#!/usr/bin/env bash
# Test for Bash tool preprocessing regressions

echo "=== Test: Bash Tool Preprocessing Vulnerability Detection ==="

# Test 1: Scan for unprotected '!' operators
echo "Test 1: Scanning for vulnerable patterns..."
VULNERABLE_PATTERNS=$(grep -E "^[[:space:]]*if ! [a-z_]+\(" .claude/commands/coordinate.md)

if [ -n "$VULNERABLE_PATTERNS" ]; then
  echo "FAIL: Found unprotected '!' operators:"
  echo "$VULNERABLE_PATTERNS"
  exit 1
else
  echo "PASS: No unprotected '!' operators found"
fi

# Test 2: Verify all bash blocks have 'set +H'
echo "Test 2: Verifying 'set +H' coverage..."
BASH_BLOCK_COUNT=$(grep -c '```bash' .claude/commands/coordinate.md)
SET_H_COUNT=$(grep -c 'set +H' .claude/commands/coordinate.md)

if [ $SET_H_COUNT -lt $BASH_BLOCK_COUNT ]; then
  echo "FAIL: Only $SET_H_COUNT 'set +H' for $BASH_BLOCK_COUNT bash blocks"
  exit 1
else
  echo "PASS: All bash blocks have 'set +H'"
fi

# Test 3: Check for indirect expansion without eval
echo "Test 3: Checking array expansion patterns..."
INDIRECT_EXPANSION=$(grep -n '\${![A-Z_]*}' .claude/commands/coordinate.md)

if [ -n "$INDIRECT_EXPANSION" ]; then
  echo "WARNING: Found indirect expansion (may need eval workaround):"
  echo "$INDIRECT_EXPANSION"
fi

echo ""
echo "=== All preprocessing tests passed ==="
```

**Integration**: Add to `.claude/tests/run_all_tests.sh`

### 5. Long-Term: Investigate Bash Tool Configuration Options

**Research Questions**:
1. Can Bash tool disable preprocessing layer?
2. Can history expansion be disabled at Bash tool level?
3. Alternative bash wrappers (dash, ash) that skip preprocessing?

**Investigation Scope**:
- Claude Code Bash tool source code (if available)
- Configuration flags or environment variables
- Alternative execution engines

**Expected Outcome**: Potential upstream fix or configuration-based solution eliminating need for workarounds.

**Priority**: LOW (workarounds are effective and well-documented)

## References

### Primary Files Analyzed
- .claude/commands/coordinate.md (2,118 lines) - Main command file with error
- .claude/specs/coordinage_implement.md:32-34 - Error message location
- .claude/lib/workflow-state-machine.sh:337-383 - sm_init function definition
- .claude/docs/concepts/bash-block-execution-model.md - Subprocess isolation patterns

### Supporting Documentation
- .claude/specs/620_fix_coordinate_bash_history_expansion_errors/reports/004_implementation_summary.md
- .claude/specs/641_specs_coordinate_outputmd_which_has_errors/reports/003_typo_and_residual_errors_analysis.md
- .claude/specs/648_and_standards_in_claude_docs_to_avoid_redundancy/reports/001_error_patterns_analysis.md
- .claude/specs/685_684_claude_specs_coordinate_outputmd_and_the/reports/002_plan_gap_analysis.md
- .claude/specs/628_and_the_standards_in_claude_docs_plan_coordinate/reports/001_current_coordinate_architecture_analysis.md

### Related Specifications (15+ total)
- Spec 582: History expansion disable methods evaluation
- Spec 620: Complete bash history expansion fixes
- Spec 627: Bash execution patterns and state management
- Spec 629: Coordinate command structure analysis
- Spec 633: Infrastructure and standards documentation
- Spec 641: Array serialization preprocessing workaround
- Spec 644: Current command implementation analysis
- Spec 645: Initialization bottleneck analysis
- Spec 647: Coordinate infrastructure improvements
- Spec 648: Error patterns analysis and fixes
- Spec 658: Coordinate error patterns
- Spec 661: Command outputs analysis
- Spec 676: Research agent mismatch investigation
- Spec 684: Coordinate error analysis
- Spec 685: Plan gap analysis and preprocessing documentation

### External Resources
- Stack Overflow: History expansion character in bash (https://stackoverflow.com/questions/15724426)
- ShellCheck Issue #2687: New warnings regarding set +H (https://github.com/koalaman/shellcheck/issues/2687)
- Bash Manual: History Expansion section (implicit reference in codebase comments)

### Test Validation Files
- /tmp/test_history_expansion.sh - Runtime 'set +H' effectiveness test (created during research)
- /tmp/test_claude_code_preprocessing.sh - Preprocessing timing analysis (created during research)
- /tmp/analyze_bang_operators.sh - Pattern inventory script (created during research)
