# .claude/docs/ Structure and Standards Documentation Analysis

## Overview

This report provides a comprehensive analysis of the current `.claude/docs/` directory structure, existing standards documentation, and the architectural patterns already in place for command/agent development. The analysis identifies where executable/documentation separation standards naturally fit within the existing framework.

**Research Date**: 2025-11-07
**Files Analyzed**: 114 markdown files across 13 subdirectories
**Focus Areas**: Directory organization, standards documentation, command architecture, documentation patterns, cross-references

---

## Current Directory Organization

### Top-Level Structure

The `.claude/docs/` directory follows the **Diataxis framework** with 8 primary subdirectories:

```
docs/
├── reference/          Information-oriented quick lookup (15 files)
├── guides/            Task-focused how-to guides (39 files)
├── concepts/          Understanding-oriented explanations (5 files + patterns/)
├── workflows/         Learning-oriented step-by-step tutorials (11 files)
├── quick-reference/   Decision trees and flowcharts (5 files)
├── troubleshooting/   Problem-solving documentation (4 files)
├── architecture/      System design documentation (1 file)
└── archive/           Historical documentation (redirects to current files)
```

**Total Documentation**: 114 markdown files covering commands, agents, patterns, workflows, and reference materials.

### Diataxis Framework Alignment

The documentation structure deliberately aligns with the Diataxis documentation framework:

1. **Reference** (Information-oriented): Quick lookup for syntax, parameters, schemas
2. **Guides** (Task-oriented): Practical instructions to achieve specific goals
3. **Concepts** (Understanding-oriented): Explanations to build comprehension
4. **Workflows** (Learning-oriented): Lessons to acquire skills

This organization ensures developers can quickly find documentation matching their current need (learning, solving, understanding, or looking up).

---

## Existing Standards Documentation

### Command Architecture Standards

**Primary Document**: `.claude/docs/reference/command_architecture_standards.md` (2,111 lines)

This comprehensive document establishes architectural standards for all command and agent files with **14 core standards**:

#### Key Standards Relevant to Executable/Documentation Separation

**Standard 0: Execution Enforcement**
- Distinguishes descriptive documentation from mandatory execution directives
- Imperative vs descriptive language patterns
- Enforcement patterns: "EXECUTE NOW", "MANDATORY VERIFICATION", "THIS EXACT TEMPLATE"
- Language strength hierarchy (Critical/Mandatory/Strong/Standard/Optional)
- Fallback mechanism requirements
- Testing execution enforcement

**Standard 1: Executable Instructions Must Be Inline**
- Step-by-step execution procedures with numbered steps
- Tool invocation examples with actual parameter values
- JSON/YAML structure specifications
- Agent prompt templates (complete, not truncated)
- Critical warnings (CRITICAL, IMPORTANT, NEVER)
- Error recovery procedures
- External references allowed only for supplemental context

**Standard 2: Reference Pattern**
- "Instructions first, reference after" pattern
- External references supplement (not replace) inline instructions
- Command must execute using only inline content

**Standard 11: Imperative Agent Invocation Pattern**
- All Task invocations MUST use imperative instructions
- No code block wrappers around Task invocations
- Direct reference to agent behavioral files
- Explicit completion signals required
- Historical context: 0% → >90% delegation rate after implementation

**Standard 12: Structural vs Behavioral Content Separation**
- Structural templates MUST be inline (Task syntax, bash blocks, JSON schemas, verification checkpoints)
- Behavioral content MUST be referenced (agent STEP sequences, file creation workflows, verification steps)
- 90% code reduction per agent invocation when properly applied
- Single source of truth for agent behavioral guidelines

### Template vs Behavioral Distinction

**Document**: `.claude/docs/reference/template-vs-behavioral-distinction.md` (14,587 bytes)

Defines critical architectural distinction:
- **Structural Templates** (inline): Execution-critical patterns Claude must see immediately
- **Behavioral Content** (referenced): Agent execution procedures and workflows

**Benefits**:
- 90% code reduction per agent invocation (150 lines → 15 lines)
- 71% context usage reduction (85% → 25%)
- 100% file creation rate (up from 70%)
- 50-67% maintenance burden reduction
- Single source of truth for agent behavioral guidelines

---

