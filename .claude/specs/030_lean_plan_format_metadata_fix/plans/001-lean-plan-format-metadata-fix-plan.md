# Implementation Plan: Fix /lean-plan Format and Metadata Issues

## Metadata
- **Date**: 2025-12-08 (Revised)
- **Feature**: Fix /lean-plan command to generate plans with correct phase heading format (### not ##), phase metadata (dependencies, implementer), and Status metadata compliance, plus documentation updates to prevent recurrence
- **Status**: [IN PROGRESS]
- **Estimated Hours**: 14-20 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Lean Plan Format Issues](../reports/001-lean-plan-format-issues.md)
  - [Correct Plan Format Reference](../reports/002-correct-plan-format-reference.md)
  - [Lean Plan Architect Analysis](../reports/003-lean-plan-architect-analysis.md)
  - [Command Authoring Standards Gaps](../reports/004-command-authoring-standards-gaps.md)

## Overview

The /lean-plan command currently generates plans with format issues that cause /lean-implement parser failures and inconsistent metadata. Root cause analysis reveals the lean-plan-architect.md behavioral file has correct format specifications in templates but lacks enforcement mechanisms and explicit warnings that prevent format violations. Additionally, documentation gaps in command authoring standards, enforcement mechanisms reference, and CLAUDE.md prevent future command authors from avoiding similar issues.

**Critical Issues Identified**:
1. Phase headings use `## Phase N:` (level 2) instead of `### Phase N:` (level 3)
2. Missing `dependencies: []` declarations immediately after phase headings
3. Missing `implementer: lean|software` field declarations
4. Inconsistent Status metadata format (`[IN PROGRESS]` vs proper format)
5. No automated validation enforcement in behavioral file
6. Command authoring standards lack plan metadata integration guidance
7. Enforcement mechanisms documentation missing plan metadata validation tool
8. CLAUDE.md section metadata excludes /lean-plan from listed commands
9. /lean-implement does not update plan metadata to `[COMPLETE]` when all phases finish

## Research Summary

**Report 1 - Lean Plan Format Issues**: Analysis of reference lean plan (048_minimal_axiom_review_proofs) identified four critical format issues:
- Phase headings incorrectly use level-2 (`##`) instead of level-3 (`###`)
- No per-phase dependency declarations (`dependencies: []` missing)
- No implementation type indicators (`implementer: lean|software` missing)
- Inconsistent status metadata formatting with brackets

**Report 2 - Correct Plan Format Reference**: Analysis of 3 production plans from /create-plan reveals the correct format:
- Two-line phase structure: `### Phase N: Title [STATUS]` followed by `dependencies: [...]` on next line
- All plans use level-3 headings consistently (100% across all analyzed plans)
- Dependencies always explicit (even empty: `dependencies: []`)
- Metadata has 6 required fields with strict ordering

**Report 3 - Lean Plan Architect Analysis**: Identified root cause in behavioral file:
- Line 256 specifies `### Phase N:` format but lacks enforcement emphasis
- Line 242 describes field order but not marked as parser-critical
- Lines 276-345 have manual verification checklist but no automated validation script
- Missing validation commands like plan-architect.md has (lines 1178-1204)

**Report 4 - Command Authoring Standards Gaps**: Identified five documentation gaps preventing format issues in future commands:
- command-authoring.md lacks plan metadata integration guidance section (Gap 1)
- enforcement-mechanisms.md missing validate-plan-metadata.sh in tool inventory (Gap 2)
- CLAUDE.md plan_metadata_standard section excludes /lean-plan from "Used by" metadata (Gap 3)
- No enforcement strategy decision matrix exists (Gap 4)
- Lean-specific metadata fields undocumented (Gap 5, optional)

## Success Criteria

**Behavioral File Fixes**:
- [ ] All phase headings in generated plans use `### Phase N:` (level 3, not level 2)
- [ ] All phases have `dependencies: []` line immediately after heading
- [ ] All phases have `implementer: lean|software` field in correct position
- [ ] Metadata **Status** field uses `[NOT STARTED]` format for new plans
- [ ] Phase Routing Summary table validation added
- [ ] Automated metadata validation script execution enforced
- [ ] Self-verification checklist includes format checks
- [ ] Test plan generation confirms correct format compliance

