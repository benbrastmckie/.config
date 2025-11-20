# Orchestration Guide - Troubleshooting

## Navigation

This document is part of a multi-part guide:
- [Overview](orchestration-guide-overview.md) - Quick start, architecture, and artifact-based aggregation
- [Patterns](orchestration-guide-patterns.md) - Context pruning, user workflows, and error recovery
- [Examples](orchestration-guide-examples.md) - Wave-based execution and behavioral injection examples
- **Troubleshooting** (this file) - Common issues, diagnostics, and reference

---

## Common Issues

### 1. Context Overflow During Parallel Execution

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

### 2. Partial Failure: Some Operations Succeed, Some Fail

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

### 3. Metadata Inconsistency After Parallel Operations

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

### 4. Agent Timeout During Parallel Execution

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

### 5. Artifact Validation Failures

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

---

## Diagnostic Commands

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

---

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

- **Expand:** complexity >= 8/10
- **Collapse:** complexity <= 4/10
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

---

## Related Documentation

- [Overview](orchestration-guide-overview.md) - Quick start, architecture, and artifact-based aggregation
- [Patterns](orchestration-guide-patterns.md) - Context pruning, user workflows, and error recovery
- [Examples](orchestration-guide-examples.md) - Wave-based execution and behavioral injection examples
- [/orchestrate Command](../../commands/orchestrate.md) - Full command documentation
- [/expand Command](../../commands/expand.md) - Phase expansion details
- [/collapse Command](../../commands/collapse.md) - Phase collapse details
- [Agent Development Guide](../guides/development/agent-development/agent-development-fundamentals.md) - Creating specialized agents
- [Adaptive Planning Guide](adaptive-planning-guide.md) - Progressive plan structures
