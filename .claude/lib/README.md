# Shared Utility Libraries

This directory contains shared utility libraries used across multiple Claude Code commands.

**Note**: This README documents **sourced utility libraries** (functions that are sourced into other scripts). For documentation of **standalone utility scripts** (executable scripts), see [UTILS_README.md](UTILS_README.md).

## Purpose

Extracting common functionality to shared libraries:
- **Reduces code duplication** (~300-400 LOC saved across commands)
- **Improves maintainability** (update once, applies everywhere)
- **Increases testability** (utilities can be unit tested independently)
- **Ensures consistency** (same logic used by all commands)

## Available Utilities

### conversion-logger.sh

Structured logging for document conversion operations with validation and statistics.

**Key Functions:**
- `init_conversion_log()` - Initialize conversion log file
- `log_conversion_start()` - Log start of conversion
- `log_conversion_success()` - Log successful conversion
- `log_conversion_failure()` - Log failed conversion
- `log_conversion_fallback()` - Log fallback attempt
- `log_tool_detection()` - Log tool detection results
- `log_phase_start()` - Log start of conversion phase
- `log_phase_end()` - Log end of conversion phase
- `log_validation_check()` - Log validation check result
- `log_summary()` - Log conversion summary statistics
- `rotate_conversion_log_if_needed()` - Rotate log files automatically

**Usage Example:**
```bash
# Source the utility library
source .claude/lib/conversion-logger.sh

# Initialize log
init_conversion_log "output/conversion.log" "input/" "output/"

# Log conversion lifecycle
log_conversion_start "file.docx" "markdown"
log_conversion_success "file.docx" "file.md" "markitdown" 1500
log_validation_check "file.md" "size" "pass" "File size OK"

# Log summary
log_summary 10 8 2 0
```

**Log Format:**
```
[2025-10-12 14:30:45] START: document.docx -> markdown
[2025-10-12 14:30:47] SUCCESS: document.docx
  Tool: markitdown
  Output: document.md
  Size: 15234 bytes
  Duration: 1850ms
```

**Log Rotation:**
- Max file size: 10MB
- Max rotated files: 5
- Rotation format: conversion.log → conversion.log.1 → conversion.log.2...

**Used By:** `/convert-docs`, `convert-docs.sh`

---

### adaptive-planning-logger.sh

Structured logging for adaptive planning trigger evaluations and replanning events.

**Key Functions:**
- `log_trigger_evaluation()` - Log a trigger evaluation with result
- `log_complexity_check()` - Log complexity score and threshold comparison
- `log_test_failure_pattern()` - Log test failure pattern detection
- `log_scope_drift()` - Log scope drift detection
- `log_replan_invocation()` - Log a replanning invocation and result
- `log_loop_prevention()` - Log loop prevention enforcement
- `query_adaptive_log()` - Query log for recent events
- `get_adaptive_stats()` - Get statistics about adaptive planning activity

**Usage Example:**
```bash
# Source the utility library
source .claude/lib/adaptive-planning-logger.sh

# Log a complexity trigger evaluation
log_complexity_check 3 9.2 8 12

# Log a replan invocation
log_replan_invocation "expand_phase" "success" "/path/to/updated_plan.md" '{"phase": 3}'

# Query recent events
query_adaptive_log "trigger_eval" 5

# Get statistics
get_adaptive_stats
```

**Log Format:**
```
[2025-10-06T12:30:45Z] INFO trigger_eval: Trigger evaluation: complexity -> triggered | data={"phase": 3, "score": 9.2, "threshold": 8, "tasks": 12}
[2025-10-06T12:31:15Z] INFO replan: Replanning invoked: expand_phase -> success | data={"revision_type": "expand_phase", "result": "/path/to/plan.md"}
[2025-10-06T12:31:20Z] WARN loop_prevention: Loop prevention: phase 3 replan count 2 -> blocked | data={"phase": 3, "replan_count": 2, "max_allowed": 2}
```

