# Phase 2: Coordinator Expansion - Detailed Implementation

## Overview

This phase extends the three-tier agent pattern (orchestrator → coordinator → specialist) from research workflows to testing, debug, and repair workflows. Currently, `/test`, `/debug`, and `/repair` commands use two-tier architecture (orchestrator → specialist) without the coordinator intermediary that provides parallel orchestration and metadata-only passing.

**Objective**: Implement testing-coordinator, debug-coordinator, and repair-coordinator to achieve 40-60% time savings through parallelization and 95% context reduction through metadata aggregation.

**Dependencies**: Phase 1 (coordinator template and three-tier pattern guide must exist)

**Estimated Duration**: 10-15 hours (revised from 12-18 hours)

**Revision Notes**:
- **Hard Barrier Pattern Reuse**: Spec 016 (lean-implement Phase 3) provides validated hard barrier implementation - reuse pattern instead of reimplementing
- **Research Coordination**: Spec 013 Phases 10-11 propose research-coordinator integration for /repair and /debug commands
- **Dual Coordinator Pattern**: Commands should support BOTH coordinators in sequence:
  1. **Research Phase**: Use research-coordinator for multi-topic research (error pattern analysis, root cause investigation)
  2. **Execution Phase**: Use domain-specific coordinator for parallel execution (testing, debugging, repair)
- **Example Flow** (/repair):
  ```
  /repair command
    ├─> Block 1: Research Phase (via research-coordinator)
    │   └─> Multi-topic error pattern analysis (Spec 013 Phase 10)
    ├─> Block 2: Planning Phase (via plan-architect)
    │   └─> Create repair plan based on research findings
    └─> Block 3: Execution Phase (via repair-coordinator)
        └─> Parallel error dimension analysis and fix implementation
  ```
- **Example Flow** (/debug):
  ```
  /debug command
    ├─> Block 1: Research Phase (via research-coordinator)
    │   └─> Multi-topic root cause analysis (Spec 013 Phase 11)
    └─> Block 2: Investigation Phase (via debug-coordinator)
        └─> Parallel investigation vectors (logs, code, dependencies, environment)
  ```

## Success Criteria

- [ ] Testing-coordinator implemented with parallel test category execution
- [ ] Testing-coordinator integrated with `/test` command
- [ ] Debug-coordinator implemented with parallel investigation vector execution
- [ ] Debug-coordinator integrated with `/debug` command
- [ ] Repair-coordinator implemented with parallel error dimension analysis
- [ ] Repair-coordinator integrated with `/repair` command
- [ ] All coordinators follow hard barrier pattern (path pre-calculation, artifact validation, metadata-only return)
- [ ] All coordinators support both automated and manual pre-decomposition modes
- [ ] Integration tests pass for all three coordinators
- [ ] Command documentation updated to reflect three-tier architecture

## Stage 1: Testing-Coordinator Implementation

### Objective
Create testing-coordinator agent that orchestrates parallel test execution across multiple test categories (unit, integration, e2e) and returns aggregated test results metadata.

### Revision Notes
- **Reuse Hard Barrier Pattern**: Reference Spec 016 (lean-implement Phase 3) for validated hard barrier implementation
  - Path pre-calculation utility: `create_topic_artifact()` from unified-location-detection.sh
  - Artifact validation pattern: Fail-fast on missing files with detailed error reporting
  - Delegation bypass detection: Verify specialist created artifact at expected path (not bypassed orchestrator)
- **No Research Phase**: Testing workflows do NOT require research-coordinator integration (purely execution-focused)

### Input Contract

The testing-coordinator receives from `/test` command:

```yaml
test_request: "Run all tests with coverage analysis"
test_categories: ["unit", "integration", "e2e"]  # Optional - if omitted, coordinator auto-detects
test_results_dir: /home/user/.config/.claude/specs/NNN_topic/test_results/
topic_path: /home/user/.config/.claude/specs/NNN_topic
max_parallel: 3  # Default: 3 (respects system limits)
coverage_threshold: 80  # Optional - minimum coverage percentage
context:
  plan_file: /path/to/plan.md
  test_file_patterns: ["**/*_test.lua", "test_*.sh"]
```

### Coordinator Structure

File: `.claude/agents/testing-coordinator.md`

**Frontmatter**:
```yaml
---
allowed-tools: Task, Read, Bash, Grep, Glob
description: Supervisor agent coordinating parallel test-executor invocations for multi-category test orchestration
model: sonnet-4.5
model-justification: Coordinator role managing parallel test delegation, coverage aggregation, and hard barrier validation
fallback-model: sonnet-4.5
dependent-agents: test-executor
---
```

**Core Responsibilities**:
1. **Category Decomposition**: Parse test request into test categories (unit, integration, e2e) or use provided categories
2. **Path Pre-Calculation**: Calculate test result paths for each category BEFORE agent invocation (hard barrier pattern)
3. **Parallel Test Delegation**: Invoke test-executor for each category via Task tool
4. **Artifact Validation**: Verify all test result files exist at pre-calculated paths (fail-fast on missing results)
5. **Metadata Extraction**: Extract pass/fail counts, coverage percentages, execution time from each result file
6. **Metadata Aggregation**: Return aggregated metadata to `/test` command (95% context reduction)

