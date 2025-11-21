# Test Directory Reorganization Implementation Plan

## Metadata
- **Date**: 2025-11-20
- **Feature**: Test directory reorganization and optimization
- **Scope**: Reorganize `.claude/tests/` from flat 97-file structure to organized 7-category hierarchy with comprehensive documentation and dependency-safe relocation
- **Estimated Phases**: 9
- **Estimated Hours**: 20
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Complexity Score**: 158.0
- **Structure Level**: 0
- **Research Reports**:
  - [Test Directory Analysis and Reorganization](../reports/001_test_directory_analysis_and_reorganization.md)
  - [Test Relocation Dependency Analysis](../reports/002_test_relocation_dependency_analysis.md)

## Overview

The `.claude/tests/` directory has accumulated significant bloat over iterative development, containing 97 shell scripts with minimal organization, inconsistent naming, and redundant coverage. This plan reorganizes tests into a structured 7-category hierarchy with comprehensive documentation following `.claude/docs/` standards.

**Key Objectives**:
1. Reduce test count from 97 to ~69 files (29% reduction) through strategic removal and consolidation
2. Implement 7-category organizational structure (unit, integration, state, progressive, topic-naming, classification, features)
3. Create comprehensive documentation (13 READMEs) following project standards
4. Preserve git history and maintain zero test regressions
5. Update all dependencies systematically to prevent breakage
6. Improve test discoverability by 85% through categorization

## Research Summary

The research identified critical issues and provided detailed dependency analysis:

**Current State Problems** (from Report 001):
- 97 test files in flat directory structure
- 23 tests identified for removal (obsolete, debug artifacts, one-time scripts)
- 8 tests identified for consolidation into 3 merged suites
- ~40% library coverage with only 6 dedicated unit tests for 45 library files
- Naming inconsistency across 7 different prefixes
- Missing category-specific documentation

**Dependency Analysis** (from Report 002):
- **Test Path Architecture**: All tests use relative paths from SCRIPT_DIR (../lib pattern), making them relocation-safe
- **Critical Dependency**: run_all_tests.sh test discovery requires update for recursive subdirectory search
- **Build Command**: Pre-existing bug in test discovery path needs fixing
- **Documentation**: 28 files reference tests, 3 require structural updates
- **Library Comments**: unified-location-detection.sh contains 3 test file citations requiring updates
- **Spec Files**: 100+ historical references need NO updates (context, not dependencies)

**Proposed Organization**:
- **Unit Tests** (6 files): Library function testing
- **Integration Tests** (9 files): Workflow and command integration
- **State Tests** (9 files): Checkpoint and persistence operations
- **Progressive Tests** (8 files): Plan expansion/collapse functionality
- **Topic Naming Tests** (6 files): Topic directory and slug generation
- **Classification Tests** (4 files): Workflow type detection
- **Features Tests** (33 files in 5 subcategories): Feature-specific testing
- **Utilities** (7 files): Test runners, benchmarks, linters

**Consolidation Strategy**:
- Merge 3 topic naming tests into 1 comprehensive suite
- Merge 2 workflow detection tests into 1 suite
- Consider merging 2 state management tests

## Success Criteria

- [ ] Test count reduced from 97 to ~69 active tests (29% reduction achieved)
- [ ] 7 main category directories created with proper README.md documentation
- [ ] All tests relocated using `git mv` (history preserved)
- [ ] All tests pass with same baseline pass/fail rates (zero regressions)
- [ ] 13 READMEs created following `.claude/docs/` standards
- [ ] `run_all_tests.sh` updated with recursive subdirectory support
- [ ] Archive directory created with obsolete tests and manifest
- [ ] COVERAGE_REPORT.md updated to reflect new structure
- [ ] Navigation links functional across all documentation
- [ ] All dependency references updated (run_all_tests.sh, build.md, 3 doc files, library comments)
- [ ] Zero test breakage from path changes (verified by dependency analysis)

## Technical Design

### Directory Structure Architecture

```
.claude/tests/
├── README.md                          # Main documentation (updated)
├── COVERAGE_REPORT.md                 # Coverage report (updated)
├── run_all_tests.sh                   # Test runner (enhanced for subdirectories)
│
├── unit/                              # Library function testing
│   ├── README.md
│   └── test_*.sh (6 files)
│
├── integration/                       # Workflow testing
│   ├── README.md
│   └── test_*.sh (9 files)
│
├── state/                             # Checkpoint/persistence
│   ├── README.md
│   └── test_*.sh (9 files)
│
├── progressive/                       # Plan expansion/collapse
│   ├── README.md
│   └── test_*.sh (8 files)
│
├── topic-naming/                      # Topic/slug generation
│   ├── README.md
│   └── test_*.sh (6 files, consolidated)
│
├── classification/                    # Workflow detection
│   ├── README.md
│   └── test_*.sh (4 files, consolidated)
│
├── features/                          # Feature-specific tests
│   ├── README.md
│   ├── convert-docs/
│   ├── commands/
│   ├── compliance/
│   ├── location/
│   └── specialized/
│
├── utilities/                         # Non-test utilities
│   ├── README.md
│   ├── lint_*.sh
│   ├── benchmarks/
│   └── manual/
│
└── fixtures/                          # Test fixtures (existing)
    └── README.md (new)
```

### Test Relocation Strategy

**Preservation Requirements**:
- Use `git mv` for all relocations to preserve git history
- Maintain test file naming conventions
- NO updates needed to test file internals (verified safe by dependency analysis)
- Verify test execution from new locations

