# Research Report: /lean-implement Delegation Failure Analysis

**Date**: 2025-12-04
**Researcher**: research-specialist
**Topic**: /lean-implement subagent delegation failure
**Research Complexity**: 3

---

## Executive Summary

The `/lean-implement` command exhibits critical delegation failures evidenced in `lean-implement-output-2.md`, where the primary agent performs implementation work directly instead of delegating to coordinators. This violates the hierarchical agent architecture and causes context exhaustion, inefficient execution, and inconsistent behavior compared to working reference commands (`/implement`, `/lean-build`).

**Root Cause**: `/lean-implement` lacks the **hard barrier pattern** that enforces mandatory coordinator delegation. The command directly executes implementation tasks in Block 1b instead of using Task tool invocation with verification barriers.

**Impact**: Context exhaustion, no parallel execution, inconsistent routing logic, missing progress tracking integration.

**Solution**: Implement hard barrier pattern at Block 1b (coordinator invocation checkpoint) and Block 1c (summary verification checkpoint), matching the proven architecture of `/implement` and `/lean-build`.

---

## Research Questions Answered

### 1. Root Cause of Delegation Failure

**Finding**: `/lean-implement` Block 1b contains a **COORDINATOR INVOCATION DECISION** section with conditional Task invocations based on `CURRENT_PHASE_TYPE`, but lacks enforcement mechanisms to ensure the Task tool is actually used.

**Evidence** (lean-implement.md:672-773):
```markdown
**COORDINATOR INVOCATION DECISION**:

Based on the CURRENT_PHASE_TYPE from Block 1b state:

**If CURRENT_PHASE_TYPE is "lean"**:
**EXECUTE NOW**: USE the Task tool to invoke the lean-coordinator agent.
Task { ... }

**If CURRENT_PHASE_TYPE is "software"**:
**EXECUTE NOW**: USE the Task tool to invoke the implementer-coordinator agent.
Task { ... }
```

**Problem**: This is an **instructional pattern** without verification. The agent can ignore these directives and perform work directly. No bash block checks whether delegation occurred.

**Contrast with /implement** (implement.md:494-567):
```markdown
## Block 1b: Implementer-Coordinator Invocation [CRITICAL BARRIER]

**HARD BARRIER - Implementer-Coordinator Invocation**

**CRITICAL BARRIER**: This block MUST invoke implementer-coordinator via Task tool.
The Task invocation is MANDATORY and CANNOT be bypassed.
The verification block (Block 1c) will FAIL if implementation summary is not created.

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallelization"
  prompt: "..."
}
```

**Key Difference**: `/implement` has:
1. **Block label**: `[CRITICAL BARRIER]` in heading
2. **Imperative directive**: "This block MUST invoke implementer-coordinator"
3. **Verification promise**: "Block 1c will FAIL if summary not created"
4. **Single Task invocation**: No conditional logic, always delegates

`/lean-implement` has:
1. No block label
2. Conditional directives ("If X, then invoke Y")
3. No verification promise
4. Complex branching logic that allows bypassing

### 2. How /implement Correctly Delegates

**Architecture**: `/implement` uses a **3-block hard barrier pattern**:

**Block 1a: Setup** (implement.md:23-492)
- Captures arguments, initializes state
- Validates plan file existence
- Marks starting phase as [IN PROGRESS]
- Persists iteration variables
- **Checkpoint**: "Ready for: implementer-coordinator invocation (Block 1b)"

**Block 1b: Coordinator Invocation [CRITICAL BARRIER]** (implement.md:494-567)
- **Single Task invocation** (no conditionals)
- Passes structured input contract with all paths
- Includes iteration parameters for continuation support
- **Critical**: No bash code in this block, only Task prompt

**Block 1c: Verification (Hard Barrier)** (implement.md:569-896)
- **Mandatory verification**: Checks summary file exists in `SUMMARIES_DIR`
- **File size validation**: Must be ≥100 bytes
- **Defensive diagnostics**: Enhanced error reporting with alternate location search
- **Iteration decision**: Parses `work_remaining` and `requires_continuation` from agent output
- **Loop or proceed**: Either continues to next iteration (Block 1b) or proceeds to Block 1d

**Key Pattern**: The verification block ENFORCES delegation by FAILING THE WORKFLOW if the coordinator didn't create the summary file. This architectural constraint makes delegation mandatory.

**Code Evidence** (implement.md:689-743):
```bash
# HARD BARRIER: Summary file MUST exist
LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f -exec ls -t {} + 2>/dev/null | head -1 || echo "")
if [ -z "$LATEST_SUMMARY" ] || [ ! -f "$LATEST_SUMMARY" ]; then
  echo "❌ HARD BARRIER FAILED - Implementation summary not found" >&2
  # Enhanced diagnostics...
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "agent_error" "implementer-coordinator failed to create summary file" \
    "bash_block_1c" "..."
  exit 1
fi
```

