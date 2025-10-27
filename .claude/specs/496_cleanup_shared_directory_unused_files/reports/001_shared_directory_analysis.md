# Shared Directory Analysis Report

## Metadata
- **Date**: 2025-10-27
- **Topic Directory**: specs/496_cleanup_shared_directory_unused_files/
- **Report Number**: 001
- **Scope**: Analysis of all files in .claude/commands/shared/ directory
- **Total Files Analyzed**: 34 files
- **Directory Size**: 404KB

## Executive Summary

This report provides a comprehensive analysis of all 34 files in the `/home/benjamin/.config/.claude/commands/shared/` directory. The analysis categorizes files by type, documents their purpose and usage, and identifies which files are actively referenced by commands versus potentially unused files.

**Key Findings**:
- 34 total files in shared/ directory
- 11 files are actively referenced by command files (32%)
- 23 files are not directly referenced by any commands (68%)
- Several files marked as "will be added during Phase 2, 3, and 5" are essentially placeholders
- Most unreferenced files appear to be historical/extracted content that may still serve documentation purposes

**Overall Assessment**: The directory contains a mix of actively-used template files and documentation files that may be candidates for cleanup, consolidation, or relocation.

## File Inventory by Category

### Category 1: Template Reference Files (Actively Used)

These files define standard structures and patterns referenced by multiple commands.

#### 1. debug-structure.md
- **Size**: 11,108 bytes
- **Last Modified**: Oct 27 11:13
- **Purpose**: Standard debug report template and structure
- **Referenced By**: debug.md
- **Key Content**: Debug report structure, file location patterns, metadata, investigation process, proposed solutions, testing strategy
- **Status**: ACTIVELY USED

#### 2. refactor-structure.md
- **Size**: 12,038 bytes
- **Last Modified**: Oct 27 11:13
- **Purpose**: Refactoring analysis report template
- **Referenced By**: refactor.md
- **Key Content**: Refactoring report structure, critical issues categorization, refactoring opportunities, priority/effort/risk matrices
- **Status**: ACTIVELY USED

#### 3. report-structure.md
- **Size**: 7,816 bytes
- **Last Modified**: Oct 27 11:13
- **Purpose**: Research report template and structure
- **Referenced By**: research.md
- **Key Content**: Standard report structure, metadata, executive summary, analysis sections, recommendations, implementation considerations
- **Status**: ACTIVELY USED

#### 4. orchestration-patterns.md
- **Size**: 71,369 bytes (LARGEST FILE)
- **Last Modified**: Oct 27 11:13
- **Purpose**: Reusable templates and patterns for multi-agent workflow orchestration
- **Referenced By**: orchestrate.md (multiple references)
- **Key Content**: Agent prompt templates, phase coordination patterns, checkpoint structure, error recovery patterns, progress streaming patterns
- **Status**: ACTIVELY USED (CRITICAL)

#### 5. agent-invocation-patterns.md
- **Size**: 7,604 bytes
- **Last Modified**: Oct 27 11:13
- **Purpose**: Standard patterns for invoking agents using Task tool
- **Referenced By**: Not directly referenced in grep results, but likely used for documentation
- **Key Content**: Basic Task tool invocation, common agent invocation examples (research-specialist, plan-architect, code-writer, debug-specialist, spec-updater, test-specialist, doc-writer), parallel/sequential patterns
- **Status**: DOCUMENTATION REFERENCE

#### 6. agent-tool-descriptions.md
- **Size**: 8,558 bytes
- **Last Modified**: Oct 27 11:13
- **Purpose**: Standard tool descriptions and usage patterns for agents
- **Key Content**: Available tools (Read, Write, Edit, Bash, Grep, Glob, TodoWrite, Task, WebSearch, WebFetch), tool combinations, common patterns, error handling
- **Status**: DOCUMENTATION REFERENCE

