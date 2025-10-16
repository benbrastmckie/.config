# Phase 4: Hybrid Complexity & Workflow Metrics - Detailed Implementation Specification

## Overview

**Objective**: Add agent-based complexity evaluation for borderline cases and comprehensive workflow metrics aggregation

**Complexity**: 7/10 (Medium-High) - Architectural significance with implementation uncertainty

**Duration**: 3-4 sessions

**Task Count**: 11 tasks (7 hybrid complexity + 4 workflow metrics)

**Status**: PENDING

---

## Complexity Rationale

This phase receives a complexity score of 7/10 due to:

1. **Architectural Significance (3/10 contribution)**:
   - Defines decision tree for when to invoke agent vs use threshold scoring
   - Establishes score reconciliation algorithm affecting downstream agent selection
   - Integration point between complexity-utils.sh and implement.md workflow

2. **Implementation Uncertainty (2/10 contribution)**:
   - Score reconciliation algorithm requires careful design (blend vs choose)
   - Optimal invocation criteria need experimentation (score >=7 vs >=8, tasks >=8 vs >=10)
   - Agent failure fallback patterns require robust error handling

3. **Integration Complexity (2/10 contribution)**:
   - Metrics collection hooks into multiple execution points (/implement and /orchestrate)
   - Agent invocation requires Task tool with precise context building
   - Score reconciliation affects Steps 1.5, 1.55, and 1.6 in implement.md

4. **Cross-Cutting Concerns (additional)**:
   - Affects both /implement and /orchestrate commands
   - Integrates with existing complexity-utils.sh (threshold-based) and complexity_estimator agent
   - Workflow metrics span multiple workflows (research, planning, implementation, debugging)

5. **Extensive Testing Requirements (additional)**:
   - Agent scoring accuracy tests (does agent improve on thresholds?)
   - Reconciliation edge cases (large score differences, low confidence, agent failures)
   - Metrics aggregation accuracy across heterogeneous log sources

---

## Architecture

### 1. Hybrid Complexity Evaluation Decision Tree

The hybrid evaluation system determines when to invoke the complexity_estimator agent:

```
┌─────────────────────────────────────────────────────┐
│ Phase Complexity Evaluation Entry Point             │
│ (implement.md Step 1.5)                             │
└───────────────────┬─────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────┐
│ Step 1: Calculate Threshold-Based Score            │
│ Function: calculate_phase_complexity()              │
│ Input: phase_name, task_list                        │
│ Output: threshold_score (0-15)                      │
└───────────────────┬─────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────┐
│ Step 2: Determine If Agent Evaluation Needed       │
│ Conditions:                                          │
│   - threshold_score >= 7 (borderline complexity)    │
│   OR                                                 │
│   - task_count >= 8 (high task count threshold)     │
└───────────────────┬─────────────────────────────────┘
                    ↓
            ┌───────┴────────┐
            ↓                ↓
   ┌────────────────┐  ┌──────────────────┐
   │ No Agent       │  │ Yes Agent        │
   │ Needed         │  │ Needed           │
   └────────┬───────┘  └────────┬─────────┘
            ↓                   ↓
   ┌────────────────┐  ┌──────────────────────────────┐
   │ Return         │  │ Step 3: Invoke Agent         │
   │ threshold_     │  │ Function: agent_based_       │
   │ score          │  │ complexity_score()           │
   └────────────────┘  │ Input: phase context JSON    │
                       │ Output: agent_score + metadata│
                       └────────┬─────────────────────┘
                                ↓
                       ┌──────────────────────────────┐
                       │ Step 4: Score Reconciliation │
                       │ Function: reconcile_scores() │
                       │ Input: threshold, agent      │
                       │ Output: final_score + method │
                       └────────┬─────────────────────┘
                                ↓
                       ┌──────────────────────────────┐
                       │ Return final_score           │
                       └──────────────────────────────┘
```

### 2. Score Reconciliation Algorithm

The reconciliation algorithm decides how to combine threshold and agent scores:

```bash
# reconcile_scores() - Core reconciliation logic
reconcile_scores() {
  local threshold_score="$1"
  local agent_score="$2"
  local agent_confidence="$3"  # high/medium/low
  local agent_reasoning="$4"

  # Calculate score difference
  local score_diff=$(awk -v t="$threshold_score" -v a="$agent_score" \
    'BEGIN {diff = (a > t ? a - t : t - a); print diff}')

  # Decision tree for reconciliation
  if awk -v d="$score_diff" 'BEGIN {exit !(d < 2.0)}'; then
    # Scores agree (difference < 2): Use threshold (faster, proven)
    RECONCILIATION_METHOD="threshold"
    FINAL_SCORE="$threshold_score"
    RECONCILIATION_REASON="Agent agrees with threshold (diff: $score_diff)"

  elif [ "$agent_confidence" = "high" ]; then
    # Scores disagree, agent highly confident: Use agent
    RECONCILIATION_METHOD="agent"
    FINAL_SCORE="$agent_score"
    RECONCILIATION_REASON="Agent high confidence overrides threshold (diff: $score_diff)"

  elif [ "$agent_confidence" = "medium" ]; then
    # Scores disagree, agent medium confidence: Average
    RECONCILIATION_METHOD="hybrid"
    FINAL_SCORE=$(awk -v t="$threshold_score" -v a="$agent_score" \
      'BEGIN {avg = (t + a) / 2.0; printf "%.1f", avg}')
    RECONCILIATION_REASON="Average of threshold and medium-confidence agent (diff: $score_diff)"

  else
    # Scores disagree, agent low confidence: Use threshold
    RECONCILIATION_METHOD="threshold_fallback"
    FINAL_SCORE="$threshold_score"
    RECONCILIATION_REASON="Agent low confidence, fallback to threshold (diff: $score_diff)"
  fi

  # Log discrepancy if significant
  if awk -v d="$score_diff" 'BEGIN {exit !(d >= 2.0)}'; then
    log_complexity_discrepancy "$PHASE_NAME" "$threshold_score" "$agent_score" \
      "$score_diff" "$agent_reasoning" "$RECONCILIATION_METHOD"
  fi

  # Return JSON result
  jq -n \
    --argjson final "$FINAL_SCORE" \
    --arg method "$RECONCILIATION_METHOD" \
    --arg reason "$RECONCILIATION_REASON" \
    --argjson threshold "$threshold_score" \
    --argjson agent "$agent_score" \
    --arg confidence "$agent_confidence" \
    '{
      final_score: $final,
      reconciliation_method: $method,
      reconciliation_reason: $reason,
      threshold_score: $threshold,
      agent_score: $agent,
      agent_confidence: $confidence
    }'
}
```

**Reconciliation Logic Summary**:

| Score Diff | Agent Confidence | Result Method         | Final Score         |
|------------|------------------|-----------------------|---------------------|
| < 2.0      | Any              | threshold             | threshold_score     |
| >= 2.0     | high             | agent                 | agent_score         |
| >= 2.0     | medium           | hybrid                | (threshold + agent) / 2 |
| >= 2.0     | low              | threshold_fallback    | threshold_score     |

### 3. Agent Invocation Pattern

Agent invocation uses the Task tool with context JSON:

