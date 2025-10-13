# Standards Integration Examples

This document provides concrete examples of how commands discover, parse, and apply standards from CLAUDE.md files.

## Example 1: Discovering CLAUDE.md

### Scenario
Command `/implement` is running in `/home/user/project/src/feature/` and needs to find CLAUDE.md.

### Discovery Process

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

### Expected Output

```
Found: /home/user/project/src/CLAUDE.md
Found: /home/user/project/CLAUDE.md
Standards hierarchy:
  - /home/user/project/src/CLAUDE.md
  - /home/user/project/CLAUDE.md
```

### Result
Command uses `/home/user/project/src/CLAUDE.md` first, falls back to `/home/user/project/CLAUDE.md` for missing sections.

## Example 2: Parsing Code Standards

### CLAUDE.md Content

```markdown
## Code Standards
[Used by: /implement, /refactor, /plan]

### General Principles
- **Indentation**: 2 spaces, expandtab
- **Line Length**: ~100 characters (soft limit)
- **Naming**: snake_case for variables/functions
- **Error Handling**: Use pcall for Lua operations
```

### Extraction Script

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

### Output

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

## Example 3: Applying Code Standards

### Scenario
`/implement` command generating Lua code with discovered standards.

### Standards Applied

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

### Verification

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

## Example 4: Finding Test Commands

### CLAUDE.md Content

```markdown
## Testing Protocols
[Used by: /test, /test-all, /implement]

### Neovim Testing
- **Test Commands**: `:TestNearest`, `:TestFile`, `:TestSuite`, `:TestLast`
- **Test Pattern**: `*_spec.lua`, `test_*.lua`
- **Linting**: `<leader>l`
- **Formatting**: `<leader>mp`
```

### Extraction

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

### Output

```
Available test commands: `:TestNearest`, `:TestFile`, `:TestSuite`, `:TestLast`
  - :TestNearest
  - :TestFile
  - :TestSuite
  - :TestLast
```

### Application

```bash
#!/bin/bash
# run_tests.sh - Uses discovered test commands

# Discovered from CLAUDE.md
test_suite_cmd=":TestSuite"

# Run in Neovim
nvim --headless -c "$test_suite_cmd" -c "qa"
```

## Example 5: Checking Documentation Policy

### CLAUDE.md Content

```markdown
## Documentation Policy
[Used by: /document, /plan]

### README Requirements
Every subdirectory must have a README.md containing:
- **Purpose**: Clear explanation of directory role
- **Module Documentation**: Documentation for each file/module
- **Usage Examples**: Code examples where applicable
- **Navigation Links**: Links to parent and subdirectory READMEs
```

### Validation Script

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

### Output

```
OK: Found section matching: ^## Purpose
OK: Found section matching: ^## Module
WARNING: README.md missing section matching: ^## Usage
OK: Found section matching: ^## Navigation
```

## Example 6: Subdirectory Override

### Root CLAUDE.md

```markdown
## Code Standards
[Used by: /implement, /refactor, /plan]

### General Principles
- **Indentation**: 2 spaces, expandtab
- **Line Length**: ~100 characters (soft limit)
- **Naming**: snake_case for variables/functions
```

### src/frontend/CLAUDE.md

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

### Merging Logic

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

### Output

```
Merged Standards:
  Indentation: 2 spaces, expandtab
  Line Length: 80 characters (override for frontend)
  Naming: camelCase for JavaScript (override)
```

## Example 7: Fallback Behavior

### Scenario
No CLAUDE.md found, command uses defaults.

### Implementation

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

### Output (with CLAUDE.md)

```
Using standards from: /home/user/project/CLAUDE.md
Applying standards: indentation=2 spaces, expandtab, naming=snake_case
```

### Output (without CLAUDE.md)

```
CLAUDE.md not found, using lua defaults
Suggestion: Run /setup to create CLAUDE.md
Applying standards: indentation=2 spaces, naming=snake_case
```

## Example 8: Command-Specific Section Discovery

### Scenario
`/implement` needs to find all sections it uses.

### Discovery Script

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

### CLAUDE.md Content

```markdown
## Code Standards
[Used by: /implement, /refactor, /plan]
...

## Testing Protocols
[Used by: /test, /test-all, /implement]
...

## Documentation Policy
[Used by: /document, /plan]
...

## Standards Discovery
[Used by: all commands]
...
```

### Output

```
Finding sections for /implement...
Code Standards
Testing Protocols
Standards Discovery
```

## Example 9: Compliance Verification

### Scenario
Verifying generated code matches CLAUDE.md standards before commit.

### Verification Script

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

### Output (passing)

```
Verifying module.lua against CLAUDE.md standards...
OK: Indentation uses spaces
OK: Functions use snake_case
Compliance verification passed
```

### Output (failing)

```
Verifying module.lua against CLAUDE.md standards...
OK: Indentation uses spaces
FAIL: Found camelCase function, expected snake_case
local function calculateTotal(items)
```

## Example 10: Cross-Command Integration

### Scenario
Showing standards flow through command chain.

### Commands Used

1. `/plan` - Discovers and captures standards
2. `/implement` - Applies captured standards
3. `/test` - Verifies using test standards
4. `/document` - Documents following documentation standards

### Plan Metadata (from `/plan`)

```markdown
## Metadata
- **Standards File**: /home/user/project/CLAUDE.md
- **Code Standards**: 2 space indent, snake_case naming
- **Test Commands**: `:TestSuite`
- **Documentation**: README required per directory
```

### Implementation (from `/implement`)

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

### Testing (from `/test`)

```bash
# Test command from CLAUDE.md: `:TestSuite`
nvim --headless -c ":TestSuite" -c "qa"
```

### Documentation (from `/document`)

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

## Summary

These examples demonstrate:

1. **Discovery**: Finding CLAUDE.md files in hierarchy
2. **Parsing**: Extracting specific sections and fields
3. **Application**: Using standards to generate compliant code
4. **Verification**: Checking compliance before completion
5. **Inheritance**: Merging parent and subdirectory standards
6. **Fallback**: Handling missing CLAUDE.md gracefully
7. **Integration**: Standards flow through command chain

## References

- [Standards Integration Pattern](standards-integration-pattern.md) - General pattern
- [CLAUDE.md Section Schema](claude-md-section-schema.md) - Section formats
- Root CLAUDE.md - Live example
- nvim/CLAUDE.md - Subdirectory example
