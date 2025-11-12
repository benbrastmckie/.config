# Multi-Agent Orchestration Error Handling

## Metadata
- **Date**: 2025-11-09
- **Agent**: research-specialist
- **Topic**: Multi-Agent Orchestration Error Handling
- **Report Type**: codebase analysis
- **Overview Report**: [Coordinate Orchestration Best Practices Overview](OVERVIEW.md)
- **Related Implementation Plan**: [Fix coordinate.md Bash History Expansion Errors](../../../620_fix_coordinate_bash_history_expansion_errors/plans/001_coordinate_history_expansion_fix.md)

## Executive Summary

Multi-agent orchestration in the /coordinate command implements comprehensive error handling through five key mechanisms: fail-fast validation with mandatory checkpoints, state machine-based recovery with atomic transitions, context preservation across agent boundaries using metadata extraction, hierarchical error propagation through supervisor agents, and graceful degradation patterns for partial failures. The architecture achieves 100% file creation reliability while maintaining <30% context usage through explicit error boundaries between orchestrator and subagents.

## Findings

### 1. Error Handling Patterns: Orchestrator vs Subagents

The /coordinate command establishes clear error handling boundaries between orchestrator and subagent responsibilities:

**Orchestrator Error Handling** (`.claude/commands/coordinate.md`):
- **Line 152-192**: `handle_state_error()` function provides state-aware error handling with retry tracking
- **Line 169-170**: Errors logged to workflow state for resume capability (`FAILED_STATE`, `LAST_ERROR`)
- **Line 173-178**: Retry counter implementation prevents infinite loops (max 2 retries per state using `eval` for indirect variable expansion)
- **Line 180-190**: User escalation when retry limit exceeded with diagnostic context

**Subagent Error Handling** (`.claude/agents/research-specialist.md`):
- **Lines 261-320**: Comprehensive retry policy for network, file access, and search timeouts
- **Lines 267-276**: Network errors: 3 retries with exponential backoff (1s, 2s, 4s)
- **Lines 272-276**: File access errors: 2 retries with 500ms delay
- **Lines 278-283**: Search timeouts: 1 retry with adjusted scope
- **Lines 279-295**: Fallback strategies preserve partial results with documented limitations

**Key Architectural Principle**:
Orchestrators handle workflow-level errors (state transitions, agent delegation failures), while subagents handle operation-level errors (network, file I/O, tool timeouts). This separation prevents error handling logic duplication and maintains clear responsibility boundaries.

### 2. Fail-Fast vs Graceful Degradation Strategies

The codebase implements a hybrid approach combining fail-fast orchestration with graceful degradation at agent level:

**Fail-Fast at Orchestrator Level** (`.claude/commands/coordinate.md`):
- **Lines 40-95**: Strict validation of library sourcing and state machine initialization
- **Lines 47-50, 53-57**: Library loading fails immediately with diagnostic paths on error
- **Lines 113-114**: TOPIC_PATH validation with explicit bug attribution message
- **Lines 354-357, 383-386**: Mandatory verification checkpoints with zero tolerance for agent failures
- **Lines 456-460**: File creation verification is binary (success/failure) with no partial acceptance

**Graceful Degradation at Agent Level** (`.claude/lib/error-handling.sh`):
- **Lines 476-501**: `try_with_fallback()` function provides primary/fallback execution patterns
- **Lines 534-604**: `handle_partial_failure()` processes mixed success/failure results in parallel operations
- **Lines 566-573**: Explicit `can_continue: true` flag when ≥1 operation succeeds
- **Lines 577-582**: Failed operations reported with structured error details while workflow continues
- **Lines 598-600**: `requires_retry` flag signals orchestrator to retry failed operations

**Research Agent Graceful Degradation** (`.claude/agents/research-specialist.md`):
- **Lines 296-302**: Web search failure fallback to codebase-only research
- **Lines 286-290**: Grep timeout fallback to Glob + targeted Read pattern
- **Lines 292-295**: Complex search simplification with incremental result combination
- **Lines 297-302**: Partial results documented with confidence levels and manual investigation suggestions

