# TODO.md Update Implementation Analysis

## Metadata
- **Date**: 2025-12-01
- **Agent**: research-specialist
- **Topic**: Commands that create/modify plans or reports and TODO.md update patterns
- **Report Type**: codebase analysis

## Executive Summary

Only the `/todo` command currently updates TODO.md. No other commands that create or modify plans or reports have TODO.md update functionality implemented. The `/todo` command provides comprehensive TODO.md management but requires manual invocation. Commands emit artifact creation signals (`PLAN_CREATED`, `REPORT_CREATED`) but do not leverage these for automatic TODO.md updates. A clear standard exists for TODO organization but not for command-level TODO integration.

## Findings

### 1. Current TODO.md Update Implementation

**Commands that currently update TODO.md:**

1. **`/todo` Command** - `/home/benjamin/.config/.claude/commands/todo.md`
   - **Primary responsibility**: Scan specs/ directories and update TODO.md with current project status
   - **Implementation pattern**:
     - Scans all topic directories in `.claude/specs/`
     - Delegates classification to `todo-analyzer` agent
     - Generates complete TODO.md using 7-section hierarchy
     - Preserves Backlog and Saved sections (manual curation)
   - **Update mechanism**: Complete regeneration of auto-managed sections
   - **Lines**: 3, 17, 20, 32, 106, 504, 1252, 1265
   - **Status**: ✓ Fully implemented

**Commands that DO NOT update TODO.md:**

1. **`/plan`** - Creates plans but does not update TODO.md
   - Emits `PLAN_CREATED` signal (line 1210: `echo "PLAN_CREATED: $PLAN_PATH"`)
   - Signal includes absolute path to created plan
   - No TODO.md update logic present

2. **`/research`** - Creates research reports but does not update TODO.md
   - Emits `REPORT_CREATED` signal (line 994: `echo "REPORT_CREATED: $LATEST_REPORT"`)
   - Signal includes absolute path to report
   - No TODO.md update logic present

3. **`/build`** - Implements plans but does not update TODO.md
   - No artifact creation signals (delegates to implementer-coordinator)
   - No TODO.md update logic present
   - Could update status from "Not Started" → "In Progress" → "Completed"

4. **`/repair`** - Creates repair plans and reports
   - Emits `PLAN_CREATED` signal (line 1450)
   - Emits `REPORT_CREATED` signal (line 522)
   - No TODO.md update logic present

5. **`/debug`** - Creates debug reports and plans
   - Emits `DEBUG_REPORT_CREATED` signal (line 1469)
   - Emits `PLAN_CREATED` signal (line 964)
   - Emits `REPORT_CREATED` signal (line 677)
   - No TODO.md update logic present

6. **`/revise`** - Revises existing plans
   - Emits `REPORT_CREATED` signal (line 640)
   - No TODO.md update logic present

7. **`/errors`** - Creates error analysis reports
   - Emits `REPORT_CREATED` signal (line 709)
   - No TODO.md update logic present

### 2. Artifact Creation Signal Pattern

**Pattern discovered**: Commands emit standardized completion signals but do not consume them.

**Signal formats found:**

```bash
# Plan creation
echo "PLAN_CREATED: $PLAN_PATH"

# Report creation
echo "REPORT_CREATED: $REPORT_PATH"

# Debug-specific
echo "DEBUG_REPORT_CREATED: $PLAN_PATH"
```

**Commands emitting signals:**
- `/plan`: PLAN_CREATED (line 1210)
- `/research`: REPORT_CREATED (line 994)
- `/repair`: PLAN_CREATED (line 1450), REPORT_CREATED (line 522)
- `/debug`: DEBUG_REPORT_CREATED (line 1469), PLAN_CREATED (line 964), REPORT_CREATED (line 677)
- `/revise`: REPORT_CREATED (line 640)
- `/errors`: REPORT_CREATED (line 709)

**Signal purpose**: These signals enable buffer-opener hooks and orchestrator detection, but are not currently used for TODO.md updates.

### 3. Documentation Standards Review

**TODO Organization Standards** - `/home/benjamin/.config/.claude/docs/reference/standards/todo-organization-standards.md`

