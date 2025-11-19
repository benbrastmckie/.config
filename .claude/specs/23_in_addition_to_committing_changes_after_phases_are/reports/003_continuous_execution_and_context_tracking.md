# Continuous Execution and Context Window Tracking

## Metadata
- **Date**: 2025-11-17
- **Topic**: Continuous Execution Patterns and Context Budget Management
- **Research Complexity**: 3
- **Related Files**:
  - `/home/benjamin/.config/.claude/docs/workflows/context-budget-management.md`
  - `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh`
  - `/home/benjamin/.config/.claude/docs/concepts/patterns/checkpoint-recovery.md`

## Executive Summary

Context window tracking is a mature pattern in the codebase with comprehensive documentation and layered pruning strategies. Continuous execution patterns exist in /implement but NOT in /build. Context estimation utilities are documented but not fully implemented as reusable libraries.

**Key Findings**:
1. Target context budget: <30% (7,500 tokens of 25,000)
2. Layered context architecture: 4 layers with 95-97% pruning
3. Checkpoint recovery supports resume after interruption
4. Continuous execution NOT currently in /build (single-pass only)
5. User confirmation prompts NOT currently implemented
6. Context estimation uses 4-character-per-token approximation

## Context Budget Management Architecture

### Layered Context Strategy (context-budget-management.md lines 82-204)

**Layer 1: Permanent Context** (500-1,000 tokens, 4%)
- Command prompt skeleton (200 tokens)
- Project standards metadata (150 tokens)
- Workflow scope description (100 tokens)
- Library function registry (150 tokens)
- **Retention**: Keep throughout entire workflow

**Example**:
```markdown
# Layer 1: Permanent Context
## Workflow Scope
- Description: "Implement JWT authentication"
- Scope: full-implementation
- Target: <30% context usage

## Project Standards
- Language: JavaScript (Node.js)
- Test Command: npm test
- Code Style: 2 spaces, camelCase

## Library Functions Loaded
- state-persistence.sh: ✓
- checkpoint-utils.sh: ✓

Total: ~600 tokens
```

**Layer 2: Phase-Scoped Context** (2,000-4,000 tokens, 12%)
- Current phase execution state (500 tokens)
- Wave tracking for parallel execution (300 tokens/wave)
- Active artifact paths (200 tokens)
- Current phase instructions (1,000-2,000 tokens)
- **Retention**: Prune when phase completes or wave finishes

**Example**:
```markdown
# Layer 2: Phase-Scoped Context (Phase 3)
## Current Phase: Implementation
### Wave 1 Execution
- Phases in wave: [1, 2]
- Phase 1 status: in_progress
- Phase 2 status: in_progress

### Active Artifacts
- Plan: specs/084_jwt/plans/001_jwt_plan.md
- Working dir: /project/src/auth/

Total: ~2,300 tokens
{Pruned when Wave 1 completes}
```

**Layer 3: Metadata** (200-300 tokens per artifact, 6% total)
- Report metadata (title, 50-word summary, key findings)
- Plan metadata (complexity, phase count, time estimate)
- Implementation metadata (files changed, tests status)
- **Retention**: Keep metadata only, prune full content

**Example**:
```markdown
# Layer 3: Metadata
## Report 1: OAuth Flow Patterns
- Path: specs/084_jwt/reports/001_oauth.md
- Summary: "OAuth 2.0 authorization code flow provides secure authentication..."
- Key Findings: ["Authorization code most secure", "Refresh token rotation"]
- Token Count: 250 tokens

## Report 2: JWT Strategies
- Summary: "JWT tokens contain claims signed with secret key..."
- Token Count: 250 tokens

Total: ~500 tokens (2 reports)
```

**Layer 4: Transient** (0 tokens after pruning)
- Full agent responses (5,000-10,000 tokens/agent) - PRUNED
- Intermediate calculations (1,000-2,000 tokens) - PRUNED
- Verbose diagnostic logs (500-1,000 tokens) - PRUNED
- **Retention**: Prune immediately after metadata extraction

