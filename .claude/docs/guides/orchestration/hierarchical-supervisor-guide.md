# Hierarchical Supervisor Usage Guide

## Overview

This guide explains how to use hierarchical supervisors for multi-agent coordination with 95% context reduction and 40-60% time savings through parallel execution.

**Supervisors Available**:
- **research-sub-supervisor**: Coordinates 4+ research-specialist workers (95% context reduction)
- **implementation-sub-supervisor**: Coordinates track-level parallel implementation (40-60% time savings)
- **testing-sub-supervisor**: Coordinates sequential testing lifecycle (generation → execution → validation)

**Key Benefits**:
- Context reduction: 10,000 tokens → 500 tokens (95%)
- Time savings: Parallel execution (40-60% faster than sequential)
- Checkpoint coordination: Resume capability for multi-hour workflows
- Partial failure handling: Graceful degradation when some workers fail

---

## When to Use Hierarchical Supervision

### Decision Matrix

Use hierarchical supervision when:

| Supervisor | Threshold | Condition |
|------------|-----------|-----------|
| research-sub-supervisor | ≥4 topics | Context reduction justifies overhead |
| implementation-sub-supervisor | ≥3 tracks OR complexity ≥10 | Parallel execution beneficial |
| testing-sub-supervisor | ≥20 tests OR ≥2 test types | Lifecycle coordination beneficial |

### Use Flat Coordination When

- **Research**: <4 topics (overhead > benefit)
- **Implementation**: <3 tracks AND complexity <10 (simple single-domain changes)
- **Testing**: <20 tests AND single test type (minimal lifecycle complexity)

---

## Research Sub-Supervisor

### Purpose

Coordinates 4+ research-specialist workers in parallel, aggregating metadata for 95% context reduction.

### When to Use

- **Topic count**: ≥4 research topics
- **Report size**: >2,000 tokens per report (significant context savings)
- **Parallel benefit**: Topics are independent (no sequential dependencies)

### Invocation Pattern

```bash
# In orchestrator command (e.g., /coordinate)

# Detect if hierarchical supervision needed
RESEARCH_COMPLEXITY=4  # 4+ topics
USE_HIERARCHICAL=$([ $RESEARCH_COMPLEXITY -ge 4 ] && echo "true" || echo "false")

if [ "$USE_HIERARCHICAL" = "true" ]; then
  # Invoke research-sub-supervisor via Task tool
  Task {
    subagent_type: "general-purpose"
    description: "Coordinate research across 4+ topics with 95% context reduction"
    timeout: 600000
    prompt: "
      Read and follow ALL behavioral guidelines from:
      ${CLAUDE_PROJECT_DIR}/.claude/agents/research-sub-supervisor.md

      **Supervisor Inputs**:
      - Topics: authentication,authorization,session,password
      - Output directory: $TOPIC_PATH/reports
      - State file: $STATE_FILE
      - Supervisor ID: research_sub_supervisor_$(date +%s)

      Return: SUPERVISOR_COMPLETE: {supervisor_id, aggregated_metadata}
    "
  }

  # Load supervisor checkpoint
  SUPERVISOR_CHECKPOINT=$(load_json_checkpoint "research_supervisor")

  # Extract aggregated metadata (95% context reduction)
  SUPERVISOR_REPORTS=$(echo "$SUPERVISOR_CHECKPOINT" | jq -r '.aggregated_metadata.reports_created[]')
  SUPERVISOR_SUMMARY=$(echo "$SUPERVISOR_CHECKPOINT" | jq -r '.aggregated_metadata.summary')
fi
```

### Expected Outputs

```json
{
  "supervisor_id": "research_sub_supervisor_1699356030",
  "aggregated_metadata": {
    "reports_count": 4,
    "reports_created": [
      "/path/to/specs/042_auth/reports/001_authentication.md",
      "/path/to/specs/042_auth/reports/002_authorization.md",
      "/path/to/specs/042_auth/reports/003_session.md",
      "/path/to/specs/042_auth/reports/004_password.md"
    ],
    "summary": "Research covered authentication patterns (session-based, JWT), authorization models (RBAC, ABAC), session management, and password security best practices",
    "key_findings": [
      "JWT recommended for stateless APIs",
      "RBAC sufficient for most apps",
      "Session rotation prevents fixation",
      "Bcrypt minimum 12 rounds",
      "MFA mandatory for admin access",
      "OAuth2 for third-party auth",
      "CSRF tokens for state-changing requests",
      "Password complexity less important than length"
    ],
    "total_duration_ms": 45000,
    "context_tokens": 500
  }
}
```

