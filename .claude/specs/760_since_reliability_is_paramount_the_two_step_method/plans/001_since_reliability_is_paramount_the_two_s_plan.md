# Two-Step Argument Pattern Systematic Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: Systematic implementation of two-step argument capture pattern for 4 selected commands
- **Scope**: Create reusable library, update 4 commands, update documentation standards
- **Estimated Phases**: 4
- **Estimated Hours**: 4-6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 38.5
- **Research Reports**:
  - [Scope Reduction Analysis](../reports/001_scope_reduction_analysis.md)
  - [Two-Step Pattern Systematic Implementation](../reports/001_two_step_pattern_systematic_implementation.md)
  - [Command Exclusion Analysis](../reports/002_command_exclusion_analysis.md)

## Scope

### Commands to Migrate (4 Commands)

The following 4 commands will be migrated to the two-step pattern:

| Command | File | Argument Pattern | Complexity |
|---------|------|------------------|------------|
| `/build` | build.md:70 | `PLAN_FILE="$1"` + `STARTING_PHASE="${2:-1}"` + flags | High |
| `/research-report` | research-report.md:29 | `WORKFLOW_DESCRIPTION="$1"` | Low |
| `/research-plan` | research-plan.md:30 | `FEATURE_DESCRIPTION="$1"` | Low |
| `/research-revise` | research-revise.md:30 | `REVISION_DESCRIPTION="$1"` | Medium |

### Scope Exclusions

The following commands are **explicitly excluded** from this migration:

- `/debug` - Complex workflow orchestrator with multi-phase investigation
- `/implement` - Critical plan executor with auto-resume and 5+ flags
- `/plan` - Primary planning orchestrator with research delegation
- `/revise` - Dual-mode command supporting interactive and auto-mode
- `/coordinate` - Already uses two-step pattern (canonical reference)
- `/fix` - Excluded to achieve minimal 4-command scope
- `/expand` - Mode detection logic adds complexity
- `/collapse` - Mode detection logic adds complexity
- `/setup` - Complex flag parsing
- `/convert-docs` - Directory arguments + optional flags

**Rationale**: This minimal scope focuses on commands with consistent, simple patterns (the three research-* commands with Low/Medium complexity) plus /build as the single High complexity command. This approach allows validation of the pattern with minimal risk.

## Overview

This plan implements the two-step argument capture pattern for 4 selected slash commands to improve reliability. The pattern uses a two-bash-block approach where Part 1 captures user input to a temp file via explicit substitution, and Part 2 reads from that file, eliminating shell expansion issues with special characters.

**Key Objectives**:
1. Create a reusable `argument-capture.sh` library to reduce per-command code from 15-25 lines to 3-5 lines
2. Update 4 selected commands to use the two-step pattern (build, research-report, research-plan, research-revise)
3. Update documentation standards to reflect the library usage
4. Maintain backward compatibility during transition via legacy filename fallbacks
5. Include testing for the new library and migrated commands

## Research Summary

Key findings from the research reports:

- **Canonical Reference**: The `/coordinate` command (lines 18-92) provides the production-tested two-step implementation
- **4 Commands for Migration**: research-report (Low), research-plan (Low), research-revise (Medium), build (High)
- **Library Integration**: The new `argument-capture.sh` should integrate with existing `state-persistence.sh` for state management
- **Consistent Pattern**: All 4 commands have single primary argument with embedded flag extraction (--complexity for research-* commands)
- **Risk Reduction**: Focusing on 4 commands reduces implementation time by ~50% vs original 8-command scope

Recommended approach: Start with foundation (library + tests), migrate all 3 research-* commands in one phase, then migrate /build separately due to its higher complexity.

## Success Criteria

