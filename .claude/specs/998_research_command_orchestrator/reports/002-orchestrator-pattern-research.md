# Study Orchestrator Pattern in /implement and /create-plan

## Executive Summary

The /implement and /create-plan commands demonstrate sophisticated orchestrator and coordinator agent patterns for managing complex multi-phase workflows. Both commands use hierarchical delegation to specialized agents (implementer-coordinator and research-coordinator) with hard barrier validation, metadata-only context passing achieving 95%+ context reduction, and wave-based parallel execution delivering 40-60% time savings. The pattern separates orchestration concerns (state management, path pre-calculation) from execution concerns (agent delegation, artifact creation).

## Findings

### Finding 1: Hard Barrier Pattern for Mandatory Delegation

**Pattern Description**: Commands pre-calculate output paths BEFORE agent invocation and validate artifacts exist AFTER agent returns, preventing orchestrators from bypassing subagent delegation.

**Implementation in /implement**:
- Block 1a: Pre-calculates `SUMMARIES_DIR` path and persists to state
- Block 1b: Invokes implementer-coordinator via Task tool with explicit contract
- Block 1c: Validates summary file exists at expected path with fail-fast on missing artifact

```bash
# Hard Barrier Validation (implement.md:682-771)
if [ -z "$LATEST_SUMMARY" ] || [ ! -f "$LATEST_SUMMARY" ]; then
  echo "❌ HARD BARRIER FAILED - Implementation summary not found" >&2
  echo "Expected: Summary file in $SUMMARIES_DIR" >&2
  exit 1
fi
```

**Implementation in /create-plan**:
- Block 1b: Pre-calculates `TOPIC_NAME_FILE` absolute path
- Block 1b-exec: Passes path as literal contract to topic-naming-agent
- Block 1c: Validates file exists with fail-fast, preventing workflow continuation without topic name

```bash
# Path Pre-Calculation (create-plan.md:360-395)
TOPIC_NAME_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt"
if [[ "$TOPIC_NAME_FILE" =~ ^/ ]]; then
  : # Path is absolute, continue
else
  echo "ERROR: TOPIC_NAME_FILE is not absolute: $TOPIC_NAME_FILE" >&2
  exit 1
fi
```

**Design Benefits**:
- Prevents "implementation work directly" anti-pattern (orchestrator doing specialist work)
- Enforces separation of concerns (path calculation vs artifact creation)
- Enables early error detection (missing file = agent invocation failure)
- Supports diagnostics (enhanced error messages identify wrong-location vs missing-file failures)

### Finding 2: Metadata-Only Context Passing (95%+ Reduction)

**Pattern Description**: Coordinators extract lightweight metadata summaries from specialist outputs instead of passing full artifact content to orchestrators.

**Implementation in /implement**:
- implementer-coordinator returns brief summary with metadata fields (work_remaining, context_exhausted, checkpoint_path)
- Block 1c parses metadata from summary file header (80 tokens vs 2,000 tokens full summary)
- Orchestrator uses metadata for iteration decisions without loading full implementation details

```bash
# Metadata Extraction (implement.md:831-843)
WORK_REMAINING=$(grep "^work_remaining:" "$LATEST_SUMMARY" | sed 's/work_remaining:[[:space:]]*//' | head -1)
CONTEXT_EXHAUSTED=$(grep "^context_exhausted:" "$LATEST_SUMMARY" | sed 's/context_exhausted:[[:space:]]*//' | head -1)
CONTEXT_USAGE_PERCENT=$(grep "^context_usage_percent:" "$LATEST_SUMMARY" | sed 's/context_usage_percent:[[:space:]]*//' | sed 's/%//' | head -1)
```

**Implementation in /create-plan**:
- research-coordinator extracts metadata from research reports (title, findings_count, recommendations_count)
- Returns aggregated JSON metadata (110 tokens per report vs 2,500 tokens full content)
- Enables parallel research on 3-4 topics without context exhaustion

