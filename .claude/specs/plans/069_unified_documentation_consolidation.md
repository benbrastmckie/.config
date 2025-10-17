# Unified Documentation Consolidation Plan

## Metadata
- **Date**: 2025-10-17
- **Feature**: Unified .claude/docs/ consolidation integrating context preservation, topic organization, and spec maintenance
- **Scope**: Extend Plan 068 with 11 additional tasks covering Report 051 findings + checkpoint-template integration from Report 052
- **Estimated Phases**: 7 (5 from Plan 068 + 1 pattern library phase + 1 checkpoint-template integration phase)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - .claude/specs/reports/051_command_architecture_context_preservation_standards.md
  - .claude/specs/reports/052_checkpoint_template_system_integration_analysis.md
- **Parent Plan**: .claude/specs/plans/068_docs_alignment_with_command_architecture_standards.md

## Overview

This plan consolidates and unifies all `.claude/docs/` documentation by extending Plan 068 with research findings from Report 051 and Report 052. The unified approach integrates:

1. **Command Architecture Standards** (Plan 068): 11 architectural standards for command and agent files
2. **Context Preservation Patterns** (Report 051): Metadata-only passing, forward message, context pruning utilities
3. **Topic-Based Organization** (Report 051): `specs/{NNN_topic}/{type}/XXX_artifact.md` structure and automation
4. **Spec Maintenance Protocols** (Report 051): Checkbox propagation, parent plan updates, recovery mechanisms
5. **Checkpoint-Template Integration** (Report 052): Unified system with schema v1.3, template-checkpoint linking, consolidated documentation

**Integration Strategy**: Extend Plan 068's 5 phases with additional tasks covering Report 051 findings, add Phase 6 for pattern library creation, and add Phase 7 for checkpoint-template system integration from Report 052.

### Key Achievements from Report 051

**Current State**:
- Context preservation: 56% command adoption (5/9 commands use metadata extraction)
- Context pruning: 0% adoption (critical gap causing 80-90% overhead)
- Topic organization: Well-automated (`get_next_topic_number()`, `get_next_artifact_number()`)
- Spec maintenance: Robust checkbox propagation across plan levels

**Gaps Identified**:
1. **Context-pruning.sh unused**: Zero adoption across all commands
2. **No cross-topic linking**: 106 legacy plans in flat structure vs 13 topic directories
3. **Missing pattern libraries**: Repeated bash procedures in 5+ commands (utility init, checkpoint setup)
4. **Spec-updater standardization**: Unclear when to use agent-based vs direct utility calls

### Approach

- **Phases 1-5**: Execute Plan 068 with **extended tasks** from Report 051
- **Phase 6**: Create pattern libraries and complete migration (new phase)
- Non-breaking changes: Additive enhancements, not replacements
- Cross-reference heavy: Link to `command_architecture_standards.md` throughout
- Example-driven: Concrete implementations of all patterns

## Success Criteria

**From Plan 068**:
- [ ] All 32 docs files reviewed and updated for standards alignment
- [ ] Context preservation standards (6-8) documented in relevant guides
- [ ] Lean command design principles (9-11) integrated where applicable
- [ ] Agent invocation examples use behavioral injection pattern
- [ ] Cross-references to command_architecture_standards.md added (15-20 total)
- [ ] No documentation promotes over-extraction of execution-critical content
- [ ] Testing checklist validates inline completeness requirements

**New From Report 051**:
- [ ] Layered context architecture documented (5 layers: Meta/Operational/Domain/Historical/Environmental)
- [ ] Pattern library references integrated (bash-patterns.md, implementation-patterns.md)
- [ ] Context pruning workflows documented with pruning policy decision tree
- [ ] Spec maintenance protocols documented (bidirectional cross-referencing, artifact lifecycle)
- [ ] Topic-based migration completed (106 legacy plans → topic directories)
- [ ] Gitignore compliance protocols documented
- [ ] Context usage validation added to testing standards (<30% target)

**New From Report 052**:
- [ ] Checkpoint schema upgraded to v1.3 with context preservation, topic organization, and template integration fields
- [ ] Template-checkpoint integration implemented (/plan-from-template creates initial checkpoints)
- [ ] Unified checkpoint_template_guide.md created (consolidating 22 scattered references)
- [ ] Pattern library templates use YAML format with comprehensive variable substitution
- [ ] Commands updated to populate checkpoint v1.3 fields (topic_directory, template_source, etc.)
- [ ] Migration script created for checkpoint v1.2 → v1.3 upgrade

## Technical Design

### Architectural Integration

**Four Documentation Layers** (from Report 051 integration analysis):

1. **Core Standards** (command_architecture_standards.md):
   - 11 architectural standards for commands and agents
   - Context preservation standards (6-8)
   - Lean design standards (9-11)
   - Layered context architecture

