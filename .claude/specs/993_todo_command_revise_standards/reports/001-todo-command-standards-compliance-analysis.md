# /todo Command Standards Compliance Analysis

## Executive Summary

This report analyzes the significant discrepancy between the /todo command implementation and the TODO Organization Standards, identifying three critical architectural conflicts that must be resolved to ensure standards compliance while preserving the command's functional integrity.

**Key Finding**: The /todo command currently implements a **6-section** TODO.md structure (In Progress, Not Started, Backlog, Superseded, Abandoned, Completed), while the TODO Organization Standards mandate a **7-section** structure that includes both a **Research** section (for research-only projects without plans) and a **Saved** section (for manually demoted items to revisit later).

**Impact**: This discrepancy creates:
1. **Standards Non-Compliance**: Missing sections violate documented standards
2. **Manual Workflow Disruption**: Users cannot use the Saved section for intentional demotion
3. **Research Project Invisibility**: Research-only workflows have no dedicated tracking

**Recommendation**: Implement a phased revision to add the missing sections while maintaining backward compatibility with existing TODO.md files and preserving all manual curation mechanisms.

---

## Analysis Scope

### Documents Reviewed

1. **Command Implementation**: `.claude/commands/todo.md` (1228 lines)
2. **TODO Organization Standards**: `.claude/docs/reference/standards/todo-organization-standards.md` (383 lines)
3. **Command Guide**: `.claude/docs/guides/commands/todo-command-guide.md` (506 lines)
4. **Integration Specification**: `.claude/specs/990_commands_todo_tracking_integration/reports/001-i-want-all-commands-in-claudecommands.md` (789 lines)
5. **Library Implementation**: `.claude/lib/todo/todo-functions.sh` (1257 lines)
6. **Agent Implementation**: `.claude/agents/todo-analyzer.md` (451 lines)

### Current TODO.md Actual State

Current TODO.md file analysis reveals:
- **Section Count**: 6 sections (missing Research and Saved)
- **Section Order**: In Progress → Not Started → Backlog → Superseded → Abandoned → Completed
- **Backlog Content**: Manually curated with enhancement ideas and research links
- **Active Projects**: 1 In Progress, 8 Not Started, 4 Superseded, 49+ Abandoned, 0 explicitly Completed

---

## Critical Discrepancies Identified

### Discrepancy 1: Missing Research Section

**Standards Requirement** (TODO Organization Standards, Lines 13-19):

```markdown
| Section | Purpose | Auto-Updated | Checkbox |
|---------|---------|--------------|----------|
| Research | Research-only projects without plans | Yes | [ ] |
```

**Standards Definition** (Lines 163-198):

> The Research section tracks spec directories that contain research reports but no implementation plans. These are typically created by:
> - `/research` command (research-only workflows)
> - `/errors` command (error analysis reports)

**Current Implementation**: The /todo command has **no Research section** in its structure.

**Evidence**:

1. **Command Implementation** (`.claude/commands/todo.md`, Lines 36-46):
   ```markdown
   ## Sections and Classification
   TODO.md is organized into six sections...
   | Section | Purpose | Checkbox | Auto-Updated |
   |---------|---------|----------|--------------|
   | In Progress | Active implementation | [x] | Yes |
   | Not Started | Planned but not begun | [ ] | Yes |
   | Backlog | Manual prioritization queue | [ ] | No |
   | Superseded | Replaced by newer plans | [~] | Yes |
   | Abandoned | Intentionally discontinued | [x] | Yes |
   | Completed | Successfully finished | [x] | Yes |
   ```

2. **Library Implementation** (`todo-functions.sh`, Lines 881-917):
   ```bash
   validate_todo_structure() {
     # Check required sections exist
     local required_sections=("## In Progress" "## Not Started" "## Backlog"
                              "## Superseded" "## Abandoned" "## Completed")
     # Missing: "## Research"
   }
   ```

3. **Integration Specification** (Lines 88-111): Research section documented as a separate category but not integrated into command

**Impact**:

- Research-only projects (created by `/research` and `/errors` commands) have no dedicated tracking location
- Users must manually add research entries to Backlog or Not Started (violates auto-update principle)
- Current Backlog includes research links manually (Lines 35-40 in TODO.md), indicating workaround usage