**Path Safety (from Report 002)**:
All tests use relative path pattern from SCRIPT_DIR:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"
source "$LIB_DIR/plan/plan-core-bundle.sh"
```

**Critical Finding**: This architecture is relocation-safe. Tests moved to subdirectories (e.g., `unit/`, `integration/`) will continue using `../lib` pattern without modification.

### Dependency Update Strategy

**Dependencies Identified by Research**:

1. **run_all_tests.sh** (HIGH PRIORITY - Line 55):
   - Current: `find "$TEST_DIR" -name "test_*.sh"` (maxdepth 1, flat only)
   - Required: `find "$TEST_DIR" -path "*/fixtures" -prune -o -name "test_*.sh" -print`
   - Impact: Critical - test discovery breaks without this update
   - Phase: 6

2. **build.md** (OPPORTUNISTIC FIX - Line 675):
   - Current: `if [ -f ".claude/run_all_tests.sh" ]` (WRONG PATH - pre-existing bug)
   - Required: `if [ -f ".claude/tests/run_all_tests.sh" ]` (CORRECT PATH)
   - Impact: Low - enables build command auto-detection
   - Phase: 6

3. **Documentation** (3 files - Phase 7):
   - testing-protocols.md (Lines 12-23): Update test category list
   - testing-patterns.md (Line 35, 50): Update directory structure diagram
   - test-command-guide.md: Update example test paths

4. **Library Comments** (1 file - Phase 5):
   - unified-location-detection.sh (Lines 72-74): Update 3 test file path comments
   - Impact: Low - comment accuracy only
   - Phase: 5 (during relocation)

**Dependencies NOT Requiring Updates**:
- Test file internals: NO (relative path architecture is relocation-safe)
- Spec files: NO (historical references, 100+ files confirmed safe)
- Fixture references: NO (tests don't use direct fixture paths)
- Command files: NO (delegate to run_all_tests.sh only)

### Consolidation Approach

**Topic Naming Consolidation** (3 → 1):
- Source tests: `test_topic_naming.sh`, `test_topic_slug_validation.sh`, `test_topic_name_sanitization.sh`
- Target: `test_topic_naming_suite.sh`
- Method: Merge test functions, preserve all test cases, verify count matches sum
- Dependency Safety: test_workflow_initialization.sh has internal function with same name (NO conflict confirmed)

**Workflow Detection Consolidation** (2 → 1):
- Source tests: `test_workflow_detection.sh`, `test_offline_classification.sh`
- Target: `test_workflow_detection_suite.sh`
- Method: Combine with mode parameter (online/offline)

### Documentation Standards Implementation

Each category README.md MUST contain:
1. **Purpose**: Category role and scope
2. **Test Coverage**: Functionality tested
3. **Test Files**: List with descriptions
4. **Running Tests**: Execution instructions
5. **Adding New Tests**: Guidelines
6. **Test Patterns**: Common patterns/helpers
7. **Navigation Links**: Parent and related docs

**Template compliance**: Follow `.claude/docs/` README pattern with navigation links to parent and child directories.

## Implementation Phases

### Phase 1: Baseline and Preparation [NOT STARTED]
dependencies: []

**Objective**: Establish baseline metrics and prepare for safe reorganization

**Complexity**: Low

**Tasks**:
- [ ] Run full test suite: `cd /home/benjamin/.config/.claude/tests && ./run_all_tests.sh` (file: run_all_tests.sh)
- [ ] Document baseline pass/fail rates per test file in `/tmp/test_baseline_$(date +%Y%m%d).log`
- [ ] Create backup archive: `tar -czf /tmp/tests_backup_$(date +%Y%m%d).tar.gz /home/benjamin/.config/.claude/tests/`
- [ ] Review investigation_log.md and COVERAGE_REPORT.md for historical context
- [ ] Create rollback procedure script in `/tmp/rollback_test_reorganization.sh`
- [ ] Verify disk space available for reorganization: `df -h /home/benjamin/.config/.claude/tests/`
- [ ] Document all dependency update points from research report 002

**Testing**:
```bash
# Verify baseline captured
test -f /tmp/test_baseline_*.log && echo "Baseline recorded"

# Verify backup exists
test -f /tmp/tests_backup_*.tar.gz && echo "Backup created"

# Verify rollback script created
test -x /tmp/rollback_test_reorganization.sh && echo "Rollback ready"
```

**Expected Duration**: 1 hour

### Phase 2: Archive Obsolete Tests [NOT STARTED]
dependencies: [1]

**Objective**: Remove deprecated tests while preserving git history

**Complexity**: Low

**Tasks**:
- [ ] Create archive directory: `mkdir -p /home/benjamin/.config/.claude/archive/tests/cleanup-2025-11-20` (file: .claude/archive/tests/cleanup-2025-11-20/)
- [ ] Move obsolete tests using git mv:
  - [ ] `git mv test_supervisor_checkpoint_old.sh archive/tests/cleanup-2025-11-20/` (682 lines, replaced by compact version)
  - [ ] `git mv test_checkpoint_v2_simple.sh archive/tests/cleanup-2025-11-20/` (87 lines, simplified duplicate)
  - [ ] `git mv test_debug.sh archive/tests/cleanup-2025-11-20/` (30 lines, 0 test functions)
  - [ ] `git mv fix_arithmetic_increments.sh archive/tests/cleanup-2025-11-20/` (task complete per investigation_log.md)
  - [ ] `git mv run_migration.sh archive/tests/cleanup-2025-11-20/` (if migration verified complete)
  - [ ] `git mv verify_phase7_baselines.sh archive/tests/cleanup-2025-11-20/` (if phase 7 verified complete)
- [ ] Create archive manifest README.md documenting removal rationale (file: .claude/archive/tests/cleanup-2025-11-20/README.md)
- [ ] Update main tests/README.md with reference to archive location

**Testing**:
```bash
# Verify archive directory exists
test -d /home/benjamin/.config/.claude/archive/tests/cleanup-2025-11-20

# Verify archived files no longer in tests/
! test -f /home/benjamin/.config/.claude/tests/test_debug.sh

