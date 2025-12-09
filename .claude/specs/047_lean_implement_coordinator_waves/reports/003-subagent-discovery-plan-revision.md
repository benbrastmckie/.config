# Subagent Discovery and Plan Revision Workflow Analysis

**Research Date**: 2025-12-09
**Research Scope**: Analyze how implementer subagents discover and report blocking dependencies, mechanisms for updating plan phases with findings, and coordinator-based plan revision workflow that recalculates dependencies for next iteration waves
**Workflow Context**: Lean implementation coordinator with wave-based orchestration

---

## Executive Summary

This analysis examines how implementer subagents in the wave-based lean implementation system discover blocking dependencies during theorem proving, communicate these findings back to coordinators, and trigger plan revision workflows. The research reveals:

1. **Subagent Discovery Signals**: Implementer agents (lean-implementer) return structured completion signals with `work_remaining` and `theorems_partial` fields indicating blocking issues
2. **Communication Protocol**: Metadata-only passing via bash-parsed signals reduces context overhead by 95% (80 tokens vs 2000 tokens full output)
3. **Plan Revision Mechanism**: The `/revise` command provides a research-and-revise workflow for updating plans based on discovered dependencies
4. **Dependency Recalculation**: Coordinators can parse `work_remaining` to identify which phases need retry waves with additional context
5. **Adaptive Planning Integration**: The system supports dynamic plan modification through Edit tool operations while maintaining checkpoint continuity

**Key Finding**: The existing architecture supports dependency discovery but lacks automated coordinator-triggered plan revision. Manual `/revise` invocation is currently required to update plans based on subagent findings.

---

## Findings

### 1. Subagent Discovery Signals (lean-implementer)

**Source**: `/home/benjamin/.config/.claude/agents/lean-implementer.md`

#### Output Signal Format

The lean-implementer agent returns structured completion signals after theorem proving attempts:

```yaml
THEOREM_BATCH_COMPLETE:
  theorems_completed: ["theorem_add_comm", "theorem_mul_assoc"]
  theorems_partial: ["theorem_zero_add"]
  tactics_used: ["exact", "ring", "simp"]
  mathlib_theorems: ["Nat.add_comm", "Algebra.Ring.Basic"]
  diagnostics: []
  context_exhausted: false
  work_remaining: Phase_3  # Space-separated list of incomplete phases (or 0)
  wave_number: 1
  budget_consumed: 2
```

**Key Discovery Fields**:
- `theorems_partial`: List of theorems with incomplete proofs (blocking dependencies)
- `work_remaining`: Space-separated string of incomplete phase identifiers (NOT JSON array)
- `diagnostics`: Error messages indicating specific blockers (e.g., missing lemmas, infrastructure gaps)
- `context_exhausted`: Boolean flag indicating if agent needs continuation

**Example from lean-implement-output.md** (lines 151-179):
```
Phase 2 has 3/6 theorems complete with some blocked on infrastructure. Let me verify and continue:

Phase 2 has 3/6 theorems proven with 3 more blocked on infrastructure gaps
(classical merge lemma, biconditional infrastructure).
```

**Discovery Pattern**: Agent attempts proof, encounters missing infrastructure (e.g., `classical_merge` lemma), marks theorem as `sorry`, and reports partial completion.

### 2. Coordinator Parsing and Metadata Extraction

**Source**: `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-communication.md`

#### Metadata Extraction Pattern

Coordinators extract summary information from subagent output to avoid context bloat:

```bash
extract_metadata() {
  local agent_output="$1"

  # Parse standard signals
  CREATED=$(echo "$agent_output" | grep -oP 'CREATED:\s*\K.+')
  TITLE=$(echo "$agent_output" | grep -oP 'TITLE:\s*\K.+')
  SUMMARY=$(echo "$agent_output" | grep -oP 'SUMMARY:\s*\K.+')

  # Return as JSON
  jq -n \
    --arg path "$CREATED" \
    --arg title "$TITLE" \
    --arg summary "$SUMMARY" \
    '{path: $path, title: $title, summary: $summary}'
}
```