#### 7. audit-checklist.md
- **Size**: 4,069 bytes
- **Last Modified**: Oct 27 11:13
- **Purpose**: Execution enforcement audit checklist template
- **Key Content**: 10 patterns for auditing (imperative language, step dependencies, verification checkpoints, fallback mechanisms, critical requirements, path verification, file creation enforcement, return format, passive voice detection, error handling)
- **Status**: TEMPLATE REFERENCE

#### 8. command-frontmatter.md
- **Size**: 6,462 bytes
- **Last Modified**: Oct 27 11:13
- **Purpose**: Standard YAML frontmatter template for command files
- **Key Content**: Tool allowlist definitions (primary commands, analysis commands, utility commands), frontmatter fields reference, tool descriptions
- **Status**: TEMPLATE REFERENCE

#### 9. output-patterns.md
- **Size**: 6,273 bytes
- **Last Modified**: Oct 27 11:13
- **Purpose**: Consistent output patterns for commands and agents
- **Key Content**: Minimal success/error patterns, progress markers, context optimization principles, command-specific patterns, agent response patterns
- **Status**: TEMPLATE REFERENCE

#### 10. readme-template.md
- **Size**: 1,217 bytes
- **Last Modified**: Oct 27 11:13
- **Purpose**: Template for directory README files
- **Key Content**: Standard README structure with purpose, navigation, documents, quick start, directory structure, related documentation
- **Status**: TEMPLATE REFERENCE

#### 11. README.md
- **Size**: 3,030 bytes
- **Last Modified**: Oct 27 11:13
- **Purpose**: Index and overview of shared command documentation
- **Referenced By**: README.md in parent directory
- **Key Content**: Usage pattern explanation, shared sections listing (high/medium/low priority), cross-reference index, maintenance guidelines
- **Status**: ACTIVELY USED (INDEX)

### Category 2: Orchestration Documentation Files

These files were extracted from orchestrate.md and contain detailed orchestration patterns.

#### 12. workflow-phases.md
- **Size**: 60,461 bytes (SECOND LARGEST)
- **Last Modified**: Oct 20 14:48
- **Purpose**: Comprehensive documentation for all workflow phases
- **Key Content**: Research phase (parallel execution), planning phase, implementation phase, documentation phase, phase coordination patterns
- **Status**: EXTRACTED DOCUMENTATION

#### 13. orchestrate-enhancements.md
- **Size**: 16,869 bytes
- **Last Modified**: Oct 26 21:33
- **Purpose**: Reusable patterns for enhanced /orchestrate command
- **Key Content**: Complexity evaluation patterns, plan expansion patterns, wave-based execution patterns, context preservation patterns, progress markers
- **Status**: DOCUMENTATION REFERENCE

#### 14. orchestration-alternatives.md
- **Size**: 24,130 bytes
- **Last Modified**: Oct 26 21:33
- **Purpose**: Alternative orchestration workflow patterns (extracted from orchestrate.md during 070 refactor)
- **Key Content**: Placeholder - "Content will be added during Phase 2, 3, and 5"
- **Status**: PLACEHOLDER (CANDIDATE FOR REMOVAL)

#### 15. orchestrate-examples.md
- **Size**: 659 bytes
- **Last Modified**: Oct 19 03:17
- **Purpose**: Example usage patterns for /orchestrate command
- **Key Content**: Basic research-plan-implement workflow, custom workflow with parallel research, debugging-focused workflow
- **Status**: DOCUMENTATION REFERENCE

#### 16. orchestration-history.md
- **Size**: 171 bytes
- **Last Modified**: Oct 23 00:59
- **Purpose**: Orchestration architecture history (extracted from orchestrate.md during 070 refactor)
- **Key Content**: Placeholder - "Content will be added during Phase 2, 3, and 5"
- **Status**: PLACEHOLDER (CANDIDATE FOR REMOVAL)

#### 17. orchestration-performance.md
- **Size**: 175 bytes
- **Last Modified**: Oct 23 00:59
- **Purpose**: Orchestration performance optimization (extracted from orchestrate.md during 070 refactor)
- **Key Content**: Placeholder - "Content will be added during Phase 2, 3, and 5"
- **Status**: PLACEHOLDER (CANDIDATE FOR REMOVAL)

