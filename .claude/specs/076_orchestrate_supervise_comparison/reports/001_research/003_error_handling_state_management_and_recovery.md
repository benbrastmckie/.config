# Error Handling State Management and Recovery Research Report

## Metadata
- **Date**: 2025-10-23
- **Agent**: research-specialist
- **Topic**: Error Handling State Management and Recovery
- **Report Type**: codebase analysis

## Executive Summary

Both /orchestrate and /supervise commands implement error handling and state management, but with dramatically different philosophies and mechanisms. /orchestrate uses a comprehensive checkpoint-based recovery system with automatic retry logic, fallback mechanisms, and stateful workflow tracking via `.claude/lib/checkpoint-utils.sh` and `.claude/lib/error-handling.sh`. /supervise takes a minimalist "fail-fast" approach with zero fallback mechanisms, relying on explicit verification checkpoints without persistent state management or retry infrastructure.

## Findings

### Error Handling Architecture

#### /orchestrate Error Handling Strategy

**Comprehensive Error Recovery Framework**

/orchestrate implements a three-tier error handling strategy:

1. **Auto-Retry with Exponential Backoff** (/orchestrate.md:857-1058)
   - Research phase: 3 retry attempts per topic with escalating template enforcement
   - Planning phase: 3 retry attempts with ultra-explicit enforcement (orchestrate.md:1515-1783)
   - Uses `retry_with_backoff()` from error-handling.sh:230-260
   - Exponential backoff: base 500ms, doubles per attempt (2x multiplier)
   - Timeout extension: `retry_with_timeout()` increases timeout 1.5x per attempt (error-handling.sh:262-304)

2. **Fallback File Creation** (/orchestrate.md:516-544, 1198-1227)
   - When subagents fail to create files after 3 retries, orchestrator creates minimal fallback files
   - Example: Topic directory creation fallback (orchestrate.md:519-523)
   - Overview report fallback using research-synthesizer agent (orchestrate.md:1206-1227)
   - Guarantees 100% workflow completion even with agent failures

3. **Error Classification and Recovery Suggestions** (error-handling.sh:10-71)
   - Errors classified as: transient, permanent, or fatal
   - `classify_error()`: Pattern matching on error messages (error-handling.sh:20-42)
   - `suggest_recovery()`: Context-specific recovery actions (error-handling.sh:44-71)
   - Transient errors → retry with backoff
   - Permanent errors → analyze and fix code
   - Fatal errors → user intervention required

**Specialized Error Handlers**

- `detect_error_type()`: 8 specific error types (syntax, test_failure, file_not_found, import_error, null_error, timeout, permission, unknown) - error-handling.sh:77-128
- `extract_location()`: Parse file:line from error messages - error-handling.sh:130-145
- `generate_suggestions()`: Error-specific remediation steps - error-handling.sh:147-224
- Orchestrate-specific formatters: `format_orchestrate_agent_failure()`, `format_orchestrate_test_failure()`, `format_orchestrate_phase_context()` - error-handling.sh:625-729

#### /supervise Error Handling Strategy

**Fail-Fast with Zero Fallbacks**

/supervise implements a strict fail-fast approach (supervise.md:163, 245-260):

1. **Single Execution Path** (supervise.md:1475-1492)
   - Zero retry infrastructure - single template per agent type
   - No fallback file creation mechanisms
   - Immediate workflow termination on agent failure
   - Clear error messages with actionable instructions

2. **Explicit Verification Checkpoints** (supervise.md:15, 330, 1490)
   - Mandatory verification after every file operation
   - Uses Bash tool for verification: `ls`, `grep`, `wc`
   - File must exist AND have content >500 bytes
   - Empty files trigger immediate workflow termination

3. **Error Detection Only** (supervise.md:245-260)
   - Detects agent failures (file not created)
   - Detects empty file creation
   - Reports error and terminates workflow
   - No recovery mechanisms - user must fix and retry

**Design Philosophy**

Per supervise.md:163,1475:
- **Zero Fallbacks**: Single working path, fail-fast on errors
- **Conservative**: Default to safest workflow mode (research-and-plan)
- **Explicit**: Mandatory verification at all checkpoints
- **Transparent**: Clear failure modes, no hidden recovery paths

### State Management and Checkpoints

#### /orchestrate Checkpoint System

**Comprehensive Checkpoint Infrastructure**

