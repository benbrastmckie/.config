# Implementation Plan: Task #45

**Task**: Fix LogosWebsite agent system gaps identified in task 44 research
**Version**: 001
**Date**: 2026-02-05
**Feature**: Apply plan status update fixes and missing files to LogosWebsite .claude/
**Status**: [COMPLETED]
**Estimated Hours**: 2-3 hours
**Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
**Research Reports**: [research-001.md](../reports/research-001.md), [research-002.md](../reports/research-002.md)
**Language**: meta

## Overview

This plan applies the plan-status-update bug fixes from the nvim repo to the LogosWebsite `.claude/` system. The nvim repo has already been patched with dual-pattern sed matching (bullet + non-bullet markdown formats), post-update verification with grep, INFO logging for missing plan files, and a defensive verification checkpoint in the `/implement` command. The LogosWebsite repo still has the old single-pattern sed (bullet only) with no verification. This plan also copies missing files (schemas, templates, output templates, docs) that were never synced due to the `<leader>ac` sync mechanism's file-type scanning gaps.

The padding convention (`{N}` unpadded in LogosWebsite vs `{NNN}` padded in nvim) is intentionally left as-is -- that is a larger migration best handled as a separate task.

## Goals & Non-Goals

**Goals**:
- Apply dual-pattern sed + verification to all 4 implementation skills in LogosWebsite
- Add missing plan status updates to skill-neovim-implementation (preflight + postflight)
- Add Checkpoint 5 defensive verification to LogosWebsite implement.md
- Copy missing files (schemas, templates, output templates, docs standard)
- Update LogosWebsite CLAUDE.md with Multi-Task Creation Standards section

**Non-Goals**:
- Changing the `{N}` unpadded directory convention in LogosWebsite (separate task)
- Modifying any web-specific files (agents, skills, context)
- Fixing the `<leader>ac` sync source path (separate Neovim config task)
- Adding Phase Checkpoint Protocol to neovim-implementation-agent (lower priority)

## Phases

### Phase 1: Fix skill-implementer Plan Status Patterns [COMPLETED]

**Estimated effort**: 20 minutes
**Status**: [IMPLEMENTING]

**Objectives**:
1. Replace single-pattern sed with dual-pattern sed (bullet + non-bullet) for COMPLETED and PARTIAL status updates
2. Add grep verification after each sed update
3. Add INFO log when no plan file is found

**Source of truth**: `/home/benjamin/.config/nvim/.claude/skills/skill-implementer/SKILL.md` (lines 266-313)

**Files to modify**:
- `/home/benjamin/Projects/Logos/LogosWebsite/.claude/skills/skill-implementer/SKILL.md` - Replace COMPLETED sed block (lines 265-271), PARTIAL sed block (lines 287-292), and preflight IMPLEMENTING sed block (line 96)

**Steps**:
1. Read the LogosWebsite skill-implementer/SKILL.md
2. Locate the COMPLETED plan file update block (around line 265-271)
3. Replace the single-pattern sed with dual-pattern sed + verification:
   - Add second sed line for non-bullet pattern: `sed -i 's/^\*\*Status\*\*: \[.*\]$/**Status**: [COMPLETED]/' "$plan_file"`
   - Add verification: `grep -qE` check with success/warning echo
   - Add INFO else clause for missing plan file
4. Locate the PARTIAL plan file update block (around line 287-292)
5. Apply same dual-pattern + verification pattern for PARTIAL
6. Locate the preflight IMPLEMENTING sed (around line 96)
7. Add second sed line for non-bullet pattern to preflight

**Verification**:
- `grep -c 'sed -i' /home/benjamin/Projects/Logos/LogosWebsite/.claude/skills/skill-implementer/SKILL.md` should return 6 (2 per status: IMPLEMENTING, COMPLETED, PARTIAL)
- `grep -c 'grep -qE' /home/benjamin/Projects/Logos/LogosWebsite/.claude/skills/skill-implementer/SKILL.md` should return 2 (COMPLETED + PARTIAL verification)
- `grep -c 'INFO: No plan file' /home/benjamin/Projects/Logos/LogosWebsite/.claude/skills/skill-implementer/SKILL.md` should return 2

