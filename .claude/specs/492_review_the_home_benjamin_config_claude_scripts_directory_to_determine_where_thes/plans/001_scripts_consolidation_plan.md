# Scripts Directory Consolidation Implementation Plan

## Metadata
- **Date**: 2025-10-27
- **Feature**: Scripts directory complete elimination
- **Scope**: Remove dashboard scripts (orchestrate deprecation), move validate_context_reduction to lib/, remove scripts/ directory entirely
- **Estimated Phases**: 4
- **Estimated Hours**: 3-4 hours
- **Structure Level**: 0
- **Complexity Score**: 38.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Scripts Inventory and Dependencies](../reports/001_scripts_inventory_and_dependencies.md)
  - [Scripts Usage Patterns](../reports/002_scripts_usage_patterns.md)
  - [Consolidation Opportunities](../reports/003_consolidation_opportunities.md)

## Revision History

### 2025-10-27 - Revision 1
**Changes**:
- Changed goal from partial consolidation to complete scripts/ directory elimination
- Removed archive creation phases (use existing .claude/archive/)
- Removed dashboard preservation (context_metrics_dashboard.sh to be deleted with /orchestrate removal)
- Changed validate_context_reduction.sh from retention to lib/ migration
- Reduced phase count from 5 to 4

**Reason**:
- User confirmed .claude/archive/ already exists
- User will remove /orchestrate command and dashboard utilities
- User wants complete scripts/ directory removal
- validate_context_reduction should move to lib/ for better organization

**Modified Phases**: All phases restructured for elimination strategy

## Overview

The `.claude/scripts/` directory contains 5 operational scripts totaling 1,568 LOC. Research indicates that 3 of these scripts are historical artifacts from completed migrations (specs 056, 074, 079), 1 script is dashboard-related (will be removed with /orchestrate deprecation), and 1 script should be migrated to lib/. This plan **completely eliminates the scripts/ directory** by archiving historical scripts and migrating the validation tool to lib/.

**Goals**:
1. Archive 3 historical migration scripts to existing .claude/archive/
2. Delete context_metrics_dashboard.sh (dashboard functionality deprecated with /orchestrate)
3. Migrate validate_context_reduction.sh to lib/validate-context-reduction.sh
4. Update all documentation references (remove scripts/ directory references)
5. Remove the empty scripts/ directory
6. Validate that no workflows are broken by changes

## Research Summary

Key findings from research reports:

**From Scripts Inventory Report**:
- 5 operational scripts identified with minimal dependencies
- Only migrate_to_topic_structure.sh sources a library (lib/template-integration.sh)
- No problematic duplication between scripts found
- Scripts are standalone executables with CLI interfaces

**From Usage Patterns Report**:
- Zero active integration: No scripts referenced in commands/, agents/, or lib/
- All references are documentation-only (example usage, available tools)
- 4 of 5 scripts are legacy from completed migrations (Oct 18-21, 2025)
- Only validate-readme-counts.sh shows recent activity

**From Consolidation Opportunities Report**:
- context_metrics_dashboard.sh duplicates calculate_context_reduction() from lib/context-metrics.sh (100% overlap)
- Migration scripts (migrate_to_topic_structure.sh, validate_migration.sh) are historical artifacts from completed spec 056
- validate-readme-counts.sh is project-specific with hardcoded paths, created for completed plan 074
- validate_context_reduction.sh is complex (525 LOC) with CLI interface, should be migrated to lib/

**Revised Approach**: Archive historical scripts to existing `.claude/archive/`, delete dashboard script (deprecated with /orchestrate), migrate validate_context_reduction to lib/, completely remove scripts/ directory.

## Success Criteria
- [ ] Historical migration scripts archived to `.claude/archive/scripts/` (using existing archive structure)
- [ ] context_metrics_dashboard.sh and validate-readme-counts.sh deleted (no longer needed)
- [ ] validate_context_reduction.sh migrated to `.claude/lib/validate-context-reduction.sh`
- [ ] All documentation references updated (remove scripts/ directory mentions)
- [ ] scripts/ directory completely removed
- [ ] No broken workflows or references after elimination
- [ ] validate-context-reduction.sh accessible from lib/ with same functionality
- [ ] Git commits follow project standards (atomic, tested)

## Technical Design

### Final Directory Structure
```
.claude/
├── archive/
│   └── scripts/
│       ├── migrate_to_topic_structure.sh (archived)
│       ├── validate_migration.sh (archived)
│       └── validate-readme-counts.sh (archived)
├── lib/
│   ├── context-metrics.sh (unchanged - no dashboard functions needed)
│   └── validate-context-reduction.sh (migrated from scripts/)
└── [scripts/ directory removed entirely]
```

### Validation Tool Migration Design

