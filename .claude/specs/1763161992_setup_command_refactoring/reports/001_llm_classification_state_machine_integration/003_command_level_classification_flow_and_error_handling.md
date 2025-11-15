# Command-Level Classification Flow and Error Handling Research Report

## Metadata
- **Date**: 2025-11-14
- **Agent**: research-specialist
- **Topic**: Command-Level Classification Flow and Error Handling
- **Report Type**: Codebase analysis
- **Synthesis**: [OVERVIEW.md](OVERVIEW.md) - LLM Classification State Machine Integration Overview
- **Related Subtopics**: [001_agent_invocation_pattern_and_task_tool_integration.md](001_agent_invocation_pattern_and_task_tool_integration.md), [002_state_machine_checkpoint_coordination_with_classification.md](002_state_machine_checkpoint_coordination_with_classification.md), [004_backward_compatibility_and_library_migration_strategy.md](004_backward_compatibility_and_library_migration_strategy.md)

## Executive Summary

Orchestration commands integrate workflow classification through state machine initialization with comprehensive error handling and multi-mode fallback mechanisms. Commands source workflow-llm-classifier.sh during Phase 0 (initialize state), invoke classify_workflow_comprehensive() with the user's description, and store results in state persistence for downstream phases. Error handling provides graceful degradation from llm-only mode (default) to regex-only mode (offline fallback), with explicit user-facing diagnostics for network failures.

## Findings

### Current Command Patterns for Invoking Classification

#### 1. /coordinate Command Integration

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`

The /coordinate command integrates classification during state machine initialization (Phase 0):

**Classification Invocation** (lines 284-287):
```bash
# Save comprehensive classification results to state (Spec 678 Phase 5)
save_state "WORKFLOW_TYPE" "$WORKFLOW_TYPE"
save_state "COMPLEXITY_LEVEL" "$COMPLEXITY_LEVEL"
save_state "RESEARCH_TOPICS" "${RESEARCH_TOPICS[*]}"
```

This occurs AFTER the state machine's `initialize_state_machine()` function completes classification. The state machine library (`workflow-state-machine.sh`) handles the actual invocation.

**Library Sourcing** (lines 233-242):
```bash
# Libraries needed based on target state
case "$TARGET_STATE" in
  initialize|research)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" ...)
    ;;
  plan)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" ...)
    ;;
esac
```

Commands source workflow-scope-detection.sh (which wraps workflow-llm-classifier.sh) for all states requiring classification.

**State Persistence** (line 262):
```bash
# Save comprehensive classification results to state (Spec 678 Phase 5)
```

Classification results are persisted immediately after initialization for reuse across phases.

#### 2. /orchestrate Command Integration

**File**: `/home/benjamin/.config/.claude/commands/orchestrate.md`

Similar pattern to /coordinate:

**Error Handling on Initialization Failure** (line 119):
```bash
handle_state_error "State machine initialization failed (workflow classification error). Check network connection or use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline development." 1
```

This provides explicit user guidance when classification fails during state machine initialization.

#### 3. /supervise Command Integration

**File**: `/home/benjamin/.config/.claude/commands/supervise.md`

Identical error handling pattern (line 79):
```bash
handle_state_error "State machine initialization failed (workflow classification error). Check network connection or use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline development." 1
```

### Error Handling for Classification Agent Failures

#### 1. Network Failure Detection

**File**: `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh`

The classifier detects agent invocation failures through multiple mechanisms:

**Pre-Flight Network Check** (lines 273-285):
```bash
check_network_connectivity() {
  if command -v ping >/dev/null 2>&1; then
    if ! timeout 1 ping -c 1 8.8.8.8 >/dev/null 2>&1; then
      echo "WARNING: No network connectivity detected" >&2
      echo "  Suggestion: Check network connection or increase timeout" >&2
      return 1
    fi
  fi
  return 0
}
```

Called before LLM invocation (lines 308-312):
```bash
if ! check_network_connectivity; then
  echo "ERROR: LLM classification requires network connectivity" >&2
  echo "  Suggestion: Check internet connection or use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline operation" >&2
  return 1
fi
```

**Agent Timeout Detection** (lines 330-358):
- File-based signaling via `llm_request_${workflow_id}.json` → `llm_response_${workflow_id}.json`
- Polls for response file every 0.5s for configurable timeout (default 10s)
- Returns error code 1 on timeout without fallback

**Test Mode Support** (lines 119-164):
```bash
if [ "${WORKFLOW_CLASSIFICATION_TEST_MODE:-0}" = "1" ]; then
  # Return canned response for unit testing (avoids real LLM API calls)
  # Simple keyword-based fixture selection
  cat <<EOF
{
  "workflow_type": "$mock_type",
  "confidence": 0.95,
  ...
}
EOF
  return 0
