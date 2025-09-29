---
command-type: primary
dependent-commands: list-summaries, validate-setup
description: Update all relevant documentation based on recent code changes
argument-hint: [change-description] [scope]
allowed-tools: Read, Write, Edit, MultiEdit, Grep, Glob, Task, TodoWrite
---

# /document Command

Updates all relevant documentation based on recent code changes, ensuring compliance with project documentation standards defined in CLAUDE.md.

## Usage

```
/document [change-description] [scope]
```

### Arguments

- `[change-description]` (optional): Brief description of recent changes to document
- `[scope]` (optional): Specific directory or module to focus on (defaults to all affected areas)

## Examples

### Auto-detect Changes
```
/document
```
Analyzes recent git commits and updates all affected documentation

### With Change Description
```
/document "Added Kitty terminal support and command picker improvements"
```

### Scoped Documentation
```
/document "Refactored authentication system" nvim/lua/neotex/auth
```

## Process

### 1. **Change Detection**
- Analyzes recent git commits (uncommitted and recent commits)
- Identifies modified files and their types
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
- **Configuration documentation** for setting changes
- **Command documentation** for CLI changes
- **Architecture docs** if structure changed
- **Migration guides** for breaking changes
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
- Documents new settings
- Updates default values
- Adds deprecation notices

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
- Breaking changes highlighted

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
1. **Breaking Changes** - Must be documented immediately
2. **New APIs** - Public interfaces need documentation
3. **Configuration Changes** - User-facing settings
4. **Removed Features** - Deprecation and migration paths

### Medium Priority
1. **Internal Changes** - Architecture modifications
2. **Performance Improvements** - Optimization notes
3. **Bug Fixes** - Notable fixes worth documenting
4. **Refactoring** - Structure changes

### Low Priority
1. **Code Comments** - Inline documentation
2. **TODO Updates** - Task tracking
3. **Style Changes** - Formatting updates
4. **Test Documentation** - Test case descriptions

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

### Markdown Standards
- Clear, concise language
- Code examples with syntax highlighting
- Consistent formatting
- Proper heading hierarchy
- Link validity

## Best Practices

### DO
- **Run after significant changes**: Keep docs in sync with code
- **Review before committing**: Verify documentation accuracy
- **Include examples**: Add usage examples for new features
- **Maintain consistency**: Follow established patterns
- **Document rationale**: Explain why, not just what

### DON'T
- **Over-document**: Avoid redundant documentation
- **Break existing docs**: Preserve valid existing content
- **Add emojis**: Follow encoding standards
- **Create without purpose**: Every doc should add value
- **Ignore standards**: Always check CLAUDE.md

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

### New Features
- Creates comprehensive documentation
- Adds usage examples
- Updates feature lists
- Creates migration guides if needed

### Refactoring
- Updates architectural documentation
- Modifies module descriptions
- Updates code examples
- Preserves historical context

### Bug Fixes
- Documents in CHANGELOG if present
- Updates known issues sections
- Adds resolution notes
- Updates troubleshooting guides

### Breaking Changes
- Creates migration guides
- Documents removal timelines
- Updates all affected examples
- Highlights in CHANGELOG

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

## Notes

- **Automatic detection**: Analyzes code changes to determine documentation needs
- **Standards-compliant**: Follows project-specific documentation requirements
- **Non-destructive**: Preserves existing valid documentation
- **Comprehensive**: Updates all related documentation in one pass
- **Traceable**: Creates clear summary of all documentation changes
- **Idempotent**: Safe to run multiple times