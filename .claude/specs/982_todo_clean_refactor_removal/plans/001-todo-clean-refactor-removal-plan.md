# TODO Clean Refactor - Direct Removal Plan

## Metadata
- **Date**: 2025-11-29
- **Feature**: Refactor /todo --clean to remove all projects in Completed, Abandoned, Superseded sections
- **Scope**: Update cleanup logic to parse TODO.md sections directly instead of relying on plan classification
- **Estimated Phases**: 5
- **Estimated Hours**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Complexity**: Medium
- **Structure Level**: 0
- **Complexity Score**: 62.0
- **Research Reports**:
  - [TODO Clean Removal Gap Analysis](/home/benjamin/.config/.claude/specs/982_todo_clean_refactor_removal/reports/001-todo-clean-removal-gap-analysis.md)

## Overview

The `/todo --clean` command currently removes only 106 directories while leaving 119+ entries in TODO.md's Completed, Abandoned, and Superseded sections. This occurs because cleanup relies on plan file classification (via `todo-analyzer`), but 98% of plans lack the `**Status**:` metadata field that classification depends on. Additionally, manual categorization in TODO.md (e.g., marking plans as "Abandoned" with reason notes) does not propagate to plan files.

This plan implements a direct solution: parse TODO.md sections during cleanup and remove all projects listed in Completed, Abandoned, and Superseded sections, regardless of plan file metadata. This honors user intent (manual categorization) and achieves the goal of zero entries in cleanup-eligible sections after `/todo --clean` runs.

## Research Summary

Key findings from the gap analysis research:

1. **Missing Status Field Coverage**: Only 1 out of 50 plan files contains the `**Status**:` metadata field. Plans without this field fall back to phase marker counting, which classifies them as "not_started" even when manually marked as "Abandoned" in TODO.md.

2. **Manual TODO.md Edits Ignored**: Users manually categorize plans in TODO.md sections (Abandoned, Completed, Superseded) with reason notes, but this categorization is not reflected in plan files. Classification ignores TODO.md section placement and only reads plan file contents.

3. **Filter Logic Only Uses Classification**: The `filter_completed_projects()` function in `todo-functions.sh` filters by the `status` field from classification JSON, not by TODO.md section placement. This creates a disconnect where manual categorization is invisible to cleanup logic.

4. **Recommended Solution**: Parse TODO.md sections directly for cleanup instead of using classification. This is simpler, honors user intent, and achieves the goal without modifying plan files or classification logic.

## Success Criteria

- [ ] After `/todo --clean` runs with actual removal, TODO.md has 0 entries in Completed section
- [ ] After `/todo --clean` runs with actual removal, TODO.md has 0 entries in Abandoned section
- [ ] After `/todo --clean` runs with actual removal, TODO.md has 0 entries in Superseded section
- [ ] Projects in In Progress, Not Started, and Backlog sections are NOT removed
- [ ] Manual categorization in TODO.md is preserved across regenerations (Backlog section)
- [ ] Dry-run preview shows projects grouped by section with accurate counts
- [ ] All removed projects are committed to git before deletion for recovery via git revert
- [ ] Uncommitted changes in eligible projects cause skip (existing safety check preserved)

## Technical Design

### Architecture Changes

**Current Flow** (Classification-Based):
```
Block 1: Discover plans → Store in JSON
Block 2: Classify via todo-analyzer → Classification JSON with status field
Block 4b: Filter by status (filter_completed_projects) → Remove directories
```

**New Flow** (Section-Based):
```
Block 1: Discover plans → Store in JSON
Block 2: Classify via todo-analyzer → Classification JSON (for TODO.md update)
Block 4b: Parse TODO.md sections → Extract Completed/Abandoned/Superseded entries → Remove directories
```

### Key Components

