---
description: Execute implementation with resume support
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, mcp__lean-lsp__*
argument-hint: TASK_NUMBER
model: claude-opus-4-5-20251101
---

# /implement Command

Execute implementation plan with automatic resume support.

## Arguments

- `$1` - Task number (required)
- Optional: `--force` to override status validation

## Execution

### 1. Parse and Validate

```
task_number = first token from $ARGUMENTS
force_mode = "--force" in $ARGUMENTS
```

Read .claude/specs/state.json:
- Find task by project_number
- Extract: language, status, project_name, description
- If not found: Error "Task {N} not found"

### 2. Validate Status

Allowed: planned, implementing, partial, researched, not_started
- If completed: Error unless --force
- If abandoned: Error "Recover task first"
- If implementing: Resume from last incomplete phase

### 3. Load Implementation Plan

Find latest plan:
```
.claude/specs/{N}_{SLUG}/plans/implementation-{LATEST}.md
```

Parse plan to extract:
- Phases with status markers
- Files to modify per phase
- Steps and verification criteria

### 4. Detect Resume Point

Scan phases for first incomplete:
- [NOT STARTED] → Start here
- [IN PROGRESS] → Resume here
- [COMPLETED] → Skip
- [PARTIAL] → Resume here

If all phases [COMPLETED]: Task already done

### 5. Update Status to IMPLEMENTING

Update both files atomically:
1. state.json: status = "implementing"
2. TODO.md: Status: [IMPLEMENTING]

### 6. Execute Phases

For each phase starting from resume point:

**A. Mark Phase In Progress**
Update plan file: Phase N status → [IN PROGRESS]

**B. Execute Steps**

Route by language:

**Lean tasks:**
- Use lean-lsp MCP tools
- `lean_goal` - Check proof state constantly
- `lean_diagnostic_messages` - Verify no errors
- `lean_hover_info` - Check types
- `lean_multi_attempt` - Try multiple tactics
- Write/Edit .lean files
- Run `lake build` to verify

**General tasks:**
- Read/Write/Edit source files
- Run tests if applicable
- Verify changes work

**C. Verify Phase**
Check verification criteria from plan

**D. Mark Phase Complete**
Update plan file: Phase N status → [COMPLETED]

**E. Git Commit for Phase**
```bash
git add -A
git commit -m "task {N} phase {P}: {phase_name}"
```

### 7. Handle Errors/Timeouts

**On Error:**
- Keep phase as [IN PROGRESS]
- Log error details
- Return partial status
- Next /implement will resume

**On Timeout:**
- Mark phase [PARTIAL]
- Preserve all progress
- Git commit partial work
- Next /implement will resume

### 8. Complete Implementation

After all phases done:

1. **Update Status to COMPLETED**
   - state.json: status = "completed"
   - TODO.md: Status: [COMPLETED], add Completed date

2. **Create Summary**
   Write to `.claude/specs/{N}_{SLUG}/summaries/implementation-summary-{DATE}.md`:
   ```markdown
   # Implementation Summary: Task #{N}

   **Completed**: {ISO_DATE}
   **Duration**: {total time}

   ## Changes Made

   {Summary of all changes}

   ## Files Modified

   - `path/to/file` - {change description}

   ## Verification

   - {What was verified}
   - {Test results}

   ## Notes

   {Any additional notes or follow-up items}
   ```

3. **Final Git Commit**
   ```bash
   git add -A
   git commit -m "task {N}: complete implementation"
   ```

### 9. Output

**During Execution:**
```
Implementing Task #{N}: {title}

Phase 1: {name} [IN PROGRESS]
  Step 1: {description}... done
  Step 2: {description}... done
Phase 1: [COMPLETED]

Phase 2: {name} [IN PROGRESS]
...
```

**On Completion:**
```
Implementation complete for Task #{N}

Summary: .claude/specs/{N}_{SLUG}/summaries/implementation-summary-{DATE}.md

Status: [COMPLETED]
```

**On Partial:**
```
Implementation paused for Task #{N}

Completed: Phases 1-2
Remaining: Phase 3

Status: [IMPLEMENTING]
Next: /implement {N} (will resume from Phase 3)
```
