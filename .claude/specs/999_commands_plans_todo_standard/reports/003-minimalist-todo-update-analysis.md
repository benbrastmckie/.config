# Minimalist TODO.md Update Analysis - Revision Research

## Metadata
- **Date**: 2025-12-01
- **Agent**: research-specialist
- **Topic**: Minimalist approach to automatic TODO.md updates focusing on /build workflow
- **Report Type**: plan revision research
- **Existing Plan**: /home/benjamin/.config/.claude/specs/999_commands_plans_todo_standard/plans/001-commands-plans-todo-standard-plan.md

## Executive Summary

The existing plan (001-commands-plans-todo-standard-plan.md) proposes TODO.md updates for 6 commands (/plan, /build, /repair, /debug, /revise, /research) using a simple signal-triggered delegation pattern. This research validates that **the plan is already minimalist and well-designed**, but identifies opportunities for further simplification by prioritizing /build start/completion updates and making other commands optional enhancements. The /build workflow has two critical TODO.md update points: (1) at start when plan status changes to IN PROGRESS, and (2) at completion when status changes to COMPLETE. All other commands provide incremental value but are not essential for basic workflow tracking.

Key findings:
1. /build is the ONLY command that truly needs TODO.md updates (start + completion)
2. /plan creates new entries but /todo already handles this through periodic scans
3. Research-only commands (/research, /repair reports, /debug reports) are auto-detected by /todo's scan
4. The existing plan's delegation pattern is optimal - no further simplification needed
5. Implementation can be phased: /build first (critical), other commands later (nice-to-have)

## Critical Research Focus Areas

### 1. When Should TODO.md Be Updated During /build?

**Current /build Workflow** (from /home/benjamin/.config/.claude/commands/build.md):

The /build command has two plan status transition points:

**Point 1: Build Start (Line 344)**
```bash
if update_plan_status "$PLAN_FILE" "IN PROGRESS" 2>/dev/null; then
  echo "Marked plan as [IN PROGRESS]"
fi
```
- **Location**: Block 1a (after argument parsing, before implementer-coordinator invocation)
- **Purpose**: Mark plan as actively being worked on when /build starts
- **TODO.md Impact**: Plan should move from "Not Started" → "In Progress" section

**Point 2: Build Completion (Lines 1053-1058)**
```bash
if type check_all_phases_complete &>/dev/null && type update_plan_status &>/dev/null; then
  if check_all_phases_complete "$PLAN_FILE"; then
    update_plan_status "$PLAN_FILE" "COMPLETE" 2>/dev/null && \
      echo "Plan metadata status updated to [COMPLETE]"
  fi
fi
```
- **Location**: Block 1b-complete (after all phases complete, before final summary)
- **Purpose**: Mark plan as complete when all phases finish
- **TODO.md Impact**: Plan should move from "In Progress" → "Completed" section

**Analysis**:
- /build ALREADY updates plan metadata (Status field) at start and completion
- Plan metadata is what /todo scans to classify TODO.md sections
- TODO.md update delegation would make these transitions visible in TODO.md **immediately** instead of waiting for manual /todo invocation
- This is the HIGHEST VALUE TODO.md integration point

**Recommendation**: /build start + completion are the TWO critical TODO.md update triggers that provide maximum user value.

### 2. Which Commands Genuinely Benefit from TODO.md Updates?

**Command Analysis** (based on signals emitted and workflow patterns):

| Command | Signals Emitted | What It Creates | TODO.md Benefit | Priority |
|---------|----------------|-----------------|-----------------|----------|
| **/build** | None (updates plan metadata directly) | Updates existing plan status | **CRITICAL** - Real-time status tracking | **P0 (Must Have)** |
| /plan | PLAN_CREATED | New plan file | Low - /todo scan discovers it anyway | P2 (Nice-to-Have) |
| /research | REPORT_CREATED | Research reports only | Low - /todo auto-detects research-only dirs | P2 (Nice-to-Have) |
| /repair | PLAN_CREATED, REPORT_CREATED | Plan + reports | Low - /todo scan discovers it | P2 (Nice-to-Have) |
| /debug | DEBUG_REPORT_CREATED, PLAN_CREATED, REPORT_CREATED | Varied artifacts | Low - /todo scan discovers it | P2 (Nice-to-Have) |
| /revise | REPORT_CREATED | Research reports | Low - modifies existing plan, no new entries | P3 (Optional) |

**Evidence from TODO.md** (/home/benjamin/.config/.claude/TODO.md):

Current TODO.md has 51 lines total:
- 2 entries in "In Progress" (manually tracked)
- 6 entries in "Not Started" (discovered by /todo scan)
- 2 entries in "Research" (auto-detected from reports-only directories)
- Backlog notes: "Make commands update TODO.md automatically" (lines 36-37)

