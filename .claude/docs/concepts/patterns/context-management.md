# Context Management Pattern

**Path**: docs → concepts → patterns → context-management.md

[Used by: /orchestrate, /implement, all commands, agents, and multi-phase workflows]

Techniques for maintaining <30% context usage throughout workflows through aggressive pruning, layered context, and metadata-only passing.

## Definition

Context Management is a comprehensive pattern combining multiple techniques to minimize token usage: metadata extraction, context pruning, forward message passing, layered context architecture, and aggressive cleanup. This enables complex multi-phase workflows to complete within context limits that would otherwise accommodate only 1-2 phases.

Target metric: <30% context usage across entire workflow lifecycle.

## Rationale

### Why This Pattern Matters

Context overflow is the primary scalability limit for multi-agent workflows. Without active context management:
- Research phase: 40-60% context (4 agents × full reports)
- Planning phase: +30% context (plan creation + research references)
- Total after 2 phases: 70-90% context (cannot proceed to implementation)

With context management:
- Research phase: 4-6% context (metadata only)
- Planning phase: +3-5% context (metadata + plan summary)
- Implementation phase: +8-12% context (code changes metadata)
- All 7 phases: <30% context usage

## Implementation

### Technique 1: Metadata Extraction

Return condensed metadata instead of full content:

```markdown
## Agent Completion Protocol

Return metadata only (200-300 tokens):
{
  "artifact_path": "/path/to/artifact.md",
  "summary": "50-word summary",
  "key_findings": ["finding 1", "finding 2", "finding 3"]
}

DO NOT include full artifact content (5,000-10,000 tokens).
```

See [Metadata Extraction Pattern](./metadata-extraction.md) for complete details.

### Technique 2: Context Pruning

Aggressively remove completed phase data:

```markdown
## Phase Completion Cleanup

After Phase N completes:

1. Extract metadata from phase results
2. Store metadata in checkpoint
3. PRUNE full phase content from context:
   - Remove agent full responses
   - Remove intermediate calculations
   - Remove verbose logs
4. Retain only:
   - Phase metadata (100-200 tokens)
   - Artifact paths
   - Critical errors/warnings

Result: Phase N reduced from 5,000 tokens to 200 tokens (96% reduction)
```

Use `.claude/lib/workflow/context-pruning.sh` utilities:
```bash
# Prune subagent output after metadata extraction
prune_subagent_output "agent_response" "metadata"

# Prune completed phase data
prune_phase_metadata "$phase_number" "$plan_path"

# Apply workflow-specific pruning policy
apply_pruning_policy "$workflow_type"  # aggressive|moderate|conservative
```

### Technique 3: Forward Message Pattern

Pass metadata directly without re-summarization:

```markdown
❌ BAD - Re-summarization adds 500 tokens:
Based on the research findings, the key points are...
[Paraphrasing metadata unnecessarily]

✓ GOOD - Direct forwarding (0 additional tokens):
FORWARDING RESEARCH RESULTS:
{metadata from agent}

Proceeding to planning phase.
```

See [Forward Message Pattern](./forward-message.md) for complete details.

### Technique 4: Layered Context Architecture

Organize context into layers with different retention policies:

```markdown
Layer 1: Permanent (always retained)
- User request
- Workflow type
- Current phase
- Critical errors
Total: 500-1,000 tokens

Layer 2: Phase-Scoped (retained during phase, pruned after)
- Current phase instructions
- Agent invocations for this phase
- Verification checkpoints
Total: 2,000-4,000 tokens per phase

Layer 3: Metadata (retained between phases)
- Artifact paths
- Phase summaries
- Key findings
Total: 200-300 tokens per phase

Layer 4: Transient (pruned immediately after use)
- Full agent responses
- Detailed logs
- Intermediate calculations
Total: 0 tokens (pruned before next phase)

Context budget:
- Layer 1: 1,000 tokens (4%)
- Layer 2: 3,000 tokens (12%) - current phase only
- Layer 3: 1,500 tokens (6%) - 5 completed phases × 300 tokens
- Layer 4: 0 tokens (pruned)
Total: 5,500 tokens (22% context usage across 6 phases)
```

### Technique 5: Checkpoint-Based State

Store state externally, load on-demand:

```markdown
## Checkpoint Strategy

After each phase:
1. Write checkpoint file: .claude/data/checkpoints/workflow_id.json
2. Include full state: phase metadata, paths, decisions, errors
3. PRUNE state from context
4. On resume: Load checkpoint, extract only needed metadata

Benefit: Unlimited state storage, minimal context consumption
```

### Code Example

Real implementation from Plan 080 - /orchestrate with context management:

```markdown
## /orchestrate - Context Management Throughout Workflow

CONTEXT BUDGET: Target <30% usage across all 7 phases

### Phase 0: Initialization (Layer 1 - Permanent)
Tokens: 800

User request: "Implement OAuth 2.0 authentication"
Workflow type: end-to-end (research → implement → test → document)
Topic path: specs/027_authentication/

### Phase 1: Research (Layer 2 - Phase-scoped)
Tokens during phase: 3,200
Tokens after pruning: 400 (metadata only)

EXECUTE:
- Invoke 4 research agents in parallel
- Collect metadata returns (250 tokens × 4 = 1,000 tokens)
- Create research overview (300 tokens)
- PRUNE full agent responses (0 tokens retained)

CHECKPOINT:
research_metadata = {
  "reports": [4 report metadata objects],
  "overview_path": "specs/027_auth/reports/000_overview.md",
  "summary": "100-word synthesis"
}
# Tokens retained: 400

### Phase 2: Planning (Layer 2 - Phase-scoped)
Tokens during phase: 2,800
Tokens after pruning: 300 (metadata only)

CONTEXT USAGE SO FAR:
- Layer 1 (permanent): 800 tokens
- Layer 3 (research metadata): 400 tokens
- Layer 2 (planning phase): 2,800 tokens
Total: 4,000 tokens (16% context)

EXECUTE:
- Read research metadata (not full reports)
- Invoke planner with research context
- Collect plan metadata (300 tokens)
- PRUNE planning phase content

### Phases 3-7: Similar pruning strategy

FINAL CONTEXT USAGE:
- Layer 1 (permanent): 800 tokens
- Layer 3 (all phase metadata): 2,100 tokens (7 phases × 300 tokens)
- Layer 2 (current phase 7): 2,500 tokens
Total: 5,400 tokens (22% context usage)

Result: Completed 7-phase workflow in <30% context budget
```

## Context Usage Targets and Monitoring

### Usage Target: <30% Throughout Workflow Lifecycle

**Primary Goal**: Maintain context usage below 30% across entire workflow to ensure:
- Sufficient headroom for unexpected complexity
- Ability to recover from errors without context overflow
- Smooth workflow progression without pruning emergencies

**Measurement Points**:
```bash
# Check current context usage
/context  # Should show ≤30% during normal operation

# Automated monitoring (in workflow commands)
CURRENT_USAGE=$(get_context_usage_percentage)
if [ "$CURRENT_USAGE" -gt 30 ]; then
  log_warning "Context usage: ${CURRENT_USAGE}% (target: <30%)"
  trigger_aggressive_pruning
fi
```

### Warning Thresholds

**Green Zone** (<25%): Normal operation
- Continue workflow without intervention
- Standard pruning policies apply
- No warnings needed

**Yellow Zone** (25-30%): Approaching limit
- Log informational message
- Increase pruning frequency
- Consider phase simplification for remaining work

**Orange Zone** (30-40%): Exceeding target
- **WARNING**: Log visible warning to user
- Apply aggressive pruning immediately
- Consider hierarchical supervision if >4 agents
- Review workflow complexity

**Red Zone** (>40%): Critical
- **ERROR**: Workflow may fail soon
- Emergency pruning of all non-essential context
- MANDATORY hierarchical supervision
- Consider workflow splitting

### Pruning Triggers

**Automatic Triggers**:
1. **After Phase Completion**: Always prune phase-scoped context (Layer 2 → Layer 3)
2. **After Agent Completion**: Prune full agent response, retain metadata only
3. **Usage > 30%**: Trigger aggressive pruning pass
4. **Usage > 40%**: Emergency pruning + hierarchical supervision recommendation

**Manual Triggers**:
```bash
# Force pruning at any time
# Context pruning library not yet implemented
force_context_prune "aggressive"

# Workflow-specific pruning
apply_workflow_pruning_policy "$WORKFLOW_TYPE"
```

### Workflow-Specific Pruning Policies

**Research Workflow** (Aggressive Pruning):
- Target: <15% context usage
- Rationale: Multiple parallel agents, large report outputs
- Policy:
  ```bash
  - Prune full agent responses immediately
  - Retain 200-token metadata only
  - Forward message pattern mandatory
  - No research content in planning phase context
  ```

**Implementation Workflow** (Moderate Pruning):
- Target: <25% context usage
- Rationale: Sequential code changes, moderate complexity
- Policy:
  ```bash
  - Retain current file content during active editing
  - Prune completed file changes to metadata
  - Keep test results summary only (not full output)
  - Prune git diff after commit
  ```

**Validation Workflow** (Conservative Pruning):
- Target: <20% context usage
- Rationale: Need test failure context for debugging
- Policy:
  ```bash
  - Retain test failure messages and stack traces
  - Prune passing test outputs
  - Keep validation metadata for reporting
  - Retain error context for troubleshooting
  ```

### Hierarchical Supervision Integration

**Trigger Criteria**: Apply hierarchical supervision when:
1. Total agents ≥5 (flat supervision would exceed 30% context)
2. Context usage >30% with flat supervision
3. Workflow has complex inter-agent dependencies
4. Need specialized supervision logic (phase coordination, result synthesis)