**Standards-Compliant Workflow** (not currently supported):

```bash
# User runs /research command
/research "Error patterns analysis"
# Creates: specs/935_errors_repair_research/reports/001_error_analysis.md

# Expected: /research should auto-add entry to Research section
# Actual: Entry not added automatically, requires manual Backlog addition
```

---

### Discrepancy 2: Missing Saved Section

**Standards Requirement** (TODO Organization Standards, Lines 14-17):

```markdown
| Section | Purpose | Auto-Updated | Checkbox |
|---------|---------|--------------|----------|
| Saved | Demoted items to revisit later | No (manual) | [ ] |
```

**Standards Definition** (Lines 200-237):

> The Saved section holds items demoted from "Not Started" or "In Progress" that the user wants to revisit later. Unlike Abandoned items, Saved items are intentionally preserved for future consideration.
>
> **Manual Curation**: The Saved section is manually curated and NOT auto-updated by the `/todo` command.
>
> **Preservation Rules**:
> 1. `/todo` command MUST preserve existing Saved content
> 2. Items are moved manually from "Not Started" or "In Progress"
> 3. Each entry SHOULD include "Demoted from" and "Reason" metadata

**Current Implementation**: The /todo command has **no Saved section** in its structure.

**Evidence**:

1. **Command Implementation** (`.claude/commands/todo.md`): No mention of Saved section in workflow or structure
2. **Library Functions** (`todo-functions.sh`): No `extract_saved_section()` function (contrast with `extract_backlog_section()` at Line 391)
3. **Integration Specification**: Saved section mentioned in standards reference but not in command integration points

**Impact**:

- Users cannot intentionally demote items for later consideration (must choose between "Abandoned" or keeping in "Not Started")
- No semantic distinction between "abandoned completely" vs "saved for later"
- Forces all-or-nothing categorization (active vs abandoned) without middle ground
- Manual workflow disruption: Users resort to Backlog for saved items (mixing future ideas with paused work)

**Standards-Compliant Workflow** (not currently supported):

```bash
# User manually edits TODO.md to demote a plan
# Move from "## Not Started" to "## Saved"
# Add metadata:
- [ ] **Buffer Hook Reversion** - ... [path]
  - **Demoted from**: Not Started (2025-11-30)
  - **Reason**: Lower priority; revisit after core workflow improvements

# Expected: /todo preserves Saved section content
# Actual: /todo would regenerate and lose Saved section (no preservation logic)
```

---

### Discrepancy 3: Section Order Mismatch

**Standards Requirement** (TODO Organization Standards, Lines 10-19):

```markdown
1. **In Progress** - Actively being worked on
2. **Not Started** - Planned but not yet started
3. **Research** - Research-only projects (no plans)
4. **Saved** - Demoted items to revisit later
5. **Backlog** - Manually curated ideas and future enhancements
6. **Abandoned** - Intentionally stopped or superseded
7. **Completed** - Successfully finished
```

**Current Implementation** (Command, Lines 36-46):

```markdown
1. In Progress
2. Not Started
3. Backlog       # Standards position: 5
4. Superseded    # Standards merged into Abandoned (position 6)
5. Abandoned
6. Completed
```

**Analysis**:

1. **Backlog Position**: Command places at position 3, Standards specify position 5
2. **Superseded Treatment**: Command uses separate section, Standards merge into Abandoned with `[~]` checkbox
3. **Missing Sections**: Research (position 3) and Saved (position 4) entirely absent

**Impact on Migration**:

- Adding missing sections requires reordering existing sections
- Existing TODO.md files will need section reordering during upgrade
- Validation logic must be updated to reflect new canonical order

---

## Root Cause Analysis

### Why the Discrepancy Exists

**Hypothesis**: The /todo command was implemented based on an **earlier version** of the TODO Organization Standards that predated the Research and Saved sections.

**Evidence Timeline**:

1. **Command Implementation Date**: Unknown (no creation metadata in command file)
2. **Standards Last Updated**: Documentation includes Saved section with detailed workflow (Lines 200-237)
3. **Integration Specification Date**: 2025-11-28 (based on report structure)
4. **Current TODO.md State**: Uses 6-section structure, confirming command is driving actual behavior

**Contributing Factors**:

1. **No Validation Enforcement**: Command does not validate against standards document
2. **Hard-Coded Section Lists**: Section structure embedded in multiple locations:
   - Command markdown (Lines 36-46)
   - Library validation (Lines 881-917)
   - Agent classification logic (implied by categorize_plan function)
3. **Documentation Drift**: Standards evolved without triggering command updates

---

## Standards-Compliant Architecture

### Required 7-Section Structure

```markdown
# TODO

## In Progress
[x] Active implementation entries

## Not Started
[ ] Planned but not started entries

## Research
[ ] Research-only projects (no plans)
- Auto-populated by /research and /errors commands
- Links to topic directories (not plan files)

## Saved
[ ] Demoted items to revisit later
- Manually curated (preserved by /todo)
- Includes "Demoted from" and "Reason" metadata
- NOT auto-updated

## Backlog
Manual prioritization queue
- Enhancement ideas
- Research links
- Future features
- Completely user-defined structure

## Abandoned
[x] Intentionally stopped or superseded
- Includes [~] checkbox for superseded items
- Merged with Superseded section from old structure

## Completed
[x] Date-grouped completed entries
```

### Auto-Detection Rules for Research Section

**From Standards** (Lines 171-187):

```markdown
The `/todo` command identifies Research entries by:
1. Directory exists in `specs/` with `reports/` subdirectory
2. Directory has NO files in `plans/` subdirectory (or no `plans/` subdirectory)
3. Directory is not manually placed in other sections
```

**Implementation Requirements**:

1. Scan specs/ directories for research-only projects
2. Check for existence of `reports/` subdirectory with `.md` files
3. Check for absence of `plans/` subdirectory or empty `plans/`
4. Auto-add to Research section with directory link (not plan link)

**Entry Format** (Lines 182-186):

```markdown
- [ ] **{Topic Title}** - {Brief description from report} [.claude/specs/{NNN_topic}/]
  - Reports: [Report Title](.claude/specs/{NNN_topic}/reports/001-report.md)
```

### Preservation Logic for Saved Section

**From Standards** (Lines 209-217):

```markdown
### Preservation Rules

1. `/todo` command MUST preserve existing Saved content
2. Items are moved manually from "Not Started" or "In Progress"
3. Each entry SHOULD include "Demoted from" and "Reason" metadata
4. Items can be promoted back to "Not Started" when ready
```

**Implementation Requirements**:

1. Add `extract_saved_section()` function (parallel to `extract_backlog_section()`)
2. Preserve section content verbatim during TODO.md regeneration
3. No auto-population logic (manual-only section)
4. Include in section order validation

---

## Implementation Complexity Analysis

### Code Impact Assessment

**Files Requiring Changes**:

1. **Command File** (`.claude/commands/todo.md`):
   - Update section count documentation (Line 36: "six sections" → "seven sections")
   - Add Research and Saved section descriptions (Lines 36-75)
   - Update status classification table
   - Revise block structure to generate new sections
   - Document auto-detection for Research entries
   - Document preservation for Saved section

2. **Library File** (`.claude/lib/todo/todo-functions.sh`):
   - Add `extract_saved_section()` function (Lines 391-407 pattern)
   - Update `validate_todo_structure()` required_sections array (Line 882)
   - Update `update_todo_file()` to include Research and Saved sections (Lines 692-857)
   - Add Research auto-detection logic in plan processing loop
   - Update canonical_sections array for new order (Line 890)

3. **Agent File** (`.claude/agents/todo-analyzer.md`):
   - Update status values table to include "research" classification (Lines 130-139)
   - Add Research detection rules to classification algorithm (Lines 99-128)
   - Document Research vs Not Started distinction

4. **Standards File** (`.claude/docs/reference/standards/todo-organization-standards.md`):
   - **NO CHANGES REQUIRED** - Standards are already correct and comprehensive

5. **Command Guide** (`.claude/docs/guides/commands/todo-command-guide.md`):
   - Update Architecture section (Lines 54-71) to reflect 7-section hierarchy
   - Add Research section documentation
   - Add Saved section documentation
   - Update examples to show new sections

