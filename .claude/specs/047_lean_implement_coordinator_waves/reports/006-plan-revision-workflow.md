# Coordinator-Triggered Plan Revision Workflow Analysis

**Research Date**: 2025-12-09
**Research Scope**: Analyze blocking dependency detection patterns in Lean theorem proving, context budget calculation strategies, revision depth tracking mechanisms, integration patterns for /revise command delegation from coordinators, dependency recalculation workflows, and error handling for revision failures
**Workflow Context**: Phase 8 of spec 047 - Lean-implement coordinator wave-based orchestration

---

## Executive Summary

This analysis examines how lean-coordinator can automatically detect blocking dependencies during theorem proving, trigger plan revision workflows via Task delegation, and recalculate wave dependencies for continued execution. The research reveals:

1. **Blocking Detection Signal**: The `theorems_partial` field from lean-implementer output provides structured data on incomplete proofs requiring infrastructure
2. **Context Budget Strategy**: Minimum 30,000 tokens (15% of 200k window) required for /revise workflow to complete research and plan modification
3. **Revision Depth Tracking**: Workflow state-based counter with MAX_REVISION_DEPTH=2 prevents infinite loops
4. **Task Delegation Pattern**: Bash conditional blocks with imperative directives enable standards-compliant /revise invocation from coordinators
5. **Dependency Recalculation**: The newly created dependency-recalculation.sh utility provides tier-agnostic wave recalculation after plan modifications
6. **Error Recovery**: Structured error logging via log_command_error enables queryable debugging of revision failures

**Key Finding**: The architecture supports automated coordinator-triggered plan revision with defensive safeguards, but introduces architectural complexity requiring careful integration. Recommended as a separate focused spec due to scope and risk considerations.

**Recommended Approach**: Defer Phase 8 to spec 048 to manage complexity and enable test-driven development with isolated validation.

---

## Findings

### 1. Blocking Dependency Detection Patterns

#### 1.1 lean-implementer Output Signal Structure

**Source**: `/home/benjamin/.config/.claude/agents/lean-implementer.md` (lines 664-676)

The lean-implementer agent returns structured completion signals after theorem proving attempts:

```yaml
THEOREM_BATCH_COMPLETE:
  theorems_completed: ["theorem_add_comm", "theorem_mul_assoc"]
  theorems_partial: ["theorem_zero_add"]
  tactics_used: ["exact", "ring", "simp"]
  mathlib_theorems: ["Nat.add_comm", "Algebra.Ring.Basic"]
  diagnostics: []
  context_exhausted: false
  work_remaining: Phase_3  # Space-separated string (NOT JSON array)
  wave_number: 1
  budget_consumed: 2
```

**Key Detection Fields for Plan Revision**:
- `theorems_partial`: List of theorem names with incomplete proofs (some `sorry` remain)
- `diagnostics`: Error messages indicating specific blockers (e.g., "unknown identifier", "type mismatch")
- `work_remaining`: Space-separated string of incomplete phase identifiers
- `context_exhausted`: Boolean indicating if agent context threshold approached

**Example from Real Execution** (lean-implement-output.md):
```
Phase 2 has 3/6 theorems complete with some blocked on infrastructure.
Phase 2 has 3/6 theorems proven with 3 more blocked on infrastructure gaps
(classical merge lemma, biconditional infrastructure).
```

#### 1.2 Blocking Issue Extraction Pattern

**Bash Pattern for lean-coordinator**:
```bash
# Parse theorems_partial field from lean-implementer output
PARTIAL_THEOREMS=$(grep "^  theorems_partial:" "$IMPLEMENTER_OUTPUT" | \
                   sed 's/theorems_partial:[[:space:]]*//' | \
                   tr -d '[],' | xargs)
PARTIAL_COUNT=$(echo "$PARTIAL_THEOREMS" | wc -w)

# Extract diagnostic blockers (e.g., "unknown identifier: classical_merge")
BLOCKING_DIAGNOSTICS=$(grep "^  diagnostics:" "$IMPLEMENTER_OUTPUT" | \
                       sed 's/diagnostics:[[:space:]]*//')

# Build structured blocking summary for /revise prompt
if [ "$PARTIAL_COUNT" -gt 0 ]; then
  BLOCKING_SUMMARY=$(cat <<EOF
Blocking Dependencies Detected:
- Partial Theorems: $PARTIAL_THEOREMS
- Diagnostic Messages: $BLOCKING_DIAGNOSTICS
- Work Remaining: $WORK_REMAINING_NEW

Infrastructure gaps prevent completion of $PARTIAL_COUNT theorems.
EOF
  )
fi
```

**Detection Trigger Criteria**:
1. `PARTIAL_COUNT > 0` (at least one theorem incomplete)
2. `diagnostics` contains infrastructure-related errors (e.g., "unknown identifier", "missing lemma")
3. `work_remaining` non-empty (phases still pending)
4. Context budget available (see Section 2)

#### 1.3 Diagnostic Error Patterns Indicating Infrastructure Gaps

