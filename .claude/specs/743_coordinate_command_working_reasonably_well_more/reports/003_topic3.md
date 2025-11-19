# Dedicated Orchestrator Plan Analysis

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: Dedicated Orchestrator Plan Analysis
- **Report Type**: plan analysis
- **Complexity Level**: 3

## Executive Summary

The dedicated orchestrator commands plan proposes extracting 5 workflow types from /coordinate into standalone commands (/research, /research-plan, /research-revise, /build, /fix) to eliminate 5-10s classification latency while preserving all 6 essential features through a template-based architecture with shared state machine libraries. The plan demonstrates solid technical design with comprehensive feature preservation strategy and phased implementation, though it contains gaps in argument handling patterns, error recovery mechanisms, and template versioning strategy.

## Findings

### 1. Current Plan Approach: Template-Based Orchestrator Extraction

**Location**: `/home/benjamin/.config/.claude/specs/743_coordinate_command_working_reasonably_well_more/plans/001_dedicated_orchestrator_commands.md:66-106`

The plan uses a **template-based architecture** with shared state machine libraries to extract 5 workflow types from /coordinate into dedicated commands:

**Core Strategy**:
- Single template file (`.claude/templates/state-based-orchestrator-template.md`, 600-800 lines) with substitution markers
- Substitution markers: `{{WORKFLOW_TYPE}}`, `{{TERMINAL_STATE}}`, `{{COMMAND_NAME}}`, `{{DEFAULT_COMPLEXITY}}`
- Shared libraries preserved from /coordinate: workflow-state-machine.sh, state-persistence.sh, dependency-analyzer.sh, metadata-extraction.sh, verification-helpers.sh, error-handling.sh
- Template instantiation per command with workflow-specific phase sections (conditional: research, planning, implementation, testing, debug, documentation)

**Hardcoded Workflow Types** (Lines 110-131):
- `/research`: workflow_type="research-only", terminal_state="research" (after research phase)
- `/research-plan`: workflow_type="research-and-plan", terminal_state="plan" (after planning phase)
- `/research-revise`: workflow_type="research-and-revise", terminal_state="plan" (revision mode)
- `/build`: workflow_type="full-implementation", terminal_state="complete" (takes existing plan path + optional start phase)
- `/fix`: workflow_type="debug-only", terminal_state="debug" (after debug phase)

**Latency Reduction Mechanism**:
- Skips workflow-classifier agent invocation (Phase 0.1 in /coordinate, lines 191-318)
- Eliminates 5-10s LLM-based classification delay
- Direct sm_init() invocation with hardcoded workflow_type parameter

### 2. Design Decisions and Rationale

**Decision 1: Library Reuse Over Reimplementation** (Lines 47-56)

**Rationale from Research**:
- Feature preservation patterns report (003_feature_preservation_patterns.md:12-13) identifies 6 essential features as integrated system
- State machine library provides 48.9% code reduction (coordinate.md:1,084→800 lines, Lines 60-66 of feature preservation report)
- Stable library APIs prevent feature loss during template customization

**Implementation**:
- All 6 libraries sourced in template initialization section (lines 100-117 of coordinate.md pattern)
- Library sourcing order preserved: workflow-state-machine.sh → state-persistence.sh → error-handling.sh → verification-helpers.sh (critical ordering dependency per coordinate.md:99-138)

**Decision 2: Two-Step Initialization Pattern** (Lines 87-106, 136-143)

**Rationale**:
- Avoids positional parameter issues in bash subprocess boundaries
- Part 1: Capture workflow description to temp file (coordinate.md:18-43 pattern)
- Part 2: Main logic reads from file and sources libraries (coordinate.md:47-186 pattern)

**Critical Success Factor**: Temp file path must use timestamp-based filename for concurrent execution safety (Spec 678 Phase 5, coordinate.md:38-42)

**Decision 3: Hierarchical Supervision Threshold** (Lines 145-151, 206-210)

**Configuration**:
- Default complexity per command: /research=2, /research-plan=3, /research-revise=2, /fix=2
- Hierarchical supervision enabled at complexity ≥4 (architecture report:30, feature preservation report:68-96)
- Flat coordination for complexity <4

**Performance Impact**:
- Hierarchical: 95.6% context reduction (10,000 tokens → 440 tokens per feature preservation report:86-88)
- Flat: No overhead for simple research workflows

