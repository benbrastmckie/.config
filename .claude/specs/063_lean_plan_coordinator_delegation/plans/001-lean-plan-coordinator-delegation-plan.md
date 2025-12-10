# Implementation: lean-plan Coordinator Library Extraction (Pattern A)

## Metadata
- **Date**: 2025-12-09 (Revised)
- **Feature**: Extract coordinator logic to library (Pattern A - Orchestrator Mode) with hard barrier pattern and /lean-implement compatibility validation
- **Status**: [ABANDONED]
- **Estimated Hours**: 10-14 hours
- **Complexity Score**: 38
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Primary Agent Usage Analysis](../reports/001-primary-agent-usage-analysis.md)
  - [Coordinator Research Delegation Patterns](../reports/002-coordinator-delegation-patterns.md)
  - [Planning Subagent Architecture Analysis](../reports/003-planning-subagent-architecture.md)
  - [Orchestrator vs Direct Invocation Patterns](../../066_pattern_tradeoff_comparison/reports/001-orchestrator-vs-direct-invocation-patterns.md)
  - [Pattern A Consistency Analysis](../reports/004-pattern-a-consistency-analysis.md)
  - [/lean-implement Compatibility Research](../reports/5-lean_implement_compatibility_research.md)

## Overview

The lean-plan command is bypassing hierarchical agent delegation entirely, executing all research and planning operations in the primary agent instead of delegating to research-coordinator and lean-plan-architect subagents. Research has confirmed that **nested Task invocation** (coordinator -> specialist) is architecturally problematic and should be avoided.

**Solution**: Implement **Pattern A (Orchestrator Mode)** - extract coordinator logic to a sourced library, allowing the primary agent to execute coordinator logic inline while invoking specialists directly via single-level Task calls.

**CRITICAL SCOPE BOUNDARIES** (prevents /lean-implement confusion):

**This plan modifies**:
- `/lean-plan` command ONLY - research coordination logic
- Creates new library: `.claude/lib/coordination/research-orchestrator.sh`

**This plan does NOT modify**:
- `/lean-implement` command - already working perfectly with implementer-coordinator
- `lean-coordinator.md` agent - wave-based orchestration unchanged
- `implementer-coordinator.md` agent - brief summary format unchanged

**Compatibility Guarantee**: All changes are isolated to lean-plan's research phase. The `/lean-implement` command will continue to work exactly as before with its proven implementer-coordinator delegation pattern.

**Pattern A Consistency** (aligned with Spec 065 - Lean Coordinator Wave Optimization):
- **Brief Summary Format**: Aggregation returns 80 tokens (metadata fields) not 2,000 tokens (full content)
- **Deterministic Logic**: No LLM reasoning in library functions - complexity directly maps to topic count
- **Sequential-by-Default**: Parallel specialist invocation requires explicit flag (fail-safe)

**Benefits**:
- **Eliminates nesting**: Reduces from 2 levels (primary -> coordinator -> specialist) to 1 level
- **Preserves coordinator logic**: All parallelization, error handling, and aggregation logic remains functional
- **Token efficiency**: No LLM tokens spent on coordinator reasoning - only specialist work
- **Deterministic execution**: Coordinator logic runs as code, not LLM interpretation
- **96% context reduction**: Brief summary format (80 tokens vs 2,000) aligns with lean-coordinator pattern

**Impact Resolution**:
- Context consumption: Reduced from ~15,000+ tokens to ~500 tokens per research phase
- Execution mode: Sequential by default, parallel when explicitly requested (complexity >= 3)
- Architecture: Coordinator logic preserved as reusable library

## Research Summary

Research confirmed that **Pattern A (Orchestrator Mode)** is the recommended approach based on industry patterns from Anthropic, Google ADK, Microsoft Azure, and other multi-agent frameworks.

**Key Research Findings** (Report: Orchestrator vs Direct Invocation):

1. **Pattern A Advantages**:
   - Preserves all coordinator orchestration logic
   - Eliminates nesting depth constraints
   - Deterministic code execution vs LLM interpretation
   - Lowest token overhead (no coordinator LLM reasoning)

2. **Industry Support**:
   - Google ADK's AgentTool Pattern: Parent agent inlines coordination logic
   - Anthropic's Lead Agent Pattern: Lead maintains control rather than delegating to intermediate subprocess
   - Microsoft's Magentic Manager: Coordinates specialized agents directly without deep nesting

3. **Decision Rationale**:
   - research-coordinator provides meaningful value (multi-topic decomposition, parallel invocation, result aggregation)
   - Pattern A preserves this value while eliminating nesting constraint
   - Pattern B (Direct Specialist) would lose orchestration logic and require reimplementation

**Pattern A Consistency Analysis** (Report: Pattern A Consistency):

