# Refactor /todo --clean Command Implementation Plan

## Metadata
- **Date**: 2025-11-29 (Revised)
- **Feature**: Refactor /todo --clean to remove age threshold and expand cleanup targets
- **Scope**: Maintain plan-generation approach while removing 30-day age threshold and targeting Completed, Superseded, and Abandoned sections
- **Estimated Phases**: 3
- **Estimated Hours**: 5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Structure Level**: 0
- **Complexity Score**: 22.0
- **Research Reports**:
  - [Refactor /todo --clean Command Research](/home/benjamin/.config/.claude/specs/974_todo_clean_refactor/reports/001-todo-clean-refactor-research.md)
  - [Plan Revision Insights](/home/benjamin/.config/.claude/specs/974_todo_clean_refactor/reports/002-plan-revision-insights.md)

## Overview

Refactor the `/todo --clean` command to maintain the plan-generation approach while removing the 30-day age threshold and expanding cleanup targets. The command will continue to invoke the plan-architect agent to generate cleanup plans, but will now target ALL projects in Completed, Superseded, and Abandoned sections regardless of age. The generated plan is then executed via `/build` command.

**Key Changes**:
1. **Execution Model**: Plan generation (maintains current architecture)
2. **Age Filtering**: Removed (clean all eligible projects regardless of age)
3. **Target Sections**: Completed + Abandoned + Superseded (not just Completed)
4. **Plan Scope**: Generated plan includes git verification, archiving, and directory removal phases
5. **Workflow**: `/todo --clean` → generates plan → `/build <plan>` → executes cleanup

## Research Summary

Research identified that the current `/todo --clean` implementation generates a cleanup plan via plan-architect agent, applies a 30-day age threshold, and only targets completed projects. The plan-generation approach is working well and should be preserved.

**Key Findings from Research**:
- Current implementation uses plan-generation approach (maintained architecture)
- Existing `filter_completed_projects()` function filters only "completed" status with 30-day age threshold
- TODO.md has 6 sections with ~193 eligible projects across target sections
- plan-architect agent already handles plan generation for cleanup operations
- Archive approach is safer than deletion (full recovery possible)

**Recommended Approach**:
- KEEP plan-generation workflow (generates plan → `/build` executes)
- REMOVE 30-day age threshold from filtering logic
- EXPAND target sections from Completed-only to Completed + Abandoned + Superseded
- Update `filter_completed_projects()` function to accept three statuses without age filtering
- Update plan-architect prompt to include all three section types

## Success Criteria

- [ ] `/todo --clean` generates a cleanup plan (maintains current architecture)
- [ ] Generated plan targets Completed, Abandoned, AND Superseded sections
- [ ] No age-based filtering applied (all eligible projects included in plan)
- [ ] `filter_completed_projects()` function updated to accept three statuses
- [ ] plan-architect prompt updated to remove age threshold requirement
- [ ] Generated plan includes git verification phase
- [ ] Generated plan includes archiving to timestamped directory
- [ ] Generated plan preserves TODO.md (no modification during cleanup)
- [ ] Plan can be executed via `/build <plan>` command
- [ ] Documentation updated with new behavior
- [ ] Function changes maintain backward compatibility where possible

## Technical Design

### Architecture

The refactored implementation maintains the plan-generation pattern in the `/todo` command with modifications to the filtering library function and plan-architect prompt.

**Component Structure**:

```
/todo command (todo.md)
├── Block 1-4: Default Mode (TODO.md generation) - UNCHANGED
└── Clean Mode Section (Plan Generation) - MODIFIED
    ├── Invoke plan-architect agent
    ├── Filter projects using updated filter function
    └── Generate cleanup plan with expanded scope

todo-functions.sh library
├── filter_completed_projects() - MODIFIED
    ├── Accept three statuses: completed, superseded, abandoned
    └── Remove age-based filtering logic
```

**Workflow Flow**:

```
/todo --clean
    ↓
Clean Mode Section
    ↓
1. Filter eligible projects using updated filter_completed_projects()
    ├─→ Include status: completed, superseded, abandoned
    └─→ Remove age threshold check
    ↓
2. Invoke plan-architect agent with filtered projects
    ↓
3. plan-architect generates cleanup plan with phases:
    ├─→ Phase 1: Git verification (check uncommitted changes)
    ├─→ Phase 2: Archive creation (timestamped directory)
    ├─→ Phase 3: Directory removal (move to archive)
    └─→ Phase 4: Verification (confirm cleanup success)
    ↓
4. Save plan to specs/{NNN_topic}/plans/
    ↓
User executes: /build <plan-file>
    ↓
5. Build command executes cleanup phases
```

**Key Decisions**:

1. **Plan Generation**: Maintain current plan-architect approach (generates plan for `/build` execution)
2. **Age Filtering**: Remove 30-day threshold completely from filter logic
3. **Target Sections**: Expand from Completed-only to Completed + Abandoned + Superseded
4. **Backward Compatibility**: Keep `filter_completed_projects()` function name, extend logic
5. **Generated Plan**: Includes git verification, archiving, and TODO.md preservation phases

### Data Flow

**TODO.md Entry Structure**:
```markdown
- [x] **Feature Title** - Description
  [.claude/specs/961_repair_spec_numbering/plans/001-plan.md]
  - 4 phases complete: Summary
```

**Directory Extraction Pattern**:
```bash
# Input: TODO.md entry line
entry="- [x] **Title** [.claude/specs/961_test/plans/001.md]"

# Extract topic directory
topic=$(echo "$entry" | grep -oP '\.claude/specs/\K[0-9]{3}_[^/]+')
# Result: "961_test"

# Construct full path
dir_path="${SPECS_ROOT}/${topic}"
# Result: "/home/user/.claude/specs/961_test"
```

**Git Status Check**:
```bash
# Change to project root
cd "$CLAUDE_PROJECT_DIR"

# Get relative path
rel_path="${dir_path#$CLAUDE_PROJECT_DIR/}"

# Check for uncommitted changes
git_status=$(git status --porcelain "$rel_path" 2>/dev/null)

if [ -n "$git_status" ]; then
  # Uncommitted changes → skip directory
  skipped_dirs+=("$topic")
else
  # Clean → proceed with removal
  safe_dirs+=("$topic")
fi
```

**Archive Structure**:
```
.claude/
├── archive/
│   └── cleaned_20251129_172530/
│       ├── 102_plan_command_error_analysis/
│       ├── 787_state_machine_persistence_bug/
│       └── ... (archived directories)
└── specs/
    ├── 969_repair_plan_20251129_155633/  (preserved)
    └── ... (remaining projects)
```

### Integration Points

1. **plan-architect Agent**:
   - Already integrated in Clean Mode section (lines 624-651 of todo.md)
   - Receives filtered project list from updated filter function
   - Generates multi-phase cleanup plan

2. **Library Functions**:
   - `filter_completed_projects()`: Extend to accept three statuses, remove age check
   - `scan_project_directories()`: Unchanged (discovers topic directories)
   - `find_plans_in_topic()`: Unchanged (finds plan files)
   - `categorize_plan()`: Unchanged (maps status to section)

3. **Existing Functions** (no changes needed):
   - All discovery and classification functions remain as-is
   - Only filtering logic modified in `filter_completed_projects()`

## Implementation Phases

### Phase 1: Update Filter Function [COMPLETE]
dependencies: []

**Objective**: Modify `filter_completed_projects()` function in `todo-functions.sh` to accept three statuses (completed, superseded, abandoned) and remove age-based filtering.

**Complexity**: Low

Tasks:
- [x] Locate `filter_completed_projects()` function (file: /home/benjamin/.config/.claude/lib/todo/todo-functions.sh, lines 717-768)
- [x] Remove age threshold parameter and logic
  - Remove `age_threshold_days` parameter
  - Remove `stat` command checking file modification time
  - Remove age comparison logic
- [x] Expand status filtering to three types
  - Change status filter from `status == "completed"` to `status in ["completed", "superseded", "abandoned"]`
  - Use jq filter: `select(.status == "completed" or .status == "superseded" or .status == "abandoned")`
- [x] Update function documentation header
  - Update Purpose: "Filter projects by cleanup-eligible status (completed, superseded, abandoned)"
  - Remove age threshold from Arguments section
  - Add note about expanded status coverage
- [x] Maintain backward compatibility
  - Keep function name as `filter_completed_projects()`
  - Ensure return format matches existing contract (JSON array)
- [x] Add inline comments explaining status expansion

Testing:
```bash
# Test filtering with three statuses
bash .claude/tests/unit/test_filter_completed_projects.sh

# Verify no age-based filtering applied
# Verify all three statuses included
# Verify JSON output format maintained
```

**Expected Duration**: 1.5 hours

---

### Phase 2: Update plan-architect Prompt [COMPLETE]
dependencies: [1]

**Objective**: Update the plan-architect agent invocation in Clean Mode section to remove age threshold requirement and expand target sections.

**Complexity**: Low

Tasks:
- [x] Update Clean Mode description (file: /home/benjamin/.config/.claude/commands/todo.md, lines 618-622)
  - Change "completed projects older than 30 days" to "projects in Completed, Abandoned, and Superseded sections"
  - Update to: "generates a cleanup plan for all projects marked as cleanup-eligible"