**Reduction**: 95-97% per artifact

### Budget Allocation Strategies (context-budget-management.md lines 206-298)

**Strategy 1: Fixed Allocation** (Simple)

**Full-Implementation Workflow** (6 phases):
```
Phase 0 (Location): 500 tokens
Phase 1 (Research): 900 tokens (3 × 300 metadata)
Phase 2 (Planning): 800 tokens
Phase 3 (Implementation): 2,000 tokens
Phase 4 (Testing): 400 tokens
Phase 6 (Documentation): 300 tokens
─────────────────────────────────────
Total: 4,900 tokens (19.6% of budget)
Buffer: 2,600 tokens (10.4% reserve)
```

**Advantages**:
- Simple to implement
- Predictable usage
- Easy to debug

**Disadvantages**:
- May over-allocate simple phases
- May under-allocate complex phases

**Strategy 2: Dynamic Allocation** (Adaptive)

**Algorithm**:
```bash
# Calculate complexity scores
PHASE_1_COMPLEXITY=5  # Simple
PHASE_2_COMPLEXITY=8  # Moderate
PHASE_3_COMPLEXITY=12 # Complex
TOTAL_COMPLEXITY=25

# Total budget
TOTAL_BUDGET=7500  # 30% of 25,000

# Allocate proportionally
PHASE_1_BUDGET=$(( TOTAL_BUDGET * PHASE_1_COMPLEXITY / TOTAL_COMPLEXITY ))
# Result: 1,500 tokens

PHASE_2_BUDGET=$(( TOTAL_BUDGET * PHASE_2_COMPLEXITY / TOTAL_COMPLEXITY ))
# Result: 2,400 tokens

PHASE_3_BUDGET=$(( TOTAL_BUDGET * PHASE_3_COMPLEXITY / TOTAL_COMPLEXITY ))
# Result: 3,600 tokens
```

**Advantages**:
- Optimal allocation based on complexity
- Prevents under-allocation
- Maximizes budget utilization

**Disadvantages**:
- Requires complexity calculation upfront
- More complex to implement

**Strategy 3: Reserve Allocation** (Safe)

**Distribution**:
```
Core Phases (0-4, 6): 60% (4,500 tokens)
Debugging Reserve: 20% (1,500 tokens)
Overflow Buffer: 20% (1,500 tokens)
─────────────────────────────────────
Total: 7,500 tokens (30% budget)
```

**Advantages**:
- Safety margin for unexpected issues
- Debugging fully budgeted
- Prevents hard failures

**Disadvantages**:
- May under-utilize if no debugging needed

### Pruning Policies (context-budget-management.md lines 299-371)

**Aggressive Pruning** (Multi-Agent Workflows)

**When**: Workflows with >3 phases

**Rules**:
1. Prune full agent responses immediately after metadata extraction
2. Prune completed wave context before next wave
3. Prune phase-scoped context when phase completes
4. Retain only metadata and artifact paths

**Implementation**:
```bash
# After research agent completes
FULL_RESPONSE=$(cat agent_output.txt)  # 5,000 tokens
METADATA=$(extract_report_metadata "$REPORT_PATH")  # 250 tokens

prune_subagent_output "$FULL_RESPONSE" "$METADATA"  # Removes 4,750 tokens

# After Wave 1 completes
prune_phase_output "Wave 1" "aggressive"  # Removes all transient data

# Retention: Only metadata (250 tokens per report)
```

**Savings**: 95-97% per artifact

**Moderate Pruning** (Linear Workflows)

**When**: Simple workflows with sequential phases

**Rules**:
1. Keep full agent responses until phase completes
2. Prune full content when next phase starts
3. Retain metadata + phase summary (500-800 tokens)

**Savings**: 85-90% per artifact

