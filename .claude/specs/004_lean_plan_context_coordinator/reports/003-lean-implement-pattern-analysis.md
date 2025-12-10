# Lean Implementation Pattern Analysis Report

## Metadata

**Report Type**: Implementation Pattern Analysis
**Focus**: /implement command orchestration strategies for /lean-plan optimization
**Date**: 2025-12-09
**Analysis Scope**: Wave-based execution, context reduction, state-based coordination, hierarchical agents
**Source Files Analyzed**:
- `/home/benjamin/.config/.claude/commands/implement.md` (1761 lines)
- `/home/benjamin/.config/.claude/commands/lean-implement.md` (1749 lines)
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` (975 lines)
- `/home/benjamin/.config/.claude/lib/util/dependency-analyzer.sh` (200+ lines)
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md` (Example 8)

---

## Executive Summary

The /implement command family demonstrates highly optimized orchestration patterns for managing multi-phase implementation workflows. These patterns achieve **95-96% context reduction** and **40-60% time savings** through hierarchical agent coordination, wave-based parallel execution, and metadata-only communication. The analysis identifies seven key patterns directly applicable to /lean-plan optimization:

1. **Hard Barrier Pattern**: 3-block delegation enforcement (Setup → Execute → Verify) preventing bypass
2. **Wave-Based Orchestration**: Dependency-aware parallel phase execution with topological sorting
3. **Brief Summary Parsing**: 80-token metadata extraction vs 2,000-token full file reads (96% reduction)
4. **Context Estimation & Checkpointing**: Dynamic halting at 85-90% thresholds with resumption support
5. **Iteration Loop Management**: Multi-iteration execution with continuation context tracking
6. **Defensive Validation**: Contract invariant enforcement for agent reliability
7. **State-Based Coordination**: Persistent state machines enabling cross-block communication

These patterns enable /lean-plan to scale from 3-4 iterations (current) to **10+ iterations** (target) while maintaining correctness and architectural modularity.

---

## Finding 1: Hard Barrier Pattern - Mandatory Delegation Enforcement

### Pattern Description

The hard barrier pattern enforces subagent delegation through architectural constraints, preventing orchestrators from bypassing coordinators and performing work directly.

### Implementation in /implement

**File**: `/home/benjamin/.config/.claude/commands/implement.md`
**Lines**: 523-812

The /implement command uses a 3-block structure for implementer-coordinator delegation:

```markdown
## Block 1a: Implementation Phase Setup (Lines 23-521)
- State transition: sm_transition "$STATE_IMPLEMENT"
- Variable persistence: append_workflow_state
- Path pre-calculation: SUMMARIES_DIR, TOPIC_PATH
- Checkpoint reporting: Ready for implementer-coordinator

## Block 1b: Implementer-Coordinator Invocation [CRITICAL BARRIER] (Lines 523-595)
**CRITICAL BARRIER**: This block MUST invoke implementer-coordinator via Task tool.
Verification block (Block 1c) will FAIL if implementation summary is not created.

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallelization"
  prompt: "
    Read and follow: .claude/agents/implementer-coordinator.md

    **Input Contract (Hard Barrier Pattern)**:
    - plan_path: $PLAN_FILE
    - topic_path: $TOPIC_PATH
    - summaries_dir: ${TOPIC_PATH}/summaries/
    - artifact_paths: [pre-calculated paths]

    **CRITICAL**: You MUST create implementation summary at ${TOPIC_PATH}/summaries/
    The orchestrator will validate the summary exists after you return.
  "
}

## Block 1c: Implementation Phase Verification (Lines 599-1043)
# Fail-fast if summary missing
if [ -z "$LATEST_SUMMARY" ] || [ ! -f "$LATEST_SUMMARY" ]; then
  echo "❌ HARD BARRIER FAILED - Implementation summary not found"
  log_command_error "agent_error" "implementer-coordinator failed to create summary"
  exit 1
fi
```

**Key Design Features** (from hierarchical-agents-examples.md, Example 6, lines 483-510):

1. **Bash Blocks Between Task Invocations**: Makes bypass impossible
   - Claude cannot skip bash verification block
   - Fail-fast errors prevent progression without artifacts

2. **State Transitions as Gates**: Explicit state changes prevent phase skipping
   - `sm_transition` returns exit code
   - Non-zero exit code triggers error logging and exits

3. **Mandatory Task Invocation**: CRITICAL BARRIER label emphasizes requirement
   - Verification block depends on Task execution
   - No alternative path available

4. **Fail-Fast Verification**: Exits immediately on missing artifacts
   - Directory existence check
   - File count check (>= 1 required)
   - File size validation (>100 bytes minimum)

### Application to /lean-plan

The /lean-plan command should adopt this pattern for research-coordinator delegation:

**Current Issue**: /lean-plan Phase 1d-exec invokes research-coordinator but lacks hard barrier validation

**Proposed Enhancement**:
```markdown
## Block 1e-validate: Research Validation (Hard Barrier)

# Fail-fast if research directory missing
if [[ ! -d "$RESEARCH_DIR" ]]; then
  log_command_error "validation_error" \
    "Research directory not found: $RESEARCH_DIR"
  exit 1
fi

# Fail-fast if any pre-calculated report path missing
for REPORT_PATH in "${REPORT_PATHS[@]}"; do
  if [[ ! -f "$REPORT_PATH" ]]; then
    log_command_error "validation_error" \
      "Research report missing: $REPORT_PATH"
    exit 1
  fi
done

# Validate minimum report size (>500 bytes)
for REPORT_PATH in "${REPORT_PATHS[@]}"; do
  REPORT_SIZE=$(wc -c < "$REPORT_PATH")
  if [ "$REPORT_SIZE" -lt 500 ]; then
    log_command_error "validation_error" \
      "Report too small ($REPORT_SIZE bytes): $REPORT_PATH"
    exit 1
  fi
done
```

**Benefits**:
- Prevents research-coordinator Task invocation skipping (observed in testing)
- Provides immediate failure feedback vs silent degradation
- Enables error logging with structured diagnostics

---

## Finding 2: Wave-Based Orchestration with Dependency Analysis

### Pattern Description

Wave-based execution groups independent phases into parallel execution waves using topological sorting of dependency graphs. This achieves **40-60% time savings** for plans with 2+ independent phases.

