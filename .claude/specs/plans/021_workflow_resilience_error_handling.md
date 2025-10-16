# Workflow Resilience and Error Handling Implementation Plan

## Metadata

- **Date**: 2025-10-03
- **Specs Directory**: /home/benjamin/.config/.claude/specs/
- **Plan Number**: 021
- **Feature**: Implement workflow checkpointing and enhanced error messages
- **Scope**: Phase 3 of Plan 019 - Agentic Workflow Enhancements
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Parent Plan**: [019_agentic_workflow_enhancements.md](019_agentic_workflow_enhancements.md)
- **Research Reports**: [../reports/023_claude_agentic_workflow_improvements.md](../reports/023_claude_agentic_workflow_improvements.md)

## Overview

This plan implements workflow resilience features and enhanced error handling from the broader agentic workflow enhancements initiative. It focuses on adding checkpointing for workflow interruption recovery and improving error messages to accelerate problem resolution.

**Current State**: Phases 1-2 complete (metrics, thinking modes, retry logic, artifact system, agent tracking)
**Target State**: Resumable workflows with intelligent checkpointing, actionable error messages with fix suggestions

**Total Effort**: ~26 hours over 4 sub-phases
**Expected Impact**: 40-60% faster problem resolution, resumable workflows after interruption

## Success Criteria

- [ ] Workflow checkpointing operational in `/orchestrate` and `/implement`
- [ ] Checkpoints stored in `.claude/data/checkpoints/` with auto-cleanup
- [ ] Interactive resume detection on workflow restart
- [ ] Enhanced error messages with 2-3 specific fix suggestions
- [ ] Error context includes relevant code locations and documentation links
- [ ] Graceful degradation for partial failures
- [ ] Documentation complete for checkpointing and error enhancement
- [ ] Backward compatible with existing workflows

## Technical Design

### Workflow Checkpointing System

```
Current (No Checkpointing):           Enhanced (With Checkpointing):
┌─────────────────────┐              ┌─────────────────────┐
│ /orchestrate start  │              │ /orchestrate start  │
│ ↓                   │              │ ↓                   │
│ Phase 1 → Phase 2   │              │ Check for existing  │
│ ↓                   │              │ checkpoint          │
│ [Process killed]    │              │ ↓                   │
│                     │    ───>      │ Resume? [y/n/v]     │
│ Lost all progress   │              │ ↓                   │
│ Restart from begin  │              │ Resume from Phase 2 │
└─────────────────────┘              └─────────────────────┘
```

### Checkpoint Data Structure

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

### Enhanced Error Messages

```
Before:                              After:
┌──────────────────────┐            ┌─────────────────────────────────┐
│ Error: Test failed   │            │ Error: Test failed in auth_spec │
│ Exit code: 1         │   ───>     │                                 │
│                      │            │ Location: tests/auth_spec.lua:42│
│ [End of message]     │            │                                 │
│                      │            │ Context:                        │
│                      │            │   login() expects mock_session  │
│                      │            │   but received nil              │
│                      │            │                                 │
│                      │            │ Suggestions:                    │
│                      │            │ 1. Add session mock in setup()  │
│                      │            │ 2. Check session_manager init   │
│                      │            │ 3. Review auth factory pattern  │
│                      │            │                                 │
│                      │            │ Debug: /debug "auth test fail"  │
│                      │            │ Docs: tests/README.md#mocking   │
└──────────────────────┘            └─────────────────────────────────┘
```

## Implementation Phases

### Phase 3.1: Workflow Checkpointing Infrastructure

**Objective**: Create checkpoint storage and management system
**Complexity**: Medium-High
**Effort**: 8 hours

Tasks:
- [x] Create checkpoint data schema
  - Design JSON structure for checkpoint data
  - Include workflow type, state, progress tracking
  - Add metadata (timestamps, status, error info)
  - Define checkpoint ID generation (type_project_timestamp)
- [x] Create `.claude/data/checkpoints/` directory structure
  - Initialize checkpoints directory
  - Add .gitignore for checkpoints/
  - Create README documenting checkpoint format
- [x] Implement checkpoint save logic
  - Create `save-checkpoint.sh` utility script
  - Accept workflow state as JSON
  - Generate unique checkpoint ID
  - Write checkpoint file atomically
  - Return checkpoint path
