# Coordinator Research Delegation Patterns

## Executive Summary

Investigation of coordinator agent architecture reveals a critical limitation: coordinator agents declare Task tool access (`allowed-tools: Task`) and contain extensive Task invocation logic, but nested Task delegation (Task subprocess invoking another Task) may not be supported by the execution environment. This architectural mismatch explains why lean-plan skips research-coordinator delegation and performs research directly in the primary agent.

## Findings

### Finding 1: Coordinator Agents Require Nested Task Capability

**Architecture Analysis**: 10 coordinator agents declare Task tool access:
- research-coordinator.md
- lean-coordinator.md
- implementation-executor.md
- implementer-coordinator.md
- conversion-coordinator.md
- debug-coordinator.md
- research-sub-supervisor.md
- coordinator-template.md
- testing-coordinator.md
- repair-coordinator.md

**Common Pattern** (from grep results):
```yaml
allowed-tools: Task, Read, Bash, Grep
```

**Architectural Intent**: Coordinators receive high-level tasks from commands, decompose them, and invoke specialist agents via Task tool to perform actual work.

**Dependency Chain**:
```
Command (Primary Agent)
  └─ Task invocation → Coordinator Agent
       └─ Task invocation → Specialist Agent (e.g., research-specialist)
            └─ Performs actual work
```

**Critical Requirement**: This pattern REQUIRES nested Task invocations (depth 2).

### Finding 2: research-coordinator Assumes Nested Task Support

**Evidence from `/home/benjamin/.config/.claude/agents/research-coordinator.md`**:

**Lines 332-422**: STEP 3 "Invoke Parallel Research Workers" contains:
- Bash script to generate Task invocation blocks (lines 342-373)
- Loop over topics array generating concrete Task invocations (lines 358-409)
- Each iteration outputs an "**EXECUTE NOW**: USE the Task tool" directive
- Each Task block invokes research-specialist with absolute report path

**Example Generated Task Block** (lines 379-403):
```
**EXECUTE NOW (Topic 1/3)**: USE the Task tool to invoke research-specialist for this topic.

Task {
  subagent_type: "general-purpose"
  description: "Research topic: $TOPIC"
  prompt: "
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **CRITICAL - Hard Barrier Pattern**:
    REPORT_PATH=$REPORT_PATH

    **Research Topic**: $TOPIC
    ...
  "
}
```

**Assumption**: The coordinator agent assumes it can USE the Task tool to create subprocesses for each research-specialist invocation.

### Finding 3: Nested Task Invocation May Not Be Supported

**Experimental Evidence**: During this investigation, when operating in the context of research-coordinator agent:
- Behavioral guidelines direct: "USE the Task tool to invoke research-specialist"
- Attempts to execute Task tool reveal architectural limitation
- The Task tool creates isolated subprocesses—nested subprocess creation may not be supported

**Hypothesis**: The execution environment supports:
- ✅ Primary agent → Task subprocess (depth 1)
- ❌ Task subprocess → Nested Task subprocess (depth 2)

**Consequence**: If nested Tasks are unsupported:
- Coordinator agents CANNOT delegate to specialist agents
- Coordinator must either:
  - Perform work directly (violating coordinator role)
  - Return error indicating delegation not possible
  - OR be invoked differently by commands

### Finding 4: lean-plan Command Expects Mode 2 Delegation

**Evidence from `/home/benjamin/.config/.claude/commands/lean-plan.md` lines 994-1045**:

**Block 1e-exec** contains:
```
**EXECUTE NOW**: USE the Task tool to invoke the research-coordinator agent for parallel multi-topic research.

Task {
  subagent_type: "general-purpose"
  description: "Coordinate parallel Lean research across ${TOPIC_COUNT} topics"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    **Input Contract (Hard Barrier Pattern - Mode 2: Pre-Decomposed)**:
    - topics: [...]
    - report_paths: [...]

    **CRITICAL**:
    - You MUST invoke research-specialist for EACH topic in parallel
    - Validate ALL reports exist at pre-calculated paths after delegation
    - Return aggregated metadata
  "
}
```

**Delegation Expectation**:
1. lean-plan invokes research-coordinator via Task
2. research-coordinator decomposes into per-topic Tasks
3. Each research-specialist performs research and writes report
4. research-coordinator validates and returns metadata

**Actual Behavior**: If step 2 (nested Task invocation) is unsupported, the coordinator cannot delegate to specialists.

### Finding 5: Alternative Invocation Pattern Exists (Mode 1 vs Mode 2)

**From research-coordinator.md lines 57-96**:

**Mode 1: Automated Decomposition** (topics NOT provided):
- Coordinator performs topic decomposition from research_request
- Coordinator calculates report paths
- Coordinator invokes research-specialist for each topic
- Full autonomous operation

**Mode 2: Manual Pre-Decomposition** (topics provided by primary agent):
- Primary agent calculates topics and report paths
- Coordinator receives pre-calculated values
- Coordinator uses provided topics directly
- **Still requires nested Task invocations for delegation**

**Critical Observation**: lean-plan uses Mode 2, but BOTH modes require nested Task capability in STEP 3.

### Finding 6: Hard Barrier Validation Depends on Delegation

**From research-coordinator.md lines 510-656** (STEP 4):

