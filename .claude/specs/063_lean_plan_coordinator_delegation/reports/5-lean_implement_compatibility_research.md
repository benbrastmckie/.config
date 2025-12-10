# Research Report: /lean-implement Compatibility Patterns for lean-plan Coordinator Delegation

**Research Date**: 2025-12-09
**Research Complexity**: 2
**Workflow Type**: research-and-revise
**Input Plan**: /home/benjamin/.config/.claude/specs/063_lean_plan_coordinator_delegation/plans/001-lean-plan-coordinator-delegation-plan.md

---

## Executive Summary

This research analyzes the robust patterns used in `/implement` command and `/lean-implement` command to inform the revision of the lean-plan coordinator delegation plan (Spec 063). The goal is to ensure `/lean-implement` compatibility and prevent regression of proven delegation patterns.

**Key Findings**:
1. `/implement` uses **hard barrier pattern** across 3 blocks (Setup → Execute → Verify) with mandatory delegation
2. **implementer-coordinator** returns brief summary format (80 tokens metadata) for 96% context reduction
3. **State machine integration** with fail-fast validation prevents bypass attempts
4. **Plan-based mode** eliminates dependency analysis overhead (65→51→16 coordinator implementation uses plan metadata extraction)
5. **Pattern A (Orchestrator Mode)** is the recommended architecture for coordinator delegation based on industry research

**Critical Insight**: The `/lean-implement` command successfully delegates to **implementer-coordinator** using plan-based mode with wave structure extraction from plan metadata. This same pattern should be applied to lean-plan's research coordination.

---

## 1. /implement Command Architecture Analysis

### 1.1 Hard Barrier Pattern Structure

The `/implement` command enforces delegation via a **3-block pattern** that makes bypass architecturally impossible:

```
Block 1a: Implementation Phase Setup
├── State transition: IMPLEMENT [fail-fast]
├── Variable persistence (append_workflow_state)
└── Checkpoint reporting

Block 1b: Implementer-Coordinator Invocation [CRITICAL BARRIER]
└── Task invocation (MANDATORY - no conditionals)

Block 1c: Implementation Phase Verification (Hard Barrier)
├── Artifact existence check (LATEST_SUMMARY)
├── Fail-fast on missing outputs (exit 1)
└── Error logging with recovery hints
```

**Why This Works**:
- Bash blocks between Task invocations prevent Claude from skipping verification
- State transitions act as gates (non-zero exit code stops workflow)
- Mandatory Task invocation has no alternative execution path
- Verification block depends on Task execution artifacts

**Source**: `.claude/commands/implement.md` lines 410-812

### 1.2 State Machine Integration

The `/implement` command integrates workflow state machine for robust state tracking:

```bash
# Block 1a: State transition prevents progression without valid state
sm_transition "$STATE_IMPLEMENT" "plan loaded, starting implementation" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to IMPLEMENT failed" \
    "bash_block_1" \
    "$(jq -n --arg state "IMPLEMENT" '{target_state: $state}')"

  echo "ERROR: State transition to IMPLEMENT failed" >&2
  exit 1
fi
```

**Key Pattern**: Every state transition has fail-fast error handling with structured error logging.

**Source**: `.claude/commands/implement.md` lines 447-462

### 1.3 Brief Summary Aggregation Pattern

After implementer-coordinator returns, `/implement` parses **metadata fields only** (not full file content):

```bash
# Parse all fields from agent return signal (from summary file metadata)
WORK_REMAINING=$(grep "^work_remaining:" "$LATEST_SUMMARY" | sed 's/work_remaining:[[:space:]]*//' | head -1 || echo "")
CONTEXT_EXHAUSTED=$(grep "^context_exhausted:" "$LATEST_SUMMARY" | sed 's/context_exhausted:[[:space:]]*//' | head -1 || echo "false")
SUMMARY_PATH="$LATEST_SUMMARY"
CONTEXT_USAGE_PERCENT=$(grep "^context_usage_percent:" "$LATEST_SUMMARY" | sed 's/context_usage_percent:[[:space:]]*//' | sed 's/%//' | head -1 || echo "0")
CHECKPOINT_PATH=$(grep "^checkpoint_path:" "$LATEST_SUMMARY" | sed 's/checkpoint_path:[[:space:]]*//' | head -1 || echo "")
REQUIRES_CONTINUATION=$(grep "^requires_continuation:" "$LATEST_SUMMARY" | sed 's/requires_continuation:[[:space:]]*//' | head -1 || echo "false")
STUCK_DETECTED=$(grep "^stuck_detected:" "$LATEST_SUMMARY" | sed 's/stuck_detected:[[:space:]]*//' | head -1 || echo "false")
```

