# Documentation Improvements: Template vs Behavioral Distinction

## Metadata
- **Date**: 2025-10-24
- **Last Revised**: 2025-10-24 (Revision 2: Reorganized phase order for logical execution flow)
- **Feature**: Documentation improvements for structural template vs behavioral content distinction
- **Scope**: Update .claude/docs/ to clarify when inline templates are appropriate vs when behavioral injection is required; apply standards to /supervise command
- **Estimated Phases**: 7 (reorganized for optimal execution order)
- **Phase Execution Order**: Foundation docs → Real-world application → Guides → Troubleshooting → Quick reference → Validation → Navigation
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - `.claude/specs/441_template_usage_patterns_docs_analysis/reports/001_template_patterns_research/OVERVIEW.md`
  - `.claude/specs/441_template_usage_patterns_docs_analysis/reports/001_template_patterns_research/001_inline_template_patterns_and_usage.md`
  - `.claude/specs/441_template_usage_patterns_docs_analysis/reports/001_template_patterns_research/002_behavioral_injection_reference_patterns.md`
  - `.claude/specs/441_template_usage_patterns_docs_analysis/reports/001_template_patterns_research/003_template_vs_behavioral_decision_criteria.md`
- **Diagnostic Reports**:
  - `.claude/specs/444_research_allowed_tools_fix/reports/001_research/OVERVIEW.md` (Pattern mismatch in spec 438 supervise refactor)

## Overview

Implement comprehensive documentation improvements to clarify the critical architectural distinction between:

1. **Structural Templates** (MUST be inline): Task invocation syntax, bash execution blocks, JSON schemas, verification checkpoints, "EXECUTE NOW" markers
2. **Behavioral Content** (MUST be referenced): Agent step-by-step procedures, file creation workflows, verification steps within agent behavior, output format specifications

Research findings show this distinction resolves documentation ambiguity and enables 90% code reduction per agent invocation (150 lines → 15 lines) through proper behavioral injection pattern application.

## Success Criteria

- [ ] New template-vs-behavioral-distinction.md reference document provides clear, actionable guidance
- [ ] All high-priority documentation updated with consistent structural/behavioral terminology
- [ ] Structural vs behavioral distinction explicitly documented in 5+ places across .claude/docs/
- [ ] Troubleshooting guide provides concrete remediation steps for anti-pattern detection
- [ ] Cross-references and navigation updated throughout docs/ hierarchy
- [ ] Optional validation script (if implemented) detects anti-pattern with <5% false positives

## Technical Design

### Core Concepts

**Structural Templates** (inline required):
- Execution-critical patterns that Claude must see immediately
- Examples: Task { }, bash code blocks, JSON schemas
- Purpose: Direct execution, structural parsing
- Location: Inline in command files

**Behavioral Content** (reference required):
- Agent execution procedures and workflows
- Examples: STEP 1/2/3 sequences, PRIMARY OBLIGATION blocks, verification procedures
- Purpose: Agent behavioral guidelines
- Location: `.claude/agents/*.md` files, referenced via behavioral injection

### Key Metrics from Research

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Code per invocation | 150 lines | 15 lines | 90% reduction |
| Context usage | 85% | 25% | 71% reduction |
| File creation rate | 70% | 100% | 43% improvement |
| Maintenance burden | Baseline | -50-67% | 50-67% reduction |

### Documentation Architecture

```
.claude/docs/
├── reference/
│   ├── template-vs-behavioral-distinction.md    [NEW - Core reference]
│   └── command_architecture_standards.md         [UPDATE - Add Standard 12]
├── concepts/patterns/
│   └── behavioral-injection.md                   [UPDATE - Add clarification]
├── guides/
│   ├── execution-enforcement-guide.md            [UPDATE - Add context]
│   ├── agent-development-guide.md                [UPDATE - Add SoT section]
│   └── command-development-guide.md              [UPDATE - Add reference]
├── troubleshooting/
│   └── inline-template-duplication.md            [NEW - Detection/remediation]
├── quick-reference/
│   └── template-usage-decision-tree.md           [NEW - Quick decisions]
└── tests/
    └── validate_no_behavioral_duplication.sh     [NEW - Optional validation]
```

## Implementation Phases

### Phase 1: Create Core Reference Documentation (High Priority) [COMPLETED]

**Objective**: Establish authoritative documentation for structural vs behavioral distinction

**Status**: COMPLETED

**Complexity**: Medium

**Estimated Time**: 2-3 hours

#### Tasks

- [x] Create `.claude/docs/reference/template-vs-behavioral-distinction.md`
  - Add metadata section (date, scope, purpose, related documents)
  - Define structural templates with characteristics and examples
    - Task invocation syntax: `Task { subagent_type, description, prompt }`
    - Bash execution blocks: `**EXECUTE NOW**: bash code blocks`
    - JSON schemas: Data structures for agent communication
    - Verification checkpoints: `**MANDATORY VERIFICATION**: file existence checks`
    - Critical warnings: `**CRITICAL**: error conditions and constraints`
  - Define behavioral content with characteristics and examples
    - Agent procedures: STEP 1/2/3 sequences
    - File creation workflows: PRIMARY OBLIGATION blocks
    - Verification steps: Agent-internal verification logic
    - Output specifications: Template formats for agent outputs
  - Provide side-by-side comparison table
  - Include decision tree: "Should this be inline?" → flow chart
  - Document quantified benefits (90% reduction, 71% context savings, 100% file creation rate)
  - Add "See Also" section linking to behavioral-injection.md and command-architecture-standards.md

- [x] Update `.claude/docs/concepts/patterns/behavioral-injection.md`
  - Add new section "Structural Templates vs Behavioral Content" after line 185 (after "Usage Context" section)
  - Clarify that Anti-Pattern Violation 0 is about behavioral duplication, not structural templates
  - Add subsection "Valid Inline Templates" with examples:
    - Task invocation blocks (structural, not behavioral)
    - Bash execution blocks (commands must execute these)
    - Verification checkpoints (orchestrator responsibility)
  - Update "Benefits" section to emphasize distinction:
    - "90% reduction applies to behavioral content, not structural templates"
    - "Structural templates remain inline for immediate execution"
  - Add cross-reference to new template-vs-behavioral-distinction.md