### Implementation in /implement

**File**: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`
**Lines**: 86-126

The implementer-coordinator uses dependency-analyzer.sh to build wave structure:

```bash
# STEP 2: Dependency Analysis (Lines 86-103)
bash /path/to/dependency-analyzer.sh "$plan_path" > dependency_analysis.json

# Parse wave structure from JSON
WAVES=$(jq -r '.waves[] | .wave_number' dependency_analysis.json)
for wave_num in $WAVES; do
  PHASES=$(jq -r ".waves[] | select(.wave_number==$wave_num) | .phases[]" dependency_analysis.json)
  # Invoke executors in parallel for this wave
done
```

**Dependency Metadata Format** (from dependency-analyzer.sh, lines 77-89):
```markdown
### Phase 2: Backend Implementation
**Dependencies**: depends_on: [phase_1]
```

**Wave Structure Output** (implementer-coordinator.md, lines 103-126):
```
╔═══════════════════════════════════════════════════════╗
║ WAVE-BASED IMPLEMENTATION PLAN                        ║
╠═══════════════════════════════════════════════════════╣
║ Total Phases: 5                                       ║
║ Waves: 3                                              ║
║ Parallel Phases: 2                                    ║
║ Sequential Time: 15 hours                             ║
║ Parallel Time: 9 hours                                ║
║ Time Savings: 40%                                     ║
╠═══════════════════════════════════════════════════════╣
║ Wave 1: Setup (1 phase)                               ║
║ ├─ Phase 1: Project Setup                            ║
╠═══════════════════════════════════════════════════════╣
║ Wave 2: Implementation (2 phases, PARALLEL)           ║
║ ├─ Phase 2: Backend Implementation                   ║
║ └─ Phase 3: Frontend Implementation                  ║
╠═══════════════════════════════════════════════════════╣
║ Wave 3: Integration (2 phases, PARALLEL)              ║
║ ├─ Phase 4: API Integration                          ║
║ └─ Phase 5: Testing                                  ║
╚═══════════════════════════════════════════════════════╝
```

**Parallel Executor Invocation** (implementer-coordinator.md, lines 256-330):
```markdown
# Wave 2 with 2 phases - invoke both executors in single response
**EXECUTE NOW**: USE the Task tool to invoke implementation-executor.

Task {
  description: "Execute Phase 2 implementation"
  prompt: |
    Read and follow: .claude/agents/implementation-executor.md
    Input: phase_file_path, topic_path, wave_number: 2
}

**EXECUTE NOW**: USE the Task tool to invoke implementation-executor.

Task {
  description: "Execute Phase 3 implementation"
  prompt: |
    Read and follow: .claude/agents/implementation-executor.md
    Input: phase_file_path, topic_path, wave_number: 2
}
```

**Wave Synchronization** (implementer-coordinator.md, lines 388-395):
```markdown
**CRITICAL**: Wait for ALL executors in wave to complete before proceeding to next wave.

- All executors MUST report completion (success or failure)
- Aggregate results from all executors
- Update implementation state with wave results
- Proceed to next wave only after synchronization
```

### Application to /lean-plan

The /lean-plan command currently has no wave-based orchestration. Research topics are invoked sequentially or in parallel without dependency awareness.

**Current Limitation**: Research topics are classified by complexity (2-4 topics) but not analyzed for dependencies

**Proposed Enhancement**: Integrate dependency-aware research orchestration

**Step 1: Add Dependency Metadata to Research Topics**
```bash
# In Block 1d-topics: Research Topics Classification
LEAN_TOPICS=(
  "Mathlib Theorems|depends_on:[]"
  "Proof Strategies|depends_on:[Mathlib Theorems]"
  "Project Structure|depends_on:[]"
  "Style Guide|depends_on:[Project Structure]"
)
```

**Step 2: Invoke dependency-analyzer for Research Wave Structure**
```bash
# Create temporary plan file with research phase metadata
TEMP_RESEARCH_PLAN="${LEAN_PLAN_WORKSPACE}/research_phases.md"
for i in "${!LEAN_TOPICS[@]}"; do
  TOPIC_NAME=$(echo "${LEAN_TOPICS[$i]}" | cut -d'|' -f1)
  DEPENDS=$(echo "${LEAN_TOPICS[$i]}" | cut -d'|' -f2)
  cat >> "$TEMP_RESEARCH_PLAN" <<EOF
### Phase $((i+1)): Research $TOPIC_NAME
**Dependencies**: $DEPENDS

- [ ] Research task
EOF
done

# Analyze dependencies
bash "$CLAUDE_LIB/util/dependency-analyzer.sh" "$TEMP_RESEARCH_PLAN" > research_waves.json
```

**Step 3: Execute Research in Waves**
```bash
# Read wave structure
WAVES=$(jq -r '.waves[] | .wave_number' research_waves.json)

for wave_num in $WAVES; do
  echo "=== Research Wave $wave_num ==="

  # Get topics for this wave
  WAVE_TOPICS=$(jq -r ".waves[] | select(.wave_number==$wave_num) | .phases[]" research_waves.json)

  # Invoke research-specialist in parallel for all topics in wave
  for topic_id in $WAVE_TOPICS; do
    # Extract topic index from phase_N format
    topic_idx=$(echo "$topic_id" | sed 's/phase_//')
    topic_name="${LEAN_TOPICS[$((topic_idx-1))]}"

    Task {
      description: "Research $topic_name (Wave $wave_num)"
      prompt: "Read and follow: .claude/agents/research-specialist.md
        Topic: $topic_name
        Output: ${REPORT_PATHS[$((topic_idx-1))]}"
    }
  done

  # Wait for wave completion before next wave
done
```

**Benefits**:
- **Correctness**: Ensures Proof Strategies research waits for Mathlib Theorems completion
- **Efficiency**: Parallelizes independent topics (Mathlib + Project Structure in Wave 1)
- **Scalability**: Handles 4-topic complexity-4 plans with optimal wave grouping

**Time Savings Estimate**:
- Complexity 3 (3 topics, 2 independent): 33% time savings (2 topics in Wave 1, 1 in Wave 2)
- Complexity 4 (4 topics, 2 independent waves): 50% time savings (2+2 parallel waves)

---

## Finding 3: Brief Summary Parsing - Context Reduction via Metadata

### Pattern Description

Brief summary parsing extracts 80-token structured metadata from agent return signals instead of reading 2,000-token full summary files, achieving **96% context reduction**.

### Implementation in /lean-implement

**File**: `/home/benjamin/.config/.claude/commands/lean-implement.md`
**Lines**: 1096-1182

The /lean-implement command parses coordinator output via structured metadata fields at top of summary file:

```bash
# Block 1c: Brief Summary Parsing (Lines 1111-1137)

