# Implementation Plan: Archive Orphaned Agents and Unused Library Scripts

## Metadata
- **Plan ID**: 001
- **Date Created**: 2025-01-15
- **Type**: Refactor
- **Scope**: Archive 3 orphaned agents and 5 unused library scripts following clean-break philosophy
- **Priority**: MEDIUM
- **Complexity**: 5/10
- **Estimated Duration**: 2 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Related Specs**: [722_agent_and_library_archival_research]
- **Research Reports**:
  - [OVERVIEW.md](../reports/001_can_now_also_be_archived_do_not_archive_agents_or/OVERVIEW.md)
  - [Agent Dependency Analysis](../reports/001_can_now_also_be_archived_do_not_archive_agents_or/001_agent_dependency_analysis_for_archived_commands.md)
  - [Script Library Usage](../reports/001_can_now_also_be_archived_do_not_archive_agents_or/002_script_library_usage_by_active_commands.md)
  - [Cross-Reference Validation](../reports/001_can_now_also_be_archived_do_not_archive_agents_or/003_cross_reference_validation_agents_and_scripts.md)
  - [Safe Archival Strategy](../reports/001_can_now_also_be_archived_do_not_archive_agents_or/004_safe_archival_strategy_and_dependency_mapping.md)
- **Structure Level**: 0 (Single-file)

## Executive Summary

### Problem Statement

Following the archival of 8 commands (analyze, document, list, orchestrate, plan-from-template, plan-wizard, refactor, supervise, test-all, test), we need to archive associated agents and library scripts that are no longer used by active commands. Research identified 3 orphaned agents and 5 unused library scripts that can be safely archived without breaking production workflows.

### Solution Overview

Archive identified agents and scripts using clean-break philosophy:
- **Immediate removal** (no deprecation period)
- **Fail-fast validation** (verify no active dependencies)
- **Git-tracked archival** (preserve history)
- **Pre-archival verification** (automated safety checks)

**Items to Archive**:

**Agents (3)**:
1. `code-reviewer.md` - Only used by archived test.md command
2. `test-specialist.md` - Only used by archived test-all.md command
3. `doc-writer.md` - Only used by archived document.md command

**Library Scripts (5)**:
1. `analyze-metrics.sh` - Only used by archived analyze.md command
2. `checkpoint-580.sh` - Legacy version superseded by checkpoint-utils.sh
3. `workflow-detection.sh.backup-before-task2.2` - Backup file
4. `workflow-scope-detection.sh.backup-phase1` - Backup file
5. `workflow-state-machine.sh.backup` - Backup file

### Success Criteria

- [ ] All 3 agents archived to `.claude/archive/agents/`
- [ ] All 5 library scripts archived to `.claude/archive/lib/`
- [ ] No active commands reference archived items (verified via grep)
- [ ] Archive structure maintains git history
- [ ] Changes committed with descriptive message
- [ ] Fail-fast verification confirms no breakage

### Benefits

- **Reduced clutter**: Remove 8 obsolete files from active codebase
- **Improved discoverability**: Clearer separation between active and archived infrastructure
- **Preserved history**: Git archive maintains full change history
- **Fail-fast safety**: Verification ensures no silent degradation
- **Clean architecture**: Follows project's clean-break philosophy

---

## Implementation Phases

### Phase 1: Pre-Archival Verification

**Objective**: Verify archival candidates have no active dependencies

**Dependencies**: None

**Complexity**: 2/10

**Duration**: 15 minutes

#### Tasks

- [ ] **Task 1.1**: Create verification script `.claude/tmp/verify_archival_safety.sh`
  - Grep all active commands for references to agents/scripts
  - Check for dynamic invocations (Task tool, source statements)
  - Verify no inter-agent dependencies exist

- [ ] **Task 1.2**: Run verification against 3 agents
  ```bash
  grep -r "code-reviewer" .claude/commands/*.md
  grep -r "test-specialist" .claude/commands/*.md
  grep -r "doc-writer" .claude/commands/*.md
  ```