# Verify git history preserved
git log --follow .claude/archive/tests/cleanup-2025-11-20/test_debug.sh
```

**Expected Duration**: 1 hour

### Phase 3: Consolidate Overlapping Tests [NOT STARTED]
dependencies: [2]

**Objective**: Merge redundant tests into consolidated suites without losing coverage

**Complexity**: Medium

**Tasks**:
- [ ] Create `test_topic_naming_suite.sh` consolidating 3 topic tests (file: .claude/tests/test_topic_naming_suite.sh):
  - [ ] Copy test functions from `test_topic_naming.sh` (8.5K)
  - [ ] Copy test functions from `test_topic_slug_validation.sh` (11K)
  - [ ] Copy test functions from `test_topic_name_sanitization.sh` (11K)
  - [ ] Verify all test cases preserved (count original vs consolidated)
  - [ ] Run consolidated suite to ensure all tests pass
  - [ ] Move original 3 tests to archive with `git mv`
- [ ] Create `test_workflow_detection_suite.sh` consolidating 2 workflow tests (file: .claude/tests/test_workflow_detection_suite.sh):
  - [ ] Merge `test_workflow_detection.sh` (3.9K) and `test_offline_classification.sh` (4.6K)
  - [ ] Add mode parameter for online/offline classification
  - [ ] Verify all test cases preserved
  - [ ] Archive original tests
- [ ] Review `test_state_management.sh` vs `test_state_persistence.sh` for overlap:
  - [ ] Document distinct concerns or consolidate if warranted
  - [ ] Decision documented in consolidation notes

**Testing**:
```bash
# Verify consolidated topic naming suite
./test_topic_naming_suite.sh
# Expected: All tests pass, count matches sum of originals

# Verify consolidated workflow detection suite
./test_workflow_detection_suite.sh
# Expected: All tests pass in both modes

# Verify originals archived
test -f .claude/archive/tests/cleanup-2025-11-20/test_topic_naming.sh
```

**Expected Duration**: 3 hours

### Phase 4: Create Directory Structure [NOT STARTED]
dependencies: [3]

**Objective**: Establish organized subdirectory hierarchy

**Complexity**: Low

**Tasks**:
- [ ] Create 7 main category directories (file: .claude/tests/):
  - [ ] `mkdir -p unit integration state progressive topic-naming classification features utilities`
- [ ] Create features subdirectories (file: .claude/tests/features/):
  - [ ] `mkdir -p convert-docs commands compliance location specialized`
- [ ] Create utilities subdirectories (file: .claude/tests/utilities/):
  - [ ] `mkdir -p benchmarks manual`
- [ ] Create placeholder README.md in each directory:
  - [ ] 7 main category READMEs: `touch {unit,integration,state,progressive,topic-naming,classification,features,utilities}/README.md`
  - [ ] 5 features subcategory READMEs: `touch features/{convert-docs,commands,compliance,location,specialized}/README.md`
  - [ ] fixtures/README.md: `touch fixtures/README.md`
- [ ] Verify directory structure matches design: `tree -d -L 3 /home/benjamin/.config/.claude/tests/`

**Testing**:
```bash
# Verify all directories created
for dir in unit integration state progressive topic-naming classification features utilities; do
  test -d "$dir" && echo "$dir: OK" || echo "$dir: MISSING"
done

# Verify features subdirectories
for subdir in convert-docs commands compliance location specialized; do
  test -d "features/$subdir" && echo "features/$subdir: OK"
done

