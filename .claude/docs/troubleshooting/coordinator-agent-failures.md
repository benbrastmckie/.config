# Coordinator Agent Failures Troubleshooting

## Overview

This guide covers common failure modes for coordinator agents (research-coordinator, implementer-coordinator, etc.) and provides diagnostic workflows and fixes.

## Common Symptoms

### Symptom 1: Empty Reports Directory

**Error Message**:
```
ERROR: Coordinator failure detected - reports directory is empty
Root Cause Analysis:
  - research-coordinator completed but created no reports
  - This indicates Task tool invocations were skipped or failed
```

**What Happened**:
- Coordinator agent completed execution (visible in tool use logs)
- No research-specialist or implementation-executor agents invoked
- Reports/summaries directory remains empty
- Workflow detects failure at hard barrier validation

**Diagnostic Steps**:

1. **Check Coordinator Tool Use Count**:
   ```bash
   # Look for coordinator completion message
   grep "Task.*completed" output.md
   # Example: "Task(Coordinate multi-topic research) completed"
   ```

2. **Verify Task Invocations**:
   - Check if coordinator invoked subagents (should see multiple "Task(...) starting" messages)
   - If only 1 Task completion (the coordinator itself), no subagents were invoked

3. **Review Agent Behavioral File**:
   ```bash
   # Check research-coordinator.md STEP 3 for Task invocation patterns
   grep -A 20 "STEP 3.*EXECUTE MANDATORY" .claude/agents/research-coordinator.md
   ```

4. **Look for Pseudo-Code Patterns**:
   - Code block wrappers: ` ```Task { }``` `
   - Bash variable syntax: `${TOPICS[0]}` instead of concrete values
   - Missing imperative directives: No "**EXECUTE NOW**: USE the Task tool..." prefix

**Root Causes**:

| Root Cause | Indicator | Fix |
|------------|-----------|-----|
| Pseudo-code Task patterns | Task blocks wrapped in ``` fences | Remove code fences, add imperative directives |
| Missing imperative directives | No "EXECUTE NOW" prefix | Add "**EXECUTE NOW**: USE the Task tool..." before each Task block |
| Bash variable placeholders | `${TOPICS[0]}` in Task prompts | Use descriptive placeholders: "(use TOPICS[0] - exact topic string)" |
| Agent misinterpreted patterns as docs | Coordinator completed without Task uses | Verify STEP 3 patterns match standards (see below) |

**Fix**:

Update coordinator agent behavioral file STEP 3 to use standards-compliant Task invocation patterns:

```markdown
**CHECKPOINT AFTER TOPIC 0**: Did you just USE the Task tool for topic at index 0?

**EXECUTE NOW**: USE the Task tool to invoke research-specialist for topic at index 0.

Task {
  subagent_type: "general-purpose"
  description: "Research topic at index 0 with mandatory file creation"
  prompt: "
    Read and follow behavioral guidelines from:
    (use CLAUDE_PROJECT_DIR)/.claude/agents/research-specialist.md

    **CRITICAL - Hard Barrier Pattern**:
    REPORT_PATH=(use REPORT_PATHS[0] - exact absolute path from array)

    **Research Topic**: (use TOPICS[0] - exact topic string from array)

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: (REPORT_PATHS[0])
  "
}
```

**Validation**:
```bash
# Run Task invocation pattern linter
bash .claude/scripts/lint-task-invocation-pattern.sh .claude/agents/research-coordinator.md