**Industry Best Practices Alignment** (Web Research, 2025):
- Fail-fast for configuration/setup errors (prevents cascading failures)
- Graceful degradation for runtime operations (agents fail, systems handle it)
- Always set maxIterations limits to prevent infinite loops (coordinate implements 2-retry limit per state)
- Circuit breakers prevent cascading failures (retry counters serve this role)

### 3. Context Preservation Across Agent Boundaries

Context preservation uses three complementary strategies to maintain <30% context usage:

**Metadata Extraction Pattern** (`.claude/lib/metadata-extraction.sh`):
- Extracts title + 50-word summary from reports (99% context reduction: 5,000 tokens → 50 tokens)
- Functions: `extract_report_metadata()`, `extract_plan_metadata()`, `load_metadata_on_demand()`
- Caching prevents repeated file reads across phases

**Workflow State Persistence** (`.claude/lib/state-persistence.sh`, `.claude/commands/coordinate.md`):
- **Lines 59-64**: GitHub Actions-style state file pattern for workflow variables
- **Lines 118, 392**: Critical paths saved to state file (`TOPIC_PATH`, `REPORT_PATHS_JSON`)
- **Lines 139-143**: Context preservation structure in checkpoint schema v2.0:
  ```json
  {
    "pruning_log": [],
    "artifact_metadata_cache": {},
    "subagent_output_references": []
  }
  ```
- Selective persistence (7 critical items, 70% of state) achieves 67% performance improvement (6ms → 2ms)

**Forward Message Pattern** (documented in behavioral injection pattern):
- Agents return structured metadata (`REPORT_CREATED: [path]`), not full summaries
- Orchestrator reads metadata on-demand, never full file content
- Subagent outputs referenced by path, not duplicated in context

**State Machine Context Management** (`.claude/lib/workflow-state-machine.sh`):
- **Lines 59-71**: Global state variables minimize context pollution
- **Lines 126-153**: Checkpoint loading preserves state across interruptions
- **Line 150-151**: Completed states array tracks history without full output retention
- State transitions are atomic (lines 200-250) preventing partial state corruption

**Context Pruning After Completion** (`.claude/lib/context-pruning.sh`):
- `prune_subagent_output()`: Clears full outputs after metadata extraction
- `prune_phase_metadata()`: Removes phase data after completion
- `apply_pruning_policy()`: Automatic pruning by workflow type

**Hierarchical Supervision Context Reduction** (`.claude/commands/coordinate.md`):
- **Lines 258-296**: Hierarchical research supervision for ≥4 topics
- **Lines 335-363**: Supervisor checkpoint aggregates metadata (95.6% reduction: 10,000 → 440 tokens)
- Research supervisor returns aggregated summary, not individual report content
- Implementation supervisor coordinates parallel waves with metadata-only status

### 4. Error Propagation and Recovery Mechanisms

Error propagation follows explicit hierarchical patterns with state-based recovery:

**State Machine Error Recovery** (`.claude/lib/workflow-state-machine.sh`):
- **Lines 126-182**: `sm_load()` restores state machine from checkpoint v2.0 format
- **Lines 200-250**: `sm_transition()` validates state transitions against transition table
- **Lines 44-53**: Transition table defines valid next states preventing invalid state changes
- Checkpoint stores `FAILED_STATE` and `LAST_ERROR` for diagnostics on resume

**Atomic State Transitions** (`.claude/commands/coordinate.md`):
- **Lines 169-192**: Two-phase error handling: append state → check retry count → escalate/exit
- **Line 173**: Retry counters isolated per state (`RETRY_COUNT_${current_state}`)
- **Lines 175-176**: Indirect variable expansion using `eval` (safe: variable name constructed from known state)
- State file cleanup on exit (line 61) prevents orphaned state corruption

**Hierarchical Error Propagation** (`.claude/lib/error-handling.sh`):
- **Lines 629-667**: `format_orchestrate_agent_failure()` adds workflow phase context to agent errors
- **Lines 669-709**: `format_orchestrate_test_failure()` propagates test errors with error type classification
- **Lines 711-729**: `format_orchestrate_phase_context()` wraps base errors with orchestration metadata
- Error classification system (lines 12-42): transient, permanent, fatal with recovery suggestions

