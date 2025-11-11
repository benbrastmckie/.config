# Plan Archival Standards and Patterns Research Report

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: Standards in .claude/docs/ for plan archival, completion criteria, and gitignore patterns
- **Report Type**: codebase analysis
- **Complexity**: 2 (moderate - multiple documentation sources, established patterns)

## Executive Summary

This research reveals that the codebase currently has **NO formal plan archival system**. Plans follow a "keep indefinitely" retention policy with gitignore patterns preventing commit to version control. Plan completion is determined by implementation summary creation (42 existing summaries vs 131 plans = 32% completion rate), with state machine tracking workflow completion via STATE_COMPLETE. The system follows a fail-fast, clean-break philosophy that explicitly rejects archival directories beyond git history, relying instead on summaries and git commits for historical record.

Key finding: No post-completion hooks exist in /implement or /coordinate for automatic archival. Plans remain in active topic directories indefinitely, with manual cleanup implied but not documented or automated.

## Findings

### Current State Analysis

#### No Formal Archival Infrastructure

**Evidence from codebase search**:
- Zero references to "plan archival" in documentation (`.claude/docs/concepts/directory-protocols.md`, `.claude/docs/concepts/development-workflow.md`)
- No archival commands or utilities in `.claude/commands/` or `.claude/lib/`
- No archival hooks in `/implement` or `/coordinate` command files
- One indirect reference in backup-retention-policy.md:38 suggests keeping "one backup if plan archived for reference" but provides no archival mechanism

**Search results**: `grep -r "plan.*archiv" /home/benjamin/.config/.claude/docs --include="*.md" -i` returns only backup retention context, not archival procedures

**Implication**: Plans accumulate indefinitely in topic directories without lifecycle management beyond creation and summary generation

#### Retention Policy: Indefinite Preservation

From `.claude/docs/concepts/directory-protocols.md` (lines 180-198):

```markdown
### Core Planning Artifacts
**Location**: `reports/`, `plans/`, `summaries/`

**Lifecycle**:
- Created during: Planning, research, documentation phases
- Preserved: Indefinitely (reference material)
- Cleaned up: Never
- Gitignore: YES (local working artifacts)
```

Retention table (lines 525-534):

| Artifact Type | Retention Policy | Cleanup Trigger | Automated |
|---------------|------------------|-----------------|-----------|
| **Reports** | Indefinite | Never | No |
| **Plans** | Indefinite | Never | No |
| **Summaries** | Indefinite | Never | No |

**Key insight**: Plans are NOT treated as temporary artifacts like scripts (0 days retention) or backups (30 days). They are permanent reference material.

#### Actual Artifact Count Analysis

**Real-world data** (current system state):
- Plans: 131 files in `.claude/specs/*/plans/*.md`
- Summaries: 42 files in `.claude/specs/*/summaries/*.md`
- Completion rate: 32% (42/131)

**Interpretation**:
- 89 plans (68%) do not have implementation summaries
- These plans are either:
  1. Incomplete (implementation in progress or abandoned)
  2. Complete but summary not created
  3. Complete but used older workflow that didn't create summaries

**No cleanup mechanism exists** for incomplete/abandoned plans - they accumulate indefinitely

### Plan Completion Criteria

#### State Machine Definition

From `.claude/lib/workflow-state-machine.sh` (lines 40-44, 72-73):

```bash
readonly STATE_COMPLETE="complete"           # Phase 7: Finalization, cleanup

# Terminal state for this workflow (determined by scope)
TERMINAL_STATE="${STATE_COMPLETE}"
```

Scope-based terminal states (lines 109-120):

```bash
case "$WORKFLOW_SCOPE" in
  research-only)
    TERMINAL_STATE="$STATE_RESEARCH"
    ;;
  research-and-plan)
    TERMINAL_STATE="$STATE_PLAN"
    ;;
  full-implementation)
    TERMINAL_STATE="$STATE_COMPLETE"
    ;;
  debug-only)
    TERMINAL_STATE="$STATE_DEBUG"
    ;;
esac
```

**Key criterion**: Plan reaches completion when state machine transitions to workflow-specific terminal state

#### Implementation Summary as Completion Signal

From `.claude/docs/concepts/development-workflow.md` (lines 1-9):

```markdown
# Development Workflow

## Planning and Implementation

1. Create research reports in `specs/reports/` for complex topics
2. Generate implementation plans in `specs/plans/` based on research
3. Execute plans phase-by-phase with testing and commits
4. Generate summaries in `specs/summaries/` linking plans to code
5. Adaptive planning automatically adjusts plans during implementation
```