---

### Phase 2: Fix skill-neovim-implementation Plan Status Patterns [COMPLETED]

**Estimated effort**: 30 minutes
**Status**: [IMPLEMENTING]

**Objectives**:
1. Add plan file status update to preflight (IMPLEMENTING) -- currently missing entirely
2. Add plan file status update to postflight (COMPLETED) with dual-pattern sed + verification -- currently missing entirely
3. Add explicit PARTIAL plan status update -- currently only prose, no code

**Source of truth**: `/home/benjamin/.config/nvim/.claude/skills/skill-neovim-implementation/SKILL.md` (lines 82-91 for preflight, lines 191-210 for postflight)

**Files to modify**:
- `/home/benjamin/Projects/Logos/LogosWebsite/.claude/skills/skill-neovim-implementation/SKILL.md` - Add plan file update blocks to Stage 2 (preflight) and Stage 7 (postflight)

**Steps**:
1. Read the LogosWebsite skill-neovim-implementation/SKILL.md
2. In Stage 2 (Preflight Status Update), after the TODO.md update line (~line 79), add the plan file IMPLEMENTING update block:
   ```
   **Update plan file** (if exists): Update the Status field in plan metadata:
   ```bash
   plan_file=$(ls -1 "specs/${task_number}_${project_name}/plans/implementation-"*.md 2>/dev/null | sort -V | tail -1)
   if [ -n "$plan_file" ] && [ -f "$plan_file" ]; then
       sed -i 's/^\- \*\*Status\*\*: \[.*\]$/- **Status**: [IMPLEMENTING]/' "$plan_file"
       sed -i 's/^\*\*Status\*\*: \[.*\]$/**Status**: [IMPLEMENTING]/' "$plan_file"
   fi
   ```
   ```
3. In Stage 7 (Postflight Status Update), after the TODO.md update to COMPLETED (~line 177), add the plan file COMPLETED update block with verification and INFO log
4. Replace the prose-only partial handling (~line 179 "On partial/failed") with explicit PARTIAL plan file update block with dual-pattern sed + verification

**Verification**:
- `grep -c 'sed -i' /home/benjamin/Projects/Logos/LogosWebsite/.claude/skills/skill-neovim-implementation/SKILL.md` should return 6 (2 per status: IMPLEMENTING, COMPLETED, PARTIAL)
- `grep -c 'grep -qE' /home/benjamin/Projects/Logos/LogosWebsite/.claude/skills/skill-neovim-implementation/SKILL.md` should return 2

---

### Phase 3: Fix skill-latex-implementation and skill-typst-implementation [COMPLETED]

**Estimated effort**: 20 minutes
**Status**: [IMPLEMENTING]

**Objectives**:
1. Replace single-pattern sed with dual-pattern sed for both skills (IMPLEMENTING, COMPLETED, PARTIAL)
2. Add grep verification for COMPLETED and PARTIAL updates
3. Add INFO log for missing plan files

**Source of truth**: `/home/benjamin/.config/nvim/.claude/skills/skill-latex-implementation/SKILL.md` and `/home/benjamin/.config/nvim/.claude/skills/skill-typst-implementation/SKILL.md`

**Files to modify**:
- `/home/benjamin/Projects/Logos/LogosWebsite/.claude/skills/skill-latex-implementation/SKILL.md` - Update IMPLEMENTING (line 75), COMPLETED (lines 283-289), PARTIAL (lines 305-311) sed blocks
- `/home/benjamin/Projects/Logos/LogosWebsite/.claude/skills/skill-typst-implementation/SKILL.md` - Update IMPLEMENTING (line 75), COMPLETED (lines 282-288), PARTIAL (lines 304-310) sed blocks

