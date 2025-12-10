# Implementation: lean-plan Coordinator Library Extraction (Pattern A)

## Metadata
- **Date**: 2025-12-09 (Revised)
- **Feature**: Extract coordinator logic to library (Pattern A - Orchestrator Mode) to fix Task nesting limitations and improve performance
- **Status**: [NOT STARTED]
- **Estimated Hours**: 6-8 hours
- **Complexity Score**: 32
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Primary Agent Usage Analysis](../reports/001-primary-agent-usage-analysis.md)
  - [Coordinator Research Delegation Patterns](../reports/002-coordinator-delegation-patterns.md)
  - [Planning Subagent Architecture Analysis](../reports/003-planning-subagent-architecture.md)
  - [Orchestrator vs Direct Invocation Patterns](../../066_pattern_tradeoff_comparison/reports/001-orchestrator-vs-direct-invocation-patterns.md)

## Overview

The lean-plan command is bypassing hierarchical agent delegation entirely, executing all research and planning operations in the primary agent instead of delegating to research-coordinator and lean-plan-architect subagents. Research has confirmed that **nested Task invocation** (coordinator → specialist) is architecturally problematic and should be avoided.

**Solution**: Implement **Pattern A (Orchestrator Mode)** - extract coordinator logic to a sourced library, allowing the primary agent to execute coordinator logic inline while invoking specialists directly via single-level Task calls.

**Benefits**:
- **Eliminates nesting**: Reduces from 2 levels (primary → coordinator → specialist) to 1 level
- **Preserves coordinator logic**: All parallelization, error handling, and aggregation logic remains functional
- **Token efficiency**: No LLM tokens spent on coordinator reasoning - only specialist work
- **Deterministic execution**: Coordinator logic runs as code, not LLM interpretation

**Impact Resolution**:
- Context consumption: Reduced from ~15,000+ tokens to ~500 tokens per research phase
- Execution mode: Parallel research enabled via library-based orchestration
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

**Architecture Decision**: Proceed with Pattern A - extract coordinator logic to `.claude/lib/coordination/research-orchestrator.sh`

## Success Criteria
- [ ] Research orchestrator library created: `.claude/lib/coordination/research-orchestrator.sh`
- [ ] Library contains topic decomposition, parallel invocation generation, and result aggregation functions
- [ ] lean-plan command updated to source library and execute specialists directly
- [ ] Single-level Task invocations working (primary → specialist)
- [ ] Delegation checkpoints implemented with trace file validation
- [ ] Architecture Decision Record (ADR) created documenting Pattern A adoption
- [ ] lean-plan-output.md shows successful specialist delegation when re-executed
- [ ] Context consumption reduced from ~15k tokens to ~500 tokens

## Technical Design

### Pattern A Implementation Architecture

**Library Structure**: `.claude/lib/coordination/research-orchestrator.sh`
```bash
#!/usr/bin/env bash
# Research Orchestrator Library - Pattern A Implementation
# Extracted from research-coordinator.md for inline execution

# Topic decomposition - splits research scope into parallel topics
decompose_research_topics() {
  local feature_description="$1"
  local complexity="$2"
  # Returns JSON array of research topics
}

# Generates specialist Task invocation prompts
generate_specialist_prompts() {
  local topics_json="$1"
  local report_dir="$2"
  # Returns array of prompts for Task invocations
}

# Aggregates specialist results with metadata extraction
aggregate_research_results() {
  local report_dir="$1"
  # Validates reports, extracts metadata, returns summary
}

# Main orchestration function
orchestrate_research() {
  local feature="$1"
  local complexity="$2"
  local report_dir="$3"

  # 1. Decompose topics
  local topics=$(decompose_research_topics "$feature" "$complexity")

  # 2. Generate prompts (returned for Task invocation by caller)
  generate_specialist_prompts "$topics" "$report_dir"
}
```

