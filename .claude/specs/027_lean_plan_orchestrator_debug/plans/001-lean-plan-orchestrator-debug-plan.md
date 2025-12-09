# Implementation Plan: lean-plan Command Orchestrator Pattern Diagnosis

## Metadata

- **Date**: 2025-12-08
- **Feature**: Diagnose and fix /lean-plan command orchestrator-coordinator-specialist pattern implementation gap
- **Status**: [COMPLETE]
- **Estimated Hours**: 8-12 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [lean-plan Command Execution Analysis](../reports/001-lean-plan-execution-analysis.md)
  - [Orchestrator-Coordinator-Specialist Pattern Architecture](../reports/002-orchestrator-coordinator-specialist-pattern.md)
  - [Context Window Optimization in Hierarchical Agents](../reports/003-context-optimization-hierarchical-agents.md)
- **Complexity Score**: 85
- **Structure Level**: 0

## Overview

The /lean-plan command was designed to use the three-tier orchestrator-coordinator-specialist pattern for context optimization (95% reduction) and parallel execution (40-60% time savings). However, analysis of actual execution reveals the primary agent bypassed the hierarchical delegation structure and performed all work directly, resulting in high context usage and no parallel optimization benefits.

This plan addresses the root causes of the delegation bypass and implements enforcement mechanisms to ensure proper three-tier orchestration.

## Research Summary

Key findings from research reports:

**Root Cause** (Report 001): The command was invoked with an incorrect prompt format - the user provided a file path reference as a meta-instruction instead of a direct feature description. The primary agent interpreted this as permission to read files directly rather than delegating to the orchestration structure.

**Expected Architecture** (Report 002): The three-tier pattern requires:
1. Orchestrator Layer (slash command): State management, path pre-calculation, hard barrier validation
2. Coordinator Layer (research-coordinator): Parallel specialist invocation, metadata aggregation
3. Specialist Layer (research-specialist, lean-plan-architect): Deep domain work, comprehensive artifacts

**Context Optimization** (Report 003): Proper delegation achieves:
- Metadata-only passing: 95.6% context reduction (330 tokens vs 7,500 full reports)
- Hard barrier enforcement: 100% delegation success rate
- Iteration capacity: 10+ iterations (vs 3-4 before optimization)

**Actual Behavior**: The primary agent performed orchestrator responsibilities (reading files, analyzing content, creating plan) instead of delegating to the coordinator tier, defeating the purpose of the hierarchical architecture.

## Success Criteria

- [x] /lean-plan command enforces mandatory research-coordinator delegation via hard barriers
- [x] research-coordinator is invoked for ALL research phases (no bypass scenarios)
- [x] lean-plan-architect receives metadata-only context (110 tokens per report, not full content)
- [x] Command validation detects and rejects delegation bypass attempts
- [x] Integration tests verify hard barrier enforcement across all invocation paths
- [x] Documentation clearly explains when to use --file flag vs direct description
- [x] Context reduction metrics meet 95%+ target for multi-topic research scenarios

## Technical Design

### Architecture Issue

The current /lean-plan.md command structure lacks explicit hard barrier enforcement between blocks. The command assumes the primary agent will respect the orchestrator-coordinator-specialist pattern, but without structural constraints (fail-fast validation), the agent can bypass delegation.

**Current Vulnerable Pattern**:
```markdown
Block 1: Setup
- Initialize state
- Calculate paths

Block 2: Execute
- "Invoke research-coordinator" (suggestion, not enforcement)
- Primary agent can choose to read files directly instead

Block 3: Verify
- Validate results
- If research-coordinator not invoked, no artifacts to validate → silent failure
```

**Required Hard Barrier Pattern**:
```markdown
Block 1a: Setup
- State transition (fail-fast)
- Path pre-calculation
- Variable persistence

Block 1b: Execute [HARD BARRIER]
- MANDATORY Task invocation (no alternative code path)
- Cannot proceed to Block 1c without Task return

Block 1c: Verify
- Artifact existence check (exit 1 if missing)
- Fail-fast on missing coordinator outputs
- Error logging with recovery hints
```

