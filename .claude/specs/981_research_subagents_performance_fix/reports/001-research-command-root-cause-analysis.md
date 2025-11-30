# Research Command Root Cause Analysis

## Metadata
- **Date**: 2025-11-29
- **Agent**: research-specialist
- **Topic**: /research command poor performance and lack of subagent delegation
- **Report Type**: root cause analysis

## Executive Summary

The `/research` command exhibits poor performance because **the primary agent (Claude) performs research work directly instead of delegating to the research-specialist subagent**. The command architecture includes proper Task invocations at Block 1d (lines 450-472), but the primary agent bypasses this delegation and executes research tasks itself, generating output in `/home/benjamin/.config/.claude/output/research-output.md`. This violates the hierarchical agent architecture standards and prevents the workflow from achieving the intended separation of concerns, context efficiency, and specialization benefits.

## Root Cause Analysis

### Problem Statement

The `/research` command output file (`/home/benjamin/.config/.claude/output/research-output.md`) contains evidence that the primary agent conducted research directly:

```
● Read(.claude/output/build-output.md)
● Read(.claude/agents/implementer-coordinator.md)
● Read(.claude/specs/975_hook_buffer_opening_issue/plans/001-hook-buffer-opening-issue-plan.md)
● Read(.claude/commands/build.md)
● Search(pattern: ".claude/agents/test-executor*.md", path: "~/.config")
● Read(.claude/agents/test-executor.md)
● Bash(mkdir -p /home/benjamin/.config/.claude/specs/978_research_buffer_hook_integration/reports)
● Write(.claude/specs/978_research_buffer_hook_integration/reports/001-build-testing-delegation-analysis.md)
```

This demonstrates that instead of invoking the research-specialist agent via the Task tool (as specified in Block 1d), the primary agent performed all research work itself.

### Architecture Comparison

#### Expected Architecture (from /plan and /build commands)

The `/plan` command demonstrates proper hierarchical delegation:

**File**: `/home/benjamin/.config/.claude/commands/plan.md`

- **Block 1a** (lines 1-260): Orchestrator setup and initialization
- **Block 1b** (lines 262-290): Task invocation for topic-naming-agent
- **Block 1c** (lines 392-500): Topic path initialization
- **Research Phase**: Would invoke research-specialist (similar pattern to /research Block 1d)
- **Planning Phase**: Task invocation for plan-architect agent

The `/build` command shows proper coordinator delegation:

**File**: `/home/benjamin/.config/.claude/commands/build.md`

- **Block 1** (lines 24-492): Orchestrator setup
- **Implementation Phase** (line 498): Task invocation for implementer-coordinator
- Coordinator then delegates to implementation-executor workers in parallel waves

**Key Pattern**: Orchestrator → Coordinator → Specialists (3-tier hierarchy)

#### Actual /research Implementation

**File**: `/home/benjamin/.config/.claude/commands/research.md`

- **Block 1a** (lines 23-232): Setup and state initialization ✓
- **Block 1b** (lines 234-261): Task invocation for topic-naming-agent ✓
- **Block 1c** (lines 265-442): Topic path initialization ✓
- **Block 1d** (lines 444-472): **Task invocation for research-specialist** ✓ (PRESENT BUT NOT EXECUTED)
- **Block 2** (lines 474-701): Verification and completion

**Critical Finding**: The Task invocation exists at Block 1d (lines 450-472) but is not being executed by the primary agent.

### Root Cause: Missing Hard Barrier Pattern

Comparing `/research.md` to `/build.md` reveals the critical difference:

#### /build Command (Proper Implementation)

**File**: `/home/benjamin/.config/.claude/commands/build.md` (lines 494-500)

```markdown
**EXECUTE NOW**: Invoke implementer-coordinator subagent for implementation phase, then verify completion inline.

**Iteration Context**: The coordinator will be passed iteration parameters. After it returns, inline verification will check work_remaining to determine if another iteration is needed.

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallelization (iteration ${ITERATION}/${MAX_ITERATIONS})"
  ...
}
```

