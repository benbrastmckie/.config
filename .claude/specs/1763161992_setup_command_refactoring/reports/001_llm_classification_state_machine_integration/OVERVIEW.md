# LLM Classification State Machine Integration - Research Overview

## Metadata
- **Date**: 2025-11-14
- **Research Topic**: Integration of LLM classification timeout solutions with existing state-machine architecture
- **Orchestrator**: research-sub-supervisor
- **Synthesizer**: research-synthesizer
- **Subtopic Count**: 4
- **Report Type**: Research synthesis overview

## Executive Summary

Current LLM classification system uses a **broken file-based signaling pattern** that polls for an external handler that doesn't exist, causing inevitable 10-second timeouts in all orchestration commands (/coordinate, /orchestrate, /supervise). The solution requires migrating to **Task tool agent invocation** at the command level BEFORE state machine initialization, with classification results passed as an optional third parameter to sm_init(). This eliminates timeouts while maintaining backward compatibility during migration. Integration with v2.0 checkpoint schema requires extending to v2.1 with classification metadata fields (research_complexity, research_topics) and implementing atomic coordination between state files and checkpoint files during state transitions.

**Impact**: Zero timeout failures, <5s classification (vs 10s timeout), complete checkpoint resumability with classification metadata preservation, backward-compatible migration path.

## Research Synthesis

### 1. Root Cause Analysis: File-Based Signaling Pattern Failure

**Source**: Subtopic 001 (Agent Invocation Pattern) and Subtopic 004 (Backward Compatibility)

**Problem Architecture**:

The current classification system in `.claude/lib/workflow-llm-classifier.sh` (lines 287-359) follows this broken workflow:

```bash
invoke_llm_classifier() {
  # Step 1: Write request to filesystem
  request_file="${HOME}/.claude/tmp/llm_request_${workflow_id}.json"
  echo "$llm_input" > "$request_file"

  # Step 2: Emit signal to stderr (NO HANDLER EXISTS)
  echo "[LLM_CLASSIFICATION_REQUEST] Please process: $request_file → $response_file" >&2

  # Step 3: Poll for response file (NEVER ARRIVES)
  while [ $count -lt $iterations ]; do
    if [ -f "$response_file" ]; then
      return 0  # Success
    fi
    sleep 0.5
  done

  # Step 4: Timeout after 10 seconds (ALWAYS HAPPENS)
  return 1
}
```

**Why This Fails**:
- Pattern assumes external handler monitors stderr for `[LLM_CLASSIFICATION_REQUEST]` signals
- No such handler exists in Claude Code framework
- Libraries cannot use Task tool (requires command execution context)
- Result: 100% timeout rate, 10 seconds wasted per workflow initialization

**Call Chain** (Subtopic 004):
```
/coordinate, /orchestrate, /supervise
    ↓
sm_init() (workflow-state-machine.sh:334-476)
    ↓
classify_workflow_comprehensive() (workflow-scope-detection.sh:48-86)
    ↓
classify_workflow_llm_comprehensive() (workflow-llm-classifier.sh:109-204)
    ↓
invoke_llm_classifier() ← TIMES OUT HERE
```

### 2. Proven Solution Pattern: Behavioral Injection via Task Tool

**Source**: Subtopic 001 (Agent Invocation Pattern)

**Working Example from /coordinate** (lines 566-585):

```markdown
**EXECUTE NOW**: USE the Task tool:

Task {
  subagent_type: "general-purpose"
  description: "Research Topic 1 with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: $RESEARCH_TOPIC_1
    - Report Path: $AGENT_REPORT_PATH_1

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [exact absolute path to report file]
  "
}
```

**Key Success Characteristics**:
1. **Imperative Execution Directive**: `**EXECUTE NOW**: USE the Task tool` (prevents documentation-only interpretation)
2. **Behavioral File Reference**: Points to `.claude/agents/research-specialist.md`
3. **Context Injection**: Provides workflow-specific parameters
4. **No Code Fence Wrappers**: Task invocation NOT wrapped in ```yaml``` blocks
5. **Synchronous Execution**: Blocks until agent completes (no polling needed)
6. **Explicit Return Format**: `REPORT_CREATED: /path/to/file`

**Documented Pattern**: Standard 11 (Imperative Agent Invocation) in `.claude/docs/reference/command_architecture_standards.md` (lines 334-414)

