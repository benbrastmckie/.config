# Implementation Plan: Task #43

- **Task**: 43 - Fix .claude/ agent system language routing gaps
- **Version**: 001
- **Created**: 2026-02-05
- **Language**: general
- **Status**: [COMPLETED]
- **Estimated Hours**: 2-3 hours
- **Standards File**: /home/benjamin/.config/nvim/.claude/CLAUDE.md
- **Research Reports**: [research-001.md](../reports/research-001.md)

## Overview

Fix inconsistencies in language routing across the `.claude/` agent system. The recognized routing languages for this project are: `neovim`, `general`, `meta`, `markdown`, `latex`, `typst`. Multiple files contain stale `lean` references (from a previous project), stale `python`/`shell`/`json` entries that are not valid routing languages, and missing `typst`/`latex`/`meta` entries in routing tables. This plan systematically updates all routing-related files to be consistent with each other and with the actual skill/agent inventory.

## Goals and Non-Goals

**Goals**:
- Make all routing tables consistent across commands, skills, orchestration docs, and workflow docs
- Replace stale `lean` references with `neovim` (the correct routing language name for this project)
- Remove non-routing languages (`python`, `shell`, `json`) from routing tables where they create false routing expectations
- Add missing `typst` entries to research routing tables
- Ensure trigger conditions in skills match the languages they actually handle

**Non-Goals**:
- Adding `web` language routing (not applicable to this project)
- Creating new skills or agents
- Changing the actual routing logic (only documentation/configuration alignment)
- Modifying files outside `.claude/` directory

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Changing a reference that is still valid | Medium | Verify each `lean` reference is stale, not a legitimate cross-reference to Lean-specific content in typst/latex domain docs |
| Breaking routing by editing command files | High | Only edit documentation/comments, not functional routing logic; test after each phase |
| Missing a file with stale routing | Low | Comprehensive grep search completed; plan covers all 15 identified gaps |

## Implementation Phases

### Phase 1: Fix Core Routing Files [COMPLETED]

**Goal**: Update the two primary routing reference files that other files derive from.

**Estimated effort**: 20 minutes

**Files to modify**:
- `.claude/context/core/routing.md` -- Add missing `typst`, `latex`, `meta` entries to Language -> Skill Routing table
- `.claude/context/core/orchestration/routing.md` -- Fix deprecated file's routing table: replace `python` with correct entries, add missing languages

**Steps**:

1. **Edit `.claude/context/core/routing.md`** (lines 7-14):
   - Current table is missing `typst` and `latex` rows
   - Add `typst` row: `| typst | skill-researcher | skill-typst-implementation |`
   - Add `latex` row: `| latex | skill-researcher | skill-latex-implementation |`
   - This makes the table match the orchestrator skill's table (which is already correct)

2. **Edit `.claude/context/core/orchestration/routing.md`** (lines 72-77):
   - Replace `python` row with `latex` row: `| latex | skill-researcher | latex-implementation-agent |`
   - Add `typst` row: `| typst | skill-researcher | typst-implementation-agent |`
   - Add `meta` row: `| meta | researcher | implementer |`
   - This brings the deprecated file in line (it is still referenced by some workflows)

**Verification**:
- Grep for "Language.*Skill Routing" in core/routing.md and verify 6 language rows exist
- Grep for the deprecated routing.md table and verify no `python` row remains

---

### Phase 2: Fix Command Routing Tables [COMPLETED]

**Goal**: Update `/research` and `/implement` command files to include all routing languages.

**Estimated effort**: 15 minutes

**Files to modify**:
- `.claude/commands/research.md` -- Add `typst` to language routing table
- `.claude/commands/implement.md` -- Add `typst` to language routing table

**Steps**:

1. **Edit `.claude/commands/research.md`** (lines 50-53):
   - Current table: `neovim -> skill-neovim-research`, `general, meta, markdown, latex -> skill-researcher`
   - Add `typst` to the second row: `general, meta, markdown, latex, typst`
   - Rationale: typst tasks use the general researcher (no typst-specific research skill exists)

2. **Edit `.claude/commands/implement.md`** (lines 65-69):
   - Current table: `neovim -> skill-neovim-implementation`, `latex -> skill-latex-implementation`, `general, meta, markdown -> skill-implementer`
   - Add row: `| typst | skill-typst-implementation |`
   - This matches the existing `skill-typst-implementation` skill

**Verification**:
- Read each command file and confirm all 6 routing languages appear in the routing table

---

### Phase 3: Fix Workflow Process Documentation [COMPLETED]

**Goal**: Update research-workflow.md and implementation-workflow.md to have complete, correct routing tables.

**Estimated effort**: 20 minutes

