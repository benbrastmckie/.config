# Haiku Classifier Integration with /coordinate Command

## Metadata
- **Date**: 2025-11-12
- **Agent**: research-specialist
- **Topic**: Integration with /coordinate command (how classifier is invoked and used)
- **Report Type**: codebase analysis
- **Source Plan**: /home/benjamin/.config/.claude/specs/678_coordinate_haiku_classification/plans/001_comprehensive_classification_implementation.md

## Executive Summary

The Haiku-based workflow classifier integrates with /coordinate through a multi-layered architecture: comprehensive classification occurs in `sm_init()` via `classify_workflow_comprehensive()`, results persist through GitHub Actions-style state files, and dynamic path allocation uses classification results to allocate exactly the right number of report paths (1-4). The integration achieves zero operational risk through automatic regex fallback and 85% token reduction through Phase 0 path pre-calculation.

## Findings

### 1. Invocation Flow

**Entry Point: /coordinate command initialization** (`coordinate.md:166`)
```bash
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" >/dev/null
```

The `/coordinate` command invokes the state machine initialization function `sm_init()` which triggers the comprehensive classifier.

**State Machine Initialization** (`workflow-state-machine.sh:217-302`)
```bash
sm_init() {
  local workflow_desc="$1"
  local command_name="$2"

  # Source workflow-scope-detection.sh
  source "$SCRIPT_DIR/workflow-scope-detection.sh"

  # Get comprehensive classification (workflow_type, research_complexity, subtopics)
  if classification_result=$(classify_workflow_comprehensive "$workflow_desc" 2>/dev/null); then
    WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type // "full-implementation"')
    RESEARCH_COMPLEXITY=$(echo "$classification_result" | jq -r '.research_complexity // 2')
    RESEARCH_TOPICS_JSON=$(echo "$classification_result" | jq -c '.subtopics // []')

    # Export all three classification dimensions
    export WORKFLOW_SCOPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON
  else
    # Fallback to regex-only classification
    WORKFLOW_SCOPE=$(classify_workflow_regex "$workflow_desc" 2>/dev/null || echo "full-implementation")
    RESEARCH_COMPLEXITY=2
    RESEARCH_TOPICS_JSON='["Topic 1", "Topic 2"]'
    export WORKFLOW_SCOPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON
  fi
}
```

Key observations:
- **Single comprehensive call**: One LLM invocation provides all three classification dimensions
- **Automatic fallback**: If comprehensive classification fails, regex-only mode provides safe defaults
- **Export pattern**: All results exported for cross-bash-block availability
- **Silent by default**: stderr suppressed (`2>/dev/null`) to avoid polluting output

### 2. Comprehensive Classification Layer

**Hybrid Mode Router** (`workflow-scope-detection.sh:50-106`)
```bash
classify_workflow_comprehensive() {
  case "$WORKFLOW_CLASSIFICATION_MODE" in
    hybrid)
      # Try LLM first, fallback to regex + heuristic
      if llm_result=$(classify_workflow_llm_comprehensive "$workflow_description" 2>/dev/null); then
        echo "$llm_result"
        return 0
      fi
      fallback_comprehensive_classification "$workflow_description"
      return 0
      ;;
    llm-only)
      # Fail fast on LLM errors
      ;;
    regex-only)
      # Skip LLM entirely
      fallback_comprehensive_classification "$workflow_description"
      return 0
      ;;
  esac
}
```

**Three-Mode Architecture**:
1. **Hybrid mode (default)**: LLM with automatic regex fallback → zero operational risk
2. **LLM-only mode**: Fail-fast for testing/debugging → exposes classification errors
3. **Regex-only mode**: Traditional pattern matching → deterministic for CI/CD

