# Research Report: Core Workflow Phases and Execution Patterns

## Metadata
- **Topic**: Comparative analysis of workflow phases between /orchestrate and /supervise
- **Date**: 2025-10-23
- **Status**: Complete
- **Related Commands**: orchestrate.md, supervise.md

## Executive Summary

This report compares the core workflow phase structures and execution patterns between /orchestrate and /supervise commands. Key finding: **Phase numbering differs fundamentally** - /orchestrate uses named phases (Phase 0, Research Phase, Planning Phase, Phase 3-6) while /supervise uses sequential numeric phases (Phase 0-6). Both implement similar workflows but with different scope detection sophistication and execution enforcement patterns.

**Critical Gap**: /orchestrate lacks the systematic workflow scope detection function found in /supervise (lines 172-210), which provides automated phase skipping based on keyword pattern matching.

## Research Findings

### Phase Structure Overview

#### /orchestrate Phase Structure
Location: /home/benjamin/.config/.claude/commands/orchestrate.md

**Phase Naming Convention** (Mixed numeric and descriptive):
- **Phase 0**: Project Location Determination (line 390)
- **Research Phase**: Parallel research execution (line 596) - NOT numbered as "Phase 1"
- **Planning Phase**: Sequential planning synthesis (line 1408) - NOT numbered as "Phase 2"
- **Phase 3**: Implementation (Adaptive Execution) (line 2125)
- **Phase 4**: Comprehensive Testing (line 3070)
- **Phase 5**: Debugging Loop (Conditional) (line 2623)
- **Phase 6**: Documentation Phase (Sequential Execution) (line 3309)

**Architectural Approach**:
- Descriptive phase names emphasize execution pattern (Parallel, Sequential, Adaptive, Conditional)
- Research and Planning are conceptually "Phase 1" and "Phase 2" but not explicitly numbered
- Phases 3-6 use numeric labels consistently

#### /supervise Phase Structure
Location: /home/benjamin/.config/.claude/commands/supervise.md

**Phase Naming Convention** (Strict sequential numbering):
- **Phase 0**: Project Location and Path Pre-Calculation (line 343)
- **Phase 1**: Research (line 522)
- **Phase 2**: Planning (line 738)
- **Phase 3**: Implementation (line 931)
- **Phase 4**: Testing (line 1034)
- **Phase 5**: Debug (Conditional) (line 1130)
- **Phase 6**: Documentation (Conditional) (line 1324)

**Architectural Approach**:
- Consistent numeric sequencing (0-6)
- Clear mapping to workflow stages
- Simplified conditional marking (Phase 5 and 6 both conditional)

### Execution Patterns

#### /orchestrate Execution Model

**Sequential with Conditional Branching** (line 57):
- Execute all phases in "EXACT sequential order (Phases 0-6)"
- Conditional debugging: Only if tests fail (line 2627)
- Simplified workflow support mentioned but not systematically implemented (lines 349-352):
  - "Skip research if task is well-understood"
  - "Direct to implementation for simple fixes"
  - "Minimal documentation for internal changes"

**No Automated Scope Detection**:
- Manual assessment required ("you MUST determine which phases are needed", line 340)
- No code-based workflow pattern matching
- Relies on orchestrator judgment

**Enforcement Pattern**:
- Mandatory file creation verification at each phase (lines 66-73)
- Auto-retry mechanism for research phase (3 attempts, line 1084)
- Planning phase auto-retry (3 attempts, line 1521)
- No explicit fail-fast philosophy

#### /supervise Execution Model

**Scope-Driven Selective Execution** (lines 172-210):

**Automated Workflow Scope Detection Function**:
```bash
detect_workflow_scope() {
  # Pattern 1: research-only (phases 0,1)
  # Pattern 2: research-and-plan (phases 0,1,2)
  # Pattern 3: full-implementation (phases 0,1,2,3,4 + conditional 5,6)
  # Pattern 4: debug-only (phases 0,1,5)
}
```

**Phase Execution Mapping** (lines 371-388):
- research-only: Execute 0,1 only (skip 2,3,4,5,6)
- research-and-plan: Execute 0,1,2 only (skip 3,4,5,6)
- full-implementation: Execute 0,1,2,3,4 (5,6 conditional)
- debug-only: Execute 0,1,5 only (skip 2,3,4,6)