### Root Cause Analysis

**Finding 1: User Input Validation Gap**
- The command accepts meta-instructions ("Use file.md to create a plan...") as feature descriptions
- No validation to detect file path patterns without --file flag
- No warning when user provides indirect instructions vs direct formalization goals

**Finding 2: Missing Hard Barrier Enforcement**
- No structural separation between Setup → Execute → Verify blocks
- Primary agent can skip coordinator delegation and perform work inline
- Verification blocks don't fail-fast when coordinator artifacts missing

**Finding 3: Insufficient Tool Access Restrictions**
- Primary agent has access to Read, Write, Edit tools
- Can perform specialist work (reading research, creating plans) directly
- No enforcement that these tools should only be used by specialist tier

**Finding 4: Ambiguous Prompting**
- Command prompts use "should" and "recommended" language for delegation
- Not explicit that delegation is MANDATORY and bypass is prohibited
- Missing enforcement language like "CRITICAL BARRIER" and "ABSOLUTE REQUIREMENT"

### Proposed Solutions

**Solution 1: Input Validation Enhancement**
Add meta-instruction detection to Block 1a (after argument capture):

```bash
# Detect meta-instruction patterns suggesting user confusion
if [[ "$FEATURE_DESCRIPTION" =~ [Uu]se.*to.*(create|make|generate) ]]; then
  echo "WARNING: Feature description appears to be a meta-instruction" >&2
  echo "Did you mean to use --file flag instead?" >&2
  echo "Example: /lean-plan --file /path/to/requirements.md" >&2
  echo "" >&2
  echo "Proceeding with provided description, but delegation may be affected." >&2
  log_command_error "validation_error" \
    "Meta-instruction pattern detected in feature description" \
    "User provided: $FEATURE_DESCRIPTION"
fi
```

**Solution 2: Hard Barrier Structure Enforcement**
Refactor command to use explicit 3-block structure per orchestrator-coordinator-specialist pattern:

```bash
# Block 1d-calc: Pre-calculate coordinator inputs [SETUP]
# Block 1e-exec: Invoke research-coordinator [HARD BARRIER]
# Block 1f: Validate coordinator outputs [VERIFY]
```

Each VERIFY block must use fail-fast validation:
```bash
if [ ! -f "$EXPECTED_ARTIFACT" ]; then
  echo "ERROR: HARD BARRIER FAILED - Coordinator did not create expected artifact" >&2
  echo "Expected: $EXPECTED_ARTIFACT" >&2
  log_command_error "agent_error" \
    "research-coordinator did not create required artifacts" \
    "Missing: $EXPECTED_ARTIFACT"
  exit 1
fi
```

**Solution 3: Coordinator Contract Validation**
After research-coordinator returns, validate the coordinator created exactly the artifacts specified in its input contract:

```bash
# Validate all pre-calculated report paths exist
SUCCESSFUL_REPORTS=0
for REPORT_PATH in "${REPORT_PATHS[@]}"; do
  if [ -f "$REPORT_PATH" ]; then
    SUCCESSFUL_REPORTS=$((SUCCESSFUL_REPORTS + 1))
  else
    echo "ERROR: Missing report: $REPORT_PATH" >&2
  fi
done

# Fail if <50% success (partial success threshold)
SUCCESS_PERCENTAGE=$((SUCCESSFUL_REPORTS * 100 / TOTAL_REPORTS))
if [ $SUCCESS_PERCENTAGE -lt 50 ]; then
  echo "ERROR: Research validation failed - <50% success rate" >&2
  log_command_error "validation_error" \
    "research-coordinator partial success below threshold" \
    "Only $SUCCESSFUL_REPORTS/$TOTAL_REPORTS reports created"
  exit 1
fi
```

**Solution 4: Documentation and User Guidance**
- Add clear --file flag examples to command argument-hint
- Update error messages to suggest --file flag when description is empty
- Create decision tree documentation for when to use direct description vs --file
- Add pre-execution warnings for ambiguous inputs

## Implementation Phases

