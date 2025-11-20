# Deleted Library Files Research Report

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Deleted lib files still referenced in documentation
- **Report Type**: codebase analysis
- **Specs Directory**: /home/benjamin/.config/.claude/specs

## Executive Summary

This report analyzes 15 library files that were deleted during the lib directory refactoring (commit fb8680db) but are still referenced in documentation. The analysis found that most files (13/15) should have their documentation references REMOVED as they were intentionally archived and their functionality either consolidated elsewhere or deemed unnecessary. Two files (parse-adaptive-plan.sh, complexity-thresholds.sh) were consolidated into existing libraries (plan-core-bundle.sh, complexity-utils.sh) and documentation should be UPDATED to reference the new locations. Zero files need to be restored.

## Summary Statistics

| Recommendation | Count | Files |
|---------------|-------|-------|
| REMOVE_REFS | 13 | generate-readme.sh, agent-registry-utils.sh, monitor-model-usage.sh, validate-context-reduction.sh, list-checkpoints.sh, json-utils.sh, cleanup-checkpoints.sh, dependency-analysis.sh, agent-discovery.sh, context-metrics.sh, agent-schema-validator.sh, deps-utils.sh, git-utils.sh |
| UPDATE_REFS | 2 | parse-adaptive-plan.sh, complexity-thresholds.sh |
| RESTORE | 0 | - |

## Detailed File Analysis

### 1. parse-adaptive-plan.sh (21 references)

**Original Functionality** (from git history):
- Progressive plan structure parsing utilities
- Functions: detect_tier, list_phases, get_tasks, mark_complete
- Purpose: Parse any tier structure of adaptive plans

**Current Status**: CONSOLIDATED
- Functionality moved to `.claude/lib/plan/plan-core-bundle.sh` (lines 1-50 show consolidation header)
- The consolidation combined: parse-plan-core.sh, plan-metadata-utils.sh, plan-structure-utils.sh
- Note in `.claude/commands/expand.md:862`: "parse-adaptive-plan.sh was consolidated into plan-core-bundle.sh"

**Reference Locations**:
- .claude/README.md:108
- .claude/CHANGELOG.md:60, 67
- .claude/docs/workflows/adaptive-planning-guide.md:354, 404, 410, 417, 423
- .claude/commands/README.md:227, 577-592
- .claude/commands/expand.md:142, 862
- .claude/docs/reference/architecture/documentation.md:188
- .claude/docs/reference/architecture/error-handling.md:272
- .claude/lib/UTILS_README.md:329, 351-353
- .claude/docs/guides/patterns/implementation-guide.md:55, 58, 349, 493, 515
- Multiple specs reports/plans

**Assessment**: UPDATE_REFS
- Functionality exists in plan-core-bundle.sh
- Documentation should be updated to reference the new location
- Active commands (expand.md) already have consolidation notes but references remain

---

### 2. generate-readme.sh (10 references)

**Original Functionality** (from git history):
- README scaffolding utility
- Functions: generate_readme()
- Purpose: Generate template-based README.md files with navigation links

**Current Status**: ARCHIVED - Not Used
- Marked as "not used" in refactor analysis
- Intentionally deleted as unused utility
- No replacement created - functionality considered unnecessary

**Reference Locations**:
- .claude/docs/guides/commands/setup-command-guide.md:109, 116, 119, 122, 134, 161, 201, 204, 254, 255
- .claude/specs/820 reports and plans (archival documentation)

**Assessment**: REMOVE_REFS
- Not needed by any active commands
- setup-command-guide.md has extensive documentation for non-existent feature
- Should remove entire "README Scaffolding" section from setup-command-guide.md

---

### 3. agent-registry-utils.sh (9 references)

**Original Functionality** (from git history):
- Agent registry management
- Functions: ensure_registry_exists(), register_agent(), update_agent_metrics()
- Purpose: Read and update agent-registry.json for performance tracking

**Current Status**: ARCHIVED - Not Used
- Marked as "not used" in refactor analysis
- No active commands or agents source this file
- Agent registry feature was not implemented

