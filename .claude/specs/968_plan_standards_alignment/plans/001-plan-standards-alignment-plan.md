# Plan Standards Alignment Implementation Plan

## Metadata
- **Date**: 2025-11-29
- **Feature**: Standards-aware plan creation
- **Scope**: Integrate CLAUDE.md standards extraction and validation into /plan command workflow
- **Estimated Phases**: 5
- **Estimated Hours**: 10
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 42.5
- **Research Reports**:
  - [Plan Standards Integration Research](/home/benjamin/.config/.claude/specs/968_plan_standards_alignment/reports/001-plan-standards-integration-research.md)

## Overview

The /plan command currently lacks integration with CLAUDE.md standards, creating a gap where plan-architect agent cannot validate that generated plans align with project conventions. This implementation adds standards extraction, prompt enhancement, and divergence detection capabilities to ensure all plans either comply with established standards or explicitly propose standards revisions through a Phase 0 mechanism.

## Research Summary

Research identified three critical integration points:
- **Standards Extraction**: CLAUDE.md uses `<!-- SECTION: name -->` markers enabling programmatic extraction of planning-relevant sections (code_standards, testing_protocols, documentation_policy, error_logging, clean_break_development)
- **Agent Enhancement**: Plan-architect already has standards compliance completion criteria (lines 977-983) but lacks actual standards content to validate against
- **Divergence Handling**: Well-motivated divergence from standards should be supported via Phase 0 (standards revision) rather than blocked, with explicit user warnings

Recommended approach: Create reusable standards extraction library, enhance plan-architect prompt with standards content, add divergence detection protocol, and implement user warning system for standards-changing plans.

## Success Criteria

- [ ] Plan-architect receives relevant CLAUDE.md standards sections in prompt
- [ ] Plans demonstrate alignment with code standards, testing protocols, and documentation policy
- [ ] Plans proposing standards divergence include Phase 0 for standards revision
- [ ] Users receive warnings when plans propose standards changes
- [ ] Standards extraction utility is reusable by other commands (/revise, /implement, /debug)
- [ ] All existing /plan tests continue passing
- [ ] Documentation covers standards integration pattern for future command development

## Technical Design

### Architecture Overview

```
/plan command workflow:
┌─────────────────────────────────────────────────────────────┐
│ Block 1: Setup and topic initialization (existing)         │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Block 1d: Research invocation (existing)                    │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Block 2: Standards extraction (NEW)                         │
│  1. Source standards-extraction.sh library                  │
│  2. Extract planning-relevant sections from CLAUDE.md       │
│  3. Format standards content for prompt injection           │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Block 2 (Task): Plan-architect invocation (ENHANCED)        │
│  - Original context (feature, reports, paths)               │
│  - NEW: Extracted standards content                         │
│  - NEW: Divergence detection instructions                   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Block 3: Plan verification (ENHANCED)                       │
│  1. Verify plan file created (existing)                     │
│  2. NEW: Detect Phase 0 (standards revision)                │
│  3. NEW: Add divergence warning to console summary          │
└─────────────────────────────────────────────────────────────┘
```

### Component Design

**1. Standards Extraction Library** (`.claude/lib/plan/standards-extraction.sh`):
- `extract_claude_section(section_name)`: Extract single named section using awk
- `extract_planning_standards()`: Extract all planning-relevant sections (code_standards, testing_protocols, documentation_policy, error_logging, clean_break_development, directory_organization)
- `format_standards_for_prompt()`: Format extracted sections for agent prompt injection
- Follows three-tier sourcing pattern with fail-fast handler

**2. Plan-Architect Behavioral Enhancement** (`.claude/agents/plan-architect.md`):
- Add "Standards Integration" subsection to STEP 1 (Requirements Analysis)
- Add "Standards Divergence Protocol" section defining Phase 0 generation criteria
- Add Phase 0 template for standards revision proposals
- Update completion criteria to validate against provided standards content (not just path)
- Add divergence metadata field specification

**3. /plan Command Enhancement** (`.claude/commands/plan.md`):
- Block 2 enhancement: Source standards-extraction.sh and extract standards before plan-architect Task
- Task prompt enhancement: Inject standards content and divergence instructions
- Block 3 enhancement: Detect Phase 0 and add user warning