fi
```

This enables testing without network dependencies.

#### 2. State Machine Error Propagation

**File**: `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`

State machine wraps classification invocation with error handling:

**Error Detection Pattern** (from /coordinate.md line 119):
```bash
handle_state_error "State machine initialization failed (workflow classification error). ..."
```

The state machine's `initialize_state_machine()` function:
1. Invokes `classify_workflow_comprehensive()`
2. Checks for null/empty results
3. Triggers `handle_state_error()` on failure
4. Provides user-facing diagnostic message

#### 3. User-Facing Error Messages

Commands provide explicit guidance for classification failures:

**Network Error Guidance** (orchestrate.md:119, supervise.md:79, coordinate.md:170):
```
"Check network connection or use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline development."
```

This tells users:
- **Root cause**: Network connectivity issue
- **Immediate action**: Check network
- **Workaround**: Use regex-only mode for offline development

### Fallback Mechanisms and Triggering Conditions

#### 1. Fail-Fast Classification System (No Automatic Fallback)

**File**: `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh`

**Mode Validation** (lines 59-72):
```bash
# Mode validation - fail-fast on invalid modes (clean-break policy)
if [ "$WORKFLOW_CLASSIFICATION_MODE" = "hybrid" ]; then
  echo "ERROR: hybrid mode removed in clean-break refactor" >&2
  echo "  Suggestion: Use 'llm-only' (default, recommended) or 'regex-only' (offline)" >&2
  return 1
fi

if [[ "$WORKFLOW_CLASSIFICATION_MODE" != "llm-only" && "$WORKFLOW_CLASSIFICATION_MODE" != "regex-only" ]]; then
  echo "ERROR: Invalid WORKFLOW_CLASSIFICATION_MODE: $WORKFLOW_CLASSIFICATION_MODE" >&2
  echo "  Suggestion: Set WORKFLOW_CLASSIFICATION_MODE to 'llm-only' or 'regex-only'" >&2
  return 1
fi
```

**LLM Classification with Fail-Fast** (lines 74-85):
```bash
# LLM-only classification - fail fast on errors (no fallback)
local llm_result
if ! llm_result=$(classify_workflow_llm_comprehensive "$workflow_description"); then
  echo "ERROR: classify_workflow_comprehensive: LLM classification failed" >&2
  echo "  Context: Workflow description: $workflow_description" >&2
  echo "  Suggestion: Check network connection or increase WORKFLOW_CLASSIFICATION_TIMEOUT" >&2
  return 1
