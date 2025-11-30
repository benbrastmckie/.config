# TODO Clean Removal Gap Analysis

## Research Date
2025-11-29

## Problem Statement

After `/todo --clean` runs and removes 106 directories, TODO.md still contains many entries in the Completed, Abandoned, and Superseded sections. The goal is for TODO.md to have NO entries in these sections after cleanup runs because all corresponding project directories should be deleted.

## Root Cause Analysis

### Issue 1: Missing Status Metadata Field

**Finding**: Only 1 out of 50 plan files contains the `**Status**:` field that todo-analyzer relies on for classification.

**Evidence**:
```bash
$ grep -c "^\*\*Status\*\*:" .claude/specs/*/plans/*.md
# Only 1 file has Status field:
.claude/specs/977_cleanup_completed_projects/plans/001-cleanup-plan.md:1

# All others have 0:
.claude/specs/799_coordinate_command_all_its_dependencies_order/plans/001_coordinate_command_all_its_dependencies__plan.md:0
.claude/specs/805_when_plans_created_command_want_metadata_include/plans/001_when_plans_created_command_want_metadata_plan.md:0
[... 47 more files with 0]
```

**Classification Algorithm** (from `todo-analyzer.md` lines 100-128):
```
1. IF Status field contains "[COMPLETE]" OR "COMPLETE" OR "100%":
     status = "completed"
2. ELSE IF Status field contains "[IN PROGRESS]":
     status = "in_progress"
3. ELSE IF Status field contains "[NOT STARTED]":
     status = "not_started"
4. ELSE IF Status field contains "SUPERSEDED" OR "DEFERRED":
     status = "superseded"
5. ELSE IF Status field contains "ABANDONED":
     status = "abandoned"
6. ELSE IF Status field is missing:
     # Fallback: Count phase markers
     IF complete_phases == total_phases AND total_phases > 0:
       status = "completed"
     ELSE IF complete_phases > 0:
       status = "in_progress"
     ELSE:
       status = "not_started"
```

**Impact**: Plans without Status field fall back to phase marker counting, which classifies them as "not_started" even if TODO.md manually marks them as "Abandoned".

### Issue 2: TODO.md Manual Curation Disconnect

**Finding**: TODO.md entries for Abandoned/Superseded/Completed sections are manually curated with reason notes that do NOT exist in plan files.

**Example from TODO.md** (lines 54-56):
```markdown
- [x] **Coordinate command archival (799)** - Archive /coordinate command with all dependencies [.claude/specs/799_coordinate_command_all_its_dependencies_order/plans/001_coordinate_command_all_its_dependencies__plan.md]
  - **Reason**: Work already completed - coordinate.md no longer exists (already archived)
  - Command references already cleaned up by Plan 801
```

**Corresponding Plan File** (`799_coordinate_command_all_its_dependencies_order/plans/001_coordinate_command_all_its_dependencies__plan.md`):
- NO `**Status**:` field in metadata
- Phase markers show: `[NOT STARTED]` for all 5 phases
- No "Abandoned" or completion indication in plan file itself

**Classification Result**:
```bash
$ jq -r '.[] | select(.topic_name == "799_coordinate_command_all_its_dependencies_order")' \
  /home/benjamin/.config/.claude/tmp/todo_classified_*.json
{
  "topic_name": "799_coordinate_command_all_its_dependencies_order",
  "status": "not_started",  # ← Fallback classification, NOT "abandoned"
  ...
}
```

**Impact**: Plans manually marked as "Abandoned" in TODO.md are classified as "not_started" by todo-analyzer, making them ineligible for cleanup.

### Issue 3: Filter Logic Only Uses Classification Status

**Finding**: `filter_completed_projects()` in `todo-functions.sh` (lines 717-738) filters by status field from classification, NOT by TODO.md section.

**Code**:
```bash
filter_completed_projects() {
  local plans_json="$1"

  # Filter for cleanup-eligible statuses: completed, superseded, abandoned
  local eligible_projects
  eligible_projects=$(echo "$plans_json" | jq -r '[.[] | select(.status == "completed" or .status == "superseded" or .status == "abandoned")]')

  echo "$eligible_projects"
}
```