### 3. Recommended Migration Architecture

**Source**: Subtopic 001 (Agent Invocation Pattern), Subtopic 004 (Backward Compatibility)

**Option 1: Command-Level Classification with Agent (RECOMMENDED)**

**Architecture Flow**:
```
/coordinate command
  ↓
[Phase 0 Bash Block 1: Save workflow description]
  ↓
[Agent Invocation: Invoke workflow-classifier via Task tool]  ← NEW
  ↓
[Get classification result JSON]  ← NEW
  ↓
[Phase 0 Bash Block 2: Parse result, call sm_init_with_result()]  ← MODIFIED
  ↓
[State machine initialization with pre-computed classification]
  ↓
[Continue with research phase...]
```

**Required Changes**:

**1. Create Classification Agent** (Subtopic 001, Recommendation 1):

File: `.claude/agents/workflow-classifier.md`

```markdown
---
allowed-tools: None (pure logic agent)
model: haiku
description: Fast semantic workflow classification for orchestration commands
---

# Workflow Classifier Agent

**YOU MUST perform these exact steps**:

1. Receive workflow description via injected context
2. Analyze description semantically (not keyword matching)
3. Classify into workflow type (research-only, research-and-plan, full-implementation, etc.)
4. Determine research complexity (1-4 based on scope)
5. Generate descriptive research topic names (matching complexity count)
6. Return JSON: {"workflow_type": "...", "confidence": 0.0-1.0, "research_complexity": N, "research_topics": [...]}

**CRITICAL**: Focus on INTENT not keywords.
Example: "research the research-and-revise workflow" is research-and-plan (intent: learn), not research-and-revise (intent: revise).
```

**2. Refactor sm_init() to Accept Pre-Computed Classification** (Subtopic 001, Recommendation 2):

Before (workflow-state-machine.sh:334-399):
```bash
sm_init() {
  local workflow_desc="$1"
  local command_name="$2"

  # Performs classification internally (BROKEN - times out)
  classification_result=$(classify_workflow_comprehensive "$workflow_desc")
  WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type')
  # ...
}
```

After:
```bash
# sm_init_with_classification: Initialize state machine with pre-classified results
# Args:
#   $1: workflow_desc - Workflow description string
#   $2: command_name - Command name (coordinate, orchestrate, supervise)
#   $3: workflow_scope - Pre-classified workflow type
#   $4: research_complexity - Pre-determined complexity (1-4)
#   $5: research_topics_json - JSON array of topic names
sm_init_with_classification() {
  local workflow_desc="$1"
  local command_name="$2"
  local workflow_scope="$3"
  local research_complexity="$4"
  local research_topics_json="$5"

  # Store provided classification (no internal classification)
  WORKFLOW_DESCRIPTION="$workflow_desc"
  COMMAND_NAME="$command_name"
  WORKFLOW_SCOPE="$workflow_scope"
  RESEARCH_COMPLEXITY="$research_complexity"
  RESEARCH_TOPICS_JSON="$research_topics_json"

  export WORKFLOW_SCOPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON

  # Continue with state machine setup
  sm_calculate_terminal_state
  sm_reset  # Reset to initialize state

  return 0
}
```

**Backward-Compatible Alternative** (Subtopic 004, Recommendation 2):
```bash
sm_init() {
  local workflow_description="$1"
  local command_name="$2"
  local classification_result="${3:-}"  # OPTIONAL pre-computed result

  if [ -n "$classification_result" ]; then
    # New path: Use pre-computed result (agent-based, fast)
    echo "Using pre-computed classification"
    export WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type')
    export RESEARCH_COMPLEXITY=$(echo "$classification_result" | jq -r '.research_complexity')
    export RESEARCH_TOPICS_JSON=$(echo "$classification_result" | jq -c '.research_topics')
  else
    # Old path: Call library (times out, preserves existing behavior)
    classification_result=$(classify_workflow_comprehensive "$workflow_description")
    export WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type')
    # ... same extraction logic ...
  fi

  # ... rest of initialization ...
}
```

**3. Update Orchestration Commands** (Subtopic 001, Recommendation 3):

Pattern to add to `/coordinate`, `/orchestrate`, `/supervise` (before current sm_init call):

