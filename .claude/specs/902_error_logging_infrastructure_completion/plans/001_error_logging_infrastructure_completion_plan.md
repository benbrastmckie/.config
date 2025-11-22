# Error Logging Helper Functions Plan

## Metadata
- **Date**: 2025-11-21 (Revised)
- **Feature**: Error Logging Helper Functions - Optional Improvements
- **Scope**: Add optional helper functions to error-handling.sh for boilerplate reduction
- **Estimated Phases**: 2
- **Estimated Hours**: 2.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 18
- **Research Reports**:
  - [Preserved Elements Analysis](/home/benjamin/.config/.claude/specs/902_error_logging_infrastructure_completion/reports/001_plan_884_preserved_elements.md)
  - [Revision Research - Compliance Analysis](/home/benjamin/.config/.claude/specs/902_error_logging_infrastructure_completion/reports/002_revision_research_compliance_analysis.md)

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-21 | 1.0 | Initial plan with 3 phases |
| 2025-11-21 | 2.0 | **Major revision**: Removed obsolete Phase 2 (convert-docs.md already has full error logging). Fixed compliance issue with error type constant. Reclassified as optional improvements rather than infrastructure completion. |

## Overview

This plan adds two **optional helper functions** to error-handling.sh that reduce boilerplate in commands. These are **convenience improvements**, not critical infrastructure completion.

### Important Context

Research revealed that the error logging infrastructure is **already complete** across all major orchestrator commands:
- expand.md: Full integration with setup_bash_error_trap and log_command_error
- collapse.md: Full integration with setup_bash_error_trap and log_command_error
- convert-docs.md: Full integration (STEP 1.5, lines 236-266) with 6 log_command_error call sites
- build.md: Full integration with setup_bash_error_trap
- plan.md: Full integration with setup_bash_error_trap
- research.md: Full integration with setup_bash_error_trap

### Key Objectives

1. **Add `validate_required_functions()` helper** - Optional defensive validation for edge cases
2. **Add `execute_with_logging()` wrapper** - Optional boilerplate reduction for command execution

### Value Assessment

| Function | Value | Justification |
|----------|-------|---------------|
| `validate_required_functions()` | Low-Medium | Catches edge case where function missing after successful library sourcing; existing setup_bash_error_trap catches runtime errors |
| `execute_with_logging()` | Medium | Reduces boilerplate but trades context-specific error messages for brevity; no current adoption |

### Relationship to Other Plans

- **Plan 884 (Superseded)**: Original source of these helper function ideas; Phase 0 was obsolete (function exists), Phase 2 duplicated Plan 2
- **Plan 2 (Error Logging Infrastructure Migration)**: Covered expand.md and collapse.md; convert-docs.md was already integrated
- **This Plan**: Implements optional helper functions only; infrastructure completion is NOT needed

## Success Criteria

- [ ] `validate_required_functions()` function added to error-handling.sh and exported
- [ ] `execute_with_logging()` function added to error-handling.sh and exported
- [ ] Unit tests created for both new functions
- [ ] Pre-commit hooks pass for all modified files
- [ ] Documentation updated in error-handling pattern docs

## Technical Design

### Architecture Overview

```
error-handling.sh (Enhanced with Optional Helpers)
├── Existing functions (COMPLETE):
│   ├── log_command_error()
│   ├── ensure_error_log_exists()
│   ├── setup_bash_error_trap()
│   ├── parse_subagent_error()
│   └── Error type constants
│
├── NEW: validate_required_functions()
│   ├── Takes space-separated list of function names
│   ├── Validates each function exists (type -t)
│   ├── Logs missing functions with validation_error type
│   └── Returns 1 if any missing (caller decides on exit)
│
└── NEW: execute_with_logging()
    ├── Takes operation name and command
    ├── Executes command, captures output and exit code
    ├── Logs failure with execution_error type
    └── Returns original exit code
```

### Function Specifications

**validate_required_functions()**:
- Input: Space-separated string of function names
- Output: None on success, error message on failure
- Side effects: Logs to error log if functions missing
- Error type: `validation_error` (standards-compliant; "dependency_error" is not a valid constant)
- Return: 0 on success, 1 if any function missing

**execute_with_logging()**:
- Input: Operation name (string), command and arguments
- Output: Command's stdout (if successful)
- Side effects: Logs to error log if command fails
- Error type: `execution_error`
- Return: Command's exit code

### Standards Compliance Notes

1. **Error Type Constants**: Using `validation_error` instead of proposed `dependency_error` which is not a defined constant in error-handling.sh (lines 367-374)
2. **Three-Tier Sourcing**: Functions added to error-handling.sh (Tier 1 library) - compliant
3. **Export Pattern**: Functions will be added to the conditional export block (lines 1233-1459)

## Implementation Phases

### Phase 1: Add Helper Functions to error-handling.sh [NOT STARTED]
dependencies: []

**Objective**: Add `validate_required_functions()` and `execute_with_logging()` to error-handling.sh

**Complexity**: Low

