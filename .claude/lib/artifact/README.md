# Artifact Libraries

## Purpose

Artifact creation, registration, and management libraries. This directory provides utilities for creating topic artifacts, registering artifacts in a central registry for querying, synthesizing overviews from multiple reports, performing variable substitution in templates, and integrating with the template system for plan generation.

## Libraries

### artifact-creation.sh
Artifact file creation and workflow integration.

**Key Functions:**
- `create_topic_artifact()` - Create artifact in topic directory
- `create_artifact_directory()` - Create directory for artifacts
- `write_artifact_file()` - Write artifact with proper formatting
- `get_next_artifact_number()` - Get next sequential number

**Usage:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact/artifact-creation.sh"
create_artifact_directory "specs/plans" "new_feature"
```

### artifact-registry.sh
Artifact tracking and querying.

**Key Functions:**
- `register_artifact()` - Register artifact in central registry
- `query_artifacts()` - Query artifacts by type or pattern
- `update_artifact_status()` - Update artifact metadata
- `list_artifacts()` - List all registered artifacts

**Usage:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact/artifact-registry.sh"
PLAN_ID=$(register_artifact "plan" "specs/plans/025.md" '{"status":"in_progress"}')
PLANS=$(query_artifacts "plan")
```

### overview-synthesis.sh
Report overview generation from multiple sources.

**Key Functions:**
- `synthesize_overview()` - Generate overview from reports
- `extract_key_findings()` - Extract key findings

### substitute-variables.sh
Variable substitution in templates.

**Key Functions:**
- `substitute_variables()` - Replace variables in template content
- `validate_substitution()` - Validate all variables substituted
- `escape_variable_value()` - Escape special characters

**Usage:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact/substitute-variables.sh"
CONTENT=$(substitute_variables "$TEMPLATE" "$VARS_JSON")
```

### template-integration.sh
Template system integration for plan generation.

**Key Functions:**
- `generate_plan_from_template()` - Full template-to-plan workflow
- `list_available_templates()` - List templates by category
- `get_template_info()` - Get template metadata

**Usage:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact/template-integration.sh"
generate_plan_from_template "crud-feature" "$VARS_JSON"
```

## Dependencies

- `artifact-creation.sh` and `artifact-registry.sh` depend on `core/base-utils.sh` and `core/unified-logger.sh`

## Navigation

- [← Parent Directory](../README.md)