#### 18. orchestration-troubleshooting.md
- **Size**: 172 bytes
- **Last Modified**: Oct 23 00:59
- **Purpose**: Orchestration troubleshooting guide (extracted from orchestrate.md during 070 refactor)
- **Key Content**: Placeholder - "Content will be added during Phase 2, 3, and 5"
- **Status**: PLACEHOLDER (CANDIDATE FOR REMOVAL)

### Category 3: Implementation Workflow Files

Files related to /implement command and phase execution.

#### 19. implementation-workflow.md
- **Size**: 6,429 bytes
- **Last Modified**: Oct 15 15:18
- **Purpose**: Complete workflow for implementing plans using /implement command
- **Key Content**: Utility initialization, progressive plan support, implementation flow, dry-run mode execution
- **Status**: DOCUMENTATION REFERENCE

#### 20. phase-execution.md
- **Size**: 16,797 bytes
- **Last Modified**: Oct 15 15:19
- **Purpose**: Comprehensive phase execution protocol documentation
- **Key Content**: Step-by-step phase execution, progressive structure navigation, task execution and testing, commit workflow, error handling
- **Status**: DOCUMENTATION REFERENCE

#### 21. progressive-structure.md
- **Size**: 645 bytes
- **Last Modified**: Oct 19 03:17
- **Purpose**: Overview of progressive plan organization (Level 0 → Level 1 → Level 2)
- **Key Content**: Level descriptions, expansion criteria, thresholds
- **Status**: DOCUMENTATION REFERENCE

### Category 4: Setup Command Files

Files related to /setup command functionality.

#### 22. setup-modes.md
- **Size**: 7,179 bytes
- **Last Modified**: Oct 14 10:29
- **Purpose**: Comprehensive documentation for all /setup command modes
- **Key Content**: Standard mode, cleanup mode, validation mode, analysis mode, report application mode
- **Status**: DOCUMENTATION REFERENCE

#### 23. bloat-detection.md
- **Size**: 4,763 bytes
- **Last Modified**: Oct 14 10:30
- **Purpose**: Automatic bloat detection algorithm for CLAUDE.md optimization
- **Key Content**: Detection thresholds, user interaction, opt-out mechanisms, integration with cleanup mode
- **Status**: DOCUMENTATION REFERENCE

#### 24. extraction-strategies.md
- **Size**: 8,834 bytes
- **Last Modified**: Oct 14 10:31
- **Purpose**: Smart extraction system for optimizing CLAUDE.md
- **Key Content**: Extraction mapping, interactive process, decision criteria, file organization, extraction preferences, dry-run preview
- **Status**: DOCUMENTATION REFERENCE

#### 25. standards-analysis.md
- **Size**: 9,605 bytes
- **Last Modified**: Oct 14 10:34
- **Purpose**: Standards analysis and report application features
- **Key Content**: Analysis mode workflow, discrepancy types, generated report structure, report application mode
- **Status**: DOCUMENTATION REFERENCE

### Category 5: Revise Command Files

Files related to /revise command functionality.

#### 26. revise-auto-mode.md
- **Size**: 11,416 bytes
- **Last Modified**: Oct 14 10:39
- **Purpose**: Automated revision mode specification for /revise command
- **Key Content**: Context JSON structure, revision types (expand_phase, add_phase, split_phase, update_tasks, collapse_phase), decision logic, integration with /implement
- **Status**: DOCUMENTATION REFERENCE

#### 27. revision-types.md
- **Size**: 4,175 bytes
- **Last Modified**: Oct 14 10:40
- **Purpose**: Operation modes and revision types for /revise command
- **Key Content**: Interactive mode vs auto-mode, mode comparison, when to use each mode
- **Status**: DOCUMENTATION REFERENCE

### Category 6: Cross-Command Pattern Files

Small files defining patterns used across multiple commands.