```markdown
# Coordinator Return Signal (research-coordinator.md:760-776)
RESEARCH_COMPLETE: 3
reports: [
  {"path": "/path/to/001-mathlib-theorems.md", "title": "Mathlib Theorems", "findings_count": 12, "recommendations_count": 5},
  {"path": "/path/to/002-proof-automation.md", "title": "Proof Automation", "findings_count": 8, "recommendations_count": 4}
]
total_findings: 30
total_recommendations: 15
```

**Performance Metrics**:
- Context reduction: 95.6% (7,500 tokens → 330 tokens for 3 reports)
- Iteration capacity: 10+ iterations possible (vs 3-4 before coordinator pattern)
- Partial success mode: ≥50% reports threshold allows graceful degradation

### Finding 3: Wave-Based Parallel Execution

**Pattern Description**: Coordinators identify independent phases and execute them in parallel waves, respecting dependency constraints.

**Implementation in /implement**:
- implementer-coordinator analyzes plan for phase dependencies
- Groups independent phases into waves (e.g., Wave 1: Phases 1,2,3 in parallel; Wave 2: Phase 4 depends on 1-3)
- Executes waves sequentially, phases within waves in parallel

```markdown
# Wave Execution Contract (implement.md:536-595)
Workflow-Specific Context:
  - Execution Mode: wave-based (parallel where possible)
  - Current Iteration: ${ITERATION}/${MAX_ITERATIONS}

Execute all implementation phases according to the plan.
```

**Implementation in /create-plan**:
- research-coordinator decomposes research request into 2-5 topics (based on complexity)
- Invokes research-specialist agents in parallel (STEP 3)
- Aggregates results after all workers complete (STEP 4-6)

```bash
# Parallel Invocation Loop (research-coordinator.md:343-422)
for i in "${!TOPICS[@]}"; do
  TOPIC="${TOPICS[$i]}"
  REPORT_PATH="${REPORT_PATHS[$i]}"

  # Generate Task invocation (executed in parallel)
  Task {
    prompt: "Research topic: $TOPIC, Output: $REPORT_PATH"
  }
done
```

**Time Savings**:
- 40-60% reduction in total execution time for multi-phase workflows
- Example: 4 research topics in parallel vs sequential (45s vs 120s)
- MCP rate limits respected (3 req/30s budget across parallel agents)

### Finding 4: Behavioral Injection via Markdown Agent Files

**Pattern Description**: Agent behavior defined in single-source `.claude/agents/*.md` files, injected at runtime via Task tool prompt parameter.

**Implementation in /implement**:
```markdown
# Coordinator Invocation (implement.md:533-595)
Task {
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    **Input Contract**: plan_path, topic_path, iteration
    Execute implementation phases...
  "
}
```

**Implementation in /create-plan**:
```markdown
# Multiple Agent Injections
- topic-naming-agent.md (Block 1b-exec)
- topic-detection-agent.md (Block 1d-decomp)
- research-coordinator.md (Block 1e-exec)
- plan-architect.md (Block 2b)
```

**Benefits**:
- Single source of truth for agent behavior (no duplication)
- Versioning agents independently from commands
- Runtime behavior changes without command updates
- Testability (agent files can be unit tested separately)

### Finding 5: Iteration Loop Pattern with Context Monitoring

**Pattern Description**: Orchestrators monitor context usage and implement iterative execution with continuation support for large plans.

**Implementation in /implement**:
- Block 1c parses `context_usage_percent` and `requires_continuation` from coordinator
- Decision point: If continuation required, loop back to Block 1b with updated iteration variables
- Stuck detection: Monitors `work_remaining` across iterations, halts if unchanged

```bash
# Iteration Decision Logic (implement.md:1002-1040)
if [ "$REQUIRES_CONTINUATION" = "true" ]; then
  NEXT_ITERATION=$((ITERATION + 1))
  CONTINUATION_CONTEXT="${IMPLEMENT_WORKSPACE}/iteration_${ITERATION}_summary.md"
  append_workflow_state "ITERATION" "$NEXT_ITERATION"
  append_workflow_state "CONTINUATION_CONTEXT" "$CONTINUATION_CONTEXT"
  # Loop back to Block 1b
else
  # Mark complete or halted
  append_workflow_state "IMPLEMENTATION_STATUS" "complete"
fi
```