Spec updater checklist (lines 33-39):

```markdown
**Spec Updater Checklist** (included in all plan templates):
- Ensure plan is in topic-based directory structure
- Create standard subdirectories if needed
- Update cross-references if artifacts moved
- Create implementation summary when complete
- Verify gitignore compliance (debug/ committed, others ignored)
```

**Completion indicator**: Implementation summary creation marks plan completion

From `.claude/commands/supervise.md.backup-20251027-phase0` (lines 2082-2138):

```markdown
**Objective**: Create workflow summary linking plan, research, and implementation.

**Pattern**: Invoke doc-writer agent → Verify summary created → Update research reports

**Execution Condition**: Phase 6 only executes if implementation occurred (Phase 3 ran)
```

**Critical finding**: Summary creation is conditional on implementation phase execution. Research-only and research-and-plan workflows do NOT create summaries (lines 2199, 2211).

#### Checkpoint Schema Completion Tracking

From `.claude/lib/checkpoint-utils.sh` (lines 40-44, checkpoint schema v2.0):

```bash
# Wave Tracking Fields (for parallel execution - Phase 2):
# - wave_results: Detailed results for each completed/in-progress wave
#   Example: {
#     "1": {"phases": [1], "status": "completed", "duration_ms": 185000},
#     "2": {"phases": [2, 3], "status": "in_progress", "parallel": true}
#   }
```

**Completion tracking mechanism**: Checkpoint files (`.claude/data/checkpoints/`) record workflow state including completed phases, wave results, and terminal state reached

**Observable completion**: Checkpoint exists with `current_state` matching `TERMINAL_STATE` for the workflow scope

#### No Post-Completion Hooks

**Search results for hooks**: `grep -r "hook|post-completion|after.*complete" .claude/commands/*.md -i -C 2`

**Finding**: No post-completion hooks found in:
- `/implement` command (executes plan phases, creates commits)
- `/coordinate` command (orchestrates workflow phases)
- `/orchestrate` command (full workflow coordination)

**Only hook reference**: `.claude/commands/templates/test-suite.yaml:76` mentions "Set up pre-commit hooks to require passing tests" (testing context, not plan lifecycle)

**Implication**: No automatic archival, cleanup, or state transitions occur after plan completion. Manual intervention required.

### Gitignore Patterns

#### Current Configuration

From `.gitignore` (lines 75-87):

```gitignore
**/CLAUDE.md
**/.claude/
!.claude/
!.claude/commands/
!.claude/commands/*.md
# Archive directory (local only, not tracked)
.claude/archive/
# Topic-based specs organization (added by /migrate-specs)
# Gitignore all specs subdirectories
specs/*/*
# Un-ignore debug subdirectories within topics
!specs/*/debug/
!specs/*/debug/**
```

**Pattern**: Gitignore all specs subdirectories (`specs/*/*`) EXCEPT debug directories

**Effect on plans**:
- `specs/*/plans/*.md` - GITIGNORED (not committed)
- `specs/*/reports/*.md` - GITIGNORED (not committed)
- `specs/*/summaries/*.md` - GITIGNORED (not committed)
- `specs/*/debug/*.md` - COMMITTED (project history)

#### Compliance Rules

From `.claude/docs/concepts/directory-protocols.md` (lines 303-315):

| Artifact Type | Committed to Git | Reason |
|---------------|------------------|--------|
| `debug/` | YES | Project history, issue tracking |
| `plans/` | NO | Local working artifacts |
| `reports/` | NO | Local working artifacts |
| `summaries/` | NO | Local working artifacts |
| `scripts/` | NO | Temporary investigation |
| `outputs/` | NO | Regenerable test results |
| `artifacts/` | NO | Operational metadata |
| `backups/` | NO | Temporary recovery files |

**Rationale** (lines 236-240):

```markdown
**Why Committed**:
Debug reports are valuable project history:
- Track recurring issues
- Document solutions for future reference
- Enable team knowledge sharing
- Support post-mortem analysis
```

**Plans NOT committed because**: Treated as "local working artifacts" rather than permanent project history

#### Archive Directory Exception

From `.gitignore` (line 81):

```gitignore
# Archive directory (local only, not tracked)
.claude/archive/
```

**Purpose**: Documented archived content exists in `.claude/archive/` but is gitignored

**Current archive contents**:
- `.claude/archive/lib/cleanup-2025-10-26/` - 25 archived library scripts
- `.claude/docs/archive/` - Archived documentation files

**No plan archival subdirectory exists**: `.claude/archive/plans/` does not exist in current system