1. **Brief Summary Format** (from Spec 065):
   - Summary files have metadata fields on lines 1-8 (80 tokens)
   - Full content follows metadata section
   - Orchestrator parses only metadata fields (96% context reduction)

2. **Deterministic Logic** (from Spec 065):
   - No runtime analysis - plan metadata is source of truth
   - Complexity level directly maps to behavior
   - Wave structure extracted from plan, not computed

3. **Sequential-by-Default** (from Spec 065):
   - Default behavior: sequential execution (one phase per wave)
   - Parallel execution requires explicit indicator (parallel_wave: true + wave_id)
   - Missing metadata defaults to sequential (fail-safe)

**Architecture Decision**: Proceed with Pattern A - extract coordinator logic to `.claude/lib/coordination/research-orchestrator.sh` with all three consistency patterns applied.

## Success Criteria

- [ ] Research orchestrator library created: `.claude/lib/coordination/research-orchestrator.sh`
- [ ] Library contains deterministic topic decomposition (complexity -> topic count mapping)
- [ ] Library implements brief summary aggregation (80 tokens target, metadata on lines 1-8)
- [ ] Library defaults to sequential specialist invocation (parallel requires explicit flag)
- [ ] lean-plan command updated to use 3-block hard barrier pattern (Setup → Execute → Verify)
- [ ] State machine integration with fail-fast validation (aligned with /implement)
- [ ] Pre-calculated report paths before specialist invocation (hard barrier requirement)
- [ ] Hard barrier validation with exit 1 on missing reports
- [ ] Structured error logging for all validation failures
- [ ] Single-level Task invocations working (primary -> specialist)
- [ ] Checkpoint support for partial research completion
- [ ] Architecture Decision Record (ADR) created documenting Pattern A adoption
- [ ] lean-plan-output.md shows successful specialist delegation when re-executed
- [ ] Context consumption reduced from ~15k tokens to ~500 tokens
- [ ] **CRITICAL: /lean-implement still works after lean-plan changes (no regression)**
- [ ] implementer-coordinator brief summary format unchanged
- [ ] Wave-based orchestration validated in /lean-implement
- [ ] Scope boundaries validated: NO changes to /lean-implement, lean-coordinator, implementer-coordinator

## Technical Design

### Pattern A Implementation Architecture

**Library Structure**: `.claude/lib/coordination/research-orchestrator.sh`
```bash
#!/usr/bin/env bash
# research-orchestrator.sh - Pattern A Implementation
# Version: 1.0.0
# Extracted from research-coordinator.md for inline execution
# Eliminates nested Task invocation while preserving orchestration logic
#
# Pattern A Consistency (aligned with Spec 065):
# - Brief summary format (80 tokens metadata output)
# - Deterministic topic decomposition (no LLM reasoning)
# - Sequential-by-default execution (parallel requires explicit flag)

# Dependency: error-handling.sh for logging
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || true

# Deterministic topic decomposition based on complexity level
# Complexity 1-2: 2-3 topics | Complexity 3-4: 4-5 topics
decompose_research_topics() {
  local feature="$1"
  local complexity="$2"

  # Deterministic mapping - no LLM reasoning
  local topic_count
  case "$complexity" in
    1) topic_count=2 ;;
    2) topic_count=3 ;;
    3) topic_count=4 ;;
    4) topic_count=5 ;;
    *) topic_count=3 ;;  # Default
  esac

  # Fixed topic categories (deterministic)
  local topics=()
  topics+=("Implementation patterns for: $feature")
  topics+=("Best practices and standards for: $feature")
  [ "$topic_count" -ge 3 ] && topics+=("Architecture considerations for: $feature")
  [ "$topic_count" -ge 4 ] && topics+=("Testing strategy for: $feature")
  [ "$topic_count" -ge 5 ] && topics+=("Integration requirements for: $feature")

  # Return newline-separated topics
  printf '%s\n' "${topics[@]:0:$topic_count}"
}

# Generates specialist Task invocation prompts
generate_specialist_prompts() {
  local topics="$1"
  local report_dir="$2"
  local index=1

  while IFS= read -r topic; do
    [ -z "$topic" ] && continue
    local report_path="${report_dir}/${index}-$(echo "$topic" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | cut -c1-30).md"

    cat <<EOF
{
  "topic": "$topic",
  "report_path": "$report_path",
  "index": $index
}
EOF
    index=$((index + 1))
  done <<< "$topics"
}

# Brief summary aggregation (80 tokens target - Pattern A consistency)
aggregate_research_results() {
  local report_dir="$1"

  # Count reports
  local report_count=$(find "$report_dir" -name "*.md" -type f 2>/dev/null | wc -l)

  # Validate all reports exist and are non-empty
  local valid_count=0
  local report_summaries=""
  for report in "$report_dir"/*.md; do
    [ -f "$report" ] || continue
    local size=$(wc -c < "$report" 2>/dev/null || echo 0)
    if [ "$size" -gt 100 ]; then
      valid_count=$((valid_count + 1))
      # Extract first line of Executive Summary (brief)
      local brief=$(sed -n '/^## Executive Summary/,/^##/p' "$report" | head -5 | tail -3 | tr '\n' ' ' | cut -c1-50)
      report_summaries="${report_summaries}${brief}; "
    fi
  done

  # Return brief metadata format (80 tokens target)
  echo "coordinator_type: research"
  echo "summary_brief: \"Completed ${valid_count}/${report_count} research reports. ${report_summaries:0:80}\""
  echo "reports_completed: [$(seq -s, 1 $valid_count)]"
  echo "reports_total: $report_count"
  echo "research_status: $([ "$valid_count" -eq "$report_count" ] && echo 'complete' || echo 'partial')"
  echo "report_dir: $report_dir"
}

# Main orchestration function with sequential-by-default pattern
orchestrate_research() {
  local feature="$1"
  local complexity="$2"
  local report_dir="$3"
  local parallel="${4:-false}"  # Default: sequential (Pattern A consistency)

  # Validate parallel mode (only for complexity >= 3)
  if [ "$parallel" = "true" ] && [ "$complexity" -lt 3 ]; then
    echo "WARNING: Parallel mode requested but complexity < 3. Defaulting to sequential." >&2
    parallel="false"
  fi

  # 1. Decompose topics (deterministic)
  local topics=$(decompose_research_topics "$feature" "$complexity")

  # 2. Generate prompts (returned for Task invocation by caller)
  local prompts=$(generate_specialist_prompts "$topics" "$report_dir")

  # Return execution metadata
  echo "execution_mode: $parallel"
  echo "topic_count: $(echo "$topics" | grep -c .)"
  echo "prompts:"
  echo "$prompts"
}

# Checkpoint support for partial research completion (Pattern A consistency)
save_research_checkpoint() {
  local checkpoint_dir="$1"
  local workflow_id="$2"
  local report_dir="$3"
  local completed_topics="$4"
  local remaining_topics="$5"

  mkdir -p "$checkpoint_dir"
  local checkpoint_file="${checkpoint_dir}/research_${workflow_id}_$(date +%Y%m%d_%H%M%S).json"

  cat > "$checkpoint_file" <<EOF
{
  "version": "1.0",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "workflow_id": "$workflow_id",
  "report_dir": "$report_dir",
  "completed_topics": $completed_topics,
  "remaining_topics": $remaining_topics,
  "checkpoint_reason": "partial_completion"
}
EOF

  echo "$checkpoint_file"
}
```

