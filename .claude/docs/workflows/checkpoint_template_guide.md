# Checkpoint-Template System Guide

## Overview

The checkpoint-template system provides seamless workflow state management and plan generation automation. This guide consolidates documentation from multiple sources into a single comprehensive resource.

### What are Checkpoints?

Checkpoints are JSON-based workflow state snapshots that enable:
- **Auto-resume**: Automatically resume interrupted workflows
- **Progress tracking**: Record phase completion and test results
- **Error recovery**: Restore state after failures
- **Workflow coordination**: Coordinate multi-step workflows across sessions

### What are Templates?

Templates are YAML-based plan generation specifications that enable:
- **Rapid plan creation**: Generate plans 60-80% faster than manual `/plan`
- **Consistency**: Ensure standard structure across similar features
- **Variable substitution**: Customize plans with project-specific values
- **Pattern reuse**: Leverage proven patterns across projects

### How They Work Together

The integrated system creates a seamless workflow:

```
Template → Plan Generation → Checkpoint Creation → Implementation → Auto-Resume
```

1. **Template Selection**: Choose from 11 categories (CRUD, refactoring, testing, etc.)
2. **Plan Generation**: `/plan-from-template` creates plan with variables substituted
3. **Checkpoint Creation**: Initial checkpoint created automatically with template context
4. **Implementation**: `/implement` uses checkpoint for smart defaults and state tracking
5. **Auto-Resume**: Interrupted workflows resume automatically with full context

### When to Use Each

**Use Checkpoints when:**
- Implementing multi-phase plans that may span multiple sessions
- Running workflows that could be interrupted (long tests, network operations)
- Coordinating complex multi-agent workflows
- Need rollback capability for parallel operations

**Use Templates when:**
- Creating plans for common patterns (CRUD features, refactors, migrations)
- Need consistent structure across similar features
- Want to leverage proven implementation patterns
- Have repetitive planning tasks

**Use Both when:**
- Implementing template-generated plans (automatic integration)
- Need full workflow state tracking for template-based features
- Want to resume template-based implementations across sessions

## Checkpoint System

### Schema v1.3 Reference

Current schema version: **1.3**

**Core Fields:**
- `schema_version` (string): Checkpoint format version
- `checkpoint_id` (string): Unique identifier (format: `{workflow}_{project}_{timestamp}`)
- `workflow_type` (string): Type of workflow (implement, orchestrate, debug, etc.)
- `project_name` (string): Project identifier
- `workflow_description` (string): Human-readable description
- `created_at` (string): ISO 8601 timestamp
- `updated_at` (string): ISO 8601 timestamp of last update
- `status` (string): Workflow status (in_progress, completed, failed)

**Phase Tracking:**
- `current_phase` (number): Current phase number (0-indexed)
- `total_phases` (number): Total number of phases in plan
- `completed_phases` (array): List of completed phase numbers

**State Management:**
- `workflow_state` (object): Complete workflow-specific state
- `last_error` (string|null): Last error message if any
- `tests_passing` (boolean): Whether tests are passing
- `plan_modification_time` (number|null): Plan file mtime for staleness detection

**Adaptive Planning (v1.1+):**
- `replanning_count` (number): Total number of replans
- `last_replan_reason` (string|null): Reason for most recent replan
- `replan_phase_counts` (object): Replan count per phase
- `replan_history` (array): Complete replan history with timestamps

**Debug Integration (v1.2+):**
- `debug_report_path` (string|null): Path to debug report if created
- `user_last_choice` (string|null): Last user choice in debug workflow
- `debug_iteration_count` (number): Number of debug iterations

**Topic Organization (v1.3+):**
- `topic_directory` (string|null): Path to topic directory (e.g., `specs/042_authentication`)
- `topic_number` (number|null): Topic number extracted from directory (e.g., 42)

**Context Preservation (v1.3+):**
- `context_preservation` (object): Context tracking
  - `pruning_log` (array): Record of pruning operations
  - `artifact_metadata_cache` (object): Cached metadata from reports/plans
  - `subagent_output_references` (array): References to subagent outputs

**Template Integration (v1.3+):**
- `template_source` (string|null): Template name if plan generated from template
- `template_variables` (object|null): Variables used in template generation