1. **Checkpoint Utilities** (checkpoint-utils.sh:1-824)
   - **Schema Version**: 1.3 (supports migration from 1.0 → 1.1 → 1.2 → 1.3)
   - **Storage**: `.claude/data/checkpoints/` directory
   - **Functions**:
     - `save_checkpoint()`: Save workflow state (checkpoint-utils.sh:54-172)
     - `restore_checkpoint()`: Load most recent checkpoint (checkpoint-utils.sh:174-230)
     - `validate_checkpoint()`: Verify structure and required fields (checkpoint-utils.sh:232-278)
     - `migrate_checkpoint_format()`: Auto-upgrade old checkpoints (checkpoint-utils.sh:280-375)

2. **Checkpoint Schema** (checkpoint-utils.sh:82-138)
   ```json
   {
     "schema_version": "1.3",
     "checkpoint_id": "orchestrate_project_20251023_142300",
     "workflow_type": "orchestrate",
     "project_name": "user_authentication",
     "workflow_description": "Add OAuth2 authentication",
     "created_at": "2025-10-23T14:23:00Z",
     "updated_at": "2025-10-23T14:25:00Z",
     "status": "in_progress",
     "current_phase": 2,
     "total_phases": 7,
     "completed_phases": [1],
     "workflow_state": { /* phase-specific state */ },
     "last_error": null,
     "tests_passing": true,
     "plan_modification_time": 1729693800,
     "replanning_count": 0,
     "replan_phase_counts": {},
     "replan_history": [],
     "debug_report_path": null,
     "user_last_choice": null,
     "debug_iteration_count": 0,
     "topic_directory": "specs/042_auth",
     "topic_number": "042",
     "context_preservation": { /* pruning logs, metadata cache */ },
     "template_source": null,
     "spec_maintenance": { /* parent plans, checkbox propagation */ }
   }
   ```

3. **Workflow State Tracking** (orchestrate.md:173-227)
   - In-memory `workflow_state` structure tracks execution progress
   - Fields: current_phase, topic_directory, research_topics, report_paths, plan_path, error_history, execution_tracking
   - Saved to checkpoint at phase boundaries (orchestrate.md:611, 1422, 2034, 2560)
   - Enables resume from exact interruption point

4. **Smart Auto-Resume** (checkpoint-utils.sh:665-806)
   - `check_safe_resume_conditions()`: 5 safety checks before auto-resume
     1. Tests passing in last run (tests_passing == true)
     2. No recent errors (last_error == null)
     3. Status is in_progress (not failed/complete)
     4. Checkpoint age < 7 days
     5. Plan file not modified since checkpoint
   - `get_skip_reason()`: Human-readable reason if auto-resume not safe
   - Prevents silent continuation after failures

5. **Parallel Operation Checkpoints** (checkpoint-utils.sh:500-659)
   - `save_parallel_operation_checkpoint()`: State before parallel ops
   - `restore_from_checkpoint()`: Rollback on failure
   - `validate_checkpoint_integrity()`: Pre-restore validation
   - Storage: `.claude/data/checkpoints/parallel_ops/`

6. **Checkpoint Resume Flow** (orchestrate.md:211-228)
   ```bash
   # Check for checkpoint file
   if [ -f .claude/checkpoints/orchestrate_latest.checkpoint ]; then
     echo "Found existing orchestration checkpoint. Resume? (y/n)"
     # If yes: load checkpoint state and skip to current_phase
   fi
   ```

7. **Context Preservation** (checkpoint schema v1.3, checkpoint-utils.sh:125-129)
   - Pruning logs track context reduction operations
   - Artifact metadata cache for fast reload
   - Subagent output references (paths only, not full content)

#### /supervise State Management

**No Persistent State**

/supervise has ZERO checkpoint or state management infrastructure:

1. **No Checkpoints** (supervise.md - no checkpoint references)
   - No checkpoint creation functions
   - No checkpoint restoration capabilities
   - No state persistence between invocations
   - Workflow is atomic - must complete or restart from beginning

2. **No Resume Capability** (supervise.md - no resume logic)
   - Cannot resume from interruption
   - Cannot continue after agent failure
   - No workflow state tracking
   - Each invocation is independent

3. **Verification-Only Checkpoints** (supervise.md:15, 330, 1490)
   - "Checkpoints" refer to verification points, not state snapshots
   - Explicit file existence checks after agent operations
   - No state saved - only validation performed
   - Workflow terminates if verification fails