**Context Reduction**:
- Full subagent output: 2,500 tokens
- Extracted metadata: 110 tokens
- **Reduction: 95.6%**

**Application to Dependency Discovery**: Coordinators can parse `work_remaining` and `theorems_partial` fields from subagent output without loading full proof context.

### 3. Plan Revision Workflow (/revise command)

**Source**: `/home/benjamin/.config/.claude/commands/revise.md`

#### Workflow Architecture

The `/revise` command provides a two-phase workflow:

1. **Research Phase** (Block 4a-4c):
   - Analyze revision requirements from user prompt
   - Invoke research-specialist to create insights report
   - Hard barrier validation ensures report exists at pre-calculated path

2. **Plan Revision Phase** (Block 5a-5c):
   - Create backup of existing plan at `${SPECS_DIR}/backups/${PLAN_BASENAME}_backup_${TIMESTAMP}.md`
   - Invoke plan-architect to modify plan via Edit tool
   - Hard barrier validation ensures backup exists AND plan differs from backup

**Critical Pattern - Hard Barrier Enforcement**:
```bash
# HARD BARRIER: Report file MUST exist at pre-calculated path
if [ ! -f "$EXPECTED_REPORT_PATH" ]; then
  echo "❌ HARD BARRIER FAILED - Report file not found anywhere" >&2
  echo "Expected: $EXPECTED_REPORT_PATH" >&2
  exit 1
fi
```

**Plan Modification Constraints**:
- Must use Edit tool (NEVER Write) for modifications
- Preserve all `[COMPLETE]` phases unchanged
- Update plan metadata (Date, Estimated Hours, Phase count)
- Maintain `/implement` compatibility (checkbox format, phase markers, dependency syntax)

### 4. Dependency Propagation Mechanisms

#### Current State: Manual Propagation

**Observation**: The lean-implement-output.md example shows no automated plan revision after discovering infrastructure gaps. The coordinator continues with available work but does not trigger `/revise`.

**Manual Workflow**:
1. Coordinator completes wave with partial results
2. User reviews output summary: "Phase 2: 3/6 theorems (blocked on infrastructure)"
3. User manually invokes: `/revise "plan at /path/to/plan.md to add Phase X for infrastructure gaps"`
4. Research-specialist analyzes blockers and creates insights report
5. Plan-architect modifies plan to add new phases or update dependencies

#### Potential Automated Pattern (Not Implemented)

**Hypothetical coordinator-triggered revision**:
```yaml
# In lean-coordinator after parsing subagent output
if [ "$PARTIAL_COUNT" -gt 0 ] && [ "$CONTEXT_REMAINING" -gt 3000 ]; then
  # Sufficient context for plan revision
  BLOCKING_ISSUES=$(echo "$SUBAGENT_OUTPUT" | grep -oP 'blocked on \K.*')

  # Trigger /revise via Task delegation
  Task {
    subagent_type: "general-purpose"
    description: "Revise plan to address blocking dependencies"
    prompt: |
      Read and follow: .claude/commands/revise.md

      Revision context: $BLOCKING_ISSUES
      Existing plan: $PLAN_PATH
  }
fi
```

**Blockers for Automation**:
- `/revise` requires explicit user description (no programmatic API)
- Risk of infinite revision loops without user oversight
- Coordinator context budget may be insufficient for full revision workflow

### 5. Plan Phase Update Mechanics

**Source**: `/home/benjamin/.config/.claude/commands/revise.md` (Block 5b)

#### Plan-Architect Revision Instructions

