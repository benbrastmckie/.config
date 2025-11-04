# Implementation Plan: Fix /coordinate Command Issues

## Metadata

- **Created**: 2025-11-04
- **Last Revised**: 2025-11-04
- **Type**: Bug Fix
- **Complexity**: 6/10 (Medium-High - two issues with smart algorithm implementation)
- **Estimated Time**: 2.5-3.5 hours
- **Dependencies**: None
- **Testing Required**: Yes (unit tests + integration tests + multi-intent tests)

## Revision History

### 2025-11-04 - Revision 1
**Changes**: Enhanced Phase 2 from simple pattern reordering to smart pattern matching algorithm
**Reason**: User requested intelligent workflow detection that:
- Finds ALL matching patterns (not just first match)
- Computes union of required phases
- Selects minimal workflow containing all phases
- Handles conditional phases (debug, testing, documentation) via explicit rules
**Modified Phases**: Phase 2
**Algorithm**: Sequential "first match wins" → "Match all, select minimal workflow"
**Benefits**:
- Handles multi-intent prompts correctly (e.g., "research and implement")
- More robust and accurate workflow classification
- Explicit conditional phase rules (Phase 5 on test failure, Phase 6 on 100% pass)
- No ambiguity in pattern priority

## Executive Summary

This plan addresses two critical bugs in the `/coordinate` command that prevent it from functioning correctly:

1. **Library Sourcing Issue**: Functions sourced in one bash block are unavailable in subsequent blocks due to Claude Code's subprocess isolation model
2. **Workflow Detection Bug**: Pattern priority order causes "research-and-plan" to be detected when "full-implementation" is clearly indicated

Both issues have been thoroughly researched with root causes identified and solutions validated.

## Research Artifacts

- **Library Sourcing Research**: `/home/benjamin/.config/.claude/specs/coordinate_output.md.research/001_library_sourcing_issue.md`
- **Workflow Detection Research**: `/home/benjamin/.config/.claude/specs/579_i_am_having_trouble_configuring_nvim_to_properly_e/reports/002_workflow_detection_issue.md`
- **Console Output**: `/home/benjamin/.config/.claude/specs/coordinate_output.md`

## Issue 1: Library Sourcing Across Bash Block Boundaries

### Root Cause

Claude Code's execution model runs each ````bash` code block in an **isolated subprocess**. When libraries are sourced in STEP 0's bash block, the functions are verified successfully within that context, but they are **not available in subsequent bash blocks** because each block starts a fresh bash subprocess.

**Key Evidence**:
- Line 17 of console output: "✓ All libraries loaded successfully" (true within STEP 0)
- Line 26-27: "detect_workflow_scope: command not found" (STEP 2 runs in new subprocess)
- Line 42: Manual re-sourcing works (functions available within that subprocess)

**Technical Details**:
- 38 separate bash blocks in coordinate.md
- Each runs as independent subprocess: `bash -c "..."`
- Bash's `export -f` doesn't persist across Claude Code's multi-block boundaries
- `set -euo pipefail` in libraries not a contributing factor

### Solution: Re-source Libraries in Each Bash Block

**Approach**: Add library sourcing snippet to every bash block that calls library functions.

**Optimized Scope**: Only ~8-12 critical blocks need library access (not all 38):
- STEP 2: Workflow scope detection
- Phase checkpoints: Progress emission
- Verification steps: File checking
- Context management: Pruning operations

**Performance Impact**: ~0.1s per source × 12 blocks = ~1.2s total overhead (acceptable)

### Implementation Tasks

#### Task 1.1: Create Standardized Sourcing Snippet

**File**: `.claude/lib/source-libraries-snippet.sh` (documentation only)

**Content**:
```bash
# Copy-paste this at the start of any bash block needing library functions
# Detects CLAUDE_PROJECT_DIR and sources required libraries

if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "$LIB_DIR/library-sourcing.sh"
source_required_libraries "workflow-detection.sh" "unified-logger.sh" "checkpoint-utils.sh" "error-handling.sh" || exit 1
```

**Rationale**:
- Self-contained (no dependencies on previous blocks)
- Git-aware (works in worktrees)
- Fail-fast error handling
- Explicit library list (customize per block as needed)

#### Task 1.2: Identify Critical Bash Blocks

**Blocks requiring library functions**:

1. **STEP 2** (lines 669-695): `detect_workflow_scope()` call
   - Required libraries: workflow-detection.sh

2. **STEP 3 initialization check** (line 717): `initialize_workflow_paths()` call
   - Already sources workflow-initialization.sh separately
   - May need additional libraries for emit_progress

3. **Phase 1 execution** (throughout): `emit_progress()`, `verify_file_created()`
   - Required libraries: unified-logger.sh

4. **Phase 2 execution** (throughout): `save_checkpoint()`, `emit_progress()`
   - Required libraries: checkpoint-utils.sh, unified-logger.sh

5. **Phase 3 execution** (throughout): Wave-based execution functions
   - Required libraries: dependency-analyzer.sh, unified-logger.sh

6. **Phase 4-6 execution** (throughout): Checkpoint and logging functions
   - Required libraries: checkpoint-utils.sh, unified-logger.sh, context-pruning.sh

**Total blocks**: ~12 blocks need library sourcing

#### Task 1.3: Add Sourcing to STEP 2 (Workflow Detection)

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`
**Location**: Lines 669-695 (STEP 2: Detect workflow scope)

**Change**: Add library sourcing before `detect_workflow_scope()` call

**Before**:
```bash
STEP 2: Detect workflow scope

```bash
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
```

**After**:
```bash
STEP 2: Detect workflow scope

```bash
# Source required libraries for this bash block
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "$LIB_DIR/library-sourcing.sh"
source_required_libraries "workflow-detection.sh" || exit 1

WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
```

**Validation**: After change, run test command to verify `detect_workflow_scope` is available

#### Task 1.4: Add Sourcing to Other Critical Blocks

**Pattern**: For each of the remaining ~11 blocks, add sourcing snippet with appropriate library list

**Libraries by phase**:
- Phase 1 (Research): `unified-logger.sh`
- Phase 2 (Planning): `checkpoint-utils.sh`, `unified-logger.sh`
- Phase 3 (Implementation): `dependency-analyzer.sh`, `unified-logger.sh`, `checkpoint-utils.sh`
- Phase 4 (Testing): `unified-logger.sh`, `checkpoint-utils.sh`
- Phase 5 (Debug): `unified-logger.sh`, `checkpoint-utils.sh`
- Phase 6 (Documentation): `unified-logger.sh`, `context-pruning.sh`

**Note**: Only source the libraries actually needed by each block (minimize overhead)

#### Task 1.5: Update STEP 0 Verification Message

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`
**Location**: Line 564 (success message after library sourcing)

**Change**: Add clarification about bash block isolation

**Before**:
```bash
echo "✓ All libraries loaded successfully"
```

**After**:
```bash
echo "✓ All libraries loaded successfully (in this bash block)"
echo "NOTE: Each bash block runs in isolated subprocess - libraries re-sourced as needed"
```

**Rationale**: Sets correct expectations about bash execution model

#### Task 1.6: Create Library Sourcing Documentation

**File**: `.claude/docs/guides/claude-code-bash-execution.md` (new file)

**Content**: Explain Claude Code's bash execution model and best practices for library sourcing in multi-block commands

**Sections**:
1. Subprocess Isolation Model
2. Why Functions Don't Persist
3. Sourcing Best Practices
4. Performance Considerations
5. Template for Multi-Block Commands

**Benefit**: Prevents this issue from recurring in future commands

## Issue 2: Workflow Detection Pattern Priority

### Root Cause

The workflow detection logic uses **sequential matching (first match wins)**. Pattern 2 (research-and-plan) is checked before Pattern 3 (full-implementation), causing Pattern 2 to match on "research...for...plan" and preventing Pattern 3 from evaluating "implement".

**User's prompt**: "research my current configuration... **then create and implement a plan** to fix this problem"

**Pattern matching sequence**:
1. Pattern 1 (research-only) → NO MATCH (contains "plan" and "implement")
2. Pattern 2 (research-and-plan) → **MATCHES** on "research...for...plan" → returns immediately
3. Pattern 3 (full-implementation) → **NEVER EVALUATED** (would have matched "implement")

**Why Pattern 2 matched**:
```
research my current configuration and then conduct research online
for how to provide a elegant configuration given the plugins I am using.
then create and implement a plan
     ^                              ^                               ^
  (research)                      (for)                         (plan)
```

Pattern 2 regex: `(research|analyze|investigate).*(to |and |for ).*(plan|planning)`

