# Essential Workflow Infrastructure Implementation Plan

## Metadata
- **Date**: 2025-10-01
- **Feature**: Essential workflow infrastructure (Performance Monitoring, Persistent State, Enhanced Error Recovery, Notifications)
- **Scope**: Four critical features to move from 70% to 90% workflow completion
- **Estimated Phases**: 6 phases
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: /home/benjamin/.config/.claude/specs/reports/014_claude_directory_implementation_status_and_gaps.md

## Overview

This plan implements four essential features identified as critical gaps in the workflow system:

1. **Performance Monitoring and Optimization** - Track and analyze command performance
2. **Persistent Workflow State Management** - Resume workflows after interruption
3. **Enhanced Error Recovery** - Smart retry strategies and circuit breaker pattern
4. **Notification System** - Alert users on workflow completion/failure

These features transform the workflow system from ephemeral and opaque to persistent, observable, and intelligent. Current implementation is ~70% complete; these additions will push it to ~90%.

## Success Criteria

- [ ] Performance metrics collected for all commands and persisted to disk
- [ ] Workflows can be interrupted and resumed without data loss
- [ ] Error recovery uses intelligent retry with exponential backoff
- [ ] Circuit breaker prevents repeated failures in same operation
- [ ] Users receive OS notifications for workflow events
- [ ] `/metrics` command displays performance analytics
- [ ] `/workflows` command family manages persistent workflows
- [ ] Error pattern database learns from repeated failures
- [ ] All features integrate seamlessly with existing 19 commands

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│ Existing Commands (19)                                  │
│ /orchestrate, /implement, /plan, /report, etc.         │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│ New Infrastructure Layer                                │
├─────────────────────────────────────────────────────────┤
│ • MetricsCollector     → .claude/data/metrics/               │
│ • StateManager         → .claude/state/                 │
│ • ErrorRecovery        → .claude/errors/                │
│ • NotificationService  → OS notification API            │
└─────────────────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│ Storage Layer                                           │
├─────────────────────────────────────────────────────────┤
│ • .claude/data/metrics/*.jsonl  (append-only logs)           │
│ • .claude/state/*.json     (workflow checkpoints)       │
│ • .claude/errors/patterns.json (learned error patterns) │
└─────────────────────────────────────────────────────────┘
```

### Component Design

#### 1. Performance Monitoring

**MetricsCollector Module**:
- Intercepts command execution start/end
- Records: command name, start time, end time, duration, success/failure, context
- Writes to append-only JSONL (JSON Lines) format
- Minimal overhead (<1% command execution time)

**Data Model**:
```json
{
  "timestamp": "2025-10-01T10:30:45.123Z",
  "command": "/orchestrate",
  "duration_ms": 45231,
  "status": "success",
  "phase": "implementation",
  "context": {
    "workflow_id": "wf_12345",
    "phases_completed": 4,
    "parallel_agents": 3
  }
}
```

**Storage**: `.claude/data/metrics/YYYY-MM.jsonl` (monthly rotation)

#### 2. Persistent Workflow State

**StateManager Module**:
- Serializes workflow state at phase boundaries
- Writes to `.claude/state/<workflow_id>.json`
- Detects interruptions (SIGINT, SIGTERM, crash)
- Implements resume logic

**Workflow State Schema**:
```json
{
  "workflow_id": "wf_12345",
  "created_at": "2025-10-01T10:00:00Z",
  "updated_at": "2025-10-01T10:30:00Z",
  "status": "in_progress",
  "command": "/orchestrate",
  "description": "Add user authentication",
  "current_phase": {
    "phase_num": 3,
    "phase_name": "implementation",
    "progress": 67.5
  },
  "completed_phases": ["research", "planning"],
  "checkpoint_data": {
    "research_summary": "...",
    "plan_path": "specs/plans/013_*.md",
    "files_modified": ["auth.lua", "config.lua"]
  },
  "error_history": []
}
```

**Cleanup Policy**: Auto-delete completed workflows after 7 days, failed after 30 days.

#### 3. Enhanced Error Recovery

**ErrorRecovery Module**:
- Wraps operations with retry logic
- Implements exponential backoff with jitter
- Circuit breaker state machine (Closed → Open → Half-Open)
- Error pattern learning

**Retry Strategy**:
```
Attempt 1: Immediate
Attempt 2: Wait 2s + random(0-1s)
Attempt 3: Wait 4s + random(0-2s)
Attempt 4: Wait 8s + random(0-4s)
Max Attempts: 4
```

**Circuit Breaker States**:
- **Closed**: Normal operation, tracking failures
- **Open**: Too many failures (>3 in 5 min), reject immediately for 60s
- **Half-Open**: Test if issue resolved, allow 1 attempt

**Error Pattern Database** (`.claude/errors/patterns.json`):
```json
{
  "patterns": [
    {
      "error_signature": "NetworkTimeout:api.github.com",
      "occurrence_count": 12,
      "first_seen": "2025-09-15T10:00:00Z",
      "last_seen": "2025-10-01T11:00:00Z",
      "recoverable": true,
      "recommended_action": "retry_with_backoff",
      "notes": "GitHub API intermittent issues"
    }
  ]
}
```

#### 4. Notification System

**NotificationService Module**:
- OS-specific notification APIs
- Configurable notification levels (all, errors_only, major_events)
- Non-blocking (fire-and-forget)

**Supported Platforms**:
- **Linux**: `notify-send` (libnotify)
- **macOS**: `osascript` (AppleScript notification center)
- **Windows**: `powershell` (Windows Notification API)

**Notification Events**:
- Workflow completion (success/failure)
- Long-running operation milestones (>5 min, show progress)
- Critical errors
- User-requested notifications (`/orchestrate --notify`)

### Integration with Existing Commands

**Minimal Changes to Existing Commands**:

Each command wraps its main execution:

```lua
-- Pseudocode for command integration
local metrics = require('.claude.lib.metrics')
local state = require('.claude.lib.state')
local notifications = require('.claude.lib.notifications')

function execute_command(args)
  local metric_id = metrics.start('command_name', args)
  local workflow_id = state.create_workflow('command_name', args)

  local success, result = pcall(function()
    -- Existing command logic
    return original_command_execution(args)
  end)

  if success then
    metrics.record_success(metric_id)
    state.complete_workflow(workflow_id)
    notifications.send('Workflow completed', 'success')
  else
    metrics.record_failure(metric_id, result)
    state.fail_workflow(workflow_id, result)
    notifications.send('Workflow failed: ' .. result, 'error')
  end

  return success, result
end
```

**New Commands**:

1. `/metrics [command] [timeframe]` - Display performance analytics
2. `/workflows list` - List active/paused workflows
3. `/workflows resume <id>` - Resume interrupted workflow
4. `/workflows cancel <id>` - Cancel workflow
5. `/workflows clean` - Remove old completed workflows

## Implementation Phases

### Phase 1: Foundation and Directory Structure
**Objective**: Create infrastructure directories and base modules
**Complexity**: Low

Tasks:
- [ ] Create `.claude/data/metrics/` directory
- [ ] Create `.claude/state/` directory
- [ ] Create `.claude/errors/` directory
- [ ] Create `.claude/lib/` directory for shared modules
- [ ] Add `.gitignore` entries for transient state files
- [ ] Create `lib/metrics.lua` stub with interface
- [ ] Create `lib/state.lua` stub with interface
- [ ] Create `lib/error_recovery.lua` stub with interface
- [ ] Create `lib/notifications.lua` stub with interface
- [ ] Update `.claude/settings.local.json` with required permissions

Testing:
```bash
# Verify directories created
ls -la .claude/data/metrics/ .claude/state/ .claude/errors/ .claude/lib/

# Verify modules loadable
lua -e "require('.claude.lib.metrics')"
```

### Phase 2: Performance Monitoring Implementation
**Objective**: Implement metrics collection and `/metrics` command
**Complexity**: Medium

Tasks:
- [ ] Implement `lib/metrics.lua` with JSONL append logic
- [ ] Add timestamp generation (ISO 8601 format)
- [ ] Implement metrics rotation (monthly files)
- [ ] Create `/metrics` command in `commands/metrics.md`
- [ ] Add metrics parsing and aggregation
- [ ] Implement CLI table formatter for metrics display
- [ ] Add filtering by command name
- [ ] Add filtering by timeframe (day, week, month, all)
- [ ] Calculate statistics (avg, p50, p95, p99 duration)
- [ ] Integrate metrics collection into `/orchestrate` command
- [ ] Integrate metrics collection into `/implement` command
- [ ] Test with sample command executions

Testing:
```bash
# Run commands and generate metrics
/orchestrate "test workflow"
/implement specs/plans/001_*.md

# Display metrics
/metrics                     # All commands, last 7 days
/metrics orchestrate         # Specific command
/metrics --timeframe month   # Last month

# Verify JSONL format
cat .claude/data/metrics/2025-10.jsonl | jq .
```

### Phase 3: Persistent Workflow State Management
**Objective**: Implement workflow state persistence and resume capability
**Complexity**: High

Tasks:
- [ ] Implement `lib/state.lua` with JSON serialization
- [ ] Add workflow ID generation (wf_<timestamp>_<random>)
- [ ] Implement checkpoint creation at phase boundaries
- [ ] Add signal handlers for SIGINT/SIGTERM
- [ ] Implement state restoration from JSON
- [ ] Create `/workflows` command family in `commands/workflows.md`
- [ ] Implement `/workflows list` with status table
- [ ] Implement `/workflows resume <id>` with state restoration
- [ ] Implement `/workflows cancel <id>`
- [ ] Implement `/workflows clean` with retention policy (7 days completed, 30 days failed)
- [ ] Integrate state management into `/orchestrate` command
- [ ] Add checkpoint creation after each phase in `/orchestrate`
- [ ] Test interruption and resume (CTRL+C during workflow)
- [ ] Test workflow listing and filtering
- [ ] Test cleanup of old workflows

Testing:
```bash
# Start long-running workflow
/orchestrate "complex feature implementation"

# Interrupt with CTRL+C mid-execution

# List workflows
/workflows list
# Should show: wf_12345 | in_progress | implementation | 2025-10-01 10:30

# Resume
/workflows resume wf_12345
# Should continue from checkpoint

# Clean old workflows
/workflows clean --dry-run
/workflows clean
```

### Phase 4: Enhanced Error Recovery
**Objective**: Implement smart retry and circuit breaker
**Complexity**: High

Tasks:
- [ ] Implement `lib/error_recovery.lua` with retry wrapper
- [ ] Add exponential backoff calculation with jitter
- [ ] Implement circuit breaker state machine
- [ ] Add error classification (transient vs permanent)
- [ ] Create error pattern database schema
- [ ] Implement error pattern learning (signature extraction)
- [ ] Add pattern matching for known errors
- [ ] Implement pattern-based retry decision
- [ ] Create error pattern viewer (CLI table)
- [ ] Integrate error recovery into `/orchestrate` command
- [ ] Integrate error recovery into `/implement` command
- [ ] Wrap subagent invocations with retry logic
- [ ] Test transient error recovery (mock network timeout)
- [ ] Test circuit breaker open state (repeated failures)
- [ ] Test pattern learning (repeat same error multiple times)

Testing:
```bash
# Inject transient error (mock)
CLAUDE_INJECT_ERROR=NetworkTimeout /orchestrate "test workflow"
# Should retry with backoff and succeed on attempt 2

# Inject repeated failures
CLAUDE_INJECT_ERROR=PersistentFailure /orchestrate "test workflow"
# Should open circuit breaker after 3 failures

# View error patterns
cat .claude/errors/patterns.json | jq .
# Should show learned patterns

# Test pattern matching
# Run command that matches known pattern
# Should skip retry for known unrecoverable errors
```

### Phase 5: Notification System Implementation
**Objective**: Implement OS notifications for workflow events
**Complexity**: Medium

Tasks:
- [ ] Implement `lib/notifications.lua` with platform detection
- [ ] Add Linux support via `notify-send` command
- [ ] Add macOS support via `osascript` command
- [ ] Add Windows support via PowerShell (if applicable)
- [ ] Implement notification configuration (enable/disable, level)
- [ ] Add notification for workflow completion
- [ ] Add notification for workflow failure
- [ ] Add notification for long-running operations (>5 min)
- [ ] Integrate notifications into `/orchestrate` command
- [ ] Integrate notifications into `/implement` command
- [ ] Add `--notify` flag to commands for explicit notifications
- [ ] Add configuration file `.claude/config/notifications.yml`
- [ ] Test on Linux (if applicable)
- [ ] Test on macOS (if applicable)
- [ ] Test notification levels (all, errors_only, major_events)

Configuration file (`.claude/config/notifications.yml`):
```yaml
notifications:
  enabled: true
  level: major_events  # all, errors_only, major_events
  long_running_threshold_minutes: 5
```

Testing:
```bash
# Enable notifications
echo "notifications:\n  enabled: true" > .claude/config/notifications.yml

# Run workflow
/orchestrate "test feature" --notify
# Should show OS notification on completion

# Test long-running notification
# (Mock long execution >5 min)
CLAUDE_MOCK_LONG_EXECUTION=1 /orchestrate "test"
# Should show progress notification at 5 min mark

# Test error notification
# (Inject error)
CLAUDE_INJECT_ERROR=TestError /implement plan.md
# Should show error notification
```

### Phase 6: Integration Testing and Documentation
**Objective**: Comprehensive testing and documentation updates
**Complexity**: Medium

Tasks:
- [ ] Create integration test suite for all features
- [ ] Test metrics → state → recovery → notifications workflow
- [ ] Test `/orchestrate` with full infrastructure
- [ ] Test `/implement` with full infrastructure
- [ ] Test interruption and resume with notifications
- [ ] Test error recovery with metrics tracking
- [ ] Verify no performance degradation (metrics overhead <1%)
- [ ] Update `/orchestrate` command documentation
- [ ] Update `/implement` command documentation
- [ ] Create documentation for `/metrics` command
- [ ] Create documentation for `/workflows` command family
- [ ] Update CLAUDE.md with new commands
- [ ] Create user guide in `docs/workflow-infrastructure.md`
- [ ] Document configuration options
- [ ] Document troubleshooting common issues
- [ ] Generate implementation summary

Testing:
```bash
# Full workflow test
/orchestrate "Complete feature implementation with all infrastructure"
# Interrupt with CTRL+C
# Resume
/workflows resume <id>
# Should complete successfully with:
# - Metrics collected
# - State persisted and restored
# - Errors recovered automatically
# - Notification on completion

# Performance test
time /orchestrate "Simple workflow"
# Compare before/after infrastructure addition
# Overhead should be <1%

# Metrics verification
/metrics orchestrate --timeframe week
# Should show all orchestrate executions with accurate timings
```

## Testing Strategy

### Unit Testing
- Each module (`metrics.lua`, `state.lua`, `error_recovery.lua`, `notifications.lua`) has unit tests
- Test error conditions and edge cases
- Mock file system operations where appropriate

### Integration Testing
- Test interaction between modules
- Test full workflow with all infrastructure enabled
- Test interruption and resume scenarios
- Test error recovery with real/mocked errors

### Performance Testing
- Measure infrastructure overhead
- Ensure metrics collection <1% overhead
- Ensure state persistence <2% overhead
- Verify no blocking operations on critical path

### User Acceptance Testing
- Run on real workflows (`/orchestrate`, `/implement`)
- Verify notifications work on target platform
- Verify metrics are understandable and actionable
- Verify resume works after various interruption types

## Documentation Requirements

### Command Documentation
- Create `commands/metrics.md` - Performance analytics command
- Create `commands/workflows.md` - Workflow management commands
- Update `commands/orchestrate.md` - Document infrastructure integration
- Update `commands/implement.md` - Document infrastructure integration

### User Guides
- Create `docs/workflow-infrastructure.md` - Overview of new infrastructure
- Create `docs/metrics-guide.md` - Using metrics for optimization
- Create `docs/error-recovery-guide.md` - Understanding error patterns
- Create `docs/notifications-setup.md` - Platform-specific notification setup

### Developer Documentation
- Update `docs/standards-integration-pattern.md` - Include infrastructure modules
- Create `docs/infrastructure-api.md` - API reference for modules
- Update CLAUDE.md with new commands and infrastructure

## Dependencies

### System Dependencies
- **Linux**: `notify-send` (usually pre-installed with desktop environment)
- **macOS**: `osascript` (built-in)
- **Windows**: PowerShell (built-in)

### Lua Libraries (if needed)
- `luajson` or `cjson` for JSON serialization (likely already available)
- No additional dependencies expected (use built-in capabilities)

### File System Requirements
- Write access to `.claude/` directory
- ~100MB disk space for metrics (1 year history)
- ~10MB disk space for state files (100 concurrent workflows)

## Risk Assessment and Mitigation

### Risk 1: Performance Overhead
**Impact**: High (if infrastructure slows down commands)
**Likelihood**: Medium
**Mitigation**:
- Async/non-blocking metrics writes
- Lazy state serialization (only on phase boundaries)
- Performance benchmarks before/after
- Monitoring infrastructure overhead

### Risk 2: State Corruption
**Impact**: High (workflow unrecoverable)
**Likelihood**: Low
**Mitigation**:
- Atomic writes (write to temp file, rename)
- JSON schema validation on load
- Backup previous state on update
- Graceful degradation (continue without state if corrupted)

### Risk 3: Notification Spam
**Impact**: Medium (user annoyance)
**Likelihood**: Medium
**Mitigation**:
- Configurable notification levels
- Rate limiting (max 1 notification per 5 minutes per workflow)
- User can disable notifications easily

### Risk 4: Cross-Platform Compatibility
**Impact**: Medium (notifications don't work on some platforms)
**Likelihood**: Medium
**Mitigation**:
- Platform detection and graceful fallback
- Silent failure if notification API unavailable
- Test on multiple platforms
- Document platform requirements

### Risk 5: Disk Space Exhaustion
**Impact**: Medium (metrics fill disk)
**Likelihood**: Low
**Mitigation**:
- Automatic metrics rotation (monthly)
- Cleanup old metrics (>1 year)
- Configurable retention policy
- Warning when metrics directory >1GB

## Rollout Plan

### Phase 1: Soft Launch (Week 1)
- Enable infrastructure but with explicit opt-in
- Add `--enable-infrastructure` flag to commands
- Monitor for issues
- Gather user feedback

### Phase 2: Default Enable (Week 2)
- Enable infrastructure by default
- Add `--disable-infrastructure` flag for opt-out
- Continue monitoring
- Iterate based on feedback

### Phase 3: Full Integration (Week 3)
- Remove opt-out flags (infrastructure always enabled)
- Finalize documentation
- Generate implementation summary
- Announce completion

## Success Metrics

After implementation, measure:
- **Adoption**: % of workflows using state persistence
- **Reliability**: Workflow interruption → resume success rate >95%
- **Performance**: Infrastructure overhead <1% on average command
- **Error Recovery**: Automatic recovery success rate >80%
- **User Satisfaction**: Notifications helpful (survey)

## Notes

### Design Decisions

**Why JSONL for metrics?**
- Append-only, no file locking
- Easy to parse line-by-line
- Standard format, many tools support it
- Efficient for time-series data

**Why JSON for state?**
- Human-readable for debugging
- Easy to edit if recovery needed
- Good Lua support
- Structured schema

**Why separate error pattern database?**
- Learn across all workflows
- Share knowledge between commands
- Don't pollute individual workflow state

**Why OS notifications instead of terminal-only?**
- User may switch away from terminal during long workflows
- Standard platform integration
- Familiar UX for users

### Future Enhancements (Out of Scope)

These are not included in this plan but could be added later:
- Real-time progress visualization (Phase 1 roadmap item)
- Workflow templates (Phase 3 roadmap item)
- Team collaboration (Phase 3 roadmap item)
- Web dashboard for metrics (advanced)
- Metrics export to external systems (Prometheus, etc.)
- Workflow scheduling (Phase 5 roadmap item)

### Compatibility

This implementation maintains backward compatibility:
- Existing commands work without infrastructure
- Infrastructure is additive (no breaking changes)
- Old workflows (pre-infrastructure) can't be resumed but don't break
- Configuration is optional (sensible defaults)

---

*This plan addresses 4 of 15 identified gaps from report 014*
*Estimated completion: 4-6 weeks*
*Priority: Critical (Phase 1 in roadmap)*