**lean-plan Integration Pattern** (3-block hard barrier pattern from /implement):

**Block 1a: Research Phase Setup**
```bash
# State transition with fail-fast validation (aligned with /implement)
sm_transition "$STATE_RESEARCH" "plan loaded, starting research" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to RESEARCH failed" \
    "bash_block_1a" \
    "$(jq -n --arg state "RESEARCH" '{target_state: $state}')"

  echo "ERROR: State transition to RESEARCH failed" >&2
  exit 1
fi

# Pre-calculate report paths (hard barrier requirement)
REPORT_PATHS=()
for i in $(seq 1 $TOPIC_COUNT); do
  REPORT_PATHS+=("${REPORT_DIR}/${i}-topic.md")
done

append_workflow_state "REPORT_PATHS" "${REPORT_PATHS[@]}"
echo "[CHECKPOINT] Research setup: $TOPIC_COUNT topics, ${#REPORT_PATHS[@]} report paths pre-calculated"
```

**Block 1e: Research Orchestration (Pattern A - Orchestrator Mode)**
```bash
# Source orchestrator library (Pattern A)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/coordination/research-orchestrator.sh" 2>/dev/null || {
  echo "ERROR: Failed to source research-orchestrator library" >&2
  exit 1
}

# Orchestrator generates specialist prompts inline (deterministic)
ORCHESTRATION_OUTPUT=$(orchestrate_research "$FEATURE_DESCRIPTION" "$RESEARCH_COMPLEXITY" "$REPORT_DIR" "false")

# Parse execution mode (sequential by default)
EXECUTION_MODE=$(echo "$ORCHESTRATION_OUTPUT" | grep "^execution_mode:" | cut -d' ' -f2)
TOPIC_COUNT=$(echo "$ORCHESTRATION_OUTPUT" | grep "^topic_count:" | cut -d' ' -f2)

echo "[CHECKPOINT] Research orchestration: $TOPIC_COUNT topics, mode: $EXECUTION_MODE"

# Store prompts for Task invocation block
append_workflow_state "SPECIALIST_PROMPTS" "$(echo "$ORCHESTRATION_OUTPUT" | sed -n '/^prompts:/,$p' | tail -n +2)"
```

