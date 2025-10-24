# Add Report References to Research Overview Implementation Plan

## Metadata
- **Date**: 2025-10-24
- **Feature**: Add cross-references to subtopic reports in OVERVIEW.md
- **Scope**: Minimal refactor of /research command and research-synthesizer agent
- **Estimated Phases**: 2
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: None (direct code analysis)

## Overview

The `/research` command successfully creates individual subtopic reports and an OVERVIEW.md file through the research-synthesizer agent. However, the OVERVIEW.md currently lacks explicit references to the subtopic reports at the top of the document and throughout relevant sections.

This plan implements a minimal refactor to enhance the OVERVIEW.md structure by:
1. Adding a "Research Structure" section at the top listing all subtopic reports with links
2. Ensuring report references are included throughout the synthesis where relevant
3. Maintaining the existing architecture and execution flow

## Success Criteria
- [ ] OVERVIEW.md includes "Research Structure" section with links to all subtopic reports at the top
- [ ] Each detailed findings section references the corresponding subtopic report
- [ ] Relative paths are used for all report links
- [ ] No changes to /research command execution flow or agent invocation pattern
- [ ] Existing OVERVIEW.md files demonstrate the new structure

## Technical Design

### Current Implementation Analysis

**research-synthesizer.md** (lines 58-98):
- STEP 2 defines the overview report structure with 6 mandatory sections
- Section 3 ("Detailed Findings by Topic") already includes report links: `[Full Report]({relative_path})`
- Section 6 ("Individual Report References") provides table/list of all reports
- The structure is sound but needs better placement and prominence

**Gaps Identified**:
1. No explicit "Research Structure" section before Executive Summary
2. Individual Report References section is at the end (line 93-96) - should be near top
3. No explicit instruction to reference reports throughout synthesis where relevant

### Proposed Changes

**Minimal refactor approach**:
1. Reorder existing Section 6 ("Individual Report References") to position 2 (after Executive Summary)
2. Rename to "Research Structure" for clarity
3. Add explicit instruction to include report references in Section 2 ("Cross-Report Findings")
4. No changes to /research command or agent invocation

## Implementation Phases

### Phase 1: Update research-synthesizer Agent Structure [COMPLETED]
**Objective**: Modify the overview report structure in research-synthesizer.md to include prominent report references
**Complexity**: Low
**Files Modified**:
- `.claude/agents/research-synthesizer.md`

Tasks:
- [x] Read research-synthesizer.md to confirm current structure (lines 58-98)
- [x] Update STEP 2 structure to reorder sections:
  - Section 1: Executive Summary (3-5 sentences) - unchanged
  - Section 2: Research Structure (NEW POSITION - moved from Section 6)
    - List all subtopic reports with relative links
    - Brief description of each report's focus
    - Format: `1. **[Topic Name](./NNN_topic_name.md)** - Brief description`
  - Section 3: Cross-Report Findings - add instruction to reference specific reports
  - Section 4: Detailed Findings by Topic - unchanged (already has report links)
  - Section 5: Recommended Approach - unchanged
  - Section 6: Constraints and Trade-offs - unchanged
- [x] Update cross-reference requirements (lines 201-209) to emphasize relative paths
- [x] Add example of Research Structure section format in STEP 2

Testing:
```bash
# Verify syntax and structure
cat .claude/agents/research-synthesizer.md | grep -A 10 "Research Structure"

# Check that all section numbers are updated correctly
grep -n "^[0-9]\." .claude/agents/research-synthesizer.md
```

**Expected Outcome**: research-synthesizer.md has updated structure with Research Structure as Section 2

### Phase 2: Verify with Test Invocation
**Objective**: Test the updated research-synthesizer agent with existing subtopic reports to ensure proper structure
**Complexity**: Low
**Files Modified**: None (testing only)

Tasks:
- [ ] Identify an existing research subdirectory with subtopic reports for testing
- [ ] Create a test script that invokes the research-synthesizer agent with existing reports:
  - Use `.claude/specs/076_orchestrate_supervise_comparison/reports/001_research/` as test data
  - Back up existing OVERVIEW.md
  - Invoke research-synthesizer with updated behavioral guidelines
  - Compare generated OVERVIEW.md structure with expected format
- [ ] Verify Research Structure section appears after Executive Summary
- [ ] Verify relative links to subtopic reports are correct
- [ ] Verify Cross-Report Findings references specific reports where relevant
- [ ] Restore original OVERVIEW.md after testing

Testing:
```bash
# Test script (manual invocation via Claude Code)
cd .claude/specs/076_orchestrate_supervise_comparison/reports/001_research

# Backup existing overview
cp OVERVIEW.md OVERVIEW.md.backup

# Invoke /research command with same topic to regenerate
# (or manually test research-synthesizer agent with existing subtopic reports)

# Verify structure
head -100 OVERVIEW.md | grep -A 20 "Research Structure"

# Verify relative links
grep -o '\[.*\](\.\/[0-9].*\.md)' OVERVIEW.md

# Restore backup
mv OVERVIEW.md.backup OVERVIEW.md
```

**Expected Outcome**: Generated OVERVIEW.md includes Research Structure section with working relative links to subtopic reports

## Testing Strategy

### Unit Testing
- Syntax validation of research-synthesizer.md structure
- Section numbering verification (1-6 in correct order)
- Cross-reference instruction completeness

### Integration Testing
- Full `/research` command invocation with test topic
- Verify research-synthesizer agent creates OVERVIEW.md with new structure
- Verify relative links work (no broken references)
- Verify backward compatibility (existing /research invocations still work)

### Validation Testing
- Compare generated OVERVIEW.md against existing examples
- Verify Research Structure section provides clear navigation
- Confirm report references enhance synthesis readability

## Documentation Requirements

### Files to Update
1. `.claude/agents/research-synthesizer.md` - Update STEP 2 structure and examples
2. No changes to `/research` command documentation (behavior unchanged)
3. No changes to directory protocols (structure unchanged)

### Documentation Changes
- Add example of Research Structure section format in research-synthesizer.md
- Update section numbering in examples (Section 6 → Section 2 for references)
- Clarify relative path usage in cross-reference requirements

## Dependencies

### Prerequisites
- Existing /research command infrastructure (no changes)
- research-synthesizer agent behavioral guidelines (modification only)
- Unified location detection library (no changes)

### External Dependencies
- None (self-contained refactor)

## Notes

### Design Decisions
1. **Minimal refactor approach**: Reorder existing sections rather than add new functionality
2. **Backward compatibility**: No changes to /research command or agent invocation patterns
3. **User experience focus**: Improve OVERVIEW.md readability by surfacing report links earlier

### Alternative Approaches Considered
1. **Add report TOC at very top** - Rejected: Too prominent, overshadows Executive Summary
2. **Inline report links in Executive Summary** - Rejected: Clutters summary with navigation
3. **Current approach (Research Structure after Executive Summary)** - Selected: Balances prominence with readability

### Implementation Constraints
- Must maintain compatibility with spec-updater agent's cross-reference logic
- Must preserve existing STEP 2 structure (6 sections) - only reorder, not add/remove
- Must use relative paths (spec-updater requirement for portability)

### Post-Implementation Validation
After implementing this plan:
1. Run `/research` command with new topic to test end-to-end
2. Verify OVERVIEW.md structure matches new format
3. Check existing research commands (if any invocations in progress) complete successfully
4. Update `.claude/templates/report-structure.md` if needed to reflect new OVERVIEW.md format
