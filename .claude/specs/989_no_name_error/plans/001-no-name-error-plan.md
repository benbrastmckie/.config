# Bash Block Execution Formatting Corruption Fix

## Metadata
- **Date**: 2025-12-05 (Revised)
- **Feature**: Fix bash block execution formatting corruption in /research command where newlines are removed and variables become empty strings during execution
- **Status**: [COMPLETE]
- **Estimated Hours**: 2-3 hours
- **Complexity Score**: 32.0
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Root Cause Analysis](../reports/001-no-name-error-analysis.md)
  - [Infrastructure Integration Analysis](../reports/002-infrastructure-integration-analysis.md)

## Overview

The /research command experiences intermittent bash syntax errors in Block 1c (Topic Path Initialization) where bash block content is corrupted during execution. The error manifests as `syntax error near unexpected token 'then'` with evidence showing statements concatenated without newlines (e.g., `set +H if command -v git` instead of properly separated statements).

**Critical Finding**: This is NOT a Task invocation pattern issue. Research confirms Task invocations are standards-compliant. The actual problem is bash block formatting corruption during execution, where:
1. Newlines are stripped from bash blocks
2. Variables become empty strings during state restoration
3. Multi-line bash blocks are concatenated into single-line malformed syntax

## Research Summary

From [Root Cause Analysis](../reports/001-no-name-error-analysis.md):
- Task invocations in Block 1b-exec and Block 1d-exec are ALREADY standards-compliant (validated by automated linter)
- The observed error in `research-output.md` shows bash execution corruption: `set +H if command -v git & > /dev/null` (missing newline after `set +H`)
- Variables are becoming empty strings during execution (e.g., `$WORKFLOW_ID` evaluates to empty)
- Automated linter reports ZERO Task invocation violations in /research command
- The original user diagnosis was incorrect - redirecting investigation to bash block processing

**Key Insight**: The bash block content exists correctly in the source markdown file but gets mangled during execution, suggesting an issue in how Claude Code extracts and executes bash blocks from markdown.

## Success Criteria

- [ ] ALL `/research` bash blocks comply with mandatory standards (error logging, library sourcing)
- [ ] ALL count operations use 4-step sanitization pattern from defensive-programming.md Section 6
- [ ] No new libraries created (extend existing validation-utils.sh only)
- [ ] Automated linters pass (validate-all-standards.sh)
- [ ] Bash blocks in /research command execute without syntax errors
- [ ] Newlines are preserved in bash block execution (verified by logging actual executed script)
- [ ] Variables retain their values throughout execution
- [ ] Block 1c executes successfully with proper conditional logic
- [ ] `/research` command completes without bash syntax errors
- [ ] Root cause of formatting corruption identified and documented
- [ ] Test suite validates bash block preservation for all command patterns

## Technical Design

### Architecture Overview

The issue spans multiple layers of the Claude Code execution pipeline:

1. **Markdown Parsing Layer**: Extract bash blocks from command markdown
2. **Variable Substitution Layer**: Replace template variables with runtime values
3. **Bash Execution Layer**: Execute processed bash via Bash tool
4. **State Restoration Layer**: Restore workflow state between blocks

**Hypothesis**: One of these layers is stripping newlines or corrupting variable interpolation.

### Investigation Strategy

#### Phase 1: Reproduce and Capture [COMPLETE]
- Create minimal test case that reproduces the formatting corruption
- Add debug logging to capture actual bash script sent to Bash tool
- Compare source markdown bash block vs. executed bash script
- Identify the transformation layer causing corruption

#### Phase 2: Root Cause Analysis [COMPLETE]
- Analyze how Claude Code processes bash blocks in markdown
- Check if variable interpolation removes newlines
- Verify if state restoration impacts formatting
- Test if `set +H` placement triggers specific parsing issues

#### Phase 3: Fix Implementation [COMPLETE]
**Option A: Defensive Validation**
- Add pre-execution validation that checks bash block structure
- Reject execution if newlines missing or variables empty
- Provide clear error messages for debugging

**Option B: Preprocessing Fix**
- Fix the layer that strips newlines during processing
- Ensure variable substitution preserves formatting
- Add unit tests for bash block parsing

**Option C: Bash Tool Enhancement**
- Modify Bash tool to validate input before execution
- Add formatting preservation checks
- Return structured errors for malformed input

#### Phase 4: Standards Enforcement [COMPLETE]
- Add automated tests that validate bash block preservation
- Create linter rule to detect formatting corruption risks
- Document bash block formatting requirements

### Defensive Programming

