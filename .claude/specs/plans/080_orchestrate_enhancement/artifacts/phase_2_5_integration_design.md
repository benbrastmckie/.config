# Phase 2.5 Integration Design: Complexity Evaluation

## Metadata
- **Date**: 2025-10-22
- **Purpose**: Design orchestrate.md Phase 2.5 integration for agent-based complexity evaluation
- **Phase**: Phase 3.4 Stage 5
- **Status**: Design complete, ready for Phase 4 Stage 0 implementation

## Overview

Phase 2.5 (Complexity Evaluation) is the critical bridge between Planning (Phase 2) and Expansion (Phase 2.6/Phase 4). It invokes complexity-estimator agent to assess each phase in the Level 0 plan, identifies high-complexity phases requiring expansion, and conditionally branches to Phase 2.6 (expansion) or Phase 3 (implementation).

**Key Insight**: Phase 2.5 ALREADY EXISTS in orchestrate.md (lines 1910-2248) but uses DEPRECATED algorithm-based approach. Phase 4 Stage 0 must UPDATE (not create) Phase 2.5 to use pure agent-based assessment.

## Current State vs Target State

### Current Implementation (DEPRECATED)

**Location**: orchestrate.md lines 1910-2248

**Problems**:
1. Uses algorithm-based approach (5-factor weighted formula): "Apply weighted formula: (tasks * 0.30) + (files * 0.20) + ..."
2. References deprecated analyze-phase-complexity.sh (archived in Phase 3.4 Stage 3)
3. Achieves only 0.7515 correlation with ground truth
4. Invokes complexity-estimator agent but with algorithm instructions, not agent-based instructions

**Evidence from orchestrate.md**:
```yaml
# Line 1996: "Apply weighted formula: (tasks * 0.30) + (files * 0.20) + (depth * 0.20) + (tests * 0.15) + (risks * 0.15)"
# Line 1997: "Normalize to 0.0-15.0 scale (factor: 0.822)"
# Line 1995: "Extract 5 complexity factors per phase..."
```

### Target Implementation (AGENT-BASED)

**Update Required**: Replace algorithm instructions with agent-based instructions

**Key Changes**:
1. Remove algorithm formula instructions (lines 1995-2000)
2. Reference complexity-estimator.md agent specification
3. Use agent's few-shot calibration approach
4. Individual per-phase invocation pattern
5. Add MANDATORY VERIFICATION checkpoint
6. Implement fallback mechanism (task count heuristic)

## Phase 2.5 Responsibilities

### Input
- **From Phase 2 (Planning)**: Level 0 plan path (`specs/NNN_topic/plans/NNN_plan_name.md`)
- **From Phase 0 (Location)**: Topic paths (ARTIFACT_PLANS, TOPIC_NUMBER, TOPIC_PATH)
- **From CLAUDE.md**: Thresholds (expansion_threshold, task_count_threshold)

### Process
1. **Load thresholds**: Extract from CLAUDE.md (already implemented, lines 1932-1962)
2. **Extract phases**: Parse Level 0 plan to identify all phases
3. **Assess each phase**: Invoke complexity-estimator agent individually per phase
4. **Aggregate results**: Collect all complexity assessments into workflow state
5. **Identify high-complexity phases**: Filter phases with expansion_recommended=true
6. **Display summary**: Show user which phases will be expanded
7. **Set workflow state**: `expansion_pending=true/false`, `high_complexity_phases=[...]`

### Output
- **Workflow state**:
  - `complexity_reports`: Array of complexity_assessment YAML objects
  - `high_complexity_phases`: Array of phase names/numbers requiring expansion
  - `expansion_pending`: Boolean (true if any phases need expansion)
- **Next phase**:
  - If `expansion_pending=true`: Proceed to Phase 2.6 (Expansion)
  - If `expansion_pending=false`: Skip to Phase 3 (Implementation)

## Invocation Pattern: Individual Per-Phase

### Rationale

