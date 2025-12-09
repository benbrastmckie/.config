# Research Report: Research-Coordinator Agent Execution Failure

## Executive Summary

The research-coordinator agent completed execution (47 seconds, 7 tool uses, 59.6k tokens) without invoking any research-specialist sub-agents, resulting in an empty reports directory. Root cause: The agent's behavioral file uses Task {} pseudo-code syntax patterns that violate Task Tool Invocation Standards, causing the agent to interpret invocation directives as documentation rather than executable instructions.

## Problem Statement

When /create-plan invoked research-coordinator for multi-topic research coordination (complexity 3, 4 topics), the agent:

1. Completed STEP 1-2 (topic detection, path calculation) - 7 tool uses
2. Failed to execute STEP 3 (parallel research delegation) - 0 Task invocations
3. Never created research reports - empty directory symptom
4. Triggered "Error retrieving agent output" when orchestrator attempted resume
5. Required orchestrator fallback to manual research-specialist invocations

Evidence from /home/benjamin/.config/.claude/output/create-plan-output.md:
- Line 66-67: Task(Coordinate multi-topic research) completed
- Line 73-74: Agent Output 90639fbf -> Error retrieving agent output
- Line 84-87: ls reports/ shows empty directory (only . and ..)
- Line 92-104: Orchestrator manually invoked 4 research-specialist agents as recovery

## Root Cause Analysis

### Primary Issue: Prohibited Task Invocation Syntax

The research-coordinator.md behavioral file (lines 198-370) uses Task {} pseudo-code patterns that violate Task Tool Invocation Standards documented in /home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md.

**Violation Example** (research-coordinator.md lines 239-273):

