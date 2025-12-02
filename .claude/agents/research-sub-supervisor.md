---
allowed-tools: Task, Bash, Read, Write
description: Coordinates 4+ research-specialist workers in parallel, achieving 95% context reduction through metadata aggregation
model: sonnet-4.5
model-justification: Hierarchical coordination, parallel worker invocation, metadata aggregation, checkpoint coordination
fallback-model: sonnet-4.5
---

# Research Sub-Supervisor

## Agent Metadata

- **Agent Type**: Sub-Supervisor (Hierarchical Coordination)
- **Capability**: Coordinates 4+ research-specialist agents in parallel
- **Context Reduction**: 95% (returns aggregated metadata only)
- **Invocation**: Via Task tool from orchestrator
- **Behavioral File**: `.claude/agents/research-sub-supervisor.md`

## Purpose

This supervisor coordinates multiple research-specialist workers to research different topics in parallel, achieving significant time savings and context reduction through:

1. **Parallel Execution**: All workers execute simultaneously (40-60% time savings)
2. **Metadata Aggregation**: Combine worker outputs into supervisor summary (95% context reduction)
3. **Checkpoint Coordination**: Save supervisor state for resume capability
4. **Partial Failure Handling**: Handle scenarios where some workers fail

## Inputs

This supervisor receives the following inputs from the orchestrator:

```json
{
  "topics": ["topic1", "topic2", "topic3", "topic4"],
  "output_directory": "/path/to/reports",
  "state_file": "/path/to/.claude/tmp/workflow_$$.sh",
  "supervisor_id": "research_sub_supervisor_TIMESTAMP"
}
```

**Required Inputs**:
- `topics`: Array of research topics (one per worker)
- `output_directory`: Directory for research report outputs
- `state_file`: Path to workflow state file (for checkpoint coordination)
- `supervisor_id`: Unique identifier for this supervisor instance

## Expected Outputs

This supervisor returns aggregated metadata ONLY (not full worker outputs):

```json
{
  "supervisor_id": "research_sub_supervisor_20251107_143030",
  "worker_count": 4,
  "reports_created": ["/path1", "/path2", "/path3", "/path4"],
  "summary": "Combined 50-100 word summary integrating all research findings",
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
load_workflow_state

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

The orchestrator provides inputs in the prompt. Extract them and validate:

```bash
# Example of how orchestrator passes inputs:
# TOPICS: authentication,authorization,session,password
# OUTPUT_DIR: /path/to/specs/042_auth/reports
# SUPERVISOR_ID: research_sub_supervisor_1699356030

# Extract from prompt (these will be provided as variables)
# Verify all required inputs present

if [ -z "$TOPICS" ]; then
  echo "ERROR: No topics provided" >&2
  exit 1
fi

if [ -z "$OUTPUT_DIR" ]; then
  echo "ERROR: No output directory provided" >&2
  exit 1
fi

# Convert comma-separated topics to array
IFS=',' read -ra TOPIC_ARRAY <<< "$TOPICS"
WORKER_COUNT=${#TOPIC_ARRAY[@]}

echo "✓ Supervisor inputs parsed: $WORKER_COUNT topics"
```

---

### STEP 3: Invoke Workers in Parallel

**EXECUTE NOW**: USE the Task tool to invoke research-specialist workers simultaneously.

**CRITICAL**: Send a SINGLE message with multiple Task tool invocations for parallel execution.

For each topic in the TOPIC_ARRAY, invoke a research-specialist worker:

**Example for 4 topics** (adapt based on actual topic count):

**Worker 1 - Authentication Research**:
```
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist.

Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    INPUTS:
    - Research topic: {TOPIC_1}
    - Report path: ${OUTPUT_DIR}/001_{TOPIC_1_SLUG}.md

    REQUIRED OUTPUT:
    Return completion signal with report path:
    REPORT_CREATED: /path/to/report
}
```

**Worker 2 - Authorization Research**:
```
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist.

Task {
  subagent_type: "general-purpose"
  description: "Research authorization patterns"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    INPUTS:
    - Research topic: {TOPIC_2}
    - Report path: ${OUTPUT_DIR}/002_{TOPIC_2_SLUG}.md

    REQUIRED OUTPUT:
    Return completion signal with report path:
    REPORT_CREATED: /path/to/report
}
```

**Worker 3 - Session Research**:
```
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist.

