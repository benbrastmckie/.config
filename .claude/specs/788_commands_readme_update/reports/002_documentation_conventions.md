# Documentation Conventions and Standards Research Report

## Metadata
- **Date**: 2025-11-18
- **Agent**: research-specialist
- **Topic**: Documentation Conventions and Standards
- **Report Type**: codebase analysis

## Executive Summary

Documentation for `.claude/commands/README.md` must follow comprehensive standards defined in `.claude/docs/`. Key requirements include: using relative paths for all internal links (not absolute filesystem paths), following the Diataxis framework for organization, adhering to timeless writing principles (no temporal markers or historical references), using Unicode box-drawing for diagrams, and maintaining the required README sections (Purpose, Module Documentation, Usage Examples, Navigation Links). The documentation system enforces strict link conventions with validation scripts and requires all documentation to describe current state without references to past implementations or version markers.

## Findings

### 1. Link Conventions

**Standard Format** (from `/home/benjamin/.config/.claude/docs/reference/code-standards.md:55-82`):

All internal markdown links must use relative paths from the current file location:
- Same directory: `[File](file.md)`
- Parent directory: `[File](../file.md)`
- Subdirectory: `[File](subdir/file.md)`
- With anchor: `[Section](file.md#section-name)`

**Prohibited Patterns**:
- Absolute filesystem paths: `/home/user/.config/file.md`
- Repository-relative without base from outside .claude/

**Validation Scripts**:
- Quick validation: `.claude/scripts/validate-links-quick.sh`
- Full validation: `.claude/scripts/validate-links.sh`

**Template Placeholders (Allowed)**:
- `{variable}` - Template variable
- `NNN_topic` - Placeholder pattern
- `$ENV_VAR` - Environment variable

### 2. Timeless Writing Standards

**Core Principles** (from `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md:49-57`):
- Document the current implementation accurately and clearly
- No historical reporting in main documentation
- Focus on what the system does now, not how it evolved
- Documentation should read as if the current implementation always existed
- Ban historical markers like "(New)", "(Old)", "(Updated)", "(Current)"

**Banned Temporal Markers** (lines 79-98):
- (New), (Old), (Updated), (Current), (Deprecated), (Original), (Legacy), (Previous)
- "previously", "recently", "now supports", "used to", "no longer"
- "in the latest version", "updated to", "changed from"

**Banned Migration Language** (lines 144-167):
- "migration from", "migrated to", "backward compatibility"
- "breaking change", "deprecated in favor of", "replaces the old"

**Rewriting Patterns** (lines 192-256):
- Remove temporal context: "Feature X was recently added to support Y" → "Feature X supports Y"
- Focus on current capabilities: "Previously used polling. Now uses webhooks." → "Uses webhooks for real-time updates."
- Convert comparisons to descriptions: "This replaces the old caching method" → "Provides in-memory caching for performance"

### 3. Documentation Structure Requirements

**README Requirements** (from `/home/benjamin/.config/CLAUDE.md:documentation_policy`):
Every subdirectory must have a README.md containing:
- **Purpose**: Clear explanation of directory role
- **Module Documentation**: Documentation for each file/module
- **Usage Examples**: Code examples where applicable
- **Navigation Links**: Links to parent and subdirectory READMEs

**Diataxis Framework** (from `/home/benjamin/.config/.claude/docs/README.md:5-14`):
- **Reference**: Information-oriented quick lookup
- **Guides**: Task-focused how-to guides
- **Concepts**: Understanding-oriented explanations
- **Workflows**: Learning-oriented tutorials

### 4. Content Standards

**Format Requirements** (from `/home/benjamin/.config/.claude/docs/README.md:509-517`):
- NO emojis in file content
- Unicode box-drawing for diagrams
- Clear, concise language
- Code examples with syntax highlighting
- CommonMark specification

**Character Encoding** (from `/home/benjamin/.config/.claude/docs/reference/code-standards.md:10`):
- UTF-8 only
- No emojis in file content

**Diagram Standards** (box-drawing example from `/home/benjamin/.config/.claude/commands/README.md:39-63`):
```
┌─────────────────────────────────────────────────────────────┐
│ User Input: /command [args]                                │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
```

### 5. Cross-Reference Standards

**Link Targets for Commands README**:
Based on docs structure, the commands README should link to:
- Parent: `[Parent Directory](../README.md)`
- Agents: `[agents/](../agents/README.md)`
- Docs: `[docs/](../docs/README.md)`
- Specs: `[specs/](../specs/README.md)`