**Fallback Composition** (`workflow-scope-detection.sh:114-141`)
```bash
fallback_comprehensive_classification() {
  local scope=$(classify_workflow_regex "$workflow_description")
  local complexity=$(infer_complexity_from_keywords "$workflow_description")
  local subtopics_json=$(generate_generic_topics "$complexity")

  jq -n \
    --arg scope "$scope" \
    --argjson complexity "$complexity" \
    --argjson subtopics "$subtopics_json" \
    '{
      "workflow_type": $scope,
      "confidence": 0.6,
      "research_complexity": $complexity,
      "subtopics": $subtopics,
      "reasoning": "Fallback: regex scope + heuristic complexity"
    }'
}
```

Fallback provides complete JSON response with same structure as LLM classification, enabling seamless downstream consumption.

### 3. LLM Invocation Mechanism

**File-Based Signaling Protocol** (`workflow-llm-classifier.sh:210-265`)
```bash
invoke_llm_classifier() {
  local request_file="/tmp/llm_classification_request_$$.json"
  local response_file="/tmp/llm_classification_response_$$.json"

  echo "$llm_input" > "$request_file"
  echo "[LLM_CLASSIFICATION_REQUEST] Please process request at: $request_file → $response_file" >&2

  # Wait for response with timeout (default 10s)
  local iterations=$((WORKFLOW_CLASSIFICATION_TIMEOUT * 2))
  while [ $count -lt $iterations ]; do
    if [ -f "$response_file" ]; then
      cat "$response_file"
      return 0
    fi
    sleep 0.5
    count=$((count + 1))
  done

  # Timeout → fallback triggered
  return 1
}
```

**Critical Design Choice**: File-based signaling rather than subprocess invocation
- **Rationale**: Bash scripts cannot directly invoke Claude API
- **Mechanism**: Script writes request file, emits special marker to stderr, waits for response file
- **Claude's role**: Monitors stderr for `[LLM_CLASSIFICATION_REQUEST]` markers, processes JSON, writes response
- **Timeout handling**: 10-second default (configurable via `WORKFLOW_CLASSIFICATION_TIMEOUT`)
- **Failure mode**: Timeout triggers automatic fallback to regex classification

### 4. State Persistence

**Export Strategy** (`workflow-state-machine.sh:241-243`)
```bash
export WORKFLOW_SCOPE
export RESEARCH_COMPLEXITY
export RESEARCH_TOPICS_JSON
```

Three separate exports enable different persistence patterns:
- `WORKFLOW_SCOPE`: String value, simple export
- `RESEARCH_COMPLEXITY`: Integer value, simple export
- `RESEARCH_TOPICS_JSON`: JSON-encoded array (bash cannot export arrays)

**State File Serialization** (`coordinate.md:260-274`)
```bash
# Save comprehensive classification results to state
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
append_workflow_state "RESEARCH_TOPICS_JSON" "$RESEARCH_TOPICS_JSON"

# Serialize REPORT_PATHS array to state
append_workflow_state "REPORT_PATHS_COUNT" "$REPORT_PATHS_COUNT"
for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
  var_name="REPORT_PATH_$i"
  eval "value=\$$var_name"
  append_workflow_state "$var_name" "$value"
done
```

**GitHub Actions-Style State File Format**:
```bash
export WORKFLOW_SCOPE='research-and-plan'
export RESEARCH_COMPLEXITY='3'
export RESEARCH_TOPICS_JSON='["Existing auth patterns","OAuth2 integration","Session management"]'
export REPORT_PATHS_COUNT='3'
export REPORT_PATH_0='/home/user/.claude/specs/042_auth/reports/001_topic1.md'
export REPORT_PATH_1='/home/user/.claude/specs/042_auth/reports/002_topic2.md'
export REPORT_PATH_2='/home/user/.claude/specs/042_auth/reports/003_topic3.md'
```

**State Restoration** (`coordinate.md:375-382, 641-651`)
```bash
# Re-source state machine and persistence libraries
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Load workflow state
WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"
# Now WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON available
```

**Cross-Bash-Block Pattern**:
1. Bash block 1: Classification + export + state persistence
2. Bash block 2: Re-source libraries + load state → variables restored
3. Subprocess isolation constraint prevents simple variable inheritance

