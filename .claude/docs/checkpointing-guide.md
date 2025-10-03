# Workflow Checkpointing Guide

Complete guide to workflow checkpointing for interruption recovery in Claude Code workflows.

## Overview

Checkpointing enables workflows to resume after interruption without losing progress. When a workflow is interrupted (process killed, system crash, manual stop), checkpoints allow resuming from the last completed phase instead of restarting from the beginning.

## How Checkpointing Works

### Automatic Checkpoint Creation

Checkpoints are automatically created during workflow execution:

**In `/orchestrate`**:
- After research phase completes
- After planning phase completes
- After implementation phase completes
- After debugging phase (if needed)

**In `/implement`**:
- After each phase completion (after git commit)
- Before moving to next phase
- On workflow pause or interruption

### Checkpoint Storage

Checkpoints are stored in `.claude/checkpoints/`:

```
checkpoints/
├── README.md
├── orchestrate_auth_system_20251003_184530.json
├── implement_dark_mode_20251003_192230.json
└── failed/
    └── orchestrate_broken_feature_20251003_150000.json
```

**Checkpoint Filename Format**:
`{workflow_type}_{project_name}_{timestamp}.json`

- `workflow_type`: `orchestrate`, `implement`, `test-all`
- `project_name`: Snake-case project identifier
- `timestamp`: `YYYYMMDD_HHMMSS` in UTC

### Checkpoint Contents

Each checkpoint file contains workflow state as JSON:

```json
{
  "checkpoint_id": "orchestrate_auth_system_20251003_184530",
  "workflow_type": "orchestrate",
  "project_name": "auth_system",
  "workflow_description": "Implement authentication system",
  "created_at": "2025-10-03T18:45:30Z",
  "updated_at": "2025-10-03T18:52:15Z",
  "status": "in_progress",
  "current_phase": 2,
  "total_phases": 5,
  "completed_phases": [1],
  "workflow_state": {
    "project_name": "auth_system",
    "artifact_registry": {...},
    "research_results": [...],
    "plan_path": "specs/plans/022_auth_implementation.md"
  },
  "last_error": null
}
```

## Resume Workflow

### Interactive Resume Prompt

When you restart a workflow command, it automatically detects existing checkpoints:

```
Found existing checkpoint for "Implement authentication system"
Created: 2025-10-03 18:45:30 (12 minutes ago)
Progress: Phase 2 of 5 completed

Options:
  (r)esume - Continue from Phase 3
  (s)tart fresh - Delete checkpoint and restart
  (v)iew details - Show checkpoint contents
  (d)elete - Remove checkpoint without starting

Choice [r/s/v/d]:
```

### Resume Options

**r) Resume**:
- Loads workflow state from checkpoint
- Restores progress, artifacts, and context
- Continues from next incomplete phase
- No data loss

**s) Start Fresh**:
- Deletes existing checkpoint
- Starts workflow from beginning
- Use when requirements changed significantly
- Previous progress discarded

**v) View Details**:
- Shows checkpoint file contents
- Displays workflow state and progress
- Helps decide whether to resume or restart
- Returns to options prompt

**d) Delete**:
- Removes checkpoint file
- Exits without starting workflow
- Use to clean up unwanted checkpoints
- No workflow execution

### Resume Examples

**Example 1: Resume After Interruption**
```bash
# Start workflow
/orchestrate "Implement user authentication"

# Research phase completes
# Planning phase completes
# [Process killed]

# Restart
/orchestrate
# Detects checkpoint, prompts to resume
# Choose (r)esume
# Continues from implementation phase
```

**Example 2: Implementation Resume**
```bash
# Start implementation
/implement specs/plans/018_auth_implementation.md

# Phase 1 completes
# Phase 2 completes
# [Manual stop with Ctrl+C]

# Restart
/implement
# Auto-detects incomplete plan
# Resumes from Phase 3
```

## Checkpoint Management

### List Active Checkpoints

```bash
# List all checkpoints
.claude/utils/list-checkpoints.sh

# List checkpoints for specific workflow type
.claude/utils/list-checkpoints.sh orchestrate
```

Output:
```
Active Checkpoints:
==================

Checkpoint: orchestrate_auth_system_20251003_184530.json
  Type: orchestrate
  Project: auth_system
  Description: Implement authentication system
  Created: 2025-10-03T18:45:30Z
  Progress: Phase 2 of 5
  Status: in_progress
```

### Manual Checkpoint Deletion

```bash
# Delete specific checkpoint
rm .claude/checkpoints/orchestrate_auth_system_*.json

# Delete all checkpoints (use with caution!)
rm .claude/checkpoints/*.json

# Archive checkpoint to failed/ directory
mv .claude/checkpoints/checkpoint.json .claude/checkpoints/failed/
```

### Automatic Cleanup

Checkpoints are automatically cleaned up:

**On Success**:
- Checkpoint deleted immediately when workflow completes successfully
- No manual cleanup needed

**On Failure**:
- Checkpoint moved to `checkpoints/failed/` directory
- Preserved for debugging (kept for 30 days)

**Age-Based**:
- Checkpoints older than 7 days automatically deleted
- Run cleanup manually: `.claude/utils/cleanup-checkpoints.sh`
- Customize age: `.claude/utils/cleanup-checkpoints.sh 14` (14 days)

## Advanced Usage

### Force Resume

To always resume without prompting (automation):
```bash
# Set CLAUDE_AUTO_RESUME environment variable
export CLAUDE_AUTO_RESUME=1
/orchestrate "Feature description"
# Will auto-resume if checkpoint exists
```

### View Checkpoint Contents

```bash
# Pretty-print checkpoint JSON
cat .claude/checkpoints/orchestrate_*.json | jq

# Check specific field
cat .claude/checkpoints/orchestrate_*.json | jq '.current_phase'
```

### Manual Checkpoint Creation

```bash
# Create checkpoint for custom workflow
.claude/utils/save-checkpoint.sh custom_workflow project_name '{
  "status": "in_progress",
  "phase": 2,
  "custom_data": "value"
}'
```

### Checkpoint Validation

```bash
# Validate checkpoint JSON
cat .claude/checkpoints/orchestrate_*.json | jq empty
# No output = valid JSON
# Error = corrupted checkpoint
```

## Troubleshooting

### Checkpoint Not Detected

**Problem**: Restarted workflow but no resume prompt appeared

**Solutions**:
1. Check checkpoint exists: `ls .claude/checkpoints/*.json`
2. Verify filename format matches `{type}_{project}_{timestamp}.json`
3. Check file permissions: `ls -la .claude/checkpoints/`
4. Ensure workflow description matches (for orchestrate)

### Corrupted Checkpoint

**Problem**: Error loading checkpoint, invalid JSON

**Solutions**:
```bash
# Validate checkpoint
cat .claude/checkpoints/checkpoint.json | jq empty

# If corrupted, delete and restart
rm .claude/checkpoints/checkpoint.json
/orchestrate "Description"  # Start fresh
```

### Multiple Checkpoints

**Problem**: Multiple checkpoints for same project

**Solutions**:
```bash
# List checkpoints to see all
.claude/utils/list-checkpoints.sh

# Delete old ones manually
ls -lt .claude/checkpoints/orchestrate_project_*.json
rm .claude/checkpoints/orchestrate_project_20251001_*.json  # Delete old
```

### Resume Fails with State Error

**Problem**: Checkpoint loads but state restoration fails

**Solutions**:
1. View checkpoint details: choose (v) option
2. Check if referenced files exist (plan_path, artifacts)
3. If incompatible, start fresh: choose (s) option
4. Report issue if persists

### Checkpoint Cleanup Not Working

**Problem**: Old checkpoints accumulating

**Solutions**:
```bash
# Manual cleanup
.claude/utils/cleanup-checkpoints.sh 7  # Clean >7 days

# Check cleanup policy
cat .claude/utils/cleanup-checkpoints.sh | grep MAX_AGE_DAYS

# Force delete all
rm .claude/checkpoints/*.json
```

## Best Practices

### When to Resume
- Interrupted workflows (process killed, system restart)
- Long-running workflows with multiple phases
- When workflow requirements haven't changed

### When to Start Fresh
- Workflow description changed significantly
- Checkpoint is very old (>1 week)
- Requirements or goals changed
- Previous approach was incorrect

### Checkpoint Hygiene
1. **Let workflows complete**: Auto-cleanup works on success
2. **Review failures**: Check `failed/` directory for patterns
3. **Clean periodically**: Run cleanup utility monthly
4. **Descriptive names**: Use clear workflow descriptions

### Security Considerations
- Checkpoints may contain sensitive workflow data
- Stored in project directory (not synced by default)
- Add `checkpoints/` to `.gitignore` (already configured)
- Clean before sharing project

## Integration with Other Features

### With Artifact System
- Checkpoints preserve `artifact_registry` state
- Artifact references restored on resume
- No need to re-read artifacts

### With Error Analysis
- Last error captured in checkpoint
- Error context available after resume
- Failed checkpoints archived for debugging

### With Agent Tracking
- Agent metrics continue across resume
- No duplicate invocation counts
- Performance tracking preserved

## Limitations

- Checkpoints are local (not synced across machines)
- Long-running agent executions not interruptible mid-execution
- Checkpoint format may change (version field for migration)
- Very large workflow states may take time to save/load

## Navigation

- [← Documentation Index](README.md)
- [Error Enhancement Guide](error-enhancement-guide.md)
- [Checkpoints Directory](../checkpoints/README.md)
- [Troubleshooting Guide](troubleshooting.md)
