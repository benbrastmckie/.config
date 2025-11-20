# Standards Integration Guide

**Path**: docs → guides → standards-integration.md

Comprehensive guide for discovering, parsing, and applying project standards from CLAUDE.md files in slash commands.

## Overview

All development commands should follow a consistent pattern for discovering, extracting, and applying project standards from CLAUDE.md files. This ensures reliable standards enforcement across the development workflow.

This guide combines the reusable integration pattern with concrete executable examples to help command developers understand both what to implement and how to implement it.

## Discovery Process

Every command that generates or modifies code/documentation should discover standards systematically.

###  Steps

1. **Locate CLAUDE.md**: Search upward from current working directory
2. **Check Subdirectory Standards**: Look for CLAUDE.md in target directory
3. **Parse Relevant Sections**: Extract sections specific to this command
4. **Handle Missing Standards**: Fall back to sensible defaults

### Example: Discovering CLAUDE.md

Command `/implement` running in `/home/user/project/src/feature/` finds standards files:

```bash
#!/bin/bash
# discover_claude_md.sh

current_dir="$PWD"
claude_files=()

# Search upward from current directory
while [ "$current_dir" != "/" ]; do
  if [ -f "$current_dir/CLAUDE.md" ]; then
    claude_files+=("$current_dir/CLAUDE.md")
    echo "Found: $current_dir/CLAUDE.md"
  fi
  current_dir=$(dirname "$current_dir")
done

# Most specific (deepest) file first
echo "Standards hierarchy:"
for file in "${claude_files[@]}"; do
  echo "  - $file"
done
```

Expected output:
```
Found: /home/user/project/src/CLAUDE.md
Found: /home/user/project/CLAUDE.md
Standards hierarchy:
  - /home/user/project/src/CLAUDE.md
  - /home/user/project/CLAUDE.md
```

Command uses `/home/user/project/src/CLAUDE.md` first, falls back to `/home/user/project/CLAUDE.md` for missing sections.

## Section Markers and Parsing

CLAUDE.md sections use metadata format to indicate which commands use them:

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

### Example: Finding Sections for a Command

Discover which sections `/implement` should use:

```bash
#!/bin/bash
# discover_command_sections.sh

command_name="$1"  # e.g., "/implement"
claude_md="$2"

echo "Finding sections for $command_name..."

# Find all sections that list this command in [Used by: ...]
grep -B 1 "^\[Used by:.*$command_name" "$claude_md" | grep "^##" | sed 's/^## //'

# Alternative: Find sections for command
awk -v cmd="$command_name" '
  /^## / { section=$0; sub(/^## /, "", section) }
  /^\[Used by:/ && $0 ~ cmd { print section }
' "$claude_md"
```

Given CLAUDE.md with:
```markdown
## Code Standards
[Used by: /implement, /refactor, /plan]

## Testing Protocols
[Used by: /test, /test-all, /implement]

## Documentation Policy
[Used by: /document, /plan]

## Standards Discovery
[Used by: all commands]
```

Output:
```
Finding sections for /implement...
Code Standards
Testing Protocols
Standards Discovery
```

### Example: Parsing Code Standards

Extract specific fields from Code Standards section:

```bash
#!/bin/bash
# extract_code_standards.sh

file="$1"

# Extract entire Code Standards section
echo "=== Code Standards Section ==="
awk '/^## Code Standards/,/^## [^#]/' "$file" | head -n -1

# Extract specific fields
echo -e "\n=== Parsed Fields ==="
echo "Indentation: $(grep "^\- \*\*Indentation\*\*:" "$file" | sed 's/.*: //')"
echo "Line Length: $(grep "^\- \*\*Line Length\*\*:" "$file" | sed 's/.*: //')"
echo "Naming: $(grep "^\- \*\*Naming\*\*:" "$file" | sed 's/.*: //')"
echo "Error Handling: $(grep "^\- \*\*Error Handling\*\*:" "$file" | sed 's/.*: //')"
```