**lean-plan Integration Pattern**:
```bash
# Block 1e: Research Phase (Pattern A)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/coordination/research-orchestrator.sh"

# Orchestrator generates specialist prompts inline
SPECIALIST_PROMPTS=$(orchestrate_research "$FEATURE" "$COMPLEXITY" "$REPORT_DIR")

# Primary agent invokes specialists directly (depth 1 only)
# Each Task is a single-level invocation to research-specialist
for prompt in $SPECIALIST_PROMPTS; do
  # EXECUTE NOW: USE Task tool for specialist
  Task {
    subagent_type: "general-purpose"
    description: "Research specialist for topic"
    prompt: "$prompt"
  }
done

# Aggregate results after all specialists complete
RESEARCH_SUMMARY=$(aggregate_research_results "$REPORT_DIR")
```

### Validation Strategy

**Library Function Testing**:
```bash
# Source orchestrator library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/coordination/research-orchestrator.sh"

# Unit test: topic decomposition
TOPICS=$(decompose_research_topics "implement JWT auth" "2")
[ -n "$TOPICS" ] && echo "✓ decompose_research_topics works" || echo "✗ decompose failed"

# Unit test: prompt generation
PROMPTS=$(generate_specialist_prompts "$TOPICS" "/tmp/test-reports")
[ -n "$PROMPTS" ] && echo "✓ generate_specialist_prompts works" || echo "✗ prompt generation failed"

# Integration test: full orchestration
RESULT=$(orchestrate_research "test feature" "2" "/tmp/test-reports")
[ -n "$RESULT" ] && echo "✓ orchestrate_research works" || echo "✗ orchestration failed"
```

**Specialist Invocation Checkpoints**:
```bash
# After each specialist Task invocation
if [ ! -f "${REPORT_DIR}/report_${TOPIC_INDEX}.md" ]; then
  echo "ERROR: research-specialist Task did not create report"
  echo "Expected: ${REPORT_DIR}/report_${TOPIC_INDEX}.md"
  exit 1
fi
echo "✓ Specialist ${TOPIC_INDEX} completed"
```

**Post-Aggregation Validation**:
```bash
# After aggregate_research_results
if [ -z "$RESEARCH_SUMMARY" ]; then
  echo "ERROR: Research aggregation failed"
  echo "Check specialist reports in: $REPORT_DIR"
  exit 1
fi
echo "✓ Research aggregation completed"
```

## Implementation Phases

### Phase 1: Research Orchestrator Library Creation [NOT STARTED]
dependencies: []

**Objective**: Extract coordinator logic from research-coordinator.md into a reusable bash library.

**Complexity**: Medium

**Tasks**:
- [ ] Analyze research-coordinator.md to identify extractable logic
- [ ] Create library directory: `.claude/lib/coordination/`
- [ ] Create library file: `.claude/lib/coordination/research-orchestrator.sh`
- [ ] Implement `decompose_research_topics()` - topic splitting based on complexity
- [ ] Implement `generate_specialist_prompts()` - creates Task prompts for specialists
- [ ] Implement `aggregate_research_results()` - collects and validates reports
- [ ] Implement `orchestrate_research()` - main entry point combining all functions
- [ ] Add library header with version and dependency information
- [ ] Add inline documentation for each function

**Library Skeleton**:
```bash
#!/usr/bin/env bash
# research-orchestrator.sh - Pattern A Implementation
# Version: 1.0.0
# Extracted from research-coordinator.md for inline execution
# Eliminates nested Task invocation while preserving orchestration logic

# Dependency: error-handling.sh for logging
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || true

decompose_research_topics() {
  local feature="$1"
  local complexity="$2"
  # Complexity 1-2: 2-3 topics
  # Complexity 3-4: 4-5 topics
  # Returns newline-separated topic list
}

generate_specialist_prompts() {
  local topics="$1"
  local report_dir="$2"
  # Generates JSON array of prompt objects for Task invocations
}

aggregate_research_results() {
  local report_dir="$1"
  # Validates all reports exist, extracts metadata, returns summary JSON
}

orchestrate_research() {
  local feature="$1"
  local complexity="$2"
  local report_dir="$3"
  # Main orchestration: decompose → generate prompts (caller invokes Tasks) → aggregate
}
```