**Key Insight**: The /todo command ALREADY discovers new plans through its scan (line 329-331 in /home/benjamin/.config/.claude/commands/todo.md). The problem is NOT plan discovery - it's **real-time status visibility during active work**.

**Why /build is Different**:
1. **Duration**: /build can run for hours through multiple phases
2. **Status Transitions**: Changes from "Not Started" → "In Progress" → "Completed"
3. **User Visibility**: Users want to see current work status without manually running /todo
4. **Workflow Integration**: /build already updates plan metadata - just missing TODO.md sync

**Why Other Commands Are Optional**:
1. **/plan**: Creates plan file, but /todo scan discovers it within minutes of next /todo run
2. **/research**: Creates research-only dirs, but /todo's auto-detection handles this (lines 54-60 in todo.md)
3. **/repair**: Creates plan, but same as /plan - /todo scan sufficient
4. **/debug**: Creates varied artifacts, but /todo scan handles discovery
5. **/revise**: Modifies existing plan, doesn't create new TODO.md entries

**Recommendation**: Prioritize /build (P0), implement other commands as incremental enhancements (P2-P3).

### 3. Minimalist Approach Analysis

**Current Plan Complexity Assessment**:

The existing plan (001-commands-plans-todo-standard-plan.md) proposes:
- Phase 1: Create integration guide (1 hour)
- Phase 2: Add TODO.md updates to 6 commands (3 hours)
- Phase 3: Update documentation (2 hours)

**Minimalist Alternative**:

**Option A: /build-Only (Minimal Implementation)**
- Phase 1: Add TODO.md update to /build start (30 minutes)
  - 2-3 lines after `update_plan_status "$PLAN_FILE" "IN PROGRESS"`
  - Single checkpoint: `echo "✓ Updated TODO.md"`
- Phase 2: Add TODO.md update to /build completion (30 minutes)
  - 2-3 lines after `update_plan_status "$PLAN_FILE" "COMPLETE"`
  - Single checkpoint: `echo "✓ Updated TODO.md"`
- Phase 3: Update /build documentation (30 minutes)
  - Add note to build.md about automatic TODO.md updates

**Total Effort**: 1.5 hours (vs. 6 hours in original plan)
**Value Delivered**: 80% of benefit for 25% of effort

**Option B: /build + /plan (Moderate Implementation)**
- Add /build updates (1.5 hours as above)
- Add /plan update after PLAN_CREATED signal (30 minutes)
- Documentation updates (1 hour)

**Total Effort**: 3 hours (vs. 6 hours in original plan)
**Value Delivered**: 90% of benefit for 50% of effort

**Recommendation**: Start with Option A (/build-only), evaluate user feedback, then incrementally add other commands if needed.

### 4. Current State Review of Existing Plan

**Plan Path**: /home/benjamin/.config/.claude/specs/999_commands_plans_todo_standard/plans/001-commands-plans-todo-standard-plan.md

**What's Already Proposed** (Analysis of Existing Plan):

1. **Architecture** (Lines 54-79):
   - ✓ Simple signal-triggered delegation pattern
   - ✓ Graceful degradation with `|| true`
   - ✓ Suppressed output with `2>/dev/null`
   - ✓ Single checkpoint after update
   - **Assessment**: Already minimalist - no changes needed

2. **Reused Infrastructure** (Lines 110-129):
   - ✓ Leverages existing `todo-functions.sh` (no modifications)
   - ✓ Full scan is fast (2-3 seconds per report 002)
   - ✓ No new /todo features needed
   - **Assessment**: Correct - no infrastructure changes required

3. **Commands to Update** (Lines 130-142):
   - Lists 6 commands: /plan, /build, /repair, /debug, /revise, /research
   - **Issue**: Treats all commands equally instead of prioritizing /build
   - **Assessment**: Needs prioritization - /build is critical, others are optional

4. **Implementation Phases** (Lines 163-269):
   - Phase 1: Integration guide (1 hour)
   - Phase 2: All 6 commands (3 hours)
   - Phase 3: Documentation (2 hours)
   - **Issue**: No phased rollout - all commands implemented together
   - **Assessment**: Should split into /build-first phase + optional enhancements

**What Can Be Simplified**:

1. **Scope Reduction**:
   - Remove /revise from Phase 2 (P3 priority - marginal value)
   - Make /plan, /research, /repair, /debug optional (Phase 3 "Enhancements")
   - Focus Phase 2 on /build only (critical path)

2. **Documentation Reduction**:
   - Phase 1 integration guide can be deferred to Phase 3
   - /build only needs inline comments + command guide update
   - Full integration guide only needed if multiple commands are implemented

3. **Testing Reduction**:
   - Focus integration tests on /build workflow
   - Defer command-specific tests until those commands are implemented

