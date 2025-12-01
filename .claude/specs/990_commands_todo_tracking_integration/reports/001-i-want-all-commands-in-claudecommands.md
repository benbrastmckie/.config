# Command-Level TODO.md Tracking Integration Specification

## Executive Summary

This specification defines how all commands in `.claude/commands/` should integrate with `/home/benjamin/.config/.claude/TODO.md` to provide automatic project status tracking. The goal is to eliminate manual TODO.md updates by having commands automatically update relevant sections when they create, revise, debug, or complete plans.

## TODO.md Structure Reference

TODO.md follows a strict 7-section hierarchy as defined in `TODO Organization Standards`:

| Section | Purpose | Checkbox | Update Policy |
|---------|---------|----------|---------------|
| **In Progress** | Active implementation | `[x]` | Auto-updated by commands |
| **Not Started** | Planned but not begun | `[ ]` | Auto-updated by commands |
| **Research** | Research-only projects (no plans) | `[ ]` | Auto-updated by commands |
| **Saved** | Demoted items to revisit later | `[ ]` | **Preserved** (manual curation) |
| **Backlog** | Manual prioritization queue | `[ ]` | **Preserved** (manual curation) |
| **Abandoned** | Intentionally stopped or superseded | `[x]` | Auto-updated by commands |
| **Completed** | Successfully finished | `[x]` | Auto-updated with date grouping |

**Entry Format**:
```markdown
- [checkbox] **{Plan Title}** - {Brief description} [{relative-path}]
  - Report: {report-path}
  - Summary: {summary-path}
```

## Available TODO Utility Functions

From `.claude/lib/todo/todo-functions.sh`:

### Core Functions
- `update_todo_section(section, plan_path, title, description, artifacts_json)` - Update specific section with plan entry
- `move_plan_between_sections(plan_path, from_section, to_section)` - Move plan to different status
- `add_artifact_to_plan(plan_path, artifact_type, artifact_path)` - Add artifact link to existing plan entry
- `mark_plan_completed(plan_path, title, description)` - Move plan to Completed with today's date
- `mark_plan_in_progress(plan_path, title, description)` - Move plan to In Progress
- `mark_plan_abandoned(plan_path, reason, superseded_by_path)` - Mark plan as abandoned (optionally superseded)
- `preserve_backlog_section()` - Extract and preserve Backlog content during updates

### Validation Functions
- `plan_exists_in_todo(plan_path)` - Check if plan is already tracked
- `get_plan_current_section(plan_path)` - Find which section contains plan
- `validate_todo_structure()` - Verify TODO.md has all required sections

## Command Analysis and Integration Specifications

### Category 1: Plan Creation Commands

#### /plan - Create New Implementation Plan

**What it does**: Creates research reports and implementation plan in new topic directory

**Current Artifacts Created**:
- Research reports: `.claude/specs/{NNN_topic}/reports/001-*.md`
- Implementation plan: `.claude/specs/{NNN_topic}/plans/001-*.md`

**TODO.md Integration Points**:

| Event | When | Action | Details |
|-------|------|--------|---------|
| **Plan Created** | End of Block 6 (after PLAN_CREATED signal) | Add to **Not Started** section | - Extract plan title from metadata<br>- Extract brief description (first 100 chars)<br>- Add plan path as primary link<br>- Add research reports as artifact bullets |

**Implementation Location**: Block 6 (after plan creation verified, before console summary)

**Sample Code**:
```bash
# After PLAN_CREATED verification in Block 6
PLAN_TITLE=$(extract_plan_title "$PLAN_FILE")
PLAN_DESC=$(extract_plan_description "$PLAN_FILE" | head -c 100)

# Collect research reports
RESEARCH_ARTIFACTS=$(find "$RESEARCH_DIR" -name '*.md' -type f | jq -R . | jq -s '{reports: .}')

# Add to TODO.md Not Started section
update_todo_section "Not Started" "$PLAN_FILE" "$PLAN_TITLE" "$PLAN_DESC" "$RESEARCH_ARTIFACTS"

echo "✓ Added to TODO.md (Not Started section)"
```

---

#### /research - Create Research-Only Reports

**What it does**: Creates comprehensive research reports without planning phase