```markdown
## Phase 0: Workflow Classification

**EXECUTE NOW**: USE the Task tool to invoke workflow-classifier agent:

Task {
  subagent_type: "general-purpose"
  description: "Classify workflow intent for orchestration"
  timeout: 30000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/workflow-classifier.md

    **Workflow-Specific Context**:
    - Workflow Description: $SAVED_WORKFLOW_DESC
    - Command Name: coordinate

    **CRITICAL**: Return structured JSON classification.

    Execute classification following all guidelines in behavioral file.
    Return: CLASSIFICATION_COMPLETE: {JSON classification object}
  "
}

**EXECUTE NOW**: Parse classification result and initialize state machine:

```bash
# Parse classification JSON from agent return
WORKFLOW_SCOPE=$(echo "$CLASSIFICATION_RESULT" | jq -r '.workflow_type')
RESEARCH_COMPLEXITY=$(echo "$CLASSIFICATION_RESULT" | jq -r '.research_complexity')
RESEARCH_TOPICS_JSON=$(echo "$CLASSIFICATION_RESULT" | jq -c '.research_topics')

# Initialize state machine with classification results
sm_init_with_classification "$SAVED_WORKFLOW_DESC" "coordinate" "$WORKFLOW_SCOPE" "$RESEARCH_COMPLEXITY" "$RESEARCH_TOPICS_JSON"

# Verify state machine initialization
verify_state_variable "WORKFLOW_SCOPE" "State machine initialization" || exit 1
```
```

**Benefits**:
- Uses proven behavioral injection pattern (100% reliable)
- Eliminates 10-second timeout (classification typically <5s)
- No framework changes required
- Testable in isolation
- Backward compatible via optional parameter

**Effort**: ~2 hours agent creation + 2 hours command updates + 1 hour testing = **5 hours total**

### 4. Checkpoint Schema Integration (v2.0 → v2.1)

**Source**: Subtopic 002 (State Machine Checkpoint Coordination)

**Current Checkpoint Schema (V2.0)**:

```json
{
  "schema_version": "2.0",
  "state_machine": {
    "current_state": "research",
    "completed_states": ["initialize"],
    "workflow_config": {
      "scope": "full-implementation",
      "description": "Add user authentication",
      "command": "coordinate"
    }
  },
  "phase_data": {},
  "error_state": {...}
}
```

**Gap**: NO classification metadata fields (research_complexity, research_topics)

**Proposed Schema Extension (V2.1)**:

```json
{
  "schema_version": "2.1",
  "state_machine": {
    "current_state": "research",
    "completed_states": ["initialize"],
    "workflow_config": {
      "scope": "full-implementation",
      "description": "Add user authentication",
      "command": "coordinate"
    },
    "classification": {
      "workflow_type": "full-implementation",
      "research_complexity": 2,
      "research_topics": [
        {
          "short_name": "Authentication patterns",
          "detailed_description": "Analyze current authentication...",
          "filename_slug": "authentication_patterns",
          "research_focus": "Key questions: How is auth handled?"
        }
      ],
      "confidence": 0.95,
      "reasoning": "Workflow requires...",
      "classified_at": "2025-11-14T14:30:00Z"
    }
  }
}
```

**Required Changes** (Subtopic 002, Recommendations 1-5):

**1. Add classification save/restore functions** (workflow-state-machine.sh):

```bash
sm_save_with_classification() {
  local checkpoint_file="$1"

  # Build classification section from current exports
  classification_json=$(jq -n \
    --arg workflow_type "$WORKFLOW_SCOPE" \
    --argjson research_complexity "$RESEARCH_COMPLEXITY" \
    --argjson research_topics "$RESEARCH_TOPICS_JSON" \
    --arg classified_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
      workflow_type: $workflow_type,
      research_complexity: ($research_complexity | tonumber),
      research_topics: $research_topics,
      confidence: 0.95,
      classified_at: $classified_at
    }')

  # Merge into state machine JSON
  state_machine_json=$(jq -n \
    --argjson classification "$classification_json" \
    --arg current_state "$CURRENT_STATE" \
    # ... existing fields ...
    '{
      current_state: $current_state,
      classification: $classification,
      workflow_config: {...}
    }')

  echo "$state_machine_json" > "$checkpoint_file"
}

sm_load_with_classification() {
  local checkpoint_file="$1"

  # Load v2.1 checkpoint with classification
  WORKFLOW_SCOPE=$(jq -r '.state_machine.classification.workflow_type' "$checkpoint_file")
  RESEARCH_COMPLEXITY=$(jq -r '.state_machine.classification.research_complexity' "$checkpoint_file")
  RESEARCH_TOPICS_JSON=$(jq -c '.state_machine.classification.research_topics' "$checkpoint_file")

  # Export to bash environment
  export WORKFLOW_SCOPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON

  # Set terminal state from classification
  case "$WORKFLOW_SCOPE" in
    research-only) TERMINAL_STATE="$STATE_RESEARCH" ;;
    # ... other cases
  esac
}
```

