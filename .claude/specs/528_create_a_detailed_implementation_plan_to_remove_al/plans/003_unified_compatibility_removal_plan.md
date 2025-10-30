# Implementation Plan: Remove All Compatibility Layers

## Metadata

- **Plan ID**: 003
- **Created**: 2025-10-29
- **Status**: Not Started
- **Structure Level**: 1 (phases expanded to separate files)
- **Expanded Phases**: [3, 5]
- **Estimated Duration**: 3-4 hours
- **Complexity**: 7.5/10
- **Risk Level**: Medium

## Standards Compliance

- **Development Philosophy**: Clean-break refactoring, no backward compatibility
- **Error Handling**: Fail-fast with immediate bash errors for missing functions
- **Testing Protocol**: All 77/77 tests must pass (100% pass rate required)
- **Commit Strategy**: Single atomic commit for all compatibility layer removals
- **Rollback Strategy**: Git revert only (no archive files)

## Overview

### Objective

Remove all 4 compatibility layers from the Claude Code infrastructure in a single clean-break operation. This plan systematically updates 328 total references across commands, agents, and libraries, then deletes the compatibility shims.

### Philosophy

This implementation follows the project's clean-break approach:
- **No deprecation warnings**: Compatibility layers deleted immediately
- **No transition period**: All changes in one commit
- **Fail-fast errors**: Missing functions produce immediate bash errors that guide fixing
- **Git history only**: No archive files or backward compatibility code
- **Production ready**: Tests pass, documentation current, standards met

### Compatibility Layers to Remove

1. **artifact-operations.sh shim** (135 references)
   - Forwarding wrapper to spec-updater-agent.sh
   - Clean migration completed in spec 519

2. **error-handling.sh function aliases** (171 references)
   - `detect_specific_error_type()` → `detect_error_type()`
   - `extract_error_location()` → `extract_location()`
   - `suggest_recovery_actions()` → `generate_suggestions()`

3. **unified-logger.sh rotation wrappers** (22 references)
   - `rotate_log_if_needed()` → `rotate_log_file("$AP_LOG_FILE")`
   - `rotate_conversion_log_if_needed()` → `rotate_log_file("$CONVERSION_LOG_FILE")`

4. **generate_legacy_location_context()** (0 references)
   - Unused function from location detection migration
   - Delete without reference updates

## Success Criteria

- [ ] All 328 references updated to canonical functions
- [ ] All 4 compatibility layer files/sections deleted
- [ ] All 77/77 tests pass (100% pass rate - no failures tolerated)
- [ ] All commands execute without sourcing compatibility layers
- [ ] Documentation reflects current state only (no historical markers)
- [ ] Single atomic git commit with all changes
- [ ] No backward compatibility code remains

## Phases

### Phase 1: Remove artifact-operations.sh Shim (135 references)

**Objective**: Update all references from artifact-operations.sh to spec-updater-agent.sh and delete the shim file.

**Files to Update**:
- Commands (27 files): update_plan.md, list_summaries.md, list_plans.md, orchestrate.md, coordinate.md, etc.
- Agents (6 files): spec-updater-agent.md, implementation-researcher.md, etc.
- Libraries (5 files): shared utilities referencing artifact operations
- Tests (multiple): test_command_integration.sh, test_state_management.sh, etc.

**Tasks**:
- [ ] Update all source statements: `source .claude/lib/artifact-operations.sh` → `source .claude/lib/spec-updater-agent.sh`
- [ ] Update all function calls to use spec-updater canonical names (no changes needed if already using forwarding names)
- [ ] Verify grep finds 0 references to artifact-operations.sh after updates
- [ ] Delete `/home/benjamin/.config/.claude/lib/artifact-operations.sh`
- [ ] Run test suite: `.claude/tests/run_all_tests.sh`
- [ ] Verify all 77/77 tests pass - BLOCKING requirement (fix any failures before proceeding)
- [ ] Create checkpoint: document phase 1 completion