**Documentation Updates**:
- [ ] command-authoring.md has "Plan Metadata Standard Integration" section with format_standards_for_prompt() usage examples
- [ ] enforcement-mechanisms.md includes validate-plan-metadata.sh in all relevant sections (tool inventory, mapping, pre-commit, unified validation)
- [ ] CLAUDE.md plan_metadata_standard section includes /lean-plan in "Used by" metadata
- [ ] All documentation changes follow Writing Standards (no historical commentary, clear language)

**Workflow Completion Fix**:
- [x] /lean-implement calls `update_plan_status "$PLAN_FILE" "COMPLETE"` when all phases complete
- [x] Plan metadata status shows `[COMPLETE]` after successful workflow completion with all phases done

## Technical Design

### Architecture Overview

The fix involves updating lean-plan-architect.md behavioral file to add:
1. Explicit format enforcement with "parser-critical" warnings
2. Automated validation script execution requirements
3. Enhanced self-verification checklist with format checks
4. Strengthened template examples with visual comparisons

### Root Cause Analysis

The lean-plan-architect.md file correctly specifies level-3 headings in templates (lines 203, 256, 391, 423) but lacks:
1. **Enforcement emphasis**: "matching /create-plan standard" assumes agent knowledge
2. **Automated validation**: No scripts to catch violations like plan-architect.md has
3. **Parser-critical marking**: Field order not marked as mandatory for /lean-implement

### Key Design Decisions

**Decision 1**: Add explicit "three hashes" instructions
- **Rationale**: "level 3" is ambiguous; "three hashes ###" is concrete and visual
- **Impact**: Reduces ambiguity in heading format specification

**Decision 2**: Mark field order as "parser enforced"
- **Rationale**: Makes clear violations break /lean-implement, not just style issues
- **Impact**: Elevates importance from optional to mandatory

**Decision 3**: Add metadata validation script execution
- **Rationale**: Follows plan-architect.md pattern (lines 1178-1204) for enforcement
- **Impact**: Catches metadata compliance issues before plan finalization

**Decision 4**: Enhance self-verification checklist
- **Rationale**: Provides agent with concrete format checks to perform
- **Impact**: Improves plan quality through systematic verification

## Implementation Phases

### Phase 1: Clarify Phase Heading Format Instructions [COMPLETE]
dependencies: []

**Objective**: Update lean-plan-architect.md to explicitly specify "three hashes" for phase headings and add parser compatibility warnings.

**Complexity**: Low

**Tasks**:
- [x] Update line 256 in lean-plan-architect.md (file: /home/benjamin/.config/.claude/agents/lean-plan-architect.md)
  - Old: "ALL phase headings MUST use `### Phase N:` format (level 3, matching /create-plan standard)"
  - New: "CRITICAL: ALL phase headings MUST use exactly three hash marks: `### Phase N:` (level 3 heading, NOT ## which is level 2). This matches /create-plan standard and ensures parse compatibility with /lean-implement. Example: `### Phase 1: Foundation [NOT STARTED]` (correct) vs `## Phase 1: ...` (WRONG)"
  - Rationale: Adds visual clarity with "three hashes" language and wrong/correct examples

- [x] Update line 391 template heading comment
  - Old: "Use this template for each phase:"
  - New: "Use this template for each phase (NOTE: heading is level 3 - three hashes ###):"
  - Add after template: "**CRITICAL**: The phase heading above uses THREE hash marks (###) for level 3 heading. CORRECT: `### Phase 1: ...` (level 3). WRONG: `## Phase 1: ...` (level 2 - DO NOT USE). The level 3 format is required for /lean-implement parser compatibility."

**Testing**:
```bash
# Verify changes applied
grep -n "CRITICAL.*three hash marks" /home/benjamin/.config/.claude/agents/lean-plan-architect.md

# Should show line 256 and ~395 (near template section)
# Verify line count is 2
grep -c "three hash marks" /home/benjamin/.config/.claude/agents/lean-plan-architect.md
# Expected: 2
```

**Expected Duration**: 1 hour

### Phase 2: Enforce Mandatory Field Order [COMPLETE]
dependencies: []

**Objective**: Update implementer field documentation to mark field order as parser-enforced with correct/wrong examples.

**Complexity**: Low