**Analysis of Lean Error Types**:
- `"unknown identifier"`: Missing definition/theorem (requires new phase)
- `"type mismatch"`: Type infrastructure incomplete (requires foundational lemma)
- `"tactic failed"`: Proof strategy blocked on missing tactic (requires tactic library)
- `"elaboration error"`: Syntax/structure gap (requires notation or typeclass instance)

**Heuristic for Infrastructure vs Proof Complexity**:
- Infrastructure gap: Multiple theorems blocked by same missing identifier
- Proof complexity: Single theorem failed, others succeeded with same infrastructure
- **Decision Rule**: Trigger revision if ≥2 theorems share same blocking diagnostic

---

### 2. Context Budget Calculation and Threshold Management

#### 2.1 Context Budget Requirements for /revise Workflow

**Source**: `/home/benjamin/.config/.claude/commands/revise.md` (Blocks 1-6)

The /revise command consists of 6 bash blocks and 2 agent invocations:

| Component | Token Cost (Estimated) | Notes |
|-----------|----------------------|-------|
| Bash blocks (1a-6) | 2,000 tokens | Argument capture, state machine, validation |
| research-specialist agent | 12,000 tokens | Research phase output (reports, analysis) |
| plan-architect agent | 10,000 tokens | Plan revision phase (backup, Edit operations) |
| **Total Cost** | **24,000 tokens** | Minimum context required |

**Safety Margin**: Add 25% buffer → **30,000 tokens** (15% of 200k window)

#### 2.2 Context Budget Calculation Strategy

**Bash Implementation**:
```bash
# Get current context usage from coordinator state
CURRENT_CONTEXT=$(get_context_usage)  # Returns token count estimate

# Calculate remaining context
CONTEXT_WINDOW=200000  # Claude Opus 4.5 context window
CONTEXT_REMAINING=$((CONTEXT_WINDOW - CURRENT_CONTEXT))

# Minimum required for /revise workflow (30k tokens)
REVISION_MIN_CONTEXT=30000

# Check if revision is viable
if [ "$CONTEXT_REMAINING" -ge "$REVISION_MIN_CONTEXT" ]; then
  echo "Sufficient context for plan revision: ${CONTEXT_REMAINING} tokens available"
  REVISION_VIABLE=true
else
  echo "Insufficient context for revision: ${CONTEXT_REMAINING} < ${REVISION_MIN_CONTEXT}"
  REVISION_VIABLE=false
fi
```

#### 2.3 Context Estimation Utility Function

**New Function for lean-coordinator.md**:
```bash
# Estimate current context usage based on coordinator progress
get_context_usage() {
  local completed_waves="${1:-0}"
  local total_waves="${2:-1}"
  local has_continuation="${3:-false}"

  # Context cost model for Lean workflows
  local base=15000  # Plan file + lean file + standards + system prompt
  local per_wave=8000  # Average context per wave (implementer output summaries)
  local continuation_cost=0

  if [ "$has_continuation" = "true" ]; then
    continuation_cost=5000  # Previous iteration summary
  fi

  local total=$((base + (completed_waves * per_wave) + continuation_cost))

  echo "$total"
}
```

**Usage in lean-coordinator Wave Loop**:
```bash
# After each wave completion
CURRENT_WAVE=2
TOTAL_WAVES=4
CURRENT_CONTEXT=$(get_context_usage "$CURRENT_WAVE" "$TOTAL_WAVES" "$HAS_CONTINUATION")
CONTEXT_PERCENT=$((CURRENT_CONTEXT * 100 / 200000))

echo "Context usage after wave $CURRENT_WAVE: ${CONTEXT_PERCENT}% (${CURRENT_CONTEXT} tokens)"
```

#### 2.4 Context Threshold Decision Matrix

| Context Usage | Revision Viable | Action |
|---------------|-----------------|--------|
| 0-70% (0-140k) | Yes | Proceed with revision if blockers detected |
| 71-85% (141k-170k) | Marginal | Only revise if critical blockers (>50% theorems blocked) |
| 86-100% (171k+) | No | Skip revision, create checkpoint with revision_deferred flag |

**Implementation**:
```bash
if [ "$PARTIAL_COUNT" -gt 0 ]; then
  CONTEXT_PERCENT=$((CURRENT_CONTEXT * 100 / 200000))

  if [ "$CONTEXT_PERCENT" -le 70 ]; then
    echo "Context low ($CONTEXT_PERCENT%) - proceeding with plan revision"
    TRIGGER_REVISION=true
  elif [ "$CONTEXT_PERCENT" -le 85 ]; then
    # Marginal context - only revise if critical blockers
    BLOCKING_RATE=$((PARTIAL_COUNT * 100 / TOTAL_THEOREMS))
    if [ "$BLOCKING_RATE" -ge 50 ]; then
      echo "Critical blocking rate ($BLOCKING_RATE%) - proceeding with revision at $CONTEXT_PERCENT% context"
      TRIGGER_REVISION=true
    else
      echo "Marginal context ($CONTEXT_PERCENT%) - deferring revision (blocking rate: $BLOCKING_RATE%)"
      TRIGGER_REVISION=false
    fi
  else
    echo "High context usage ($CONTEXT_PERCENT%) - deferring revision to next cycle"
    TRIGGER_REVISION=false
  fi
fi
```

