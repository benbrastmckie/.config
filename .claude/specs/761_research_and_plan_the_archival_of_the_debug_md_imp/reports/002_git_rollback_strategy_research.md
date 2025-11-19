# Git-Based Rollback Strategy Research Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Remove explicit rollback strategy, use git instead
- **Report Type**: Best practices and plan revision analysis
- **Related Plan**: [Command Archival Implementation Plan](../plans/001_research_and_plan_the_archival_of_the_de_plan.md)

## Executive Summary

The existing plan contains an explicit rollback strategy with a dedicated `rollback.sh` script (Phase 5) that duplicates functionality already provided by git. The project follows a "clean-break, no-backup philosophy" documented in git-recovery-guide.md and writing-standards.md, which establishes git as the primary recovery mechanism. This research identifies 15 rollback-related items in the plan that should be replaced with git-based commands, and 8 documentation files that contain rollback references requiring review for consistency with the established clean-break philosophy.

## Findings

### 1. Existing Plan's Explicit Rollback Strategy

The plan at `/home/benjamin/.config/.claude/specs/761_research_and_plan_the_archival_of_the_debug_md_imp/plans/001_research_and_plan_the_archival_of_the_de_plan.md` contains:

**Phase 5 Rollback Tasks (lines 288-337):**
- Line 45: Success criterion for "Rollback script created and tested"
- Lines 98-101: Stub file pattern with `rollback.sh` reference
- Lines 104-111: Rollback Strategy section describing custom rollback script
- Lines 296-302: Tasks to create rollback.sh with single-file, category, and full restore functions
- Lines 318-327: Testing of rollback script
- Lines 403-408: Integration testing section for rollback
- Lines 420: Documentation reference to rollback.sh
- Lines 444: Risk assessment mentioning rollback failure

**Explicit Rollback Procedure Section (lines 451-478):**
- Immediate Rollback procedure using custom rollback.sh
- Post-Commit Rollback using rollback.sh
- Emergency Rollback (already correctly uses git commands)

### 2. Project's Established Clean-Break Philosophy

The project has documented standards that explicitly prefer git over backup files:

**Git Recovery Guide** (`/home/benjamin/.config/.claude/docs/guides/git-recovery-guide.md`):
- Lines 5-17: "Why No Backup Files?" section establishes:
  - "All version history managed via git"
  - "No backup files allowed - Enforced via .gitignore"
  - "Git provides superior recovery"
- Lines 35-41: Shows git commands for restoring deleted files:
  - `git checkout <commit-hash>^ -- <file>`
  - `git checkout <tag-name> -- <file>`
- Lines 126-138: Safety tags for recovery before major operations

**Executable Documentation Separation** (`/home/benjamin/.config/.claude/docs/concepts/patterns/executable-documentation-separation.md`):
- Lines 530-555: Clean-Break Philosophy explicitly states:
  - "No archives beyond git history"
  - "Configuration describes what it is (not what it was)"
  - "Risk Mitigation: Git history provides complete rollback capability without file clutter"
  - "Any migration can be reverted with `git revert <commit>` or `git reset --hard <previous-commit>`"

**Writing Standards** (`/home/benjamin/.config/.claude/docs/concepts/writing-standards.md`):
- Lines 23-29: Clean-Break Refactors section:
  - "Prioritize coherence over compatibility"
  - "No legacy burden"
  - "Migration is acceptable: Breaking changes are acceptable when they improve system quality"

### 3. Git Commands That Replace Custom Rollback Script

Based on documented patterns, these git commands provide all necessary rollback functionality:

**Individual File Restore:**
```bash
# Restore specific file from last commit
git checkout HEAD -- .claude/commands/debug.md

# Restore from specific commit
git checkout <commit-hash> -- .claude/commands/debug.md
```

**Category Restore:**
```bash
# Restore all commands
git checkout HEAD~1 -- .claude/commands/*.md

# Restore all agents
git checkout HEAD~1 -- .claude/agents/code-writer.md .claude/agents/implementation-executor.md
```

**Full Archive Restore:**
```bash
# Revert specific phase commits
git revert HEAD~5..HEAD

# Hard reset to pre-archival state
git reset --hard HEAD~6
```

**Safety Tag Creation:**
```bash
# Create safety tag before archival
git tag archive/pre-archival-$(date +%Y%m%d)

# Restore from safety tag
git checkout archive/pre-archival-20251117 -- .claude/
```