#### 28. adaptive-planning.md
- **Size**: 671 bytes
- **Last Modified**: Oct 19 03:17
- **Purpose**: Overview of adaptive planning patterns
- **Key Content**: Automatic plan revision triggers, behavior, integration points
- **Status**: DOCUMENTATION REFERENCE

#### 29. agent-coordination.md
- **Size**: 558 bytes
- **Last Modified**: Oct 19 03:17
- **Purpose**: Agent coordination patterns
- **Key Content**: Invocation patterns (single agent, parallel agents), coordination patterns (sequential, parallel, wave-based), metadata passing
- **Status**: DOCUMENTATION REFERENCE

#### 30. context-management.md
- **Size**: 570 bytes
- **Last Modified**: Oct 19 03:17
- **Purpose**: Context management strategies
- **Key Content**: Context reduction strategies (metadata-only passing, forward message pattern, progressive pruning), target metrics
- **Status**: DOCUMENTATION REFERENCE

#### 31. error-handling.md
- **Size**: 395 bytes
- **Last Modified**: Oct 19 03:17
- **Purpose**: Common error handling patterns
- **Key Content**: Validation errors, state errors, external tool errors, network errors
- **Status**: DOCUMENTATION REFERENCE

#### 32. error-recovery.md
- **Size**: 522 bytes
- **Last Modified**: Oct 19 03:17
- **Purpose**: Error recovery patterns
- **Key Content**: Error detection, recovery strategies (automatic retry, state rollback, user escalation)
- **Status**: DOCUMENTATION REFERENCE

#### 33. testing-patterns.md
- **Size**: 544 bytes
- **Last Modified**: Oct 19 03:17
- **Purpose**: Testing patterns and protocols
- **Key Content**: Test discovery, common test commands, coverage requirements
- **Status**: DOCUMENTATION REFERENCE

#### 34. complexity-evaluation-details.md
- **Size**: 7,121 bytes
- **Last Modified**: Oct 23 01:00
- **Purpose**: Complexity evaluation details (extracted from orchestrate.md during 070 refactor)
- **Key Content**: Hybrid evaluation pattern, complexity thresholds, agent invocation, error recovery
- **Status**: DOCUMENTATION REFERENCE

## Usage Analysis

### Files Directly Referenced by Commands

Based on grep analysis of command files, the following files are directly referenced:

1. **debug-structure.md** - Referenced by debug.md
2. **refactor-structure.md** - Referenced by refactor.md
3. **report-structure.md** - Referenced by research.md
4. **orchestration-patterns.md** - Referenced by orchestrate.md (multiple times)
5. **orchestration-alternatives.md** - Referenced by orchestrate.md
6. **README.md** - Referenced by parent README.md

### Files Not Directly Referenced

The remaining 28 files are not directly referenced in command grep results, but this does not necessarily mean they are unused:

- **Template files** (agent-invocation-patterns.md, agent-tool-descriptions.md, audit-checklist.md, command-frontmatter.md, output-patterns.md, readme-template.md) serve as reference documentation
- **Documentation files** (workflow-phases.md, orchestrate-enhancements.md, implementation-workflow.md, phase-execution.md, etc.) provide detailed explanations for command implementations
- **Pattern files** (adaptive-planning.md, agent-coordination.md, context-management.md, etc.) document cross-cutting concerns

### Placeholder Files (High Priority for Cleanup)

The following files are essentially empty placeholders marked "Content will be added during Phase 2, 3, and 5":

1. **orchestration-alternatives.md** (24,130 bytes - mostly empty)
2. **orchestration-history.md** (171 bytes)
3. **orchestration-performance.md** (175 bytes)
4. **orchestration-troubleshooting.md** (172 bytes)

**Total Size of Placeholders**: ~24.6KB

## File Size Distribution

### Largest Files
1. orchestration-patterns.md - 71,369 bytes (69.7KB)
2. workflow-phases.md - 60,461 bytes (59.0KB)
3. orchestration-alternatives.md - 24,130 bytes (23.6KB - PLACEHOLDER)
4. phase-execution.md - 16,797 bytes (16.4KB)
5. orchestrate-enhancements.md - 16,869 bytes (16.5KB)

