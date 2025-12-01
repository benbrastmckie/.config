# /todo Command Standards Compliance Revision Plan

## Metadata
- **Date**: 2025-11-30
- **Feature**: Revise /todo command to comply with 7-section TODO Organization Standards
- **Scope**: Add missing Research and Saved sections, update section ordering, implement migration logic
- **Estimated Phases**: 6
- **Estimated Hours**: 14
- **Complexity Score**: 68.0
- **Structure Level**: 0 (single file)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Research Reports**:
  - [Command-Level TODO.md Tracking Integration Specification](/home/benjamin/.config/.claude/specs/990_commands_todo_tracking_integration/reports/001-i-want-all-commands-in-claudecommands.md)
  - [TODO Command Standards Compliance Analysis](/home/benjamin/.config/.claude/specs/993_todo_command_revise_standards/reports/001-todo-command-standards-compliance-analysis.md)

## Overview

This plan addresses the critical discrepancy between the /todo command's current 6-section implementation and the documented 7-section TODO Organization Standards. The revision adds missing Research and Saved sections, reorders existing sections for standards compliance, and implements automatic migration for existing TODO.md files.

**Problem Statement**: The /todo command currently generates a 6-section TODO.md structure (In Progress, Not Started, Backlog, Superseded, Abandoned, Completed), while the standards mandate a 7-section structure that includes Research (for research-only projects) and Saved (for intentionally demoted items). This creates standards non-compliance, manual workflow disruption, and research project invisibility.

**Solution Approach**: Implement a phased revision that adds the missing sections while maintaining backward compatibility through automatic migration. The implementation preserves all manual curation mechanisms (Backlog and Saved sections) and ensures seamless upgrade for existing TODO.md files.

## Research Summary

Key findings from research reports:

1. **Standards Compliance Analysis** (Report 001):
   - Current implementation uses 6-section structure, missing Research and Saved sections
   - Section order mismatch: Backlog positioned at 3 instead of 5
   - Superseded section should merge into Abandoned with `[~]` checkbox convention
   - Standards require 7-section hierarchy: In Progress → Not Started → Research → Saved → Backlog → Abandoned → Completed

2. **Integration Specification** (Report 990):
   - Research section auto-populated by directory scan (reports/ but no plans/)
   - Saved section manually curated and preserved (like Backlog)
   - /research and /errors commands create research-only directories
   - Future command integration depends on proper section infrastructure

3. **Implementation Complexity** (Report 001):
   - Medium complexity (3/5) - section addition is straightforward
   - Research auto-detection follows existing patterns (similar to plan scanning)
   - Backward compatibility via automatic migration with backups
   - No breaking changes to plan file format or classification algorithm

## Success Criteria

- [ ] /todo command generates 7-section TODO.md structure in correct order
- [ ] Research section auto-populated from research-only directories (reports/ but no plans/)
- [ ] Saved section preserved across regeneration (manual curation maintained)
- [ ] Backlog section preserved across regeneration (existing functionality maintained)
- [ ] 6-section TODO.md files automatically migrated with backup on first run
- [ ] All validation tests pass (structure, preservation, migration)
- [ ] Documentation updated consistently across all files
- [ ] No data loss reported during migration (Superseded entries preserved with `[~]` checkbox)
- [ ] Command guide, standards docs, and integration specs reflect 7-section structure

## Technical Design

### Architecture Changes

**Current 6-Section Structure**:
```
1. In Progress
2. Not Started
3. Backlog
4. Superseded
5. Abandoned
6. Completed
```

**New 7-Section Standards-Compliant Structure**:
```
1. In Progress       (auto-updated)
2. Not Started       (auto-updated)
3. Research          (auto-detected from directory scan)
4. Saved             (manually curated, preserved)
5. Backlog           (manually curated, preserved)
6. Abandoned         (auto-updated, merges Superseded with [~] checkbox)
7. Completed         (auto-updated, date-grouped)
```

### Key Components

1. **Library Functions** (`todo-functions.sh`):
   - Add `extract_saved_section()` (parallel to `extract_backlog_section()`)
   - Add `format_research_entry()` for research-only directory formatting
   - Update `validate_todo_structure()` to require 7 sections
   - Update `update_todo_file()` to generate Research and Saved sections
   - Add research auto-detection in plan processing loop

