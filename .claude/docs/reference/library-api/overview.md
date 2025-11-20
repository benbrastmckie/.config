# Library API Reference - Overview

Quick lookup reference for all `.claude/lib/` utility libraries. This document provides function signatures, return formats, and usage examples for reusable Bash libraries.

## Navigation

This document is part of a multi-part reference:
- **Overview** (this file) - Purpose, quick index, core utilities
- [State Machine](library-api-state-machine.md) - Workflow classification and scope detection
- [Persistence](library-api-persistence.md) - State persistence and checkpoint utilities
- [Utilities](library-api-utilities.md) - Agent support, workflow support, analysis, and complete library list

---

## Purpose

Utility libraries provide reusable functions for common tasks across commands and agents. Use this reference when:
- You need to call a specific utility function in a command
- You want to understand the API of an existing library
- You're looking for existing utilities before implementing new logic

For task-focused guides on when and how to use libraries, see [Using Utility Libraries](../guides/development/using-utility-libraries.md).

---

## Quick Index

**Core Utilities**:
- [unified-location-detection.sh](#unified-location-detectionsh) - Standardized location detection for workflow commands
- [plan-core-bundle.sh](#plan-core-bundlesh) - Plan parsing and manipulation
- [metadata-extraction.sh](#metadata-extractionsh) - Metadata extraction from reports/plans
- [checkpoint-utils.sh](library-api-persistence.md#checkpoint-utilssh) - Checkpoint-based state management
- [state-persistence.sh](library-api-persistence.md#state-persistencesh) - GitHub Actions-style selective state persistence

**Workflow Classification**:
- [workflow-llm-classifier.sh](library-api-state-machine.md#workflow-llm-classifiersh) - LLM-based semantic classification
- [workflow-scope-detection.sh](library-api-state-machine.md#workflow-scope-detectionsh) - Unified workflow classification

**Agent Support**:
- [hierarchical-agent-support.sh](library-api-utilities.md#hierarchical-agent-supportsh) - Multi-level agent coordination

**Workflow Support**:
- [unified-logger.sh](library-api-utilities.md#unified-loggersh) - Structured logging with rotation
- [error-handling.sh](library-api-utilities.md#error-handlingsh) - Standardized error handling patterns
- [context-pruning.sh](library-api-utilities.md#context-pruningsh) - Context window optimization
- [overview-synthesis.sh](library-api-utilities.md#overview-synthesissh) - Standardized overview synthesis decision logic

**Analysis and Validation**:
- [complexity-utils.sh](library-api-utilities.md#complexity-utilssh) - Complexity scoring for plans
- [structure-validator.sh](library-api-utilities.md#structure-validatorsh) - Directory structure validation

See [Complete Library List](library-api-utilities.md#complete-library-list) for all 70+ libraries.

---

## Core Utilities

### unified-location-detection.sh

Standardized location detection for all workflow commands. Replaces command-specific location logic with a single, tested library.

**Performance**: <1s execution, <11k tokens (vs 75.6k baseline for agent-based detection)

**Commands using this library**: `/supervise`, `/orchestrate`, `/report`, `/research`, `/plan`

#### Core Functions

##### `perform_location_detection(workflow_description, [force_new_topic])`

Complete location detection workflow. Orchestrates all detection functions and returns JSON with topic paths.

**Arguments**:
- `workflow_description` (string): User-provided workflow description
- `force_new_topic` (optional, default: `"false"`): Set to `"true"` to skip existing topic reuse check

**Returns**: JSON object with location context:
```json
{
  "topic_number": "082",
  "topic_name": "auth_patterns_research",
  "topic_path": "/path/to/specs/082_auth_patterns_research",
  "artifact_paths": {
    "reports": "/path/to/specs/082_auth_patterns_research/reports",
    "plans": "/path/to/specs/082_auth_patterns_research/plans",
    "summaries": "/path/to/specs/082_auth_patterns_research/summaries",
    "debug": "/path/to/specs/082_auth_patterns_research/debug",
    "scripts": "/path/to/specs/082_auth_patterns_research/scripts",
    "outputs": "/path/to/specs/082_auth_patterns_research/outputs"
  }
}
```

**Exit Codes**:
- `0`: Success
- `1`: Failure (directory creation or detection failed)

**Usage Example**:
```bash
# Source the library
source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"

# Perform location detection
LOCATION_JSON=$(perform_location_detection "research authentication patterns")

# Extract paths using jq
if command -v jq &>/dev/null; then
  TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
  REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
else
  # Fallback without jq (sed parsing)
  TOPIC_PATH=$(echo "$LOCATION_JSON" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  REPORTS_DIR=$(echo "$LOCATION_JSON" | grep -o '"reports": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
fi

# MANDATORY VERIFICATION checkpoint
if [ ! -d "$TOPIC_PATH" ]; then
  echo "ERROR: Location detection failed - directory not created"
  exit 1
fi

# Use the paths
echo "Creating report in: $REPORTS_DIR"
```

##### `detect_project_root()`

Determine project root directory with git worktree support.

**Arguments**: None

**Returns**: Absolute path to project root (printed to stdout)

**Precedence**:
1. `CLAUDE_PROJECT_DIR` environment variable (manual override)
2. Git repository root (via `git rev-parse --show-toplevel`)
3. Current working directory (fallback)

**Exit Codes**: `0` (always succeeds, uses fallback if needed)

**Usage Example**:
```bash
PROJECT_ROOT=$(detect_project_root)
echo "Project root: $PROJECT_ROOT"
```

##### `sanitize_topic_name(raw_name)`

Convert workflow description to valid topic directory name.

**Arguments**:
- `raw_name` (string): Raw workflow description (user input)

**Returns**: Sanitized topic name (snake_case, max 50 chars)

**Sanitization Rules**:
- Convert to lowercase
- Replace spaces with underscores
- Remove all non-alphanumeric characters except underscores
- Trim leading/trailing underscores
- Collapse multiple consecutive underscores
- Truncate to 50 characters

**Exit Codes**: `0` (always succeeds)

**Usage Example**:
```bash
TOPIC_NAME=$(sanitize_topic_name "Research: Authentication Patterns")
# Result: "research_authentication_patterns"

TOPIC_NAME=$(sanitize_topic_name "OAuth 2.0 Security (Best Practices)")
# Result: "oauth_20_security_best_practices"
```

##### `ensure_artifact_directory(file_path)`

Creates parent directory for artifact file using lazy creation pattern.

**Arguments**:
- `file_path` (string): Absolute path to artifact file (e.g., report, plan, summary)

**Returns**: Nothing (exits on failure)

**Creates**:
- Parent directory only if it doesn't exist

**Exit Codes**:
- `0`: Success (directory exists or was created)
- `1`: Failure (directory creation failed)

**Behavior**:
- **Idempotent**: Safe to call multiple times for the same path
- **Lazy**: Creates directories only when files are actually written
- **Minimal overhead**: <5ms per call, directory check + mkdir if needed

**Performance**: Eliminates 400-500 empty directories by creating directories on-demand instead of eagerly.

**Usage Example**:
```bash
# Before writing any file, ensure parent directory exists
REPORT_PATH="${TOPIC_DIR}/reports/001_analysis.md"
ensure_artifact_directory "$REPORT_PATH" || {
  echo "ERROR: Failed to create parent directory"
  exit 1
}

# Now safe to write file
echo "content" > "$REPORT_PATH"
```

##### `create_topic_structure(topic_path)`

Create topic root directory using lazy subdirectory creation.

**Arguments**:
- `topic_path` (string): Absolute path to topic directory

**Returns**: Nothing (exits on failure)

**Creates**:
- Topic root directory ONLY
- Subdirectories (reports/, plans/, etc.) created on-demand via `ensure_artifact_directory()`

**Exit Codes**:
- `0`: Success (topic root created)
- `1`: Failure (directory creation failed)

**Usage Example**:
```bash
TOPIC_PATH="/path/to/specs/082_auth_patterns"
create_topic_structure "$TOPIC_PATH" || {
  echo "ERROR: Failed to create topic structure"
  exit 1
}

# Only topic root exists at this point
# Subdirectories created when files are written using ensure_artifact_directory()
```

##### `create_research_subdirectory(topic_path, research_name)`

Create numbered subdirectory within topic's `reports/` directory for hierarchical research (/research command).

**Arguments**:
- `topic_path` (string): Absolute path to topic directory
- `research_name` (string): Sanitized snake_case name for research subdirectory

**Returns**: Absolute path to research subdirectory (printed to stdout)

**Creates**: `{topic_path}/reports/{NNN_research_name}/` where NNN is next sequential number

**Exit Codes**:
- `0`: Success
- `1`: Error (invalid arguments, directory creation failed)

**Usage Example**:
```bash
TOPIC_PATH="/path/to/specs/082_auth_patterns"
RESEARCH_SUBDIR=$(create_research_subdirectory "$TOPIC_PATH" "oauth_analysis")
# Result: /path/to/specs/082_auth_patterns/reports/001_oauth_analysis/

# Second research in same topic
RESEARCH_SUBDIR=$(create_research_subdirectory "$TOPIC_PATH" "jwt_patterns")
# Result: /path/to/specs/082_auth_patterns/reports/002_jwt_patterns/
```

#### Supporting Functions

##### `detect_specs_directory(project_root)`

Determine specs directory location (`.claude/specs` vs `specs`).

**Arguments**:
- `project_root` (string): Absolute path to project root

**Returns**: Absolute path to specs directory

**Precedence**:
1. `.claude/specs` (preferred, modern convention)
2. `specs` (legacy convention)
3. Create `.claude/specs` (default for new projects)

**Exit Codes**:
- `0`: Success
- `1`: Failed to create directory

##### `get_next_topic_number(specs_root)`

Calculate next sequential topic number from existing topics.

**Arguments**:
- `specs_root` (string): Absolute path to specs directory

**Returns**: Three-digit topic number (e.g., "001", "042", "137")

**Logic**: Find max existing topic number, increment by 1

**Exit Codes**: `0` (always succeeds)

##### `find_existing_topic(specs_root, topic_name_pattern)`

Search for existing topic matching name pattern (optional reuse).

**Arguments**:
- `specs_root` (string): Absolute path to specs directory
- `topic_name_pattern` (string): Regex pattern to match topic names

**Returns**: Topic number if found, empty string if not found

**Exit Codes**: `0` (always succeeds, whether found or not)

---

### plan-core-bundle.sh

Plan parsing, manipulation, and metadata extraction. Used by `/plan`, `/implement`, `/expand`, `/collapse`, and `/revise` commands.

**Performance**: Pure bash, no AI calls, <1s parsing for typical plans

#### Core Functions

##### `parse_plan_file(plan_path)`

Parse plan structure and extract phases.

**Arguments**:
- `plan_path` (string): Absolute path to plan file

**Returns**: Plan metadata (phases, tasks, complexity)

**Exit Codes**:
- `0`: Success
- `1`: Failure (file not found, invalid format)

##### `extract_phase_info(plan_path, phase_number)`

Extract phase details and tasks from plan.

**Arguments**:
- `plan_path` (string): Absolute path to plan file
- `phase_number` (integer): Phase number to extract

**Returns**: Phase metadata (name, tasks, dependencies)

**Exit Codes**:
- `0`: Success
- `1`: Failure (phase not found, invalid format)

##### `get_plan_metadata(plan_path)`

Get plan-level metadata (complexity, time estimates, dependencies).

**Arguments**:
- `plan_path` (string): Absolute path to plan file

**Returns**: Plan metadata in key-value format

**Exit Codes**:
- `0`: Success
- `1`: Failure (file not found, invalid format)

---

### metadata-extraction.sh

Metadata extraction from reports and plans for context window optimization. Enables 99% context reduction for hierarchical agent patterns.

**Performance**: <100ms extraction, 5000 tokens → 50 tokens typical reduction

#### Core Functions

##### `extract_report_metadata(report_path)`

Extract title, summary, file paths, and recommendations from research reports.

**Arguments**:
- `report_path` (string): Absolute path to report file

**Returns**: JSON object with metadata:
```json
{
  "title": "Report Title",
  "summary": "50-word summary...",
  "file_paths": ["/path/to/file1", "/path/to/file2"],
  "recommendations": ["Recommendation 1", "Recommendation 2"]
}
```

**Exit Codes**:
- `0`: Success
- `1`: Failure (file not found, invalid format)

##### `extract_plan_metadata(plan_path)`

Extract complexity, phases, time estimates from implementation plans.

**Arguments**:
- `plan_path` (string): Absolute path to plan file

**Returns**: JSON object with metadata:
```json
{
  "complexity": "7.5/10",
  "phases": 6,
  "estimated_duration": "6.5-7.5 hours",
  "dependencies": []
}
```

**Exit Codes**:
- `0`: Success
- `1`: Failure (file not found, invalid format)

##### `load_metadata_on_demand(artifact_path)`

Generic metadata loader with caching for reports, plans, or summaries.

**Arguments**:
- `artifact_path` (string): Absolute path to artifact file

**Returns**: JSON metadata (format depends on artifact type)

**Exit Codes**:
- `0`: Success
- `1`: Failure (file not found, unsupported type)

---

## Related Documentation

- [State Machine](library-api-state-machine.md) - Workflow classification and scope detection
- [Persistence](library-api-persistence.md) - State persistence and checkpoint utilities
- [Utilities](library-api-utilities.md) - Agent support, workflow support, analysis, and complete library list
- [Using Utility Libraries](../guides/development/using-utility-libraries.md) - Task-focused guide for library usage
- [Command Development Guide](../guides/development/command-development/command-development-fundamentals.md) - Creating commands that use libraries
