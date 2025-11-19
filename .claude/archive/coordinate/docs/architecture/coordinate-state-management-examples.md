# /coordinate State Management - Examples

## Navigation

This document is part of a multi-part guide:
- [Overview](coordinate-state-management-overview.md) - Introduction, subprocess isolation, and stateless recalculation pattern
- [States & Decisions](coordinate-state-management-states.md) - Rejected alternatives, decision matrix, and selective state persistence
- [Transitions](coordinate-state-management-transitions.md) - Verification checkpoints and troubleshooting guide
- **Examples** (this file) - FAQ, historical context, and references

---

## FAQ

### Q1: Why is code duplicated across bash blocks?

**A**: Bash tool subprocess isolation (GitHub #334, #2508) means exports don't persist between blocks. Each block must recalculate variables it needs. The alternative (file-based state) is 30x slower and adds complexity.

**Details**: See [Overview - Subprocess Isolation Constraint](coordinate-state-management-overview.md#subprocess-isolation-constraint) and [States & Decisions - Rejected Alternatives](coordinate-state-management-states.md#rejected-alternatives) sections.

---

### Q2: Can we use `export` to share variables between blocks?

**A**: No. Each bash block runs in a separate subprocess (not subshell), so exports don't persist. This is a fundamental limitation of the Bash tool architecture.

**Proof**:
```bash
# Block 1
export VAR="value"
echo "Block 1 PID: $$"  # PID: 1234

# Block 2
echo "Block 2 PID: $$"  # PID: 5678 (different process!)
echo "VAR: ${VAR:-EMPTY}"  # Output: EMPTY
```

**Reference**: GitHub issues #334 and #2508

---

### Q3: Should we refactor to eliminate code duplication?

**A**: Only if extraction to library functions (Phase 1 of current refactor). Do NOT attempt:
- File-based state (30x slower)
- Single large block (transformation bugs at >400 lines)
- Fighting subprocess isolation (fragile, violates fail-fast)

**Decision Matrix**: See [States & Decisions - Decision Matrix](coordinate-state-management-states.md#decision-matrix) section for when to use each pattern.

---

### Q4: When should we use file-based state instead?

**A**: Only when computation cost >1 second OR state must persist across /coordinate invocations (not just between bash blocks).

**Example Use Case**:
```bash
# Expensive computation (30+ seconds)
if [ ! -f "${CACHE_FILE}" ]; then
  build_dependency_graph > "${CACHE_FILE}"  # 30 seconds
fi
GRAPH=$(cat "${CACHE_FILE}")  # 30ms
# Net savings: 30s - 30ms = 29.97s (worthwhile)
```

**Non-Example** (/coordinate case):
```bash
# Fast recalculation (<1ms)
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
# File I/O would cost 30ms (30x slower than recalculation)
```

---

### Q5: What's the performance impact of stateless recalculation?

**A**: Negligible. Measured overhead:
- CLAUDE_PROJECT_DIR detection: <1ms (git command cached)
- Scope detection: <1ms (string pattern matching)
- PHASES_TO_EXECUTE mapping: <0.1ms (case statement)
- **Total per-block**: ~2ms
- **Total workflow**: ~12ms for 6 blocks

**Context**: File I/O would cost 30ms per operation, 15-30x slower.

---

### Q6: Why not consolidate bash blocks to reduce duplication?

**A**: We do, up to 300-line safe threshold. But code transformation occurs at 400+ lines:
- <300 lines: Safe to consolidate
- 300-400 lines: Risky (100-line safety margin)
- ≥400 lines: Code transformation bugs (unpredictable failures)

**Current Structure**:
- Block 1: 176 lines (safe)
- Block 2: 168 lines (safe)
- Block 3: 77 lines (safe)
- **Total**: 421 lines across 3 blocks

**Why Not Single Block**: 421 lines would exceed 400-line threshold, triggering transformation.

**Reference**: Spec 582 discovered 400-line threshold

---

### Q7: How do we prevent synchronization bugs when duplicating code?

**A**: Three strategies:
1. **Extract to libraries** (Phase 1): Reduce duplication to library calls
2. **Synchronization tests** (Phase 3): Automated detection of drift
3. **Clear comments**: Document why duplication exists and where

**Example** (Phase 3 synchronization tests):
```bash
# Test: Verify scope detection uses library
grep "detect_workflow_scope" coordinate.md Block1
grep "detect_workflow_scope" coordinate.md Block3
# If inline logic found: FAIL
```

---

### Q8: Is this pattern used by other commands?

**A**: Yes. Stateless recalculation is the standard pattern for all bash-based commands:
- `/coordinate`: 6 blocks, 4 recalculated variables
- `/orchestrate`: Similar pattern
- `/supervise`: Similar pattern

**Alternative patterns**:
- `/implement`: Uses checkpoint files (multi-phase resumable workflow)
- Simple utilities: Single bash block (<300 lines, no subagents)

---

### Q9: What happens if we miss recalculating a variable?

**A**: Immediate failure with "unbound variable" error (fail-fast behavior).

**Example** (Spec 598, Issue 2):
```bash
# Block 1: Calculate variable
PHASES_TO_EXECUTE="0,1,2,3,4,6"

# Block 3: Forget to recalculate
# (missing PHASES_TO_EXECUTE calculation)

# Later in Block 3:
should_run_phase 3  # Calls workflow-detection.sh:182
# Error: PHASES_TO_EXECUTE: unbound variable
```

**Why This Is Good**: Fail-fast prevents silent failures and hidden bugs.

---

### Q10: Where can I learn more about bash subprocess vs subshell?

**A**: See [Overview - Subprocess Isolation Constraint](coordinate-state-management-overview.md#subprocess-isolation-constraint) section for technical details.

**Quick Summary**:
- **Subshell**: `( command )` - Forked from parent, shares some state
- **Subprocess**: `bash -c 'command'` - Independent process, no shared state
- **Bash tool**: Uses subprocess model (each block = independent process)

**Implication**: No shared state between blocks (must recalculate everything).

---

## Real-World Examples

### Example 1: /coordinate (Stateless Recalculation)

- Variables: CLAUDE_PROJECT_DIR, WORKFLOW_SCOPE, PHASES_TO_EXECUTE, WORKFLOW_DESCRIPTION
- Count: 4 core variables
- Recalculation cost: <2ms total
- Pattern: Stateless recalculation (Pattern 1)
- Rationale: Fast recalculation, simple state, no cross-invocation persistence

### Example 2: /implement (Checkpoints)

- Variables: Current phase, test results, file modifications, error history
- Count: 20+ variables
- Pattern: Checkpoint files (Pattern 2)
- Rationale: Resumable workflow, complex state, cross-invocation persistence required

### Example 3: Hypothetical Analytics Command (File-based State)

- Variables: Codebase dependency graph (10,000+ nodes)
- Computation cost: 30+ seconds to build graph
- Pattern: File-based state (Pattern 3)
- Rationale: Expensive computation, cache across invocations

---

## Historical Context

### Evolution of /coordinate State Management

The stateless recalculation pattern emerged after 13 refactor attempts across specs 582-594. This section documents the journey to understand why this pattern is correct.

### Key Milestones

**Spec 578: Foundation (Nov 4, 2025)**
- **Problem**: `${BASH_SOURCE[0]}` undefined in SlashCommand context
- **Solution**: Replace with `CLAUDE_PROJECT_DIR` detection
- **Status**: Complete (8-line fix, 1.5 hours)
- **Impact**: Established Standard 13 as foundation for all subsequent work

**Spec 581: Performance Optimization (Nov 4, 2025)**
- **Problem**: Redundant library sourcing
- **Solution**: Consolidate bash blocks, conditional library loading
- **Status**: Complete (4 hours)
- **Innovation**: Merged 3 Phase 0 blocks → 1 block (saved 250-400ms per workflow)
- **Unintended Consequence**: Created 403-line single block (exceeded transformation threshold)

**Spec 582: Code Transformation Discovery (Nov 4, 2025)**
- **Problem**: Bash code transformation in large (403-line) blocks
- **Solution**: Split large block → 3 smaller blocks
- **Status**: Complete (1-2 hours)
- **Critical Discovery**: Claude AI performs code transformation at 400-line threshold
- **Unintended Consequence**: Splitting blocks exposed export persistence limitation

**Spec 583: BASH_SOURCE Limitation (Nov 4, 2025)**
- **Problem**: BASH_SOURCE empty after block split
- **Solution**: Use CLAUDE_PROJECT_DIR from Block 1
- **Status**: Complete (10 minutes)
- **Assumption**: Exports from Block 1 persist to Block 2
- **Actual Result**: Exposed deeper issue - exports don't persist

**Spec 584: Export Persistence Failure (Nov 4, 2025)**
- **Problem**: Exports from Block 1 don't reach Block 2-3
- **Status**: Complete (confirmed limitation, no workaround)
- **Root Cause**: Bash tool subprocess isolation (GitHub #334, #2508)
- **Impact**: Forced acceptance of subprocess isolation as architectural constraint

**Spec 585: Pattern Validation (Nov 4, 2025)**
- **Problem**: Evaluate state management alternatives
- **Research**: File-based state (30x slower), single large block (transformation risk), stateless recalculation (<1ms overhead)
- **Recommendation**: Use stateless recalculation for /coordinate
- **Impact**: Validated stateless recalculation as correct approach

**Specs 586-594: Incremental Refinements (Nov 4-5, 2025)**
- **Activities**: Library organization, error handling improvements, documentation
- **Contribution**: Refined understanding of subprocess isolation, Standard 13 application

**Spec 597: Stateless Recalculation Breakthrough (Nov 5, 2025)**
- **Problem**: Unbound variable errors in Block 3
- **Solution**: Apply stateless recalculation pattern
- **Status**: Complete (~15 minutes)
- **Test Results**: 16/16 tests passing
- **Performance**: <1ms overhead per recalculation
- **Impact**: First successful implementation of stateless recalculation

**Spec 598: Extend to Derived Variables (Nov 5, 2025)**
- **Problem**: PHASES_TO_EXECUTE not recalculated
- **Solution**: Extend stateless recalculation to all derived variables
- **Status**: Complete (30-45 minutes)
- **Issues Fixed**: 3 critical issues (library sourcing, PHASES_TO_EXECUTE, phase list)
- **Impact**: Completed stateless recalculation pattern

**Spec 599: Comprehensive Refactor Analysis (Nov 5, 2025)**
- **Problem**: Identify remaining improvement opportunities
- **Analysis**: 7 potential refactor phases identified
- **Impact**: Identified high-value improvements while accepting core stateless pattern

**Spec 600: High-Value Refactoring (Nov 5-6, 2025)**
- **Problem**: Execute highest-value improvements from spec 599
- **Phases**: Extract scope detection to library, add synchronization tests, document architecture
- **Status**: Phase 4 in progress (this document)
- **Impact**: Reduces duplication while maintaining stateless recalculation foundation

### Summary Timeline

```
Spec 578 (Nov 4) → Standard 13 foundation
         ↓
Spec 581 (Nov 4) → Block consolidation (exposed issues)
         ↓
Spec 582 (Nov 4) → 400-line transformation discovery
         ↓
Spec 583 (Nov 4) → BASH_SOURCE limitation
         ↓
Spec 584 (Nov 4) → Export persistence failure (root cause)
         ↓
Spec 585 (Nov 4) → Pattern validation (stateless recommended)
         ↓
Specs 586-594    → Incremental refinements
         ↓
Spec 597 (Nov 5) → Stateless recalculation success
         ↓
Spec 598 (Nov 5) → Pattern completion (derived variables)
         ↓
Spec 599 (Nov 5) → Refactor opportunity analysis
         ↓
Spec 600 (Nov 6) → High-value improvements (current)
```

### Key Lessons

1. **Tool Constraints Are Architectural**: Don't fight subprocess isolation, design around it
2. **Fail-Fast Over Complexity**: Immediate errors better than hidden bugs
3. **Performance Measurement**: 1ms recalculation vs 30ms file I/O (30x difference)
4. **Code Duplication Can Be Correct**: 50 lines duplication < file I/O complexity
5. **Validation Through Testing**: 16 tests prove pattern works in production
6. **Incremental Discovery**: 13 attempts over time led to correct solution

---

## References

- **GitHub Issues**:
  - [#334](https://github.com/anthropics/claude-code/issues/334) - Export persistence limitation first identified
  - [#2508](https://github.com/anthropics/claude-code/issues/2508) - Confirmed subprocess model (not subshell)

- **Specifications**:
  - Spec 578: Fix Library Sourcing Error (BASH_SOURCE limitation)
  - Spec 581: Performance Optimization (block consolidation)
  - Spec 582: Code Transformation Discovery (400-line threshold)
  - Spec 583: BASH_SOURCE Limitation (SlashCommand context)
  - Spec 584: Export Persistence Failure (root cause identification)
  - Spec 585: Pattern Validation (stateless recommended)
  - Specs 586-594: Incremental refinements
  - Spec 597: Stateless Recalculation Breakthrough (first success)
  - Spec 598: Extend to Derived Variables (pattern completion)
  - Spec 599: Comprehensive Refactor Analysis (7 opportunities)
  - Spec 600: High-Value Refactoring (current implementation)

- **Related Documentation**:
  - [Overview](coordinate-state-management-overview.md) - Introduction and stateless recalculation pattern
  - [States & Decisions](coordinate-state-management-states.md) - Rejected alternatives and decision matrix
  - [Transitions](coordinate-state-management-transitions.md) - Verification checkpoints and troubleshooting
  - [Command Development Guide](../guides/command-development-guide.md)
  - [Orchestration Best Practices](../guides/orchestration-best-practices.md)
  - [CLAUDE.md](../../CLAUDE.md) - Project configuration and standards