**Minimal Pruning** (Debugging Workflows)

**When**: Debugging workflows needing full context

**Rules**:
1. Keep full agent responses throughout workflow
2. Only prune after workflow completion
3. Retain all diagnostic logs

**Savings**: 20-30% (minimal pruning)

## Context Estimation Techniques

### Token Estimation Formula (context-budget-management.md lines 422-438)

**Approximation**: 1 token ≈ 4 characters

**Implementation**:
```bash
estimate_markdown_tokens() {
  local content="$1"
  local char_count=${#content}
  echo $(( char_count / 4 ))
}

# Example
METADATA="Title: OAuth Patterns\nSummary: OAuth 2.0 provides..."
TOKEN_ESTIMATE=$(estimate_markdown_tokens "$METADATA")
echo "Estimated tokens: $TOKEN_ESTIMATE"
```

**Accuracy**: ±20% margin of error

**Alternative**: Word-based estimation (1 token ≈ 0.75 words)

### Context Usage Monitoring (context-budget-management.md lines 373-421)

**Real-Time Tracking**:
```bash
# After each phase completes
CURRENT_TOKENS=$(estimate_context_tokens)
TOTAL_BUDGET=7500  # 30% target
PERCENTAGE=$(( CURRENT_TOKENS * 100 / TOTAL_BUDGET ))

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Context Budget After Phase $N"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Current usage: $CURRENT_TOKENS tokens ($PERCENTAGE% of budget)"
echo "Budget remaining: $(( TOTAL_BUDGET - CURRENT_TOKENS )) tokens"
echo ""

if [ $CURRENT_TOKENS -gt $TOTAL_BUDGET ]; then
  echo "⚠️  WARNING: Budget exceeded!"
  echo "Action: Apply aggressive pruning or reduce scope"
fi
```

**Threshold Alerts**:
```bash
BUDGET_WARN_THRESHOLD=5625  # 75% of budget
BUDGET_CRITICAL_THRESHOLD=7125  # 95% of budget

if [ $CURRENT_TOKENS -gt $BUDGET_CRITICAL_THRESHOLD ]; then
  echo "🚨 CRITICAL: Context at 95% of budget"
  prune_all_transient_data "aggressive"

elif [ $CURRENT_TOKENS -gt $BUDGET_WARN_THRESHOLD ]; then
  echo "⚠️  WARNING: Context at 75% of budget"
  echo "Consider pruning non-critical data"
fi
```

### State File Size Tracking

**Implementation**:
```bash
estimate_context_tokens() {
  local total_chars=0

  # Count state file sizes
  for state_file in ~/.claude/data/state/*; do
    if [ -f "$state_file" ]; then
      total_chars=$((total_chars + $(wc -c < "$state_file")))
    fi
  done

  # Count checkpoint data
  if [ -f "$CHECKPOINT_FILE" ]; then
    total_chars=$((total_chars + $(wc -c < "$CHECKPOINT_FILE")))
  fi

  echo $((total_chars / 4))
}

estimate_context_percentage() {
  local current_tokens=$(estimate_context_tokens)
  local total_budget=25000  # Claude Sonnet baseline
  echo $(( current_tokens * 100 / total_budget ))
}
```

**Accuracy**: High for state persistence overhead, low for active context

**Limitation**: Does not track active conversation context, only persisted state

## Continuous Execution Patterns

### /implement Command Pattern (implement.md lines 113-202)

