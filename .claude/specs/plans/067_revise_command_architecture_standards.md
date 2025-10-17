# Revise Command Architecture Standards with Context Preservation Patterns

## Metadata
- **Date**: 2025-10-17
- **Feature**: Systematic revision of command_architecture_standards.md and cross-referenced documentation to incorporate context preservation, lean design, and agentic best practices
- **Scope**: Update `.claude/docs/command_architecture_standards.md` (primary) and 6 related documentation files with findings from research report 051
- **Estimated Phases**: 4
- **Complexity**: Medium
- **Standards File**: CLAUDE.md at /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - `.claude/specs/reports/051_command_architecture_context_preservation_standards.md`
- **Target File**: `.claude/docs/command_architecture_standards.md`

## Overview

The current `command_architecture_standards.md` (28KB, last updated 2025-10-16) focuses on preventing over-extraction of execution-critical content from command files. However, it lacks guidance on modern context preservation patterns, metadata-only artifact passing, and lean command design principles discovered in Plans 056-058 and validated through 2025 agentic system research.

Additionally, **6 related documentation files** contain overlapping or potentially inconsistent guidance that must be cross-referenced to ensure a coherent documentation ecosystem.

This plan systematically revises the standards document and related files to:
1. **Add Context Preservation Mandates**: Metadata-only passing, forward message pattern, context pruning requirements
2. **Add Lean Command Design Principles**: Pattern extraction guidelines, DRY principles for commands, target command sizes
3. **Add Layered Context Architecture**: Five-layer context separation (meta/operational/domain/historical/environmental)
4. **Integrate Modern Agentic Patterns**: Hierarchical supervision, artifact-based communication, behavioral injection standardization
5. **Cross-Reference Related Documentation**: Update hierarchical_agents.md, creating-commands.md, creating-agents.md, using-agents.md, orchestration-guide.md, and development-workflow.md for consistency

The revision will preserve existing anti-patterns and execution-critical content standards while adding complementary guidance for context efficiency and lean design.

## Success Criteria

