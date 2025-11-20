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
  echo "⚠ Context usage above target, applying aggressive pruning"
  apply_pruning_policy --mode aggressive --workflow "$WORKFLOW_TYPE"
fi
```

**Expected Context Usage by Workflow Phase:**

| Workflow | Phase 1 | Phase 2 | Phase 3 | Phase 4 | Phase 5 | Phase 6 | Phase 7 |
|----------|---------|---------|---------|---------|---------|---------|---------|
| **Orchestrate (aggressive pruning)** | 15% | 18% | 22% | 20% | 19% | 21% | 18% |
| **Implement (moderate pruning)** | 18% | 24% | 28% | 26% | 25% | - | - |
| **Single-agent (minimal pruning)** | 25% | 35% | 42% | - | - | - | - |

### Complete Example: Orchestrate Workflow with Aggressive Pruning

```bash
#!/bin/bash
# /orchestrate workflow with context pruning

# Phase 1: Research (parallel, 3 agents)
RESEARCH_OUTPUTS=(research1.md research2.md research3.md)
for output in "${RESEARCH_OUTPUTS[@]}"; do
  METADATA=$(extract_report_metadata "$output")
  prune_subagent_output "$output" "$METADATA"
done
apply_pruning_policy --mode aggressive --workflow orchestrate --phase research
# Context: 15% (750 tokens metadata only)

# Phase 2: Planning (single agent)
PLAN_OUTPUT="specs/042_auth/plans/001_implementation.md"
PLAN_METADATA=$(extract_plan_metadata "$PLAN_OUTPUT")
prune_subagent_output "$PLAN_OUTPUT" "$PLAN_METADATA"
apply_pruning_policy --mode aggressive --workflow orchestrate --phase planning
# Context: 18% (750 + 250 = 1,000 tokens accumulated)

# Phase 3: Implementation (phase 1 only)
implement_phase_1 "$PLAN_OUTPUT"
PHASE_1_DATA='{"phase": 1, "status": "completed", "commit": "abc123"}'
prune_phase_metadata "phase_1" "$PHASE_1_DATA"
apply_pruning_policy --mode aggressive --workflow orchestrate --phase implementation
# Context: 22% (1,000 + 500 = 1,500 tokens accumulated)

# Phases 4-7: Continue with aggressive pruning...
# Final context: 18% (vs 85% without pruning)
```

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

## Wave-Based Parallel Execution

### Overview

Wave-based execution (from Plan 080) enables parallel implementation of independent plan phases while respecting dependency constraints. This provides 40-60% time savings compared to sequential execution.

### Dependency-Driven Wave Organization

**Phase Dependency Syntax**:
```yaml
## Dependencies
- depends_on: [phase_1, phase_2]
- blocks: [phase_5, phase_6]
```

**Wave Calculation**:
1. **Wave 1**: All phases with no dependencies (empty `depends_on` list)
2. **Wave 2**: Phases dependent only on Wave 1 phases
3. **Wave N**: Phases dependent only on phases in previous waves

**Example from Plan 080**:
```
Plan with 6 phases:
- Phase 1: Setup (no dependencies)               → Wave 1
- Phase 2: Database (no dependencies)            → Wave 1
- Phase 3: API (depends_on: [phase_2])          → Wave 2
- Phase 4: Auth (depends_on: [phase_2])         → Wave 2
- Phase 5: Integration (depends_on: [phase_3, phase_4]) → Wave 3
- Phase 6: Testing (depends_on: [phase_5])      → Wave 4

Execution:
Wave 1: Phases 1, 2 in parallel (200s max, not 380s sum)
Wave 2: Phases 3, 4 in parallel (210s max, not 420s sum)
Wave 3: Phase 5 sequential (180s)
Wave 4: Phase 6 sequential (150s)

Total: 740s (vs 1,140s sequential)
Savings: 35%
```

### Implementer-Coordinator Subagent

The implementer-coordinator manages wave-based execution:

**Responsibilities**:
1. Parse plan hierarchy (Level 0 → Level 1 → Level 2)
2. Extract dependency metadata from all phases/stages
3. Build dependency graph and calculate waves
4. Invoke implementation-executor subagents in parallel per wave
5. Monitor wave completion before starting next wave
6. Update plan hierarchy with progress checkboxes

**Context Injection** (Behavioral Injection Pattern):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Coordinate wave-based implementation"
  prompt: |
    Read: .claude/agents/implementer-coordinator.md

    **Plan Path**: ${PLAN_PATH}
    **Topic Directory**: ${TOPIC_DIR}

    Execute wave-based implementation:
    1. Parse plan hierarchy and dependencies
    2. Calculate waves
    3. Invoke executors in parallel per wave
    4. Update plan files with progress
    5. Return wave execution summary
}
```

