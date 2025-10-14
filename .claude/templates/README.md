# Workflow Template System

This directory contains reusable implementation plan templates for common development patterns.

## Overview

Templates enable rapid plan generation for common feature types by providing pre-structured phases and tasks with variable substitution.

## Template Format

Templates are written in YAML with the following structure:

```yaml
name: "Template Name"
description: "Brief description of what this template is for"
variables:
  - name: variable_name
    description: "What this variable represents"
    type: string|array|boolean
    required: true|false
    default: "optional default value"
phases:
  - name: "Phase Name"
    dependencies: []  # Phase numbers this depends on
    tasks:
      - "Task description with {{variable_name}} substitution"
      - "Loop example: {{#each array_var}}Item: {{this}}{{/each}}"
      - "Conditional: {{#if boolean_var}}Do this{{/if}}"
research_topics:
  - "Research topic with {{variable_name}}"
```

## Variable Substitution Syntax

### Simple Variables
- `{{variable_name}}` - Replaced with variable value
- Example: `{{entity_name}}` → `User`

### Array Iteration
- `{{#each array_var}}...{{this}}...{{/each}}` - Loop over array items
- `{{@index}}` - Current index (0-based)
- `{{@first}}` - True for first item
- `{{@last}}` - True for last item
- Example: `{{#each fields}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}`

### Conditionals
- `{{#if variable}}...{{/if}}` - Include if truthy
- `{{#unless variable}}...{{/unless}}` - Include if falsy
- Example: `{{#if use_auth}}Add authentication{{/if}}`

## Available Templates

### Standard Templates

**crud-feature.yaml**
- Create CRUD (Create, Read, Update, Delete) features
- Variables: entity_name, fields, use_auth, database_type
- Use case: User management, product catalog, etc.

**api-endpoint.yaml**
- Implement REST API endpoints
- Variables: endpoint_path, methods, auth_required, request_schema
- Use case: API development, microservices

**refactoring.yaml**
- Structured code refactoring
- Variables: target_module, refactoring_goals, test_strategy
- Use case: Code cleanup, architecture improvements

### Custom Templates

Add custom templates directly to this directory:
- Create `my-workflow.yaml` in `templates/` directory
- Use same format as standard templates
- Reference as `my-workflow` in `/plan-from-template` command
- See `example-feature.yaml` for template structure reference
- Follow format and guidelines in this README

## Using Templates

### Create Plan from Template

```bash
/plan-from-template <template-name>
```

The command will:
1. Load the template
2. Prompt for required variables
3. Apply variable substitution
4. Generate numbered implementation plan
5. Save to specs/plans/

Example:
```bash
/plan-from-template crud-feature
# Prompts:
#   entity_name: User
#   fields: name, email, password
#   use_auth: true
#   database_type: postgresql
# Generates: specs/plans/024_user_crud_implementation.md
```

## Template Development Guidelines

### Variable Naming
- Use snake_case for variable names
- Be descriptive: `entity_name` not `name`
- Group related variables: `db_host`, `db_port`, `db_name`

### Task Specificity
- Tasks should reference specific files when possible
- Include line number hints if applicable
- Specify testing requirements
- Define validation criteria

### Phase Structure
- Keep phases focused (5-10 tasks each)
- Use dependencies to enforce order
- Include testing in each phase
- Add documentation tasks

### Research Topics
- Include 2-4 relevant research topics
- Use variable substitution for specificity
- Balance general best practices with specific patterns

## Implementation Details

### Template Parser
- Location: `.claude/utils/parse-template.sh`
- Validates template YAML structure
- Extracts metadata and phases
- Checks for required fields

### Variable Substitution Engine
- Location: `.claude/utils/substitute-variables.sh`
- Processes {{variable}} syntax
- Handles arrays with {{#each}}
- Handles conditionals with {{#if}}
- Graceful error handling for missing variables

### Plan Generator
- Location: `.claude/commands/plan-from-template.md`
- Interactive variable collection
- Template instantiation
- Plan file generation with numbering
- Cross-reference to source template

## Best Practices

### When to Use Templates
- **Use templates** for common, well-understood patterns
- **Use /plan** for unique, complex features
- **Use /plan-wizard** for guided planning with research

### Template Maintenance
- Review templates quarterly
- Update based on successful implementations
- Incorporate lessons learned
- Remove outdated patterns

### Variable Design
- Minimize required variables (5-7 max)
- Provide sensible defaults
- Validate variable values when possible
- Document constraints clearly

## Privacy and Security

### Template Safety
- Templates are reviewed code, not user input
- Variable values are sanitized before substitution
- No code execution in templates (declarative only)
- Templates cannot access filesystem

### Variable Validation
- Type checking enforced
- Required variables must be provided
- Arrays must be valid JSON
- No shell injection possible

## Troubleshooting

### Common Issues

**"Template not found"**
- Check template exists in `.claude/templates/`
- Verify file extension is `.yaml`
- Use `custom/` prefix for custom templates

**"Variable substitution failed"**
- Verify all required variables provided
- Check variable syntax ({{name}} not {name})
- Ensure arrays are valid JSON

**"Invalid template structure"**
- Validate YAML syntax
- Check all required fields present
- Verify phase dependencies reference valid phases


## Neovim Integration

Template files are integrated with the Neovim artifact picker for easy browsing and editing.

### Accessing Templates via Picker

- **Keybinding**: `<leader>ac` in normal mode
- **Command**: `:ClaudeCommands`
- **Category**: [Templates] section in picker

### Picker Features for Templates

**Visual Display**:
- Templates listed with descriptions from YAML files
- Local templates marked with `*` prefix
- Descriptions automatically extracted from template metadata

**Display Format**:
```
[Templates]                   Workflow templates

* ├─ crud-feature.yaml         CRUD feature implementation
  └─ api-endpoint.yaml         API endpoint scaffold
```

**Quick Actions**:
- `<CR>` - Open template file for editing
- `<C-l>` - Load template locally to project
- `<C-g>` - Update from global version
- `<C-s>` - Save local template to global
- `<C-e>` - Edit template file in buffer
- `<C-u>`/`<C-d>` - Scroll preview up/down

**Example Workflow**:
```vim
" Open picker
:ClaudeCommands

" Navigate to [Templates] category
" Select crud-feature.yaml
" Press <C-e> to edit template
" Customize phases and variables
```

### Template File Structure

Templates appear in the picker with descriptions extracted from their YAML metadata:

```yaml
name: "CRUD Feature"
description: "CRUD feature implementation"  # Shown in picker
variables:
  - name: entity_name
    type: string
phases:
  - name: "Phase 1"
    tasks: [...]
```

The picker automatically parses the `description` field to display template purpose.

### Creating Custom Templates

1. **Add template file** to `.claude/templates/` directory
2. **Name with `.yaml` extension** (e.g., `my-workflow.yaml`)
3. **Include description field** for picker display
4. **Use picker to edit** after creation

The picker will automatically detect new templates on next open.

### Documentation

- [Neovim Claude Integration](../../nvim/lua/neotex/plugins/ai/claude/README.md) - Integration overview
- [Commands Picker](../../nvim/lua/neotex/plugins/ai/claude/commands/README.md) - Picker documentation
- [Picker Implementation](../../nvim/lua/neotex/plugins/ai/claude/commands/picker.lua) - Source code

## References

- [Plan Wizard](../commands/plan-wizard.md) - Interactive planning
- [Plan Command](../commands/plan.md) - Manual planning
- [Implementation Standards](../../CLAUDE.md)
