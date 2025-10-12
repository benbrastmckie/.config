# Standards Integration Pattern for Commands

This document provides a reusable template for integrating CLAUDE.md standards discovery and application into slash commands.

## Overview

All development commands should follow a consistent pattern for discovering, extracting, and applying project standards from CLAUDE.md files. This ensures reliable standards enforcement across the development workflow.

## Pattern Template

### Section 1: Standards Discovery

Every command that generates or modifies code/documentation should include a "Standards Discovery and Application" section:

```markdown
## Standards Discovery and Application

### Discovery Process
1. **Locate CLAUDE.md**: Search upward from current working directory
2. **Check Subdirectory Standards**: Look for CLAUDE.md in target directory
3. **Parse Relevant Sections**: Extract sections specific to this command
4. **Handle Missing Standards**: Fall back to sensible defaults

### Implementation
\```bash
# Pseudocode for standards discovery
function discover_standards() {
  # 1. Find CLAUDE.md recursively upward
  claude_md=$(find_file_upward "CLAUDE.md")

  # 2. Check for subdirectory-specific CLAUDE.md
  if [ -f "$target_dir/CLAUDE.md" ]; then
    subdir_claude="$target_dir/CLAUDE.md"
  fi

  # 3. Parse sections (look for [Used by: this-command] markers)
  extract_sections "$claude_md" "$subdir_claude"

  # 4. Merge standards (subdirectory overrides parent)
  merge_standards
}
\```
```

### Section 2: Standards Sections Used

Document which CLAUDE.md sections this command uses:

```markdown
### Standards Sections Used
- **Code Standards** [for /implement, /refactor]: Indentation, naming, error handling
- **Testing Protocols** [for /test]: Test commands, patterns, coverage requirements
- **Documentation Policy** [for /document]: README requirements, format guidelines
- **Standards Discovery** [for all]: Discovery method, inheritance, fallback behavior
```

### Section 3: Standards Application

Specify HOW the command applies discovered standards:

```markdown
### Application
Standards influence command behavior as follows:
- **Code Generation**: Generated code matches indentation, naming conventions
- **Style Checks**: Verify line length, naming patterns before completion
- **Test Execution**: Use test commands from Testing Protocols section
- **Documentation**: Follow Documentation Policy format and requirements

### Concrete Examples
\```lua
-- Code Standards: "Indentation: 2 spaces, expandtab"
-- Generated code will use:
local function example()
  return {
    field = "value",  -- 2-space indentation
  }
end

-- Code Standards: "Naming: snake_case for functions"
-- Will generate: calculate_total() not calculateTotal()
\```
```

### Section 4: Compliance Verification

Document how the command verifies compliance:

```markdown
### Compliance Verification
Before marking work complete:
- [ ] Code style matches CLAUDE.md specifications
- [ ] Naming follows project conventions
- [ ] Tests follow testing standards
- [ ] Documentation meets policy requirements

### Verification Methods
- **Linting**: Run project linter if specified in CLAUDE.md
- **Pattern Matching**: Check naming, indentation programmatically
- **Manual Review**: Prompt user to review against standards
```

### Section 5: Error Handling

Define fallback behavior:

```markdown
### Fallback Behavior
When CLAUDE.md not found or incomplete:

1. **Use Language Defaults**: Apply sensible language-specific conventions
2. **Suggest Creation**: Recommend running `/setup` to create CLAUDE.md
3. **Graceful Degradation**: Continue with reduced functionality
4. **Document Limitations**: Note which standards could not be applied
```

## Complete Command Example

Here's how the pattern looks in a complete command file:

```markdown
---
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
description: Example command with standards integration
---

# Example Command

I'll help you with [task] following project standards.

## Standards Discovery and Application

### Discovery Process
1. Locate CLAUDE.md (recursive upward from working directory)
2. Check for subdirectory-specific CLAUDE.md files
3. Parse relevant sections for this command
4. Fall back to defaults if not found

### Standards Sections Used
- **Code Standards**: Indentation, line length, naming conventions
- **Testing Protocols**: Test commands and patterns
- **Documentation Policy**: Documentation format and requirements

### Application
Standards are applied during:
- Code generation (style, naming)
- Test execution (using specified test commands)
- Documentation creation (following policy)

### Compliance Verification
Before completion:
- [ ] Code style matches CLAUDE.md
- [ ] Tests follow testing protocols
- [ ] Documentation meets policy

### Fallback Behavior
When CLAUDE.md not found:
- Use language-specific defaults
- Suggest creating CLAUDE.md with `/setup`
- Continue with graceful degradation

## Process
[Rest of command documentation...]
```

## Best Practices

### DO

1. **Make Discovery Explicit**: Always document the discovery process
2. **Prioritize CLAUDE.md**: Check CLAUDE.md before other sources
3. **Show Examples**: Provide concrete examples of standards application
4. **Verify Compliance**: Include verification steps
5. **Handle Missing Gracefully**: Define fallback behavior

### DON'T

1. **Assume Standards Exist**: Always check and handle missing CLAUDE.md
2. **Use Vague Language**: Be specific about what standards are applied
3. **Skip Subdirectory Check**: Always check for more specific standards
4. **Ignore Inheritance**: Respect subdirectory override rules
5. **Forget Error Cases**: Document what happens when standards incomplete

## Integration Points

### With Other Commands

Commands should reference each other's standards usage:

```markdown
## Integration with Other Commands

### Standards Flow
1. `/report` - Researches topic (no standards needed)
2. `/plan` - Discovers and captures standards in plan
3. `/implement` - Applies standards during code generation (← YOU ARE HERE)
4. `/test` - Verifies using standards-defined test commands
5. `/document` - Documents following standards format
6. `/refactor` - Validates against standards
```

## Section Markers Reference

CLAUDE.md sections use this metadata format:

```markdown
## Section Name
[Used by: /command1, /command2, /command3]

Content...
```

### Standard Section Names
- `## Code Standards` - Code style, naming, error handling
- `## Testing Protocols` - Test commands, patterns, coverage
- `## Documentation Policy` - README requirements, format
- `## Standards Discovery` - Discovery method, inheritance, fallback

### Finding Sections

```bash
# Find sections used by a specific command
grep -A 1 "^## " CLAUDE.md | grep -B 1 "/implement"

# Extract a specific section
awk '/^## Code Standards/,/^## [^#]/' CLAUDE.md
```

## Validation Checklist

Use this checklist when adding standards integration to a command:

- [ ] Command has "Standards Discovery and Application" section
- [ ] Discovery process is documented (4 steps minimum)
- [ ] Standards sections used are listed explicitly
- [ ] Application method is described with examples
- [ ] Compliance verification steps are defined
- [ ] Fallback behavior is documented
- [ ] Integration with other commands is noted
- [ ] Error cases are handled

## References

- [CLAUDE.md Section Schema](claude-md-section-schema.md) - Section format specification
- [Standards Integration Examples](standards-integration-examples.md) - Parsing examples
- [Command-Standards Matrix](../commands/README.md) - Which commands use which sections

## Updates

When updating this pattern:
1. Update all commands using the pattern
2. Document changes in command changelogs
3. Run `/validate-setup` to verify compliance
4. Update examples to match new pattern
