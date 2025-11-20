# Data Management Guide

## Purpose

Comprehensive guide to the `.claude/data/` directory ecosystem: checkpoints, logs, metrics, and registry. This guide provides centralized documentation for understanding how Claude Code persists runtime data, tracks workflow state, logs system operations, and manages artifact metadata.

## Navigation

- [← Guides Index](README.md)
- [Documentation Index](../README.md)
- [Data Directory](../../data/README.md)

## Overview

The `.claude/data/` directory contains runtime-generated data that is gitignored to prevent sensitive or ephemeral data from entering version control. It provides four key capabilities:

1. **Checkpoints**: Workflow state persistence for resumption after interruptions
2. **Logs**: Runtime debugging and system operation tracing
3. **Metrics**: Command performance tracking and usage analysis
4. **Registry**: Artifact metadata tracking and agent registry management

All subdirectories are gitignored and contain local-only runtime data.

## Directory Structure

```
data/
├── README.md           Overview and maintenance procedures
├── checkpoints/        Workflow state for resumption
│   ├── README.md      Checkpoint documentation
│   └── *.json         Active checkpoint files
├── logs/               Runtime logs and debug output
│   ├── README.md      Logging documentation
│   └── *.log          Log files (hook-debug, tts, adaptive-planning, etc.)
├── metrics/            Command performance tracking
│   ├── README.md      Metrics documentation
│   └── YYYY-MM.jsonl  Monthly metrics files
└── registry/           Artifact metadata tracking
    ├── README.md      Registry documentation
    └── *.json         Artifact and agent registry files
```

See [data/README.md](../../data/README.md) for complete directory overview.

## Checkpoints

### Purpose

Checkpoints enable workflow interruption recovery by saving implementation progress at phase boundaries. When a workflow is interrupted (process termination, error, manual stop), checkpoints allow seamless resumption from the last completed phase.

### Which Commands Create Checkpoints

- `/orchestrate` - Multi-phase workflow coordination
- `/implement` - Implementation plan execution
- Any long-running workflow with multiple phases

### Checkpoint Format

Checkpoints are JSON files with workflow state:

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

**Checkpoint ID Format**: `{workflow_type}_{project_name}_{timestamp}`

### Auto-Resume

When you run a command that supports checkpoints:

1. **Detection**: Command checks for existing checkpoint matching workflow description
2. **Interactive Prompt**: Offers resume options:
   - `(r)esume` - Continue from last checkpoint
   - `(s)tart fresh` - Delete checkpoint and start over
   - `(v)iew details` - Show checkpoint contents
   - `(d)elete` - Remove checkpoint without starting
3. **Validation**: Checkpoint integrity checked before resume
4. **Restoration**: Workflow state restored from checkpoint
5. **Continuation**: Workflow resumes from last completed phase

Example prompt:
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

### Checkpoint Lifecycle

1. **Creation**: Workflow starts, checkpoint created
2. **Updates**: Checkpoint updated after each phase completion
3. **Deletion**: Checkpoint deleted on workflow success
4. **Archival**: Moved to `failed/` subdirectory on unrecoverable error

### Cleanup Policy

- **Success**: Checkpoint deleted immediately on workflow completion
- **Age-based**: Checkpoints older than 7 days are auto-deleted
- **Failure**: Moved to `failed/` subdirectory, kept for 30 days

### Manual Checkpoint Management

```bash
# List all checkpoints
ls -la .claude/data/checkpoints/*.json

# Delete specific checkpoint
rm .claude/data/checkpoints/orchestrate_old_project_*.json

# Clean all checkpoints (use with caution)
rm .claude/data/checkpoints/*.json

# Archive checkpoint manually
mv .claude/data/checkpoints/checkpoint.json .claude/data/checkpoints/failed/
```

### Troubleshooting

**Checkpoint Not Detected**:
- Check filename format: Must match `{type}_{project}_{timestamp}.json`
- Check file permissions: Must be readable
- Check JSON validity: Use `jq` to validate

**Resume Fails**:
- Check workflow state: Ensure all referenced files exist
- Check compatibility: Verify checkpoint schema version
- Try viewing details: Use `(v)iew` option to inspect checkpoint

**See Also**: [Adaptive Planning Guide](../workflows/adaptive-planning-guide.md), [Checkpoint Template Guide](../workflows/checkpoint_template_guide.md), [data/checkpoints/README.md](../../data/checkpoints/README.md)

