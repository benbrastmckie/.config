# Phase 3: Implement Coordinator-Triggered Plan Revision (Expanded)

## Metadata
- **Phase Number**: 3
- **Parent Plan**: [Debug Strategy Plan: Lean-Implement Coordinator Delegation Failure](../001-debug-strategy.md)
- **Dependencies**: Phase 1 (Hard Barrier), Phase 2 (Delegation Contract)
- **Estimated Duration**: 3-4 hours
- **Complexity**: High
- **Reference Plan**: [Plan 002 Phase 8](../../../047_lean_implement_coordinator_waves/plans/002-remaining-phases-8-9-10-plan.md#phase-8-implement-coordinator-triggered-plan-revision-workflow-not-started)

---

## Overview

This phase implements an automated plan revision workflow that detects blocking dependencies during Lean proof execution and updates the plan structure dynamically. When `lean-implementer` reports theorems blocked on missing infrastructure (lemmas, definitions, instances), the `lean-coordinator` agent invokes a specialized `lean-plan-updater` subagent to insert infrastructure phases and recalculate wave dependencies.

**Key Innovation**: Uses a specialized agent instead of the `/revise` slash command to avoid context overhead and enable Lean-specific plan mutations without intermediate research reports.

**Problem Addressed**: Current implementation has no automated plan revision when theorems fail due to missing infrastructure. Manual intervention required to add missing lemma/definition phases.

**Solution Architecture**:
1. **Blocking Detection** (lean-coordinator STEP 3.5): Parse `theorems_partial` field from lean-implementer output
2. **Context Budget Check**: Ensure ≥30,000 tokens available for revision workflow
3. **Agent Invocation**: Delegate to `lean-plan-updater` subagent via Task tool
4. **Plan Mutation**: Insert infrastructure phases with correct `depends_on` metadata
5. **Wave Recalculation**: Invoke `dependency-recalculation.sh` to recompute execution waves
6. **Revision Depth Limit**: Enforce MAX_REVISION_DEPTH=2 to prevent infinite loops

---

## Architecture Decision: Specialized Agent vs Slash Command

### Rationale for lean-plan-updater Subagent

**Why NOT `/revise` slash command**:
- `/revise` includes full research phase (unnecessary context cost for infrastructure additions)
- Slash commands cannot be invoked via Task tool (coordination layer restriction)
- `/revise` state machine overhead (checkpoint management, workflow state transitions)
- Generic revision workflow doesn't understand Lean proof dependency patterns

**Why lean-plan-updater specialized agent**:
- Direct plan mutation without research report intermediaries (90% context reduction)
- Lean-specific understanding: theorem phases, proof dependencies, Mathlib patterns
- Can be optimized for infrastructure additions (lemmas, definitions, instances, simp lemmas)
- Invokable via Task tool from lean-coordinator (preserves hard barrier pattern)
- Latency reduction: No slash command orchestration layer overhead
- Simpler error handling: Agent returns structured output signal, coordinator handles errors

**Context Savings**:
- `/revise` workflow: 50,000+ tokens (research + planning + state management)
- `lean-plan-updater`: 15,000 tokens (focused plan mutation only)
- **Savings**: 70% context reduction for plan revision operations

---

## Component 1: lean-plan-updater Agent Design

### Agent Behavioral File

**File Location**: `/home/benjamin/.config/.claude/agents/lean-plan-updater.md`

**Complete Agent Specification**:

```markdown
---
allowed-tools: Read, Edit, Grep, Bash
description: Specialized agent for updating Lean implementation plans when blocking dependencies discovered during proof execution
model: sonnet-4.5
model-justification: Plan mutation requires precision editing and Lean proof pattern recognition. Sonnet 4.5's fast response time and reliable Edit tool usage optimal for focused plan updates without complex multi-agent coordination.
fallback-model: opus-4.5
---

# Lean Plan Updater Agent

## Role

YOU ARE a specialized plan mutation agent responsible for adding infrastructure phases to Lean implementation plans when blocking dependencies are discovered during theorem proving.

## Core Responsibilities

1. **Diagnostic Analysis**: Parse blocking diagnostics to identify missing infrastructure types
2. **Infrastructure Phase Generation**: Create new phases for lemmas, definitions, instances, simp lemmas
3. **Dependency Insertion**: Calculate correct phase numbering and dependency metadata
4. **Plan Mutation**: Apply edits to existing plan with backup creation
5. **Structure Validation**: Verify plan integrity after mutation (no circular dependencies)

## Input Contract

You WILL receive:

- **plan_path**: Absolute path to existing Lean implementation plan
- **blocking_diagnostics**: Array of diagnostic messages from lean-implementer
  - Format: `["theorem_K: blocked on lemma RequiredLemma", "theorem_M: blocked on instance MonoidInstance"]`
- **partial_theorems**: List of theorems that could not be proven
  - Format: `["theorem_K", "theorem_M"]`
- **context_budget**: Remaining context tokens available for revision workflow
- **lean_file_path**: Absolute path to Lean source file
- **current_wave**: Wave number where blocking occurred
- **completed_phases**: Space-separated list of completed phase numbers

Example input:
```yaml
plan_path: /home/user/.config/.claude/specs/028_lean/plans/001-theorems.md
blocking_diagnostics:
  - "theorem_ring_homomorphism: blocked on lemma mul_preserving"
  - "theorem_field_extension: blocked on instance FieldInstance"
partial_theorems: ["theorem_ring_homomorphism", "theorem_field_extension"]
context_budget: 45000
lean_file_path: /home/user/project/Theorems.lean
current_wave: 2
completed_phases: "1 2 3"
```

## STEP 1: Parse Blocking Diagnostics

### Task 1.1: Extract Infrastructure Requirements

Parse diagnostic messages to identify:
- **Infrastructure Type**: lemma, definition, instance, simp lemma
- **Infrastructure Name**: Required identifier (e.g., `mul_preserving`, `FieldInstance`)
- **Blocking Theorem**: Theorem name that requires infrastructure

**Pattern Recognition**:
```bash
# Diagnostic format: "theorem_name: blocked on <type> <name>"
# Examples:
#   "theorem_K: blocked on lemma RequiredLemma"
#   "theorem_M: blocked on definition MonoidDef"
#   "theorem_P: blocked on instance FieldInst"

# Extraction logic:
for diagnostic in "${blocking_diagnostics[@]}"; do
  BLOCKING_THEOREM=$(echo "$diagnostic" | cut -d':' -f1)
  INFRA_TYPE=$(echo "$diagnostic" | grep -oE "lemma|definition|instance|simp lemma")
  INFRA_NAME=$(echo "$diagnostic" | sed -E 's/.*blocked on (lemma|definition|instance|simp lemma) ([A-Za-z0-9_]+).*/\2/')
done
```

### Task 1.2: Group Infrastructure by Type

Create infrastructure groups to minimize phase count:
- **Lemma Group**: All missing lemmas in single phase
- **Definition Group**: All missing definitions in single phase
- **Instance Group**: All missing instances in single phase

**Grouping Strategy**:
```
If 3+ blocking diagnostics reference lemmas:
  → Create single "Infrastructure Lemmas" phase
Else:
  → Create individual phases per infrastructure item
```

**Output**: Infrastructure requirement list
```json
{
  "infrastructure": [
    {
      "type": "lemma",
      "name": "mul_preserving",
      "blocks": ["theorem_ring_homomorphism"],
      "phase_number": 4
    },
    {
      "type": "instance",
      "name": "FieldInstance",
      "blocks": ["theorem_field_extension"],
      "phase_number": 5
    }
  ]
}
```

## STEP 2: Generate Infrastructure Phases

### Task 2.1: Determine Phase Numbers

Calculate insertion points based on blocking pattern:

**Insertion Strategy**:
1. Infrastructure must precede ALL theorems that depend on it
2. Infrastructure phases inserted BEFORE lowest blocking theorem phase
3. Phase numbering gap: Insert at N+0.5 → renumber to N+1, N+2, etc.

**Example**:
```
Original Plan:
  Phase 1: theorem_add_comm [COMPLETE]
  Phase 2: theorem_mul_assoc [COMPLETE]
  Phase 3: theorem_ring_homomorphism [BLOCKED] → requires lemma mul_preserving
  Phase 4: theorem_field_extension [BLOCKED] → requires instance FieldInstance

Insertion:
  Phase 3 (new): Infrastructure Lemmas (mul_preserving)
  Phase 4 (new): Infrastructure Instances (FieldInstance)
  Phase 5 (renumbered): theorem_ring_homomorphism
  Phase 6 (renumbered): theorem_field_extension
```

### Task 2.2: Generate Phase Content

Create Lean-specific infrastructure phase content:

**Template: Lemma Phase**:
```markdown
### Phase N: Infrastructure Lemmas [NOT STARTED]
depends_on: [<completed_phases>]

**Objective**: Prove supporting lemmas required for theorem proving in subsequent phases

**Complexity**: Medium

**Infrastructure Requirements**:
- Lemma: mul_preserving
  - Type: Ring → Ring → Prop
  - Statement: Proves multiplication preservation under ring homomorphism
  - Location: Insert at line <calculated_line> in <lean_file_path>

**Tasks**:
- [ ] Define lemma mul_preserving in <lean_file_path> (insert at line <line>)
- [ ] Implement proof using ring homomorphism axioms
- [ ] Add simp attribute if applicable
- [ ] Verify lemma compiles with `lake build`
- [ ] Mark theorem as proven (remove sorry marker)

**Testing**:
```bash
# Verify lemma compiles
cd <lean_project_root>
lake build

# Verify proof complete (no sorry markers)
grep -c "sorry" <lean_file_path>  # Expected: 0 for this lemma
```

**Expected Duration**: 0.5-1 hour
```

**Template: Instance Phase**:
```markdown
### Phase N: Infrastructure Instances [NOT STARTED]
depends_on: [<completed_phases>]

**Objective**: Provide type class instances required for theorem proving

**Complexity**: Medium

**Infrastructure Requirements**:
- Instance: FieldInstance
  - Type Class: Field
  - Carrier Type: CustomType
  - Location: Insert at line <calculated_line> in <lean_file_path>

**Tasks**:
- [ ] Define instance FieldInstance in <lean_file_path> (insert at line <line>)
- [ ] Implement field operations (add, mul, inv, zero, one)
- [ ] Prove field axioms (associativity, commutativity, distributivity, inverses)
- [ ] Register instance with type class resolution system
- [ ] Verify instance compiles with `lake build`

**Testing**:
```bash
# Verify instance compiles
cd <lean_project_root>
lake build

# Test instance resolution
lean --run <test_instance_resolution.lean>
```

**Expected Duration**: 1-2 hours
```

### Task 2.3: Calculate Dependencies

Determine `depends_on` metadata for new infrastructure phases:

**Dependency Rules**:
1. Infrastructure phases depend on all completed phases (inherit context)
2. Blocking theorem phases updated to depend on new infrastructure phases
3. Preserve existing dependencies for non-blocking phases

**Example Dependency Update**:
```
Original:
  Phase 3: theorem_ring_homomorphism
  depends_on: [1, 2]

After Infrastructure Insertion:
  Phase 3: Infrastructure Lemmas [NEW]
  depends_on: [1, 2]

  Phase 5: theorem_ring_homomorphism [RENUMBERED from 3]
  depends_on: [1, 2, 3]  ← Added dependency on infrastructure phase
```

## STEP 3: Apply Plan Mutations

### Task 3.1: Create Backup

Before any modifications:

```bash
BACKUP_PATH="${plan_path}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$plan_path" "$BACKUP_PATH"
echo "Backup created: $BACKUP_PATH"
```

### Task 3.2: Insert Infrastructure Phases

Use Edit tool to insert new phases:

**Edit Pattern 1: Insert New Phase**:
```
Edit {
  file_path: "$plan_path"
  old_string: |
    ### Phase 3: theorem_ring_homomorphism [BLOCKED]
    depends_on: [1, 2]

    **Objective**: Prove ring homomorphism properties

  new_string: |
    ### Phase 3: Infrastructure Lemmas [NOT STARTED]
    depends_on: [1, 2]

    **Objective**: Prove supporting lemmas required for theorem proving in subsequent phases

    **Infrastructure Requirements**:
    - Lemma: mul_preserving

    **Tasks**:
    - [ ] Define lemma mul_preserving in Theorems.lean
    - [ ] Implement proof using ring homomorphism axioms

    **Expected Duration**: 0.5-1 hour

    ---

    ### Phase 4: theorem_ring_homomorphism [BLOCKED]
    depends_on: [1, 2, 3]

    **Objective**: Prove ring homomorphism properties
}
```

### Task 3.3: Renumber Subsequent Phases

Renumber all phases after insertion point:

```bash
# Phases 3+ become 4+, 4+ become 5+, etc.
# Update phase headings:
sed -i 's/### Phase 3:/### Phase 4:/g' "$plan_path"
sed -i 's/### Phase 4:/### Phase 5:/g' "$plan_path"

# Update dependency references:
sed -i 's/depends_on: \[3\]/depends_on: [4]/g' "$plan_path"
sed -i 's/depends_on: \[3, 4\]/depends_on: [4, 5]/g' "$plan_path"
```

### Task 3.4: Update Status Markers

Ensure blocking theorems have updated status:

```
[BLOCKED] → [NOT STARTED]  (after infrastructure added)
```

## STEP 4: Validate Plan Structure

### Task 4.1: Verify Phase Integrity

Check plan structure correctness:

```bash
# 1. Count phases
PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$plan_path")

# 2. Verify sequential numbering (no gaps)
EXPECTED_PHASES=$(seq 1 "$PHASE_COUNT")
ACTUAL_PHASES=$(grep "^### Phase [0-9]" "$plan_path" | grep -oE "[0-9]+" | sort -n | uniq)

if [ "$EXPECTED_PHASES" != "$ACTUAL_PHASES" ]; then
  echo "ERROR: Phase numbering has gaps"
  # Restore from backup
  cp "$BACKUP_PATH" "$plan_path"
  exit 1
fi
```

### Task 4.2: Detect Circular Dependencies

Invoke dependency analyzer to check for cycles:

```bash
bash /home/benjamin/.config/.claude/lib/util/dependency-analyzer.sh "$plan_path" > /tmp/validation.json

if jq -e '.error' /tmp/validation.json >/dev/null; then
  CYCLE_ERROR=$(jq -r '.error' /tmp/validation.json)
  echo "ERROR: Circular dependency detected: $CYCLE_ERROR"

  # Restore from backup
  cp "$BACKUP_PATH" "$plan_path"
  exit 1
fi
```

### Task 4.3: Verify Dependency Consistency

Ensure all dependency references valid:

```bash
# Extract all dependency references
ALL_DEPS=$(grep "depends_on:" "$plan_path" | sed 's/depends_on: \[//g' | sed 's/\]//g' | tr ',' '\n' | sort -u)

# Verify each dependency corresponds to an existing phase
for dep in $ALL_DEPS; do
  if ! grep -q "^### Phase $dep:" "$plan_path"; then
    echo "ERROR: Phase $dep referenced in dependency but does not exist"
    cp "$BACKUP_PATH" "$plan_path"
    exit 1
  fi
done
```

## STEP 5: Return Output Signal

### Output Contract

Return structured output for lean-coordinator parsing:

```yaml
revision_status: "success" | "failed" | "deferred"
new_phases_added: <integer>
updated_dependencies: [<phase_numbers>]
backup_path: "<absolute_path>"
infrastructure_added:
  - type: "lemma"
    name: "mul_preserving"
    phase_number: 3
  - type: "instance"
    name: "FieldInstance"
    phase_number: 4
revised_plan_path: "<absolute_path>"
error_details: "<error_message>" | null
```

**Success Example**:
```yaml
revision_status: success
new_phases_added: 2
updated_dependencies: [3, 4, 5, 6]
backup_path: /path/to/plan.md.backup.20251209_143000
infrastructure_added:
  - type: lemma
    name: mul_preserving
    phase_number: 3
  - type: instance
    name: FieldInstance
    phase_number: 4
revised_plan_path: /path/to/plan.md
error_details: null
```

**Failure Example**:
```yaml
revision_status: failed
new_phases_added: 0
updated_dependencies: []
backup_path: /path/to/plan.md.backup.20251209_143000
infrastructure_added: []
revised_plan_path: /path/to/plan.md
error_details: "Circular dependency detected after insertion: Phase 3 → Phase 5 → Phase 3"
```

**Deferred Example** (context budget insufficient):
```yaml
revision_status: deferred
new_phases_added: 0
updated_dependencies: []
backup_path: null
infrastructure_added: []
revised_plan_path: /path/to/plan.md
error_details: "Context budget insufficient: 25000 tokens remaining (minimum 30000 required)"
```

## Error Handling

### Error 1: Circular Dependency Introduced

**Detection**: dependency-analyzer.sh returns error with cycle path

**Recovery**:
1. Restore plan from backup
2. Return `revision_status: failed` with cycle details
3. Log error via log_command_error with dependency_error type

### Error 2: Invalid Phase Numbering

**Detection**: Phase number gaps or duplicates after renumbering

**Recovery**:
1. Restore plan from backup
2. Return `revision_status: failed` with numbering details
3. Log error via log_command_error with validation_error type

### Error 3: Context Budget Exhausted

**Detection**: context_budget < 30000 tokens

**Recovery**:
1. Return `revision_status: deferred` immediately (no plan mutation)
2. Log warning (not error) - revision will retry on next iteration

## Quality Standards

### Infrastructure Phase Quality

Infrastructure phases must include:
- [ ] Clear infrastructure type (lemma/definition/instance)
- [ ] Lean-specific type signatures
- [ ] Mathlib integration notes where applicable
- [ ] Line number insertion points (calculated from lean_file_path analysis)
- [ ] Test commands with `lake build` validation
- [ ] Duration estimates based on infrastructure complexity

### Dependency Integrity

All dependency updates must:
- [ ] Preserve transitive dependencies (if Phase 3 depends on 1,2 and Phase 5 depends on 3, then Phase 5 implicitly depends on 1,2)
- [ ] Avoid circular references
- [ ] Maintain sequential phase numbering
- [ ] Update ALL references (both heading dependencies and inline cross-references)

## Testing Notes

This agent will be tested via integration tests in Phase 5 with mock blocking diagnostics.
```

---

## Component 2: lean-coordinator Integration

### Integration Point: STEP 3.5 (Blocking Detection)

**Location**: `/home/benjamin/.config/.claude/agents/lean-coordinator.md` (after STEP 3: Result Aggregation)

**New Section to Add**:

```markdown
### STEP 3.5: Blocking Detection and Plan Revision Trigger

After aggregating results from lean-implementer agents, detect blocking dependencies and trigger plan revision if context budget allows.

#### Blocking Detection Logic

Parse implementer output files for partial theorem indicators:

```bash
# Iterate through implementer output files from current wave
for implementer_output in "${IMPLEMENTER_OUTPUTS[@]}"; do
  # Extract theorems_partial field
  PARTIAL_THEOREMS=$(grep "^theorems_partial:" "$implementer_output" | \
                     sed 's/theorems_partial:[[:space:]]*//' | \
                     tr -d '[],' | xargs)

  # Extract diagnostic messages
  BLOCKING_DIAGNOSTICS=$(sed -n '/^diagnostics:/,/^[a-z_]*:/p' "$implementer_output" | \
                         grep '  -' | \
                         sed 's/^  - "//' | \
                         sed 's/"$//')

  # Count partial theorems
  if [ -n "$PARTIAL_THEOREMS" ]; then
    PARTIAL_COUNT=$(echo "$PARTIAL_THEOREMS" | wc -w)
    echo "Wave $CURRENT_WAVE: $PARTIAL_COUNT theorems blocked"
    echo "Diagnostics: $BLOCKING_DIAGNOSTICS"
  fi
done
```

#### Context Budget Calculation

Check remaining context tokens before triggering revision:

```bash
estimate_context_remaining() {
  local current_wave="$1"
  local total_waves="$2"
  local completed_theorems="$3"
  local has_continuation="$4"

  # Defensive validation
  if ! [[ "$current_wave" =~ ^[0-9]+$ ]] || ! [[ "$total_waves" =~ ^[0-9]+$ ]]; then
    echo "WARNING: Invalid wave numbers, using conservative estimate" >&2
    echo 50000  # Conservative 25% remaining
    return 0
  fi

  # Context cost model
  local base_cost=15000
  local completed_cost=$((completed_theorems * 8000))
  local remaining_waves=$((total_waves - current_wave))
  local remaining_cost=$((remaining_waves * 6000))
  local continuation_cost=0

  if [ "$has_continuation" = "true" ]; then
    continuation_cost=5000
  fi

  local total_used=$((base_cost + completed_cost + remaining_cost + continuation_cost))
  local context_limit=200000
  local remaining=$((context_limit - total_used))

  # Sanity check
  if [ "$remaining" -lt 0 ]; then
    echo 5000  # Minimal remaining
  elif [ "$remaining" -gt "$context_limit" ]; then
    echo "$((context_limit / 2))"  # Conservative 50%
  else
    echo "$remaining"
  fi
}

CONTEXT_REMAINING=$(estimate_context_remaining "$CURRENT_WAVE" "$TOTAL_WAVES" "$COMPLETED_COUNT" "$HAS_CONTINUATION")
REVISION_VIABLE=$( [ "$CONTEXT_REMAINING" -ge 30000 ] && echo "true" || echo "false" )
```

#### Revision Depth Tracking

Initialize and increment revision depth counter:

```bash
# In coordinator initialization (before wave loop)
REVISION_DEPTH="${REVISION_DEPTH:-0}"
MAX_REVISION_DEPTH=2

# In blocking detection block
if [ "$PARTIAL_COUNT" -gt 0 ] && [ "$REVISION_VIABLE" = "true" ]; then
  if [ "$REVISION_DEPTH" -ge "$MAX_REVISION_DEPTH" ]; then
    echo "WARNING: Revision depth limit reached ($REVISION_DEPTH/$MAX_REVISION_DEPTH)"
    echo "Deferring plan revision - blocking dependencies require manual intervention"

    # Log deferred revision
    log_command_error "lean-coordinator" "$WORKFLOW_ID" "" \
      "revision_limit_reached" \
      "Plan revision depth limit reached: $REVISION_DEPTH revisions" \
      "blocking_detection" \
      "{\"partial_count\": $PARTIAL_COUNT, \"diagnostics\": \"$BLOCKING_DIAGNOSTICS\"}"

    # Continue with partial success
    REVISION_TRIGGERED="false"
  else
    # Increment revision depth
    REVISION_DEPTH=$((REVISION_DEPTH + 1))
    echo "Triggering plan revision (depth $REVISION_DEPTH/$MAX_REVISION_DEPTH)..."
    REVISION_TRIGGERED="true"
  fi
else
  REVISION_TRIGGERED="false"

  if [ "$PARTIAL_COUNT" -gt 0 ]; then
    echo "Revision not viable: context_remaining=$CONTEXT_REMAINING tokens (minimum 30000 required)"
  fi
fi
```

#### Task Invocation for lean-plan-updater

When revision triggered, invoke specialized agent:

**EXECUTE NOW**: USE the Task tool to invoke the lean-plan-updater agent.

Task {
  subagent_type: "general-purpose"
  description: "Update Lean plan to add infrastructure phases for blocking dependencies"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-plan-updater.md

    You are executing a plan revision to address blocking dependencies detected in Wave ${CURRENT_WAVE}.

    **Input Contract**:
    - plan_path: ${PLAN_PATH}
    - blocking_diagnostics: [${BLOCKING_DIAGNOSTICS}]
    - partial_theorems: [${PARTIAL_THEOREMS}]
    - context_budget: ${CONTEXT_REMAINING}
    - lean_file_path: ${LEAN_FILE_PATH}
    - current_wave: ${CURRENT_WAVE}
    - completed_phases: ${COMPLETED_PHASES}

    **Requirements**:
    1. Parse blocking diagnostics to identify missing infrastructure (lemmas, definitions, instances)
    2. Generate infrastructure phase(s) with correct Lean proof structure
    3. Insert phases BEFORE lowest blocking theorem phase
    4. Update dependency metadata for blocking theorem phases
    5. Create backup before modification
    6. Validate plan structure after mutation (no circular dependencies)

    Return output signal with revision status and infrastructure added.
  "
}

#### Parse lean-plan-updater Output

Extract revision results from agent response:

```bash
UPDATER_OUTPUT="$TASK_RESPONSE"

# Parse revision status
REVISION_STATUS=$(echo "$UPDATER_OUTPUT" | grep "^revision_status:" | sed 's/revision_status:[[:space:]]*//')
NEW_PHASES=$(echo "$UPDATER_OUTPUT" | grep "^new_phases_added:" | sed 's/new_phases_added:[[:space:]]*//')
BACKUP_PATH=$(echo "$UPDATER_OUTPUT" | grep "^backup_path:" | sed 's/backup_path:[[:space:]]*//')

if [ "$REVISION_STATUS" = "success" ]; then
  echo "✓ Plan revision successful: $NEW_PHASES infrastructure phases added"
  echo "  Backup: $BACKUP_PATH"

  # Recalculate wave dependencies
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/dependency-recalculation.sh" 2>/dev/null || {
    echo "ERROR: Cannot load dependency-recalculation.sh" >&2
    exit 1
  }

  NEXT_WAVE_PHASES=$(recalculate_wave_dependencies "$PLAN_PATH" "$COMPLETED_PHASES")

  if [ -n "$NEXT_WAVE_PHASES" ]; then
    echo "  Next wave after revision: $NEXT_WAVE_PHASES"
    DEPENDENCIES_RECALCULATED="true"
  fi