**Phase Execution Check Function** (lines 216-225):
```bash
should_run_phase() {
  local phase_num="$1"
  # Check if phase is in execution list
  if echo "$PHASES_TO_EXECUTE" | grep -q "$phase_num"; then
    return 0  # true: execute phase
  else
    return 1  # false: skip phase
  fi
}
```

**Enforcement Pattern**:
- Mandatory verification checkpoints (lines 231-275)
- **100% file creation rate on first attempt** (line 528, no retries)
- Fail-fast philosophy: "Zero Fallbacks: Single working path, fail-fast on errors" (line 163)
- Strong behavioral injection enforcement

### Conditional Logic

#### /orchestrate Conditional Logic

**Debugging Phase Conditional** (line 2625-2627):
- Entry condition: `$DEBUGGING_SKIPPED == false` from Phase 6 (Testing)
- Skip condition: `$TESTS_PASSING == true` (line 3274)
- Iteration limit: Max 3 debugging iterations (line 2150)

**Documentation Phase**: Not marked as conditional (line 3309)
- Always executed after implementation/debugging

**Research Phase Skipping** (mentioned but not implemented):
- Line 350: "Skip research if task is well-understood"
- Line 653: "Low complexity (score 0-3): 0-1 topics (skip research)"
- No systematic detection mechanism

#### /supervise Conditional Logic

**Phase 5 (Debug) Conditional** (line 1130):
- Entry condition: Test failures in Phase 4
- Skip message at phase start (lines 533-539)

**Phase 6 (Documentation) Conditional** (line 1324):
- Marked as conditional (not always executed)
- Conditional execution logic not detailed in read sections

**Systematic Phase Skipping** (lines 371-388):
- Automated based on workflow scope detection
- Four predefined patterns with explicit phase lists
- Function-based execution checks (`should_run_phase()`)

### Functionality Gaps

#### Gap 1: /orchestrate Lacks Automated Workflow Scope Detection

**Location**: /orchestrate.md line 340
**Current State**: "Based on the description, YOU MUST determine which phases are needed"
**Gap**: No systematic keyword-based pattern matching function like /supervise's `detect_workflow_scope()`

**Impact**:
- Inconsistent phase skipping decisions across orchestrator invocations
- Relies on orchestrator judgment rather than codified patterns
- Harder to predict which phases will execute for a given workflow description

**Evidence**:
- /supervise implements 4 workflow patterns with regex matching (lines 172-210)
- /orchestrate only provides conceptual guidance (lines 349-352)

#### Gap 2: /orchestrate Lacks Explicit Phase Execution Control Function

**Location**: /orchestrate.md (no equivalent to /supervise lines 216-225)
**Current State**: "Execute all workflow phases in EXACT sequential order"
**Gap**: No `should_run_phase()` function to programmatically check phase eligibility

**Impact**:
- Phase skipping must be manually implemented at each phase boundary
- No centralized enforcement of workflow scope decisions
- Harder to audit which phases were skipped and why

**Evidence**:
- /supervise uses `should_run_phase 1 || { echo "Skipping..."; exit 0; }` (line 533)
- /orchestrate relies on conditional checks within phase sections

#### Gap 3: /orchestrate Uses Retry Logic vs /supervise's Fail-Fast Approach

**Location**:
- /orchestrate.md lines 1084 (research retry), 1521 (planning retry)
- /supervise.md line 528 (100% file creation rate, no retries)

**Current State**: /orchestrate attempts auto-retry up to 3 times with "escalating template enforcement"
**Gap**: No fail-fast enforcement philosophy in /orchestrate

**Impact**:
- /orchestrate may mask underlying agent behavioral issues through retries
- /supervise forces strong behavioral injection from first invocation
- /orchestrate has longer recovery time for agent failures (3x attempts)

**Evidence**:
- /supervise: "100% file creation rate on first attempt (no retries)" (line 528)
- /supervise: "Zero Fallbacks: Single working path, fail-fast on errors" (line 163)
- /orchestrate: "Research phase automatically retries each topic up to 3 times" (line 1084)

## Detailed Analysis

### Phase Numbering Philosophy

**Why /orchestrate Uses Hybrid Naming**:
- Research and Planning emphasized as conceptually distinct from implementation phases
- Phase names communicate execution pattern (Parallel, Sequential, Adaptive)
- Implementation phases (3-6) use numbers for checkpoint consistency

