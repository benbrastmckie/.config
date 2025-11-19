# Two-Step Argument Pattern Systematic Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: Systematic implementation of two-step argument capture pattern across all slash commands
- **Scope**: Create reusable library, update 13 commands, update documentation standards
- **Estimated Phases**: 6
- **Estimated Hours**: 14-18
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 90.5
- **Research Reports**:
  - [Two-Step Pattern Systematic Implementation](../reports/001_two_step_pattern_systematic_implementation.md)

## Overview

This plan implements the two-step argument capture pattern systematically across all slash commands to maximize reliability. The pattern uses a two-bash-block approach where Part 1 captures user input to a temp file via explicit substitution, and Part 2 reads from that file, eliminating shell expansion issues with special characters.

**Key Objectives**:
1. Create a reusable `argument-capture.sh` library to reduce per-command code from 15-25 lines to 3-5 lines
2. Update all 13 commands currently using direct $1 capture to use the two-step pattern
3. Update documentation standards to make two-step pattern REQUIRED (not optional)
4. Maintain backward compatibility during transition via legacy filename fallbacks
5. Include comprehensive testing for the new library and migrated commands

## Research Summary

Key findings from the research report:

- **Canonical Reference**: The `/coordinate` command (lines 18-92) provides the production-tested two-step implementation
- **13 Commands Need Migration**: plan, debug, fix, implement, build, research-report, research-plan, research-revise, revise, expand, collapse, setup, convert-docs
- **Library Integration**: The new `argument-capture.sh` should integrate with existing `state-persistence.sh` for state management
- **Migration Complexity Tiers**: Commands categorized into Low (3), Medium (6), and High (4) complexity migrations
- **Breaking Changes**: Users must adapt to explicit substitution workflow; mitigated by clear instructions

Recommended approach: Phased migration starting with foundation (library + tests), progressing through simple commands to complex commands, with documentation updates concurrent with Phase 1.

## Success Criteria

- [ ] `argument-capture.sh` library created with source guard, version tracking, and comprehensive error handling
- [ ] Library functions `capture_argument_part1()`, `capture_argument_part2()`, and `cleanup_argument_files()` implemented
- [ ] Test suite with ≥15 test cases covering all library functions, edge cases, and concurrent execution
- [ ] All 13 commands updated to use the two-step pattern via library functions
- [ ] command-authoring-standards.md updated to mark two-step pattern as REQUIRED
- [ ] bash-block-execution-model.md updated with library usage examples
- [ ] New guide created: `two-step-argument-capture-guide.md`
- [ ] Backward compatibility verified (legacy filename fallbacks work)
- [ ] All existing command tests pass after migration
- [ ] No regressions in command functionality

## Technical Design

### Library Architecture

**Location**: `/home/benjamin/.config/.claude/lib/argument-capture.sh`

**Core Functions**:
```bash
# Part 1: Capture argument to temp file
capture_argument_part1() {
  local command_name="${1:-command}"
  local placeholder_text="${2:-YOUR_ARGUMENT_HERE}"
  # Creates: ~/.claude/tmp/{command_name}_arg_{timestamp}.txt
  # Creates: ~/.claude/tmp/{command_name}_arg_path.txt
}

# Part 2: Read captured argument
capture_argument_part2() {
  local command_name="${1:-command}"
  local variable_name="${2:-CAPTURED_ARG}"
  # Reads path file, then content file
  # Exports variable with captured value
  # Returns 1 on failure with diagnostics
}

# Cleanup: Remove temp files
cleanup_argument_files() {
  local command_name="${1:-command}"
  # Removes all temp files for command
}
```

**Design Principles**:
- Source guard to prevent multiple sourcing
- Version tracking for compatibility checks
- Timestamp-based filenames for concurrent execution safety
- Legacy filename fallback for backward compatibility
- Comprehensive error messages with diagnostics
- EXIT trap integration for cleanup

### Command Migration Pattern

**Before** (direct $1 capture):
```bash
set +H
FEATURE_DESCRIPTION="$1"
if [ -z "$FEATURE_DESCRIPTION" ]; then
  echo "ERROR: Feature description required"
  exit 1
fi
```

**After** (two-step with library):

Part 1 block:
```bash
set +H
source .claude/lib/argument-capture.sh
capture_argument_part1 "plan" "YOUR_FEATURE_DESCRIPTION_HERE" "FEATURE_DESCRIPTION"
```