**Why This Works**: The coordinator agent KNOWS it must create a summary in `SUMMARIES_DIR` because:
1. The Task prompt explicitly states: "**CRITICAL**: You MUST create implementation summary at ${TOPIC_PATH}/summaries/"
2. The prompt warns: "The orchestrator will validate the summary exists after you return."
3. The agent's behavioral guidelines (implementer-coordinator.md:557) define the output contract with `summary_path` field

### 3. How /lean-build Correctly Delegates

**Architecture**: `/lean-build` uses the same 3-block hard barrier pattern adapted for Lean workflows:

**Block 1a: Setup** (lean-build.md:75-431)
- Argument parsing, Lean project detection
- Lean file discovery (2-tier: phase metadata → global metadata)
- MCP server availability check
- Iteration variable initialization
- **Checkpoint**: Ready for coordinator invocation

**Block 1b: Invoke Lean Coordinator [HARD BARRIER]** (lean-build.md:433-485)
- **Single Task invocation** to lean-coordinator
- Passes `lean_file_path`, `topic_path`, `artifact_paths`
- Includes iteration parameters (`continuation_context`, `max_iterations`)
- Progress tracking instructions for plan-based mode
- **Critical**: "You MUST create a proof summary in ${SUMMARIES_DIR}/"

**Block 1c: Verification & Iteration Decision** (lean-build.md:487-639)
- **Mandatory verification**: Checks summary file exists
- **File size validation**: ≥100 bytes
- **Parse agent output**: Extracts `work_remaining`, `requires_continuation`, `context_exhausted`
- **Stuck detection**: Monitors unchanged `work_remaining` across iterations
- **Iteration loop**: Returns to Block 1b if continuation needed, else proceeds to Block 1d

**Key Innovation**: `/lean-build` demonstrates iteration management within the coordinator delegation pattern:
- Coordinator returns `requires_continuation: true|false`
- Orchestrator decides whether to loop back to Block 1b
- State persists across iterations for resumption

**Code Evidence** (lean-build.md:498-516):
```bash
# Check for any recent summary in directory (last 5 minutes)
LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f -mmin -5 2>/dev/null | sort | tail -1)

if [ -n "$LATEST_SUMMARY" ] && [ -f "$LATEST_SUMMARY" ] && [ $(stat -c%s "$LATEST_SUMMARY" 2>/dev/null || echo "0") -ge 100 ]; then
  SUMMARY_PATH="$LATEST_SUMMARY"
  SUMMARY_FOUND="true"
else
  echo "ERROR: Summary file not created or too small (<100 bytes)" >&2
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "agent_error" "Coordinator/implementer did not create summary" "verification_block" \
    "{\"summaries_dir\": \"$SUMMARIES_DIR\"}"
  exit 1
fi
```

### 4. Phase Metadata Format for Routing

**Finding**: `/lean-plan` creates plans with per-phase `implementer:` and `lean_file:` fields that indicate phase type and routing.

**Evidence** (lean-plan-architect.md:182-250):
```markdown
### Phase Routing Summary
| Phase | Type | Implementer Agent |
|-------|------|-------------------|
| 1 | lean | lean-implementer |
| 2 | software | implementer-coordinator |
| 3 | lean | lean-implementer |

**Phase Type Determination**:
- **lean**: Phase involves theorem proving (has `lean_file:` field)
- **software**: Phase involves tooling, infrastructure
```

**Phase Format Example**:
```markdown
### Phase 1: [Theorem Category Name] [NOT STARTED]
implementer: lean
lean_file: /absolute/path/to/file.lean
dependencies: []

**Objective**: [High-level goal]
**Complexity**: [Low|Medium|High]
**Theorems**: ...
```

**Routing Logic**: The `implementer:` field explicitly declares whether a phase requires:
- `lean` → Route to lean-coordinator
- `software` → Route to implementer-coordinator

**Current /lean-implement Approach**: Uses keyword heuristics in Block 1a-classify (lean-implement.md:429-461):
```bash
detect_phase_type() {
  local phase_content="$1"
  local phase_num="$2"

  # Tier 1: Check for lean_file metadata
  if echo "$phase_content" | grep -qE "^lean_file:"; then
    echo "lean"
    return 0
  fi

  # Tier 2: Keyword analysis
  if echo "$phase_content" | grep -qiE '\.(lean)\b|theorem\b|lemma\b|sorry\b'; then
    echo "lean"
    return 0
  fi
  # ... defaults to "software"
}
```

**Problem**: This heuristic approach is fragile and doesn't leverage the explicit `implementer:` field from `/lean-plan`.