2. **Workflow Documentation** (.claude/docs/*.md):
   - Orchestration patterns and multi-agent coordination
   - Spec maintenance protocols and checkbox propagation
   - Adaptive planning and complexity analysis
   - Directory protocols and topic organization

3. **Pattern Libraries** (.claude/templates/*.md):
   - bash-patterns.md (NEW): Reusable utility initialization, checkpoint setup, metadata extraction
   - implementation-patterns.md (NEW): Implementation workflows, error recovery procedures
   - orchestration-patterns.md (EXISTS): Multi-agent coordination patterns

4. **Utility Libraries** (.claude/lib/*.sh):
   - artifact-operations.sh: Metadata extraction (`extract_report_metadata()`, `extract_plan_metadata()`)
   - context-pruning.sh: Context pruning (`prune_subagent_output()`, `apply_pruning_policy()`)
   - checkbox-utils.sh: Checkbox propagation (`mark_phase_complete()`, `propagate_checkbox_update()`)

### Documentation Categories (from Plan 068)

**Category 1: Agent Documentation** (4 files):
- agent-reference.md
- creating-agents.md
- using-agents.md
- hierarchical_agents.md

**Category 2: Command Documentation** (4 files):
- command-patterns.md
- command-reference.md
- command-examples.md
- creating-commands.md

**Category 3: Workflow/Guide Documentation** (6 files):
- orchestration-guide.md
- setup-command-guide.md
- development-workflow.md (compliant)
- development-philosophy.md (compliant)
- adaptive-planning-guide.md (compliant)
- efficiency-guide.md (compliant)

**Category 4: Technical/Spec Documentation** (7 files):
- directory-protocols.md
- spec_updater_guide.md
- artifact_organization.md
- topic_based_organization.md
- logging-patterns.md
- phase_dependencies.md (compliant)
- error-enhancement-guide.md (compliant)

**Category 5: Miscellaneous Documentation** (11 files):
- README.md
- standards-integration.md
- claude-md-section-schema.md
- conversion-guide.md
- timeless_writing_guide.md
- tts-integration-guide.md
- archive/* (5 files - no changes)

### Report 051 Integration Points

**Phase 2 Enhancements** (Command Documentation):
- Add layered context architecture section to creating-commands.md
- Add pattern library reference guidelines with specific size thresholds
- Add explicit command size table (Simple <5KB, Focused <15KB, Complex <25KB)

**Phase 3 Enhancements** (Workflow/Guide Documentation):
- Expand orchestration-guide.md with context pruning workflows
- Add pruning policy decision tree (aggressive/moderate/minimal)

**Phase 4 Enhancements** (Technical/Spec Documentation):
- Expand spec_updater_guide.md with bidirectional cross-referencing workflows
- Add artifact lifecycle management section to artifact_organization.md
- Document gitignore compliance protocols in topic_based_organization.md

**Phase 5 Enhancements** (Final Validation):
- Add validation checks for layered context documentation
- Add validation for pattern library reference completeness
- Add validation for spec maintenance protocol coverage

**Phase 6** (NEW - Pattern Libraries and Migration):
- Create bash-patterns.md pattern library
- Create implementation-patterns.md pattern library
- Migrate 106 legacy plans to topic directories
- Complete cross-topic linking utilities

## Implementation Phases

### Phase 1: Update Agent Documentation (Category 1) - EXTENDED [COMPLETED]

**Objective**: Fix agent invocation anti-patterns and add comprehensive context preservation guidance

**Complexity**: Medium

**Files**: 4 files

**Commit**: c1c1264 (2025-10-17)

**Tasks from Plan 068**:

- [x] Update agent-reference.md:
  - Replace inline invocation template (lines 310-338) with behavioral injection pattern
  - Add "Context Preservation Requirements" section covering Standards 6-8
  - Add cross-reference to command_architecture_standards.md in introduction
  - Reduce template duplication (Standard 10 compliance)
  - File: .claude/docs/agent-reference.md

- [x] Update creating-agents.md:
  - Add "Agent Output Requirements" section explaining metadata extraction compatibility
  - Update tool combination examples (lines 64-75) to explain inline requirement rationale
  - Add structural annotation examples (Standard 5) to agent file template
  - Add cross-reference to command_architecture_standards.md#agent-file-standards
  - File: .claude/docs/creating-agents.md

- [x] Update using-agents.md:
  - Replace 50+ line inline agent prompt templates (lines 585-612, 450-530) with behavioral injection references
  - Add "Context-Efficient Agent Integration" section with Standards 6-8 examples
  - Update integration patterns (lines 126-282) to reference bash-patterns.md for procedures
  - Add metadata extraction examples after agent invocation patterns
  - File: .claude/docs/using-agents.md

- [x] Update hierarchical_agents.md:
  - Add cross-references to command_architecture_standards.md for Standards 1, 6-8
  - Link forward message pattern (lines 223-259) to forward_message() utility (Standard 7)
  - Update command integration examples (lines 498-576) to show executable patterns vs narrative
  - Add note on extraction boundaries (procedures extractable, workflow logic inline)
  - File: .claude/docs/hierarchical_agents.md

**NEW Tasks from Report 051**:

- [x] Add layered context architecture to using-agents.md:
  - Document 5 context layers (Meta/Operational/Domain/Historical/Environmental)
  - Provide practical examples for each layer with agent invocations
  - Show how to separate meta-context (behavioral injection) from operational context
  - Reference command_architecture_standards.md#layered-context-architecture
  - File: .claude/docs/using-agents.md

- [x] Document context pruning in agent coordination:
  - Add "Context Pruning for Multi-Agent Workflows" section to hierarchical_agents.md
  - Document when to call `prune_subagent_output()` after metadata extraction
  - Provide pruning policy examples (aggressive for orchestration, moderate for implementation)
  - Show context reduction metrics (target <30% usage)
  - File: .claude/docs/hierarchical_agents.md

**Testing**:
```bash
# Original Plan 068 tests
grep -n "Read and follow.*agents/" .claude/docs/agent-reference.md .claude/docs/using-agents.md
grep -n "Standard [6-8]" .claude/docs/agent-reference.md .claude/docs/using-agents.md .claude/docs/hierarchical_agents.md
grep -n "command_architecture_standards.md" .claude/docs/agent-reference.md .claude/docs/creating-agents.md .claude/docs/using-agents.md .claude/docs/hierarchical_agents.md

# NEW Report 051 tests
grep -n "Meta-Context\|Operational Context\|Domain Context" .claude/docs/using-agents.md
grep -n "prune_subagent_output\|apply_pruning_policy" .claude/docs/hierarchical_agents.md
grep -n "layered-context-architecture" .claude/docs/using-agents.md
```

Expected: All patterns present, layered context documented, pruning workflows added

---

### Phase 2: Update Command Documentation (Category 2) - EXTENDED [COMPLETED]

**Objective**: Clarify inline-first principles, add lean design guidance, and integrate pattern library references

**Complexity**: High

**Files**: 4 files

**Commit**: df3dbdc (2025-10-17)

**Tasks from Plan 068**:

- [x] Update command-patterns.md:
  - Add "Extraction Boundaries" section clarifying procedures (extractable) vs execution logic (inline)
  - Update extraction guidance (lines 1298-1309) to distinguish Standard 9 vs Standard 1 content
  - Add "Context Preservation Patterns" section with Standards 6-8 examples
  - Add behavioral injection pattern to agent invocation examples
  - Add cross-reference to command_architecture_standards.md in introduction
  - File: .claude/docs/command-patterns.md

- [x] Update command-reference.md:
  - Add "Architectural Context" section linking to command_architecture_standards.md
  - Add note emphasizing commands are "AI execution scripts" not just "workflow automation"
  - Add reference to Standards 1-11 summary with link
  - Keep reference format minimal (no major structural changes)
  - File: .claude/docs/command-reference.md

- [x] Update command-examples.md:
  - Add "Context Preservation Examples" section with Standards 6-8 patterns
  - Add metadata-only passing example (Standard 6)
  - Add forward message pattern example (Standard 7)
  - Add context pruning example (Standard 8)
  - Add note clarifying examples are supplemental reference material
  - File: .claude/docs/command-examples.md

- [x] Update creating-commands.md:
  - Add "Inline Execution Requirements" subsection to development workflow (Section 3.3)
  - Add "File Size Guidelines" section with Standard 11 targets and warnings
  - Add "Context Preservation" section covering Standards 6-8
  - Update standards integration template (lines 502-556) to include inline requirement checks
  - Add structural annotation examples (Standard 5) to command file template
  - Update testing section (lines 875-1016) to validate inline completeness
  - Add cross-reference to command_architecture_standards.md in multiple sections
  - File: .claude/docs/creating-commands.md

**NEW Tasks from Report 051**:

- [x] Add layered context architecture to creating-commands.md:
  - Create "Layered Context Architecture" section explaining 5 layers
  - Provide command file examples showing meta-context vs operational context separation
  - Document when to use behavioral injection vs inline agent personas
  - Add cross-reference to command_architecture_standards.md#layered-context-architecture
  - File: .claude/docs/creating-commands.md

- [x] Add pattern library reference guidelines to creating-commands.md:
  - Create "Pattern Library Integration" section
  - Document when to reference bash-patterns.md (utility init, checkpoint setup)
  - Document when to reference implementation-patterns.md (implementation workflows)
  - Provide specific examples: "See bash-patterns.md#utility-init" vs inline execution steps
  - Add cross-reference to command_architecture_standards.md#standard-9
  - File: .claude/docs/creating-commands.md

- [x] Add explicit command size thresholds to creating-commands.md:
  - Create "Command Size Thresholds" table with Simple/Focused/Complex categories
  - Document target sizes: Simple <5KB, Focused <15KB, Complex <25KB
  - Document warning thresholds: Simple <3KB or >8KB, etc.
  - Explain bloat indicators and solutions
  - Reference command_architecture_standards.md#standard-11
  - File: .claude/docs/creating-commands.md

**Testing**:
```bash
# Original Plan 068 tests
grep -n "inline.*first\|Inline Execution Requirements" .claude/docs/creating-commands.md .claude/docs/command-patterns.md
grep -n "procedures.*extractable\|execution logic.*inline" .claude/docs/command-patterns.md
grep -n "Target.*Size\|size.*threshold\|Standard 11" .claude/docs/creating-commands.md
grep -n "Context Preservation\|Standard [6-8]" .claude/docs/command-patterns.md .claude/docs/command-examples.md .claude/docs/creating-commands.md
grep -c "command_architecture_standards.md" .claude/docs/command-patterns.md .claude/docs/command-reference.md .claude/docs/creating-commands.md

# NEW Report 051 tests
grep -n "Layered Context Architecture" .claude/docs/creating-commands.md
grep -n "Pattern Library Integration\|bash-patterns.md" .claude/docs/creating-commands.md
grep -n "Command Size Thresholds" .claude/docs/creating-commands.md
grep -n "Simple <5KB\|Focused <15KB\|Complex <25KB" .claude/docs/creating-commands.md
```

Expected: All Plan 068 patterns + layered context + pattern libraries + size thresholds documented

---

### Phase 3: Update Workflow/Guide Documentation (Category 3) - EXTENDED [COMPLETED]

**Objective**: Add context efficiency guidance, pruning workflows, and cross-references

**Complexity**: Low

**Files**: 6 files (2 updated, 4 verified compliant)

**Commit**: 2b8de03 (2025-10-17)

**Tasks from Plan 068**:

- [x] Update orchestration-guide.md:
  - Add explicit reference to Standard 7 (forward message pattern) in context reduction section
  - Add reference to Standard 8 (context pruning) with utility examples
  - Add cross-reference to command_architecture_standards.md#context-preservation-standards
  - File: .claude/docs/orchestration-guide.md

- [x] Update setup-command-guide.md:
  - Add warning section: "Command File Optimization" explaining optimization utilities should NOT be applied to command files
  - Add note under extraction guidance (lines 59-81) clarifying target is CLAUDE.md, not commands
  - Add cross-reference to command_architecture_standards.md for command-specific optimization rules
  - File: .claude/docs/setup-command-guide.md

- [x] Verify development-workflow.md (compliant):
  - Quick review to confirm no conflicts with command architecture standards
  - Add cross-reference to command_architecture_standards.md if beneficial
  - File: .claude/docs/development-workflow.md

- [x] Verify development-philosophy.md (compliant):
  - Confirm exemption language for command files is clear
  - Ensure reference to command_architecture_standards.md is accurate
  - File: .claude/docs/development-philosophy.md

- [x] Verify adaptive-planning-guide.md (compliant):
  - Quick review to confirm no command architecture conflicts
  - File: .claude/docs/adaptive-planning-guide.md

- [x] Verify efficiency-guide.md (compliant):
  - Quick review to confirm alignment with lean design principles
  - File: .claude/docs/efficiency-guide.md

**NEW Tasks from Report 051**:

- [x] Add context pruning workflows to orchestration-guide.md:
  - Create "Context Pruning Workflows" section
  - Document pruning policy decision tree (aggressive/moderate/minimal)
  - Show when to call `apply_pruning_policy()` in multi-phase workflows
  - Provide examples: orchestrate uses aggressive, implement uses moderate
  - Document target context usage <30% throughout workflows
  - Add cross-reference to command_architecture_standards.md#standard-8
  - File: .claude/docs/orchestration-guide.md

- [x] Add pruning utility examples to orchestration-guide.md:
  - Document `prune_subagent_output()` usage after metadata extraction
  - Document `prune_phase_metadata()` usage after phase completion
  - Provide complete code examples with before/after context measurements
  - Reference .claude/lib/context-pruning.sh utility library
  - File: .claude/docs/orchestration-guide.md

**Testing**:
```bash
# Original Plan 068 tests
grep -n "Command File Optimization\|NOT.*applied to command files" .claude/docs/setup-command-guide.md
grep -n "Standard [78]\|forward message\|context pruning" .claude/docs/orchestration-guide.md
grep -n "command_architecture_standards.md" .claude/docs/development-workflow.md .claude/docs/development-philosophy.md
grep -c "command_architecture_standards.md" .claude/docs/orchestration-guide.md .claude/docs/setup-command-guide.md

# NEW Report 051 tests
grep -n "Context Pruning Workflows\|pruning policy decision tree" .claude/docs/orchestration-guide.md
grep -n "prune_subagent_output\|prune_phase_metadata\|apply_pruning_policy" .claude/docs/orchestration-guide.md
grep -n "aggressive.*moderate.*minimal" .claude/docs/orchestration-guide.md
grep -n "<30%.*context" .claude/docs/orchestration-guide.md
```

Expected: Plan 068 content + pruning workflows + policy decision tree + utility examples documented

---

### Phase 4: Update Technical/Spec Documentation (Category 4) - EXTENDED [COMPLETED]

**Objective**: Integrate context preservation patterns, metadata extraction utilities, and spec maintenance protocols

**Complexity**: Medium

**Files**: 7 files (2 compliant, 5 needing updates)

**Commit**: 2f0ef57 (2025-10-17)

**Tasks from Plan 068**:

- [x] Update directory-protocols.md:
  - Add "Metadata-Only References" section under artifact types (after line 27)
  - Add note: "Artifacts should be referenced by path+metadata, not full content (see Standards 6-8)"
  - Add cross-reference to command_architecture_standards.md#standard-6
  - Reference `.claude/lib/artifact-operations.sh` metadata utilities
  - File: .claude/docs/directory-protocols.md

- [x] Update spec_updater_guide.md:
  - Update agent invocation example (lines 104-133) to use behavioral injection pattern
  - Add "Cross-Reference Best Practices" section with metadata-only passing example
  - Reference `extract_report_metadata()` utility when creating cross-references
  - Add cross-reference to command_architecture_standards.md for agent invocation patterns
  - File: .claude/docs/spec_updater_guide.md

- [x] Update artifact_organization.md:
  - Add subsection "Metadata Extraction" under "Artifact Lifecycle → Phase 2: Usage"
  - Add `.claude/lib/artifact-operations.sh` metadata utilities to "Shell Utilities" section (lines 430-513)
  - Add "Anti-Patterns" section with full content passing example (align with Standards 6-7)
  - Update cross-referencing examples (lines 361-372) to emphasize metadata extraction
  - File: .claude/docs/artifact_organization.md

- [x] Update topic_based_organization.md:
  - Add "Context-Efficient Artifact Usage" section with metadata extraction examples
  - Add note under "Artifact Management" utilities (lines 221-251) about metadata extraction
  - Add cross-reference to command_architecture_standards.md under "Best Practices" (lines 172-203)
  - File: .claude/docs/topic_based_organization.md

- [x] Update logging-patterns.md:
  - Add "Context-Efficient Logging" section with metadata-only examples
  - Add note under "Agent Invocation Markers" (lines 56-97) about metadata extraction utilities
  - Reference command_architecture_standards.md#standard-6 for artifact passing patterns
  - Update parallel research example (lines 56-67) to emphasize metadata-only output
  - File: .claude/docs/logging-patterns.md

- [x] Verify phase_dependencies.md (compliant):
  - Quick review to confirm orthogonality to context preservation
  - Optional: Add note under "Integration with Commands" about metadata-only passing for progress tracking
  - File: .claude/docs/phase_dependencies.md

- [x] Verify error-enhancement-guide.md (compliant):
  - Quick review to confirm orthogonality to command architecture standards
  - File: .claude/docs/error-enhancement-guide.md

**NEW Tasks from Report 051**:

- [x] Add bidirectional cross-referencing workflows to spec_updater_guide.md:
  - Create "Bidirectional Cross-Referencing" section
  - Document automatic cross-reference creation (reports ↔ plans ↔ summaries)
  - Provide workflow: create artifact → extract metadata → update parent references → update child references
  - Document utilities: `create_bidirectional_link()`, `update_parent_references()`
  - Add examples showing forward and backward references
  - File: .claude/docs/spec_updater_guide.md

- [x] Add artifact lifecycle management to artifact_organization.md:
  - Create "Artifact Lifecycle Management" section
  - Document lifecycle stages: creation → usage → completion → archival
  - Document retention policies (debug: permanent, scripts: 0-day, artifacts: 30-day)
  - Document cleanup triggers and automation (`cleanup_all_temp_artifacts()`)
  - Document metadata tracking throughout lifecycle
  - File: .claude/docs/artifact_organization.md

- [x] Add gitignore compliance protocols to topic_based_organization.md:
  - Create "Gitignore Compliance Protocols" section
  - Document which artifacts are committed vs gitignored
  - Explain debug/ is committed, plans/reports/summaries are gitignored
  - Document validation: `validate_gitignore_compliance()` utility
  - Add automatic compliance checking to workflow documentation
  - File: .claude/docs/topic_based_organization.md

**Testing**:
```bash
# Original Plan 068 tests
grep -n "extract_report_metadata\|extract_plan_metadata\|artifact-operations.sh" .claude/docs/directory-protocols.md .claude/docs/artifact_organization.md .claude/docs/topic_based_organization.md .claude/docs/logging-patterns.md
grep -n "Read and follow.*agents/" .claude/docs/spec_updater_guide.md
grep -n "Anti-Patterns\|full content passing" .claude/docs/artifact_organization.md
grep -n "Context-Efficient\|Metadata-Only" .claude/docs/topic_based_organization.md .claude/docs/logging-patterns.md
grep -c "command_architecture_standards.md" .claude/docs/directory-protocols.md .claude/docs/spec_updater_guide.md .claude/docs/artifact_organization.md .claude/docs/topic_based_organization.md .claude/docs/logging-patterns.md

# NEW Report 051 tests
grep -n "Bidirectional Cross-Referencing\|create_bidirectional_link" .claude/docs/spec_updater_guide.md
grep -n "Artifact Lifecycle Management\|cleanup_all_temp_artifacts" .claude/docs/artifact_organization.md
grep -n "Gitignore Compliance Protocols\|validate_gitignore_compliance" .claude/docs/topic_based_organization.md
grep -n "retention policies\|0-day\|30-day" .claude/docs/artifact_organization.md
```

Expected: All Plan 068 content + bidirectional cross-referencing + lifecycle management + gitignore protocols

---

### Phase 5: Update Miscellaneous Documentation and Final Validation - EXTENDED [COMPLETED]

**Objective**: Update remaining docs and validate entire refactor with Report 051 additions

**Complexity**: Low

**Files**: Miscellaneous docs + full validation

**Commit**: 11ecc32 (2025-10-17)

**Tasks from Plan 068**:

- [x] Update README.md:
  - Add "Command Architecture Standards" section linking to command_architecture_standards.md
  - Add brief overview of 11 standards (1-2 sentences per standard)
  - Update navigation links to include command_architecture_standards.md
  - File: .claude/docs/README.md

- [x] Update standards-integration.md:
  - Add section on command architecture standards integration
  - Reference command_architecture_standards.md for command-specific guidelines
  - Add examples of standards integration in commands vs other files
  - File: .claude/docs/standards-integration.md

- [x] Review claude-md-section-schema.md:
  - Verify schema allows for command architecture standards references
  - No changes expected (schema is orthogonal)
  - File: .claude/docs/claude-md-section-schema.md

- [x] Review conversion-guide.md:
  - Verify guide doesn't conflict with command architecture standards
  - No changes expected (conversion is orthogonal)
  - File: .claude/docs/conversion-guide.md

- [x] Review timeless_writing_guide.md:
  - Verify alignment with command architecture standards (particularly inline-first principle)
  - Add cross-reference if beneficial
  - File: .claude/docs/timeless_writing_guide.md

- [x] Review tts-integration-guide.md:
  - Verify guide doesn't conflict with command architecture standards
  - No changes expected (TTS integration is orthogonal)
  - File: .claude/docs/tts-integration-guide.md

- [x] Final validation across all updated files (Plan 068):
  - Run comprehensive grep tests for all 11 standards references
  - Verify cross-reference count (target: 15-20 cross-references total)
  - Check for anti-pattern language (over-extraction, reference-only, etc.)
  - Validate behavioral injection pattern usage
  - Verify metadata extraction utilities documented

**NEW Tasks from Report 051**:

- [x] Add Report 051 findings to README.md:
  - Add "Context Preservation Utilities" section linking to relevant docs
  - Add "Pattern Libraries" section describing bash-patterns.md, implementation-patterns.md
  - Add "Spec Maintenance" section linking to spec_updater_guide.md
  - Add "Topic-Based Organization" section linking to topic_based_organization.md
  - File: .claude/docs/README.md

- [x] Validate Report 051 integration:
  - Verify layered context architecture documented in creating-commands.md and using-agents.md
  - Verify pattern library references present in creating-commands.md
  - Verify context pruning workflows documented in orchestration-guide.md
  - Verify spec maintenance protocols documented in spec_updater_guide.md
  - Verify gitignore compliance protocols in topic_based_organization.md

**Testing**:
```bash
# Original Plan 068 validation suite
echo "=== Cross-Reference Count ==="
grep -r "command_architecture_standards.md" .claude/docs/*.md | wc -l
# Expected: 15-20 references

echo "=== Standards Coverage ==="
for i in {1..11}; do
  echo "Standard $i:"
  grep -l "Standard $i" .claude/docs/*.md | wc -l
done
# Expected: Each standard referenced in at least 1-3 files

echo "=== Behavioral Injection Pattern ==="
grep -r "Read and follow.*agents/" .claude/docs/*.md | wc -l
# Expected: 3-5 occurrences

echo "=== Metadata Extraction Utilities ==="
grep -r "extract_report_metadata\|extract_plan_metadata\|artifact-operations.sh" .claude/docs/*.md | wc -l
# Expected: 5-8 occurrences

echo "=== Anti-Pattern Warnings ==="
grep -r "anti-pattern\|Anti-Pattern" .claude/docs/*.md | wc -l
# Expected: 2-4 occurrences

echo "=== Inline-First Principle ==="
grep -r "inline.*first\|Inline.*First\|execution-critical" .claude/docs/*.md | wc -l
# Expected: 4-8 occurrences

echo "=== Context Preservation Sections ==="
grep -r "Context Preservation\|Context-Efficient" .claude/docs/*.md | wc -l
# Expected: 4-7 occurrences

echo "=== Over-Extraction Check ==="
grep -r "extract all\|move all.*to external\|replace.*with.*See" .claude/docs/*.md
# Expected: No matches (or only in anti-pattern warnings)

echo "=== README Command Architecture Section ==="
grep -n "Command Architecture Standards" .claude/docs/README.md
# Expected: Section present

# NEW Report 051 validation tests
echo "=== Layered Context Architecture ==="
grep -r "Layered Context Architecture\|Meta-Context\|Operational Context" .claude/docs/*.md | wc -l
# Expected: 4-6 occurrences

echo "=== Pattern Library References ==="
grep -r "bash-patterns.md\|implementation-patterns.md" .claude/docs/*.md | wc -l
# Expected: 3-5 occurrences

echo "=== Context Pruning Workflows ==="
grep -r "prune_subagent_output\|apply_pruning_policy\|Context Pruning Workflows" .claude/docs/*.md | wc -l
# Expected: 4-6 occurrences

echo "=== Spec Maintenance Protocols ==="
grep -r "Bidirectional Cross-Referencing\|Artifact Lifecycle Management" .claude/docs/*.md | wc -l
# Expected: 2-3 occurrences

echo "=== Gitignore Compliance ==="
grep -r "Gitignore Compliance\|validate_gitignore_compliance" .claude/docs/*.md | wc -l
# Expected: 1-2 occurrences

echo "=== Command Size Thresholds ==="
grep -r "Simple <5KB\|Focused <15KB\|Complex <25KB" .claude/docs/*.md | wc -l
# Expected: 1-2 occurrences

echo "=== Final Summary ==="
echo "Total docs files: $(find .claude/docs -name '*.md' -not -path '*/archive/*' | wc -l)"
echo "Updated files: $(git diff --name-only .claude/docs/*.md 2>/dev/null | wc -l)"
echo "Cross-references: $(grep -r "command_architecture_standards.md" .claude/docs/*.md | wc -l)"
echo "Report 051 integrations: $(grep -r "bash-patterns.md\|Layered Context\|Bidirectional Cross" .claude/docs/*.md | wc -l)"
```

Expected: All Plan 068 validation + Report 051 validation passes

---

### Phase 6: Create Pattern Libraries and Complete Topic Migration (NEW)

**Objective**: Create bash-patterns.md and implementation-patterns.md pattern libraries, migrate 106 legacy plans to topic directories, and implement cross-topic linking utilities

**Complexity**: High

**Files**: 2 new pattern libraries + 106 plan migrations + 1 utility enhancement

**Tasks**:

- [ ] Create bash-patterns.yaml pattern library template:
  - Create file: .claude/templates/bash-patterns.yaml
  - Use YAML format with comprehensive variable substitution (per Report 052)
  - Define variables: checkpoint_prefix (string), log_file (string, optional)
  - Document 5 pattern phases:
    1. Utility Initialization Pattern (source checkpoint-utils.sh, artifact-operations.sh, context-pruning.sh, error-handling.sh)
    2. Checkpoint Setup Pattern (mkdir checkpoints, restore_checkpoint, validate_checkpoint, check_safe_resume_conditions)
    3. Metadata Extraction Pattern (extract_report_metadata, extract_plan_metadata, cache in checkpoint)
    4. Context Pruning Pattern (apply_pruning_policy, prune_subagent_output, prune_phase_metadata, log operations)
    5. Error Handling Pattern (classify_error, suggest_recovery, log to checkpoint, update status)
  - Provide copy-paste ready bash code blocks for each pattern with {{variable}} substitution
  - Add cross-references to command_architecture_standards.md#standard-9
  - Reference Report 052 Recommendation 3 for complete template structure
  - File: .claude/templates/bash-patterns.yaml

- [ ] Create implementation-patterns.yaml pattern library template:
  - Create file: .claude/templates/implementation-patterns.yaml
  - Use YAML format with comprehensive variable substitution (per Report 052)
  - Define variables: plan_path (string, required)
  - Document 4 pattern phases:
    1. Phase-by-Phase Execution Pattern (load plan, parse phases, execute tasks, run tests, commit, update checkpoint, invoke spec-updater)
    2. Test-After-Phase Pattern (get test command from plan, execute, validate passing, update checkpoint.tests_passing)
    3. Git Commit Pattern (stage files, create commit with structured message including 🤖 Generated with Claude Code, verify, store commit hash)
    4. Checkpoint Save Pattern (prepare workflow_state JSON, save_checkpoint, verify creation, log path)
  - Provide complete workflow bash code blocks for each pattern with {{plan_path}} substitution
  - Add cross-references to command_architecture_standards.md#standard-9
  - Reference Report 052 Recommendation 3 for complete template structure
  - File: .claude/templates/implementation-patterns.yaml

- [ ] Create cross-topic linking utilities:
  - Enhance .claude/lib/artifact-operations.sh with `find_artifact_across_topics()`
  - Add `create_cross_topic_reference()` function
  - Add `validate_cross_topic_link()` function
  - Document usage in .claude/docs/topic_based_organization.md
  - Add examples showing cross-topic references
  - File: .claude/lib/artifact-operations.sh

- [ ] Migrate 106 legacy plans to topic directories:
  - Create migration script: .claude/scripts/migrate_legacy_plans.sh
  - Script logic:
    - For each plan in .claude/specs/plans/*.md (flat structure)
    - Extract topic from plan filename/content
    - Create or reuse topic directory: specs/{NNN_topic}/
    - Move plan to specs/{NNN_topic}/plans/001_plan.md
    - Update all internal cross-references
    - Update parent/grandparent plan references if hierarchical
  - Run migration script with --dry-run first
  - Review migration preview
  - Run migration script for real
  - Validate all migrated plans have correct paths
  - Files: .claude/scripts/migrate_legacy_plans.sh, specs/plans/*.md → specs/{NNN_topic}/plans/*.md

- [ ] Update commands to reference pattern libraries:
  - Update .claude/commands/orchestrate.md to reference bash-patterns.md for utility init
  - Update .claude/commands/implement.md to reference bash-patterns.md for checkpoint setup
  - Update .claude/commands/implement.md to reference implementation-patterns.md for phase execution
  - Update .claude/commands/debug.md to reference bash-patterns.md for error handling
  - Update .claude/commands/plan.md to reference bash-patterns.md for utility init
  - Remove inline duplicated code, replace with pattern references
  - Files: .claude/commands/*.md (5 command files)

**Testing**:
```bash
# Verify pattern libraries created
test -f .claude/templates/bash-patterns.md && echo "✓ bash-patterns.md created"
test -f .claude/templates/implementation-patterns.md && echo "✓ implementation-patterns.md created"

# Verify pattern libraries have required sections
grep -n "Utility Initialization\|Checkpoint Setup\|Metadata Extraction" .claude/templates/bash-patterns.md
grep -n "Phase-by-Phase Execution\|Test-After-Phase\|Git Commit" .claude/templates/implementation-patterns.md

# Verify cross-topic utilities added
grep -n "find_artifact_across_topics\|create_cross_topic_reference" .claude/lib/artifact-operations.sh

# Verify migration script created
test -f .claude/scripts/migrate_legacy_plans.sh && echo "✓ Migration script created"

# Verify legacy plans migrated
LEGACY_COUNT=$(find .claude/specs/plans -maxdepth 1 -name "[0-9][0-9][0-9]_*.md" | wc -l)
echo "Legacy plans remaining: $LEGACY_COUNT (should be 0 or very low)"

# Verify topic directories created
TOPIC_COUNT=$(find .claude/specs -maxdepth 1 -type d -name "[0-9][0-9][0-9]_*" | wc -l)
echo "Topic directories: $TOPIC_COUNT (should be significantly increased from 13)"

# Verify commands reference pattern libraries
grep -n "bash-patterns.md" .claude/commands/orchestrate.md .claude/commands/implement.md .claude/commands/debug.md .claude/commands/plan.md
grep -n "implementation-patterns.md" .claude/commands/implement.md

# Verify inline code removed from commands
ORCHESTRATE_SIZE=$(wc -c < .claude/commands/orchestrate.md)
IMPLEMENT_SIZE=$(wc -c < .claude/commands/implement.md)
echo "orchestrate.md size: $ORCHESTRATE_SIZE (target <25KB = 25600 bytes)"
echo "implement.md size: $IMPLEMENT_SIZE (target <15KB = 15360 bytes)"

# Verify pattern library cross-references
grep -c "command_architecture_standards.md" .claude/templates/bash-patterns.md
grep -c "command_architecture_standards.md" .claude/templates/implementation-patterns.md
# Expected: ≥2 per file

# Final validation: End-to-end test
echo "=== Running End-to-End Test ==="
# Test command execution with pattern library references
echo "Testing /orchestrate with pattern libraries..."
# (Manual test: invoke /orchestrate "Simple test feature" and verify it executes successfully)
```

Expected: Pattern libraries created, 106 plans migrated, commands reference patterns, command file sizes reduced

---

### Phase 7: Checkpoint-Template System Integration (NEW from Report 052)

**Objective**: Upgrade checkpoint schema to v1.3, implement template-checkpoint integration, and create unified documentation guide consolidating 22 scattered references

**Complexity**: Medium

**Files**: 1 schema upgrade + 1 command enhancement + 1 unified guide + migration script

**Tasks**:

- [ ] Upgrade checkpoint schema to v1.3 (Report 052 Recommendation 1, HIGH PRIORITY):
  - Update `.claude/lib/checkpoint-utils.sh` CHECKPOINT_SCHEMA_VERSION to "1.3"
  - Add new fields to checkpoint JSON structure:
    - `topic_directory` (string, nullable): Path to topic directory (e.g., "specs/042_authentication")
    - `topic_number` (number, nullable): Topic number extracted from directory (e.g., 42)
    - `context_preservation` (object): Nested object with pruning_log (array), artifact_metadata_cache (object), subagent_output_references (array)
    - `template_source` (string, nullable): Template name if plan generated from template (e.g., "crud-feature")
    - `template_variables` (object, nullable): Variables used in template generation
    - `spec_maintenance` (object): Nested object with parent_plan_path, grandparent_plan_path, spec_updater_invocations (array), checkbox_propagation_log (array)
  - Update `save_checkpoint()` function to populate new fields from workflow_state when provided
  - File: .claude/lib/checkpoint-utils.sh

- [ ] Create checkpoint migration script v1.2 → v1.3:
  - Create file: `.claude/lib/migrate-checkpoint-v1.3.sh`
  - Implement migration logic using jq to add new fields with safe defaults:
    - topic_directory: Extract from workflow_state.topic_directory or null
    - topic_number: Extract from workflow_state.topic_number or null
    - context_preservation: Initialize with empty arrays/objects
    - template_source: Extract from workflow_state.template_source or null
    - template_variables: Extract from workflow_state.template_variables or null
    - spec_maintenance: Initialize with nulls and empty arrays
  - Add backup creation (.backup suffix) before migration
  - Add validation after migration
  - Test migration on existing checkpoints
  - File: .claude/lib/migrate-checkpoint-v1.3.sh

- [ ] Update `migrate_checkpoint_format()` in checkpoint-utils.sh:
  - Add v1.2 → v1.3 migration case to existing migration function
  - Use same migration logic as standalone script
  - Ensure backward compatibility (all new fields nullable/optional)
  - Test automated migration on checkpoint load
  - File: .claude/lib/checkpoint-utils.sh

- [ ] Implement template-checkpoint integration (Report 052 Recommendation 2, MEDIUM PRIORITY):
  - Modify `/plan-from-template` command to create initial checkpoint after plan generation
  - Checkpoint should include:
    - workflow_type: "plan_generated"
    - status: "planning_complete"
    - workflow_state.plan_path: Path to generated plan
    - workflow_state.template_source: Template name used
    - workflow_state.template_variables: Collected variable values
    - workflow_state.topic_directory: Topic directory path
    - workflow_state.topic_number: Extracted topic number
  - Add informational message: "Checkpoint created. Run /implement $plan_file to begin implementation."
  - Update `/implement` command to detect template-generated checkpoints and use template context for intelligent defaults
  - File: .claude/commands/plan-from-template.md

- [ ] Create unified checkpoint_template_guide.md (Report 052 Recommendation 4, MEDIUM PRIORITY):
  - Create file: `.claude/docs/checkpoint_template_guide.md`
  - Consolidate content from 22 scattered references into single comprehensive guide
  - Structure (per Report 052 design):
    1. Overview: What are checkpoints and templates, how they work together, when to use each
    2. Checkpoint System: Schema v1.3 reference, lifecycle, smart auto-resume (5 safety conditions), migration path, utility functions
    3. Template System: YAML format, variable substitution syntax, topic-based integration, 11 categories, Neovim picker
    4. Integration Workflows: Template → Plan → Checkpoint → Implement → Resume (end-to-end), pattern library usage, context-preserving templates, spec maintenance
    5. Best Practices: When to create checkpoints, templates vs /plan, designing templates, cleanup strategies
    6. Troubleshooting: Common checkpoint issues, template validation errors, resume failures, migration problems
    7. API Reference: Checkpoint utilities (20+ functions), template utilities (10+ functions), code examples
  - Add layered architecture diagram from Report 052 (4 layers: User-Facing, Checkpoint Coordination, Template Generation, Utility Foundation)
  - Add end-to-end integration flow diagram with 16 steps from template selection to workflow completion
  - Cross-reference command_architecture_standards.md, bash-patterns.yaml, implementation-patterns.yaml
  - File: .claude/docs/checkpoint_template_guide.md

- [ ] Update commands to populate checkpoint v1.3 fields:
  - Update `/orchestrate` to populate:
    - context_preservation.pruning_log when apply_pruning_policy() called
    - context_preservation.artifact_metadata_cache when extract_report_metadata() called
    - context_preservation.subagent_output_references when subagents complete
  - Update `/implement` to populate:
    - topic_directory and topic_number from plan path analysis
    - spec_maintenance.parent_plan_path for hierarchical plans
    - spec_maintenance.spec_updater_invocations when spec-updater agent called
    - spec_maintenance.checkbox_propagation_log when checkboxes updated
  - Update `/plan-from-template` to populate:
    - template_source and template_variables (already covered above)
  - Files: .claude/commands/orchestrate.md, .claude/commands/implement.md, .claude/commands/plan-from-template.md

- [ ] Add checkpoint-template integration references to existing docs:
  - Update `.claude/docs/directory-protocols.md`: Add note about checkpoint-template linking under artifact lifecycle
  - Update `.claude/docs/development-workflow.md`: Reference unified checkpoint_template_guide.md in workflow section
  - Update `.claude/docs/README.md`: Add "Checkpoint-Template System" section linking to checkpoint_template_guide.md
  - Update `.claude/templates/README.md`: Add note about template-checkpoint integration and link to unified guide
  - Files: Multiple documentation files

**Testing**:
```bash
# Verify checkpoint schema v1.3 upgrade
grep -n "CHECKPOINT_SCHEMA_VERSION.*1.3" .claude/lib/checkpoint-utils.sh
grep -n "topic_directory\|context_preservation\|template_source\|spec_maintenance" .claude/lib/checkpoint-utils.sh

# Verify migration script created
test -f .claude/lib/migrate-checkpoint-v1.3.sh && echo "✓ Migration script created"

# Test migration on sample checkpoint
.claude/lib/migrate-checkpoint-v1.3.sh .claude/data/checkpoints/test_*/test_checkpoint.json --dry-run
# Expected: Shows migration preview with new fields

# Verify template-checkpoint integration in /plan-from-template
grep -n "save_checkpoint.*plan_generated" .claude/commands/plan-from-template.md
grep -n "template_source\|template_variables" .claude/commands/plan-from-template.md

# Verify unified guide created
test -f .claude/docs/checkpoint_template_guide.md && echo "✓ Unified guide created"

# Verify unified guide structure
grep -n "^## Overview\|^## Checkpoint System\|^## Template System\|^## Integration Workflows" .claude/docs/checkpoint_template_guide.md
# Expected: All 7 main sections present

# Verify unified guide consolidates scattered references
SCATTERED_REFS=$(grep -r "checkpoint.*resume\|template.*generation" .claude/docs/*.md | grep -v checkpoint_template_guide.md | wc -l)
echo "Scattered references remaining: $SCATTERED_REFS (many should reference unified guide now)"

# Verify commands populate v1.3 fields
grep -n "context_preservation\|topic_directory\|spec_maintenance" .claude/commands/orchestrate.md .claude/commands/implement.md
# Expected: Multiple matches showing field population

# Verify cross-references to unified guide
grep -r "checkpoint_template_guide.md" .claude/docs/*.md .claude/commands/*.md | wc -l
# Expected: 5-8 references

# Test end-to-end: template → checkpoint → implement
echo "=== End-to-End Integration Test ==="
# 1. Generate plan from template (should create checkpoint)
# /plan-from-template crud-feature
# Expected: Checkpoint created with template_source and template_variables populated

# 2. Implement plan (should detect template-generated checkpoint)
# /implement specs/042_crud/plans/001_implementation.md
# Expected: Auto-resumes from template context, shows intelligent defaults

# 3. Verify checkpoint v1.3 fields populated
# cat .claude/data/checkpoints/*/checkpoint_*.json | jq '.schema_version, .template_source, .topic_directory, .context_preservation'
# Expected: v1.3, template source present, topic directory present, context preservation tracking

# Final validation
echo "=== Checkpoint-Template Integration Validation ==="
echo "Schema version: $(grep CHECKPOINT_SCHEMA_VERSION .claude/lib/checkpoint-utils.sh | grep -oE '1\.[0-9]+')"
echo "Migration script: $(test -f .claude/lib/migrate-checkpoint-v1.3.sh && echo 'Present' || echo 'Missing')"
echo "Unified guide: $(test -f .claude/docs/checkpoint_template_guide.md && echo 'Present' || echo 'Missing')"
echo "Template integration: $(grep -c 'save_checkpoint.*plan_generated' .claude/commands/plan-from-template.md)"
echo "Commands updated: $(grep -c 'context_preservation\|topic_directory' .claude/commands/orchestrate.md .claude/commands/implement.md)"
```

Expected: Schema v1.3 implemented, migration script functional, unified guide comprehensive, template-checkpoint integration working, commands populating new fields

---

## Testing Strategy

### Per-Phase Testing

Each phase includes specific grep-based tests to validate:
- Required content additions (from Plan 068 + Report 051)
- Pattern updates (behavioral injection, metadata extraction, layered context)
- Cross-reference presence (command_architecture_standards.md, pattern libraries)
- Anti-pattern removal

### Integration Testing

After Phase 4 completion:
1. **Context Preservation Integration**: Verify metadata extraction + forward message + pruning documented consistently
2. **Layered Context Integration**: Verify 5 layers documented in agent and command docs
3. **Pattern Library Integration**: Verify bash-patterns.yaml and implementation-patterns.yaml referenced appropriately

After Phase 7 completion:
4. **Checkpoint-Template Integration**: Verify schema v1.3 implemented, template-checkpoint linking functional, unified guide comprehensive
5. **End-to-End Flow**: Test template → checkpoint → implement → resume workflow with v1.3 fields populated

### Final Validation Suite

Comprehensive testing after Phase 7:
1. Cross-reference count verification (20-25 total, increased from Plan 068's 15-20)
2. Standards 1-11 coverage analysis
3. Behavioral injection pattern usage
4. Metadata extraction utility documentation
5. Anti-pattern warnings present
6. Inline-first principle emphasized
7. Context preservation sections added
8. Over-extraction language removed
9. README updates verified
10. **NEW**: Layered context architecture documented
11. **NEW**: Pattern library references validated
12. **NEW**: Context pruning workflows documented
13. **NEW**: Spec maintenance protocols documented
14. **NEW**: Topic migration completed
15. **NEW**: Command file sizes within thresholds
16. **NEW**: Checkpoint schema v1.3 implemented with new fields
17. **NEW**: Template-checkpoint integration functional
18. **NEW**: Unified checkpoint_template_guide.md created

### Manual Review Checklist

**From Plan 068**:
- [ ] No documentation promotes over-extraction of execution-critical content
- [ ] Agent invocation examples use behavioral injection (not inline behavioral guidelines)
- [ ] Context preservation utilities (Standards 6-8) documented in relevant guides
- [ ] Lean command design principles (Standards 9-11) integrated where applicable
- [ ] Cross-references to command_architecture_standards.md are contextually appropriate
- [ ] Extraction boundaries clearly distinguished (procedures vs execution logic)
- [ ] File size guidelines and warnings documented

**NEW From Report 051**:
- [ ] Layered context architecture (5 layers) documented with examples
- [ ] Pattern libraries (bash-patterns.yaml, implementation-patterns.yaml) created and referenced
- [ ] Context pruning workflows documented with pruning policy decision tree
- [ ] Spec maintenance protocols documented (bidirectional cross-referencing, lifecycle management)
- [ ] Gitignore compliance protocols documented
- [ ] Topic migration completed (legacy plans moved to topic directories)
- [ ] Command file sizes within target thresholds (orchestrate <25KB, implement <15KB)
- [ ] Context usage validation added to testing standards (<30% target)

**NEW From Report 052**:
- [ ] Checkpoint schema v1.3 fields validated in checkpoint-utils.sh (topic_directory, context_preservation, template_source, spec_maintenance)
- [ ] Migration script functional (v1.2 → v1.3 with backup and validation)
- [ ] Template-checkpoint integration working (/plan-from-template creates checkpoints)
- [ ] Unified checkpoint_template_guide.md comprehensive (7 sections, consolidates 22 references)
- [ ] Commands populate v1.3 fields (/orchestrate, /implement, /plan-from-template)
- [ ] End-to-end flow tested (template → checkpoint → implement → resume)

## Documentation Requirements

### Updated Files Summary

By category:
- **Category 1 (Agent)**: 4 files updated + 2 new sections (layered context, pruning)
- **Category 2 (Command)**: 4 files updated + 3 new sections (layered context, pattern libraries, size thresholds) + 3 commands enhanced for checkpoint v1.3
- **Category 3 (Workflow/Guide)**: 2 updated, 4 verified compliant + 2 new sections (pruning workflows, policy tree) + 1 new unified guide
- **Category 4 (Technical/Spec)**: 5 updated, 2 verified compliant + 3 new sections (bidirectional cross-ref, lifecycle, gitignore)
- **Category 5 (Miscellaneous)**: 2 updated, 4 reviewed + Report 051 sections added

**Total from Plan 068**: 17 files updated, 6 verified compliant, 4 reviewed, 5 archived (no changes)

**NEW from Report 051**: 11 new sections added to existing files + 2 new pattern library templates (YAML) + migration script (plan migration)

**NEW from Report 052**: 1 schema upgrade (checkpoint-utils.sh) + 1 migration script (checkpoint v1.2→v1.3) + 1 unified guide (checkpoint_template_guide.md) + 3 commands enhanced + 4 docs updated

**Grand Total**: 17+1 docs files updated, 2 pattern library templates (YAML), 2 migration scripts, 1 unified guide, 3 commands enhanced for checkpoint v1.3, 106 plans migrated to topic directories

### Cross-Reference Distribution

Target cross-references to command_architecture_standards.md:
- Agent docs: 4-5 references (Plan 068) + 2 new (layered context, pruning) = 6-7 total
- Command docs: 5-6 references (Plan 068) + 3 new (layered context, patterns, sizes) = 8-9 total
- Workflow/guide docs: 2-3 references (Plan 068) + 2 new (pruning workflows) = 4-5 total
- Technical/spec docs: 4-5 references (Plan 068) + 3 new (cross-ref, lifecycle, gitignore) = 7-8 total
- Miscellaneous docs: 1-2 references (Plan 068) + 1 new (Report 051 overview) = 2-3 total

**Total target**: 27-32 cross-references (increased from Plan 068's 15-20)

### Pattern Library Cross-References

New pattern library cross-references:
- bash-patterns.md: Referenced in 5 command files + 2 docs files = 7 references
- implementation-patterns.md: Referenced in 1 command file + 1 docs file = 2 references

**Pattern library cross-references total**: 9 references

### Standards Coverage Distribution

Expected coverage by standard (Plan 068 + Report 051 additions):

- **Standard 1 (Inline Execution)**: 6-8 files (Plan 068) + pattern library examples = 8-10 total
- **Standard 2 (Reference Pattern)**: 3-4 files (Plan 068) + pattern library docs = 5-6 total
- **Standard 3 (Information Density)**: 2-3 files (Plan 068, unchanged)
- **Standard 4 (Template Completeness)**: 3-4 files (Plan 068, unchanged)
- **Standard 5 (Structural Annotations)**: 2-3 files (Plan 068, unchanged)
- **Standard 6 (Metadata-Only)**: 6-8 files (Plan 068) + lifecycle docs = 8-10 total
- **Standard 7 (Forward Message)**: 4-5 files (Plan 068) + orchestration pruning = 6-7 total
- **Standard 8 (Context Pruning)**: 4-5 files (Plan 068) + **pruning workflows docs** = 8-10 total (MAJOR INCREASE)
- **Standard 9 (Orchestrate Patterns)**: 3-4 files (Plan 068) + **pattern library docs** = 7-8 total (MAJOR INCREASE)
- **Standard 10 (DRY for Commands)**: 2-3 files (Plan 068) + pattern library docs = 4-5 total
- **Standard 11 (Target Sizes)**: 2-3 files (Plan 068) + **size thresholds table** = 4-5 total (MAJOR INCREASE)

**Key Improvements**: Standards 8, 9, 11 significantly increased coverage (doubles or more)

## Dependencies

### Required Reading

- command_architecture_standards.md (primary reference, updated 2025-10-16)
- .claude/specs/reports/051_command_architecture_context_preservation_standards.md (Report 051 findings)
- .claude/specs/plans/068_docs_alignment_with_command_architecture_standards.md (Plan 068 base)

### Utility Libraries Referenced

- `.claude/lib/artifact-operations.sh` (metadata extraction utilities, will be enhanced with cross-topic linking)
- `.claude/lib/context-pruning.sh` (context pruning utilities, **currently unused - will be integrated**)
- `.claude/lib/checkbox-utils.sh` (checkbox propagation utilities)
- `.claude/templates/bash-patterns.md` (**NEW - to be created in Phase 6**)
- `.claude/templates/implementation-patterns.md` (**NEW - to be created in Phase 6**)

### No External Dependencies

All updates are documentation-only (Phases 1-5) plus pattern library creation and migration script (Phase 6). No changes to core command functionality required.

## Notes

### Key Principles Guiding Unified Refactor

1. **Non-Breaking**: All changes are additive or clarifying, not removing existing content (from Plan 068)
2. **Cross-Reference Heavy**: Extensive linking to command_architecture_standards.md and new pattern libraries
3. **Standards Integration**: Weaving standards into existing documentation rather than replacing sections (from Plan 068)
4. **Compliance Preservation**: Files already compliant (6 files) receive minimal changes (from Plan 068)
5. **Example-Driven**: Adding concrete examples of behavioral injection, metadata extraction, context preservation, and **layered context** (Plan 068 + Report 051)
6. **Context Efficiency**: Integrating context pruning workflows and metadata-only passing patterns throughout (Report 051)
7. **Pattern Reusability**: Creating reusable pattern libraries to eliminate code duplication (Report 051)
8. **Topic Consolidation**: Completing migration to topic-based organization (Report 051)

### Refactor Philosophy

This refactor follows the "enhancement not replacement" principle (from Plan 068):
- Add clarity where missing (inline-first principle, layered context architecture)
- Add sections where gaps exist (context preservation, pruning workflows, pattern libraries)
- Add cross-references where helpful (standards integration, pattern references)
- Update anti-patterns where present (behavioral injection, full content passing)
- Preserve compliant content (don't fix what isn't broken)
- **NEW**: Create pattern libraries to reduce command file bloat
- **NEW**: Complete topic-based migration for unified organization

### Post-Refactor Benefits

**For Command Developers** (Plan 068 + Report 051):
- Clear guidance on what must stay inline vs what can be extracted
- Examples of context-efficient multi-agent workflows
- Size targets and bloat warnings to guide development
- **NEW**: Reusable pattern libraries for common procedures
- **NEW**: Layered context architecture for agent invocations
- **NEW**: Context pruning workflows to maintain <30% usage

**For Agent Developers** (Plan 068 + Report 051):
- Behavioral injection pattern clearly documented
- Output format requirements for metadata extraction
- Context preservation utilities referenced
- **NEW**: Layered context examples showing meta vs operational separation

**For Documentation Maintainers** (Plan 068):
- Centralized standards in command_architecture_standards.md
- Clear cross-reference structure
- Reduced documentation drift risk

**For Spec Maintainers** (Report 051):
- **NEW**: Bidirectional cross-referencing workflows
- **NEW**: Artifact lifecycle management protocols
- **NEW**: Gitignore compliance validation
- **NEW**: Unified topic-based organization

### Risks and Mitigations

**Risk**: Over-referencing command_architecture_standards.md creates navigation burden
**Mitigation**: Target 27-32 cross-references (average 0.8 per file), only where contextually beneficial

**Risk**: Updates contradict existing compliant content
**Mitigation**: Verify compliant files (development-workflow.md, development-philosophy.md, etc.) before making changes

**Risk**: Refactor itself violates "don't over-extract" principle
**Mitigation**: Add content inline in docs, use cross-references for supplemental depth only

**NEW Risk**: Pattern libraries encourage over-extraction of execution-critical content
**Mitigation**: Pattern libraries only contain procedures (utility init, checkpoint setup), NOT workflow logic or decision points

**NEW Risk**: Topic migration breaks existing plan references
**Mitigation**: Migration script updates all cross-references automatically; validation step confirms no broken links

**NEW Risk**: Command file size reduction compromises execution completeness
**Mitigation**: Only extract procedures to pattern libraries; workflow logic and tool invocations stay inline per Standard 1

### Implementation Notes

- Phase 1-4 are independent and could be parallelized (from Plan 068)
- Phase 5 depends on Phases 1-4 completion (final validation, from Plan 068)
- **Phase 6 depends on Phases 1-5 completion** (pattern libraries need documented standards context)
- Each phase is testable independently (from Plan 068)
- Rollback strategy: git revert per-phase commits (from Plan 068)
- **NEW**: Migration script has --dry-run mode for safe preview before execution
- **NEW**: Pattern library integration requires command file updates (5 commands affected)

### Success Metrics

**Quantitative** (Plan 068 + Report 051 + Report 052):
- 18 files updated (17 from Plan 068 + 1 schema upgrade)
- 32-40 cross-references added (increased from Plan 068's 15-20, includes unified guide references)
- 11 standards covered across docs (Plan 068 target, achieved)
- 0 files promoting over-extraction (Plan 068 target, maintained)
- **NEW (Report 051)**: 2 pattern library templates (YAML) created
- **NEW (Report 051)**: 106 legacy plans migrated to topic directories
- **NEW (Report 051)**: 5 command files referencing pattern libraries
- **NEW (Report 051)**: Command file sizes within thresholds (orchestrate <25KB, implement <15KB)
- **NEW (Report 051)**: Context pruning documented in 8-10 files (up from 4-5)
- **NEW (Report 052)**: Checkpoint schema v1.3 with 6 new fields
- **NEW (Report 052)**: 1 unified guide consolidating 22 scattered references
- **NEW (Report 052)**: 3 commands enhanced to populate checkpoint v1.3 fields
- **NEW (Report 052)**: Template-checkpoint integration (seamless workflow)

**Qualitative** (Plan 068):
- Documentation clarity improved
- Standards integration seamless
- No execution-critical content over-extracted
- Context preservation patterns well-documented

**NEW Qualitative** (Report 051):
- Context pruning workflows actionable and comprehensive
- Pattern libraries reduce duplication without compromising execution
- Layered context architecture clearly explained with examples
- Spec maintenance protocols standardized and automated
- Topic-based organization fully adopted

**NEW Qualitative** (Report 052):
- Checkpoint-template integration creates seamless workflow
- Unified guide improves system discoverability dramatically
- Schema v1.3 enables full tracking of context preservation, topic organization, and spec maintenance
- Template context preserved for intelligent implementation defaults
- System maturity increased from 85% to 95% compatible with design goals

### Report 051 Integration Summary

**Coverage of Report 051 Recommendations**:

1. **Integrate apply_pruning_policy() in all commands** → Phase 3 (orchestration-guide.md pruning workflows)
2. **Add context tracking to /expand, /collapse, /revise** → Deferred (commands, not docs)
3. **Add metadata extraction to /report** → Deferred (command functionality, not docs)
4. **Complete topic migration** → Phase 6 (106 plans migrated)
5. **Enforce topic-based creation** → Phase 4 (topic_based_organization.md protocols)
6. **Automatic cleanup integration** → Phase 4 (artifact_organization.md lifecycle)
7. **Standardize spec-updater invocation** → Phase 4 (spec_updater_guide.md bidirectional cross-ref)
8. **Document layered context architecture** → Phases 1-2 (agent and command docs)
9. **Create pattern libraries** → Phase 6 (bash-patterns.md, implementation-patterns.md)

**Deferred Items** (require command implementation, not documentation):
- Context tracking in /expand, /collapse, /revise (Report 051 Recommendation 2)
- Metadata extraction in /report (Report 051 Recommendation 3)
- Apply pruning policy in commands (Report 051 Recommendation 1) - *documentation ready, command implementation deferred*

**Rationale for Deferral**: This plan focuses on documentation consolidation. Command implementation improvements will be addressed in a follow-up plan based on this unified documentation.

### Report 052 Integration Summary

**Coverage of Report 052 Recommendations**:

1. **Enhance Checkpoint Schema to v1.3** (HIGH PRIORITY) → Phase 7 (schema upgrade, migration script, 6 new fields)
2. **Integrate Template System with Checkpoint Creation** (MEDIUM PRIORITY) → Phase 7 (/plan-from-template creates checkpoints)
3. **Create Pattern Library Templates** (HIGH PRIORITY) → Phase 6 (bash-patterns.yaml, implementation-patterns.yaml with YAML format per Report 052)
4. **Consolidate Documentation into Unified Guide** (MEDIUM PRIORITY) → Phase 7 (checkpoint_template_guide.md with 7 sections)
5. **Add Wave Tracking Fields** (LOW PRIORITY) → Deferred to v1.4 (parallel execution not yet implemented)

**Implementation Impact**:
- All HIGH and MEDIUM priority recommendations implemented
- LOW priority recommendation (wave tracking) appropriately deferred
- System integration increased from 85% to 95% compatibility with design goals
- Pattern library templates use comprehensive YAML format from Report 052 (vs simpler markdown originally planned)
- Unified guide consolidates 22 scattered references into single source of truth

**Integration Benefits**:
- **Seamless workflow**: Template → Checkpoint → Implement → Resume with full context preservation
- **Intelligent defaults**: Template context available during implementation
- **System discoverability**: Single comprehensive guide vs scattered references
- **Full tracking**: Context preservation, topic organization, spec maintenance all tracked in checkpoint schema
- **Zero breaking changes**: Schema v1.3 backward compatible, automated migration

**Deferred Items** (require parallel execution implementation first):
- Wave tracking fields (Report 052 Recommendation 5) - Will be added in checkpoint schema v1.4 when parallel phase execution is implemented

**Rationale for Deferral**: Wave tracking depends on parallel phase execution feature which is documented but not yet implemented. Schema v1.3 provides all fields needed for current design goals.

---