**Defensive Validation Pattern**:
```bash
# Contract Invariant Enforcement (implement.md:944-996)
if ! is_work_remaining_empty "$WORK_REMAINING"; then
  if [ "$REQUIRES_CONTINUATION" != "true" ]; then
    echo "WARNING: Agent returned requires_continuation=false with work_remaining non-empty" >&2
    REQUIRES_CONTINUATION="true"  # Override agent bug
    log_command_error "validation_error" "Agent contract violation"
  fi
fi
```

**Checkpoint Resume Support**:
- Checkpoint files capture iteration state (iteration, work_remaining, continuation_context)
- `--resume=<checkpoint>` flag allows resumption from saved state
- Validates checkpoint version (2.1 schema) and critical fields

### Finding 6: State-Based Orchestration with Fail-Fast

**Pattern Description**: Commands use workflow state machines for phase transitions with fail-fast error handling and diagnostic logging.

**Implementation in /implement**:
```bash
# State Transitions (implement.md:378-462)
sm_init "$PLAN_FILE" "$COMMAND_NAME" "$WORKFLOW_TYPE" "1" "[]"
sm_transition "$STATE_IMPLEMENT" "plan loaded, starting implementation"

# Error Logging on Failure
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "state_error" "State transition to IMPLEMENT failed" "bash_block_1" \
    "$(jq -n --arg state "IMPLEMENT" '{target_state: $state}')"
  exit 1
fi
```

**State Persistence Pattern**:
```bash
# Cross-Block State Sharing (implement.md:466-504)
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
append_workflow_state "PLAN_FILE" "$PLAN_FILE"
append_workflow_state "ITERATION" "$ITERATION"
append_workflow_state "CONTINUATION_CONTEXT" "$CONTINUATION_CONTEXT"
```

**State Restoration with Recovery**:
```bash
# Block-Isolated Restoration (implement.md:615-666)
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/implement_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)
load_workflow_state "$WORKFLOW_ID" false
validate_state_restoration "PLAN_FILE" "TOPIC_PATH" || exit 1
```

### Finding 7: Pre-Execution Barriers and Self-Validation

**Pattern Description**: Coordinators implement mandatory checkpoints that force agent self-verification before proceeding to next step.

**Implementation in research-coordinator**:
```markdown
# STEP 2.5: Invocation Planning (research-coordinator.md:266-328)
**Objective**: Force agent to declare expected invocation count and create plan file BEFORE Task invocations.

Actions:
1. Calculate EXPECTED_INVOCATIONS from topics array
2. Create .invocation-plan.txt file with topic list
3. Output checkpoint confirming plan file creation

**CRITICAL**: If STEP 4 detects missing plan file, workflow FAILS with error.
```

**Self-Validation Questionnaire**:
```markdown
# STEP 3.5: Mandatory Self-Validation (research-coordinator.md:460-508)
SELF-CHECK QUESTIONS (Answer YES or NO):
1. Did you USE Task tool for each topic? (Not just read patterns)
2. How many Task invocations executed? (MUST EQUAL topics count)
3. Did each Task include REPORT_PATH from array?
4. Did you use actual values (not placeholders)?
5. Did you write Task blocks WITHOUT code fences?

If FALSE, immediately return to STEP 3.
```

**Validation Artifacts**:
- `.invocation-plan.txt`: Proves STEP 2.5 executed (contains expected invocation count)
- `.invocation-trace.log`: Proves STEP 3 executed (contains `Status: INVOKED` per topic)
- Hard barrier in STEP 4 validates both files exist with correct counts

### Finding 8: Error Return Protocol for Hierarchical Logging

**Pattern Description**: Subagents return structured error signals for parent command logging integration.

**Coordinator Error Return Format**:
```markdown
# Error Signal (research-coordinator.md:860-875)
ERROR_CONTEXT: {
  "error_type": "validation_error",
  "message": "3 research reports missing after agent invocation",
  "details": {"missing_reports": ["/path/1.md", "/path/2.md"]}
}

TASK_ERROR: validation_error - 3 research reports missing (hard barrier failure)
```