6. **Integration Specification** (`.claude/specs/990_commands_todo_tracking_integration/reports/001-i-want-all-commands-in-claudecommands.md`):
   - Update TODO.md structure reference (Lines 8-26)
   - Document /research command integration point
   - Document Saved section preservation requirement

**Estimated Complexity**: **Medium** (3/5)

**Rationale**:
- Section addition is straightforward (precedent exists with Backlog preservation)
- Research auto-detection requires new logic but follows existing patterns
- No breaking changes to plan file format or classification algorithm
- Backward compatibility maintained (existing TODO.md files can be upgraded)

---

## Backward Compatibility Strategy

### Upgrade Path for Existing TODO.md Files

**Problem**: Existing TODO.md files use 6-section structure. First /todo run after upgrade must migrate gracefully.

**Solution**: Automatic migration on first run after upgrade

**Migration Algorithm**:

```bash
# Detect old format (6 sections)
if ! grep -q "^## Research" "$TODO_PATH" && ! grep -q "^## Saved" "$TODO_PATH"; then
  echo "Detected old 6-section format. Migrating to 7-section structure..."

  # 1. Extract existing sections
  EXISTING_IN_PROGRESS=$(extract_section "In Progress")
  EXISTING_NOT_STARTED=$(extract_section "Not Started")
  EXISTING_BACKLOG=$(extract_section "Backlog")
  EXISTING_SUPERSEDED=$(extract_section "Superseded")
  EXISTING_ABANDONED=$(extract_section "Abandoned")
  EXISTING_COMPLETED=$(extract_section "Completed")

  # 2. Create backup
  cp "$TODO_PATH" "${TODO_PATH}.pre-migration-backup"

  # 3. Regenerate with new structure
  # - In Progress: preserve
  # - Not Started: preserve
  # - Research: auto-detect (new section, starts empty or populated from scan)
  # - Saved: start empty (manual section)
  # - Backlog: preserve
  # - Abandoned: merge Superseded entries using [~] checkbox
  # - Completed: preserve

  echo "Migration complete. Backup saved to: ${TODO_PATH}.pre-migration-backup"
fi
```

**Merge Strategy for Superseded → Abandoned**:

```bash
# During migration, convert Superseded entries to Abandoned with [~] checkbox
while IFS= read -r entry; do
  # Change checkbox from [~] to [x] is NOT needed (keep [~])
  # Standards allow [~] checkbox in Abandoned section for superseded items
  echo "$entry" >> abandoned_section
done < superseded_section
```

**No User Intervention Required**: Migration is transparent and automatic.

---

## Integration with Other Commands

### /research Command Integration

**Current State**: `/research` command creates reports but does NOT update TODO.md

**Standards Requirement** (Integration Spec, Lines 83-111):

```markdown
#### /research - Create Research-Only Reports

**TODO.md Integration Points**:
| Event | When | Action | Details |
|-------|------|--------|---------|
| **Research Complete** | Block 2 (after report verification) | Add to **Research** section | - Extract title from report or topic directory<br>- Link to topic directory (not plan)<br>- Include report artifacts |
```

**Implementation Plan** (Out of Scope for This Revision):

The /research command integration is documented in the Integration Specification but is NOT part of this /todo command revision. The /todo command will support the Research section by:

1. **Auto-detecting** existing research-only directories during scan
2. **Populating** Research section with discovered entries
3. **Providing infrastructure** for /research command to add entries

Actual /research command modification to call TODO.md update functions will be handled in a separate implementation plan.

### /plan and /build Command Integration

**Standards Requirement** (Integration Spec, Lines 50-79, 119-176):

> `/plan` should add newly created plans to "Not Started" section
> `/build` should move plans from "Not Started" to "In Progress" on start, then to "Completed" on finish

**Current State**: These commands do NOT currently update TODO.md automatically

**Implementation Plan** (Out of Scope for This Revision):

The command-level TODO.md tracking integration is a **separate feature** documented in the Integration Specification. This /todo command revision focuses on:

1. **Supporting** the required section structure
2. **Providing** library functions for other commands to use
3. **Ensuring** standards compliance for manual and automated updates

Actual integration of TODO.md updates into /plan, /build, /revise, etc. will be implemented in subsequent phases per the Integration Specification timeline (Phases 1-3, Weeks 1-3).

---

## Proposed Implementation Plan

