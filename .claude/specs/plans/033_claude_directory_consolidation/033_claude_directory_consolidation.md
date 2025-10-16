# .claude/ Directory Consolidation Implementation Plan

## Metadata
- **Date**: 2025-10-07
- **Specs Directory**: /home/benjamin/.config/.claude/specs/
- **Plan Number**: 033
- **Feature**: .claude/ directory consolidation
- **Scope**: Eliminate duplication, consolidate commands, reorganize directories
- **Structure Level**: 1
- **Expanded Phases**: [1, 5]
- **Complexity Score**: 7.8
- **Estimated Phases**: 6
- **Estimated Tasks**: 32
- **Estimated Hours**: 45-60
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [../reports/025_consolidation_opportunities.md](../reports/025_consolidation_opportunities.md)

## Overview

This plan consolidates the .claude/ directory structure to eliminate duplication, simplify command organization, and improve maintainability. Based on comprehensive analysis in Report 025, this consolidation reduces ~4,200 lines of code, merges 8 commands to 3, and reorganizes from 16 to 12 top-level directories.

**Key Principles:**
- Preserve all functionality (zero feature loss)
- Keep unused commands per user preference
- Integrate (not delete) learning system
- Defer template system decision pending evaluation
- Prioritize lib/ over utils/ for shared libraries

## Success Criteria
- [ ] All utilities consolidated into lib/ (utils/ directory removed)
- [ ] Command count reduced from 26 to 20 (6 commands consolidated to 3)
- [ ] Directory count reduced from 16 to 12
- [ ] All existing tests pass after consolidation
- [ ] All command workflows verified functional
- [ ] Documentation updated to reflect new structure

## Technical Design

### Architecture Changes

**Before:**
```
.claude/
├── lib/ (9 files, 2,725 lines)
├── utils/ (16 files, 3,271 lines) ← Duplication!
├── commands/ (26 commands)
├── 16 top-level directories
```

**After:**
```
.claude/
├── lib/ (15 files, ~4,400 lines) ← Consolidated
├── commands/ (20 commands) ← Merged
├── 12 top-level directories ← Reorganized
```

### Consolidation Strategy

**Phase 1:** Utilities layer (lib/ vs utils/)
- Move all utils/ to lib/
- Update references in all commands
- Delete utils/ directory

**Phase 2:** Command consolidation
- Merge list-plans/reports/summaries → /list
- Delete /resume-implement (duplicate)
- Merge update-plan/report → /update
- Merge expand/collapse pairs → /expand and /collapse

**Phase 3:** Directory reorganization
- prompts/ → agents/prompts/
- checkpoints/ + logs/ + metrics/ → data/
- utils/ → lib/ (from Phase 1)

**Phase 4:** Learning system integration
- Add hooks to /implement
- Integrate into /plan and /orchestrate
- Document activation

## Implementation Phases

### Phase 1: Utilities Consolidation (Critical Path)
**Objective**: Eliminate lib/ vs utils/ duplication by consolidating to lib/
**Complexity**: High
**Status**: COMPLETED

**Summary**: Move all utilities from utils/ to lib/, update references in ~25 files, and remove utils/ directory. Consolidates 1,681 lines of duplicate code and establishes lib/ as single source for shared functionality.

**Key Tasks**: Backup, move files (parse-adaptive-plan.sh, analyze-error.sh, learning system), update command references, test all functions, remove utils/

For detailed tasks and implementation, see [Phase 1 Details](phase_1_utilities_consolidation.md)

### Phase 2: List Command Consolidation (Low Risk)
**Objective**: Merge list-plans, list-reports, list-summaries into unified /list command
**Complexity**: Low
**Status**: COMPLETED

Tasks:
- [x] Create .claude/commands/list.md with unified interface (.claude/commands/list-plans.md, list-reports.md, list-summaries.md as templates)
- [x] Implement /list [plans|reports|summaries|all] syntax
- [x] Add --recent N flag for limiting results
- [x] Add --incomplete flag for filtering incomplete plans
- [x] Extract shared metadata logic (number, date, title extraction)
- [x] Test /list plans (verify output matches old /list-plans)
- [x] Test /list reports (verify output matches old /list-reports)
- [x] Test /list summaries (verify output matches old /list-summaries)
- [x] Test /list all (verify combined output)
- [x] Test --recent and --incomplete flags
- [x] Delete old commands (git rm .claude/commands/list-plans.md list-reports.md list-summaries.md)