**Current Implementation**:
```bash
# Phase execution loop
for CURRENT_PHASE in $(seq "$STARTING_PHASE" "$TOTAL_PHASES"); do
  echo "PROGRESS: Starting Phase $CURRENT_PHASE"

  # Extract phase information
  PHASE_CONTENT=$(.claude/lib/parse-adaptive-plan.sh extract_phase "$PLAN_FILE" "$CURRENT_PHASE")
  PHASE_NAME=$(echo "$PHASE_CONTENT" | grep "^### Phase $CURRENT_PHASE:" | sed 's/^### Phase [0-9]*: //')

  # Agent delegation based on complexity
  if [ "$COMPLEXITY_SCORE" -lt 3 ]; then
    # Direct execution
    echo "PROGRESS: Direct execution (complexity: $COMPLEXITY_SCORE)"
  else
    # Agent delegation
    echo "PROGRESS: Delegating to code-writer agent"
  fi

  # Run tests
  if [ -n "$TEST_COMMAND" ]; then
    TEST_OUTPUT=$($TEST_COMMAND 2>&1)
    TEST_EXIT_CODE=$?

    if [ $TEST_EXIT_CODE -ne 0 ]; then
      # Handle test failures with tiered recovery
      DEBUG_REPORT_PATH=$(invoke_debug "$CURRENT_PHASE" "$ERROR_TYPE" "$PLAN_FILE")

      # Present user choices
      echo "Test failure detected. Choose: (r)evise, (c)ontinue, (s)kip, (a)bort"
    fi
  fi

  # Update plan hierarchy
  # Invoke spec-updater agent

  # Create git commit
  git add .
  git commit -m "feat: implement Phase $CURRENT_PHASE - $PHASE_NAME"

  # Save checkpoint
  save_checkpoint "implement" "{\"plan_path\":\"$PLAN_FILE\",\"current_phase\":$((CURRENT_PHASE + 1))}"
done
```

**Key Features**:
1. For-loop over all phases
2. Checkpoint save after each phase
3. Test failure handling with user choices
4. Plan hierarchy updates
5. Git commits per phase

**Missing**:
1. Context window tracking
2. 75% limit check
3. User confirmation on limit

### Checkpoint Recovery Pattern (checkpoint-utils.sh)

**Checkpoint Structure**:
```json
{
  "workflow_description": "build",
  "plan_path": "/path/to/plan.md",
  "current_phase": 3,
  "total_phases": 7,
  "status": "in_progress",
  "tests_passing": true,
  "timestamp": "2025-11-17T10:30:00Z"
}
```

**Save Checkpoint**:
```bash
save_checkpoint() {
  local workflow="$1"
  local checkpoint_data="$2"

  CHECKPOINT_DIR="${HOME}/.claude/data/checkpoints"
  mkdir -p "$CHECKPOINT_DIR"

  CHECKPOINT_FILE="$CHECKPOINT_DIR/${workflow}_checkpoint.json"
  echo "$checkpoint_data" > "$CHECKPOINT_FILE"
}
```

**Load Checkpoint**:
```bash
load_checkpoint() {
  local workflow="$1"

  CHECKPOINT_FILE="${HOME}/.claude/data/checkpoints/${workflow}_checkpoint.json"
  if [ -f "$CHECKPOINT_FILE" ]; then
    cat "$CHECKPOINT_FILE"
    return 0
  fi

  return 1
}
```

**Delete Checkpoint**:
```bash
delete_checkpoint() {
  local workflow="$1"

  CHECKPOINT_FILE="${HOME}/.claude/data/checkpoints/${workflow}_checkpoint.json"
  rm -f "$CHECKPOINT_FILE"
}
```

**Resume Logic** (build.md lines 88-125):
```bash
# Auto-resume if no plan file specified
if [ -z "$PLAN_FILE" ]; then
  # Strategy 1: Check checkpoint
  CHECKPOINT_DATA=$(load_checkpoint "build" 2>/dev/null || echo "")

  if [ -n "$CHECKPOINT_DATA" ]; then
    CHECKPOINT_FILE="${HOME}/.claude/data/checkpoints/build_checkpoint.json"

    # Verify checkpoint age (<24 hours)
    CHECKPOINT_AGE_HOURS=$(( ($(date +%s) - $(stat -c %Y "$CHECKPOINT_FILE")) / 3600 ))

    if [ "$CHECKPOINT_AGE_HOURS" -lt 24 ]; then
      PLAN_FILE=$(echo "$CHECKPOINT_DATA" | jq -r '.plan_path')
      STARTING_PHASE=$(echo "$CHECKPOINT_DATA" | jq -r '.current_phase')
      echo "✓ Auto-resuming from checkpoint: Phase $STARTING_PHASE"
    fi
  fi
fi
```

