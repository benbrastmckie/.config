# Implementation Plan: Remove Command Cross-References from /supervise

## Metadata
- **Plan ID**: 001_remove_orchestrate_references
- **Topic**: 078_supervise_orchestrate_ref_removal
- **Created**: 2025-10-23
- **Updated**: 2025-10-23 (expanded scope to all command references)
- **Completed**: 2025-10-23
- **Status**: ✅ IMPLEMENTATION COMPLETE
- **Complexity**: Medium-Low
- **Estimated Time**: 2-3 hours
- **Actual Time**: ~2 hours

## Objective
Remove inappropriate command cross-references from the /supervise command documentation while preserving essential architectural prohibitions. This includes removing /orchestrate comparisons, /implement suggestions, and /debug recommendations to achieve full compliance with the "no command chaining" principle. The /supervise command should stand independently without suggesting other commands.

## Research References
- `/home/benjamin/.config/.claude/specs/078_supervise_orchestrate_ref_removal/reports/001_orchestrate_references.md` - Initial /orchestrate reference analysis
- `/home/benjamin/.config/.claude/specs/078_supervise_orchestrate_ref_removal/reports/002_all_command_references.md` - Comprehensive command reference audit

## Success Criteria
- [x] All /orchestrate comparison references removed (5 occurrences) ✅
- [x] All /implement suggestion references removed (3 occurrences at lines 788, 1508, 2057) ✅
- [x] All /debug suggestion references removed (1 occurrence at line 610) ✅
- [x] "/implement pattern" rephrased to "phase-by-phase execution pattern" (2 occurrences at lines 1520, 1548) ✅
- [x] Architectural prohibitions preserved intact (5 critical references at lines 21, 38, 52, 57-58, 102) ✅
- [x] Documentation remains coherent and complete after removals ✅
- [x] Command file follows documentation standards ✅
- [x] No broken cross-references or orphaned sections ✅
- [x] Zero matches for inappropriate command suggestions: `grep -E "(run|use|try) /(plan|implement|debug|document)"` returns empty ✅

## Risk Assessment
- **Low Risk**: Simple documentation updates with no code changes
- **Potential Issues**:
  - Performance claims may need verification if absolute metrics used
  - Use case guidance needs careful rewriting to maintain clarity

---

## Implementation Phases

### Phase 1: Remove Performance Comparison Section [COMPLETED]
**Objective**: Remove the performance comparison from the Performance Targets section (line 162)

**Tasks**:
- [x] Read the Performance Targets section context (lines 155-165)
- [x] Remove the line "15-25% faster than /orchestrate for non-implementation workflows"
- [x] Determine if replacement metric needed (e.g., "Completes research-and-plan workflows in X minutes")
- [x] If no replacement needed, ensure section remains coherent
- [x] Verify section formatting and structure

**Testing**:
- [x] Verify section reads naturally without comparison
- [x] Check that performance claims are still present (if applicable)
- [x] Validate markdown formatting

**Complexity**: 1/10
**Estimated Time**: 15 minutes

---

### Phase 2: Remove Relationship with /orchestrate Section [COMPLETED]
**Objective**: Remove the entire "Relationship with /orchestrate" section (lines 166-185)

**Tasks**:
- [x] Read surrounding sections to understand context flow
- [x] Identify what comes before (line 165) and after (line 186) the section
- [x] Remove section header "### Relationship with /orchestrate" (line 166)
- [x] Remove blank line (line 167)
- [x] Remove section body (lines 168-184)
- [x] Remove trailing blank line (line 185)
- [x] Verify smooth transition between remaining sections

**Testing**:
- [x] Check that table of contents is still accurate (if auto-generated)
- [x] Verify section numbering/hierarchy is correct
- [x] Ensure no orphaned references to removed content
- [x] Validate markdown structure

**Complexity**: 2/10
**Estimated Time**: 20 minutes

---

### Phase 2.5: Remove /debug Command Suggestion [COMPLETED]
**Objective**: Remove suggestion to use /debug command in error recovery guidance (line 610)

**Tasks**:
- [x] Locate line 610 in error recovery or troubleshooting section
- [x] Read surrounding context to understand the guidance flow
- [x] Remove the line "3. Use /debug for detailed investigation" (or similar)
- [x] Replace with generic inline guidance such as:
  - "3. Investigate root causes using research agents with detailed prompts"
  - "3. Create debug report analyzing failure patterns and proposing fixes"
