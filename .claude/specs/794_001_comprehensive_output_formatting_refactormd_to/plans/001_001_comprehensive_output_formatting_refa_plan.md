# Documentation Standards Update Implementation Plan

## Metadata
- **Date**: 2025-11-18
- **Feature**: Update .claude/docs/ standards to enforce clean and concise output formatting approach
- **Scope**: Documentation standards update across 8 files plus 1 new reference document
- **Estimated Phases**: 5
- **Estimated Hours**: 8-10
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 49.5
- **Research Reports**:
  - [Documentation Standards Update Research](../reports/001_documentation_standards_update.md)

## Overview

This plan updates the .claude/docs/ standards documentation to enforce the clean and concise commenting and output formatting approach established in the output formatting refactor plan (spec 778). The update standardizes:

1. **Output suppression patterns** - `2>/dev/null` for library sourcing, single summary lines
2. **Block consolidation patterns** - Reduce commands from 6-11 blocks to 2-3 blocks
3. **WHAT not WHY comment enforcement** - Clear examples and anti-patterns
4. **Error visibility preservation** - Suppress success output while keeping errors visible

The research report identified 8 existing files requiring updates and recommends creating one new comprehensive reference document to consolidate these standards.

## Research Summary

Key findings from the documentation standards update research report:

**Existing "WHAT not WHY" Standard**:
- Already defined in code-standards.md:36 and executable-documentation-separation.md:71
- Current gap: lacks specific enforcement patterns and examples

**Missing Standards Identified**:
- Output suppression pattern (`2>/dev/null`, debug logs) not documented
- Block consolidation pattern (6 blocks to 2-3) not standardized
- Library sourcing templates use verbose patterns inconsistent with goals

**Files Requiring Updates** (from research):
1. code-standards.md - Add output suppression and block consolidation standards
2. command-authoring-standards.md - Add output suppression section
3. bash-block-execution-model.md - Add block consolidation pattern
4. _template-bash-block.md - Update library sourcing patterns
5. logging-patterns.md - Add output suppression guidance
6. executable-documentation-separation.md - Add output formatting benefits
7. command-development-fundamentals.md - Add block consolidation guidance
8. Create new output-formatting-standards.md reference document

**Potential Conflict**: error-enhancement-guide.md promotes verbose errors. Resolution: output suppression applies only to success/progress output, not errors.

## Success Criteria
- [ ] All 8 identified files updated with consistent output formatting standards
- [ ] New output-formatting-standards.md reference document created
- [ ] CLAUDE.md updated with new section referencing output formatting standards
- [ ] All templates updated to use suppressed library sourcing pattern
- [ ] WHAT not WHY comment standard has enforcement examples
- [ ] Block consolidation pattern documented with clear structure
- [ ] Output vs error distinction explicitly clarified
- [ ] All internal links validated and working
- [ ] No conflicting guidance between updated documents

## Technical Design

### Standards Architecture

The update introduces a layered documentation structure:

```
CLAUDE.md (index)
└── <!-- SECTION: output_formatting -->
    └── Reference: output-formatting-standards.md (comprehensive)
        ├── Output Suppression Patterns
        ├── Block Consolidation Patterns
        └── Comment Standards

Supporting Documents (updated):
├── code-standards.md (add output suppression subsection)
├── command-authoring-standards.md (add suppression patterns)
├── bash-block-execution-model.md (add Pattern 8: Block Minimization)
├── _template-bash-block.md (update library sourcing)
├── logging-patterns.md (add output vs error distinction)
├── executable-documentation-separation.md (add formatting benefits)
└── command-development-fundamentals.md (add block structure guidance)
```

### Key Pattern Definitions

**Output Suppression Pattern**:
```bash
# Suppress library sourcing
source "${LIB_DIR}/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Library not found" >&2
  exit 1
}

# Single summary line per block
echo "Setup complete: $WORKFLOW_ID"
```

**Block Consolidation Pattern**:
```
Block 1: Setup (capture, validate, source, init, allocate)
Block 2: Execute (main workflow logic)
Block 3: Cleanup (verify, complete, summary)
```

**WHAT Not WHY Comment Enforcement**:
```bash
# WHAT (correct)
source lib.sh  # Load state management functions

# WHY (incorrect - belongs in guide)
# We source this because subprocess isolation requires re-sourcing...
```

### Integration Points

- References from CLAUDE.md to new output-formatting-standards.md
- Cross-references between updated documents
- Alignment with existing error-enhancement-guide.md (errors remain verbose)
- Compatibility with existing state-persistence.sh documentation

## Implementation Phases

### Phase 1: Create Core Reference Document [COMPLETE]
dependencies: []

**Objective**: Create comprehensive output-formatting-standards.md as the canonical reference for all output formatting standards.

**Complexity**: Medium
**Estimated Duration**: 2-3 hours

Tasks:
- [x] Create `/home/benjamin/.config/.claude/docs/reference/output-formatting-standards.md`
- [x] Add metadata and table of contents
- [x] Add Core Principles section with 5 principles
- [x] Add Output Suppression Patterns section with:
  - Library sourcing pattern
  - Directory operations pattern
  - Single summary line pattern
  - Debug log pattern
