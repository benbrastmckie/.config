# Implementation Plan: Remove Command Cross-References from /supervise

## Metadata
- **Plan ID**: 001_remove_orchestrate_references
- **Topic**: 078_supervise_orchestrate_ref_removal
- **Created**: 2025-10-23
- **Updated**: 2025-10-23 (expanded scope to all command references)
- **Status**: draft
- **Complexity**: Medium-Low
- **Estimated Time**: 2-3 hours

## Objective
Remove inappropriate command cross-references from the /supervise command documentation while preserving essential architectural prohibitions. This includes removing /orchestrate comparisons, /implement suggestions, and /debug recommendations to achieve full compliance with the "no command chaining" principle. The /supervise command should stand independently without suggesting other commands.

## Research References
- `/home/benjamin/.config/.claude/specs/078_supervise_orchestrate_ref_removal/reports/001_orchestrate_references.md` - Initial /orchestrate reference analysis
- `/home/benjamin/.config/.claude/specs/078_supervise_orchestrate_ref_removal/reports/002_all_command_references.md` - Comprehensive command reference audit

## Success Criteria
- [ ] All /orchestrate comparison references removed (5 occurrences)
- [ ] All /implement suggestion references removed (3 occurrences at lines 788, 1508, 2057)
- [ ] All /debug suggestion references removed (1 occurrence at line 610)
- [ ] "/implement pattern" rephrased to "phase-by-phase execution pattern" (2 occurrences at lines 1520, 1548)
- [ ] Architectural prohibitions preserved intact (5 critical references at lines 21, 38, 52, 57-58, 102)
- [ ] Documentation remains coherent and complete after removals
- [ ] Command file follows documentation standards
- [ ] No broken cross-references or orphaned sections
- [ ] Zero matches for inappropriate command suggestions: `grep -E "(run|use|try) /(plan|implement|debug|document)"` returns empty

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

### Phase 3: Reframe Use Case Guidance
**Objective**: Ensure use case guidance remains clear without /orchestrate comparisons

**Tasks**:
- [ ] Search for any implicit comparisons in remaining text
- [ ] Identify sections that previously relied on contrast with /orchestrate
- [ ] Rewrite to focus on /supervise's intrinsic strengths:
  - Subagent coordination capabilities
  - Research workflow optimization
  - Context management benefits
- [ ] Ensure "When to Use /supervise" guidance is self-contained
- [ ] Add clarity where comparative context was removed

**Testing**:
- [ ] Verify use case guidance is clear to new users
- [ ] Check that command purpose is unambiguous
- [ ] Ensure examples are self-explanatory

**Complexity**: 3/10
**Estimated Time**: 25 minutes

---

### Phase 4: Remove Success Criteria Comparison
**Objective**: Remove the performance comparison from Success Criteria section (line 2090)

**Tasks**:
- [ ] Read Success Criteria section context (lines 2085-2095)
- [ ] Remove the line "15-25% faster than /orchestrate for research-and-plan"
- [ ] Determine if replacement metric needed for success validation
- [ ] If needed, add absolute performance criterion (e.g., "Research-and-plan completes in <5 minutes")
- [ ] Verify remaining success criteria are comprehensive

**Testing**:
- [ ] Verify success criteria remain measurable
- [ ] Check that performance expectations are clear
- [ ] Validate section completeness

**Complexity**: 2/10
**Estimated Time**: 15 minutes

---

### Phase 5: Final Validation and Standards Compliance
**Objective**: Ensure the updated command file follows all documentation standards and verify all command cross-references removed

**Tasks**:
- [ ] Search entire file for any remaining "orchestrate" references (case-insensitive): `grep -i orchestrate supervise.md`
- [ ] Verify only architectural prohibitions remain for /plan, /implement, /debug, /document
- [ ] Run comprehensive check: `grep -E "(run|use|try|invoke) /(plan|implement|debug|document)" supervise.md` should return zero inappropriate suggestions
- [ ] Verify pattern references changed: `grep "/implement pattern" supervise.md` should return zero matches
- [ ] Check that "phase-by-phase execution pattern" appears in expected locations (lines ~1520, ~1548)
- [ ] Verify no broken internal links or cross-references
- [ ] Check adherence to Command Architecture Standards
- [ ] Validate imperative language usage (MUST/WILL/SHALL)
- [ ] Ensure sections follow established patterns
- [ ] Review for documentation clarity and coherence
- [ ] Check markdown formatting and structure
- [ ] Verify architectural prohibitions preserved at lines 21, 38, 52, 57-58, 102

**Testing**:
- [ ] Run `grep -i orchestrate supervise.md` to confirm zero matches
- [ ] Run `grep -n "/implement" supervise.md` to verify only prohibition lines remain (21, 38, 102, ~52, ~57)
- [ ] Run `grep -n "/debug" supervise.md` to verify only prohibition lines remain (21, 38, 102)
- [ ] Run `grep -n "/document" supervise.md` to verify only prohibition lines remain (21, 38, 102)
- [ ] Validate command can be executed without errors
- [ ] Check that documentation follows standards in CLAUDE.md
- [ ] Verify file passes any linting/validation tools
- [ ] Confirm all 12 changes documented in research reports were addressed

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
