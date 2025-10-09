# Parallel Expansion/Collapse Architecture

## Overview

The parallel expansion/collapse system enables concurrent execution of multiple expansion or collapse operations while maintaining plan consistency through artifact-based aggregation and coordinated metadata updates.

## Architecture Components

### 1. Agent Behavior Files

**Expansion Specialist** (`.claude/agents/expansion_specialist.md`)
- Specializes in extracting phase/stage content into separate files
- Tools: Read, Write, Edit, Bash
- Outputs: Artifact file with operation summary

**Collapse Specialist** (`.claude/agents/collapse_specialist.md`)
- Specializes in merging phase/stage content back to parent
- Tools: Read, Write, Edit, Bash
- Outputs: Artifact file with operation summary

**Complexity Estimator** (`.claude/agents/complexity_estimator.md`)
- Analyzes plan structure for optimization opportunities
- Provides batch complexity analysis
- Recommends expansion/collapse candidates

### 2. Utility Libraries

**Artifact Management** (`.claude/lib/artifact-utils.sh`)
```bash
create_artifact_directory()         # Create specs/artifacts/{plan_name}/
save_operation_artifact()           # Save operation results
load_artifact_references()          # Load artifact paths only
cleanup_operation_artifacts()       # Remove old artifacts
register_operation_artifact()       # Track artifact paths
validate_operation_artifacts()      # Verify artifact format
```

**Parallel Execution** (`.claude/lib/auto-analysis-utils.sh`)
```bash
invoke_expansion_agents_parallel()  # Launch expansion agents
invoke_collapse_agents_parallel()   # Launch collapse agents
aggregate_expansion_artifacts()     # Collect expansion artifacts
aggregate_collapse_artifacts()      # Collect collapse artifacts
coordinate_metadata_updates()       # Update plan metadata
review_plan_hierarchy()             # Analyze plan structure
run_second_round_analysis()         # Re-analyze after operations
present_recommendations_for_approval() # User approval gate
generate_recommendations_report()   # Format recommendations
```

**Error Recovery** (`.claude/lib/error-utils.sh`)
```bash
retry_with_timeout()                # Retry with 1.5x timeout
retry_with_fallback()               # Retry with reduced toolset
handle_partial_failure()            # Process partial successes
escalate_to_user_parallel()         # Interactive escalation
```

**Checkpoint Management** (`.claude/lib/checkpoint-utils.sh`)
```bash
save_parallel_operation_checkpoint()  # Save pre-operation state
restore_from_checkpoint()             # Rollback on failure
validate_checkpoint_integrity()       # Verify checkpoint
```

## Execution Flow

### Parallel Expansion Workflow

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

### Parallel Collapse Workflow

```
1. User invokes: /collapse <plan> --auto-analysis
   ↓
2. Batch Complexity Analysis
   - Invoke complexity_estimator agent
   - Analyze expanded items for collapse candidates
   - Return recommendations with complexity scores
   ↓
3. Save Checkpoint
   - Capture pre-operation plan state
   - Save to .claude/checkpoints/parallel_ops/
   ↓
4. Parallel Agent Invocation
   - Launch collapse_specialist for each recommendation
   - Execute concurrently using multiple Task calls
   - Each agent saves artifact to specs/artifacts/{plan}/
   ↓
5. Artifact Aggregation
   - Collect artifact paths (NOT content)
   - Validate all expected artifacts created
   - Build lightweight reference list
   ↓
6. Metadata Coordination (Sequential)
   - Handle three-way updates (stage→phase→plan)
   - Update Structure Level (2→1→0)
   - Update plan metadata atomically
   ↓
7. Hierarchy Review (Optional)
   - Analyze updated plan structure
   - Identify further optimization opportunities
   - Generate recommendations
   ↓
8. Second-Round Analysis (Optional)
   - Re-analyze plan with complexity_estimator
   - Identify new collapse candidates
   - Generate recommendations
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
    {"path": "specs/artifacts/001_plan/expansion_5.md", "phase": 5},
    ...
  ]
}

# Selective reading (only if needed)
if needs_detailed_validation; then
  artifact_content=$(cat "specs/artifacts/001_plan/expansion_3.md")
fi
```

### Context Reduction

**Before (Sequential with Full Content):**
- 5 operations × 200 lines = 1000 lines
- Total context: ~8000 tokens

**After (Parallel with Artifacts):**
- 5 operations × 3 lines (path + metadata) = 15 lines
- Total context: ~1200 tokens
- **Reduction: 85%**

## Error Recovery

### Retry Strategies

**1. Timeout Errors:**
```bash
# Generate retry metadata
retry_metadata=$(retry_with_timeout "expand_phase_3" 1)

# Result:
{
  "operation": "expand_phase_3",
  "attempt": 1,
  "new_timeout": 180000,  # 1.5x base timeout
  "should_retry": true,
  "max_attempts": 3
}
```

