# Orchestration Guide - Patterns

## Navigation

This document is part of a multi-part guide:
- [Overview](orchestration-guide-overview.md) - Quick start, architecture, and artifact-based aggregation
- **Patterns** (this file) - Context pruning, user workflows, and error recovery
- [Examples](orchestration-guide-examples.md) - Wave-based execution and behavioral injection examples
- [Troubleshooting](orchestration-guide-troubleshooting.md) - Common issues, diagnostics, and reference

---

## Context Pruning Workflows

### Overview

**Context pruning** actively removes completed operation data from the execution context after metadata extraction. This prevents context accumulation in multi-phase workflows, maintaining target context usage **<30% throughout** (Standard 8).

### Pruning Policy Decision Tree

Choose pruning policy based on workflow type and complexity:

```
┌─────────────────────────────────────┐
│  Select Pruning Policy              │
└──────────────┬──────────────────────┘
               │
               ▼
        ┌──────────────┐
        │ Workflow Type │
        └──────┬───────┘
               │
       ┌───────┴───────┬───────────────┐
       │               │               │
       ▼               ▼               ▼
  Orchestrate    Implement      Single-Agent
  (5-7 phases)   (3-5 phases)   (1-2 phases)
       │               │               │
       ▼               ▼               ▼
  AGGRESSIVE      MODERATE         MINIMAL
  (<20% target)   (20-30%)        (30-50%)
```

**Policy Characteristics:**

| Policy | Context Target | Prune Frequency | Artifact Retention | Use Cases |
|--------|---------------|-----------------|-------------------|-----------|
| **Aggressive** | <20% | After each phase | Metadata only, 0-day full content | Orchestrate workflows (research → plan → implement → debug → document) |
| **Moderate** | 20-30% | After major milestones | Metadata + summaries, 7-day full content | Implement workflows (phase-by-phase execution with testing) |
| **Minimal** | 30-50% | End of workflow only | Full content retained | Single-agent operations (report generation, debugging analysis) |

### Pruning Utility Examples

#### 1. `prune_subagent_output()` - Prune After Metadata Extraction

Call immediately after extracting metadata from subagent outputs:

```bash
# Research phase completes with 3 reports
RESEARCH_OUTPUTS=(
  "specs/042_auth/reports/001_jwt_patterns.md"
  "specs/042_auth/reports/002_security.md"
  "specs/042_auth/reports/003_integration.md"
)

# Extract metadata first
for output in "${RESEARCH_OUTPUTS[@]}"; do
  METADATA=$(extract_report_metadata "$output")
  # METADATA: {path, 50-word summary, key_findings[]}
  REPORT_METADATA+=("$METADATA")

  # Prune full content, keep metadata in context
  prune_subagent_output "$output" "$METADATA"
done

# Context accumulated: 3 × 250 tokens = 750 tokens
# Without pruning: 3 × 5000 tokens = 15,000 tokens
# Reduction: 95%
```

#### 2. `prune_phase_metadata()` - Prune After Phase Completion

Call after completing a workflow phase (testing passed, committed):

```bash
# Phase 2 completes: code written, tests pass, committed
PHASE_2_DATA='
{
  "phase_number": 2,
  "status": "completed",
  "files_modified": ["src/auth.py", "tests/test_auth.py"],
  "commit_hash": "a1b2c3d",
  "tests_passing": true
}
'

# Prune detailed phase metadata, keep completion status
prune_phase_metadata "phase_2" "$PHASE_2_DATA"

# Context retained: {phase: 2, status: "completed", commit: "a1b2c3d"}
# Context pruned: files_modified[], tests_passing details, full diffs
# Reduction: 80%
```

#### 3. `apply_pruning_policy()` - Automatic Policy-Based Pruning

Call at workflow checkpoints to apply configured pruning policy:

```bash
# Orchestrate workflow after research phase
apply_pruning_policy \
  --mode aggressive \
  --workflow orchestrate \
  --phase research \
  --artifacts "${RESEARCH_OUTPUTS[@]}"

# Actions performed:
# 1. Prune all research report full content
# 2. Retain metadata only (paths + 50-word summaries)
# 3. Log pruning operation to checkpoint
# 4. Update context usage metrics

# Context before: 18,000 tokens (research + planning + coordination)
# Context after: 3,500 tokens (metadata + active planning context)
# Reduction: 81%
```

### Context Usage Target: <30%

**Monitoring Context Usage:**

