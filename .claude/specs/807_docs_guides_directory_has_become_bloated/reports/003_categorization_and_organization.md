# Categorization and Organization Proposal

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Directory Structure and Guide Categorization
- **Report Type**: pattern recognition

## Executive Summary

The guides directory should be reorganized from a flat structure (78 files) into 5 logical subdirectories: commands/, development/, orchestration/, patterns/, and templates/. This reorganization groups related content, improves discoverability, and enables targeted maintenance. Combined with archiving 12 unused files and cleaning split file legacy content, the result is a streamlined structure of ~55 active files across well-defined categories.

## Findings

### Current Structure Analysis

**Current State**: Flat directory with 78 files
- No logical grouping
- Difficult to find related content
- Mix of active guides, redirect stubs, split files, and templates
- README.md attempts to organize via sections but file system doesn't reflect it

**File Distribution by Topic**:
- Command-specific guides: 17 files
- Development patterns: 12 files
- Orchestration & workflows: 8 files
- Reference & standards: 6 files
- Templates: 3 files
- Agent-specific guides: 8 files
- Split file fragments: 18 files
- Redirect stubs/minimal content: 12 files

### Proposed Directory Structure

```
.claude/docs/guides/
├── README.md                           # Index and navigation
├── commands/                           # Command-specific documentation
│   ├── README.md
│   ├── build-command-guide.md
│   ├── collapse-command-guide.md
│   ├── convert-docs-command-guide.md
│   ├── debug-command-guide.md
│   ├── document-command-guide.md
│   ├── expand-command-guide.md
│   ├── optimize-claude-command-guide.md
│   ├── plan-command-guide.md
│   ├── research-command-guide.md
│   ├── revise-command-guide.md
│   ├── setup-command-guide.md
│   └── test-command-guide.md
│
├── development/                        # Creating commands and agents
│   ├── README.md
│   ├── command-development/
│   │   ├── fundamentals.md
│   │   ├── advanced-patterns.md
│   │   ├── examples-case-studies.md
│   │   ├── standards-integration.md
│   │   └── troubleshooting.md
│   ├── agent-development/
│   │   ├── fundamentals.md
│   │   ├── patterns.md
│   │   ├── testing.md
│   │   ├── troubleshooting.md
│   │   ├── advanced.md
│   │   └── examples.md
│   ├── model-selection-guide.md
│   ├── model-rollback-guide.md
│   └── using-utility-libraries.md
│
├── orchestration/                      # Workflow orchestration
│   ├── README.md
│   ├── orchestration-best-practices.md
│   ├── orchestration-troubleshooting.md
│   ├── orchestrate-overview-architecture.md
│   ├── orchestrate-phases-implementation.md
│   ├── creating-orchestrator-commands.md
│   ├── state-machine-orchestrator-development.md
│   ├── state-machine-migration-guide.md
│   ├── hierarchical-supervisor-guide.md
│   └── workflow-classification-guide.md
│
├── patterns/                           # Reusable patterns and standards
│   ├── README.md
│   ├── command-patterns/
│   │   ├── overview.md
│   │   ├── agents.md
│   │   ├── checkpoints.md
│   │   └── integration.md
│   ├── execution-enforcement/
│   │   ├── overview.md
│   │   ├── patterns.md
│   │   ├── migration.md
│   │   └── validation.md
│   ├── logging-patterns.md
│   ├── testing-patterns.md
│   ├── error-enhancement-guide.md
│   ├── data-management.md
│   ├── standards-integration.md
│   ├── refactoring-methodology.md
│   ├── performance-optimization.md
│   ├── phase-0-optimization.md
│   ├── implementation-guide.md
│   ├── revision-guide.md
│   └── enhanced-topic-generation-guide.md
│
├── templates/                          # File templates
│   ├── README.md
│   ├── _template-bash-block.md
│   ├── _template-command-guide.md
│   └── _template-executable-command.md
│
└── archive/                            # Archived/deprecated content
    └── (moved from main directory)
```

### Category Definitions

#### 1. commands/ - Command-Specific Documentation (13 files)

**Purpose**: Comprehensive documentation for individual slash commands following the executable/documentation separation pattern.

**Criteria for inclusion**:
- Named `*-command-guide.md`
- Documents a specific command in `.claude/commands/`
- Contains usage examples, architecture, troubleshooting

**Files to include**:
- build-command-guide.md
- collapse-command-guide.md
- convert-docs-command-guide.md
- debug-command-guide.md
- document-command-guide.md
- expand-command-guide.md
- optimize-claude-command-guide.md
- plan-command-guide.md
- research-command-guide.md
- revise-command-guide.md
- setup-command-guide.md
- test-command-guide.md

**Special handling**:
- docs-accuracy-analyzer-agent-guide.md → Move to development/agent-development/
- revision-specialist-agent-guide.md → Move to development/agent-development/

---

#### 2. development/ - Creating Commands and Agents (15 files)

**Purpose**: How-to guides for developing custom commands and agents.

**Criteria for inclusion**:
- Teaches how to create/modify commands or agents
- Focuses on development process, not usage
- Includes patterns, templates, and best practices

**Files to include**:

*Command Development subdirectory*:
- command-development-fundamentals.md
- command-development-advanced-patterns.md
- command-development-examples-case-studies.md
- command-development-standards-integration.md
- command-development-troubleshooting.md

*Agent Development subdirectory*:
- agent-development-fundamentals.md
- agent-development-patterns.md
- agent-development-testing.md
- agent-development-troubleshooting.md
- agent-development-advanced.md
- agent-development-examples.md

*Supporting guides*:
- model-selection-guide.md
- model-rollback-guide.md
- using-utility-libraries.md

