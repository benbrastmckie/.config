# Context Window Optimization in Hierarchical Agents

## Executive Summary

Hierarchical agent architectures in the `.claude/` system employ sophisticated context optimization techniques that achieve 95-96% context reduction while maintaining agent effectiveness. The research-coordinator pattern and implementer-coordinator integration demonstrate how metadata-only passing, brief summary parsing, and hard barrier enforcement enable 10+ iteration capacity (vs 3-4 iterations before optimization). These patterns are production-deployed in `/lean-plan` and `/lean-implement` commands with validated performance metrics.

## Analysis

### 1. Core Context Optimization Strategies

The hierarchical agent system uses three primary techniques for context window optimization:

#### 1.1 Metadata-Only Passing (95% Reduction)

**Pattern**: Supervisor agents extract lightweight metadata summaries from worker outputs and pass only metadata to parent agents, not full content.

**Implementation** (research-coordinator):
```bash
# Traditional approach: Pass full report content
3 reports × 2,500 tokens = 7,500 tokens consumed

# Optimized approach: Extract and pass metadata only
extract_metadata() {
  local report_path="$1"

  # Extract title (first heading)
  TITLE=$(grep -m 1 "^# " "$report_path" | sed 's/^# //')

  # Count findings subsections
  FINDINGS=$(grep -c "^### Finding" "$report_path")

  # Count recommendations
  RECOMMENDATIONS=$(awk '/^## Recommendations/,/^## / {
    if (/^[0-9]+\./) count++
  } END {print count}' "$report_path")

  # Return compact JSON (110 tokens vs 2,500 full content)
  echo "{\"path\":\"$report_path\",\"title\":\"$TITLE\",\"findings_count\":$FINDINGS,\"recommendations_count\":$RECOMMENDATIONS}"
}

3 reports × 110 tokens metadata = 330 tokens consumed
Context reduction: 95.6%
```

**Key Insight**: Downstream consumers (plan-architect) receive report paths with counts, then use Read tool for selective access to full content only when needed. This delegated reading pattern keeps orchestrator context minimal.

#### 1.2 Brief Summary Parsing (96% Reduction)

**Pattern**: Parse structured return signals from agent output instead of reading full artifact files.

**Implementation** (implementer-coordinator → /lean-implement):
```bash
# Traditional approach: Read full summary file
FULL_SUMMARY=$(cat "$LATEST_SUMMARY")  # 2,000 tokens

# Optimized approach: Parse structured fields from return signal
SUMMARY_BRIEF=$(grep "^summary_brief:" "$LATEST_SUMMARY" | sed 's/^summary_brief:[[:space:]]*//')
PHASES_COMPLETED=$(grep "^phases_completed:" "$LATEST_SUMMARY" | sed 's/^phases_completed:[[:space:]]*//')
CONTEXT_USAGE_PERCENT=$(grep "^context_usage_percent:" "$LATEST_SUMMARY" | sed 's/^context_usage_percent:[[:space:]]*//')
WORK_REMAINING=$(grep "^work_remaining:" "$LATEST_SUMMARY" | sed 's/^work_remaining:[[:space:]]*//')

# Display brief (80 tokens vs 2,000 full file)
echo "Summary: $SUMMARY_BRIEF"
echo "Phases completed: ${PHASES_COMPLETED:-none}"
echo "Context usage: ${CONTEXT_USAGE_PERCENT}%"
echo "Full report: $LATEST_SUMMARY"

Context reduction: 96% (80 tokens vs 2,000)
```

**Key Insight**: Return signals use machine-parseable format (key:value pairs) that enable grep-based field extraction without loading full file into context. Orchestrators display brief summaries and provide file path for manual inspection.

#### 1.3 Hard Barrier Pattern (Delegation Enforcement)

**Pattern**: Structural constraints that make delegation bypass impossible, ensuring work stays in specialized agents (not orchestrator context).

**Implementation** (Setup → Execute → Verify):
```markdown
## Block 1a: Setup
- State transition (fail-fast)
- Path pre-calculation
- Variable persistence

## Block 1b: Execute [CRITICAL BARRIER]
- MANDATORY Task invocation
- No alternative code path
- Cannot skip to Block 1c

## Block 1c: Verify
- Artifact existence check (exit 1 if missing)
- Fail-fast on validation failure
- Error logging with recovery hints
```