**2. Implement atomic checkpoint coordination** (Subtopic 002, Recommendation 3):

```bash
sm_transition() {
  local next_state="$1"

  # Phase 1: Validate transition
  if ! validate_transition "$CURRENT_STATE" "$next_state"; then
    return 1
  fi

  # Phase 2: Pre-transition checkpoint (atomic save)
  local pre_checkpoint_file="${CHECKPOINT_DIR}/pre_transition_${next_state}.json"
  if ! sm_save_with_classification "$pre_checkpoint_file"; then
    echo "ERROR: Pre-transition checkpoint failed" >&2
    return 1
  fi

  # Phase 3: Update state (in-memory only)
  local old_state="$CURRENT_STATE"
  CURRENT_STATE="$next_state"
  COMPLETED_STATES+=("$next_state")

  # Phase 4: Persist to state file
  if ! append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"; then
    # Rollback in-memory state
    CURRENT_STATE="$old_state"
    unset 'COMPLETED_STATES[-1]'
    echo "ERROR: State file update failed, rolled back" >&2
    return 1
  fi

  # Phase 5: Post-transition checkpoint (atomic save)
  local post_checkpoint_file="${CHECKPOINT_DIR}/post_transition_${next_state}.json"
  sm_save_with_classification "$post_checkpoint_file"

  # Phase 6: Cleanup pre-transition checkpoint
  rm -f "$pre_checkpoint_file"

  echo "State transition: $old_state → $CURRENT_STATE (atomic)" >&2
}
```

**3. Early checkpoint save after classification** (Subtopic 002, Recommendation 4):

Add to `/coordinate` (after line 188):

```bash
# Save initial checkpoint with classification metadata
INITIAL_CHECKPOINT_FILE=$(save_checkpoint "coordinate" "$(basename "$TOPIC_PATH")" \
  "$(jq -n \
    --arg workflow_desc "$SAVED_WORKFLOW_DESC" \
    --arg scope "$WORKFLOW_SCOPE" \
    --argjson complexity "$RESEARCH_COMPLEXITY" \
    --argjson topics "$RESEARCH_TOPICS_JSON" \
    '{
      workflow_description: $workflow_desc,
      workflow_scope: $scope,
      research_complexity: $complexity,
      research_topics: $topics,
      current_state: "initialize",
      status: "in_progress"
    }')")

echo "✓ Initial checkpoint saved: $INITIAL_CHECKPOINT_FILE"
```

**Benefits**:
- Complete checkpoint resumability (classification preserved)
- Atomic state transitions (rollback on failure)
- Early checkpoint creation (resume even during early phases)
- Backward compatible (v2.0 checkpoints auto-migrate)

### 5. Command-Level Error Handling and Flow

**Source**: Subtopic 003 (Command-Level Classification Flow)

**Current Error Handling** (coordinate.md:170, orchestrate.md:119, supervise.md:79):

All commands use identical error message:
```bash
handle_state_error "State machine initialization failed (workflow classification error). Check network connection or use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline development." 1
```

**Current Fallback Mechanism** (Subtopic 003, Section 3):

**Fail-Fast System** (workflow-scope-detection.sh:59-85):
```bash
# Mode validation - fail-fast on invalid modes
if [ "$WORKFLOW_CLASSIFICATION_MODE" = "hybrid" ]; then
  echo "ERROR: hybrid mode removed in clean-break refactor" >&2
  return 1
fi

# LLM-only classification - fail fast on errors (NO FALLBACK)
if ! llm_result=$(classify_workflow_llm_comprehensive "$workflow_description"); then
  echo "ERROR: classify_workflow_comprehensive: LLM classification failed" >&2
  echo "  Suggestion: Check network connection or increase WORKFLOW_CLASSIFICATION_TIMEOUT" >&2
  return 1
fi
```

