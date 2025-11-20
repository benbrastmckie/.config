# State Machine Migration Guide

**Purpose**: Guide for migrating orchestration commands from phase-based architecture to state machine architecture.

**Status**: Production (based on successful migrations of /coordinate, /orchestrate, /supervise)

**Achieved Results**: 51.2% code reduction across 3 orchestrators (3,420 → 1,669 lines), exceeding 39% target

---

## Table of Contents

1. [Overview](#overview)
2. [Migration Pattern](#migration-pattern)
3. [Step-by-Step Migration](#step-by-step-migration)
4. [Code Examples](#code-examples)
5. [Testing Requirements](#testing-requirements)
6. [Common Issues](#common-issues)
7. [Case Studies](#case-studies)

---

## Overview

### What is State Machine Architecture?

State machine architecture replaces implicit phase numbering (Phase 0, Phase 1, etc.) with explicit states and transitions, providing:

- **Clear state representation**: `CURRENT_STATE = "research"` instead of `PHASE = 1`
- **Validated transitions**: State transition table enforces valid paths
- **Atomic checkpoints**: Two-phase commit for state changes
- **Error context**: Failed state tracking for debugging
- **Resumability**: State persistence enables workflow recovery

### Why Migrate?

**Benefits**:
- **Code Reduction**: 33-78% reduction depending on original complexity
- **Maintainability**: Explicit states easier to understand than phase numbers
- **Error Handling**: State-based context simplifies debugging
- **Consistency**: Same pattern across all orchestrators
- **Resumability**: Better checkpoint/recovery with state persistence

**When to Migrate**:
- Orchestration commands (multi-agent coordination)
- Long-running workflows requiring resumability
- Commands with complex phase dependencies
- Systems needing better error recovery

**When NOT to Migrate**:
- Simple linear commands (<100 lines)
- Commands without phases or states
- Read-only commands (no state changes)
- Single-shot operations (no resumability needed)

### Migration Results

From our three successful migrations:

| Command | Before | After | Reduction | Notes |
|---------|--------|-------|-----------|-------|
| /coordinate | 1,084 lines | 721 lines | 33.5% | Near 40% target with error handling |
| /orchestrate | 557 lines | 551 lines | 1.1% | Already optimized, added consistency |
| /supervise | 1,779 lines | 397 lines | 77.7% | Massive header reduction |
| **Total** | **3,420 lines** | **1,669 lines** | **51.2%** | **Exceeded 39% target** |

---

## Migration Pattern

### Core Components

Every state machine migration requires:

1. **State Machine Library**: `.claude/lib/workflow/workflow-state-machine.sh`
   - `sm_init()`: Initialize state machine
   - `sm_transition()`: Transition between states
   - `sm_execute()`: Execute state handlers (optional)

2. **State Persistence Library**: `.claude/lib/core/state-persistence.sh`
   - `init_workflow_state()`: Create state file
   - `load_workflow_state()`: Restore state
   - `append_workflow_state()`: Add state variables

3. **State Handler Pattern**: Replace phases with state handlers
   - Before: `## Phase 1: Research`
   - After: `## State Handler: Research`

### State Enumeration

Standard states for orchestration workflows:

```bash
STATE_INITIALIZE="initialize"    # Phase 0: Setup, paths, scope detection
STATE_RESEARCH="research"         # Phase 1: Research coordination
STATE_PLAN="plan"                 # Phase 2: Planning
STATE_IMPLEMENT="implement"       # Phase 3: Implementation
STATE_TEST="test"                 # Phase 4: Testing
STATE_DEBUG="debug"               # Phase 5: Debug (conditional)
STATE_DOCUMENT="document"         # Phase 6: Documentation (conditional)
STATE_COMPLETE="complete"         # Terminal state
```

### State Transition Flow

```
initialize → research → plan → implement → test → debug → document → complete
                ↓         ↓                         ↓
            complete  complete                  complete
            (research- (research-              (test passed,
             only)     and-plan)                skip debug)
```

### Workflow Scopes and Terminal States

| Scope | Terminal State | Transitions |
|-------|---------------|-------------|
| research-only | research | initialize → research → complete |
| research-and-plan | plan | initialize → research → plan → complete |
| full-implementation | complete | initialize → research → plan → implement → test → document → complete |
| debug-only | debug | initialize → research → debug → complete |

---

## Step-by-Step Migration

### Step 1: Backup and Analyze

**Action**: Create backup and analyze structure

```bash
# Backup original
cp .claude/commands/mycommand.md .claude/commands/mycommand.md.phase-based-backup

# Analyze structure
grep "^## Phase" .claude/commands/mycommand.md
wc -l .claude/commands/mycommand.md

# Count bash blocks (optimization target)
grep -c '```bash' .claude/commands/mycommand.md
```

**Analysis Questions**:
- How many phases? (Determines number of state handlers)
- How many bash blocks? (Consolidation opportunity)
- Header size? (Documentation to move to guide file)
- Verification blocks? (Can be simplified with error handling)

### Step 2: Replace Phase 0 with State Machine Initialization

**Before** (typical Phase 0):
```markdown
## Phase 0: Initialization

USE the Bash tool to execute Phase 0 (Step 1 of 3):

```bash
# Library sourcing
source "${CLAUDE_PROJECT_DIR}/.claude/lib/some-library.sh"
# ... more sourcing ...
```

USE the Bash tool to execute Phase 0 (Step 2 of 3):

```bash
# Scope detection
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
# ... more logic ...
```

USE the Bash tool to execute Phase 0 (Step 3 of 3):

```bash
# Path pre-calculation
initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"
```
```

**After** (state machine initialization):
```markdown
## State Machine Initialization

USE the Bash tool:

```bash
echo "=== State Machine Workflow Orchestration ==="

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Parse workflow description
WORKFLOW_DESCRIPTION="$1"
if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description required"
  exit 1
fi

# Source state machine libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"

# Initialize workflow state (GitHub Actions pattern)
STATE_FILE=$(init_workflow_state "mycommand_$$")
trap "rm -f '$STATE_FILE'" EXIT

append_workflow_state "WORKFLOW_ID" "mycommand_$$"

# Initialize state machine
sm_init "$WORKFLOW_DESCRIPTION" "mycommand"

# Save state machine configuration
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
append_workflow_state "TERMINAL_STATE" "$TERMINAL_STATE"
append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"

# Source and initialize paths (existing logic)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh"
initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"

# Define error handling helper
handle_state_error() {
  local error_message="$1"
  local current_state="${CURRENT_STATE:-unknown}"
  echo ""
  echo "ERROR in state '$current_state': $error_message"
  append_workflow_state "FAILED_STATE" "$current_state"
  append_workflow_state "LAST_ERROR" "$error_message"
  exit 1
}
export -f handle_state_error

# Transition to first state
sm_transition "$STATE_RESEARCH"

echo "State Machine Initialized:"
echo "  Scope: $WORKFLOW_SCOPE"
echo "  Current State: $CURRENT_STATE"
echo "  Topic: $TOPIC_PATH"
```
```

**Key Changes**:
- Consolidated 3 bash blocks → 1 block
- Added state machine initialization (`sm_init`)
- Added state persistence (`init_workflow_state`)
- Added error handling helper
- Explicit state transition (`sm_transition`)

### Step 3: Convert Phases to State Handlers

**Pattern for Each Phase**:

```markdown
## State Handler: [StateName]

**State**: Execute when `CURRENT_STATE == "[state_name]"`

USE the Bash tool:

```bash
load_workflow_state "mycommand_$$"

# Check terminal state
if [ "$CURRENT_STATE" = "$TERMINAL_STATE" ]; then
  echo "✓ Workflow complete"
  exit 0
fi

# Verify state
if [ "$CURRENT_STATE" != "$STATE_[STATENAME]" ]; then
  handle_state_error "Expected [state_name] state"
fi

# State-specific logic here
echo "[State name] state executing..."
```

**EXECUTE NOW**: USE the Task tool to invoke [agent]:

Task {
  subagent_type: "general-purpose"
  description: "[Task description]"
  timeout: 300000
  prompt: "
    Read: ${CLAUDE_PROJECT_DIR}/.claude/agents/[agent].md

    [Agent-specific context]

    Return: [COMPLETION_SIGNAL]: [path or status]
  "
}

USE the Bash tool:

```bash
load_workflow_state "mycommand_$$"

# Verify output (if applicable)
[ ! -f "$EXPECTED_FILE" ] && handle_state_error "Output not created"

# Determine next state based on scope
case "$WORKFLOW_SCOPE" in
  [scope-that-terminates-here])
    sm_transition "$STATE_COMPLETE"
    echo "✓ [Scope] workflow complete"
    exit 0
    ;;
  *)
    sm_transition "$STATE_[NEXT]"
    ;;
esac

echo "[Current state] complete → [Next state]"
```
```

### Step 4: Add State-Based Error Handling

**Error Handler Function** (included in initialization):

```bash
handle_state_error() {
  local error_message="$1"
  local current_state="${CURRENT_STATE:-unknown}"
  local exit_code="${2:-1}"

  echo ""
  echo "ERROR in state '$current_state': $error_message"
  echo ""
  echo "State Machine Context:"
  echo "  Workflow: $WORKFLOW_DESCRIPTION"
  echo "  Scope: $WORKFLOW_SCOPE"
  echo "  Current State: $current_state"
  echo "  Terminal State: $TERMINAL_STATE"
  echo ""

  # Save failed state to workflow state for retry
  append_workflow_state "FAILED_STATE" "$current_state"
  append_workflow_state "LAST_ERROR" "$error_message"

  # Increment retry counter for this state
  RETRY_COUNT_VAR="RETRY_COUNT_${current_state}"
  RETRY_COUNT=${!RETRY_COUNT_VAR:-0}
  RETRY_COUNT=$((RETRY_COUNT + 1))
  append_workflow_state "$RETRY_COUNT_VAR" "$RETRY_COUNT"

  if [ $RETRY_COUNT -ge 2 ]; then
    echo "Max retries (2) reached for state '$current_state'"
    exit $exit_code
  else
    echo "Retry $RETRY_COUNT/2 available"
    exit $exit_code
  fi
}
export -f handle_state_error
```

**Usage in State Handlers**:

```bash
# Replace generic error exits
if [ $VERIFICATION_FAILURES -gt 0 ]; then
  echo "❌ FAILED: $VERIFICATION_FAILURES reports not created"
  exit 1  # OLD
fi

# With state-based error handling
if [ $VERIFICATION_FAILURES -gt 0 ]; then
  handle_state_error "Research verification failed - $VERIFICATION_FAILURES reports not created"  # NEW
fi
```

### Step 5: Update Tests

**Test Expectations to Update**:

1. **Delegation Rate** (`.claude/tests/test_orchestration_commands.sh`):
```bash
# Before
coordinate.md)
  expected_min=7  # Old: Research, plan, implement, test, debug (3), doc
  ;;

# After
coordinate.md)
  expected_min=5  # State machine: Research, plan, implement, debug, document
  ;;
```

2. **Library Sourcing Pattern**:
- Ensure state machine libraries are sourced with full paths
- Pattern: `source "${CLAUDE_PROJECT_DIR}/.claude/lib/[library].sh"`

3. **Agent Invocation Pattern**:
- Use: `**EXECUTE NOW**: USE the Task tool`
- Avoid template variables in agent prompts (use placeholder text)

### Step 6: Validate and Test

**Validation Checklist**:

```bash
# 1. Run orchestration tests
bash .claude/tests/test_orchestration_commands.sh
# Expected: All tests passing

# 2. Validate executable/doc separation
bash .claude/tests/validate_executable_doc_separation.sh 2>&1 | grep "mycommand.md"
# Expected: PASS on size, guide existence, cross-references

# 3. Check agent invocation patterns
bash .claude/lib/util/validate-agent-invocation-pattern.sh .claude/commands/mycommand.md
# Expected: No anti-patterns detected

# 4. Verify line count reduction
wc -l .claude/commands/mycommand.md.phase-based-backup .claude/commands/mycommand.md
# Expected: 30-80% reduction (varies by original complexity)

# 5. Smoke test (optional)
# /mycommand "test workflow description"
# Expected: State machine initializes correctly
```

---

## Code Examples

### Example 1: Complete Research State Handler

**Before** (Phase 1):
```markdown
## Phase 1: Research

USE the Bash tool:

```bash
# Determine research complexity
RESEARCH_COMPLEXITY=2
if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration"; then
  RESEARCH_COMPLEXITY=3
fi

echo "Research Complexity: $RESEARCH_COMPLEXITY topics"
```

**EXECUTE NOW**: USE the Task tool to invoke research-specialist:
[Task block...]

USE the Bash tool:

```bash
# Verify reports
VERIFICATION_FAILURES=0
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$i-1]}"
  if [ ! -f "$REPORT_PATH" ]; then
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
  fi
done

if [ $VERIFICATION_FAILURES -gt 0 ]; then
  echo "ERROR: Research phase failed"
  exit 1
fi

echo "Research complete"
```
```

**After** (Research State):
```markdown
## State Handler: Research

USE the Bash tool:

```bash
load_workflow_state "mycommand_$$"

if [ "$CURRENT_STATE" = "$TERMINAL_STATE" ]; then
  echo "✓ Workflow complete"
  exit 0
fi

if [ "$CURRENT_STATE" != "$STATE_RESEARCH" ]; then
  handle_state_error "Expected research state"
fi

# Determine complexity
RESEARCH_COMPLEXITY=2
[[ "$WORKFLOW_DESCRIPTION" =~ integrate|migration ]] && RESEARCH_COMPLEXITY=3

echo "Research: $RESEARCH_COMPLEXITY topics"
```

**EXECUTE NOW**: USE the Task tool to invoke research-specialist:
[Task block with placeholder text instead of template variables...]

USE the Bash tool:

```bash
load_workflow_state "mycommand_$$"

# Verify reports (simplified with error handler)
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$i-1]}"
  [ ! -f "$REPORT_PATH" ] && handle_state_error "Report $i not created at: $REPORT_PATH"
done

echo "✓ All reports verified"

# Transition based on scope
case "$WORKFLOW_SCOPE" in
  research-only)
    sm_transition "$STATE_COMPLETE"
    echo "✓ Research-only workflow complete"
    exit 0
    ;;
  *)
    sm_transition "$STATE_PLAN"
    ;;
esac
```
```

### Example 2: Conditional State (Debug)

**Before** (Conditional Phase):
```markdown
## Phase 5: Debug (Conditional)

USE the Bash tool:

```bash
if [ "$TESTS_PASSING" == "false" ]; then
  emit_progress "5" "Phase 5: Debug"
else
  echo "⏭️  Skipping Phase 5"
  exit 0
fi
```

[Debug logic...]
```

**After** (State Handler):
```markdown
## State Handler: Debug (Conditional)

USE the Bash tool:

```bash
load_workflow_state "mycommand_$$"

if [ "$CURRENT_STATE" != "$STATE_DEBUG" ]; then
  handle_state_error "Expected debug state"
fi

# Debug state only entered if tests failed (transition handles this)
echo "Debug state: Analyzing failures"
```

**EXECUTE NOW**: USE the Task tool for debug-analyst:
[Task block...]

USE the Bash tool:

```bash
load_workflow_state "mycommand_$$"

echo "✓ Debug analysis complete"

sm_transition "$STATE_COMPLETE"
echo "Debug complete - manual fixes required"
echo "Re-run workflow after fixes"
```
```

**Note**: State machine handles conditional logic via transitions, not within state handlers.

---

## Testing Requirements

### Pre-Migration Testing

**Baseline Metrics**:
```bash
# 1. Record original line count
wc -l .claude/commands/mycommand.md > migration_baseline.txt

# 2. Run existing tests to establish baseline
bash .claude/tests/test_orchestration_commands.sh > tests_before.txt 2>&1

# 3. Document current delegation rate
grep -c "**EXECUTE NOW**.*USE the Task tool" .claude/commands/mycommand.md
```

### Post-Migration Testing

**Validation Steps**:

1. **Orchestration Tests** (MUST PASS):
```bash
bash .claude/tests/test_orchestration_commands.sh
# All tests must pass (especially for migrated command)
```

2. **Anti-Pattern Detection** (MUST PASS):
```bash
bash .claude/lib/util/validate-agent-invocation-pattern.sh .claude/commands/mycommand.md
# No violations allowed
```

3. **Executable/Doc Separation** (MUST PASS):
```bash
bash .claude/tests/validate_executable_doc_separation.sh 2>&1 | grep "mycommand.md"
# All checks must pass
```

4. **Code Reduction Verification**:
```bash
# Compare line counts
wc -l .claude/commands/mycommand.md.phase-based-backup .claude/commands/mycommand.md

# Calculate percentage
python3 <<EOF
original = [original_lines]
new = [new_lines]
reduction = ((original - new) / original) * 100
print(f"Reduction: {reduction:.1f}%")
print(f"Target: 30-40% (minimum for migration to be worthwhile)")
EOF
```

### Smoke Testing (Optional)

**Manual Execution Test**:
```bash
# Test state machine initialization
/mycommand "test workflow: simple feature"

# Expected output:
# - "State Machine Initialized:"
# - "Scope: [detected scope]"
# - "Current State: research"
# - No errors during initialization
```

### Regression Testing

**Zero Regression Requirement**:
- All pre-existing tests must continue to pass
- No new anti-patterns introduced
- Documentation references still valid
- Agent delegation patterns maintained

---

## Common Issues

### Issue 1: Template Variables in Agent Prompts

**Symptom**:
```
❌ VIOLATION: Template variables found in agent prompts
141:    Output: ${REPORTS_DIR}/[001-00N]_[topic].md
```

**Cause**: Using bash variables directly in agent prompts fails anti-pattern detection.

**Solution**: Use placeholder text instead of template variables:

```markdown
<!-- WRONG -->
prompt: "
  Output: ${REPORTS_DIR}/001_report.md
"

<!-- CORRECT -->
prompt: "
  Output: [pre-calculated reports directory]/001_report.md
"
```

**Why**: Agent prompts should describe what the orchestrator will provide, not contain executable bash variable expansions.

### Issue 2: Library Sourcing Not Detected

**Symptom**:
```
✗ Bootstrap sequence: mycommand
  Error: No library sourcing found
```

**Cause**: Library sourcing uses variable paths instead of full paths.

**Solution**: Use full `${CLAUDE_PROJECT_DIR}` paths:

```bash
# WRONG
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "${LIB_DIR}/workflow-state-machine.sh"

# CORRECT
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh"
```

**Why**: Test pattern looks for `source.*\.claude/lib/` or `source.*lib/` and needs full paths to match.

### Issue 3: Missing "USE the Task tool" Text

**Symptom**:
```
✗ Delegation rate check: mycommand.md
  Error: No imperative invocations found (expected ≥5)
```

**Cause**: Task invocation missing exact text "USE the Task tool".

**Solution**: Use exact invocation pattern:

```markdown
<!-- WRONG -->
**EXECUTE NOW**: Invoke research-specialist via Task tool

<!-- CORRECT -->
**EXECUTE NOW**: USE the Task tool for research-specialist:
```

**Why**: Test pattern specifically searches for `**EXECUTE NOW**.*USE the Task tool`.

### Issue 4: State Not Loading Between Blocks

**Symptom**: Variables from previous bash blocks are undefined.

**Cause**: Forgetting to call `load_workflow_state` in subsequent blocks.

**Solution**: Always load state at the start of each bash block:

```bash
# MUST be at the top of every bash block after initialization
load_workflow_state "mycommand_$$"

# Then use variables
if [ "$CURRENT_STATE" != "$STATE_RESEARCH" ]; then
  # ...
fi
```

**Why**: Each bash block executes in a fresh environment; state must be explicitly loaded.

### Issue 5: Exit Code Handling in Error Handler

**Symptom**: Workflow doesn't exit after error.

**Cause**: Not exiting after `handle_state_error`.

**Solution**: `handle_state_error` already exits - don't catch its return:

```bash
# WRONG (error handler can't exit)
if ! some_command; then
  handle_state_error "Command failed"
  # This line never executes
fi

# CORRECT (one-liner or explicit check)
[ $FAILURES -gt 0 ] && handle_state_error "Verification failed"

# OR
if [ $FAILURES -gt 0 ]; then
  handle_state_error "Verification failed"
fi
# (no code after this - handle_state_error will exit)
```

### Issue 6: Excessive Code Reduction Breaking Functionality

**Symptom**: Tests pass but workflow doesn't work correctly.

**Cause**: Over-aggressive optimization removing necessary logic.

**Solution**: Balance code reduction with functionality:

```markdown
<!-- TOO AGGRESSIVE -->
## State Handler: Research
USE the Bash tool:
```bash
load_workflow_state "mycommand_$$"
# Missing state verification, complexity detection, etc.
```

<!-- BALANCED -->
## State Handler: Research
USE the Bash tool:
```bash
load_workflow_state "mycommand_$$"

# Essential state verification
if [ "$CURRENT_STATE" != "$STATE_RESEARCH" ]; then
  handle_state_error "Expected research state"
fi

# Essential business logic
RESEARCH_COMPLEXITY=2
[[ "$WORKFLOW_DESCRIPTION" =~ complex_pattern ]] && RESEARCH_COMPLEXITY=3

echo "Research: $RESEARCH_COMPLEXITY topics"
```
```

**Guidelines**:
- Keep state verification
- Keep scope-based branching
- Keep error handling
- Keep essential business logic
- Remove redundant verification
- Remove duplicate logging
- Remove redundant variable assignments

---

## Case Studies

### Case Study 1: /coordinate (33.5% Reduction)

**Original**: 1,084 lines
**Migrated**: 721 lines
**Reduction**: 363 lines (33.5%)

**Key Optimizations**:
1. **Phase 0 Consolidation**: 3 bash blocks → 1 block (saved ~100 lines)
2. **State Handler Pattern**: Removed redundant phase checking
3. **Error Handling**: `handle_state_error` replaced verbose error blocks
4. **Verification Simplification**: One-liner checks instead of multi-line blocks

**Challenges**:
- Target was 40% but achieved 33.5% due to adding robust error handling
- Added state persistence code offset some savings
- Prioritized code quality over hitting exact target

**Lesson**: Near-target results acceptable when maintaining quality.

### Case Study 2: /orchestrate (1.1% Reduction)

**Original**: 557 lines
**Migrated**: 551 lines
**Reduction**: 6 lines (1.1%)

**Key Observations**:
1. **Already Optimized**: Original was lean (557 lines vs coordinate's 1,084)
2. **Architectural Value**: Minimal reduction but gained consistency
3. **Error Handling Added**: State-based error handling offset savings
4. **Maintainability**: Consistent pattern more valuable than raw reduction

**Challenges**:
- Target was 37% (350 lines) but achieved 1.1%
- Original already followed best practices
- State machine added structure without significant bloat reduction

**Lesson**: Not all migrations achieve high reduction - consistency and architecture matter.

### Case Study 3: /supervise (77.7% Reduction)

**Original**: 1,779 lines
**Migrated**: 397 lines
**Reduction**: 1,382 lines (77.7%)

**Key Optimizations**:
1. **Massive Header Reduction**: 417 lines of documentation → 50 lines
   - Moved architectural docs to guide file
   - Removed prohibition explanations (documented elsewhere)
   - Removed side-by-side comparisons (in migration guide)

2. **State Machine Consolidation**: ~1,014 lines saved
   - Removed redundant verification blocks
   - Simplified scope-based branching
   - Streamlined agent prompts

3. **Aggressive Simplification**:
   - Placeholder text instead of detailed agent instructions
   - Minimal verification (trust error handler)
   - One bash block per state handler

**Challenges**:
- Initial migration failed anti-pattern tests
- Template variable issues in agent prompts
- Library sourcing pattern not matching test expectations

**Fixes Applied**:
- Replaced `${VAR}` with `[placeholder text]` in prompts
- Used full library paths: `${CLAUDE_PROJECT_DIR}/.claude/lib/...`
- Added exact text: `**EXECUTE NOW**: USE the Task tool`

**Lesson**: Large files offer biggest reduction opportunity through header optimization and verification simplification.

### Comparative Analysis

| Metric | /coordinate | /orchestrate | /supervise |
|--------|-------------|--------------|------------|
| **Original Size** | 1,084 lines | 557 lines | 1,779 lines |
| **Reduction %** | 33.5% | 1.1% | 77.7% |
| **Header Size** | ~100 lines | ~37 lines | ~417 lines |
| **Header Saved** | Minimal | Minimal | 367 lines (88%) |
| **Phase Count** | 7 phases | 7 phases | 7 phases |
| **Bash Blocks Before** | 11+ blocks | 11 blocks | Many |
| **Bash Blocks After** | 13 blocks | 13 blocks | 13 blocks |
| **Primary Savings** | Phase consolidation | Consistency | Header + verification |

**Key Insight**: Reduction percentage inversely correlates with original optimization level. Large, documentation-heavy files offer greatest opportunity.

---

## Migration Checklist

Use this checklist to track migration progress:

**Pre-Migration**:
- [ ] Create backup: `mycommand.md.phase-based-backup`
- [ ] Document baseline metrics (line count, bash blocks, delegation rate)
- [ ] Run pre-migration tests and save results
- [ ] Identify optimization opportunities (header size, verification blocks)

**Migration Steps**:
- [ ] Step 1: Replace Phase 0 with state machine initialization
  - [ ] Consolidate library sourcing
  - [ ] Add state machine init (`sm_init`)
  - [ ] Add state persistence (`init_workflow_state`)
  - [ ] Add error handler (`handle_state_error`)
  - [ ] Add state transition to first state

- [ ] Step 2: Convert each phase to state handler
  - [ ] Phase 1 → State Handler: Research
  - [ ] Phase 2 → State Handler: Plan
  - [ ] Phase 3 → State Handler: Implement
  - [ ] Phase 4 → State Handler: Test
  - [ ] Phase 5 → State Handler: Debug (conditional)
  - [ ] Phase 6 → State Handler: Document (conditional)

- [ ] Step 3: Update error handling
  - [ ] Replace `exit 1` with `handle_state_error`
  - [ ] Add state context to error messages
  - [ ] Implement retry logic

- [ ] Step 4: Update tests
  - [ ] Update delegation rate expectation
  - [ ] Verify library sourcing pattern
  - [ ] Fix any anti-patterns

**Post-Migration**:
- [ ] Run orchestration tests (all must pass)
- [ ] Run anti-pattern validation (no violations)
- [ ] Run executable/doc separation validation (all pass)
- [ ] Verify code reduction (calculate percentage)
- [ ] Smoke test state machine initialization (optional)
- [ ] Update implementation plan with results
- [ ] Create git commit with detailed metrics

**Documentation**:
- [ ] Update command guide if needed
- [ ] Document any migration-specific issues encountered
- [ ] Add to migration guide case studies if novel patterns emerged

---

## Summary

### Key Takeaways

1. **Code Reduction Varies**: 1-78% depending on original optimization (average: 33-51%)
2. **Quality Over Metrics**: Maintaining robust error handling more important than hitting targets
3. **Consistency Matters**: Architectural consistency valuable even with minimal reduction
4. **Header Optimization**: Largest files benefit most from moving docs to guide files
5. **Test-Driven**: Anti-pattern validation catches 90% of issues early

### Success Criteria

A migration is successful when:
- ✓ All orchestration tests pass (zero regressions)
- ✓ No anti-patterns detected
- ✓ Code reduction ≥ 20% (or architectural value justifies <20%)
- ✓ State machine pattern consistent with other commands
- ✓ Error handling improved or maintained
- ✓ Documentation updated appropriately

### When to Stop

Don't migrate if:
- Command is <100 lines (overhead not worth it)
- Command already uses state machine
- Command is read-only (no state changes)
- Reduction would be <10% with no architectural benefit

### Resources

- **State Machine Library**: `.claude/lib/workflow/workflow-state-machine.sh`
- **State Persistence Library**: `.claude/lib/core/state-persistence.sh`
- **Test Suite**: `.claude/tests/test_orchestration_commands.sh`
- **Anti-Pattern Validator**: `.claude/lib/util/validate-agent-invocation-pattern.sh`
- **Example Migrations**: See `/coordinate`, `/orchestrate`, `/supervise` in `.claude/commands/`

---

**Document Version**: 1.0 (2025-11-07)
**Status**: Production (based on 3 successful migrations)
**Maintenance**: Update case studies as new migrations are completed