- [ ] **Task 1.3**: Run verification against 5 library scripts
  ```bash
  grep -r "analyze-metrics.sh" .claude/commands/*.md .claude/lib/*.sh
  grep -r "checkpoint-580.sh" .claude/commands/*.md .claude/lib/*.sh
  grep -r "workflow-detection.sh.backup" .claude/commands/*.md .claude/lib/*.sh
  grep -r "workflow-scope-detection.sh.backup" .claude/commands/*.md .claude/lib/*.sh
  grep -r "workflow-state-machine.sh.backup" .claude/commands/*.md .claude/lib/*.sh
  ```

- [ ] **Task 1.4**: Document verification results
  - Create `.claude/specs/722_*/debug/001_archival_verification.log`
  - Record all grep results (should be zero matches)
  - Flag any unexpected dependencies for manual review

#### Deliverables

1. Verification script: `.claude/tmp/verify_archival_safety.sh`
2. Verification log: `.claude/specs/722_*/debug/001_archival_verification.log`
3. Green light confirmation: "All archival candidates safe to proceed"

#### Success Criteria

- [ ] Verification script created and executable
- [ ] Zero active dependencies found for all 8 items
- [ ] Verification log documents zero-match results
- [ ] Manual spot-check confirms automated verification

---

### Phase 2: Archive Structure Creation

**Objective**: Create archive directories following project conventions

**Dependencies**: Phase 1 complete (verification passed)

**Complexity**: 1/10

**Duration**: 10 minutes

#### Tasks

- [ ] **Task 2.1**: Create agent archive directory
  ```bash
  mkdir -p .claude/archive/agents
  ```

- [ ] **Task 2.2**: Create library archive directory
  ```bash
  mkdir -p .claude/archive/lib
  ```

- [ ] **Task 2.3**: Create archive metadata file
  ```bash
  cat > .claude/archive/ARCHIVE_LOG.md << 'EOF'
  # Archive Log

  ## 2025-01-15: Agents and Library Scripts (Topic 722)

  **Archived Items**: 8 total (3 agents, 5 library scripts)

  **Rationale**: Following command archival (Topic 721), these items no longer have active dependencies.

  **Research**: See Topic 722 research reports

  **Agents Archived**:
  - code-reviewer.md (used by archived test.md)
  - test-specialist.md (used by archived test-all.md)
  - doc-writer.md (used by archived document.md)

  **Library Scripts Archived**:
  - analyze-metrics.sh (used by archived analyze.md)
  - checkpoint-580.sh (legacy, superseded by checkpoint-utils.sh)
  - workflow-detection.sh.backup-before-task2.2 (backup file)
  - workflow-scope-detection.sh.backup-phase1 (backup file)
  - workflow-state-machine.sh.backup (backup file)
  EOF
  ```

- [ ] **Task 2.4**: Update `.gitignore` to track archive directories
  - Verify `.claude/archive/` is NOT in `.gitignore`
  - Archive directories must be git-tracked (not ignored)

#### Deliverables

1. Directory: `.claude/archive/agents/`
2. Directory: `.claude/archive/lib/`
3. Metadata: `.claude/archive/ARCHIVE_LOG.md`
4. Updated: `.gitignore` (if needed)

#### Success Criteria

- [ ] Archive directories created
- [ ] Archive log documents rationale and item list
- [ ] Git tracking confirmed (not ignored)

---

### Phase 3: Execute Archival with Fail-Fast Validation

**Objective**: Move files to archive with immediate validation

**Dependencies**: Phase 2 complete (archive structure ready)

**Complexity**: 2/10

**Duration**: 20 minutes

#### Tasks

