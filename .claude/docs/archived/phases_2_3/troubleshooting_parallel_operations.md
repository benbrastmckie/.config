# Troubleshooting Guide: Parallel Expansion/Collapse Operations

## Common Issues and Solutions

### 1. Context Overflow During Parallel Execution

**Symptoms:**
- "Context limit exceeded" errors
- Operations slow down significantly
- Unable to complete metadata updates

**Causes:**
- Too many parallel operations (>6)
- Artifact content loaded into context
- Large operation results

**Solutions:**

```bash
# Solution 1: Reduce parallel operations
# Modify batch size in command invocation
MAX_PARALLEL=4  # Instead of 6+

# Solution 2: Verify artifact-based aggregation
# Check that only artifact paths are collected, not content
artifact_refs=$(aggregate_expansion_artifacts "$plan_path")
echo "$artifact_refs" | jq '.artifacts[0]'  # Should be path only

# Solution 3: Cleanup old artifacts
cleanup_operation_artifacts "$plan_name"
```

**Prevention:**
- Limit parallel operations to 4-6
- Use artifact-based aggregation properly
- Clean up artifacts after completion
- Monitor context usage

### 2. Partial Failure: Some Operations Succeed, Some Fail

**Symptoms:**
- Mixed success/failure in operation results
- Some phases expanded, others not
- Metadata partially updated

**Causes:**
- Network timeouts
- Agent tool access issues
- File permission errors
- Race conditions

**Solutions:**

```bash
# Solution 1: Handle partial failures
result=$(handle_partial_failure "$aggregation_json")

# Check if can continue
can_continue=$(echo "$result" | jq -r '.can_continue')
if [[ "$can_continue" == "true" ]]; then
  # Update metadata for successful operations only
  coordinate_metadata_updates "$successful_ops"
fi

# Solution 2: Retry failed operations
failed_ops=$(echo "$result" | jq -r '.failed_operations')
for op in $(echo "$failed_ops" | jq -r '.[] | .item_id'); do
  retry_with_timeout "$op" 1
done

# Solution 3: Restore from checkpoint
checkpoint_data=$(restore_from_checkpoint "$checkpoint_file")
# Roll back to pre-operation state
```

**Prevention:**
- Use checkpoint system before operations
- Implement retry logic with exponential backoff
- Validate tool permissions before execution
- Monitor operation progress

### 3. Metadata Inconsistency After Parallel Operations

**Symptoms:**
- Structure Level incorrect (e.g., shows 0 but phases are expanded)
- Expanded Phases list missing items
- Plan metadata out of sync with actual files

**Causes:**
- Parallel metadata updates (race conditions)
- Partial failure without rollback
- Checkpoint not used
- Validation skipped

**Solutions:**

```bash
# Solution 1: Validate metadata consistency
detect_structure_level "$plan_path"  # Should match expected level
validate_expanded_phases "$plan_path"  # Should match actual files

# Solution 2: Repair metadata
# Update Structure Level
update_structure_level "$plan_path" 1

# Rebuild Expanded Phases list
expanded_phases=$(find "$plan_dir" -name "phase_*.md" | sort)
update_expanded_phases "$plan_path" "$expanded_phases"

# Solution 3: Restore from checkpoint
restore_from_checkpoint "$checkpoint_file"
```

**Prevention:**
- Always use sequential metadata coordination
- Checkpoint before metadata updates
- Validate after each update
- Use atomic operations

### 4. Checkpoint Corruption or Not Found

**Symptoms:**
- "Checkpoint file not found" errors
- Invalid JSON in checkpoint
- Unable to restore from checkpoint

**Causes:**
- Checkpoint file deleted prematurely
- Disk space issues during save
- Concurrent checkpoint operations
- Invalid JSON generation

**Solutions:**