**Context Reduction**: 4 reports × 2,500 tokens = 10,000 tokens → 500 tokens (95% reduction)

### Performance Characteristics

- **Sequential execution**: 4 workers × 12s = 48s
- **Parallel execution**: max(12s) = 12s
- **Time savings**: 75% ((48-12)/48)

---

## Implementation Sub-Supervisor

### Purpose

Coordinates track-level parallel implementation across frontend, backend, testing, and infrastructure domains.

### When to Use

- **Track count**: ≥3 tracks detected (significant parallel benefit)
- **Domain complexity**: ≥10 complexity score (warrants track-level coordination)
- **Parallel execution benefit**: Tracks are mostly independent (max 1 dependency wave)

### Track Detection Patterns

The supervisor automatically detects tracks from file path patterns in the implementation plan:

| Track | Patterns |
|-------|----------|
| Frontend | `components/`, `views/`, `ui/`, `frontend/`, `client/`, `pages/` |
| Backend | `api/`, `server/`, `backend/`, `services/`, `models/`, `controllers/` |
| Testing | `tests/`, `spec/`, `__tests__/` |
| Infrastructure | `docker`, `k8s`, `terraform`, `ansible`, `deploy/` |

### Cross-Track Dependencies

The supervisor enforces dependency rules:

- **Frontend depends on Backend**: Backend must complete before Frontend (API contracts needed)
- **Testing runs in parallel**: Testing can run alongside Frontend/Backend
- **Infrastructure runs in parallel**: Infrastructure independent of other tracks

### Execution Waves

Example with frontend + backend + testing:

```
Wave 1 (parallel):
  - Backend track
  - Testing track

Wave 2 (after Wave 1):
  - Frontend track (depends on backend API)
```

### Invocation Pattern

```bash
# In orchestrator command (e.g., /coordinate)

# Determine if hierarchical implementation needed
PLAN_FILE="$TOPIC_PATH/plans/001_implementation.md"
TRACK_COUNT=$(detect_tracks "$PLAN_FILE")  # Returns 3 (backend, frontend, testing)

if [ $TRACK_COUNT -ge 3 ]; then
  # Invoke implementation-sub-supervisor via Task tool
  Task {
    subagent_type: "general-purpose"
    description: "Coordinate track-level parallel implementation"
    timeout: 600000
    prompt: "
      Read and follow ALL behavioral guidelines from:
      ${CLAUDE_PROJECT_DIR}/.claude/agents/implementation-sub-supervisor.md

      **Supervisor Inputs**:
      - Plan file: $PLAN_FILE
      - Topic path: $TOPIC_PATH
      - State file: $STATE_FILE
      - Supervisor ID: implementation_sub_supervisor_$(date +%s)

      Return: SUPERVISOR_COMPLETE: {supervisor_id, aggregated_metadata}
    "
  }

  # Load supervisor checkpoint
  SUPERVISOR_CHECKPOINT=$(load_json_checkpoint "implementation_supervisor")

  # Extract aggregated metadata
  FILES_MODIFIED=$(echo "$SUPERVISOR_CHECKPOINT" | jq -r '.aggregated_metadata.files_modified')
  PARALLEL_SAVINGS=$(echo "$SUPERVISOR_CHECKPOINT" | jq -r '.aggregated_metadata.parallel_savings_percent')
fi
```

### Expected Outputs

```json
{
  "supervisor_id": "implementation_sub_supervisor_1699356030",
  "aggregated_metadata": {
    "track_count": 3,
    "tracks_executed": ["backend", "frontend", "testing"],
    "files_modified": 24,
    "lines_changed": 1850,
    "commits_created": 3,
    "total_duration_ms": 45000,
    "parallel_savings_percent": 55
  }
}
```

### Performance Characteristics

- **Sequential execution**: 3 tracks × 40s = 120s
- **Parallel execution**: Wave 1 (40s) + Wave 2 (30s) = 70s
- **Time savings**: 42% ((120-70)/120)

---

## Testing Sub-Supervisor

### Purpose

Coordinates sequential testing lifecycle (generation → execution → validation) with parallel workers within each stage.

### When to Use