Part 2 block:
```bash
set +H
source .claude/lib/argument-capture.sh
capture_argument_part2 "plan" "FEATURE_DESCRIPTION" || exit 1
```

### Integration Points

1. **state-persistence.sh**: Library integrates with existing EXIT trap patterns
2. **unified-location-detection.sh**: Uses CLAUDE_PROJECT_DIR detection
3. **workflow-initialization.sh**: Two-step capture precedes Phase 0 initialization

## Implementation Phases

### Phase 1: Foundation - Library Creation
Dependencies: []

**Objective**: Create the `argument-capture.sh` library with all core functions and comprehensive error handling

**Complexity**: Medium
**Estimated Time**: 3-4 hours

Tasks:
- [ ] Create `/home/benjamin/.config/.claude/lib/argument-capture.sh` with library header
- [ ] Implement source guard (`ARGUMENT_CAPTURE_SOURCED`)
- [ ] Implement version tracking (`ARGUMENT_CAPTURE_VERSION="1.0.0"`)
- [ ] Implement `capture_argument_part1()` function:
  - [ ] mkdir -p for ~/.claude/tmp/
  - [ ] Timestamp-based filename generation
  - [ ] Path file creation
  - [ ] Echo confirmation message
- [ ] Implement `capture_argument_part2()` function:
  - [ ] Read path file with fallback to legacy filename
  - [ ] Read content file with error handling
  - [ ] Empty string validation
  - [ ] Export variable with captured value
  - [ ] Return appropriate exit codes
- [ ] Implement `cleanup_argument_files()` function:
  - [ ] Remove all temp files for command
  - [ ] Handle missing files gracefully
- [ ] Add CLAUDE_PROJECT_DIR detection at top of library
- [ ] Add comprehensive inline documentation following existing library patterns
- [ ] Test library sourcing works correctly

Testing:
```bash
# Test library sourcing
source .claude/lib/argument-capture.sh
echo "Version: $ARGUMENT_CAPTURE_VERSION"
```

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(760): complete Phase 1 - Foundation Library Creation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 2: Testing - Library Test Suite
Dependencies: [1]

**Objective**: Create comprehensive test suite for the argument-capture library

**Complexity**: Medium
**Estimated Time**: 2-3 hours

Tasks:
- [ ] Create `/home/benjamin/.config/.claude/tests/test_argument_capture.sh`
- [ ] Implement test harness with setup/teardown:
  - [ ] Create isolated test directory with temp files
  - [ ] Set `CLAUDE_SPECS_ROOT` override for isolation
  - [ ] Cleanup trap for test artifacts
- [ ] Implement basic function tests:
  - [ ] test_capture_part1_creates_files
  - [ ] test_capture_part1_uses_timestamp
  - [ ] test_capture_part2_reads_content
  - [ ] test_capture_part2_exports_variable
  - [ ] test_cleanup_removes_files
- [ ] Implement error handling tests:
  - [ ] test_part2_fails_without_part1
  - [ ] test_part2_fails_with_empty_content
  - [ ] test_part2_legacy_fallback
  - [ ] test_handles_missing_path_file
- [ ] Implement special character tests:
  - [ ] test_handles_quotes
  - [ ] test_handles_dollar_signs
  - [ ] test_handles_newlines
  - [ ] test_handles_backticks
  - [ ] test_handles_exclamation_marks
- [ ] Implement concurrent execution tests:
  - [ ] test_concurrent_commands_no_collision
  - [ ] test_concurrent_different_commands
- [ ] Add test to `run_all_tests.sh` test runner
- [ ] Verify all tests pass