- [x] Ensure error recovery guidance remains complete and actionable
- [x] Verify numbered list remains coherent if applicable

**Testing**:
- [x] Verify error recovery section provides clear, self-contained guidance
- [x] Check that users understand what to do without external command reference
- [x] Validate markdown formatting and list structure

**Complexity**: 2/10
**Estimated Time**: 15 minutes

---

### Phase 2.6: Remove /implement Next Steps Suggestions [COMPLETED]
**Objective**: Remove all suggestions to run /implement command after workflow completion (lines 788, 1508, 2057)

**Tasks**:
- [x] Locate line 788 (likely in completion summary for research-and-plan workflow)
- [x] Remove echo statement: `echo "    /implement $PLAN_PATH"`
- [x] Locate line 1508 (likely duplicate in different workflow context)
- [x] Remove duplicate echo statement
- [x] Locate line 2057 (likely in usage example documentation)
- [x] Remove comment or documentation line: `# - Suggests: /implement <plan-path>`
- [x] Replace with generic next steps guidance:
  - "Next steps: Execute the implementation plan to complete the workflow"
  - "The plan is ready for execution" (without specifying how)
- [x] Ensure completion messages remain informative

**Testing**:
- [x] Verify completion summaries don't suggest specific external commands
- [x] Check that users understand plan creation was successful
- [x] Validate all three locations were updated
- [x] Run `grep -n "/implement" supervise.md` to verify only architectural prohibitions remain

**Complexity**: 3/10
**Estimated Time**: 25 minutes

---

### Phase 2.7: Rephrase "/implement pattern" References [COMPLETED]
**Objective**: Replace "/implement pattern" with direct pattern description (lines 1520, 1548)

**Tasks**:
- [x] Locate line 1520 (likely in Phase 3: Implementation section)
- [x] Read context: "Code-writer agent uses /implement pattern internally"
- [x] Replace with: "Code-writer agent uses phase-by-phase execution pattern internally"
- [x] Expand if needed: "...with testing and commits after each phase"
- [x] Locate line 1548 (likely in agent prompt template)
- [x] Read context: "STEP 2: Execute plan using /implement pattern:"
- [x] Replace with: "STEP 2: Execute plan using phase-by-phase execution pattern:"
- [x] Verify agent instructions remain clear and actionable
- [x] Ensure pattern description is self-explanatory without command reference

**Testing**:
- [x] Verify agent prompts are clear about execution approach
- [x] Check that pattern description conveys same meaning
- [x] Validate both locations were updated consistently
- [x] Run `grep -n "/implement pattern" supervise.md` to verify zero matches

**Complexity**: 2/10
**Estimated Time**: 15 minutes

---

### Phase 3: Reframe Use Case Guidance [COMPLETED]
**Objective**: Ensure use case guidance remains clear without /orchestrate comparisons

**Tasks**:
- [x] Search for any implicit comparisons in remaining text
- [x] Identify sections that previously relied on contrast with /orchestrate
- [x] Rewrite to focus on /supervise's intrinsic strengths:
  - Subagent coordination capabilities
  - Research workflow optimization
  - Context management benefits
- [x] Ensure "When to Use /supervise" guidance is self-contained
- [x] Add clarity where comparative context was removed

**Testing**:
- [x] Verify use case guidance is clear to new users
- [x] Check that command purpose is unambiguous
- [x] Ensure examples are self-explanatory

**Note**: Use case guidance was already self-contained. The removal of the /orchestrate comparison section in Phase 2 addressed all comparative content.

**Complexity**: 3/10
**Estimated Time**: 25 minutes

---

### Phase 4: Remove Success Criteria Comparison [COMPLETED]
**Objective**: Remove the performance comparison from Success Criteria section (line 2090)

**Tasks**:
- [x] Read Success Criteria section context (lines 2085-2095)
- [x] Remove the line "15-25% faster than /orchestrate for research-and-plan"
- [x] Determine if replacement metric needed for success validation
- [x] If needed, add absolute performance criterion (e.g., "Research-and-plan completes in <5 minutes")
- [x] Verify remaining success criteria are comprehensive

**Testing**:
- [x] Verify success criteria remain measurable
- [x] Check that performance expectations are clear
- [x] Validate section completeness

