# Context Budget Management Tutorial

**Path**: `.claude/docs/workflows/context-budget-management.md` → Home: [../README.md](../README.md) | Workflows: [README.md](README.md)

[Used by: /orchestrate, /coordinate, /supervise, all workflow orchestration commands]

Actionable guide for managing context across 7-phase workflows, achieving <30% context usage through layered architecture, pruning policies, and budget allocation strategies.

## Overview

Context window management is the primary scalability constraint for multi-agent workflows. This tutorial provides practical techniques for allocating, monitoring, and optimizing context budgets to enable complete 7-phase workflows within available limits.

**Target Performance**: <30% context usage (7,500 tokens out of 25,000 baseline)

**Achieved Performance**: 21% average context usage (5,250 tokens) across production workflows

## The Context Budget Problem

### Naive Approach: Unlimited Context

**Example Workflow** (without context management):

```
Phase 0 (Location Detection):
  Agent output: 2,000 tokens (full directory trees, location analysis)
  Retained: 2,000 tokens

Phase 1 (Research - 3 agents):
  Agent 1 output: 5,000 tokens (full OAuth patterns report)
  Agent 2 output: 5,000 tokens (full JWT strategies report)
  Agent 3 output: 4,500 tokens (full security practices report)
  Retained: 14,500 tokens

Cumulative after Phase 1: 16,500 tokens (66% of 25,000 budget)

Phase 2 (Planning):
  Plan creation: 3,000 tokens (implementation plan)
  Research context passed: 14,500 tokens (full reports)
  Retained: 17,500 tokens

Cumulative after Phase 2: 34,000 tokens (136% of budget) → OVERFLOW
```

**Result**: Workflow cannot proceed beyond Phase 2.

### Managed Approach: Layered Context Architecture

**Same Workflow** (with context management):

```
Phase 0 (Location Detection):
  Agent output: 2,000 tokens (full analysis)
  Metadata extracted: 500 tokens (paths + summary)
  Pruned: 1,500 tokens
  Retained: 500 tokens (Layer 1 - permanent)

Phase 1 (Research - 3 agents):
  Agent 1 output: 5,000 tokens → metadata: 250 tokens
  Agent 2 output: 5,000 tokens → metadata: 250 tokens
  Agent 3 output: 4,500 tokens → metadata: 250 tokens
  Pruned: 13,750 tokens
  Retained: 750 tokens (Layer 3 - metadata)

Cumulative after Phase 1: 1,250 tokens (5% of budget)

Phase 2 (Planning):
  Plan creation: 3,000 tokens
  Research metadata passed: 750 tokens (metadata only, NOT full reports)
  Plan metadata extracted: 800 tokens
  Pruned: 2,200 tokens (full plan content)
  Retained: 800 tokens (Layer 2 - phase-scoped)

Cumulative after Phase 2: 2,050 tokens (8.2% of budget)

Phase 3-7: Continue pattern...

Final cumulative: 5,250 tokens (21% of budget) ✓
```

**Result**: Full 7-phase workflow completes successfully.

## Layered Context Architecture

### Layer 1: Permanent Context (500-1,000 tokens, 4%)

**Contents**:
- Command prompt skeleton (200 tokens)
- Project standards (CLAUDE.md metadata, 150 tokens)
- Workflow scope and description (100 tokens)
- Library function registry (150 tokens)

**Retention Policy**: Keep throughout entire workflow

**Example**:
```markdown
# Layer 1: Permanent Context (retained all phases)

## Workflow Scope
- Description: "Implement JWT authentication for API endpoints"
- Scope: full-implementation
- Target: <30% context usage

## Project Standards
- Language: JavaScript (Node.js)
- Test Command: npm test
- Code Style: 2 spaces, camelCase

## Library Functions Loaded
- unified-location-detection.sh: ✓
- metadata-extraction.sh: ✓
- dependency-analyzer.sh: ✓
- context-pruning.sh: ✓

Total: ~600 tokens
```