**Script Migration Strategy**:
- Move `scripts/validate_context_reduction.sh` to `lib/validate-context-reduction.sh`
- Rename follows lib/ naming convention (hyphenated, not underscore)
- Keep existing CLI interface intact (no functional changes)
- Update shebang and sourcing paths if needed
- Script remains executable and directly callable

### Documentation Updates Required
1. `.claude/scripts/README.md` - DELETE (directory being removed)
2. `CLAUDE.md` - Remove any scripts/ directory references
3. `.claude/lib/README.md` - Add validate-context-reduction.sh documentation
4. `.claude/docs/` - Update any references from scripts/ to lib/
5. `.claude/archive/scripts/README.md` - Create if needed to explain archived scripts

## Implementation Phases

### Phase 1: Archive Historical Scripts and Delete Dashboard Scripts [COMPLETED]
dependencies: []

**Objective**: Archive migration scripts, delete deprecated dashboard scripts

**Complexity**: Low

**Tasks**:
- [x] Verify `.claude/archive/scripts/` directory exists (should already exist per user)
- [x] Use `git mv` to move `scripts/migrate_to_topic_structure.sh` to `archive/scripts/`
- [x] Use `git mv` to move `scripts/validate_migration.sh` to `archive/scripts/`
- [x] Use `git mv` to move `scripts/validate-readme-counts.sh` to `archive/scripts/`
- [x] Delete `scripts/context_metrics_dashboard.sh` (deprecated with /orchestrate removal):
  - Use `git rm scripts/context_metrics_dashboard.sh`
  - Dashboard functionality no longer needed
- [x] Create/update `.claude/archive/scripts/README.md` if needed to document archived scripts
- [x] Search codebase for references to archived/deleted scripts using Grep tool:
  - Pattern: `scripts/(migrate_to_topic_structure|validate_migration|validate-readme-counts|context_metrics_dashboard)\.sh`
  - Update any found references or mark as historical

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Verify scripts archived
test -f .claude/archive/scripts/migrate_to_topic_structure.sh && echo "✓ migrate_to_topic_structure.sh archived"
test -f .claude/archive/scripts/validate_migration.sh && echo "✓ validate_migration.sh archived"
test -f .claude/archive/scripts/validate-readme-counts.sh && echo "✓ validate-readme-counts.sh archived"

# Verify dashboard script deleted
test ! -f .claude/scripts/context_metrics_dashboard.sh && echo "✓ context_metrics_dashboard.sh deleted"

# Verify scripts removed from scripts/ directory
test ! -f .claude/scripts/migrate_to_topic_structure.sh && echo "✓ Removed from scripts/"
test ! -f .claude/scripts/validate_migration.sh && echo "✓ Removed from scripts/"
test ! -f .claude/scripts/validate-readme-counts.sh && echo "✓ Removed from scripts/"

# Verify only validate_context_reduction.sh remains
REMAINING_SCRIPTS=$(find .claude/scripts -maxdepth 1 -name "*.sh" -type f | wc -l)
test "$REMAINING_SCRIPTS" -eq 1 && echo "✓ Only 1 script remains in scripts/"
```

**Expected Duration**: 30 minutes

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(492): complete Phase 1 - Archive and Delete Scripts`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 2: Migrate Validation Script to lib/ [COMPLETED]
dependencies: [1]

**Objective**: Move validate_context_reduction.sh to lib/ directory

**Complexity**: Low

**Tasks**:
- [x] Use `git mv` to move `scripts/validate_context_reduction.sh` to `lib/validate-context-reduction.sh`
  - Note: Rename uses hyphen (lib/ convention) instead of underscore
- [x] Update script's internal source paths if it references other lib/ files:
  - Check for relative paths like `../lib/` that may need adjustment
  - Update to use `"${BASH_SOURCE%/*}/"` for reliable path resolution
- [x] Verify script remains executable after move: `chmod +x lib/validate-context-reduction.sh`
- [x] Test script functionality from lib/ location:
  - Run `lib/validate-context-reduction.sh --help`
  - Verify CLI interface unchanged
  - Check that all sourced libraries resolve correctly
- [x] Search codebase for references to old script path:
  - Pattern: `scripts/validate_context_reduction\.sh`
  - Update references to `lib/validate-context-reduction.sh`

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Verify script migrated
test -f .claude/lib/validate-context-reduction.sh && echo "✓ validate-context-reduction.sh in lib/"
test ! -f .claude/scripts/validate_context_reduction.sh && echo "✓ Removed from scripts/"

# Verify executable permissions
test -x .claude/lib/validate-context-reduction.sh && echo "✓ Script is executable"

# Test script functionality
.claude/lib/validate-context-reduction.sh --help > /dev/null 2>&1
test $? -eq 0 && echo "✓ Script runs successfully"

