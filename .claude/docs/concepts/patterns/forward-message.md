# Forward Message Pattern

**Path**: docs → concepts → patterns → forward-message.md

[Used by: /orchestrate, /implement, /plan, all supervisor agents coordinating subagents]

Direct subagent response passing without paraphrasing preserves detail and eliminates re-summarization overhead.

## Definition

Forward Message Pattern is a communication technique where supervisor agents pass subagent responses directly to subsequent phases or the user without re-summarizing, paraphrasing, or interpreting the content. This preserves the precision of subagent outputs while eliminating redundant summarization overhead (200-500 tokens per forwarding).

Key principle: Subagents already return metadata in structured format. Supervisors should forward this structure unchanged, not rewrite it in their own words.

## Rationale

### Why This Pattern Matters

Re-summarization is wasteful and error-prone:

1. **Redundancy**: Subagent already provided 50-word summary → supervisor rewrites in 100 words → net increase of 50 tokens
2. **Information Loss**: Supervisor paraphrasing loses precision from original metadata
3. **Interpretation Errors**: Supervisor may misinterpret subagent findings and introduce inaccuracies
4. **Context Bloat**: 4 subagents × 200 tokens re-summarization = 800 tokens wasted

With forward message pattern:
- Zero redundancy (subagent metadata forwarded as-is)
- Zero information loss (original precision preserved)
- Zero interpretation errors (no paraphrasing)
- Minimal context overhead (0 additional tokens per forwarding)

## Implementation

### Core Mechanism

**Step 1: Receive Structured Metadata from Subagent**

```markdown
## Subagent Response

Agent: research-specialist
Task: Research OAuth 2.0 patterns

Response (metadata only):
{
  "report_path": "specs/027_auth/reports/001_oauth_patterns.md",
  "title": "OAuth 2.0 Authentication Patterns for Node.js",
  "summary": "OAuth 2.0 provides secure authorization through token-based authentication with support for refresh tokens, PKCE flow, and SSO integration. Implementation requires careful handling of redirect URIs and state parameters.",
  "key_findings": [
    "PKCE flow prevents authorization code interception",
    "Refresh token rotation improves security",
    "State parameter prevents CSRF attacks"
  ],
  "recommendations": [
    "Use PKCE for public clients",
    "Implement refresh token rotation",
    "Validate redirect URIs against whitelist"
  ]
}
```

**Step 2: Forward Response Directly (No Paraphrasing)**

```markdown
✓ GOOD - Direct forwarding:

## Research Phase Complete

FORWARDING SUBAGENT RESULTS (no modification):

Research Agent 1 (OAuth patterns):
{
  "report_path": "specs/027_auth/reports/001_oauth_patterns.md",
  "title": "OAuth 2.0 Authentication Patterns for Node.js",
  "summary": "OAuth 2.0 provides secure authorization through token-based authentication...",
  "key_findings": [...],
  "recommendations": [...]
}

Proceeding to planning phase with these findings.

---

❌ BAD - Re-summarization:

## Research Phase Complete

Based on the research agent's findings, OAuth 2.0 is a secure authorization framework that uses tokens for authentication. The main recommendations are to use PKCE flow for security and implement refresh token rotation. The research identified several key security considerations including redirect URI validation and CSRF protection via state parameters.

[Added 100 tokens of redundant paraphrasing]
```

**Step 3: Multi-Agent Forwarding**

```markdown
## Multiple Subagent Results

FORWARDING ALL SUBAGENT RESULTS:

Agent 1 (OAuth patterns):
{metadata object}

Agent 2 (Security analysis):
{metadata object}

Agent 3 (Performance optimization):
{metadata object}

Agent 4 (Testing strategies):
{metadata object}

All research complete. Proceeding to planning phase.

Total overhead: ~50 tokens (transition text)
vs Re-summarization: ~800 tokens (4 agents × 200 tokens each)
Savings: 750 tokens (94%)
```

### Code Example

Real implementation from Plan 080 - /orchestrate with forward message pattern:

```markdown
## /orchestrate - Phase 1: Research Results Forwarding

### Subagent Completion

4 research agents have completed. Responses received:

Agent 1: {metadata object with 250 tokens}
Agent 2: {metadata object with 220 tokens}
Agent 3: {metadata object with 280 tokens}
Agent 4: {metadata object with 240 tokens}

Total: 990 tokens of metadata

### Forwarding Protocol (MANDATORY)

DO NOT re-summarize subagent results.
DO NOT paraphrase metadata in your own words.
DO NOT extract "key points" and rewrite them.

FORWARD DIRECTLY:

---
RESEARCH PHASE RESULTS:

Agent 1 (OAuth patterns):
{paste Agent 1 metadata object exactly}

Agent 2 (Security analysis):
{paste Agent 2 metadata object exactly}

Agent 3 (Performance optimization):
{paste Agent 3 metadata object exactly}

Agent 4 (Testing strategies):
{paste Agent 4 metadata object exactly}
---

Proceeding to Phase 2 (Planning) with these research findings.

Total overhead: 50 tokens (headers + transition)
Total tokens: 990 (metadata) + 50 (overhead) = 1,040 tokens

COMPARISON - If re-summarized:
- Original metadata: 990 tokens
- Re-summarization: 800 tokens (4 × 200 tokens paraphrasing)
- Total: 1,790 tokens (72% more than forward message)
- Information loss: Medium (paraphrasing loses precision)
- Error introduction: Risk of misinterpretation
```