## Logs

### Purpose

Runtime logs provide debugging, monitoring, and audit trail capabilities for hooks, TTS system, and workflow operations.

### Log Files

#### hook-debug.log
**Purpose**: Trace hook execution with event details

**Written By**: `hooks/tts-dispatcher.sh` and other hooks

**Format**:
```
[2025-10-01T12:34:56+00:00] Hook called: EVENT=Stop CMD=/implement STATUS=success
[2025-10-01T12:35:23+00:00] Hook called: EVENT=Stop CMD=/test STATUS=success
```

**Use Cases**:
- Verify hooks are being triggered
- Check event type detection
- Debug hook registration issues
- Trace execution flow

**Viewing**:
```bash
# Show recent hook calls
tail .claude/data/logs/hook-debug.log

# Follow in real-time
tail -f .claude/data/logs/hook-debug.log

# Filter by event type
grep "EVENT=Stop" .claude/data/logs/hook-debug.log
```

#### tts.log
**Purpose**: TTS invocation history for notification troubleshooting

**Written By**: `hooks/tts-dispatcher.sh`

**Enabled**: When `TTS_DEBUG=true` in `tts/tts-config.sh`

**Format**:
```
[2025-10-01T12:34:56+00:00] [Stop] config, master (pitch:50 speed:160)
[2025-10-01T12:36:44+00:00] [SubagentStop] Progress update. code writer complete. (pitch:40 speed:180)
```

**Use Cases**:
- Verify TTS is being invoked
- Check message content
- Debug voice parameter issues
- Monitor notification frequency

#### adaptive-planning.log
**Purpose**: Adaptive planning replan event logging

**Written By**: `.claude/lib/core/unified-logger.sh`

**Format**: Structured logging of complexity detection, replan triggers, and plan updates

**Use Cases**:
- Track automatic plan revisions during `/implement`
- Debug complexity threshold triggers
- Audit replan history and loop prevention
- Analyze adaptive planning effectiveness

**Viewing**:
```bash
# Show recent adaptive planning events
tail .claude/data/logs/adaptive-planning.log

# Query replan events
grep "REPLAN_TRIGGERED" .claude/data/logs/adaptive-planning.log
```

#### Advanced Log Files

The following log files provide detailed tracking for hierarchical agent workflows and user interactions:

**approval-decisions.log**
- **Purpose**: User approval tracking for command execution
- **Use Cases**: Audit trail of approved/denied operations
- **Integration**: Hook-driven approval system

**phase-handoffs.log**
- **Purpose**: Agent coordination logs for phase transitions
- **Use Cases**: Debug multi-phase workflow coordination
- **Integration**: `/orchestrate` and `/implement` workflows

**supervision-tree.log**
- **Purpose**: Hierarchical agent structure visualization
- **Use Cases**: Track supervisor-subagent relationships, debug recursive supervision
- **Integration**: Hierarchical agent system (max depth: 3)

**subagent-outputs.log**
- **Purpose**: Subagent response logs for context management
- **Use Cases**: Debug subagent delegation, verify metadata extraction
- **Integration**: Context pruning and forward message patterns

### Log Management

#### Viewing Logs
```bash
# Recent events from any log
tail .claude/data/logs/hook-debug.log
tail .claude/data/logs/tts.log
tail .claude/data/logs/adaptive-planning.log

# Follow logs in real-time
tail -f .claude/data/logs/hook-debug.log

# Search across all logs
grep "ERROR" .claude/data/logs/*.log
```

#### Log Rotation
Logs do NOT auto-rotate. Manual cleanup recommended:

```bash
# Archive old logs monthly
mkdir -p .claude/data/logs/archive
mv .claude/data/logs/hook-debug.log .claude/data/logs/archive/hook-debug-$(date +%Y-%m).log
mv .claude/data/logs/tts.log .claude/data/logs/archive/tts-$(date +%Y-%m).log

# Clear logs (keeps files)
> .claude/data/logs/hook-debug.log
> .claude/data/logs/tts.log
```

#### Log Analysis
```bash
# Event frequency (events per hour)
cat .claude/data/logs/hook-debug.log | cut -d']' -f1 | cut -d'T' -f2 | cut -d':' -f1 | sort | uniq -c

# TTS notifications per category
grep -o "\[[^]]*\]" .claude/data/logs/tts.log | sort | uniq -c

# Find error patterns
grep -i "error\|fail\|exception" .claude/data/logs/*.log
```