**Decision 4: Phase Conditional Execution** (Lines 162-192)

**Implementation Pattern**:
```bash
case "$COMMAND_NAME" in
  research) sm_transition "$STATE_COMPLETE"; exit 0 ;;
  research-plan|research-revise) sm_transition "$STATE_PLAN" ;;
  build) sm_transition "$STATE_IMPLEMENT" ;;
  fix) sm_transition "$STATE_DEBUG" ;;
esac
```

**Workflow-Specific Phase Sequences** (Lines 165-170):
- /research: research → complete (skip planning, implementation, testing, debug, documentation)
- /research-plan: research → plan → complete (skip implementation, testing, debug, documentation)
- /build: implement → test → debug/document → complete (skip research, planning)
- /fix: research → plan (debug strategy) → debug → complete (skip implementation, testing, documentation)

**Terminal State Mapping** (distinct_workflows_in_coordinate.md:72-150):
- research-only → complete after research (coordinate.md:1164-1171)
- research-and-plan → complete after plan (coordinate.md:1644-1652)
- build → complete after documentation or debug (coordinate.md:2275, 2451)
- debug-only → complete after debug (coordinate.md:2275)

### 3. Identified Gaps and Improvement Opportunities

**Gap 1: /build Command Argument Handling Incomplete** (Lines 377-393)

**Issue**:
- Plan specifies "/build takes existing plan path (required) and optional start phase number" (Line 378)
- Argument parsing task at Line 378: "Add argument parsing for plan path (required) and optional start phase number"
- No specification of argument format (positional vs flags: `/build <plan-path> <phase>` vs `/build --plan <path> --phase <num>`)

**Comparison with /implement Command** (/home/benjamin/.config/.claude/commands/implement.md:3, 56-75):
- /implement uses: `[plan-file] [starting-phase] [--report-scope-drift "<description>"] [--force-replan] [--create-pr] [--dashboard] [--dry-run]`
- Positional arguments for plan file and phase, flags for optional features
- Phase defaults to 1 if not provided (Line 58)
- Auto-resume logic finds most recent incomplete plan if no arguments (Lines 84-99)

**Recommendation**: Adopt /implement argument pattern for /build to maintain consistency and enable resume functionality.

**Gap 2: Error Recovery Mechanisms Not Specified** (Lines 219-225)

**Current Plan Statement** (Lines 222-225):
```
6. Verification Checkpoints (fail-fast error handling):
   - Mandatory verification after each agent invocation
   - File existence checks with diagnostic messages
   - No retry logic (fail-fast philosophy)
```

**Issue**:
- "No retry logic" contradicts Phase 4 task at Line 387: "Add debug retry logic with max attempts limit"
- /coordinate uses fail-fast validation (coordinate.md:140-175: verification checkpoints with handle_state_error)
- No specification of retry policy for /build debug phase vs fail-fast for other phases

**Current /coordinate Debug Retry Pattern** (coordinate.md:2053-2061):
```bash
if [ "$TEST_EXIT_CODE" -eq 0 ]; then
  sm_transition "$STATE_DOCUMENT"
else
  sm_transition "$STATE_DEBUG"  # Retry testing after debug
fi
```

**Gap**: Plan doesn't specify max retry limit, loop prevention, or escalation criteria for debug phase.

**Gap 3: Template Versioning Strategy Missing** (Lines 652-656)

**Risk Identified** (Lines 652-656):
- "Risk 1: Template Maintenance Burden"
- "Mitigation: Version template with changelog, provide migration guides"

**Issue**:
- No specification of version numbering scheme
- No changelog format defined
- No migration path for commands created from older template versions
- No compatibility matrix (template version → library version dependencies)

**Comparison with Library Compatibility**:
- Plan includes "verify-state-machine-compatibility.sh" (Line 244) for library verification
- No equivalent template versioning verification script specified

**Gap 4: Testing Coverage Incomplete for Edge Cases** (Lines 247-255, 291-305, 337-351, 394-414)

**Current Test Specifications**:
- Template validation: Substitution markers present (grep -c pattern, Lines 252-254)
- /research: Command execution, report creation, no plan file (Lines 293-303)
- /research-plan: New plan created (Line 341)
- /research-revise: Backup created, revised plan exists (Lines 346-347)
- /build: Phases executed, state transitions (Lines 399-413)