**Steps**:
1. Read the LogosWebsite skill-latex-implementation/SKILL.md
2. For each of the three status updates (IMPLEMENTING, COMPLETED, PARTIAL):
   a. Add second sed line for non-bullet pattern
   b. Add grep verification block (for COMPLETED and PARTIAL)
   c. Add INFO log else clause (for COMPLETED and PARTIAL)
3. Repeat identically for skill-typst-implementation/SKILL.md

**Verification**:
- For each file, `grep -c 'sed -i'` should return 6
- For each file, `grep -c 'grep -qE'` should return 2
- For each file, `grep -c 'INFO: No plan file'` should return 2

---

### Phase 4: Fix implement.md Command - Add Defensive Verification [COMPLETED]

**Estimated effort**: 20 minutes
**Status**: [IMPLEMENTING]

**Objectives**:
1. Add Checkpoint 5 "Verify Plan File Status Updated (Defensive)" to the GATE OUT section of the LogosWebsite implement.md command

**Source of truth**: `/home/benjamin/.config/nvim/.claude/commands/implement.md` (lines 122-156)

**Files to modify**:
- `/home/benjamin/Projects/Logos/LogosWebsite/.claude/commands/implement.md` - Add item 5 to CHECKPOINT 2: GATE OUT section, before the RETRY line

**Steps**:
1. Read the LogosWebsite implement.md
2. Locate the GATE OUT section (CHECKPOINT 2), specifically after item 4 (Populate Completion Summary)
3. Insert new item 5 "Verify Plan File Status Updated (Defensive)" with:
   - Condition: Only when result.status == "implemented"
   - Logic: grep to check for [COMPLETED] in plan file
   - Fallback: dual-pattern sed correction if missing
   - Verification: grep to confirm correction applied
   - Skip note for partial implementations
4. Adapt path references to use `${task_number}` (unpadded, matching LogosWebsite convention) instead of `${padded_num}`

**Verification**:
- `grep -c 'Verify Plan File Status Updated' /home/benjamin/Projects/Logos/LogosWebsite/.claude/commands/implement.md` should return 1
- `grep -c 'defensive correction' /home/benjamin/Projects/Logos/LogosWebsite/.claude/commands/implement.md` should return at least 1
- The plan file lookup should use `${task_number}` not `${padded_num}` (matching LogosWebsite convention)

---

### Phase 5: Copy Missing Files [COMPLETED]

**Estimated effort**: 20 minutes
**Status**: [IMPLEMENTING]

**Objectives**:
1. Copy context/core/schemas/ directory (2 files)
2. Copy context/core/templates/state-template.json (1 file)
3. Copy missing output/ template files (5 files)
4. Copy docs/reference/standards/multi-task-creation-standard.md (1 file)

**Source directory**: `/home/benjamin/.config/nvim/.claude/`
**Target directory**: `/home/benjamin/Projects/Logos/LogosWebsite/.claude/`

**Files to create**:
- `/home/benjamin/Projects/Logos/LogosWebsite/.claude/context/core/schemas/frontmatter-schema.json` - Copy from nvim
- `/home/benjamin/Projects/Logos/LogosWebsite/.claude/context/core/schemas/subagent-frontmatter.yaml` - Copy from nvim
- `/home/benjamin/Projects/Logos/LogosWebsite/.claude/context/core/templates/state-template.json` - Copy from nvim
- `/home/benjamin/Projects/Logos/LogosWebsite/.claude/output/learn.md` - Copy from nvim
- `/home/benjamin/Projects/Logos/LogosWebsite/.claude/output/plan.md` - Copy from nvim
- `/home/benjamin/Projects/Logos/LogosWebsite/.claude/output/research.md` - Copy from nvim
- `/home/benjamin/Projects/Logos/LogosWebsite/.claude/output/revise.md` - Copy from nvim
- `/home/benjamin/Projects/Logos/LogosWebsite/.claude/output/todo.md` - Copy from nvim
- `/home/benjamin/Projects/Logos/LogosWebsite/.claude/docs/reference/standards/multi-task-creation-standard.md` - Copy from nvim

