# Library API Reference - Utilities

Agent support, workflow support, analysis, and complete library list.

## Navigation

This document is part of a multi-part reference:
- [Overview](overview.md) - Purpose, quick index, core utilities
- [State Machine](library-api-state-machine.md) - Workflow classification and scope detection
- [Persistence](library-api-persistence.md) - State persistence and checkpoint utilities
- **Utilities** (this file) - Agent support, workflow support, analysis, and complete library list

---

## Agent Support

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

### overview-synthesis.sh

Standardized overview synthesis decision logic for orchestration commands.

**Purpose**: Provides uniform decision logic for when OVERVIEW.md synthesis should occur across `/research`, `/supervise`, and `/coordinate` commands.

**Commands using this library**: `/research`, `/supervise`, `/coordinate`

**Key Principle**: Overview synthesis only occurs when workflows conclude with research (no planning follows). When planning phase follows research, the plan-architect agent synthesizes reports, making OVERVIEW.md redundant.

#### Core Functions

##### `should_synthesize_overview(workflow_scope, report_count)`

Determines if overview synthesis should occur based on workflow scope and report count.

**Arguments**:
- `workflow_scope` (string): Workflow type (research-only | research-and-plan | full-implementation | debug-only)
- `report_count` (integer): Number of successful research reports created

**Returns**: Nothing (uses exit code to indicate decision)

**Exit Codes**:
- `0` (true): Overview should be synthesized
- `1` (false): Overview should NOT be synthesized

**Decision Logic**:
- Requires >=2 reports for synthesis (can't synthesize 1 report into overview)
- `research-only`: Returns `0` (workflow ends with research)
- `research-and-plan`: Returns `1` (plan-architect will synthesize)
- `full-implementation`: Returns `1` (plan-architect will synthesize)
- `debug-only`: Returns `1` (debug doesn't produce research reports)
- Unknown scope: Returns `1` (conservative default)

**Usage Example**:
```bash
# /research is always research-only workflow
WORKFLOW_SCOPE="research-only"

if should_synthesize_overview "$WORKFLOW_SCOPE" "$REPORT_COUNT"; then
  # Create OVERVIEW.md
  OVERVIEW_PATH=$(calculate_overview_path "$RESEARCH_SUBDIR")
  echo "Creating overview at: $OVERVIEW_PATH"
else
  # Skip synthesis - plan will synthesize reports
  SKIP_REASON=$(get_synthesis_skip_reason "$WORKFLOW_SCOPE" "$REPORT_COUNT")
  echo "Skipping overview: $SKIP_REASON"
fi
```

##### `calculate_overview_path(research_subdir)`

Calculates the standardized path for OVERVIEW.md synthesis report.

**Arguments**:
- `research_subdir` (string): Directory containing research reports

**Returns**: Prints standardized overview path to stdout

**Exit Codes**:
- `0`: Success
- `1`: Error (empty research_subdir argument)

**Path Format**: `${research_subdir}/OVERVIEW.md`

##### `get_synthesis_skip_reason(workflow_scope, report_count)`

Returns human-readable explanation of why overview synthesis was skipped.

**Arguments**:
- `workflow_scope` (string): Workflow type
- `report_count` (integer): Number of successful research reports

**Returns**: Prints skip reason to stdout

**Exit Codes**: `0` (always succeeds)

---

## Analysis and Validation

### complexity-utils.sh

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
- `complexity-utils.sh` - Plan complexity scoring
- `dependency-analyzer.sh` - Phase dependency analysis
- `checkpoint-utils.sh` - Checkpoint state management
- `checkbox-utils.sh` - Checkbox state tracking in plans

### Agent Coordination
- `agent-loading-utils.sh` - Agent definition loading
- `hierarchical-agent-support.sh` - Multi-level agent coordination
- `agent-frontmatter-validator.sh` - Agent metadata validation

### Context Optimization
- `metadata-extraction.sh` - Report/plan metadata extraction
- `context-pruning.sh` - Context window optimization

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

### Conversion Utilities
- `convert-core.sh` - Document format conversion
- `convert-docx.sh` - DOCX conversion
- `convert-markdown.sh` - Markdown conversion
- `convert-pdf.sh` - PDF conversion

### Miscellaneous
- `timestamp-utils.sh` - Timestamp utilities
- `base-utils.sh` - Base utility functions

### Migration Scripts
- `migrate-checkpoint-v1.3.sh` - Checkpoint migration
- `migrate-agent-registry.sh` - Agent registry migration

---

## Usage Notes

### Sourcing Libraries

Always source libraries using absolute paths from `CLAUDE_CONFIG`:

```bash
# Recommended
source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"

# Also acceptable (relative path from .claude/)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/core/unified-location-detection.sh"
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

- [Overview](overview.md) - Purpose, quick index, core utilities
- [State Machine](library-api-state-machine.md) - Workflow classification and scope detection
- [Persistence](library-api-persistence.md) - State persistence and checkpoint utilities
- [Using Utility Libraries](../guides/development/using-utility-libraries.md) - Task-focused guide for library usage
- [Command Development Guide](../guides/development/command-development/command-development-fundamentals.md) - Creating commands that use libraries
- [Agent Development Guide](../guides/development/agent-development/agent-development-fundamentals.md) - Creating agents that use libraries
- [Performance Measurement](../guides/patterns/performance-optimization.md) - Measuring library performance impact
