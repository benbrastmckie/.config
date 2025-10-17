# Orchestration Guide: Parallel Operations and Workflows

## Overview

The Claude Code orchestration system enables efficient management of complex development workflows through:
- **Parallel execution** of independent operations (expansion, collapse, analysis)
- **Workflow coordination** across multiple specialized agents
- **Artifact-based aggregation** for efficient context management
- **Checkpoint system** for safe experimentation and recovery

This guide covers the `/orchestrate` command and the underlying parallel execution architecture for plan structure management.

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

**Artifact Management** (`.claude/lib/artifact-utils.sh`)
```bash
create_artifact_directory()         # Create specs/artifacts/{plan_name}/
save_operation_artifact()           # Save operation results
load_artifact_references()          # Load artifact paths only
cleanup_operation_artifacts()       # Remove old artifacts
```

**Parallel Execution** (`.claude/lib/auto-analysis-utils.sh`)
```bash
invoke_expansion_agents_parallel()  # Launch expansion agents
invoke_collapse_agents_parallel()   # Launch collapse agents
aggregate_expansion_artifacts()     # Collect expansion artifacts
aggregate_collapse_artifacts()      # Collect collapse artifacts
coordinate_metadata_updates()       # Update plan metadata
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
   Phase 3: Database      Complexity: 9/10  ⚠ Expand
   Phase 5: Implementation Complexity: 8/10  ⚠ Expand
   Phase 7: Deployment    Complexity: 8/10  ⚠ Expand
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Proceed? (y/n): y
   ```

4. **Operations execute in parallel:**
   ```
   Expanding 3 phases in parallel...
   ✓ Phase 3 expanded
   ✓ Phase 5 expanded
   ✓ Phase 7 expanded

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
   Recommendations: Collapse phases 2, 4, 6, 8 (complexity ≤4)

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
  ✓ Expand phase 1  → Success
  ✓ Expand phase 3  → Success
  ✓ Expand phase 5  → Success
  ✗ Expand phase 7  → Failed (timeout)
  ✗ Expand phase 9  → Failed (permission denied)

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

### Common Issues

#### 1. Context Overflow During Parallel Execution

**Symptoms:**
- "Context limit exceeded" errors
- Operations slow down significantly
- Unable to complete metadata updates

**Solutions:**
```bash
# Reduce parallel operations
MAX_PARALLEL=4  # Instead of 6+

# Verify artifact-based aggregation
artifact_refs=$(aggregate_expansion_artifacts "$plan_path")
echo "$artifact_refs" | jq '.artifacts[0]'  # Should be path only

# Cleanup old artifacts
cleanup_operation_artifacts "$plan_name"
```

**Prevention:**
- Limit parallel operations to 4-6
- Use artifact-based aggregation properly
- Clean up artifacts after completion
- Monitor context usage

#### 2. Partial Failure: Some Operations Succeed, Some Fail

**Symptoms:**
- Mixed success/failure in operation results
- Some phases expanded, others not
- Metadata partially updated

**Solutions:**
```bash
# Handle partial failures
result=$(handle_partial_failure "$aggregation_json")

# Check if can continue
can_continue=$(echo "$result" | jq -r '.can_continue')
if [[ "$can_continue" == "true" ]]; then
  coordinate_metadata_updates "$successful_ops"
fi

# Retry failed operations
failed_ops=$(echo "$result" | jq -r '.failed_operations')
for op in $(echo "$failed_ops" | jq -r '.[] | .item_id'); do
  retry_with_timeout "$op" 1
done
```

**Prevention:**
- Use checkpoint system before operations
- Implement retry logic with exponential backoff
- Validate tool permissions before execution

#### 3. Metadata Inconsistency After Parallel Operations

**Symptoms:**
- Structure Level incorrect
- Expanded Phases list missing items
- Plan metadata out of sync with actual files

**Solutions:**
```bash
# Validate metadata consistency
detect_structure_level "$plan_path"
validate_expanded_phases "$plan_path"

# Repair metadata
update_structure_level "$plan_path" 1

# Rebuild Expanded Phases list
expanded_phases=$(find "$plan_dir" -name "phase_*.md" | sort)
update_expanded_phases "$plan_path" "$expanded_phases"

# Restore from checkpoint if needed
restore_from_checkpoint "$checkpoint_file"
```

**Prevention:**
- Always use sequential metadata coordination
- Checkpoint before metadata updates
- Validate after each update
- Use atomic operations

#### 4. Agent Timeout During Parallel Execution

**Symptoms:**
- "Operation timed out" errors
- Some agents don't complete
- Partial results in artifacts

**Solutions:**
```bash
# Retry with extended timeout
retry_metadata=$(retry_with_timeout "expand_phase_3" 1)
new_timeout=$(echo "$retry_metadata" | jq -r '.new_timeout')