### Implementation Steps

#### Step 1: Create Testing-Coordinator Agent

1. **Base Structure**: Use coordinator template from Phase 1 as starting point
   - Copy `.claude/agents/templates/coordinator-template.md` to `.claude/agents/testing-coordinator.md`
   - Replace template variables:
     - `{{COORDINATOR_TYPE}}` → "Testing Coordinator"
     - `{{SPECIALIST_TYPE}}` → "test-executor"
     - `{{ARTIFACT_TYPE}}` → "test result"
     - `{{METADATA_FIELDS}}` → "pass_count, fail_count, coverage_percentage, execution_time"

2. **Define Input Validation**:
```bash
# Validate required inputs
if [ -z "${TEST_RESULTS_DIR:-}" ]; then
  echo "ERROR: TEST_RESULTS_DIR is required" >&2
  exit 1
fi

if [ -z "${TOPIC_PATH:-}" ]; then
  echo "ERROR: TOPIC_PATH is required" >&2
  exit 1
fi

# Set defaults
MAX_PARALLEL="${MAX_PARALLEL:-3}"
COVERAGE_THRESHOLD="${COVERAGE_THRESHOLD:-0}"
```

3. **Implement Two-Mode Support**:

**Mode 1: Automated Category Detection** (test_categories NOT provided):
```bash
# Auto-detect test categories from test file patterns
detect_test_categories() {
  local topic_path="$1"
  local categories=()

  # Check for unit tests
  if find "$topic_path" -name "*_test.lua" -o -name "test_*.sh" | grep -q .; then
    categories+=("unit")
  fi

  # Check for integration tests
  if find "$topic_path" -name "*_integration_test.*" | grep -q .; then
    categories+=("integration")
  fi

  # Check for e2e tests
  if find "$topic_path" -name "*_e2e_test.*" -o -name "*_e2e.sh" | grep -q .; then
    categories+=("e2e")
  fi

  # Default to "unit" if no tests found
  if [ ${#categories[@]} -eq 0 ]; then
    categories=("unit")
  fi

  echo "${categories[@]}"
}

# Mode detection
if [ -n "${TEST_CATEGORIES:-}" ] && [ ${#TEST_CATEGORIES[@]} -gt 0 ]; then
  MODE="pre_decomposed"
  echo "Mode: Manual Pre-Decomposition (${#TEST_CATEGORIES[@]} categories provided)"
else
  MODE="automated"
  TEST_CATEGORIES=($(detect_test_categories "$TOPIC_PATH"))
  echo "Mode: Automated Detection (${#TEST_CATEGORIES[@]} categories detected)"
fi
```

**Mode 2: Manual Pre-Decomposition** (test_categories provided):
```bash
# Use provided test categories directly
TEST_CATEGORIES=("${TEST_CATEGORIES_ARRAY[@]}")
echo "Using pre-specified test categories: ${TEST_CATEGORIES[*]}"
```

4. **Implement Path Pre-Calculation** (Hard Barrier Pattern):
```bash
# Pre-calculate test result paths for each category
TEST_RESULT_PATHS=()
for category in "${TEST_CATEGORIES[@]}"; do
  result_file="${TEST_RESULTS_DIR}/test_results_${category}.json"
  TEST_RESULT_PATHS+=("$result_file")
done

# Display path pre-calculation
echo "╔═══════════════════════════════════════════════════════╗"
echo "║ TESTING COORDINATOR - PATH PRE-CALCULATION           ║"
echo "╠═══════════════════════════════════════════════════════╣"
echo "║ Categories: ${#TEST_CATEGORIES[@]}                                            ║"
echo "║ Results Directory: ${TEST_RESULTS_DIR}               ║"
echo "╠═══════════════════════════════════════════════════════╣"
echo "║ Pre-Calculated Result Paths:                          ║"
for i in "${!TEST_RESULT_PATHS[@]}"; do
  echo "║ ├─ $(basename "${TEST_RESULT_PATHS[$i]}")            ║"
done
echo "╚═══════════════════════════════════════════════════════╝"
```

5. **Implement Parallel Test-Executor Invocation**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the test-executor.

Task {
  subagent_type: "general-purpose"
  description: "Execute unit tests with coverage analysis"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/test-executor.md

    You are acting as a Test Executor Agent with the tools and constraints
    defined in that file.

    **CRITICAL - Hard Barrier Pattern**:
    TEST_RESULT_PATH="${TEST_RESULT_PATHS[0]}"

    **Test Category**: unit
    **Test Patterns**: ${TEST_FILE_PATTERNS[@]}
    **Coverage Threshold**: ${COVERAGE_THRESHOLD}

    **Context**:
    ${CONTEXT}

    Follow all steps in test-executor.md:
    1. STEP 1: Verify absolute result path received
    2. STEP 2: Discover test files matching patterns
    3. STEP 3: Execute tests and collect results
    4. STEP 4: Generate coverage report
    5. STEP 5: Write result JSON to TEST_RESULT_PATH
    6. STEP 6: Return: TEST_COMPLETE: [path]
}

