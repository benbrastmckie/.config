# /research Command Error Repair Implementation Plan

## Metadata
- **Date**: 2025-11-23
- **Feature**: /research Command Error Repair
- **Scope**: Fix error patterns in /research command affecting topic naming, research topics validation, bash environment, and state machine initialization
- **Estimated Phases**: 4
- **Estimated Hours**: 8
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Complexity Score**: 31 (Tier 1)
- **Structure Level**: 0
- **Research Reports**:
  - [Error Analysis Report](/home/benjamin/.config/.claude/specs/935_errors_repair_research/reports/001_error_analysis.md)

## Overview

This plan addresses four distinct error patterns identified in the /research command:

1. **Topic Naming Agent Failures** (29% of errors): Agent output file not created, preventing directory naming
2. **Research Topics Validation Failures** (29% of errors): Empty research_topics array from classifier
3. **Bash Environment Initialization Errors** (29% of errors): /etc/bashrc sourcing failures
4. **State Machine Transition Failures** (14% of errors): STATE_FILE not set before sm_transition

These errors cause workflow failures that prevent proper directory creation and state management.

## Research Summary

Key findings from error analysis report:

- **Root Cause 1 (Agent Output)**: Topic naming agent invocation fails silently with no output file created. The `validate_agent_output` function exists but needs retry logic with exponential backoff.
- **Root Cause 2 (Classification)**: Classification agent returns `topic_directory_slug` but empty `research_topics: []`. Partial results pass initial validation but fail downstream.
- **Root Cause 3 (State Initialization)**: `load_workflow_state` not called before `sm_transition` in some code paths. STATE_FILE remains unset causing immediate failure.
- **Root Cause 4 (Bash Environment)**: `/etc/bashrc` sourcing failures are already filtered by `_is_benign_bash_error` but pattern may be incomplete for some environments.

Recommended approach: Implement defensive guards at each failure point with clear error messages and graceful fallbacks where appropriate.

## Success Criteria

- [ ] Topic naming agent failures produce clear diagnostic messages and use robust fallback naming
- [ ] Research topics validation catches empty arrays and provides meaningful defaults
- [ ] Bash environment errors from system initialization files are properly filtered
- [ ] State machine validates initialization before any transition attempt
- [ ] All existing tests continue to pass
- [ ] New tests cover the four error patterns identified

## Technical Design

### Architecture Overview

The fixes target three library files:

1. **error-handling.sh**: Enhance agent output validation and bash error filtering
2. **workflow-initialization.sh**: Add research_topics validation before path allocation
3. **workflow-state-machine.sh**: Add state initialization guards with clear diagnostics

### Component Interactions

```
/research command
    |
    v
workflow-initialization.sh
    |-- validate_and_generate_filename_slugs() [Phase 1: Add empty array handling]
    |-- validate_topic_directory_slug() [Already has fallback]
    |
    v
workflow-state-machine.sh
    |-- sm_init() [Already validates]
    |-- sm_transition() [Phase 3: Add initialization guard]
    |
    v
error-handling.sh
    |-- validate_agent_output_with_retry() [Phase 2: Add timeout handling]
    |-- _is_benign_bash_error() [Phase 4: Extend patterns]
```

## Implementation Phases

### Phase 1: Research Topics Validation Fix [NOT STARTED]
dependencies: []

**Objective**: Ensure research_topics array is never empty when passed to path allocation

**Complexity**: Low

Tasks:
- [ ] Read workflow-initialization.sh to understand current validation flow (file: /home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh)
- [ ] Add validation in validate_and_generate_filename_slugs() to handle empty classification_result.research_topics
- [ ] Add logging when fallback slugs are generated due to empty research_topics
- [ ] Update validate_topic_directory_slug() error messages to include diagnostic information

Testing:
```bash
# Run research topics validation tests
bash /home/benjamin/.config/.claude/tests/topic-naming/test_topic_naming_fallback.sh
```

**Expected Duration**: 1.5 hours

### Phase 2: Agent Output Validation Enhancement [NOT STARTED]
dependencies: [1]

**Objective**: Make agent output validation more robust with better timeout handling and diagnostics

**Complexity**: Medium

