# Repair Plan Standards Enforcement - Implementation Plan

## Metadata
- **Date**: 2025-12-02 (Revised)
- **Feature**: Enforce uniform plan metadata standards across all plan-generating commands
- **Scope**: Create canonical plan metadata standard in .claude/docs/reference/standards/, add lightweight CLAUDE.md reference section, update /repair command to use standard context format, create validation infrastructure, and update plan-architect agent for self-validation
- **Estimated Phases**: 5
- **Estimated Hours**: 11-15 hours (revised from 12-16 to reflect Phase 1 expansion and Phase 5 simplification)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Complexity Score**: 78.5
- **Structure Level**: 0
- **Research Reports**:
  - [Repair Plan Standards Analysis](../reports/001-repair-plan-standards-analysis.md)
  - [Plan Revision: Standards Documentation Architecture](../reports/002-revise-plan-standards-documentation.md)

## Overview

The /repair command generates plans with metadata that diverges from /plan command standards in field naming, timestamp formats, and structural organization. Both commands invoke the plan-architect agent but pass different context, causing inconsistent plan outputs. This creates parsing challenges, breaks tooling dependencies, and makes adding new plan-generating commands difficult.

This plan establishes a canonical plan metadata standard following the project's reference architecture pattern: comprehensive standard documentation in .claude/docs/reference/standards/plan-metadata-standard.md with a lightweight reference section in CLAUDE.md. The standard will be automatically injected into all plan-generating commands (/plan, /repair, /revise, /debug) via existing standards-extraction.sh infrastructure. Validation is enforced through pre-commit hooks and linters, ensuring all plans follow uniform structure without manual coordination.

## Research Summary

Key findings from research analysis:

**Metadata Divergence**:
- /plan uses: `Estimated Hours`, human-readable dates, `Complexity Score`, `Structure Level`
- /repair uses: `Estimated Duration`, ISO 8601 timestamps, `Plan ID`, `Type`, `Created`
- Research reports: /plan uses relative markdown links, /repair uses absolute paths without links

**Root Cause**:
- Both commands invoke plan-architect but pass different workflow context ("plan workflow" vs "repair workflow")
- /repair includes repair-specific requirements (error log status update phase) that influence metadata structure
- No canonical documentation defines required vs optional metadata fields

**Infrastructure Opportunity**:
- Existing standards-extraction.sh automatically injects CLAUDE.md sections into agent prompts
- Pre-commit hooks and validation scripts already enforce code standards, READMEs, and links
- Plan-parsing libraries (plan-core-bundle.sh, metadata-extraction.sh) depend on consistent metadata
- CLAUDE.md follows "reference architecture" pattern: 18 of 21 sections link to comprehensive docs with quick reference summaries

**Solution Approach**:
- Create comprehensive plan-metadata-standard.md in .claude/docs/reference/standards/
- Add lightweight `plan_metadata_standard` section to CLAUDE.md (quick reference + link to full doc)
- Update standards-extraction.sh to include new section in planning standards
- Update /repair to normalize context format (REPORT_PATHS_LIST, "repair" context marker)
- Create validate-plan-metadata.sh linter integrated into pre-commit hooks
- Update plan-architect to validate its own metadata before returning

## Success Criteria

- [ ] Comprehensive standard created: .claude/docs/reference/standards/plan-metadata-standard.md
- [ ] Standard defines 6 required fields: Date, Feature, Status, Estimated Hours, Standards File, Research Reports
- [ ] Standard defines 4 optional fields: Scope, Complexity Score, Structure Level, Estimated Phases
- [ ] Standard defines workflow-specific extensions: /repair (Error Log Query, Errors Addressed), /revise (Original Plan, Revision Reason)
- [ ] Standard includes validation rules, integration points, and migration strategy
- [ ] CLAUDE.md contains lightweight `plan_metadata_standard` section with quick reference (6 required fields) and link to full documentation
- [ ] standards-extraction.sh updated to include plan_metadata_standard in extracted planning standards
- [ ] /repair command uses REPORT_PATHS_LIST format matching /plan
- [ ] /repair command passes normalized "repair" context marker
- [ ] validate-plan-metadata.sh script validates all required fields and formats
- [ ] Validation script integrated into validate-all-standards.sh --plans category
- [ ] Pre-commit hook validates plan file metadata on commit
- [ ] plan-architect agent validates metadata during creation (STEP 3)
- [ ] All validation uses ERROR-level for missing required fields, WARNING-level for format issues
- [ ] standards/README.md updated with plan-metadata-standard.md entry
- [ ] No forced migration of existing plans (progressive migration via revision cycle)