**Context Reduction**: 80 tokens (metadata fields) vs 2,000 tokens (full file) = **96% reduction**

**Source**: `.claude/commands/implement.md` lines 830-843

---

## 2. /lean-implement Command Architecture Analysis

### 2.1 Plan-Based Mode Integration

The `/lean-implement` command delegates to **lean-coordinator** and **implementer-coordinator** with plan-based mode:

```bash
# === EXECUTION MODE INITIALIZATION ===
# Wave-based plan delegation: Pass entire plan to coordinator
# Coordinator analyzes dependencies and executes waves in parallel
# Note: Coordinators expect "plan-based" mode (not "full-plan")
EXECUTION_MODE="plan-based"

echo "Execution Mode: Plan-based delegation with wave-based orchestration"
```

**Key Insight**: Plan-based mode means the coordinator extracts wave structure from plan metadata (`dependencies: []` fields), **not** from dependency-analyzer.sh invocation.

**Source**: `.claude/commands/lean-implement.md` lines 294-300

### 2.2 Coordinator Delegation Pattern

The `/lean-implement` command uses the same hard barrier pattern as `/implement`:

```markdown
## Block 1b: Route to Coordinator [HARD BARRIER]

**CRITICAL BARRIER**: This block MUST invoke coordinator via Task tool.
Verification block (1c) will FAIL if summary not created.

**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation phases via implementer-coordinator"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    **Input Contract (Hard Barrier Pattern)**:
    - plan_path: ${PLAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - summaries_dir: ${SUMMARIES_DIR}
    - artifact_paths:
      - summaries: ${SUMMARIES_DIR}
      - debug: ${DEBUG_DIR}
      - outputs: ${OUTPUTS_DIR}
      - checkpoints: ${CHECKPOINTS_DIR}

    Execute implementation according to behavioral guidelines.
  "
}
```

**Source**: `.claude/commands/lean-implement.md` (inferred from research into Spec 051, 065)

### 2.3 lean-coordinator Brief Summary Format

The lean-coordinator agent returns brief summary with metadata fields:

```markdown
coordinator_type: lean
summary_brief: "Completed Wave 1-2 (Phase 1,2) with 15 theorems. Context: 72%. Next: Continue Wave 3."
phases_completed: [1, 2]
theorem_count: 15
work_remaining: Phase_3 Phase_4
context_exhausted: false
context_usage_percent: 72
requires_continuation: true
```

**Context Reduction**: 80 tokens (brief summary) vs 2,000 tokens (full content) = **96% reduction**

**Source**: `.claude/agents/lean-coordinator.md` lines 732-779

---

## 3. Pattern A (Orchestrator Mode) Analysis

### 3.1 Pattern A Definition

From research report 004 (Pattern A Consistency Analysis), the recommended architecture is:

**Pattern A (Orchestrator Mode)**:
- Extract coordinator logic to sourced library (`.claude/lib/coordination/research-orchestrator.sh`)
- Primary agent executes coordinator logic inline (deterministic code, no LLM reasoning)
- Specialists invoked via single-level Task (no nesting: primary → specialist)

**Benefits**:
1. Eliminates nesting depth constraint (from 2 levels to 1 level)
2. Preserves all coordination logic (parallelization, aggregation, error handling)
3. Deterministic execution (coordinator logic runs as bash code, not LLM interpretation)
4. Lowest token overhead (no coordinator LLM reasoning, only specialist work)

**Source**: `.claude/specs/063_lean_plan_coordinator_delegation/reports/004-pattern-a-consistency-analysis.md`

### 3.2 Pattern A Consistency Requirements

Based on Spec 065 (Lean Coordinator Wave Optimization), Pattern A must enforce:

1. **Brief Summary Format**: Aggregation returns 80 tokens (metadata fields), not 2,000 tokens (full content)
2. **Deterministic Logic**: No LLM reasoning in library functions - complexity directly maps to topic count
3. **Sequential-by-Default**: Parallel specialist invocation requires explicit flag (fail-safe for low complexity)

