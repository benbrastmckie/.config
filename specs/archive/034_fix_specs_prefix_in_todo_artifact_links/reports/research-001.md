# Research Report: Task #42

**Task**: Fix specs/ prefix in TODO.md artifact links
**Date**: 2026-02-05
**Focus**: Investigate all files that write artifact paths to TODO.md or .return-meta.json, identify which include the incorrect specs/ prefix, and determine the correct fix pattern.

## Summary

TODO.md artifact links incorrectly include the `specs/` prefix in link targets (e.g., `(specs/041_slug/reports/research-001.md)`). Since TODO.md itself resides inside `specs/`, links should be relative to that directory (e.g., `(041_slug/reports/research-001.md)`). The bug has two root causes: (1) agents write `specs/`-prefixed paths in `.return-meta.json` artifacts, and (2) skill postflight code and documentation templates pass these paths verbatim into TODO.md Edit operations without stripping the prefix.

## Findings

### Finding 1: Current TODO.md Exhibits the Bug

Confirmed in `specs/TODO.md` (lines 22-36), all artifact links include the `specs/` prefix:

```markdown
- **Summary**: [implementation-summary-20260204.md](specs/041_fix_leanls_lsp_client_exit_error/summaries/implementation-summary-20260204.md)
- **Research**: [research-001.md](specs/041_fix_leanls_lsp_client_exit_error/reports/research-001.md)
- **Plan**: [implementation-003.md](specs/041_fix_leanls_lsp_client_exit_error/plans/implementation-003.md)
```

Since TODO.md is at `specs/TODO.md`, these links resolve to `specs/specs/041_...` from the project root, which is incorrect.

### Finding 2: Agent Metadata Files Write specs/-Prefixed Paths

All agents instruct their metadata file artifacts to use `specs/`-prefixed paths. This is by design since agent artifact paths are "relative from project root" per the return-metadata-file.md schema (line 82: `path: string | Yes | Relative path from project root`). The agents correctly write paths like:

```json
"path": "specs/{NNN}_{SLUG}/reports/research-{NNN}.md"
```

This is **correct for state.json** (which lives at the project root) but **incorrect when passed verbatim to TODO.md** (which lives inside `specs/`).

### Finding 3: Eight Agent Files Write specs/-Prefixed Artifact Paths

All agent files in `/home/benjamin/.config/.claude/agents/` contain artifact path examples with the `specs/` prefix:

| Agent File | Line | Path Pattern |
|------------|------|-------------|
| `general-research-agent.md` | 243 | `specs/{N}_{SLUG}/reports/research-{NNN}.md` |
| `neovim-research-agent.md` | 248 | `specs/{N}_{SLUG}/reports/research-{NNN}.md` |
| `planner-agent.md` | 284 | `specs/{N}_{SLUG}/plans/implementation-{NNN}.md` |
| `general-implementation-agent.md` | 267 | `specs/{N}_{SLUG}/summaries/implementation-summary-{DATE}.md` |
| `neovim-implementation-agent.md` | 215 | `specs/{N}_{SLUG}/summaries/implementation-summary-{DATE}.md` |
| `latex-implementation-agent.md` | 291 | `specs/{N}_{SLUG}/summaries/implementation-summary-{DATE}.md` |
| `typst-implementation-agent.md` | 267 | `specs/{N}_{SLUG}/summaries/implementation-summary-{DATE}.md` |
| `meta-builder-agent.md` | 483 | `specs/TODO.md` (not an artifact link issue) |

**Note**: These agent paths are correct for their purpose (project-root-relative). The fix should NOT change agent behavior. Instead, the stripping should happen at the consumer side (skill postflight).

### Finding 4: Eight Skill Files Pass Artifact Paths Verbatim to TODO.md

The skill postflight stages read `artifact_path` from `.return-meta.json` and use it directly in TODO.md Edit operations:

| Skill | Stage | TODO.md Link Pattern | Location |
|-------|-------|---------------------|----------|
| `skill-researcher` | Stage 8 | `[research-{NNN}.md]({artifact_path})` | Line 222 |
| `skill-neovim-research` | Stage 8 | (abbreviated, same pattern) | Implicit |
| `skill-planner` | Stage 8 | `[implementation-{NNN}.md]({artifact_path})` | Line 229 |
| `skill-implementer` | Stage 8 | `[implementation-summary-{DATE}.md]({artifact_path})` | Line 323 |
| `skill-typst-implementation` | Section 5 | `[implementation-summary-{DATE}.md]({artifact_path})` | Line 279 |
| `skill-latex-implementation` | Section 5 | `[implementation-summary-{DATE}.md]({artifact_path})` | Line 280 |
| `skill-neovim-implementation` | Stage 8 | (abbreviated, same pattern) | Implicit |
| `skill-status-sync` | Operation: artifact_link | `[research-{NNN}.md]({path})` | Lines 207-209 |

### Finding 5: Two Rules Files Document the Incorrect Pattern