---

### 3. Revision Depth Tracking and Loop Prevention

#### 3.1 Revision Depth Counter Pattern

**Workflow State Integration**:
```bash
# Initialize revision depth counter in workflow state
append_workflow_state "REVISION_DEPTH" "0"
append_workflow_state "MAX_REVISION_DEPTH" "2"

# Increment on each revision trigger
REVISION_DEPTH=$(grep "^REVISION_DEPTH=" "$STATE_FILE" | cut -d'=' -f2 || echo "0")
REVISION_DEPTH=$((REVISION_DEPTH + 1))
append_workflow_state "REVISION_DEPTH" "$REVISION_DEPTH"
```

#### 3.2 Loop Prevention Logic

**Enforcement Pattern**:
```bash
# Check revision depth before triggering /revise
MAX_REVISION_DEPTH=$(grep "^MAX_REVISION_DEPTH=" "$STATE_FILE" | cut -d'=' -f2 || echo "2")
REVISION_DEPTH=$(grep "^REVISION_DEPTH=" "$STATE_FILE" | cut -d'=' -f2 || echo "0")

if [ "$REVISION_DEPTH" -ge "$MAX_REVISION_DEPTH" ]; then
  echo "WARNING: Max revision depth ($MAX_REVISION_DEPTH) reached - manual intervention required" >&2
  echo "Deferred blocking issues: $PARTIAL_THEOREMS" >&2

  # Log revision limit error
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" \
    "Revision depth limit exceeded: $REVISION_DEPTH >= $MAX_REVISION_DEPTH" \
    "wave_execution_loop" \
    "$(jq -n --argjson depth "$REVISION_DEPTH" --argjson max "$MAX_REVISION_DEPTH" \
       --arg partial "$PARTIAL_THEOREMS" \
       '{revision_depth: $depth, max_depth: $max, partial_theorems: $partial}')"

  # Set flag for user intervention
  append_workflow_state "REVISION_LIMIT_REACHED" "true"
  TRIGGER_REVISION=false
else
  echo "Revision depth check passed: $REVISION_DEPTH < $MAX_REVISION_DEPTH"
  TRIGGER_REVISION=true
fi
```

#### 3.3 Depth Reset Strategy

**When to Reset Counter**:
1. **Wave Completion**: Reset after each complete wave (all phases succeeded)
2. **Iteration Boundary**: Reset at start of new iteration (continuation context)
3. **Manual Override**: User explicitly resets via checkpoint modification

**Implementation**:
```bash
# Reset revision depth on wave success (no partial theorems)
if [ "$PARTIAL_COUNT" -eq 0 ]; then
  echo "Wave completed successfully - resetting revision depth counter"
  append_workflow_state "REVISION_DEPTH" "0"
fi
```

#### 3.4 Alternative: Per-Wave Revision Tracking

**More Granular Approach**:
```bash
# Track revisions per wave instead of global counter
append_workflow_state "WAVE_${CURRENT_WAVE}_REVISION_COUNT" "0"

# Increment per-wave counter
WAVE_REVISIONS=$(grep "^WAVE_${CURRENT_WAVE}_REVISION_COUNT=" "$STATE_FILE" | cut -d'=' -f2 || echo "0")
WAVE_REVISIONS=$((WAVE_REVISIONS + 1))

if [ "$WAVE_REVISIONS" -ge 2 ]; then
  echo "Max revisions for wave $CURRENT_WAVE reached - moving to next wave"
  TRIGGER_REVISION=false
fi
```

**Trade-offs**:
- **Global Counter**: Simpler implementation, prevents total revision explosion
- **Per-Wave Counter**: More granular control, allows multiple waves to receive revisions
- **Recommendation**: Use global counter for Phase 8 MVP, add per-wave tracking in future enhancement

---

### 4. Integration Patterns for /revise Command Delegation

#### 4.1 Standards-Compliant Task Invocation Pattern

**Source**: `/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md` (Task Tool Invocation Patterns section)

**Bash Conditional + Imperative Directive Pattern**:
```bash
# Bash block: Calculate revision parameters
if [ "$TRIGGER_REVISION" = "true" ]; then
  REVISION_DESCRIPTION="Revise plan at $PLAN_PATH to add infrastructure for blocking dependencies: $BLOCKING_SUMMARY"

  # Persist parameters for Task invocation
  append_workflow_state "REVISION_DESCRIPTION" "$REVISION_DESCRIPTION"
  append_workflow_state "REVISION_TRIGGERED" "true"

  echo "Triggering plan revision via /revise command..."
fi
```

**Subsequent Task Invocation Block** (after bash block):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the /revise command.

