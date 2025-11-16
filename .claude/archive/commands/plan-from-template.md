---
allowed-tools: Read, Write, Bash, Grep, Glob
argument-hint: <template-name> or --list-categories or --category <category>
description: Generate a structured implementation plan from a reusable template with variable substitution
command-type: primary
dependent-commands: plan, implement
---

# Create Implementation Plan from Template

I'll generate a structured implementation plan from a predefined template with interactive variable substitution.

## Arguments
$ARGUMENTS

## Overview

This command streamlines plan creation for common feature patterns by:
1. Loading a predefined template (with optional category filtering)
2. Prompting for required variables interactively
3. Applying variable substitution using the template system
4. Generating a numbered implementation plan
5. Saving to the appropriate specs/plans/ directory

## Template Categories

Templates are organized by category for easier discovery:
- **backend**: API endpoints, backend services
- **feature**: Full-stack features, CRUD operations
- **debugging**: Issue investigation and fixes
- **documentation**: Documentation updates and syncing
- **testing**: Test suite implementation
- **migration**: Breaking changes and migrations
- **research**: Research reports and investigations
- **refactoring**: Code cleanup and consolidation

## Process

### Step 1: Handle Arguments and Load Template

I'll first check what argument was provided and handle accordingly:

**If `--list-categories` provided**:
- Use Bash to list all unique categories from templates:
  ```bash
  grep -h "^category:" .claude/commands/templates/*.yaml 2>/dev/null | \
    sed 's/category: "\(.*\)"/\1/' | sort -u
  ```
- For each category, count templates and display in format:
  ```
  Available template categories:
    - backend (2 templates)
    - feature (3 templates)
    ...
  ```
- Stop execution after displaying categories

**If `--category <category>` provided**:
- Extract category name from second argument
- Use Bash to find all templates with matching category
- For each matching template, extract and display:
  - Template filename (without .yaml)
  - Name
  - Description
  - Complexity level
  - Estimated time
- Stop execution after displaying templates

**If template name provided**:
- Check if template exists in `.claude/commands/templates/<name>.yaml`
- If not found, check `.claude/commands/templates/custom/<name>.yaml`
- If still not found, display error with list of available templates
- Once found, validate template structure using:
  ```bash
  .claude/lib/parse-template.sh <template-file> validate
  ```
- If validation fails, display error and stop

### Step 2: Extract Template Metadata

I'll extract template information and variable definitions:

**Extract template metadata**:
- Use Bash to call parse-template.sh:
  ```bash
  .claude/lib/parse-template.sh <template-file> extract-metadata
  ```
- Parse the JSON output to extract name and description
- Display template name and description to the user

**Extract variable definitions**:
- Use Bash to call parse-template.sh:
  ```bash
  .claude/lib/parse-template.sh <template-file> extract-variables
  ```
- Returns JSON array of variables with fields: name, type, required
- Example format:
  ```json
  [
    {"name":"entity_name","type":"string","required":true},
    {"name":"fields","type":"array","required":true},
    {"name":"use_auth","type":"boolean","required":false}
  ]
  ```

### Step 3: Collect Variable Values

I'll prompt the user for each variable value interactively:

**For each variable in the extracted variable list**:
1. Display prompt: `variable_name (type): `
2. Wait for user input
3. Validate:
   - If required and empty → display error and re-prompt
   - If optional and empty → skip this variable
4. Format value based on type:
   - **string**: Use as-is, wrap in quotes for JSON
   - **array**: Parse comma-separated input (e.g., "name, email, password") into JSON array `["name","email","password"]`
   - **boolean**: Convert true/yes/1/y → `true`, everything else → `false`
5. Build JSON object with all collected variables

**Example interaction**:
```
Please provide values for template variables:

entity_name (string): User
fields (array): name, email, password
use_auth (boolean): true
database_type (string): postgresql
```

**Result JSON**:
```json
{
  "entity_name":"User",
  "fields":["name","email","password"],
  "use_auth":true,
  "database_type":"postgresql"
}
```