```bash
# Solution 1: Validate checkpoint integrity
validation=$(validate_checkpoint_integrity "$checkpoint_file")
if [[ $(echo "$validation" | jq -r '.valid') == "false" ]]; then
  # Checkpoint corrupted, cannot restore
  echo "ERROR: Checkpoint corrupted"
  exit 1
fi

# Solution 2: Use backup checkpoint
# Checkpoints are timestamped, find previous one
prev_checkpoint=$(ls -t .claude/checkpoints/parallel_ops/ | head -2 | tail -1)
restore_from_checkpoint "$prev_checkpoint"

# Solution 3: Manual recovery
# If no checkpoint available, manually review and fix:
# 1. Check plan Structure Level
# 2. Verify expanded files exist
# 3. Rebuild metadata manually
```

**Prevention:**
- Ensure sufficient disk space
- Validate checkpoint after save
- Don't delete checkpoints until operations complete
- Use checkpoint backup strategy

### 5. Agent Timeout During Parallel Execution

**Symptoms:**
- "Operation timed out" errors
- Some agents don't complete
- Partial results in artifacts

**Causes:**
- Complex operations exceed timeout
- System resource constraints
- Network issues
- Too many concurrent operations

**Solutions:**

```bash
# Solution 1: Retry with extended timeout
retry_metadata=$(retry_with_timeout "expand_phase_3" 1)
new_timeout=$(echo "$retry_metadata" | jq -r '.new_timeout')
# Re-execute with new_timeout (180000ms = 3 min)

# Solution 2: Use reduced toolset
fallback=$(retry_with_fallback "expand_phase_3" 2)
reduced_toolset=$(echo "$fallback" | jq -r '.reduced_toolset')
# Re-execute with reduced_toolset: "Read,Write" only

# Solution 3: Escalate to user
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

### 6. Artifact Validation Failures

**Symptoms:**
- "Artifact not found" errors
- "Invalid artifact format" errors
- Missing operation results

**Causes:**
- Agent failed to save artifact
- Incorrect artifact path
- Artifact deleted prematurely
- Invalid JSON in artifact

**Solutions:**

```bash
# Solution 1: Validate artifacts exist
validate_operation_artifacts "$plan_name"

# Solution 2: Check artifact format
artifact_path=$(get_artifact_path "$plan_name" "expansion_3")
if [[ -f "$artifact_path" ]]; then
  jq empty "$artifact_path" || echo "Invalid JSON"
fi

# Solution 3: Regenerate missing artifacts
# Re-execute failed operation
execute_expansion_operation "phase_3"
```

**Prevention:**
- Validate artifacts immediately after creation
- Use proper artifact path conventions
- Don't cleanup artifacts during operations
- Implement artifact existence checks

### 7. Hierarchy Review Agent Returns No Recommendations

**Symptoms:**
- Empty recommendations after hierarchy review
- No optimization opportunities identified
- Second-round analysis skipped

**Causes:**
- Plan structure already optimal
- Complexity threshold not met
- Agent prompt unclear
- Analysis mode incorrect

**Solutions:**

```bash
# Solution 1: Check plan complexity
# If all phases have complexity 4-6, no expansion/collapse needed
analyze_plan_complexity "$plan_path"

# Solution 2: Adjust complexity thresholds
# Lower threshold for expansion (default: 8)
EXPANSION_THRESHOLD=7

# Solution 3: Force second-round analysis
# Even if hierarchy review found no issues
run_second_round_analysis "$plan_path" "$initial_analysis"
```

**Prevention:**
- Understand when hierarchy review is useful
- Set appropriate complexity thresholds
- Don't expect recommendations for already-optimal plans
- Review agent prompt clarity

### 8. User Approval Gate Hangs or Times Out

**Symptoms:**
- Waiting indefinitely for user input
- Non-interactive mode doesn't proceed
- Approval prompt not displayed

**Causes:**
- Running in non-interactive shell
- Input redirection issues
- Terminal not attached
- Timeout not configured

**Solutions:**

```bash
# Solution 1: Check if interactive
if [[ -t 0 ]]; then
  # Interactive mode
  present_recommendations_for_approval "$recommendations"
else
  # Non-interactive mode - auto-approve or skip
  echo "Non-interactive mode: skipping approval gate"