```bash
# Check context usage at workflow checkpoints
CONTEXT_USAGE=$(calculate_context_usage)
echo "Current context usage: $CONTEXT_USAGE%"

if [[ $CONTEXT_USAGE -gt 30 ]]; then
  echo "Context usage above target, applying aggressive pruning"
  apply_pruning_policy --mode aggressive --workflow "$WORKFLOW_TYPE"
fi
```

**Expected Context Usage by Workflow Phase:**

| Workflow | Phase 1 | Phase 2 | Phase 3 | Phase 4 | Phase 5 | Phase 6 | Phase 7 |
|----------|---------|---------|---------|---------|---------|---------|---------|
| **Orchestrate (aggressive pruning)** | 15% | 18% | 22% | 20% | 19% | 21% | 18% |
| **Implement (moderate pruning)** | 18% | 24% | 28% | 26% | 25% | - | - |
| **Single-agent (minimal pruning)** | 25% | 35% | 42% | - | - | - | - |

### Utility Library Reference

Context pruning utilities are provided by `.claude/lib/workflow/context-pruning.sh`:

```bash
# Core Functions
prune_subagent_output <artifact_path> <metadata_json>
prune_phase_metadata <phase_id> <phase_data_json>
apply_pruning_policy --mode <aggressive|moderate|minimal> --workflow <type> [--phase <name>]
calculate_context_usage

# Pruning Configuration
configure_pruning_policy <workflow_type> <policy_name>
get_pruning_retention_days <policy_name>
validate_pruning_config

# Logging and Monitoring
log_pruning_operation <artifact_path> <pruned_tokens> <retained_tokens>
get_pruning_statistics <workflow_id>
export_pruning_report <output_path>
```

