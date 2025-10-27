# Library API Reference

Quick lookup reference for all `.claude/lib/` utility libraries. This document provides function signatures, return formats, and usage examples for reusable Bash libraries.

## Purpose

Utility libraries provide reusable functions for common tasks across commands and agents. Use this reference when:
- You need to call a specific utility function in a command
- You want to understand the API of an existing library
- You're looking for existing utilities before implementing new logic

For task-focused guides on when and how to use libraries, see [Using Utility Libraries](../guides/using-utility-libraries.md).

## Quick Index

**Core Utilities**:
- [unified-location-detection.sh](#unified-location-detectionsh) - Standardized location detection for workflow commands
- [plan-core-bundle.sh](#plan-core-bundlesh) - Plan parsing and manipulation
- [metadata-extraction.sh](#metadata-extractionsh) - Metadata extraction from reports/plans
- [checkpoint-utils.sh](#checkpoint-utilssh) - Checkpoint-based state management

**Agent Support**:
- [agent-registry-utils.sh](#agent-registry-utilssh) - Agent registration and discovery
- [hierarchical-agent-support.sh](#hierarchical-agent-supportsh) - Multi-level agent coordination

**Workflow Support**:
- [unified-logger.sh](#unified-loggersh) - Structured logging with rotation
- [error-handling.sh](#error-handlingsh) - Standardized error handling patterns
- [context-pruning.sh](#context-pruningsh) - Context window optimization

**Analysis and Validation**:
- [complexity-thresholds.sh](#complexity-thresholdssh) - Complexity scoring for plans
- [structure-validator.sh](#structure-validatorsh) - Directory structure validation

See [Complete Library List](#complete-library-list) for all 70+ libraries.

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
source "${CLAUDE_CONFIG}/.claude/lib/unified-location-detection.sh"

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

**NEW**: Create parent directory for artifact file using lazy creation pattern.

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

**Common Patterns**:
```bash
# In commands
ensure_artifact_directory "$PLAN_PATH" || exit 1
cat > "$PLAN_PATH" <<EOF
...
EOF

# In agent templates (via Bash tool)
source .claude/lib/unified-location-detection.sh
ensure_artifact_directory "$REPORT_PATH" || {
  echo "ERROR: Failed to create directory" >&2
  exit 1
}
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

**Behavior**: Creates only the topic root directory. Subdirectories are created on-demand when files are written to them.

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

#### Legacy Compatibility

##### `generate_legacy_location_context(location_json)`

Convert JSON output to legacy YAML format for backward compatibility.

**Arguments**:
- `location_json` (string): JSON output from `perform_location_detection()`

**Returns**: YAML-formatted location context (legacy format)

**Note**: Provided for backward compatibility. New code should use JSON output directly.

**Exit Codes**: `0` (always succeeds)

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

### checkpoint-utils.sh

Checkpoint-based state management for resumable workflows. Enables `/implement` to resume after failures.

**Performance**: <50ms checkpoint save/load

#### Core Functions

##### `save_checkpoint(checkpoint_name, state_data)`

Save workflow state to checkpoint file.

**Arguments**:
- `checkpoint_name` (string): Unique checkpoint identifier
- `state_data` (string): JSON state data

**Returns**: Nothing

**Exit Codes**:
- `0`: Success
- `1`: Failure (write failed)

##### `load_checkpoint(checkpoint_name)`

Load workflow state from checkpoint file.

**Arguments**:
- `checkpoint_name` (string): Unique checkpoint identifier

**Returns**: JSON state data (printed to stdout)

**Exit Codes**:
- `0`: Success
- `1`: Failure (checkpoint not found)

##### `list_checkpoints(pattern)`

List available checkpoints matching pattern.

**Arguments**:
- `pattern` (optional, string): Glob pattern to filter checkpoints

**Returns**: Newline-separated list of checkpoint names

**Exit Codes**: `0` (always succeeds)

---

## Agent Support

### agent-registry-utils.sh

Agent registration and discovery. Used by `/orchestrate` and Task tool integration.

#### Core Functions

##### `register_agent(agent_name, agent_path, capabilities)`

Register an agent in the global registry.

**Arguments**:
- `agent_name` (string): Unique agent identifier
- `agent_path` (string): Absolute path to agent definition
- `capabilities` (string): Comma-separated capability list

**Returns**: Nothing

**Exit Codes**:
- `0`: Success
- `1`: Failure (invalid arguments, registry write failed)

##### `discover_agent(capability_pattern)`

Discover registered agents matching capability pattern.

**Arguments**:
- `capability_pattern` (string): Regex pattern to match capabilities

**Returns**: Newline-separated list of matching agent paths

**Exit Codes**: `0` (always succeeds)

---

### hierarchical-agent-support.sh

Multi-level agent coordination for recursive supervision patterns.

#### Core Functions

##### `invoke_subagent(agent_name, task_description, context_metadata)`

Invoke a subagent with metadata context (not full content).

**Arguments**:
- `agent_name` (string): Agent identifier
- `task_description` (string): Task for subagent
- `context_metadata` (string): JSON metadata from parent agent

**Returns**: JSON response from subagent

**Exit Codes**:
- `0`: Success
- `1`: Failure (agent not found, invocation failed)

---

## Workflow Support

### unified-logger.sh

Structured logging with automatic rotation. Used by `/implement`, `/orchestrate`, adaptive planning.

**Log Location**: `.claude/data/logs/`

**Rotation**: 10MB max per log, 5 files retained

#### Core Functions

##### `log_info(message, [context])`

Log informational message with optional JSON context.

**Arguments**:
- `message` (string): Log message
- `context` (optional, string): JSON context object

**Returns**: Nothing (writes to log file)

**Exit Codes**: `0` (always succeeds)

##### `log_error(message, [context])`

Log error message with optional JSON context.

**Arguments**:
- `message` (string): Error message
- `context` (optional, string): JSON context object

**Returns**: Nothing (writes to log file and stderr)

**Exit Codes**: `0` (always succeeds)

##### `query_logs(pattern, [time_range])`

Query log files by pattern and optional time range.

**Arguments**:
- `pattern` (string): Grep-compatible search pattern
- `time_range` (optional, string): ISO 8601 time range (e.g., "2025-10-20T00:00:00/2025-10-23T23:59:59")

**Returns**: Matching log entries (newline-separated)

**Exit Codes**: `0` (always succeeds)

---

### error-handling.sh

Standardized error handling patterns for commands.

#### Core Functions

##### `handle_error(error_code, error_message, [recovery_action])`

Handle errors with optional recovery action.

**Arguments**:
- `error_code` (integer): Numeric error code
- `error_message` (string): Human-readable error description
- `recovery_action` (optional, string): Recovery command to execute

**Returns**: Nothing (exits script with error_code)

**Exit Codes**: Exits with `error_code`

---

### context-pruning.sh

Context window optimization through aggressive metadata pruning.

**Target**: <30% context usage throughout workflows

**Achieved**: 92-97% reduction through metadata-only passing

#### Core Functions

##### `prune_subagent_output(output_text)`

Clear full subagent output after metadata extraction.

**Arguments**:
- `output_text` (string): Full subagent output

**Returns**: Nothing (clears output from context)

**Exit Codes**: `0` (always succeeds)

##### `prune_phase_metadata(phase_number)`

Remove completed phase data from context.

**Arguments**:
- `phase_number` (integer): Phase to prune

**Returns**: Nothing

**Exit Codes**: `0` (always succeeds)

##### `apply_pruning_policy(workflow_type)`

Apply automatic pruning by workflow type.

**Arguments**:
- `workflow_type` (string): Workflow type (e.g., "implement", "orchestrate", "research")

**Returns**: Nothing

**Exit Codes**: `0` (always succeeds)

---

## Analysis and Validation

### complexity-thresholds.sh

Complexity scoring for plans. Used by `/plan` and adaptive planning in `/implement`.

#### Core Functions

##### `calculate_complexity(plan_path)`

Calculate complexity score for plan (0-10 scale).

**Arguments**:
- `plan_path` (string): Absolute path to plan file

**Returns**: Complexity score (float, e.g., "7.5")

**Factors**:
- Number of phases
- Tasks per phase
- File references per phase
- Dependency graph complexity

**Exit Codes**:
- `0`: Success
- `1`: Failure (file not found, invalid format)

---

### structure-validator.sh

Directory structure validation for topic directories.

#### Core Functions

##### `validate_topic_structure(topic_path)`

Validate that topic directory has all 6 required subdirectories.

**Arguments**:
- `topic_path` (string): Absolute path to topic directory

**Returns**: Validation report (JSON)

**Exit Codes**:
- `0`: Valid structure
- `1`: Invalid structure (missing subdirectories)

---

## Complete Library List

### Workflow Orchestration
- `unified-location-detection.sh` - Standardized location detection
- `parallel-orchestration-utils.sh` - Parallel subagent execution
- `workflow-detection.sh` - Workflow type detection from descriptions

### Plan Management
- `plan-core-bundle.sh` - Plan parsing and manipulation
- `progressive-planning-utils.sh` - Progressive plan expansion/collapse
- `complexity-thresholds.sh` - Plan complexity scoring
- `dependency-analyzer.sh` - Phase dependency analysis
- `checkpoint-utils.sh` - Checkpoint state management
- `checkbox-utils.sh` - Checkbox state tracking in plans

### Agent Coordination
- `agent-registry-utils.sh` - Agent registration and discovery
- `agent-discovery.sh` - Agent capability matching
- `agent-loading-utils.sh` - Agent definition loading
- `hierarchical-agent-support.sh` - Multi-level agent coordination
- `agent-frontmatter-validator.sh` - Agent metadata validation
- `agent-schema-validator.sh` - Agent schema validation

### Context Optimization
- `metadata-extraction.sh` - Report/plan metadata extraction
- `context-pruning.sh` - Context window optimization
- `context-metrics.sh` - Context usage measurement

### Artifact Management
- `artifact-creation.sh` - Artifact file creation
- `artifact-registry.sh` - Artifact tracking and cross-reference
- `artifact-cross-reference.sh` - Cross-reference resolution
- `artifact-cleanup.sh` - Artifact lifecycle management

### Logging and Monitoring
- `unified-logger.sh` - Structured logging with rotation
- `progress-tracker.sh` - Workflow progress tracking
- `progress-dashboard.sh` - Progress visualization
- `analyze-metrics.sh` - Performance metrics analysis

### Error Handling
- `error-handling.sh` - Standardized error handling
- `validation-utils.sh` - Input validation utilities

### Template and Substitution
- `template-integration.sh` - Template rendering
- `parse-template.sh` - Template parsing
- `substitute-variables.sh` - Variable substitution

### Testing and Validation
- `detect-testing.sh` - Test infrastructure detection
- `generate-testing-protocols.sh` - Test protocol generation
- `structure-validator.sh` - Directory structure validation

### Git Integration
- `git-utils.sh` - Git operations (commit, push, status)

### Conversion Utilities
- `convert-core.sh` - Document format conversion
- `convert-docx.sh` - DOCX conversion
- `convert-markdown.sh` - Markdown conversion
- `convert-pdf.sh` - PDF conversion

### Miscellaneous
- `json-utils.sh` - JSON parsing and manipulation
- `timestamp-utils.sh` - Timestamp utilities
- `base-utils.sh` - Base utility functions
- `deps-utils.sh` - Dependency checking

### Legacy and Migration
- `artifact-operations-legacy.sh` - Legacy artifact operations
- `migrate-checkpoint-v1.3.sh` - Checkpoint migration
- `migrate-specs-utils.sh` - Specs directory migration
- `migrate-agent-registry.sh` - Agent registry migration

---

## Usage Notes

### Sourcing Libraries

Always source libraries using absolute paths from `CLAUDE_CONFIG`:

```bash
# Recommended
source "${CLAUDE_CONFIG}/.claude/lib/unified-location-detection.sh"

# Also acceptable (relative path from .claude/)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/unified-location-detection.sh"
```

### jq Dependency

Many libraries support optional jq for JSON parsing:

```bash
# Preferred (jq available)
if command -v jq &>/dev/null; then
  TOPIC_PATH=$(echo "$JSON" | jq -r '.topic_path')
else
  # Fallback (sed/grep parsing)
  TOPIC_PATH=$(echo "$JSON" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
fi
```

### Error Handling

All libraries follow consistent error handling:

```bash
# Check exit code
if ! perform_location_detection "description"; then
  echo "ERROR: Location detection failed"
  exit 1
fi

# Or use command substitution with || operator
RESULT=$(some_library_function "arg") || {
  echo "ERROR: Function failed"
  exit 1
}
```

### Performance Characteristics

| Library | Typical Execution Time | Token Usage | Notes |
|---------|----------------------|-------------|-------|
| unified-location-detection.sh | <1s | <11k | No AI calls |
| plan-core-bundle.sh | <1s | 0 | Pure bash |
| metadata-extraction.sh | <100ms | 0 | Pure bash |
| checkpoint-utils.sh | <50ms | 0 | File I/O only |
| agent-registry-utils.sh | <100ms | 0 | File I/O only |
| unified-logger.sh | <10ms | 0 | Append-only writes |

---

## See Also

- [Using Utility Libraries](../guides/using-utility-libraries.md) - Task-focused guide for library usage
- [Command Development Guide](../guides/command-development-guide.md) - Creating commands that use libraries
- [Agent Development Guide](../guides/agent-development-guide.md) - Creating agents that use libraries
- [Performance Measurement](../guides/performance-measurement.md) - Measuring library performance impact
