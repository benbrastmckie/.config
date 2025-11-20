# Hierarchical Supervision Pattern

**Path**: docs → concepts → patterns → hierarchical-supervision.md

[Used by: /orchestrate, /plan, /debug, multi-agent workflows coordinating 5+ agents]

Multi-level agent coordination with recursive supervision enables coordination of 10+ agents across 3 hierarchical levels.

## Definition

Hierarchical Supervision is a pattern where supervisor agents coordinate sub-supervisors or worker agents through metadata-only communication, enabling recursive multi-level coordination. This allows complex workflows to scale beyond the 2-4 agent limit by distributing coordination responsibilities across supervisor levels.

The pattern creates a supervision tree:
- **Level 1**: Primary supervisor (coordinates 2-4 sub-supervisors)
- **Level 2**: Sub-supervisors (each coordinates 2-4 workers)
- **Level 3**: Worker agents (execute tasks)

Maximum depth: 3 levels (prevents excessive abstraction overhead)

## Rationale

### Why This Pattern Matters

Flat multi-agent coordination (one supervisor managing all workers) fails at scale:

1. **Context Overflow**: Even with metadata extraction, coordinating 10+ agents directly exceeds supervisor context capacity
2. **Complexity Management**: Single supervisor must understand all task details across diverse domains
3. **Coordination Overhead**: Supervisor spends excessive context on task delegation vs high-level orchestration
4. **Sequential Bottleneck**: Supervisor must invoke agents sequentially (cannot parallelize at scale)

### Problems Solved

- **Scalability**: Coordinate 10-30 agents (vs 2-4 without hierarchy)
- **Domain Specialization**: Sub-supervisors provide domain expertise (e.g., frontend sub-supervisor coordinates UI agents)
- **Parallel Execution**: Sub-supervisors run in parallel, each managing their worker pool
- **Context Distribution**: Distribute coordination load across supervisor levels

## Implementation

### Core Mechanism

**Level 1: Primary Supervisor (Orchestrator)**

Coordinates sub-supervisors, not individual workers:

```markdown
## YOUR ROLE: Primary Supervisor

You coordinate sub-supervisors who manage specialized worker agents.

DO NOT invoke worker agents directly.
ONLY invoke sub-supervisors via Task tool.

## Phase 1: Research Coordination

INVOKE SUB-SUPERVISORS (Parallel):

1. Research Sub-Supervisor (coordinates 4 research-specialist agents)
   Task tool: {
     "agent": "research-sub-supervisor",
     "task": "Coordinate research on 4 topics: OAuth, Security, Performance, Testing",
     "context": {
       "topics": ["OAuth patterns", "Security analysis", "Performance optimization", "Testing strategies"],
       "output_dir": "specs/027_auth/reports/",
       "supervision_level": 2,
       "max_workers": 4
     }
   }

2. Analysis Sub-Supervisor (coordinates 3 analyzer agents)
   Task tool: {
     "agent": "analysis-sub-supervisor",
     "task": "Coordinate analysis of existing codebase for 3 components",
     "context": {
       "components": ["auth module", "session management", "API routes"],
       "output_dir": "specs/027_auth/analysis/",
       "supervision_level": 2,
       "max_workers": 3
     }
   }

EXPECTED RETURNS (metadata aggregation from sub-supervisors):
- Research sub-supervisor: {summary of 4 research reports, paths[]}
- Analysis sub-supervisor: {summary of 3 analyses, paths[]}

Total agents coordinated: 7 workers across 2 sub-supervisors
```

**Level 2: Sub-Supervisor**

Coordinates worker agents within specialized domain:

```markdown
## YOUR ROLE: Research Sub-Supervisor

You coordinate research-specialist worker agents for your assigned topics.

You are at supervision level 2 (managed by primary supervisor).

DO NOT create research reports yourself.
ONLY coordinate worker agents who create reports.

## Research Coordination

FOR EACH of 4 topics, invoke research-specialist in parallel:

Topic 1 (OAuth patterns):
  Task tool: {
    "agent": "research-specialist",
    "task": "Research OAuth 2.0 patterns for Node.js APIs",
    "context": {
      "output_path": "specs/027_auth/reports/001_oauth_patterns.md",
      "focus": "Implementation patterns, security, integration",
      "depth": "detailed"
    }
  }

Topic 2 (Security analysis):
  Task tool: {
    "agent": "research-specialist",
    "task": "Research OAuth security best practices",
    "context": {
      "output_path": "specs/027_auth/reports/002_security.md",
      "focus": "Attack vectors, mitigation, secure storage",
      "depth": "detailed"
    }
  }

[Topics 3-4 similar structure]

## Metadata Aggregation

Collect metadata from all 4 worker agents:
{
  "sub_supervisor": "research-sub-supervisor",
  "workers_coordinated": 4,
  "reports_created": [
    {"path": "specs/027_auth/reports/001_oauth_patterns.md", "summary": "..."},
    {"path": "specs/027_auth/reports/002_security.md", "summary": "..."},
    {"path": "specs/027_auth/reports/003_performance.md", "summary": "..."},
    {"path": "specs/027_auth/reports/004_testing.md", "summary": "..."}
  ],
  "aggregate_summary": "100-word synthesis of all 4 research reports",
  "key_findings": ["finding 1", "finding 2", "finding 3"],
  "recommendations": ["rec 1", "rec 2", "rec 3"]
}

Return this metadata to primary supervisor (DO NOT include full report contents).
```