```markdown
**CRITICAL INSTRUCTIONS FOR PLAN REVISION**:
1. Use STEP 1-REV → STEP 2-REV → STEP 3-REV → STEP 4-REV workflow (revision flow)
2. Create backup at ${BACKUP_PATH} BEFORE making any changes
3. Use Edit tool (NEVER Write) for all modifications to existing plan file
4. Preserve all [COMPLETE] phases unchanged (do not modify completed work)
5. Update plan metadata (Date, Estimated Hours, Phase count) to reflect revisions
6. **METADATA NORMALIZATION**: Convert non-standard fields to standard format
7. Maintain /implement compatibility (checkbox format, phase markers, dependency syntax)
```

**Edit Tool Operations**:
- Add new phases: Insert after highest existing phase number
- Update dependencies: Modify `depends_on: [1, 2]` arrays in phase metadata
- Add tasks: Insert checkbox items `- [ ] New task description`
- Update estimates: Revise `Estimated Hours: {low}-{high}` based on new scope

**Example Revision** (hypothetical):
```markdown
Original Phase 2:
### Phase 2: Modal S5 Theorems
- [ ] Prove t_box_consistency
- [ ] Prove box_contrapose

Revised Plan (adds infrastructure phase):
### Phase 2: Infrastructure - Classical Lemmas
- [ ] Implement classical_merge lemma
- [ ] Implement biconditional infrastructure
depends_on: [1]

### Phase 3: Modal S5 Theorems
- [ ] Prove t_box_consistency (requires classical_merge)
- [ ] Prove box_contrapose
depends_on: [1, 2]
```

### 6. Dependency Recalculation for Next Wave

#### Wave-Based Execution Model

**Source**: `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md` (Example 8)

**Current Wave Logic**:
1. Parse plan to extract phases with dependencies
2. Identify Wave 1 phases (no dependencies: `depends_on: []`)
3. Execute Wave 1 via parallel subagent invocations
4. Mark completed phases, identify Wave 2 phases (dependencies now satisfied)
5. Repeat until all phases complete or context exhausted

**Dependency Recalculation After Revision**:
```bash
# After plan revision, re-parse dependency graph
source "${CLAUDE_LIB}/plan/plan-core-bundle.sh"

# Detect plan tier and extract phases
PLAN_TIER=$(detect_tier "$PLAN_PATH")
ALL_PHASES=$(list_phases "$PLAN_PATH")

# Rebuild dependency graph
for phase_num in $ALL_PHASES; do
  PHASE_DEPS=$(get_phase_dependencies "$PLAN_PATH" "$phase_num")
  PHASE_STATUS=$(get_phase_status "$PLAN_PATH" "$phase_num")

  # Check if dependencies satisfied
  if all_deps_complete "$PHASE_DEPS"; then
    NEXT_WAVE_PHASES="$NEXT_WAVE_PHASES $phase_num"
  fi
done

# Execute next wave with recalculated phases
for phase in $NEXT_WAVE_PHASES; do
  invoke_lean_implementer "$phase"
done
```

**Key Insight**: The plan-core-bundle.sh library provides tier-agnostic parsing functions that work across L0/L1/L2 plan structures, enabling dependency recalculation after revision.

### 7. Metadata and State Preservation

**Source**: `/home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md`

#### State Machine Persistence

The workflow state machine preserves context across bash blocks:

```bash
# After research phase (Block 4c)
append_workflow_state "EXISTING_PLAN_PATH" "$EXISTING_PLAN_PATH"
append_workflow_state "TOTAL_REPORT_COUNT" "$TOTAL_REPORT_COUNT"
append_workflow_state "NEW_REPORT_COUNT" "$NEW_REPORT_COUNT"
append_workflow_state "REVISION_DETAILS" "$REVISION_DETAILS"

# Load in next phase (Block 5a)
load_workflow_state "$WORKFLOW_ID" false
# Variables automatically restored
```

**Persistence Mechanism**: State stored in `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh` as bash variable assignments.

#### Checkpoint System

**Source**: Adaptive Planning Guide, lines 172-230