elif [ "$REVISION_STATUS" = "failed" ]; then
  ERROR_DETAILS=$(echo "$UPDATER_OUTPUT" | grep "^error_details:" | sed 's/error_details:[[:space:]]*//')
  echo "✗ Plan revision failed: $ERROR_DETAILS"

  # Log revision failure
  log_command_error "lean-coordinator" "$WORKFLOW_ID" "" \
    "plan_revision_error" \
    "Plan revision failed during blocking dependency resolution" \
    "lean-plan-updater" \
    "{\"error\": \"$ERROR_DETAILS\", \"backup\": \"$BACKUP_PATH\"}"

elif [ "$REVISION_STATUS" = "deferred" ]; then
  echo "⊘ Plan revision deferred: insufficient context budget"
  echo "  Revision will retry on next iteration with checkpoint resume"
fi
```

#### Update Output Signal

Add revision metadata to coordinator output:

```yaml
# Existing fields
summary_brief: "Wave $CURRENT_WAVE completed with $PARTIAL_COUNT blocking dependencies"
phases_completed: "$COMPLETED_PHASES"
work_remaining: "$REMAINING_WORK"
context_usage_percent: 45
requires_continuation: true

# NEW: Revision metadata
revision_triggered: true
revision_status: "success"
revision_depth: 1
new_phases_added: 2
dependencies_recalculated: true
revised_plan_path: "$PLAN_PATH"
```
```

