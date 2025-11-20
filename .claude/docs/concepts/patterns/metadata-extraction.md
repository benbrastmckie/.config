# Metadata Extraction Pattern

**Path**: docs → concepts → patterns → metadata-extraction.md

[Used by: /orchestrate, /implement, /plan, research-specialist, planner-specialist, all hierarchical agents]

Extract title + 50-word summary + paths from reports and plans for 95-99% context reduction in multi-agent workflows.

## Definition

Metadata Extraction is a pattern where agents return condensed metadata (title, summary, file paths, key recommendations) instead of full document content. This enables hierarchical multi-agent coordination by reducing context window consumption from thousands of tokens to hundreds, allowing supervisors to coordinate many agents without hitting context limits.

The pattern transforms agent outputs from:
- **Before**: Full report content (5,000-10,000 tokens)
- **After**: Structured metadata (200-300 tokens)

## Rationale

### Why This Pattern Matters

Multi-agent workflows fail at scale without metadata extraction:

1. **Context Explosion**: 4 research agents returning full reports consume 20,000-40,000 tokens, leaving no room for planning, implementation, or debugging phases.

2. **Nested Bloat**: Hierarchical supervision (supervisor → sub-supervisors → workers) compounds context usage exponentially. Each level duplicates full content from lower levels.

3. **Coordination Limits**: Without metadata extraction, supervisors can coordinate 2-3 agents maximum before hitting context limits. With metadata extraction, 10+ agents across 3 hierarchical levels.

### Problems Solved

- **Scalability**: Coordinate 10+ agents instead of 2-3
- **Hierarchical Depth**: Support 3-level supervision (supervisor → sub-supervisor → workers)
- **Context Budget**: Maintain <30% context usage throughout workflows
- **Information Density**: Preserve key findings while discarding verbose explanations

## Implementation

### Core Mechanism

**Step 1: Agent Execution with Metadata Return**

Agents create full artifacts (reports, plans) but return only metadata:

```markdown
## AGENT COMPLETION PROTOCOL (REQUIRED)

After creating the artifact, you MUST return ONLY this metadata structure:

{
  "artifact_path": "/absolute/path/to/artifact.md",
  "title": "Extracted from first # heading",
  "summary": "First 50 words from Executive Summary or opening paragraph",
  "key_findings": [
    "Finding 1 (1 sentence)",
    "Finding 2 (1 sentence)",
    "Finding 3 (1 sentence)"
  ],
  "recommendations": [
    "Top recommendation 1",
    "Top recommendation 2",
    "Top recommendation 3"
  ],
  "file_paths": [
    "/path/to/referenced/file1.sh",
    "/path/to/referenced/file2.md"
  ]
}

DO NOT include full artifact content in your response.
The supervisor will read the artifact file directly if detailed content is needed.
```

**Step 2: Metadata Extraction via Utility Functions**

Use `.claude/lib/workflow/metadata-extraction.sh` for consistent extraction:

```bash
# Extract report metadata
extract_report_metadata "/path/to/report.md"

# Returns JSON:
# {
#   "title": "OAuth 2.0 Authentication Patterns",
#   "summary": "This report analyzes OAuth 2.0 implementation patterns for Node.js APIs, focusing on security best practices and integration strategies...",
#   "file_paths": [".claude/lib/auth-utils.sh", "src/auth/oauth.js"],
#   "recommendations": ["Use refresh token rotation", "Implement token expiration"],
#   "path": "/path/to/report.md",
#   "size": 15420
# }

# Extract plan metadata
extract_plan_metadata "/path/to/plan.md"

# Returns JSON:
# {
#   "title": "OAuth Implementation Plan",
#   "phases": 5,
#   "complexity": 7.2,
#   "estimated_time": "12-16 hours",
#   "high_complexity_phases": [2, 4],
#   "path": "/path/to/plan.md"
# }
```

**Step 3: Forward Message Pattern**

Supervisors forward metadata directly without re-summarization:

```markdown
## Research Phase Complete

I've received research results from 4 parallel agents.

FORWARDING AGENT RESULTS (no re-summarization):

Agent 1 (OAuth Patterns):
{
  "artifact_path": "specs/027_auth/reports/001_oauth_patterns.md",
  "summary": "OAuth 2.0 provides secure authorization through token-based authentication...",
  "recommendations": ["Use PKCE flow", "Implement refresh rotation"]
}

Agent 2 (Security Considerations):
{
  "artifact_path": "specs/027_auth/reports/002_security.md",
  "summary": "Security analysis identifies three critical attack vectors...",
  "recommendations": ["Validate redirect URIs", "Use state parameter"]
}

Proceeding to planning phase with these findings.
```

