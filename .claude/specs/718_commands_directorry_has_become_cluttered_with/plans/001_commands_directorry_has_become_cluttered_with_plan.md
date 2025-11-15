# Commands Directory Cleanup Implementation Plan

## Metadata
- **Date**: 2025-11-15
- **Feature**: Commands Directory Cleanup and Rationalization
- **Scope**: Remove clutter (backups, redundant commands) via clean-break approach
- **Estimated Phases**: 4
- **Estimated Hours**: 4-6 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 52.0 (Medium)
- **Research Reports**:
  - [Rarely-Used Commands Analysis](../reports/001_topic1.md)
  - [Cleanup Prioritization Framework](../reports/002_topic2.md)

## Revision History

### 2025-11-15 - Revision 1
**Changes**: Adopted clean-break approach, removed deprecation/migration complexity, added explicit command removal/retention lists
**Reason**: User prefers immediate removal over gradual deprecation. Simplifies implementation and aligns with project's clean-break philosophy.
**Modified Phases**: Removed Phase 4 (Orchestrator Deprecation), simplified all phases, reduced from 6 to 4 phases
**Key Additions**: Added "Commands to Remove" and "Commands to Keep" sections with explicit approval checkboxes

## Overview

The `.claude/commands/` directory has accumulated significant clutter with 23 backup files and redundant commands that create navigation overhead. Following the project's clean-break philosophy (CLAUDE.md development philosophy), this plan immediately removes backup files and redundant commands without deprecation periods or migration guides. Git history provides complete recovery for any accidentally removed files.

## Commands Inventory and Removal Plan

### Commands to Remove (User Approval Required)

**Backup Files (23 files)** ✅ APPROVED
- [x] All `*.backup*` files in `.claude/commands/`
- [x] All `*.bak` files
- **Rationale**: 100% redundancy with git history, zero functional value
- **Recovery**: `git log --all -- .claude/commands/<filename>`
- **Disk Impact**: 1.4M reclaimed

**Redundant Orchestrators (2 commands)** ✅ APPROVED
- [x] `/orchestrate` - 85% overlap with `/coordinate`, superseded by production-ready replacement
- [x] `/supervise` - 90% overlap with `/coordinate`, reference implementation only
- **Rationale**: `/coordinate` is production-ready with 48.9% code reduction, 67% performance improvement, 164 commits vs 54/95
- **Recovery**: Git tag before removal enables restoration if needed

### Commands to Keep (Core Functionality)

**Primary Workflow Commands (7)**
- [x] `/coordinate` - Production orchestrator (keep - primary workflow tool)
- [x] `/implement` - Plan execution (keep - core functionality)
- [x] `/plan` - Plan creation (keep - core functionality)
- [x] `/research` - Research generation (keep - core functionality)
- [x] `/debug` - Debugging workflow (keep - core functionality)
- [x] `/revise` - Plan revision (keep - core functionality)
- [x] `/document` - Documentation updates (keep - core functionality)

**Structural Utilities (4)**
- [x] `/expand` - Phase/stage expansion (keep - unique functionality)
- [x] `/collapse` - Phase/stage collapse (keep - counterpart to expand)
- [x] `/list` - Artifact discovery (keep - 88% context reduction optimization)
- [x] `/analyze` - Performance metrics (keep - agent performance tracking)

**Planning Interfaces (2)**
- [x] `/plan-from-template` - Template-based planning (keep - 60-80% faster for common patterns)
- [x] `/plan-wizard` - Guided planning (keep pending usage review - may consolidate later)

**Testing Commands (2)**
- [x] `/test` - Targeted testing (keep - core development tool)
- [x] `/test-all` - Comprehensive testing (keep - CI/CD integration)

**Refactoring (1)**
- [x] `/refactor` - Code quality analysis (keep - pre-feature refactoring)

**Setup/Utilities (2)**
- [x] `/setup` - Project configuration (keep - critical utility)
- [x] `/optimize-claude` - CLAUDE.md optimization (keep pending usage review)

## Research Summary

Research reveals immediate removal candidates without migration complexity:
- **Backup files**: 23 files consuming 1,556 disk units, creating 56% navigation overhead (50 files vs 22 active commands)
- **Redundant orchestrators**: `/orchestrate` and `/supervise` both superseded by `/coordinate` (production-ready, 164 commits vs 54/95)
- **Git recovery**: All deleted files recoverable via git history (zero risk of data loss)

Key insight: Project's clean-break philosophy eliminates need for deprecation warnings, migration guides, or transition periods. Direct removal aligns with existing development practices.

