# Documentation Standards for Skills Research Report

## Executive Summary

Documentation standards for skills integration follow a comprehensive framework defined across multiple reference files. Key standards include: (1) README requirements mandate purpose, module docs, usage examples, and navigation links in every subdirectory; (2) Timeless writing policy prohibits temporal markers like "(New)" or "previously" in functional documentation; (3) Command/agent files use imperative enforcement language ("YOU MUST", "EXECUTE NOW"); (4) Template completeness requires copy-paste ready examples without truncation; (5) Topic-based artifact organization structures all documentation under `specs/{NNN_topic}/` directories; (6) UTF-8 encoding with no emojis in file content. Standards apply hierarchically with subdirectory CLAUDE.md files extending parent standards. Enforcement includes pre-commit hooks, validation scripts, and structural annotations distinguishing execution-critical from reference-ok content.

## Current State Analysis

### Documentation Policy (CLAUDE.md:354-378)

The project defines comprehensive documentation requirements:

**README Requirements** - Every subdirectory must have README.md containing:
- Purpose: Clear explanation of directory role
- Module Documentation: Documentation for each file/module
- Usage Examples: Code examples where applicable
- Navigation Links: Links to parent and subdirectory READMEs

**Documentation Format Standards**:
- Use clear, concise language
- Include code examples with syntax highlighting
- Use Unicode box-drawing for diagrams (see nvim/CLAUDE.md)
- No emojis in file content (UTF-8 encoding issues)
- Follow CommonMark specification
- No historical commentary (see Development Philosophy)

**Documentation Updates**:
- Update documentation with code changes
- Keep examples current with implementation
- Document breaking changes prominently
- Remove historical markers when updating docs

### Writing Standards (.claude/docs/concepts/writing-standards.md:1-558)

Comprehensive guide covering three major areas:

**1. Development Philosophy (lines 9-45)**:
- Prioritize coherence over backward compatibility
- Clean-break refactors preferred
- System integration matters more than legacy support
- Exception: Command/agent files require special refactoring rules (AI prompts, not code)

**2. Timeless Writing Principles (lines 66-253)**:
- Present-focused, current state descriptions
- Banned temporal markers: (New), (Old), (Updated), (Deprecated), (Current), (Original)
- Banned temporal phrases: "previously", "recently", "now supports", "used to", "no longer"
- Banned migration language: "migration from", "backward compatibility", "breaking change"
- Separation of concerns: Functional docs (timeless) vs CHANGELOG.md (historical) vs migration guides

**3. Enforcement Tools (lines 469-533)**:
- Grep validation script: `.claude/scripts/validate_docs_timeless.sh`
- Pre-commit hook integration for doc validation
- Scans for temporal markers, phrases, migration language

### Command Architecture Standards (.claude/docs/reference/command_architecture_standards.md)

**Standard 0: Execution Enforcement (lines 50-417)**:
- Imperative vs descriptive language distinction
- Required patterns: "YOU MUST", "EXECUTE NOW", "MANDATORY VERIFICATION"
- Enforcement patterns: direct execution blocks, verification checkpoints, non-negotiable agent prompts
- Language strength hierarchy: Critical → Mandatory → Strong → Standard → Optional

**Standard 0.5: Subagent Prompt Enforcement (lines 419-912)**:
- Agent definition files follow same enforcement principles
- Pattern A: Role declaration transformation ("I am" → "YOU MUST")
- Pattern B: Sequential step dependencies (STEP 1 REQUIRED BEFORE STEP 2)
- Pattern C: File creation as primary obligation
- Pattern D: Elimination of passive voice
- Pattern E: Template-based output enforcement

**Standards 1-5: File Structure (lines 931-1125)**:
- Standard 1: Executable instructions must be inline
- Standard 2: Reference pattern (instructions first, reference after)
- Standard 3: Critical information density
- Standard 4: Template completeness (copy-paste ready)
- Standard 5: Structural annotations ([EXECUTION-CRITICAL], [INLINE-REQUIRED], [REFERENCE-OK])

### Agent Documentation Standards (.claude/agents/README.md)

**Agent Definition Format (lines 308-337)**:
- Frontmatter metadata: allowed-tools, description
- System prompt structure: introduction, capabilities, standards compliance, behavioral guidelines, expected input/output
- Standards compliance section references CLAUDE.md explicitly
- Output format specifications for metadata extraction compatibility

**Documentation Standards Section (lines 580-590)**:
- NO emojis in file content
- Unicode box-drawing for diagrams
- Clear, concise language
- Code examples with syntax highlighting
- CommonMark specification compliance

### Template System (.claude/templates/README.md)