Testing:
```bash
# Create test artifacts
mkdir -p .claude/specs/{plans,reports,summaries}
touch .claude/specs/plans/{001_test.md,002_test.md}
touch .claude/specs/reports/{001_test.md}

# Test new command
/list plans
/list reports
/list summaries
/list all
/list plans --recent 1
/list plans --incomplete
```

### Phase 3: Resume-Implement Removal (Zero Risk)
**Objective**: Delete /resume-implement (duplicate of /implement auto-resume)
**Complexity**: Low
**Status**: COMPLETED

Tasks:
- [x] Verify /implement has auto-resume feature (.claude/commands/implement.md:4 - check description)
- [x] Grep for references to /resume-implement (should be zero)
- [x] Test /implement without arguments (verify auto-resume works)
- [x] Test /implement resume from incomplete plan
- [x] Delete /resume-implement command (git rm .claude/commands/resume-implement.md)

Testing:
```bash
# Test /implement auto-resume
/implement  # Should detect incomplete plan and resume

# Verify no references
grep -r "resume-implement" .claude/
```

### Phase 4: Update Command Consolidation (Medium Risk)
**Objective**: Merge update-plan and update-report into unified /update command
**Complexity**: Medium
**Status**: COMPLETED

Tasks:
- [x] Analyze update-plan.md and update-report.md for shared logic (.claude/commands/update-plan.md, update-report.md)
- [x] Create .claude/commands/update.md with /update [plan|report] syntax
- [x] Extract shared metadata update logic (date, status fields)
- [x] Extract shared content modification workflow
- [x] Implement plan-specific updates (phase status, task checkboxes)
- [x] Implement report-specific updates (sections, findings)
- [x] Test /update plan (verify metadata and content updates)
- [x] Test /update report (verify section updates)
- [x] Test edge cases (missing files, invalid paths, malformed content)
- [x] Delete old commands (git rm .claude/commands/update-plan.md update-report.md)

Testing:
```bash
# Test plan updates
/update plan .claude/specs/plans/001_test.md "Update reason"

# Test report updates
/update report .claude/specs/reports/001_test.md "Section 1"
```

### Phase 5: Expansion/Collapse Command Consolidation (High Risk)
**Objective**: Merge 4 commands (expand-phase, expand-stage, collapse-phase, collapse-stage) into 2 (/expand, /collapse)
**Complexity**: High
**Status**: COMPLETED

**Summary**: Consolidate 3,565 lines across 4 expansion/collapse commands into 2 unified commands with type parameters. Extract shared logic for structure detection, metadata management, and content migration. Highest-risk phase due to progressive planning system complexity.

**Key Tasks**: Analyze shared logic, create /expand and /collapse with [phase|stage] syntax, extract shared functions, implement all level transitions (0→1, 1→2, reverse), test thoroughly, delete old commands

For detailed tasks and implementation, see [Phase 5 Details](phase_5_expansion_collapse_command_consolidation.md)

### Phase 6: Directory Reorganization (Medium Risk)
**Objective**: Reduce from 16 to 12 top-level directories
**Complexity**: Medium
**Status**: COMPLETED