# Parse brief summary fields (96% context reduction)
SUMMARY_BRIEF=$(grep "^summary_brief:" "$LATEST_SUMMARY" | sed 's/^summary_brief:[[:space:]]*//')
PHASES_COMPLETED=$(grep "^phases_completed:" "$LATEST_SUMMARY" | sed 's/^phases_completed:[[:space:]]*//' | tr -d '[],"')
CONTEXT_USAGE_PERCENT=$(grep "^context_usage_percent:" "$LATEST_SUMMARY" | sed 's/^context_usage_percent:[[:space:]]*//' | sed 's/%//')
WORK_REMAINING=$(grep "^work_remaining:" "$LATEST_SUMMARY" | sed 's/^work_remaining:[[:space:]]*//')

# Display brief summary (no full file read required)
echo "Summary: $SUMMARY_BRIEF"
echo "Phases completed: ${PHASES_COMPLETED:-none}"
echo "Context usage: ${CONTEXT_USAGE_PERCENT}%"
echo "Full report: $LATEST_SUMMARY"

# Context reduction: 80 tokens parsed vs 2,000 tokens read = 96% reduction
```

**Summary File Format** (implementer-coordinator.md, lines 514-554):
```markdown
coordinator_type: software
summary_brief: "Completed Wave 1 (Phase 3,4) with 25 tasks. Context: 65%. Next: Continue Wave 2."
phases_completed: [3, 4]
phase_count: 2
git_commits: [hash1, hash2]
work_remaining: Phase_5 Phase_6
context_exhausted: false
context_usage_percent: 65
requires_continuation: true

# Implementation Summary - Iteration 1

## Work Status
**Completion**: 2/6 phases (33%)

## Completed Phases
- Phase 3: Authentication Module (8 tasks)
- Phase 4: Database Layer (12 tasks)

[... full markdown content follows ...]
```

**Brief Summary Generation Logic** (implementer-coordinator.md, lines 456-506):
```bash
# Determine wave range
WAVE_START=1
WAVE_END=$CURRENT_WAVE

# Build phase list
PHASES_COMPLETED=$(echo "$COMPLETED_PHASES" | tr ' ' ',')

# Count tasks
TASKS_COMPLETED=$(grep -c "\[x\]" "$PLAN_FILE" || echo 0)

# Get context usage
CONTEXT_PERCENT=$(estimate_context_usage)

# Determine next action
if [ "$WAVES_REMAINING" -gt 0 ]; then
  NEXT_ACTION="Continue Wave $((WAVE_END + 1))"
elif [ "$CONTEXT_EXHAUSTED" = "true" ]; then
  NEXT_ACTION="Context limit"
else
  NEXT_ACTION="Complete"
fi

# Generate brief summary (max 150 characters)
SUMMARY_BRIEF="Completed Wave ${WAVE_START}-${WAVE_END} (Phase ${PHASES_COMPLETED}) with ${TASKS_COMPLETED} tasks. Context: ${CONTEXT_PERCENT}%. Next: ${NEXT_ACTION}."
SUMMARY_BRIEF="${SUMMARY_BRIEF:0:150}"
```

### Application to /lean-plan

The /lean-plan command currently lacks brief summary parsing. It passes full report metadata (330 tokens for 3 reports) to lean-plan-architect.

**Current Pattern** (from lean-plan-output.md, lines 119-136):
```markdown
# /lean-plan reads full reports to extract metadata
Read(.claude/specs/063_proof_automation_tactics_refactor/reports/001-mathlib-theorems.md)
Read(.claude/specs/063_proof_automation_tactics_refactor/reports/002-proof-strategies.md)
Read(.claude/specs/063_proof_automation_tactics_refactor/reports/003-project-structure.md)
Read(.claude/specs/063_proof_automation_tactics_refactor/reports/004-style-guide.md)

# Then invokes lean-plan-architect with full context
Task {
  prompt: |
    Research Reports: 4 reports created
    - /path/to/001-mathlib-theorems.md
    - /path/to/002-proof-strategies.md
    ...
}
```

**Proposed Enhancement**: Add structured metadata to research reports

**Step 1: Enhance research-specialist to emit metadata fields**
```markdown
# In research-specialist.md output format
Create report at specified path with structure:

report_type: lean_research
topic: "Mathlib Theorems"
findings_count: 12
recommendations_count: 5
mathlib_theorems_found: 8
proof_tactics_analyzed: 6

# Mathlib Theorems Research Report

## Executive Summary
[... full content ...]
```

**Step 2: Parse metadata in /lean-plan Block 1f-metadata**
```bash
# Extract metadata from each report (80 tokens vs 2,500 full read)
REPORT_METADATA=()
for REPORT_PATH in "${REPORT_PATHS[@]}"; do
  # Parse structured fields (first 10 lines)
  TOPIC=$(head -10 "$REPORT_PATH" | grep "^topic:" | sed 's/^topic:[[:space:]]*//' | tr -d '"')
  FINDINGS=$(head -10 "$REPORT_PATH" | grep "^findings_count:" | sed 's/^findings_count:[[:space:]]*//')
  RECOMMENDATIONS=$(head -10 "$REPORT_PATH" | grep "^recommendations_count:" | sed 's/^recommendations_count:[[:space:]]*//')

  REPORT_METADATA+=("$TOPIC|$FINDINGS|$RECOMMENDATIONS|$REPORT_PATH")
done

# Format for architect prompt (80 tokens vs 2,500 per report)
FORMATTED_METADATA=""
for metadata in "${REPORT_METADATA[@]}"; do
  TOPIC=$(echo "$metadata" | cut -d'|' -f1)
  FINDINGS=$(echo "$metadata" | cut -d'|' -f2)
  RECS=$(echo "$metadata" | cut -d'|' -f3)
  PATH=$(echo "$metadata" | cut -d'|' -f4)

  FORMATTED_METADATA+="- $TOPIC: $FINDINGS findings, $RECS recommendations ($PATH)\n"