Given CLAUDE.md with:
```markdown
## Code Standards
[Used by: /implement, /refactor, /plan]

### General Principles
- **Indentation**: 2 spaces, expandtab
- **Line Length**: ~100 characters (soft limit)
- **Naming**: snake_case for variables/functions
- **Error Handling**: Use pcall for Lua operations
```

Output:
```
=== Code Standards Section ===
## Code Standards
[Used by: /implement, /refactor, /plan]

### General Principles
- **Indentation**: 2 spaces, expandtab
- **Line Length**: ~100 characters (soft limit)
- **Naming**: snake_case for variables/functions
- **Error Handling**: Use pcall for Lua operations

=== Parsed Fields ===
Indentation: 2 spaces, expandtab
Line Length: ~100 characters (soft limit)
Naming: snake_case for variables/functions
Error Handling: Use pcall for Lua operations
```

### Example: Extracting Test Commands

Parse Testing Protocols to find test commands:

```bash
#!/bin/bash
# extract_test_commands.sh

file="$1"

# Extract test commands
test_commands=$(grep "^\- \*\*Test Commands\*\*:" "$file" | sed 's/.*: //')
echo "Available test commands: $test_commands"

# Parse individual commands
IFS=',' read -ra CMDS <<< "$test_commands"
for cmd in "${CMDS[@]}"; do
  cmd=$(echo "$cmd" | sed 's/[`\s]//g')  # Remove backticks and whitespace
  echo "  - $cmd"
done
```

Given CLAUDE.md with:
```markdown
## Testing Protocols
[Used by: /test, /test-all, /implement]

### Neovim Testing
- **Test Commands**: `:TestNearest`, `:TestFile`, `:TestSuite`, `:TestLast`
- **Test Pattern**: `*_spec.lua`, `test_*.lua`
- **Linting**: `<leader>l`
- **Formatting**: `<leader>mp`
```

Output:
```
Available test commands: `:TestNearest`, `:TestFile`, `:TestSuite`, `:TestLast`
  - :TestNearest
  - :TestFile
  - :TestSuite
  - :TestLast
```

## Applying Standards

Specify HOW the command applies discovered standards during code generation and testing.

### Application Methods

Standards influence command behavior as follows:
- **Code Generation**: Generated code matches indentation, naming conventions
- **Style Checks**: Verify line length, naming patterns before completion
- **Test Execution**: Use test commands from Testing Protocols section
- **Documentation**: Follow Documentation Policy format and requirements

### Example: Applying Code Standards

`/implement` command generating Lua code with discovered standards:

```lua
-- From Code Standards:
-- Indentation: 2 spaces, expandtab
-- Naming: snake_case for variables/functions
-- Error Handling: Use pcall for operations

local function calculate_user_total(user_id)  -- snake_case naming
  local status, result = pcall(function()     -- pcall error handling
    local user_data = database.query({        -- 2-space indentation
      id = user_id,
      fields = {"total", "balance"}
    })
    return user_data.total + user_data.balance
  end)

  if not status then
    print("Error calculating total: " .. result)
    return nil
  end

  return result
end
```

Verification of generated code:

```bash
# Check indentation (should be 2 spaces)
grep -P "^\s+" generated_file.lua | sed 's/[^ ].*//' | sort -u
# Output: "  " (2 spaces), "    " (4 spaces), "      " (6 spaces)

# Check naming convention (should be snake_case)
grep "^local function" generated_file.lua
# Output: local function calculate_user_total(user_id)

# Check error handling (should use pcall)
grep "pcall" generated_file.lua
# Output: local status, result = pcall(function()
```

### Example: Using Test Commands

Apply discovered test commands from Testing Protocols:

```bash
#!/bin/bash
# run_tests.sh - Uses discovered test commands

# Discovered from CLAUDE.md
test_suite_cmd=":TestSuite"

# Run in Neovim
nvim --headless -c "$test_suite_cmd" -c "qa"
```

### Example: Subdirectory Override Logic

Merge parent and subdirectory standards (subdirectory overrides parent):

Root CLAUDE.md:
```markdown
## Code Standards
[Used by: /implement, /refactor, /plan]

