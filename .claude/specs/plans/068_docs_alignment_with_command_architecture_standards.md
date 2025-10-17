# Documentation Alignment with Command Architecture Standards

## Metadata
- **Date**: 2025-10-17
- **Feature**: Align .claude/docs/ files with command_architecture_standards.md
- **Scope**: Update 32 documentation files to follow 11 architectural standards
- **Estimated Phases**: 5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: Based on 4 parallel research agents analyzing docs compliance

## Overview

This refactor updates all documentation in `.claude/docs/` to align with the comprehensive command architecture standards established in `command_architecture_standards.md`. The standards define how command and agent files should be structured as "AI execution scripts" rather than traditional code, emphasizing inline execution requirements, context preservation, and lean design principles.

**Key Challenges**:
1. Many docs promote extraction patterns without distinguishing execution-critical (inline) vs supplemental (extractable) content
2. Context preservation standards (6-8) are missing from most documentation
3. Lean command design principles (9-11) are not documented in guides
4. Agent invocation examples use anti-patterns (inline behavioral guidelines instead of behavioral injection)

**Approach**:
- Phase-by-phase updates by documentation category
- Add cross-references to command_architecture_standards.md
- Integrate context preservation patterns and utilities
- Clarify inline-first principles without over-extracting

## Success Criteria
- [ ] All 32 docs files reviewed and updated for standards alignment
- [ ] Context preservation standards (6-8) documented in relevant guides
- [ ] Lean command design principles (9-11) integrated where applicable
- [ ] Agent invocation examples use behavioral injection pattern
- [ ] Cross-references to command_architecture_standards.md added throughout
- [ ] No documentation promotes over-extraction of execution-critical content
- [ ] Testing checklist validates inline completeness requirements

## Technical Design

### Architectural Principles

**11 Standards Coverage**:
1. **Standard 1**: Executable Instructions Must Be Inline - Emphasize in all command documentation
2. **Standard 2**: Reference Pattern - Show "inline first, reference after" examples
3. **Standard 3**: Critical Information Density - Document minimum density requirements
4. **Standard 4**: Template Completeness - Require copy-paste ready templates
5. **Standard 5**: Structural Annotations - Add annotation examples to guides
6. **Standard 6**: Metadata-Only Passing - Document utilities and patterns
7. **Standard 7**: Forward Message Pattern - Show no-paraphrase handoffs
8. **Standard 8**: Context Pruning - Document pruning utilities and policies
9. **Standard 9**: Commands Orchestrate Patterns - Clarify extraction boundaries
10. **Standard 10**: DRY Principle for Commands - Show procedure extraction examples
11. **Standard 11**: Target Command Sizes - Document size thresholds and warnings

### Documentation Categories

**Category 1: Agent Documentation** (4 files)
- agent-reference.md
- creating-agents.md
- using-agents.md
- hierarchical_agents.md

**Category 2: Command Documentation** (4 files)
- command-patterns.md
- command-reference.md
- command-examples.md
- creating-commands.md

**Category 3: Workflow/Guide Documentation** (6 files)
- development-workflow.md (compliant - minimal changes)
- development-philosophy.md (compliant - minimal changes)
- orchestration-guide.md
- adaptive-planning-guide.md (compliant - minimal changes)
- efficiency-guide.md (compliant - minimal changes)
- setup-command-guide.md

**Category 4: Technical/Spec Documentation** (7 files)
- directory-protocols.md
- spec_updater_guide.md
- artifact_organization.md
- topic_based_organization.md
- phase_dependencies.md (compliant - no changes needed)
- logging-patterns.md
- error-enhancement-guide.md (compliant - no changes needed)