#### Fail-Fast and Clean-Break Philosophy

From `CLAUDE.md` (lines 171-192):

```markdown
### Clean-Break and Fail-Fast Approach

This configuration maintains a **clean-break, fail-fast evolution philosophy**:

**Clean Break**:
- Delete obsolete code immediately after migration
- No deprecation warnings, compatibility shims, or transition periods
- No archives beyond git history
- Configuration and code describe what they are, not what they were

**Avoid Cruft**:
- No historical commentary in active files
- No backward compatibility layers
- No migration tracking spreadsheets (use git commits)
- No "what changed" documentation (use git log)

**Rationale**: Configuration should focus on being what it is without extra
commentary on top. Clear, immediate failures are better than hidden complexity
masking problems.
```

**Critical principle**: "No archives beyond git history"

**Implication for plan archival**: Philosophy OPPOSES formal archival directories, favoring git commits and summaries as historical record

### Backup Retention Policy (Related Context)

From `.claude/docs/reference/backup-retention-policy.md` (lines 33-40):

```markdown
### Implementation Plans (`.claude/specs/NNN_topic/plans/`)

**Retention Policy**:
- Keep plan file backups: **Until plan completion**
- Remove after implementation summary created
- Keep one backup if plan archived for reference

**Rationale**: Plans are iteratively refined. Backups enable rollback during
active development. Once complete and summarized, original plan serves as
historical record.
```

**Key insight**: Backup retention policy mentions archival ("Keep one backup if plan archived for reference") but no archival mechanism documented

**Cleanup trigger**: "Remove after implementation summary created" suggests summary creation = completion signal

### Research-Only and Research-and-Plan Workflows

From `.claude/commands/supervise.md.backup-20251027-phase0` (lines 2196-2213):

**Example 1: Research-only workflow**:
```bash
# - Scope detected: research-only
# - Phases executed: 0, 1
# - Artifacts: 2-3 research reports
# - No plan, no implementation, no summary
```

**Example 2: Research-and-plan workflow (MOST COMMON)**:
```bash
# - Scope detected: research-and-plan
# - Phases executed: 0, 1, 2
# - Artifacts: 4 research reports + 1 implementation plan
# - No implementation, no summary (per standards)
# - Plan ready for execution
```

**Critical finding**: Most workflows (research-and-plan) do NOT create summaries because implementation doesn't occur

**Completion criteria for research-and-plan**:
- Terminal state: STATE_PLAN (not STATE_COMPLETE)
- No summary created
- Plan file is final artifact
- Plan remains in topic directory indefinitely (no archival, no cleanup)

## Recommendations

### 1. Document "No Archival" as Intentional Design

**Recommendation**: Create explicit documentation stating that plan archival is intentionally absent, aligning with fail-fast/clean-break philosophy

**Rationale**:
- Current silence on archival creates ambiguity (is it missing or intentional?)
- Fail-fast philosophy explicitly opposes archival directories
- Summaries and git commits provide historical record
- Documentation prevents future attempts to "fix" non-existent archival

**Suggested location**: `.claude/docs/concepts/plan-lifecycle.md` (new file)

**Content outline**:
```markdown
# Plan Lifecycle Management

## No Archival System (Intentional)

This project does NOT implement plan archival directories. This is intentional:

**Philosophy**: Clean-break approach favors git history over archival
**Historical Record**: Implementation summaries document completed work
**Cleanup**: Plans remain in topic directories indefinitely (manual removal if needed)
**Rationale**: Summaries + git commits provide sufficient historical context

## Completion Criteria
- Full implementation: Implementation summary created
- Research-and-plan: Plan file created (terminal state)
- Retention: Indefinite (gitignored, local artifacts)
```

### 2. Add Optional Manual Cleanup Documentation

**Recommendation**: Document manual cleanup procedures for completed plans (optional, not automated)

**Rationale**:
- 131 plans vs 42 summaries = 89 plans without completion confirmation
- No automatic cleanup means manual intervention required for disk space management
- Users may want to remove old/abandoned plans

**Suggested location**: `.claude/docs/guides/plan-cleanup-guide.md` (new file)

