---
description: Research a task and create reports
allowed-tools: Skill, Bash(jq:*), Bash(git:*), Read, Edit
argument-hint: TASK_NUMBER [FOCUS]
model: claude-opus-4-5-20251101
---

# /research Command

Conduct research for a task by delegating to the appropriate research skill/subagent.

## Arguments

- `$1` - Task number (required)
- Remaining args - Optional focus/prompt for research direction

## Execution

**Note**: Delegate to skills for language-specific research.

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
| `general`, `meta`, `markdown`, `latex`, `typst` | `skill-researcher` |

**Invoke the Skill tool NOW** with:
```
skill: "{skill-name from table above}"
args: "task_number={N} focus={focus_prompt} session_id={session_id}"
```

The skill will spawn the appropriate agent to conduct research and create a report.

**On DELEGATE success**: Research complete. **IMMEDIATELY CONTINUE** to CHECKPOINT 2 below.

### CHECKPOINT 2: GATE OUT

1. **Validate Return**
   Required fields: status, summary, artifacts

2. **Verify Artifacts**
   Check each artifact path exists on disk

3. **Verify Status Updated**
   The skill handles status updates internally (preflight and postflight).
   Confirm status is now "researched" in state.json.

**RETRY** skill if validation fails.

**On GATE OUT success**: Artifacts verified. **IMMEDIATELY CONTINUE** to CHECKPOINT 3 below.

### CHECKPOINT 3: COMMIT

```bash
git add -A
git commit -m "$(cat <<'EOF'
task {N}: complete research

Session: {session_id}

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

Commit failure is non-blocking (log and continue).

## Output

```
Research completed for Task #{N}

Report: specs/{NNN}_{SLUG}/reports/research-{NNN}.md (padded path from skill result)

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