**Better Approach**: Read `implementer:` field directly:
```bash
# Tier 1: Check implementer field (strongest signal)
IMPLEMENTER=$(echo "$phase_content" | grep -E "^implementer:" | sed 's/^implementer:[[:space:]]*//')
if [ -n "$IMPLEMENTER" ]; then
  echo "$IMPLEMENTER"  # Returns "lean" or "software"
  return 0
fi

# Tier 2: Fallback to lean_file detection
if echo "$phase_content" | grep -qE "^lean_file:"; then
  echo "lean"
  return 0
fi
```

### 5. Routing to Appropriate Coordinators

**Finding**: `/lean-implement` should invoke coordinators based on phase type, similar to how `/implement` always invokes implementer-coordinator and `/lean-build` always invokes lean-coordinator.

**Current Architecture** (lean-implement.md:672-773):
- Block 1b contains conditional Task invocations
- Decision logic based on `CURRENT_PHASE_TYPE` variable
- No verification that Task was actually invoked

**Recommended Architecture**:

**Block 1b: Coordinator Routing [HARD BARRIER]**
```bash
# Restore state
load_workflow_state "$WORKFLOW_ID" false

# Read routing map to get current phase type
PHASE_TYPE=$(get_current_phase_type "$ROUTING_MAP_FILE" "$CURRENT_PHASE")

# Validate phase type
if [ "$PHASE_TYPE" != "lean" ] && [ "$PHASE_TYPE" != "software" ]; then
  echo "ERROR: Invalid phase type: $PHASE_TYPE" >&2
  exit 1
fi

# Set coordinator name for verification
if [ "$PHASE_TYPE" = "lean" ]; then
  COORDINATOR_NAME="lean-coordinator"
  COORDINATOR_AGENT_PATH="$CLAUDE_PROJECT_DIR/.claude/agents/lean-coordinator.md"
else
  COORDINATOR_NAME="implementer-coordinator"
  COORDINATOR_AGENT_PATH="$CLAUDE_PROJECT_DIR/.claude/agents/implementer-coordinator.md"
fi

# Persist for verification block
append_workflow_state "COORDINATOR_NAME" "$COORDINATOR_NAME"
append_workflow_state "PHASE_TYPE" "$PHASE_TYPE"

echo "Routing Phase $CURRENT_PHASE ($PHASE_TYPE) to $COORDINATOR_NAME..."
echo ""
```

**Then invoke appropriate coordinator** (based on PHASE_TYPE):

```markdown
**EXECUTE NOW**: Invoke coordinator based on phase type.

**If PHASE_TYPE=lean**, USE the Task tool:
Task {
  subagent_type: "general-purpose"
  description: "Wave-based Lean theorem proving for phase ${CURRENT_PHASE}"
  prompt: "Read and follow: ${COORDINATOR_AGENT_PATH}\n\n**Input Contract**: ..."
}

**If PHASE_TYPE=software**, USE the Task tool:
Task {
  subagent_type: "general-purpose"
  description: "Wave-based software implementation for phase ${CURRENT_PHASE}"
  prompt: "Read and follow: ${COORDINATOR_AGENT_PATH}\n\n**Input Contract**: ..."
}
```

**Key Change**: Simplify to single Task invocation per phase type, not complex conditional logic in prose.

### 6. Reusable Infrastructure from lib/

**Finding**: The existing library infrastructure supports the hard barrier pattern:

**State Persistence** (`lib/core/state-persistence.sh`):
- `append_workflow_state()`: Store variables across blocks
- `load_workflow_state()`: Restore variables in subprocess
- `validate_state_restoration()`: Verify critical variables restored

**Error Handling** (`lib/core/error-handling.sh`):
- `log_command_error()`: Centralized error logging to errors.jsonl
- `parse_subagent_error()`: Extract error context from agent output
- Error type taxonomy: `state_error`, `agent_error`, `validation_error`, etc.

**Workflow State Machine** (`lib/workflow/workflow-state-machine.sh`):
- `sm_init()`: Initialize state machine for workflow
- `sm_transition()`: Transition between workflow states
- State validation and history tracking

**Checkbox Utilities** (`lib/plan/checkbox-utils.sh`):
- `add_in_progress_marker()`: Mark phase as [IN PROGRESS]
- `mark_phase_complete()`: Mark all tasks complete
- `add_complete_marker()`: Add [COMPLETE] to phase heading
- `verify_phase_complete()`: Check if all tasks done

**Barrier Utilities** (`lib/workflow/barrier-utils.sh`):
- Hard barrier verification patterns
- Summary existence validation
- File size checks

**Reuse Strategy for /lean-implement**:
1. **Use existing state persistence**: No new libraries needed
2. **Use existing error logging**: Integrate `log_command_error()` at failure points
3. **Use existing checkbox utilities**: Forward to coordinators for progress tracking
4. **Adapt hard barrier pattern**: Copy verification logic from `/implement` Block 1c

### 7. Minimal Changes Needed

**Finding**: The fix requires restructuring 3 blocks, not rewriting the entire command.