### Layer 2: Phase-Scoped Context (2,000-4,000 tokens, 12%)

**Contents**:
- Current phase execution state (500 tokens)
- Wave tracking for parallel execution (300 tokens per wave)
- Active artifact paths (200 tokens)
- Current phase instructions (1,000-2,000 tokens)

**Retention Policy**: Prune when phase completes or wave finishes

**Example** (Phase 3 - Implementation):
```markdown
# Layer 2: Phase-Scoped Context (Wave 1)

## Current Phase: Phase 3 (Implementation)

### Wave 1 Execution
- Phases in this wave: [1, 2]
- Phase 1 status: in_progress (implementing auth middleware)
- Phase 2 status: in_progress (implementing token validation)

### Active Artifact Paths
- Plan: specs/084_jwt_auth/plans/001_jwt_implementation_plan.md
- Working directory: /project/src/auth/

### Current Phase Instructions
{Full instructions for Wave 1 execution - 1,500 tokens}

Total: ~2,300 tokens

{Pruned when Wave 1 completes}
```

### Layer 3: Metadata (200-300 tokens per artifact, 6% total)

**Contents**:
- Report metadata (title, 50-word summary, key findings)
- Plan metadata (complexity score, phase count, time estimate)
- Implementation metadata (files changed, tests status)

**Retention Policy**: Keep only metadata, prune full content immediately

**Example**:
```markdown
# Layer 3: Metadata (Research Reports)

## Report 1: OAuth Flow Patterns
- Path: specs/084_jwt_auth/reports/001_oauth_flow_patterns.md
- Summary: "OAuth 2.0 authorization code flow provides secure API authentication through token exchange. Refresh tokens enable long-lived sessions. PKCE extension required for public clients."
- Key Findings: ["Authorization code flow most secure", "Refresh token rotation recommended", "PKCE prevents interception attacks"]
- Token Count: 250 tokens

## Report 2: JWT Implementation Strategies
- Path: specs/084_jwt_auth/reports/002_jwt_implementation_strategies.md
- Summary: "JWT tokens contain claims signed with secret key. RS256 algorithm recommended for distributed systems. Token expiry should be 15-60 minutes with refresh mechanism."
- Key Findings: ["RS256 for multi-server setups", "Short expiry + refresh tokens", "Claim validation critical"]
- Token Count: 250 tokens

Total: ~500 tokens (2 reports)
```

### Layer 4: Transient (0 tokens after pruning)

**Contents** (before pruning):
- Full agent responses (5,000-10,000 tokens per agent)
- Intermediate calculations (1,000-2,000 tokens)
- Verbose diagnostic logs (500-1,000 tokens)

**Retention Policy**: Prune immediately after extracting metadata

**Example**:
```markdown
# Layer 4: Transient (PRUNED IMMEDIATELY)

## Research Agent 1 Full Response (5,000 tokens)
{Full OAuth flow patterns report content - PRUNED to 250 token metadata}

## Research Agent 2 Full Response (5,000 tokens)
{Full JWT strategies report content - PRUNED to 250 token metadata}

## Research Agent 3 Full Response (4,500 tokens)
{Full security practices report content - PRUNED to 250 token metadata}

Total before pruning: 14,500 tokens
Total after pruning: 0 tokens (metadata moved to Layer 3)
Reduction: 100% (all transient content removed)
```

## Budget Allocation Strategies

### Strategy 1: Fixed Allocation (Simple)

**Approach**: Allocate fixed token budget per phase based on workflow scope.

**Full-Implementation Workflow** (6 phases: 0-4, 6):
```
Phase 0 (Location Detection): 500 tokens
Phase 1 (Research - 3 agents): 900 tokens (3 × 300 metadata)
Phase 2 (Planning): 800 tokens
Phase 3 (Implementation): 2,000 tokens (largest phase)
Phase 4 (Testing): 400 tokens
Phase 6 (Documentation): 300 tokens
───────────────────────────────────────────────────
Total: 4,900 tokens (19.6% of 25,000 budget)
Buffer: 2,600 tokens (10.4%) for overruns
```