1. **New Function: `parse_todo_sections()`**
   - Location: `.claude/lib/todo/todo-functions.sh`
   - Purpose: Parse TODO.md and extract entries from cleanup-eligible sections
   - Input: TODO.md file path
   - Output: JSON array with `topic_name`, `topic_path`, `plan_path`, `section` fields
   - Logic: Uses sed/awk to extract entries from `## Completed`, `## Abandoned`, `## Superseded` sections

2. **Updated Function: Block 4b Cleanup Logic**
   - Location: `.claude/commands/todo.md` Block 4b
   - Current: Calls `filter_completed_projects($CLASSIFIED_JSON)`
   - New: Calls `parse_todo_sections($TODO_PATH)`
   - Rationale: Replace classification-based filtering with direct section parsing

3. **Updated Preview: Block 4a Dry-Run**
   - Location: `.claude/commands/todo.md` Block 4a
   - Enhancement: Show projects grouped by section (Completed: 100, Abandoned: 15, Superseded: 4)
   - Data Source: Use `parse_todo_sections()` output instead of classification

4. **Preserved Function: `execute_cleanup_removal()`**
   - No changes needed - function already handles git commit, uncommitted change checks, and directory removal
   - Input format remains the same (JSON array with `topic_path` field)

### Data Flow

**TODO.md Section Format** (from TODO Organization Standards):
```markdown
## Completed
- [x] **Project Title (NNN)** - Description [path/to/plan.md]
  - Related artifacts (reports, summaries)

## Abandoned
- [x] **Project Title (NNN)** - Description [path/to/plan.md]
  - **Reason**: Why abandoned
  - Additional context

## Superseded
- [~] **Project Title (NNN)** - Description [path/to/plan.md]
  - **Reason**: Superseded by newer plan
```

**Parsing Logic**:
1. Extract section blocks using sed: `/^## Completed$/,/^## /`
2. Extract topic numbers from entries: `**Title (NNN)**`
3. Map topic numbers to topic paths: `specs/NNN_topic_name/`
4. Build JSON array with topic_path for `execute_cleanup_removal()`

### Error Handling

- **TODO.md Not Found**: Log error, exit with clear message
- **Empty Section**: Continue with 0 eligible projects (valid state)
- **Malformed Entry**: Skip entry, log warning, continue processing
- **Missing Topic Directory**: Skip entry (already removed), log info

### Backward Compatibility

- Classification logic (`todo-analyzer`) remains unchanged - still used for TODO.md generation
- `filter_completed_projects()` function preserved - may be used by other tools
- TODO.md generation (Blocks 3-4) unchanged - sections still populated via classification
- Only Block 4b cleanup logic changes (when `--clean` flag provided)

## Implementation Phases

### Phase 1: Add TODO.md Section Parser [COMPLETE]
dependencies: []

**Objective**: Create `parse_todo_sections()` function to extract cleanup-eligible entries from TODO.md.

**Complexity**: Medium

Tasks:
- [x] Add `parse_todo_sections()` function to `.claude/lib/todo/todo-functions.sh` (file: .claude/lib/todo/todo-functions.sh)
- [x] Implement section extraction logic using sed to find `## Completed`, `## Abandoned`, `## Superseded` sections
- [x] Parse topic numbers from entry format: `**Title (NNN)**` using grep/awk
- [x] Map topic numbers to topic paths by scanning `$SPECS_ROOT/NNN_*/` directories
- [x] Build JSON array output with fields: `topic_name`, `topic_path`, `plan_path`, `section`
- [x] Add error handling for missing TODO.md file (return empty JSON array)
- [x] Add warning logging for malformed entries (skip and continue)
- [x] Add info logging for missing topic directories (already removed)