**Template Format Standards (lines 9-30)**:
- YAML structure with name, description, variables, phases, research_topics
- Variable substitution syntax: `{{variable_name}}`
- Array iteration: `{{#each array_var}}...{{/each}}`
- Conditionals: `{{#if variable}}...{{/if}}`

**Documentation Requirements (lines 105-127)**:
- Variable naming: snake_case, descriptive
- Task specificity: reference specific files, include line number hints
- Phase structure: 5-10 tasks each, dependencies enforced
- Research topics: 2-4 relevant topics with variable substitution

### Directory Protocols (.claude/docs/concepts/directory-protocols.md)

**Artifact Organization (lines 20-152)**:
- Topic-based structure: `specs/{NNN_topic}/{artifact_type}/NNN_artifact_name.md`
- Artifact types: plans/, reports/, summaries/, debug/, scripts/, outputs/, artifacts/, backups/
- Numbering: Three-digit sequential (001, 002, 003...) per topic and type
- Metadata-only references: Extract title + 50-word summary (95% context reduction)

**Documentation in Artifacts (lines 186-229)**:
- Debug reports use structured template with metadata, issue description, root cause, fix proposals, resolution
- Debug reports committed to git (project history)
- Other artifacts gitignored (local working files)

## Research Findings

### Documentation Structure Patterns

