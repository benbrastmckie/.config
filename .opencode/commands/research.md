---
description: Research a task and create reports
allowed-tools: Skill, Bash(jq:*), Bash(git:*), Read, Edit, Read(/tmp/*.json), Bash(rm:*)
argument-hint: TASK_NUMBER [FOCUS]
---

# /research Command

Conduct research for a task by delegating to the appropriate research skill.

## Arguments

- `$1` - Task number (required)
- Remaining args - Optional focus/prompt for research direction

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
   - Status allows research: not_started, planned, partial, blocked, researched
   - If completed/abandoned: ABORT with recommendation

**ABORT** if any validation fails.

**On GATE IN success**: Task validated. **IMMEDIATELY CONTINUE** to STAGE 2 below.

### STAGE 2: DELEGATE

**EXECUTE NOW**: After CHECKPOINT 1 passes, immediately invoke the Skill tool.

**Language-Based Routing**:

| Language | Skill to Invoke |
|----------|-----------------|
| `neovim` | `skill-neovim-research` |
| `web` | `skill-web-research` |
| `general`, `meta`, `markdown` | `skill-researcher` |

**Invoke the Skill tool NOW** with:
```
skill: "{skill-name from table above}"
args: "task_number={N} focus={focus_prompt} session_id={session_id}"
```

The skill will:
1. Update status to [RESEARCHING] (preflight)
2. Spawn the appropriate research agent
3. Create a research report
4. Update status to [RESEARCHED] (postflight)
5. Link artifacts in state.json
6. Git commit

**On DELEGATE success**: Research complete. **IMMEDIATELY CONTINUE** to CHECKPOINT 2 below.

### CHECKPOINT 2: GATE OUT

1. **Validate Return**
   - Skill should return: status, summary
   - Status should be "researched"

2. **Verify Artifacts**
   Check that research report exists:
   ```bash
   report_path=$(jq -r --arg num "$task_number" \
     '.active_projects[] | select(.project_number == ($num | tonumber)) | .artifacts[] | select(.type == "research") | .path' \
     specs/state.json)
   
   if [ -f "$report_path" ]; then
     echo "Research report verified: $report_path"
   else
     echo "Warning: Research report not found at expected path"
   fi
   ```

3. **Verify Status Updated**
   Confirm status is now "researched" in state.json:
   ```bash
   current_status=$(jq -r --arg num "$task_number" \
     '.active_projects[] | select(.project_number == ($num | tonumber)) | .status' \
     specs/state.json)
   
   if [ "$current_status" = "researched" ]; then
     echo "Status confirmed: [RESEARCHED]"
   else
     echo "Warning: Status is $current_status, expected researched"
   fi
   ```

**RETRY** skill if validation fails.

**On GATE OUT success**: Artifacts verified. **IMMEDIATELY CONTINUE** to CHECKPOINT 3 below.

### CHECKPOINT 3: COMMIT

```bash
git add -A
git commit -m "$(cat <<'EOF'
task {N}: complete research

Session: {session_id}

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

Commit failure is non-blocking (log and continue).

## Output

```
Research completed for Task #{N}

Report: {artifact_path from skill result}

Summary: {summary from skill result}

Status: [RESEARCHED]
Next: /plan {N}
```

## Error Handling

### GATE IN Failure
- Task not found: Return error with guidance
- Invalid status: Return error with current status

### DELEGATE Failure
- Skill fails: Keep [RESEARCHING], log error
- Timeout: Partial research preserved, user can re-run

### GATE OUT Failure
- Missing artifacts: Log warning, continue with available
- Link failure: Non-blocking warning