### 5. Dynamic Path Allocation

**Phase 0 Just-in-Time Allocation** (`workflow-initialization.sh:326-352`)
```bash
# Dynamic allocation based on RESEARCH_COMPLEXITY (1-4)
local -a report_paths
for i in $(seq 1 "$research_complexity"); do
  report_paths+=("${topic_path}/reports/$(printf '%03d' $i)_topic${i}.md")
done

# Export individual variables (arrays can't be exported)
for i in $(seq 0 $((research_complexity - 1))); do
  export "REPORT_PATH_$i=${report_paths[$i]}"
done

export REPORT_PATHS_COUNT="$research_complexity"
```

**Design Evolution** (Spec 678 Phase 4):
- **Before**: Pre-allocated 4 paths regardless of complexity → wasted variables, diagnostic noise
- **After**: Allocate exactly `$research_complexity` paths → clean, efficient, matches usage
- **Enabler**: Comprehensive classification provides complexity before path allocation
- **Benefits**: Zero unused variables, cleaner state files, precise resource allocation

**Integration with Research Phase** (`coordinate.md:511-523`)
```bash
# Prepare variables for conditional agent invocations
for i in $(seq 1 4); do
  REPORT_PATH_VAR="REPORT_PATH_$((i-1))"
  topic_index=$((i-1))
  if [ $topic_index -lt ${#RESEARCH_TOPICS[@]} ]; then
    export "RESEARCH_TOPIC_${i}=${RESEARCH_TOPICS[$topic_index]}"
  else
    export "RESEARCH_TOPIC_${i}=Topic ${i}"
  fi
  export "AGENT_REPORT_PATH_${i}=${!REPORT_PATH_VAR}"
done
```

**Conditional Agent Invocation**:
- Explicit IF guards: `IF RESEARCH_COMPLEXITY >= 1`, `IF RESEARCH_COMPLEXITY >= 2`, etc.
- Prevents over-invocation: Only spawn agents matching complexity (not all 4)
- Uses descriptive topic names from `RESEARCH_TOPICS_JSON` (not generic "Topic N")

### 6. Error Handling and Fallback Patterns

**Three-Tier Fallback Architecture**:

**Tier 1: LLM Classification** (`workflow-llm-classifier.sh:99-145`)
- Primary intelligence layer
- File-based signaling protocol
- 10-second timeout default
- Returns comprehensive JSON with confidence score

**Tier 2: Confidence Threshold Filter** (`workflow-llm-classifier.sh:129-140`)
```bash
local conf_int=$(echo "$confidence * 100" | awk '{printf "%.0f", $1}')
local threshold_int=$(echo "$WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD * 100" | awk '{printf "%.0f", $1}')

if [ "$conf_int" -lt "$threshold_int" ]; then
  log_classification_result "low-confidence" "$parsed_response"
  return 1  # Trigger fallback
fi
```
- Default threshold: 0.7 (70% confidence)
- Low-confidence classifications rejected → automatic fallback
- Prevents unreliable classifications from propagating

**Tier 3: Regex + Heuristic Fallback** (`workflow-scope-detection.sh:114-141`)
- Deterministic pattern matching for scope
- Keyword-based heuristics for complexity
- Generic topic name generation
- Guaranteed success (no failure mode)

**Verification Pattern** (Spec 057 distinction):
- **Bootstrap fallbacks**: PROHIBITED (hide errors)
- **Verification fallbacks**: REQUIRED (detect errors)
- **Optimization fallbacks**: ACCEPTABLE (graceful degradation)

LLM classification uses **optimization fallback**:
- LLM is performance optimization (higher accuracy)
- Regex is guaranteed baseline (always works)
- Failure detection explicit: timeout, low confidence, parse error
- Graceful degradation: Switch to regex without workflow failure

### 7. State Machine Integration

**State-Based Lifecycle** (`coordinate.md:323-326`)
```bash
# Transition to research state
sm_transition "$STATE_RESEARCH"
append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"
```