# Verify scripts/ directory is now empty
REMAINING_SCRIPTS=$(find .claude/scripts -maxdepth 1 -name "*.sh" -type f 2>/dev/null | wc -l)
test "$REMAINING_SCRIPTS" -eq 0 && echo "✓ scripts/ directory empty"
```

**Expected Duration**: 30 minutes

**Phase 2 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(492): complete Phase 2 - Migrate Validation Script to lib/`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 3: Update Documentation and Remove scripts/ Directory [COMPLETED]
dependencies: [2]

**Objective**: Update all documentation to reflect elimination of scripts/ directory

**Complexity**: Low

**Tasks**:
- [x] Delete `.claude/scripts/README.md` (directory being removed):
  - Use `git rm .claude/scripts/README.md`
- [x] Update `.claude/lib/README.md`:
  - Add validate-context-reduction.sh to module documentation:
    - `validate-context-reduction.sh` - Context reduction validation suite with CLI interface
    - Document parameters: --help, --verbose, etc.
    - Note: Migrated from deprecated scripts/ directory
- [x] Search for scripts/ directory references in documentation:
  - Use Grep with pattern: `\.claude/scripts/` or `scripts/`
  - Check: CLAUDE.md, docs/, specs/
  - Update references to lib/ or mark as historical/deprecated
- [x] Update CLAUDE.md if it mentions scripts/ directory:
  - Remove any "Scripts Directory" sections
  - Update utility references to point to lib/ only
- [x] Remove empty `.claude/scripts/` directory:
  - Verify directory is empty: `ls -la .claude/scripts/`
  - Remove with: `rmdir .claude/scripts/` (will fail if not empty - good safety check)
  - Use `git rm -r .claude/scripts/` if directory tracked by git
- [x] Create/update `.claude/archive/scripts/README.md` to document archived scripts

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Verify scripts/README.md deleted
test ! -f .claude/scripts/README.md && echo "✓ scripts/README.md deleted"

# Verify lib/README.md updated
grep -q "validate-context-reduction" .claude/lib/README.md && echo "✓ Validation script documented in lib/README.md"

# Verify scripts/ directory removed
test ! -d .claude/scripts && echo "✓ scripts/ directory removed"

# Verify no dangling references to scripts/ in documentation
! grep -r "\.claude/scripts/" .claude/docs/ .claude/CLAUDE.md 2>/dev/null && echo "✓ No scripts/ references in docs"

# Verify archive README exists
test -f .claude/archive/scripts/README.md && echo "✓ Archive README exists"
```

**Expected Duration**: 1 hour

**Phase 3 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(492): complete Phase 3 - Update Documentation and Remove scripts/`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 4: Validation and Integration Testing
dependencies: [3]

**Objective**: Verify complete elimination of scripts/ directory and no broken workflows

**Complexity**: Low

**Tasks**:
- [ ] Run comprehensive validation checks:
  - Verify scripts/ directory no longer exists
  - Verify 3 scripts archived in .claude/archive/scripts/
  - Verify validate-context-reduction.sh works from lib/ location
  - Verify 1 script deleted (context_metrics_dashboard.sh)
- [ ] Test validate-context-reduction.sh end-to-end:
  - Run `lib/validate-context-reduction.sh --verbose`
  - Verify it sources lib/context-metrics.sh correctly
  - Check validation output shows expected test results
- [ ] Search codebase for any remaining scripts/ references:
  - Use Grep with pattern: `scripts/.*\.sh`
  - Verify all matches are either in archive/ or historical documentation
  - No broken references should exist in commands/, agents/, lib/
- [ ] Verify all git commits follow standards:
  - Format: `feat(492): complete Phase N - Description`
  - Atomic commits with clear messages
- [ ] Verify git status shows clean working tree
- [ ] Test that no workflows are broken:
  - Run any test suites that reference validation tools
  - Check that lib/ utilities source correctly
  - Verify no broken links in documentation

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Verify scripts/ directory eliminated
test ! -d .claude/scripts && echo "✓ scripts/ directory removed"

# Verify archived scripts count
ARCHIVED_COUNT=$(find .claude/archive/scripts -maxdepth 1 -name "*.sh" -type f 2>/dev/null | wc -l)
test "$ARCHIVED_COUNT" -eq 3 && echo "✓ Exactly 3 scripts archived"

# Test validate-context-reduction.sh from lib/
.claude/lib/validate-context-reduction.sh --help > /dev/null 2>&1
test $? -eq 0 && echo "✓ validate-context-reduction.sh works from lib/"

# Verify no broken references in active codebase
! grep -r "scripts/.*\.sh" .claude/commands/ .claude/agents/ .claude/lib/ 2>/dev/null && echo "✓ No broken script references"

# Verify git commits
git log --oneline -4 | grep -q "feat(492)" && echo "✓ Git commits follow standards"