## Success Criteria
- [ ] User approves removal lists above (backup files + redundant orchestrators)
- [ ] All 23 backup files removed from `.claude/commands/` directory
- [ ] `/orchestrate` and `/supervise` removed completely
- [ ] Disk space reclaimed (1,556 units from backups)
- [ ] Directory listing reduced from 50 to 25-27 entries (50-54% reduction)
- [ ] Anti-backup policy established (.gitignore + pre-commit hook)
- [ ] Documentation updated to remove references to deleted commands
- [ ] All tests passing after cleanup
- [ ] Git recovery documentation added

## Technical Design

### Architecture Decisions

**1. Clean-Break Removal Strategy**
- Direct file deletion without deprecation period
- Aligns with project's clean-break philosophy (CLAUDE.md development philosophy section)
- Git version control provides complete recovery mechanism
- Pre-commit hook prevents future backup file creation

**2. Backup Removal**
- Git version control provides complete recovery mechanism
- `.gitignore` + pre-commit hook prevents future backup proliferation
- Recovery documentation ensures no knowledge loss

**3. Documentation Updates**
- Remove all references to deleted commands (README.md, command-reference.md, CLAUDE.md)
- Update to reflect `/coordinate` as sole production orchestrator
- No migration guides needed (clean break)

### Component Interactions

```
┌─────────────────────────────────────────────────────────────┐
│                   Cleanup Workflow                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Phase 1: User Approval Checklist                          │
│  ┌───────────────────────────────────────────────┐         │
│  │ Present removal lists → User approves tiers   │         │
│  │ Output: Approved removal plan                 │         │
│  └───────────────────────────────────────────────┘         │
│                        ↓                                    │
│  Phase 2: File Removal (Backup + Commands)                 │
│  ┌───────────────────────────────────────────────┐         │
│  │ Git tag → rm backups → rm commands → Verify   │         │
│  │ Expected: 25 files removed total              │         │
│  └───────────────────────────────────────────────┘         │
│                        ↓                                    │
│  Phase 3: Anti-Backup Policy + Documentation               │
│  ┌───────────────────────────────────────────────┐         │
│  │ .gitignore → Pre-commit Hook → Docs Update    │         │
│  │ Git Recovery Guide                            │         │
│  └───────────────────────────────────────────────┘         │
│                        ↓                                    │
│  Phase 4: Validation & Testing                             │
│  ┌───────────────────────────────────────────────┐         │
│  │ Test Suite → Verify Removal → Metrics         │         │
│  │ Documentation Validation                       │         │
│  └───────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Phases

### Phase 1: User Approval and Inventory
dependencies: []

**Objective**: Present explicit removal lists for user approval, inventory current state

**Complexity**: Low

Tasks:
- [x] List all backup files for user review
  - [x] Run: `find /home/benjamin/.config/.claude/commands/ -name "*.backup*" -o -name "*.bak" -o -name "*~" | sort`
  - [x] Count: `find /home/benjamin/.config/.claude/commands/ -name "*.backup*" -o -name "*.bak" | wc -l` (actual: 23)
  - [x] Disk usage: 1.4M total for backup files
- [x] Verify orchestrator files exist
  - [x] Check: `/home/benjamin/.config/.claude/commands/orchestrate.md` (exists, 18.6KB)
  - [x] Check: `/home/benjamin/.config/.claude/commands/supervise.md` (exists, 10.5KB)
- [x] Present removal lists to user (see "Commands to Remove" section above)
- [x] Wait for explicit user approval before proceeding
- [x] Document current directory state
  - [x] File count: 52 files total
  - [x] Disk usage: 2.2M total directory size

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] User has reviewed and approved removal lists
- [x] Current state documented for comparison
- [x] Git commit created: `feat(718): complete Phase 1 - User Approval and Inventory`
- [x] Update this plan file with phase completion status

### Phase 1 [COMPLETED]

### Phase 2: Clean-Break Removal
dependencies: [1]

**Objective**: Remove all approved backup files and redundant commands immediately

**Complexity**: Low

Tasks:
- [x] Create git safety tag: `git tag cleanup/pre-removal-$(date +%Y%m%d)` ✅
- [x] Remove backup files
  - [x] Run: `cd /home/benjamin/.config/.claude/commands && rm -f *.backup* *.bak *~` ✅
  - [x] Verify removal: 0 backup files found ✅
- [x] Remove redundant orchestrator commands
  - [x] Remove: orchestrate.md ✅
  - [x] Remove: supervise.md ✅
  - [x] Verify removal: Both files not found (successfully deleted) ✅
- [x] Verify git recovery works
  - [x] Test view deleted file: Successfully viewed orchestrate.md from HEAD~1 ✅
  - [x] Test log deleted file: Git log accessible ✅
- [x] Verify directory improvement
  - [x] After count: 27 files (down from 52) ✅
  - [x] After disk usage: 640K (down from 2.2M - 71% disk space reclaimed!) ✅
  - [x] Calculate reduction: 48.1% file count reduction (25 files removed) ✅

**Phase 2 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] All approved files removed (25 total - actual results)
- [x] Git recovery verified working
- [x] Directory reduced by 48.1% (exceeds expectations with 71% disk space reclaimed)
- [x] Git commit created: `feat(718): complete Phase 2 - Clean-Break Removal`
- [x] Update this plan file with phase completion status

### Phase 2 [COMPLETED]

### Phase 3: Prevention and Documentation
dependencies: [2]

**Objective**: Prevent future clutter and update documentation for removed commands

**Complexity**: Medium

Tasks:
- [ ] Create anti-backup policy
  - [ ] Create `.gitignore` in commands directory: `/home/benjamin/.config/.claude/commands/.gitignore`
  - [ ] Add patterns: `*.backup*`, `*.bak`, `*.phase-based*`, `*~`
  - [ ] Add comment: "All version history managed via git - no backup files allowed"
  - [ ] Create pre-commit hook: `/home/benjamin/.config/.git/hooks/pre-commit`
  - [ ] Hook logic: Detect and reject backup file commits
  - [ ] Make executable: `chmod +x .git/hooks/pre-commit`
  - [ ] Test hook: `touch .claude/commands/test.backup && git add . && git commit -m "test"` (should fail)
  - [ ] Cleanup: `rm .claude/commands/test.backup`
- [ ] Create git recovery guide: `/home/benjamin/.config/.claude/docs/guides/git-recovery-guide.md`
  - [ ] Examples: viewing historical versions (`git show`)
  - [ ] Examples: restoring deleted files (`git checkout <commit> -- <file>`)
  - [ ] Examples: comparing versions (`git diff`)
  - [ ] Link from CLAUDE.md quick reference
- [ ] Update documentation to remove orchestrate/supervise references
  - [ ] README.md: Remove orchestrate/supervise from orchestration section
  - [ ] README.md: Promote /coordinate as sole orchestrator
  - [ ] command-reference.md: Remove orchestrate/supervise entries
  - [ ] CLAUDE.md project_commands section: Remove legacy orchestrator note
  - [ ] Search specs: `grep -rl "/orchestrate\|/supervise" .claude/specs/ | head -20`
  - [ ] Add note to recent specs: "Note: /orchestrate and /supervise removed, use /coordinate"
- [ ] Update command-development-guide.md
  - [ ] Add anti-backup policy section
  - [ ] Reference git recovery guide
  - [ ] Document pre-commit hook behavior

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Anti-backup policy active and tested
- [ ] Documentation fully updated
- [ ] Git recovery guide created
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(718): complete Phase 3 - Prevention and Documentation`
- [ ] Update this plan file with phase completion status

