# Research Report: /lean-implement Command Analysis

## Metadata
- **Date**: 2025-12-08
- **Topic**: /lean-implement command shortcomings and coordinator integration opportunities
- **Complexity**: 3

## Findings

### Finding 1: Primary Agent Performing Direct Implementation Work (Critical)
**Problem**: The /lean-implement orchestrator performs implementation work directly in Block 1b instead of delegating to coordinators.

**Evidence**: From lean-implement-output.md (lines 30-176), the primary agent directly:
- Reads the plan file (406 lines, line 34)
- Reads Tactics.lean source (529 lines, line 40)
- Reads TacticsTest.lean (670 lines, line 56)
- Runs lake build and lake test (lines 76-84)
- Updates the plan file status markers (lines 107-174)
- Updates TACTIC_DEVELOPMENT.md (lines 176-420)
- Updates CLAUDE.md (lines 320-420)

**Impact**:
- Context window consumption: ~3,000+ tokens for file reads + modifications
- Violates separation of concerns (orchestrator doing implementation)
- Bypasses coordinator delegation pattern
- No hard barrier validation (summary file check happens but after self-implementation)

### Finding 2: Hard Barrier Pattern Not Enforced
**Problem**: The command has hard barrier validation in Block 1c (lines 861-909 in lean-implement.md), but the actual execution (lean-implement-output.md) shows the primary agent bypassed coordinator delegation entirely.

**Evidence**:
- Block 1b (lines 598-810 in lean-implement.md) shows Task tool invocation for coordinators
- But lean-implement-output.md shows no Task tool invocation in the actual run
- The primary agent went directly from "routing to implementer-coordinator" (line 30) to reading files and implementing

**Impact**:
- Hard barrier pattern exists in design but isn't enforced at runtime
- No fail-fast detection when coordinator delegation is bypassed
- Orchestrator context exhaustion from direct implementation

### Finding 3: No Research Coordinator Integration
**Problem**: The /lean-implement command lacks integration with research-coordinator for multi-topic research orchestration.

**Evidence**:
- lean-implement.md shows no research phase (only Block 1a/1a-classify/1b/1c/1d/2)
- research-coordinator.md (lines 1-635) demonstrates supervisor-based parallel research with 95% context reduction
- /lean-plan command (from docs) integrates research-coordinator, but /lean-implement does not

**Comparison with /lean-plan integration pattern**:
```yaml
# /lean-plan has research phase BEFORE planning
Block 1: Research Phase
  -> invoke research-coordinator
  -> receive aggregated metadata (110 tokens per report vs 2,500 full content)

Block 2: Planning Phase
  -> use research report paths (not content)
  -> lean-plan-architect references reports
```

**Impact**:
- No upfront research capability for implementation decisions
- Cannot parallelize multi-topic investigation (e.g., "investigate Mathlib, proof strategies, project patterns")
- Missing 95% context reduction benefit from metadata-only passing

### Finding 4: Missing Implementer-Coordinator for Software Phases
**Problem**: The command routes to "implementer-coordinator" but actual execution suggests this agent may not exist or isn't being invoked correctly.

**Evidence**:
- lean-implement-output.md shows routing decision (line 30) but no Task tool invocation
- implementer-coordinator.md exists (Read result shows 975 lines) and defines wave-based orchestration
- Gap: Primary agent performed work instead of delegating to implementer-coordinator

**Impact**:
- Software phases don't benefit from wave-based parallel execution
- No phase dependency analysis (lines 86-127 in implementer-coordinator.md)
- Missing 40-60% time savings from parallel phase execution

### Finding 5: Context Window Consumption from Sequential File Operations
**Problem**: The primary agent performs multiple large file reads sequentially during implementation.

**Evidence** (from lean-implement-output.md):
- Line 34: Read 406-line plan file
- Line 40: Read 529-line Tactics.lean
- Line 56: Read 670-line TacticsTest.lean
- Line 94: Read 738-line TACTIC_DEVELOPMENT.md
- Line 306: Read 100-line CLAUDE.md (then line 317 for partial re-read)
- Total: ~2,443 lines read = estimated 6,000-8,000 tokens

**Impact**:
- High orchestrator context consumption (30-40% of 200k window)
- Violates "coordinator receives paths, not content" pattern (hierarchical-agents-overview.md, line 51-58)
- Prevents multi-iteration workflows due to context pressure

### Finding 6: Iteration Management Without Coordinator Context Tracking
**Problem**: The command has iteration management logic (Block 1c, lines 1091-1148 in lean-implement.md) but coordinators don't report context usage for aggregation.