**Current Artifacts Created**:
- Research reports: `.claude/specs/{NNN_topic}/reports/001-*.md`

**TODO.md Integration Points**:

| Event | When | Action | Details |
|-------|------|--------|---------|
| **Research Complete** | Block 2 (after report verification) | Add to **Research** section | - Extract title from report or topic directory<br>- Link to topic directory (not plan)<br>- Include report artifacts |

**Implementation Location**: Block 2 (after research report verification)

**Sample Code**:
```bash
# After research reports created and verified
TOPIC_TITLE=$(extract_topic_title "$SPECS_DIR")
TOPIC_DESC=$(extract_report_summary "$RESEARCH_DIR/001-*.md" | head -c 100)

# Collect research reports
RESEARCH_ARTIFACTS=$(find "$RESEARCH_DIR" -name '*.md' -type f | jq -R . | jq -s '{reports: .}')

# Add to TODO.md Research section (links to directory, not plan)
update_todo_section "Research" "$SPECS_DIR/" "$TOPIC_TITLE" "$TOPIC_DESC" "$RESEARCH_ARTIFACTS"

echo "Added to TODO.md (Research section)"
```

**Rationale**: Research-only projects without plans are tracked in the Research section for visibility. Users can reference these when creating plans via /plan command or promote to plans via /repair.

---

### Category 2: Plan Implementation Commands

#### /build - Execute Implementation Plan

**What it does**: Orchestrates multi-phase implementation from existing plan file

**Current Artifacts Created**:
- Implementation summaries: `.claude/specs/{NNN_topic}/summaries/001-*.md`
- Test results: `.claude/specs/{NNN_topic}/outputs/test_results_*.md`

**TODO.md Integration Points**:

| Event | When | Action | Details |
|-------|------|--------|---------|
| **Build Started** | Block 1 (after state machine init, before research phase) | Move to **In Progress** section | - Check if plan exists in TODO.md<br>- Move from "Not Started" to "In Progress"<br>- Update checkbox from `[ ]` to `[x]` |
| **Phase Completed** | After each phase transition (research→plan→implement→test→document) | Update artifacts | - Add phase-specific artifacts (reports, summaries, test results)<br>- Keep in "In Progress" section |
| **Build Completed** | Block 6 (after STATE_COMPLETE transition) | Move to **Completed** section | - Move from "In Progress" to "Completed"<br>- Add completion date grouping<br>- Include all artifacts (reports, summaries, test results) |

**Implementation Locations**:

1. **Start tracking** (Block 1, after sm_init):
```bash
# After state machine initialization
if plan_exists_in_todo "$PLAN_FILE"; then
  mark_plan_in_progress "$PLAN_FILE" "$(extract_plan_title "$PLAN_FILE")" "Implementation started"
  echo "✓ Moved to In Progress in TODO.md"
else
  # Plan not tracked yet - add it
  PLAN_TITLE=$(extract_plan_title "$PLAN_FILE")
  PLAN_DESC="Implementation in progress"
  update_todo_section "In Progress" "$PLAN_FILE" "$PLAN_TITLE" "$PLAN_DESC" "{}"
  echo "✓ Added to In Progress in TODO.md"
fi
```

2. **Completion tracking** (Block 6, after sm_transition COMPLETE):
```bash
# After workflow completion
PLAN_TITLE=$(extract_plan_title "$PLAN_FILE")
COMPLETION_DESC="All phases completed successfully"

# Collect all artifacts
ARTIFACTS=$(jq -n \
  --argjson reports "$(find "$RESEARCH_DIR" -name '*.md' -type f 2>/dev/null | jq -R . | jq -s .)" \
  --argjson summaries "$(find "$SUMMARIES_DIR" -name '*.md' -type f 2>/dev/null | jq -R . | jq -s .)" \
  --argjson tests "$(find "$OUTPUTS_DIR" -name 'test_results_*.md' -type f 2>/dev/null | jq -R . | jq -s .)" \
  '{reports: $reports, summaries: $summaries, test_results: $tests}')

mark_plan_completed "$PLAN_FILE" "$PLAN_TITLE" "$COMPLETION_DESC"

# Add all artifacts to the completed entry
echo "$ARTIFACTS" | jq -r '.reports[]' | while read report; do
  add_artifact_to_plan "$PLAN_FILE" "Report" "$report"
done
echo "$ARTIFACTS" | jq -r '.summaries[]' | while read summary; do
  add_artifact_to_plan "$PLAN_FILE" "Summary" "$summary"
done

echo "✓ Moved to Completed in TODO.md with all artifacts"
```

