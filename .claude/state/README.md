# State Directory

Workflow state files for Claude Code session management, enabling resumption of interrupted work and tracking of ongoing processes.

## Purpose

The state directory enables:

- **Workflow resumption** after interruptions
- **Progress tracking** for long-running tasks
- **Context preservation** across sessions
- **State queries** for status reporting

## State Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Command Execution                                           │
│ Long-running workflow starts                                │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ State File Creation                                         │
│ Command writes state to .claude/state/workflow.json        │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Interruption or Completion                                  │
│ Workflow pauses or finishes                                 │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ SessionStart Hook                                           │
│ session-start-restore.sh checks for state files            │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ User Notification                                           │
│ Display state files and resumption instructions            │
└─────────────────────────────────────────────────────────────┘
```

## State Files

### File Naming
State files use descriptive names indicating their purpose:

```
workflow-name.json           Generic workflow state
last-completion.json         Last command completion details
implement-phase-3.json       Specific phase state
orchestrate-progress.json    Orchestration progress
```

### JSON Format
State files are JSON for easy parsing:

```json
{
  "workflow": "implement",
  "plan_file": "specs/plans/007_dark_mode.md",
  "current_phase": 3,
  "total_phases": 5,
  "phase_status": "in_progress",
  "started_at": "2025-10-01T12:34:56Z",
  "last_update": "2025-10-01T13:15:22Z",
  "next_steps": [
    "Complete phase 3 implementation",
    "Run tests for phase 3",
    "Commit phase 3 changes"
  ],
  "context": {
    "files_modified": ["src/settings.lua", "src/theme.lua"],
    "tests_passed": 15,
    "tests_failed": 2
  }
}
```

### Common Fields

- **workflow**: Command or workflow name
- **current_phase**: Current step/phase number
- **total_phases**: Total steps/phases
- **status**: Status (in_progress, paused, completed, error)
- **started_at**: ISO 8601 timestamp of start
- **last_update**: ISO 8601 timestamp of last update
- **next_steps**: Array of upcoming actions
- **context**: Workflow-specific context data

## State File Usage

### Writing State
Commands write state to track progress:

```bash
#!/usr/bin/env bash
# Example: Writing state from a command

STATE_DIR="$CLAUDE_PROJECT_DIR/.claude/state"
STATE_FILE="$STATE_DIR/implement-phase-${PHASE}.json"

# Ensure directory exists
mkdir -p "$STATE_DIR"

# Create state object
STATE=$(cat <<EOF
{
  "workflow": "implement",
  "plan_file": "$PLAN_FILE",
  "current_phase": $PHASE,
  "total_phases": $TOTAL_PHASES,
  "phase_status": "in_progress",
  "started_at": "$(date -Iseconds)",
  "last_update": "$(date -Iseconds)",
  "next_steps": [
    "Run tests for phase $PHASE",
    "Commit phase $PHASE changes"
  ]
}
EOF
)

# Write atomically
echo "$STATE" > "$STATE_FILE.tmp"
mv "$STATE_FILE.tmp" "$STATE_FILE"
```

### Reading State
Hooks and commands read state to restore context:

```bash
#!/usr/bin/env bash
# Example: Reading state

STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/state/implement-phase-3.json"

if [[ -f "$STATE_FILE" ]]; then
  # Parse with jq
  WORKFLOW=$(jq -r '.workflow' "$STATE_FILE")
  CURRENT_PHASE=$(jq -r '.current_phase' "$STATE_FILE")
  NEXT_STEPS=$(jq -r '.next_steps[]' "$STATE_FILE")

  echo "Resuming $WORKFLOW at phase $CURRENT_PHASE"
  echo "Next steps:"
  echo "$NEXT_STEPS"
fi
```

### Updating State
Commands update state as work progresses:

```bash
#!/usr/bin/env bash
# Example: Updating existing state

STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/state/workflow.json"

# Read current state
CURRENT_STATE=$(cat "$STATE_FILE")