**Supervisor Error Aggregation** (`.claude/commands/coordinate.md`):
- **Lines 342-357**: Hierarchical mode aggregates supervisor checkpoint errors
- **Lines 368-389**: Flat mode aggregates individual agent failures
- **Lines 354-357, 383-386**: Both paths converge to same verification failure handling
- `VERIFICATION_FAILURES` counter enables partial failure tracking

**Checkpoint-Based Recovery** (`.claude/lib/checkpoint-utils.sh`):
- **Lines 54-186**: `save_checkpoint()` with schema v2.0 including error state fields
- **Lines 116-120**: Error state structure: `last_error`, `retry_count`, `failed_state`
- **Lines 188-250**: `restore_checkpoint()` loads most recent checkpoint for resume
- Wave tracking fields (lines 30-48) enable recovery at wave boundaries for parallel execution

**Recovery Workflow**:
1. Error occurs in subagent (e.g., file creation failure)
2. Orchestrator verification checkpoint detects failure (lines 354-357)
3. `handle_state_error()` logs error to workflow state (lines 169-170)
4. Retry counter incremented for current state (lines 173-178)
5. If retry limit not exceeded, user instructed to re-run command (lines 186-189)
6. On re-run, state machine loads checkpoint and resumes from `FAILED_STATE`

### 5. Best Practices for Debugging Orchestration Failures

The codebase provides comprehensive diagnostic tools and patterns:

**Mandatory Verification Checkpoints** (`.claude/lib/verification-helpers.sh`):
- **Lines 67-120**: `verify_file_created()` function with concise success (✓) and verbose failure diagnostics
- **Lines 74-75**: Single-character success output (90% token reduction at checkpoints)
- **Lines 78-110**: Failure diagnostics include: expected vs found status, directory status, file count, recent files
- **Lines 112-116**: Actionable diagnostic commands for manual investigation

**Bootstrap Diagnostics** (`.claude/docs/guides/orchestration-troubleshooting.md`):
- **Lines 43-146**: Bootstrap failure troubleshooting section with 3 common patterns
- **Lines 56-73**: Library sourcing errors with diagnostic commands (ls, cat, pwd)
- **Lines 86-105**: Function availability checks with API mismatch detection
- **Lines 121-145**: SCRIPT_DIR validation with absolute path solutions

**Agent Delegation Diagnostics** (`.claude/docs/guides/orchestration-troubleshooting.md`):
- **Lines 148-200**: 0% delegation rate detection patterns
- **Lines 159-172**: Anti-pattern validation commands including delegation rate tests
- **Lines 174-199**: Side-by-side comparison of documentation-only YAML blocks (❌) vs imperative invocations (✅)

**State Machine Diagnostics** (`.claude/commands/coordinate.md`):
- **Lines 158-166**: State context display on error (workflow, scope, current state, terminal state)
- **Lines 196-203**: State initialization verification with debug output
- **Lines 218-231**: State verification at phase boundaries with diagnostic exits

**Error Classification and Suggestions** (`.claude/lib/error-handling.sh`):
- **Lines 76-128**: `detect_error_type()` categorizes errors: syntax, test_failure, file_not_found, import_error, null_error, timeout, permission
- **Lines 130-144**: `extract_location()` parses file:line locations from error messages
- **Lines 149-224**: `generate_suggestions()` provides error-type-specific fix commands

**Logging and Observability** (`.claude/lib/unified-logger.sh`, checkpoint-utils.sh):
- Adaptive planning log: `.claude/data/logs/adaptive-planning.log` (10MB max, 5 files retained)
- Checkpoint history: `.claude/data/checkpoints/` with timestamped snapshots
- Error context logging: `log_error_context()` creates structured error logs (lines 347-380 in error-handling.sh)