**Level 3: Worker Agents**

Execute tasks and return metadata:

```markdown
## YOUR ROLE: Research-Specialist Worker

You create research reports per assigned topic.

You are at supervision level 3 (managed by sub-supervisor).

Execute research, create report, return metadata only.

[Standard research-specialist agent instructions]

COMPLETION PROTOCOL:
Return metadata to sub-supervisor:
{
  "report_path": "specs/027_auth/reports/001_oauth_patterns.md",
  "title": "OAuth 2.0 Authentication Patterns",
  "summary": "50-word summary...",
  "key_findings": [...],
  "recommendations": [...]
}
```

### Code Example

Real implementation from Plan 080 - /orchestrate with recursive supervision:

```markdown
## /orchestrate Command - Hierarchical Research Phase

YOU ARE THE PRIMARY SUPERVISOR (Level 1).
You coordinate sub-supervisors who manage worker agents.

## Phase 1: Multi-Domain Research (10+ topics)

DOMAIN DECOMPOSITION:

Domain 1: Technical Research (5 topics)
  - Sub-supervisor: technical-research-supervisor
  - Workers: 5× research-specialist agents
  - Topics: Architecture, Implementation, Testing, Performance, Security

Domain 2: Integration Research (4 topics)
  - Sub-supervisor: integration-research-supervisor
  - Workers: 4× research-specialist agents
  - Topics: API design, Database schema, Authentication flow, Error handling

Domain 3: Documentation Research (3 topics)
  - Sub-supervisor: docs-research-supervisor
  - Workers: 3× research-specialist agents
  - Topics: User guides, API docs, Migration guides

## Supervision Tree

Primary Supervisor (/orchestrate)
├── Technical Research Sub-Supervisor
│   ├── Worker 1 (Architecture research)
│   ├── Worker 2 (Implementation research)
│   ├── Worker 3 (Testing research)
│   ├── Worker 4 (Performance research)
│   └── Worker 5 (Security research)
├── Integration Research Sub-Supervisor
│   ├── Worker 6 (API design research)
│   ├── Worker 7 (Database schema research)
│   ├── Worker 8 (Auth flow research)
│   └── Worker 9 (Error handling research)
└── Docs Research Sub-Supervisor
    ├── Worker 10 (User guides research)
    ├── Worker 11 (API docs research)
    └── Worker 12 (Migration guides research)

Total: 12 worker agents across 3 sub-supervisors (3-level hierarchy)

## Execution

INVOKE SUB-SUPERVISORS IN PARALLEL (Level 2):

Task tool (parallel invocations):
{
  "agent": "technical-research-supervisor",
  "task": "Coordinate 5 research workers for technical topics",
  "context": { "topics": [...], "output_dir": "specs/NNN/reports/technical/" }
}

{
  "agent": "integration-research-supervisor",
  "task": "Coordinate 4 research workers for integration topics",
  "context": { "topics": [...], "output_dir": "specs/NNN/reports/integration/" }
}

{
  "agent": "docs-research-supervisor",
  "task": "Coordinate 3 research workers for documentation topics",
  "context": { "topics": [...], "output_dir": "specs/NNN/reports/docs/" }
}

## Metadata Aggregation

Each sub-supervisor returns:
{
  "domain": "technical",
  "workers": 5,
  "reports": [metadata × 5],
  "domain_summary": "100-word synthesis of technical research",
  "key_findings": [...]
}

Primary supervisor aggregates all 3 domain summaries (300 words total)
vs reading 12 full reports (60,000 tokens).

Context reduction: 99% (60,000 tokens → 600 tokens)
```

### Usage Context

**When to Apply:**
- Workflows coordinating 5+ agents
- Multi-domain tasks requiring specialized coordination
- Research phases with 6+ parallel topics
- Complex implementations requiring frontend + backend + database + testing coordination

**When Not to Apply:**
- Simple workflows (1-4 agents) - use flat coordination
- Single-domain tasks - direct worker invocation
- Workflows where all agents are identical - batch processing sufficient

## Anti-Patterns

### Example Violation 1: Flat Coordination at Scale

```markdown
❌ BAD - Primary supervisor coordinating 12 workers directly:

## Phase 1: Research (12 topics)

FOR EACH of 12 topics, invoke research-specialist:
  Task 1: OAuth patterns
  Task 2: Security analysis
  Task 3: Performance optimization
  [Tasks 3-12...]

[Context overflow: Managing 12 distinct task contexts]
```