**Alignment with /implement**:
- ✓ Brief summary format matches implementer-coordinator pattern (96% context reduction)
- ✓ Deterministic logic eliminates coordinator LLM token consumption
- ✓ Sequential-by-default provides fail-safe execution mode

**Source**: `.claude/specs/063_lean_plan_coordinator_delegation/reports/004-pattern-a-consistency-analysis.md` lines 63-79

### 3.3 Industry Pattern Support

Research into multi-agent frameworks (Report 066) confirmed Pattern A alignment:

- **Google ADK's AgentTool Pattern**: Parent agent inlines coordination logic, invokes workers directly
- **Anthropic's Lead Agent Pattern**: Lead maintains control rather than delegating to intermediate subprocess
- **Microsoft's Magentic Manager**: Coordinates specialized agents directly without deep nesting

**Key Quote**: "Pattern A preserves all coordinator orchestration logic while eliminating nesting constraint. Pattern B (Direct Specialist) would lose orchestration logic and require reimplementation."

**Source**: `.claude/specs/066_pattern_tradeoff_comparison/reports/001-orchestrator-vs-direct-invocation-patterns.md`

---

## 4. Existing Infrastructure Analysis

### 4.1 State Machine Library

**Library**: `.claude/lib/workflow/workflow-state-machine.sh`

**Key Functions Used by /implement**:
- `sm_init()` - Initialize workflow state with plan path, command name, workflow type
- `sm_transition()` - Transition to new state with fail-fast validation
- `save_completed_states_to_state()` - Persist state transitions to state file

**Integration Pattern**:
```bash
# Initialize state machine
sm_init "$PLAN_FILE" "$COMMAND_NAME" "$WORKFLOW_TYPE" "1" "[]" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State machine initialization failed" \
    "bash_block_1" \
    "$(jq -n --arg type "$WORKFLOW_TYPE" --arg plan "$PLAN_FILE" \
       '{workflow_type: $type, plan_file: $plan}')"

  echo "ERROR: State machine initialization failed" >&2
  exit 1
fi
```

**Recommendation**: lean-plan should use identical state machine integration pattern for consistency.

### 4.2 Error Handling Library

**Library**: `.claude/lib/core/error-handling.sh`

**Key Functions Used by /implement**:
- `ensure_error_log_exists()` - Initialize error log file
- `log_command_error()` - Log structured errors with workflow context
- `setup_bash_error_trap()` - Install error trap for uncaught failures

**Integration Pattern**:
```bash
# Initialize error logging
ensure_error_log_exists

# Setup error trap with workflow context
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Log errors with structured details
log_command_error \
  "$COMMAND_NAME" \
  "$WORKFLOW_ID" \
  "$USER_ARGS" \
  "validation_error" \
  "Summary file too small (agent may have failed during write)" \
  "bash_block_1c" \
  "$(jq -n --arg path "$LATEST_SUMMARY" --argjson size "$SUMMARY_SIZE" \
     '{summary_path: $path, size_bytes: $size, min_required: 100}')"
```

**Recommendation**: lean-plan should adopt identical error logging pattern for queryable debugging.

### 4.3 Checkpoint Utilities Library

**Library**: `.claude/lib/workflow/checkpoint-utils.sh`

**Key Functions Used by /implement**:
- `load_checkpoint()` - Load saved checkpoint for resumption
- `delete_checkpoint()` - Cleanup checkpoint after completion

**Integration Pattern**:
```bash
# Check for checkpoint resumption
CHECKPOINT_DATA=$(load_checkpoint "implement" 2>/dev/null || echo "")

if [ -n "$CHECKPOINT_DATA" ]; then
  PLAN_FILE=$(echo "$CHECKPOINT_DATA" | jq -r '.plan_path')
  STARTING_PHASE=$(echo "$CHECKPOINT_DATA" | jq -r '.current_phase')
  echo "Auto-resuming from checkpoint: Phase $STARTING_PHASE"
fi

# Cleanup checkpoint after completion
delete_checkpoint "implement" 2>/dev/null || true
```

**Recommendation**: lean-plan should support checkpoint resumption for partial research completion scenarios.

### 4.4 Validation Utilities Library

