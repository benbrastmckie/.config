# Research Invocation Standards

## Overview

This document defines when to use `research-coordinator` versus direct `research-specialist` invocation in workflow commands. Following these standards ensures consistent research patterns across all commands and maximizes the benefits of parallel multi-topic research orchestration.

## Decision Matrix

Use this matrix to determine which research pattern to use:

| Scenario | Complexity | Prompt Structure | Pattern | Agent to Invoke |
|----------|-----------|------------------|---------|-----------------|
| Simple, focused request | 1-2 | Single domain/topic | Direct invocation | research-specialist |
| Complex, multi-domain | 3 | 2-3 topics identifiable | Coordinator | research-coordinator |
| Comprehensive analysis | 4 | 4-5 topics required | Coordinator | research-coordinator |
| Lean-specific research | Any | Lean/Mathlib context | Specialized direct | lean-research-specialist |

## Pattern Definitions

### Pattern 1: Direct research-specialist Invocation

**Use When**:
- Research complexity is 1-2
- Prompt describes a single, focused topic
- No multi-topic indicators present (no "and", "or", commas)
- Research can be completed in one cohesive report

**Benefits**:
- Simple, straightforward invocation
- No coordination overhead
- Single report output

**Example**:
```yaml
research_request: "Investigate JWT token best practices for Node.js"
research_complexity: 2
pattern: direct
agent: research-specialist
```

**Command Integration**:
```bash
# Direct Task invocation
Task {
  subagent_type: "general-purpose"
  description: "Research ${FEATURE_DESCRIPTION}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Input Contract**:
    - Report Path: ${REPORT_PATH}
    - Research Topic: ${FEATURE_DESCRIPTION}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
  "
}
```

---

### Pattern 2: research-coordinator with Multi-Topic Decomposition

**Use When**:
- Research complexity is 3 or 4
- Prompt contains multiple distinct topics
- Multi-topic indicators present ("and", "or", commas, domain keywords)
- Research benefits from parallel execution

**Benefits**:
- Parallel research execution (40-60% time savings potential)
- Metadata-only context passing (95% token reduction: 110 tokens vs 2,500 tokens per report)
- Focused, topic-specific reports
- Better organization for complex features

**Example**:
```yaml
research_request: "Implement OAuth2 authentication with session management and password security"
research_complexity: 3
pattern: coordinator
agent: research-coordinator
topics:
  - "OAuth2 authentication implementation patterns"
  - "Session management and token storage"
  - "Password security best practices"
```

**Command Integration**:
```bash
# Multi-topic decomposition block
# Analyze FEATURE_DESCRIPTION for topics
# Pre-calculate report paths for each topic
# Store in TOPICS_LIST and REPORT_PATHS_LIST (pipe-separated)

# Coordinator Task invocation
Task {
  subagent_type: "general-purpose"
  description: "Coordinate multi-topic research for ${FEATURE_DESCRIPTION}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    **Input Contract (Mode 2: Pre-Decomposed)**:
    - research_request: ${FEATURE_DESCRIPTION}
    - research_complexity: ${RESEARCH_COMPLEXITY}
    - report_dir: ${RESEARCH_DIR}
    - topic_path: ${TOPIC_PATH}
    - topics: ${TOPICS_LIST}
    - report_paths: ${REPORT_PATHS_LIST}
  "
}
```

---

### Pattern 3: Specialized Direct Invocation (Lean)

**Use When**:
- Research involves Lean 4 or Mathlib
- Domain-specific knowledge required (theorem proving, proof tactics)
- Lean project context needed

**Benefits**:
- Domain-specific research expertise
- Mathlib discovery and theorem analysis
- Proof pattern recommendations

**Example**:
```yaml
research_request: "Investigate group homomorphism theorems in Mathlib"
research_complexity: 2
pattern: specialized_direct
agent: lean-research-specialist
```

**Command Integration**:
```bash
# Direct Task invocation with Lean context
Task {
  subagent_type: "general-purpose"
  description: "Research ${FEATURE_DESCRIPTION} with Mathlib discovery"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-research-specialist.md

    **Input Contract**:
    - REPORT_PATH: ${REPORT_PATH}
    - LEAN_PROJECT_PATH: ${LEAN_PROJECT_PATH}
    - FEATURE_DESCRIPTION: ${FEATURE_DESCRIPTION}
    - RESEARCH_COMPLEXITY: ${RESEARCH_COMPLEXITY}
  "
}
```

