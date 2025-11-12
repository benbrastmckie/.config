# Integration Requirements for Executable/Documentation Separation Standards

## Metadata
- **Date**: 2025-11-07
- **Agent**: research-specialist
- **Topic**: Gap Analysis and Standards Integration Requirements
- **Report Type**: Documentation gap analysis

## Executive Summary

The executable/documentation separation pattern from Plan 002 is partially documented across multiple files but lacks systematic integration and consistent cross-referencing. Command Development Guide (Section 2.4, lines 213-330) provides the primary documentation with templates, migration checklist, and metrics. CLAUDE.md references this via line 403 but only minimally. The pattern is well-established for commands but completely absent from agent documentation standards. Key integration gaps: Agent Development Guide lacks section on separation pattern, Command Architecture Standards mentions templates but doesn't explain the architectural principle, and discovery paths are inconsistent.

## Findings

### 1. Command Development Guide Coverage

**Location**: `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md`
**Lines**: 213-330 (Section 2.4)
**Coverage Level**: COMPREHENSIVE (118 lines dedicated to pattern)

**Strengths**:
- Complete architectural explanation (lines 215-226: problem statement, meta-confusion loops, recursive invocation bugs)
- Two-file pattern definition aligned with Diataxis framework (lines 228-237: executable vs guide files)
- Template references with file paths (lines 243-244: `_template-executable-command.md`, `_template-command-guide.md`)
- Migration checklist with 10 steps (lines 246-260)
- File size guidelines table (lines 263-267: <200 lines target, 250 max for executables)
- Cross-reference convention examples (lines 271-285)
- Benefits enumeration (lines 289-293: eliminates meta-confusion, maintainability, scalability, fail-fast)
- Validation script reference (lines 297-300)
- Migration results table (lines 304-323: 7 commands, 26-90% reduction, comprehensive metrics)
- Lessons learned documentation (lines 325-329)

**Gaps**:
- No mention of when NOT to apply pattern (simple utility commands)
- No guidance on splitting complex command logic vs documentation
- Missing link to Standard 12 in Command Architecture Standards
- No examples of edge cases (e.g., commands with heavy inline templates)

**References In**:
- CLAUDE.md:403 (minimal reference)
- guides/README.md:212 (explains "why separated")

**References Out**:
- Lines 243-244: Template file paths (relative)

### 2. Agent Development Guide Coverage

**Location**: `/home/benjamin/.config/.claude/docs/guides/agent-development-guide.md`
**Lines**: 2,012 total
**Coverage Level**: NONE (pattern not mentioned)

**Critical Gap**: No section on executable/documentation separation for agent files.

**Why This Matters**:
- Agent files are execution scripts (similar to commands)
- Agent files also suffer from documentation bloat (see research-specialist.md: 671 lines)
- Mixed behavioral instructions with examples creates same meta-confusion risk
- No guidance on when to extract agent usage examples to separate guide

**Potential Location for Integration**:
- After Section 1.5 "Creating a New Agent" (would become Section 1.6)
- Similar structure to Command Development Guide Section 2.4
- Cover: agent file structure (behavioral only), agent guide structure (usage examples, invocation patterns, integration patterns)

**Required Content**:
- Principle: Agent files contain behavioral guidelines only
- Pattern: Agent usage examples go to `/docs/guides/[agent-name]-agent-guide.md`
- When to split: Agent file >400 lines (empirical threshold from research-specialist)
- Template: Similar to command templates but focused on behavioral enforcement
- Migration: Checklist for extracting examples without losing behavioral clarity

### 3. Command Architecture Standards Coverage

**Location**: `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md`
**Lines**: 2,110 total
**Coverage Level**: PARTIAL (mentions templates but not architectural principle)

**Current References**:
- Standard 4 (lines 1045-1095): Template Completeness
  - Requires "Complete, copy-paste ready templates" (line 1049)
  - Shows complete agent prompt template example (lines 1050-1081)
  - Forbids truncated templates with external references (lines 1084-1095)
- Standard 12 (lines 1310-1397): Structural vs Behavioral Content Separation
  - Structural templates MUST be inline (lines 1315-1334)
  - Behavioral content MUST NOT be duplicated (lines 1339-1390)
  - 90% code reduction metric (line 1363)

**Gap Analysis**:
- Standard 4 focuses on completeness, NOT architectural separation
- Standard 12 covers what goes IN commands, not WHERE documentation goes
- No dedicated standard for "Executable/Documentation File Separation"
- Missing cross-reference to Command Development Guide Section 2.4
- No mention of the 250-line target for executable files
- No guidance on when to create guide files vs inline documentation

