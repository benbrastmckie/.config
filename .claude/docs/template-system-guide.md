# Template System Guide

Comprehensive guide for creating and using workflow templates in the Claude Code system.

## Table of Contents

- [Overview](#overview)
- [Template Structure](#template-structure)
- [Variable Substitution](#variable-substitution)
- [Creating Custom Templates](#creating-custom-templates)
- [Using Templates](#using-templates)
- [Best Practices](#best-practices)
- [Examples](#examples)

## Overview

The template system enables rapid implementation plan generation for common development patterns. Templates provide pre-structured phases, tasks, and success criteria with flexible variable substitution.

### Benefits

- **Time Savings**: 60-80% reduction in planning time for repetitive features
- **Consistency**: Enforces best practices across similar implementations
- **Reusability**: Templates work across projects with minimal customization
- **Customization**: Create project-specific templates for common patterns

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│ User Command: /plan-from-template <template-name>      │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│ Template Loading (.claude/templates/*.yaml)            │
├─────────────────────────────────────────────────────────┤
│ • Locate template file                                  │
│ • Validate YAML structure                               │
│ • Extract metadata and variables                        │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│ Variable Collection                                     │
├─────────────────────────────────────────────────────────┤
│ • Identify required variables                           │
│ • Prompt user for values                                │
│ • Apply default values                                  │
│ • Build substitution JSON                               │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│ Variable Substitution                                   │
├─────────────────────────────────────────────────────────┤
│ • Replace {{variables}} with values                     │
│ • Process {{#if}} conditionals                          │
│ • Process {{#each}} iterations                          │
│ • Handle edge cases                                     │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│ Plan Generation                                         │
├─────────────────────────────────────────────────────────┤
│ • Format as implementation plan                         │
│ • Add metadata and numbering                            │
│ • Save to specs/plans/NNN_name.md                       │
│ • Report completion                                     │
└─────────────────────────────────────────────────────────┘
```

## Template Structure

Templates are written in YAML format with specific sections:

### Basic Structure

```yaml
# Template Metadata
name: "Template Display Name"
description: "Brief description of template purpose"
author: "Optional author name"
version: "1.0"

# Variable Definitions
variables:
  - name: variable_name
    description: "What this variable represents"
    type: string
    required: true
    default: "optional default value"

# Plan Structure
plan:
  title: "{{variable_name}} Implementation"

  overview: |
    Multi-line overview description.
    Can reference {{variables}} here.

  phases:
    - name: "Phase Name"
      complexity: "Low|Medium|High"
      tasks:
        - "Task description with {{variable}}"
        - "Another task"

  success_criteria:
    - "Criterion with {{variable}}"

  estimated_hours: "8"
```

### Required Fields

- **name**: Template display name (string)
- **description**: Template purpose (string)
- **variables** OR **phases**: At least one must be present

### Optional Fields

- **author**: Template creator
- **version**: Template version
- **plan.title**: Plan title (can use variables)
- **plan.overview**: Plan overview (multi-line)
- **plan.success_criteria**: Success criteria list
- **plan.estimated_hours**: Time estimate

### Variable Definitions

Each variable in the `variables` list can have:

```yaml
- name: variable_name          # Required: variable identifier
  description: "Description"   # Optional: prompt text
  type: string                 # Optional: string|array|boolean
  required: true               # Optional: true|false (default: false)
  default: "value"             # Optional: default value if not provided
```

### Phase Structure

```yaml
phases:
  - name: "Phase Name"         # Required: phase identifier
    complexity: "Medium"       # Optional: Low|Medium|High
    estimated_hours: "4"       # Optional: time estimate
    dependencies: []           # Optional: phase number dependencies
    tasks:                     # Required: task list
      - "Task 1"
      - "Task 2"
```

## Variable Substitution

The template system supports three types of variable substitution:

### 1. Simple Variables

Replace placeholders with values:

```yaml
# Template
title: "{{feature_name}} Implementation"
overview: "Implementing {{feature_name}} for {{project_name}}"

# Variables
{"feature_name": "User Auth", "project_name": "MyApp"}

# Result
title: "User Auth Implementation"
overview: "Implementing User Auth for MyApp"
```

### 2. Conditionals

Include content based on boolean values:

#### If Statements

```yaml
# Template
{{#if use_authentication}}
- name: "Authentication Setup"
  tasks:
    - "Configure auth system"
{{/if}}

# Variables (true case)
{"use_authentication": "true"}

# Result
- name: "Authentication Setup"
  tasks:
    - "Configure auth system"

# Variables (false case)
{"use_authentication": "false"}

# Result
(content excluded)
```

#### Unless Statements

```yaml
# Template
{{#unless skip_tests}}
- name: "Testing"
  tasks:
    - "Write tests"
{{/unless}}

# Variables
{"skip_tests": "false"}

# Result
- name: "Testing"
  tasks:
    - "Write tests"
```

### 3. Array Iteration

Loop over array values:

```yaml
# Template
phases:
  - name: "Data Model"
    tasks:
      {{#each fields}}
      - "Add {{this}} field to model"
      {{/each}}

# Variables
{"fields": ["name", "email", "password"]}

# Result
phases:
  - name: "Data Model"
    tasks:
      - "Add name field to model"
      - "Add email field to model"
      - "Add password field to model"
```

#### Array Helpers

Within `{{#each}}` blocks:

- `{{this}}`: Current item value
- `{{@index}}`: Zero-based index (0, 1, 2, ...)
- `{{@first}}`: true for first item, false otherwise
- `{{@last}}`: true for last item, false otherwise

```yaml
# Template
{{#each endpoints}}
- Endpoint {{@index}}: {{this}}{{#unless @last}}, {{/unless}}
{{/each}}

# Variables
{"endpoints": ["/users", "/posts", "/comments"]}

# Result
- Endpoint 0: /users,
- Endpoint 1: /posts,
- Endpoint 2: /comments
```

### Substitution Rules

1. **Missing variables**: Placeholders remain unchanged (e.g., `{{undefined}}`)
2. **Truthy values**: Non-empty strings, "true", numbers > 0
3. **Falsy values**: Empty string, "false", "0", "null", undefined
4. **Array format**: JSON arrays `["item1", "item2"]`
5. **Escaping**: Not currently supported (avoid `{{` in literal text)

## Creating Custom Templates

### Step 1: Choose Template Location

Custom templates go in `.claude/templates/custom/`:

```bash
# Create custom directory if it doesn't exist
mkdir -p .claude/templates/custom

# Create your template
nvim .claude/templates/custom/my-feature.yaml
```

### Step 2: Define Template Structure

Start with the basic template structure:

```yaml
name: "My Custom Feature Template"
description: "Template for implementing my custom feature pattern"
author: "Your Name"
version: "1.0"

variables:
  - name: feature_name
    description: "Name of the feature"
    required: true

  - name: complexity
    description: "Feature complexity (Low/Medium/High)"
    required: false
    default: "Medium"

plan:
  title: "{{feature_name}} Implementation"

  overview: |
    Implementation plan for {{feature_name}} feature.
    Complexity: {{complexity}}

  phases:
    - name: "Phase 1: Planning"
      complexity: "{{complexity}}"
      tasks:
        - "Define requirements for {{feature_name}}"
        - "Create architecture diagram"

    - name: "Phase 2: Implementation"
      complexity: "{{complexity}}"
      tasks:
        - "Implement {{feature_name}} core logic"
        - "Add error handling"

    - name: "Phase 3: Testing"
      complexity: "Low"
      tasks:
        - "Write tests for {{feature_name}}"
        - "Run test suite"

  success_criteria:
    - "{{feature_name}} fully functional"
    - "All tests passing"
    - "Documentation complete"

  estimated_hours: "8"
```

### Step 3: Add Variable Flexibility

Use conditionals and arrays for flexibility:

```yaml
variables:
  - name: feature_name
    required: true

  - name: components
    description: "List of components (comma-separated)"
    required: false

  - name: needs_database
    description: "Requires database changes (true/false)"
    required: false
    default: "false"

plan:
  phases:
    - name: "Component Setup"
      tasks:
        {{#each components}}
        - "Create {{this}} component"
        {{/each}}

    {{#if needs_database}}
    - name: "Database Migration"
      tasks:
        - "Create migration for {{feature_name}}"
        - "Update schema"
    {{/if}}
```

### Step 4: Test Your Template

Test template validation:

```bash
# Validate syntax
.claude/lib/parse-template.sh .claude/templates/custom/my-feature.yaml validate

# Extract metadata
.claude/lib/parse-template.sh .claude/templates/custom/my-feature.yaml extract-metadata

# Test substitution
echo '{"feature_name":"Test","complexity":"High"}' | \
  .claude/lib/substitute-variables.sh .claude/templates/custom/my-feature.yaml -
```

### Step 5: Use Your Template

```bash
# In Claude Code
/plan-from-template custom/my-feature
```

## Using Templates

### Command Syntax

```bash
/plan-from-template <template-name>
```

Template names:
- Standard templates: `crud-feature`, `api-endpoint`, `refactoring`
- Custom templates: `custom/my-template`

### Interactive Flow

1. **Template Selection**: Command loads specified template
2. **Validation**: Checks template structure
3. **Variable Prompts**: Asks for each required variable
4. **Value Collection**: Gathers user input
5. **Substitution**: Applies variables to template
6. **Plan Generation**: Creates numbered plan file
7. **Confirmation**: Reports plan location

### Example Session

```
You: /plan-from-template crud-feature

Claude: Loading template: crud-feature
Template: CRUD Feature Implementation (v1.0)

Please provide values for the following variables:

entity_name (required): User
fields (comma-separated): name, email, password, role
use_auth (true/false) [default: true]: true
database_type [default: postgresql]: postgresql

Generating plan...

Plan created: specs/plans/035_user_crud_implementation.md
```

## Best Practices

### Template Design

1. **Start Simple**: Begin with basic structure, add complexity as needed
2. **Clear Variables**: Use descriptive variable names and descriptions
3. **Sensible Defaults**: Provide defaults for optional variables
4. **Flexible Phases**: Use conditionals to handle optional phases
5. **Reusable Patterns**: Abstract common workflows into templates

### Variable Naming

- Use `snake_case` for variable names
- Be descriptive: `entity_name` not `name`
- Indicate type in description: "List of fields (comma-separated)"
- Group related variables: `auth_enabled`, `auth_provider`, `auth_config`

### Phase Organization

```yaml
# Good: Clear, focused phases
phases:
  - name: "Data Model Design"
    tasks:
      - "Define entity schema"
      - "Create relationships"

  - name: "API Implementation"
    tasks:
      - "Create endpoints"
      - "Add validation"

# Avoid: Vague, overly broad phases
phases:
  - name: "Setup"
    tasks:
      - "Do everything"
      - "Make it work"
```

### Conditional Usage

```yaml
# Good: Optional but complete phases
{{#if use_caching}}
- name: "Caching Layer"
  complexity: "Medium"
  tasks:
    - "Setup Redis connection"
    - "Implement cache strategies"
    - "Add cache invalidation"
{{/if}}

# Avoid: Incomplete or confusing conditionals
{{#if maybe_cache}}
- "Maybe add caching?"
{{/if}}
```

### Array Patterns

```yaml
# Good: Clear iteration with context
{{#each api_endpoints}}
- name: "{{this}} Endpoint Implementation"
  tasks:
    - "Create {{this}} handler"
    - "Add {{this}} validation"
    - "Test {{this}} endpoint"
{{/each}}

# Avoid: Bare iteration without context
{{#each endpoints}}
- {{this}}
{{/each}}
```

## Examples

### Example 1: Feature Flag Template

```yaml
name: "Feature Flag Implementation"
description: "Add feature flag with gradual rollout support"
version: "1.0"

variables:
  - name: flag_name
    description: "Feature flag name"
    required: true

  - name: default_enabled
    description: "Default state (true/false)"
    required: false
    default: "false"

  - name: rollout_strategy
    description: "Rollout strategy (percentage/user_list/all)"
    required: false
    default: "percentage"

plan:
  title: "{{flag_name}} Feature Flag"

  overview: |
    Implement feature flag for {{flag_name}} with {{rollout_strategy}} rollout.
    Default state: {{default_enabled}}

  phases:
    - name: "Flag Definition"
      complexity: "Low"
      tasks:
        - "Define {{flag_name}} flag in configuration"
        - "Set default to {{default_enabled}}"
        - "Configure {{rollout_strategy}} rollout"

    - name: "Integration"
      complexity: "Medium"
      tasks:
        - "Add flag checks to relevant code paths"
        - "Implement fallback behavior"
        - "Add logging for flag evaluation"

    - name: "Testing"
      complexity: "Medium"
      tasks:
        - "Test with flag enabled"
        - "Test with flag disabled"
        - "Test rollout strategy"

    {{#if rollout_strategy}}
    - name: "Rollout Management"
      complexity: "Low"
      tasks:
        - "Configure {{rollout_strategy}} parameters"
        - "Setup monitoring for flag usage"
        - "Document rollout plan"
    {{/if}}

  success_criteria:
    - "{{flag_name}} flag functional"
    - "Rollout strategy working"
    - "All code paths tested"

  estimated_hours: "4"
```

### Example 2: Database Migration Template

```yaml
name: "Database Migration"
description: "Create and apply database schema migration"
version: "1.0"

variables:
  - name: migration_name
    description: "Migration name (e.g., add_user_roles)"
    required: true

  - name: tables
    description: "Tables to modify (comma-separated)"
    required: true

  - name: reversible
    description: "Include rollback (true/false)"
    required: false
    default: "true"

plan:
  title: "{{migration_name}} Migration"

  phases:
    - name: "Migration Creation"
      complexity: "Low"
      tasks:
        - "Generate migration file: {{migration_name}}"
        {{#each tables}}
        - "Define {{this}} table changes"
        {{/each}}
        {{#if reversible}}
        - "Write down migration"
        - "Write up migration"
        {{/if}}

    - name: "Testing"
      complexity: "Medium"
      tasks:
        - "Apply migration to test database"
        - "Verify schema changes"
        {{#if reversible}}
        - "Test rollback procedure"
        - "Re-apply migration"
        {{/if}}

    - name: "Deployment"
      complexity: "Low"
      tasks:
        - "Backup production database"
        - "Apply migration to production"
        - "Verify application functionality"

  success_criteria:
    - "Migration applies successfully"
    - "No data loss"
    {{#if reversible}}
    - "Rollback tested and working"
    {{/if}}