**2. Toolset Fallback:**
```bash
# Get reduced toolset recommendation
fallback=$(retry_with_fallback "expand_phase_3" 2)

# Result:
{
  "operation": "expand_phase_3",
  "attempt": 2,
  "full_toolset": "Read,Write,Edit,Bash",
  "reduced_toolset": "Read,Write",
  "strategy": "fallback"
}
```

**3. Partial Failure Handling:**
```bash
# Process partial successes
result=$(handle_partial_failure '{
  "total": 5,
  "successful": 3,
  "failed": 2,
  "artifacts": [...]
}')

# Result:
{
  "total": 5,
  "successful": 3,
  "failed": 2,
  "successful_operations": [...],
  "failed_operations": [...],
  "can_continue": true,
  "requires_retry": true
}
```

### Checkpoint System

**Save Checkpoint:**
```bash
checkpoint_file=$(save_parallel_operation_checkpoint \
  "$plan_path" \
  "expansion" \
  '[{"item_id":"phase_3","complexity":8}]')

# Creates: .claude/checkpoints/parallel_ops/parallel_expansion_001_plan_20251009_143022.json
```

**Restore on Failure:**
```bash
checkpoint_data=$(restore_from_checkpoint "$checkpoint_file")

# Returns original plan state for rollback
```

**Validate Integrity:**
```bash
validation=$(validate_checkpoint_integrity "$checkpoint_file")

# Result:
{
  "valid": true,
  "warnings": ["Plan path no longer exists: /tmp/test.md"]
}
```

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
  "last_expansion": "2025-10-09T14:30:00Z",
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

## Performance Characteristics

### Execution Time

**Sequential (Old):**
- 5 operations × 45s each = 225s
- Plus overhead: ~240s total

**Parallel (New):**
- 5 operations × 45s concurrent = 45s
- Plus coordination: ~60s total
- **Speedup: 4x**

### Context Usage

**Sequential (Old):**
- Full operation results in context
- ~8000 tokens per 5 operations

**Parallel (New):**
- Artifact references only
- ~1200 tokens per 5 operations
- **Reduction: 85%**

### Scalability

**Linear Scaling (up to 6 operations):**
- 2 operations: 2x speedup
- 4 operations: 3.5x speedup
- 6 operations: 4.5x speedup

**Diminishing Returns (6+ operations):**
- Coordination overhead increases
- Context management complexity
- Network/system limitations

## Hierarchy Review

### Purpose

After expansion/collapse operations, analyze plan structure for:
- Over-expanded phases (too granular)
- Under-collapsed phases (too coarse)
- Organizational improvements
- Balance and coherence

### Workflow

```bash
# 1. Invoke hierarchy review
review_result=$(review_plan_hierarchy "$plan_path" "$operation_summary")

# 2. Generate agent prompt
{
  "agent_prompt": "Review plan hierarchy...",
  "plan_path": "specs/plans/001_plan.md",
  "current_level": 1,
  "mode": "hierarchy_review"
}

# 3. Execute review agent
# (Command layer invokes Task tool with prompt)

# 4. Present recommendations to user
present_recommendations_for_approval "$recommendations"
```

### Recommendations Format

```markdown
## Hierarchy Review Recommendations

### Current Structure
- Level: 1
- Phases: 6 (5 expanded)
- Balance: Good

### Optimization Opportunities

**Phase 3: Complex Implementation**
- Complexity: 9/10
- Recommendation: Expand into stages
- Reason: 15+ tasks, multiple dependencies

**Phases 4-5: Database and API**
- Complexity: 4/10, 5/10
- Recommendation: Consider merging
- Reason: Closely related, similar complexity
```

## Second-Round Analysis

### Purpose

After initial operations complete, re-analyze plan to identify:
- New expansion candidates (from complexity changes)
- New collapse candidates (from simplification)
- Iterative optimization opportunities

### Workflow

```bash
# 1. Run second-round analysis
second_round=$(run_second_round_analysis "$plan_path" "$initial_analysis")

# 2. Compare before/after
{
  "current_level": 1,
  "comparison_available": true,
  "second_round": {
    "mode": "expansion",
    "new_candidates": [
      {"item_id": "phase_2", "complexity": 9, "reason": "High complexity after expansion"}
    ],
    "recommendations": [...]
  }
}

# 3. User approval gate
if present_recommendations_for_approval "$second_round"; then
  # User approved, execute second round
  execute_second_round "$second_round"
fi
```

### Iterative Optimization

```
Initial Plan (Level 0)
  ↓
First Expansion → Level 1 (5 phases expanded)
  ↓
Second-Round Analysis
  ↓
Second Expansion → Level 2 (2 phases → stages)
  ↓
Hierarchy Review
  ↓
Optimization: Merge related phases
  ↓
Final Optimized Structure
```

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

## Troubleshooting

See [Troubleshooting Guide](troubleshooting_parallel_operations.md) for common issues and solutions.