**Block 1f: Research Verification (Hard Barrier)**
```bash
# Validate all pre-calculated report paths exist (fail-fast)
MISSING_REPORTS=()
for REPORT_PATH in "${REPORT_PATHS[@]}"; do
  if [[ ! -f "$REPORT_PATH" ]]; then
    MISSING_REPORTS+=("$REPORT_PATH")
  fi
done

if [[ ${#MISSING_REPORTS[@]} -gt 0 ]]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "${#MISSING_REPORTS[@]} research reports missing after specialist invocation" \
    "bash_block_1f" \
    "$(jq -n --argjson missing "$(printf '%s\n' "${MISSING_REPORTS[@]}" | jq -R . | jq -s .)" \
       '{missing_reports: $missing}')"

  echo "ERROR: Research verification failed - ${#MISSING_REPORTS[@]} reports missing"
  echo "Missing reports: ${MISSING_REPORTS[*]}"
  exit 1
fi

# Parse brief summary metadata (96% context reduction)
AGGREGATION=$(aggregate_research_results "$REPORT_DIR")
RESEARCH_STATUS=$(echo "$AGGREGATION" | grep "^research_status:" | cut -d' ' -f2)
REPORTS_COMPLETED=$(echo "$AGGREGATION" | grep "^reports_completed:" | cut -d' ' -f2)

echo "[CHECKPOINT] Research verification: status=$RESEARCH_STATUS, completed=$REPORTS_COMPLETED"
```

### Validation Strategy

**Library Function Testing**:
```bash
# Source orchestrator library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/coordination/research-orchestrator.sh"

# Unit test: deterministic topic decomposition
TOPICS_C1=$(decompose_research_topics "implement JWT auth" "1")
TOPICS_C4=$(decompose_research_topics "implement JWT auth" "4")
[ "$(echo "$TOPICS_C1" | wc -l)" -eq 2 ] && echo "OK: Complexity 1 = 2 topics" || echo "FAIL"
[ "$(echo "$TOPICS_C4" | wc -l)" -eq 5 ] && echo "OK: Complexity 4 = 5 topics" || echo "FAIL"

# Unit test: prompt generation
PROMPTS=$(generate_specialist_prompts "$TOPICS_C1" "/tmp/test-reports")
[ -n "$PROMPTS" ] && echo "OK: generate_specialist_prompts" || echo "FAIL"

# Unit test: brief summary format (80 tokens target)
mkdir -p /tmp/test-reports
echo "## Executive Summary\nTest content here" > /tmp/test-reports/1-test.md
AGGREGATION=$(aggregate_research_results "/tmp/test-reports")
echo "$AGGREGATION" | grep -q "^coordinator_type: research" && echo "OK: Brief format" || echo "FAIL"
echo "$AGGREGATION" | grep -q "^summary_brief:" && echo "OK: summary_brief field" || echo "FAIL"

# Unit test: sequential-by-default
ORCH_SEQ=$(orchestrate_research "test" "2" "/tmp" "true")  # Parallel requested but complexity=2
echo "$ORCH_SEQ" | grep -q "execution_mode: false" && echo "OK: Sequential default for low complexity" || echo "FAIL"
```

**Specialist Invocation Checkpoints**:
```bash
# After each specialist Task invocation
if [ ! -f "${REPORT_DIR}/report_${TOPIC_INDEX}.md" ]; then
  echo "ERROR: research-specialist Task did not create report"
  echo "Expected: ${REPORT_DIR}/report_${TOPIC_INDEX}.md"

  # Save checkpoint for partial completion
  save_research_checkpoint "$CHECKPOINT_DIR" "$WORKFLOW_ID" "$REPORT_DIR" "$COMPLETED" "$REMAINING"
  exit 1
fi
echo "[CHECKPOINT] Specialist ${TOPIC_INDEX} completed"
```

**Brief Summary Validation**:
```bash
# After aggregate_research_results
AGGREGATION=$(aggregate_research_results "$REPORT_DIR")
TOKEN_ESTIMATE=$(echo "$AGGREGATION" | wc -w)

if [ "$TOKEN_ESTIMATE" -gt 100 ]; then
  echo "WARNING: Brief summary exceeds 100 tokens ($TOKEN_ESTIMATE)" >&2
fi

echo "[CHECKPOINT] Research aggregation: $(echo "$AGGREGATION" | grep "^research_status:" | cut -d' ' -f2)"
```

## Implementation Phases

### Phase 1: Research Orchestrator Library Creation [NOT STARTED]
dependencies: []

**Objective**: Extract coordinator logic from research-coordinator.md into a reusable bash library with Pattern A consistency applied.

**Complexity**: Medium