**Standard exists for**: ✓
- 7-section hierarchy (In Progress, Not Started, Research, Saved, Backlog, Abandoned, Completed)
- Checkbox conventions (`[ ]` vs `[x]`)
- Entry format with plan paths and artifacts
- Date grouping for Completed section
- Backlog/Saved preservation policy

**Standard does NOT exist for**: ✗
- Command-level TODO.md update integration
- When/how commands should update TODO.md
- Automatic vs manual TODO.md updates
- Signal-based TODO.md triggering

**Usage metadata** (lines 325-342):
```markdown
## Usage by Commands

### /todo Command
- Scans specs/ directories
- Classifies plans by status
- Updates TODO.md (preserving Backlog)
- Includes related artifacts

### /build Command
- May update TODO.md on completion
- Moves entries from "Not Started" to "In Progress"
- On completion, moves to "Completed" section

### /plan Command
- Creates new entries in "Not Started" section
- Follows entry format standards
```

**Finding**: Documentation describes *intended* behavior for `/build` and `/plan` but actual implementation is missing.

### 4. Library Support for TODO Updates

**Library**: `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh`

**Functions available:**
1. `scan_project_directories()` - Discover all topic directories
2. `find_plans_in_topic()` - Find plan files in a topic
3. `find_related_artifacts()` - Find reports/summaries
4. `extract_plan_metadata()` - Extract title, description, status from plan

**Version**: 1.0.0 (line 20)

**Commands using this library**: Only `/todo` (line 7)

**Finding**: Reusable library exists but is not leveraged by other commands. Functions are well-suited for incremental TODO.md updates.

### 5. Agent Behavior Analysis

**Agent files reviewed:**
- `/home/benjamin/.config/.claude/agents/research-specialist.md`
- `/home/benjamin/.config/.claude/agents/plan-architect.md` (via commands)

**Finding**: Agents do not have TODO.md update responsibilities. This is appropriate - TODO.md updates should be command-level, not agent-level.

**Agent completion signals**: Agents use different return protocols:
- research-specialist: `REPORT_CREATED: [path]`
- plan-architect: `PLAN_CREATED: [path]`

These signals are consumed by commands and re-emitted, but not used to trigger TODO.md updates.

### 6. Current Backlog References

**From TODO.md** (lines 36-37):
```markdown
- Make commands update TODO.md automatically
- Make all relevant commands update TODO.md
```

**Finding**: User has already identified this gap and added it to Backlog. This research validates the need.

**Research entry** (line 22):
```markdown
- [ ] **Command TODO Tracking Integration** - Command-level TODO.md tracking integration spec [.claude/specs/990_commands_todo_tracking_integration/]
```

**Finding**: A research-only spec exists for this exact topic (990_commands_todo_tracking_integration). This report should complement or supersede that research.

### 7. Implementation Patterns Analysis

**Pattern 1: Complete Regeneration** (used by `/todo`)
- Scan all specs/ directories
- Classify all plans
- Generate complete TODO.md
- Preserve manual sections (Backlog, Saved)

**Pros**: Guaranteed consistency, handles renames/moves
**Cons**: Requires full scan, slower, loses manual tweaks

**Pattern 2: Incremental Update** (not currently implemented)
- Add entry when plan created
- Update entry when status changes
- Remove entry when plan deleted

**Pros**: Fast, minimal I/O, preserves all content
**Cons**: Requires locking, more complex, can drift from reality

**Pattern 3: Signal-Triggered Scan** (hybrid, not implemented)
- Commands emit artifact signals
- Signal triggers targeted `/todo` scan for that topic
- Update only affected section

**Pros**: Balances speed and consistency, leverages existing signals
**Cons**: Requires signal handling infrastructure

### 8. Standards Gaps Identified

**Missing standards:**

1. **Command TODO Integration Standard**
   - Which commands should update TODO.md?
   - When should updates occur (immediate vs deferred)?
   - What update mechanism (incremental vs full scan)?
   - How to handle concurrent updates?

2. **Artifact Signal Protocol**
   - Should signals trigger TODO.md updates?
   - Signal consumption and routing
   - Error handling for failed updates

3. **TODO.md Update API**
   - Function signatures for incremental updates
   - Locking/concurrency primitives
   - Validation and rollback procedures

4. **Command Completion Workflow**
   - Post-command cleanup steps
   - Artifact registration protocol
   - Status synchronization requirements