# Verify README placeholders exist
find . -maxdepth 3 -name README.md | wc -l
# Expected: 13 READMEs (7 main + 5 features + 1 fixtures)
```

**Expected Duration**: 0.5 hours

### Phase 5: Relocate Tests to Categories with Dependency Updates [NOT STARTED]
dependencies: [4]

**Objective**: Move tests to appropriate categories using git mv and update library comment dependencies

**Complexity**: Medium

**Tasks**:
- [ ] Relocate unit tests (6 files) (file: .claude/tests/unit/):
  - [ ] `git mv test_parsing_utilities.sh unit/`
  - [ ] `git mv test_error_logging.sh unit/`
  - [ ] `git mv test_git_commit_utils.sh unit/`
  - [ ] `git mv test_llm_classifier.sh unit/`
  - [ ] `git mv test_array_serialization.sh unit/`
  - [ ] `git mv test_cross_block_function_availability.sh unit/`
- [ ] Relocate integration tests (9 files) (file: .claude/tests/integration/):
  - [ ] `git mv test_command_integration.sh integration/`
  - [ ] `git mv test_workflow_initialization.sh integration/`
  - [ ] `git mv test_workflow_scope_detection.sh integration/`
  - [ ] `git mv test_workflow_classifier_agent.sh integration/`
  - [ ] `git mv test_revise_automode.sh integration/`
  - [ ] `git mv test_repair_workflow.sh integration/`
  - [ ] `git mv test_recovery_integration.sh integration/`
  - [ ] `git mv test_all_fixes_integration.sh integration/`
  - [ ] `git mv test_unified_location_detection.sh integration/`
  - [ ] `git mv test_unified_location_simple.sh integration/`
  - [ ] `git mv test_system_wide_location.sh integration/`
- [ ] Relocate state tests (9 files) (file: .claude/tests/state/):
  - [ ] `git mv test_checkpoint_parallel_ops.sh state/`
  - [ ] `git mv test_checkpoint_schema_v2.sh state/`
  - [ ] `git mv test_state_file_path_consistency.sh state/`
  - [ ] `git mv test_state_machine_persistence.sh state/`
  - [ ] `git mv test_state_management.sh state/`
  - [ ] `git mv test_state_persistence.sh state/`
  - [ ] `git mv test_supervisor_checkpoint.sh state/`
  - [ ] `git mv test_smart_checkpoint_resume.sh state/`
  - [ ] `git mv test_build_state_transitions.sh state/`
- [ ] Relocate progressive tests (8 files) (file: .claude/tests/progressive/):
  - [ ] `git mv test_progressive_expansion.sh progressive/`
  - [ ] `git mv test_progressive_collapse.sh progressive/`
  - [ ] `git mv test_progressive_roundtrip.sh progressive/`
  - [ ] `git mv test_parallel_expansion.sh progressive/`
  - [ ] `git mv test_parallel_collapse.sh progressive/`
  - [ ] `git mv test_plan_updates.sh progressive/`
  - [ ] `git mv test_plan_progress_markers.sh progressive/`
  - [ ] `git mv test_hierarchy_updates.sh progressive/`
- [ ] Relocate topic-naming tests (6 files including consolidated) (file: .claude/tests/topic-naming/):
  - [ ] `git mv test_topic_naming_suite.sh topic-naming/`
  - [ ] `git mv test_topic_filename_generation.sh topic-naming/`
  - [ ] `git mv test_directory_naming_integration.sh topic-naming/`
  - [ ] `git mv test_semantic_slug_commands.sh topic-naming/`
  - [ ] `git mv test_command_topic_allocation.sh topic-naming/`
  - [ ] `git mv test_atomic_topic_allocation.sh topic-naming/`
- [ ] Relocate classification tests (4 files including consolidated) (file: .claude/tests/classification/):
  - [ ] `git mv test_scope_detection.sh classification/`
  - [ ] `git mv test_scope_detection_ab.sh classification/`
  - [ ] `git mv test_workflow_detection_suite.sh classification/`
  - [ ] `git mv test_llm_classifier.sh classification/` (if not already in unit/)
- [ ] Relocate features tests (33 files to 5 subcategories) (file: .claude/tests/features/):
  - [ ] Move convert-docs tests (5 files) to features/convert-docs/
  - [ ] Move command tests (4 files) to features/commands/
  - [ ] Move compliance tests (10 files) to features/compliance/
  - [ ] Move location tests (3 files) to features/location/
  - [ ] Move specialized tests (11 files) to features/specialized/
- [ ] Relocate utilities (7 files) (file: .claude/tests/utilities/):
  - [ ] `git mv lint_bash_conditionals.sh utilities/`
  - [ ] `git mv lint_error_suppression.sh utilities/`
  - [ ] `git mv bench_workflow_classification.sh utilities/benchmarks/`
  - [ ] `git mv manual_e2e_hybrid_classification.sh utilities/manual/`
- [ ] Update library comment dependencies (file: .claude/lib/core/unified-location-detection.sh):
  - [ ] Update line 72: `.claude/tests/test_unified_location_detection.sh` → `.claude/tests/integration/test_unified_location_detection.sh`
  - [ ] Update line 73: `.claude/tests/test_unified_location_simple.sh` → `.claude/tests/integration/test_unified_location_simple.sh`
  - [ ] Update line 74: `.claude/tests/test_system_wide_location.sh` → `.claude/tests/integration/test_system_wide_location.sh`
- [ ] Verify test execution from each category after relocation:
  - [ ] Run sample test from unit/: `cd unit && ./test_parsing_utilities.sh`
  - [ ] Run sample test from integration/: `cd integration && ./test_command_integration.sh`
  - [ ] Run sample test from state/: `cd state && ./test_checkpoint_parallel_ops.sh`

**Testing**:
```bash
# Verify test count in each category
echo "Unit: $(ls unit/test_*.sh 2>/dev/null | wc -l) (expected: 6)"
echo "Integration: $(ls integration/test_*.sh 2>/dev/null | wc -l) (expected: 11)"
echo "State: $(ls state/test_*.sh 2>/dev/null | wc -l) (expected: 9)"
echo "Progressive: $(ls progressive/test_*.sh 2>/dev/null | wc -l) (expected: 8)"
echo "Topic-naming: $(ls topic-naming/test_*.sh 2>/dev/null | wc -l) (expected: 6)"
echo "Classification: $(ls classification/test_*.sh 2>/dev/null | wc -l) (expected: 4)"

# Verify no tests remain in root (except run_all_tests.sh)
root_tests=$(ls test_*.sh 2>/dev/null | wc -l)
test "$root_tests" -eq 0 && echo "Root cleared: OK" || echo "Root still has $root_tests tests"

# Verify library comments updated
grep -n "tests/integration/test_unified_location" /home/benjamin/.config/.claude/lib/core/unified-location-detection.sh
```

**Expected Duration**: 2.5 hours

### Phase 6: Update Test Runner and Build Command [NOT STARTED]
dependencies: [5]

**Objective**: Enhance run_all_tests.sh for recursive test execution and fix build.md test discovery

**Complexity**: Medium

**Tasks**:
- [ ] Update test discovery to search subdirectories (file: .claude/tests/run_all_tests.sh):
  - [ ] Update line 55: Change `find` pattern to search recursively with exclusions
  - [ ] New pattern: `find "$TEST_DIR" -path "*/fixtures" -prune -o -path "*/logs" -prune -o -path "*/validation_results" -prune -o -name "test_*.sh" -print | grep -v "run_all_tests.sh" | sort`
  - [ ] Verify excludes: fixtures/, logs/, validation_results/, tmp/
- [ ] Add category-level reporting (file: .claude/tests/run_all_tests.sh):
  - [ ] Report pass/fail counts per category
  - [ ] Display category summary after full run
- [ ] Implement `--category` flag for selective execution (file: .claude/tests/run_all_tests.sh):
  - [ ] `./run_all_tests.sh --category unit` runs only unit tests
  - [ ] `./run_all_tests.sh --category state` runs only state tests
  - [ ] Validate category name against known categories
- [ ] Implement `--list` flag to show all tests (file: .claude/tests/run_all_tests.sh):
  - [ ] Display tests grouped by category
  - [ ] Show test count per category
- [ ] Update pollution detection for new structure (file: .claude/tests/run_all_tests.sh):
  - [ ] Check for empty topic directories in `.claude/specs/`
  - [ ] Report before/after directory counts
- [ ] Fix build.md test discovery bug (file: .claude/commands/build.md):
  - [ ] Update line 675: `if [ -f ".claude/run_all_tests.sh" ]` → `if [ -f ".claude/tests/run_all_tests.sh" ]`
  - [ ] Update line 676: `TEST_COMMAND="./.claude/run_all_tests.sh"` → `TEST_COMMAND="./.claude/tests/run_all_tests.sh"`

**Testing**:
```bash
# Test recursive discovery
./run_all_tests.sh --list | grep -c "test_.*\.sh"
# Expected: ~69 tests found