# Repeat for integration and e2e categories...
```

6. **Implement Hard Barrier Validation**:
```bash
# Validate all test result files exist
MISSING_RESULTS=()
for result_path in "${TEST_RESULT_PATHS[@]}"; do
  if [ ! -f "$result_path" ]; then
    MISSING_RESULTS+=("$result_path")
    echo "ERROR: Test result not found: $result_path" >&2
  elif [ $(wc -c < "$result_path") -lt 50 ]; then
    echo "WARNING: Test result is too small: $result_path ($(wc -c < "$result_path") bytes)" >&2
  fi
done

# Fail-fast if any results missing
if [ ${#MISSING_RESULTS[@]} -gt 0 ]; then
  echo "CRITICAL ERROR: ${#MISSING_RESULTS[@]} test results missing" >&2
  echo "Missing results: ${MISSING_RESULTS[*]}" >&2
  exit 1
fi

echo "✓ VERIFIED: All ${#TEST_RESULT_PATHS[@]} test results created successfully"
```

7. **Implement Metadata Extraction**:
```bash
# Extract metadata from test result JSON files
extract_test_metadata() {
  local result_path="$1"
  local pass_count=$(jq -r '.pass_count // 0' "$result_path" 2>/dev/null || echo 0)
  local fail_count=$(jq -r '.fail_count // 0' "$result_path" 2>/dev/null || echo 0)
  local coverage=$(jq -r '.coverage_percentage // 0' "$result_path" 2>/dev/null || echo 0)
  local exec_time=$(jq -r '.execution_time_seconds // 0' "$result_path" 2>/dev/null || echo 0)

  echo "{\"path\": \"$result_path\", \"pass_count\": $pass_count, \"fail_count\": $fail_count, \"coverage_percentage\": $coverage, \"execution_time\": $exec_time}"
}

# Build metadata array
METADATA=()
for result_path in "${TEST_RESULT_PATHS[@]}"; do
  metadata=$(extract_test_metadata "$result_path")
  METADATA+=("$metadata")
done
```

8. **Implement Metadata Return Format**:
```bash
# Return aggregated metadata
TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_TIME=0
for metadata in "${METADATA[@]}"; do
  TOTAL_PASS=$((TOTAL_PASS + $(echo "$metadata" | jq -r '.pass_count')))
  TOTAL_FAIL=$((TOTAL_FAIL + $(echo "$metadata" | jq -r '.fail_count')))
  TOTAL_TIME=$(echo "$TOTAL_TIME + $(echo "$metadata" | jq -r '.execution_time')" | bc)
done

cat <<EOF
TESTING_COMPLETE: ${#TEST_CATEGORIES[@]}
results: [$(IFS=,; echo "${METADATA[*]}")]
total_pass: $TOTAL_PASS
total_fail: $TOTAL_FAIL
total_execution_time: $TOTAL_TIME
overall_status: $([ $TOTAL_FAIL -eq 0 ] && echo "PASS" || echo "FAIL")
EOF
```

9. **Implement Error Return Protocol**:
```bash
# Error types: validation_error, agent_error, file_error, execution_error
# Example validation error:
ERROR_CONTEXT: {
  "error_type": "validation_error",
  "message": "2 test result files missing after test execution",
  "details": {"missing_results": ["test_results_integration.json", "test_results_e2e.json"]}
}

TASK_ERROR: validation_error - 2 test results missing (hard barrier failure)
```

10. **Implement Partial Success Mode**:
```bash
# If ≥50% of test categories completed, return partial results with warning
if [ ${#MISSING_RESULTS[@]} -gt 0 ] && [ ${#MISSING_RESULTS[@]} -lt $((${#TEST_CATEGORIES[@]} / 2)) ]; then
  echo "WARNING: Partial test execution (${#MISSING_RESULTS[@]} categories failed)" >&2
  # Extract metadata from successful results only
  # Return metadata with partial_success flag
fi
```

#### Step 2: Integrate Testing-Coordinator with /test Command

1. **Update `/test` command to invoke testing-coordinator**:

File: `.claude/commands/test.md`

**Current Pattern** (two-tier):
```bash
# Direct test-executor invocation
**EXECUTE NOW**: USE the Task tool to invoke the test-executor.
Task {
  description: "Execute all tests"
  # ... test-executor prompt
}
```

**New Pattern** (three-tier via coordinator):
```bash
# Invoke testing-coordinator for parallel execution
**EXECUTE NOW**: USE the Task tool to invoke the testing-coordinator.
Task {
  subagent_type: "general-purpose"
  description: "Coordinate parallel test execution across categories"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/testing-coordinator.md

    You are acting as a Testing Coordinator Agent with the tools and constraints
    defined in that file.

    **Test Request**: Run all tests with coverage analysis
    **Test Results Directory**: ${TEST_RESULTS_DIR}
    **Topic Path**: ${TOPIC_PATH}
    **Coverage Threshold**: ${COVERAGE_THRESHOLD}

    Context:
      plan_file: ${PLAN_FILE}
      test_file_patterns: ${TEST_FILE_PATTERNS[@]}

    Execute testing coordination workflow and return aggregated metadata.
}
```

2. **Update command to parse coordinator metadata return**:
```bash
# Parse testing-coordinator return signal
parse_testing_coordinator_output() {
  local output="$1"

  # Extract TESTING_COMPLETE signal
  if echo "$output" | grep -q "^TESTING_COMPLETE:"; then
    CATEGORY_COUNT=$(echo "$output" | grep "^TESTING_COMPLETE:" | cut -d: -f2 | xargs)
    TOTAL_PASS=$(echo "$output" | grep "^total_pass:" | cut -d: -f2 | xargs)
    TOTAL_FAIL=$(echo "$output" | grep "^total_fail:" | cut -d: -f2 | xargs)
    OVERALL_STATUS=$(echo "$output" | grep "^overall_status:" | cut -d: -f2 | xargs)

    echo "Test execution complete: $CATEGORY_COUNT categories, $TOTAL_PASS passed, $TOTAL_FAIL failed"

    if [ "$OVERALL_STATUS" = "FAIL" ]; then
      return 1
    fi
  else
    echo "ERROR: Invalid testing-coordinator output" >&2
    return 1
  fi
}
```

3. **Update error handling to use `parse_subagent_error()`**:
```bash
# Source error handling library
source "${CLAUDE_LIB}/core/error-handling.sh" 2>/dev/null || {
  echo "Error: Cannot load error-handling library"
  exit 1
}

# Parse coordinator errors
if echo "$coordinator_output" | grep -q "^TASK_ERROR:"; then
  parse_subagent_error "$coordinator_output" "testing-coordinator"
  log_command_error "agent_error" "Testing coordinator failed" "$coordinator_output"
  exit 1
fi
```

4. **Update command documentation**:
```markdown
## Architecture

This command uses a **three-tier architecture** for parallel test execution:

1. **Orchestrator Layer** (`/test` command): Argument capture, state management, checkpoint handling
2. **Coordinator Layer** (`testing-coordinator`): Parallel test category orchestration, metadata aggregation
3. **Specialist Layer** (`test-executor`): Deep test execution, coverage analysis, result reporting

Benefits:
- **40-60% time savings** via parallel category execution
- **95% context reduction** via metadata-only passing (JSON metadata vs full test output)
- **Scalable** to additional test categories without command changes
```

### Testing Strategy for Stage 1

```bash
# Test 1: Automated category detection mode
echo "Testing testing-coordinator with automated category detection..."
# Manual Task invocation with no test_categories provided
# Verify coordinator auto-detects categories from test file patterns

# Test 2: Manual pre-decomposition mode
echo "Testing testing-coordinator with pre-specified categories..."
# Manual Task invocation with test_categories=["unit", "integration"]
# Verify coordinator uses provided categories

# Test 3: Hard barrier validation
echo "Testing hard barrier validation (simulate missing result)..."
# Delete one test result file after test-executor completes
# Verify coordinator fails-fast with validation_error

# Test 4: Metadata extraction
echo "Testing metadata extraction from result JSON..."
# Verify pass/fail counts, coverage percentages extracted correctly

# Test 5: Command integration
echo "Testing /test command integration..."
grep -q "testing-coordinator" .claude/commands/test.md
# Run /test command end-to-end and verify parallel execution

# Test 6: Partial success mode
echo "Testing partial success mode (≥50% threshold)..."
# Simulate 1 of 3 categories failing
# Verify coordinator returns partial results with warning
```

---

## Stage 2: Debug-Coordinator Implementation

### Objective
Create debug-coordinator agent that orchestrates parallel investigation across multiple debug vectors (logs, code, dependencies, environment) and returns aggregated debug findings metadata.

### Revision Notes
- **Reuse Hard Barrier Pattern**: Reference Spec 016 for validated hard barrier implementation (same as testing-coordinator)
- **Research Coordination**: Coordinate with research-coordinator for multi-topic root cause analysis (Spec 013 Phase 11)
  - **Research Phase** (Block 1): Use research-coordinator when issue description suggests multiple topics (e.g., "timeout affecting auth and session modules")
  - **Investigation Phase** (Block 2): Use debug-coordinator for parallel investigation vectors AFTER research phase completes
  - **Dual Coordinator Flow**: research-coordinator (multi-topic research) → debug-coordinator (parallel investigation)
- **When to Use Research-Coordinator**:
  - Issue involves multiple system components/modules
  - Root cause analysis requires cross-domain research
  - Problem space is poorly understood (exploratory investigation)
- **When to Skip Research Phase**:
  - Issue is narrowly scoped (single component)
  - Root cause is suspected (confirmation investigation only)
  - Debug vectors are pre-specified by user

### Input Contract

The debug-coordinator receives from `/debug` command:

```yaml
debug_request: "Investigate authentication timeout issue"
investigation_vectors: ["logs", "code", "dependencies", "environment"]  # Optional - if omitted, coordinator auto-detects
debug_reports_dir: /home/user/.config/.claude/specs/NNN_topic/debug/
topic_path: /home/user/.config/.claude/specs/NNN_topic
issue_description: "Users experiencing timeout during login after 30 seconds"
context:
  error_log_path: /var/log/app.log
  affected_components: ["auth", "session"]
  recent_changes: "Updated JWT library to v2.0"
```

### Coordinator Structure

File: `.claude/agents/debug-coordinator.md`

**Frontmatter**:
```yaml
---
allowed-tools: Task, Read, Bash, Grep, Glob
description: Supervisor agent coordinating parallel debug-analyst invocations for multi-vector investigation orchestration
model: sonnet-4.5
model-justification: Coordinator role managing parallel debug delegation, finding aggregation, and hard barrier validation
fallback-model: sonnet-4.5
dependent-agents: debug-analyst
---
```

**Core Responsibilities**:
1. **Vector Decomposition**: Parse debug request into investigation vectors (logs, code, dependencies, environment) or use provided vectors
2. **Path Pre-Calculation**: Calculate debug report paths for each vector BEFORE agent invocation (hard barrier pattern)
3. **Parallel Debug Delegation**: Invoke debug-analyst for each vector via Task tool
4. **Artifact Validation**: Verify all debug reports exist at pre-calculated paths (fail-fast on missing reports)
5. **Metadata Extraction**: Extract findings count, root cause candidates, confidence scores from each report
6. **Metadata Aggregation**: Return aggregated metadata to `/debug` command (95% context reduction)

### Implementation Steps

#### Step 1: Create Debug-Coordinator Agent

1. **Base Structure**: Use coordinator template from Phase 1
   - Replace `{{COORDINATOR_TYPE}}` → "Debug Coordinator"
   - Replace `{{SPECIALIST_TYPE}}` → "debug-analyst"
   - Replace `{{ARTIFACT_TYPE}}` → "debug report"
   - Replace `{{METADATA_FIELDS}}` → "findings_count, root_cause_candidates, confidence_score"

2. **Implement Vector Detection** (Mode 1 - Automated):
```bash
detect_investigation_vectors() {
  local issue_description="$1"
  local vectors=()

  # Always investigate logs
  vectors+=("logs")

  # Check if code analysis relevant (keywords: "error", "crash", "exception")
  if echo "$issue_description" | grep -qiE "(error|crash|exception|bug)"; then
    vectors+=("code")
  fi

  # Check if dependency analysis relevant (keywords: "library", "package", "version")
  if echo "$issue_description" | grep -qiE "(library|package|version|dependency|upgrade)"; then
    vectors+=("dependencies")
  fi

  # Check if environment analysis relevant (keywords: "config", "environment", "deployment")
  if echo "$issue_description" | grep -qiE "(config|environment|deployment|server|host)"; then
    vectors+=("environment")
  fi

  # Default to logs + code if no vectors detected
  if [ ${#vectors[@]} -eq 1 ]; then
    vectors+=("code")
  fi

  echo "${vectors[@]}"
}

# Mode detection
if [ -n "${INVESTIGATION_VECTORS:-}" ] && [ ${#INVESTIGATION_VECTORS[@]} -gt 0 ]; then
  MODE="pre_decomposed"
else
  MODE="automated"
  INVESTIGATION_VECTORS=($(detect_investigation_vectors "$ISSUE_DESCRIPTION"))
fi
```

3. **Implement Path Pre-Calculation**:
```bash
DEBUG_REPORT_PATHS=()
for vector in "${INVESTIGATION_VECTORS[@]}"; do
  report_file="${DEBUG_REPORTS_DIR}/debug_${vector}_$(date +%Y%m%d_%H%M%S).md"
  DEBUG_REPORT_PATHS+=("$report_file")
done
```

4. **Implement Parallel Debug-Analyst Invocation**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the debug-analyst.

Task {
  subagent_type: "general-purpose"
  description: "Investigate logs for authentication timeout issue"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/debug-analyst.md

    **CRITICAL - Hard Barrier Pattern**:
    DEBUG_REPORT_PATH="${DEBUG_REPORT_PATHS[0]}"

    **Investigation Vector**: logs
    **Issue Description**: ${ISSUE_DESCRIPTION}
    **Log Path**: ${ERROR_LOG_PATH}

    **Investigation Focus**:
    - Search for timeout errors in logs
    - Identify error patterns around authentication
    - Analyze timestamps for timeout correlation
    - Extract relevant log snippets

    Context: ${CONTEXT}

    Return: DEBUG_COMPLETE: [path]
}

# Repeat for code, dependencies, environment vectors...
```

5. **Implement Metadata Extraction**:
```bash
extract_debug_metadata() {
  local report_path="$1"

  # Extract findings count
  local findings_count=$(grep -c "^### Finding" "$report_path" 2>/dev/null || echo 0)

  # Extract root cause candidates (## Root Cause Candidates section)
  local root_causes=$(awk '/^## Root Cause Candidates/,/^## / {
    if (/^- /) count++
  } END {print count}' "$report_path" 2>/dev/null || echo 0)

  # Extract confidence score (from metadata if present)
  local confidence=$(grep "^- \*\*Confidence\*\*:" "$report_path" | sed 's/.*: //' | sed 's/%//' || echo 0)

  echo "{\"path\": \"$report_path\", \"findings_count\": $findings_count, \"root_cause_candidates\": $root_causes, \"confidence_score\": $confidence}"
}
```

6. **Implement Metadata Return Format**:
```bash
cat <<EOF
DEBUG_COMPLETE: ${#INVESTIGATION_VECTORS[@]}
reports: [$(IFS=,; echo "${METADATA[*]}")]
total_findings: $TOTAL_FINDINGS
total_root_causes: $TOTAL_ROOT_CAUSES
highest_confidence_vector: $HIGHEST_CONFIDENCE_VECTOR
recommended_next_steps: $RECOMMENDED_NEXT_STEPS
EOF
```

#### Step 2: Integrate Debug-Coordinator with /debug Command

1. **Update `/debug` command invocation pattern** (similar to testing-coordinator integration)
2. **Parse coordinator metadata return** (findings, root causes, confidence scores)
3. **Update error handling** with `parse_subagent_error()`
4. **Update command documentation** to reflect three-tier architecture

### Testing Strategy for Stage 2

```bash
# Test 1: Automated vector detection
# Test 2: Manual pre-decomposition mode
# Test 3: Hard barrier validation
# Test 4: Metadata extraction (findings, root causes, confidence)
# Test 5: Command integration
# Test 6: Partial success mode
```

---

## Stage 3: Repair-Coordinator Implementation

### Objective
Create repair-coordinator agent that orchestrates parallel error analysis across multiple error dimensions (type, timeframe, command, severity) and returns aggregated repair recommendations metadata.

### Revision Notes
- **Reuse Hard Barrier Pattern**: Reference Spec 016 for validated hard barrier implementation (same as testing-coordinator and debug-coordinator)
- **Research Coordination**: Coordinate with research-coordinator for multi-topic error pattern research (Spec 013 Phase 10)
  - **Research Phase** (Block 1): Use research-coordinator when error patterns span multiple topics (e.g., "state_error across /implement, /test, /debug commands")
  - **Planning Phase** (Block 2): Use plan-architect to create repair plan based on research findings
  - **Execution Phase** (Block 3): Use repair-coordinator for parallel error dimension analysis and fix implementation
  - **Triple Coordinator Flow**: research-coordinator (multi-topic research) → plan-architect (repair plan) → repair-coordinator (parallel execution)
- **When to Use Research-Coordinator**:
  - Errors span multiple commands/workflows/topics
  - Error patterns require cross-domain analysis (e.g., "validation_error in commands, agents, and skills")
  - Root cause is unclear and requires research across multiple error dimensions
- **When to Skip Research Phase**:
  - Errors are narrowly scoped (single command or single error type)
  - Error patterns are well-understood (e.g., known bug in specific library)
  - User provides explicit error dimension decomposition (pre-decomposed mode)

### Input Contract

The repair-coordinator receives from `/repair` command:

```yaml
repair_request: "Analyze and fix recent implementation errors"
error_dimensions: ["type", "timeframe", "command", "severity"]  # Optional - if omitted, coordinator auto-detects
repair_reports_dir: /home/user/.config/.claude/specs/NNN_topic/reports/
topic_path: /home/user/.config/.claude/specs/NNN_topic
error_log_query: "--since 24h --type state_error,validation_error"
context:
  command_context: "/implement"
  complexity: 2
```

### Coordinator Structure

File: `.claude/agents/repair-coordinator.md`

**Frontmatter**:
```yaml
---
allowed-tools: Task, Read, Bash, Grep
description: Supervisor agent coordinating parallel repair-analyst invocations for multi-dimension error analysis orchestration
model: sonnet-4.5
model-justification: Coordinator role managing parallel repair delegation, pattern aggregation, and hard barrier validation
fallback-model: sonnet-4.5
dependent-agents: repair-analyst
---
```

**Core Responsibilities**:
1. **Dimension Decomposition**: Parse repair request into error dimensions (type, timeframe, command, severity) or use provided dimensions
2. **Path Pre-Calculation**: Calculate repair report paths for each dimension BEFORE agent invocation (hard barrier pattern)
3. **Parallel Repair Delegation**: Invoke repair-analyst for each dimension via Task tool
4. **Artifact Validation**: Verify all repair reports exist at pre-calculated paths (fail-fast on missing reports)
5. **Metadata Extraction**: Extract error patterns, fix recommendations, affected components from each report
6. **Metadata Aggregation**: Return aggregated metadata to `/repair` command (95% context reduction)

### Implementation Steps

#### Step 1: Create Repair-Coordinator Agent

1. **Base Structure**: Use coordinator template from Phase 1
   - Replace `{{COORDINATOR_TYPE}}` → "Repair Coordinator"
   - Replace `{{SPECIALIST_TYPE}}` → "repair-analyst"
   - Replace `{{ARTIFACT_TYPE}}` → "repair report"
   - Replace `{{METADATA_FIELDS}}` → "error_patterns_count, fix_recommendations_count, affected_components"

2. **Implement Dimension Detection** (Mode 1 - Automated):
```bash
detect_error_dimensions() {
  local error_log_query="$1"
  local dimensions=()

  # Always analyze by error type
  dimensions+=("type")

  # Check if timeframe analysis relevant (--since flag present)
  if echo "$error_log_query" | grep -q "\-\-since"; then
    dimensions+=("timeframe")
  fi

  # Check if command analysis relevant (--command flag present)
  if echo "$error_log_query" | grep -q "\-\-command"; then
    dimensions+=("command")
  fi

  # Check if severity analysis relevant (multiple error types)
  if echo "$error_log_query" | grep -qE "(state_error.*validation_error|validation_error.*agent_error)"; then
    dimensions+=("severity")
  fi

  # Default to type + timeframe if minimal query
  if [ ${#dimensions[@]} -eq 1 ]; then
    dimensions+=("timeframe")
  fi

  echo "${dimensions[@]}"
}
```

3. **Implement Path Pre-Calculation**:
```bash
REPAIR_REPORT_PATHS=()
for dimension in "${ERROR_DIMENSIONS[@]}"; do
  report_file="${REPAIR_REPORTS_DIR}/repair_${dimension}_$(date +%Y%m%d_%H%M%S).md"
  REPAIR_REPORT_PATHS+=("$report_file")
done
```

4. **Implement Parallel Repair-Analyst Invocation**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the repair-analyst.

Task {
  subagent_type: "general-purpose"
  description: "Analyze errors by type dimension"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/repair-analyst.md

    **CRITICAL - Hard Barrier Pattern**:
    REPAIR_REPORT_PATH="${REPAIR_REPORT_PATHS[0]}"

    **Analysis Dimension**: type
    **Error Log Query**: ${ERROR_LOG_QUERY}

    **Analysis Focus**:
    - Group errors by error type (state_error, validation_error, etc.)
    - Identify common error patterns within each type
    - Recommend fixes per error type
    - Estimate impact and priority

    Context: ${CONTEXT}

    Return: REPAIR_COMPLETE: [path]
}

# Repeat for timeframe, command, severity dimensions...
```

5. **Implement Metadata Extraction**:
```bash
extract_repair_metadata() {
  local report_path="$1"

  # Extract error patterns count (## Error Patterns section)
  local patterns_count=$(awk '/^## Error Patterns/,/^## / {
    if (/^### Pattern/) count++
  } END {print count}' "$report_path" 2>/dev/null || echo 0)

  # Extract fix recommendations count (## Fix Recommendations section)
  local recommendations_count=$(awk '/^## Fix Recommendations/,/^## / {
    if (/^- \[ \]/) count++
  } END {print count}' "$report_path" 2>/dev/null || echo 0)

  # Extract affected components (comma-separated list)
  local components=$(grep "^- \*\*Affected Components\*\*:" "$report_path" | sed 's/.*: //' || echo "unknown")

  echo "{\"path\": \"$report_path\", \"error_patterns_count\": $patterns_count, \"fix_recommendations_count\": $recommendations_count, \"affected_components\": \"$components\"}"
}
```

6. **Implement Metadata Return Format**:
```bash
cat <<EOF
REPAIR_COMPLETE: ${#ERROR_DIMENSIONS[@]}
reports: [$(IFS=,; echo "${METADATA[*]}")]
total_error_patterns: $TOTAL_PATTERNS
total_fix_recommendations: $TOTAL_RECOMMENDATIONS
high_priority_fixes: $HIGH_PRIORITY_COUNT
affected_components: $ALL_COMPONENTS
EOF
```

#### Step 2: Integrate Repair-Coordinator with /repair Command

1. **Update `/repair` command invocation pattern** (similar to testing and debug coordinators)
2. **Parse coordinator metadata return** (error patterns, fix recommendations, components)
3. **Update error handling** with `parse_subagent_error()`
4. **Update command documentation** to reflect three-tier architecture

### Testing Strategy for Stage 3

```bash
# Test 1: Automated dimension detection from error log query
# Test 2: Manual pre-decomposition mode with specified dimensions
# Test 3: Hard barrier validation (missing repair reports)
# Test 4: Metadata extraction (patterns, recommendations, components)
# Test 5: Command integration with /repair
# Test 6: Partial success mode (≥50% dimensions analyzed)
```

---

## Integration Testing

### End-to-End Workflow Tests

**Test 1: Testing-Coordinator E2E**:
```bash
# Setup: Create test files in topic directory
# Execute: Run /test command with coverage threshold
# Verify: Parallel execution logs show 3 categories running simultaneously
# Verify: Metadata returned contains pass/fail counts and coverage
# Verify: Test result JSON files exist at pre-calculated paths
# Verify: Command completes in 40-60% less time vs sequential
```

**Test 2: Debug-Coordinator E2E**:
```bash
# Setup: Create mock error logs and affected code
# Execute: Run /debug command with issue description
# Verify: Parallel investigation logs show 4 vectors running simultaneously
# Verify: Metadata returned contains findings and root causes
# Verify: Debug report files exist at pre-calculated paths
# Verify: Highest confidence vector identified correctly
```

**Test 3: Repair-Coordinator E2E**:
```bash
# Setup: Populate errors.jsonl with sample errors
# Execute: Run /repair command with error log query
# Verify: Parallel analysis logs show N dimensions running simultaneously
# Verify: Metadata returned contains error patterns and fix recommendations
# Verify: Repair report files exist at pre-calculated paths
# Verify: High-priority fixes identified correctly
```

### Hard Barrier Pattern Validation

```bash
# Test hard barrier enforcement across all coordinators
validate_hard_barrier() {
  local coordinator="$1"

  # Test 1: Pre-calculation - verify paths calculated BEFORE agent invocation
  # Test 2: Validation - verify artifact existence checked AFTER agent returns
  # Test 3: Fail-fast - verify workflow aborts on missing artifacts
  # Test 4: Partial success - verify ≥50% threshold for graceful degradation
}

validate_hard_barrier "testing-coordinator"
validate_hard_barrier "debug-coordinator"
validate_hard_barrier "repair-coordinator"
```

### Metadata-Only Passing Validation

```bash
# Verify 95% context reduction across all coordinators
validate_metadata_efficiency() {
  local coordinator="$1"
  local full_artifact_size=$(wc -c < "$ARTIFACT_PATH")
  local metadata_size=$(echo "$METADATA_JSON" | wc -c)
  local reduction_pct=$(echo "scale=2; (1 - $metadata_size / $full_artifact_size) * 100" | bc)

  echo "Context reduction for $coordinator: ${reduction_pct}%"
  [ $(echo "$reduction_pct >= 90" | bc) -eq 1 ]
}
```

---

## Documentation Updates

### Command Documentation

1. **Update `.claude/commands/test.md`**:
   - Add "## Architecture" section describing three-tier pattern
   - Update "## Usage" examples to show coordinator invocation
   - Add performance notes (40-60% time savings, 95% context reduction)

2. **Update `.claude/commands/debug.md`**:
   - Add "## Architecture" section
   - Document investigation vectors and auto-detection
   - Update error handling section with coordinator error protocol

3. **Update `.claude/commands/repair.md`**:
   - Add "## Architecture" section
   - Document error dimensions and auto-detection
   - Update examples with coordinator invocation pattern

### Agent Documentation

1. **Create coordinator agent files**:
   - `.claude/agents/testing-coordinator.md` (635+ lines based on research-coordinator)
   - `.claude/agents/debug-coordinator.md` (635+ lines)
   - `.claude/agents/repair-coordinator.md` (635+ lines)

2. **Update agent index** (`.claude/agents/README.md`):
   - Add coordinator agents to catalog
   - Update coordinator count from 2 to 5 (research, implementer, testing, debug, repair)

### Cross-References

Update all documentation cross-references:
- Three-tier pattern guide ← testing-coordinator, debug-coordinator, repair-coordinator
- Command reference ← updated /test, /debug, /repair documentation
- Error handling guide ← coordinator error return protocol

---

## Performance Metrics

### Expected Time Savings

**Testing Workflows**:
- Sequential execution: 3 categories × 2 minutes = 6 minutes
- Parallel execution: max(2, 2, 2) = 2 minutes
- Time savings: 67% (4 minutes saved)

**Debug Workflows**:
- Sequential execution: 4 vectors × 3 minutes = 12 minutes
- Parallel execution: max(3, 3, 3, 3) = 3 minutes
- Time savings: 75% (9 minutes saved)

**Repair Workflows**:
- Sequential execution: 3 dimensions × 4 minutes = 12 minutes
- Parallel execution: max(4, 4, 4) = 4 minutes
- Time savings: 67% (8 minutes saved)

### Expected Context Reduction

**Metadata vs Full Content**:
- Test result JSON: 150 tokens metadata vs 800 tokens full = 81% reduction
- Debug report: 110 tokens metadata vs 2,500 tokens full = 95% reduction
- Repair report: 120 tokens metadata vs 2,000 tokens full = 94% reduction

**Aggregated Efficiency**:
- 3 test categories: 450 tokens vs 2,400 tokens = 81% reduction
- 4 debug vectors: 440 tokens vs 10,000 tokens = 95% reduction
- 3 repair dimensions: 360 tokens vs 6,000 tokens = 94% reduction

---

## Rollback Plan

If coordinator integration causes issues:

1. **Feature Flag Approach**:
```bash
# Add feature flag to commands
USE_COORDINATOR="${USE_COORDINATOR:-false}"

if [ "$USE_COORDINATOR" = "true" ]; then
  # Invoke coordinator (three-tier)
else
  # Invoke specialist directly (two-tier fallback)
fi
```

2. **Gradual Rollout**:
   - Phase 2.1: Deploy testing-coordinator only, monitor for issues
   - Phase 2.2: Deploy debug-coordinator if testing-coordinator stable
   - Phase 2.3: Deploy repair-coordinator if both stable

3. **Rollback Trigger Conditions**:
   - Hard barrier failures >10% of executions
   - Metadata parsing errors >5% of executions
   - Performance regression (parallel slower than sequential)

4. **Rollback Procedure**:
   - Set `USE_COORDINATOR=false` in all affected commands
   - Revert command documentation to two-tier architecture
   - Document rollback reason and coordinator issues in Phase 2 notes

---

## Dependencies

- Phase 1 complete (coordinator template and three-tier pattern guide available)
- Error handling library (`.claude/lib/core/error-handling.sh`) for error logging integration
- Unified location detection library (`.claude/lib/core/unified-location-detection.sh`) for path calculation
- Validation utilities (`.claude/lib/workflow/validation-utils.sh`) for artifact validation

---

## Completion Signal

When Phase 2 is complete, return:

```
PHASE_EXPANDED: Phase 2 - Coordinator Expansion

Coordinators Implemented: 3
- testing-coordinator (parallel test execution)
- debug-coordinator (parallel investigation)
- repair-coordinator (parallel error analysis)

Commands Updated: 3
- /test (three-tier architecture)
- /debug (three-tier architecture)
- /repair (three-tier architecture)

Expected Performance Impact:
- Time savings: 40-75% via parallelization
- Context reduction: 81-95% via metadata-only passing

Integration tests: PASSED
Hard barrier validation: PASSED
Metadata extraction: PASSED
```