**Changes Required**:

**1. Block 1a-classify** (lean-implement.md:383-573):
- **KEEP**: Phase discovery, routing map construction
- **CHANGE**: Read `implementer:` field first (Tier 1), fallback to `lean_file:` detection (Tier 2)
- **ADD**: Validation that routing map has valid phase types ("lean" or "software")

**2. Block 1b** (lean-implement.md:575-773):
- **REMOVE**: Entire "COORDINATOR INVOCATION DECISION" conditional section
- **REPLACE WITH**: Single bash block that reads current phase type from routing map
- **ADD**: Two separate Task invocations (one for lean coordinator, one for software coordinator)
- **ADD**: Block heading `[HARD BARRIER]` marker

**3. Block 1c** (lean-implement.md:774-970):
- **KEEP**: Summary verification logic structure
- **ENHANCE**: Add file size validation (≥100 bytes)
- **ADD**: Enhanced diagnostics (search alternate locations)
- **ADD**: Coordinator name validation (log which coordinator failed)
- **KEEP**: Iteration decision logic (already correct)

**4. Block 1d** (lean-implement.md:972-1091):
- **KEEP**: Phase marker recovery logic (already correct)
- **NO CHANGES**: This block is independent of delegation

**5. Block 2** (lean-implement.md:1093-1247):
- **KEEP**: Completion summary display
- **ENHANCE**: Add coordinator-specific metrics (lean vs software phase counts)
- **NO CHANGES**: Core structure is correct

**Lines of Code Impact**:
- Block 1a-classify: +20 lines (enhanced tier detection)
- Block 1b: -100 lines, +80 lines (remove conditionals, add hard barrier)
- Block 1c: +30 lines (enhanced verification)
- Total: ~+30 lines net, but significant restructuring

**Complexity Assessment**: Medium
- Requires understanding hard barrier pattern
- Requires coordinating state persistence across blocks
- No new library creation needed (reuse existing)
- Testing requires /lean-plan integration

---

## Comparative Analysis

### Command Architecture Comparison

| Aspect | /implement | /lean-build | /lean-implement (current) | /lean-implement (proposed) |
|--------|-----------|-------------|---------------------------|---------------------------|
| **Delegation Pattern** | Hard barrier | Hard barrier | Instructional (broken) | Hard barrier |
| **Block 1b Type** | Single Task | Single Task | Conditional Tasks | Single Task per phase type |
| **Verification** | Block 1c enforces | Block 1c enforces | None | Block 1c enforces |
| **Iteration Support** | ✓ (via continuation_context) | ✓ (via continuation_context) | ✓ (via continuation_context) | ✓ (unchanged) |
| **Routing Logic** | N/A (single type) | N/A (single type) | Keyword heuristics | Explicit `implementer:` field |
| **Progress Tracking** | ✓ (forwarded to coordinator) | ✓ (forwarded to coordinator) | ✗ (missing) | ✓ (forward to coordinators) |

### Delegation Enforcement Mechanisms

| Mechanism | /implement | /lean-build | /lean-implement (current) | /lean-implement (proposed) |
|-----------|-----------|-------------|---------------------------|---------------------------|
| **Block Label** | `[CRITICAL BARRIER]` | `[HARD BARRIER]` | None | `[HARD BARRIER]` |
| **Imperative Directive** | "This block MUST invoke" | "EXECUTE NOW: USE the Task tool" | "**EXECUTE NOW**" (conditional) | "**EXECUTE NOW**: USE the Task tool" |
| **Verification Promise** | "Block 1c will FAIL if..." | "The orchestrator will validate..." | None | "Block 1c will FAIL if..." |
| **Summary Size Check** | ✓ (≥100 bytes) | ✓ (≥100 bytes) | ✗ | ✓ (≥100 bytes) |
| **Error Logging** | ✓ (`agent_error`) | ✓ (`agent_error`) | ✗ | ✓ (`agent_error`) |

### Coordinator Input Contracts

**implementer-coordinator.md:37-52**:
```yaml
plan_path: /path/to/plan.md
topic_path: /path/to/topic
summaries_dir: /path/to/summaries/
artifact_paths:
  reports: /path/to/reports/
  plans: /path/to/plans/
  summaries: /path/to/summaries/
  debug: /path/to/debug/
  outputs: /path/to/outputs/
  checkpoints: /path/to/checkpoints/
continuation_context: null  # Or path to previous summary
iteration: 1  # Current iteration (1-5)
max_iterations: 5
context_threshold: 85
```

**lean-coordinator.md:28-52**:
```yaml
plan_path: /path/to/plan.md
lean_file_path: /path/to/file.lean
topic_path: /path/to/topic
artifact_paths:
  summaries: /path/to/summaries/
  outputs: /path/to/outputs/
  checkpoints: /path/to/checkpoints/
continuation_context: null  # Or path to previous summary
iteration: 1  # Current iteration (1-5)
max_iterations: 5
context_threshold: 85
```

