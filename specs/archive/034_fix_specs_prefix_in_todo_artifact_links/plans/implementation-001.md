# Implementation Plan: Task #42

**Date**: 2026-02-05
**Feature**: Fix specs/ prefix in TODO.md artifact links
**Status**: [IMPLEMENTING]
**Estimated Hours**: 1-2 hours
**Standards File**: /home/benjamin/.config/nvim/.claude/CLAUDE.md
**Research Reports**: [research-001.md](../reports/research-001.md)
**Type**: meta
**Lean Intent**: false

## Overview

TODO.md artifact links incorrectly include the `specs/` prefix in link targets (e.g., `(specs/041_slug/reports/research-001.md)`). Since TODO.md resides at `specs/TODO.md`, links should be relative to that directory (e.g., `(041_slug/reports/research-001.md)`). The fix has two parts: (1) update skill postflight code to strip the `specs/` prefix before writing TODO.md links, and (2) correct documentation/rule templates that show the wrong pattern. A final cleanup phase fixes existing TODO.md entries.

### Research Integration

The research report identified 12 files across 3 categories: 8 skill postflight files, 2 rules/pattern files, and 2 workflow documentation files. The root cause is that agents correctly write project-root-relative paths (with `specs/` prefix) in `.return-meta.json`, but skill postflight code passes these verbatim into TODO.md Edit operations without stripping the prefix. The fix should happen at the consumer side (skill postflight), not the producer side (agents).

## Goals & Non-Goals

**Goals**:
- Strip `specs/` prefix from artifact paths before writing to TODO.md in all 8 skill postflight stages
- Correct the 2 rules/pattern documentation files to show correct TODO.md link format
- Correct the 2 workflow documentation files to clarify path transformation
- Clean up existing TODO.md entries with incorrect `specs/` prefix

**Non-Goals**:
- Changing agent artifact path conventions (agents should keep writing project-root-relative paths)
- Modifying state.json artifact paths (state.json lives at project root, so `specs/` prefix is correct there)
- Changing the return-metadata-file.md schema

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Links break for entries without specs/ prefix | Low | Low | `${var#specs/}` is a no-op if prefix absent |
| Agent changes conflict with skill changes | None | None | Only skill postflight and documentation are changed |
| Missing a skill file | Low | Low | Research report enumerated all 8 skills via systematic search |
| Existing TODO.md entries missed during cleanup | Low | Low | Use grep to find all `specs/` prefixed links before cleanup |

## Implementation Phases

### Phase 1: Fix Skill Postflight Code (8 files) [COMPLETED]

**Goal**: Add `specs/` prefix stripping in all skill postflight stages before TODO.md Edit operations, so artifact links use paths relative to specs/ directory.

**Timing**: 0.5 hours

**Tasks**:
- [ ] Fix skill-researcher/SKILL.md - Stage 8 TODO.md link
- [ ] Fix skill-neovim-research/SKILL.md - Stage 8 TODO.md link
- [ ] Fix skill-planner/SKILL.md - Stage 8 TODO.md link
- [ ] Fix skill-implementer/SKILL.md - Stage 8 TODO.md link
- [ ] Fix skill-typst-implementation/SKILL.md - Section 5 TODO.md link
- [ ] Fix skill-latex-implementation/SKILL.md - Section 5 TODO.md link
- [ ] Fix skill-neovim-implementation/SKILL.md - Stage 8 TODO.md link
- [ ] Fix skill-status-sync/SKILL.md - Operation: artifact_link format strings

**Files to modify**:

1. `/home/benjamin/.config/.claude/skills/skill-researcher/SKILL.md` (line ~222)

   **Before** (line 222):
   ```markdown
   - **Research**: [research-{NNN}.md]({artifact_path})
   ```

   **After** - Add stripping instruction before TODO.md Edit, then use stripped path:
   ```markdown
   **Strip specs/ prefix for TODO.md** (TODO.md is inside specs/):
   ```
   ```
   todo_link_path="${artifact_path#specs/}"
   ```
   ```markdown
   - **Research**: [research-{NNN}.md]({todo_link_path})
   ```