- [ ] `argument-capture.sh` library created with source guard, version tracking, and error handling
- [ ] Library functions `capture_argument_part1()`, `capture_argument_part2()`, and `cleanup_argument_files()` implemented
- [ ] Test suite with ~8 test cases covering library functions and edge cases
- [ ] /research-report migrated to two-step pattern via library functions
- [ ] /research-plan migrated to two-step pattern via library functions
- [ ] /research-revise migrated to two-step pattern via library functions
- [ ] /build migrated to two-step pattern via library functions
- [ ] command-authoring-standards.md updated with library usage examples
- [ ] bash-block-execution-model.md updated with library reference
- [ ] Backward compatibility verified (legacy filename fallbacks work)
- [ ] All migrated commands execute correctly with various argument types

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
- Clear error messages with diagnostics
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
capture_argument_part1 "research-plan" "YOUR_FEATURE_DESCRIPTION_HERE"
```

Part 2 block:
```bash
set +H
source .claude/lib/argument-capture.sh
capture_argument_part2 "research-plan" "FEATURE_DESCRIPTION" || exit 1
```

### Integration Points

1. **state-persistence.sh**: Library integrates with existing EXIT trap patterns
2. **unified-location-detection.sh**: Uses CLAUDE_PROJECT_DIR detection
3. **workflow-initialization.sh**: Two-step capture precedes Phase 0 initialization

## Implementation Phases

### Phase 1: Foundation - Library Creation and Testing
Dependencies: []

**Objective**: Create the `argument-capture.sh` library with all core functions and comprehensive test suite

**Complexity**: Medium
**Estimated Time**: 2-2.5 hours

Tasks:
- [x] Create `/home/benjamin/.config/.claude/lib/argument-capture.sh` with library header
- [x] Implement source guard (`ARGUMENT_CAPTURE_SOURCED`)
- [x] Implement version tracking (`ARGUMENT_CAPTURE_VERSION="1.0.0"`)
- [x] Implement `capture_argument_part1()` function:
  - [x] mkdir -p for ~/.claude/tmp/
  - [x] Timestamp-based filename generation
  - [x] Path file creation
  - [x] Echo confirmation message
- [x] Implement `capture_argument_part2()` function:
  - [x] Read path file with fallback to legacy filename
  - [x] Read content file with error handling
  - [x] Empty string validation
  - [x] Export variable with captured value
  - [x] Return appropriate exit codes
- [x] Implement `cleanup_argument_files()` function
- [x] Add CLAUDE_PROJECT_DIR detection at top of library
- [x] Create `/home/benjamin/.config/.claude/tests/test_argument_capture.sh` with test harness
- [x] Implement basic function tests:
  - [x] test_capture_part1_creates_files
  - [x] test_capture_part2_reads_content
  - [x] test_capture_part2_exports_variable
  - [x] test_cleanup_removes_files
  - [x] test_part2_fails_without_part1
  - [x] test_part2_fails_with_empty_content
  - [x] test_handles_special_characters
  - [x] test_legacy_fallback
- [x] Add test to `run_all_tests.sh` test runner
- [x] Verify all tests pass

Testing:
```bash
# Test library sourcing
source .claude/lib/argument-capture.sh
echo "Version: $ARGUMENT_CAPTURE_VERSION"

# Run test suite
.claude/tests/test_argument_capture.sh
```

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(760): complete Phase 1 - Foundation Library and Tests`
- [ ] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

---

### Phase 2: Research Commands Migration
Dependencies: [1]

**Objective**: Migrate all 3 research-* commands to two-step pattern

**Complexity**: Low-Medium
**Estimated Time**: 1-1.5 hours

Commands to migrate:
1. `/research-report` - Low complexity (single argument with embedded --complexity flag)
2. `/research-plan` - Low complexity (single argument with embedded --complexity flag)
3. `/research-revise` - Medium complexity (single argument with embedded --complexity flag and path extraction)

Tasks:
- [ ] Migrate `/research-report` command:
  - [ ] Add Part 1 block with `capture_argument_part1 "research-report" "YOUR_WORKFLOW_DESCRIPTION_HERE"`
  - [ ] Modify Part 2 to use `capture_argument_part2 "research-report" "WORKFLOW_DESCRIPTION"`
  - [ ] Preserve embedded --complexity flag extraction
  - [ ] Test command execution
- [ ] Migrate `/research-plan` command:
  - [ ] Add Part 1 block with `capture_argument_part1 "research-plan" "YOUR_FEATURE_DESCRIPTION_HERE"`
  - [ ] Modify Part 2 to use `capture_argument_part2 "research-plan" "FEATURE_DESCRIPTION"`
  - [ ] Preserve embedded --complexity flag extraction
  - [ ] Test command execution
- [ ] Migrate `/research-revise` command:
  - [ ] Add Part 1 block with `capture_argument_part1 "research-revise" "YOUR_REVISION_DESCRIPTION_WITH_PLAN_PATH_HERE"`
  - [ ] Modify Part 2 to use `capture_argument_part2 "research-revise" "REVISION_DESCRIPTION"`
  - [ ] Preserve embedded --complexity flag extraction
  - [ ] Preserve path extraction using grep -oE regex
  - [ ] Test command execution
- [ ] Test all 3 commands with special characters in arguments
- [ ] Verify backward compatibility with legacy patterns

