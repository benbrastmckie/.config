# Library Directory Refactor Analysis

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: .claude/lib/ directory analysis and refactor design
- **Report Type**: codebase analysis

## Executive Summary

The `.claude/lib/` directory contains 63 library files totaling ~872KB, of which 16 libraries (25%) have zero external references and should be archived. The remaining 47 libraries can be logically organized into 6 subdirectories based on functional domain. Additionally, the README.md documentation references 12+ non-existent libraries that were previously archived but not updated in documentation, creating confusion and broken sourcing attempts.

## Findings

### Current State Analysis

**Directory Statistics**:
- Total library files: 63 (.sh files)
- Total size: ~872KB
- Actively used libraries: 47 (75%)
- Unused libraries (0 references): 16 (25%)
- Documented libraries that don't exist: 12+

**Library Usage Distribution** (by reference count in commands/, agents/, scripts/, tests/):

**High Usage (10+ references)** - Core Infrastructure:
- `state-persistence.sh` (19 refs) - State management
- `unified-location-detection.sh` (18 refs) - Path resolution
- `workflow-state-machine.sh` (14 refs) - State machine
- `error-handling.sh` (14 refs) - Error handling
- `checkpoint-utils.sh` (13 refs) - Checkpoints
- `workflow-initialization.sh` (11 refs) - Workflow init
- `detect-project-dir.sh` (10 refs) - Project detection

**Medium Usage (5-9 references)** - Workflow Support:
- `checkbox-utils.sh` (9 refs) - Checkbox updates
- `plan-core-bundle.sh` (8 refs) - Plan parsing
- `workflow-scope-detection.sh` (7 refs) - Scope detection
- `convert-core.sh` (7 refs) - Document conversion
- `library-version-check.sh` (6 refs) - Version validation
- `artifact-creation.sh` (6 refs) - Artifact creation
- `unified-logger.sh` (5 refs) - Logging
- `topic-utils.sh` (5 refs) - Topic management
- `optimize-claude-md.sh` (5 refs) - CLAUDE.md optimization
- `auto-analysis-utils.sh` (5 refs) - Auto analysis

**Low Usage (1-4 references)** - Specialized:
- `workflow-llm-classifier.sh` (4 refs)
- `metadata-extraction.sh` (4 refs)
- `overview-synthesis.sh` (3 refs)
- `library-sourcing.sh` (3 refs)
- `complexity-utils.sh` (3 refs)
- `base-utils.sh` (3 refs)
- `artifact-registry.sh` (3 refs)
- And 16 more with 1-2 references each

**Zero References (Candidates for Archival)**:
1. `agent-discovery.sh` - Agent auto-scanning (not used)
2. `agent-invocation.sh` - Complexity estimator invocation (not used)
3. `agent-registry-utils.sh` - Agent registry management (not used)
4. `agent-schema-validator.sh` - Agent schema validation (not used)
5. `analysis-pattern.sh` - Analysis patterns (not used)
6. `audit-imperative-language.sh` - Language auditing (not used)
7. `checkpoint-migration.sh` - Checkpoint migration (not used)
8. `complexity-thresholds.sh` - Complexity thresholds (not used)
9. `context-metrics.sh` - Context tracking (not used)
10. `convert-docx.sh` - DOCX conversion (not used directly)
11. `convert-markdown.sh` - Markdown conversion (not used directly)
12. `convert-pdf.sh` - PDF conversion (not used directly)
13. `debug-utils.sh` - Debug utilities (not used)
14. `dependency-analysis.sh` - Dependency analysis (not used)
15. `deps-utils.sh` - Dependency utilities (not used)
16. `generate-readme.sh` - README generation (not used)
17. `git-utils.sh` - Git utilities (not used)
18. `json-utils.sh` - JSON utilities (not used)
19. `monitor-model-usage.sh` - Model usage monitoring (not used)
20. `source-libraries-snippet.sh` - Library sourcing snippet (not used)
21. `timestamp-utils.sh` - Timestamp formatting (not used)
22. `validate_executable_doc_separation.sh` - Validation (not used)

**Note**: `convert-docx.sh`, `convert-markdown.sh`, and `convert-pdf.sh` are sourced by `convert-core.sh` internally (3 indirect usages)

### Documentation Issues

The `README.md` references 12+ libraries that no longer exist:
- `plan-parsing.sh` (line 84)
- `conversion-logger.sh` (lines 160, 797)
- `adaptive-planning-logger.sh` (lines 286, 829)
- `plan-structure-utils.sh` (line 373)
- `plan-metadata-utils.sh` (line 412)
- `progressive-planning-utils.sh` (line 450)
- `validation-utils.sh` (line 621)
- `parallel-orchestration-utils.sh` (line 1017)
- `structure-eval-utils.sh` (line 1100)
- `analyze-metrics.sh` (line 1134)
- `hierarchical-agent-support.sh` (referenced in tests)
- `verification-helpers.sh` (referenced in tests)

