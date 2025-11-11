# Plan Archival System Implementation

## Metadata
- **Date**: 2025-11-10
- **Feature**: Automatic plan archival for completed implementations
- **Scope**: Archive completed plans from /implement and /coordinate to specs/{topic}/archived/ with verification, cross-reference updates, and user approval workflow
- **Estimated Phases**: 6
- **Estimated Hours**: 8-12 hours
- **Structure Level**: 0
- **Complexity Score**: 85.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Plan Archival Infrastructure](../reports/001_plan_archival_infrastructure.md)
  - [Archival Standards and Patterns](../reports/002_archival_standards_patterns.md)

## Overview

Implement automated plan archival system that moves completed implementation plans from active `plans/` directories to `archived/` subdirectories after successful implementation. System integrates with /implement Phase 2 and /coordinate complete state, preserving plan structure (Level 0/1/2), updating cross-references, and providing verification checkpoints per Standard 0. User approval workflow handles plans with deferred or skipped items.

**Key Components**:
1. Core archival utility library (plan-archival.sh, 200-300 lines)
2. Integration with /implement Phase 2 (10-15 lines)
3. Integration with /coordinate complete state (15-20 lines)
4. Comprehensive test suite (12 test cases)
5. Documentation updates following timeless writing standards
6. User approval workflow for incomplete plans

## Research Summary

Research findings inform this plan:
- **Infrastructure readiness (95%)**: Completion detection mechanisms exist (checkpoint deletion, summary file, test status), directory structure supports archived/, gitignore patterns compatible, utility functions reusable (cleanup_plan_directory, ensure_artifact_directory), integration points identified (/implement Phase 2, /coordinate complete state)
- **Archiving standards**: Directory Protocols define artifact lifecycle (create → use → complete → archive) but archival stage not implemented, timeless writing standards mandate present-focused documentation without historical markers, lazy directory creation pattern eliminates empty directories
- **File operation patterns**: Rollback utility provides safety backup + verification + rollback pattern, metadata extraction enables 95% context reduction, checkpoint schema v2.0 includes completion status
- **Testing infrastructure**: Existing test patterns (test_checkpoint_utils.sh, test_state_machine.sh) provide framework, 80% coverage requirement, fail-fast verification pattern established

Recommended approach: Implement plan-archival.sh utility library with completion detection, file operations, verification checkpoints, integrate into /implement Phase 2 and /coordinate complete state using existing patterns, add user approval workflow for plans with deferred items, comprehensive testing with 12 test cases covering all plan levels and edge cases.

## Success Criteria
- [ ] Plan archival utility library created (plan-archival.sh) with 6 core functions
- [ ] /implement Phase 2 integration archives plans after summary finalization
- [ ] /coordinate complete state integration archives full-implementation workflows
- [ ] User approval workflow implemented for plans with deferred/skipped items
- [ ] All 12 test cases passing (Level 0/1/2 plans, verification, rollback, discovery)
- [ ] Documentation updated in 3 locations (directory-protocols.md, implement-command-guide.md, new archival guide)
- [ ] Archived plans preserve structure (single files, directories, hierarchies)
- [ ] Cross-references updated in implementation summaries
- [ ] Gitignore compliance verified (archived/ automatically ignored)
- [ ] Zero file corruption (verification checksums pass)
- [ ] README.md auto-generated for archived/ subdirectories

## Technical Design

**Architecture**:
```
.claude/lib/plan-archival.sh (new utility library)
├── is_plan_complete()          # Detect completion via checkpoint + summary
├── has_deferred_items()        # Scan plan for deferred/skipped tasks
├── prompt_user_approval()      # Interactive approval for incomplete work
├── archive_plan()              # Move plan to archived/ with verification
├── verify_archive()            # Post-archival checkpoint (Standard 0)
├── list_archived_plans()       # Discovery function
└── restore_archived_plan()     # Restoration capability
```

**Integration Points**:
1. `/implement` Phase 2: After summary finalization, before checkpoint deletion
2. `/coordinate` Complete state: Terminal state handler for full-implementation workflows
3. Shared utilities: cleanup_plan_directory, ensure_artifact_directory, metadata-extraction.sh

**Directory Structure** (lazy creation):
```
specs/{NNN_topic}/
├── plans/                      # Active plans
├── archived/                   # Completed plans (created on-demand)
│   ├── README.md              # Auto-generated index
│   ├── 001_feature_archived_20251110.md           # Level 0
│   └── 002_enhancement_archived_20251108/         # Level 1
│       ├── 002_enhancement_archived_20251108.md
│       └── phase_3_implementation.md
├── summaries/                  # Implementation summaries
└── debug/                      # Committed reports
```

