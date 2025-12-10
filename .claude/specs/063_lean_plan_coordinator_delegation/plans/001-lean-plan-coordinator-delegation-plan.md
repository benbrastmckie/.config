# Implementation: lean-plan Coordinator Library Extraction (Pattern A)

## Metadata
- **Date**: 2025-12-09 (Revised)
- **Feature**: Extract coordinator logic to library (Pattern A - Orchestrator Mode) with brief summary format and sequential-by-default execution
- **Status**: [NOT STARTED]
- **Estimated Hours**: 8-12 hours
- **Complexity Score**: 38
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Primary Agent Usage Analysis](../reports/001-primary-agent-usage-analysis.md)
  - [Coordinator Research Delegation Patterns](../reports/002-coordinator-delegation-patterns.md)
  - [Planning Subagent Architecture Analysis](../reports/003-planning-subagent-architecture.md)
  - [Orchestrator vs Direct Invocation Patterns](../../066_pattern_tradeoff_comparison/reports/001-orchestrator-vs-direct-invocation-patterns.md)
  - [Pattern A Consistency Analysis](../reports/004-pattern-a-consistency-analysis.md)

## Overview

The lean-plan command is bypassing hierarchical agent delegation entirely, executing all research and planning operations in the primary agent instead of delegating to research-coordinator and lean-plan-architect subagents. Research has confirmed that **nested Task invocation** (coordinator -> specialist) is architecturally problematic and should be avoided.

**Solution**: Implement **Pattern A (Orchestrator Mode)** - extract coordinator logic to a sourced library, allowing the primary agent to execute coordinator logic inline while invoking specialists directly via single-level Task calls.

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
- [ ] lean-plan command updated to source library and execute specialists directly
- [ ] Single-level Task invocations working (primary -> specialist)
- [ ] Delegation checkpoints implemented with trace file validation
- [ ] Checkpoint support for partial research completion
- [ ] Architecture Decision Record (ADR) created documenting Pattern A adoption
- [ ] lean-plan-output.md shows successful specialist delegation when re-executed
- [ ] Context consumption reduced from ~15k tokens to ~500 tokens

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

**lean-plan Integration Pattern**:
```bash
# Block 1e: Research Phase (Pattern A - Orchestrator Mode)
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

### Phase 2: lean-plan Command Integration [NOT STARTED]
dependencies: [1]

**Objective**: Update lean-plan.md to source the orchestrator library and invoke specialists directly with sequential-by-default behavior.

**Complexity**: Medium

**Tasks**:
- [ ] Read lean-plan.md Block 1e structure (research coordination)
- [ ] Replace research-coordinator Task invocation with library sourcing
- [ ] Update Block 1e to call `orchestrate_research()` for topic decomposition
- [ ] Implement sequential specialist invocation loop (default behavior)
- [ ] Add parallel execution mode with explicit flag (complexity >= 3 only)
- [ ] Update Block 1e verification to check specialist reports (not coordinator trace)
- [ ] Add brief summary parsing after aggregation (80 tokens)
- [ ] Verify lean-plan-architect invocation in Block 2b (single-level, should work)
- [ ] Test updated lean-plan with simple feature description

**Updated Block 1e Pattern**:
```bash
# Block 1e: Research Phase (Pattern A - Orchestrator Mode)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/coordination/research-orchestrator.sh" 2>/dev/null || {
  echo "ERROR: Failed to source research-orchestrator library" >&2
  exit 1
}

# Decompose topics and generate specialist prompts (deterministic)
ORCHESTRATION=$(orchestrate_research "$FEATURE_DESCRIPTION" "$RESEARCH_COMPLEXITY" "$REPORT_DIR" "false")

# Parse execution mode
EXECUTION_MODE=$(echo "$ORCHESTRATION" | grep "^execution_mode:" | cut -d' ' -f2)
TOPIC_COUNT=$(echo "$ORCHESTRATION" | grep "^topic_count:" | cut -d' ' -f2)

echo "[CHECKPOINT] Orchestration complete: $TOPIC_COUNT specialists, mode: $EXECUTION_MODE"