### Phase 4: Validation and Metrics
dependencies: [2, 3]

**Objective**: Validate all changes, measure cleanup impact, verify no regressions

**Complexity**: Low

Tasks:
- [ ] Run full test suite
  - [ ] Execute: `/test-all` or test suite per CLAUDE.md protocols
  - [ ] Verify no regressions from cleanup
  - [ ] Fix any failures
- [ ] Verify cleanup metrics
  - [ ] Final file count: `ls /home/benjamin/.config/.claude/commands/ | wc -l`
  - [ ] Final disk usage: `du -sh /home/benjamin/.config/.claude/commands/`
  - [ ] Files removed: 25 (23 backups + 2 commands)
  - [ ] Reduction percentage: ~50%
- [ ] Verify git recovery end-to-end
  - [ ] Pick removed file: orchestrate.md
  - [ ] Find deletion commit: `git log --all --diff-filter=D -- .claude/commands/orchestrate.md | head -5`
  - [ ] View deleted content: `git show <commit>^:.claude/commands/orchestrate.md | head -20`
  - [ ] Verify content accessible
- [ ] Validate documentation consistency
  - [ ] Verify no broken references to removed commands
  - [ ] Search: `grep -r "orchestrate.md\|supervise.md" .claude/docs/`
  - [ ] Search: `grep -r "/orchestrate\|/supervise" .claude/commands/README.md`
  - [ ] Fix any stale references found
- [ ] Create implementation summary
  - [ ] Document: `/home/benjamin/.config/.claude/specs/718_commands_directorry_has_become_cluttered_with/summaries/001_cleanup_summary.md`
  - [ ] Sections: Changes Made, Metrics (files removed, disk reclaimed), Validation Results
  - [ ] Reference research reports and plan

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] All tests passing
- [ ] Cleanup metrics documented
- [ ] No broken documentation references
- [ ] Implementation summary created
- [ ] Git commit created: `feat(718): complete Phase 4 - Validation and Metrics`
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Pre-Removal Testing
- Document current state (file counts, disk usage)
- Verify git recovery commands work before removal
- Test pre-commit hook before enforcement

