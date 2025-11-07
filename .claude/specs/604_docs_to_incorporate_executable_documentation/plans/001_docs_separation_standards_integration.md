# Executable/Documentation Separation Standards Integration Plan

## Metadata
- **Date**: 2025-11-07
- **Feature**: Integrate executable/documentation separation pattern into .claude/docs/ standards
- **Scope**: Documentation enhancement and standardization
- **Estimated Phases**: 5
- **Estimated Hours**: 8-10 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 42.0
- **Research Reports**:
  - [Plan 002 Analysis](../reports/001_plan_002_analysis.md)
  - [Docs Structure Analysis](../reports/002_docs_structure_analysis.md)
  - [Integration Requirements](../reports/003_integration_requirements.md)

## Overview

The executable/documentation separation pattern from Plan 002 successfully migrated 7 major commands with 70% average file size reduction and eliminated meta-confusion loops. The pattern is documented in Command Development Guide Section 2.4 with templates and migration checklists, but lacks systematic integration across the documentation system. This plan elevates the pattern to a first-class architectural concept with dedicated pattern document, comprehensive cross-references, and integration with Command Architecture Standards.

**Key Insight**: The pattern is ALREADY IMPLEMENTED and WORKING. This plan focuses on improving DISCOVERABILITY, STANDARDIZATION, and CROSS-REFERENCING across the documentation system.

## Research Summary

### From Plan 002 Analysis Report

**Problem Solved**: Meta-confusion loops where Claude misinterprets documentation as conversational instructions, causing recursive invocation bugs and context bloat (520+ lines before first executable instruction).

**Solution**: Two-file pattern separating lean executable commands (<250 lines) from comprehensive guides (unlimited length). Achieved 70% average reduction across 7 commands (largest: /orchestrate 90% reduction from 5,439 to 557 lines).

**Key Standards**:
- Executable files: Bash blocks, minimal inline comments, phase structure only
- Guide files: Architecture, examples, troubleshooting, design decisions
- Templates: _template-executable-command.md (56 lines), _template-command-guide.md (171 lines)
- Validation: 3-layer script (file size, guide existence, cross-references)

### From Docs Structure Analysis Report

**Current State**: Documentation follows Diataxis framework with 114 files across 8 directories. Executable/documentation separation documented in command-development-guide.md Section 2.4 (lines 213-330) but not in pattern catalog.

**Gap Identified**: Pattern lacks standalone concept document, quick reference decision tree, dedicated troubleshooting guide, and cross-reference from Command Architecture Standards.

**Natural Fit**: Pattern naturally belongs in multiple locations based on Diataxis:
- Primary (exists): guides/command-development-guide.md Section 2.4 (task-oriented)
- Secondary (recommended): concepts/patterns/executable-documentation-separation.md (understanding-oriented)
- Reference (recommended): command_architecture_standards.md cross-reference (information-oriented)
- Quick Reference (recommended): decision tree for content placement

### From Integration Requirements Report

**Documentation Gaps**:
1. Agent Development Guide lacks section on behavioral/usage separation (2,012 lines, no pattern coverage)
2. Command Architecture Standards mentions templates (Standard 4) but not architectural principle
3. CLAUDE.md has minimal reference (line 403 only, not integrated with Code Standards or Development Philosophy)
4. No Standard 14 for executable/documentation separation (Standards 6-10 also missing)
5. Validation script referenced but may lack comprehensive documentation

**Cross-Reference Consistency**: Command Development Guide → Templates (present), CLAUDE.md → Command Development Guide (present), Command Architecture Standards → Section 2.4 (MISSING), Agent Development Guide → Pattern (MISSING).

**Priority Recommendations**: Add Agent Development Guide Section 1.6, create Command Architecture Standard 14, enhance CLAUDE.md integration, create pattern catalog entry.

## Success Criteria

- [ ] Pattern catalog contains executable-documentation-separation.md with complete architecture documentation
- [ ] Command Architecture Standards includes Standard 14 formalizing architectural requirement
- [ ] CLAUDE.md integrates pattern into Code Standards, Development Philosophy, and Quick Reference sections
- [ ] Agent Development Guide includes Section 1.6 for agent behavioral/usage separation
- [ ] Quick reference decision tree created for content placement decisions
- [ ] All cross-references bidirectional and validated (command-development-guide.md ↔ pattern document ↔ standards ↔ CLAUDE.md)
- [ ] Templates have header comments linking to usage guide
- [ ] Validation script documented with usage examples