- [x] Update `.claude/docs/reference/command_architecture_standards.md`
  - Add new Standard 12: "Structural vs Behavioral Content Separation" after Standard 11
  - Define requirement: "Commands MUST include structural templates inline"
    - List what qualifies as structural: Task syntax, bash blocks, schemas, warnings
    - Rationale: Immediate execution and parsing requirements
  - Define prohibition: "Commands MUST NOT duplicate behavioral content"
    - List what qualifies as behavioral: Agent procedures, file workflows, output specs
    - Rationale: Single source of truth, maintenance burden, context bloat
  - Include enforcement section:
    - Validation criteria: Count STEP instructions in commands (<5), agent invocation size (<50 lines)
    - Metrics: 90% reduction per invocation when properly applied
    - Detection: validate_no_behavioral_duplication.sh (if implemented)
  - Add "Exceptions" subsection: "NONE - Zero documented exceptions to this standard"
  - Reference template-vs-behavioral-distinction.md for detailed guidance

**Testing**:
```bash
# Verify internal consistency
grep -n "structural\|behavioral" .claude/docs/reference/template-vs-behavioral-distinction.md | wc -l
# Expect: >20 mentions (comprehensive coverage)

# Verify cross-references exist
grep -l "template-vs-behavioral-distinction.md" .claude/docs/concepts/patterns/behavioral-injection.md
grep -l "template-vs-behavioral-distinction.md" .claude/docs/reference/command_architecture_standards.md

# Validate no broken links
for file in .claude/docs/reference/template-vs-behavioral-distinction.md \
            .claude/docs/concepts/patterns/behavioral-injection.md \
            .claude/docs/reference/command_architecture_standards.md; do
  echo "Checking $file for broken links..."
  grep -o '\[.*\](\..*\.md)' "$file" | while read link; do
    path=$(echo "$link" | sed 's/.*(\(.*\))/\1/')
    if [ ! -f "$(dirname "$file")/$path" ]; then
      echo "  BROKEN: $link in $file"
    fi
  done
done
```

---

### Phase 2: Apply Standards to /supervise Command (Critical Priority - Real-World Validation) [COMPLETED]

**Objective**: Fix /supervise command to comply with structural vs behavioral distinction standards using diagnostic findings from spec 444

**Status**: COMPLETED

**Complexity**: High

**Estimated Time**: 3-4 hours

**Context**: Diagnostic report (spec 444/001/OVERVIEW.md) identified critical issues in supervise refactor plan (spec 438/001):
- Incorrect search pattern blocks Phase 1 implementation
- Plan searches for non-existent "Example agent invocation:" pattern
- Actual file has 7 YAML blocks with different patterns
- Regression test gives false pass (searches wrong pattern)
- Need to apply structural/behavioral distinction to determine which YAML blocks to keep vs remove

#### Tasks

**Task 2.1: Analyze Current /supervise YAML Blocks Against Standards**

- [x] Read current `.claude/commands/supervise.md` to identify all 7 YAML blocks
  - [x] Lines 49, 63: Documentation examples (Wrong vs Correct patterns)
  - [x] Line 682: Research agent template
  - [x] Line 1082: Planning agent template
  - [x] Line 1440: Implementation agent template
  - [x] Line 1721: Testing agent template
  - [x] Line 2246: Documentation agent template

- [x] Classify each YAML block per structural vs behavioral distinction:
  - [x] **Documentation examples (lines 49, 63)**: Determine if these are structural templates (keep) or behavioral duplication (remove)
    - Analysis: These show Task invocation SYNTAX (structural) but may include behavioral STEP sequences
    - Decision needed: Keep Task structure, remove embedded STEP sequences?
  - [x] **Agent templates (lines 682+)**: These are BEHAVIORAL content (must be removed)
    - Contains: STEP 1/2/3 sequences, PRIMARY OBLIGATION blocks, verification procedures
    - Target: Extract to `.claude/agents/*.md` files, replace with context injection references

- [x] Document classification results in diagnostic addendum:
  - [x] Create `.claude/specs/444_research_allowed_tools_fix/reports/001_research/supervise_yaml_classification.md`
  - [x] For each block: Location, type (structural/behavioral), keep/remove decision, rationale
  - [x] Include line-by-line breakdown showing which parts are structural vs behavioral

**Task 2.2: Create Corrected Refactor Instructions for /supervise**

