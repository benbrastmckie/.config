# Coordinate Implementation Analysis - /implement Invocation

## Metadata
- **Date**: 2025-11-11
- **Agent**: research-specialist
- **Topic**: Analysis of /coordinate command /implement invocation patterns
- **Report Type**: codebase analysis

## Executive Summary

The analysis of `/home/benjamin/.config/.claude/specs/coordinage_implement.md` reveals that this file is **NOT the /coordinate command implementation**, but rather a **transcript/execution log** of a /coordinate command being run. The file shows /coordinate detecting scope incorrectly, then falling back to directly invoking /implement as a slash command. The actual /coordinate command implementation is in `/home/benjamin/.config/.claude/commands/coordinate.md` and uses **Task tool with implementer-coordinator agent**, not SlashCommand for /implement invocation.

## Findings

### 1. File Identity: Execution Log, Not Implementation

The file `coordinage_implement.md` is an execution transcript showing:

**Lines 1-6**: User invoked `/coordinate implement <plan>`:
```
/coordinate is running… implement /home/benjamin/.config/.claude/specs/661_and_the_standards_in_claude_docs_to_avoid/plans/002_coordinate_revision_workflow_fixes.md
  ⎿  Allowed 4 tools for this command

● I'll execute the /coordinate command to implement the plan for fixing the coordinate revision workflow.
```

**Lines 32-37**: /coordinate misdetected scope as "research-and-plan" when user said "implement":
```
● I see the issue - the workflow scope was detected as "research-and-plan" but we actually want "full-implementation" since
  the user said "implement". The workflow scope detection needs to be corrected. Let me trace through what happened and
  execute the plan directly using /implement:

> /implement is running… /home/benjamin/.config/.claude/specs/661_and_the_standards_in_claude_docs_to_avoid/plans/002_coordinate_revision_workflow_fixes.md
```

This shows **/coordinate falling back to invoking /implement as a SlashCommand** when scope detection failed, not the expected behavior.

### 2. Actual /coordinate Implementation Analysis

Reading the actual implementation in `/home/benjamin/.config/.claude/commands/coordinate.md`:

**Lines 1113-1200**: Implementation phase uses **Task tool with implementer-coordinator agent**:

```markdown
## State Handler: Implementation Phase

**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator:

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation with wave-based parallel execution"
  timeout: 600000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    **Workflow-Specific Context**:
    - Plan File: $PLAN_PATH (absolute path)
    - Topic Directory: $TOPIC_PATH
    - Artifact Paths:
      - Reports: $REPORTS_DIR
      - Plans: $PLANS_DIR
      - Summaries: $SUMMARIES_DIR
      - Debug: $DEBUG_DIR
      - Outputs: $OUTPUTS_DIR
      - Checkpoints: $CHECKPOINT_DIR

    **Execution Requirements**:
    - Wave-based parallel execution for independent phases
    - Automated testing after each wave
    - Git commits for completed phases
    - Checkpoint state management
    - Progress tracking and metrics collection

    Execute implementation following all guidelines in behavioral file.
    Return: IMPLEMENTATION_COMPLETE: [summary]
  "
}
```

**Key Architecture**:
- **No SlashCommand invocation of /implement**
- **Direct agent delegation** via Task tool to implementer-coordinator.md
- **Pre-calculated artifact paths** (Phase 0 optimization)
- **Context injection** pattern for behavioral file

### 3. Why SlashCommand Was Used in Transcript

The transcript shows /coordinate falling back to SlashCommand invocation because:

1. **Scope Detection Failure** (line 32): Workflow scope detected as "research-and-plan" instead of "full-implementation"
2. **Fallback Pattern** (line 34): "let me trace through what happened and execute the plan directly using /implement"
3. **User Instruction Violation**: User said "implement" but scope detector didn't detect full-implementation scope

This is a **bug in workflow scope detection**, not the intended architecture.

### 4. Expected vs Actual Pattern

**Expected Pattern** (from coordinate.md):
```
State: implement → Task tool → implementer-coordinator agent → wave-based execution
```

**Actual Pattern in Transcript** (coordinage_implement.md):
```
State: research-and-plan (wrong!) → fallback → SlashCommand(/implement) → standard /implement execution
```

### 5. Root Cause Analysis

The file `coordinage_implement.md` is located in **`.claude/specs/`** directory, which suggests it's a **debugging artifact** created during troubleshooting of workflow scope detection issues.

**Evidence**:
- Filename pattern `coordinage_<action>.md` suggests spec/analysis artifact
- File shows scope detection error explicitly
- User's workflow description was "implement <plan>" but scope detector returned "research-and-plan"
- /coordinate fell back to direct /implement invocation as emergency workaround

**Implication**: This is **NOT how /coordinate is supposed to work** in production. The correct implementation uses Task tool with implementer-coordinator agent.

## Recommendations

### 1. Fix Workflow Scope Detection

The workflow scope detection logic in `/coordinate` needs to handle explicit "implement" commands:

**Current Issue**: User says "implement <plan>" but scope detector returns "research-and-plan"

**Expected**: When user provides plan path in workflow description, scope should be "full-implementation"

**Fix Location**: `.claude/lib/workflow-scope-detection.sh` or equivalent

### 2. Document Scope Detection Rules

Create clear documentation for when each scope is selected:
- `research-only`: No plan mentioned
- `research-and-plan`: "plan X feature" pattern
- `full-implementation`: Plan path provided OR "implement" keyword
- `research-and-revise`: Existing plan + "revise" keyword

### 3. Remove Fallback SlashCommand Invocation

The fallback pattern where /coordinate invokes /implement via SlashCommand should be removed:

**Why**:
- Violates architectural principle (Task tool delegation)
- Bypasses Phase 0 optimization (pre-calculated paths)
- Loses context injection benefits
- Creates inconsistent execution patterns

**Alternative**: Fail-fast with clear error message about scope detection

### 4. Verify coordinage_*.md Files Are Debug Artifacts

Check if other `coordinage_*.md` files in `.claude/specs/` are also execution logs/debug artifacts:
- `coordinage_plan.md`
- `coordinage_output.md`

If so, these should either:
- Be moved to `.claude/tmp/` (temporary debug artifacts)
- Be documented as execution transcripts (not implementation files)
- Be deleted if obsolete

### 5. Add Scope Detection Tests

Create tests for workflow scope detection with explicit test cases:
```bash
# Test: "implement <plan-path>" → full-implementation
# Test: "plan auth feature" → research-and-plan
# Test: "research patterns" → research-only
# Test: "revise <plan>" → research-and-revise
```

## References

### Files Analyzed
- `/home/benjamin/.config/.claude/specs/coordinage_implement.md` (69 lines) - Execution log showing scope detection bug
- `/home/benjamin/.config/.claude/commands/coordinate.md` (1791 lines) - Actual implementation using Task tool
  - Lines 1113-1200: Implementation phase handler
  - Lines 1169-1200: Task tool invocation with implementer-coordinator agent
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` (referenced but not read) - Target agent for implementation phase

### Related Specs
- Workflow scope detection issue (evident from transcript)
- Phase 0 optimization (artifact path pre-calculation, lines 199-219 in coordinate.md)
- State machine architecture (lines 43-267 in coordinate.md)

### Key Line Numbers
- `coordinate.md:1169-1200` - Correct implementation pattern (Task tool delegation)
- `coordinage_implement.md:32-37` - Scope detection failure and fallback pattern
- `coordinage_implement.md:1-6` - User invocation showing "implement" keyword