**Parent Command Parsing**:
```bash
# Subagent Error Integration (implement.md:680-746)
if [ $PARSING_ERRORS -gt 0 ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "agent_error" "implementer-coordinator return signal parsing failed" \
    "bash_block_1c" "$(jq -n --argjson errors "$PARSING_ERRORS" '{parsing_errors: $errors}')"
fi
```

**Error Trap Handler** (research-coordinator):
```bash
# STEP 0.5: Error Handler Installation (research-coordinator.md:98-144)
handle_coordinator_error() {
  echo "ERROR_CONTEXT: {" >&2
  echo "  \"error_type\": \"agent_error\"," >&2
  echo "  \"message\": \"Research coordinator failed at line $line_number\"," >&2
  echo "}" >&2
  echo "TASK_ERROR: agent_error - Research coordinator failed"
  exit $exit_code
}
trap 'handle_coordinator_error $? $LINENO' ERR
```

## Recommendations

### Recommendation 1: Standardize Hard Barrier Pattern Across All Coordinator Agents

**Action**: Document hard barrier pattern as required architecture for all coordinator/orchestrator relationships.

**Template Components**:
1. Path pre-calculation block (calculate before invocation)
2. Contract parameter injection (pass literal paths to subagent)
3. Hard barrier validation block (fail-fast if artifact missing)
4. Enhanced diagnostics (wrong-location vs missing-file detection)

**Commands to Update**:
- /lean-implement (adopt implementer-coordinator pattern from /implement)
- /debug (if using coordinator for parallel diagnosis)
- /repair (if using coordinator for parallel fixes)

### Recommendation 2: Extract Metadata Parsing to Reusable Library

**Action**: Create `coordinator-metadata-utils.sh` library with standardized metadata extraction functions.

**Proposed Functions**:
```bash
# Extract metadata from coordinator return signal
parse_coordinator_metadata() {
  local summary_file="$1"
  local field_name="$2"
  grep "^${field_name}:" "$summary_file" | sed "s/${field_name}:[[:space:]]*//" | head -1
}

# Validate coordinator return signal format
validate_coordinator_signal() {
  local summary_file="$1"
  local required_fields=("work_remaining" "context_exhausted" "requires_continuation")
  # Returns 0 if all fields present, 1 if any missing
}

# Convert JSON array to space-separated scalar (defensive format conversion)
normalize_work_remaining() {
  local work_remaining="$1"
  # Handles: "[Phase 4, Phase 5]" → "Phase 4 Phase 5"
}
```

**Benefits**:
- Consistency across /implement, /lean-implement, /debug coordinators
- Centralized defensive validation logic
- Easier testing and bug fixes

### Recommendation 3: Document Wave-Based Execution Patterns

**Action**: Create design guide for phase dependency analysis and wave grouping.

**Documentation Structure**:
```markdown
# Wave-Based Execution Pattern

## When to Use
- Plan has 5+ phases with mixed dependencies
- Some phases are independent (can run in parallel)
- Time savings justify complexity overhead

## Dependency Detection
1. Parse plan for dependency declarations (e.g., "depends_on: [1, 2]")
2. Build dependency graph (adjacency list)
3. Topological sort to identify wave boundaries

## Wave Grouping Algorithm
- Wave 1: Phases with no dependencies
- Wave 2: Phases depending only on Wave 1
- Wave N: Phases depending on Waves 1..N-1

## Implementation Template
[Code examples from implementer-coordinator]
```

**Reference Implementation**: implementer-coordinator.md (to be created based on /lean-implement pattern)

### Recommendation 4: Standardize Self-Validation Checkpoints

**Action**: Add mandatory self-validation questionnaires to all coordinator agent files at critical execution junctures.

**Template**:
```markdown
## STEP X.5 (MANDATORY SELF-VALIDATION): Verify [Action]

SELF-CHECK QUESTIONS (Answer YES or NO):
1. Did you execute [critical action]? (Not just read instructions)
2. How many [units of work] completed? (MUST EQUAL [expected count])
3. Did each [unit] include [required field]?

**FAIL-FAST**: If any answer is NO, return to STEP X immediately.

**Common Mistake Detection**:
- If you see [anti-pattern text], workflow will fail
- Recovery: Return to STEP X, [corrective action]
```