**Validation Logic**:
```bash
# Check if invocation plan file exists (proves STEP 2.5 was executed)
if [ ! -f "$INVOCATION_PLAN_FILE" ]; then
  echo "CRITICAL ERROR: Invocation plan file missing - STEP 2.5 was skipped"
  exit 1
fi

# Check if invocation trace file exists (proves STEP 3 was executed)
if [ ! -f "$TRACE_FILE" ]; then
  echo "CRITICAL ERROR: Invocation trace file missing - STEP 3 did not execute"
  exit 1
fi

# Count expected vs created reports
if [ "$CREATED_REPORTS" -eq 0 ]; then
  echo "CRITICAL ERROR: Reports directory is empty - no reports created"
  echo "This indicates Task tool invocations did not execute in STEP 3"
  exit 1
fi
```

**Design Intent**: Hard barrier pattern ensures coordinator MUST delegate (cannot skip Task invocations).

**Reality**: If nested Task is unsupported, coordinator will always fail STEP 4 validation.

### Finding 7: Workaround Pattern Used in lean-plan Output

**From lean-plan-output.md analysis**:
- Primary agent skipped research-coordinator invocation entirely
- Primary agent performed research directly (10+ WebSearch, Read operations)
- Primary agent wrote research reports directly
- Primary agent wrote plan directly (skipped lean-plan-architect too)

**Interpretation**: Primary agent "optimized" by bypassing coordinators when delegation would fail.

**Consequences**:
- Architecture violated but workflow completes
- Context consumption high (~15k tokens vs ~500 with coordination)
- Parallelization lost (sequential research instead of parallel)
- Specialist logic bypassed (quality may suffer)

## Recommendations

### 1. Clarify Task Tool Nesting Support

**Priority**: CRITICAL

**Action**: Obtain definitive documentation or testing for Task tool nesting capabilities.

**Test Procedure**:
1. Create minimal coordinator agent that invokes specialist via Task
2. Invoke coordinator from primary agent via Task
3. Observe if nested Task succeeds, fails, or is silently skipped
4. Document maximum nesting depth supported

### 2. Redesign Coordinator Pattern for Non-Nested Execution

**If nested Task is NOT supported**:

**Option A: Orchestrator Pattern (Inline Execution)**
- Commands load coordinator logic inline (not via Task subprocess)
- Coordinator generates specialist Task invocations
- Primary agent executes these invocations directly
- Coordinator validates artifacts and aggregates metadata

**Implementation**:
```bash
# In lean-plan.md Block 1e
# Instead of: Task { invoke research-coordinator }
# Use: Source coordinator logic inline

source "${CLAUDE_PROJECT_DIR}/.claude/lib/coordination/research-orchestrator.sh"
REPORT_METADATA=$(orchestrate_research "$TOPICS" "$REPORT_PATHS" "$FEATURE_DESCRIPTION")
```

**Option B: Direct Specialist Invocation**
- Commands invoke specialists directly (skip coordinator layer)
- Commands handle parallelization via multiple Task blocks
- Commands perform metadata aggregation

**Implementation**:
```bash
# In lean-plan.md Block 1e
# Generate Task invocations for each topic
for i in "${!TOPICS[@]}"; do
  # EXECUTE NOW: USE Task tool for topic ${i}
  Task {
    prompt: "Read research-specialist.md and research: ${TOPICS[$i]}"
  }
done
```

### 3. Implement Execution Mode Detection in Coordinators

**Action**: Add capability detection to coordinator agents.

**Pattern**:
```yaml
# In research-coordinator.md frontmatter
execution-modes:
  - nested-task  # Preferred: Full nested Task delegation
  - inline       # Fallback: Coordinator runs inline, returns specialist invocation instructions
```

**Logic**:
```bash
# In coordinator STEP 0
# Detect execution context
if [ -n "${TASK_SUBPROCESS_LEVEL:-}" ]; then
  # Running as Task subprocess
  if command -v task_tool_test &>/dev/null; then
    EXECUTION_MODE="nested-task"
  else
    EXECUTION_MODE="inline"
    echo "WARNING: Nested Task not supported, switching to inline mode"
  fi
else
  EXECUTION_MODE="inline"
fi
```

### 4. Add Explicit Delegation Validation to Commands

**Action**: Enhance lean-plan.md to verify delegation occurred.

**After Block 1e-exec**:
```bash
# Validate Task invocation occurred
if [ -z "${LAST_TASK_SUBPROCESS_ID:-}" ]; then
  echo "ERROR: research-coordinator Task invocation did not execute"
  echo "Possible causes:"
  echo "  1. Task tool not available in current context"
  echo "  2. Directive was interpreted as documentation"
  echo "  3. Agent chose to skip delegation"
  exit 1
fi
```

### 5. Document Architectural Decision on Nesting

**Action**: Create ADR (Architecture Decision Record) documenting:
- Whether nested Task invocations are supported
- Maximum nesting depth (if limited)
- Preferred patterns for multi-level delegation
- Migration path for existing coordinator agents

**Location**: `/home/benjamin/.config/.claude/docs/architecture/adr/002-task-nesting-support.md`

## Conclusion

The coordinator delegation pattern assumes nested Task invocation capability (Task subprocess invoking another Task), but evidence suggests this may not be supported by the execution environment. This architectural mismatch results in:

1. **Command behavior**: lean-plan skips coordinator invocation and performs work directly
2. **Coordinator design**: All 10 coordinator agents contain Task invocation logic that may never execute
3. **Hard barrier failures**: Coordinators designed to REQUIRE delegation will fail if invoked

**Root Cause**: Architectural assumption (nested Task support) not validated against execution environment capabilities.

**Resolution Path**:
1. Confirm Task nesting support status
2. If unsupported: Redesign coordinator pattern (orchestrator or direct specialist invocation)
3. If supported: Debug why lean-plan skips coordinator invocation
4. Update all coordinator agents and commands consistently