2. `/home/benjamin/.config/.claude/skills/skill-neovim-research/SKILL.md`

   Apply the same pattern as skill-researcher. Find the TODO.md artifact link line and add the `todo_link_path` stripping before it, then use `{todo_link_path}` in the link.

3. `/home/benjamin/.config/.claude/skills/skill-planner/SKILL.md` (line ~229)

   **Before** (line 229):
   ```markdown
   - **Plan**: [implementation-{NNN}.md]({artifact_path})
   ```

   **After**:
   ```markdown
   **Strip specs/ prefix for TODO.md** (TODO.md is inside specs/):
   ```
   ```
   todo_link_path="${artifact_path#specs/}"
   ```
   ```markdown
   - **Plan**: [implementation-{NNN}.md]({todo_link_path})
   ```

4. `/home/benjamin/.config/.claude/skills/skill-implementer/SKILL.md` (line ~323)

   **Before** (line 323):
   ```markdown
   - **Summary**: [implementation-summary-{DATE}.md]({artifact_path})
   ```

   **After**:
   ```markdown
   **Strip specs/ prefix for TODO.md** (TODO.md is inside specs/):
   ```
   ```
   todo_link_path="${artifact_path#specs/}"
   ```
   ```markdown
   - **Summary**: [implementation-summary-{DATE}.md]({todo_link_path})
   ```

5. `/home/benjamin/.config/.claude/skills/skill-typst-implementation/SKILL.md` (line ~279)

   **Before** (line 279):
   ```markdown
   - Add summary artifact link: `- **Summary**: [implementation-summary-{DATE}.md]({artifact_path})`
   ```

   **After**:
   Add stripping instruction before this line, then:
   ```markdown
   - Add summary artifact link: `- **Summary**: [implementation-summary-{DATE}.md]({todo_link_path})`
   ```

6. `/home/benjamin/.config/.claude/skills/skill-latex-implementation/SKILL.md` (line ~280)

   Same pattern as skill-typst-implementation. The files are structurally identical.

7. `/home/benjamin/.config/.claude/skills/skill-neovim-implementation/SKILL.md`

   Apply the same pattern. Find the TODO.md summary artifact link and add the `todo_link_path` stripping before it.

8. `/home/benjamin/.config/.claude/skills/skill-status-sync/SKILL.md` (lines 207-209)

   **Before** (lines 207-209):
   ```markdown
   | research | `- **Research**: [research-{NNN}.md]({path})` |
   | plan | `- **Plan**: [implementation-{NNN}.md]({path})` |
   | summary | `- **Summary**: [implementation-summary-{DATE}.md]({path})` |
   ```

   **After** - Add stripping instruction before the table, then update all `{path}` references to `{todo_link_path}`:

   Add above the table:
   ```
   **Strip specs/ prefix** (TODO.md is inside specs/): `todo_link_path="${path#specs/}"`
   ```

   Then update table:
   ```markdown
   | research | `- **Research**: [research-{NNN}.md]({todo_link_path})` |
   | plan | `- **Plan**: [implementation-{NNN}.md]({todo_link_path})` |
   | summary | `- **Summary**: [implementation-summary-{DATE}.md]({todo_link_path})` |
   ```

**Verification**:
- Grep all 8 skill files for `{artifact_path}` or `{path}` in TODO.md link contexts -- should find zero occurrences
- Grep all 8 skill files for `todo_link_path` -- should find occurrences in each
- Grep all 8 skill files for `specs/` prefix stripping instruction -- should find occurrences in each

---

### Phase 2: Fix Rules and Pattern Documentation (2 files) [COMPLETED]

**Goal**: Correct the template examples in rules/pattern files so they show TODO.md links without the `specs/` prefix.

**Timing**: 0.25 hours

**Tasks**:
- [ ] Fix state-management.md Artifact Linking section (lines 231-247)
- [ ] Fix inline-status-update.md Adding Artifact Links section (lines 187-199)

**Files to modify**:

1. `/home/benjamin/.config/nvim/.claude/rules/state-management.md` (lines 231-247)

   **Before**:
   ```markdown
   ### Research Completion
   ```markdown
   - **Status**: [RESEARCHED]
   - **Research**: [specs/{NNN}_{SLUG}/reports/research-001.md]
   ```

   ### Plan Completion
   ```markdown
   - **Status**: [PLANNED]
   - **Plan**: [specs/{NNN}_{SLUG}/plans/implementation-001.md]
   ```

   ### Implementation Completion
   ```markdown
   - **Status**: [COMPLETED]
   - **Completed**: 2026-01-08
   - **Summary**: [specs/{NNN}_{SLUG}/summaries/implementation-summary-20260108.md]
   ```

   **After** - Remove `specs/` prefix from all link targets and use proper markdown link format `[text](target)`:
   ```markdown
   ### Research Completion
   ```markdown
   - **Status**: [RESEARCHED]
   - **Research**: [research-001.md]({NNN}_{SLUG}/reports/research-001.md)
   ```

   ### Plan Completion
   ```markdown
   - **Status**: [PLANNED]
   - **Plan**: [implementation-001.md]({NNN}_{SLUG}/plans/implementation-001.md)
   ```

   ### Implementation Completion
   ```markdown
   - **Status**: [COMPLETED]
   - **Completed**: 2026-01-08
   - **Summary**: [implementation-summary-20260108.md]({NNN}_{SLUG}/summaries/implementation-summary-20260108.md)
   ```

2. `/home/benjamin/.config/nvim/.claude/context/core/patterns/inline-status-update.md` (lines 187-199)

   **Before**:
   ```markdown
   - **Research**: [research-001.md](specs/{NNN}_{SLUG}/reports/research-001.md)
   - **Plan**: [implementation-001.md](specs/{NNN}_{SLUG}/plans/implementation-001.md)
   - **Summary**: [implementation-summary-{DATE}.md](specs/{NNN}_{SLUG}/summaries/implementation-summary-{DATE}.md)
   ```

   **After** - Remove `specs/` prefix from all link targets:
   ```markdown
   - **Research**: [research-001.md]({NNN}_{SLUG}/reports/research-001.md)
   - **Plan**: [implementation-001.md]({NNN}_{SLUG}/plans/implementation-001.md)
   - **Summary**: [implementation-summary-{DATE}.md]({NNN}_{SLUG}/summaries/implementation-summary-{DATE}.md)
   ```

**Verification**:
- Grep both files for `specs/{NNN}` in link targets -- should find zero occurrences
- Grep both files for `({NNN}_` in link targets -- should find occurrences

---

### Phase 3: Fix Workflow Documentation (2 files) [COMPLETED]

**Goal**: Update the workflow documentation to note that artifact paths need `specs/` prefix stripping before use in TODO.md links.

**Timing**: 0.25 hours

**Tasks**:
- [ ] Fix research-workflow.md artifact link description (line ~236)
- [ ] Fix planning-workflow.md plan link description (line ~207)

**Files to modify**:

1. `/home/benjamin/.config/nvim/.claude/context/project/processes/research-workflow.md` (line 236)

   **Before** (line 236):
   ```
       - Add **Research**: {report_path}
   ```

   **After** - Clarify that path needs specs/ prefix stripped for TODO.md:
   ```
       - Add **Research**: {report_path} (stripped of specs/ prefix for TODO-relative link)
   ```

2. `/home/benjamin/.config/nvim/.claude/context/project/processes/planning-workflow.md` (line 207)

   **Before** (line 207):
   ```
       - Add **Plan**: {plan_path}
   ```

   **After** - Clarify that path needs specs/ prefix stripped for TODO.md:
   ```
       - Add **Plan**: {plan_path} (stripped of specs/ prefix for TODO-relative link)
   ```

**Verification**:
- Grep both files for "stripped of specs/" -- should find one occurrence in each

---

### Phase 4: Clean Up Existing TODO.md Entries [COMPLETED]

**Goal**: Fix the existing incorrect `specs/` prefix in TODO.md links for tasks 40 and 41.

**Timing**: 0.25 hours