done
```

**Step 3: Pass metadata-only context to lean-plan-architect**
```markdown
Task {
  description: "Create Lean implementation plan"
  prompt: |
    Read and follow: .claude/agents/lean-plan-architect.md

    **Research Context** (metadata-only):
    ${FORMATTED_METADATA}

    **CRITICAL**: Use Read tool to access full reports as needed.
    DO NOT expect full content in this prompt.

    Output: ${PLAN_PATH}
}
```

**Context Reduction**:
- **Before**: 4 reports × 2,500 tokens = 10,000 tokens
- **After**: 4 reports × 80 tokens = 320 tokens
- **Reduction**: 96.8%

---

## Finding 4: Context Estimation & Dynamic Checkpointing

### Pattern Description

Context estimation calculates current token usage after each iteration and triggers checkpoint saving when threshold (85-90%) is exceeded, enabling graceful halt and resumption.

### Implementation in /implement

**File**: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`
**Lines**: 133-189

The implementer-coordinator estimates context usage with defensive error handling:

```bash
# Context Estimation (Lines 144-189)
estimate_context_usage() {
  local completed_phases="$1"
  local remaining_phases="$2"
  local has_continuation="$3"

  # Defensive: Validate inputs are numeric
  if ! [[ "$completed_phases" =~ ^[0-9]+$ ]]; then
    echo "WARNING: Invalid completed_phases, defaulting to 0" >&2
    completed_phases=0
  fi
  if ! [[ "$remaining_phases" =~ ^[0-9]+$ ]]; then
    echo "WARNING: Invalid remaining_phases, defaulting to 1" >&2
    remaining_phases=1
  fi

  # Token cost estimates per component
  local base=20000  # Plan file + standards + system prompt
  local completed_cost=$((completed_phases * 15000))  # 15k per completed phase
  local remaining_cost=$((remaining_phases * 12000))  # 12k per remaining phase
  local continuation_cost=0

  if [ "$has_continuation" = "true" ]; then
    continuation_cost=5000
  fi

  local total=$((base + completed_cost + remaining_cost + continuation_cost))

  # Defensive: Sanity check (valid range: 10k-300k tokens)
  if [ "$total" -lt 10000 ] || [ "$total" -gt 300000 ]; then
    echo "WARNING: Context estimate out of range ($total tokens), using conservative 50%" >&2
    echo 100000  # Conservative 50% of 200k context window
  else
    echo "$total"
  fi
}
```

**Checkpoint Saving** (implementer-coordinator.md, lines 196-229):
```bash
save_resumption_checkpoint() {
  local halt_reason="$1"
  local checkpoint_dir="${artifact_paths[checkpoints]}"

  jq -n \
    --arg version "2.1" \
    --arg plan_path "$plan_path" \
    --arg topic_path "$topic_path" \
    --argjson iteration "$iteration" \
    --arg work_remaining "$work_remaining" \
    --argjson context_estimate "$context_estimate" \
    --arg halt_reason "$halt_reason" \
    '{
      version: $version,
      plan_path: $plan_path,
      topic_path: $topic_path,
      iteration: $iteration,
      work_remaining: $work_remaining,
      context_estimate: $context_estimate,
      halt_reason: $halt_reason
    }' > "${checkpoint_dir}/implement_${workflow_id}_iteration_${iteration}.json"
}
```

**Context Threshold Enforcement** (/lean-implement.md, lines 1247-1289):
```bash
# Check context usage against threshold
if [ "$CONTEXT_USAGE_PERCENT" -ge "$CONTEXT_THRESHOLD" ]; then
  echo "WARNING: Context usage at ${CONTEXT_USAGE_PERCENT}% (threshold: ${CONTEXT_THRESHOLD}%)"

  # Save checkpoint
  CHECKPOINT_DATA=$(jq -n \
    --arg plan_path "$PLAN_FILE" \
    --argjson iteration "$ITERATION" \
    --arg work_remaining "$WORK_REMAINING_NEW" \
    --argjson context_usage "$CONTEXT_USAGE_PERCENT" \
    --arg halt_reason "context_threshold_exceeded" \
    '{...}')

  save_checkpoint "lean_implement" "$WORKFLOW_ID" "$CHECKPOINT_DATA"

  # Halt workflow
  REQUIRES_CONTINUATION="false"
fi
```

### Application to /lean-plan

The /lean-plan command currently has no context estimation or checkpointing. Large plans (complexity 4, 4 research topics) may exceed context limits.

**Proposed Enhancement**: Add context monitoring to research coordinator

**Step 1: Estimate Context in research-coordinator**
```bash
# After collecting all research reports in STEP 5
estimate_research_context() {
  local report_count="$1"
  local report_avg_size="$2"  # Average report size in tokens

  # Base: System prompt + coordinator logic
  local base=15000

  # Per-report overhead: metadata extraction + validation
  local per_report=2000

  # Aggregate metadata size
  local metadata_total=$((report_count * 110))  # 110 tokens per report metadata

  local total=$((base + (report_count * per_report) + metadata_total))

  # Percentage of 200k context window
  local percentage=$((total * 100 / 200000))

  echo "$percentage"
}

# Usage
CONTEXT_USAGE=$(estimate_research_context "${#REPORT_PATHS[@]}" 2500)
echo "context_usage_percent: $CONTEXT_USAGE" >> "$AGGREGATED_METADATA_FILE"
```

**Step 2: Save Research Checkpoint if Threshold Exceeded**
```bash
# In research-coordinator STEP 6: Return aggregated metadata
if [ "$CONTEXT_USAGE_PERCENT" -ge 85 ]; then
  echo "WARNING: Research context at ${CONTEXT_USAGE_PERCENT}%, saving checkpoint"

  # Save checkpoint with partial research results
  CHECKPOINT_FILE="${CHECKPOINTS_DIR}/research_${WORKFLOW_ID}_partial.json"
  jq -n \
    --arg version "1.0" \
    --argjson reports_completed "${#SUCCESSFUL_REPORTS[@]}" \
    --argjson reports_total "${#REPORT_PATHS[@]}" \
    --argjson context_percent "$CONTEXT_USAGE_PERCENT" \
    '{
      version: $version,
      reports_completed: $reports_completed,
      reports_total: $reports_total,
      context_percent: $context_percent,
      completed_paths: $SUCCESSFUL_REPORTS
    }' > "$CHECKPOINT_FILE"

  echo "checkpoint_path: $CHECKPOINT_FILE" >> "$AGGREGATED_METADATA_FILE"
fi
```