**Content outline**:
```markdown
# Plan Cleanup Guide (Manual)

## When to Clean Up Plans

- Plan implementation completed (summary created)
- Plan abandoned (no longer relevant)
- Disk space management needed

## Identification Commands

# Find plans without summaries
for topic in specs/*/; do
  plan_count=$(ls -1 "$topic/plans/"*.md 2>/dev/null | wc -l)
  summary_count=$(ls -1 "$topic/summaries/"*.md 2>/dev/null | wc -l)
  if [ "$plan_count" -gt 0 ] && [ "$summary_count" -eq 0 ]; then
    echo "No summary: $topic"
  fi
done

## Manual Removal

# Remove specific plan (after verification)
rm -rf specs/042_topic_name/

# Keep debug/ history (don't delete topic if debug reports exist)
if [ -d "specs/042_topic/debug" ] && [ "$(ls -A specs/042_topic/debug)" ]; then
  echo "WARNING: Debug reports exist - archive topic instead of deleting"
fi
```

### 3. Enhance Completion Criteria Documentation

**Recommendation**: Consolidate completion criteria documentation from scattered sources into single authoritative reference

**Current gaps**:
- Completion criteria scattered across 5+ files
- No single "what constitutes a completed plan?" reference
- State machine definition separate from workflow documentation
- Summary creation conditional logic not clearly documented

**Suggested location**: `.claude/docs/reference/completion-criteria.md` (new file)

**Content outline**:
```markdown
# Plan Completion Criteria

## Full Implementation Workflow

**Terminal State**: STATE_COMPLETE
**Completion Artifacts**:
1. Implementation summary in specs/{topic}/summaries/
2. Checkpoint with current_state = STATE_COMPLETE
3. Git commits for all phases
4. Test suite passing

**Verification**: Summary file exists and links plan to implementation

## Research-and-Plan Workflow

**Terminal State**: STATE_PLAN
**Completion Artifacts**:
1. Plan file in specs/{topic}/plans/
2. Checkpoint with current_state = STATE_PLAN
3. NO summary (per standards - no implementation occurred)

**Verification**: Plan file exists and references research reports

## Research-Only Workflow

**Terminal State**: STATE_RESEARCH
**Completion Artifacts**:
1. Research reports in specs/{topic}/reports/
2. Checkpoint with current_state = STATE_RESEARCH
3. NO plan, NO summary

**Verification**: 2-4 research reports created
```

### 4. Gitignore Pattern Documentation Enhancement

**Recommendation**: Document gitignore rationale more explicitly in directory-protocols.md

**Current gap**: Gitignore compliance section explains WHAT is gitignored but not WHY plans are local-only

**Suggested enhancement** (add to `.claude/docs/concepts/directory-protocols.md` after line 315):

```markdown
### Why Plans Are Gitignored

Plans are treated as **local working artifacts** rather than committed project history:

**Rationale**:
1. **Ephemeral nature**: Plans change frequently during implementation
2. **Implementation summaries are canonical**: Summaries document completed work
3. **Git history provides context**: Commit messages capture implementation progression
4. **Avoid version control churn**: Plan edits don't clutter git history
5. **Fail-fast philosophy**: Summaries + git commits sufficient for historical record

**Exception**: Debug reports ARE committed because they document permanent issue history

**Historical Record**:
- Completed work: Implementation summaries (gitignored, local reference)
- Permanent history: Git commits + debug reports (committed)
```

### 5. Add Post-Completion Optional Hook Points

**Recommendation**: Document optional post-completion hook points in /implement and /coordinate (not automated, user-configurable)

**Rationale**:
- Some users may want custom post-completion actions
- Hook points enable extensibility without modifying core commands
- Optional nature aligns with fail-fast philosophy (no hidden automation)

**Suggested location**: `.claude/docs/guides/workflow-hooks.md` (new file)

**Content outline**:
```markdown
# Workflow Hooks (Optional)

## Post-Completion Hook Points

### /implement Command

After implementation summary created, optionally source:
`.claude/hooks/post-implement.sh`

**Example use cases**:
- Move completed plan to archive directory
- Generate project documentation
- Create git tag for release
- Trigger CI/CD pipeline

### /coordinate Command

After STATE_COMPLETE reached, optionally source:
`.claude/hooks/post-coordinate.sh`

**Hook signature**:
```bash
# post-coordinate.sh receives:
# - PLAN_PATH
# - SUMMARY_PATH
# - WORKFLOW_SCOPE
# - TERMINAL_STATE

# Example: Archive completed plan
if [ "$TERMINAL_STATE" = "$STATE_COMPLETE" ]; then
  mkdir -p .claude/archive/plans/
  cp "$PLAN_PATH" ".claude/archive/plans/$(basename $PLAN_PATH)"
fi
```

**Note**: Hooks are NOT executed by default (user must create them)
```

### 6. State Machine Documentation Cross-Reference

**Recommendation**: Add cross-references between workflow-state-machine.sh and completion criteria documentation

**Current gap**: State machine library defines STATE_COMPLETE but doesn't reference how it relates to plan completion

