# CLAUDE.md Section Schema

This document defines the standard format for sections in CLAUDE.md files, ensuring they are machine-parseable by slash commands.

## Schema Overview

CLAUDE.md files should contain well-defined sections with consistent formatting and metadata. This allows commands to reliably discover and extract standards.

## Section Format

### Basic Structure

```markdown
## Section Name
[Used by: /command1, /command2]

### Subsection
Content...
```

### Required Elements

1. **Level 2 Heading** (`##`): Primary section marker
2. **Metadata Line** (`[Used by: ...]`): Commands that use this section
3. **Content**: Standards, guidelines, or configuration

### Metadata Format

```markdown
[Used by: /command1, /command2, /command3]
```

- Must be on first line after section heading
- Comma-separated list of command names
- Commands start with `/`
- Use `all commands` for universal sections

## Standard Sections

### 1. Code Standards

**Purpose**: Define coding style, naming conventions, and language-specific rules

**Format**:
```markdown
## Code Standards
[Used by: /implement, /refactor, /plan]

### General Principles
- **Indentation**: [specification]
- **Line Length**: [specification]
- **Naming**: [conventions]
- **Error Handling**: [patterns]
- **Documentation**: [requirements]
- **Character Encoding**: [encoding rules]

### Language-Specific Standards
- **[Language]**: [link to detailed standards or inline rules]
```

**Parsing Pattern**:
```bash
# Extract Code Standards section
awk '/^## Code Standards/,/^## [^#]/' CLAUDE.md

# Get indentation rule
grep "^\*\*Indentation\*\*:" CLAUDE.md
```

### 2. Testing Protocols

**Purpose**: Define test commands, patterns, and quality requirements

**Format**:
```markdown
## Testing Protocols
[Used by: /test, /test-all, /implement]

### Test Discovery
[How commands should find tests]

### [Project Type] Testing
- **Test Commands**: [commands to run tests]
- **Test Pattern**: [file patterns]
- **Linting**: [linter command]
- **Formatting**: [formatter command]

### Coverage Requirements
- [Coverage thresholds]
- [Quality standards]
```

**Parsing Pattern**:
```bash
# Extract test commands
grep "^\*\*Test Commands\*\*:" CLAUDE.md

# Find test patterns
grep "^\*\*Test Pattern\*\*:" CLAUDE.md
```

### 3. Documentation Policy

**Purpose**: Define documentation requirements and format

**Format**:
```markdown
## Documentation Policy
[Used by: /document, /plan]

### README Requirements
[What every README must contain]

### Documentation Format
- [Formatting rules]
- [Code example format]
- [Diagram standards]
- [Character encoding]

### Documentation Updates
- [When to update docs]
- [How to keep docs current]
```

**Parsing Pattern**:
```bash
# Extract documentation policy
awk '/^## Documentation Policy/,/^## [^#]/' CLAUDE.md
```

### 4. Standards Discovery

**Purpose**: Define how commands should discover and apply standards

**Format**:
```markdown
## Standards Discovery
[Used by: all commands]

### Discovery Method
1. [Search strategy]
2. [Subdirectory checks]
3. [Merging/inheritance rules]

### Subdirectory Standards
- [Override rules]
- [Inheritance behavior]

### Fallback Behavior
- [What to do when CLAUDE.md missing]
- [Graceful degradation]
```

**Parsing Pattern**:
```bash
# Extract discovery method
awk '/^### Discovery Method/,/^###/' CLAUDE.md
```

### 5. Specifications Structure (Optional)

**Purpose**: Define specs directory protocol

**Format**:
```markdown
### Specifications Structure (`specs/`)
[Used by: /report, /plan, /implement, /list-plans, /list-reports, /list-summaries]

The specifications directory follows this structure:
- `plans/` - [format]
- `reports/` - [format]
- `summaries/` - [format]

[Numbering scheme]
[Location rules]
```

## Subsection Patterns

### Field Definitions

Use bold for field names, colon separator:

```markdown
- **Field Name**: value
- **Another Field**: description
```

### Lists

Use markdown lists with optional nesting:

```markdown
- Top level item
  - Nested item
  - Another nested item
- Another top level item
```

### Code Blocks

Use triple backticks with language identifier:

```markdown
\```bash
# Shell command example
command --option value
\```

\```lua
-- Lua code example
local function example()
  return true
end
\```
```

### Links

Link to other files for detailed standards:

```markdown
- **Lua**: See [Neovim Configuration Guidelines](../../nvim/CLAUDE.md)
```

## Metadata Schema

### Usage Metadata

**Format**: `[Used by: comma, separated, list]`

**Examples**:
```markdown
[Used by: /implement, /refactor, /plan]
[Used by: /test, /test-all]
[Used by: /document]
[Used by: all commands]
```

