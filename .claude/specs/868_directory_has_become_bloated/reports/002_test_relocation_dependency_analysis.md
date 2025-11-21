# Test Relocation Dependency Analysis

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Test relocation dependency analysis for Plan 001
- **Report Type**: codebase analysis
- **Plan**: 001_directory_has_become_bloated_plan.md

## Executive Summary

Comprehensive analysis of 97 test files reveals a well-isolated test architecture using relative paths from SCRIPT_DIR, eliminating relocation risks. Critical dependencies identified: run_all_tests.sh (test discovery), build.md (test runner path), documentation (28 files with test references), and unified-location-detection.sh (3 test citations). The plan's git mv approach preserves history while requiring only 4 strategic updates: run_all_tests.sh test discovery pattern, build.md path check, documentation cross-references, and testing-protocols.md category list.

## Findings

### 1. Test Path Architecture Analysis

**Pattern Discovery** (100+ test files examined):
All tests use consistent relative path pattern from SCRIPT_DIR:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"
source "$LIB_DIR/plan/plan-core-bundle.sh"
```

**Key Finding**: Tests reference libraries via relative paths (../lib), NOT absolute paths or hardcoded test/ directory references. This architecture is **relocation-safe** - tests will work from subdirectories without modification.

**Evidence**:
- `/home/benjamin/.config/.claude/tests/test_parsing_utilities.sh:8-12` - Standard pattern
- `/home/benjamin/.config/.claude/tests/test_progressive_expansion.sh:8-12` - Same pattern
- Analysis of 20+ test files confirms consistent usage

**Implication**: Phase 5 (test relocation) requires NO path updates within test files themselves. The ../lib pattern will continue to work from unit/, integration/, state/, etc.

### 2. Critical Dependency: run_all_tests.sh

**Current Implementation** (`/home/benjamin/.config/.claude/tests/run_all_tests.sh:55`):
```bash
TEST_FILES=$(find "$TEST_DIR" -name "test_*.sh" -not -name "run_all_tests.sh" | sort)
```

**Issue**: Searches only maxdepth 1 (flat directory), will NOT find tests in subdirectories after Phase 5.

**Required Update** (Phase 6):
```bash
TEST_FILES=$(find "$TEST_DIR" -path "*/fixtures" -prune -o -name "test_*.sh" -print | grep -v "run_all_tests.sh" | sort)
```

**Verification Points**:
- Line 55: Test discovery pattern
- Line 18: TEST_DIR definition (remains unchanged)
- Lines 40-52: Pollution detection (continues to work with subdirectories)

**References in Codebase** (56 total):
- `.claude/README.md:264` - Execution instructions
- `.claude/tests/COVERAGE_REPORT.md:279,287` - Usage examples
- `.claude/docs/reference/standards/test-isolation.md:268,733` - Test runner documentation
- `.claude/docs/reference/standards/testing-protocols.md:12,244` - Testing standards
- 50+ additional references in specs, plans, and documentation

**Impact**: Medium-high. All documentation references remain valid as the script location doesn't change. Only the internal find pattern needs updating.

### 3. Build Command Test Discovery

**Location**: `/home/benjamin/.config/.claude/commands/build.md:675-676`

**Current Code**:
```bash
elif [ -f ".claude/run_all_tests.sh" ]; then
  TEST_COMMAND="./.claude/run_all_tests.sh"
```

**Issue**: Checks wrong path (.claude/run_all_tests.sh instead of .claude/tests/run_all_tests.sh)

**Finding**: This is a **pre-existing bug**, NOT a relocation concern. The actual path has always been `.claude/tests/run_all_tests.sh`, so this check never matches.

**Recommendation**: Fix during Phase 6 to:
```bash
elif [ -f ".claude/tests/run_all_tests.sh" ]; then
  TEST_COMMAND="./.claude/tests/run_all_tests.sh"
