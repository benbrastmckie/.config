# Research Report: Task #43

**Task**: Fix web language routing gaps
**Date**: 2026-02-05
**Focus**: Phase 4 gaps and remaining incomplete phases in web language routing implementation (LogosWebsite task 3)

## Summary

The LogosWebsite task 3 ("Add web language routing") was partially implemented. Phase 1 core routing is mostly done (6 of 8 items fully complete, 3 files have `web` but are missing `typst`). Phases 2, 3, and 4 were never started. The total remaining work spans 14 specific changes across 12 files. All changes are additive (new table rows or list entries), so risk is minimal.

## Findings

### Current Implementation Status

An exhaustive audit of the LogosWebsite `.claude/` directory reveals the following status for each planned phase of task 3:

#### Phase 1: Core Routing Infrastructure (6/8 COMPLETE, 2 PARTIAL)

| File | Item | Web | Typst | Status |
|------|------|-----|-------|--------|
| `.claude/rules/state-management.md` (A7) | Language enum line 69 | Present | Present | DONE |
| `.claude/commands/task.md` (A5) | Keyword detection line 112 | Present | N/A | DONE |
| `.claude/CLAUDE.md` (A6) | Language-Based Routing table line 55 | Present | Present | DONE |
| `.claude/context/core/routing.md` (A1) | Primary routing table line 14 | Present | **MISSING** | PARTIAL |
| `.claude/commands/research.md` (A2) | Research routing line 53 | Present | **MISSING** | PARTIAL |
| `.claude/commands/implement.md` (A3) | Implement routing line 69 | Present | **MISSING** | PARTIAL |
| `.claude/skills/skill-orchestrator/SKILL.md` (A4) | Orchestrator table line 46 | Present | Present | DONE |
| `.claude/context/core/templates/command-template.md` (A8) | Template table line 49 | Present | Present | DONE |

#### Phase 2: Skill Trigger Updates (0/2 COMPLETE)

| File | Item | Status |
|------|------|--------|
| `.claude/skills/skill-researcher/SKILL.md` (B1) | Trigger: `"general", "meta", or "markdown"` on line 32 | Missing `"web"` and `"latex"` |
| `.claude/skills/skill-implementer/SKILL.md` (B2) | Trigger: `"general", "meta", or "markdown"` on line 33 | Missing `"web"` |

**Note on skill-researcher**: The trigger condition says `"general", "meta", or "markdown"` but the actual routing table in `research.md` routes `latex` and `web` to this skill too. The trigger text should match the routing reality.

#### Phase 3: Documentation Updates (0/7 COMPLETE)

| File | Item | What is Missing |
|------|------|-----------------|
| `.claude/docs/guides/user-guide.md` (C3) | Language Routing table lines 563-569 | Missing `web` row (has lean, meta, latex, typst, general) |
| `.claude/context/core/standards/ci-workflow.md` (C4) | Language-Based Defaults lines 66-72 | Missing `web` and `typst` rows |
| `.claude/context/core/standards/task-management.md` (C5) | Language enum line 38 | Uses `neovim|markdown|general|python|shell|json|meta` -- missing `latex`, `typst`, `web` |
| `.claude/context/core/standards/task-management.md` (C5) | Quality checklist line 235 | Same outdated language list |
| `.claude/context/project/processes/research-workflow.md` (C6) | Routing Rules table lines 52-57 | Missing `web`, `latex`, `typst` rows (has neovim, markdown, python, general) |
| `.claude/context/project/processes/implementation-workflow.md` (C7) | Routing Rules table lines 67-73 | Missing `web`, `meta` rows (has neovim, markdown, latex, typst, general) |
| `.claude/context/core/orchestration/routing.md` (B4) | Deprecated Language->Agent table lines 72-77 | Missing `web`, `latex`, `typst`, `meta` rows |
| `.claude/context/core/orchestration/orchestration-core.md` (B5) | Command->Agent Mapping | Missing `web` in the language-based entries |

#### Phase 4: Pre-existing Gap Fixes (0/3 COMPLETE)

| File | Item | Status |
|------|------|--------|
| `.claude/context/core/routing.md` | Add `typst` row to routing table | **MISSING** |
| `.claude/commands/research.md` | Add `typst` to language groups | **MISSING** |
| `.claude/commands/implement.md` | Add `typst` entry | **MISSING** |

### Additional Gaps Discovered Beyond Original Plan

During the audit, I found additional inconsistencies not listed in the original Phase 4:

1. **user-guide.md references `lean` instead of `neovim`**: Line 565 lists `lean` as a language while the routing system uses `neovim`. This was noted in the original research report but not addressed in any phase.

2. **task-management.md is severely outdated**: The language enum includes `python|shell|json` which are not recognized routing languages. It is missing `latex`, `typst`, and `web`.

3. **research-workflow.md references `python`**: The routing table includes `python` (which is not a recognized language in the system) but omits `latex`, `typst`, `web`, and `meta`.

4. **ci-workflow.md missing `typst`**: The CI defaults table has `lean`, `meta`, `markdown`, `general` but is missing `typst`, `latex`, and `web`.

5. **skill-researcher trigger conditions omit `latex`**: The routing tables route `latex` to `skill-researcher` for research, but the skill's own trigger text only lists `"general", "meta", or "markdown"`.

6. **Deprecated routing.md has stale entries**: The deprecated file references `python` and `markdown` agents but is missing `meta`, `latex`, `typst`, and `web`.

