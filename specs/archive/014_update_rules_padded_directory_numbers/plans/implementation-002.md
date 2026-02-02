# Implementation Plan: Task #14

**Task**: Update rules to define 3-digit padded directory numbering standard
**Version**: 002
**Created**: 2026-02-02 (Revised)
**Language**: meta
**Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
**Research Reports**: [research-001.md](../reports/research-001.md)

## Overview

Update `artifact-formats.md` and `state-management.md` rules to define the standard for 3-digit zero-padded directory names (`{NNN}_{SLUG}`) while keeping task numbers unpadded in TODO.md, state.json, and commit messages. This revision incorporates exact line numbers from research and adds a third phase for CLAUDE.md updates.

## Phases

### Phase 1: Update artifact-formats.md Placeholder Table

**Estimated effort**: 10 minutes
**Status**: [COMPLETED]

**Objectives**:
1. Modify placeholder conventions table to clarify `{NNN}` is used for both directories AND artifact versions
2. Update "Key distinction" explanation

**Files to modify**:
- `.claude/rules/artifact-formats.md` - Lines 11-20

**Steps**:
1. Update line 13 - Change `{N}` examples from `{N}_{SLUG}` to remove directory context:
   - Old: `| \`{N}\` | Unpadded integer | Task numbers, counts | \`389\`, \`task 389:\`, \`{N}_{SLUG}\` |`
   - New: `| \`{N}\` | Unpadded integer | Task numbers in text, commits | \`389\`, \`task 389:\` |`

2. Update line 14 - Expand `{NNN}` usage to include directories:
   - Old: `| \`{NNN}\` | 3-digit padded | Artifact versions | \`001\`, \`research-001.md\` |`
   - New: `| \`{NNN}\` | 3-digit padded | Directory numbers, artifact versions | \`014\`, \`research-001.md\`, \`{NNN}_{SLUG}\` |`

3. Update lines 20-21 - Revise "Key distinction" note:
   - Old: `**Key distinction**: Task numbers (\`{N}\`) are unpadded because they grow indefinitely. Artifact versions (\`{NNN}\`) are padded because they rarely exceed 999 per task.`
   - New: `**Key distinction**: Task numbers in text and JSON (\`{N}\`) remain unpadded for readability. Directory names and artifact versions (\`{NNN}\`) use 3-digit zero-padding for proper lexicographic sorting.`