Testing:
```bash
# Unit test the parser function
source .claude/lib/todo/todo-functions.sh
TODO_PATH=".claude/TODO.md"
RESULT=$(parse_todo_sections "$TODO_PATH")
echo "$RESULT" | jq .

# Verify section extraction
echo "$RESULT" | jq -r '.[] | select(.section == "Completed") | .topic_name' | head -5
echo "$RESULT" | jq -r '.[] | select(.section == "Abandoned") | .topic_name' | head -5
echo "$RESULT" | jq -r '.[] | select(.section == "Superseded") | .topic_name' | head -5

# Verify JSON structure
echo "$RESULT" | jq 'length'  # Total count
echo "$RESULT" | jq '.[0]'    # Sample entry
```

**Expected Duration**: 2 hours

---

### Phase 2: Update Cleanup Logic to Use Section Parser [COMPLETE]
dependencies: [1]

**Objective**: Replace classification-based filtering with TODO.md section-based filtering in Block 4b.

**Complexity**: Low

Tasks:
- [x] Update `.claude/commands/todo.md` Block 4b (lines 700-803) (file: .claude/commands/todo.md)
- [x] Replace `filter_completed_projects($CLASSIFIED_JSON)` call with `parse_todo_sections($TODO_PATH)`
- [x] Update variable naming: `ELIGIBLE_PROJECTS=$(parse_todo_sections "$TODO_PATH")`
- [x] Verify `execute_cleanup_removal()` receives correct JSON format
- [x] Add error handling for TODO.md missing (log error, exit gracefully)
- [x] Preserve existing uncommitted changes check in `execute_cleanup_removal()`
- [x] Add comment documenting switch from classification to section-based approach

Testing:
```bash
# Dry-run test to verify parsing works
/todo --clean --dry-run

# Verify output shows correct project count
# Expected: matches number of entries in Completed/Abandoned/Superseded sections

# Check JSON structure passed to execute_cleanup_removal
# Add debug echo before execute_cleanup_removal call
echo "ELIGIBLE_PROJECTS JSON:"
echo "$ELIGIBLE_PROJECTS" | jq .
```

**Expected Duration**: 1 hour

---

### Phase 3: Update Dry-Run Preview to Show Section Grouping [COMPLETE]
dependencies: [1]

**Objective**: Enhance Block 4a dry-run preview to display projects grouped by section with counts.

**Complexity**: Low

Tasks:
- [x] Update `.claude/commands/todo.md` Block 4a (lines 620-698) (file: .claude/commands/todo.md)
- [x] Replace `filter_completed_projects()` call with `parse_todo_sections($TODO_PATH)`
- [x] Add section grouping logic using jq: `group_by(.section)`
- [x] Display section headers with counts: "Completed (100 projects)", "Abandoned (15 projects)", "Superseded (4 projects)"
- [x] Show first 10 entries per section (with "... (N more)" if >10)
- [x] Update preview message: "To execute cleanup (with git commit), run: /todo --clean"

Testing:
```bash
# Test dry-run preview
/todo --clean --dry-run

# Verify output format:
# === Cleanup Preview (Dry Run) ===
# Eligible projects: 119
#
# Cleanup candidates (grouped by section):
#
# Completed (100 projects):
#   - 799_coordinate_command: Coordinate command archival
#   - 801_cleanup_refs: Cleanup coordinate references
#   [... 8 more entries ...]
#   ... (90 more)
#
# Abandoned (15 projects):
#   - 805_metadata_include: Plan metadata enhancement
#   [... entries ...]
#
# Superseded (4 projects):
#   - 810_old_approach: Old implementation approach
#   [... entries ...]
```

**Expected Duration**: 1 hour

---

### Phase 4: Integration Testing and Validation [COMPLETE]
dependencies: [2, 3]

**Objective**: Validate end-to-end cleanup workflow with section-based approach.

**Complexity**: Medium

Tasks:
- [x] Create test TODO.md with known entries in each section (file: test-fixtures/TODO-test.md)
- [x] Run `/todo --clean --dry-run` and verify section counts match test data
- [x] Verify In Progress, Not Started, Backlog sections are NOT shown as cleanup candidates
- [x] Create test projects with uncommitted changes in Completed section
- [x] Verify uncommitted projects are skipped with proper logging
- [x] Execute actual cleanup: `/todo --clean` (in test environment)
- [x] Verify git commit created with proper message
- [x] Verify topic directories removed (check filesystem)
- [x] Verify TODO.md sections empty after cleanup (rescan with `/todo`)
- [x] Test recovery: `git revert <commit>` and verify directories restored

