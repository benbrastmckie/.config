# Research Report: Task #22

**Task**: 22 - review_claude_directory_neovim_improvements
**Started**: 2026-02-02
**Completed**: 2026-02-02
**Effort**: 2-3 hours (implementation)
**Dependencies**: None (research-only)
**Sources/Inputs**: Codebase analysis, Grep searches, file review
**Artifacts**: This report
**Standards**: report-format.md

## Executive Summary

- **61 files** still contain Lean/lean references in `.claude/context/`
- **19 files** still reference "ProofChecker" (old project name)
- **context/README.md** is severely outdated - references non-existent directories (lean4/, logic/, math/, physics/)
- Neovim context (14 files in `project/neovim/`) is comprehensive and well-structured
- Several documentation files need updates to replace Lean examples with Neovim examples
- Core infrastructure is correctly updated for Neovim routing

## Context and Scope

This research examined the `.claude/context/` directory structure to identify remaining improvements needed after tasks 19, 20, and 21 adapted the system from Lean 4 theorem proving to Neovim configuration management.

### Files Examined
- All 116 files in `.claude/context/`
- 9 agents in `.claude/agents/`
- 16 skills in `.claude/skills/`
- Documentation guides in `.claude/docs/`

## Findings

### 1. Context README.md is Severely Outdated

**File**: `.claude/context/README.md`

This file still references directories that no longer exist:
- `lean4/` - Lean 4 domain knowledge (DELETED)
- `logic/` - Logic domain knowledge (DELETED)
- `math/` - Math domain knowledge (DELETED)
- `physics/` - Physics domain knowledge (DELETED)

**Current project/ structure**:
```
project/
├── hooks/           (NEW - wezterm integration)
├── latex/           (exists)
├── meta/            (exists)
├── neovim/          (NEW - comprehensive)
├── processes/       (exists)
├── repo/            (exists)
└── typst/           (exists)
```

**Impact**: Critical - this is the primary README for context organization.

### 2. Lean References in 61 Context Files

**Categories of Lean references**:

1. **Routing tables** (4 files):
   - `core/templates/command-template.md` - references `skill-lean-{operation}`
   - `core/orchestration/orchestration-reference.md` - uses lean routing examples
   - `core/orchestration/architecture.md` - mentions `lean-implementation-agent`
   - `core/routing.md` - correctly updated (no Lean)

2. **Format standards** (4 files):
   - `core/formats/plan-format.md` - has `Lean Intent: false` field
   - `core/formats/report-format.md` - has "Project Context (Lean only)" section
   - `core/formats/frontmatter.md` - references "non-Lean tasks"
   - `core/formats/command-output.md` - may have examples

3. **Domain patterns** (2 files):
   - `project/meta/domain-patterns.md` - has entire "Formal Verification Domain Pattern" section
   - `project/meta/context-revision-guide.md` - uses Lean as example

4. **CI workflow** (1 file):
   - `core/standards/ci-workflow.md` - references Lean files, Mathlib, lakefile.lean

5. **LaTeX/Typst documentation context** (8 files):
   - These legitimately reference Lean for cross-referencing Lean source code
   - `project/latex/standards/notation-conventions.md` - Lean cross-references
   - `project/typst/standards/notation-conventions.md` - Lean identifiers
   - These may need review but could be preserved if LaTeX/Typst docs are still used

6. **Schema files** (2 files):
   - `core/schemas/subagent-frontmatter.yaml` - blocks lakefile.lean writes
   - `core/schemas/frontmatter-schema.json` - references lean-lsp-mcp tools

### 3. ProofChecker References in 19 Context Files

Files still mention "ProofChecker" as the project name:
- `core/orchestration/architecture.md` - "ProofChecker implements..."
- `project/meta/domain-patterns.md` - "ProofChecker-Specific" section
- Many `core/standards/` files reference "ProofChecker Development Team"

### 4. Neovim Context is Comprehensive

The `project/neovim/` directory (14 files) is well-structured:

```
neovim/
├── README.md                    # Directory overview
├── domain/
│   ├── lua-patterns.md         # Lua idioms
│   ├── plugin-ecosystem.md     # lazy.nvim, plugins
│   ├── lsp-overview.md         # LSP concepts
│   └── neovim-api.md           # vim.* API (237 lines)
├── patterns/
│   ├── plugin-spec.md          # lazy.nvim specs
│   ├── keymap-patterns.md      # vim.keymap.set
│   ├── autocommand-patterns.md # vim.api.nvim_create_autocmd
│   └── ftplugin-patterns.md    # after/ftplugin
├── standards/
│   ├── lua-style-guide.md      # Coding conventions
│   └── testing-patterns.md     # plenary.nvim
├── tools/
│   ├── lazy-nvim-guide.md      # lazy.nvim usage (291 lines)
│   ├── treesitter-guide.md     # Tree-sitter
│   └── telescope-guide.md      # Telescope (291 lines)
└── templates/
    ├── plugin-template.md       # Plugin spec template
    └── ftplugin-template.md     # ftplugin template
```

**Assessment**: Comprehensive coverage, good structure, follows existing patterns.

### 5. Skills/Agents Correctly Updated

