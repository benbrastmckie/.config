# Task Invocation Pattern Migration Guide

## Purpose

This guide provides step-by-step instructions for converting legacy Task invocation patterns (pseudo-code syntax and instructional text) to the mandatory imperative directive pattern.

## Target Audience

- Developers updating existing command files
- Maintainers fixing linter violations
- Anyone creating new slash commands

## Migration Context

**Spec Reference**: 006_plan_command_orchestration_fix

Between December 2025, all command files using pseudo-code Task syntax were systematically converted to imperative directives. This migration eliminated delegation bypass issues where orchestrators performed agent work inline instead of delegating via the Task tool.

**Impact**: 40-60% reduction in orchestrator context usage, 100% delegation success rate, improved architectural consistency.

---

## Pattern Types and Migration

### Pattern 1: Pseudo-Code Task Blocks

**Before** (pseudo-code - PROHIBITED):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: |
    Read and follow ALL instructions in: research-specialist.md

    Research Topic: ${TOPIC}
    Output Path: ${REPORT_PATH}
}
```

**After** (imperative directive - REQUIRED):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${TOPIC}
    - Output Path: ${REPORT_PATH}

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

**Key Changes**:
1. Added imperative instruction: "**EXECUTE NOW**: USE the Task tool to invoke..."
2. Removed YAML code block wrapper (` ```yaml `)
3. Changed `prompt: |` to `prompt: "` (inline prompt with variable interpolation)
4. Added explicit completion signal requirement
5. Changed "instructions" to "behavioral guidelines" (standard terminology)

**Commands Fixed**: `/build`, `/debug`, `/plan`, `/repair`, `/research`, `/revise`

### Pattern 2: Instructional Text Without Task Invocation

**Before** (instructional text - PROHIBITED):
```markdown
## Phase 3: Agent Delegation

This phase invokes the test-executor agent.
Use the Task tool to invoke the agent with the test suite path.
The agent will run tests and return coverage results.
```

**After** (actual Task invocation - REQUIRED):
```markdown
## Phase 3: Agent Delegation

**EXECUTE NOW**: USE the Task tool to invoke the test-executor agent.

Task {
  subagent_type: "general-purpose"
  description: "Run test suite with coverage tracking"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-executor.md

    **Workflow-Specific Context**:
    - Plan Path: ${PLAN_PATH}
    - Test Suite Path: ${TEST_SUITE_PATH}
    - Coverage Target: ${COVERAGE_TARGET}%

    Execute test suite per behavioral guidelines.
    Return: TESTS_COMPLETE: ${TEST_SUMMARY_PATH}
  "
}
```

**Key Changes**:
1. Converted instructional text to actual Task invocation
2. Added imperative directive
3. Created proper Task block structure with context variables
4. Added explicit completion signal

**Commands Fixed**: `/test`

### Pattern 3: Incomplete EXECUTE NOW Directives

**Before** (incomplete directive - PROHIBITED):
```markdown
**EXECUTE NOW**: Invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "..."
}
```

**After** (complete directive - REQUIRED):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${TOPIC}
    - Output Path: ${REPORT_PATH}

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

**Key Changes**:
1. Added "USE the Task tool" phrase (explicit instruction)
2. Made agent name explicit in directive
3. Ensured prompt has complete context and completion signal

---

## Edge Case Patterns

### Iteration Loop Invocations

**Context**: Commands that re-invoke the same agent in iteration loops (e.g., `/implement`, `/test`).

**Before** (single directive for both invocations - INCOMPLETE):
```markdown
## Block 5: Initial Implementation

**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator.

Task { ... }

## Block 7: Iteration Loop Re-Invocation

```bash
if [ "$WORK_REMAINING" != "0" ]; then
  ITERATION=$((ITERATION + 1))
fi
```

Task { ... }
```