# Test category filtering
./run_all_tests.sh --category unit
# Expected: Only unit tests run (6 tests)

# Test full suite with category reporting
./run_all_tests.sh
# Expected: Category-level summary displayed

# Verify pollution detection
# Should report no empty directories created

# Verify build.md fix
grep ".claude/tests/run_all_tests.sh" /home/benjamin/.config/.claude/commands/build.md
```

**Expected Duration**: 2.5 hours

### Phase 7: Create Category Documentation with Cross-Reference Updates [NOT STARTED]
dependencies: [6]

**Objective**: Document each category following `.claude/docs/` standards and update documentation cross-references

**Complexity**: High

**Tasks**:
- [ ] Create unit/README.md (file: .claude/tests/unit/README.md):
  - [ ] Purpose: Library function unit testing
  - [ ] List 6 test files with descriptions
  - [ ] Document test patterns (library sourcing, function isolation)
  - [ ] Add navigation links
- [ ] Create integration/README.md (file: .claude/tests/integration/README.md):
  - [ ] Purpose: Workflow and command integration testing
  - [ ] List 11 test files with descriptions
  - [ ] Note large files for potential splitting
  - [ ] Add navigation links
- [ ] Create state/README.md (file: .claude/tests/state/README.md):
  - [ ] Purpose: Checkpoint and state persistence testing
  - [ ] List 9 test files with descriptions
  - [ ] Document state testing patterns
  - [ ] Add navigation links
- [ ] Create progressive/README.md (file: .claude/tests/progressive/README.md):
  - [ ] Purpose: Plan expansion/collapse testing
  - [ ] List 8 test files with descriptions
  - [ ] Document progressive structure patterns
  - [ ] Add navigation links
- [ ] Create topic-naming/README.md (file: .claude/tests/topic-naming/README.md):
  - [ ] Purpose: Topic directory and slug generation testing
  - [ ] List 6 test files (including consolidated suite)
  - [ ] Document naming convention patterns
  - [ ] Add navigation links
- [ ] Create classification/README.md (file: .claude/tests/classification/README.md):
  - [ ] Purpose: Workflow type detection testing
  - [ ] List 4 test files (including consolidated suite)
  - [ ] Document LLM classifier patterns
  - [ ] Add navigation links
- [ ] Create features/README.md (file: .claude/tests/features/README.md):
  - [ ] Purpose: Feature-specific testing organization
  - [ ] List 5 subcategories with overviews
  - [ ] Add navigation links to subcategories
- [ ] Create features subcategory READMEs (5 files):
  - [ ] features/convert-docs/README.md (5 tests)
  - [ ] features/commands/README.md (4 tests)
  - [ ] features/compliance/README.md (10 tests)
  - [ ] features/location/README.md (3 tests)
  - [ ] features/specialized/README.md (11 tests)
- [ ] Create utilities/README.md (file: .claude/tests/utilities/README.md):
  - [ ] Purpose: Non-test utilities documentation
  - [ ] List linters, benchmarks, manual test tools
  - [ ] Add navigation links
- [ ] Create fixtures/README.md (file: .claude/tests/fixtures/README.md):
  - [ ] Document fixture directory structure
  - [ ] List 12 fixture subdirectories with purposes
  - [ ] Document fixture usage patterns
- [ ] Update main tests/README.md (file: .claude/tests/README.md):
  - [ ] Reflect 7-category organization
  - [ ] Add category index table with links
  - [ ] Document removed tests with rationale
  - [ ] Update test discovery instructions
  - [ ] Add quick start guide for new structure
- [ ] Update documentation cross-references (3 critical files):
  - [ ] Update testing-protocols.md (file: .claude/docs/reference/standards/testing-protocols.md):
    - [ ] Replace flat test list (lines 12-23) with category-based organization
    - [ ] Add category structure: unit/, integration/, state/, progressive/, topic-naming/, classification/, features/
  - [ ] Update testing-patterns.md (file: .claude/docs/guides/patterns/testing-patterns.md):
    - [ ] Update directory tree diagram (lines 35, 50) with subdirectories
  - [ ] Review test-command-guide.md for test path examples requiring updates

**Testing**:
```bash
# Verify all READMEs exist
find . -name README.md | sort
# Expected: 14 READMEs (main + 7 categories + 5 features + fixtures)

# Verify each README has required sections
for readme in $(find . -name README.md); do
  echo "Checking $readme"
  grep -q "## Purpose" "$readme" || echo "  Missing Purpose"
  grep -q "## Navigation" "$readme" || echo "  Missing Navigation"
done

# Verify documentation cross-references updated
grep -n "unit/test_parsing" /home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md
grep -n "integration/" /home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md