### Phase 1: Diagnosis and Root Cause Validation [COMPLETE]
dependencies: []

**Objective**: Verify the root cause analysis by examining actual /lean-plan.md command structure and identifying specific locations where hard barriers are missing or weak.

**Complexity**: Low

**Tasks**:
- [x] Read /lean-plan.md command definition and map block structure (file: /home/benjamin/.config/.claude/commands/lean-plan.md)
- [x] Identify all locations where research-coordinator or lean-plan-architect should be invoked
- [x] Check for hard barrier markers ([HARD BARRIER], [CRITICAL BARRIER]) in Execute blocks
- [x] Verify fail-fast validation exists in Verify blocks (grep for "exit 1" after artifact checks)
- [x] Document current delegation flow vs expected orchestrator-coordinator-specialist pattern
- [x] Create diagnostic checklist of all missing hard barrier components

**Testing**:
```bash
# Verify lean-plan.md structure
grep -n "Block.*exec" /home/benjamin/.config/.claude/commands/lean-plan.md

# Check for hard barrier markers
grep -n "HARD BARRIER\|CRITICAL BARRIER" /home/benjamin/.config/.claude/commands/lean-plan.md

# Verify fail-fast validation
grep -A5 "if.*-f.*REPORT_PATH" /home/benjamin/.config/.claude/commands/lean-plan.md | grep "exit 1"
```

**Expected Duration**: 1 hour

### Phase 2: Input Validation Enhancement [COMPLETE]
dependencies: [1]

**Objective**: Add meta-instruction detection and --file flag promotion to prevent user input errors that confuse the orchestrator.

**Complexity**: Low

**Tasks**:
- [x] Add meta-instruction pattern detection after argument capture in Block 1a (file: /home/benjamin/.config/.claude/commands/lean-plan.md, after line ~53)
- [x] Implement warning message suggesting --file flag usage
- [x] Log meta-instruction detection as validation_error for queryability
- [x] Update argument-hint to clarify direct description vs --file usage
- [x] Enhance empty description error message to suggest --file flag
- [x] Test with various meta-instruction patterns ("Use X to create...", "Read Y and generate...")

**Testing**:
```bash
# Test meta-instruction detection
/lean-plan "Use /path/to/report.md to create a plan for..."
# Expected: WARNING message suggesting --file flag, then proceeds

# Test empty description
/lean-plan ""
# Expected: ERROR with --file flag suggestion in help text

# Test valid direct description
/lean-plan "formalize group homomorphism properties"
# Expected: No warnings, normal execution
```

**Expected Duration**: 1.5 hours

### Phase 3: Hard Barrier Structure Implementation [COMPLETE]
dependencies: [1]

**Objective**: Refactor /lean-plan.md command to enforce mandatory delegation through structural hard barriers following the Setup → Execute → Verify pattern.

**Complexity**: High

**Tasks**:
- [x] Identify all delegation points requiring hard barriers (research-coordinator, lean-plan-architect)
- [x] Refactor Block 1d-1f (research phase) to explicit Setup → Execute → Verify structure
- [x] Add [HARD BARRIER] markers to all Execute blocks with coordinator/architect invocations
- [x] Implement fail-fast validation in all Verify blocks (exit 1 when artifacts missing)
- [x] Add error logging with recovery hints for hard barrier failures
- [x] Update state transitions to gate progression (RESEARCH → PLAN only after reports validated)
- [x] Verify bash blocks cannot be skipped between Task invocations
- [x] Test that delegation bypass attempts result in immediate failure

**Testing**:
```bash
# Test hard barrier enforcement
# Manually trigger coordinator bypass scenario and verify fail-fast behavior

# Test state transition gating
# Verify RESEARCH → PLAN transition only occurs after report validation passes

# Test error logging
/errors --command /lean-plan --type agent_error --limit 5
# Expected: Clear error messages with recovery hints
```

**Expected Duration**: 4 hours

### Phase 4: Coordinator Contract Validation [COMPLETE]
dependencies: [3]

**Objective**: Implement comprehensive validation that research-coordinator created exactly the artifacts specified in its input contract, with partial success mode (≥50% threshold).