## Executable/Documentation Separation Pattern (Existing)

### Current Implementation

**Location**: `.claude/docs/guides/command-development-guide.md` - Section 2.4 (lines 213-330)

This pattern is **already documented and actively used** in the codebase. Key details:

#### Architecture Principle

"Separate execution logic from comprehensive documentation to eliminate meta-confusion loops and maintain lean, obviously-executable command files."

#### Problems Solved

1. **Meta-confusion loops**: Claude misinterprets documentation as conversational instructions
2. **Recursive invocation bugs**: Attempts to "invoke /command" instead of executing as command
3. **Context bloat**: Hundreds of lines of documentation loaded before first executable instruction
4. **Maintenance burden**: Changes to docs or logic affect each other

#### Solution Architecture

**Two-file pattern**:

1. **Executable Command** (`.claude/commands/command-name.md`)
   - Purpose: Lean execution script (target: <250 lines)
   - Content: Bash blocks, minimal inline comments, phase structure
   - Documentation: One-line link to guide file only

2. **Command Guide** (`.claude/docs/guides/command-name-command-guide.md`)
   - Purpose: Complete task-focused documentation (unlimited length)
   - Content: Architecture, examples, troubleshooting, design decisions
   - Audience: Developers and maintainers

#### Templates Available

1. **Executable Template**: `.claude/docs/guides/_template-executable-command.md` (56 lines)
   - Standard 13 CLAUDE_PROJECT_DIR detection
   - Phase-based structure
   - Minimal inline comments
   - Cross-reference to guide

2. **Guide Template**: `.claude/docs/guides/_template-command-guide.md` (100 lines)
   - Complete documentation structure
   - Architecture, usage examples, troubleshooting sections
   - Cross-reference to executable

#### File Size Guidelines

| File Type | Target Size | Maximum | Rationale |
|-----------|------------|---------|-----------|
| Executable | <200 lines | 250 lines | Obviously executable, minimal context |
| Guide | Unlimited | N/A | Documentation can grow without bloating executable |
| Template | <100 lines | 150 lines | Quick-start reference only |

#### Migration Results (Completed 2025-11-07)

All major commands successfully migrated:

| Command | Original Lines | New Lines | Reduction | Guide Lines |
|---------|---------------|-----------|-----------|-------------|
| `/coordinate` | 2,334 | 1,084 | 54% | 1,250 |
| `/orchestrate` | 5,439 | 557 | 90% | 4,882 |
| `/implement` | 2,076 | 220 | 89% | 921 |
| `/plan` | 1,447 | 229 | 84% | 460 |
| `/debug` | 810 | 202 | 75% | 375 |
| `/document` | 563 | 168 | 70% | 669 |
| `/test` | 200 | 149 | 26% | 666 |

**Key Achievements**:
- ✅ Average 70% reduction in executable file size
- ✅ All files under 250-line target (largest: coordinate at 1,084 lines)
- ✅ Comprehensive guides averaging 1,300 lines of documentation
- ✅ Bidirectional cross-references established
- ✅ Zero meta-confusion loops in testing
- ✅ Pattern validated across command types

#### Validation Tool

**Script**: `.claude/tests/validate_executable_doc_separation.sh`

Verifies:
- All command files under 250 lines
- All guides exist and are referenced
- Cross-references valid both directions

---

## Command Development Guidelines

### Primary Guide

**Document**: `.claude/docs/guides/command-development-guide.md` (comprehensive, ~1000+ lines)

Covers:
1. Introduction (What is a command, when to create, command vs agent vs script)
2. Command Architecture (definition format, metadata, separation pattern)
3. Command Development Workflow (8-step process, quality checklist)
4. Standards Integration (standardization pattern template)
5. Agent Integration (behavioral injection pattern)
6. State Management Patterns (4 patterns with decision framework)
7. Testing and Validation
8. Common Patterns and Examples
9. References

**Section 2.4** (Executable/Documentation Separation Pattern) is the authoritative source for this architectural principle.

### Supporting Guides

**Command-Specific Guides** (`.claude/docs/guides/*-command-guide.md`):
- `/coordinate` guide (coordinate-command-guide.md)
- `/orchestrate` guide (orchestrate-command-guide.md)
- `/implement` guide (implement-command-guide.md)
- `/plan` guide (plan-command-guide.md)
- `/debug` guide (debug-command-guide.md)
- `/document` guide (document-command-guide.md)
- `/test` guide (test-command-guide.md)
- `/supervise` guide (supervise-guide.md)