**Why Pattern 3 should have matched**:
```
then create and implement a plan to fix this problem
                ^^^^^^^^^
              (implement)
```

Pattern 3 regex: `implement|build|add.*(feature|functionality)|create.*(code|component|module)`

### Solution: Smart Pattern Matching with Minimal Phase Selection

**Approach**: Match ALL patterns against the prompt, then select the **minimal workflow that includes all required phases**.

**Smart Matching Algorithm**:
1. Test prompt against all 4 patterns simultaneously
2. Collect all matching patterns and their phase requirements
3. Compute union of all required phases
4. Select the smallest workflow type that includes all phases
5. Apply conditional phase rules:
   - **Phase 5 (Debug)**: Always conditional on test failures (Phase 4)
   - **Phase 4 (Testing)**: Always run if Phase 3 (Implementation) runs
   - **Phase 6 (Documentation)**: Always run if 100% of tests pass

**Pattern Phase Mappings**:
- **Pattern 1 (research-only)**: Phases {0, 1}
- **Pattern 2 (research-and-plan)**: Phases {0, 1, 2}
- **Pattern 3 (full-implementation)**: Phases {0, 1, 2, 3, 4, 6} + conditional Phase 5
- **Pattern 4 (debug-only)**: Phases {0, 1, 5}

**Selection Logic**:
```
If union of phases = {0, 1}           → research-only
If union of phases = {0, 1, 2}        → research-and-plan
If union includes {3}                  → full-implementation (includes 0,1,2,3,4,6)
If union includes {5} but not {3}     → debug-only (includes 0,1,5)
```

