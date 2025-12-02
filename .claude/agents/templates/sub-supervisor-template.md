# Sub-Supervisor Template

## Overview

This template provides a reusable pattern for creating hierarchical supervisor agents that coordinate multiple worker agents in parallel while achieving 95% context reduction through metadata aggregation.

**Use this template when**:
- Coordinating 4+ workers for the same type of task (research, implementation, testing)
- Context reduction is critical (large worker outputs)
- Parallel execution is beneficial (independent workers)

**Template Variables** (replace when creating supervisor):
- `{{SUPERVISOR_TYPE}}`: Supervisor type (e.g., "research", "implementation", "testing")
- `{{WORKER_TYPE}}`: Worker agent type (e.g., "research-specialist", "implementation-executor")
- `{{WORKER_COUNT}}`: Number of workers to coordinate (e.g., 4)
- `{{TASK_DESCRIPTION}}`: Description of tasks workers will perform
- `{{OUTPUT_TYPE}}`: Type of output workers produce (e.g., "research reports", "code changes", "test files")
- `{{METADATA_FIELDS}}`: Specific metadata fields to extract from worker outputs

---

# {{SUPERVISOR_TYPE}}-Sub-Supervisor

## Agent Metadata

- **Agent Type**: Sub-Supervisor (Hierarchical Coordination)
- **Capability**: Coordinates {{WORKER_COUNT}} {{WORKER_TYPE}} agents in parallel
- **Context Reduction**: 95% (returns aggregated metadata only)
- **Invocation**: Via Task tool from orchestrator
- **Behavioral File**: `.claude/agents/{{SUPERVISOR_TYPE}}-sub-supervisor.md`

## Purpose

This supervisor coordinates {{WORKER_COUNT}} {{WORKER_TYPE}} workers to {{TASK_DESCRIPTION}} in parallel, achieving significant time savings and context reduction through:

1. **Parallel Execution**: All workers execute simultaneously (40-60% time savings)
2. **Metadata Aggregation**: Combine worker outputs into supervisor summary (95% context reduction)
3. **Checkpoint Coordination**: Save supervisor state for resume capability
4. **Partial Failure Handling**: Handle scenarios where some workers fail

## Inputs

This supervisor receives the following inputs from the orchestrator:

```json
{
  "tasks": [
    "{{TASK_1_DESCRIPTION}}",
    "{{TASK_2_DESCRIPTION}}",
    "{{TASK_3_DESCRIPTION}}",
    "{{TASK_4_DESCRIPTION}}"
  ],
  "output_directory": "/path/to/output",
  "state_file": "/path/to/.claude/tmp/workflow_$$.sh",
  "supervisor_id": "{{SUPERVISOR_TYPE}}_sub_supervisor_{{TIMESTAMP}}"
}
```

**Required Inputs**:
- `tasks`: Array of task descriptions (one per worker)
- `output_directory`: Directory for worker outputs
- `state_file`: Path to workflow state file (for checkpoint coordination)
- `supervisor_id`: Unique identifier for this supervisor instance

## Expected Outputs

This supervisor returns aggregated metadata ONLY (not full worker outputs):

```json
{
  "supervisor_id": "{{SUPERVISOR_TYPE}}_sub_supervisor_{{TIMESTAMP}}",
  "worker_count": {{WORKER_COUNT}},
  "{{OUTPUT_TYPE}}_created": ["/path1", "/path2", "/path3", "/path4"],
  "summary": "Combined 50-100 word summary integrating all worker outputs",
  "key_findings": ["finding1", "finding2", "finding3", "finding4"],
  "total_duration_ms": 45000,
  "context_tokens": 500
}
```

**Context Reduction**: Returns ~500 tokens vs ~10,000 tokens if full worker outputs returned (95% reduction).

---

## Execution Protocol

### STEP 1: Load Workflow State

**EXECUTE NOW**: Load workflow state file initialized by orchestrator.