**Checkpoint Contents**:
```json
{
  "checkpoint_id": "lean_implement_wave_2_20251209_184530",
  "workflow_type": "lean-implementation",
  "project_name": "hilbert_theorems",
  "current_phase": 2,
  "total_phases": 5,
  "completed_phases": [1],
  "workflow_state": {
    "artifact_registry": {...},
    "plan_path": "specs/057_hilbert/.../001-plan.md",
    "wave_number": 2,
    "partial_theorems": ["RCP", "LCE", "RCE"]
  }
}
```

**Integration with Revision**: Checkpoints preserve `partial_theorems` and `wave_number`, enabling resume after plan revision without losing discovery context.

### 8. Error Communication Protocol

**Source**: `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-communication.md`

#### Error Reporting Format

```
ERROR: [Category] - [Description]
CONTEXT: [Relevant context]
RECOVERY: [Suggested action]
```

**Example Blocking Dependency Error**:
```
ERROR: DEPENDENCY_MISSING - Cannot prove theorem_box_conj without classical_merge
CONTEXT: Phase 2, Task 4, ModalS5.lean line 197
RECOVERY: Add Phase 1.5 to implement classical_merge lemma, update Phase 2 dependencies
```

**Error Categories Relevant to Discovery**:
- `DEPENDENCY_MISSING`: Required lemma/theorem not available
- `VALIDATION`: Proof attempt failed diagnostics
- `TIMEOUT`: Context budget exhausted before completion

**Coordinator Parsing**:
```bash
parse_subagent_error() {
  local agent_output="$1"
  local agent_name="$2"

  ERROR_TYPE=$(echo "$agent_output" | grep -oP '^ERROR: \K[A-Z_]+')
  ERROR_DESC=$(echo "$agent_output" | grep -oP '^ERROR: [A-Z_]+ - \K.*')
  ERROR_CONTEXT=$(echo "$agent_output" | grep -oP '^CONTEXT: \K.*')

  # Log to centralized error system
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "agent_error" \
    "$agent_name failed: $ERROR_DESC" \
    "coordinator" \
    "$(jq -n --arg type "$ERROR_TYPE" --arg ctx "$ERROR_CONTEXT" \
       '{error_type: $type, context: $ctx}')"
}
```

**Integration with /repair Command**: Logged errors queryable via `/errors` and analyzed via `/repair` for automated plan revision generation.

---

## Recommendations

### 1. Implement Coordinator-Triggered Plan Revision

**Objective**: Enable coordinators to automatically invoke `/revise` when subagents report blocking dependencies.

**Design**:
```yaml
# In lean-coordinator after wave completion
if [ "$PARTIAL_THEOREM_COUNT" -gt 0 ]; then
  # Extract blocking issues from diagnostics
  BLOCKING_SUMMARY=$(extract_blocking_issues "$SUBAGENT_OUTPUT")

  # Check context budget
  CURRENT_CONTEXT=$(get_context_usage)
  if [ "$CURRENT_CONTEXT" -lt 100000 ]; then
    # Sufficient budget for revision
    Task {
      subagent_type: "general-purpose"
      description: "Revise plan to address $PARTIAL_THEOREM_COUNT blocking theorems"
      prompt: |
        Read and follow: .claude/commands/revise.md

        Revision context: $BLOCKING_SUMMARY
        Existing plan: $PLAN_PATH

        Add infrastructure phases for missing lemmas.
    }

    # After revision, recalculate dependencies for next wave
    reload_plan_dependencies "$PLAN_PATH"
  else
    # Insufficient context - defer to next session
    echo "CHECKPOINT: Partial results due to missing infrastructure"
    echo "MANUAL_INTERVENTION_REQUIRED: Run /revise to add infrastructure phases"
  fi
fi
```

**Benefits**:
- Eliminates manual intervention for common blocking patterns
- Maintains checkpoint continuity across revision
- Preserves user oversight via dry-run mode

**Risks**:
- Infinite revision loops if blockers not resolvable
- Context budget exhaustion from nested Task invocations
- Plan corruption if revision introduces syntax errors