---

## Uniformity Requirements

### Dependent-Agents Declaration Rules

1. **Direct Invocation Commands**:
   - List only directly invoked agents
   - Example: `dependent-agents: [research-specialist]`

2. **Coordinator Pattern Commands**:
   - List `research-coordinator` (directly invoked)
   - Do NOT list `research-specialist` (transitive dependency, invoked by coordinator)
   - Do NOT list `research-sub-supervisor` (transitive dependency, invoked by coordinator when needed)
   - Example: `dependent-agents: [research-coordinator]`

3. **Mixed Pattern Commands** (if applicable):
   - List all directly invoked agents
   - Example: `dependent-agents: [research-coordinator, topic-detection-agent, plan-architect]`

**Rationale**: The dependent-agents field should reflect the command's direct delegation, not the full agent hierarchy. This improves clarity and prevents documentation drift.

---

### Multi-Report Validation

All commands using `research-coordinator` MUST implement multi-report validation:

```bash
# Parse report paths from state
IFS='|' read -ra REPORT_PATHS_ARRAY <<< "$REPORT_PATHS_LIST"

# Validate each report exists (hard barrier)
for REPORT_PATH in "${REPORT_PATHS_ARRAY[@]}"; do
  if [ ! -f "$REPORT_PATH" ]; then
    echo "ERROR: HARD BARRIER FAILED - Report missing: $REPORT_PATH" >&2
    exit 1
  fi

  # Validate minimum size
  REPORT_SIZE=$(wc -c < "$REPORT_PATH" 2>/dev/null || echo 0)
  if [ "$REPORT_SIZE" -lt 100 ]; then
    echo "ERROR: Report too small: $REPORT_PATH ($REPORT_SIZE bytes)" >&2
    exit 1
  fi
done
```

**Fail-Fast Policy**: If ANY report is missing or invalid, the workflow MUST terminate. Partial success is not acceptable.

---

## Command-Specific Guidance

### /create-plan Command

**Pattern**: research-coordinator (Mode 2: Pre-Decomposed)
**Complexity**: Default 3
**Decomposition**: Automated via topic-detection-agent (Haiku model) or heuristic fallback
**Validation**: Multi-report hard barrier before plan-architect invocation

**Integration Points**:
1. Block 1d-topics: Topic decomposition (automated or heuristic)
2. Block 1e-exec: research-coordinator invocation with pre-calculated topics/paths
3. Block 1f: Multi-report validation loop
4. Block 2: plan-architect receives report paths (metadata-only)

---

### /research Command

**Pattern**: research-coordinator (Mode 2: Pre-Decomposed)
**Complexity**: Default 2 (single-topic), 3+ triggers multi-topic
**Decomposition**: Heuristic-based (no topic-detection-agent)
**Validation**: Multi-report hard barrier before terminal state

**Integration Points**:
1. Block 1d-topics: Topic decomposition (heuristic only)
2. Block 1d-exec: research-coordinator invocation with pre-calculated topics/paths
3. Block 1e: Multi-report validation loop
4. Block 2: Terminal state (no planning phase)

**Key Difference from /create-plan**: /research does NOT use topic-detection-agent (simpler, faster decomposition).

---

### /lean-plan Command

**Pattern**: research-coordinator (Mode 2: Pre-Decomposed)
**Complexity**: Default 3
**Status**: INTEGRATED with research-coordinator (as of 2025-12-08)
**Decomposition**: Pre-defined Lean-specific topics based on complexity level
**Validation**: Multi-report hard barrier with ≥50% partial success mode

**Lean-Specific Topics by Complexity**:
- **Complexity 1-2**: Mathlib Research (1 topic)
- **Complexity 3**: Mathlib Research, Proof Strategies, Project Structure (3 topics)
- **Complexity 4**: Mathlib Research, Proof Strategies, Project Structure, Style Guidelines (4 topics)

