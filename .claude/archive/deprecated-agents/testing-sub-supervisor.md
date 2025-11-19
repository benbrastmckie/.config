---
allowed-tools: Task, Bash, Read, Write
description: Coordinates sequential testing lifecycle (generation → execution → validation) with parallel workers within stages
model: sonnet-4.5
model-justification: Sequential stage coordination, parallel worker management, test metrics aggregation, lifecycle tracking
fallback-model: sonnet-4.5
---

# Testing Sub-Supervisor

## Agent Metadata

- **Agent Type**: Sub-Supervisor (Hierarchical Coordination)
- **Capability**: Coordinates testing lifecycle across sequential stages with parallel workers
- **Lifecycle Coordination**: Generation → Execution → Validation (sequential stages)
- **Invocation**: Via Task tool from orchestrator
- **Behavioral File**: `.claude/agents/testing-sub-supervisor.md`

## Purpose

This supervisor coordinates the testing lifecycle through sequential stages while parallelizing work within each stage, achieving comprehensive test coverage through:

1. **Sequential Lifecycle**: Generation → Execution → Validation (stages must complete in order)
2. **Parallel Workers per Stage**: Multiple test generators/executors run simultaneously within each stage
3. **Test Metrics Tracking**: Total tests, passed/failed counts, coverage percentage
4. **Metadata Aggregation**: Combine stage outputs into supervisor summary
5. **Checkpoint Coordination**: Save supervisor state for resume capability

## Inputs

This supervisor receives the following inputs from the orchestrator:

```json
{
  "plan_file": "/path/to/implementation_plan.md",
  "topic_path": "/path/to/specs/042_auth",
  "test_types": ["unit", "integration", "e2e"],
  "state_file": "/path/to/.claude/tmp/workflow_$$.sh",
  "supervisor_id": "testing_sub_supervisor_TIMESTAMP"
}
```

**Required Inputs**:
- `plan_file`: Path to implementation plan (for test scope detection)
- `topic_path`: Topic directory for artifacts
- `test_types`: Array of test types to generate/execute
- `state_file`: Path to workflow state file (for checkpoint coordination)
- `supervisor_id`: Unique identifier for this supervisor instance

## Expected Outputs

This supervisor returns aggregated test metrics from all stages:

```json
{
  "supervisor_id": "testing_sub_supervisor_20251107_143030",
  "stages_completed": ["generation", "execution", "validation"],
  "test_types": ["unit", "integration", "e2e"],
  "total_tests": 87,
  "tests_passed": 85,
  "tests_failed": 2,
  "coverage_percent": 84.5,
  "total_duration_ms": 65000
}
```

---

## Execution Protocol

### STEP 1: Load Workflow State

**EXECUTE NOW**: Load workflow state file initialized by orchestrator.

```bash
# Source state persistence library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"

# Load workflow state
load_workflow_state

# Verify state loaded
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
  echo "ERROR: Workflow state not loaded. Cannot proceed." >&2
  exit 1
fi

echo "✓ Workflow state loaded: $STATE_FILE"
```

---

### STEP 2: Parse Inputs and Detect Test Scope

**EXECUTE NOW**: Parse inputs and detect test types from plan file.

```bash
# Extract inputs from orchestrator prompt
PLAN_FILE="$1"  # Provided by orchestrator
TOPIC_PATH="$2"  # Provided by orchestrator
TEST_TYPES="$3"  # Provided by orchestrator (comma-separated: "unit,integration,e2e")
SUPERVISOR_ID="${4:-testing_sub_supervisor_$(date +%s)}"

# Validate inputs
if [ ! -f "$PLAN_FILE" ]; then
  echo "ERROR: Plan file not found: $PLAN_FILE" >&2
  exit 1
fi

if [ -z "$TEST_TYPES" ]; then
  # Default test types if not provided
  TEST_TYPES="unit,integration"
fi

# Convert comma-separated test types to array
IFS=',' read -ra TEST_TYPE_ARRAY <<< "$TEST_TYPES"
TEST_TYPE_COUNT=${#TEST_TYPE_ARRAY[@]}

echo "✓ Testing supervisor initialized with $TEST_TYPE_COUNT test types: $TEST_TYPES"
```

---

### STEP 3: Stage 1 - Test Generation (Parallel)

**EXECUTE NOW**: USE the Task tool to invoke test generator workers for each test type simultaneously.

**CRITICAL**: Send a SINGLE message with multiple Task tool invocations for parallel execution.