**Tasks**:
- [ ] Read current error-handling.sh to identify insertion point (after existing utility functions)
- [ ] Add `validate_required_functions()` function:
  ```bash
  # validate_required_functions: Check that required functions exist after library sourcing
  # Usage: validate_required_functions "func1 func2 func3"
  # Returns: 0 if all functions exist, 1 if any missing
  # Note: Uses validation_error type (dependency_error is not a valid constant)
  validate_required_functions() {
    local required_functions="$1"
    local missing_functions=""

    for func in $required_functions; do
      if ! type "$func" &>/dev/null; then
        missing_functions="$missing_functions $func"
      fi
    done

    if [ -n "$missing_functions" ]; then
      log_command_error \
        "${COMMAND_NAME:-unknown}" \
        "${WORKFLOW_ID:-unknown}" \
        "${USER_ARGS:-}" \
        "validation_error" \
        "Missing required functions:$missing_functions" \
        "function_validation" \
        "$(jq -n --arg funcs "$missing_functions" '{missing_functions: $funcs}')"
      echo "ERROR: Missing required functions:$missing_functions" >&2
      return 1
    fi

    return 0
  }
  ```
- [ ] Add `execute_with_logging()` function:
  ```bash
  # execute_with_logging: Execute command with automatic error logging
  # Usage: execute_with_logging "operation_name" command [args...]
  # Returns: Command exit code
  # Effect: Logs error if command fails
  execute_with_logging() {
    local operation="$1"
    shift
    local output
    local exit_code

    output=$("$@" 2>&1)
    exit_code=$?

    if [ $exit_code -ne 0 ]; then
      log_command_error \
        "${COMMAND_NAME:-unknown}" \
        "${WORKFLOW_ID:-unknown}" \
        "${USER_ARGS:-}" \
        "execution_error" \
        "$operation failed: $(echo "$output" | head -1)" \
        "execute_wrapper" \
        "$(jq -n --argjson code "$exit_code" --arg op "$operation" \
           '{exit_code: $code, operation: $op}')"
      echo "$output" >&2
    else
      echo "$output"
    fi

    return $exit_code
  }
  ```
- [ ] Add both functions to exports section (conditional export block)
- [ ] Verify functions work by sourcing and testing manually

**Testing**:
```bash
# Test validate_required_functions with existing function
source .claude/lib/core/error-handling.sh
validate_required_functions "log_command_error ensure_error_log_exists"
echo "Exit code: $?"  # Expected: 0

# Test validate_required_functions with missing function
validate_required_functions "nonexistent_function_xyz"
echo "Exit code: $?"  # Expected: 1

# Test execute_with_logging with successful command
execute_with_logging "Echo test" echo "hello"
echo "Exit code: $?"  # Expected: 0

# Test execute_with_logging with failing command
execute_with_logging "False test" false
echo "Exit code: $?"  # Expected: 1
```

**Expected Duration**: 1.5 hours

### Phase 2: Testing and Documentation [NOT STARTED]
dependencies: [1]

**Objective**: Create unit tests and update documentation

**Complexity**: Low

**Tasks**:
- [ ] Create unit test file `.claude/tests/unit/test_error_handling_helpers.sh`:
  - Test validate_required_functions with all functions present
  - Test validate_required_functions with missing function
  - Test validate_required_functions with empty string
  - Test execute_with_logging with successful command
  - Test execute_with_logging with failing command
  - Test execute_with_logging captures output correctly
  - Verify error log entries have correct format
- [ ] Update `.claude/docs/concepts/patterns/error-handling.md`:
  - Add "Function Validation Pattern" section with validate_required_functions usage
  - Add "Wrapper Function Pattern" section with execute_with_logging usage
  - Add note that these are optional convenience functions
  - Add examples for both patterns
- [ ] Run pre-commit validation:
  ```bash
  bash .claude/scripts/validate-all-standards.sh --sourcing --suppression
  ```
- [ ] Run test suite to verify no regressions

**Testing**:
```bash
# Run new unit tests
bash .claude/tests/unit/test_error_handling_helpers.sh

# Run existing test suite
cd .claude/tests && bash run_all_tests.sh

# Verify documentation links work
# Check all internal references are valid
```

**Expected Duration**: 1 hour

## Testing Strategy

### Unit Testing
- Test both new functions in isolation
- Test error logging output format
- Test edge cases (empty input, special characters)

### Regression Testing
- Run existing test suite
- Verify other commands still work
- Check no performance degradation

## Documentation Requirements

### Updated Files
- `.claude/lib/core/error-handling.sh`: Add inline documentation for new functions
- `.claude/docs/concepts/patterns/error-handling.md`: Add usage patterns and examples

### New Documentation Sections
- "Function Validation Pattern" (~30 lines) - Note: optional convenience function
- "Wrapper Function Pattern" (~30 lines) - Note: optional convenience function

## Dependencies

### Internal Dependencies
- error-handling.sh: log_command_error function (exists)
- jq: Required for JSON context creation (standard utility)

### External Dependencies
- None

## Risk Assessment

### Low Risk
- Adding new functions to error-handling.sh is additive
- All changes are backward compatible
- Functions are optional (no forced adoption)

### Mitigation
- Test each function independently before integration
- Run pre-commit hooks to catch violations
- Verify existing functionality not affected

## Implementation Notes

### Standards Compliance
- All bash blocks must follow three-tier sourcing pattern
- Error logging must use WHICH/WHAT/WHERE structure
- Tests must use CLAUDE_TEST_MODE=1 isolation
- Use `validation_error` type (not `dependency_error` which is undefined)

### Adoption Strategy (Future)

These helper functions are available for use but NOT mandatory. Commands may choose to:
1. Continue using inline error handling for context-specific messages
2. Adopt `execute_with_logging` for simple operations where generic messages suffice
3. Use `validate_required_functions` in defensive programming scenarios

No retrofitting of existing commands is required or recommended at this time.