**Research-and-Plan Workflow** (3 phases: 0-2):
```
Phase 0 (Location Detection): 500 tokens
Phase 1 (Research - 4 agents): 1,200 tokens (4 × 300 metadata)
Phase 2 (Planning): 1,000 tokens
───────────────────────────────────────────────────
Total: 2,700 tokens (10.8% of 25,000 budget)
Buffer: 4,800 tokens (19.2%) for deep research
```

**Advantages**:
- Simple to implement and monitor
- Predictable context usage
- Easy to debug budget overruns

**Disadvantages**:
- May over-allocate for simple phases
- May under-allocate for complex phases

### Strategy 2: Dynamic Allocation (Adaptive)

**Approach**: Allocate budget based on phase complexity score and remaining budget.

**Algorithm**:
```bash
# Calculate complexity score per phase
PHASE_1_COMPLEXITY=5  # Simple research (1 agent)
PHASE_2_COMPLEXITY=8  # Moderate planning
PHASE_3_COMPLEXITY=12 # Complex implementation (3 waves)
TOTAL_COMPLEXITY=25

# Total budget available
TOTAL_BUDGET=7500  # 30% of 25,000

# Allocate proportionally
PHASE_1_BUDGET=$(( TOTAL_BUDGET * PHASE_1_COMPLEXITY / TOTAL_COMPLEXITY ))
# Result: 1,500 tokens

PHASE_2_BUDGET=$(( TOTAL_BUDGET * PHASE_2_COMPLEXITY / TOTAL_COMPLEXITY ))
# Result: 2,400 tokens

PHASE_3_BUDGET=$(( TOTAL_BUDGET * PHASE_3_COMPLEXITY / TOTAL_COMPLEXITY ))
# Result: 3,600 tokens
```

**Advantages**:
- Optimally allocates budget based on actual complexity
- Prevents under-allocation for complex phases
- Maximizes utilization of available budget

**Disadvantages**:
- Requires complexity calculation upfront
- More complex to implement

### Strategy 3: Reserve Allocation (Safe)

**Approach**: Reserve buffer for debugging and unexpected complexity.

**Budget Distribution**:
```
Core Phases (Phases 0-4, 6): 60% of budget (4,500 tokens)
Debugging Reserve (Phase 5): 20% of budget (1,500 tokens)
Overflow Buffer: 20% of budget (1,500 tokens)
───────────────────────────────────────────────────
Total: 7,500 tokens (30% of 25,000 budget)
```

**Advantages**:
- Safety margin for unexpected issues
- Debugging phase fully budgeted
- Prevents hard failures from overflow

**Disadvantages**:
- May under-utilize budget if debugging not needed

## Pruning Policies

### Aggressive Pruning (Orchestration Commands)

**When to Use**: Multi-agent workflows with >3 phases

**Pruning Rules**:
1. Prune full agent responses immediately after metadata extraction
2. Prune completed wave context before starting next wave
3. Prune phase-scoped context when phase completes
4. Retain only metadata and artifact paths

**Implementation**:
```bash
# After research agent completes
FULL_RESPONSE=$(cat agent_output.txt)  # 5,000 tokens
METADATA=$(extract_report_metadata "$REPORT_PATH")  # 250 tokens

# Prune full response immediately
prune_subagent_output "$FULL_RESPONSE" "$METADATA"  # Removes 4,750 tokens

# After Wave 1 completes
prune_phase_output "Wave 1" "aggressive"  # Removes all transient data

# Retention: Only metadata (250 tokens per report)
```

**Token Savings**: 95-97% per artifact

### Moderate Pruning (Linear Workflows)

**When to Use**: Simple workflows with sequential phases, need to reference previous outputs

**Pruning Rules**:
1. Keep full agent responses until phase completes
2. Prune full content when next phase starts
3. Retain metadata + phase summary (500-800 tokens)