Testing:
```bash
.claude/tests/test_argument_capture.sh
.claude/tests/run_all_tests.sh
```

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(760): complete Phase 2 - Library Test Suite`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 3: Simple Commands Migration
Dependencies: [2]

**Objective**: Migrate low-complexity commands (single primary argument) to two-step pattern

**Complexity**: Low
**Estimated Time**: 2-3 hours

Commands to migrate:
1. `/fix` - Single issue description
2. `/research-report` - Single workflow description
3. `/research-plan` - Single feature description

Tasks:
- [ ] Migrate `/fix` command:
  - [ ] Add Part 1 block with `capture_argument_part1 "fix" "YOUR_ISSUE_DESCRIPTION_HERE"`
  - [ ] Modify Part 2 to use `capture_argument_part2 "fix" "ISSUE_DESCRIPTION"`
  - [ ] Remove direct $1 capture
  - [ ] Test command execution
- [ ] Migrate `/research-report` command:
  - [ ] Add Part 1 block with appropriate placeholder
  - [ ] Modify Part 2 to use library function
  - [ ] Remove direct $1 capture
  - [ ] Test command execution
- [ ] Migrate `/research-plan` command:
  - [ ] Add Part 1 block with appropriate placeholder
  - [ ] Modify Part 2 to use library function
  - [ ] Remove direct $1 capture
  - [ ] Test command execution
- [ ] Verify existing tests still pass for migrated commands
- [ ] Test backward compatibility with legacy patterns

Testing:
```bash
# Test each migrated command manually
# Verify error messages are clear
# Test with special characters in input
```

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(760): complete Phase 3 - Simple Commands Migration`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 4: Medium Commands Migration
Dependencies: [3]

**Objective**: Migrate medium-complexity commands (multiple arguments or path extraction) to two-step pattern

**Complexity**: Medium
**Estimated Time**: 3-4 hours

Commands to migrate:
1. `/plan` - Primary description + optional report paths array
2. `/debug` - Issue description + optional context reports
3. `/research-revise` - Revision description with path extraction
4. `/expand` - Path or phase/stage mode detection
5. `/collapse` - Path or phase/stage mode detection
6. `/convert-docs` - Directories + optional flags

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Tasks:
- [ ] Migrate `/plan` command:
  - [ ] Add Part 1 block for feature description
  - [ ] Modify argument parsing to use `capture_argument_part2`
  - [ ] Preserve report paths array parsing after Part 2
  - [ ] Test with and without report paths
- [ ] Migrate `/debug` command:
  - [ ] Add Part 1 block for issue description
  - [ ] Modify to use library function
  - [ ] Preserve context reports parsing
  - [ ] Test command execution
- [ ] Migrate `/research-revise` command:
  - [ ] Add Part 1 block for revision description
  - [ ] Modify to use library function
  - [ ] Preserve path extraction logic
  - [ ] Test command execution
- [ ] Migrate `/expand` command:
  - [ ] Add Part 1 block for path/phase argument
  - [ ] Preserve mode detection (auto vs specific)
  - [ ] Test both auto and specific modes
- [ ] Migrate `/collapse` command:
  - [ ] Add Part 1 block for path/phase argument
  - [ ] Preserve mode detection logic
  - [ ] Test both modes
- [ ] Migrate `/convert-docs` command:
  - [ ] Add Part 1 block for directory arguments
  - [ ] Preserve flag parsing
  - [ ] Test command execution
- [ ] Verify existing tests still pass for migrated commands

Testing:
```bash
# Test each migrated command with various argument combinations
# Test mode detection still works
# Verify array argument handling
```

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(760): complete Phase 4 - Medium Commands Migration`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 5: Complex Commands Migration
Dependencies: [4]

**Objective**: Migrate high-complexity commands (multiple positional args + flags) to two-step pattern

**Complexity**: High
**Estimated Time**: 3-4 hours

Commands to migrate:
1. `/implement` - Multiple positional args + 5+ flags
2. `/build` - Multiple positional args + flags
3. `/revise` - Mode detection + flags
4. `/setup` - Flags with values

Tasks:
- [ ] Migrate `/implement` command:
  - [ ] Design Part 1 capture strategy (primary argument capture)
  - [ ] Add Part 1 block for plan file path
  - [ ] Modify argument parsing in Part 2
  - [ ] Preserve flag parsing (--dashboard, --dry-run, --create-pr, --report-scope-drift, --force-replan)
  - [ ] Preserve default for STARTING_PHASE
  - [ ] Test with all flag combinations
- [ ] Migrate `/build` command:
  - [ ] Add Part 1 block for plan file path
  - [ ] Modify argument parsing
  - [ ] Preserve flag parsing (--dry-run)
  - [ ] Test command execution
- [ ] Migrate `/revise` command:
  - [ ] Add Part 1 block for revision details
  - [ ] Modify argument parsing
  - [ ] Preserve --auto-mode and --context flag handling
  - [ ] Test interactive and auto modes
- [ ] Migrate `/setup` command:
  - [ ] Add Part 1 block for project directory/flags
  - [ ] Preserve complex flag parsing (--cleanup, --dry-run, --validate, --analyze, --apply-report, --enhance-with-docs)
  - [ ] Test all flag combinations
- [ ] Verify existing tests still pass for migrated commands
- [ ] Run integration tests for workflow commands

Testing:
```bash
# Test complex flag combinations
# Test auto-resume functionality in /implement
# Verify default values work correctly
.claude/tests/run_all_tests.sh
```

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(760): complete Phase 5 - Complex Commands Migration`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 6: Documentation Updates
Dependencies: [2]