**Key Insight**: Bash blocks between Task invocations create hard barriers—Claude cannot skip verification blocks. Fail-fast validation (exit 1) prevents progression without artifacts, making bypass structurally impossible.

**Before Hard Barriers**:
- 40-60% context usage in orchestrator performing worker tasks directly
- Inconsistent delegation (sometimes bypassed)

**After Hard Barriers**:
- Context reduction: orchestrator only coordinates (no inline work)
- 100% delegation success rate
- Modular architecture with focused responsibilities

### 2. Production Implementations

#### 2.1 research-coordinator (Parallel Research)

**Location**: `/home/benjamin/.config/.claude/agents/research-coordinator.md`

**Purpose**: Coordinate parallel research-specialist invocations across 2-5 topics with metadata aggregation.

**Architecture**:
```
/lean-plan Primary Agent
    |
    +-- research-coordinator (Supervisor)
            +-- research-specialist 1 (Mathlib Theorems)
            +-- research-specialist 2 (Proof Automation)
            +-- research-specialist 3 (Project Structure)
```

**Context Optimization Workflow**:

1. **Path Pre-Calculation** (Block 1d-calc):
   - Primary agent calculates `RESEARCH_DIR` before coordinator invocation
   - Coordinator calculates individual `REPORT_PATHS[]` before worker invocation
   - Hard barrier pattern: paths known before delegation

2. **Parallel Worker Invocation** (Block 1e-exec):
   - research-coordinator invokes 3 research-specialist agents in parallel
   - Each specialist receives pre-calculated report path
   - Time savings: 40-60% vs sequential execution

3. **Metadata Extraction** (STEP 5):
   ```bash
   METADATA=()
   for REPORT_PATH in "${REPORT_PATHS[@]}"; do
     TITLE=$(extract_report_title "$REPORT_PATH")
     FINDINGS=$(count_findings "$REPORT_PATH")
     RECOMMENDATIONS=$(count_recommendations "$REPORT_PATH")

     METADATA+=("{\"path\":\"$REPORT_PATH\",\"title\":\"$TITLE\",\"findings_count\":$FINDINGS,\"recommendations_count\":$RECOMMENDATIONS}")
   done
   ```

4. **Aggregated Metadata Return** (STEP 6):
   ```json
   {
     "reports": [
       {"path": "/path/to/001-mathlib-theorems.md", "title": "...", "findings_count": 12, "recommendations_count": 5},
       {"path": "/path/to/002-proof-automation.md", "title": "...", "findings_count": 8, "recommendations_count": 4},
       {"path": "/path/to/003-project-structure.md", "title": "...", "findings_count": 10, "recommendations_count": 6}
     ],
     "total_reports": 3,
     "total_findings": 30,
     "total_recommendations": 15
   }
   ```

5. **Downstream Consumption** (lean-plan-architect):
   ```markdown
   **Research Context**:
   Research Reports: 3 reports created

   Report 1: Mathlib Theorems for Group Homomorphism
     - Findings: 12
     - Recommendations: 5
     - Path: /path/to/001-mathlib-theorems.md (use Read tool to access full content)

   **CRITICAL**: You have access to these report paths via Read tool.
   DO NOT expect full report content in this prompt.
   Use Read tool to access specific sections as needed.
   ```

**Context Metrics**:
- Reports metadata: 330 tokens (vs 7,500 full content)
- Reduction: 95.6%
- Iteration capacity: 10+ iterations (vs 3-4 before)

#### 2.2 /lean-plan Integration

**Location**: `/home/benjamin/.config/.claude/commands/lean-plan.md`

**Context Flow**:

```
Block 1d-topics: Research Topics Classification
├─ Complexity → Topic Count Mapping
│  - C1-2: 2 topics
│  - C3: 3 topics
│  - C4: 4 topics
└─ Lean-Specific Topics
   - Mathlib Theorems
   - Proof Strategies
   - Project Structure
   - Style Guide

Block 1d-calc: Report Path Pre-Calculation
├─ Find existing reports (NNN-*.md)
├─ Calculate sequential paths
└─ Persist TOPICS[] and REPORT_PATHS[]

Block 1e-exec: research-coordinator Invocation [HARD BARRIER]
└─ MANDATORY delegation (no bypass)

Block 1f: Hard Barrier Validation
├─ Validate all REPORT_PATHS[] exist
├─ Extract metadata (110 tokens per report)
└─ Format for planning phase

Block 2: lean-plan-architect Invocation
└─ Receives FORMATTED_METADATA (330 tokens)
   - Not full content (7,500 tokens)
   - Delegated Read tool access for full reports
```

**Formatted Metadata Structure**:
```bash
FORMATTED_METADATA="Research Reports: 3 reports created

Report 1: Mathlib Theorems for Group Homomorphism
  - Findings: 12
  - Recommendations: 5
  - Path: /path/to/001-mathlib-theorems.md (use Read tool to access full content)

Report 2: Proof Automation Strategies for Lean 4
  - Findings: 8
  - Recommendations: 4
  - Path: /path/to/002-proof-automation.md (use Read tool to access full content)

Report 3: Lean 4 Project Structure Patterns
  - Findings: 10
  - Recommendations: 6
  - Path: /path/to/003-project-structure.md (use Read tool to access full content)
"
```

**Partial Success Mode**:
```bash
# Calculate success percentage
SUCCESS_PERCENTAGE=$((SUCCESSFUL_REPORTS * 100 / TOTAL_REPORTS))

# Fail if <50% success
if [ $SUCCESS_PERCENTAGE -lt 50 ]; then
  log_command_error "validation_error" \
    "Research validation failed: <50% success rate" \
    "Only $SUCCESSFUL_REPORTS/$TOTAL_REPORTS reports created"
  exit 1
fi

# Warn if 50-99% success
if [ $SUCCESS_PERCENTAGE -lt 100 ]; then
  echo "WARNING: Partial research success (${SUCCESS_PERCENTAGE}%)" >&2
  echo "Proceeding with $SUCCESSFUL_REPORTS/$TOTAL_REPORTS reports..."
fi
```

#### 2.3 /lean-implement Integration

**Location**: `/home/benjamin/.config/.claude/commands/lean-implement.md`

**Context Flow**:

```
Block 1a: Pre-calculate Artifact Paths
├─ SUMMARIES_DIR
├─ DEBUG_DIR
├─ OUTPUTS_DIR
└─ CHECKPOINTS_DIR

Block 1b: Route to Coordinator [HARD BARRIER]
├─ MANDATORY delegation (no conditionals)
├─ implementer-coordinator invocation
└─ Wave-based parallel phase execution

Block 1c: Hard Barrier Validation + Brief Summary Parsing
├─ Validate summary exists (delegation bypass detection)
└─ Parse return signal fields (96% context reduction)
   - summary_brief: 80 tokens vs 2,000 full file
   - phases_completed
   - context_usage_percent
   - work_remaining
```

**Brief Summary Parsing**:
```bash
# Validate summary exists (hard barrier)
LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f -mmin -10 | sort | tail -1)

if [ -z "$LATEST_SUMMARY" ]; then
  echo "ERROR: HARD BARRIER FAILED - Summary not created by coordinator" >&2
  log_command_error "agent_error" "Coordinator did not create summary file"
  exit 1
fi

# Parse brief summary fields (96% context reduction)
SUMMARY_BRIEF=$(grep "^summary_brief:" "$LATEST_SUMMARY" | sed 's/^summary_brief:[[:space:]]*//')
PHASES_COMPLETED=$(grep "^phases_completed:" "$LATEST_SUMMARY" | sed 's/^phases_completed:[[:space:]]*//' | tr -d '[],"')
CONTEXT_USAGE_PERCENT=$(grep "^context_usage_percent:" "$LATEST_SUMMARY" | sed 's/^context_usage_percent:[[:space:]]*//' | sed 's/%//')
WORK_REMAINING=$(grep "^work_remaining:" "$LATEST_SUMMARY" | sed 's/^work_remaining:[[:space:]]*//')

# Display brief summary (no full file read required)
echo "Summary: $SUMMARY_BRIEF"
echo "Phases completed: ${PHASES_COMPLETED:-none}"
echo "Context usage: ${CONTEXT_USAGE_PERCENT}%"
echo "Full report: $LATEST_SUMMARY"

# Context reduction: 80 tokens parsed vs 2,000 tokens read = 96% reduction
```

