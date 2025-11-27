# Spec Directory Numbering Collision Fix - Implementation Plan

## Metadata
- **Date**: 2025-11-24
- **Feature**: Fix spec directory numbering collision bug
- **Scope**: Prevent duplicate topic numbers through path canonicalization and enhanced verification
- **Estimated Phases**: 5
- **Estimated Hours**: 12
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 68.0
- **Research Reports**:
  - [Root Cause Analysis](../reports/001-numbering-collision-root-cause.md)
  - [Fix Implementation Plan](../reports/002-fix-implementation-plan.md)

## Overview

Fix the critical bug that allowed two directories with number 923 to be created 25 minutes apart (`923_error_analysis_research` and `923_subagent_converter_skill_strategy`). The root cause is specs_root path inconsistency causing different processes to use different lock files, breaking the atomicity guarantee of `allocate_and_create_topic()`.

**Core Problem**: Different commands may calculate different values for specs_root (relative vs absolute paths, symlinks), causing them to use DIFFERENT lock files and breaking the exclusive locking mechanism.

**Solution Strategy**: Canonicalize specs_root at function entry, add collision detection logging, and verify no duplicates after creation.

## Research Summary

Research identified the collision mechanism:

**From Root Cause Analysis**:
- Two 923 directories created 25 minutes apart (17:28 and 17:53)
- Atomic allocation function uses flock with specs_root-relative lock file
- If specs_root paths differ (symlink vs real, relative vs absolute), lock files differ
- Different lock files = no mutual exclusion = race condition possible

**From Fix Implementation Plan**:
- Five-phase fix: canonicalization, collision logging, lock validation, error integration, testing
- Clean-break approach (no backward compatibility needed)
- Comprehensive test coverage for concurrent allocation scenarios

**Key Insight**: The collision detection loop (line 281) only triggers AFTER calculating the initial number. If two processes see different max_num values due to path inconsistency, both can allocate the same number.

## Success Criteria

- [ ] Zero duplicate topic numbers under any path variation (symlinks, relative, trailing slashes)
- [ ] All specs_root values canonicalized to absolute paths before lock acquisition
- [ ] Collision detection events logged for post-mortem analysis
- [ ] Post-creation verification detects and reports any duplicates that slip through
- [ ] Lock file path validation warns about inconsistencies
- [ ] All allocation events logged to errors.jsonl with full context
- [ ] Test suite proves 0% collision rate under 1000 concurrent allocations
- [ ] No performance regression (allocation still <50ms per call)

## Technical Design

### Architecture Changes

**Component**: `.claude/lib/core/unified-location-detection.sh`

**New Function**: `canonicalize_path()`
- Purpose: Resolve any path to canonical absolute form
- Handles non-existent paths by canonicalizing parent
- Uses `readlink -f` for symlink resolution
- Returns error if path cannot be resolved

**Modified Function**: `allocate_and_create_topic()`
- Canonicalize specs_root on entry (line 248)
- Validate specs_root is absolute (starts with `/`)
- Check for multiple lock files (warns if >1 found)
- Log max_num calculation results
- Log collision detection events
- Post-creation duplicate verification
- Integrate with error-handling.sh library

### Error Logging Integration

Source `error-handling.sh` with conditional behavior:
- If `log_command_error` function available: enable logging
- If not available: disable logging (standalone library use)
- Log allocation failures as "state_error" type
- Log successful allocations at DEBUG level
- Include diagnostic context: specs_root, topic_number, collision_count

### Lock File Strategy

Current: `${specs_root}/.topic_number.lock`
- Maintained (no breaking changes)
- Add validation: scan for multiple lock files
- Warn if count >1 (indicates path inconsistency)
- Include lock file path in all error messages

### Collision Detection Enhancement

Add observability without changing behavior:
- Log when max_num calculated
- Log when collision loop executes
- Count collision iterations
- Log final allocated number
- All logged at DEBUG level (not error reports)

## Implementation Phases

### Phase 1: Path Canonicalization Infrastructure [COMPLETE]
dependencies: []

**Objective**: Add path canonicalization capability to unified-location-detection.sh

**Complexity**: Low

**Tasks**:
- [x] Implement `canonicalize_path()` helper function (file: .claude/lib/core/unified-location-detection.sh:~240)
  - Accept path parameter
  - Handle non-existent paths by canonicalizing parent + basename
  - Use `readlink -f` for symlink resolution
  - Return canonical absolute path on stdout
  - Return exit code 1 if path unresolvable