**Step 3: Partial Success Mode in /lean-plan**
```bash
# In Block 1f-validate
SUCCESS_PERCENTAGE=$((SUCCESSFUL_REPORTS * 100 / TOTAL_REPORTS))

# Allow partial success if ≥50% reports created
if [ $SUCCESS_PERCENTAGE -lt 50 ]; then
  log_command_error "validation_error" \
    "Research validation failed: <50% success rate"
  exit 1
fi

# Warn if 50-99% success
if [ $SUCCESS_PERCENTAGE -lt 100 ]; then
  echo "WARNING: Partial research success (${SUCCESS_PERCENTAGE}%)"
  echo "Proceeding with $SUCCESSFUL_REPORTS/$TOTAL_REPORTS reports..."
fi
```

**Benefits**:
- **Graceful Degradation**: Proceeds with 50%+ completed research instead of full failure
- **Context Awareness**: Monitors token usage across research phase
- **Resumption Support**: Checkpoint enables future resume-from-partial-research feature

---

## Finding 5: Iteration Loop Management with Continuation Context

### Pattern Description

Iteration loop management enables multi-iteration execution for large plans by tracking work remaining, saving continuation context, and resuming from previous iteration summaries.

### Implementation in /implement

**File**: `/home/benjamin/.config/.claude/commands/implement.md`
**Lines**: 1000-1182

The /implement command implements iteration decision logic in Block 1c:

```bash
# Block 1c: Iteration Decision (Lines 1000-1043)

# Parse coordinator output for continuation signals
WORK_REMAINING=$(grep "^work_remaining:" "$LATEST_SUMMARY" | sed 's/^work_remaining:[[:space:]]*//')
REQUIRES_CONTINUATION=$(grep "^requires_continuation:" "$LATEST_SUMMARY" | sed 's/^requires_continuation:[[:space:]]*//')
CONTEXT_USAGE_PERCENT=$(grep "^context_usage_percent:" "$LATEST_SUMMARY" | sed 's/^context_usage_percent:[[:space:]]*//')

# Defensive validation: Override requires_continuation if work remains
if [ -n "$WORK_REMAINING" ] && [ "$WORK_REMAINING" != "0" ]; then
  if [ "$REQUIRES_CONTINUATION" != "true" ]; then
    echo "WARNING: Agent returned requires_continuation=false with non-empty work_remaining"
    log_command_error "validation_error" "Agent contract violation"
    REQUIRES_CONTINUATION="true"  # Override
  fi
fi

# Check iteration limit
if [ "$REQUIRES_CONTINUATION" = "true" ] && [ "$ITERATION" -lt "$MAX_ITERATIONS" ]; then
  NEXT_ITERATION=$((ITERATION + 1))
  CONTINUATION_CONTEXT="${IMPLEMENT_WORKSPACE}/iteration_${ITERATION}_summary.md"

  # Save current summary for next iteration
  cp "$LATEST_SUMMARY" "$CONTINUATION_CONTEXT"

  # Update state for next iteration
  append_workflow_state "ITERATION" "$NEXT_ITERATION"
  append_workflow_state "WORK_REMAINING" "$WORK_REMAINING"
  append_workflow_state "CONTINUATION_CONTEXT" "$CONTINUATION_CONTEXT"

  # HARD BARRIER: Exit here, resume at Block 1b
  exit 0
else
  # Work complete or max iterations reached
  append_workflow_state "IMPLEMENTATION_STATUS" "complete"
fi
```

**Iteration Context Passing** (implement.md, lines 1115-1180):
```markdown
# On next iteration, Block 1b passes continuation_context to coordinator

Task {
  prompt: |
    Read and follow: .claude/agents/implementer-coordinator.md

    **Input Contract**:
    - continuation_context: ${CONTINUATION_CONTEXT}
    - iteration: ${ITERATION}
    - max_iterations: ${MAX_ITERATIONS}
    - work_remaining: ${WORK_REMAINING}

    **Workflow Instructions**:
    Resume from first incomplete phase listed in work_remaining.
    Read continuation_context for completed phase context.
}
```

**Multi-Iteration Example** (implementer-coordinator.md, lines 849-870):
```
Iteration 1 (fresh start):
  - Executes phases 1-5
  - Context ~85%
  - Returns: work_remaining: Phase_6 Phase_7 Phase_8

Iteration 2 (continuation):
  - Reads iteration_1_summary.md
  - Executes phases 6-9
  - Context ~88%
  - Returns: work_remaining: Phase_10 Phase_11

Iteration 3 (continuation):
  - Reads iteration_2_summary.md
  - Executes phases 10-11
  - Returns: work_remaining: 0
```

### Application to /lean-plan

The /lean-plan command currently lacks iteration loop support. Large complexity-4 plans with 4 research topics may exceed single-iteration limits.

**Current Limitation**: /lean-plan completes all research in single iteration or fails entirely

**Proposed Enhancement**: Add iteration loop to /lean-plan

**Step 1: Add Iteration Variables to Block 1c**
```bash
# Initialize iteration tracking
ITERATION=1
MAX_ITERATIONS=3  # Allow up to 3 research iterations
RESEARCH_COMPLETE="false"
TOPICS_REMAINING="${TOPICS[@]}"

# Persist for cross-block access
append_workflow_state "ITERATION" "$ITERATION"
append_workflow_state "MAX_ITERATIONS" "$MAX_ITERATIONS"
append_workflow_state "TOPICS_REMAINING" "$TOPICS_REMAINING"
```

**Step 2: Coordinator Returns Partial Completion Signal**
```markdown
# In research-coordinator STEP 6

RESEARCH_COMPLETE:
  reports_completed: [1, 2]
  topics_completed: ["Mathlib Theorems", "Proof Strategies"]
  topics_remaining: ["Project Structure", "Style Guide"]
  context_usage_percent: 88
  requires_continuation: true
```