**Checkpoint Age Limit**: 24 hours (configurable)

## User Confirmation Patterns

### AskUserQuestion Tool (Available in Commands)

**Capability**: Commands can prompt user for input during execution

**Not Currently Used** in /build command

**Example Usage**:
```markdown
AskUserQuestion {
  questions: [
    {
      question: "Context usage at 75%. Continue execution?",
      header: "Context Limit",
      options: [
        {
          label: "Continue",
          description: "Continue execution, may exceed 75% limit"
        },
        {
          label: "Stop and Save",
          description: "Stop execution and save checkpoint for later resume"
        }
      ],
      multiSelect: false
    }
  ]
}
```

**Response Handling**:
```bash
# Extract user choice from AskUserQuestion response
USER_CHOICE=$(echo "$QUESTION_RESPONSE" | jq -r '.answers.question_1')

case "$USER_CHOICE" in
  "Continue")
    echo "Continuing execution..."
    CONTINUE_EXECUTION=true
    ;;
  "Stop and Save")
    echo "Stopping execution, checkpoint saved"
    save_checkpoint "build" "{\"plan_path\":\"$PLAN_FILE\",\"current_phase\":$CURRENT_PHASE}"
    exit 0
    ;;
esac
```

### Interactive Prompt Pattern (bash read)

**Simple Text Prompt**:
```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Context Budget Alert"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Current context usage: $CURRENT_CONTEXT_PERCENT% of 75% limit"
echo "Completed phases: $CURRENT_PHASE / $TOTAL_PHASES"
echo "Remaining phases: $(($TOTAL_PHASES - $CURRENT_PHASE))"
echo ""
echo "Options:"
echo "  (c) Continue execution (may exceed limit)"
echo "  (s) Stop and save checkpoint"
echo "  (f) Force complete with aggressive pruning"
echo ""
read -p "Choose action [c/s/f]: " USER_CHOICE

case "$USER_CHOICE" in
  c|C)
    echo "Continuing execution..."
    ;;
  s|S)
    echo "Stopping execution"
    save_checkpoint "build" "{\"plan_path\":\"$PLAN_FILE\",\"current_phase\":$CURRENT_PHASE}"
    exit 0
    ;;
  f|F)
    echo "Forcing completion with aggressive pruning"
    AGGRESSIVE_PRUNING=true
    ;;
  *)
    echo "Invalid choice, stopping"
    exit 1
    ;;
esac
```

**Pros**: Simple, works in all terminals
**Cons**: Blocks execution, requires terminal input

## Implementation Recommendations for /build

### Recommendation 1: Add Context Estimation Library

**Location**: /home/benjamin/.config/.claude/lib/context-estimation.sh