**state-management.md** (lines 231-247) - Artifact Linking section shows:
```markdown
- **Research**: [specs/{NNN}_{SLUG}/reports/research-001.md]
- **Plan**: [specs/{NNN}_{SLUG}/plans/implementation-001.md]
- **Summary**: [specs/{NNN}_{SLUG}/summaries/implementation-summary-20260108.md]
```

**inline-status-update.md** (lines 187-199) - Adding Artifact Links section shows:
```markdown
- **Research**: [research-001.md](specs/{NNN}_{SLUG}/reports/research-001.md)
- **Plan**: [implementation-001.md](specs/{NNN}_{SLUG}/plans/implementation-001.md)
- **Summary**: [implementation-summary-{DATE}.md](specs/{NNN}_{SLUG}/summaries/implementation-summary-{DATE}.md)
```

### Finding 6: Two Workflow Documentation Files Also Show the Pattern

**research-workflow.md** (line 236): Shows `{report_path}` being added to TODO.md without stripping.
**planning-workflow.md** (line 207): Shows `{plan_path}` being added to TODO.md without stripping.

These are process documentation files. They do not directly execute code but instruct agents on how to link artifacts. They contain the same conceptual issue.

### Finding 7: return-metadata-file.md Examples All Use specs/ Prefix

The schema file at `.claude/context/core/formats/return-metadata-file.md` has 8 examples using `specs/`-prefixed paths in artifact definitions (lines 27, 226, 255, 289, 323, 357, 390, 440). These are correct since they represent the agent-written paths (relative to project root). No change needed here.

### Finding 8: Parent .claude Directory Has Slightly Older Copies

The files at `/home/benjamin/.config/.claude/` (parent config directory) contain slightly older versions of the same files with the same `specs/` prefix issue but using `{N}` instead of `{NNN}` in some templates. These should be fixed too, or will naturally be fixed when synced with the nvim versions.

## Root Cause Analysis

The bug occurs at the boundary between two path conventions:

1. **Agent convention**: Artifact paths are relative to project root (include `specs/` prefix). This is correct because agents operate at the project root level and state.json (also at project root) needs these paths.

2. **TODO.md convention**: Links in TODO.md should be relative to TODO.md's location (which is `specs/TODO.md`). Since TODO.md lives inside `specs/`, links should omit the `specs/` prefix.

The skill postflight code is the bridge between these two conventions. It reads the agent's project-root-relative path from `.return-meta.json` and should strip the `specs/` prefix before using it in TODO.md Edit operations.

## Recommendations

### Fix Pattern

Add a path transformation in each skill's postflight code, immediately after reading `artifact_path` from the metadata file and before any TODO.md Edit operation:

```bash
# Strip specs/ prefix for TODO.md links (TODO.md is inside specs/)
todo_link_path="${artifact_path#specs/}"
```

Then use `$todo_link_path` instead of `$artifact_path` in the TODO.md Edit format string.

**Important**: Continue using the original `$artifact_path` (with `specs/` prefix) for:
- state.json artifact entries (project-root-relative)
- Any other project-root-relative operations

### Files to Fix (Categorized)

**Category 1: Skill Postflight Code (8 files)** -- Primary fixes

These are the executable specifications that agents follow during postflight. Each needs the `todo_link_path="${artifact_path#specs/}"` pattern added.

1. `/home/benjamin/.config/.claude/skills/skill-researcher/SKILL.md` - Stage 8 (line 222)
2. `/home/benjamin/.config/.claude/skills/skill-neovim-research/SKILL.md` - Stage 8 (link pattern implicit)
3. `/home/benjamin/.config/.claude/skills/skill-planner/SKILL.md` - Stage 8 (line 229)
4. `/home/benjamin/.config/.claude/skills/skill-implementer/SKILL.md` - Stage 8 (line 323)
5. `/home/benjamin/.config/.claude/skills/skill-typst-implementation/SKILL.md` - Section 5 (line 279)
6. `/home/benjamin/.config/.claude/skills/skill-latex-implementation/SKILL.md` - Section 5 (line 280)
7. `/home/benjamin/.config/.claude/skills/skill-neovim-implementation/SKILL.md` - Stage 8 (link pattern implicit)
8. `/home/benjamin/.config/.claude/skills/skill-status-sync/SKILL.md` - Operation: artifact_link (lines 207-209)

**Category 2: Rules/Pattern Files (2 files)** -- Template corrections

These document the TODO.md linking patterns that skills/agents reference:

1. `/home/benjamin/.config/nvim/.claude/rules/state-management.md` - Lines 231-247 (Artifact Linking section)
2. `/home/benjamin/.config/nvim/.claude/context/core/patterns/inline-status-update.md` - Lines 187-199 (Adding Artifact Links section)

**Category 3: Workflow Documentation (2 files)** -- Documentation corrections

These describe the workflow process:

1. `/home/benjamin/.config/nvim/.claude/context/project/processes/research-workflow.md` - Line 236
2. `/home/benjamin/.config/nvim/.claude/context/project/processes/planning-workflow.md` - Line 207

### Detailed Fix for Each Category