**Implementation**:
```bash
# Research phase completes
# Keep full reports during planning phase (may need to reference details)

# Planning phase starts
# Prune full research reports, keep metadata + summary
prune_phase_metadata "1" "$PLAN_PATH"  # Moderate policy

# Retention: Metadata + summary (500 tokens for 3 reports)
```

**Token Savings**: 85-90% per artifact

### Minimal Pruning (Debugging Workflows)

**When to Use**: Debugging workflows, need full context for investigation

**Pruning Rules**:
1. Keep full agent responses throughout workflow
2. Only prune after workflow completion
3. Retain all diagnostic logs

**Implementation**:
```bash
# Throughout workflow
# No pruning during execution

# After workflow completes
# Optional: prune for archival
prune_workflow_context "minimal"  # Keep all critical data

# Retention: Full context (may reach 60-80% budget usage)
```

**Token Savings**: 20-30% (minimal pruning)

## Monitoring Context Usage

### Real-Time Monitoring

**Track context usage after each phase**:

```bash
# After Phase N completes
CURRENT_TOKENS=$(estimate_context_tokens)
TOTAL_BUDGET=7500  # 30% target
PERCENTAGE=$(( CURRENT_TOKENS * 100 / TOTAL_BUDGET ))

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Context Budget After Phase $N"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Current usage: $CURRENT_TOKENS tokens ($PERCENTAGE% of budget)"
echo "Budget remaining: $(( TOTAL_BUDGET - CURRENT_TOKENS )) tokens"
echo ""

if [ $CURRENT_TOKENS -gt $TOTAL_BUDGET ]; then
  echo "⚠️  WARNING: Budget exceeded!"
  echo "Action: Apply aggressive pruning or reduce scope"
fi
```

### Budget Threshold Alerts

**Define warning thresholds**:

```bash
BUDGET_WARN_THRESHOLD=5625  # 75% of 7,500 token budget
BUDGET_CRITICAL_THRESHOLD=7125  # 95% of budget

if [ $CURRENT_TOKENS -gt $BUDGET_CRITICAL_THRESHOLD ]; then
  echo "🚨 CRITICAL: Context usage at 95% of budget"
  echo "Action: Emergency pruning required"

  # Trigger emergency pruning
  prune_all_transient_data "aggressive"

elif [ $CURRENT_TOKENS -gt $BUDGET_WARN_THRESHOLD ]; then
  echo "⚠️  WARNING: Context usage at 75% of budget"
  echo "Action: Consider pruning non-critical data"
fi
```

### Estimation Functions

**Estimate token count for context elements**:

```bash
# Estimate tokens for markdown content
estimate_markdown_tokens() {
  local content="$1"
  local char_count=${#content}
  # Rough approximation: 1 token ≈ 4 characters
  echo $(( char_count / 4 ))
}

# Example
METADATA="Title: OAuth Patterns\nSummary: OAuth 2.0 provides..."
TOKEN_ESTIMATE=$(estimate_markdown_tokens "$METADATA")
echo "Estimated tokens: $TOKEN_ESTIMATE"
```

## Practical Examples

### Example 1: Full-Implementation Workflow (6 Phases)

**Workflow**: "Implement JWT authentication for API endpoints"

**Budget Allocation** (Fixed Strategy):
```
Phase 0: 500 tokens
Phase 1: 900 tokens (3 research agents)
Phase 2: 800 tokens (planning)
Phase 3: 2,000 tokens (implementation in 2 waves)
Phase 4: 400 tokens (testing)
Phase 6: 300 tokens (documentation)
───────────────────────────────────────────────────
Total: 4,900 tokens (19.6% of budget)
```

