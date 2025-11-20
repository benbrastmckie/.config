# Fix /revise Command Errors Implementation Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Fix /revise command bash execution and library sourcing errors
- **Scope**: Bash history expansion errors, CLAUDE_PROJECT_DIR bootstrap, library validation in revise.md and similar commands
- **Estimated Phases**: 4
- **Estimated Hours**: 3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 32.5
- **Status**: [NOT STARTED]
- **Research Reports**:
  - [Error Analysis](/home/benjamin/.config/.claude/specs/822_claude_reviseoutputmd_which_i_want_you_to/reports/001_error_analysis.md)
  - [Revise Command Architecture](/home/benjamin/.config/.claude/specs/822_claude_reviseoutputmd_which_i_want_you_to/reports/002_revise_command_architecture.md)
  - [Standards Compliance Integration](/home/benjamin/.config/.claude/specs/822_claude_reviseoutputmd_which_i_want_you_to/reports/003_standards_compliance_integration.md)
  - [Standards Compliance Analysis](/home/benjamin/.config/.claude/specs/822_claude_reviseoutputmd_which_i_want_you_to/reports/004_standards_compliance_analysis.md)

## Overview

This plan addresses two categories of critical errors in the /revise command:

1. **Bash History Expansion Errors**: The `\!` pattern in conditional expressions (line 115) causes "!: command not found" when passed through eval
2. **Library Function Not Found Errors**: Missing `CLAUDE_PROJECT_DIR` bootstrap in Part 3 (Research Phase) causes `load_workflow_state`, `sm_transition`, and `append_workflow_state` to fail

The root cause is a violation of the bash block execution model's subprocess isolation patterns. Each bash block runs in a new subprocess and must re-establish `CLAUDE_PROJECT_DIR` before sourcing libraries. The revise.md Part 3 (Research Phase) at lines 285-336 attempts to source libraries without bootstrapping this variable first.

Additionally, the `!` operator in pattern matching conditions should be replaced with `!=` to avoid eval-related escaping issues.

## Research Summary

Key findings from research reports:

- **Error Analysis (Report 001)**: Two distinct error categories - bash history expansion (`\!`) and library function not found. The `\!` syntax is incorrect bash and should use `!=` instead.
- **Revise Command Architecture (Report 002)**: The command has 5 parts but Part 3 (Research Phase) lacks the `CLAUDE_PROJECT_DIR` bootstrap that exists in Part 3 (Init). Evidence shows relative paths (`./reports`) when project dir not set.
- **Standards Compliance (Report 003)**: Violation of Pattern 4 from bash-block-execution-model.md (Library Re-sourcing with Source Guards). Similar commands (plan.md, debug.md, research.md) all include the bootstrap pattern.
- **Standards Compliance (Report 004)**: Library paths must use new subdirectory structure (e.g., `.claude/lib/core/state-persistence.sh` instead of `.claude/lib/state-persistence.sh`) per November 2025 reorganization.

Recommended approach: Apply the standard bootstrap pattern to all subsequent bash blocks and replace `!` conditionals with `!=` patterns to avoid eval escaping.

## Success Criteria
- [ ] No "!: command not found" errors when running /revise
- [ ] No "conditional binary operator expected" syntax errors
- [ ] load_workflow_state, sm_transition, append_workflow_state functions available in all blocks
- [ ] CLAUDE_PROJECT_DIR correctly set in Part 3 (Research Phase)
- [ ] SPECS_DIR resolves to absolute paths (not `.` or `./reports`)
- [ ] /revise completes full workflow without library sourcing errors
- [ ] Similar pattern fixes applied to debug.md, plan.md, research.md if needed
- [ ] All existing tests pass: `.claude/tests/run_all_tests.sh`

## Technical Design

### Architecture Decisions

1. **Bootstrap Pattern Placement**: Add CLAUDE_PROJECT_DIR bootstrap to Part 3 (Research Phase) lines 285-290, before library sourcing
2. **Negation Operator Replacement**: Replace `[[ ! "$VAR" = pattern ]]` with `[[ "$VAR" != pattern ]]` throughout
3. **Library Validation**: Add function existence checks after sourcing to provide clear error messages
4. **Consistency Check**: Audit similar commands for the same issues

### Component Interactions

```
revise.md Part 3 (Research Phase)
  |
  +-- Bootstrap CLAUDE_PROJECT_DIR (git rev-parse or upward search)
  |
  +-- Export CLAUDE_PROJECT_DIR
  |
  +-- Source state-persistence.sh (with validation)
  |
  +-- Source workflow-state-machine.sh
  |
  +-- Load workflow state
  |
  +-- Execute research phase
```

### Integration Points

- **core/state-persistence.sh**: Provides load_workflow_state, append_workflow_state functions
- **workflow/workflow-state-machine.sh**: Provides sm_transition, sm_current_state functions
- **core/library-version-check.sh**: Provides check_library_requirements function
- **core/error-handling.sh**: Provides error handling utilities
- **bash-block-execution-model.md**: Pattern 4 compliance for library re-sourcing

