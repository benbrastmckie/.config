# State-Based Orchestration: Overview

**Related Documents**:
- [States](state-orchestration-states.md) - State machine architecture
- [Transitions](state-orchestration-transitions.md) - State transitions and persistence
- [Examples](state-orchestration-examples.md) - Reference implementations
- [Troubleshooting](state-orchestration-troubleshooting.md) - Common issues

---

## Metadata

- **Date**: 2025-11-17
- **Status**: Production (Phase 7 Complete)
- **Version**: 2.0 (State Machine Architecture)

## Executive Summary

The state-based orchestration architecture is a comprehensive refactor of the `.claude/` orchestration system that introduced formal state machines, selective file-based state persistence, and hierarchical supervisor coordination. This architecture replaces implicit phase-based orchestration with explicit state enumeration, validated transitions, and coordinated checkpoint management.

### Key Achievements

**Code Reduction**: 48.9% (3,420 -> 1,748 lines across 3 orchestrators)
- Exceeded 39% target by 9.9%
- Eliminated 1,672 lines of duplicate logic
- Consolidated state machine implementation

**Performance Improvements**:
- State operations: 67% faster (6ms -> 2ms for CLAUDE_PROJECT_DIR detection)
- Context reduction: 95.6% via hierarchical supervisors
- Parallel execution: 53% time savings
- File creation reliability: 100% maintained

**Architectural Benefits**:
- Explicit over implicit: Named states replace phase numbers
- Validated transitions: State machine enforces valid state changes
- Centralized logic: Single state machine library owns lifecycle
- Hierarchical coordination: 95%+ context reduction at scale

### Core Components

1. **State Machine Library** (`workflow-state-machine.sh`)
   - 8 explicit states
   - Transition table validation
   - Atomic state transitions with checkpoint coordination
   - 50 tests passing

2. **State Persistence Library** (`state-persistence.sh`)
   - GitHub Actions-style workflow state files
   - Selective file-based persistence (7 critical items)
   - Graceful degradation to stateless recalculation
   - 67% performance improvement

3. **Hierarchical Supervisor Pattern**
   - Research supervisors coordinate parallel workers
   - 95%+ context reduction at scale
   - Metadata-only context passing
   - 53% parallel execution time savings

## Architecture Principles

### 1. Explicit State Management

Replace implicit phases with explicit named states:

```bash
# Old: Implicit phases
PHASE=1
((PHASE++))

# New: Explicit states
sm_transition "research" "planning"
```

### 2. Validated Transitions

State machine enforces valid transitions:

```bash
# Valid transitions defined in table
TRANSITIONS=(
  "initialize:research"
  "research:planning"
  "planning:implementation"
  "implementation:testing"
  "testing:documentation"
  "documentation:complete"
)

# Invalid transition fails
sm_transition "initialize" "complete"  # Error
```

### 3. Selective Persistence

Only persist what needs to survive failures:

| Item | Persist? | Reason |
|------|----------|--------|
| WORKFLOW_SCOPE | Yes | Classification result |
| TOPIC_PATH | Yes | Artifact location |
| PLAN_PATH | Yes | Created artifact |
| thinking_mode | No | Recalculable |
| progress_markers | No | Transient |

### 4. Hierarchical Coordination

Use supervisors to manage context:

```
Orchestrator (30k tokens)
    |
    +-- Supervisor (20k tokens)
            +-- Worker 1 (10k tokens)
            +-- Worker 2 (10k tokens)
            +-- Worker 3 (10k tokens)
```

Context at orchestrator: 440 tokens (vs 10,000 without hierarchy)

## Quick Start

### Initialize State Machine

```bash
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Initialize state machine
if ! sm_init "$WORKFLOW_DESC" "coordinate"; then
  echo "ERROR: State machine initialization failed"
  exit 1
fi

# Verify exports
echo "Scope: $WORKFLOW_SCOPE"
echo "Topics: $RESEARCH_TOPICS_JSON"
```

### Transition States

```bash
# Transition from current to next state
sm_transition "research" "planning" || exit 1

# Check current state
CURRENT=$(sm_get_state)
echo "Current state: $CURRENT"
```

### Persist State

```bash
# Append to state file
append_workflow_state "PLAN_PATH" "$PLAN_PATH"
append_workflow_state "REPORT_PATHS" "$REPORTS_JSON"

# Load from state file
PLAN=$(load_workflow_state "PLAN_PATH")
```

## Performance Summary

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Code size | 3,420 | 1,748 | 48.9% reduction |
| CLAUDE_PROJECT_DIR | 6ms | 2ms | 67% faster |
| Context per agent | 2,500 | 110 | 95.6% reduction |
| Parallel execution | N/A | Yes | 53% time savings |

## Migration Path

Commands using old phase-based orchestration should migrate:

1. Replace phase numbers with state names
2. Use `sm_transition()` for state changes
3. Use `append_workflow_state()` for persistence
4. Add supervisors for parallel agents

See [Migration Guide](state-orchestration-transitions.md#migration-from-phase-based) for details.

---

## Related Documentation

- [States](state-orchestration-states.md) - State definitions
- [Transitions](state-orchestration-transitions.md) - State transitions
- [Examples](state-orchestration-examples.md) - Implementations
- [Troubleshooting](state-orchestration-troubleshooting.md) - Issues