- [x] Implement checkpoint load logic
  - Create `load-checkpoint.sh` utility script
  - Find most recent checkpoint by workflow type
  - Validate checkpoint integrity
  - Return checkpoint data
- [x] Add checkpoint cleanup policy
  - Auto-delete on workflow success
  - Archive failures to `checkpoints/failed/`
  - Auto-cleanup checkpoints >7 days old
  - Create cleanup cron/systemd timer (optional)
- [x] Create checkpoint listing utility
  - List all active checkpoints
  - Show workflow type, phase, age
  - Support filtering by type/status

Testing:
```bash
# Test checkpoint creation
.claude/utils/save-checkpoint.sh orchestrate '{"status":"in_progress","phase":2}'

# Verify checkpoint file
ls -la .claude/data/checkpoints/
cat .claude/data/checkpoints/orchestrate_*.json | jq

# Test checkpoint loading
.claude/utils/load-checkpoint.sh orchestrate

# Test cleanup
# Create old checkpoint (manual timestamp edit)
# Run cleanup script
# Verify old checkpoint removed
```

Expected Outcomes:
- Checkpoints successfully created and loaded
- Unique IDs prevent collisions
- Cleanup policy works as expected

---

### Phase 3.2: Checkpoint Integration in /orchestrate and /implement

**Objective**: Add checkpoint save/restore to workflow commands
**Complexity**: Medium-High
**Effort**: 10 hours

Tasks:
- [x] Add checkpoint detection to `/orchestrate` start
  - Check for existing checkpoint at workflow start
  - Parse workflow description to match checkpoint
  - Display interactive resume prompt if found
  - Options: (r)esume, (s)tart fresh, (v)iew details, (d)elete
- [x] Implement checkpoint save in `/orchestrate`
  - Save checkpoint after each major step
  - Include: current phase, workflow_state, artifacts, results
  - Update checkpoint on progress
  - Delete checkpoint on successful completion
  - Archive checkpoint on failure
- [x] Add checkpoint restore to `/orchestrate`
  - Load workflow state from checkpoint
  - Restore: project_name, artifact_registry, progress
  - Resume from last completed phase
  - Display resume summary to user
- [x] Add checkpoint integration to `/implement`
  - Save checkpoint after each phase completion
  - Include: plan_path, current_phase, test_results
  - Enable resume from last successful phase
  - Update `/resume-implement` to check checkpoints first
- [x] Implement interactive resume prompts
  - Display checkpoint details (age, phase, description)
  - Confirm resume vs. restart
  - Show diff if workflow description changed
  - Validate checkpoint compatibility
- [x] Add checkpoint error handling
  - Detect corrupted checkpoints
  - Handle version mismatches gracefully
  - Provide clear error messages
  - Offer manual checkpoint deletion

Testing:
```bash
# Test /orchestrate checkpointing
/orchestrate "Test workflow with research and planning"
# Kill process after Phase 1
# Restart
/orchestrate  # Should prompt to resume

# Test /implement checkpointing
/implement specs/plans/022_test_plan.md
# Stop after Phase 2
# Restart
/implement  # Should auto-resume

# Test checkpoint corruption handling
# Manually corrupt checkpoint JSON
/orchestrate  # Should detect and handle gracefully
```

Expected Outcomes:
- Workflows resume seamlessly after interruption
- Interactive prompts provide clear options
- Corrupted checkpoints handled without crashes

---

### Phase 3.3: Enhanced Error Messages and Analysis

**Objective**: Add intelligent error parsing and fix suggestions
**Complexity**: Medium
**Effort**: 6 hours

Tasks:
- [x] Create error analysis framework
  - Define error parsing utilities
  - Extract error type (syntax, test failure, file not found, etc.)
  - Extract location (file:line) from error output
  - Parse stack traces and error context
- [x] Implement context search for errors
  - Search for relevant code around error location
  - Find related functions/classes
  - Identify recent changes (git blame)
  - Locate documentation for errored component
- [x] Generate fix suggestions
  - Create suggestion templates per error type
  - Syntax errors: Show correct syntax, link to docs
  - Test failures: Suggest mock/setup fixes, data issues
  - File errors: Show path resolution, suggest corrections
  - Import errors: Suggest package installation, path fixes
  - Provide 2-3 specific, actionable suggestions per error