### General Principles
- **Indentation**: 2 spaces, expandtab
- **Line Length**: ~100 characters (soft limit)
- **Naming**: snake_case for variables/functions
```

src/frontend/CLAUDE.md:
```markdown
## Code Standards
[Used by: /implement, /refactor, /plan]

This frontend CLAUDE.md extends the root CLAUDE.md.

### JavaScript-Specific
- **Indentation**: 2 spaces, expandtab (inherited from root)
- **Line Length**: 80 characters (override for frontend)
- **Naming**: camelCase for JavaScript (override)
- **Module System**: ES6 imports (frontend-specific)
```

Merging logic:

```bash
#!/bin/bash
# merge_standards.sh

root_claude="CLAUDE.md"
subdir_claude="src/frontend/CLAUDE.md"

# Function to get field value
get_field() {
  local file=$1
  local field=$2
  grep "^\- \*\*$field\*\*:" "$file" | sed 's/.*: //'
}

# Extract values (subdirectory overrides root)
indentation=$(get_field "$subdir_claude" "Indentation" || get_field "$root_claude" "Indentation")
line_length=$(get_field "$subdir_claude" "Line Length" || get_field "$root_claude" "Line Length")
naming=$(get_field "$subdir_claude" "Naming" || get_field "$root_claude" "Naming")

echo "Merged Standards:"
echo "  Indentation: $indentation"
echo "  Line Length: $line_length"
echo "  Naming: $naming"
```

Output:
```
Merged Standards:
  Indentation: 2 spaces, expandtab
  Line Length: 80 characters (override for frontend)
  Naming: camelCase for JavaScript (override)
```

### Example: Validating Documentation Policy

Check if README.md meets Documentation Policy requirements:

```bash
#!/bin/bash
# validate_documentation.sh

directory="$1"

# Check if README.md exists
if [ ! -f "$directory/README.md" ]; then
  echo "FAIL: Missing README.md in $directory"
  exit 1
fi

readme="$directory/README.md"

# Check for required sections
required=(
  "^## Purpose"
  "^## Module"
  "^## Usage"
  "^## Navigation"
)

for pattern in "${required[@]}"; do
  if ! grep -q "$pattern" "$readme"; then
    echo "WARNING: README.md missing section matching: $pattern"
  else
    echo "OK: Found section matching: $pattern"
  fi
done
```

Output:
```
OK: Found section matching: ^## Purpose
OK: Found section matching: ^## Module
WARNING: README.md missing section matching: ^## Usage
OK: Found section matching: ^## Navigation
```

## Verification and Compliance

Document how the command verifies compliance before completion.

### Compliance Checklist

Before marking work complete:
- [ ] Code style matches CLAUDE.md specifications
- [ ] Naming follows project conventions
- [ ] Tests follow testing standards
- [ ] Documentation meets policy requirements

### Verification Methods

- **Linting**: Run project linter if specified in CLAUDE.md
- **Pattern Matching**: Check naming, indentation programmatically
- **Manual Review**: Prompt user to review against standards

### Example: Compliance Verification Script

Verify generated code matches CLAUDE.md standards before commit:

```bash
#!/bin/bash
# verify_compliance.sh

file="$1"
claude_md="CLAUDE.md"

# Extract standards
expected_indent=$(grep "^\- \*\*Indentation\*\*:" "$claude_md" | sed 's/.*: //')
expected_naming=$(grep "^\- \*\*Naming\*\*:" "$claude_md" | sed 's/.*: //')

echo "Verifying $file against CLAUDE.md standards..."

# Check indentation
if [[ "$expected_indent" =~ "2 spaces" ]]; then
  if grep -q $'\t' "$file"; then
    echo "FAIL: Found tabs, expected spaces"
    exit 1
  fi
  echo "OK: Indentation uses spaces"
fi