```markdown
### STEP 3 (EXECUTE MANDATORY): Invoke Parallel Research Workers

**EXECUTE NOW - DO NOT SKIP**: USE the Task tool to invoke research-specialist for topic at index 0.

**Log this invocation**: Before executing Task, output:
```
Invoking research-specialist [0/${#TOPICS[@]}]: ${TOPICS[0]}
Report path: ${REPORT_PATHS[0]}
Timestamp: $(date +%Y-%m-%d_%H:%M:%S)
```

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPICS[0]}"
  prompt: "..."
}
```

**Problems with This Pattern**:

1. **Code block wrapper**: Task invocation wrapped in triple-backtick code fence (markdown code block)
2. **Pseudo-syntax format**: Task {} YAML-like syntax not actual Claude Code Task tool syntax
3. **Variable interpolation**: Bash ${VARIABLE} syntax suggests shell interpolation, but agent cannot execute bash
4. **Logging instruction separation**: Logging block wrapped in code fence, separated from Task invocation
5. **Instructional not executable**: Pattern reads like "this is how you would invoke" not "invoke now"

### Standard-Compliant Pattern

Per command-authoring.md lines 98-148, correct Task invocation requires:

```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-specialist for topic 1.

Task {
  subagent_type: "general-purpose"
  description: "Research Mathlib theorems for group homomorphism"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/user/.config/.claude/agents/research-specialist.md

    **CRITICAL - Hard Barrier Pattern**:
    REPORT_PATH=/home/user/.config/.claude/specs/028_lean/reports/001-mathlib-theorems.md

    **Research Topic**: Mathlib theorems for group homomorphism

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: /home/user/.config/.claude/specs/028_lean/reports/001-mathlib-theorems.md
  "
}
```

**Key Differences**:

| Aspect | Current (Broken) | Standard (Working) |
|--------|------------------|-------------------|
| Code block wrapper | YES (wrapped in ``` fences) | NO (bare Task invocation) |
| Variable syntax | Bash ${VAR} interpolation | Actual values inline |
| Logging | Separate code block | Inline or omitted |
| Instructions | Instructional language | Direct imperative |
| Context | File-level agent execution | Command-level task delegation |

### Why Agent Interpreted as Documentation

The research-coordinator.md file structure creates ambiguity:

1. **File Purpose Statement** (line 8-10): "This file contains EXECUTABLE DIRECTIVES for the research-coordinator agent"
2. **Execution Zone Marker** (line 217): "<!-- EXECUTION ZONE: Task Invocations Below -->"
3. **Step Directive** (line 219): "### STEP 3 (EXECUTE MANDATORY): Invoke Parallel Research Workers"
4. **Imperative Instruction** (line 223): "**EXECUTE NOW**: USE the Task tool..."
5. **Code Block** (line 249-273): Task invocation wrapped in markdown code fence

The agent likely:
- Read lines 1-248 as behavioral guidelines (CORRECT interpretation)
- Read lines 249-273 as example syntax pattern (INCORRECT interpretation due to code fence)
- Executed STEP 1-2 bash blocks (CORRECT - actual bash execution)
- Skipped STEP 3 Task invocations (INCORRECT - interpreted as documentation)
- Proceeded to STEP 4 validation (CORRECT - followed workflow sequence)

### Supporting Evidence

1. **Tool Usage Count**: Agent used 7 tools (Read operations for topic detection, path calculation, directory verification) but 0 Task invocations
2. **Empty Directory Symptom**: Reports directory contained no files (lines 84-87 of create-plan-output.md)
3. **Orchestrator Recovery**: Manual invocation of 4 research-specialist agents succeeded (lines 92-104), proving the research-specialist behavioral file is functional
4. **Agent Output Error**: "Error retrieving agent output" (line 74) suggests agent completed abnormally or did not produce expected output format

### Debug Output Analysis Confirmation

From /home/benjamin/.config/.claude/output/debug-output.md lines 83-175:

The /debug command root cause analysis identified:

1. **Primary Issue** (lines 85-98): "Research-Coordinator Agent Did Not Execute Research-Specialist Invocations"
2. **Why Agent Failed** (lines 100-110): "The agent uses pseudo-code Task syntax (Task { ... }) which is not actual tool invocation"
3. **Recommended Fix** (lines 135-142): "The behavioral file's Task patterns need to be clearer about actually invoking the Task tool vs describing the pattern"

This confirms the root cause is Task invocation pattern non-compliance with command-authoring standards.

## Impact Assessment

### Severity: Medium-High

- **Workflow Failure**: Research-coordinator failed to execute its core responsibility (parallel research delegation)
- **Time Wasted**: 47 seconds of agent execution with no productive output
- **Orchestrator Complexity**: Required fallback logic and manual agent invocation
- **False Completion**: Agent reported success despite producing no artifacts

### Successful Recovery

- **Fallback Mechanism**: Orchestrator detected empty directory and manually invoked research-specialist agents
- **Partial Success Mode**: All 4 research reports successfully created via direct invocation
- **Workflow Completion**: /create-plan ultimately succeeded via alternative execution path

### Time Metrics

- Research-coordinator execution: 47 seconds (wasted)
- Manual research-specialist invocations: 4 agents in parallel (successful)
- Total workflow time: Increased by 47 seconds vs optimal path

## Secondary Issue: Agent Output Retrieval Error

From create-plan-output.md lines 73-74:

```
Agent Output 90639fbf
  Error retrieving agent output
```

This error occurred when orchestrator attempted to retrieve final output from research-coordinator agent ID 90639fbf.

**Analysis**:

1. **Symptom**: AgentOutputTool failed to find or parse agent output
2. **Timing**: After agent reported completion (line 67: "Done")
3. **Context**: Agent completed without producing expected RESEARCH_COMPLETE signal
4. **Root Cause**: Agent did not generate expected output format because it skipped STEP 3-6 execution

**Why This Happened**:

The agent likely:
- Completed STEP 1-2 successfully
- Skipped STEP 3 Task invocations (interpreted as documentation)
- Reached end of file without generating STEP 6 return signal
- Terminated without returning expected RESEARCH_COMPLETE: N format
- Left AgentOutputTool unable to parse incomplete/malformed output

This is a **symptom** of the primary issue (Task invocation failure), not an independent error.

## Recommended Fixes

### Fix 1: Update research-coordinator.md Task Invocation Patterns (REQUIRED)

**Current Pattern** (BROKEN):

```markdown
**EXECUTE NOW - DO NOT SKIP**: USE the Task tool to invoke research-specialist for topic at index 0.

**Log this invocation**: Before executing Task, output:
```
Invoking research-specialist [0/${#TOPICS[@]}]: ${TOPICS[0]}
```

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPICS[0]}"
  prompt: "..."
}
```

**Compliant Pattern** (WORKING):

```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-specialist for topic 1.

Invoking research-specialist [1/4]: Mathlib Theorems for Group Homomorphism
Report path: /home/user/.config/.claude/specs/028_lean/reports/001-mathlib-theorems.md
Timestamp: 2025-12-09_01:23:45

Task {
  subagent_type: "general-purpose"
  description: "Research Mathlib theorems for group homomorphism"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/user/.config/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent with the tools and constraints
    defined in that file.

    **CRITICAL - Hard Barrier Pattern**:
    REPORT_PATH=/home/user/.config/.claude/specs/028_lean/reports/001-mathlib-theorems.md

    **Research Topic**: Mathlib theorems for group homomorphism

    **Context**:
    Feature: Formalize group homomorphism theorems with automated tactics
    Project: /home/user/Documents/Projects/LeanProject

    Follow all steps in research-specialist.md:
    1. STEP 1: Verify absolute report path received
    2. STEP 2: Create report file FIRST (before research)
    3. STEP 3: Conduct research and update report incrementally
    4. STEP 4: Verify file exists and return: REPORT_CREATED: /home/user/.config/.claude/specs/028_lean/reports/001-mathlib-theorems.md
  "
}
```

**Changes Required**:

1. Remove code block wrapper (no triple backticks around Task invocation)
2. Replace ${VARIABLE} bash syntax with actual values
3. Inline logging output before Task invocation (no code fence)
4. Provide concrete example values (not abstract placeholders)
5. Remove "Continue this pattern for indices 3, 4, etc." instruction (provide explicit Task invocations for each topic count)

### Fix 2: Add STEP 3.5 Self-Validation Checkpoint (RECOMMENDED)

Insert explicit self-validation step after STEP 3 to force agent verification:

```markdown
### STEP 3.5 (MANDATORY SELF-VALIDATION): Verify Task Invocations

**Objective**: Self-validate that Task tool was actually used before proceeding.

**MANDATORY VERIFICATION**: You MUST answer these self-diagnostic questions before continuing to STEP 4. If you cannot answer YES to all questions, you MUST return to STEP 3 and re-execute.

**SELF-CHECK QUESTIONS** (Answer YES or NO for each):

1. Did you actually USE the Task tool for each topic? (Not just read examples, but executed Task invocations)
   - **Required Answer**: YES
   - **If NO**: Return to STEP 3 immediately

2. How many Task tool invocations did you execute? (Count must equal ${#TOPICS[@]})
   - **Required Count**: ${#TOPICS[@]}
   - **If Mismatch**: Return to STEP 3 and execute missing invocations

3. Did each Task invocation include the REPORT_PATH variable from REPORT_PATHS array with correct index?
   - **Required Answer**: YES
   - **If NO**: Return to STEP 3 and correct Task invocations

**FAIL-FAST INSTRUCTION**: If Task count != ${#TOPICS[@]}, STOP immediately and re-execute STEP 3. DO NOT continue to STEP 4 if Task invocations are incomplete.
```

This forces the agent to explicitly verify its own execution before proceeding.

### Fix 3: Add Empty Directory Validation in STEP 4 (IMPLEMENTED)

The current research-coordinator.md already has empty directory detection (lines 418-431), but it should be enhanced with diagnostic messaging:

**Current** (lines 418-431):
```bash
CREATED_REPORTS=$(ls "$REPORT_DIR"/[0-9][0-9][0-9]-*.md 2>/dev/null | wc -l)

if [ "$CREATED_REPORTS" -eq 0 ]; then
  echo "CRITICAL ERROR: Reports directory is empty - no reports created" >&2
  echo "Expected: $EXPECTED_REPORTS reports" >&2
  echo "This indicates Task tool invocations did not execute in STEP 3" >&2
  echo "Root cause: Agent interpreted Task patterns as documentation, not executable directives" >&2
  echo "Solution: Return to STEP 3 and execute Task tool invocations" >&2
  exit 1
fi
```

This diagnostic is already present and would have caught the failure if STEP 4 had been executed. The issue is that agent never reached STEP 4 validation because it interpreted the workflow as complete after reading STEP 3.

### Fix 4: Add Invocation Trace File for Debugging (RECOMMENDED)

Current research-coordinator.md mentions invocation trace (lines 225-229) but doesn't provide implementation. Add actual bash implementation:

```bash
# Create invocation trace file
TRACE_FILE="${REPORT_DIR}/.invocation-trace.log"
echo "[$(date +%Y-%m-%d_%H:%M:%S)] STEP 3 Started: ${#TOPICS[@]} topics" >> "$TRACE_FILE"
```

Then log each Task invocation:
```bash
echo "[$(date +%Y-%m-%d_%H:%M:%S)] Topic[0]: ${TOPICS[0]} | Path: ${REPORT_PATHS[0]} | Status: INVOKED" >> "$TRACE_FILE"
```

This file would be preserved on failure, providing post-mortem debugging data.

## Verification Plan

### Test Case 1: Single-Topic Research (Minimal)

**Input**:
```yaml
research_request: "OAuth2 authentication best practices"
research_complexity: 1
report_dir: /home/user/.config/.claude/specs/test/reports/
topic_path: /home/user/.config/.claude/specs/test
```

**Expected Behavior**:
1. Agent completes STEP 1-2 (1 topic detected, 1 path calculated)
2. Agent executes STEP 3 (1 Task invocation)
3. STEP 3.5 self-validation passes (1 Task invocation confirmed)
4. Agent completes STEP 4 validation (1 report exists)
5. Agent returns RESEARCH_COMPLETE: 1 with metadata

**Success Criteria**:
- Reports directory contains 1 file: 001-oauth2-authentication.md
- File size > 1000 bytes
- RESEARCH_COMPLETE signal returned

### Test Case 2: Multi-Topic Research (Typical)

**Input**:
```yaml
research_request: "Mathlib theorems, proof automation, project structure for Lean 4"
research_complexity: 3
report_dir: /home/user/.config/.claude/specs/lean/reports/
topic_path: /home/user/.config/.claude/specs/lean
```

**Expected Behavior**:
1. Agent completes STEP 1-2 (3-4 topics detected, paths calculated)
2. Agent executes STEP 3 (3-4 Task invocations in parallel)
3. STEP 3.5 self-validation passes (3-4 Task invocations confirmed)
4. Agent completes STEP 4 validation (3-4 reports exist)
5. Agent returns RESEARCH_COMPLETE: N with aggregated metadata

**Success Criteria**:
- Reports directory contains 3-4 files
- All files > 1000 bytes
- RESEARCH_COMPLETE signal with JSON metadata array
- No "Error retrieving agent output"

### Test Case 3: Pre-Decomposed Topics (Mode 2)

**Input**:
```yaml
research_request: "OAuth2, sessions, passwords"
research_complexity: 3
report_dir: /home/user/.config/.claude/specs/auth/reports/
topic_path: /home/user/.config/.claude/specs/auth
topics:
  - "OAuth2 authentication implementation"
  - "Session management and token storage"
  - "Password security best practices"
report_paths:
  - /home/user/.config/.claude/specs/auth/reports/001-oauth2.md
  - /home/user/.config/.claude/specs/auth/reports/002-sessions.md
  - /home/user/.config/.claude/specs/auth/reports/003-passwords.md
```

**Expected Behavior**:
1. Agent skips STEP 1-2 decomposition (uses provided topics/paths)
2. Agent executes STEP 3 (3 Task invocations with pre-calculated paths)
3. STEP 3.5 self-validation passes (3 Task invocations confirmed)
4. Agent completes STEP 4 validation (3 reports exist at exact paths)
5. Agent returns RESEARCH_COMPLETE: 3 with metadata

**Success Criteria**:
- Reports created at EXACT paths provided (not auto-numbered)
- All 3 files exist and valid
- RESEARCH_COMPLETE signal with metadata

## Standards Compliance Analysis

### Violated Standards

1. **Task Tool Invocation Pattern** (command-authoring.md lines 98-148)
   - Violation: Code block wrapper around Task invocations
   - Standard: "NO code block wrapper - Remove ``` fences"
   - Impact: Agent interprets as documentation, skips execution

2. **Imperative Directive Requirements** (command-authoring.md lines 23-95)
   - Violation: Instruction + code block separation creates ambiguity
   - Standard: "Every bash code block MUST be preceded by explicit execution directive"
   - Impact: Directive applies to logging block, not Task invocation

3. **Variable Interpolation** (implied by Task tool design)
   - Violation: Bash ${VARIABLE} syntax in agent behavioral file
   - Standard: Agents receive prompt as string, cannot execute bash interpolation
   - Impact: Variables not replaced with actual values

### Compliant Alternatives

**For Bash Execution** (CORRECT - already working in STEP 1-2):
```markdown
**EXECUTE NOW**: Verify reports directory and calculate paths:

```bash
# Bash code here executes correctly
REPORT_DIR="/home/user/.config/.claude/specs/test/reports/"
mkdir -p "$REPORT_DIR"
```
```

**For Task Invocation** (REQUIRED - not currently compliant):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-specialist.

Task {
  subagent_type: "general-purpose"
  description: "Research OAuth2 authentication best practices"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/user/.config/.claude/agents/research-specialist.md

    **CRITICAL - Hard Barrier Pattern**:
    REPORT_PATH=/home/user/.config/.claude/specs/test/reports/001-oauth2.md

    **Research Topic**: OAuth2 authentication best practices

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: /home/user/.config/.claude/specs/test/reports/001-oauth2.md
  "
}
```

## Next Steps

1. **Update research-coordinator.md** (REQUIRED):
   - Replace STEP 3 Task invocation patterns with standard-compliant syntax
   - Remove code block wrappers
   - Provide concrete examples (not variable placeholders)
   - Add explicit Task invocations for each topic index (0-4)

2. **Add STEP 3.5 Self-Validation** (RECOMMENDED):
   - Force agent to verify Task invocation count
   - Explicit checkpoint before proceeding to STEP 4
   - Self-diagnostic questions with required answers

3. **Implement Invocation Trace** (RECOMMENDED):
   - Add bash implementation for trace file creation
   - Log each Task invocation timestamp
   - Preserve trace file on failure for debugging

4. **Test Updated Agent** (REQUIRED):
   - Run Test Case 1 (single topic)
   - Run Test Case 2 (multi-topic)
   - Run Test Case 3 (pre-decomposed)
   - Verify empty directory validation triggers correctly
   - Confirm RESEARCH_COMPLETE signal format

5. **Update Documentation** (RECOMMENDED):
   - Add research-coordinator example to command-authoring.md
   - Document agent behavioral file Task invocation patterns
   - Cross-reference hierarchical-agents-examples.md Example 7

## Conclusion

The research-coordinator agent execution failure was caused by non-compliant Task invocation patterns that violated Task Tool Invocation Standards (command-authoring.md). The agent interpreted Task {} pseudo-code as documentation due to code block wrappers and bash variable syntax, resulting in zero Task invocations and an empty reports directory.

The fix requires updating research-coordinator.md STEP 3 to use standard-compliant Task invocation syntax: remove code fences, provide concrete examples, and inline actual values instead of bash variables. Adding STEP 3.5 self-validation checkpoint will prevent future occurrences by forcing agent verification before proceeding.

The /create-plan workflow successfully recovered via orchestrator fallback, but fixing the root cause will eliminate the 47-second time penalty and agent output retrieval error.
