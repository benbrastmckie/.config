# Checkpoints Directory

Workflow checkpoints for interrupted operation recovery.

## Purpose

This directory stores checkpoint files that enable resuming workflows after interruptions. Checkpoints capture workflow state at key milestones, allowing seamless recovery from process termination, errors, or manual stops.

## Checkpoint Format

Checkpoints are JSON files with the following structure:

```json
{
  "checkpoint_id": "orchestrate_auth_system_20251003_184530",
  "workflow_type": "orchestrate",
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

## Checkpoint ID Format

`{workflow_type}_{project_name}_{timestamp}`

- **workflow_type**: `orchestrate`, `implement`, `test-all`
- **project_name**: Snake-case project identifier
- **timestamp**: `YYYYMMDD_HHMMSS` in UTC

Examples:
- `orchestrate_auth_system_20251003_184530.json`
- `implement_dark_mode_20251003_192230.json`

## Directory Structure

```
checkpoints/
├── README.md                           # This file
├── orchestrate_project_date_time.json  # Active checkpoints
├── implement_feature_date_time.json
└── failed/                             # Archived failed workflows
    └── orchestrate_broken_date_time.json
```

## Checkpoint Lifecycle

### 1. Creation
Checkpoints are created when:
- `/orchestrate` starts a multi-phase workflow
- `/implement` begins executing a plan
- Any long-running workflow reaches a milestone

### 2. Updates
Checkpoints are updated when:
- A phase completes successfully
- Workflow state changes
- Progress is made

### 3. Deletion
Checkpoints are deleted when:
- Workflow completes successfully
- User explicitly deletes checkpoint
- Checkpoint age exceeds cleanup threshold (7 days default)

### 4. Archival
Checkpoints are moved to `failed/` when:
- Workflow fails with unrecoverable error
- User abandons workflow and starts fresh
- Manual archival requested

## Cleanup Policy

### Automatic Cleanup
- **Success**: Checkpoint deleted immediately on workflow completion
- **Age-based**: Checkpoints older than 7 days are auto-deleted
- **Failure**: Moved to `failed/` subdirectory, kept for 30 days

### Manual Cleanup
```bash
# List all checkpoints
ls -la .claude/checkpoints/*.json

# Delete specific checkpoint
rm .claude/checkpoints/orchestrate_old_project_*.json

# Clean all checkpoints (use with caution)
rm .claude/checkpoints/*.json

# Archive checkpoint manually
mv .claude/checkpoints/checkpoint.json .claude/checkpoints/failed/
```

## Resume Workflow

When a workflow command detects an existing checkpoint:

1. **Detection**: Command checks for checkpoint matching workflow description
2. **Prompt**: Interactive prompt offers resume options:
   - `(r)esume` - Continue from last checkpoint
   - `(s)tart fresh` - Delete checkpoint and start over
   - `(v)iew details` - Show checkpoint contents
   - `(d)elete` - Remove checkpoint without starting
3. **Validation**: Checkpoint integrity checked before resume
4. **Restoration**: Workflow state restored from checkpoint
5. **Continuation**: Workflow resumes from last completed phase

## Example Resume Prompt

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

## Checkpoint Utilities

### Save Checkpoint
```bash
.claude/utils/save-checkpoint.sh <workflow-type> <state-json>
```

### Load Checkpoint
```bash
.claude/utils/load-checkpoint.sh <workflow-type> [project-name]
```

### List Checkpoints
```bash
.claude/utils/list-checkpoints.sh [workflow-type]
```

### Cleanup Old Checkpoints
```bash
.claude/utils/cleanup-checkpoints.sh [max-age-days]
```

## Error Handling

### Corrupted Checkpoints
If a checkpoint file is corrupted:
1. Error message displayed with checkpoint path
2. Option to delete corrupted checkpoint
3. Workflow can start fresh

### Missing State Data
If checkpoint lacks required state:
1. Validation fails with specific error
2. Checkpoint considered invalid
3. User prompted to delete and restart

### Version Mismatch
If checkpoint format version incompatible:
1. Version mismatch detected
2. Option to attempt migration (future feature)
3. Fallback: delete and restart

## Troubleshooting

### Checkpoint Not Detected
- **Check filename format**: Must match `{type}_{project}_{timestamp}.json`
- **Check file permissions**: Must be readable
- **Check JSON validity**: Use `jq` to validate

### Resume Fails
- **Check workflow state**: Ensure all referenced files exist
- **Check compatibility**: Verify checkpoint schema version
- **Try viewing details**: Use `(v)iew` option to inspect checkpoint

### Multiple Checkpoints
- **Latest used**: Most recent checkpoint for workflow type
- **Clean old ones**: Remove outdated checkpoints manually
- **Descriptive names**: Use clear project names to differentiate

## Best Practices

1. **Let workflows complete**: Checkpoint cleanup is automatic on success
2. **Review failures**: Check `failed/` directory to understand errors
3. **Clean periodically**: Remove old checkpoints if accumulating
4. **Descriptive workflows**: Use clear descriptions for better checkpoint matching
5. **Don't edit manually**: Checkpoints are machine-generated, editing risks corruption

## Security Considerations

- Checkpoints may contain sensitive workflow data
- Store in project directory (not synced by default)
- Add `checkpoints/` to `.gitignore` (already configured)
- Clean up checkpoints when sharing project

## Future Enhancements

- Checkpoint compression for large states
- Remote checkpoint storage (cloud sync)
- Checkpoint diffing (compare states)
- Checkpoint versioning and migration
- Web UI for checkpoint management

## Navigation

- [← Parent Directory](../README.md)
- [Commands](../commands/README.md) - Commands using checkpoints
- [Docs](../docs/README.md) - Checkpointing guides