**Why /supervise Uses Sequential Numbering**:
- Simplifies programmatic phase control (`should_run_phase 1`)
- Easier to map workflow scopes to phase lists ("0,1,2,3,4")
- Reduces cognitive overhead for tracking phase progression

**Recommendation**: /orchestrate should adopt sequential numbering (0-6) for consistency with programmatic phase control patterns.

### Workflow Scope Detection Patterns

**/supervise's Pattern Matching Strategy** (lines 172-210):

1. **Research-only**: `^research` without `plan|implement`
2. **Research-and-plan**: `(research|analyze|investigate).*(to |and |for ).*(plan|planning)`
3. **Full-implementation**: `implement|build|add.*(feature|functionality)|create.*(code|component)`
4. **Debug-only**: `^(fix|debug|troubleshoot).*(bug|issue|error|failure)`
5. **Fallback**: Conservative default to research-and-plan

**Strengths**:
- Codified patterns enable consistent scope detection
- Conservative fallback prevents under-scoping
- Explicit phase lists eliminate ambiguity

**Limitations**:
- Keyword matching may miss nuanced workflow descriptions
- No complexity-based phase adjustment (e.g., skip research for very simple tasks)
- Fixed patterns may not cover all workflow types

### File Creation Enforcement Philosophy

**/orchestrate Approach** (Auto-Retry with Degradation):
- Phase 1 (Research): Up to 3 retries per topic, continue with partial results (line 1084)
- Phase 2 (Planning): Up to 3 retries, workflow fails if all attempts fail (line 1521)
- Escalating enforcement: More strict prompts on each retry
- Graceful degradation: Accept partial research completion

**/supervise Approach** (Fail-Fast with Strong Injection):
- 100% file creation rate on first attempt (line 528)
- Workflow terminates on first agent failure (lines 244-261)
- Strong behavioral injection from initial invocation
- No retry mechanisms or fallbacks

**Trade-offs**:
- /orchestrate: More resilient to transient agent issues, but may mask problems
- /supervise: Exposes behavioral injection issues immediately, forces strong prompts

## Recommendations

### Recommendation 1: Adopt Systematic Workflow Scope Detection in /orchestrate

**Priority**: High
**Effort**: Medium (2-3 hours)

**Action**: Implement `detect_workflow_scope()` function in /orchestrate based on /supervise pattern (lines 172-210)

**Benefits**:
- Consistent phase skipping decisions across invocations
- Codified workflow patterns for audit and refinement
- Reduced cognitive load on orchestrator
- Enables dry-run mode to preview phase execution plan

**Implementation**:
```bash
# Add to /orchestrate.md before Phase 0
detect_workflow_scope() {
  local workflow_desc="$1"

  # Pattern matching logic from /supervise (lines 172-210)
  # Return: research-only | research-and-plan | full-implementation | debug-only
}

# Use in Phase 0 initialization
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
case "$WORKFLOW_SCOPE" in
  research-only) PHASES_TO_EXECUTE="0,research,planning" ;;
  research-and-plan) PHASES_TO_EXECUTE="0,research,planning" ;;
  full-implementation) PHASES_TO_EXECUTE="0,research,planning,3,4,5,6" ;;
  debug-only) PHASES_TO_EXECUTE="0,research,5" ;;
esac
```

**Reference**: /supervise.md lines 172-210 (scope detection), lines 371-388 (phase mapping)

### Recommendation 2: Implement `should_run_phase()` Function for Explicit Phase Control

**Priority**: High
**Effort**: Low (1 hour)

**Action**: Add phase execution control function to /orchestrate

**Benefits**:
- Centralized phase skipping logic
- Easier to audit phase execution decisions
- Consistent pattern across all phase boundaries
- Supports workflow scope-driven phase selection

**Implementation**:
```bash
# Add after detect_workflow_scope()
should_run_phase() {
  local phase_name="$1"  # e.g., "research", "planning", "3", "4"

  if echo "$PHASES_TO_EXECUTE" | grep -q "$phase_name"; then
    return 0  # Execute phase
  else
    echo "⏭️  Skipping $phase_name phase (workflow scope: $WORKFLOW_SCOPE)"
    return 1  # Skip phase
  fi
}

# Use at each phase boundary
should_run_phase "research" || {
  echo "Research phase skipped - proceeding to next phase"
  # Jump to next eligible phase
}
```

