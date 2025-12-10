# Coordinator Patterns Standard

**Purpose**: Define five core coordinator patterns for hierarchical agent architecture implementation, ensuring consistency across all coordinator agents.

**Status**: Production-ready (implemented in research-coordinator, implementer-coordinator, testing-coordinator, debug-coordinator, repair-coordinator)

**Applies To**: All coordinator/supervisor agents in `.claude/agents/`

**Related Documentation**:
- [Three-Tier Coordination Pattern](../../concepts/three-tier-coordination-pattern.md) - Tier responsibilities
- [Choosing Agent Architecture](../../guides/architecture/choosing-agent-architecture.md) - Decision framework
- [Coordinator Return Signals](coordinator-return-signals.md) - Signal contract specifications

---

## Overview

Coordinator agents implement five core patterns to achieve 95-96% context reduction, 100% delegation success, and graceful degradation. These patterns are mandatory for all coordinators to ensure consistent behavior and reliable multi-agent orchestration.

**The Five Core Patterns**:
1. **Path Pre-Calculation Pattern** - Hard barrier enforcement via pre-calculated artifact paths
2. **Metadata Extraction Pattern** - 95%+ context reduction via brief metadata summaries
3. **Partial Success Mode Pattern** - ≥50% threshold with graceful degradation
4. **Error Return Protocol** - Structured ERROR_CONTEXT + TASK_ERROR signals
5. **Multi-Layer Validation Pattern** - Invocation plan → trace artifacts → output artifacts

---

## Pattern 1: Path Pre-Calculation (Hard Barrier Enforcement)

### Purpose

Enforce hard barrier pattern by pre-calculating all specialist artifact paths BEFORE specialist invocation, guaranteeing delegation and preventing orchestrators from bypassing coordinators.

### Requirements

**MANDATORY**:
- [ ] Coordinator receives pre-calculated paths from command (preferred) OR calculates paths before specialist invocation
- [ ] Paths are absolute (not relative)
- [ ] Paths include topic directories and artifact subdirectories (`specs/{NNN_topic}/reports/`)
- [ ] Paths are validated for directory existence before specialist invocation
- [ ] Paths are persisted in invocation plan file for traceability
- [ ] Specialist receives EXACT path (no path calculation by specialist)

**PROHIBITED**:
- ✗ Letting specialists calculate their own output paths
- ✗ Passing relative paths to specialists
- ✗ Using shared state ID files for path discovery
- ✗ Coordinator invoking specialists before validating path structure

### Implementation Pattern

**Command Pre-Calculates Paths** (Preferred):
```bash
# Block 1a: Pre-Calculate Artifact Paths (Command)
# Topic directory created lazily via unified-location-detection.sh
TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESC" ".claude/specs")
REPORT_DIR="${TOPIC_DIR}/reports"
mkdir -p "$REPORT_DIR"

# Pre-calculate all report paths
declare -a REPORT_PATHS=(
  "${REPORT_DIR}/001_topic1.md"
  "${REPORT_DIR}/002_topic2.md"
  "${REPORT_DIR}/003_topic3.md"
  "${REPORT_DIR}/004_topic4.md"
)

# Persist for coordinator access
save_workflow_state "REPORT_PATHS" "${REPORT_PATHS[@]}"
save_workflow_state "REPORT_DIR" "$REPORT_DIR"
save_workflow_state "TOPIC_PATH" "$TOPIC_DIR"
```

**Coordinator Validates and Passes Paths** (Task Invocation):
```markdown
Task {
  prompt: |
    Read and follow: .claude/agents/research-coordinator.md

    **Input Contract (Hard Barrier Pattern)**:
    - report_dir: ${REPORT_DIR}
    - topic_path: ${TOPIC_PATH}
    - topics: ["Topic 1", "Topic 2", "Topic 3", "Topic 4"]
    - report_paths: ["${REPORT_PATHS[@]}"]
}
```