**Archival Workflow**:
1. Detect completion (all phases done, tests passing, summary exists, checkpoint deleted)
2. Check for deferred items in plan tasks
3. If deferred items: Prompt user approval or skip archival
4. If approved/no deferred items: Create safety backup
5. Move plan to archived/ (preserve Level 0/1/2 structure)
6. Add timestamp suffix: {original_name}_archived_{YYYYMMDD}.md
7. Verify archive integrity (file exists, readable, size >100 bytes)
8. Update summary cross-reference with archived path
9. Generate/update archived/README.md
10. Log operation to archival-operations.log
11. On verification failure: Rollback using safety backup

**Completion Detection Signals** (from research):
- Summary file exists in summaries/ directory
- Checkpoint deleted (no active checkpoint for plan)
- CURRENT_PHASE == TOTAL_PHASES
- tests_passing == true in checkpoint before deletion
- Git commits created for all phases

**Deferred Item Detection**:
- Scan plan tasks for patterns: "deferred", "TODO", "blocked", "not implemented"
- Check for unchecked tasks ([ ]) in phases marked completed
- Identify phases with status "DEFERRED" or "SKIPPED"
- Generate summary of incomplete work for user review

**User Approval Workflow**:
```bash
if has_deferred_items "$PLAN_FILE"; then
  echo "WARNING: Plan has deferred/skipped items:"
  list_deferred_items "$PLAN_FILE"
  read -p "Archive anyway? (y/n): " approval
  [ "$approval" = "y" ] || return 1
fi
```

**Standards Compliance**:
- **Standard 0 (Execution Enforcement)**: Mandatory verification checkpoint before considering archival complete
- **Standard 13 (Project Directory Detection)**: Use detect-project-dir.sh for CLAUDE_PROJECT_DIR
- **Standard 14 (Executable/Documentation Separation)**: Utility library (200-300 lines), command integration (10-15 lines each), comprehensive guide (1,000-1,500 lines)

**Error Handling** (from rollback-command-file.sh pattern):
- Safety backup before move operation
- Checksum verification after archival
- Rollback on verification failure
- Comprehensive logging to .claude/data/logs/archival-operations.log

**Preservation of Plan Structure**:
- Level 0: Archive single .md file
- Level 1: Archive entire directory (main plan + phase files)
- Level 2: Archive entire hierarchy (main plan + phase dirs + stage files)

## Implementation Phases

### Phase 0: Preparation and Validation
dependencies: []

**Objective**: Validate research findings and prepare development environment

**Complexity**: Low