**Mitigation**:
- Max revision depth limit (e.g., 2 revisions per wave)
- Hard barrier validation after each revision
- Automatic backup restoration on validation failure

### 2. Enhance Subagent Discovery Signal Structure

**Current Gap**: `work_remaining` is space-separated string, limiting metadata richness.

**Proposed Enhancement**:
```yaml
THEOREM_BATCH_COMPLETE:
  theorems_completed: ["theorem_add_comm"]
  theorems_partial:
    - name: "theorem_zero_add"
      blocker: "missing_lemma"
      blocker_details: "Requires Nat.zero_add lemma from Mathlib"
      suggested_action: "Add import Mathlib.Data.Nat.Basic"
    - name: "theorem_box_conj"
      blocker: "infrastructure_gap"
      blocker_details: "No classical_merge lemma available"
      suggested_action: "Add Phase 1.5 to implement classical_merge"
  work_remaining: Phase_3 Phase_4
  blocking_recommendations:
    - phase_to_add: "1.5"
      phase_title: "Classical Reasoning Infrastructure"
      tasks: ["Implement classical_merge", "Implement biconditional_intro"]
      depends_on: [1]
```

**Benefits**:
- Structured blocker information enables automated plan generation
- Suggested actions reduce research phase overhead
- Phase recommendations allow direct Edit tool operations

**Implementation**:
- Update lean-implementer.md output contract
- Add blocker detection logic during proof attempts
- Integrate with plan-architect's revision templates

### 3. Create Dependency Recalculation Utility

**Objective**: Provide standalone function for rebuilding dependency graph after plan revision.

**Design**:
```bash
# File: .claude/lib/plan/dependency-recalculation.sh

recalculate_wave_dependencies() {
  local plan_path="$1"
  local completed_phases="$2"  # Space-separated list

  # Parse plan structure
  source "${CLAUDE_LIB}/plan/plan-core-bundle.sh"
  ALL_PHASES=$(list_phases "$plan_path")

  # Build dependency graph
  declare -A phase_deps
  declare -A phase_status

  for phase in $ALL_PHASES; do
    phase_deps[$phase]=$(get_phase_dependencies "$plan_path" "$phase")
    phase_status[$phase]=$(get_phase_status "$plan_path" "$phase")
  done

  # Identify next wave candidates
  next_wave=""
  for phase in $ALL_PHASES; do
    # Skip completed phases
    [[ " $completed_phases " =~ " $phase " ]] && continue
    [[ "${phase_status[$phase]}" == "COMPLETE" ]] && continue

    # Check dependencies satisfied
    deps_satisfied=true
    for dep in ${phase_deps[$phase]}; do
      if ! [[ " $completed_phases " =~ " $dep " ]]; then
        deps_satisfied=false
        break
      fi
    done

    if [ "$deps_satisfied" = true ]; then
      next_wave="$next_wave $phase"
    fi
  done

  echo "$next_wave"
}
```

**Usage in Coordinator**:
```bash
# After plan revision
NEXT_WAVE_PHASES=$(recalculate_wave_dependencies "$PLAN_PATH" "$COMPLETED_PHASES")

# Execute recalculated wave
for phase in $NEXT_WAVE_PHASES; do
  invoke_lean_implementer "$phase"
done
```

**Benefits**:
- Reusable across lean-coordinator and implementer-coordinator
- Tier-agnostic (works with L0/L1/L2 plans)
- Enables dynamic wave replanning

### 4. Integrate Error Logging with Plan Revision

**Objective**: Bridge centralized error logging system with `/revise` workflow.

**Current State**: `/errors` command queries logged errors, `/repair` creates fix plans, but no direct link to plan revision.