- **Test count**: ≥20 tests (sufficient to warrant lifecycle coordination)
- **Test types**: ≥2 types (unit, integration, e2e - benefit from parallel generation/execution)
- **Lifecycle complexity**: Sequential stages with parallel workers beneficial

### Sequential Lifecycle Stages

1. **Stage 1 - Generation** (parallel):
   - Generate unit tests
   - Generate integration tests
   - Generate e2e tests

2. **Stage 2 - Execution** (parallel):
   - Execute unit tests
   - Execute integration tests
   - Execute e2e tests

3. **Stage 3 - Validation** (single):
   - Analyze results
   - Check coverage thresholds
   - Provide recommendations

### Invocation Pattern

```bash
# In orchestrator command (e.g., /coordinate)

# Determine if hierarchical testing needed
PLAN_FILE="$TOPIC_PATH/plans/001_implementation.md"
TEST_COUNT=$(estimate_test_count "$PLAN_FILE")  # Returns 87
TEST_TYPES="unit,integration,e2e"

if [ $TEST_COUNT -ge 20 ]; then
  # Invoke testing-sub-supervisor via Task tool
  Task {
    subagent_type: "general-purpose"
    description: "Coordinate sequential testing lifecycle"
    timeout: 600000
    prompt: "
      Read and follow ALL behavioral guidelines from:
      ${CLAUDE_PROJECT_DIR}/.claude/agents/testing-sub-supervisor.md

      **Supervisor Inputs**:
      - Plan file: $PLAN_FILE
      - Topic path: $TOPIC_PATH
      - Test types: $TEST_TYPES
      - State file: $STATE_FILE
      - Supervisor ID: testing_sub_supervisor_$(date +%s)

      Return: SUPERVISOR_COMPLETE: {supervisor_id, aggregated_metadata}
    "
  }

  # Load supervisor checkpoint
  SUPERVISOR_CHECKPOINT=$(load_json_checkpoint "testing_supervisor")

  # Extract aggregated metadata
  TOTAL_TESTS=$(echo "$SUPERVISOR_CHECKPOINT" | jq -r '.aggregated_metadata.total_tests')
  TESTS_PASSED=$(echo "$SUPERVISOR_CHECKPOINT" | jq -r '.aggregated_metadata.tests_passed')
  COVERAGE=$(echo "$SUPERVISOR_CHECKPOINT" | jq -r '.aggregated_metadata.coverage_percent')
fi
```

### Expected Outputs

```json
{
  "supervisor_id": "testing_sub_supervisor_1699356030",
  "aggregated_metadata": {
    "stages_completed": ["generation", "execution", "validation"],
    "test_types": ["unit", "integration", "e2e"],
    "total_tests": 87,
    "tests_passed": 85,
    "tests_failed": 2,
    "coverage_percent": 84.5,
    "validation_status": "passed",
    "coverage_meets_threshold": true,
    "critical_failures_count": 0
  }
}
```

### Performance Characteristics

- **Sequential execution**: (15s + 20s + 10s) × 3 test types = 135s
- **Parallel execution**: Stage 1 (15s) + Stage 2 (20s) + Stage 3 (10s) = 45s
- **Time savings**: 67% ((135-45)/135)

---

## Checkpoint Coordination

All supervisors save checkpoints for resume capability using the v2.0 schema.

### Supervisor Checkpoint Schema

```json
{
  "supervisor_id": "research_sub_supervisor_1699356030",
  "supervisor_name": "research-sub-supervisor",
  "worker_count": 4,
  "workers": [
    {
      "worker_id": "research_specialist_1",
      "topic": "authentication",
      "status": "completed",
      "output_path": "/path/to/report1.md",
      "duration_ms": 12000,
      "metadata": {
        "title": "Authentication Patterns",
        "summary": "50-word summary",
        "key_findings": ["finding1", "finding2"]
      }
    }
  ],
  "aggregated_metadata": {
    "reports_count": 4,
    "reports_created": ["/path1", "/path2", "/path3", "/path4"],
    "summary": "Combined summary",
    "key_findings": ["finding1", "finding2"],
    "total_duration_ms": 45000,
    "context_tokens": 500
  }
}
```

### Loading Supervisor Checkpoints

```bash
# Load supervisor checkpoint
CHECKPOINT=$(load_json_checkpoint "research_supervisor")

# Extract aggregated metadata
METADATA=$(echo "$CHECKPOINT" | jq '.aggregated_metadata')

# Extract worker details (for debugging)
WORKERS=$(echo "$CHECKPOINT" | jq '.workers')
```