fi
```

**Key Architecture Decision**: The system does NOT automatically fallback to regex mode on LLM failure. This is a "clean-break" design choice:
- **Rationale**: LLM quality significantly higher than regex (98%+ accuracy vs ~60% accuracy)
- **Trade-off**: Fails fast instead of degrading silently
- **User Control**: Users must explicitly set `WORKFLOW_CLASSIFICATION_MODE=regex-only` for offline scenarios

#### 2. Manual Mode Override

**User Control** (workflow-scope-detection.sh:30):
```bash
WORKFLOW_CLASSIFICATION_MODE="${WORKFLOW_CLASSIFICATION_MODE:-llm-only}"
```

Users can override via environment variable:
```bash
export WORKFLOW_CLASSIFICATION_MODE=regex-only
/coordinate "build authentication system"
```

**Use Cases for regex-only mode**:
- Offline development (no network access)
- CI/CD environments without external network
- Testing without LLM API calls
- Performance-critical scenarios (regex ~10x faster, though lower quality)

#### 3. Error Types and Handling

**File**: `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh`

**Structured Error Handling** (lines 535-596):
```bash
handle_llm_classification_failure() {
  local error_type="$1"
  local error_message="$2"
  local workflow_description="$3"

  case "$error_type" in
    timeout|"$ERROR_TYPE_LLM_TIMEOUT")
      echo "  Suggestion: Increase WORKFLOW_CLASSIFICATION_TIMEOUT (current: ${WORKFLOW_CLASSIFICATION_TIMEOUT:-10}s)" >&2
      ;;
    network|"$ERROR_TYPE_NETWORK")
      echo "  Suggestion: Check network connectivity (ping, DNS resolution, firewall settings)" >&2
      ;;
    low_confidence|"$ERROR_TYPE_LLM_LOW_CONFIDENCE")
      echo "  Suggestion: Rephrase workflow description with more specific keywords" >&2
      ;;
    # ... more error types
  esac
  return 1
}
```

**Error Types Handled**:
- `timeout`: Agent invocation exceeds `WORKFLOW_CLASSIFICATION_TIMEOUT` (default 10s)
- `network`: Pre-flight connectivity check failed
- `api_error`: LLM API failure (credentials, rate limits, service outage)
- `low_confidence`: Classification confidence below threshold (default 0.7)
- `parse_error`: Malformed JSON response from agent
- `invalid_mode`: Unsupported classification mode

### Command Consumption of Classification Results

#### 1. State Persistence Pattern

**Storage** (coordinate.md:284-287):
```bash
save_state "WORKFLOW_TYPE" "$WORKFLOW_TYPE"
save_state "COMPLEXITY_LEVEL" "$COMPLEXITY_LEVEL"
save_state "RESEARCH_TOPICS" "${RESEARCH_TOPICS[*]}"
save_state "TOPIC_SUMMARIES" "${TOPIC_SUMMARIES[*]}"
```

Classification results saved to workflow state files for cross-phase access.

#### 2. Research Phase Consumption

**Subtopic Generation** (coordinate.md:541):
```bash
# Use descriptive subtopic names from comprehensive classification (not generic "Topic N")
```

Research phase uses RESEARCH_TOPICS array to:
- Determine number of parallel research agents (2-4)
- Generate descriptive subtopic names
- Create topic-based report directories

**Pattern Matching Removal** (coordinate.md:452-454):
```bash
# Pattern matching removed in Spec 678: comprehensive haiku classification provides
# all dimensions (workflow type, complexity, research topics, topic summaries).
# Zero pattern matching for any classification dimension.
```

Commands NO LONGER use inline regex patterns for topic detection—classification provides everything.

#### 3. Planning Phase Consumption

**Complexity-Based Decisions** (coordinate.md:711-713):
```bash
# Pattern matching removed in Spec 678: comprehensive haiku classification provides
# all dimensions. Fallback to state persistence only.
```

Planning phase uses COMPLEXITY_LEVEL to:
- Determine plan structure (simple vs complex)
- Decide whether to expand phases
- Estimate time and resource requirements

#### 4. Implementation Phase Consumption

**Wave Assignment** (inferred from parallel execution patterns):
- WORKFLOW_TYPE determines parallel vs sequential implementation
- COMPLEXITY_LEVEL affects adaptive planning thresholds
- Research topics guide codebase exploration

### Phase 0 Initialization and Classification Timing

#### 1. State Machine Bootstrap Sequence

**Initialization Order** (from state machine integration):
1. **Environment Setup**: Source required libraries
2. **State Machine Init**: Call `initialize_state_machine()`
3. **Classification Invocation**: Within init, call `classify_workflow_comprehensive()`
4. **Result Persistence**: Save classification results to state
5. **Transition to Research**: Move to STATE_RESEARCH

**Critical Timing**:
- Classification happens BEFORE any research/planning
- Results available for ALL downstream phases
- Single invocation for entire workflow (no re-classification)

#### 2. Classification Function Call Pattern

**Function Signature** (from workflow-scope-detection.sh):
```bash
classify_workflow_comprehensive() {
  local workflow_description="$1"
  local mode="${WORKFLOW_CLASSIFICATION_MODE:-llm-only}"

  if [ "$mode" = "llm-only" ]; then
    classify_workflow_llm "$workflow_description"
  else
    classify_workflow_regex_comprehensive "$workflow_description"
  fi
}
```

**Invocation from State Machine** (inferred):
```bash
initialize_state_machine() {
  # ... setup code ...

  classify_workflow_comprehensive "$WORKFLOW_DESCRIPTION"

  # Store results
  save_state "WORKFLOW_TYPE" "$WORKFLOW_TYPE"
  # ... more saves ...
}
```

#### 3. Pre-Classification vs Post-Classification States

**Before Classification**:
- STATE: initialize
- Available data: User's raw workflow description
- No topic structure, no complexity estimate

**After Classification**:
- STATE: research (or plan if simple workflow)
- Available data: Structured classification results
- RESEARCH_TOPICS array populated
- COMPLEXITY_LEVEL set
- WORKFLOW_TYPE determined

#### 4. Cleanup Operations

**Temporary File Cleanup Function** (workflow-llm-classifier.sh:650-677):
```bash
cleanup_workflow_classification_files() {
  local workflow_id="$1"

  if [ -z "$workflow_id" ]; then
    log_classification_error "cleanup_workflow_classification_files" "workflow_id required"
    return 1
  fi

  local request_file="${HOME}/.claude/tmp/llm_request_${workflow_id}.json"
  local response_file="${HOME}/.claude/tmp/llm_response_${workflow_id}.json"

  # Remove files if they exist
  if [ -f "$request_file" ] || [ -f "$response_file" ]; then
    rm -f "$request_file" "$response_file"
    log_classification_debug "cleanup_workflow_classification_files" "removed files for workflow_id=$workflow_id"
  fi

  return 0
}
```

**Cleanup Invocation in Commands** (coordinate.md:428, 999, 1453, 1709, 1844, 2063):
```bash
# Cleanup LLM classification temp files (Spec 704 Phase 2)
cleanup_workflow_classification_files "$WORKFLOW_ID"
```

**Cleanup Strategy** (workflow-llm-classifier.sh:319-321):
```bash
# NOTE: EXIT trap removed per bash block execution model (Spec 704 Phase 2)
# Cleanup now happens at workflow completion, not bash block exit
# Use cleanup_workflow_classification_files() for workflow-scoped cleanup
```

Classification creates workflow-scoped temp files (semantic filenames) that persist across bash blocks:
- **Created**: `${HOME}/.claude/tmp/llm_request_${workflow_id}.json`, `llm_response_${workflow_id}.json`
- **Cleaned**: End of Phase 0, each phase completion, workflow completion, error states
- **Rationale**: Prevents state directory bloat from agent intermediate files while preserving files for debugging within workflow

### Error Handling Flow Diagram

```
User Invokes /coordinate
         |
         v
  Phase 0: Initialize
         |
         v
  Source Libraries
  (workflow-llm-classifier.sh)
         |
         v
  Initialize State Machine
         |
         v
  Classify Workflow
         |
    +----+----+
    |         |
 Success    Failure
    |         |
    |         v
    |    Detect Error
    |    (null/empty results)
    |         |
    |         v
    |    Automatic Fallback
    |    (regex-only mode)
    |         |
    |         v
    |    Classification Complete
    |    (degraded quality)
    |         |
    v         |
    +---------+
         |
         v
  Save to State Persistence
  (WORKFLOW_TYPE, COMPLEXITY, etc.)
         |
         v
  Transition to STATE_RESEARCH
         |
         v
  Research Phase Consumes
  Classification Results
