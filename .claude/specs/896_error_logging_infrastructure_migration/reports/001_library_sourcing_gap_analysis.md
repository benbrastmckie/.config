# Library Sourcing and Error Logging Gap Analysis

## Analysis Date
2025-11-21

## Executive Summary

This report analyzes gaps in the error logging infrastructure, specifically focusing on:
1. Existing library sourcing utilities that are NOT being used by commands
2. Function validation capabilities that lack centralized error logging
3. Error logging coverage gaps in orchestrator commands

## Key Findings

### 1. Existing Library Sourcing Utilities (UNUSED)

Two library sourcing utilities exist but **no commands use them**:

#### source-libraries.sh
Location: `/home/benjamin/.config/.claude/lib/core/source-libraries.sh`

Features:
- `source_libraries_for_block()` - Block-type based sourcing (init, state, verify)
- `validate_sourced_functions()` - Validates required functions by block type
- Predefined function requirements per block type

```bash
validate_sourced_functions() {
  local block_type="$1"
  local missing_functions=()

  case "$block_type" in
    init)
      local required=("log_command_error" "init_workflow_state" "append_workflow_state" "initialize_state_machine")
      ;;
    state)
      local required=("log_command_error" "load_workflow_state" "append_workflow_state" "initialize_workflow_paths")
      ;;
    verify)
      local required=("log_command_error" "load_workflow_state" "transition_state")
      ;;
  esac
  # ... validation logic ...
}
```

#### source-libraries-inline.sh
Location: `/home/benjamin/.config/.claude/lib/core/source-libraries-inline.sh`

Features:
- Three-tier sourcing pattern (Critical, Workflow, Command-specific)
- `source_critical_libraries()` - Tier 1 with fail-fast
- `source_workflow_libraries()` - Tier 2 with graceful degradation
- `source_command_libraries()` - Tier 3 optional
- Built-in validation for `append_workflow_state` and `save_completed_states_to_state`

```bash
source_critical_libraries() {
  # ... sources libraries ...

  # Verify critical functions are available
  if ! type append_workflow_state &>/dev/null; then
    echo "ERROR: append_workflow_state function not available" >&2
    return 1
  fi

  if ! type save_completed_states_to_state &>/dev/null; then
    echo "ERROR: save_completed_states_to_state function not available" >&2
    return 1
  fi
}
```

### 2. Current Command Behavior (Manual Inline Sourcing)

All commands currently use **manual inline sourcing** with no function validation:

```bash
# Current pattern in build.md, debug.md, plan.md, etc.
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
# No function validation after sourcing!
```

### 3. Error Logging Coverage Analysis

| Command | Has log_command_error | Notes |
|---------|----------------------|-------|
| build.md | Yes | Full coverage |
| debug.md | Yes | Full coverage |
| plan.md | Yes | Full coverage |
| repair.md | Yes | Full coverage |
| research.md | Yes | Full coverage |
| revise.md | Yes | Full coverage |
| convert-docs.md | Yes | Full coverage |
| setup.md | Yes | Full coverage |
| optimize-claude.md | Yes | Full coverage |
| errors.md | Yes | Query-only |
| **expand.md** | **NO** | **GAP** |
| **collapse.md** | **NO** | **GAP** |
| README.md | N/A | Documentation |

**Coverage: 11/13 commands (85%)**

### 4. Function Validation Gap

Existing validation only outputs to stderr - no centralized error logging:

```bash
# Current behavior (source-libraries-inline.sh)
if ! type append_workflow_state &>/dev/null; then
  echo "ERROR: append_workflow_state function not available" >&2  # Only stderr!
  return 1
}
# Missing: log_command_error call
```

## Gap Summary

| Gap | Impact | Priority |
|-----|--------|----------|
| Commands don't use library sourcing utilities | Code duplication, no function validation | High |
| Function validation lacks error logging | Errors not queryable via /errors | Medium |
| expand.md lacks error logging | 15% coverage gap | Medium |
| collapse.md lacks error logging | 15% coverage gap | Medium |

## Recommendations

### Phase 1: Enhance source-libraries-inline.sh
Add centralized error logging to function validation:

```bash
if ! type append_workflow_state &>/dev/null; then
  if type log_command_error &>/dev/null; then
    log_command_error "${COMMAND_NAME:-unknown}" "${WORKFLOW_ID:-unknown}" \
      "${USER_ARGS:-}" "dependency_error" \
      "append_workflow_state function not available" "library_validation" "{}"
  fi
  echo "ERROR: append_workflow_state function not available" >&2
  return 1
fi
```

### Phase 2: Migrate One Command as Proof-of-Concept
Migrate research.md to use source-libraries-inline.sh to validate the pattern.

### Phase 3: Add Error Logging to Orchestrators
Add error-handling.sh integration to expand.md and collapse.md.

### Phase 4: Full Command Migration (Future)
Migrate remaining commands to use standardized library sourcing.

## Implementation Status
- **Status**: Planning In Progress
- **Plan**: [Error Logging Infrastructure Migration Plan](../plans/001_error_logging_infrastructure_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-21

## Related Documentation

- Previous plan (superseded): `/home/benjamin/.config/.claude/specs/884_build_error_logging_discrepancy/plans/001_debug_strategy.md`
- Plan relevance analysis: `/home/benjamin/.config/.claude/specs/error_logging_plan_relevance/reports/001_plan_relevance_analysis.md`