- [x] Add unit tests for canonicalize_path() (file: .claude/tests/unit/test_path_canonicalization.sh)
  - Test with absolute paths (should pass through)
  - Test with relative paths (should resolve to absolute)
  - Test with symlinks (should resolve to real path)
  - Test with trailing slashes (should normalize)
  - Test with non-existent paths (should canonicalize parent)
  - Test with completely invalid paths (should return error)
- [x] Document canonicalize_path() API in directory-protocols.md

**Testing**:
```bash
# Run unit tests
bash .claude/tests/unit/test_path_canonicalization.sh

# Manual verification
source .claude/lib/core/unified-location-detection.sh
canonicalize_path "/tmp/test/../specs"  # Should return /tmp/specs
canonicalize_path "relative/path"       # Should return absolute path
```

**Expected Duration**: 2 hours

### Phase 2: Atomic Allocation Function Enhancement [COMPLETE]
dependencies: [1]

**Objective**: Integrate path canonicalization and validation into allocate_and_create_topic()

**Complexity**: Medium

**Tasks**:
- [x] Update allocate_and_create_topic() to canonicalize specs_root on entry (file: .claude/lib/core/unified-location-detection.sh:247)
  - Call canonicalize_path() before any other operations
  - Store result back to specs_root variable
  - Return error if canonicalization fails
- [x] Add absolute path validation (file: .claude/lib/core/unified-location-detection.sh:~255)
  - Check specs_root starts with `/`
  - Return error with clear message if relative path detected
- [x] Add lock file validation (file: .claude/lib/core/unified-location-detection.sh:~260)
  - Use `find "$specs_root" -name ".topic_number.lock"` to count lock files
  - If count >1, emit warning to stderr
  - Include lock file path and count in warning message
- [x] Update function documentation with new validation behavior

**Testing**:
```bash
# Test with various path forms
RESULT=$(allocate_and_create_topic "/absolute/path" "test")
RESULT=$(allocate_and_create_topic "./relative/path" "test")  # Should canonicalize
RESULT=$(allocate_and_create_topic "/path/with/symlink" "test")  # Should resolve
```

**Expected Duration**: 2 hours

### Phase 3: Collision Detection Logging [COMPLETE]
dependencies: [2]

**Objective**: Add comprehensive logging to collision detection for observability

**Complexity**: Medium

**Tasks**:
- [x] Add DEBUG logging for max_num calculation (file: .claude/lib/core/unified-location-detection.sh:~273)
  - Log max_num value found
  - Log calculated next number (topic_number)
  - Use stderr for debug output
- [x] Instrument collision detection loop (file: .claude/lib/core/unified-location-detection.sh:281-287)
  - Add collision_count variable (initialize to 0)
  - Increment on each collision detected
  - Log each collision event at DEBUG level
  - Include existing directories causing collision
- [x] Add post-loop collision summary logging
  - Log total collisions resolved
  - Log final allocated number
  - Only log if collision_count >0