**Coordinator Validates Paths**:
```bash
# STEP 1: Validate Input Contract
if [ -z "${report_paths:-}" ]; then
  ERROR_CONTEXT='{"error_type":"validation_error","message":"Missing report_paths array"}'
  echo "TASK_ERROR: validation_error - report_paths array not provided"
  exit 1
fi

# STEP 2: Validate Directory Exists
if [ ! -d "$report_dir" ]; then
  ERROR_CONTEXT='{"error_type":"file_error","message":"Report directory missing","details":{"path":"'"$report_dir"'"}}'
  echo "TASK_ERROR: file_error - Report directory missing: $report_dir"
  exit 1
fi
```

**Coordinator Creates Invocation Plan**:
```bash
# STEP 3: Create Invocation Plan File (Hard Barrier Proof)
INVOCATION_PLAN_PATH="${topic_path}/.invocation-plan.txt"

cat > "$INVOCATION_PLAN_PATH" <<EOF
Expected Invocations: ${#topics[@]}

Topics:
EOF

for i in "${!topics[@]}"; do
  echo "[$i] ${topics[$i]} -> ${report_paths[$i]}" >> "$INVOCATION_PLAN_PATH"
done

echo "Status: PLAN_COMPLETE (ready for primary agent invocation)" >> "$INVOCATION_PLAN_PATH"
```

**Coordinator Passes Exact Paths to Specialists**:
```markdown
Task {
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    **Input Contract**:
    - research_topic: "${topics[$i]}"
    - report_path: ${report_paths[$i]}  # EXACT absolute path
    - topic_path: ${topic_path}
}
```

### Validation

**Pre-Invocation Checklist**:
- [ ] All paths are absolute (start with `/`)
- [ ] Topic directory exists
- [ ] Artifact subdirectories created (`reports/`, `plans/`, `summaries/`)
- [ ] Invocation plan file created
- [ ] Path count matches topic count

**Post-Invocation Validation**:
```bash
# STEP N: Validate Specialist Outputs (Hard Barrier)
for path in "${report_paths[@]}"; do
  if [ ! -f "$path" ]; then
    ERROR_CONTEXT='{"error_type":"validation_error","message":"Report missing after specialist completion","details":{"missing_path":"'"$path"'"}}'
    echo "TASK_ERROR: validation_error - Report missing: $path"
    exit 1
  fi
done
```

### Examples

- **research-coordinator**: Validates report_paths array, creates invocation plan, passes exact paths to research-specialist
- **implementer-coordinator**: Validates phase_file_paths, creates wave execution plan, passes exact paths to implementation-executor
- **testing-coordinator**: Pre-calculates test result paths, validates test suite directories, passes paths to test-executor

---

## Pattern 2: Metadata Extraction (95%+ Context Reduction)

### Purpose

Extract brief metadata summaries (110-150 tokens) from specialist artifacts instead of passing full content (2,000-2,500 tokens) to orchestrators, achieving 95-96% context reduction.

### Requirements

**MANDATORY**:
- [ ] Extract metadata from YAML frontmatter (not full file reads)
- [ ] Generate metadata objects with 4-6 fields (path, title, counts)
- [ ] Aggregate metadata across all specialists
- [ ] Return metadata-only to orchestrator (no full content)
- [ ] Calculate totals (total_findings, total_reports, etc.)
- [ ] Target: 110-150 tokens per artifact metadata

**PROHIBITED**:
- ✗ Reading full specialist output files (>2,000 tokens)
- ✗ Passing full file content to orchestrator
- ✗ Extracting metadata without YAML frontmatter
- ✗ Including verbose details in metadata objects

### Implementation Pattern

**YAML Frontmatter Extraction**:
```bash
# STEP 1: Extract Metadata from YAML Frontmatter
extract_report_metadata() {
  local report_path="$1"

  # Read only YAML frontmatter (first 20 lines)
  local yaml_content=$(head -n 20 "$report_path")

  # Extract fields using grep/sed (lightweight parsing)
  local findings_count=$(echo "$yaml_content" | grep "^findings_count:" | sed 's/^findings_count:[[:space:]]*//')
  local recommendations_count=$(echo "$yaml_content" | grep "^recommendations_count:" | sed 's/^recommendations_count:[[:space:]]*//')
  local report_type=$(echo "$yaml_content" | grep "^report_type:" | sed 's/^report_type:[[:space:]]*//')

  # Extract title from first heading (after YAML)
  local title=$(grep -m 1 "^# " "$report_path" | sed 's/^# //')

  # Build metadata JSON (110 tokens)
  jq -n \
    --arg path "$report_path" \
    --arg title "$title" \
    --arg type "$report_type" \
    --argjson findings "$findings_count" \
    --argjson recommendations "$recommendations_count" \
    '{
      path: $path,
      title: $title,
      report_type: $type,
      findings_count: $findings,
      recommendations_count: $recommendations
    }'
}
```