### 4. Documentation Files Requiring Updates

The following files contain rollback references that should be reviewed:

1. **backup-retention-policy.md** (`/home/benjamin/.config/.claude/docs/reference/backup-retention-policy.md`)
   - Lines 29, 40, 48, 149-165, 219: Multiple rollback procedure references
   - Line 229: References `.claude/lib/rollback-command-file.sh` which may not be needed

2. **refactor-structure.md** (`/home/benjamin/.config/.claude/docs/reference/refactor-structure.md`)
   - Lines 244-245: "Rollback Plan" section template
   - Line 371: Lists rollback plan as required documentation

3. **plan-architect.md** (`/home/benjamin/.config/.claude/agents/plan-architect.md`)
   - Lines 557, 749: References to rollback procedures in plan templates

4. **checkpoint_template_guide.md** (`/home/benjamin/.config/.claude/docs/workflows/checkpoint_template_guide.md`)
   - Lines 43, 269, 330, 633: Rollback capability references
   - These are for parallel operation checkpoints, which may be legitimate

5. **orchestration-guide.md** (`/home/benjamin/.config/.claude/docs/workflows/orchestration-guide.md`)
   - Lines 97, 585, 704: Checkpoint rollback references

6. **agent-reference.md** (`/home/benjamin/.config/.claude/docs/reference/agent-reference.md`)
   - Line 45: "Include backup and rollback procedures" guidance

7. **CLAUDE.md** (`/home/benjamin/.config/CLAUDE.md`)
   - No direct rollback references found, but may need section updates after documentation changes

### 5. Existing Git-Based Rollback Examples in Project

Several existing plans already use git-based rollback correctly:

**spec 752 debug plans** (`/home/benjamin/.config/.claude/specs/752_debug_coordinate_workflow_classifier/plans/001_debug_strategy.md`):
- Lines 876-877, 901-902, 928, 931: Use `git checkout HEAD -- <file>` and `git revert`

**spec 730 implementation plan** (`/home/benjamin/.config/.claude/specs/730_research_the_optimizeclaudemd_command_in_order_to_/plans/730_implementation_plan.md`):
- Lines 259-260: Use `git revert <commit-hash>` and `git reset --hard <commit-hash>`

These serve as templates for the revised rollback strategy.

## Recommendations

### 1. Remove Custom Rollback Script from Plan

**Changes Required:**
- Remove success criterion for "Rollback script created and tested" (line 45)
- Remove stub file reference to rollback.sh (lines 98-101)
- Remove entire "Rollback Strategy" section (lines 104-111)
- Remove Phase 5 tasks for creating rollback.sh (lines 296-302)
- Remove rollback script testing tasks (lines 318-327)
- Remove rollback testing from integration testing (lines 403-408)
- Remove documentation reference to rollback.sh (line 420)
- Remove risk assessment for "Rollback fails" (line 444)

### 2. Replace Rollback Procedure Section with Git Commands

**Replace lines 451-478 with:**
```markdown
## Recovery Procedure

### Pre-Archival Safety
```bash
# Create safety tag before starting archival
git tag archive/pre-archival-$(date +%Y%m%d)
echo "Safety tag created: archive/pre-archival-$(date +%Y%m%d)"
```

### Individual File Recovery
```bash
# Restore specific command from before archival
git checkout archive/pre-archival-20251117 -- .claude/commands/debug.md

# Restore specific agent
git checkout archive/pre-archival-20251117 -- .claude/agents/code-writer.md
```

### Full Recovery (All Archived Files)
```bash
# Restore all archived files at once
git checkout archive/pre-archival-20251117 -- \
  .claude/commands/debug.md \
  .claude/commands/implement.md \
  .claude/commands/plan.md \
  .claude/commands/research.md \
  .claude/commands/revise.md \
  .claude/agents/code-writer.md \
  .claude/agents/implementation-executor.md \
  .claude/lib/validate-plan.sh

# Or restore entire .claude directory
git checkout archive/pre-archival-20251117 -- .claude/
```

### Undo Archival Commits
```bash
# Revert all archival commits (reverse chronological)
git revert HEAD~5..HEAD

# Or hard reset to pre-archival state
git reset --hard archive/pre-archival-20251117
```
```