# Update fields
UPDATED_STATE=$(echo "$CURRENT_STATE" | jq \
  --arg phase "$NEW_PHASE" \
  --arg update "$(date -Iseconds)" \
  '.current_phase = ($phase | tonumber) | .last_update = $update'
)

# Write back atomically
echo "$UPDATED_STATE" > "$STATE_FILE.tmp"
mv "$STATE_FILE.tmp" "$STATE_FILE"
```

### Cleanup State
Remove state when workflow completes or is abandoned:

```bash
#!/usr/bin/env bash
# Example: Cleaning up completed state

STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/state/workflow.json"

# Remove when done
rm -f "$STATE_FILE"

# Or archive if keeping history
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/state/archive"
mv "$STATE_FILE" "$CLAUDE_PROJECT_DIR/.claude/state/archive/workflow-$(date +%Y%m%d-%H%M%S).json"
```

## Session Start Detection

### session-start-restore.sh Hook
Automatically checks for state on session start:

**Behavior**:
1. Checks if `.claude/state/` directory exists
2. Finds all `*.json` state files
3. If state files found, displays message:
   ```
   ┌─────────────────────────────────────────────────────────┐
   │ Workflow State Detected                                 │
   ├─────────────────────────────────────────────────────────┤
   │ Found 2 interrupted workflow(s) in .claude/state/       │
   │                                                         │
   │ To resume a workflow, review the state files:          │
   │   ls -la .claude/state/                                 │
   │                                                         │
   │ State files contain context for resuming work.         │
   └─────────────────────────────────────────────────────────┘
   ```
4. Lists state files with modification times
5. Exits (non-blocking)

**Use Case**: Know about interrupted work when starting a session

## State File Examples

### Implementation Progress
```json
{
  "workflow": "implement",
  "plan_file": "specs/plans/007_dark_mode.md",
  "current_phase": 3,
  "total_phases": 5,
  "phase_status": "in_progress",
  "started_at": "2025-10-01T12:34:56Z",
  "last_update": "2025-10-01T13:15:22Z",
  "phases_completed": [1, 2],
  "phases_pending": [4, 5],
  "next_steps": [
    "Implement dark mode toggle component",
    "Add state management for theme",
    "Run tests for phase 3"
  ],
  "files_modified": [
    "src/settings.lua",
    "src/theme.lua"
  ]
}
```

### Orchestration Progress
```json
{
  "workflow": "orchestrate",
  "description": "Implement authentication system",
  "agents_total": 4,
  "agents_completed": 2,
  "agents_in_progress": 1,
  "agents_pending": 1,
  "started_at": "2025-10-01T10:00:00Z",
  "last_update": "2025-10-01T11:30:00Z",
  "agents": [
    {
      "name": "plan-architect",
      "status": "completed",
      "started": "2025-10-01T10:00:00Z",
      "completed": "2025-10-01T10:30:00Z"
    },
    {
      "name": "code-writer",
      "status": "completed",
      "started": "2025-10-01T10:30:00Z",
      "completed": "2025-10-01T11:15:00Z"
    },
    {
      "name": "test-specialist",
      "status": "in_progress",
      "started": "2025-10-01T11:15:00Z"
    },
    {
      "name": "doc-writer",
      "status": "pending"
    }
  ]
}
```

### Last Completion
```json
{
  "command": "implement",
  "status": "success",
  "duration_ms": 45231,
  "completed_at": "2025-10-01T13:45:12Z",
  "summary": "Implemented dark mode toggle in settings",
  "phases_completed": 5,
  "tests_passed": 23,
  "files_modified": 8,
  "commits_created": 5
}
```

## Best Practices

### Atomic Writes
Always write to temporary file then move:

```bash
# Write to temp file
echo "$STATE" > "$STATE_FILE.tmp"

# Atomic move
mv "$STATE_FILE.tmp" "$STATE_FILE"
```

### Timestamp Everything
Include timestamps for debugging:

```bash
"started_at": "$(date -Iseconds)"
"last_update": "$(date -Iseconds)"
```

### Validate JSON
Ensure valid JSON before writing:

```bash
if echo "$STATE" | jq empty 2>/dev/null; then
  echo "$STATE" > "$STATE_FILE"