**Tasks**:
- [ ] Verify completion detection mechanisms in checkpoint-utils.sh (functions: restore_checkpoint, delete_checkpoint)
- [ ] Verify cleanup_plan_directory() function in plan-core-bundle.sh (line 1093)
- [ ] Verify ensure_artifact_directory() function in unified-location-detection.sh
- [ ] Confirm gitignore pattern specs/*/* covers archived/ subdirectory
- [ ] Validate /implement Phase 2 integration point (implement.md line 180-216)
- [ ] Validate /coordinate complete state handler (coordinate.md terminal state check)
- [ ] Review rollback-command-file.sh error handling patterns (lines 40-75)
- [ ] Review metadata-extraction.sh for plan metadata extraction (line 89-166)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Validate core utilities exist
test -f .claude/lib/checkpoint-utils.sh || echo "ERROR: checkpoint-utils.sh missing"
test -f .claude/lib/plan-core-bundle.sh || echo "ERROR: plan-core-bundle.sh missing"
test -f .claude/lib/unified-location-detection.sh || echo "ERROR: unified-location-detection.sh missing"

# Test gitignore pattern
mkdir -p test_topic/archived
git check-ignore -v test_topic/archived/test.md  # Should be gitignored
rmdir test_topic/archived && rmdir test_topic
```

**Expected Duration**: 1 hour

**Phase 0 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(650): complete Phase 0 - Preparation and Validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 1: Core Archival Utility Library
dependencies: [0]

**Objective**: Implement plan-archival.sh with 7 core functions

**Complexity**: High

**Tasks**:
- [ ] Create .claude/lib/plan-archival.sh with standard header and project directory detection
- [ ] Implement is_plan_complete() function (file: .claude/lib/plan-archival.sh, ~40 lines)
  - Check summary file exists
  - Verify no active checkpoint
  - Validate summary shows completion status
  - Return 0 if complete, 1 otherwise
- [ ] Implement has_deferred_items() function (~30 lines)
  - Scan plan tasks for deferred patterns (deferred, TODO, blocked, not implemented)
  - Check for unchecked tasks in completed phases
  - Identify phases with DEFERRED/SKIPPED status
  - Return 0 if deferred items exist, 1 otherwise
- [ ] Implement prompt_user_approval() function (~25 lines)
  - Display deferred items summary
  - Prompt user for archival approval
  - Return 0 if approved, 1 if denied
- [ ] Implement archive_plan() function (~80 lines)
  - Create safety backup with timestamp
  - Detect plan structure level (0, 1, or 2)
  - Generate archived filename with date suffix
  - Ensure archived/ directory exists (lazy creation)
  - Move plan file or directory to archived/
  - Verify archive using verify_archive()
  - Update cross-references using update_summary_reference()
  - Generate/update archived/README.md
  - Log operation to archival-operations.log
  - On failure: rollback using safety backup

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Implement verify_archive() function (~30 lines)
  - Check archived file exists
  - Verify file readable
  - Validate file size >100 bytes
  - Return 0 if valid, 1 if verification fails
- [ ] Implement list_archived_plans() function (~40 lines)
  - Find all archived plans in topic directory
  - Extract metadata using metadata-extraction.sh
  - Return JSON array of archived plan metadata
- [ ] Implement restore_archived_plan() function (~50 lines)
  - Create safety backup of archived plan
  - Determine original filename (remove _archived_YYYYMMDD suffix)
  - Move archived plan back to plans/ directory
  - Verify restoration
  - On failure: rollback using safety backup
- [ ] Add comprehensive error handling with rollback pattern from rollback-command-file.sh
- [ ] Add logging to .claude/data/logs/archival-operations.log (log rotation: 10MB max, 5 files)
- [ ] Source detect-project-dir.sh for CLAUDE_PROJECT_DIR compliance (Standard 13)

**Testing**:
```bash
# Source library
source .claude/lib/plan-archival.sh

# Test completion detection
is_plan_complete "test_plan.md" && echo "✓ is_plan_complete"

# Test deferred item detection
has_deferred_items "test_plan_with_deferred.md" && echo "✓ has_deferred_items"

# Test archival (dry-run)
archive_plan "test_plan.md" "test_summary.md" --dry-run

# Test verification
verify_archive "archived/test_plan_archived_20251110.md" && echo "✓ verify_archive"

# Test listing
list_archived_plans "specs/042_auth" | jq '.'

# Test restoration
restore_archived_plan "archived/test_plan_archived_20251110.md" && echo "✓ restore"
```

**Expected Duration**: 3-4 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(650): complete Phase 1 - Core Archival Utility Library`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: /implement Command Integration
dependencies: [1]

**Objective**: Integrate archival into /implement Phase 2 workflow

**Complexity**: Low

**Tasks**:
- [ ] Read /implement command Phase 2 (file: .claude/commands/implement.md, lines 180-216)
- [ ] Identify insertion point (after summary finalization, before checkpoint deletion)
- [ ] Add archival integration code (~15 lines after line 208)
  - Source plan-archival.sh
  - Check if plan complete using is_plan_complete()
  - Check for deferred items using has_deferred_items()
  - If deferred items: prompt user approval
  - If approved or no deferred items: archive_plan()
  - Verify archive using verify_archive()
  - On failure: log warning, continue (non-blocking)
- [ ] Preserve existing Phase 2 logic (summary finalization, checkpoint deletion)
- [ ] Update "CHECKPOINT: Implementation Complete" output to include archive status
- [ ] Add error handling for archival failures (non-blocking, log warnings)

**Testing**:
```bash
# Test /implement integration with completed plan
/implement specs/test_topic/plans/001_test_plan.md

# Expected output:
# - Summary finalized: specs/test_topic/summaries/001_implementation_summary.md
# - CHECKPOINT: Archiving completed plan
# - ✓ Archive verified: specs/test_topic/archived/001_test_plan_archived_20251110.md
# - CHECKPOINT: Implementation Complete

# Test with deferred items (should prompt user)
/implement specs/test_topic/plans/002_plan_with_deferred.md
# Expected: User approval prompt before archival
```

**Expected Duration**: 1 hour

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(650): complete Phase 2 - /implement Command Integration`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: /coordinate Command Integration
dependencies: [1]

**Objective**: Integrate archival into /coordinate complete state handler

**Complexity**: Low

**Tasks**:
- [ ] Read /coordinate command complete state handler (file: .claude/commands/coordinate.md, terminal state check)
- [ ] Identify integration point (when CURRENT_STATE == TERMINAL_STATE and WORKFLOW_SCOPE == "full-implementation")
- [ ] Add archival integration code (~20 lines in complete state handler)
  - Source plan-archival.sh
  - Check if PLAN_PATH is set
  - Check if SUMMARY_PATH is set
  - Verify plan complete using is_plan_complete()
  - Check for deferred items using has_deferred_items()
  - If deferred items: prompt user approval
  - If approved or no deferred items: archive_plan()
  - Verify archive using verify_archive()
  - On failure: log warning, continue (non-blocking)
- [ ] Preserve existing complete state logic (summary display, exit 0)
- [ ] Update workflow summary output to include archive status
- [ ] Add conditional check (only archive for full-implementation workflows, not research-only or research-and-plan)

**Testing**:
```bash
# Test /coordinate with full-implementation workflow
/coordinate "implement authentication feature"

# Expected output:
# - (workflow executes through all states)
# - STATE: complete
# - ✓ Workflow complete at terminal state: complete
# - CHECKPOINT: Archiving completed plan
# - ✓ Archive verified: specs/042_auth/archived/001_auth_archived_20251110.md
# - (workflow summary displayed)

# Test /coordinate with research-only workflow (should NOT archive)
/coordinate "research async patterns" --scope research-only
# Expected: No archival step (terminal state is research, no plan created)
```

**Expected Duration**: 1 hour

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(650): complete Phase 3 - /coordinate Command Integration`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Comprehensive Test Suite
dependencies: [1, 2, 3]

**Objective**: Create test_plan_archival.sh with 12 test cases covering all scenarios

**Complexity**: Medium

**Tasks**:
- [ ] Create .claude/tests/test_plan_archival.sh with test framework setup
- [ ] Implement test_is_plan_complete_detection (verify completion detection via checkpoint + summary)
- [ ] Implement test_has_deferred_items_detection (verify deferred item scanning patterns)
- [ ] Implement test_archive_level_0_plan (archive single-file plan, verify file moved)
- [ ] Implement test_archive_level_1_plan (archive directory plan, verify all files moved)
- [ ] Implement test_archive_level_2_plan (archive hierarchical plan, verify entire tree moved)
- [ ] Implement test_lazy_archived_directory_creation (verify archived/ created on-demand, not eagerly)
- [ ] Implement test_cross_reference_update (verify summary metadata updated with archived path)
- [ ] Implement test_gitignore_compliance (verify archived/ directory is gitignored per specs/*/* pattern)
- [ ] Implement test_verification_checkpoint (verify fail-fast on verification failure)
- [ ] Implement test_rollback_on_failure (verify safety backup restored on archival failure)
- [ ] Implement test_list_archived_plans (verify discovery function returns correct metadata)
- [ ] Implement test_restore_archived_plan (verify restoration moves plan back to plans/ directory)
- [ ] Implement test_archive_readme_generation (verify README.md auto-generated in archived/ subdirectory)
- [ ] Add test_user_approval_workflow (verify prompt displays deferred items and respects user decision)
- [ ] Add setup_test_environment() to create test fixtures (plans, summaries, checkpoints)
- [ ] Add teardown_test_environment() to cleanup test artifacts