**Key Difference**: lean-coordinator requires `lean_file_path`, implementer-coordinator does not. Both require `plan_path` for phase marker tracking.

**Implication**: /lean-implement must extract `lean_file_path` from routing map for lean phases.

---

## Infrastructure Integration Points

### 1. Phase Metadata Reading

**Current Approach** (lean-implement.md:464-496):
```bash
# Extract phase content from plan file
PHASE_CONTENT=$(awk -v target="$phase_num" '
  BEGIN { in_phase=0; found=0 }
  /^### Phase / {
    if (found) exit
    if (index($0, "Phase " target ":") > 0) {
      in_phase=1
      found=1
      print
      next
    }
  }
  in_phase { print }
' "$PLAN_FILE")
```

**Enhanced Approach**:
```bash
# Extract phase content AND implementer field
PHASE_CONTENT=$(extract_phase_content "$PLAN_FILE" "$phase_num")

# Tier 1: Read implementer field
IMPLEMENTER=$(echo "$PHASE_CONTENT" | grep -E "^implementer:" | sed 's/^implementer:[[:space:]]*//')

if [ -n "$IMPLEMENTER" ]; then
  PHASE_TYPE="$IMPLEMENTER"  # "lean" or "software"
else
  # Tier 2: Fallback to lean_file detection
  if echo "$PHASE_CONTENT" | grep -qE "^lean_file:"; then
    PHASE_TYPE="lean"
  else
    PHASE_TYPE="software"
  fi
fi
```

**Benefit**: Directly reads explicit routing information from plan, eliminating fragile keyword heuristics.

### 2. Routing Map Format

**Current Format** (lean-implement.md:534):
```bash
ROUTING_MAP="${ROUTING_MAP}${phase_num}:${PHASE_TYPE}:${LEAN_FILE_PATH:-none}"
```

**Enhanced Format**:
```bash
ROUTING_MAP="${ROUTING_MAP}${phase_num}:${PHASE_TYPE}:${LEAN_FILE_PATH:-none}:${IMPLEMENTER:-software}"
```

**Fields**:
1. `phase_num`: Phase number (1-indexed)
2. `PHASE_TYPE`: Detected type ("lean" or "software")
3. `LEAN_FILE_PATH`: Absolute path to .lean file (or "none")
4. `IMPLEMENTER`: Explicit coordinator name ("lean-coordinator" or "implementer-coordinator")

**Benefit**: Store all routing decisions upfront, Block 1b just reads and invokes.

### 3. Progress Tracking Integration

**Current Status**: /lean-implement does not forward progress tracking instructions to coordinators.

**Evidence**: No mention of checkbox utilities in lean-implement.md Block 1b Task prompts.

**Required Change**: Forward progress tracking instructions to coordinators, matching /lean-build pattern.

**lean-build.md:313-334** (progress tracking forwarding):
```markdown
Progress Tracking Instructions (plan-based mode only):
- Source checkbox utilities: source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh
- Before proving each theorem phase: add_in_progress_marker '${PLAN_FILE}' <phase_num>
- After completing each theorem proof: mark_phase_complete '${PLAN_FILE}' <phase_num> && add_complete_marker '${PLAN_FILE}' <phase_num>
- This creates visible progress: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]
- Note: Progress tracking gracefully degrades if unavailable (non-fatal)
- File-based mode: Skip progress tracking (phase_num = 0)
```

**Integration Point**: Add this same instruction block to both coordinator invocations in /lean-implement Block 1b.

### 4. Error Return Protocol

**Finding**: Both coordinators use standardized error return protocol for critical failures.

**implementer-coordinator.md:759-820**:
```markdown
## Error Return Protocol

If a critical error prevents workflow completion, return a structured error signal.

**Error Signal Format**:
ERROR_CONTEXT: {
  "error_type": "state_error",
  "message": "State file not found",
  "details": {"expected_path": "/path"}
}

TASK_ERROR: state_error - State file not found at /path

**Error Types**: state_error, validation_error, agent_error, parse_error, file_error, timeout_error, execution_error, dependency_error
```

**lean-coordinator.md:703-755** (same protocol)

**Integration Requirement**: /lean-implement Block 1c must parse `TASK_ERROR:` signals from coordinator output and call `parse_subagent_error()` to log to errors.jsonl.

**Current Status**: Not implemented in lean-implement.md.

**Required Addition** (Block 1c):
```bash
# Parse coordinator output for error signal
COORDINATOR_ERROR=$(parse_subagent_error "$COORDINATOR_OUTPUT" "$COORDINATOR_NAME")

if [ -n "$COORDINATOR_ERROR" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Coordinator failed: $COORDINATOR_ERROR" \
    "bash_block_1c" \
    "$(jq -n --arg coord "$COORDINATOR_NAME" --arg phase "$CURRENT_PHASE" \
       '{coordinator: $coord, phase: $phase}')"
  exit 1
fi
```