**4. Plan Metadata Extension**:
- Add `- **Standards Divergence**: true|false` field
- Add `- **Divergence Justification**: [text]` field (if divergent)

### Standards Section Selection Rationale

Planning-relevant sections from CLAUDE.md:
- **code_standards**: Informs Technical Design phase requirements
- **testing_protocols**: Shapes Testing Strategy section
- **documentation_policy**: Guides Documentation Requirements
- **error_logging**: Ensures error handling integration in phases
- **clean_break_development**: Influences refactoring approach for enhancement plans
- **directory_organization**: Validates file placement in tasks

Excluded sections (not planning-relevant):
- **adaptive_planning_config**: Internal /plan configuration
- **state_based_orchestration**: /build implementation detail
- **skills_architecture**: Model invocation, not plan design

## Implementation Phases

### Phase 1: Standards Extraction Library [NOT STARTED]
dependencies: []

**Objective**: Create reusable library for extracting CLAUDE.md standards sections

**Complexity**: Low

**Tasks**:
- [ ] Create `.claude/lib/plan/standards-extraction.sh` with three-tier sourcing pattern
- [ ] Implement `extract_claude_section(section_name)` using awk to parse `<!-- SECTION: name -->` markers
- [ ] Implement `extract_planning_standards()` to extract all 6 planning-relevant sections (code_standards, testing_protocols, documentation_policy, error_logging, clean_break_development, directory_organization)
- [ ] Implement `format_standards_for_prompt()` to format sections for agent prompt injection with markdown headers
- [ ] Add error handling for missing CLAUDE.md or missing sections (graceful degradation)
- [ ] Add library documentation header with usage examples

**Testing**:
```bash
# Test section extraction
source .claude/lib/plan/standards-extraction.sh
EXTRACTED=$(extract_claude_section "code_standards")
echo "$EXTRACTED" | grep -q "Bash Sourcing" # Verify content present

# Test all planning standards extraction
STANDARDS=$(extract_planning_standards)
echo "$STANDARDS" | grep -q "code_standards" # Verify all 6 sections
echo "$STANDARDS" | grep -q "testing_protocols"
echo "$STANDARDS" | grep -q "documentation_policy"

# Test formatting for prompt
FORMATTED=$(format_standards_for_prompt)
echo "$FORMATTED" | grep -q "### Code Standards" # Verify markdown headers
```

**Expected Duration**: 2 hours

### Phase 2: Plan-Architect Behavioral Enhancement [NOT STARTED]
dependencies: []

**Objective**: Update plan-architect agent to consume and validate against provided standards

**Complexity**: Medium

**Tasks**:
- [ ] Add "Standards Integration" subsection to STEP 1 (after line 75 in plan-architect.md)
  - Document that standards content will be provided in prompt under "**Project Standards**" heading
  - Instruct agent to parse standards sections and reference during plan creation
  - Update requirements analysis to include standards validation
- [ ] Add "Standards Divergence Protocol" section (after line 906 in plan-architect.md)
  - Define three divergence levels: Minor (document only), Moderate (justify in design), Major (Phase 0 required)
  - Provide Phase 0 template with required sections (Objective, Divergence, Justification, Tasks, User Warning)
  - Specify metadata fields for divergent plans (Standards Divergence: true, Divergence Justification)
- [ ] Update completion criteria "Standards Compliance" section (lines 977-983)
  - Change from "CLAUDE.md standards file path captured" to "Standards content validated"
  - Add divergence detection criteria: "If divergent, Phase 0 included with justification"
  - Add metadata validation: "Divergence metadata fields present if Phase 0 exists"
- [ ] Add example Phase 0 to "Plan Templates" section showing standards revision format

**Testing**:
```bash
# Verify behavioral file updated correctly
grep -q "Standards Integration" .claude/agents/plan-architect.md
grep -q "Standards Divergence Protocol" .claude/agents/plan-architect.md
grep -q "Phase 0: Standards Revision" .claude/agents/plan-architect.md

# Integration test: Run /plan with standards and verify plan compliance
# (This will be tested in Phase 4 integration testing)
```

**Expected Duration**: 2 hours

### Phase 3: /plan Command Enhancement [NOT STARTED]
dependencies: [1]

**Objective**: Integrate standards extraction into /plan command workflow

**Complexity**: Medium