**Tasks**:
- [x] Replace lines 242-245 in lean-plan-architect.md with enhanced field order section
  - Add "MANDATORY FIELD ORDER (parser enforced)" header
  - List exact sequence: heading → implementer → lean_file → dependencies
  - Add WRONG ORDER EXAMPLE showing parser failure case
  - Add CORRECT ORDER EXAMPLE with inline comments
  - Make clear "lean_file" only for lean phases (software phases omit)

**Testing**:
```bash
# Verify MANDATORY FIELD ORDER section exists
grep -A 20 "MANDATORY FIELD ORDER" /home/benjamin/.config/.claude/agents/lean-plan-architect.md | grep -q "parser enforced"

# Verify wrong/correct examples present
grep -c "WRONG ORDER EXAMPLE" /home/benjamin/.config/.claude/agents/lean-plan-architect.md
# Expected: 1

grep -c "CORRECT ORDER EXAMPLE" /home/benjamin/.config/.claude/agents/lean-plan-architect.md
# Expected: 1
```

**Expected Duration**: 1-2 hours

### Phase 3: Add Metadata Validation Script Execution [COMPLETE]
dependencies: []

**Objective**: Insert automated metadata validation script execution section before Lean-specific verification section.

**Complexity**: Medium

**Tasks**:
- [x] Insert new section at line 290 in lean-plan-architect.md (before "**Lean-Specific Verification**:")
  - Section title: "**Metadata Validation** (MANDATORY - Execute Before Lean-Specific Checks):"
  - Add bash script invoking validate-plan-metadata.sh with exit code checking
  - List 8 required metadata fields with format specifications
  - Reference Plan Metadata Standard documentation
  - Include Lean-specific fields: Lean File and Lean Project

- [x] Verify validate-plan-metadata.sh script exists and is executable
  - Path: /home/benjamin/.config/.claude/scripts/lint/validate-plan-metadata.sh
  - If missing, document as dependency blocker

**Testing**:
```bash
# Verify metadata validation section inserted
grep -n "Metadata Validation.*MANDATORY" /home/benjamin/.config/.claude/agents/lean-plan-architect.md

# Should show line ~290 (before Lean-Specific Verification)

# Verify script reference present
grep -q "validate-plan-metadata.sh" /home/benjamin/.config/.claude/agents/lean-plan-architect.md

# Verify required fields listed
grep -A 15 "Required Metadata Fields" /home/benjamin/.config/.claude/agents/lean-plan-architect.md | grep -c "^\- \*\*"
# Expected: 8 (Date, Feature, Status, Estimated Hours, Standards File, Research Reports, Lean File, Lean Project)
```

**Expected Duration**: 2-3 hours

### Phase 4: Add Phase Routing Summary Validation [COMPLETE]
dependencies: []

**Objective**: Insert Phase Routing Summary table validation script in verification section.

**Complexity**: Medium

**Tasks**:
- [x] Insert new validation section at line ~318 (in theorem count validation area)
  - Section title: "**Phase Routing Summary Validation**:"
  - Add bash script checking for "### Phase Routing Summary" heading
  - Validate table has ≥2 rows (header + at least one phase)
  - Add error messages for missing table or incomplete rows
  - Add success message when validation passes

**Testing**:
```bash
# Verify Phase Routing Summary validation section added
grep -n "Phase Routing Summary Validation" /home/benjamin/.config/.claude/agents/lean-plan-architect.md

# Verify grep command for table presence
grep -A 10 "Phase Routing Summary Validation" /home/benjamin/.config/.claude/agents/lean-plan-architect.md | grep -q "grep -q.*Phase Routing Summary"

# Verify row count validation
grep -A 10 "Phase Routing Summary Validation" /home/benjamin/.config/.claude/agents/lean-plan-architect.md | grep -q "TABLE_ROWS"
```

**Expected Duration**: 1-2 hours

### Phase 5: Update Self-Verification Checklist [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Enhance self-verification checklist to include format checks for heading level, field order, and validation script execution.

**Complexity**: Low

**Tasks**:
- [x] Update lines 334-343 (Self-Verification Checklist section) in lean-plan-architect.md
  - Add: "Metadata validation script executed and passed (EXIT_CODE=0)"
  - Add: "Phase Routing Summary table present and valid (≥2 rows)"
  - Add: "ALL phase headings use level 3 format: `### Phase N:` (three hashes, not two)"
  - Add: "ALL phases have `implementer:` field immediately after heading"
  - Add: "ALL phases have correct field order: heading → implementer → lean_file → dependencies"
  - Keep existing checklist items (plan path, sections, research, theorems, dependencies)