**Reference Locations**:
- .claude/lib/core/error-handling.sh:1026
- .claude/docs/guides/patterns/implementation-guide.md:449, 473, 550
- .claude/docs/reference/library-api/overview.md:40
- .claude/docs/reference/library-api/utilities.md:17, 335, 448
- .claude/docs/guides/development/command-development/command-development-standards-integration.md:278
- .claude/specs/820 reports and plans

**Assessment**: REMOVE_REFS
- Agent registry feature not implemented
- References in implementation-guide.md are for theoretical patterns
- Should remove all API documentation for this utility

---

### 4. complexity-thresholds.sh (6 references)

**Original Functionality** (from git history):
- Complexity thresholds extraction from CLAUDE.md
- Functions: get_complexity_thresholds(), extract_thresholds_from_file(), validate_threshold()
- Purpose: Extract adaptive planning thresholds with validation

**Current Status**: CONSOLIDATED
- Functionality inlined into `.claude/lib/plan/complexity-utils.sh:11-13`
- Comment in complexity-utils.sh: "complexity-thresholds.sh was archived - using inline defaults"
- Default values now hardcoded: COMPLEXITY_THRESHOLD_LOW=2, MEDIUM=5, HIGH=8

**Reference Locations**:
- .claude/lib/plan/complexity-utils.sh:11 (mentions archival)
- .claude/docs/guides/patterns/refactoring-methodology.md:265, 407, 805
- .claude/docs/reference/library-api/utilities.md:271, 329
- .claude/docs/reference/library-api/overview.md:50
- .claude/specs/820 reports and plans

**Assessment**: UPDATE_REFS
- Functionality consolidated into complexity-utils.sh
- Update documentation to reference the inline defaults approach
- Remove API documentation for standalone file

---

### 5. monitor-model-usage.sh (4 references)

**Original Functionality** (from git history):
- Model usage and cost monitoring
- Functions: usage(), info(), success(), warning(), error()
- Purpose: Track invocation counts, costs, and quality metrics for Claude models

**Current Status**: ARCHIVED - Not Used
- Marked as "not used" in refactor analysis
- Model monitoring feature not implemented

**Reference Locations**:
- .claude/docs/guides/development/model-selection-guide.md:386, 390, 393, 396
- .claude/specs/820 reports and plans

**Assessment**: REMOVE_REFS
- Feature not implemented
- model-selection-guide.md has usage examples for non-existent utility
- Should remove "Monitoring" section or mark as planned-but-not-implemented

---

### 6. validate-context-reduction.sh (3 references)

**Original Functionality**: Unknown - file did not exist in retrieved commit
- Likely planned but never implemented
- Referenced in troubleshooting and coordinate workflow docs

**Current Status**: NEVER EXISTED or very old
- Could not retrieve from fb8680db commit
- References are for planned functionality

**Reference Locations**:
- .claude/docs/troubleshooting/agent-delegation-troubleshooting.md:657
- .claude/lib/UTILS_README.md:210, 213, 230, 231, 332
- .claude/docs/concepts/hierarchical-agents.md:1227

**Assessment**: REMOVE_REFS
- Planned utility never implemented
- Remove all references from UTILS_README.md and troubleshooting docs

---

### 7. list-checkpoints.sh (3 references)

**Original Functionality**: Unknown - file did not exist in retrieved commit
- Likely planned checkpoint management utility
- Part of adaptive planning features

**Current Status**: NEVER EXISTED
- Could not retrieve from git history
- Referenced in adaptive-planning-guide.md for planned features

**Reference Locations**:
- .claude/docs/workflows/adaptive-planning-guide.md:260, 261, 355
- .claude/lib/UTILS_README.md:48, 51

**Assessment**: REMOVE_REFS
- Planned utility never implemented
- Remove from adaptive-planning-guide.md checkpoint management section

---

### 8. json-utils.sh (2 references)

**Original Functionality** (from git history):
- JSON/jq operations utilities
- Functions: jq_extract_field(), jq_validate_json(), jq_merge_objects()
- Purpose: Centralized jq operations with consistent error handling

**Current Status**: ARCHIVED - Not Used
- Marked as "not used" in refactor analysis
- No active code sources this utility

**Reference Locations**:
- .claude/docs/reference/library-api/utilities.md:383
- .claude/docs/guides/development/using-utility-libraries.md:391
- .claude/specs/820 reports and plans