**Implementation**:
```bash
#!/usr/bin/env bash
# context-estimation.sh
#
# Context window usage estimation utilities

set -e

# Estimate context tokens from state files
estimate_context_tokens() {
  local total_chars=0

  # Count state file sizes
  if [ -d "${HOME}/.claude/data/state" ]; then
    for state_file in "${HOME}/.claude/data/state"/*; do
      if [ -f "$state_file" ]; then
        total_chars=$((total_chars + $(wc -c < "$state_file" 2>/dev/null || echo "0")))
      fi
    done
  fi

  # Count checkpoint data
  if [ -d "${HOME}/.claude/data/checkpoints" ]; then
    for checkpoint_file in "${HOME}/.claude/data/checkpoints"/*.json; do
      if [ -f "$checkpoint_file" ]; then
        total_chars=$((total_chars + $(wc -c < "$checkpoint_file" 2>/dev/null || echo "0")))
      fi
    done
  fi

  # Convert chars to tokens (1 token ≈ 4 chars)
  echo $((total_chars / 4))
}

# Estimate context percentage of total budget
estimate_context_percentage() {
  local total_budget="${1:-25000}"  # Default: Claude Sonnet baseline

  local current_tokens=$(estimate_context_tokens)
  echo $(( current_tokens * 100 / total_budget ))
}

# Check if context exceeds threshold
check_context_threshold() {
  local threshold_percent="${1:-75}"  # Default: 75%
  local total_budget="${2:-25000}"

  local current_percent=$(estimate_context_percentage "$total_budget")

  if [ "$current_percent" -ge "$threshold_percent" ]; then
    return 0  # Threshold exceeded
  else
    return 1  # Under threshold
  fi
}

# Print context usage report
print_context_report() {
  local phase_num="$1"
  local total_budget="${2:-25000}"
  local target_percent="${3:-30}"

  local current_tokens=$(estimate_context_tokens)
  local current_percent=$(estimate_context_percentage "$total_budget")
  local target_tokens=$((total_budget * target_percent / 100))
  local remaining_tokens=$((target_tokens - current_tokens))

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Context Budget After Phase $phase_num"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Current usage: $current_tokens tokens ($current_percent%)"
  echo "Target budget: $target_tokens tokens ($target_percent%)"
  echo "Remaining: $remaining_tokens tokens"
  echo ""

  if [ "$current_percent" -ge 95 ]; then
    echo "🚨 CRITICAL: Near budget limit!"
  elif [ "$current_percent" -ge 75 ]; then
    echo "⚠️  WARNING: Approaching budget limit"
  else
    echo "✓ Within budget"
  fi
  echo ""
}

export -f estimate_context_tokens
export -f estimate_context_percentage
export -f check_context_threshold
export -f print_context_report
```

### Recommendation 2: Add Continuous Execution Loop to /build

**Location**: /build.md - Restructure Parts 3-5 into loop

**Implementation**:
```bash
# Part 3-5: Continuous Phase Execution Loop

CONTEXT_LIMIT_PERCENT=75
CURRENT_PHASE=$STARTING_PHASE

# Source context estimation library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/context-estimation.sh"

while [ "$CURRENT_PHASE" -le "$TOTAL_PHASES" ]; do
  echo "=== Phase $CURRENT_PHASE Execution ==="
  echo ""

  # Check context before starting phase
  if check_context_threshold "$CONTEXT_LIMIT_PERCENT"; then
    # Context limit reached, prompt user
    prompt_user_continuation
  fi

  # Execute phase implementation (existing Part 3 logic)
  execute_phase_implementation "$CURRENT_PHASE"

  # Execute phase testing (existing Part 4 logic)
  execute_phase_testing "$CURRENT_PHASE"

  # Conditional branching (existing Part 5 logic)
  if [ "$TESTS_PASSED" = "false" ]; then
    execute_phase_debug "$CURRENT_PHASE"
  else
    execute_phase_documentation "$CURRENT_PHASE"
  fi

  # Update plan hierarchy with [COMPLETE] markers
  update_plan_after_phase "$CURRENT_PHASE"

  # Print context report
  print_context_report "$CURRENT_PHASE" 25000 30

  # Advance to next phase
  CURRENT_PHASE=$((CURRENT_PHASE + 1))
done

# All phases complete
sm_transition "$STATE_COMPLETE"
echo "=== Build Complete ==="
```

### Recommendation 3: Add User Confirmation Prompt

**Location**: New function in /build.md