**Testing**:
```bash
# Verify checklist updated with new items
grep -A 20 "Self-Verification Checklist" /home/benjamin/.config/.claude/agents/lean-plan-architect.md | grep -c "metadata validation script"
# Expected: 1

grep -A 20 "Self-Verification Checklist" /home/benjamin/.config/.claude/agents/lean-plan-architect.md | grep -c "three hashes, not two"
# Expected: 1

grep -A 20 "Self-Verification Checklist" /home/benjamin/.config/.claude/agents/lean-plan-architect.md | grep -c "correct field order"
# Expected: 1
```

**Expected Duration**: 1 hour

### Phase 6: Integration Testing with /lean-plan Command [NOT STARTED]
dependencies: [5]

**Objective**: Test the updated lean-plan-architect behavioral file by generating a test plan and verifying format compliance.

**Complexity**: Medium

**Tasks**:
- [ ] Create test lean plan using /lean-plan command
  - Command: `/lean-plan "Implement basic group theory axioms with Mathlib integration" --complexity 3`
  - Target: Create plan in test spec directory

- [ ] Verify generated plan format compliance
  - Check all phase headings use `### Phase N:` (level 3)
  - Check all phases have `implementer: lean|software` field
  - Check all phases have `dependencies: []` line
  - Check field order is correct: heading → implementer → lean_file → dependencies
  - Check metadata has all 8 required fields
  - Check Phase Routing Summary table present

- [ ] Run validation script manually on generated plan
  - Command: `bash .claude/scripts/lint/validate-plan-metadata.sh [plan-path]`
  - Expected: EXIT_CODE=0 (no errors)

- [ ] Test negative case with intentionally broken format
  - Manually create plan with `## Phase N:` (level 2 heading)
  - Verify validation catches the error
  - Manually create plan with wrong field order
  - Verify error is reported

**Testing**:
```bash
# Generate test plan
cd /home/benjamin/.config
/lean-plan "Implement basic group theory axioms with Mathlib integration" --complexity 3

# Find generated plan path
PLAN_PATH=$(find .claude/specs -name "*group_theory*" -type d | head -1)/plans/001-*.md

# Verify phase heading format (should all be level 3)
grep "^## Phase" "$PLAN_PATH" && echo "ERROR: Found level-2 phase headings" || echo "✓ All phase headings are level 3"

# Verify implementer field present
PHASE_COUNT=$(grep -c "^### Phase" "$PLAN_PATH")
IMPLEMENTER_COUNT=$(grep -c "^implementer: " "$PLAN_PATH")
[ "$PHASE_COUNT" -eq "$IMPLEMENTER_COUNT" ] && echo "✓ All phases have implementer field" || echo "ERROR: Missing implementer fields"

# Verify dependencies present
DEPS_COUNT=$(grep -c "^dependencies: " "$PLAN_PATH")
[ "$PHASE_COUNT" -eq "$DEPS_COUNT" ] && echo "✓ All phases have dependencies" || echo "ERROR: Missing dependencies"

# Run validation script
bash .claude/scripts/lint/validate-plan-metadata.sh "$PLAN_PATH"
```

**Expected Duration**: 2-3 hours

### Phase 7: Update Command Authoring Standards with Plan Metadata Integration [COMPLETE]
dependencies: []

**Objective**: Add "Plan Metadata Standard Integration" section to command-authoring.md to document when and how to integrate plan metadata standards into command workflows.

**Complexity**: Medium

**Tasks**:
- [x] Insert new section at line 1190 in command-authoring.md (file: /home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md)
  - Section title: "Plan Metadata Standard Integration"
  - Location: After "Output Suppression Requirements" section, before "Command Integration Patterns"

- [x] Add subsection: "When to Inject Plan Metadata Standards"
  - Content: All plan-generating commands must inject standards
  - List eligible commands: /create-plan, /lean-plan, /repair, /revise, /debug
  - Rationale: Proactive compliance via agent context injection

- [x] Add subsection: "How to Use format_standards_for_prompt()"
  - Source library: .claude/lib/plan/standards-extraction.sh
  - Function signature and return behavior
  - Graceful degradation pattern (empty string on failure)
  - Integration point: Before Task tool invocation with plan-generating agent

