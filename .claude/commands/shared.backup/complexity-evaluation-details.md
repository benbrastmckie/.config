# Complexity Evaluation Details

[Extracted from orchestrate.md during 070 refactor]

Last Updated: 2025-10-23

---

[Content will be added during Phase 2, 3, and 5]
- **Analyzes** plan complexity using weighted formula
- **Determines** whether to proceed to Phase 4 (Expansion) or skip directly to Phase 5 (Implementation)

### Quick Overview

1. Invoke complexity-estimator agent with plan path
2. Extract complexity scores for all phases
3. Identify phases requiring expansion
4. Display complexity summary to user
5. Set workflow state: expansion_pending (true/false)
6. Conditional branch: expansion → Phase 4, no expansion → Phase 5

### Step 1: Invoke Complexity-Estimator Agent

**EXECUTE NOW - Load Complexity Thresholds**:

Load complexity thresholds from CLAUDE.md with subdirectory override support:

```bash
# STEP 1: Load thresholds from CLAUDE.md hierarchy
# Source the threshold extraction utility
source "${CLAUDE_PROJECT_DIR}/.claude/lib/complexity-thresholds.sh"

# Determine starting directory for threshold search
# Use plan's directory if available, otherwise current directory
if [ -n "$IMPLEMENTATION_PLAN_PATH" ]; then
  THRESHOLD_SEARCH_DIR=$(dirname "$IMPLEMENTATION_PLAN_PATH")
--
  ANALYSIS TASK: Calculate complexity scores for all phases in the implementation plan

  Input Data:
   plan_path: ${IMPLEMENTATION_PLAN_PATH}

   thresholds:
    expansion_threshold: ${EXPANSION_THRESHOLD}
    task_count_threshold: ${TASK_COUNT_THRESHOLD}
    file_reference_threshold: ${FILE_REFERENCE_THRESHOLD}
    replan_limit: ${REPLAN_LIMIT}

   phase_number: null  # Analyze all phases

  Analysis Requirements:
   - Extract 5 complexity factors per phase (task count, file references, dependency depth, test scope, risk factors)
   - Apply weighted formula: (tasks * 0.30) + (files * 0.20) + (depth * 0.20) + (tests * 0.15) + (risks * 0.15)
   - Normalize to 0.0-15.0 scale (factor: 0.822)
   - Classify complexity level (Low/Medium/Medium-High/High/Very High)
   - Recommend expansion based on thresholds
   - Return structured YAML report

  RETURN FORMAT (you must return this exact structure):

  complexity_report:
   plan_path: "${IMPLEMENTATION_PLAN_PATH}"
   analysis_timestamp: "[ISO 8601 timestamp]"
   total_phases: [N]
   thresholds_used:
    expansion_threshold: ${EXPANSION_THRESHOLD}
    task_count_threshold: ${TASK_COUNT_THRESHOLD}
    file_reference_threshold: ${FILE_REFERENCE_THRESHOLD}

   phases:
    - phase_number: [N]
      phase_name: "[name]"
      complexity_score: [0.0-15.0]
--
  echo "Reason: No phases require expansion (all complexity scores within thresholds)"
  echo "✓ Plan is well-scoped for direct implementation"
  echo ""
  echo "Proceeding directly to Phase 5 (Implementation)"
  echo ""

  # Skip Phase 4, continue to Phase 5 (Implementation)
fi
```

### Error Recovery

**Handling Complexity Analysis Failures**:

If complexity-estimator fails (agent error, parsing error, malformed plan):

1. **Log Warning**: "Complexity analysis failed, proceeding without expansion"
2. **Set Fallback State**:
   - `WORKFLOW_STATE_EXPANSION_PENDING = false`
   - `WORKFLOW_STATE_EXPANSION_COUNT = 0`
   - `COMPLEXITY_ANALYSIS_FAILED = true`
get_complexity_thresholds "$THRESHOLD_SEARCH_DIR"