**Aggregate Metadata Across Specialists**:
```bash
# STEP 2: Aggregate Metadata
METADATA_ARRAY="[]"
TOTAL_FINDINGS=0
TOTAL_RECOMMENDATIONS=0

for report_path in "${report_paths[@]}"; do
  # Extract metadata (110 tokens per report)
  metadata=$(extract_report_metadata "$report_path")

  # Aggregate
  METADATA_ARRAY=$(echo "$METADATA_ARRAY" | jq ". + [$metadata]")
  TOTAL_FINDINGS=$(( TOTAL_FINDINGS + $(echo "$metadata" | jq '.findings_count') ))
  TOTAL_RECOMMENDATIONS=$(( TOTAL_RECOMMENDATIONS + $(echo "$metadata" | jq '.recommendations_count') ))
done

# Build aggregated response (440 tokens for 4 reports vs 10,000 baseline)
AGGREGATED_METADATA=$(jq -n \
  --argjson reports "$METADATA_ARRAY" \
  --argjson total_reports "${#report_paths[@]}" \
  --argjson total_findings "$TOTAL_FINDINGS" \
  --argjson total_recommendations "$TOTAL_RECOMMENDATIONS" \
  '{
    reports: $reports,
    total_reports: $total_reports,
    total_findings: $total_findings,
    total_recommendations: $total_recommendations
  }')
```

**Return Metadata-Only to Orchestrator**:
```markdown
## Coordinator Return Signal

RESEARCH_COORDINATOR_COMPLETE: SUCCESS
topics_planned: 4
invocation_plan_path: /path/.invocation-plan.txt
context_usage_percent: 8

METADATA_SUMMARY:
```json
{
  "reports": [
    {
      "path": "/path/001-mathlib.md",
      "title": "Mathlib Theorems",
      "findings_count": 12,
      "recommendations_count": 5
    },
    {
      "path": "/path/002-proofs.md",
      "title": "Proof Strategies",
      "findings_count": 8,
      "recommendations_count": 4
    },
    {
      "path": "/path/003-structure.md",
      "title": "Project Structure",
      "findings_count": 6,
      "recommendations_count": 3
    },
    {
      "path": "/path/004-style.md",
      "title": "Coding Style",
      "findings_count": 4,
      "recommendations_count": 3
    }
  ],
  "total_reports": 4,
  "total_findings": 30,
  "total_recommendations": 15
}
```
```

### Context Reduction Calculation

```
Baseline (Orchestrator reads all files):
  4 reports x 2,500 tokens = 10,000 tokens

Hierarchical (Coordinator extracts metadata):
  4 reports x 110 tokens metadata = 440 tokens

Context Reduction: (10,000 - 440) / 10,000 = 95.6%
```

### Validation

**Metadata Completeness**:
- [ ] All required fields present (path, title, counts)
- [ ] Counts are numeric (not null or strings)
- [ ] Paths are absolute
- [ ] Total calculations correct

**Token Budget**:
- [ ] Metadata per artifact: 110-150 tokens
- [ ] Total metadata: <500 tokens for 4 artifacts
- [ ] Context reduction ≥95%

### Examples

- **research-coordinator**: Extracts findings_count, recommendations_count from research reports (110 tokens/report)
- **implementer-coordinator**: Extracts tasks_completed, tests_passing from phase summaries (80 tokens/phase via brief format)
- **testing-coordinator**: Extracts test_count, passed_count, coverage_percent from test results (120 tokens/suite)

---

## Pattern 3: Partial Success Mode (≥50% Threshold)

### Purpose

Enable graceful degradation when some specialists fail, allowing workflows to continue with partial results instead of complete failure. Supports ≥50% success threshold with warnings.

### Requirements