**Batch Update Strategy**:
```bash
# Find all files sourcing artifact-operations.sh
grep -rl "source.*artifact-operations.sh" .claude/

# Batch update source statements
find .claude/ -type f \( -name "*.md" -o -name "*.sh" \) -exec sed -i \
  's|source .*/artifact-operations\.sh|source .claude/lib/spec-updater-agent.sh|g' {} +

# Verify no references remain
grep -r "artifact-operations" .claude/ || echo "Clean"
```

**Expected Outcome**: All 135 references updated, shim deleted, tests passing.

---

### Phase 2: Remove error-handling.sh Function Aliases (171 references)

**Objective**: Update all references to use canonical function names and delete the compatibility aliases.

**Function Migrations**:
1. `detect_specific_error_type()` → `detect_error_type()` (60 references)
2. `extract_error_location()` → `extract_location()` (55 references)
3. `suggest_recovery_actions()` → `generate_suggestions()` (56 references)

**Files to Update**:
- Commands: implement.md, debug.md, orchestrate.md, coordinate.md, supervise.md
- Agents: debug-analyst.md, implementation-researcher.md
- Libraries: checkpoint-utils.sh, adaptive-planning-lib.sh
- Tests: test_error_handling.sh, test_adaptive_planning.sh

**Tasks**:
- [ ] Update all `detect_specific_error_type()` calls to `detect_error_type()`
- [ ] Update all `extract_error_location()` calls to `extract_location()`
- [ ] Update all `suggest_recovery_actions()` calls to `generate_suggestions()`
- [ ] Verify grep finds 0 references to old function names
- [ ] Remove alias definitions from `/home/benjamin/.config/.claude/lib/error-handling.sh`
- [ ] Update error-handling.sh documentation to show only canonical names
- [ ] Run test suite: `.claude/tests/run_all_tests.sh`
- [ ] Verify all 77/77 tests pass - BLOCKING requirement (fix any failures before proceeding)
- [ ] Create checkpoint: document phase 2 completion

**Batch Update Strategy**:
```bash
# Update function calls across all files
find .claude/ -type f \( -name "*.md" -o -name "*.sh" \) -exec sed -i \
  -e 's/detect_specific_error_type(/detect_error_type(/g' \
  -e 's/extract_error_location(/extract_location(/g' \
  -e 's/suggest_recovery_actions(/generate_suggestions(/g' {} +

# Verify no old names remain
grep -rE "detect_specific_error_type|extract_error_location|suggest_recovery_actions" .claude/ \
  || echo "Clean"
```

**Compatibility Code to Delete**:
```bash
# Remove these alias definitions from error-handling.sh
detect_specific_error_type() { detect_error_type "$@"; }
extract_error_location() { extract_location "$@"; }
suggest_recovery_actions() { generate_suggestions "$@"; }
```

**Expected Outcome**: All 171 references updated, aliases deleted, tests passing.

---

### Phase 3: Remove unified-logger.sh Rotation Wrappers (High Complexity)

**Objective**: Update all log rotation calls to use the canonical `rotate_log_file()` function with explicit paths.

**Summary**: This phase requires context-sensitive manual updates for 22 references across commands, agents, and libraries. Each reference must be analyzed to determine the correct log file variable (`$AP_LOG_FILE` or `$CONVERSION_LOG_FILE`) before updating. The complexity arises from variable context preservation requirements that make batch scripting unsafe.

**Status**: PENDING

For detailed implementation steps, see [Phase 3 Expansion](../artifacts/phase_3_expansion.md)

**Key Details**:
- Reference count: 22 (11 per wrapper function)
- Estimated duration: 45-60 minutes
- Complexity: 8/10 (context-sensitive manual updates)
- Includes: 6-stage implementation with context analysis checklists and comprehensive testing protocols

---

### Phase 4: Remove Unused Legacy Function (0 references)

**Objective**: Delete the unused `generate_legacy_location_context()` function from unified-location-detection.sh.

**Function to Delete**:
- `generate_legacy_location_context()` in `/home/benjamin/.config/.claude/lib/unified-location-detection.sh`
- Artifact from location detection migration (spec 519)
- 0 active references (safe to delete)