**Log Rotation:**
- Max file size: 10MB
- Max rotated files: 5
- Rotation format: adaptive-planning.log → adaptive-planning.log.1 → adaptive-planning.log.2...

**Used By:** `/implement` (adaptive planning feature)

---

### checkpoint-utils.sh

Checkpoint management for workflow resume capability.

**Key Functions:**
- `save_checkpoint()` - Save workflow state for resume
- `restore_checkpoint()` - Load most recent checkpoint
- `validate_checkpoint()` - Validate checkpoint structure
- `migrate_checkpoint_format()` - Migrate old checkpoints to current schema
- `checkpoint_get_field()` - Extract field value from checkpoint
- `checkpoint_set_field()` - Update field value in checkpoint
- `checkpoint_increment_replan()` - Increment replanning counters
- `checkpoint_delete()` - Delete checkpoint file

**Usage Example:**
```bash
# Source the utility library
source .claude/lib/checkpoint-utils.sh

# Save a checkpoint
STATE_JSON='{"phase": 3, "status": "in_progress"}'
CHECKPOINT_FILE=$(save_checkpoint "implement" "my_project" "$STATE_JSON")

# Restore a checkpoint
CHECKPOINT=$(restore_checkpoint "implement" "my_project")
CURRENT_PHASE=$(echo "$CHECKPOINT" | jq -r '.current_phase')

# Increment replan counter
checkpoint_increment_replan "$CHECKPOINT_FILE" "3" "Complexity threshold exceeded"
```

**Checkpoint Schema (v1.1):**
```json
{
  "schema_version": "1.1",
  "checkpoint_id": "implement_project_20251006_123045",
  "workflow_type": "implement",
  "project_name": "project",
  "workflow_description": "Implement feature X",
  "created_at": "2025-10-06T12:30:45Z",
  "updated_at": "2025-10-06T13:15:22Z",
  "status": "in_progress",
  "current_phase": 3,
  "total_phases": 5,
  "completed_phases": [1, 2],
  "workflow_state": {},
  "last_error": null,
  "replanning_count": 1,
  "last_replan_reason": "Phase complexity exceeded",
  "replan_phase_counts": {"phase_3": 1},
  "replan_history": [
    {
      "phase": 3,
      "timestamp": "2025-10-06T13:15:22Z",
      "reason": "Complexity threshold exceeded"
    }
  ]
}
```

**Schema Migration:**
Checkpoints are automatically migrated from v1.0 to v1.1 when loaded. Backups are created before migration.

**Used By:** `/implement`, `/orchestrate`, `/resume-implement`

---

### error-handling.sh

Error classification, recovery, and escalation utilities.

**Key Functions:**
- `classify_error()` - Classify error as transient/permanent/fatal
- `detect_error_type()` - Detect specific error type from message
- `suggest_recovery()` - Suggest recovery action for error type
- `generate_suggestions()` - Generate error-specific suggestions
- `retry_with_backoff()` - Retry command with exponential backoff
- `retry_with_timeout()` - Generate retry metadata with extended timeout
- `retry_with_fallback()` - Generate fallback retry metadata
- `log_error_context()` - Log error with context for debugging
- `escalate_to_user()` - Present error to user with options
- `escalate_to_user_parallel()` - Format escalation for parallel operations
- `try_with_fallback()` - Try primary approach, fall back to alternative
- `format_error_report()` - Format error message with context
- `handle_partial_failure()` - Process successful operations, report failures
- `cleanup_on_error()` - Cleanup temp files on error
- `format_orchestrate_agent_failure()` - Format agent invocation failures
- `format_orchestrate_test_failure()` - Format test failures in workflows
- `extract_location()` - Extract file location from error message

