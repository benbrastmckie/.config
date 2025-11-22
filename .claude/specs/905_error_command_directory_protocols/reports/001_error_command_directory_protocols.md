# /errors Command Directory Protocols Non-Compliance Research Report

## Metadata
- **Date**: 2025-11-21
- **Agent**: research-specialist
- **Topic**: /errors command directory protocol violations
- **Report Type**: codebase analysis

## Executive Summary

The `/errors` command does not follow the standard project directory creation protocols that other workflow commands like `/repair` use. Instead of using the `workflow-initialization.sh` library and `initialize_workflow_paths()` function for proper topic directory management with lazy directory creation, the `/errors` command manually constructs directory paths with direct `mkdir -p` calls in Block 1, violating the lazy directory creation standard documented in directory-protocols.md.

## Findings

### Finding 1: Manual Directory Creation Instead of Library Usage

**Location**: `/home/benjamin/.config/.claude/commands/errors.md`, lines 266-274

The `/errors` command uses manual topic directory creation:

```bash
# Get topic number and directory using LLM agent
TOPIC_NUMBER=$(get_next_topic_number)
TOPIC_NAME=$(generate_topic_name "$ERROR_DESCRIPTION")
TOPIC_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${TOPIC_NUMBER}_${TOPIC_NAME}"

# Create topic directory structure
mkdir -p "${TOPIC_DIR}/reports" 2>/dev/null
```

**Problem**: This violates the lazy directory creation standard which requires:
1. Only the topic root directory should be created during setup
2. Subdirectories (reports/, plans/, debug/, etc.) should be created on-demand via `ensure_artifact_directory()` when files are written
3. Commands should use `initialize_workflow_paths()` from `workflow-initialization.sh`

### Finding 2: Missing workflow-initialization.sh Integration

**Location**: `/home/benjamin/.config/.claude/commands/errors.md`, lines 234-241

The `/errors` command sources the following libraries:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null
```

**Missing**: `workflow-initialization.sh` which provides `initialize_workflow_paths()` - the standard function used by `/repair` and other workflow commands.

**Comparison with /repair** (lines 122-142):
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-initialization.sh" >&2
  exit 1
}
```

### Finding 3: Direct generate_topic_name() vs LLM Agent Pattern

**Location**: `/home/benjamin/.config/.claude/commands/errors.md`, lines 267-268

The `/errors` command uses:
```bash
TOPIC_NUMBER=$(get_next_topic_number)
TOPIC_NAME=$(generate_topic_name "$ERROR_DESCRIPTION")
```

These functions are undefined in the sourced libraries and appear to be placeholder references. The correct pattern from `/repair` (using `initialize_workflow_paths()`) handles:
1. Atomic topic allocation via `allocate_and_create_topic()`
2. Proper LLM-based topic naming with validation
3. Collision detection and rollover
4. Lazy directory creation

### Finding 4: Incorrect Output in errors-output.md

**Location**: `/home/benjamin/.config/.claude/errors-output.md`, lines 5-7

The output shows the /errors command created a non-standard directory structure:
```
Report will be created at: /home/benjamin/.config/.claude/specs/errors_plan_analysis/reports/001_plan_error_report.md
```

**Problems identified**:
1. Topic directory name `errors_plan_analysis` lacks the required three-digit prefix (should be `NNN_errors_plan_analysis`)
2. The directory was manually created rather than atomically allocated
3. No proper topic number was assigned per the standard `{NNN_topic}/` format

### Finding 5: Directory Protocol Standard Violations

**Reference**: `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md`, lines 245-365

The directory protocols explicitly state:

> Commands MUST NOT create artifact subdirectories (`reports/`, `debug/`, `plans/`, `summaries/`) eagerly during setup. This violates the lazy directory creation standard and creates empty directories that persist when workflows fail.

The `/errors` command violates this by:
1. Using `mkdir -p "${TOPIC_DIR}/reports"` during setup (line 271)
2. Not using `ensure_artifact_directory()` before file writes
3. Not using atomic topic allocation

### Finding 6: /repair Command as Reference Implementation

**Location**: `/home/benjamin/.config/.claude/commands/repair.md`, lines 224-256

The `/repair` command follows the correct pattern:

```bash
# Initialize workflow paths (uses fallback slug generation)
initialize_workflow_paths "$ERROR_DESCRIPTION" "research-and-plan" "$RESEARCH_COMPLEXITY" ""
INIT_EXIT=$?
if [ $INIT_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Failed to initialize workflow paths" \
    "bash_block_1" \
    "$(jq -n --arg desc "$ERROR_DESCRIPTION" '{description: $desc}')"

  echo "ERROR: Failed to initialize workflow paths" >&2
  exit 1
fi

SPECS_DIR="$TOPIC_PATH"
RESEARCH_DIR="${TOPIC_PATH}/reports"
PLANS_DIR="${TOPIC_PATH}/plans"
```

Key differences:
1. Uses `initialize_workflow_paths()` which handles everything correctly
2. Assigns path variables without creating directories
3. Relies on agents to use `ensure_artifact_directory()` for lazy creation

## Recommendations

### Recommendation 1: Source workflow-initialization.sh Library

Add the workflow-initialization.sh library to the /errors command's library sourcing section:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-initialization.sh" >&2
  exit 1
}
```

**Priority**: High
**Effort**: Low (1 line change)

### Recommendation 2: Replace Manual Directory Creation with initialize_workflow_paths()

Replace the manual topic number/name/directory creation (lines 266-271) with:

```bash
# Initialize workflow paths (uses fallback slug generation)
initialize_workflow_paths "$ERROR_DESCRIPTION" "research-only" "$RESEARCH_COMPLEXITY" ""
INIT_EXIT=$?
if [ $INIT_EXIT -ne 0 ]; then
  echo "ERROR: Failed to initialize workflow paths" >&2
  exit 1
fi

# Use exported path variables (no mkdir needed here)
RESEARCH_DIR="${TOPIC_PATH}/reports"
```

**Priority**: High
**Effort**: Medium (replace 10-15 lines)

### Recommendation 3: Remove Eager mkdir Calls

Delete or remove the following line:
```bash
mkdir -p "${TOPIC_DIR}/reports" 2>/dev/null
```

The reports directory should be created by the errors-analyst agent using `ensure_artifact_directory()` before writing the report file.

**Priority**: High
**Effort**: Low (delete 1 line)

### Recommendation 4: Update errors-analyst Agent to Use Lazy Creation

Ensure the errors-analyst agent behavioral file includes:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null
ensure_artifact_directory "$REPORT_PATH" || exit 1
```

Before writing the report file.

**Priority**: Medium
**Effort**: Low (verify agent follows standard)

### Recommendation 5: Add Topic Number to Directory Name

Ensure the topic directory follows the standard `NNN_topic_name` format by using atomic allocation from `allocate_and_create_topic()` or the `initialize_workflow_paths()` wrapper.

The output should show:
```
Report will be created at: .../specs/905_errors_plan_analysis/reports/001_plan_error_report.md
```

Not:
```
Report will be created at: .../specs/errors_plan_analysis/reports/001_plan_error_report.md
```

**Priority**: High
**Effort**: Low (automatic when using correct functions)

## Root Cause Analysis

The root cause of the `/errors` command not following directory protocols is that it was likely developed before the `workflow-initialization.sh` library was created, or was developed independently without following the established patterns. The command manually implements topic directory creation logic that has since been standardized in the workflow-initialization library.

### Contributing Factors

1. **Library Debt**: The `/errors` command was not updated when workflow-initialization.sh was introduced
2. **Copy-Paste Divergence**: Manual implementation diverged from evolving standards
3. **Missing Validation**: No automated checks to enforce directory protocol compliance

## Implementation Priority

| Fix | Priority | Effort | Impact |
|-----|----------|--------|--------|
| Source workflow-initialization.sh | High | Low | Enables all other fixes |
| Use initialize_workflow_paths() | High | Medium | Proper topic allocation |
| Remove eager mkdir | High | Low | Standard compliance |
| Verify agent lazy creation | Medium | Low | Complete the pattern |

**Recommended implementation order**: 1 -> 2 -> 3 -> 4

## References

- `/home/benjamin/.config/.claude/commands/errors.md` - /errors command implementation
- `/home/benjamin/.config/.claude/commands/repair.md` - /repair command (reference implementation)
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` - Directory protocol standards
- `/home/benjamin/.config/.claude/docs/concepts/directory-organization.md` - Directory organization standards
- `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` - Workflow path initialization library
- `/home/benjamin/.config/.claude/lib/core/unified-location-detection.sh` - Location detection and lazy creation utilities
- `/home/benjamin/.config/.claude/errors-output.md` - Output showing the problem