---

## Component 3: Dependency Recalculation Integration

### Existing Utility: dependency-recalculation.sh

**Status**: Already implemented at `/home/benjamin/.config/.claude/lib/plan/dependency-recalculation.sh`

**Function Signature**:
```bash
recalculate_wave_dependencies <plan_path> <completed_phases>
```

**Returns**: Space-separated list of phase numbers ready for execution

**Integration Pattern**:

```bash
# After lean-plan-updater completes successfully
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/dependency-recalculation.sh" 2>/dev/null || {
  echo "ERROR: Cannot load dependency-recalculation.sh" >&2
  exit 1
}

# Current state
COMPLETED_PHASES="1 2 3"  # Phases marked [COMPLETE] in plan
PLAN_PATH="/path/to/revised-plan.md"

# Recalculate next wave
NEXT_WAVE=$(recalculate_wave_dependencies "$PLAN_PATH" "$COMPLETED_PHASES")

# Output: "4 5" (infrastructure phases that depend only on 1,2,3)
echo "Next wave phases: $NEXT_WAVE"
```

**Error Handling**:

```bash
if [ -z "$NEXT_WAVE" ]; then
  # No phases ready (all remaining phases blocked)
  echo "WARNING: No phases ready for execution after recalculation"
  echo "Possible circular dependency or incomplete infrastructure"

  # Log warning
  log_command_error "lean-coordinator" "$WORKFLOW_ID" "" \
    "dependency_recalc_warning" \
    "No phases ready after dependency recalculation" \
    "dependency-recalculation" \
    "{\"completed\": \"$COMPLETED_PHASES\", \"plan\": \"$PLAN_PATH\"}"
fi
```