# Expected: 0 ERROR violations
```

---

### Symptom 2: Partial Report Creation

**Error Message**:
```
WARNING: Partial coordinator failure - some reports missing
Expected: 4 reports
Found: 2 reports
```

**What Happened**:
- Coordinator invoked some subagents but not all
- Reports directory has fewer files than expected
- Workflow continues with partial results (if ≥50% threshold met)

**Diagnostic Steps**:

1. **Count Expected vs Actual**:
   ```bash
   # Expected: Check topics count in command invocation
   grep "Expected reports:" output.md

   # Actual: Check reports directory
   ls .claude/specs/NNN_topic/reports/ | grep -c "^[0-9][0-9][0-9]-"
   ```

2. **Identify Missing Topics**:
   ```bash
   # Check which report numbers are missing
   ls .claude/specs/NNN_topic/reports/
   # Example: Has 001, 002, missing 003, 004
   ```

3. **Review Coordinator STEP 3**:
   - Check if Task invocation patterns exist for ALL topic indices (0, 1, 2, 3, 4, etc.)
   - Verify coordinator didn't skip indices (e.g., has 0, 1, but missing 2, 3)

**Root Causes**:

| Root Cause | Indicator | Fix |
|------------|-----------|-----|
| Incomplete Task invocation templates | Coordinator STEP 3 has only topics 0-2, but needs 0-4 | Add Task invocations for missing indices |
| Conditional logic errors | Task invocations wrapped in incorrect conditionals | Verify topic count conditionals |
| Agent stopped early | Coordinator self-validation checkpoint failed | Check STEP 3.5 self-check responses |

**Fix**:

Ensure coordinator STEP 3 has Task invocations for ALL expected topic indices:

```markdown
### STEP 3 (EXECUTE MANDATORY): Invoke Parallel Research Workers

**For each topic in TOPICS array (indices 0 through N-1), execute one Task invocation**:

<!-- Topic 0 -->
**EXECUTE NOW**: USE the Task tool for topic 0...
Task { ... }

<!-- Topic 1 -->
**EXECUTE NOW**: USE the Task tool for topic 1...
Task { ... }

<!-- Topic 2 -->
**EXECUTE NOW**: USE the Task tool for topic 2...
Task { ... }

<!-- Topic 3 -->
**EXECUTE NOW**: USE the Task tool for topic 3...
Task { ... }

<!-- Topic 4 -->
**EXECUTE NOW**: USE the Task tool for topic 4...
Task { ... }
```

---

### Symptom 3: "Error Retrieving Agent Output"

**Error Message**:
```
Task(Coordinate multi-topic research) completed
Agent Output 90639fbf -> Error retrieving agent output
```

**What Happened**:
- Coordinator Task completed
- Command attempted to retrieve coordinator's return signal
- Retrieval failed (agent output not accessible)
- This is often a secondary symptom of empty reports directory

**Diagnostic Steps**:

1. **Check if Reports Directory is Empty**:
   ```bash
   ls .claude/specs/NNN_topic/reports/
   # If empty (only . and ..), root cause is Task invocation failure, not retrieval
   ```

2. **Check Coordinator Completion Signal**:
   - Coordinator should return: `RESEARCH_COMPLETE: {N}`
   - If signal missing, coordinator STEP 5 (return signal) may be broken

3. **Verify Block 1e-validate Exists**:
   - Commands should have coordinator output validation BEFORE file checks
   - Check if command has Block 1e-validate between coordinator invocation and Block 1f

**Root Causes**:

| Root Cause | Indicator | Fix |
|------------|-----------|-----|
| Empty reports directory | No reports created | See "Symptom 1: Empty Reports Directory" |
| Missing return signal | Coordinator didn't output RESEARCH_COMPLETE | Fix coordinator STEP 5 return statement |
| Missing Block 1e-validate | Command proceeds directly to file checks | Add coordinator output validation block |

**Fix**:

Add Block 1e-validate to command BEFORE Block 1f:

```markdown
## Block 1e-validate: Coordinator Output Signal Validation

**EXECUTE NOW**: Validate research-coordinator output signal before hard barrier file checks.