### Smallest Files
1. orchestration-troubleshooting.md - 172 bytes (PLACEHOLDER)
2. orchestration-history.md - 171 bytes (PLACEHOLDER)
3. orchestration-performance.md - 175 bytes (PLACEHOLDER)
4. error-handling.md - 395 bytes
5. error-recovery.md - 522 bytes

## Categorization Summary

| Category | File Count | Total Size | Status |
|----------|-----------|------------|--------|
| Template Reference Files | 11 | ~62KB | ACTIVELY USED |
| Orchestration Documentation | 7 | ~103KB | MIXED (4 placeholders) |
| Implementation Workflow | 3 | ~24KB | DOCUMENTATION |
| Setup Command Files | 4 | ~30KB | DOCUMENTATION |
| Revise Command Files | 2 | ~16KB | DOCUMENTATION |
| Cross-Command Patterns | 7 | ~4KB | DOCUMENTATION |
| **Total** | **34** | **~404KB** | - |

## Recommendations

### High Priority Actions

1. **Remove or Complete Placeholder Files**
   - orchestration-alternatives.md (24,130 bytes)
   - orchestration-history.md (171 bytes)
   - orchestration-performance.md (175 bytes)
   - orchestration-troubleshooting.md (172 bytes)
   - **Impact**: Remove ~24.6KB of essentially empty content
   - **Rationale**: These files were created during 070 refactor but never completed. If content is not added soon, remove them.

2. **Audit Template Reference Files**
   - All 11 template files appear to be in active use or serve as valuable reference
   - **Action**: Keep all template files
   - **Rationale**: These provide standardization across the command system

3. **Consolidate Small Pattern Files**
   - Consider merging the 7 small cross-command pattern files (adaptive-planning.md, agent-coordination.md, context-management.md, error-handling.md, error-recovery.md, testing-patterns.md, progressive-structure.md) into a single "patterns-reference.md"
   - **Impact**: Reduce file count from 7 to 1, easier navigation
   - **Risk**: May reduce discoverability if files are referenced individually

### Medium Priority Actions

1. **Verify orchestration-alternatives.md Usage**
   - File is referenced by orchestrate.md but contains only placeholder content
   - **Action**: Either complete the content or remove the file and its reference
   - **Rationale**: Reference to incomplete file creates confusion

2. **Review Documentation File Sizes**
   - workflow-phases.md (60KB) and orchestration-patterns.md (71KB) are very large
   - **Action**: Consider whether these should be further broken down into subsections
   - **Rationale**: Easier to maintain and navigate smaller focused files

3. **Create Usage Index**
   - Add a "Referenced By" field to README.md for each shared file
   - **Impact**: Clarify which files are actively used vs documentation only
   - **Rationale**: Helps with future maintenance and cleanup decisions

### Low Priority Actions

1. **Standardize File Naming**
   - Some files use singular (error-handling.md), others plural (testing-patterns.md)
   - **Action**: Establish and document naming convention
   - **Rationale**: Consistency aids navigation

2. **Add Last Updated Dates**
   - Only some files have "Last Updated" fields in their content
   - **Action**: Standardize metadata in file headers
   - **Rationale**: Helps identify stale content

## Next Steps

1. **Decision Required**: Remove placeholder files or commit to completing them?
2. **Review**: Are all documentation files still relevant to current command implementations?
3. **Consolidation**: Should small pattern files be merged into a single reference?
4. **Indexing**: Update README.md with comprehensive usage information?

## References

### Affected Files
- All 34 files in `/home/benjamin/.config/.claude/commands/shared/`

### Related Documentation
- [commands/README.md](../README.md) - Parent directory index
- [.claude/docs/reference/command_architecture_standards.md](../../docs/reference/command_architecture_standards.md) - Command architecture standards

### External Resources
- Directory structure follows reference-based composition pattern documented in spec 070