## Technical Design

### Architecture

The implementation leverages existing infrastructure patterns:

**Reference Architecture Pattern** (Established in CLAUDE.md):
- 18 of 21 CLAUDE.md sections follow pattern: "See [Full Doc](path) for complete..." + Quick Reference
- Comprehensive standards live in .claude/docs/reference/standards/
- CLAUDE.md provides quick summaries with links to full documentation
- Enables detailed specifications without bloating CLAUDE.md

**Standards Injection Pattern** (Already Implemented):
```bash
# Commands already use this pattern
source "${CLAUDE_LIB}/plan/standards-extraction.sh"
FORMATTED_STANDARDS=$(format_standards_for_prompt)

# Plan-architect receives standards in prompt:
# **Project Standards**:
# ${FORMATTED_STANDARDS}
```

**Validation Infrastructure Pattern** (Already Implemented):
```bash
# Pre-commit hook pattern
bash .claude/scripts/validate-all-standards.sh --staged

# Unified validation script pattern
bash .claude/scripts/validate-all-standards.sh --plans
```

**New Component**: validate-plan-metadata.sh
- Parses ## Metadata section from plan file
- Validates required fields present: Date, Feature, Status, Estimated Hours, Standards File, Research Reports
- Validates field formats: Date (YYYY-MM-DD), Status (bracket notation), Estimated Hours (numeric range)
- Validates Standards File is absolute path
- Validates Research Reports use relative paths with markdown links
- Returns exit 0 (pass), exit 1 (errors block commit), warnings informational

**Integration Points**:
1. **.claude/docs/reference/standards/plan-metadata-standard.md**: Comprehensive standard (new file)
2. **CLAUDE.md**: Lightweight `plan_metadata_standard` section with quick reference + link
3. **standards-extraction.sh**: Updated to include plan_metadata_standard in extracted sections
4. **plan-architect.md**: STEP 3 updated to run validate-plan-metadata.sh before returning
5. **repair.md**: Block 2b-exec context updated to match /plan format
6. **validate-all-standards.sh**: New --plans category added
7. **pre-commit hook**: Plan file validation added
8. **standards/README.md**: Catalog entry for plan-metadata-standard.md

### Metadata Standard Structure

**Required Fields** (ERROR if missing):
1. **Date**: `YYYY-MM-DD` or `YYYY-MM-DD (Revised)` - Creation/revision date
2. **Feature**: One-line description (50-100 chars) - What is being implemented
3. **Status**: `[NOT STARTED]`, `[IN PROGRESS]`, `[COMPLETE]`, `[BLOCKED]` - Current plan status
4. **Estimated Hours**: `{low}-{high} hours` - Time estimate as numeric range
5. **Standards File**: `/absolute/path/to/CLAUDE.md` - Standards traceability
6. **Research Reports**: Markdown links with relative paths or `none` if no research phase

**Optional Fields** (INFO if missing):
7. **Scope**: Multi-line scope description (recommended for complex plans)
8. **Complexity Score**: Numeric complexity from plan-architect calculation
9. **Structure Level**: `0`, `1`, or `2` - Plan structure tier
10. **Estimated Phases**: Phase count estimate before detailed planning

**Workflow-Specific Extensions**:
- `/repair`: Error Log Query, Errors Addressed
- `/revise`: Original Plan, Revision Reason

### Backward Compatibility

**No Forced Migration**:
- Existing plans remain valid (no breaking changes)
- Standard applies to new plans created after implementation
- Plans revised using /revise get updated metadata
- If metadata-extraction.sh breaks on old plans, add backward-compatible parsing

**Progressive Migration**:
- Natural revision cycle updates metadata over time
- No manual migration tasks required
- Tooling handles both old and new formats during transition

## Implementation Phases

### Phase 1: Create Plan Metadata Standard Documentation [COMPLETE]
dependencies: []

**Objective**: Create comprehensive plan metadata standard in .claude/docs/reference/standards/ and add lightweight reference section to CLAUDE.md following the project's established reference architecture pattern

