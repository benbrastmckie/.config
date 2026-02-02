# Implementation Plan: Task #22

- **Task**: 22 - review_claude_directory_neovim_improvements
- **Status**: [COMPLETE]
- **Date**: 2026-02-02 (Revised)
- **Feature**: Update .claude/context/ directory from Lean to Neovim context
- **Estimated Hours**: 2-3 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [reports/research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-002.md (this file)
- **Type**: meta
- **Revision Note**: Removed CI workflow updates per user request

## Overview

This task updates the `.claude/context/` directory and related files to complete the transition from Lean 4 theorem proving to Neovim configuration management. The research report identified 61 files with Lean references and 19 files with ProofChecker references. Updates are organized by priority: critical format files and README first, then important routing and pattern files, and finally documentation examples.

### Changes from v001

- **Removed**: CI workflow update (`.claude/context/core/standards/ci-workflow.md`) per user feedback
- **Consolidated**: Phases 1 and 4 merged since CI workflow was the bulk of Phase 1's complexity
- **Reduced scope**: 4 phases instead of 5

### Research Integration

- Research report identified 4 Priority 1 files, 4 Priority 2 files, and 8 Priority 3 files requiring updates
- The context/README.md is severely outdated, referencing non-existent directories
- Neovim context (14 files in project/neovim/) is comprehensive and requires no changes
- Core routing infrastructure is already correctly updated

## Goals & Non-Goals

**Goals**:
- Update context/README.md to reflect current directory structure
- Remove or generalize Lean-specific fields from format standards
- Replace Lean examples with Neovim examples in routing and template files
- Replace ProofChecker references with generic project references

**Non-Goals**:
- Modifying the existing Neovim context files (already comprehensive)
- Removing LaTeX/Typst notation files (may still be relevant for other documentation)
- Adding new Neovim context files (this is a cleanup task, not expansion)
- Updating CI workflow (user explicitly does not need this)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Breaking existing workflows | Medium | Low | Review each file change individually, test commands after changes |
| Missing Lean references | Low | Medium | Use grep to verify all references removed after each phase |
| Context budget impact | Low | Low | Files being updated are documentation, not execution-critical |

## Implementation Phases

### Phase 1: Update Critical Format Files and README [COMPLETED]

**Goal**: Update core format standards and README that affect all plan and research operations

**Tasks**:
- [ ] Update `.claude/context/README.md` - remove lean4/, logic/, math/, physics/ references, add hooks/ directory, update to current project structure
- [ ] Update `.claude/context/core/formats/plan-format.md` - change "Lean Intent" field to "Domain Specific" or remove entirely
- [ ] Update `.claude/context/core/formats/report-format.md` - generalize "Project Context (Lean only)" section

**Timing**: 45 minutes

**Files to modify**:
- `.claude/context/README.md` - update directory structure
- `.claude/context/core/formats/plan-format.md` - remove Lean Intent field
- `.claude/context/core/formats/report-format.md` - generalize Lean-only section

**Verification**:
- Grep for "lean4" in modified files returns no matches
- context/README.md accurately reflects current project/ directory structure
- Plan metadata no longer requires Lean-specific fields

---

### Phase 2: Update Important Routing and Pattern Files [COMPLETED]

**Goal**: Update routing examples and domain patterns to use Neovim instead of Lean

**Tasks**:
- [ ] Update `.claude/context/project/meta/domain-patterns.md` - replace "Formal Verification Domain Pattern" with "Neovim Configuration Domain Pattern"
- [ ] Update `.claude/context/core/orchestration/architecture.md` - replace ProofChecker references with generic project references, update agent examples
- [ ] Update `.claude/context/core/templates/command-template.md` - replace lean routing examples with neovim
- [ ] Update `.claude/skills/skill-learn/SKILL.md` - replace Lean file examples with Neovim file examples

**Timing**: 1 hour

**Files to modify**:
- `.claude/context/project/meta/domain-patterns.md` - replace Lean domain pattern section
- `.claude/context/core/orchestration/architecture.md` - update ProofChecker references
- `.claude/context/core/templates/command-template.md` - update routing examples
- `.claude/skills/skill-learn/SKILL.md` - update file patterns

**Verification**:
- Grep for "ProofChecker" in modified files returns no matches
- Grep for "lean-implementation-agent" in modified files returns no matches
- Domain patterns reflect Neovim configuration use case

---

### Phase 3: Update Documentation and Schema Files [COMPLETED]

**Goal**: Update example documentation and schema files to use Neovim patterns instead of Lean

**Tasks**:
- [ ] Update `.claude/docs/guides/creating-commands.md` - replace lean routing examples
- [ ] Update `.claude/docs/guides/creating-agents.md` - replace lean agent examples
- [ ] Update `.claude/docs/guides/creating-skills.md` - replace lean skill examples
- [ ] Update `.claude/docs/examples/research-flow-example.md` - use Neovim research as example
- [ ] Update `.claude/context/core/schemas/frontmatter-schema.json` - remove lean-lsp-mcp tool references
- [ ] Update `.claude/context/core/schemas/subagent-frontmatter.yaml` - remove lakefile.lean from blocked paths
- [ ] Update `.claude/context/core/orchestration/orchestration-reference.md` - update routing examples
- [ ] Update `.claude/context/project/meta/context-revision-guide.md` - replace Lean examples

**Timing**: 1 hour

**Files to modify**:
- `.claude/docs/guides/creating-commands.md` - update routing examples
- `.claude/docs/guides/creating-agents.md` - update agent examples
- `.claude/docs/guides/creating-skills.md` - update skill examples
- `.claude/docs/examples/research-flow-example.md` - update research example
- `.claude/context/core/schemas/frontmatter-schema.json` - remove Lean tool references
- `.claude/context/core/schemas/subagent-frontmatter.yaml` - remove Lean blocked paths
- `.claude/context/core/orchestration/orchestration-reference.md` - update examples
- `.claude/context/project/meta/context-revision-guide.md` - update examples

**Verification**:
- Documentation examples reference neovim patterns, not lean
- Schema files no longer reference lean-lsp-mcp
- Grep for "lakefile.lean" returns no matches

---

### Phase 4: Final Verification and Cleanup [COMPLETED]

**Goal**: Verify all Lean references removed and documentation is consistent

**Tasks**:
- [ ] Run comprehensive grep for "lean" and "Lean" in .claude/context/
- [ ] Run comprehensive grep for "ProofChecker" in .claude/context/
- [ ] Review any remaining legitimate references (LaTeX/Typst cross-references)
- [ ] Update context/index.md if any consolidation notes reference old structure
- [ ] Create implementation summary

**Timing**: 30 minutes

**Verification**:
- Grep for "ProofChecker" in .claude/context/ returns 0 matches
- Grep for Lean references in core files returns 0 matches (LaTeX/Typst may have legitimate references)
- All modified files are syntactically valid

## Testing & Validation

- [ ] Run `/plan` on a test task to verify plan format works without Lean Intent field
- [ ] Run `/research` on a test task to verify report format works without Lean-only section
- [ ] Verify context/README.md accurately describes current directory structure
- [ ] Grep verification confirms no unintended Lean/ProofChecker references remain

## Artifacts & Outputs

- plans/implementation-001.md (original plan)
- plans/implementation-002.md (this file - revised plan)
- summaries/implementation-summary-YYYYMMDD.md (after completion)
- Updated files in .claude/context/ directory
- Updated files in .claude/docs/ directory
- Updated files in .claude/skills/ directory

## Rollback/Contingency

If changes break existing workflows:
1. Revert individual file changes using git checkout
2. Identify which specific change caused the issue
3. Create more targeted fix that preserves compatibility
4. Consider adding compatibility notes if field names changed