**Category 1 - Skill Postflight (example for skill-researcher Stage 8)**:

Before (line 222):
```markdown
- **Research**: [research-{NNN}.md]({artifact_path})
```

After:
```markdown
**Strip specs/ prefix for TODO.md links** (TODO.md is inside specs/):
```bash
todo_link_path="${artifact_path#specs/}"
```

Then use in TODO.md Edit:
```markdown
- **Research**: [research-{NNN}.md]({todo_link_path})
```

**Category 2 - Rules/Pattern Files (state-management.md)**:

Before (lines 231-247):
```markdown
- **Research**: [specs/{NNN}_{SLUG}/reports/research-001.md]
- **Plan**: [specs/{NNN}_{SLUG}/plans/implementation-001.md]
- **Summary**: [specs/{NNN}_{SLUG}/summaries/implementation-summary-20260108.md]
```

After:
```markdown
- **Research**: [research-001.md]({NNN}_{SLUG}/reports/research-001.md)
- **Plan**: [implementation-001.md]({NNN}_{SLUG}/plans/implementation-001.md)
- **Summary**: [implementation-summary-{DATE}.md]({NNN}_{SLUG}/summaries/implementation-summary-{DATE}.md)
```

**Category 2 - inline-status-update.md (lines 187-199)**:

Before:
```markdown
- **Research**: [research-001.md](specs/{NNN}_{SLUG}/reports/research-001.md)
- **Plan**: [implementation-001.md](specs/{NNN}_{SLUG}/plans/implementation-001.md)
- **Summary**: [implementation-summary-{DATE}.md](specs/{NNN}_{SLUG}/summaries/implementation-summary-{DATE}.md)
```

After:
```markdown
- **Research**: [research-001.md]({NNN}_{SLUG}/reports/research-001.md)
- **Plan**: [implementation-001.md]({NNN}_{SLUG}/plans/implementation-001.md)
- **Summary**: [implementation-summary-{DATE}.md]({NNN}_{SLUG}/summaries/implementation-summary-{DATE}.md)
```

### Existing TODO.md Entries

Existing TODO.md entries with the incorrect `specs/` prefix should also be corrected as part of the implementation. This is a one-time cleanup of historical data.

## Decisions

1. **Fix at the consumer (skill postflight), not the producer (agent)**. Agent paths should remain project-root-relative since they are also used for state.json and other root-level operations.
2. **Use shell parameter expansion** (`${artifact_path#specs/}`) rather than `sed` or other tools for simplicity and robustness.
3. **Fix both the code templates and the documentation** to ensure new skills/agents follow the correct pattern.
4. **Clean up existing TODO.md entries** as part of the implementation to fix historical data.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Links break for entries without specs/ prefix | Low - all current entries have the prefix | The `${var#specs/}` expansion is a no-op if prefix is absent |
| Agent changes conflict with skill changes | None - agents are not being modified | Only skill postflight and documentation are changed |
| Parent .claude/ directory gets out of sync | Medium - could re-introduce bug | Fix both copies, or establish sync mechanism |
| Edge case: artifact_path is empty | Low - already guarded by `if [ -n "$artifact_path" ]` | Existing guards sufficient |

## Appendix

### Search Queries Used
- `Glob: .claude/skills/skill-*.md` - Skill file discovery
- `Grep: specs/.*reports/research|specs/.*plans/implementation` in TODO.md - Bug confirmation
- `Grep: "path".*specs/` in agents directory - Agent path patterns
- `Grep: specs/{NNN}.*reports/research` in state-management.md and inline-status-update.md - Rule template patterns
- `diff` between parent and nvim .claude directories - Sync check

### File Inventory

Total files requiring changes: **12**

| # | File | Type | Changes Needed |
|---|------|------|----------------|
| 1 | skill-researcher/SKILL.md | Skill | Add todo_link_path stripping, update TODO.md Edit |
| 2 | skill-neovim-research/SKILL.md | Skill | Add todo_link_path stripping, update TODO.md Edit |
| 3 | skill-planner/SKILL.md | Skill | Add todo_link_path stripping, update TODO.md Edit |
| 4 | skill-implementer/SKILL.md | Skill | Add todo_link_path stripping, update TODO.md Edit |
| 5 | skill-typst-implementation/SKILL.md | Skill | Add todo_link_path stripping, update TODO.md Edit |
| 6 | skill-latex-implementation/SKILL.md | Skill | Add todo_link_path stripping, update TODO.md Edit |
| 7 | skill-neovim-implementation/SKILL.md | Skill | Add todo_link_path stripping, update TODO.md Edit |
| 8 | skill-status-sync/SKILL.md | Skill | Update artifact_link format strings |
| 9 | state-management.md | Rule | Fix Artifact Linking section examples |
| 10 | inline-status-update.md | Pattern | Fix Adding Artifact Links section |
| 11 | research-workflow.md | Doc | Fix artifact link description |
| 12 | planning-workflow.md | Doc | Fix plan link description |

### Additional Cleanup
- Existing TODO.md entries (tasks 40, 41) need `specs/` prefix removed from links