- [x] Add subsection: "Example Integration Pattern"
  - Use /create-plan as reference implementation (lines 1888-1895)
  - Show bash code block with sourcing, extraction, and injection
  - Include error logging pattern for extraction failures
  - Show Task invocation with ${FORMATTED_STANDARDS} variable

- [x] Add subsection: "Validation Script Invocation"
  - When to invoke: After agent returns plan artifact
  - Script path: .claude/scripts/lint/validate-plan-metadata.sh
  - Exit code handling: Log error but allow workflow continuation
  - Example bash code block from /create-plan pattern

- [x] Add subsection: "CLAUDE.md Section Metadata Updates"
  - Update plan_metadata_standard section "Used by" metadata
  - Add command name to metadata list when integrating standards
  - Location: CLAUDE.md line 218 (example reference)

**Testing**:
```bash
# Verify new section added at correct location
grep -n "^## Plan Metadata Standard Integration" /home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md

# Should show line ~1190 (between Output Suppression and Command Integration)

# Verify all subsections present
SECTION_START=$(grep -n "^## Plan Metadata Standard Integration" /home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md | cut -d: -f1)
SECTION_END=$(tail -n +$SECTION_START /home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md | grep -n "^## " | sed -n '2p' | cut -d: -f1)

# Extract section and verify subsections
tail -n +$SECTION_START /home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md | head -n $((SECTION_END - 1)) > /tmp/metadata_section.txt

grep -c "^### When to Inject Plan Metadata Standards" /tmp/metadata_section.txt
# Expected: 1

grep -c "^### How to Use format_standards_for_prompt" /tmp/metadata_section.txt
# Expected: 1

grep -c "^### Example Integration Pattern" /tmp/metadata_section.txt
# Expected: 1

grep -c "^### Validation Script Invocation" /tmp/metadata_section.txt
# Expected: 1

grep -c "^### CLAUDE.md Section Metadata Updates" /tmp/metadata_section.txt
# Expected: 1

# Verify code examples present
grep -c '```bash' /tmp/metadata_section.txt
# Expected: ≥2 (Example Integration + Validation Script)
```

**Expected Duration**: 2-3 hours

### Phase 8: Update Enforcement Mechanisms Documentation [COMPLETE]
dependencies: []

**Objective**: Update enforcement-mechanisms.md to include validate-plan-metadata.sh in tool inventory, mapping tables, pre-commit documentation, and unified validation categories.

**Complexity**: Low

**Tasks**:
- [x] Add to Tool Inventory Table (line ~15) in enforcement-mechanisms.md (file: /home/benjamin/.config/.claude/docs/reference/standards/enforcement-mechanisms.md)
  - Row: `| validate-plan-metadata.sh | scripts/lint/ | Plan metadata format and required fields | ERROR | Yes |`
  - Insert in alphabetical order with other validators

- [x] Add Tool Description Section (line ~288)
  - Section title: "### validate-plan-metadata.sh"
  - Purpose: "Validates plan metadata compliance with plan-metadata-standard.md"
  - Checks Performed (6 items):
    1. Required fields: Date, Feature, Status, Estimated Hours, Standards File, Research Reports
    2. Date format: YYYY-MM-DD or YYYY-MM-DD (Revised)
    3. Status format: Bracket notation with approved statuses
    4. Estimated Hours: Numeric range with "hours" suffix
    5. Standards File: Absolute path validation
    6. Research Reports: Relative path links or literal "none"
  - Exit Codes: 0 (passed), 1 (failed)
  - Usage example in bash code block
  - Related Standard link to plan-metadata-standard.md

- [x] Add to Standards-to-Tool Mapping Table (line ~295)
  - Row: `| plan-metadata-standard.md | validate-plan-metadata.sh |`
  - Insert in alphabetical order by standard name

- [x] Add to Pre-Commit Documentation (line ~310)
  - Add item 7: "Run validate-plan-metadata.sh on staged plan files in specs/*/plans/"
  - Location: In pre-commit behavior enumeration list

- [x] Add to Unified Validation Categories (line ~361)
  - Add new category: `bash .claude/scripts/validate-all-standards.sh --plans       # Plan metadata validation`
  - Location: In category option list with comments
  - Insert in alphabetical order with other categories