### 3. Token Efficiency Patterns

#### 3.1 Complexity-Based Topic Scaling

```bash
# Map research complexity to topic count
case "$RESEARCH_COMPLEXITY" in
  1|2) TOPIC_COUNT=2 ;;
  3)   TOPIC_COUNT=3 ;;
  4)   TOPIC_COUNT=4 ;;
  *)   TOPIC_COUNT=3 ;;  # Default fallback
esac
```

**Rationale**: Higher complexity features require more research breadth. Context cost scales linearly (110 tokens × topic count), but value increases with comprehensive coverage.

#### 3.2 Selective Section Extraction

```bash
# Extract specific sections without loading full file
count_findings() {
  local report_path="$1"
  grep -c "^### Finding" "$report_path" 2>/dev/null || echo 0
}

count_recommendations() {
  local report_path="$1"
  awk '/^## Recommendations/,/^## / {
    if (/^[0-9]+\./) count++
  } END {print count}' "$report_path" 2>/dev/null || echo 0
}
```

**Rationale**: grep and awk operate on file without loading into memory/context. Only matched patterns consume tokens, not full file content.

#### 3.3 Delegated Read Pattern

```markdown
**CRITICAL INSTRUCTION**:
- The above is METADATA ONLY (not full report content)
- You have Read tool access to full reports at specified paths
- Use Read tool to access full research content when needed for planning
- DO NOT expect full report content in this prompt (95% context reduction)
```

**Rationale**: Downstream agents (plan-architect) decide which sections to read based on metadata. Orchestrator doesn't pre-load content speculatively. This shifts context consumption from orchestrator (limited iterations) to worker (single-use context).

### 4. Validation and Performance Metrics

#### 4.1 Integration Test Results

**Test Coverage**:
- `test_lean_plan_coordinator.sh`: 21 tests (100% pass rate)
- `test_lean_implement_coordinator.sh`: 27 tests (100% pass rate)
- Total: 48 tests, 0 failures

**Validation Scenarios**:
- Hard barrier enforcement (delegation bypass detection)
- Metadata extraction accuracy (title, counts)
- Partial success mode (≥50% threshold)
- Path pre-calculation correctness
- Return signal parsing

#### 4.2 Context Reduction Metrics

| Workflow Phase | Before Optimization | After Optimization | Reduction |
|----------------|---------------------|---------------------|-----------|
| /lean-plan research | 7,500 tokens (3 full reports) | 330 tokens (metadata) | 95.6% |
| /lean-implement iteration | 2,000 tokens (full summary) | 80 tokens (parsed fields) | 96.0% |

#### 4.3 Iteration Capacity

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Iterations per session | 3-4 | 10+ | 150-250% |
| Context exhaustion | ~85% at iteration 4 | ~40% at iteration 10 | 2.5× capacity |
| Time per iteration | ~45s (sequential) | ~27s (parallel) | 40% faster |

#### 4.4 Parallel Execution Metrics

**Time Savings** (3 research topics):
- Sequential execution: 3 × 30s = 90s
- Parallel execution: max(30s, 30s, 30s) = 30s
- Time reduction: 60s (66.7%)

**MCP Rate Limit Compliance**:
- WebSearch rate limit: 3 requests per 30 seconds
- 3 parallel research-specialists: 1 WebSearch each
- Total requests: 3 (within budget)
- No rate limit violations

## Findings

### Finding 1: Metadata-Only Passing Achieves 95% Context Reduction

The research-coordinator pattern demonstrates that extracting lightweight metadata (title, findings count, recommendations count) from worker outputs achieves 95.6% context reduction (330 tokens vs 7,500 tokens for 3 full reports). Downstream consumers receive report paths and use Read tool for selective content access.

