# Agent Enhancement and Error Handling Fix Strategy

## Executive Summary

This report documents the root causes behind research-coordinator agent failures and provides comprehensive fix strategies for three critical issues:

1. **Pseudo-code Task invocations** - The research-coordinator.md behavioral file uses Task { } syntax that agents interpret as documentation rather than executable directives
2. **Missing hard barrier validation** - Commands don't validate coordinator output before proceeding, allowing silent failures
3. **Poor agent output retrieval error handling** - "Error retrieving agent output" messages lack context and recovery mechanisms

The analysis shows that while the research-coordinator workflow has strong documentation and self-validation checkpoints (STEP 3.5), the actual Task invocations use pseudo-code patterns that Claude interprets as examples rather than executable instructions.

## Root Cause Analysis

### Issue 1: Pseudo-Code Task Invocation Patterns

**Problem Location**: `/home/benjamin/.config/.claude/agents/research-coordinator.md` lines 239-346

**Current Pattern** (from research-coordinator.md):
```markdown
**EXECUTE NOW - DO NOT SKIP**: USE the Task tool to invoke research-specialist for topic at index 0.

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPICS[0]}"
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **CRITICAL - Hard Barrier Pattern**:
    REPORT_PATH=${REPORT_PATHS[0]}

    **Research Topic**: ${TOPICS[0]}
    ...
  "
}
```

**Why This Fails**:
- The `Task { }` syntax is **pseudo-code** showing the expected structure
- Claude interprets this as a **documentation example**, not an actual tool invocation
- The agent reads through STEP 3, sees the Task patterns, but doesn't execute them
- Result: No research-specialist agents are spawned, reports directory remains empty

**Evidence from Debug Output** (`/home/benjamin/.config/.claude/output/debug-output.md`):
- Line 67: research-coordinator completed with only 7 tool uses (should be 7 + 4 Task invocations = 11)
- Line 84-87: Reports directory was empty after coordinator returned
- Line 92-104: Orchestrator had to manually invoke 4 research-specialist agents as fallback

### Issue 2: Missing Hard Barrier Validation in Orchestrators

**Problem Location**: `/home/benjamin/.config/.claude/commands/create-plan.md` Block 1e-exec and 1f

**Current Gap**:
The create-plan command invokes research-coordinator but does **not** validate the coordinator's output signal before proceeding to hard barrier validation in Block 1f.

**Expected Pattern** (from other commands):
```bash
# After Task invocation completes
COORDINATOR_OUTPUT="<agent output here>"

# Validate completion signal exists
if ! echo "$COORDINATOR_OUTPUT" | grep -q "RESEARCH_COMPLETE:"; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "research-coordinator did not return RESEARCH_COMPLETE signal" \
    "bash_block_1f" \
    "$(jq -n --arg output "$COORDINATOR_OUTPUT" '{coordinator_output: $output}')"

  echo "ERROR: research-coordinator failed to complete - no RESEARCH_COMPLETE signal" >&2
  echo "Falling back to direct research-specialist invocation..." >&2
  # Fallback logic here
fi
```

**Why This Matters**:
- Without signal validation, silent failures go undetected
- The hard barrier check (verifying report files exist) comes too late
- By the time empty directory is detected, coordinator has already consumed time/context
- No structured error logging for debugging coordinator failures

### Issue 3: Poor Agent Output Retrieval Error Handling

**Problem Location**: Debug output line 74: "Error retrieving agent output"

**Current Behavior**:
When agent output retrieval fails, the error message provides:
- ❌ No context about which agent failed
- ❌ No agent ID for debugging
- ❌ No reason for retrieval failure
- ❌ No structured error logging
- ❌ No recovery strategy

**Root Cause**:
This error likely comes from the AgentOutput tool failing to retrieve results from agent ID `90639fbf`. Possible reasons:
- Agent hit context limits and output was truncated
- Agent completed abnormally (error during execution)
- Output parsing failed due to malformed response
- Agent never returned (timeout/hang)

**Impact**:
- Debug output shows orchestrator tried to "resume" the agent (lines 69-71), suggesting confusion about completion state
- No structured error logged to errors.jsonl for `/errors` or `/repair` analysis
- Manual debugging required to understand what happened