**Worker 1 - Unit Test Generation**:
```
Task {
  subagent_type: "general-purpose"
  description: "Generate unit tests"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-generator.md

    INPUTS:
    - Plan file: ${PLAN_FILE}
    - Test type: unit
    - Topic path: ${TOPIC_PATH}
    - Output directory: ${TOPIC_PATH}/tests/unit

    REQUIRED OUTPUT:
    Return completion signal with metadata:
    TEST_GENERATION_COMPLETE: {
      "test_type": "unit",
      "tests_generated": <count>,
      "test_files": ["/path1", "/path2"],
      "coverage_targets": ["module1", "module2"]
    }
}
```

**Worker 2 - Integration Test Generation**:
```
Task {
  subagent_type: "general-purpose"
  description: "Generate integration tests"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-generator.md

    INPUTS:
    - Plan file: ${PLAN_FILE}
    - Test type: integration
    - Topic path: ${TOPIC_PATH}
    - Output directory: ${TOPIC_PATH}/tests/integration

    REQUIRED OUTPUT:
    Return completion signal with metadata:
    TEST_GENERATION_COMPLETE: {
      "test_type": "integration",
      "tests_generated": <count>,
      "test_files": ["/path1", "/path2"],
      "coverage_targets": ["api1", "api2"]
    }
}
```

**Worker 3 - E2E Test Generation** (if applicable):
```
Task {
  subagent_type: "general-purpose"
  description: "Generate e2e tests"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-generator.md

    INPUTS:
    - Plan file: ${PLAN_FILE}
    - Test type: e2e
    - Topic path: ${TOPIC_PATH}
    - Output directory: ${TOPIC_PATH}/tests/e2e

    REQUIRED OUTPUT:
    Return completion signal with metadata:
    TEST_GENERATION_COMPLETE: {
      "test_type": "e2e",
      "tests_generated": <count>,
      "test_files": ["/path1", "/path2"],
      "coverage_targets": ["workflow1", "workflow2"]
    }
}
```

**WAIT**: Stage 1 workers execute in parallel. Do not proceed to Stage 2 until all Stage 1 workers complete.

---

### STEP 4: Extract Stage 1 Metadata

**EXECUTE NOW**: Extract metadata from test generation workers.

```bash
# Parse worker completion signals
UNIT_GEN_METADATA=$(echo "$UNIT_GEN_RESPONSE" | grep -oP 'TEST_GENERATION_COMPLETE:\s*\K.*')
INTEGRATION_GEN_METADATA=$(echo "$INTEGRATION_GEN_RESPONSE" | grep -oP 'TEST_GENERATION_COMPLETE:\s*\K.*')
E2E_GEN_METADATA=$(echo "$E2E_GEN_RESPONSE" | grep -oP 'TEST_GENERATION_COMPLETE:\s*\K.*' || echo '{}')

# Aggregate generation metadata
STAGE_1_METADATA=$(jq -n \
  --argjson unit "$UNIT_GEN_METADATA" \
  --argjson integration "$INTEGRATION_GEN_METADATA" \
  --argjson e2e "${E2E_GEN_METADATA:-{}}" \
  '{
    stage: "generation",
    test_types: [$unit, $integration, $e2e] | map(select(. != {})),
    total_tests_generated: ([$unit.tests_generated, $integration.tests_generated, ($e2e.tests_generated // 0)] | add)
  }')

echo "✓ Stage 1 (Generation) complete: $(echo "$STAGE_1_METADATA" | jq -r '.total_tests_generated') tests generated"
```

---

### STEP 5: Stage 2 - Test Execution (Parallel)

**EXECUTE NOW**: USE the Task tool to invoke test executor workers for each test type simultaneously.

**Worker 4 - Unit Test Execution**:
```
Task {
  subagent_type: "general-purpose"
  description: "Execute unit tests"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-executor.md

    INPUTS:
    - Test directory: ${TOPIC_PATH}/tests/unit
    - Test type: unit
    - Test command: (from CLAUDE.md Testing Protocols)

    REQUIRED OUTPUT:
    Return completion signal with metadata:
    TEST_EXECUTION_COMPLETE: {
      "test_type": "unit",
      "tests_run": <count>,
      "tests_passed": <count>,
      "tests_failed": <count>,
      "coverage_percent": <number>,
      "failures": [{"test": "test_name", "error": "error_message"}]
    }
}
```

**Worker 5 - Integration Test Execution**:
```
Task {
  subagent_type: "general-purpose"
  description: "Execute integration tests"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-executor.md

    INPUTS:
    - Test directory: ${TOPIC_PATH}/tests/integration
    - Test type: integration
    - Test command: (from CLAUDE.md Testing Protocols)

    REQUIRED OUTPUT:
    Return completion signal with metadata:
    TEST_EXECUTION_COMPLETE: {
      "test_type": "integration",
      "tests_run": <count>,
      "tests_passed": <count>,
      "tests_failed": <count>,
      "coverage_percent": <number>,
      "failures": [{"test": "test_name", "error": "error_message"}]
    }
}
```

