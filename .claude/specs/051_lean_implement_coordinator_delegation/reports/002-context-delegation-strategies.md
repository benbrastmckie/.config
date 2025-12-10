# Research Report: Context Window Delegation and Load Distribution

## Metadata
- **Date**: 2025-12-09
- **Topic**: Strategies for protecting primary agent context window through proper delegation
- **Source**: .claude/docs/concepts/hierarchical-agents-*.md

## Executive Summary

This report analyzes delegation patterns that protect the primary agent's context window while maintaining workflow functionality. The key strategy is metadata-only passing between hierarchy levels, achieving 95%+ context reduction.

## Findings

### 1. Current Hierarchical Architecture

The `.claude/docs/concepts/hierarchical-agents-overview.md` defines a three-tier hierarchy:

```
Orchestrator Command (Primary Agent)
    |
    +-- Supervisor Agent (Coordinator)
    |       +-- Worker Agent 1 (Specialist)
    |       +-- Worker Agent 2 (Specialist)
```

The /lean-implement command partially implements this:
- Primary Agent = /lean-implement command
- Coordinator = lean-coordinator or implementer-coordinator
- Workers = lean-implementer agents

### 2. Metadata-Only Context Passing

The hierarchical-agents-overview.md specifies:
- **Full content**: 2,500 tokens per agent
- **Metadata summary**: 110 tokens per agent
- **Target reduction**: 95%+

**Current /lean-implement implementation violates this**:
- Reads 1,374 lines of agent files (estimated 4,000+ tokens)
- Reads 474 lines of plan file (estimated 1,500+ tokens)
- Parses entire summary files (2,000+ tokens)

### 3. Brief Summary Pattern

Coordinators are documented to return structured metadata:
```yaml
coordinator_type: lean
summary_brief: "Completed Wave 1-2 (Phase 1,2) with 15 theorems. Context: 72%. Next: Continue Wave 3."
phases_completed: [1, 2]
work_remaining: Phase_3 Phase_4
context_usage_percent: 72
requires_continuation: true
```

The primary agent should parse ONLY these structured lines, not read the entire summary file.

### 4. Hard Barrier Pattern

From `.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md`:

The hard barrier pattern ensures:
1. Pre-calculated output paths before agent invocation
2. Mandatory Task tool invocation (no bypass)
3. Post-invocation validation of outputs
4. `exit 0` after iteration decision to prevent primary agent from performing delegated work

**Current /lean-implement status**:
- Pre-calculated paths: YES (Block 1a)
- Mandatory Task invocation: PARTIAL (pseudo-code blocks instead of real invocations)
- Post-invocation validation: YES (Block 1c)
- Hard barrier exit: YES (line 1292: `exit 0`)

### 5. When Delegation Should Occur vs Primary Execution

**Delegate to Coordinators**:
- All theorem proving work (lean-coordinator -> lean-implementer)
- All software implementation work (implementer-coordinator -> implementer)
- Reading agent behavioral files
- Writing output files
- Complex decision-making within a phase

**Keep in Primary Agent**:
- Pre-calculating artifact paths
- Invoking Task tool with pre-calculated parameters
- Parsing brief metadata from coordinator output (80 tokens)
- Iteration decision logic
- Routing to next coordinator based on phase type

## Recommendations

### 1. Remove Agent File Reads from Primary Agent

**Before** (current):
```markdown
Now I'll read the lean-coordinator agent to understand its behavior...
Read(.claude/agents/lean-coordinator.md)
```

**After** (recommended):
```markdown
**EXECUTE NOW**: Invoke lean-coordinator via Task tool

Task {
  prompt: "Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md"
}
```

### 2. Implement Brief Metadata Extraction

**Before** (current):
```bash
LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" | tail -1)
# Then grep entire file for patterns
```

**After** (recommended):
```bash
# Extract only structured metadata lines (lines 1-8)
SUMMARY_BRIEF=$(head -8 "$LATEST_SUMMARY" | grep "^summary_brief:" | sed 's/summary_brief://')
WORK_REMAINING=$(head -8 "$LATEST_SUMMARY" | grep "^work_remaining:" | sed 's/work_remaining://')
CONTEXT_USAGE=$(head -8 "$LATEST_SUMMARY" | grep "^context_usage_percent:" | sed 's/context_usage_percent://')
```

### 3. Add Context Budget Monitoring

Add to Block 1a:
```bash
PRIMARY_CONTEXT_BUDGET=5000  # tokens
CURRENT_CONTEXT=0

track_context_usage() {
  local operation="$1"
  local tokens="$2"
  CURRENT_CONTEXT=$((CURRENT_CONTEXT + tokens))

  if [ "$CURRENT_CONTEXT" -gt "$PRIMARY_CONTEXT_BUDGET" ]; then
    echo "WARNING: Primary agent context budget exceeded ($CURRENT_CONTEXT/$PRIMARY_CONTEXT_BUDGET tokens)" >&2
  fi
}
```

### 4. Convert Pseudo-Code to Real Invocations

The lean-implement.md contains pseudo-code that doesn't invoke Task:
```
Task {
  subagent_type: "general-purpose"
  ...
}
```

Replace with actual invocation directive:
```markdown
**EXECUTE NOW**: USE the Task tool with these parameters:
- **subagent_type**: "general-purpose"
- **description**: "Wave-based theorem proving"
- **prompt**: [exact prompt text]
```

## Context Reduction Targets

| Component | Current | Target | Method |
|-----------|---------|--------|--------|
| Agent file reads | 4,000 tokens | 0 tokens | Pass paths, not content |
| Plan file read | 1,500 tokens | 1,500 tokens | Keep (needed for routing) |
| Summary parsing | 2,000 tokens | 80 tokens | Extract only metadata lines |
| Routing logic | 500 tokens | 500 tokens | Keep (essential) |
| **Total** | **8,000 tokens** | **2,080 tokens** | **74% reduction** |

## Implementation Priority

1. **HIGH**: Remove agent file reads (4,000 token savings)
2. **HIGH**: Brief metadata extraction (1,920 token savings)
3. **MEDIUM**: Convert pseudo-code to real Task invocations
4. **LOW**: Add context budget monitoring