## Technical Design

### Architecture: Multi-Location Integration Pattern

The executable/documentation separation pattern will be documented in 5 complementary locations following Diataxis framework:

**1. Pattern Catalog** (NEW - Understanding-Oriented)
- File: `.claude/docs/concepts/patterns/executable-documentation-separation.md`
- Purpose: Comprehensive architectural explanation answering WHY pattern exists
- Audience: Developers seeking to understand principles
- Content: Problem statement, solution architecture, case studies, benefits, validation

**2. Command Development Guide** (EXISTS - Task-Oriented)
- File: `.claude/docs/guides/command-development-guide.md` Section 2.4
- Purpose: Practical implementation instructions answering HOW to apply pattern
- Audience: Developers creating or migrating commands
- Content: Migration checklist, templates, file size guidelines, cross-reference conventions

**3. Command Architecture Standards** (NEW STANDARD - Information-Oriented)
- File: `.claude/docs/reference/command_architecture_standards.md` Standard 14
- Purpose: Authoritative requirement specification answering WHAT is required
- Audience: Developers checking compliance requirements
- Content: Formal requirement statement, enforcement criteria, validation methods

**4. Quick Reference** (NEW - Decision-Oriented)
- File: `.claude/docs/quick-reference/executable-vs-guide-content.md`
- Purpose: Fast decision support answering WHERE content belongs
- Audience: Developers needing quick classification guidance
- Content: Decision tree, content type matrix, common edge cases

**5. CLAUDE.md** (ENHANCED - Discovery-Oriented)
- File: `/home/benjamin/.config/CLAUDE.md`
- Purpose: Project-level standards with links to detailed documentation
- Audience: All developers needing entry point to standards
- Content: Pattern summary, template links, cross-references to detailed guides

### Integration Points

**Bidirectional Cross-References**:
```
CLAUDE.md (Code Standards section)
  ↓ references
Pattern Document (concepts/patterns/)
  ↓ references                      ↑ referenced by
Command Development Guide (guides/) → Command Architecture Standards (reference/)
  ↓ references                      ↑ referenced by
Templates (_template-*.md)          Quick Reference (decision tree)
```

**Discovery Paths**:
1. **From CLAUDE.md**: Code Standards → Pattern Document OR Quick Reference
2. **From Command Development**: Section 2.4 → Pattern Document (understanding) OR Quick Reference (decision)
3. **From Standards**: Standard 14 → Pattern Document (rationale) OR Command Development Guide (implementation)
4. **From Templates**: Header comments → Command Development Guide → Pattern Document

### Relationship to Existing Standards

**Standard 12 (Structural vs Behavioral Content Separation)**:
- Focuses on WHAT content (structural templates inline vs behavioral guidelines referenced)
- Complementary to executable/documentation separation (focuses on WHERE content goes)
- Combined decision matrix: Standard 12 determines inline/referenced, executable/documentation determines command/guide

**Standard 11 (Imperative Agent Invocation Pattern)**:
- Both patterns prevent Claude from treating executable content as documentation
- Synergy: Standard 11 ensures invocations obviously executable, executable/documentation ensures commands obviously executable

**Standard 4 (Template Completeness)**:
- Standard 4 requires templates be complete and copy-paste ready
- Executable/documentation separation extends by specifying WHERE complete templates live (executable vs guide)

## Implementation Phases

### Phase 1: Create Pattern Catalog Document
dependencies: []

**Objective**: Establish executable-documentation-separation.md as authoritative pattern document in concepts/patterns/ catalog

**Complexity**: Medium

Tasks:
- [x] Create `.claude/docs/concepts/patterns/executable-documentation-separation.md` following pattern catalog structure
- [x] Document problem statement: meta-confusion loops, recursive invocation bugs, context bloat (520+ lines before execution)
- [x] Document solution architecture: two-file pattern (executable <250 lines, guide unlimited)
- [x] Include case studies section with migration metrics from 7 commands (26-90% reduction)
- [x] Add before/after examples from /coordinate (2,334 → 1,084 lines) and /orchestrate (5,439 → 557 lines)
- [x] Document benefits: meta-confusion elimination (zero incidents), context reduction (70% average), independent evolution
- [x] Include architectural patterns section: AI execution scripts concept, context window optimization, separation of concerns
- [x] Add testing and validation section referencing validate_executable_doc_separation.sh script
- [x] Create cross-references section linking to Command Development Guide 2.4, Standard 14, templates, quick reference
- [x] Add integration with existing patterns section (relationship to Standard 11, Standard 12, Diataxis framework)