**Hierarchical Organization**:
1. **CLAUDE.md** (root) - Central configuration, standards index, links to detailed guides
2. **.claude/docs/** - Detailed standards, guides, reference documentation
3. **Subdirectory CLAUDE.md** - Directory-specific standards extending parent
4. **README.md** (every directory) - Purpose, module docs, usage examples, navigation

**Standards Discovery Method** (command-development-guide.md:383-397):
- Search upward from current directory for CLAUDE.md
- Check subdirectory-specific CLAUDE.md files
- Merge/override: subdirectory standards extend parent standards
- Fallback: Use sensible language-specific defaults, suggest /setup

### Enforcement Mechanisms

**1. Pre-Commit Validation**:
- Location: `.git/hooks/pre-commit`
- Validates command file integrity (line count, critical patterns, Task examples)
- Runs timeless writing validation on documentation files
- Example check: Command files must be ≥300 lines for main commands

**2. Structural Annotations** (command_architecture_standards.md:1097-1125):
- `[EXECUTION-CRITICAL]` - Cannot be moved to external files
- `[INLINE-REQUIRED]` - Must stay inline for tool invocation
- `[REFERENCE-OK]` - Can be supplemented with external references
- `[EXAMPLE-ONLY]` - Can be moved to external files if core example remains

**3. Quality Checklists**:
- Command development checklist: Structure, content, standards integration, agent integration, testing, documentation (command-development-guide.md:287-326)
- Agent development checklist: Structure, content, behavior, testing (agent-development-guide.md:820-847)
- Review checklist for command/agent file changes (command_architecture_standards.md:1559-1613)

### Integration Patterns

**Skills as Specialized Agents**:
- Skills follow agent definition format (allowed-tools, description frontmatter)
- Behavioral guidelines in markdown body
- Tool restrictions enforce security/predictability
- Invocation via general-purpose agent type with behavioral injection

**Documentation Requirements for Skills**:
1. **Frontmatter**: allowed-tools (minimal set), description (one-line purpose)
2. **Core Capabilities**: Hierarchical breakdown of what skill does
3. **Standards Compliance**: References to project standards (CLAUDE.md sections)
4. **Behavioral Guidelines**: Decision-making process, priorities, workflow expectations
5. **Expected Input**: Required context, format guidelines
6. **Expected Output**: Deliverables, success indicators, format specifications

**Metadata Extraction Compatibility**:
- Output formats must support `extract_report_metadata()` for 95% context reduction
- Research agents: Include "Executive Summary" (50-word), "Key Findings", "Recommendations"
- Planning agents: Include "Metadata" section with complexity, time estimate, phases
- Structured outputs enable metadata-only passing between workflow stages

## Recommendations

### 1. Create Skills Documentation Template

**Action**: Develop `.claude/templates/skill-definition-template.md` following agent definition format.

**Structure**:
```markdown
---
allowed-tools: Read, Write, Edit, [other tools]
description: Brief one-line description of skill purpose
---

# Skill Name

System prompt defining skill behavior and capabilities.

## Core Capabilities

[Hierarchical breakdown of skill functionality]

## Standards Compliance

[References to CLAUDE.md sections this skill follows]

## Behavioral Guidelines

[Decision-making process, priorities, workflow expectations]

## Expected Input

[Required context, format guidelines, example inputs]

## Expected Output

[Deliverables, success indicators, format specifications with metadata extraction compatibility]
```

**Rationale**: Standardizes skill documentation across all skill files, ensures enforcement patterns, supports metadata extraction.

### 2. Add Skills README with Standards References

**Action**: Create `.claude/skills/README.md` documenting:
- Purpose of skills directory
- Relationship to agents (specialized capabilities)
- Documentation requirements (links to command_architecture_standards.md)
- Tool access patterns
- Invocation patterns (behavioral injection)
- Quality checklist for skills development
- Navigation links to related documentation

**Rationale**: Provides central reference for skills development, ensures standards discoverability, maintains documentation hierarchy.

### 3. Integrate Skills with /setup Command

**Action**: Extend `/setup` command to:
- Detect `.claude/skills/` directory
- Validate skill definition format (frontmatter, sections)
- Check skills README exists
- Suggest creating missing documentation
- Add skills section to generated CLAUDE.md if skills present

**Rationale**: Automates documentation bootstrapping, ensures skills follow project standards, provides feedback on compliance.

### 4. Apply Enforcement Patterns to Skills

**Action**: Update existing skill files to use:
- Imperative language for critical steps ("YOU MUST", "EXECUTE NOW")
- Sequential step dependencies ("STEP 1 REQUIRED BEFORE STEP 2")
- File creation as primary obligation for output-generating skills
- Verification checkpoints ("MANDATORY VERIFICATION")
- Template-based output enforcement ("THIS EXACT TEMPLATE")

**Rationale**: Ensures skills follow command_architecture_standards.md Standard 0.5, improves reliability, reduces agent non-compliance.

### 5. Add Skills to Pre-Commit Validation

**Action**: Extend `.git/hooks/pre-commit` to validate skills:
- Check skill files ≥200 lines (minimum for skill definition)
- Verify frontmatter complete (allowed-tools, description)
- Check for critical sections (Core Capabilities, Standards Compliance, Expected Input/Output)
- Scan for temporal markers/phrases (timeless writing policy)

**Rationale**: Prevents documentation debt, enforces standards automatically, catches violations early.

## Implementation Guidance

### Phase 1: Documentation Infrastructure
1. Create skill definition template in `.claude/templates/`
2. Create skills README in `.claude/skills/`
3. Add skills validation to pre-commit hook
4. Document skills integration in command-development-guide.md

### Phase 2: Standards Application
1. Apply enforcement patterns to existing skill files (imperative language, verification checkpoints)
2. Add metadata extraction compatibility to skill outputs
3. Validate all skills against quality checklist
4. Update cross-references in agent-reference.md and command-reference.md

### Phase 3: Tooling Integration
1. Extend `/setup` command with skills detection and validation
2. Add skills section to CLAUDE.md generation
3. Create skills-specific validation script (similar to validate_docs_timeless.sh)
4. Test complete workflow: create skill → validate → integrate → document

### Testing Strategy
- **Unit**: Validate individual skill files against template
- **Integration**: Test skill invocation via behavioral injection pattern
- **Standards Compliance**: Run all validation scripts on skills directory
- **Documentation**: Verify all README files link correctly, navigation complete

### Success Criteria
- All skills have complete frontmatter (allowed-tools, description)
- All skills include required sections (Core Capabilities, Standards Compliance, Behavioral Guidelines, Expected Input, Expected Output)
- All skills pass timeless writing validation (no temporal markers)
- All skills pass pre-commit validation
- Skills README provides complete navigation and standards references
- `/setup` command detects and validates skills directory

## References

### Primary Standards Documents
- `/home/benjamin/.config/CLAUDE.md:354-378` - Documentation Policy
- `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md:1-558` - Writing Standards
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md:50-912` - Command Architecture Standards (Standard 0, Standard 0.5)
- `/home/benjamin/.config/.claude/agents/README.md:308-337,580-590` - Agent Documentation Standards

### Supporting Documentation
- `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md:330-397` - Standards Integration
- `/home/benjamin/.config/.claude/docs/guides/agent-development-guide.md:1-884` - Agent Development Guide
- `/home/benjamin/.config/.claude/templates/README.md:1-287` - Template System Standards
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md:1-1021` - Directory Protocols

### Validation Tools
- `.claude/scripts/validate_docs_timeless.sh` - Timeless writing validation
- `.git/hooks/pre-commit` - Pre-commit validation hooks
- `.claude/lib/metadata-extraction.sh` - Metadata extraction utilities

## Metadata

- **Research Date**: 2025-10-23
- **Files Analyzed**: 9 primary files (CLAUDE.md, writing-standards.md, command_architecture_standards.md, agent-reference.md, command-development-guide.md, agent-development-guide.md, agents/README.md, templates/README.md, directory-protocols.md)
- **Key Concepts Identified**: Timeless writing policy, execution enforcement, behavioral injection, metadata extraction, structural annotations, hierarchical organization
- **Standards Coverage**: README requirements, documentation format, writing standards, command/agent architecture, template format, artifact organization