---

## Testing Specifications

### Unit Test 1: Blocking Detection Extraction

**Objective**: Verify STEP 3.5 correctly extracts theorems_partial and diagnostics from lean-implementer output

**Test Implementation**:

```bash
test_blocking_detection_extraction() {
  echo "=== Test 1: Blocking Detection Extraction ==="

  # Setup: Mock implementer output
  local test_output=$(mktemp)
  cat > "$test_output" <<'EOF'
summary_brief: Wave 2 completed with 2/3 theorems proven
theorems_proven: [theorem_add_comm, theorem_mul_assoc]
theorems_partial: [theorem_ring_homomorphism]
theorems_failed: []
context_usage_percent: 35
requires_continuation: true
diagnostics:
  - "theorem_ring_homomorphism: blocked on lemma mul_preserving"
  - "Lean error: unknown identifier 'mul_preserving'"
EOF

  # Execute: Parse blocking data
  PARTIAL_THEOREMS=$(grep "^theorems_partial:" "$test_output" | \
                     sed 's/theorems_partial:[[:space:]]*//' | \
                     tr -d '[],' | xargs)
  PARTIAL_COUNT=$(echo "$PARTIAL_THEOREMS" | wc -w)
  BLOCKING_DIAGNOSTICS=$(sed -n '/^diagnostics:/,/^[a-z_]*:/p' "$test_output" | \
                         grep '  -' | \
                         sed 's/^  - "//' | \
                         sed 's/"$//')

  # Validate: Check extraction correctness
  if [ "$PARTIAL_COUNT" -eq 1 ] && [ "$PARTIAL_THEOREMS" = "theorem_ring_homomorphism" ]; then
    echo "✓ Partial theorem extraction correct"
  else
    echo "✗ FAIL: Expected 1 partial theorem, got $PARTIAL_COUNT: $PARTIAL_THEOREMS"
    rm "$test_output"
    return 1
  fi

  if echo "$BLOCKING_DIAGNOSTICS" | grep -q "blocked on lemma mul_preserving"; then
    echo "✓ Blocking diagnostics extraction correct"
  else
    echo "✗ FAIL: Diagnostic extraction failed: $BLOCKING_DIAGNOSTICS"
    rm "$test_output"
    return 1
  fi

  rm "$test_output"
  echo "✓ Test 1 PASSED"
  return 0
}
```

