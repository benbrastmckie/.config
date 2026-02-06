---
description: Execute implementation plan with resume support
allowed-tools: Skill, Bash(jq:*), Bash(git:*), Read, Edit, Read(/tmp/*.json), Bash(rm:*)
argument-hint: TASK_NUMBER
---

# /implement Command

Execute an implementation plan for a task by delegating to the appropriate implementation skill.

## Arguments

- `$1` - Task number (required)

## Execution

### CHECKPOINT 1: GATE IN

1. **Generate Session ID**
   ```
   session_id = sess_{timestamp}_{random}
   ```

2. **Lookup Task**
   ```bash
   task_data=$(jq -r --arg num "$task_number" \
     '.active_projects[] | select(.project_number == ($num | tonumber))' \
     specs/state.json)
   ```

3. **Validate**
   - Task exists (ABORT if not)
   - Status allows implementation: planned, implementing, partial, researched
   - If completed/abandoned: ABORT with recommendation
   - Check if plan exists (warn if not)

**ABORT** if any validation fails.

**On GATE IN success**: Task validated. **IMMEDIATELY CONTINUE** to STAGE 2 below.

### STAGE 2: DELEGATE

**EXECUTE NOW**: After CHECKPOINT 1 passes, immediately invoke the Skill tool.

**Language-Based Routing**:

| Language | Skill to Invoke |
|----------|-----------------|
| `neovim` | `skill-neovim-implementation` |
| `web` | `skill-web-implementation` |
| `general`, `meta`, `markdown` | `skill-implementer` |

**Invoke the Skill tool NOW** with:
```
skill: "{skill-name from table above}"
args: "task_number={N} session_id={session_id}"
```

The skill will:
1. Update status to [IMPLEMENTING] (preflight)
2. Read implementation plan
3. Find resume point (first incomplete phase)
4. Spawn the appropriate implementation agent
5. Execute phases sequentially
6. Run build verification after each phase
7. Update phase statuses
8. Create implementation summary
9. Update status to [COMPLETED] (postflight)
10. Link summary artifact in state.json
11. Git commit

**On DELEGATE success**: Implementation complete. **IMMEDIATELY CONTINUE** to CHECKPOINT 2 below.

### CHECKPOINT 2: GATE OUT

1. **Validate Return**
   - Skill should return: status, summary
   - Status should be "completed" or "partial"

2. **Verify Artifacts**
   Check that implementation summary exists:
   ```bash
   summary_path=$(jq -r --arg num "$task_number" \
     '.active_projects[] | select(.project_number == ($num | tonumber)) | .artifacts[] | select(.type == "summary") | .path' \
     specs/state.json)
   
   if [ -f "$summary_path" ]; then
     echo "Implementation summary verified: $summary_path"
   else
     echo "Warning: Summary not found at expected path"
   fi
   ```

3. **Verify Status Updated**
   Confirm status is now "completed" in state.json:
   ```bash
   current_status=$(jq -r --arg num "$task_number" \
     '.active_projects[] | select(.project_number == ($num | tonumber)) | .status' \
     specs/state.json)
   
   if [ "$current_status" = "completed" ]; then
     echo "Status confirmed: [COMPLETED]"
   elif [ "$current_status" = "partial" ]; then
     echo "Status: [PARTIAL] - Run /implement {N} to continue"
   else
     echo "Warning: Status is $current_status"
   fi
   ```

**RETRY** skill if validation fails (for transient errors).

**On GATE OUT success**: Implementation verified. **IMMEDIATELY CONTINUE** to CHECKPOINT 3 below.

### CHECKPOINT 3: COMMIT

```bash
git add -A
git commit -m "$(cat <<'EOF'
task {N}: complete implementation

Session: {session_id}

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

Commit failure is non-blocking (log and continue).

## Resume Support

If implementation was interrupted or partially completed:

1. The skill reads the plan file for status markers
2. Finds first [IN PROGRESS] or [NOT STARTED] phase
3. Resumes from that point
4. Updates status to [PARTIAL] if not all phases complete

## Output

### On Success
```
Implementation completed for Task #{N}

Summary: {artifact_path from skill result}

Phases Completed: {completed}/{total}
Build Status: {pass/fail}

Status: [COMPLETED]
```

### On Partial
```
Implementation partially completed for Task #{N}

Summary: {artifact_path from skill result}

Phases Completed: {completed}/{total}
Next Phase: {phase_name}

Status: [PARTIAL]
Run: /implement {N} to continue
```

## Error Handling

### GATE IN Failure
- Task not found: Return error with guidance
- Invalid status: Return error with current status

### DELEGATE Failure
- Skill fails: Keep [IMPLEMENTING], log error
- Build failure: Phase marked [BLOCKED], status [PARTIAL]
- Timeout: Partial implementation preserved, user can re-run

### GATE OUT Failure
- Missing summary: Log warning, continue with available
- Link failure: Non-blocking warning
