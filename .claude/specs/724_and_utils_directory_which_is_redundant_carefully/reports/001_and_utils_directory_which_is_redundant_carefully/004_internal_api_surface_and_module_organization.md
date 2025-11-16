# Internal API Surface and Module Organization Research Report

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: Internal API Surface and Module Organization
- **Report Type**: codebase analysis
- **Overview Report**: [Research Overview](./OVERVIEW.md)

## Related Reports

This is part 4 of 4 in a hierarchical research analysis:
- **[Overview](./OVERVIEW.md)** - Synthesized findings across all subtopics
- **[Avante MCP Consolidation and Abstraction](./001_avante_mcp_consolidation_and_abstraction.md)** - MCP integration architecture
- **[Terminal Management and State Coordination](./002_terminal_management_and_state_coordination.md)** - Bash subprocess isolation patterns
- **[System Prompts and Configuration Persistence](./003_system_prompts_and_configuration_persistence.md)** - Configuration approaches

## Executive Summary

The .claude/lib directory contains 58 bash library files totaling approximately 25,000+ lines of code, organized into 9 functional domains. Analysis reveals a well-structured internal API with explicit function exports, comprehensive documentation in README.md, and clear separation of concerns. Key findings: 109+ exported functions identified, organized consolidation patterns (plan-core-bundle.sh, unified-logger.sh), and consistent export patterns with source guards preventing duplicate sourcing.

## Findings

### 1. Library Inventory and Organization

**Total Libraries**: 58 shell script files in /home/benjamin/.config/.claude/lib/

**Functional Domains** (from README.md:196-243):
1. **Parsing & Plans** (3 modules): parse-plan-core.sh, plan-structure-utils.sh, plan-metadata-utils.sh
2. **Artifact Management** (2 modules): artifact-creation.sh, artifact-registry.sh
3. **Error Handling & Validation** (1 module): error-handling.sh
4. **Document Conversion** (5 modules): convert-core.sh, convert-docx.sh, convert-pdf.sh, convert-markdown.sh, conversion-logger.sh
5. **Adaptive Planning** (3 modules): adaptive-planning-logger.sh, checkpoint-utils.sh, complexity-utils.sh
6. **Agent Coordination** (3 modules): agent-registry-utils.sh, agent-invocation.sh, workflow-detection.sh
7. **Analysis & Metrics** (2 modules): analysis-pattern.sh, analyze-metrics.sh
8. **Template System** (3 modules): parse-template.sh, substitute-variables.sh, template-integration.sh
9. **Infrastructure** (6 modules): progress-dashboard.sh, auto-analysis-utils.sh, timestamp-utils.sh, json-utils.sh, deps-utils.sh, detect-project-dir.sh

### 2. Exported Function API Surface

**Function Export Pattern Analysis**:

Total exported functions identified: **109+ functions** across key modules

**Major API Surfaces by Module**:

1. **plan-core-bundle.sh** (31 exports, lines 1129-1159):
   - Phase/stage extraction: extract_phase_name, extract_phase_content, extract_stage_name, extract_stage_content
   - Structure operations: detect_structure_level, is_plan_expanded, list_expanded_phases, cleanup_plan_directory
   - Metadata manipulation: add_phase_metadata, update_structure_level, merge_phase_into_plan

2. **metadata-extraction.sh** (13 exports, lines 643-655):
   - Metadata extraction: extract_report_metadata, extract_plan_metadata, extract_summary_metadata, extract_accuracy_metadata
   - On-demand loading: load_metadata_on_demand, cache_metadata, get_cached_metadata
   - Section extraction: get_plan_section, get_report_section, get_plan_phase

3. **workflow-state-machine.sh** (13 exports, lines 880-895):
   - State management: sm_init, sm_load, sm_current_state, sm_transition, sm_execute, sm_save
   - State mapping: map_phase_to_state, map_state_to_phase, sm_is_terminal, sm_get_scope

4. **error-handling.sh** (18 exports, lines 861-881):
   - Classification: classify_error, detect_error_type, suggest_recovery
   - Retry logic: retry_with_backoff, retry_with_timeout, retry_with_fallback
   - User escalation: escalate_to_user, escalate_to_user_parallel, handle_state_error

5. **artifact-creation.sh** (7 exports, lines 262-267):
   - create_topic_artifact, create_artifact_directory, create_artifact_directory_with_workflow
   - get_next_artifact_number, write_artifact_file, generate_artifact_invocation

6. **artifact-registry.sh** (3+ exports, lines 400-402):
   - register_artifact, query_artifacts, update_artifact_status

### 3. Module Consolidation Patterns

**Recent Consolidation Efforts** (README.md:246-293):

1. **plan-core-bundle.sh** (1,159 lines) - Consolidates 3 modules:
   - Original files now act as lightweight wrappers
   - Benefits: Reduced sourcing overhead (3 files → 1), consistent function availability
   - Pattern: Single source file with wrapper compatibility layer

