# Basic Usage Guide Implementation Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Add basic usage guide with workflow examples to commands README
- **Scope**: Document /research standalone workflow and /plan-/revise-/expand-/build pipeline
- **Estimated Phases**: 3
- **Estimated Hours**: 2.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Complexity Score**: 14 (Tier 1 - Single File)
- **Structure Level**: 0
- **Research Reports**:
  - [Basic Usage Guide Research](/home/benjamin/.config/.claude/specs/819_revise_expand_build_add_basic_usage_guide/reports/001_basic_usage_guide_research.md)
  - [Quick Start Removal Analysis](/home/benjamin/.config/.claude/specs/819_revise_expand_build_add_basic_usage_guide/reports/002_quick_start_removal_analysis.md)

## Overview

This plan documents the implementation of a basic usage guide section in the commands README. The guide will demonstrate two primary workflow patterns: (1) research-only investigations using /research, and (2) complete feature implementation using the /plan->/revise->/expand->/build pipeline. The goal is to provide developers with clear, example-driven documentation that enables immediate productivity with these commands.

## Research Summary

The research reports identified clear patterns and relationships between the five workflow commands:

**Key Findings from Basic Usage Guide Research**:
- Commands form a coherent workflow system with distinct purposes
- Two primary patterns emerge: research-only and plan-build pipeline
- Complexity defaults vary by command: /research=2, /plan=3, /revise=2
- Expected durations scale with complexity (5-90 minutes)
- Common workflow chains exist: research->plan, plan->build, build->revise->build

**Key Findings from Quick Start Removal Analysis**:
- Quick Start subsection duplicates content that naturally belongs in guide introduction
- Minimal examples should appear directly after "## Basic Usage Guide" heading
- Eliminating the subsection reduces structural overhead without losing content value
- Success criteria should be updated to reflect integrated approach

**Recommended Approach**:
Structure the guide with minimal examples directly in the introduction (no separate Quick Start subsection), then document workflow patterns in detail. This provides immediate value while avoiding content duplication.

## Success Criteria
- [ ] Basic usage guide section added to README between Overview and Command Guides
- [ ] Guide introduction demonstrates both workflows with minimal examples
- [ ] Workflow Pattern 1 (research-only) includes syntax, examples, and expected output
- [ ] Workflow Pattern 2 (plan-build) includes all four commands with examples
- [ ] Common workflow chains documented with copy-paste ready examples
- [ ] Complexity selection guide helps users choose appropriate depth
- [ ] Guide follows CommonMark specification without emojis
- [ ] All examples use realistic command invocations

## Technical Design

### Architecture Overview

The usage guide will be added as a new section in the existing README.md file, positioned between the "Overview" section and the "Command Guides" table. This placement ensures users see practical examples before diving into individual command documentation.

### Section Structure

```markdown
## Basic Usage Guide

Start with these minimal examples:

```bash
# Research-only workflow
/research "existing auth patterns"

