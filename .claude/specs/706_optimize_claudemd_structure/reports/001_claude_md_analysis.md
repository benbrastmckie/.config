# CLAUDE.md Structure Analysis

## Metadata
- **Date**: 2025-11-14
- **Agent**: claude-md-analyzer
- **File Analyzed**: /home/benjamin/.config/CLAUDE.md
- **Threshold**: balanced (80 lines)
- **Report Type**: Structure Analysis and Bloat Detection

## Summary

- **Total Lines**: 964
- **Total Sections**: 24 (major sections)
- **Bloated Sections (>80 lines)**: 4
- **Sections Missing Metadata**: 15
- **Projected Savings**: ~437 lines (45.3% reduction)
- **Target Size**: 527 lines

## Section Analysis

| Section | Lines | Status | Recommendation |
|---------|-------|--------|----------------|
| Project Standards and Guidelines | 25 | Optimal | Keep inline |
| Testing Protocols | 39 | Optimal | Keep inline |
| Code Standards | 84 | **Bloated** | Extract to docs/ with summary |
| Directory Organization Standards | 231 | **Bloated** | Extract to docs/ with summary |
| Characteristics | 3 | Optimal | Keep inline |
| Examples | 3 | Optimal | Keep inline |
| When to Use | 2 | Optimal | Keep inline |
| Documentation | 40 | Optimal | Keep inline |
| Development Philosophy | 49 | Optimal | Keep inline |
| Adaptive Planning | 36 | Optimal | Keep inline |
| Adaptive Planning Configuration | 39 | Optimal | Keep inline |
| Development Workflow | 15 | Optimal | Keep inline |
| Hierarchical Agent Architecture | 93 | **Bloated** | Extract to docs/ with summary |
| State-Based Orchestration Architecture | 108 | **Bloated** | Extract to docs/ with summary |
| Project-Specific Commands | 61 | Moderate | Consider extraction |
| Quick Reference | 32 | Optimal | Keep inline |
| Documentation Policy | 25 | Optimal | Keep inline |
| Standards Discovery | 20 | Optimal | Keep inline |
| Notes | 6 | Optimal | Keep inline |

## Extraction Candidates

### High Priority (Bloated Sections)

1. **Code Standards** (84 lines) → `.claude/docs/reference/code-standards.md`
   - **Rationale**: Reference documentation belongs in reference directory
   - **Integration**: Create new file (no existing code-standards.md found)
   - **Summary Link**: Replace inline section with 2-3 line summary linking to reference doc
   - **Content**: General principles, language-specific standards, command architecture standards, development guides, internal link conventions

2. **Directory Organization Standards** (231 lines) → `.claude/docs/concepts/directory-organization.md`
   - **Rationale**: Architecture concept documentation, largest bloat section
   - **Integration**: Create new file (no existing directory-organization.md found)
   - **Summary Link**: Replace with 3-4 line overview linking to concepts doc
   - **Content**: Purpose, directory structure, decision matrices, anti-patterns, verification steps, references

3. **Hierarchical Agent Architecture** (93 lines) → `.claude/docs/concepts/hierarchical-agents.md`
   - **Rationale**: Architectural concept, already referenced in CLAUDE.md
   - **Integration**: File already referenced but does not exist - create new file
   - **Summary Link**: Replace with 2-3 line summary of key features and link
   - **Content**: Overview, key features, context reduction metrics, utilities, agent templates, command integration, validation

4. **State-Based Orchestration Architecture** (108 lines) → `.claude/docs/architecture/state-based-orchestration-overview.md`
   - **Rationale**: Comprehensive documentation file already exists
   - **Integration**: File already exists (verified) - update summary link only
   - **Summary Link**: Replace with 2-3 line overview of state machines and link to existing doc
   - **Content**: Already documented in existing file, just need to simplify inline reference

### Medium Priority (Moderate Sections)

5. **Project-Specific Commands** (61 lines) → `.claude/docs/reference/command-reference.md`
   - **Rationale**: Reference catalog, already exists and is referenced
   - **Integration**: Merge with existing command-reference.md or simplify inline listing
   - **Summary Link**: Replace detailed descriptions with simple list + link to reference
   - **Content**: Command names, one-line descriptions, link to comprehensive reference

## Integration Points

### `.claude/docs/concepts/`
- **Natural home for**: Hierarchical Agent Architecture, Directory Organization Standards
- **Existing files**: bash-block-execution-model.md, development-workflow.md, patterns/, writing-standards.md
- **Gaps**: No directory-organization.md or hierarchical-agents.md (should be created)
- **Opportunity**: Extract architectural concept sections here with comprehensive examples

### `.claude/docs/reference/`
- **Natural home for**: Code Standards, Project-Specific Commands
- **Existing files**: agent-reference.md, command-architecture-standards.md, command-reference.md, library-api.md
- **Gaps**: No code-standards.md file (should be created)
- **Opportunity**: Extract standards and reference documentation with cross-links

### `.claude/docs/architecture/`
- **Natural home for**: State-Based Orchestration Architecture
- **Existing files**: coordinate-state-management.md, state-based-orchestration-overview.md
- **Gaps**: None (state-based-orchestration-overview.md already covers this content)
- **Opportunity**: Replace inline section with summary link to existing comprehensive doc

### `.claude/docs/guides/`
- **Natural home for**: Task-focused how-to guides (already well-populated)
- **Existing files**: Many command guides, pattern guides, workflow guides
- **Gaps**: None identified
- **Opportunity**: Cross-reference from CLAUDE.md sections to relevant guides

## Metadata Gaps

### Sections Missing [Used by: ...] Tags

The following major sections do not have `[Used by: ...]` metadata tags:

1. **Task Metadata** (lines 3-8) - Worktree-specific, not a standard section
2. **Objective** (line 10) - Worktree-specific, not a standard section
3. **Current Status** (lines 13-18) - Worktree-specific, not a standard section
4. **Claude Context** (line 20) - Worktree-specific, not a standard section
5. **Task Notes** (line 23) - Worktree-specific, not a standard section
6. **Project Standards and Guidelines** (lines 35-42) - Index section, used by all commands (should add metadata)
7. **Development Workflow** (lines 597-610) - Missing metadata (likely used by /orchestrate, /implement, /plan)
8. **Project-Specific Commands** (lines 816-875) - Missing metadata (used by all commands as reference)
9. **Quick Reference** (lines 878-908) - Missing metadata (used by all commands as quick lookup)
10. **Notes** (lines 958-963) - Footer section, not a standard

### Recommendations for Metadata Tags

- **Project Standards and Guidelines**: Add `[Used by: all commands]`
- **Development Workflow**: Add `[Used by: /orchestrate, /implement, /plan, /research]`
- **Project-Specific Commands**: Add `[Used by: all commands]`
- **Quick Reference**: Add `[Used by: all commands]`

Note: Worktree-specific sections (Task Metadata, Objective, etc.) are temporary and do not need metadata tags.