**MANDATORY**:
- [ ] Calculate success rate (completed / total)
- [ ] Accept ≥50% success with warnings
- [ ] Reject <50% success with errors
- [ ] Log failed specialist details for debugging
- [ ] Return partial results with success indicators
- [ ] Include failed_topics array in return signal

**PROHIBITED**:
- ✗ Failing entire workflow on single specialist error (unless <50%)
- ✗ Silently accepting failures without logging
- ✗ Returning success signal with <50% completion
- ✗ Omitting failed specialist details from error context

### Implementation Pattern

**Calculate Success Rate**:
```bash
# STEP 1: Track Specialist Completions
declare -a COMPLETED_PATHS=()
declare -a FAILED_TOPICS=()

for i in "${!topics[@]}"; do
  topic="${topics[$i]}"
  path="${report_paths[$i]}"

  # Check if specialist created artifact
  if [ -f "$path" ]; then
    COMPLETED_PATHS+=("$path")
  else
    FAILED_TOPICS+=("$topic")
  fi
done

# STEP 2: Calculate Success Rate
TOTAL_TOPICS=${#topics[@]}
COMPLETED_COUNT=${#COMPLETED_PATHS[@]}
SUCCESS_RATE=$(( COMPLETED_COUNT * 100 / TOTAL_TOPICS ))
```

**Apply Threshold Logic**:
```bash
# STEP 3: Evaluate Against Threshold
if [ "$SUCCESS_RATE" -lt 50 ]; then
  # REJECT: Less than 50% success
  ERROR_CONTEXT=$(jq -n \
    --argjson rate "$SUCCESS_RATE" \
    --argjson completed "$COMPLETED_COUNT" \
    --argjson total "$TOTAL_TOPICS" \
    --argjson failed "$(printf '%s\n' "${FAILED_TOPICS[@]}" | jq -R . | jq -s .)" \
    '{
      error_type: "agent_error",
      message: "Insufficient specialist completions (< 50% threshold)",
      details: {
        success_rate: $rate,
        completed: $completed,
        total: $total,
        failed_topics: $failed
      }
    }')

  echo "TASK_ERROR: agent_error - Only $COMPLETED_COUNT/$TOTAL_TOPICS specialists completed (<50% threshold)"
  exit 1

elif [ "$SUCCESS_RATE" -lt 100 ]; then
  # WARN: 50-99% success (partial success mode)
  echo "WARNING: Partial success mode - $COMPLETED_COUNT/$TOTAL_TOPICS specialists completed (${SUCCESS_RATE}%)"
  echo "Failed topics: ${FAILED_TOPICS[*]}"

else
  # SUCCESS: 100% completion
  echo "SUCCESS: All $TOTAL_TOPICS specialists completed"
fi
```

**Return Partial Results**:
```markdown
## Coordinator Return Signal (Partial Success)

RESEARCH_COORDINATOR_COMPLETE: PARTIAL_SUCCESS
topics_planned: 4
topics_completed: 3
success_rate: 75
failed_topics: ["Coding Style Guidelines"]
context_usage_percent: 8

METADATA_SUMMARY:
```json
{
  "reports": [
    {"path": "/path/001-mathlib.md", ...},
    {"path": "/path/002-proofs.md", ...},
    {"path": "/path/003-structure.md", ...}
  ],
  "total_reports": 3,
  "failed_topics": ["Coding Style Guidelines"],
  "partial_success": true
}
```

WARNING: 1 specialist failed (75% success rate)
```

### Validation

**Threshold Enforcement**:
- [ ] <50% success → exit 1 with error
- [ ] 50-99% success → continue with warning
- [ ] 100% success → continue without warning

**Error Context**:
- [ ] Failed topics array populated
- [ ] Success rate calculated correctly
- [ ] Error details include completion counts

### Examples

- **research-coordinator**: 3/4 reports completed (75%) → PARTIAL_SUCCESS with warning
- **implementer-coordinator**: 2/5 phases completed (40%) → TASK_ERROR with exit 1
- **testing-coordinator**: 4/4 test suites passed (100%) → SUCCESS without warning

---

## Pattern 4: Error Return Protocol

### Purpose

Provide structured error context for orchestrator logging and debugging when coordinator or specialist errors occur. Enables centralized error tracking via errors.jsonl integration.

### Requirements