### Phase 1: Library and Validation Updates

**Objective**: Add Research and Saved section support to todo-functions.sh

**Changes**:

1. Add `extract_saved_section()` function:
   ```bash
   # SECTION 6: TODO.md File Operations
   # Add after extract_backlog_section() (Line 407)

   extract_saved_section() {
     local todo_path="$1"
     if [ ! -f "$todo_path" ]; then
       echo ""
       return 0
     fi
     # Extract content between ## Saved and next ## header
     sed -n '/^## Saved$/,/^## /p' "$todo_path" | sed '1d;$d'
   }
   ```

2. Update `validate_todo_structure()` required_sections:
   ```bash
   # Line 882: Add Research and Saved to required_sections
   local required_sections=("## In Progress" "## Not Started" "## Research"
                            "## Saved" "## Backlog" "## Abandoned" "## Completed")
   ```

3. Update `validate_todo_structure()` canonical_sections:
   ```bash
   # Line 890: Update to 7-section order
   local canonical_sections=("## In Progress" "## Not Started" "## Research"
                             "## Saved" "## Backlog" "## Abandoned" "## Completed")
   ```

4. Update `update_todo_file()` to generate new sections:
   ```bash
   # Add research_entries array (Line 716)
   local research_entries=()
   local saved_entries=()  # Not auto-populated

   # Add Research section generation (after Not Started, before Backlog)
   content+="## Research\n\n"
   if [ ${#research_entries[@]} -gt 0 ]; then
     for entry in "${research_entries[@]}"; do
       content+="${entry}\n\n"
     done
   fi

   # Add Saved section generation (after Research, before Backlog)
   content+="## Saved\n\n"
   if [ -n "$existing_saved" ]; then
     content+="${existing_saved}\n"
   fi
   content+="\n"
   ```

5. Add Research auto-detection in plan processing loop:
   ```bash
   # In update_todo_file(), after plan classification (around Line 730)

   # Check if this is a research-only directory
   if [ -z "$plan_path" ] && [ -d "${topic_path}/reports" ]; then
     # Directory has reports but no plans - add to Research section
     local research_entry
     research_entry=$(format_research_entry "$topic_name" "$topic_path")
     research_entries+=("$research_entry")
     continue
   fi
   ```

6. Add `format_research_entry()` helper function:
   ```bash
   # SECTION 5: Path Utilities
   # Add new function

   format_research_entry() {
     local topic_name="$1"
     local topic_path="$2"

     # Extract title from first report file
     local first_report
     first_report=$(find "${topic_path}/reports" -name "*.md" -type f 2>/dev/null | sort | head -1)

     local title="Research: $topic_name"
     local description=""

     if [ -f "$first_report" ]; then
       # Extract title from first heading in report
       title=$(grep -m1 "^# " "$first_report" | sed 's/^# //' || echo "$topic_name")
       # Extract brief description
       description=$(grep -m1 "^## " "$first_report" | sed 's/^## //' | head -c 100 || echo "")
     fi

     local rel_path
     rel_path=$(get_relative_path "$topic_path")

     # Build entry
     local entry="- [ ] **${title}** - ${description} [${rel_path}/]"

     # Add report links
     local reports
     reports=$(find "${topic_path}/reports" -name "*.md" -type f 2>/dev/null | sort)

     if [ -n "$reports" ]; then
       local report_list=""
       while IFS= read -r report_path; do
         [ -z "$report_path" ] && continue
         local report_name
         report_name=$(basename "$report_path" .md)
         local rel_report
         rel_report=$(get_relative_path "$report_path")
         report_list="${report_list}[${report_name}](${rel_report}), "
       done <<< "$reports"
       report_list="${report_list%, }"
       if [ -n "$report_list" ]; then
         entry="${entry}\n  - Reports: ${report_list}"
       fi
     fi

     echo -e "$entry"
   }
   ```

**Testing**:
- Unit test: `extract_saved_section()` preserves content correctly
- Unit test: `validate_todo_structure()` accepts 7-section files
- Integration test: `update_todo_file()` generates all 7 sections in correct order

---

### Phase 2: Command File Updates

**Objective**: Update /todo command documentation and block structure

**Changes**:

1. Update section count documentation (Line 36):
   ```markdown
   TODO.md is organized into seven sections following strict hierarchy...
   ```