**Evidence**:
- lean-implement.md defines CONTEXT_THRESHOLD (line 30, default 90%)
- Block 1c parses `context_usage_percent` from summary (line 1000)
- But implementer-coordinator.md shows context estimation is coordinator-internal (lines 142-189), not reported to orchestrator

**Comparison with research-coordinator pattern**:
- research-coordinator.md doesn't report context usage (returns metadata only)
- Coordinator context is "firewall" - doesn't propagate to orchestrator

**Impact**:
- Orchestrator cannot make informed continuation decisions
- Context threshold enforcement relies on incomplete data
- Risk of context exhaustion without early warning

### Finding 7: Phase Marker Recovery Duplicates Coordinator Responsibility
**Problem**: Block 1d (lines 1153-1271 in lean-implement.md) performs phase marker validation and recovery, but this should be coordinator's responsibility.

**Evidence**:
- implementer-coordinator.md defines "Phase Marker Validation" (lines 344-385)
- But lean-implement.md also validates markers in Block 1d (lines 1200-1245)
- Double validation = wasted context + unclear ownership

**Impact**:
- Duplication of validation logic across layers
- Orchestrator context consumed for coordinator-level concerns
- Marker recovery race condition (coordinator vs orchestrator)

### Finding 8: Brief Summary Pattern Incompletely Implemented
**Problem**: The command parses `summary_brief` field (line 956-962 in lean-implement.md) but actual execution shows full file reads.

**Evidence**:
- lean-implement.md Block 1c defines brief summary parsing (lines 936-1004)
- Claims 96% context reduction (80 tokens vs 2,000 tokens, line 1020)
- But lean-implement-output.md shows no summary file parsing at all (primary agent did the work)

**Impact**:
- Context reduction benefit unrealized (0% vs promised 96%)
- Orchestrator reads full implementation artifacts instead of metadata
- No metadata-only passing between coordinator and orchestrator

### Finding 9: State Machine Integration Without Wave Orchestration
**Problem**: The command uses state machine (STATE_IMPLEMENT transition, line 280 in lean-implement.md) but doesn't leverage wave-based orchestration.

**Evidence**:
- lean-implement.md initializes workflow state machine (lines 245-293)
- But no wave structure analysis (missing dependency-analyzer invocation)
- implementer-coordinator.md shows wave orchestration (lines 248-436) but isn't invoked

**Comparison with implementer-coordinator pattern**:
```bash
# implementer-coordinator STEP 2: Dependency Analysis
bash dependency-analyzer.sh "$plan_path" > dependency_analysis.json
# Extracts: wave structure, parallelization metrics, time savings
```

**Impact**:
- No parallel phase execution (40-60% time savings missed)
- Sequential execution even for independent phases
- State machine underutilized (no wave transitions)

### Finding 10: Routing Map Construction Without Coordinator Metadata
**Problem**: Block 1a-classify builds routing map (lines 475-596 in lean-implement.md) but doesn't pre-calculate artifact paths for coordinators.

**Evidence**:
- Routing map format: `phase_num:type:lean_file:implementer` (line 557)
- Missing: summaries_dir, debug_dir paths for coordinator invocation
- research-coordinator.md requires pre-calculated report_paths (lines 19-42)

**Comparison with research-coordinator hard barrier pattern**:
```markdown
# Primary agent MUST pre-calculate paths BEFORE invoking coordinator
REPORT_PATHS=("${REPORT_DIR}/001-topic1.md" "${REPORT_DIR}/002-topic2.md")
# Coordinator validates these paths exist AFTER agent returns
```

**Impact**:
- Coordinators receive incomplete input contract
- No hard barrier path validation possible
- Summary files created in unpredictable locations

## Recommendations

### 1. Implement Research-Coordinator Integration (High Priority)
**Recommendation**: Add research phase BEFORE implementation phase, following /lean-plan pattern.

**Implementation**:
```markdown
## Block 0: Research Phase (NEW)

**EXECUTE NOW**: If plan has research topics, invoke research-coordinator

Task {
  subagent_type: "general-purpose"
  model: "sonnet"
  description: "Parallel research coordination for implementation context"
  prompt: |
    Read and follow: .claude/agents/research-coordinator.md

    research_request: "${RESEARCH_REQUEST}"
    research_complexity: ${COMPLEXITY}
    report_dir: ${TOPIC_PATH}/reports/
    topic_path: ${TOPIC_PATH}
    context: { feature_description: "...", plan_path: "..." }
}

# Coordinator returns aggregated metadata (110 tokens per report)
# Pass report paths to implementer-coordinator, NOT content
```