Routing in skills/agents is correctly updated:
- `skill-neovim-research` and `skill-neovim-implementation` exist
- `neovim-research-agent` and `neovim-implementation-agent` exist
- `core/routing.md` correctly maps `neovim` language to skills
- CLAUDE.md routing tables are correct

**Issue**: `skill-learn/SKILL.md` still has Lean-specific examples and file patterns.

### 6. Index.md is Mostly Updated

`context/index.md` has been updated with Neovim references but still contains some dated references in the consolidation notes section.

### 7. Documentation Guides Need Updates

Files in `.claude/docs/guides/` reference Lean patterns:
- `creating-commands.md` - lean routing examples
- `creating-agents.md` - lean agent examples
- `creating-skills.md` - lean skill examples
- `research-flow-example.md` - uses Lean research as example

## Recommendations

### Priority 1: Critical Updates (Must Fix)

1. **Update context/README.md**
   - Remove references to lean4/, logic/, math/, physics/
   - Add hooks/ directory
   - Update project structure to current state

2. **Update core/formats/plan-format.md**
   - Remove or rename "Lean Intent" field
   - Update examples to use Neovim

3. **Update core/formats/report-format.md**
   - Remove "Project Context (Lean only)" section
   - Or generalize to "Domain Context (when applicable)"

4. **Update core/standards/ci-workflow.md**
   - Replace Lean file triggers with Neovim patterns
   - Update language-based defaults table

### Priority 2: Important Updates (Should Fix)

5. **Update project/meta/domain-patterns.md**
   - Replace "Formal Verification Domain Pattern (ProofChecker-Specific)" with "Neovim Configuration Domain Pattern"
   - Update examples throughout

6. **Update core/orchestration/architecture.md**
   - Replace "ProofChecker implements" with "The system implements"
   - Update agent examples from lean-* to neovim-*

7. **Update core/templates/command-template.md**
   - Replace lean routing examples with neovim

8. **Update skill-learn/SKILL.md**
   - Replace Lean file examples with Neovim file examples
   - Update language detection patterns

### Priority 3: Nice to Have

9. **Update docs/guides/ examples**
   - Replace Lean examples with Neovim throughout
   - Update research-flow-example.md

10. **Review LaTeX/Typst notation files**
    - If still used for Lean documentation, keep
    - If not, remove Lean cross-reference sections

11. **Update schema files**
    - Remove lean-lsp-mcp tool references from frontmatter-schema.json
    - Remove lakefile.lean from blocked paths in subagent-frontmatter.yaml

### Priority 4: Maintenance (Optional)

12. **Replace "ProofChecker Development Team" attribution**
    - Update to "Neovim Config Development Team" or remove

13. **Review index.md consolidation notes**
    - Remove or update Task 246 references that mention old structure

## Potential Improvements to Neovim Context

While comprehensive, the Neovim context could be enhanced with:

1. **Debugging guide** - Adding context for nvim debugging workflows
2. **Color scheme patterns** - Common colorscheme customization patterns
3. **Session management** - Patterns for session/workspace management
4. **Performance profiling** - Using `--startuptime` and profiling tools
5. **Migration patterns** - For users migrating from Vimscript

## Decisions

1. LaTeX/Typst Lean cross-references should be reviewed - if no longer creating Lean documentation, these sections can be removed
2. The "Lean Intent" field in plan formats should be removed as it's no longer relevant

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Breaking existing workflows | Review each file change individually |
| Missing Lean references | Use grep to verify all references removed |
| Context budget impact | Files being updated are documentation, not execution-critical |

## Summary Statistics

| Category | Count |
|----------|-------|
| Files with Lean references | 61 |
| Files with ProofChecker references | 19 |
| Priority 1 updates needed | 4 files |
| Priority 2 updates needed | 4 files |
| Priority 3 updates needed | ~8 files |
| Neovim context files (complete) | 14 files |

## Appendix

### Search Queries Used

```bash
# Find Lean references
grep -rn "lean\|Lean\|lean4" .claude/context/

# Find ProofChecker references
grep -rn "ProofChecker" .claude/context/

# List project directories
find .claude/context/project -type d

# Count Neovim context files
find .claude/context/project/neovim -type f | wc -l
```

### Files Requiring Updates (Complete List)

**Priority 1**:
- .claude/context/README.md
- .claude/context/core/formats/plan-format.md
- .claude/context/core/formats/report-format.md
- .claude/context/core/standards/ci-workflow.md

**Priority 2**:
- .claude/context/project/meta/domain-patterns.md
- .claude/context/core/orchestration/architecture.md
- .claude/context/core/templates/command-template.md
- .claude/skills/skill-learn/SKILL.md

**Priority 3**:
- .claude/docs/guides/creating-commands.md
- .claude/docs/guides/creating-agents.md
- .claude/docs/guides/creating-skills.md
- .claude/docs/examples/research-flow-example.md
- .claude/context/core/schemas/frontmatter-schema.json
- .claude/context/core/schemas/subagent-frontmatter.yaml
- .claude/context/core/orchestration/orchestration-reference.md
- .claude/context/project/meta/context-revision-guide.md