Task {
  subagent_type: "general-purpose"
  description: "Revise plan to address blocking dependencies in wave ${CURRENT_WAVE}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/commands/revise.md

    You are executing a plan revision workflow triggered by coordinator blocking dependency detection.

    **Revision Description**:
    ${REVISION_DESCRIPTION}

    **Context**:
    - Plan Path: ${PLAN_PATH}
    - Wave Number: ${CURRENT_WAVE}
    - Partial Theorems: ${PARTIAL_THEOREMS}
    - Blocking Diagnostics: ${BLOCKING_DIAGNOSTICS}

    **Revision Requirements**:
    1. Analyze blocking diagnostics to identify missing infrastructure
    2. Create research report documenting infrastructure gaps
    3. Add new phases for infrastructure lemmas/definitions
    4. Update dependency metadata to ensure proper wave sequencing
    5. Preserve all [COMPLETE] phases unchanged

    Execute /revise workflow and return completion signal:
    PLAN_REVISED: ${PLAN_PATH}
  "
}
```

#### 4.2 /revise Command Integration Requirements

**Input Contract for Coordinator-Triggered Revision**:
```bash
# /revise command expects description format:
# "revise plan at /path/to/plan.md based on INSIGHTS"

# Coordinator constructs description from blocking data
REVISION_PROMPT="revise plan at $PLAN_PATH based on lean-coordinator blocking dependency analysis:

Blocking Dependencies Detected in Wave $CURRENT_WAVE:
- Partial Theorems: $PARTIAL_THEOREMS ($PARTIAL_COUNT incomplete)
- Diagnostic Messages: $BLOCKING_DIAGNOSTICS
- Infrastructure Gaps: Missing lemmas for classical logic, biconditional properties

Recommended Actions:
1. Add Phase X: Infrastructure - Classical Lemmas
   - Prove classical_merge lemma
   - Prove double_negation equivalence
   Dependencies: [existing foundational phases]

2. Add Phase Y: Infrastructure - Biconditional Properties
   - Prove biconditional_symmetry
   - Prove biconditional_transitivity
   Dependencies: [Phase X]

Update wave dependencies to sequence infrastructure before blocked theorems.
"
```

#### 4.3 Return Signal Parsing

**Expected Output from /revise**:
```yaml
PLAN_REVISED: /path/to/plan.md
```

**Coordinator Parsing Pattern**:
```bash
# Parse /revise completion signal
PLAN_REVISED_PATH=$(echo "$REVISE_OUTPUT" | grep "^PLAN_REVISED:" | sed 's/PLAN_REVISED:[[:space:]]*//')

if [ -n "$PLAN_REVISED_PATH" ]; then
  echo "Plan revision completed: $PLAN_REVISED_PATH"

  # Verify plan was actually modified (not just backup created)
  if [ -f "$PLAN_REVISED_PATH" ]; then
    # Update workflow state with revision metadata
    append_workflow_state "PLAN_REVISED" "true"
    append_workflow_state "PLAN_REVISION_WAVE" "$CURRENT_WAVE"

    # Trigger dependency recalculation (see Section 5)
    RECALC_DEPENDENCIES=true
  else
    echo "ERROR: Plan revision claimed success but file not found: $PLAN_REVISED_PATH" >&2
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "agent_error" \
      "/revise returned success but plan file missing" \
      "revision_workflow" \
      "$(jq -n --arg path "$PLAN_REVISED_PATH" '{expected_plan: $path}')"
  fi
else
  echo "WARNING: /revise did not return PLAN_REVISED signal" >&2
  RECALC_DEPENDENCIES=false
fi
```

---

### 5. Dependency Recalculation Workflows After Plan Modifications

#### 5.1 dependency-recalculation.sh Integration

**Source**: `/home/benjamin/.config/.claude/lib/plan/dependency-recalculation.sh` (created in Phase 7)

**Function Signature**:
```bash
recalculate_wave_dependencies() {
  local plan_path="$1"
  local completed_phases="$2"  # Space-separated list

  # Returns: Space-separated list of next wave phase numbers
}
```

**Tier-Agnostic Support**: Works with L0 (inline), L1 (phase files), L2 (stage files) plan structures.

#### 5.2 Integration Pattern in lean-coordinator

**After Plan Revision**:
```bash
if [ "$PLAN_REVISED" = "true" ]; then
  echo "Recalculating wave dependencies after plan revision..."

  # Source dependency recalculation utility
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/dependency-recalculation.sh" 2>/dev/null || {
    echo "ERROR: Cannot load dependency-recalculation.sh" >&2
    exit 1
  }

  # Get list of completed phases (from plan file markers)
  COMPLETED_PHASES=$(grep -oE "^### Phase ([0-9]+):.*\[COMPLETE\]" "$PLAN_PATH" | \
                     grep -oE "[0-9]+" | xargs)

  # Recalculate next wave based on updated plan dependencies
  NEXT_WAVE_PHASES=$(recalculate_wave_dependencies "$PLAN_PATH" "$COMPLETED_PHASES")

  if [ -n "$NEXT_WAVE_PHASES" ]; then
    echo "Next wave after revision: $NEXT_WAVE_PHASES"

    # Update wave structure in coordinator state
    append_workflow_state "NEXT_WAVE_PHASES" "$NEXT_WAVE_PHASES"
    append_workflow_state "DEPENDENCIES_RECALCULATED" "true"

    # Continue with revised wave execution
    CONTINUE_EXECUTION=true
  else
    echo "No phases ready for execution after revision (dependencies not satisfied)"
    CONTINUE_EXECUTION=false
  fi
