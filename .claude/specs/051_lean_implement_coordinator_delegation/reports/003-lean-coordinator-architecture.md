# Research Report: Lean Coordinator Architecture Optimization

## Metadata
- **Date**: 2025-12-09
- **Topic**: Applying hierarchical agent patterns to lean-implement
- **Source**: .claude/agents/lean-coordinator.md, .claude/docs/concepts/hierarchical-agents-examples.md

## Executive Summary

The lean-coordinator agent is well-designed with wave-based orchestration and proper delegation to lean-implementer agents. However, the integration with /lean-implement has architectural gaps that cause the primary agent to consume context unnecessarily. This report identifies optimization opportunities that maintain existing coordinator architecture while fixing the integration layer.

## Findings

### 1. Lean Coordinator Architecture (Existing)

The lean-coordinator.md defines a sophisticated architecture:

**Wave-Based Orchestration**:
- Dependency analysis via dependency-analyzer.sh
- Parallel lean-implementer invocations per wave
- Wait for ALL implementers before next wave (synchronization barrier)
- Rate limit coordination (3 requests/30s budget allocation)

**Output Signal Format**:
```yaml
PROOF_COMPLETE:
  coordinator_type: lean
  summary_brief: "Completed Wave 1-2 (Phase 1,2) with 15 theorems. Context: 72%. Next: Continue Wave 3."
  phases_completed: [1, 2]
  work_remaining: Phase_4 Phase_5 Phase_6
  context_usage_percent: 72
  requires_continuation: true
```

**Context Efficiency Target**: <20% for coordination overhead

### 2. Integration Layer Issues

The /lean-implement command (lines 29-49 of output) shows the primary agent:
1. Reading lean-coordinator.md (1174 lines)
2. Reading plan file (474 lines)
3. THEN invoking Task tool

This violates the hierarchical pattern where:
- Coordinators should read their own behavioral files
- Primary agent should only pass file paths

### 3. Communication Protocol

From `hierarchical-agents-communication.md`, the correct pattern:

**Orchestrator -> Coordinator**:
```yaml
Input Contract:
  - plan_path: /absolute/path  # Path, not content
  - agent_behavior_path: /absolute/path  # Path, not content
  - artifact_paths:
      summaries: /path
      outputs: /path
```

**Coordinator -> Orchestrator**:
```yaml
Return Signal:
  - summary_brief: "80-token summary"  # Brief, not full
  - phases_completed: [1, 2]  # Structured data
  - work_remaining: "Phase_3 Phase_4"  # Space-separated
```

### 4. Existing Pattern Success: research-coordinator

From `hierarchical-agents-examples.md` Example 7:

The research-coordinator demonstrates successful 95% context reduction:
- Receives topic list from orchestrator
- Invokes research-specialist in parallel
- Extracts only metadata from results (title, findings count, path)
- Returns aggregated 110-token summaries to orchestrator

**Key difference from lean-implement**:
- research-coordinator is invoked WITHOUT the orchestrator reading agent files
- research-coordinator reads its OWN behavioral file internally
- Orchestrator only parses brief metadata on return

### 5. Lean Command Coordinator Optimization (Example 8)

From CLAUDE.md and `hierarchical-agents-examples.md`:

```
Dual coordinator integration:
- /lean-plan: research-coordinator for parallel multi-topic research
- /lean-implement: implementer-coordinator for wave-based orchestration

Performance: 95-96% context reduction, 10+ iterations possible (vs 3-4 before)
```

The /lean-plan command correctly implements this pattern. /lean-implement should follow the same architecture.

## Recommendations

### 1. Modify Primary Agent Invocation Pattern

**Current** (lean-implement.md lines 932-943):
```markdown
Task {
  subagent_type: "general-purpose"
  model: "sonnet"
  description: "${COORDINATOR_DESCRIPTION}"
  prompt: "${COORDINATOR_PROMPT}"
}
```

**Recommended**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke lean-coordinator.

You MUST use the Task tool with these EXACT parameters:
- **subagent_type**: "general-purpose"
- **model**: "opus-4.5"  # From lean-coordinator.md model field
- **description**: "Wave-based theorem proving for ${PLAN_FILE}"
- **prompt**:
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md

    **Input Contract**:
    - plan_path: ${PLAN_FILE}
    - lean_file_path: ${PRIMARY_LEAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - artifact_paths:
        summaries: ${SUMMARIES_DIR}
        outputs: ${OUTPUTS_DIR}
    - iteration: ${ITERATION}
    - max_iterations: ${MAX_ITERATIONS}

    Execute wave-based orchestration and return PROOF_COMPLETE signal.
```

**Key Changes**:
1. Add `**EXECUTE NOW**: USE the Task tool` directive
2. Include `Read and follow` instruction in prompt (coordinator reads its own file)
3. Pass only paths, not content
4. Do NOT read lean-coordinator.md from primary agent

### 2. Implement Brief Summary Parsing

Replace full file read with structured metadata extraction:

```bash
# Block 1c: Parse coordinator output (80 tokens instead of 2000)
parse_brief_summary() {
  local summary_file="$1"

  # Extract ONLY structured metadata (lines 1-8)
  SUMMARY_BRIEF=$(head -8 "$summary_file" | grep "^summary_brief:" | cut -d: -f2- | xargs)
  PHASES_COMPLETED=$(head -8 "$summary_file" | grep "^phases_completed:" | cut -d: -f2- | xargs)
  WORK_REMAINING=$(head -8 "$summary_file" | grep "^work_remaining:" | cut -d: -f2- | xargs)
  CONTEXT_USAGE=$(head -8 "$summary_file" | grep "^context_usage_percent:" | cut -d: -f2- | xargs)
  REQUIRES_CONTINUATION=$(head -8 "$summary_file" | grep "^requires_continuation:" | cut -d: -f2- | xargs)
}
```

### 3. Remove Agent File Read Operations

Delete these sections from primary agent flow:
- Line 32-34 equivalent: `Read(.claude/agents/lean-coordinator.md)`
- Line 85-86 equivalent: `Read(.claude/agents/implementer-coordinator.md)`

Replace with comment:
```markdown
# Coordinator reads its own behavioral file internally via:
# "Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md"
```

### 4. Add Delegation Contract Validation

The lean-implement.md includes `validate_delegation_contract()` function (lines 55-106). This should be called after each coordinator return:

```bash
# Block 1c: Validate delegation contract
if ! validate_delegation_contract "$WORKFLOW_LOG"; then
  log_command_error "delegation_error" "Primary agent performed implementation work"
fi
```

## Architecture Diagram (Optimized)

```
/lean-implement (Primary Agent)
├── Block 1a: Pre-calculate paths (NO reads)
├── Block 1a-classify: Parse plan structure (1 read: plan file)
├── Block 1b: Build coordinator prompt (NO reads)
│   └── Task(lean-coordinator) ─────────────────────────────┐
│       │                                                    │
│       ├── Coordinator reads lean-coordinator.md            │
│       ├── Coordinator parses plan                          │
│       ├── Coordinator invokes lean-implementer agents      │
│       └── Returns brief summary (80 tokens)                │
│                                                            │
├── Block 1c: Parse brief summary (head -8 only)            │
│   └── If requires_continuation: exit 0 (hard barrier)     │
└── Block 2: Final summary (80-token parsing)
```

## Performance Metrics (Projected)

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Primary agent context | 8,000 tokens | 2,000 tokens | 75% |
| Max iterations | 3-4 | 10+ | 3x |
| Coordinator overhead | N/A | <20% | Per spec |
| Brief summary size | 2,000 tokens | 80 tokens | 96% |
