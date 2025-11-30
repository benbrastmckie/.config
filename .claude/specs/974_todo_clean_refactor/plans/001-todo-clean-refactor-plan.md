# Refactor /todo --clean Output Standardization Plan

## Metadata
- **Date**: 2025-11-29
- **Feature**: Standardize /todo --clean output format and enhance git verification
- **Scope**: Adopt 4-section console summary pattern used by /plan, /build, /research commands. Ensure generated cleanup plans include proper git verification phases. No changes to execution model (plan-generation approach is correct).
- **Estimated Phases**: 3
- **Estimated Hours**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 18.0
- **Research Reports**:
  - [/home/benjamin/.config/.claude/specs/974_todo_clean_refactor/reports/001-todo-clean-refactor-research.md](/home/benjamin/.config/.claude/specs/974_todo_clean_refactor/reports/001-todo-clean-refactor-research.md)
  - [/home/benjamin/.config/.claude/specs/974_todo_clean_refactor/reports/002-plan-revision-insights.md](/home/benjamin/.config/.claude/specs/974_todo_clean_refactor/reports/002-plan-revision-insights.md)
  - [/home/benjamin/.config/.claude/specs/974_todo_clean_refactor/reports/003-todo-clean-output-standardization.md](/home/benjamin/.config/.claude/specs/974_todo_clean_refactor/reports/003-todo-clean-output-standardization.md)

## Overview

Refactor the `/todo --clean` command output to adopt the standardized 4-section console summary format used by other artifact-producing commands (/plan, /build, /research). The current implementation correctly generates cleanup plans via plan-architect agent but lacks standardized output formatting. This plan adds proper completion signals, emoji markers, absolute artifact paths, and actionable next steps while maintaining the existing plan-generation architecture.