**Testing**:
```bash
# Run archival test suite
.claude/tests/test_plan_archival.sh

# Expected output:
# ✓ test_is_plan_complete_detection
# ✓ test_has_deferred_items_detection
# ✓ test_archive_level_0_plan
# ✓ test_archive_level_1_plan
# ✓ test_archive_level_2_plan
# ✓ test_lazy_archived_directory_creation
# ✓ test_cross_reference_update
# ✓ test_gitignore_compliance
# ✓ test_verification_checkpoint
# ✓ test_rollback_on_failure
# ✓ test_list_archived_plans
# ✓ test_restore_archived_plan
# ✓ test_archive_readme_generation
# ✓ test_user_approval_workflow
#
# All 14 tests passed

# Run full test suite (includes archival tests)
.claude/tests/run_all_tests.sh
```

**Expected Duration**: 2-3 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(650): complete Phase 4 - Comprehensive Test Suite`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Documentation Updates
dependencies: [1, 2, 3, 4]

**Objective**: Update documentation following timeless writing standards

**Complexity**: Medium

**Tasks**:
- [ ] Create .claude/docs/guides/plan-archival-guide.md (1,000-1,500 lines, comprehensive guide)
  - Overview section (what archival does, when it happens)
  - Architecture section (utility functions, integration points)
  - Usage examples (manual archival, restoration, listing)
  - Troubleshooting section (common issues, verification failures)
  - Standards compliance section (Standard 0, 13, 14)
  - No temporal markers per writing-standards.md (no "now supports", "previously", "recently")
- [ ] Update .claude/docs/concepts/directory-protocols.md
  - Add archived/ subdirectory to artifact taxonomy (section 2, line 177-297)
  - Document archival lifecycle phase (section 6, line 447-536)
  - Add archival to retention policies table (line 524)
  - Update directory structure examples to include archived/
- [ ] Update .claude/docs/guides/implement-command-guide.md
  - Add archival integration section (Phase 2 workflow)
  - Document user approval workflow for deferred items
  - Add troubleshooting for archival failures
- [ ] Update .claude/docs/guides/coordinate-command-guide.md
  - Add archival integration section (complete state handler)
  - Document conditional archival (only full-implementation workflows)
  - Add troubleshooting for archival failures
- [ ] Update CLAUDE.md (project root)
  - Add archival to Development Workflow section (line 356, after summaries)
  - Add brief archival mention to Quick Reference section (line 387)
- [ ] Review all documentation for timeless writing compliance (no temporal markers, present-focused)
- [ ] Generate archived/README.md template for reuse

**Testing**:
```bash
# Validate documentation exists
test -f .claude/docs/guides/plan-archival-guide.md || echo "ERROR: Archival guide missing"