**Tasks**:
- [ ] Analyze research-coordinator.md to identify extractable logic
- [ ] Create library directory: `.claude/lib/coordination/`
- [ ] Create library file: `.claude/lib/coordination/research-orchestrator.sh`
- [ ] Implement `decompose_research_topics()` - deterministic topic splitting based on complexity
- [ ] Implement `generate_specialist_prompts()` - creates Task prompts for specialists
- [ ] Implement `aggregate_research_results()` - brief summary format (80 tokens target)
- [ ] Implement `orchestrate_research()` - sequential-by-default main entry point
- [ ] Implement `save_research_checkpoint()` - checkpoint support for partial completion
- [ ] Add library header with version and dependency information
- [ ] Add inline documentation for each function
- [ ] Create unit tests for deterministic behavior validation

**Pattern A Consistency Checklist**:
- [ ] `decompose_research_topics()` is deterministic (complexity -> topic count mapping)
- [ ] `aggregate_research_results()` returns brief metadata (80 tokens target)
- [ ] `orchestrate_research()` defaults to sequential (parallel requires explicit flag)
- [ ] No LLM reasoning in any library function

**Expected Duration**: 3 hours

**Success Criteria**:
- [ ] Library file created with all five functions
- [ ] Functions source successfully without errors
- [ ] Unit tests pass for each function (see Validation Strategy)
- [ ] Library follows three-tier sourcing pattern
- [ ] Brief summary format validated (< 100 tokens)

### Phase 2: lean-plan Command Integration with Hard Barrier Pattern [NOT STARTED]
dependencies: [1]

**Objective**: Update lean-plan.md to use 3-block hard barrier pattern (Setup → Execute → Verify) aligned with /implement success patterns.

**Complexity**: Medium

**Tasks**:
- [ ] Read lean-plan.md Block 1e structure (research coordination)
- [ ] Implement Block 1a: Research Phase Setup with state machine integration
- [ ] Add fail-fast state transition validation with structured error logging
- [ ] Pre-calculate all report paths before specialist invocation (hard barrier requirement)
- [ ] Replace research-coordinator Task invocation with library sourcing in Block 1e
- [ ] Update Block 1e to call `orchestrate_research()` for topic decomposition
- [ ] Implement sequential specialist invocation loop (default behavior)
- [ ] Add parallel execution mode with explicit flag (complexity >= 3 only)
- [ ] Implement Block 1f: Research Verification with hard barrier validation
- [ ] Add brief summary parsing after aggregation (80 tokens metadata)
- [ ] Verify lean-plan-architect invocation in Block 2b (single-level, should work)
- [ ] Test updated lean-plan with simple feature description

**3-Block Hard Barrier Pattern** (aligned with /implement):
```bash
# Block 1a: Research Phase Setup (state transition + path pre-calculation)
sm_transition "$STATE_RESEARCH" "plan loaded, starting research" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "state_error" "State transition to RESEARCH failed" "bash_block_1a" \
    "$(jq -n --arg state "RESEARCH" '{target_state: $state}')"
  exit 1
fi

# Pre-calculate report paths (mandatory for hard barrier)
REPORT_PATHS=()
for i in $(seq 1 $TOPIC_COUNT); do
  REPORT_PATHS+=("${REPORT_DIR}/${i}-topic.md")
done

# Block 1e: Research Orchestration (Pattern A - inline coordination)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/coordination/research-orchestrator.sh" 2>/dev/null || {
  echo "ERROR: Failed to source research-orchestrator library" >&2
  exit 1
}
ORCHESTRATION=$(orchestrate_research "$FEATURE_DESCRIPTION" "$RESEARCH_COMPLEXITY" "$REPORT_DIR" "false")

# Block 1f: Research Verification (hard barrier - fail-fast on missing reports)
MISSING_REPORTS=()
for REPORT_PATH in "${REPORT_PATHS[@]}"; do
  [[ ! -f "$REPORT_PATH" ]] && MISSING_REPORTS+=("$REPORT_PATH")
done

if [[ ${#MISSING_REPORTS[@]} -gt 0 ]]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" "${#MISSING_REPORTS[@]} research reports missing" "bash_block_1f" \
    "$(jq -n --argjson missing "$(printf '%s\n' "${MISSING_REPORTS[@]}" | jq -R . | jq -s .)" '{missing_reports: $missing}')"
  exit 1
fi
```

**Expected Duration**: 3 hours (increased for hard barrier implementation)

**Success Criteria**:
- [ ] lean-plan uses 3-block pattern (Setup → Execute → Verify)
- [ ] State machine integration with fail-fast validation
- [ ] Report paths pre-calculated before specialist invocation
- [ ] Hard barrier validation catches missing reports (exit 1)
- [ ] Structured error logging for all failure points
- [ ] Topic decomposition executes inline (no coordinator Task)
- [ ] Specialist Task invocations generated correctly
- [ ] Sequential execution by default (parallel only when flag set)
- [ ] lean-plan-architect invocation unchanged (single-level)