```bash
# Count expected vs actual reports
EXPECTED_REPORT_COUNT="${#REPORT_PATHS_ARRAY[@]}"
ACTUAL_REPORT_COUNT=$(find "$RESEARCH_DIR" -name "[0-9][0-9][0-9]-*.md" -type f 2>/dev/null | wc -l)

# Early detection: If reports directory is empty, coordinator failed
if [ "$ACTUAL_REPORT_COUNT" -eq 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "research-coordinator failed - no reports created (empty directory detected)" \
    "bash_block_1e_validate" \
    "$(jq -n --arg dir "$RESEARCH_DIR" --argjson expected "$EXPECTED_REPORT_COUNT" \
       '{research_dir: $dir, expected_reports: $expected, actual_reports: 0}')"

  echo "ERROR: Coordinator failure detected - reports directory is empty" >&2
  exit 1
fi
```
```

---

## Preventive Measures

### 1. Lint Agent Behavioral Files

Run Task invocation pattern linter before committing changes:

```bash
# Check all coordinator agents
find .claude/agents -name "*coordinator*.md" -exec \
  bash .claude/scripts/lint-task-invocation-pattern.sh {} \;

# Expected: 0 ERROR violations across all files
```

### 2. Add Block 1e-validate to Commands

All commands invoking coordinators should have output validation:

```markdown
## Block 1e-exec: Coordinator Invocation
**EXECUTE NOW**: USE the Task tool to invoke coordinator...

## Block 1e-validate: Coordinator Output Validation
**EXECUTE NOW**: Validate coordinator created expected outputs...

## Block 1f: File Content Validation
**EXECUTE NOW**: Validate file existence and structure...
```

### 3. Enhance Coordinator Self-Validation

Add mandatory self-check questions in STEP 3.5:

```markdown
### STEP 3.5 (MANDATORY SELF-VALIDATION): Verify Task Invocations

**SELF-CHECK QUESTIONS**:

1. Did you actually USE the Task tool for each topic?
   - Required Answer: YES

2. How many Task tool invocations did you execute?
   - Required Count: MUST EQUAL TOPICS array length

**MANDATORY CHECKPOINT COUNT**:
Write: "I executed [N] Task tool invocations for [M] topics. N == M: [TRUE|FALSE]"

If FALSE, immediately return to STEP 3.
```

### 4. Add Invocation Trace Logging

Create trace files for debugging:

```markdown
**Invocation Trace File**: Create trace at `$REPORT_DIR/.invocation-trace.log`:

[2025-12-09_14:32:15] Topic[0]: OAuth2 authentication | Path: /path/to/001-oauth2.md | Status: INVOKED
[2025-12-09_14:32:47] Topic[0]: OAuth2 authentication | Path: /path/to/001-oauth2.md | Status: COMPLETED
```

Preserve on failure, delete on success.

---

## Recovery Workflows

### Recovery 1: Fix and Re-run

If coordinator failure detected:

1. Fix agent behavioral file (see fixes above)
2. Re-run command: `/create-plan "same description"`
3. Verify Block 1e-validate passes
4. Verify all reports created

### Recovery 2: Manual Fallback

If coordinator cannot be fixed immediately:

1. Decompose topics manually
2. Invoke research-specialist directly for each topic
3. Create reports at expected paths
4. Continue workflow from next block

Example:
```bash
# Manual research-specialist invocations
for topic in "OAuth2" "Sessions" "Passwords"; do
  # Use Task tool to invoke research-specialist with topic
done
```

### Recovery 3: Query Error History

Check for patterns across failures:

```bash
# Query coordinator errors
/errors --type agent_error --limit 20

# Analyze error patterns
/repair --type agent_error --complexity 2
```

---

## Reference Links

- [Task Tool Invocation Patterns](../reference/standards/command-authoring.md#task-tool-invocation-patterns)
- [Hierarchical Agents Examples - Research Coordinator](../concepts/hierarchical-agents-examples.md#example-7-research-coordinator)
- [Hard Barrier Subagent Delegation](../concepts/patterns/hard-barrier-subagent-delegation.md)
- [Error Handling Pattern](../concepts/patterns/error-handling.md)
