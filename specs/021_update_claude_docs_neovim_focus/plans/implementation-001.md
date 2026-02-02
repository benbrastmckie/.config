# Implementation Plan: Task #21

- **Task**: 21 - update_claude_docs_neovim_focus
- **Status**: [COMPLETED]
- **Effort**: 6-8 hours
- **Dependencies**: None
- **Research Inputs**: [specs/21_update_claude_docs_neovim_focus/reports/research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: meta
- **Lean Intent**: false

## Overview

Systematic update of .claude/ documentation to remove 587 Lean references across 88 files and 372 ProofChecker/theorem/proof references across 78 files. The system has been partially migrated (Neovim skills/agents exist, Lean removed), but documentation retains extensive Lean references. This plan organizes updates by priority: high-priority core files first, then medium-priority implementation files, then low-priority examples and templates.

### Research Integration

Research report (research-001.md) identified:
- 6 high-priority files requiring immediate attention (routing tables, main docs)
- 8 medium-priority files affecting agent behavior
- 74 low-priority files (examples, templates)
- 2 files to DELETE entirely (Lean-specific MCP tool docs)
- Complete replacement pattern mappings (lean -> neovim, ProofChecker -> Neovim Configuration)

## Goals & Non-Goals

**Goals**:
- Remove all Lean/ProofChecker references from .claude/ documentation
- Update routing tables from `lean` to `neovim` language option
- Replace Lean examples with Neovim equivalents
- Delete Lean-specific files that have no Neovim equivalent
- Ensure documentation accurately reflects stock Neovim configuration focus

**Non-Goals**:
- Modifying actual skill/agent implementations (already migrated)
- Updating files outside .claude/ directory
- Creating new Neovim-specific documentation (beyond replacing examples)
- Changing LaTeX/Typst support (unaffected by this change)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Missing files in update | Medium | Low | Use grep verification after each phase |
| Breaking agent routing | High | Low | Test routing after Phase 1 |
| Inconsistent examples | Medium | Medium | Use consistent replacement patterns from research |
| Over-deletion of content | Medium | Low | Only delete files confirmed 100% Lean-specific |

## Implementation Phases

### Phase 1: Delete Lean-Specific Files [COMPLETED]

**Goal**: Remove files that are entirely Lean-specific and have no Neovim equivalent.

**Tasks**:
- [ ] Delete `.claude/context/core/patterns/blocked-mcp-tools.md`
- [ ] Delete `.claude/context/core/patterns/mcp-tool-recovery.md`
- [ ] Update any files that reference these deleted files
- [ ] Verify no broken links remain

**Timing**: 30 minutes

**Files to modify**:
- `.claude/context/core/patterns/blocked-mcp-tools.md` - DELETE
- `.claude/context/core/patterns/mcp-tool-recovery.md` - DELETE
- Files referencing deleted content - UPDATE links

**Verification**:
- Grep for references to deleted files returns empty

---

### Phase 2: Update Core Documentation - README and System Overview [COMPLETED]

**Goal**: Update the two most visible core documentation files.

**Tasks**:
- [ ] Update `.claude/README.md` - replace 31 Lean references with Neovim equivalents
- [ ] Update `.claude/docs/architecture/system-overview.md` - replace 13 Lean references
- [ ] Replace ProofChecker project description with Neovim Configuration description
- [ ] Update skill/agent examples to use neovim-research-agent, neovim-implementation-agent
- [ ] Update file path examples (Theories/*.lean -> nvim/lua/**/*.lua)

**Timing**: 1.5 hours

**Files to modify**:
- `.claude/README.md` - Major rewrite of project description and examples
- `.claude/docs/architecture/system-overview.md` - Update agent and skill examples

**Verification**:
- Grep for "lean" in modified files returns 0 matches
- Grep for "ProofChecker" in modified files returns 0 matches

---

### Phase 3: Update Routing Tables [COMPLETED]

**Goal**: Update language-based routing configuration across all files.

**Tasks**:
- [ ] Update `.claude/context/core/routing.md` - replace lean routing with neovim
- [ ] Update `.claude/context/core/orchestration/routing.md` - same changes
- [ ] Verify routing table format: `neovim | skill-neovim-research | skill-neovim-implementation`
- [ ] Update `.claude/context/index.md` - fix Lean loading examples

**Timing**: 1 hour

**Files to modify**:
- `.claude/context/core/routing.md` - Update routing table
- `.claude/context/core/orchestration/routing.md` - Update routing table
- `.claude/context/index.md` - Update loading examples

**Verification**:
- All routing tables use `neovim` not `lean`
- Routing references skill-neovim-research and skill-neovim-implementation

---

### Phase 4: Update Medium-Priority Documentation [COMPLETED]

**Goal**: Update implementation documentation that affects agent behavior.

**Tasks**:
- [ ] Update `.claude/context/core/orchestration/delegation.md` - replace lean-implementation-agent examples
- [ ] Update `.claude/context/core/standards/task-management.md` - replace Lean task examples
- [ ] Update `.claude/context/core/standards/error-handling.md` - remove lean-lsp-mcp error references
- [ ] Update `.claude/context/core/formats/return-metadata-file.md` - replace Lean research examples

**Timing**: 1.5 hours

**Files to modify**:
- `.claude/context/core/orchestration/delegation.md`
- `.claude/context/core/standards/task-management.md`
- `.claude/context/core/standards/error-handling.md`
- `.claude/context/core/formats/return-metadata-file.md`

**Verification**:
- Grep for "lean" in modified files returns 0 matches

---

### Phase 5: Update Installation and Configuration Docs [COMPLETED]

**Goal**: Update user-facing installation and configuration documentation.

**Tasks**:
- [ ] Update `.claude/docs/guides/user-installation.md` - remove Lean installation instructions
- [ ] Update `.claude/docs/guides/permission-configuration.md` - remove Lean MCP permission examples
- [ ] Add Neovim-relevant configuration examples where appropriate

**Timing**: 1 hour

**Files to modify**:
- `.claude/docs/guides/user-installation.md`
- `.claude/docs/guides/permission-configuration.md`

**Verification**:
- No Lean-specific installation steps remain
- No lean-lsp MCP permissions documented

---

### Phase 6: Update Examples and Templates [COMPLETED]

**Goal**: Update low-priority example files with Neovim equivalents.

**Tasks**:
- [ ] Update `.claude/docs/examples/learn-flow-example.md` - rewrite with Neovim file examples
- [ ] Update `.claude/docs/examples/research-flow-example.md` - use Neovim research scenario
- [ ] Update `.claude/context/project/processes/research-workflow.md` - Neovim patterns
- [ ] Update `.claude/context/core/templates/thin-wrapper-skill.md` - Neovim skill examples
- [ ] Update `.claude/context/core/formats/frontmatter.md` - Neovim agent examples

**Timing**: 1.5 hours

**Files to modify**:
- `.claude/docs/examples/learn-flow-example.md`
- `.claude/docs/examples/research-flow-example.md`
- `.claude/context/project/processes/research-workflow.md`
- `.claude/context/core/templates/thin-wrapper-skill.md`
- `.claude/context/core/formats/frontmatter.md`

**Verification**:
- All examples use Neovim/Lua patterns
- No Lean file paths (*.lean, Theories/)

---

### Phase 7: Update Remaining Files and Final Verification [COMPLETED]

**Goal**: Address remaining files with Lean references and perform comprehensive verification.

**Tasks**:
- [ ] Update `.claude/output/*.md` files with Neovim output examples
- [ ] Update `.claude/commands/learn.md` - replace Lean file references
- [ ] Update `.claude/commands/review.md` - replace Lean references
- [ ] Update `.claude/skills/skill-learn/SKILL.md` - replace Lean examples
- [ ] Update `.claude/context/core/architecture/system-overview.md` if separate from Phase 2 file
- [ ] Run comprehensive grep for remaining Lean/ProofChecker references
- [ ] Fix any remaining references found

**Timing**: 1 hour

**Files to modify**:
- `.claude/output/*.md` files
- `.claude/commands/learn.md`
- `.claude/commands/review.md`
- `.claude/skills/skill-learn/SKILL.md`
- Any remaining files with Lean references

**Verification**:
- `grep -r '\blean\b' .claude/` returns 0 matches (case insensitive)
- `grep -r 'ProofChecker' .claude/` returns 0 matches
- `grep -r 'theorem' .claude/` returns 0 contextual matches
- `grep -r 'Mathlib' .claude/` returns 0 matches

## Testing & Validation

- [ ] Run comprehensive grep after each phase to verify removals
- [ ] Verify no broken internal links after file deletions (Phase 1)
- [ ] Confirm routing tables are syntactically correct
- [ ] Validate example code blocks are consistent with Neovim patterns
- [ ] Final grep verification: zero Lean/ProofChecker/Mathlib references

## Artifacts & Outputs

- plans/implementation-001.md (this file)
- summaries/implementation-summary-{DATE}.md (upon completion)

## Rollback/Contingency

Git provides full rollback capability. If updates break agent behavior:
1. Identify the breaking change via git diff
2. Revert specific commits as needed with `git revert`
3. All changes are atomic per phase, enabling granular rollback