**Parsing**:
```bash
# Find sections used by specific command
grep "^\[Used by:.*\/implement" CLAUDE.md

# Extract command list from metadata
grep "^\[Used by:" CLAUDE.md | sed 's/\[Used by: \(.*\)\]/\1/'
```

### Optional Metadata

Additional metadata can be added on subsequent lines:

```markdown
## Section Name
[Used by: /command1]
[Version: 1.0]
[Last Updated: 2025-10-01]
```

## Inheritance Rules

### Parent-Child Relationship

When subdirectory has its own CLAUDE.md:

```markdown
## Standards Discovery
[Used by: all commands]

This [subdir]/CLAUDE.md extends the root CLAUDE.md with [specific] standards.

### Inheritance
- This file overrides/extends root CLAUDE.md for [scope]
- Commands should check this file first for [scope] directory
- Fall back to root CLAUDE.md for general standards
- Both files should be consulted for complete standards
```

### Merging Strategy

1. **Check subdirectory CLAUDE.md first** for most specific standards
2. **Fall back to parent CLAUDE.md** for missing sections
3. **Merge when both exist**: subdirectory values override parent values
4. **Document overrides**: Note which standards are overridden

## Parsing Examples

### Extract Section by Name

```bash
# Using awk
awk '/^## Code Standards/,/^## [^#]/' CLAUDE.md

# Using sed
sed -n '/^## Code Standards/,/^## /p' CLAUDE.md | head -n -1
```

### Find Sections for Command

```bash
# Find all sections used by /implement
grep -B 1 "^\[Used by:.*\/implement" CLAUDE.md | grep "^##"

# Output: ## Code Standards
#         ## Testing Protocols
```

### Extract Field Values

```bash
# Get indentation rule
grep "^\- \*\*Indentation\*\*:" CLAUDE.md | sed 's/.*: //'

# Get test commands
grep "^\- \*\*Test Commands\*\*:" CLAUDE.md | sed 's/.*: //'
```

### Check if Section Exists

```bash
# Check for Code Standards section
if grep -q "^## Code Standards" CLAUDE.md; then
  echo "Code Standards section found"
fi
```

## Validation

### Schema Validation Checklist

- [ ] All level 2 sections have `[Used by: ...]` metadata
- [ ] Metadata uses comma-separated command list
- [ ] Commands start with `/` or use `all commands`
- [ ] Subsections use level 3 headings (`###`)
- [ ] Field definitions use `**Field**: value` format
- [ ] Code blocks have language identifiers
- [ ] Links use valid paths

### Common Issues

**Issue**: Metadata missing
```markdown
## Code Standards  <!-- Missing [Used by: ...] -->

### General Principles
```

**Fix**:
```markdown
## Code Standards
[Used by: /implement, /refactor, /plan]

### General Principles
```

**Issue**: Inconsistent field format
```markdown
- Indentation: 2 spaces  <!-- Not bold -->
```

**Fix**:
```markdown
- **Indentation**: 2 spaces
```

**Issue**: Wrong heading level
```markdown
## Code Standards
## General Principles  <!-- Should be ### -->
```

**Fix**:
```markdown
## Code Standards
### General Principles
```

## Tools and Utilities

### Validation Script

```bash
#!/bin/bash
# validate-claude-md.sh - Validate CLAUDE.md structure

file="${1:-CLAUDE.md}"

echo "Validating $file..."

# Check for level 2 sections
sections=$(grep "^## " "$file" | wc -l)
echo "Found $sections level 2 sections"

# Check for metadata
metadata=$(grep "^\[Used by:" "$file" | wc -l)
echo "Found $metadata metadata lines"

# Check for orphaned sections (no metadata)
orphans=$(grep -A 1 "^## " "$file" | grep -v "^\[Used by:" | grep -v "^--" | grep "^## " | wc -l)
if [ $orphans -gt 0 ]; then
  echo "WARNING: $orphans sections missing metadata"
  grep -A 1 "^## " "$file" | grep -v "^\[Used by:" | grep "^## "
fi
```

### Section Extractor

```bash
#!/bin/bash
# extract-section.sh - Extract specific section from CLAUDE.md

file="${1:-CLAUDE.md}"
section="$2"

if [ -z "$section" ]; then
  echo "Usage: $0 [file] <section-name>"
  exit 1
fi

awk "/^## $section/,/^## [^#]/" "$file" | head -n -1
```

## References

- [Standards Integration Pattern](../guides/patterns/standards-integration.md) - How commands use these sections
- [Standards Integration Examples](../guides/patterns/standards-integration.md) - Parsing examples
- Root CLAUDE.md - Reference implementation
- ../../nvim/CLAUDE.md - Subdirectory example

## Version History

- **1.0** (2025-10-01): Initial schema definition
  - Defined standard sections (Code Standards, Testing Protocols, etc.)
  - Established metadata format `[Used by: ...]`
  - Documented parsing patterns and validation