**Comprehensive Classification Timing**:
1. **Phase 0 (Initialize)**: `sm_init()` invokes comprehensive classifier
2. **Result persistence**: Classification exported + saved to state file
3. **Phase 1 (Research)**: Classification results loaded from state
4. **Dynamic allocation**: `initialize_workflow_paths()` uses `RESEARCH_COMPLEXITY`
5. **Agent invocation**: Research agents spawn conditionally based on complexity

**State Transition Flow**:
```
STATE_INITIALIZE
  └─> sm_init() [comprehensive classification]
  └─> initialize_workflow_paths() [dynamic allocation]
  └─> sm_transition(STATE_RESEARCH)
STATE_RESEARCH
  └─> load_workflow_state() [restore classification]
  └─> spawn N agents (N = RESEARCH_COMPLEXITY)
  └─> sm_transition(STATE_PLAN or STATE_COMPLETE)
```

### 8. Performance Characteristics

**Phase 0 Optimization Metrics** (`coordinate.md:340-344`)
```bash
PERF_LIB_MS=$(( (PERF_AFTER_LIBS - PERF_START_TOTAL) / 1000000 ))
PERF_PATH_MS=$(( (PERF_AFTER_PATHS - PERF_AFTER_LIBS) / 1000000 ))
PERF_TOTAL_MS=$(( (PERF_END_INIT - PERF_START_TOTAL) / 1000000 ))
echo "  Library loading: ${PERF_LIB_MS}ms"
echo "  Path initialization: ${PERF_PATH_MS}ms"
echo "  Total init overhead: ${PERF_TOTAL_MS}ms"
```

**Observed Performance** (Spec 602):
- Library loading: ~200-300ms
- Path initialization: ~50-100ms (includes classification)
- Total Phase 0: ~250-400ms
- LLM classification: ~2000-5000ms (when used)
- Regex fallback: <1ms (when used)

**Phase 0 Token Reduction**:
- **Before**: Agent-based discovery consumed 20,000+ tokens
- **After**: Pre-calculated paths consumed 3,000 tokens
- **Reduction**: 85% token reduction, 25x speedup
- **Reference**: `.claude/docs/guides/phase-0-optimization.md`

**Comprehensive Classification Overhead**:
- Single comprehensive call vs 3 separate calls
- JSON parsing overhead: ~5-10ms per parse
- Net benefit: 66% fewer LLM calls, cleaner response structure

## Recommendations

### 1. Monitoring and Observability

**Add classification metrics logging**:
```bash
# In sm_init() after classification
log_classification_metrics() {
  local mode="$1"
  local duration_ms="$2"
  local scope="$3"
  local complexity="$4"

  echo "[METRICS] classification_method=$mode duration_ms=$duration_ms scope=$scope complexity=$complexity" >> "$CLAUDE_PROJECT_DIR/.claude/data/logs/classification-metrics.log"
}
```

**Benefits**:
- Track LLM vs regex usage ratio
- Identify timeout patterns
- Monitor confidence score distribution
- Performance regression detection

### 2. Configuration Validation

**Add comprehensive mode validation**:
```bash
# In coordinate.md initialization block
validate_classification_config() {
  if [ -n "${WORKFLOW_CLASSIFICATION_MODE:-}" ]; then
    case "$WORKFLOW_CLASSIFICATION_MODE" in
      hybrid|llm-only|regex-only) ;;
      *)
        echo "ERROR: Invalid WORKFLOW_CLASSIFICATION_MODE='$WORKFLOW_CLASSIFICATION_MODE'"
        echo "Valid modes: hybrid, llm-only, regex-only"
        return 1
        ;;
    esac
  fi
}
```

**Benefits**:
- Catch typos early (e.g., `hybrd`, `regex`)
- Explicit error messages
- Environment variable documentation

### 3. State Persistence Optimization