### Internal Dependencies

Only 3 internal library dependencies exist:
- `checkpoint-migration.sh` → `error-handling.sh` (line 38)
- `workflow-scope-detection.sh` → `workflow-llm-classifier.sh` (line 27)
- `workflow-detection.sh` → `workflow-scope-detection.sh` (line 21)

### Proposed Subdirectory Organization

Based on functional domains, the libraries can be organized into:

**1. `core/` - Essential Infrastructure (8 libraries)**
- `state-persistence.sh` - State management
- `error-handling.sh` - Error handling and retry
- `unified-location-detection.sh` - Path resolution
- `detect-project-dir.sh` - Project detection
- `base-utils.sh` - Base utilities
- `library-sourcing.sh` - Library loading
- `library-version-check.sh` - Version validation
- `unified-logger.sh` - Logging

**2. `workflow/` - Workflow Orchestration (9 libraries)**
- `workflow-state-machine.sh` - State machine
- `workflow-initialization.sh` - Workflow init
- `workflow-init.sh` - Init helpers
- `workflow-scope-detection.sh` - Scope detection
- `workflow-detection.sh` - Detection
- `workflow-llm-classifier.sh` - LLM classification
- `checkpoint-utils.sh` - Checkpoints
- `argument-capture.sh` - Argument capture
- `metadata-extraction.sh` - Metadata

**3. `plan/` - Plan Management (7 libraries)**
- `plan-core-bundle.sh` - Core plan parsing
- `topic-utils.sh` - Topic management
- `topic-decomposition.sh` - Topic decomposition
- `checkbox-utils.sh` - Checkbox updates
- `complexity-utils.sh` - Complexity analysis
- `auto-analysis-utils.sh` - Auto analysis
- `parse-template.sh` - Template parsing

**4. `artifact/` - Artifact Management (5 libraries)**
- `artifact-creation.sh` - Artifact creation
- `artifact-registry.sh` - Artifact tracking
- `overview-synthesis.sh` - Overview generation
- `substitute-variables.sh` - Variable substitution
- `template-integration.sh` - Template integration

**5. `convert/` - Document Conversion (4 libraries)**
- `convert-core.sh` - Core conversion
- `convert-docx.sh` - DOCX conversion
- `convert-pdf.sh` - PDF conversion
- `convert-markdown.sh` - Markdown conversion

**6. `util/` - Miscellaneous Utilities (9 libraries)**
- `git-commit-utils.sh` - Git commit helpers
- `optimize-claude-md.sh` - CLAUDE.md optimization
- `progress-dashboard.sh` - Progress display
- `detect-testing.sh` - Test detection
- `generate-testing-protocols.sh` - Test protocols
- `backup-command-file.sh` - Backup creation
- `rollback-command-file.sh` - Rollback
- `validate-agent-invocation-pattern.sh` - Validation
- `dependency-analyzer.sh` - Dependency analysis

### Files Requiring Reference Updates

The following files in `.claude/` (excluding specs/, archive/, backups/) will need path updates:

**Commands (8 files)**:
- `commands/build.md` - 12 source statements
- `commands/debug.md` - 17 source statements
- `commands/plan.md` - 10 source statements
- `commands/research.md` - 8 source statements
- `commands/revise.md` - 8 source statements
- `commands/collapse.md` - 3 source statements
- `commands/expand.md` - 3 source statements
- `commands/convert-docs.md` - 1 source statement
- `commands/optimize-claude.md` - 1 source statement

**Agents (5 files)**:
- `agents/docs-structure-analyzer.md` - 1 source statement
- `agents/cleanup-plan-architect.md` - 1 source statement
- `agents/plan-complexity-classifier.md` - 1 source statement
- `agents/spec-updater.md` - 7 source statements
- `agents/implementer-coordinator.md` - 1 reference

**Tests (20+ files)**:
- All test files in `.claude/tests/` with source statements

**Documentation**:
- `lib/README.md` - Complete rewrite needed
- `agents/README.md` - Library references
- `docs/` - Various guides referencing libraries

## Recommendations

### 1. Archive Unused Libraries (Priority: High)
Archive 16 zero-reference libraries to `.claude/archive/lib/cleanup-2025-11-19/`:
- `agent-discovery.sh`
- `agent-invocation.sh`
- `agent-registry-utils.sh`
- `agent-schema-validator.sh`
- `analysis-pattern.sh`
- `audit-imperative-language.sh`
- `checkpoint-migration.sh`
- `complexity-thresholds.sh`
- `context-metrics.sh`
- `debug-utils.sh`
- `dependency-analysis.sh`
- `deps-utils.sh`
- `generate-readme.sh`
- `git-utils.sh`
- `json-utils.sh`
- `monitor-model-usage.sh`
- `source-libraries-snippet.sh`
- `timestamp-utils.sh`
- `validate_executable_doc_separation.sh`