# Display loaded thresholds
echo ""
echo "Complexity Thresholds Loaded:"
echo "- Expansion Threshold: $EXPANSION_THRESHOLD"
echo "- Task Count Threshold: $TASK_COUNT_THRESHOLD"
echo "- File Reference Threshold: $FILE_REFERENCE_THRESHOLD"
echo "- Replan Limit: $REPLAN_LIMIT"
echo "- Source: $THRESHOLDS_SOURCE"
echo ""
```

**EXECUTE NOW - Invoke complexity-estimator Agent**:

Use the Task tool to invoke complexity-estimator with behavioral injection:

```yaml
subagent_type: general-purpose

description: "Analyze plan complexity and identify phases requiring expansion"

timeout: 120000  # 2 minutes for complexity analysis

prompt: |
  Read and follow the behavioral guidelines from:
  ${CLAUDE_PROJECT_DIR}/.claude/agents/complexity-estimator.md

  You are acting as a Complexity Estimator Agent.

  ANALYSIS TASK: Calculate complexity scores for all phases in the implementation plan

  Input Data:
   plan_path: ${IMPLEMENTATION_PLAN_PATH}

   thresholds:
    expansion_threshold: ${EXPANSION_THRESHOLD}
    task_count_threshold: ${TASK_COUNT_THRESHOLD}
    file_reference_threshold: ${FILE_REFERENCE_THRESHOLD}
    replan_limit: ${REPLAN_LIMIT}

   phase_number: null  # Analyze all phases

  Analysis Requirements:
   - Extract 5 complexity factors per phase (task count, file references, dependency depth, test scope, risk factors)
   - Apply weighted formula: (tasks * 0.30) + (files * 0.20) + (depth * 0.20) + (tests * 0.15) + (risks * 0.15)
   - Normalize to 0.0-15.0 scale (factor: 0.822)
   - Classify complexity level (Low/Medium/Medium-High/High/Very High)
   - Recommend expansion based on thresholds
   - Return structured YAML report

  RETURN FORMAT (you must return this exact structure):

  complexity_report:
   plan_path: "${IMPLEMENTATION_PLAN_PATH}"
   analysis_timestamp: "[ISO 8601 timestamp]"
   total_phases: [N]
   thresholds_used:
    expansion_threshold: ${EXPANSION_THRESHOLD}
    task_count_threshold: ${TASK_COUNT_THRESHOLD}
    file_reference_threshold: ${FILE_REFERENCE_THRESHOLD}

   phases:
    - phase_number: [N]
      phase_name: "[name]"
      complexity_score: [0.0-15.0]
      complexity_level: "[Low|Medium|Medium-High|High|Very High]"
      factors:
       task_count: [N]
       file_references: [N]
       dependency_depth: [N]
       test_scope: [N]
       risk_factors: [N]
      raw_score: [N.N]
      normalized_score: [N.N]
      expansion_recommended: [true|false]
      expansion_reason: "[reason or null]"

   summary:
    phases_to_expand: [array of phase numbers]
    expansion_count: [N]
    average_complexity: [N.N]
    max_complexity: [N.N]
    recommendation: "[descriptive text]"

  Quality Requirements:
   - All phases analyzed (no skipped phases)
   - All 5 factors extracted for each phase
   - Scores in valid range (0.0-15.0)
   - YAML properly formatted (2-space indentation)
  Analysis Requirements:
   - Extract 5 complexity factors per phase (task count, file references, dependency depth, test scope, risk factors)
   - Apply weighted formula: (tasks * 0.30) + (files * 0.20) + (depth * 0.20) + (tests * 0.15) + (risks * 0.15)
   - Normalize to 0.0-15.0 scale (factor: 0.822)
   - Classify complexity level (Low/Medium/Medium-High/High/Very High)
   - Recommend expansion based on thresholds
   - Return structured YAML report

  RETURN FORMAT (you must return this exact structure):

  complexity_report:
   plan_path: "${IMPLEMENTATION_PLAN_PATH}"
   analysis_timestamp: "[ISO 8601 timestamp]"
   total_phases: [N]
   thresholds_used:
    expansion_threshold: ${EXPANSION_THRESHOLD}
    task_count_threshold: ${TASK_COUNT_THRESHOLD}
    file_reference_threshold: ${FILE_REFERENCE_THRESHOLD}

   phases:
    - phase_number: [N]
      phase_name: "[name]"
      complexity_score: [0.0-15.0]
      complexity_level: "[Low|Medium|Medium-High|High|Very High]"
      factors:
       task_count: [N]