2. **unified-logger.sh** (717 lines) - Consolidates 2 loggers:
   - Merges adaptive-planning-logger.sh + conversion-logger.sh
   - Original logger files remain as wrappers
   - Benefits: Consistent logging interface, reduced duplication

3. **base-utils.sh** (~100 lines) - Common utilities:
   - Eliminates circular dependencies
   - Provides: error(), warn(), info(), debug(), require_command(), require_file(), require_dir()
   - Zero dependencies (base-utils.sh:18, README.md:296-320)

### 4. Source Guards and Duplicate Prevention

**Pattern**: All major libraries implement source guard pattern

Example from error-handling.sh (lines 6-9):
```bash
if [ -n "${ERROR_HANDLING_SOURCED:-}" ]; then
  return 0
fi
export ERROR_HANDLING_SOURCED=1
```

**Benefits**:
- Prevents duplicate sourcing across multiple dependencies
- Enables safe circular dependency resolution
- Reduces memory footprint in long-running scripts

### 5. Constants and Configuration

**Readonly Constants Pattern** (58+ constants identified):

1. **Error Types** (error-handling.sh:18-27):
   - ERROR_TYPE_TRANSIENT, ERROR_TYPE_PERMANENT, ERROR_TYPE_FATAL
   - ERROR_TYPE_LLM_TIMEOUT, ERROR_TYPE_LLM_API_ERROR, ERROR_TYPE_LLM_LOW_CONFIDENCE

2. **State Definitions** (workflow-state-machine.sh:37-44):
   - STATE_INITIALIZE, STATE_RESEARCH, STATE_PLAN, STATE_IMPLEMENT
   - STATE_TEST, STATE_DEBUG, STATE_DOCUMENT, STATE_COMPLETE

3. **ANSI/Display Constants** (progress-dashboard.sh:55-99):
   - Cursor control, colors, box-drawing characters
   - 30+ display-related constants

4. **Directory Paths** (multiple modules):
   - CHECKPOINT_SCHEMA_VERSION="2.1" (checkpoint-utils.sh:25)
   - CHECKPOINTS_DIR, ERROR_LOG_DIR, ARTIFACT_REGISTRY_DIR

### 6. Library Classification and Sourcing Strategy

**From README.md:102-193**:

**Core Libraries** (auto-sourced by all commands):
- unified-location-detection.sh - 85% token reduction, 25x speedup
- error-handling.sh - Fail-fast error handling
- checkpoint-utils.sh - State preservation
- unified-logger.sh - Progress logging
- metadata-extraction.sh - 99% context reduction

**Workflow Libraries** (orchestration):
- dependency-analyzer.sh - Wave-based execution (40-60% time savings)
- complexity-utils.sh - Adaptive planning thresholds
- plan-core-bundle.sh - Plan parsing and structure

**Specialized Libraries** (single-command):
- convert-*.sh (only /convert-docs)
- template-*.sh (only /plan-from-template, /plan-wizard)
- agent-*.sh (only orchestration commands)

### 7. Dependency Graph Analysis

**Zero-Dependency Base Layer** (README.md:1426-1442):
- timestamp-utils.sh
- deps-utils.sh
- detect-project-dir.sh
- base-utils.sh (added to break circular dependencies)

**Dependency Hierarchy**:
```
Level 1: Core Infrastructure (no dependencies)
  ├─ base-utils.sh
  ├─ timestamp-utils.sh
  ├─ deps-utils.sh
  └─ detect-project-dir.sh

Level 2: JSON & Validation
  ├─ json-utils.sh → deps-utils.sh
  └─ validation-utils.sh (standalone)

Level 3: Domain Libraries
  ├─ error-handling.sh → timestamp-utils.sh
  ├─ artifact-creation.sh → json-utils.sh, timestamp-utils.sh
  └─ metadata-extraction.sh → base-utils.sh, unified-logger.sh

Level 4: High-Level Operations
  └─ auto-analysis-utils.sh → complexity-utils.sh, artifact-creation.sh, error-handling.sh
```

### 8. Documentation Quality

**README.md Analysis** (1,695 lines):
- Comprehensive module documentation with usage examples
- Function-level documentation for all 42+ modules
- Dependency graphs and sourcing order guidelines
- Version history tracking (v1.1 → v2.0 clean-break refactor)
- Integration patterns for Neovim picker

**Per-Module Documentation Standards**:
- Header comments describing purpose
- Dependencies listed explicitly
- Usage examples with code blocks
- Exit codes documented
- Export statements at bottom of file

### 9. Testing Infrastructure

**Test Categories** (README.md:1597-1604):
- test_parsing_utilities.sh - Parsing modules
- test_shared_utilities.sh - Core utilities
- test_artifact_utils.sh - Artifact operations
- test_progressive_*.sh - Progressive planning
- test_adaptive_planning.sh - Adaptive planning integration
- test_convert_docs_*.sh - Document conversion (5 test files)