**Tasks**:
- [ ] Verify grep confirms 0 references to `generate_legacy_location_context()`
- [ ] Remove function definition from unified-location-detection.sh
- [ ] Remove any related comments or documentation for the function
- [ ] Run test suite: `.claude/tests/run_all_tests.sh`
- [ ] Verify all 77/77 tests pass - BLOCKING requirement (fix any failures before proceeding)
- [ ] Create checkpoint: document phase 4 completion

**Verification Strategy**:
```bash
# Confirm no references exist
grep -r "generate_legacy_location_context" .claude/

# Expected: Only the function definition in unified-location-detection.sh
```

**Expected Outcome**: Legacy function deleted, no impact on references (none exist), tests passing.

---

### Phase 5: Final Validation and Commit (Very High Complexity)

**Objective**: Comprehensive validation of all changes and single atomic commit.

**Summary**: This phase performs comprehensive validation across all 4 compatibility layer removals (328 total references), updates 20+ documentation files systematically, and creates a single atomic commit. The complexity arises from coordinating validation, extensive documentation updates across multiple categories, and ensuring production readiness with 100% test pass rate.

**Status**: PENDING

For detailed implementation steps, see [Phase 5 Expansion](../artifacts/phase_5_expansion.md)

**Key Details**:
- Task count: 12 checkboxes (including 6 documentation subtasks)
- Estimated duration: 90-120 minutes
- Complexity: 9/10 (comprehensive validation and documentation)
- Includes: 5-stage implementation with test suite validation, systematic documentation updates (library inline docs, READMEs, standards docs), git workflow, and quality assurance checklists

## Testing Strategy

### Test Execution Timeline

- **After Phase 1**: Run full test suite, verify all 77/77 pass
- **After Phase 2**: Run full test suite, verify all 77/77 pass
- **After Phase 3**: Run full test suite, verify all 77/77 pass
- **After Phase 4**: Run full test suite, verify all 77/77 pass
- **Phase 5**: Final comprehensive test run before commit

### Test Categories

1. **Unit Tests**: Library function correctness
2. **Integration Tests**: Command workflows end-to-end
3. **Regression Tests**: Known failure patterns
4. **Compatibility Tests**: Verify old function names fail as expected

### Success Threshold

- **Baseline**: 58/77 tests passing (current state)
- **Target**: 77/77 tests passing (100%)
- **Acceptable**: All 77 tests must pass
- **Blocking Condition**: Any test failure blocks phase completion
- **Action on Failure**: Fix failing tests before proceeding to next phase

### Test Fixing Strategy

If tests fail after any phase:

1. **Identify failing tests**: Review test output for specific failures
2. **Analyze root cause**: Determine if failure is due to:
   - Missed reference update
   - Incorrect function signature
   - Test infrastructure issue
3. **Fix the issue**: Update code or tests as needed
4. **Re-run tests**: Verify fix resolves failure
5. **Proceed only when 77/77 pass**: Do not continue to next phase with failures

**Philosophy**: Clean-break means fixing all issues immediately, not deferring failures.

### Test Command

```bash
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh
```

## Rollback Strategy

### Clean-Break Approach

No forward compatibility or deprecation code:
- **Rollback mechanism**: `git revert <commit-hash>` only
- **No archive files**: Use git history for previous versions
- **No compatibility flags**: Changes are permanent or reverted

### Rollback Procedure

If issues discovered after commit:

1. **Identify commit**: `git log --oneline | grep "Remove all compatibility layers"`
2. **Revert commit**: `git revert <commit-hash>`
3. **Verify tests**: Run test suite to confirm restoration
4. **Investigate**: Analyze failure cause before retry

### Expected Errors (Fail-Fast Behavior)

After removal, old function calls produce immediate bash errors:

```bash
# Example fail-fast error
bash: detect_specific_error_type: command not found

# This is DESIRED behavior - guides fixing remaining references
```

## Risk Assessment

### Medium Risk Factors

