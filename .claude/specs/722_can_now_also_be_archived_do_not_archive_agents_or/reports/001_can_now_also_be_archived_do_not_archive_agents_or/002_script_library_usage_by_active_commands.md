# Script Library Usage by Active Commands

**[← Back to Overview](./OVERVIEW.md)**

## Metadata
- **Date**: 2025-11-15
- **Agent**: research-specialist
- **Topic**: Script Library Usage by Active Commands
- **Report Type**: codebase analysis
- **Part of**: [Research Overview: Agents and Library Scripts Archival Analysis](./OVERVIEW.md)

## Research Summary

This report analyzes all shell scripts in `.claude/lib/` to identify which are used by active commands versus archived commands. The goal is to determine which library scripts can be safely archived.

## Methodology

1. Analyzed all active commands in `.claude/commands/`
2. Analyzed all archived commands in `.claude/archive/commands/`
3. Examined all agents in `.claude/agents/` for library usage
4. Analyzed inter-script dependencies within `.claude/lib/`
5. Created dependency maps for each library script

## Active Commands (11 total)

Located in `/home/benjamin/.config/.claude/commands/`:

1. collapse.md
2. convert-docs.md
3. coordinate.md (primary orchestrator)
4. debug.md
5. expand.md
6. implement.md
7. optimize-claude.md
8. plan.md
9. research.md
10. revise.md
11. setup.md

## Archived Commands (8 total)

Located in `/home/benjamin/.config/.claude/archive/commands/`:

1. analyze.md
2. document.md
3. list.md
4. plan-from-template.md
5. plan-wizard.md
6. refactor.md
7. test-all.md
8. test.md

## Library Scripts Analysis (81 total)

### Scripts Used by Active Commands

#### Core State Management (Used by /coordinate and agents)
- **workflow-state-machine.sh** - State machine orchestration (coordinate.md, all sub-supervisors)
- **state-persistence.sh** - State persistence and recovery (coordinate.md, workflow-classifier.md, sub-supervisors)
- **error-handling.sh** - Error handling and logging (coordinate.md)
- **verification-helpers.sh** - Verification checkpoints (coordinate.md)

#### Core Workflow Support
- **workflow-initialization.sh** - Workflow initialization (coordinate.md)
- **unified-logger.sh** - Logging and progress emission (coordinate.md, artifact-creation.sh, artifact-registry.sh, metadata-extraction.sh)
- **context-pruning.sh** - Context reduction (coordinate.md)
- **dependency-analyzer.sh** - Phase dependency analysis for wave execution (coordinate.md)
- **library-sourcing.sh** - Dynamic library sourcing (coordinate.md, source-libraries-snippet.sh)

#### Planning and Analysis
- **plan-core-bundle.sh** - Core plan parsing utilities (expand.md, collapse.md, checkbox-utils.sh, auto-analysis-utils.sh, dependency-analysis.sh)
- **auto-analysis-utils.sh** - Automatic complexity analysis (expand.md, collapse.md)
- **detect-project-dir.sh** - Project directory detection (expand.md, collapse.md, implement.md, research.md, checkpoint-utils.sh, workflow-state-machine.sh)
- **complexity-utils.sh** - Complexity scoring (plan.md)
- **complexity-thresholds.sh** - Complexity threshold configuration (complexity-utils.sh)

#### Research Workflow
- **topic-decomposition.sh** - Topic breakdown (research.md)
- **artifact-creation.sh** - Artifact creation and management (research.md)
- **template-integration.sh** - Template processing (research.md)
- **metadata-extraction.sh** - Metadata extraction (research.md, research-sub-supervisor.md, sub-supervisor-template.md)
- **overview-synthesis.sh** - Overview synthesis (research.md)
- **topic-utils.sh** - Topic utilities (research.md)
- **artifact-registry.sh** - Artifact registration and tracking (research.md, artifact-creation.sh, auto-analysis-utils.sh)

#### Document Conversion
- **convert-core.sh** - Document conversion orchestrator (convert-docs.md)
- **convert-docx.sh** - DOCX conversion (convert-core.sh)
- **convert-pdf.sh** - PDF conversion (convert-core.sh)
- **convert-markdown.sh** - Markdown conversion (convert-core.sh)