---

## Architectural Insights

### Why Hard Barrier Pattern Works

The hard barrier pattern enforces architectural constraints through **runtime verification** rather than **static instructions**:

1. **Separation of Concerns**:
   - Orchestrator: Path calculation, iteration management, verification
   - Coordinator: Wave orchestration, parallel execution, progress aggregation
   - Implementer: Task execution, artifact creation

2. **Fail-Fast Validation**:
   - If coordinator doesn't create summary → workflow FAILS immediately
   - No silent bypassing of delegation
   - Clear error attribution (which coordinator failed)

3. **Context Efficiency**:
   - Orchestrator passes metadata-only (paths, iteration params)
   - Coordinator returns metadata-only (summary_path, work_remaining)
   - Full content stays in filesystem, not in context window

4. **Iteration Support**:
   - Orchestrator manages continuation_context across iterations
   - Coordinator handles execution within single iteration
   - Clean resumption via checkpoint files

### Why /lean-implement Fails

**Absence of Verification**: Block 1b contains Task prompts but no bash verification. The primary agent can:
1. Read the Task prompt
2. Decide to perform work directly instead of delegating
3. Skip creating summary file
4. Return without triggering any errors

**No Fail-Fast**: Block 1c doesn't check for summary existence, so delegation bypass goes undetected until user notices incorrect behavior.

**Complex Conditional Logic**: The COORDINATOR INVOCATION DECISION section has two Task prompts (lean vs software), making it unclear which one is mandatory.

### Hierarchical Agent Architecture Principles

**From hierarchical-agents-overview.md:20-65**:

1. **Hierarchical Supervision**: Coordinators manage workers, orchestrators manage coordinators
2. **Behavioral Injection**: Runtime loading of behavioral guidelines from `.claude/agents/*.md`
3. **Metadata-Only Passing**: Pass summaries (110 tokens) not full content (2,500 tokens)
4. **Single Source of Truth**: Agent behavior in ONE location only

**Application to /lean-implement**:
- Orchestrator: `/lean-implement` command (Blocks 1a-2)
- Coordinators: lean-coordinator, implementer-coordinator
- Workers: lean-implementer, implementation-executor (invoked by coordinators)

**Current Violation**: /lean-implement attempts to be both orchestrator AND worker (direct implementation), violating hierarchy.

---

## Recommendations

### 1. Immediate Fix (Block 1b Restructure)

**Priority**: CRITICAL
**Effort**: Medium (2-4 hours)
**Risk**: Low (pattern proven in /implement and /lean-build)

**Changes**:
1. Remove COORDINATOR INVOCATION DECISION conditional section
2. Add bash block that reads routing map and determines coordinator
3. Add separate Task invocations for lean-coordinator and implementer-coordinator
4. Add block heading marker `[HARD BARRIER]`

**Template** (based on /implement):
```markdown
## Block 1b: Coordinator Routing [HARD BARRIER]

**HARD BARRIER - Coordinator Invocation**

**CRITICAL BARRIER**: This block MUST invoke appropriate coordinator (lean-coordinator or implementer-coordinator) via Task tool based on phase type. The Task invocation is MANDATORY and CANNOT be bypassed. The verification block (Block 1c) will FAIL if summary is not created by the coordinator.

**EXECUTE NOW**: First, determine coordinator based on phase type.

```bash
# Restore state
load_workflow_state "$WORKFLOW_ID" false

# Read routing map
ROUTING_MAP_FILE="${LEAN_IMPLEMENT_WORKSPACE}/routing_map.txt"
PHASE_ENTRY=$(grep "^${CURRENT_PHASE}:" "$ROUTING_MAP_FILE" | head -1)

# Parse phase type
PHASE_TYPE=$(echo "$PHASE_ENTRY" | cut -d: -f2)
LEAN_FILE_PATH=$(echo "$PHASE_ENTRY" | cut -d: -f3)

# Determine coordinator
if [ "$PHASE_TYPE" = "lean" ]; then
  COORDINATOR_NAME="lean-coordinator"
  COORDINATOR_PATH="$CLAUDE_PROJECT_DIR/.claude/agents/lean-coordinator.md"
else
  COORDINATOR_NAME="implementer-coordinator"
  COORDINATOR_PATH="$CLAUDE_PROJECT_DIR/.claude/agents/implementer-coordinator.md"
fi

# Persist for verification
append_workflow_state "COORDINATOR_NAME" "$COORDINATOR_NAME"
append_workflow_state "PHASE_TYPE" "$PHASE_TYPE"