**Suggested enhancement** (add to `.claude/lib/workflow-state-machine.sh` after line 44):

```bash
# State COMPLETE indicates workflow reached terminal state for scope
# For plan completion criteria, see: .claude/docs/reference/completion-criteria.md
# For summary creation conditions, see: .claude/docs/concepts/development-workflow.md
```

### 7. Summary Creation Automation Consistency

**Recommendation**: Document summary creation as MANDATORY for full-implementation workflows (currently inconsistent)

**Current inconsistency**:
- Spec updater checklist says "Create implementation summary when complete"
- /supervise only creates summary if Phase 3 (implementation) ran
- No enforcement mechanism for summary creation

**Suggested enhancement** (add to `/implement` command after final phase):

```markdown
**FINAL STEP - Summary Creation Verification**

After all phases complete, verify implementation summary exists:

```bash
SUMMARY_PATH="$(dirname $PLAN_PATH)/../summaries/001_implementation_summary.md"

if [ ! -f "$SUMMARY_PATH" ]; then
  echo "WARNING: No implementation summary found at $SUMMARY_PATH"
  echo "Create summary via: /orchestrate (Phase 6) or manual doc-writer invocation"
  echo ""
  echo "Summary is REQUIRED for full-implementation workflows"
fi
```

**Note**: Verification only, not automatic creation (aligns with fail-fast philosophy)
```

## References

### Primary Sources (Complete Documentation)

1. `.claude/docs/concepts/directory-protocols.md` (1,045 lines)
   - Lines 180-198: Core planning artifacts lifecycle
   - Lines 303-315: Gitignore compliance table
   - Lines 525-534: Retention policies table
   - Lines 236-240: Debug reports commit rationale

2. `.claude/docs/concepts/development-workflow.md` (109 lines)
   - Lines 1-9: Planning and implementation workflow
   - Lines 33-39: Spec updater checklist
   - Lines 41-75: Artifact lifecycle details

3. `CLAUDE.md` (root configuration, 650+ lines)
   - Lines 171-192: Clean-break and fail-fast philosophy
   - Lines 187-192: Fallback types and fail-fast policy
   - Lines 194-202: Avoid cruft principles

4. `.gitignore` (96 lines)
   - Lines 75-87: Claude specs organization gitignore patterns
   - Line 81: Archive directory exception

5. `.claude/lib/workflow-state-machine.sh` (500+ lines)
   - Lines 40-44: STATE_COMPLETE definition
   - Lines 72-73: Terminal state initialization
   - Lines 109-120: Scope-based terminal states
   - Lines 463-464: Terminal state check function

### Secondary Sources (Supporting Evidence)

6. `.claude/docs/reference/backup-retention-policy.md` (230 lines)
   - Lines 33-40: Implementation plans backup retention
   - Lines 36-38: Plan completion and archival mention

7. `.claude/lib/checkpoint-utils.sh` (800+ lines)
   - Lines 1-49: Checkpoint schema v2.0 documentation
   - Lines 40-44: Wave results completion tracking

8. `.claude/commands/supervise.md.backup-20251027-phase0` (2,200+ lines)
   - Lines 2082-2138: Phase 6 summary creation
   - Lines 2196-2225: Workflow scope examples

9. `.claude/commands/coordinate.md.backup-phase1` (2,500+ lines)
   - Lines 442-447: Full implementation summary display
   - Lines 1523-1529: Standards compliance verification

### Codebase Statistics

10. Artifact counts (empirical data):
    - Plans: 131 files (`specs/*/plans/*.md`)
    - Summaries: 42 files (`specs/*/summaries/*.md`)
    - Completion rate: 32% (42/131)

### Standards and Philosophy Documents

11. `.claude/docs/reference/command_architecture_standards.md` (2,325 lines)
    - Referenced for fail-fast verification fallback patterns
    - Lines 419-462: Fail-fast policy relationship to verification

12. `.claude/docs/concepts/writing-standards.md` (referenced in CLAUDE.md)
    - Clean-break refactoring principles
    - Timeless writing standards

### Search Query Results

13. Archival pattern search: `grep -r "plan.*archiv" .claude/docs --include="*.md" -i`
    - Result: No formal archival documentation (only backup retention context)

14. Completion criteria search: `grep -r "plan.*complete|implementation.*complete" .claude/docs`
    - Result: 30+ references scattered across docs, no single authoritative source

15. Hook search: `grep -r "hook|post-completion|after.*complete" .claude/commands -i`
    - Result: Zero post-completion hooks in orchestration commands