**Testing**:
```bash
# Verify tool added to inventory table
grep "validate-plan-metadata.sh" /home/benjamin/.config/.claude/docs/reference/standards/enforcement-mechanisms.md | grep -q "scripts/lint/"

# Verify tool description section exists
grep -n "^### validate-plan-metadata.sh" /home/benjamin/.config/.claude/docs/reference/standards/enforcement-mechanisms.md

# Should show line ~288 (in tool descriptions area)

# Verify mapping table updated
grep "plan-metadata-standard.md" /home/benjamin/.config/.claude/docs/reference/standards/enforcement-mechanisms.md | grep -q "validate-plan-metadata.sh"

# Verify pre-commit documentation includes plan validation
grep -A 20 "Pre-Commit Integration" /home/benjamin/.config/.claude/docs/reference/standards/enforcement-mechanisms.md | grep -q "validate-plan-metadata.sh.*staged plan files"

# Verify unified validation category added
grep -A 30 "Unified Validation" /home/benjamin/.config/.claude/docs/reference/standards/enforcement-mechanisms.md | grep -q "\-\-plans.*Plan metadata validation"

# Count total mentions of validate-plan-metadata.sh
grep -c "validate-plan-metadata.sh" /home/benjamin/.config/.claude/docs/reference/standards/enforcement-mechanisms.md
# Expected: ≥5 (inventory, description section, mapping, pre-commit, unified validation)
```

**Expected Duration**: 1 hour

### Phase 9: Update CLAUDE.md Section Metadata [COMPLETE]
dependencies: []

**Objective**: Update CLAUDE.md to include /lean-plan in plan_metadata_standard section "Used by" metadata and add prominent link to command-authoring.md for command authors.

**Complexity**: Low

**Tasks**:
- [x] Update plan_metadata_standard section metadata (line 218) in CLAUDE.md (file: /home/benjamin/.config/CLAUDE.md)
  - Old: `[Used by: /create-plan, /repair, /revise, /debug, plan-architect]`
  - New: `[Used by: /create-plan, /lean-plan, /repair, /revise, /debug, plan-architect]`
  - Insert /lean-plan in alphabetical order after /create-plan

- [x] Update code_standards section (around line 129)
  - Locate "Quick Reference - Task Invocation" subsection
  - Add new "Quick Reference - Plan Metadata Integration" subsection after it
  - Content: "All plan-generating commands MUST inject plan metadata standards via format_standards_for_prompt()"
  - Add link: "See [Plan Metadata Standard Integration](.claude/docs/reference/standards/command-authoring.md#plan-metadata-standard-integration)"
  - Purpose: Make metadata integration requirements visible to command authors browsing code standards

**Testing**:
```bash
# Verify /lean-plan added to metadata
grep "plan_metadata_standard" -A 3 /home/benjamin/.config/CLAUDE.md | grep -q "lean-plan"

# Verify command order is alphabetical
METADATA_LINE=$(grep -n "\[Used by:.*plan-architect\]" /home/benjamin/.config/CLAUDE.md | grep "plan_metadata_standard" -B 2 | head -1 | cut -d: -f1)
sed -n "${METADATA_LINE}p" /home/benjamin/.config/CLAUDE.md | grep -o "/[a-z-]*" | tr '\n' ' '
# Should show: /create-plan /lean-plan /repair /revise /debug (alphabetical)

# Verify code_standards section has new quick reference
grep -A 50 "<!-- SECTION: code_standards -->" /home/benjamin/.config/CLAUDE.md | grep -q "Quick Reference - Plan Metadata Integration"

# Verify link to command-authoring.md present
grep -A 50 "<!-- SECTION: code_standards -->" /home/benjamin/.config/CLAUDE.md | grep -q "command-authoring.md#plan-metadata-standard-integration"
```

**Expected Duration**: 30 minutes

### Phase 10: Fix /lean-implement Plan Status Update on Completion [COMPLETE]
dependencies: []

**Objective**: Fix `/lean-implement` Block 2 to call `update_plan_status` with "COMPLETE" status when all phases are marked complete.

**Complexity**: Low

**Root Cause**: The `/lean-implement` command computes `PLAN_COMPLETE=true` when `check_all_phases_complete` returns success, but never calls `update_plan_status "$PLAN_FILE" "COMPLETE"` to update the plan metadata. This leaves the plan status as `[IN PROGRESS]` even when all phases show `[COMPLETE]`.

**Evidence**:
- Block 1a (lines 340-342) correctly sets status to `[IN PROGRESS]` at workflow start
- Block 2 (lines 1256-1261) checks completion but doesn't update status
- No subsequent call to `update_plan_status` with "COMPLETE" exists