### Code Example

Real implementation from Plan 077 - research-specialist agent:

```markdown
## RESEARCH COMPLETION PROTOCOL

After saving your research report, return ONLY this metadata:

METADATA ONLY - DO NOT INCLUDE FULL REPORT CONTENT:
{
  "report_path": "<absolute path to saved report>",
  "title": "<extracted from first # heading>",
  "summary": "<first 50 words from Executive Summary section>",
  "key_findings": [
    "<critical finding 1 in one sentence>",
    "<critical finding 2 in one sentence>",
    "<critical finding 3 in one sentence>"
  ],
  "recommendations": [
    "<top recommendation 1>",
    "<top recommendation 2>",
    "<top recommendation 3>"
  ],
  "file_paths": [
    "<path to relevant file 1>",
    "<path to relevant file 2>"
  ],
  "size": <file size in bytes>
}

CRITICAL: The supervisor will read the full report file if needed.
Your response should contain ONLY the metadata above (200-300 tokens).
```

Supervisor processing (from /orchestrate):

```markdown
## Phase 1: Research Aggregation

EXECUTE NOW:

1. Collect metadata from all 4 research agents (Task tool responses)
2. DO NOT re-summarize agent responses
3. Forward metadata directly to Phase 2 (planning)
4. Store metadata in checkpoint for recovery

Example metadata aggregation:
research_results = [
  agent_1_metadata,  # 250 tokens
  agent_2_metadata,  # 220 tokens
  agent_3_metadata,  # 280 tokens
  agent_4_metadata   # 240 tokens
]
# Total: 990 tokens (vs 30,000 tokens for full reports)
```

### Usage Context

**When to Apply:**
- Any agent that creates reports, plans, or documents
- Hierarchical supervision (supervisor → subagents)
- Multi-phase workflows (research → planning → implementation)
- Parallel agent execution (2+ agents running concurrently)

**When Not to Apply:**
- Single-agent workflows with no coordination
- Agents that only modify existing files (no new artifacts)
- Utility agents that perform calculations and return small results

## Anti-Patterns

### Example Violation 1: Returning Full Content

```markdown
❌ BAD - Agent returning full report:

## Research Complete

Here's my full research report:

# OAuth 2.0 Authentication Patterns

## Executive Summary
[500 words of detailed analysis...]

## OAuth 2.0 Flow Overview
[1,000 words explaining flows...]

## Implementation Patterns
[2,000 words with code examples...]

[Full 5,000-token report included in response]
```

**Why This Fails:**
1. Consumes 5,000 tokens in supervisor context
2. With 4 research agents, supervisor context = 20,000 tokens (80%)
3. No room for planning, implementation, or debugging phases
4. Cannot add more agents without hitting context limits

### Example Violation 2: Re-Summarization

```markdown
❌ BAD - Supervisor re-summarizing subagent metadata:

## Research Phase Complete

I've analyzed the 4 research reports and summarized the key findings:

Based on Agent 1's OAuth patterns analysis, the main recommendations are to use PKCE flow and implement refresh token rotation for improved security. Agent 2 identified three critical attack vectors including redirect URI validation and state parameter usage...

[Supervisor paraphrasing metadata unnecessarily - adds 500 tokens]
```

**Why This Fails:**
1. Adds 500+ tokens of redundant paraphrasing
2. Loses precision from original metadata
3. Introduces summarization errors
4. Violates forward message pattern

### Example Violation 3: Incomplete Metadata

```markdown
❌ BAD - Missing critical metadata fields:

## Research Complete

{
  "report_path": "specs/027_auth/reports/001_oauth.md"
}
```

**Why This Fails:**
1. Supervisor must read full file to get summary (defeats context reduction)
2. No key findings for quick decision-making
3. No file paths for dependency tracking
4. Incomplete metadata format inconsistency

## Testing Validation

### Validation Script