**Files to modify**:
- `.claude/context/project/processes/research-workflow.md` -- Fix routing table (remove `python`, add missing), fix `lean` error example
- `.claude/context/project/processes/implementation-workflow.md` -- Add `meta` to routing table

**Steps**:

1. **Edit `research-workflow.md`** (lines 52-57):
   - Remove `python` row
   - Add `latex` row: `| latex | researcher | Web search, documentation review |`
   - Add `typst` row: `| typst | researcher | Web search, documentation review |`
   - Add `meta` row: `| meta | researcher | Read, Grep, Glob |`
   - Add `general` row if missing

2. **Edit `research-workflow.md`** (lines 448-449):
   - Replace `lean` error example with `neovim`:
     - `Expected: language=neovim -> agent=neovim-research-agent`
     - `Got: language=neovim -> agent=researcher`

3. **Edit `implementation-workflow.md`** (lines 67-73):
   - Add `meta` row: `| meta | implementer | File operations, git |`
   - This makes it consistent with the implement command's routing table

**Verification**:
- Grep for `python` in both files -- should return no matches
- Grep for `lean` in research-workflow.md -- should return no matches
- Count routing table rows in each file -- should be 6 (one per language)

---

### Phase 4: Replace Stale `lean` References in Core Documentation [COMPLETED]

**Goal**: Replace `lean` with `neovim` in routing-related documentation where `lean` is used as a routing language name.

**Estimated effort**: 30 minutes

**Files to modify**:
- `.claude/rules/workflows.md` -- Fix `lean->lean-lsp` in research workflow diagram
- `.claude/context/core/standards/ci-workflow.md` -- Replace `lean` CI triggers with `neovim`-appropriate entries
- `.claude/context/core/orchestration/orchestrator.md` -- Replace `lean` examples with `neovim`
- `.claude/context/core/orchestration/state-management.md` -- Fix language enum and examples
- `.claude/context/core/orchestration/orchestration-reference.md` -- Fix `lean` in error example

**Steps**:

1. **Edit `rules/workflows.md`** (line 53):
   - Change `lean->lean-lsp` to `neovim->neovim-*`
   - This reflects the actual routing (neovim tasks go to neovim-research-agent or neovim-implementation-agent)

2. **Edit `ci-workflow.md`**:
   - Lines 35-36: Replace "Lean files (.lean)" with "Neovim Lua files (.lua)" and "Mathlib deps" with "Plugin dependencies (lazy-lock.json)"
   - Lines 60-61: Replace "Lean phases" with "Neovim phases" references
   - Line 68: Replace `lean` with `neovim` in language-based defaults table
   - Add `latex` and `typst` rows to the language-based defaults table

3. **Edit `orchestrator.md`**:
   - Lines 108, 197, 214: Change `lean` to `neovim` in examples
   - Line 247: Change `lean: lean-research-agent` to `neovim: neovim-research-agent`
   - Lines 821-825: Change `lean` routing example to `neovim` routing example

4. **Edit `state-management.md`**:
   - Line 75: Change `"language": "lean"` to `"language": "neovim"` in example
   - Line 93: Change language enum from `lean, general, meta, markdown, latex` to `neovim, general, meta, markdown, latex, typst`
   - Lines 147-148: Change `lean` task query example to `neovim`

5. **Edit `orchestration-reference.md`** (line 174):
   - Change `language=lean but agent=researcher` to `language=neovim but agent=researcher`

**Verification**:
- Grep for `\blean\b` across all modified files -- should return no matches in routing contexts
- Note: Some files in `.claude/context/project/typst/` and `.claude/context/project/latex/` legitimately reference Lean (mathematical content) -- these should NOT be changed

---

### Phase 5: Fix Skill Trigger Conditions and Language Enum [COMPLETED]

**Goal**: Update skill trigger conditions to list all languages they handle, and fix the task-management language enum.

**Estimated effort**: 20 minutes

**Files to modify**:
- `.claude/skills/skill-researcher/SKILL.md` -- Add `latex` and `typst` to trigger conditions
- `.claude/context/core/standards/task-management.md` -- Fix language enum to match routing reality

**Steps**:

1. **Edit `skill-researcher/SKILL.md`** (lines 31-33):
   - Current trigger: `Task language is "general", "meta", or "markdown"`
   - Change to: `Task language is "general", "meta", "markdown", "latex", or "typst"`
   - Rationale: The research command routes latex and typst tasks to skill-researcher

2. **Edit `task-management.md`** (line 38):
   - Current enum: `neovim|markdown|general|python|shell|json|meta`
   - Change to: `neovim|markdown|general|meta|latex|typst`
   - Rationale: `python`, `shell`, `json` are not routing languages; `latex` and `typst` are
   - Also update the "Missing Language Field" troubleshooting section (lines 277-285):
     - Remove `python`, `shell`, `json` options
     - Add `latex` and `typst` options