```bash
# agent_based_complexity_score() - Invoke complexity_estimator agent
agent_based_complexity_score() {
  local phase_name="$1"
  local phase_content="$2"
  local plan_overview="$3"
  local plan_goals="$4"

  # Build context JSON for agent
  local context_json=$(jq -n \
    --arg phase_name "$phase_name" \
    --arg phase_content "$phase_content" \
    --arg plan_overview "$plan_overview" \
    --arg plan_goals "$plan_goals" \
    '{
      parent_plan_context: {
        overview: $plan_overview,
        goals: $plan_goals
      },
      current_structure_level: 0,
      items_to_analyze: [
        {
          item_id: "phase_evaluation",
          item_name: $phase_name,
          content: $phase_content
        }
      ]
    }')

  # Invoke complexity_estimator agent via Task tool
  local agent_response=$(claude_code_task \
    --subagent-type "general-purpose" \
    --description "Estimate phase complexity with context-aware analysis" \
    --prompt "
      Read and follow behavioral guidelines from:
      ${CLAUDE_PROJECT_DIR}/.claude/agents/complexity_estimator.md

      You are acting as a Complexity Estimator with constraints:
      - Read-only operations (tools: Read, Grep, Glob only)
      - Context-aware analysis (not just keyword matching)
      - JSON output with structured recommendations

      Analysis Task: Phase Complexity Evaluation

      Context: $context_json

      For the phase, provide: item_id, item_name, complexity_level (1-10),
      reasoning (context-aware), recommendation (expand/skip), confidence (low/medium/high).

      Output Format: JSON array
    " 2>&1)

  # Parse agent response
  local parse_status=$?
  if [ $parse_status -ne 0 ]; then
    # Agent invocation failed - return error structure
    echo '{"status":"error","error":"Agent invocation failed","agent_response":""}'
    return 1
  fi

  # Extract JSON from response (agent returns array, we want first item)
  local agent_result=$(echo "$agent_response" | jq '.[0]' 2>/dev/null)

  if [ -z "$agent_result" ] || [ "$agent_result" = "null" ]; then
    # JSON parsing failed
    echo '{"status":"error","error":"Failed to parse agent response","agent_response":""}'
    return 1
  fi

  # Extract fields
  local complexity_level=$(echo "$agent_result" | jq -r '.complexity_level // 0')
  local reasoning=$(echo "$agent_result" | jq -r '.reasoning // "No reasoning provided"')
  local confidence=$(echo "$agent_result" | jq -r '.confidence // "low"')

  # Return structured result
  jq -n \
    --arg status "success" \
    --argjson score "$complexity_level" \
    --arg reasoning "$reasoning" \
    --arg confidence "$confidence" \
    --arg raw "$agent_response" \
    '{
      status: $status,
      score: $score,
      reasoning: $reasoning,
      confidence: $confidence,
      agent_response: $raw
    }'
}
```

### 4. Workflow Metrics Collection Architecture

Workflow metrics aggregate data from multiple sources:

```
┌─────────────────────────────────────────────────────┐
│ Workflow Metrics Aggregation                        │
└─────────────────────────────────────────────────────┘
                    ↓
    ┌───────────────┴───────────────┐
    ↓                               ↓
┌───────────────────────┐   ┌──────────────────────────┐
│ adaptive-planning.log │   │ agent-registry.json      │
│ (timing, triggers)    │   │ (agent performance)      │
└───────────┬───────────┘   └──────────┬───────────────┘
            ↓                          ↓
    ┌───────────────────────────────────┐
    │ workflow-metrics.sh Aggregator    │
    │                                   │
    │ Functions:                        │
    │ - aggregate_workflow_times()      │
    │ - aggregate_agent_metrics()       │
    │ - generate_performance_report()   │
    └───────────┬───────────────────────┘
                ↓
    ┌───────────────────────────────────┐
    │ Metrics Output                    │
    │ - Total workflow duration         │
    │ - Phase breakdown (time/task)     │
    │ - Agent invocation stats          │
    │ - Success rates by agent type     │
    │ - Complexity evaluation metrics   │
    └───────────────────────────────────┘
```

**Data Points Collected**:

1. **Workflow Timing** (from adaptive-planning.log):
   - Workflow start/end timestamps
   - Phase start/end timestamps
   - Task completion times
   - Test execution duration

2. **Agent Performance** (from agent-registry.json):
   - Invocation count by agent type
   - Success rate by agent type
   - Average duration by agent type
   - Failure reasons and recovery success

3. **Complexity Metrics** (from adaptive-planning.log):
   - Threshold score distribution
   - Agent invocation frequency
   - Score reconciliation methods used
   - Complexity discrepancies (threshold vs agent)

4. **Adaptive Planning Events** (from adaptive-planning.log):
   - Replan triggers (complexity, test failure, scope drift)
   - Expansion recommendations (accepted/rejected)
   - Collapse triggers and outcomes

### 5. Integration with implement.md Steps

**Step 1.5: Hybrid Complexity Evaluation** (NEW)

```markdown
### 1.5. Hybrid Complexity Evaluation

Evaluate phase complexity using hybrid approach (threshold + agent for borderline cases).

**Workflow**:

1. **Calculate threshold-based score**:
   ```bash
   THRESHOLD_SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$TASK_LIST")
   TASK_COUNT=$(echo "$TASK_LIST" | grep -c "^- \[ \]" || echo "0")
   ```

2. **Determine if agent evaluation needed**:
   ```bash
   AGENT_NEEDED="false"
   if [ "$THRESHOLD_SCORE" -ge 7 ] || [ "$TASK_COUNT" -ge 8 ]; then
     AGENT_NEEDED="true"
   fi
   ```

3. **Invoke agent if needed**:
   ```bash
   if [ "$AGENT_NEEDED" = "true" ]; then
     # Extract plan context
     PLAN_OVERVIEW=$(grep -A 5 "^## Overview" "$PLAN_FILE" | tail -n +2)
     PLAN_GOALS=$(grep -A 5 "^## Success Criteria" "$PLAN_FILE" | tail -n +2)
     PHASE_CONTENT=$(extract_phase_content "$PLAN_FILE" "$CURRENT_PHASE")

     # Invoke complexity_estimator agent
     AGENT_RESULT=$(agent_based_complexity_score "$PHASE_NAME" "$PHASE_CONTENT" \
       "$PLAN_OVERVIEW" "$PLAN_GOALS")

     AGENT_STATUS=$(echo "$AGENT_RESULT" | jq -r '.status')

     if [ "$AGENT_STATUS" = "success" ]; then
       AGENT_SCORE=$(echo "$AGENT_RESULT" | jq -r '.score')
       AGENT_CONFIDENCE=$(echo "$AGENT_RESULT" | jq -r '.confidence')
       AGENT_REASONING=$(echo "$AGENT_RESULT" | jq -r '.reasoning')

       # Reconcile scores
       RECONCILIATION=$(reconcile_scores "$THRESHOLD_SCORE" "$AGENT_SCORE" \
         "$AGENT_CONFIDENCE" "$AGENT_REASONING")

       COMPLEXITY_SCORE=$(echo "$RECONCILIATION" | jq -r '.final_score')
       EVALUATION_METHOD=$(echo "$RECONCILIATION" | jq -r '.reconciliation_method')

       # Log hybrid evaluation
       log_complexity_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" \
         "$COMPLEXITY_THRESHOLD_HIGH" "true"
       echo "Complexity Score: $COMPLEXITY_SCORE ($EVALUATION_METHOD)"
       echo "Agent Reasoning: $AGENT_REASONING"
     else
       # Agent failed - fallback to threshold
       COMPLEXITY_SCORE="$THRESHOLD_SCORE"
       EVALUATION_METHOD="threshold_fallback"
       AGENT_ERROR=$(echo "$AGENT_RESULT" | jq -r '.error')

       log_agent_failure "complexity_estimator" "$AGENT_ERROR"
       echo "⚠ Agent evaluation failed, using threshold score: $COMPLEXITY_SCORE"
     fi
   else
     # Agent not needed - use threshold
     COMPLEXITY_SCORE="$THRESHOLD_SCORE"
     EVALUATION_METHOD="threshold"
     echo "Complexity Score: $COMPLEXITY_SCORE (threshold-only)"
   fi
   ```

4. **Use score for downstream decisions**:
   - Step 1.55 (Proactive Expansion): Uses COMPLEXITY_SCORE
   - Step 1.6 (Agent Selection): Uses COMPLEXITY_SCORE for thresholds

**Expected Impact**: 30% reduction in expansion errors via context-aware evaluation
```