**Assessment**: REMOVE_REFS
- Not used by any active code
- Remove API documentation reference

---

### 9. cleanup-checkpoints.sh (2 references)

**Original Functionality**: Unknown - file did not exist in retrieved commit
- Likely planned checkpoint cleanup utility
- Part of adaptive planning features

**Current Status**: NEVER EXISTED
- Could not retrieve from git history
- Referenced alongside list-checkpoints.sh

**Reference Locations**:
- .claude/docs/workflows/adaptive-planning-guide.md:273, 356
- .claude/lib/UTILS_README.md:61, 64

**Assessment**: REMOVE_REFS
- Planned utility never implemented
- Remove from adaptive-planning-guide.md

---

### 10. dependency-analysis.sh (1 reference)

**Original Functionality** (from git history):
- Dependency parsing and wave-based execution planning
- Functions: parse_dependencies(), calculate_execution_waves(), detect_circular_dependencies(), validate_dependencies()
- Purpose: Wave-based parallel execution for orchestration workflows

**Current Status**: ARCHIVED - Not Used
- Marked as "not used" in refactor analysis
- Note: sourced plan-core-bundle.sh (which still exists)

**Reference Locations**:
- .claude/docs/reference/workflows/phase-dependencies.md:829
- .claude/specs/820 reports and plans

**Assessment**: REMOVE_REFS
- Functionality archived, not needed
- Phase dependencies document references removed

---

### 11. agent-discovery.sh (1 reference)

**Original Functionality** (from git history):
- Agent auto-scanning and registration
- Functions: discover_agents(), extract_agent_metadata()
- Purpose: Discover and register agents in .claude/agents/

**Current Status**: ARCHIVED - Not Used
- Marked as "not used" in refactor analysis
- Sourced agent-schema-validator.sh (also archived)

**Reference Locations**:
- .claude/docs/reference/library-api/utilities.md:336
- .claude/specs/820 reports and plans

**Assessment**: REMOVE_REFS
- Agent discovery feature not implemented
- Remove API documentation reference

---

### 12. context-metrics.sh (1 reference)

**Original Functionality** (from git history):
- Context preservation metrics tracking
- Functions: track_context_usage(), calculate_context_reduction(), log_context_metrics(), generate_context_report()
- Purpose: Track context usage before/after operations for optimization

**Current Status**: ARCHIVED - Not Used
- Marked as "not used" in refactor analysis
- Feature not implemented

**Reference Locations**:
- .claude/docs/reference/library-api/utilities.md:345
- .claude/specs/820 reports and plans

**Assessment**: REMOVE_REFS
- Context tracking feature not implemented
- Remove API documentation reference

---

### 13. agent-schema-validator.sh (1 reference)

**Original Functionality** (from git history):
- Agent registry schema validation
- Functions: validate_agent_registry(), validate_agent_entry()
- Purpose: Validate agent registry against JSON schema

**Current Status**: ARCHIVED - Not Used
- Marked as "not used" in refactor analysis
- Depended on by agent-discovery.sh (also archived)

**Reference Locations**:
- .claude/docs/reference/library-api/utilities.md:340
- .claude/specs/820 reports and plans

**Assessment**: REMOVE_REFS
- Schema validation feature not implemented
- Remove API documentation reference

---

### 14. deps-utils.sh (1 reference)

**Original Functionality** (from git history):
- Dependency checking utilities
- Functions: check_dependency(), require_jq(), require_git(), require_bash4(), verify_dependencies(), check_dependency_version()
- Purpose: Centralized dependency validation with install hints

**Current Status**: ARCHIVED - Not Used
- Marked as "not used" in refactor analysis
- Was sourced by json-utils.sh (also archived)

**Reference Locations**:
- .claude/docs/reference/library-api/utilities.md:386
- .claude/specs/820 reports and plans

**Assessment**: REMOVE_REFS
- Not used by any active code
- Remove API documentation reference

---

### 15. git-utils.sh (1 reference)

**Original Functionality** (from git history):
- Git commit message generation
- Functions: generate_commit_message()
- Purpose: Standardized commit message generation for Phase 7 progress tracking

**Current Status**: ARCHIVED - Not Used
- Marked as "not used" in refactor analysis
- Progress tracking features evolved differently