1. **Reference Count**: 328 total references across codebase
2. **Batch Updates**: sed/awk scripts may miss edge cases
3. **Test Coverage**: Some compatibility paths may not be tested

### Mitigation Strategies

1. **Phase-by-phase testing**: Catch issues early
2. **Comprehensive grep**: Verify 0 references after each phase
3. **Manual review**: Check git diff before final commit
4. **Checkpoint recovery**: Document state after each phase

### Low Risk Justification

- All compatibility layers are simple forwarding functions
- Reference patterns are consistent and grep-able
- Test suite provides rapid feedback
- Single commit enables easy rollback
- Fail-fast errors guide fixing any missed references

## Dependencies

### Required Files

- `/home/benjamin/.config/.claude/lib/spec-updater-agent.sh` (canonical artifact operations)
- `/home/benjamin/.config/.claude/lib/error-handling.sh` (canonical error functions)
- `/home/benjamin/.config/.claude/lib/unified-logger.sh` (canonical logging)
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` (location utilities)

### Test Infrastructure

- `/home/benjamin/.config/.claude/tests/run_all_tests.sh`
- All test files in `/home/benjamin/.config/.claude/tests/`

## Documentation Updates

### Documentation Strategy

Systematic documentation updates are required to ensure all references to compatibility layers are removed and replaced with canonical function documentation. This includes both inline documentation in library files and comprehensive updates to `.claude/docs/` standards documentation.

### Files to Update

#### 1. Library Documentation
- `/home/benjamin/.config/.claude/lib/error-handling.sh` - Remove alias function documentation, update to show only canonical names
- `/home/benjamin/.config/.claude/lib/unified-logger.sh` - Remove wrapper function documentation, update to show only canonical function
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` - Remove legacy function documentation
- `/home/benjamin/.config/.claude/lib/spec-updater-agent.sh` - Verify documentation reflects canonical artifact operations

#### 2. Library Directory README
- `/home/benjamin/.config/.claude/lib/README.md` - Update library inventory to reflect:
  - Remove artifact-operations.sh from active libraries list
  - Update error-handling.sh entry (remove mention of aliases)
  - Update unified-logger.sh entry (remove mention of wrappers)
  - Update function listings to show only canonical names

#### 3. Standards Documentation (`.claude/docs/`)
- `/home/benjamin/.config/.claude/docs/reference/library-api.md` - Remove all compatibility function documentation:
  - Remove `detect_specific_error_type()`, `extract_error_location()`, `suggest_recovery_actions()`
  - Remove `rotate_log_if_needed()`, `rotate_conversion_log_if_needed()`
  - Remove `generate_legacy_location_context()`
  - Update all examples to use canonical functions
- `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md` - Update all code examples:
  - Replace old function names with canonical equivalents
  - Remove any references to compatibility patterns
- `/home/benjamin/.config/.claude/docs/guides/agent-development-guide.md` - Update agent examples to use canonical functions
- `/home/benjamin/.config/.claude/docs/concepts/patterns/*.md` - Review for compatibility layer references

#### 4. Command and Agent Files
- All command files in `.claude/commands/*.md` - Update inline examples and documentation blocks
- All agent files in `.claude/agents/*.md` - Update behavioral guidelines and example code
- Ensure all source statements and function calls use canonical forms

#### 5. Directory READMEs
Systematically update all README.md files that reference compatibility layers:
- `/home/benjamin/.config/.claude/commands/README.md`
- `/home/benjamin/.config/.claude/agents/README.md`
- `/home/benjamin/.config/.claude/docs/README.md`
- `/home/benjamin/.config/.claude/docs/guides/README.md`
- `/home/benjamin/.config/.claude/docs/reference/README.md`
- `/home/benjamin/.config/.claude/docs/concepts/README.md`

### Documentation Principle

Per Development Philosophy (Writing Standards):
- Remove all historical markers like "(New)" or "previously"
- Document current state only
- Use git history for past states
- No forward references to removed compatibility code
- No "migration guides" or "upgrade paths" - clean-break means immediate adoption