### Troubleshooting

**Hook Not Running**:
1. Check hook registration: `cat .claude/settings.local.json | jq '.hooks'`
2. Verify hook executable: `ls -l .claude/hooks/*.sh`
3. Test hook manually: `echo '{"hook_event_name":"Stop"}' | .claude/hooks/your-hook.sh`

**TTS Not Working**:
1. Enable TTS debug: `grep "TTS_DEBUG" .claude/tts/tts-config.sh` (should be `true`)
2. Check TTS enabled: `grep "TTS_ENABLED" .claude/tts/tts-config.sh` (should be `true`)
3. Verify category enabled: `grep "TTS_COMPLETION_ENABLED" .claude/tts/tts-config.sh`
4. Check logs: `tail .claude/data/logs/tts.log`
5. Test espeak-ng: `espeak-ng "Test message"`

**See Also**: [Orchestration Guide](../workflows/orchestration-guide.md), [Hierarchical Agents](../concepts/hierarchical-agents.md), [TTS Integration Guide](../workflows/tts-integration-guide.md), [data/logs/README.md](../../data/logs/README.md)

## Metrics

### Purpose

Automated command execution performance tracking for usage analysis, optimization, and reliability monitoring.

### Which Commands Write Metrics

All commands automatically write metrics via the `post-command-metrics.sh` hook registered on the Stop event.

### Metrics Format

**File Naming**: `YYYY-MM.jsonl` (e.g., `2025-10.jsonl` for October 2025)

**JSONL Format** (one JSON object per line):
```json
{"timestamp":"2025-10-01T12:34:56Z","operation":"implement","duration_ms":15234,"status":"success"}
{"timestamp":"2025-10-01T12:45:23Z","operation":"test","duration_ms":3421,"status":"success"}
{"timestamp":"2025-10-01T13:02:17Z","operation":"plan","duration_ms":8932,"status":"success"}
```

**Fields**:
- `timestamp`: ISO 8601 UTC timestamp of command completion
- `operation`: Command name (without leading slash)
- `duration_ms`: Execution duration in milliseconds
- `status`: Command result ("success" or "error")

### Metrics Collection

Metrics are collected automatically:

1. Hook receives JSON input from Claude Code on Stop event
2. Extracts command, duration, and status
3. Generates UTC timestamp
4. Normalizes command name (removes leading slash)
5. Creates JSONL entry
6. Appends to current month's metrics file
7. Always exits 0 (non-blocking)

**Monthly Rotation**: Automatic - October data goes to `2025-10.jsonl`, November to `2025-11.jsonl`

### Analyzing Metrics

```bash
# View current month
cat .claude/data/metrics/$(date +%Y-%m).jsonl | jq

# Count commands by operation
cat .claude/data/metrics/*.jsonl | jq -r '.operation' | sort | uniq -c | sort -rn

# Average duration per operation
cat .claude/data/metrics/*.jsonl | jq -s '
  group_by(.operation) |
  map({
    operation: .[0].operation,
    count: length,
    avg_ms: (map(.duration_ms) | add / length | floor)
  }) | sort_by(-.count)
'

# Success rate by operation
cat .claude/data/metrics/*.jsonl | jq -s '
  group_by(.operation) |
  map({
    operation: .[0].operation,
    total: length,
    success_rate: ((map(select(.status == "success")) | length) / length * 100 | floor)
  })
'

# Find slowest command executions
cat .claude/data/metrics/*.jsonl | jq -s 'sort_by(-.duration_ms) | .[0:10]'

# Show all errors
cat .claude/data/metrics/*.jsonl | jq 'select(.status == "error")'
```

### Optimization Use Cases

**Identify Slow Commands** (averaging over 10 seconds):
```bash
cat .claude/data/metrics/*.jsonl | jq -s '
  group_by(.operation) |
  map({
    operation: .[0].operation,
    avg_ms: (map(.duration_ms) | add / length)
  }) | map(select(.avg_ms > 10000))
'
```

**Find Failing Commands** (>10% error rate):
```bash
cat .claude/data/metrics/*.jsonl | jq -s '
  group_by(.operation) |
  map({
    operation: .[0].operation,
    error_rate: ((map(select(.status == "error")) | length) / length * 100)
  }) | map(select(.error_rate > 10))
'
```

