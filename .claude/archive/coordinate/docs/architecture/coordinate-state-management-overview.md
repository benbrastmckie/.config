# /coordinate State Management Architecture - Overview

## Metadata
- **Date**: 2025-11-06
- **Command**: /coordinate
- **Pattern**: Stateless Recalculation
- **GitHub Issues**: #334, #2508
- **Related Specs**: 597, 598, 582-594, 599, 600

## Navigation

This document is part of a multi-part guide:
- **Overview** (this file) - Introduction, subprocess isolation, and stateless recalculation pattern
- [States & Decisions](coordinate-state-management-states.md) - Rejected alternatives, decision matrix, and selective state persistence
- [Transitions](coordinate-state-management-transitions.md) - Verification checkpoints and troubleshooting guide
- [Examples](coordinate-state-management-examples.md) - FAQ, historical context, and references

---

## Overview

This document explains the state management architecture for the `/coordinate` command, documenting the subprocess isolation constraint, the stateless recalculation pattern, rejected alternatives, and decision frameworks for state management.

The `/coordinate` command uses **stateless recalculation**: every bash block independently recalculates all variables it needs, without relying on state from previous blocks. This pattern emerged after 13 refactor attempts (specs 582-594) and provides the optimal balance of simplicity, performance, and reliability within the constraints of Claude Code's Bash tool execution model.

**Key Architectural Principles**:
- Work with subprocess isolation, not against it
- Fail-fast over hidden complexity
- Performance measured, not assumed
- Code duplication accepted when alternatives add complexity

**Target Audience**: Developers maintaining `/coordinate` or implementing similar bash-based commands.

---

## Subprocess Isolation Constraint

### The Fundamental Limitation

Claude Code's Bash tool executes each bash block in a **separate subprocess**, not a subshell. This architectural constraint has critical implications for variable persistence.

**GitHub Issues**:
- **#334**: Export persistence limitation first identified
- **#2508**: Confirmed subprocess model (not subshell)

### Technical Explanation

**What Happens** (process isolation):
```bash
# Block 1 (subprocess PID 1234)
export VAR="value"
export CLAUDE_PROJECT_DIR="/path/to/project"

# Block 2 (subprocess PID 5678 - DIFFERENT PROCESS)
echo "$VAR"  # Empty! Export didn't persist
echo "$CLAUDE_PROJECT_DIR"  # Empty! Export didn't persist
```

**Why It Happens**:
1. Bash tool launches new process for each block (not fork/subshell)
2. Separate process spaces = separate environment tables
3. Exports only persist within same process and child processes
4. Sequential bash blocks are **sibling processes**, not parent-child

**Subprocess vs Subshell**:
```bash
# Subshell (would work, but not how Bash tool operates)
(
  export VAR="value"
)
echo "$VAR"  # Would be empty (subshell boundary)

# Subprocess (how Bash tool actually works)
bash -c 'export VAR="value"'  # Process 1
bash -c 'echo "$VAR"'         # Process 2 (sibling to Process 1)
# Output: (empty - processes don't share environment)
```

### Validation Test

Proof of subprocess isolation:
```bash
# Test 1: Verify export failure
# Block 1
export TEST_VAR="coordinate-test-$$"
echo "Block 1 PID: $$"

# Block 2
echo "Block 2 PID: $$"  # Different PID = different process
echo "TEST_VAR: ${TEST_VAR:-EMPTY}"  # Will show EMPTY
```

Expected output shows different PIDs, confirming subprocess isolation.

### Implications

**Cannot Rely On**:
- Export between bash blocks
- Variable assignments persisting
- Function definitions persisting
- Working directory persisting (without re-establishing)

**Must Recalculate**:
- All variables needed in each block
- All function definitions (via library sourcing)
- Working directory (via CLAUDE_PROJECT_DIR detection)
- All derived state (WORKFLOW_SCOPE, PHASES_TO_EXECUTE, etc.)

---

## Stateless Recalculation Pattern

### Definition

**Stateless Recalculation**: Every bash block independently recalculates all variables it needs, without relying on state from previous blocks.

**Core Principle**: Treat each bash block as if it's the first and only block executing.

### Pattern Implementation

**Standard 13 - CLAUDE_PROJECT_DIR Detection**:
```bash
# Standard 13: CLAUDE_PROJECT_DIR detection for SlashCommand context
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
```

**Usage Frequency**: Applied in 6+ locations across coordinate.md (all bash blocks).

**Scope Detection Recalculation** (using library function after Phase 1):
```bash
# Source library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

# Parse workflow description from command argument
WORKFLOW_DESCRIPTION="$1"

# Call library function
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
```

**Derived Variable Recalculation** (PHASES_TO_EXECUTE mapping):
```bash
# Map workflow scope to phase execution list
case "$WORKFLOW_SCOPE" in
  research-only)
    PHASES_TO_EXECUTE="0,1"
    ;;
  research-and-plan)
    PHASES_TO_EXECUTE="0,1,2"
    ;;
  full-implementation)
    PHASES_TO_EXECUTE="0,1,2,3,4,6"
    ;;
  debug-only)
    PHASES_TO_EXECUTE="0,1,5"
    ;;
esac
```

### Pattern Benefits

**Correctness**:
- No dependency on subprocess behavior
- Deterministic results (same inputs → same outputs)
- No hidden state or race conditions

**Performance**:
- CLAUDE_PROJECT_DIR detection: <1ms (git command cached)
- Scope detection: <1ms (string pattern matching)
- PHASES_TO_EXECUTE mapping: <0.1ms (case statement)
- **Total per-block overhead**: ~2ms
- **Total workflow overhead**: ~12ms for 6 blocks

**Simplicity**:
- No I/O operations (no file reads/writes)
- No cleanup logic required
- No synchronization primitives needed
- Clear, readable code (pattern repeats consistently)

### Pattern Trade-offs

**Accepted**:
- Code duplication: Some variables recalculated in multiple blocks
- Synchronization requirement: Library sourcing must be consistent
- Cognitive overhead: Pattern must be understood by maintainers

**Rejected Alternatives** (see [States & Decisions](coordinate-state-management-states.md)):
- File-based state: 30ms I/O overhead (30x slower)
- Single large block: >400 lines triggers code transformation bugs
- Fighting tool constraints: Fragile workarounds violate fail-fast principle

### Validation

**Test Results** (from spec 597, 598):
- Research-only workflow: ✓
- Research-and-plan workflow: ✓
- Full-implementation workflow: ✓
- Debug-only workflow: ✓

**Performance Measurement**:
- Recalculation overhead: <1ms per variable
- Total workflow overhead: ~12ms (negligible)
- No I/O operations required

---

## Related Documentation

- [States & Decisions](coordinate-state-management-states.md) - Rejected alternatives, decision matrix, selective state persistence
- [Transitions](coordinate-state-management-transitions.md) - Verification checkpoints and troubleshooting
- [Examples](coordinate-state-management-examples.md) - FAQ, historical context, and references
- [Command Development Guide](../guides/command-development-guide.md)
- [Orchestration Best Practices](../guides/orchestration-best-practices.md)