fi
```

#### 5.3 Wave Structure Rebuild

**Full Dependency Graph Recalculation**:
```bash
# Alternative: Rebuild complete wave structure using dependency-analyzer.sh
source "${CLAUDE_PROJECT_DIR}/.claude/lib/util/dependency-analyzer.sh"

# Analyze revised plan structure
DEPENDENCY_ANALYSIS=$(analyze_dependencies "$PLAN_PATH")

# Extract updated wave structure
WAVE_STRUCTURE=$(echo "$DEPENDENCY_ANALYSIS" | jq -r '.waves')

# Log wave structure changes
echo "Wave structure after revision:"
echo "$WAVE_STRUCTURE" | jq -r '.[] | "Wave \(.wave_number): phases \(.phases | join(", "))"'

# Update coordinator execution state
append_workflow_state "WAVE_STRUCTURE" "$WAVE_STRUCTURE"
append_workflow_state "TOTAL_WAVES" "$(echo "$WAVE_STRUCTURE" | jq 'length')"
```

#### 5.4 Partial Wave Retry Strategy

**Scenario**: Wave 2 had 4 phases, 2 succeeded, 2 blocked on infrastructure. Plan revision adds Phase X (infrastructure). What phases run in next wave?

**Strategy Options**:

1. **Retry Blocked Phases Only** (Recommended):
   - Next wave: [Blocked phases from Wave 2] + [New infrastructure phases ready]
   - Avoids re-executing successful phases
   - Requires phase-level completion tracking

2. **Retry Entire Wave**:
   - Next wave: [All phases from Wave 2]
   - Simpler implementation (wave-level granularity)
   - Wastes resources re-running successful phases

3. **Dynamic Wave Reconstruction**:
   - Next wave: [All phases with satisfied dependencies and no [COMPLETE] marker]
   - Most flexible, adapts to any revision pattern
   - Relies on dependency-recalculation.sh

**Implementation (Strategy 3 - Dynamic)**:
```bash
# After plan revision, recalculate waves considering both:
# 1. Completed phases (have [COMPLETE] marker)
# 2. Updated dependencies from revised plan

COMPLETED_PHASES=$(grep -oE "^### Phase ([0-9]+):.*\[COMPLETE\]" "$PLAN_PATH" | \
                   grep -oE "[0-9]+" | xargs)

# Get next wave candidates (dependency-recalculation.sh handles this)
NEXT_WAVE=$(recalculate_wave_dependencies "$PLAN_PATH" "$COMPLETED_PHASES")

echo "Next wave after revision (dynamic recalculation): $NEXT_WAVE"
```

---

### 6. Error Handling for Revision Failures

#### 6.1 Error Types and Recovery Strategies

**Source**: `/home/benjamin/.config/.claude/lib/core/error-handling.sh`

| Error Type | Cause | Recovery Strategy | Error Code |
|------------|-------|------------------|-----------|
| `agent_error` | /revise agent failed or returned invalid signal | Skip revision, continue with available work | agent_error |
| `validation_error` | Revised plan structure invalid (missing phases, malformed metadata) | Restore from backup, log failure | validation_error |
| `file_error` | Plan file corrupted or inaccessible after revision | Restore from backup, halt workflow | file_error |
| `dependency_error` | Circular dependencies introduced by revision | Revert plan, warn user | dependency_error |
| `context_error` | Insufficient context for revision workflow | Defer revision to next iteration | execution_error |

#### 6.2 Error Logging Pattern

**Implementation**:
```bash
# Log revision failure with structured error data
log_revision_error() {
  local error_type="$1"
  local error_message="$2"
  local error_details="$3"

  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$error_type" \
    "Plan revision failed: $error_message" \
    "revision_workflow_wave_${CURRENT_WAVE}" \
    "$error_details"
}

# Usage after /revise invocation
if [ -z "$PLAN_REVISED_PATH" ]; then
  log_revision_error \
    "agent_error" \
    "/revise agent did not return PLAN_REVISED signal" \
    "$(jq -n \
      --argjson wave "$CURRENT_WAVE" \
      --arg partial "$PARTIAL_THEOREMS" \
      --arg output "$REVISE_OUTPUT" \
      '{wave: $wave, partial_theorems: $partial, agent_output_length: ($output | length)}')"
