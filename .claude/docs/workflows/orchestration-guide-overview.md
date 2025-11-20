# Orchestration Guide - Overview

## Navigation

This document is part of a multi-part guide:
- **Overview** (this file) - Quick start, architecture, and artifact-based aggregation
- [Patterns](orchestration-guide-patterns.md) - Context pruning, user workflows, and error recovery
- [Examples](orchestration-guide-examples.md) - Wave-based execution and behavioral injection examples
- [Troubleshooting](orchestration-guide-troubleshooting.md) - Common issues, diagnostics, and reference

---

## Overview

The Claude Code orchestration system enables efficient management of complex development workflows through:
- **Parallel execution** of independent operations (expansion, collapse, analysis)
- **Workflow coordination** across multiple specialized agents
- **Artifact-based aggregation** for efficient context management
- **Checkpoint system** for safe experimentation and recovery

This guide covers the `/orchestrate` command and the underlying parallel execution architecture for plan structure management.

---

## Quick Start

### Basic Orchestration

**Expand multiple phases in parallel:**
```bash
/expand specs/plans/001_myplan.md --auto-analysis
```

**Collapse multiple phases in parallel:**
```bash
/collapse specs/plans/001_myplan/ --auto-analysis
```

**Orchestrate end-to-end workflow:**
```bash
/orchestrate "Research authentication patterns, create implementation plan, and execute first phase"
```

### When to Use Auto-Analysis Mode

**Use `--auto-analysis` when:**
- You have 3+ phases/stages to expand/collapse
- You want automatic complexity-based recommendations
- You trust the system to identify optimal candidates
- You want parallel execution for speed

**Use explicit mode (specify phase numbers) when:**
- You know exactly which phases to expand/collapse
- You need fine-grained control
- You have 1-2 items to process
- You want sequential execution

---

## Architecture

### Components

#### 1. Specialized Agents

**Expansion Specialist** (`.claude/agents/expansion_specialist.md`)
- Extracts phase/stage content into separate files
- Tools: Read, Write, Edit, Bash
- Outputs: Artifact file with operation summary

**Collapse Specialist** (`.claude/agents/collapse_specialist.md`)
- Merges phase/stage content back to parent
- Tools: Read, Write, Edit, Bash
- Outputs: Artifact file with operation summary

**Complexity Estimator** (`.claude/agents/complexity_estimator.md`)
- Analyzes plan structure for optimization opportunities
- Provides batch complexity analysis
- Recommends expansion/collapse candidates

#### 2. Utility Libraries

**Artifact Management** (`.claude/lib/artifact/artifact-creation.sh`, `.claude/lib/artifact/artifact-registry.sh`)
```bash
create_artifact_directory()         # Create specs/artifacts/{plan_name}/
save_operation_artifact()           # Save operation results
load_artifact_references()          # Load artifact paths only
cleanup_operation_artifacts()       # Remove old artifacts
```

**Parallel Execution** (`.claude/lib/plan/auto-analysis-utils.sh`)
```bash
invoke_expansion_agents_parallel()  # Launch expansion agents
invoke_collapse_agents_parallel()   # Launch collapse agents
aggregate_expansion_artifacts()     # Collect expansion artifacts
aggregate_collapse_artifacts()      # Collect collapse artifacts
coordinate_metadata_updates()       # Update plan metadata
```

**Error Recovery** (`.claude/lib/core/error-handling.sh`)
```bash
retry_with_timeout()                # Retry with 1.5x timeout
retry_with_fallback()               # Retry with reduced toolset
handle_partial_failure()            # Process partial successes
escalate_to_user_parallel()         # Interactive escalation
```

**Checkpoint Management** (`.claude/lib/workflow/checkpoint-utils.sh`)
```bash
save_parallel_operation_checkpoint()  # Save pre-operation state
restore_from_checkpoint()             # Rollback on failure
validate_checkpoint_integrity()       # Verify checkpoint
```

### Execution Workflows

#### Parallel Expansion Workflow

