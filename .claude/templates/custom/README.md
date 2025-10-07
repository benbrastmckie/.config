# Custom Templates Directory

User-defined workflow templates for project-specific planning patterns.

## Purpose

This directory contains custom templates created by users to accelerate planning for project-specific workflows. Custom templates extend the standard templates with patterns unique to your development environment.

## Template Files

### example-feature.yaml
Example template demonstrating custom template structure:
- Shows proper YAML format and required fields
- Demonstrates variable definitions with defaults
- Includes multiple phases with task templates
- Uses variable substitution (simple, conditionals)
- Provides complete working example

**Variables**:
- `feature_name` - Feature name (required)
- `component_name` - Main component name (required)
- `estimated_hours` - Time estimate (default: "8")

**Usage**: `/plan-from-template custom/example-feature`

## Creating Custom Templates

### 1. Create Template File
```bash
nvim .claude/templates/custom/my-workflow.yaml
```

### 2. Define Template Structure
Follow the format in `example-feature.yaml`:
```yaml
name: "My Custom Workflow"
description: "Description of when to use this template"
author: "Your Name"
version: "1.0"

variables:
  - name: required_var
    description: "Description for user prompt"
    required: true

plan:
  title: "{{required_var}} Implementation"
  phases:
    - name: "Phase 1"
      tasks:
        - "Task with {{required_var}}"
```

### 3. Use Template
```bash
/plan-from-template custom/my-workflow
```

## Template Guidelines

### Required Fields
- `name` - Display name for template
- `description` - When to use this template
- `variables` OR `phases` - At least one must be present

### Variable Best Practices
- Use descriptive names: `entity_name` not `name`
- Provide clear descriptions for user prompts
- Set sensible defaults for optional variables
- Use required:true only when necessary

### Phase Organization
- Keep phases focused and specific
- Use conditionals for optional phases
- Provide complete task lists
- Include success criteria

## Variable Substitution

### Simple Variables
```yaml
title: "{{feature_name}} Implementation"
```

### Conditionals
```yaml
{{#if use_auth}}
- name: "Authentication Setup"
{{/if}}
```

### Arrays
```yaml
{{#each components}}
- Create {{this}} component
{{/each}}
```

See [Template System Guide](../../docs/template-system-guide.md) for complete syntax reference.

## Examples

### Feature Template
```yaml
name: "Custom Feature Implementation"
description: "Standard feature with optional database"

variables:
  - name: feature_name
    required: true
  - name: needs_database
    required: false
    default: "false"

plan:
  title: "{{feature_name}} Feature"
  phases:
    - name: "Implementation"
      tasks:
        - "Implement {{feature_name}}"

    {{#if needs_database}}
    - name: "Database"
      tasks:
        - "Create migration"
    {{/if}}
```

## Documentation

- **Parent Directory**: [templates/](../README.md)
- **Template Guide**: [Template System Guide](../../docs/template-system-guide.md)
- **Standard Templates**: [crud-feature](../crud-feature.yaml), [api-endpoint](../api-endpoint.yaml), [refactoring](../refactoring.yaml)

## Navigation

- [← Parent Directory](../README.md)
- [Template System Guide](../../docs/template-system-guide.md)
- [.claude/ Root](../../README.md)
