# TODO Command Sections Review - Implementation Plan

## Metadata
- **Date**: 2025-11-30
- **Feature**: TODO command sections compliance enhancements
- **Scope**: Address minor gaps in TODO.md section handling (date range grouping, section order validation, documentation)
- **Estimated Phases**: 3
- **Estimated Hours**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 28.0
- **Research Reports**:
  - [TODO Command Sections Compliance Analysis](/home/benjamin/.config/.claude/specs/987_todo_command_sections_review/reports/001_todo_command_sections_compliance_analysis.md)

## Overview

The /todo command demonstrates 95%+ compliance with TODO Organization Standards, implementing all 6 required sections (In Progress, Not Started, Backlog, Superseded, Abandoned, Completed) with correct checkbox conventions, status classification, and Backlog preservation. This plan addresses three minor enhancement opportunities identified in the compliance analysis:

1. **Date Range Grouping**: Enhance Completed section to support date range headers (e.g., "November 27-29, 2025") instead of single-day only
2. **Section Order Validation**: Strengthen validation to enforce strict section ordering
3. **Documentation Enhancement**: Improve /todo command documentation to explicitly document all 6 sections and their semantics

## Research Summary

The compliance analysis revealed:

**Strengths (95%+ compliant)**:
- All 6 required sections fully implemented and operational
- Correct checkbox conventions enforced per section
- Backlog manual curation honored (extraction and preservation working)
- Complete status classification algorithm with fallback logic
- Section-based cleanup respects TODO.md as source of truth
- Related artifacts (reports/summaries) discovered and included
- Entry formatting follows standards

**Minor Gaps Identified**:
1. Date range grouping not implemented (cosmetic, low-priority) - currently only supports single-day headers
2. Section order validation could be stricter (currently partial) - validates existence but not strict ordering
3. Command documentation should explicitly document all 6 sections and their semantics

## Success Criteria

- [ ] Completed section supports date range grouping (e.g., "November 27-29, 2025") for consecutive completion dates
- [ ] Section order validation enforces strict ordering: In Progress -> Not Started -> Backlog -> Superseded -> Abandoned -> Completed
- [ ] Command documentation includes comprehensive "Sections and Classification" subsection
- [ ] All existing tests pass
- [ ] TODO.md generation continues working correctly with enhanced features
- [ ] Date range grouping handles edge cases (single day, non-consecutive days, month boundaries)

## Technical Design

### Architecture Overview

The implementation involves three independent enhancements to existing TODO command infrastructure:

**Component 1: Date Range Grouping**
- Location: `.claude/lib/todo/todo-functions.sh`
- Function: `generate_completed_date_header()`
- Current: Generates single-day headers only
- Enhancement: Detect consecutive completion dates and generate range headers

**Component 2: Section Order Validation**
- Location: `.claude/lib/todo/todo-functions.sh`
- Function: `validate_todo_structure()`
- Current: Checks In Progress vs Completed ordering only
- Enhancement: Validate all 6 sections in strict order

**Component 3: Documentation**
- Location: `.claude/commands/todo.md`
- Current: Basic section descriptions
- Enhancement: Add comprehensive "Sections and Classification" subsection

### Design Decisions

1. **Date Range Grouping Algorithm**:
   - Track completion dates from entries
   - Sort dates chronologically
   - Identify consecutive date ranges
   - Generate range headers (e.g., "Nov 27-29, 2025") or single-day headers
   - Edge cases: Month boundaries, year boundaries, single days

2. **Section Order Validation**:
   - Define canonical section order array
   - Extract section line numbers from TODO.md
   - Verify sections appear in canonical order
   - Report violations with section names and line numbers

3. **Documentation Enhancement**:
   - Add new subsection after "Default Mode" section
   - Document all 6 sections with purposes
   - Include checkbox convention table
   - Document status classification algorithm
   - Document Backlog preservation policy

## Implementation Phases