Testing:
```bash
# Setup test environment
cd /tmp/todo-cleanup-test
git init
mkdir -p .claude/specs/{100_completed,101_abandoned,102_superseded,103_in_progress}
# Create test TODO.md with entries in each section

# Dry-run preview
/todo --clean --dry-run
# Expected: Shows 100_completed, 101_abandoned, 102_superseded (3 projects)
# Expected: Does NOT show 103_in_progress

# Execute cleanup
/todo --clean
# Expected: Git commit created
# Expected: 3 directories removed
# Expected: Message shows "Removed: 3 projects"

# Verify filesystem
ls .claude/specs/
# Expected: Only 103_in_progress remains

# Verify recovery
git log --oneline -1  # Get commit hash
git revert HEAD
ls .claude/specs/
# Expected: All 4 directories restored
```

**Expected Duration**: 2 hours

---

### Phase 5: Documentation Updates [COMPLETE]
dependencies: [4]

**Objective**: Update documentation to reflect section-based cleanup approach.

**Complexity**: Low

Tasks:
- [x] Update `.claude/docs/guides/commands/todo-command-guide.md` (file: .claude/docs/guides/commands/todo-command-guide.md)
- [x] Add section "Cleanup Behavior" explaining TODO.md section-based removal
- [x] Document manual categorization workflow (user moves entry to Abandoned → run --clean)
- [x] Add examples showing section grouping in dry-run preview
- [x] Note that classification is still used for TODO.md generation (not cleanup)
- [x] Update `.claude/commands/todo.md` frontmatter documentation field if needed
- [x] Add inline comments in `parse_todo_sections()` explaining parsing logic
- [x] Document recovery procedure: git revert for mistaken cleanup

Testing:
```bash
# Verify documentation completeness
cat .claude/docs/guides/commands/todo-command-guide.md | grep -A 10 "Cleanup Behavior"

# Verify examples are accurate
# Run actual commands from docs examples to ensure they work

# Verify inline comments in code
grep -A 5 "parse_todo_sections()" .claude/lib/todo/todo-functions.sh | head -20
```

**Expected Duration**: 1 hour

---

## Testing Strategy

### Unit Testing
- **Function: `parse_todo_sections()`**
  - Test with well-formed TODO.md (all sections present)
  - Test with missing sections (empty Abandoned, Superseded)
  - Test with malformed entries (missing topic number, invalid format)
  - Test with missing TODO.md file (return empty JSON)
  - Verify JSON structure and field accuracy

### Integration Testing
- **Workflow: Dry-Run Preview**
  - Verify section grouping displays correctly
  - Verify counts match actual entries
  - Verify entry formatting (topic name, title)
  - Verify truncation logic (show first 10, "... (N more)")

- **Workflow: Actual Cleanup**
  - Verify git commit creation before removal
  - Verify directory removal for eligible projects
  - Verify uncommitted changes skip logic
  - Verify skip/failed counts in output
  - Verify recovery via git revert

### Edge Cases
- Empty TODO.md (no sections)
- All projects in Backlog (0 eligible)
- Missing topic directory (already removed)
- Uncommitted changes in all eligible projects (all skipped)
- TODO.md with duplicate entries (same topic in multiple sections)

### Regression Testing
- Verify default mode (`/todo` without --clean) still works
- Verify TODO.md generation (Blocks 3-4) unchanged
- Verify classification logic (`todo-analyzer`) still used for updates
- Verify Backlog section preservation unchanged

## Documentation Requirements