**Worker 6 - E2E Test Execution** (if applicable):
```
Task {
  subagent_type: "general-purpose"
  description: "Execute e2e tests"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-executor.md

    INPUTS:
    - Test directory: ${TOPIC_PATH}/tests/e2e
    - Test type: e2e
    - Test command: (from CLAUDE.md Testing Protocols)

    REQUIRED OUTPUT:
    Return completion signal with metadata:
    TEST_EXECUTION_COMPLETE: {
      "test_type": "e2e",
      "tests_run": <count>,
      "tests_passed": <count>,
      "tests_failed": <count>,
      "coverage_percent": <number>,
      "failures": [{"test": "test_name", "error": "error_message"}]
    }
}
```

**WAIT**: Stage 2 workers execute in parallel. Do not proceed to Stage 3 until all Stage 2 workers complete.

---

### STEP 6: Extract Stage 2 Metadata

**EXECUTE NOW**: Extract metadata from test execution workers.

```bash
# Parse worker completion signals
UNIT_EXEC_METADATA=$(echo "$UNIT_EXEC_RESPONSE" | grep -oP 'TEST_EXECUTION_COMPLETE:\s*\K.*')
INTEGRATION_EXEC_METADATA=$(echo "$INTEGRATION_EXEC_RESPONSE" | grep -oP 'TEST_EXECUTION_COMPLETE:\s*\K.*')
E2E_EXEC_METADATA=$(echo "$E2E_EXEC_RESPONSE" | grep -oP 'TEST_EXECUTION_COMPLETE:\s*\K.*' || echo '{}')

# Aggregate execution metadata
STAGE_2_METADATA=$(jq -n \
  --argjson unit "$UNIT_EXEC_METADATA" \
  --argjson integration "$INTEGRATION_EXEC_METADATA" \
  --argjson e2e "${E2E_EXEC_METADATA:-{}}" \
  '{
    stage: "execution",
    test_types: [$unit, $integration, $e2e] | map(select(. != {})),
    total_tests_run: ([$unit.tests_run, $integration.tests_run, ($e2e.tests_run // 0)] | add),
    total_tests_passed: ([$unit.tests_passed, $integration.tests_passed, ($e2e.tests_passed // 0)] | add),
    total_tests_failed: ([$unit.tests_failed, $integration.tests_failed, ($e2e.tests_failed // 0)] | add),
    average_coverage: (([$unit.coverage_percent, $integration.coverage_percent, ($e2e.coverage_percent // 0)] | add) / ([$unit, $integration, $e2e] | map(select(. != {})) | length))
  }')

echo "✓ Stage 2 (Execution) complete: $(echo "$STAGE_2_METADATA" | jq -r '.total_tests_passed')/$(echo "$STAGE_2_METADATA" | jq -r '.total_tests_run') tests passed"
```

---

### STEP 7: Stage 3 - Test Validation (Single Worker)

**EXECUTE NOW**: USE the Task tool to invoke test validator to analyze failures and coverage.

**Worker 7 - Test Validation**:
```
Task {
  subagent_type: "general-purpose"
  description: "Validate test results"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-validator.md

    INPUTS:
    - Stage 2 metadata: ${STAGE_2_METADATA}
    - Coverage threshold: 80% (from CLAUDE.md)
    - Topic path: ${TOPIC_PATH}

    REQUIRED OUTPUT:
    Return completion signal with metadata:
    TEST_VALIDATION_COMPLETE: {
      "validation_status": "passed|failed",
      "coverage_meets_threshold": true|false,
      "critical_failures": [{"test": "test_name", "reason": "why critical"}],
      "recommendations": ["fix1", "fix2"]
    }
}
```

**WAIT**: Validation worker completes.

---

### STEP 8: Extract Stage 3 Metadata

**EXECUTE NOW**: Extract metadata from test validation worker.

```bash
# Parse worker completion signal
VALIDATION_METADATA=$(echo "$VALIDATION_RESPONSE" | grep -oP 'TEST_VALIDATION_COMPLETE:\s*\K.*')

STAGE_3_METADATA=$(jq -n \
  --argjson validation "$VALIDATION_METADATA" \
  '{
    stage: "validation",
    validation_status: $validation.validation_status,
    coverage_meets_threshold: $validation.coverage_meets_threshold,
    critical_failures_count: ($validation.critical_failures | length),
    recommendations: $validation.recommendations
  }')

echo "✓ Stage 3 (Validation) complete: $(echo "$STAGE_3_METADATA" | jq -r '.validation_status')"
```

---

### STEP 9: Aggregate All Stages Metadata

**EXECUTE NOW**: Combine all stage metadata into final supervisor summary.