**Expected Duration**: 2 hours

**Success Criteria**:
- [ ] Library file created with all four functions
- [ ] Functions source successfully without errors
- [ ] Unit tests pass for each function (see Validation Strategy)
- [ ] Library follows three-tier sourcing pattern

### Phase 2: lean-plan Command Integration [NOT STARTED]
dependencies: [1]

**Objective**: Update lean-plan.md to source the orchestrator library and invoke specialists directly.

**Complexity**: Medium

**Tasks**:
- [ ] Read lean-plan.md Block 1e structure (research coordination)
- [ ] Replace research-coordinator Task invocation with library sourcing
- [ ] Update Block 1e to call `orchestrate_research()` for topic decomposition
- [ ] Update Block 1e to iterate specialist prompts and invoke Task for each
- [ ] Add specialist Task invocation loop with parallel execution hint
- [ ] Update Block 1e verification to check specialist reports (not coordinator trace)
- [ ] Verify lean-plan-architect invocation in Block 2b (single-level, should work)
- [ ] Test updated lean-plan with simple feature description

**Updated Block 1e Pattern**:
```bash
# Block 1e: Research Phase (Pattern A - Orchestrator Mode)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/coordination/research-orchestrator.sh" 2>/dev/null || {
  echo "ERROR: Failed to source research-orchestrator library" >&2
  exit 1
}

# Decompose topics and generate specialist prompts
SPECIALIST_PROMPTS=$(orchestrate_research "$FEATURE_DESCRIPTION" "$RESEARCH_COMPLEXITY" "$REPORT_DIR")

# Store prompts for Task invocation block
append_workflow_state "SPECIALIST_PROMPTS" "$SPECIALIST_PROMPTS"

echo "Research orchestration complete: $(echo "$SPECIALIST_PROMPTS" | jq length) specialists to invoke"
```

**Expected Duration**: 2 hours

**Success Criteria**:
- [ ] lean-plan sources orchestrator library successfully
- [ ] Topic decomposition executes inline (no coordinator Task)
- [ ] Specialist Task invocations generated correctly
- [ ] lean-plan-architect invocation unchanged (single-level)

### Phase 3: Specialist Task Invocation and Validation [NOT STARTED]
dependencies: [2]

**Objective**: Implement the specialist Task invocation loop and hard barrier validation.

**Complexity**: Medium

**Tasks**:
- [ ] Create Block 1e-exec with specialist Task invocations
- [ ] Implement parallel Task invocation pattern (multiple Tasks in single block)
- [ ] Add specialist completion checkpoints after Task block
- [ ] Implement aggregate_research_results call after specialists complete
- [ ] Add hard barrier validation for report files
- [ ] Test with 2-topic complexity to verify parallel execution
- [ ] Test with 4-topic complexity to verify scaling

**Specialist Invocation Block**:
```markdown
## Block 1e-exec: Research Specialist Invocation [CRITICAL BARRIER]

**EXECUTE NOW**: USE the Task tool to invoke research specialists in parallel.

For each specialist prompt in SPECIALIST_PROMPTS:

Task {
  subagent_type: "general-purpose"
  description: "Research specialist for: ${TOPIC}"
  prompt: "${SPECIALIST_PROMPT}"
}

Note: Invoke all specialists in parallel by including multiple Task invocations in a single response.
```

**Expected Duration**: 2 hours

**Success Criteria**:
- [ ] Specialists invoke via single-level Task (no nesting)
- [ ] Multiple specialists run in parallel when possible
- [ ] Reports created at expected paths
- [ ] Hard barrier validation catches missing reports

### Phase 4: Architecture Documentation and Testing [NOT STARTED]
dependencies: [3]

**Objective**: Document Pattern A adoption, create ADR, and validate end-to-end.