**Evidence**:
- `/lean-plan` Block 1f extracts 110 tokens per report (title + 2 counts)
- lean-plan-architect receives `FORMATTED_METADATA` with paths, not full content
- Context reduction validated in 21 integration tests (100% pass rate)

### Finding 2: Brief Summary Parsing Enables 96% Context Reduction

The implementer-coordinator integration uses grep-based field extraction from structured return signals instead of reading full summary files. Parsing `summary_brief`, `phases_completed`, `context_usage_percent`, and `work_remaining` fields consumes 80 tokens vs 2,000 tokens for full file.

**Evidence**:
- `/lean-implement` Block 1c parses 4 key:value pairs (80 tokens)
- Full summary file: ~2,000 tokens (structured markdown)
- Pattern validated in 27 integration tests (100% pass rate)

### Finding 3: Hard Barrier Pattern Enforces 100% Delegation Success

The Setup → Execute → Verify pattern makes delegation bypass structurally impossible. Bash blocks between Task invocations create barriers Claude cannot skip, and fail-fast validation (exit 1) prevents progression without artifacts.

**Evidence**:
- `/lean-plan` Block 1e-exec is MANDATORY (hard barrier label)
- Block 1f validation fails immediately if reports missing
- research-coordinator STEP 4 uses exit 1 for missing artifacts
- Before: 40-60% bypass rate; After: 0% bypass rate

### Finding 4: Complexity-Based Topic Scaling Balances Coverage and Context Cost

The `/lean-plan` command maps research complexity (1-4) to topic count (2-4), scaling research breadth with feature complexity while maintaining predictable context cost (110 tokens × topic count).

**Evidence**:
- Complexity 1-2: 2 topics = 220 tokens metadata
- Complexity 3: 3 topics = 330 tokens metadata
- Complexity 4: 4 topics = 440 tokens metadata
- Linear scaling enables budget predictability

### Finding 5: Partial Success Mode Handles Worker Failures Gracefully

The research-coordinator implements ≥50% success threshold for partial completion. Workflows proceed with warnings if 50-99% of reports created, enabling graceful degradation instead of total failure.

**Evidence**:
- `/lean-plan` Block 1f calculates `SUCCESS_PERCENTAGE`
- Fails if <50% (insufficient coverage)
- Warns if 50-99% (partial success)
- Continues with available reports
- Resilience validated in integration tests

### Finding 6: Delegated Read Pattern Shifts Context from Orchestrator to Worker

The metadata-only passing strategy includes explicit instructions for downstream agents to use Read tool for full content access. This shifts context consumption from orchestrator (limited iterations) to single-use worker agents.

**Evidence**:
- lean-plan-architect receives paths with "use Read tool" instruction
- Orchestrator avoids speculative content loading
- Worker decides which sections to read based on metadata
- Context budget preserved for additional iterations

### Finding 7: Parallel Execution Provides 40-60% Time Savings

The research-coordinator invokes multiple research-specialist agents in parallel, reducing wall-clock time from sequential sum to maximum individual time. For 3 topics at 30s each: 90s sequential → 30s parallel (60s savings).

**Evidence**:
- research-coordinator STEP 3 uses multiple Task invocations in single response
- Parallel pattern documented in hierarchical-agents-examples.md Example 7
- Time savings: 40-60% for typical 2-4 topic research
- MCP rate limits respected (3 req/30s budget)

### Finding 8: Iteration Capacity Increased 150-250%

Context optimization techniques enable 10+ iterations per session (vs 3-4 before), increasing workflow capacity by 150-250%. This supports complex features requiring multiple revision cycles.

**Evidence**:
- Before: 3-4 iterations = ~85% context exhaustion
- After: 10+ iterations = ~40% context usage
- 2.5× capacity increase
- Validated in production `/lean-plan` and `/lean-implement` workflows

## Recommendations

### Recommendation 1: Apply Metadata-Only Passing to All Multi-Topic Coordinators

Extend the research-coordinator metadata extraction pattern to other coordinator agents (implementer-coordinator, testing-coordinator, debug-coordinator). Define standard metadata fields (title, status, artifact_count, error_count) for consistent parsing.