Testing:
```bash
# Test each migrated command manually
# Verify error messages are clear
# Test with special characters in input
```

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(760): complete Phase 2 - Research Commands Migration`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 3: Build Command Migration
Dependencies: [2]

**Objective**: Migrate /build command (High complexity with positional args + flags) to two-step pattern

**Complexity**: High
**Estimated Time**: 1-1.5 hours

Tasks:
- [ ] Migrate `/build` command:
  - [ ] Add Part 1 block with `capture_argument_part1 "build" "YOUR_PLAN_FILE_PATH [starting-phase] [--dry-run]"`
  - [ ] Modify argument parsing in Part 2:
    - [ ] Use `capture_argument_part2 "build" "BUILD_ARGS"` to get full argument string
    - [ ] Parse PLAN_FILE from first positional
    - [ ] Parse STARTING_PHASE from second positional (with default)
    - [ ] Preserve flag parsing for --dry-run
  - [ ] Preserve auto-resume logic for finding most recent plan
  - [ ] Test command execution with various argument combinations
- [ ] Test with positional args only
- [ ] Test with positional args + --dry-run flag
- [ ] Test with no args (auto-resume mode)
- [ ] Verify existing tests still pass

Testing:
```bash
# Test the migrated command with various combinations
# /build plan.md
# /build plan.md 3
# /build plan.md --dry-run
# /build plan.md 3 --dry-run
# /build (auto-resume)
```

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(760): complete Phase 3 - Build Command Migration`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 4: Documentation Updates
Dependencies: [1]

**Objective**: Update documentation standards with library usage examples

**Complexity**: Low
**Estimated Time**: 1 hour

Tasks:
- [ ] Update `/home/benjamin/.config/.claude/docs/reference/command-authoring-standards.md`:
  - [ ] Add section on using argument-capture.sh library
  - [ ] Add example showing library usage for simple command
  - [ ] Note that two-step pattern is recommended for reliability
- [ ] Update `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md`:
  - [ ] Reference argument-capture.sh library in two-step execution section
  - [ ] Add brief example of library usage
- [ ] Validate all internal links work correctly
- [ ] Run link validation script

Testing:
```bash
.claude/scripts/validate-links-quick.sh
```

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(760): complete Phase 4 - Documentation Updates`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Unit Testing
- **Library Functions**: Test each function in isolation with various inputs
- **Error Handling**: Verify appropriate error codes and messages
- **Edge Cases**: Special characters, empty strings, legacy fallback

### Integration Testing
- **Command Migration**: Test each of the 4 migrated commands end-to-end
- **Backward Compatibility**: Verify legacy filename fallbacks work
- **Argument Patterns**: Test embedded flag extraction in research-* commands

### Regression Testing
- **Full Test Suite**: Run `.claude/tests/run_all_tests.sh` after each phase

### Test Isolation
Per Testing Protocols, all tests must use:
```bash
export CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"
export CLAUDE_PROJECT_DIR="/tmp/test_project_$$"
```

## Documentation Requirements

### Files to Update
1. `command-authoring-standards.md` - Add library usage examples
2. `bash-block-execution-model.md` - Reference library

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
1. Commands require two bash blocks instead of one
2. Users must adapt to explicit substitution workflow
3. Temp file system dependency

### Backward Compatibility Measures
1. Legacy filename fallback in `capture_argument_part2()`
2. Clear error messages if Part 1 skipped

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Special character edge cases | Low | Medium | Test suite covers common cases |
| Concurrent execution conflicts | Low | Low | Timestamp-based filenames |
| User friction with new workflow | Low | Low | Only 4 commands affected |
| Orphaned temp files | Low | Low | EXIT trap cleanup |
| Backward compatibility breakage | Low | Medium | Legacy fallback patterns |

## Notes

### Implementation Order Rationale
Phases are ordered to manage risk:
1. Foundation + Tests first (verify library works)
2. Research commands together (similar patterns, build confidence)
3. Build command last (highest complexity)
4. Documentation can proceed in parallel with Phase 2+

### Minimal Scope Benefits
By focusing on only 4 commands (research-report, research-plan, research-revise, build), this migration:
- Achieves meaningful reliability improvement with minimal risk
- Provides consistent pattern across all research-* workflow commands
- Validates the library with one complex command (/build)
- Reduces implementation time to 4-6 hours (50% of previous 8-command scope)

### Future Migration Path
Additional commands can be migrated in follow-up efforts after this 4-command migration proves stable:
- /fix - Low complexity, easy addition
- /expand, /collapse - Mode detection patterns
- /setup, /convert-docs - Complex flag patterns
- /debug, /implement, /plan, /revise - Critical orchestrator commands (highest risk)