# Verify navigation links are valid (no broken links)
# Manual verification recommended
```

**Expected Duration**: 4.5 hours

### Phase 8: Update Coverage Report [NOT STARTED]
dependencies: [7]

**Objective**: Reflect new organization in COVERAGE_REPORT.md

**Complexity**: Low

**Tasks**:
- [ ] Update test suite breakdown with new categories (file: .claude/tests/COVERAGE_REPORT.md):
  - [ ] List tests by category instead of flat list
  - [ ] Update test counts per category
- [ ] Document removed tests and rationale (file: .claude/tests/COVERAGE_REPORT.md):
  - [ ] List 23 removed tests with removal reasons
  - [ ] Reference archive location
- [ ] Update coverage percentages after consolidation (file: .claude/tests/COVERAGE_REPORT.md):
  - [ ] Recalculate library coverage (currently ~40%)
  - [ ] Identify coverage gaps from reorganization
- [ ] Add navigation links to category READMEs (file: .claude/tests/COVERAGE_REPORT.md):
  - [ ] Link each category section to its README
- [ ] Add reorganization metrics (file: .claude/tests/COVERAGE_REPORT.md):
  - [ ] Before: 97 tests, flat structure
  - [ ] After: 69 tests, 7 categories
  - [ ] Reduction: 29%, improvement: 85% discoverability

**Testing**:
```bash
# Verify coverage report updated
grep -q "7-category organization" .claude/tests/COVERAGE_REPORT.md

# Verify test counts accurate
grep -q "69 active tests" .claude/tests/COVERAGE_REPORT.md

# Verify navigation links present
grep -c "README.md" .claude/tests/COVERAGE_REPORT.md
# Expected: ≥7 (one per category)
```

**Expected Duration**: 1.5 hours

### Phase 9: Final Validation and Dependency Verification [NOT STARTED]
dependencies: [8]

**Objective**: Verify reorganization success, zero regressions, and all dependency updates complete

**Complexity**: Medium

**Tasks**:
- [ ] Run complete test suite: `./run_all_tests.sh` (file: .claude/tests/run_all_tests.sh)
- [ ] Compare results to baseline from Phase 1:
  - [ ] Generate comparison report: `diff /tmp/test_baseline_*.log /tmp/test_final_$(date +%Y%m%d).log`
  - [ ] Verify same pass/fail rates (zero regressions)
- [ ] Verify all tests execute from new locations:
  - [ ] Run each category separately with `--category` flag
  - [ ] Check for path-related errors
- [ ] Validate README navigation links:
  - [ ] Manually verify links in main README
  - [ ] Verify category README links
  - [ ] Check for broken relative paths
- [ ] Verify fixtures still accessible:
  - [ ] Run tests that use fixtures
  - [ ] Check fixture path references
- [ ] Review git history preservation:
  - [ ] `git log --follow` on several relocated tests
  - [ ] Verify archive commits show proper git mv
- [ ] Run pollution detection:
  - [ ] Verify no empty directories created during testing
  - [ ] Check `.claude/specs/` for pollution
- [ ] Verify all dependency updates complete:
  - [ ] Confirm run_all_tests.sh recursive discovery (line 55 updated)
  - [ ] Confirm build.md test path fix (lines 675-676 updated)
  - [ ] Confirm library comments updated (unified-location-detection.sh lines 72-74)
  - [ ] Confirm documentation cross-references updated (3 files: testing-protocols.md, testing-patterns.md, test-command-guide.md)
  - [ ] Run test discovery validation: `./run_all_tests.sh --list | wc -l` (expect ~69)
  - [ ] Run category validation: `./run_all_tests.sh --list | cut -d/ -f1 | sort -u` (expect 7 categories)
- [ ] Create reorganization completion report (file: /tmp/reorganization_report_$(date +%Y%m%d).md):
  - [ ] Document final metrics (test count, categories, READMEs)
  - [ ] Compare baseline vs final results
  - [ ] List all removed/consolidated tests
  - [ ] List all dependency updates performed
  - [ ] Success criteria verification

**Testing**:
```bash
# Full test suite verification
./run_all_tests.sh > /tmp/test_final_$(date +%Y%m%d).log 2>&1

# Pass rate comparison
baseline_pass=$(grep -c "PASS" /tmp/test_baseline_*.log)
final_pass=$(grep -c "PASS" /tmp/test_final_*.log)
echo "Baseline: $baseline_pass passes, Final: $final_pass passes"

# Category execution verification
for cat in unit integration state progressive topic-naming classification features; do
  ./run_all_tests.sh --category "$cat" && echo "$cat: OK" || echo "$cat: FAILED"
done

# Git history verification
git log --follow --oneline unit/test_parsing_utilities.sh | head -5
# Expected: Shows history before relocation

# Pollution check
empty_dirs=$(find .claude/specs -type d -empty 2>/dev/null | wc -l)
test "$empty_dirs" -eq 0 && echo "No pollution" || echo "WARNING: $empty_dirs empty dirs"