- [x] Research findings from Report 051 comprehensively integrated
- [ ] New sections added to command_architecture_standards.md: Context Preservation Mandates, Lean Command Design, Layered Context Architecture
- [ ] Existing standards preserved: Execution-critical content must remain inline
- [ ] Balance achieved: Context preservation complements (not contradicts) anti-over-extraction stance
- [ ] Practical examples provided for each new pattern
- [ ] Cross-references added to utility libraries (.claude/lib/*.sh)
- [ ] Document remains actionable for command refactoring decisions
- [ ] File size: 35-45KB (current 28KB + ~15KB new content)
- [ ] All 6 related documentation files updated with cross-references to new standards
- [ ] No conflicting guidance across documentation ecosystem
- [ ] Consistent terminology used across all updated files
- [ ] Clear delineation: standards document provides mandates, related docs provide examples/implementation

## Technical Design

### Architectural Approach

**Complementary Standards Addition**:
- Existing standards prevent extraction of execution-critical content (anti-over-extraction)
- New standards guide context preservation within execution-critical content (pro-efficiency)
- Together: Commands remain executable AND context-efficient

**Integration Strategy**:
```
Current Standards (Preserve):
├── Executable Instructions Must Be Inline
├── Reference Pattern (inline first, reference after)
├── Template Completeness
└── Anti-Patterns to Avoid

New Standards (Add):
├── Context Preservation Mandates
│   ├── Metadata-Only Passing
│   ├── Forward Message Pattern
│   └── Context Pruning
├── Lean Command Design Principles
│   ├── Commands Orchestrate Patterns
│   ├── DRY Principle for Commands
│   └── Target Command Sizes
└── Layered Context Architecture
    └── Five Context Layers
```

### Reconciliation of Tensions

**Tension 1: Inline Content vs. Pattern References**

**Current Standard**: Execution steps must be inline (prevent over-extraction)
**New Standard**: Commands should reference patterns, not duplicate them (prevent bloat)

**Resolution**:
- **Execution-Critical Content** (workflow logic, decision points, tool invocations): MUST stay inline
- **Reusable Procedures** (utility initialization, checkpoint patterns, bash functions): Extract to pattern libraries, reference from commands
- **Guideline**: "Commands orchestrate patterns, not document them" applies to procedures, NOT to workflow logic

**Example**:
```markdown
KEEP INLINE (execution logic):
## Step 2: Launch Research Agents

**CRITICAL**: Send ALL Task invocations in SINGLE message.

For each research topic:
1. Calculate complexity score
2. Determine thinking mode
3. Construct agent prompt with behavioral injection
4. Invoke Task tool

EXTRACT TO PATTERN (reusable procedure):
Checkpoint initialization bash script
→ Reference: `.claude/templates/bash-patterns.md#checkpoint-init`
```

**Tension 2: Complete Templates vs. Metadata Passing**

**Current Standard**: Agent prompts must be complete, copy-paste ready (template completeness)
**New Standard**: Pass metadata only, not full content (context preservation)

**Resolution**:
- **Agent Prompt Templates** (in command files): MUST be complete for agent invocation
- **Agent Response Handling** (subagent outputs): Extract metadata ONLY, pass artifact paths
- **Guideline**: Templates are complete for invocation; responses are minimized for context

**Example**:
```markdown
COMPLETE TEMPLATE (for invocation):
Task {
  subagent_type: "general-purpose"
  prompt: |
    [COMPLETE prompt with all context layers]
}

METADATA-ONLY PASSING (for response):
artifact_path=$(extract_from_response "$subagent_output")
metadata=$(extract_report_metadata "$artifact_path")
# Store metadata only, NOT full subagent_output
```

### Document Structure After Revision

```
command_architecture_standards.md

## Purpose
[Existing: AI execution scripts, not traditional code]

## Fundamental Understanding
[Existing: Command files are AI execution scripts]

## Core Standards
[Existing: Standards 1-5]
├── Standard 1: Executable Instructions Must Be Inline
├── Standard 2: Reference Pattern
├── Standard 3: Critical Information Density
├── Standard 4: Template Completeness
└── Standard 5: Structural Annotations

## Context Preservation Standards [NEW]
├── Standard 6: Metadata-Only Passing
├── Standard 7: Forward Message Pattern
└── Standard 8: Context Pruning

## Lean Command Design Standards [NEW]
├── Standard 9: Commands Orchestrate Patterns
├── Standard 10: DRY Principle for Commands
└── Standard 11: Target Command Sizes

## Layered Context Architecture [NEW]
├── Meta-Context Layer
├── Operational Context Layer
├── Domain Context Layer
├── Historical Context Layer
└── Environmental Context Layer

## Refactoring Guidelines
[Existing + Enhanced with context preservation]

## Testing Standards
[Existing + Add context usage validation]

## Anti-Patterns to Avoid
[Existing + Add paraphrasing anti-pattern, full content passing]

## File Organization Standards
[Existing + Add pattern library references]

## Related Standards
[Existing + Add references to artifact-operations.sh, context-pruning.sh]
```

### Key Additions Detail

#### Standard 6: Metadata-Only Passing

**Mandate**: Commands MUST pass artifact metadata, not full content, between agents.

**Pattern**:
1. Subagent creates artifact (report, plan, debug findings)
2. Subagent extracts metadata using `extract_{type}_metadata()`
3. Subagent returns metadata ONLY to caller
4. Caller stores metadata in context (path + 50-word summary)
5. Downstream agents read artifacts directly when needed

**Utilities**:
- `.claude/lib/artifact-operations.sh:extract_report_metadata()`
- `.claude/lib/artifact-operations.sh:extract_plan_metadata()`
- `.claude/lib/artifact-operations.sh:load_metadata_on_demand()`

**Target**: <30% context usage throughout workflows

#### Standard 7: Forward Message Pattern

**Mandate**: Commands MUST forward subagent responses without paraphrasing.

**Pattern**:
1. Primary delegates complete task to subagent
2. Subagent returns structured output
3. Primary forwards output to next phase WITHOUT modification
4. Primary extracts metadata ONLY for own context

**Benefit**: Eliminates 200-300 token paraphrasing overhead per subagent

**Source**: LangChain 2025 supervisor pattern best practices (Report 051)

#### Standard 8: Context Pruning

**Mandate**: Commands MUST aggressively prune context after each phase.

**Actions**:
- After research: Prune summaries, keep artifact paths
- After planning: Prune plan details, keep path + current phase
- After phase completion: Prune detailed data, keep status only

**Utilities**: `.claude/lib/context-pruning.sh`
- `prune_subagent_output()` - Clear full outputs after metadata extraction
- `prune_phase_metadata()` - Remove phase data after completion
- `apply_pruning_policy()` - Automatic pruning by workflow type

#### Standard 9: Commands Orchestrate Patterns

**Guideline**: Commands should reference external patterns, not duplicate them inline.

**Extraction Guidelines**:
- **Inline** (keep in command): Workflow logic, phase coordination, decision points, tool invocation examples
- **Extract** (move to pattern library): Procedures, utility initialization, repeated bash functions

**Pattern Libraries**:
- `.claude/templates/bash-patterns.md` - Reusable bash procedures
- `.claude/templates/implementation-patterns.md` - Implementation workflows
- `.claude/templates/orchestration-patterns.md` - Multi-agent coordination
- `.claude/docs/command-patterns.md` - General command patterns

#### Standard 10: DRY Principle for Commands

**Mandate**: Eliminate redundant procedures across commands.

**Common Bloat Sources**:
- Checkpoint initialization (appears in 3+ commands)
- Utility sourcing (appears in 5+ commands)
- Spec-updater invocation (appears in 4+ commands)
- Standards discovery (appears in 3+ commands)

**Solution**: Create shared templates, reference once

#### Standard 11: Target Command Sizes

**Size Guidelines**:
- Simple commands (wrappers): <5KB
- Focused commands (single workflow): <15KB
- Complex commands (multi-phase): <25KB

**Current Violations** (from Report 051):
- orchestrate.md: 110KB (83% bloat, target 15-20KB)
- implement.md: 52KB (71% bloat, target 10-15KB)
- debug.md: 20KB (40% bloat, target 8-12KB)

#### Layered Context Architecture

**Five Layers**:

1. **Meta-Context** (Identity): Agent role, responsibilities, constraints
   - Defined in: `.claude/agents/{agent-name}.md`
   - Injected via: Behavioral injection pattern

2. **Operational Context** (Task): Current task, tools, success criteria
   - Defined in: Command invocation
   - Unique per task

3. **Domain Context** (Knowledge): Project standards, documentation
   - Referenced: CLAUDE.md, architecture docs
   - NOT inlined

4. **Historical Context** (Memory): Previous phase results
   - Format: Metadata only (50-word summaries + paths)
   - Pruned aggressively

5. **Environmental Context** (System): File paths, system state
   - Format: Current state only
   - No historical changes

**Benefits**:
- Separation of concerns
- Context minimization
- Reusability
- Progressive loading

## Implementation Phases

### Phase 1: Add Context Preservation Standards
**Objective**: Integrate metadata-only passing, forward message pattern, and context pruning standards
**Complexity**: Medium

**Tasks**:
- [ ] Read current `command_architecture_standards.md` (already done above)
- [ ] Create new section "Context Preservation Standards" after "Core Standards"
- [ ] Add Standard 6: Metadata-Only Passing
  - Include mandate, required pattern (5 steps), utilities list, target metric
  - Add practical bash example from Report 051:857-885
  - Reference `.claude/lib/artifact-operations.sh`
- [ ] Add Standard 7: Forward Message Pattern
  - Include mandate, pattern diagram (from Report 051:330-372), anti-pattern warning
  - Add implementation bash example from Report 051:937-975
  - Reference LangChain 2025 supervisor pattern
- [ ] Add Standard 8: Context Pruning
  - Include mandate, required actions, utilities list
  - Add usage example from Report 051:1117-1138
  - Reference `.claude/lib/context-pruning.sh`
- [ ] Add cross-reference at end of Core Standards section: "See Context Preservation Standards for context efficiency requirements."

**Testing**:
- Verify new section follows existing document style (markdown format, structural annotations)
- Confirm no contradictions with existing "Executable Instructions Must Be Inline" standard
- Check that utilities referenced exist in `.claude/lib/`

**Validation Criteria**:
- All 3 new standards clearly defined with mandates
- Practical bash examples included for each
- Utilities properly referenced with file paths
- Cross-reference added to Core Standards section

---

### Phase 2: Add Lean Command Design Standards
**Objective**: Integrate pattern orchestration, DRY principles, and target command sizes
**Complexity**: Medium

**Tasks**:
- [ ] Create new section "Lean Command Design Standards" after "Context Preservation Standards"
- [ ] Add Standard 9: Commands Orchestrate Patterns
  - Include guideline, extraction guidelines (inline vs extract)
  - Add pattern libraries list (4 libraries)
  - Add example from Report 051:161-165 (BAD) and reference-based GOOD alternative
  - Add integration note: "This standard applies to PROCEDURES, not EXECUTION LOGIC (see Standard 1)"
- [ ] Add Standard 10: DRY Principle for Commands
  - Include mandate, common bloat sources (4 sources from Report 051:114-117)
  - Add BAD example (50-line inline utility sourcing)
  - Add GOOD example (1-line pattern reference)
  - Add note: "For execution-critical steps, inline duplication is acceptable per Standard 1"
- [ ] Add Standard 11: Target Command Sizes
  - Include size guidelines (simple/focused/complex command targets)
  - Add current violations table from Report 051:291-296
  - Add warning: "Sizes below minimum indicate over-extraction; sizes above maximum indicate bloat"
- [ ] Update "File Size Guidelines" section (lines 544-568) to reference Standard 11

**Testing**:
- Verify examples clearly distinguish procedures (extractable) from execution logic (inline)
- Confirm size targets don't contradict existing "File Size Guidelines" (lines 544-568)
- Check that bloat sources match actual command files (orchestrate.md, implement.md)

**Validation Criteria**:
- All 3 new standards clearly defined
- Distinction between procedures and execution logic explicit
- No contradictions with existing inline content requirements
- File Size Guidelines section updated with cross-reference

---

### Phase 3: Add Layered Context Architecture and Update Related Sections
**Objective**: Add layered context architecture, update existing sections with context preservation references
**Complexity**: Medium

**Tasks**:
- [ ] Create new section "Layered Context Architecture" after "Lean Command Design Standards"
- [ ] Add Context Layer Separation subsection
  - Include mandate for layer separation
  - Add five layers with definitions (meta/operational/domain/historical/environmental)
  - Add benefits list (4 benefits from Report 051:561-565)
- [ ] Add practical examples for each layer
  - Meta-Context: Agent definition example from Report 051:1148-1196
  - Operational Context: Task invocation example from Report 051:1207-1239
  - Domain Context: Referenced standards example from Report 051:1250-1265
  - Historical Context: Metadata example from Report 051:1276-1285
  - Environmental Context: System state example from Report 051:1296-1303
- [ ] Update "Anti-Patterns to Avoid" section (lines 373-514)
  - Add Anti-Pattern 5: Paraphrasing Subagent Outputs
  - Include BAD example from Report 051:979-994
  - Include GOOD example (forward message pattern)
  - Add warning: "Violates Standard 7 (Forward Message Pattern)"
  - Add Anti-Pattern 6: Full Content Passing Between Agents
  - Include example of passing full report content vs metadata
  - Add warning: "Violates Standard 6 (Metadata-Only Passing)"
  - Add Anti-Pattern 7: Commands Calling Other Commands
  - Include BAD example: Agent told to invoke `/plan` using SlashCommand (current orchestrate.md:1081)
  - Include GOOD example: Direct subagent invocation with behavioral injection (master branch pattern)
  - Add warning: "Breaks context preservation - use Task tool with general-purpose + behavioral injection"
  - Reference: git commit 8fe34aa, master branch agent-integration-guide.md
- [ ] Update "Testing Standards" section (lines 300-370)
  - Add Test 5: Context Usage Validation
  - Include bash test for context pruning calls in workflow commands
  - Include bash test for metadata extraction after subagent invocations
  - Add PASS criteria: Context usage <30% throughout workflow
- [ ] Update "Related Standards" section (lines 811-818)
  - Add reference to `.claude/lib/artifact-operations.sh` - Metadata extraction utilities
  - Add reference to `.claude/lib/context-pruning.sh` - Context pruning utilities
  - Add reference to `.claude/templates/bash-patterns.md` - Reusable bash procedures (to be created)
  - Add reference to `.claude/templates/implementation-patterns.md` - Implementation workflows (to be created)
- [ ] Add "Quick Reference Card" subsection to end of document
  - **When Preserving Context in Commands**: DO/DON'T list for metadata passing, forward pattern, pruning
  - **When Designing Lean Commands**: DO/DON'T list for pattern orchestration, DRY, sizing
  - **Testing After Changes**: Enhanced checklist including context validation

**Testing**:
- Verify layered context examples are complete and copy-paste ready
- Confirm new anti-patterns align with standards 6 and 7
- Check that testing standards additions are actionable (bash commands provided)
- Verify related standards references point to existing files (or note "to be created")

**Validation Criteria**:
- Layered Context Architecture fully documented with examples
- 2 new anti-patterns added with violations noted
- Testing Standards enhanced with context validation
- Related Standards updated with utility and template references
- Quick Reference Card added for practical guidance

---

### Phase 4: Cross-Reference and Consistency Updates
**Objective**: Update 6 related documentation files with cross-references to new standards and ensure consistent terminology
**Complexity**: Medium

**Tasks**:
- [ ] Update `hierarchical_agents.md`
  - Add cross-reference in introduction to `command_architecture_standards.md` Standards 6-8
  - Add note in "Metadata Extraction" section: "This implementation complies with Standard 6 (Metadata-Only Passing) from command_architecture_standards.md"
  - Add note in "Forward Message Pattern" section: "This pattern implements Standard 7 (Forward Message Pattern) from command_architecture_standards.md"
  - Add note in "Context Management" section: "These utilities implement Standard 8 (Context Pruning) from command_architecture_standards.md"
  - Clarify delineation: "hierarchical_agents.md provides implementation details; command_architecture_standards.md provides architectural mandates"
- [ ] Update `creating-commands.md`
  - Add section reference after introduction: "See command_architecture_standards.md for complete standards including Context Preservation (Standards 6-8) and Lean Design (Standards 9-11)"
  - Add warning in "Agent Invocation" section referencing Anti-Pattern 7: "NEVER instruct agents to call slash commands. Use Task tool with general-purpose + behavioral injection instead."
  - Add example of correct pattern: Task with general-purpose + behavioral injection from `.claude/agents/{role}.md`
  - Add reference to Standard 9: "Extract reusable procedures to pattern libraries (see Standard 9: Commands Orchestrate Patterns)"
  - Update "Command Size Guidelines" to reference Standard 11 from command_architecture_standards.md
- [ ] Update `creating-agents.md`
  - Add section on "Layered Context Architecture" after "Agent File Structure"
  - Reference command_architecture_standards.md definition of five context layers
  - Add guidance: "Agent definition files provide Meta-Context Layer (identity, role, constraints)"
  - Add example: Agent file structure maps to meta-context requirements
  - Add note: "Operational Context (task details) provided by command at invocation time"
  - Reference `.claude/agents/` directory for behavioral injection pattern examples
- [ ] Update `using-agents.md`
  - Add prominent warning at top of "Agent Invocation" section: "CRITICAL: Anti-Pattern 7 - Never Call Commands from Commands"
  - Add explanation: Commands calling commands (via SlashCommand tool) breaks context preservation
  - Add correct pattern: Direct subagent invocation with behavioral injection (existing content already shows this)
  - Add cross-reference: "See command_architecture_standards.md Anti-Pattern 7 for detailed rationale"
  - Add note in "Behavioral Injection" section: "This pattern complies with Standard 6 (Metadata-Only Passing) by keeping agent definitions external"
- [ ] Update `orchestration-guide.md`
  - Add cross-reference in "Artifact-Based Aggregation" section to Standard 6 (Metadata-Only Passing)
  - Add note: "This workflow implements Standards 6-8 (Context Preservation) from command_architecture_standards.md"
  - Add validation criteria: "Context usage should remain <30% throughout workflow (Standard 6 target)"
  - Add example: Metadata extraction from subagent responses (reference existing examples)
  - Update "Parallel Execution" section to note: "Parallel agents return metadata only, enabling aggregation without context explosion"
- [ ] Update `development-workflow.md`
  - Add cross-reference in "Spec Updater Integration" section to Standard 6 (Metadata-Only Passing)
  - Add note: "Spec updater passes artifact paths, not full content, between workflow phases"
  - Add reference in "Artifact Lifecycle" section to Standard 8 (Context Pruning)
  - Add note: "Temporary artifacts (scripts/, outputs/) are pruned to maintain context efficiency"
  - Update "Shell Utilities" section to cross-reference `.claude/lib/artifact-operations.sh` utilities mentioned in Standards 6-8

**Testing**:
- Verify all cross-references point to valid sections in command_architecture_standards.md
- Confirm no conflicting guidance between documents (e.g., agent invocation pattern consistent)
- Check that terminology is consistent across all files (metadata-only passing, forward message pattern, etc.)
- Verify clear delineation: standards doc = mandates, related docs = examples/implementation

**Validation Criteria**:
- All 6 documentation files updated with appropriate cross-references
- Anti-Pattern 7 warning prominently placed in creating-commands.md and using-agents.md
- No duplicate content (hierarchical_agents.md details not repeated in standards doc)
- Consistent terminology used across all documents
- Clear relationship established: command_architecture_standards.md provides mandates, other docs provide implementation guidance

---

## Testing Strategy

### Test 1: Standards Consistency Check

**Verify no contradictions between new and existing standards**:

```bash
# Check that "metadata-only passing" doesn't contradict "template completeness"
grep -A 10 "Standard 4: Template Completeness" command_architecture_standards.md
grep -A 10 "Standard 6: Metadata-Only Passing" command_architecture_standards.md
# Manual review: Templates are for invocation, metadata is for response handling

# Check that "commands orchestrate patterns" doesn't contradict "executable instructions inline"
grep -A 10 "Standard 1: Executable Instructions" command_architecture_standards.md
grep -A 10 "Standard 9: Commands Orchestrate Patterns" command_architecture_standards.md
# Manual review: Pattern extraction applies to procedures, not execution logic
```

**Expected**: Clear distinction in each standard's scope, no logical conflicts

### Test 2: Example Completeness Validation

**Verify all examples are complete and actionable**:

```bash
# Check that bash examples are complete (not truncated)
grep -B 3 "```bash" command_architecture_standards.md | grep -c "..."
# Expected: 0 (no truncated examples)

# Check that examples have closing code fences
BASH_BLOCKS=$(grep -c "```bash" command_architecture_standards.md)
CLOSING_FENCES=$(grep -c "^```$" command_architecture_standards.md)
[[ $BASH_BLOCKS -eq $CLOSING_FENCES ]] && echo "All code blocks closed" || echo "Unclosed code blocks!"

# Verify utility references point to existing files
grep -oE '\.claude/lib/[a-z-]+\.sh' command_architecture_standards.md | while read util; do
  [[ -f "$util" ]] && echo "✓ $util exists" || echo "✗ $util missing"
done
```

**Expected**: All bash examples complete, all code blocks closed, all referenced utilities exist

### Test 3: Cross-Reference Integrity

**Verify all cross-references are accurate**:

```bash
# Extract all section references (e.g., "see Standard 6", "See Context Preservation Standards")
grep -oE '(see|See) (Standard [0-9]+|[A-Z][a-z ]+ Standards)' command_architecture_standards.md | sort -u
# Manual validation: Each reference points to existing section

# Check that pattern library references mention "to be created" if not exist
grep -oE '\.claude/templates/[a-z-]+\.md' command_architecture_standards.md | while read tmpl; do
  if [[ ! -f "$tmpl" ]]; then
    grep -B 2 -A 2 "$tmpl" command_architecture_standards.md | grep -q "to be created" && \
      echo "✓ $tmpl marked as 'to be created'" || \
      echo "✗ $tmpl missing and not marked"
  fi
done
```

**Expected**: All cross-references valid, missing files noted as "to be created"

### Test 4: Document Size Validation

**Verify document remains within target size**:

```bash
FILE_SIZE=$(wc -c < .claude/docs/command_architecture_standards.md)
FILE_SIZE_KB=$((FILE_SIZE / 1024))

echo "File size: ${FILE_SIZE_KB}KB"

# Target: 35-45KB (current 28KB + ~15KB additions)
if [[ $FILE_SIZE_KB -ge 35 && $FILE_SIZE_KB -le 45 ]]; then
  echo "✓ Within target range (35-45KB)"
elif [[ $FILE_SIZE_KB -lt 35 ]]; then
  echo "⚠ Below target (may be missing content)"
else
  echo "⚠ Above target (may need condensing)"
fi
```

**Expected**: 35-45KB final size

### Test 5: Practical Applicability Test

**Verify standards are actionable for refactoring decisions**:

**Scenario 1**: Developer wants to extract checkpoint initialization from `implement.md`

```bash
# Can developer determine if extraction is allowed?
# Check Standard 9 (Commands Orchestrate Patterns)
grep -A 20 "Standard 9:" command_architecture_standards.md | grep -q "utility initialization"
# Expected: YES (utility initialization listed as extractable procedure)
```

**Scenario 2**: Developer wants to extract phase execution workflow from `orchestrate.md`

```bash
# Can developer determine if extraction is allowed?
# Check Standard 1 (Executable Instructions Must Be Inline) and Standard 9
grep -A 20 "Standard 1:" command_architecture_standards.md | grep -q "execution procedures"
grep -A 20 "Standard 9:" command_architecture_standards.md | grep -q "workflow logic"
# Expected: NO (workflow logic is execution-critical, must stay inline per Standard 1)
```

**Scenario 3**: Developer wants to pass full research report to planning agent

```bash
# Can developer determine if this is allowed?
# Check Standard 6 (Metadata-Only Passing)
grep -A 20 "Standard 6:" command_architecture_standards.md | grep -q "metadata ONLY"
# Expected: NO (must extract metadata and pass artifact path, not full content)
```

**Expected**: Standards provide clear guidance for all 3 scenarios

## Documentation Requirements

**Files to Update**:

1. `.claude/docs/command_architecture_standards.md` (primary target - Phases 1-3)
   - Add 3 new standard sections: Context Preservation Standards (6-8), Lean Command Design Standards (9-11), Layered Context Architecture
   - Update anti-patterns section with Anti-Patterns 5-7
   - Update testing standards section with context usage validation
   - Update related standards section with utility library references
   - Add quick reference card for practical guidance

2. `.claude/docs/hierarchical_agents.md` (Phase 4)
   - Add cross-references to Standards 6-8 in relevant sections
   - Clarify relationship: implementation details vs architectural mandates

3. `.claude/docs/creating-commands.md` (Phase 4)
   - Add reference to complete standards (Standards 6-8, 9-11)
   - Add Anti-Pattern 7 warning about command-to-command calls
   - Add correct agent invocation pattern example
   - Update command size guidelines to reference Standard 11

4. `.claude/docs/creating-agents.md` (Phase 4)
   - Add Layered Context Architecture section
   - Explain meta-context layer role of agent definition files

5. `.claude/docs/using-agents.md` (Phase 4)
   - Add prominent Anti-Pattern 7 warning in agent invocation section
   - Add cross-reference to command_architecture_standards.md

6. `.claude/docs/orchestration-guide.md` (Phase 4)
   - Add cross-references to Standards 6-8 in artifact aggregation section
   - Add context usage validation criteria

7. `.claude/docs/development-workflow.md` (Phase 4)
   - Add cross-references to Standards 6 and 8 in spec updater and artifact lifecycle sections
   - Reference utility libraries mentioned in standards

**After Implementation**:
- Reference updated standards in future command refactoring plans
- Use updated standards for /orchestrate and /implement refactoring (Report 051 recommendations 6-7)
- All 7 documentation files will provide consistent, cross-referenced guidance on command architecture

## Dependencies

**Required Files** (must exist):
- ✅ `.claude/docs/command_architecture_standards.md` (target file)
- ✅ `.claude/specs/reports/051_command_architecture_context_preservation_standards.md` (source)
- ✅ `.claude/lib/artifact-operations.sh` (referenced utility)
- ✅ `.claude/lib/context-pruning.sh` (referenced utility)

**Optional Files** (noted as "to be created" if missing):
- `.claude/templates/bash-patterns.md` (referenced pattern library)
- `.claude/templates/implementation-patterns.md` (referenced pattern library)
- `.claude/templates/orchestration-patterns.md` (may already exist)

## Risk Assessment

### Risk 1: Standards Contradiction
**Severity**: High
**Probability**: Medium

**Issue**: New standards (metadata-only passing, pattern orchestration) might appear to contradict existing standards (template completeness, executable instructions inline)

**Mitigation**:
- Explicitly address tensions in Technical Design section
- Add "Reconciliation of Tensions" subsection showing how standards complement each other
- Include scope clarifications: "Template completeness applies to invocation; metadata passing applies to response handling"
- Add integration notes in each new standard: "This standard applies to X, not Y (see Standard N)"

**Contingency**: If contradiction detected during implementation, add clarifying notes immediately below conflicting standard

### Risk 2: Over-Prescription
**Severity**: Medium
**Probability**: Low

**Issue**: New standards might be too prescriptive, limiting command flexibility

**Mitigation**:
- Use "MUST" only for critical requirements (metadata passing, forward pattern)
- Use "SHOULD" for strong recommendations (pattern orchestration, DRY)
- Provide rationale for each mandate (context reduction %, maintenance benefits)
- Include "When to Apply" guidance in each standard

**Contingency**: If implementation reveals over-prescription, soften mandate to recommendation with rationale

### Risk 3: Incomplete Examples
**Severity**: Medium
**Probability**: Low

**Issue**: Bash examples might be incomplete or untested, leading to copy-paste errors

**Mitigation**:
- Extract examples directly from Report 051 (already validated)
- Ensure all bash examples include complete context (variable definitions, function calls)
- Test bash examples for syntax errors before adding to standards
- Add comments to bash examples explaining each step

**Contingency**: If example incomplete, expand with missing context or add "Note: Assumes X is defined"

### Risk 4: Document Bloat
**Severity**: Low
**Probability**: Medium

**Issue**: Adding ~15KB of new content might make document too long (>45KB)

**Mitigation**:
- Use concise language, avoid redundancy
- Move extensive examples to Report 051 with references
- Use bullet points and tables instead of paragraphs where possible
- Condense existing sections if new content exceeds target

**Contingency**: If document exceeds 50KB, extract detailed examples to separate reference file (e.g., `context-preservation-examples.md`)

## Critical New Findings: Command-to-Subagent Delegation

### Anti-Pattern: Commands Calling Other Commands

**Discovery**: Current branch orchestrate.md (line 1049, 1081) instructs agents to call other commands using SlashCommand tool:
```markdown
- Agent invokes /plan slash command
2. Invoke SlashCommand: /plan "${WORKFLOW_DESC}" ${RESEARCH_REPORT_PATHS[@]}
```

**Problem**: This breaks context preservation because:
1. Each command call creates a new agent context
2. Primary orchestrator loses visibility into subagent work
3. Context window gets fragmented across command invocations
4. Cannot apply metadata-only passing between command boundaries

**Master Branch Solution**: Master branch (commit 8fe34aa) uses direct subagent invocation with behavioral injection instead of calling commands.

### Correct Pattern: Behavioral Injection with general-purpose

**Pattern** (from master branch `.claude/docs/agent-integration-guide.md`):
```yaml
Task {
  subagent_type: "general-purpose"  # ALWAYS use general-purpose
  description: "Create plan using plan-architect protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/plan-architect.md

    You are acting as a Plan Architect with the constraints and
    capabilities defined in that file.

    [Your actual task description here]
}
```

**Why This Works**:
- Agent behaviors defined in `.claude/agents/*.md` files
- Task tool only supports: `general-purpose`, `statusline-setup`, `output-style-setup`
- Specialized behaviors (research-specialist, plan-architect, code-writer, etc.) invoked via behavioral injection
- Primary agent maintains full visibility into subagent execution
- Enables metadata-only passing and context preservation

**Incorrect Pattern** (causes "Agent type not found" errors):
```yaml
Task {
  subagent_type: "plan-architect"  # ERROR: Not valid
  ...
}
```

### Master Branch Architecture Lessons

**What Worked Better in Master Branch**:

1. **External Reference Files**:
   - `.claude/templates/orchestration-patterns.md` contains complete agent prompt templates
   - Commands reference templates with placeholders: `[THINKING_MODE]`, `[TOPIC_TITLE]`, `[ABSOLUTE_REPORT_PATH]`
   - Commands stay lean (orchestrate.md ~5-10KB vs current 110KB)

2. **Direct Subagent Invocation**:
   - Commands invoke subagents directly (no `/plan`, `/implement`, `/debug` calls)
   - Subagents create artifacts directly using Write tool
   - Agent prompts tell agents: "You MUST create a research report file using the Write tool"

3. **Metadata-Based Coordination**:
   - Agents return: `REPORT_PATH: /absolute/path/to/report.md`
   - Primary extracts metadata from artifact path
   - Context stays minimal in orchestrator

**Integration with Plan 067**:

Add new Anti-Pattern 7 in Phase 3:

**Anti-Pattern 7: Commands Calling Other Commands**

**❌ BAD** (Current branch orchestrate.md:1081):
```markdown
## Planning Phase
Agent should invoke SlashCommand tool:
```yaml
SlashCommand {
  command: "/plan \"${WORKFLOW_DESC}\" ${RESEARCH_REPORT_PATHS[@]}"
}
```
```

**✅ GOOD** (Master branch pattern):
```markdown
## Planning Phase
Invoke subagent directly with behavioral injection:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create plan using plan-architect protocol"
  prompt: |
    Read and follow: /home/benjamin/.config/.claude/agents/plan-architect.md

    You are acting as a Plan Architect.

    Workflow: ${WORKFLOW_DESC}
    Research Reports: ${RESEARCH_REPORT_PATHS[@]}

    Create implementation plan at: ${PLAN_PATH}

    [Complete task instructions...]
}
```
```

**Why This Matters**:
- Calling `/plan` command creates separate agent → context fragmentation
- Direct subagent invocation keeps context in orchestrator → enables metadata passing
- Primary agent can extract metadata from subagent response → <30% context usage

**Commit Reference**: git commit 8fe34aa "fix agent invocation patterns to use general-purpose with behavioral injection" updated 19 files to use correct pattern.

## Notes

### Integration with Existing Standards

This revision **complements** existing standards, not replaces them. The document's core message remains: "Command files are AI execution scripts that must be directly executable by Claude."

New standards add **context efficiency** requirements while preserving **execution completeness** requirements:

- **Standard 1** (existing): Execution steps must be inline → **Standard 9** (new): But procedures can be externalized
- **Standard 4** (existing): Templates must be complete → **Standard 6** (new): But responses should be minimized
- **Anti-Pattern 1** (existing): No reference-only sections → **Anti-Pattern 5** (new): No paraphrasing in responses
- **NEW Anti-Pattern 7** (add in Phase 3): No commands calling other commands (use direct subagent invocation)

### Relationship to Report 051 Recommendations

This plan addresses **Immediate Action #1** from Report 051:

> Update `command_architecture_standards.md` with metadata-only passing mandates

This plan **does NOT**:
- Extract bloated inline procedures (Immediate Action #2) - separate refactoring plan needed
- Standardize subagent invocation (Immediate Action #3) - separate implementation plan needed
- Implement context pruning utilities (Immediate Action #4) - already implemented in Plan 057

**Next Steps After This Plan**:
- Create implementation plans for /orchestrate and /implement refactoring (Report 051 recommendations 6-7)
- Create bash-patterns.md and implementation-patterns.md pattern libraries (Report 051 recommendation 5)

### Preservation of Existing Tone

The document's assertive, prescriptive tone will be preserved:
- Use "CRITICAL", "MUST", "NEVER" for mandates
- Use ✅ and ❌ markers for examples
- Maintain existing BAD/GOOD example structure
- Keep structural annotations ([EXECUTION-CRITICAL], etc.)

New standards will match this tone to maintain consistency.

---

**Plan Created**: 2025-10-17
**Based on Research**: Report 051 (3 parallel research agents, 45 minutes)
**Target Implementation Time**: 3-4 hours (3 phases, medium complexity per phase)
**Next Implementation Step**: `/implement .claude/specs/plans/067_revise_command_architecture_standards.md`