**After** (separate directive for each invocation - REQUIRED):
```markdown
## Block 5: Initial Implementation

**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Implement phase ${STARTING_PHASE}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    **Input Contract**:
    - plan_path: ${PLAN_PATH}
    - topic_path: ${TOPIC_PATH}
    - iteration: ${ITERATION}

    Execute implementation per behavioral guidelines.
    Return: IMPLEMENTATION_COMPLETE: ${SUMMARY_PATH}
  "
}

## Block 7: Iteration Loop Re-Invocation

```bash
if [ "$WORK_REMAINING" != "0" ]; then
  ITERATION=$((ITERATION + 1))
  echo "Iteration $ITERATION required"
fi
```

**EXECUTE NOW**: USE the Task tool to re-invoke implementer-coordinator for iteration ${ITERATION}.

Task {
  subagent_type: "general-purpose"
  description: "Continue implementation (iteration ${ITERATION})"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    **Input Contract**:
    - plan_path: ${PLAN_PATH}
    - topic_path: ${TOPIC_PATH}
    - iteration: ${ITERATION}
    - continuation_context: ${CONTINUATION_SUMMARY}

    Execute implementation per behavioral guidelines.
    Return: IMPLEMENTATION_COMPLETE: ${SUMMARY_PATH}
  "
}
```

**Key Points**:
- Each invocation point (initial and loop) requires separate imperative directive
- Loop re-invocation includes iteration number in directive text
- Continuation context passed to agent in loop invocation
- Both Task blocks have complete prompt structure

**Commands Fixed**: `/implement` (2 Task blocks), `/test` (2 Task blocks)

### Conditional Invocations

**Context**: Commands that invoke agents based on runtime conditions (e.g., coverage thresholds).

**Before** (conditional without explicit directive):
```markdown
```bash
if [ "$COVERAGE" -lt "$THRESHOLD" ]; then
  # Task invocation here
fi
```

Task { ... }
```

**After** (conditional imperative directive):
```markdown
```bash
COVERAGE=$(get_coverage_percentage)
THRESHOLD=80

if [ "$COVERAGE" -lt "$THRESHOLD" ]; then
  echo "Coverage ${COVERAGE}% below threshold ${THRESHOLD}% - re-running tests"
fi
```

**EXECUTE IF** coverage below threshold: USE the Task tool to invoke test-executor.

Task {
  subagent_type: "general-purpose"
  description: "Run test suite (iteration ${TEST_ITERATION})"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-executor.md

    **Workflow-Specific Context**:
    - Plan Path: ${PLAN_PATH}
    - Coverage Target: ${THRESHOLD}%
    - Current Coverage: ${COVERAGE}%
    - Test Iteration: ${TEST_ITERATION}

    Execute test suite per behavioral guidelines.
    Return: TESTS_COMPLETE: ${TEST_SUMMARY_PATH}
  "
}
```

**Alternative Pattern** (explicit bash conditional):
```bash
if [ "$COVERAGE" -lt "$THRESHOLD" ]; then
  echo "Coverage insufficient - invoking test-executor"
fi
```

**EXECUTE NOW**: USE the Task tool to invoke test-executor.

Task { ... }
```

**Key Points**:
- Use "**EXECUTE IF**" prefix for conditionally invoked agents
- Or use explicit bash conditional before standard "**EXECUTE NOW**" directive
- Include conditional context in agent prompt (coverage values, iteration numbers)

---

## Step-by-Step Migration Process

### Step 1: Identify Legacy Patterns

Run the linter to detect violations:

```bash
# Check specific command
bash .claude/scripts/lint-task-invocation-pattern.sh .claude/commands/COMMAND.md