echo "Invoking $COORDINATOR_NAME for Phase $CURRENT_PHASE ($PHASE_TYPE)..."
```

**EXECUTE NOW**: Invoke appropriate coordinator.

**If PHASE_TYPE is "lean"**, USE the Task tool:
Task {
  subagent_type: "general-purpose"
  description: "Wave-based Lean theorem proving for phase ${CURRENT_PHASE}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${COORDINATOR_PATH}

    **Input Contract**: ...
  "
}

**If PHASE_TYPE is "software"**, USE the Task tool:
Task {
  subagent_type: "general-purpose"
  description: "Wave-based software implementation for phase ${CURRENT_PHASE}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${COORDINATOR_PATH}

    **Input Contract**: ...
  "
}
```

### 2. Enhanced Verification (Block 1c)

**Priority**: HIGH
**Effort**: Low (1-2 hours)
**Risk**: None (additive change)

**Additions**:
1. File size validation (≥100 bytes)
2. Coordinator name in error messages
3. Enhanced diagnostics (alternate location search)
4. Error signal parsing (`TASK_ERROR:`)

**Template** (based on /implement Block 1c:689-743):
```bash
# === MANDATORY VERIFICATION (hard barrier pattern) ===
echo ""
echo "=== Hard Barrier Verification: Coordinator Summary ==="
echo ""

# HARD BARRIER: Summary file MUST exist
LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f -mmin -10 2>/dev/null | sort | tail -1)

if [ -z "$LATEST_SUMMARY" ] || [ ! -f "$LATEST_SUMMARY" ]; then
  echo "❌ HARD BARRIER FAILED - Summary not created by $COORDINATOR_NAME" >&2

  # Enhanced diagnostics
  FOUND_FILES=$(find "$TOPIC_PATH" -name "*summary*.md" -type f 2>/dev/null)
  if [ -n "$FOUND_FILES" ]; then
    echo "Found summary at alternate location:" >&2
    echo "$FOUND_FILES" >&2
  fi

  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "$COORDINATOR_NAME failed to create summary" \
    "bash_block_1c" \
    "$(jq -n --arg coord "$COORDINATOR_NAME" --arg phase "$CURRENT_PHASE" \
       '{coordinator: $coord, phase: $phase, summaries_dir: "'"$SUMMARIES_DIR"'"}')"
  exit 1
fi

# Validate summary size
SUMMARY_SIZE=$(wc -c < "$LATEST_SUMMARY" 2>/dev/null || echo "0")
if [ "$SUMMARY_SIZE" -lt 100 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Summary file too small ($SUMMARY_SIZE bytes)" \
    "bash_block_1c" \
    "$(jq -n --arg path "$LATEST_SUMMARY" --argjson size "$SUMMARY_SIZE" \
       '{summary_path: $path, size_bytes: $size}')"
  exit 1
fi

echo "[OK] $COORDINATOR_NAME output validated: $LATEST_SUMMARY ($SUMMARY_SIZE bytes)"
```

### 3. Routing Enhancement (Block 1a-classify)

**Priority**: MEDIUM
**Effort**: Low (1 hour)
**Risk**: None (backward compatible)

**Changes**:
1. Read `implementer:` field first (Tier 1 discovery)
2. Fallback to `lean_file:` detection (Tier 2)
3. Validate routing map has valid phase types

**Template**:
```bash
detect_phase_type() {
  local phase_content="$1"
  local phase_num="$2"

  # Tier 1: Read implementer field (explicit routing)
  local implementer=$(echo "$phase_content" | grep -E "^implementer:" | sed 's/^implementer:[[:space:]]*//')
  if [ -n "$implementer" ]; then
    case "$implementer" in
      lean|software)
        echo "$implementer"
        return 0
        ;;
      *)
        echo "WARNING: Invalid implementer value: $implementer (defaulting to software)" >&2
        echo "software"
        return 0
        ;;
    esac
  fi

  # Tier 2: Check for lean_file metadata
  if echo "$phase_content" | grep -qE "^lean_file:"; then
    echo "lean"
    return 0
  fi

  # Tier 3: Keyword and extension analysis (fallback)
  if echo "$phase_content" | grep -qiE '\.(lean)\b|theorem\b|lemma\b|sorry\b'; then
    echo "lean"
    return 0
  fi

  # Default: software
  echo "software"
}
```

### 4. Progress Tracking Integration

**Priority**: MEDIUM
**Effort**: Low (1 hour)
**Risk**: None (non-blocking feature)

**Changes**:
1. Forward progress tracking instructions to both coordinators
2. Include in Task prompt for both lean-coordinator and implementer-coordinator

**Template** (add to both Task prompts in Block 1b):
```markdown
Progress Tracking Instructions:
- Source checkbox utilities: source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh
- Before starting phase: add_in_progress_marker '${PLAN_FILE}' ${CURRENT_PHASE}
- After completing phase: mark_phase_complete '${PLAN_FILE}' ${CURRENT_PHASE} && add_complete_marker '${PLAN_FILE}' ${CURRENT_PHASE}
- This creates visible progress: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]
- Note: Progress tracking gracefully degrades if unavailable (non-fatal)
```