# Check for temporal markers (should return 0 results)
grep -E "(now supports|previously|recently|used to|migrated to)" .claude/docs/guides/plan-archival-guide.md

# Validate links work
markdown-link-check .claude/docs/guides/plan-archival-guide.md
```

**Expected Duration**: 2-3 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(650): complete Phase 5 - Documentation Updates`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Integration Testing and Validation
dependencies: [1, 2, 3, 4, 5]

**Objective**: Validate end-to-end archival workflow with real plans

**Complexity**: Medium

**Tasks**:
- [ ] Create test plan in specs/test_archival/plans/001_sample_plan.md (5 phases, all tasks completed)
- [ ] Create test summary in specs/test_archival/summaries/001_implementation_summary.md
- [ ] Run /implement on test plan and verify automatic archival
  - Verify archived/ directory created
  - Verify plan moved with timestamp suffix
  - Verify archived/README.md generated
  - Verify summary cross-reference updated
  - Verify archival-operations.log contains entry
- [ ] Create test plan with deferred items specs/test_archival/plans/002_plan_with_deferred.md
- [ ] Run /implement on plan with deferred items and verify user approval prompt
  - Test approval (y): Verify archival proceeds
  - Test denial (n): Verify archival skipped, plan remains in plans/
- [ ] Test /coordinate full-implementation workflow and verify archival
- [ ] Test /coordinate research-only workflow and verify no archival
- [ ] Test archival of Level 1 plan (directory structure)
- [ ] Test restoration of archived plan using restore_archived_plan()
- [ ] Test listing archived plans using list_archived_plans()
- [ ] Test gitignore compliance (verify git status shows archived/ as untracked)
- [ ] Test verification failure scenario (corrupt archived file, verify rollback)
- [ ] Validate all 14 test cases passing in test_plan_archival.sh
- [ ] Run full test suite (.claude/tests/run_all_tests.sh) and verify zero regressions
- [ ] Cleanup test artifacts (specs/test_archival/)

**Testing**:
```bash
# Integration test: /implement with archival
/implement specs/test_archival/plans/001_sample_plan.md
# Expected: Plan archived to specs/test_archival/archived/001_sample_plan_archived_20251110.md

# Integration test: /implement with deferred items
/implement specs/test_archival/plans/002_plan_with_deferred.md
# Expected: User approval prompt, archival based on user response

# Integration test: /coordinate with archival
/coordinate "implement test feature"
# Expected: Plan archived after implementation complete

# Validation test: Full test suite
.claude/tests/run_all_tests.sh
# Expected: All tests passing, including 14 archival tests

# Validation test: Gitignore compliance
git status specs/test_archival/archived/
# Expected: Untracked files (gitignored per specs/*/* pattern)

# Cleanup
rm -rf specs/test_archival/
```

**Expected Duration**: 1-2 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(650): complete Phase 6 - Integration Testing and Validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

