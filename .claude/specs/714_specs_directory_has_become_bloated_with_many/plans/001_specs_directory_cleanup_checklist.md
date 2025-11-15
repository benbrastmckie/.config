# Specs Directory Cleanup Checklist

## Metadata
- **Date**: 2025-11-14
- **Feature**: Rapid cleanup of bloated .claude/specs/ directory
- **Scope**: Remove obsolete directories (<700) and loose files
- **Estimated Phases**: 2
- **Estimated Hours**: 0.25 hours (15 minutes)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Specs Directory Structure Analysis](../reports/001_specs_directory_analysis.md)
  - [Directory Removal Safety Criteria](../reports/002_removal_safety_criteria.md)
- **Structure Level**: 0
- **Complexity Score**: 8.0

## Overview

The `.claude/specs/` directory has grown to 212 topic directories with significant bloat from obsolete directories numbered below 700 and loose files violating directory protocols. This cleanup plan focuses on safe removal of obsolete content without wasting effort on complex migrations.

**Current State**:
- 198 obsolete topic directories (numbered <700) - safe for removal
- 12 loose markdown files in specs root (violating protocols)
- All directories use proper NNN_ naming format

**Target State**:
- Remove all directories numbered <700 (legacy/obsolete specs)
- Clean up loose files that pose no risk
- Maintain active directories (700+) unchanged
- Zero protocol violations in specs root

## Research Summary

Research findings from provided reports:

**Directory Structure Analysis** (Report 001):
- 224 total topic directories analyzed
- 17% completion rate (38 specs with summaries)
- 68% research-only specs without implementation
- 7% completely empty directories (immediate removal candidates)
- Timestamp-based numbering shows 4.7x higher completion rate (75% vs 16%)

**Safety Criteria** (Report 002):
- 4-tier risk classification system developed
- Tier 1 (zero-risk): Empty directories - safe immediate removal
- Tier 2 (low-risk): Non-standard names - safe with renumbering
- Tier 3 (medium-risk): Loose files - requires migration or deletion
- Tier 4 (high-risk): Top-level artifact dirs - extensive migration needed
- Git history preservation critical for all tracked files
- Cross-reference impact: 20+ files reference coordinate_output.md
- Automation available: `.claude/scripts/detect-empty-topics.sh --cleanup`

Recommended approach: Incremental phased cleanup with validation after each tier.

## Success Criteria

- [ ] All 198 directories numbered <700 removed safely
- [ ] All 12 loose markdown files cleaned up (deleted)
- [ ] Zero violations of directory protocols
- [ ] Active directories (700+) remain unchanged
- [ ] Git history preserved for all tracked files
- [ ] All workflow commands function correctly after cleanup
- [ ] Test suite passes with zero regressions

## Technical Design

### Cleanup Strategy

**Architecture**: Two-phase approach focused on safe removal without complex migrations.

**Phase 1: Remove Obsolete Directories** (<700)
- Target: 198 directories numbered below 700
- Risk: Very low (legacy/obsolete content from old numbering system)
- Method: Bulk removal with `git rm -r`
- Validation: Verify no active cross-references before deletion
- Recovery: Git history preserves all removed content if needed

**Phase 2: Clean Up Loose Files**
- Target: 12 loose markdown files in specs root
- Risk: Very low (all are workflow artifacts or typos)
- Method: Direct removal with `git rm`
- Validation: Quick grep check for critical references
- Recovery: Git history preserves all removed content if needed

### Directory Structure Standards

Following `.claude/docs/concepts/directory-protocols.md`:
- Topic-based structure: `specs/{NNN_topic}/`
- Artifact subdirectories: plans/, reports/, summaries/, debug/
- No loose files in specs root (except README.md)
- All topic directories use NNN_ prefix (three-digit sequential)

### Git History Preservation

**For all removals**:
- Tracked files: Use `git rm` (preserves history)
- Gitignored files: Direct delete is safe (never tracked)
- Migrations: Use `git mv` (preserves history and tracking)

**Verification before deletion**:
```bash
git log --all --oneline -- path/to/file  # Check history exists
```

## Implementation Phases

### Phase 1: Remove Obsolete Directories (<700)

dependencies: []

**Objective**: Remove 198 directories numbered below 700 (legacy/obsolete content)

**Complexity**: Low

**Tasks**:
- [ ] List directories to be removed
  ```bash
  ls -1d .claude/specs/[0-6][0-9][0-9]_* > /tmp/obsolete_dirs.txt
  wc -l /tmp/obsolete_dirs.txt  # Should show 198
  ```
- [ ] Quick scan for any critical cross-references (unlikely for old specs)
  ```bash
  # Sample check on a few directories
  grep -r "specs/0[0-6][0-9]" .claude/commands/ --include="*.md" || echo "No references found"
  grep -r "specs/0[0-6][0-9]" .claude/docs/ --include="*.md" || echo "No references found"
  ```
- [ ] Remove all directories numbered <700 in batches
  ```bash
  # Remove in groups to avoid command line limits
  git rm -r .claude/specs/0[0-5][0-9]_* 2>/dev/null || true
  git rm -r .claude/specs/6[0-8][0-9]_* 2>/dev/null || true
  git rm -r .claude/specs/69[0-9]_* 2>/dev/null || true
  ```
- [ ] Verify removal count
  ```bash
  # Should show only directories 700+
  ls -1d .claude/specs/[0-9][0-9][0-9]_* | wc -l  # Should be ~14 (212 - 198)
  ```
