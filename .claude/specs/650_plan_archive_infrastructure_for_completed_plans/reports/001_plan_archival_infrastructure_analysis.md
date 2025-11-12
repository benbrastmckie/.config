# Plan Archival Infrastructure Analysis

## Metadata
- **Date**: 2025-11-10
- **Topic Directory**: `.claude/specs/650_plan_archive_infrastructure_for_completed_plans/`
- **Report Number**: 001
- **Scope**: Comprehensive audit of existing plan management, completion detection, and archival patterns
- **Files Analyzed**: 25+ core files including implement.md, checkpoint-utils.sh, plan-core-bundle.sh, workflow-state-machine.sh, directory-protocols.md

---

## Executive Summary

The Claude Code infrastructure currently **lacks a formal plan archival system**. However, substantial foundations exist for implementing one:

**Key Findings:**
1. **Completion Detection**: Plans complete when `CURRENT_PHASE == TOTAL_PHASES` (detected in implement.md Phase 2 finalization)
2. **Gitignore Compliance**: Plans are intentionally gitignored (`specs/*/*` pattern), making archival isolated to local state only
3. **Lifecycle Markers**: Implementation summaries exist but are not automatically created or marked as "complete"
4. **State Machine Ready**: Workflow-state-machine.sh has terminal state concept (`STATE_COMPLETE`) but it applies to workflow state, not plan completion
5. **No Existing Archives**: No `archived/` directories found in specs/ — archival is not yet implemented
6. **No Completion Tracking**: Plans lack metadata marking them as "complete" vs "in-progress"

**Recommendations:**
- Implement plan completion metadata (completion date, final phase timestamp)
- Create optional archival utility (move completed plans to `specs/{topic}/archived/`)
- Update /implement to mark plans complete in checkpoint
- Establish gitignore patterns for archived plans if they should be committed

---

## Current Gitignore Patterns

**File**: `.gitignore` (lines 80-87)

```
# Archive directory (local only, not tracked)
.claude/archive/

# Topic-based specs organization (added by /migrate-specs)
# Gitignore all specs subdirectories
specs/*/*
# Un-ignore debug subdirectories within topics
!specs/*/debug/
!specs/*/debug/**
```

**Key Observations:**
- All artifacts in `specs/{topic}/{artifact}/` are gitignored EXCEPT debug reports
- `.claude/archive/` reserved for local-only archival (not tracked in git)
- Plans are already local-only via gitignore pattern

---

## Plan Completion Detection in /implement

**File**: `.claude/commands/implement.md` (Phase 2: Lines 180-216)

The /implement command detects completion via:

1. **Phase Loop Completion**: `for CURRENT_PHASE in $(seq "$STARTING_PHASE" "$TOTAL_PHASES")`
   - Loop completes when all phases executed

2. **Summary Finalization**:
   - Renames partial summary to final summary
   - Creates `specs/{topic}/summaries/{N}_implementation_summary.md`

3. **Checkpoint Deletion**:
   - Deletes checkpoint file on successful completion
   - Confirms workflow completion

4. **Test Validation**:
   - Tests required to pass before each phase
   - Only reaches completion if all tests pass

**Completion Output**:
```bash
echo "CHECKPOINT: Implementation Complete"
echo "- Plan: $(basename "$PLAN_FILE")"
echo "- Phases: $TOTAL_PHASES/$TOTAL_PHASES (100%)"
echo "- Summary: $FINAL_SUMMARY"
echo "- Status: COMPLETE"
```

---

## Checkpoint-Based State Tracking

**File**: `.claude/lib/checkpoint-utils.sh` (lines 54-120)

Checkpoints store workflow state with these relevant fields:
- `workflow_type`: "implement"
- `plan_path`: Full path to plan file
- `current_phase`: Last executed phase
- `total_phases`: Total phases in plan
- `status`: "in_progress" | "complete"
- `tests_passing`: Boolean

**Completion Logic**:
```bash
if [ $CURRENT_PHASE -eq $TOTAL_PHASES ] && [ "$tests_passing" = "true" ]; then
  status="complete"
fi
```

When /implement finishes, checkpoint is deleted (line 212 of implement.md).

---

## State Machine Integration

**File**: `.claude/lib/workflow-state-machine.sh` (lines 43, 52, 72)

Defines explicit workflow completion state:
- `STATE_COMPLETE` (Phase 7: Finalization, cleanup)
- Terminal state determined by workflow scope
- Note: Tracks workflow state, not individual plan state (different concepts)