2. **Command File** (`todo.md`):
   - Update section count documentation (6 → 7 sections)
   - Add Research and Saved rows to classification table
   - Update blocks to extract and preserve Saved section
   - Add migration detection and execution logic
   - Document Research auto-detection and Saved preservation

3. **Migration Logic**:
   - Detect old 6-section format on first run
   - Create automatic backup (`.pre-migration-backup`)
   - Merge Superseded entries into Abandoned (preserve `[~]` checkbox)
   - Insert empty Research and Saved sections in correct positions
   - Preserve all existing entries (no data loss)

### Research Auto-Detection Algorithm

```bash
# In plan processing loop
if [ -z "$plan_path" ] && [ -d "${topic_path}/reports" ]; then
  # Directory has reports but no plans - add to Research section
  research_entry=$(format_research_entry "$topic_name" "$topic_path")
  research_entries+=("$research_entry")
  continue
fi
```

**Detection Criteria**:
1. Directory exists in `specs/` with `reports/` subdirectory
2. Directory has NO `plans/` subdirectory OR `plans/` is empty
3. Entry links to topic directory (not plan file)

### Preservation Strategy

**Saved Section Preservation** (new):
```bash
# Block 3: Extract and preserve Saved section
EXISTING_SAVED=$(extract_saved_section "$TODO_PATH")
append_workflow_state "EXISTING_SAVED" "$EXISTING_SAVED"

# Block 4: Restore Saved section during regeneration
content+="## Saved\n\n"
if [ -n "$existing_saved" ]; then
  content+="${existing_saved}\n"
fi
```

**Backlog Section Preservation** (existing):
- Already implemented via `extract_backlog_section()`
- No changes required to existing preservation logic

## Implementation Phases

### Phase 1: Library Functions Update [COMPLETE]
dependencies: []

**Objective**: Add Research and Saved section support to todo-functions.sh

**Complexity**: Low

Tasks:
- [x] Add `extract_saved_section()` function (file: `.claude/lib/todo/todo-functions.sh`, after Line 407)
- [x] Add `format_research_entry()` helper function (file: `.claude/lib/todo/todo-functions.sh`, SECTION 5)
- [x] Update `validate_todo_structure()` required_sections array to include Research and Saved (Line 882)
- [x] Update `validate_todo_structure()` canonical_sections array for 7-section order (Line 890)
- [x] Update `update_todo_file()` to initialize research_entries and saved_entries arrays (Line 716)
- [x] Add Research section generation logic in `update_todo_file()` (after Not Started section)
- [x] Add Saved section generation logic in `update_todo_file()` (after Research section)
- [x] Add Research auto-detection in plan processing loop (around Line 730)
- [x] Add logic to merge Superseded entries into Abandoned during migration

Testing:
```bash
# Unit tests for new functions
bash .claude/tests/lib/test_todo_functions.sh test_extract_saved_section
bash .claude/tests/lib/test_todo_functions.sh test_format_research_entry
bash .claude/tests/lib/test_todo_functions.sh test_validate_todo_structure_7_sections
bash .claude/tests/lib/test_todo_functions.sh test_research_auto_detection
```

**Expected Duration**: 3 hours

---

### Phase 2: Migration Logic Implementation [COMPLETE]
dependencies: [1]

**Objective**: Implement automatic migration from 6-section to 7-section format

**Complexity**: Medium

Tasks:
- [x] Add migration detection to Block 1 in `/todo` command (file: `.claude/commands/todo.md`, after Line 212)
- [x] Set `TODO_MIGRATION_NEEDED` flag when old format detected
- [x] Add migration logic to Block 3 to extract Superseded section (file: `.claude/commands/todo.md`)
- [x] Update Block 4 to merge Superseded entries into Abandoned section with `[~]` checkbox preservation
- [x] Create automatic backup file (`.pre-migration-backup`) before migration
- [x] Add migration success messaging and backup file location output
- [x] Update state persistence to track migration status

Testing:
```bash
# Create test TODO.md with 6-section format
cp .claude/TODO.md .claude/TODO.md.6section.backup
# Simulate old format (remove Research and Saved sections if present)
# Run /todo and verify:
# 1. Backup created
# 2. 7-section output generated
# 3. All entries preserved
# 4. Superseded entries merged into Abandoned
```