#### Agent Support
- **unified-location-detection.sh** - Location detection (optimize-claude.md, cleanup-plan-architect.md, claude-md-analyzer.md, research-synthesizer.md, docs-accuracy-analyzer.md, docs-structure-analyzer.md, research-specialist.md, docs-bloat-analyzer.md)
- **optimize-claude-md.sh** - CLAUDE.md optimization (claude-md-analyzer.md)
- **checkbox-utils.sh** - Checkbox synchronization (spec-updater.md, code-writer.md)
- **checkpoint-utils.sh** - Checkpoint management (implementation-executor.md)

#### Base Utilities (Used by many scripts)
- **base-utils.sh** - Core utility functions (artifact-creation.sh, dependency-analysis.sh, checkbox-utils.sh, metadata-extraction.sh, agent-schema-validator.sh, artifact-registry.sh, agent-discovery.sh, unified-logger.sh, timestamp-utils.sh, plan-core-bundle.sh)
- **timestamp-utils.sh** - Timestamp utilities (checkpoint-utils.sh, unified-logger.sh)
- **json-utils.sh** - JSON parsing and manipulation (auto-analysis-utils.sh)
- **deps-utils.sh** - Dependency utilities (json-utils.sh)

#### Agent Infrastructure
- **agent-discovery.sh** - Agent discovery and loading
- **agent-schema-validator.sh** - Agent schema validation (agent-discovery.sh)
- **agent-registry-utils.sh** - Agent registry management
- **agent-invocation.sh** - Agent invocation patterns (auto-analysis-utils.sh)

#### Workflow Classification
- **workflow-detection.sh** - Workflow type detection
- **workflow-scope-detection.sh** - Scope detection (workflow-detection.sh)
- **workflow-llm-classifier.sh** - LLM-based classification (workflow-scope-detection.sh)

#### Git and Backup
- **git-utils.sh** - Git operations
- **git-commit-utils.sh** - Git commit utilities
- **backup-command-file.sh** - Command backup
- **rollback-command-file.sh** - Command rollback

#### Dependency Analysis
- **dependency-analysis.sh** - Dependency analysis utilities

#### Testing and Validation
- **detect-testing.sh** - Testing infrastructure detection
- **validate-agent-invocation-pattern.sh** - Agent pattern validation
- **validate-context-reduction.sh** - Context reduction validation

#### Generation and Analysis
- **generate-readme.sh** - README generation
- **generate-testing-protocols.sh** - Testing protocol generation
- **monitor-model-usage.sh** - Model usage monitoring
- **context-metrics.sh** - Context metrics tracking
- **parse-template.sh** - Template parsing
- **substitute-variables.sh** - Variable substitution
- **progress-dashboard.sh** - Progress dashboard

### Scripts Used ONLY by Archived Commands

#### analyze.md Dependencies
- **analyze-metrics.sh** - Metrics analysis (ONLY used by archived analyze.md)

#### list.md Dependencies
No unique dependencies - list.md used artifact-creation.sh and artifact-registry.sh which are still actively used by research.md

### Orphaned or Minimal-Use Scripts

These scripts have limited or no usage in active commands/agents:

1. **analysis-pattern.sh** - Used only by auto-analysis-utils.sh (indirect use via expand/collapse)
2. **audit-imperative-language.sh** - Standalone auditing tool, no command usage detected
3. **checkpoint-580.sh** - Legacy checkpoint version, superseded by checkpoint-utils.sh
4. **source-libraries-snippet.sh** - Code snippet generator, used only in README examples

### Backup Files (Can be safely removed)

1. **workflow-detection.sh.backup-before-task2.2** - Backup of workflow-detection.sh
2. **workflow-scope-detection.sh.backup-phase1** - Backup of workflow-scope-detection.sh
3. **workflow-state-machine.sh.backup** - Backup of workflow-state-machine.sh

## Dependency Map: Script → Users

### High-Usage Core Scripts (10+ references)

**base-utils.sh**: artifact-creation.sh, dependency-analysis.sh, checkbox-utils.sh, metadata-extraction.sh, agent-schema-validator.sh, artifact-registry.sh, agent-discovery.sh, unified-logger.sh, timestamp-utils.sh, plan-core-bundle.sh

**plan-core-bundle.sh**: expand.md, collapse.md, checkbox-utils.sh, auto-analysis-utils.sh, dependency-analysis.sh

**state-persistence.sh**: coordinate.md (multiple sections), implementation-sub-supervisor.md, workflow-classifier.md, research-sub-supervisor.md, testing-sub-supervisor.md, sub-supervisor-template.md

**unified-logger.sh**: coordinate.md, artifact-creation.sh, artifact-registry.sh, metadata-extraction.sh

**detect-project-dir.sh**: expand.md, collapse.md, implement.md, research.md, checkpoint-utils.sh, workflow-state-machine.sh

