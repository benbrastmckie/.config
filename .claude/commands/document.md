---
command-type: primary
dependent-commands: list-summaries, validate-setup
description: Update all relevant documentation based on recent code changes
argument-hint: [change-description] [scope]
allowed-tools: Read, Write, Edit, MultiEdit, Grep, Glob, Task, TodoWrite
---

# /document Command

Updates all relevant documentation to accurately reflect the current codebase state, ensuring compliance with project documentation standards defined in CLAUDE.md.

## Usage

```
/document [change-description] [scope]
```

### Arguments

- `[scope-description]` (optional): Brief description of area to document
- `[scope]` (optional): Specific directory or module to focus on (defaults to entire codebase)

## Examples

### Auto-detect Scope
```
/document
```
Analyzes the codebase and updates all relevant documentation

### With Scope Description
```
/document "Kitty terminal support and command picker" nvim/lua/neotex
```

### Scoped Documentation
```
/document "Authentication system" nvim/lua/neotex/auth
```

## Process

### 1. **Scope Detection**
- Analyzes affected areas of the codebase
- Identifies files and their types
- Determines which documentation needs updating
- Reviews implementation summaries if available

### 2. **Standards Verification**
- Reads CLAUDE.md for project documentation standards
- Checks for specific requirements:
  - README.md requirements per directory
  - Code style documentation
  - ASCII diagram standards
  - Character encoding rules
  - API documentation format

### 3. **Documentation Identification**
Automatically identifies and updates:
- **README.md files** in affected directories
- **API documentation** for modified functions/modules
- **Configuration documentation** for settings
- **Command documentation** for CLI functionality
- **Architecture docs** for system structure
- **CHANGELOG.md** if present

### 4. **Documentation Updates**

#### README.md Updates
Following CLAUDE.md standards:
```markdown
# Directory Name

Brief description of directory purpose.

## Modules

### filename.lua
Description of what this module does and its key functions.

## Subdirectories

- [subdirectory-name/](subdirectory-name/README.md) - Brief description

## Navigation
- [← Parent Directory](../README.md)
```

#### Function Documentation
- Updates docstrings and annotations
- Maintains parameter descriptions
- Updates return value documentation
- Adds usage examples if missing

#### Configuration Documentation
- Updates available options
- Documents current settings
- Updates default values
- Documents option behaviors

### 5. **Compliance Checks**

#### Style Compliance
- Indentation (as specified in CLAUDE.md)
- Line length limits
- Naming conventions
- Import organization

#### Content Requirements
- All directories have README.md
- All public functions documented
- Configuration options explained
- System capabilities accurately described

#### Formatting Standards
- UTF-8 encoding (no emojis in files)
- Box-drawing characters for diagrams
- Markdown formatting consistency
- Code example syntax highlighting

### 6. **Cross-Reference Updates**
- Updates links between documents
- Fixes broken references
- Updates navigation sections
- Maintains document hierarchy

## Documentation Priorities

### High Priority
1. **Public APIs** - External interfaces and their usage
2. **Configuration Options** - Available settings and their effects
3. **Core Functionality** - Primary features and capabilities

### Medium Priority
1. **Internal Architecture** - System structure and organization
2. **Code Comments** - Inline documentation and explanations
3. **Module Organization** - Component relationships

### Low Priority
1. **Performance Characteristics** - Current performance metrics and behavior
2. **Implementation Details** - Technical specifics and internals
3. **Test Documentation** - Test case descriptions and coverage

## Output

### Updated Files
The command will update:
- All affected README.md files
- Module documentation headers
- Configuration documentation
- API reference documents
- Architecture diagrams (if needed)

### Report Generation
Creates a summary of documentation updates:
```
Documentation Update Summary
============================
Files Updated: 12
- nvim/lua/neotex/ai-claude/README.md (added new modules)
- nvim/lua/neotex/ai-claude/commands/README.md (updated features)
- CLAUDE.md (added new standards)

Compliance Checks: ✓ All passed
New Documentation: 3 files created
Broken Links Fixed: 2
```

## Standards Compliance

### CLAUDE.md Requirements
Automatically enforces:
- **Documentation Policy**: Every subdirectory must have README.md
- **Content Requirements**: Purpose, modules, navigation
- **ASCII Diagrams**: Using Unicode box-drawing characters
- **No Emojis**: In file content (only runtime UI)
- **UTF-8 Encoding**: All documentation files
- **Timeless Writing**: No historical commentary, temporal markers, or version references (see CLAUDE.md "Development Philosophy → Documentation Standards")