- [x] Implement post-creation duplicate verification (file: .claude/lib/core/unified-location-detection.sh:~298)
  - Count directories matching `${topic_number}_*` pattern
  - If count >1, emit CRITICAL error log
  - List all duplicate directories for manual investigation
  - Continue execution (don't fail - directory was created successfully)

**Testing**:
```bash
# Create collision scenario
TEMP_SPECS=$(mktemp -d)
mkdir -p "$TEMP_SPECS/000_existing"

# Should detect collision and skip to 001
RESULT=$(allocate_and_create_topic "$TEMP_SPECS" "test" 2>&1)
echo "$RESULT" | grep "DEBUG: Topic number collision detected"  # Should match
```

**Expected Duration**: 3 hours

### Phase 4: Error Logging Integration [COMPLETE]
dependencies: [3]

**Objective**: Integrate centralized error logging for allocation failures

**Complexity**: Low

**Tasks**:
- [x] Add conditional error-handling.sh sourcing (file: .claude/lib/core/unified-location-detection.sh:~265)
  - Check if log_command_error function exists
  - Set ENABLE_ERROR_LOGGING=1 if available, 0 otherwise
  - No failure if library unavailable (standalone library support)
- [x] Update all error paths to use centralized logging
  - Canonicalization failures: log as "validation_error"
  - Lock acquisition failures: log as "state_error"
  - mkdir failures: log as "file_error"
  - Duplicate detection: log as "state_error" with diagnostic context
- [x] Add success logging at DEBUG level
  - Log allocated topic number and path
  - Include canonical specs_root path
  - Include lock file path
  - Only when ENABLE_ERROR_LOGGING=1
- [x] Update error messages to include diagnostic context
  - specs_root (canonical)
  - topic_name
  - max_num found
  - topic_number allocated
  - collision_count
  - lock_file path

**Testing**:
```bash
# Initialize error logging
source .claude/lib/core/error-handling.sh
ensure_error_log_exists

# Trigger allocation
RESULT=$(allocate_and_create_topic "/tmp/specs" "test")

# Verify logged
grep "allocate_and_create_topic" .claude/data/logs/errors.jsonl | tail -1
```

**Expected Duration**: 2 hours

### Phase 5: Comprehensive Testing [COMPLETE]
dependencies: [4]

**Objective**: Prove zero collision rate under all conditions

**Complexity**: High

**Tasks**:
- [x] Create concurrent allocation stress test (file: .claude/tests/integration/test_concurrent_topic_allocation.sh)
  - Launch 1000 parallel allocations with different topic names
  - Verify exactly 1000 directories created
  - Verify zero duplicate numbers
  - Verify sequential numbering (gaps allowed, duplicates not)
  - Run 10 times to prove consistency
- [x] Create path canonicalization integration test (file: .claude/tests/integration/test_path_canonicalization_allocation.sh)
  - Create symlink to specs directory
  - Allocate via absolute path, symlink path, relative path
  - Verify all use same canonical specs_root
  - Verify sequential numbering across all paths
  - Verify single lock file exists
- [x] Create collision detection test (file: .claude/tests/unit/test_collision_detection.sh)
  - Pre-create directories with gaps (000, 001, 003)
  - Allocate new topic (should use 002, filling gap)
  - Pre-create next number manually
  - Allocate again (should detect collision and skip)
- [x] Create error logging integration test (file: .claude/tests/integration/test_allocation_error_logging.sh)
  - Trigger allocation failure (invalid specs_root)
  - Verify logged to errors.jsonl
  - Verify error contains all diagnostic context
  - Verify error type is correct
- [x] Create lock file validation test (file: .claude/tests/unit/test_lock_file_validation.sh)
  - Create multiple .topic_number.lock files
  - Verify warning emitted
  - Verify allocation still succeeds
- [x] Update COVERAGE_REPORT.md with new test coverage
- [x] Run full test suite and verify all pass

**Testing**:
```bash
# Run all new tests
bash .claude/tests/integration/test_concurrent_topic_allocation.sh
bash .claude/tests/integration/test_path_canonicalization_allocation.sh
bash .claude/tests/unit/test_collision_detection.sh
bash .claude/tests/integration/test_allocation_error_logging.sh
bash .claude/tests/unit/test_lock_file_validation.sh

# Run full suite
bash .claude/tests/run_all_tests.sh
```

**Expected Duration**: 3 hours

## Testing Strategy

### Unit Tests
- Path canonicalization (all edge cases)
- Collision detection logic
- Lock file validation
- Error message formatting

### Integration Tests
- Concurrent allocation (1000 parallel processes)
- Path canonicalization across symlinks/relative/absolute
- Error logging integration
- Lock file uniqueness

### Stress Tests
- 1000 concurrent allocations, 10 iterations (prove 0% collision rate)
- Symlink + relative + absolute paths mixed concurrently
- All 1000 numbers exhausted scenario

### Regression Tests
- Verify no performance degradation (<50ms per allocation)
- Verify backward compatibility (function signature unchanged)
- Verify standalone library use still works (no error-handling.sh required)

### Success Criteria
- 100% test pass rate
- 0% collision rate under concurrent load
- All error conditions logged with full context
- No false positives in lock file validation

## Documentation Requirements

### Update Existing Documentation

**File**: `.claude/docs/concepts/directory-protocols.md`
- Add "Path Canonicalization" subsection to "Atomic Topic Allocation" (line ~150)
- Document canonicalize_path() API
- Add "Collision Detection Logging" subsection (line ~175)
- Update "Concurrency Guarantee" to mention observability enhancements

**File**: `.claude/lib/core/unified-location-detection.sh`
- Update allocate_and_create_topic() docstring with new validations
- Add canonicalize_path() docstring with full API documentation
- Document ENABLE_ERROR_LOGGING behavior

**File**: `.claude/docs/concepts/patterns/error-handling.md`
- Add example of allocation error logging (under "State Errors" section)
- Document state_error usage for duplicate detection

### Create New Documentation

**File**: `.claude/tests/README.md`
- Add section for concurrent allocation tests
- Document stress testing approach
- Reference new integration tests

## Dependencies

### External Dependencies
- `flock` command (already required by atomic allocation)
- `readlink` command (standard on Linux/macOS)
- `find` command (standard on all systems)

### Internal Dependencies
- `.claude/lib/core/error-handling.sh` (optional - only for logging)
- `.claude/lib/core/unified-location-detection.sh` (modified)

### Calling Code Impact
- **Zero breaking changes** - function signature unchanged
- **Zero migration needed** - all changes internal to function
- **Zero caller updates** - all existing callers work unchanged

## Risk Assessment

### Technical Risks

**Risk 1**: readlink not available on some systems
- **Likelihood**: Low (standard on Linux/macOS)
- **Impact**: High (canonicalization breaks)
- **Mitigation**: Add fallback using realpath or cd + pwd

**Risk 2**: Performance regression from path canonicalization
- **Likelihood**: Low (readlink is fast)
- **Impact**: Medium (slower allocation)
- **Mitigation**: Benchmark before/after, optimize if >10% regression

**Risk 3**: Error logging integration breaks standalone library use
- **Likelihood**: Low (conditional sourcing designed for this)
- **Impact**: Medium (library unusable standalone)
- **Mitigation**: Comprehensive testing of standalone scenarios

### Operational Risks

**Risk 1**: Duplicate detection false positives
- **Likelihood**: Low (logic thoroughly tested)
- **Impact**: Medium (alarm fatigue)
- **Mitigation**: Test with known-good scenarios, tune logging levels

**Risk 2**: Lock file validation warnings spam logs
- **Likelihood**: Medium (if misconfigured systems exist)
- **Impact**: Low (warnings not errors)
- **Mitigation**: Document expected single lock file, provide troubleshooting guide

## Rollback Plan

If critical issues discovered post-deployment:

1. **Immediate**: Revert allocate_and_create_topic() to original implementation
2. **Within 1 hour**: Deploy revert, verify allocation works
3. **Within 24 hours**: Analyze root cause, fix, re-test
4. **Within 1 week**: Re-deploy fixed version

**Rollback Safety**: Clean-break approach means reverting single function restores original behavior completely. No partial state to clean up.

## Migration Notes

### Backward Compatibility

**Function Signature**: Unchanged - allocate_and_create_topic(specs_root, topic_name)
**Return Format**: Unchanged - "${topic_number}|${topic_path}"
**Caller Impact**: Zero - all callers work unchanged
**Lock File**: Unchanged - same location and format
**Numbering**: Unchanged - same sequential algorithm

### User-Visible Changes

**Only change**: Improved error messages include more diagnostic context
**No user action required**: Fix is transparent to all users
**No configuration needed**: All behavior automatic

### Testing Migration

**New tests added**: 5 new test files
**Existing tests**: All continue to pass (verified in Phase 5)
**Coverage increase**: +15% on unified-location-detection.sh

## References

- **Root Cause Report**: /home/benjamin/.config/.claude/specs/946_errors_spec_numbering_fix/reports/001-numbering-collision-root-cause.md
- **Fix Implementation Plan**: /home/benjamin/.config/.claude/specs/946_errors_spec_numbering_fix/reports/002-fix-implementation-plan.md
- **Atomic Allocation Function**: /home/benjamin/.config/.claude/lib/core/unified-location-detection.sh:247-305
- **Directory Protocols**: /home/benjamin/.config/.claude/docs/concepts/directory-protocols.md:120-196
- **Code Standards**: /home/benjamin/.config/.claude/docs/reference/standards/code-standards.md
- **Error Logging Pattern**: /home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md
- **Clean-Break Standard**: /home/benjamin/.config/.claude/docs/reference/standards/clean-break-development.md
- **Evidence**: 923_error_analysis_research (2025-11-23 17:28:06) and 923_subagent_converter_skill_strategy (2025-11-23 17:53:13)