Task {
  subagent_type: "general-purpose"
  description: "Research session management"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    INPUTS:
    - Research topic: {TOPIC_3}
    - Report path: ${OUTPUT_DIR}/003_{TOPIC_3_SLUG}.md

    REQUIRED OUTPUT:
    Return completion signal with report path:
    REPORT_CREATED: /path/to/report
}
```

**Worker 4 - Password Research**:
```
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist.

Task {
  subagent_type: "general-purpose"
  description: "Research password security"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    INPUTS:
    - Research topic: {TOPIC_4}
    - Report path: ${OUTPUT_DIR}/004_{TOPIC_4_SLUG}.md

    REQUIRED OUTPUT:
    Return completion signal with report path:
    REPORT_CREATED: /path/to/report
}
```

**WAIT**: Workers execute in parallel. Do not proceed until all workers complete.

---

### STEP 4: Extract Worker Metadata

**EXECUTE NOW**: Extract metadata from each worker output.

```bash
# Source metadata extraction library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/metadata-extraction.sh"

# Parse worker completion signals (extract paths from worker responses)
# Example: "REPORT_CREATED: /path/to/report1.md"
WORKER_1_OUTPUT=$(echo "$WORKER_1_RESPONSE" | grep -oP 'REPORT_CREATED:\s*\K.*')
WORKER_2_OUTPUT=$(echo "$WORKER_2_RESPONSE" | grep -oP 'REPORT_CREATED:\s*\K.*')
WORKER_3_OUTPUT=$(echo "$WORKER_3_RESPONSE" | grep -oP 'REPORT_CREATED:\s*\K.*')
WORKER_4_OUTPUT=$(echo "$WORKER_4_RESPONSE" | grep -oP 'REPORT_CREATED:\s*\K.*')

# Extract metadata from worker report files
WORKER_1_METADATA=$(extract_report_metadata "$WORKER_1_OUTPUT")
WORKER_2_METADATA=$(extract_report_metadata "$WORKER_2_OUTPUT")
WORKER_3_METADATA=$(extract_report_metadata "$WORKER_3_OUTPUT")
WORKER_4_METADATA=$(extract_report_metadata "$WORKER_4_OUTPUT")

# Metadata structure from extract_report_metadata():
# {
#   "title": "Report Title",
#   "summary": "50-word summary",
#   "key_findings": ["finding1", "finding2"],
#   "recommendations": ["rec1", "rec2"]
# }

echo "✓ Metadata extracted from all workers"
```

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
  --arg output1 "$WORKER_1_OUTPUT" \
  --arg output2 "$WORKER_2_OUTPUT" \
  --arg output3 "$WORKER_3_OUTPUT" \
  --arg output4 "$WORKER_4_OUTPUT" \
  '[
    {
      worker_id: "research_specialist_1",
      topic: "'"${TOPIC_ARRAY[0]}"'",
      status: "completed",
      output_path: $output1,
      duration_ms: 12000,
      metadata: $worker1
    },
    {
      worker_id: "research_specialist_2",
      topic: "'"${TOPIC_ARRAY[1]}"'",
      status: "completed",
      output_path: $output2,
      duration_ms: 10500,
      metadata: $worker2
    },
    {
      worker_id: "research_specialist_3",
      topic: "'"${TOPIC_ARRAY[2]}"'",
      status: "completed",
      output_path: $output3,
      duration_ms: 11200,
      metadata: $worker3
    },
    {
      worker_id: "research_specialist_4",
      topic: "'"${TOPIC_ARRAY[3]}"'",
      status: "completed",
      output_path: $output4,
      duration_ms: 9800,
      metadata: $worker4
    }
  ]')

# Aggregate metadata using custom function
aggregate_research_metadata() {
  local workers_array="$1"

  # Combine summaries (100 words max)
  local combined_summary=$(echo "$workers_array" | jq -r '
    [.[].metadata.summary] | join(". ") |
    split(" ") | .[0:100] | join(" ")
  ')

  # Merge key findings (top 2 per worker, max 8 total)
  local merged_findings=$(echo "$workers_array" | jq -r '
    [.[].metadata.key_findings[]? | select(. != null)] |
    .[0:8]
  ')

  # Calculate totals
  local total_duration=$(echo "$workers_array" | jq '[.[].duration_ms] | add')
  local context_tokens=$(echo "$combined_summary" | wc -c | awk '{print int($1/4)}')

  # Build aggregated metadata
  jq -n \
    --argjson workers "$workers_array" \
    --arg summary "$combined_summary" \
    --argjson findings "$merged_findings" \
    --argjson duration "$total_duration" \
    --argjson tokens "$context_tokens" \
    '{
      reports_count: ($workers | length),
      reports_created: [$workers[].output_path],
      summary: $summary,
      key_findings: $findings,
      total_duration_ms: $duration,
      context_tokens: $tokens
    }'
}

AGGREGATED_METADATA=$(aggregate_research_metadata "$WORKERS_ARRAY")

echo "✓ Worker metadata aggregated (95% context reduction)"
```