fi

# Solution 2: Use environment variable for auto-approval
AUTO_APPROVE=true present_recommendations_for_approval "$recommendations"

# Solution 3: Timeout for approval
# Present recommendations with timeout (e.g., 60 seconds)
timeout 60 present_recommendations_for_approval "$recommendations" || echo "Timeout: skipping"
```

**Prevention:**
- Detect interactive vs non-interactive mode
- Provide auto-approval option
- Implement approval timeouts
- Log approval decisions

### 9. Second-Round Analysis Detects No New Candidates

**Symptoms:**
- Second-round analysis returns empty results
- No new expansion/collapse recommendations
- Identical to first-round analysis

**Causes:**
- No complexity changes after operations
- Operations didn't affect complexity scores
- Threshold not adjusted
- Analysis mode incorrect

**Solutions:**

```bash
# Solution 1: Compare before/after complexity
initial_complexity=$(echo "$initial_analysis" | jq '.items[0].complexity')
current_complexity=$(get_current_complexity "$plan_path" "phase_1")
echo "Before: $initial_complexity, After: $current_complexity"

# Solution 2: Lower threshold for second round
# First round: threshold 8
# Second round: threshold 7
SECOND_ROUND_THRESHOLD=7

# Solution 3: Force hierarchy review
# Instead of second-round analysis, use hierarchy review
review_plan_hierarchy "$plan_path"
```

**Prevention:**
- Understand that second-round may find nothing
- Monitor complexity changes during operations
- Use hierarchy review for organizational improvements
- Don't assume second round always finds candidates

### 10. Performance Degradation with Large Plans

**Symptoms:**
- Operations slow down with 20+ phases
- Context usage increases significantly
- Metadata updates take longer

**Causes:**
- Plan file size too large
- Too many expanded phases
- Inefficient metadata updates
- Artifact cleanup not performed

**Solutions:**

```bash
# Solution 1: Batch metadata updates
# Instead of updating per operation, batch updates
update_metadata_batch "$plan_path" "$all_updates"

# Solution 2: Optimize plan file size
# Extract large phases to separate files
# Already at Structure Level 1 or 2

# Solution 3: Increase parallel batch size
# For large plans, expand more phases in parallel (up to 6)
MAX_PARALLEL=6

# Solution 4: Cleanup artifacts aggressively
cleanup_operation_artifacts "$plan_name"
```

**Prevention:**
- Use progressive structure levels (0→1→2)
- Cleanup artifacts regularly
- Optimize metadata update functions
- Monitor plan file size

## Diagnostic Commands

### Check System State

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

### Monitor Operation Progress

```bash
# Check artifact creation in real-time
watch -n 1 'ls -lt specs/artifacts/001_plan/ | head -10'

# Monitor context usage (if available)
echo "Context tokens: $(wc -w < /tmp/context.log)"

# Check metadata consistency
diff <(detect_structure_level "$plan_path") <(get_structure_level_metadata "$plan_path")
```

### Debugging Failed Operations

```bash
# Enable debug logging
export DEBUG=1

# Run operation with verbose output
invoke_expansion_agents_parallel "$recommendations" 2>&1 | tee operation.log

# Check for errors in log
grep -i error operation.log

# Validate all utilities loaded
declare -f invoke_expansion_agents_parallel
declare -f aggregate_expansion_artifacts
```

## Getting Help

### Before Reporting Issues

1. Check diagnostic commands above
2. Review error messages carefully
3. Verify prerequisites (jq, bash 4.0+)
4. Check disk space and permissions
5. Validate plan file structure

### Information to Include

When reporting issues, include:
- Plan structure level
- Number of parallel operations
- Error messages (full text)
- Checkpoint status
- Artifact directory contents
- System: OS, Bash version, available tools

### Contact and Resources

- GitHub Issues: (project repository)
- Documentation: `specs/orchestration-guide.md`
- Test Suites: `.claude/tests/test_parallel_*.sh`
- Utility Functions: `.claude/lib/auto-analysis-utils.sh`