**Implement state file compression**:
```bash
# For large RESEARCH_TOPICS_JSON arrays
compress_state_value() {
  local key="$1"
  local value="$2"

  if [ ${#value} -gt 1000 ]; then
    # Base64 encode + gzip for values >1KB
    compressed=$(echo "$value" | gzip | base64 -w0)
    append_workflow_state "${key}_COMPRESSED" "1"
    append_workflow_state "$key" "$compressed"
  else
    append_workflow_state "$key" "$value"
  fi
}
```

**Benefits**:
- Reduce state file size for complex workflows
- Faster state loading across bash blocks
- Lower disk I/O overhead

### 4. Fallback Transparency

**Add fallback reason tracking**:
```bash
# In classify_workflow_comprehensive fallback path
fallback_comprehensive_classification() {
  local workflow_description="$1"
  local fallback_reason="${2:-unknown}"

  # Add fallback_reason to JSON response
  jq -n \
    --arg scope "$scope" \
    --argjson complexity "$complexity" \
    --argjson subtopics "$subtopics_json" \
    --arg reason "$fallback_reason" \
    '{
      "workflow_type": $scope,
      "confidence": 0.6,
      "research_complexity": $complexity,
      "subtopics": $subtopics,
      "reasoning": "Fallback: regex scope + heuristic complexity",
      "fallback_reason": $reason
    }'
}
```

**Benefits**:
- Distinguish timeout vs low-confidence vs parse-error fallbacks
- Improve debugging when LLM classification fails
- Track most common failure modes

### 5. Enhanced Dynamic Discovery

**Post-classification path reconciliation** (already implemented in `coordinate.md:690-714`):
```bash
# Dynamic Report Path Discovery
DISCOVERY_COUNT=0
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  PATTERN=$(printf '%03d' $i)
  FOUND_FILE=$(find "$REPORTS_DIR" -maxdepth 1 -name "${PATTERN}_*.md" -type f | head -1)

  if [ -n "$FOUND_FILE" ]; then
    DISCOVERED_REPORTS+=("$FOUND_FILE")
    DISCOVERY_COUNT=$((DISCOVERY_COUNT + 1))
  fi
done
```

**Enhancement**: Add discovery result validation
```bash
if [ "$DISCOVERY_COUNT" -ne "$RESEARCH_COMPLEXITY" ]; then
  echo "WARNING: Path discovery mismatch (expected $RESEARCH_COMPLEXITY, found $DISCOVERY_COUNT)"
  # Log details for debugging
  log_discovery_mismatch "$RESEARCH_COMPLEXITY" "$DISCOVERY_COUNT" "${DISCOVERED_REPORTS[@]}"
fi
```

## References

### Primary Integration Points
- `/home/benjamin/.config/.claude/commands/coordinate.md:166` - sm_init invocation
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh:217-302` - sm_init implementation
- `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh:50-141` - Comprehensive classification router
- `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh:99-145` - LLM classifier implementation
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:168-352` - Dynamic path allocation

### State Management
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` - GitHub Actions-style state file operations
- `/home/benjamin/.config/.claude/commands/coordinate.md:260-274` - State serialization logic
- `/home/benjamin/.config/.claude/commands/coordinate.md:375-382` - State restoration pattern

### Error Handling
- `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh:210-265` - File-based signaling protocol
- `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh:129-140` - Confidence threshold filtering
- `/home/benjamin/.config/.claude/specs/057_fail_fast_policy_analysis/reports/001_fail_fast_policy_analysis.md` - Fallback taxonomy

### Performance Documentation
- `/home/benjamin/.config/.claude/docs/guides/phase-0-optimization.md` - Phase 0 optimization guide
- `/home/benjamin/.config/.claude/specs/602_601_and_documentation_in_claude_docs_in_order_to/reports/004_performance_validation_report.md` - Performance metrics
- `/home/benjamin/.config/.claude/specs/678_coordinate_haiku_classification/plans/001_comprehensive_classification_implementation.md` - Source implementation plan

### Architecture References
- `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md` - State machine architecture
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md` - Bash subprocess isolation patterns
- `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md` - Complete /coordinate usage guide