2. Add Research and Saved rows to classification table (Lines 38-45):
   ```markdown
   | Section | Purpose | Checkbox | Auto-Updated | Preservation |
   |---------|---------|----------|--------------|--------------|
   | **In Progress** | Active implementation | `[x]` | Yes | Regenerated |
   | **Not Started** | Planned but not begun | `[ ]` | Yes | Regenerated |
   | **Research** | Research-only projects | `[ ]` | Yes | Auto-detected |
   | **Saved** | Demoted items to revisit | `[ ]` | No | **Preserved** |
   | **Backlog** | Manual prioritization | `[ ]` | No | **Preserved** |
   | **Abandoned** | Stopped or superseded | `[x]`/`[~]` | Yes | Regenerated |
   | **Completed** | Successfully finished | `[x]` | Yes | Date-grouped |
   ```

3. Add Research section auto-detection documentation (after Line 75):
   ```markdown
   **Research Section Behavior**:

   The Research section is auto-populated by scanning specs/ for research-only projects:
   - Directory has `reports/` subdirectory with `.md` files
   - Directory has NO `plans/` subdirectory or empty `plans/`
   - Entry links to topic directory (not plan file)

   Research entries are typically created by `/research` and `/errors` commands.
   ```

4. Add Saved section preservation documentation (after Research section):
   ```markdown
   **Saved Section Behavior**:

   The Saved section is manually curated and preserved by /todo:
   - NOT auto-populated by /todo command
   - Items moved manually from "Not Started" or "In Progress"
   - Each entry SHOULD include "Demoted from" and "Reason" metadata
   - Items can be promoted back to "Not Started" when ready

   Example entry:
   ```markdown
   - [ ] **Buffer Hook Reversion** - ... [path]
     - **Demoted from**: Not Started (2025-11-30)
     - **Reason**: Lower priority; revisit after core improvements
   ```
   ```

5. Update Block 3 (Line 484-563) to extract Saved section:
   ```bash
   # === BACKUP EXISTING TODO.MD ===
   if [ -f "$TODO_PATH" ]; then
     cp "$TODO_PATH" "${TODO_PATH}.backup"
     echo "Backed up existing TODO.md"

     # Extract Saved section for preservation (in addition to Backlog)
     EXISTING_SAVED=$(extract_saved_section "$TODO_PATH")
     append_workflow_state "EXISTING_SAVED" "$EXISTING_SAVED"
   fi
   ```

6. Update Block 4 instruction (Lines 565-659) to include Saved section:
   ```markdown
   Based on the classified plans from todo-analyzer, generate the TODO.md content with proper section organization:

   1. Read classified plans from Block 2 output
   2. Group plans by section (In Progress, Not Started, Research, Saved, Backlog, Abandoned, Completed)
   3. Auto-detect research-only directories (reports/ but no plans/)
   4. Preserve existing Saved and Backlog section content
   5. Generate entries with proper checkbox conventions
   6. Include related artifacts (reports, summaries) as indented bullets
   7. Write to TODO.md (or display if --dry-run)
   ```

**Testing**:
- Dry-run test: `/todo --dry-run` shows 7-section structure
- Preservation test: Saved section content preserved across regeneration
- Research test: Research-only directories auto-populated in Research section

---

### Phase 3: Agent and Documentation Updates

**Objective**: Update agent classification and guides

**Changes**:

1. **Agent File** (`.claude/agents/todo-analyzer.md`):
   - No changes required (agent classifies individual plans, not directories)
   - Research section populated by directory scan, not plan classification

2. **Command Guide** (`.claude/docs/guides/commands/todo-command-guide.md`):
   - Update section hierarchy documentation (Lines 54-71)
   - Add Research section auto-detection explanation
   - Add Saved section preservation explanation
   - Update examples to show 7-section output

3. **Integration Specification** (`.claude/specs/990_commands_todo_tracking_integration/reports/001-i-want-all-commands-in-claudecommands.md`):
   - Update TODO.md structure reference table (Lines 8-26)
   - Confirm /research integration point documented
   - Confirm Saved section preservation requirement

**Testing**:
- Documentation review: All references updated consistently
- Example validation: Code examples match implementation

---

