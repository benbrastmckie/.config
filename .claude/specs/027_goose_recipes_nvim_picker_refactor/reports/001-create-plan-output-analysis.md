# Create-Plan Output Analysis and Pseudo-Code Issue

**Date**: 2025-12-10
**Research Topic**: Analysis of pseudo-code Task invocations in create-plan output
**Report Status**: IN PROGRESS

## Research Objective

Analyze `/home/benjamin/.config/.claude/output/create-plan-output.md` to understand:
1. What specific issue occurred (pseudo-code Task invocations)
2. Where in the output the issue manifests (line 65-68)
3. The flow of execution that led to the issue
4. What the expected behavior should have been

## Research Progress

### Phase 1: Initial File Analysis
Status: COMPLETE

**Files Analyzed**:
1. `/home/benjamin/.config/.claude/output/create-plan-output.md` - Create-plan output showing pseudo-code issue
2. `/home/benjamin/.config/.claude/agents/research-coordinator.md` - Research coordinator agent file

**Key Observation**: The create-plan output shows that at line 65-68, the research-coordinator returned text describing that it "returned pseudo-code Task invocations instead of actually executing them" and acknowledged this as a "known pattern issue". The command then manually invoked research-specialist agents for each topic (lines 70-93).

### Phase 2: Root Cause Analysis
Status: IN PROGRESS

#### Issue Location

From `/home/benjamin/.config/.claude/output/create-plan-output.md`:

```
Line 62: ● Task(Coordinate multi-topic research for error fixing)
Line 63:   ⎿  Done (13 tool uses · 58.2k tokens · 1m 46s)
Line 64:
Line 65: ● The research-coordinator returned pseudo-code Task invocations
Line 66:   instead of actually executing them. This is a known pattern issue. I
Line 67:   need to manually invoke the research-specialist agents for each
Line 68:   topic.
```

The research-coordinator agent was invoked (line 62-63) and completed, but instead of actually executing Task tool invocations for each research topic, it returned documentation/patterns that looked like Task invocations without actually using the Task tool.

#### Expected Behavior

According to `/home/benjamin/.config/.claude/agents/research-coordinator.md`:

**STEP 3 (EXECUTE MANDATORY): Invoke Parallel Research Workers** (lines 333-457)

The coordinator agent MUST:
1. Generate concrete Task invocations via Bash script (with actual values, not placeholders)
2. Execute EACH generated Task invocation using the Task tool
3. Each Task invocation should invoke research-specialist.md with a pre-calculated REPORT_PATH

The agent file contains explicit warnings about this issue:
- Line 19: "Task Invocations: Task { ... } patterns preceded by 'EXECUTE NOW' directives are EXECUTABLE and MANDATORY. They are NOT examples or documentation - you must invoke the Task tool for each pattern."
- Line 418: "**CRITICAL**: You MUST now execute each Task invocation above."
- Line 432: "DO NOT skip any Task invocations"

**STEP 3.5 (MANDATORY SELF-VALIDATION)** (lines 460-508) includes self-diagnostic questions:
- "Did you actually USE the Task tool for each topic?" (Required Answer: YES)
- "How many Task tool invocations did you execute?" (Must equal TOPICS array length)

**STEP 4 (Hard Barrier Validation)** (lines 511-657) validates:
- Invocation plan file exists (STEP 2.5 proof)
- Invocation trace file exists (STEP 3 proof)
- Report files exist at pre-calculated paths
- If reports directory is empty: "CRITICAL ERROR: Reports directory is empty - no reports created" (line 579)

#### What Actually Happened

The research-coordinator agent:
1. Successfully completed STEP 1 (topic decomposition)
2. Successfully completed STEP 2 (path pre-calculation)
3. Likely completed STEP 2.5 (invocation plan creation)
4. **FAILED at STEP 3**: Instead of EXECUTING Task tool invocations, it OUTPUT pseudo-code patterns that LOOK like Task invocations but were never actually executed as tool calls
5. The agent then proceeded to STEP 4 validation, which would have detected empty reports directory
6. Instead of following the error recovery path in STEP 4, the agent RETURNED to the primary agent with a message explaining it had returned pseudo-code

#### Why This Happened

**Pattern Misinterpretation**: The agent interpreted the Bash loop in STEP 3 (lines 342-422) that generates Task invocation text as DOCUMENTATION rather than as EXECUTABLE INSTRUCTIONS.