```bash
# Source state persistence library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"

# Load workflow state (contains CLAUDE_PROJECT_DIR, STATE_FILE, etc.)
load_workflow_state "{{WORKFLOW_ID}}"

# Verify state loaded
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
  echo "ERROR: Workflow state not loaded. Cannot proceed." >&2
  exit 1
fi

echo "✓ Workflow state loaded: $STATE_FILE"
```

---

### STEP 2: Parse Inputs

**EXECUTE NOW**: Parse supervisor inputs from orchestrator prompt.

```bash
# Extract inputs (provided by orchestrator in prompt)
TASKS=({{TASK_1}} {{TASK_2}} {{TASK_3}} {{TASK_4}})
OUTPUT_DIR="{{OUTPUT_DIRECTORY}}"
SUPERVISOR_ID="{{SUPERVISOR_ID}}"

# Validate inputs
if [ ${#TASKS[@]} -eq 0 ]; then
  echo "ERROR: No tasks provided" >&2
  exit 1
fi

if [ -z "$OUTPUT_DIR" ]; then
  echo "ERROR: No output directory provided" >&2
  exit 1
fi

echo "✓ Supervisor inputs parsed: ${#TASKS[@]} tasks"
```

---

### STEP 3: Invoke Workers in Parallel

**EXECUTE NOW**: USE the Task tool to invoke {{WORKER_COUNT}} workers simultaneously.

**CRITICAL**: Send a SINGLE message with {{WORKER_COUNT}} Task tool invocations for parallel execution.

**Worker 1 - {{TASK_1_DESCRIPTION}}**:

```
**EXECUTE NOW**: USE the Task tool to invoke the worker.

Task {
  subagent_type: "general-purpose"
  description: "{{TASK_1_DESCRIPTION}}"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/{{WORKER_TYPE}}.md

    INPUTS:
    - Task: {{TASK_1_DESCRIPTION}}
    - Output path: ${OUTPUT_DIR}/001_{{OUTPUT_FILENAME_1}}

    REQUIRED OUTPUT:
    Return completion signal with output path:
    {{OUTPUT_SIGNAL}}: /path/to/output
}
```

**Worker 2 - {{TASK_2_DESCRIPTION}}**:

```
**EXECUTE NOW**: USE the Task tool to invoke the worker.

Task {
  subagent_type: "general-purpose"
  description: "{{TASK_2_DESCRIPTION}}"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/{{WORKER_TYPE}}.md

    INPUTS:
    - Task: {{TASK_2_DESCRIPTION}}
    - Output path: ${OUTPUT_DIR}/002_{{OUTPUT_FILENAME_2}}

    REQUIRED OUTPUT:
    Return completion signal with output path:
    {{OUTPUT_SIGNAL}}: /path/to/output
}
```

**Worker 3 - {{TASK_3_DESCRIPTION}}**:

```
**EXECUTE NOW**: USE the Task tool to invoke the worker.

Task {
  subagent_type: "general-purpose"
  description: "{{TASK_3_DESCRIPTION}}"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/{{WORKER_TYPE}}.md

    INPUTS:
    - Task: {{TASK_3_DESCRIPTION}}
    - Output path: ${OUTPUT_DIR}/003_{{OUTPUT_FILENAME_3}}

    REQUIRED OUTPUT:
    Return completion signal with output path:
    {{OUTPUT_SIGNAL}}: /path/to/output
}
```

**Worker 4 - {{TASK_4_DESCRIPTION}}**:

```
**EXECUTE NOW**: USE the Task tool to invoke the worker.

Task {
  subagent_type: "general-purpose"
  description: "{{TASK_4_DESCRIPTION}}"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/{{WORKER_TYPE}}.md

    INPUTS:
    - Task: {{TASK_4_DESCRIPTION}}
    - Output path: ${OUTPUT_DIR}/004_{{OUTPUT_FILENAME_4}}

    REQUIRED OUTPUT:
    Return completion signal with output path:
    {{OUTPUT_SIGNAL}}: /path/to/output
}
```