**Objective**: Update documentation standards and create new guide for two-step pattern

**Complexity**: Medium
**Estimated Time**: 2-3 hours

Tasks:
- [ ] Update `/home/benjamin/.config/.claude/docs/reference/command-authoring-standards.md`:
  - [ ] Change "Recommendation Summary" table to mark two-step as REQUIRED for all arguments
  - [ ] Update Pattern 1 to note it's deprecated (only for internal paths)
  - [ ] Add section on using argument-capture.sh library
  - [ ] Update "When to use" guidance to be prescriptive
- [ ] Update `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md`:
  - [ ] Expand "Example 2: Two-Step Execution Pattern" with library usage
  - [ ] Add section on argument capture as execution model foundation
  - [ ] Document the two-bash-block requirement
- [ ] Create `/home/benjamin/.config/.claude/docs/guides/two-step-argument-capture-guide.md`:
  - [ ] Rationale for universal adoption
  - [ ] Library API reference
  - [ ] Migration checklist for each command type
  - [ ] Troubleshooting common issues
  - [ ] Examples for all command patterns (simple, medium, complex)
- [ ] Update CLAUDE.md if needed to reference new guide
- [ ] Validate all internal links work correctly
- [ ] Run link validation script

Testing:
```bash
.claude/scripts/validate-links-quick.sh
```

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(760): complete Phase 6 - Documentation Updates`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Unit Testing
- **Library Functions**: Test each function in isolation with various inputs
- **Error Handling**: Verify appropriate error codes and messages
- **Edge Cases**: Special characters, empty strings, concurrent execution

### Integration Testing
- **Command Migration**: Test each migrated command end-to-end
- **Backward Compatibility**: Verify legacy filename fallbacks work
- **Workflow Integration**: Test commands in actual workflow contexts

### Regression Testing
- **Existing Tests**: All existing command tests must pass
- **Full Test Suite**: Run `.claude/tests/run_all_tests.sh` after each phase

### Test Isolation
Per Testing Protocols, all tests must use:
```bash
export CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"
export CLAUDE_PROJECT_DIR="/tmp/test_project_$$"
```

## Documentation Requirements

### Files to Update
1. `command-authoring-standards.md` - Make two-step REQUIRED
2. `bash-block-execution-model.md` - Add library usage examples

### Files to Create
1. `two-step-argument-capture-guide.md` - Comprehensive guide

### Link Validation
- Run `.claude/scripts/validate-links-quick.sh` before committing
- Ensure all internal links use relative paths

## Dependencies

### External Dependencies
- `bash` 4.0+ (for associative arrays if needed)
- `date` with `%N` support (nanoseconds for unique filenames)

### Internal Dependencies
- `state-persistence.sh` - EXIT trap patterns
- `unified-location-detection.sh` - CLAUDE_PROJECT_DIR detection

### Breaking Changes
1. Users must adapt to explicit substitution workflow
2. Commands require two bash blocks instead of one
3. Temp file system dependency

### Backward Compatibility Measures
1. Legacy filename fallback in `capture_argument_part2()`
2. Clear error messages if Part 1 skipped
3. Gradual rollout through phases

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Special character edge cases | Low | Medium | Comprehensive test suite |
| Concurrent execution conflicts | Low | Low | Timestamp-based filenames |
| User friction with new workflow | Medium | Medium | Clear documentation, consistent placeholders |
| Orphaned temp files | Low | Low | EXIT trap cleanup, periodic cleanup |
| Backward compatibility breakage | Low | High | Legacy fallback patterns |

## Notes

### Implementation Order Rationale
Phases are ordered to manage risk:
1. Foundation + Tests before any migration (verify library works)
2. Simple commands first (low risk, build confidence)
3. Medium commands (moderate complexity)
4. Complex commands last (highest risk)
5. Documentation can proceed in parallel with Phase 2+

### Expansion Hint
If Phase 4 or 5 prove too complex during implementation, consider using `/expand` to break them into detailed stage files. Complexity score of 90.5 suggests potential for expansion.