---

## Partial Failure Handling

All supervisors handle partial worker failures gracefully.

### Partial Success Strategy

- **≥50% workers succeed**: Return aggregated metadata with failure context
- **<50% workers succeed**: Return error and abort

### Example: 2/3 Workers Succeed

```json
{
  "aggregated_metadata": {
    "reports_count": 2,
    "reports_created": ["/path1.md", "/path2.md"],
    "summary": "Partial research summary (2/3 topics completed)",
    "key_findings": ["finding1", "finding2", "finding3", "finding4"],
    "partial_failures": "Failed: session_management (timeout); password_security (agent error)"
  }
}
```

### Error Handling

```bash
# Check for partial failures in aggregated metadata
PARTIAL_FAILURES=$(echo "$CHECKPOINT" | jq -r '.aggregated_metadata.partial_failures // ""')

if [ -n "$PARTIAL_FAILURES" ]; then
  echo "WARNING: Some workers failed: $PARTIAL_FAILURES"
  # Decide whether to continue or abort based on failure severity
fi
```

---

## Performance Optimization

### Context Reduction

**Research supervisor example**:

```
Without supervisor:
  - 4 reports × 2,500 tokens each = 10,000 tokens
  - Full report text passed between phases

With supervisor:
  - Aggregated summary: 500 tokens
  - 95% reduction: (10,000 - 500) / 10,000 = 95%
```

### Time Savings

**Implementation supervisor example**:

```
Without supervisor (sequential):
  - Backend: 40s
  - Frontend: 30s
  - Testing: 25s
  - Total: 95s

With supervisor (parallel):
  - Wave 1 (Backend + Testing): max(40s, 25s) = 40s
  - Wave 2 (Frontend): 30s
  - Total: 70s
  - Savings: (95-70)/95 = 26% improvement

With supervisor (all parallel):
  - All 3 tracks: max(40s, 30s, 25s) = 40s
  - Total: 40s
  - Savings: (95-40)/95 = 58% improvement
```

---

## Creating Custom Supervisors

To create a new supervisor based on the sub-supervisor-template.md:

### Step 1: Copy Template

```bash
cp .claude/agents/templates/sub-supervisor-template.md \
   .claude/agents/my-supervisor.md
```

### Step 2: Replace Template Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `{{SUPERVISOR_TYPE}}` | Supervisor type | "deployment", "migration" |
| `{{WORKER_TYPE}}` | Worker agent type | "deployment-executor", "migration-worker" |
| `{{WORKER_COUNT}}` | Number of workers | 3, 4, 5 |
| `{{TASK_DESCRIPTION}}` | Task description | "deploy to production", "migrate databases" |
| `{{OUTPUT_TYPE}}` | Output type | "deployments", "migrations" |
| `{{METADATA_FIELDS}}` | Metadata fields | "deployment_status", "migration_errors" |

### Step 3: Customize Aggregation Algorithm

Replace the `aggregate_worker_metadata()` function with supervisor-specific logic:

```bash
aggregate_deployment_metadata() {
  local workers_array="$1"

  # Deployment-specific aggregation
  local total_deployments=$(echo "$workers_array" | jq '[.[].deployments] | add')
  local success_rate=$(echo "$workers_array" | jq '
    [.[].deployments_successful] | add as $successful |
    [.[].deployments_total] | add as $total |
    ($successful / $total) * 100
  ')

  jq -n \
    --argjson workers "$workers_array" \
    --argjson deployments "$total_deployments" \
    --argjson success "$success_rate" \
    '{
      deployment_count: $deployments,
      success_rate_percent: $success,
      environments: [$workers[].environment],
      total_duration_ms: ([$workers[].duration_ms] | add)
    }'
}
```

### Step 4: Create Tests

Create `test_my_supervisor.sh` to validate:

```bash
test_my_supervisor_exists() {
  run_test "My supervisor behavioral file exists"
  if [ -f "${CLAUDE_DIR}/agents/my-supervisor.md" ]; then
    pass_test
  else
    fail_test "my-supervisor.md not found"
  fi
}

test_my_supervisor_metadata_aggregation() {
  run_test "My supervisor aggregates metadata correctly"

  # Create mock worker metadata
  local workers='[
    {"deployments": 5, "status": "completed"},
    {"deployments": 3, "status": "completed"}
  ]'

  # Test aggregation logic
  local total=$(echo "$workers" | jq '[.[].deployments] | add')

  if [ "$total" -eq 8 ]; then
    pass_test
  else
    fail_test "Aggregation incorrect (expected 8, got $total)"
  fi
}
```