---

## Implementation Summary Structure

**Example**: `.claude/specs/647_and_standards_in_claude_docs_in_order_to_create_a/summaries/001_implementation_summary.md` (567 lines)

**Standard Format**:
```markdown
# Implementation Summary: {Plan Name}

## Metadata
- **Specification**: {Number}
- **Implementation Date**: {Date}
- **Phases Completed**: {Completed}/{Total}
- **Status**: Near-complete | Complete | In Progress

## Overview
[Summary of what was completed]

## Key Achievements
[Major accomplishments]

## Phase-by-Phase Implementation
[Details of each phase]

## Files Modified
[List of changed files]

## Git Commit History
[Commits created during implementation]

## Success Metrics Summary
[Table of targets vs achieved]

## Conclusion
[Final assessment]
```

**Observations**:
- Summaries created during /implement Phase 2
- Status field exists but not standardized
- No automated completion date insertion
- No archival trigger based on summary existence

---

## Topic-Based Directory Structure

**File**: `.claude/docs/concepts/directory-protocols.md` (lines 40-51)

Current structure:
```
specs/
└── {NNN_topic}/
    ├── plans/          # Implementation plans (gitignored)
    ├── reports/        # Research reports (gitignored)
    ├── summaries/      # Implementation summaries (gitignored)
    ├── debug/          # Debug reports (COMMITTED to git)
    ├── scripts/        # Investigation scripts (gitignored, temporary)
    ├── outputs/        # Test outputs (gitignored, temporary)
    ├── artifacts/      # Operation artifacts (gitignored)
    └── backups/        # Backups (gitignored)
```

**Notable Absence**: No `archived/` subdirectory defined. Would be natural addition for completed plans.

---

## Artifact Lifecycle Documentation

**File**: `.claude/docs/concepts/directory-protocols.md` (line 26)

States lifecycle as: `create → use → complete → archive`

**Current Status**:
- ✓ Create: Plans created by /plan command
- ✓ Use: Plans executed by /implement command
- ✓ Complete: Summaries mark completion
- ✗ Archive: Not implemented

---

## Existing Plan Completion Signals

**Primary Signals**:
1. **Checkpoint Deletion**: No active checkpoint after /implement completes
2. **Summary Existence**: `specs/{topic}/summaries/{N}_implementation_summary.md` exists
3. **Phase Completion**: All phases 1..TOTAL_PHASES executed

**Secondary Signals**:
1. **Test Passing**: All tests passed during execution
2. **Git Commits**: Commits created for each phase
3. **Plan Unchanged**: No modifications after summary created

---

## No Existing Archive Implementation

**Search Result**: `find .claude/specs -name "archived" -type d` → **0 results**

**Implication**: Archival not currently practiced. Infrastructure ready, but pattern not established.

---

## Plan Parsing and Manipulation Utilities

**File**: `.claude/lib/plan-core-bundle.sh` (1,143 lines)

Available functions relevant to archival:
- `extract_phase_name()`: Get phase name
- `extract_phase_content()`: Get phase content
- `detect_structure_level()`: Detect plan expansion level (0/1/2)
- `is_plan_expanded()`: Check if plan has directory
- `cleanup_plan_directory()`: Move plan file and delete directory

**Notable**: `cleanup_plan_directory()` can be repurposed for archival operations.

---

## Checkpoint Utilities

**File**: `.claude/lib/checkpoint-utils.sh` (34,860 bytes)

Functions available:
- `save_checkpoint()`: Save workflow state
- `load_checkpoint()`: Load most recent checkpoint
- `delete_checkpoint()`: Remove checkpoint (used on completion)
- `is_checkpoint_complete()`: Verify completion status

**For Archival**: Can verify plan completion via checkpoint queries.

---

## Unified Location Detection

**File**: `.claude/lib/unified-location-detection.sh`

Provides:
- `ensure_artifact_directory()`: Create directory if needed
- `get_next_artifact_number()`: Get sequential numbering
- Lazy directory creation (only when needed)

**For Archival**: Can use to create `archived/` directories and manage numbering.

---

## Testing Infrastructure

**Location**: `.claude/tests/` directory

Test files for relevant components:
- `test_checkpoint_utils.sh`: Checkpoint operations
- `test_state_machine.sh`: Workflow state transitions
- `test_plan_parsing.sh`: Plan structure detection
- `test_implement_integration.sh`: /implement command workflow