Testing:
```bash
# Verify file structure and completeness
test -f .claude/docs/concepts/patterns/executable-documentation-separation.md
grep -q "## Problem Statement" .claude/docs/concepts/patterns/executable-documentation-separation.md
grep -q "## Solution Architecture" .claude/docs/concepts/patterns/executable-documentation-separation.md
grep -q "## Case Studies" .claude/docs/concepts/patterns/executable-documentation-separation.md
grep -q "## Benefits" .claude/docs/concepts/patterns/executable-documentation-separation.md
grep -q "## Testing and Validation" .claude/docs/concepts/patterns/executable-documentation-separation.md
grep -q "## Cross-References" .claude/docs/concepts/patterns/executable-documentation-separation.md
```

**Expected Duration**: 2 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(604): complete Phase 1 - Create pattern catalog document`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

**[COMPLETED]** - Phase 1 finished 2025-11-07

### Phase 2: Add Command Architecture Standard 14
dependencies: [1]

**Objective**: Formalize executable/documentation separation as Standard 14 in command_architecture_standards.md

**Complexity**: Low

Tasks:
- [x] Open `.claude/docs/reference/command_architecture_standards.md` and locate insertion point after Standard 13 (around line 1476)
- [x] Add Standard 14 heading and requirement statement: "Commands MUST separate executable logic from comprehensive documentation"
- [x] Document two-file pattern: executable command (<250 lines) + command guide (unlimited)
- [x] Specify file paths: .claude/commands/command-name.md and .claude/docs/guides/command-name-command-guide.md
- [x] Add rationale section: eliminates meta-confusion loops, prevents recursive invocation bugs, enables independent documentation growth
- [x] Document enforcement criteria: commands >250 lines MUST extract documentation, guides MUST be cross-referenced from CLAUDE.md
- [x] Add validation section referencing .claude/tests/validate_executable_doc_separation.sh script
- [x] Create See Also section with cross-references: Command Development Guide Section 2.4, executable template, guide template, pattern document
- [x] Update Table of Contents in command_architecture_standards.md to include Standard 14 (no TOC exists in file)
- [x] Add backward reference from Standard 12 (Structural vs Behavioral) noting complementary relationship with Standard 14

Testing:
```bash
# Verify Standard 14 exists and is properly structured
grep -q "### Standard 14: Executable/Documentation File Separation" .claude/docs/reference/command_architecture_standards.md
grep -q "Commands MUST separate executable logic" .claude/docs/reference/command_architecture_standards.md
grep -q "See Also" .claude/docs/reference/command_architecture_standards.md
```

**Expected Duration**: 1 hour

**Phase 2 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(604): complete Phase 2 - Add Standard 14`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

**[COMPLETED]** - Phase 2 finished 2025-11-07

### Phase 3: Enhance CLAUDE.md Integration
dependencies: [1, 2]

**Objective**: Integrate executable/documentation separation into CLAUDE.md Code Standards, Development Philosophy, and Quick Reference sections

**Complexity**: Medium

Tasks:
- [x] Add "Architectural Separation" subsection to Code Standards section (after line 145 in CLAUDE.md)
- [x] Document executable/documentation separation principle: commands/agents separate execution from documentation, executables <250 lines, guides unlimited
- [x] Add cross-references to Command Development Guide Section 2.4 and templates (_template-executable-command.md, _template-command-guide.md)
- [x] Update Development Philosophy section (lines 147-171) to connect pattern with "clean, coherent systems" and "present-focused documentation" values
- [x] Add architectural principles bullet: "Clean separation between executable logic and documentation" with fail-fast execution and independent documentation growth
- [x] Expand Quick Reference section (after line 445) with Command Development subsection
- [x] Add template links: "New Command: Start with _template-executable-command.md" and "Command Guide: Use _template-command-guide.md"
- [x] Add pattern guide link: Command Development Guide Section 2.4 for complete separation pattern details
- [x] Update existing Command Documentation Pattern reference (line 398-403) to reference new pattern document in concepts/patterns/
- [x] Add validation note: Reference validate_executable_doc_separation.sh in Testing Protocols section