Tasks:
- [ ] Create agents/prompts/ directory (mkdir -p .claude/agents/prompts)
- [ ] Move prompt templates to agents/prompts/ (git mv .claude/agents/prompts/*.md .claude/agents/prompts/)
- [ ] Remove prompts/ directory (git rmdir .claude/prompts)
- [ ] Update prompt references in commands (grep -r "prompts/" .claude/commands/ and update)
- [ ] Create data/ directory structure (mkdir -p .claude/data/{checkpoints,logs,metrics})
- [ ] Move checkpoints to data/checkpoints/ (git mv .claude/data/checkpoints/* .claude/data/checkpoints/)
- [ ] Move logs to data/logs/ (git mv .claude/data/logs/* .claude/data/logs/)
- [ ] Move metrics to data/metrics/ (git mv .claude/data/metrics/* .claude/data/metrics/)
- [ ] Remove old directories (git rmdir .claude/{checkpoints,logs,metrics})
- [ ] Update checkpoint paths in commands (update lib/checkpoint-utils.sh paths)
- [ ] Update log paths in commands (update lib/adaptive-planning-logger.sh paths)
- [ ] Update metrics paths in commands (grep and update references)
- [ ] Test checkpoint operations with new paths
- [ ] Test logging with new paths
- [ ] Test metrics collection with new paths
- [ ] Verify final directory structure (ls .claude/ should show 12 directories)

Testing:
```bash
# Verify directory structure
ls .claude/ | wc -l  # Should be 12

# Expected structure:
# agents/ commands/ data/ docs/ hooks/ learning/ lib/ specs/ templates/ tests/ tts/ + archive/

# Test checkpoint with new paths
source .claude/lib/checkpoint-utils.sh
save_checkpoint "test" "data"
list_checkpoints

# Test logging with new paths
source .claude/lib/adaptive-planning-logger.sh
log_adaptive_event "test" "test message"
```

## Testing Strategy

### Unit Tests
**Coverage Target**: ≥80% for modified code

Test files to create/update:
- `.claude/tests/test_utilities_consolidation.sh` - Test all lib/ functions
- `.claude/tests/test_list_command.sh` - Test /list command
- `.claude/tests/test_update_command.sh` - Test /update command
- `.claude/tests/test_expand_collapse_commands.sh` - Test /expand and /collapse

### Integration Tests
**Coverage**: End-to-end workflows

Workflows to test:
- `/plan` → `/implement` → `/document` (using consolidated commands)
- `/list plans` → `/update plan` → `/implement` (full planning workflow)
- `/expand phase` → edit → `/collapse phase` (progressive planning)
- `/report` → `/plan` → `/list all` (research workflow)

### Regression Testing
**Coverage**: All existing functionality

Test suite to run:
```bash
cd .claude/tests
./run_all_tests.sh  # All 12 test suites must pass
```

### Performance Testing
**Baseline**: Record before consolidation

Metrics to track:
- Command execution times (before/after)
- Memory usage (lib/ sourcing overhead)
- File operation performance (checkpoint save/load)

## Documentation Requirements

### Files to Update
- [ ] `.claude/README.md` - Update directory structure overview
- [ ] `.claude/commands/README.md` - Update command list (26 → 20)
- [ ] `.claude/lib/README.md` - Document consolidated utilities
- [ ] `CLAUDE.md` - Update command references if needed
- [ ] `.claude/docs/` - Update any command reference guides

### New Documentation
- [ ] `.claude/docs/CONSOLIDATION.md` - Migration guide for users
- [ ] `.claude/docs/COMMAND_REFERENCE.md` - Updated with new command syntax

## Dependencies

### External Dependencies
None - all consolidation is internal to .claude/

### Command Dependencies
- Git (for all file moves and deletions)
- Bash (for all test scripts)
- Grep/Sed (for reference updates)

### Prerequisite Work
1. Create backup branch before starting
2. Ensure all tests pass before consolidation
3. Commit current state to git

## Notes

### Risk Mitigation

**Backup Strategy:**
```bash
git checkout -b consolidation-backup
git add .claude/
git commit -m "Backup before consolidation"
git push origin consolidation-backup
```

**Rollback Plan:**
- All deleted code preserved in git history
- Can revert any phase individually
- archive/ directory for soft deletion

**Phased Approach:**
- Complete each phase fully before next
- Test thoroughly after each phase
- Commit after each successful phase

### User Preferences Preserved
- **Unused commands kept**: /plan-from-template, /plan-wizard remain
- **Learning system integrated**: Not deleted, activated in workflows
- **Template system deferred**: Evaluation pending, not removed

### Post-Consolidation Benefits
- **Code reduction**: ~4,200 lines eliminated
- **Directory reduction**: 16 → 12 (33% reduction)
- **Command reduction**: 26 → 20 (23% reduction)
- **Maintenance**: Fewer files, clearer organization
- **Discoverability**: Easier to find code, logical grouping

### Future Work (Not in This Plan)
- Learning system activation (separate initiative)
- Template system evaluation (separate decision)
- Performance optimization of consolidated commands
- Additional command consolidation opportunities