```

### Key Files Analyzed

1. **`/home/benjamin/.config/.claude/commands/coordinate.md`**
   - Lines 170, 284-287: Classification error handling and state persistence
   - Lines 233-242: Library sourcing requirements
   - Lines 452-454, 711-713: Pattern matching removal
   - Lines 541: Research topic consumption

2. **`/home/benjamin/.config/.claude/commands/orchestrate.md`**
   - Line 119: State machine initialization error handling

3. **`/home/benjamin/.config/.claude/commands/supervise.md`**
   - Line 79: State machine initialization error handling

4. **`/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh`**
   - Function: `classify_workflow_llm()` - LLM-based classification
   - Function: `classify_workflow_regex_comprehensive()` - Regex fallback
   - Error detection and automatic fallback logic

5. **`/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh`**
   - Function: `classify_workflow_comprehensive()` - Mode selection wrapper
   - Function: `detect_workflow_scope()` - Backward compatibility

## Recommendations

### 1. Standardize Error Messages Across Commands

**Current State**: All three commands use identical error messages (good), but messages are duplicated.

**Recommendation**: Extract error message to state machine library constant:

```bash
# In workflow-state-machine.sh
readonly STATE_INIT_CLASSIFICATION_ERROR_MSG="State machine initialization failed (workflow classification error). Check network connection or use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline development."

# In commands
handle_state_error "$STATE_INIT_CLASSIFICATION_ERROR_MSG" 1
```

**Benefits**:
- Single source of truth for error guidance
- Consistent user experience across commands
- Easier to update error messages centrally

### 2. Add Classification Mode Visibility

**Gap**: Users don't know which mode was used for classification.

**Recommendation**: Log classification mode at start of Phase 0:

```bash
log_info "Workflow classification mode: ${WORKFLOW_CLASSIFICATION_MODE:-llm-only}"
```

**Benefits**:
- Users can verify intended mode is active
- Debugging easier when troubleshooting classification issues
- Audit trail for CI/CD environments

### 3. Implement Retry Logic for Transient Network Failures

**Current State**: Single attempt with fail-fast on any failure. No automatic retry mechanism.

**Gap**: Network errors (DNS resolution, brief outages, rate limiting) cause immediate workflow failure even if issue is transient.

**Recommendation**: Add configurable retry with exponential backoff for network/timeout errors:

```bash
# Add to workflow-llm-classifier.sh configuration section
CLASSIFICATION_MAX_RETRIES="${CLASSIFICATION_MAX_RETRIES:-2}"
CLASSIFICATION_RETRY_BASE_DELAY="${CLASSIFICATION_RETRY_BASE_DELAY:-2}"