- [x] Add error enhancement to commands
  - Update `/implement` to enhance test failures
  - Update `/test` to enhance test errors
  - Update `/orchestrate` to enhance agent failures
  - Add error enhancement to `test-specialist` agent
- [x] Include debug commands and links
  - Add `/debug` command suggestion
  - Link to relevant documentation
  - Show related log files
  - Suggest investigation steps
- [x] Implement graceful degradation
  - Detect partial success scenarios
  - Document what succeeded vs. failed
  - Suggest manual steps for completion
  - Preserve partial results

Testing:
```bash
# Test syntax error enhancement
# Create file with syntax error
/test file_with_error.lua
# Verify enhanced message with suggestions

# Test test failure enhancement
# Create failing test
/test failing_test_spec.lua
# Verify context and fix suggestions

# Test missing file error
/implement plan_referencing_missing_file.md
# Verify path suggestions and resolution help
```

Expected Outcomes:
- Error messages include 2-3 actionable suggestions
- Context shows relevant code and locations
- Debug commands and documentation linked
- 40-60% faster problem resolution

---

### Phase 3.4: Documentation and Integration Testing

**Objective**: Document checkpoint system and error enhancements, verify end-to-end
**Complexity**: Low-Medium
**Effort**: 2 hours

Tasks:
- [x] Create checkpointing guide
  - Document checkpoint format and location
  - Explain resume workflow
  - Show checkpoint management commands
  - Document cleanup policy
- [x] Create error enhancement guide
  - Document error analysis process
  - Show example enhanced messages
  - List error types and suggestions
  - Explain graceful degradation
- [x] Update command documentation
  - Update `/orchestrate` with checkpoint info
  - Update `/implement` with resume details
  - Update `/test` with error enhancement
  - Add troubleshooting section to README
- [x] Add checkpoint examples
  - Example: Resume interrupted research workflow
  - Example: Recover from mid-implementation failure
  - Example: Handle checkpoint conflicts
- [x] Create troubleshooting guide
  - Common checkpoint issues and fixes
  - Error message interpretation
  - Manual checkpoint management
  - When to delete checkpoints
- [x] Run integration tests
  - Test full `/orchestrate` with checkpointing
  - Test `/implement` resume from various phases
  - Test error enhancement across commands
  - Verify cleanup policy execution

Testing:
```bash
# Integration test 1: Complete workflow with interruption
/orchestrate "Multi-phase integration test"
# Interrupt mid-workflow
# Resume and complete
# Verify checkpoint cleanup

# Integration test 2: Implementation with failure and recovery
/implement specs/plans/test_plan.md
# Trigger intentional error in Phase 2
# Review enhanced error message
# Fix and resume
# Verify success

# Integration test 3: Multiple checkpoint scenarios
# Start multiple workflows
# List checkpoints
# Resume specific workflow
# Verify correct state restoration
```

Expected Outcomes:
- Complete documentation for checkpoint system
- Clear troubleshooting guides
- All integration tests pass
- System ready for production use

## Testing Strategy

### Unit Testing
- Test checkpoint save/load in isolation
- Test error parsing utilities
- Test suggestion generation logic

### Integration Testing
- Test `/orchestrate` with checkpointing end-to-end
- Test `/implement` resume across multiple phases
- Test error enhancement in real failures

### Edge Case Testing
- Corrupted checkpoints
- Concurrent checkpoint access
- Disk full during checkpoint save
- Very old checkpoints (>30 days)
- Checkpoint for non-existent workflow

### Performance Testing
- Checkpoint save/load speed (<100ms)
- Error analysis overhead (<200ms)
- Checkpoint cleanup time

## Documentation Requirements

### New Documentation Files
- [ ] `.claude/docs/checkpointing-guide.md`
  - Checkpoint system overview
  - Resume workflow process
  - Checkpoint management
  - Troubleshooting

- [ ] `.claude/docs/error-enhancement-guide.md`
  - Error analysis framework
  - Suggestion generation
  - Example enhanced messages
  - Graceful degradation

