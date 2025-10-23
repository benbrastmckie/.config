# Skills vs Subagents vs Utilities Decision Guide

## Purpose

This guide helps developers choose the optimal approach for implementing functionality in the .claude/ system: utility functions (bash scripts), subagents (Task tool), or skills (automatic activation).

## When to Use Each Approach

### Use Utility Functions (Bash Scripts)

**Criteria**: Deterministic logic with no AI reasoning required

**Examples**:
- Topic numbering (sequential calculation)
- Directory creation (file system operations)
- Path sanitization (string manipulation)
- Project root detection (directory traversal)
- Metadata extraction (parsing structured files)

**Benefits**:
- Zero AI token cost
- 10-20x faster execution
- Easily testable with unit tests
- Predictable, deterministic behavior
- No API rate limits or failures

**Pattern**:
```bash
# Source library
source "${CLAUDE_CONFIG}/.claude/lib/topic-utils.sh"

# Call functions directly
TOPIC_NUM=$(get_next_topic_number "$SPECS_ROOT")
TOPIC_NAME=$(sanitize_topic_name "$WORKFLOW_DESCRIPTION")
```

**When NOT to use**:
- Complex decision-making required
- Natural language understanding needed
- Context-dependent analysis
- Ambiguous inputs that need interpretation

---

### Use Subagents (Task Tool)

**Criteria**: Orchestrated workflows, temporal dependencies, verification checkpoints

**Examples**:
- Research phases (multi-topic exploration)
- Planning (requirement analysis and task breakdown)
- Implementation (code generation and testing)
- Debug analysis (root cause investigation)

**Benefits**:
- Controlled execution order
- Checkpoint recovery (resume from failures)
- Metadata extraction (99% context reduction)
- Parallel execution capabilities
- Agent specialization

**Pattern**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: "
    Read behavioral guidelines: .claude/agents/research-specialist.md

    Topic: ${TOPIC_DESCRIPTION}

    Analyze codebase and create comprehensive report.
    Save to: ${REPORT_PATH}
  "
}
```

**When NOT to use**:
- Simple string manipulation
- Deterministic calculations
- No AI reasoning needed
- Performance-critical paths

---

### Use Skills (Automatic Activation)

**Criteria**: Reusable expertise, standards enforcement, no timing dependencies

**Examples**:
- Code style checking (language-specific rules)
- Testing patterns (test framework selection)
- Documentation standards (formatting and structure)
- Security best practices (vulnerability detection)

**Benefits**:
- 99% dormant token reduction (only loaded when relevant)
- Automatic activation (Claude detects relevance)
- Reusable across projects
- Standards enforcement without explicit calls

**Pattern**:
```yaml
# skill.json
{
  "name": "python-style-checker",
  "description": "Enforces PEP 8 style guidelines for Python code",
  "activation_keywords": ["python", "style", "lint", "format"],
  "expertise": "..."
}
```

**When NOT to use**:
- Temporal orchestration needed (skills can't guarantee execution order)
- File creation required (skills provide guidance, not actions)
- Phase-dependent logic (e.g., "run after planning, before implementation")
- Location detection (no timing control)

---

### Use Hybrid Approach

**Criteria**: Common simple cases + rare complex cases

**Examples**:
- Location detection (utilities 90%, agent 10%)
  - Simple: Project root + sequential topic number
  - Complex: Multi-system refactor spanning directories
- Test execution (utilities for standard patterns, agent for custom)
- Documentation generation (templates for standard, agent for novel)

**Benefits**:
- Best of both worlds (efficiency + robustness)
- Graceful degradation (fallback to robust path)
- Cost optimization (zero-cost for common cases)
- Quality maintenance (agent handles edge cases)

**Pattern**:
```bash
# Complexity heuristic
if is_simple_workflow "$WORKFLOW_DESCRIPTION"; then
  # Use utility functions (90% of cases)
  TOPIC_NUM=$(get_next_topic_number "$SPECS_ROOT")
  TOPIC_NAME=$(sanitize_topic_name "$WORKFLOW_DESCRIPTION")
else
  # Fallback to agent (10% of cases)
  invoke_location_specialist_agent "$WORKFLOW_DESCRIPTION"
fi
```

**Implementation Example** (from /supervise Phase 0 optimization):
```bash
# Heuristic: Simple workflows use utilities, complex use agent
WORKFLOW_COMPLEXITY=$(calculate_complexity "$WORKFLOW_DESCRIPTION")

if [ "$WORKFLOW_COMPLEXITY" -lt 5 ]; then
  # Simple workflow: Use utilities (zero cost, instant)
  source "${CLAUDE_CONFIG}/.claude/lib/topic-utils.sh"
  TOPIC_NUM=$(get_next_topic_number "$SPECS_ROOT")
  TOPIC_NAME=$(sanitize_topic_name "$WORKFLOW_DESCRIPTION")
  create_topic_structure "${SPECS_ROOT}/${TOPIC_NUM}_${TOPIC_NAME}"
else
  # Complex workflow: Use Haiku 4.5 agent (67% cost savings vs Sonnet)
  Task {
    subagent_type: "general-purpose"
    description: "Determine project location for complex workflow"
    prompt: "Read: .claude/agents/location-specialist.md ..."
  }