**Recommended Plan Revisions**:

**NEW Phase 1: /build TODO.md Integration (P0 - Critical)**
- Add TODO.md update after `update_plan_status "IN PROGRESS"` (build.md:344)
- Add TODO.md update after `update_plan_status "COMPLETE"` (build.md:1055)
- Update /build command guide to note automatic TODO.md updates
- Integration test: Verify TODO.md updates during /build workflow
- **Effort**: 1.5 hours
- **Value**: 80% of total benefit

**NEW Phase 2: /plan TODO.md Integration (P2 - Nice-to-Have)**
- Add TODO.md update after PLAN_CREATED signal
- Update /plan command guide
- Integration test: Verify new plans appear in TODO.md
- **Effort**: 1 hour
- **Value**: Additional 10% benefit

**NEW Phase 3: Optional Command Enhancements (P2-P3)**
- Create integration guide (deferred from original Phase 1)
- Add TODO.md updates to /research, /repair, /debug (if user feedback warrants)
- Update command reference and TODO Organization Standards
- **Effort**: 2-3 hours
- **Value**: Additional 10% benefit

**Total Effort**: 4.5 hours (vs. 6 hours original) with phased delivery

## Findings

### /build Workflow State Transitions

**File**: /home/benjamin/.config/.claude/commands/build.md

The /build command manages plan status through `update_plan_status()` function from checkbox-utils.sh:

**Function Signature** (/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh:592-647):
```bash
update_plan_status() {
  local plan_path="$1"
  local status="$2"  # "NOT STARTED", "IN PROGRESS", "COMPLETE", "BLOCKED"

  # Updates plan metadata Status field:
  # - **Status**: [$status]
}
```

**Status Field Format** (from plan examples):
- Plans use `- **Status**: [IN PROGRESS]` in metadata section
- TODO Organization Standards classify based on this field (lines 276-285)
- /todo command uses `extract_plan_metadata()` to read Status field

**Integration Point**:
- /build updates plan Status field
- /todo reads Status field to classify TODO.md sections
- Adding /todo delegation immediately after `update_plan_status` ensures TODO.md stays synchronized

### TODO.md Classification Algorithm

**File**: /home/benjamin/.config/.claude/docs/reference/standards/todo-organization-standards.md

**Status Detection** (Lines 270-300):
1. **Primary**: Check plan metadata `Status:` field
   - `[COMPLETE]` → Completed section
   - `[IN PROGRESS]` → In Progress section
   - `[NOT STARTED]` → Not Started section
   - `SUPERSEDED`/`ABANDONED` → Abandoned section
2. **Fallback**: Analyze phase completion markers if Status field missing
3. **Research Detection**: Directories with reports but no plans → Research section

**Key Insight**: /build's `update_plan_status()` calls ALREADY provide the metadata that /todo needs for classification. The missing piece is triggering /todo to regenerate TODO.md after those updates.

### Existing Signal Infrastructure

**Commands Emitting Signals** (from grep results):

| Command | Signal | Line | Purpose |
|---------|--------|------|---------|
| /plan | PLAN_CREATED | plan.md:1271 | New plan file created |
| /repair | PLAN_CREATED | repair.md:1450 | Repair plan created |
| /repair | REPORT_CREATED | (multiple) | Research reports created |
| /debug | PLAN_CREATED | debug.md:964 | Debug plan created |
| /debug | DEBUG_REPORT_CREATED | (multiple) | Debug analysis created |
| /research | REPORT_CREATED | (multiple) | Research reports created |
| /revise | REPORT_CREATED | (multiple) | Revision research created |

**Signal Pattern**:
```bash
# Standard pattern across all commands:
echo "PLAN_CREATED: $PLAN_PATH"
echo "REPORT_CREATED: $REPORT_PATH"
```

**Integration Pattern** (from existing plan):
```bash
# After signal emission:
bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true
echo "✓ Updated TODO.md"
```

**Note**: /build doesn't emit PLAN_CREATED (it works with existing plans), but it DOES update plan metadata directly via `update_plan_status()`.

### Performance and User Experience

**Full Scan Performance** (from report 002):
- Scan time: 2-3 seconds for 50 topics
- Acceptable for background operations
- User sees single checkpoint: `✓ Updated TODO.md`
- No perceivable delay in command workflow

**Current TODO.md Size**:
- 51 lines total (from wc -l output)
- 2 In Progress entries
- 6 Not Started entries
- 2 Research entries
- Minimal Backlog and Completed sections

**Scaling Considerations**:
- /todo scan scales linearly with topic count
- At 2-3 seconds per 50 topics, even 200 topics would be 8-12 seconds
- Graceful degradation ensures command completion even if /todo times out
- User can manually run /todo if automatic update fails