else
  echo "Invalid JSON, not writing state"
fi
```

### Cleanup Old State
Remove or archive completed state:

```bash
# On successful completion
rm -f "$STATE_FILE"

# Or archive for history
mv "$STATE_FILE" "$STATE_DIR/archive/$(basename "$STATE_FILE" .json)-$(date +%Y%m%d).json"
```

### Include Next Steps
Always document what to do next:

```json
"next_steps": [
  "Complete phase 4 implementation",
  "Run full test suite",
  "Update documentation"
]
```

## Querying State

### List All State
```bash
ls -lh .claude/state/*.json
```

### Show State Summary
```bash
for file in .claude/state/*.json; do
  echo "=== $(basename "$file") ==="
  jq -r '"\(.workflow) - Phase \(.current_phase)/\(.total_phases) - \(.phase_status)"' "$file"
  echo ""
done
```

### Check Specific Workflow
```bash
jq . .claude/state/implement-phase-3.json
```

### Find Interrupted Work
```bash
jq -r 'select(.phase_status == "in_progress") | "\(.workflow) - \(.current_phase)/\(.total_phases)"' .claude/state/*.json
```

## Maintenance

### Archive Old State
```bash
# Create archive directory
mkdir -p .claude/state/archive

# Move state files older than 7 days
find .claude/state -maxdepth 1 -name "*.json" -mtime +7 -exec mv {} .claude/state/archive/ \;
```

### Cleanup Archive
```bash
# Remove archived state older than 90 days
find .claude/state/archive -name "*.json" -mtime +90 -delete
```

### Validate State Files
```bash
# Check all state files are valid JSON
for file in .claude/state/*.json; do
  if ! jq empty "$file" 2>/dev/null; then
    echo "Invalid JSON: $file"
  fi
done
```

## Privacy and Security

### Data Stored
State files may contain:
- Workflow names and descriptions
- File paths being worked on
- Phase/step information
- Timestamps

State files should NOT contain:
- File contents
- Secrets or credentials
- User input verbatim
- Personal information

### Access Control
State files inherit permissions from `.claude/` directory.

Ensure appropriate permissions:
```bash
chmod 700 .claude/state
chmod 600 .claude/state/*.json
```

## Documentation Standards

All state documentation follows standards:

- **NO emojis** in file content
- **Unicode box-drawing** for diagrams
- **Clear examples** with syntax highlighting
- **CommonMark** specification

See [/home/benjamin/.config/nvim/docs/GUIDELINES.md](../../nvim/docs/GUIDELINES.md) for complete standards.

## Navigation

### Related
- [← Parent Directory](../README.md)
- [hooks/](../hooks/README.md) - Session start restore hook
- [commands/](../commands/README.md) - Commands that use state

## Quick Reference

### Create State Directory
```bash
mkdir -p .claude/state
```

### Write State
```bash
echo '{"workflow":"test","phase":1}' > .claude/state/workflow.json.tmp
mv .claude/state/workflow.json.tmp .claude/state/workflow.json
```

### Read State
```bash
jq . .claude/state/workflow.json
```

### List State
```bash
ls -lh .claude/state/*.json
```

### Cleanup
```bash
rm -f .claude/state/*.json
```

## Example Workflow

### 1. Command Starts
```bash
# /implement starts, writes initial state
echo '{"workflow":"implement","current_phase":1,"total_phases":5}' > \
  .claude/state/implement.json
```

### 2. Progress Updates
```bash
# Phase 2 starts
jq '.current_phase = 2' .claude/state/implement.json > \
  .claude/state/implement.json.tmp
mv .claude/state/implement.json.tmp .claude/state/implement.json
```

### 3. Interruption
```bash
# Session ends, state preserved
# On next session start, hook displays:
# "Found 1 interrupted workflow in .claude/state/"
```

### 4. Resumption
```bash
# User reads state
jq . .claude/state/implement.json

# User resumes
/resume-implement

# Command reads state, continues from phase 2
```

### 5. Completion
```bash
# Workflow completes, cleanup state
rm .claude/state/implement.json
```