# Store prompts for Task invocation block
append_workflow_state "SPECIALIST_PROMPTS" "$(echo "$ORCHESTRATION" | sed -n '/^prompts:/,$p' | tail -n +2)"
```

**Expected Duration**: 2.5 hours

**Success Criteria**:
- [ ] lean-plan sources orchestrator library successfully
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

**Expected Duration**: 2.5 hours

**Success Criteria**:
- [ ] Specialists invoke via single-level Task (no nesting)
- [ ] Sequential invocation works by default (one at a time)
- [ ] Parallel invocation available for complexity >= 3 with flag
- [ ] Reports created at expected paths
- [ ] Hard barrier validation catches missing reports
- [ ] Checkpoint saved on partial completion
- [ ] Brief summary format validated (< 100 tokens)

### Phase 4: Architecture Documentation and Testing [NOT STARTED]
dependencies: [3]

**Objective**: Document Pattern A adoption with consistency notes, create ADR, and validate end-to-end.

**Complexity**: Low

**Tasks**:
- [ ] Create ADR: `.claude/docs/architecture/adr/002-orchestrator-mode-adoption.md`
- [ ] Document Pattern A decision rationale and tradeoffs
- [ ] Document Pattern A consistency with Spec 065 (brief summary, deterministic, sequential-default)
- [ ] Update hierarchical-agents-examples.md with Pattern A example
- [ ] Update research-coordinator.md with library extraction note
- [ ] Re-execute lean-plan with test feature (complexity 2 - sequential)
- [ ] Re-execute lean-plan with test feature (complexity 4 - parallel mode)
- [ ] Validate context consumption reduced (~500 tokens target)
- [ ] Measure execution time improvement (compare sequential vs parallel)
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

## Decision
Adopt Pattern A (Orchestrator Mode) with consistency across all implementations:
- Extract coordinator logic to `.claude/lib/coordination/research-orchestrator.sh`
- Commands source library and execute coordination logic inline
- Specialists invoked via single-level Task (no nesting)

Pattern A Consistency (aligned with Spec 065 - Lean Coordinator Wave Optimization):
1. Brief Summary Format: Aggregation returns 80 tokens (metadata fields)
2. Deterministic Logic: No LLM reasoning in library functions
3. Sequential-by-Default: Parallel execution requires explicit flag

## Consequences
- Eliminates nested Task constraint
- Preserves all orchestration logic (parallelization, aggregation)
- Reduces token overhead (no coordinator LLM reasoning)
- Requires library extraction for coordinators
- Consistent patterns across lean-coordinator and research-orchestrator

## Alternatives Rejected
- Pattern B (Direct Specialist): Loses orchestration logic, code duplication
- Nested Task Fix: Architectural constraint, not implementation bug
```

**Expected Duration**: 2 hours

**Success Criteria**:
- [ ] ADR created documenting Pattern A adoption with consistency notes
- [ ] Documentation updated across affected files
- [ ] lean-plan re-execution shows specialist Task invocations
- [ ] Sequential execution works (default)
- [ ] Parallel execution works (complexity >= 3 with flag)
- [ ] Context consumption reduced to ~500 tokens
- [ ] Brief summary format validated
- [ ] CHANGELOG.md entry added

## Testing Strategy

**Unit Testing**:
- Library function tests: `decompose_research_topics`, `generate_specialist_prompts`, `aggregate_research_results`
- Deterministic behavior validation: Same inputs always produce same outputs
- Brief summary format validation: Output < 100 tokens
- Sequential-by-default validation: Parallel mode rejected for complexity < 3
- Sourcing validation: Library sources without errors
- Error handling: Functions return proper error codes on invalid input

**Integration Testing**:
- Phase 2: lean-plan library integration test (sources and executes inline)
- Phase 3: Specialist invocation test (sequential and parallel modes)
- Phase 4: Full lean-plan execution with Pattern A

**Validation Metrics**:
- Library function return codes (0 = success)
- Deterministic output validation (same input -> same output)
- Specialist Task invocation count in output (>0 expected)
- Brief summary token count (< 100 tokens target)
- Context token consumption (~500 tokens target, down from ~15k)
- Execution time comparison (sequential vs parallel for complexity 4)
- Report artifact creation at expected paths

**Pattern A Consistency Validation**:
- Brief summary format matches lean-coordinator pattern (metadata on lines 1-8)
- Topic decomposition is deterministic (no LLM reasoning)
- Sequential execution by default (parallel requires explicit flag)

**Test Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["research-orchestrator.sh", "research reports", "adr-002-orchestrator-mode-adoption.md", "brief-summary-samples.txt"]

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

**Architecture Impact**: Pattern A adoption establishes a consistent pattern for coordinator agents. The library extraction approach can be applied to other coordinators:
- research-coordinator -> research-orchestrator.sh (this plan)
- implementer-coordinator -> implementer-orchestrator.sh (future)
- lean-coordinator -> already optimized (Spec 065)

**Pattern A Consistency**: This plan is aligned with Spec 065 (Lean Coordinator Wave Optimization) which established:
1. Brief summary format (80 tokens metadata)
2. Deterministic logic (no runtime analysis)
3. Sequential-by-default execution

These patterns are now applied uniformly to research-orchestrator.sh.

**Migration Path**: Phased rollout for Pattern A adoption:
1. **Phase 1**: lean-plan with research-orchestrator.sh (this plan)
2. **Phase 2**: /create-plan, /research using same library
3. **Phase 3**: Evaluate other coordinators for extraction

**Library Reuse**: The research-orchestrator.sh library can be shared across multiple commands:
- lean-plan (primary target)
- create-plan (research phase)
- research (standalone research)
- Any command needing multi-topic research orchestration

**Future Enhancement**: Consider implementing lean-plan-architect as a library if single-level Task continues to have issues. Current plan assumes single-level Task works correctly (depth 1 only).