**Spec Maintenance (v1.3+):**
- `spec_maintenance` (object): Spec updater tracking
  - `parent_plan_path` (string|null): Parent plan for hierarchical plans
  - `grandparent_plan_path` (string|null): Grandparent plan for 3-level hierarchy
  - `spec_updater_invocations` (array): Log of spec-updater agent calls
  - `checkbox_propagation_log` (array): Checkbox update propagation log

### Checkpoint Lifecycle

**1. Creation**
```bash
# Created by commands during workflow initialization
save_checkpoint "implement" "auth_system" '{
  "plan_path": "specs/042_auth/plans/001_implementation.md",
  "current_phase": 1,
  "total_phases": 5,
  "status": "in_progress",
  "topic_directory": "specs/042_auth",
  "topic_number": 42,
  "template_source": "crud-feature",
  "template_variables": {"entity": "User", "database": "PostgreSQL"}
}'
```

**2. Usage**
- Commands read checkpoint on workflow start
- State updated after each phase completion
- Test results recorded
- Error states captured

**3. Completion**
- Status updated to `completed`
- Final state saved
- Checkpoint retained for audit trail

**4. Archival**
- Checkpoints retained indefinitely by default
- Manual cleanup via `checkpoint_delete()`
- Completed checkpoints can be archived after 30 days

### Smart Auto-Resume

Checkpoints enable intelligent auto-resume with 5 safety conditions:

**Condition 1: Tests Passing**
- `tests_passing` must be `true`
- Ensures no broken tests from previous run

**Condition 2: No Recent Errors**
- `last_error` must be `null`
- Avoids resuming from error states

**Condition 3: Status In-Progress**
- `status` must be `"in_progress"`
- Prevents resuming completed or failed workflows

**Condition 4: Checkpoint Age < 7 Days**
- `created_at` within last 7 days
- Prevents resuming stale workflows

**Condition 5: Plan Not Modified**
- `plan_modification_time` matches current plan mtime
- Detects manual plan edits requiring review

**Example: Auto-Resume Check**
```bash
# Check if safe to auto-resume
if check_safe_resume_conditions "$checkpoint_file"; then
  echo "Auto-resuming from phase $(jq -r '.current_phase' "$checkpoint_file")"
  restore_checkpoint "implement" "auth_system"
else
  echo "Manual review needed: $(get_skip_reason "$checkpoint_file")"
  # Prompt user for confirmation
fi
```

### Schema Migration

Checkpoints support automatic migration between schema versions using `migrate_checkpoint_format()` or the standalone migration script.

**Migration command**: `.claude/lib/migrate-checkpoint-v1.3.sh <checkpoint-file> [--dry-run]`

**Schema Versions**:
- **v1.0**: Base checkpoint system
- **v1.1**: Adaptive planning fields (`replanning_count`, `replan_history`)
- **v1.2**: Debug integration (`debug_report_path`, `debug_iteration_count`)
- **v1.3**: Full integration (topic organization, context preservation, template support, spec maintenance)

**Migration Example:**
```bash
# Preview migration
.claude/lib/migrate-checkpoint-v1.3.sh checkpoint.json --dry-run

# Apply migration (creates backup)
.claude/lib/migrate-checkpoint-v1.3.sh checkpoint.json

# Revert if needed
cp checkpoint.json.backup checkpoint.json
```

### Checkpoint Utilities

**Core Functions** (`.claude/lib/workflow/checkpoint-utils.sh`):

1. **save_checkpoint(workflow_type, project_name, state_json)**
   - Creates new checkpoint or updates existing
   - Returns: Checkpoint file path
   - Example: `save_checkpoint "implement" "auth" '{"phase":2}'`

2. **restore_checkpoint(workflow_type, [project_name])**
   - Loads most recent checkpoint for workflow
   - Automatically migrates to current schema
   - Returns: Checkpoint JSON data
   - Example: `restore_checkpoint "implement" "auth"`

3. **validate_checkpoint(checkpoint_file)**
   - Validates JSON structure and required fields
   - Returns: 0 if valid, 1 if invalid
   - Example: `validate_checkpoint "$checkpoint_file"`

4. **migrate_checkpoint_format(checkpoint_file)**
   - Migrates checkpoint to current schema version
   - Creates backup before migration
   - Idempotent (safe to run multiple times)
   - Example: `migrate_checkpoint_format "$checkpoint_file"`

5. **checkpoint_get_field(checkpoint_file, field_path)**
   - Extracts field value using jq path
   - Returns: Field value or empty
   - Example: `checkpoint_get_field "$file" ".current_phase"`