**Integration Points**:
1. Block 1d-topics: Lean-specific topic classification and path pre-calculation
2. Block 1e-exec: research-coordinator invocation with pre-decomposed topics
3. Block 1f: Multi-report validation with ≥50% partial success mode
4. Block 1f-metadata: Metadata extraction from coordinator output
5. Block 2: lean-plan-architect receives metadata-only context

**Performance Metrics**:
- Context reduction: 95.6% (7,500 → 330 tokens for 3 reports)
- Time savings: 40-60% through parallel research execution
- Iteration capacity: 10+ iterations (vs 3-4 with full report passing)

**Note**: Uses research-coordinator with research-specialist for general research tasks. Future enhancement may introduce lean-research-specialist for Mathlib-specific deep research.

---

### /repair, /debug, /revise Commands

**Pattern**: TBD (Phase 10-12 of spec 013)
**Status**: NOT YET INTEGRATED
**Planned Complexity**: 3 (multi-topic by default for comprehensive analysis)

**Future Topics Examples**:
- **/repair**: "error patterns", "root causes", "affected workflows"
- **/debug**: "symptom analysis", "code path investigation", "context gathering"
- **/revise**: "current implementation analysis", "proposed changes impact", "dependency assessment"

---

## Migration Path

### For Existing Commands Using Direct research-specialist

1. **Assess Complexity**: Determine if multi-topic decomposition adds value
   - If complexity typically 1-2: Keep direct invocation
   - If complexity typically 3-4: Migrate to coordinator

2. **Add Topic Decomposition Block** (if migrating):
   - Insert Block 1d-topics after path initialization
   - Implement heuristic decomposition logic
   - Pre-calculate report paths for each topic
   - Persist TOPICS_LIST and REPORT_PATHS_LIST

3. **Replace Agent Invocation**:
   - Change Task invocation from research-specialist to research-coordinator
   - Pass topics and report_paths in contract (Mode 2)
   - Update agent name in prompt

4. **Update Validation**:
   - Replace single-report validation with multi-report loop
   - Parse REPORT_PATHS_LIST from state
   - Validate each report (fail-fast on missing)

5. **Update Frontmatter**:
   - Change `dependent-agents: [research-specialist]` to `dependent-agents: [research-coordinator]`

6. **Test Multi-Topic Scenarios**:
   - Test with complexity 3-4 prompts
   - Verify parallel execution (time measurement)
   - Verify all reports created
   - Verify metadata extraction

---

### For New Commands

1. **Choose Pattern** (use decision matrix above)
2. **Follow Reference Implementation**:
   - Direct: See `/research` Block 1d, 1d-exec, 1e (single-topic mode)
   - Coordinator: See `/research` Block 1d-topics, 1d-exec, 1e (multi-topic mode)
   - Coordinator with topic-detection: See `/create-plan` Block 1d-topics-auto, 1e-exec, 1f

3. **Implement Hard Barrier Pattern**:
   - Pre-calculate paths BEFORE agent invocation
   - Pass paths as literal contract to agent
   - Validate artifacts exist AFTER agent returns
   - Fail-fast if validation fails

4. **Update Dependent-Agents**:
   - List only directly invoked agents
   - Follow uniformity rules above

---

## Troubleshooting

### Issue: Multi-Topic Decomposition Returns 1 Topic

**Cause**: Prompt does not contain multi-topic indicators
**Solution**:
- Check RESEARCH_COMPLEXITY (must be ≥3 for multi-topic)
- Check for conjunctions ("and", "or") or commas in prompt
- Fallback to single-topic mode is correct behavior

---

### Issue: research-coordinator Reports Missing

**Cause**: Coordinator failed to invoke research-specialist or path mismatch
**Diagnostics**:
1. Check research-coordinator output for errors
2. Verify topics and report_paths were passed correctly (check pipe-separated format)
3. Verify research-coordinator parsed topics correctly
4. Run `/errors --command <command> --type agent_error`

**Solution**:
- Ensure topics and report_paths arrays match in length
- Ensure paths are absolute (start with `/`)
- Ensure report_dir exists before coordinator invocation

---

### Issue: Context Reduction Not Achieved

**Cause**: Metadata-only passing not implemented correctly
**Diagnostics**:
1. Check if plan-architect receives report paths (not full content)
2. Check if aggregated metadata format matches 110-token spec
3. Measure token usage before/after (expected 95% reduction)