fi
```

#### 6.3 Plan Backup Verification

**/revise Command Backup Guarantee**:
- /revise creates backup at `${SPECS_DIR}/backups/${PLAN_BASENAME}_backup_${TIMESTAMP}.md` (Block 5a)
- Hard barrier validation ensures backup exists before any Edit operations (Block 5c)
- Coordinator can restore from backup on validation failure

**Restoration Pattern**:
```bash
# Verify plan integrity after revision
validate_revised_plan() {
  local plan_path="$1"

  # Check file exists
  if [ ! -f "$plan_path" ]; then
    echo "ERROR: Revised plan file missing: $plan_path" >&2
    return 1
  fi

  # Check for valid phase structure (at least one phase heading)
  PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$plan_path" || echo "0")
  if [ "$PHASE_COUNT" -lt 1 ]; then
    echo "ERROR: Revised plan has no phase headings (invalid structure)" >&2
    return 1
  fi

  # Check for metadata completeness
  if ! grep -q "^**Date**:" "$plan_path"; then
    echo "WARNING: Revised plan missing Date metadata" >&2
  fi

  return 0
}

# After /revise completes
if ! validate_revised_plan "$PLAN_REVISED_PATH"; then
  echo "Plan validation failed - restoring from backup..."

  # Find most recent backup
  BACKUP_DIR="$(dirname "$(dirname "$PLAN_PATH")")/backups"
  LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/*.md | head -1)

  if [ -n "$LATEST_BACKUP" ]; then
    cp "$LATEST_BACKUP" "$PLAN_PATH"
    echo "Restored plan from backup: $LATEST_BACKUP"

    log_revision_error \
      "validation_error" \
      "Revised plan validation failed - restored from backup" \
      "$(jq -n --arg backup "$LATEST_BACKUP" '{restored_from: $backup}')"
  else
    echo "ERROR: No backup found for restoration" >&2
    exit 1
  fi
fi
```

#### 6.4 Dependency Cycle Detection

**Post-Revision Validation**:
```bash
# Validate no circular dependencies introduced
source "${CLAUDE_PROJECT_DIR}/.claude/lib/util/dependency-analyzer.sh"

DEPENDENCY_ANALYSIS=$(analyze_dependencies "$PLAN_REVISED_PATH" 2>&1)
ANALYSIS_EXIT=$?

if [ $ANALYSIS_EXIT -ne 0 ]; then
  # Dependency analysis failed (likely circular dependency)
  if echo "$DEPENDENCY_ANALYSIS" | grep -q "circular dependency"; then
    echo "ERROR: Plan revision introduced circular dependency" >&2

    log_revision_error \
      "dependency_error" \
      "Circular dependency detected in revised plan" \
      "$(jq -n --arg analysis "$DEPENDENCY_ANALYSIS" '{dependency_analysis_output: $analysis}')"

    # Restore from backup
    # (restoration pattern from previous section)
  fi
fi
```

#### 6.5 Context Exhaustion Handling

**Insufficient Context for Revision**:
```bash
# Before triggering revision
if [ "$CONTEXT_REMAINING" -lt "$REVISION_MIN_CONTEXT" ]; then
  echo "WARNING: Insufficient context for revision ($CONTEXT_REMAINING < $REVISION_MIN_CONTEXT)" >&2

  # Save checkpoint with revision_deferred flag
  CHECKPOINT_DATA=$(jq -n \
    --arg plan "$PLAN_PATH" \
    --argjson wave "$CURRENT_WAVE" \
    --arg partial "$PARTIAL_THEOREMS" \
    --arg blocking "$BLOCKING_DIAGNOSTICS" \
    --argjson context "$CONTEXT_REMAINING" \
    '{
      version: "2.1",
      plan_path: $plan,
      current_wave: $wave,
      partial_theorems: $partial,
      blocking_diagnostics: $blocking,
      context_remaining: $context,
      revision_deferred: true,
      revision_reason: "insufficient_context"
    }')

  CHECKPOINT_FILE=$(save_checkpoint "lean_coordinator" "$WORKFLOW_ID" "$CHECKPOINT_DATA")

  echo "Checkpoint saved with deferred revision: $CHECKPOINT_FILE"

  # Log context exhaustion
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "execution_error" \
    "Revision deferred due to insufficient context" \
    "revision_workflow_wave_${CURRENT_WAVE}" \
    "$(jq -n --argjson context "$CONTEXT_REMAINING" --argjson min "$REVISION_MIN_CONTEXT" \
       '{context_remaining: $context, min_required: $min}')"

  # Set return flag for orchestrator
  append_workflow_state "REVISION_DEFERRED" "true"
  append_workflow_state "REQUIRES_CONTINUATION" "true"
fi
```

---

## Integration Recommendations

### Recommended Approach: Defer to Separate Spec (048)

**Rationale**:
1. **Architectural Complexity**: Coordinator-triggered plan revision requires significant behavioral changes to lean-coordinator.md (new STEP after wave execution loop)
2. **Risk Management**: Automated revision introduces risk of plan corruption, infinite loops, and resource exhaustion
3. **Test Coverage**: Requires comprehensive integration tests for revision triggers, backup/restore, and dependency recalculation
4. **Scope Creep**: Phase 8 is an enhancement feature, not core functionality for wave-based orchestration

**Recommended Separation**:
- **Spec 047 (Current)**: Focus on Phases 0-7 (standards compliance, checkpoint resume, context tracking)
- **Spec 048 (Future)**: Dedicated spec for coordinator-triggered plan revision with isolated test-driven development

### If Implemented in Spec 047: Integration Points

#### 1. lean-coordinator.md Modifications

**New STEP 4.5: Blocking Dependency Detection and Revision**

Location: After STEP 4 (Wave Execution Loop), before STEP 5 (Result Aggregation)

```markdown
### STEP 4.5: Blocking Dependency Detection and Plan Revision

After each wave completes, check for blocking dependencies and trigger plan revision if viable.

#### Blocking Detection

Parse implementer outputs for partial theorems:

```bash
# Parse theorems_partial from all implementers in wave
PARTIAL_THEOREMS=""
for implementer_output in "${IMPLEMENTER_OUTPUTS[@]}"; do
  partial=$(grep "^  theorems_partial:" "$implementer_output" | \
            sed 's/theorems_partial:[[:space:]]*//' | tr -d '[],' | xargs)
  PARTIAL_THEOREMS="$PARTIAL_THEOREMS $partial"