**Context Benefits**:
```
Flat Supervision (6 agents):
- 6 agents × 10KB = 60KB overhead
- Orchestration logic: ~15KB
- Total: ~75KB ≈ 38% context ✗

Hierarchical Supervision (6 agents via 2 supervisors):
- 2 supervisors × 5KB = 10KB overhead
- 6 agents × metadata only = 3KB
- Orchestration logic: ~8KB
- Total: ~21KB ≈ 11% context ✓

Context Reduction: 38% → 11% (71% improvement)
```

**Implementation**:
```markdown
# When context usage >30% with multiple agents
if [ "$AGENT_COUNT" -ge 5 ] && [ "$CONTEXT_USAGE" -gt 30 ]; then
  echo "RECOMMENDATION: Switch to hierarchical supervision"
  echo "Expected context reduction: ~60-70%"
  echo "See: .claude/docs/architecture/state-based-orchestration-overview.md"
fi
```

**Case Study Reference**: Coordinate command migration (45% → 23% context usage via hierarchical supervision)

### Monitoring and Validation

**Pre-Workflow Validation**:
```bash
# Estimate context requirements before starting
estimate_workflow_context "$WORKFLOW_TYPE" "$AGENT_COUNT"
# Output: "Estimated context: 28% (within target)"

# If estimate >30%, recommend changes
if [ "$ESTIMATED" -gt 30 ]; then
  echo "WARNING: Estimated context $ESTIMATED% exceeds 30% target"
  echo "Consider: Hierarchical supervision, workflow simplification"
fi
```

**During-Workflow Monitoring**:
```bash
# Check context after each phase
log_context_usage "$PHASE_NUMBER" "$CURRENT_USAGE"

# Automated checkpoint with context tracking
save_checkpoint_with_context_metric "$CHECKPOINT_DATA" "$CONTEXT_USAGE"
```

**Post-Workflow Analysis**:
```bash
# Generate context usage report
generate_context_report "$WORKFLOW_ID"
# Output:
# Phase 1: 12%
# Phase 2: 18%
# Phase 3: 22%
# Peak: 22% (target: <30%) ✓
```

### Cross-References

**Library Implementation**:
- `.claude/lib/workflow/context-pruning.sh` - Context pruning utilities
- `.claude/lib/workflow/checkpoint-utils.sh` - Checkpoint-based state management

**Related Patterns**:
- [Hierarchical Supervision](../../architecture/state-based-orchestration-overview.md) - Scalability for >4 agents
- [Metadata Extraction Pattern](metadata-extraction.md) - Condensing agent outputs
- [Forward Message Pattern](forward-message.md) - Zero-cost metadata passing

**Decision Framework**:
- [Architectural Decision Framework](../architectural-decision-framework.md) - Decision 2: Flat vs Hierarchical Supervision

## Anti-Patterns

### Violation 1: No Pruning

```markdown
❌ BAD - Retaining full content:

Phase 1 complete. Research results:
[Full 5,000-token research report]

Phase 2 complete. Plan created:
[Full 3,000-token plan]

Phase 3 complete. Implementation:
[Full 8,000-token implementation log]

Total: 16,000 tokens (64% context) - cannot proceed to Phase 4
```

### Violation 2: Excessive Re-Summarization

```markdown
❌ BAD - Adding 500 tokens per re-summarization:

Phase 1: Research complete
Summary: Based on the research findings...
[500 tokens paraphrasing metadata]

Phase 2: Planning complete
Summary: The plan incorporates research insights...
[500 tokens paraphrasing plan]

Unnecessary overhead: 1,000 tokens (4%)
```

### Violation 3: No Layering

```markdown
❌ BAD - Flat context (everything equal priority):

User request + research + planning + implementation all at same retention level
No distinction between permanent, phase-scoped, and transient data
Cannot selectively prune - must keep everything or lose critical context
```

## Performance Impact

**Context Reduction Metrics (Plan 077 & 080):**

| Workflow | Without Management | With Management | Reduction |
|----------|-------------------|-----------------|-----------|
| 4-agent research | 20,000 tokens (80%) | 1,000 tokens (4%) | 95% |
| 7-phase /orchestrate | 40,000 tokens (160% overflow) | 7,000 tokens (28%) | 82% |
| Hierarchical (3 levels) | 60,000 tokens (240% overflow) | 4,000 tokens (16%) | 93% |

**Scalability Improvements:**
- Phases supported: 2-3 → 7-10
- Agents coordinated: 2-4 → 10-30
- Workflow completion rate: 40% → 100% (no context overflows)

## Related Patterns

- [Metadata Extraction](./metadata-extraction.md) - Primary context reduction technique
- [Forward Message Pattern](./forward-message.md) - Prevents re-summarization overhead
- [Hierarchical Supervision](./hierarchical-supervision.md) - Distributes context across supervision levels
- [Checkpoint Recovery](./checkpoint-recovery.md) - External state storage

## See Also

- [Performance Measurement Guide](../../guides/patterns/performance-optimization.md) - Measuring context usage
- [Hierarchical Agents Guide](../hierarchical-agents.md) - Multi-agent context strategies
- `.claude/lib/workflow/context-pruning.sh` - Pruning utilities
- `.claude/lib/core/unified-logger.sh` - Efficient logging with minimal context impact