**MANDATORY**:
- [ ] Return ERROR_CONTEXT JSON with error_type, message, details
- [ ] Emit TASK_ERROR signal for orchestrator parsing
- [ ] Use standardized error types (validation_error, agent_error, file_error, etc.)
- [ ] Include recovery hints in error messages
- [ ] Exit 1 on critical errors (not exit 0)

**PROHIBITED**:
- ✗ Generic error messages without details
- ✗ Missing ERROR_CONTEXT JSON
- ✗ Non-standard error types
- ✗ Exit 0 on errors (masks failures)

### Error Types (Standardized)

- `validation_error` - Input validation failures, missing required fields
- `agent_error` - Specialist execution failures, delegation errors
- `parse_error` - Output parsing failures, signal format errors
- `file_error` - File system errors, missing directories
- `timeout_error` - Operation timeout errors
- `execution_error` - General execution failures
- `dependency_error` - Missing dependencies, invalid references
- `state_error` - Workflow state persistence issues

### Implementation Pattern

**Input Validation Error**:
```bash
# Validate required input field
if [ -z "${research_request:-}" ]; then
  ERROR_CONTEXT='{"error_type":"validation_error","message":"Missing research_request field","details":{"required_fields":["research_request","topics","report_paths"]}}'
  echo "TASK_ERROR: validation_error - research_request field not provided in input contract"
  exit 1
fi
```

**Agent Execution Error**:
```bash
# Specialist failed to create artifact
if [ ! -f "$report_path" ]; then
  ERROR_CONTEXT=$(jq -n \
    --arg path "$report_path" \
    --arg topic "$topic" \
    '{
      error_type: "agent_error",
      message: "Specialist failed to create report",
      details: {
        missing_path: $path,
        topic: $topic,
        recovery_hint: "Check specialist logs for errors, verify path permissions"
      }
    }')
  echo "TASK_ERROR: agent_error - Specialist failed to create report at $report_path"
  exit 1
fi
```

**File System Error**:
```bash
# Directory not found
if [ ! -d "$report_dir" ]; then
  ERROR_CONTEXT=$(jq -n \
    --arg dir "$report_dir" \
    '{
      error_type: "file_error",
      message: "Report directory does not exist",
      details: {
        missing_directory: $dir,
        recovery_hint: "Create directory structure before coordinator invocation"
      }
    }')
  echo "TASK_ERROR: file_error - Report directory missing: $report_dir"
  exit 1
fi
```

**Parse Error**:
```bash
# Failed to parse specialist output
if ! echo "$specialist_output" | jq . >/dev/null 2>&1; then
  ERROR_CONTEXT=$(jq -n \
    --arg output "${specialist_output:0:200}" \
    '{
      error_type: "parse_error",
      message: "Specialist returned invalid JSON output",
      details: {
        output_preview: $output,
        expected_format: "REPORT_CREATED: /absolute/path"
      }
    }')
  echo "TASK_ERROR: parse_error - Invalid specialist output format"
  exit 1
fi
```

### Orchestrator Integration

**Command Parsing**:
```bash
# Parse coordinator error
if echo "$COORDINATOR_OUTPUT" | grep -q "^TASK_ERROR:"; then
  ERROR_TYPE=$(echo "$COORDINATOR_OUTPUT" | grep "^TASK_ERROR:" | sed 's/^TASK_ERROR: \([a-z_]*\) -.*/\1/')
  ERROR_MESSAGE=$(echo "$COORDINATOR_OUTPUT" | grep "^TASK_ERROR:" | sed 's/^TASK_ERROR: [a-z_]* - //')
  ERROR_CONTEXT=$(echo "$COORDINATOR_OUTPUT" | grep "^ERROR_CONTEXT:" | sed 's/^ERROR_CONTEXT: //')

  # Log to centralized error log
  log_command_error "$ERROR_TYPE" "$ERROR_MESSAGE" "$ERROR_CONTEXT"

  # Display to user
  echo "ERROR: Coordinator failed - $ERROR_MESSAGE"
  exit 1
fi
```

### Validation

**Error Signal Format**:
- [ ] ERROR_CONTEXT is valid JSON
- [ ] TASK_ERROR signal includes error_type
- [ ] Error message is descriptive (not generic)
- [ ] Recovery hints provided when applicable
- [ ] Exit code is 1 (not 0)