### Phase 4: Migration and Backward Compatibility

**Objective**: Ensure seamless upgrade from 6-section to 7-section format

**Changes**:

1. Add migration detection to Block 1 (after Line 212):
   ```bash
   # === DETECT OLD FORMAT AND MIGRATE ===
   if [ -f "$TODO_PATH" ]; then
     # Check if Research and Saved sections exist
     if ! grep -q "^## Research" "$TODO_PATH" && ! grep -q "^## Saved" "$TODO_PATH"; then
       echo "Detected 6-section format (pre-v2.0). Migrating to 7-section structure..."

       # Create backup
       cp "$TODO_PATH" "${TODO_PATH}.pre-migration-backup"
       echo "  Backup created: ${TODO_PATH}.pre-migration-backup"

       # Set migration flag
       TODO_MIGRATION_NEEDED="true"
       append_workflow_state "TODO_MIGRATION_NEEDED" "true"
       echo "  Migration will occur during TODO.md generation"
     fi
   fi
   ```

2. Add migration logic to Block 3 (after existing section extraction):
   ```bash
   # === HANDLE MIGRATION ===
   if [ "${TODO_MIGRATION_NEEDED:-false}" = "true" ]; then
     echo ""
     echo "=== Migrating TODO.md Format ==="

     # Extract Superseded section for merging into Abandoned
     EXISTING_SUPERSEDED=$(extract_section "Superseded" "$TODO_PATH")

     # Migration will preserve:
     # - In Progress entries
     # - Not Started entries
     # - Backlog content (already extracted)
     # - Abandoned entries (will merge Superseded entries)
     # - Completed entries

     # Migration will create:
     # - Research section (auto-detected from directory scan)
     # - Saved section (starts empty, manual curation)

     append_workflow_state "EXISTING_SUPERSEDED" "$EXISTING_SUPERSEDED"
     echo "  Extracted Superseded section for merging into Abandoned"
   fi
   ```

3. Update Block 4 to merge Superseded entries during migration:
   ```bash
   # In TODO.md generation logic

   # Abandoned section (merge Superseded if migrating)
   content+="## Abandoned\n\n"
   if [ ${#abandoned_entries[@]} -gt 0 ]; then
     for entry in "${abandoned_entries[@]}"; do
       content+="${entry}\n\n"
     done
   fi

   # Merge Superseded entries during migration
   if [ "${TODO_MIGRATION_NEEDED:-false}" = "true" ] && [ -n "$EXISTING_SUPERSEDED" ]; then
     echo "  Merging Superseded entries into Abandoned section"
     # Superseded entries already use [~] checkbox, no modification needed
     content+="${EXISTING_SUPERSEDED}\n"
   fi
   ```

**Testing**:
- Migration test: Run /todo on 6-section TODO.md, verify 7-section output
- Preservation test: All entries preserved during migration
- Backup test: Backup file created with correct content
- Idempotency test: Running /todo twice produces identical output

---

### Phase 5: Validation and Integration Testing

**Objective**: Comprehensive validation of revised /todo command

**Test Cases**:

1. **Empty Repository Test**:
   - No TODO.md file exists
   - /todo creates 7-section structure
   - All sections present in correct order

2. **Research-Only Project Test**:
   - Create specs/999_test_research/reports/001.md
   - No plans/ directory
   - /todo adds entry to Research section
   - Entry links to directory, not plan

3. **Saved Section Preservation Test**:
   - Manually add entry to Saved section
   - Run /todo
   - Saved content preserved exactly

4. **Backlog Preservation Test** (existing functionality):
   - Manually edit Backlog section
   - Run /todo
   - Backlog content preserved exactly

5. **Migration Test**:
   - Start with 6-section TODO.md (old format)
   - Run /todo
   - Output has 7 sections
   - All entries preserved
   - Backup file created
   - Superseded entries merged into Abandoned

6. **Section Order Validation Test**:
   - Run /todo
   - Validate sections appear in canonical order:
     1. In Progress
     2. Not Started
     3. Research
     4. Saved
     5. Backlog
     6. Abandoned
     7. Completed

7. **Clean Mode Test**:
   - Run /todo --clean
   - Verify cleanup uses correct section parsing
   - Verify Research and Saved sections excluded from cleanup