**Step 3: Iteration Decision in /lean-plan Block 1f**
```bash
# Parse coordinator return signal
TOPICS_REMAINING=$(grep "^topics_remaining:" "$METADATA_FILE" | sed 's/^topics_remaining:[[:space:]]*//')
REQUIRES_CONTINUATION=$(grep "^requires_continuation:" "$METADATA_FILE" | sed 's/^requires_continuation:[[:space:]]*//')

# Check iteration limit
if [ "$REQUIRES_CONTINUATION" = "true" ] && [ "$ITERATION" -lt "$MAX_ITERATIONS" ]; then
  NEXT_ITERATION=$((ITERATION + 1))

  # Save partial metadata for next iteration
  CONTINUATION_METADATA="${LEAN_PLAN_WORKSPACE}/iteration_${ITERATION}_metadata.json"
  cp "$AGGREGATED_METADATA_FILE" "$CONTINUATION_METADATA"

  # Update state
  append_workflow_state "ITERATION" "$NEXT_ITERATION"
  append_workflow_state "TOPICS_REMAINING" "$TOPICS_REMAINING"

  echo "Continuing to iteration $NEXT_ITERATION for remaining topics: $TOPICS_REMAINING"

  # Loop back to Block 1e-exec for next batch
  exit 0
else
  # All topics researched or max iterations reached
  echo "Research complete: $ITERATION iterations"
fi
```

**Benefits**:
- **Scalability**: Handles complexity-4 plans (4 topics) across 2-3 iterations
- **Robustness**: Graceful degradation if 1-2 topics fail in iteration
- **Efficiency**: Each iteration consumes 40-60k tokens vs 100k+ for all-at-once

---

## Finding 6: Defensive Validation - Contract Invariant Enforcement

### Pattern Description

Defensive validation enforces contract invariants between agents by validating return signals and overriding invalid states to prevent workflow failures from agent bugs.

### Implementation in /implement

**File**: `/home/benjamin/.config/.claude/commands/implement.md`
**Lines**: 943-999

The /implement command validates the `work_remaining` ↔ `requires_continuation` invariant:

```bash
# Block 1c: Defensive Validation (Lines 943-999)

# Helper function: Check if work_remaining is truly empty
is_work_remaining_empty() {
  local work_remaining="${1:-}"

  # Empty string
  [ -z "$work_remaining" ] && return 0

  # Literal "0"
  [ "$work_remaining" = "0" ] && return 0

  # Empty JSON array "[]"
  [ "$work_remaining" = "[]" ] && return 0

  # Contains only whitespace
  [[ "$work_remaining" =~ ^[[:space:]]*$ ]] && return 0

  # Work remains
  return 1
}

# Validate invariant: work_remaining non-empty → requires_continuation must be true
if ! is_work_remaining_empty "$WORK_REMAINING"; then
  # Work remains - continuation is MANDATORY
  if [ "$REQUIRES_CONTINUATION" != "true" ]; then
    echo "WARNING: Agent returned requires_continuation=false with non-empty work_remaining"
    echo "  work_remaining: $WORK_REMAINING"
    echo "  OVERRIDING: Forcing continuation due to incomplete work"

    # Log agent contract violation
    log_command_error \
      "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "validation_error" \
      "Agent contract violation: requires_continuation=false with work_remaining non-empty" \
      "bash_block_1c_defensive_validation" \
      "$(jq -n --arg work "$WORK_REMAINING" --arg cont "$REQUIRES_CONTINUATION" \
         '{work_remaining: $work, requires_continuation: $cont, override: "forced_true"}')"

    # Override agent signal
    REQUIRES_CONTINUATION="true"
  fi
fi
```

**Contract Documentation** (implementer-coordinator.md, lines 673-713):
```markdown
### Return Signal Contract

**CRITICAL INVARIANT**: work_remaining and requires_continuation MUST satisfy:

| work_remaining | requires_continuation | Valid? | Description |
|----------------|----------------------|---------|-------------|
| Non-empty      | true                 | ✓ Valid | Work remains, continuation needed |
| Empty/0        | false                | ✓ Valid | No work, halt workflow |
| Empty/0        | true                 | ⚠ Suboptimal | No work but requesting continuation |
| Non-empty      | false                | ✗ INVALID | Contract violation - orchestrator overrides |

**Defensive Orchestrator Behavior**:
If work_remaining is non-empty and requires_continuation=false:
1. Log validation_error to errors.jsonl
2. Override requires_continuation to true
3. Continue to next iteration with warning
4. Workflow continues instead of halting prematurely
```

### Application to /lean-plan

The /lean-plan command should add defensive validation for research-coordinator return signals.

**Proposed Enhancement**: Validate research completion contract

**Contract Definition**:
```markdown
# In research-coordinator.md

### Return Signal Contract

| topics_remaining | requires_continuation | Valid? | Description |
|------------------|----------------------|---------|-------------|
| Non-empty array  | true                 | ✓ Valid | Topics remain, continue research |
| Empty array      | false                | ✓ Valid | All topics researched |
| Empty array      | true                 | ⚠ Suboptimal | No topics but requesting continuation |
| Non-empty array  | false                | ✗ INVALID | Contract violation - orchestrator overrides |
```

**Validation Implementation**:
```bash
# In /lean-plan Block 1f-validate

# Parse coordinator return signal
TOPICS_REMAINING=$(grep "^topics_remaining:" "$METADATA_FILE" | sed 's/^topics_remaining:[[:space:]]*//' | tr -d '[],"')
REQUIRES_CONTINUATION=$(grep "^requires_continuation:" "$METADATA_FILE" | sed 's/^requires_continuation:[[:space:]]*//')

# Validate contract invariant
if [ -n "$TOPICS_REMAINING" ]; then
  # Topics remain
  if [ "$REQUIRES_CONTINUATION" != "true" ]; then
    echo "WARNING: Coordinator returned requires_continuation=false with topics remaining"
    echo "  topics_remaining: $TOPICS_REMAINING"
    echo "  OVERRIDING: Forcing continuation due to incomplete research"

    log_command_error \
      "/lean-plan" "$WORKFLOW_ID" "$FEATURE_DESCRIPTION" \
      "validation_error" \
      "research-coordinator contract violation: requires_continuation=false with topics_remaining non-empty" \
      "bash_block_1f_defensive_validation" \
      "$(jq -n --arg topics "$TOPICS_REMAINING" --arg cont "$REQUIRES_CONTINUATION" \
         '{topics_remaining: $topics, requires_continuation: $cont, override: "forced_true"}')"

    REQUIRES_CONTINUATION="true"
  fi
fi
```