4. **Stateless Design Philosophy**
   - Designed for simple, short-duration workflows
   - Completion within single agent session expected
   - No long-running or interruptible workflows
   - Restart from beginning if interrupted

### Recovery Patterns

#### /orchestrate Recovery Mechanisms

1. **Automatic Retry Loop** (orchestrate.md:857-1058)
   - 3 retry attempts with escalating enforcement templates
   - Attempt 1: Standard template
   - Attempt 2: Ultra-explicit enforcement
   - Attempt 3: Step-by-step enforcement with verification
   - File validation built into retry loop

2. **Degraded Continuation** (orchestrate.md:998-1027)
   - Workflow continues even if some agents fail
   - Tracks successful vs failed operations
   - Reports partial results
   - Example: 2/3 research topics completed successfully

3. **Error History Tracking** (orchestrate.md:199, 291-295)
   ```
   workflow_state.error_history: [
     {phase: "research", error: "timeout", retry_count: 2, recovered: true},
     {phase: "planning", error: "file_not_found", retry_count: 1, recovered: false}
   ]
   ```

4. **Debugging Loop Integration** (orchestrate.md:2150-2611)
   - Max 3 debug iterations on test failures
   - Iteration < 3: Retry with fixes
   - Iteration ≥ 3: Escalate to user
   - State tracked: debug_iteration_count, debug_report_path, user_last_choice

5. **Partial Failure Handling** (error-handling.sh:532-604)
   - `handle_partial_failure()`: Process successful ops, report failures
   - Separates successful_operations from failed_operations
   - Returns: `{can_continue: true/false, requires_retry: true/false}`
   - Enables continuation with partial results

6. **User Escalation** (error-handling.sh:384-473)
   - `escalate_to_user()`: Present error with recovery options
   - `escalate_to_user_parallel()`: Context for parallel operation failures
   - Interactive choice if terminal available
   - Default to safe option if non-interactive

#### /supervise Recovery Mechanisms

**Zero Automatic Recovery**

1. **Fail-Fast Termination** (supervise.md:245-260, 685-688)
   ```
   ERROR: Agent failed to create report file.
   Workflow TERMINATED. Fix agent enforcement and retry.
   ```

2. **Manual Retry Required**
   - User must:
     1. Identify failure cause from error message
     2. Fix agent enforcement or workflow description
     3. Re-invoke /supervise from beginning
   - No checkpoint to resume from
   - No partial progress saved

3. **No Fallback Paths**
   - Single execution path (supervise.md:1484)
   - No orchestrator file creation
   - No retry infrastructure
   - No graceful degradation

### Integration with Utilities

#### /orchestrate Utility Integration

**Deep Integration** (orchestrate.md:236-295)

1. **Error Handling Library** (orchestrate.md:251, 255, 263-267)
   - Sources: `.claude/lib/error-handling.sh`
   - Functions used:
     - `retry_with_backoff()`: Auto-retry with exponential backoff
     - `classify_error()`: Categorize error types
     - `suggest_recovery()`: Recovery suggestions
     - `format_error_report()`: Structured error reporting
     - `format_orchestrate_agent_failure()`: Orchestrate-specific error formatting
     - `format_orchestrate_test_failure()`: Test failure formatting
     - `handle_partial_failure()`: Partial failure processing

2. **Checkpoint Utilities** (orchestrate.md:252, 256, 262)
   - Sources: `.claude/lib/checkpoint-utils.sh`
   - Functions used:
     - `save_checkpoint()`: Workflow state persistence
     - `restore_checkpoint()`: Resume from checkpoint
     - `validate_checkpoint()`: Checkpoint validation
     - `checkpoint_increment_replan()`: Replan counter management

3. **Unified Logger** (referenced in error-handling.sh:145-147)
   - Test failure pattern logging: `log_test_failure_pattern()`
   - Adaptive planning triggers: `log_trigger_evaluation()`
   - Log directory: `.claude/data/logs/adaptive-planning.log`

4. **Error Context Preservation** (error-handling.sh:343-380)
   - `log_error_context()`: Structured error logs with context
   - Storage: `.claude/data/logs/error_*.log`
   - Includes: error_type, location, message, context_data, stack_trace

#### /supervise Utility Integration

**Zero Utility Integration**