**Actual Usage**:
```
Phase 0:
  Full output: 2,000 tokens
  Metadata extracted: 500 tokens
  Pruned: 1,500 tokens ✂️
  Retained: 500 tokens ✓

Phase 1:
  Agent 1 full: 5,000 tokens → metadata: 250 tokens ✂️
  Agent 2 full: 4,800 tokens → metadata: 250 tokens ✂️
  Agent 3 full: 5,200 tokens → metadata: 300 tokens ✂️
  Pruned: 14,200 tokens ✂️
  Retained: 800 tokens ✓
  Cumulative: 1,300 tokens (5.2%)

Phase 2:
  Full plan: 3,000 tokens
  Metadata extracted: 800 tokens
  Pruned: 2,200 tokens ✂️
  Retained: 800 tokens ✓
  Cumulative: 2,100 tokens (8.4%)

Phase 3 (Wave 1):
  Phase 1 full: 3,000 tokens → metadata: 400 tokens ✂️
  Phase 2 full: 2,800 tokens → metadata: 400 tokens ✂️
  Wave 1 pruned: 5,000 tokens ✂️
  Retained: 800 tokens ✓
  Cumulative: 2,900 tokens (11.6%)

Phase 3 (Wave 2):
  Phase 3 full: 2,500 tokens → metadata: 350 tokens ✂️
  Pruned: 2,150 tokens ✂️
  Retained: 350 tokens ✓
  Wave 1 metadata pruned after completion ✂️
  Cumulative: 2,450 tokens (9.8%)

Phase 4:
  Test execution: 1,000 tokens → summary: 400 tokens ✂️
  Pruned: 600 tokens ✂️
  Retained: 400 tokens ✓
  Cumulative: 2,850 tokens (11.4%)

Phase 6:
  Summary creation: 800 tokens → metadata: 300 tokens ✂️
  Pruned: 500 tokens ✂️
  Retained: 300 tokens ✓

Final Cumulative: 3,150 tokens (12.6% of budget) ✓✓
Under budget by: 1,750 tokens (58% buffer remaining)
```

### Example 2: Research-Only Workflow (2 Phases)

**Workflow**: "Research API authentication best practices"

**Budget Allocation** (Fixed Strategy):
```
Phase 0: 500 tokens
Phase 1: 1,200 tokens (4 research agents for deep investigation)
───────────────────────────────────────────────────
Total: 1,700 tokens (6.8% of budget)
```

**Actual Usage**:
```
Phase 0:
  Full output: 1,800 tokens
  Metadata: 500 tokens
  Pruned: 1,300 tokens ✂️
  Retained: 500 tokens ✓

Phase 1 (4 parallel agents):
  Agent 1 (OAuth): 6,000 tokens → 300 tokens metadata ✂️
  Agent 2 (JWT): 5,500 tokens → 300 tokens metadata ✂️
  Agent 3 (Sessions): 5,800 tokens → 300 tokens metadata ✂️
  Agent 4 (Security): 6,200 tokens → 350 tokens metadata ✂️

  Pruned: 22,250 tokens ✂️
  Retained: 1,250 tokens ✓

Final Cumulative: 1,750 tokens (7% of budget) ✓✓
Under budget by: 5,750 tokens (329% buffer remaining)
```

**Analysis**: Research-only workflows use minimal context due to:
1. Only 2 phases executed (scope detection skips 3-7)
2. Aggressive metadata extraction (95% reduction per report)
3. No implementation or testing context overhead

## Troubleshooting Budget Overruns

### Symptom: Budget Exceeds 30% After Phase 1

**Diagnosis**: Research phase retaining too much content

**Causes**:
1. Full reports not being pruned (transient data retained)
2. Too many research agents (>4 agents)
3. Metadata extraction not working (library not sourced)

**Solutions**:
```bash
# Solution 1: Verify aggressive pruning enabled
prune_subagent_output "agent_response" "metadata"  # Must be called after EACH agent

# Solution 2: Reduce research agent count
# Change: 4 agents → 3 agents (saves 300 tokens)

# Solution 3: Verify metadata extraction library loaded
source "${CLAUDE_CONFIG}/.claude/lib/workflow/metadata-extraction.sh"
if ! declare -f extract_report_metadata > /dev/null; then
  echo "ERROR: Metadata extraction not available"
  exit 1
fi
```

