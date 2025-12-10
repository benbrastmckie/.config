# Research Report: Research Coordinator Architecture and Task Invocation Pattern Analysis

**Research Topic**: Analysis of research-coordinator agent Task invocation patterns and architectural implications

**Date**: 2025-12-10

**Status**: IN PROGRESS

## Research Objectives

1. Read `/home/benjamin/.config/.claude/agents/research-coordinator.md`
2. Focus on STEP 3: Invoke Parallel Research Workers
3. Analyze the Task invocation pattern in the Bash heredoc (lines 373-405)
4. Understand why Task patterns in Bash output don't get executed
5. Compare with command-authoring.md Task invocation requirements

## Research Context

The research-coordinator.md uses a Bash heredoc to output Task invocation patterns as text. The model cannot programmatically invoke tools based on text output from Bash - it can only invoke tools based on instructions in the conversation. This creates a fundamental architectural issue.

---

## Research Findings

### Section 1: Research Coordinator Agent Structure

The research-coordinator.md file (1190 lines) serves as an executable behavioral guideline for a supervisor agent that orchestrates parallel research-specialist invocations. Key structural elements:

**Agent Metadata (Lines 1-11)**:
- `allowed-tools: Task, Read, Bash, Grep`
- `model: sonnet-4.5` (coordination role requires reliable reasoning)
- `dependent-agents: research-specialist`
- Critical note: "This file contains EXECUTABLE DIRECTIVES for the research-coordinator agent"

**Workflow Structure**:
- STEP 0.5: Error handler installation
- STEP 1: Receive and verify research topics
- STEP 2: Pre-calculate report paths (hard barrier pattern)
- STEP 2.5: Invocation planning (pre-execution barrier)
- **STEP 3: Invoke parallel research workers** (CRITICAL - analyzed below)
- STEP 3.5: Verify Task invocations (self-validation)
- STEP 4: Validate research artifacts (hard barrier)
- STEP 5: Extract metadata
- STEP 6: Return aggregated metadata

**Return Protocol**:
- Completion signal: `RESEARCH_COORDINATOR_COMPLETE: SUCCESS`
- Metadata-only passing: 95% context reduction (7,500 → 330 tokens for 3 reports)
- Error signals via TASK_ERROR protocol

### Section 2: STEP 3 Task Invocation Pattern (Lines 333-458)

**Current Implementation Architecture**:

STEP 3 uses a **Bash heredoc to OUTPUT Task invocation patterns as text**. The agent generates markdown text containing Task blocks but does NOT actually invoke the Task tool programmatically.

**Code Analysis (Lines 373-405)**:

```bash
# Output the actual Task invocation (this is what the agent must execute)
cat <<EOF_TASK_INVOCATION

---

**EXECUTE NOW (Topic $INDEX_NUM/${#TOPICS[@]})**: USE the Task tool to invoke research-specialist for this topic.

Task {
  subagent_type: "general-purpose"
  description: "Research topic: $TOPIC"
  prompt: "
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **CRITICAL - Hard Barrier Pattern**:
    REPORT_PATH=$REPORT_PATH

    **Research Topic**: $TOPIC

    **Context**:
    $CONTEXT

    Follow all steps in research-specialist.md:
    1. STEP 1: Verify absolute report path received
    2. STEP 2: Create report file FIRST (before research)
    3. STEP 3: Conduct research and update report incrementally
    4. STEP 4: Verify file exists and return: REPORT_CREATED: $REPORT_PATH
  "
}

EOF_TASK_INVOCATION
```

**Critical Issue**: This heredoc uses `cat <<EOF_TASK_INVOCATION ... EOF_TASK_INVOCATION` to output text. The bash script executes successfully (exit 0), but the output is just text in Claude's conversation context. The model reads this text but has no mechanism to programmatically invoke tools based on bash output.

### Section 3: Why Task Patterns in Bash Output Don't Execute

**Root Cause**: The Claude Code execution model separates bash execution from conversation context. Task tool invocations can only be triggered by:

1. **Direct Task blocks in conversation** (outside bash code blocks)
2. **Imperative directives in markdown** (e.g., "**EXECUTE NOW**: USE the Task tool...")

**What Doesn't Work**:
- Task patterns inside bash output (stdout from bash blocks)
- Task patterns inside heredocs (text generation, not tool invocation)
- Task patterns in variables or files (no dynamic parsing)

**Why This Fails**:
1. Bash block executes → produces text output to stdout
2. Text contains Task invocation patterns (valid syntax)
3. Claude receives bash output as string data
4. Model interprets output as information, not as instructions
5. No tool invocation occurs because model cannot programmatically invoke tools based on text it reads

**Analogy**: This is like a bash script that prints "echo hello" to stdout. The text "echo hello" appears in output but doesn't get executed as a command. Similarly, printing "Task { ... }" to stdout displays the pattern but doesn't invoke the Task tool.