### Medium-Usage Scripts (5-10 references)

**workflow-state-machine.sh**: coordinate.md (11 code blocks)

**error-handling.sh**: coordinate.md (11 code blocks), auto-analysis-utils.sh

**verification-helpers.sh**: coordinate.md (11 code blocks)

**unified-location-detection.sh**: optimize-claude.md, cleanup-plan-architect.md, claude-md-analyzer.md, research-synthesizer.md, docs-accuracy-analyzer.md, docs-structure-analyzer.md, research-specialist.md, docs-bloat-analyzer.md

### Low-Usage Scripts (1-4 references)

**auto-analysis-utils.sh**: expand.md, collapse.md

**convert-core.sh**: convert-docs.md

**complexity-utils.sh**: plan.md

**topic-decomposition.sh**: research.md

**artifact-creation.sh**: research.md

**template-integration.sh**: research.md

**metadata-extraction.sh**: research.md, research-sub-supervisor.md, sub-supervisor-template.md

**overview-synthesis.sh**: research.md

**topic-utils.sh**: research.md

**artifact-registry.sh**: research.md, artifact-creation.sh, auto-analysis-utils.sh

**checkbox-utils.sh**: spec-updater.md, code-writer.md

**checkpoint-utils.sh**: implementation-executor.md

**optimize-claude-md.sh**: claude-md-analyzer.md

**timestamp-utils.sh**: checkpoint-utils.sh, unified-logger.sh

**json-utils.sh**: auto-analysis-utils.sh

**complexity-thresholds.sh**: complexity-utils.sh

**agent-discovery.sh**: (No direct command usage found)

**agent-schema-validator.sh**: agent-discovery.sh

**agent-invocation.sh**: auto-analysis-utils.sh

**workflow-detection.sh**: (No direct command usage found)

**workflow-scope-detection.sh**: workflow-detection.sh

**workflow-llm-classifier.sh**: workflow-scope-detection.sh

### Single-Use by Archived Commands

**analyze-metrics.sh**: analyze.md (archived)

### Orphaned Scripts (No active usage detected)

1. **audit-imperative-language.sh** - Standalone tool
2. **checkpoint-580.sh** - Legacy version

### Script Type Classification

#### Sourced Libraries (68 scripts)
Scripts designed to be sourced by other scripts/commands via `source` or `.` command.

#### Standalone Tools (9 scripts with shebangs)
These may be designed for direct execution:
1. audit-imperative-language.sh
2. base-utils.sh (also sourced)
3. complexity-thresholds.sh (also sourced)
4. complexity-utils.sh (also sourced)
5. dependency-analysis.sh (also sourced)
6. git-utils.sh (also sourced)
7. overview-synthesis.sh (also sourced)
8. template-integration.sh (also sourced)
9. topic-decomposition.sh (also sourced)

#### Backup Files (3 scripts)
1. workflow-detection.sh.backup-before-task2.2
2. workflow-scope-detection.sh.backup-phase1
3. workflow-state-machine.sh.backup

## Archive Candidates

### Safe to Archive (Definite)

**Reason: Used ONLY by archived commands**
1. **analyze-metrics.sh** - Only used by archived analyze.md

**Reason: Backup files**
2. **workflow-detection.sh.backup-before-task2.2**
3. **workflow-scope-detection.sh.backup-phase1**
4. **workflow-state-machine.sh.backup**

**Reason: Legacy/superseded**
5. **checkpoint-580.sh** - Legacy checkpoint version

### Consider Archiving (Context-Dependent)

**Reason: Standalone tools with no command integration**
1. **audit-imperative-language.sh** - Standalone auditing tool
   - Decision: Check if used manually or in CI/CD pipelines
   - If not used, can be archived

**Reason: Minimal usage (code snippet generator)**
2. **source-libraries-snippet.sh** - Only referenced in README examples
   - Decision: If only used for documentation, could be archived or moved to docs/

**Reason: No direct command usage detected**
3. **agent-discovery.sh** - May be used dynamically at runtime
   - Decision: Investigate runtime usage before archiving
4. **workflow-detection.sh** - May be used dynamically
   - Decision: Investigate runtime usage before archiving

### Do NOT Archive

All other 72 scripts are actively used by:
- Active commands (coordinate, research, plan, implement, expand, collapse, etc.)
- Agents (sub-supervisors, specialists, analyzers)
- Other library scripts (transitive dependencies)

## Recommendations

### Immediate Actions