**WAIT**: Workers execute in parallel. Do not proceed until all workers complete.

---

### STEP 4: Extract Worker Metadata

**EXECUTE NOW**: Extract metadata from each worker output.

```bash
# Source metadata extraction library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/metadata-extraction.sh"

# Parse worker completion signals
WORKER_1_OUTPUT="{{WORKER_1_OUTPUT_PATH}}"
WORKER_2_OUTPUT="{{WORKER_2_OUTPUT_PATH}}"
WORKER_3_OUTPUT="{{WORKER_3_OUTPUT_PATH}}"
WORKER_4_OUTPUT="{{WORKER_4_OUTPUT_PATH}}"

# Extract metadata from worker outputs
WORKER_1_METADATA=$(extract_{{METADATA_FUNCTION}} "$WORKER_1_OUTPUT")
WORKER_2_METADATA=$(extract_{{METADATA_FUNCTION}} "$WORKER_2_OUTPUT")
WORKER_3_METADATA=$(extract_{{METADATA_FUNCTION}} "$WORKER_3_OUTPUT")
WORKER_4_METADATA=$(extract_{{METADATA_FUNCTION}} "$WORKER_4_OUTPUT")

# Example metadata structure:
# {
#   "title": "{{OUTPUT_TITLE}}",
#   "summary": "{{OUTPUT_SUMMARY}}",
#   "{{METADATA_FIELD_1}}": "{{VALUE_1}}",
#   "{{METADATA_FIELD_2}}": ["{{VALUE_2A}}", "{{VALUE_2B}}"]
# }

echo "✓ Metadata extracted from all workers"
```

**Metadata Extraction Functions** (examples):

- Research reports: `extract_report_metadata()` → title, summary, key_findings
- Implementation files: `extract_implementation_metadata()` → files_modified, lines_changed, tests_created
- Test files: `extract_test_metadata()` → test_count, coverage_percent, failures

---

### STEP 5: Aggregate Worker Metadata

**EXECUTE NOW**: Combine worker metadata into supervisor summary.

```bash
# Build workers array
WORKERS_ARRAY=$(jq -n \
  --argjson worker1 "$WORKER_1_METADATA" \
  --argjson worker2 "$WORKER_2_METADATA" \
  --argjson worker3 "$WORKER_3_METADATA" \
  --argjson worker4 "$WORKER_4_METADATA" \
  '[
    {
      worker_id: "{{WORKER_TYPE}}_1",
      task: "{{TASK_1_DESCRIPTION}}",
      status: "completed",
      output_path: "'"$WORKER_1_OUTPUT"'",
      duration_ms: 12000,
      metadata: $worker1
    },
    {
      worker_id: "{{WORKER_TYPE}}_2",
      task: "{{TASK_2_DESCRIPTION}}",
      status: "completed",
      output_path: "'"$WORKER_2_OUTPUT"'",
      duration_ms: 10500,
      metadata: $worker2
    },
    {
      worker_id: "{{WORKER_TYPE}}_3",
      task: "{{TASK_3_DESCRIPTION}}",
      status: "completed",
      output_path: "'"$WORKER_3_OUTPUT"'",
      duration_ms: 11200,
      metadata: $worker3
    },
    {
      worker_id: "{{WORKER_TYPE}}_4",
      task: "{{TASK_4_DESCRIPTION}}",
      status: "completed",
      output_path: "'"$WORKER_4_OUTPUT"'",
      duration_ms: 9800,
      metadata: $worker4
    }
  ]')

# Aggregate metadata
AGGREGATED_METADATA=$(aggregate_worker_metadata "$WORKERS_ARRAY")
# Returns: {
#   "{{OUTPUT_TYPE}}_count": 4,
#   "{{OUTPUT_TYPE}}_created": ["path1", "path2", "path3", "path4"],
#   "summary": "Combined 50-100 word summary",
#   "{{METADATA_FIELD_1}}": [...],
#   "total_duration_ms": 43500,
#   "context_tokens": 500
# }

echo "✓ Worker metadata aggregated (95% context reduction)"
```

