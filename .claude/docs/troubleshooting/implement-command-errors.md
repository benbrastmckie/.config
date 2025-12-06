# /implement Command Troubleshooting

This guide covers common errors and troubleshooting scenarios for the `/implement` command.

## Table of Contents

1. [Why did my workflow continue despite agent returning false?](#continuation-override)
2. [Workflow halted with incomplete work](#workflow-halted-incomplete-work)
3. [Max iterations reached](#max-iterations-reached)
4. [Stuck detection](#stuck-detection)

---

## Continuation Override

### Problem

You see a warning message during `/implement` execution:

```
WARNING: Agent returned requires_continuation=false with non-empty work_remaining
  work_remaining: Phase_4 Phase_5 Phase_6
  OVERRIDING: Forcing continuation due to incomplete work
```

And the workflow continues to the next iteration despite the agent returning `requires_continuation: false`.

### Explanation

This is the **defensive validation** feature working correctly. The `/implement` command includes defensive logic that validates the relationship between `work_remaining` and `requires_continuation` signals from the implementer-coordinator agent.

**Contract Invariant**:
- If `work_remaining` contains phase identifiers → `requires_continuation` MUST be `true`
- If agent violates this invariant → Orchestrator overrides the signal to `true`

### Why This Happens

The implementer-coordinator agent has a bug in its continuation logic that caused it to return `requires_continuation: false` even though incomplete work remains. Without defensive validation, this would cause the workflow to halt prematurely.

### Resolution

The override is **automatic and transparent** - the workflow continues correctly despite the agent bug. However, you should investigate the root cause:

**Step 1: Query validation errors**

```bash
/errors --type validation_error --command /implement --limit 10
```

This shows all logged instances of agent contract violations.

**Step 2: Review error details**

Each validation error log entry includes:
- `work_remaining` value at time of violation
- `requires_continuation` value that was overridden
- Workflow ID and iteration number

**Step 3: Monitor for patterns**

If you see frequent validation errors:
1. The implementer-coordinator agent may need bug fixes
2. The plan structure may be causing agent confusion
3. Consider filing an issue with agent logs for investigation

### Prevention

The defensive override is a **safety feature** - it prevents workflow halt with incomplete work. No action is required unless you want to diagnose agent bugs.

---

## Workflow Halted Incomplete Work

### Problem

The `/implement` command completes but reports:

```
Implementation halted - max iterations or other limit reached
work_remaining: Phase_7 Phase_8 Phase_9
```

### Causes

1. **Max iterations reached**: Default is 5 iterations, may be too low for large plans
2. **Stuck detection**: Work remaining unchanged across 2+ iterations
3. **Manual interruption**: Workflow was stopped mid-execution

### Resolution

**If max iterations reached**:

Increase the iteration limit:
```bash
/implement plan.md --max-iterations=10
```

**If stuck detected**:

Check what caused the agent to make no progress:
```bash
/errors --command /implement --since 1h --type agent_error
```

Possible causes:
- Phase implementation failing repeatedly
- Missing dependencies or files
- Test failures blocking progress

**If manually interrupted**:

Resume from checkpoint:
```bash
/implement --resume .claude/tmp/implement_checkpoint_*.json
```

---

## Max Iterations Reached

### Problem

```
Max iterations (5) reached. Work remaining: Phase 10 Phase 11 Phase 12
```

### Explanation

The `/implement` command has a maximum iteration limit (default: 5) to prevent infinite loops. Large or complex plans may legitimately require more iterations.

### Resolution

**Option 1: Increase iteration limit**

```bash
/implement plan.md --max-iterations=10
```

**Option 2: Continue from checkpoint**

The workflow saves a summary at each iteration. You can review the summary and manually continue:

```bash
# Review last iteration summary
cat .claude/specs/{topic}/summaries/*

# Continue implementation
/implement plan.md
```

**Option 3: Split the plan**

If a plan consistently requires 5+ iterations, consider splitting it into smaller, more focused plans:

```bash
# Split large plan into smaller plans
/create-plan "Implement Phase 1-5 of large feature" --complexity 2
/create-plan "Implement Phase 6-12 of large feature" --complexity 3
```

### Best Practices

- Use default max iterations (5) for most plans
- Increase limit for known large plans (10+ phases)
- Monitor iteration count - if consistently >3, plan may be too complex
- Lower context threshold for more aggressive iteration: `--context-threshold=85`

---

## Stuck Detection

### Problem

```
Implementation halted - stuck detected by coordinator
work_remaining: Phase 7 Phase 8
```

### Explanation

The `/implement` orchestrator tracks `work_remaining` across iterations. If the value is unchanged for 2+ consecutive iterations, it indicates the agent is stuck (no progress being made).

### Causes

1. **Phase implementation failing**: Repeated errors in same phase
2. **Test failures**: Tests blocking phase completion
3. **Agent bug**: Continuation logic not updating work_remaining
4. **Missing dependencies**: Files or tools not available

### Diagnosis

**Step 1: Review iteration summaries**

```bash
ls .claude/specs/{topic}/summaries/
cat .claude/specs/{topic}/summaries/*_iteration_N_summary.md
```

Look for:
- Same phase listed in multiple summaries
- Error messages in "Errors Encountered" section
- Missing test results

**Step 2: Query error logs**

```bash
/errors --command /implement --since 1h
```

Look for:
- Repeated errors in same phase
- State errors or validation errors
- Agent delegation failures

**Step 3: Check phase status**

```bash
grep -A 5 "Phase 7:" .claude/specs/{topic}/plans/*.md
```

Verify:
- Are all tasks checked off?
- Is phase marked [COMPLETE]?
- Are there any skipped tasks?

### Resolution

**If phase failing**:
1. Review error logs for specific failure cause
2. Fix underlying issue (missing file, syntax error, etc.)
3. Re-run `/implement plan.md` to continue

**If test failures**:
1. Run tests manually to diagnose: `/test plan.md`
2. Fix failing tests
3. Re-run `/implement plan.md`

**If agent bug**:
1. Check implementer-coordinator logs in debug/ directory
2. File issue with logs and plan file
3. Use `/repair` command to create fix plan

---

## Error Logging Integration

All `/implement` errors are automatically logged to `.claude/data/errors.jsonl` for queryable diagnostics.

**Query recent errors**:
```bash
/errors --command /implement --since 1h --summary
```

**Query specific error types**:
```bash
/errors --type validation_error --command /implement
/errors --type state_error --command /implement
/errors --type agent_error --command /implement
```

**Analyze error patterns and create fix plan**:
```bash
/repair --command /implement --since 24h --complexity 2
```

This creates an implementation plan to fix recurring errors.

---

## Related Documentation

- [Implement Command Guide](../guides/commands/implement-command-guide.md) - Complete command reference
- [Error Handling Pattern](../concepts/patterns/error-handling.md) - Error logging integration
- [Errors Command Guide](../guides/commands/errors-command-guide.md) - Error query command
- [Repair Command Guide](../guides/commands/repair-command-guide.md) - Error repair workflow
- [Implementer Coordinator Agent](../../agents/implementer-coordinator.md) - Agent contract documentation