See [Command Architecture Standards - Standard 8](../reference/architecture/overview.md#standard-8) for complete context pruning specifications.

---

## User Workflows

### Workflow 1: Expand Complex Plan

**Goal:** Break down a complex plan into manageable pieces

**Steps:**

1. **Start with Level 0 plan:**
   ```bash
   cat specs/plans/001_feature.md
   # Shows: 8 phases, all inline
   ```

2. **Run auto-analysis expansion:**
   ```bash
   /expand specs/plans/001_feature.md --auto-analysis
   ```

3. **Review recommendations:**
   ```
   Complexity Analysis Results:
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Phase 3: Database      Complexity: 9/10  Expand
   Phase 5: Implementation Complexity: 8/10  Expand
   Phase 7: Deployment    Complexity: 8/10  Expand
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Proceed? (y/n): y
   ```

4. **Operations execute in parallel:**
   ```
   Expanding 3 phases in parallel...
   Phase 3 expanded
   Phase 5 expanded
   Phase 7 expanded

   Completed in 45s (vs 135s sequential)
   ```

5. **Final structure:**
   ```
   specs/plans/001_feature/
   ├── 001_feature.md (main plan)
   ├── phase_3_database.md
   ├── phase_5_implementation.md
   └── phase_7_deployment.md
   ```

### Workflow 2: Collapse Over-Expanded Plan

**Goal:** Simplify a plan that's too granular

**Steps:**

1. **Start with expanded plan:**
   ```bash
   ls specs/plans/001_api/
   # Shows: 15 phase files, many simple
   ```

2. **Run auto-analysis collapse:**
   ```bash
   /collapse specs/plans/001_api/ --auto-analysis
   ```

3. **Review recommendations:**
   ```
   Recommendations: Collapse phases 2, 4, 6, 8 (complexity <=4)

   These phases are simple enough to merge back.

   Proceed? (y/n): y
   ```

4. **Verify structure:**
   ```bash
   cat specs/plans/001_api.md
   # Shows: Phases 2, 4, 6, 8 merged back inline
   ```

### Workflow 3: Iterative Optimization

**Goal:** Continuously optimize plan structure

1. **Initial expansion:**
   ```bash
   /expand specs/plans/001_refactor.md --auto-analysis
   # Expands 3 complex phases
   ```

2. **Work on implementation, discover complexity changes**

3. **Collapse simplified phase:**
   ```bash
   /collapse specs/plans/001_refactor/ phase 2
   ```

4. **Expand newly complex phase:**
   ```bash
   /expand specs/plans/001_refactor.md phase 5
   ```

5. **Final optimization with hierarchy review**

---

## Error Recovery

### Retry Strategies

**1. Timeout Errors:**
```bash
# Automatic retry with 1.5x timeout
Attempt 1: timeout = 120s  → Failed
Attempt 2: timeout = 180s  → Failed  (1.5x)
Attempt 3: timeout = 270s  → Success (2.25x)
```

**2. Toolset Fallback:**
```bash
# Reduced toolset on repeated failures
Attempt 1: tools = [Read, Write, Edit, Bash]  → Failed
Attempt 2: tools = [Read, Write]               → Success
```

**3. Partial Failure Handling:**
```bash
# Process partial successes
5 Operations:
  Expand phase 1  → Success
  Expand phase 3  → Success
  Expand phase 5  → Success
  Expand phase 7  → Failed (timeout)
  Expand phase 9  → Failed (permission denied)

Result: Update metadata for successful operations, offer retry for failed
```

### Checkpoint System

**Save Checkpoint:**
```bash
checkpoint_file=$(save_parallel_operation_checkpoint \
  "$plan_path" \
  "expansion" \
  '[{"item_id":"phase_3","complexity":8}]')

# Creates: .claude/checkpoints/parallel_ops/parallel_expansion_001_plan_*.json
```

**Restore on Failure:**
```bash
checkpoint_data=$(restore_from_checkpoint "$checkpoint_file")
# Returns original plan state for rollback
```

---

## Performance Characteristics

### Execution Speed

**Sequential Execution:**
- 5 operations × 45s each = 225s
- Plus overhead: ~240s total

**Parallel Execution:**
- 5 operations × 45s concurrent = 45s
- Plus coordination: ~60s total
- **Speedup: 4x**

### Context Usage

| Operations | Context Usage | Mode |
|------------|---------------|------|
| 1-2 | Low (~500 tokens) | Sequential |
| 3-4 | Medium (~1200 tokens) | Parallel |
| 5-6 | Medium (~1500 tokens) | Parallel |
| 7+ | Risk overflow | Batch into groups |

### Scalability

**Linear Scaling (up to 6 operations):**
- 2 operations: 2x speedup
- 4 operations: 3.5x speedup
- 6 operations: 4.5x speedup

**Diminishing Returns (6+ operations):**
- Coordination overhead increases
- Context management complexity
- Network/system limitations

---

## Metadata Coordination

### Challenge

Parallel operations require coordinated metadata updates to maintain consistency:
- Structure Level transitions (0→1→2)
- Expanded Phases/Stages lists
- Plan metadata (dates, status)

### Solution

**Sequential Coordination Phase:**

After all parallel operations complete, update metadata sequentially:

```bash
# 1. Update Structure Level
update_structure_level "$plan_path" $((current_level + 1))

# 2. Update Expanded Items list
update_expanded_phases "$plan_path" "$newly_expanded_phases"

# 3. Update plan metadata
update_plan_metadata "$plan_path" '{
  "last_expansion": "2025-10-12T14:30:00Z",
  "total_expansions": 5
}'
```

**Checkpoint Protection:**
```bash
# Save checkpoint before metadata updates
metadata_checkpoint=$(save_metadata_checkpoint "$plan_path")

# Perform updates
if ! update_all_metadata; then
  restore_from_checkpoint "$metadata_checkpoint"
fi
```

---

## Best Practices

### When to Use Parallel Execution

**Use Parallel:**
- 3+ expansion/collapse operations
- Independent operations (no dependencies)
- Auto-analysis mode
- Large plans (10+ phases)

**Use Sequential:**
- 1-2 operations
- Dependent operations
- Explicit mode (user-specified items)
- Small plans

### Context Management

**Do:**
- Use artifact-based aggregation
- Read artifacts selectively
- Limit parallel operations to 4-6
- Cleanup artifacts after success

**Don't:**
- Load all artifacts into context
- Execute 10+ parallel operations
- Skip artifact validation
- Leave artifacts after completion

### Error Handling

**Do:**
- Use checkpoint system
- Handle partial failures gracefully
- Retry with extended timeouts
- Escalate after max attempts

**Don't:**
- Fail fast on first error
- Ignore partial successes
- Retry indefinitely
- Auto-rollback without user confirmation

### Metadata Updates

**Do:**
- Coordinate updates sequentially
- Use atomic operations
- Checkpoint before updates
- Validate after updates

**Don't:**
- Update metadata in parallel
- Skip validation
- Proceed without checkpoints
- Ignore update failures

---

## Related Documentation

- [Overview](orchestration-guide-overview.md) - Quick start, architecture, and artifact-based aggregation
- [Examples](orchestration-guide-examples.md) - Wave-based execution and behavioral injection examples
- [Troubleshooting](orchestration-guide-troubleshooting.md) - Common issues, diagnostics, and reference