**Complexity**: Low

**Tasks**:
- [ ] Create ADR: `.claude/docs/architecture/adr/002-orchestrator-mode-adoption.md`
- [ ] Document Pattern A decision rationale and tradeoffs
- [ ] Update hierarchical-agents-examples.md with Pattern A example
- [ ] Update research-coordinator.md with library extraction note
- [ ] Re-execute lean-plan with test feature
- [ ] Validate context consumption reduced (~500 tokens target)
- [ ] Measure execution time improvement (parallel specialists)
- [ ] Update CHANGELOG.md with Pattern A implementation

**ADR Content**:
```markdown
# ADR 002: Orchestrator Mode (Pattern A) Adoption

## Status
Accepted

## Context
Nested Task invocation (coordinator → specialist) proved problematic in command execution.
Research into industry patterns (Anthropic, Google ADK, Microsoft) confirmed orchestrator mode
as a valid alternative that preserves coordination logic.

## Decision
Adopt Pattern A (Orchestrator Mode):
- Extract coordinator logic to `.claude/lib/coordination/research-orchestrator.sh`
- Commands source library and execute coordination logic inline
- Specialists invoked via single-level Task (no nesting)

## Consequences
- Eliminates nested Task constraint
- Preserves all orchestration logic (parallelization, aggregation)
- Reduces token overhead (no coordinator LLM reasoning)
- Requires library extraction for coordinators

## Alternatives Rejected
- Pattern B (Direct Specialist): Loses orchestration logic, code duplication
- Nested Task Fix: Architectural constraint, not implementation bug
```

**Expected Duration**: 2 hours

**Success Criteria**:
- [ ] ADR created documenting Pattern A adoption
- [ ] Documentation updated across affected files
- [ ] lean-plan re-execution shows specialist Task invocations
- [ ] Context consumption reduced to ~500 tokens
- [ ] CHANGELOG.md entry added

## Testing Strategy

**Unit Testing**:
- Library function tests: `decompose_research_topics`, `generate_specialist_prompts`, `aggregate_research_results`
- Sourcing validation: Library sources without errors
- Error handling: Functions return proper error codes on invalid input

**Integration Testing**:
- Phase 2: lean-plan library integration test (sources and executes inline)
- Phase 3: Specialist invocation test (single-level Task execution)
- Phase 4: Full lean-plan execution with Pattern A

**Validation Metrics**:
- Library function return codes (0 = success)
- Specialist Task invocation count in output (>0 expected)
- Context token consumption (~500 tokens target, down from ~15k)
- Execution time improvement (parallel specialists)
- Report artifact creation at expected paths

**Test Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["research-orchestrator.sh", "research reports", "adr-002-orchestrator-mode-adoption.md"]

## Documentation Requirements

**New Documentation**:
- ADR 002: Orchestrator Mode (Pattern A) Adoption
- Orchestrator library: `.claude/lib/coordination/research-orchestrator.sh`
- Library README: `.claude/lib/coordination/README.md`

**Updated Documentation**:
- `.claude/docs/concepts/hierarchical-agents-examples.md` - Add Pattern A orchestrator example
- `.claude/docs/concepts/hierarchical-agents-coordination.md` - Document library extraction pattern
- `.claude/agents/research-coordinator.md` - Note library extraction for inline mode
- `.claude/commands/lean-plan.md` - Update research phase to use orchestrator library
- `CHANGELOG.md` - Document Pattern A implementation

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

**Prerequisite Knowledge**:
- Hierarchical agent architecture patterns
- Hard barrier pattern implementation
- Bash library authoring conventions
- Three-tier sourcing pattern

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
- Success Metric: Parallel specialist execution confirmed

## Notes

**Architecture Impact**: Pattern A adoption establishes a new pattern for coordinator agents. The library extraction approach can be applied to other coordinators:
- research-coordinator → research-orchestrator.sh (this plan)
- implementer-coordinator → implementer-orchestrator.sh (future)
- Other coordinators as needed

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