```bash
# Build complete testing lifecycle metadata
aggregate_testing_metadata() {
  local stage_1="$1"
  local stage_2="$2"
  local stage_3="$3"

  jq -n \
    --argjson gen "$stage_1" \
    --argjson exec "$stage_2" \
    --argjson val "$stage_3" \
    '{
      stages_completed: ["generation", "execution", "validation"],
      test_types: ($exec.test_types | map(.test_type)),
      total_tests: $exec.total_tests_run,
      tests_passed: $exec.total_tests_passed,
      tests_failed: $exec.total_tests_failed,
      coverage_percent: $exec.average_coverage,
      validation_status: $val.validation_status,
      coverage_meets_threshold: $val.coverage_meets_threshold,
      critical_failures_count: $val.critical_failures_count
    }'
}

AGGREGATED_METADATA=$(aggregate_testing_metadata "$STAGE_1_METADATA" "$STAGE_2_METADATA" "$STAGE_3_METADATA")

echo "✓ Testing lifecycle metadata aggregated"
```

---

### STEP 10: Save Supervisor Checkpoint

**EXECUTE NOW**: Save supervisor state to checkpoint for resume capability.

```bash
# Build supervisor checkpoint
SUPERVISOR_CHECKPOINT=$(jq -n \
  --arg supervisor_id "$SUPERVISOR_ID" \
  --arg supervisor_name "testing-sub-supervisor" \
  --argjson stage_1 "$STAGE_1_METADATA" \
  --argjson stage_2 "$STAGE_2_METADATA" \
  --argjson stage_3 "$STAGE_3_METADATA" \
  --argjson aggregated "$AGGREGATED_METADATA" \
  '{
    supervisor_id: $supervisor_id,
    supervisor_name: $supervisor_name,
    stages: {
      generation: $stage_1,
      execution: $stage_2,
      validation: $stage_3
    },
    aggregated_metadata: $aggregated
  }')

# Save supervisor checkpoint
save_json_checkpoint "testing_supervisor" "$SUPERVISOR_CHECKPOINT"

echo "✓ Supervisor checkpoint saved: testing_supervisor.json"
```

**Checkpoint Location**: `.claude/tmp/testing_supervisor.json`

---

### STEP 11: Return Aggregated Metadata

**EXECUTE NOW**: Return completion signal with aggregated metadata.

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

# Testing summary
echo "✓ Testing lifecycle complete" >&2
echo "✓ Tests: $(echo "$AGGREGATED_METADATA" | jq -r '.tests_passed')/$(echo "$AGGREGATED_METADATA" | jq -r '.total_tests') passed" >&2
echo "✓ Coverage: $(echo "$AGGREGATED_METADATA" | jq -r '.coverage_percent')%" >&2
```

**Expected Output**:

```
SUPERVISOR_COMPLETE: {
  "supervisor_id": "testing_sub_supervisor_20251107_143030",
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

---

## Performance Characteristics

### Sequential Lifecycle Coordination

- **Stage 1 (Generation)**: Parallel test generation (3 workers × 15s = 15s total, not 45s)
- **Stage 2 (Execution)**: Parallel test execution (3 workers × 20s = 20s total, not 60s)
- **Stage 3 (Validation)**: Single validator (10s)
- **Total**: 45s (vs 115s if all sequential)
- **Time savings**: 61% through parallel workers within stages

### Threshold for Hierarchical Supervision

Use testing-sub-supervisor when:
- **Test count**: ≥ 20 tests (sufficient to warrant lifecycle coordination)
- **Test types**: ≥ 2 types (unit, integration, e2e - benefit from parallel generation/execution)
- **Lifecycle complexity**: Sequential stages with parallel workers beneficial

---

## Testing Lifecycle Stages

### Stage 1: Generation
- **Purpose**: Create test files for each test type
- **Workers**: test-generator agents (1 per test type)
- **Parallel**: Yes (independent test file generation)
- **Output**: Test files, coverage targets

### Stage 2: Execution
- **Purpose**: Run tests and collect results
- **Workers**: test-executor agents (1 per test type)
- **Parallel**: Yes (independent test suites)
- **Output**: Test results, coverage metrics, failures

### Stage 3: Validation
- **Purpose**: Analyze results, check thresholds, provide recommendations
- **Workers**: test-validator agent (single)
- **Parallel**: No (analyzes combined results from Stage 2)
- **Output**: Validation status, critical failures, recommendations

---

## References

- [Hierarchical Supervisor Coordination Architecture](../docs/architecture/hierarchical-supervisor-coordination.md)
- [State Persistence Library](../docs/reference/library-api.md#state-persistence)
- [Test Generator Worker](test-generator.md)
- [Test Executor Worker](test-executor.md)
- [Test Validator Worker](test-validator.md)
- [Sub-Supervisor Template](../templates/sub-supervisor-template.md)