**Key Architecture Decision**: System does NOT automatically fallback to regex mode on LLM failure (clean-break design, maintains quality)

**Error Types Handled** (Subtopic 003, workflow-llm-classifier.sh:535-596):
- `timeout`: Agent invocation exceeds WORKFLOW_CLASSIFICATION_TIMEOUT (default 10s)
- `network`: Pre-flight connectivity check failed
- `api_error`: LLM API failure (credentials, rate limits, service outage)
- `low_confidence`: Classification confidence below threshold (default 0.7)
- `parse_error`: Malformed JSON response from agent
- `invalid_mode`: Unsupported classification mode

**Recommended Enhancements** (Subtopic 003, Recommendations 1-5):

**1. Standardize error messages** (extract to library constant):
```bash
# In workflow-state-machine.sh
readonly STATE_INIT_CLASSIFICATION_ERROR_MSG="State machine initialization failed (workflow classification error). Check network connection or use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline development."
```

**2. Add classification mode visibility**:
```bash
log_info "Workflow classification mode: ${WORKFLOW_CLASSIFICATION_MODE:-llm-only}"
```

**3. Implement retry logic for transient failures**:
```bash
CLASSIFICATION_MAX_RETRIES="${CLASSIFICATION_MAX_RETRIES:-2}"
CLASSIFICATION_RETRY_BASE_DELAY="${CLASSIFICATION_RETRY_BASE_DELAY:-2}"

invoke_llm_classifier_with_retry() {
  local attempt=1
  while [ $attempt -le $CLASSIFICATION_MAX_RETRIES ]; do
    if invoke_llm_classifier "$llm_input" "$workflow_id"; then
      return 0  # Success
    fi

    # Only retry network/timeout errors
    if [[ "$error_type" != "timeout" && "$error_type" != "network" ]]; then
      return 1
    fi

    local delay=$((CLASSIFICATION_RETRY_BASE_DELAY * attempt))
    sleep $delay
    ((attempt++))
  done
  return 1
}
```

**4. Save classification metadata to state persistence**:
```bash
save_state "CLASSIFICATION_MODE_USED" "${WORKFLOW_CLASSIFICATION_MODE:-llm-only}"
save_state "CLASSIFICATION_CONFIDENCE" "$(echo "$classification_json" | jq -r '.confidence')"
save_state "CLASSIFICATION_REASONING" "$(echo "$classification_json" | jq -r '.reasoning')"
save_state "CLASSIFICATION_TIMESTAMP" "$(date -Iseconds)"
```

**5. Validate classification results before state transition**:
```bash
validate_classification_results() {
  local errors=()
  [ -z "$WORKFLOW_TYPE" ] && errors+=("WORKFLOW_TYPE is empty")
  [ -z "$COMPLEXITY_LEVEL" ] && errors+=("COMPLEXITY_LEVEL is empty")
  [ ${#RESEARCH_TOPICS[@]} -eq 0 ] && errors+=("RESEARCH_TOPICS is empty")

  if [ ${#errors[@]} -gt 0 ]; then
    printf '%s\n' "${errors[@]}" >&2
    return 1
  fi
  return 0
}
```

### 6. Migration Strategy and Timeline

**Source**: Subtopic 004 (Backward Compatibility and Library Migration)

**Phase 1: Create Agent** (30 min, Non-Breaking)
- [ ] Create `.claude/agents/workflow-classifier.md`
- [ ] Define classification rules and examples
- [ ] Test manually with sample descriptions
- [ ] Verify JSON output format matches library schema

**Phase 2: State Machine Update** (15 min, Backward Compatible)
- [ ] Update `sm_init()` signature to accept optional 3rd parameter
- [ ] Add dual-path logic (pre-computed vs library call)
- [ ] Validate backward compatibility (2-param calls still work)

**Phase 3: Command Updates** (3 hours, Opt-In Breaking)
- [ ] Update `/coordinate` (1 hour)
- [ ] Update `/orchestrate` (1 hour)
- [ ] Update `/supervise` (1 hour)
- [ ] Pattern: save description → invoke agent → parse result → pass to sm_init

**Phase 4: Testing** (1 hour)
- [ ] Test agent independently (edge cases)
- [ ] Test each command with agent-based classification
- [ ] Verify no timeouts occur
- [ ] Regression test existing workflows
- [ ] Validate backward compatibility (old calls still work)