### Documentation Update Process

1. **Search for all references**:
   ```bash
   # Find all documentation mentioning old function names
   grep -r "detect_specific_error_type\|extract_error_location\|suggest_recovery_actions" .claude/docs/
   grep -r "rotate_log_if_needed\|rotate_conversion_log_if_needed" .claude/docs/
   grep -r "artifact-operations\.sh" .claude/docs/
   grep -r "generate_legacy_location_context" .claude/docs/
   ```

2. **Update each file**:
   - Replace old function names with canonical equivalents
   - Remove any compatibility layer explanations
   - Update code examples to current patterns
   - Remove historical context (use git log instead)

3. **Verify completeness**:
   ```bash
   # Verify no old references remain in documentation
   grep -r "artifact-operations" .claude/ --include="*.md" | grep -v "\.git" | grep -v "archive"
   ```

## Timeline Estimate

### Phase Duration Estimates

- **Phase 1**: 45 minutes (135 references, batch updates possible)
- **Phase 2**: 60 minutes (171 references, 3 function migrations)
- **Phase 3**: 30 minutes (22 references, manual review needed)
- **Phase 4**: 15 minutes (0 references, simple deletion)
- **Phase 5**: 90 minutes (validation, documentation updates, commit)

**Total Estimated Duration**: 4 hours

**Buffer for Issues**: +1 hour

**Total with Buffer**: 5 hours

## Success Metrics

### Completion Criteria

- [ ] 0 references to artifact-operations.sh
- [ ] 0 references to detect_specific_error_type()
- [ ] 0 references to extract_error_location()
- [ ] 0 references to suggest_recovery_actions()
- [ ] 0 references to rotate_log_if_needed()
- [ ] 0 references to rotate_conversion_log_if_needed()
- [ ] 0 references to generate_legacy_location_context()
- [ ] 4 compatibility files/sections deleted
- [ ] 77/77 tests passing (100% pass rate)
- [ ] Single atomic commit
- [ ] Documentation reflects current state only

### Quality Metrics

- **Code Cleanliness**: No backward compatibility code remains
- **Test Stability**: Pass rate maintained or improved
- **Documentation**: Current state only, no historical markers
- **Fail-Fast Behavior**: Missing functions produce immediate errors
- **Rollback Ready**: Single commit enables clean revert

## Notes

This plan follows the project's clean-break philosophy:
- No deprecation warnings or transition periods
- Fail-fast errors are desired (guide fixing)
- Git history for rollback, no archive files
- Production ready means tests pass, not zero risk
- Single atomic commit with all changes

The systematic phase-by-phase approach with testing after each phase ensures:
- Early detection of issues
- Clear checkpoints for recovery
- Comprehensive validation before final commit
- Maintainable test baseline throughout process

## Revision History

### 2025-10-29 - Revision 1
**Changes**: Raised test requirements from 75% baseline to 100% pass rate
**Reason**: User requirement for all tests to pass before completion
**Modified Phases**: All phases (1-5) - changed test verification criteria from ≥58/77 to 77/77
**Impact**: Adds test-fixing work to each phase if failures occur
**New Section**: Added "Test Fixing Strategy" with 5-step process for handling failures
**Philosophy Alignment**: Clean-break means fixing all issues immediately, not deferring failures

### 2025-10-29 - Revision 2
**Changes**: Added comprehensive documentation update requirements
**Reason**: Systematic updates needed for all README.md and .claude/docs/ files
**Modified Sections**:
- Expanded "Documentation Updates" section with 5 categories of files
- Added documentation tasks to Phase 5 (6 new checkboxes)
- Increased Phase 5 duration from 30 min to 90 min
- Added documentation verification grep commands
**Files to Update**:
- Library inline docs (3 files)
- .claude/lib/README.md
- .claude/docs/reference/library-api.md
- .claude/docs/guides/*.md (2+ files)
- All directory README.md files (6+ files)
**Philosophy Alignment**: Clean-break means documentation reflects current state only, no historical markers