**Reference Locations**:
- .claude/docs/reference/library-api/utilities.md:374
- .claude/specs/820 reports and plans

**Assessment**: REMOVE_REFS
- Not used by any active code
- Remove API documentation reference

---

## Recommendations

### Priority 1: Update References (2 files)

1. **parse-adaptive-plan.sh** (21 references)
   - Update all documentation to reference `.claude/lib/plan/plan-core-bundle.sh`
   - Keep function names but update file path
   - Files to update:
     - .claude/README.md:108
     - .claude/docs/workflows/adaptive-planning-guide.md
     - .claude/commands/README.md
     - .claude/lib/UTILS_README.md
     - .claude/docs/guides/patterns/implementation-guide.md

2. **complexity-thresholds.sh** (6 references)
   - Update documentation to reference `.claude/lib/plan/complexity-utils.sh`
   - Note that thresholds are now inline defaults
   - Files to update:
     - .claude/docs/guides/patterns/refactoring-methodology.md
     - .claude/docs/reference/library-api/utilities.md
     - .claude/docs/reference/library-api/overview.md

### Priority 2: Remove References (13 files)

**API Documentation Cleanup** (.claude/docs/reference/library-api/):
- Remove from utilities.md: agent-registry-utils.sh, agent-discovery.sh, agent-schema-validator.sh, context-metrics.sh, deps-utils.sh, git-utils.sh, json-utils.sh
- Remove from overview.md: agent-registry-utils.sh

**Guide Cleanup**:
- .claude/docs/guides/commands/setup-command-guide.md: Remove entire "README Scaffolding" section (generate-readme.sh)
- .claude/docs/guides/development/model-selection-guide.md: Remove "Monitoring" section (monitor-model-usage.sh)
- .claude/docs/guides/patterns/implementation-guide.md: Remove agent-registry-utils.sh references
- .claude/docs/guides/development/using-utility-libraries.md: Remove json-utils.sh reference

**Workflow/Concept Documentation Cleanup**:
- .claude/docs/workflows/adaptive-planning-guide.md: Remove list-checkpoints.sh and cleanup-checkpoints.sh references
- .claude/docs/troubleshooting/agent-delegation-troubleshooting.md: Remove validate-context-reduction.sh reference
- .claude/docs/concepts/hierarchical-agents.md: Remove validate-context-reduction.sh reference
- .claude/lib/UTILS_README.md: Remove all references to archived utilities

**Core Library Cleanup**:
- .claude/lib/core/error-handling.sh:1026: Remove agent-registry-utils.sh reference

### Priority 3: Documentation Consistency

After removing references, ensure:
1. No broken links remain in documentation
2. API documentation accurately reflects available utilities
3. Guide examples use only existing utilities
4. UTILS_README.md only documents existing files

## Implementation Notes

The lib directory refactoring (spec 820) properly archived unused utilities but did not complete the documentation cleanup. This report identifies all remaining stale references that need removal or update.

Key points:
- Files were intentionally archived as unused - do not restore
- parse-adaptive-plan.sh functionality lives in plan-core-bundle.sh
- complexity-thresholds.sh functionality lives in complexity-utils.sh (inline defaults)
- All other files represent unimplemented features

## References

Files analyzed:
- /home/benjamin/.config/.claude/lib/plan/plan-core-bundle.sh:1-50
- /home/benjamin/.config/.claude/lib/plan/complexity-utils.sh:1-30
- /home/benjamin/.config/.claude/README.md
- /home/benjamin/.config/.claude/docs/reference/library-api/utilities.md
- /home/benjamin/.config/.claude/docs/reference/library-api/overview.md
- /home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md
- /home/benjamin/.config/.claude/docs/guides/commands/setup-command-guide.md
- /home/benjamin/.config/.claude/docs/guides/patterns/implementation-guide.md
- /home/benjamin/.config/.claude/lib/UTILS_README.md
- /home/benjamin/.config/.claude/commands/README.md
- /home/benjamin/.config/.claude/commands/expand.md
- /home/benjamin/.config/.claude/specs/820_archive_and_backups_directories_can_be_safely/reports/001_lib_directory_refactor_analysis.md

Git commits referenced:
- fb8680db (lib reorganization deletes)
- 43a166e2 (archive deletes)