1. **Archive backup files immediately** (3 files):
   - workflow-detection.sh.backup-before-task2.2
   - workflow-scope-detection.sh.backup-phase1
   - workflow-state-machine.sh.backup

2. **Archive legacy checkpoint version** (1 file):
   - checkpoint-580.sh

3. **Archive analyze-metrics.sh** (1 file):
   - Only used by archived analyze.md command

### Investigate Before Archiving (4 files)

1. **audit-imperative-language.sh**
   - Check: Manual usage, CI/CD integration, or documentation references
   - Action: If not actively used, archive

2. **source-libraries-snippet.sh**
   - Check: Is this needed for documentation generation?
   - Action: Consider moving to docs/ or archiving if only historical

3. **agent-discovery.sh**
   - Check: Runtime dynamic loading in agent system
   - Action: Verify no dynamic usage before archiving

4. **workflow-detection.sh**
   - Check: Runtime dynamic usage in workflow classification
   - Action: Verify no dynamic usage before archiving

### Total Archive Potential

- **Definite**: 5 files (backups + legacy + analyze-metrics.sh)
- **Possible**: 4 files (pending investigation)
- **Maximum**: 9 files out of 81 total (11%)
- **Keep Active**: 72 files (89%)

## Cross-Reference: Active Command Dependencies

### /coordinate (Primary Orchestrator)
**Direct dependencies (9 scripts)**:
- workflow-state-machine.sh
- state-persistence.sh
- error-handling.sh
- verification-helpers.sh
- workflow-initialization.sh
- unified-logger.sh
- context-pruning.sh
- dependency-analyzer.sh
- library-sourcing.sh

**Transitive dependencies**: ~15 additional scripts through sourced libraries

### /research
**Direct dependencies (6 scripts)**:
- topic-decomposition.sh
- artifact-creation.sh
- template-integration.sh
- metadata-extraction.sh
- overview-synthesis.sh
- topic-utils.sh
- detect-project-dir.sh

**Transitive dependencies**: base-utils.sh, unified-logger.sh, artifact-registry.sh, timestamp-utils.sh

### /plan
**Direct dependencies (1 script)**:
- complexity-utils.sh

**Transitive dependencies**: complexity-thresholds.sh

### /implement
**Direct dependencies (1 script)**:
- detect-project-dir.sh

### /expand & /collapse
**Direct dependencies (3 scripts)**:
- detect-project-dir.sh
- plan-core-bundle.sh
- auto-analysis-utils.sh

**Transitive dependencies**: base-utils.sh, json-utils.sh, error-handling.sh, agent-invocation.sh, analysis-pattern.sh, artifact-registry.sh

### /convert-docs
**Direct dependencies (1 script)**:
- convert-core.sh

**Transitive dependencies**: convert-docx.sh, convert-pdf.sh, convert-markdown.sh

### /optimize-claude
**Direct dependencies (1 script)**:
- unified-location-detection.sh

## Critical Scripts (Cannot Archive)

These scripts are foundational and used across multiple commands/agents:

1. **base-utils.sh** - 10+ dependents
2. **plan-core-bundle.sh** - 5+ dependents
3. **state-persistence.sh** - 6+ dependents (all sub-supervisors)
4. **unified-logger.sh** - 4+ dependents
5. **detect-project-dir.sh** - 6+ dependents
6. **workflow-state-machine.sh** - Core orchestration
7. **error-handling.sh** - Core error handling
8. **verification-helpers.sh** - Core verification

## File Size Analysis

Total library files: 81
- Backup files: 3 (can remove immediately)
- Archive candidates: 6 (pending verification)
- Active files: 72

## Conclusion

**Safe to Archive Immediately**: 5 files
1. analyze-metrics.sh
2. checkpoint-580.sh
3. workflow-detection.sh.backup-before-task2.2
4. workflow-scope-detection.sh.backup-phase1
5. workflow-state-machine.sh.backup

**Requires Investigation**: 4 files
1. audit-imperative-language.sh
2. source-libraries-snippet.sh
3. agent-discovery.sh
4. workflow-detection.sh

**Must Remain Active**: 72 files (89% of library)

The vast majority of library scripts (72/81 = 89%) are actively used by current commands and agents. Only a small subset (11%) can be considered for archiving, and most of those require further investigation to ensure no dynamic runtime usage.

## Next Steps

1. Create archive structure: `.claude/archive/lib/`
2. Move 5 definite archive candidates
3. Investigate 4 uncertain scripts for dynamic usage
4. Update any documentation references
5. Verify no broken imports after archiving