**Tasks**:
- [ ] Update Block 2 (before plan-architect Task invocation, after line 656 in plan.md)
  - Source standards-extraction.sh library with fail-fast handler
  - Call `extract_planning_standards()` and store result in `PLANNING_STANDARDS` variable
  - Call `format_standards_for_prompt()` and store result in `FORMATTED_STANDARDS` variable
  - Add error handling for extraction failures (log error, continue with warning)
- [ ] Enhance plan-architect Task prompt (lines 938-960)
  - Add "**Project Standards**" section after "**Workflow-Specific Context**"
  - Inject `${FORMATTED_STANDARDS}` content
  - Add divergence detection instructions: "If approach diverges from standards for well-motivated reasons, include Phase 0 to revise standards with clear justification and user warning"
- [ ] Update Block 3 plan verification (after line 1087)
  - Add Phase 0 detection: `grep -q "^### Phase 0: Standards Revision" "$PLAN_PATH"`
  - If detected, extract divergence justification and add to console summary
  - Add warning to console output: "⚠️  This plan proposes changes to project standards (see Phase 0)"
- [ ] Update console summary template to include divergence warning section (if applicable)

**Testing**:
```bash
# Test standards extraction integration
# Run /plan and verify standards passed to plan-architect
# (Verified via plan-architect output containing standards-aligned content)

# Test divergence detection
# Create test plan with Phase 0 manually, verify warning displayed

# Test graceful degradation
# Temporarily rename CLAUDE.md, verify /plan continues with warning
```

**Expected Duration**: 2.5 hours

### Phase 4: Integration Testing and Validation [NOT STARTED]
dependencies: [2, 3]

**Objective**: Validate end-to-end standards integration with real /plan invocations

**Complexity**: Medium

**Tasks**:
- [ ] Test Case 1: Standards-compliant plan
  - Run `/plan "Add user authentication with JWT"` (should align with existing code_standards)
  - Verify plan includes standards-aligned Technical Design (bash sourcing, error logging)
  - Verify plan includes standards-aligned Testing Strategy (test commands from testing_protocols)
  - Verify no Phase 0 generated (compliant plan)
- [ ] Test Case 2: Divergent plan triggering Phase 0
  - Run `/plan "Refactor to TypeScript configuration system"` (diverges from Lua/Bash standards)
  - Verify plan includes Phase 0 with divergence justification
  - Verify metadata includes `Standards Divergence: true`
  - Verify console output includes warning
- [ ] Test Case 3: Missing CLAUDE.md graceful degradation
  - Temporarily move CLAUDE.md, run /plan
  - Verify warning logged to error log
  - Verify plan still created (degraded mode)
  - Restore CLAUDE.md
- [ ] Verify existing /plan tests still pass (regression testing)
- [ ] Add new test cases to `.claude/tests/test_plan_command.sh` (if test file exists)

**Testing**:
```bash
# Run integration tests
bash .claude/tests/test_plan_command.sh # If exists

# Manual validation with real workflows
/plan "Simple feature aligned with standards"
/plan "Complex refactoring requiring standards update"
```

**Expected Duration**: 2 hours

### Phase 5: Documentation and Pattern Guide [NOT STARTED]
dependencies: [4]

**Objective**: Document standards integration pattern for reuse by other commands

**Complexity**: Low

**Tasks**:
- [ ] Create `.claude/docs/guides/patterns/standards-integration.md`
  - Document standards extraction utilities (extract_claude_section, extract_planning_standards, format_standards_for_prompt)
  - Document agent prompt enhancement pattern (how to inject standards content)
  - Document divergence detection protocol (Phase 0 generation criteria)
  - Document user warning mechanism (console output, metadata fields)
  - Include code examples for each integration point
- [ ] Update `.claude/docs/guides/commands/plan-command-guide.md`
  - Add "Standards Integration" section explaining how /plan uses CLAUDE.md
  - Document Phase 0 behavior for divergent plans
  - Add example workflows (compliant plan vs divergent plan)
- [ ] Update plan-architect.md documentation header
  - Reference new standards integration capabilities
  - Link to standards-integration.md pattern guide
- [ ] Add standards-extraction.sh to library documentation index (if exists)