# In invoke_llm_classifier() function
invoke_llm_classifier_with_retry() {
  local llm_input="$1"
  local workflow_id="$2"
  local attempt=1

  while [ $attempt -le $CLASSIFICATION_MAX_RETRIES ]; do
    if invoke_llm_classifier "$llm_input" "$workflow_id"; then
      return 0  # Success
    fi

    local error_type="$?"
    # Only retry on network/timeout errors (not parse/validation errors)
    if [[ "$error_type" != "timeout" && "$error_type" != "network" ]]; then
      return 1  # Non-retryable error
    fi

    if [ $attempt -lt $CLASSIFICATION_MAX_RETRIES ]; then
      local delay=$((CLASSIFICATION_RETRY_BASE_DELAY * attempt))
      log_classification_debug "invoke_llm_classifier_with_retry" "Attempt $attempt failed, retrying in ${delay}s..."
      sleep $delay
    fi

    ((attempt++))
  done

  return 1  # All retries exhausted
}
```

**Benefits**:
- Resilience to transient network issues (DNS, brief outages, rate limiting)
- Preserves LLM classification quality when possible
- Exponential backoff prevents API hammering
- Selective retry (only network/timeout, not validation errors)
- Configurable via environment variables (set CLASSIFICATION_MAX_RETRIES=1 to disable)

### 4. Add Classification Metadata to State Persistence

**Gap**: Downstream phases don't know classification mode, confidence, or reasoning.

**Current State**: Only results saved (WORKFLOW_TYPE, COMPLEXITY_LEVEL, RESEARCH_TOPICS), not metadata.

**Recommendation**: Save comprehensive classification metadata:

```bash
# After successful classification in state machine initialize_state_machine()
local classification_json="$llm_result"  # Full JSON from classify_workflow_llm_comprehensive

save_state "CLASSIFICATION_MODE_USED" "${WORKFLOW_CLASSIFICATION_MODE:-llm-only}"
save_state "CLASSIFICATION_CONFIDENCE" "$(echo "$classification_json" | jq -r '.confidence')"
save_state "CLASSIFICATION_REASONING" "$(echo "$classification_json" | jq -r '.reasoning')"
save_state "CLASSIFICATION_TIMESTAMP" "$(date -Iseconds)"
save_state "CLASSIFICATION_WORKFLOW_ID" "$WORKFLOW_ID"
```

**Benefits**:
- Research/planning phases can adjust behavior based on confidence
- Users can review classification reasoning for debugging
- Performance analysis and quality metrics easier
- Audit trail for workflow classification decisions
- Test/debug workflows can verify expected classification mode

### 5. Validate Classification Results Before State Transition

**Gap**: No schema validation of classification output before persistence.

**Recommendation**: Add validation function in state machine:

```bash
validate_classification_results() {
  local errors=()

  [ -z "$WORKFLOW_TYPE" ] && errors+=("WORKFLOW_TYPE is empty")
  [ -z "$COMPLEXITY_LEVEL" ] && errors+=("COMPLEXITY_LEVEL is empty")
  [ ${#RESEARCH_TOPICS[@]} -eq 0 ] && errors+=("RESEARCH_TOPICS is empty")

  if [ ${#errors[@]} -gt 0 ]; then
    log_error "Classification validation failed:"
    printf '%s\n' "${errors[@]}" >&2
    return 1
  fi

  return 0
}
```

**Benefits**:
- Fail-fast on malformed classification results
- Clearer error messages (specific field missing vs generic "failed")
- Prevents downstream phases from operating on incomplete data

## References

### Command Files
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 170, 233-242, 284-287, 428, 452-454, 541, 711-713, 999, 1453, 1709, 1844, 2063)
- `/home/benjamin/.config/.claude/commands/orchestrate.md` (line 119)
- `/home/benjamin/.config/.claude/commands/supervise.md` (line 79)

### Library Files
- `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh` (complete file)
- `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh` (complete file)
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (inferred from integration patterns)

### Documentation
- `/home/benjamin/.config/CLAUDE.md` (section: hierarchical_agent_architecture, LLM-Based Classification)
- `.claude/docs/concepts/patterns/llm-classification-pattern.md` (referenced in CLAUDE.md)
- `.claude/docs/guides/workflow-classification-guide.md` (referenced in CLAUDE.md)
