# Plan Templates

This directory contains YAML templates used by the `/plan-from-template` command to generate implementation plans quickly.

## Purpose

Templates provide reusable structures for common development patterns, enabling fast plan generation (60-80% faster than manual planning). Each template includes:
- Phase structure
- Task checklists
- Testing protocols
- Documentation requirements
- Variable placeholders for customization

## Usage

```bash
# List all available templates by category
/plan-from-template --list-categories

# List templates in a specific category
/plan-from-template --category feature

# Generate a plan from a template
/plan-from-template crud-feature

# The command will prompt for variable values
```

## Available Templates

### Feature Development
- **crud-feature.yaml** - CRUD operations with validation and testing
- **api-endpoint.yaml** - REST API endpoint implementation
- **example-feature.yaml** - Generic feature template

### Code Quality
- **refactoring.yaml** - Code refactoring and improvement
- **refactor-consolidation.yaml** - Consolidating duplicate code
- **test-suite.yaml** - Comprehensive test implementation

### Operations
- **migration.yaml** - Data or schema migrations
- **debug-workflow.yaml** - Systematic debugging process
- **documentation-update.yaml** - Documentation improvements

### Research
- **research-report.yaml** - Structured research and analysis

## Template Variables

Templates use variable placeholders that are replaced during plan generation:

- `{{FEATURE_NAME}}` - Name of the feature being implemented
- `{{COMPONENT_NAME}}` - Specific component or module name
- `{{FILE_PATH}}` - Target file paths
- `{{DESCRIPTION}}` - Feature or task description

Variables are defined in the template's frontmatter section.

## Creating New Templates

To create a new template:

1. Copy an existing template as a starting point
2. Define variables in the frontmatter
3. Structure phases with clear objectives
4. Include comprehensive task lists
5. Add testing and validation steps
6. Document in this README

See [Command Development Guide](../../docs/guides/development/command-development/command-development-fundamentals.md) for template development guidelines.

## Related Documentation

- `/plan-from-template` command: `.claude/commands/plan-from-template.md`
- Planning workflow: `.claude/docs/concepts/development-workflow.md`
- Directory protocols: `.claude/docs/concepts/directory-protocols.md`

## Navigation

- [← Parent Directory](../README.md)
- [Related: Agent Templates](../../agents/templates/README.md)
- [Related: Command Development](../../docs/guides/development/command-development/README.md)