### Phase 3: Specialist Task Invocation and Validation [NOT STARTED]
dependencies: [2]

**Objective**: Implement the specialist Task invocation loop with sequential-by-default and hard barrier validation.

**Complexity**: Medium

**Tasks**:
- [ ] Create Block 1e-exec with specialist Task invocations
- [ ] Implement sequential Task invocation loop (default behavior)
- [ ] Add optional parallel Task invocation pattern (complexity >= 3 with flag)
- [ ] Add specialist completion checkpoints after each Task
- [ ] Implement `aggregate_research_results()` call after specialists complete
- [ ] Validate brief summary format (80 tokens target)
- [ ] Add hard barrier validation for report files
- [ ] Add checkpoint saving for partial completion scenarios
- [ ] Test with complexity 2 (sequential, 3 topics)
- [ ] Test with complexity 4 (optional parallel, 5 topics)

**Sequential Specialist Invocation Block** (default):
```markdown
## Block 1e-exec: Research Specialist Invocation [CRITICAL BARRIER]

**EXECUTE NOW**: USE the Task tool to invoke research specialists SEQUENTIALLY (default behavior).

For each specialist prompt in SPECIALIST_PROMPTS (one at a time):

Task {
  subagent_type: "general-purpose"
  description: "Research specialist for: ${TOPIC}"
  prompt: "${SPECIALIST_PROMPT}"
}

# Wait for completion before next specialist
# This is the sequential-by-default pattern (Pattern A consistency)
```

**Parallel Mode Block** (complexity >= 3 with flag):
```markdown
## Block 1e-exec-parallel: Research Specialist Invocation [OPTIONAL]

**EXECUTE NOW**: USE the Task tool to invoke research specialists IN PARALLEL.

Note: Only used when EXECUTION_MODE=true AND COMPLEXITY >= 3

Invoke all specialists in parallel by including multiple Task invocations in a single response.
```

**Expected Duration**: 3 hours (increased for checkpoint implementation)

**Success Criteria**:
- [ ] Specialists invoke via single-level Task (no nesting)
- [ ] Sequential invocation works by default (one at a time)
- [ ] Parallel invocation available for complexity >= 3 with flag
- [ ] Reports created at expected paths (pre-calculated paths validated)
- [ ] Hard barrier validation catches missing reports (fail-fast)
- [ ] Structured error logging for all validation failures
- [ ] Checkpoint saved on partial completion
- [ ] Checkpoint support validated with resumption test
- [ ] Brief summary format validated (< 100 tokens)

### Phase 4: Architecture Documentation and /lean-implement Compatibility Testing [NOT STARTED]
dependencies: [3]

**Objective**: Document Pattern A adoption, validate /lean-implement still works, and confirm no regression in proven delegation patterns.

**Complexity**: Medium (increased for compatibility testing)

**Tasks**:
- [ ] Create ADR: `.claude/docs/architecture/adr/002-orchestrator-mode-adoption.md`
- [ ] Document Pattern A decision rationale and tradeoffs
- [ ] Document Pattern A consistency with Spec 065 (brief summary, deterministic, sequential-default)
- [ ] Document scope boundaries (lean-plan ONLY, NOT lean-implement)
- [ ] Update hierarchical-agents-examples.md with Pattern A example
- [ ] Update research-coordinator.md with library extraction note
- [ ] Re-execute lean-plan with test feature (complexity 2 - sequential)
- [ ] Re-execute lean-plan with test feature (complexity 4 - parallel mode)
- [ ] Validate context consumption reduced (~500 tokens target)
- [ ] Measure execution time improvement (compare sequential vs parallel)
- [ ] **CRITICAL: Test /lean-implement compatibility** (prove no regression)
- [ ] Execute /lean-implement on existing Lean plan (verify delegation still works)
- [ ] Validate implementer-coordinator brief summary format unchanged
- [ ] Confirm wave-based orchestration still functions correctly
- [ ] Validate lean-coordinator agent still works with /lean-implement
- [ ] Update CHANGELOG.md with Pattern A implementation