# Use reduced toolset
fallback=$(retry_with_fallback "expand_phase_3" 2)
reduced_toolset=$(echo "$fallback" | jq -r '.reduced_toolset')

# Escalate to user
escalate_to_user_parallel '{
  "operation": "expand",
  "failed": 2,
  "total": 5
}' "retry,skip,abort"
```

**Prevention:**
- Use appropriate timeout values
- Monitor system resources
- Limit concurrent operations
- Implement progressive retry strategies

#### 5. Artifact Validation Failures

**Symptoms:**
- "Artifact not found" errors
- "Invalid artifact format" errors
- Missing operation results

**Solutions:**
```bash
# Validate artifacts exist
validate_operation_artifacts "$plan_name"

# Check artifact format
artifact_path=$(get_artifact_path "$plan_name" "expansion_3")
if [[ -f "$artifact_path" ]]; then
  jq empty "$artifact_path" || echo "Invalid JSON"
fi

# Regenerate missing artifacts
execute_expansion_operation "phase_3"
```

**Prevention:**
- Validate artifacts immediately after creation
- Use proper artifact path conventions
- Don't cleanup artifacts during operations

### Diagnostic Commands

**Check System State:**
```bash
# Check parallel operations checkpoint status
ls -lh .claude/checkpoints/parallel_ops/

# Validate checkpoint integrity
for checkpoint in .claude/checkpoints/parallel_ops/*.json; do
  validate_checkpoint_integrity "$checkpoint"
done

# Check artifact directory
ls -lh specs/artifacts/*/

# Verify plan structure level
detect_structure_level "specs/plans/001_plan.md"
```

**Monitor Operation Progress:**
```bash
# Check artifact creation in real-time
watch -n 1 'ls -lt specs/artifacts/001_plan/ | head -10'

# Check metadata consistency
diff <(detect_structure_level "$plan_path") \
     <(get_structure_level_metadata "$plan_path")
```

**Debug Failed Operations:**
```bash
# Enable debug logging
export DEBUG=1

# Run operation with verbose output
invoke_expansion_agents_parallel "$recommendations" 2>&1 | tee operation.log

# Check for errors
grep -i error operation.log
```

## Reference

### Command Options

```bash
/expand <plan-path> [--auto-analysis] [phase <N>]
/collapse <plan-path> [--auto-analysis] [phase <N>] [stage <M>]
/orchestrate <workflow-description> [--parallel] [--sequential]
```

**Options:**
- `--auto-analysis`: Enable automatic complexity-based recommendations and parallel execution
- `phase <N>`: Explicitly specify phase to expand/collapse (sequential mode)
- `stage <M>`: Explicitly specify stage to collapse (sequential mode)
- `--parallel`: Force parallel agent execution in orchestrate workflows
- `--sequential`: Force sequential agent execution in orchestrate workflows

### Complexity Thresholds

- **Expand:** complexity ≥ 8/10
- **Collapse:** complexity ≤ 4/10
- **Balanced:** complexity 5-7/10

### Structure Levels

- **Level 0:** Single file, all phases inline
- **Level 1:** Directory, some phases in separate files
- **Level 2:** Phase directories with stage files

### Performance Metrics

- **Context Reduction:** 60-85% with artifact-based aggregation
- **Execution Speed:** 2-4x faster with parallel execution
- **Max Parallel Operations:** 4-6 recommended
- **Timeout:** Base 120s, retry at 180s, 270s

## Advanced Features

### Hierarchy Review

After operations complete, the system analyzes plan structure:

```
Reviewing plan hierarchy...

Hierarchy Analysis:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Current Structure:
  - Level: 1 (phase expansion)
  - Total Phases: 5
  - Expanded: 2
  - Balance: Good

Optimization Opportunities:

1. Phase 2: Authentication (complexity 9)
   Recommendation: Expand into stages
   Reason: Still highly complex after expansion

2. Phases 4-5: Testing and Deployment
   Recommendation: Consider merging
   Reason: Closely related, similar complexity
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Second-Round Analysis

The system can re-analyze to find new candidates:

```
Running second-round analysis...

New Expansion Candidates:
  - Phase 2: Authentication (complexity increased to 9)

Would you like to proceed with second-round expansion? (y/n):
```

### User Approval Gates

You control when operations proceed:

```
Recommendations Ready for Review
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Operations to perform:
  1. Expand phase 2 into stages
  2. Merge phases 4 and 5

Estimated time: 60s

Proceed with these operations? (y/n):
```

## Related Documentation

- [/orchestrate Command](../commands/orchestrate.md) - Full command documentation
- [/expand Command](../commands/expand.md) - Phase expansion details
- [/collapse Command](../commands/collapse.md) - Phase collapse details
- [Agent Development Guide](creating-agents.md) - Creating specialized agents
- [Adaptive Planning Guide](adaptive-planning-guide.md) - Progressive plan structures