**Why This Fails:**
1. Supervisor context consumed by 12 task specifications
2. Cannot parallelize effectively (sequential invocations)
3. No domain expertise (generic coordination)
4. Exceeds recommended 4-agent flat coordination limit

### Example Violation 2: Excessive Hierarchy Depth

```markdown
❌ BAD - 5-level hierarchy:

Level 1: Primary supervisor
Level 2: Domain sub-supervisor
Level 3: Sub-domain supervisor
Level 4: Task coordinator
Level 5: Worker agents

[Too much abstraction overhead]
```

**Why This Fails:**
1. Each level adds coordination overhead
2. Excessive metadata passing (5 levels of summaries)
3. Difficult to debug (failure could be at any of 5 levels)
4. Violates 3-level maximum guideline

### Example Violation 3: Workers at Multiple Levels

```markdown
❌ BAD - Mixing workers across levels:

Level 1: Primary supervisor
  - Invokes sub-supervisor for research (Level 2)
  - Directly invokes planner-specialist worker (Level 3)

[Inconsistent coordination pattern]
```

**Why This Fails:**
1. Violates hierarchical separation
2. Primary supervisor manages both sub-supervisors and workers
3. Cannot benefit from domain specialization
4. Confusing delegation model

## Testing Validation

### Validation Script

```bash
#!/bin/bash
# .claude/tests/validate_hierarchical_supervision.sh

COMMAND_FILE="$1"

echo "Validating hierarchical supervision pattern in $COMMAND_FILE..."

# Check 1: Supervision level documented
if ! grep -q "supervision.*level\|Level [1-3]" "$COMMAND_FILE"; then
  echo "⚠️  WARNING: Supervision level not documented"
fi

# Check 2: Maximum 3 levels
max_level=$(grep -oE "Level [0-9]|supervision.*level.*[0-9]" "$COMMAND_FILE" | grep -oE "[0-9]" | sort -rn | head -1)
if [ "$max_level" -gt 3 ]; then
  echo "❌ VIOLATION: Hierarchy exceeds 3 levels (found: $max_level)"
  exit 1
fi

# Check 3: Sub-supervisor invocations present
if grep -q "sub-supervisor\|Sub-Supervisor" "$COMMAND_FILE"; then
  echo "✓ Sub-supervisor pattern detected"
fi

# Check 4: Metadata aggregation at each level
if ! grep -q "aggregate.*metadata\|Metadata Aggregation" "$COMMAND_FILE"; then
  echo "⚠️  WARNING: Metadata aggregation not documented"
fi

echo "✓ Hierarchical supervision pattern validated"
```

### Expected Results

**Compliant Implementation:**
- Maximum 3 supervision levels
- 10-30 worker agents coordinated
- Metadata-only passing between levels
- Domain-specialized sub-supervisors
- <30% context usage across all levels

**Performance Metrics:**
- Agent coordination: 10-30 agents (vs 2-4 flat)
- Context usage: <30% (vs 80-100% flat at scale)
- Parallel execution: Sub-supervisors run concurrently

## Performance Impact

### Measurable Improvements

**Scalability (Agents Coordinated):**
- Flat coordination: 2-4 agents maximum
- 2-level hierarchy: 8-16 agents (4 sub-supervisors × 4 workers each)
- 3-level hierarchy: 16-64 agents (4 sub-supervisors × 4 sub-sub-supervisors × 4 workers)

**Context Reduction (10-agent workflow):**
- Flat: 10 agents × 250 tokens (metadata) = 2,500 tokens (10%)
- Hierarchical (2 levels): 2 sub-supervisors × 500 tokens = 1,000 tokens (4%)

**Real-World Example (Plan 080):**
- Workflow: /orchestrate with 12 research topics
- Before: Limited to 4 topics (flat coordination)
- After: 12 topics across 3 sub-supervisors (hierarchical)
- Time savings: 60% (parallel sub-supervisor execution)

## Related Patterns

- [Behavioral Injection](./behavioral-injection.md) - Enables hierarchical delegation through role clarification
- [Metadata Extraction](./metadata-extraction.md) - Essential for scalable hierarchical communication
- [Forward Message Pattern](./forward-message.md) - Sub-supervisors forward worker metadata without re-summarization
- [Parallel Execution](./parallel-execution.md) - Sub-supervisors execute in parallel for time savings

## See Also

- [Hierarchical Agents Guide](../hierarchical-agents.md) - Complete architectural documentation
- [Orchestration Guide](../../workflows/orchestration-guide.md) - Full workflow patterns
- [Creating Agents Guide](../../guides/development/agent-development/agent-development-fundamentals.md) - Sub-supervisor development
- [Performance Measurement Guide](../../guides/patterns/performance-optimization.md) - Measuring hierarchical efficiency
