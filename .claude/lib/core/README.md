# Core Libraries

## Purpose

Essential infrastructure libraries required by most commands. This directory contains foundational utilities including base utilities for error handling and logging, project directory detection, centralized error classification and recovery strategies, library sourcing with deduplication, version validation, state persistence for workflows, unified location detection, and structured logging interfaces.

## Libraries

### base-utils.sh
Common utility functions to eliminate code duplication across libraries.

**Key Functions:**
- `error()` - Print error message and exit
- `warn()` - Print warning message
- `info()` - Print info message
- `debug()` - Print debug message (if DEBUG=1)
- `require_command()` - Check for required command
- `require_file()` - Check for required file
- `require_dir()` - Check for required directory

**Usage:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/base-utils.sh"
error "Configuration file not found"
require_command "jq" "Please install jq"
```

### detect-project-dir.sh
Project directory detection for determining project root.

**Key Functions:**
- `detect_project_root()` - Find project root directory
- `find_claude_dir()` - Locate .claude directory

### error-handling.sh
Error classification, recovery strategies, retry logic, and user escalation.

**Key Functions:**
- `classify_error()` - Classify error as transient/permanent/fatal
- `detect_error_type()` - Detect specific error type from message
- `suggest_recovery()` - Suggest recovery action for error type
- `retry_with_backoff()` - Retry command with exponential backoff
- `try_with_fallback()` - Try primary approach, fall back to alternative

**Usage:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh"
ERROR_TYPE=$(classify_error "Database connection timeout")
retry_with_backoff 3 500 curl "https://api.example.com"
```

### library-sourcing.sh
Library sourcing utilities with deduplication.

**Key Functions:**
- `source_required_libraries()` - Source libraries with automatic deduplication

### library-version-check.sh
Library version validation.

**Key Functions:**
- `check_library_requirements()` - Validate library versions meet requirements

**Usage:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/library-version-check.sh"
check_library_requirements "$(cat <<'EOF'
workflow-state-machine.sh: ">=2.0.0"
state-persistence.sh: ">=1.5.0"
EOF
)" || exit 1
```

### state-persistence.sh
State file management for workflow persistence.

**Key Functions:**
- `init_workflow_state()` - Initialize workflow state file
- `append_workflow_state()` - Append state to workflow
- `get_workflow_state()` - Get current workflow state

### unified-location-detection.sh
Standard path resolution (85% token reduction vs agent-based detection).

**Key Functions:**
- `detect_location()` - Standard location detection
- `resolve_path()` - Resolve relative paths

### unified-logger.sh
Unified logging interface for all operation types.

**Key Functions:**
- `init_log()` - Initialize log file
- `log_event()` - Log structured event
- `rotate_log_file()` - Rotate log files automatically
- `query_log()` - Query log entries

## Dependencies

`base-utils.sh` has no dependencies and should be sourced first when needed by other libraries.

## Navigation

- [← Parent Directory](../README.md)