### Examples

- **research-coordinator**: Returns validation_error when topics array missing
- **implementer-coordinator**: Returns agent_error when ≥50% phases fail
- **testing-coordinator**: Returns file_error when test suite directory not found

---

## Pattern 5: Multi-Layer Validation

### Purpose

Validate coordinator execution at three layers (invocation plan, trace artifacts, output artifacts) to ensure delegation occurred correctly and all expected outputs exist.

### Requirements

**MANDATORY**:
- [ ] Layer 1: Validate invocation plan file created (hard barrier proof)
- [ ] Layer 2: Validate trace artifacts exist (logs, checkpoints)
- [ ] Layer 3: Validate output artifacts exist (reports, summaries, plans)
- [ ] All validations fail-fast (exit 1 on missing artifacts)
- [ ] Validation errors include recovery hints

**PROHIBITED**:
- ✗ Skipping any validation layer
- ✗ Continuing execution with missing artifacts
- ✗ Silent failures (no error logging)
- ✗ Validating only final outputs (must validate invocation plan)

### Implementation Pattern

**Layer 1: Invocation Plan Validation**:
```bash
# STEP 1: Validate Invocation Plan File Created
INVOCATION_PLAN_PATH="${topic_path}/.invocation-plan.txt"

if [ ! -f "$INVOCATION_PLAN_PATH" ]; then
  ERROR_CONTEXT='{"error_type":"validation_error","message":"Invocation plan file not created","details":{"expected_path":"'"$INVOCATION_PLAN_PATH"'"}}'
  echo "TASK_ERROR: validation_error - Invocation plan file missing (hard barrier failure)"
  exit 1
fi

# Validate plan completeness
EXPECTED_INVOCATIONS=$(grep "^Expected Invocations:" "$INVOCATION_PLAN_PATH" | awk '{print $3}')
if [ "$EXPECTED_INVOCATIONS" != "${#topics[@]}" ]; then
  echo "ERROR: Invocation plan incomplete (expected ${#topics[@]}, found $EXPECTED_INVOCATIONS)"
  exit 1
fi
```

**Layer 2: Trace Artifact Validation** (Optional):
```bash
# STEP 2: Validate Trace Artifacts (Logs, Checkpoints)
# This layer is optional but recommended for debugging

TRACE_DIR="${topic_path}/.trace"
if [ -d "$TRACE_DIR" ]; then
  # Validate specialist invocation logs exist
  for i in "${!topics[@]}"; do
    log_file="${TRACE_DIR}/specialist_${i}.log"
    if [ ! -f "$log_file" ]; then
      echo "WARNING: Trace log missing for topic ${topics[$i]}"
    fi
  done
fi
```

**Layer 3: Output Artifact Validation**:
```bash
# STEP 3: Validate Output Artifacts (Reports, Plans, Summaries)
declare -a MISSING_ARTIFACTS=()

for i in "${!report_paths[@]}"; do
  path="${report_paths[$i]}"
  topic="${topics[$i]}"

  if [ ! -f "$path" ]; then
    MISSING_ARTIFACTS+=("$topic -> $path")
  fi
done

# Fail-fast if any outputs missing (unless partial success mode)
if [ "${#MISSING_ARTIFACTS[@]}" -gt 0 ]; then
  MISSING_COUNT=${#MISSING_ARTIFACTS[@]}
  TOTAL_COUNT=${#report_paths[@]}
  FAILURE_RATE=$(( MISSING_COUNT * 100 / TOTAL_COUNT ))

  if [ "$FAILURE_RATE" -ge 50 ]; then
    # Critical failure (≥50% missing)
    ERROR_CONTEXT=$(jq -n \
      --argjson missing "$(printf '%s\n' "${MISSING_ARTIFACTS[@]}" | jq -R . | jq -s .)" \
      --argjson count "$MISSING_COUNT" \
      '{
        error_type: "validation_error",
        message: "Critical output artifact failure",
        details: {
          missing_artifacts: $missing,
          missing_count: $count,
          recovery_hint: "Check specialist logs in .trace/ directory"
        }
      }')
    echo "TASK_ERROR: validation_error - $MISSING_COUNT/$TOTAL_COUNT outputs missing (≥50% failure)"
    exit 1
  else
    # Partial success (warnings only)
    echo "WARNING: $MISSING_COUNT/$TOTAL_COUNT outputs missing"
    echo "Missing artifacts:"
    printf '%s\n' "${MISSING_ARTIFACTS[@]}"
  fi
fi
```