**Complexity**: Medium

**Tasks**:
- [x] Create /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md with comprehensive specification
- [x] Document 6 required fields with format specifications, validation rules, and examples
- [x] Document 4 optional fields with format specifications, use cases, and when to include
- [x] Define workflow-specific optional fields: /repair (Error Log Query, Errors Addressed), /revise (Original Plan, Revision Reason)
- [x] Specify metadata section placement rules (after title, before all other sections)
- [x] Include complete format examples for each workflow type (plan, repair, revise)
- [x] Document validation rules: ERROR for missing required fields, WARNING for format issues, INFO for missing optional recommended fields
- [x] Document integration points: standards-extraction.sh, metadata-extraction.sh, validate-plan-metadata.sh, pre-commit hooks
- [x] Document extension mechanism for new workflow-specific fields
- [x] Document migration strategy (progressive, no forced updates, backward compatibility approach)
- [x] Add lightweight `plan_metadata_standard` section to /home/benjamin/.config/CLAUDE.md using SECTION comment markers
- [x] CLAUDE.md section: Include opening line "See [Plan Metadata Standard](.claude/docs/reference/standards/plan-metadata-standard.md) for complete..."
- [x] CLAUDE.md section: Include "Required Fields Quick Reference" with 6 required fields (brief format only)
- [x] CLAUDE.md section: Include "Enforcement" note about pre-commit hooks and ERROR-level validation
- [x] CLAUDE.md section: Add [Used by: /plan, /repair, /revise, /debug, plan-architect] metadata tag
- [x] Update /home/benjamin/.config/.claude/docs/reference/standards/README.md catalog with plan-metadata-standard.md entry
- [x] Update /home/benjamin/.config/.claude/lib/plan/standards-extraction.sh to include plan_metadata_standard in extracted sections array (line ~150-160)

**Testing**:
```bash
# Verify comprehensive standard file created
[ -f /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md ]

# Verify comprehensive standard has all required sections
grep -q "## Required Metadata Fields" /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md
grep -q "## Optional Metadata Fields" /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md
grep -q "## Workflow-Specific Optional Fields" /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md
grep -q "## Validation Rules" /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md
grep -q "## Integration Points" /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md

# Verify CLAUDE.md section present
grep -q "<!-- SECTION: plan_metadata_standard -->" /home/benjamin/.config/CLAUDE.md

# Verify CLAUDE.md section follows reference pattern (links to full doc)
grep -A5 "<!-- SECTION: plan_metadata_standard -->" /home/benjamin/.config/CLAUDE.md | grep -q "See \[Plan Metadata Standard\]"

# Verify standards-extraction.sh can parse new section
source /home/benjamin/.config/.claude/lib/plan/standards-extraction.sh
STANDARD_CONTENT=$(extract_claude_section "plan_metadata_standard")
[ -n "$STANDARD_CONTENT" ] && echo "Standard extracted successfully"

# Verify standards-extraction.sh includes plan_metadata_standard in planning standards
grep -q "plan_metadata_standard" /home/benjamin/.config/.claude/lib/plan/standards-extraction.sh

# Verify standards catalog updated
grep -q "plan-metadata-standard.md" /home/benjamin/.config/.claude/docs/reference/standards/README.md
```

**Expected Duration**: 3-4 hours

---

### Phase 2: Update /repair Command Context Format [COMPLETE]
dependencies: [1]

**Objective**: Normalize /repair command's plan-architect invocation to use consistent context format matching /plan

**Complexity**: Low

**Files Modified**:
- /home/benjamin/.config/.claude/commands/repair.md

**Tasks**:
- [x] Locate plan-architect Task invocation in repair.md (Block 2b-exec, ~line 1159-1206)
- [x] Change `Research Reports: ${REPORT_PATHS_JSON}` to `Research Reports: ${REPORT_PATHS_LIST}`
- [x] Update bash block that creates REPORT_PATHS_LIST variable (convert JSON array to space-separated list)
- [x] Replace `Workflow Type: research-and-plan` context with `Command Context: repair`
- [x] Add `Error Log Query: ${ERROR_FILTERS}` field to provide repair-specific metadata
- [x] Preserve repair-specific requirements section (error log status update phase) as separate context
- [x] Verify workflow identifier shows "repair workflow" not "plan workflow" (keeps workflow distinction)
- [x] Test /repair invocation with error query and verify plan-architect receives correct context