**Library**: `.claude/lib/workflow/validation-utils.sh`

**Key Functions Used by /implement**:
- `validate_workflow_prerequisites()` - Pre-flight validation of library functions
- `validate_state_restoration()` - Verify critical variables after state load
- `validate_agent_artifact()` - Check subagent output files

**Integration Pattern**:
```bash
# Pre-flight validation
if ! validate_workflow_prerequisites; then
  echo "FATAL: Pre-flight validation failed - cannot proceed" >&2
  exit 1
fi

# State restoration validation
validate_state_restoration "PLAN_FILE" "TOPIC_PATH" "MAX_ITERATIONS" "SUMMARIES_DIR" || {
  echo "ERROR: State restoration failed - critical variables missing" >&2
  exit 1
}

# Agent artifact validation
if ! validate_agent_artifact "$LATEST_SUMMARY" 100 "implementation summary"; then
  echo "ERROR: Summary validation failed" >&2
  exit 1
fi
```

**Recommendation**: lean-plan should use validation-utils for consistent artifact checking.

---

## 5. Hierarchical Agents Pattern Documentation

### 5.1 Example 7: Research Coordinator Pattern

From `.claude/docs/concepts/hierarchical-agents-examples.md` Example 7:

**Architecture**:
```
/lean-plan Primary Agent
    |
    +-- research-coordinator (Supervisor)
            +-- research-specialist 1 (Mathlib Theorems)
            +-- research-specialist 2 (Proof Automation)
            +-- research-specialist 3 (Project Structure)
```

**Context Reduction**:
- Traditional: 3 reports × 2,500 tokens = 7,500 tokens
- Coordinator: 3 reports × 110 tokens metadata = 330 tokens
- **Reduction: 95.6%**

**Hard Barrier Validation**:
```bash
# Fail-fast if any pre-calculated report path missing
MISSING_REPORTS=()
for REPORT_PATH in "${REPORT_PATHS[@]}"; do
  if [[ ! -f "$REPORT_PATH" ]]; then
    MISSING_REPORTS+=("$REPORT_PATH")
  fi
done

if [[ ${#MISSING_REPORTS[@]} -gt 0 ]]; then
  log_command_error "validation_error" \
    "${#MISSING_REPORTS[@]} research reports missing after coordinator invocation" \
    "Missing reports: ${MISSING_REPORTS[*]}"
  echo "ERROR: Hard barrier validation failed"
  exit 1
fi
```

**Source**: `.claude/docs/concepts/hierarchical-agents-examples.md` lines 686-708

### 5.2 Example 8: Lean Command Coordinator Optimization

From `.claude/docs/concepts/hierarchical-agents-examples.md` Example 8:

**Integration Results**:
- `/lean-plan`: research-coordinator for parallel multi-topic Lean research (95% context reduction)
- `/lean-implement`: implementer-coordinator for wave-based orchestration (96% context reduction)
- **Validation**: 48 tests, 100% pass rate (21 lean-plan + 27 lean-implement)

**Brief Summary Pattern**:
```bash
# Parse brief summary fields (96% context reduction)
SUMMARY_BRIEF=$(grep "^summary_brief:" "$LATEST_SUMMARY" | sed 's/^summary_brief:[[:space:]]*//')
PHASES_COMPLETED=$(grep "^phases_completed:" "$LATEST_SUMMARY" | sed 's/^phases_completed:[[:space:]]*//' | tr -d '[],"')
CONTEXT_USAGE_PERCENT=$(grep "^context_usage_percent:" "$LATEST_SUMMARY" | sed 's/^context_usage_percent:[[:space:]]*//' | sed 's/%//')
WORK_REMAINING=$(grep "^work_remaining:" "$LATEST_SUMMARY" | sed 's/^work_remaining:[[:space:]]*//')
```

**Source**: `.claude/docs/concepts/hierarchical-agents-examples.md` lines 1113-1136

---

## 6. Critical Patterns for lean-plan Revision

### 6.1 Pattern A Implementation Requirements

Based on all research findings, the lean-plan coordinator delegation revision must implement:

**1. Research Orchestrator Library**:
- Location: `.claude/lib/coordination/research-orchestrator.sh`
- Functions:
  - `decompose_research_topics()` - Deterministic topic splitting (complexity → topic count)
  - `generate_specialist_prompts()` - Create Task prompts for specialists
  - `aggregate_research_results()` - Brief summary format (80 tokens target)
  - `orchestrate_research()` - Main entry point (sequential-by-default)
  - `save_research_checkpoint()` - Checkpoint support for partial completion