Testing:
```bash
# Verify CLAUDE.md enhancements
grep -q "Architectural Separation" /home/benjamin/.config/CLAUDE.md
grep -q "executable/documentation separation" /home/benjamin/.config/CLAUDE.md
grep -q "_template-executable-command.md" /home/benjamin/.config/CLAUDE.md
grep -q "Command Development Guide - Section 2.4" /home/benjamin/.config/CLAUDE.md
grep -q "Clean separation between executable logic" /home/benjamin/.config/CLAUDE.md
```

**Expected Duration**: 1.5 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 3 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(604): complete Phase 3 - Enhance CLAUDE.md integration`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

**[COMPLETED]** - Phase 3 finished 2025-11-07

### Phase 4: Create Quick Reference Decision Tree and Agent Guide Section
dependencies: [1, 2, 3]

**Objective**: Add quick reference decision tree for content placement and extend pattern to agent development

**Complexity**: High

Tasks:
- [x] Create `.claude/docs/quick-reference/executable-vs-guide-content.md` with decision tree structure
- [x] Document decision tree: "Should this content be in executable or guide?" with branches for bash blocks, imperative instructions, architecture explanations, troubleshooting, examples, design rationale
- [x] Add content type matrix: Bash blocks (executable), Phase markers (executable), Minimal comments (executable), Architecture (guide), Troubleshooting (guide), Examples (guide), Design decisions (guide), Cross-references (both)
- [x] Include edge cases section: Large inline templates (keep in executable with HEREDOC), Agent invocation templates (inline per Standard 11), Complex bash with extensive comments (extract explanation to guide)
- [x] Add quick validation checklist: File size <250 lines (executable), Guide exists and referenced (both), Cross-references bidirectional (both)
- [x] Open `.claude/docs/guides/agent-development-guide.md` and add Section 1.6 after line 752 (after Section 1.5 "Creating a New Agent")
- [x] Document Section 1.6 "Agent Behavioral/Usage Separation Pattern" following structure parallel to Command Development Guide Section 2.4
- [x] Add problem statement: Agent files mixing behavioral guidelines with usage examples (research-specialist.md: 671 lines with ~200 lines extractable)
- [x] Document solution architecture: Agent behavioral file (<400 lines) + agent usage guide (unlimited), similar to command pattern but threshold adjusted for agent complexity
- [x] Create "When to Split" section: Agent file >400 lines, extensive usage examples (>100 lines), multiple invocation patterns documented
- [x] Note template requirements: _template-agent-behavioral.md and _template-agent-usage-guide.md (to be created in future work)
- [x] Add cross-references: Link to executable/documentation separation pattern document, Command Development Guide Section 2.4, Standard 14

Testing:
```bash
# Verify quick reference decision tree
test -f .claude/docs/quick-reference/executable-vs-guide-content.md
grep -q "decision tree" .claude/docs/quick-reference/executable-vs-guide-content.md
grep -q "content type matrix" .claude/docs/quick-reference/executable-vs-guide-content.md

# Verify agent guide section
grep -q "### 1.6 Agent Behavioral/Usage Separation Pattern" .claude/docs/guides/agent-development-guide.md
grep -q "400 lines" .claude/docs/guides/agent-development-guide.md
grep -q "research-specialist" .claude/docs/guides/agent-development-guide.md
```

**Expected Duration**: 2.5 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 4 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(604): complete Phase 4 - Quick reference and agent guide`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

**[COMPLETED]** - Phase 4 finished 2025-11-07

### Phase 5: Update Cross-References and Validation
dependencies: [1, 2, 3, 4]

**Objective**: Establish bidirectional cross-references across all documentation and validate completeness

**Complexity**: Low