- [ ] Stage changes for git
  ```bash
  git add -A
  ```
- [ ] Create git commit
  ```bash
  git commit -m "chore(714): remove 198 obsolete spec directories (<700)"
  ```

**Testing**:
```bash
# Verify no workflow breakage
.claude/tests/run_all_tests.sh

# Verify current directories still accessible
ls -ld .claude/specs/7[0-9][0-9]_*
```

**Expected Duration**: 10 minutes

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `chore(714): complete Phase 1 - Remove Obsolete Directories`
- [ ] Update this plan file with phase completion status

---

### Phase 2: Clean Up Loose Files

dependencies: [1]

**Objective**: Remove 12 loose markdown files from specs root

**Complexity**: Low

**Tasks**:
- [ ] List all loose markdown files (excluding README.md)
  ```bash
  find .claude/specs -maxdepth 1 -type f -name "*.md" ! -name "README.md"
  ```
  Expected: 12 files
- [ ] Quick check for any critical cross-references
  ```bash
  grep -r "coordinate_output.md" .claude/commands/ --include="*.md" || echo "No refs"
  grep -r "coordinate_output.md" .claude/docs/ --include="*.md" || echo "No refs"
  ```
- [ ] Remove all loose files (these are all workflow artifacts/typos)
  ```bash
  git rm .claude/specs/coordinage_implement.md
  git rm .claude/specs/coordinage_plan.md
  git rm .claude/specs/coordinate_command.md
  git rm .claude/specs/coordinate_output.md
  git rm .claude/specs/coordinate_research.md
  git rm .claude/specs/coordinate_revise.md
  git rm .claude/specs/coordinate_ultrathink.md
  git rm .claude/specs/optimize_output.md
  git rm .claude/specs/research_output.md
  git rm .claude/specs/setup_choice.md
  git rm .claude/specs/supervise_output.md
  git rm .claude/specs/workflow_scope_detection_analysis.md
  ```
- [ ] Verify no loose markdown files remain (except README.md)
  ```bash
  find .claude/specs -maxdepth 1 -type f -name "*.md" ! -name "README.md"
  ```
  Expected: Empty output
- [ ] Stage changes for git
  ```bash
  git add -A
  ```
- [ ] Create git commit
  ```bash
  git commit -m "chore(714): remove 12 loose files from specs root"
  ```

**Testing**:
```bash
# Verify workflows still function
.claude/tests/run_all_tests.sh

# Verify specs directory is clean
ls .claude/specs/*.md  # Should only show README.md
```

**Expected Duration**: 5 minutes

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `chore(714): complete Phase 2 - Clean Up Loose Files`
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Integration Testing
- Workflow commands: `/research`, `/plan`, `/implement`, `/coordinate`
- Test suite: `.claude/tests/run_all_tests.sh`

### Validation Points
- After Phase 1: Verify only directories 700+ remain (should be ~14 directories)
- After Phase 2: Verify 0 loose files in specs root
- After both phases: Verify 100% test suite pass rate

### Rollback Strategy
- Phase 1: `git revert <commit-hash>` (restores all 198 directories)
- Phase 2: `git revert <commit-hash>` (restores all 12 loose files)

All phases preserve git history, enabling easy rollback if issues discovered.

## Documentation Requirements

### Files to Update
- `.claude/specs/714_specs_directory_has_become_bloated_with_many/summaries/001_cleanup_summary.md` - Document removal counts and results

### Standards Compliance
- Follow git conventions: Descriptive commit messages, atomic commits per phase
- Preserve git history for all removals (use `git rm`, not direct deletion)

## Dependencies

### External Dependencies
- Git: For history preservation (`git rm`)
- Bash: For scripting

### Internal Dependencies
- Phase 2 depends on Phase 1: Ensures directories removed before cleaning loose files

### Prerequisite Verification
```bash
# Verify git is available
git --version

# Verify current branch status
git status
```

## Risk Assessment

### Very Low-Risk Operations (Both Phases)
- Obsolete directory removal: 9/10 safety score (legacy content <700)
- Loose file removal: 8/10 safety score (workflow artifacts only)
- Total time: 15 minutes
- Rollback: Easy (`git revert`)

## Completion Metrics

### Success Metrics
- Obsolete directories: 198 → 0 (100% removal)
- Loose files: 12 → 0 (100% protocol compliance)
- Remaining active directories: ~14 (700+)
- Test suite: 100% pass rate maintained
- Git history: 100% preserved

### Time Metrics
- Phase 1: 10 minutes (actual vs 10 min estimated)
- Phase 2: 5 minutes (actual vs 5 min estimated)
- Total: ~15 minutes (rapid cleanup)

### Quality Metrics
- Zero regressions in test suite
- Zero workflow command failures
- 100% directory protocol compliance

## Revision History

### 2025-11-14 - Revision 1
**Changes**: Simplified plan from 4 complex phases to 2 simple removal phases
**Reason**: User wants to avoid wasting effort on migrations - just remove obsolete content
**Key Simplifications**:
- Removed empty directory detection phase (not needed)
- Removed non-standard directory migration phase (no such directories exist)
- Removed loose file migration/categorization (just delete all 12 files)
- Removed validation/documentation phase (minimal validation only)
- Changed from ~3 hours of work to ~15 minutes
**Target Changes**:
- Phase 1: Remove 198 directories numbered <700 (obsolete legacy content)
- Phase 2: Remove 12 loose files (all are workflow artifacts/typos)
**Modified Phases**: All phases replaced with simplified approach