Create an archive manifest README.md documenting each archived file's purpose for potential future restoration.

### 2. Implement Subdirectory Organization (Priority: High)
Create 6 subdirectories and migrate active libraries:
- `core/` (8 libraries)
- `workflow/` (9 libraries)
- `plan/` (7 libraries)
- `artifact/` (5 libraries)
- `convert/` (4 libraries)
- `util/` (9 libraries)

Each subdirectory should have a `README.md` explaining:
- Purpose and scope
- List of libraries with brief descriptions
- Common usage patterns
- Dependencies on other subdirectories

### 3. Update All References (Priority: Critical)
Use systematic find-and-replace to update all source statements:
```bash
# Pattern to update
OLD: source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
NEW: source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
```

Order of updates (to prevent breaking functionality):
1. First: Test files (can be verified with test runs)
2. Second: Agent files (can be verified with agent invocations)
3. Third: Command files (can be verified with command execution)
4. Fourth: Documentation (no runtime impact)

### 4. Create Comprehensive README Structure (Priority: High)
Main `lib/README.md` should:
- Remove all references to non-existent libraries
- Document subdirectory organization
- Include migration guide for existing users
- Provide sourcing examples for each subdirectory
- Document inter-library dependencies

Each subdirectory `README.md` should:
- List all contained libraries
- Describe each library's functions
- Show usage examples
- Note dependencies

### 5. Implement Library Loading Pattern (Priority: Medium)
Create a centralized loading mechanism:
```bash
# lib/load-core.sh - Load all core libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh"
# ... etc
```

This enables:
- Single source statement for common combinations
- Consistent loading order
- Easier maintenance

### 6. Add Deprecation Markers (Priority: Low)
For libraries with very low usage (1-2 refs), add deprecation comments:
```bash
# DEPRECATED: Consider using [alternative] instead
# Usage count: 1 (only in tests/test_X.sh)
```

## Implementation Phases

### Phase 1: Preparation (Low Risk)
- Create archive directory
- Create subdirectory structure
- Create README templates
- Document current state

### Phase 2: Archive Unused (Medium Risk)
- Move 16 unused libraries to archive
- Create archive manifest
- Update README to remove archived library references

### Phase 3: Migrate Active Libraries (High Risk)
- Move libraries to subdirectories
- Update all source statements in commands
- Update all source statements in agents
- Update all source statements in tests
- Validate with test suite

### Phase 4: Documentation (Low Risk)
- Rewrite lib/README.md
- Create subdirectory READMEs
- Update docs references
- Update agents/README.md

### Phase 5: Validation
- Run all tests
- Execute key commands
- Verify agent functionality
- Check documentation links

## References

- `/home/benjamin/.config/.claude/lib/` - All 63 library files
- `/home/benjamin/.config/.claude/lib/README.md` - Current documentation (1573+ lines)
- `/home/benjamin/.config/.claude/commands/build.md` - Lines 77-81, 167, 310-311, 476-477, 625-627, 770-772
- `/home/benjamin/.config/.claude/commands/debug.md` - Lines 111-119, 209-210, 243-245, 356, 420-421, 505, 554-555, 620, 665-666
- `/home/benjamin/.config/.claude/commands/plan.md` - Lines 115-123, 260-261, 373-374
- `/home/benjamin/.config/.claude/commands/research.md` - Lines 114-122, 252-253
- `/home/benjamin/.config/.claude/commands/revise.md` - Lines 222-227, 289-290, 567-568
- `/home/benjamin/.config/.claude/commands/collapse.md` - Lines 111, 486-487
- `/home/benjamin/.config/.claude/commands/expand.md` - Lines 109, 618-619
- `/home/benjamin/.config/.claude/commands/convert-docs.md` - Line 242
- `/home/benjamin/.config/.claude/commands/optimize-claude.md` - Line 29
- `/home/benjamin/.config/.claude/agents/docs-structure-analyzer.md` - Line 78
- `/home/benjamin/.config/.claude/agents/cleanup-plan-architect.md` - Line 108
- `/home/benjamin/.config/.claude/agents/plan-complexity-classifier.md` - Line 494
- `/home/benjamin/.config/.claude/agents/spec-updater.md` - Lines 373, 385, 434, 483, 521, 601, 713
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` - Line 86
- `/home/benjamin/.config/.claude/tests/` - 20+ test files with source statements
- `/home/benjamin/.config/.claude/lib/checkpoint-migration.sh:38` - Internal dependency
- `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh:27` - Internal dependency
- `/home/benjamin/.config/.claude/lib/workflow-detection.sh:21` - Internal dependency

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001_archive_and_backups_directories_can_be_s_plan.md](../plans/001_archive_and_backups_directories_can_be_s_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-19