## Anti-Patterns

### Violation 1: Unnecessary Paraphrasing

```markdown
❌ BAD - Supervisor rewrites metadata:

Subagent metadata:
{
  "summary": "OAuth 2.0 provides secure authorization through token-based authentication...",
  "key_findings": ["PKCE flow prevents authorization code interception", ...]
}

Supervisor response:
"The research indicates that OAuth 2.0 is a security-focused authorization system
that relies on tokens. One important finding is that PKCE helps prevent code theft."

Problems:
1. "provides secure authorization" → "security-focused authorization system" (synonym, no added value)
2. "prevents authorization code interception" → "helps prevent code theft" (less precise)
3. Added 80 tokens of paraphrasing for no benefit
```

### Violation 2: Extractive Re-Summarization

```markdown
❌ BAD - Extracting and rewriting key points:

Subagent returned 3 key_findings in structured format.
Supervisor extracts these and rewrites as prose:

"The main findings from the research are threefold. First, PKCE flow
provides security benefits. Second, refresh token rotation is recommended.
Third, state parameters help with CSRF protection."

Problems:
1. Original metadata already in structured, precise format
2. Prose rewrite adds 60 tokens
3. "provides security benefits" less precise than "prevents authorization code interception"
4. Lost structured format (harder for subsequent agents to parse)
```

### Violation 3: Interpretation Injection

```markdown
❌ BAD - Supervisor adding interpretation:

Subagent: "PKCE flow prevents authorization code interception"

Supervisor: "The research strongly recommends PKCE flow due to its critical
security benefits in preventing code theft, which is a major vulnerability."

Problems:
1. "strongly recommends" (interpretation) vs factual statement
2. "critical security benefits" (subjective) vs "prevents interception" (objective)
3. "major vulnerability" (supervisor's opinion, not in original metadata)
4. Added 40 tokens of interpretation
```

## Testing Validation

### Validation Script

```bash
#!/bin/bash
# .claude/tests/validate_forward_message.sh

COMMAND_FILE="$1"

echo "Validating forward message pattern in $COMMAND_FILE..."

# Check 1: Forward message protocol documented
if grep -q "FORWARD.*DIRECTLY\|Forwarding.*no modification" "$COMMAND_FILE"; then
  echo "✓ Forward message protocol documented"
else
  echo "⚠️  WARNING: Forward message protocol not explicit"
fi

# Check 2: Anti-paraphrasing warnings present
if grep -q "DO NOT re-summarize\|DO NOT paraphrase" "$COMMAND_FILE"; then
  echo "✓ Anti-paraphrasing warnings present"
else
  echo "⚠️  WARNING: No explicit anti-paraphrasing instructions"
fi

# Check 3: Example forwarding structure present
if grep -q "FORWARDING.*RESULTS\|Agent [0-9]:" "$COMMAND_FILE"; then
  echo "✓ Forwarding structure example present"
fi

echo "✓ Forward message pattern validated"
```

### Expected Results

**Compliant Implementation:**
- Subagent metadata forwarded unchanged
- Minimal transition text (20-50 tokens: "Phase complete. Proceeding to next phase.")
- No paraphrasing or interpretation
- Structured metadata preserved

**Non-Compliant Implementation:**
- Supervisor rewrites metadata in prose
- Extractive summarization of key points
- Interpretation or opinion injection
- Overhead: 200-500 tokens per agent forwarded

## Performance Impact

**Token Overhead (Per Agent Forwarded):**
- Forward message: 0-10 tokens (transition text only)
- Re-summarization: 100-300 tokens (paraphrasing)
- Interpretation injection: 200-500 tokens (analysis + paraphrasing)

**Multi-Agent Workflows:**
- 4 agents with forward message: 40 tokens overhead (4 × 10)
- 4 agents with re-summarization: 800 tokens overhead (4 × 200)
- Savings: 760 tokens (95%)

**Information Preservation:**
- Forward message: 100% precision (original metadata unchanged)
- Re-summarization: 80-90% precision (paraphrasing loses nuance)
- Interpretation: 60-70% precision (supervisor opinions mixed with facts)

**Real-World Example (Plan 077):**
```
/orchestrate research phase (4 agents):

WITHOUT forward message:
- Agent metadata: 990 tokens
- Supervisor re-summarization: 800 tokens
- Total: 1,790 tokens
- Information loss: Medium
- Errors introduced: 2 (paraphrasing inaccuracies)

WITH forward message:
- Agent metadata: 990 tokens
- Supervisor forwarding: 40 tokens (minimal transitions)
- Total: 1,030 tokens
- Information loss: None
- Errors introduced: 0

Savings: 760 tokens (42% reduction)
Quality: Higher (no information loss or errors)
```

## Related Patterns

- [Metadata Extraction](./metadata-extraction.md) - Produces structured metadata for forwarding
- [Context Management](./context-management.md) - Forwarding is a key context reduction technique
- [Hierarchical Supervision](./hierarchical-supervision.md) - Forward message between supervision levels
- [Behavioral Injection](./behavioral-injection.md) - Supervisors forward context to agents

## See Also

- [Hierarchical Agents Guide](../hierarchical-agents.md) - Multi-level forwarding patterns
- [Creating Commands Guide](../../guides/development/command-development/command-development-fundamentals.md) - Supervisor communication best practices
- [Orchestration Guide](../../workflows/orchestration-guide.md) - Workflow-level forwarding
- [Writing Standards](../writing-standards.md) - Precision and clarity principles