**Usage Example:**
```bash
# Source the utility library
source .claude/lib/error-handling.sh

# Classify an error
ERROR_MSG="Database connection timeout"
ERROR_TYPE=$(classify_error "$ERROR_MSG")

# Retry with backoff
if retry_with_backoff 3 500 curl "https://api.example.com/data"; then
  echo "Request succeeded"
else
  echo "Request failed after retries"
fi

# Try with fallback
try_with_fallback \
  "complex_edit large_file.lua" \
  "simple_edit large_file.lua"

# Format error report
format_error_report \
  "transient" \
  "Write configuration file" \
  "/etc/app/config.yml" \
  "File locked" \
  3
```

**Error Types:**
- **Transient**: Temporary failures (locks, timeouts, resource unavailable)
  - Recovery: Retry with exponential backoff
- **Permanent**: Code-level issues (syntax errors, logic bugs)
  - Recovery: Fix underlying problem, then retry
- **Fatal**: Environment issues (disk full, permissions)
  - Recovery: User intervention required

**Retry Strategy:**
- Max attempts: 3 (default)
- Base delay: 500ms (default)
- Exponential backoff: 500ms → 1s → 2s

**Used By:** `/implement`, `/orchestrate`, `/test`, `/setup`

---

### validation-utils.sh

Input validation and parameter checking utilities.

**Key Functions:**
- `require_param()` - Exit with error if parameter is empty
- `validate_file_exists()` - Check if file exists
- `validate_dir_exists()` - Check if directory exists
- `validate_number()` - Check if value is a valid positive integer
- `validate_positive_number()` - Check if value is positive (> 0)
- `validate_float()` - Check if value is a valid float
- `validate_path_safe()` - Validate path doesn't contain dangerous characters
- `validate_choice()` - Validate value is one of allowed choices
- `validate_boolean()` - Validate value is a boolean
- `validate_not_empty()` - Validate value is not empty or whitespace
- `validate_file_readable()` - Check if file is readable
- `validate_file_writable()` - Check if file is writable
- `check_required_tool()` - Check if required tool is available
- `check_file_writable()` - Legacy function for file writability (use validate_file_writable instead)

**Usage Example:**
```bash
# Source the utility library
source .claude/lib/validation-utils.sh

# Require parameters
require_param "plan_file" "$1" || exit 1

# Validate file exists
if validate_file_exists "$plan_file"; then
  echo "Plan file found"
fi

# Validate number
if validate_positive_number "$phase_number"; then
  echo "Valid phase number: $phase_number"
fi

# Validate choice
validate_choice "$mode" "sequential" "parallel" "hybrid" || exit 1

# Check required tools
check_required_tool "jq" "sudo apt install jq" || exit 1
check_required_tool "git" || exit 1
```

**Validation Patterns:**
- **File Operations**: validate_file_exists, validate_file_readable, validate_file_writable
- **Directory Operations**: validate_dir_exists
- **Number Validation**: validate_number, validate_positive_number, validate_float
- **String Validation**: validate_not_empty, require_param
- **Choice Validation**: validate_choice, validate_boolean
- **Path Safety**: validate_path_safe (prevents directory traversal)
- **Tool Availability**: check_required_tool

**Used By:** All commands requiring input validation

---

### complexity-utils.sh

Complexity analysis for phases and plans, enabling adaptive planning detection.

**Key Functions:**
- `calculate_phase_complexity()` - Calculate complexity score (0-10+)
- `analyze_task_structure()` - Analyze task metrics (count, nesting, files)
- `detect_complexity_triggers()` - Check if thresholds exceeded
- `generate_complexity_report()` - Generate JSON report with all metrics
- `analyze_plan_complexity()` - Analyze overall plan complexity
- `get_complexity_level()` - Get human-readable complexity level
- `format_complexity_summary()` - Format report for display