**Step 1.55 Update** (minor change):

```markdown
### 1.55. Proactive Expansion Check

Before implementation, evaluate if phase should be expanded using agent-based judgment.

**Note**: This step uses the hybrid complexity score from Step 1.5.

[Rest of Step 1.55 unchanged]
```

**Step 1.6 Update** (minor change):

```markdown
### 1.6. Parallel Wave Execution

[...]

**Agent selection thresholds** (using hybrid complexity score from Step 1.5):
- **Direct execution** (score 0-2): Simple phases
- **code-writer** (score 3-5): Medium complexity
- **code-writer + think** (score 6-7): Medium-high complexity
- **code-writer + think hard** (score 8-9): High complexity
- **code-writer + think harder** (score 10+): Critical complexity

[Rest of Step 1.6 unchanged]
```

---

## Implementation Steps

### Task 1: Verify complexity_estimator Agent

**Objective**: Ensure complexity_estimator agent exists and is functional

**Location**: `/home/benjamin/.config/.claude/agents/complexity_estimator.md`

**Steps**:

1. Check if agent file exists:
   ```bash
   if [ ! -f "${CLAUDE_PROJECT_DIR}/.claude/agents/complexity_estimator.md" ]; then
     echo "Agent file missing, creating..."
   fi
   ```

2. Test invocation with sample phase:
   ```bash
   # Create minimal test context
   TEST_CONTEXT='{"parent_plan_context":{"overview":"Test plan","goals":"Test goals"},"current_structure_level":0,"items_to_analyze":[{"item_id":"test","item_name":"Test Phase","content":"Simple test phase with 3 tasks"}]}'

   # Invoke agent (behavioral injection pattern)
   RESULT=$(claude_code_task \
     --subagent-type "general-purpose" \
     --description "Test complexity estimator" \
     --prompt "Read behavioral guidelines from .claude/agents/complexity_estimator.md. Analyze: $TEST_CONTEXT" \
     2>&1)

   # Check if response is valid JSON array
   echo "$RESULT" | jq '.[0].complexity_level' >/dev/null 2>&1
   if [ $? -ne 0 ]; then
     echo "❌ Agent test failed: Invalid response format"
   else
     echo "✓ Agent test passed"
   fi
   ```

3. If agent missing or non-functional, create basic version:
   ```markdown
   ---
   allowed-tools: Read, Grep, Glob
   description: Estimates plan/phase/stage complexity with context awareness
   ---

   # Complexity Estimator Agent

   I analyze implementation plan complexity considering architectural significance,
   integration complexity, and implementation uncertainty.

   ## Output Format
   ```json
   [
     {
       "item_id": "phase_N",
       "item_name": "Phase Name",
       "complexity_level": 1-10,
       "reasoning": "detailed explanation",
       "recommendation": "expand|skip",
       "confidence": "low|medium|high"
     }
   ]
   ```

   ## Complexity Scoring (1-10)
   - 1-3: Simple, well-established tasks
   - 4-6: Moderate challenges, clear implementation path
   - 7-8: Significant architectural/integration challenges
   - 9-10: Critical, complex, high-risk implementations
   ```

**Expected Output**: Agent file exists and responds with valid JSON

---

### Task 2: Add agent_based_complexity_score() to complexity-utils.sh

**Objective**: Implement agent invocation function with robust error handling

**Location**: `/home/benjamin/.config/.claude/lib/complexity-utils.sh`

**Implementation**:

Add after `calculate_phase_complexity()` function:

```bash
# agent_based_complexity_score: Invoke complexity_estimator agent for context-aware analysis
# Usage: agent_based_complexity_score <phase-name> <phase-content> <plan-overview> <plan-goals>
# Returns: JSON with status, score, reasoning, confidence
# Example: agent_based_complexity_score "Phase 3" "$CONTENT" "$OVERVIEW" "$GOALS"
agent_based_complexity_score() {
  local phase_name="${1:-}"
  local phase_content="${2:-}"
  local plan_overview="${3:-}"
  local plan_goals="${4:-}"

  if [ -z "$phase_name" ] || [ -z "$phase_content" ]; then
    echo '{"status":"error","error":"Missing required parameters"}'
    return 1
  fi

  # Check if agent file exists
  local agent_file="${CLAUDE_PROJECT_DIR}/.claude/agents/complexity_estimator.md"
  if [ ! -f "$agent_file" ]; then
    echo '{"status":"error","error":"complexity_estimator.md not found"}'
    return 1
  fi

  # Build context JSON for agent
  local context_json=$(jq -n \
    --arg phase_name "$phase_name" \
    --arg phase_content "$phase_content" \
    --arg plan_overview "$plan_overview" \
    --arg plan_goals "$plan_goals" \
    '{
      parent_plan_context: {
        overview: $plan_overview,
        goals: $plan_goals
      },
      current_structure_level: 0,
      items_to_analyze: [
        {
          item_id: "phase_evaluation",
          item_name: $phase_name,
          content: $phase_content
        }
      ]
    }')

  # Invoke agent with timeout (60 seconds)
  local agent_response
  agent_response=$(timeout 60 claude_code_task \
    --subagent-type "general-purpose" \
    --description "Estimate phase complexity with context-aware analysis" \
    --prompt "
      Read and follow behavioral guidelines from:
      ${agent_file}

      You are acting as a Complexity Estimator with constraints:
      - Read-only operations (tools: Read, Grep, Glob only)
      - Context-aware analysis (not just keyword matching)
      - JSON output with structured recommendations

      Analysis Task: Phase Complexity Evaluation

      Context: $context_json

      For the phase, provide: item_id, item_name, complexity_level (1-10),
      reasoning (context-aware), recommendation (expand/skip), confidence (low/medium/high).

      Output Format: JSON array
    " 2>&1)

  local exit_code=$?

  # Check for timeout
  if [ $exit_code -eq 124 ]; then
    echo '{"status":"error","error":"Agent invocation timed out (60s)"}'
    return 1
  fi

  # Check for other invocation errors
  if [ $exit_code -ne 0 ]; then
    local error_msg=$(echo "$agent_response" | tail -1)
    jq -n --arg error "$error_msg" '{"status":"error","error":$error}'
    return 1
  fi

  # Extract JSON from response (agent returns array, we want first item)
  local agent_result
  agent_result=$(echo "$agent_response" | jq '.[0]' 2>/dev/null)

  if [ -z "$agent_result" ] || [ "$agent_result" = "null" ]; then
    echo '{"status":"error","error":"Failed to parse agent response as JSON array"}'
    return 1
  fi

  # Validate required fields
  local complexity_level=$(echo "$agent_result" | jq -r '.complexity_level // "null"')
  local reasoning=$(echo "$agent_result" | jq -r '.reasoning // "null"')
  local confidence=$(echo "$agent_result" | jq -r '.confidence // "null"')

  if [ "$complexity_level" = "null" ] || [ "$reasoning" = "null" ] || [ "$confidence" = "null" ]; then
    echo '{"status":"error","error":"Agent response missing required fields"}'
    return 1
  fi

  # Validate complexity_level range (1-10)
  if ! [[ "$complexity_level" =~ ^[0-9]+$ ]] || [ "$complexity_level" -lt 1 ] || [ "$complexity_level" -gt 10 ]; then
    echo '{"status":"error","error":"Agent complexity_level out of range (1-10)"}'
    return 1
  fi

  # Return structured result
  jq -n \
    --arg status "success" \
    --argjson score "$complexity_level" \
    --arg reasoning "$reasoning" \
    --arg confidence "$confidence" \
    --arg raw "$agent_response" \
    '{
      status: $status,
      score: $score,
      reasoning: $reasoning,
      confidence: $confidence,
      agent_response: $raw
    }'
}
```

**Testing**:

```bash
# Test with valid phase
RESULT=$(agent_based_complexity_score "Test Phase" "Simple tasks: 1, 2, 3" "Test Plan" "Test Goals")
echo "$RESULT" | jq '.status'  # Should be "success"
echo "$RESULT" | jq '.score'   # Should be 1-10

# Test with missing parameters
RESULT=$(agent_based_complexity_score "" "" "" "")
echo "$RESULT" | jq '.status'  # Should be "error"

# Test with agent timeout (mock by making agent unresponsive)
# [Implementation-specific timeout test]
```

**Expected Output**: Function returns JSON with status, score, reasoning, confidence

---

### Task 3: Add reconcile_scores() to complexity-utils.sh

**Objective**: Implement score reconciliation with confidence-based decision logic

**Location**: `/home/benjamin/.config/.claude/lib/complexity-utils.sh`

**Implementation**:

Add after `agent_based_complexity_score()`:

```bash
# reconcile_scores: Reconcile threshold and agent scores using confidence
# Usage: reconcile_scores <threshold-score> <agent-score> <agent-confidence> <agent-reasoning>
# Returns: JSON with final_score, reconciliation_method, reconciliation_reason
# Example: reconcile_scores 8 5 "high" "Agent reasoning text"
reconcile_scores() {
  local threshold_score="$1"
  local agent_score="$2"
  local agent_confidence="$3"
  local agent_reasoning="${4:-No reasoning provided}"

  # Validate inputs
  if [ -z "$threshold_score" ] || [ -z "$agent_score" ] || [ -z "$agent_confidence" ]; then
    echo '{"error":"Missing required parameters for score reconciliation"}'
    return 1
  fi

  # Calculate absolute score difference
  local score_diff
  score_diff=$(awk -v t="$threshold_score" -v a="$agent_score" \
    'BEGIN {diff = (a > t ? a - t : t - a); printf "%.1f", diff}')

  # Decision variables
  local reconciliation_method
  local final_score
  local reconciliation_reason

  # Decision tree for reconciliation
  if awk -v d="$score_diff" 'BEGIN {exit !(d < 2.0)}'; then
    # Scores agree (difference < 2): Use threshold (faster, proven)
    reconciliation_method="threshold"
    final_score="$threshold_score"
    reconciliation_reason="Agent agrees with threshold (diff: $score_diff)"

  elif [ "$agent_confidence" = "high" ]; then
    # Scores disagree, agent highly confident: Use agent
    reconciliation_method="agent"
    final_score="$agent_score"
    reconciliation_reason="Agent high confidence overrides threshold (diff: $score_diff)"

  elif [ "$agent_confidence" = "medium" ]; then
    # Scores disagree, agent medium confidence: Average
    reconciliation_method="hybrid"
    final_score=$(awk -v t="$threshold_score" -v a="$agent_score" \
      'BEGIN {avg = (t + a) / 2.0; printf "%.1f", avg}')
    reconciliation_reason="Average of threshold and medium-confidence agent (diff: $score_diff)"

  else
    # Scores disagree, agent low confidence: Use threshold
    reconciliation_method="threshold_fallback"
    final_score="$threshold_score"
    reconciliation_reason="Agent low confidence, fallback to threshold (diff: $score_diff)"
  fi

  # Build JSON response
  if command -v jq &> /dev/null; then
    jq -n \
      --argjson final "$final_score" \
      --arg method "$reconciliation_method" \
      --arg reason "$reconciliation_reason" \
      --argjson threshold "$threshold_score" \
      --argjson agent "$agent_score" \
      --arg confidence "$agent_confidence" \
      --argjson diff "$score_diff" \
      '{
        final_score: $final,
        reconciliation_method: $method,
        reconciliation_reason: $reason,
        threshold_score: $threshold,
        agent_score: $agent,
        agent_confidence: $confidence,
        score_difference: $diff
      }'
  else
    cat <<EOF
{
  "final_score": $final_score,
  "reconciliation_method": "$reconciliation_method",
  "reconciliation_reason": "$reconciliation_reason",
  "threshold_score": $threshold_score,
  "agent_score": $agent_score,
  "agent_confidence": "$agent_confidence",
  "score_difference": $score_diff
}
EOF
  fi
}
```

**Testing**:

```bash
# Test: Scores agree (diff < 2)
RESULT=$(reconcile_scores 5 6 "high" "Test reasoning")
echo "$RESULT" | jq '.reconciliation_method'  # Should be "threshold"
echo "$RESULT" | jq '.final_score'           # Should be 5

# Test: Scores disagree, high confidence
RESULT=$(reconcile_scores 3 8 "high" "Test reasoning")
echo "$RESULT" | jq '.reconciliation_method'  # Should be "agent"
echo "$RESULT" | jq '.final_score'           # Should be 8

# Test: Scores disagree, medium confidence
RESULT=$(reconcile_scores 4 8 "medium" "Test reasoning")
echo "$RESULT" | jq '.reconciliation_method'  # Should be "hybrid"
echo "$RESULT" | jq '.final_score'           # Should be 6.0 (average)

# Test: Scores disagree, low confidence
RESULT=$(reconcile_scores 5 9 "low" "Test reasoning")
echo "$RESULT" | jq '.reconciliation_method'  # Should be "threshold_fallback"
echo "$RESULT" | jq '.final_score'           # Should be 5
```

**Expected Output**: Function returns JSON with reconciliation decision

---

### Task 4: Add hybrid_complexity_evaluation() Wrapper

**Objective**: Create convenience function combining threshold + agent + reconciliation

**Location**: `/home/benjamin/.config/.claude/lib/complexity-utils.sh`

**Implementation**:

```bash
# hybrid_complexity_evaluation: Complete hybrid evaluation workflow
# Usage: hybrid_complexity_evaluation <phase-name> <task-list> <plan-file>
# Returns: JSON with final_score, evaluation_method, reasoning
# Example: hybrid_complexity_evaluation "Phase 3" "$TASKS" "plan.md"
hybrid_complexity_evaluation() {
  local phase_name="${1:-}"
  local task_list="${2:-}"
  local plan_file="${3:-}"

  # Step 1: Calculate threshold-based score
  local threshold_score
  threshold_score=$(calculate_phase_complexity "$phase_name" "$task_list")

  local task_count
  task_count=$(echo "$task_list" | grep -c "^- \[ \]" || echo "0")

  # Step 2: Determine if agent evaluation needed
  local agent_needed="false"
  if [ "$threshold_score" -ge 7 ] || [ "$task_count" -ge 8 ]; then
    agent_needed="true"
  fi

  # Step 3: Invoke agent if needed
  if [ "$agent_needed" = "true" ]; then
    # Extract plan context
    local plan_overview=""
    local plan_goals=""

    if [ -f "$plan_file" ]; then
      plan_overview=$(sed -n '/^## Overview$/,/^##/p' "$plan_file" | sed '$d' | tail -n +2)
      plan_goals=$(sed -n '/^## Success Criteria$/,/^##/p' "$plan_file" | sed '$d' | tail -n +2)
    fi

    # Build phase content from task list
    local phase_content="$task_list"

    # Invoke agent
    local agent_result
    agent_result=$(agent_based_complexity_score "$phase_name" "$phase_content" \
      "$plan_overview" "$plan_goals")

    local agent_status
    agent_status=$(echo "$agent_result" | jq -r '.status')

    if [ "$agent_status" = "success" ]; then
      # Agent succeeded - reconcile scores
      local agent_score
      agent_score=$(echo "$agent_result" | jq -r '.score')

      local agent_confidence
      agent_confidence=$(echo "$agent_result" | jq -r '.confidence')

      local agent_reasoning
      agent_reasoning=$(echo "$agent_result" | jq -r '.reasoning')

      # Reconcile
      local reconciliation
      reconciliation=$(reconcile_scores "$threshold_score" "$agent_score" \
        "$agent_confidence" "$agent_reasoning")

      local final_score
      final_score=$(echo "$reconciliation" | jq -r '.final_score')

      local evaluation_method
      evaluation_method=$(echo "$reconciliation" | jq -r '.reconciliation_method')

      # Return result
      jq -n \
        --argjson score "$final_score" \
        --arg method "$evaluation_method" \
        --arg reasoning "$agent_reasoning" \
        --argjson reconciliation "$reconciliation" \
        '{
          final_score: $score,
          evaluation_method: $method,
          agent_reasoning: $reasoning,
          reconciliation_details: $reconciliation
        }'
    else
      # Agent failed - fallback to threshold
      local agent_error
      agent_error=$(echo "$agent_result" | jq -r '.error')

      jq -n \
        --argjson score "$threshold_score" \
        --arg method "threshold_fallback" \
        --arg error "$agent_error" \
        '{
          final_score: $score,
          evaluation_method: $method,
          agent_error: $error
        }'
    fi
  else
    # Agent not needed - use threshold only
    jq -n \
      --argjson score "$threshold_score" \
      --arg method "threshold" \
      '{
        final_score: $score,
        evaluation_method: $method
      }'
  fi
}
```

