# Hierarchical Agent Workflow

This workflow guide describes how to use hierarchical agents for complex multi-agent workflows.

## Overview

Hierarchical agent architecture enables multi-level agent coordination that minimizes context window consumption through metadata-based context passing and recursive supervision.

**Key Benefits**:
- 99% context reduction through metadata extraction
- 60-80% time savings with parallel subagent execution
- Scalability to 10+ parallel agents across domains

## Quick Start

### Basic Workflow
```bash
# 1. Research with parallel agents
/research "authentication patterns"
# → Creates reports with metadata extraction

# 2. Plan with research context
/plan "implement OAuth" specs/reports/001_auth_patterns.md
# → References report via metadata, not full content

# 3. Implement with subagent delegation
/implement specs/plans/001_oauth_implementation.md
# → Delegates complex phases to subagents automatically
```

### Advanced Workflows
```bash
# Orchestrate end-to-end with hierarchical agents
/orchestrate "build authentication system with JWT and refresh tokens"

# Coordinate with wave-based parallel execution
/coordinate "refactor API layer with new error handling"
```

## Architecture Levels

```
Level 0: Primary Orchestrator (command-level agent)
  ↓
Level 1: Domain Supervisors (research, implementation, testing)
  ↓
Level 2: Specialized Subagents (auth research, API research, security research)
  ↓
Level 3: Task Executors (focused single-task agents - rarely used)
```

**Depth Limit**: Maximum 3 levels to prevent complexity explosion.

## Core Patterns

### 1. Metadata-Only Passing

**Problem**: Passing full report content consumes 1000+ tokens per artifact.

**Solution**: Extract title + 50-word summary + key references.

**Reduction**: 99% (5000 chars → 250 chars per artifact)

**Implementation**:
```bash
# Metadata extraction utility
source .claude/lib/workflow/metadata-extraction.sh
extract_report_metadata "$report_path"
# Returns: {title, summary, file_paths, recommendations, path, size}
```

### 2. Forward Message Pattern

**Problem**: Primary agents re-summarize subagent outputs (200-300 token overhead).

**Solution**: Pass subagent responses directly without paraphrasing.

**Benefit**: Maintains original fidelity, eliminates paraphrasing cost.

### 3. Recursive Supervision

**Problem**: Single-level supervision limited to 4-5 parallel agents.

**Solution**: Supervisors delegate to sub-supervisors (2-3 agents each).

**Scalability**: Enables 10+ parallel agents across multiple domains.

### 4. Aggressive Context Pruning

**Problem**: Completed phase data accumulates throughout workflow.

**Solution**: Prune full content after completion, retain metadata only.

**Reduction**: 80-90% reduction in accumulated context.

## Agent Templates

### Implementation Researcher
**File**: `.claude/agents/implementation-researcher.md`

**Purpose**: Analyzes codebase before complex implementation phases

**Usage**:
```bash
# Automatically invoked by /implement for phases with complexity ≥8
/implement specs/plans/001_complex_refactor.md
```

**Output**: 50-word summary + artifact path + key findings

### Debug Analyst
**File**: `.claude/agents/debug-analyst.md`

**Purpose**: Investigates root causes in parallel

**Usage**:
```bash
/debug "authentication failures in production"
```

**Output**: Structured findings + proposed fixes

### Sub-Supervisor
**Pattern**: Manages 2-3 specialized subagents per domain

**Purpose**: Enables recursive supervision for large-scale workflows

**Output**: Aggregated metadata only to parent supervisor

## Workflow Integration

### /implement
Delegates codebase exploration for complex phases (complexity ≥8):
```bash
/implement specs/plans/001_refactor.md
# → Phase 3 complexity: 9.5
# → Automatically invokes implementation-researcher agent
# → Receives metadata + findings, continues implementation
```

### /plan
Delegates research for ambiguous features (2-3 parallel research agents):
```bash
/plan "implement authentication" --research
# → Spawns parallel research agents
# → Aggregates metadata from all agents
# → Creates plan with research context
```

### /orchestrate
Supports recursive supervision for large-scale workflows (10+ topics):
```bash
/orchestrate "full-stack authentication system"
# → Level 1: Research supervisor (3 subagents)
# → Level 1: Implementation supervisor (4 subagents)
# → Level 1: Testing supervisor (2 subagents)
# → Aggregates metadata at each level
```

## Context Reduction Metrics

**Target**: <30% context usage throughout workflows

**Achieved**: 92-97% reduction through metadata-only passing

**Breakdown**:
- Report/plan passing: 99% reduction (5000 → 250 chars)
- Subagent output: 85% reduction (forward message pattern)
- Completed phases: 90% reduction (aggressive pruning)

## Utilities

### Metadata Extraction
**Library**: `.claude/lib/workflow/metadata-extraction.sh`

Functions:
- `extract_report_metadata()` - Extract report metadata
- `extract_plan_metadata()` - Extract plan metadata
- `load_metadata_on_demand()` - Generic metadata loader with caching

### Plan Parsing
**Library**: `.claude/lib/plan/plan-core-bundle.sh`

Functions:
- `parse_plan_file()` - Parse plan structure and phases
- `extract_phase_info()` - Extract phase details and tasks
- `get_plan_metadata()` - Get plan-level metadata

### Context Management
**Library**: `.claude/lib/workflow/context-pruning.sh`

Functions:
- `prune_subagent_output()` - Clear full outputs after metadata extraction
- `prune_phase_metadata()` - Remove phase data after completion
- `apply_pruning_policy()` - Automatic pruning by workflow type

## Performance Optimization

### Phase 0 Optimization
Pre-calculate artifact paths before workflow execution (85% token reduction).

See [Phase 0 Optimization Guide](../guides/patterns/phase-0-optimization.md).

### Parallel Execution
Wave-based parallel implementation for 40-60% time savings.

See [Parallel Execution Pattern](../concepts/patterns/parallel-execution.md).

### Context Budget Management
Monitor and manage context usage throughout workflows.

See [Context Budget Management Tutorial](./context-budget-management.md).

## Best Practices

1. **Always extract metadata** before passing artifacts between agents
2. **Use forward message pattern** for subagent outputs
3. **Prune aggressively** after phase completion
4. **Limit hierarchy depth** to 3 levels maximum
5. **Parallelize when possible** using phase dependencies
6. **Monitor context usage** and prune proactively

## Troubleshooting

### High Context Usage
- Check if metadata extraction is being used
- Verify pruning is applied after phase completion
- Review hierarchy depth (should be ≤3 levels)

### Subagent Not Delegating
- Verify agent file exists in `.claude/agents/`
- Check behavioral injection pattern is used
- Review agent invocation in command file

### Metadata Extraction Failing
- Verify artifact file exists at expected path
- Check metadata extraction library is sourced
- Review artifact structure matches expected format

## Related Documentation

- [Hierarchical Agent Architecture Guide](../concepts/hierarchical-agents.md) - Complete architecture documentation
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Agent invocation patterns
- [Metadata Extraction Pattern](../concepts/patterns/metadata-extraction.md) - Metadata extraction details
- [Forward Message Pattern](../concepts/patterns/forward-message.md) - Passing subagent outputs
- [Context Management Pattern](../concepts/patterns/context-management.md) - Context pruning strategies
- [Orchestration Best Practices Guide](../guides/orchestration/orchestration-best-practices.md) - Unified orchestration framework