### Section 4: Comparison with Command Authoring Standards

**Command Authoring Standards (command-authoring.md Lines 99-148)**:

Required Task invocation pattern:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${FEATURE_DESCRIPTION} with mandatory file creation"
  prompt: "..."
}
```

**Key Requirements**:
1. **NO code block wrapper** - Remove ` ```yaml ` fences
2. **Imperative instruction** - "**EXECUTE NOW**: USE the Task tool..."
3. **Inline prompt** - Variables interpolated directly
4. **Completion signal** - Agent must return explicit signal

**Correct Pattern Location**:
- Task invocations MUST appear in markdown (outside bash blocks)
- Imperative directives MUST precede Task blocks
- No bash generation of Task patterns via heredocs

### Section 5: Architectural Contradiction

**The Fundamental Problem**:

The research-coordinator.md design assumes:
- Agent reads STEP 3 bash script
- Agent executes bash script (generates Task patterns via heredoc)
- Agent reads bash output
- Agent interprets Task patterns as executable instructions
- Agent invokes Task tool for each pattern

**Reality**:
- Agent reads STEP 3 bash script ✓
- Agent executes bash script ✓
- Bash script outputs Task patterns to stdout ✓
- Agent receives bash output as string data ✓
- **Agent has no mechanism to programmatically invoke tools from bash output** ✗

**Why This Architectural Pattern Fails**:

1. **Separation of Execution Contexts**: Bash execution happens in subprocess. Task tool invocation happens in conversation context. No bridge exists between them.

2. **Model Interpretation Boundary**: Claude reads bash output as information (like reading a file), not as instructions. The model cannot execute tool calls based on text it reads - it can only execute tool calls based on instructions in the conversation flow.

3. **Dynamic Generation Limitation**: While bash can dynamically generate text, the model cannot dynamically parse that text into tool invocations. Tool invocations must be statically present in the agent's conversation (markdown directives).

### Section 6: Evidence from Agent Behavioral Guidelines

**Lines 296-343 (Agent Behavioral File Task Patterns)**:

The command-authoring.md explicitly addresses this pattern:

```markdown
#### Agent Behavioral File Task Patterns

When agent behavioral files (e.g., research-coordinator.md) contain Task invocations that the agent should execute, use the same standards-compliant pattern as commands:

**CRITICAL REQUIREMENTS**:
1. **No code block wrappers**: Task invocations must NOT be wrapped in ``` fences
2. **Imperative directives**: Each Task invocation requires "**EXECUTE NOW**: USE the Task tool..." prefix
3. **Concrete values**: Use actual topic strings and paths, not bash variable placeholders like `${TOPICS[0]}`
4. **Checkpoint verification**: Add explicit "Did you just USE the Task tool?" checkpoints after invocations

**Anti-Patterns** (DO NOT USE):
- ❌ Wrapping Task invocations in code blocks: ` ```Task { }``` `
- ❌ Using bash variable syntax: `${TOPICS[0]}` (looks like documentation)
- ❌ Separate logging code blocks: ` ```bash echo "..."``` ` before Task invocation
- ❌ Pseudo-code notation without imperative directive

**Why This Matters**:
- Agents interpret code-fenced Task blocks as documentation examples
- Bash variable syntax suggests shell interpolation, not actual execution
- Missing imperative directives = agent skips invocation = empty output directories
- Result: Coordinator completes with 0 Task invocations, workflow fails
```

**This section directly contradicts the STEP 3 implementation**, which:
1. Uses bash heredocs (code generation)
2. Uses bash variable syntax (`$TOPICS[0]`, `$REPORT_PATHS[0]`)
3. Generates Task patterns inside bash blocks
4. Relies on agent interpreting bash output as executable instructions

### Section 7: STEP 3.5 Self-Validation Evidence

**Lines 460-508 (STEP 3.5 Self-Validation)**:

The agent file includes explicit self-diagnostic questions:

```markdown
**SELF-CHECK QUESTIONS** (Answer YES or NO for each - be honest):

1. **Did you actually USE the Task tool for each topic?** (Not just read patterns, but executed Task tool invocations)
   - Required Answer: YES
   - If NO: STOP - Return to STEP 3 immediately and execute Task invocations

2. **How many Task tool invocations did you execute?** (Count the actual "Task {" blocks you generated)
   - Required Count: MUST EQUAL TOPICS array length
   - If Mismatch: STOP - Return to STEP 3 and execute missing invocations

**DIAGNOSTIC FOR EMPTY REPORTS FAILURE**:
If you proceed to STEP 4 and it fails with "Reports directory is empty" error, this means you did NOT actually execute Task invocations in STEP 3. The patterns above are templates - you must generate actual Task tool invocations with concrete values, not documentation examples.

