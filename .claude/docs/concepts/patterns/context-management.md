# Context Management Pattern

[Used by: all commands, agents, and multi-phase workflows]

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

Use `.claude/lib/context-pruning.sh` utilities:
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

- [Performance Measurement Guide](../../guides/performance-measurement.md) - Measuring context usage
- [Hierarchical Agents Guide](../hierarchical-agents.md) - Multi-agent context strategies
- `.claude/lib/context-pruning.sh` - Pruning utilities
- `.claude/lib/unified-logger.sh` - Efficient logging with minimal context impact