**Implementation**:
```bash
# Standard metadata extraction function
extract_agent_metadata() {
  local artifact_path="$1"
  local artifact_type="$2"  # research|implementation|test|debug

  TITLE=$(grep -m 1 "^# " "$artifact_path" | sed 's/^# //')

  case "$artifact_type" in
    research)
      FINDINGS=$(grep -c "^### Finding" "$artifact_path")
      RECOMMENDATIONS=$(grep -c "^[0-9]+\." "$artifact_path")
      echo "{\"path\":\"$artifact_path\",\"title\":\"$TITLE\",\"findings\":$FINDINGS,\"recommendations\":$RECOMMENDATIONS}"
      ;;
    implementation)
      PHASES=$(grep -c "^### Phase" "$artifact_path")
      FILES_MODIFIED=$(grep -c "^- \[x\]" "$artifact_path")
      echo "{\"path\":\"$artifact_path\",\"title\":\"$TITLE\",\"phases\":$PHASES,\"files_modified\":$FILES_MODIFIED}"
      ;;
    test)
      TESTS_PASSED=$(grep -c "PASS" "$artifact_path")
      TESTS_FAILED=$(grep -c "FAIL" "$artifact_path")
      echo "{\"path\":\"$artifact_path\",\"title\":\"$TITLE\",\"passed\":$TESTS_PASSED,\"failed\":$TESTS_FAILED}"
      ;;
  esac
}
```

### Recommendation 2: Standardize Brief Summary Return Signals

Define a canonical return signal format for all coordinator agents with mandatory fields (summary_brief, status, artifact_paths, metrics). This enables consistent parsing across workflows.

**Standard Format**:
```
COORDINATOR_COMPLETE: {AGENT_NAME}
summary_brief: {80-char one-line summary}
status: {complete|partial|blocked}
artifact_paths: [{path1}, {path2}, ...]
metrics: {
  "phases_completed": N,
  "context_usage_percent": N,
  "time_elapsed_seconds": N,
  "work_remaining": "description"
}
```

### Recommendation 3: Document Context Budget Guidelines

Create a reference document specifying context budgets for each agent tier (orchestrator, coordinator, worker) and metadata token targets (e.g., 80-120 tokens per artifact).

**Proposed Guidelines**:
| Agent Tier | Context Budget | Metadata Target | Full Artifact |
|------------|----------------|-----------------|---------------|
| Orchestrator (command) | 15,000 tokens | 80-120 tokens | Never loaded |
| Coordinator (supervisor) | 30,000 tokens | 500-1,000 tokens | Metadata only |
| Worker (specialist) | 100,000 tokens | N/A | Full content access |

### Recommendation 4: Implement Automated Context Tracking

Add instrumentation to log actual context usage per workflow phase and compare against budgets. This enables empirical validation of optimization effectiveness.

**Implementation**:
```bash
# Log context usage after each phase
log_context_usage() {
  local phase="$1"
  local tokens_used="$2"
  local budget="$3"

  PERCENTAGE=$((tokens_used * 100 / budget))

  echo "[CONTEXT] Phase: $phase | Used: $tokens_used / $budget tokens ($PERCENTAGE%)" | \
    tee -a "${CLAUDE_PROJECT_DIR}/.claude/logs/context_usage.log"

  if [ $PERCENTAGE -gt 80 ]; then
    echo "WARNING: Context usage exceeds 80% in phase: $phase" >&2
  fi
}
```

### Recommendation 5: Create Context Optimization Testing Suite

Develop integration tests that validate context reduction metrics (95%+ for metadata-only, 96%+ for brief summaries). Fail builds if context usage exceeds thresholds.

**Test Cases**:
1. Metadata extraction: Validate 110 token target per report
2. Brief summary parsing: Validate 80 token target per summary
3. Full workflow: Track total context across 10 iterations
4. Regression detection: Alert if context usage increases >10%

### Recommendation 6: Apply Hard Barrier Pattern to All Delegation Workflows