**Implementation note**: Since Claude cannot use bash `read` interactively, I'll prompt the user for each variable in my response text, then wait for the user to provide the values. Once all values are collected, I'll proceed to substitution.

### Step 4: Apply Variable Substitution

I'll use the template substitution utility to generate the plan content:

**Substitution process**:
- Call substitute-variables.sh with template file and variables JSON:
  ```bash
  .claude/lib/substitute-variables.sh <template-file> '<variables-json>'
  ```
- The utility handles:
  - Simple variables: `{{entity_name}}` → `User`
  - Arrays: `{{#each fields}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}` → `name, email, password`
  - Conditionals: `{{#if use_auth}}Add authentication{{/if}}` → `Add authentication` (if true)
- If substitution fails, display error and stop

**Example transformation**:
```yaml
# Before:
tasks:
  - "Create {{entity_name}} model"
  - "{{#if use_auth}}Add authentication{{/if}}"

# After:
tasks:
  - "Create User model"
  - "Add authentication"
```

### Step 5: Generate Plan File

I'll determine the plan number, generate the filename, and create the plan file:

**Determine specs directory**:
- Check for `specs/plans/` in current directory
- If not found, check for `.claude/specs/plans/`
- If neither exists, create `specs/plans/`

**Find next plan number**:
- List all plan files in the specs directory
- Extract three-digit numbers (001, 002, etc.)
- Find the highest number and increment by 1
- Default to 001 if no plans exist
- Format as three digits with leading zeros

**Generate feature name**:
- Try to extract `entity_name` or similar key variable from JSON
- Convert to lowercase with underscores
- If no entity_name, use template name as feature name
- Example: `entity_name:"Product"` → `product_crud_implementation`

**Create plan file** using Write tool:
- Filename format: `<specs-dir>/<number>_<feature-name>.md`
- Content structure:
  ```markdown
  # <Template Name>

  ## Metadata
  - **Date**: <current-date>
  - **Plan Number**: <NNN>
  - **Feature**: <feature-name>
  - **Template**: <template-name>
  - **Standards File**: <path-to-CLAUDE.md>

  ## Template Variables
  - entity_name: User
  - fields: ["name","email","password"]
  - use_auth: true

  ## Overview
  Generated from template: <template-name>
  <template-description>

  <substituted-plan-content>
  ```

### Step 6: Display Confirmation

I'll display a success message with next steps:

**Success output format**:
```
Plan created successfully

Plan file: <path-to-plan>
Plan number: <NNN>
Template: <template-name>

Variables used:
  - entity_name: User
  - fields: ["name","email","password"]
  - use_auth: true

Next steps:
1. Review the generated plan
2. Customize phases and tasks if needed
3. Execute the plan: /implement <plan-file>
```

## Available Templates

Use `/plan-from-template --list-categories` to see all templates organized by category.
Use `/plan-from-template --category <category>` to see templates in a specific category.

11 standard templates available in categories: backend, feature, debugging, documentation, testing, migration, research, refactoring.
Custom templates can be placed in `.claude/commands/templates/custom/`.

## Example Usage

```bash
/plan-from-template crud-feature
# Prompts for: entity_name, fields, use_auth, database_type
# Generates: specs/plans/NNN_<entity>_crud_implementation.md
```

## Error Handling

Common errors and their resolution:
- **Template not found**: Lists available templates
- **Invalid template structure**: Shows validation errors
- **Required variable missing**: Re-prompts for required values
- **Substitution failed**: Displays error with details

## Integration

**Typical workflow**: `/plan-from-template` → `/implement` → `/document`
**With research**: `/plan-from-template` → `/revise` (with reports) → `/implement`

**When to use**:
- `/plan-from-template`: Common patterns, fast generation (60-80% faster than manual)
- `/plan`: Unique features, custom structure, research-driven
- `/plan-wizard`: Guided experience with component identification

## References

- Template documentation: `.claude/commands/templates/README.md`
- Related commands: `/plan`, `/plan-wizard`, `/implement`, `/revise`