# Check all commands
bash .claude/scripts/lint-task-invocation-pattern.sh
```

Linter reports:
- ERROR: `Task {` without EXECUTE NOW directive (line N)
- ERROR: Instructional text without actual Task invocation (line N)
- ERROR: Incomplete EXECUTE NOW directive (line N)

### Step 2: Classify the Pattern Type

Determine which pattern type applies:

1. **Pseudo-code**: Naked `Task {` block without directive
2. **Instructional text**: Comments describing Task invocation without actual Task block
3. **Incomplete directive**: "EXECUTE NOW: Invoke..." without "USE the Task tool"
4. **Iteration loop**: Task invocation inside iteration loop
5. **Conditional**: Task invocation based on runtime conditions

### Step 3: Apply the Appropriate Migration Pattern

Use the before/after examples above for your pattern type.

**Required Elements Checklist**:
- [ ] Imperative directive: "**EXECUTE NOW**: USE the Task tool to invoke [AGENT_NAME] agent"
- [ ] No code block wrapper around Task block
- [ ] Inline prompt with `prompt: "` (not `prompt: |`)
- [ ] Workflow-specific context variables in prompt
- [ ] Explicit completion signal: "Return: [SIGNAL_NAME]: ${PATH}"
- [ ] For iteration loops: separate directive for each invocation point
- [ ] For conditionals: "**EXECUTE IF**" prefix or explicit bash conditional

### Step 4: Test the Conversion

```bash
# Run linter to verify fix
bash .claude/scripts/lint-task-invocation-pattern.sh .claude/commands/COMMAND.md
# Expected: No errors

# Run hard barrier compliance validator
bash .claude/scripts/validate-hard-barrier-compliance.sh --command COMMAND
# Expected: 100% compliance

# Manual test: invoke the command
/COMMAND <args>
# Expected: Agent invoked (not inline work), artifacts created
```

### Step 5: Commit the Changes

```bash
git add .claude/commands/COMMAND.md
git commit -m "fix: convert COMMAND Task invocations to imperative directive pattern"
```

Pre-commit hook will validate the fix automatically.

---

## Command-by-Command Examples

### /build Command

**Fixed Components**: implementer-coordinator (1 invocation)

**Before**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Build implementation from plan"
  prompt: |
    Read instructions from: implementer-coordinator.md
}
```

**After**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the implementer-coordinator agent.

Task {
  subagent_type: "general-purpose"
  description: "Build implementation from plan with test execution"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    **Input Contract**:
    - plan_path: ${PLAN_PATH}
    - topic_path: ${TOPIC_PATH}
    - workflow_type: build

    Execute build workflow per behavioral guidelines.
    Return: BUILD_COMPLETE: ${SUMMARY_PATH}
  "
}
```

### /implement Command (Iteration Loop)

**Fixed Components**: implementer-coordinator (2 invocations - initial + loop)

**Before**:
```markdown
Task { subagent: "implementer-coordinator" }

# Later in iteration loop:
Task { subagent: "implementer-coordinator" }
```

**After**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Implement phase ${STARTING_PHASE}"
  prompt: "..."
}

# Iteration loop re-invocation:
**EXECUTE NOW**: USE the Task tool to re-invoke implementer-coordinator for iteration ${ITERATION}.

Task {
  subagent_type: "general-purpose"
  description: "Continue implementation (iteration ${ITERATION})"
  prompt: "..."
}
```

**Key Point**: Both invocation points require separate directives.

### /test Command (Instructional Text + Iteration Loop)

**Fixed Components**: test-executor (2 invocations), debug-analyst (1 invocation)

**Before** (instructional text pattern):
```markdown
## Phase 2: Test Execution

Use the Task tool to invoke the test-executor agent.
The agent will run the test suite and return coverage results.
```

**After**:
```markdown
## Phase 2: Test Execution

**EXECUTE NOW**: USE the Task tool to invoke the test-executor agent.

Task {
  subagent_type: "general-purpose"
  description: "Run test suite with coverage tracking"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-executor.md

    **Workflow-Specific Context**:
    - Plan Path: ${PLAN_PATH}
    - Coverage Target: ${COVERAGE_TARGET}%

    Execute test suite per behavioral guidelines.
    Return: TESTS_COMPLETE: ${TEST_SUMMARY_PATH}
  "
}
```

### /plan Command (Multiple Agents)

**Fixed Components**: research-specialist (1 invocation), plan-architect (1 invocation)

**Before**:
```markdown
Task { subagent: "research-specialist" }
Task { subagent: "plan-architect" }
```

**After**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC}"
  prompt: "..."
}

**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan from research"
  prompt: "..."
}
```