Tasks:
- [x] Update `.claude/docs/concepts/patterns/README.md` pattern catalog to include executable-documentation-separation.md in list with brief description
- [x] Add cross-reference from behavioral-injection.md pattern to executable-documentation-separation.md (complementary patterns)
- [x] Add cross-reference from verification-fallback.md pattern to executable-documentation-separation.md (both support execution reliability)
- [x] Update Command Development Guide Section 2.4 to reference new pattern document in concepts/patterns/ (add link after line 226)
- [x] Add template header comments to _template-executable-command.md and _template-command-guide.md linking to Command Development Guide Section 2.4
- [x] Update .claude/docs/README.md to reference executable-documentation-separation pattern in "Key Patterns" section
- [x] Verify bidirectional cross-references: pattern document → Command Development Guide (check), Command Development Guide → pattern document (check), Standard 14 → pattern document (check), pattern document → Standard 14 (check), CLAUDE.md → pattern document (check), quick reference → pattern document (check)
- [x] Run validation: Check all cross-reference links are valid absolute or relative paths
- [x] Verify validate_executable_doc_separation.sh script exists and document usage in Command Development Guide Section 2.4 (expand lines 297-300)
- [x] Add validation script usage example: Basic validation (all commands), specific command validation, expected output format
- [x] Update Table of Contents in affected files: patterns/README.md, command-development-guide.md, agent-development-guide.md, CLAUDE.md if TOC exists

Testing:
```bash
# Verify pattern catalog updated
grep -q "executable-documentation-separation" .claude/docs/concepts/patterns/README.md

# Verify all bidirectional cross-references
grep -q "concepts/patterns/executable-documentation-separation.md" .claude/docs/guides/command-development-guide.md
grep -q "command-development-guide.md" .claude/docs/concepts/patterns/executable-documentation-separation.md
grep -q "Standard 14" .claude/docs/concepts/patterns/executable-documentation-separation.md
grep -q "executable-documentation-separation" .claude/docs/reference/command_architecture_standards.md

# Verify validation script documented
grep -q "validate_executable_doc_separation.sh" .claude/docs/guides/command-development-guide.md
test -x .claude/tests/validate_executable_doc_separation.sh || echo "Validation script does not exist or is not executable"
```

**Expected Duration**: 1.5 hours

**Phase 5 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(604): complete Phase 5 - Cross-references and validation`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

**[COMPLETED]** - Phase 5 finished 2025-11-07

**PLAN COMPLETE** - All 5 phases finished successfully

## Testing Strategy

### Unit Testing (Per Phase)

Each phase includes inline test commands verifying:
- File creation (test -f)
- Section presence (grep -q)
- Cross-reference validity (grep pattern matching)
- File permissions where applicable (test -x)

### Integration Testing (After Phase 5)

**Cross-Reference Validation**:
```bash
# Test all cross-references are valid
.claude/tests/validate_cross_references.sh .claude/docs/

# Expected output: All cross-references valid (0 broken links)
```

**Pattern Consistency Validation**:
```bash
# Verify terminology consistency
grep -r "executable/documentation separation" .claude/docs/ | wc -l
# Expected: 10+ references across pattern document, standards, guides, CLAUDE.md

# Verify file path consistency
grep -r ".claude/commands/\*\.md" .claude/docs/ | wc -l
grep -r ".claude/docs/guides/\*-command-guide\.md" .claude/docs/ | wc -l
# Expected: Consistent path patterns in all references
```

**Validation Script Testing**:
```bash
# Test validation script on all commands
.claude/tests/validate_executable_doc_separation.sh