**Coverage Target**: >80% for new utilities (README.md:1606)

## Recommendations

### 1. Standardize Export Patterns

**Current State**: Inconsistent export block locations (some at bottom, some scattered)

**Recommendation**: Enforce export blocks at EOF (End Of File) pattern consistently:
```bash
# Export functions (if sourced)
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f function_name_1
  export -f function_name_2
  # ... all exports grouped together
fi
```

**Benefits**: Easier API surface auditing, clearer function discovery

### 2. Create API Surface Documentation

**Recommendation**: Generate automated API reference from export statements

**Approach**:
1. Parse all `export -f` statements across lib/ directory
2. Extract function signatures and first-line comments
3. Generate markdown reference: .claude/docs/reference/lib-api-reference.md
4. Organize by functional domain (matching README.md structure)

**Benefits**: Single source of truth for available functions, reduces documentation drift

### 3. Implement Function Deprecation Strategy

**Current Gap**: No mechanism for deprecating obsolete functions while maintaining compatibility

**Recommendation**: Add deprecation annotation pattern:
```bash
# DEPRECATED: Use new_function_name instead (removal scheduled: v3.0)
old_function_name() {
  echo "Warning: old_function_name is deprecated, use new_function_name" >&2
  new_function_name "$@"
}
```

**Benefits**: Gradual migration path, backward compatibility during refactors

### 4. Consolidate Remaining Redundant Modules

**Candidates for Consolidation** (based on function overlap patterns):
1. **Verification Helpers**: verification-helpers.sh exports 4 functions - could merge into base-utils.sh or error-handling.sh
2. **Checkbox Utils**: checkbox-utils.sh (5 exports) - specialized enough to remain standalone but document as optional
3. **Workflow Detection**: workflow-detection.sh (1 export: should_run_phase) - candidate for merging into workflow-state-machine.sh

**Benefits**: Reduced file count, simpler dependency graph

### 5. Add Library Usage Analytics

**Recommendation**: Instrument library sourcing to track actual usage patterns

**Approach**:
```bash
# In each library, add optional telemetry
if [ "${CLAUDE_TRACK_USAGE:-0}" = "1" ]; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ),${BASH_SOURCE[0]}" >> .claude/data/logs/library-usage.log
fi
```

**Benefits**: Data-driven decisions on which libraries to optimize, identify unused code

### 6. Standardize Constant Naming Conventions

**Current State**: Mixed patterns - ERROR_TYPE_*, STATE_*, ANSI_*, BOX_*, ICON_*

**Recommendation**: Adopt consistent prefix pattern:
- Module-scoped constants: `${MODULE}_CONSTANT_NAME`
- Example: ERROR_HANDLING_TYPE_TRANSIENT, STATE_MACHINE_STATE_COMPLETE
- Global constants: Keep current pattern (CHECKPOINTS_DIR, etc.)

**Benefits**: Namespace collision prevention, clearer constant origin

## References

### Files Analyzed

1. /home/benjamin/.config/.claude/lib/README.md - Complete library documentation (1,695 lines)
2. /home/benjamin/.config/.claude/lib/unified-location-detection.sh:1-597 - Location detection with lazy creation
3. /home/benjamin/.config/.claude/lib/base-utils.sh:1-80 - Base utility functions
4. /home/benjamin/.config/.claude/lib/git-utils.sh:1-83 - Git commit message generation
5. /home/benjamin/.config/.claude/lib/error-handling.sh:1-882 - Error classification and recovery (18 exports)
6. /home/benjamin/.config/.claude/lib/metadata-extraction.sh:1-655 - Metadata extraction (13 exports)
7. /home/benjamin/.config/.claude/lib/plan-core-bundle.sh (referenced) - 31 exports for plan operations
8. /home/benjamin/.config/.claude/lib/workflow-state-machine.sh (referenced) - 13 exports for state management
9. /home/benjamin/.config/.claude/lib/artifact-creation.sh (referenced) - 7 exports for artifact creation
10. /home/benjamin/.config/.claude/lib/artifact-registry.sh (referenced) - 3+ exports for registry operations

### Key Patterns Identified

- **Source Guards**: Implemented in all major libraries (error-handling.sh:6-9)
- **Export Blocks**: 109+ exported functions across modules
- **Consolidation Pattern**: 3 major bundles (plan-core-bundle.sh, unified-logger.sh, base-utils.sh)
- **Dependency Hierarchy**: 4-level dependency graph with zero-dependency base layer
- **Constants**: 58+ readonly constants for configuration and state definitions

### External References

- README.md functional domain classification (lines 196-243)
- Module consolidation strategy (lines 246-293)
- Library sourcing best practices (lines 144-163)
- Dependency graph visualization (lines 1426-1479)