## Implementation Phases

### Phase 1: Fix Bash Negation Operators [NOT STARTED]
dependencies: []

**Objective**: Replace all `!` conditional operators with `!=` patterns to avoid eval escaping issues

**Complexity**: Low

Tasks:
- [ ] Read revise.md line 115 to confirm exact negation pattern (file: /home/benjamin/.config/.claude/commands/revise.md:115)
- [ ] Replace `[[ ! "$ORIGINAL_PROMPT_FILE_PATH" = /* ]]` with `[[ "$ORIGINAL_PROMPT_FILE_PATH" != /* ]]`
- [ ] Search for other `[[ !` patterns in revise.md: `grep -n '\[\[ !' revise.md`
- [ ] Search debug.md for same pattern: `grep -n '\[\[ !' debug.md`
- [ ] Search plan.md for same pattern: `grep -n '\[\[ !' plan.md`
- [ ] Search research.md for same pattern: `grep -n '\[\[ !' research.md`
- [ ] Fix any additional occurrences found using same `!=` replacement

Testing:
```bash
# Verify syntax is correct
bash -n /home/benjamin/.config/.claude/commands/revise.md || echo "Syntax error in revise.md"

# Verify no \! patterns remain (should return nothing)
grep -n '\\!' /home/benjamin/.config/.claude/commands/revise.md && echo "WARNING: \\! pattern found"

# Verify != pattern is present
grep -n '\[\[ "\$ORIGINAL_PROMPT_FILE_PATH" != /\*' /home/benjamin/.config/.claude/commands/revise.md
```

**Expected Duration**: 0.5 hours

### Phase 2: Add CLAUDE_PROJECT_DIR Bootstrap to Research Phase [NOT STARTED]
dependencies: [1]

**Objective**: Add missing project directory bootstrap to Part 3 (Research Phase Execution) before library sourcing

**Complexity**: Medium

Tasks:
- [ ] Read revise.md Part 3 Research Phase (lines 285-340) to understand current structure (file: /home/benjamin/.config/.claude/commands/revise.md:285-340)
- [ ] Read reference implementation from plan.md (lines 58-80) for correct bootstrap pattern (file: /home/benjamin/.config/.claude/commands/plan.md:58-80)
- [ ] Insert CLAUDE_PROJECT_DIR bootstrap after `set +H` and before library sourcing (after line 287)
- [ ] Add bootstrap pattern:
  ```bash
  # Bootstrap CLAUDE_PROJECT_DIR (subprocess isolation)
  if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
    if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
      CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
    else
      current_dir="$(pwd)"
      while [ "$current_dir" != "/" ]; do
        if [ -d "$current_dir/.claude" ]; then
          CLAUDE_PROJECT_DIR="$current_dir"
          break
        fi
        current_dir="$(dirname "$current_dir")"
      done
    fi
  fi

  if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
    echo "ERROR: Failed to detect project directory" >&2
    exit 1
  fi
  export CLAUDE_PROJECT_DIR
  ```
- [ ] Update library source paths to use new subdirectory structure:
  ```bash
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh"
  ```
- [ ] Verify bootstrap comes before lines 288-290 (library sourcing)
- [ ] Add brief WHAT comment: `# Bootstrap project directory for subprocess isolation`
- [ ] Verify Part 4 has bootstrap (lines 415-426) - confirm no action needed
- [ ] Verify Part 5 has bootstrap (lines 567-568) - confirm no action needed

Testing:
```bash
# Verify syntax is correct
bash -n /home/benjamin/.config/.claude/commands/revise.md || echo "Syntax error in revise.md"

# Verify bootstrap pattern exists before library sourcing in Part 3 Research
grep -A 5 "Part 3.*Research" /home/benjamin/.config/.claude/commands/revise.md | grep -q "git rev-parse" && echo "Bootstrap found"

# Check that git detection is present
grep -c "git rev-parse --show-toplevel" /home/benjamin/.config/.claude/commands/revise.md
```

**Expected Duration**: 0.75 hours

### Phase 3: Add Library Sourcing Validation [NOT STARTED]
dependencies: [2]

**Objective**: Add validation after library sourcing to provide clear error messages

**Complexity**: Low

Tasks:
- [ ] After state-persistence.sh sourcing (revise.md line 288), add validation:
  ```bash
  if ! declare -f load_workflow_state >/dev/null 2>&1; then
    echo "ERROR: state-persistence.sh functions not available" >&2
    echo "DIAGNOSTIC: CLAUDE_PROJECT_DIR=$CLAUDE_PROJECT_DIR" >&2
    exit 1
  fi
  ```
- [ ] After workflow-state-machine.sh sourcing (revise.md line 290), add validation:
  ```bash
  if ! declare -f sm_transition >/dev/null 2>&1; then
    echo "ERROR: workflow-state-machine.sh functions not available" >&2
    exit 1
  fi
  ```