### Workflow Integration Points

**Where TODO.md Updates Provide Maximum Value**:

1. **During Active Development** (/build):
   - User starts /build → Plan marked "In Progress" → TODO.md reflects this immediately
   - User can check TODO.md to see what's currently being worked on
   - On completion, plan moves to "Completed" automatically

2. **During Planning** (/plan):
   - New plan created → Appears in "Not Started" section
   - User doesn't have to remember to run /todo manually
   - **BUT**: User typically runs /todo periodically anyway, so this is nice-to-have

3. **During Research** (/research):
   - Research reports created → Auto-detected in "Research" section
   - **BUT**: /todo already auto-detects research-only directories on next scan

**Value Ranking**:
- **High Value**: /build status transitions (real-time workflow tracking)
- **Medium Value**: /plan new entries (convenience, not critical)
- **Low Value**: Research commands (auto-detection already works)

## Recommendations

### 1. Prioritize /build Integration (Critical Path)

**Rationale**:
- /build is the only command where real-time TODO.md updates provide significant user value
- Status transitions during active work are most important to track
- All other commands are "create and forget" - /todo scan handles discovery fine

**Implementation**:
1. Add TODO.md update after `update_plan_status "IN PROGRESS"` (build.md:344)
2. Add TODO.md update after `update_plan_status "COMPLETE"` (build.md:1055)
3. Use identical delegation pattern: `bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true`
4. Single checkpoint after each: `echo "✓ Updated TODO.md"`

**Effort**: 1.5 hours
**Testing**: Integration test verifying TODO.md section transitions during /build

### 2. Make Other Commands Optional Enhancements

**Rationale**:
- /plan, /research, /repair, /debug provide incremental value
- /todo's periodic scan already handles plan/report discovery
- No urgent user need for real-time updates from these commands

**Phased Approach**:
- **Phase 1**: /build only (deliver 80% of value)
- **Phase 2**: Evaluate user feedback after /build integration
- **Phase 3**: Add /plan if users request immediate TODO.md updates
- **Phase 4**: Add research commands only if clearly beneficial

**Benefits**:
- Faster delivery of critical functionality
- Lower implementation risk
- Evidence-based decision for optional features

### 3. Simplify Documentation Requirements

**Rationale**:
- Full integration guide unnecessary for /build-only implementation
- Inline comments + command guide update sufficient for single command
- Defer comprehensive guide until multiple commands are implemented

**Minimal Documentation** (Phase 1):
- Update /build command guide: Add note about automatic TODO.md updates
- Inline comment in build.md explaining TODO.md delegation
- Update TODO Organization Standards: Reference /build automatic updates

**Comprehensive Documentation** (Deferred to Phase 3):
- Create integration guide only if implementing multiple commands
- Full cross-command patterns documentation
- Command Reference updates for all affected commands

### 4. Leverage Existing Plan Architecture

**No Changes Needed**:
- Signal-triggered delegation pattern is optimal
- Graceful degradation with `|| true` is correct
- Suppressed output with `2>/dev/null` follows standards
- Full scan approach (no targeted updates) is best for simplicity

**Validation**:
- Report 002 confirmed existing infrastructure is complete
- No new /todo features needed
- No file locking needed (sequential execution)
- Performance is acceptable (2-3 seconds)

**Recommendation**: Keep existing plan's technical approach, only revise scope and phasing.

## References

### Plans Analyzed
- /home/benjamin/.config/.claude/specs/999_commands_plans_todo_standard/plans/001-commands-plans-todo-standard-plan.md (Lines 1-327)
- /home/benjamin/.config/.claude/specs/968_plan_standards_alignment/plans/001-plan-standards-alignment-plan.md (Lines 1-30)

### Commands Analyzed
- /home/benjamin/.config/.claude/commands/build.md (Lines 1-150, 327-336, 1050-1092)
- /home/benjamin/.config/.claude/commands/plan.md (Lines 1-200, 979, 1271)
- /home/benjamin/.config/.claude/commands/research.md (Lines 1-150)
- /home/benjamin/.config/.claude/commands/todo.md (Lines 1-100)

### Libraries Analyzed
- /home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh (Lines 592-669)
- /home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh (Lines 1-100)

### Standards Analyzed
- /home/benjamin/.config/.claude/docs/reference/standards/todo-organization-standards.md (Lines 1-383)

### TODO.md Current State
- /home/benjamin/.config/.claude/TODO.md (Lines 1-52) - 51 lines, minimal size, shows backlog item "Make commands update TODO.md automatically"

### Signal Patterns
- grep results: PLAN_CREATED signals in 4 commands (plan.md, repair.md, debug.md, optimize-claude.md)
- grep results: update_plan_status calls in build.md at 2 critical transition points