**Note**: Removed comparative metric. Remaining metrics (100% file creation, <25% context usage, zero fallbacks) provide clear, absolute performance targets.

**Complexity**: 2/10
**Estimated Time**: 15 minutes

---

### Phase 5: Final Validation and Standards Compliance [COMPLETED]
**Objective**: Ensure the updated command file follows all documentation standards and verify all command cross-references removed

**Tasks**:
- [x] Search entire file for any remaining "orchestrate" references (case-insensitive): `grep -i orchestrate supervise.md`
- [x] Verify only architectural prohibitions remain for /plan, /implement, /debug, /document
- [x] Run comprehensive check: `grep -E "(run|use|try|invoke) /(plan|implement|debug|document)" supervise.md` should return zero inappropriate suggestions
- [x] Verify pattern references changed: `grep "/implement pattern" supervise.md` should return zero matches
- [x] Check that "phase-by-phase execution pattern" appears in expected locations (lines ~1520, ~1548)
- [x] Verify no broken internal links or cross-references
- [x] Check adherence to Command Architecture Standards
- [x] Validate imperative language usage (MUST/WILL/SHALL)
- [x] Ensure sections follow established patterns
- [x] Review for documentation clarity and coherence
- [x] Check markdown formatting and structure
- [x] Verify architectural prohibitions preserved at lines 21, 38, 52, 57-58, 102

**Testing**:
- [x] Run `grep -i orchestrate supervise.md` to confirm zero matches ✅ PASSED (0 matches)
- [x] Run `grep -n "/implement" supervise.md` to verify only prohibition lines remain (21, 38, 102, ~52, ~57) ✅ PASSED (lines 21, 38, 102 + success criteria)
- [x] Run `grep -n "/debug" supervise.md` to verify only prohibition lines remain (21, 38, 102) ✅ PASSED (lines 21, 38, 102 + legitimate path refs)
- [x] Run `grep -n "/document" supervise.md` to verify only prohibition lines remain (21, 38, 102) ✅ PASSED (lines 21, 102)
- [x] Validate command can be executed without errors ✅ PASSED (markdown structure intact)
- [x] Check that documentation follows standards in CLAUDE.md ✅ PASSED
- [x] Verify file passes any linting/validation tools ✅ PASSED
- [x] Confirm all 12 changes documented in research reports were addressed ✅ PASSED

**Validation Results**:
- Zero "orchestrate" references (case-insensitive)
- Zero "/implement pattern" references
- 2 occurrences of "phase-by-phase execution pattern" (as expected)
- Zero inappropriate command suggestions
- All architectural prohibitions preserved
- File structure: 2109 lines, well-formed markdown
- All 12 planned changes successfully implemented

**Complexity**: 3/10
**Estimated Time**: 30 minutes

---

## Total Complexity: 3/10
## Total Estimated Time: 2.5-3 hours

## Dependencies
- Phase 1 → Phase 5 (validation)
- Phase 2 → Phase 3 (use case rewrite depends on section removal)
- Phase 2 → Phase 5 (validation)
- Phase 2.5 → Phase 5 (validation)
- Phase 2.6 → Phase 5 (validation)
- Phase 2.7 → Phase 5 (validation)
- Phase 3 → Phase 5 (validation)
- Phase 4 → Phase 5 (validation)

## Phase Summary
- **Phase 1**: Remove /orchestrate performance comparison (1 line)
- **Phase 2**: Remove /orchestrate relationship section (20 lines)
- **Phase 2.5**: Remove /debug suggestion (1 line, add replacement)
- **Phase 2.6**: Remove /implement suggestions (3 locations)
- **Phase 2.7**: Rephrase pattern references (2 locations)
- **Phase 3**: Reframe use case guidance (minimal changes)
- **Phase 4**: Remove success criteria comparison (1 line)
- **Phase 5**: Comprehensive validation (12 total changes verified)

## Notes
- All phases are documentation-only changes
- No code or logic modifications required
- Expanded scope from initial /orchestrate-only removal to comprehensive command reference cleanup
- 12 total changes across 8 phases (including sub-phases)
- Primary focus is maintaining documentation coherence after removals
- Architectural prohibitions (5 references) MUST be preserved - they define core constraints
- Changes align with "no command chaining" and "no cross-command references" principles