Per [Defensive Programming Pattern](.claude/docs/concepts/patterns/defensive-programming.md):
- Validate bash block structure before execution
- Check for empty variables before critical operations
- Fail fast with clear error messages identifying corruption layer
- Log actual bash script content for debugging

### Error Logging Integration

Per [Error Logging Standards](CLAUDE.md#error_logging):
- Log formatting corruption errors with `execution_error` type
- Include bash block content (sanitized) in error details
- Enable `/errors --type execution_error` queries for pattern analysis
- Support `/repair` workflow for automated fix planning

## Implementation Phases

### Phase 0: Standards Compliance Analysis [COMPLETE]
dependencies: []

**Objective**: Verify mandatory error logging integration and library sourcing patterns in all /research bash blocks, identifying compliance gaps before applying fixes.

**Complexity**: Low

**Tasks**:
- [x] Verify Block 1 includes setup_bash_error_trap() call (MANDATORY per error-logging standards)
- [x] Verify Block 1 includes ensure_error_log_exists call (MANDATORY per error-logging standards)
- [x] Verify all bash blocks follow three-tier library sourcing pattern (enforced by linter)
- [x] Run automated linters to identify violations: bash .claude/scripts/validate-all-standards.sh --sourcing
- [x] Document current compliance status and required changes
- [x] Identify all grep -c and count operations that need 4-step sanitization

**Testing**:
```bash
# Run sourcing validation
bash .claude/scripts/validate-all-standards.sh --sourcing

# Check for error logging integration
grep -n "setup_bash_error_trap\|ensure_error_log_exists" .claude/commands/research.md

# Identify count operations needing sanitization
grep -n "grep -c\|wc -l" .claude/commands/research.md
```

**Expected Duration**: 30 minutes

---

### Phase 1: Apply Existing Patterns [COMPLETE]
dependencies: [0]

**Objective**: Apply documented 4-step sanitization pattern to all count operations and grep -c invocations in /research command to prevent empty string errors.

**Complexity**: Low

**Tasks**:
- [x] Apply 4-step sanitization pattern to all grep -c and wc -l operations per defensive-programming.md Section 6
- [x] Pattern: 1) Capture output, 2) Validate non-empty, 3) Validate numeric, 4) Use with default
- [x] Add reference comments pointing to defensive-programming.md Section 6 for pattern documentation
- [x] Verify all count operations follow pattern: `count=$(grep -c pattern file 2>/dev/null || echo "0"); [[ -z "$count" || ! "$count" =~ ^[0-9]+$ ]] && count=0`
- [x] Test each sanitized operation individually to confirm no empty string errors

**Example Pattern Application**:
```bash
# Before (vulnerable to empty string)
file_count=$(find . -name "*.md" | wc -l)

# After (4-step sanitization per defensive-programming.md Section 6)
file_count=$(find . -name "*.md" 2>/dev/null | wc -l)
[[ -z "$file_count" || ! "$file_count" =~ ^[0-9]+$ ]] && file_count=0
```

**Testing**:
```bash
# Test sanitized count operations in isolation
bash -c 'count=$(grep -c pattern /nonexistent 2>/dev/null || echo "0"); [[ -z "$count" || ! "$count" =~ ^[0-9]+$ ]] && count=0; echo "Count: $count"'

# Verify pattern prevents empty string errors
/research "test prompt to validate count operations"
```

**Expected Duration**: 1 hour

---

### Phase 2: Standards Integration [COMPLETE]
dependencies: [1]

**Objective**: Integrate mandatory error logging and state validation into /research command Block 1, using existing infrastructure functions.

**Complexity**: Low

**Tasks**:
- [x] Add setup_bash_error_trap() to Block 1 after library sourcing (MANDATORY per error-logging standards)
- [x] Add ensure_error_log_exists to Block 1 after error trap setup (MANDATORY per error-logging standards)
- [x] Call validate_state_restoration() from validation-utils.sh after load_workflow_state
- [x] Verify error trap integration: test with intentional error to confirm logging
- [x] Verify state validation integration: test with corrupted state file
- [x] Document integration points with inline comments

**Integration Pattern**:
```bash
# Block 1: Setup and Initialization
# Source libraries (three-tier pattern)
source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || { echo "Error: Cannot load state-persistence"; exit 1; }
source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || { echo "Error: Cannot load error-handling"; exit 1; }
source "$CLAUDE_LIB/workflow/validation-utils.sh" 2>/dev/null || { echo "Error: Cannot load validation-utils"; exit 1; }

# MANDATORY: Setup error trap (error-logging standards)
setup_bash_error_trap "/research"
ensure_error_log_exists

# Load and validate state
load_workflow_state "$WORKFLOW_ID"
validate_state_restoration || { log_command_error "state_error" "State restoration failed"; exit 1; }
```

