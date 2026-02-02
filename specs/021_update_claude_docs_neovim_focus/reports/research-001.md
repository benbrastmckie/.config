# Research Report: Task #21

**Task**: 21 - update_claude_docs_neovim_focus
**Started**: 2026-02-02T12:00:00Z
**Completed**: 2026-02-02T12:30:00Z
**Effort**: 2-4 hours
**Dependencies**: None
**Sources/Inputs**: Codebase analysis (Grep, Glob, Read)
**Artifacts**: specs/21_update_claude_docs_neovim_focus/reports/research-001.md
**Standards**: report-format.md, subagent-return.md

## Executive Summary

- Found 587 Lean references across 88 files, plus 372 ProofChecker/theorem/proof/Mathlib references across 78 files
- System has been partially migrated: Neovim skills/agents exist, Lean skills/agents removed, but documentation/context files retain Lean references
- High-priority files: README.md (31 refs), docs/architecture/system-overview.md (13 refs), routing tables in multiple files
- Key changes: Update CLAUDE.md routing tables, remove Lean MCP tool references, update ProofChecker examples to Neovim examples
- Lean-specific context directories (project/lean4/, project/logic/, project/math/) have already been removed

## Context & Scope

This research identifies all .claude/ files containing Lean/theorem/proof/Mathlib references that need updating to reflect the Neovim configuration focus. The goal is systematic documentation updates to replace Lean examples with Neovim examples and ensure accuracy.

### Current State

The system has been **partially migrated**:

**Already Complete:**
- Neovim skills exist: `skill-neovim-research`, `skill-neovim-implementation`
- Neovim agents exist: `neovim-research-agent.md`, `neovim-implementation-agent.md`
- Neovim context exists: `.claude/context/project/neovim/` directory
- Lean skills removed: No `skill-lean-*` directories exist
- Lean agents removed: No `lean-*-agent.md` files exist
- Lean context directories removed: No `project/lean4/`, `project/logic/`, `project/math/`

**Remaining Issues:**
- Documentation still references Lean extensively
- Routing tables still include Lean language option
- MCP tool references for lean-lsp tools remain
- Examples use ProofChecker/Lean scenarios
- CLAUDE.md still describes "Lean 4 theorem proving"

## Findings

### File Categorization by Priority

#### HIGH PRIORITY (Core documentation, visible to users)

| File | Lean Refs | Issue |
|------|-----------|-------|
| `.claude/README.md` | 31 | Main architecture doc describes "Lean 4 theorem proving" extensively |
| `.claude/CLAUDE.md` | ~50 | Already updated to Neovim in system-reminder but may need verification |
| `.claude/docs/architecture/system-overview.md` | 13 | Shows lean-research-agent, skill-lean-* in examples |
| `.claude/context/core/routing.md` | 44 | Routing table includes "lean" language option that no longer exists |
| `.claude/context/core/orchestration/routing.md` | 44 | Duplicate routing table with Lean |
| `.claude/context/index.md` | 2 | References Lean in loading examples |

#### MEDIUM PRIORITY (Implementation details, affect agent behavior)

| File | Lean Refs | Issue |
|------|-----------|-------|
| `.claude/context/core/patterns/blocked-mcp-tools.md` | 10 | Documents lean_diagnostic_messages and lean_file_outline - entire file is Lean-specific |
| `.claude/context/core/patterns/mcp-tool-recovery.md` | 10 | lean-lsp tool recovery patterns - entire file is Lean-specific |
| `.claude/context/core/orchestration/delegation.md` | 8 | Examples use lean-implementation-agent |
| `.claude/context/core/standards/task-management.md` | 15 | Uses Lean task examples |
| `.claude/context/core/standards/error-handling.md` | 12 | References lean-lsp-mcp errors |
| `.claude/context/core/formats/return-metadata-file.md` | 17 | Examples use Lean research scenarios |
| `.claude/docs/guides/user-installation.md` | 20 | Lean installation/configuration instructions |
| `.claude/docs/guides/permission-configuration.md` | 26 | Lean MCP permission examples |

#### LOW PRIORITY (Examples/templates that can use any domain)

| File | Refs | Issue |
|------|------|-------|
| `.claude/docs/examples/learn-flow-example.md` | 42 | Uses Lean file examples - can be rewritten for Neovim |
| `.claude/docs/examples/research-flow-example.md` | 12 | Uses Lean research scenario |
| `.claude/context/project/processes/research-workflow.md` | 20 | Lean-specific research patterns |
| `.claude/context/core/templates/thin-wrapper-skill.md` | 9 | Template uses Lean skill examples |
| `.claude/context/core/formats/frontmatter.md` | 10 | Frontmatter examples use Lean agents |
| `.claude/output/*.md` files | various | Output format examples use Lean scenarios |

### Files to DELETE (Lean-Specific, No Longer Needed)

These files are entirely Lean-specific and should be removed:

1. `.claude/context/core/patterns/blocked-mcp-tools.md` - Documents lean-lsp bugs
2. `.claude/context/core/patterns/mcp-tool-recovery.md` - Lean MCP recovery patterns

### Routing Table Changes Needed

**Current routing (in multiple files):**
```
| lean | skill-lean-research | skill-lean-implementation |
| latex | skill-researcher | skill-latex-implementation |
| general | skill-researcher | skill-implementer |
| meta | skill-researcher | skill-implementer |
| markdown | skill-researcher | skill-implementer |
```

**Should be updated to:**
```
| neovim | skill-neovim-research | skill-neovim-implementation |
| latex | skill-researcher | skill-latex-implementation |
| typst | skill-researcher | skill-typst-implementation |
| general | skill-researcher | skill-implementer |
| meta | skill-researcher | skill-implementer |
| markdown | skill-researcher | skill-implementer |
```

### Settings.json Update

The `.claude/settings.json` file contains MCP server permissions for lean-lsp tools that should be removed.

### Example Replacement Patterns

| Lean Example | Neovim Replacement |
|--------------|-------------------|
| `lean-research-agent` | `neovim-research-agent` |
| `lean-implementation-agent` | `neovim-implementation-agent` |
| `skill-lean-research` | `skill-neovim-research` |
| `skill-lean-implementation` | `skill-neovim-implementation` |
| `Theories/*.lean` | `nvim/lua/**/*.lua` |
| `lake build` | `nvim --headless` |
| `lean_goal`, `lean_hover_info` | Neovim LSP commands |
| `ProofChecker` | `Neovim Configuration` |
| `theorem proving` | `configuration management` |
| `Mathlib` | `lazy.nvim/plugin ecosystem` |

## Decisions

1. **DELETE** Lean-specific files that have no Neovim equivalent (blocked-mcp-tools.md, mcp-tool-recovery.md)
2. **UPDATE** routing tables from `lean` to `neovim` across all files
3. **REWRITE** examples using Neovim/Lua patterns instead of Lean
4. **REMOVE** MCP tool references (lean_goal, lean_hover_info, etc.) since Neovim doesn't use MCP
5. **KEEP** LaTeX and Typst support intact (not affected by this change)

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Breaking existing workflows | Test each command after updates |
| Missing files in update | Use grep/glob patterns to verify completeness |
| Inconsistent examples | Create consistent Neovim example set first, then apply |
| Over-deletion | Only delete files that are 100% Lean-specific |

## Appendix

### Search Queries Used

```bash
# Primary search for Lean references
grep -r '\b(lean|Lean|LEAN)\b' .claude/

# ProofChecker and theorem references
grep -r '\b(ProofChecker|theorem|proof|Mathlib)\b' .claude/

# MCP tool references
grep -r '\b(lean_goal|lean_hover|lean_search|lean_loogle)\b' .claude/

# Lean file patterns
grep -r '\b(Theories/|\.lean\b|lean4|Lean 4)\b' .claude/

# Lake build references
grep -r '\b(lake|Lake|LAKE)\b' .claude/
```

### File Count Summary

| Pattern | Files | Occurrences |
|---------|-------|-------------|
| lean/Lean/LEAN | 88 | 587 |
| ProofChecker/theorem/proof/Mathlib | 78 | 372 |
| lean-lsp tools | 22 | ~100 |
| Theories/\.lean | 49 | ~200 |
| lake/Lake | 18 | ~50 |

### Complete File List (Lean References)

**Core Files (>10 refs):**
1. `.claude/README.md` - 31 refs
2. `.claude/context/core/orchestration/routing.md` - 44 refs
3. `.claude/docs/examples/learn-flow-example.md` - 42 refs
4. `.claude/docs/guides/permission-configuration.md` - 26 refs
5. `.claude/docs/guides/user-installation.md` - 20 refs
6. `.claude/context/project/processes/research-workflow.md` - 20 refs
7. `.claude/context/core/standards/task-management.md` - 15 refs
8. `.claude/output/implement.md` - 14 refs
9. `.claude/commands/learn.md` - 13 refs
10. `.claude/docs/architecture/system-overview.md` - 13 refs
11. `.claude/docs/examples/research-flow-example.md` - 12 refs
12. `.claude/context/core/standards/error-handling.md` - 12 refs
13. `.claude/skills/skill-learn/SKILL.md` - 11 refs
14. `.claude/commands/review.md` - 11 refs

**Medium Files (5-10 refs):**
- `.claude/context/core/patterns/blocked-mcp-tools.md` - 10 refs
- `.claude/context/core/patterns/mcp-tool-recovery.md` - 10 refs
- `.claude/context/core/formats/frontmatter.md` - 10 refs
- `.claude/context/core/architecture/system-overview.md` - 10 refs
- `.claude/context/core/templates/thin-wrapper-skill.md` - 9 refs
- (plus ~20 more files with 5-9 refs each)

**Low Files (1-4 refs):**
- ~50 files with 1-4 references each