---

## Troubleshooting

### Supervisor Not Invoked

**Symptom**: Orchestrator uses flat coordination instead of hierarchical.

**Diagnosis**:

```bash
# Check threshold detection
echo "Research complexity: $RESEARCH_COMPLEXITY"
echo "Use hierarchical: $([ $RESEARCH_COMPLEXITY -ge 4 ] && echo 'true' || echo 'false')"
```

**Solution**: Adjust complexity detection or lower threshold.

### Checkpoint Not Found

**Symptom**: `load_json_checkpoint` returns `{}`.

**Diagnosis**:

```bash
# Check checkpoint file exists
ls -la .claude/tmp/research_supervisor.json
```

**Solution**: Ensure supervisor completed successfully and saved checkpoint.

### Worker Failures

**Symptom**: Supervisor reports partial failures.

**Diagnosis**:

```bash
# Check worker status
CHECKPOINT=$(load_json_checkpoint "research_supervisor")
echo "$CHECKPOINT" | jq '.workers[] | select(.status == "failed")'
```

**Solution**: Investigate failed worker errors, increase timeout, or accept partial success if ≥50% succeeded.

### Context Reduction Not Achieved

**Symptom**: Aggregated metadata larger than expected.

**Diagnosis**:

```bash
# Measure aggregated metadata size
METADATA=$(echo "$CHECKPOINT" | jq '.aggregated_metadata')
TOKEN_COUNT=$(echo "$METADATA" | jq '@json' | wc -c | awk '{print int($1/4)}')
echo "Aggregated metadata tokens: $TOKEN_COUNT"
```

**Solution**: Review aggregation algorithm, ensure summary is 50-100 words max, limit findings to top 8-12.

---

## References

- [Sub-Supervisor Template](../../templates/sub-supervisor-template.md)
- [Research Sub-Supervisor](../../agents/research-sub-supervisor.md)
- [Implementation Sub-Supervisor](../../agents/implementation-sub-supervisor.md)
- [Testing Sub-Supervisor](../../agents/testing-sub-supervisor.md)
- [Hierarchical Supervisor Coordination Architecture](../architecture/hierarchical-supervisor-coordination.md)
- [State Persistence Library](../reference/library-api/overview.md#state-persistence)
- [Metadata Extraction Library](../reference/library-api/overview.md#metadata-extraction)
- [Checkpoint Schema v2.0](../reference/library-api/overview.md#checkpoint-schema-v20)

---

## Appendix: Complete Example Workflow

### Full Hierarchical Research Workflow

```bash
# Step 1: Initialize workflow state
STATE_FILE=$(init_workflow_state "coordinate_$$")

# Step 2: Detect research complexity
RESEARCH_COMPLEXITY=4  # 4 topics: auth, oauth, session, password

# Step 3: Invoke hierarchical supervision
if [ $RESEARCH_COMPLEXITY -ge 4 ]; then
  # Invoke research-sub-supervisor
  echo "Using hierarchical research supervision"

  # Supervisor coordinates 4 workers in parallel
  # Each worker creates a report
  # Supervisor aggregates metadata

  # Step 4: Load supervisor checkpoint
  CHECKPOINT=$(load_json_checkpoint "research_supervisor")

  # Step 5: Extract aggregated metadata (95% context reduction)
  REPORTS=$(echo "$CHECKPOINT" | jq -r '.aggregated_metadata.reports_created[]')
  SUMMARY=$(echo "$CHECKPOINT" | jq -r '.aggregated_metadata.summary')
  FINDINGS=$(echo "$CHECKPOINT" | jq -r '.aggregated_metadata.key_findings[]')

  echo "Research complete:"
  echo "  Reports: ${#REPORTS[@]}"
  echo "  Summary: $SUMMARY"
  echo "  Key findings: ${#FINDINGS[@]}"

  # Step 6: Verify reports exist
  for REPORT in $REPORTS; do
    if [ ! -f "$REPORT" ]; then
      echo "ERROR: Report not found: $REPORT"
      exit 1
    fi
  done

  echo "✓ All reports verified"
  echo "✓ Context reduction: 10,000 → 500 tokens (95%)"
fi
```

This workflow demonstrates end-to-end hierarchical supervision with context reduction and checkpoint coordination.