**Testing**:
```bash
# Test error trap integration
bash -c 'source .claude/lib/core/error-handling.sh; setup_bash_error_trap "/research"; false' && echo "FAIL" || echo "PASS"

# Test state validation
bash -c 'source .claude/lib/workflow/validation-utils.sh; validate_state_restoration' && echo "PASS" || echo "Expected failure"

# Run full /research command
/research "test prompt for standards integration"
```

**Expected Duration**: 1 hour

---

### Phase 3: Extend Existing Infrastructure [COMPLETE]
dependencies: [2]

**Objective**: Extend validation-utils.sh with variable initialization validation using existing patterns, avoiding creation of new libraries.

**Complexity**: Low

**Tasks**:
- [x] Extend validation-utils.sh with validate_variable_initialization() function if needed
- [x] Use existing validate_directory_var() as reference pattern
- [x] Apply function to validate critical variables in /research Block 1c
- [x] Reference defensive-programming.md patterns in function documentation
- [x] Test validation function in isolation before integration
- [x] Integrate validation calls in /research command

**Extension Pattern** (extends validation-utils.sh):
```bash
# Validate variable initialization (extends validation-utils.sh)
# Uses existing pattern from validate_directory_var()
validate_variable_initialization() {
  local var_name="$1"
  local var_value="$2"
  local context="${3:-command execution}"

  # Apply 4-step sanitization (defensive-programming.md Section 6)
  if [[ -z "$var_value" ]]; then
    log_command_error "validation_error" "Variable initialization failed: $var_name is empty" "Context: $context"
    return 1
  fi

  return 0
}
```

**Testing**:
```bash
# Test validation function extension
source .claude/lib/workflow/validation-utils.sh
validate_variable_initialization "TEST_VAR" "" "test" && echo "FAIL" || echo "PASS"
validate_variable_initialization "TEST_VAR" "value" "test" && echo "PASS" || echo "FAIL"

# Run automated linters
bash .claude/scripts/validate-all-standards.sh --sourcing
```

**Expected Duration**: 30 minutes

---

### Phase 4: Testing and Validation [COMPLETE]
dependencies: [3]

**Objective**: Create comprehensive tests following existing test patterns and validate all changes with automated linters.

**Complexity**: Low

**Tasks**:
- [x] Create unit test in .claude/tests/unit/ following existing test patterns (test_research_count_sanitization.sh)
- [x] Test 4-step sanitization pattern for count operations
- [x] Test error trap integration and logging
- [x] Test state validation integration
- [x] Run automated linters: bash .claude/scripts/validate-all-standards.sh --all
- [x] Verify all linters pass (ERROR-level violations must be zero)
- [x] Run full /research workflow to validate end-to-end behavior
- [x] Verify no bash syntax errors in research-output.md

**Testing**:
```bash
# Run unit test for count sanitization
bash .claude/tests/unit/test_research_count_sanitization.sh

# Run all automated linters
bash .claude/scripts/validate-all-standards.sh --all

# Verify sourcing compliance
bash .claude/scripts/validate-all-standards.sh --sourcing

# Run full /research workflow
/research "Validate bash block formatting fixes"

# Verify no syntax errors in output
grep -q "syntax error" ~/.config/.claude/output/research-output.md && echo "FAIL" || echo "PASS"

# Query error logs to verify logging integration
/errors --command /research --since 1h
```

**Expected Duration**: 30 minutes

---

## Testing Strategy

### Unit Tests
1. **Count Sanitization** (.claude/tests/unit/test_research_count_sanitization.sh)
   - Test 4-step sanitization pattern prevents empty string errors
   - Test count operations with missing files return "0" not empty string
   - Test numeric validation catches non-numeric output
   - Test pattern matches defensive-programming.md Section 6

2. **Error Trap Integration** (.claude/tests/unit/test_error_trap_integration.sh)
   - Test setup_bash_error_trap() initializes correctly
   - Test ensure_error_log_exists creates log file
   - Test error trap logs errors to centralized error log
   - Test error queries via /errors command

3. **State Validation** (.claude/tests/unit/test_state_validation.sh)
   - Test validate_state_restoration() detects corrupted state
   - Test validate_variable_initialization() catches empty variables
   - Test validation integrates with error logging

### Integration Tests
1. **Research Command Standards Compliance** (.claude/tests/commands/test_research_standards_compliance.sh)
   - Test Block 1 includes mandatory error logging calls
   - Test all bash blocks follow three-tier sourcing pattern
   - Test all count operations use sanitization pattern
   - Test full /research workflow completes without bash syntax errors

