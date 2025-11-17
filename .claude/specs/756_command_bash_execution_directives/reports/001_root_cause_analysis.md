# Root Cause Analysis: Command Bash Execution Failures

## Problem Statement

The `/research-plan` command (and similar workflow commands) fail silently - bash blocks are not executed, state machine is never initialized, and the LLM improvises its own approach instead of following the prescribed workflow.

Evidence from `/home/benjamin/.config/.claude/research_plan_output.md`:
- No "=== Research-and-Plan Workflow ===" output from Part 1
- No "State machine initialized" message from Part 2
- No "CHECKPOINT: Research phase complete" from Part 3
- Agent used "Explore" tool instead of the prescribed `Task {}` syntax
- Files created manually without following state machine flow

## Root Causes Identified

### Root Cause 1: Missing Explicit Execution Directives

**Severity**: Critical
**Impact**: Bash blocks treated as documentation, not executable code

Commands that work (like `/coordinate`, `/research`) have explicit directives:
- `Execute this **small** bash block with your substitution:`
- `**EXECUTE NOW**: USE the Bash tool to source libraries:`

Commands that fail (like `/research-plan`) just have headers:
```markdown
## Part 1: Capture Feature Description

```bash
FEATURE_DESCRIPTION="$1"
...
```

Without "EXECUTE NOW" or similar, the LLM interprets these as examples rather than commands to run.

### Root Cause 2: Invalid `Task {}` Pseudo-Syntax

**Severity**: Critical
**Impact**: Agent delegation never happens

The commands use an invented syntax:
```
Task {
  subagent_type: "research-specialist"
  description: "Research $FEATURE_DESCRIPTION"
  prompt: |
    ...
}
```

This syntax:
- Is not valid markdown, YAML, JSON, or bash
- Has no execution directive telling LLM to use Task tool
- Contains shell variables that won't be interpolated
- Is not documented anywhere as a recognized format

### Root Cause 3: Variable State Loss Between Subprocess Bash Blocks

**Severity**: High
**Impact**: State machine flow breaks, variables undefined

Each bash code block runs in a separate shell subprocess. Variables set in Part 1 don't exist in Part 2.

The commands try to mitigate this with:
```bash
append_workflow_state "SPECS_DIR" "$SPECS_DIR"
```

But the corresponding `load_workflow_state` calls are in later blocks that also don't execute.

## Affected Commands Analysis

| Command | Exec Directives | Task {} Syntax | Bash Blocks | Status |
|---------|----------------|----------------|-------------|--------|
| research-plan.md | 0 | Yes (2 blocks) | 7 | BROKEN |
| research-report.md | 0 | Yes (1 block) | 5 | BROKEN |
| research-revise.md | 0 | Yes (2 blocks) | 7 | BROKEN |
| implement.md | 0 | No (comments) | 3 | BROKEN |
| build.md | 0 | No | 9 | BROKEN |
| debug.md | 0 | No | 7 | BROKEN |
| fix.md | 0 | No | 10 | BROKEN |
| coordinate.md | 13 | No | 16 | WORKING |
| research.md | 15 | No | 10 | WORKING |
| plan.md | 10 | No | 10 | WORKING |

## Why Failures Are Silent

1. **No runtime errors**: The LLM reads the file successfully
2. **LLM improvises**: Seeing "Research Phase" sections, it attempts research using its own approach
3. **Partial success**: Files may get created, giving appearance of progress
4. **No checkpoint output**: Expected outputs like "CHECKPOINT:" never appear because bash blocks don't run

## Evidence From Output

The output shows LLM improvisation:
```
Research Phase
Let me investigate the root cause.

Explore(Research spec numbering issue)
⎿  Done (37 tool uses · 90.1k tokens · 2m 20s)
```

Instead of prescribed flow:
```
=== Research-and-Plan Workflow ===
Feature: [description]
Research Complexity: 3

✓ State machine initialized

=== Phase 1: Research ===
[Task tool invocation for research-specialist]

CHECKPOINT: Research phase complete
```

## Solution Requirements

1. Add explicit execution directives before EVERY bash block
2. Replace `Task {}` pseudo-syntax with actual Task tool invocations
3. Consolidate bash blocks or ensure proper state persistence
4. Add verification that expected outputs appear
5. Consider using the two-step pattern from `/coordinate` for argument capture

## Reference Implementation

From `/coordinate.md` (working pattern):
```markdown
**STEP 1**: The user invoked `/coordinate "<workflow-description>"`. You need to capture that description.

Execute this **small** bash block with your substitution:

```bash
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > "$WORKFLOW_TEMP_FILE"
```

Now execute the main initialization (this reads from the file created above):

```bash
# Main logic
...
```
```

This explicit pattern ensures execution.