**Solution**:
- Pass REPORT_PATHS_ARRAY to plan-architect
- Include metadata summary (title, findings count, recommendations count)
- plan-architect reads reports as needed via Read tool

---

## Performance Benefits

### Context Reduction

**Baseline**: Full report content passed to downstream agents
- Report size: ~2,500 tokens average
- Multi-report scenario (3 topics): 7,500 tokens

**Coordinator Pattern**: Metadata-only passing
- Metadata per report: ~110 tokens (title, findings count, recommendations count, path)
- Multi-report scenario (3 topics): 330 tokens
- **Reduction**: 95% (7,500 → 330 tokens)

---

### Parallel Execution Time Savings

**Baseline**: Sequential research-specialist invocations
- Single topic: 60 seconds average
- Multi-topic scenario (3 topics): 180 seconds sequential

**Coordinator Pattern**: Parallel research-specialist invocations
- Single topic: 60 seconds average
- Multi-topic scenario (3 topics): 70 seconds parallel (limited by slowest topic + coordination overhead)
- **Time Savings**: 61% (180 → 70 seconds)

**Note**: Actual savings depend on topic complexity distribution. If one topic is significantly more complex, parallelization gains are reduced.

---

## Standards Compliance

### Code Standards

- Three-tier bash sourcing pattern (error-handling, state-persistence, workflow-state-machine)
- Task invocations use imperative directives: "**EXECUTE NOW**: USE the Task tool..."
- Path validation handles PROJECT_DIR under HOME as valid

### Hierarchical Agent Architecture

- research-coordinator fits supervisor role
- research-specialist fits worker role
- Metadata-only context passing (supervisor → primary agent)
- Hard barrier pattern (path pre-calculation → validation)

### Error Logging

- Use `log_command_error()` for all research failures
- Error types: `agent_error`, `validation_error`, `state_error`
- Parse subagent errors with `parse_subagent_error()`

### Output Formatting

- Target 2-3 bash blocks per command (Setup/Execute/Cleanup)
- Single summary line per block for interim output
- Console summaries use 4-section format (Summary/Phases/Artifacts/Next Steps)

---

## Decision Tree Flowchart

```
┌─────────────────────────────────────────┐
│ Does prompt require research?           │
└───────────┬─────────────────────────────┘
            │
            ├─── Yes ───┐
            │           │
            └─── No ──> Exit (no research needed)
                        │
                        ▼
                ┌───────────────────────────────┐
                │ What is RESEARCH_COMPLEXITY?  │
                └───────┬───────────────────────┘
                        │
                        ├─── 1-2 ───┐
                        │           │
                        ├─── 3-4 ───┼───> Use research-coordinator
                        │           │     (multi-topic decomposition)
                        │           │
                        └───────────┼───> Pattern 2
                                    │
                                    ▼
                            ┌───────────────────────┐
                            │ Is domain-specific?   │
                            └───────┬───────────────┘
                                    │
                                    ├─── Lean/Mathlib ───> Use lean-research-specialist
                                    │                      (Pattern 3)
                                    │
                                    └─── General ───> Use research-specialist
                                                       (Pattern 1)
```

---

## Related Documentation

- [Hierarchical Agent Architecture Overview](../../../concepts/hierarchical-agents-overview.md)
- [Hierarchical Agent Examples - Example 7: Research Coordinator](../../../concepts/hierarchical-agents-examples.md#example-7-research-coordinator-with-parallel-multi-topic-research)
- [Command Authoring Standards](./command-authoring.md)
- [Command Patterns Quick Reference](../command-patterns-quick-reference.md)
- [Hard Barrier Pattern](../../../concepts/patterns/hard-barrier-pattern.md)
- [Error Handling Pattern](../../../concepts/patterns/error-handling.md)

---

## Changelog

- **2025-12-08**: Updated /lean-plan status from NOT INTEGRATED to INTEGRATED (spec 022)
- **2025-12-08**: Added Lean-specific topic classification and performance metrics
- **2025-12-08**: Initial standards document created (spec 013 Phase 5)
- **Status**: Active (enforced for all new commands, recommended for migrations)