**Expected Output**: One-function call for complete hybrid evaluation

---

### Task 5: Add Step 1.5 to implement.md

**Objective**: Insert hybrid complexity evaluation before Step 1.55

**Location**: `/home/benjamin/.config/.claude/commands/implement.md`

**Implementation**:

Locate Step 1.4 "Check Expansion Status" and insert after it:

```markdown
### 1.5. Hybrid Complexity Evaluation

Evaluate phase complexity using hybrid approach (threshold + agent for borderline cases).

**Workflow**:

1. **Calculate threshold-based score**:
   ```bash
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/complexity-utils.sh"

   THRESHOLD_SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$TASK_LIST")
   TASK_COUNT=$(echo "$TASK_LIST" | grep -c "^- \[ \]" || echo "0")
   ```

2. **Determine if agent evaluation needed**:
   ```bash
   AGENT_NEEDED="false"
   if [ "$THRESHOLD_SCORE" -ge 7 ] || [ "$TASK_COUNT" -ge 8 ]; then
     AGENT_NEEDED="true"
     echo "Borderline complexity detected (score: $THRESHOLD_SCORE, tasks: $TASK_COUNT)"
     echo "Invoking complexity_estimator agent for context-aware analysis..."
   fi
   ```

3. **Run hybrid evaluation**:
   ```bash
   EVALUATION_RESULT=$(hybrid_complexity_evaluation "$PHASE_NAME" "$TASK_LIST" "$PLAN_FILE")

   COMPLEXITY_SCORE=$(echo "$EVALUATION_RESULT" | jq -r '.final_score')
   EVALUATION_METHOD=$(echo "$EVALUATION_RESULT" | jq -r '.evaluation_method')

   echo "Complexity Score: $COMPLEXITY_SCORE ($EVALUATION_METHOD)"

   # If agent was used, display reasoning
   if [ "$AGENT_NEEDED" = "true" ]; then
     AGENT_REASONING=$(echo "$EVALUATION_RESULT" | jq -r '.agent_reasoning // "N/A"')
     if [ "$AGENT_REASONING" != "N/A" ]; then
       echo "Agent Reasoning: $AGENT_REASONING"
     fi

     # Check for agent errors
     AGENT_ERROR=$(echo "$EVALUATION_RESULT" | jq -r '.agent_error // "null"')
     if [ "$AGENT_ERROR" != "null" ]; then
       echo "⚠ Agent evaluation failed: $AGENT_ERROR"
       echo "  Falling back to threshold score: $COMPLEXITY_SCORE"
     fi
   fi
   ```

4. **Log evaluation for analytics**:
   ```bash
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/adaptive-planning-logger.sh"

   log_complexity_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" \
     "$COMPLEXITY_THRESHOLD_HIGH" "$([ $AGENT_NEEDED = 'true' ] && echo 'true' || echo 'false')"

   # If score reconciliation occurred, log discrepancy details
   if [ "$EVALUATION_METHOD" != "threshold" ]; then
     THRESHOLD_SCORE=$(echo "$EVALUATION_RESULT" | jq -r '.reconciliation_details.threshold_score // 0')
     AGENT_SCORE=$(echo "$EVALUATION_RESULT" | jq -r '.reconciliation_details.agent_score // 0')
     SCORE_DIFF=$(echo "$EVALUATION_RESULT" | jq -r '.reconciliation_details.score_difference // 0')

     log_complexity_discrepancy "$PHASE_NAME" "$THRESHOLD_SCORE" "$AGENT_SCORE" \
       "$SCORE_DIFF" "$AGENT_REASONING" "$EVALUATION_METHOD"
   fi
   ```

5. **Use score for downstream decisions**:
   - Export COMPLEXITY_SCORE for Steps 1.55 (Proactive Expansion) and 1.6 (Agent Selection)
   ```bash
   export COMPLEXITY_SCORE
   export EVALUATION_METHOD
   ```

**Expected Impact**: 30% reduction in expansion errors via context-aware evaluation

**Error Handling**:
- Agent timeout (60s): Fallback to threshold score
- Agent invocation failure: Fallback to threshold score
- Invalid agent response: Fallback to threshold score
- All fallbacks logged for improvement tracking
```

**Update Steps 1.55 and 1.6**:

In Step 1.55, add note at the top:
```markdown
**Note**: This step uses the hybrid complexity score ($COMPLEXITY_SCORE) from Step 1.5.
```

In Step 1.6, update agent selection thresholds section:
```markdown
**Agent selection thresholds** (using hybrid complexity score from Step 1.5):
```

**Expected Output**: Step 1.5 added, downstream steps reference hybrid score

---

### Task 6: Add log_complexity_discrepancy() to adaptive-planning-logger.sh

**Objective**: Log score discrepancies for threshold accuracy analysis

**Location**: `/home/benjamin/.config/.claude/lib/adaptive-planning-logger.sh`

**Implementation**:

Add new logging function:

```bash
# log_complexity_discrepancy: Log threshold vs agent score differences
# Usage: log_complexity_discrepancy <phase> <threshold-score> <agent-score> <diff> <reasoning> <method>
# Example: log_complexity_discrepancy "Phase 3" 5 9 4.0 "Agent reasoning" "agent"
log_complexity_discrepancy() {
  local phase="$1"
  local threshold_score="$2"
  local agent_score="$3"
  local score_diff="$4"
  local agent_reasoning="${5:-}"
  local reconciliation_method="${6:-}"

  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  # Build log entry
  local log_entry=$(cat <<EOF
[$timestamp] COMPLEXITY_DISCREPANCY:
  Phase: $phase
  Threshold Score: $threshold_score
  Agent Score: $agent_score
  Difference: $score_diff
  Reconciliation Method: $reconciliation_method
  Agent Reasoning: $agent_reasoning
EOF
)

  # Append to log file
  echo "$log_entry" >> "${ADAPTIVE_PLANNING_LOG}"

  # Log to stdout if verbose
  if [ "${VERBOSE:-0}" = "1" ]; then
    echo "$log_entry"
  fi
}
```

**Export function**:

Add to export section at bottom of file:
```bash
export -f log_complexity_discrepancy
```

**Testing**:

```bash
source .claude/lib/adaptive-planning-logger.sh

log_complexity_discrepancy "Phase 3" 5 9 4.0 "High integration complexity not captured by thresholds" "agent"

# Verify log entry
tail -n 10 .claude/logs/adaptive-planning.log | grep "COMPLEXITY_DISCREPANCY"
```

**Expected Output**: Discrepancy logged for future analysis

---

### Task 7: Create workflow-metrics.sh Utility

**Objective**: Aggregate metrics from logs and registry