**Note**: Remove hub files (agent-development-guide.md, command-development-index.md) after creating subdirectory READMEs.

---

#### 3. orchestration/ - Workflow Orchestration (10 files)

**Purpose**: Multi-phase workflow execution, state machine orchestration, and supervisor patterns.

**Criteria for inclusion**:
- Documents orchestration architecture or patterns
- Covers state machines, phases, or workflow coordination
- Specific to `/orchestrate`, `/build`, or supervisors

**Files to include**:
- orchestration-best-practices.md
- orchestration-troubleshooting.md
- orchestrate-overview-architecture.md
- orchestrate-phases-implementation.md
- creating-orchestrator-commands.md
- state-machine-orchestrator-development.md
- state-machine-migration-guide.md
- hierarchical-supervisor-guide.md
- workflow-classification-guide.md
- state-variable-decision-guide.md

---

#### 4. patterns/ - Reusable Patterns and Standards (18 files)

**Purpose**: Cross-cutting patterns that apply to multiple commands or agents.

**Criteria for inclusion**:
- Patterns used across multiple contexts
- Standards and conventions
- Error handling, testing, logging approaches

**Files to include**:

*Command Patterns subdirectory*:
- command-patterns-overview.md
- command-patterns-agents.md
- command-patterns-checkpoints.md
- command-patterns-integration.md

*Execution Enforcement subdirectory*:
- execution-enforcement-overview.md
- execution-enforcement-patterns.md
- execution-enforcement-migration.md
- execution-enforcement-validation.md

*Standalone patterns*:
- logging-patterns.md
- testing-patterns.md
- error-enhancement-guide.md
- data-management.md
- standards-integration.md
- refactoring-methodology.md
- performance-optimization.md
- phase-0-optimization.md
- implementation-guide.md
- revision-guide.md
- enhanced-topic-generation-guide.md

---

#### 5. templates/ - File Templates (3 files)

**Purpose**: Starting templates for creating new files.

**Files to include**:
- _template-bash-block.md
- _template-command-guide.md
- _template-executable-command.md

---

#### 6. archive/ - Deprecated Content (12+ files)

**Purpose**: Content that is no longer actively used but preserved for reference.

**Files to archive**:
- using-agents.md (redirect stub)
- command-examples.md (redirect stub)
- migration-validation.md (redirect stub)
- testing-standards.md (redirect stub)
- setup-modes.md (minimal content)
- orchestrate-command-index.md (minimal content)
- git-recovery-guide.md (rarely used)
- skills-vs-subagents-decision.md (narrow scope)
- atomic-allocation-migration.md (completed migration)
- link-conventions-guide.md (minimal utility)
- supervise-guide.md (limited adoption)
- agent-development-guide.md (hub after splits moved)
- command-patterns.md (hub after splits moved)
- execution-enforcement-guide.md (hub after splits moved)
- command-development-index.md (hub after splits moved)

---

### Migration Impact Analysis

#### Reference Updates Required

| Pattern | Count | Example |
|---------|-------|---------|
| `guides/command-development-*.md` | ~50 | → `guides/development/command-development/*.md` |
| `guides/agent-development-*.md` | ~40 | → `guides/development/agent-development/*.md` |
| `guides/*-command-guide.md` | ~30 | → `guides/commands/*.md` |
| `guides/command-patterns*.md` | ~25 | → `guides/patterns/command-patterns/*.md` |
| `guides/execution-enforcement*.md` | ~20 | → `guides/patterns/execution-enforcement/*.md` |
| `guides/orchestrat*.md` | ~30 | → `guides/orchestration/*.md` |
| **Total** | **~195** | |

#### Files Requiring Updates

Primary files with many guide references:
1. `.claude/docs/README.md` - Main documentation index
2. `.claude/docs/guides/README.md` - Guides index
3. `.claude/docs/reference/command-reference.md` - Command reference
4. `.claude/docs/reference/agent-reference.md` - Agent reference
5. `CLAUDE.md` - Project configuration

## Recommendations

### 1. Phase 1 - Archive Unused Content (Low Risk)

**Actions**:
1. Create `.claude/docs/archive/guides/` if not exists
2. Move 12 identified files to archive
3. Update references in active documentation (few references expected)

**Timeline**: 1-2 hours

### 2. Phase 2 - Create Subdirectory Structure (Medium Risk)

**Actions**:
1. Create subdirectories: commands/, development/, orchestration/, patterns/, templates/
2. Create README.md for each subdirectory
3. Move files to appropriate subdirectories
4. Update guides/README.md to reflect new structure

**Timeline**: 2-3 hours

### 3. Phase 3 - Update References (High Risk)

**Actions**:
1. Use grep to find all guide references
2. Create migration script for path updates
3. Update references in batches by source directory
4. Validate all links

**Timeline**: 3-4 hours

### 4. Phase 4 - Clean Split File Legacy Content (Low Risk)

**Actions**:
1. Remove "Legacy Content Below" from hub files
2. Verify sub-files are complete
3. Archive cleaned hub files

**Timeline**: 1-2 hours

### 5. Total Estimated Effort

- Archiving: 1-2 hours
- Restructuring: 2-3 hours
- Reference updates: 3-4 hours
- Cleanup: 1-2 hours
- Testing/validation: 1-2 hours
- **Total**: 8-13 hours

## References

- `/home/benjamin/.config/.claude/docs/guides/README.md` - Lines 337-355 (current structure)
- `/home/benjamin/.config/.claude/docs/README.md` - Lines 130-155 (documentation index)
- Grep searches for reference patterns throughout codebase
- Analysis of file naming conventions and content topics