**Missing Edge Cases**:
1. Concurrent execution: Multiple instances of same command running simultaneously (file path conflicts)
2. Invalid plan path: /build with non-existent plan file (error handling validation)
3. Mid-phase interruption: Resume from interrupted state (state machine recovery)
4. Library incompatibility: Template created with older library version (compatibility validation)
5. Malformed workflow description: Research complexity extraction failure (input validation)

**Comparison with /coordinate Testing**:
- /coordinate has comprehensive state persistence testing (state-based-orchestration-overview.md:1019-1028)
- Feature preservation validation (delegation rate >90%, context usage <300 tokens)

**Gap 5: Research Complexity Override Not Implemented** (Lines 146-160)

**Plan States** (Lines 146-151):
- "/report: Default complexity 2 (extensible to 1-4 via flags)"
- Other commands have hardcoded default complexity

**Future Enhancement Section** (Lines 154-160):
```bash
# Phase 0: Parse optional --complexity flag
RESEARCH_COMPLEXITY=2  # Default
if [[ "$WORKFLOW_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
fi
```

**Issue**:
- Marked as "future enhancement" but not included in any phase tasks
- No decision on whether to implement in Phase 1 (template) or defer to later iteration
- No specification of flag format: `--complexity 3` vs `--complexity=3` vs `-c 3`

### 4. Feature Preservation Strategy Analysis

**Strengths**:

1. **Complete Feature Coverage** (Lines 47-56, 194-225):
   - All 6 essential features explicitly addressed
   - Library reuse strategy preserves implementation details
   - Verification checkpoints mandate file creation validation

2. **Validation Phase** (Phase 6, Lines 472-521):
   - Dedicated validation script for feature preservation (.claude/tests/validate_feature_preservation.sh)
   - Measurable criteria: delegation rate >90%, context usage <300 tokens, file creation 100%
   - Run against all 5 new commands before completion

3. **Documented Success Criteria** (Lines 57-64):
   - Workflow classification removed (5-10s latency reduction)
   - All 6 features preserved
   - State machine library integration maintained
   - Test suite validation thresholds specified

**Weaknesses**:

1. **No Feature Degradation Monitoring**:
   - Validation script creates point-in-time snapshot
   - No CI/CD integration specified for continuous validation
   - No regression testing between template versions

2. **No Feature Tradeoff Analysis**:
   - Plan assumes all 6 features required for all commands
   - /research (research-only) may not need wave-based parallel execution
   - /fix (debug-only) may not need hierarchical supervision for complexity 2

3. **No Performance Baseline**:
   - Plan targets 5-10s latency reduction but doesn't specify measurement methodology
   - No before/after performance comparison planned
   - No latency budget per phase

## Recommendations

### Recommendation 1: Standardize /build Argument Pattern with /implement

**Rationale**: /implement command has proven argument handling pattern (auto-resume, optional phase, flags for features) that should be replicated in /build for consistency and user experience.

**Implementation**:
- Adopt argument signature: `/build [plan-file] [starting-phase] [--dashboard] [--dry-run]`
- Add auto-resume logic: Find most recent incomplete plan if no arguments provided
- Add phase validation: Verify starting phase exists in plan before execution
- Add resume safety checks: Verify checkpoint integrity before resuming

**Phase**: Add to Phase 4 (Build Command) tasks before Line 378

**Example**:
```bash
# Parse arguments
PLAN_FILE="${1:-}"
STARTING_PHASE="${2:-1}"
DASHBOARD_FLAG="false"
DRY_RUN="false"

shift 2 2>/dev/null || shift $# 2>/dev/null
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dashboard) DASHBOARD_FLAG="true"; shift ;;
    --dry-run) DRY_RUN="true"; shift ;;
    *) shift ;;
  esac
done

# Auto-resume if no plan file provided
if [ -z "$PLAN_FILE" ]; then
  PLAN_FILE=$(find .claude/specs/*/plans/*.md -type f -exec ls -t {} + 2>/dev/null | head -1)
fi
```

### Recommendation 2: Clarify Error Recovery Policy with Retry Limits

**Rationale**: Plan contradicts itself on retry logic (fail-fast vs debug retry). Specify explicit policy per phase type.

