# Migration Guide: Agential System Refinement

**Date**: 2025-10-06
**Plan**: 026_agential_system_refinement.md
**Impact**: Low to Medium (command consolidation, new features added)

## Overview

This guide documents breaking changes from the agential system refinement and provides clear migration paths for all affected workflows.

## Breaking Changes

### 1. Command Consolidation

Four commands have been removed and consolidated into existing commands for a cleaner interface.

#### `/cleanup` → `/setup --cleanup`

**Before**:
```bash
/cleanup /path/to/project
/cleanup /path/to/project --dry-run
```

**After**:
```bash
/setup --cleanup /path/to/project
/setup --cleanup --dry-run /path/to/project
```

**Impact**: Low
**Migration**: Simple command replacement

---

#### `/validate-setup` → `/setup --validate`

**Before**:
```bash
/validate-setup
/validate-setup /path/to/project
```

**After**:
```bash
/setup --validate
/setup --validate /path/to/project
```

**Impact**: Low
**Migration**: Simple command replacement

---

#### `/analyze-agents` → `/analyze agents`

**Before**:
```bash
/analyze-agents
```

**After**:
```bash
/analyze agents
```

**Impact**: Medium
**Migration**: Add type parameter `agents`

---

#### `/analyze-patterns` → `/analyze patterns`

**Before**:
```bash
/analyze-patterns
```

**After**:
```bash
/analyze patterns
```

**Impact**: Medium
**Migration**: Add type parameter `patterns`

---

### 2. New `/analyze` Command

The `/analyze` command now accepts a type parameter for unified analysis:

**Usage**:
```bash
/analyze agents      # Analyze agent performance
/analyze patterns    # Analyze codebase patterns
/analyze all         # Run all analysis types (default)
```

**Migration from Old Commands**:
- `/analyze-agents` → `/analyze agents`
- `/analyze-patterns` → `/analyze patterns`

## New Features (No Migration Required)

### 1. Adaptive Planning in /implement

**Feature**: Automatic plan revision during implementation

**Triggers**:
- Complexity threshold exceeded (score >8 or >10 tasks)
- 2+ consecutive test failures in same phase
- Scope drift detected (manual flag)

**Behavior**:
- Automatically invokes `/revise --auto-mode`
- Updates plan structure (expands phases, adds phases, updates tasks)
- Continues with revised plan
- Maximum 2 replans per phase (loop prevention)

**New Logging**:
- Logs: `.claude/logs/adaptive-planning.log`
- Log rotation: 10MB max, 5 files retained
- Query logs: Use new utility functions in `lib/adaptive-planning-logger.sh`

**No Action Required**: Feature is automatically available in `/implement`

---

### 2. /revise Auto-Mode

**Feature**: Programmatic plan revision for /implement integration

**Usage** (for /implement, not user-facing):
```bash
/revise <plan-path> --auto-mode --context '<json>'
```

**Context JSON Structure**:
```json
{
  "revision_type": "expand_phase|add_phase|split_phase|update_tasks",
  "current_phase": <number>,
  "reason": "<explanation>",
  "suggested_action": "<action description>",
  "trigger_data": <context-specific data>
}
```

**No Action Required**: Used automatically by `/implement` adaptive planning

---

### 3. Shared Utility Libraries

**Feature**: Reusable utility functions in `.claude/lib/`

**Available Libraries**:
- `checkpoint-utils.sh` - Workflow state persistence
- `complexity-utils.sh` - Phase complexity analysis
- `artifact-utils.sh` - Artifact tracking
- `error-utils.sh` - Error classification and recovery
- `adaptive-planning-logger.sh` - Adaptive planning logging

**Usage** (for developers extending Claude Code):
```bash
source .claude/lib/checkpoint-utils.sh
save_checkpoint "implement" "my_project" "$state_json"
```

**No Action Required**: Commands automatically use these utilities

## Automated Data Migrations

### Checkpoint Schema v1.0 → v1.1

**Changes**:
- Added `replanning_count`
- Added `last_replan_reason`
- Added `replan_phase_counts`
- Added `replan_history`

**Migration**: Automatic
**Impact**: None (backward compatible, auto-migrates on load)

---

### Plan Structure Level Tracking

**Changes**:
- Added `Structure Level` metadata field
- Tracks progressive expansion (0 → 1 → 2)

**Migration**: Automatic
**Impact**: None (added to metadata on next plan update)

## Testing Your Migration

### 1. Test Consolidated Commands

```bash
# Test /setup consolidation
/setup --cleanup --dry-run /path/to/project
/setup --validate /path/to/project

# Test /analyze consolidation
/analyze agents
/analyze patterns
```

### 2. Verify Adaptive Planning

```bash
# Create a complex test plan and run /implement
# Watch for adaptive planning triggers in output
/implement specs/plans/test_complex_plan.md
```

### 3. Check Logs

```bash
# View adaptive planning logs
tail -f .claude/logs/adaptive-planning.log

# Query specific events
source .claude/lib/adaptive-planning-logger.sh
query_adaptive_log "trigger_eval" 10
```

## Troubleshooting

### Command Not Found

**Error**: `/cleanup: command not found` or similar

**Solution**: Use consolidated command
```bash
# Old: /cleanup
# New: /setup --cleanup
```

---

### Checkpoint Migration Warnings

**Warning**: `Migrating checkpoint from v1.0 to v1.1`

**Action**: None required (automatic migration)
**Info**: Backup created at `<checkpoint>.v1.0.backup`

---

### Adaptive Planning Loop Prevention

**Warning**: `Phase 3 replan limit exceeded (2/2), escalating to user`

**Action**: Manual intervention required
**Info**: Review replan history and decide next steps
```bash
# Check replan history
source .claude/lib/adaptive-planning-logger.sh
query_adaptive_log "replan" 10
```

## Rollback Instructions

If you encounter issues and need to rollback:

### 1. Restore Old Commands

Old commands were removed in Phase 2. To restore:
```bash
# Checkout commands from before Phase 2
git checkout <commit-before-phase-2> -- .claude/commands/cleanup.md
git checkout <commit-before-phase-2> -- .claude/commands/validate-setup.md
git checkout <commit-before-phase-2> -- .claude/commands/analyze-agents.md
git checkout <commit-before-phase-2> -- .claude/commands/analyze-patterns.md
```

### 2. Disable Adaptive Planning

Adaptive planning can be disabled by avoiding the flags:
```bash
# Don't use --report-scope-drift flag
# Adaptive planning won't trigger
/implement <plan>
```

### 3. Use Old Checkpoint Format

If checkpoint migration causes issues:
```bash
# Restore from backup
cp <checkpoint>.v1.0.backup <checkpoint>
```

## Support

For issues or questions:
1. Check `.claude/tests/COVERAGE_REPORT.md` for known gaps
2. Review `.claude/specs/plans/026_agential_system_refinement.md` for implementation details
3. Check `.claude/lib/README.md` for utility documentation
4. Review implementation summary at `.claude/specs/summaries/026_implementation_summary.md`

## Summary

**Total Commands Removed**: 4
**Total Commands Added**: 0 (consolidated into existing)
**Net Command Reduction**: 4 (29 → 26)
**Breaking Changes**: 4 command replacements (all with clear migration paths)
**New Features**: 3 (adaptive planning, auto-mode /revise, shared utilities)
**Data Migrations**: 2 (both automatic)

**Migration Effort**: Low (< 1 hour for most users)
**Benefits**: Cleaner interface, adaptive planning, better error handling, reduced code duplication