**Output** (Metadata Only):
```json
{
  "waves_executed": 4,
  "phases_completed": 6,
  "time_saved": "35%",
  "failures": [],
  "checkpoint_path": ".claude/data/checkpoints/implement_027_auth.json"
}
```

### Progress Tracking Across Plan Hierarchy

Wave execution updates all levels of plan hierarchy:

**Level 2** (Stage file):
```markdown
### Stage 1: Database Schema
- [x] Design user table
- [x] Design session table
- [ ] Create migration scripts
```

**Level 1** (Phase file aggregates stages):
```markdown
### Phase 2: Database Implementation
**Progress**: 2/3 stages complete (67%)
- [x] Stage 1: Database Schema (2/3 tasks)
- [ ] Stage 2: Query Layer
- [ ] Stage 3: Testing
```

**Level 0** (Main plan aggregates phases):
```markdown
### Phase 2: Database Implementation
**Status**: In Progress (Wave 1)
**Progress**: 2/9 total tasks complete (22%)

See [phase_2_database.md](phase_2_database.md) for details.
```

**Checkpoint Propagation**:
Each executor creates checkpoints containing:
- Current wave number
- Phase/stage completion status
- Task-level checkbox states
- Updated plan file paths (all levels)
- Next wave to execute

### Cross-References to Patterns

**Wave-based execution implements**:
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Commands control orchestration
- [Parallel Execution Pattern](../concepts/patterns/parallel-execution.md) - Concurrent wave execution
- [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md) - Wave state preservation
- [Hierarchical Supervision Pattern](../concepts/patterns/hierarchical-supervision.md) - Coordinator → Executors

## Behavioral Injection Example: Complete Workflow

This section demonstrates a complete workflow using the behavioral injection pattern with topic-based artifact organization, showing research through planning phases.

**Key Concepts**:
- Topic-based artifact organization
- Behavioral injection pattern
- Metadata-only context passing
- Cross-reference requirements

### Workflow: User Authentication Research and Planning

#### Step 1: Calculate Topic Directory

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact/artifact-creation.sh"

FEATURE_DESCRIPTION="User authentication with OAuth 2.0"
TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE_DESCRIPTION" "specs")

echo "Topic directory: $TOPIC_DIR"
# Output: specs/027_user_authentication
```

**Key Points**:
- Topic directory calculated from feature description
- Sequential numbering (027 = next available number)
- All workflow artifacts will live in this directory

#### Step 2: Research Phase (Parallel Research Agents)

**Calculate Research Report Paths**:

```bash
REPORT_OAUTH=$(create_topic_artifact "$TOPIC_DIR" "reports" "oauth_security" "")
REPORT_DB=$(create_topic_artifact "$TOPIC_DIR" "reports" "database_design" "")
REPORT_BEST_PRACTICES=$(create_topic_artifact "$TOPIC_DIR" "reports" "best_practices" "")

echo "Research reports:"
echo "  - $REPORT_OAUTH"
echo "  - $REPORT_DB"
echo "  - $REPORT_BEST_PRACTICES"
# Output:
#   - specs/027_user_authentication/reports/027_oauth_security.md
#   - specs/027_user_authentication/reports/028_database_design.md
#   - specs/027_user_authentication/reports/029_best_practices.md
```

**Invoke Research Agents in Parallel**:

```bash
# Invoke 3 research agents in parallel (single message, multiple Task calls)
Task {
  subagent_type: "general-purpose"
  description: "Research OAuth 2.0 security patterns"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent.

    **Research Topic**: OAuth 2.0 security patterns for authentication
    **Focus Areas**: Security best practices, common vulnerabilities, recommended flows
    **Report Output Path**: ${REPORT_OAUTH}

    Create research report at the exact path provided.
    Return metadata: {path, summary (≤50 words), key_findings[]}
}

Task {
  subagent_type: "general-purpose"
  description: "Research database design for auth"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent.

    **Research Topic**: Database schema design for user authentication
    **Focus Areas**: User table structure, session management, token storage
    **Report Output Path**: ${REPORT_DB}

    Create research report at the exact path provided.
    Return metadata: {path, summary (≤50 words), key_findings[]}
}