**Aggregation Algorithm** (customize per supervisor type):

```bash
aggregate_worker_metadata() {
  local workers_array="$1"

  # Combine summaries (50-100 words total)
  local combined_summary=$(echo "$workers_array" | jq -r '
    [.[].metadata.summary] | join(". ") |
    split(" ") | .[0:100] | join(" ")
  ')

  # Merge {{METADATA_FIELD_1}} (top 2 per worker, max 12 total)
  local merged_{{METADATA_FIELD_1}}=$(echo "$workers_array" | jq -r '
    [.[].metadata.{{METADATA_FIELD_1}}[] | select(. != null)] |
    .[0:12]
  ')

  # Calculate totals
  local total_duration=$(echo "$workers_array" | jq '[.[].duration_ms] | add')
  local context_tokens=$(echo "$combined_summary" | wc -c | awk '{print int($1/4)}')

  # Build aggregated metadata
  jq -n \
    --argjson workers "$workers_array" \
    --arg summary "$combined_summary" \
    --argjson {{METADATA_FIELD_1}} "$merged_{{METADATA_FIELD_1}}" \
    --argjson duration "$total_duration" \
    --argjson tokens "$context_tokens" \
    '{
      {{OUTPUT_TYPE}}_count: ($workers | length),
      {{OUTPUT_TYPE}}_created: [$workers[].output_path],
      summary: $summary,
      {{METADATA_FIELD_1}}: ${{METADATA_FIELD_1}},
      total_duration_ms: $duration,
      context_tokens: $tokens
    }'
}
```

---

### STEP 6: Save Supervisor Checkpoint

**EXECUTE NOW**: Save supervisor state to checkpoint for resume capability.

```bash
# Build supervisor checkpoint
SUPERVISOR_CHECKPOINT=$(jq -n \
  --arg supervisor_id "$SUPERVISOR_ID" \
  --arg supervisor_name "{{SUPERVISOR_TYPE}}-sub-supervisor" \
  --argjson worker_count {{WORKER_COUNT}} \
  --argjson workers "$WORKERS_ARRAY" \
  --argjson aggregated "$AGGREGATED_METADATA" \
  '{
    supervisor_id: $supervisor_id,
    supervisor_name: $supervisor_name,
    worker_count: $worker_count,
    workers: $workers,
    aggregated_metadata: $aggregated
  }')

# Save supervisor checkpoint using state-persistence.sh
save_json_checkpoint "{{SUPERVISOR_TYPE}}_supervisor" "$SUPERVISOR_CHECKPOINT"

echo "✓ Supervisor checkpoint saved: {{SUPERVISOR_TYPE}}_supervisor.json"
```

**Checkpoint Location**: `.claude/tmp/{{SUPERVISOR_TYPE}}_supervisor.json`

---

### STEP 7: Handle Partial Failures (if applicable)

**EXECUTE NOW**: Check for worker failures and handle gracefully.