6. **checkpoint_set_field(checkpoint_file, field_path, value)**
   - Updates field value atomically
   - Updates `updated_at` timestamp
   - Example: `checkpoint_set_field "$file" ".status" "completed"`

7. **checkpoint_increment_replan(checkpoint_file, phase, reason)**
   - Increments replan counters
   - Adds entry to replan history
   - Example: `checkpoint_increment_replan "$file" "3" "complexity threshold"`

8. **checkpoint_delete(workflow_type, project_name)**
   - Deletes all checkpoints for workflow/project
   - Returns: 0 on success
   - Example: `checkpoint_delete "implement" "auth"`

**Auto-Resume Functions:**

9. **check_safe_resume_conditions(checkpoint_file)**
   - Validates all 5 safety conditions
   - Returns: 0 if safe, 1 if manual review needed
   - Example: `check_safe_resume_conditions "$file"`

10. **get_skip_reason(checkpoint_file)**
    - Returns human-readable skip reason
    - Useful for user prompts
    - Example: `reason=$(get_skip_reason "$file")`

**Parallel Operations:**

11. **save_parallel_operation_checkpoint(plan_path, operation_type, operations_json)**
    - Saves pre-execution state for rollback
    - Used by `/expand`, `/collapse` for safety
    - Returns: Checkpoint file path

12. **restore_from_checkpoint(checkpoint_file)**
    - Restores from parallel operation checkpoint
    - Returns: Checkpoint JSON data

13. **validate_checkpoint_integrity(checkpoint_file)**
    - Validates checkpoint consistency
    - Returns: JSON with validation result

## Template System

### YAML Format

Templates use YAML format with comprehensive variable substitution:

```yaml
# Template metadata
name: crud-feature
category: feature-development
description: Generate CRUD operations for database entity
version: 1.0

# Variable definitions
variables:
  entity:
    type: string
    description: Entity name (e.g., User, Product)
    required: true
    example: User

  database:
    type: string
    description: Database type
    required: true
    options: [PostgreSQL, MySQL, SQLite]
    default: PostgreSQL

  include_tests:
    type: boolean
    description: Generate test files
    required: false
    default: true

# Plan template with variable substitution
plan_template: |
  # {{entity}} CRUD Implementation

  ## Metadata
  - **Feature**: {{entity}} CRUD operations
  - **Database**: {{database}}
  - **Testing**: {{include_tests}}

  ## Phases

  ### Phase 1: Database Schema
  - [ ] Create {{entity}} table migration
  - [ ] Add indexes for {{entity}} queries
  {{#include_tests}}
  - [ ] Test migration rollback
  {{/include_tests}}

  ### Phase 2: Repository Layer
  - [ ] Implement {{entity}}Repository
  - [ ] Add CRUD methods (create, read, update, delete)
  {{#include_tests}}
  - [ ] Write repository tests
  {{/include_tests}}
```

### Variable Substitution Syntax

**Simple Variables:**
```yaml
{{variable_name}}           # Simple substitution
{{entity}}                  # → "User"
```

**Conditional Blocks:**
```yaml
{{#boolean_var}}            # Include if true
  Content here
{{/boolean_var}}

{{^boolean_var}}            # Include if false
  Content here
{{/boolean_var}}
```

**Default Values:**
```yaml
{{variable_name:default}}   # Use default if not provided
{{database:PostgreSQL}}     # → "PostgreSQL" if database not set
```

**String Operations:**
```yaml
{{variable_name|lower}}     # Lowercase
{{variable_name|upper}}     # Uppercase
{{variable_name|snake}}     # snake_case
{{variable_name|pascal}}    # PascalCase
{{variable_name|camel}}     # camelCase
```

### Topic-Based Integration

Templates automatically integrate with topic-based organization:

```yaml
# Template specifies topic organization
topic_structure:
  base_directory: specs
  topic_prefix: auto    # Auto-generate topic number
  artifact_types:
    - plans
    - reports
    - summaries

# Generated structure:
# specs/042_user_crud/
#   plans/001_implementation.md      ← Generated plan
#   reports/                         ← For research
#   summaries/                       ← For completion summary
```

**Topic Number Assignment:**
- `auto`: Next available topic number (e.g., 042 → 043)
- `{number}`: Specific topic number (e.g., 050)
- `reuse:{name}`: Reuse existing topic directory

### Template Categories

11 categories with 50+ templates:

1. **Feature Development** (12 templates)
   - crud-feature, api-endpoint, ui-component, state-management

2. **Refactoring** (8 templates)
   - extract-module, rename-pattern, consolidate-duplicates

3. **Testing** (7 templates)
   - test-suite, integration-tests, e2e-tests

4. **Infrastructure** (6 templates)
   - ci-cd-pipeline, deployment-config, monitoring-setup

5. **Documentation** (5 templates)
   - api-docs, user-guide, architecture-decision-record

6. **Database** (4 templates)
   - schema-migration, data-migration, index-optimization

7. **Performance** (3 templates)
   - performance-optimization, caching-layer, lazy-loading

8. **Security** (3 templates)
   - auth-integration, permission-system, input-validation

9. **Bug Fixes** (2 templates)
   - bug-fix, regression-fix

10. **Migration** (2 templates)
    - library-migration, framework-upgrade

11. **Configuration** (2 templates)
    - config-system, environment-setup

### Neovim Picker Integration

Templates integrated with Neovim Telescope picker:

```lua
-- Keybinding: <leader>pt (Plan from Template)
require('telescope.builtin').find_files({
  prompt_title = 'Plan Templates',
  cwd = vim.fn.expand('~/.config/.claude/templates'),
  find_command = {'fd', '-e', 'yaml', '-t', 'f'},
  attach_mappings = function(prompt_bufnr, map)
    actions.select_default:replace(function()
      -- Invoke /plan-from-template with selected template
    end)
    return true
  end
})
```

## Integration Workflows

### Template → Plan → Checkpoint → Implement → Resume

**Complete End-to-End Flow (16 steps):**

1. **Template Selection**
   ```bash
   /plan-from-template crud-feature
   ```

2. **Variable Collection** (interactive prompts)
   ```
   Entity name: User
   Database type: PostgreSQL
   Include tests? yes
   ```

3. **Plan Generation** (template → plan)
   ```
   Generated: specs/042_user_crud/plans/001_implementation.md
   ```

4. **Checkpoint Creation** (automatic)
   ```json
   {
     "schema_version": "1.3",
     "workflow_type": "plan_generated",
     "status": "planning_complete",
     "workflow_state": {
       "plan_path": "specs/042_user_crud/plans/001_implementation.md",
       "template_source": "crud-feature",
       "template_variables": {
         "entity": "User",
         "database": "PostgreSQL",
         "include_tests": true
       },
       "topic_directory": "specs/042_user_crud",
       "topic_number": 42
     }
   }
   ```

5. **Implementation Start**
   ```bash
   /implement specs/042_user_crud/plans/001_implementation.md
   ```

6. **Checkpoint Detection** (auto-detects template context)
   ```
   Detected template-generated plan: crud-feature
   Using template context for intelligent defaults...
   ```

7. **Phase Execution** (with checkpoint updates)
   - Phase 1: Database Schema
     - Checkpoint updated: `current_phase: 1`, `status: "in_progress"`
     - Tests run and results recorded: `tests_passing: true`
     - Checkpoint updated: `completed_phases: [1]`

8. **Interruption** (workflow stops)

9. **Auto-Resume Check** (next session)
   ```bash
   /implement specs/042_user_crud/plans/001_implementation.md
   ```

10. **Safety Validation** (5 conditions checked)
    ```
    ✓ Tests passing: true
    ✓ No errors: true
    ✓ Status: in_progress
    ✓ Age: 2 hours (< 7 days)
    ✓ Plan unmodified: true

    Auto-resuming from Phase 2...
    ```

11. **Resume Execution** (continues from Phase 2)
    - Context preserved: template variables, topic directory
    - Spec maintenance: checkbox propagation, parent plan updates

12. **Completion** (all phases done)
    - Status updated: `completed`
    - Summary generated with template context

13. **Spec Updater Invocation** (automatic)
    - Updates parent plan checkboxes
    - Creates bidirectional cross-references
    - Logs invocations in checkpoint

14. **Context Pruning** (if orchestrated)
    - Prunes completed phase metadata
    - Caches essential metadata only
    - Logs pruning operations

15. **Summary Generation**
    - Links to template source
    - Documents template variables used
    - Includes checkpoint metadata

16. **Workflow Completion**
    - Checkpoint marked completed
    - Audit trail preserved
    - Template metrics updated

### Pattern Library Usage

Bash pattern libraries work alongside templates:

**Template provides:**
- Plan structure and content
- Variable substitution
- Topic organization

**Bash patterns provide:**
- Reusable command procedures
- Utility initialization snippets
- Error handling patterns

**Example: Template references bash pattern**
```yaml
plan_template: |
  ### Phase 1: Setup
  - [ ] Initialize utilities (see bash-patterns.yaml#utility-init)
  - [ ] Create checkpoint (see bash-patterns.yaml#checkpoint-setup)
  - [ ] {{entity}} implementation
```

**Workflow integration:**
1. Template generates plan with pattern references
2. Command reads plan and sees pattern references
3. Command loads procedures from bash-patterns.yaml
4. Procedures executed with template variables injected

### Context-Preserving Templates

Templates can specify context preservation strategies:

```yaml
# Template metadata
context_preservation:
  pruning_policy: moderate    # aggressive, moderate, minimal
  cache_artifacts: true        # Cache metadata from referenced reports
  preserve_subagent_output: false  # Don't preserve full subagent output

# Applied during implementation:
# - Moderate pruning after each phase
# - Artifact metadata cached in checkpoint
# - Subagent outputs replaced with references
```

### Spec Maintenance

Templates integrate with spec maintenance workflows:

```yaml
spec_maintenance:
  enable_checkbox_propagation: true
  parent_plan_pattern: "specs/{topic}/plans/000_overview.md"
  update_on_phase_complete: true

  # Automatic parent plan updates:
  # Phase 1 complete → Update parent plan checkbox
  # All phases complete → Update grandparent if exists
```

## Best Practices

### When to Create Checkpoints

**Create checkpoints for:**
- Multi-phase implementations (3+ phases)
- Workflows with external dependencies (network, databases)
- Long-running operations (>10 minutes)
- Workflows spanning multiple sessions
- Parallel operations requiring rollback

**Skip checkpoints for:**
- Single-phase quick tasks (<5 minutes)
- Read-only operations (research, analysis)
- Workflows with no state to preserve

### Templates vs /plan

**Use Templates when:**
- Pattern is well-defined and repeatable
- Need consistent structure across features
- Have common variable substitutions
- 60-80% of plan content is predictable

**Use /plan when:**
- Feature is unique or experimental
- Need AI-driven plan generation
- Requirements are ambiguous
- Template doesn't exist for pattern

**Hybrid Approach:**
- Use template for initial structure
- Manually edit plan for specific needs
- Checkpoint preserves both template context and manual edits

### Designing Templates

**Template Design Principles:**

1. **Start Specific, Generalize Later**
   - Create template for one project first
   - Extract variables after validation
   - Generalize when pattern proven

2. **Use Clear Variable Names**
   - `entity` not `e`
   - `database_type` not `db`
   - `include_integration_tests` not `int_tests`

3. **Provide Examples**
   - Show example values for all variables
   - Include realistic descriptions
   - Demonstrate conditional blocks

4. **Test Variable Combinations**
   - Test all conditionals (true/false)
   - Test optional variables (present/absent)
   - Test edge cases (empty strings, special chars)

5. **Include Metadata**
   - Version number for template evolution
   - Category for organization
   - Description for discovery

**Template Evolution:**
```
v1.0: Initial template (specific project)
v1.1: Extract variables (generalize)
v1.2: Add conditionals (handle variants)
v1.3: Refine based on usage metrics
```

### Cleanup Strategies

**Checkpoint Cleanup:**

**Automatic Cleanup** (future feature):
```bash
# Cleanup completed checkpoints older than 30 days
cleanup_old_checkpoints --status completed --older-than 30d

# Cleanup failed checkpoints after manual review
cleanup_old_checkpoints --status failed --older-than 7d
```

**Manual Cleanup:**
```bash
# Delete specific workflow checkpoints
checkpoint_delete "implement" "auth_system"

# Find and review old checkpoints
find .claude/data/checkpoints -name "*.json" -mtime +30 -ls
```

**Retention Policy:**
- **In-progress**: Retain until completed or manually deleted
- **Completed**: Retain 30 days, then archive or delete
- **Failed**: Review within 7 days, then delete or debug
- **Template-generated**: Retain for metrics (template usage tracking)

**Template Cleanup:**
- Templates are static files, no cleanup needed
- Version old templates (crud-feature-v1.yaml → crud-feature-v2.yaml)
- Archive deprecated templates in `.claude/templates/archive/`

## Troubleshooting

