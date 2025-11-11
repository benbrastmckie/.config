# Coordinate Error Fixes Implementation Plan

## Metadata
- **Date**: 2025-11-11
- **Feature**: Fix coordinate command verification failures and state persistence issues
- **Scope**: Coordinate command infrastructure, verification checkpoints, report path discovery, state persistence
- **Estimated Phases**: 4 (Phase 4 made optional)
- **Estimated Hours**: 8.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Coordinate Error Patterns Analysis](../reports/001_coordinate_error_patterns.md)
  - [Coordinate Infrastructure Analysis](../reports/002_coordinate_infrastructure_analysis.md)
  - [Fail-Fast Policy Analysis](../../659_658_infrastructure_and_claude_docs_standards/reports/001_fail_fast_policy_analysis.md)
  - [Existing Plan Analysis](../../659_658_infrastructure_and_claude_docs_standards/reports/002_existing_plan_analysis.md)
- **Structure Level**: 0
- **Complexity Score**: 34.0

## Overview

The /coordinate command exhibits two critical error patterns: (1) verification checkpoints execute before dynamic report path discovery, causing false path mismatch failures, and (2) REPORT_PATHS array reconstruction returns zero paths due to state persistence timing issues. This plan implements essential fixes to verification checkpoint ordering and enhances reconstruct_report_paths_array() with filesystem fallback discovery (REQUIRED verification fallback per Spec 057). Diagnostic enhancements are included for faster debugging. Phase 4 (state persistence verification) is deferred as optional work - no evidence of state WRITE failures observed in production.

## Research Summary

Research revealed that coordinate's error patterns stem from bash subprocess isolation constraints combined with the two-phase report path pattern: Phase 0 pre-calculates generic paths (001_topic1.md) for state persistence, while research agents create descriptive filenames (001_auth_patterns.md) following behavioral guidelines. The discovery reconciliation logic exists (coordinate.md:529-548) but executes AFTER verification checkpoints (line 550+), causing verification to check against stale generic paths. The REPORT_PATHS array reconstruction fails when state persistence READ operations incomplete.

**Fail-Fast Policy Compliance** (Reports 001_fail_fast_policy_analysis.md and 002_existing_plan_analysis.md): Plan analysis confirms NO bootstrap fallbacks present. Phase 2 fallback discovery implements REQUIRED verification fallback per Spec 057 taxonomy (detects errors, does not hide them). All phases promote fail-fast error reporting through immediate detection, transparent fallbacks with stderr warnings, and enhanced diagnostics.

## Success Criteria
- [ ] Verification checkpoints pass for all research report variations (descriptive filenames)
- [ ] REPORT_PATHS array reconstruction returns correct count (1-4 reports) with fallback discovery
- [ ] Dynamic report path discovery executes BEFORE verification in coordinate.md
- [ ] Diagnostic output shows expected vs actual paths on verification failure
- [ ] All coordinate tests passing (100% reliability maintained)
- [ ] Zero false-positive verification failures from path mismatches

## Technical Design

### Architecture Overview

Fix execution follows three-layer approach:
1. **Checkpoint Reordering**: Move dynamic discovery (Lines 529-548) before verification (Line 550+) in coordinate.md
2. **Fallback Discovery**: Enhance reconstruct_report_paths_array() with filesystem glob pattern as secondary path source
3. **Diagnostic Enhancement**: Expand verification failure output to show expected vs actual paths with troubleshooting steps

### Component Interactions

```
Coordinate Bash Block 2+ (Research Phase Verification)
│
├─> Load Workflow State (loads generic REPORT_PATH_N)
├─> Reconstruct REPORT_PATHS Array
│   ├─> Primary: Use exported REPORT_PATH_N variables
│   └─> Fallback: Glob search ${TOPIC_PATH}/reports/NNN_*.md
│
├─> Dynamic Report Path Discovery (MOVED HERE - Before Verification)
│   └─> Update REPORT_PATHS with actual created filenames
│
└─> Verification Checkpoint (MOVED AFTER Discovery)
    ├─> Iterate REPORT_PATHS array
    ├─> Call verify_file_created() for each path
    └─> If failure: Enhanced diagnostic output
        ├─> Expected vs Actual path comparison
        ├─> Directory listing showing actual files
        └─> Troubleshooting steps with root cause analysis
```