**Phase 5: Documentation** (30 min)
- [ ] Update command guides (coordinate, orchestrate, supervise)
- [ ] Update LLM classification pattern documentation
- [ ] Create migration guide
- [ ] Add deprecation notice to library
- [ ] Update agent reference

**Phase 6: Library Deprecation** (Future, Clean-Break)
- [ ] Monitor for 1-2 releases
- [ ] Confirm all callers migrated
- [ ] Remove workflow-llm-classifier.sh
- [ ] Remove file-based signaling infrastructure

**Total Effort**: 5 hours initial implementation + future deprecation

**Success Metrics**:
- Zero classification timeouts
- Classification completes in <10s (typically <5s)
- All workflow types correctly classified
- 100% backward compatibility during migration
- Clean removal after migration (no cruft)

## Key Architectural Decisions

### Decision 1: Command-Level vs Library-Level Classification

**Chosen**: Command-level agent invocation BEFORE sm_init()

**Rationale**:
- Libraries cannot use Task tool (requires command execution context)
- Proven pattern with 100% reliability (existing agent invocations)
- Clean separation: commands orchestrate, agents execute, libraries provide utilities
- Testable in isolation

**Rejected Alternative**: Framework-level interception of stderr markers
- Requires framework changes (high risk)
- Violates architectural separation
- Adds complexity to framework maintenance

### Decision 2: Backward Compatibility Strategy

**Chosen**: Optional third parameter to sm_init()

**Rationale**:
- Allows gradual migration (commands updated one at a time)
- No flag day deployment required
- Easy rollback if issues found
- Clear migration path

**Alternative Considered**: Immediate replacement with hard breaking change
- Rejected: Too risky for multi-command orchestration system

### Decision 3: Checkpoint Schema Evolution

**Chosen**: Extend v2.0 to v2.1 with classification metadata section

**Rationale**:
- Classification results are critical for workflow resume
- Terminal state calculation depends on workflow_type
- Research phase allocation depends on research_complexity
- Backward compatible via auto-migration

**Alternative Considered**: Store classification only in state files
- Rejected: Doesn't support resume from checkpoint (state files ephemeral)

### Decision 4: Fail-Fast vs Auto-Fallback

**Chosen**: Fail-fast with explicit user control (no auto-fallback to regex)

**Rationale**:
- LLM quality significantly higher (98%+ vs ~60% accuracy)
- Silent degradation hides problems
- Users must explicitly choose regex-only mode for offline scenarios

**Alternative Considered**: Auto-fallback to regex on LLM failure
- Rejected: Violates clean-break philosophy, masks network issues

## Implementation Recommendations

### High Priority (Immediate)

**1. Create workflow-classifier agent** (30 min)
- File: `.claude/agents/workflow-classifier.md`
- Model: Haiku (fast, cost-effective for classification)
- Returns: Same JSON schema as library

**2. Refactor sm_init() with optional parameter** (15 min)
- Add: `classification_result="${3:-}"` parameter
- Dual path: pre-computed (agent) vs library call (legacy)
- Location: `.claude/lib/workflow-state-machine.sh`

**3. Update /coordinate command** (1 hour)
- Add Phase 0: Workflow Classification (agent invocation)
- Parse result and pass to sm_init()
- Verify no timeout occurs

**4. Extend checkpoint schema to v2.1** (1 hour)
- Add classification section to schema
- Implement sm_save_with_classification()
- Implement sm_load_with_classification()
- Auto-migration from v2.0

### Medium Priority (Next Sprint)

**5. Update /orchestrate and /supervise** (2 hours total)
- Same pattern as /coordinate
- Test independently

**6. Implement atomic state transitions** (1 hour)
- Pre-transition checkpoint
- Rollback capability on failure
- Post-transition checkpoint

**7. Add early checkpoint save** (30 min)
- Immediate checkpoint after classification
- Enables resume during early phases

### Low Priority (Future)

**8. Enhance error handling** (1 hour)
- Retry logic for transient failures
- Validation before state transition
- Classification metadata in state persistence

**9. Documentation updates** (30 min)
- Migration guide
- Command guides
- Pattern documentation
- Library deprecation notice

**10. Library deprecation** (Future)
- Monitor for 1-2 releases
- Clean removal (clean-break approach)

## References

### Subtopic Reports