**Location**: `/home/benjamin/.config/.claude/lib/workflow-metrics.sh`

**Implementation**:

```bash
#!/usr/bin/env bash
# Workflow metrics aggregation utility
# Aggregates data from adaptive-planning.log and agent-registry.json

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/detect-project-dir.sh"

# ==============================================================================
# Workflow Time Aggregation
# ==============================================================================

# aggregate_workflow_times: Extract timing data from adaptive-planning.log
# Usage: aggregate_workflow_times
# Returns: JSON with workflow timing metrics
aggregate_workflow_times() {
  local log_file="${CLAUDE_PROJECT_DIR}/.claude/logs/adaptive-planning.log"

  if [ ! -f "$log_file" ]; then
    echo '{"error":"Log file not found"}'
    return 1
  fi

  # Extract workflow start/end timestamps (simplified - real implementation needs parsing)
  local workflow_start=$(grep "WORKFLOW_START" "$log_file" | tail -1 | awk '{print $1" "$2}')
  local workflow_end=$(grep "WORKFLOW_END" "$log_file" | tail -1 | awk '{print $1" "$2}')

  # Calculate duration (requires date manipulation - simplified here)
  local duration_seconds=0
  if [ -n "$workflow_start" ] && [ -n "$workflow_end" ]; then
    local start_epoch=$(date -d "$workflow_start" +%s 2>/dev/null || echo "0")
    local end_epoch=$(date -d "$workflow_end" +%s 2>/dev/null || echo "0")
    duration_seconds=$((end_epoch - start_epoch))
  fi

  # Count phases
  local total_phases=$(grep -c "PHASE_START" "$log_file" || echo "0")
  local completed_phases=$(grep -c "PHASE_COMPLETE" "$log_file" || echo "0")

  # Average time per phase
  local avg_phase_time=0
  if [ "$completed_phases" -gt 0 ]; then
    avg_phase_time=$((duration_seconds / completed_phases))
  fi

  # Build JSON
  jq -n \
    --argjson duration "$duration_seconds" \
    --argjson total "$total_phases" \
    --argjson completed "$completed_phases" \
    --argjson avg "$avg_phase_time" \
    '{
      workflow_duration_seconds: $duration,
      total_phases: $total,
      completed_phases: $completed,
      avg_phase_time_seconds: $avg
    }'
}

# ==============================================================================
# Agent Metrics Aggregation
# ==============================================================================

# aggregate_agent_metrics: Extract agent performance from agent-registry.json
# Usage: aggregate_agent_metrics
# Returns: JSON with agent invocation statistics
aggregate_agent_metrics() {
  local registry_file="${CLAUDE_PROJECT_DIR}/.claude/agents/agent-registry.json"

  if [ ! -f "$registry_file" ]; then
    echo '{"error":"Agent registry not found"}'
    return 1
  fi

  # Extract agent metrics using jq
  jq '{
    total_agents: (.agents | length),
    agent_summary: [
      .agents | to_entries[] | {
        agent_type: .key,
        invocations: .value.invocations,
        successes: .value.successes,
        failures: .value.failures,
        success_rate: (if .value.invocations > 0 then (.value.successes / .value.invocations * 100) else 0 end),
        avg_duration: .value.avg_duration
      }
    ]
  }' "$registry_file"
}

# ==============================================================================
# Complexity Metrics Aggregation
# ==============================================================================

# aggregate_complexity_metrics: Extract complexity evaluation stats from log
# Usage: aggregate_complexity_metrics
# Returns: JSON with complexity evaluation statistics
aggregate_complexity_metrics() {
  local log_file="${CLAUDE_PROJECT_DIR}/.claude/logs/adaptive-planning.log"

  if [ ! -f "$log_file" ]; then
    echo '{"error":"Log file not found"}'
    return 1
  fi

  # Count evaluation methods
  local threshold_only=$(grep -c "evaluation_method.*threshold\"" "$log_file" 2>/dev/null || echo "0")
  local agent_used=$(grep -c "evaluation_method.*agent\"" "$log_file" 2>/dev/null || echo "0")
  local hybrid_used=$(grep -c "evaluation_method.*hybrid\"" "$log_file" 2>/dev/null || echo "0")

  # Count discrepancies
  local discrepancies=$(grep -c "COMPLEXITY_DISCREPANCY" "$log_file" 2>/dev/null || echo "0")

  # Total evaluations
  local total_evaluations=$((threshold_only + agent_used + hybrid_used))

  # Build JSON
  jq -n \
    --argjson total "$total_evaluations" \
    --argjson threshold "$threshold_only" \
    --argjson agent "$agent_used" \
    --argjson hybrid "$hybrid_used" \
    --argjson discrepancies "$discrepancies" \
    '{
      total_evaluations: $total,
      threshold_only: $threshold,
      agent_overrides: $agent,
      hybrid_averages: $hybrid,
      score_discrepancies: $discrepancies,
      agent_invocation_rate: (if $total > 0 then (($agent + $hybrid) / $total * 100) else 0 end)
    }'
}

# ==============================================================================
# Performance Report Generation
# ==============================================================================

# generate_performance_report: Create markdown performance report
# Usage: generate_performance_report
# Returns: Markdown formatted report
generate_performance_report() {
  local workflow_metrics
  workflow_metrics=$(aggregate_workflow_times)

  local agent_metrics
  agent_metrics=$(aggregate_agent_metrics)

  local complexity_metrics
  complexity_metrics=$(aggregate_complexity_metrics)

  # Extract values
  local duration=$(echo "$workflow_metrics" | jq -r '.workflow_duration_seconds // 0')
  local total_phases=$(echo "$workflow_metrics" | jq -r '.total_phases // 0')
  local completed_phases=$(echo "$workflow_metrics" | jq -r '.completed_phases // 0')

  local total_agents=$(echo "$agent_metrics" | jq -r '.total_agents // 0')
  local agent_summary=$(echo "$agent_metrics" | jq -r '.agent_summary // []')

  local total_evals=$(echo "$complexity_metrics" | jq -r '.total_evaluations // 0')
  local agent_rate=$(echo "$complexity_metrics" | jq -r '.agent_invocation_rate // 0')

  # Generate markdown report
  cat <<EOF
# Workflow Performance Report

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')

## Workflow Summary

- **Total Duration**: ${duration}s ($(($duration / 60))m $(($duration % 60))s)
- **Phases**: $completed_phases / $total_phases completed
- **Average Phase Time**: $(echo "$workflow_metrics" | jq -r '.avg_phase_time_seconds')s

## Agent Performance

- **Total Agents Used**: $total_agents
- **Agent Invocation Summary**:

$(echo "$agent_summary" | jq -r '.[] | "  - **\(.agent_type)**: \(.invocations) invocations, \(.success_rate | floor)% success rate, \(.avg_duration)s avg"')

## Complexity Evaluation

- **Total Evaluations**: $total_evals
- **Agent Invocation Rate**: ${agent_rate}%
- **Threshold-Only**: $(echo "$complexity_metrics" | jq -r '.threshold_only')
- **Agent Overrides**: $(echo "$complexity_metrics" | jq -r '.agent_overrides')
- **Hybrid Averages**: $(echo "$complexity_metrics" | jq -r '.hybrid_averages')
- **Score Discrepancies**: $(echo "$complexity_metrics" | jq -r '.score_discrepancies')

---

*Report generated by workflow-metrics.sh*
EOF
}

# ==============================================================================
# Export Functions
# ==============================================================================

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f aggregate_workflow_times
  export -f aggregate_agent_metrics
  export -f aggregate_complexity_metrics
  export -f generate_performance_report
fi
```

**Testing**:

```bash
source .claude/lib/workflow-metrics.sh

# Test individual aggregators
aggregate_workflow_times | jq .
aggregate_agent_metrics | jq .
aggregate_complexity_metrics | jq .

# Generate full report
generate_performance_report
```