# Complete implementation pipeline
/plan "add user auth"
/build
```

For detailed explanations, see the workflow patterns below.

### Workflow Pattern 1: Research-Only
- Purpose, syntax, examples, output

### Workflow Pattern 2: Plan-Build Pipeline
- Step 1: /plan
- Step 2: /revise (optional)
- Step 3: /expand (optional)
- Step 4: /build

### Common Workflow Chains
- Research -> Plan
- Plan -> Build
- Build -> Revise -> Build

### Choosing Complexity Level
- Quick reference table

### Integration Points

- Maintains existing README structure
- Links to individual command guides for deep dives
- Consistent with documentation standards (no emojis, CommonMark)

## Implementation Phases

### Phase 1: Create Guide Structure and Introduction [COMPLETE]
dependencies: []

**Objective**: Add the basic usage guide section framework with integrated introduction examples

**Complexity**: Low

Tasks:
- [x] Read current README structure (file: /home/benjamin/.config/.claude/docs/guides/commands/README.md)
- [x] Create "## Basic Usage Guide" section after "## Overview" (line ~9)
- [x] Add introduction paragraph with minimal examples (no subsection):
  - Research-only: `/research "existing auth patterns"`
  - Plan-build: `/plan "add user auth"` followed by `/build`
  - Brief note directing to detailed patterns below
- [x] Ensure examples are in a properly formatted bash code block

Testing:
```bash
# Verify section added
grep -q "## Basic Usage Guide" /home/benjamin/.config/.claude/docs/guides/commands/README.md && echo "Guide section exists"
# Check minimal examples exist (validates integrated approach)
grep -q "/research.*auth\|/plan.*auth" /home/benjamin/.config/.claude/docs/guides/commands/README.md && echo "Minimal examples exist"
```

**Expected Duration**: 0.5 hours

---

### Phase 2: Document Workflow Patterns with Examples [COMPLETE]
dependencies: [1]

**Objective**: Add detailed documentation for both workflow patterns with examples

**Complexity**: Medium

Tasks:
- [x] Add "### Workflow Pattern 1: Research-Only" subsection with:
  - Use case description (investigation without implementation)
  - Syntax: `/research "<topic>" [--complexity 1-4]`
  - Three examples from research report (basic, higher complexity, hierarchical)
  - Output structure explanation (specs/NNN/reports/)
- [x] Add "### Workflow Pattern 2: Plan-Build Pipeline" subsection with:
  - Overview of the pipeline flow
  - Step 1: /plan - syntax, examples, output (reports + plan)
  - Step 2: /revise (optional) - syntax, examples, backup behavior
  - Step 3: /expand (optional) - syntax, auto vs explicit examples
  - Step 4: /build - syntax, examples, workflow states
- [x] Add "### Common Workflow Chains" subsection with:
  - Research -> Plan chain example
  - Plan -> Build chain example
  - Build -> Revise -> Build chain example
  - Debug loop example
- [x] Add "### Choosing Complexity Level" subsection with:
  - Table of complexity levels and expected durations
  - Default complexity by command
  - Guidance on when to use each level

Testing:
```bash
# Verify workflow patterns exist
grep -q "### Workflow Pattern 1: Research-Only" /home/benjamin/.config/.claude/docs/guides/commands/README.md && echo "Pattern 1 exists"
grep -q "### Workflow Pattern 2: Plan-Build Pipeline" /home/benjamin/.config/.claude/docs/guides/commands/README.md && echo "Pattern 2 exists"
# Count code blocks (should have at least 8 examples)
grep -c '```bash' /home/benjamin/.config/.claude/docs/guides/commands/README.md
```

**Expected Duration**: 1.5 hours

---

### Phase 3: Review and Finalize [COMPLETE]
dependencies: [2]

**Objective**: Validate documentation quality and ensure standards compliance

**Complexity**: Low

Tasks:
- [x] Review all examples for accuracy and consistency
- [x] Verify CommonMark compliance (no emojis, proper formatting)
- [x] Check all internal links resolve correctly
- [x] Ensure examples are copy-paste ready (proper quoting)
- [x] Verify section order and hierarchy is logical
- [x] Add cross-references to related documentation where helpful
- [x] Final read-through for clarity and completeness

Testing:
```bash
# Check for emojis (should find none in guide)
grep -P '[\x{1F000}-\x{1FFFF}]' /home/benjamin/.config/.claude/docs/guides/commands/README.md || echo "No emojis found"
# Validate markdown structure
head -100 /home/benjamin/.config/.claude/docs/guides/commands/README.md
# Check file exists and has content
wc -l /home/benjamin/.config/.claude/docs/guides/commands/README.md
```

**Expected Duration**: 0.5 hours

## Testing Strategy

### Documentation Quality
- All code examples are syntactically correct and executable
- No broken internal links
- CommonMark compliant formatting
- No emojis in content

### Content Completeness
- Both workflow patterns fully documented
- All five commands covered (/research, /plan, /revise, /expand, /build)
- Complexity guide included
- Common chains documented

### User Experience
- Guide introduction provides immediate value with minimal examples
- Examples progress from simple to complex
- Navigation is intuitive

## Documentation Requirements

### Files to Update
- `/home/benjamin/.config/.claude/docs/guides/commands/README.md` - Add basic usage guide section

### Documentation Standards
- Follow CommonMark specification
- No emojis in file content
- Clear, concise language
- Include code examples with syntax highlighting (```bash)
- Use realistic command invocations

### Cross-References
- Link to individual command guides for detailed information
- Reference related documentation (command reference, orchestration guides)

## Dependencies

### Prerequisites
- Existing README.md structure must be preserved
- All referenced command guides must exist
- Research report findings inform content

### External Dependencies
- None

### Constraints
- Must not break existing navigation links
- Must follow documentation policy (no proactive doc creation)
- Content must fit logically between existing sections