- [x] Add Block Consolidation Patterns section with:
  - Target block count (2-3)
  - Block structure definitions
  - Consolidation rules
  - Before/after example
- [x] Add Comment Standards section with:
  - WHAT not WHY enforcement examples
  - Correct and incorrect patterns
  - Reference to guides for WHY content
- [x] Add Output vs Error Distinction section
- [x] Add Related Documentation section with links
- [x] Validate all internal links

Testing:
```bash
# Verify file created
test -f /home/benjamin/.config/.claude/docs/reference/output-formatting-standards.md || echo "FAIL"

# Check file size (should be comprehensive)
wc -c < /home/benjamin/.config/.claude/docs/reference/output-formatting-standards.md

# Validate links
.claude/scripts/validate-links-quick.sh
```

---

### Phase 2: Update Primary Standards Files [COMPLETE]
dependencies: [1]

**Objective**: Update code-standards.md and command-authoring-standards.md with output suppression patterns.

**Complexity**: Medium
**Estimated Duration**: 2 hours

Tasks:
- [x] Update `/home/benjamin/.config/.claude/docs/reference/code-standards.md`:
  - Add "### Output Suppression Patterns" subsection under "Command and Agent Architecture Standards"
  - Include library sourcing, directory operations, summary line, and debug log patterns
  - Add rationale explaining Claude Code display behavior
- [x] Update `/home/benjamin/.config/.claude/docs/reference/command-authoring-standards.md`:
  - Add new section "## Output Suppression Requirements"
  - Include output suppression as mandatory pattern
  - Add examples using existing working command patterns
  - Cross-reference output-formatting-standards.md for comprehensive documentation
- [x] Add WHAT not WHY enforcement examples to code-standards.md:
  - Correct comment examples
  - Incorrect comment examples (belongs in guide)
  - Reference to executable-documentation-separation.md
- [x] Ensure consistent formatting with existing document styles
- [x] Verify no conflicting guidance introduced

Testing:
```bash
# Check for new sections
grep -l "Output Suppression" .claude/docs/reference/code-standards.md
grep -l "Output Suppression" .claude/docs/reference/command-authoring-standards.md

# Validate internal links
.claude/scripts/validate-links-quick.sh .claude/docs/reference/
```

---

### Phase 3: Update Execution Model and Templates [COMPLETE]
dependencies: [1]

**Objective**: Add block consolidation pattern to bash-block-execution-model.md and update templates to use suppressed patterns.

**Complexity**: Medium
**Estimated Duration**: 2 hours

Tasks:
- [x] Update `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md`:
  - Add "### Pattern 8: Block Count Minimization" section
  - Include problem statement (display noise from multiple blocks)
  - Define target block count (2-3 per command)
  - Document block structure (Setup/Execute/Cleanup)
  - Add consolidation rules
  - Include comprehensive example
  - Document benefits (50-67% reduction)
- [x] Update `/home/benjamin/.config/.claude/docs/guides/_template-bash-block.md`:
  - Update library sourcing pattern (lines 32-44) to use `2>/dev/null`
  - Add error handling with stderr output
  - Add single summary line example
  - Update any verbose patterns to suppressed versions
- [x] Verify pattern consistency between documents
- [x] Add cross-references to output-formatting-standards.md

Testing:
```bash
# Check for new pattern
grep -l "Pattern 8" .claude/docs/concepts/bash-block-execution-model.md
grep "2>/dev/null" .claude/docs/guides/_template-bash-block.md

# Validate links
.claude/scripts/validate-links-quick.sh
```

---

### Phase 4: Update Supporting Documentation [COMPLETE]
dependencies: [2, 3]

**Objective**: Update logging-patterns.md, executable-documentation-separation.md, and command-development-fundamentals.md with output formatting guidance.

**Complexity**: Medium
**Estimated Duration**: 2 hours

Tasks:
- [x] Update `/home/benjamin/.config/.claude/docs/guides/logging-patterns.md`:
  - Add "### Output vs Error Distinction" section
  - Document what to suppress (success, progress chatter, intermediate state)
  - Document what to preserve (errors, warnings, completion summaries)
  - Include pattern examples with stderr/stdout distinction
  - Cross-reference error-enhancement-guide.md for error standards
- [x] Update `/home/benjamin/.config/.claude/docs/concepts/patterns/executable-documentation-separation.md`:
  - Add output formatting to pattern benefits
  - Note that lean executables use suppression patterns
  - Reference output-formatting-standards.md for complete patterns
- [x] Update or create section in command development fundamentals:
  - Locate appropriate file (command-development-fundamentals.md or guide)
  - Add "### Block Structure Optimization" subsection
  - Document 2-3 block target
  - Explain Setup/Execute/Cleanup structure
  - Include rationale for display optimization
- [x] Ensure no conflicting guidance with error-enhancement-guide.md
- [x] Verify consistent terminology across all updated documents