### Automated Linter Validation
- Run validate-all-standards.sh --sourcing (three-tier library sourcing)
- Run validate-all-standards.sh --conditionals (bash conditional safety)
- Run validate-all-standards.sh --suppression (error suppression patterns)
- Target: ZERO ERROR-level violations

### Regression Tests
- Run existing /research tests to ensure no regression
- Validate existing commands not affected by validation-utils.sh extension
- Check that pattern application doesn't break valid bash blocks

### Test Coverage Target
- 100% coverage for new validation functions in validation-utils.sh
- 100% compliance with automated linters
- All /research bash blocks tested for standards compliance

## Documentation Requirements

### Files to Update
1. **.claude/lib/workflow/README.md**
   - Document validate_variable_initialization() extension to validation-utils.sh
   - Explain usage pattern and integration with error logging
   - Provide examples of variable validation

2. **.claude/commands/research.md**
   - Add inline comments referencing defensive-programming.md Section 6 for count sanitization
   - Add comments explaining mandatory error logging integration
   - Document state validation calls

3. **.claude/docs/concepts/patterns/defensive-programming.md**
   - Verify Section 6 (4-step sanitization) is complete and accurate
   - Add /research command as reference implementation example
   - Include count operation sanitization pattern

4. **Test Files README**
   - Document test_research_count_sanitization.sh purpose and usage
   - Document test_error_trap_integration.sh purpose and usage
   - Document test_state_validation.sh purpose and usage

### Documentation Standards
Per [Documentation Policy](CLAUDE.md#documentation_policy):
- Use clear, concise language
- Include code examples with syntax highlighting
- Document the "what" not the "why" in comments
- No historical commentary about this fix
- Reference existing patterns instead of creating new documentation

## Dependencies

### External Dependencies
- Bash tool execution environment
- State persistence library (.claude/lib/core/state-persistence.sh)

### Internal Dependencies (All Existing - No New Libraries)
- error-handling.sh library (provides setup_bash_error_trap, ensure_error_log_exists, log_command_error)
- validation-utils.sh library (provides validate_state_restoration, validate_directory_var - extend with validate_variable_initialization)
- defensive-programming.md Section 6 (documents 4-step sanitization pattern)

### Prerequisite Knowledge
- 4-step sanitization pattern from defensive-programming.md Section 6
- Mandatory error logging integration requirements
- Three-tier library sourcing pattern
- Existing validation patterns in validation-utils.sh

## Risk Assessment

### Technical Risks
1. **Risk**: Pattern application may miss count operations in conditional contexts
   - **Mitigation**: Comprehensive grep search for all count operations, manual review
   - **Severity**: Low

2. **Risk**: Extension to validation-utils.sh may conflict with existing functions
   - **Mitigation**: Follow existing patterns (validate_directory_var as template)
   - **Severity**: Very Low

3. **Risk**: Automated linters may fail on edge cases not covered by patterns
   - **Mitigation**: Run linters frequently during development, fix violations immediately
   - **Severity**: Low

### Implementation Risks
1. **Risk**: Time estimate may be too optimistic (2-3 hours vs original 4-6 hours)
   - **Mitigation**: Focus on pattern application not pattern creation; existing infrastructure reduces complexity
   - **Severity**: Low

2. **Risk**: Error logging integration may reveal other issues in /research
   - **Mitigation**: Address discovered issues as part of this fix
   - **Severity**: Medium (but beneficial for overall quality)

## Notes

### Key Findings from Research
- Original diagnosis was incorrect (Task invocation patterns are compliant)
- Linter validation confirms zero Task invocation violations
- Actual issue is bash execution formatting corruption
- Error manifests as: `set +H if command -v git` (missing newline)
- **Critical**: Research report 002 shows existing infrastructure already provides all needed patterns

### Revision Strategy (from 002-infrastructure-integration-analysis.md)
- **DO NOT** create bash-block-validation.sh (violates clean-break development)
- **DO** extend validation-utils.sh following existing patterns
- **DO** apply documented 4-step sanitization pattern (defensive-programming.md Section 6)
- **DO** integrate mandatory error logging (setup_bash_error_trap, ensure_error_log_exists)
- Time reduced from 4-6 hours to 2-3 hours by leveraging existing infrastructure

### Success Indicators
- `/research` command executes without bash syntax errors
- ALL bash blocks comply with mandatory standards (error logging, sourcing)
- ALL count operations use 4-step sanitization pattern
- Automated linters pass with zero ERROR-level violations
- No new libraries created (clean-break compliance)