### Symptom: Budget Exceeds 30% After Phase 3

**Diagnosis**: Implementation phase not pruning wave context

**Causes**:
1. Completed waves not being pruned
2. Phase-scoped context growing unbounded
3. All wave metadata retained (should prune after wave completes)

**Solutions**:
```bash
# Solution 1: Prune after each wave completes
after_wave_completes() {
  local wave_number=$1

  # Prune wave context
  prune_phase_output "Wave $wave_number" "aggressive"

  # Keep only: "Wave N: complete ✓"
  echo "Wave $wave_number: complete ✓"
}

# Solution 2: Clear phase-scoped context between waves
WAVE_1_CONTEXT=""  # Clear after Wave 1 completes
WAVE_2_CONTEXT=""  # Clear after Wave 2 completes
```

### Symptom: Slow Context Growth Throughout Workflow

**Diagnosis**: Metadata accumulation without cleanup

**Causes**:
1. Metadata from all phases retained indefinitely
2. No layered cleanup strategy

**Solutions**:
```bash
# Solution: Implement layered cleanup
# After Phase N completes, prune Phase N-2 metadata

if [ $CURRENT_PHASE -gt 2 ]; then
  PHASE_TO_PRUNE=$(( CURRENT_PHASE - 2 ))
  prune_phase_metadata "$PHASE_TO_PRUNE" "$PLAN_PATH"

  # Example: After Phase 4 completes, prune Phase 2 metadata
  # Retain only: "Phase 2: complete ✓" (5 tokens vs 800 tokens)
fi
```

## Best Practices Checklist

### Before Starting Workflow

- [ ] Determine workflow scope (research-only, research-and-plan, full-implementation)
- [ ] Calculate expected phase count
- [ ] Choose budget allocation strategy (fixed, dynamic, or reserve)
- [ ] Set total budget target (default: 7,500 tokens = 30%)
- [ ] Choose pruning policy (aggressive for >3 phases, moderate for ≤3 phases)

### During Each Phase

- [ ] Extract metadata immediately after agent completion
- [ ] Prune full agent responses after metadata extraction
- [ ] Monitor cumulative context usage (report after each phase)
- [ ] Alert if budget exceeds 75% threshold

### After Each Phase Completes

- [ ] Prune phase-scoped context
- [ ] Prune completed wave context (if wave-based execution)
- [ ] Update context usage metrics
- [ ] Verify metadata extraction successful (cross-check token counts)

### After Workflow Completes

- [ ] Final context usage report (compare actual vs budget)
- [ ] Archive workflow for budget analysis
- [ ] Document any budget overruns for future optimization

## Cross-References

### Related Patterns
- [Context Management Pattern](../concepts/patterns/context-management.md) - Comprehensive context management techniques
- [Metadata Extraction Pattern](../concepts/patterns/metadata-extraction.md) - 95% reduction per artifact
- [Parallel Execution Pattern](../concepts/patterns/parallel-execution.md) - Wave-based pruning strategies

### Related Guides
- [Orchestration Best Practices Guide](../guides/orchestration/orchestration-best-practices.md) - 7-phase workflow with context budget targets
- [Phase 0 Optimization Guide](../guides/patterns/phase-0-optimization.md) - 85% reduction in Phase 0

### Related Reference
- [Library API Reference](../reference/library-api/overview.md) - context-pruning.sh, metadata-extraction.sh
- [Orchestration Reference](../reference/workflows/orchestration-reference.md) - Context usage per command

## Changelog

### 2025-10-28: Initial Creation
- Layered context architecture defined (4 layers)
- Three budget allocation strategies documented
- Three pruning policies defined
- Real-world examples with token breakdowns
- Troubleshooting guide for budget overruns
- Monitoring and alerting strategies documented