1. **No Error Handling Library** (supervise.md - no error-handling.sh references)
   - No retry functions
   - No error classification
   - No recovery suggestions
   - No structured error reporting

2. **No Checkpoint Utilities** (supervise.md - no checkpoint-utils.sh references)
   - No state persistence
   - No resume capability
   - No checkpoint validation

3. **Bash-Only Verification** (supervise.md:34, 330)
   - Uses Bash tool for file verification: `ls`, `grep`, `wc`
   - Inline verification logic (not library functions)
   - Simple existence and size checks

### Tests and Validation

#### /orchestrate Test Failure Handling

1. **Test Failure ≠ Error** (orchestrate.md:284-285)
   - Test failures enter debugging loop (max 3 iterations)
   - NOT treated as workflow errors
   - Checkpoint saved with tests_passing: false

2. **Checkpoint Safe Resume Checks** (checkpoint-utils.sh:688-698)
   - `tests_passing` field in checkpoint
   - Auto-resume blocked if tests_passing == false
   - Reason: "Tests failing in last run" (checkpoint-utils.sh:765-767)

3. **Debug Iteration Control** (orchestrate.md:2150, 2498)
   - workflow_state.debug_iteration: 0-3
   - Iteration < 3: Retry with fixes from debug report
   - Iteration ≥ 3: Escalate to user for manual intervention

4. **Test Failure Pattern Detection** (unified-logger.sh:189-210)
   - `log_test_failure_pattern()`: Track consecutive failures
   - Triggers adaptive replanning when pattern detected
   - 2+ consecutive failures in same phase → missing prerequisites

#### /supervise Test Failure Handling

**Not Applicable**

- /supervise does not execute tests
- Focuses on artifact creation verification only
- Test execution would be delegated to implementation agents
- No test failure recovery logic

## Recommendations

### 1. **Hybrid Error Handling Approach for /supervise**

**Problem**: /supervise's fail-fast approach works well for simple workflows but lacks resilience for transient failures (network timeouts, temporary file locks).

**Recommendation**: Add LIMITED retry logic for transient errors only:

```bash
# Add to /supervise
source "$UTILS_DIR/error-handling.sh"

# Classify error before terminating
error_type=$(classify_error "$agent_output")

if [ "$error_type" == "transient" ]; then
  # Single retry for transient errors only
  echo "⚠️  Transient error detected. Retrying once..."
  # Retry agent invocation
else
  # Maintain fail-fast for permanent/fatal errors
  echo "ERROR: Agent failed to create report file."
  echo "Workflow TERMINATED. Fix agent enforcement and retry."
  exit 1
fi
```

**Benefits**:
- Handles temporary file locks, network hiccups
- Maintains fail-fast philosophy for real errors
- No complexity overhead (single retry, not 3x)
- Uses existing error-handling.sh infrastructure

**Impact**: Low - ~20 lines added, reuses existing utilities

---

### 2. **Lightweight Checkpoint Support for /supervise**

**Problem**: Long /supervise workflows (10+ subagents) lose all progress on interruption or failure.

**Recommendation**: Add OPTIONAL checkpoint creation at major phase boundaries:

```bash
# Add to /supervise (optional flag --enable-checkpoints)
if [ "$ENABLE_CHECKPOINTS" == "true" ]; then
  # Save checkpoint after research phase completes
  save_checkpoint "supervise" "$workflow_desc" '{
    "phase": "research",
    "completed_topics": '"$research_count"',
    "report_paths": '"$(printf '%s\n' "${REPORT_PATHS[@]}" | jq -R . | jq -s .)"'
  }'
fi
```

**Scope**:
- Checkpoints ONLY at phase boundaries (research → planning → implementation)
- NOT within-phase checkpoints (no per-agent state)
- Resume skips completed phases, starts at next incomplete phase
- Maintains stateless philosophy within each phase

**Benefits**:
- Prevents loss of multi-hour research efforts
- Optional feature (default: disabled)
- Minimal state tracking (phase-level only)

**Impact**: Medium - ~100 lines for checkpoint logic, flag handling, resume checks

---

### 3. **Error Context Logging for /supervise**

**Problem**: /supervise error messages lack diagnostic context (workflow description, agent type, phase, failure count).

**Recommendation**: Integrate `log_error_context()` for structured error logging:

```bash
# Add to /supervise error paths
log_error_context \
  "permanent" \
  "$agent_type:$phase" \
  "Agent failed to create file" \
  "{\"workflow\": \"$workflow_desc\", \"agent\": \"$agent_type\", \"phase\": \"$phase\"}"

# Log file: .claude/data/logs/error_20251023_142300.log
# Contains: timestamp, error_type, location, message, full context JSON
```

**Benefits**:
- Post-mortem analysis of failure patterns
- Identifies problematic agent types or workflows
- No runtime impact (logging only)
- Reuses error-handling.sh infrastructure

**Impact**: Low - ~10 lines per error path, no logic changes

---

### 4. **Checkpoint Migration Path for /orchestrate v1.3 → v1.4**

**Problem**: Current checkpoint schema (v1.3) lacks wave execution tracking needed for parallel phase implementation.

**Recommendation**: Add wave-specific fields in checkpoint schema v1.4:

```json
{
  "schema_version": "1.4",
  "wave_execution": {
    "current_wave": 2,
    "total_waves": 3,
    "wave_structure": {"1": [1], "2": [2, 3], "3": [4]},
    "parallel_execution_enabled": true,
    "max_wave_parallelism": 3,
    "wave_results": {
      "1": {"phases": [1], "status": "completed", "duration_ms": 185000},
      "2": {"phases": [2, 3], "status": "in_progress", "parallel": true}
    }
  }
}
```

**Migration Logic** (add to checkpoint-utils.sh:372-374):
```bash
# Migrate from 1.3 to 1.4 (add wave tracking)
if [ "$current_version" = "1.3" ]; then
  jq '. + {
    schema_version: "1.4",
    wave_execution: (.wave_execution // {
      current_wave: 1,
      total_waves: 1,
      wave_structure: {"1": [.current_phase]},
      parallel_execution_enabled: false,
      max_wave_parallelism: 3,
      wave_results: {}
    })
  }' "$checkpoint_file" > "${checkpoint_file}.migrated"

  mv "${checkpoint_file}.migrated" "$checkpoint_file"
fi
```

**Benefits**:
- Enables wave-based resume (resume at wave boundary, not phase)
- Tracks parallel execution state
- Backward compatible (auto-migration)

**Impact**: Medium - checkpoint schema extension, migration logic, wave state tracking

---

### 5. **Unified Error Classification Across Commands**

**Problem**: Error classification patterns exist in error-handling.sh but not consistently used across /orchestrate, /implement, /supervise.

**Recommendation**: Create shared error classification wrapper:

```bash
# Add to .claude/lib/error-handling.sh
# Usage: handle_command_error "$error_output" "$workflow_type" "$phase"
handle_command_error() {
  local error_output="${1:-}"
  local workflow_type="${2:-unknown}"
  local phase="${3:-unknown}"

  # Classify error
  local error_type=$(classify_error "$error_output")
  local specific_type=$(detect_error_type "$error_output")
  local location=$(extract_location "$error_output")

  # Log with context
  log_error_context "$error_type" "$location" "$error_output" \
    "{\"workflow\": \"$workflow_type\", \"phase\": \"$phase\"}"

  # Format report
  format_error_report "$error_type" "$phase" "$location" "$error_output" 1

  # Return classification for caller to decide retry/fail
  echo "$error_type"
}
```

**Usage in Commands**:
```bash
# In /orchestrate, /implement, /supervise
error_type=$(handle_command_error "$agent_output" "orchestrate" "research")

if [ "$error_type" == "transient" ]; then
  # Retry logic
elif [ "$error_type" == "fatal" ]; then
  # User escalation
else
  # Standard error handling
fi
```

**Benefits**:
- Consistent error handling across commands
- Centralized error classification logic
- Unified error logs for cross-command analysis

**Impact**: Low - wrapper function, caller integration in 3 commands

## Related Reports

- [Overview Report](./OVERVIEW.md) - Complete comparison of /orchestrate vs /supervise across all dimensions
- [Core Workflow Report](./001_core_workflow_phases_and_execution_patterns.md) - Phase structure and execution patterns
- [Agent Coordination Report](./002_agent_coordination_and_behavioral_injection.md) - Behavioral injection patterns and agent invocation
- [Performance Features Report](./004_performance_features_and_user_facing_options.md) - User-facing features and optimization

## References