**Tasks**:
- [ ] Remove `specs/` prefix from task 41 Summary link
- [ ] Remove `specs/` prefix from task 41 Research links
- [ ] Remove `specs/` prefix from task 41 Plan link
- [ ] Remove `specs/` prefix from task 40 Summary link
- [ ] Remove `specs/` prefix from task 40 Research link
- [ ] Remove `specs/` prefix from task 40 Plan link

**Files to modify**:

1. `/home/benjamin/.config/nvim/specs/TODO.md`

   **Task 41 lines** (lines 23-26):

   **Before**:
   ```markdown
   - **Summary**: [implementation-summary-20260204.md](specs/041_fix_leanls_lsp_client_exit_error/summaries/implementation-summary-20260204.md)
   - **Research**: [research-001.md](specs/041_fix_leanls_lsp_client_exit_error/reports/research-001.md), [research-002.md](specs/041_fix_leanls_lsp_client_exit_error/reports/research-002.md)
   - **Plan**: [implementation-003.md](specs/041_fix_leanls_lsp_client_exit_error/plans/implementation-003.md)
   ```

   **After**:
   ```markdown
   - **Summary**: [implementation-summary-20260204.md](041_fix_leanls_lsp_client_exit_error/summaries/implementation-summary-20260204.md)
   - **Research**: [research-001.md](041_fix_leanls_lsp_client_exit_error/reports/research-001.md), [research-002.md](041_fix_leanls_lsp_client_exit_error/reports/research-002.md)
   - **Plan**: [implementation-003.md](041_fix_leanls_lsp_client_exit_error/plans/implementation-003.md)
   ```

   **Task 40 lines** (lines 34-37):

   **Before**:
   ```markdown
   - **Summary**: [implementation-summary-20260203.md](specs/040_standardize_multi_task_creation_patterns/summaries/implementation-summary-20260203.md)
   - **Research**: [research-001.md](specs/040_standardize_multi_task_creation_patterns/reports/research-001.md)
   - **Plan**: [implementation-001.md](specs/040_standardize_multi_task_creation_patterns/plans/implementation-001.md)
   ```

   **After**:
   ```markdown
   - **Summary**: [implementation-summary-20260203.md](040_standardize_multi_task_creation_patterns/summaries/implementation-summary-20260203.md)
   - **Research**: [research-001.md](040_standardize_multi_task_creation_patterns/reports/research-001.md)
   - **Plan**: [implementation-001.md](040_standardize_multi_task_creation_patterns/plans/implementation-001.md)
   ```

**Verification**:
- Grep TODO.md for `(specs/` -- should find zero occurrences
- All markdown links in TODO.md should resolve correctly from specs/ directory

---

## Testing & Validation

- [ ] All 8 skill files contain `todo_link_path` stripping pattern before TODO.md Edit operations
- [ ] All 8 skill files use `{todo_link_path}` (not `{artifact_path}` or `{path}`) in TODO.md link format strings
- [ ] state-management.md Artifact Linking section shows links without `specs/` prefix
- [ ] inline-status-update.md Adding Artifact Links section shows links without `specs/` prefix
- [ ] research-workflow.md notes specs/ prefix stripping for TODO.md links
- [ ] planning-workflow.md notes specs/ prefix stripping for TODO.md links
- [ ] TODO.md contains zero occurrences of `(specs/` in link targets
- [ ] State.json artifact paths still correctly use `specs/` prefix (no regression)

## Artifacts & Outputs

- 8 modified skill SKILL.md files with corrected TODO.md link generation
- 2 modified rules/pattern files with corrected link templates
- 2 modified workflow documentation files with clarified path handling
- 1 cleaned-up TODO.md with corrected historical links
- Total: 13 files modified (12 code/docs + 1 data cleanup)

## Rollback/Contingency

All changes are documentation-level edits to markdown files. If any change causes issues:
1. `git revert` the commit to restore all files
2. The `${var#specs/}` pattern is safe -- it is a no-op when the prefix is absent, so partial application cannot break existing links
3. No runtime code or compiled artifacts are affected