**Key Point**: Each agent requires its own imperative directive.

---

## Validation and Testing

### Automated Validation

```bash
# Run Task invocation linter
bash .claude/scripts/lint-task-invocation-pattern.sh

# Run all validators
bash .claude/scripts/validate-all-standards.sh --all

# Run hard barrier compliance validator
bash .claude/scripts/validate-hard-barrier-compliance.sh --verbose
```

### Manual Testing Checklist

After migration, verify:

- [ ] Command executes without errors
- [ ] Agent is invoked (check for behavioral file reads in output)
- [ ] Artifacts created at expected paths
- [ ] No inline work performed by orchestrator (check context usage)
- [ ] Completion signal returned by agent
- [ ] Hard barrier verification passes

### Pre-Commit Hook

The pre-commit hook automatically validates Task invocation patterns:

```bash
git add .claude/commands/COMMAND.md
git commit -m "fix: Task invocation pattern"
# Pre-commit hook runs lint-task-invocation-pattern.sh
# Commit blocked if violations found
```

---

## Troubleshooting

### Issue: Linter Still Reports Violation After Fix

**Symptoms**: Linter reports "Task { without EXECUTE NOW directive" even after adding directive.

**Cause**: Directive not within 5 lines before Task block, or missing "USE the Task tool" phrase.

**Solution**:
1. Ensure directive is immediately before Task block (no more than 5 lines separation)
2. Verify directive contains "USE the Task tool" phrase
3. Check for typos in directive format

**Correct Format**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the [AGENT_NAME] agent.

Task {
  ...
}
```

### Issue: Agent Not Invoked Despite Correct Pattern

**Symptoms**: Command executes but agent never runs, orchestrator performs work inline.

**Cause**: Code block wrapper around Task block, or missing variable interpolation.

**Solution**:
1. Remove ` ```yaml ` fences around Task block
2. Change `prompt: |` to `prompt: "` for inline interpolation
3. Verify variables are defined in workflow state

**Incorrect** (code block wrapper):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke agent.

```yaml
Task {
  prompt: |
    Static text
}
```
```

**Correct** (no wrapper):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke agent.

Task {
  prompt: "
    Dynamic text: ${VARIABLE}
  "
}
```

### Issue: Iteration Loop Only Runs Once

**Symptoms**: Iteration loop Task block executed only on first iteration, subsequent iterations skipped.

**Cause**: Missing imperative directive before loop re-invocation.

**Solution**: Add separate imperative directive before EACH Task invocation point (initial and loop).

**Correct Pattern**:
```markdown
# Initial invocation
**EXECUTE NOW**: USE the Task tool to invoke agent.
Task { ... }

# Loop re-invocation
**EXECUTE NOW**: USE the Task tool to re-invoke agent for iteration ${ITERATION}.
Task { ... }
```

### Issue: Conditional Invocation Always Executes

**Symptoms**: Conditionally invoked agent runs even when condition not met.

**Cause**: "**EXECUTE IF**" directive not properly aligned with bash conditional.

**Solution**: Use explicit bash conditional before standard "**EXECUTE NOW**" directive:

```bash
if [ "$CONDITION" = true ]; then
  echo "Condition met - invoking agent"
fi
```

**EXECUTE NOW**: USE the Task tool to invoke agent.

Task { ... }
```

---

## Related Documentation

- [Hard Barrier Subagent Delegation Pattern](../../concepts/patterns/hard-barrier-subagent-delegation.md#task-invocation-requirements)
- [Command Authoring Standards](../../reference/standards/command-authoring.md#task-tool-invocation-patterns)
- [Command Patterns Quick Reference](../../reference/command-patterns-quick-reference.md#agent-delegation-pattern)
- [Enforcement Mechanisms](../../reference/standards/enforcement-mechanisms.md#lint-task-invocation-patternsh)

---

**Last Updated**: 2025-12-02
**Spec Reference**: 006_plan_command_orchestration_fix