**Integration Tests**:

1. Test with actual project (this repository)
2. Verify Research section populated from existing research-only directories
3. Verify no data loss during migration
4. Verify TODO.md remains human-readable

---

## Risk Assessment

### High-Risk Areas

1. **Data Loss During Migration**
   - **Risk**: Superseded entries lost when merging into Abandoned
   - **Mitigation**: Automatic backup creation + checkbox preservation ([~] retained)

2. **Section Order Confusion**
   - **Risk**: Users expect old order (Backlog at position 3)
   - **Mitigation**: Clear migration messaging + backup file reference

3. **Preservation Logic Failure**
   - **Risk**: Saved or Backlog content lost during regeneration
   - **Mitigation**: Extensive testing + validation in Phase 5

### Medium-Risk Areas

1. **Research Auto-Detection False Positives**
   - **Risk**: Directories misclassified as research-only
   - **Mitigation**: Strict detection criteria (no plans/ OR empty plans/)

2. **Performance Impact**
   - **Risk**: Directory scanning adds latency
   - **Mitigation**: Research scan only occurs if reports/ exists

### Low-Risk Areas

1. **Backward Compatibility**
   - **Risk**: Old TODO.md files break command
   - **Mitigation**: Automatic migration with backup

---

## Recommendation

**Proceed with phased implementation** as outlined above.

### Implementation Priority

1. **Phase 1** (Library Updates): Foundation for all other changes
2. **Phase 4** (Migration): Must be implemented before Phase 2 (command updates) to avoid breaking existing TODO.md files
3. **Phase 2** (Command Updates): User-facing changes
4. **Phase 3** (Documentation): Inform users of new sections
5. **Phase 5** (Validation): Final verification

### Success Criteria

- [ ] /todo command generates 7-section TODO.md structure
- [ ] Research section auto-populated from research-only directories
- [ ] Saved section preserved across regeneration
- [ ] Backlog section preserved across regeneration (existing functionality maintained)
- [ ] 6-section TODO.md files automatically migrated with backup
- [ ] All validation tests pass
- [ ] Documentation updated consistently
- [ ] No data loss reported during migration

### Out of Scope

The following items are explicitly **OUT OF SCOPE** for this revision:

1. **Command-Level TODO.md Integration**: Modifying /plan, /build, /revise, /research, /debug, /repair, /errors commands to automatically update TODO.md (documented in Integration Specification, implemented in subsequent phases)

2. **Advanced Research Detection**: Parsing report content for better title/description extraction (current implementation uses first heading and description from first report file)

3. **Saved Section Automation**: Auto-detecting when to move items to Saved (remains manual-only per standards)

4. **Section Customization**: Allowing users to customize section order or names (standards mandate fixed structure)

---

## Conclusion

The /todo command's 6-section structure represents a significant deviation from the documented 7-section TODO Organization Standards. This analysis has identified three critical discrepancies:

1. **Missing Research Section**: No infrastructure for tracking research-only projects
2. **Missing Saved Section**: No mechanism for intentional item demotion
3. **Section Order Mismatch**: Backlog positioned incorrectly, Superseded not merged into Abandoned

The proposed phased implementation plan provides a clear roadmap to achieve standards compliance while maintaining backward compatibility and preserving all manual curation mechanisms. The migration strategy ensures existing TODO.md files are upgraded seamlessly with automatic backups for safety.

**Estimated Implementation Effort**: 2-3 days for all 5 phases, including comprehensive testing.

**Recommended Timeline**:
- Day 1: Phases 1 and 4 (library updates and migration logic)
- Day 2: Phases 2 and 3 (command and documentation updates)
- Day 3: Phase 5 (validation and integration testing)

This revision will bring the /todo command into full compliance with documented standards and enable future command-level TODO.md integration as described in the Integration Specification.

---

## Navigation

- Parent: [993_todo_command_revise_standards](../)
- Related: [TODO Organization Standards](../../docs/reference/standards/todo-organization-standards.md)
- Related: [/todo Command Guide](../../docs/guides/commands/todo-command-guide.md)
- Related: [Command-Level TODO.md Integration Specification](../../specs/990_commands_todo_tracking_integration/reports/001-i-want-all-commands-in-claudecommands.md)