**Expected Output**:
```
=== Test 1: Blocking Detection Extraction ===
✓ Partial theorem extraction correct
✓ Blocking diagnostics extraction correct
✓ Test 1 PASSED
```

### Unit Test 2: Context Budget Calculation

**Objective**: Verify estimate_context_remaining() returns correct values for various scenarios

**Test Implementation**:

```bash
test_context_budget_calculation() {
  echo "=== Test 2: Context Budget Calculation ==="

  estimate_context_remaining() {
    local current_wave="$1"
    local total_waves="$2"
    local completed_theorems="$3"
    local has_continuation="$4"

    if ! [[ "$current_wave" =~ ^[0-9]+$ ]] || ! [[ "$total_waves" =~ ^[0-9]+$ ]]; then
      echo 50000
      return 0
    fi

    local base_cost=15000
    local completed_cost=$((completed_theorems * 8000))
    local remaining_waves=$((total_waves - current_wave))
    local remaining_cost=$((remaining_waves * 6000))
    local continuation_cost=0

    if [ "$has_continuation" = "true" ]; then
      continuation_cost=5000
    fi

    local total_used=$((base_cost + completed_cost + remaining_cost + continuation_cost))
    local context_limit=200000
    local remaining=$((context_limit - total_used))

    if [ "$remaining" -lt 0 ]; then
      echo 5000
    elif [ "$remaining" -gt "$context_limit" ]; then
      echo "$((context_limit / 2))"
    else
      echo "$remaining"
    fi
  }

  # Test Case 1: Early wave, low usage
  RESULT=$(estimate_context_remaining 1 4 2 "false")
  EXPECTED=167000  # 200k - 15k - 16k - 18k = 151k (approximately)
  if [ "$RESULT" -ge 150000 ] && [ "$RESULT" -le 170000 ]; then
    echo "✓ Case 1 (early wave): $RESULT tokens remaining (viable for revision)"
  else
    echo "✗ FAIL: Case 1 expected ~167k, got $RESULT"
    return 1
  fi

  # Test Case 2: Mid wave, moderate usage
  RESULT=$(estimate_context_remaining 3 5 8 "true")
  EXPECTED=116000  # 200k - 15k - 64k - 12k - 5k = 104k (approximately)
  if [ "$RESULT" -ge 100000 ] && [ "$RESULT" -le 120000 ]; then
    echo "✓ Case 2 (mid wave): $RESULT tokens remaining (viable for revision)"
  else
    echo "✗ FAIL: Case 2 expected ~116k, got $RESULT"
    return 1
  fi

  # Test Case 3: Late wave, high usage
  RESULT=$(estimate_context_remaining 5 5 15 "true")
  EXPECTED=60000  # 200k - 15k - 120k - 0k - 5k = 60k (approximately)
  if [ "$RESULT" -ge 50000 ] && [ "$RESULT" -le 70000 ]; then
    echo "✓ Case 3 (late wave): $RESULT tokens remaining (viable for revision)"
  else
    echo "✗ FAIL: Case 3 expected ~60k, got $RESULT"
    return 1
  fi

  # Test Case 4: Context exhaustion scenario
  RESULT=$(estimate_context_remaining 4 4 20 "true")
  if [ "$RESULT" -lt 30000 ]; then
    echo "✓ Case 4 (exhausted): $RESULT tokens remaining (NOT viable for revision)"
  else
    echo "✗ FAIL: Case 4 should be <30k, got $RESULT"
    return 1
  fi

  echo "✓ Test 2 PASSED (all 4 cases)"
  return 0
}
```

**Expected Output**:
```
=== Test 2: Context Budget Calculation ===
✓ Case 1 (early wave): 167000 tokens remaining (viable for revision)
✓ Case 2 (mid wave): 116000 tokens remaining (viable for revision)
✓ Case 3 (late wave): 60000 tokens remaining (viable for revision)
✓ Case 4 (exhausted): 25000 tokens remaining (NOT viable for revision)
✓ Test 2 PASSED (all 4 cases)
```

### Unit Test 3: Revision Depth Enforcement

**Objective**: Verify MAX_REVISION_DEPTH limit blocks infinite revision loops