### Phase 1: Date Range Grouping Enhancement [COMPLETE]
dependencies: []

**Objective**: Enhance Completed section to support date range headers for consecutive completion dates

**Complexity**: Medium

Tasks:
- [x] Analyze current `generate_completed_date_header()` implementation (`todo-functions.sh:486-494`)
- [x] Design date range detection algorithm (identify consecutive dates from entries)
- [x] Implement `detect_date_ranges()` helper function
  - Input: Array of completion dates (YYYY-MM-DD format)
  - Output: Array of date range objects with start/end dates
  - Logic: Sort dates, identify consecutive sequences, handle month/year boundaries
- [x] Update `generate_completed_date_header()` to accept date range parameters
  - Single date: "November 30, 2025"
  - Date range: "November 27-29, 2025"
  - Cross-month: "October 31 - November 1, 2025"
- [x] Refactor Completed section generation to use date range grouping
  - Parse completion dates from entries
  - Group entries by date range
  - Generate appropriate headers per group
- [x] Add edge case handling
  - Single-day ranges (use single date format)
  - Month boundary ranges (show both months)
  - Year boundary ranges (show both years)
  - Non-consecutive dates (separate groups)

Testing:
```bash
# Create test TODO.md with entries on consecutive dates
# Run /todo command
# Verify Completed section uses date range headers
# Test edge cases: month boundary, year boundary, single day, gaps

# Integration test
cd /home/benjamin/.config
bash .claude/tests/lib/test_todo_functions.sh
```

**Expected Duration**: 2 hours

### Phase 2: Section Order Validation Enhancement [COMPLETE]
dependencies: [1]

**Objective**: Strengthen section order validation to enforce strict 6-section ordering

**Complexity**: Low

Tasks:
- [x] Review current validation logic (`todo-functions.sh:686-699`)
- [x] Define canonical section order array
  ```bash
  CANONICAL_SECTION_ORDER=("In Progress" "Not Started" "Backlog" "Superseded" "Abandoned" "Completed")
  ```
- [x] Implement `validate_section_order()` function
  - Extract section headers from TODO.md with line numbers
  - Map sections to canonical order indices
  - Verify sections appear in ascending index order
  - Return validation errors with section names and line numbers
- [x] Integrate into `validate_todo_structure()` function
- [x] Add informative error messages
  - "Section 'Completed' (line 50) appears before 'Backlog' (line 100)"
  - "Expected section order: In Progress -> Not Started -> Backlog -> Superseded -> Abandoned -> Completed"
- [x] Update validation to warn (not error) on ordering violations (since TODO.md might have manual edits)

Testing:
```bash
# Create test TODO.md with out-of-order sections
# Run validation
# Verify warnings emitted with correct section names and line numbers

# Integration test
cd /home/benjamin/.config
bash .claude/tests/lib/test_todo_functions.sh
```

**Expected Duration**: 1 hour

### Phase 3: Documentation Enhancement [COMPLETE]
dependencies: [1, 2]

**Objective**: Enhance /todo command documentation with comprehensive section and classification details

**Complexity**: Low

Tasks:
- [x] Read current command documentation (`.claude/commands/todo.md:28-35`)
- [x] Add new "Sections and Classification" subsection after "Default Mode" section
- [x] Document all 6 sections
  - Section name, purpose, auto-updated status, checkbox convention
  - Format as table for clarity
- [x] Document status classification algorithm
  - Status field mapping (COMPLETE -> Completed, etc.)
  - Fallback logic (phase marker analysis)
  - Examples
- [x] Document Backlog preservation policy
  - Manual curation honored
  - Content extracted and preserved during updates
  - Structure within Backlog is user-defined
- [x] Add examples for each section type
- [x] Add cross-reference to TODO Organization Standards document
  - Link: `.claude/docs/reference/standards/todo-organization-standards.md`