- [x] Update plan-architect Task prompt (lines 624-651)
  - Remove age_threshold parameter: Delete line `- age_threshold: 30 days`
  - Update input description to include three sections:
    - `- completed_projects: Projects with status=completed`
    - `- superseded_projects: Projects with status=superseded`
    - `- abandoned_projects: Projects with status=abandoned`
  - Update archive path from `archive/completed_$(date +%Y%m%d)/` to `archive/cleaned_$(date +%Y%m%d)/`
  - Update plan phases description to clarify git verification phase
- [x] Update filter function call
  - Call `filter_completed_projects()` with updated logic (no age parameter)
  - Pass result to plan-architect agent
- [x] Verify plan-architect prompt includes:
  - Git verification phase (check uncommitted changes)
  - Archive creation phase (timestamped directory)
  - Directory removal phase (move to archive)
  - TODO.md preservation (no modification during cleanup)

Testing:
```bash
# Test plan generation
/todo --clean

# Verify plan file created
# Verify plan includes all three section types
# Verify no age filtering mentioned
# Verify plan has git verification phase
```

**Expected Duration**: 2 hours

---

### Phase 3: Update Documentation and Testing [COMPLETE]
dependencies: [2]

**Objective**: Update command documentation to reflect removal of age threshold and expansion of target sections. Add validation tests.

**Complexity**: Low

Tasks:
- [x] Update todo-command-guide.md Clean Mode section (file: /home/benjamin/.config/.claude/docs/guides/commands/todo-command-guide.md)
  - Update description: "generates cleanup plan for Completed, Abandoned, and Superseded sections"
  - Remove references to 30-day age threshold
  - Document expanded target sections
  - Clarify plan-generation workflow: `/todo --clean` → review plan → `/build <plan>`
- [x] Update inline documentation in todo.md (file: /home/benjamin/.config/.claude/commands/todo.md)
  - Update Clean Mode description (lines 618-622)
  - Remove age threshold mention
  - Add examples showing plan generation output
- [x] Update function documentation in todo-functions.sh (file: /home/benjamin/.config/.claude/lib/todo/todo-functions.sh)
  - Update `filter_completed_projects()` header
  - Remove age threshold from Arguments
  - Document three status types in Purpose
- [x] Create validation test for filter function
  - Test completed status filtering
  - Test superseded status filtering
  - Test abandoned status filtering
  - Verify no age filtering applied
  - Verify JSON output format
- [x] Test plan generation workflow
  - Execute `/todo --clean` on test environment
  - Verify plan file created
  - Verify plan includes all three section types
  - Verify plan has expected phases (git verification, archive, removal)
- [x] Verify standards compliance
  - Run library sourcing validator on modified files
  - Ensure no violations introduced

Testing:
```bash
# Test filter function
bash .claude/tests/unit/test_filter_completed_projects.sh

# Test plan generation
/todo --clean
# Review generated plan for correctness

# Standards compliance
bash .claude/scripts/validate-all-standards.sh --staged
```

**Expected Duration**: 1.5 hours

---

## Testing Strategy

### Unit Testing (Phase 1)

Test modified library function:

1. **filter_completed_projects()**:
   - Filter projects with status="completed"
   - Filter projects with status="superseded"
   - Filter projects with status="abandoned"
   - Verify no age-based filtering applied (all ages included)
   - Verify JSON output format maintained
   - Test with empty project list
   - Test with mixed status types

### Integration Testing (Phase 3)

Test complete plan-generation workflow:

1. **Plan Generation**:
   - Execute `/todo --clean`
   - Verify plan file created in specs/{NNN_topic}/plans/
   - Verify plan includes all three section types
   - Verify no age threshold mentioned in plan
   - Verify plan has expected phases (git verification, archive, removal, verification)

2. **Plan Content Validation**:
   - Verify plan targets correct directories (from three sections)
   - Verify plan includes git verification phase
   - Verify plan includes archive creation with timestamp
   - Verify plan preserves TODO.md (no modification phase)

3. **Standards Compliance**:
   - Library sourcing validation
   - Error suppression validation
   - Conditionals validation
   - No violations detected

### Test Coverage Requirements

- **Unit Tests**: Modified filter function tested (all three statuses, no age filtering)
- **Integration Tests**: Plan generation workflow tested (output, content, phases)
- **Validation Tests**: Standards compliance verified

## Documentation Requirements

### Files to Update

1. **Command Documentation**:
   - `/home/benjamin/.config/.claude/commands/todo.md`: Replace Clean Mode section, add Block 5
   - `/home/benjamin/.config/.claude/docs/guides/commands/todo-command-guide.md`: Update Clean Mode description, add troubleshooting

2. **Library Documentation**:
   - `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh`: Add function headers for 4 new functions

3. **Standards Documentation**:
   - `/home/benjamin/.config/.claude/docs/reference/standards/todo-organization-standards.md`: Update "Usage by Commands" section

4. **Test Documentation**:
   - Test scripts: Inline documentation for setup, execution, verification

### Documentation Standards