**Tasks**:
- [x] Add plan status update logic after `PLAN_COMPLETE` check in Block 2 (file: /home/benjamin/.config/.claude/commands/lean-implement.md)
  - Location: After line 1261 (after `check_all_phases_complete` block)
  - Insert code block:
    ```bash
    # Update plan metadata status if all phases complete
    if [ "$PLAN_COMPLETE" = "true" ]; then
      if type update_plan_status &>/dev/null; then
        if update_plan_status "$PLAN_FILE" "COMPLETE" 2>/dev/null; then
          echo "Plan metadata status updated to [COMPLETE]"
        else
          echo "WARNING: Could not update plan metadata status to COMPLETE" >&2
        fi
      fi
    fi
    ```

- [x] Add corresponding logic for partial completion scenarios
  - If `PLAN_COMPLETE=false` but workflow completed normally, status should remain `[IN PROGRESS]`
  - If workflow was halted (max iterations, stuck), status should remain `[IN PROGRESS]`
  - Only update to `[COMPLETE]` when `check_all_phases_complete` returns true

- [x] Update Success Metrics section to include plan status verification
  - Add metric: "Plan metadata status shows [COMPLETE] when all phases complete"

**Testing**:
```bash
# Verify the new code block exists in lean-implement.md
grep -A 10 'PLAN_COMPLETE.*true' /home/benjamin/.config/.claude/commands/lean-implement.md | grep -q "update_plan_status.*COMPLETE"

# Verify the status update has proper error handling
grep -A 10 'update_plan_status.*COMPLETE' /home/benjamin/.config/.claude/commands/lean-implement.md | grep -q "WARNING.*Could not update"

# Integration test: Run /lean-implement on a plan with all phases complete
# Then verify: grep "Status.*COMPLETE" [plan-file]
```

**Expected Duration**: 1 hour

## Testing Strategy

### Unit Testing

Each phase has inline bash testing to verify specific changes:
- Phase 1: grep validation for "three hashes" text (2 occurrences expected)
- Phase 2: grep validation for MANDATORY FIELD ORDER section and examples
- Phase 3: grep validation for metadata validation script reference
- Phase 4: grep validation for Phase Routing Summary validation code
- Phase 5: grep validation for enhanced checklist items
- Phase 10: grep validation for update_plan_status COMPLETE call in lean-implement.md
- Phase 7: grep validation for Plan Metadata Standard Integration section and subsections
- Phase 8: grep validation for validate-plan-metadata.sh in enforcement-mechanisms.md (≥5 occurrences)
- Phase 9: grep validation for /lean-plan in CLAUDE.md metadata and new Quick Reference

### Integration Testing

Phase 6 provides end-to-end integration testing for behavioral file changes:
1. Generate actual lean plan using /lean-plan command
2. Verify all format requirements met
3. Run validation script to confirm compliance
4. Test negative cases to ensure error detection

Documentation changes (Phases 7-9) are validated through:
1. Cross-reference verification (links resolve correctly)
2. Section placement verification (correct line numbers)
3. Content consistency checks (metadata lists match actual usage)
4. Documentation standards compliance (no historical commentary)

### Regression Testing

After implementation, verify existing lean plans can be validated:
- Test validation script against spec 016, 009, 013 (known good plans)
- Ensure no false positives on correctly formatted plans

### Performance Testing

Not applicable - documentation changes have no performance impact.

## Documentation Requirements

### Files to Update

1. **lean-plan-architect.md** (Phases 1-5, primary target):
   - Line 256: Phase heading format clarification
   - Line 242-245: Field order enforcement section
   - Line 290: Metadata validation script section (insert)
   - Line 318: Phase Routing Summary validation (insert)
   - Line 391: Template heading comment
   - Lines 334-343: Self-verification checklist

2. **command-authoring.md** (Phase 7):
   - Line 1190: Insert "Plan Metadata Standard Integration" section (new)
   - Add 5 subsections documenting standards injection pattern

3. **enforcement-mechanisms.md** (Phase 8):
   - Line ~15: Add validate-plan-metadata.sh to tool inventory table
   - Line ~288: Add tool description section
   - Line ~295: Add to standards-to-tool mapping
   - Line ~310: Add to pre-commit documentation
   - Line ~361: Add to unified validation categories

