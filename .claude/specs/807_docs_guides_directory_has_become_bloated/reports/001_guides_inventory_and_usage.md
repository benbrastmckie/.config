# Guides Inventory and Usage Analysis

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Guide Files Inventory and Usage Patterns
- **Report Type**: codebase analysis

## Executive Summary

The `.claude/docs/guides/` directory contains 78 files totaling approximately 1.3MB. Analysis reveals significant bloat from split documentation files, orphaned redirects, and underutilized content. High-usage guides (orchestration-best-practices, agent-development, command-development) are actively referenced, while many specialized guides (migration-validation, setup-modes, testing-standards) have minimal references. 12 files are redirect stubs, and 7 guide families were split but retain legacy content.

## Findings

### Complete Guide Inventory

#### High Usage Guides (10+ references across codebase)

| File | Size (KB) | Lines | References | Assessment |
|------|-----------|-------|------------|------------|
| orchestration-best-practices.md | 50 | 1517 | 30+ | **ACTIVE** - Primary orchestration reference |
| agent-development-guide.md | 67 | 2178 | 40+ | **ACTIVE** - Hub for split files |
| command-development-fundamentals.md | 27 | 800 | 20+ | **ACTIVE** - Core command guide |
| execution-enforcement-guide.md | 44 | 1584 | 25+ | **ACTIVE** - Standards enforcement |
| command-patterns.md | 40 | 1519 | 25+ | **ACTIVE** - Hub for split files |
| performance-optimization.md | 36 | 1319 | 15+ | **ACTIVE** - Efficiency patterns |
| orchestration-troubleshooting.md | 24 | 889 | 20+ | **ACTIVE** - Debugging reference |
| standards-integration.md | 25 | 898 | 15+ | **ACTIVE** - CLAUDE.md parsing |
| logging-patterns.md | 23 | 715 | 12+ | **ACTIVE** - Output formatting |
| refactoring-methodology.md | 26 | 813 | 10+ | **ACTIVE** - Migration guide |

#### Medium Usage Guides (5-9 references)

| File | Size (KB) | Lines | References | Assessment |
|------|-----------|-------|------------|------------|
| setup-command-guide.md | 40 | 1297 | 8 | **ACTIVE** - /setup documentation |
| state-machine-orchestrator-development.md | 31 | 1252 | 6 | **ACTIVE** - New orchestrator guide |
| hierarchical-supervisor-guide.md | 19 | 669 | 8 | **ACTIVE** - Supervisor patterns |
| model-selection-guide.md | 17 | 481 | 7 | **ACTIVE** - Model tier guidance |
| data-management.md | 21 | 682 | 6 | **ACTIVE** - Data ecosystem |
| implementation-guide.md | 23 | 551 | 5 | **ACTIVE** - Phase execution |
| phase-0-optimization.md | 21 | 624 | 6 | **ACTIVE** - Performance breakthrough |
| error-enhancement-guide.md | 11 | 439 | 8 | **ACTIVE** - Error patterns |
| testing-patterns.md | 12 | 449 | 7 | **ACTIVE** - Test organization |
| creating-orchestrator-commands.md | 18 | 565 | 5 | **ACTIVE** - New command creation |

#### Low Usage Guides (2-4 references)

| File | Size (KB) | Lines | References | Assessment |
|------|-----------|-------|------------|------------|
| build-command-guide.md | 17 | 512 | 4 | **REVIEW** - /build documentation |
| plan-command-guide.md | 12 | 429 | 4 | **REVIEW** - /plan documentation |
| debug-command-guide.md | 13 | 450 | 4 | **REVIEW** - /debug documentation |
| research-command-guide.md | 10 | 391 | 4 | **REVIEW** - /research documentation |
| revise-command-guide.md | 15 | 493 | 4 | **REVIEW** - /revise documentation |
| model-rollback-guide.md | 11 | 392 | 3 | **REVIEW** - Rollback procedures |
| state-machine-migration-guide.md | 28 | 1011 | 4 | **REVIEW** - Migration reference |
| using-utility-libraries.md | 19 | 761 | 4 | **REVIEW** - Library patterns |
| enhanced-topic-generation-guide.md | 23 | 697 | 3 | **REVIEW** - Topic generation |
| workflow-classification-guide.md | 18 | 662 | 3 | **REVIEW** - Classification system |
| revision-guide.md | 15 | 557 | 2 | **REVIEW** - Revision patterns |
| state-variable-decision-guide.md | 15 | 466 | 3 | **REVIEW** - State choices |

#### Minimal/No Usage Guides (0-1 references)