**Implementation**:
- **Research Phase**: Fail-fast (no retries) - agent file creation failures indicate behavioral file bugs
- **Planning Phase**: Fail-fast (no retries) - plan-architect behavioral issues require manual intervention
- **Implementation Phase**: Fail-fast (no retries) - implementation errors should trigger debug phase
- **Testing Phase**: Fail-fast (no retries) - test failures trigger debug phase
- **Debug Phase**: Limited retry (max 2 attempts) - prevent infinite debug loops

**Phase**: Add error recovery specification to Phase 4 (Build Command) and Phase 5 (Debug Command)

**Example for Debug Phase**:
```bash
DEBUG_ATTEMPTS=0
MAX_DEBUG_ATTEMPTS=2

while [ $DEBUG_ATTEMPTS -lt $MAX_DEBUG_ATTEMPTS ]; do
  # Debug phase execution
  sm_transition "$STATE_TEST"  # Re-run tests

  if [ "$TEST_EXIT_CODE" -eq 0 ]; then
    sm_transition "$STATE_DOCUMENT"
    break
  else
    DEBUG_ATTEMPTS=$((DEBUG_ATTEMPTS + 1))
    if [ $DEBUG_ATTEMPTS -ge $MAX_DEBUG_ATTEMPTS ]; then
      echo "ERROR: Debug phase failed after $MAX_DEBUG_ATTEMPTS attempts"
      echo "Manual intervention required"
      sm_transition "$STATE_COMPLETE"
      exit 1
    fi
  fi
done
```

### Recommendation 3: Add Template Versioning and Compatibility Verification

**Rationale**: Template maintenance burden (identified risk) requires versioning strategy for long-term sustainability.

**Implementation**:
1. **Version Numbering**: Semantic versioning (MAJOR.MINOR.PATCH) in template header
   - MAJOR: Breaking changes (incompatible with existing libraries)
   - MINOR: New features (backward compatible)
   - PATCH: Bug fixes (no API changes)

2. **Changelog Format**: Keep CHANGELOG.md in `.claude/templates/` directory
   - Document substitution marker changes
   - Document library version dependencies
   - Document migration steps per version

3. **Compatibility Matrix**: Document in template header
   ```markdown
   Template Version: 1.0.0
   Compatible with:
   - workflow-state-machine.sh: >=2.0.0, <3.0.0
   - state-persistence.sh: >=1.5.0, <2.0.0
   - dependency-analyzer.sh: >=1.0.0, <2.0.0
   ```

4. **Verification Script**: Extend verify-state-machine-compatibility.sh
   ```bash
   verify_template_version() {
     local template_file="$1"
     local template_version=$(grep "Template Version:" "$template_file" | cut -d: -f2 | xargs)
     local lib_version=$(grep "VERSION=" "$LIB_DIR/workflow-state-machine.sh" | cut -d= -f2)
     # Semver compatibility check
   }
   ```

**Phase**: Add to Phase 1 (Foundation) tasks after Line 245

### Recommendation 4: Expand Testing Coverage for Edge Cases and Failure Modes

**Rationale**: Current test specifications focus on happy path. Production readiness requires edge case validation.

**Implementation**: Add test cases to Phase 6 (Feature Preservation Validation)

1. **Concurrent Execution Test**:
   ```bash
   # Start two /research commands simultaneously
   /research "topic A" &
   /research "topic B" &
   wait
   # Verify: No file path conflicts, both complete successfully
   ```

2. **Invalid Input Test**:
   ```bash
   # Test /build with non-existent plan
   /build /nonexistent/plan.md 2>&1 | grep "ERROR: Plan file not found"
   # Verify: Fail-fast with diagnostic message
   ```

3. **Mid-Phase Interruption Test**:
   ```bash
   # Start /build, kill mid-execution
   /build plan.md &
   PID=$!
   sleep 5
   kill -TERM $PID
   # Verify: State file saved, resume possible
   /build plan.md  # Should resume from checkpoint
   ```

4. **Library Version Incompatibility Test**:
   ```bash
   # Temporarily replace library with incompatible version
   mv workflow-state-machine.sh workflow-state-machine.sh.backup
   echo "VERSION=0.5.0" > workflow-state-machine.sh
   /research "test" 2>&1 | grep "ERROR: Incompatible library version"
   # Verify: Fail-fast with version mismatch diagnostic
   ```

5. **Malformed Workflow Description Test**:
   ```bash
   # Test complexity extraction with malformed input
   /research ""  # Empty description
   # Verify: Default complexity applied or fail-fast with validation error
   ```