Tasks:
- [ ] Read error-handling.sh validate_agent_output functions (file: /home/benjamin/.config/.claude/lib/core/error-handling.sh)
- [ ] Add pre-validation check for output path writability in validate_agent_output()
- [ ] Enhance validate_agent_output_with_retry() with configurable timeout (default 30s)
- [ ] Add diagnostic logging when agent fails to create output file
- [ ] Add metric logging for agent execution time to help identify timeout patterns

Testing:
```bash
# Run agent validation tests
bash /home/benjamin/.config/.claude/tests/unit/test_error_logging.sh
```

**Expected Duration**: 2 hours

### Phase 3: State Machine Initialization Guards [NOT STARTED]
dependencies: [1]

**Objective**: Prevent sm_transition from being called without proper state initialization

**Complexity**: Medium

Tasks:
- [ ] Read workflow-state-machine.sh to understand current initialization flow (file: /home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh)
- [ ] Add ensure_state_initialized() guard function that validates STATE_FILE and CURRENT_STATE
- [ ] Add guard call at start of sm_transition() before any state operations
- [ ] Add clear error message with instructions when guard fails
- [ ] Add sm_validate_state() call in sm_transition if not already present

Testing:
```bash
# Run state machine tests
bash /home/benjamin/.config/.claude/tests/state/test_state_machine_persistence.sh
bash /home/benjamin/.config/.claude/tests/state/test_state_persistence.sh
```

**Expected Duration**: 2.5 hours

### Phase 4: Bash Environment Error Filtering [NOT STARTED]
dependencies: [2]

**Objective**: Extend bash error filtering to prevent false positives from environment initialization

**Complexity**: Low

Tasks:
- [ ] Read _is_benign_bash_error() function in error-handling.sh (file: /home/benjamin/.config/.claude/lib/core/error-handling.sh)
- [ ] Add pattern for /etc/bash.bashrc (alternative bashrc location)
- [ ] Add pattern for .profile initialization failures
- [ ] Wrap /etc/bashrc sourcing with conditional guard in relevant places
- [ ] Add test case for NixOS-style bashrc failures

Testing:
```bash
# Run benign error filter tests
bash /home/benjamin/.config/.claude/tests/unit/test_benign_error_filter.sh
```

**Expected Duration**: 2 hours

## Testing Strategy

### Test Approach
1. **Unit Tests**: Test individual functions in isolation
2. **Integration Tests**: Test workflow end-to-end with simulated error conditions
3. **Regression Tests**: Ensure existing functionality remains working

### Test Commands
```bash
# Run all tests
bash /home/benjamin/.config/.claude/tests/run_all_tests.sh

# Run specific test categories
bash /home/benjamin/.config/.claude/tests/unit/test_error_logging.sh
bash /home/benjamin/.config/.claude/tests/unit/test_benign_error_filter.sh
bash /home/benjamin/.config/.claude/tests/state/test_state_persistence.sh
bash /home/benjamin/.config/.claude/tests/topic-naming/test_topic_naming_fallback.sh
```

### Coverage Requirements
- All four error patterns must have test coverage
- Error messages must be verified for clarity
- Fallback behaviors must be tested

## Documentation Requirements

- [ ] Update error-handling.sh function docstrings with new parameters
- [ ] Update workflow-state-machine.sh with initialization requirements
- [ ] Update workflow-initialization.sh with validation behavior documentation
- [ ] No new documentation files needed (inline documentation only)

## Dependencies

### External Dependencies
- jq (JSON processing) - already required
- bash 4.3+ (for nameref pattern) - already required

### Internal Dependencies
- state-persistence.sh - provides append_workflow_state()
- detect-project-dir.sh - provides CLAUDE_PROJECT_DIR
- topic-utils.sh - provides get_or_create_topic_number()

## Risk Assessment

### Technical Risks
1. **Guard function overhead**: Adding initialization checks may slightly increase execution time
   - Mitigation: Guards are simple null checks with minimal overhead
2. **Fallback naming collisions**: Multiple failed workflows may create similar "no_name_error" directories
   - Mitigation: Use timestamp suffix for uniqueness

### Rollback Strategy
- Each phase is independent and can be reverted individually
- No database or external state changes
- All changes are to library functions with existing tests