# Dependency update verification
echo "Checking dependency updates..."
grep -q 'find.*prune.*test_\*.sh' run_all_tests.sh && echo "✓ run_all_tests.sh updated" || echo "✗ run_all_tests.sh NOT updated"
grep -q '.claude/tests/run_all_tests.sh' /home/benjamin/.config/.claude/commands/build.md && echo "✓ build.md updated" || echo "✗ build.md NOT updated"
grep -q 'tests/integration/test_unified' /home/benjamin/.config/.claude/lib/core/unified-location-detection.sh && echo "✓ Library comments updated" || echo "✗ Library comments NOT updated"
grep -q 'unit/' /home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md && echo "✓ testing-protocols.md updated" || echo "✗ testing-protocols.md NOT updated"
```

**Expected Duration**: 3.5 hours

## Testing Strategy

### Overall Testing Approach

**Per-Phase Validation**:
- Each phase includes specific testing section with verification commands
- Tests must pass before proceeding to dependent phases
- Baseline comparison ensures zero regressions

**Dependency Safety**:
- Research report 002 confirms test path architecture is relocation-safe
- NO test file internals require modification (relative path pattern preserved)
- 4 critical dependencies identified and addressed in phases 5-7
- Spec files require NO updates (100+ historical references confirmed safe)

**Rollback Strategy**:
- Phase 1 creates backup tarball for complete rollback if needed
- Phase 1 creates automated rollback script for quick recovery
- Git history preserved via `git mv` allows partial rollbacks
- Archive directory preserves removed tests for reference

**Test Isolation**:
- All tests already use isolation patterns (CLAUDE_SPECS_ROOT overrides)
- Reorganization does not change test isolation behavior
- Pollution detection remains in run_all_tests.sh

### Phase-Specific Testing

**Phase 3 (Consolidation) Testing**:
- Critical phase requiring careful verification
- Test count validation: sum of original test cases must equal consolidated count
- Manual review of merged test functions recommended
- Original tests preserved in archive (not deleted)

**Phase 5 (Relocation) Testing**:
- Verify each category has expected test count
- Run sample tests from each category after relocation
- Verify library comment updates (unified-location-detection.sh)
- NO test file internal modifications expected (architecture verified safe)

**Phase 6 (Test Runner) Testing**:
- Test recursive discovery finds all tests
- Verify category filtering works correctly
- Ensure pollution detection still functional
- Verify build.md test discovery fix enables auto-detection

**Phase 7 (Documentation) Testing**:
- Verify all category READMEs created
- Verify documentation cross-references updated (3 critical files)
- Manual verification of navigation links

**Phase 9 (Final Validation) Testing**:
- Most comprehensive testing phase
- Baseline comparison is critical success criterion
- Manual verification of documentation links required
- Git history spot-check for several files
- Complete dependency update verification checklist

## Documentation Requirements

### Documentation Created (14 READMEs)

**Main Documentation**:
- Updated tests/README.md with 7-category organization guide
- Updated COVERAGE_REPORT.md with new structure metrics

**Category Documentation** (8 READMEs):
- unit/README.md - Unit testing guide
- integration/README.md - Integration testing guide
- state/README.md - State testing guide
- progressive/README.md - Progressive structure testing guide
- topic-naming/README.md - Topic naming testing guide
- classification/README.md - Classification testing guide
- features/README.md - Feature testing organization guide
- utilities/README.md - Utilities documentation

**Subcategory Documentation** (5 READMEs):
- features/convert-docs/README.md
- features/commands/README.md
- features/compliance/README.md
- features/location/README.md
- features/specialized/README.md

**Supporting Documentation**:
- fixtures/README.md - Fixture structure and usage
- .claude/archive/tests/cleanup-2025-11-20/README.md - Archive manifest

### Documentation Standards Compliance

All READMEs must follow `.claude/docs/` standards:
- **Purpose section**: Clear category role explanation
- **Test Coverage section**: Functionality tested in category
- **Test Files section**: List with descriptions
- **Running Tests section**: Execution instructions
- **Adding New Tests section**: Guidelines for new tests
- **Test Patterns section**: Common patterns and helpers
- **Navigation Links section**: Parent and child links

### Documentation Cross-References Updated

**Critical Updates** (Phase 7):
1. **testing-protocols.md**: Replace flat test list with category-based organization
2. **testing-patterns.md**: Update directory structure diagram with subdirectories
3. **test-command-guide.md**: Update example test paths

Cross-references to:
- [Testing Protocols](/home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md)
- [Test Isolation Standards](/home/benjamin/.config/.claude/docs/reference/standards/test-isolation.md)
- [Directory Organization](/home/benjamin/.config/.claude/docs/concepts/directory-organization.md)

## Dependencies

### External Dependencies
- Git (for history-preserving relocations)
- Bash 4.0+ (for test suite execution)
- Standard Unix utilities (find, grep, wc, tree)

### Internal Dependencies

**Code Dependencies** (4 critical updates):
1. **run_all_tests.sh** (Line 55): Test discovery pattern
   - Current: Flat directory search (maxdepth 1)
   - Required: Recursive search with exclusions
   - Phase: 6

2. **build.md** (Lines 675-676): Test runner path
   - Current: Incorrect path (.claude/run_all_tests.sh)
   - Required: Correct path (.claude/tests/run_all_tests.sh)
   - Phase: 6

3. **unified-location-detection.sh** (Lines 72-74): Test file comments
   - Current: Flat directory paths
   - Required: Subdirectory paths (integration/)
   - Phase: 5

4. **Documentation** (3 files): Cross-references
   - testing-protocols.md: Test category list
   - testing-patterns.md: Directory structure diagram
   - test-command-guide.md: Example test paths
   - Phase: 7

**Infrastructure Dependencies**:
- Existing test isolation infrastructure (CLAUDE_SPECS_ROOT)
- run_all_tests.sh test runner
- Test fixture directories (12 subdirectories)

**Dependencies NOT Requiring Updates** (verified by research):
- Test file internals: NO (relative path architecture is relocation-safe)
- Spec files: NO (100+ historical references confirmed safe)
- Fixture references: NO (tests don't use direct fixture paths)
- Command files: NO (delegate to run_all_tests.sh only)

### Phase Dependencies

Phase dependencies enable sequential execution with clear checkpoints:
- **Phase 1** (Baseline): No dependencies, establishes baseline
- **Phase 2** (Archive): Depends on Phase 1 (baseline established)
- **Phase 3** (Consolidate): Depends on Phase 2 (obsolete removed)
- **Phase 4** (Structure): Depends on Phase 3 (consolidation complete)
- **Phase 5** (Relocate): Depends on Phase 4 (directories created)
- **Phase 6** (Test Runner): Depends on Phase 5 (tests relocated)
- **Phase 7** (Documentation): Depends on Phase 6 (runner updated)
- **Phase 8** (Coverage): Depends on Phase 7 (docs complete)
- **Phase 9** (Validation): Depends on Phase 8 (all changes complete)

**Note**: This plan uses strict sequential dependencies to ensure safe reorganization with validation checkpoints. Parallel execution is not recommended for this reorganization due to file system state dependencies.

## Risk Management

### Risk 1: Test Breakage from Relocation
**Likelihood**: Very Low (reduced from Low based on research)
**Impact**: High
**Mitigation**:
- Research confirms test path architecture is relocation-safe (relative paths from SCRIPT_DIR)
- Use `git mv` exclusively (preserves history and updates references)
- Run tests after each category relocation
- Keep backup tarball for complete rollback
- Phase 9 includes comprehensive regression testing
- NO test file internal modifications required (verified by dependency analysis)

### Risk 2: Loss of Coverage from Consolidation
**Likelihood**: Medium
**Impact**: Medium
**Mitigation**:
- Document all test cases before consolidation
- Manual review of consolidated test functions
- Compare test counts (before sum = after count)
- Keep originals in archive (not deleted permanently)
- Verify consolidated suites pass all tests before archiving originals

### Risk 3: Incomplete Documentation
**Likelihood**: Medium
**Impact**: Low
**Mitigation**:
- Use standardized template for all READMEs
- Checklist verification in Phase 7 testing
- Cross-reference with testing-protocols.md
- Iterative improvement possible post-implementation

### Risk 4: Git History Confusion
**Likelihood**: Low
**Impact**: Low
**Mitigation**:
- `git mv` preserves file history (git log --follow works)
- Clear commit messages per phase
- Create git tag before reorganization
- Archive manifest documents all changes

### Risk 5: Broken Dependencies from Relocation
**Likelihood**: Very Low (NEW - addressed by research)
**Impact**: Medium
**Mitigation**:
- Research report 002 identified all dependencies systematically
- 4 critical dependencies addressed in phases 5-7
- 100+ spec files confirmed safe (historical references only)
- Test file internals confirmed safe (relative path architecture)
- Phase 9 includes complete dependency verification checklist

### Risk 6: Test Discovery Failure
**Likelihood**: Very Low (NEW - addressed by plan)
**Impact**: High
**Mitigation**:
- run_all_tests.sh update in Phase 6 is critical path item
- Specific line number (55) and exact pattern provided
- Testing includes verification of recursive discovery
- Category filtering implementation provides fallback

## Success Metrics

### Quantitative Metrics

1. **Test Count Reduction**: 97 → 69 files (29% reduction)
2. **Category Organization**: 1 flat directory → 7 organized categories
3. **Documentation Coverage**: 1 README → 14 READMEs (100% category coverage)
4. **Test Pass Rate**: Maintain baseline pass rate (no regressions)
5. **Execution Time**: Potential 20% reduction from fewer redundant tests
6. **Dependency Updates**: 4 critical updates completed successfully

### Qualitative Metrics

1. **Discoverability**: Can new contributor find relevant test in <2 minutes?
2. **Maintainability**: Is test organization clear and logical?
3. **Documentation Quality**: Do READMEs follow .claude/docs/ standards?
4. **Standards Compliance**: Does structure align with project conventions?
5. **Dependency Safety**: Are all references updated correctly?
6. **Rollback Capability**: Can reorganization be reversed if needed?

## Conclusion

The `.claude/tests/` directory reorganization addresses significant bloat (97 files) through strategic removal (23 tests), consolidation (8 → 3 tests), and structured organization (7 categories with comprehensive documentation). Comprehensive dependency analysis confirms the test architecture is relocation-safe, requiring only 4 strategic updates to maintain full functionality. This plan provides detailed implementation phases following `.claude/docs/` standards, ensuring high-quality test coverage with improved maintainability and zero dependency breakage.

**Key Improvements from Dependency Research**:
1. Confirmed test relocation is safe (relative path architecture)
2. Identified 4 critical dependencies requiring updates
3. Confirmed 100+ spec files are safe (historical references only)
4. Added specific dependency update tasks to phases 5-7
5. Enhanced Phase 9 with complete dependency verification checklist
6. Reduced relocation risk from Low to Very Low

**Recommended Execution**:
1. Execute phases sequentially (strict dependencies)
2. Complete all testing checkpoints before proceeding
3. Use backup and rollback procedures if issues arise
4. Validate all 4 dependency updates in Phase 9
5. Update project documentation to reference new structure

## References

### Project Documentation
- [Testing Protocols](/home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md)
- [Test Isolation Standards](/home/benjamin/.config/.claude/docs/reference/standards/test-isolation.md)
- [Directory Organization](/home/benjamin/.config/.claude/docs/concepts/directory-organization.md)
- [Documentation Policy](/home/benjamin/.config/CLAUDE.md#documentation_policy)

### Research Reports
- [Test Directory Analysis and Reorganization](../reports/001_test_directory_analysis_and_reorganization.md)
- [Test Relocation Dependency Analysis](../reports/002_test_relocation_dependency_analysis.md)

### Test Files Referenced
- Current README: `/home/benjamin/.config/.claude/tests/README.md`
- Coverage Report: `/home/benjamin/.config/.claude/tests/COVERAGE_REPORT.md`
- Investigation Log: `/home/benjamin/.config/.claude/tests/investigation_log.md`
- Test Runner: `/home/benjamin/.config/.claude/tests/run_all_tests.sh`

### Critical Dependencies
- `/home/benjamin/.config/.claude/tests/run_all_tests.sh:55` - Test discovery (REQUIRES UPDATE)
- `/home/benjamin/.config/.claude/commands/build.md:675-676` - Test path (BUG FIX)
- `/home/benjamin/.config/.claude/lib/core/unified-location-detection.sh:72-74` - Comments (UPDATE)
- `/home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md:12-23` - Categories (UPDATE)
- `/home/benjamin/.config/.claude/docs/guides/patterns/testing-patterns.md:35,50` - Diagram (UPDATE)

### Library Documentation
- Library Overview: `/home/benjamin/.config/.claude/lib/README.md`
- 45 library files requiring test coverage assessment
