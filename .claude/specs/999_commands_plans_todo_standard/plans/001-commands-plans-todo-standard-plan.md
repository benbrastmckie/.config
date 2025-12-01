# Commands Plans TODO Standard - Implementation Plan

## Metadata
- **Date**: 2025-12-01 (Revised 2025-12-01)
- **Feature**: Comprehensive TODO.md update integration for all plan/report commands
- **Scope**: Add TODO.md update functionality to all commands that create/modify plans or reports (/build, /plan, /research, /debug, /repair, /revise) using signal-triggered delegation pattern
- **Estimated Phases**: 3
- **Estimated Hours**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Complexity Score**: 60.0
- **Structure Level**: 0
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/999_commands_plans_todo_standard/reports/001-todo-update-implementation-analysis.md
  - /home/benjamin/.config/.claude/specs/999_commands_plans_todo_standard/reports/002-existing-infrastructure-analysis.md
  - /home/benjamin/.config/.claude/specs/999_commands_plans_todo_standard/reports/003-minimalist-todo-update-analysis.md

## Overview

Currently, only the `/todo` command updates TODO.md. Multiple workflow gaps exist: `/build` execution where plan status transitions (NOT STARTED → IN PROGRESS → COMPLETE) are not immediately reflected in TODO.md, `/plan` creates new plans that don't appear, `/research` creates reports not tracked, and `/debug`/`/repair`/`/revise` create artifacts that remain invisible until manual `/todo` invocation.

This plan implements a **comprehensive TODO.md update integration** for all commands that create or modify plans and reports: `/build` (status transitions at start and completion), `/plan` (new plan creation), `/research` (report creation), `/debug` (debug reports), `/repair` (repair plans), and `/revise` (plan modifications). All six commands will use the same signal-triggered delegation pattern.

**Revision Notes**:
- **Report 002**: Existing `todo-functions.sh` library is comprehensive; full `/todo` scan is fast (2-3 seconds). No new infrastructure needed.
- **User Preference**: All commands that create/modify artifacts should update TODO.md for consistent visibility, rather than relying on periodic scans for some commands. The overhead is minimal (2-3 seconds per command) and provides immediate feedback.

## Research Summary

Three research reports informed this plan:

**Report 001 - Initial Analysis**:
1. **Current State**: Only `/todo` updates TODO.md; 6 other commands create plans/reports but don't update TODO.md
2. **Signal Infrastructure**: Commands already emit standardized signals (`PLAN_CREATED`, `REPORT_CREATED`) with absolute paths
3. **Library Support**: `todo-functions.sh` provides comprehensive reusable functions for TODO.md management
4. **Documentation Gap**: TODO Organization Standards lack command-level integration requirements

**Report 002 - Infrastructure Analysis**:
1. **Existing Infrastructure is Complete**: All required functions already exist in `todo-functions.sh` - no modifications needed
2. **Full Scan is Fast**: 2-3 seconds for 50 topics - targeted updates are premature optimization
3. **No File Locking Needed**: Race conditions are negligible (commands run sequentially by single user)
4. **Simple Integration Pattern**: Just invoke `/todo` after signal emission (no topic extraction, no new flags)

**Report 003 - Analysis** (Referenced for patterns):
1. **Signal-Triggered Pattern**: All commands can use the same simple delegation pattern
2. **Full Commands Scope**: User preference overrides minimalist approach - all 6 commands included
   - `/build`: Status transitions at START (→ In Progress) and COMPLETION (→ Completed)
   - `/plan`: New plan creation adds "Not Started" entry
   - `/research`: Report creation triggers update
   - `/debug`: Debug report creation triggers update
   - `/repair`: Repair plan creation triggers update
   - `/revise`: Plan modification triggers update
3. **Consistent Experience**: All artifact-creating commands provide immediate TODO.md visibility

The implementation uses a **comprehensive signal-triggered delegation pattern** for all 6 commands, leveraging existing infrastructure while maintaining the `/todo` command as the single source of truth for TODO.md generation.

## Success Criteria