**Category 5: Miscellaneous Documentation** (11 files)
- README.md
- claude-md-section-schema.md
- command-reference.md (duplicate - covered in Category 2)
- conversion-guide.md
- standards-integration.md
- timeless_writing_guide.md
- tts-integration-guide.md
- archive/* (5 files - no changes needed)

### Integration Strategy

**Cross-Reference Pattern**:
```markdown
**Note**: For command-specific architectural guidance, see [Command Architecture Standards](command_architecture_standards.md).
```

**Context Preservation Section Template**:
```markdown
## Context Preservation in [Workflow Type]

Following Standards 6-8 from command_architecture_standards.md:

### Metadata-Only Passing (Standard 6)
[Examples of extract_report_metadata() usage]

### Forward Message Pattern (Standard 7)
[Examples of no-paraphrase handoffs]

### Context Pruning (Standard 8)
[Examples of pruning utilities]
```

**Agent Invocation Update Pattern**:
```markdown
<!-- BEFORE (anti-pattern): -->
Task {
  prompt: |
    You are a research specialist.
    [Full behavioral guidelines inline...]
}

<!-- AFTER (correct pattern): -->
Task {
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    [Operational context only...]
}
```

## Implementation Phases

### Phase 1: Update Agent Documentation (Category 1)
**Objective**: Fix agent invocation anti-patterns and add context preservation guidance
**Complexity**: Medium
**Files**: 4 files

Tasks:
- [ ] Update agent-reference.md:
  - Replace inline invocation template (lines 310-338) with behavioral injection pattern
  - Add "Context Preservation Requirements" section covering Standards 6-8
  - Add cross-reference to command_architecture_standards.md in introduction
  - Reduce template duplication (Standard 10 compliance)
  - File: .claude/docs/agent-reference.md

- [ ] Update creating-agents.md:
  - Add "Agent Output Requirements" section explaining metadata extraction compatibility
  - Update tool combination examples (lines 64-75) to explain inline requirement rationale
  - Add structural annotation examples (Standard 5) to agent file template
  - Add cross-reference to command_architecture_standards.md#agent-file-standards
  - File: .claude/docs/creating-agents.md

- [ ] Update using-agents.md:
  - Replace 50+ line inline agent prompt templates (lines 585-612, 450-530) with behavioral injection references
  - Add "Context-Efficient Agent Integration" section with Standards 6-8 examples
  - Update integration patterns (lines 126-282) to reference bash-patterns.md for procedures
  - Add metadata extraction examples after agent invocation patterns
  - File: .claude/docs/using-agents.md

- [ ] Update hierarchical_agents.md:
  - Add cross-references to command_architecture_standards.md for Standards 1, 6-8
  - Link forward message pattern (lines 223-259) to forward_message() utility (Standard 7)
  - Update command integration examples (lines 498-576) to show executable patterns vs narrative
  - Add note on extraction boundaries (procedures extractable, workflow logic inline)
  - File: .claude/docs/hierarchical_agents.md

Testing:
```bash
# Verify behavioral injection pattern appears in updated docs
grep -n "Read and follow.*agents/" .claude/docs/agent-reference.md .claude/docs/using-agents.md

# Verify context preservation standards referenced
grep -n "Standard [6-8]" .claude/docs/agent-reference.md .claude/docs/using-agents.md .claude/docs/hierarchical_agents.md

# Verify cross-references to command_architecture_standards.md
grep -n "command_architecture_standards.md" .claude/docs/agent-reference.md .claude/docs/creating-agents.md .claude/docs/using-agents.md .claude/docs/hierarchical_agents.md
```

Expected: All greps return matches, confirming updates applied

---

### Phase 2: Update Command Documentation (Category 2)
**Objective**: Clarify inline-first principles and add lean design guidance
**Complexity**: High
**Files**: 4 files

Tasks:
- [ ] Update command-patterns.md:
  - Add "Extraction Boundaries" section clarifying procedures (extractable) vs execution logic (inline)
  - Update extraction guidance (lines 1298-1309) to distinguish Standard 9 vs Standard 1 content
  - Add "Context Preservation Patterns" section with Standards 6-8 examples
  - Add behavioral injection pattern to agent invocation examples
  - Add cross-reference to command_architecture_standards.md in introduction
  - File: .claude/docs/command-patterns.md

- [ ] Update command-reference.md:
  - Add "Architectural Context" section linking to command_architecture_standards.md
  - Add note emphasizing commands are "AI execution scripts" not just "workflow automation"
  - Add reference to Standards 1-11 summary with link
  - Keep reference format minimal (no major structural changes)
  - File: .claude/docs/command-reference.md

- [ ] Update command-examples.md:
  - Add "Context Preservation Examples" section with Standards 6-8 patterns
  - Add metadata-only passing example (Standard 6)
  - Add forward message pattern example (Standard 7)
  - Add context pruning example (Standard 8)
  - Add note clarifying examples are supplemental reference material
  - File: .claude/docs/command-examples.md

- [ ] Update creating-commands.md:
  - Add "Inline Execution Requirements" subsection to development workflow (Section 3.3)
  - Add "File Size Guidelines" section with Standard 11 targets and warnings
  - Add "Context Preservation" section covering Standards 6-8
  - Update standards integration template (lines 502-556) to include inline requirement checks
  - Add structural annotation examples (Standard 5) to command file template
  - Update testing section (lines 875-1016) to validate inline completeness
  - Add cross-reference to command_architecture_standards.md in multiple sections
  - File: .claude/docs/creating-commands.md

Testing:
```bash
# Verify inline-first principle documented
grep -n "inline.*first\|Inline Execution Requirements" .claude/docs/creating-commands.md .claude/docs/command-patterns.md

# Verify extraction boundaries clarified
grep -n "procedures.*extractable\|execution logic.*inline" .claude/docs/command-patterns.md

# Verify file size guidelines added
grep -n "Target.*Size\|size.*threshold\|Standard 11" .claude/docs/creating-commands.md

# Verify context preservation sections added
grep -n "Context Preservation\|Standard [6-8]" .claude/docs/command-patterns.md .claude/docs/command-examples.md .claude/docs/creating-commands.md

# Verify cross-references present
grep -c "command_architecture_standards.md" .claude/docs/command-patterns.md .claude/docs/command-reference.md .claude/docs/creating-commands.md
```

Expected: All patterns found in updated files

---

### Phase 3: Update Workflow/Guide Documentation (Category 3)
**Objective**: Add context efficiency guidance and cross-references
**Complexity**: Low
**Files**: 6 files (3 compliant, 3 needing updates)

Tasks:
- [ ] Update orchestration-guide.md:
  - Add explicit reference to Standard 7 (forward message pattern) in context reduction section
  - Add reference to Standard 8 (context pruning) with utility examples
  - Add cross-reference to command_architecture_standards.md#context-preservation-standards
  - File: .claude/docs/orchestration-guide.md

- [ ] Update setup-command-guide.md:
  - Add warning section: "Command File Optimization" explaining optimization utilities should NOT be applied to command files
  - Add note under extraction guidance (lines 59-81) clarifying target is CLAUDE.md, not commands
  - Add cross-reference to command_architecture_standards.md for command-specific optimization rules
  - File: .claude/docs/setup-command-guide.md

- [ ] Verify development-workflow.md (compliant):
  - Quick review to confirm no conflicts with command architecture standards
  - Add cross-reference to command_architecture_standards.md if beneficial
  - File: .claude/docs/development-workflow.md

- [ ] Verify development-philosophy.md (compliant):
  - Confirm exemption language for command files is clear
  - Ensure reference to command_architecture_standards.md is accurate
  - File: .claude/docs/development-philosophy.md

- [ ] Verify adaptive-planning-guide.md (compliant):
  - Quick review to confirm no command architecture conflicts
  - File: .claude/docs/adaptive-planning-guide.md

- [ ] Verify efficiency-guide.md (compliant):
  - Quick review to confirm alignment with lean design principles
  - File: .claude/docs/efficiency-guide.md

Testing:
```bash
# Verify warning added to setup-command-guide.md
grep -n "Command File Optimization\|NOT.*applied to command files" .claude/docs/setup-command-guide.md

# Verify orchestration-guide references Standards 7-8
grep -n "Standard [78]\|forward message\|context pruning" .claude/docs/orchestration-guide.md

# Verify compliant files reviewed
grep -n "command_architecture_standards.md" .claude/docs/development-workflow.md .claude/docs/development-philosophy.md

# Count total cross-references in Category 3
grep -c "command_architecture_standards.md" .claude/docs/orchestration-guide.md .claude/docs/setup-command-guide.md
```

Expected: Warning present, standards referenced, compliant files verified

---

### Phase 4: Update Technical/Spec Documentation (Category 4)
**Objective**: Integrate context preservation patterns and metadata extraction utilities
**Complexity**: Medium
**Files**: 7 files (2 compliant, 5 needing updates)

Tasks:
- [ ] Update directory-protocols.md:
  - Add "Metadata-Only References" section under artifact types (after line 27)
  - Add note: "Artifacts should be referenced by path+metadata, not full content (see Standards 6-8)"
  - Add cross-reference to command_architecture_standards.md#standard-6
  - Reference `.claude/lib/artifact-operations.sh` metadata utilities
  - File: .claude/docs/directory-protocols.md

- [ ] Update spec_updater_guide.md:
  - Update agent invocation example (lines 104-133) to use behavioral injection pattern
  - Add "Cross-Reference Best Practices" section with metadata-only passing example
  - Reference `extract_report_metadata()` utility when creating cross-references
  - Add cross-reference to command_architecture_standards.md for agent invocation patterns
  - File: .claude/docs/spec_updater_guide.md

- [ ] Update artifact_organization.md:
  - Add subsection "Metadata Extraction" under "Artifact Lifecycle → Phase 2: Usage"
  - Add `.claude/lib/artifact-operations.sh` metadata utilities to "Shell Utilities" section (lines 430-513)
  - Add "Anti-Patterns" section with full content passing example (align with Standards 6-7)
  - Update cross-referencing examples (lines 361-372) to emphasize metadata extraction
  - File: .claude/docs/artifact_organization.md

- [ ] Update topic_based_organization.md:
  - Add "Context-Efficient Artifact Usage" section with metadata extraction examples
  - Add note under "Artifact Management" utilities (lines 221-251) about metadata extraction
  - Add cross-reference to command_architecture_standards.md under "Best Practices" (lines 172-203)
  - File: .claude/docs/topic_based_organization.md

- [ ] Update logging-patterns.md:
  - Add "Context-Efficient Logging" section with metadata-only examples
  - Add note under "Agent Invocation Markers" (lines 56-97) about metadata extraction utilities
  - Reference command_architecture_standards.md#standard-6 for artifact passing patterns
  - Update parallel research example (lines 56-67) to emphasize metadata-only output
  - File: .claude/docs/logging-patterns.md

- [ ] Verify phase_dependencies.md (compliant):
  - Quick review to confirm orthogonality to context preservation
  - Optional: Add note under "Integration with Commands" about metadata-only passing for progress tracking
  - File: .claude/docs/phase_dependencies.md

- [ ] Verify error-enhancement-guide.md (compliant):
  - Quick review to confirm orthogonality to command architecture standards
  - File: .claude/docs/error-enhancement-guide.md

Testing:
```bash
# Verify metadata utilities referenced
grep -n "extract_report_metadata\|extract_plan_metadata\|artifact-operations.sh" .claude/docs/directory-protocols.md .claude/docs/artifact_organization.md .claude/docs/topic_based_organization.md .claude/docs/logging-patterns.md

# Verify behavioral injection pattern in spec_updater_guide.md
grep -n "Read and follow.*agents/" .claude/docs/spec_updater_guide.md

# Verify anti-patterns section added
grep -n "Anti-Patterns\|full content passing" .claude/docs/artifact_organization.md

# Verify context-efficient sections added
grep -n "Context-Efficient\|Metadata-Only" .claude/docs/topic_based_organization.md .claude/docs/logging-patterns.md

# Count cross-references to command_architecture_standards.md
grep -c "command_architecture_standards.md" .claude/docs/directory-protocols.md .claude/docs/spec_updater_guide.md .claude/docs/artifact_organization.md .claude/docs/topic_based_organization.md .claude/docs/logging-patterns.md
```

Expected: All patterns present, cross-references added, behavioral injection updated

---

### Phase 5: Update Miscellaneous Documentation and Final Validation
**Objective**: Update remaining docs and validate entire refactor
**Complexity**: Low
**Files**: Miscellaneous docs + full validation

Tasks:
- [ ] Update README.md:
  - Add "Command Architecture Standards" section linking to command_architecture_standards.md
  - Add brief overview of 11 standards (1-2 sentences per standard)
  - Update navigation links to include command_architecture_standards.md
  - File: .claude/docs/README.md

- [ ] Update standards-integration.md:
  - Add section on command architecture standards integration
  - Reference command_architecture_standards.md for command-specific guidelines
  - Add examples of standards integration in commands vs other files
  - File: .claude/docs/standards-integration.md

- [ ] Review claude-md-section-schema.md:
  - Verify schema allows for command architecture standards references
  - No changes expected (schema is orthogonal)
  - File: .claude/docs/claude-md-section-schema.md

- [ ] Review conversion-guide.md:
  - Verify guide doesn't conflict with command architecture standards
  - No changes expected (conversion is orthogonal)
  - File: .claude/docs/conversion-guide.md

- [ ] Review timeless_writing_guide.md:
  - Verify alignment with command architecture standards (particularly inline-first principle)
  - Add cross-reference if beneficial
  - File: .claude/docs/timeless_writing_guide.md

- [ ] Review tts-integration-guide.md:
  - Verify guide doesn't conflict with command architecture standards
  - No changes expected (TTS integration is orthogonal)
  - File: .claude/docs/tts-integration-guide.md

- [ ] Final validation across all updated files:
  - Run comprehensive grep tests for all 11 standards references
  - Verify cross-reference count (target: 15-20 cross-references total)
  - Check for anti-pattern language (over-extraction, reference-only, etc.)
  - Validate behavioral injection pattern usage
  - Verify metadata extraction utilities documented

Testing:
```bash
# Final validation suite

# 1. Count total cross-references to command_architecture_standards.md
echo "=== Cross-Reference Count ==="
grep -r "command_architecture_standards.md" .claude/docs/*.md | wc -l
# Expected: 15-20 references

# 2. Verify Standards 1-11 coverage across docs
echo "=== Standards Coverage ==="
for i in {1..11}; do
  echo "Standard $i:"
  grep -l "Standard $i" .claude/docs/*.md | wc -l
done
# Expected: Each standard referenced in at least 1-3 files

# 3. Check for behavioral injection pattern
echo "=== Behavioral Injection Pattern ==="
grep -r "Read and follow.*agents/" .claude/docs/*.md | wc -l
# Expected: 3-5 occurrences

# 4. Check for metadata extraction utilities
echo "=== Metadata Extraction Utilities ==="
grep -r "extract_report_metadata\|extract_plan_metadata\|artifact-operations.sh" .claude/docs/*.md | wc -l
# Expected: 5-8 occurrences

# 5. Check for anti-pattern warnings
echo "=== Anti-Pattern Warnings ==="
grep -r "anti-pattern\|Anti-Pattern" .claude/docs/*.md | wc -l
# Expected: 2-4 occurrences

# 6. Verify inline-first principle mentioned
echo "=== Inline-First Principle ==="
grep -r "inline.*first\|Inline.*First\|execution-critical" .claude/docs/*.md | wc -l
# Expected: 4-8 occurrences

# 7. Check for context preservation sections
echo "=== Context Preservation Sections ==="
grep -r "Context Preservation\|Context-Efficient" .claude/docs/*.md | wc -l
# Expected: 4-7 occurrences

# 8. Verify no over-extraction language
echo "=== Over-Extraction Check ==="
grep -r "extract all\|move all.*to external\|replace.*with.*See" .claude/docs/*.md
# Expected: No matches (or only in anti-pattern warnings)

# 9. Check README updates
echo "=== README Command Architecture Section ==="
grep -n "Command Architecture Standards" .claude/docs/README.md
# Expected: Section present

# 10. Final summary
echo "=== Validation Summary ==="
echo "Total docs files: $(find .claude/docs -name '*.md' -not -path '*/archive/*' | wc -l)"
echo "Updated files: $(git diff --name-only .claude/docs/*.md | wc -l)"
echo "Cross-references: $(grep -r "command_architecture_standards.md" .claude/docs/*.md | wc -l)"
```

Expected: All validation checks pass with expected counts

---

## Testing Strategy

### Per-Phase Testing
Each phase includes specific grep-based tests to validate:
- Required content additions
- Pattern updates (behavioral injection, metadata extraction)
- Cross-reference presence
- Anti-pattern removal

### Final Validation Suite
Comprehensive testing after Phase 5:
1. Cross-reference count verification (15-20 total)
2. Standards 1-11 coverage analysis
3. Behavioral injection pattern usage
4. Metadata extraction utility documentation
5. Anti-pattern warnings present
6. Inline-first principle emphasized
7. Context preservation sections added
8. Over-extraction language removed
9. README updates verified
10. Summary statistics for documentation coverage

### Manual Review Checklist
- [ ] No documentation promotes over-extraction of execution-critical content
- [ ] Agent invocation examples use behavioral injection (not inline behavioral guidelines)
- [ ] Context preservation utilities (Standards 6-8) documented in relevant guides
- [ ] Lean command design principles (Standards 9-11) integrated where applicable
- [ ] Cross-references to command_architecture_standards.md are contextually appropriate
- [ ] Extraction boundaries clearly distinguished (procedures vs execution logic)
- [ ] File size guidelines and warnings documented

## Documentation Requirements

### Updated Files Summary
By category:
- **Category 1 (Agent)**: 4 files updated
- **Category 2 (Command)**: 4 files updated
- **Category 3 (Workflow/Guide)**: 2 updated, 4 verified compliant
- **Category 4 (Technical/Spec)**: 5 updated, 2 verified compliant
- **Category 5 (Miscellaneous)**: 2 updated, 4 reviewed

**Total**: 17 files updated, 6 verified compliant, 4 reviewed, 5 archived (no changes)

### Cross-Reference Distribution
Target cross-references to command_architecture_standards.md:
- Agent docs: 4-5 references
- Command docs: 5-6 references
- Workflow/guide docs: 2-3 references
- Technical/spec docs: 4-5 references
- Miscellaneous docs: 1-2 references

**Total target**: 15-20 cross-references

### Standards Coverage Distribution
Expected coverage by standard:
- **Standard 1 (Inline Execution)**: 6-8 files (command docs, creating-commands.md, command-patterns.md)
- **Standard 2 (Reference Pattern)**: 3-4 files (command-patterns.md, creating-commands.md)
- **Standard 3 (Information Density)**: 2-3 files (creating-commands.md, command-patterns.md)
- **Standard 4 (Template Completeness)**: 3-4 files (agent docs, creating-commands.md)
- **Standard 5 (Structural Annotations)**: 2-3 files (creating-agents.md, creating-commands.md)
- **Standard 6 (Metadata-Only)**: 6-8 files (agent docs, tech docs, orchestration-guide.md)
- **Standard 7 (Forward Message)**: 4-5 files (agent docs, orchestration-guide.md)
- **Standard 8 (Context Pruning)**: 4-5 files (agent docs, orchestration-guide.md)
- **Standard 9 (Orchestrate Patterns)**: 3-4 files (command-patterns.md, creating-commands.md)
- **Standard 10 (DRY for Commands)**: 2-3 files (command-patterns.md, creating-commands.md)
- **Standard 11 (Target Sizes)**: 2-3 files (creating-commands.md, command-patterns.md)

## Dependencies

### Required Reading
- command_architecture_standards.md (primary reference)
- Research findings from 4 parallel agents (already gathered)

### Utility Libraries Referenced
- `.claude/lib/artifact-operations.sh` (metadata extraction utilities)
- `.claude/lib/context-pruning.sh` (context pruning utilities)
- `.claude/templates/bash-patterns.md` (referenced for procedure extraction examples)

### No External Dependencies
All updates are documentation-only, no code changes required.

## Notes

### Key Principles Guiding Refactor

1. **Non-Breaking**: All changes are additive or clarifying, not removing existing content
2. **Cross-Reference Heavy**: Extensive linking to command_architecture_standards.md rather than duplicating content
3. **Standards Integration**: Weaving standards into existing documentation rather than replacing sections
4. **Compliance Preservation**: Files already compliant (6 files) receive minimal changes
5. **Example-Driven**: Adding concrete examples of behavioral injection, metadata extraction, and context preservation

### Refactor Philosophy

This refactor follows the "enhancement not replacement" principle:
- Add clarity where missing (inline-first principle)
- Add sections where gaps exist (context preservation)
- Add cross-references where helpful (standards integration)
- Update anti-patterns where present (behavioral injection)
- Preserve compliant content (don't fix what isn't broken)

### Post-Refactor Benefits

**For Command Developers**:
- Clear guidance on what must stay inline vs what can be extracted
- Examples of context-efficient multi-agent workflows
- Size targets and bloat warnings to guide development

**For Agent Developers**:
- Behavioral injection pattern clearly documented
- Output format requirements for metadata extraction
- Context preservation utilities referenced

**For Documentation Maintainers**:
- Centralized standards in command_architecture_standards.md
- Clear cross-reference structure
- Reduced documentation drift risk

### Risks and Mitigations

**Risk**: Over-referencing command_architecture_standards.md creates navigation burden
**Mitigation**: Target 15-20 cross-references (average 0.5 per file), only where contextually beneficial

**Risk**: Updates contradict existing compliant content
**Mitigation**: Verify compliant files (development-workflow.md, development-philosophy.md, etc.) before making changes

**Risk**: Refactor itself violates "don't over-extract" principle
**Mitigation**: Add content inline in docs, use cross-references for supplemental depth only

### Implementation Notes

- Phase 1-4 are independent and could be parallelized
- Phase 5 depends on Phases 1-4 completion (final validation)
- Each phase is testable independently
- Rollback strategy: git revert per-phase commits

### Success Metrics

**Quantitative**:
- 17 files updated (target)
- 15-20 cross-references added (target)
- 11 standards covered across docs (target)
- 0 files promoting over-extraction (target)

**Qualitative**:
- Documentation clarity improved
- Standards integration seamless
- No execution-critical content over-extracted
- Context preservation patterns well-documented

---

**Plan Status**: Ready for implementation
**Next Step**: Execute with `/implement .claude/specs/plans/068_docs_alignment_with_command_architecture_standards.md`