**Complexity**: Medium

**Tasks**:
- [x] Implement artifact existence validation loop for all REPORT_PATHS[] (file: /home/benjamin/.config/.claude/commands/lean-plan.md, Block 1f)
- [x] Add success percentage calculation (SUCCESSFUL_REPORTS * 100 / TOTAL_REPORTS)
- [x] Implement ≥50% partial success threshold with fail-fast for <50%
- [x] Add warning output for 50-99% success (partial completion)
- [x] Log validation failures as agent_error with missing artifact details
- [x] Implement metadata extraction only after validation passes
- [x] Test partial success scenarios (1/3, 2/3, 3/3 reports created)

**Testing**:
```bash
# Test 100% success scenario
# All reports created → validation passes silently

# Test 66% success scenario (2/3 reports)
# Validation passes with WARNING about partial success

# Test 33% success scenario (1/3 reports)
# Validation fails with ERROR (below 50% threshold)

# Verify error logging
/errors --command /lean-plan --type validation_error --since 1h
```

**Expected Duration**: 2 hours

### Phase 5: Documentation and User Guidance [COMPLETE]
dependencies: [2]

**Objective**: Create comprehensive documentation explaining when to use --file flag vs direct description, with decision trees and examples.

**Complexity**: Low

**Tasks**:
- [x] Create decision tree for lean workflow selection (file: /home/benjamin/.config/.claude/docs/reference/decision-trees/lean-workflow-selection.md)
- [x] Add clear --file flag examples to lean-plan-command-guide.md (create if missing)
- [x] Update command reference with correct usage patterns and anti-patterns
- [x] Add inline help examples to argument-hint frontmatter
- [x] Document meta-instruction anti-pattern in troubleshooting guide
- [x] Create example prompts showing correct vs incorrect invocations

**Testing**:
```bash
# Verify documentation exists and is complete
test -f /home/benjamin/.config/.claude/docs/reference/decision-trees/lean-workflow-selection.md
test -f /home/benjamin/.config/.claude/docs/guides/commands/lean-plan-command-guide.md

# Verify decision tree covers all usage scenarios
grep -q "Direct Description" /home/benjamin/.config/.claude/docs/reference/decision-trees/lean-workflow-selection.md
grep -q "--file flag" /home/benjamin/.config/.claude/docs/reference/decision-trees/lean-workflow-selection.md
```

**Expected Duration**: 1.5 hours

### Phase 6: Integration Testing and Validation [COMPLETE]
dependencies: [3, 4]

**Objective**: Create comprehensive integration tests validating hard barrier enforcement, delegation success, and context reduction metrics across all invocation paths.

**Complexity**: Medium

**Tasks**:
- [x] Create test suite for /lean-plan hard barrier enforcement (file: /home/benjamin/.config/.claude/tests/integration/test_lean_plan_hard_barriers.sh)
- [x] Test Case 1: Verify research-coordinator is always invoked (no bypass)
- [x] Test Case 2: Verify fail-fast when coordinator artifacts missing
- [x] Test Case 3: Verify partial success mode (≥50% threshold)
- [x] Test Case 4: Verify metadata extraction accuracy (110 tokens per report)
- [x] Test Case 5: Verify context reduction metrics (95%+ for 3+ topics)
- [x] Test Case 6: Verify meta-instruction detection warnings
- [x] Run all existing lean-plan integration tests to ensure no regressions
- [x] Document test coverage and results

**Testing**:
```bash
# Run new integration tests
bash /home/benjamin/.config/.claude/tests/integration/test_lean_plan_hard_barriers.sh

# Run existing lean-plan tests
bash /home/benjamin/.config/.claude/tests/integration/test_lean_plan_coordinator.sh

# Verify all tests pass (100% pass rate)
echo "Expected: All tests PASS, 0 failures"
```

**Expected Duration**: 3 hours

### Phase 7: Verification and Documentation Update [COMPLETE]
dependencies: [5, 6]

**Objective**: Verify all fixes are working correctly in production scenarios, update relevant documentation, and create before/after metrics comparison.