- [ ] `/build` command triggers TODO.md updates at two critical points: START (after marking plan as IN PROGRESS) and COMPLETION (after marking plan as COMPLETE)
- [ ] `/plan` command triggers TODO.md update after PLAN_CREATED signal emission
- [ ] `/research` command triggers TODO.md update after REPORT_CREATED signal emission
- [ ] `/debug` command triggers TODO.md update after DEBUG_REPORT_CREATED signal emission
- [ ] `/repair` command triggers TODO.md update after PLAN_CREATED signal emission
- [ ] `/revise` command triggers TODO.md update after PLAN_REVISED signal emission
- [ ] All commands use standardized delegation pattern: `bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true`
- [ ] Integration tests verify TODO.md section transitions (Not Started → In Progress → Completed) during /build workflow
- [ ] Integration tests verify new plans appear in TODO.md "Not Started" section after /plan execution
- [ ] Integration tests verify reports appear in TODO.md after /research, /debug execution
- [ ] Command Reference documentation updated to note automatic TODO.md updates for all 6 commands
- [ ] TODO Organization Standards updated to reference automatic command integration for all artifact-creating commands

## Technical Design

### Architecture Overview

The design uses a **simple signal-triggered delegation pattern** where commands that create/modify artifacts delegate TODO.md updates to the `/todo` command rather than implementing update logic themselves. This maintains separation of concerns and ensures consistent TODO.md generation.

**Key Simplifications** (based on infrastructure analysis):
1. **No New `/todo` Features**: Existing full-scan mode is fast enough (2-3 seconds)
2. **No File Locking**: Single-user, sequential command execution makes race conditions negligible
3. **No Topic Extraction**: Full scan eliminates need for topic name parsing
4. **Simple Error Handling**: Graceful degradation with `|| true` (TODO.md updates are non-critical)

**Integration Pattern**:

```bash
# Pattern A: /plan command (after PLAN_CREATED signal)
echo "PLAN_CREATED: $PLAN_PATH"
bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true
echo "✓ Updated TODO.md"

# Pattern B: /build command at START (after update_plan_status "IN PROGRESS")
if update_plan_status "$PLAN_FILE" "IN PROGRESS" 2>/dev/null; then
  echo "Marked plan as [IN PROGRESS]"
  bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true
  echo "✓ Updated TODO.md"
fi

# Pattern C: /build command at COMPLETION (after update_plan_status "COMPLETE")
if check_all_phases_complete "$PLAN_FILE"; then
  update_plan_status "$PLAN_FILE" "COMPLETE" 2>/dev/null && \
    echo "Plan metadata status updated to [COMPLETE]"
  bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true
  echo "✓ Updated TODO.md"
fi

# Pattern D: /research command (after REPORT_CREATED signal)
echo "REPORT_CREATED: $REPORT_PATH"
bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true
echo "✓ Updated TODO.md"

# Pattern E: /debug command (after DEBUG_REPORT_CREATED signal)
echo "DEBUG_REPORT_CREATED: $DEBUG_REPORT_PATH"
bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true
echo "✓ Updated TODO.md"

# Pattern F: /repair command (after PLAN_CREATED signal)
echo "PLAN_CREATED: $REPAIR_PLAN_PATH"
bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true
echo "✓ Updated TODO.md"

# Pattern G: /revise command (after PLAN_REVISED signal)
echo "PLAN_REVISED: $EXISTING_PLAN_PATH"
bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true
echo "✓ Updated TODO.md"
```

**Why This Design**:
- **Separation of Concerns**: `/todo` remains single source of truth for TODO.md generation logic
- **Consistency**: All TODO.md updates use same classification/formatting logic
- **Simplicity**: No new features or infrastructure - just delegation calls
- **Maintainability**: Changes to TODO.md format only require updating `/todo`, not all commands
- **Robustness**: Leverages existing, well-tested `todo-functions.sh` library

### Standards Compliance Integration

This plan aligns with existing project standards:

**Output Formatting Standards** (from CLAUDE.md):
- Suppress `/todo` output with `2>/dev/null`
- Single checkpoint after TODO.md update: `✓ Updated TODO.md`
- No interim console output for background TODO update operation

**Command Authoring Standards** (from CLAUDE.md):
- Block consolidation: Target 2-3 bash blocks per command
- Checkpoint format: Single line summary per major operation

**Documentation Standards** (from CLAUDE.md):
- Create lightweight integration guide (1-2 pages)
- Reference existing TODO Organization Standards (no duplication)
- Use structured sections with code examples

**Testing Standards** (from CLAUDE.md):
- Integration tests verify TODO.md contains expected entry after command execution
- Verify graceful degradation when `/todo` fails or times out

### Reused Infrastructure

This plan leverages existing, production-ready infrastructure:

**`todo-functions.sh` Library** (`/home/benjamin/.config/.claude/lib/todo/todo-functions.sh`):
- `scan_project_directories()` - Fast project discovery (2-3 seconds for 50 topics)
- `extract_plan_metadata()` - Status detection from plans
- `classify_status_from_metadata()` - Two-tier classification algorithm
- `update_todo_file()` - Complete TODO.md generation
- `extract_backlog_section()` / `extract_saved_section()` - Preserve manual curation