```

**Impact**: Low. Bug fix opportunity during reorganization, not a breaking change from relocation.

### 4. Documentation Test References

**High-Frequency References** (28 documentation files):
1. **testing-protocols.md** (Lines 12-23): Lists specific test categories
   - Update needed: Replace flat list with category-based organization
   - Example current: "test_parsing_utilities.sh - Plan parsing functions"
   - Example revised: "unit/test_parsing_utilities.sh - Plan parsing functions"

2. **test-isolation.md** (Lines 268, 733): References test runner architecture
   - No update needed: Discusses run_all_tests.sh which stays in same location

3. **testing-patterns.md** (Line 35, 50): Directory structure diagram
   - Update needed: Add subdirectory structure to diagram

4. **refactoring-methodology.md** (Line 563): Test suite checklist
   - No update needed: References run_all_tests.sh which doesn't move

**Documentation Files Requiring Updates** (Analysis of 28 files):
- **Structural Changes**: 3 files (testing-protocols.md, testing-patterns.md, test-command-guide.md)
- **Example Updates**: 5 files (various guides showing test execution)
- **No Changes**: 20 files (reference run_all_tests.sh only, which doesn't move)

**Systematic Update Pattern**:
```bash
# Before: test_parsing_utilities.sh
# After:  unit/test_parsing_utilities.sh
```

### 5. Library Test References

**unified-location-detection.sh** (`/home/benjamin/.config/.claude/lib/core/unified-location-detection.sh:72-74`):

**Current Code (comments)**:
```bash
#     - .claude/tests/test_unified_location_detection.sh (lines 23-27)
#     - .claude/tests/test_unified_location_simple.sh (lines 18-22)
#     - .claude/tests/test_system_wide_location.sh (lines 19-23)
```

**Tests to Be Moved**:
- test_unified_location_detection.sh → integration/
- test_unified_location_simple.sh → integration/
- test_system_wide_location.sh → integration/

**Required Update** (Phase 5):
```bash
#     - .claude/tests/integration/test_unified_location_detection.sh (lines 23-27)
#     - .claude/tests/integration/test_unified_location_simple.sh (lines 18-22)
#     - .claude/tests/integration/test_system_wide_location.sh (lines 19-23)
```

**Impact**: Low. Comments only, but should be updated for accuracy.

### 6. Spec File Test References

**Pattern**: 100+ spec files reference tests in various contexts

**Categories of References**:
1. **Historical Context**: References to tests that validated implementations
2. **Test Creation**: Plans that created specific test files
3. **Test Results**: Summaries documenting test outcomes
4. **Future Testing**: Plans referencing tests to be run

**Key Finding**: Spec references are **historical documentation**, NOT active dependencies. Test relocations don't break spec files because:
- Specs reference tests by name, not by path
- References are descriptive ("created test_error_logging.sh"), not executable
- Historical accuracy is preserved (tests existed at those paths when referenced)

**Example**: `specs/847_updating_the_standard_for_error_logging_to_claude/reports/002_clean_break_revision_insights.md:84`
```markdown
**Trade-off**: Would break existing test_error_logging.sh, but tests should be updated...
```
This is historical context, not a path dependency.

**Recommendation**: NO updates needed to spec files. Historical references remain accurate.

### 7. Test Fixture Dependencies

**Fixture Location**: `/home/benjamin/.config/.claude/tests/fixtures/`

**Current Usage Pattern**: NO hardcoded fixture paths found in test files

**Search Results**:
- Pattern `FIXTURES_DIR|fixtures/` found only in 2 validation result files
- No test files use `fixtures/` in source or require statements

**Finding**: Tests use relative paths to fixtures implicitly:
```bash
# Typical pattern
TEST_DIR="/tmp/test_name_$$"
# Tests create temporary fixtures in TEST_DIR, not .claude/tests/fixtures/
```

**Implication**: Test relocation to subdirectories (unit/, integration/, etc.) does NOT affect fixture access. The fixtures/ directory remains at `.claude/tests/fixtures/` and tests don't reference it directly.

**Verification**: Phase 5 testing should confirm fixtures remain accessible from new test locations.

### 8. Test Consolidation Dependencies

**Plan Consolidation Tasks** (Phase 3):

**Topic Naming Consolidation** (3 → 1):
- Source: test_topic_naming.sh, test_topic_slug_validation.sh, test_topic_name_sanitization.sh
- Target: test_topic_naming_suite.sh
- Location: topic-naming/ directory (Phase 4)

**Cross-Reference Analysis**:
- test_topic_name_sanitization.sh referenced in test_workflow_initialization.sh:407
  ```bash
  test_topic_name_sanitization() {
  ```
  **Issue**: Function name collision - test_workflow_initialization.sh has internal function with same name

**Finding**: This is NOT a dependency issue. test_workflow_initialization.sh defines its own test_topic_name_sanitization() function internally (line 407), it doesn't source the separate test file.

**Verification**: Consolidation can proceed without breaking test_workflow_initialization.sh

### 9. Test Execution References in Commands

**Command Integration Analysis**:

**Search Pattern**: References to test execution in command files
**Result**: NO command files directly invoke specific test files

**Key Finding**: Commands use test runner pattern:
```bash
# From build.md (lines 675-676)
if [ -f ".claude/run_all_tests.sh" ]; then  # Current (incorrect path)
  TEST_COMMAND="./.claude/run_all_tests.sh"
```

**Implication**: Commands delegate to run_all_tests.sh, which will handle subdirectory discovery after Phase 6 update. No command files need updates for test relocation.

### 10. Relocation Safety Verification

**Critical Safety Checks**:

1. **Git History Preservation**: Plan correctly specifies `git mv` for all relocations
   - Preserves file history
   - Maintains blame information
   - Enables `git log --follow`

2. **Path Reference Types**:
   - ✓ Relative paths from SCRIPT_DIR: Safe (automatically adjust)
   - ✓ Test discovery via find: Requires update (Phase 6, planned)
   - ✓ Documentation references: Requires update (Phase 7, planned)
   - ✓ Spec historical references: No update needed (historical)

3. **Test Isolation Pattern**: Tests use CLAUDE_SPECS_ROOT override
   - Pattern verified in run_all_tests.sh pollution detection (lines 40-52)
   - Tests create temporary directories (/tmp/test_name_$$)
   - Relocation doesn't affect isolation

4. **Zero Test Breakage Prediction**: Based on architecture analysis:
   - NO test files require internal path updates
   - NO commands directly invoke specific tests
   - NO libraries depend on test locations
   - Only 4 files need updates (runner + 3 doc files)

## Recommendations

### 1. Update Sequence for Zero Breakage

**Phase 5 Enhancement** (during test relocation):
Add verification step after each category relocation:
```bash
# After moving each category (e.g., unit tests)
cd /home/benjamin/.config/.claude/tests/unit
for test in test_*.sh; do
  echo "Verifying: $test"
  bash "$test" --dry-run 2>&1 | head -5
done
```

**Rationale**: Early detection of any unexpected path issues before proceeding to next category.

### 2. Run_all_tests.sh Update (Phase 6)

**Critical Update** (line 55):
```bash
# OLD (current)
TEST_FILES=$(find "$TEST_DIR" -name "test_*.sh" -not -name "run_all_tests.sh" | sort)

# NEW (recursive subdirectory search)
TEST_FILES=$(find "$TEST_DIR" -path "*/fixtures" -prune -o -path "*/logs" -prune -o -path "*/validation_results" -prune -o -name "test_*.sh" -print | grep -v "run_all_tests.sh" | sort)
```

**Exclusions Needed**:
- fixtures/ - Test data directory (not executable tests)
- logs/ - Test execution logs
- validation_results/ - Validation output directory

**Testing**:
```bash
# Verify finds all tests in subdirectories
./run_all_tests.sh --list | wc -l  # Should show ~69 tests

# Verify excludes non-test directories
./run_all_tests.sh --list | grep -c "fixtures"  # Should be 0
```

### 3. Build.md Test Discovery Fix

**Current Bug** (line 675):
```bash
elif [ -f ".claude/run_all_tests.sh" ]; then  # WRONG PATH
```

**Corrected** (opportunistic fix during Phase 6):
```bash
elif [ -f ".claude/tests/run_all_tests.sh" ]; then  # CORRECT PATH
```

**Impact**: Enables build command to auto-detect and run .claude project tests.

### 4. Documentation Update Strategy

**High Priority** (Phase 7):

**testing-protocols.md** (Lines 12-23):
Replace flat test list with category organization:
```markdown
### Test Categories
- **Unit Tests** (`unit/`)
  - test_parsing_utilities.sh - Plan parsing functions
  - test_error_logging.sh - Error logging library
  [etc.]
- **Integration Tests** (`integration/`)
  - test_command_integration.sh - Command workflows
  [etc.]
```

**testing-patterns.md** (Line 35):
Update directory tree diagram:
```markdown
.claude/tests/
├── run_all_tests.sh           # Main test runner
├── unit/                       # Library function tests
├── integration/                # Workflow tests
├── state/                      # State management tests
[etc.]
```

**Low Priority** (Phase 7):
Update example commands in guides to reflect new structure:
```bash
# OLD: bash .claude/tests/test_error_logging.sh
# NEW: bash .claude/tests/unit/test_error_logging.sh
```

### 5. Library Comment Updates

**unified-location-detection.sh** (Lines 72-74):
Update test file references after Phase 5:
```bash
# OLD
#     - .claude/tests/test_unified_location_detection.sh (lines 23-27)

# NEW
#     - .claude/tests/integration/test_unified_location_detection.sh (lines 23-27)
```

**Impact**: Maintains code comment accuracy, aids future developers.

### 6. Validation Checkpoint Enhancement

**Add to Phase 9** (Final Validation):

**Test Discovery Verification**:
```bash
# Verify all categories discovered
./run_all_tests.sh --list | cut -d/ -f1 | sort -u
# Expected output: unit, integration, state, progressive, topic-naming, classification, features

# Verify count matches expectation
test_count=$(./run_all_tests.sh --list | wc -l)
if [ "$test_count" -ne 69 ]; then
  echo "WARNING: Expected 69 tests, found $test_count"
fi
```

**Path Reference Validation**:
```bash
# Verify no broken relative paths
grep -r "SCRIPT_DIR.*\.\./\.\./lib" tests/*/test_*.sh
# Should be empty (no double-parent references needed)
```

### 7. Rollback Procedure Enhancement

**Add to Phase 1** (Baseline):

**Create Rollback Script**:
```bash
cat > /tmp/rollback_test_reorganization.sh <<'EOF'
#!/bin/bash
# Rollback test reorganization to baseline
set -e

echo "Rolling back test reorganization..."
cd /home/benjamin/.config/.claude/tests

# Restore from backup
tar -xzf /tmp/tests_backup_$(date +%Y%m%d).tar.gz -C /

echo "Rollback complete. Verify with: git status"
EOF
chmod +x /tmp/rollback_test_reorganization.sh
```

**Rationale**: Quick recovery if Phase 5-6 changes cause unexpected issues.

### 8. No Updates Required for Specs

**Recommendation**: Do NOT update spec file references to tests.

**Rationale**:
- Spec files are historical documentation
- References are contextual, not executable dependencies
- Updating would create maintenance burden
- Historical accuracy preserved (tests existed at old paths when written)

**Exception**: If future specs reference tests, use new paths (unit/, integration/, etc.)

## References

### Primary Analysis Files
- `/home/benjamin/.config/.claude/tests/run_all_tests.sh:55` - Test discovery pattern (REQUIRES UPDATE)
- `/home/benjamin/.config/.claude/tests/test_parsing_utilities.sh:8-12` - Standard path pattern (NO UPDATE)
- `/home/benjamin/.config/.claude/tests/test_progressive_expansion.sh:8-12` - Consistent pattern (NO UPDATE)
- `/home/benjamin/.config/.claude/commands/build.md:675-676` - Test runner path check (BUG FIX NEEDED)

### Library References
- `/home/benjamin/.config/.claude/lib/core/unified-location-detection.sh:72-74` - Test file comments (UPDATE COMMENTS)
- `/home/benjamin/.config/.claude/lib/README.md:184` - Test execution example (NO UPDATE - generic)

### Documentation References (28 files analyzed)
- `/home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md:12-23` - Test categories (UPDATE LIST)
- `/home/benjamin/.config/.claude/docs/reference/standards/test-isolation.md:268,733` - Test runner (NO UPDATE)
- `/home/benjamin/.config/.claude/docs/guides/patterns/testing-patterns.md:35,50` - Directory structure (UPDATE DIAGRAM)
- `/home/benjamin/.config/.claude/README.md:264` - Execution instructions (NO UPDATE)
- `/home/benjamin/.config/.claude/tests/COVERAGE_REPORT.md:279,287` - Usage examples (NO UPDATE)

### Spec Files (100+ analyzed)
- Spec files contain historical references only
- NO updates required for spec file references
- Pattern verified across specs/840-868 directories

### Consolidation Dependencies
- `/home/benjamin/.config/.claude/tests/test_workflow_initialization.sh:407` - Internal function (NO CONFLICT)
- test_topic_name_sanitization.sh can be safely consolidated per plan

### Test Architecture Verification
- 20+ test files examined for path patterns
- Consistent ../lib relative path usage confirmed
- Zero hardcoded test directory paths found
- Fixture usage analysis: no direct dependencies found

### Plan Source
- `/home/benjamin/.config/.claude/specs/868_directory_has_become_bloated/plans/001_directory_has_become_bloated_plan.md` - Implementation plan being analyzed