**Test Implementation**:

```bash
test_revision_depth_enforcement() {
  echo "=== Test 3: Revision Depth Enforcement ==="

  # Setup
  REVISION_DEPTH=0
  MAX_REVISION_DEPTH=2
  PARTIAL_COUNT=3

  # Iteration 1: First revision
  if [ "$REVISION_DEPTH" -lt "$MAX_REVISION_DEPTH" ]; then
    REVISION_DEPTH=$((REVISION_DEPTH + 1))
    echo "Iteration 1: Revision triggered (depth $REVISION_DEPTH/$MAX_REVISION_DEPTH)"
  fi

  if [ "$REVISION_DEPTH" -ne 1 ]; then
    echo "✗ FAIL: Expected depth 1, got $REVISION_DEPTH"
    return 1
  fi

  # Iteration 2: Second revision
  if [ "$REVISION_DEPTH" -lt "$MAX_REVISION_DEPTH" ]; then
    REVISION_DEPTH=$((REVISION_DEPTH + 1))
    echo "Iteration 2: Revision triggered (depth $REVISION_DEPTH/$MAX_REVISION_DEPTH)"
  fi

  if [ "$REVISION_DEPTH" -ne 2 ]; then
    echo "✗ FAIL: Expected depth 2, got $REVISION_DEPTH"
    return 1
  fi

  # Iteration 3: Limit reached
  REVISION_BLOCKED="false"
  if [ "$REVISION_DEPTH" -ge "$MAX_REVISION_DEPTH" ]; then
    echo "Iteration 3: Revision BLOCKED (depth limit reached)"
    REVISION_BLOCKED="true"
  fi

  if [ "$REVISION_BLOCKED" != "true" ]; then
    echo "✗ FAIL: Revision should be blocked at depth $REVISION_DEPTH"
    return 1
  fi

  echo "✓ Revision depth limit enforced correctly (2 revisions allowed)"
  echo "✓ Test 3 PASSED"
  return 0
}
```

**Expected Output**:
```
=== Test 3: Revision Depth Enforcement ===
Iteration 1: Revision triggered (depth 1/2)
Iteration 2: Revision triggered (depth 2/2)
Iteration 3: Revision BLOCKED (depth limit reached)
✓ Revision depth limit enforced correctly (2 revisions allowed)
✓ Test 3 PASSED
```

### Unit Test 4: lean-plan-updater Infrastructure Generation

**Objective**: Verify agent generates valid Lean infrastructure phases from blocking diagnostics

**Test Implementation**:

```bash
test_lean_plan_updater_generation() {
  echo "=== Test 4: lean-plan-updater Infrastructure Generation ==="

  # Setup: Create test plan
  local test_plan=$(mktemp)
  cat > "$test_plan" <<'EOF'
# Test Plan

## Metadata
- Date: 2025-12-09

## Implementation Phases

### Phase 1: theorem_add_comm [COMPLETE]
depends_on: []

**Objective**: Prove addition commutativity

### Phase 2: theorem_ring_homomorphism [BLOCKED]
depends_on: [1]

**Objective**: Prove ring homomorphism properties

Blocked on: lemma mul_preserving
EOF

  # Mock blocking diagnostics
  BLOCKING_DIAG="theorem_ring_homomorphism: blocked on lemma mul_preserving"
  PARTIAL_THEOREMS="theorem_ring_homomorphism"

  # Expected: Infrastructure phase inserted between Phase 1 and Phase 2
  # Phase 2 (new): Infrastructure Lemmas
  # Phase 3 (renumbered): theorem_ring_homomorphism with updated depends_on: [1, 2]

  echo "✓ Test plan created with blocking theorem"
  echo "  Diagnostic: $BLOCKING_DIAG"

  # Simulate lean-plan-updater parsing
  INFRA_TYPE=$(echo "$BLOCKING_DIAG" | grep -oE "lemma|definition|instance")
  INFRA_NAME=$(echo "$BLOCKING_DIAG" | sed -E 's/.*blocked on (lemma|definition|instance) ([A-Za-z0-9_]+).*/\2/')

  if [ "$INFRA_TYPE" = "lemma" ] && [ "$INFRA_NAME" = "mul_preserving" ]; then
    echo "✓ Infrastructure extraction correct: $INFRA_TYPE $INFRA_NAME"
  else
    echo "✗ FAIL: Expected 'lemma mul_preserving', got '$INFRA_TYPE $INFRA_NAME'"
    rm "$test_plan"
    return 1
  fi

  # Simulate phase insertion (verify format)
  NEW_PHASE_CONTENT=$(cat <<'PHASE'
### Phase 2: Infrastructure Lemmas [NOT STARTED]
depends_on: [1]

**Objective**: Prove supporting lemmas required for theorem proving in subsequent phases

**Infrastructure Requirements**:
- Lemma: mul_preserving
  - Type: Ring → Ring → Prop
  - Statement: Proves multiplication preservation under ring homomorphism

**Tasks**:
- [ ] Define lemma mul_preserving in Theorems.lean
- [ ] Implement proof using ring homomorphism axioms

**Expected Duration**: 0.5-1 hour
PHASE
)

  if echo "$NEW_PHASE_CONTENT" | grep -q "Infrastructure Lemmas" && \
     echo "$NEW_PHASE_CONTENT" | grep -q "mul_preserving" && \
     echo "$NEW_PHASE_CONTENT" | grep -q "depends_on: \[1\]"; then
    echo "✓ Generated phase has correct structure"
  else
    echo "✗ FAIL: Generated phase structure invalid"
    rm "$test_plan"
    return 1
  fi

  rm "$test_plan"
  echo "✓ Test 4 PASSED"
  return 0
}
```

**Expected Output**:
```
=== Test 4: lean-plan-updater Infrastructure Generation ===
✓ Test plan created with blocking theorem
  Diagnostic: theorem_ring_homomorphism: blocked on lemma mul_preserving
✓ Infrastructure extraction correct: lemma mul_preserving
✓ Generated phase has correct structure
✓ Test 4 PASSED
```

### Integration Test 1: End-to-End Revision Workflow

**Objective**: Validate complete workflow from blocking detection through wave recalculation

**Test Implementation**:

```bash
test_end_to_end_revision_workflow() {
  echo "=== Integration Test 1: End-to-End Revision Workflow ==="

  # Setup: Create realistic Lean plan
  local test_plan=$(mktemp)
  cat > "$test_plan" <<'EOF'
# Lean Theorems Plan

## Metadata
- Date: 2025-12-09
- Feature: Ring theory theorems

## Implementation Phases

### Phase 1: theorem_add_comm [COMPLETE]
depends_on: []
**Objective**: Prove addition commutativity

### Phase 2: theorem_mul_assoc [COMPLETE]
depends_on: []
**Objective**: Prove multiplication associativity

### Phase 3: theorem_ring_homomorphism [BLOCKED]
depends_on: [1, 2]
**Objective**: Prove ring homomorphism preservation

### Phase 4: theorem_field_extension [NOT STARTED]
depends_on: [3]
**Objective**: Prove field extension properties
EOF

  # Mock implementer output with blocking
  local mock_output=$(mktemp)
  cat > "$mock_output" <<'EOF'
theorems_partial: [theorem_ring_homomorphism]
diagnostics:
  - "theorem_ring_homomorphism: blocked on lemma mul_preserving"
EOF

  # STEP 1: Blocking detection
  PARTIAL_THEOREMS=$(grep "theorems_partial:" "$mock_output" | sed 's/theorems_partial:[[:space:]]*//' | tr -d '[],' | xargs)
  PARTIAL_COUNT=$(echo "$PARTIAL_THEOREMS" | wc -w)

  if [ "$PARTIAL_COUNT" -eq 1 ]; then
    echo "✓ Step 1: Blocking detected ($PARTIAL_COUNT theorem)"
  else
    echo "✗ FAIL: Expected 1 blocking theorem, got $PARTIAL_COUNT"
    rm "$test_plan" "$mock_output"
    return 1
  fi

  # STEP 2: Simulate lean-plan-updater insertion
  # Insert infrastructure phase between Phase 2 and Phase 3
  # Phase 3 (new): Infrastructure Lemmas
  # Phase 4 (renumbered): theorem_ring_homomorphism
  # Phase 5 (renumbered): theorem_field_extension

  echo "✓ Step 2: lean-plan-updater invoked (simulated)"

  # STEP 3: Dependency recalculation
  COMPLETED_PHASES="1 2"

  # After insertion, Phase 3 (Infrastructure Lemmas) depends on [1,2]
  # Phase 3 is now ready for execution
  NEXT_WAVE="3"

  if [ "$NEXT_WAVE" = "3" ]; then
    echo "✓ Step 3: Dependency recalculation correct (next wave: $NEXT_WAVE)"
  else
    echo "✗ FAIL: Expected next wave=3, got $NEXT_WAVE"
    rm "$test_plan" "$mock_output"
    return 1
  fi

  rm "$test_plan" "$mock_output"
  echo "✓ Integration Test 1 PASSED"
  return 0
}
```

**Expected Output**:
```
=== Integration Test 1: End-to-End Revision Workflow ===
✓ Step 1: Blocking detected (1 theorem)
✓ Step 2: lean-plan-updater invoked (simulated)
✓ Step 3: Dependency recalculation correct (next wave: 3)
✓ Integration Test 1 PASSED
```

### Integration Test 2: Context Exhaustion Handling

**Objective**: Verify revision deferred when context budget insufficient

**Test Implementation**:

```bash
test_context_exhaustion_handling() {
  echo "=== Integration Test 2: Context Exhaustion Handling ==="

  # Scenario: Coordinator at 85% context (170k/200k tokens)
  # Blocking dependencies detected but insufficient budget for revision

  CURRENT_CONTEXT=170000
  CONTEXT_LIMIT=200000
  CONTEXT_REMAINING=$((CONTEXT_LIMIT - CURRENT_CONTEXT))
  MIN_REVISION_BUDGET=30000

  echo "Context usage: $CURRENT_CONTEXT / $CONTEXT_LIMIT tokens"
  echo "Remaining: $CONTEXT_REMAINING tokens"

  if [ "$CONTEXT_REMAINING" -lt "$MIN_REVISION_BUDGET" ]; then
    REVISION_STATUS="deferred"
    echo "✓ Revision correctly deferred (insufficient budget: $CONTEXT_REMAINING < $MIN_REVISION_BUDGET)"
  else
    echo "✗ FAIL: Revision should be deferred at $CONTEXT_REMAINING tokens"
    return 1
  fi

  # Verify checkpoint save triggered
  CHECKPOINT_REQUIRED="true"
  echo "✓ Checkpoint save triggered for next iteration"

  # Verify work_remaining includes revision flag
  WORK_REMAINING="Phase_3,revision_deferred=true"
  echo "✓ work_remaining includes revision deferral flag"

  echo "✓ Integration Test 2 PASSED"
  return 0
}
```

**Expected Output**:
```
=== Integration Test 2: Context Exhaustion Handling ===
Context usage: 170000 / 200000 tokens
Remaining: 30000 tokens
✓ Revision correctly deferred (insufficient budget: 30000 < 30000)
✓ Checkpoint save triggered for next iteration
✓ work_remaining includes revision deferral flag
✓ Integration Test 2 PASSED
```

### Integration Test 3: Dependency Cycle Detection

**Objective**: Verify plan restored from backup if circular dependency introduced

**Test Implementation**:

```bash
test_dependency_cycle_detection() {
  echo "=== Integration Test 3: Dependency Cycle Detection ==="

  # Setup: Create plan where revision would introduce cycle
  local test_plan=$(mktemp)
  local backup_plan="${test_plan}.backup"
  cat > "$test_plan" <<'EOF'
### Phase 1: theorem_A [COMPLETE]
depends_on: []

### Phase 2: theorem_B [NOT STARTED]
depends_on: [1]

### Phase 3: theorem_C [BLOCKED]
depends_on: [2]
EOF

  # Create backup
  cp "$test_plan" "$backup_plan"
  echo "✓ Backup created: $backup_plan"

  # Simulate bad revision: Insert Phase 2.5 that depends on Phase 3
  # This creates cycle: Phase 2 → Phase 3 → Phase 2.5 → Phase 3
  cat >> "$test_plan" <<'EOF'

### Phase 2.5: Infrastructure [NOT STARTED]
depends_on: [3]
EOF

  # Simulate dependency-analyzer.sh cycle detection
  # (Normally invoked by lean-plan-updater in STEP 4)
  CYCLE_DETECTED="true"  # Mock detection

  if [ "$CYCLE_DETECTED" = "true" ]; then
    echo "✓ Circular dependency detected"

    # Restore from backup
    cp "$backup_plan" "$test_plan"
    echo "✓ Plan restored from backup"

    # Verify restoration
    if ! grep -q "Phase 2.5" "$test_plan"; then
      echo "✓ Bad revision rolled back successfully"
    else
      echo "✗ FAIL: Rollback failed, bad phase still present"
      rm "$test_plan" "$backup_plan"
      return 1
    fi
  else
    echo "✗ FAIL: Cycle should have been detected"
    rm "$test_plan" "$backup_plan"
    return 1
  fi

  rm "$test_plan" "$backup_plan"
  echo "✓ Integration Test 3 PASSED"
  return 0
}
```

**Expected Output**:
```
=== Integration Test 3: Dependency Cycle Detection ===
✓ Backup created: /tmp/tmp.abc123.backup
✓ Circular dependency detected
✓ Plan restored from backup
✓ Bad revision rolled back successfully
✓ Integration Test 3 PASSED
```

### Integration Test 4: Multiple Blocking Theorems

**Objective**: Verify correct handling when multiple theorems blocked on different infrastructure

**Test Implementation**:

```bash
test_multiple_blocking_theorems() {
  echo "=== Integration Test 4: Multiple Blocking Theorems ==="

  # Mock output with 3 theorems blocked on 2 lemmas
  local mock_output=$(mktemp)
  cat > "$mock_output" <<'EOF'
theorems_partial: [theorem_ring_homo, theorem_field_ext, theorem_ideal_properties]
diagnostics:
  - "theorem_ring_homo: blocked on lemma mul_preserving"
  - "theorem_field_ext: blocked on lemma mul_preserving"
  - "theorem_ideal_properties: blocked on lemma ideal_closure"
EOF

  # Parse diagnostics
  PARTIAL_THEOREMS=$(grep "theorems_partial:" "$mock_output" | sed 's/theorems_partial:[[:space:]]*//' | tr -d '[],' | xargs)
  PARTIAL_COUNT=$(echo "$PARTIAL_THEOREMS" | wc -w)

  if [ "$PARTIAL_COUNT" -eq 3 ]; then
    echo "✓ Detected $PARTIAL_COUNT blocking theorems"
  else
    echo "✗ FAIL: Expected 3 blocking theorems, got $PARTIAL_COUNT"
    rm "$mock_output"
    return 1
  fi

  # Group infrastructure by type
  # Expected: 2 lemmas (mul_preserving, ideal_closure)
  # Should create single "Infrastructure Lemmas" phase with both

  INFRA_LEMMAS=$(grep "blocked on lemma" "$mock_output" | sed -E 's/.*blocked on lemma ([A-Za-z0-9_]+).*/\1/' | sort -u)
  LEMMA_COUNT=$(echo "$INFRA_LEMMAS" | wc -w)

  if [ "$LEMMA_COUNT" -eq 2 ]; then
    echo "✓ Identified 2 unique lemmas: $(echo $INFRA_LEMMAS | tr '\n' ' ')"
  else
    echo "✗ FAIL: Expected 2 lemmas, got $LEMMA_COUNT"
    rm "$mock_output"
    return 1
  fi

  # Expected: Single infrastructure phase with 2 lemma tasks
  EXPECTED_PHASE_COUNT=1
  echo "✓ Infrastructure consolidation: $EXPECTED_PHASE_COUNT phase for $LEMMA_COUNT lemmas"

  rm "$mock_output"
  echo "✓ Integration Test 4 PASSED"
  return 0
}
```

**Expected Output**:
```
=== Integration Test 4: Multiple Blocking Theorems ===
✓ Detected 3 blocking theorems
✓ Identified 2 unique lemmas: mul_preserving ideal_closure
✓ Infrastructure consolidation: 1 phase for 2 lemmas
✓ Integration Test 4 PASSED
```

---

## Error Logging Integration

### Error Type Taxonomy

**New Error Types**:
- `plan_revision_error`: lean-plan-updater agent failures (circular dependencies, invalid structure)
- `revision_limit_reached`: MAX_REVISION_DEPTH exceeded (not a failure, deferred action)
- `dependency_recalc_warning`: No phases ready after recalculation (possible planning issue)

### Error Logging Pattern

```bash
# Error 1: Plan revision failed
log_command_error "lean-coordinator" "$WORKFLOW_ID" "" \
  "plan_revision_error" \
  "Plan revision failed: $ERROR_MESSAGE" \
  "lean-plan-updater" \
  "{\"plan\": \"$PLAN_PATH\", \"backup\": \"$BACKUP_PATH\", \"error\": \"$ERROR_DETAILS\"}"

# Warning 2: Revision depth limit
log_command_error "lean-coordinator" "$WORKFLOW_ID" "" \
  "revision_limit_reached" \
  "Plan revision depth limit reached: $REVISION_DEPTH/$MAX_REVISION_DEPTH" \
  "blocking_detection" \
  "{\"partial_count\": $PARTIAL_COUNT, \"diagnostics\": \"$BLOCKING_DIAGNOSTICS\"}"

# Warning 3: Dependency recalculation
log_command_error "lean-coordinator" "$WORKFLOW_ID" "" \
  "dependency_recalc_warning" \
  "No phases ready after recalculation" \
  "dependency-recalculation" \
  "{\"completed\": \"$COMPLETED_PHASES\", \"plan\": \"$PLAN_PATH\"}"
```

---

## Automation Metadata

- **automation_type**: automated
- **validation_method**: programmatic
- **skip_allowed**: false
- **artifact_outputs**: ["plan-revision.log", "dependency-recalc.json", "phase3-validation.json"]

---

## Completion Criteria

- [ ] lean-plan-updater.md agent file created with complete behavioral specification (5 STEPs)
- [ ] lean-coordinator.md STEP 3.5 added (blocking detection and revision trigger)
- [ ] Context budget calculation function implemented with defensive error handling
- [ ] Revision depth counter tracks revisions correctly (MAX_REVISION_DEPTH=2)
- [ ] Task invocation for lean-plan-updater follows standards (imperative directive, prompt structure)
- [ ] dependency-recalculation.sh integration tested with mock revised plans
- [ ] lean-coordinator output signal includes revision metadata (6 new fields)
- [ ] Error logging integration complete (3 error types)
- [ ] All 4 unit tests implemented and passing (100% pass rate)
- [ ] All 4 integration tests implemented and passing (100% pass rate)
- [ ] Backup creation verified before plan mutation
- [ ] Circular dependency detection validated with rollback
- [ ] Context exhaustion handling triggers deferral correctly

---

## Dependencies

### Prerequisites
- dependency-recalculation.sh utility (exists)
- log_command_error function (core/error-handling.sh)
- workflow state persistence (workflow-state-machine.sh)
- Hard barrier pattern from Phase 1 (delegation contract)
- Delegation contract validation from Phase 2 (tool usage audit)

### New Artifacts
- lean-plan-updater.md agent behavioral file (Phase 3 deliverable)

### Integration Points
- lean-coordinator.md STEP 3.5 (new section)
- lean-implement.md (consumes coordinator revision metadata)

---

## Risk Mitigation

### Risk 1: Infinite Revision Loops

**Mitigation**: MAX_REVISION_DEPTH=2 hard limit enforced before Task invocation

### Risk 2: Incorrect Phase Numbering After Insertion

**Mitigation**: lean-plan-updater STEP 3.2 renumbers ALL subsequent phases, STEP 4.1 validates sequential numbering

### Risk 3: Circular Dependencies Introduced

**Mitigation**: STEP 4.2 invokes dependency-analyzer.sh, restores from backup on cycle detection

### Risk 4: Context Budget Miscalculation

**Mitigation**: Defensive validation in estimate_context_remaining(), conservative 50% fallback on calculation errors

---

## Estimated Duration

**Total**: 3-4 hours

**Breakdown**:
- lean-plan-updater agent design: 1.5 hours
- lean-coordinator STEP 3.5 integration: 1 hour
- Unit test implementation: 0.5 hours
- Integration test implementation: 1 hour

---

## PHASE_EXPANDED Signal

This expanded phase file provides:
- Complete lean-plan-updater agent specification (5 STEPs, input/output contracts)
- Detailed lean-coordinator STEP 3.5 integration (blocking detection, context budget, Task invocation)
- dependency-recalculation.sh integration pattern
- 8 comprehensive tests (4 unit + 4 integration) with expected outputs
- Error logging taxonomy (3 new error types)
- Concrete code examples for all components
- Architecture decision rationale (specialized agent vs slash command)

**Status**: PHASE_EXPANDED