**Expected Duration**: 3 hours

---

### Phase 3: Command File Documentation Updates [COMPLETE]
dependencies: [1]

**Objective**: Update /todo command documentation and block structure

**Complexity**: Low

Tasks:
- [x] Update section count documentation from "six sections" to "seven sections" (file: `.claude/commands/todo.md`, Line 36)
- [x] Add Research and Saved rows to classification table (Lines 38-75)
- [x] Add Research section auto-detection documentation (after Line 75)
- [x] Add Saved section preservation documentation (after Research section docs)
- [x] Update Block 3 to extract Saved section for preservation (Line 484-563)
- [x] Update Block 4 instruction to include Saved section preservation (Lines 565-659)
- [x] Update section grouping documentation in Block 4 to include Research and Saved
- [x] Update completion messaging to reflect 7-section structure

Testing:
```bash
# Verify documentation consistency
grep -A 10 "## Sections and Classification" .claude/commands/todo.md
# Should show 7 sections in table
```

**Expected Duration**: 2 hours

---

### Phase 4: Documentation and Guide Updates [COMPLETE]
dependencies: [2, 3]

**Objective**: Update all documentation to reflect 7-section structure

**Complexity**: Low

Tasks:
- [x] Update Command Guide section hierarchy (file: `.claude/docs/guides/commands/todo-command-guide.md`, Lines 54-71)
- [x] Add Research section auto-detection explanation to Command Guide
- [x] Add Saved section preservation explanation to Command Guide
- [x] Update examples in Command Guide to show 7-section output
- [x] Update Integration Specification TODO.md structure reference (file: `.claude/specs/990_commands_todo_tracking_integration/reports/001-i-want-all-commands-in-claudecommands.md`, Lines 8-26)
- [x] Confirm /research integration point documented in Integration Spec
- [x] Confirm Saved section preservation requirement in Integration Spec
- [x] Verify TODO Organization Standards document requires no changes (already correct)

Testing:
```bash
# Validate cross-references
grep -r "## Research" .claude/docs/ .claude/commands/
grep -r "## Saved" .claude/docs/ .claude/commands/
# All references should be consistent
```

**Expected Duration**: 2 hours

---

### Phase 5: Validation and Integration Testing [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Comprehensive validation of revised /todo command

**Complexity**: Medium

Tasks:
- [x] Create integration test suite for /todo command
- [x] Test 1: Empty repository (no TODO.md) - verify 7-section creation
- [x] Test 2: Research-only project - verify auto-population in Research section
- [x] Test 3: Saved section preservation - verify content preserved across regeneration
- [x] Test 4: Backlog preservation - verify existing functionality maintained
- [x] Test 5: Migration - verify 6-section to 7-section upgrade with backup
- [x] Test 6: Section order validation - verify canonical order maintained
- [x] Test 7: Clean mode - verify cleanup uses correct section parsing
- [x] Test 8: Idempotency - verify running /todo twice produces identical output
- [x] Verify Research section excludes directories with empty plans/ folder
- [x] Verify Saved section remains empty if no manual entries added

Testing:
```bash
# Run comprehensive test suite
bash .claude/tests/commands/test_todo_integration.sh

# Test migration specifically
bash .claude/tests/commands/test_todo_migration.sh

# Verify no data loss
bash .claude/tests/commands/test_todo_preservation.sh
```

**Expected Duration**: 3 hours

---

### Phase 6: Real-World Validation and Deployment [COMPLETE]
dependencies: [5]

**Objective**: Validate with actual project data and deploy

**Complexity**: Low

Tasks:
- [x] Backup current TODO.md (file: `.claude/TODO.md`)
- [x] Run /todo command on actual repository
- [x] Verify Research section populated from existing research-only directories
- [x] Verify no data loss during migration (check backup file)
- [x] Verify TODO.md remains human-readable and properly formatted
- [x] Review migration backup file content
- [x] Verify Backlog section content preserved exactly
- [x] Verify Saved section created (empty if no manual entries)
- [x] Review Research section entries for accuracy (title, description, report links)
- [x] Commit revised /todo command implementation
- [x] Update CLAUDE.md if needed to reference 7-section structure

