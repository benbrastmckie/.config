# Hierarchical Supervisor Coordination Architecture

## Overview

This document defines the architecture for hierarchical supervisor coordination in the .claude/ orchestration system. Supervisors enable scaling orchestrators to 8-16+ agents through two-level hierarchical coordination, achieving 95% context reduction through metadata aggregation.

## Metadata

- **Version**: 1.0
- **Status**: Active
- **Created**: 2025-11-07
- **Last Updated**: 2025-11-07
- **Related**:
  - [Checkpoint Schema v2.0](#checkpoint-schema)
  - [State Persistence Library](../reference/library-api/overview.md#state-persistence)
  - [Workflow State Machine](workflow-state-machine.md)

## Architecture Components

### 1. Orchestrator Layer

The orchestrator is the top-level coordinator that:
- Detects when hierarchical supervision is needed (complexity thresholds)
- Invokes supervisor agents via Task tool
- Receives aggregated metadata from supervisors
- Saves supervisor state to checkpoint
- Achieves 95% context reduction by receiving metadata only

**Invocation Pattern**:

```bash
# In orchestrator bash block
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
load_workflow_state "coordinate_$$"

# Invoke supervisor for 4+ topics (hierarchical threshold)
if [ $TOPIC_COUNT -ge 4 ]; then
  # Use hierarchical supervision
  USE the Task tool to invoke research supervisor:

  Task {
    subagent_type: "general-purpose"
    description: "Coordinate research across 4 topics"
    prompt: |
      Read and follow behavioral guidelines from:
      ${CLAUDE_PROJECT_DIR}/.claude/agents/research-sub-supervisor.md

      Research topics: authentication,authorization,session,password
      Output directory: ${RESEARCH_DIR}

      Return format:
      SUPERVISOR_COMPLETE: <aggregated_metadata_json>
  }

  # Extract aggregated metadata from supervisor response
  SUPERVISOR_METADATA=$(extract_supervisor_metadata "$SUPERVISOR_RESPONSE")

  # Save to checkpoint for 95% context reduction
  save_json_checkpoint "supervisor_metadata" "$SUPERVISOR_METADATA"

  # Append to workflow state
  append_workflow_state "SUPERVISOR_METADATA_PATH" "${CLAUDE_PROJECT_DIR}/.claude/tmp/supervisor_metadata.json"
fi
```

### 2. Supervisor Layer

The supervisor is a specialized agent that:
- Receives task decomposition from orchestrator (e.g., 4 research topics)
- Invokes N worker agents in parallel via Task tool
- Extracts metadata from each worker output
- Aggregates metadata into supervisor summary (95% reduction)
- Returns aggregated metadata ONLY (not full worker outputs)
- Saves supervisor state to checkpoint using state-persistence.sh

**Key Responsibilities**:
- **Worker Invocation**: Parallel Task invocations (2-4 workers typical)
- **Metadata Extraction**: Parse worker outputs for key information
- **Metadata Aggregation**: Combine worker metadata into supervisor summary
- **Checkpoint Coordination**: Save supervisor_state for resume capability
- **Error Handling**: Handle partial failures (e.g., 2/3 workers succeed)

### 3. Worker Layer

Workers are specialized agents that:
- Receive specific tasks from supervisor (e.g., "Research authentication patterns")
- Execute task autonomously
- Create output artifacts (e.g., research reports, implementation files)
- Return completion signal with artifact path (e.g., `REPORT_CREATED: /path/to/report.md`)
- Include metadata in output (title, summary, key findings)

**Worker Types**:
- **research-specialist**: Autonomous research agents (creates reports)
- **implementation-executor**: Autonomous implementation agents (modifies code)
- **test-generator**: Autonomous test creation agents (creates test files)
- **debug-analyst**: Autonomous debugging agents (creates diagnostic reports)

## Checkpoint Schema v2.0: Supervisor State

### Schema Definition

The `supervisor_state` field in checkpoint v2.0 stores state for all supervisors used in the workflow:

```json
{
  "schema_version": "2.0",
  "checkpoint_id": "coordinate_20251107_143022",
  "workflow_type": "coordinate",
  "project_name": "auth_system",
  "state_machine": {
    "current_state": "plan",
    "completed_states": ["initialize", "research"]
  },
  "supervisor_state": {
    "research_supervisor": {
      "supervisor_id": "research_sub_supervisor_20251107_143030",
      "supervisor_name": "research-sub-supervisor",
      "worker_count": 4,
      "workers": [
        {
          "worker_id": "research_specialist_1",
          "topic": "authentication patterns",
          "status": "completed",
          "output_path": "/home/user/.config/.claude/specs/042_auth/reports/001_authentication_patterns.md",
          "duration_ms": 12000,
          "metadata": {
            "title": "Authentication Patterns Research",
            "summary": "Analysis of session-based auth, JWT tokens, OAuth2 flows with security trade-offs",
            "key_findings": [
              "Session-based auth suitable for traditional web apps",
              "JWT tokens enable stateless authentication"
            ]
          }
        },
        {
          "worker_id": "research_specialist_2",
          "topic": "authorization patterns",
          "status": "completed",
          "output_path": "/home/user/.config/.claude/specs/042_auth/reports/002_authorization_patterns.md",
          "duration_ms": 10500,
          "metadata": {
            "title": "Authorization Patterns Research",
            "summary": "RBAC, ABAC, policy-based access control comparison with implementation complexity",
            "key_findings": [
              "RBAC simplest for straightforward permission models",
              "ABAC provides fine-grained control at cost of complexity"
            ]
          }
        },
        {
          "worker_id": "research_specialist_3",
          "topic": "session management",
          "status": "completed",
          "output_path": "/home/user/.config/.claude/specs/042_auth/reports/003_session_management.md",
          "duration_ms": 11200,
          "metadata": {
            "title": "Session Management Research",
            "summary": "Server-side sessions, client-side storage, session fixation prevention",
            "key_findings": [
              "Server-side sessions most secure",
              "Session rotation prevents fixation attacks"
            ]
          }
        },
        {
          "worker_id": "research_specialist_4",
          "topic": "password security",
          "status": "completed",
          "output_path": "/home/user/.config/.claude/specs/042_auth/reports/004_password_security.md",
          "duration_ms": 9800,
          "metadata": {
            "title": "Password Security Research",
            "summary": "Hashing algorithms (bcrypt, Argon2), password policies, breach detection",
            "key_findings": [
              "Argon2 recommended for new implementations",
              "Password breach detection critical for security"
            ]
          }
        }
      ],
      "aggregated_metadata": {
        "topics_researched": 4,
        "reports_created": [
          "/home/user/.config/.claude/specs/042_auth/reports/001_authentication_patterns.md",
          "/home/user/.config/.claude/specs/042_auth/reports/002_authorization_patterns.md",
          "/home/user/.config/.claude/specs/042_auth/reports/003_session_management.md",
          "/home/user/.config/.claude/specs/042_auth/reports/004_password_security.md"
        ],
        "summary": "Comprehensive auth research covering authentication (session/JWT/OAuth2), authorization (RBAC/ABAC), session management (server-side/client-side), and password security (bcrypt/Argon2). Key recommendations: session-based for web apps, RBAC for simple permissions, server-side sessions for security, Argon2 for password hashing.",
        "key_findings": [
          "Session-based auth suitable for traditional web apps",
          "JWT tokens enable stateless authentication",
          "RBAC simplest for straightforward permission models",
          "ABAC provides fine-grained control at cost of complexity",
          "Server-side sessions most secure",
          "Session rotation prevents fixation attacks",
          "Argon2 recommended for new implementations",
          "Password breach detection critical for security"
        ],
        "total_duration_ms": 43500,
        "context_tokens": 950
      }
    },
    "implementation_supervisor": {
      "supervisor_id": "impl_sub_supervisor_20251107_150000",
      "supervisor_name": "implementation-sub-supervisor",
      "worker_count": 3,
      "tracks": [
        {
          "track_id": "frontend_track",
          "track_name": "Frontend Implementation",
          "worker_id": "implementation_executor_1",
          "status": "completed",
          "files_modified": [
            "src/components/LoginForm.tsx",
            "src/components/RegisterForm.tsx"
          ],
          "duration_ms": 25000,
          "metadata": {
            "components_created": 2,
            "tests_created": 2,
            "total_lines": 450
          }
        },
        {
          "track_id": "backend_track",
          "track_name": "Backend Implementation",
          "worker_id": "implementation_executor_2",
          "status": "completed",
          "files_modified": [
            "src/auth/auth.service.ts",
            "src/auth/auth.controller.ts"
          ],
          "duration_ms": 30000,
          "metadata": {
            "endpoints_created": 4,
            "tests_created": 8,
            "total_lines": 680
          }
        },
        {
          "track_id": "testing_track",
          "track_name": "Integration Testing",
          "worker_id": "implementation_executor_3",
          "status": "completed",
          "files_modified": [
            "tests/integration/auth.test.ts"
          ],
          "duration_ms": 15000,
          "metadata": {
            "test_suites": 1,
            "test_cases": 12,
            "total_lines": 320
          }
        }
      ],
      "aggregated_metadata": {
        "tracks_completed": 3,
        "files_modified": 5,
        "total_lines": 1450,
        "parallel_duration_ms": 30000,
        "sequential_duration_ms": 70000,
        "time_savings_percent": 57,
        "summary": "Parallel implementation across frontend (2 components), backend (4 endpoints), and testing (12 test cases). Achieved 57% time savings through parallel execution."
      }
    },
    "testing_supervisor": {
      "supervisor_id": "test_sub_supervisor_20251107_160000",
      "supervisor_name": "testing-sub-supervisor",
      "worker_count": 4,
      "stages": [
        {
          "stage_id": "generation",
          "stage_name": "Test Generation",
          "workers": [
            {
              "worker_id": "unit_test_generator",
              "status": "completed",
              "tests_created": 15,
              "duration_ms": 8000
            },
            {
              "worker_id": "integration_test_generator",
              "status": "completed",
              "tests_created": 8,
              "duration_ms": 12000
            }
          ],
          "status": "completed",
          "duration_ms": 12000
        },
        {
          "stage_id": "execution",
          "stage_name": "Test Execution",
          "workers": [
            {
              "worker_id": "test_executor",
              "status": "completed",
              "tests_passed": 23,
              "tests_failed": 0,
              "duration_ms": 5000
            }
          ],
          "status": "completed",
          "duration_ms": 5000
        }
      ],
      "aggregated_metadata": {
        "total_tests": 23,
        "tests_passed": 23,
        "tests_failed": 0,
        "coverage_percent": 85,
        "total_duration_ms": 17000,
        "summary": "Generated 23 tests (15 unit, 8 integration) with 85% coverage. All tests passing."
      }
    }
  },
  "phase_data": {},
  "error_state": {
    "last_error": null,
    "retry_count": 0,
    "failed_state": null
  }
}
```

### Schema Fields

#### Top-Level Supervisor State

Each supervisor in `supervisor_state` is keyed by supervisor type (e.g., `research_supervisor`, `implementation_supervisor`, `testing_supervisor`).

**Common Fields** (all supervisor types):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `supervisor_id` | string | Yes | Unique identifier for supervisor instance (e.g., `research_sub_supervisor_20251107_143030`) |
| `supervisor_name` | string | Yes | Supervisor behavioral file name (e.g., `research-sub-supervisor`) |
| `worker_count` | number | Yes | Total number of workers coordinated by supervisor |
| `aggregated_metadata` | object | Yes | Supervisor summary combining all worker outputs (95% context reduction) |

#### Research Supervisor Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `workers` | array | Yes | Array of worker objects with topic, status, output_path, metadata |
| `workers[].worker_id` | string | Yes | Unique identifier for worker (e.g., `research_specialist_1`) |
| `workers[].topic` | string | Yes | Research topic assigned to worker |
| `workers[].status` | string | Yes | Worker status: `completed`, `failed`, `in_progress` |
| `workers[].output_path` | string | Yes (if completed) | Path to report created by worker |
| `workers[].duration_ms` | number | Yes (if completed) | Worker execution duration in milliseconds |
| `workers[].metadata` | object | Yes (if completed) | Worker output metadata (title, summary, key_findings) |

**Aggregated Metadata Fields** (research):

| Field | Type | Description |
|-------|------|-------------|
| `topics_researched` | number | Total topics researched across all workers |
| `reports_created` | array | Paths to all reports created by workers |
| `summary` | string | Combined summary (50-100 words) integrating all worker findings |
| `key_findings` | array | Top 8-12 findings merged from all workers |
| `total_duration_ms` | number | Total execution time across all workers |
| `context_tokens` | number | Estimated token count for aggregated metadata (should be <1000) |

#### Implementation Supervisor Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `tracks` | array | Yes | Array of track objects (frontend, backend, testing, etc.) |
| `tracks[].track_id` | string | Yes | Unique identifier for track (e.g., `frontend_track`) |
| `tracks[].track_name` | string | Yes | Human-readable track name |
| `tracks[].worker_id` | string | Yes | Worker executing this track |
| `tracks[].status` | string | Yes | Track status: `completed`, `failed`, `in_progress` |
| `tracks[].files_modified` | array | Yes (if completed) | Files modified in this track |
| `tracks[].duration_ms` | number | Yes (if completed) | Track execution duration |
| `tracks[].metadata` | object | Yes (if completed) | Track-specific metadata |

**Aggregated Metadata Fields** (implementation):

| Field | Type | Description |
|-------|------|-------------|
| `tracks_completed` | number | Total tracks completed |
| `files_modified` | number | Total files modified across all tracks |
| `total_lines` | number | Total lines of code written |
| `parallel_duration_ms` | number | Actual duration with parallel execution |
| `sequential_duration_ms` | number | Estimated duration if executed sequentially |
| `time_savings_percent` | number | Time savings percentage (40-60% typical) |
| `summary` | string | Implementation summary covering all tracks |

#### Testing Supervisor Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `stages` | array | Yes | Sequential stages (generation → execution → validation) |
| `stages[].stage_id` | string | Yes | Unique identifier for stage (e.g., `generation`) |
| `stages[].stage_name` | string | Yes | Human-readable stage name |
| `stages[].workers` | array | Yes | Workers executing in this stage (may be parallel) |
| `stages[].status` | string | Yes | Stage status: `completed`, `failed`, `in_progress` |
| `stages[].duration_ms` | number | Yes (if completed) | Stage execution duration |

**Aggregated Metadata Fields** (testing):

| Field | Type | Description |
|-------|------|-------------|
| `total_tests` | number | Total tests across all stages |
| `tests_passed` | number | Number of tests passing |
| `tests_failed` | number | Number of tests failing |
| `coverage_percent` | number | Code coverage percentage |
| `total_duration_ms` | number | Total duration across all stages |
| `summary` | string | Testing summary with pass/fail counts and coverage |

## Supervisor-to-Worker Communication Protocol

### 1. Supervisor Invocation by Orchestrator

The orchestrator invokes the supervisor using the Task tool with behavioral injection pattern:

```markdown
**STEP 2: Invoke Research Supervisor**

**EXECUTE NOW**: USE the Task tool to invoke the research supervisor:

Task {
  subagent_type: "general-purpose"
  description: "Coordinate research across 4 topics"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-sub-supervisor.md

    INPUTS:
    - Research topics: authentication,authorization,session,password
    - Output directory: ${RESEARCH_DIR}
    - State file: ${STATE_FILE}

    REQUIRED OUTPUT:
    Return completion signal with aggregated metadata:
    SUPERVISOR_COMPLETE: <json_metadata>
}
```

### 2. Worker Invocation by Supervisor

The supervisor invokes workers in parallel using multiple Task tool calls in a single message:

```markdown
**STEP 3: Invoke Workers in Parallel**

**EXECUTE NOW**: USE the Task tool to invoke 4 research workers simultaneously.

Send a SINGLE message with FOUR Task tool invocations:

Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    INPUTS:
    - Research topic: Authentication patterns (session-based, JWT, OAuth2)
    - Output path: ${RESEARCH_DIR}/001_authentication_patterns.md

    REQUIRED OUTPUT:
    Return completion signal:
    REPORT_CREATED: /path/to/report.md
}

Task {
  subagent_type: "general-purpose"
  description: "Research authorization patterns"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    INPUTS:
    - Research topic: Authorization patterns (RBAC, ABAC, policy-based)
    - Output path: ${RESEARCH_DIR}/002_authorization_patterns.md

    REQUIRED OUTPUT:
    Return completion signal:
    REPORT_CREATED: /path/to/report.md
}

Task {
  subagent_type: "general-purpose"
  description: "Research session management"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    INPUTS:
    - Research topic: Session management (server-side, client-side, security)
    - Output path: ${RESEARCH_DIR}/003_session_management.md

    REQUIRED OUTPUT:
    Return completion signal:
    REPORT_CREATED: /path/to/report.md
}

Task {
  subagent_type: "general-purpose"
  description: "Research password security"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    INPUTS:
    - Research topic: Password security (hashing, policies, breach detection)
    - Output path: ${RESEARCH_DIR}/004_password_security.md

    REQUIRED OUTPUT:
    Return completion signal:
    REPORT_CREATED: /path/to/report.md
}
```

### 3. Worker Completion Signal

Workers return completion signal with artifact path:

```
REPORT_CREATED: /home/user/.config/.claude/specs/042_auth/reports/001_authentication_patterns.md
```

The supervisor parses this signal to extract the report path.

### 4. Metadata Extraction by Supervisor

The supervisor extracts metadata from each worker output:

```bash
# Extract metadata from worker report using metadata-extraction.sh
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/metadata-extraction.sh"

WORKER_1_METADATA=$(extract_report_metadata "$WORKER_1_OUTPUT_PATH")
# Returns: {
#   "title": "Authentication Patterns Research",
#   "summary": "Analysis of session-based auth, JWT tokens, OAuth2 flows",
#   "key_findings": ["finding1", "finding2"]
# }
```

### 5. Metadata Aggregation by Supervisor

The supervisor combines worker metadata into aggregated summary:

```bash
# Aggregate worker metadata
aggregate_worker_metadata() {
  local worker_metadata_array="$1"

  # Combine summaries (50-100 words total)
  local combined_summary=$(echo "$worker_metadata_array" | jq -r '
    [.[].summary] | join(". ") |
    split(" ") | .[0:100] | join(" ")
  ')

  # Merge key findings (top 2 per worker, max 12 total)
  local merged_findings=$(echo "$worker_metadata_array" | jq -r '
    [.[].key_findings[] | select(. != null)] |
    .[0:12]
  ')

  # Build aggregated metadata
  jq -n \
    --argjson workers "$worker_metadata_array" \
    --arg summary "$combined_summary" \
    --argjson findings "$merged_findings" \
    '{
      topics_researched: ($workers | length),
      reports_created: [$workers[].output_path],
      summary: $summary,
      key_findings: $findings,
      total_duration_ms: ($workers | map(.duration_ms) | add),
      context_tokens: ($summary | length / 4 | floor)
    }'
}
```

### 6. Checkpoint Coordination

The supervisor saves its state using state-persistence.sh:

```bash
# Load workflow state (initialized by orchestrator)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
load_workflow_state "coordinate_$$"

# Build supervisor checkpoint
SUPERVISOR_CHECKPOINT=$(jq -n \
  --arg supervisor_id "research_sub_supervisor_$(date +%s)" \
  --arg supervisor_name "research-sub-supervisor" \
  --argjson worker_count 4 \
  --argjson workers "$WORKERS_ARRAY" \
  --argjson aggregated "$AGGREGATED_METADATA" \
  '{
    supervisor_id: $supervisor_id,
    supervisor_name: $supervisor_name,
    worker_count: $worker_count,
    workers: $workers,
    aggregated_metadata: $aggregated
  }')

# Save supervisor checkpoint
save_json_checkpoint "research_supervisor" "$SUPERVISOR_CHECKPOINT"
```

### 7. Supervisor Completion Signal

The supervisor returns aggregated metadata ONLY (not full worker outputs):

```
SUPERVISOR_COMPLETE: {
  "supervisor_id": "research_sub_supervisor_20251107_143030",
  "topics_researched": 4,
  "reports_created": ["path1.md", "path2.md", "path3.md", "path4.md"],
  "summary": "Combined 50-word summary",
  "key_findings": ["finding1", "finding2", "finding3", "finding4"]
}
```

**Context Reduction**: Supervisor returns ~500 tokens vs ~10,000 tokens if full worker outputs returned (95% reduction).

## Partial Failure Handling

### Scenario: 2/3 Workers Succeed

If 2 out of 3 workers complete successfully but 1 fails:

```bash
# Check worker status
SUCCESSFUL_WORKERS=$(echo "$WORKERS_ARRAY" | jq '[.[] | select(.status == "completed")]')
FAILED_WORKERS=$(echo "$WORKERS_ARRAY" | jq '[.[] | select(.status == "failed")]')

SUCCESS_COUNT=$(echo "$SUCCESSFUL_WORKERS" | jq 'length')
FAILURE_COUNT=$(echo "$FAILED_WORKERS" | jq 'length')

if [ $FAILURE_COUNT -gt 0 ] && [ $SUCCESS_COUNT -ge 2 ]; then
  # Partial success: aggregate successful workers
  AGGREGATED_METADATA=$(aggregate_worker_metadata "$SUCCESSFUL_WORKERS")

  # Add failure context to summary
  FAILURE_SUMMARY=$(echo "$FAILED_WORKERS" | jq -r '
    [.[] | "Failed: \(.topic) (\(.error))"] | join("; ")
  ')

  AGGREGATED_METADATA=$(echo "$AGGREGATED_METADATA" | jq \
    --arg failures "$FAILURE_SUMMARY" \
    '.partial_failures = $failures')

  # Return success with failure context
  echo "SUPERVISOR_COMPLETE: $AGGREGATED_METADATA"
  echo "WARNING: Partial failures occurred: $FAILURE_SUMMARY" >&2
fi
```

### Scenario: All Workers Fail

If all workers fail, supervisor returns error:

```bash
if [ $SUCCESS_COUNT -eq 0 ]; then
  echo "ERROR: All workers failed" >&2
  echo "SUPERVISOR_FAILED: {\"errors\": $(echo "$FAILED_WORKERS" | jq '[.[] | .error]')}" >&2
  return 1
fi
```

## Conditional Hierarchical Invocation

### Decision Matrix

Orchestrators use these thresholds to decide between flat and hierarchical coordination:

| Supervisor Type | Threshold | Flat Coordination | Hierarchical Coordination |
|----------------|-----------|-------------------|---------------------------|
| Research | Topic count | < 4 topics | ≥ 4 topics |
| Implementation | Domain count OR complexity | < 3 domains AND complexity < 10 | ≥ 3 domains OR complexity ≥ 10 |
| Testing | Test count OR test types | < 20 tests AND < 2 test types | ≥ 20 tests OR ≥ 2 test types |

### Example: Research Supervisor

```bash
# Count research topics
TOPIC_COUNT=$(echo "$RESEARCH_TOPICS" | tr ',' '\n' | wc -l)

if [ $TOPIC_COUNT -ge 4 ]; then
  # Use hierarchical supervision
  echo "Using hierarchical research supervision for $TOPIC_COUNT topics"

  # Invoke research supervisor
  USE the Task tool to invoke research supervisor
else
  # Use flat coordination (direct worker invocation)
  echo "Using flat coordination for $TOPIC_COUNT topics"

  # Invoke research specialists directly
  for topic in $RESEARCH_TOPICS; do
    USE the Task tool to invoke research-specialist for $topic
  done
fi
```

## Context Reduction Validation

### Target: 95% Reduction

Full worker outputs: ~10,000 tokens (4 reports × 2,500 tokens each)
Aggregated metadata: ~500 tokens (supervisor summary)

Reduction: (10,000 - 500) / 10,000 = 95%

### Validation Formula

```bash
validate_context_reduction() {
  local worker_outputs="$1"
  local aggregated_metadata="$2"

  # Calculate token counts (rough estimate: 4 chars per token)
  WORKER_TOKENS=$(echo "$worker_outputs" | wc -c | awk '{print int($1/4)}')
  AGGREGATED_TOKENS=$(echo "$aggregated_metadata" | wc -c | awk '{print int($1/4)}')

  # Calculate reduction percentage
  REDUCTION_PERCENT=$(echo "$WORKER_TOKENS $AGGREGATED_TOKENS" | awk '{
    reduction = (($1 - $2) / $1) * 100
    printf "%.1f", reduction
  }')

  echo "Context reduction: $REDUCTION_PERCENT% ($WORKER_TOKENS → $AGGREGATED_TOKENS tokens)"

  # Validate ≥ 90% reduction
  if (( $(echo "$REDUCTION_PERCENT >= 90" | bc -l) )); then
    echo "✓ Context reduction target met (≥90%)"
    return 0
  else
    echo "✗ Context reduction below target (<90%)"
    return 1
  fi
}
```

## Nested Checkpoint Structure

### Two-Level Hierarchy

```
Orchestrator Checkpoint (coordinate)
├── state_machine
│   ├── current_state: "plan"
│   └── completed_states: ["initialize", "research"]
├── supervisor_state
│   ├── research_supervisor
│   │   ├── supervisor_id, supervisor_name, worker_count
│   │   ├── workers[] (4 workers with metadata)
│   │   └── aggregated_metadata (95% reduced)
│   ├── implementation_supervisor
│   │   ├── supervisor_id, supervisor_name, worker_count
│   │   ├── tracks[] (3 tracks with metadata)
│   │   └── aggregated_metadata (parallel time savings)
│   └── testing_supervisor
│       ├── supervisor_id, supervisor_name, worker_count
│       ├── stages[] (sequential stages)
│       └── aggregated_metadata (test results)
└── phase_data
    ├── research: {reports_created, duration_ms}
    └── plan: {plan_path, complexity}
```

### Checkpoint Loading

When orchestrator resumes from checkpoint:

```bash
# Load checkpoint
CHECKPOINT=$(restore_checkpoint "coordinate" "auth_system")

# Extract supervisor state
RESEARCH_SUPERVISOR=$(echo "$CHECKPOINT" | jq -r '.supervisor_state.research_supervisor')

# Check if research already completed
if [ "$RESEARCH_SUPERVISOR" != "null" ]; then
  echo "Research phase already completed by supervisor"

  # Extract aggregated metadata
  AGGREGATED_METADATA=$(echo "$RESEARCH_SUPERVISOR" | jq -r '.aggregated_metadata')

  # Use metadata (no need to re-invoke supervisor)
  REPORTS_CREATED=$(echo "$AGGREGATED_METADATA" | jq -r '.reports_created[]')

  # Skip to next phase
  sm_transition "plan"
fi
```

## Performance Characteristics

### Research Supervisor

- **Workers**: 4 parallel research specialists
- **Worker output size**: 2,500 tokens each (10,000 total)
- **Aggregated metadata size**: 500 tokens
- **Context reduction**: 95%
- **Parallel execution time**: Max worker duration (~12 seconds)
- **Sequential execution time**: Sum of worker durations (~45 seconds)
- **Time savings**: 73%

### Implementation Supervisor

- **Workers**: 3 parallel implementation executors (tracks)
- **Parallel execution time**: Max track duration (~30 seconds)
- **Sequential execution time**: Sum of track durations (~70 seconds)
- **Time savings**: 57% (40-60% typical)

### Testing Supervisor

- **Stages**: 3 sequential stages (generation → execution → validation)
- **Workers per stage**: 2-3 parallel workers
- **Stage execution**: Sequential (cannot parallelize)
- **Worker execution within stage**: Parallel
- **Time savings**: 40-50% within stages (not across stages)

## References

- [State Persistence Library](../reference/library-api/overview.md#state-persistence)
- [Workflow State Machine](workflow-state-machine.md)
- [Checkpoint Utils](../reference/library-api/overview.md#checkpoint-utils)
- [Metadata Extraction](../reference/library-api/overview.md#metadata-extraction)
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md)

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-11-07 | Initial architecture document for Phase 4 |