### Error Handling and Recovery
- `/home/benjamin/.config/.claude/lib/error-handling.sh` - Complete error handling library (752 lines)
  - Lines 10-42: `classify_error()` - Error type classification
  - Lines 44-71: `suggest_recovery()` - Recovery suggestions
  - Lines 77-128: `detect_error_type()` - Specific error detection
  - Lines 147-224: `generate_suggestions()` - Error-specific guidance
  - Lines 230-260: `retry_with_backoff()` - Exponential backoff retry
  - Lines 262-304: `retry_with_timeout()` - Timeout extension logic
  - Lines 306-338: `retry_with_fallback()` - Reduced toolset retry
  - Lines 343-380: `log_error_context()` - Structured error logging
  - Lines 384-413: `escalate_to_user()` - Interactive error escalation
  - Lines 415-473: `escalate_to_user_parallel()` - Parallel operation escalation
  - Lines 507-528: `format_error_report()` - Formatted error reporting
  - Lines 532-604: `handle_partial_failure()` - Partial failure processing
  - Lines 625-667: `format_orchestrate_agent_failure()` - Orchestrate agent failures
  - Lines 669-709: `format_orchestrate_test_failure()` - Orchestrate test failures
  - Lines 711-729: `format_orchestrate_phase_context()` - Phase context formatting

- `/home/benjamin/.config/.claude/commands/shared/error-handling.md` - High-level error patterns (17 lines)
- `/home/benjamin/.config/.claude/commands/shared/error-recovery.md` - Recovery pattern documentation (22 lines)

### Checkpoint and State Management
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` - Checkpoint utilities (824 lines)
  - Lines 23-26: Checkpoint schema version 1.3
  - Lines 54-172: `save_checkpoint()` - Save workflow state
  - Lines 174-230: `restore_checkpoint()` - Load checkpoint
  - Lines 232-278: `validate_checkpoint()` - Structure validation
  - Lines 280-375: `migrate_checkpoint_format()` - Schema migration (1.0 → 1.3)
  - Lines 377-396: `checkpoint_get_field()` - Field extraction
  - Lines 398-428: `checkpoint_set_field()` - Field updates
  - Lines 434-472: `checkpoint_increment_replan()` - Replan counter tracking
  - Lines 500-553: `save_parallel_operation_checkpoint()` - Parallel ops checkpoint
  - Lines 555-597: `restore_from_checkpoint()` - Rollback restoration
  - Lines 599-659: `validate_checkpoint_integrity()` - Integrity checks
  - Lines 665-732: `check_safe_resume_conditions()` - Auto-resume safety checks
  - Lines 734-806: `get_skip_reason()` - Human-readable skip reasons

- `/home/benjamin/.config/.claude/lib/checkpoint-manager.sh` - Implementation-specific checkpoint manager (100+ lines)
  - Lines 23-27: Context thresholds (70% triggers checkpoint)
  - Lines 36-100: `create_implementation_checkpoint()` - Phase-level checkpoints

### Command-Specific Integration
- `/home/benjamin/.config/.claude/commands/orchestrate.md` - Orchestrate command (5000+ lines)
  - Lines 211-228: Checkpoint resume detection
  - Lines 236-295: Utility initialization and integration
  - Lines 516-544: Topic directory creation fallback
  - Lines 857-1058: Research phase auto-retry with fallback
  - Lines 1198-1227: Overview report fallback
  - Lines 1515-1783: Planning phase auto-retry
  - Lines 2150-2611: Debug iteration loop
  - Lines 3319-3322: Checkpoint state extraction

- `/home/benjamin/.config/.claude/commands/supervise.md` - Supervise command (1500+ lines)
  - Lines 15, 330, 1490: Verification checkpoint references
  - Lines 163, 1475: Zero fallback philosophy
  - Lines 245-260: Fail-fast error handling
  - Lines 685-688: Verification failure termination

### Supporting Utilities
- `/home/benjamin/.config/.claude/lib/unified-logger.sh` - Adaptive planning logger
  - Lines 147-210: `log_test_failure_pattern()` - Test failure tracking
  - Lines 405-424: Test failure trigger statistics

- `/home/benjamin/.config/.claude/lib/metadata-extraction.sh` - Artifact metadata extraction
  - Lines 195-235: Test status extraction from summaries

- `/home/benjamin/.config/.claude/lib/artifact-operations-legacy.sh` - Legacy artifact operations
  - Lines 2073-2142: Artifact metadata with tests_passing field