```
1. User invokes: /expand <plan> --auto-analysis
   ↓
2. Batch Complexity Analysis
   - Invoke complexity_estimator agent
   - Analyze all phases/stages in single pass
   - Return recommendations with complexity scores
   ↓
3. Save Checkpoint
   - Capture pre-operation plan state
   - Save to .claude/checkpoints/parallel_ops/
   ↓
4. Parallel Agent Invocation
   - Launch expansion_specialist for each recommendation
   - Execute concurrently using multiple Task calls
   - Each agent saves artifact to specs/artifacts/{plan}/
   ↓
5. Artifact Aggregation
   - Collect artifact paths (NOT content)
   - Validate all expected artifacts created
   - Build lightweight reference list
   ↓
6. Metadata Coordination (Sequential)
   - Update Structure Level (0→1 or 1→2)
   - Update Expanded Phases/Stages list
   - Update plan metadata atomically
   ↓
7. Hierarchy Review (Optional)
   - Analyze updated plan structure
   - Identify optimization opportunities
   - Generate recommendations
   ↓
8. Second-Round Analysis (Optional)
   - Re-analyze plan with complexity_estimator
   - Compare before/after complexity
   - Identify new expansion candidates
   ↓
9. User Approval Gate
   - Present recommendations
   - Wait for explicit confirmation
   - Log approval decision
   ↓
10. Cleanup
    - Remove temporary artifacts
    - Delete checkpoint on success
```

#### Parallel Collapse Workflow

```
1. User invokes: /collapse <plan> --auto-analysis
   ↓
2. Batch Complexity Analysis
   - Invoke complexity_estimator agent
   - Analyze expanded items for collapse candidates
   - Return recommendations with complexity scores
   ↓
3. Save Checkpoint → 4. Parallel Agent Invocation → 5. Artifact Aggregation
   (Same as expansion workflow)
   ↓
6. Metadata Coordination (Sequential)
   - Handle three-way updates (stage→phase→plan)
   - Update Structure Level (2→1→0)
   - Update plan metadata atomically
   ↓
7-10. Hierarchy Review → Second-Round Analysis → User Approval → Cleanup
   (Same as expansion workflow)
```

---

## Artifact-Based Aggregation

### Problem Statement

When executing multiple operations in parallel, collecting full operation results in the supervisor's context causes context overflow:
- 5 operations × 200 lines each = 1000 lines of context
- With analysis and metadata, easily exceeds context limits

### Solution

**Artifact-Based Aggregation Pattern:**

1. Each subagent saves full results to artifact file
2. Supervisor collects only artifact paths (not content)
3. Supervisor selectively reads artifacts only when needed
4. Context reduction: ~50 words per operation vs 200+ lines

### Implementation

**Subagent Side:**
```bash
# Save operation result to artifact
save_operation_artifact "$plan_name" "expansion" "phase_3" '
{
  "operation": "expand_phase",
  "phase_number": 3,
  "created_file": "specs/plans/001_plan/phase_3_implementation.md",
  "status": "success"
}
'
```

**Supervisor Side:**
```bash
# Collect artifact paths
artifact_refs=$(aggregate_expansion_artifacts "$plan_path")

# Result: Lightweight JSON
{
  "total": 5,
  "successful": 5,
  "artifacts": [
    {"path": "specs/artifacts/001_plan/expansion_3.md", "phase": 3},
    ...
  ]
}
```

### Context Reduction

**Before (Sequential with Full Content):**
- 5 operations × 200 lines = 1000 lines
- Total context: ~8000 tokens

**After (Parallel with Artifacts):**
- 5 operations × 3 lines (path + metadata) = 15 lines
- Total context: ~1200 tokens
- **Reduction: 85%**

**Context Preservation Standards:**

This artifact-based aggregation pattern implements **Standard 7 (Forward Message Pattern)** from [Command Architecture Standards](../reference/architecture/overview.md#context-preservation-standards), where subagent responses are passed via artifact references rather than re-summarized content. Combined with **Standard 8 (Context Pruning)**, orchestration workflows achieve 60-85% context reduction while maintaining complete operation history in artifacts.

---

## Related Documentation

- [Patterns](orchestration-guide-patterns.md) - Context pruning, user workflows, and error recovery
- [Examples](orchestration-guide-examples.md) - Wave-based execution and behavioral injection examples
- [Troubleshooting](orchestration-guide-troubleshooting.md) - Common issues, diagnostics, and reference
- [/orchestrate Command](../../commands/orchestrate.md) - Full command documentation
- [Adaptive Planning Guide](adaptive-planning-guide.md) - Progressive plan structures