Testing:
```bash
# Backup current state
cp .claude/TODO.md .claude/TODO.md.pre-revision-backup

# Run revised /todo command
/todo

# Validate output structure
grep "^## " .claude/TODO.md | wc -l  # Should output 7

# Check section order
grep "^## " .claude/TODO.md
# Should show: In Progress, Not Started, Research, Saved, Backlog, Abandoned, Completed

# Verify migration backup exists
ls -la .claude/TODO.md.pre-migration-backup
```

**Expected Duration**: 1 hour

---

## Testing Strategy

### Unit Tests (Phase 1)

**Library Function Tests** (`.claude/tests/lib/test_todo_functions.sh`):
- `test_extract_saved_section()` - Verify Saved section extraction preserves content
- `test_format_research_entry()` - Verify research entry formatting with directory links
- `test_validate_todo_structure()` - Verify 7-section validation accepts new structure
- `test_research_auto_detection()` - Verify directories with reports/ but no plans/ detected

### Integration Tests (Phase 5)

**Migration Tests** (`.claude/tests/commands/test_todo_migration.sh`):
1. **6-to-7 Section Migration**:
   - Create TODO.md with 6 sections
   - Run /todo
   - Verify 7 sections in output
   - Verify backup created
   - Verify all entries preserved
   - Verify Superseded entries merged into Abandoned

2. **Preservation Tests**:
   - Add manual entry to Saved section
   - Add manual content to Backlog section
   - Run /todo
   - Verify Saved content preserved exactly
   - Verify Backlog content preserved exactly

3. **Research Auto-Detection**:
   - Create specs/999_test_research/reports/001.md
   - Ensure no plans/ directory
   - Run /todo
   - Verify entry appears in Research section
   - Verify entry links to directory (not plan file)

### Regression Tests (Phase 5)

**Structure Validation** (`.claude/tests/commands/test_todo_structure.sh`):
- After multiple /todo runs, verify:
  - All 7 sections present
  - Sections in canonical order
  - No duplicate entries
  - Backlog and Saved sections preserved
  - Research section auto-populated correctly

### Real-World Validation (Phase 6)

**Production Testing**:
- Run on actual repository with existing TODO.md
- Verify no data loss (compare backup to output)
- Verify Research section populated from existing research-only directories
- Verify human readability maintained
- Verify Backlog content preserved exactly

## Documentation Requirements

### Files Requiring Updates

1. **Command Implementation** (`.claude/commands/todo.md`):
   - Section count (6 → 7)
   - Classification table (add Research and Saved)
   - Block 3 (extract Saved section)
   - Block 4 (generate Saved and Research sections)
   - Migration detection and execution

2. **Library Implementation** (`.claude/lib/todo/todo-functions.sh`):
   - `extract_saved_section()` function
   - `format_research_entry()` function
   - `validate_todo_structure()` updates
   - `update_todo_file()` section generation

3. **Command Guide** (`.claude/docs/guides/commands/todo-command-guide.md`):
   - Architecture section (7-section hierarchy)
   - Research section documentation
   - Saved section documentation
   - Updated examples

4. **Integration Specification** (`.claude/specs/990_commands_todo_tracking_integration/reports/001-i-want-all-commands-in-claudecommands.md`):
   - TODO.md structure reference table
   - /research integration point
   - Saved section preservation requirement

5. **No Changes Required**:
   - `.claude/docs/reference/standards/todo-organization-standards.md` (already correct)

## Dependencies

### External Dependencies
- None (pure bash implementation)

### Internal Dependencies
- `error-handling.sh` (Tier 1 library) - already sourced
- `state-persistence.sh` (Tier 1 library) - already sourced
- `unified-location-detection.sh` (Tier 1 library) - already sourced
- `todo-functions.sh` (Tier 3 library) - being modified

### Command Dependencies
- This revision enables future integration with:
  - `/research` command (will auto-add to Research section)
  - `/errors` command (will auto-add to Research section)
  - `/plan`, `/build`, `/revise` commands (will auto-update TODO.md)

## Risk Assessment

### High-Risk Areas