**Diagnostic Command Patterns**:
```bash
# Check agent delegation rate
grep "PROGRESS:" coordinate_output.log

# Verify file creation
find .claude/specs -name "*.md" -mmin -5

# Check checkpoint state
jq '.state_machine.current_state' .claude/data/checkpoints/coordinate_*.json | tail -1

# Validate agent invocation pattern
./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md

# Check for TODO fallback files (indicates delegation failure)
ls .claude/TODO*.md 2>/dev/null
```

**Production Best Practices** (Web Research + Codebase Patterns):
- Trace every step and handoff (PROGRESS markers in coordinate command)
- Capture prompts, outputs, tools, token/costs (checkpoint metadata)
- Instrument all agent operations (verification checkpoints at every boundary)
- Comprehensive logging across agent boundaries (state file + checkpoint + error logs)
- Durable execution with resume capability (checkpoint-based recovery)
- Validate outputs with structured schemas (verify_file_created checks existence + content)
- Maxmize observability without bloating context (metadata extraction, concise verification)

## Recommendations

### 1. Enforce Clear Error Boundary Separation

**Principle**: Orchestrators handle workflow-level errors, subagents handle operation-level errors.

**Implementation Guidelines**:
- Orchestrator error handling: State transitions, agent delegation failures, verification checkpoint failures, retry limit enforcement
- Subagent error handling: Network timeouts, file I/O errors, tool failures, search timeouts
- Never duplicate error handling logic between orchestrator and subagent layers
- Use structured error metadata (`type`, `message`, `retry_count`, `can_continue`) for cross-boundary error communication

**Anti-Pattern to Avoid**:
```bash
# DON'T: Orchestrator handles file I/O retries (subagent responsibility)
for i in 1 2 3; do
  invoke_agent && break
  sleep 1
done
```

**Recommended Pattern**:
```bash
# DO: Orchestrator delegates to agent with retry policy, handles delegation failure
invoke_agent || handle_state_error "Agent failed after internal retries" 1
```

### 2. Implement Hybrid Error Handling Strategy

**Principle**: Fail-fast for configuration errors, graceful degradation for runtime operations.

**Fail-Fast Checklist** (Bootstrap Phase):
- [ ] Library sourcing failures exit immediately with diagnostic paths
- [ ] Function availability checks exit on missing functions with API documentation reference
- [ ] State machine initialization validates all required variables before transition
- [ ] TOPIC_PATH validation confirms directory creation before agent invocation

**Graceful Degradation Checklist** (Runtime Phase):
- [ ] Partial failure handling allows workflow continuation when ≥50% operations succeed
- [ ] Fallback strategies documented with confidence levels and limitations
- [ ] Retry limits prevent infinite loops (recommended: 2-3 retries max)
- [ ] `can_continue` and `requires_retry` flags enable intelligent workflow branching

**Implementation Example**:
```bash
# Fail-fast: Bootstrap validation
[ -f "$LIB_PATH/state-machine.sh" ] || {
  echo "ERROR: state-machine.sh not found at $LIB_PATH"
  exit 1
}

# Graceful degradation: Parallel operations
RESULT=$(handle_partial_failure "$PARALLEL_RESULTS")
CAN_CONTINUE=$(echo "$RESULT" | jq -r '.can_continue')
if [ "$CAN_CONTINUE" = "true" ]; then
  echo "Proceeding with $(echo "$RESULT" | jq -r '.successful') successful operations"
else
  handle_state_error "All parallel operations failed" 1
fi
```

### 3. Optimize Context Preservation with Metadata Extraction

**Principle**: Pass metadata references, not full content, across agent boundaries.

**Metadata Extraction Pattern**:
```bash
# Extract metadata after agent completes (99% context reduction)
REPORT_METADATA=$(extract_report_metadata "$REPORT_PATH")
TITLE=$(echo "$REPORT_METADATA" | jq -r '.title')
SUMMARY=$(echo "$REPORT_METADATA" | jq -r '.summary')  # 50-word max

# Pass metadata to next agent, not full report
invoke_next_agent "Previous research: $TITLE - $SUMMARY\nFull report: $REPORT_PATH"
```

**Context Preservation Checklist**:
- [ ] Extract metadata immediately after artifact creation (before next phase)
- [ ] Store artifact paths in workflow state, not content
- [ ] Use forward message pattern (return structured metadata, not summaries)
- [ ] Prune completed phase data after metadata extraction
- [ ] Cache metadata to prevent repeated file reads