**Expected Output**: Comprehensive metrics report

---

## Testing Specifications

### Test File 1: test_hybrid_complexity.sh

**Location**: `/home/benjamin/.config/.claude/tests/test_hybrid_complexity.sh`

**Test Cases**:

```bash
#!/usr/bin/env bash
# Test hybrid complexity evaluation

source "$(dirname "$0")/../lib/complexity-utils.sh"

test_threshold_only_scoring() {
  # Low complexity phase - agent should not be invoked
  local phase_name="Simple Configuration"
  local task_list="- [ ] Update config\n- [ ] Restart service\n- [ ] Verify"

  local result=$(hybrid_complexity_evaluation "$phase_name" "$task_list" "")
  local method=$(echo "$result" | jq -r '.evaluation_method')

  [[ "$method" = "threshold" ]] || {
    echo "FAIL: Expected threshold-only, got $method"
    return 1
  }

  echo "PASS: Threshold-only scoring"
}

test_agent_invocation_borderline() {
  # Borderline complexity - agent should be invoked
  local phase_name="Core State Management Refactor"
  local task_list=$(cat <<EOF
- [ ] Design state management architecture
- [ ] Implement state store module
- [ ] Integrate with auth system
- [ ] Add cache layer
- [ ] Handle concurrency
- [ ] Security audit
- [ ] Performance testing
- [ ] Integration testing
EOF
)

  local result=$(hybrid_complexity_evaluation "$phase_name" "$task_list" "test_plan.md")
  local method=$(echo "$result" | jq -r '.evaluation_method')

  [[ "$method" != "threshold" ]] || {
    echo "FAIL: Expected agent invocation for borderline case, got threshold-only"
    return 1
  }

  echo "PASS: Agent invoked for borderline complexity"
}

test_score_reconciliation_agent_agrees() {
  # Test reconciliation when scores are close (diff < 2)
  local reconciliation=$(reconcile_scores 7 8 "high" "Test reasoning")
  local method=$(echo "$reconciliation" | jq -r '.reconciliation_method')
  local final_score=$(echo "$reconciliation" | jq -r '.final_score')

  [[ "$method" = "threshold" ]] || {
    echo "FAIL: Expected threshold when scores agree, got $method"
    return 1
  }

  [[ "$final_score" = "7" ]] || {
    echo "FAIL: Expected threshold score 7, got $final_score"
    return 1
  }

  echo "PASS: Score reconciliation - agent agrees"
}

test_score_reconciliation_agent_overrides() {
  # Test reconciliation when scores differ significantly and agent confident
  local reconciliation=$(reconcile_scores 3 9 "high" "Significant architectural complexity")
  local method=$(echo "$reconciliation" | jq -r '.reconciliation_method')
  local final_score=$(echo "$reconciliation" | jq -r '.final_score')

  [[ "$method" = "agent" ]] || {
    echo "FAIL: Expected agent override, got $method"
    return 1
  }

  [[ "$final_score" = "9" ]] || {
    echo "FAIL: Expected agent score 9, got $final_score"
    return 1
  }

  echo "PASS: Score reconciliation - agent overrides"
}

test_score_reconciliation_hybrid_average() {
  # Test reconciliation when scores differ and agent medium confidence
  local reconciliation=$(reconcile_scores 4 8 "medium" "Moderate disagreement")
  local method=$(echo "$reconciliation" | jq -r '.reconciliation_method')
  local final_score=$(echo "$reconciliation" | jq -r '.final_score')

  [[ "$method" = "hybrid" ]] || {
    echo "FAIL: Expected hybrid averaging, got $method"
    return 1
  }

  # Check if final_score is 6.0 (average of 4 and 8)
  [[ "$final_score" = "6.0" ]] || {
    echo "FAIL: Expected average 6.0, got $final_score"
    return 1
  }

  echo "PASS: Score reconciliation - hybrid average"
}

test_agent_failure_fallback() {
  # Test fallback to threshold when agent fails
  # (Mock agent failure by providing invalid agent function)

  # Temporarily override agent function to simulate failure
  agent_based_complexity_score() {
    echo '{"status":"error","error":"Simulated agent failure"}'
    return 1
  }

  local result=$(hybrid_complexity_evaluation "Test Phase" "- [ ] Task 1\n- [ ] Task 2" "")
  local method=$(echo "$result" | jq -r '.evaluation_method')
  local error=$(echo "$result" | jq -r '.agent_error // "null"')

  [[ "$method" = "threshold_fallback" ]] || {
    echo "FAIL: Expected threshold_fallback on agent error, got $method"
    return 1
  }

  [[ "$error" != "null" ]] || {
    echo "FAIL: Expected agent_error field to be populated"
    return 1
  }

  echo "PASS: Agent failure fallback"
}

# Run all tests
echo "Running hybrid complexity tests..."
test_threshold_only_scoring
test_agent_invocation_borderline
test_score_reconciliation_agent_agrees
test_score_reconciliation_agent_overrides
test_score_reconciliation_hybrid_average
test_agent_failure_fallback

echo "All tests passed!"
```

### Test File 2: test_workflow_metrics.sh

**Location**: `/home/benjamin/.config/.claude/tests/test_workflow_metrics.sh`

**Test Cases**:

```bash
#!/usr/bin/env bash
# Test workflow metrics aggregation

source "$(dirname "$0")/../lib/workflow-metrics.sh"

test_aggregate_workflow_times() {
  local result=$(aggregate_workflow_times)

  # Check JSON structure
  echo "$result" | jq -e '.workflow_duration_seconds' >/dev/null || {
    echo "FAIL: Missing workflow_duration_seconds"
    return 1
  }

  echo "$result" | jq -e '.total_phases' >/dev/null || {
    echo "FAIL: Missing total_phases"
    return 1
  }

  echo "PASS: Workflow times aggregation"
}

test_aggregate_agent_metrics() {
  local result=$(aggregate_agent_metrics)

  # Check JSON structure
  echo "$result" | jq -e '.total_agents' >/dev/null || {
    echo "FAIL: Missing total_agents"
    return 1
  }

  echo "$result" | jq -e '.agent_summary' >/dev/null || {
    echo "FAIL: Missing agent_summary"
    return 1
  }

  echo "PASS: Agent metrics aggregation"
}

test_aggregate_complexity_metrics() {
  local result=$(aggregate_complexity_metrics)

  # Check JSON structure
  echo "$result" | jq -e '.total_evaluations' >/dev/null || {
    echo "FAIL: Missing total_evaluations"
    return 1
  }

  echo "$result" | jq -e '.agent_invocation_rate' >/dev/null || {
    echo "FAIL: Missing agent_invocation_rate"
    return 1
  }

  echo "PASS: Complexity metrics aggregation"
}

test_generate_performance_report() {
  local report=$(generate_performance_report)

  # Check markdown structure
  echo "$report" | grep -q "# Workflow Performance Report" || {
    echo "FAIL: Missing report title"
    return 1
  }

  echo "$report" | grep -q "## Workflow Summary" || {
    echo "FAIL: Missing workflow summary section"
    return 1
  }

  echo "$report" | grep -q "## Agent Performance" || {
    echo "FAIL: Missing agent performance section"
    return 1
  }

  echo "PASS: Performance report generation"
}

# Run all tests
echo "Running workflow metrics tests..."
test_aggregate_workflow_times
test_aggregate_agent_metrics
test_aggregate_complexity_metrics
test_generate_performance_report

echo "All tests passed!"
```

---

## Risk Mitigation Patterns

### 1. Agent Invocation Failure

**Scenario**: complexity_estimator agent fails to respond or times out

**Mitigation**:
- 60-second timeout on agent invocation
- Robust JSON parsing with validation
- Immediate fallback to threshold score
- Logged failure for analysis
- No workflow interruption