### Risk Assessment

All required changes are **additive** -- adding new rows to existing tables or new entries to existing lists. No existing routing entries need to be modified. The risk of breaking existing functionality is negligible.

The only potential concern is the `typst` gap in the 3 primary routing files (`routing.md`, `research.md`, `implement.md`). If a `typst` task is created and routed through these files, the routing would silently fall through to the default `general` handler rather than reaching `skill-typst-implementation`. However, the orchestrator's routing table (`SKILL.md`) correctly includes `typst`, which provides a safety net for most routing paths.

## Recommendations

### Priority 1: Fix Phase 4 Gaps (typst in 3 core routing files)

These are the most impactful fixes because they affect active routing logic:

1. **`.claude/context/core/routing.md`**: Add `| typst | skill-researcher | skill-typst-implementation |` row between `latex` and `general`.

2. **`.claude/commands/research.md`**: Change line 53 from:
   ```
   | `general`, `meta`, `markdown`, `latex`, `web` | `skill-researcher` |
   ```
   to:
   ```
   | `general`, `meta`, `markdown`, `latex`, `typst`, `web` | `skill-researcher` |
   ```

3. **`.claude/commands/implement.md`**: Add a new row:
   ```
   | `typst` | `skill-typst-implementation` |
   ```
   between the `latex` and `general/meta/markdown/web` rows.

### Priority 2: Complete Phase 2 (Skill Trigger Updates)

4. **`.claude/skills/skill-researcher/SKILL.md`**: Change trigger condition from:
   ```
   - Task language is "general", "meta", or "markdown"
   ```
   to:
   ```
   - Task language is "general", "meta", "markdown", "latex", or "web"
   ```

5. **`.claude/skills/skill-implementer/SKILL.md`**: Change trigger condition from:
   ```
   - Task language is "general", "meta", or "markdown"
   ```
   to:
   ```
   - Task language is "general", "meta", "markdown", or "web"
   ```

### Priority 3: Complete Phase 3 (Documentation Updates)

6. **`.claude/docs/guides/user-guide.md`**: Add `web` row to Language Routing table.

7. **`.claude/context/core/standards/ci-workflow.md`**: Add `web` and `typst` rows to Language-Based Defaults.

8. **`.claude/context/core/standards/task-management.md`**: Update language enum in both locations (lines 38 and 235) to use `neovim|general|meta|markdown|latex|typst|web`.

9. **`.claude/context/project/processes/research-workflow.md`**: Add `web`, `latex`, `typst`, `meta` rows to Routing Rules table. Remove `python`.

10. **`.claude/context/project/processes/implementation-workflow.md`**: Add `web` and `meta` rows to Routing Rules table.

11. **`.claude/context/core/orchestration/routing.md`** (deprecated): Add `web`, `latex`, `typst`, `meta` rows. Remove `python`. Low priority since file is deprecated.

12. **`.claude/context/core/orchestration/orchestration-core.md`**: Verify web is reflected in Command->Agent Mapping.

### Priority 4: Fix Pre-existing Issues

13. **`.claude/docs/guides/user-guide.md`**: Change `lean` to `neovim` in Language Routing table, or confirm if this project uses `lean` as its language name.

14. **`.claude/context/core/standards/task-management.md`**: Remove `python|shell|json` from the language enum as these are not recognized routing languages.

## File Inventory Summary

| Priority | Files to Change | Changes Required |
|----------|----------------|------------------|
| P1 (Core routing gaps) | 3 files | Add `typst` to routing.md, research.md, implement.md |
| P2 (Skill triggers) | 2 files | Add `web` (and `latex`) to trigger conditions |
| P3 (Documentation) | 7 files | Add `web` and fix stale language references |
| P4 (Pre-existing) | 2 files | Fix `lean` vs `neovim`, remove `python|shell|json` |
| **Total** | **12 unique files** | **14 changes** |

## Exact File Paths

All files are relative to `/home/benjamin/Projects/Logos/LogosWebsite/`:

```
.claude/context/core/routing.md
.claude/commands/research.md
.claude/commands/implement.md
.claude/skills/skill-researcher/SKILL.md
.claude/skills/skill-implementer/SKILL.md
.claude/docs/guides/user-guide.md
.claude/context/core/standards/ci-workflow.md
.claude/context/core/standards/task-management.md
.claude/context/project/processes/research-workflow.md
.claude/context/project/processes/implementation-workflow.md
.claude/context/core/orchestration/routing.md
.claude/context/core/orchestration/orchestration-core.md
```

## References

- LogosWebsite task 3 research report: `/home/benjamin/Projects/Logos/LogosWebsite/specs/3_add_web_language_routing/reports/research-001.md`
- LogosWebsite task 3 implementation plan: `/home/benjamin/Projects/Logos/LogosWebsite/specs/3_add_web_language_routing/plans/implementation-001.md`
- LogosWebsite state.json: `/home/benjamin/Projects/Logos/LogosWebsite/specs/state.json` (task 3 status: "implementing")
- Adding domains guide: `/home/benjamin/Projects/Logos/LogosWebsite/.claude/docs/guides/adding-domains.md`

## Next Steps

1. Create an implementation plan (`/plan 43`) that addresses all 14 changes across 12 files
2. Group changes by priority tier for phased execution
3. Implementation is straightforward (all additive edits), estimated at 30-45 minutes
4. After implementation, verify with grep across `.claude/` for consistent `typst` and `web` presence in all routing tables