**2. lean-plan Command Integration**:
- Block 1e: Source orchestrator library, call `orchestrate_research()`
- Block 1e-exec: Sequential specialist Task invocations (default)
- Block 1f: Hard barrier validation with pre-calculated report paths
- Block 1f-metadata: Parse brief summary metadata (95% context reduction)

**3. Brief Summary Format**:
```bash
# Coordinator library returns (80 tokens target)
coordinator_type: research
summary_brief: "Completed 3/3 research reports. Topics: Mathlib, Proofs, Structure."
reports_completed: [1, 2, 3]
reports_total: 3
research_status: complete
report_dir: /path/to/reports
```

**4. Deterministic Topic Decomposition**:
```bash
# Complexity → topic count mapping (no LLM reasoning)
case "$complexity" in
  1) topic_count=2 ;;
  2) topic_count=3 ;;
  3) topic_count=4 ;;
  4) topic_count=5 ;;
esac
```

**5. Sequential-by-Default Execution**:
```bash
# Default: sequential (one specialist at a time)
orchestrate_research "$FEATURE" "$COMPLEXITY" "$REPORT_DIR" "false"

# Parallel mode requires explicit flag AND complexity >= 3
[ "$COMPLEXITY" -ge 3 ] && orchestrate_research "$FEATURE" "$COMPLEXITY" "$REPORT_DIR" "true"
```

### 6.2 State Machine Integration Pattern

Adopt `/implement` state machine pattern for consistency:

```bash
# Block 1a: State transition to RESEARCH
sm_transition "$STATE_RESEARCH" "plan loaded, starting research" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to RESEARCH failed" \
    "bash_block_1a" \
    "$(jq -n --arg state "RESEARCH" '{target_state: $state}')"

  echo "ERROR: State transition to RESEARCH failed" >&2
  exit 1
fi
```

### 6.3 Hard Barrier Validation Pattern

Adopt `/implement` verification block pattern:

```bash
# Block 1f: Hard barrier validation (fail-fast)
if [[ ! -d "$RESEARCH_DIR" ]]; then
  log_command_error "validation_error" \
    "Research directory not found: $RESEARCH_DIR" \
    "research-orchestrator should have created this directory"
  echo "ERROR: Research validation failed"
  exit 1
fi

# Validate all pre-calculated report paths
MISSING_REPORTS=()
for REPORT_PATH in "${REPORT_PATHS[@]}"; do
  if [[ ! -f "$REPORT_PATH" ]]; then
    MISSING_REPORTS+=("$REPORT_PATH")
  fi
done

if [[ ${#MISSING_REPORTS[@]} -gt 0 ]]; then
  log_command_error "validation_error" \
    "${#MISSING_REPORTS[@]} research reports missing" \
    "Missing: ${MISSING_REPORTS[*]}"
  exit 1
fi
```

### 6.4 Error Logging Integration Pattern

Adopt `/implement` error logging pattern:

```bash
# Initialize error logging
ensure_error_log_exists

# Setup error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Log all failures with structured context
log_command_error \
  "$COMMAND_NAME" \
  "$WORKFLOW_ID" \
  "$USER_ARGS" \
  "agent_error" \
  "research-orchestrator failed to create reports" \
  "bash_block_1f" \
  "$(jq -n --arg dir "$RESEARCH_DIR" --argjson missing "${#MISSING_REPORTS[@]}" \
     '{research_dir: $dir, missing_count: $missing}')"
```

---

## 7. Implementation Recommendations

### 7.1 Phase Sequencing

Based on research findings, implement in this order:

**Phase 1: Research Orchestrator Library**
- Create `.claude/lib/coordination/research-orchestrator.sh`
- Implement all 5 functions with Pattern A consistency
- Add unit tests for deterministic behavior validation

**Phase 2: lean-plan Command Integration**
- Update Block 1e to source orchestrator library
- Replace coordinator Task invocation with inline orchestration
- Implement sequential specialist invocation loop

**Phase 3: Specialist Task Invocation and Validation**
- Create Block 1e-exec with specialist Task invocations
- Add hard barrier validation with pre-calculated paths
- Implement brief summary parsing (80 tokens target)