## Recommended Fix Strategies

### Fix 1: Convert Pseudo-Code to Explicit Task Invocations

**Approach**: Update research-coordinator.md to use stronger execution directives that cannot be misinterpreted.

**Option A: Imperative Instruction Pattern** (Recommended)

Replace the current Task { } pseudo-code with explicit instructions:

```markdown
**EXECUTE NOW - DO NOT SKIP**: YOU MUST invoke the Task tool for topic at index 0.

DO NOT read this as an example. DO NOT skip this step. You MUST execute this Task invocation.

Before continuing to topic index 1, verify you have actually used the Task tool for topic 0.

**Task Parameters**:
- subagent_type: "general-purpose"
- description: "Research ${TOPICS[0]}"
- prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **CRITICAL - Hard Barrier Pattern**:
    REPORT_PATH=${REPORT_PATHS[0]}

    **Research Topic**: ${TOPICS[0]}

    **Context**:
    ${CONTEXT}

    Follow all steps in research-specialist.md:
    1. STEP 1: Verify absolute report path received
    2. STEP 2: Create report file FIRST (before research)
    3. STEP 3: Conduct research and update report incrementally
    4. STEP 4: Verify file exists and return: REPORT_CREATED: ${REPORT_PATHS[0]}

**CHECKPOINT**: Did you just use the Task tool? If NO, go back and use it now.
```

**Option B: Iterative Loop Pattern** (Alternative)

Replace static invocations with a dynamic loop:

```markdown
### STEP 3: Invoke Parallel Research Workers

**MANDATORY EXECUTION**: For each topic in TOPICS array, invoke research-specialist using Task tool.

**Loop Structure**:

```bash
# This is NOT a bash block to execute - this shows the conceptual pattern
for i in "${!TOPICS[@]}"; do
  Task {
    subagent_type: "general-purpose"
    description: "Research ${TOPICS[$i]}"
    prompt: "... (full prompt with ${REPORT_PATHS[$i]}) ..."
  }
done
```

**CRITICAL**: You must generate ONE Task tool invocation per topic. Count the topics and verify your invocation count matches.

**Execution Checklist** (complete before proceeding to STEP 4):
- [ ] How many topics in TOPICS array? _____
- [ ] How many Task tool invocations did you execute? _____
- [ ] Do these numbers match? YES / NO
- [ ] If NO, return to beginning of STEP 3 and execute missing invocations

**FAIL-FAST**: If you cannot answer YES to the match question, STOP and re-execute STEP 3.
```

**Recommendation**: Use **Option A** for research-coordinator because:
- More explicit about each invocation being mandatory
- Harder to misinterpret as documentation
- Includes per-topic checkpoints
- Aligns with existing STEP 3.5 self-validation

### Fix 2: Add Hard Barrier Output Validation to Orchestrators

**Location**: `/home/benjamin/.config/.claude/commands/create-plan.md` after Block 1e-exec

**Add New Block: 1e-validate**

```markdown
## Block 1e-validate: Coordinator Output Validation

**EXECUTE NOW**: Validate that research-coordinator returned expected completion signal.

This validation occurs BEFORE the hard barrier report file checks to catch coordinator failures early.

```bash
set +H  # CRITICAL: Disable history expansion

# === DETECT PROJECT DIRECTORY ===
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

export CLAUDE_PROJECT_DIR

# === RESTORE STATE ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
source "$STATE_FILE" 2>/dev/null || {
  echo "ERROR: Cannot restore state" >&2
  exit 1
}

COMMAND_NAME="/create-plan"
USER_ARGS="${FEATURE_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === RETRIEVE COORDINATOR OUTPUT ===
# CRITICAL: Replace <COORDINATOR_OUTPUT_VARIABLE> with actual agent output from Block 1e-exec
# This will be populated automatically by Claude after Task invocation completes
COORDINATOR_OUTPUT="<COORDINATOR_OUTPUT_FROM_BLOCK_1E_EXEC>"

# === VALIDATE COMPLETION SIGNAL ===
echo "=== Coordinator Output Validation ==="
echo "Checking for RESEARCH_COMPLETE signal..."