**Testing**:
```bash
# Verify documentation created
test -f .claude/docs/guides/patterns/standards-integration.md

# Verify documentation follows documentation_policy standards
grep -q "## Overview" .claude/docs/guides/patterns/standards-integration.md
grep -q "## Usage" .claude/docs/guides/patterns/standards-integration.md

# Verify links valid
bash .claude/scripts/validate-links-quick.sh .claude/docs/guides/patterns/standards-integration.md
```

**Expected Duration**: 1.5 hours

## Testing Strategy

### Unit Testing
- Test standards-extraction.sh functions independently (extract_claude_section, extract_planning_standards, format_standards_for_prompt)
- Test edge cases: missing CLAUDE.md, missing sections, malformed section markers
- Test awk pattern matching for section extraction accuracy

### Integration Testing
- Test /plan command with standards extraction enabled
- Test plan-architect receiving and using standards content
- Test Phase 0 generation for divergent plans
- Test graceful degradation when CLAUDE.md unavailable

### Regression Testing
- Run existing /plan test suite (if exists)
- Verify existing plans can still be created
- Verify /revise command compatibility (uses plan-architect)

### Validation Testing
- Verify generated plans reference standards in Technical Design
- Verify generated plans include test commands from testing_protocols
- Verify generated plans follow documentation_policy
- Verify divergent plans include proper Phase 0 with justification

### Performance Testing
- Measure standards extraction overhead (<100ms acceptable)
- Verify no impact on plan-architect agent response time

## Documentation Requirements

### New Documentation
- `.claude/docs/guides/patterns/standards-integration.md` - Comprehensive pattern guide (created in Phase 5)
- `.claude/lib/plan/standards-extraction.sh` - Library documentation header with usage examples (created in Phase 1)

### Documentation Updates
- `.claude/docs/guides/commands/plan-command-guide.md` - Add standards integration section (Phase 5)
- `.claude/agents/plan-architect.md` - Add standards integration and divergence protocol sections (Phase 2)
- `.claude/commands/plan.md` - Inline comments explaining standards extraction blocks (Phase 3)

### README Updates
- `.claude/lib/plan/README.md` - Add standards-extraction.sh to module documentation
- `.claude/docs/guides/patterns/README.md` - Add standards-integration.md to index

## Dependencies

### External Dependencies
- CLAUDE.md must exist with section markers (standard project requirement)
- Awk utility (standard on all Unix systems)

### Internal Dependencies
- `.claude/lib/core/error-handling.sh` - For error logging in standards-extraction.sh
- `.claude/lib/plan/topic-utils.sh` - Already sourced by /plan (no changes needed)
- Plan-architect agent model (opus-4.1 or sonnet-4.5 fallback)

### Workflow Dependencies
- Phase 1 must complete before Phase 3 (library needed by command)
- Phases 2 and 3 can proceed in parallel (independent enhancements)
- Phase 4 requires Phases 2 and 3 complete (integration testing needs both)
- Phase 5 requires Phase 4 complete (documentation validates implementation)

## Risk Mitigation

### Risk 1: Standards extraction parsing errors
**Mitigation**: Implement robust error handling with graceful degradation. If extraction fails, log error and continue without standards (preserve existing /plan behavior).

### Risk 2: Plan-architect ignoring provided standards
**Mitigation**: Update completion criteria to require standards validation. Add explicit instructions in divergence protocol. Include standards reference requirement in plan template.

### Risk 3: Users ignoring Phase 0 warnings
**Mitigation**: Make warnings prominent in console output. Add Phase 0 flag to metadata for buffer-opener hook highlighting. Document Phase 0 review requirement in plan-command-guide.md.

### Risk 4: Standards extraction performance overhead
**Mitigation**: Extraction is simple awk operation on single file (<100ms). If slow, cache extracted standards in Block 2 variable for reuse.

### Risk 5: Divergence detection too aggressive
**Mitigation**: Use three-tier divergence levels (Minor/Moderate/Major). Only require Phase 0 for Major divergences. Document examples of each tier in divergence protocol.

## Notes

- Standards extraction library is designed for reusability by /revise, /implement, and /debug commands
- Phase 0 mechanism supports controlled standards evolution (not rigid enforcement)
- User transparency is critical - all standards changes must be explicit and justified
- Graceful degradation ensures /plan remains functional even if CLAUDE.md unavailable
- This implementation aligns with clean-break development standard (no compatibility wrappers, direct integration)