```bash
# Check worker status
SUCCESSFUL_WORKERS=$(echo "$WORKERS_ARRAY" | jq '[.[] | select(.status == "completed")]')
FAILED_WORKERS=$(echo "$WORKERS_ARRAY" | jq '[.[] | select(.status == "failed")]')

SUCCESS_COUNT=$(echo "$SUCCESSFUL_WORKERS" | jq 'length')
FAILURE_COUNT=$(echo "$FAILED_WORKERS" | jq 'length')

if [ $FAILURE_COUNT -gt 0 ]; then
  if [ $SUCCESS_COUNT -ge 2 ]; then
    # Partial success: aggregate successful workers only
    echo "WARNING: $FAILURE_COUNT workers failed, but $SUCCESS_COUNT succeeded"

    # Re-aggregate with successful workers only
    AGGREGATED_METADATA=$(aggregate_worker_metadata "$SUCCESSFUL_WORKERS")

    # Add failure context
    FAILURE_SUMMARY=$(echo "$FAILED_WORKERS" | jq -r '
      [.[] | "Failed: \(.task) (\(.error))"] | join("; ")
    ')

    AGGREGATED_METADATA=$(echo "$AGGREGATED_METADATA" | jq \
      --arg failures "$FAILURE_SUMMARY" \
      '.partial_failures = $failures')

  else
    # Complete failure: all workers failed
    echo "ERROR: All workers failed" >&2

    FAILURE_DETAILS=$(echo "$FAILED_WORKERS" | jq '[.[] | {task: .task, error: .error}]')
    echo "SUPERVISOR_FAILED: {\"errors\": $FAILURE_DETAILS}" >&2
    exit 1
  fi
fi
```

**Partial Failure Strategy**:
- **≥50% workers succeed**: Return aggregated metadata with failure context
- **<50% workers succeed**: Return error and abort

---

### STEP 8: Return Aggregated Metadata

**EXECUTE NOW**: Return completion signal with aggregated metadata ONLY.

```bash
# Build completion response
COMPLETION_RESPONSE=$(jq -n \
  --arg supervisor_id "$SUPERVISOR_ID" \
  --argjson aggregated "$AGGREGATED_METADATA" \
  '{
    supervisor_id: $supervisor_id,
    aggregated_metadata: $aggregated
  }')

# Return completion signal
echo "SUPERVISOR_COMPLETE: $COMPLETION_RESPONSE"

# Context reduction validation
WORKER_TOKENS=$(echo "$WORKERS_ARRAY" | jq '[.[].metadata] | @json' | wc -c | awk '{print int($1/4)}')
AGGREGATED_TOKENS=$(echo "$AGGREGATED_METADATA" | jq '@json' | wc -c | awk '{print int($1/4)}')
REDUCTION_PERCENT=$(echo "scale=1; (($WORKER_TOKENS - $AGGREGATED_TOKENS) / $WORKER_TOKENS) * 100" | bc)

echo "✓ Context reduction: $REDUCTION_PERCENT% ($WORKER_TOKENS → $AGGREGATED_TOKENS tokens)" >&2
```

**Expected Output**:

```
SUPERVISOR_COMPLETE: {
  "supervisor_id": "{{SUPERVISOR_TYPE}}_sub_supervisor_20251107_143030",
  "aggregated_metadata": {
    "{{OUTPUT_TYPE}}_count": 4,
    "{{OUTPUT_TYPE}}_created": ["path1", "path2", "path3", "path4"],
    "summary": "Combined 50-100 word summary integrating all worker outputs",
    "{{METADATA_FIELD_1}}": ["item1", "item2", "item3", "item4"],
    "total_duration_ms": 43500,
    "context_tokens": 500
  }
}
```

---

## Usage Example

### Orchestrator Invocation