### Validation Checkpoint Summary

```bash
# STEP 4: Summary of Multi-Layer Validation
echo "=== Validation Summary ==="
echo "Layer 1 (Invocation Plan): ✓ PASS"
echo "Layer 2 (Trace Artifacts): ✓ PASS (${#topics[@]} logs)"
echo "Layer 3 (Output Artifacts): ✓ PASS (${#COMPLETED_PATHS[@]}/${#report_paths[@]} outputs)"
echo "Overall Status: SUCCESS"
```

### Examples

- **research-coordinator**: Validates .invocation-plan.txt → specialist logs → research reports
- **implementer-coordinator**: Validates .wave-plan.txt → phase checkpoints → implementation summaries
- **testing-coordinator**: Validates .test-plan.txt → test execution logs → test result files

---

## Summary: Pattern Compliance Checklist

Use this checklist when implementing new coordinators or auditing existing ones:

### Pattern 1: Path Pre-Calculation
- [ ] Receives pre-calculated paths from command OR calculates before specialist invocation
- [ ] All paths are absolute
- [ ] Creates invocation plan file with path mappings
- [ ] Validates directory structure before specialist invocation
- [ ] Passes exact paths to specialists (no specialist path calculation)

### Pattern 2: Metadata Extraction
- [ ] Extracts metadata from YAML frontmatter (not full files)
- [ ] Generates 110-150 token metadata objects per artifact
- [ ] Aggregates metadata across all specialists
- [ ] Returns metadata-only to orchestrator (no full content)
- [ ] Achieves ≥95% context reduction

### Pattern 3: Partial Success Mode
- [ ] Calculates success rate (completed / total)
- [ ] Accepts ≥50% success with warnings
- [ ] Rejects <50% success with errors
- [ ] Logs failed specialist details
- [ ] Returns partial results with success indicators

### Pattern 4: Error Return Protocol
- [ ] Returns ERROR_CONTEXT JSON with error_type, message, details
- [ ] Emits TASK_ERROR signal for orchestrator parsing
- [ ] Uses standardized error types
- [ ] Includes recovery hints in error messages
- [ ] Exit 1 on critical errors

### Pattern 5: Multi-Layer Validation
- [ ] Layer 1: Validates invocation plan file created
- [ ] Layer 2: Validates trace artifacts exist (optional)
- [ ] Layer 3: Validates output artifacts exist
- [ ] All validations fail-fast on missing artifacts
- [ ] Validation errors include recovery hints

---

## References

### Implementation Examples
- `.claude/agents/research-coordinator.md` - Planning-only mode with all 5 patterns
- `.claude/agents/implementer-coordinator.md` - Supervisor mode with wave-based execution
- `.claude/agents/testing-coordinator.md` - Parallel test execution pattern
- `.claude/agents/debug-coordinator.md` - Multi-vector investigation pattern
- `.claude/agents/repair-coordinator.md` - Error dimension analysis pattern

### Related Standards
- [Coordinator Return Signals](coordinator-return-signals.md) - Signal contract specifications
- [Artifact Metadata Standard](artifact-metadata-standard.md) - YAML frontmatter schema
- [Brief Summary Format](brief-summary-format.md) - 96% context reduction format
- [Three-Tier Coordination Pattern](../../concepts/three-tier-coordination-pattern.md) - Tier responsibilities

### Testing Standards
- `.claude/tests/integration/test_lean_plan_coordinator.sh` - 21 tests (100% pass)
- `.claude/tests/integration/test_lean_implement_coordinator.sh` - 27 tests (100% pass)
- Pattern compliance validation (all 5 patterns tested)

### Decision Framework
- [Choosing Agent Architecture](../../guides/architecture/choosing-agent-architecture.md) - When to use coordinators
- [Hierarchical Agents Overview](../../concepts/hierarchical-agents-overview.md) - Architecture fundamentals