Testing:
```bash
# Verify sections added
grep -l "Output vs Error" .claude/docs/guides/logging-patterns.md
grep -l "Block Structure" .claude/docs/guides/command-development-guide.md

# Full link validation
.claude/scripts/validate-links.sh
```

---

### Phase 5: Update CLAUDE.md Index and Final Validation [COMPLETE]
dependencies: [4]

**Objective**: Add output formatting section to CLAUDE.md and perform final validation of all updates.

**Complexity**: Low
**Estimated Duration**: 1 hour

Tasks:
- [x] Update `/home/benjamin/.config/CLAUDE.md`:
  - Add new section between existing sections (after code_standards is logical)
  - Use proper section markers: `<!-- SECTION: output_formatting -->`
  - Include [Used by: ...] metadata
  - Reference output-formatting-standards.md
  - Close with `<!-- END_SECTION: output_formatting -->`
- [x] Update `.claude/docs/reference/README.md` with new output-formatting-standards.md entry
- [x] Run full link validation across all updated files
- [x] Verify no broken internal links
- [x] Check for consistent formatting and style
- [x] Review all cross-references for accuracy
- [x] Verify WHAT not WHY examples are clear and actionable

Testing:
```bash
# Verify CLAUDE.md section
grep -A 5 "SECTION: output_formatting" /home/benjamin/.config/CLAUDE.md

# Full validation suite
.claude/scripts/validate-links.sh

# Check all modified files exist and have content
for f in \
  .claude/docs/reference/output-formatting-standards.md \
  .claude/docs/reference/code-standards.md \
  .claude/docs/reference/command-authoring-standards.md \
  .claude/docs/concepts/bash-block-execution-model.md \
  .claude/docs/guides/_template-bash-block.md \
  .claude/docs/guides/logging-patterns.md; do
  test -f "/home/benjamin/.config/$f" && echo "OK: $f" || echo "MISSING: $f"
done
```

---

## Testing Strategy

### Overall Approach

1. **File Existence Verification**: Confirm all new/updated files exist
2. **Content Validation**: Check required sections present in each file
3. **Link Validation**: Use project validation scripts for internal links
4. **Consistency Review**: Ensure no conflicting guidance across documents
5. **Manual Review**: Read through updated sections for clarity

### Test Commands

```bash
# Link validation (quick)
.claude/scripts/validate-links-quick.sh

# Full link validation
.claude/scripts/validate-links.sh

# Check new file exists
test -f /home/benjamin/.config/.claude/docs/reference/output-formatting-standards.md

# Verify CLAUDE.md update
grep "output_formatting" /home/benjamin/.config/CLAUDE.md

# Check all files for new patterns
grep -l "2>/dev/null" .claude/docs/reference/*.md .claude/docs/guides/*.md
```

### Success Metrics

- All 8 files successfully updated
- New output-formatting-standards.md created with comprehensive content
- CLAUDE.md includes output_formatting section
- Zero broken internal links
- No conflicting guidance between documents
- Pattern examples are clear and copy-paste ready

## Documentation Requirements

- [ ] Update .claude/docs/reference/README.md with new output-formatting-standards.md entry
- [ ] Ensure all cross-references between updated documents are valid
- [ ] Verify CLAUDE.md section markers follow established format
- [ ] Confirm examples use consistent formatting (code blocks, indentation)

## Dependencies

### External Dependencies
- Existing .claude/scripts/validate-links.sh validation script
- Project CLAUDE.md section marker format

### Prerequisites
- Research report reviewed and findings validated
- Existing documents accessible and readable
- Understanding of output formatting refactor plan patterns

### Phase Dependencies for Wave-Based Execution

```
Wave 1: Phase 1 (create core reference document)
Wave 2: Phases 2, 3 (parallel - update primary standards and execution model)
Wave 3: Phase 4 (update supporting documentation - requires 2, 3 for consistency)
Wave 4: Phase 5 (final validation - requires all prior phases)
```

**Time Savings**: Phases 2 and 3 can run in parallel after Phase 1 completes (25% time savings for Wave 2).

## Risks and Mitigations

### Risk 1: Conflicting Guidance with Error Enhancement Standards
**Mitigation**: Explicitly document that output suppression applies to success output only. Errors remain verbose per error-enhancement-guide.md.

### Risk 2: Breaking Existing Working Templates
**Mitigation**: Update templates incrementally. Test each change for correctness before proceeding.

### Risk 3: Incomplete Cross-References
**Mitigation**: Run full link validation after each phase. Fix broken links immediately.

### Risk 4: Inconsistent Terminology
**Mitigation**: Use exact terms from research report (output suppression, block consolidation, WHAT not WHY). Review all documents for terminology consistency.

## Notes

**Scope Limitation**: This plan updates documentation standards only. The actual implementation of output suppression and block consolidation in workflow commands is covered by the output formatting refactor plan (spec 778, plan 001).

**Future Consideration**: After these standards are established, existing commands should be audited for compliance. This audit is outside the scope of this documentation update plan.

**Style Consistency**: All new content follows existing document styles in .claude/docs/. Use same heading levels, formatting patterns, and link conventions as surrounding content.