**Usage Example:**
```bash
# Source the utility library
source .claude/lib/complexity-utils.sh

# Calculate phase complexity
PHASE_NAME="Phase 3: Refactor Architecture"
TASK_LIST="$(cat phase_tasks.txt)"
SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$TASK_LIST")

# Check if triggers exceeded
if detect_complexity_triggers "$SCORE" "12"; then
  echo "Phase complexity exceeds threshold - expansion recommended"
fi

# Generate full complexity report
REPORT=$(generate_complexity_report "$PHASE_NAME" "$TASK_LIST")
echo "$REPORT" | jq '.'

# Format for display
format_complexity_summary "$REPORT"
```

**Complexity Thresholds:**
- **Low**: 0-2 (trivial implementation)
- **Medium**: 3-5 (standard implementation)
- **High**: 6-8 (complex implementation)
- **Critical**: 9+ (very complex, expansion recommended)

**Trigger Conditions:**
- Complexity score > 8
- Task count > 10

**Report Format:**
```json
{
  "phase_name": "Phase 3: Refactor",
  "complexity_score": 9,
  "task_structure": {
    "total_tasks": 12,
    "nested_tasks": 3,
    "max_depth": 2,
    "file_count": 8
  },
  "trigger_detected": "true",
  "recommended_action": "expand_phase",
  "trigger_reason": "Complexity score 9 exceeds threshold 8"
}
```

**Used By:** `/implement` (adaptive planning detection)

---

### artifact-utils.sh

Artifact registry for tracking implementation artifacts (plans, reports, summaries).

**Key Functions:**
- `register_artifact()` - Register artifact in registry
- `query_artifacts()` - Query artifacts by type/pattern
- `update_artifact_status()` - Update artifact metadata
- `cleanup_artifacts()` - Remove old artifact entries
- `validate_artifact_references()` - Check if paths still exist
- `list_artifacts()` - List registered artifacts
- `get_artifact_path()` - Get path for artifact by ID

**Usage Example:**
```bash
# Source the utility library
source .claude/lib/artifact-utils.sh

# Register a plan
PLAN_ID=$(register_artifact "plan" "specs/plans/025.md" '{"status":"in_progress"}')

# Query all plans
PLANS=$(query_artifacts "plan")
echo "$PLANS" | jq '.'

# Update artifact status
update_artifact_status "$PLAN_ID" '{"status":"completed","phases":5}'

# List all artifacts
list_artifacts "plan"

# Cleanup old artifacts (30+ days)
CLEANED=$(cleanup_artifacts 30)
echo "Cleaned up $CLEANED old artifacts"

# Validate references
VALIDATION=$(validate_artifact_references "plan")
echo "$VALIDATION" | jq '.invalid_artifacts[]'
```

**Artifact Types:**
- `plan` - Implementation plans
- `report` - Research reports
- `summary` - Implementation summaries
- `checkpoint` - Workflow checkpoints

**Registry Entry Format:**
```json
{
  "artifact_id": "plan_auth_system_20251006_123045",
  "artifact_type": "plan",
  "artifact_path": "specs/plans/025_auth.md",
  "created_at": "2025-10-06T12:30:45Z",
  "metadata": {
    "status": "completed",
    "phases": 5
  }
}
```

**Used By:** `/orchestrate`, `/implement`, `/list-plans`, `/list-reports`

---

## Guidelines

### When to Use Shared Utilities

✅ **Use shared utilities when:**
- Functionality is used by 2+ commands
- Logic is complex and benefits from centralized testing
- Consistency across commands is important
- Code would otherwise be duplicated

❌ **Don't use shared utilities when:**
- Functionality is command-specific
- Logic is trivial (1-2 lines)
- Command has unique requirements that don't generalize

### Adding New Utilities

When adding a new shared utility library:

1. **Create utility file** in `.claude/lib/`
2. **Follow naming convention**: `[domain]-utils.sh`
3. **Include header comment** describing purpose
4. **Export functions** at bottom of file
5. **Document in this README** with usage examples
6. **Add unit tests** in `.claude/tests/`

### Utility Structure Template