# Check naming convention
if [[ "$expected_naming" =~ "snake_case" ]]; then
  # Check for camelCase functions (violation)
  if grep -q "^local function [a-z][a-zA-Z]*[A-Z]" "$file"; then
    echo "FAIL: Found camelCase function, expected snake_case"
    grep "^local function [a-z][a-zA-Z]*[A-Z]" "$file"
    exit 1
  fi
  echo "OK: Functions use snake_case"
fi

echo "Compliance verification passed"
```

Output (passing):
```
Verifying module.lua against CLAUDE.md standards...
OK: Indentation uses spaces
OK: Functions use snake_case
Compliance verification passed
```

Output (failing):
```
Verifying module.lua against CLAUDE.md standards...
OK: Indentation uses spaces
FAIL: Found camelCase function, expected snake_case
local function calculateTotal(items)
```

## Error Handling and Fallbacks

Define fallback behavior when CLAUDE.md is missing or incomplete.

### Fallback Strategy

When CLAUDE.md not found or incomplete:

1. **Use Language Defaults**: Apply sensible language-specific conventions
2. **Suggest Creation**: Recommend running `/setup` to create CLAUDE.md
3. **Graceful Degradation**: Continue with reduced functionality
4. **Document Limitations**: Note which standards could not be applied

### Example: Fallback Implementation

Handle missing CLAUDE.md gracefully:

```bash
#!/bin/bash
# apply_standards_with_fallback.sh

file_to_generate="$1"
language="$2"

# Try to discover CLAUDE.md
claude_md=$(find_claude_md)

if [ -n "$claude_md" ]; then
  # Use standards from CLAUDE.md
  indentation=$(extract_field "$claude_md" "Indentation")
  naming=$(extract_field "$claude_md" "Naming")
  echo "Using standards from: $claude_md"
else
  # Fallback to language defaults
  case "$language" in
    lua)
      indentation="2 spaces"
      naming="snake_case"
      ;;
    javascript)
      indentation="2 spaces"
      naming="camelCase"
      ;;
    python)
      indentation="4 spaces"
      naming="snake_case"
      ;;
  esac
  echo "CLAUDE.md not found, using $language defaults"
  echo "Suggestion: Run /setup to create CLAUDE.md"
fi

echo "Applying standards: indentation=$indentation, naming=$naming"
# Generate code with these standards...
```

Output (with CLAUDE.md):
```
Using standards from: /home/user/project/CLAUDE.md
Applying standards: indentation=2 spaces, expandtab, naming=snake_case
```

Output (without CLAUDE.md):
```
CLAUDE.md not found, using lua defaults
Suggestion: Run /setup to create CLAUDE.md
Applying standards: indentation=2 spaces, naming=snake_case
```

## Cross-Command Integration

Commands should reference each other's standards usage to show workflow integration.

### Standards Flow

Standard command workflow for feature development:

1. `/report` - Researches topic (no standards needed)
2. `/plan` - Discovers and captures standards in plan metadata
3. `/implement` - Applies standards during code generation
4. `/test` - Verifies using standards-defined test commands
5. `/document` - Documents following standards format
6. `/refactor` - Validates against standards

### Example: Standards Flow Through Commands

**Plan Metadata** (from `/plan`):
```markdown
## Metadata
- **Standards File**: /home/user/project/CLAUDE.md
- **Code Standards**: 2 space indent, snake_case naming
- **Test Commands**: `:TestSuite`
- **Documentation**: README required per directory
```

**Implementation** (from `/implement`):
```lua
-- Standards from plan metadata + CLAUDE.md discovery
-- Indentation: 2 spaces (from CLAUDE.md)
-- Naming: snake_case (from CLAUDE.md)

local function process_user_data(user_id)  -- snake_case
  return database.query({                  -- 2-space indent
    id = user_id
  })
end
```

**Testing** (from `/test`):
```bash
# Test command from CLAUDE.md: `:TestSuite`
nvim --headless -c ":TestSuite" -c "qa"
```

**Documentation** (from `/document`):
```markdown
# Data Processing Module

## Purpose
Processes user data from database queries.

## Modules

### process.lua
Main processing functions for user data operations.