### State Persistence Flow

```
Initialization Block:
  initialize_workflow_paths()
    ├─> Export REPORT_PATH_0="...001_topic1.md"
    ├─> Export REPORT_PATH_1="...002_topic2.md"
    ├─> Export REPORT_PATH_N (for N in 0..3)
    └─> append_workflow_state("REPORT_PATHS_COUNT", 4)

Verification Block:
  reconstruct_report_paths_array()
    ├─> Primary path: Read REPORT_PATH_N from state
    │   └─> Success: REPORT_PATHS=["...001_topic1.md", ...]
    └─> Fallback path (if primary returns 0):
        └─> Glob search: find ${TOPIC_PATH}/reports/[0-9][0-9][0-9]_*.md
            └─> Success: REPORT_PATHS=["...001_auth_patterns.md", ...]

  dynamic_report_path_discovery() [NEW LOCATION]
    └─> For each expected position (1 to RESEARCH_COMPLEXITY):
        ├─> Pattern: NNN_*.md where NNN = sprintf('%03d', i)
        ├─> Find actual file: find ... -name "${PATTERN}_*.md"
        └─> Update REPORT_PATHS[i-1] with discovered path

  verification_checkpoint()
    └─> For each path in REPORT_PATHS:
        └─> verify_file_created(path) with enhanced diagnostic
```

### Verification Enhancement Design

**Current Output** (coordinate.md:500-512):
```
✗ ERROR [Research]: Research report 1/2 verification failed
   Expected: /path/to/001_topic1.md
   Found: File does not exist
```

**Enhanced Output**:
```
✗ ERROR [Research]: Research report 1/2 verification failed

Expected vs Actual:
  ✗ Report 1/2: Path mismatch
     Expected: /path/to/reports/001_topic1.md
     Found in directory:
       - 001_coordinate_infrastructure.md (29,547 bytes, created 2025-11-11 10:30)
       - 002_testing_best_practices.md (15,234 bytes, created 2025-11-11 10:31)

  ✓ Report 2/2: Verified
     Path: /path/to/reports/002_testing_best_practices.md

Root Cause: Dynamic discovery executed after verification checkpoint

TROUBLESHOOTING:
  1. Verify research agents completed successfully
     Command: grep -r "REPORT_CREATED:" "${CLAUDE_PROJECT_DIR}/.claude/tmp/"
  2. Check dynamic discovery logic execution
     File: .claude/commands/coordinate.md (Lines 529-548)
  3. List actual files created
     Command: ls -la "${TOPIC_PATH}/reports/"
  4. Verify topic path calculation
     Command: echo "${TOPIC_PATH}"

Context:
  - Workflow ID: coordinate_1731340200
  - Workflow Scope: research-and-plan
  - Research Complexity: 2
  - Topic Path: /home/user/.claude/specs/657_review_tests/
```

## Implementation Phases

### Phase 1: Reorder Verification Checkpoint in coordinate.md [COMPLETED]
dependencies: []

**Objective**: Move dynamic report path discovery before verification checkpoint to ensure verification checks against actual created filenames

**Complexity**: Low