**Usage Patterns** (top 5 most used commands):
```bash
cat .claude/data/metrics/*.jsonl | jq -r '.operation' | sort | uniq -c | sort -rn | head -5
```

### Metrics Maintenance

```bash
# Archive old metrics
mkdir -p .claude/data/metrics/archive
mv .claude/data/metrics/2024-*.jsonl .claude/data/metrics/archive/

# Export to CSV
cat .claude/data/metrics/*.jsonl | jq -r '[.timestamp, .operation, .duration_ms, .status] | @csv' > metrics.csv

# Remove metrics older than 6 months
find .claude/data/metrics -name "*.jsonl" -mtime +180 -delete
```

### Privacy

**Metrics contain**:
- Command names (e.g., "implement", "test")
- Timestamps
- Durations
- Success/error status

**Metrics do NOT contain**:
- Command arguments
- File contents
- User input
- File paths
- Error messages

All metrics are stored locally and never transmitted externally.

**See Also**: [data/metrics/README.md](../../data/metrics/README.md)

## Registry

### Purpose

Artifact metadata tracking enables:
- Artifact lifecycle management
- Cross-referencing between artifacts
- Workflow coordination state tracking
- Agent registry management

### Which Utilities Write Registry Files

- `.claude/lib/workflow/metadata-extraction.sh` - Unified artifact management
- `/orchestrate` - Workflow coordination
- `/implement` - Implementation tracking
- Various commands creating trackable artifacts

### Registry File Types

#### Artifact Metadata
Individual JSON files tracking created artifacts:

```json
{
  "id": "artifact_001",
  "path": "specs/reports/001_analysis.md",
  "type": "research_report",
  "created": "2025-10-16T12:00:00Z",
  "workflow": "orchestrate_feature_xyz",
  "status": "complete"
}
```

#### Agent Registry
`agent-registry.json` - Central registry of available agents:

```json
{
  "agents": [
    {
      "name": "research-specialist",
      "role": "Research and analysis",
      "tools": ["Read", "Grep", "Glob", "WebSearch"],
      "status": "active"
    }
  ]
}
```

### Integration Patterns with Hierarchical Agents

The registry system integrates with hierarchical agents to track:

1. **Subagent Invocations**: Registry tracks which subagents were invoked, their inputs, and metadata-only outputs
2. **Artifact Paths**: Forward message pattern uses registry to pass artifact references (not full content)
3. **Supervision Depth**: Registry tracks supervision tree depth to prevent infinite recursion (max depth: 3)
4. **Context Pruning**: Registry metadata enables aggressive cleanup of completed phase data

Example workflow:
1. `/orchestrate` invokes research-specialist subagent
2. Subagent creates report at `specs/reports/053_analysis.md`
3. Registry file created: `outputs_001_research_20251016_120000.json`
4. Parent receives metadata: `{path: "specs/reports/053_analysis.md", summary: "50-word summary"}`
5. Context reduction: 5000 tokens → 250 tokens (95% reduction)

### Registry Inspection

```bash
# List all registered artifacts
ls -lh .claude/data/registry/*.json

# View specific artifact metadata
cat .claude/data/registry/artifact_001.json | jq .

# Find artifacts by type
grep -l '"type":"research_report"' .claude/data/registry/*.json
```

### Registry Cleanup

```bash
# Remove all registry files (reset tracking)
rm .claude/data/registry/*.json

# Remove specific artifact metadata
rm .claude/data/registry/artifact_*.json

# Remove old registry files (>30 days)
find .claude/data/registry -name "*.json" -mtime +30 -delete
```

**See Also**: [Hierarchical Agents Guide](../concepts/hierarchical-agents.md), [Orchestration Guide](../workflows/orchestration-guide.md), [data/registry/README.md](../../data/registry/README.md)

## Integration Workflows

### Commands That Use data/

| Command | Checkpoints | Logs | Metrics | Registry |
|---------|-------------|------|---------|----------|
| /orchestrate | ✓ | via hooks | ✓ | ✓ |
| /implement | ✓ | via hooks | ✓ | ✓ |
| /plan | - | - | ✓ | ✓ |
| /report | - | - | ✓ | ✓ |
| /debug | - | - | ✓ | ✓ |
| /test-all | - | via hooks | ✓ | - |
| All commands | - | via hooks | ✓ | - |