**Apply To**:
- research-coordinator (already has STEP 3.5, expand coverage)
- implementer-coordinator (add wave execution verification)
- Any future coordinator with multi-step delegation

### Recommendation 5: Implement Partial Success Mode

**Action**: Add threshold-based completion criteria to coordinators, allowing workflow continuation if ≥50% of work succeeds.

**Pattern** (from research-coordinator.md:820-826):
```markdown
# Partial Success Threshold
if research_reports_created >= 0.5 * total_topics:
  return partial metadata with warning
else:
  return TASK_ERROR (insufficient results)
```

**Benefits**:
- Graceful degradation for network failures or rate limits
- User can manually retry failed topics instead of full restart
- Better UX for long-running multi-topic workflows

**Commands to Update**:
- /implement (add partial phase completion mode)
- /lean-plan (add partial research completion mode)

### Recommendation 6: Centralize Iteration Loop Logic

**Action**: Extract iteration management pattern to `iteration-loop-utils.sh` library.

**Proposed Functions**:
```bash
# Check if work truly remains (defensive validation)
is_work_remaining_empty() {
  local work_remaining="$1"
  # Handles: "", "0", "[]", whitespace-only
}

# Enforce continuation contract invariant
validate_continuation_signal() {
  local work_remaining="$1"
  local requires_continuation="$2"
  # If work_remaining non-empty, continuation MUST be true
}

# Detect stuck iteration (work_remaining unchanged)
is_iteration_stuck() {
  local current_work="$1"
  local previous_work="$2"
  local stuck_threshold="${3:-3}"  # Number of unchanged iterations
}
```

**Apply To**:
- /implement (already has pattern, extract to library)
- /lean-implement (adopt standardized pattern)
- Future iterative workflows

## References

### Files Examined

1. `/home/benjamin/.config/.claude/commands/implement.md` (1,761 lines)
   - Hard barrier pattern (Block 1b-1c)
   - Metadata-only context passing (Block 1c parsing)
   - Iteration loop with defensive validation (Block 1c continuation logic)
   - State-based orchestration (Block 1a initialization, Block 1d restoration)

2. `/home/benjamin/.config/.claude/commands/create-plan.md` (partial, first 500 lines)
   - Hard barrier pattern (Block 1b-1c topic name validation)
   - Multi-agent behavioral injection (topic-naming-agent, research-coordinator)
   - Research complexity-based topic decomposition
   - Path pre-calculation with absolute path validation

3. `/home/benjamin/.config/.claude/agents/research-coordinator.md` (963 lines)
   - Parallel research delegation (STEP 3 Task invocations)
   - Metadata extraction and aggregation (STEP 5-6)
   - Pre-execution barriers (STEP 2.5 invocation planning)
   - Self-validation checkpoints (STEP 3.5 questionnaire)
   - Error return protocol (STEP 0.5 error handler)
   - Hard barrier artifact validation (STEP 4)

4. `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md` (177 lines)
   - Hierarchical supervision principles
   - Behavioral injection pattern
   - Metadata-only context passing metrics (95%+ reduction)
   - Communication flow between orchestrator/supervisor/specialist roles
   - When to use hierarchical architecture decision criteria

### Key Architectural Patterns

**Hard Barrier Pattern**: Orchestrator pre-calculates paths → invokes agent with contract → validates artifacts exist → fails fast if missing

**Metadata-Only Passing**: Coordinator extracts lightweight summaries (110 tokens) instead of full content (2,500 tokens) = 95% context reduction

**Wave-Based Execution**: Coordinator analyzes dependencies → groups independent phases → executes waves in parallel → respects constraints

**Behavioral Injection**: Agent behavior in `.claude/agents/*.md` files → injected via Task prompt → single source of truth → runtime modification

**Iteration Loops**: Monitor context usage → check continuation signal → validate contract invariants → detect stuck state → loop or complete

**Error Return Protocol**: Subagent returns ERROR_CONTEXT + TASK_ERROR → parent parses with parse_subagent_error() → logs to errors.jsonl with workflow context