**Phase**: Add to Phase 6 tasks after Line 489

### Recommendation 5: Implement Research Complexity Override in Phase 1

**Rationale**: Marked as "future enhancement" but provides immediate value for power users. Include in MVP to avoid breaking changes later.

**Implementation**:
1. Add complexity flag parsing to template (Phase 1)
2. Support both workflow description embedding and explicit flag:
   - Embedded: `/research "auth patterns --complexity 4"`
   - Explicit flag: `/research --complexity 4 "auth patterns"`

3. Validation: Reject invalid complexity values (not in 1-4 range)
4. Default behavior: Use command-specific defaults if not specified

**Example**:
```bash
# Part 1: Parse complexity from flags or workflow description
RESEARCH_COMPLEXITY="${DEFAULT_COMPLEXITY}"  # Command-specific default

# Check for explicit --complexity flag
if [[ "$WORKFLOW_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  # Strip flag from workflow description
  WORKFLOW_DESCRIPTION=$(echo "$WORKFLOW_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//')
fi

# Validate complexity
if ! echo "$RESEARCH_COMPLEXITY" | grep -Eq "^[1-4]$"; then
  handle_state_error "Invalid research complexity: $RESEARCH_COMPLEXITY (must be 1-4)" 1
fi
```

**Phase**: Add to Phase 1 (Foundation) tasks after Line 241

### Recommendation 6: Add Performance Baseline and Latency Budget

**Rationale**: Plan targets 5-10s latency reduction but lacks measurement methodology. Performance regression prevention requires baseline.

**Implementation**:
1. **Baseline Measurement** (before implementation):
   - Measure /coordinate execution time for each workflow type (10 runs per type)
   - Capture per-phase latency breakdown (classification, research, planning, etc.)
   - Document baseline in `.claude/specs/743_*/artifacts/performance_baseline.md`

2. **Latency Budget per Command**:
   - /research: <5s total (no classification, direct research invocation)
   - /research-plan: <15s total (research + planning, no classification)
   - /research-revise: <10s total (research + revision, no classification)
   - /build: Variable (depends on plan size, no fixed budget)
   - /fix: <10s total (research + debug planning, no classification)

3. **Performance Test** (Phase 6):
   ```bash
   # Measure each command 10 times
   for i in {1..10}; do
     START=$(date +%s%N)
     /research "test topic $i" >/dev/null 2>&1
     END=$(date +%s%N)
     DURATION=$(( (END - START) / 1000000 ))  # Convert to milliseconds
     echo "$DURATION" >> research_latency.txt
   done

   # Calculate median latency
   MEDIAN=$(sort -n research_latency.txt | awk 'NR==5')
   echo "Median /research latency: ${MEDIAN}ms"
   # Verify: Median < 5000ms (5s budget)
   ```

4. **Regression Detection**:
   - CI/CD integration: Run performance tests on each commit
   - Alert if any command exceeds latency budget by >10%

**Phase**: Add to Phase 6 (Feature Preservation Validation) after Line 489

## References

### Plan Files
- `/home/benjamin/.config/.claude/specs/743_coordinate_command_working_reasonably_well_more/plans/001_dedicated_orchestrator_commands.md` (Lines 1-667)

### Implementation Files
- `/home/benjamin/.config/.claude/commands/coordinate.md` (Lines 1-300+: workflow classification, state machine initialization, research phase)
- `/home/benjamin/.config/.claude/commands/implement.md` (Lines 1-100: argument handling pattern, auto-resume logic)
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (Lines 1-200: state enumeration, transition validation, array persistence)
- `/home/benjamin/.config/.claude/lib/error-handling.sh` (Lines 1-100: error classification, recovery suggestions)

### Research Reports
- `/home/benjamin/.config/.claude/specs/743_coordinate_command_working_reasonably_well_more/reports/001_coordinate_command_architecture.md` (Lines 42, 77, 80: workflow types and state mapping)
- `/home/benjamin/.config/.claude/specs/743_coordinate_command_working_reasonably_well_more/reports/002_distinct_workflows_in_coordinate.md` (Lines 1-150: workflow classification system, 5 workflow types with inputs/outputs/transitions)
- `/home/benjamin/.config/.claude/specs/743_coordinate_command_working_reasonably_well_more/reports/003_feature_preservation_patterns.md` (Lines 1-100: 6 essential features, wave-based execution, state machine architecture, context reduction)