**Benefits**:
- **Reliability**: Prevents premature halt from coordinator bugs
- **Observability**: Logs contract violations for debugging
- **Graceful Degradation**: Overrides invalid signals instead of failing

---

## Finding 7: State-Based Coordination with Persistent State Machines

### Pattern Description

State-based coordination uses persistent state machines (workflow-state-machine.sh) to manage workflow transitions, enabling cross-block variable persistence and validation.

### Implementation in /implement

**File**: `/home/benjamin/.config/.claude/commands/implement.md`
**Lines**: 378-462

The /implement command uses state machine for workflow orchestration:

```bash
# Block 1a: State Machine Initialization (Lines 378-462)

# Initialize workflow state file
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE

# Validate state file creation
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "state_error" \
    "Failed to initialize workflow state file" \
    "bash_block_1a" \
    "$(jq -n --arg path "${STATE_FILE:-UNDEFINED}" '{expected_path: $path}')"
  exit 1
fi

# Initialize state machine with workflow metadata
sm_init "$PLAN_FILE" "$COMMAND_NAME" "$WORKFLOW_TYPE" "1" "[]" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error "state_error" "State machine initialization failed"
  exit 1
fi

# Transition to implement state
sm_transition "$STATE_IMPLEMENT" "plan loaded, starting implementation" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error "state_error" "State transition to IMPLEMENT failed"
  exit 1
fi

# Persist variables for next block
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
append_workflow_state "PLAN_FILE" "$PLAN_FILE"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "ITERATION" "$ITERATION"
```

**State Restoration in Verification Block** (implement.md, lines 649-672):
```bash
# Block 1c: Load State (Lines 649-672)

# Restore WORKFLOW_ID from persistent file
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/implement_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

# Load workflow state variables
load_workflow_state "$WORKFLOW_ID" false
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to load workflow state"
  exit 1
fi

# Validate critical variables restored
validate_state_restoration "PLAN_FILE" "TOPIC_PATH" "MAX_ITERATIONS" || {
  echo "ERROR: State restoration failed - critical variables missing"
  exit 1
}
```

**State Persistence Pattern** (Lines 466-504):
```bash
# Persist all workflow variables
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
append_workflow_state "USER_ARGS" "$USER_ARGS"
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"
append_workflow_state "PLAN_FILE" "$PLAN_FILE"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "MAX_ITERATIONS" "$MAX_ITERATIONS"
append_workflow_state "ITERATION" "$ITERATION"
append_workflow_state "CONTINUATION_CONTEXT" "$CONTINUATION_CONTEXT"
```

### Application to /lean-plan

The /lean-plan command currently uses state persistence but lacks comprehensive state machine integration.

**Current Pattern**: Manual variable persistence without state machine validation

**Proposed Enhancement**: Integrate workflow-state-machine.sh

**Step 1: Initialize State Machine in Block 1c**
```bash
# In Block 1c: Setup

# Initialize workflow state file
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE

# Initialize state machine
sm_init "$FEATURE_DESCRIPTION" "/lean-plan" "lean-research-and-plan" "1" "[]"

# Transition to research state
sm_transition "$STATE_RESEARCH" "starting multi-topic research phase"
```

**Step 2: State Transitions for Research Phases**
```bash
# After research-coordinator completes
sm_transition "$STATE_PLAN" "research complete, starting plan creation"

# After lean-plan-architect completes
sm_transition "$STATE_COMPLETE" "lean plan created"
```

**Step 3: State Validation in Error Paths**
```bash
# In Block 1f-validate: Hard Barrier Validation

if [ $SUCCESS_PERCENTAGE -lt 50 ]; then
  # Log state error before exit
  sm_transition "$STATE_ERROR" "research validation failed: <50% success rate"

  log_command_error "validation_error" \
    "Research validation failed: <50% success rate"
  exit 1
fi
```

**Benefits**:
- **Consistency**: Standardized state transitions across all commands
- **Observability**: State machine logs enable workflow debugging
- **Validation**: Built-in state transition validation prevents invalid sequences

---

## Recommendations

### Priority 1: Implement Hard Barrier Pattern for Research Delegation

**Action**: Add Block 1f-validate to /lean-plan with fail-fast validation
**Impact**: HIGH - Prevents silent research-coordinator failures
**Complexity**: LOW - 20 lines of bash validation code
**References**: Finding 1, hierarchical-agents-examples.md Example 6

### Priority 2: Integrate Brief Summary Parsing for Research Reports

**Action**: Add structured metadata fields to research-specialist output format
**Impact**: HIGH - 96% context reduction (10,000 → 320 tokens for 4 reports)
**Complexity**: MEDIUM - Requires research-specialist.md updates + /lean-plan parsing
**References**: Finding 3, implementer-coordinator.md lines 514-554

### Priority 3: Add Context Estimation to Research Phase

**Action**: Implement estimate_research_context() in research-coordinator
**Impact**: MEDIUM - Enables graceful halt at 85-90% thresholds
**Complexity**: MEDIUM - 40 lines of context calculation + checkpoint integration
**References**: Finding 4, implementer-coordinator.md lines 133-189

### Priority 4: Implement Iteration Loop Management

**Action**: Add ITERATION, MAX_ITERATIONS, TOPICS_REMAINING state tracking
**Impact**: HIGH - Enables 10+ iteration capacity (vs 3-4 current)
**Complexity**: HIGH - Requires continuation context passing + iteration decision logic
**References**: Finding 5, implement.md lines 1000-1182

### Priority 5: Add Defensive Validation for Coordinator Contracts

**Action**: Validate topics_remaining ↔ requires_continuation invariant
**Impact**: MEDIUM - Prevents premature workflow halt from agent bugs
**Complexity**: LOW - 30 lines of validation + override logic
**References**: Finding 6, implement.md lines 943-999

### Priority 6: Integrate Wave-Based Research Orchestration