| File | Size (KB) | Lines | References | Assessment |
|------|-----------|-------|------------|------------|
| migration-validation.md | 0.7 | 16 | 2 | **ARCHIVE** - Redirect stub |
| setup-modes.md | 1.5 | 76 | 2 | **ARCHIVE** - Minimal content |
| testing-standards.md | 1.3 | 41 | 2 | **ARCHIVE** - Redirect stub |
| using-agents.md | 1.2 | 29 | 3 | **ARCHIVE** - Redirect stub |
| command-examples.md | N/A | N/A | 2 | **ARCHIVE** - Redirect stub |
| git-recovery-guide.md | 5 | 182 | 1 | **ARCHIVE** - Rarely used |
| skills-vs-subagents-decision.md | 10 | 339 | 2 | **ARCHIVE** - Narrow scope |
| atomic-allocation-migration.md | 9 | 349 | 1 | **ARCHIVE** - One-time migration |
| link-conventions-guide.md | 4 | 175 | 1 | **ARCHIVE** - Minimal utility |
| orchestrate-command-index.md | 1.7 | 52 | 1 | **ARCHIVE** - Index page |
| supervise-guide.md | 7 | 276 | 1 | **ARCHIVE** - Limited references |
| workflow-type-selection-guide.md | 12 | 477 | 3 | **REVIEW** - Selection guide |

#### Split Documentation Files (7 families)

**Agent Development Family** (7 files):
- agent-development-guide.md (hub)
- agent-development-fundamentals.md
- agent-development-patterns.md
- agent-development-testing.md
- agent-development-troubleshooting.md
- agent-development-advanced.md
- agent-development-examples.md

**Command Patterns Family** (5 files):
- command-patterns.md (hub)
- command-patterns-overview.md
- command-patterns-agents.md
- command-patterns-checkpoints.md
- command-patterns-integration.md

**Command Development Family** (6 files):
- command-development-fundamentals.md
- command-development-index.md
- command-development-advanced-patterns.md
- command-development-examples-case-studies.md
- command-development-standards-integration.md
- command-development-troubleshooting.md

**Execution Enforcement Family** (5 files):
- execution-enforcement-guide.md (hub)
- execution-enforcement-overview.md
- execution-enforcement-patterns.md
- execution-enforcement-migration.md
- execution-enforcement-validation.md

#### Template Files (3 files)

| File | Size (KB) | Lines | Assessment |
|------|-----------|-------|------------|
| _template-bash-block.md | 12 | 406 | **KEEP** - Active template |
| _template-command-guide.md | 2.5 | 170 | **KEEP** - Active template |
| _template-executable-command.md | 2.8 | 92 | **KEEP** - Active template |

### Usage Pattern Analysis

**Referencing Files Location**:
- Primary references from: `docs/README.md`, `docs/reference/*.md`, `docs/concepts/*.md`
- Command references from: `commands/*.md`, `commands/README.md`
- Troubleshooting references from: `docs/troubleshooting/*.md`
- Archive references (stale): `backups/`, `archive/`

**Reference Quality Issues**:
1. Many references in backup files (not current usage)
2. Self-references within guides (circular)
3. References from archived coordinate documentation (obsolete)

## Recommendations

### 1. Archive Low-Value Files (12 files)

Move to `.claude/docs/archive/guides/`:
- migration-validation.md (redirect stub)
- setup-modes.md (content in setup-command-guide)
- testing-standards.md (redirect stub)
- using-agents.md (redirect stub)
- command-examples.md (redirect stub)
- git-recovery-guide.md (rarely used)
- skills-vs-subagents-decision.md (narrow scope)
- atomic-allocation-migration.md (one-time migration complete)
- link-conventions-guide.md (minimal utility)
- orchestrate-command-index.md (index page with minimal content)
- supervise-guide.md (limited adoption)
- command-development-index.md (hub file with splits)

### 2. Consolidate Split File Families

Consider re-consolidating or properly organizing:
- Agent development: Keep hub, archive legacy content
- Command patterns: Keep hub, archive legacy content
- Execution enforcement: Keep hub, archive legacy content

### 3. Create Subdirectory Organization

Proposed structure:
```
guides/
├── commands/          # Command-specific guides (17 files)
├── development/       # Development patterns (8 files)
├── orchestration/     # Orchestration & workflows (6 files)
├── reference/         # Reference & standards (8 files)
├── templates/         # Templates (3 files)
└── README.md
```

### 4. Update All References

After reorganization:
- Update all `guides/*.md` references to new paths
- Update CLAUDE.md links
- Update docs/README.md navigation

## References

- `/home/benjamin/.config/.claude/docs/guides/` - Directory analyzed (78 files)
- `/home/benjamin/.config/.claude/docs/guides/README.md` - Lines 1-372
- `/home/benjamin/.config/.claude/backups/docs-optimization-20251117/size_baseline.txt` - File sizes
- Grep searches across `.claude/` directory for reference counts