**Phase 4: Architecture Documentation and Testing**
- Create ADR: `.claude/docs/architecture/adr/002-orchestrator-mode-adoption.md`
- Document Pattern A consistency with Spec 065
- Re-execute lean-plan with validation

### 7.2 Success Criteria Validation

Based on `/implement` patterns, validation must verify:

1. **Library Function Tests**:
   - `decompose_research_topics()` deterministic (same input → same output)
   - `aggregate_research_results()` brief format (< 100 tokens)
   - `orchestrate_research()` sequential-by-default (parallel requires flag)

2. **Integration Tests**:
   - lean-plan sources library successfully
   - Specialist Task invocations generated correctly
   - Hard barrier validation catches missing reports
   - Brief summary parsing works (metadata fields only)

3. **Context Reduction**:
   - Target: ~500 tokens total (down from ~15,000 tokens)
   - Metadata-only parsing: 80 tokens per report (vs 2,500 full content)
   - Context reduction: 95-96% (aligned with /implement pattern)

4. **Pattern A Consistency**:
   - Brief summary format matches lean-coordinator pattern
   - Topic decomposition is deterministic (no LLM reasoning)
   - Sequential execution by default (parallel only for complexity >= 3)

### 7.3 Risk Mitigation

Based on `/implement` reliability patterns:

1. **Pre-flight Validation**: Use `validate_workflow_prerequisites()` before any coordination
2. **State Restoration Checks**: Use `validate_state_restoration()` after state load
3. **Artifact Validation**: Use `validate_agent_artifact()` for all specialist outputs
4. **Error Trap Handler**: Use `setup_bash_error_trap()` for uncaught failures
5. **Checkpoint Support**: Use `save_research_checkpoint()` for partial completion scenarios

---

## 8. Comparison Matrix: /implement vs lean-plan (Current vs Proposed)

| Pattern | /implement | lean-plan (Current) | lean-plan (Proposed) |
|---------|-----------|---------------------|----------------------|
| **Architecture** | Hard barrier (3-block) | Direct coordinator Task | Pattern A (orchestrator library) |
| **Delegation** | implementer-coordinator | research-coordinator | research-orchestrator.sh (inline) |
| **Nesting** | 1 level (primary → coordinator) | 2 levels (primary → coordinator → specialist) | 1 level (primary → specialist) |
| **Context Reduction** | 96% (brief summary) | ~0% (full reports read) | 95% (metadata-only) |
| **State Machine** | ✓ Integrated | ✗ Missing | ✓ Integrated (proposed) |
| **Error Logging** | ✓ Structured | ✗ Minimal | ✓ Structured (proposed) |
| **Checkpoint Support** | ✓ Yes | ✗ No | ✓ Yes (proposed) |
| **Validation Pattern** | Hard barrier (fail-fast) | Soft checks (warnings) | Hard barrier (fail-fast, proposed) |
| **Specialist Invocation** | Coordinator delegates | Coordinator delegates | Primary delegates (proposed) |
| **Deterministic Logic** | ✓ Yes (state machine) | ✗ No (LLM reasoning) | ✓ Yes (library functions, proposed) |
| **Sequential-by-Default** | ✓ Yes (wave-based) | ✗ No (always parallel) | ✓ Yes (flag required, proposed) |

**Key Insight**: The proposed Pattern A architecture aligns lean-plan with `/implement` reliability patterns while preserving coordinator orchestration logic.

---

## 9. Action Items for Plan Revision

Based on research findings, the lean-plan coordinator delegation plan (Spec 063) should be revised to:

1. **Adopt Pattern A (Orchestrator Mode)**:
   - Extract coordinator logic to `.claude/lib/coordination/research-orchestrator.sh`
   - Primary agent executes coordination inline (no nested Task invocation)
   - Specialists invoked via single-level Task (primary → specialist)

2. **Implement Pattern A Consistency**:
   - Brief summary format (80 tokens metadata)
   - Deterministic logic (no LLM reasoning in library)
   - Sequential-by-default (parallel requires explicit flag)

3. **Integrate State Machine Pattern**:
   - Use `sm_init()`, `sm_transition()`, `save_completed_states_to_state()`
   - Adopt `/implement` fail-fast error handling pattern
   - Add state restoration validation after cross-block state loads