- [ ] Add stderr redirection to source statements per output-formatting-standards.md (using new subdirectory paths):
  ```bash
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
  ```
- [ ] Verify error handling follows output formatting standards (errors to stderr)

Testing:
```bash
# Verify syntax is correct
bash -n /home/benjamin/.config/.claude/commands/revise.md || echo "Syntax error in revise.md"

# Verify validation pattern exists
grep -q "declare -f load_workflow_state" /home/benjamin/.config/.claude/commands/revise.md && echo "Validation found"

# Verify stderr redirection on source with new subdirectory paths
grep "source.*lib/core/state-persistence.sh.*2>/dev/null" /home/benjamin/.config/.claude/commands/revise.md
grep "source.*lib/workflow/workflow-state-machine.sh.*2>/dev/null" /home/benjamin/.config/.claude/commands/revise.md
```

**Expected Duration**: 0.5 hours

### Phase 4: Testing and Verification [NOT STARTED]
dependencies: [3]

**Objective**: Verify all errors are resolved and the /revise command completes successfully

**Complexity**: Medium

Tasks:
- [ ] Run /revise command with a test revision on an existing plan
- [ ] Verify no "!: command not found" errors in output
- [ ] Verify no "conditional binary operator expected" errors
- [ ] Verify no "load_workflow_state: command not found" errors
- [ ] Verify no "sm_transition: command not found" errors
- [ ] Verify SPECS_DIR resolves to absolute path (not `.`)
- [ ] Verify research report is created successfully
- [ ] Verify plan revision completes successfully
- [ ] Run test suite: `.claude/tests/run_all_tests.sh`
- [ ] Verify test_command_standards_compliance.sh passes

Testing:
```bash
# Full workflow test - run /revise on a test plan
# Create simple test plan first:
mkdir -p /home/benjamin/.config/.claude/specs/test_revise_fix/plans
cat > /home/benjamin/.config/.claude/specs/test_revise_fix/plans/001_test_plan.md << 'EOF'
# Test Plan
## Metadata
- **Date**: 2025-11-19
- **Status**: [NOT STARTED]

## Overview
Test plan for /revise error fix verification.

### Phase 1: Test [NOT STARTED]
- [ ] Task 1
EOF

# Run /revise with test description
# /revise "Add a second task to the test plan in /home/benjamin/.config/.claude/specs/test_revise_fix/plans/001_test_plan.md"

# After test, cleanup:
rm -rf /home/benjamin/.config/.claude/specs/test_revise_fix

# Run automated tests
/home/benjamin/.config/.claude/tests/run_all_tests.sh

# Verify command standards compliance
/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh
```

**Expected Duration**: 1.25 hours

## Testing Strategy

### Test Approach
1. **Unit Testing**: Bash syntax validation with `bash -n`
2. **Pattern Validation**: grep-based verification of correct patterns
3. **Integration Testing**: Full /revise workflow execution
4. **Regression Testing**: Run full test suite

### Test Commands
- `bash -n` for syntax validation
- `grep` for pattern verification
- Manual /revise execution for full workflow test
- `.claude/tests/run_all_tests.sh` for regression testing

### Success Metrics
- All bash syntax checks pass
- No error patterns in /revise output
- Full workflow completes without errors
- Test suite passes

## Documentation Requirements

### Updates Needed
- [ ] Add comment in revise.md explaining subprocess isolation requirement
- [ ] No new documentation files needed (existing docs/concepts/bash-block-execution-model.md covers patterns)

### Cross-References
- Reference existing documentation at `.claude/docs/concepts/bash-block-execution-model.md` for pattern details

## Dependencies

### External Dependencies
- None

### Prerequisites
- Existing plan file to test revision workflow
- Test infrastructure in `.claude/tests/`

### Risk Mitigation
- **Low Risk**: Changes are isolated to specific bash patterns in revise.md
- **Fallback**: Can revert to previous revise.md if issues arise
- **Testing**: Multiple verification steps ensure each fix is validated independently

## Notes

### Library Path Reorganization (November 2025)
The `.claude/lib/` directory was reorganized into functional subdirectories:
- `core/` - Essential infrastructure (state-persistence.sh, error-handling.sh)
- `workflow/` - Orchestration (workflow-state-machine.sh, checkpoint-utils.sh)
- `plan/`, `artifact/`, `convert/`, `util/` - Domain-specific utilities

All source statements must use the new subdirectory paths. See `.claude/lib/README.md` for complete structure.

### Implementation Order
Execute phases in sequence - each builds on previous:
1. Fix negation operators first (simplest change)
2. Add bootstrap pattern (core fix) - includes updating to new library paths
3. Add validation (defensive programming)
4. Full testing (verification)

### Backward Compatibility
- Changes are fully backward compatible
- No API changes to library functions
- No changes to workflow behavior, only fix execution errors

### Future Improvements
After this fix is verified working, consider:
- Auditing all commands for `\!` patterns using automated test
- Creating shared bootstrap helper in lib/ directory
- Adding pre-commit hook to detect subprocess isolation violations