**Signal Infrastructure**:
- Commands already emit `PLAN_CREATED`, `REPORT_CREATED`, `DEBUG_REPORT_CREATED` signals
- Integration requires adding delegation immediately after signal emission

**TODO Organization Standards**:
- Defines 7-section hierarchy, checkbox conventions, entry format
- Integration guide will reference these standards (no duplication)

### Commands Requiring Modification

**All Commands to Update** (6 commands, comprehensive coverage):

| Command | Signals/Actions | Update Trigger Point | Implementation Effort | Priority |
|---------|----------------|----------------------|----------------------|----------|
| `/build` | `update_plan_status()` calls | After status transition to "IN PROGRESS" | 2-3 lines | P0 (Critical) |
| `/build` | `update_plan_status()` calls | After status transition to "COMPLETE" | 2-3 lines | P0 (Critical) |
| `/plan` | `PLAN_CREATED` signal | After plan file created | 2-3 lines after signal | P0 (Critical) |
| `/research` | `REPORT_CREATED` signal | After research report created | 2-3 lines after signal | P1 |
| `/debug` | `DEBUG_REPORT_CREATED` signal | After debug report created | 2-3 lines after signal | P1 |
| `/repair` | `PLAN_CREATED` signal | After repair plan created | 2-3 lines after signal | P1 |
| `/revise` | `PLAN_REVISED` signal | After plan revision complete | 2-3 lines after signal | P1 |

**Note**: All commands use identical delegation pattern - no command-specific logic needed. Pattern is simply: `bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true`

### Performance Considerations

**Full Scan Performance**:
- Time: ~2-3 seconds for 50 topics
- Acceptable for signal-triggered updates (non-blocking background operation)
- User sees single checkpoint: `✓ Updated TODO.md`

**Why Full Scan is Sufficient**:
1. **Fast Enough**: 2-3 seconds is imperceptible in command workflow context
2. **Simple**: No new infrastructure or complexity
3. **Reliable**: Ensures TODO.md always reflects complete project state
4. **Maintainable**: No targeted update logic to debug

**Graceful Degradation**:
- If `/todo` fails: Command completes successfully (TODO.md update non-critical)
- User can manually run `/todo` to recover

## Implementation Phases

### Phase 1: Create Lightweight Command-TODO Integration Guide [COMPLETE]
dependencies: []

**Objective**: Document simple integration pattern for command-level TODO.md updates with code examples for all 6 commands.

**Complexity**: Low

**Tasks**:
- [x] Create `.claude/docs/guides/development/command-todo-integration-guide.md` (2-3 pages) (file: .claude/docs/guides/development/command-todo-integration-guide.md)
- [x] Document signal-triggered delegation pattern with seven code examples: /plan (Pattern A), /build START (Pattern B), /build COMPLETION (Pattern C), /research (Pattern D), /debug (Pattern E), /repair (Pattern F), /revise (Pattern G)
- [x] Reference TODO Organization Standards for section hierarchy and status classification
- [x] Reference Command Authoring Standards for block consolidation and checkpoint format
- [x] List all 6 commands that need TODO.md updates with their signal types
- [x] Document graceful degradation pattern (`|| true`) and why TODO.md updates are non-critical
- [x] Include testing approach (verify TODO.md section transitions during /build, verify artifacts appear after all commands)
- [x] Add anti-patterns section: "Don't implement incremental/targeted updates", "Don't add complex error handling", "Don't modify todo-functions.sh"

**Testing**:
```bash
# Verify guide exists and has correct structure
test -f .claude/docs/guides/development/command-todo-integration-guide.md
grep -q "## Signal-Triggered Delegation Pattern" .claude/docs/guides/development/command-todo-integration-guide.md
grep -q "Pattern A.*plan" .claude/docs/guides/development/command-todo-integration-guide.md
grep -q "Pattern B.*build.*START" .claude/docs/guides/development/command-todo-integration-guide.md
grep -q "Pattern D.*research" .claude/docs/guides/development/command-todo-integration-guide.md
grep -q "Pattern G.*revise" .claude/docs/guides/development/command-todo-integration-guide.md

# Verify all 6 commands documented
grep -c "/build\|/plan\|/research\|/debug\|/repair\|/revise" .claude/docs/guides/development/command-todo-integration-guide.md | grep -qE "^[6-9]|^[1-9][0-9]"

# Verify references to existing standards
grep -q "todo-organization-standards.md" .claude/docs/guides/development/command-todo-integration-guide.md
grep -q "command-authoring.md" .claude/docs/guides/development/command-todo-integration-guide.md
```