### Hooks That Use data/

| Hook | Logs | Metrics | Purpose |
|------|------|---------|---------|
| post-command-metrics.sh | - | ✓ | Performance tracking |
| tts-dispatcher.sh | ✓ | - | TTS logging and hook debugging |
| user-prompt-submit.sh | ✓ | - | Approval decision logging |

### Artifact Lifecycle

1. **Creation**: Command creates artifact (report, plan, debug doc)
2. **Registration**: `metadata-extraction.sh` creates registry entry
3. **Usage**: Other commands reference artifact via registry metadata
4. **Completion**: Workflow completes, artifact status updated
5. **Cleanup**: Registry entry persists until manual cleanup or project reset

## Maintenance

### Consolidated Cleanup Procedures

```bash
# Clean all data/ subdirectories
.claude/lib/cleanup-data.sh

# Or clean individually:

# Checkpoints (>7 days)
find .claude/data/checkpoints -name "*.json" -mtime +7 -delete

# Logs (archive monthly)
mkdir -p .claude/data/logs/archive
mv .claude/data/logs/*.log .claude/data/logs/archive/

# Metrics (>6 months)
find .claude/data/metrics -name "*.jsonl" -mtime +180 -delete

# Registry (>30 days)
find .claude/data/registry -name "*.json" -mtime +30 -delete
```

### Backup Recommendations

```bash
# Backup important checkpoints before cleanup
cp -r .claude/data/checkpoints ~/backup/checkpoints-$(date +%Y%m%d)

# Archive metrics for analysis
tar -czf ~/backup/metrics-$(date +%Y%m%d).tar.gz .claude/data/metrics/

# Backup registry for workflow recovery
cp -r .claude/data/registry ~/backup/registry-$(date +%Y%m%d)
```

### Privacy Considerations

All data/ contents:
- Stay local (never transmitted)
- Are gitignored (`.gitignore` includes `.claude/data/`)
- Contain project-specific data only
- Should be cleaned before sharing projects

Sensitive data locations:
- Checkpoint state may contain workflow descriptions
- Logs may contain command names and events
- Metrics contain command execution data (no arguments)
- Registry contains artifact paths

## Quick Reference

### Common Data Operations

```bash
# Check checkpoint status
ls -lh .claude/data/checkpoints/*.json

# View recent logs
tail .claude/data/logs/hook-debug.log
tail .claude/data/logs/tts.log

# Analyze metrics
cat .claude/data/metrics/$(date +%Y-%m).jsonl | jq

# Inspect registry
ls .claude/data/registry/*.json
```

### Troubleshooting Data Issues

**No checkpoints being created**:
- Check workflow supports checkpoints (`/orchestrate`, `/implement`)
- Verify `.claude/data/checkpoints/` directory exists and is writable

**Logs not updating**:
- Check hook registration: `cat .claude/settings.local.json | jq '.hooks'`
- Verify hook executability: `ls -l .claude/hooks/*.sh`

**Metrics not collecting**:
- Check hook registered: `cat .claude/settings.local.json | jq '.hooks.Stop'`
- Test manually: `echo '{"hook_event_name":"Stop","command":"/test","duration_ms":1000,"status":"success"}' | .claude/hooks/post-command-metrics.sh`

**Registry files accumulating**:
- Normal behavior - registry persists until manual cleanup
- Clean old entries: `find .claude/data/registry -name "*.json" -mtime +30 -delete`

## Related Documentation

### Workflows
- [Orchestration Guide](../workflows/orchestration-guide.md) - Multi-agent workflow coordination
- [Adaptive Planning Guide](../workflows/adaptive-planning-guide.md) - Checkpoint and adaptive planning integration
- [Checkpoint Template Guide](../workflows/checkpoint_template_guide.md) - Checkpoint system details

### Concepts
- [Hierarchical Agents](../concepts/hierarchical-agents.md) - Registry integration patterns
- [Development Workflow](../concepts/development-workflow.md) - Artifact lifecycle management

### Data Subdirectories
- [checkpoints/README.md](../../data/checkpoints/README.md) - Checkpoint documentation
- [logs/README.md](../../data/logs/README.md) - Logging documentation
- [metrics/README.md](../../data/metrics/README.md) - Metrics documentation
- [registry/README.md](../../data/registry/README.md) - Registry documentation
- [data/README.md](../../data/README.md) - Data directory overview