**Steps**:
1. Create target directories:
   ```bash
   mkdir -p /home/benjamin/Projects/Logos/LogosWebsite/.claude/context/core/schemas
   mkdir -p /home/benjamin/Projects/Logos/LogosWebsite/.claude/docs/reference/standards
   ```
   (context/core/templates/ and output/ already exist)
2. Read each source file from the nvim repo
3. Write each file to the LogosWebsite target path
4. Verify all 9 files exist after copying

**Verification**:
- All 9 target files exist and are non-empty
- `diff` between source and target for each file shows no differences
- Existing LogosWebsite output/implement.md is NOT modified

---

### Phase 6: Update LogosWebsite CLAUDE.md [COMPLETED]

**Estimated effort**: 15 minutes
**Status**: [IMPLEMENTING]

**Objectives**:
1. Add Multi-Task Creation Standards section to LogosWebsite CLAUDE.md

**Source of truth**: `/home/benjamin/.config/nvim/.claude/CLAUDE.md` (lines 156-179)

**Files to modify**:
- `/home/benjamin/Projects/Logos/LogosWebsite/.claude/CLAUDE.md` - Insert Multi-Task Creation Standards section

**Steps**:
1. Read the LogosWebsite CLAUDE.md
2. Identify insertion point: between the Skill-to-Agent Mapping section and the Rules References section (after line ~137, before line ~138)
3. Insert the Multi-Task Creation Standards section, matching the nvim version exactly (with reference to `.claude/docs/reference/standards/multi-task-creation-standard.md`)
4. Verify no other sections were disturbed

**Verification**:
- `grep -c 'Multi-Task Creation Standards' /home/benjamin/Projects/Logos/LogosWebsite/.claude/CLAUDE.md` should return 1
- `grep -c '^## ' /home/benjamin/Projects/Logos/LogosWebsite/.claude/CLAUDE.md` should be exactly 1 more than before (was 14, now 15)

---

## Dependencies

- All phases are independent and can be executed in any order
- Phases 1-4 are logically related (plan status fixes) and should ideally be done together
- Phase 5 (copy files) has no dependencies on other phases
- Phase 6 (CLAUDE.md update) has a soft dependency on Phase 5 (the standard it references should exist first)

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Sed patterns break on LogosWebsite-specific plan formatting | Medium | Using same dual-pattern approach that works in nvim; verification catches failures |
| Overwriting web-specific file content in shared skills | High | Only modifying plan-status sed blocks within skills; NOT touching web-routing, web-agents, or context files |
| Unpadded `{N}` vs padded `{NNN}` in path references | Low | Intentionally keeping LogosWebsite's unpadded convention; all new code uses `${task_number}` not `${padded_num}` |
| Missing `docs/reference/` parent directories | Low | Using `mkdir -p` before writing files |
| CLAUDE.md section insertion disrupts existing content | Low | Using Edit tool with precise old_string matching; verifying section count before and after |

## Success Criteria

- [ ] All 4 implementation skills in LogosWebsite use dual-pattern sed (bullet + non-bullet) for plan status updates
- [ ] All 4 implementation skills have grep verification for COMPLETED and PARTIAL status updates
- [ ] skill-neovim-implementation has preflight IMPLEMENTING and postflight COMPLETED/PARTIAL plan file updates (previously missing entirely)
- [ ] implement.md command has Checkpoint 5 defensive verification
- [ ] 9 missing files copied from nvim to LogosWebsite
- [ ] LogosWebsite CLAUDE.md has Multi-Task Creation Standards section
- [ ] No web-specific files modified
- [ ] All path references use unpadded `${task_number}` (LogosWebsite convention)