# Verify clean working tree
test -z "$(git status --porcelain)" && echo "✓ Clean working tree" || echo "⚠ Uncommitted changes"
```

**Expected Duration**: 45 minutes

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(492): complete Phase 4 - Validation and Integration Testing`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- Script archival using git mv (Phase 1)
- Dashboard script deletion (Phase 1)
- Validation script migration to lib/ (Phase 2)
- Documentation updates (Phase 3)

### Integration Testing
- validate-context-reduction.sh sources lib/context-metrics.sh correctly (Phase 2)
- All documentation links valid after scripts/ removal (Phase 3)
- No broken references after directory elimination (Phase 4)

### End-to-End Testing
- Complete workflow: archive → migrate → document → validate (Phase 4)
- No broken references in commands, agents, or lib (Phase 4)
- Validation tool functions correctly from lib/ (Phase 4)

### Regression Testing
- Verify validate-context-reduction.sh behavior unchanged after migration (Phase 2, 4)
- Verify no workflows broken by scripts/ directory removal (Phase 4)

## Documentation Requirements

### Files to Delete
1. `.claude/scripts/README.md` - DELETE (directory being removed)

### Files to Update
1. `.claude/lib/README.md` - Add validate-context-reduction.sh documentation
2. `CLAUDE.md` - Remove scripts/ directory references (if any)
3. `.claude/docs/` files - Update scripts/ references to lib/
4. `.claude/archive/scripts/README.md` - Create/update to document archived scripts

### Documentation Standards
- Follow CLAUDE.md documentation policy (clear, concise, no emojis)
- Document validate-context-reduction.sh parameters and usage in lib/README.md
- Explain why scripts archived (historical reference only)
- Note dashboard script removal (deprecated with /orchestrate)

## Dependencies

### External Dependencies
- None (all operations use standard bash, git commands)

### Library Dependencies
- `lib/context-metrics.sh` (unchanged - validate-context-reduction.sh depends on it)

### File Dependencies
- `.claude/scripts/migrate_to_topic_structure.sh` (archived in Phase 1)
- `.claude/scripts/validate_migration.sh` (archived in Phase 1)
- `.claude/scripts/validate-readme-counts.sh` (archived in Phase 1)
- `.claude/scripts/context_metrics_dashboard.sh` (deleted in Phase 1)
- `.claude/scripts/validate_context_reduction.sh` (migrated to lib/ in Phase 2)

### Git Dependencies
- Use `git mv` for tracking file moves (preserves history)
- Use `git rm` for file deletion (tracked removal)
- Atomic commits per phase for easy rollback

## Rollback Plan

### Phase-by-Phase Rollback
- **Phase 1**: Restore archived scripts with `git mv archive/scripts/*.sh scripts/`; restore deleted dashboard script from git history
- **Phase 2**: Restore validate_context_reduction.sh with `git mv lib/validate-context-reduction.sh scripts/validate_context_reduction.sh`
- **Phase 3**: Restore scripts/README.md from git history, revert documentation changes
- **Phase 4**: No rollback needed (validation only)

### Emergency Rollback
If critical issues discovered:
```bash
# Revert all commits from this plan (4 phase commits)
git revert HEAD~4..HEAD

# Or reset to before implementation (loses commits)
git reset --hard <commit-before-plan-492>

# Restore scripts/ directory structure
mkdir -p .claude/scripts
git checkout HEAD~4 -- .claude/scripts/
```

## Risk Assessment

### Low Risk
- Script archival (Phase 1) - uses git mv (safe, preserves history)
- Validation script migration (Phase 2) - single file move with testing
- Documentation updates (Phase 3) - easily reverted
- Validation testing (Phase 4) - read-only operations

### Medium Risk
- Dashboard script deletion (Phase 1) - permanent removal (but deprecated functionality)
- scripts/ directory removal (Phase 3) - eliminates entire directory structure

### Mitigation Strategies
- Use git mv/rm for all operations (preserves history, enables rollback)
- Test validate-context-reduction.sh thoroughly after migration (Phase 2)
- Search comprehensively for broken references before directory removal (Phase 3)
- Run validation checks before each commit (all phases)
- Keep atomic commits for easy revert (all phases)
- Dashboard script deletion acceptable (functionality deprecated with /orchestrate removal)

## Notes
- Complexity score (revised): (14 tasks × 1.0) + (4 phases × 5.0) + (3.5 hours × 0.5) + (3 dependencies × 2.0) = 14 + 20 + 1.75 + 6 = **41.75**
- Reduced from original 50.75 due to elimination strategy (simpler than preservation)
- All phases have clear testing requirements following CLAUDE.md Testing Protocols
- Phase dependencies are sequential (1→2→3→4) for safe directory elimination
- Dashboard script deletion justified by /orchestrate command deprecation
- Complete scripts/ directory removal achieves user's goal of reducing .claude/ subdirectories