if ! echo "$COORDINATOR_OUTPUT" | grep -q "RESEARCH_COMPLETE:"; then
  # Check if coordinator returned error signal
  if echo "$COORDINATOR_OUTPUT" | grep -q "TASK_ERROR:"; then
    echo "ERROR: research-coordinator returned error" >&2
    parse_subagent_error "$COORDINATOR_OUTPUT" "research-coordinator"
    exit 1
  fi

  # No completion signal and no error - coordinator failed silently
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "research-coordinator failed to complete - no RESEARCH_COMPLETE signal found" \
    "bash_block_1e_validate" \
    "$(jq -n --arg output "${COORDINATOR_OUTPUT:0:500}" '{coordinator_output_preview: $output}')"

  echo "ERROR: research-coordinator failed to complete properly" >&2
  echo "Expected: RESEARCH_COMPLETE: <count>" >&2
  echo "Got: <no completion signal>" >&2
  echo "" >&2
  echo "This indicates the coordinator did not execute research-specialist Task invocations" >&2
  echo "Review .claude/agents/research-coordinator.md STEP 3 for root cause" >&2
  exit 1
fi

# Extract report count from signal
EXPECTED_REPORT_COUNT=$(echo "$COORDINATOR_OUTPUT" | grep -o "RESEARCH_COMPLETE: [0-9]*" | grep -o "[0-9]*")