**Code Pattern**:
```bash
if [ "$agent_status" != "success" ]; then
  COMPLEXITY_SCORE="$threshold_score"
  EVALUATION_METHOD="threshold_fallback"
  log_agent_failure "complexity_estimator" "$agent_error"
  echo "⚠ Agent evaluation failed, using threshold: $COMPLEXITY_SCORE"
fi
```

### 2. Incorrect Invocation Criteria Leading to Overhead

**Scenario**: Agent invoked too frequently (e.g., for simple phases), causing unnecessary delays

**Mitigation**:
- Conservative thresholds (score >=7 OR tasks >=8)
- Monitor agent invocation rate via metrics (target: 10-20%)
- Adjust thresholds based on logged data
- User can override via environment variable

**Tuning Pattern**:
```bash
# Allow threshold override
AGENT_INVOCATION_THRESHOLD="${AGENT_INVOCATION_THRESHOLD:-7}"
TASK_COUNT_THRESHOLD="${TASK_COUNT_THRESHOLD:-8}"

if [ "$threshold_score" -ge "$AGENT_INVOCATION_THRESHOLD" ] || \
   [ "$task_count" -ge "$TASK_COUNT_THRESHOLD" ]; then
  agent_needed="true"
fi
```

### 3. Score Discrepancy Handling

**Scenario**: Large gap between threshold and agent scores (diff >=5)

**Mitigation**:
- Reconciliation algorithm considers confidence level
- High-confidence agent overrides threshold
- Low-confidence falls back to threshold
- All discrepancies logged for threshold improvement
- Manual review via metrics report

**Analysis Pattern**:
```bash
# Query logged discrepancies
grep "COMPLEXITY_DISCREPANCY" .claude/logs/adaptive-planning.log | \
  grep "Difference: [5-9]" | \
  awk '{print $NF}' | \
  sort | uniq -c

# Identify patterns in large discrepancies
```

### 4. Metrics Collection Performance Impact

**Scenario**: Workflow metrics aggregation slows down implementation

**Mitigation**:
- Metrics aggregation runs asynchronously at workflow completion
- Log appends are atomic and non-blocking
- Log rotation prevents unbounded growth (10MB max)
- Metrics report generation is opt-in (flag-controlled)

**Async Pattern**:
```bash
# Run metrics aggregation in background after workflow completes
(
  sleep 2  # Allow final log writes to complete
  generate_performance_report > "${SPECS_DIR}/summaries/${PLAN_NUMBER}_metrics.md"
) &
```

---

## Integration Examples

### Before: Threshold-Only Complexity Evaluation (Current)

```bash
# Step 1.5 (non-existent currently) - Jump from 1.4 to 1.55
# Complexity calculated inline in Step 1.55

### 1.55. Proactive Expansion Check

# Calculate complexity
COMPLEXITY_SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$TASK_LIST")
echo "Complexity Score: $COMPLEXITY_SCORE (threshold-only)"

# Check if expansion needed
if [ "$COMPLEXITY_SCORE" -gt 8 ]; then
  echo "High complexity detected, consider expanding..."
fi
```

### After: Hybrid Complexity Evaluation (New Step 1.5)

```bash
# Step 1.5: Hybrid Complexity Evaluation (NEW)

# Run hybrid evaluation
EVALUATION_RESULT=$(hybrid_complexity_evaluation "$PHASE_NAME" "$TASK_LIST" "$PLAN_FILE")

COMPLEXITY_SCORE=$(echo "$EVALUATION_RESULT" | jq -r '.final_score')
EVALUATION_METHOD=$(echo "$EVALUATION_RESULT" | jq -r '.evaluation_method')

echo "Complexity Score: $COMPLEXITY_SCORE ($EVALUATION_METHOD)"

# If agent was used, display reasoning
if [ "$EVALUATION_METHOD" != "threshold" ]; then
  AGENT_REASONING=$(echo "$EVALUATION_RESULT" | jq -r '.agent_reasoning // "N/A"')
  echo "Agent Reasoning: $AGENT_REASONING"
fi

# Export for downstream steps
export COMPLEXITY_SCORE
export EVALUATION_METHOD

# Step 1.55 now uses $COMPLEXITY_SCORE from Step 1.5 (no recalculation)
```

### Agent Invocation Example with Context JSON

```bash
# Build context for complexity_estimator agent
CONTEXT_JSON=$(jq -n \
  --arg phase_name "Phase 3: State Management Refactor" \
  --arg phase_content "$(cat phase_3_content.txt)" \
  --arg overview "Implement OAuth2 authentication system with session management" \
  --arg goals "Secure authentication, token refresh, Redis integration" \
  '{
    parent_plan_context: {
      overview: $overview,
      goals: $goals
    },
    current_structure_level: 0,
    items_to_analyze: [
      {
        item_id: "phase_3",
        item_name: $phase_name,
        content: $phase_content
      }
    ]
  }')

# Invoke agent
AGENT_RESPONSE=$(claude_code_task \
  --subagent-type "general-purpose" \
  --description "Estimate phase complexity" \
  --prompt "
    Read behavioral guidelines from .claude/agents/complexity_estimator.md
    Context: $CONTEXT_JSON
    Output: JSON array with complexity_level, reasoning, confidence
  ")

# Parse response
AGENT_SCORE=$(echo "$AGENT_RESPONSE" | jq -r '.[0].complexity_level')
# Output: 9 (agent identified high complexity threshold missed)
```

### Score Reconciliation Decision Tree Example

```
Input:
  threshold_score = 5
  agent_score = 9
  agent_confidence = "high"
  agent_reasoning = "Critical state management with concurrency challenges"

Decision Tree:
  1. Check score_diff = |9 - 5| = 4.0
  2. score_diff >= 2.0? YES → Scores disagree
  3. agent_confidence = "high"? YES
  4. Action: Use agent score (agent override)

Output:
  {
    "final_score": 9,
    "reconciliation_method": "agent",
    "reconciliation_reason": "Agent high confidence overrides threshold (diff: 4.0)"
  }

Logged as COMPLEXITY_DISCREPANCY for threshold improvement analysis
```

### Metrics Aggregation Output Sample

```markdown
# Workflow Performance Report

**Generated**: 2025-10-12 14:32:15

## Workflow Summary

- **Total Duration**: 1847s (30m 47s)
- **Phases**: 5 / 5 completed
- **Average Phase Time**: 369s

## Agent Performance

- **Total Agents Used**: 3
- **Agent Invocation Summary**:
  - **code-writer**: 5 invocations, 100% success rate, 285s avg
  - **complexity_estimator**: 2 invocations, 100% success rate, 18s avg
  - **debug-specialist**: 1 invocations, 100% success rate, 142s avg

## Complexity Evaluation

- **Total Evaluations**: 5
- **Agent Invocation Rate**: 40%
- **Threshold-Only**: 3
- **Agent Overrides**: 1
- **Hybrid Averages**: 1
- **Score Discrepancies**: 2

---

*Report generated by workflow-metrics.sh*
```

---

## Summary

This detailed specification provides:

1. **Complete architecture** with decision trees, reconciliation algorithm, and agent invocation patterns
2. **Concrete implementation steps** with full function implementations and file paths
3. **Comprehensive testing** with specific test cases for all scenarios
4. **Risk mitigation** with concrete code patterns for fallback and error handling
5. **Integration examples** showing before/after and actual usage patterns

**Total Lines**: ~600 lines of detailed implementation guidance

**Key Deliverables**:
- 3 new functions in complexity-utils.sh (agent_based, reconcile, hybrid_evaluation)
- New Step 1.5 in implement.md with complete workflow
- New logging function in adaptive-planning-logger.sh
- New workflow-metrics.sh utility with 4 aggregation functions
- 2 comprehensive test files with 10+ test cases

**Expected Impact**: 30% reduction in expansion errors, actionable workflow metrics, intelligent borderline case handling