**Testing**:
```bash
# Test repair command with sample error query
/repair --since 24h --type state_error --complexity 1

# Verify plan created with standard metadata
REPAIR_PLAN=$(find .claude/specs -name "*repair*plan*.md" -type f | head -1)
grep -q "^## Metadata" "$REPAIR_PLAN"
grep -q "^\- \*\*Date\*\*:" "$REPAIR_PLAN"
grep -q "^\- \*\*Feature\*\*:" "$REPAIR_PLAN"
grep -q "^\- \*\*Research Reports\*\*:" "$REPAIR_PLAN"

# Verify research reports use relative paths (not absolute)
grep "Research Reports" "$REPAIR_PLAN" -A5 | grep -q "\.\./reports/"
```

**Expected Duration**: 2-3 hours

---

### Phase 3: Create Plan Metadata Validation Script [COMPLETE]
dependencies: [1]

**Objective**: Create validate-plan-metadata.sh linter that validates plan metadata compliance with canonical standard

**Complexity**: Medium

**Files Created**:
- /home/benjamin/.config/.claude/scripts/lint/validate-plan-metadata.sh

**Tasks**:
- [x] Create validate-plan-metadata.sh script with shebang and set -euo pipefail
- [x] Add argument parsing: accept plan file path as $1, exit with error if missing/invalid
- [x] Extract ## Metadata section from plan file (between "## Metadata" and next "##" heading)
- [x] Validate 6 required fields present: Date, Feature, Status, Estimated Hours, Standards File, Research Reports
- [x] Validate Date format: `YYYY-MM-DD` or `YYYY-MM-DD (Revised)` using regex
- [x] Validate Status format: `[NOT STARTED]`, `[IN PROGRESS]`, `[COMPLETE]`, or `[BLOCKED]` using bracket notation
- [x] Validate Estimated Hours format: `{low}-{high} hours` as numeric range
- [x] Validate Standards File is absolute path (starts with /)
- [x] Validate Research Reports use relative paths with markdown links `[Title](../reports/file.md)`
- [x] Check optional recommended fields (Scope, Complexity Score) and report INFO if missing
- [x] Return exit 0 for pass, exit 1 for errors, output ERROR/WARNING/INFO messages to stderr
- [x] Add usage documentation in script comments

**Testing**:
```bash
# Test with valid plan
bash /home/benjamin/.config/.claude/scripts/lint/validate-plan-metadata.sh \
  /home/benjamin/.config/.claude/specs/006_plan_command_orchestration_fix/plans/001-plan-command-orchestration-fix-plan.md
# Should exit 0

# Test with plan missing required field (create test fixture)
TEMP_PLAN=$(mktemp)
cat > "$TEMP_PLAN" <<'EOF'
# Test Plan

## Metadata
- **Date**: 2025-12-02
- **Feature**: Test feature
EOF

bash /home/benjamin/.config/.claude/scripts/lint/validate-plan-metadata.sh "$TEMP_PLAN"
# Should exit 1 with ERROR messages

rm "$TEMP_PLAN"

# Test format validation (invalid date format)
TEMP_PLAN=$(mktemp)
cat > "$TEMP_PLAN" <<'EOF'
# Test Plan

## Metadata
- **Date**: 12-02-2025
- **Feature**: Test feature
- **Status**: [COMPLETE]
- **Estimated Hours**: 10 hours
- **Standards File**: /path/to/CLAUDE.md
- **Research Reports**: none
EOF

bash /home/benjamin/.config/.claude/scripts/lint/validate-plan-metadata.sh "$TEMP_PLAN"
# Should show WARNING for date format

rm "$TEMP_PLAN"
```

**Expected Duration**: 3-4 hours

---

### Phase 4: Integrate Validation into Infrastructure [COMPLETE]
dependencies: [3]

**Objective**: Integrate plan metadata validator into validate-all-standards.sh and pre-commit hooks

**Complexity**: Low

**Files Modified**:
- /home/benjamin/.config/.claude/scripts/validate-all-standards.sh
- /home/benjamin/.config/.claude/hooks/pre-commit