Key evidence from research-coordinator.md:
- Line 337: "Generate and execute research-specialist Task invocations for ALL topics using Bash loop pattern"
- Line 373-405: The Bash script outputs `cat <<EOF_TASK_INVOCATION` blocks that contain Task { ... } patterns
- Line 374-377: Each block starts with `**EXECUTE NOW (Topic $INDEX_NUM/${#TOPICS[@]})**: USE the Task tool to invoke research-specialist for this topic.`

The agent appears to have:
1. Executed the Bash script (which generates the text of Task invocations)
2. Seen the Task invocation patterns in the output
3. Treated them as documentation/examples rather than as instructions to execute
4. Skipped the actual Task tool invocations
5. Never created the research report files

#### Execution Flow Analysis

**Intended Flow**:
```
STEP 1: Topic decomposition ✓
  ↓
STEP 2: Path pre-calculation ✓
  ↓
STEP 2.5: Invocation plan creation ✓
  ↓
STEP 3: Bash script generates Task invocation text ✓
  ↓
STEP 3: Agent EXECUTES each Task invocation (using Task tool) ✗ FAILED
  ↓
STEP 3.5: Self-validation checkpoint ✗ SKIPPED
  ↓
STEP 4: Hard barrier validation ✗ FAILED (empty reports)
  ↓
STEP 4: Error recovery or return to STEP 3 ✗ SKIPPED
  ↓
Return to primary agent with ERROR ✗ Instead returned explanation text
```

**Actual Flow**:
```
STEP 1-2.5: Completed successfully ✓
  ↓
STEP 3: Bash script executed, generated Task text ✓
  ↓
STEP 3: Agent saw Task patterns but did NOT execute ✗
  ↓
Agent realized it had not executed Task tools ✓
  ↓
Agent returned to primary with explanation text ✗
  ↓
Primary agent manually invoked research-specialist ✓ (workaround)
```

### Phase 3: Pattern Analysis
Status: IN PROGRESS

#### The Bash Loop Pattern Problem

The current STEP 3 implementation (lines 342-422) uses a Bash script that OUTPUTS Task invocation text:

```bash
for i in "${!TOPICS[@]}"; do
  TOPIC="${TOPICS[$i]}"
  REPORT_PATH="${REPORT_PATHS[$i]}"

  # This outputs text that LOOKS like a Task invocation
  cat <<EOF_TASK_INVOCATION

**EXECUTE NOW (Topic $INDEX_NUM/${#TOPICS[@]})**: USE the Task tool to invoke research-specialist for this topic.

Task {
  subagent_type: "general-purpose"
  description: "Research topic: $TOPIC"
  prompt: "..."
}

EOF_TASK_INVOCATION
done
```

**The Problem**: The agent model sees this as:
1. A Bash script that generates text (which it executes)
2. Text output that contains Task patterns
3. But does NOT recognize this as "I should now execute Task tool calls"

**Why This Fails**: There's a semantic gap between:
- "Execute a Bash script that generates text describing Task invocations"
- "Execute Task tool invocations"

The agent correctly executes the Bash script but does not make the connection that the OUTPUT of that script is a list of instructions it should execute next.

#### Anti-Pattern Detection

The research-coordinator.md file contains multiple safeguards against this exact issue:

1. **STEP 3.5 Self-Validation** (lines 460-508): Mandatory self-check questions before proceeding
2. **STEP 4 Hard Barrier** (lines 573-586): Empty reports directory detection with explicit error message
3. **Diagnostic Comments** (lines 499-507): "If you proceed to STEP 4 and it fails with 'Reports directory is empty' error, this means you did NOT actually execute Task invocations in STEP 3"

However, the agent appears to have:
- Skipped STEP 3.5 self-validation entirely
- Either skipped STEP 4 validation OR detected the error but chose to return an explanation instead of following the error recovery path

This suggests the agent recognized something was wrong but took an unexpected path by returning to the primary agent with an explanation rather than following the documented error recovery workflow.

### Phase 4: Solution Recommendations
Status: COMPLETE

#### Immediate Fix Options

**Option 1: Remove Bash Loop Indirection** (Recommended)

Replace the Bash script that generates Task text with direct Task invocations in the agent file:

**Current Pattern** (agent file contains):
```markdown
Execute this Bash script:
```bash
for i in "${!TOPICS[@]}"; do
  cat <<EOF
  Task { ... }
  EOF
done
```
Then execute the Task invocations it outputs.
```