done
PARTIAL_THEOREMS=$(echo "$PARTIAL_THEOREMS" | xargs)  # Trim whitespace
PARTIAL_COUNT=$(echo "$PARTIAL_THEOREMS" | wc -w)
```

#### Revision Viability Check

Evaluate context budget and revision depth:

```bash
if [ "$PARTIAL_COUNT" -gt 0 ]; then
  # Check context budget (see Section 2.2)
  CURRENT_CONTEXT=$(get_context_usage "$CURRENT_WAVE" "$TOTAL_WAVES" "$HAS_CONTINUATION")
  CONTEXT_REMAINING=$((200000 - CURRENT_CONTEXT))

  # Check revision depth (see Section 3.2)
  REVISION_DEPTH=$(grep "^REVISION_DEPTH=" "$STATE_FILE" | cut -d'=' -f2 || echo "0")
  MAX_REVISION_DEPTH=$(grep "^MAX_REVISION_DEPTH=" "$STATE_FILE" | cut -d'=' -f2 || echo "2")

  if [ "$CONTEXT_REMAINING" -ge 30000 ] && [ "$REVISION_DEPTH" -lt "$MAX_REVISION_DEPTH" ]; then
    TRIGGER_REVISION=true
  else
    TRIGGER_REVISION=false
  fi
fi
```

#### Revision Trigger

If viable, invoke /revise via Task delegation:

**EXECUTE NOW**: USE the Task tool to invoke the /revise command.

Task {
  subagent_type: "general-purpose"
  description: "Revise plan for blocking dependencies in wave ${CURRENT_WAVE}"
  prompt: "
    Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/commands/revise.md

    [Revision prompt from Section 4.2]
  "
}

#### Dependency Recalculation

After revision, recalculate waves:

```bash
if [ "$PLAN_REVISED" = "true" ]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/dependency-recalculation.sh"

  COMPLETED_PHASES=$(grep -oE "^### Phase ([0-9]+):.*\[COMPLETE\]" "$PLAN_PATH" | \
                     grep -oE "[0-9]+" | xargs)

  NEXT_WAVE_PHASES=$(recalculate_wave_dependencies "$PLAN_PATH" "$COMPLETED_PHASES")

  # Update wave structure and continue
fi
```
```

#### 2. Output Signal Extension

**New Field in lean-coordinator Return Signal**:
```yaml
PROOF_COMPLETE:
  coordinator_type: lean
  summary_path: /path/to/summary.md
  summary_brief: "..."
  phases_completed: [1, 2]
  theorem_count: 15
  work_remaining: Phase_4 Phase_5
  context_exhausted: false
  requires_continuation: true
  revision_triggered: true  # NEW FIELD
  revision_depth: 1  # NEW FIELD
  revised_plan_path: /path/to/plan.md  # NEW FIELD (if revision occurred)
```

#### 3. Error Logging Integration