**Complexity**: Low

**Tasks**:
- [x] Test /lean-plan with various real-world formalization descriptions
- [x] Verify context reduction metrics match 95%+ target for multi-topic research
- [x] Confirm iteration capacity increased to 10+ iterations (vs 3-4 before)
- [x] Update hierarchical-agents-examples.md with lean-plan delegation enforcement example
- [x] Update lean-plan-command-guide.md with hard barrier pattern explanation
- [x] Document before/after metrics (context reduction, iteration capacity, delegation success rate)
- [x] Add troubleshooting section for common delegation bypass scenarios
- [x] Update CLAUDE.md hierarchical_agent_architecture section with lean-plan as Example 9

**Testing**:
```bash
# Test real-world usage scenarios
/lean-plan "formalize soundness theorem for modal logic K4"
/lean-plan --file /path/to/complex-formalization-requirements.md

# Verify metrics
# Before: ~60% context usage at iteration 4, delegation bypass 40-60%
# After: ~30% context usage at iteration 10+, delegation bypass 0%

# Verify documentation updates
grep -q "lean-plan hard barrier enforcement" /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md
```

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Testing
- Input validation logic: meta-instruction detection, --file flag parsing
- Hard barrier validation functions: artifact existence checks, success percentage calculation
- Metadata extraction functions: title, findings count, recommendations count
- Error logging integration: validation_error, agent_error logging

### Integration Testing
- Hard barrier enforcement: Verify delegation bypass attempts fail immediately
- Coordinator contract validation: Test partial success scenarios (33%, 50%, 66%, 100%)
- Context reduction metrics: Measure actual token usage (target: 95%+ reduction)
- State transition gating: Verify RESEARCH → PLAN only after validation passes

### End-to-End Testing
- Real-world formalization descriptions: "formalize group homomorphism properties"
- Complex requirements via --file flag: Load formalization requirements from file
- Error recovery scenarios: Invalid inputs, coordinator failures, missing artifacts
- Performance benchmarks: Iteration capacity, parallel execution time savings

### Validation Criteria
All integration tests must pass (100% pass rate) before Phase 7 completion. Context reduction must meet 95%+ target. Delegation bypass rate must be 0% (hard barrier enforcement).

## Documentation Requirements

### New Documentation
- `/home/benjamin/.config/.claude/docs/reference/decision-trees/lean-workflow-selection.md` - Decision tree for when to use direct description vs --file flag
- `/home/benjamin/.config/.claude/docs/guides/commands/lean-plan-command-guide.md` - Complete command guide with usage patterns and troubleshooting
- `/home/benjamin/.config/.claude/tests/integration/test_lean_plan_hard_barriers.sh` - Integration test suite for hard barrier enforcement

### Updated Documentation
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md` - Add Example 9: lean-plan hard barrier enforcement pattern
- `/home/benjamin/.config/.claude/commands/lean-plan.md` - Update with hard barrier structure and enhanced input validation
- `/home/benjamin/.config/CLAUDE.md` - Update hierarchical_agent_architecture section with lean-plan example

### Documentation Standards
- Follow clean-break development standard (no historical commentary)
- Use Unicode box-drawing for diagrams
- Include code examples with syntax highlighting
- Maintain bidirectional links between related documents

## Dependencies

### Internal Dependencies
- `/home/benjamin/.config/.claude/lib/core/error-handling.sh` - Error logging integration
- `/home/benjamin/.config/.claude/lib/workflow/validation-utils.sh` - Validation functions
- `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh` - State transition management
- `/home/benjamin/.config/.claude/agents/research-coordinator.md` - Coordinator behavioral definition
- `/home/benjamin/.config/.claude/agents/lean-plan-architect.md` - Specialist behavioral definition

### External Dependencies
None - this is an internal .claude/ system improvement

### Prerequisite Knowledge
- Three-tier orchestrator-coordinator-specialist pattern architecture
- Hard barrier pattern (Setup → Execute → Verify)
- Metadata-only passing for context reduction
- Error return protocol and centralized logging