**Implementation**:
```bash
prompt_user_continuation() {
  local current_percent=$(estimate_context_percentage)
  local remaining_phases=$((TOTAL_PHASES - CURRENT_PHASE + 1))

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Context Budget Alert"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Current context usage: $current_percent% of 75% limit"
  echo "Completed phases: $((CURRENT_PHASE - 1)) / $TOTAL_PHASES"
  echo "Remaining phases: $remaining_phases"
  echo ""
  echo "Continuing may exceed context limits and cause errors."
  echo ""
  echo "Options:"
  echo "  (c) Continue execution (may exceed limit)"
  echo "  (s) Stop and save checkpoint (resume later)"
  echo "  (f) Force complete with aggressive pruning"
  echo ""
  read -p "Choose action [c/s/f]: " USER_CHOICE

  case "$USER_CHOICE" in
    c|C)
      echo "Continuing execution..."
      ;;
    s|S)
      echo "Stopping execution, saving checkpoint"
      save_checkpoint "build" "{\"plan_path\":\"$PLAN_FILE\",\"current_phase\":$CURRENT_PHASE}"
      echo ""
      echo "Resume with: /build $PLAN_FILE $CURRENT_PHASE"
      exit 0
      ;;
    f|F)
      echo "Forcing completion with aggressive pruning"
      # Enable aggressive pruning mode
      export AGGRESSIVE_PRUNING=true
      # Prune all non-essential state
      prune_all_transient_data
      ;;
    *)
      echo "Invalid choice, stopping execution"
      save_checkpoint "build" "{\"plan_path\":\"$PLAN_FILE\",\"current_phase\":$CURRENT_PHASE}"
      exit 1
      ;;
  esac
  echo ""
}
```

### Recommendation 4: Extract Phase Execution Functions

**Location**: New functions in /build.md

**Purpose**: Enable loop-based execution without code duplication

**Implementation**:
```bash
execute_phase_implementation() {
  local phase_num="$1"

  sm_transition "$STATE_IMPLEMENT"

  # Agent invocation (existing Part 3 logic)
  Task {
    subagent_type: "general-purpose"
    description: "Execute implementation for phase $phase_num"
    prompt: |
      Read and follow ALL behavioral guidelines from:
      ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

      Execute Phase $phase_num from plan: $PLAN_FILE
  }

  # Verification (existing Part 3 logic)
  echo "Verifying implementation completion..."
  if git diff --quiet && git diff --cached --quiet; then
    warn "No changes detected"
  fi

  # State persistence
  append_workflow_state "CURRENT_PHASE" "$phase_num"
  save_completed_states_to_state
}

execute_phase_testing() {
  local phase_num="$1"

  sm_transition "$STATE_TEST"

  # Test execution (existing Part 4 logic)
  TEST_COMMAND=$(grep -oE "(npm test|pytest)" "$PLAN_FILE" | head -1)

  if [ -n "$TEST_COMMAND" ]; then
    TEST_OUTPUT=$($TEST_COMMAND 2>&1)
    TEST_EXIT_CODE=$?

    if [ $TEST_EXIT_CODE -ne 0 ]; then
      TESTS_PASSED=false
    else
      TESTS_PASSED=true
    fi
  else
    TESTS_PASSED=true
  fi

  # State persistence
  append_workflow_state "TESTS_PASSED" "$TESTS_PASSED"
  save_completed_states_to_state
}

execute_phase_debug() {
  local phase_num="$1"

  sm_transition "$STATE_DEBUG"

  # Debug execution (existing Part 5 logic)
  Task {
    subagent_type: "debug-analyst"
    description: "Debug phase $phase_num failures"
    prompt: |
      Read and follow behavioral guidelines from:
      ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

      Debug phase $phase_num test failures
      Test exit code: $TEST_EXIT_CODE
  }
}

execute_phase_documentation() {
  local phase_num="$1"

  sm_transition "$STATE_DOCUMENT"

  # Documentation (existing Part 5 logic)
  if git diff --name-only HEAD~1 | grep -qE '\.(py|js|ts)$'; then
    echo "NOTE: Code files modified, documentation recommended"
  fi
}

update_plan_after_phase() {
  local phase_num="$1"

  # Update plan hierarchy with spec-updater
  Task {
    subagent_type: "general-purpose"
    description: "Update plan hierarchy after phase completion"
    prompt: |
      Read and follow behavioral guidelines from:
      ${CLAUDE_PROJECT_DIR}/.claude/agents/spec-updater.md

      Update plan hierarchy after Phase $phase_num completion
      Plan: $PLAN_FILE
      Phase: $phase_num
  }

  # Add [COMPLETE] marker
  sed -i "s/^### Phase ${phase_num}:/### Phase ${phase_num}: [COMPLETE]/" "$PLAN_FILE"

  # Git commit
  git add "$PLAN_FILE"
  git commit -m "feat: complete Phase $phase_num

Plan updated with [COMPLETE] marker and checkboxes

Co-Authored-By: Claude <noreply@anthropic.com>"

  # Save checkpoint
  save_checkpoint "build" "{\"plan_path\":\"$PLAN_FILE\",\"current_phase\":$((phase_num + 1))}"
}
```

