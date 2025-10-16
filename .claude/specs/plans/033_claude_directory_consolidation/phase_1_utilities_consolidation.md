# Phase 1: Utilities Consolidation (Critical Path)

## Metadata
- **Phase Number**: 1
- **Parent Plan**: 033_claude_directory_consolidation.md
- **Objective**: Eliminate lib/ vs utils/ duplication by consolidating to lib/
- **Complexity**: High
- **Status**: COMPLETED

## Overview

This phase consolidates all utilities from utils/ to lib/, eliminating duplication and establishing lib/ as the single source of truth for shared libraries. This is the critical path phase that must succeed for all subsequent phases.

**Impact:**
- Moves 16 files from utils/ to lib/
- Eliminates 1,681 lines of duplicate code
- Updates references in ~25 files across commands and lib/
- Establishes clear architecture (lib/ for all shared code)

## Tasks

### Backup and Preparation
- [x] Backup current state (create git branch `consolidation-backup`)

### Core File Migrations
- [x] Move parse-adaptive-plan.sh from utils/ to lib/ (.claude/utils/parse-adaptive-plan.sh:1-1298)
- [x] Merge analyze-error.sh logic into lib/error-utils.sh (.claude/utils/analyze-error.sh:1-196 → .claude/lib/error-utils.sh)

### Remove Redundant Files
- [x] Delete redundant checkpoint scripts (.claude/utils/save-checkpoint.sh, load-checkpoint.sh, list-checkpoints.sh, cleanup-checkpoints.sh)
- [x] Delete analyze-phase-complexity.sh (lib/complexity-utils.sh wraps it)

### Move Learning System Files
- [x] Move remaining utils/*.sh to lib/ (collect-learning-data.sh, match-similar-workflows.sh, generate-recommendations.sh)

### Update References
- [x] Update all commands: change utils/ sourcing to lib/ sourcing (grep -r "utils/" .claude/commands/)
- [x] Update lib/ cross-references (lib/progressive-planning-utils.sh:10-12 sources utils/parse-adaptive-plan.sh)

### Testing and Validation
- [x] Test checkpoint functionality (save, load, list, cleanup via lib/checkpoint-utils.sh)
- [x] Test error handling (all error detection and recovery functions)
- [x] Test complexity analysis (verify lib/complexity-utils.sh still works)

### Cleanup
- [x] Remove utils/ directory (git rm -r .claude/utils/)

## Testing

### Checkpoint Operations
```bash
# Verify checkpoint operations
source .claude/lib/checkpoint-utils.sh
save_checkpoint "test" "test data"
load_checkpoint "test"
list_checkpoints
cleanup_checkpoints 1
```

**Expected:** All checkpoint operations succeed with no errors.

### Error Handling
```bash
# Verify error handling
source .claude/lib/error-utils.sh
detect_error_type "test error message"
suggest_recovery "test error"
```

**Expected:** Error detection and recovery functions work correctly.

### Complexity Analysis
```bash
# Verify complexity analysis
source .claude/lib/complexity-utils.sh
calculate_complexity 10 5 20 3
```

**Expected:** Complexity calculation returns valid score.

## Expected Outcomes

After completing this phase:
- [ ] All utilities consolidated in lib/ (15 files, ~4,400 lines)
- [ ] utils/ directory removed
- [ ] All commands reference lib/ for shared functionality
- [ ] No cross-dependencies between lib/ files and non-existent utils/
- [ ] All tests pass
- [ ] Clean git history with backup branch available

## Dependencies

**Blocks:**
- Phase 2: List Command Consolidation (needs lib/ structure in place)
- Phase 6: Directory Reorganization (needs utils/ removed)

**Required Before:**
- None (this is the foundation phase)

## Risk Mitigation

**Backup Strategy:**
- Git branch `consolidation-backup` created before any changes
- All deleted code preserved in git history

**Testing Strategy:**
- Test each core function (checkpoint, error, complexity) after migration
- Verify all command references before deleting utils/

**Rollback Plan:**
- Revert to `consolidation-backup` branch if critical issues arise
- Each file move is reversible

## Notes

- This phase touches the most files (~25) and has highest impact on system
- parse-adaptive-plan.sh (1,298 lines) is the largest file being moved
- Learning system files (collect-learning-data.sh, match-similar-workflows.sh, generate-recommendations.sh) moved but not integrated yet
- Cross-sourcing issue (lib/ sourcing from utils/) will be resolved by moving parse-adaptive-plan.sh

## Update Reminder

**When this phase is complete:**
1. Mark all tasks above as [x]
2. Update phase status to: `**Status**: COMPLETED`
3. Mark Phase 1 as [COMPLETED] in main plan: `033_claude_directory_consolidation.md`
4. Create git commit for phase completion