## Navigation
- [← Parent Directory](../README.md)
```

## Command Architecture Standards Integration

When developing commands or agents, CLAUDE.md standards discovery is complemented by **command architecture standards** which govern how command files themselves are structured.

### Two Types of Standards

**CLAUDE.md Standards** (this guide):
- Project-specific coding standards (indentation, naming, error handling)
- Testing protocols and test commands
- Documentation policies
- Language-specific conventions
- Discovered at runtime by commands

**Command Architecture Standards** ([command_architecture_standards.md](../reference/architecture/overview.md)):
- How command/agent files are structured (Standards 1-5)
- How commands pass context between agents (Standards 6-8)
- How commands manage file size and complexity (Standards 9-11)
- Apply to `.claude/commands/*.md` and `.claude/agents/*.md` files themselves
- Apply during command development, not runtime

### When to Use Each

**Use CLAUDE.md Standards** when:
- Generating user code (not command files)
- Running tests on user code
- Creating documentation for user projects
- Applying project-specific conventions

**Use Command Architecture Standards** when:
- Writing or modifying command files (`.claude/commands/*.md`)
- Creating agent files (`.claude/agents/*.md`)
- Deciding what to keep inline vs extract to utilities
- Implementing context-efficient agent invocations
- Refactoring command file structure

### Example: Two Standards in One Command

A command file follows **both** standard types:

```markdown
---
allowed-tools: Read, Write, Edit, Bash
description: Implementation command
---

# Implement Command

<!-- Command Architecture Standard 1: Inline execution requirements -->
I'll implement the feature following these steps:
1. Discover project standards from CLAUDE.md
2. Generate code matching discovered standards
3. Run tests specified in CLAUDE.md
4. Create documentation per CLAUDE.md policy

## Standards Discovery and Application

<!-- CLAUDE.md standards discovery (this guide) -->
### Discovery Process
1. Locate CLAUDE.md recursively upward
2. Parse Code Standards section
3. Extract indentation, naming, error handling
4. Apply during code generation

<!-- Command Architecture Standard 6: Metadata-only passing -->
### Research Integration
For research reports, I'll extract metadata instead of passing full content:

Task {
  subagent_type: "general-purpose"
  description: "Research using researcher protocol"
  prompt: "Read and follow: .claude/agents/researcher.md

          Research [topic].

          Return: {path, 50-word summary, key_findings}"
}

<!-- Apply CLAUDE.md standards to generated user code -->
After research, I'll generate code matching CLAUDE.md standards:
- Indentation: {discovered_indentation}
- Naming: {discovered_naming}
- Error handling: {discovered_error_handling}
```

In this example:
- Command file structure follows **Command Architecture Standards** (inline execution, metadata-only passing)
- Generated user code follows **CLAUDE.md Standards** (indentation, naming from project CLAUDE.md)

### Integration Examples

**Command Files** (command_architecture_standards.md applies):
- `.claude/commands/implement.md` - Must have inline execution steps (Standard 1)
- `.claude/commands/orchestrate.md` - Must use metadata-only artifact passing (Standard 6)
- `.claude/agents/researcher.md` - Must have inline behavioral guidelines (Standard 1)

**User Code** (CLAUDE.md standards apply):
- `src/module.lua` - Follows indentation, naming from project CLAUDE.md
- `tests/spec.lua` - Uses test patterns from CLAUDE.md Testing Protocols
- `docs/README.md` - Follows format from CLAUDE.md Documentation Policy

**Utility Libraries** (neither applies directly):
- `.claude/lib/workflow/metadata-extraction.sh` - General bash best practices
- `.claude/lib/workflow/checkpoint-utils.sh` - Internal utility conventions

### Cross-References

When implementing standards discovery in commands, reference both standard types:

```markdown
## Standards Discovery and Application

This command follows:
- **[Command Architecture Standards](../reference/architecture/overview.md)** for command file structure (Standards 1-11)
- **CLAUDE.md Standards** (this guide) for project-specific code generation

### Discovery Process
[CLAUDE.md discovery steps from this guide]

### Context Preservation
[Standard 6-8 from command_architecture_standards.md]

### Application
[Apply CLAUDE.md standards to generated code]
```

### References

- [command_architecture_standards.md](../reference/architecture/overview.md) - Command file structure standards (Standards 1-11)
- [CLAUDE.md Section Schema](../reference/standards/claude-md-schema.md) - Project CLAUDE.md format
- [Creating Commands](../development/command-development/command-development-fundamentals.md) - Command development guide integrating both standard types

---

## Quick Reference

### Command Integration Checklist

Use this checklist when adding standards integration to a command:

- [ ] Command has "Standards Discovery and Application" section
- [ ] Discovery process is documented (4 steps minimum)
- [ ] Standards sections used are listed explicitly
- [ ] Application method is described with examples
- [ ] Compliance verification steps are defined
- [ ] Fallback behavior is documented
- [ ] Integration with other commands is noted
- [ ] Error cases are handled

### Complete Command Template

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

### Best Practices

**DO**:
1. Make Discovery Explicit - Always document the discovery process
2. Prioritize CLAUDE.md - Check CLAUDE.md before other sources
3. Show Examples - Provide concrete examples of standards application
4. Verify Compliance - Include verification steps
5. Handle Missing Gracefully - Define fallback behavior

**DON'T**:
1. Assume Standards Exist - Always check and handle missing CLAUDE.md
2. Use Vague Language - Be specific about what standards are applied
3. Skip Subdirectory Check - Always check for more specific standards
4. Ignore Inheritance - Respect subdirectory override rules
5. Forget Error Cases - Document what happens when standards incomplete

## Troubleshooting

### Issue: CLAUDE.md Not Found

**Symptom**: Command reports "CLAUDE.md not found"

**Solution**:
```bash
# Verify search path
pwd  # Check current directory
find . -name "CLAUDE.md"  # Search from current location
find $(pwd) -maxdepth 5 -name "CLAUDE.md"  # Limit search depth
```

Create CLAUDE.md if missing:
```bash
/setup  # Run setup command to create CLAUDE.md
```

### Issue: Section Parsing Fails

**Symptom**: Command can't extract Code Standards section

**Solution**: Verify section marker format in CLAUDE.md:
```bash
# Check section headers
grep "^## " CLAUDE.md

# Verify section format
awk '/^## Code Standards/,/^## [^#]/' CLAUDE.md
```

Section markers must be:
- Level 2 headers (`## Section Name`)
- Followed by `[Used by: ...]` metadata line
- Ended by next level 2 header or EOF

### Issue: Standards Not Applied

**Symptom**: Generated code doesn't match CLAUDE.md standards

**Solution**: Check discovery logs:
```bash
# Add debug logging to discovery script
echo "DEBUG: Found CLAUDE.md at: $claude_md"
echo "DEBUG: Extracted indentation: $indentation"
echo "DEBUG: Extracted naming: $naming"
```

Verify extraction logic:
```bash
# Test field extraction
grep "^\- \*\*Indentation\*\*:" CLAUDE.md
grep "^\- \*\*Naming\*\*:" CLAUDE.md
```

### Issue: Subdirectory Override Not Working

**Symptom**: Subdirectory CLAUDE.md values not taking precedence

**Solution**: Check merge logic order:
```bash
# Subdirectory should be checked FIRST
subdir_value=$(get_field "$subdir_claude" "Field" || get_field "$root_claude" "Field")

# Not: root_value=$(get_field "$root_claude" "Field")  # Wrong!
```

Verify subdirectory CLAUDE.md is detected:
```bash
if [ -f "$target_dir/CLAUDE.md" ]; then
  echo "Found subdirectory CLAUDE.md: $target_dir/CLAUDE.md"
fi
```

## References

- [CLAUDE.md Section Schema](../reference/standards/claude-md-schema.md) - Section format specification
- [Command Patterns](command-patterns.md) - Command development patterns
- [Command Reference](../reference/standards/command-reference.md) - Full command documentation
- Root CLAUDE.md - Live standards example
- nvim/CLAUDE.md - Subdirectory standards example