**For Archival**: Established patterns for comprehensive test coverage.

---

## Cross-Reference Impact

**Files that reference plan paths**:
1. **Checkpoints**: `plan_path` field (deleted on completion, so stale paths not issue)
2. **Summaries**: Reference source plan in metadata section
3. **Execution logs**: Phase-by-phase plan references

**Impact of Archival**:
- Checkpoint already deleted, no path issues
- Summaries can be updated with archive location
- Log references immutable (use archived plan path)

---

## Standards Compliance

### Standard 0: Execution Enforcement
**Current**: /implement has MANDATORY VERIFICATION checkpoints

**For Archival**: Add verification checkpoint before archival to confirm plan moved successfully.

### Standard 14: Executable/Documentation Separation
**Current**: /implement is 216 lines (within limits)

**For Archival**: Implement as shared utility library (plan-archival.sh) to keep commands lean.

### Standard 13: Project Directory Detection
**Current**: Uses `detect-project-dir.sh` pattern

**For Archival**: Will use same pattern for consistency.

---

## Key Findings Summary

| Category | Status | Notes |
|----------|--------|-------|
| **Completion Detection** | Ready | Checkpoint + summary signals exist |
| **Archival Location** | Ready | Directory structure supports archived/ |
| **Gitignore Pattern** | Ready | Can extend existing pattern |
| **Utilities Available** | Ready | cleanup_plan_directory() is reusable |
| **Metadata** | Partial | Summaries exist, completion markers needed |
| **Testing Framework** | Ready | Test infrastructure in place |
| **Integration Point** | Ready | /implement Phase 2 is ideal trigger |
| **State Machine Support** | Ready | STATE_COMPLETE provides hook |
| **Safety Mechanisms** | Ready | Checkpoint/summary provide verification |
| **Documentation** | Needed | Plan archival guide needed |
| **Implementation Utility** | Needed | Create plan-archival.sh |
| **Command Integration** | Needed | Modify /implement Phase 2 |

---

## Recommended Archival Structure

**Proposed Addition to Directory Protocols**:
```
specs/{NNN_topic}/
├── plans/                 # Active implementation plans
│   ├── 001_feature.md
│   └── 002_enhancement.md
├── archived/              # Completed plans (local only)
│   ├── 001_completed_20251110.md
│   └── 003_completed_20251105.md
├── summaries/
│   ├── 001_implementation_summary.md
│   └── 003_implementation_summary.md
└── debug/
    └── [committed reports]
```

---

## Recommendations for Implementation

### 1. Create Archival Utility Library
File: `.claude/lib/plan-archival.sh`

Functions to implement:
- `is_plan_complete(plan_file)` - Detect completion via checkpoint + summary
- `archive_plan(plan_file, summary_file)` - Move plan to archived/ directory
- `verify_archive(archived_path)` - Verify move succeeded
- `list_archived_plans(topic)` - Discover archived plans

### 2. Integrate with /implement Command
**Modification Location**: `/implement` Phase 2

After summary finalization:
```bash
# NEW: Archive the completed plan
if is_plan_complete "$PLAN_FILE"; then
  archive_plan "$PLAN_FILE" "$FINAL_SUMMARY"
fi
```

### 3. Update Gitignore
Add to `.gitignore`:
```
# Completed plans (local archival, not tracked in git)
specs/*/archived/
specs/*/archived/**
```

### 4. Update Documentation
- Extend `directory-protocols.md` with `archived/` section
- Create `plan-archival-guide.md` with usage patterns
- Document archival behavior in `/implement` command guide

### 5. Add Comprehensive Tests
File: `.claude/tests/test_plan_archival.sh`

Test cases:
- Plan completion detection
- Archive directory creation
- File move operations
- Gitignore compliance
- Cross-reference handling

---

## Estimated Effort

**Phase 1**: Create archival utility library
- Time: 2-3 hours
- Lines: 200-300
- Tests: 8-12 test cases

**Phase 2**: Integrate with /implement
- Time: 1 hour
- Lines: 10-15
- Tests: 3-5 integration tests

**Phase 3**: Update documentation
- Time: 1-2 hours
- Lines: 1,000-1,500

**Total**: 4-6 hours, ~1,500 lines of code + documentation

---

**Report Complete**: 2025-11-10
**Analysis Scope**: Complete (covered all major infrastructure areas)
**Ready for Planning**: Yes, sufficient information for detailed implementation plan