**Context Budget Targets** (7-phase workflow):
- Phase 0: 500-1,000 tokens (4%)
- Phase 1: 600-1,200 tokens (6% - metadata from 2-4 reports)
- Phase 2: 800-1,200 tokens (5%)
- Phase 3: 1,500-2,000 tokens (8%)
- Phase 4-7: 200-500 tokens each (2% each)
- **Total**: <30% context usage throughout workflow

### 4. Design Hierarchical Error Propagation with State Machine Recovery

**Principle**: Errors propagate up supervision hierarchy with increasing context; recovery uses checkpoint-based state restoration.

**Error Propagation Layers**:
1. **Subagent Layer**: Operation-level errors (file I/O, network, tool failures)
   - Return structured error: `{"status": "error", "type": "transient", "message": "...", "retry_count": 2}`
2. **Orchestrator Layer**: Workflow-level errors (verification failures, delegation failures)
   - Add state context: `{"state": "research", "phase": 1, "workflow": "...", "error": {...}}`
3. **Supervisor Layer** (if hierarchical): Aggregate subagent errors
   - Summarize: `{"failed_agents": 2, "successful_agents": 3, "can_continue": true, "errors": [...]}`

**State Machine Recovery Pattern**:
```bash
# On error: Save state with error context
handle_state_error() {
  append_workflow_state "FAILED_STATE" "$CURRENT_STATE"
  append_workflow_state "LAST_ERROR" "$error_message"

  RETRY_COUNT_VAR="RETRY_COUNT_${CURRENT_STATE}"
  RETRY_COUNT=$(eval echo "\${${RETRY_COUNT_VAR}:-0}")
  RETRY_COUNT=$((RETRY_COUNT + 1))
  append_workflow_state "$RETRY_COUNT_VAR" "$RETRY_COUNT"

  if [ $RETRY_COUNT -ge 2 ]; then
    echo "Max retries reached. Workflow cannot proceed."
    exit 1
  else
    echo "Retry $RETRY_COUNT/2 available. Re-run command to resume."
    exit 1
  fi
}

# On resume: Load checkpoint and retry from failed state
load_workflow_state "coordinate_$$"
if [ -n "${FAILED_STATE:-}" ]; then
  sm_transition "$FAILED_STATE"  # Resume from failure point
fi
```

**Recovery Best Practices**:
- Checkpoints saved at state boundaries (before transitions)
- Atomic state transitions prevent partial state corruption
- Retry counters isolated per state to prevent cross-state interference
- Wave boundaries in parallel execution enable recovery without re-executing completed waves

### 5. Build Comprehensive Diagnostic Tooling

**Principle**: Maximize observability while minimizing context bloat through concise success signals and verbose failure diagnostics.

**Verification Pattern**:
```bash
# Concise success (✓), verbose failure (38-line diagnostic)
if verify_file_created "$REPORT_PATH" "Research report" "Phase 1"; then
  echo " Report verified"  # Single line on success
else
  # Verbose diagnostic already emitted by verify_file_created()
  handle_state_error "Report verification failed" 1
fi
```

**Diagnostic Tooling Checklist**:
- [ ] Verification functions emit single-character success (✓) for 90% token reduction
- [ ] Failure diagnostics include expected vs found, directory status, recent files, fix commands
- [ ] Error classification system categorizes errors (syntax, test_failure, file_not_found, etc.)
- [ ] Structured error logs with context: `log_error_context(type, location, message, context_json)`
- [ ] PROGRESS markers for external monitoring without context pollution
- [ ] Checkpoint history for workflow replay and debugging

**Observability Best Practices**:
- Trace every agent invocation with entry/exit markers
- Capture metadata at every phase boundary (status, duration, artifacts created)
- Log errors with full context but return concise error codes
- Provide diagnostic commands in error messages for user self-service
- Rotate logs to prevent disk exhaustion (10MB max, 5 files retained)

### 6. Validate Agent Invocation Patterns