**Command-Specific Documentation Links**:
Each command should reference its detailed guide:
- `/plan` → `[Plan Command Guide](../docs/guides/plan-command-guide.md)`
- `/build` → `[Build Command Guide](../docs/guides/build-command-guide.md)`
- `/coordinate` → `[Coordinate Command Guide](../docs/guides/coordinate-command-guide.md)`

**Reference Documentation Links**:
- Command Reference: `[Command Reference](../docs/reference/command-reference.md)`
- Agent Reference: `[Agent Reference](../docs/reference/agent-reference.md)`
- Command Architecture Standards: `[Architecture Standards](../docs/reference/command_architecture_standards.md)`

### 6. Section Organization

**Command README Structure** (current pattern from `/home/benjamin/.config/.claude/commands/README.md`):
1. Title and overview
2. Command Highlights (feature emphasis)
3. Purpose (workflow categories)
4. Command Architecture (diagram)
5. Available Commands (detailed entries)
6. Command Definition Format
7. Command Types (categorization)
8. Adaptive Plan Structures
9. Standards Discovery
10. Creating Custom Commands
11. Command Integration
12. Best Practices
13. Documentation Standards
14. Neovim Integration
15. Navigation
16. Examples

### 7. Code Block Standards

**Bash Examples** (consistent formatting):
```bash
# Comment explaining the command
/command "argument" [optional]
```

**Markdown Examples** (frontmatter and content):
```markdown
---
frontmatter-field: value
---

# Heading
Content
```

**YAML Examples** (configuration):
```yaml
key: value
list:
  - item1
  - item2
```

### 8. Content Ownership

**Single Source of Truth** (from `/home/benjamin/.config/.claude/docs/README.md:103-109`):
- Patterns: `concepts/patterns/` catalog is authoritative
- Command Syntax: `reference/command-reference.md` is authoritative
- Agent Syntax: `reference/agent-reference.md` is authoritative
- Architecture: `concepts/hierarchical-agents.md` is authoritative

Commands README should cross-reference these authoritative sources rather than duplicating content.

## Recommendations

### 1. Use Relative Paths for All Links
Replace any absolute paths with relative paths from the commands directory:
- `../docs/guides/plan-command-guide.md` (not `/home/benjamin/.config/.claude/docs/guides/plan-command-guide.md`)
- `../agents/README.md` (not `.claude/agents/README.md`)

### 2. Apply Timeless Writing Standards
Review all content for temporal markers and rewrite:
- Remove "(New)", "(Updated)", etc. labels
- Eliminate "previously", "now supports", "recently added"
- Focus on current state descriptions

### 3. Maintain Required README Sections
Ensure the README includes:
- Clear Purpose statement
- Complete Module Documentation for each command file
- Usage Examples with syntax highlighting
- Navigation Links to parent and related directories

### 4. Use Standard Link Format for Commands
Each command entry should include consistent links:
```markdown
#### /command-name
**Purpose**: Brief description
**Usage**: `/command-name <args>`
**See Also**: [Command Guide](../docs/guides/command-name-guide.md)
```

### 5. Follow Box-Drawing Standards for Diagrams
Use Unicode box-drawing characters for all architecture diagrams:
- `┌ ─ ┐ │ └ ┘` for boxes
- `├ ┼ ┤ ┬ ┴` for connections
- `▼ ▲ ◀ ▶` for arrows

### 6. Validate Links Before Committing
Run validation scripts to ensure all links resolve:
```bash
.claude/scripts/validate-links-quick.sh
```

### 7. Cross-Reference Authoritative Sources
For detailed syntax and patterns, link to authoritative sources:
- Command syntax → `../docs/reference/command-reference.md`
- Architecture patterns → `../docs/reference/command_architecture_standards.md`
- Agent usage → `../docs/reference/agent-reference.md`

## References

### Documentation Standards Files
- `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md` (lines 1-558)
- `/home/benjamin/.config/.claude/docs/reference/code-standards.md` (lines 1-84)
- `/home/benjamin/.config/.claude/docs/README.md` (lines 1-771)

### Project Configuration
- `/home/benjamin/.config/CLAUDE.md` (documentation_policy section)

### Example Files
- `/home/benjamin/.config/.claude/commands/README.md` (lines 1-700)
- `/home/benjamin/.config/.claude/docs/reference/command-reference.md` (lines 1-644)

### Validation Tools
- `/home/benjamin/.config/.claude/scripts/validate-links-quick.sh`
- `/home/benjamin/.config/.claude/scripts/validate-links.sh`