**Tasks**:
- [x] Add --plans flag and RUN_PLANS variable to validate-all-standards.sh
- [x] Create validate_plans() function that finds all .md files in specs/*/plans/ directories
- [x] Invoke validate-plan-metadata.sh for each plan file found
- [x] Add --plans to --all flag processing (runs with --all)
- [x] Update help text to document --plans category
- [x] Modify pre-commit hook to detect staged plan files (*.md in specs/*/plans/)
- [x] Add loop to validate each staged plan file using validate-plan-metadata.sh
- [x] Set EXIT_CODE=1 if any plan validation fails (blocks commit)
- [x] Test pre-commit hook with valid and invalid plan files
- [x] Document in /home/benjamin/.config/.claude/docs/reference/standards/enforcement-mechanisms.md

**Testing**:
```bash
# Test validate-all-standards.sh --plans
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --plans
# Should validate all existing plans

# Test pre-commit hook with staged plan
cd /home/benjamin/.config
git add .claude/specs/010_repair_plan_standards_enforcement/plans/001-repair-plan-standards-enforcement-plan.md

# Run pre-commit hook manually
bash .claude/hooks/pre-commit
# Should validate plan metadata

# Test with invalid plan (create bad metadata)
TEMP_PLAN=".claude/specs/999_test/plans/001-test-plan.md"
mkdir -p "$(dirname "$TEMP_PLAN")"
cat > "$TEMP_PLAN" <<'EOF'
# Test Plan
## Metadata
- **Date**: 2025-12-02
EOF

git add "$TEMP_PLAN"
bash .claude/hooks/pre-commit
# Should exit 1 (block commit) with ERROR message

# Cleanup
rm -rf .claude/specs/999_test
git reset HEAD "$TEMP_PLAN"
```

**Expected Duration**: 2-3 hours

---

### Phase 5: Update plan-architect for Self-Validation [COMPLETE]
dependencies: [3]

**Objective**: Update plan-architect agent to validate its own metadata before returning, ensuring all plans conform regardless of workflow context

**Complexity**: Low

**Files Modified**:
- /home/benjamin/.config/.claude/agents/plan-architect.md

**Tasks**:
- [x] Locate STEP 3 (Plan Verification) in plan-architect.md (~line 180-215)
- [x] Add substep 5: "Verify Metadata Compliance" after existing verifications
- [x] Add bash snippet showing validate-plan-metadata.sh invocation with error handling
- [x] Update self-verification checklist to include "Metadata validation passes (exit 0)"
- [x] Document required fields, format validation, and research report link format in substep
- [x] Add reference to plan-metadata-standard.md for complete field specifications
- [x] Test plan-architect creates plans that pass metadata validation

**Testing**:
```bash
# Test plan-architect via /plan command
/plan "test metadata validation integration" --complexity 1

# Verify created plan passes metadata validation
CREATED_PLAN=$(find .claude/specs -name "*test*plan*.md" -type f -mmin -5 | head -1)
bash /home/benjamin/.config/.claude/scripts/lint/validate-plan-metadata.sh "$CREATED_PLAN"
# Should exit 0

# Test plan-architect via /repair command
/repair --since 1h --type validation_error --complexity 1

# Verify repair plan passes metadata validation
REPAIR_PLAN=$(find .claude/specs -name "*repair*plan*.md" -type f -mmin -5 | head -1)
bash /home/benjamin/.config/.claude/scripts/lint/validate-plan-metadata.sh "$REPAIR_PLAN"
# Should exit 0

# Verify research reports in metadata (if research reports provided)
grep -A10 "Research Reports" "$CREATED_PLAN" | grep -q "\.\./reports/"
```

**Expected Duration**: 2-3 hours

---

## Testing Strategy

### Unit Testing
- Test validate-plan-metadata.sh with fixtures covering all validation paths
- Test required field detection (missing fields)
- Test format validation (dates, status markers, hours, paths)
- Test research report link format validation
- Test optional field INFO messages

### Integration Testing
- Test /plan command creates plans with valid metadata
- Test /repair command creates plans with valid metadata
- Test /revise command preserves metadata compliance during revisions
- Test pre-commit hook blocks commits with invalid plan metadata
- Test validate-all-standards.sh --plans validates all existing plans
- Test plan-architect self-validation prevents non-compliant plans

### Regression Testing
- Verify existing plans are NOT broken by validation (backward compatibility)
- Verify metadata-extraction.sh still parses plans correctly
- Verify plan-core-bundle.sh functions work with both old and new metadata
- Verify /implement can parse plans with standard metadata