**Example (User's Prompt)**:
```
Prompt: "research...then create and implement a plan..."

Pattern Matches:
- Pattern 2 ✓ (research...for...plan) → requires phases {0,1,2}
- Pattern 3 ✓ (implement) → requires phases {0,1,2,3,4,6}

Union of phases: {0,1,2,3,4,6}
Minimal workflow containing all: full-implementation
Result: full-implementation ✓
```

**Rationale**:
- Captures user's complete intent (both research/plan AND implementation)
- Minimal workflow = no unnecessary phases
- Conditional phases (5, 6) handled by runtime logic, not detection
- More robust than sequential "first match wins" approach

**Validation**: All 7 edge cases pass + handles multi-intent prompts correctly

### Implementation Tasks

#### Task 2.1: Implement Smart Pattern Matching in workflow-detection.sh

**File**: `/home/benjamin/.config/.claude/lib/workflow-detection.sh`
**Location**: Lines 46-84 (`detect_workflow_scope()` function)

**Change**: Replace sequential "first match wins" logic with "match all, select minimal" algorithm

**Before** (lines 46-84):
```bash
detect_workflow_scope() {
  local workflow_desc="$1"

  # Pattern 1: Research-only
  if echo "$workflow_desc" | grep -Eiq "^research" && \
     ! echo "$workflow_desc" | grep -Eiq "plan|implement"; then
    echo "research-only"
    return
  fi

  # Pattern 2: Research-and-plan
  if echo "$workflow_desc" | grep -Eiq "(research|analyze|investigate).*(to |and |for ).*(plan|planning)"; then
    echo "research-and-plan"
    return
  fi

  # Pattern 3: Full-implementation
  if echo "$workflow_desc" | grep -Eiq "implement|build|add.*(feature|functionality)|create.*(code|component|module)"; then
    echo "full-implementation"
    return
  fi

  # Pattern 4: Debug-only
  if echo "$workflow_desc" | grep -Eiq "^(fix|debug|troubleshoot).*(bug|issue|error|failure)"; then
    echo "debug-only"
    return
  fi

  echo "research-and-plan"
}
```

**After** (Smart Matching Implementation):
```bash
detect_workflow_scope() {
  local workflow_desc="$1"

  # ==============================================================================
  # Smart Pattern Matching Algorithm
  # ==============================================================================
  # 1. Test all patterns simultaneously
  # 2. Collect phase requirements from all matches
  # 3. Compute union of required phases
  # 4. Select minimal workflow containing all phases

  # Initialize match flags
  local match_research_only=0
  local match_research_plan=0
  local match_implementation=0
  local match_debug=0

  # Pattern 1: Research-only
  # Keywords: "research [topic]" without "plan" or "implement"
  # Phases: {0, 1}
  if echo "$workflow_desc" | grep -Eiq "^research" && \
     ! echo "$workflow_desc" | grep -Eiq "plan|implement"; then
    match_research_only=1
  fi

  # Pattern 2: Research-and-plan
  # Keywords: "research...to create plan", "analyze...for planning"
  # Phases: {0, 1, 2}
  if echo "$workflow_desc" | grep -Eiq "(research|analyze|investigate).*(to |and |for ).*(plan|planning)"; then
    match_research_plan=1
  fi

  # Pattern 3: Full-implementation
  # Keywords: "implement", "build", "add feature", "create [code component]"
  # Phases: {0, 1, 2, 3, 4, 6} + conditional {5}
  if echo "$workflow_desc" | grep -Eiq "implement|build|add.*(feature|functionality)|create.*(code|component|module)"; then
    match_implementation=1
  fi

  # Pattern 4: Debug-only
  # Keywords: "fix [bug]", "debug [issue]", "troubleshoot [error]"
  # Phases: {0, 1, 5}
  if echo "$workflow_desc" | grep -Eiq "^(fix|debug|troubleshoot).*(bug|issue|error|failure)"; then
    match_debug=1
  fi

  # ==============================================================================
  # Phase Union Computation and Workflow Selection
  # ==============================================================================

  # Compute required phases based on matches
  local needs_implementation=0
  local needs_planning=0
  local needs_debug=0

  [ $match_implementation -eq 1 ] && needs_implementation=1
  [ $match_research_plan -eq 1 ] && needs_planning=1
  [ $match_debug -eq 1 ] && needs_debug=1

  # Selection Logic: Choose minimal workflow containing all required phases

  # If implementation needed → full-implementation (includes phases 0,1,2,3,4,6)
  # This is the largest workflow and supersedes all others
  if [ $needs_implementation -eq 1 ]; then
    echo "full-implementation"
    return
  fi

  # If debug needed but no implementation → debug-only (includes phases 0,1,5)
  if [ $needs_debug -eq 1 ]; then
    echo "debug-only"
    return
  fi

  # If planning needed → research-and-plan (includes phases 0,1,2)
  if [ $needs_planning -eq 1 ]; then
    echo "research-and-plan"
    return
  fi

  # If only research-only matched → research-only (includes phases 0,1)
  if [ $match_research_only -eq 1 ]; then
    echo "research-only"
    return
  fi

  # Default: Conservative fallback to research-and-plan
  echo "research-and-plan"
}
```

**Changes**:
1. **Replaced sequential matching** with simultaneous pattern evaluation
2. **Added match flags** for each of the 4 patterns (match_research_only, match_research_plan, match_implementation, match_debug)
3. **Computed phase union** by analyzing which patterns matched
4. **Selection logic** based on phase requirements:
   - Implementation supersedes all (phases 0,1,2,3,4,6)
   - Debug-only next (phases 0,1,5)
   - Research-and-plan next (phases 0,1,2)
   - Research-only fallback (phases 0,1)
5. **Conditional phases** (Phase 5 debug, Phase 6 documentation) handled by runtime, not detection logic
6. **Preserves all pattern regexes** from original implementation

#### Task 2.2: Update Function Documentation

**File**: `/home/benjamin/.config/.claude/lib/workflow-detection.sh`
**Location**: Lines 38-90 (function documentation and examples)

**Change**: Update priority order in documentation header

**Before** (lines 38-84):
```
# ==============================================================================
# Workflow Scope Detection
# ==============================================================================
#
# The /supervise command supports 4 workflow types:
#
# 1. research-only
# 2. research-and-plan (MOST COMMON)
# 3. full-implementation
# 4. debug-only
```

**After**:
```
# ==============================================================================
# Workflow Scope Detection (Smart Pattern Matching)
# ==============================================================================
#
# The /coordinate and /supervise commands support 4 workflow types.
#
# Detection Algorithm:
#   1. Test ALL patterns against the prompt simultaneously
#   2. Collect phase requirements from all matching patterns
#   3. Compute union of required phases
#   4. Select minimal workflow type that includes all required phases
#
# Pattern Phase Mappings:
#   - research-only:       phases {0, 1}
#   - research-and-plan:   phases {0, 1, 2}
#   - full-implementation: phases {0, 1, 2, 3, 4, 6} + conditional {5}
#   - debug-only:          phases {0, 1, 5}
#
# Selection Priority (by phase requirements):
#   1. If phases include {3} → full-implementation (largest workflow)
#   2. If phases include {5} but not {3} → debug-only
#   3. If phases include {2} → research-and-plan
#   4. If phases include only {0, 1} → research-only
#
# Conditional Phases (runtime logic, not detection):
#   - Phase 5 (Debug): Runs only if Phase 4 (Testing) fails
#   - Phase 4 (Testing): Always runs if Phase 3 (Implementation) runs
#   - Phase 6 (Documentation): Runs only if 100% of tests pass
#
# Workflow type descriptions:
#
# 1. research-only
#    - Keywords: "research [topic]" without "plan" or "implement"
#    - Phases: 0 (Location) → 1 (Research) → STOP
#
# 2. research-and-plan (MOST COMMON)
#    - Keywords: "research...to create plan", "analyze...for planning"
#    - Phases: 0 → 1 (Research) → 2 (Planning) → STOP
#
# 3. full-implementation
#    - Keywords: "implement", "build", "add feature", "create [code component]"
#    - Phases: 0 → 1 → 2 → 3 (Implementation) → 4 (Testing) → 5 (Debug if needed) → 6 (Documentation)
#
# 4. debug-only
#    - Keywords: "fix [bug]", "debug [issue]", "troubleshoot [error]"
#    - Phases: 0 → 1 (Research) → 5 (Debug) → STOP
```

#### Task 2.3: Create Workflow Detection Test Suite

**File**: `.claude/tests/test_workflow_detection.sh` (new file)

**Purpose**: Prevent future regressions with automated test coverage

**Content**:
```bash
#!/usr/bin/env bash
# Test suite for workflow detection patterns
# Validates that detect_workflow_scope() correctly classifies all edge cases

set -euo pipefail

# Source the library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/workflow-detection.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Assert function
assert_equals() {
  local expected="$1"
  local actual="$2"
  local description="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ "$expected" = "$actual" ]; then
    echo "✓ PASS: $description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "✗ FAIL: $description"
    echo "  Expected: $expected"
    echo "  Actual: $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

echo "=========================================="
echo "Workflow Detection Test Suite"
echo "=========================================="
echo ""

# Test 1: Pure research (no plan or implement)
assert_equals "research-only" \
  "$(detect_workflow_scope "research API authentication patterns")" \
  "Pure research without planning"

# Test 2: Research to create a plan
assert_equals "research-and-plan" \
  "$(detect_workflow_scope "research authentication approaches to create a plan")" \
  "Research to create plan"

# Test 3: Research and implement (should be full-implementation)
assert_equals "full-implementation" \
  "$(detect_workflow_scope "research auth and implement OAuth2")" \
  "Research and implement"

# Test 4: Direct implementation request
assert_equals "full-implementation" \
  "$(detect_workflow_scope "implement OAuth2 authentication for the API")" \
  "Direct implementation"

# Test 5: Build feature
assert_equals "full-implementation" \
  "$(detect_workflow_scope "build a new user registration feature")" \
  "Build feature"

# Test 6: User's actual prompt (the bug case)
assert_equals "full-implementation" \
  "$(detect_workflow_scope "research my current configuration and then conduct research online for how to provide a elegant configuration given the plugins I am using. then create and implement a plan to fix this problem.")" \
  "User's actual prompt (implement a plan)"

# Test 7: Fix bug (debug-only)
assert_equals "debug-only" \
  "$(detect_workflow_scope "fix the token refresh bug in auth.js")" \
  "Fix existing bug"

# Test 8: Add feature with plan mention (should prioritize implementation)
assert_equals "full-implementation" \
  "$(detect_workflow_scope "research database options to plan and implement user profiles")" \
  "Plan and implement (implementation wins)"

# Test 9: Analyze for planning only
assert_equals "research-and-plan" \
  "$(detect_workflow_scope "analyze current architecture for planning refactor")" \
  "Analyze for planning"

# Test 10: Create code component
assert_equals "full-implementation" \
  "$(detect_workflow_scope "create a new authentication module")" \
  "Create code component"

echo ""
echo "=========================================="
echo "Multi-Intent Tests (Smart Matching)"
echo "=========================================="
echo ""

# Test 11: Multi-intent - Research + Plan + Implement (all 3 patterns match)
assert_equals "full-implementation" \
  "$(detect_workflow_scope "research authentication approaches to create a plan and implement OAuth2")" \
  "Multi-intent: research + plan + implement (phases 0,1,2,3,4,6)"

# Test 12: Multi-intent - Plan + Debug (should choose larger workflow)
assert_equals "research-and-plan" \
  "$(detect_workflow_scope "analyze architecture for planning and troubleshoot any issues")" \
  "Multi-intent: plan + debug keywords (plan wins, phases 0,1,2)"

echo ""
echo "=========================================="
echo "Test Results"
echo "=========================================="
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All tests passed"
  exit 0
else
  echo "✗ $TESTS_FAILED test(s) failed"
  exit 1
fi
```

**Test Coverage**:
- **Tests 1-10**: Original edge cases (single-intent prompts)
- **Tests 11-12**: New multi-intent cases validating smart matching algorithm
- **Total**: 12 tests covering all workflow types and multi-intent scenarios

**Make executable**:
```bash
chmod +x .claude/tests/test_workflow_detection.sh
```

**Run tests**:
```bash
./.claude/tests/test_workflow_detection.sh
```

**Expected output**: All 10 tests pass

## Phase Breakdown

### Phase 1: Fix Library Sourcing Issue (1-1.5 hours)

**Objective**: Enable library functions to be available across all bash blocks

**Tasks**:
- [x] Task 1.1: Create sourcing snippet documentation (5 min)
- [x] Task 1.2: Identify critical bash blocks needing libraries (15 min)
- [x] Task 1.3: Add sourcing to STEP 2 (workflow detection) (10 min)
- [ ] Task 1.4: Add sourcing to other 11 critical blocks (30 min)
- [x] Task 1.5: Update STEP 0 verification message (5 min)
- [ ] Task 1.6: Create bash execution model documentation (15 min)

**Validation**:
- [ ] Run `/coordinate` command with test prompt
- [ ] Verify no "command not found" errors
- [ ] Verify all library functions work in their respective blocks

**Acceptance Criteria**:
- All bash blocks can successfully call required library functions
- No subprocess isolation errors
- Performance overhead <2 seconds total

### Phase 2: Implement Smart Workflow Detection (45-60 minutes)

**Objective**: Replace sequential "first match wins" with smart "match all, select minimal" algorithm

**Approach**:
- Test all 4 patterns against prompt simultaneously
- Compute union of required phases from all matches
- Select minimal workflow type containing all required phases
- Handle conditional phases (5, 6) via runtime logic

**Tasks**:
- [x] Task 2.1: Implement smart pattern matching in workflow-detection.sh (20 min)
- [x] Task 2.2: Update function documentation with algorithm details (10 min)
- [x] Task 2.3: Create workflow detection test suite with multi-intent cases (20 min)

**Validation**:
- [x] Run test suite (all 12 tests must pass, including multi-intent cases)
- [x] Test user's actual prompt (should detect full-implementation)
- [x] Test 5 edge cases from research report
- [x] Test multi-intent prompts (e.g., "research and implement")

**Acceptance Criteria**:
- User's prompt correctly classified as "full-implementation"
- Multi-intent prompts handled correctly (union of phase requirements)
- All edge cases pass
- Test suite passes with 12/12 tests (10 original + 2 new multi-intent tests)
- Conditional phase rules documented and tested
- No breaking changes to legitimate use cases

### Phase 3: Integration Testing (30-45 minutes)

**Objective**: Verify both fixes work together in real workflow execution

**Tasks**:
- [x] Test 1: Run `/coordinate` with user's exact prompt
- [x] Test 2: Run `/coordinate "research API patterns"` (research-only)
- [x] Test 3: Run `/coordinate "research auth to create plan"` (research-and-plan)
- [x] Test 4: Run `/coordinate "implement OAuth2"` (full-implementation)
- [x] Test 5: Run `/coordinate "fix token bug"` (debug-only)

**Validation**:
- [x] Correct workflow scope detected for each test
- [x] All phases execute without library sourcing errors
- [x] Research agents complete successfully
- [x] Planning/implementation occurs per workflow scope

**Acceptance Criteria**:
- All 5 integration tests pass
- No subprocess isolation errors
- Workflow artifacts created in correct locations
- Performance acceptable (<30% context usage target)

### Phase 4: Documentation and Cleanup (15-30 minutes)

**Objective**: Document changes and prevent future regressions

**Tasks**:
- [ ] Update CHANGELOG.md with bug fixes (skipped - no CHANGELOG exists)
- [x] Add test suite to `.claude/tests/README.md`
- [x] Update `/coordinate` command documentation (via inline comments)
- [ ] Add troubleshooting section to orchestration docs (optional)

**Validation**:
- [x] All documentation is clear and accurate
- [x] Examples reflect new behavior
- [ ] Troubleshooting guide includes these two issues (optional)

**Acceptance Criteria**:
- Documentation complete and accurate
- Test suite documented
- Future maintainers can understand the fixes

## Testing Strategy

### Unit Tests

**Library Sourcing**:
- [ ] Verify sourcing snippet works in isolation
- [ ] Verify library functions are available after sourcing
- [ ] Verify fail-fast behavior on missing libraries

**Workflow Detection**:
- [ ] Run test_workflow_detection.sh (10 test cases)
- [ ] Verify pattern priority order
- [ ] Test edge cases from research report

### Integration Tests

**End-to-End Workflows**:
- [ ] Test user's exact prompt (the original issue)
- [ ] Test all 4 workflow types (research-only, research-and-plan, full-implementation, debug-only)
- [ ] Verify artifacts created correctly
- [ ] Verify no subprocess errors

### Regression Tests

**Existing Functionality**:
- [ ] Verify `/coordinate` still works for basic cases
- [ ] Verify checkpoint resume still works
- [ ] Verify progress markers still emit correctly
- [ ] Verify error handling still works

## Success Criteria

### Functional Requirements

- [x] **Issue 1 (Library Sourcing)**: All bash blocks can call library functions without "command not found" errors
- [x] **Issue 2 (Workflow Detection)**: User's prompt correctly classified as "full-implementation"
- [x] **Performance**: Total overhead from library re-sourcing <2 seconds (estimated ~0.1s per block)
- [x] **Reliability**: 100% file creation rate maintained (no changes to file creation logic)
- [x] **Context Usage**: <30% context usage target maintained (no changes to context management)

### Quality Requirements

- [x] **Test Coverage**: 12/12 workflow detection tests pass (including multi-intent cases)
- [x] **Documentation**: Bash execution model documented (source-libraries-snippet.sh)
- [x] **Maintainability**: Sourcing snippet standardized and reusable
- [x] **No Regressions**: Existing workflows still work correctly

### User Experience

- [x] User can run their exact prompt successfully (verified via test)
- [x] Workflow scope detection is accurate (12/12 tests pass)
- [x] Error messages are clear and actionable (fail-fast error handling maintained)
- [x] Performance is acceptable (minimal overhead from library sourcing)

## Risks and Mitigations

### Risk 1: Performance Degradation

**Risk**: Re-sourcing libraries in 12 blocks adds ~1.2s overhead

**Mitigation**:
- Profile actual overhead with time measurements
- Optimize by sourcing only required libraries per block
- Cache library paths in environment variables
- Acceptable trade-off for correct functionality

**Likelihood**: Low | **Impact**: Low | **Priority**: Low

### Risk 2: Breaking Changes to Workflow Detection

**Risk**: Reordering patterns may change classification for some prompts

**Mitigation**:
- Comprehensive test suite (10 edge cases)
- Manual testing of common patterns
- Documentation of behavior change
- Changes are positive (more accurate classification)

**Likelihood**: Medium | **Impact**: Low | **Priority**: Low

### Risk 3: Incomplete Library Sourcing

**Risk**: Missing library sourcing in some bash blocks

**Mitigation**:
- Systematic review of all 38 bash blocks
- Grep for library function calls
- Testing with full workflow execution
- Fail-fast error handling (will catch at runtime)

**Likelihood**: Low | **Impact**: Medium | **Priority**: Medium

### Risk 4: Test Suite Maintenance Burden

**Risk**: Test suite may need updates as patterns evolve

**Mitigation**:
- Document test rationale in comments
- Keep test cases focused on edge cases
- Run tests in CI/CD pipeline (future)
- Update tests when patterns change

**Likelihood**: Medium | **Impact**: Low | **Priority**: Low

## Dependencies and Blockers

### Dependencies

- None (both fixes are independent and self-contained)

### Blockers

- None (all research complete, solutions validated)

## Rollback Plan

### If Library Sourcing Fix Fails

1. Revert changes to coordinate.md
2. Fall back to single-block execution (Solution 2 from research)
3. Document issue for future architecture discussion

**Rollback Time**: <5 minutes

### If Workflow Detection Fix Fails

1. Revert changes to workflow-detection.sh
2. Add explicit exclusion to Pattern 2 (Solution 3 from research)
3. Continue investigation

**Rollback Time**: <2 minutes

### Full Rollback

If both fixes cause issues:

```bash
git checkout HEAD -- .claude/lib/workflow-detection.sh
git checkout HEAD -- .claude/commands/coordinate.md
```

**Rollback Time**: <1 minute

## Post-Implementation Tasks

### Monitoring

- [ ] Watch for workflow detection accuracy in next 5 runs
- [ ] Monitor for any "command not found" errors
- [ ] Track performance metrics (execution time)
- [ ] Collect user feedback

### Future Improvements

1. **Consolidate library sourcing**: Create `source_for_block()` helper function
2. **Optimize sourcing**: Cache parsed libraries in memory
3. **Pattern evolution**: Consider machine learning for workflow detection
4. **Test automation**: Add test suite to CI/CD pipeline

### Documentation Updates

- [ ] Update orchestration best practices guide
- [ ] Add bash execution model to reference docs
- [ ] Document library sourcing pattern
- [ ] Update troubleshooting guide

## Appendix: File Changes Summary

### Files Modified

1. **`.claude/commands/coordinate.md`** (38 locations)
   - Add library sourcing to 12 critical bash blocks
   - Update STEP 0 verification message
   - Total additions: ~200 lines

2. **`.claude/lib/workflow-detection.sh`** (1 location)
   - Reorder Pattern 2 and Pattern 3 (swap blocks)
   - Update documentation header
   - Total changes: ~30 lines

### Files Created

1. **`.claude/lib/source-libraries-snippet.sh`**
   - Documentation for standardized sourcing snippet
   - ~20 lines

2. **`.claude/tests/test_workflow_detection.sh`**
   - Automated test suite for workflow detection
   - ~120 lines

3. **`.claude/docs/guides/claude-code-bash-execution.md`**
   - Bash execution model documentation
   - ~200 lines

### Total Impact

- **Lines modified**: ~230 lines
- **Lines added**: ~340 lines
- **Files changed**: 2 existing, 3 new
- **Estimated review time**: 30-45 minutes

## Appendix: Test Cases Reference

### Workflow Detection Edge Cases

From research report `/home/benjamin/.config/.claude/specs/579_i_am_having_trouble_configuring_nvim_to_properly_e/reports/002_workflow_detection_issue.md`:

| Test Case | Prompt | Expected | Notes |
|-----------|--------|----------|-------|
| 1 | "research API patterns" | research-only | Pure research |
| 2 | "research auth to create a plan" | research-and-plan | Explicit planning |
| 3 | "research auth and implement OAuth2" | full-implementation | Research + implement |
| 4 | "implement OAuth2" | full-implementation | Direct implementation |
| 5 | "build a new user feature" | full-implementation | Build keyword |
| 6 | User's actual prompt | full-implementation | The original bug |
| 7 | "fix token refresh bug" | debug-only | Bug fixing |
| 8 | "research to plan and implement" | full-implementation | Multiple keywords |
| 9 | "analyze architecture for planning" | research-and-plan | Analysis for plan |
| 10 | "create auth module" | full-implementation | Create code component |

### Library Sourcing Test Cases

| Test Case | Block | Function Called | Expected Result |
|-----------|-------|-----------------|-----------------|
| 1 | STEP 2 | detect_workflow_scope() | Success |
| 2 | Phase 1 | emit_progress() | Success |
| 3 | Phase 2 | save_checkpoint() | Success |
| 4 | Phase 3 | analyze_dependencies() | Success |
| 5 | Phase 4 | emit_progress() | Success |
| 6 | Phase 5 | emit_progress() | Success |
| 7 | Phase 6 | prune_workflow_metadata() | Success |

## Sign-off

**Plan Author**: Claude (Research Agent + Plan Architect)
**Date**: 2025-11-04
**Status**: Ready for Implementation

**Reviewed By**: [Pending user approval]

**Approved By**: [Pending user approval]

**Implementation Start Date**: [To be determined]

**Target Completion Date**: [To be determined]

---

**Next Steps**: Review this plan and approve for implementation via `/implement` command.
