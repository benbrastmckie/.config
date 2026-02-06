---
description: Create an implementation plan from research findings
allowed-tools: Skill, Bash(jq:*), Bash(git:*), Read, Edit, Read(/tmp/*.json), Bash(rm:*)
argument-hint: TASK_NUMBER
---

# /plan Command

Create a detailed implementation plan for a task by delegating to the planner skill.

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
   - Status allows planning: not_started, researched, partial
   - If completed/abandoned: ABORT with recommendation
   - Check if research exists (warn if not)

**ABORT** if any validation fails.

**On GATE IN success**: Task validated. **IMMEDIATELY CONTINUE** to STAGE 2 below.

### STAGE 2: DELEGATE

**EXECUTE NOW**: After CHECKPOINT 1 passes, immediately invoke the Skill tool.

**Invoke skill-planner**:
```
skill: "skill-planner"
args: "task_number={N} session_id={session_id}"
```

The skill will:
1. Update status to [PLANNING] (preflight)
2. Read research report if available
3. Spawn the planner agent
4. Create implementation plan
5. Update status to [PLANNED] (postflight)
6. Link plan artifact in state.json
7. Git commit

**On DELEGATE success**: Planning complete. **IMMEDIATELY CONTINUE** to CHECKPOINT 2 below.

### CHECKPOINT 2: GATE OUT

1. **Validate Return**
   - Skill should return: status, summary
   - Status should be "planned"

2. **Verify Artifacts**
   Check that plan exists:
   ```bash
   plan_path=$(jq -r --arg num "$task_number" \
     '.active_projects[] | select(.project_number == ($num | tonumber)) | .artifacts[] | select(.type == "plan") | .path' \
     specs/state.json)
   
   if [ -f "$plan_path" ]; then
     echo "Plan verified: $plan_path"
   else
     echo "Warning: Plan not found at expected path"
   fi
   ```

3. **Verify Status Updated**
   Confirm status is now "planned" in state.json:
   ```bash
   current_status=$(jq -r --arg num "$task_number" \
     '.active_projects[] | select(.project_number == ($num | tonumber)) | .status' \
     specs/state.json)
   
   if [ "$current_status" = "planned" ]; then
     echo "Status confirmed: [PLANNED]"
   else
     echo "Warning: Status is $current_status, expected planned"
   fi
   ```

**RETRY** skill if validation fails.

**On GATE OUT success**: Plan verified. **IMMEDIATELY CONTINUE** to CHECKPOINT 3 below.

### CHECKPOINT 3: COMMIT

```bash
git add -A
git commit -m "$(cat <<'EOF'
task {N}: create implementation plan

Session: {session_id}

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

Commit failure is non-blocking (log and continue).

## Output

```
Plan created for Task #{N}

Plan: {artifact_path from skill result}

Summary: {summary from skill result}
Phases: {phase_count}
Estimated Effort: {total_hours} hours

Status: [PLANNED]
Next: /implement {N}
```

## Error Handling

### GATE IN Failure
- Task not found: Return error with guidance
- Invalid status: Return error with current status

### DELEGATE Failure
- Skill fails: Keep [PLANNING], log error
- Timeout: Partial plan preserved, user can re-run

### GATE OUT Failure
- Missing plan: Log warning, continue with available
- Link failure: Non-blocking warning