**After Task block**: The command proceeds directly to verification Block 2 which ONLY checks artifacts created by the subagent.

#### /research Command (Current Implementation)

**File**: `/home/benjamin/.config/.claude/commands/research.md` (lines 444-472)

```markdown
## Block 1d: Research Initiation

**CRITICAL BARRIER - Research Delegation**

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent. This invocation is MANDATORY. The orchestrator MUST NOT perform research work directly. Block 2 verification will FAIL if research artifacts are not created by the specialist.

Task {
  subagent_type: "general-purpose"
  description: "Research ${WORKFLOW_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md
    ...
  "
}
```

**Analysis**:

1. **The language is present** ("CRITICAL BARRIER", "MANDATORY", "MUST NOT perform research work directly")
2. **The Task invocation is present** (lines 450-472)
3. **BUT**: The primary agent is NOT interpreting this as a hard barrier

The primary agent sees the Task block as guidance rather than an execution requirement. After reading Block 1d, instead of **executing** the Task invocation, the agent **interprets** it as describing what needs to happen and then proceeds to do the work itself.

### Comparison with Working Commands

#### /plan Command Pattern (Lines 262-290)

```markdown
## Block 1b: Topic Name Generation

**EXECUTE NOW**: Invoke the topic-naming-agent to generate a semantic directory name.

Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  prompt: "..."
}

**EXECUTE NOW**: Validate agent output file was created.

```bash
# Validation code that checks for agent output
```
```

**Why this works**: The command separates invocation (Block 1b) from validation (Block 1c with bash). The bash block in 1c REQUIRES the agent output to exist, creating a dependency chain.

#### /build Command Pattern (Lines 498-500 + verification)

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan..."
}

## Inline Verification Block

After coordinator returns, verify:
- Work completion status
- Artifact creation
- Context exhaustion
```

**Why this works**: The verification is positioned AFTER the Task block expects completion, with no intervening bash blocks that could trigger early execution.

#### /research Command Pattern (BROKEN)

```markdown
## Block 1d: Research Initiation

Task {
  ...
}

## Block 2: Verification and Completion

**EXECUTE NOW**: Verify research artifacts and complete workflow:

```bash
# Verification code
```
```

**Why this fails**: There's no intermediate validation block between Task invocation and final verification. The primary agent can bypass the Task invocation and proceed directly to the bash block in Block 2.

### Specific Architectural Defects

#### Defect 1: No Output File Path Pre-Calculation

**File**: `/home/benjamin/.config/.claude/commands/research.md` (Block 1d, lines 450-472)

The research-specialist Task prompt includes:

```
- Output Directory: ${RESEARCH_DIR}
```

But **NOT**:
```
- Report Path: ${RESEARCH_DIR}/001-${TOPIC_NAME}-analysis.md
```

**Consequence**: The primary agent doesn't have a specific file path to expect, so it can't verify the subagent created the expected artifact. Without this hard expectation, the agent can substitute its own work.

**Comparison**: The research-specialist behavioral file (lines 24-44) EXPECTS a pre-calculated report path:

```markdown
### STEP 1 (REQUIRED BEFORE STEP 2) - Receive and Verify Report Path

**MANDATORY INPUT VERIFICATION**

The invoking command MUST provide you with an absolute report path. Verify you have received it:

```bash
REPORT_PATH="[PATH PROVIDED IN YOUR PROMPT]"

if [[ ! "$REPORT_PATH" =~ ^/ ]]; then
  echo "CRITICAL ERROR: Path is not absolute: $REPORT_PATH"
  exit 1
fi
```
```

**Root Cause**: `/research` command does NOT provide `REPORT_PATH` to the agent, violating the research-specialist's required input protocol.

#### Defect 2: Missing Hard Barrier Verification

**File**: `/home/benjamin/.config/.claude/commands/research.md` (Block 2, lines 474-701)

Block 2 verification checks:
- Directory exists (line 595)
- Files exist (line 609)
- File size (line 623)

But **NOT**:
- Specific file path from STEP 1 pre-calculation
- Agent completion signal (`REPORT_CREATED: [path]`)
- Agent output validation

**Comparison**: `/build` command has inline verification after Task invocation that checks for agent-specific outputs and continuation context.

#### Defect 3: Weak Delegation Language

**File**: `/home/benjamin/.config/.claude/commands/research.md` (Block 1d, lines 444-448)

```markdown
**CRITICAL BARRIER - Research Delegation**

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent. This invocation is MANDATORY. The orchestrator MUST NOT perform research work directly. Block 2 verification will FAIL if research artifacts are not created by the specialist.
```

**Analysis**: While strongly worded, this is **descriptive** language about what should happen, not **procedural** instructions that create an execution dependency.

**Comparison**: `/build` command uses:

```markdown
**EXECUTE NOW**: Invoke implementer-coordinator subagent for implementation phase, then verify completion inline.