All follow the two-file pattern with lean executables and comprehensive guides.

### Agent Development Guidelines

**Primary Guide**: `.claude/docs/guides/agent-development-guide.md`

Covers:
- Agent creation and design
- Behavioral injection pattern
- Layered context architecture (5 layers, 90-95% context reduction)
- Agent invocation and coordination patterns
- Testing and validation

**Standard 0.5**: Subagent Prompt Enforcement (in command_architecture_standards.md)
- Extension of Standard 0 for agent definition files
- Imperative language requirements for agents
- Sequential step dependencies
- File creation as primary obligation
- Template-based output enforcement
- Quality scoring rubric (95+/100 target)

---

## Documentation Patterns Currently Used

### Cross-Reference Pattern

**Bidirectional References**:

In executable files:
```markdown
# /command-name - Brief Title

YOU ARE EXECUTING AS the [command-name] command.

**Documentation**: See `.claude/docs/guides/command-name-command-guide.md`
```

In guide files:
```markdown
# /command-name Command - Complete Guide

**Executable**: `.claude/commands/command-name.md`
```

### Navigation Structure

**Top-Level README** (`.claude/docs/README.md`):
- "I Want To..." section (common tasks mapped to documentation)
- Quick navigation for agents (working on commands/agents/refactoring)
- Content ownership (single source of truth definitions)
- Documentation structure overview
- Browse by category (reference/guides/concepts/workflows)
- Quick start by role (new users/command developers/agent developers/contributors)

**Subdirectory READMEs**:
- Each subdirectory has its own README.md
- Index of files in that category
- Purpose and usage guidance
- Navigation links to related directories

### Pattern Documentation

**Location**: `.claude/docs/concepts/patterns/` (10 pattern files)

Documented architectural patterns:
1. **behavioral-injection.md** (41,965 bytes) - Reference behavioral files, inject context
2. **checkpoint-recovery.md** - State preservation and restoration
3. **context-management.md** - <30% context usage techniques
4. **forward-message.md** - Direct subagent response passing
5. **hierarchical-supervision.md** - Multi-level agent coordination
6. **metadata-extraction.md** - 95-99% context reduction via summaries
7. **parallel-execution.md** - Wave-based concurrent execution
8. **verification-fallback.md** - 100% file creation via checkpoints
9. **workflow-scope-detection.md** - Conditional phase execution by scope

Each pattern document includes:
- Problem statement
- Solution architecture
- Implementation examples
- Anti-patterns to avoid
- Integration with other patterns
- Testing and validation

---

## Cross-References and Integration

### How Documentation Files Reference Each Other

**Pattern Catalog** (`.claude/docs/concepts/patterns/README.md`):
- Central index of all architectural patterns
- Cross-references to guides that implement patterns
- Links to command architecture standards

**Command Architecture Standards** (`.claude/docs/reference/command_architecture_standards.md`):
- References specific patterns for each standard
- Links to guides for implementation details
- Cross-references to troubleshooting documentation

**Command Development Guide** (`.claude/docs/guides/command-development-guide.md`):
- References command architecture standards
- Links to specific patterns (behavioral injection, verification-fallback)
- Cross-references to agent development guide
- Links to testing patterns

**Agent Development Guide** (`.claude/docs/guides/agent-development-guide.md`):
- References command architecture standards (Standard 0.5, Standard 11, Standard 12)
- Links to behavioral injection pattern
- Cross-references to command development guide
- Links to hierarchical agents concept document

### Integration with CLAUDE.md

**Main Configuration** (`/home/benjamin/.config/CLAUDE.md`):
- References `.claude/docs/README.md` as central index
- Links to command architecture standards
- Links to specific guides (command development, agent development, model selection)
- References patterns (behavioral injection, verification-fallback, checkpoint recovery, parallel execution)
- Links to imperative language guide

**Section Markers**: CLAUDE.md uses HTML comments to mark sections:
```html
<!-- SECTION: section_name -->
Content here
<!-- END_SECTION: section_name -->
```