Task {
  subagent_type: "general-purpose"
  description: "Research authentication best practices"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent.

    **Research Topic**: Authentication implementation best practices
    **Focus Areas**: Password hashing, 2FA, session management, security headers
    **Report Output Path**: ${REPORT_BEST_PRACTICES}

    Create research report at the exact path provided.
    Return metadata: {path, summary (≤50 words), key_findings[]}
}
```

**Key Points**:
- All 3 agents invoked in parallel (single message)
- Each agent receives pre-calculated path
- Agents use `research-specialist.md` behavioral guidelines
- Agents return metadata only (not full content)
- 40-60% time savings vs sequential invocation

**Extract Metadata**:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/metadata-extraction.sh"

# Verify artifacts created
VERIFIED_OAUTH=$(verify_artifact_or_recover "$REPORT_OAUTH" "oauth_security")
VERIFIED_DB=$(verify_artifact_or_recover "$REPORT_DB" "database_design")
VERIFIED_BEST=$(verify_artifact_or_recover "$REPORT_BEST_PRACTICES" "best_practices")

# Extract metadata only (95% context reduction)
METADATA_OAUTH=$(extract_report_metadata "$VERIFIED_OAUTH")
METADATA_DB=$(extract_report_metadata "$VERIFIED_DB")
METADATA_BEST=$(extract_report_metadata "$VERIFIED_BEST")

# Context reduction: 3 reports x 5000 tokens = 15000 tokens
#                    3 metadata x 250 tokens = 750 tokens
#                    Reduction: 95% (15000 → 750)
```

#### Step 3: Planning Phase (Plan Architect Agent)

**Calculate Plan Path**:

```bash
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")

echo "Plan path: $PLAN_PATH"
# Output: specs/027_user_authentication/plans/027_implementation.md
```

**Invoke Plan Architect Agent**:

```bash
# Collect research report paths for cross-referencing
RESEARCH_REPORTS="
  - ${VERIFIED_OAUTH}
  - ${VERIFIED_DB}
  - ${VERIFIED_BEST}
"

# Invoke plan-architect agent
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan for user authentication"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are acting as a Plan Architect Agent.

    **Feature**: User authentication with OAuth 2.0
    **Research Reports**: ${RESEARCH_REPORTS}
    **Plan Output Path**: ${PLAN_PATH}

    **Context from Research**:
    - OAuth Security: ${SUMMARY_OAUTH}
    - Database Design: ${SUMMARY_DB}
    - Best Practices: ${SUMMARY_BEST}

    **Requirements**:
    1. Create implementation plan at exact path provided
    2. Include "Research Reports" metadata section with all report paths
    3. Structure plan with phases, tasks, success criteria
    4. Reference research findings in plan phases

    Return metadata: {path, phase_count, complexity_score, estimated_hours}
}
```

**Key Points**:
- Agent receives research summaries (not full reports)
- Agent receives all research report paths for cross-referencing
- Agent creates plan at exact path provided
- Agent includes "Research Reports" metadata section
- Agent uses Write tool (not SlashCommand)

#### Step 4: Complete Workflow Artifact Structure

Final artifact structure:

```
specs/027_user_authentication/
├── reports/
│   ├── 027_oauth_security.md            (research report 1)
│   ├── 028_database_design.md           (research report 2)
│   └── 029_best_practices.md            (research report 3)
├── plans/
│   └── 027_implementation.md            (plan with cross-references to reports)
└── summaries/
    └── 027_research_and_planning.md     (summary with cross-references to all artifacts)
```

**Benefits Demonstrated**:
1. **Topic-Based Organization**: All artifacts in single directory (easy navigation)
2. **Behavioral Injection**: Commands control orchestration, agents execute
3. **Metadata-Only Passing**: 95% context reduction throughout workflow
4. **Parallel Execution**: 40-60% time savings with parallel agents
5. **Cross-Referencing**: Complete audit trail from summary to research
6. **Path Control**: Commands pre-calculate paths (consistent numbering)
7. **No Recursion**: Agents use Write tool (never SlashCommand)

**Context Reduction Metrics**:

**Without Behavioral Injection**:
- Research phase: 3 reports x 5000 tokens = 15000 tokens
- Planning phase: 15000 tokens + plan 3000 tokens = 18000 tokens
- Total context: 18000 tokens (90% of available context)

**With Behavioral Injection**:
- Research phase: 3 metadata x 250 tokens = 750 tokens
- Planning phase: 750 tokens + plan metadata 200 tokens = 950 tokens
- Total context: 950 tokens (5% of available context)

**Reduction**: 95% (18000 → 950 tokens)

**See Also**:
- [Agent Development Guide](../guides/development/agent-development/agent-development-fundamentals.md) - Creating agent behavioral files
- [Command Development Guide](../guides/development/command-development/command-development-fundamentals.md) - Invoking agents from commands
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Pattern details
- [Troubleshooting Guide](../troubleshooting/agent-delegation-troubleshooting.md) - Common issues and solutions

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

- [/orchestrate Command](../../commands/orchestrate.md) - Full command documentation
- [/expand Command](../../commands/expand.md) - Phase expansion details
- [/collapse Command](../../commands/collapse.md) - Phase collapse details
- [Agent Development Guide](../guides/development/agent-development/agent-development-fundamentals.md) - Creating specialized agents
- [Adaptive Planning Guide](adaptive-planning-guide.md) - Progressive plan structures