### Common Checkpoint Issues

**Issue: "No checkpoint found for workflow type"**
```
Cause: No checkpoint file matches workflow type and project name
Solution: Check exact workflow type and project name spelling
```

**Issue: "Corrupted checkpoint (invalid JSON)"**
```
Cause: Checkpoint file has malformed JSON
Solution: Delete checkpoint or restore from backup:
  ls -la .claude/data/checkpoints/*.backup
  cp checkpoint.json.backup checkpoint.json
```

**Issue: "Checkpoint age X days old (max: 7 days)"**
```
Cause: Checkpoint older than 7-day safety threshold
Solution:
  1. Review plan for changes
  2. Manually resume with user confirmation
  3. Or start fresh implementation
```

**Issue: "Plan file modified since checkpoint"**
```
Cause: Plan file edited after checkpoint creation
Solution:
  1. Review plan changes
  2. Decide: resume with changes or restart
  3. Update checkpoint manually if resuming
```

**Issue: "Tests failing in last run"**
```
Cause: Previous run left failing tests
Solution:
  1. Fix failing tests
  2. Update checkpoint: tests_passing = true
  3. Or start fresh from clean state
```

### Template Validation Errors

**Error: "Missing required variable: entity"**
```
Cause: Template requires variable not provided
Solution: Provide all required variables:
  /plan-from-template crud-feature entity=User database=PostgreSQL
```

**Error: "Invalid variable type for 'include_tests': expected boolean"**
```
Cause: Variable type mismatch
Solution: Use correct type:
  Correct: include_tests=true
  Incorrect: include_tests=yes
```

**Error: "Template not found: foo-feature"**
```
Cause: Template doesn't exist in .claude/templates/
Solution:
  1. List available templates: ls .claude/templates/*.yaml
  2. Check spelling
  3. Or create template if needed
```

**Error: "Variable substitution failed: {{unknown_var}}"**
```
Cause: Template references undefined variable
Solution:
  1. Check template variable definitions
  2. Add missing variable or fix reference
  3. Template validation: validate-template.sh crud-feature.yaml
```

### Resume Failures

**Issue: Resume starts from wrong phase**
```
Cause: current_phase in checkpoint incorrect
Solution: Manually set correct phase:
  checkpoint_set_field "$file" ".current_phase" "3"
```

**Issue: Resume ignores template context**
```
Cause: template_source or template_variables missing
Solution:
  1. Check checkpoint schema version (must be v1.3)
  2. Migrate if needed: migrate-checkpoint-v1.3.sh "$file"
  3. Manually add template fields if migration failed
```

**Issue: Auto-resume skipped despite safe conditions**
```
Cause: One of 5 safety conditions failing unexpectedly
Solution:
  1. Check skip reason: get_skip_reason "$checkpoint_file"
  2. Validate each condition manually
  3. Debug with: check_safe_resume_conditions "$file"; echo $?
```

### Migration Problems

**Issue: "This script migrates from v1.2 to v1.3"**
```
Cause: Checkpoint not at v1.2
Solution:
  1. Check current version: jq -r '.schema_version' checkpoint.json
  2. If v1.0 or v1.1: Use migrate_checkpoint_format() first
  3. If v1.3: Already migrated, no action needed
```

**Issue: Migration produces invalid JSON**
```
Cause: Checkpoint had malformed JSON before migration
Solution:
  1. Restore from backup: cp checkpoint.json.backup checkpoint.json
  2. Validate original: jq empty checkpoint.json
  3. Fix JSON issues manually before migrating
```

**Issue: New fields not populated after migration**
```
Cause: workflow_state missing expected fields
Solution:
  1. Migration sets new fields to null (safe defaults)
  2. Manually populate if needed:
     jq '.topic_directory = "specs/042_auth"' checkpoint.json
  3. Or let commands populate during next save
```

## API Reference

### Checkpoint Utilities

**save_checkpoint**
```bash
save_checkpoint <workflow-type> <project-name> <state-json>
```
- **Returns**: Checkpoint file path
- **Example**:
  ```bash
  checkpoint_path=$(save_checkpoint "implement" "auth" '{
    "plan_path": "plan.md",
    "current_phase": 2,
    "template_source": "crud-feature"
  }')
  echo "Saved: $checkpoint_path"
  ```