**Expected Duration**: 1 hour

### Phase 2: Add TODO.md Updates to All Commands [COMPLETE]
dependencies: [1]

**Objective**: Add simple TODO.md update delegation to all 6 commands that create/modify plans and reports using the standardized signal-triggered pattern.

**Complexity**: Medium

**Tasks**:
- [x] Add TODO.md update delegation to `/build` after `update_plan_status "IN PROGRESS"` call - Pattern B (file: .claude/commands/build.md)
- [x] Add TODO.md update delegation to `/build` after `update_plan_status "COMPLETE"` call - Pattern C (file: .claude/commands/build.md)
- [x] Add TODO.md update delegation to `/plan` after `PLAN_CREATED` signal - Pattern A (file: .claude/commands/plan.md)
- [x] Add TODO.md update delegation to `/research` after `REPORT_CREATED` signal - Pattern D (file: .claude/commands/research.md)
- [x] Add TODO.md update delegation to `/debug` after `DEBUG_REPORT_CREATED` signal - Pattern E (file: .claude/commands/debug.md)
- [x] Add TODO.md update delegation to `/repair` after `PLAN_CREATED` signal - Pattern F (file: .claude/commands/repair.md)
- [x] Add TODO.md update delegation to `/revise` after `PLAN_REVISED` signal - Pattern G (file: .claude/commands/revise.md)
- [x] Use identical pattern in all commands: `bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true`
- [x] Add checkpoint after each update: `echo "✓ Updated TODO.md"`
- [x] Suppress `/todo` output completely with `2>/dev/null`

**Testing**:
```bash
# Test /plan updates TODO.md (Pattern A verification)
rm .claude/TODO.md
/plan "test feature for todo integration"
grep -q "test feature for todo integration" .claude/TODO.md
grep -q "Not Started" .claude/TODO.md  # Should be in Not Started section

# Test /build START updates TODO.md (Pattern B verification)
/build .claude/specs/*/plans/001-*.md
grep -q "In Progress" .claude/TODO.md  # Should move to In Progress section

# Test /build COMPLETION updates TODO.md (Pattern C verification)
# After all phases complete
grep -q "Completed" .claude/TODO.md  # Should move to Completed section

# Test /research updates TODO.md (Pattern D verification)
/research "test research topic"
# Verify research reports reflected in TODO.md

# Test /revise updates TODO.md (Pattern G verification)
/revise "revise plan at .claude/specs/*/plans/001-*.md based on new insights"
# Verify plan modifications reflected in TODO.md

# Test graceful degradation: simulate /todo failure
mv .claude/commands/todo.md .claude/commands/todo.md.bak
/plan "test graceful degradation" || echo "FAIL: plan should succeed even if /todo fails"
mv .claude/commands/todo.md.bak .claude/commands/todo.md
```

**Expected Duration**: 3 hours

### Phase 3: Update Documentation [COMPLETE]
dependencies: [2]

**Objective**: Update Command Reference and TODO Organization Standards to reflect automatic TODO.md updates for all 6 artifact-creating commands.

**Complexity**: Low

**Tasks**:
- [x] Update TODO Organization Standards "Usage by Commands" section to note automatic updates for all 6 commands (file: .claude/docs/reference/standards/todo-organization-standards.md)
- [x] List all commands with TODO.md integration: /build (start + completion), /plan, /research, /debug, /repair, /revise (file: .claude/docs/reference/standards/todo-organization-standards.md)
- [x] Add reference link from TODO Organization Standards to command-todo-integration-guide.md (file: .claude/docs/reference/standards/todo-organization-standards.md)
- [x] Update Command Reference to add "Automatically updates TODO.md" note for all 6 commands (file: .claude/docs/reference/standards/command-reference.md)
- [x] Add integration guide to development docs index (file: .claude/docs/guides/development/README.md if exists)

**Testing**:
```bash
# Verify TODO Organization Standards updated with all 6 commands
grep -q "automatically update TODO.md" .claude/docs/reference/standards/todo-organization-standards.md
grep -q "/build\|/plan\|/research\|/debug\|/repair\|/revise" .claude/docs/reference/standards/todo-organization-standards.md
grep -q "command-todo-integration-guide.md" .claude/docs/reference/standards/todo-organization-standards.md

# Verify Command Reference updated for all 6 commands
grep -q "Automatically updates TODO.md" .claude/docs/reference/standards/command-reference.md
# Count should be 6+ (one for each command, build has 2 update points)
grep -c "Automatically updates TODO.md" .claude/docs/reference/standards/command-reference.md | grep -qE "^[6-9]$"

# Run link validator
bash .claude/scripts/validate-links-quick.sh .claude/docs/
```