- [x] Create new implementation guide: `.claude/specs/444_research_allowed_tools_fix/plans/001_supervise_refactor_corrected.md`
  - [x] **Phase 0: Pattern Verification** (from Recommendation 4)
    - [x] Add grep commands to verify actual patterns before implementation
    - [x] Test for `Example agent invocation:` (expect 0)
    - [x] Test for ` ```yaml` (expect 7)
    - [x] Test for YAML + Task combination (expect 7)
    - [x] Exit with error if patterns don't match expectations

  - [x] **Phase 1: Fix Documentation Examples** (Lines 49-89)
    - [x] Decision: RETAIN Task invocation syntax (structural), REMOVE any embedded STEP sequences (behavioral)
    - [x] Update line 49-82 example to show pure context injection (no behavioral procedures)
    - [x] Ensure examples reference `.claude/agents/*.md` files instead of duplicating procedures
    - [x] Validate: Examples demonstrate correct pattern per template-vs-behavioral-distinction.md

  - [x] **Phase 2: Extract Agent Behavioral Content** (Lines 682, 1082, 1440, 1721, 2246)
    - [x] For EACH of 5 agent templates:
      - [x] **Step 1**: Extract behavioral content (STEP sequences, PRIMARY OBLIGATION blocks)
      - [x] **Step 2**: Verify corresponding agent file in `.claude/agents/` contains this content
      - [x] **Step 3**: If content missing from agent file, add it (research-specialist.md, plan-architect.md, etc.)
      - [x] **Step 4**: Replace inline template with lean context injection (10-15 lines)
      - [x] **Step 5**: Validate reduction: ~90% fewer lines per invocation
    - [x] Target: 150 lines → 15 lines per invocation (consistent with research metrics)

  - [x] **Phase 3: Update Regression Test** (from Recommendation 2)
    - [x] Fix `.claude/tests/test_supervise_delegation.sh:78`
    - [x] Replace search for "Example agent invocation:" with actual pattern:
      ```bash
      # Exclude first 100 lines (documentation section)
      YAML_BLOCKS=$(tail -n +100 "$SUPERVISE_FILE" | grep -c '```yaml')
      ```
    - [x] Add test: Verify "Example agent invocation:" stays at 0 (anti-pattern eliminated)
    - [x] Expected after refactor: 2 YAML blocks (documentation examples), 0 agent templates

  - [x] **Success Criteria**:
    - [x] Pattern verification passes before implementation begins
    - [x] Documentation examples retain structural syntax, remove behavioral duplication
    - [x] 5 agent templates replaced with context injection references
    - [x] 90% line reduction achieved (750+ lines removed)
    - [x] Regression test detects actual patterns (not false pass)
    - [x] All agent behavioral content in `.claude/agents/*.md` files (single source of truth)

**Task 2.3: Document /supervise as Case Study**

- [x] Add /supervise case study to `.claude/docs/troubleshooting/inline-template-duplication.md`
  - [x] New section: "Real-World Example: /supervise Command Refactor"
  - [x] Problem: Plan 438 blocked due to search pattern mismatch
  - [x] Root cause: Incorrect assumptions about file patterns
  - [x] Solution: Pattern verification + structural/behavioral classification
  - [x] Results: 90% code reduction, correct pattern application
  - [x] Lessons learned:
    - [x] Always verify search patterns exist before planning replacements
    - [x] Use Grep to extract actual strings, not inferred descriptions
    - [x] Classify YAML blocks as structural vs behavioral before deciding keep/remove
    - [x] Pattern verification in Phase 0 prevents wasted implementation effort

- [x] Update `.claude/docs/reference/template-vs-behavioral-distinction.md`
  - [x] Add subsection under "Common Pitfalls": "Search Pattern Mismatches in Refactoring"
  - [x] Reference /supervise diagnostic (spec 444/001) as example
  - [x] Key insight: "Example agent invocation:" pattern assumed but never existed
  - [x] Prevention: Pattern verification step before implementation
  - [x] Link to corrected refactor plan (spec 444/001/plans)

**Task 2.4: Update Spec 438 Plan with Corrections**

- [ ] Option A: Create addendum to spec 438/001 referencing spec 444 corrections
  - [ ] Add section "Plan Revision - Pattern Corrections" to 438/001/001_supervise_command_refactor_integration.md
  - [ ] Reference diagnostic report: spec 444/001/OVERVIEW.md
  - [ ] Reference corrected plan: spec 444/001/plans/001_supervise_refactor_corrected.md
  - [ ] Mark Phase 1 as "BLOCKED - See spec 444 for corrected implementation"
  - [ ] Preserve original plan as historical record (don't delete incorrect patterns)

- [x] Option B: Use /revise on spec 438 plan directly (CHOSEN)
  - [x] Run: `/revise "Fix search patterns per spec 444 diagnostic" specs/444_research_allowed_tools_fix/reports/001_research/OVERVIEW.md`
  - [x] Updated 438 plan with corrected patterns inline
  - [x] Added Revision 3 history documenting pattern corrections
  - [x] Preferred for single source of truth implementation

- [x] **Decision**: Choose Option B (inline revision) for single source of truth
  - [x] Rationale: Maintains plan as standalone implementation guide
  - [x] Benefit: No need to track separate corrected plan (spec 444)
  - [x] Educational value: Revision history shows pattern correction process
  - [x] Result: Plan is now READY FOR IMPLEMENTATION with corrected patterns

**Testing**:
```bash
# Verify classification document created
test -f .claude/specs/444_research_allowed_tools_fix/reports/001_research/supervise_yaml_classification.md

# Verify corrected plan created
test -f .claude/specs/444_research_allowed_tools_fix/plans/001_supervise_refactor_corrected.md

# Verify case study added to troubleshooting
grep -A 10 "Real-World Example: /supervise Command Refactor" \
  .claude/docs/troubleshooting/inline-template-duplication.md

# Verify pattern verification step exists in corrected plan
grep -A 5 "Phase 0: Pattern Verification" \
  .claude/specs/444_research_allowed_tools_fix/plans/001_supervise_refactor_corrected.md

# Test pattern verification commands work
cd .claude/commands
grep -c "Example agent invocation:" supervise.md  # Expect: 0
grep -c '```yaml' supervise.md  # Expect: 7
tail -n +100 supervise.md | grep -c '```yaml'  # Expect: 5 (agent templates only)
```

**Success Criteria**:
- [x] All 7 YAML blocks classified as structural or behavioral
- [x] Corrected refactor plan created with pattern verification step
- [x] /supervise case study documented in troubleshooting guide
- [x] Spec 438 plan updated with addendum referencing corrections
- [x] Pattern verification commands validated on actual file
- [x] Educational value captured for future refactoring efforts

---

### Phase 3: Update Enforcement and Development Guides (High Priority) [COMPLETED]

**Objective**: Align existing guides with new structural/behavioral distinction

**Status**: COMPLETED

**Complexity**: Medium

**Estimated Time**: 2-3 hours

#### Tasks

- [x] Update `.claude/docs/guides/execution-enforcement-guide.md`
  - Add clarifying header in Overview section (after line 23):
    - Section title: "Agent Behavioral Patterns vs Command Structural Patterns"
    - Explanation: "This guide shows both agent behavioral patterns (for agent files) and command structural patterns (for command files). Context determines which applies."
    - Table showing which sections apply to which file types
  - Update Pattern 1-4 descriptions (lines 140-220) to specify context:
    - Pattern 1 (Step Dependencies): "For agent files: STEP N REQUIRED BEFORE STEP N+1"
    - Pattern 2 (Execution Blocks): "For command files: EXECUTE NOW markers"
    - Pattern 3 (File-First Creation): "For agent files: file creation behavioral guidelines"
    - Pattern 4 (Verification Checkpoints): "For command files: MANDATORY VERIFICATION blocks"
  - Add references to behavioral-injection.md for command examples (line ~100)
  - Add warning box: "⚠️ IMPORTANT: Do not duplicate agent behavioral patterns (STEP sequences) in command prompts. Reference agent files via behavioral injection instead."

- [x] Update `.claude/docs/guides/agent-development-guide.md`
  - Add new section "Agent Files as Single Source of Truth" after "Agent Architecture" section
    - Principle: Agent behavioral files should contain ALL execution procedures
    - Commands reference these files; don't excerpt or summarize in commands
    - Benefits: 90% reduction, no synchronization burden, single source of truth
    - Example showing behavioral file + command reference (not duplication)
  - Update "Creating New Agents" section with note:
    - "Agent files are the ONLY location for behavioral guidelines"
    - "Commands invoke agents via 'Read and follow ALL behavioral guidelines from: .claude/agents/[name].md'"
    - "Never duplicate STEP sequences, PRIMARY OBLIGATION blocks, or verification procedures in command prompts"
  - Add cross-reference to template-vs-behavioral-distinction.md in introduction
  - Update examples to show context injection only (not behavioral duplication)

- [ ] Update `.claude/docs/guides/command-development-guide.md`
  - Add reference to template-vs-behavioral-distinction.md in Section 7 (Common Patterns)
  - Update Section 7.1 example (lines 737-765) to add note:
    - "✓ CORRECT: This example shows context injection only"
    - "✗ INCORRECT: Do not add STEP 1/2/3 instructions inline (reference behavioral file instead)"
  - Add new subsection "When to Use Inline Templates" after Section 7.1:
    - Structural templates: Task blocks, bash execution, verification checkpoints
    - These are command responsibilities, not agent procedures
    - Link to template-vs-behavioral-distinction.md for decision criteria
  - Update "Agent Integration" checklist (lines 705-710):
    - Change "Agents invoked using behavioral injection" to "Agents invoked with context injection only (no behavioral duplication)"
    - Add item: "Agent prompts reference behavioral files, contain NO STEP sequences"

**Testing**:
```bash
# Verify guides updated
grep -n "Agent Files as Single Source of Truth" .claude/docs/guides/agent-development-guide.md
grep -n "Agent Behavioral Patterns vs Command Structural Patterns" .claude/docs/guides/execution-enforcement-guide.md

# Check for remaining problematic examples (should find 0 after updates)
grep -r "STEP 1.*STEP 2.*STEP 3" .claude/docs/guides/*.md | grep -v "agent-development-guide\|execution-enforcement-guide"

# Verify cross-references to new distinction doc
grep -l "template-vs-behavioral-distinction" .claude/docs/guides/*.md | wc -l
# Expect: 3 (execution-enforcement, agent-development, command-development)
```

---

### Phase 4: Create Troubleshooting Guide (Medium Priority) [COMPLETED]

**Objective**: Help developers identify and fix inline duplication anti-pattern

**Status**: COMPLETED

**Complexity**: Low

**Estimated Time**: 1-2 hours

#### Tasks

- [x] Create `.claude/docs/troubleshooting/inline-template-duplication.md`
  - Add metadata header:
    - Problem Type: Anti-Pattern
    - Symptoms: Large command files, maintenance burden, synchronization issues
    - Severity: Medium
    - Fix Time: 15-30 minutes per command
  - Create "Quick Diagnosis" section with symptoms checklist:
    - [ ] Command file >2000 lines with multiple agent invocations
    - [ ] Agent invocation prompts >100 lines each
    - [ ] STEP 1/2/3 sequences embedded in command prompts
    - [ ] PRIMARY OBLIGATION or ABSOLUTE REQUIREMENT in command files
    - [ ] Duplicate behavioral guidelines across multiple commands
  - Add "Root Cause" section:
    - Issue: Behavioral content duplicated inline instead of referenced
    - Pattern: Commands contain STEP sequences that belong in agent files
    - Why it happens: Unclear distinction between structural and behavioral content
  - Create "Detection" section with grep commands:
    ```bash
    # Detect inline STEP sequences in commands
    grep -c "STEP 1.*STEP 2" .claude/commands/*.md

    # Detect PRIMARY OBLIGATION outside agent files
    grep -r "PRIMARY OBLIGATION" .claude/commands/

    # Find large agent invocations (>50 lines)
    awk '/Task \{/,/\}/ {count++} /\}/ {if (count > 50) print FILENAME; count=0}' .claude/commands/*.md
    ```
  - Add "Refactoring Process" section:
    - Step 1: Identify behavioral content in command (STEP sequences, workflows)
    - Step 2: Extract to appropriate agent file in `.claude/agents/`
    - Step 3: Update command to reference agent file with context injection only
    - Step 4: Validate reduction (expect ~90% line reduction per invocation)
    - Step 5: Test command execution to verify agent receives guidelines
  - Include before/after example using real content:
    - Before: 150-line agent invocation with inline STEP sequences
    - After: 15-line agent invocation with behavioral file reference
    - Metrics: Lines reduced, maintenance burden eliminated
  - Add "Prevention" section:
    - Use behavioral injection pattern for all agent invocations
    - Reference template-vs-behavioral-distinction.md before creating commands
    - Run validate_no_behavioral_duplication.sh (if available) before commits
    - Code review checklist item: "No behavioral duplication in commands"

- [x] Update `.claude/docs/troubleshooting/README.md`
  - Add new entry in Anti-Pattern section (or create section if not exists):
    - Title: "Inline Template Duplication"
    - Link: `[inline-template-duplication.md](./inline-template-duplication.md)`
    - Category: "Anti-Pattern Detection and Remediation"
    - Priority: Medium (affects maintainability, not functionality)

**Testing**:
```bash
# Verify troubleshooting guide created
test -f .claude/docs/troubleshooting/inline-template-duplication.md && echo "✓ File exists"

# Test detection commands from guide
grep -c "STEP 1.*STEP 2" .claude/commands/supervise.md
# Expect: 0 (if supervise refactor completed, otherwise >0 for validation)

# Verify README updated
grep "inline-template-duplication" .claude/docs/troubleshooting/README.md
```

---

### Phase 5: Create Quick Reference Materials (Low Priority) [COMPLETED]

**Objective**: Provide fast access to decision guidance

**Status**: COMPLETED

**Complexity**: Low

**Estimated Time**: 1-2 hours

#### Tasks

- [x] Create `.claude/docs/quick-reference/` directory (if not exists)
  ```bash
  mkdir -p .claude/docs/quick-reference
  ```

- [x] Create `.claude/docs/quick-reference/template-usage-decision-tree.md`
  - Add metadata header with purpose and scope
  - Create ASCII decision tree:
    ```
    Should this content be inline in command file?
                     │
                     ├─ Is it STRUCTURAL? (Task syntax, bash blocks, schemas, checkpoints)
                     │  └─ YES → Inline in command file ✓
                     │
                     └─ Is it BEHAVIORAL? (STEP sequences, workflows, procedures)
                        └─ NO → Reference agent file via behavioral injection ✓
    ```
  - Add "Common Scenarios" quick reference table:
    | Content Type | Inline? | Rationale | Example |
    |--------------|---------|-----------|---------|
    | Task invocation structure | YES | Structural execution | `Task { subagent_type, description, prompt }` |
    | Bash execution blocks | YES | Command must execute | `**EXECUTE NOW**: bash code` |
    | Verification checkpoints | YES | Orchestrator responsibility | `**MANDATORY VERIFICATION**: file check` |
    | JSON schemas | YES | Data structure parsing | `{ "field": "value" }` |
    | Critical warnings | YES | Execution-critical | `**CRITICAL**: error condition` |
    | Agent STEP sequences | NO | Behavioral guidelines | Reference .claude/agents/[name].md |
    | File creation workflows | NO | Agent procedures | Reference .claude/agents/[name].md |
    | PRIMARY OBLIGATION blocks | NO | Agent behavioral | Reference .claude/agents/[name].md |
    | Output format templates | NO | Agent responsibility | Reference .claude/agents/[name].md |
  - Add "Quick Test" section:
    - Question: "If I change this content, where do I update it?"
    - If answer is "multiple places" → WRONG (should be referenced, not inline)
    - If answer is "only here" → Depends (structural YES, behavioral NO)
  - Link to full template-vs-behavioral-distinction.md for detailed guidance

- [ ] Update `.claude/docs/README.md`
  - Add "Quick Reference" section after "Guides" section:
    ```markdown
    ## Quick Reference
    - [Template Usage Decision Tree](./quick-reference/template-usage-decision-tree.md) - Fast decisions for inline vs reference
    ```
  - Add template-vs-behavioral-distinction.md to "Core Concepts" section (or create if not exists):
    ```markdown
    ## Core Concepts
    - [Template vs Behavioral Distinction](./reference/template-vs-behavioral-distinction.md) - Critical architectural principle
    - [Behavioral Injection Pattern](./concepts/patterns/behavioral-injection.md) - Reference behavioral files, inject context
    ```

**Testing**:
```bash
# Verify quick reference created
test -f .claude/docs/quick-reference/template-usage-decision-tree.md && echo "✓ Decision tree created"

# Verify README links
grep "template-usage-decision-tree" .claude/docs/README.md
grep "template-vs-behavioral-distinction" .claude/docs/README.md

# Test decision tree answers with example scenarios
# Scenario 1: Task block → Should be inline (structural)
# Scenario 2: STEP 1/2/3 in agent invocation → Should reference agent file (behavioral)
# Validate decision tree gives correct answers for both
```

---

### Phase 6: Optional Validation Tooling (Low Priority)

**Objective**: Automate detection of behavioral duplication anti-pattern

**Status**: PENDING

**Complexity**: Medium

**Estimated Time**: 2-3 hours

#### Tasks

- [ ] Create `.claude/tests/validate_no_behavioral_duplication.sh`
  - Add script header with usage and description
  - Implement detection checks:

    **Check 1: Count STEP instructions in command files**
    ```bash
    for file in .claude/commands/*.md; do
      step_count=$(grep -c "STEP [0-9]" "$file")
      if [ "$step_count" -gt 5 ]; then
        echo "⚠️  WARNING: $file has $step_count STEP instructions (expect <5)"
      fi
    done
    ```

    **Check 2: Detect PRIMARY OBLIGATION outside agent files**
    ```bash
    if grep -r "PRIMARY OBLIGATION" .claude/commands/ --include="*.md"; then
      echo "❌ FAIL: PRIMARY OBLIGATION found in command files (should only be in agent files)"
      exit 1
    fi
    ```

    **Check 3: Find behavioral file content duplicated in commands**
    ```bash
    # Extract first 50 chars of each STEP from agent files
    # Search for those patterns in command files
    # Flag if found (indicates duplication)
    ```

    **Check 4: Calculate agent invocation size**
    ```bash
    # Use awk to extract Task { ... } blocks
    # Count lines between Task { and closing }
    # Flag if >50 lines (indicates inline behavioral content)
    awk '/Task \{/,/^\}$/ {
      if (/Task \{/) { start=NR; file=FILENAME }
      if (/^\}$/ && start>0) {
        size=NR-start
        if (size > 50) print "⚠️  WARNING: " file " has " size "-line Task invocation (expect <50)"
        start=0
      }
    }' .claude/commands/*.md
    ```

    **Check 5: Detect "Read and follow" without context-only prompt**
    ```bash
    # Find "Read and follow: .claude/agents/" lines
    # Check if followed by STEP sequences (wrong) or context injection (correct)
    ```

  - Generate summary report:
    - Total commands scanned
    - Issues found by category
    - Suggested fixes with file locations
    - Pass/fail status

  - Add example output format:
    ```
    ═══════════════════════════════════════════════════════
      Behavioral Duplication Validation
    ═══════════════════════════════════════════════════════

    Scanned: 15 command files

    ✓ PASS: No PRIMARY OBLIGATION in command files
    ⚠️  WARNING: 2 commands have >5 STEP instructions
        - .claude/commands/orchestrate.md: 7 STEP instructions
        - .claude/commands/supervise.md: 9 STEP instructions
    ⚠️  WARNING: 1 command has large agent invocation
        - .claude/commands/report.md: 150-line Task block

    Suggested fixes:
    1. Extract STEP sequences to agent behavioral files
    2. Update commands to reference agent files with context injection
    3. Validate reduction (expect ~90% line reduction per invocation)

    See: .claude/docs/troubleshooting/inline-template-duplication.md
    ```

- [ ] Update `.claude/tests/run_all_tests.sh`
  - Add validation script to test suite:
    ```bash
    # Behavioral duplication validation (warning only)
    echo "Running behavioral duplication validation..."
    if .claude/tests/validate_no_behavioral_duplication.sh; then
      echo "✓ No behavioral duplication detected"
    else
      echo "⚠️  Behavioral duplication detected (see output above)"
      echo "   This is a warning, not a failure"
      echo "   See: .claude/docs/troubleshooting/inline-template-duplication.md"
    fi
    ```
  - Configure as warning (not failure) initially to avoid breaking CI
  - Add comment explaining future transition to error

- [ ] Create `.claude/docs/guides/documentation-review-checklist.md`
  - Add metadata header with purpose
  - Create "Pre-Commit Checklist" section:
    - [ ] No behavioral duplication in documentation examples
    - [ ] Agent invocations use behavioral injection pattern (reference files, inject context)
    - [ ] STEP sequences only appear in agent files, not commands
    - [ ] Structural templates (Task syntax, bash) are complete, not truncated
    - [ ] Cross-references to template-vs-behavioral-distinction.md where applicable
  - Add "Review Standards" section:
    - All documentation examples must follow current patterns
    - No inline STEP sequences in command examples (reference agent files instead)
    - Context injection shown correctly (parameters only, not procedures)
    - Metrics cited accurately (90% reduction, 71% context savings)
  - Add "Validation Script Usage" section:
    - How to run validate_no_behavioral_duplication.sh manually
    - Interpreting output and suggested fixes
    - When to update agent files vs commands

**Testing**:
```bash
# Verify validation script created and executable
test -x .claude/tests/validate_no_behavioral_duplication.sh && echo "✓ Script is executable"

# Run validation script against known examples
.claude/tests/validate_no_behavioral_duplication.sh

# Verify integration with test suite
grep "validate_no_behavioral_duplication" .claude/tests/run_all_tests.sh

# Test documentation review checklist exists
test -f .claude/docs/guides/documentation-review-checklist.md && echo "✓ Checklist created"

# Validate script detects anti-patterns correctly
# Create temporary test file with inline STEP sequences
# Run validation script
# Verify it detects the anti-pattern
# Clean up test file
```

---

### Phase 7: Update Navigation and Cross-References

**Objective**: Ensure new documentation is discoverable throughout .claude/docs/

**Status**: PENDING

**Complexity**: Low

**Estimated Time**: 30 minutes

#### Tasks

- [x] Update `.claude/docs/concepts/patterns/README.md`
  - Add new anti-pattern entry in Anti-Patterns section (or create section):
    ```markdown
    ## Anti-Patterns

    - [Inline Template Duplication](../../troubleshooting/inline-template-duplication.md) - Duplicating agent behavioral guidelines in command prompts instead of referencing agent files
      - **Impact**: 90% unnecessary code, maintenance burden, synchronization issues
      - **Detection**: >50 lines per agent invocation, STEP sequences in commands
      - **Fix**: Extract to `.claude/agents/*.md`, reference via behavioral injection
    ```
  - Add link to template-vs-behavioral-distinction.md in "Core Patterns" section:
    ```markdown
    - [Template vs Behavioral Distinction](../../reference/template-vs-behavioral-distinction.md) - Critical architectural principle
    ```

- [x] Update `.claude/docs/guides/README.md`
  - Add reference to troubleshooting guide in appropriate section:
    ```markdown
    ## Troubleshooting

    - [Inline Template Duplication](../troubleshooting/inline-template-duplication.md) - Detect and fix behavioral duplication anti-pattern
    ```
  - Update command-development-guide summary to mention distinction:
    ```markdown
    - [Command Development Guide](./command-development-guide.md) - Complete guide to creating and maintaining slash commands
      - Includes structural template patterns and behavioral injection guidance
    ```

- [x] Update `.claude/docs/reference/README.md`
  - Add template-vs-behavioral-distinction.md to reference list:
    ```markdown
    ## Reference Documentation

    - [Template vs Behavioral Distinction](./template-vs-behavioral-distinction.md) - When to use inline templates vs behavioral file references
      - **Key Principle**: Structural templates inline, behavioral content referenced
      - **Metrics**: 90% code reduction, 71% context savings, 100% file creation rate
      - **Zero Exceptions**: No documented exceptions to behavioral duplication prohibition
    ```
  - Update command-architecture-standards summary to mention Standard 12:
    ```markdown
    - [Command Architecture Standards](./command-architecture-standards.md) - Complete architectural standards for .claude/ system
      - Includes Standard 12: Structural vs Behavioral Content Separation
    ```

- [x] Verify all cross-references are bidirectional
  - Check template-vs-behavioral-distinction.md links to:
    - behavioral-injection.md ✓
    - command-architecture-standards.md ✓
    - agent-development-guide.md ✓
  - Check behavioral-injection.md links to:
    - template-vs-behavioral-distinction.md ✓
  - Check command-architecture-standards.md links to:
    - template-vs-behavioral-distinction.md ✓
  - Check troubleshooting guide links to:
    - template-vs-behavioral-distinction.md ✓
    - behavioral-injection.md ✓

**Testing**:
```bash
# Verify all README files updated
grep "template-vs-behavioral" .claude/docs/concepts/patterns/README.md
grep "inline-template-duplication" .claude/docs/guides/README.md
grep "Template vs Behavioral Distinction" .claude/docs/reference/README.md

# Check for broken links across all updated files
find .claude/docs -name "*.md" -type f -exec grep -l "template-vs-behavioral-distinction\|inline-template-duplication" {} \; | while read file; do
  echo "Validating links in $file..."
  grep -o '\[.*\](\..*\.md)' "$file" | while read link; do
    path=$(echo "$link" | sed 's/.*(\(.*\))/\1/')
    full_path="$(dirname "$file")/$path"
    if [ ! -f "$full_path" ]; then
      echo "  ❌ BROKEN: $link"
    fi
  done
done

# Verify bidirectional cross-references
echo "Checking bidirectional links..."
grep -l "behavioral-injection.md" .claude/docs/reference/template-vs-behavioral-distinction.md
grep -l "template-vs-behavioral-distinction.md" .claude/docs/concepts/patterns/behavioral-injection.md
# Both should return file paths (indicating links exist)

# Verify discoverability from main README
grep "template-vs-behavioral\|inline-template-duplication" .claude/docs/README.md
```

---

## Testing Strategy

### Unit Testing (Per Phase)
- Each phase includes specific validation commands
- Check for internal consistency within documents
- Verify cross-references are accurate
- Test examples against documented patterns

### Integration Testing (After All Phases)
```bash
# 1. Verify all new files created
test -f .claude/docs/reference/template-vs-behavioral-distinction.md || echo "Missing: template-vs-behavioral-distinction.md"
test -f .claude/docs/troubleshooting/inline-template-duplication.md || echo "Missing: inline-template-duplication.md"
test -f .claude/docs/quick-reference/template-usage-decision-tree.md || echo "Missing: decision tree"

# 2. Verify structural vs behavioral mentioned in 5+ places
grep -r "structural.*behavioral\|behavioral.*structural" .claude/docs/ --include="*.md" | wc -l
# Expect: >20 (comprehensive coverage)

# 3. Check for consistency in terminology
grep -r "inline template" .claude/docs/ --include="*.md" | grep -v "structural\|behavioral" | wc -l
# Expect: 0 (all mentions should specify structural or behavioral)

# 4. Validate decision tree against real scenarios
# Test Case 1: Task block → Should be inline (structural)
# Test Case 2: STEP sequence → Should reference agent file (behavioral)
# Test Case 3: Verification checkpoint → Should be inline (structural)
# Test Case 4: File creation workflow → Should reference agent file (behavioral)

# 5. Run validation script (if Phase 5 completed)
.claude/tests/validate_no_behavioral_duplication.sh

# 6. Check navigation completeness
# User should be able to find documentation via:
# - Main README → Quick Reference → Decision Tree
# - Main README → Core Concepts → Template vs Behavioral Distinction
# - Patterns README → Anti-Patterns → Inline Template Duplication
# - Guides README → Troubleshooting → Inline Template Duplication
```

### Acceptance Testing
- [ ] New developer can understand structural vs behavioral distinction in <5 minutes
- [ ] Decision tree provides correct answer for 10 test scenarios
- [ ] Troubleshooting guide enables remediation of anti-pattern in <30 minutes
- [ ] Validation script (if implemented) detects anti-pattern with <5% false positives
- [ ] All cross-references navigable without broken links

## Documentation Requirements

### New Documentation Created
1. `.claude/docs/reference/template-vs-behavioral-distinction.md` (Core reference)
2. `.claude/docs/troubleshooting/inline-template-duplication.md` (Remediation guide)
3. `.claude/docs/quick-reference/template-usage-decision-tree.md` (Quick decisions)
4. `.claude/docs/guides/documentation-review-checklist.md` (Optional - Phase 5)
5. `.claude/tests/validate_no_behavioral_duplication.sh` (Optional - Phase 5)

### Existing Documentation Updated
1. `.claude/docs/concepts/patterns/behavioral-injection.md` - Add structural vs behavioral clarification
2. `.claude/docs/reference/command_architecture_standards.md` - Add Standard 12
3. `.claude/docs/guides/execution-enforcement-guide.md` - Add context clarification
4. `.claude/docs/guides/agent-development-guide.md` - Add single source of truth section
5. `.claude/docs/guides/command-development-guide.md` - Add references to distinction
6. `.claude/docs/README.md` - Add quick reference and core concept links
7. `.claude/docs/concepts/patterns/README.md` - Add anti-pattern entry
8. `.claude/docs/guides/README.md` - Add troubleshooting reference
9. `.claude/docs/reference/README.md` - Add template-vs-behavioral reference
10. `.claude/docs/troubleshooting/README.md` - Add anti-pattern entry

## Dependencies

### Internal Dependencies
- Research reports from `.claude/specs/441_template_usage_patterns_docs_analysis/reports/001_template_patterns_research/`
- Existing behavioral-injection.md pattern documentation
- Existing command-architecture-standards.md

### External Dependencies
- None (pure documentation updates)

### Tool Dependencies (Optional - Phase 5 only)
- bash (for validation script)
- grep, awk, sed (for pattern detection)

## Risk Assessment

### Low Risk
- Documentation-only changes (no code modifications)
- Backward compatible (doesn't break existing functionality)
- Incremental implementation (phases can be done separately)

### Potential Issues
1. **Inconsistency during transition**: Some docs updated, others not yet
   - **Mitigation**: Implement phases in priority order (high → medium → low)
   - **Mitigation**: Add "Last Updated" dates to track refresh status

2. **Link breakage during restructuring**: New files may break relative paths
   - **Mitigation**: Test all links after each phase
   - **Mitigation**: Use testing commands provided in each phase

3. **Confusion from terminology change**: "Template" now means two different things
   - **Mitigation**: Always qualify as "structural template" or "behavioral content"
   - **Mitigation**: Decision tree provides quick clarification

4. **Validation script false positives**: May flag legitimate patterns
   - **Mitigation**: Configure as warning initially (not error)
   - **Mitigation**: Tune thresholds based on real-world testing

## Phase Execution Strategy

### Rationale for Phase Order

**Phase 1: Foundation** - Create core reference documentation defining structural vs behavioral distinction
- **Why first**: Establishes shared vocabulary and principles for all subsequent work
- **Status**: COMPLETED

**Phase 2: Real-World Validation** - Apply standards to /supervise command
- **Why second**: Validates documentation works in practice; discovers gaps early
- **Key benefit**: Lessons learned inform phases 3-5; creates concrete case study
- **Status**: PENDING (next to execute)

**Phase 3: Guide Updates** - Update enforcement and development guides
- **Why third**: Can incorporate insights from /supervise application
- **Status**: COMPLETED (may need updates after Phase 2)

**Phase 4: Troubleshooting** - Create troubleshooting guide with /supervise case study
- **Why fourth**: Now has real-world example from Phase 2 to document
- **Status**: COMPLETED (will be enhanced by Phase 2 findings)

**Phase 5: Quick Reference** - Create decision tree and quick lookup
- **Why fifth**: Builds on validated patterns from Phases 2-4
- **Status**: COMPLETED

**Phase 6: Validation Tooling** - Optional automated detection script
- **Why sixth**: All patterns established; can codify detection rules
- **Status**: PENDING (optional)

**Phase 7: Navigation Polish** - Update cross-references and navigation
- **Why last**: Final integration after all documentation complete
- **Status**: PENDING

## Estimated Timeline

### Completed Work (Phases 1, 3, 4, 5)
- Phase 1: 2-3 hours (core reference documentation) [COMPLETED]
- Phase 3: 2-3 hours (guide updates) [COMPLETED]
- Phase 4: 1-2 hours (troubleshooting guide) [COMPLETED]
- Phase 5: 1-2 hours (quick reference) [COMPLETED]
- **Completed subtotal**: 6-10 hours

### Remaining Work (Phases 2, 6, 7)
- Phase 2: 3-4 hours (apply standards to /supervise - CRITICAL) [NEXT]
- Phase 6: 2-3 hours (optional validation tooling)
- Phase 7: 30 minutes (navigation updates)
- **Remaining subtotal**: 5.5-7.5 hours

### Total Estimate
- **Already completed**: 6-10 hours
- **Remaining required** (Phases 2, 7): 3.5-4.5 hours
- **Remaining optional** (Phase 6): 2-3 hours
- **Complete project total**: 12-17 hours

## Implementation Notes

### Commit Strategy
- Commit after each phase completes
- Use descriptive commit messages referencing phase number
- Example: `docs: Phase 1 - Create template vs behavioral distinction reference`

### Code Review Checklist
- [ ] All new files follow documentation standards (header, sections, examples)
- [ ] Cross-references are accurate and bidirectional
- [ ] Examples are clear and match documented patterns
- [ ] Terminology is consistent (structural template vs behavioral content)
- [ ] Decision tree provides correct guidance
- [ ] No broken links in updated documentation

### Post-Implementation
- Announce documentation updates to team
- Update any training materials or onboarding docs
- Monitor for questions or confusion (indicates areas needing clarification)
- Consider creating video walkthrough of decision tree usage

## Metrics for Success

### Quantitative
- [ ] 5+ documents mention structural vs behavioral distinction
- [ ] 90% code reduction cited in 3+ places
- [ ] Decision tree covers 10+ common scenarios
- [ ] Validation script (if implemented) has <5% false positive rate
- [ ] Zero broken links across updated documentation

### Qualitative
- [ ] New developers understand distinction without confusion
- [ ] Existing developers can quickly reference decision guidance
- [ ] Troubleshooting guide enables self-service remediation
- [ ] Documentation feedback: clarity improvement reported

## Notes

### Key Principles
1. **Structural templates** (MUST be inline): Task syntax, bash blocks, schemas, checkpoints
2. **Behavioral content** (MUST be referenced): Agent procedures, workflows, specifications
3. **Zero exceptions**: No documented exceptions to behavioral duplication prohibition
4. **Single source of truth**: Agent files are authoritative for behavioral guidelines

### Research Foundation
This plan implements findings from comprehensive documentation analysis showing:
- 90% code reduction per invocation (150 lines → 15 lines)
- 71% context usage reduction (85% → 25%)
- 100% file creation rate (up from 70%)
- 50-67% maintenance burden reduction

### Future Enhancements
- Video tutorial demonstrating decision tree usage
- Interactive examples in documentation
- Pre-commit hook enforcing validation script
- Automated link checking in CI/CD pipeline

---

## Revision History

### 2025-10-24 - Revision 2: Reorganize Phase Execution Order

**Changes**: Reorganized phases into logical execution flow: Foundation → Real-world validation → Refinement → Polish

**Reason**: Original phase order had /supervise application (Phase 6) near the end, but applying standards to a real-world case should happen early to:
1. Validate documentation works in practice
2. Discover gaps in guidance early
3. Create concrete case study that informs later phases
4. Enable validate-early approach rather than document-then-validate

**Phase Reordering**:
- **Phase 1**: Core Reference Documentation [COMPLETED] - No change (foundation)
- **Phase 2**: Apply Standards to /supervise [PENDING - CRITICAL] - **MOVED from Phase 6** (real-world validation)
- **Phase 3**: Update Guides [COMPLETED] - Moved from Phase 2 (can incorporate Phase 2 lessons)
- **Phase 4**: Troubleshooting Guide [COMPLETED] - Moved from Phase 3 (includes Phase 2 case study)
- **Phase 5**: Quick Reference [COMPLETED] - Moved from Phase 4 (builds on validated patterns)
- **Phase 6**: Validation Tooling [PENDING] - Moved from Phase 5 (codifies proven patterns)
- **Phase 7**: Navigation [PENDING] - No change (final polish)

**New Execution Strategy**:
- **Completed phases** (1, 3, 4, 5): 6-10 hours
- **Next phase** (2): 3-4 hours - /supervise application (validates all prior work)
- **Final phases** (6, 7): 2.5-3.5 hours - Automation + polish

**Key Benefits**:
- Phase 2 now validates Phase 1 documentation immediately
- Phases 3-5 can be updated with Phase 2 findings if needed
- Real-world case study available when creating troubleshooting guide
- Logical flow: foundation → validation → refinement → automation → polish

**Documentation Updates**:
- Added "Phase Execution Strategy" section explaining rationale for order
- Updated timeline to show completed work vs remaining work
- Clarified that Phase 2 is next critical step
- Updated metadata with execution order: "Foundation docs → Real-world application → Guides → Troubleshooting → Quick reference → Validation → Navigation"
- **Task Renumbering**: Updated all task references from "Task 6.x" to "Task 2.x" to match new phase number (Tasks 2.1, 2.2, 2.3, 2.4)

**Impact**: This reorganization creates a validate-early approach where real-world application happens immediately after foundation documentation, enabling faster feedback and higher confidence in guidance quality.

---

### 2025-10-24 - Revision 1: Add /supervise Application Phase

**Changes**: Added Phase 6 to apply structural/behavioral distinction standards to `/supervise` command using diagnostic findings from spec 444

**Reason**: Diagnostic report (spec 444/001) identified that `/supervise` refactor plan (spec 438/001) is blocked due to incorrect search patterns. The plan searches for non-existent "Example agent invocation:" pattern when actual file contains different patterns. Need to:
1. Classify 7 YAML blocks in supervise.md as structural vs behavioral
2. Create corrected refactor instructions with pattern verification
3. Document /supervise as case study in troubleshooting guide
4. Apply 90% code reduction through proper behavioral extraction

**Reports Used**:
- `.claude/specs/444_research_allowed_tools_fix/reports/001_research/OVERVIEW.md` - Pattern mismatch diagnostic

**Modified Phases**:
- **Added Phase 6**: "Apply Standards to /supervise Command (Critical Priority)" with 4 subtasks
- **Renumbered**: Previous Phase 6 (Navigation) → Phase 7
- **Updated Timeline**: Added 3-4 hours for Phase 6; total now 12-17 hours (was 8.5-13.5 hours)
- **Updated Metadata**: Added diagnostic report reference, increased phase count to 7

**Key Additions**:
- Task 2.1: Analyze and classify all 7 YAML blocks in supervise.md
- Task 2.2: Create corrected refactor plan with pattern verification (Phase 0 guard)
- Task 2.3: Document /supervise as real-world case study
- Task 2.4: Update spec 438 with addendum preserving diagnostic trail

**Success Criteria Added**:
- Pattern verification passes before implementation
- 90% line reduction achieved (750+ lines removed from supervise.md)
- Regression test fixed to detect actual patterns (not false pass)
- Case study demonstrates pattern verification importance

**Impact**: This revision ensures the documentation plan directly applies to fixing a critical real-world issue (/supervise blocked refactor), demonstrating the practical value of structural/behavioral distinction standards.