- Follow CommonMark specification
- Use clear, concise language
- Include code examples with syntax highlighting
- No emojis in file content
- Document WHAT code does (not WHY)
- Use 4-section format for summaries (Summary, Phases, Artifacts, Next Steps)

### Required Sections

1. **Command Guide Updates**:
   - Clean Mode behavior (direct execution)
   - Target sections (Completed, Abandoned, Superseded)
   - Git verification (skip-and-warn pattern)
   - Archive management (timestamped directories)
   - Recovery procedures (restore from archive)
   - Troubleshooting (uncommitted changes, permission errors)

2. **Function Documentation**:
   - Purpose (one-line description)
   - Arguments (with types and descriptions)
   - Returns (exit codes and output format)
   - Usage examples (typical invocations)

3. **Standards Documentation**:
   - `/todo --clean` behavior summary
   - TODO.md preservation clarification
   - Workflow: cleanup → rescan

## Dependencies

### External Dependencies

- **bash**: Shell execution environment (required)
- **git**: Git status verification (optional, graceful degradation if not available)
- **jq**: JSON parsing (already used in existing code, required)
- **sed**: TODO.md section parsing (required)
- **grep**: Pattern extraction (required)
- **date**: Timestamp generation (required)
- **mkdir**: Archive directory creation (required)
- **mv**: Directory moves (required)

### Internal Dependencies

1. **Libraries**:
   - `/home/benjamin/.config/.claude/lib/core/state-persistence.sh`: State restoration
   - `/home/benjamin/.config/.claude/lib/core/error-handling.sh`: Error logging
   - `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh`: Cleanup functions

2. **Command Blocks**:
   - Block 1: Setup and discovery (provides `SPECS_ROOT`, `CLAUDE_PROJECT_DIR`)
   - Block 2c: Hard barrier (provides state file for restoration)

3. **Data Files**:
   - `/home/benjamin/.config/.claude/TODO.md`: Source of cleanup candidates
   - State files: `~/.claude/data/state/todo_*.state`

### Phase Dependencies

- Phase 2 depends on Phase 1 (filter function must be updated before prompt modification)
- Phase 3 depends on Phase 2 (documentation describes updated behavior)

**Note**: All phases are sequential in this simplified plan.

## Risk Management

### Technical Risks

1. **Risk**: Git verification may fail on non-git environments
   - **Mitigation**: Graceful degradation (skip git check if not available)
   - **Impact**: Low (log warning, proceed with cleanup)

2. **Risk**: Archive directory creation may fail (disk full, permission denied)
   - **Mitigation**: Check available space, validate permissions before cleanup
   - **Impact**: High (fatal error, abort cleanup)

3. **Risk**: Directory move operations may fail mid-cleanup
   - **Mitigation**: Continue-on-error pattern (log and proceed with next directory)
   - **Impact**: Medium (partial cleanup, user must retry)

4. **Risk**: TODO.md parsing may fail on malformed entries
   - **Mitigation**: Skip malformed entries, log warnings
   - **Impact**: Low (some directories missed, manual cleanup needed)

### Operational Risks

1. **Risk**: User accidentally removes directories with valuable uncommitted work
   - **Mitigation**: Git verification with skip-and-warn, dry-run preview
   - **Impact**: Low (uncommitted directories skipped)

2. **Risk**: Archive directory grows large over time
   - **Mitigation**: Document archive management, suggest rotation policy
   - **Impact**: Low (disk space usage, manual cleanup needed)

3. **Risk**: Concurrent execution of `/todo` and `/todo --clean`
   - **Mitigation**: Separate workflow IDs, independent state files
   - **Impact**: Low (race condition possible but operations independent)

### Recovery Procedures

1. **Restore single directory**: `mv archive/cleaned_*/NNN_topic/ specs/`
2. **Restore all directories**: `mv archive/cleaned_*/* specs/`
3. **Verify restoration**: `/todo` to regenerate TODO.md
4. **Commit changes**: Address uncommitted changes, re-run cleanup

## Rollback Strategy

If issues are discovered post-deployment:

1. **Immediate Rollback**:
   - Revert commit containing refactored implementation
   - Restore previous plan-generation behavior
   - Notify users of rollback

2. **Partial Rollback**:
   - Keep new library functions
   - Revert Block 5 to plan-generation
   - Maintain git verification additions

3. **Data Recovery**:
   - All removed directories archived (no data loss)
   - Archive restore procedures documented
   - Git history provides additional recovery option

## Notes

- This plan maintains the plan-generation approach (not direct execution)
- Removes 30-day age threshold completely from filtering logic
- Expands cleanup targets from Completed-only to Completed + Abandoned + Superseded
- Generated plan will be executed via `/build` command (two-step workflow preserved)
- Git verification, archiving, and TODO.md preservation are handled in the generated plan phases
- Plan 971 exists but targets different approach (also plan-generation but with different scope)