**Key Changes**:
1. **Output Format**: Replace generic completion message with 4-section console summary (Summary, Phases, Artifacts, Next Steps)
2. **Completion Signal**: Add `CLEANUP_PLAN_CREATED: <path>` signal for orchestrator parsing
3. **Emoji Markers**: Add visual markers (📄 for plans) for terminal scanning
4. **Git Verification**: Enhance plan-architect prompt to explicitly specify git verification phase behavior
5. **Dry-Run Support**: Add `--dry-run` preview mode for cleanup candidates
6. **No --execute Flag**: Already satisfied (flag doesn't exist, no action needed)

## Research Summary

Research identified that `/todo --clean` currently generates cleanup plans via plan-architect agent (correct architecture) but outputs a generic completion message that doesn't follow the standardized 4-section console summary pattern. Commands like /plan, /build, and /research use a consistent output format with completion signals, emoji markers, absolute paths, and actionable next steps.

**Key Findings from Research**:
- Current output lacks standardized format (no emoji markers, no clear artifact paths)
- Other commands use 4-section pattern: Summary, Phases (optional), Artifacts, Next Steps
- Completion signals enable orchestrator parsing (e.g., `PLAN_CREATED:`, `REPORT_CREATED:`)
- No `--execute` flag exists (requirement already satisfied)
- Git verification should be in generated plan phases (not /todo command itself)
- Dry-run preview mode missing for cleanup candidates
- Plan-generation approach is architecturally correct (maintain as-is)

**Recommended Approach**:
- Add standardized 4-section console summary output to Clean Mode
- Include `CLEANUP_PLAN_CREATED:` completion signal
- Use emoji markers from approved vocabulary (📄 for plan files)
- Enhance plan-architect prompt with explicit git verification requirements
- Add dry-run preview support
- Update documentation to reflect standardized output

## Success Criteria

- [ ] `/todo --clean` outputs 4-section console summary format
- [ ] Completion signal `CLEANUP_PLAN_CREATED: <path>` emitted with absolute path
- [ ] Emoji markers used for visual scanning (📄 for plan artifact)
- [ ] Summary section describes WHAT was accomplished and WHY it matters (2-3 sentences)
- [ ] Artifacts section lists cleanup plan with absolute path
- [ ] Next Steps section provides actionable commands (review plan, execute via /build, rescan)
- [ ] plan-architect prompt explicitly specifies git verification phase behavior
- [ ] Dry-run mode added (`/todo --clean --dry-run` previews candidates without generating plan)
- [ ] Output format matches /plan, /build, /research patterns
- [ ] Documentation updated with example output and workflow
- [ ] Standards compliance maintained (library sourcing, error handling)

## Technical Design

### Architecture

The refactored implementation adds a new completion block (Block 5) after the plan-architect invocation in Clean Mode. This block reads the plan path from the agent's return signal and formats a standardized 4-section console summary.

**Component Structure**:

```
/todo command (todo.md)
├── Block 1-4: Default Mode (TODO.md generation) - UNCHANGED
└── Clean Mode Section - MODIFIED
    ├── Dry-Run Check (NEW Block 4a)
    │   └── Preview cleanup candidates, exit before plan generation
    ├── Plan Generation (Existing Block, Enhanced Prompt)
    │   └── Invoke plan-architect with enhanced git verification requirements
    └── Completion Output (NEW Block 5)
        ├── Parse CLEANUP_PLAN_CREATED signal
        ├── Generate 4-section console summary
        └── Emit completion signal for orchestrator
```

**Workflow Flow**:

```
/todo --clean [--dry-run]
    ↓
Block 4a: Dry-Run Check (NEW)
    ↓
IF --dry-run:
    ├─→ Filter eligible projects
    ├─→ Display preview (count, project list)
    └─→ Exit (no plan generation)
    ↓
ELSE (execute clean mode):
    ↓
Invoke plan-architect (Enhanced Prompt)
    ├─→ Filter eligible projects (completed, superseded, abandoned)
    ├─→ Generate cleanup plan with explicit git verification phase
    ├─→ Return signal: CLEANUP_PLAN_CREATED: <path>
    ↓
Block 5: Standardized Output (NEW)
    ├─→ Parse plan path from signal
    ├─→ Count eligible projects
    ├─→ Generate 4-section console summary
    │   ├─→ Summary: What was accomplished, why it matters
    │   ├─→ Artifacts: 📄 Plan path (absolute)
    │   └─→ Next Steps: Review, execute, rescan
    └─→ Emit CLEANUP_PLAN_CREATED signal
```

**Key Decisions**:

1. **Output Format**: Adopt 4-section console summary pattern for consistency
2. **Completion Signal**: Use `CLEANUP_PLAN_CREATED:` prefix for orchestrator parsing
3. **Emoji Markers**: Use 📄 for plan files (from approved vocabulary in output-formatting.md)
4. **Git Verification**: Specify in plan-architect prompt (not in /todo command)
5. **Dry-Run Preview**: Add preview mode before plan generation (skip-and-exit pattern)
6. **Backward Compatibility**: Maintain plan-generation approach (no execution model change)

### Data Flow

**plan-architect Return Signal**:
```bash
# plan-architect agent returns completion signal
CLEANUP_PLAN_CREATED: /home/user/.config/.claude/specs/975_cleanup/plans/001-cleanup-plan.md
```

**Block 5 Signal Parsing**:
```bash
# Parse plan path from agent output
CLEANUP_PLAN_PATH=$(echo "$AGENT_OUTPUT" | grep "^CLEANUP_PLAN_CREATED:" | cut -d' ' -f2-)

# Validate path exists
if [ -z "$CLEANUP_PLAN_PATH" ] || [ ! -f "$CLEANUP_PLAN_PATH" ]; then
  echo "ERROR: Cleanup plan not created" >&2
  exit 1
fi
```

**4-Section Console Summary Output**:
```bash
=== /todo --clean Complete ===

Summary: Generated cleanup plan for 193 eligible projects from Completed, Abandoned, and Superseded sections. Plan includes git verification, timestamped archival, and directory removal phases.

Artifacts:
  📄 Cleanup Plan: /home/user/.config/.claude/specs/975_cleanup/plans/001-cleanup-plan.md

Next Steps:
  • Review plan: cat /home/user/.config/.claude/specs/975_cleanup/plans/001-cleanup-plan.md
  • Execute cleanup: /build /home/user/.config/.claude/specs/975_cleanup/plans/001-cleanup-plan.md
  • Rescan projects: /todo

CLEANUP_PLAN_CREATED: /home/user/.config/.claude/specs/975_cleanup/plans/001-cleanup-plan.md
```

**Dry-Run Preview Output**:
```bash
=== Cleanup Preview (Dry Run) ===

Eligible projects: 193

Cleanup candidates (would be archived):
  - 102_plan_command_error_analysis: Fix /plan command error handling
  - 787_state_machine_persistence_bug: Repair state persistence bug
  - 788_commands_readme_update: Update commands README
  ... (190 more)

To generate cleanup plan, run: /todo --clean
```

### Integration Points

1. **plan-architect Agent**:
   - Already integrated in Clean Mode section (lines 624-651 of todo.md)
   - Receives filtered project list
   - Returns `CLEANUP_PLAN_CREATED:` signal (NEW requirement)
   - Enhanced prompt specifies git verification behavior

2. **State Persistence**:
   - Block 5 restores state from plan-architect barrier
   - Reads `DISCOVERED_PROJECTS` variable for eligible count
   - Preserves workflow ID for error logging

3. **Output Formatting Standards**:
   - Follows 4-section pattern from output-formatting.md (lines 378-403)
   - Uses emoji vocabulary from approved list (lines 462-470)
   - Meets length targets: 15-25 lines total (lines 513-522)

## Implementation Phases

### Phase 1: Add Dry-Run Preview Mode [COMPLETE]
dependencies: []

**Objective**: Add `--dry-run` preview mode to Clean Mode that displays cleanup candidates without generating a plan.

**Complexity**: Low

Tasks:
- [x] Add Block 4a after existing discovery blocks (file: /home/benjamin/.config/.claude/commands/todo.md, after line 617)
- [x] Check if both `CLEAN_MODE=true` and `DRY_RUN=true`
  - If both true: Display preview and exit
  - If only CLEAN_MODE true: Continue to plan generation
- [x] Restore state from Block 2c hard barrier
  - Source state file: `STATE_FILE=$(ls -t ~/.claude/data/state/todo_*.state 2>/dev/null | head -1)`
  - Load variables: `CLASSIFIED_RESULTS`, `SPECS_ROOT`
- [x] Filter eligible projects using `filter_completed_projects()`
  - Call: `ELIGIBLE_PROJECTS=$(filter_completed_projects "$CLASSIFIED_RESULTS")`
  - Count: `ELIGIBLE_COUNT=$(echo "$ELIGIBLE_PROJECTS" | jq 'length')`
- [x] Display preview output
  - Header: `=== Cleanup Preview (Dry Run) ===`
  - Count: `Eligible projects: $ELIGIBLE_COUNT`
  - List: Use jq to format project names and titles
  - Footer: `To generate cleanup plan, run: /todo --clean`
- [x] Exit after preview (don't continue to plan generation)
  - Use `exit 0` to terminate cleanly

Testing:
```bash
# Test dry-run preview
/todo --clean --dry-run

# Verify output shows eligible count
# Verify output lists project names
# Verify no plan file created
# Verify exit code 0
```

**Expected Duration**: 1 hour

---

### Phase 2: Add Standardized Completion Output [COMPLETE]
dependencies: [1]

**Objective**: Replace generic completion message in Clean Mode with standardized 4-section console summary format.

**Complexity**: Medium

Tasks:
- [x] Add Block 5 after plan-architect invocation (file: /home/benjamin/.config/.claude/commands/todo.md, after line 651)
- [x] Parse plan path from plan-architect signal
  - Extract path from `CLEANUP_PLAN_CREATED:` prefix
  - Validate path exists and is readable
  - Store in `CLEANUP_PLAN_PATH` variable
- [x] Restore state for eligible project count
  - Source state file from Block 2c
  - Read `DISCOVERED_PROJECTS` for filtering
  - Calculate `ELIGIBLE_COUNT` using `filter_completed_projects()`
- [x] Generate 4-section console summary
  - **Summary**: 2-3 sentences describing what was accomplished and why it matters
  - **Artifacts**: Single line with 📄 emoji, "Cleanup Plan:", and absolute path
  - **Next Steps**: Three bullets (review plan, execute via /build, rescan)
- [x] Use heredoc for clean formatting
  - Pattern: `cat << EOF ... EOF`
  - Ensures proper line breaks and indentation
- [x] Emit completion signal after summary
  - Format: `CLEANUP_PLAN_CREATED: $CLEANUP_PLAN_PATH`
  - Absolute path required
- [x] Remove old generic completion message (lines 659-671)
  - Delete entire old completion block
  - Replace with Block 5 implementation

Testing:
```bash
# Test standardized output
/todo --clean

# Verify 4-section format displayed
# Verify emoji markers present
# Verify absolute paths used
# Verify completion signal emitted
# Verify actionable next steps
```

**Expected Duration**: 1.5 hours

---

### Phase 3: Enhance plan-architect Prompt and Documentation [COMPLETE]
dependencies: [2]

**Objective**: Update plan-architect prompt with explicit git verification requirements and update documentation to reflect standardized output format.

**Complexity**: Low

Tasks:
- [x] Update plan-architect prompt (file: /home/benjamin/.config/.claude/commands/todo.md, lines 635-651)
  - Add explicit git verification phase requirements
  - Specify skip-and-warn behavior for uncommitted changes
  - Document that plan should preserve TODO.md (no modification)
  - Clarify archive approach (move, not delete)
  - Update expected plan phases section
- [x] Ensure prompt requests `CLEANUP_PLAN_CREATED:` signal
  - Add instruction for plan-architect to return signal
  - Format: "Return completion signal: CLEANUP_PLAN_CREATED: <plan-path>"
- [x] Update todo-command-guide.md (file: /home/benjamin/.config/.claude/docs/guides/commands/todo-command-guide.md)
  - Add "Clean Mode Output Format" section (after line 294)
  - Include example output (4-section console summary)
  - Document workflow: dry-run → clean → build → rescan
  - Add troubleshooting section for common issues
- [x] Update inline documentation in todo.md
  - Update Clean Mode description (lines 618-622)
  - Add examples of standardized output
  - Document dry-run preview mode
- [x] Verify standards compliance
  - Run library sourcing validator: `bash .claude/scripts/validate-all-standards.sh --staged`
  - Run error suppression validator
  - Run conditionals validator
  - Ensure no violations introduced

Testing:
```bash
# Test enhanced prompt
/todo --clean
# Review generated plan for git verification phase
# Verify plan includes skip-and-warn behavior
# Verify plan preserves TODO.md

# Standards compliance
bash .claude/scripts/validate-all-standards.sh --staged
# Verify no violations
```

**Expected Duration**: 1.5 hours

---

## Testing Strategy

### Unit Testing (Phase 1)

Test dry-run preview mode:

1. **Dry-Run Output**:
   - Execute `/todo --clean --dry-run`
   - Verify eligible project count displayed
   - Verify project list formatted correctly
   - Verify no plan file created
   - Verify exit code 0
   - Verify guidance message displayed

### Integration Testing (Phase 2)

Test standardized output format:

1. **4-Section Console Summary**:
   - Execute `/todo --clean`
   - Verify Summary section present (2-3 sentences)
   - Verify Artifacts section has 📄 emoji and absolute path
   - Verify Next Steps section has 3 actionable bullets
   - Verify completion signal emitted with absolute path

2. **Signal Parsing**:
   - Verify `CLEANUP_PLAN_CREATED:` signal correctly parsed
   - Verify plan path extracted and validated
   - Verify error handling if plan not created

### Workflow Testing (Phase 3)

Test complete cleanup workflow:

1. **Full Workflow Execution**:
   - Execute `/todo --clean --dry-run` (preview)
   - Execute `/todo --clean` (generate plan)
   - Review plan file content
   - Execute `/build <plan-path>` (cleanup execution)
   - Execute `/todo` (rescan and update TODO.md)

2. **Generated Plan Content**:
   - Verify plan includes git verification phase
   - Verify plan specifies skip-and-warn for uncommitted changes
   - Verify plan includes archive creation with timestamp
   - Verify plan preserves TODO.md (no modification)
   - Verify plan has verification phase

### Standards Compliance Testing

- **Library Sourcing**: Verify three-tier sourcing pattern maintained
- **Error Handling**: Verify error logging integration
- **Output Formatting**: Verify 4-section pattern compliance
- **Documentation**: Verify README structure and link validity

### Test Coverage Requirements

- **Unit Tests**: Dry-run preview mode tested
- **Integration Tests**: Output format and signal parsing tested
- **Workflow Tests**: Complete cleanup workflow validated
- **Standards Tests**: All validators pass

## Documentation Requirements

### Files to Update

1. **Command Documentation**:
   - `/home/benjamin/.config/.claude/commands/todo.md`: Add Block 4a (dry-run), Block 5 (output), update prompt
   - `/home/benjamin/.config/.claude/docs/guides/commands/todo-command-guide.md`: Add Clean Mode Output Format section

2. **Standards Documentation**:
   - No updates needed (follows existing output-formatting.md standards)

3. **Test Documentation**:
   - Inline documentation in test scripts (if tests created)

### Documentation Standards

- Follow CommonMark specification
- Use clear, concise language
- Include code examples with syntax highlighting
- No emojis in file content (only in terminal output)
- Document WHAT code does (not WHY)
- Use 4-section format for command completion summaries

### Required Sections

1. **Command Guide Updates**:
   - Clean Mode Output Format (example output, 4-section breakdown)
   - Workflow description (dry-run → clean → build → rescan)
   - Troubleshooting section (plan not created, signal parsing errors)

2. **Inline Documentation**:
   - Block 4a purpose (dry-run preview)
   - Block 5 purpose (standardized output)
   - plan-architect prompt updates (git verification requirements)

## Dependencies

### External Dependencies

- **bash**: Shell execution environment (required)
- **jq**: JSON parsing for eligible project count (required)
- **cat**: Heredoc output formatting (required)
- **grep**: Signal parsing (required)
- **cut**: Path extraction (required)
- **ls**: State file discovery (required)

### Internal Dependencies

1. **Libraries**:
   - `/home/benjamin/.config/.claude/lib/core/state-persistence.sh`: State restoration (Block 5)
   - `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh`: `filter_completed_projects()` function

2. **Command Blocks**:
   - Block 2c: Hard barrier (provides state file for restoration)
   - plan-architect Task block: Returns `CLEANUP_PLAN_CREATED:` signal

3. **Standards Files**:
   - `/home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md`: 4-section format specification

### Phase Dependencies

- Phase 2 depends on Phase 1 (completion output needs dry-run to be skippable)
- Phase 3 depends on Phase 2 (documentation describes implemented behavior)

**Note**: All phases are sequential in this plan.

## Risk Management

### Technical Risks

1. **Risk**: plan-architect may not return `CLEANUP_PLAN_CREATED:` signal in expected format
   - **Mitigation**: Add signal parsing validation with error handling
   - **Impact**: Medium (fallback to error message, no plan displayed)

2. **Risk**: State restoration may fail in Block 5
   - **Mitigation**: Graceful degradation (use default count if state missing)
   - **Impact**: Low (eligible count may be inaccurate but plan still created)

3. **Risk**: Dry-run preview may display incorrect eligible count
   - **Mitigation**: Test filtering logic thoroughly, verify against TODO.md sections
   - **Impact**: Low (preview only, no data modification)

### Operational Risks

1. **Risk**: Users may expect immediate execution instead of plan generation
   - **Mitigation**: Clear documentation emphasizing review-before-execute pattern
   - **Impact**: Low (users can still review plan before executing)

2. **Risk**: Output format changes may break downstream tooling
   - **Mitigation**: Maintain completion signal format for programmatic parsing
   - **Impact**: Low (signal format unchanged, only human-readable output enhanced)

### Recovery Procedures

1. **Rollback Output Format**: Revert Block 5, restore old completion message
2. **Disable Dry-Run**: Comment out Block 4a, default to plan generation
3. **Restore Plan-Architect Prompt**: Revert prompt changes if issues detected

## Rollback Strategy

If issues are discovered post-deployment:

1. **Immediate Rollback**:
   - Revert commit containing output format changes
   - Restore previous generic completion message
   - Notify users of rollback

2. **Partial Rollback**:
   - Keep dry-run preview (Block 4a)
   - Revert standardized output (Block 5)
   - Keep enhanced plan-architect prompt

3. **No Data Loss**:
   - Output format changes don't affect data or plan generation
   - Safe to rollback without data recovery concerns

## Notes

- This plan maintains the plan-generation approach (no execution model change)
- Focuses on output standardization and user experience improvements
- No --execute flag removal needed (flag doesn't exist)
- Git verification strategy handled in generated plan (not /todo command)
- Dry-run preview enhances safety by allowing users to preview before plan generation
- Completion signal enables orchestrator parsing for workflow automation
- Follows output-formatting.md standards for consistency across commands