**Source error-handling.sh and log all revision errors**:
```bash
# In lean-coordinator STEP 0 (initialization)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}
ensure_error_log_exists

# Set command metadata
COMMAND_NAME="/lean-coordinator"
WORKFLOW_ID="${WORKFLOW_ID:-lean_coord_$(date +%s)}"
USER_ARGS="${PLAN_PATH:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

---

## Performance and Risk Analysis

### Context Overhead

| Component | Token Cost | Percentage of 200k Window |
|-----------|-----------|--------------------------|
| Base coordinator cost | 15,000 | 7.5% |
| Per-wave cost (avg) | 8,000 | 4.0% |
| Revision workflow | 30,000 | 15.0% |
| **Total for 3 waves + 1 revision** | **63,000** | **31.5%** |

**Implication**: Coordinator can handle ~3 waves + 1 revision before approaching 50% context threshold (100k tokens).

### Revision Success Rate Estimates

**Assumptions**:
- 20% of waves encounter blocking dependencies
- 80% of revisions successfully resolve blockers
- 10% of revisions introduce new issues (require revert)
- 10% of revisions hit context/depth limits

**Expected Workflow Outcomes**:
- 80% of plans complete without revision (no blockers)
- 16% of plans complete after successful revision (20% × 80%)
- 2% of plans require manual intervention (20% × 10%)
- 2% of plans hit revision limits (20% × 10%)

### Risk Mitigation Strategies

1. **Revision Depth Limit (MAX_REVISION_DEPTH=2)**:
   - Prevents infinite loops
   - Forces manual intervention on persistent blockers

2. **Context Budget Check (30k minimum)**:
   - Ensures /revise has sufficient context to complete
   - Defers revision to next iteration if budget exhausted

3. **Plan Backup Guarantee**:
   - /revise hard barrier ensures backup before modifications
   - Coordinator can restore on validation failure

4. **Dependency Cycle Detection**:
   - Post-revision validation via dependency-analyzer.sh
   - Automatic revert on circular dependency introduction

5. **Error Logging**:
   - All revision failures logged to errors.jsonl
   - Queryable via /errors command for debugging

---

## Test Plan (for Spec 048)

### Unit Tests

1. **Blocking Detection**:
   - Input: lean-implementer output with theorems_partial
   - Expected: Correct PARTIAL_COUNT and BLOCKING_DIAGNOSTICS extraction

2. **Context Budget Calculation**:
   - Input: Various context usage levels (0%, 50%, 85%, 95%)
   - Expected: Correct REVISION_VIABLE decisions

3. **Revision Depth Enforcement**:
   - Input: REVISION_DEPTH values (0, 1, 2, 3)
   - Expected: Correct TRIGGER_REVISION decisions

### Integration Tests

1. **End-to-End Revision Workflow**:
   - Setup: Plan with theorems requiring missing lemmas
   - Execution: lean-coordinator detects blockers, triggers /revise, recalculates waves
   - Expected: New infrastructure phase added, waves recalculated, blocked theorems succeed in next wave

2. **Context Exhaustion Handling**:
   - Setup: Coordinator at 85% context, encounters blockers
   - Execution: Revision deferred, checkpoint saved with revision_deferred flag
   - Expected: Workflow halts gracefully, next iteration can resume with revision

3. **Revision Depth Limit**:
   - Setup: Plan with persistent blockers (2+ revision attempts)
   - Execution: Coordinator hits MAX_REVISION_DEPTH=2
   - Expected: Revision skipped, error logged, manual intervention message displayed

4. **Dependency Cycle Introduction**:
   - Setup: /revise adds phase with circular dependency
   - Execution: Coordinator validates revised plan, detects cycle
   - Expected: Plan restored from backup, error logged, revision marked failed

### Performance Tests

1. **Context Overhead Measurement**:
   - Measure token usage: base + waves + revision
   - Expected: Total context < 50% for typical 4-wave plan with 1 revision

2. **Time Overhead Measurement**:
   - Measure wall-clock time: revision workflow (research + plan modification)
   - Expected: Revision adds 15-30 minutes to overall workflow

---

## Conclusion

Coordinator-triggered plan revision is architecturally feasible with the following key components:

1. **Blocking Detection**: Parse `theorems_partial` and `diagnostics` from lean-implementer output
2. **Context Budget**: Require ≥30,000 tokens (15% of window) for /revise workflow
3. **Revision Depth**: Track via workflow state, enforce MAX_REVISION_DEPTH=2
4. **Task Delegation**: Use bash conditional + imperative directive pattern (standards-compliant)
5. **Dependency Recalculation**: Leverage dependency-recalculation.sh utility (tier-agnostic)
6. **Error Handling**: Structured logging, backup restoration, cycle detection

**Recommendation**: Defer to separate spec (048) for test-driven development and isolated risk management. Phase 8 is an enhancement feature that can be developed independently after core wave orchestration (Phases 0-7) is validated.

---

## References

1. `/home/benjamin/.config/.claude/agents/lean-coordinator.md` - Wave execution architecture
2. `/home/benjamin/.config/.claude/agents/lean-implementer.md` - Output signal format (theorems_partial)
3. `/home/benjamin/.config/.claude/commands/revise.md` - Plan revision workflow (6 blocks)
4. `/home/benjamin/.config/.claude/lib/plan/dependency-recalculation.sh` - Wave recalculation utility (Phase 7)
5. `/home/benjamin/.config/.claude/lib/core/error-handling.sh` - Error logging patterns
6. `/home/benjamin/.config/.claude/lib/workflow/checkpoint-utils.sh` - Checkpoint save/load (schema v2.1)
7. `/home/benjamin/.config/.claude/specs/047_lean_implement_coordinator_waves/plans/001-lean-implement-coordinator-waves-plan.md` - Phase 8 requirements

---

**REPORT_CREATED**: /home/benjamin/.config/.claude/specs/047_lean_implement_coordinator_waves/reports/006-plan-revision-workflow.md