```bash
#!/bin/bash
# .claude/tests/validate_metadata_extraction.sh

AGENT_FILE="$1"

echo "Validating metadata extraction pattern in $AGENT_FILE..."

# Check 1: Completion protocol present
if ! grep -q "METADATA ONLY" "$AGENT_FILE" && \
   ! grep -q "return ONLY this metadata" "$AGENT_FILE"; then
  echo "❌ MISSING: Metadata-only return protocol"
  exit 1
fi

# Check 2: Required metadata fields documented
required_fields=("artifact_path" "title" "summary" "key_findings" "recommendations")
for field in "${required_fields[@]}"; do
  if ! grep -q "\"$field\":" "$AGENT_FILE"; then
    echo "❌ MISSING: Metadata field '$field'"
    exit 1
  fi
done

# Check 3: Anti-pattern warnings present
if ! grep -q "DO NOT include full.*content" "$AGENT_FILE"; then
  echo "⚠️  WARNING: No explicit anti-full-content warning"
fi

# Check 4: Word count limit specified
if ! grep -E "(50|100) words" "$AGENT_FILE"; then
  echo "⚠️  WARNING: No summary word count limit specified"
fi

echo "✓ Metadata extraction pattern validated"
```

### Expected Results

**Compliant Agent:**
- Returns metadata JSON with all required fields
- Metadata size: 200-300 tokens
- Full artifact saved to specified path
- Supervisor can coordinate 10+ agents

**Non-Compliant Agent:**
- Returns full artifact content in response
- Response size: 5,000-10,000 tokens
- Supervisor limited to 2-3 agents before context overflow

### Performance Test

```bash
# Test context reduction
research_specialist_full_output_tokens=5000
research_specialist_metadata_tokens=250

context_reduction=$((100 - (metadata_tokens * 100 / full_output_tokens)))
echo "Context reduction: ${context_reduction}%" # Expected: 95%

# Test scalability
max_agents_without_metadata=$((100000 / full_output_tokens))  # ~20 agents
max_agents_with_metadata=$((100000 / metadata_tokens))         # ~400 agents
echo "Scalability improvement: ${max_agents_with_metadata}x" # Expected: 20x
```

## Performance Impact

### Measurable Improvements

**Context Reduction (Real Metrics from Plan 077):**
- Research agent output: 5,000 tokens → 250 tokens (95% reduction)
- 4 parallel research agents: 20,000 tokens → 1,000 tokens (95% reduction)
- Hierarchical supervision (3 levels): 60,000 tokens → 3,000 tokens (95% reduction)

**Agent Coordination Scalability:**
- Before: 2-3 agents maximum per supervisor (context overflow)
- After: 10+ agents per supervisor (with metadata extraction)
- Recursive supervision: 10+ agents across 3 hierarchical levels (30+ total agents)

**Workflow Context Budget:**
- Before: 80-100% context usage (research + planning phases)
- After: <30% context usage (all 7 phases in /orchestrate)

### Real-World Example (Plan 080)

**Before metadata extraction:**
```
/orchestrate workflow:
- Phase 1 (Research): 4 agents × 5,000 tokens = 20,000 tokens (80%)
- Cannot proceed to planning (context overflow)
- Must reduce to 2 research agents
- Sequential execution required (no parallelization)
```

**After metadata extraction:**
```
/orchestrate workflow:
- Phase 1 (Research): 4 agents × 250 tokens = 1,000 tokens (4%)
- Phase 2 (Planning): 1 agent × 300 tokens = 300 tokens (1%)
- Phase 3 (Implementation): Waves × 200 tokens = 800 tokens (3%)
- Phases 4-7: 2,000 tokens (8%)
- Total: 4,100 tokens (16% context usage)
- Parallel execution: 4 research agents + wave-based implementation
```

## Related Patterns

- [Behavioral Injection](./behavioral-injection.md) - Injects artifact paths for metadata extraction
- [Forward Message Pattern](./forward-message.md) - Passes extracted metadata without re-summarization
- [Hierarchical Supervision](./hierarchical-supervision.md) - Requires metadata extraction for multi-level coordination
- [Context Management](./context-management.md) - Metadata extraction is core context reduction technique

## See Also

- [Hierarchical Agents Guide](../hierarchical-agents.md) - Complete agent coordination architecture
- [Performance Measurement Guide](../../guides/patterns/performance-optimization.md) - How to measure context reduction
- [Creating Agents Guide](../../guides/development/agent-development/agent-development-fundamentals.md) - Agent development best practices
- `.claude/lib/workflow/metadata-extraction.sh` - Utility functions for metadata extraction