**Critical Requirement**: Prevent documentation-only YAML blocks that cause 0% delegation rate.

**Anti-Pattern Detector**:
```bash
# Run validation before committing orchestration commands
./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md
```

**Correct Invocation Pattern**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: Authentication Patterns
    - Report Path: /absolute/path/to/report.md
    - Project Standards: /absolute/path/to/CLAUDE.md

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [exact absolute path]
  "
}
```

**Validation Checklist**:
- [ ] Imperative instruction present (`**EXECUTE NOW**: USE the Task tool`)
- [ ] No code block wrappers around Task invocations (no ` ```yaml ` fences)
- [ ] Behavioral file reference explicit (`.claude/agents/[agent-name].md`)
- [ ] Absolute paths provided for all artifacts
- [ ] Completion signal format documented (`REPORT_CREATED: [path]`)
- [ ] All verification checkpoints use fail-fast pattern (exit on failure)

**Testing**:
```bash
# Integration test for delegation rate
./.claude/tests/test_orchestration_commands.sh

# Expected: >90% delegation rate for all orchestration commands
```

## References

### Core Files Analyzed

**Commands**:
- `/home/benjamin/.config/.claude/commands/coordinate.md` (Lines 1-800+) - State machine orchestration, error handling, verification checkpoints

**Libraries**:
- `/home/benjamin/.config/.claude/lib/error-handling.sh` (Lines 1-751) - Error classification, retry logic, escalation, orchestrate-specific error formatting
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (Lines 1-150+) - State machine abstraction, transition validation, checkpoint integration
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` (Lines 1-200+) - Checkpoint save/restore with schema v2.0, wave tracking support
- `/home/benjamin/.config/.claude/lib/verification-helpers.sh` (Lines 1-124) - Concise verification pattern with 90% token reduction
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` - GitHub Actions-style workflow state files

**Agents**:
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (Lines 1-671) - Subagent error handling, retry policies, graceful degradation patterns

**Documentation**:
- `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md` (Lines 1-200+) - Architecture, workflow types, tool constraints
- `/home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md` (Lines 1-300+) - Unified 7-phase framework, performance targets, verification patterns
- `/home/benjamin/.config/.claude/docs/guides/orchestration-troubleshooting.md` (Lines 1-200+) - Bootstrap failures, agent delegation issues, diagnostic procedures
- `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md` - State machine design principles

### Web Research Sources

- **Azure Architecture Center** (Microsoft Learn, 2025): "AI Agent Orchestration Patterns"
- **Skywork AI Blog** (2025): "Best Practices for Multi-Agent Orchestration and Reliable Handoffs"
- **Manus AI Newsletter** (2025): "The Complete Guide to AI Multi-Agent Orchestration"
- **Botpress Blog** (2025): "AI Agent Orchestration: How To Coordinate Multiple AI Agents"
- **Fixtergeek** (2025): "Agent Workflow Patterns: The Essential Guide to AI Orchestration in 2025"
- **LangChain Blog** (2025): "How and when to build multi-agent systems"
- **Latenode** (2025): "LangGraph Multi-Agent Orchestration: Complete Framework Guide + Architecture Analysis 2025"

### Key Patterns Referenced

- **Behavioral Injection Pattern** (`.claude/docs/concepts/patterns/behavioral-injection.md`) - Direct agent invocation via Task tool with behavioral file injection
- **Metadata Extraction Pattern** (`.claude/docs/concepts/patterns/metadata-extraction.md`) - 99% context reduction through title + 50-word summary
- **Forward Message Pattern** (`.claude/docs/concepts/patterns/forward-message.md`) - Pass metadata references, not full content
- **Verification and Fallback Pattern** (`.claude/docs/concepts/patterns/verification-fallback.md`) - Mandatory checkpoints with fail-fast philosophy
- **Checkpoint Recovery Pattern** (`.claude/docs/concepts/patterns/checkpoint-recovery.md`) - State preservation for resumable workflows
- **Hierarchical Supervision Pattern** (`.claude/docs/concepts/patterns/hierarchical-supervision.md`) - Recursive supervision with metadata aggregation