---

### Category 3: Plan Revision Commands

#### /revise - Research and Revise Existing Plan

**What it does**: Creates research reports analyzing revision requirements, then revises existing plan

**Current Artifacts Created**:
- Revision research reports: `.claude/specs/{NNN_topic}/reports/revision_*.md`
- Plan backup: `.claude/specs/{NNN_topic}/plans/backups/{plan}_{timestamp}.md`
- Revised plan (overwrites): `.claude/specs/{NNN_topic}/plans/001-*.md`

**TODO.md Integration Points**:

| Event | When | Action | Details |
|-------|------|--------|---------|
| **Revision Started** | Block 3 (after state machine init) | Update **In Progress** section | - Add revision note to plan description<br>- Add research artifact links as they're created |
| **Research Phase Complete** | Block 4c (after research verification) | Update artifacts | - Add revision research report links to plan entry<br>- Keep in current section |
| **Revision Complete** | Block 6 (after PLAN_REVISED signal) | Update artifacts, keep current section | - Add backup path as artifact<br>- Update timestamp in entry<br>- **DO NOT** change section (plan remains in same status) |

**Implementation Locations**:

1. **Start tracking** (Block 3):
```bash
# After state machine initialization
CURRENT_SECTION=$(get_plan_current_section "$EXISTING_PLAN_PATH")
PLAN_TITLE=$(extract_plan_title "$EXISTING_PLAN_PATH")

if [ -z "$CURRENT_SECTION" ]; then
  # Plan not yet in TODO.md - add to Not Started
  update_todo_section "Not Started" "$EXISTING_PLAN_PATH" "$PLAN_TITLE" "Plan under revision" "{}"
else
  # Update existing entry with revision note
  CURRENT_DESC=$(get_plan_description "$EXISTING_PLAN_PATH")
  update_todo_section "$CURRENT_SECTION" "$EXISTING_PLAN_PATH" "$PLAN_TITLE" \
    "$CURRENT_DESC (revision in progress)" "{}"
fi

echo "✓ Updated TODO.md with revision status"
```

2. **Completion tracking** (Block 6):
```bash
# After PLAN_REVISED verification
CURRENT_SECTION=$(get_plan_current_section "$EXISTING_PLAN_PATH")
PLAN_TITLE=$(extract_plan_title "$EXISTING_PLAN_PATH")

# Collect revision artifacts
REVISION_ARTIFACTS=$(jq -n \
  --arg backup "$BACKUP_PATH" \
  --argjson reports "$(find "$RESEARCH_DIR" -name 'revision_*.md' -type f 2>/dev/null | jq -R . | jq -s .)" \
  '{backup: $backup, revision_reports: $reports}')

# Update plan entry in current section with new artifacts
update_todo_section "$CURRENT_SECTION" "$EXISTING_PLAN_PATH" "$PLAN_TITLE" \
  "Plan revised (backup: $(basename "$BACKUP_PATH"))" "$REVISION_ARTIFACTS"

# Add artifacts individually
echo "$REVISION_ARTIFACTS" | jq -r '.revision_reports[]' | while read report; do
  add_artifact_to_plan "$EXISTING_PLAN_PATH" "Report" "$report"
done

echo "✓ Updated TODO.md with revision artifacts"
```

---

### Category 4: Debugging Commands

#### /debug - Debug Implementation Issues

**What it does**: Creates debug analysis reports and fix strategy

**Current Artifacts Created**:
- Debug reports: `.claude/specs/{NNN_topic}/debug/001-*.md`
- Root cause analysis: `.claude/specs/{NNN_topic}/debug/root_cause_analysis.md`

**TODO.md Integration Points**:

| Event | When | Action | Details |
|-------|------|--------|---------|
| **Debug Complete** | After debug report creation | Add debug artifact to plan | - Find plan in TODO.md (search by topic path)<br>- Add debug report as artifact bullet<br>- **DO NOT** change section (debugging doesn't change plan status) |

**Implementation Location**: After debug report verification

**Sample Code**:
```bash
# After debug report created and verified
TOPIC_PATH=$(dirname "$(dirname "$DEBUG_REPORT")")
PLAN_FILE=$(find "$TOPIC_PATH/plans" -name '*.md' -type f | head -1)

if [ -n "$PLAN_FILE" ] && plan_exists_in_todo "$PLAN_FILE"; then
  # Add debug report as artifact to existing plan
  add_artifact_to_plan "$PLAN_FILE" "Debug" "$DEBUG_REPORT"
  echo "✓ Added debug report to TODO.md plan entry"
else
  echo "Note: No plan found in TODO.md for this topic (debug reports are standalone artifacts)"
fi
```

---

### Category 5: Error Analysis Commands

#### /errors - Query Error Logs and Generate Reports

**What it does**: Generates error analysis reports from centralized error logs

**Current Artifacts Created**:
- Error analysis reports: `.claude/specs/{NNN_topic}/reports/001-*.md`

**TODO.md Integration Points**:

| Event | When | Action | Details |
|-------|------|--------|---------|
| **Error Report Complete** | After report generation (if report mode) | Add error report artifact | - Find related plan in TODO.md<br>- Add error analysis report as artifact<br>- **DO NOT** change section |

**Implementation Location**: Block 2 (after errors-analyst returns)

**Sample Code**:
```bash
# After error analysis report created
if [ "$QUERY_MODE" = "false" ]; then
  # Report mode - find related plan if exists
  TOPIC_PATH=$(dirname "$(dirname "$ERROR_REPORT")")
  PLAN_FILE=$(find "$TOPIC_PATH/plans" -name '*.md' -type f | head -1)

  if [ -n "$PLAN_FILE" ] && plan_exists_in_todo "$PLAN_FILE"; then
    add_artifact_to_plan "$PLAN_FILE" "Report" "$ERROR_REPORT"
    echo "✓ Added error analysis to TODO.md plan entry"
  fi
fi
```

---

#### /repair - Error Analysis and Repair Planning

**What it does**: Analyzes error patterns and creates implementation plan to fix them

**Current Artifacts Created**:
- Error analysis reports: `.claude/specs/{NNN_topic}/reports/001-*.md`
- Repair plan: `.claude/specs/{NNN_topic}/plans/001-*.md`

**TODO.md Integration Points**:

| Event | When | Action | Details |
|-------|------|--------|---------|
| **Repair Plan Created** | After plan-architect creates repair plan | Add to **Not Started** section | - Same as /plan command<br>- Include error analysis reports as artifacts<br>- Description indicates this is a repair plan |

**Implementation Location**: After plan creation verified (similar to /plan)

**Sample Code**:
```bash
# After repair plan created and verified
PLAN_TITLE=$(extract_plan_title "$PLAN_FILE")
PLAN_DESC="Error repair plan: $(echo "$ERROR_DESCRIPTION" | head -c 80)"

# Collect error analysis reports
ERROR_ARTIFACTS=$(find "$RESEARCH_DIR" -name '*.md' -type f | jq -R . | jq -s '{error_reports: .}')

update_todo_section "Not Started" "$PLAN_FILE" "$PLAN_TITLE" "$PLAN_DESC" "$ERROR_ARTIFACTS"

echo "✓ Added repair plan to TODO.md (Not Started section)"
```

---

### Category 6: Plan Structure Commands

#### /expand - Expand Phase/Stage to Separate File

**What it does**: Expands complex phases into detailed separate files (progressive organization)

**Current Artifacts Created**:
- Phase files: `.claude/specs/{NNN_topic}/plans/phase_{N}_*.md`
- Stage files: `.claude/specs/{NNN_topic}/plans/phase_{N}/stage_{M}_*.md`

**TODO.md Integration Points**:

| Event | When | Action | Details |
|-------|------|--------|---------|
| **Expansion Complete** | After phase/stage expansion | Update plan metadata note | - Find plan in TODO.md<br>- Add note about expanded structure<br>- **DO NOT** change section or status |

**Implementation Location**: After expansion verification

**Sample Code**:
```bash
# After phase/stage expansion complete
PLAN_DIR=$(dirname "$PHASE_FILE")
MAIN_PLAN=$(find "$PLAN_DIR" -name '*.md' -maxdepth 1 -type f | head -1)

if [ -n "$MAIN_PLAN" ] && plan_exists_in_todo "$MAIN_PLAN"; then
  CURRENT_SECTION=$(get_plan_current_section "$MAIN_PLAN")
  PLAN_TITLE=$(extract_plan_title "$MAIN_PLAN")
  CURRENT_DESC=$(get_plan_description "$MAIN_PLAN")

  # Update description to note expansion
  update_todo_section "$CURRENT_SECTION" "$MAIN_PLAN" "$PLAN_TITLE" \
    "$CURRENT_DESC (phase $PHASE_NUM expanded)" "{}"

  echo "✓ Updated TODO.md with expansion note"
fi
```

---

#### /collapse - Collapse Expanded Phase/Stage

**What it does**: Merges expanded phase content back into main plan

**Current Artifacts Created**:
- None (removes phase/stage files, updates main plan)

**TODO.md Integration Points**:

| Event | When | Action | Details |
|-------|------|--------|---------|
| **Collapse Complete** | After content merged back | Update plan metadata note | - Find plan in TODO.md<br>- Remove expansion note<br>- **DO NOT** change section or status |

**Implementation Location**: After collapse verification

**Sample Code**:
```bash
# After phase/stage collapse complete
if plan_exists_in_todo "$MAIN_PLAN"; then
  CURRENT_SECTION=$(get_plan_current_section "$MAIN_PLAN")
  PLAN_TITLE=$(extract_plan_title "$MAIN_PLAN")
  CURRENT_DESC=$(get_plan_description "$MAIN_PLAN")

  # Remove expansion note from description
  UPDATED_DESC=$(echo "$CURRENT_DESC" | sed 's/ (phase [0-9]* expanded)//')

  update_todo_section "$CURRENT_SECTION" "$MAIN_PLAN" "$PLAN_TITLE" "$UPDATED_DESC" "{}"

  echo "✓ Updated TODO.md after collapse"
fi
```

---

### Category 7: TODO Management Commands

#### /todo - Scan and Update TODO.md

**What it does**: Scans all specs directories, classifies plans, and updates TODO.md

**TODO.md Integration**:
- This command IS the TODO.md manager
- Regenerates entire TODO.md based on plan classification
- Preserves Backlog section (manual curation)
- No additional integration needed

---

#### /todo --clean - Remove Completed Projects

**What it does**: Removes projects in Completed/Abandoned sections, then regenerates TODO.md

**TODO.md Integration**:
- After removal: automatically rescans and regenerates TODO.md
- Removed projects no longer appear in any section
- No additional integration needed (built-in regeneration)

---

### Category 8: Utility Commands

#### /setup - Initialize Project Configuration

**What it does**: Generates or analyzes CLAUDE.md configuration file

**TODO.md Integration**: None needed (configuration file, not plan-related)

---

#### /convert-docs - Document Format Conversion

**What it does**: Converts between Markdown, DOCX, and PDF formats

**TODO.md Integration**: None needed (utility command, not plan-related)

---

## Implementation Priority

### Phase 1: Core Plan Lifecycle (High Priority)
1. `/plan` - Add newly created plans to "Not Started"
2. `/build` - Move to "In Progress" on start, move to "Completed" on finish
3. `/revise` - Add revision artifacts to existing plan entries

### Phase 2: Debugging and Error Tracking (Medium Priority)
4. `/debug` - Add debug reports as artifacts to existing plans
5. `/repair` - Add repair plans to "Not Started" with error context
6. `/errors` - Add error analysis reports as artifacts

### Phase 3: Plan Structure Management (Low Priority)
7. `/expand` - Add expansion notes to plan descriptions
8. `/collapse` - Remove expansion notes from plan descriptions

---

## Technical Implementation Details

### Library Function Signatures

From `.claude/lib/todo/todo-functions.sh`:

```bash
# Add or update plan in specific section
update_todo_section() {
  local section="$1"           # "In Progress", "Not Started", "Completed", etc.
  local plan_path="$2"          # Absolute path to plan file
  local title="$3"              # Plan title from metadata
  local description="$4"        # Brief description (max 100 chars)
  local artifacts_json="$5"     # JSON: {"reports":[],"summaries":[],"debug":[]}
}

# Move plan between sections
move_plan_between_sections() {
  local plan_path="$1"
  local from_section="$2"
  local to_section="$3"
}

# Add artifact link to existing plan entry
add_artifact_to_plan() {
  local plan_path="$1"
  local artifact_type="$2"     # "Report", "Summary", "Debug", "Test"
  local artifact_path="$3"      # Absolute path to artifact
}

# Specialized status functions
mark_plan_completed() {
  local plan_path="$1"
  local title="$2"
  local description="$3"
  # Moves to Completed section with today's date grouping
}

mark_plan_in_progress() {
  local plan_path="$1"
  local title="$2"
  local description="$3"
  # Moves to In Progress section
}

# Query functions
plan_exists_in_todo() {
  local plan_path="$1"
  # Returns 0 if plan found, 1 if not
}

get_plan_current_section() {
  local plan_path="$1"
  # Returns section name or empty string
}
```

### Artifact JSON Format

```json
{
  "reports": [
    ".claude/specs/027_topic/reports/001-analysis.md",
    ".claude/specs/027_topic/reports/002-research.md"
  ],
  "summaries": [
    ".claude/specs/027_topic/summaries/001-implementation.md"
  ],
  "debug": [
    ".claude/specs/027_topic/debug/001-root-cause.md"
  ],
  "test_results": [
    ".claude/specs/027_topic/outputs/test_results_1234567890.md"
  ],
  "backup": ".claude/specs/027_topic/plans/backups/001_plan_20251130.md"
}
```

### Extracting Plan Metadata

Commands need to extract metadata from plan files:

```bash
# Extract plan title from frontmatter or first heading
extract_plan_title() {
  local plan_file="$1"
  # Try frontmatter first
  local title=$(grep "^title:" "$plan_file" | head -1 | sed 's/^title: *//')
  if [ -z "$title" ]; then
    # Fallback to first heading
    title=$(grep "^# " "$plan_file" | head -1 | sed 's/^# *//')
  fi
  echo "$title"
}

# Extract brief description
extract_plan_description() {
  local plan_file="$1"
  # Try frontmatter first
  local desc=$(grep "^description:" "$plan_file" | head -1 | sed 's/^description: *//')
  if [ -z "$desc" ]; then
    # Fallback to first paragraph after title
    desc=$(awk '/^# / {flag=1; next} flag && /^[A-Z]/ {print; exit}' "$plan_file")
  fi
  echo "$desc" | head -c 100
}
```

---

## Error Handling and Edge Cases

### 1. Plan Already Exists in TODO.md

When a command tries to add a plan that's already tracked:

```bash
if plan_exists_in_todo "$PLAN_FILE"; then
  # Update existing entry instead of creating duplicate
  CURRENT_SECTION=$(get_plan_current_section "$PLAN_FILE")
  update_todo_section "$CURRENT_SECTION" "$PLAN_FILE" "$TITLE" "$DESC" "$ARTIFACTS"
else
  # Add new entry
  update_todo_section "Not Started" "$PLAN_FILE" "$TITLE" "$DESC" "$ARTIFACTS"
fi
```

### 2. TODO.md Doesn't Exist

First command run should create TODO.md with proper structure:

```bash
if [ ! -f "$TODO_PATH" ]; then
  # Initialize TODO.md with all sections
  initialize_todo_structure "$TODO_PATH"
fi
```

### 3. Artifact Path Formatting

All artifact paths in TODO.md should be relative to project root:

```bash
# Convert absolute to relative path
make_relative_path() {
  local abs_path="$1"
  local project_root="${CLAUDE_PROJECT_DIR}"
  echo "${abs_path#$project_root/}"
}
```

### 4. Concurrent Access

Multiple commands might update TODO.md simultaneously:

```bash
# Use file locking
update_todo_with_lock() {
  local lockfile="/tmp/todo_update.lock"
  (
    flock -x 200
    # Perform update
    update_todo_section "$@"
  ) 200>"$lockfile"
}
```

### 5. Preserving Backlog Section

Every update must preserve manually curated Backlog:

```bash
# Always preserve Backlog before regenerating
BACKLOG_CONTENT=$(preserve_backlog_section "$TODO_PATH")
# ... perform updates ...
# Restore Backlog
restore_backlog_section "$TODO_PATH" "$BACKLOG_CONTENT"
```

---

## Testing Strategy

### Unit Tests

Test each TODO function independently:

```bash
# Test update_todo_section
test_update_todo_section() {
  local test_todo=$(mktemp)
  initialize_todo_structure "$test_todo"

  update_todo_section "Not Started" "/path/to/plan.md" "Test Plan" "Test description" "{}"

  assert_contains "$test_todo" "Test Plan"
  assert_section_contains "$test_todo" "Not Started" "Test Plan"
}

# Test move_plan_between_sections
test_move_plan() {
  local test_todo=$(mktemp)
  setup_test_plan "$test_todo" "Not Started" "/path/to/plan.md"

  move_plan_between_sections "/path/to/plan.md" "Not Started" "In Progress"

  assert_section_not_contains "$test_todo" "Not Started" "plan.md"
  assert_section_contains "$test_todo" "In Progress" "plan.md"
}
```

### Integration Tests

Test full command workflows:

```bash
# Test /build workflow
test_build_todo_integration() {
  # Create test plan
  local test_plan=$(create_test_plan)

  # Run /build (should move to In Progress)
  /build "$test_plan"

  assert_section_contains "$TODO_PATH" "In Progress" "$(basename "$test_plan")"

  # Verify artifacts added
  assert_plan_has_artifact "$test_plan" "Summary"
}
```

### Regression Tests

Ensure TODO.md structure remains valid:

```bash
test_todo_structure_after_updates() {
  # Perform multiple operations
  create_multiple_test_plans

  # Verify structure still valid
  validate_todo_structure "$TODO_PATH"

  assert_has_section "$TODO_PATH" "In Progress"
  assert_has_section "$TODO_PATH" "Not Started"
  assert_has_section "$TODO_PATH" "Completed"
  assert_backlog_preserved "$TODO_PATH"
}
```

---

## Migration Strategy

### Phase 1: Library Functions (Week 1)
1. Implement core TODO functions in `todo-functions.sh`
2. Add unit tests for all functions
3. Document function APIs

### Phase 2: High-Priority Commands (Week 2)
1. Integrate `/plan` command
2. Integrate `/build` command
3. Integrate `/revise` command
4. Test end-to-end workflows

### Phase 3: Debugging Commands (Week 3)
1. Integrate `/debug` command
2. Integrate `/repair` command
3. Integrate `/errors` command

### Phase 4: Structure Commands (Week 4)
1. Integrate `/expand` command
2. Integrate `/collapse` command
3. Final integration testing
4. Documentation updates

---

## Summary

This specification provides:

1. **Complete Command Analysis**: All 17 commands analyzed for TODO.md integration needs
2. **Detailed Integration Points**: Exact timing and behavior for each command
3. **Implementation Code**: Sample bash code for each integration point
4. **Function Specifications**: Required TODO utility functions with signatures
5. **Error Handling**: Edge cases and mitigation strategies
6. **Testing Strategy**: Unit, integration, and regression test plans
7. **Migration Roadmap**: Phased implementation over 4 weeks

**Commands Requiring Integration**:
- **High Priority (4)**: /plan, /build, /revise, /research
- **Medium Priority (3)**: /debug, /repair, /errors
- **Low Priority (2)**: /expand, /collapse

**Commands Not Requiring Integration**:
- /todo (is the manager)
- /setup (configuration only)
- /convert-docs (utility only)

**Key Principles**:
1. **Automatic tracking**: No manual TODO.md updates required
2. **Status transitions**: Plans move through lifecycle automatically
3. **Research tracking**: Research-only projects visible in dedicated section
4. **Saved section**: Manual demotion of items for future consideration
5. **Artifact linking**: All related files linked to plan entries
6. **Backlog/Saved preservation**: Manual curation never overwritten
7. **Atomic updates**: File locking prevents concurrent write issues