**Benefits**:
- 95% context reduction via metadata-only passing
- Parallel research (40-60% time savings for 3+ topics)
- Implementation decisions informed by upfront research

### 2. Enforce Hard Barrier Pattern in Block 1b (Critical)
**Recommendation**: Make coordinator invocation MANDATORY, add fail-fast validation.

**Implementation**:
```markdown
## Block 1b: Route to Coordinator [HARD BARRIER]

# STEP 1: Pre-calculate artifact paths
SUMMARIES_DIR="${TOPIC_PATH}/summaries"
DEBUG_DIR="${TOPIC_PATH}/debug"
mkdir -p "$SUMMARIES_DIR" "$DEBUG_DIR"

# STEP 2: Persist coordinator name for Block 1c validation
append_workflow_state "COORDINATOR_NAME" "$COORDINATOR_NAME"

# STEP 3: Invoke coordinator (NO conditionals, ALWAYS delegate)
**EXECUTE NOW**: USE the Task tool to invoke ${COORDINATOR_NAME}

# STEP 4: Block 1c validates summary file exists (fail-fast if missing)
if [ ! -f "$LATEST_SUMMARY" ]; then
  log_command_error ... "agent_error" \
    "Coordinator $COORDINATOR_NAME did not create summary (delegation bypass)"
  exit 1
fi
```

**Benefits**:
- Prevents orchestrator from doing implementation work
- Fail-fast detection of delegation bypass
- Clear error diagnostics (coordinator name in error message)

### 3. Integrate Wave-Based Orchestration via implementer-coordinator (High Priority)
**Recommendation**: Ensure implementer-coordinator is invoked for software phases with dependency analysis.

**Implementation**:
```markdown
# In Block 1b, when routing to implementer-coordinator:
Task {
  prompt: |
    Read and follow: .claude/agents/implementer-coordinator.md

    # Input Contract (ALL required):
    plan_path: ${PLAN_FILE}
    topic_path: ${TOPIC_PATH}
    artifact_paths:
      summaries: ${SUMMARIES_DIR}
      debug: ${DEBUG_DIR}
      outputs: ${OUTPUTS_DIR}
      checkpoints: ${CHECKPOINTS_DIR}

    # CRITICAL: Coordinator will:
    # 1. Run dependency-analyzer.sh on plan
    # 2. Build wave structure
    # 3. Invoke implementation-executor for each phase in parallel
    # 4. Return metadata-only summary
}
```

**Benefits**:
- 40-60% time savings from parallel phase execution
- Dependency analysis ensures correctness
- Wave-based progress tracking

### 4. Remove Phase Marker Recovery from Orchestrator (Medium Priority)
**Recommendation**: Delete Block 1d, delegate marker validation to coordinators.

**Justification**:
- implementer-coordinator already validates markers (lines 344-385)
- Orchestrator should only verify final plan status, not individual phases
- Reduces orchestrator context consumption

**Implementation**:
```markdown
# DELETE Block 1d entirely

# In Block 2 (Completion), add lightweight validation:
if type check_all_phases_complete &>/dev/null; then
  check_all_phases_complete "$PLAN_FILE" && PLAN_COMPLETE=true || PLAN_COMPLETE=false
fi
# Trust coordinators did marker updates, don't recover
```

### 5. Implement Brief Summary Parsing (Medium Priority)
**Recommendation**: Parse summary metadata from coordinator return signals, not file reads.

**Implementation**:
```bash
# In Block 1c, parse return signal fields (NOT file content)
SUMMARY_BRIEF=$(grep "^summary_brief:" <<< "$COORDINATOR_OUTPUT" | sed 's/^summary_brief:[[:space:]]*//')
PHASES_COMPLETED=$(grep "^phases_completed:" <<< "$COORDINATOR_OUTPUT" | tr -d '[],"')
CONTEXT_USAGE=$(grep "^context_usage_percent:" <<< "$COORDINATOR_OUTPUT" | sed 's/%//')

# Display brief summary (no full file read)
echo "Summary: $SUMMARY_BRIEF"
echo "Phases completed: $PHASES_COMPLETED"
echo "Context usage: ${CONTEXT_USAGE}%"

# Full report path for user reference only
echo "Full report: $LATEST_SUMMARY"
```

**Benefits**:
- 96% context reduction (80 tokens vs 2,000 tokens)
- Enables multi-iteration workflows (10+ iterations possible)
- Follows research-coordinator metadata-only pattern

### 6. Add Coordinator Context Reporting Contract (Low Priority)
**Recommendation**: Extend coordinator output contract to include context usage for aggregation.