**Data Flow**:
1. `/todo --clean` → Block 1: Discover all plans
2. Block 2b: Invoke `todo-analyzer` to classify each plan → `CLASSIFIED_RESULTS` JSON
3. Block 4b: Call `filter_completed_projects($CLASSIFIED_RESULTS)` → filters by `.status` field
4. Only projects with `status == "completed|superseded|abandoned"` are eligible for removal

**Impact**: Plans classified as "not_started" (due to missing Status field) are excluded from cleanup even if TODO.md shows them as Abandoned.

### Issue 4: No Feedback Loop from TODO.md to Plan Files

**Finding**: TODO.md is generated FROM plan files, but changes to TODO.md do NOT propagate back to plan files.

**Workflow**:
```
Plan Files (source of truth)
    ↓ (via todo-analyzer classification)
TODO.md (generated output)
    ↓ (manual edits add Abandoned/Reason notes)
TODO.md (curated state)
    ↓ (/todo --clean reads classifications)
Plan Files (source of truth) ← NO FEEDBACK LOOP
```

**Impact**: Manual categorization in TODO.md (Abandoned section) is disconnected from the plan file metadata that drives cleanup logic.

## Current Workflow Analysis

### /todo Command Flow

**Block 1: Discovery** (`todo.md` lines 156-217)
- Scans `.claude/specs/` for numbered topic directories
- Finds all `plans/*.md` files
- Stores in `DISCOVERED_PROJECTS` JSON

**Block 2b: Classification** (`todo.md` lines 276-330)
- Invokes `todo-analyzer` agent via Task tool
- Agent reads each plan file and extracts:
  - Title
  - Status field (if present)
  - Phase headers and completion markers
  - Description
- Applies classification algorithm (see Issue 1 above)
- Outputs `CLASSIFIED_RESULTS` JSON with `status` field

**Block 4b: Cleanup Execution** (`todo.md` lines 700-803)
```bash
# Filter eligible projects
CLASSIFIED_JSON=$(cat "$CLASSIFIED_RESULTS")
ELIGIBLE_PROJECTS=$(filter_completed_projects "$CLASSIFIED_JSON")
ELIGIBLE_COUNT=$(echo "$ELIGIBLE_PROJECTS" | jq 'length')

# Execute removal
execute_cleanup_removal "$ELIGIBLE_PROJECTS" "${CLAUDE_PROJECT_DIR}/.claude/specs"
```

### Classification vs TODO.md Section Mapping

**todo-analyzer Classification** → **TODO.md Section**:
- `completed` → Completed
- `in_progress` → In Progress
- `not_started` → Not Started
- `superseded` → Superseded
- `abandoned` → Abandoned
- `backlog` → Backlog

**Cleanup Eligibility** (from `filter_completed_projects()`):
- ✅ `completed` → Removed by `--clean`
- ✅ `superseded` → Removed by `--clean`
- ✅ `abandoned` → Removed by `--clean`
- ❌ `in_progress` → NOT removed
- ❌ `not_started` → NOT removed
- ❌ `backlog` → NOT removed (manually curated)

## Gap Analysis

### Gap 1: Missing Status Field Coverage