## Performance Considerations

### Context Overhead per Phase

**Additional Context**:
- Checkpoint data: ~200 tokens
- State persistence: ~100 tokens
- Plan hierarchy updates: ~50 tokens
- Context tracking: ~50 tokens

**Total**: ~400 tokens per phase

**6-Phase Workflow**: 400 × 6 = 2,400 tokens (9.6% of budget)

**Conclusion**: Continuous execution overhead acceptable within 30% budget

### Pruning Effectiveness

**Without Pruning**:
- Phase 1: 5,000 tokens
- Phase 2: 3,000 tokens
- Phase 3: 4,000 tokens
- Total: 12,000 tokens (48% of budget) ❌ Exceeds target

**With Aggressive Pruning**:
- Phase 1: 250 tokens (metadata only)
- Phase 2: 300 tokens (metadata only)
- Phase 3: 400 tokens (metadata only)
- Total: 950 tokens (3.8% of budget) ✓ Within target

**Reduction**: 92% (12,000 → 950 tokens)

## Risk Assessment

### High Risk: Context Estimation Inaccuracy

**Probability**: 40%
**Impact**: High (may exceed limits unexpectedly)
**Mitigation**:
- Use conservative 70% threshold instead of 75%
- Implement emergency pruning at 90%
- Test estimation accuracy across workflows

### Medium Risk: User Interruption Friction

**Probability**: 25%
**Impact**: Medium (workflow paused, user must respond)
**Mitigation**:
- Clear resume instructions
- Reliable checkpoint recovery
- Auto-resume within 24 hours

### Low Risk: Checkpoint Corruption

**Probability**: 10%
**Impact**: Medium (cannot resume, must restart)
**Mitigation**:
- Atomic file writes
- Checkpoint validation on load
- Multiple checkpoint slots (keep last 3)

## Conclusion

Context window tracking and continuous execution patterns are well-documented with:
1. Layered context architecture (4 layers, 95% reduction)
2. Budget allocation strategies (fixed/dynamic/reserve)
3. Checkpoint recovery (24-hour auto-resume)
4. Pruning policies (aggressive/moderate/minimal)

**Integration into /build** requires:
1. Context estimation library (context-estimation.sh)
2. Continuous execution loop (phase iteration)
3. User confirmation prompts (at 75% threshold)
4. Phase execution functions (refactored from Parts 3-5)

**Estimated Implementation Effort**: 6-8 hours
- Context estimation library: 2 hours
- Continuous execution loop: 3 hours
- User confirmation prompts: 1 hour
- Function extraction: 1 hour
- Testing and validation: 2 hours

**Expected Outcome**: /build command with continuous phase execution until 75% context usage, with user confirmation and reliable checkpoint recovery.