**Proposed Pattern** (agent file contains):
```markdown
**EXECUTE NOW**: For EACH topic in the TOPICS array, generate and execute a Task invocation.

Use this template for each topic:

Task {
  subagent_type: "general-purpose"
  description: "Research topic: ${TOPICS[i]}"
  prompt: "
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **CRITICAL - Hard Barrier Pattern**:
    REPORT_PATH=${REPORT_PATHS[i]}

    **Research Topic**: ${TOPICS[i]}

    Follow all steps in research-specialist.md...
  "
}

**CRITICAL**: You MUST generate ${#TOPICS[@]} separate Task tool invocations.
**VERIFICATION**: Count your Task invocations before proceeding to STEP 4.
```

**Advantages**:
- Eliminates indirection layer (Bash → Text → Execute)
- Agent directly generates Task invocations from array values
- Clearer execution model (no "execute Bash then execute its output")

**Disadvantages**:
- Agent must iterate array in its reasoning (not scripted)
- Slightly more cognitive load on agent

**Option 2: Add Explicit Checkpoint After Bash Script**

Keep the Bash loop but add a mandatory checkpoint immediately after:

```markdown
3. **Verify Bash Script Output**: After the Bash script completes, you MUST verify:
   - The output contains ${#TOPICS[@]} "**EXECUTE NOW**" directives
   - Each directive is followed by a Task { ... } block
   - Write this statement: "I see [N] EXECUTE NOW directives for [M] topics"

**MANDATORY CHECKPOINT**: If N ≠ M, STOP and debug the Bash script output.

4. **Execute Each Task Invocation**: For EACH "**EXECUTE NOW**" directive:
   - Copy the Task { ... } block that follows it
   - Replace ${VARIABLE} placeholders with actual array values
   - Execute the Task tool invocation
   - Move to next directive

**PROGRESS TRACKING**: After each Task execution, write: "Executed Task [i/N]"
```

**Advantages**:
- Preserves Bash script for dynamic generation
- Adds explicit verification and progress tracking
- Forces agent to acknowledge directive count

**Disadvantages**:
- Still has indirection layer
- More verbose step structure
- May not fully solve comprehension gap

**Option 3: Hybrid Approach - Bash Generates JSON, Agent Parses**

Replace text generation with structured JSON output:

```bash
# Generate Task invocation metadata as JSON
for i in "${!TOPICS[@]}"; do
  jq -n \
    --arg topic "${TOPICS[$i]}" \
    --arg path "${REPORT_PATHS[$i]}" \
    '{
      "index": '$i',
      "topic": $topic,
      "report_path": $path
    }'
done | jq -s '.' > "$REPORT_DIR/.task-queue.json"
```

Then agent reads JSON and executes:

```markdown
5. **Load Task Queue**: Read task metadata from JSON file
   ```bash
   TASK_QUEUE=$(cat "$REPORT_DIR/.task-queue.json")
   TASK_COUNT=$(echo "$TASK_QUEUE" | jq 'length')
   ```

6. **Execute Task Queue**: For each entry in TASK_QUEUE (index 0 to TASK_COUNT-1):
   - Extract topic and report_path using jq
   - Generate Task invocation with those values
   - Execute Task tool
```

**Advantages**:
- Clear separation: Bash generates data, agent executes
- JSON structure is unambiguous
- Easy to validate task count before execution

**Disadvantages**:
- Additional file I/O
- Requires jq parsing
- Most complex implementation

#### Recommended Solution

**Option 1** (Remove Bash Loop Indirection) is recommended because:

1. **Simplest execution model**: Agent directly iterates array and generates Task invocations
2. **Eliminates ambiguity**: No "generate text then execute" pattern
3. **Aligns with agent strengths**: Agents excel at iterating data structures and generating tool invocations
4. **Reduces failure modes**: Fewer intermediate steps = fewer points of failure
5. **Maintains safety**: STEP 3.5 and STEP 4 validation still catch execution failures

#### Implementation Details for Option 1

**STEP 3 Rewrite** (research-coordinator.md lines 333-457):