Testing:
```bash
# Manual review of documentation
# Verify all 6 sections documented
# Verify examples are correct
# Verify cross-references valid
# Check formatting and clarity

# Link validation
cd /home/benjamin/.config
bash .claude/scripts/validate-links-quick.sh .claude/commands/todo.md
```

**Expected Duration**: 1 hour

## Testing Strategy

### Unit Tests

**Test File**: `.claude/tests/lib/test_todo_functions.sh`

New test cases to add:
1. `test_date_range_grouping_consecutive_days()` - Verify "Nov 27-29, 2025" format
2. `test_date_range_grouping_single_day()` - Verify "November 30, 2025" format
3. `test_date_range_grouping_month_boundary()` - Verify "October 31 - November 1, 2025"
4. `test_date_range_grouping_year_boundary()` - Verify year boundary handling
5. `test_date_range_grouping_non_consecutive()` - Verify separate groups for gaps
6. `test_section_order_validation_correct()` - Verify no warnings for correct order
7. `test_section_order_validation_violations()` - Verify warnings for out-of-order sections
8. `test_section_order_validation_missing()` - Verify handling of missing sections

### Integration Tests

**Test Scenario**: Run /todo command with real specs directory
- Verify TODO.md generated correctly
- Verify date range grouping in Completed section
- Verify section order validation warnings (if applicable)
- Verify all 6 sections present and populated

### Documentation Tests

**Test**: Link validation
```bash
bash .claude/scripts/validate-links-quick.sh .claude/commands/todo.md
```

**Test**: README structure validation
```bash
bash .claude/scripts/validate-readmes.sh .claude/commands/
```

### Regression Tests

**Existing Tests**: All existing TODO function tests must pass
- `test_todo_functions.sh` - All existing test cases
- `test_todo_functions_cleanup.sh` - Cleanup mode tests

## Documentation Requirements

### Files to Update

1. `.claude/commands/todo.md` - Add "Sections and Classification" subsection (Phase 3)
2. `.claude/lib/todo/README.md` - Document new date range grouping function
3. `.claude/docs/reference/standards/todo-organization-standards.md` - Update with implementation notes for date range grouping

### Content Updates

**todo.md Enhancement**:
- Add comprehensive section documentation table
- Document status classification algorithm with examples
- Document Backlog preservation policy
- Add cross-reference to TODO Organization Standards

**lib/todo/README.md Enhancement**:
- Document `detect_date_ranges()` function signature and behavior
- Document updated `generate_completed_date_header()` function
- Document `validate_section_order()` function

**Standards Document Update**:
- Add note confirming date range grouping implementation
- Update examples to show date ranges in action

## Dependencies

### External Dependencies
None - all changes are to existing TODO infrastructure

### Internal Dependencies
- `.claude/lib/todo/todo-functions.sh` - Primary implementation file
- `.claude/commands/todo.md` - Command documentation
- `.claude/docs/reference/standards/todo-organization-standards.md` - Standards reference

### Prerequisites
- Existing /todo command infrastructure (fully functional)
- Test suite infrastructure (`.claude/tests/lib/test_todo_functions.sh`)

## Notes

**Priority Rationale**: All three enhancements are low-priority cosmetic improvements. The /todo command is already 95%+ compliant and fully functional. These enhancements improve polish and documentation clarity but do not fix critical bugs.

**Date Range Complexity**: Date range grouping is the most complex enhancement due to edge cases (month boundaries, year boundaries, gaps). The implementation should be conservative and prefer clarity over complexity.

**Section Order Validation**: Should emit warnings (not errors) to allow manual TODO.md editing flexibility. Strict ordering is a standard, not a hard requirement.

**Documentation First**: Phase 3 (documentation) has no code changes and can be completed quickly. Consider prioritizing documentation if time-constrained.

**Expansion Note**: Complexity score of 28.0 is well below the threshold (50) for phase expansion. This plan is appropriately structured as a single-file Level 0 plan.