**Common Mistake Detection**:
- If your Task blocks still contain "(use TOPICS[0])" text, you failed to execute correctly
- If your Task blocks are inside ``` code fences, they will not execute
- If you "described" what Task invocations should happen, but didn't generate them, workflow will fail
```

**Analysis**: This self-validation section EXISTS BECAUSE the current architecture fails. The questions reveal awareness that:
- Agents read STEP 3 patterns as documentation
- Agents skip Task invocations despite heredoc generation
- Empty reports directory is common symptom (0 invocations executed)
- The design relies on agent "honesty" in self-diagnosis

**Root Cause Confirmation**: If the heredoc-based generation worked, STEP 3.5 self-validation would be unnecessary. The existence of this extensive self-check proves the architectural pattern is fundamentally broken.

### Section 8: STEP 4 Validation Diagnostics

**Lines 572-593 (Empty Directory Detection)**:

```bash
# Early-exit check for empty directory (critical failure indicator)
if [ "$CREATED_REPORTS" -eq 0 ]; then
  echo "CRITICAL ERROR: Reports directory is empty - no reports created" >&2
  echo "Expected: $EXPECTED_REPORTS reports" >&2
  echo "This indicates Task tool invocations did not execute in STEP 3" >&2
  echo "Root cause: Agent interpreted Task patterns as documentation, not executable directives" >&2
  echo "Solution: Return to STEP 3 and execute Task tool invocations" >&2
  exit 1
fi
```

**Critical Admission**: The error message explicitly states:
- "Agent interpreted Task patterns as documentation, not executable directives"
- This is the exact failure mode of the heredoc-based generation approach

**Design Implication**: The agent file KNOWS the current pattern fails and includes error messages to diagnose it. This is defensive programming around an architectural flaw, not a working solution.

## Analysis Summary

### Architectural Root Cause

The research-coordinator.md design uses **bash heredoc text generation** to output Task invocation patterns, expecting the agent to:
1. Read bash output as text
2. Interpret Task patterns as executable instructions
3. Programmatically invoke Task tool based on parsed text

**This violates the Claude Code execution model**:
- Task tool invocations MUST appear in conversation context (markdown directives)
- Bash output is interpreted as information, not instructions
- No dynamic parsing bridge exists between bash stdout and tool invocation

### Correct Architecture (Per Command Authoring Standards)

Task invocations MUST be:
1. **Static in markdown** - Not dynamically generated
2. **Outside bash blocks** - In conversation context
3. **Preceded by imperative directives** - "**EXECUTE NOW**: USE the Task tool..."
4. **Direct tool calls** - Not text representations of tool calls

### Why Current Implementation Persists

Despite violating standards, the current implementation exists because:
1. **Iterative loop requirement** - Need to invoke N research-specialists based on topic count
2. **Variable topic count** - Cannot statically write 3-5 Task blocks
3. **No alternative pattern documented** - Command authoring standards don't show how to handle dynamic agent counts

### Required Solution Pattern

To fix research-coordinator.md, one approach:

**Option 1: Unroll Task Invocations** (static but verbose)
```markdown
**EXECUTE NOW**: USE the Task tool for topic 1 (if exists)
Task { prompt: "Topic from TOPICS[0]" }

**EXECUTE NOW**: USE the Task tool for topic 2 (if exists)
Task { prompt: "Topic from TOPICS[1]" }

**EXECUTE NOW**: USE the Task tool for topic 3 (if exists)
Task { prompt: "Topic from TOPICS[2]" }
```

**Option 2: Bash-Generated Markdown Files + Read Tool**
```bash
# Generate markdown file with Task invocations
cat > /tmp/task_invocations.md <<EOF
**EXECUTE NOW**: USE the Task tool...
Task { ... }
EOF

# Agent reads file and executes directives
# (Requires agent to interpret file contents as instructions)
```

**Option 3: Coordinator Generates Invocation Plan, Primary Agent Executes**
```markdown
# Coordinator role changes:
# - Calculate topics and paths (planning only)
# - Return invocation plan as structured data
# - Primary agent reads plan and executes Task invocations
```

**Critical Constraint**: Any solution must work within Claude Code's execution model where:
- Tool invocations are conversation-level actions
- Bash output is data, not executable instructions
- Dynamic generation requires static invocation points

## Conclusion

The research-coordinator.md STEP 3 implementation uses an architecturally unsound pattern that violates the Claude Code execution model. The agent file itself includes extensive diagnostics (STEP 3.5 self-validation, STEP 4 empty directory errors) that reveal awareness of this failure mode.

The correct pattern requires Task invocations to appear statically in markdown with imperative directives, NOT dynamically generated via bash heredocs. This creates a design challenge for variable-count agent invocations that requires architectural rethinking.