Tasks:
- [x] Open coordinate.md and locate verification checkpoint section (Lines 448-603)
- [x] Identify dynamic discovery block (Lines 529-548: "Dynamic Report Path Discovery" comment through REPORT_PATHS update)
- [x] Move dynamic discovery to execute immediately after reconstruct_report_paths_array() call (after Line 448)
- [x] Update line number references in comments to reflect new positions
- [x] Add comment marker: "# CRITICAL: Discovery MUST execute before verification to reconcile agent-created filenames"
- [x] Test coordinate command with simple research workflow (2 topics)
- [x] Verify verification checkpoint passes with descriptive report filenames
- [x] Commit changes: `fix(coordinate): move dynamic report path discovery before verification checkpoint`

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
# Test Phase 1: Verification checkpoint ordering
cd "${CLAUDE_PROJECT_DIR}/.claude/tests"
bash test_coordinate_verification_ordering.sh

# Manual integration test
cd "${CLAUDE_PROJECT_DIR}"
/coordinate "Research authentication patterns and testing best practices"
# Expected: Verification passes even though agents create descriptive filenames
# Verify: grep "✓" output shows all reports verified
```

**Expected Duration**: 1.0 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `fix(coordinate): complete Phase 1 - Verification Checkpoint Reordering`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Enhance reconstruct_report_paths_array() with Fallback Discovery [COMPLETED]
dependencies: [1]

**Objective**: Add filesystem glob pattern fallback to reconstruct_report_paths_array() ensuring array reconstruction succeeds even when state persistence incomplete

**Complexity**: Medium

Tasks:
- [x] Open workflow-initialization.sh and locate reconstruct_report_paths_array() function (Lines 345-369)
- [x] Add fallback discovery section after primary reconstruction attempt
- [x] Implement check: `if [ ${#REPORT_PATHS[@]} -eq 0 ] && [ -n "${TOPIC_PATH:-}" ]; then`
- [x] Add warning message to stderr: "Warning: State reconstruction failed, using filesystem discovery fallback (acceptable per Spec 057)"
- [x] Implement glob pattern: `for report_file in "$REPORTS_DIR"/[0-9][0-9][0-9]_*.md; do`
- [x] Add file existence check and preserve numeric sorting
- [x] Update function documentation: "Primary: state file, Fallback: filesystem (verification fallback per Spec 057)"
- [x] Test fallback by temporarily removing state file and invoking reconstruction

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
# Test Phase 2: Fallback discovery
cd "${CLAUDE_PROJECT_DIR}/.claude/tests"
bash test_reconstruct_report_paths_array_fallback.sh

# Manual fallback test
cd "${CLAUDE_PROJECT_DIR}"
# 1. Create test topic with reports
mkdir -p /tmp/test_topic/reports
touch /tmp/test_topic/reports/001_auth_patterns.md
touch /tmp/test_topic/reports/002_oauth_flows.md

# 2. Test reconstruction without state file
TOPIC_PATH="/tmp/test_topic"
source .claude/lib/workflow-initialization.sh
reconstruct_report_paths_array
echo "Reconstructed ${#REPORT_PATHS[@]} paths (expected: 2)"
echo "${REPORT_PATHS[@]}"

# Expected: Fallback discovers both files via glob pattern
```

**Expected Duration**: 2 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `fix(coordinate): complete Phase 2 - Fallback Discovery Enhancement`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Enhance Verification Diagnostic Output [COMPLETED]
dependencies: [1]

**Objective**: Expand verify_file_created() failure output to show expected vs actual paths, directory contents, and actionable troubleshooting steps

**Complexity**: Medium

Tasks:
- [x] Open verification-helpers.sh and locate verify_file_created() function (Lines 73-126)
- [x] Add "Expected vs Actual" comparison section showing both paths
- [x] Add directory listing with file metadata for mismatch cases
- [x] Add troubleshooting commands section (3-4 diagnostic commands)
- [x] Format output for readability (proper indentation, spacing)
- [x] Test enhanced diagnostic with intentional verification failure

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
# Test Phase 3: Enhanced diagnostic output
cd "${CLAUDE_PROJECT_DIR}/.claude/tests"
bash test_verification_diagnostic_enhancement.sh

# Manual diagnostic test
cd "${CLAUDE_PROJECT_DIR}"
source .claude/lib/verification-helpers.sh

# Create test scenario with path mismatch
EXPECTED_PATH="/tmp/test/reports/001_generic.md"
mkdir -p /tmp/test/reports
touch /tmp/test/reports/001_descriptive_name.md

# Trigger verification failure to see enhanced diagnostic
verify_file_created "$EXPECTED_PATH" "Test report" "Test Phase" 2>&1 | head -50

# Expected: Enhanced output shows:
#  - Expected path: 001_generic.md
#  - Found in directory: 001_descriptive_name.md
#  - Troubleshooting steps
#  - Root cause analysis
```

**Expected Duration**: 1.5 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `fix(coordinate): complete Phase 3 - Verification Diagnostic Enhancement`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: [OPTIONAL] Add State Persistence Verification
dependencies: [2]
**STATUS**: DEFERRED - No evidence of state WRITE failures in production

**Objective**: Add defensive verification checkpoint after report path array serialization to ensure state persistence succeeded before proceeding

**Complexity**: Low

**Rationale for Deferral**: Research analysis (002_existing_plan_analysis.md) shows no observed state persistence WRITE failures. All documented failures are READ failures (reconstruction), which Phase 2 fallback discovery addresses. This phase implements defensive checks for unproven failure modes and can be deferred until evidence demonstrates need.

**Implementation Trigger**: If grep shows 3+ state persistence WRITE failures in logs, implement this phase.

Tasks (if implemented):
- [ ] Open coordinate.md and locate state persistence section (Lines 195-202)
- [ ] Add lightweight inline verification after critical state writes only
- [ ] Add fail-fast error handler on verification failure
- [ ] Test verification by temporarily making state file read-only
- [ ] Commit changes with descriptive message

Testing:
```bash
# Test Phase 4: State persistence verification
cd "${CLAUDE_PROJECT_DIR}/.claude/tests"
bash test_state_persistence_verification.sh

# Manual verification test
cd "${CLAUDE_PROJECT_DIR}"
# Temporarily make state file read-only to trigger verification failure
STATE_FILE="${HOME}/.claude/tmp/workflow_test.sh"
echo "export TEST_VAR=value" > "$STATE_FILE"
chmod 444 "$STATE_FILE"  # Read-only

# Attempt to append state (should fail gracefully)
source .claude/lib/state-persistence.sh
append_workflow_state "NEW_VAR" "value" 2>&1

# Restore permissions
chmod 644 "$STATE_FILE"

# Expected: Error output shows state persistence failure with diagnostic
```

**Expected Duration**: 1.5 hours (if implemented)

**Phase 4 Completion Requirements** (if implemented):
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `fix(coordinate): complete Phase 4 - State Persistence Verification`
- [ ] Update this plan file with phase completion status

### Phase 5: Integration Testing and Documentation [COMPLETED]
dependencies: [1, 2, 3]

**Objective**: Validate all fixes work together, run full coordinate test suite, update documentation with fix details

**Complexity**: Medium

Tasks:
- [x] Run complete coordinate test suite: `.claude/tests/test_coordinate_*.sh`
- [x] Execute manual integration test with research-and-plan workflow (2-3 topics)
- [x] Verify verification checkpoint passes with descriptive report filenames
- [x] Confirm REPORT_PATHS array reconstruction returns correct count (fallback works)
- [x] Validate enhanced diagnostic output appears on intentional failure
- [x] Update coordinate-command-guide.md with troubleshooting section for path mismatches
- [x] Document dynamic discovery timing requirement in coordinate.md header comments
- [x] Add fallback type decision matrix section (bootstrap vs verification vs optimization)
- [x] Add entry to CHANGELOG.md describing fixes under "Bug Fixes" section
- [x] Create minimal reproduction test case for regression prevention
- [x] Run final test suite validation: `./run_all_tests.sh`

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
# Test Phase 5: Integration testing
cd "${CLAUDE_PROJECT_DIR}/.claude/tests"
./run_all_tests.sh

# Full integration test
cd "${CLAUDE_PROJECT_DIR}"
/coordinate "Research authentication patterns, OAuth flows, and session management best practices"

# Expected outcomes:
# 1. Research phase completes with 3 topics
# 2. Agents create descriptive filenames (e.g., 001_auth_patterns.md)
# 3. Dynamic discovery executes BEFORE verification
# 4. Verification checkpoint passes for all 3 reports
# 5. REPORT_PATHS array contains actual created paths
# 6. No false-positive verification failures
# 7. Planning phase receives correct report paths

# Verify results
echo "Verification: Check all reports exist"
ls -lh "${TOPIC_PATH}/reports/"

echo "Verification: Check plan references correct report paths"
grep "Research Reports:" "${PLAN_PATH}"
```

**Expected Duration**: 2.0 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `docs(coordinate): complete Phase 5 - Integration Testing and Documentation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- `test_coordinate_verification_ordering.sh` - Verify discovery executes before verification
- `test_reconstruct_report_paths_array_fallback.sh` - Test fallback discovery path
- `test_verification_diagnostic_enhancement.sh` - Validate enhanced error output
- `test_state_persistence_verification.sh` - Verify state serialization checkpoint

### Integration Testing
- Full coordinate workflow test (research-and-plan scope with 2-3 topics)
- Descriptive filename handling test (agents create non-generic names)
- State persistence reliability test (array reconstruction across blocks)
- Verification checkpoint reliability test (zero false positives)

### Regression Testing
- Existing coordinate test suite must continue passing (100% pass rate)
- No performance regression (initialization overhead target: <800ms)
- Backward compatibility maintained (existing workflows unaffected)

### Test Commands
```bash
# Run coordinate-specific tests
cd .claude/tests
bash test_coordinate_verification_ordering.sh
bash test_reconstruct_report_paths_array_fallback.sh
bash test_verification_diagnostic_enhancement.sh
bash test_state_persistence_verification.sh

# Run full test suite
./run_all_tests.sh

# Integration test
cd "${CLAUDE_PROJECT_DIR}"
/coordinate "Research testing best practices and coordinate infrastructure"
# Verify: No verification failures, correct paths in REPORT_PATHS array
```

## Documentation Requirements

### Files to Update
1. **coordinate-command-guide.md**
   - Add troubleshooting section for path mismatch errors
   - Document dynamic discovery timing requirement
   - Add diagnostic interpretation guide

2. **workflow-initialization.sh**
   - Update function documentation for reconstruct_report_paths_array()
   - Document two-phase reconstruction pattern (primary + fallback)
   - Add examples showing fallback behavior

3. **CHANGELOG.md**
   - Add entry under "Bug Fixes" section:
     - Fix verification checkpoint ordering (discovery before verification)
     - Add fallback discovery to report path reconstruction
     - Enhance verification diagnostic output

4. **coordinate.md**
   - Add header comment documenting critical discovery timing
   - Update inline comments explaining verification flow

### Documentation Standards
- Use imperative language (MUST/WILL/SHALL) for requirements
- Include code examples showing correct vs incorrect patterns
- Add troubleshooting decision trees for common errors
- Cross-reference related patterns (bash-block-execution-model.md)

## Dependencies

### External Dependencies
- workflow-initialization.sh (reconstruct_report_paths_array function)
- verification-helpers.sh (verify_file_created function)
- coordinate.md (verification checkpoint and discovery sections)
- state-persistence.sh (append_workflow_state operations)

### Integration Points
- Research agent completion signals (REPORT_CREATED: format)
- Topic path calculation (sanitize_topic_name + get_or_create_topic_number)
- State machine transitions (research → plan transition)
- Error handling infrastructure (handle_state_error)

### Prerequisites
- Bash Block Execution Model understanding (subprocess isolation)
- State persistence patterns (GitHub Actions-style state files)
- Verification checkpoint patterns (fail-fast with diagnostics)
- Dynamic path discovery patterns (glob matching + fallback)

## Risk Analysis

### Technical Risks
1. **Verification timing**: Discovery must execute atomically before verification
   - Mitigation: Add critical comment markers and validation test
2. **Fallback discovery**: Glob pattern must match agent filename conventions
   - Mitigation: Test with various filename patterns, document agent requirements
3. **State persistence**: Append operations must complete before reconstruction
   - Mitigation: Add verification checkpoint after state serialization

### Compatibility Risks
1. **Existing workflows**: Changes should not affect working coordinate invocations
   - Mitigation: Run full regression test suite, validate backward compatibility
2. **Agent behavioral changes**: Research agents may change filename patterns
   - Mitigation: Document expected completion signal format, add validation

### Performance Risks
1. **Filesystem operations**: Adding glob discovery may add latency
   - Mitigation: Fallback only executes when primary reconstruction fails (~1% of cases)
   - Expected overhead: <50ms for glob operation with 4 files

## Completion Checklist

- [ ] Essential phases completed (Phases 1, 2, 3, 5) and marked [COMPLETED]
- [ ] Phase 4 deferred with documented rationale and implementation trigger
- [ ] All unit tests passing (3 new tests created for implemented phases)
- [ ] Integration test passing (full coordinate workflow with descriptive filenames)
- [ ] Regression test suite passing (100% pass rate maintained)
- [ ] Documentation updated (4 files: guide, library, changelog, command)
- [ ] Git commits atomic and descriptive (4 commits for implemented phases)
- [ ] Performance validated (no regression, initialization overhead <800ms)
- [ ] Zero false-positive verification failures observed in testing
- [ ] Fail-fast policy compliance verified (no bootstrap fallbacks, verification fallbacks present)

## Revision History

### Revision 1 - 2025-11-11
- **Date**: 2025-11-11
- **Type**: research-informed (fail-fast policy compliance and complexity reduction)
- **Research Reports Used**:
  - [Fail-Fast Policy Analysis](../../659_658_infrastructure_and_claude_docs_standards/reports/001_fail_fast_policy_analysis.md) - Spec 057 fallback taxonomy and policy compliance
  - [Existing Plan Analysis](../../659_658_infrastructure_and_claude_docs_standards/reports/002_existing_plan_analysis.md) - Complexity assessment and simplification opportunities
- **Key Changes**:
  - Made Phase 4 (State Persistence Verification) optional/deferred - no evidence of state WRITE failures in production
  - Streamlined Phase 1 from 10 tasks to 8 tasks (removed redundant buffer extraction step)
  - Streamlined Phase 2 from 10 tasks to 8 tasks (combined related documentation updates)
  - Streamlined Phase 3 from 10 tasks to 6 tasks (removed over-detailed diagnostic formatting steps)
  - Updated Phase 5 dependencies from [1,2,3,4] to [1,2,3] (removed Phase 4 dependency)
  - Reduced total phases from 5 to 4 essential + 1 optional
  - Reduced total hours from 10.0h to 8.5h (15% reduction)
  - Reduced complexity score from 42.0 to 34.0 (19% reduction)
  - Added fail-fast policy compliance documentation to Research Summary
  - Added Spec 057 verification fallback references to Phase 2
  - Added fallback type decision matrix documentation task to Phase 5
  - Updated completion checklist to reflect 4 essential phases + 1 deferred
- **Rationale**: Research analysis confirmed plan is already fail-fast compliant (NO bootstrap fallbacks, Phase 2 implements REQUIRED verification fallback per Spec 057). Simplification focuses on eliminating over-engineered Phase 4 (addresses unproven failure mode) and streamlining task granularity across all phases. Changes maintain 100% of essential functionality while reducing implementation complexity by 19% and time by 15%.
- **Backup**: /home/benjamin/.config/.claude/specs/658_infrastructure_and_claude_docs_standards_debug/plans/backups/001_coordinate_error_fixes_20251111_114318.md