if [ -z "$EXPECTED_REPORT_COUNT" ] || [ "$EXPECTED_REPORT_COUNT" -eq 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "research-coordinator reported zero reports created" \
    "bash_block_1e_validate" \
    "$(jq -n --arg signal "RESEARCH_COMPLETE: $EXPECTED_REPORT_COUNT" '{completion_signal: $signal}')"

  echo "ERROR: research-coordinator reported zero reports created" >&2
  exit 1
fi

echo "✓ Coordinator completed successfully"
echo "  Expected reports: $EXPECTED_REPORT_COUNT"
echo ""
echo "Proceeding to hard barrier report validation..."
```
```

**Benefits**:
- Catches coordinator failures **before** hard barrier file checks
- Provides structured error logging for `/errors` and `/repair` workflows
- Gives actionable diagnostics (points to research-coordinator.md STEP 3)
- Enables early-exit instead of wasting time on hard barrier validation

### Fix 3: Improve Agent Output Retrieval Error Handling

**Problem**: Current error "Error retrieving agent output" provides no context.

**Solution**: Wrap Task invocations with structured error handling.

**Pattern to Add in Commands** (example for create-plan.md Block 1e-exec):

```markdown
## Block 1e-exec: Research Coordinator Invocation

**EXECUTE NOW**: USE the Task tool to invoke the research-coordinator agent.

**CRITICAL**: After the Task invocation completes, capture the output and check for errors.

If you receive "Error retrieving agent output" or similar message:
1. Log the agent ID that failed
2. Log the error message received
3. Log the workflow context (which command, which block, which agent)
4. Attempt graceful recovery (fallback to direct research-specialist invocation)

**Expected Flow**:
1. Invoke Task tool with research-coordinator parameters
2. Capture agent output (automatically provided by Claude)
3. Check if output contains error message
4. If error: Log structured error and attempt recovery
5. If success: Proceed to output validation (Block 1e-validate)

**Recovery Strategy** (if agent output retrieval fails):
- Fall back to direct research-specialist invocations (parallel execution)
- Log the coordinator failure for post-mortem analysis
- Continue workflow using fallback results
```

**Structured Error Logging Pattern**:

```bash
# In bash validation block after Task invocation
AGENT_OUTPUT="<captured from Task invocation>"

# Check for agent output retrieval failures
if echo "$AGENT_OUTPUT" | grep -qi "error retrieving agent output"; then
  # Extract agent ID if available (pattern: "agent output <ID>")
  AGENT_ID=$(echo "$AGENT_OUTPUT" | grep -oP 'output \K[a-f0-9]+' || echo "unknown")

  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Failed to retrieve output from research-coordinator agent" \
    "bash_block_1e_exec" \
    "$(jq -n \
      --arg agent_id "$AGENT_ID" \
      --arg agent_name "research-coordinator" \
      --arg error_msg "${AGENT_OUTPUT:0:500}" \
      '{agent_id: $agent_id, agent_name: $agent_name, error_preview: $error_msg}')"

  echo "ERROR: Could not retrieve research-coordinator output (agent ID: $AGENT_ID)" >&2
  echo "Attempting graceful recovery via fallback..." >&2

  # Set flag to trigger fallback in next block
  export COORDINATOR_FAILED=true
fi
```

## Implementation Priority

### Phase 1: Critical Fixes (Immediate)

1. **Fix research-coordinator.md Task invocations** (Fix 1 - Option A)
   - Impact: HIGH - Prevents silent coordinator failures
   - Effort: MEDIUM - Requires careful rewording of STEP 3
   - Files: `.claude/agents/research-coordinator.md`
   - Testing: Run `/create-plan` and verify research-coordinator executes all Task invocations

2. **Add coordinator output validation to create-plan** (Fix 2)
   - Impact: HIGH - Early detection of coordinator failures
   - Effort: LOW - Add single validation block
   - Files: `.claude/commands/create-plan.md`
   - Testing: Verify validation catches coordinator failures before hard barrier

### Phase 2: Robustness Improvements (Short-term)

3. **Add structured error handling for agent output retrieval** (Fix 3)
   - Impact: MEDIUM - Better debugging experience
   - Effort: MEDIUM - Add error handling to all coordinator invocations
   - Files: `.claude/commands/create-plan.md`, `.claude/commands/lean-plan.md`
   - Testing: Verify errors are logged to errors.jsonl with full context

4. **Apply similar fixes to other coordinators**
   - Impact: MEDIUM - Prevents similar issues in other workflows
   - Effort: MEDIUM - Pattern replication across coordinator agents
   - Files: `implementer-coordinator.md`, `lean-coordinator.md`, etc.
   - Testing: Run each coordinator's command and verify Task invocations execute

### Phase 3: Preventive Measures (Long-term)

5. **Create linter rule for pseudo-code Task patterns**
   - Impact: LOW - Prevents future regressions
   - Effort: MEDIUM - Develop detection regex and enforcement
   - Files: New validator script in `.claude/scripts/validators/`
   - Testing: Run on all agent behavioral files

6. **Document Task invocation best practices**
   - Impact: LOW - Developer education
   - Effort: LOW - Add to agent authoring standards
   - Files: `.claude/docs/reference/standards/agent-authoring.md`

## Code Examples

### Example 1: Fixed research-coordinator.md STEP 3

**Before** (lines 240-273):
```markdown
**EXECUTE NOW - DO NOT SKIP**: USE the Task tool to invoke research-specialist for topic at index 0.

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPICS[0]}"
  prompt: "..."
}
```

**After**:
```markdown
**EXECUTE NOW - DO NOT SKIP**: YOU MUST invoke the Task tool for topic at index 0.

This is NOT documentation. This is NOT an example. You MUST execute this Task invocation NOW.

**Invocation Parameters**:
- **subagent_type**: "general-purpose"
- **description**: "Research ${TOPICS[0]}"
- **prompt**:
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent.

    **CRITICAL - Hard Barrier Pattern**:
    REPORT_PATH=${REPORT_PATHS[0]}

    **Research Topic**: ${TOPICS[0]}

    **Context**:
    ${CONTEXT}

    Follow all steps in research-specialist.md:
    1. STEP 1: Verify absolute report path received
    2. STEP 2: Create report file FIRST (before research)
    3. STEP 3: Conduct research and update report incrementally
    4. STEP 4: Verify file exists and return: REPORT_CREATED: ${REPORT_PATHS[0]}

**MANDATORY CHECKPOINT**: Did you just use the Task tool? If NO, you MUST go back and use it NOW before proceeding to topic index 1.

**Self-Verification Questions**:
1. Did I actually invoke the Task tool (not just read the parameters)? YES/NO
2. Did I receive output from the Task invocation? YES/NO
3. If both answers are not YES, return to the beginning of this topic and execute the Task invocation.
```

### Example 2: create-plan.md Coordinator Output Validation

**Add after Block 1e-exec** (new Block 1e-validate):

```markdown
## Block 1e-validate: Coordinator Output Validation

**EXECUTE NOW**: Validate research-coordinator completion signal before proceeding to hard barrier.

```bash
set +H

# [Project directory detection and state restoration code here]

# === COORDINATOR OUTPUT VALIDATION ===
echo "=== Research Coordinator Output Validation ==="

# CRITICAL: COORDINATOR_OUTPUT is populated by Claude after Block 1e-exec Task completes
# This variable contains the full output from research-coordinator agent
COORDINATOR_OUTPUT="<POPULATED_BY_CLAUDE_FROM_PREVIOUS_TASK>"

# Validate RESEARCH_COMPLETE signal exists
if ! echo "$COORDINATOR_OUTPUT" | grep -q "RESEARCH_COMPLETE:"; then
  # Check for explicit error signal
  if echo "$COORDINATOR_OUTPUT" | grep -q "TASK_ERROR:"; then
    parse_subagent_error "$COORDINATOR_OUTPUT" "research-coordinator"
    exit 1
  fi

  # No signal - coordinator failed silently
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "research-coordinator failed - no RESEARCH_COMPLETE signal" \
    "bash_block_1e_validate" \
    "$(jq -n --arg output "${COORDINATOR_OUTPUT:0:1000}" '{output_preview: $output}')"

  echo "ERROR: research-coordinator did not complete properly" >&2
  echo "Expected: RESEARCH_COMPLETE: N" >&2
  echo "This indicates Task invocations were not executed in coordinator STEP 3" >&2
  exit 1
fi

# Extract and validate report count
REPORT_COUNT=$(echo "$COORDINATOR_OUTPUT" | grep -oP 'RESEARCH_COMPLETE: \K\d+')

if [ -z "$REPORT_COUNT" ] || [ "$REPORT_COUNT" -eq 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "research-coordinator reported zero reports" \
    "bash_block_1e_validate" \
    "$(jq -n --argjson count "${REPORT_COUNT:-0}" '{report_count: $count}')"
  exit 1
fi

echo "✓ Coordinator validation passed"
echo "  Reports expected: $REPORT_COUNT"
echo "Proceeding to hard barrier file validation..."
```
```

### Example 3: Agent Output Retrieval Error Handler

**Pattern for all commands invoking coordinators**:

```bash
# After Task invocation completes
AGENT_OUTPUT="<from Task invocation>"

# Check for retrieval errors
if echo "$AGENT_OUTPUT" | grep -qi "error retrieving\|failed to retrieve"; then
  AGENT_ID=$(echo "$AGENT_OUTPUT" | grep -oP 'agent.*\K[a-f0-9]{8}' || echo "unknown")

  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Failed to retrieve agent output (ID: $AGENT_ID)" \
    "bash_block_<BLOCK_ID>" \
    "$(jq -n \
      --arg agent_id "$AGENT_ID" \
      --arg agent_name "<AGENT_NAME>" \
      --arg error "${AGENT_OUTPUT:0:500}" \
      '{agent_id: $agent_id, agent_name: $agent_name, error: $error}')"

  echo "ERROR: Agent output retrieval failed" >&2
  echo "Agent: <AGENT_NAME> (ID: $AGENT_ID)" >&2
  echo "Fallback strategy: [DESCRIBE RECOVERY APPROACH]" >&2

  # Execute fallback strategy
  # ...
fi
```

## Testing Strategy

### Test 1: Verify research-coordinator Task Invocations

**Objective**: Confirm research-coordinator executes all Task invocations in STEP 3

**Method**:
1. Apply Fix 1 to research-coordinator.md
2. Run `/create-plan "test feature with 4 research topics"`
3. Monitor create-plan output for research-coordinator execution
4. Verify:
   - Coordinator invokes 4 Task tools (one per topic)
   - No empty reports directory error
   - No fallback to manual research-specialist invocation
   - RESEARCH_COMPLETE signal includes count of 4

**Expected Result**: All 4 reports created by research-specialist agents invoked by coordinator

### Test 2: Validate Coordinator Output Signal Detection

**Objective**: Confirm Block 1e-validate catches coordinator failures

**Method**:
1. Apply Fix 2 to create-plan.md (add Block 1e-validate)
2. Intentionally break research-coordinator.md (remove RESEARCH_COMPLETE signal)
3. Run `/create-plan "test feature"`
4. Verify:
   - Block 1e-validate detects missing signal
   - Structured error logged to errors.jsonl
   - Workflow exits with clear error message
   - Error message points to research-coordinator.md STEP 3

**Expected Result**: Early detection of coordinator failure with actionable diagnostics

### Test 3: Error Logging for Agent Output Retrieval

**Objective**: Verify agent output retrieval errors are logged properly

**Method**:
1. Apply Fix 3 to create-plan.md
2. Simulate agent output retrieval failure (mock error response)
3. Verify:
   - Error logged to errors.jsonl with agent ID
   - Error includes workflow context (command, block, agent name)
   - Error message is actionable
   - Fallback strategy is attempted

**Expected Result**: Structured error in errors.jsonl with full debugging context

## Related Patterns in Other Agents

### Successful Task Invocation Pattern: implementer-coordinator.md

**Lines 258-297** show a working pattern:

```markdown
**EXECUTE NOW**: USE the Task tool to invoke the implementation-executor.

Task {
  subagent_type: "general-purpose"
  description: "Execute Phase 2 implementation"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/user/.config/.claude/agents/implementation-executor.md
    ...
}
```

**Why This Works**:
- Uses "**EXECUTE NOW**: USE the Task tool" imperative
- Task { } appears immediately after execution directive
- Context clearly indicates this is an action, not documentation

**Difference from research-coordinator**:
- implementer-coordinator has fewer invocations (1-3 per wave)
- research-coordinator has 2-5 invocations in rapid succession
- Higher cognitive load may cause research-coordinator to skip invocations

### Hard Barrier Pattern: lean-implement.md

**Lines 891-939** demonstrate proper hard barrier validation:

```bash
echo "=== Hard Barrier Verification ==="

# === VALIDATE SUMMARY EXISTENCE [HARD BARRIER] ===
if [ ! -f "$SUMMARY_PATH" ]; then
  echo "ERROR: HARD BARRIER FAILED - Summary not created by $COORDINATOR_NAME" >&2
  # [Structured error logging]
  exit 1
fi

# Size validation
SUMMARY_SIZE=$(wc -c < "$SUMMARY_PATH")
if [ "$SUMMARY_SIZE" -lt 500 ]; then
  echo "ERROR: HARD BARRIER FAILED - Summary file too small" >&2
  exit 1
fi
```

**Recommendation**: Apply similar pattern to create-plan.md for coordinator output validation

## Conclusion

The root cause of research-coordinator failures is the pseudo-code Task invocation pattern in the behavioral file. Claude interprets `Task { }` syntax as documentation examples rather than executable directives.

The fixes are straightforward:
1. **Rephrase Task invocations** with stronger execution directives (Fix 1)
2. **Add output validation** to catch failures early (Fix 2)
3. **Improve error handling** for retrieval failures (Fix 3)

These changes will:
- Prevent silent coordinator failures
- Enable early detection with actionable diagnostics
- Improve debugging experience via structured error logging
- Maintain consistency with hard barrier patterns used elsewhere

**Next Steps**:
1. Implement Fix 1 (research-coordinator.md Task invocations)
2. Test with `/create-plan` to verify all Task invocations execute
3. Implement Fix 2 (coordinator output validation)
4. Implement Fix 3 (error handling) for robustness
5. Apply patterns to other coordinator agents

## References

- **Debug Output**: `/home/benjamin/.config/.claude/output/debug-output.md` (root cause analysis lines 83-174)
- **research-coordinator Agent**: `/home/benjamin/.config/.claude/agents/research-coordinator.md` (STEP 3 lines 219-369)
- **create-plan Command**: `/home/benjamin/.config/.claude/commands/create-plan.md` (Block 1e-exec line 1430-1444)
- **Error Handling Library**: `/home/benjamin/.config/.claude/lib/core/error-handling.sh` (parse_subagent_error function line 746-753)
- **implementer-coordinator Pattern**: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` (successful Task pattern lines 258-297)
- **Hard Barrier Pattern**: `/home/benjamin/.config/.claude/commands/lean-implement.md` (validation example lines 891-939)