**ADR Content**:
```markdown
# ADR 002: Orchestrator Mode (Pattern A) Adoption

## Status
Accepted

## Context
Nested Task invocation (coordinator -> specialist) proved problematic in command execution.
Research into industry patterns (Anthropic, Google ADK, Microsoft) confirmed orchestrator mode
as a valid alternative that preserves coordination logic.

## Scope
**This ADR applies to /lean-plan ONLY**. The /lean-implement command is NOT modified and
continues to use implementer-coordinator delegation successfully.

## Decision
Adopt Pattern A (Orchestrator Mode) with consistency across all implementations:
- Extract coordinator logic to `.claude/lib/coordination/research-orchestrator.sh`
- Commands source library and execute coordination logic inline
- Specialists invoked via single-level Task (no nesting)
- Use 3-block hard barrier pattern (Setup → Execute → Verify) aligned with /implement

Pattern A Consistency (aligned with Spec 065 - Lean Coordinator Wave Optimization):
1. Brief Summary Format: Aggregation returns 80 tokens (metadata fields)
2. Deterministic Logic: No LLM reasoning in library functions
3. Sequential-by-Default: Parallel execution requires explicit flag
4. Hard Barrier Validation: Pre-calculated paths, fail-fast on missing artifacts
5. State Machine Integration: Fail-fast state transitions with error logging

## Consequences
- Eliminates nested Task constraint
- Preserves all orchestration logic (parallelization, aggregation)
- Reduces token overhead (no coordinator LLM reasoning)
- Requires library extraction for coordinators
- Consistent patterns across lean-coordinator and research-orchestrator
- Aligns with /implement reliability patterns (hard barrier, state machine, error logging)
- **NO impact on /lean-implement** - changes isolated to lean-plan research phase

## Compatibility
- /lean-implement continues to work unchanged (implementer-coordinator delegation preserved)
- lean-coordinator agent unchanged (wave-based orchestration preserved)
- implementer-coordinator agent unchanged (brief summary format preserved)

## Alternatives Rejected
- Pattern B (Direct Specialist): Loses orchestration logic, code duplication
- Nested Task Fix: Architectural constraint, not implementation bug
```

**Expected Duration**: 3 hours (increased for /lean-implement compatibility testing)

**Success Criteria**:
- [ ] ADR created documenting Pattern A adoption with consistency notes
- [ ] Scope boundaries documented (lean-plan ONLY, NOT lean-implement)
- [ ] Documentation updated across affected files
- [ ] lean-plan re-execution shows specialist Task invocations
- [ ] Sequential execution works (default)
- [ ] Parallel execution works (complexity >= 3 with flag)
- [ ] Context consumption reduced to ~500 tokens
- [ ] Brief summary format validated
- [ ] **CRITICAL: /lean-implement still works after lean-plan changes**
- [ ] implementer-coordinator brief summary format unchanged
- [ ] Wave-based orchestration validated in /lean-implement
- [ ] lean-coordinator agent functionality confirmed
- [ ] No regression in proven /lean-implement delegation patterns
- [ ] CHANGELOG.md entry added

## Testing Strategy

**Unit Testing**:
- Library function tests: `decompose_research_topics`, `generate_specialist_prompts`, `aggregate_research_results`
- Deterministic behavior validation: Same inputs always produce same outputs
- Brief summary format validation: Output < 100 tokens
- Sequential-by-default validation: Parallel mode rejected for complexity < 3
- Sourcing validation: Library sources without errors
- Error handling: Functions return proper error codes on invalid input
- State machine integration: Fail-fast validation catches invalid state transitions

**Integration Testing**:
- Phase 2: lean-plan library integration test (sources and executes inline)
- Phase 2: Hard barrier validation test (missing reports cause exit 1)
- Phase 2: State machine integration test (fail-fast on state errors)
- Phase 3: Specialist invocation test (sequential and parallel modes)
- Phase 3: Checkpoint save/resume test (partial completion scenarios)
- Phase 4: Full lean-plan execution with Pattern A
- Phase 4: **CRITICAL: /lean-implement compatibility test** (no regression)

**Validation Metrics**:
- Library function return codes (0 = success)
- Deterministic output validation (same input -> same output)
- Specialist Task invocation count in output (>0 expected)
- Brief summary token count (< 100 tokens target)
- Context token consumption (~500 tokens target, down from ~15k)
- Execution time comparison (sequential vs parallel for complexity 4)
- Report artifact creation at expected paths
- Hard barrier validation: exit 1 on missing reports
- State transition success rate (100% expected)
- **CRITICAL: /lean-implement delegation success rate** (100% expected, no regression)

**Pattern A Consistency Validation**:
- Brief summary format matches lean-coordinator pattern (metadata on lines 1-8)
- Topic decomposition is deterministic (no LLM reasoning)
- Sequential execution by default (parallel requires explicit flag)

**/lean-implement Compatibility Validation** (CRITICAL - prevents regression):
- Execute /lean-implement on existing Lean plan (verify coordinator delegation works)
- Validate implementer-coordinator brief summary format unchanged (80 tokens metadata)
- Confirm wave-based orchestration functions correctly (parallel phase execution)
- Validate lean-coordinator agent brief summary parsing works
- Confirm no changes to /lean-implement command file (scope verification)
- Confirm no changes to lean-coordinator.md agent file (scope verification)
- Confirm no changes to implementer-coordinator.md agent file (scope verification)

**Test Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["research-orchestrator.sh", "research reports", "adr-002-orchestrator-mode-adoption.md", "brief-summary-samples.txt", "lean-implement-compatibility-report.md"]