**restore_checkpoint**
```bash
restore_checkpoint <workflow-type> [project-name]
```
- **Returns**: Checkpoint JSON data (stdout)
- **Example**:
  ```bash
  checkpoint_data=$(restore_checkpoint "implement" "auth")
  current_phase=$(echo "$checkpoint_data" | jq -r '.current_phase')
  ```

**validate_checkpoint**
```bash
validate_checkpoint <checkpoint-file>
```
- **Returns**: 0 if valid, 1 if invalid
- **Example**:
  ```bash
  if validate_checkpoint "$checkpoint_file"; then
    echo "Valid checkpoint"
  else
    echo "Invalid checkpoint"
  fi
  ```

**migrate_checkpoint_format**
```bash
migrate_checkpoint_format <checkpoint-file>
```
- **Returns**: 0 if migrated or already current
- **Example**:
  ```bash
  migrate_checkpoint_format "$checkpoint_file"
  echo "Migrated to v$(jq -r '.schema_version' "$checkpoint_file")"
  ```

**checkpoint_get_field**
```bash
checkpoint_get_field <checkpoint-file> <field-path>
```
- **Returns**: Field value (stdout)
- **Example**:
  ```bash
  phase=$(checkpoint_get_field "$file" ".current_phase")
  template=$(checkpoint_get_field "$file" ".template_source")
  ```

**checkpoint_set_field**
```bash
checkpoint_set_field <checkpoint-file> <field-path> <value>
```
- **Returns**: 0 on success
- **Example**:
  ```bash
  checkpoint_set_field "$file" ".status" "completed"
  checkpoint_set_field "$file" ".tests_passing" "false"
  ```

**checkpoint_increment_replan**
```bash
checkpoint_increment_replan <checkpoint-file> <phase-number> <reason>
```
- **Returns**: 0 on success
- **Example**:
  ```bash
  checkpoint_increment_replan "$file" "3" "complexity threshold exceeded"
  ```

**checkpoint_delete**
```bash
checkpoint_delete <workflow-type> <project-name>
```
- **Returns**: 0 on success
- **Example**:
  ```bash
  checkpoint_delete "implement" "auth"
  ```

**check_safe_resume_conditions**
```bash
check_safe_resume_conditions <checkpoint-file>
```
- **Returns**: 0 if safe, 1 if manual review needed
- **Example**:
  ```bash
  if check_safe_resume_conditions "$file"; then
    echo "Safe to auto-resume"
  else
    echo "Manual review needed"
  fi
  ```

**get_skip_reason**
```bash
get_skip_reason <checkpoint-file>
```
- **Returns**: Human-readable skip reason (stdout)
- **Example**:
  ```bash
  reason=$(get_skip_reason "$file")
  echo "Auto-resume skipped: $reason"
  ```

### Template Utilities

**Template utilities are integrated into commands; no direct utility functions exposed**

**Via Commands:**
```bash
# List templates
/plan-from-template --list-categories
/plan-from-template --category feature-development

# Generate plan from template
/plan-from-template crud-feature
/plan-from-template crud-feature entity=User database=PostgreSQL
```

**Template Structure Validation:**
```bash
# Validate template YAML structure (manual check)
yq eval . .claude/templates/crud-feature.yaml
# Returns: Valid YAML if parseable

# Check required fields
yq eval '.name, .category, .variables, .plan_template' template.yaml
```

## Cross-References

- **Command Architecture Standards**: [command_architecture_standards.md](../reference/architecture/overview.md) - Context preservation patterns
- **Bash Patterns**: [bash-patterns.yaml](../templates/bash-patterns.yaml) - Reusable utility procedures
- **Implementation Patterns**: [implementation-patterns.yaml](../templates/implementation-patterns.yaml) - Workflow procedures
- **Orchestration Guide**: [orchestration-guide.md](orchestration-guide.md) - Multi-agent workflows with checkpoints
- **Directory Protocols**: [directory-protocols.md](../concepts/directory-protocols.md) - Topic-based organization
- **Development Workflow**: [development-workflow.md](../concepts/development-workflow.md) - Standard development workflow
- **Report 052**: [.claude/specs/reports/052_checkpoint_template_system_integration_analysis.md](../specs/reports/052_checkpoint_template_system_integration_analysis.md) - Detailed integration analysis

---

**Last Updated**: 2025-10-17 (Schema v1.3 release)
**Consolidates**: 22 scattered checkpoint/template references
**Maintainer**: See [writing-standards.md](../concepts/writing-standards.md) for contribution guidelines