Sections include usage metadata:
```markdown
## Section Name
[Used by: /command1, /command2, /command3]
```

---

## Gaps and Opportunities

### Where Executable/Documentation Separation Standards Fit

**Current State**: The executable/documentation separation pattern is:
- ✅ **Already documented** in command-development-guide.md (Section 2.4)
- ✅ **Already implemented** across all major commands (7 commands migrated)
- ✅ **Has templates** (_template-executable-command.md, _template-command-guide.md)
- ✅ **Has validation tooling** (validate_executable_doc_separation.sh)
- ✅ **Has migration checklist** (10-item checklist in Section 2.4)
- ✅ **Has metrics** (migration results table with reductions)

**Gap Identified**: While comprehensively documented, this pattern could benefit from:

1. **Standalone Pattern Document**: Create `.claude/docs/concepts/patterns/executable-documentation-separation.md`
   - Extract from command-development-guide.md Section 2.4
   - Add to pattern catalog alongside behavioral-injection, verification-fallback, etc.
   - Provide more examples and anti-patterns
   - Link to case studies from migration

2. **Enhanced Cross-References**:
   - Add to `.claude/docs/concepts/patterns/README.md` pattern catalog
   - Reference from command architecture standards as a core principle
   - Link from agent development guide (agents also benefit from lean behavioral files)

3. **Expanded Troubleshooting**:
   - Add `.claude/docs/troubleshooting/meta-confusion-loops.md`
   - Document symptoms, detection, and remediation
   - Provide before/after examples from actual migrations

4. **Integration with Standard 12**:
   - Cross-reference executable/documentation separation with structural/behavioral separation
   - Show how both patterns work together
   - Unified decision framework for "what goes where"

### Natural Placement in Documentation Hierarchy

Based on analysis of existing structure, the pattern naturally fits in multiple locations:

**Primary Location** (Already Exists):
- `.claude/docs/guides/command-development-guide.md` Section 2.4
- This is the authoritative implementation guide

**Secondary Location** (Recommended Addition):
- `.claude/docs/concepts/patterns/executable-documentation-separation.md`
- This would provide understanding-oriented explanation
- Would join the pattern catalog alongside 9 existing patterns

**Reference Location**:
- `.claude/docs/reference/command_architecture_standards.md`
- Could add as Standard 14 or integrate with Standard 12
- Provides quick lookup for architectural requirement

**Quick Reference Location**:
- `.claude/docs/quick-reference/` could include decision tree
- "Should this content be in executable or guide?" flowchart
- Similar to existing template-usage-decision-tree.md

---

## Recommendations

### 1. Elevate Executable/Documentation Separation to Pattern Catalog

**Action**: Create `.claude/docs/concepts/patterns/executable-documentation-separation.md`

**Rationale**:
- Pattern is already proven (7 commands migrated, 70% average reduction)
- Deserves standalone documentation alongside other core patterns
- Makes pattern more discoverable for new developers

**Content Structure**:
```markdown
# Executable/Documentation Separation Pattern

## Problem Statement
- Meta-confusion loops in mixed-purpose command files
- Context bloat from extensive documentation
- Maintenance burden from coupled logic and docs

## Solution Architecture
- Two-file pattern: lean executable + comprehensive guide
- File size guidelines and cross-reference conventions
- Template-driven development

## Implementation
- Templates, migration checklist, validation tooling
- Integration with Standard 12 (structural/behavioral separation)

## Case Studies
- 7 command migrations with metrics
- Before/after examples
- Lessons learned

## Testing and Validation
- Validation script usage
- Quality metrics (line counts, cross-references)

## Cross-References
- Command Development Guide Section 2.4 (implementation details)
- Standard 12 (structural vs behavioral content)
- Template files
```

### 2. Add Quick Reference Decision Tree

**Action**: Create `.claude/docs/quick-reference/executable-vs-guide-content.md`

**Rationale**:
- Quick decision-making tool for developers
- Similar to existing template-usage-decision-tree.md
- Answers "where does this content belong?"

**Content**:
```
Should this content be in executable or guide?

├─ Is it a bash block? → Executable
├─ Is it imperative instruction? → Executable
├─ Is it architecture explanation? → Guide
├─ Is it troubleshooting? → Guide
├─ Is it usage example? → Guide
├─ Is it design rationale? → Guide
└─ Is it cross-reference? → Both
```