**Why individual per-phase** (vs batch multi-phase):
- Consistent with research phase pattern (parallel individual research agents)
- Better error isolation (one bad phase doesn't fail entire batch)
- Simpler agent logic (no array handling needed)
- Easier to debug and validate

**Implementation**: Loop through phases, invoke complexity-estimator once per phase

### Pseudo-Code

```bash
# Phase 2.5: Complexity Evaluation in orchestrate.md

PLAN_PATH="${ARTIFACT_PLANS}/${TOPIC_NUMBER}_${TOPIC_NAME}.md"

# Extract all phases from Level 0 plan
PHASE_COUNT=$(grep -c "^### Phase" "$PLAN_PATH")
echo "Plan contains $PHASE_COUNT phases to assess"

# Initialize assessment storage
declare -a COMPLEXITY_ASSESSMENTS
HIGH_COMPLEXITY_PHASES=()
EXPANSION_PENDING=false

# Assess each phase individually
for PHASE_NUM in $(seq 1 $PHASE_COUNT); do
  echo ""
  echo "=== Assessing Phase $PHASE_NUM/$PHASE_COUNT ==="

  # Extract phase content (from "### Phase N:" to "### Phase N+1:" or end)
  if [ "$PHASE_NUM" -eq "$PHASE_COUNT" ]; then
    # Last phase: extract to end of file
    PHASE_CONTENT=$(sed -n "/^### Phase $PHASE_NUM:/,\$p" "$PLAN_PATH")
  else
    # Non-last phase: extract to next phase
    PHASE_CONTENT=$(sed -n "/^### Phase $PHASE_NUM:/,/^### Phase $((PHASE_NUM+1)):/p" "$PLAN_PATH" | head -n -1)
  fi

  # Extract phase name (remove "### Phase N: " prefix)
  PHASE_NAME=$(echo "$PHASE_CONTENT" | head -1 | sed "s/^### Phase $PHASE_NUM: //")

  echo "Phase name: $PHASE_NAME"

  # Invoke complexity-estimator agent via Task tool
  ASSESSMENT=$(claude-code Task <<EOF
subagent_type: general-purpose
description: "Assess complexity of Phase $PHASE_NUM: $PHASE_NAME"
timeout: 10000  # 10 seconds per phase (conservative)

prompt: |
  Read and follow the behavioral guidelines from:
  ${CLAUDE_PROJECT_DIR}/.claude/agents/complexity-estimator.md

  You are acting as a Complexity Estimator Agent.

  ANALYSIS TASK: Assess the complexity of the following phase using pure LLM judgment with few-shot calibration.

  operation: assess_phase_complexity

  phase_name: "$PHASE_NAME"
  phase_content: |
$(echo "$PHASE_CONTENT" | sed 's/^/    /')

  is_expanded: false  # Level 0 plan, not yet expanded

  plan_context:
    plan_name: "${TOPIC_NUMBER}_${TOPIC_NAME}"
    plan_overview: "[Extract from plan overview section]"
    total_phases: $PHASE_COUNT

  thresholds:
    expansion_threshold: $EXPANSION_THRESHOLD

  Follow the agent specification exactly. Return ONLY the YAML output as specified in the [EXECUTION-CRITICAL] Output Format section.
EOF
)

  # Store assessment
  COMPLEXITY_ASSESSMENTS[$PHASE_NUM]="$ASSESSMENT"

  # Extract complexity score and expansion recommendation
  COMPLEXITY_SCORE=$(echo "$ASSESSMENT" | grep "^ *complexity_score:" | awk '{print $2}')
  EXPANSION_REC=$(echo "$ASSESSMENT" | grep "^ *expansion_recommended:" | awk '{print $2}')

  echo "Complexity score: $COMPLEXITY_SCORE"
  echo "Expansion recommended: $EXPANSION_REC"

  # Collect high-complexity phases
  if [ "$EXPANSION_REC" = "true" ]; then
    HIGH_COMPLEXITY_PHASES+=("$PHASE_NUM")
    EXPANSION_PENDING=true
    echo "→ Phase $PHASE_NUM will be expanded"
  else
    echo "→ Phase $PHASE_NUM will NOT be expanded"
  fi
done

# MANDATORY VERIFICATION CHECKPOINT (see next section)
verify_complexity_assessments

# Display summary
echo ""
echo "=== Complexity Evaluation Summary ==="
echo "Total phases assessed: $PHASE_COUNT"
echo "High-complexity phases: ${#HIGH_COMPLEXITY_PHASES[@]}"
if [ "$EXPANSION_PENDING" = "true" ]; then
  echo "Expansion required for phases: ${HIGH_COMPLEXITY_PHASES[*]}"
  echo "Next: Phase 2.6 (Plan Expansion)"
else
  echo "No expansion needed, all phases within threshold"
  echo "Next: Phase 3 (Implementation)"
fi
echo ""
```

## Verification Checkpoint

**CRITICAL**: Phase 2.5 MUST include verification checkpoint with fallback

### Purpose

- Catch agent failures (invalid YAML, missing fields, timeout)
- Validate assessment quality (not all default scores)
- Degrade gracefully to task count heuristic if agent fails

### Implementation

```bash
verify_complexity_assessments() {
  echo ""
  echo "=== MANDATORY VERIFICATION: Complexity Assessments ==="

  # 1. Verify phase count matches
  EXPECTED_COUNT=$PHASE_COUNT
  ACTUAL_COUNT=${#COMPLEXITY_ASSESSMENTS[@]}

  if [ "$ACTUAL_COUNT" -ne "$EXPECTED_COUNT" ]; then
    echo "ERROR: Phase count mismatch (expected $EXPECTED_COUNT, got $ACTUAL_COUNT)"
    execute_fallback
    return 1
  fi
  echo "✓ Phase count: $ACTUAL_COUNT matches $EXPECTED_COUNT"

  # 2. Validate YAML structure for each assessment
  INVALID_COUNT=0
  for PHASE_NUM in $(seq 1 $PHASE_COUNT); do
    ASSESSMENT="${COMPLEXITY_ASSESSMENTS[$PHASE_NUM]}"

    # Check required fields present
    if ! echo "$ASSESSMENT" | grep -q "^ *phase_name:"; then
      echo "ERROR: phase_name missing in Phase $PHASE_NUM"
      INVALID_COUNT=$((INVALID_COUNT + 1))
    fi

    if ! echo "$ASSESSMENT" | grep -q "^ *complexity_score:"; then
      echo "ERROR: complexity_score missing in Phase $PHASE_NUM"
      INVALID_COUNT=$((INVALID_COUNT + 1))
    fi

    if ! echo "$ASSESSMENT" | grep -q "^ *expansion_recommended:"; then
      echo "ERROR: expansion_recommended missing in Phase $PHASE_NUM"
      INVALID_COUNT=$((INVALID_COUNT + 1))
    fi

    # Validate complexity score is numeric and in range
    SCORE=$(echo "$ASSESSMENT" | grep "^ *complexity_score:" | awk '{print $2}')
    if ! [[ "$SCORE" =~ ^[0-9]+$ ]] || [ "$SCORE" -lt 0 ] || [ "$SCORE" -gt 15 ]; then
      echo "ERROR: Invalid complexity score ($SCORE) in Phase $PHASE_NUM"
      INVALID_COUNT=$((INVALID_COUNT + 1))
    fi
  done

  if [ "$INVALID_COUNT" -gt 0 ]; then
    echo "ERROR: $INVALID_COUNT assessment(s) have invalid structure"
    execute_fallback
    return 1
  fi
  echo "✓ All assessments have valid YAML structure"

  # 3. Verify at least one phase has non-default score
  ALL_DEFAULT=true
  for PHASE_NUM in $(seq 1 $PHASE_COUNT); do
    SCORE=$(echo "${COMPLEXITY_ASSESSMENTS[$PHASE_NUM]}" | grep "^ *complexity_score:" | awk '{print $2}')
    if [ "$SCORE" -ne 5 ]; then
      ALL_DEFAULT=false
      break
    fi
  done

  if [ "$ALL_DEFAULT" = "true" ]; then
    echo "WARNING: All phases have default score (5), assessments may be degraded"
    echo "Continuing with caution..."
  else
    echo "✓ Assessments show variation (not all default scores)"
  fi

  echo "Verification complete: All checks passed"
  echo ""
  return 0
}

execute_fallback() {
  echo ""
  echo "=== FALLBACK: Using Task Count Heuristic ==="

  # Reset expansion tracking
  HIGH_COMPLEXITY_PHASES=()
  EXPANSION_PENDING=false

  # Fallback strategy: Identify phases with >10 tasks
  for PHASE_NUM in $(seq 1 $PHASE_COUNT); do
    # Extract phase content
    if [ "$PHASE_NUM" -eq "$PHASE_COUNT" ]; then
      PHASE_CONTENT=$(sed -n "/^### Phase $PHASE_NUM:/,\$p" "$PLAN_PATH")
    else
      PHASE_CONTENT=$(sed -n "/^### Phase $PHASE_NUM:/,/^### Phase $((PHASE_NUM+1)):/p" "$PLAN_PATH" | head -n -1)
    fi

    # Count tasks (lines starting with "- [ ]")
    TASK_COUNT=$(echo "$PHASE_CONTENT" | grep -c "^- \[ \]")

    # Apply task count threshold
    if [ "$TASK_COUNT" -gt "$TASK_COUNT_THRESHOLD" ]; then
      PHASE_NAME=$(echo "$PHASE_CONTENT" | head -1 | sed "s/^### Phase $PHASE_NUM: //")
      HIGH_COMPLEXITY_PHASES+=("$PHASE_NUM")
      EXPANSION_PENDING=true
      echo "Phase $PHASE_NUM: $TASK_COUNT tasks > $TASK_COUNT_THRESHOLD threshold → EXPAND"
    else
      echo "Phase $PHASE_NUM: $TASK_COUNT tasks ≤ $TASK_COUNT_THRESHOLD threshold → no expansion"
    fi
  done

  echo ""
  echo "Fallback complete: Identified ${#HIGH_COMPLEXITY_PHASES[@]} high-complexity phases using task count"
  echo ""
}
```

## Checkpoint Strategy

After Phase 2.5 completes, save checkpoint for recovery:

```bash
# Save checkpoint after Phase 2.5
CHECKPOINT_FILE="${CHECKPOINT_DIR}/orchestrate_complexity_evaluation_${WORKFLOW_ID}.yaml"

cat > "$CHECKPOINT_FILE" <<EOF
checkpoint:
  workflow_id: "$WORKFLOW_ID"
  phase: "complexity_evaluation"
  timestamp: "$(date -Iseconds)"
  status: "complete"

inputs:
  plan_path: "$PLAN_PATH"
  expansion_threshold: $EXPANSION_THRESHOLD
  task_count_threshold: $TASK_COUNT_THRESHOLD

outputs:
  total_phases_assessed: $PHASE_COUNT
  high_complexity_phases: [${HIGH_COMPLEXITY_PHASES[*]}]
  expansion_pending: $EXPANSION_PENDING
  verification_passed: true

metadata:
  assessment_count: ${#COMPLEXITY_ASSESSMENTS[@]}
  fallback_used: false

next_phase: "$([ "$EXPANSION_PENDING" = "true" ] && echo "expansion" || echo "implementation")"
EOF

echo "Checkpoint saved: $CHECKPOINT_FILE"
```

**Restoration**: If Phase 2.6 fails, orchestrator can restore from this checkpoint:

```bash
# Restore from checkpoint
if [ -f "$CHECKPOINT_FILE" ]; then
  EXPANSION_PENDING=$(grep "expansion_pending:" "$CHECKPOINT_FILE" | awk '{print $2}')
  HIGH_COMPLEXITY_PHASES=($(grep "high_complexity_phases:" "$CHECKPOINT_FILE" | sed 's/.*\[//; s/\].*//' | tr ' ' '\n'))
  echo "Restored checkpoint: expansion_pending=$EXPANSION_PENDING, phases=[${HIGH_COMPLEXITY_PHASES[*]}]"
fi
```

## Phase Numbering After Integration

orchestrate.md currently has phases 0-8. Phase 2.5 and 2.6 are sub-phases inserted between Planning and Implementation:

```
Before Phase 3.4:
  Phase 0: Location Determination
  Phase 1: Research
  Phase 2: Planning
  Phase 3: Implementation
  Phase 4: Testing
  Phase 5: Debugging
  Phase 6: Documentation
  Phase 7: GitHub
  Phase 8: Summary

After Phase 3.4 (with 2.5 and 2.6):
  Phase 0: Location Determination
  Phase 1: Research
  Phase 2: Planning
  Phase 2.5: Complexity Evaluation (UPDATED, not new)
  Phase 2.6: Plan Expansion (NEW in Phase 4)
  Phase 3: Implementation (unchanged)
  Phase 4: Testing (unchanged)
  Phase 5: Debugging (unchanged)
  Phase 6: Documentation (unchanged)
  Phase 7: GitHub (unchanged)
  Phase 8: Summary (unchanged)

Note: Phase 3-8 retain original numbers, sub-phases 2.5 and 2.6 inserted
```

**Implementation**: orchestrate.md Phase 2.5 already exists, so Phase 4 Stage 0 will **update** (not create) it.

## Context Management

**Context Minimization Strategy**: Orchestrator stores minimal metadata, not full assessments

### Stored in Workflow State
```yaml
workflow_state:
  complexity_evaluation:
    high_complexity_phases: [2, 5]  # Phase numbers only
    expansion_pending: true
    assessment_count: 5
    verification_passed: true
```

### NOT Stored
- Full `complexity_assessment` YAML objects (600+ tokens each)
- `reasoning` text (natural language explanations)
- `key_factors` lists

**Context Reduction**: 5 phases × 600 tokens = 3000 tokens → 100 tokens (97% reduction)

### Full Assessments Available
If Phase 2.6 (expansion) needs full reasoning/key_factors for documentation:
- Read directly from checkpoint file
- Or re-invoke complexity-estimator on specific phase

## Phase 4 Stage 0 Specification

**Update Required**: Modify orchestrate.md Phase 2.5 (lines 1910-2248) to use agent-based approach

### Tasks for Phase 4 Stage 0

1. **Update agent invocation prompt** (lines 1975-2050):
   - Remove algorithm formula instructions (lines 1995-2000)
   - Replace with agent-based instructions: "Follow complexity-estimator.md specification exactly"
   - Change return format to match agent's output (complexity_assessment YAML)

2. **Implement individual per-phase invocation**:
   - Replace batch invocation with loop through phases
   - Invoke complexity-estimator once per phase
   - Aggregate results into COMPLEXITY_ASSESSMENTS array

3. **Add MANDATORY VERIFICATION checkpoint** (new section after assessment loop):
   - Implement `verify_complexity_assessments()` function
   - Check phase count, YAML structure, score validity
   - Call verification before proceeding to Phase 2.6

4. **Implement fallback mechanism** (new section):
   - Implement `execute_fallback()` function
   - Use task count heuristic (>10 tasks = expand)
   - Log fallback usage for debugging

5. **Update conditional branching logic**:
   - Check `expansion_pending` flag
   - If true: Proceed to Phase 2.6 (Expansion)
   - If false: Skip to Phase 3 (Implementation)
   - Display clear message to user

6. **Add checkpoint save**:
   - Save checkpoint after Phase 2.5 completion
   - Include high_complexity_phases, expansion_pending, verification status

7. **Test Phase 2.5 integration**:
   - Create test plan with 3 phases (simple, medium, high complexity)
   - Run orchestrate.md through Phase 2.5
   - Verify complexity assessments collected
   - Verify high-complexity phases identified correctly
   - Verify conditional branch works (expansion vs no expansion)

8. **Update documentation**:
   - Update orchestrate.md header comments to note agent-based approach
   - Cross-reference complexity-estimator.md
   - Document individual per-phase invocation pattern

### Success Criteria for Phase 4 Stage 0

- [ ] orchestrate.md Phase 2.5 invokes complexity-estimator correctly (agent-based, not algorithm)
- [ ] Individual per-phase invocation pattern implemented
- [ ] YAML assessments collected and validated
- [ ] High-complexity phases identified (expansion_recommended=true)
- [ ] Verification checkpoint implemented with fallback
- [ ] Conditional flow to Phase 2.6 or Phase 3 works
- [ ] End-to-end test passes (simple plan: no expansion, complex plan: expansion)
- [ ] Checkpoint save/restore works

### Estimated Duration

**2-3 hours** for Phase 4 Stage 0 implementation and testing

## Integration with Phase 4 (Expansion)

After Phase 2.5 identifies high-complexity phases, Phase 2.6 (implemented in Phase 4) will:

1. **Receive input**: `HIGH_COMPLEXITY_PHASES` array from Phase 2.5
2. **For each phase**: Invoke expansion-specialist agent
3. **Create expanded files**: `specs/NNN_topic/plans/NNN_plan/phase_N_name.md`
4. **Update parent plan**: Replace phase content with summary + reference
5. **Recursive evaluation**: Re-run Phase 2.5 on expanded phases (max 2 levels)

**Phase 2.6 Input Format**:
```yaml
expansion_request:
  high_complexity_phases: [2, 5]
  plan_path: "specs/027_auth/plans/027_auth_implementation.md"
  thresholds:
    expansion_threshold: 8.0
    task_count_threshold: 10
```

**Phase 2.6 Output**:
- Expanded phase files created
- Parent plan updated with references
- Expansion metadata added to plan

## Files Referenced

### Existing Files
1. `.claude/commands/orchestrate.md` (lines 1910-2248: Phase 2.5 current implementation)
2. `.claude/agents/complexity-estimator.md` (pure agent specification)
3. `.claude/lib/complexity-thresholds.sh` (threshold extraction utility)
4. `CLAUDE.md` (adaptive_planning_config section with thresholds)

### Files Created in Phase 3.4
1. `.claude/tests/fixtures/complexity/test_multi_phase_plan.md` (5-phase test plan)
2. `.claude/specs/plans/080_orchestrate_enhancement/reports/phase_3_4_stage_2_validation_report.md` (output format validation)
3. `.claude/specs/plans/080_orchestrate_enhancement/artifacts/phase_2_5_integration_design.md` (this document)

### Files to Create in Phase 4 Stage 0
1. None (orchestrate.md updated in place)
2. Test results (validation logs for Phase 2.5 integration)

## Summary

Phase 2.5 integration design is complete and ready for Phase 4 Stage 0 implementation. Key decisions:

1. **Update existing Phase 2.5** in orchestrate.md (lines 1910-2248), don't create new
2. **Use pure agent-based approach**, not algorithm (remove formula instructions)
3. **Individual per-phase invocation**, not batch (consistent with research phase)
4. **MANDATORY VERIFICATION checkpoint** with fallback to task count heuristic
5. **Conditional branching**: expansion_pending → Phase 2.6 or Phase 3
6. **Context minimization**: Store phase numbers only, not full YAML (97% reduction)

Phase 4 Stage 0 can now proceed with confidence that the integration strategy is well-defined, validated, and ready for implementation.

**Stage 5 design complete** ✓