**Verification**:
- Read skill-researcher trigger conditions -- should list all 5 non-neovim languages
- Read task-management language enum -- should list exactly 6 languages matching routing tables

---

### Phase 6: Fix User Guide `lean` References [COMPLETED]

**Goal**: Update the user-facing guide to use `neovim` instead of `lean` throughout.

**Estimated effort**: 25 minutes

**Files to modify**:
- `.claude/docs/guides/user-guide.md` -- Replace `lean` routing references with `neovim`

**Steps**:

1. **Line 112**: Change `"Fix type mismatch error in Frame.lean"` to a neovim-appropriate example like `"Fix type mismatch error in lsp/init.lua"`

2. **Lines 116-117**: Change language detection keywords:
   - From: `lean, theorem, proof, lemma, Mathlib -> lean`
   - To: `neovim, plugin, keymap, lua, nvim -> neovim`

3. **Lines 188-189**: Change research language routing:
   - From: `lean tasks -> Uses Lean MCP tools (leansearch, loogle, leanfinder)`
   - To: `neovim tasks -> Uses Neovim-specific research agent`

4. **Lines 218-220**: Change plan example from Lean to neovim:
   - From: `Create Theories/Modal/Completeness.lean`
   - To: Neovim-appropriate example like `Create lua/neotex/plugins/new_feature.lua`

5. **Lines 268-269**: Change implement language routing:
   - From: `lean -> Lean-specific implementation with MCP tools`
   - To: `neovim -> Neovim-specific implementation agent`

6. **Lines 330-331**: Change review section:
   - From: `For Lean: sorry placeholders, axioms, build status`
   - To: `For Neovim: deprecated APIs, missing lazy-loading, keymap descriptions`

7. **Lines 365-371**: Replace `/lake` command section with note that it is not applicable, or remove entirely

8. **Lines 563-565**: Fix language routing table:
   - Change `lean` row to `neovim` with appropriate keywords
   - Fix detection keywords and tools columns for neovim

9. **Lines 625-631**: Fix MCP troubleshooting:
   - Change "Lean tools timeout" to Neovim-appropriate troubleshooting
   - Change `lake build` to `nvim --headless` verification

**Verification**:
- Grep for `\blean\b` in user-guide.md -- should return 0 matches in routing contexts
- Read the language routing table -- should list `neovim` not `lean`

---

### Phase 7: Validation and Cross-Check [COMPLETED]

**Goal**: Verify all routing tables are consistent across the entire `.claude/` directory.

**Estimated effort**: 15 minutes

**Steps**:

1. **Cross-reference audit**: For each routing language, verify it appears consistently:
   - `neovim`: research -> skill-neovim-research, implement -> skill-neovim-implementation
   - `latex`: research -> skill-researcher, implement -> skill-latex-implementation
   - `typst`: research -> skill-researcher, implement -> skill-typst-implementation
   - `general`: research -> skill-researcher, implement -> skill-implementer
   - `meta`: research -> skill-researcher, implement -> skill-implementer
   - `markdown`: research -> skill-researcher, implement -> skill-implementer

2. **Stale reference scan**:
   - `grep -ri '\blean\b' .claude/` -- Filter results to only routing-context files
   - `grep -ri '\bpython\b' .claude/` -- Should not appear in routing tables
   - `grep -ri '\bshell\b' .claude/` -- Should not appear in routing tables

3. **Document any remaining legitimate `lean` references**:
   - Files in `context/project/typst/` and `context/project/latex/` may legitimately reference Lean mathematical content
   - These should NOT be modified

**Verification**:
- All 6 languages appear in: core/routing.md, orchestrator SKILL.md, CLAUDE.md
- All command routing tables cover their relevant languages
- No stale `python`, `shell`, `json` remain in routing tables
- No stale `lean` remains in routing-context documentation

## Dependencies

- None (this is a documentation/configuration alignment task with no code dependencies)

## Testing and Validation

- [ ] All routing tables list exactly 6 languages: neovim, general, meta, markdown, latex, typst
- [ ] No stale `lean` references remain in routing-context files
- [ ] No stale `python`/`shell`/`json` remain in routing tables
- [ ] Skill trigger conditions match the languages routed to them
- [ ] CLAUDE.md routing table matches orchestrator skill routing table
- [ ] Command routing tables cover all languages they need to route
- [ ] User guide language routing section uses `neovim` not `lean`

## Artifacts and Outputs

- Modified routing documentation files (15+ files)
- This implementation plan: `specs/043_fix_web_language_routing_gaps/plans/implementation-001.md`

## Rollback/Contingency

All changes are to documentation/configuration markdown files. Rollback via `git checkout` of any modified files if issues arise. No functional code is modified.