fi
```

---

## Decision Tree

```
Is the logic deterministic?
├─ YES: Is AI reasoning required?
│  ├─ NO: Use Utility Functions (bash scripts)
│  └─ YES: Is it orchestrated workflow?
│     ├─ YES: Use Subagents (Task tool)
│     └─ NO: Is timing control needed?
│        ├─ NO: Use Skills (automatic activation)
│        └─ YES: Use Subagents (Task tool)
└─ NO: Are there common simple cases?
   ├─ YES: Use Hybrid Approach (utilities + agent fallback)
   └─ NO: Use Subagents (Task tool)
```

## Case Study: /supervise Location Detection Optimization

### Problem
Phase 0 location detection consumed 75.6k tokens (38% context window) through location-specialist agent, despite 90%+ workflows following simple pattern (project root + sequential topic number).

### Analysis
| Aspect | Agent-Only | Utility-Only | Hybrid |
|--------|-----------|-------------|--------|
| Token Usage | 75.6k | 7.5k-11k | 8.5k (avg) |
| Execution Time | 25.2s | 0.7s | 1.1s (avg) |
| Cost | $0.68 | $0.00 | $0.03 (avg) |
| Accuracy | 100% | 98% | 100% |
| Complexity | Low | Low | Medium |

### Decision
Implemented utility-based detection with agent fallback for complex cases:
- 90% of workflows: Use utilities (zero cost, instant)
- 10% of workflows: Use Haiku 4.5 agent (67% cost savings vs Sonnet)
- Result: 90% cost reduction, 85% token reduction, 100% reliability

### Implementation
1. Created `.claude/lib/topic-utils.sh` with deterministic functions
2. Refactored `/supervise` Phase 0 to source utilities
3. Added verification checkpoint (standards compliance)
4. Retained location-specialist agent with Haiku 4.5 model for fallback

### Key Insights
- Deterministic logic (topic numbering) doesn't benefit from AI
- Agent's codebase search (15-20k tokens) provided minimal value
- Utility functions are 20x faster and zero-cost
- Hybrid approach maintains 100% reliability with graceful degradation

---

## Performance Comparison

### Token Usage
| Approach | Token Usage | Context % | Cost per Call |
|----------|------------|-----------|---------------|
| Agent (Sonnet 4.5) | 75,600 | 38% | $0.68 |
| Agent (Haiku 4.5) | 75,600 | 38% | $0.23 |
| Utility Functions | 7,500-11,000 | 4-6% | $0.00 |
| Hybrid (90% util, 10% agent) | 8,500 (avg) | 4% | $0.03 |

### Execution Time
| Approach | Time | Speedup |
|----------|------|---------|
| Agent (Sonnet 4.5) | 25.2s | 1x |
| Agent (Haiku 4.5) | 5.2s | 4.8x |
| Utility Functions | 0.7s | 36x |
| Hybrid | 1.1s | 23x |

---

## Best Practices

### 1. Start with Simplest Approach
- Default to utilities for deterministic logic
- Only add AI when truly needed
- Measure before optimizing

### 2. Profile Before Optimizing
- Measure token usage, execution time, cost
- Identify bottlenecks (use monitoring infrastructure)
- Quantify optimization potential

### 3. Maintain Verification Checkpoints
- Utility functions MUST verify outputs (file existence, data validity)
- Follow Verification and Fallback pattern (see `.claude/docs/concepts/patterns/verification-fallback.md`)
- Add fallback to agent if utility fails

### 4. Document Decision Rationale
- Explain why approach was chosen
- Include performance metrics
- Describe edge cases and fallback strategy

### 5. Test Edge Cases
- Utilities: Empty inputs, special characters, boundary conditions
- Subagents: Transient failures, partial successes, timeouts
- Hybrid: Complexity threshold accuracy, fallback triggers

---

## Migration Path

### From Agent-Only to Hybrid

1. **Profile Current Implementation**
   - Measure token usage, execution time, cost
   - Identify deterministic logic patterns
   - Quantify optimization potential

2. **Extract Deterministic Logic**
   - Create utility library (`.claude/lib/`)
   - Implement functions with verification
   - Add comprehensive unit tests

3. **Refactor Command**
   - Source utility library
   - Replace agent invocation with utility calls
   - Maintain output format compatibility

4. **Add Fallback Mechanism** (Optional)
   - Define complexity heuristic
   - Implement agent fallback for complex cases
   - Test edge cases thoroughly

5. **Monitor and Iterate**
   - Track token usage, execution time, cost
   - Identify false positives/negatives
   - Refine heuristic based on data

---

## Common Pitfalls

### Pitfall 1: Using Agent for Deterministic Logic
**Symptom**: High token usage for simple calculations
**Solution**: Extract to utility functions

### Pitfall 2: Using Utility for Complex Analysis
**Symptom**: Incorrect results, brittle logic
**Solution**: Use subagent with proper behavioral guidelines

### Pitfall 3: Using Skill for Temporal Orchestration
**Symptom**: Unpredictable execution order
**Solution**: Use subagent with explicit phase control

### Pitfall 4: No Fallback in Hybrid Approach
**Symptom**: Failures on edge cases, reduced reliability
**Solution**: Implement agent fallback with error classification

---

## Related Documentation

- [Agent Development Guide](agent-development-guide.md) - Creating specialized agents
- [Command Development Guide](command-development-guide.md) - Slash command patterns
- [Verification and Fallback Pattern](../concepts/patterns/verification-fallback.md) - Error handling
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Agent invocation
- [Context Management Pattern](../concepts/patterns/context-management.md) - Token optimization

---

## Revision History

### 2025-10-23 - Initial Version
- Created based on /supervise Phase 0 optimization experience
- Documented utility functions vs subagents vs skills decision criteria
- Added case study, performance comparison, best practices