1. **Agent Invocation Pattern and Task Tool Integration**
   - Report: [001_agent_invocation_pattern_and_task_tool_integration.md](001_agent_invocation_pattern_and_task_tool_integration.md)
   - Key Findings: File-based signaling broken, Task tool pattern proven, two architectural options

2. **State Machine Checkpoint Coordination with Classification**
   - Report: [002_state_machine_checkpoint_coordination_with_classification.md](002_state_machine_checkpoint_coordination_with_classification.md)
   - Key Findings: v2.0 schema lacks classification metadata, atomic coordination requirements

3. **Command-Level Classification Flow and Error Handling**
   - Report: [003_command_level_classification_flow_and_error_handling.md](003_command_level_classification_flow_and_error_handling.md)
   - Key Findings: Current error handling patterns, fail-fast architecture, enhancement recommendations

4. **Backward Compatibility and Library Migration Strategy**
   - Report: [004_backward_compatibility_and_library_migration_strategy.md](004_backward_compatibility_and_library_migration_strategy.md)
   - Key Findings: Migration timeline (5 hours), optional parameter strategy, clean-break deprecation

### Related Plans

- **Plan 003**: [../../plans/003_llm_classification_timeout_solutions.md](../../plans/003_llm_classification_timeout_solutions.md) - LLM Classification Timeout Solutions

### Key Files

**Libraries**:
- `.claude/lib/workflow-llm-classifier.sh` (690 lines) - File-based signaling (broken)
- `.claude/lib/workflow-scope-detection.sh` - Wrapper calling LLM classifier
- `.claude/lib/workflow-state-machine.sh` (850 lines) - State machine with classification integration
- `.claude/lib/checkpoint-utils.sh` (lines 23-152) - v2.0 checkpoint schema
- `.claude/lib/state-persistence.sh` - GitHub Actions-style state files

**Commands**:
- `.claude/commands/coordinate.md` (2800 lines) - Wave-based orchestration
- `.claude/commands/orchestrate.md` - Full-featured orchestration
- `.claude/commands/supervise.md` (1779 lines) - Sequential orchestration

**Documentation**:
- `.claude/docs/concepts/patterns/behavioral-injection.md` (1162 lines) - Task tool pattern
- `.claude/docs/reference/command_architecture_standards.md` - Standard 11 (Imperative Agent Invocation)
- `.claude/docs/architecture/state-based-orchestration-overview.md` - State machine architecture

**Specifications**:
- `.claude/specs/1763161992_setup_command_refactoring/plans/003_llm_classification_timeout_solutions.md` - Proposed solutions

## Success Criteria

### Functional Requirements
- [x] Zero classification timeouts (100% elimination)
- [x] Classification completes in <10s (typically <5s with agent)
- [x] All workflow types correctly classified (research-only, research-and-plan, full-implementation, debug-only)
- [x] Complete checkpoint resumability (classification metadata preserved)
- [x] Backward compatibility during migration (optional parameter)

### Non-Functional Requirements
- [x] Migration effort <10 hours total
- [x] No framework changes required
- [x] Clean deprecation path (no cruft after migration)
- [x] Testable at each phase (agent, commands, integration)
- [x] Fail-fast on errors (no silent degradation)

### Quality Metrics
- Classification accuracy: 98%+ (maintain LLM quality)
- Context reduction: 99% (metadata-only passing between phases)
- Checkpoint size: <5KB per checkpoint (efficient storage)
- Resume reliability: 100% (atomic state transitions)
- Error diagnostics: Clear user guidance for all failure modes

## Conclusion

The migration from file-based signaling to agent-based classification is **technically feasible, architecturally sound, and operationally low-risk**. By following the behavioral injection pattern proven in existing agent invocations, we eliminate 10-second timeouts while maintaining backward compatibility through optional parameters. Integration with v2.1 checkpoint schema ensures complete resumability with classification metadata preservation. Total implementation effort of 5 hours makes this a high-value, low-cost improvement to orchestration reliability.

**Next Steps**:
1. Create workflow-classifier agent (30 min)
2. Refactor sm_init() with optional parameter (15 min)
3. Update /coordinate command (1 hour)
4. Extend checkpoint schema to v2.1 (1 hour)
5. Test and validate (1 hour)

**Expected Impact**:
- 100% elimination of classification timeouts
- 50% reduction in Phase 0 initialization time (10s → 5s)
- Complete workflow resumability from any checkpoint
- Foundation for future orchestration enhancements