### Post-Removal Testing
- Full test suite execution (verify no regressions)
- Documentation link validation (no broken references)
- Git recovery verification (deleted files accessible)
- Pre-commit hook validation (backup file rejection)

### Regression Testing
- Run full test suite per CLAUDE.md protocols
- Verify no active commands broken by cleanup
- Verify documentation still renders correctly

## Documentation Requirements

### New Documentation
1. **Git Recovery Guide** (`/home/benjamin/.config/.claude/docs/guides/git-recovery-guide.md`)
   - Examples for viewing historical file versions
   - Examples for restoring deleted files
   - Examples for comparing versions across commits

2. **Implementation Summary** (`/home/benjamin/.config/.claude/specs/718_commands_directorry_has_become_cluttered_with/summaries/001_cleanup_summary.md`)
   - Changes made during implementation
   - Metrics (files removed, disk reclaimed)
   - Validation results

### Updated Documentation
1. **CLAUDE.md**
   - Project commands section: Remove legacy orchestrator note
   - Development philosophy: Reference anti-backup policy (already present)
   - Quick reference: Link to git recovery guide

2. **README.md** (`.claude/commands/README.md`)
   - Orchestration section: Remove orchestrate/supervise
   - Promote /coordinate as sole orchestrator

3. **command-reference.md**
   - Remove orchestrate/supervise entries completely
   - Update /coordinate description

4. **command-development-guide.md**
   - Anti-backup policy section
   - Git version control best practices
   - Pre-commit hook documentation

## Dependencies

### External Dependencies
- Git version control system (for history, recovery, hooks)
- Bash shell (for pre-commit hook execution)
- Standard Unix utilities (rm, find, du, wc, chmod)

### Internal Dependencies
- Research reports (001_topic1.md, 002_topic2.md)
- CLAUDE.md standards and protocols
- Documentation guides directory structure

### File Dependencies
- `.git/hooks/` directory (for pre-commit hook)
- `.claude/commands/` directory (cleanup target)
- `.claude/docs/guides/` directory (new documentation)

## Risk Management

### Risk 1: User Accidentally Approves Wrong Removal
- **Likelihood**: Low
- **Impact**: Medium
- **Mitigation**:
  - Explicit approval checkboxes in plan
  - Git tag before deletion enables instant recovery
  - Recovery guide created in Phase 3

### Risk 2: Documentation References Break
- **Likelihood**: Medium
- **Impact**: Low
- **Mitigation**:
  - Phase 3 searches and updates all references
  - Phase 4 validates no broken links
  - Grep searches find stale references

### Risk 3: Pre-commit Hook Breaks Workflow
- **Likelihood**: Low
- **Impact**: Medium
- **Mitigation**:
  - Hook only rejects backup files (unlikely legitimate use)
  - Clear error messages guide resolution
  - Tested in Phase 3 before enforcement

### Risk 4: Tests Fail After Removal
- **Likelihood**: Low
- **Impact**: Medium
- **Mitigation**:
  - Only removing redundant commands (not core functionality)
  - Full test suite in Phase 4
  - Git tag enables rollback if needed

## Complexity Calculation

```
Score = (tasks × 1.0) + (phases × 5.0) + (hours × 0.5) + (dependencies × 2.0)
      = (32 × 1.0) + (4 × 5.0) + (5 × 0.5) + (2 × 2.0)
      = 32 + 20 + 2.5 + 4
      = 58.5

Note: Complexity reduced from 92.5 to 58.5 by eliminating deprecation workflow.
Plan remains Level 0 (single file) following progressive planning standards.
```

## Phase Dependencies

This plan uses minimal dependencies to enable faster execution:
- Phase 1 (Approval): No dependencies, starts immediately
- Phase 2 (Removal): Depends on Phase 1 approval
- Phase 3 (Prevention): Depends on Phase 2 completion
- Phase 4 (Validation): Depends on Phases 2, 3 completion

**Estimated Time**: 4-6 hours (no deprecation overhead)

## Notes

### User Approval Required
**Before proceeding to Phase 2**, user must explicitly approve the removal lists in the "Commands to Remove" section at the top of this plan.

Mark each category with `[x]` to approve:
- [ ] Backup files (23 files)
- [ ] Redundant orchestrators (orchestrate, supervise)

### Clean-Break Philosophy Alignment
This plan follows the project's clean-break philosophy from CLAUDE.md:
- No deprecation warnings or transition periods
- No migration guides or backward compatibility
- Immediate removal with git recovery as safety net
- Focus on what the system is, not what it was

### Deferred Decisions
The following commands flagged for potential consolidation but deferred pending usage data:
- `/plan-wizard` vs `/plan` or `/plan-from-template`
- `/optimize-claude` vs `/setup --analyze`

Recommend 30-90 day usage monitoring before making consolidation decisions.