### 3. Simplify Phase 5

Rename Phase 5 from "Create Rollback and Documentation" to "Create Archive Documentation" and:
- Remove rollback.sh creation tasks
- Keep MANIFEST.md and README.md creation
- Add task to create safety git tag
- Update testing to verify git recovery works

### 4. Update Documentation Files

**High Priority (directly related to plan patterns):**

1. **plan-architect.md**: Update line 557 to reference git recovery instead of "Include rollback procedure"
2. **refactor-structure.md**: Update "Rollback Plan" template to show git commands instead of custom scripts

**Medium Priority (general documentation):**

3. **backup-retention-policy.md**: Consider deprecating or updating to emphasize git is the primary backup
4. **agent-reference.md**: Update guidance about backup and rollback procedures

**Low Priority (legitimate checkpoint usage):**

5. **checkpoint_template_guide.md**: Keep as-is - checkpoints serve different purpose (parallel operation state)
6. **orchestration-guide.md**: Keep as-is - checkpoint recovery is for runtime state, not file rollback

### 5. Add Git Recovery Reference to Archive README

The archive README.md should document:
- Safety tag name created during archival
- Git commands for recovery
- Reference to git-recovery-guide.md for complete documentation

## Implementation Summary

### Plan Changes Required

| Section | Line(s) | Action | Rationale |
|---------|---------|--------|-----------|
| Success Criteria | 45 | Remove rollback script criterion | Git replaces custom script |
| Stub File Pattern | 98-101 | Remove rollback.sh reference | Not needed |
| Rollback Strategy | 104-111 | Replace with git commands | Clean-break philosophy |
| Phase 5 Tasks | 296-302 | Remove rollback.sh tasks | Git provides functionality |
| Phase 5 Testing | 318-327 | Replace with git recovery testing | Verify git works |
| Rollback Testing | 403-408 | Update to test git recovery | Consistency |
| Documentation | 420 | Remove rollback.sh reference | File won't exist |
| Risk Assessment | 444 | Remove rollback failure risk | Git is reliable |
| Rollback Procedure | 451-478 | Replace with git commands | Clean-break philosophy |

### Documentation Changes Required

| File | Priority | Action |
|------|----------|--------|
| plan-architect.md | High | Update rollback guidance to use git |
| refactor-structure.md | High | Update Rollback Plan template |
| backup-retention-policy.md | Medium | Review for consistency with git-first approach |
| agent-reference.md | Medium | Update backup/rollback guidance |

### New Content Required

1. Safety tag creation task in Phase 1
2. Git recovery testing in Phase 5
3. Archive README.md with git recovery instructions

## References

### Plan File
- `/home/benjamin/.config/.claude/specs/761_research_and_plan_the_archival_of_the_debug_md_imp/plans/001_research_and_plan_the_archival_of_the_de_plan.md` - Lines 45, 98-111, 288-337, 403-478

### Documentation Files
- `/home/benjamin/.config/.claude/docs/guides/git-recovery-guide.md` - Lines 5-17, 35-41, 126-138
- `/home/benjamin/.config/.claude/docs/concepts/patterns/executable-documentation-separation.md` - Lines 530-555
- `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md` - Lines 23-29
- `/home/benjamin/.config/.claude/docs/reference/backup-retention-policy.md` - Lines 29, 40, 48, 149-165, 219, 229
- `/home/benjamin/.config/.claude/docs/reference/refactor-structure.md` - Lines 244-245, 371
- `/home/benjamin/.config/.claude/agents/plan-architect.md` - Lines 557, 749
- `/home/benjamin/.config/.claude/docs/workflows/checkpoint_template_guide.md` - Lines 43, 269, 330, 633
- `/home/benjamin/.config/.claude/docs/workflows/orchestration-guide.md` - Lines 97, 585, 704
- `/home/benjamin/.config/.claude/docs/reference/agent-reference.md` - Line 45

### Example Plans Using Git Rollback
- `/home/benjamin/.config/.claude/specs/752_debug_coordinate_workflow_classifier/plans/001_debug_strategy.md` - Lines 876-877, 901-902, 928, 931
- `/home/benjamin/.config/.claude/specs/730_research_the_optimizeclaudemd_command_in_order_to_/plans/730_implementation_plan.md` - Lines 259-260