### Validation Coverage
- All 6 required fields validated
- All format specifications validated
- Research reports link format validated
- Optional fields generate INFO messages
- ERROR-level violations block commits
- WARNING-level issues are informational only

## Documentation Requirements

### New Documentation
- `/home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md` - Comprehensive standard with field specifications, validation rules, integration points, extension mechanism, and migration strategy

### Updated Documentation
- `/home/benjamin/.config/CLAUDE.md` - New lightweight `plan_metadata_standard` section with quick reference and link to comprehensive doc
- `/home/benjamin/.config/.claude/lib/plan/standards-extraction.sh` - Updated to include plan_metadata_standard in extracted planning standards
- `/home/benjamin/.config/.claude/docs/reference/standards/README.md` - Updated catalog with plan-metadata-standard.md entry
- `/home/benjamin/.config/.claude/agents/plan-architect.md` - STEP 3 updated with metadata validation substep
- `/home/benjamin/.config/.claude/docs/reference/standards/enforcement-mechanisms.md` - Document plan metadata validator integration

### Documentation Standards Compliance
- Follow reference architecture pattern: comprehensive doc in .claude/docs/reference/standards/, quick reference in CLAUDE.md
- Follow existing CLAUDE.md section pattern (comment markers, "Used by" metadata, "See [Full Doc]" opening)
- Use clear, concise language without historical commentary
- Include code examples with syntax highlighting
- Cross-reference related documentation (standards-integration.md, metadata-extraction.md)
- Document backward compatibility and migration approach

## Dependencies

### Prerequisites
- Existing standards-extraction.sh infrastructure (already implemented)
- Existing validate-all-standards.sh infrastructure (already implemented)
- Existing pre-commit hook infrastructure (already implemented)
- Existing plan-parsing libraries (plan-core-bundle.sh, metadata-extraction.sh)

### External Dependencies
- None (all implementation uses existing bash, grep, sed patterns)

### Integration Points
- CLAUDE.md standards injection pattern
- Pre-commit hook validation pattern
- Unified validation script pattern
- Plan-architect agent protocol
- /plan, /repair, /revise, /debug commands

## Risk Assessment

| Phase | Risk Level | Mitigation |
|-------|-----------|------------|
| Phase 1 | Low | CLAUDE.md section pattern well-established |
| Phase 2 | Medium | /repair context change may affect existing workflows - test thoroughly |
| Phase 3 | Low | Validation script is new code but follows existing patterns |
| Phase 4 | Medium | Pre-commit hook changes may break developer workflow - provide clear error messages |
| Phase 5 | Low | plan-architect changes are additive (validation step) |

**Rollback Strategy**:
- Phase 1: Remove CLAUDE.md section
- Phase 2: Revert repair.md Task invocation changes
- Phase 3: Delete validate-plan-metadata.sh
- Phase 4: Revert validate-all-standards.sh and pre-commit hook changes
- Phase 5: Revert plan-architect.md STEP 3 changes

**Testing Strategy to Minimize Risk**:
- Test each phase independently with fixtures
- Test integration with existing plans (backward compatibility)
- Test all plan-generating commands after Phase 5
- Document bypass procedure (git commit --no-verify) for emergencies

## Completion Checklist

- [ ] Phase 1: Comprehensive plan-metadata-standard.md created in .claude/docs/reference/standards/
- [ ] Phase 1: Lightweight CLAUDE.md section added with quick reference and link to full doc
- [ ] Phase 1: standards-extraction.sh updated to include plan_metadata_standard
- [ ] Phase 1: standards/README.md catalog updated
- [ ] Phase 2: /repair command uses normalized context format
- [ ] Phase 3: validate-plan-metadata.sh script created and tested
- [ ] Phase 4: Validation integrated into validate-all-standards.sh and pre-commit hook
- [ ] Phase 5: plan-architect self-validates metadata with reference to comprehensive standard
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] All regression tests passing (existing plans not broken)
- [ ] Pre-commit hook validated with staged plan files
- [ ] Documentation follows reference architecture pattern (no duplication)
- [ ] No regressions in /plan, /repair, /revise, /debug commands

---

**Plan Status**: Ready for implementation
**Next Step**: Execute with `/build` or `/implement` command