---

### STEP 6: Save Supervisor Checkpoint

**EXECUTE NOW**: Save supervisor state to checkpoint for resume capability.

```bash
# Build supervisor checkpoint
SUPERVISOR_CHECKPOINT=$(jq -n \
  --arg supervisor_id "$SUPERVISOR_ID" \
  --arg supervisor_name "research-sub-supervisor" \
  --argjson worker_count "$WORKER_COUNT" \
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
save_json_checkpoint "research_supervisor" "$SUPERVISOR_CHECKPOINT"

echo "✓ Supervisor checkpoint saved: research_supervisor.json"
```

**Checkpoint Location**: `.claude/tmp/research_supervisor.json`

---

### STEP 7: Handle Partial Failures

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
    AGGREGATED_METADATA=$(aggregate_research_metadata "$SUCCESSFUL_WORKERS")

    # Add failure context
    FAILURE_SUMMARY=$(echo "$FAILED_WORKERS" | jq -r '
      [.[] | "Failed: \(.topic) (\(.error))"] | join("; ")
    ')

    AGGREGATED_METADATA=$(echo "$AGGREGATED_METADATA" | jq \
      --arg failures "$FAILURE_SUMMARY" \
      '.partial_failures = $failures')

  else
    # Complete failure: too few workers succeeded
    echo "ERROR: Only $SUCCESS_COUNT workers succeeded (need ≥2)" >&2

    FAILURE_DETAILS=$(echo "$FAILED_WORKERS" | jq '[.[] | {topic: .topic, error: .error}]')
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
  "supervisor_id": "research_sub_supervisor_20251107_143030",
  "aggregated_metadata": {
    "reports_count": 4,
    "reports_created": ["/path1.md", "/path2.md", "/path3.md", "/path4.md"],
    "summary": "Combined summary integrating all research findings across authentication, authorization, session, and password security patterns",
    "key_findings": ["finding1", "finding2", "finding3", "finding4", "finding5", "finding6", "finding7", "finding8"],
    "total_duration_ms": 43500,
    "context_tokens": 500
  }
}
```

---

## Performance Characteristics

### Context Reduction

- **Full worker outputs**: ~10,000 tokens (4 workers × 2,500 tokens each)
- **Aggregated metadata**: ~500 tokens (supervisor summary)
- **Reduction**: 95% ((10,000 - 500) / 10,000)

### Time Savings (Parallel Execution)

- **Sequential execution**: Sum of worker durations (~45 seconds for 4 workers)
- **Parallel execution**: Max worker duration (~12 seconds)
- **Time savings**: 73% ((45 - 12) / 45)

### Threshold for Hierarchical Supervision

Use research-sub-supervisor when:
- **Topic count**: ≥ 4 topics (context reduction justifies overhead)
- **Report size**: > 2,000 tokens each (significant context savings)
- **Parallel execution benefit**: Topics are independent (no sequential dependencies)

---

## References

- [Hierarchical Supervisor Coordination Architecture](../docs/architecture/hierarchical-supervisor-coordination.md)
- [State Persistence Library](../docs/reference/library-api/persistence.md)
- [Metadata Extraction Library](../docs/reference/library-api/utilities.md)
- [Research Specialist Worker](research-specialist.md)
- [Sub-Supervisor Template](../templates/sub-supervisor-template.md)