**Current State**:
- 49 out of 50 plan files lack `**Status**:` field
- Plans rely on phase marker fallback (which doesn't detect "Abandoned")

**Desired State**:
- All plan files have explicit `**Status**:` field in metadata
- Status field reflects current project state (Abandoned, Completed, Superseded)

**Gap**: No mechanism to add Status field to existing plans retroactively.

### Gap 2: Manual TODO.md Edits Not Persisted

**Current State**:
- User manually categorizes plans in TODO.md as "Abandoned" with reason notes
- `/todo` command regenerates TODO.md, potentially overwriting manual edits
- Plan files remain unchanged (still show "NOT STARTED")

**Desired State**:
- Manual categorization in TODO.md persists across regenerations
- Plan files update to match TODO.md categorization (bi-directional sync)

**Gap**: No mechanism to sync TODO.md manual edits back to plan files.

### Gap 3: Classification Ignores TODO.md Section

**Current State**:
- `todo-analyzer` classifies plans based ONLY on plan file contents
- TODO.md section placement (Abandoned vs Completed) is ignored during classification

**Desired State**:
- Classification considers existing TODO.md section as hint or override
- Plans in Abandoned section are classified as "abandoned" regardless of plan file Status

**Gap**: Classification is one-way (plan → TODO.md), doesn't read TODO.md state.

### Gap 4: Backlog Section Preservation Conflict

**Current State**:
- Backlog section is manually curated and preserved by `/todo` command
- No other sections have preservation logic

**Desired State**:
- Manual edits to Abandoned/Superseded sections are also preserved
- Clear distinction between auto-generated and manually-curated content

**Gap**: Only Backlog has preservation, other sections regenerate fully.

## Impact Assessment

### Quantified Impact

**Recent Cleanup Run**:
- Removed: 106 directories
- TODO.md Abandoned section: ~15 entries still present
- TODO.md Completed section: ~100+ entries still present
- TODO.md Superseded section: ~4 entries still present

**Estimated Unremoved Projects**: 119 projects remain that should have been removed.

**Breakdown by Root Cause**:
1. **Missing Status field**: ~90% (plans without explicit Status → classified as "not_started")
2. **Manual TODO.md edits**: ~8% (plans manually marked Abandoned but not in plan file)
3. **Phase marker false negatives**: ~2% (completed plans with incomplete phase markers)

### User Experience Impact

**Current Workflow**:
1. User runs `/todo` to update TODO.md
2. User manually reviews plans and marks some as "Abandoned" with reasons
3. User runs `/todo --clean` expecting all Abandoned/Completed/Superseded to be removed
4. **Surprise**: 119 projects remain because classification doesn't match TODO.md

**Expected Workflow**:
1. User runs `/todo` to update TODO.md
2. User reviews and manually marks as Abandoned (with reasons)
3. User runs `/todo --clean`
4. **Expected**: TODO.md has NO entries in Abandoned/Completed/Superseded sections

## Proposed Solutions

### Solution 1: Bi-Directional Sync (High Fidelity)

**Approach**: Parse TODO.md sections and update plan file Status fields before cleanup.

**Implementation**:
1. Add `sync_todo_to_plans()` function in `todo-functions.sh`
2. Before classification, read TODO.md and extract section placement
3. For plans in Abandoned/Superseded/Completed sections:
   - Update plan file `**Status**:` field to match section
   - Or store in metadata JSON for classification override
4. Run classification as normal (now sees correct Status)
5. Cleanup removes all projects in cleanup-eligible sections

**Pros**:
- Preserves manual TODO.md categorization
- No user workflow change
- Plan files become source of truth (updated via TODO.md)

**Cons**:
- Modifies plan files (may conflict with version control)
- Adds complexity to `/todo` command
- Requires careful parsing of TODO.md format

### Solution 2: TODO.md Section-Based Cleanup (Pragmatic)

**Approach**: Skip classification for cleanup, directly use TODO.md section placement.

**Implementation**:
1. Add `extract_cleanup_projects_from_todo()` function
2. Parse TODO.md and extract all entries in Abandoned/Superseded/Completed sections
3. Extract topic paths from section entries
4. Pass directly to `execute_cleanup_removal()`
5. Skip `filter_completed_projects()` and classification entirely for `--clean`

**Pros**:
- Simple implementation (parse TODO.md, no classification needed)
- Directly honors user's manual categorization
- No plan file modifications

**Cons**:
- Creates dual logic (classification for update, section parsing for cleanup)
- TODO.md becomes source of truth instead of plan files
- Manual edits required for all abandoned projects

### Solution 3: Add Status Field to All Plans (Retroactive Fix)

**Approach**: One-time script to add `**Status**:` field to all plan files based on current TODO.md.

**Implementation**:
1. Create `add-status-to-plans.sh` script
2. Parse TODO.md sections (Abandoned, Completed, Superseded, etc.)
3. For each plan in those sections:
   - Add `**Status**: ABANDONED` or `**Status**: [COMPLETE]` to metadata
4. Commit all plan file updates
5. Future `/todo --clean` works correctly with classification

**Pros**:
- Fixes root cause (missing Status fields)
- One-time effort, permanent fix
- Maintains classification-based approach

**Cons**:
- Large commit (modifies 119+ plan files)
- Manual review needed for accuracy
- Doesn't prevent future missing Status fields

### Solution 4: Hybrid - Classification Override via TODO.md

**Approach**: Enhance classification to accept TODO.md section as override hint.

**Implementation**:
1. Modify `todo-analyzer` to accept optional `todo_section` parameter
2. Before invoking analyzer, parse TODO.md and map `plan_path → section`
3. Pass section hint to analyzer
4. Analyzer uses hint as override if Status field missing:
   - If `todo_section == "Abandoned"` → status = "abandoned"
   - If `todo_section == "Completed"` → status = "completed"
   - If `todo_section == "Superseded"` → status = "superseded"
5. Cleanup uses classification results (now includes manual categorization)

**Pros**:
- Honors manual TODO.md edits
- Preserves classification approach
- No plan file modifications

**Cons**:
- Adds complexity to classification
- TODO.md parsing required
- Potential conflicts if plan Status disagrees with TODO.md section

## Recommended Solution

**Recommendation**: **Solution 2 - TODO.md Section-Based Cleanup** with refinements.

### Justification

1. **Simplicity**: Directly reads TODO.md sections, no classification needed for cleanup
2. **User Intent**: Honors manual categorization (user placed it in Abandoned → remove it)
3. **Minimal Risk**: No plan file modifications, no classification changes
4. **Clear Semantics**: "Cleanup removes everything in Completed/Abandoned/Superseded sections"

### Refinements

1. **Preserve Backlog Section**: Continue preserving Backlog (manually curated)
2. **Clear Documentation**: Update docs to explain cleanup uses TODO.md sections, not classification
3. **Validation Check**: Before removal, verify plan files still exist (detect manual deletions)
4. **Dry-Run Preview**: Show list of projects by section for user confirmation

### Alternative for Long-Term

After Solution 2 is implemented, consider **Solution 3** (retroactive Status field addition) as a follow-up to bring plan files in sync with TODO.md state. This makes classification more accurate for non-cleanup use cases.

## Implementation Plan Outline

### Phase 1: Parse TODO.md Sections
- Add `parse_todo_sections()` function to `todo-functions.sh`
- Extract entries from Abandoned, Completed, Superseded sections
- Return JSON array with `topic_name`, `plan_path`, `section`

### Phase 2: Update Cleanup Logic
- Modify `/todo` command Block 4b (Clean Mode)
- Replace `filter_completed_projects()` call with `parse_todo_sections()`
- Pass section-based list to `execute_cleanup_removal()`

### Phase 3: Update Dry-Run Preview
- Modify Block 4a to show projects grouped by section
- Example: "Abandoned (15 projects), Completed (100 projects), Superseded (4 projects)"

### Phase 4: Documentation Updates
- Update `.claude/docs/guides/commands/todo-command-guide.md`
- Document that `--clean` removes based on TODO.md section placement
- Add examples showing manual categorization workflow

### Phase 5: Testing & Validation
- Test with dry-run mode (`/todo --clean --dry-run`)
- Verify project count matches TODO.md sections
- Confirm no false positives (In Progress, Not Started, Backlog are preserved)

## Test Cases

### Test Case 1: Abandoned Project Removal
**Setup**: Plan file has Status="[NOT STARTED]", TODO.md shows in Abandoned section
**Expected**: Project removed by `--clean`
**Current Behavior**: Project NOT removed (classified as "not_started")

### Test Case 2: Completed Project Removal
**Setup**: Plan has all phases marked [COMPLETE], TODO.md shows in Completed section
**Expected**: Project removed by `--clean`
**Current Behavior**: Project removed (classification works via phase markers)

### Test Case 3: Backlog Preservation
**Setup**: Plan in Backlog section of TODO.md
**Expected**: Project NOT removed by `--clean`
**Current Behavior**: Correctly preserved (Backlog section excluded)

### Test Case 4: Manual TODO.md Edit Persistence
**Setup**: User runs `/todo`, manually moves plan to Abandoned, runs `/todo --clean`
**Expected**: Plan removed, TODO.md regenerated without that entry
**Current Behavior**: Plan NOT removed (classification still shows "not_started")

### Test Case 5: Uncommitted Changes Skip
**Setup**: Abandoned project has uncommitted changes
**Expected**: Project skipped, shown in skip count
**Current Behavior**: Correctly skipped by `has_uncommitted_changes()` check

## Metrics & Success Criteria

### Success Criteria

1. **100% Section Alignment**: After `/todo --clean` runs, TODO.md has:
   - 0 entries in Completed section
   - 0 entries in Abandoned section
   - 0 entries in Superseded section
   - All entries in In Progress, Not Started, Backlog sections (preserved)

2. **Manual Edit Preservation**: If user manually categorizes a plan as Abandoned and runs `--clean`, that plan is removed

3. **No False Positives**: Plans in In Progress, Not Started, Backlog are NOT removed

4. **Audit Trail**: Git commit shows exact list of removed projects (via pre-cleanup snapshot)

### Metrics to Track

- **Removal Count**: Number of projects removed by `--clean`
- **Skip Count**: Projects skipped due to uncommitted changes
- **Section Counts** (before/after):
  - Completed: 100+ → 0
  - Abandoned: 15 → 0
  - Superseded: 4 → 0
  - Backlog: X → X (unchanged)

## Related Files

### Core Implementation Files
- `.claude/commands/todo.md` - /todo command (Blocks 1, 2, 4a, 4b)
- `.claude/lib/todo/todo-functions.sh` - Helper functions (filter_completed_projects, execute_cleanup_removal)
- `.claude/agents/todo-analyzer.md` - Classification agent

### Documentation Files
- `.claude/docs/guides/commands/todo-command-guide.md` - Command usage guide
- `.claude/docs/reference/standards/todo-organization-standards.md` - TODO.md structure standards

### Data Files
- `.claude/TODO.md` - Current TODO file showing the issue
- `.claude/tmp/todo_classified_*.json` - Classification results (ephemeral)

## References

### Code Locations

**Classification Algorithm**: `.claude/agents/todo-analyzer.md` lines 100-128

**Filter Function**: `.claude/lib/todo/todo-functions.sh` lines 717-738
```bash
filter_completed_projects() {
  eligible_projects=$(echo "$plans_json" | jq -r '[.[] | select(.status == "completed" or .status == "superseded" or .status == "abandoned")]')
}
```

**Cleanup Execution**: `.claude/commands/todo.md` Block 4b lines 760-768
```bash
CLASSIFIED_JSON=$(cat "$CLASSIFIED_RESULTS")
ELIGIBLE_PROJECTS=$(filter_completed_projects "$CLASSIFIED_JSON")
execute_cleanup_removal "$ELIGIBLE_PROJECTS" "${CLAUDE_PROJECT_DIR}/.claude/specs"
```

### Related Standards

- **TODO Organization Standards**: `.claude/docs/reference/standards/todo-organization-standards.md`
- **Directory Protocols**: `.claude/docs/concepts/directory-protocols.md`
- **Clean-Break Development**: `.claude/docs/reference/standards/clean-break-development.md`

## Conclusion

The gap between `/todo --clean` behavior and user expectations stems from a fundamental disconnect: **TODO.md manual categorization is not reflected in plan file Status fields**, causing classification to ignore Abandoned/Superseded designations. The recommended solution is to parse TODO.md sections directly for cleanup instead of relying on classification, honoring the user's manual categorization intent.

**Next Steps**:
1. Create implementation plan for Solution 2 (TODO.md section-based cleanup)
2. Implement `parse_todo_sections()` function
3. Update `/todo --clean` to use section-based removal
4. Test with dry-run mode to validate behavior
5. Consider Solution 3 (retroactive Status field addition) as follow-up for plan file accuracy