## Recommendations

### 1. Create Comprehensive TODO Integration Standard

**Location**: `.claude/docs/reference/standards/command-todo-integration.md`

**Content should define:**
- Which commands MUST update TODO.md (plan, build, repair, debug, revise)
- Which commands SHOULD NOT (research - research-only entries handled by /todo scan)
- Update timing (immediate vs next /todo scan)
- Mechanism selection guide (incremental vs signal-triggered vs manual)
- Concurrency and locking requirements

**Priority**: HIGH - Foundational for implementation

### 2. Implement Signal-Triggered TODO Updates

**Approach**: Hybrid pattern combining existing signals with targeted scans

**Implementation steps:**
1. Extend `/todo` to accept `--topic <NNN_topic_name>` flag for targeted updates
2. Add `update_todo_for_topic()` function to todo-functions.sh library
3. Commands emit signals AND call `/todo --topic $TOPIC_NAME` after artifact creation
4. Use file locking to prevent concurrent TODO.md updates

**Commands to modify:**
- `/plan`: Add TODO update after PLAN_CREATED signal
- `/build`: Add TODO update for status transitions (Not Started → In Progress → Completed)
- `/repair`: Add TODO update after plan creation
- `/debug`: Add TODO update after plan creation

**Priority**: MEDIUM - Improves UX but not critical

### 3. Document Existing /todo Capabilities

**Update**: `.claude/docs/guides/commands/todo-command-guide.md`

**Add sections:**
- "Integration with Other Commands" (how other commands should trigger /todo)
- "Targeted Update Mode" (--topic flag usage)
- "Concurrent Update Safety" (locking mechanism)

**Priority**: LOW - Documentation improvement

### 4. Expand todo-functions.sh Library

**New functions needed:**
```bash
# Update TODO.md for a specific topic (incremental)
update_todo_entry() {
  local topic_name="$1"
  local action="$2"  # "add", "update", "remove"
  # Implementation: Lock, update, unlock
}

# Acquire TODO.md lock
acquire_todo_lock() {
  # Implementation: flock or mkdir-based lock
}

# Release TODO.md lock
release_todo_lock() {
  # Implementation: Remove lock file
}
```

**Priority**: MEDIUM - Enables incremental updates

### 5. Revise CLAUDE.md Standards References

**Update**: `/home/benjamin/.config/CLAUDE.md` (lines 329-342)

**Changes needed:**
- Remove "May update TODO.md on completion" from /build (replace with "DOES update")
- Remove "Creates new entries in 'Not Started' section" from /plan (replace with "DOES create")
- Add explicit statement: "Commands delegate to /todo for updates"

**Priority**: LOW - Consistency improvement

## References

### Command Files Analyzed
- `/home/benjamin/.config/.claude/commands/todo.md` - Lines 3, 17, 20, 32, 73, 106, 504, 599, 1252, 1265
- `/home/benjamin/.config/.claude/commands/plan.md` - Lines 632, 943, 1206, 1210
- `/home/benjamin/.config/.claude/commands/research.md` - Lines 614, 988, 994
- `/home/benjamin/.config/.claude/commands/build.md` - Lines 1-300 (reviewed, no TODO logic found)
- `/home/benjamin/.config/.claude/commands/repair.md` - Lines 522, 1083, 1446, 1450
- `/home/benjamin/.config/.claude/commands/debug.md` - Lines 677, 964, 1465, 1469
- `/home/benjamin/.config/.claude/commands/revise.md` - Line 640
- `/home/benjamin/.config/.claude/commands/errors.md` - Lines 558, 705, 709
- `/home/benjamin/.config/.claude/commands/README.md` - Line 423

### Documentation Files Analyzed
- `/home/benjamin/.config/.claude/docs/reference/standards/todo-organization-standards.md` - Complete file (383 lines)
- `/home/benjamin/.config/.claude/TODO.md` - Lines 1-52 (current state)
- `/home/benjamin/.config/CLAUDE.md` - Section on TODO.md usage

### Library Files Analyzed
- `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh` - Lines 1-200 (functions and patterns)

### Agent Files Analyzed
- `/home/benjamin/.config/.claude/agents/research-specialist.md` - Complete behavioral file
- Agent references in command files (plan-architect, todo-analyzer)