- [ ] `.claude/data/checkpoints/README.md`
  - Checkpoint format specification
  - Storage location and naming
  - Cleanup policy
  - Manual management

### Updated Documentation
- [ ] `.claude/commands/orchestrate.md`
  - Add checkpoint save/restore info
  - Document resume prompts
  - Add checkpoint troubleshooting

- [ ] `.claude/commands/implement.md`
  - Document checkpoint integration
  - Explain auto-resume behavior
  - Add resume examples

- [ ] `.claude/commands/README.md`
  - Add checkpoint system overview
  - Link to checkpointing guide
  - Update troubleshooting section

## Dependencies

### Internal
- Requires Phases 1-2 completion (metrics, artifacts, agent tracking)
- Builds on `/orchestrate` and `/implement` commands
- Uses existing workflow state structures

### External
- jq for JSON checkpoint manipulation
- bash for checkpoint utilities
- git (optional, for blame in error context)

### Execution Order
- Must complete phases 3.1 → 3.2 → 3.3 → 3.4 sequentially
- Phase 3.3 could partially overlap with 3.2 if needed

## Risk Assessment

### Medium-High Risk Components
- Checkpoint corruption handling (data loss risk)
- Concurrent checkpoint access (race conditions)
- Resume state validation (incompatible states)

### Mitigation Strategies
- Atomic checkpoint writes (write to .tmp, rename)
- File locking for checkpoint access
- Checkpoint schema versioning
- Extensive validation before resume

### Rollback Plan
- Can disable checkpointing via feature flag
- Checkpoints are optional (workflows work without)
- Delete corrupted checkpoints manually
- Error enhancement is non-breaking (degrades gracefully)

## Notes

### Design Decisions

**Checkpoint Storage**: `.claude/data/checkpoints/` directory
- Local to project for isolation
- Auto-cleanup prevents clutter
- Failed checkpoints archived for debugging
- Can manually inspect/edit for recovery

**Checkpoint Format**: JSON with metadata
- Human-readable for debugging
- Includes full workflow state
- Versioned for compatibility
- Atomic writes prevent corruption

**Resume Prompts**: Interactive by default
- User controls resume vs. restart
- View details option for transparency
- Delete option for cleanup
- Can be automated via flag (future)

**Error Enhancement**: Always-on by default
- Minimal performance overhead (<200ms)
- Degrades gracefully if enhancement fails
- Non-breaking (falls back to original error)
- Valuable for all users

### Future Enhancements (Post-Plan)
- Checkpoint compression for large states
- Remote checkpoint storage (cloud sync)
- Checkpoint diffing (compare states)
- Automated error fix application
- Machine learning for suggestion quality
- Checkpoint visualization dashboard

## Implementation Status

- **Status**: Complete
- **Plan**: This document
- **Implementation**: All 4 phases completed
- **Date Completed**: 2025-10-03
- **Parent Plan Status**: Phase 3 completed, proceed to Phase 4
- **Commits**:
  - 60ad340: Phase 3.1 - Workflow checkpointing infrastructure
  - 268b8df: Phase 3.2 - Checkpoint integration in commands
  - ad1f3c6: Phase 3.3 - Enhanced error analysis framework
  - (pending): Phase 3.4 - Documentation and guides

**Completed Phases:**
- Phase 3.1: Workflow Checkpointing Infrastructure ✅
- Phase 3.2: Checkpoint Integration in Commands ✅
- Phase 3.3: Enhanced Error Messages and Analysis ✅
- Phase 3.4: Documentation and Integration Testing ✅

## References

### Parent Plan
- [Plan 019: Agentic Workflow Enhancements](019_agentic_workflow_enhancements.md)

### Related Plans
- [Plan 020: Artifact System and Observability](020_artifact_system_and_observability.md) - Completed prerequisite

### Research Report
- [Report 023: Agentic Workflow Improvements](../reports/023_claude_agentic_workflow_improvements.md)

### Standards and Documentation
- [CLAUDE.md](/home/benjamin/.config/CLAUDE.md) - Project standards
- [.claude/README.md](../../README.md) - System overview
- [commands/orchestrate.md](../../commands/orchestrate.md) - Orchestrate command
- [commands/implement.md](../../commands/implement.md) - Implement command