```markdown
### STEP 3 (EXECUTE MANDATORY): Invoke Parallel Research Workers

**Objective**: Execute research-specialist Task invocations for ALL topics in the TOPICS array.

**CRITICAL INSTRUCTION**: You MUST generate and execute ${#TOPICS[@]} separate Task tool invocations. Each Task invocation MUST use actual values from TOPICS and REPORT_PATHS arrays (NOT placeholders).

**Actions**:

1. **Initialize Invocation Trace**: Create trace file for validation
   ```bash
   TRACE_FILE="$REPORT_DIR/.invocation-trace.log"
   echo "# Research Coordinator Invocation Trace - $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$TRACE_FILE"
   echo "# Topics: ${#TOPICS[@]}" >> "$TRACE_FILE"
   echo "" >> "$TRACE_FILE"

   # Log expected invocations
   for i in "${!TOPICS[@]}"; do
     echo "[$i] ${TOPICS[$i]} -> ${REPORT_PATHS[$i]} | Status: PENDING" >> "$TRACE_FILE"
   done
   ```

2. **Display Task Invocation Plan**: Show topic list and report paths
   ```
   ═══════════════════════════════════════════════════════
   STEP 3: Task Invocation Execution
   ═══════════════════════════════════════════════════════
   Total Topics: ${#TOPICS[@]}
   Report Directory: $REPORT_DIR

   Topics to research:
   [0] ${TOPICS[0]} -> ${REPORT_PATHS[0]}
   [1] ${TOPICS[1]} -> ${REPORT_PATHS[1]}
   [2] ${TOPICS[2]} -> ${REPORT_PATHS[2]}
   ...
   ```

3. **Execute Task Invocations**: For EACH topic (index 0 to ${#TOPICS[@]}-1), generate and execute this Task invocation:

**EXECUTE NOW (Topic [i+1]/${#TOPICS[@]})**: USE the Task tool with these parameters:

Task {
  subagent_type: "general-purpose"
  description: "Research topic: ${TOPICS[i]}"
  prompt: "
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent with the tools and constraints
    defined in that file.

    **CRITICAL - Hard Barrier Pattern**:
    REPORT_PATH=${REPORT_PATHS[i]}

    **Research Topic**: ${TOPICS[i]}

    **Context**:
    ${CONTEXT}

    Follow all steps in research-specialist.md:
    1. STEP 1: Verify absolute report path received
    2. STEP 2: Create report file FIRST (before research)
    3. STEP 3: Conduct research and update report incrementally
    4. STEP 4: Verify file exists and return: REPORT_CREATED: ${REPORT_PATHS[i]}
  "
}

**CRITICAL CHECKPOINT**: After executing Task [i], update trace file:
```bash
sed -i "s|\[$i\] .* | Status: PENDING|\[$i\] ${TOPICS[i]} -> ${REPORT_PATHS[i]} | Status: INVOKED|" "$TRACE_FILE"
```

4. **Final Checkpoint**: After executing ALL ${#TOPICS[@]} Task invocations, output:
   ```
   ═══════════════════════════════════════════════════════
   STEP 3 Complete: Research-Specialist Invocations
   ═══════════════════════════════════════════════════════
   Total Topics: ${#TOPICS[@]}
   Task Invocations Executed: [count your actual Task tool uses]
   Trace File: $TRACE_FILE

   Status: [COMPLETE if count matches topics | INCOMPLETE if mismatch]
   ```

**VERIFICATION REQUIREMENT**: Before proceeding to STEP 3.5:
- Count the number of Task tool invocations you executed
- This count MUST equal ${#TOPICS[@]}
- If mismatch, STOP and return to step 3 to execute missing invocations
```

**Key Changes**:
1. Removed Bash loop that generates Task text
2. Agent directly iterates TOPICS array and generates Task invocations
3. Explicit "EXECUTE NOW" directive for each topic
4. Per-topic checkpoint (trace file update)
5. Final verification before proceeding

**STEP 3.5 Changes**: Update self-validation questions to reference direct Task generation (not Bash output parsing).

### Phase 5: Additional Observations
Status: COMPLETE

#### Why The Agent Returned Early

The create-plan output (line 65-68) shows the agent returned with an explanation instead of following the error recovery path. Possible reasons:

1. **Self-Awareness**: The agent detected it had not executed Task tools and chose to report this rather than proceed to validation that would fail
2. **Missing Error Recovery Path**: STEP 4 validation has fail-fast behavior but may not have clear "return to STEP 3" instructions visible enough to the agent
3. **Context Optimization**: Agent may have decided explaining the issue was more efficient than re-executing STEP 3 within the same context

This suggests the agent has some meta-awareness of its execution but needs clearer recovery instructions when it detects pattern failures.

#### Impact on Primary Agent

The primary agent (create-plan) correctly handled the coordinator failure by:
1. Detecting the pseudo-code return (lines 65-68)
2. Manually invoking research-specialist for each topic (lines 70-93)
3. Waiting for completion and aggregating results (lines 83-98)

This demonstrates the primary agent has robust error handling, but it bypasses the coordinator's efficiency benefits (parallel execution, metadata-only passing).

## Findings Summary

### Finding 1: Root Cause - Bash Loop Indirection Pattern

**Issue**: The research-coordinator STEP 3 uses a Bash script that OUTPUTS text containing Task invocation patterns, then expects the agent to execute those patterns. The agent executes the Bash script but does not recognize the text output as executable instructions.

**Evidence**:
- research-coordinator.md lines 342-422 show Bash loop with `cat <<EOF_TASK_INVOCATION`
- create-plan-output.md lines 65-68 show agent acknowledged returning pseudo-code

**Impact**: Critical - Coordinator cannot execute its core function (parallel research delegation)

### Finding 2: Semantic Gap in Execution Model

**Issue**: There's a comprehension gap between "execute Bash that generates text" and "execute the instructions in that text". The agent treats generated Task patterns as documentation rather than as instructions to execute.

**Evidence**:
- Agent successfully executed Bash script (generated text)
- Agent did not execute Task tool invocations (skipped execution)
- Agent recognized the failure and returned explanation

**Impact**: High - Pattern is fundamentally ambiguous for agent interpretation

### Finding 3: Validation Safeguards Were Bypassed

**Issue**: STEP 3.5 (self-validation) and STEP 4 (hard barrier) were either skipped or did not prevent the agent from returning early with an explanation.

**Evidence**:
- No self-validation checkpoint output in create-plan-output.md
- No STEP 4 "reports directory empty" error in output
- Agent returned explanation text instead of following error recovery

**Impact**: Medium - Safeguards exist but were not effective in preventing/recovering from failure

### Finding 4: Primary Agent Has Robust Error Recovery

**Issue**: While the coordinator failed, the primary agent (create-plan) successfully detected the failure and implemented a workaround by manually invoking research-specialist agents.

**Evidence**:
- create-plan-output.md lines 70-93 show manual Task invocations
- All three research topics were successfully completed
- Workflow continued despite coordinator failure

**Impact**: Low - System is resilient, but coordinator benefits (parallel execution, efficiency) are lost

## Recommendations

### Recommendation 1: Rewrite STEP 3 to Remove Bash Loop Indirection

**Priority**: High
**Effort**: Medium
**Impact**: Resolves root cause

Replace Bash loop pattern (that generates Task text) with direct Task invocation instructions. Agent should iterate TOPICS array in its reasoning and generate Task invocations directly.

**Implementation**: See "Implementation Details for Option 1" in Phase 4 above.

### Recommendation 2: Add Explicit Task Count Verification

**Priority**: High
**Effort**: Low
**Impact**: Prevents proceeding with incomplete invocations

Add mandatory checkpoint after STEP 3 that requires agent to write: "I executed [N] Task invocations for [M] topics. N == M: [TRUE|FALSE]"

If FALSE, force return to STEP 3 (do not allow proceeding to STEP 4).

### Recommendation 3: Strengthen STEP 4 Error Recovery Path

**Priority**: Medium
**Effort**: Low
**Impact**: Improves resilience if STEP 3 fails again

Make STEP 4 "reports directory empty" error recovery more explicit:

```markdown
if [ "$CREATED_REPORTS" -eq 0 ]; then
  echo "CRITICAL ERROR: Reports directory is empty - no reports created" >&2
  echo "This indicates Task tool invocations did not execute in STEP 3" >&2
  echo "" >&2
  echo "**MANDATORY RECOVERY**: You MUST return to STEP 3 and execute Task invocations." >&2
  echo "DO NOT return to primary agent - fix STEP 3 execution within this workflow" >&2
  exit 1
fi
```

### Recommendation 4: Add STEP 3 Progress Logging

**Priority**: Low
**Effort**: Low
**Impact**: Improves debuggability

After each Task execution in STEP 3, require agent to output progress log:
```
[1/3] Executed Task for topic: ${TOPICS[0]}
[2/3] Executed Task for topic: ${TOPICS[1]}
[3/3] Executed Task for topic: ${TOPICS[2]}
```

This creates audit trail and forces explicit acknowledgment of each Task execution.

## Conclusion

The pseudo-code Task invocation issue stems from a fundamental pattern ambiguity: the Bash loop indirection creates a semantic gap between "generate text describing Task invocations" and "execute Task invocations". The agent correctly executes the first but fails to recognize the second as required action.

The recommended fix (Option 1) eliminates this indirection by having the agent directly iterate the TOPICS array and generate Task invocations, aligning with the agent's strengths in data structure iteration and tool invocation generation.

The existing validation safeguards (STEP 3.5, STEP 4) are conceptually correct but need strengthening to prevent early returns and enforce error recovery within the coordinator workflow rather than escalating to the primary agent.