**Iteration Context**: The coordinator will be passed iteration parameters. After it returns, inline verification will check work_remaining to determine if another iteration is needed.
```

The difference: `/build` explicitly states "After it returns" - creating a temporal dependency. `/research` says "Block 2 verification will FAIL" - but Block 2 is a separate execution block that the agent can reach without executing the Task.

### Evidence from Hierarchical Agent Standards

**File**: `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md` (lines 95-110)

```markdown
## When to Use Hierarchical Architecture

### Use When

- Workflow has 4+ parallel agents
- Context reduction is critical
- Workers produce large outputs (>1,000 tokens each)
- Need clear responsibility boundaries
- Workflow has distinct phases (research, plan, implement)

### Don't Use When

- Single agent workflow
- Simple sequential operations
- Minimal context management needs
- No parallel execution benefits
```

**Analysis**: The `/research` command qualifies for hierarchical architecture ("distinct phases", "clear responsibility boundaries"), but the current implementation doesn't enforce the hierarchy.

The standards document (lines 37-48) shows the behavioral injection pattern:

```yaml
Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    Context:
    - Topic: ${RESEARCH_TOPIC}
    - Output Path: ${REPORT_PATH}
}
```

**Note**: `Output Path: ${REPORT_PATH}` - This is a **singular, pre-calculated path**, not just a directory.

### Implementer-Coordinator Analysis (Successful Pattern)

**File**: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` (lines 1-50)

The implementer-coordinator demonstrates the correct pattern:

1. **Clear Role Definition** (lines 11-22): Lists specific responsibilities
2. **Input Format Specification** (lines 27-52): Exact input structure expected
3. **Step-by-Step Workflow** (lines 54+): Procedural steps with verification
4. **Output Format Specification**: Structured return signals

**Key Success Factor**: The coordinator receives **pre-calculated paths** from the orchestrator:

```yaml
artifact_paths:
  reports: /path/to/specs/027_auth/reports/
  plans: /path/to/specs/027_auth/plans/
  summaries: /path/to/specs/027_auth/summaries/
  debug: /path/to/specs/027_auth/debug/
  outputs: /path/to/specs/027_auth/outputs/
  checkpoints: /home/user/.claude/data/checkpoints/
```

This creates a **contract** that both orchestrator and coordinator must fulfill.

### Plan-Architect Analysis (Successful Pattern)

**File**: `/home/benjamin/.config/.claude/agents/plan-architect.md` (lines 99-153)

The plan-architect receives:

```markdown
**Plan Creation Pattern**:
1. **Receive PLAN_PATH**: The calling command provides absolute path in your prompt
   - Format: `specs/{NNN_workflow}/plans/{NNN}_implementation.md`
   - Example: `specs/027_authentication/plans/027_implementation.md`
   - This path is PRE-CALCULATED using `create_topic_artifact()` utility

2. **Create Plan File**: Use Write tool to create plan at EXACT path provided
   - DO NOT calculate your own path
   - DO NOT modify the provided path
   - USE Write tool with absolute path from prompt
```

**Key Success Factor**: Absolute path provided upfront, creating verifiable contract.

## Recommendations

### Recommendation 1: Add Report Path Pre-Calculation (CRITICAL)

**Before** Block 1d Task invocation, add a bash block that calculates the exact report path:

```bash
# === CALCULATE REPORT PATH ===
REPORT_NUMBER="001"
REPORT_SLUG=$(echo "$WORKFLOW_DESCRIPTION" | head -c 40 | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
REPORT_PATH="${RESEARCH_DIR}/${REPORT_NUMBER}-${REPORT_SLUG}.md"

# Persist for Block 2 verification
append_workflow_state "REPORT_PATH" "$REPORT_PATH"

echo "Pre-calculated report path: $REPORT_PATH"
```

**Rationale**: Creates a specific artifact expectation that can be verified in Block 2.

### Recommendation 2: Update Task Prompt with Absolute Path

Modify Block 1d Task invocation (line 463) from:

```
- Output Directory: ${RESEARCH_DIR}
```

To:

```
- Report Path: ${REPORT_PATH}
- Output Directory: ${RESEARCH_DIR}
```

**Rationale**: Matches research-specialist STEP 1 requirement for absolute report path.

### Recommendation 3: Add Agent Output Validation Block

Insert a new **Block 1e** between current Block 1d (Task invocation) and Block 2 (verification):

```markdown
## Block 1e: Agent Output Validation

**EXECUTE NOW**: Validate research-specialist created the expected report file.

```bash
# Restore state
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"

WORKFLOW_ID=$(cat "${CLAUDE_PROJECT_DIR}/.claude/tmp/research_state_id.txt")
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
source "$STATE_FILE"