**Implementation**:
```yaml
# Add to implementer-coordinator.md output format (line 613):
IMPLEMENTATION_COMPLETE:
  # ... existing fields ...
  context_usage_percent: ${CONTEXT_PERCENT}  # NEW: Report context usage
  context_exhausted: true|false               # NEW: Early warning signal
```

**Coordinator implementation**:
```bash
# In implementer-coordinator, estimate context usage:
CONTEXT_ESTIMATE=$(estimate_context_usage "$COMPLETED_PHASES" "$REMAINING_PHASES" "$HAS_CONTINUATION")
CONTEXT_PERCENT=$((CONTEXT_ESTIMATE * 100 / 200000))
```

**Benefits**:
- Orchestrator makes informed continuation decisions
- Context threshold enforcement with accurate data
- Early warning for context pressure

### 7. Pre-Calculate All Artifact Paths in Block 1a (Medium Priority)
**Recommendation**: Calculate summaries_dir, debug_dir, outputs_dir paths BEFORE classifier, pass to coordinators.

**Implementation**:
```bash
# In Block 1a (after TOPIC_PATH calculation):
SUMMARIES_DIR="${TOPIC_PATH}/summaries"
DEBUG_DIR="${TOPIC_PATH}/debug"
OUTPUTS_DIR="${TOPIC_PATH}/outputs"
CHECKPOINTS_DIR="${HOME}/.claude/data/checkpoints"

mkdir -p "$SUMMARIES_DIR" "$DEBUG_DIR" "$OUTPUTS_DIR" "$CHECKPOINTS_DIR"

# Persist for Block 1b
append_workflow_state "SUMMARIES_DIR" "$SUMMARIES_DIR"
append_workflow_state "DEBUG_DIR" "$DEBUG_DIR"
append_workflow_state "OUTPUTS_DIR" "$OUTPUTS_DIR"
append_workflow_state "CHECKPOINTS_DIR" "$CHECKPOINTS_DIR"
```

**Benefits**:
- Coordinators receive complete input contract
- Hard barrier validation possible (pre-calculated paths)
- Consistent artifact organization

### 8. Simplify Iteration Logic with Coordinator Signals (Low Priority)
**Recommendation**: Replace orchestrator iteration management with coordinator signals (requires_continuation, work_remaining).

**Implementation**:
```bash
# In Block 1c, trust coordinator signals:
if [ "$REQUIRES_CONTINUATION" = "true" ] && [ -n "$WORK_REMAINING" ]; then
  NEXT_ITERATION=$((ITERATION + 1))
  echo "Continuing to iteration $NEXT_ITERATION (work remaining: $WORK_REMAINING)"
  # Loop back to Block 1b with updated state
else
  echo "Work complete or max iterations reached"
  # Proceed to Block 2 (Completion)
fi
```

**Benefits**:
- Simpler orchestrator logic
- Coordinators make context-aware continuation decisions
- Clearer separation of concerns

## Summary

The /lean-implement command has a well-designed architecture (hard barrier pattern, hybrid routing, iteration management) but the actual execution shows critical gaps in coordinator integration. The primary agent performs implementation work directly instead of delegating to coordinators, bypassing the hard barrier pattern and consuming excessive context.

**Top 3 Action Items**:
1. **Enforce hard barrier pattern** in Block 1b with fail-fast validation (prevents delegation bypass)
2. **Integrate research-coordinator** for upfront research phase (95% context reduction + parallelization)
3. **Ensure implementer-coordinator invocation** with wave-based orchestration (40-60% time savings)

These changes will align the implementation with the hierarchical agent architecture principles (metadata-only passing, parallel execution, clear boundaries) and unlock the full context efficiency benefits.

## References

**Files Examined**:
- `/home/benjamin/.config/.claude/output/lean-implement-output.md` (554 lines) - Actual execution log
- `/home/benjamin/.config/.claude/commands/lean-implement.md` (1,545 lines) - Command implementation
- `/home/benjamin/.config/.claude/agents/research-coordinator.md` (635 lines) - Supervisor pattern reference
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` (975 lines) - Wave orchestration reference
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md` (177 lines) - Architecture principles
- `/home/benjamin/.config/.claude/docs/guides/commands/lean-implement-command-guide.md` (545 lines) - Command documentation

**Documentation Referenced**:
- Hierarchical Agent Architecture Overview (hard barrier pattern, metadata-only passing)
- Research Coordinator Agent (95% context reduction via supervisor pattern)
- Implementer Coordinator Agent (wave-based parallel execution, 40-60% time savings)
- /lean-implement Command Guide (hybrid routing, iteration management, hard barrier validation)