```bash
#!/usr/bin/env bash
# [Utility Name]: Brief description
# Purpose and use cases

set -euo pipefail

# ==============================================================================
# Constants
# ==============================================================================

readonly CONSTANT_NAME="value"

# ==============================================================================
# Core Functions
# ==============================================================================

# function_name: Description
# Usage: function_name <arg1> <arg2>
# Returns: Description of return value
# Example: function_name "value1" "value2"
function_name() {
  local arg1="${1:-}"
  local arg2="${2:-}"

  # Implementation
}

# ==============================================================================
# Export Functions
# ==============================================================================

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f function_name
fi
```

### Testing Utilities

Shared utilities should have corresponding test files:

```bash
# Test individual utility
source .claude/lib/checkpoint-utils.sh
# Run specific function tests

# Test integration with commands
.claude/tests/test_shared_utilities.sh
.claude/tests/test_command_integration.sh
```

## Dependencies

All utilities require:
- **Bash 4.0+**: For modern shell features
- **jq** (recommended): For JSON processing in checkpoint-utils

Optional dependencies noted in each utility's documentation.

## Version History

### v1.2 (2025-10-14)
- Split error-utils.sh into error-handling.sh and validation-utils.sh
- Enhanced error-handling.sh with orchestrate-specific contexts
- Added comprehensive validation functions to validation-utils.sh
- Improved error classification and recovery patterns

### v1.1 (2025-10-06)
- Created checkpoint-utils.sh with checkpoint management
- Created error-utils.sh with error handling
- Initial library structure established

### v1.0 (Initial)
- Utilities were inline in individual commands
- No shared library structure

## Neovim Integration

Utility library files are integrated with the Neovim artifact picker for easy browsing and editing.

### Accessing Library Files via Picker

- **Keybinding**: `<leader>ac` in normal mode
- **Command**: `:ClaudeCommands`
- **Category**: [Lib] section in picker

### Picker Features for Library Files

**Visual Display**:
- Library utilities listed with descriptions from script headers
- Local utilities marked with `*` prefix
- Descriptions automatically extracted from file comments

**Display Format**:
```
[Lib]                         Utility libraries

* ├─ checkpoint-utils.sh       State persistence utilities
  └─ template-parser.sh        Template variable substitution
```

**Quick Actions**:
- `<CR>` - Open utility script for editing
- `<C-l>` - Load utility locally to project
- `<C-g>` - Update from global version
- `<C-s>` - Save local utility to global
- `<C-e>` - Edit utility file in buffer
- `<C-u>`/`<C-d>` - Scroll preview up/down

**Example Workflow**:
```vim
" Open picker
:ClaudeCommands

" Navigate to [Lib] category
" Select checkpoint-utils.sh
" Press <C-e> to view or modify utility functions
```

### Library Script Structure

Utilities appear in the picker with descriptions extracted from their header comments:

```bash
#!/usr/bin/env bash
# Purpose: State persistence utilities  # Shown in picker
# Functions for checkpoint management

# Rest of script...
```

The picker automatically parses the `Purpose:` or first comment line to display utility function.

### Using Shared Utilities

Library utilities are meant to be sourced by commands and other scripts:

```bash
# In command script
source "$CLAUDE_PROJECT_DIR/.claude/lib/checkpoint-utils.sh"

# Use utility function
save_checkpoint "implement" "my_project" "$STATE_JSON"
```

Use the picker to browse available utilities and their functions before using them in your scripts.

### Documentation

- [Neovim Claude Integration](../../nvim/lua/neotex/plugins/ai/claude/README.md) - Integration overview
- [Commands Picker](../../nvim/lua/neotex/plugins/ai/claude/commands/README.md) - Picker documentation
- [Picker Implementation](../../nvim/lua/neotex/plugins/ai/claude/commands/picker.lua) - Source code

## See Also

- [Agent Shared Protocols](../agents/shared/) - Shared agent documentation
- [Command Documentation](../commands/) - Commands using these utilities
- [Testing Documentation](../tests/) - Test suite for utilities