**Proposed Integration**:
```bash
# In /revise command (Block 4a)
# Check for related errors in error log
source "${CLAUDE_LIB}/core/error-handling.sh"

ERROR_LOG="${CLAUDE_PROJECT_DIR}/.claude/data/errors/command-errors.jsonl"
PLAN_ERRORS=$(jq -r --arg plan "$EXISTING_PLAN_PATH" \
  'select(.details.plan_path == $plan) | .error_message' \
  "$ERROR_LOG" | tail -5)

if [ -n "$PLAN_ERRORS" ]; then
  echo "=== Related Errors from Log ==="
  echo "$PLAN_ERRORS"
  echo ""

  # Inject errors into research-specialist prompt
  RESEARCH_CONTEXT="$REVISION_DETAILS

Recent errors for this plan:
$PLAN_ERRORS"
fi
```

**Benefits**:
- Research-specialist has full error context
- Reduces duplicate error analysis
- Enables error-driven revision recommendations

### 5. Implement Partial Success Thresholds

**Objective**: Define when coordinators should proceed vs trigger revision.

**Proposed Thresholds**:
```yaml
# In coordinator configuration
PARTIAL_SUCCESS_THRESHOLD=0.5  # 50% theorems proven

# After wave completion
SUCCESS_RATE=$(echo "scale=2; $THEOREMS_PROVEN / $TOTAL_THEOREMS" | bc)

if (( $(echo "$SUCCESS_RATE >= $PARTIAL_SUCCESS_THRESHOLD" | bc -l) )); then
  # Acceptable progress - continue to next wave
  echo "Wave $WAVE_NUM: $SUCCESS_RATE success rate (>= $PARTIAL_SUCCESS_THRESHOLD threshold)"
  continue_to_next_wave
else
  # Insufficient progress - trigger revision
  echo "Wave $WAVE_NUM: $SUCCESS_RATE success rate (< $PARTIAL_SUCCESS_THRESHOLD threshold)"
  echo "Triggering plan revision to address blockers"
  trigger_plan_revision "$BLOCKING_ISSUES"
fi
```

**Benefits**:
- Avoids premature revision for minor blockers
- Configurable threshold per project complexity
- Preserves context budget for high-value revisions

### 6. Add Plan Diff Visualization

**Objective**: Show users what changed after automated plan revision.

**Design**:
```bash
# In /revise Block 6 (completion)
echo "=== Plan Revision Diff ==="
diff -u "$BACKUP_PATH" "$EXISTING_PLAN_PATH" | head -50

echo ""
echo "Summary of Changes:"
PHASES_ADDED=$(diff "$BACKUP_PATH" "$EXISTING_PLAN_PATH" | grep "^+### Phase" | wc -l)
TASKS_ADDED=$(diff "$BACKUP_PATH" "$EXISTING_PLAN_PATH" | grep "^+- \[ \]" | wc -l)
DEPS_MODIFIED=$(diff "$BACKUP_PATH" "$EXISTING_PLAN_PATH" | grep "^+depends_on:" | wc -l)

echo "  - Phases added: $PHASES_ADDED"
echo "  - Tasks added: $TASKS_ADDED"
echo "  - Dependencies modified: $DEPS_MODIFIED"
```

**Benefits**:
- Clear visibility into automated changes
- Enables rollback decisions
- Auditable revision history

---

## Conclusion

The current architecture provides robust foundations for subagent discovery and plan revision through:
1. Structured completion signals with `work_remaining` and `theorems_partial` fields
2. Metadata-only passing for 95% context reduction
3. Manual `/revise` workflow with hard barrier validation
4. State machine persistence across bash blocks

**Critical Gap**: No automated coordinator-triggered plan revision. This requires:
- Coordinator logic to detect blocking threshold
- Context budget management for nested Task invocations
- Dependency recalculation utility for wave replanning

**Recommended Next Steps**:
1. Implement `recalculate_wave_dependencies()` utility (Recommendation 3)
2. Enhance lean-implementer output signal with blocker metadata (Recommendation 2)
3. Prototype coordinator-triggered revision with dry-run mode (Recommendation 1)
4. Define partial success thresholds per project complexity (Recommendation 5)

The system is well-positioned for automated plan revision with modest enhancements to coordinator decision logic and utility libraries.