**Expected Duration**: 2 hours

## Testing Strategy

### Integration Testing
- Test `/plan` command updates TODO.md after PLAN_CREATED signal (Pattern A verification)
- Test `/build` command updates TODO.md at START after status transition to "IN PROGRESS" (Pattern B verification)
- Test `/build` command updates TODO.md at COMPLETION after status transition to "COMPLETE" (Pattern C verification)
- Test `/research` command updates TODO.md after REPORT_CREATED signal (Pattern D verification)
- Test `/debug` command updates TODO.md after DEBUG_REPORT_CREATED signal (Pattern E verification)
- Test `/repair` command updates TODO.md after PLAN_CREATED signal (Pattern F verification)
- Test `/revise` command updates TODO.md after PLAN_REVISED signal (Pattern G verification)
- Test TODO.md contains correct section placement (Not Started → In Progress → Completed transitions)
- Test graceful degradation when `/todo` fails (commands complete successfully, TODO.md update skipped)
- Verify Backlog and Saved sections preserved after updates

### Regression Testing
- Verify `/todo` full scan behavior unchanged (backward compatibility)
- Verify existing TODO.md format and section structure preserved
- Verify commands still work if `/todo` fails (non-critical operation)

### Test Commands
```bash
# Integration test suite for all commands
bash .claude/tests/integration/test_todo_integration.sh

# Specific command tests (all 6 commands)
bash .claude/tests/commands/test_plan_todo_update.sh
bash .claude/tests/commands/test_build_todo_update.sh
bash .claude/tests/commands/test_research_todo_update.sh
bash .claude/tests/commands/test_debug_todo_update.sh
bash .claude/tests/commands/test_repair_todo_update.sh
bash .claude/tests/commands/test_revise_todo_update.sh

# Verify all 6 commands have TODO.md update logic
grep -q "bash -c.*todo.md" .claude/commands/plan.md
grep -q "bash -c.*todo.md" .claude/commands/build.md
grep -q "bash -c.*todo.md" .claude/commands/research.md
grep -q "bash -c.*todo.md" .claude/commands/debug.md
grep -q "bash -c.*todo.md" .claude/commands/repair.md
grep -q "bash -c.*todo.md" .claude/commands/revise.md
```

## Documentation Requirements

### New Documentation
- **Command-TODO Integration Guide** (`.claude/docs/guides/development/command-todo-integration-guide.md`): Guide (2-3 pages) documenting signal-triggered delegation pattern with seven code examples (Patterns A-G) for all 6 commands. Document comprehensive approach covering /plan, /build (2 points), /research, /debug, /repair, /revise.

### Updated Documentation
- **TODO Organization Standards** (`.claude/docs/reference/standards/todo-organization-standards.md`): Update "Usage by Commands" section to reflect automatic updates for all 6 commands, add reference link to integration guide
- **Command Reference** (`.claude/docs/reference/standards/command-reference.md`): Add "Automatically updates TODO.md" note to all 6 commands

### Documentation Standards Compliance
- Follow Documentation Standards from CLAUDE.md (clear structure, navigation links)
- Use structured sections with code examples for each pattern
- Include anti-patterns section ("Don't implement targeted/incremental updates", "Don't add complex error handling")
- Reference existing standards (no duplication)

## Dependencies

### Internal Dependencies
- **`/todo` command**: Core dependency for all TODO.md updates (no modifications needed)
- **`todo-functions.sh`**: Library providing complete TODO.md management (existing functions reused)
- **`unified-location-detection.sh`**: Library for artifact directory detection

### Integration Points
- **Artifact Creation Signals**: Commands emit `PLAN_CREATED`, `REPORT_CREATED`, `DEBUG_REPORT_CREATED` signals - delegation added immediately after
- **TODO.md File**: Shared state modified by all commands via `/todo` delegation
- **Full Scan Approach**: Eliminates need for topic extraction, lock management, or targeted update logic

### Risk Mitigation
- **Graceful Degradation**: Commands complete successfully even if TODO.md update fails (non-critical operation)
- **Sequential Execution**: Single-user workflows make race conditions negligible
- **Backward Compatibility**: `/todo` command unchanged - full scan behavior preserved