# Validate agent output
if [ ! -f "$REPORT_PATH" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "agent_error" "research-specialist failed to create report file" \
    "bash_block_1e" "$(jq -n --arg path "$REPORT_PATH" '{expected_path: $path}')"

  echo "ERROR: research-specialist did not create report: $REPORT_PATH" >&2
  exit 1
fi

# Validate report contains completion signal
grep -q "## Findings" "$REPORT_PATH" || {
  echo "ERROR: Report missing required sections" >&2
  exit 1
}

echo "✓ Agent output validated: $REPORT_PATH"
```
```

**Rationale**: Creates a hard barrier that prevents proceeding without agent completion.

### Recommendation 4: Strengthen Block 1d Language

Update Block 1d header from:

```markdown
**CRITICAL BARRIER - Research Delegation**

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent. This invocation is MANDATORY. The orchestrator MUST NOT perform research work directly. Block 2 verification will FAIL if research artifacts are not created by the specialist.
```

To:

```markdown
**HARD BARRIER - Research Specialist Invocation**

**YOU MUST execute the Task tool invocation below. After the agent returns, Block 1e will verify the report file was created at the expected path. You cannot proceed without completing this Task invocation.**

**AGENT CONTRACT**: The research-specialist will create a report file at ${REPORT_PATH}. You will verify this file exists in Block 1e before proceeding to workflow completion.
```

**Rationale**: Establishes temporal dependency ("After the agent returns") and explicit verification step.

### Recommendation 5: Add research-sub-supervisor for Complexity ≥3

For research complexity 3-4, the command should invoke research-sub-supervisor instead of research-specialist directly:

```bash
if [ "$RESEARCH_COMPLEXITY" -ge 3 ]; then
  # High complexity: Use supervisor pattern with parallel specialists
  DELEGATION_TARGET="research-sub-supervisor"

  # Calculate research topics breakdown
  RESEARCH_TOPICS="codebase_analysis,best_practices,integration_patterns,test_strategy"
else
  # Low complexity: Direct specialist invocation
  DELEGATION_TARGET="research-specialist"
fi
```

**Rationale**: Aligns with hierarchical agent standards (4+ parallel agents for scale).

### Recommendation 6: Implement Hard Barrier Pattern (from docs)

**File**: `/home/benjamin/.config/.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md`

The `.claude/docs/` should contain documentation for the hard barrier pattern:

```markdown
# Hard Barrier Pattern: Enforcing Mandatory Subagent Delegation

## Problem

Orchestrator commands may bypass subagent delegation and perform work directly, violating hierarchical agent architecture.

## Solution

Implement a three-part hard barrier:

1. **Pre-Calculation Block**: Calculate exact output paths before invocation
2. **Task Invocation Block**: Invoke subagent with pre-calculated paths
3. **Validation Block**: Verify subagent output exists before proceeding

## Implementation

### Step 1: Pre-Calculate Output Path

```bash
EXPECTED_OUTPUT_PATH="${OUTPUT_DIR}/001-expected-artifact.md"
append_workflow_state "EXPECTED_OUTPUT_PATH" "$EXPECTED_OUTPUT_PATH"
```

### Step 2: Pass Path to Subagent

```markdown
Task {
  prompt: |
    Output Path: ${EXPECTED_OUTPUT_PATH}
}
```

### Step 3: Validate Output Exists

```bash
if [ ! -f "$EXPECTED_OUTPUT_PATH" ]; then
  echo "ERROR: Subagent failed to create expected artifact" >&2
  exit 1
fi
```

## Examples

- /build command: implementer-coordinator delegation
- /plan command: plan-architect delegation (PLAN_PATH pre-calculated)
```

**Rationale**: Provides reusable pattern for all orchestrator commands.

## References

- `/home/benjamin/.config/.claude/commands/research.md` - Current implementation (lines 444-472, Block 1d)
- `/home/benjamin/.config/.claude/commands/build.md` - Reference implementation (lines 494-500)
- `/home/benjamin/.config/.claude/commands/plan.md` - Reference implementation (lines 262-290, Block 1b)
- `/home/benjamin/.config/.claude/agents/research-specialist.md` - Agent behavioral file (lines 24-44, STEP 1)
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` - Coordinator pattern (lines 27-52)
- `/home/benjamin/.config/.claude/agents/plan-architect.md` - Path contract pattern (lines 99-153)
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md` - Architecture standards (lines 95-110)
- `/home/benjamin/.config/.claude/output/research-output.md` - Evidence of primary agent direct execution

## Implementation Priority

1. **CRITICAL** (Must Fix): Recommendation 1 (Report path pre-calculation)
2. **CRITICAL** (Must Fix): Recommendation 2 (Update Task prompt with absolute path)
3. **CRITICAL** (Must Fix): Recommendation 3 (Add agent output validation block)
4. **HIGH** (Should Fix): Recommendation 4 (Strengthen delegation language)
5. **MEDIUM** (Nice to Have): Recommendation 5 (Add supervisor for high complexity)
6. **LOW** (Documentation): Recommendation 6 (Document hard barrier pattern)

## Success Criteria

After implementing recommendations 1-3:

1. Primary agent CANNOT proceed past Block 1e without research-specialist completion
2. Report file exists at pre-calculated path: `${RESEARCH_DIR}/001-${REPORT_SLUG}.md`
3. Agent completion signal verified: `REPORT_CREATED: ${REPORT_PATH}`
4. Verification block enforces hard barrier (exit 1 if report missing)
5. Workflow output shows Task invocation → Agent execution → Validation → Completion

## Testing Plan

1. **Test Case 1**: Run `/research "test topic"` with recommendations applied
   - Expected: research-specialist invoked, creates report at `${RESEARCH_DIR}/001-test-topic.md`
   - Actual: Verify via grep "REPORT_CREATED" in output

2. **Test Case 2**: Simulate agent failure (mock research-specialist to not create file)
   - Expected: Block 1e exits with error, workflow halts
   - Actual: Verify error log contains "agent_error" entry

3. **Test Case 3**: High complexity research (--complexity 4)
   - Expected: research-sub-supervisor invoked (if Recommendation 5 implemented)
   - Actual: Verify parallel specialist invocations in output

## Estimated Impact

- **Context Reduction**: 85-95% (specialist summarizes findings vs full research in primary context)
- **Specialization**: research-specialist uses domain-specific tools and patterns
- **Maintainability**: Single source of truth in `.claude/agents/research-specialist.md`
- **Consistency**: Aligns `/research` with `/plan` and `/build` delegation patterns
- **Performance**: Enables future hierarchical supervision for complex research workflows