## Documentation Requirements

**New Documentation**:
- ADR 002: Orchestrator Mode (Pattern A) Adoption (with consistency notes)
- Orchestrator library: `.claude/lib/coordination/research-orchestrator.sh`
- Library README: `.claude/lib/coordination/README.md`

**Updated Documentation**:
- `.claude/docs/concepts/hierarchical-agents-examples.md` - Add Pattern A orchestrator example with consistency notes
- `.claude/docs/concepts/hierarchical-agents-coordination.md` - Document library extraction pattern
- `.claude/agents/research-coordinator.md` - Note library extraction for inline mode
- `.claude/commands/lean-plan.md` - Update research phase to use orchestrator library
- `CHANGELOG.md` - Document Pattern A implementation with consistency

## Dependencies

**External Dependencies**:
- Bash shell for library execution
- jq for JSON processing in library functions
- File system for report validation

**Internal Dependencies**:
- research-coordinator.md (source of extracted logic)
- lean-plan.md command file (integration target)
- error-handling.sh (logging support)
- state-persistence.sh (workflow state)
- Research reports (inform implementation details)
- Spec 065 implementation (Pattern A consistency reference)

**Prerequisite Knowledge**:
- Hierarchical agent architecture patterns
- Hard barrier pattern implementation
- Bash library authoring conventions
- Three-tier sourcing pattern
- Brief summary format (from Spec 065)

## Risk Mitigation

**Risk 1: Library Extraction Incomplete**
- Mitigation: Thorough analysis of research-coordinator.md before extraction
- Validation: Unit tests for each extracted function
- Rollback: Original research-coordinator.md preserved, can revert lean-plan

**Risk 2: Single-Level Task Still Fails**
- Mitigation: Phase 3 tests specialist Task invocations in isolation
- Contingency: If single-level Task fails, escalate as fundamental issue
- Impact: Would require deeper investigation of Task directive execution

**Risk 3: Integration Breaks lean-plan**
- Mitigation: Backup lean-plan.md before modification
- Validation: Test with simple feature description before complex scenarios
- Rollback: Restore from backup if integration fails

**Risk 4: Performance Regression**
- Mitigation: Measure context consumption and execution time
- Acceptance: Target ~500 tokens (97% reduction from ~15k)
- Success Metric: Sequential execution works, parallel available for complex scenarios

**Risk 5: Brief Summary Format Too Verbose**
- Mitigation: Validate aggregation output < 100 tokens
- Contingency: Further truncate summary_brief field if needed
- Success Metric: Consistent with lean-coordinator brief format (80 tokens)

## Notes

**CRITICAL SCOPE BOUNDARIES**:
This plan modifies `/lean-plan` ONLY. The following are NOT modified:
- `/lean-implement` command - continues to work with implementer-coordinator delegation
- `lean-coordinator.md` agent - wave-based orchestration unchanged
- `implementer-coordinator.md` agent - brief summary format unchanged

**Compatibility Guarantee**: All changes are isolated to lean-plan's research phase. The `/lean-implement` command's proven delegation patterns remain intact and functional.

**Architecture Impact**: Pattern A adoption establishes a consistent pattern for coordinator agents. The library extraction approach can be applied to other coordinators:
- research-coordinator -> research-orchestrator.sh (this plan)
- implementer-coordinator -> already working (Spec 065, no changes needed)
- lean-coordinator -> already optimized (Spec 065, no changes needed)

**Pattern A Consistency**: This plan is aligned with Spec 065 (Lean Coordinator Wave Optimization) which established:
1. Brief summary format (80 tokens metadata)
2. Deterministic logic (no runtime analysis)
3. Sequential-by-default execution
4. Hard barrier validation (from /implement)
5. State machine integration (from /implement)

These patterns are now applied uniformly to research-orchestrator.sh.

**Migration Path**: Phased rollout for Pattern A adoption:
1. **Phase 1**: lean-plan with research-orchestrator.sh (this plan)
2. **Phase 2**: /create-plan, /research using same library
3. **Phase 3**: Evaluate other coordinators for extraction (if needed)

**Library Reuse**: The research-orchestrator.sh library can be shared across multiple commands:
- lean-plan (primary target)
- create-plan (research phase)
- research (standalone research)
- Any command needing multi-topic research orchestration

**/lean-implement Compatibility Commitment**: Phase 4 includes mandatory compatibility testing to prove no regression in /lean-implement delegation patterns. This includes:
- Executing /lean-implement on existing Lean plan
- Validating implementer-coordinator brief summary format unchanged
- Confirming wave-based orchestration still functions
- Verifying NO changes to /lean-implement, lean-coordinator, implementer-coordinator files

**Future Enhancement**: Consider implementing lean-plan-architect as a library if single-level Task continues to have issues. Current plan assumes single-level Task works correctly (depth 1 only).