**Test Levels**:
1. **Unit Tests** (test_plan_archival.sh): 14 test cases covering all utility functions
2. **Integration Tests** (Phase 6): End-to-end workflow testing with /implement and /coordinate
3. **Edge Case Tests**: Deferred items, verification failures, rollback scenarios, Level 1/2 plans

**Test Commands** (per CLAUDE.md Testing Protocols):
```bash
# Unit tests
.claude/tests/test_plan_archival.sh

# Full test suite (includes archival tests)
.claude/tests/run_all_tests.sh

# Coverage validation (aim for >80% per CLAUDE.md)
# (manual review of function coverage)
```

**Validation Criteria**:
- All 14 unit tests pass
- Zero test failures in full test suite (no regressions)
- Manual integration tests pass (Phases 2, 3, 6)
- Gitignore compliance verified
- Documentation accuracy validated

**Test Fixtures** (setup_test_environment):
- Sample plans (Level 0, 1, 2)
- Sample summaries with completion status
- Sample checkpoints (to be deleted during test)
- Deferred item patterns in test plans

**Cleanup** (teardown_test_environment):
- Remove test topic directories
- Remove test archived/ subdirectories
- Cleanup test checkpoints
- Remove test log entries

## Documentation Requirements

**New Documentation**:
1. `.claude/docs/guides/plan-archival-guide.md` (1,000-1,500 lines)
   - Complete guide to archival system
   - Usage examples and troubleshooting
   - Standards compliance documentation
   - Present-focused writing (no temporal markers)

**Updated Documentation**:
1. `.claude/docs/concepts/directory-protocols.md`
   - Add archived/ to artifact taxonomy
   - Document archival lifecycle phase
   - Update retention policies table

2. `.claude/docs/guides/implement-command-guide.md`
   - Add Phase 2 archival integration section
   - Document user approval workflow
   - Add archival troubleshooting

3. `.claude/docs/guides/coordinate-command-guide.md`
   - Add complete state archival integration
   - Document conditional archival
   - Add archival troubleshooting

4. `CLAUDE.md` (project root)
   - Add archival to Development Workflow section
   - Add brief mention to Quick Reference section

**Auto-Generated Documentation**:
1. `archived/README.md` (template in plan-archival.sh)
   - Generated on first archival in topic
   - Documents archive format, discovery, restoration

**Writing Standards Compliance** (per writing-standards.md):
- Present-focused descriptions (what archival does, not historical context)
- No temporal markers ("now supports", "previously", "recently", "used to")
- No migration language ("migrated to", "replaces the old")
- Timeless documentation (describe current behavior only)

## Dependencies

**External Dependencies**: None (uses existing infrastructure)

**Internal Dependencies**:
1. `.claude/lib/checkpoint-utils.sh` (completion detection)
2. `.claude/lib/plan-core-bundle.sh` (plan structure detection)
3. `.claude/lib/unified-location-detection.sh` (lazy directory creation)
4. `.claude/lib/metadata-extraction.sh` (plan metadata extraction)
5. `.claude/lib/detect-project-dir.sh` (project directory detection)

**Integration Dependencies**:
1. `/implement` command Phase 2 workflow
2. `/coordinate` command complete state handler
3. Checkpoint schema v2.0 (completion status)
4. State machine terminal state transitions

**Testing Dependencies**:
1. Bash test framework (.claude/tests/)
2. Existing test utilities (assert_equals, setup/teardown helpers)

## Notes

**Hint**: This plan has complexity score 85.0. If any phase becomes too complex during implementation (score ≥8 or >10 tasks), consider using `/expand phase <plan-path> <phase-number>` to break it into separate files.

**Research Integration**: This plan implements recommendations from reports 001 (infrastructure analysis) and 002 (archiving standards). Research confirmed 95% infrastructure readiness with completion detection, directory structure, gitignore patterns, and utility functions all prepared for archival implementation.

**User Approval Workflow**: The deferred item detection and approval workflow addresses the gap identified in research report 001, section 5 (no formal deferred item tracking). This provides user control over archival when incomplete work exists.

**Standards Alignment**:
- **Standard 0**: Verification checkpoint after archival (verify_archive function)
- **Standard 13**: Project directory detection via detect-project-dir.sh
- **Standard 14**: Utility library (200-300 lines) + command integration (10-15 lines each)

**Timeless Documentation**: All documentation follows writing-standards.md principles (no temporal markers, present-focused descriptions, no historical commentary).

**Lazy Creation Pattern**: archived/ subdirectory created on-demand (not eagerly) following unified-location-detection.sh pattern.