**Reference**: /supervise.md lines 216-225 (phase control function), lines 533-539 (usage example)

### Recommendation 3: Clarify Retry vs Fail-Fast Philosophy in Architecture Documentation

**Priority**: Medium
**Effort**: Low (documentation update)

**Action**: Document the architectural trade-offs between /orchestrate's retry approach and /supervise's fail-fast approach

**Benefits**:
- Users understand when to use each command
- Agent developers know which enforcement pattern to follow
- Future architectural decisions informed by documented trade-offs

**Implementation**:
Add section to /orchestrate.md and /supervise.md explaining:
- **When to use /orchestrate**: Complex workflows where agent retries add resilience
- **When to use /supervise**: Prototyping workflows where fast failure feedback is valuable
- **Agent prompt quality**: /supervise requires higher quality behavioral injection upfront

**Rationale**:
- Both approaches valid for different use cases
- /orchestrate optimized for production workflow completion (graceful degradation)
- /supervise optimized for development/testing (fast feedback on injection issues)

**Reference**:
- /orchestrate.md lines 1084, 1521 (retry logic)
- /supervise.md lines 163, 528 (fail-fast philosophy)

### Recommendation 4: Standardize Phase Numbering to 0-6 in /orchestrate

**Priority**: Low (cosmetic, but improves consistency)
**Effort**: Medium (requires updating multiple sections)

**Action**: Rename "Research Phase" → "Phase 1", "Planning Phase" → "Phase 2" throughout /orchestrate.md

**Benefits**:
- Consistent with /supervise numbering scheme
- Easier to implement programmatic phase control
- Simpler checkpoint variable naming (`completed_phases: [0,1,2,3]`)
- Aligns with phase execution lists in `should_run_phase()` pattern

**Implementation**:
- Update all section headers (lines 596, 1408, etc.)
- Update checkpoint save/restore logic
- Update phase completion messages
- Update TodoWrite phase tracking
- Keep descriptive subheaders (e.g., "Phase 1: Research (Parallel Execution)")

**Reference**: /supervise.md phase numbering convention (lines 343, 522, 738, 931, 1034, 1130, 1324)

## Related Reports

- [Overview Report](./OVERVIEW.md) - Complete comparison of /orchestrate vs /supervise across all dimensions
- [Agent Coordination Report](./002_agent_coordination_and_behavioral_injection.md) - Behavioral injection patterns and agent invocation
- [Error Handling Report](./003_error_handling_state_management_and_recovery.md) - Error recovery and checkpoint systems
- [Performance Features Report](./004_performance_features_and_user_facing_options.md) - User-facing features and optimization

## References

### Primary Sources

1. **/orchestrate.md** - `/home/benjamin/.config/.claude/commands/orchestrate.md`
   - Phase 0 definition: line 390
   - Research Phase: line 596
   - Planning Phase: line 1408
   - Phase 3 (Implementation): line 2125
   - Phase 4 (Testing): line 3070
   - Phase 5 (Debugging): line 2623
   - Phase 6 (Documentation): line 3309
   - Sequential execution requirement: line 57
   - Simplified workflow guidance: lines 349-352
   - Research retry logic: line 1084
   - Planning retry logic: line 1521

2. **/supervise.md** - `/home/benjamin/.config/.claude/commands/supervise.md`
   - Workflow scope detection function: lines 172-210
   - Phase execution control function: lines 216-225
   - Phase execution mapping: lines 371-388
   - Phase 0 definition: line 343
   - Phase 1 (Research): line 522
   - Phase 2 (Planning): line 738
   - Phase 3 (Implementation): line 931
   - Phase 4 (Testing): line 1034
   - Phase 5 (Debug): line 1130
   - Phase 6 (Documentation): line 1324
   - Fail-fast philosophy: line 163
   - 100% file creation rate: line 528
   - File verification checkpoint: lines 231-275

### Key Patterns Identified

1. **Workflow Scope Detection**: /supervise lines 172-210
2. **Phase Execution Control**: /supervise lines 216-225
3. **Auto-Retry with Degradation**: /orchestrate lines 1084, 1521
4. **Fail-Fast Verification**: /supervise lines 231-275
5. **Conditional Phase Entry**: /orchestrate line 2625, /supervise line 1130