**Verification**:
- Grep for `{N}_{SLUG}` should return 0 matches in artifact-formats.md (except in path templates that haven't been updated yet)
- Table clearly shows `{NNN}_{SLUG}` is the directory pattern

---

### Phase 2: Update artifact-formats.md Path Templates

**Estimated effort**: 10 minutes
**Status**: [COMPLETED]

**Objectives**:
1. Update all directory path templates from `{N}_{SLUG}` to `{NNN}_{SLUG}`

**Files to modify**:
- `.claude/rules/artifact-formats.md` - Lines 24, 58, 109, 136

**Steps**:
1. Line 24 - Update Research Reports location:
   - Old: `**Location**: \`specs/{N}_{SLUG}/reports/research-{NNN}.md\``
   - New: `**Location**: \`specs/{NNN}_{SLUG}/reports/research-{NNN}.md\``

2. Line 58 - Update Implementation Plans location:
   - Old: `**Location**: \`specs/{N}_{SLUG}/plans/implementation-{NNN}.md\``
   - New: `**Location**: \`specs/{NNN}_{SLUG}/plans/implementation-{NNN}.md\``

3. Line 109 - Update Implementation Summaries location:
   - Old: `**Location**: \`specs/{N}_{SLUG}/summaries/implementation-summary-{DATE}.md\``
   - New: `**Location**: \`specs/{NNN}_{SLUG}/summaries/implementation-summary-{DATE}.md\``

4. Line 136 - Update Error Reports location:
   - Old: `**Location**: \`specs/{N}_{SLUG}/reports/error-report-{DATE}.md\``
   - New: `**Location**: \`specs/{NNN}_{SLUG}/reports/error-report-{DATE}.md\``

**Verification**:
- All 4 path templates use `specs/{NNN}_{SLUG}/` prefix
- `grep -c '{N}_{SLUG}' .claude/rules/artifact-formats.md` returns 0

---

### Phase 3: Update state-management.md Artifact Paths

**Estimated effort**: 10 minutes
**Status**: [COMPLETED]

**Objectives**:
1. Update artifact linking examples
2. Update directory creation pattern

**Files to modify**:
- `.claude/rules/state-management.md` - Lines 91, 210, 216, 223, 232, 249-250, 256

**Steps**:
1. Line 91 - Update example artifact path in state.json Entry:
   - Old: `"path": "specs/334_task_slug_here/reports/research-001.md",`
   - New: `"path": "specs/334_task_slug_here/reports/research-001.md",`
   - (Note: 334 is already 3 digits, no change needed here - but add a comment)

2. Lines 207-224 - Update Artifact Linking section examples:
   - Line 210: `- **Research**: [specs/{N}_{SLUG}/reports/research-001.md]` → `[specs/{NNN}_{SLUG}/reports/research-001.md]`
   - Line 216: `- **Plan**: [specs/{N}_{SLUG}/plans/implementation-001.md]` → `[specs/{NNN}_{SLUG}/plans/implementation-001.md]`
   - Line 223: `- **Summary**: [specs/{N}_{SLUG}/summaries/...]` → `[specs/{NNN}_{SLUG}/summaries/...]`

3. Line 232 - Update Directory Creation pattern:
   - Old: `specs/{NUMBER}_{SLUG}/`
   - New: `specs/{NNN}_{SLUG}/`

4. Lines 247-257 - Update Correct/Incorrect Pattern bash examples:
   - Line 249: `mkdir -p "specs/${task_num}_${slug}/reports"` → add comment about printf %03d
   - Line 250: `write "specs/${task_num}_${slug}/reports/..."` → same
   - Line 256: Update incorrect pattern example

5. Add implementation note after line 232:
   ```
   **Note**: Directory numbers use 3-digit zero-padding (e.g., `014_task_name`).
   Use `printf "%03d" $task_num` for path construction. Task numbers 1000+ will
   naturally have 4 digits.
   ```

**Verification**:
- All artifact linking examples use `{NNN}_{SLUG}` pattern
- Directory creation section shows padded format
- Bash examples include padding guidance

---

### Phase 4: Update CLAUDE.md Artifact Paths Section

**Estimated effort**: 5 minutes
**Status**: [COMPLETED]

**Objectives**:
1. Update the "Artifact Paths" section in .claude/CLAUDE.md to use `{NNN}` for directories

**Files to modify**:
- `.claude/CLAUDE.md` - Lines 40-45 (Artifact Paths section)

**Steps**:
1. Find and update the Artifact Paths section:
   - Old pattern: `specs/{N}_{SLUG}/`
   - New pattern: `specs/{NNN}_{SLUG}/`

2. Ensure the legend clarifies:
   - `{N}` = unpadded task number (for text references)
   - `{NNN}` = 3-digit padded (for directory names and artifact versions)

**Verification**:
- CLAUDE.md Artifact Paths section matches the updated rules files

---

## Dependencies

None - this is the foundational standards update for the padded directory migration.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Inconsistent terminology | Medium | Clear distinction between `{N}` (text) and `{NNN}` (directory) |
| Missed path templates | Low | Grep verification at end of each phase |

## Success Criteria

- [ ] artifact-formats.md placeholder table shows `{NNN}` for directories
- [ ] artifact-formats.md all 4 path templates use `{NNN}_{SLUG}`
- [ ] state-management.md artifact linking examples use `{NNN}_{SLUG}`
- [ ] state-management.md directory creation shows padded format with printf note
- [ ] .claude/CLAUDE.md Artifact Paths section updated
- [ ] `grep -r '{N}_{SLUG}' .claude/rules/` returns 0 matches
- [ ] `{N}` remains unpadded for TODO.md entries, state.json values, and commit messages