### 3. Enhance Command Architecture Standards Integration

**Action**: Update `.claude/docs/reference/command_architecture_standards.md`

**Changes**:
- Add cross-reference to executable/documentation separation pattern (new Standard 14 or integrate with Standard 12)
- Link to pattern catalog entry
- Reference validation tooling

**Rationale**:
- Ensures architectural standards document is comprehensive
- Provides quick lookup for this requirement
- Maintains single source of truth principle

### 4. Add Troubleshooting Guide

**Action**: Create `.claude/docs/troubleshooting/meta-confusion-loops.md`

**Content**:
- Symptoms (recursive invocations, Claude confused about role)
- Detection (command execution failures, unexpected behavior)
- Remediation (apply executable/documentation separation pattern)
- Prevention (use templates from start)
- Case studies from actual migrations

**Rationale**:
- Problem-focused documentation for when things go wrong
- Complements existing agent-delegation-troubleshooting.md
- Provides practical remediation steps

### 5. Update Pattern Catalog README

**Action**: Add executable/documentation separation to `.claude/docs/concepts/patterns/README.md`

**Changes**:
- Add pattern to catalog list
- Provide brief description
- Link to full pattern document
- Show relationship to Standard 12

**Rationale**:
- Maintains comprehensive pattern catalog
- Ensures discoverability
- Integrates with existing navigation structure

---

## Integration with Existing Standards

### Relationship to Standard 12 (Structural vs Behavioral)

The executable/documentation separation pattern and Standard 12 (structural vs behavioral content separation) are **complementary but distinct**:

**Standard 12** (Structural vs Behavioral):
- Focuses on WHAT content (structural templates vs behavioral guidelines)
- Answers: "Should this be inline or referenced from agent files?"
- Context: Agent invocation and coordination
- Goal: Single source of truth for agent behavior

**Executable/Documentation Separation**:
- Focuses on WHERE content goes (executable vs guide file)
- Answers: "Should this be in .claude/commands/ or .claude/docs/guides/?"
- Context: Command file organization
- Goal: Eliminate meta-confusion loops

**Together They Provide**:
1. Standard 12 determines inline vs referenced (structural vs behavioral)
2. Executable/documentation determines command vs guide (execution vs comprehension)
3. Combined decision matrix:
   - Structural templates (inline) → Executable file
   - Behavioral content (referenced) → Agent file
   - Architecture explanations → Guide file
   - Troubleshooting → Guide file
   - Usage examples → Guide file

### Relationship to Standard 11 (Imperative Agent Invocation)

Both patterns address **clarity and execution reliability**:

**Standard 11**:
- Ensures agent invocations are obviously executable
- Uses imperative language ("EXECUTE NOW", "USE the Task tool")
- No code block wrappers around Task invocations

**Executable/Documentation Separation**:
- Ensures command files are obviously executable
- Minimal documentation in executable
- Clear phase structure with bash blocks

**Synergy**: Both patterns prevent Claude from treating executable content as documentation or examples.

### Relationship to Diataxis Framework

The pattern aligns with Diataxis by placing content in appropriate categories:

- **Executable files**: Not in Diataxis (they're execution scripts, not documentation)
- **Guide files**: Task-oriented (how-to) documentation in guides/
- **Pattern document**: Understanding-oriented documentation in concepts/patterns/
- **Quick reference**: Decision tree in quick-reference/
- **Troubleshooting**: Problem-solving documentation in troubleshooting/

---

## Library and Utility Support

### Existing Utilities

**Library Files**: 85 bash scripts in `.claude/lib/`

Key libraries supporting command architecture:
- `artifact-creation.sh` - Topic directory and artifact path management
- `checkpoint-utils.sh` - State preservation and recovery
- `metadata-extraction.sh` - 95-99% context reduction
- `plan-core-bundle.sh` - Plan parsing and phase extraction
- `context-pruning.sh` - Aggressive cleanup after completion
- `unified-logger.sh` - Standardized logging for all commands
- `validate-agent-invocation-pattern.sh` - Detect anti-patterns
- `library-sourcing.sh` - Centralized library loading

### Testing Support

**Test Scripts**: Comprehensive test suite in `.claude/tests/`

Relevant tests:
- `validate_executable_doc_separation.sh` - Verify pattern compliance
- `test_orchestration_commands.sh` - Comprehensive orchestration testing
- `test_subagent_enforcement.sh` - Agent behavioral compliance
- `test_parsing_utilities.sh` - Plan parsing functions
- `test_command_integration.sh` - Command workflows

---

## Documentation Quality and Standards

### Current Documentation Standards

From `.claude/docs/README.md`:

**Documentation Standards**:
- NO emojis in file content
- Unicode box-drawing for diagrams
- Clear, concise language
- Code examples with syntax highlighting
- CommonMark specification
- Diataxis framework for organization

**Content Ownership** (Single Source of Truth):
- Patterns: `concepts/patterns/` catalog is authoritative
- Command Syntax: `reference/command-reference.md` is authoritative
- Agent Syntax: `reference/agent-reference.md` is authoritative
- Architecture: `concepts/hierarchical_agents.md` is authoritative

**Cross-Reference Principle**: Guides should cross-reference authoritative sources rather than duplicating content.

### Adherence in Executable/Documentation Pattern

The pattern follows all documentation standards:
- ✅ Clear separation of concerns
- ✅ No content duplication (guide references executable, not vice versa)
- ✅ Templates follow standards
- ✅ Migration checklist ensures quality
- ✅ Validation tooling enforces compliance
- ✅ Diataxis alignment (guides in guides/, patterns in concepts/patterns/)

---

## Conclusion

### Summary of Findings

1. **Documentation Structure**: Well-organized using Diataxis framework with 114 files across 8 directories

2. **Existing Standards**: Comprehensive command architecture standards with 14 core standards covering execution enforcement, inline requirements, reference patterns, and structural/behavioral separation

3. **Executable/Documentation Separation**: Already documented in command-development-guide.md Section 2.4 with:
   - Complete architecture documentation
   - Two templates for new command creation
   - Migration checklist (10 items)
   - Validation tooling
   - Proven results (7 commands, 70% average reduction)

4. **Gaps Identified**:
   - Pattern not yet in concepts/patterns/ catalog
   - No quick reference decision tree
   - No dedicated troubleshooting guide for meta-confusion
   - Not cross-referenced from command architecture standards

5. **Integration Opportunities**:
   - Elevate to standalone pattern document
   - Add to pattern catalog
   - Create quick reference decision tree
   - Add troubleshooting guide
   - Cross-reference from standards document

### Natural Fit in Documentation

The executable/documentation separation pattern naturally fits in **multiple locations** based on Diataxis:

- **Primary** (exists): guides/command-development-guide.md Section 2.4 (task-oriented)
- **Secondary** (recommended): concepts/patterns/executable-documentation-separation.md (understanding-oriented)
- **Reference** (recommended): command_architecture_standards.md cross-reference (information-oriented)
- **Quick Reference** (recommended): quick-reference/executable-vs-guide-content.md (decision-oriented)
- **Troubleshooting** (recommended): troubleshooting/meta-confusion-loops.md (problem-solving)

### Next Steps

To fully integrate executable/documentation separation standards into the documentation system:

1. Create standalone pattern document in concepts/patterns/
2. Add to pattern catalog README
3. Create quick reference decision tree
4. Add troubleshooting guide for meta-confusion loops
5. Cross-reference from command architecture standards
6. Update CLAUDE.md to reference pattern in appropriate sections

The pattern is **already successfully implemented** and **comprehensively documented**. These recommendations would enhance discoverability and provide multiple entry points for developers encountering this architectural principle.

---

## Metadata

- **Research Date**: 2025-11-07
- **Documentation Files Analyzed**: 114 markdown files
- **Commands Analyzed**: 7 major commands (coordinate, orchestrate, implement, plan, debug, document, test)
- **Standards Reviewed**: 14 standards in command architecture standards document
- **Patterns Reviewed**: 9 patterns in patterns catalog
- **Libraries Counted**: 85 bash scripts in .claude/lib/
- **External Sources**: None (codebase analysis only)
- **Key Finding**: Pattern already exists, documented, and proven - recommendations focus on enhanced discoverability and cross-referencing