**Recommended Addition**:
- New Standard 14: "Executable/Documentation File Separation"
- Location: After Standard 13 (Project Directory Detection)
- Content: Principle statement, two-file pattern requirement, template references, success criteria
- Cross-references: Command Development Guide 2.4, template files, migration checklist

### 4. CLAUDE.md Integration

**Location**: `/home/benjamin/.config/CLAUDE.md`
**Lines**: Referenced at 403
**Coverage Level**: MINIMAL (single line reference)

**Current Reference** (line 398-403):
```markdown
**Command Documentation Pattern**: Commands follow executable/documentation separation:
- **Executable files** (`.claude/commands/*.md`): Lean execution scripts (<250 lines)
- **Command guides** (`.claude/docs/guides/*-command-guide.md`): Comprehensive documentation
- **Templates**: See [Executable Template](.claude/docs/guides/_template-executable-command.md) and [Guide Template](.claude/docs/guides/_template-command-guide.md)
- **Details**: See [Command Development Guide - Section 2.4](.claude/docs/guides/command-development-guide.md#24-executabledocumentation-separation-pattern)
```

**Strengths**:
- Pattern name established ("executable/documentation separation")
- File path conventions specified
- Template cross-references present
- Link to detailed guide (Section 2.4)

**Gaps**:
- Not integrated with "Code Standards" section (lines 115-145)
- No mention in "Development Philosophy" (lines 147-171)
- Missing from "Development Workflow" (lines 173-201)
- Not cross-referenced from "Command-Specific Patterns" (lines 398-425)
- No guidance on when pattern applies (all commands? specific types?)

**Integration Opportunities**:
1. **Code Standards Section** (after line 145): Add subsection on architectural separation principles
2. **Development Philosophy** (lines 159-171): Connect to "clean, coherent systems" and "present-focused documentation"
3. **Development Workflow** (around line 180): Note that documentation updates happen in guide files
4. **Quick Reference** (lines 427-445): Add pointer to templates and Section 2.4

### 5. Documentation Gaps

**Gap 1: Discovery Path Inconsistency**
- **Issue**: Users starting from CLAUDE.md see minimal reference (line 403)
- **Navigation Path**: CLAUDE.md → Command Development Guide Section 2.4 → Templates
- **Problem**: Indirect; requires 2 clicks to reach templates
- **Solution**: Add template links directly to CLAUDE.md Code Standards section

**Gap 2: Agent Pattern Documentation**
- **Issue**: No equivalent section in Agent Development Guide
- **Impact**: Agent files continue to mix behavioral + usage examples (671 lines for research-specialist)
- **Evidence**: research-specialist.md contains ~200 lines of usage examples (lines 498-671) that could be extracted
- **Solution**: Create Agent Development Guide Section 1.6 (parallel to Command Development Guide 2.4)

**Gap 3: Standard 14 Missing**
- **Issue**: Command Architecture Standards lacks dedicated standard for executable/documentation separation
- **Gap**: Standards 0-5, 11-13 exist; pattern deserves dedicated standard
- **Cross-Reference Weakness**: Standard 4 (Template Completeness) and Standard 12 (Structural vs Behavioral) partially address but don't capture full architectural principle
- **Solution**: Add Standard 14 after Standard 13, focus on file separation architecture

**Gap 4: Template Documentation**
- **Issue**: Templates exist (`.claude/docs/guides/_template-*.md`) but lack comprehensive guide
- **Current**: Referenced in Command Development Guide 2.4 (lines 243-244) with file paths only
- **Missing**: When to use each template, customization guidelines, example workflows
- **Solution**: Create `/docs/guides/template-usage-guide.md` or expand Section 2.4 with template subsections

**Gap 5: Migration Guidance for Existing Files**
- **Issue**: Checklist exists (Command Development Guide lines 246-260) but lacks detailed examples
- **Missing**: Step-by-step walkthrough for migrating large command (e.g., orchestrate.md: 5,439 → 557 lines)
- **Evidence**: Plan 002 achieved 54-90% reduction but migration process not fully documented
- **Solution**: Add subsection 2.4.1 "Migration Walkthrough: Real Example" showing orchestrate.md split

**Gap 6: Validation Tools**
- **Issue**: Script referenced (`.claude/tests/validate_executable_doc_separation.sh`) in Command Development Guide line 297
- **Status**: Script may not exist or lacks documentation
- **Required**: Validation checks for <250 line requirement, guide existence, cross-reference validity
- **Solution**: Create or document validation script with usage examples

### 6. Consistency Analysis

**Terminology Consistency**: ✅ GOOD
- Pattern name: "executable/documentation separation" (used consistently)
- File naming: `*-command-guide.md` (established convention from Plan 002 Revision 1)
- Template naming: `_template-executable-command.md`, `_template-command-guide.md` (clear prefixes)

**File Path Consistency**: ✅ GOOD
- Executables: Always `.claude/commands/*.md`
- Guides: Always `.claude/docs/guides/*-command-guide.md`
- Templates: Always `.claude/docs/guides/_template-*.md`
- Aligned with Diataxis framework (guides = task-focused, reference = catalog)

**Cross-Reference Consistency**: ⚠️ PARTIAL
- Command Development Guide → Templates: ✅ Present (lines 243-244)
- CLAUDE.md → Command Development Guide: ✅ Present (line 403)
- Command Architecture Standards → Section 2.4: ❌ MISSING (no cross-reference)
- Agent Development Guide → Pattern: ❌ MISSING (not mentioned)
- Template files → Usage guide: ❌ MISSING (no comprehensive usage doc)

**Metric Consistency**: ✅ EXCELLENT
- 250-line target: Mentioned in Command Development Guide (line 265), CLAUDE.md (line 399)
- 26-90% reduction: Documented in Command Development Guide table (lines 306-315)
- <200 line target: Specified in file size guidelines (line 265)

**Standard Number Consistency**: ⚠️ GAP
- Standards 0-5 exist
- Standards 11-13 exist
- Standards 6-10: NOT DOCUMENTED (numbering gap)
- Standard 14: Proposed for executable/documentation separation

## Recommendations

### Recommendation 1: Add Agent Development Guide Section 1.6

**Priority**: HIGH
**Effort**: 2-3 hours
**Impact**: Establishes pattern for agent files, prevents future bloat

**Content Structure** (parallel to Command Development Guide 2.4):
```markdown
### 1.6 Agent Behavioral/Usage Separation Pattern

**Architecture Principle**: Separate behavioral guidelines from usage examples

#### Problem Statement
- Agent files mixing behavioral enforcement with usage examples
- Example: research-specialist.md (671 lines: ~400 behavioral, ~200 usage examples)
- Same meta-confusion risk as command files

#### Solution Architecture
1. **Agent Behavioral File** (`.claude/agents/agent-name.md`)
   - Behavioral guidelines only (STEP sequences, PRIMARY OBLIGATION blocks)
   - Target: <400 lines
2. **Agent Usage Guide** (`.claude/docs/guides/agent-name-agent-guide.md`)
   - Invocation patterns, integration examples, command-agent matrix
   - Unlimited length

#### When to Split
- Agent file >400 lines (empirical threshold)
- Extensive usage examples (>100 lines)
- Multiple invocation patterns documented

#### Templates
- Use `_template-agent-behavioral.md` (to be created)
- Use `_template-agent-usage-guide.md` (to be created)
```

**Implementation**:
1. Add section to Agent Development Guide after line 752 (after Section 1.5)
2. Create agent-specific templates in `.claude/docs/guides/`
3. Update CLAUDE.md to reference agent pattern
4. Migrate research-specialist.md as proof of concept

### Recommendation 2: Add Command Architecture Standard 14

**Priority**: HIGH
**Effort**: 1 hour
**Impact**: Formalizes architectural requirement, enables enforcement

**Proposed Content**:
```markdown
### Standard 14: Executable/Documentation File Separation

**Requirement**: Commands MUST separate executable logic from comprehensive documentation.

**Two-File Pattern**:
1. **Executable Command** (`.claude/commands/command-name.md`)
   - Target size: <250 lines (maximum for obvious executability)
   - Content: Bash blocks, minimal inline comments, phase structure
   - Documentation: One-line link to guide file only

2. **Command Guide** (`.claude/docs/guides/command-name-command-guide.md`)
   - Purpose: Complete task-focused documentation (unlimited length)
   - Content: Architecture, examples, troubleshooting, design decisions
   - Audience: Developers and maintainers

**Rationale**:
- Eliminates meta-confusion loops (Claude misinterpreting docs as instructions)
- Prevents recursive invocation bugs
- Enables documentation growth without executable bloat
- Supports fail-fast execution

**Enforcement**:
- Commands >250 lines MUST extract documentation to guide file
- All guides MUST be cross-referenced from CLAUDE.md
- Templates available: `_template-executable-command.md`, `_template-command-guide.md`

**Validation**:
- Script: `.claude/tests/validate_executable_doc_separation.sh`
- Checks: File size <250 lines, guide exists, cross-references valid

**See Also**:
- [Command Development Guide - Section 2.4](../guides/command-development-guide.md#24-executabledocumentation-separation-pattern)
- [Executable Template](../guides/_template-executable-command.md)
- [Guide Template](../guides/_template-command-guide.md)
```

**Location**: After Standard 13 (Project Directory Detection), line ~1476

### Recommendation 3: Enhance CLAUDE.md Integration

**Priority**: MEDIUM
**Effort**: 30 minutes
**Impact**: Improves discovery, establishes pattern as core principle

**Changes**:

**3a. Add to Code Standards Section** (after line 145):
```markdown
### Architectural Separation

**Executable/Documentation Separation**: Commands and agents separate execution logic from comprehensive documentation following the two-file pattern. Executables contain minimal inline comments and remain <250 lines. Complete guides exist in `.claude/docs/guides/`. See [Command Development Guide - Section 2.4](.claude/docs/guides/command-development-guide.md#24-executabledocumentation-separation-pattern) and templates in `.claude/docs/guides/_template-*.md`.
```

**3b. Update Development Philosophy** (within lines 147-171):
```markdown
Core values: clarity, quality, coherence, maintainability.

**Architectural Principles**:
- Clean separation between executable logic and documentation
- Fail-fast execution without meta-confusion loops
- Documentation grows independently of execution code
```

**3c. Expand Quick Reference** (after line 445):
```markdown
### Command Development
- **New Command**: Start with `.claude/docs/guides/_template-executable-command.md`
- **Command Guide**: Use `.claude/docs/guides/_template-command-guide.md`
- **Pattern Guide**: [Command Development Guide - Section 2.4](.claude/docs/guides/command-development-guide.md#24-executabledocumentation-separation-pattern)
```

### Recommendation 4: Create Template Usage Guide

**Priority**: LOW
**Effort**: 1 hour
**Impact**: Improves template adoption for new commands

**File**: `.claude/docs/guides/template-usage-guide.md`

**Content**:
1. When to use each template (executable vs guide)
2. Customization guidelines (metadata fields, phase structure)
3. Example workflow: Creating new command from templates
4. Migration workflow: Splitting existing large command
5. Validation checklist

**Cross-References**:
- Link from Command Development Guide Section 2.4 (after line 244)
- Link from CLAUDE.md Quick Reference (new section)
- Link from template files themselves (header comment)

### Recommendation 5: Document Validation Script

**Priority**: MEDIUM
**Effort**: 1 hour (if script exists) or 3 hours (if needs creation)
**Impact**: Enables automated enforcement, prevents pattern violations

**Requirements**:
1. Check all command files <250 lines (fail if exceeded)
2. Verify guide file exists for each command (warn if missing)
3. Validate bidirectional cross-references (command → guide, guide → command)
4. Check template usage (metadata format consistency)

**Documentation Location**:
- Command Development Guide Section 2.4 (expand line 297-300 with detailed usage)
- Script header comments (usage instructions)
- CLAUDE.md Testing Protocols section (reference validation as pre-commit check)

**Usage Example**:
```bash
# Validate all commands
.claude/tests/validate_executable_doc_separation.sh

# Validate specific command
.claude/tests/validate_executable_doc_separation.sh coordinate

# Expected output
✓ coordinate.md: 1,084 lines (under 250-line target for simple commands, acceptable for complex orchestrator)
✓ Guide exists: .claude/docs/guides/coordinate-command-guide.md
✓ Cross-references valid
```

### Recommendation 6: Fill Standard Numbering Gap (Standards 6-10)

**Priority**: LOW (documentation hygiene)
**Effort**: Research existing standards, renumber if needed
**Impact**: Consistency, future-proofing

**Action**:
- Investigate why Standards 6-10 are missing (historical gap or intentional reservation?)
- If intentional: Document reservation reason in Command Architecture Standards
- If gap: Consider renumbering Standard 11 → Standard 6, etc., OR preserve numbers and note gap
- Prefer preservation (Standard 11 is well-referenced, renumbering breaks existing links)

## References

### Primary Sources
- `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md:213-330` - Section 2.4 (primary documentation)
- `/home/benjamin/.config/.claude/docs/guides/agent-development-guide.md` - 2,012 lines (no pattern coverage)
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md:1045-1095` - Standard 4 (Template Completeness)
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md:1310-1397` - Standard 12 (Structural vs Behavioral)
- `/home/benjamin/.config/CLAUDE.md:398-403` - Command Documentation Pattern reference

### Templates
- `.claude/docs/guides/_template-executable-command.md` - Executable command template (referenced line 243)
- `.claude/docs/guides/_template-command-guide.md` - Command guide template (referenced line 244)

### Plan Documents
- `/home/benjamin/.config/.claude/specs/601_and_documentation_in_claude_docs_in_order_to/plans/002_executable_documentation_separation_plan/002_executable_documentation_separation_plan.md` - Original implementation plan
- Plan 002 Metadata: 7 commands migrated, 26-90% reduction, <250 line target validated

### Related Documentation
- `.claude/docs/guides/README.md:212` - Why separated explanation
- Command Development Guide lines 306-323 - Migration results table
- CLAUDE.md line 130 - Agent Development Guide reference (no pattern crossover currently)