**Action**: Add dependency metadata to research topics, invoke dependency-analyzer
**Impact**: MEDIUM - 33-50% time savings for parallel-safe topics
**Complexity**: HIGH - Requires dependency-analyzer integration + wave execution
**References**: Finding 2, implementer-coordinator.md lines 86-395

### Priority 7: Enhance State Machine Integration

**Action**: Add sm_transition calls for RESEARCH, PLAN, COMPLETE states
**Impact**: LOW - Improves observability and debugging
**Complexity**: LOW - 10 lines of state machine calls
**References**: Finding 7, implement.md lines 378-462

---

## Performance Metrics Summary

| Optimization | Before | After | Improvement |
|--------------|--------|-------|-------------|
| Context per Research Report | 2,500 tokens | 80 tokens | 96.8% reduction |
| Total Research Context (4 reports) | 10,000 tokens | 320 tokens | 96.8% reduction |
| Research Time (4 topics, 2 parallel) | Sequential | 2 waves | 50% time savings |
| Iteration Capacity | 3-4 iterations | 10+ iterations | 150-200% increase |
| Context Threshold Monitoring | None | 85-90% dynamic | Graceful halt enabled |

**Cumulative Impact**:
- **Context Efficiency**: 95-96% reduction in orchestrator context usage
- **Time Efficiency**: 40-60% reduction in research phase execution time
- **Scalability**: 10+ iteration capacity for large complexity-4 plans
- **Reliability**: Hard barrier pattern + defensive validation prevent silent failures

---

## References

1. **Primary Sources**:
   - `/home/benjamin/.config/.claude/commands/implement.md` - Implementation workflow (1761 lines)
   - `/home/benjamin/.config/.claude/commands/lean-implement.md` - Lean hybrid workflow (1749 lines)
   - `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` - Wave orchestration (975 lines)
   - `/home/benjamin/.config/.claude/lib/util/dependency-analyzer.sh` - Dependency graph builder (200+ lines)

2. **Documentation**:
   - `.claude/docs/concepts/hierarchical-agents-examples.md` - Example 8: Lean Command Coordinator Optimization
   - `.claude/docs/concepts/hierarchical-agents-patterns.md` - Design patterns reference

3. **Related Specifications**:
   - `063_proof_automation_tactics_refactor` - Active /lean-plan execution showing research phase patterns
   - `004_lean_plan_context_coordinator` - Current optimization spec (this report's context)

---

## Appendix: Code Examples

### Example A: Hard Barrier Validation Template

```bash
# Block 1f-validate: Research Validation (Hard Barrier)

# Fail-fast if research directory missing
if [[ ! -d "$RESEARCH_DIR" ]]; then
  log_command_error "validation_error" \
    "Research directory not found: $RESEARCH_DIR" \
    "research-coordinator should have created this directory"
  echo "ERROR: Research validation failed"
  exit 1
fi

# Fail-fast if any pre-calculated report path missing
MISSING_REPORTS=()
for REPORT_PATH in "${REPORT_PATHS[@]}"; do
  if [[ ! -f "$REPORT_PATH" ]]; then
    MISSING_REPORTS+=("$REPORT_PATH")
  fi
done

if [[ ${#MISSING_REPORTS[@]} -gt 0 ]]; then
  log_command_error "validation_error" \
    "${#MISSING_REPORTS[@]} research reports missing" \
    "Missing: ${MISSING_REPORTS[*]}"
  exit 1
fi

echo "[CHECKPOINT] Research validated: ${#REPORT_PATHS[@]} reports created"
```

### Example B: Brief Summary Metadata Format

```markdown
report_type: lean_research
topic: "Mathlib Theorems"
findings_count: 12
recommendations_count: 5
mathlib_theorems_found: 8
proof_tactics_analyzed: 6
context_tokens: 2480

# Mathlib Theorems Research Report

## Executive Summary
[... full content follows ...]
```

### Example C: Context Estimation Implementation

```bash
estimate_research_context() {
  local completed_topics="$1"
  local remaining_topics="$2"

  # Defensive validation
  if ! [[ "$completed_topics" =~ ^[0-9]+$ ]]; then
    completed_topics=0
  fi
  if ! [[ "$remaining_topics" =~ ^[0-9]+$ ]]; then
    remaining_topics=1
  fi

  # Token cost estimates
  local base=15000  # System + coordinator logic
  local per_topic=2000  # Research overhead per topic
  local metadata_per_topic=110

  local completed_cost=$((completed_topics * (per_topic + metadata_per_topic)))
  local remaining_cost=$((remaining_topics * per_topic))

  local total=$((base + completed_cost + remaining_cost))

  # Percentage of 200k context window
  local percentage=$((total * 100 / 200000))

  echo "$percentage"
}
```

### Example D: Iteration Decision Logic

```bash
# Parse coordinator return signal
TOPICS_REMAINING=$(grep "^topics_remaining:" "$METADATA_FILE" | sed 's/^topics_remaining:[[:space:]]*//')
REQUIRES_CONTINUATION=$(grep "^requires_continuation:" "$METADATA_FILE" | sed 's/^requires_continuation:[[:space:]]*//')

# Check iteration limit
if [ "$REQUIRES_CONTINUATION" = "true" ] && [ "$ITERATION" -lt "$MAX_ITERATIONS" ]; then
  NEXT_ITERATION=$((ITERATION + 1))
  CONTINUATION_METADATA="${LEAN_PLAN_WORKSPACE}/iteration_${ITERATION}_metadata.json"
  cp "$AGGREGATED_METADATA_FILE" "$CONTINUATION_METADATA"

  append_workflow_state "ITERATION" "$NEXT_ITERATION"
  append_workflow_state "TOPICS_REMAINING" "$TOPICS_REMAINING"
  append_workflow_state "CONTINUATION_METADATA" "$CONTINUATION_METADATA"

  echo "Continuing to iteration $NEXT_ITERATION for remaining topics"
  exit 0  # HARD BARRIER: Resume at research invocation block
else
  echo "Research complete: $ITERATION iterations"
  append_workflow_state "RESEARCH_STATUS" "complete"
fi
```

---

**REPORT_CREATED**: /home/benjamin/.config/.claude/specs/004_lean_plan_context_coordinator/reports/003-lean-implement-pattern-analysis.md
