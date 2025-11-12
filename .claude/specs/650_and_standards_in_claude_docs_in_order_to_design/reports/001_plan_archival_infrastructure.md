# Plan Archival Infrastructure Research Report

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: Existing plan archival infrastructure and lifecycle management patterns
- **Report Type**: Codebase analysis

## Executive Summary

The .claude/ system currently has NO automated plan archival infrastructure. Plans are gitignored and persist indefinitely in specs/ topic directories with only checkpoint-based lifecycle tracking. A minimal archival system exists for debug reports (committed) vs other artifacts (gitignored), but completed plans remain in active directories with no automated cleanup or status-based archival process.

## Findings

### 1. Current Plan Lifecycle Management

**Checkpoint-Based State Tracking** (`.claude/lib/checkpoint-utils.sh:1-1006`)

The checkpoint system (Schema V2.0) tracks workflow execution state but does NOT manage plan archival:

- **Status Field**: `status: "in_progress" | "completed" | "failed"` (line 108)
- **Lifecycle**: Checkpoints track which phase is active but do not trigger plan archival on completion
- **Storage**: `.claude/data/checkpoints/` directory (line 28)
- **Persistence**: Checkpoints remain indefinitely (no auto-cleanup for completed workflows)

**Key Functions**:
- `save_checkpoint()`: Captures workflow state (lines 54-186)
- `restore_checkpoint()`: Loads most recent checkpoint (lines 188-244)
- `checkpoint_delete()`: Manual deletion only (lines 574-597)

**Observation**: Checkpoints record completion status but DO NOT archive or move the underlying plan files.

### 2. Topic-Based Directory Structure

**Directory Protocols** (`.claude/docs/concepts/directory-protocols.md:1-150`)

Plans reside in topic-based subdirectories with artifact lifecycle guidance:

```
specs/{NNN_topic}/
├── plans/          # Implementation plans (gitignored)
├── reports/        # Research reports (gitignored)
├── summaries/      # Implementation summaries (gitignored)
├── debug/          # Debug reports (COMMITTED)
└── [outputs/, scripts/, artifacts/, backups/]  # Temporary (gitignored)
```

**Artifact Lifecycle** (line 26):
- Create → Use → Complete → Archive

**Reality**: Only "Archive" mentioned conceptually; NO implementation exists.

**Gitignore Strategy** (`.gitignore:84-87`):
```gitignore
# Gitignore all specs subdirectories
specs/*/*
# Un-ignore debug subdirectories
!specs/*/debug/
!specs/*/debug/**
```

**Implication**: Plans/reports/summaries are gitignored and local-only. They persist indefinitely with no archival process.

### 3. Implementation Summary Pattern

**Workflow Completion Documentation** (`.claude/specs/647_*/summaries/001_implementation_summary.md:1-567`)

Implementation summaries document completed work but serve as HISTORICAL REFERENCE only:

**Structure**:
- Metadata: Spec number, dates, phases completed, status
- Overview: What was implemented
- Key Achievements: Metrics and results
- Phase-by-Phase Implementation: Detailed progression
- Lessons Learned: Architectural patterns discovered
- Files Modified: Complete change log
- Git Commit History: Chronological commits

**Purpose**: Post-completion documentation, NOT archival trigger

**Location**: `specs/{topic}/summaries/NNN_implementation_summary.md`

**Status**: 69 existing summaries found across 69 topics

**Observation**: Summaries document completion but do NOT trigger plan archival or cleanup.

### 4. /implement Command Completion Behavior

**Phase 1: Execute Implementation Phases** (`.claude/commands/implement.md:89-100`)

The /implement command executes phases sequentially but has NO post-completion archival:

**Workflow**:
1. Parse plan file and detect structure level (lines 77-79)
2. Execute each phase (lines 92-100)
3. Update checkboxes in plan hierarchy (via spec-updater agent)
4. Save checkpoint after each phase
5. Continue to next phase

**Completion Detection**: Checkboxes marked complete, checkpoint saved
**Post-Completion**: NOTHING - plan remains in active directory

**No Evidence Of**:
- Automated summary generation trigger
- Plan archival to completed/ subdirectory
- Checkpoint cleanup for finished workflows
- Status-based file organization

### 5. /coordinate Command Completion Behavior

**State Machine Lifecycle** (`.claude/commands/coordinate.md:1-150`)

The /coordinate command uses state machine with explicit states but NO archival on complete:

**States** (via workflow-state-machine.sh):
- initialize → research → plan → implement → test → debug → document → **complete**

**Terminal State**: `complete` (line 129)

**On Completion**: State machine reaches "complete" but:
- NO archive function invoked
- NO plan file moved
- NO checkpoint cleanup
- State file persists in `.claude/tmp/workflow_coordinate_*.sh`

**Finding**: State machine tracks completion status but does NOT trigger archival operations.

### 6. Spec Updater Agent Artifact Management

**Spec Updater Responsibilities** (`.claude/agents/spec-updater.md:1-1076`)

The spec-updater agent manages artifact PLACEMENT but NOT archival:

**Operations Supported**:
- CREATE: New artifacts in topic directories (lines 50-56)
- UPDATE: Modify existing artifact metadata (lines 57-64)
- MOVE: Relocate artifacts between directories (lines 65-73)
- LINK: Update cross-references (lines 69-73)

**Artifact Categories** (lines 175-205):
- Core Planning: plans/, reports/, summaries/ (gitignored, preserved)
- Debugging: debug/ (committed, preserved)
- Test Outputs: outputs/ (gitignored, temporary)
- Operational: artifacts/, backups/ (gitignored, optional cleanup)

**Cleanup Policy Mentions** (lines 337-340):
```markdown
Add cleanup policy in workflow summary:
- Note whether script WILL be preserved or deleted
- Scripts are gitignored by default
```

**Reality**: Cleanup policies are DOCUMENTED in summaries but NOT automated.

### 7. Existing Archival References

**Archive Directory** (`.gitignore:80-81`):
```gitignore
# Archive directory (local only, not tracked)
.claude/archive/
```

**Purpose**: Local-only storage for archived content
**Status**: Directory exists in gitignore but NO code references it
**Usage**: Historical/manual archival only (Spec 483 removed all code mentions)

**Spec 483 Cleanup** (`.claude/specs/483_remove_all_mentions_of_archived_content_in_claude_/plans/001_*.md:1-80`)

Removed all archived content mentions from:
- Dead code fallbacks to archived agents (lines 60-62)
- Broken references to utils/ and examples/ (lines 64-68)
- Historical commentary in CLAUDE.md (lines 70-72)

**Finding**: Archival infrastructure was REMOVED, not enhanced.

### 8. Checkpoint Safe Resume Conditions

**Auto-Resume Logic** (`.claude/lib/checkpoint-utils.sh:765-834`)

Checkpoints have conditions for auto-resume, implying lifecycle stages:

**Conditions** (lines 786-830):
1. Tests passing: `tests_passing == true`
2. No recent errors: `last_error == null`
3. Status in progress: `status == "in_progress"`
4. Checkpoint age ≤7 days
5. Plan not modified since checkpoint

**get_skip_reason()** (lines 836-910): Human-readable reasons for rejecting resume

**Implications**:
- 7-day age threshold suggests implicit archival window
- Plan modification detection via `plan_modification_time`
- Status field distinguishes in_progress from completed

**Missing**: NO auto-archive logic when status="completed" and age >7 days

### 9. Implementation Patterns from Existing Summaries

**Common Summary Structure** (analyzed across 69 summaries):

**Metadata Fields**:
- Specification number and topic
- Implementation dates (start/complete)
- Phases completed (X of Y)
- Status: "Complete", "Partial", "Deferred"
- Related specs (dependencies)

**Content Sections**:
- Overview: Feature description
- Key Achievements: Metrics and outcomes
- Phase-by-Phase: Detailed implementation
- Technical Patterns: Reusable patterns discovered
- Files Modified: Change inventory
- Git Commits: Chronological history
- Lessons Learned: Architectural insights

**Lifecycle Markers** (found in summaries):
- "Implementation Status: Complete" (common)
- "Summary Complete: YYYY-MM-DD" (footer)
- "Next: [next actions]" (handoff to future work)

**Observation**: Summaries mark completion but exist alongside active plans.

### 10. Gitignore Compliance and Artifact Persistence

**Gitignored Artifacts** (`.gitignore:84-87`):
- All specs subdirectories gitignored by default
- Exception: debug/ subdirectories committed

**Implications**:
- Plans/reports/summaries are LOCAL ONLY
- No git history of plan completion
- Archival must be file-system based, not git-based
- Completed plans invisible to team unless shared manually