### Files to Update
1. **Command Guide**: `.claude/docs/guides/commands/todo-command-guide.md`
   - Add "Cleanup Behavior" section
   - Document manual categorization workflow
   - Add section-based removal examples

2. **Command File**: `.claude/commands/todo.md`
   - Update inline comments in Block 4b
   - Document `parse_todo_sections()` function in frontmatter

3. **Function Library**: `.claude/lib/todo/todo-functions.sh`
   - Add comprehensive inline comments for `parse_todo_sections()`
   - Document input/output format
   - Document error handling

### Examples to Include
- Manual categorization workflow (user moves to Abandoned → cleanup)
- Dry-run preview output format
- Recovery procedure (git revert)
- Section parsing logic explanation

## Dependencies

### External Dependencies
- **jq**: JSON parsing (already required by todo command)
- **sed/awk**: TODO.md section parsing (standard Unix tools)
- **git**: Commit creation and recovery (already required)

### Internal Dependencies
- **Library**: `.claude/lib/todo/todo-functions.sh` (existing, will be extended)
- **Function**: `execute_cleanup_removal()` (existing, no changes)
- **Function**: `has_uncommitted_changes()` (existing, used by execute_cleanup_removal)

### Configuration Dependencies
- **TODO.md Format**: Assumes TODO Organization Standards structure (6 sections, checkbox conventions)
- **Topic Directory Format**: Assumes `NNN_topic_name` directory naming pattern
- **Git Repository**: Requires git repository for commit creation

## Risk Mitigation

### Risk: Incorrect Section Parsing
- **Mitigation**: Comprehensive unit tests for `parse_todo_sections()`
- **Mitigation**: Dry-run preview allows user verification before execution
- **Mitigation**: Git commit before removal enables recovery

### Risk: Manual TODO.md Edits Lost
- **Mitigation**: Backlog section preservation already exists (preserve for all manual edits)
- **Mitigation**: Document workflow: regenerate TODO.md AFTER cleanup, not before

### Risk: Accidental Removal of Active Projects
- **Mitigation**: Only remove from Completed/Abandoned/Superseded sections
- **Mitigation**: In Progress, Not Started, Backlog are explicitly excluded
- **Mitigation**: Uncommitted changes check prevents removal of active work

### Risk: TODO.md Format Changes Break Parser
- **Mitigation**: Parser uses flexible regex patterns (tolerates whitespace variations)
- **Mitigation**: Error handling for malformed entries (skip and continue)
- **Mitigation**: Documentation specifies TODO Organization Standards as dependency

## Rollback Plan

If section-based cleanup causes issues:

1. **Immediate Rollback**: Revert Block 4b changes in `.claude/commands/todo.md`
   - Restore `filter_completed_projects()` call
   - Remove `parse_todo_sections()` call
   - Git commit revert

2. **Partial Rollback**: Keep `parse_todo_sections()` for dry-run preview only
   - Revert Block 4b (actual cleanup)
   - Keep Block 4a enhancement (section grouping)
   - Allows gradual migration

3. **Data Recovery**: If mistaken cleanup occurred
   - Use git revert to restore removed directories
   - Command: `git revert <commit-hash>`
   - Verify restoration with `ls .claude/specs/`

## Future Enhancements

### Option 1: Bi-Directional Sync (Follow-Up)
After section-based cleanup is stable, consider implementing bi-directional sync:
- Parse TODO.md sections
- Update plan file `**Status**:` fields to match TODO.md categorization
- Makes classification more accurate for non-cleanup use cases

### Option 2: Backlog Section Preservation
Extend manual edit preservation beyond Backlog:
- Preserve reason notes in Abandoned section
- Preserve metadata edits across regenerations
- Clear distinction between auto-generated and manually-curated content

### Option 3: Section-Based Undo
Add undo capability for section-based cleanup:
- Store removed projects in temporary JSON before deletion
- Add `/todo --undo-cleanup` to restore from last cleanup
- Alternative to git revert (more user-friendly)