4. **Implement Hard Barrier Validation**:
   - Pre-calculate report paths before specialist invocation
   - Validate all paths exist after specialists complete (fail-fast)
   - Use `validate_agent_artifact()` for artifact size/content checks

5. **Add Error Logging Integration**:
   - Use `ensure_error_log_exists()`, `setup_bash_error_trap()`
   - Log all failures with `log_command_error()` and structured details
   - Enable `/errors` command queryability for debugging

6. **Implement Checkpoint Support**:
   - Use `save_research_checkpoint()` for partial completion
   - Support resumption via `load_checkpoint()`
   - Enable graceful degradation for ≥50% report completion

7. **Document Pattern A Adoption**:
   - Create ADR: `.claude/docs/architecture/adr/002-orchestrator-mode-adoption.md`
   - Update hierarchical-agents-examples.md with Pattern A example
   - Document consistency with Spec 065 (lean-coordinator brief summary format)

---

## 10. Conclusion

The `/implement` command demonstrates proven delegation patterns that should inform the lean-plan coordinator revision:

1. **Hard Barrier Pattern**: 3-block structure (Setup → Execute → Verify) prevents delegation bypass
2. **Brief Summary Aggregation**: 96% context reduction via metadata-only parsing
3. **State Machine Integration**: Fail-fast validation with structured error logging
4. **Pattern A Architecture**: Orchestrator library eliminates nesting while preserving coordination logic

The **recommended approach** is to adopt **Pattern A (Orchestrator Mode)** with full consistency to Spec 065 patterns:
- Brief summary format (80 tokens)
- Deterministic logic (no LLM reasoning)
- Sequential-by-default execution (parallel requires explicit flag)

This approach aligns lean-plan with `/lean-implement` compatibility requirements while maintaining the proven reliability patterns of `/implement`.

---

## Appendix A: Code References

**Key Files Analyzed**:
1. `.claude/commands/implement.md` - Hard barrier pattern, state machine integration
2. `.claude/commands/lean-implement.md` - Plan-based mode, coordinator delegation
3. `.claude/agents/lean-coordinator.md` - Brief summary format, plan metadata extraction
4. `.claude/specs/063_lean_plan_coordinator_delegation/plans/001-lean-plan-coordinator-delegation-plan.md` - Original plan (Pattern A architecture)
5. `.claude/specs/063_lean_plan_coordinator_delegation/reports/004-pattern-a-consistency-analysis.md` - Pattern A consistency requirements
6. `.claude/docs/concepts/hierarchical-agents-examples.md` - Example 7 (research coordinator), Example 8 (lean commands)

**Library Infrastructure**:
- `.claude/lib/workflow/workflow-state-machine.sh` - State transitions
- `.claude/lib/core/error-handling.sh` - Structured error logging
- `.claude/lib/workflow/checkpoint-utils.sh` - Checkpoint save/load
- `.claude/lib/workflow/validation-utils.sh` - Artifact validation

---

## Appendix B: Pattern A vs Pattern B Comparison

**Pattern A (Orchestrator Mode)** - RECOMMENDED:
- Coordinator logic extracted to library (deterministic bash code)
- Primary agent executes inline coordination
- Specialists invoked via single-level Task (no nesting)
- Preserves all orchestration logic (parallelization, aggregation)
- 96% context reduction via brief summary parsing
- Deterministic execution (no LLM reasoning overhead)

**Pattern B (Direct Specialist Invocation)** - NOT RECOMMENDED:
- No coordinator entity (logic inlined in primary agent)
- Primary agent invokes specialists directly
- Loses orchestration abstraction (code duplication risk)
- No brief summary aggregation (primary reads full reports)
- Higher token consumption (no metadata-only optimization)

**Decision**: Pattern A is superior for lean-plan because:
1. Preserves valuable coordination logic (topic decomposition, parallel invocation, result aggregation)
2. Eliminates nested Task constraint while maintaining architecture
3. Aligns with industry patterns (Google ADK, Anthropic, Microsoft)
4. Enables deterministic execution (bash code vs LLM reasoning)

---

**REPORT_CREATED**: /home/benjamin/.config/.claude/specs/063_lean_plan_coordinator_delegation/reports/5-lean_implement_compatibility_research.md