**Current Behavior**:
- Active plans: specs/{topic}/plans/*.md
- Completed plans: SAME location (no archival)
- Summaries: specs/{topic}/summaries/*.md (alongside active)

**Gap**: No distinction between active and completed plans in directory structure.

## Recommendations

### 1. Implement Checkpoint-Triggered Archival

**Trigger**: When checkpoint status transitions to "completed"
**Action**: Move plan to archived/ subdirectory within topic
**Implementation**: Hook in save_checkpoint() or via post-completion callback

**Structure**:
```
specs/{NNN_topic}/
├── plans/          # Active plans
├── archived/       # Completed plans (new subdirectory)
│   └── YYYY-MM-DD_NNN_plan_name.md
├── summaries/      # Implementation summaries (keep current location)
└── reports/        # Research reports (keep current location)
```

**Benefits**:
- Clear separation of active vs completed work
- Preserves gitignore compliance (archived/ would also be gitignored)
- Enables easy discovery of completed plans
- Maintains co-location within topic directory

### 2. Create Archival Utility Library

**File**: `.claude/lib/plan-archival.sh`

**Functions**:
- `archive_completed_plan(plan_path)`: Move to archived/ with timestamp
- `get_plan_status(plan_path)`: Determine if plan is completed (via checkbox analysis)
- `list_archived_plans(topic_dir)`: Discover archived plans for topic
- `restore_archived_plan(archived_path)`: Move back to active plans/

**Integration Points**:
- /implement: After final phase completion
- /coordinate: After state machine reaches "complete"
- /document: After summary generation
- Manual: User-invoked archival for abandoned plans

### 3. Add Status Field to Plan Metadata

**Enhancement**: Include status in plan frontmatter

```markdown
## Metadata
- **Status**: active | completed | archived | abandoned
- **Completed Date**: YYYY-MM-DD (if status=completed)
- **Summary**: specs/{topic}/summaries/NNN_summary.md
```

**Benefits**:
- Explicit status tracking independent of location
- Supports queries for "show all active plans"
- Enables validation that archived/ contains only completed/abandoned

### 4. Enhance Checkpoint Cleanup

**Current**: Checkpoints persist indefinitely
**Proposed**: Auto-cleanup for completed workflows

**Logic**:
```bash
# After successful plan archival
if [ "$status" = "completed" ] && [ "$age_days" -gt 30 ]; then
  checkpoint_delete "$workflow_type" "$project_name"
fi
```

**Benefits**:
- Reduces checkpoint clutter
- 30-day grace period for resumability
- Aligns checkpoint lifecycle with plan archival

### 5. Summary-Triggered Archival Workflow

**Pattern**: /document command triggers archival after summary generation

**Workflow**:
1. User runs: `/document "workflow complete"`
2. Command detects all phases marked complete
3. Generates implementation summary
4. Triggers plan archival: `archive_completed_plan "$PLAN_PATH"`
5. Updates checkpoint status: `completed`
6. Returns: "Summary created, plan archived to archived/YYYY-MM-DD_plan.md"

**Benefits**:
- Explicit archival point (summary = completion)
- User-initiated, not automatic (safety)
- Maintains summary alongside archived plan

### 6. Add /list-archived Command

**Purpose**: Discover completed plans across topics

**Usage**: `/list-archived [search-pattern]`

**Output**:
```
Archived Plans:
  specs/042_auth/archived/2025-11-01_001_user_auth.md (summary: 001)
  specs/067_artifact/archived/2025-10-18_001_compliance.md (summary: 001)
  Total: 2 archived plans
```

**Implementation**: Glob search for `specs/*/archived/*.md`

### 7. Align with Existing /list Commands

**Current Commands**:
- `/list plans`
- `/list reports`
- `/list summaries`

**Enhancement**: Add `--status` filter

**Examples**:
- `/list plans --status active` (default, excludes archived/)
- `/list plans --status archived` (shows archived/ only)
- `/list plans --status all` (shows both)

**Benefits**: Unified interface, backward compatible

### 8. Preserve Gitignore Compliance

**Requirement**: Archived plans must remain gitignored (local-only)

**Validation**:
```bash
# Test archived/ directory is gitignored
git check-ignore specs/test/archived/plan.md
# Should output: specs/test/archived/plan.md (gitignored)
```

**Rationale**: Plans contain local paths, workflow specifics, may be incomplete

**Exception**: Debug reports stay committed (unchanged)

## References

### Files Analyzed

1. `.claude/lib/checkpoint-utils.sh:1-1006` - Checkpoint schema, lifecycle functions, safe resume conditions
2. `.claude/docs/concepts/directory-protocols.md:1-150` - Topic-based organization, artifact lifecycle, gitignore compliance
3. `.claude/specs/647_*/summaries/001_implementation_summary.md:1-567` - Complete summary structure example
4. `.claude/commands/implement.md:89-100` - Phase execution workflow, no archival logic
5. `.claude/commands/coordinate.md:1-150` - State machine initialization, terminal state handling
6. `.claude/agents/spec-updater.md:1-1076` - Artifact management operations, cleanup policy mentions
7. `.gitignore:76-96` - Gitignore rules for .claude/ and specs/ directories
8. `.claude/specs/483_*/plans/001_*.md:1-80` - Historical archival cleanup (removal of archived references)

### Glob Pattern Results

- **Summaries Found**: 69 files across 69 topics (pattern: `**/summaries/*.md`)
- **Topic Directories**: 170+ topics in `.claude/specs/`
- **No Archived Subdirectories**: Zero `archived/` subdirectories found in any topic

### Key Functions Referenced

- `save_checkpoint()` - `.claude/lib/checkpoint-utils.sh:54-186`
- `restore_checkpoint()` - `.claude/lib/checkpoint-utils.sh:188-244`
- `check_safe_resume_conditions()` - `.claude/lib/checkpoint-utils.sh:765-834`
- `ensure_artifact_directory()` - `.claude/lib/unified-location-detection.sh` (referenced in directory-protocols.md:79)

### Search Patterns Used

- Archive mentions: `archive|archiv` (case-insensitive)
- Completion detection: `completed|completion|finished|done`
- Plan lifecycle: `plan.*lifecycle|plan.*status|plan.*complete`
- Cleanup patterns: `cleanup|clean|remove.*plan|delete.*plan`