- [ ] **Task 3.1**: Archive agents (3 files)
  ```bash
  # Move each agent with git mv (preserves history)
  git mv .claude/agents/code-reviewer.md .claude/archive/agents/
  git mv .claude/agents/test-specialist.md .claude/archive/agents/
  git mv .claude/agents/doc-writer.md .claude/archive/agents/

  # Verify files moved
  ls -la .claude/archive/agents/
  ```

- [ ] **Task 3.2**: Archive library scripts (5 files)
  ```bash
  # Move each script with git mv
  git mv .claude/lib/analyze-metrics.sh .claude/archive/lib/
  git mv .claude/lib/checkpoint-580.sh .claude/archive/lib/
  git mv .claude/lib/workflow-detection.sh.backup-before-task2.2 .claude/archive/lib/
  git mv .claude/lib/workflow-scope-detection.sh.backup-phase1 .claude/archive/lib/
  git mv .claude/lib/workflow-state-machine.sh.backup .claude/archive/lib/

  # Verify files moved
  ls -la .claude/archive/lib/
  ```

- [ ] **Task 3.3**: Fail-fast validation checkpoint
  ```bash
  # Run active commands to verify no breakage
  # Test coordinate (primary production command)
  /coordinate "test workflow" --dry-run

  # Test research (hierarchical agent pattern)
  /research "test topic" --dry-run

  # Test plan (planning workflow)
  /plan "test feature" --dry-run

  # All commands must complete without "file not found" errors
  ```

- [ ] **Task 3.4**: Verify git status
  ```bash
  git status
  # Should show 8 renames:
  # renamed: .claude/agents/code-reviewer.md -> .claude/archive/agents/code-reviewer.md
  # (etc. for all 8 files)
  ```

#### Deliverables

1. Archived agents: 3 files in `.claude/archive/agents/`
2. Archived scripts: 5 files in `.claude/archive/lib/`
3. Validation results: All active commands pass dry-run tests
4. Git status: Shows 8 renames (not deletions)

#### Success Criteria

- [ ] All 8 files moved to archive directories
- [ ] Git tracking preserved (using `git mv`)
- [ ] Active commands pass fail-fast validation
- [ ] No "file not found" errors in validation

---

### Phase 4: Git Commit and Documentation

**Objective**: Commit changes with descriptive message following project standards

**Dependencies**: Phase 3 complete (archival executed and validated)

**Complexity**: 1/10

**Duration**: 15 minutes

#### Tasks

- [ ] **Task 4.1**: Stage all changes
  ```bash
  # Verify git status shows 8 renames + ARCHIVE_LOG.md
  git status

  # Stage archive metadata
  git add .claude/archive/ARCHIVE_LOG.md
  git add .claude/archive/agents/
  git add .claude/archive/lib/
  ```

- [ ] **Task 4.2**: Create commit with descriptive message
  ```bash
  git commit -m "$(cat <<'EOF'
  feat(722): archive 3 orphaned agents and 5 unused library scripts

  Following command archival (Topic 721), research identified 8 items
  safe to archive with zero active dependencies:

  Agents (3):
  - code-reviewer.md (used by archived test.md)
  - test-specialist.md (used by archived test-all.md)
  - doc-writer.md (used by archived document.md)

  Library Scripts (5):
  - analyze-metrics.sh (used by archived analyze.md)
  - checkpoint-580.sh (legacy, superseded by checkpoint-utils.sh)
  - 3 backup files (workflow-*.sh.backup*)

  Archival follows clean-break philosophy:
  - Pre-archival verification: zero active dependencies (grep validated)
  - Fail-fast validation: all active commands pass dry-run tests
  - Git history preserved: used git mv (not rm)
  - Archive metadata: documented in ARCHIVE_LOG.md

  Research: See Topic 722 reports for complete dependency analysis

  🤖 Generated with Claude Code

  Co-Authored-By: Claude <noreply@anthropic.com>
  EOF
  )"
  ```

- [ ] **Task 4.3**: Verify commit
  ```bash
  git log -1 --stat
  # Should show 8 file renames + ARCHIVE_LOG.md addition
  ```

