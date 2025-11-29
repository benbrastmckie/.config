# Phase 10 Analysis: /expand and /collapse Hard Barrier Implementation

## Task Invocation Analysis

### /expand Command

**Current Task Invocations:**

1. **complexity-estimator (Phase 2)**:
   - Location: Line ~693-741
   - Current state: Pseudo-code format with MANDATORY VERIFICATION note
   - Barrier status: **Partial** - has verification note but no bash verification block

2. **plan-architect parallel invocations (Phase 3)**:
   - Location: Line ~743-789
   - Current state: Pseudo-code format for parallel execution
   - Barrier status: **MISSING** - no verification block after Task invocations

3. **Phase expansion (explicit mode)**:
   - Location: Block 3-5 (~190-275)
   - Current state: Mixed bash + pseudo-code
   - Barrier status: **MISSING** - no verification after plan-architect invocation

4. **Stage expansion (explicit mode)**:
   - Location: Block 3-5 (~428-543)
   - Current state: Mixed bash + pseudo-code
   - Barrier status: **MISSING** - no verification after plan-architect invocation

### /collapse Command

**Current Task Invocations:**

1. **complexity-estimator (Phase 2)**:
   - Location: Line ~558-585
   - Current state: Pseudo-code format
   - Barrier status: **MISSING** - no verification block

2. **plan-architect parallel invocations (Phase 3)**:
   - Location: Line ~587-616
   - Current state: Pseudo-code format for parallel execution
   - Barrier status: **MISSING** - no verification block after Task invocations

3. **Phase collapse (explicit mode)**:
   - Location: Block 3-7 (~215-279)
   - Current state: Mixed bash
   - Barrier status: **MISSING** - no verification after plan-architect invocation

4. **Stage collapse (explicit mode)**:
   - Location: Block 3-7 (~372-439)
   - Current state: Mixed bash
   - Barrier status: **MISSING** - no verification after plan-architect invocation

## Hard Barrier Implementation Plan

### Approach

For both commands, we need to:

1. **Split existing blocks** into Setup → Execute → Verify pattern
2. **Add CRITICAL BARRIER labels** before Task invocations
3. **Add fail-fast verification blocks** checking for artifact creation
4. **Add error logging** with recovery instructions

### Challenge: Auto-Analysis Mode

The auto-analysis mode uses parallel execution with dynamic agent invocation. This presents unique challenges:

- **Multiple Task invocations** in single message (by design)
- **Dynamic artifact paths** (not known until agents execute)
- **Verification must check all artifacts** from parallel execution

**Solution**: Add verification block in Phase 4 (Artifact Aggregation) that checks all expected files exist.

### Challenge: Explicit Mode

Explicit mode has simpler structure but Task invocations are mixed with bash blocks.

**Solution**: Split into 3 sub-blocks (Setup → Execute → Verify) similar to /revise pattern.

## Implementation Strategy

### For /expand

**Phase expansion (explicit mode) - Split Block 3-5:**

- **Block 3a: Complexity Detection Setup**
  - State transition (if needed)
  - Variable persistence
  - Checkpoint reporting

- **Block 3b: Plan-Architect Invocation [CRITICAL BARRIER]**
  - Task invocation for plan-architect (expansion)
  - Note about verification block dependency

- **Block 3c: Phase File Verification**
  - Fail-fast existence check for phase file
  - Fail-fast size check (>500 bytes)
  - Error logging with recovery hints
  - Checkpoint reporting

**Auto-analysis mode - Add verification in Phase 4:**

- After artifact aggregation, add bash verification block
- Check all expected expansion files exist
- Fail-fast if any missing
- Log errors with recovery instructions

### For /collapse

**Phase collapse (explicit mode) - Split Block 4:**

- **Block 4a: Merge Setup**
  - State transition
  - Read phase content
  - Prepare merge operation

- **Block 4b: Plan-Architect Invocation [CRITICAL BARRIER]**
  - Task invocation for plan-architect (collapse/merge)
  - Note about verification block dependency

- **Block 4c: Merge Verification**
  - Fail-fast check that content was merged
  - Verify parent plan updated
  - Error logging
  - Checkpoint reporting

**Auto-analysis mode - Add verification in Phase 4:**

- Similar to /expand
- Check all collapse operations completed
- Verify parent files updated

## Tool Restriction Evaluation

Current allowed-tools for both commands:
- /expand: Read, Write, Edit, Bash, Glob, Task
- /collapse: Read, Write, Edit, Bash, Task

**Recommendation**: **Keep current tools** for now because:

1. Orchestrator needs Read to validate inputs and verify outputs
2. Orchestrator needs Edit to update metadata after plan-architect completes
3. plan-architect does the actual expansion/collapse work
4. Hard barriers will enforce delegation even with permissive tools

**Future consideration**: Could restrict to Read (validation only) + Task + Bash once hard barriers proven effective.

**Document in metadata**: Add note that orchestrator uses Edit only for metadata updates, not content changes.

## Expected Outcomes

After implementation:

1. **100% delegation** to plan-architect for expansion/collapse content work
2. **Fail-fast verification** catches missing artifacts immediately
3. **Clear error messages** with recovery instructions
4. **Consistent pattern** across /expand, /collapse, /revise, /build

## Next Steps

1. Implement hard barriers in /expand explicit mode (phase expansion)
2. Implement hard barriers in /expand explicit mode (stage expansion)
3. Implement hard barriers in /expand auto-analysis mode (Phase 4 verification)
4. Repeat for /collapse command
5. Create integration tests
6. Update command documentation