### 5. Testing Strategy

**Priority**: HIGH
**Effort**: Medium (3-4 hours)
**Risk**: None (validation before deployment)

**Test Cases**:

1. **Pure Lean Plan** (all phases lean type):
   - Create plan with `/lean-plan "Prove group homomorphism properties"`
   - Run `/lean-implement plan.md`
   - Verify all phases route to lean-coordinator
   - Verify summary created in summaries/
   - Verify phase markers updated

2. **Pure Software Plan** (all phases software type):
   - Create plan with `/create-plan "Setup CI pipeline for Lean project"`
   - Run `/lean-implement plan.md`
   - Verify all phases route to implementer-coordinator
   - Verify summary created in summaries/
   - Verify phase markers updated

3. **Hybrid Plan** (mixed lean/software phases):
   - Create plan with mix of theorem proving and tooling phases
   - Run `/lean-implement plan.md`
   - Verify correct routing (lean phases → lean-coordinator, software phases → implementer-coordinator)
   - Verify both coordinators create summaries
   - Verify all phase markers updated

4. **Iteration Test** (large plan requiring continuation):
   - Create plan with 10+ phases
   - Run `/lean-implement plan.md --max-iterations=3`
   - Verify iteration loop works (Block 1b → 1c → 1b)
   - Verify continuation_context passed correctly
   - Verify work_remaining tracked across iterations

5. **Failure Test** (coordinator failure):
   - Mock coordinator failure (summary not created)
   - Verify Block 1c hard barrier triggers
   - Verify error logged to errors.jsonl
   - Verify workflow exits with error

---

## Implementation Checklist

### Phase 1: Block 1b Restructure
- [ ] Remove COORDINATOR INVOCATION DECISION section
- [ ] Add bash block for routing map reading
- [ ] Add separate Task invocations (lean-coordinator, implementer-coordinator)
- [ ] Add `[HARD BARRIER]` block heading
- [ ] Add coordinator name persistence to state

### Phase 2: Block 1c Verification Enhancement
- [ ] Add summary file existence check
- [ ] Add file size validation (≥100 bytes)
- [ ] Add enhanced diagnostics (alternate location search)
- [ ] Add coordinator name in error messages
- [ ] Add error signal parsing (`TASK_ERROR:`)

### Phase 3: Block 1a-classify Enhancement
- [ ] Add Tier 1 discovery (`implementer:` field)
- [ ] Keep Tier 2 discovery (`lean_file:` field)
- [ ] Add routing map validation (valid phase types)

### Phase 4: Progress Tracking Integration
- [ ] Add progress tracking instructions to lean-coordinator invocation
- [ ] Add progress tracking instructions to implementer-coordinator invocation

### Phase 5: Testing
- [ ] Test pure Lean plan
- [ ] Test pure software plan
- [ ] Test hybrid plan
- [ ] Test iteration loop
- [ ] Test failure cases

### Phase 6: Documentation
- [ ] Update lean-implement.md with hard barrier pattern
- [ ] Update lean-implement-command-guide.md with routing explanation
- [ ] Add troubleshooting section for delegation failures

---

## Success Criteria

The fix is successful if:

1. **Delegation Enforcement**: Block 1c verification FAILS if coordinator doesn't create summary
2. **Correct Routing**: Lean phases invoke lean-coordinator, software phases invoke implementer-coordinator
3. **Progress Tracking**: Phase markers update as coordinators execute ([IN PROGRESS] → [COMPLETE])
4. **Iteration Support**: Multi-iteration execution works (continuation_context passed correctly)
5. **Error Logging**: Coordinator failures logged to errors.jsonl with full context
6. **Test Coverage**: All test cases pass (pure lean, pure software, hybrid, iteration, failure)

---

## Conclusion

The `/lean-implement` delegation failure stems from absence of the **hard barrier pattern** used successfully in `/implement` and `/lean-build`. The fix requires restructuring 3 blocks to enforce mandatory coordinator invocation with runtime verification.

**Key Architectural Principle**: Enforce delegation through **verification checkpoints** (Block 1c summary check), not **prose instructions** (conditional Task prompts).

**Minimal Changes**: The core iteration logic and phase marker recovery (Blocks 1c-1d) are correct. Only Block 1b needs restructuring, Block 1c needs verification enhancement.

**Timeline**: 8-12 hours total effort across 6 phases (restructure, verify, enhance, integrate, test, document).

**Risk Assessment**: Low - pattern proven in 2 production commands, changes are additive/defensive.

---

**REPORT_CREATED**: /home/benjamin/.config/.claude/specs/052_lean_implement_workflow_fix/reports/001-lean-implement-delegation-analysis.md