```bash
# In orchestrator command (e.g., coordinate.md)

# Detect if hierarchical supervision needed
if [ $TASK_COUNT -ge 4 ]; then
  # Use hierarchical supervision
  USE the Task tool to invoke {{SUPERVISOR_TYPE}} supervisor:

  Task {
    subagent_type: "general-purpose"
    description: "Coordinate {{SUPERVISOR_TYPE}} across {{WORKER_COUNT}} tasks"
    prompt: |
      Read and follow behavioral guidelines from:
      ${CLAUDE_PROJECT_DIR}/.claude/agents/{{SUPERVISOR_TYPE}}-sub-supervisor.md

      INPUTS:
      - Tasks: {{TASK_1}},{{TASK_2}},{{TASK_3}},{{TASK_4}}
      - Output directory: ${OUTPUT_DIR}
      - State file: ${STATE_FILE}
      - Supervisor ID: {{SUPERVISOR_TYPE}}_sub_supervisor_$(date +%s)

      REQUIRED OUTPUT:
      SUPERVISOR_COMPLETE: <aggregated_metadata_json>
  }

  # Extract aggregated metadata from supervisor response
  SUPERVISOR_RESPONSE=$(parse_supervisor_response "$TASK_TOOL_OUTPUT")
  AGGREGATED_METADATA=$(echo "$SUPERVISOR_RESPONSE" | jq -r '.aggregated_metadata')

  # Save to checkpoint (95% context reduction vs full worker outputs)
  save_json_checkpoint "{{SUPERVISOR_TYPE}}_supervisor" "$SUPERVISOR_RESPONSE"
fi
```

---

## Customization Guide

### Creating New Supervisor from Template

1. **Copy template**: `cp sub-supervisor-template.md {{SUPERVISOR_TYPE}}-sub-supervisor.md`
2. **Replace template variables**:
   - `{{SUPERVISOR_TYPE}}`: e.g., "research", "implementation", "testing"
   - `{{WORKER_TYPE}}`: e.g., "research-specialist", "implementation-executor"
   - `{{WORKER_COUNT}}`: e.g., 4
   - `{{TASK_DESCRIPTION}}`: e.g., "research authentication patterns"
   - `{{OUTPUT_TYPE}}`: e.g., "reports", "files", "tests"
   - `{{METADATA_FIELDS}}`: e.g., "key_findings", "files_modified", "test_results"
3. **Customize aggregation algorithm**: Modify `aggregate_worker_metadata()` for supervisor-specific metadata
4. **Test supervisor**: Create test cases in `.claude/tests/test_{{SUPERVISOR_TYPE}}_supervisor.sh`

### Example Customizations

**Research Supervisor**:
- `{{METADATA_FIELD_1}}`: `key_findings`
- `{{OUTPUT_TYPE}}`: `reports`
- Aggregation: Merge top 2 findings per worker (max 12 total)

**Implementation Supervisor**:
- `{{METADATA_FIELD_1}}`: `files_modified`
- `{{OUTPUT_TYPE}}`: `code_changes`
- Aggregation: Count total files, lines, tests created

**Testing Supervisor**:
- `{{METADATA_FIELD_1}}`: `test_results`
- `{{OUTPUT_TYPE}}`: `tests`
- Aggregation: Sum passed/failed counts, calculate coverage %

---

## Performance Characteristics

### Context Reduction

- **Full worker outputs**: ~10,000 tokens ({{WORKER_COUNT}} workers × 2,500 tokens each)
- **Aggregated metadata**: ~500 tokens (supervisor summary)
- **Reduction**: 95% ((10,000 - 500) / 10,000)

### Time Savings (Parallel Execution)

- **Sequential execution**: Sum of worker durations (~45 seconds for 4 workers)
- **Parallel execution**: Max worker duration (~12 seconds)
- **Time savings**: 73% ((45 - 12) / 45)

### Threshold for Hierarchical Supervision

Use hierarchical supervision when:
- **Worker count**: ≥ 4 workers (context reduction justifies overhead)
- **Worker output size**: > 2,000 tokens each (significant context savings)
- **Parallel execution benefit**: Workers are independent (no sequential dependencies)

---

## References

- [Hierarchical Supervisor Coordination Architecture](../architecture/hierarchical-supervisor-coordination.md)
- [State Persistence Library](../reference/library-api.md#state-persistence)
- [Metadata Extraction Library](../reference/library-api.md#metadata-extraction)
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md)
- [Checkpoint Schema v2.0](../reference/library-api.md#checkpoint-schema-v20)

---

## Template Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-11-07 | Initial template for Phase 4 |
