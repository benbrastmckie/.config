# Implementation Plan: Task #31

**Task**: fix_plan_file_status_update_in_implement
**Version**: 001
**Created**: 2026-02-02
**Language**: meta

- **Date**: 2026-02-02
- **Feature**: Add plan file status verification to /implement GATE OUT and improve sed commands in implementation skills
- **Status**: [COMPLETED]
- **Estimated Hours**: 1.5-2.5 hours
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: [research-001.md](../reports/research-001.md)

## Overview

This task fixes a reliability gap where plan files are not consistently updated to `[COMPLETED]` status after implementation finishes. The fix adds a defensive verification step in `/implement` GATE OUT that checks and corrects plan file status, adds missing plan file update code to `skill-neovim-implementation`, and improves sed commands in all implementation skills with error checking and verification output.

## Phases

### Phase 1: Add Plan File Verification to implement.md GATE OUT

**Estimated effort**: 0.5 hours
**Status**: [COMPLETED]

**Objectives**:
1. Add defensive verification that checks plan file status matches task status
2. Auto-correct plan file if status mismatch detected
3. Support both bullet (`- **Status**:`) and non-bullet (`**Status**:`) patterns

**Files to modify**:
- `.claude/commands/implement.md` - Add step 4a after step 3 in CHECKPOINT 2: GATE OUT

**Steps**:
1. Read current implement.md GATE OUT section (lines 81-123)
2. Add new step 4a "Verify Plan File Status Updated" between steps 4 and the RETRY clause
3. Include grep verification and defensive sed update for both patterns
4. Add warning output when correction needed

**Verification**:
- Plan file check occurs only when result.status == "implemented"
- Both bullet and non-bullet Status patterns are handled
- Warning message logged when correction applied

---

### Phase 2: Add Plan File Updates to skill-neovim-implementation

**Estimated effort**: 0.5 hours
**Status**: [COMPLETED]

**Objectives**:
1. Add preflight plan file update (Stage 2) - set to `[IMPLEMENTING]`
2. Add postflight plan file update (Stage 7) - set to `[COMPLETED]`
3. Include verification output after update

**Files to modify**:
- `.claude/skills/skill-neovim-implementation/SKILL.md` - Add plan file updates to Stages 2 and 7

**Steps**:
1. Read current skill-neovim-implementation SKILL.md (already read, lines 64-81 for Stage 2, lines 163-181 for Stage 7)
2. Add plan file update code after state.json update in Stage 2
3. Add plan file update code with verification after state.json update in Stage 7
4. Support both bullet and non-bullet patterns

**Verification**:
- Preflight updates plan file to `[IMPLEMENTING]`
- Postflight updates plan file to `[COMPLETED]` with verification output
- Both patterns handled

---

### Phase 3: Improve sed Commands in Implementation Skills

**Estimated effort**: 0.5-1.5 hours
**Status**: [COMPLETED]

**Objectives**:
1. Add verification output after all plan file sed commands
2. Support both bullet and non-bullet Status patterns
3. Handle missing plan file gracefully with informational message

**Files to modify**:
- `.claude/skills/skill-implementer/SKILL.md` - Update Stage 7 sed commands (lines 266-272)
- `.claude/skills/skill-latex-implementation/SKILL.md` - Update Stage 7 sed commands
- `.claude/skills/skill-typst-implementation/SKILL.md` - Update Stage 7 sed commands

**Steps**:
1. Read skill-latex-implementation and skill-typst-implementation to find exact line numbers
2. Update skill-implementer Stage 7 plan file update (around lines 266-272):
   - Add second sed for non-bullet pattern
   - Add grep verification with success/failure output
   - Add handling for missing plan file
3. Apply same pattern to skill-latex-implementation
4. Apply same pattern to skill-typst-implementation

**Verification**:
- All three skills produce verification output after plan file update
- Both bullet and non-bullet patterns handled
- Missing plan file produces informational message (not error)

---

## Dependencies

- Phase 2 and Phase 3 can run in parallel
- Phase 1 depends on Phase 2 and Phase 3 only for validation (can be implemented independently)

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| sed command fails silently | Plan file left in wrong state | Add grep verification after sed |
| Plan file format varies | sed pattern doesn't match | Support both bullet and non-bullet patterns |
| Multiple plan file versions | Wrong file updated | Use `sort -V \| tail -1` to get latest |
| Plan file doesn't exist | Unnecessary error | Check file exists before updating; use info message not error |

## Success Criteria

- [ ] `/implement` GATE OUT verifies plan file status when task completes
- [ ] `skill-neovim-implementation` updates plan file in preflight and postflight
- [ ] All implementation skills produce verification output after plan file updates
- [ ] Both `- **Status**: [X]` and `**Status**: [X]` patterns are supported
- [ ] Missing plan file handled gracefully (info message, not error)