### Markdown Standards
- Clear, concise language
- Code examples with syntax highlighting
- Consistent formatting
- Proper heading hierarchy
- Link validity

## Best Practices

### DO
- **Keep docs current**: Ensure documentation reflects actual codebase state
- **Review before committing**: Verify documentation accuracy
- **Include examples**: Add usage examples for features
- **Maintain consistency**: Follow established patterns
- **Document behavior**: Explain what the system does and how it works

### DON'T
- **Over-document**: Avoid redundant documentation
- **Break existing docs**: Preserve valid existing content
- **Add emojis**: Follow encoding standards
- **Create without purpose**: Every doc should add value
- **Ignore standards**: Always check CLAUDE.md

## Documentation Review Checklist

Before finalizing documentation updates, verify:

### Content Quality
- [ ] Documentation describes current state accurately
- [ ] Technical details are correct and complete
- [ ] Examples are functional and relevant
- [ ] Navigation links work correctly

### Standards Compliance
- [ ] No emojis in file content (UTF-8 compliance)
- [ ] Unicode box-drawing used for diagrams (not ASCII art)
- [ ] Markdown follows CommonMark specification
- [ ] Line length within limits (if specified in CLAUDE.md)

### Timeless Writing Policy
- [ ] No temporal markers: "(New)", "(Old)", "(Updated)", "(Current)", "(Deprecated)"
- [ ] No temporal phrases: "previously", "recently", "now supports", "used to", "no longer"
- [ ] No migration language: "migration from", "backward compatibility", "breaking change"
- [ ] No version references in descriptions: "v1.0", "since version", "as of version"
- [ ] Documentation reads as if current implementation always existed
- [ ] Historical context moved to CHANGELOG.md if needed

### Directory Structure
- [ ] Every subdirectory has README.md
- [ ] README includes: purpose, modules, navigation
- [ ] Cross-references are complete and accurate
- [ ] Parent/child links maintained

## Integration with Other Commands

### Before Documenting
- Use `/implement` to complete code changes
- Use `/test` to verify functionality
- Use `/list-summaries` to review implementation history

### After Documenting
- Review all updated documentation
- Commit documentation with code changes
- Use `/validate-setup` to verify compliance

## Special Cases

### Feature Documentation
- Creates comprehensive documentation
- Adds usage examples
- Updates feature lists
- Documents capabilities and limitations

### Architecture Documentation
- Updates architectural documentation
- Modifies module descriptions
- Updates code examples
- Documents system organization

### Troubleshooting Documentation
- Updates troubleshooting guides
- Documents resolution approaches
- Adds diagnostic procedures
- Documents common issues and solutions

## Error Handling

### Missing CLAUDE.md
- Falls back to sensible defaults
- Creates basic documentation structure
- Suggests creating CLAUDE.md

### Conflicts
- Preserves custom sections
- Merges changes carefully
- Reports conflicts for manual review

### Invalid Documentation
- Reports formatting issues
- Suggests corrections
- Maintains backup of originals

## Agent Usage

For agent invocation patterns, see [Agent Invocation Patterns](../docs/command-patterns.md#agent-invocation-patterns). For documentation standards and artifact references, see [Artifact Referencing Patterns](../docs/command-patterns.md#artifact-referencing-patterns).

**Document-specific agent:**

| Agent | Purpose | Key Capabilities |
|-------|---------|------------------|
| doc-writer | Maintain documentation consistency | Standards compliance, cross-referencing, completeness checks |

**Delegation Benefits:**
- Consistent documentation format and style
- Automatic adherence to CLAUDE.md policy
- Proper linking between docs, specs, plans, reports
- Ensures all required documentation exists

**Standards Enforced:**
- README.md in every subdirectory
- Unicode box-drawing for diagrams
- No emojis (UTF-8 compliance)
- CommonMark specification
- Proper cross-references and navigation

## Notes

- **Automatic detection**: Analyzes code changes to determine documentation needs
- **Standards-compliant**: Follows project-specific documentation requirements
- **Non-destructive**: Preserves existing valid documentation
- **Comprehensive**: Updates all related documentation in one pass
- **Traceable**: Creates clear summary of all documentation changes
- **Idempotent**: Safe to run multiple times
- **Agent-Powered**: `doc-writer` ensures consistent, high-quality documentation