# Expected output:
# ✓ coordinate.md: 1,084 lines (acceptable for complex orchestrator)
# ✓ Guide exists: .claude/docs/guides/coordinate-command-guide.md
# ✓ Cross-references valid
# ... (similar for all 7 commands)
```

### Documentation Quality Testing

**Diataxis Compliance**:
- Pattern document in concepts/patterns/ (understanding-oriented) ✓
- Command Development Guide in guides/ (task-oriented) ✓
- Standard 14 in reference/ (information-oriented) ✓
- Quick reference in quick-reference/ (decision-oriented) ✓

**Completeness Checklist**:
- [ ] Pattern document has all required sections (Problem, Solution, Case Studies, Benefits, Testing, Cross-References)
- [ ] Standard 14 has requirement statement, rationale, enforcement, validation, See Also
- [ ] CLAUDE.md integration covers Code Standards, Development Philosophy, Quick Reference
- [ ] Agent Development Guide Section 1.6 parallels Command Development Guide Section 2.4 structure
- [ ] Quick reference decision tree covers all common content types
- [ ] All cross-references bidirectional and valid

### Regression Testing

**Verify Existing Documentation Unaffected**:
```bash
# Check existing command guides still reference executables correctly
for guide in .claude/docs/guides/*-command-guide.md; do
  grep -q "Executable:" "$guide" || echo "Missing executable reference in $guide"
done

# Check existing executables still reference guides correctly
for cmd in .claude/commands/*.md; do
  grep -q "Documentation:" "$cmd" || echo "Missing guide reference in $cmd"
done
```

**Verify No Broken Links Introduced**:
```bash
# Scan for broken markdown links
.claude/tests/check_markdown_links.sh .claude/docs/
# Expected: 0 broken links
```

## Documentation Requirements

### Files to Create

1. **Pattern Catalog Document** (NEW)
   - Path: `.claude/docs/concepts/patterns/executable-documentation-separation.md`
   - Purpose: Comprehensive architectural explanation of pattern
   - Sections: Problem Statement, Solution Architecture, Case Studies, Benefits, Architectural Patterns, Testing and Validation, Cross-References
   - Length: ~800-1000 lines (similar to behavioral-injection.md: 1,024 lines)

2. **Quick Reference Decision Tree** (NEW)
   - Path: `.claude/docs/quick-reference/executable-vs-guide-content.md`
   - Purpose: Fast content placement decision support
   - Sections: Decision Tree, Content Type Matrix, Edge Cases, Quick Validation Checklist
   - Length: ~150-200 lines (concise, actionable)

3. **Standard 14** (NEW)
   - Path: `.claude/docs/reference/command_architecture_standards.md` (addition)
   - Location: After Standard 13 (around line 1476)
   - Purpose: Formal architectural requirement
   - Sections: Requirement, Two-File Pattern, Rationale, Enforcement, Validation, See Also
   - Length: ~80-100 lines

### Files to Update

1. **CLAUDE.md** (ENHANCED)
   - Path: `/home/benjamin/.config/CLAUDE.md`
   - Changes: Add Architectural Separation subsection (Code Standards), update Development Philosophy, expand Quick Reference
   - Lines affected: ~30-40 lines added across 3 sections

2. **Command Development Guide** (ENHANCED)
   - Path: `.claude/docs/guides/command-development-guide.md`
   - Changes: Add cross-reference to pattern document (after line 226), enhance validation script documentation (lines 297-300)
   - Lines affected: ~10-15 lines added

3. **Agent Development Guide** (ENHANCED)
   - Path: `.claude/docs/guides/agent-development-guide.md`
   - Changes: Add Section 1.6 "Agent Behavioral/Usage Separation Pattern" after line 752
   - Lines affected: ~100-120 lines added (parallel structure to Command Development Guide Section 2.4)

4. **Pattern Catalog README** (ENHANCED)
   - Path: `.claude/docs/concepts/patterns/README.md`
   - Changes: Add executable-documentation-separation.md to catalog list with brief description
   - Lines affected: ~3-5 lines added

5. **Templates** (ENHANCED)
   - Paths: `.claude/docs/guides/_template-executable-command.md` and `_template-command-guide.md`
   - Changes: Add header comments linking to Command Development Guide Section 2.4
   - Lines affected: ~2-3 lines added per template

6. **Documentation README** (ENHANCED)
   - Path: `.claude/docs/README.md`
   - Changes: Add executable-documentation-separation to Key Patterns section
   - Lines affected: ~2-3 lines added

### Cross-Reference Documentation

All cross-references must be bidirectional and follow these conventions:

**In Executable Files**:
```markdown
**Documentation**: See `.claude/docs/guides/command-name-command-guide.md`
```

**In Guide Files**:
```markdown
**Executable**: `.claude/commands/command-name.md`
```

**In Pattern Documents**:
```markdown
**See Also**:
- [Command Development Guide - Section 2.4](../../guides/command-development-guide.md#24-executabledocumentation-separation-pattern)
- [Command Architecture Standards - Standard 14](../../reference/command_architecture_standards.md#standard-14)
- [Executable Template](../../guides/_template-executable-command.md)
```

**In Standards Documents**:
```markdown
**See Also**:
- [Executable/Documentation Separation Pattern](../../concepts/patterns/executable-documentation-separation.md)
- [Command Development Guide - Section 2.4](../../guides/command-development-guide.md#24-executabledocumentation-separation-pattern)
```

## Dependencies

### Internal Dependencies (Phase-to-Phase)

- Phase 2 depends on Phase 1: Standard 14 references pattern document, must exist first
- Phase 3 depends on Phases 1 and 2: CLAUDE.md references both pattern document and Standard 14
- Phase 4 depends on Phases 1-3: Quick reference and agent guide reference pattern document, Standard 14, and CLAUDE.md sections
- Phase 5 depends on Phases 1-4: Cross-reference validation requires all documentation artifacts exist

### External Dependencies

- **Existing Documentation**: Command Development Guide Section 2.4 (already exists), templates (already exist), validation script (may need documentation enhancement)
- **Existing Standards**: Command Architecture Standards document (Standards 0-13 already exist)
- **Diataxis Framework**: Documentation structure follows established Diataxis organization
- **Git Clean State**: No conflicting changes in documentation files

### Resource Dependencies

- **Read Tool**: Required for examining existing documentation structure and content
- **Write Tool**: Required for creating new files (pattern document, quick reference, Standard 14)
- **Edit Tool**: Required for updating existing files (CLAUDE.md, guides, pattern catalog)
- **Grep Tool**: Required for validation and cross-reference checking
- **Bash Tool**: Required for running validation scripts and tests

## Risk Assessment

### Low Risk Areas

- **Pattern Already Proven**: Pattern successfully applied to 7 commands with zero meta-confusion incidents in testing
- **Templates Exist**: Both executable and guide templates already created and validated
- **Documentation Structure Established**: Diataxis framework provides clear organization guidelines
- **Validation Tooling**: Script exists (or easily created) to enforce pattern compliance

### Medium Risk Areas

- **Cross-Reference Maintenance**: Multiple bidirectional links increase risk of broken references over time
  - **Mitigation**: Automated validation script checks all cross-references, run in CI/CD
- **Documentation Consistency**: Pattern documented in 5 locations requires consistent terminology
  - **Mitigation**: Single source of truth in pattern document, other locations reference it
- **Agent Template Creation**: Recommendation for agent templates (_template-agent-behavioral.md, _template-agent-usage-guide.md) noted but not created in this plan
  - **Mitigation**: Document requirement in Agent Development Guide Section 1.6, defer template creation to future work

### High Risk Areas

- **Standard Numbering Gap**: Standards 6-10 missing, Standard 14 added creates potential confusion
  - **Mitigation**: Document gap in Command Architecture Standards, note Standards 6-10 reserved for future use OR investigate historical reason and document
- **Agent Pattern Adoption**: No existing agent guides to serve as examples (unlike 7 command guides)
  - **Mitigation**: Agent Development Guide Section 1.6 provides clear guidelines, research-specialist.md identified as migration candidate (671 lines with ~200 extractable)

## Notes

### Key Design Decisions

1. **Multi-Location Documentation**: Pattern documented in 5 locations (pattern catalog, command guide, standards, quick reference, CLAUDE.md) following Diataxis framework ensures discoverability by different user needs (understanding, implementing, checking compliance, making decisions, discovering)

2. **Agent Pattern Extension**: Extending pattern to agents addresses same root cause (meta-confusion from mixed behavioral/usage content) with adjusted threshold (400 lines vs 250 lines for commands due to agent complexity)

3. **Standard 14 Numbering**: Preserving existing Standard 11-13 numbering (despite Standards 6-10 gap) avoids breaking existing cross-references throughout documentation

4. **Bidirectional Cross-References**: All documentation locations reference each other to support non-linear navigation and discovery from any entry point

### Future Work

- Create agent behavioral and usage guide templates (_template-agent-behavioral.md, _template-agent-usage-guide.md)
- Migrate research-specialist.md (671 lines) as proof-of-concept for agent pattern
- Investigate and document Standards 6-10 gap (historical reason or intentional reservation)
- Consider CI/CD integration for validate_executable_doc_separation.sh (automated enforcement)
- Expand quick reference with more edge cases as patterns emerge

### Success Metrics

- **Discoverability**: Users can find pattern documentation from 5+ entry points (CLAUDE.md, command guide, standards, pattern catalog, quick reference)
- **Consistency**: Pattern terminology ("executable/documentation separation") used consistently across all 5 locations
- **Completeness**: All 6 required sections present in pattern document (Problem, Solution, Case Studies, Benefits, Testing, Cross-References)
- **Cross-Reference Integrity**: 100% of cross-references valid and bidirectional (validated by automated script)
- **Template Adoption**: New commands reference templates in header comments
- **Validation Coverage**: Automated script checks file size, guide existence, and cross-references for all commands