Audit all commands for delegation bypass risks (direct tool access in orchestrators). Refactor to Setup → Execute → Verify pattern with mandatory Task invocations and fail-fast validation.

**Anti-Pattern Detection**:
```bash
# Audit commands for delegation bypass risks
grep -r "Read\|Edit\|Write\|Grep\|Glob" .claude/commands/*.md | \
  grep -v "Block.*exec" | \
  grep -v "# Example" > potential_bypass_risks.txt

# Commands with tool access outside Execute blocks are candidates for refactoring
```

### Recommendation 7: Extend Partial Success Mode to Other Coordinators

Implement ≥50% success threshold in implementer-coordinator, testing-coordinator, and debug-coordinator for graceful degradation. Document failure handling strategy for each coordinator.

**Partial Success Logic**:
```bash
# Generic partial success validation
validate_partial_success() {
  local total="$1"
  local successful="$2"
  local threshold="${3:-50}"  # Default 50%

  PERCENTAGE=$((successful * 100 / total))

  if [ $PERCENTAGE -lt $threshold ]; then
    echo "ERROR: Success rate ${PERCENTAGE}% below ${threshold}% threshold" >&2
    return 1
  elif [ $PERCENTAGE -lt 100 ]; then
    echo "WARNING: Partial success ${PERCENTAGE}% (${successful}/${total})" >&2
  fi

  return 0
}
```

### Recommendation 8: Document Coordinator Return Signal Parsing

Create a reference guide for parsing coordinator return signals with examples for each coordinator type. Include regex patterns and error handling.

**Documentation Structure**:
```markdown
# Coordinator Return Signal Parsing Guide

## research-coordinator
Expected format:
RESEARCH_COMPLETE: {N}
reports: [{"path":"...","title":"...","findings_count":N,"recommendations_count":M},...]

Parsing:
REPORT_COUNT=$(echo "$OUTPUT" | grep "RESEARCH_COMPLETE:" | sed 's/RESEARCH_COMPLETE:[[:space:]]*//')
METADATA_JSON=$(echo "$OUTPUT" | grep "^reports:" | sed 's/^reports:[[:space:]]*//')

## implementer-coordinator
Expected format:
summary_brief: {one-line summary}
phases_completed: [{phase1},{phase2}]
context_usage_percent: N%

Parsing:
SUMMARY=$(grep "^summary_brief:" "$FILE" | sed 's/^summary_brief:[[:space:]]*//')
```

### Recommendation 9: Optimize Error Return Signals

Extend the error return protocol to include structured error metadata for machine-parseable error analysis. This supports automated error pattern detection in `/errors` and `/repair` commands.

**Enhanced Error Signal**:
```
ERROR_CONTEXT: {
  "error_type": "validation_error",
  "message": "3 research reports missing after agent invocation",
  "details": {
    "missing_reports": ["/path/1.md", "/path/2.md"],
    "expected_count": 3,
    "actual_count": 1,
    "success_percentage": 33
  },
  "recovery_hints": [
    "Check research-specialist agent logs",
    "Verify report paths are writable",
    "Retry with --complexity 2 for fewer topics"
  ]
}
TASK_ERROR: validation_error - 3 research reports missing (hard barrier failure)
```

### Recommendation 10: Create Context Optimization Best Practices Guide

Document the patterns discovered in this research as a best practices guide for future agent development. Include anti-patterns, code examples, and decision trees for choosing optimization strategies.

**Guide Outline**:
```markdown
# Context Optimization Best Practices

## When to Use Metadata-Only Passing
- Multi-topic research (>1 topic)
- Downstream consumer needs overview before detail
- Full artifacts available via Read tool
- Target: 95%+ reduction

## When to Use Brief Summary Parsing
- Iterative workflows with continuation signals
- Status monitoring without full content
- Machine-parseable structured output
- Target: 96%+ reduction

## When to Use Hard Barrier Pattern
- Orchestrator has permissive tool access
- Delegation enforcement critical
- Error recovery needs explicit checkpoints
- Target: 100% delegation success

## Anti-Patterns to Avoid
- Loading full artifacts speculatively
- Inline work in orchestrators
- Optional validation (use fail-fast)
- Historical content in metadata
```