4. **CLAUDE.md** (Phase 9):
   - Line 218: Add /lean-plan to plan_metadata_standard section metadata
   - Line ~129: Add Quick Reference - Plan Metadata Integration to code_standards section

### Documentation Standards

All changes follow:
- Clear, concise language per Documentation Policy
- Code examples with bash syntax highlighting
- Inline comments explaining WHAT, not WHY
- No historical commentary (clean-break development)

## Dependencies

### External Dependencies

None - all changes are to behavioral file and use existing validation infrastructure.

### Internal Dependencies

1. **validate-plan-metadata.sh script**: Must exist at `.claude/scripts/lint/validate-plan-metadata.sh`
   - If missing, Phase 3 blocked
   - Alternative: Document as assumption or create minimal validation script

2. **Plan Metadata Standard documentation**: Referenced in Phase 3
   - Path: `.claude/docs/reference/standards/plan-metadata-standard.md`
   - Must be accessible for agent reference

3. **/lean-implement parser**: Consumes generated plans
   - Changes must not break existing parser (verify Phase Routing Summary parsing still works)

### Standards Dependencies

- **Plan Metadata Standard**: Defines 6 required metadata fields
- **Command Authoring Standards**: Defines behavioral file format
- **Output Formatting Standards**: Defines checkpoint and validation patterns

## Risk Assessment

### High Risk

None identified - changes are isolated to behavioral file with backward-compatible format improvements.

### Medium Risk

**Risk**: Existing plans with incorrect format may fail validation after fix
- **Mitigation**: Validation script should be run in advisory mode first (warnings not errors) for existing plans
- **Impact**: Low - only new plans must meet strict format requirements

**Risk**: validate-plan-metadata.sh script may not exist or may be incomplete
- **Mitigation**: Phase 3 includes verification step; document as blocker if missing
- **Impact**: Medium - Phase 3 blocked if script unavailable

### Low Risk

**Risk**: Agent may not follow updated instructions despite clarifications
- **Mitigation**: Phase 6 integration testing will validate behavioral changes
- **Impact**: Low - can iterate on instruction wording if needed

## Rollback Plan

If format changes cause issues:
1. Revert lean-plan-architect.md to previous version (git revert)
2. Document specific failure mode in spec debug/ directory
3. Re-analyze with more restrictive format enforcement

Changes are isolated to behavioral file - no code changes required, making rollback trivial.

## Success Metrics

**Behavioral File Completion**:
- [ ] All phases 1-6 complete with tests passing
- [ ] Test plan generated with correct format (Phase 6)
- [ ] Validation script passes on test plan (EXIT_CODE=0)
- [ ] All phase headings use level 3 format (verified via grep)
- [ ] All phases have implementer and dependencies fields (verified via count comparison)
- [ ] Self-verification checklist includes format checks (verified via grep)

**Documentation Completion**:
- [ ] Phase 7 complete: command-authoring.md has Plan Metadata Standard Integration section
- [ ] Phase 8 complete: enforcement-mechanisms.md includes validate-plan-metadata.sh in all 5 locations
- [ ] Phase 9 complete: CLAUDE.md metadata updated and Quick Reference added
- [ ] All documentation follows Writing Standards (no historical commentary, clear language)
- [ ] All cross-reference links resolve correctly

**Workflow Fix Completion**:
- [x] Phase 10 complete: /lean-implement updates plan status to [COMPLETE] when all phases done
- [x] Integration test confirms plan metadata status updates correctly

## Next Steps

After plan approval:
1. Execute Phase 1: Update heading format instructions (lean-plan-architect.md)
2. Execute Phase 2: Add field order enforcement (lean-plan-architect.md)
3. Execute Phase 3: Add metadata validation script (lean-plan-architect.md)
4. Execute Phase 4: Add Phase Routing Summary validation (lean-plan-architect.md)
5. Execute Phase 5: Update self-verification checklist (lean-plan-architect.md)
6. Execute Phase 6: Integration testing with /lean-plan
7. Execute Phase 7: Update command authoring standards (command-authoring.md)
8. Execute Phase 8: Update enforcement mechanisms documentation (enforcement-mechanisms.md)
9. Execute Phase 9: Update CLAUDE.md section metadata
10. Execute Phase 10: Fix /lean-implement plan status update on completion (lean-implement.md)
11. Document results in spec completion summary