1. **Data Loss During Migration** (Mitigation: Automatic backup + `[~]` checkbox preservation)
   - Risk: Superseded entries lost when merging into Abandoned
   - Impact: High (user data loss)
   - Mitigation: Create automatic backup, preserve `[~]` checkbox exactly as-is

2. **Preservation Logic Failure** (Mitigation: Extensive testing in Phase 5)
   - Risk: Saved or Backlog content lost during regeneration
   - Impact: High (manual work lost)
   - Mitigation: Add comprehensive preservation tests, verify in real-world scenario

### Medium-Risk Areas

1. **Research Auto-Detection False Positives** (Mitigation: Strict detection criteria)
   - Risk: Directories misclassified as research-only
   - Impact: Medium (wrong section placement)
   - Mitigation: Require reports/ existence AND empty/missing plans/

2. **Section Order Confusion** (Mitigation: Clear migration messaging)
   - Risk: Users expect old order (Backlog at position 3)
   - Impact: Low (cosmetic, no data loss)
   - Mitigation: Clear messaging, backup file reference

### Low-Risk Areas

1. **Performance Impact** (Mitigation: Research scan only if reports/ exists)
   - Risk: Directory scanning adds latency
   - Impact: Low (minimal performance impact)
   - Mitigation: Conditional scanning based on directory existence

2. **Backward Compatibility** (Mitigation: Automatic migration with backup)
   - Risk: Old TODO.md files break command
   - Impact: Low (automatic handling)
   - Mitigation: Seamless migration on first run

## Rollback Plan

If critical issues arise during deployment:

1. **Immediate Rollback**:
   ```bash
   # Restore from pre-migration backup
   cp .claude/TODO.md.pre-migration-backup .claude/TODO.md

   # Revert command implementation
   git revert <commit-hash>
   ```

2. **Recovery Options**:
   - Backup file location: `.claude/TODO.md.pre-migration-backup`
   - Git history: All entries preserved in commit history
   - Manual restoration: Backup file is valid 6-section format

3. **Validation Before Commit**:
   - Run all tests in Phase 5 before committing changes
   - Review migration backup file manually
   - Verify no data loss using diff comparison

## Out of Scope

The following items are explicitly **OUT OF SCOPE** for this revision:

1. **Command-Level TODO.md Integration**: Modifying /plan, /build, /revise, /research, /debug, /repair, /errors commands to automatically update TODO.md (documented in Integration Specification, implemented in subsequent phases)

2. **Advanced Research Detection**: Parsing report content for better title/description extraction (current implementation uses first heading and description from first report file)

3. **Saved Section Automation**: Auto-detecting when to move items to Saved (remains manual-only per standards)

4. **Section Customization**: Allowing users to customize section order or names (standards mandate fixed structure)

5. **Agent Updates**: No changes to `todo-analyzer.md` agent (classifies plans, not directories; Research section populated by directory scan, not plan classification)

## Completion Checklist

Before marking this plan as complete:
- [ ] All 6 phases executed successfully
- [ ] All success criteria met
- [ ] All tests passing (unit, integration, regression)
- [ ] Documentation updated consistently
- [ ] Real-world validation completed with no data loss
- [ ] Migration backup file created and verified
- [ ] TODO.md generated with 7-section structure
- [ ] Research section auto-populated from existing research-only directories
- [ ] Saved and Backlog sections preserved correctly
- [ ] Command committed to repository

## Notes

**Key Design Decisions**:

1. **Automatic Migration**: Chosen over manual migration to ensure seamless user experience and prevent broken state
2. **Backup Creation**: Mandatory backup before migration provides safety net for recovery
3. **Superseded Merge**: Superseded section merged into Abandoned (per standards) with `[~]` checkbox preservation for distinction
4. **Research Auto-Detection**: Directory-based detection (not plan-based) enables tracking of research-only workflows
5. **Saved Section**: Manual-only section (like Backlog) for intentional item demotion without permanent abandonment

**Future Integration**:

This revision provides the infrastructure for command-level TODO.md integration (Integration Specification Phase 1-3):
- Research section enables /research and /errors commands to auto-add entries
- Saved section enables manual workflow management (demotion without abandonment)
- 7-section structure aligns with all documented standards
- Preservation mechanisms ensure manual curation never lost

**Estimated Total Time**: 14 hours across 6 phases (2-3 days implementation window)
