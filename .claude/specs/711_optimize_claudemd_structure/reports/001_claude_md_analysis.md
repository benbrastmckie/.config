# CLAUDE.md Structure Analysis

## Metadata
- **Date**: 2025-11-14
- **Agent**: claude-md-analyzer
- **File Analyzed**: /home/benjamin/.config/CLAUDE.md
- **Threshold**: balanced (80 lines)
- **Report Type**: Structure Analysis and Bloat Detection

## Summary

- Total Lines: 964
- Total Sections: 19
- Bloated Sections (>80 lines): 4
- Moderate Sections (50-80 lines): 1
- Sections Missing Metadata: 0 (all sections have proper [Used by: ...] tags)
- Projected Savings: ~437 lines
- Target Size: 527 lines
- Reduction Potential: 45.3%

## Section Analysis

| Section | Lines | Status | Recommendation |
|---------|-------|--------|----------------|
| Project Standards and Guidelines | 25 | Optimal | Keep inline |
| Testing Protocols | 39 | Optimal | Keep inline |
| Code Standards | 84 | **Bloated** | Extract to docs/ with summary |
| Directory Organization Standards | 231 | **Bloated** | Extract to docs/ with summary |
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

### 1. Code Standards (84 lines) → .claude/docs/reference/code-standards.md

**Rationale**: Standards and reference documentation should live in reference/ directory for discoverability and maintainability.

**Integration Strategy**:
- Create new file: `/home/benjamin/.config/.claude/docs/reference/code-standards.md`
- No existing file found at this path
- Include: General Principles, Language-Specific Standards, Command/Agent Architecture Standards, Architectural Separation, Development Guides, Internal Link Conventions
- CLAUDE.md Summary (keep 5-10 lines): Brief overview with link to full standards

**Content to Extract**:
- Indentation, line length, naming conventions
- Error handling patterns
- Documentation requirements
- Language-specific standards (Lua, Markdown, Shell)
- Command and agent architecture standards
- Executable/documentation separation pattern overview
- Development guide references
- Link conventions

### 2. Directory Organization Standards (231 lines) → .claude/docs/concepts/directory-organization.md

**Rationale**: Architectural concept documentation explaining the "why" behind directory structure. This is the largest bloated section.

**Integration Strategy**:
- Create new file: `/home/benjamin/.config/.claude/docs/concepts/directory-organization.md`
- No existing file found at this path
- Include: Purpose, Directory Structure, scripts/ vs lib/ vs utils/ distinctions, Decision Matrix, Anti-Patterns, README Requirements, Verification steps
- CLAUDE.md Summary (keep 5-10 lines): High-level directory tree and link to detailed guide

**Content to Extract**:
- Complete directory structure tree
- Detailed sections for scripts/, lib/, commands/, agents/, docs/, utils/
- File placement decision matrix
- Decision process flowchart
- Anti-patterns list
- Directory README requirements
- Verification procedures
- All references and cross-links

### 3. Hierarchical Agent Architecture (93 lines) → Merge with .claude/docs/concepts/hierarchical_agents.md

**Rationale**: File already exists with comprehensive agent architecture documentation.

**Integration Strategy**:
- Existing file: `/home/benjamin/.config/.claude/docs/concepts/hierarchical_agents.md`
- Merge unique content from CLAUDE.md section into existing file
- Update CLAUDE.md to use 5-10 line summary with link
- Avoid duplication - preserve single source of truth

**Content to Extract/Merge**:
- Overview and key features (if not already in existing file)
- Context reduction metrics
- Utilities list (metadata-extraction.sh, plan-core-bundle.sh, etc.)
- Agent templates list
- Command integration examples
- Validation and troubleshooting section
- Usage example

### 4. State-Based Orchestration Architecture (108 lines) → Link to .claude/docs/architecture/state-based-orchestration-overview.md

**Rationale**: Comprehensive 2,000+ line documentation already exists at referenced path.

**Integration Strategy**:
- Existing file: `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md`
- No extraction needed - documentation already complete
- Replace entire CLAUDE.md section with 5-10 line summary + link
- Reference existing comprehensive documentation

**Content to Replace With Summary**:
- Brief description: "State machines with validated transitions for multi-phase workflows"
- Key benefits: explicit states, validated transitions, checkpoint management
- Link to comprehensive documentation
- When to use guidance (3+ phases, conditional transitions, checkpoint resume)

## Integration Points

### .claude/docs/concepts/
**Natural home for**: Architectural concepts and patterns

**Current Status**:
- ✓ hierarchical_agents.md exists (needs merge with CLAUDE.md content)
- ✓ development-workflow.md exists
- ✓ directory-protocols.md exists
- ✗ directory-organization.md missing (should be created from CLAUDE.md extraction)

**Recommendation**: Create directory-organization.md with 231-line extraction

### .claude/docs/reference/
**Natural home for**: Standards, APIs, catalogs

**Current Status**:
- ✓ command-reference.md exists
- ✓ agent-reference.md exists
- ✓ command_architecture_standards.md exists
- ✓ library-api.md exists
- ✗ code-standards.md missing (should be created from CLAUDE.md extraction)

**Recommendation**: Create code-standards.md with 84-line extraction

### .claude/docs/architecture/
**Natural home for**: State machines, system architecture, coordination patterns

**Current Status**:
- ✓ state-based-orchestration-overview.md exists (2,000+ lines comprehensive)
- ✓ coordinate-state-management.md exists
- ✓ hierarchical-supervisor-coordination.md exists
- ✓ workflow-state-machine.md exists

**Recommendation**: Replace CLAUDE.md section with summary link (no extraction needed)

### .claude/docs/guides/
**Natural home for**: How-to guides and tutorials

**Current Status**:
- ✓ command-development-guide.md exists
- ✓ agent-development-guide.md exists
- ✓ orchestration-best-practices.md exists
- Many other specialized guides exist

**Recommendation**: Project-Specific Commands section (61 lines, moderate) could potentially move here as orchestration-command-reference.md, but may remain in CLAUDE.md for quick reference

## Metadata Gaps

**Good News**: All formal CLAUDE.md sections have proper `[Used by: ...]` metadata tags.

**Sections Analyzed**:
- directory_protocols: [Used by: /research, /plan, /implement, /list-plans, /list-reports, /list-summaries]
- testing_protocols: [Used by: /test, /test-all, /implement]
- code_standards: [Used by: /implement, /refactor, /plan]
- directory_organization: [Used by: /implement, /plan, /refactor, all development commands]
- development_philosophy: [Used by: /refactor, /implement, /plan, /document]
- adaptive_planning: [Used by: /implement]
- adaptive_planning_config: [Used by: /plan, /expand, /implement, /revise]
- development_workflow: No explicit tag but used implicitly
- hierarchical_agent_architecture: [Used by: /orchestrate, /implement, /plan, /debug]
- state_based_orchestration: [Used by: /coordinate, /orchestrate, /supervise, custom orchestrators]
- project_commands: No explicit tag but serves as command catalog
- quick_reference: No explicit tag but serves as navigation aid
- documentation_policy: [Used by: /document, /plan]
- standards_discovery: [Used by: all commands]

**Non-Sectioned Content** (Worktree metadata at top):
- Task Metadata, Objective, Current Status sections are worktree-specific and not subject to SECTION protocol

**Recommendation**: Metadata coverage is excellent. No action needed.
