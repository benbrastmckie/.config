# Implementation Plan: Fix /create-plan Task Delegation

## Metadata

- **Date**: 2025-12-04
- **Feature**: Fix Task tool delegation failure in /create-plan command so subagents actually execute
- **Status**: [NOT STARTED]
- **Estimated Hours**: 2-4 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [001-task-delegation-failure-analysis.md](../reports/001-task-delegation-failure-analysis.md)

## Problem Statement

The `/create-plan` command uses `Task { ... }` pseudo-syntax that is NOT being translated into actual Task tool invocations. The orchestrating Claude instance reads the directives, understands what should happen, but then does the work directly instead of spawning subagents.

## Solution Options

### Option A: Stronger Instructional Language (Low Effort, Low Confidence)

Strengthen the directive language to more forcefully instruct Claude to use the Task tool.

**Pros**:
- Minimal changes required
- Quick to implement

**Cons**:
- Relies on model interpretation (non-deterministic)
- May work inconsistently
- Doesn't address fundamental architectural issue
- Other commands use same pattern and may work/fail inconsistently

**NOT RECOMMENDED** - Does not solve the root cause.

### Option B: Pre-Verification Barrier (Medium Effort, Medium Confidence)

Add a bash block BEFORE the Task pseudo-syntax that creates a "delegation marker" file, then check after the task that a subagent-specific completion marker exists.

**Pattern**:
```bash
# Before Task
echo "DELEGATION_REQUIRED" > "$DELEGATION_MARKER_FILE"
rm -f "$SUBAGENT_COMPLETION_MARKER"
```

Then after Task, verify:
```bash
# The subagent writes this marker
if [ ! -f "$SUBAGENT_COMPLETION_MARKER" ]; then
  echo "ERROR: Subagent delegation did not occur"
  exit 1
fi
```

**Pros**:
- Enforces delegation at runtime
- Fails fast if delegation doesn't occur

**Cons**:
- Doesn't CAUSE delegation, just detects failure
- Requires agent behavioral file changes
- Still relies on model interpretation

**PARTIALLY RECOMMENDED** - Add as safety net, but doesn't solve root cause.

### Option C: Model Selection for Orchestrator (Low-Medium Effort, Medium Confidence)

The `/create-plan` command is expanded into the main conversation context. If the orchestrating model is highly capable (Opus), it may be more inclined to do work directly. Consider:

1. Using explicit model hints in command file
2. Investigating if slash commands can specify orchestrator model requirements

**Pros**:
- Different models may have different delegation behaviors
- No code changes to command logic

**Cons**:
- Speculative - no evidence this works
- May not be configurable

**INVESTIGATE** - Worth testing but not primary solution.

### Option D: Fundamental Architecture Change (High Effort, High Confidence)

The pseudo-syntax `Task { ... }` fundamentally doesn't work because it's not actual tool invocation syntax. The correct solution is architectural:

**Approach 1: Direct Tool Invocation via Natural Language**

Instead of pseudo-syntax, use stronger natural language that Claude Code reliably interprets as tool invocations:

```markdown
**MANDATORY TOOL INVOCATION**: You MUST now use the Task tool with these exact parameters:

- subagent_type: "general-purpose"
- description: "Research ${FEATURE_DESCRIPTION}"
- prompt: [Full prompt content]

DO NOT read files, write files, or perform any other action. ONLY invoke the Task tool.
This is a blocking requirement - the workflow cannot continue until Task tool is invoked.
```

**Approach 2: Explicit XML Tool Invocation Template**

Provide the exact XML syntax Claude Code uses for tool invocation (though this is fragile and may not work as Claude generates its own tool call syntax).

**Approach 3: Hook-Based Enforcement**

Create a pre-task hook that:
1. Sets an environment flag
2. Monitors tool usage
3. Fails the workflow if expected tool not invoked within timeout

**RECOMMENDED** - This addresses the root cause architecturally.

## Recommended Implementation Plan

### Phase 1: Immediate Mitigation [NOT STARTED]

**Objective**: Add runtime detection of delegation failure to prevent silent failures.

**Tasks**:
- [ ] Add pre-delegation marker file creation in bash block before each Task
- [ ] Add completion marker verification in bash block after each Task
- [ ] Update agent behavioral files to create completion markers
- [ ] Test that workflow fails fast when delegation doesn't occur

**Success Criteria**:
- [ ] Workflow fails with clear error message if delegation doesn't occur
- [ ] Error message indicates which Task failed to delegate

### Phase 2: Directive Strengthening [NOT STARTED]

**Objective**: Strengthen instructional language to maximize delegation probability.

**Tasks**:
- [ ] Research working command examples that successfully delegate
- [ ] A/B test different directive phrasings
- [ ] Update create-plan.md with strongest performing phrasing
- [ ] Document findings in command-authoring.md

**Success Criteria**:
- [ ] Delegation success rate > 90% on test runs
- [ ] Documented pattern for other commands

### Phase 3: Model Configuration [NOT STARTED]

**Objective**: Investigate model selection impact on delegation behavior.

**Tasks**:
- [ ] Test /create-plan with different orchestrator models (if configurable)
- [ ] Test subagent model specifications (haiku vs sonnet)
- [ ] Document optimal model configuration

**Success Criteria**:
- [ ] Clear recommendation for model selection
- [ ] Updated command file with model specifications if beneficial

### Phase 4: Architectural Review [NOT STARTED]

**Objective**: Determine if fundamental architecture change is needed.

**Tasks**:
- [ ] Review Claude Code documentation for recommended Task delegation patterns
- [ ] Investigate hook-based enforcement mechanisms
- [ ] Create proof-of-concept with alternative architecture
- [ ] Assess effort vs benefit of architectural change

**Success Criteria**:
- [ ] Clear recommendation for architectural approach
- [ ] Plan for implementation if changes needed

## Testing Strategy

### Unit Tests
- [ ] Test delegation marker creation/verification
- [ ] Test error messages on delegation failure
- [ ] Test completion signal parsing

### Integration Tests
- [ ] Run /create-plan 5x with simple description
- [ ] Verify subagent invocation (check for Task tool in output)
- [ ] Verify artifact creation by subagents (not orchestrator)
- [ ] Measure success rate

### Acceptance Criteria
1. /create-plan invokes Task tool for topic-naming-agent
2. /create-plan invokes Task tool for research-specialist
3. /create-plan invokes Task tool for plan-architect
4. Artifacts are created by subagents, not orchestrator
5. Context usage is reduced (main conversation smaller)

## Notes

### On Model Upgrades

The user asked about upgrading models for /create-plan. Recommendations:

1. **topic-naming-agent**: Keep as `model: "haiku"` - simple task, speed matters
2. **research-specialist**: Consider `model: "sonnet"` - complex analysis benefits from capability
3. **plan-architect**: Consider `model: "sonnet"` - plan quality benefits from capability

However, model upgrades are moot if Task tool is never invoked. Fix delegation first.

### Related Commands

These commands use identical `Task { ... }` syntax and may have the same issue:
- /debug (lines 321, 657, 944, 1201)
- /repair (lines 544, 1209)
- /research (lines 366, 839)
- /revise (lines 621, 1051)
- /implement (lines 500, 967)
- /test (lines 407, 664)
- All other commands with Task blocks

A systemic fix would benefit the entire command suite.