- [ ] **Task 4.4**: Update plan status
  - Mark this plan as COMPLETED in metadata
  - Link to commit hash in plan metadata
  - Update Topic 722 summary with archival completion

#### Deliverables

1. Git commit with descriptive message
2. Commit verification: Shows 8 renames + metadata
3. Updated plan metadata: Links to commit hash
4. Topic 722 summary updated

#### Success Criteria

- [ ] Commit created with all changes
- [ ] Commit message follows project standards
- [ ] Commit preserves git history (shows renames)
- [ ] Plan metadata updated with completion status

---

## Rollback Strategy

If issues are discovered after archival:

1. **Immediate Rollback**:
   ```bash
   git revert HEAD  # Undo archival commit
   # All files return to original locations
   ```

2. **Selective Restoration**:
   ```bash
   # Restore specific file if needed
   git mv .claude/archive/agents/code-reviewer.md .claude/agents/
   git commit -m "fix: restore code-reviewer agent (found active dependency)"
   ```

3. **Research Update**:
   - Document why restoration was needed
   - Update Topic 722 research with missed dependency
   - Re-verify dependencies before retry

**No Silent Fallbacks**: Following clean-break philosophy, there are no graceful degradation mechanisms. Any missing files will cause immediate, obvious bash errors.

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Missed dependency in verification | Low | High | Multi-stage verification (grep + dry-run + manual review) |
| Dynamic agent invocation not detected | Low | Medium | Search for Task tool patterns, not just literal filenames |
| Backup files still in use | Very Low | Low | Research confirmed these are true backups (older than active versions) |
| Git history lost | Very Low | Medium | Use `git mv` exclusively (never `rm` then `git add`) |
| Active workflow breaks silently | Very Low | High | Fail-fast validation ensures loud failures, not silent degradation |

---

## Success Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Files archived | 8/8 (100%) | Count files in `.claude/archive/` |
| Active dependencies | 0 | Grep validation shows zero matches |
| Git history preserved | 100% | All files show rename history in `git log --follow` |
| Active commands functional | 100% pass rate | Dry-run tests on coordinate, research, plan |
| Archive documentation | Complete | ARCHIVE_LOG.md contains all items with rationale |

---

## Completion Criteria

This plan is complete when:

1. **All 8 items archived**: 3 agents + 5 library scripts moved to `.claude/archive/`
2. **Zero active dependencies**: Grep verification confirms no references in active commands
3. **Fail-fast validation passed**: All active commands pass dry-run tests without errors
4. **Git commit created**: Descriptive commit message following project standards
5. **Archive documented**: ARCHIVE_LOG.md records rationale and item list
6. **Git history preserved**: All files show rename history (not deletion + addition)

---

## Notes

- **Clean-Break Philosophy**: No deprecation warnings, no migration tracking, no backward compatibility shims. Archival is immediate and final.
- **Fail-Fast Architecture**: Missing files cause immediate bash errors, not silent fallbacks. This is intentional.
- **Research Foundation**: This plan is based on comprehensive dependency analysis across 4 research reports (Topic 722).
- **Future-Proof**: If any archived item is needed later, git history allows easy restoration with full context.
- **Low Archival Scope**: Only 7.3% of agents/libraries archived (8 of 109 total items). Remaining 92.7% are actively used.

---

## Related Documentation

- [Topic 721: Command Archival Summary](../721_archive_commands_in_order_to_provide_a_detailed/reports/000_comprehensive_summary.md)
- [Topic 722: Agent and Library Research OVERVIEW](../reports/001_can_now_also_be_archived_do_not_archive_agents_or/OVERVIEW.md)
- [Clean-Break Philosophy](.claude/docs/concepts/writing-standards.md#clean-break-and-fail-fast-approach)
- [Git Recovery Guide](.claude/docs/guides/git-recovery-guide.md)
