# Stage 3: Consolidate Utility Libraries

## Metadata
- **Stage Number**: 3
- **Parent Phase**: phase_7_directory_modularization
- **Phase Number**: 7
- **Objective**: Split oversized utilities, eliminate duplicates, bundle always-sourced utilities
- **Complexity**: High
- **Status**: PENDING
- **Estimated Time**: 6-8 hours

## Overview

This stage addresses utility bloat and circular dependencies through four strategic consolidations: (1) splitting artifact-operations.sh (1,585 lines, largest utility) into three focused modules; (2) creating base-utils.sh with common error() function to eliminate 4 duplicates; (3) bundling planning utilities (1,143 lines always sourced together) into plan-core-bundle.sh; (4) consolidating loggers (adaptive-planning-logger + conversion-logger, 706 lines total) into unified-logger.sh.

The consolidations follow the proven modularization pattern from convert-docs (split by responsibility) and eliminate the circular dependency workarounds currently forcing utilities to duplicate error() functions. All changes maintain backward compatibility through a deprecation period.

## Detailed Tasks

### Task 1: Extract Adaptive Planning Documentation (200 lines)

**Objective**: Extract adaptive planning features, replan triggers, complexity thresholds, and loop prevention documentation to a shared file.

**Implementation Steps**:

1. **Locate adaptive planning content** in implement.md:
```bash
cd /home/benjamin/.config/.claude/commands
grep -n "^## Adaptive Planning\|Adaptive Planning Features\|Replan\|Complexity" implement.md
```

Expected sections:
- Line 17-57: "## Adaptive Planning Features" (40 lines - header section)
- Scattered throughout: Complexity evaluation, replan triggers, loop prevention

2. **Identify all adaptive planning references**:
```bash
# Find all mentions of adaptive planning concepts
grep -n "adaptive\|replan\|complexity.*score\|loop prevention\|trigger" implement.md -i
```

3. **Create shared/adaptive-planning.md**:
```bash
cat > shared/adaptive-planning.md << 'EOF'
# Adaptive Planning Guide

**Part of**: `/implement`, `/revise` commands
**Purpose**: Intelligent plan revision capabilities with automatic trigger detection
**Usage**: Referenced for replan triggers, complexity thresholds, and loop prevention strategies

## Overview

Adaptive planning enables the `/implement` command to detect when replanning is needed during execution and automatically invoke `/revise --auto-mode` to adjust the plan structure. This document defines the trigger conditions, complexity thresholds, loop prevention mechanisms, and integration with checkpoint management.

## Automatic Triggers

### Trigger Types

The system detects three categories of replanning triggers:

**1. Complexity Detection Trigger**

Activated when a phase proves more complex than initially estimated:

```yaml
Conditions:
  - Hybrid complexity score > 8.0 (calculated during Step 1.5)
  - OR task count > 10 tasks in a single phase
  - AND phase not already expanded

Threshold Configuration (from CLAUDE.md):
  COMPLEXITY_THRESHOLD_HIGH: 8.0
  TASK_COUNT_THRESHOLD: 10

Action:
  trigger_type: "expand_phase"
  revision_prompt: "Phase {N} complexity score {score} exceeds threshold {threshold}. Recommend expanding to separate file."
  auto_mode: true
```

**Detection Implementation**:
```bash
# After hybrid complexity evaluation (Step 1.5)
source "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh"
COMPLEXITY_SCORE=$(hybrid_complexity_evaluation "$PHASE_NAME" "$TASK_LIST" "$PLAN_FILE" | jq -r '.final_score')
TASK_COUNT=$(echo "$TASK_LIST" | grep -c "^- \[ \]")

if [ $(echo "$COMPLEXITY_SCORE > $COMPLEXITY_THRESHOLD_HIGH" | bc) -eq 1 ] || [ $TASK_COUNT -gt $TASK_COUNT_THRESHOLD ]; then
  # Check if phase already expanded
  IS_EXPANDED=$(is_phase_expanded "$PLAN_PATH" "$CURRENT_PHASE")

  if [ "$IS_EXPANDED" = "false" ]; then
    log_complexity_trigger "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "$TASK_COUNT"
    trigger_adaptive_replan "expand_phase" "$CURRENT_PHASE"
  fi
fi
```

**2. Test Failure Pattern Trigger**

Activated when repeated test failures suggest missing prerequisites or flawed plan structure:

```yaml
Conditions:
  - 2+ consecutive test failures in the same phase
  - OR test failures in 3+ different phases
  - AND implementation has not already been revised for test failures

Pattern Detection:
  - Track test results per phase in checkpoint
  - Consecutive failures: phase N fails, phase N retry fails
  - Distributed failures: phase 2 fails, phase 4 fails, phase 5 fails

Action:
  trigger_type: "add_phase"
  revision_prompt: "Test failure pattern detected: {pattern_description}. Recommend adding prerequisite phases or splitting complex phases."
  auto_mode: true
```

**Detection Implementation**:
```bash
# After test execution (Step 3)
if tests_fail; then
  # Load test failure history from checkpoint
  CHECKPOINT=$(load_checkpoint "implement")
  FAILURE_HISTORY=$(echo "$CHECKPOINT" | jq -r '.test_failure_history')

  # Check consecutive failures
  CURRENT_PHASE_FAILURES=$(echo "$FAILURE_HISTORY" | jq "[.[] | select(.phase == $CURRENT_PHASE)] | length")

  if [ "$CURRENT_PHASE_FAILURES" -ge 2 ]; then
    log_test_failure_pattern "$CURRENT_PHASE" "consecutive" "$CURRENT_PHASE_FAILURES"
    trigger_adaptive_replan "add_phase" "consecutive_failures_phase_$CURRENT_PHASE"
  fi

  # Check distributed failures
  UNIQUE_FAILED_PHASES=$(echo "$FAILURE_HISTORY" | jq '[.[] | .phase] | unique | length')

  if [ "$UNIQUE_FAILED_PHASES" -ge 3 ]; then
    log_test_failure_pattern "multiple" "distributed" "$UNIQUE_FAILED_PHASES"
    trigger_adaptive_replan "add_phase" "distributed_failures_across_phases"
  fi
fi
```

**3. Scope Drift Trigger (Manual)**

Activated by user when implementation discovers out-of-scope work:

```yaml
Activation:
  - User provides --report-scope-drift flag with description
  - Example: /implement plan.md 3 --report-scope-drift "Database migration needed before schema changes"

Conditions:
  - Always active when flag present (no automatic detection)
  - User provides textual description of scope drift

Action:
  trigger_type: "update_tasks"
  revision_prompt: "Scope drift reported: {user_description}. Recommend updating plan to incorporate discovered requirements."
  auto_mode: true
  user_description: passed via flag
```

**Detection Implementation**:
```bash
# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --report-scope-drift)
      SCOPE_DRIFT_DESCRIPTION="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [ -n "$SCOPE_DRIFT_DESCRIPTION" ]; then
  log_scope_drift "$CURRENT_PHASE" "$SCOPE_DRIFT_DESCRIPTION"
  trigger_adaptive_replan "update_tasks" "$SCOPE_DRIFT_DESCRIPTION"
fi
```

## Complexity Thresholds

### Configuration (from CLAUDE.md)

Thresholds defined in project CLAUDE.md (Adaptive Planning Configuration section):

```yaml
Default Thresholds:
  COMPLEXITY_THRESHOLD_HIGH: 8.0    # Expansion trigger
  TASK_COUNT_THRESHOLD: 10          # Task count expansion trigger
  FILE_REFERENCE_THRESHOLD: 10      # High file reference count
  REPLAN_LIMIT: 2                   # Max replans per phase

Project-Specific Examples:
  Research-Heavy:
    COMPLEXITY_THRESHOLD_HIGH: 5.0  # Lower threshold, more expansion
    TASK_COUNT_THRESHOLD: 7

  Simple Web App:
    COMPLEXITY_THRESHOLD_HIGH: 10.0 # Higher threshold, less expansion
    TASK_COUNT_THRESHOLD: 15

  Mission-Critical:
    COMPLEXITY_THRESHOLD_HIGH: 3.0  # Very low, maximum organization
    TASK_COUNT_THRESHOLD: 5
```

### Threshold Discovery

```bash
# Read thresholds from CLAUDE.md
source "$CLAUDE_PROJECT_DIR/.claude/lib/detect-project-dir.sh"
CLAUDE_MD=$(find_upward_claudemd)

COMPLEXITY_THRESHOLD_HIGH=$(grep "Expansion Threshold:" "$CLAUDE_MD" | grep -oP '\d+\.\d+')
TASK_COUNT_THRESHOLD=$(grep "Task Count Threshold:" "$CLAUDE_MD" | grep -oP '\d+')
REPLAN_LIMIT=$(grep "Replan Limit:" "$CLAUDE_MD" | grep -oP '\d+')

# Fallback to defaults if not configured
COMPLEXITY_THRESHOLD_HIGH=${COMPLEXITY_THRESHOLD_HIGH:-8.0}
TASK_COUNT_THRESHOLD=${TASK_COUNT_THRESHOLD:-10}
REPLAN_LIMIT=${REPLAN_LIMIT:-2}

export COMPLEXITY_THRESHOLD_HIGH TASK_COUNT_THRESHOLD REPLAN_LIMIT
```

### Hybrid Complexity Evaluation

Complexity scores calculated using two-stage approach:

**Stage 1: Threshold-Based Calculation** (always runs)

Uses `complexity-utils.sh:calculate_phase_complexity()`:

```python
score = 0

# Keyword scoring
score += count_keywords(["database", "migration", "schema"]) * 3
score += count_keywords(["security", "auth", "permission"]) * 4
score += count_keywords(["integrate", "external", "API"]) * 3
score += count_keywords(["refactor", "redesign", "architecture"]) * 2

# Task count scoring
score += task_count / 5  # Every 5 tasks adds 1 point

# File reference scoring
score += file_reference_count / 5  # Every 5 files adds 1 point

# Test complexity scoring
if extensive_test_coverage_required:
  score += 2

return score
```

**Stage 2: Agent-Based Evaluation** (conditional, borderline cases)

Invoked when `threshold_score >= 7 OR task_count >= 8`:

```yaml
Agent: complexity_estimator
Purpose: Context-aware complexity analysis for borderline cases
Tools: Read (phase description only, NOT full plan)
Timeout: 60s

Agent evaluates:
  - Task interdependencies (are tasks tightly coupled?)
  - Scope breadth (single module vs multiple modules)
  - Technical risk (proven patterns vs novel approaches)
  - Parallel work potential (can tasks be done concurrently?)
  - Clarity vs detail tradeoff (is more detail helpful?)

Output:
  {
    "agent_score": 7.5,
    "reasoning": "Phase has high interdependencies and spans 3 modules. Expansion recommended for clarity.",
    "recommendation": "expand"
  }
```

**Reconciliation**:
```python
if agent_invoked:
  if abs(threshold_score - agent_score) <= 2.0:
    final_score = agent_score  # Agent provides nuance
    method = "agent"
  else:
    final_score = (threshold_score + agent_score) / 2  # Average significantly different scores
    method = "reconciled"
    log_complexity_discrepancy(threshold_score, agent_score, reasoning)
else:
  final_score = threshold_score
  method = "threshold"

return {final_score, method, agent_reasoning}
```

## Loop Prevention

### Replan Counter Tracking

Prevent infinite replan loops with per-phase counters:

```yaml
Checkpoint Structure:
  phase_replan_count:
    "1": 0  # Phase 1: 0 replans
    "2": 1  # Phase 2: 1 replan
    "3": 0  # Phase 3: 0 replans

  replan_history:
    - phase: 2
      trigger: "complexity"
      timestamp: "2025-10-13T14:32:15Z"
      old_structure: "inline"
      new_structure: "expanded"
```

**Counter Management**:
```bash
# Before triggering replan
CURRENT_REPLAN_COUNT=$(get_phase_replan_count "$CHECKPOINT" "$CURRENT_PHASE")

if [ "$CURRENT_REPLAN_COUNT" -ge "$REPLAN_LIMIT" ]; then
  echo "ERROR: Replan limit ($REPLAN_LIMIT) reached for Phase $CURRENT_PHASE"
  log_loop_prevention "$CURRENT_PHASE" "$CURRENT_REPLAN_COUNT" "limit_reached"

  # Escalate to user
  escalate_replan_limit_reached "$CURRENT_PHASE" "$REPLAN_LIMIT"
  exit 1
fi

# Increment counter before invoking /revise
increment_phase_replan_count "$CHECKPOINT" "$CURRENT_PHASE"
```

### Replan History Audit Trail

Every replan logged for debugging and analysis:

```bash
log_replan_invocation() {
  local phase=$1
  local trigger_type=$2
  local old_structure=$3
  local new_structure=$4

  ENTRY="{
    \"phase\": $phase,
    \"trigger\": \"$trigger_type\",
    \"timestamp\": \"$(date -Iseconds)\",
    \"old_structure\": \"$old_structure\",
    \"new_structure\": \"$new_structure\"
  }"

  # Append to checkpoint replan_history array
  update_checkpoint_field "replan_history" "$ENTRY"

  # Also log to adaptive-planning.log
  source "$CLAUDE_PROJECT_DIR/.claude/lib/adaptive-planning-logger.sh"
  log_replan_invocation "$phase" "$trigger_type" "$old_structure" "$new_structure"
}
```

### Manual Override

User can force replan despite limit:

```bash
# Flag: --force-replan
if [ "$FORCE_REPLAN" = "true" ]; then
  echo "WARNING: Forcing replan despite limit (user override)"
  log_loop_prevention "$CURRENT_PHASE" "$CURRENT_REPLAN_COUNT" "forced_override"

  # Reset counter (user takes responsibility)
  reset_phase_replan_count "$CHECKPOINT" "$CURRENT_PHASE"

  trigger_adaptive_replan "$TRIGGER_TYPE" "$CONTEXT"
fi
```

## Replan Invocation Workflow

### Step-by-Step Invocation

```bash
trigger_adaptive_replan() {
  local trigger_type=$1  # "expand_phase", "add_phase", or "update_tasks"
  local context=$2        # Phase number or description

  # 1. Check replan limit
  CURRENT_REPLAN_COUNT=$(get_phase_replan_count "$CHECKPOINT" "$CURRENT_PHASE")
  if [ "$CURRENT_REPLAN_COUNT" -ge "$REPLAN_LIMIT" ] && [ "$FORCE_REPLAN" != "true" ]; then
    escalate_replan_limit_reached "$CURRENT_PHASE" "$REPLAN_LIMIT"
    return 1
  fi

  # 2. Build revision context JSON
  REVISION_CONTEXT=$(cat <<EOF
{
  "trigger": "$trigger_type",
  "phase": $CURRENT_PHASE,
  "complexity_score": $COMPLEXITY_SCORE,
  "task_count": $TASK_COUNT,
  "test_failures": $(get_test_failure_count "$CURRENT_PHASE"),
  "user_description": "$context"
}
EOF
)

  # 3. Invoke /revise --auto-mode
  echo "PROGRESS: Adaptive planning triggered: $trigger_type for Phase $CURRENT_PHASE"
  REVISE_OUTPUT=$(invoke_slash_command "/revise --auto-mode --context '$REVISION_CONTEXT' '$PLAN_PATH'")

  # 4. Parse response
  REVISE_STATUS=$(echo "$REVISE_OUTPUT" | grep "REVISION_STATUS:" | cut -d: -f2 | tr -d ' ')

  if [ "$REVISE_STATUS" = "success" ]; then
    # 5. Update checkpoint
    increment_phase_replan_count "$CHECKPOINT" "$CURRENT_PHASE"

    # 6. Log replan history
    OLD_STRUCTURE=$(detect_plan_structure_before_replan "$PLAN_PATH")
    NEW_STRUCTURE=$(detect_plan_structure_after_replan "$PLAN_PATH")
    log_replan_invocation "$CURRENT_PHASE" "$trigger_type" "$OLD_STRUCTURE" "$NEW_STRUCTURE"

    echo "✓ Adaptive replan successful: $trigger_type applied"
    return 0
  else
    echo "ERROR: Adaptive replan failed"
    log_replan_failure "$CURRENT_PHASE" "$trigger_type" "$REVISE_OUTPUT"
    return 1
  fi
}
```

## Integration with Checkpoint Management

### Checkpoint Schema Extensions

Adaptive planning adds fields to checkpoint structure:

```yaml
implement_checkpoint:
  # Standard fields
  workflow_description: "implement"
  plan_path: "specs/plans/025_feature.md"
  current_phase: 3
  total_phases: 5
  status: "in_progress"

  # Adaptive planning fields
  phase_replan_count:
    "1": 0
    "2": 1  # Phase 2 was replanned once
    "3": 0

  replan_history:
    - phase: 2
      trigger: "complexity"
      timestamp: "2025-10-13T14:32:15Z"
      old_structure: "inline"
      new_structure: "expanded"
      complexity_before: 9.5
      complexity_after: 6.2

  test_failure_history:
    - phase: 2
      iteration: 1
      error_type: "syntax"
      timestamp: "2025-10-13T14:20:10Z"
    - phase: 2
      iteration: 2
      error_type: "test_failure"
      timestamp: "2025-10-13T14:28:45Z"

  complexity_evaluations:
    "1": {score: 4.5, method: "threshold"}
    "2": {score: 9.5, method: "agent", reasoning: "High interdependencies"}
    "3": {score: 5.0, method: "threshold"}
```

### Checkpoint Update Operations

```bash
# Increment phase replan count
increment_phase_replan_count() {
  local checkpoint=$1
  local phase=$2

  CURRENT_COUNT=$(echo "$checkpoint" | jq -r ".phase_replan_count[\"$phase\"] // 0")
  NEW_COUNT=$((CURRENT_COUNT + 1))

  UPDATED_CHECKPOINT=$(echo "$checkpoint" | jq ".phase_replan_count[\"$phase\"] = $NEW_COUNT")
  save_checkpoint "implement" "$UPDATED_CHECKPOINT"
}

# Record test failure
record_test_failure() {
  local checkpoint=$1
  local phase=$2
  local error_type=$3

  FAILURE_ENTRY="{
    \"phase\": $phase,
    \"iteration\": $(get_test_iteration_count "$phase"),
    \"error_type\": \"$error_type\",
    \"timestamp\": \"$(date -Iseconds)\"
  }"

  UPDATED_CHECKPOINT=$(echo "$checkpoint" | jq ".test_failure_history += [$FAILURE_ENTRY]")
  save_checkpoint "implement" "$UPDATED_CHECKPOINT"
}
```

## Logging and Observability

### Adaptive Planning Log File

Location: `.claude/logs/adaptive-planning.log`

**Log Rotation**: 10MB max size, 5 files retained

**Log Entries**:
```
[2025-10-13 14:32:15] COMPLEXITY_CHECK: phase=2 score=9.5 threshold=8.0 agent_invoked=true recommendation=expand
[2025-10-13 14:32:20] REPLAN_TRIGGER: phase=2 trigger=complexity replan_count=0/2 status=invoked
[2025-10-13 14:33:45] REPLAN_SUCCESS: phase=2 old_structure=inline new_structure=expanded duration=85s
[2025-10-13 14:40:10] TEST_FAILURE: phase=2 iteration=1 error_type=syntax consecutive_failures=1
[2025-10-13 14:42:30] TEST_FAILURE: phase=2 iteration=2 error_type=test_failure consecutive_failures=2
[2025-10-13 14:42:35] REPLAN_TRIGGER: phase=2 trigger=test_failure_pattern replan_count=1/2 status=invoked
[2025-10-13 14:45:00] LOOP_PREVENTION: phase=3 replan_count=2/2 status=limit_reached action=escalate
```

### Query Functions

Provided by `adaptive-planning-logger.sh`:

```bash
# Query complexity evaluations
get_complexity_history() {
  grep "COMPLEXITY_CHECK" .claude/logs/adaptive-planning.log | tail -20
}

# Query replan history
get_replan_history() {
  grep "REPLAN_" .claude/logs/adaptive-planning.log
}

# Query loop prevention events
get_loop_prevention_events() {
  grep "LOOP_PREVENTION" .claude/logs/adaptive-planning.log
}

# Query test failure patterns
get_test_failure_patterns() {
  grep "TEST_FAILURE" .claude/logs/adaptive-planning.log | \
    awk '{print $3, $4, $5}' | \
    sort | uniq -c
}
```

## Performance Metrics

### Expected Impact

**Expansion Accuracy**: 30% reduction in manual expansion requests (complexity agent provides context-aware evaluation)

**Loop Prevention**: 100% effectiveness (hard limit enforcement prevents infinite replans)

**Test Failure Detection**: 60% of test failure patterns caught within 2 failures (early intervention)

**Replan Success Rate**: 85% of automatic replans resolve the detected issue

### Metric Collection

```bash
# After implementation completes
TOTAL_REPLANS=$(echo "$CHECKPOINT" | jq '.replan_history | length')
PHASES_WITH_REPLANS=$(echo "$CHECKPOINT" | jq '.phase_replan_count | to_entries | map(select(.value > 0)) | length')
COMPLEXITY_AGENT_INVOCATIONS=$(grep "agent_invoked=true" .claude/logs/adaptive-planning.log | wc -l)

echo "Adaptive Planning Metrics:"
echo "  Total replans: $TOTAL_REPLANS"
echo "  Phases replanned: $PHASES_WITH_REPLANS"
echo "  Complexity agent invocations: $COMPLEXITY_AGENT_INVOCATIONS"
```

---

*This is a shared documentation file. Referenced by: `implement.md`, `revise.md`*
EOF
```

4. **Update implement.md** with concise summary (replace lines 17-57):
```markdown
## Adaptive Planning Features

The `/implement` command includes intelligent plan revision with automatic trigger detection:

**Automatic Triggers**:
1. **Complexity Detection**: Phases with hybrid complexity score >8 or >10 tasks trigger phase expansion
2. **Test Failure Pattern**: 2+ consecutive failures suggest missing prerequisites, triggers phase addition
3. **Scope Drift**: Manual flag `--report-scope-drift "description"` triggers task updates

**Behavior**: Automatically invokes `/revise --auto-mode`, updates plan structure, continues implementation

**Loop Prevention**: Max 2 replans per phase (configurable in CLAUDE.md), checkpoint-based counter tracking, replan history audit trail

**Integration**: Uses shared utilities (checkpoint-utils.sh, complexity-utils.sh, adaptive-planning-logger.sh, error-utils.sh)

**See detailed adaptive planning guide**: [Adaptive Planning](shared/adaptive-planning.md)
```

5. **Verify extraction**:
```bash
wc -l shared/adaptive-planning.md  # Should be ~200 lines
grep -A8 "Adaptive Planning Features" implement.md  # Should show summary
```

**Expected Result**: Adaptive planning documentation extracted, implement.md updated with summary.

### Task 2: Extract Progressive Structure Documentation (150 lines)

**Objective**: Extract Level 0→L1→L2 plan structure documentation to enable cross-command reference by /expand, /collapse, and /plan.

**Implementation Steps**:

1. **Locate progressive structure content**:
```bash
grep -n "Progressive.*Support\|Level 0\|Level 1\|Level 2\|Structure.*Level\|Expansion\|Collapse" implement.md
```

Expected section around lines 209-249 (Progressive Plan Support).

2. **Create shared/progressive-structure.md**:
```bash
cat > shared/progressive-structure.md << 'EOF'
# Progressive Plan Structure Documentation

**Part of**: `/implement`, `/plan`, `/expand`, `/collapse` commands
**Purpose**: L0→L1→L2 plan structure evolution documentation
**Usage**: Referenced for structure level detection, expansion/collapse operations, and parser utilities

## Overview

Implementation plans use progressive organization that grows based on actual complexity discovered during execution. All plans start as single-file (Level 0) and expand on-demand when phases or stages prove too complex. This document defines the three structure levels and operations for navigating between them.

## Structure Levels

### Level 0: Single File (Default)

**Format**: `NNN_plan_name.md`

**Structure**:
```
specs/plans/
└── 025_feature_name.md  # All content in single file
```

**Content Organization**:
```markdown
# Feature Implementation Plan

## Metadata
...

## Overview
...

## Implementation Phases

### Phase 1: Foundation
**Objective**: ...
**Tasks**:
- [ ] Task 1
- [ ] Task 2

### Phase 2: Core Logic
**Objective**: ...
**Tasks**:
- [ ] Task 3
- [ ] Task 4

...
```

**When to Use**:
- All plans START at Level 0
- Simple features (1-3 phases, <5 tasks per phase)
- Proof-of-concept implementations
- Quick bug fixes with structured approach

**Advantages**:
- Single file to read/edit
- Linear narrative flow
- Easy to understand at a glance
- Git-friendly (single file diffs)

**Limitations**:
- Large plans (>8 phases) become unwieldy
- Complex phases (>10 tasks) lose clarity
- Hard to navigate specific phases quickly

### Level 1: Phase Expansion

**Format**: `NNN_plan_name/` directory with selective phase expansion

**Structure**:
```
specs/plans/
└── 025_feature_name/
    ├── 025_feature_name.md       # Main plan with phase summaries
    ├── phase_2_core_logic.md     # Expanded phase 2
    └── phase_5_optimization.md   # Expanded phase 5
```

**Main Plan Content** (025_feature_name.md):
```markdown
# Feature Implementation Plan

## Metadata
...

## Implementation Phases

### Phase 1: Foundation
**Objective**: ...
**Tasks**:
- [ ] Task 1
- [ ] Task 2

### Phase 2: Core Logic [EXPANDED]
**See**: [phase_2_core_logic.md](phase_2_core_logic.md)
**Summary**: Core business logic implementation with database integration and API endpoints.
**Complexity**: 9.5 (High)
**Tasks**: 12 tasks across 8 files

### Phase 3: Testing
**Objective**: ...
**Tasks**:
- [ ] Task 3
- [ ] Task 4

...
```

**Expanded Phase File** (phase_2_core_logic.md):
```markdown
# Phase 2: Core Logic Implementation

**Part of**: [025_feature_name.md](025_feature_name.md)
**Complexity**: 9.5 (High)
**Estimated Time**: 4-6 hours

## Objective

Implement core business logic with database persistence and RESTful API endpoints.

## Prerequisites
- Phase 1 complete (database schema created)
- Test database seeded with fixtures

## Tasks

### Database Integration
- [ ] Task 1: Create ORM models for users, sessions
- [ ] Task 2: Implement repository pattern for data access
- [ ] Task 3: Add transaction management

### API Endpoints
- [ ] Task 4: Create POST /api/users endpoint
- [ ] Task 5: Create GET /api/users/:id endpoint
- [ ] Task 6: Add authentication middleware
...

## Testing Strategy
...

## Success Criteria
...
```

**When to Use**:
- Automatic: Phase complexity score >8.0 OR >10 tasks
- Manual: `/expand phase <plan> <phase-num>` command
- Use case: 1-3 phases are complex, others remain simple

**Advantages**:
- Maintains single-file simplicity for simple phases
- Detailed organization for complex phases only
- Easy navigation: click link to see phase details
- Reduces main plan file size

**Transition from L0**:
```bash
# Before expansion (Level 0)
specs/plans/025_feature.md  # 450 lines

# After expanding Phase 2 (Level 1)
specs/plans/025_feature/
  025_feature.md            # 320 lines (130 lines moved to phase file)
  phase_2_core_logic.md     # 180 lines (extracted + 50 lines structure)
```

### Level 2: Stage Expansion

**Format**: Phase directories with stage subdirectories

**Structure**:
```
specs/plans/
└── 025_feature_name/
    ├── 025_feature_name.md           # Main plan
    ├── phase_1_foundation.md         # Simple expanded phase (no stages)
    └── phase_2_core_logic/           # Phase directory (has stages)
        ├── phase_2_overview.md       # Phase overview
        ├── stage_1_database.md       # Stage 1 details
        ├── stage_2_api.md            # Stage 2 details
        └── stage_3_testing.md        # Stage 3 details
```

**Phase Overview File** (phase_2_overview.md):
```markdown
# Phase 2: Core Logic Implementation

**Part of**: [025_feature_name.md](../025_feature_name.md)
**Complexity**: 9.5 (High)
**Structure**: 3 stages

## Overview

This phase implements core business logic through three sequential stages: database integration, API development, and comprehensive testing.

## Stages

### Stage 1: Database Integration [EXPANDED]
**See**: [stage_1_database.md](stage_1_database.md)
**Summary**: ORM models, repository pattern, transaction management
**Tasks**: 5 tasks, ~2 hours

### Stage 2: API Endpoints [EXPANDED]
**See**: [stage_2_api.md](stage_2_api.md)
**Summary**: RESTful endpoints, authentication middleware, validation
**Tasks**: 7 tasks, ~3 hours

### Stage 3: Testing [EXPANDED]
**See**: [stage_3_testing.md](stage_3_testing.md)
**Summary**: Unit tests, integration tests, E2E scenarios
**Tasks**: 4 tasks, ~1.5 hours

## Dependencies
- Phase 1 must be complete before starting any stage
- Stage 2 depends on Stage 1 (uses ORM models)
- Stage 3 can run in parallel with Stage 2 (TDD approach)

## Success Criteria
- All 16 tasks complete across 3 stages
- 80%+ test coverage
- All API endpoints functional and documented
```

**When to Use**:
- Automatic: Expanded phase has >3 distinct workflows
- Manual: `/expand stage <phase> <stage-num>` command
- Use case: Phase is complex AND has clear sequential or parallel sub-workflows

**Advantages**:
- Maximum organization for highly complex phases
- Clear stage boundaries enable parallel work
- Easier to estimate time per stage
- Better for team coordination (assign stages to different developers)

**Limitations**:
- Most complex structure (3-level hierarchy)
- Overkill for simple features
- More files to manage

## Structure Detection

### Utility: parse-adaptive-plan.sh

**Function**: `detect_structure_level <plan-path>`

**Implementation**:
```bash
detect_structure_level() {
  local plan_path=$1

  # Check if plan is a file or directory
  if [ -f "$plan_path" ]; then
    # Level 0: Single file
    echo "0"
    return 0
  fi

  if [ -d "$plan_path" ]; then
    # Check for phase directories (Level 2) vs phase files (Level 1)
    PHASE_DIRS=$(find "$plan_path" -mindepth 1 -maxdepth 1 -type d -name "phase_*" | wc -l)

    if [ "$PHASE_DIRS" -gt 0 ]; then
      # Level 2: Has phase directories
      echo "2"
      return 0
    else
      # Level 1: Has phase files but no phase directories
      echo "1"
      return 0
    fi
  fi

  echo "ERROR: Invalid plan path: $plan_path"
  return 1
}
```

**Usage**:
```bash
PLAN_PATH="specs/plans/025_feature.md"
LEVEL=$(detect_structure_level "$PLAN_PATH")
echo "Plan structure: Level $LEVEL"
```

## Expansion Operations

### Expand Phase (L0 → L1 or within L1)

**Command**: `/expand phase <plan-path> <phase-number>`

**Workflow**:
1. Read plan file (Level 0) or main plan in directory (Level 1)
2. Extract Phase N content (heading through end of phase)
3. Create directory `NNN_plan_name/` (if Level 0)
4. Write `phase_N_name.md` with extracted content + metadata header
5. Update main plan: replace phase content with summary + link
6. Update phase counter: increment `expanded_phases` field

**Example**:
```bash
# Before
specs/plans/025_feature.md  # 450 lines, Phase 2 is 180 lines

# Execute
/expand phase specs/plans/025_feature.md 2

# After
specs/plans/025_feature/
  025_feature.md            # 320 lines
  phase_2_core_logic.md     # 180 lines + 50 lines structure = 230 lines
```

### Expand Stage (L1 → L2 within phase)

**Command**: `/expand stage <phase-path> <stage-number>`

**Workflow**:
1. Read expanded phase file `phase_N_name.md`
2. Extract Stage M content
3. Create phase directory `phase_N_name/`
4. Move `phase_N_name.md` → `phase_N_name/phase_N_overview.md`
5. Write `stage_M_name.md` with extracted content
6. Update overview: replace stage content with summary + link

**Example**:
```bash
# Before
specs/plans/025_feature/
  phase_2_core_logic.md     # 230 lines, has implicit stages

# Execute
/expand stage specs/plans/025_feature/phase_2_core_logic.md 1

# After
specs/plans/025_feature/
  phase_2_core_logic/
    phase_2_overview.md     # 120 lines (summaries)
    stage_1_database.md     # 110 lines extracted + 40 structure = 150 lines
```

## Collapse Operations

### Collapse Phase (L1 → L0 or within L1)

**Command**: `/collapse phase <plan-path> <phase-number>`

**Triggers**: Automatic after phase completion if:
- Tasks ≤ 5 AND
- Complexity < 6.0

**Workflow**:
1. Read expanded phase file `phase_N_name.md`
2. Remove metadata header (Part of, Complexity, etc.)
3. Extract core content (Objective, Tasks, Testing, Success Criteria)
4. Read main plan file
5. Replace phase summary + link with full extracted content
6. Delete `phase_N_name.md` file
7. If no more expanded phases, convert directory back to single file

**Example**:
```bash
# Before
specs/plans/025_feature/
  025_feature.md            # Phase 2 summary
  phase_2_core_logic.md     # 150 lines (completed, simple now)

# Execute (automatic or manual)
/collapse phase specs/plans/025_feature/025_feature.md 2

# After (if Phase 2 was only expansion)
specs/plans/025_feature.md  # 350 lines (collapsed back to L0)
```

### Collapse Stage (L2 → L1 within phase)

**Command**: `/collapse stage <phase-path> <stage-number>`

**Workflow**:
1. Read stage file `stage_M_name.md`
2. Remove metadata header
3. Extract core content
4. Read phase overview `phase_N_overview.md`
5. Replace stage summary + link with full content
6. Delete `stage_M_name.md` file
7. If no more expanded stages, convert directory to single file

## Parsing Utilities

### Progressive Parser Functions

Located in `.claude/lib/parse-adaptive-plan.sh`:

```bash
# Check if plan is expanded
is_plan_expanded <plan-path>
# Returns: "true" or "false"

# Check if specific phase is expanded
is_phase_expanded <plan-path> <phase-number>
# Returns: "true" or "false"

# Check if specific stage is expanded
is_stage_expanded <phase-path> <stage-number>
# Returns: "true" or "false"

# List expanded phase numbers
list_expanded_phases <plan-path>
# Returns: "2 5 7" (space-separated)

# List expanded stage numbers for a phase
list_expanded_stages <phase-path>
# Returns: "1 3" (space-separated)

# Get phase file path
get_phase_file_path <plan-path> <phase-number>
# Returns: Absolute path to phase file (or main plan if not expanded)

# Get stage file path
get_stage_file_path <phase-path> <stage-number>
# Returns: Absolute path to stage file (or phase file if not expanded)
```

### Usage in Commands

```bash
# /implement command: Read correct file based on expansion status
IS_EXPANDED=$(is_phase_expanded "$PLAN_PATH" "$CURRENT_PHASE")

if [ "$IS_EXPANDED" = "true" ]; then
  PHASE_FILE=$(get_phase_file_path "$PLAN_PATH" "$CURRENT_PHASE")
  PHASE_CONTENT=$(Read "$PHASE_FILE")
else
  # Read from main plan file, extract phase section
  PHASE_CONTENT=$(Read "$PLAN_PATH" | extract_phase_section "$CURRENT_PHASE")
fi
```

## Benefits of Progressive Structure

### Organic Growth
- Plans start simple (single file)
- Expand only when complexity warrants
- Avoids premature optimization

### Clarity
- Simple phases remain inline (easy to scan)
- Complex phases get dedicated files (deep focus)
- Structure matches actual complexity

### Flexibility
- Expand complex phases during planning OR during implementation
- Collapse after simplification (refactoring, completed phases)
- Mixed expansion: some phases expanded, others inline

### Implementation-Friendly
- `/implement` reads correct file based on expansion status
- Parser handles all structure levels uniformly
- No mental model change during execution

---

*This is a shared documentation file. Referenced by: `implement.md`, `plan.md`, `expand.md`, `collapse.md`*
EOF
```

3. **Update implement.md** with summary (replace lines 209-249):
```markdown
## Progressive Plan Support

This command supports all three progressive structure levels:

**Level 0 (Single File)**: All phases inline in one file (default for new plans)
**Level 1 (Phase Expansion)**: Complex phases (score >8 or >10 tasks) in separate files
**Level 2 (Stage Expansion)**: Multi-stage workflows within expanded phases

**Structure Detection**: Uses `parse-adaptive-plan.sh:detect_structure_level()` to determine current level (0, 1, or 2)

**Unified Interface**: Parser utilities abstract level differences - commands read correct files automatically using `get_phase_file_path()` and `get_stage_file_path()`

**Benefits**: Organic growth (expand only when needed), clarity (simple phases inline, complex phases detailed), flexibility (mixed expansion supported)

**See detailed structure documentation**: [Progressive Structure](shared/progressive-structure.md)
```

4. **Verify extraction**:
```bash
wc -l shared/progressive-structure.md  # ~150 lines
grep -A6 "Progressive Plan Support" implement.md
```

**Expected Result**: Progressive structure documentation extracted and referenced.

### Task 3: Extract Phase Execution Protocol (180 lines)

**Objective**: Extract checkpoint management, test protocols, and commit workflow documentation with cross-references to error-recovery.md from Stage 2.

**Implementation Steps**:

1. **Locate phase execution content**:
```bash
grep -n "^## Phase Execution Protocol\|^### 1\.\|^### 2\.\|^### 3\.\|^### 4\.\|^### 5\." implement.md
```

Expected section: lines 289-602 (Phase Execution Protocol section).

2. **Create shared/phase-execution.md** with cross-references:
```bash
cat > shared/phase-execution.md << 'EOF'
# Phase Execution Protocol

**Part of**: `/implement` command
**Purpose**: Standardized phase execution workflow with checkpoint management and testing
**Usage**: Referenced for implementation flow, testing requirements, and commit procedures

## Overview

This document defines the complete phase execution protocol used by the `/implement` command. Each phase follows a systematic workflow: complexity evaluation → implementation → testing → debugging (if needed) → git commit → plan update → checkpoint save. This protocol ensures consistent execution and enables reliable resume capabilities.

**Cross-References**:
- Error handling and debugging: [Error Recovery Patterns](error-recovery.md)
- Adaptive planning integration: [Adaptive Planning](adaptive-planning.md)
- Progressive structure support: [Progressive Structure](progressive-structure.md)

## Execution Modes

### Sequential Mode (Default)

Execute phases in order (Phase 1, 2, 3, ...) when no dependencies declared:

```bash
for phase in $(seq 1 $TOTAL_PHASES); do
  execute_phase "$phase"
  if phase_failed; then
    handle_failure "$phase"  # See error-recovery.md
    break
  fi
done
```

### Parallel Mode (With Dependencies)

Parse dependencies into waves, execute waves sequentially, parallelize phases within waves:

```bash
# Parse dependencies to generate waves
WAVES=$(parse_phase_dependencies "$PLAN_PATH")
# Output: WAVE_1:1 WAVE_2:2,3 WAVE_3:4

for wave in $WAVES; do
  WAVE_NUM=$(echo "$wave" | cut -d: -f1)
  PHASES=$(echo "$wave" | cut -d: -f2 | tr ',' ' ')

  if [ $(echo "$PHASES" | wc -w) -eq 1 ]; then
    # Single phase wave: execute normally
    execute_phase "$PHASES"
  else
    # Multi-phase wave: execute in parallel
    execute_wave_parallel "$PHASES"
  fi
done
```

## Phase Execution Workflow

### Step 1: Pre-Execution Checks

**1.1. Read Phase Content**

Determine correct file based on expansion status:
```bash
IS_EXPANDED=$(is_phase_expanded "$PLAN_PATH" "$CURRENT_PHASE")

if [ "$IS_EXPANDED" = "true" ]; then
  PHASE_FILE=$(get_phase_file_path "$PLAN_PATH" "$CURRENT_PHASE")
else
  PHASE_FILE="$PLAN_PATH"
fi

PHASE_CONTENT=$(Read "$PHASE_FILE" | extract_phase_section "$CURRENT_PHASE")
PHASE_NAME=$(echo "$PHASE_CONTENT" | grep "^### Phase $CURRENT_PHASE:" | sed 's/^### Phase [0-9]*: //')
TASK_LIST=$(echo "$PHASE_CONTENT" | grep -A100 "^## Tasks" | grep "^- \[ \]")
```

**1.2. Display Phase Information**

```bash
echo "═══════════════════════════════════════"
echo "Phase $CURRENT_PHASE/$TOTAL_PHASES: $PHASE_NAME"
echo "═══════════════════════════════════════"
echo ""
echo "Tasks:"
echo "$TASK_LIST" | nl
echo ""
```

**1.3. Hybrid Complexity Evaluation**

See [Adaptive Planning Guide](adaptive-planning.md#hybrid-complexity-evaluation) for complete evaluation procedure.

```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh"
EVALUATION_RESULT=$(hybrid_complexity_evaluation "$PHASE_NAME" "$TASK_LIST" "$PLAN_FILE")
COMPLEXITY_SCORE=$(echo "$EVALUATION_RESULT" | jq -r '.final_score')
EVALUATION_METHOD=$(echo "$EVALUATION_RESULT" | jq -r '.evaluation_method')

echo "Complexity: $COMPLEXITY_SCORE ($EVALUATION_METHOD)"
```

**1.4. Proactive Expansion Check**

If complexity high, recommend expansion before implementation:
```bash
if [ $(echo "$COMPLEXITY_SCORE >= 8.0" | bc) -eq 1 ]; then
  IS_ALREADY_EXPANDED=$(is_phase_expanded "$PLAN_PATH" "$CURRENT_PHASE")

  if [ "$IS_ALREADY_EXPANDED" = "false" ]; then
    echo "⚠ High Complexity Detected"
    echo "Recommendation: Expand Phase $CURRENT_PHASE before implementation"
    echo "Reason: Complexity score $COMPLEXITY_SCORE >= 8.0 threshold"
    echo ""
    echo "Command: /expand phase $PLAN_PATH $CURRENT_PHASE"
    echo ""
    echo "Proceed with implementation anyway? (y/n)"
    # Informational only - user decides
  fi
fi
```

### Step 2: Implementation

**Agent Selection** based on complexity score:

```bash
if [ $(echo "$COMPLEXITY_SCORE <= 2" | bc) -eq 1 ]; then
  # Direct execution (orchestrator implements without agent)
  implement_directly "$PHASE_CONTENT"

elif [ $(echo "$COMPLEXITY_SCORE <= 5" | bc) -eq 1 ]; then
  # Code-writer agent (standard mode)
  invoke_agent "code-writer" "standard" "$PHASE_CONTENT"

elif [ $(echo "$COMPLEXITY_SCORE <= 7" | bc) -eq 1 ]; then
  # Code-writer with thinking
  invoke_agent "code-writer" "think" "$PHASE_CONTENT"

elif [ $(echo "$COMPLEXITY_SCORE <= 9" | bc) -eq 1 ]; then
  # Code-writer with hard thinking
  invoke_agent "code-writer" "think hard" "$PHASE_CONTENT"

else
  # Code-writer with harder thinking (10+)
  invoke_agent "code-writer" "think harder" "$PHASE_CONTENT"
fi
```

**Special Case Overrides**:
- Documentation phases: Use doc-writer agent
- Testing phases: Use test-specialist agent
- Debug resolution: Use debug-specialist agent

### Step 3: Testing

**3.1. Test Detection**

Discover test commands from:
1. Phase tasks containing test keywords
2. Project CLAUDE.md Testing Protocols
3. Standard test patterns (npm test, pytest, make test)

```bash
# Check phase tasks
TEST_TASKS=$(echo "$TASK_LIST" | grep -i "test\|spec\|verify")

# Check CLAUDE.md
CLAUDE_MD=$(find_upward_claudemd)
TEST_COMMANDS=$(grep -A10 "^## Testing Protocols" "$CLAUDE_MD" | grep "^- ")

# Execute tests
if [ -n "$TEST_TASKS" ] || [ -n "$TEST_COMMANDS" ]; then
  run_tests "$CURRENT_PHASE"
  TEST_EXIT_CODE=$?
else
  echo "No tests defined for this phase"
  TEST_EXIT_CODE=0
fi
```

**3.2. Test Execution**

```bash
run_tests() {
  local phase=$1

  echo "Running tests for Phase $phase..."

  # Execute test commands
  TEST_OUTPUT=$(execute_test_commands 2>&1)
  TEST_EXIT_CODE=$?

  if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "✓ All tests passed"
    return 0
  else
    echo "✗ Tests failed"
    echo "$TEST_OUTPUT"
    return 1
  fi
}
```

**3.3. Automatic Debug Integration (if tests fail)**

See [Error Recovery Patterns](error-recovery.md#debugging-iteration-limits) for complete debugging workflow.

**Tiered Recovery** (4 levels):

1. **Level 1: Classify and Suggest**
   ```bash
   source "$CLAUDE_PROJECT_DIR/.claude/lib/error-utils.sh"
   ERROR_TYPE=$(detect_error_type "$TEST_OUTPUT")
   SUGGESTIONS=$(generate_suggestions "$ERROR_TYPE" "$TEST_OUTPUT")
   echo "Error Type: $ERROR_TYPE"
   echo "$SUGGESTIONS"
   ```

2. **Level 2: Transient Retry** (timeout, busy, locked)
   ```bash
   if [ "$ERROR_TYPE" = "timeout" ]; then
     retry_with_extended_timeout "$CURRENT_PHASE"
   fi
   ```

3. **Level 3: Tool Fallback** (tool access errors)
   ```bash
   if is_tool_access_error "$TEST_OUTPUT"; then
     retry_with_reduced_toolset "$CURRENT_PHASE"
   fi
   ```

4. **Level 4: Debug Agent Invocation**
   ```bash
   DEBUG_RESULT=$(invoke_slash_command "/debug \"Phase $CURRENT_PHASE failure\" \"$PLAN_PATH\"")
   DEBUG_REPORT_PATH=$(extract_report_path "$DEBUG_RESULT")

   # Present user choices: (r)evise, (c)ontinue, (s)kip, (a)bort
   ```

**3.4. Adaptive Planning Detection**

Check if replanning needed based on test failures:

See [Adaptive Planning Guide](adaptive-planning.md#automatic-triggers) for trigger detection logic.

```bash
# Check consecutive failures
CHECKPOINT=$(load_checkpoint "implement")
FAILURES=$(get_consecutive_failures "$CHECKPOINT" "$CURRENT_PHASE")

if [ "$FAILURES" -ge 2 ]; then
  trigger_adaptive_replan "test_failure_pattern" "$CURRENT_PHASE"
fi
```

### Step 4: Git Commit

**Only after tests pass**, create structured commit:

```bash
if [ $TEST_EXIT_CODE -eq 0 ]; then
  # Generate commit message
  COMMIT_MSG=$(cat <<EOF
feat: implement Phase $CURRENT_PHASE - $PHASE_NAME

Automated implementation of phase $CURRENT_PHASE from plan $PLAN_NUMBER
All tests passed successfully

Files modified:
$(git status --porcelain | head -5)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)

  # Create commit
  git add .
  git commit -m "$COMMIT_MSG"
  COMMIT_HASH=$(git rev-parse --short HEAD)

  echo "✓ Commit created: $COMMIT_HASH"
else
  echo "Skipping commit (tests failed)"
fi
```

### Step 5: Plan Update

**After git commit succeeds**, update plan files:

**5.1. Mark Tasks Complete**

```bash
# Update correct file (expanded phase or main plan)
PHASE_FILE=$(get_phase_file_path "$PLAN_PATH" "$CURRENT_PHASE")

# Change all [ ] to [x] in phase section
Edit "$PHASE_FILE" \
  old_string="- [ ]" \
  new_string="- [x]" \
  replace_all=true
```

**5.2. Add Completion Marker**

```bash
# Add [COMPLETED] to phase heading
OLD_HEADING="### Phase $CURRENT_PHASE: $PHASE_NAME"
NEW_HEADING="### Phase $CURRENT_PHASE: $PHASE_NAME [COMPLETED]"

Edit "$PHASE_FILE" \
  old_string="$OLD_HEADING" \
  new_string="$NEW_HEADING"
```

**5.3. Update Progress Section**

```bash
# Add/update Implementation Progress in main plan
PROGRESS_SECTION="## Implementation Progress

**Last Completed**: Phase $CURRENT_PHASE - $PHASE_NAME
**Date**: $(date -I)
**Commit**: $COMMIT_HASH
**Status**: In Progress ($CURRENT_PHASE/$TOTAL_PHASES phases complete)

**To Resume**: \`/implement $PLAN_PATH $((CURRENT_PHASE + 1))\`
"

# Append or update progress section
if grep -q "^## Implementation Progress" "$MAIN_PLAN_FILE"; then
  # Update existing section
  Edit "$MAIN_PLAN_FILE" \
    old_string="$(extract_section "$MAIN_PLAN_FILE" "Implementation Progress")" \
    new_string="$PROGRESS_SECTION"
else
  # Append new section
  echo "$PROGRESS_SECTION" >> "$MAIN_PLAN_FILE"
fi
```

**5.4. Incremental Summary Generation**

Create or update partial summary:

```bash
SUMMARY_PATH="$SPECS_DIR/summaries/${PLAN_NUMBER}_partial.md"

if [ ! -f "$SUMMARY_PATH" ]; then
  # Create partial summary
  create_partial_summary "$SUMMARY_PATH" "$PLAN_PATH" "$CURRENT_PHASE"
else
  # Update existing summary
  update_partial_summary "$SUMMARY_PATH" "$CURRENT_PHASE" "$COMMIT_HASH"
fi
```

**5.5. Automatic Collapse Detection**

After phase completion, check if should collapse:

See [Adaptive Planning Guide](adaptive-planning.md#loop-prevention) for collapse logic.

```bash
if phase_complete && is_phase_expanded "$PLAN_PATH" "$CURRENT_PHASE"; then
  TASK_COUNT=$(count_phase_tasks "$CURRENT_PHASE")
  COMPLEXITY=$(get_phase_complexity "$CURRENT_PHASE")

  if [ "$TASK_COUNT" -le 5 ] && [ $(echo "$COMPLEXITY < 6.0" | bc) -eq 1 ]; then
    echo "Collapse candidate: Phase $CURRENT_PHASE (tasks=$TASK_COUNT, complexity=$COMPLEXITY)"
    trigger_adaptive_collapse "$CURRENT_PHASE"
  fi
fi
```

### Step 6: Checkpoint Save

**After plan update**, save checkpoint with updated state:

```bash
CHECKPOINT_DATA=$(cat <<EOF
{
  "workflow_description": "implement",
  "plan_path": "$PLAN_PATH",
  "current_phase": $((CURRENT_PHASE + 1)),
  "total_phases": $TOTAL_PHASES,
  "completed_phases": $(get_completed_phases),
  "status": "in_progress",
  "tests_passing": true,
  "phase_replan_count": $(get_phase_replan_counts),
  "last_commit": "$COMMIT_HASH",
  "timestamp": "$(date -Iseconds)"
}
EOF
)

source "$CLAUDE_PROJECT_DIR/.claude/lib/checkpoint-utils.sh"
save_checkpoint "implement" "$CHECKPOINT_DATA"

echo "✓ Checkpoint saved"
```

### Step 7: Defensive Check Before Next Phase

Before starting Phase N+1, verify Phase N is marked complete:

```bash
# Read plan file
PHASE_N_HEADING=$(grep "^### Phase $CURRENT_PHASE:" "$PHASE_FILE")

# Verify [COMPLETED] marker present
if ! echo "$PHASE_N_HEADING" | grep -q "\[COMPLETED\]"; then
  echo "WARNING: Phase $CURRENT_PHASE not marked complete"

  # Check if commit exists
  if git log --oneline | grep -q "Phase $CURRENT_PHASE"; then
    echo "Commit found, marking phase complete now (recovery)"
    # Add marker
    add_completion_marker "$CURRENT_PHASE"
  else
    echo "ERROR: No commit found for Phase $CURRENT_PHASE"
    exit 1
  fi
fi
```

## Checkpoint Management

### Checkpoint Structure

```yaml
implement_checkpoint:
  workflow_description: "implement"
  plan_path: "specs/plans/025_feature.md"
  plan_number: "025"
  current_phase: 3
  total_phases: 5
  completed_phases: [1, 2]
  status: "in_progress"
  tests_passing: true

  # Adaptive planning fields
  phase_replan_count: {
    "1": 0,
    "2": 1,
    "3": 0
  }

  # Test history
  test_failure_history: [
    {phase: 2, iteration: 1, error_type: "syntax"},
    {phase: 2, iteration: 2, error_type: "test_failure"}
  ]

  # Git tracking
  last_commit: "a3f9b10"
  commit_history: ["e8f3a21", "a3f9b10"]

  # Timestamps
  started_at: "2025-10-13T14:00:00Z"
  last_updated: "2025-10-13T14:32:15Z"
```

### Auto-Resume Safety Checks

Before auto-resuming from checkpoint, verify 5 conditions:

```bash
check_safe_resume_conditions() {
  local checkpoint=$1

  # 1. Tests passing in last run
  TESTS_PASSING=$(echo "$checkpoint" | jq -r '.tests_passing')
  [ "$TESTS_PASSING" = "true" ] || return 1

  # 2. No recent errors
  LAST_ERROR=$(echo "$checkpoint" | jq -r '.last_error')
  [ "$LAST_ERROR" = "null" ] || return 1

  # 3. Checkpoint age < 7 days
  CHECKPOINT_AGE=$(( $(date +%s) - $(date -d "$(echo "$checkpoint" | jq -r '.last_updated')" +%s) ))
  [ $CHECKPOINT_AGE -lt 604800 ] || return 1  # 7 days in seconds

  # 4. Plan file not modified since checkpoint
  PLAN_MTIME=$(stat -c %Y "$PLAN_PATH")
  CHECKPOINT_TIME=$(date -d "$(echo "$checkpoint" | jq -r '.last_updated')" +%s)
  [ $PLAN_MTIME -le $CHECKPOINT_TIME ] || return 1

  # 5. Status = "in_progress"
  STATUS=$(echo "$checkpoint" | jq -r '.status')
  [ "$STATUS" = "in_progress" ] || return 1

  return 0
}
```

If all 5 conditions met: auto-resume silently
If any condition fails: show interactive prompt with reason

## Wave Execution (Parallel Mode)

### Multi-Phase Wave Execution

```bash
execute_wave_parallel() {
  local phases=$1  # "2 3 4" (space-separated)

  echo "Executing Wave: Phases $phases (parallel)"

  # Invoke all phases concurrently (multiple Task calls in one message)
  # Wait for wave completion
  # Aggregate results
  # Check for failures

  FAILED_PHASES=()
  for phase in $phases; do
    if phase_failed "$phase"; then
      FAILED_PHASES+=("$phase")
    fi
  done

  if [ ${#FAILED_PHASES[@]} -gt 0 ]; then
    echo "ERROR: Wave failed - phases ${FAILED_PHASES[@]} did not complete"
    save_checkpoint "failed" "$CURRENT_WAVE" "${FAILED_PHASES[@]}"
    exit 1
  fi

  echo "✓ Wave complete - all phases succeeded"
}
```

### Parallelism Limits

- Max 3 concurrent phases per wave
- If wave has >3 phases, split into sub-waves

---

*This is a shared documentation file. Referenced by: `implement.md`*
EOF
```

3. **Update implement.md** with summary (replace section starting at line 289):
```markdown
## Phase Execution Protocol

Execute phases sequentially (traditional) or in parallel waves (with dependencies).

**Execution Modes**:
- **Sequential**: Phases executed in order (1, 2, 3, ...) when no dependencies
- **Parallel**: Phases grouped into waves based on declared dependencies, phases within waves execute concurrently

**Phase Workflow** (7 steps):
1. **Pre-Execution**: Read phase, display info, evaluate complexity (hybrid), proactive expansion check
2. **Implementation**: Agent selection based on complexity (0-2: direct, 3-5: code-writer, 6-7: think, 8-9: think hard, 10+: think harder)
3. **Testing**: Discover tests, execute, automatic debug integration if fail (4-level tiered recovery, see [Error Recovery](shared/error-recovery.md))
4. **Git Commit**: Structured commit after tests pass
5. **Plan Update**: Mark tasks [x], add [COMPLETED], update progress, incremental summary, automatic collapse detection
6. **Checkpoint Save**: Persist state for resume
7. **Defensive Check**: Verify previous phase complete before starting next

**See detailed execution protocol**: [Phase Execution](shared/phase-execution.md)
```

4. **Verify extraction and cross-references**:
```bash
wc -l shared/phase-execution.md  # ~180 lines
grep "error-recovery.md" shared/phase-execution.md  # Should find cross-references
grep "Phase Execution Protocol" -A12 implement.md
```

**Expected Result**: Phase execution protocol extracted with cross-references to error-recovery.md.

### Task 4: Update implement.md and Verify Final State

**Objective**: Finalize all extractions, update shared/README.md, verify file size targets, test command functionality.

**Implementation Steps**:

1. **Calculate final file sizes**:
```bash
cd /home/benjamin/.config/.claude/commands
wc -l implement.md shared/adaptive-planning.md shared/progressive-structure.md shared/phase-execution.md

# Expected:
#  700 implement.md (target: ~700, reduced from 987)
#  200 shared/adaptive-planning.md
#  150 shared/progressive-structure.md
#  180 shared/phase-execution.md
# 1230 total
```

2. **Verify reduction percentage**:
```bash
ORIGINAL=987
FINAL=$(wc -l < implement.md)
REDUCTION=$((ORIGINAL - FINAL))
PERCENTAGE=$((REDUCTION * 100 / ORIGINAL))

echo "implement.md: $ORIGINAL → $FINAL lines ($PERCENTAGE% reduction)"
# Expected: "implement.md: 987 → 700 lines (29% reduction)"
```

3. **Update shared/README.md cross-reference index**:
```bash
# Update the table with actual line counts and references
Edit shared/README.md \
  old_string="| _(to be populated)_ | _(during extraction)_ | _(after extraction)_ |" \
  new_string="| workflow-phases.md | orchestrate.md | 800 |
| error-recovery.md | orchestrate.md, implement.md, debug.md | 400 |
| context-management.md | orchestrate.md, implement.md | 300 |
| agent-coordination.md | orchestrate.md, implement.md, debug.md | 250 |
| orchestrate-examples.md | orchestrate.md | 200 |
| adaptive-planning.md | implement.md, revise.md | 200 |
| progressive-structure.md | implement.md, plan.md, expand.md, collapse.md | 150 |
| phase-execution.md | implement.md | 180 |"
```

4. **Test reference links**:
```bash
# Verify all links in implement.md resolve
grep -o '\[.*\](shared/.*\.md)' implement.md | while read link; do
  FILE=$(echo "$link" | grep -o 'shared/.*\.md')
  [ -f "$FILE" ] && echo "OK: $FILE" || echo "ERROR: $FILE missing"
done
```

5. **Smoke test implement command**:
```bash
# Test that implement.md is readable and reference links work
head -80 implement.md | tail -20
# Should show Adaptive Planning Features summary with link
```

**Expected Result**:
- implement.md reduced to ~700 lines (29% reduction, 287 lines saved)
- 3 new shared files created (~530 lines total)
- All reference links functional
- Cross-reference index in shared/README.md updated

## Testing Strategy

### Unit Tests

**Test shared file cross-references**:
```bash
# Verify phase-execution.md references error-recovery.md correctly
grep "error-recovery.md" shared/phase-execution.md
# Should find multiple references

# Verify link format
grep "\[Error Recovery" shared/phase-execution.md
# Should show markdown link format
```

**Test adaptive planning integration**:
```bash
# Verify adaptive-planning.md describes triggers correctly
grep -A10 "^## Automatic Triggers" shared/adaptive-planning.md
```

### Integration Tests

**Test implement with shared references**:
```bash
# Verify implement can follow reference links when reading plan
# (manual test: run /implement on a simple plan and observe behavior)
```

**Test cross-command referencing**:
```bash
# Verify future commands can reference adaptive-planning.md
# Example: /revise will reference adaptive-planning.md in Stage 4
```

### Verification Commands

```bash
# File sizes within targets
wc -l implement.md | awk '{if($1 > 750) print "FAIL: too large"; else print "PASS: size OK"}'

# All shared files created
for file in adaptive-planning.md progressive-structure.md phase-execution.md; do
  [ -f "shared/$file" ] && echo "PASS: $file" || echo "FAIL: $file missing"
done

# Cross-references valid
grep "error-recovery.md" shared/phase-execution.md > /dev/null && \
  echo "PASS: Cross-reference present" || echo "FAIL: Missing cross-reference"
```

## Success Criteria

Stage 3 is complete when:
- [ ] `shared/adaptive-planning.md` created (~200 lines) with replan triggers, thresholds, loop prevention
- [ ] `shared/progressive-structure.md` created (~150 lines) with L0→L1→L2 documentation
- [ ] `shared/phase-execution.md` created (~180 lines) with checkpoint, testing, commit workflow
- [ ] implement.md reduced to ~700 lines (29% reduction from 987 lines)
- [ ] All 3 reference links added to implement.md with summaries
- [ ] phase-execution.md successfully cross-references error-recovery.md (from Stage 2)
- [ ] shared/README.md updated with new files in cross-reference index
- [ ] No broken markdown or links
- [ ] Command functionality preserved

## Dependencies

### Prerequisites
- Stage 2 complete (shared/error-recovery.md exists for cross-referencing)
- implement.md currently at 987 lines
- Edit tool functional

### Enables
- Stage 4 (utility consolidation can reference shared docs)
- /revise command can reference adaptive-planning.md
- /expand, /collapse commands can reference progressive-structure.md
- /debug command can reference phase-execution.md for integration patterns

## Risk Mitigation

### Medium Risk Items
- **Cross-reference accuracy**: Ensure phase-execution.md links to error-recovery.md correctly
- **Complexity threshold documentation**: Values must match CLAUDE.md configuration
- **Checkpoint schema**: Document current schema accurately for future compatibility

### Mitigation Strategies
- **Test cross-references**: Open referenced file to verify content matches link
- **Git commits**: Commit after each extraction (3 commits total)
- **Backup implement.md**: Copy before editing for rollback capability

### Edge Cases
- **Adaptive planning section scattered**: Consolidate all mentions during extraction
- **Progressive structure examples**: Ensure structure levels clearly differentiated
- **Checkpoint schema evolution**: Note that schema may change, document current version

## Notes

### Design Decisions

**Why extract adaptive planning first?**
It's the most referenced section (implement, revise, expand, collapse all need it) and establishes the foundation for understanding plan evolution.

**Why cross-reference error-recovery.md?**
Demonstrates the reusability benefit of Stage 2's work - phase-execution naturally references error handling, no duplication needed.

**Why document progressive structure separately?**
It's conceptual documentation used by 4 commands (/implement, /plan, /expand, /collapse), making it ideal for shared extraction.

### Efficiency Tips

- Extract adaptive planning in one session (maintains conceptual coherence)
- Use grep to verify all mentions of adaptive planning concepts captured
- Test cross-references immediately after creating them (faster to fix)
- Update README.md last to capture actual line counts

### Future Considerations

Stage 4 (utility consolidation) can reference these shared docs when consolidating artifact-utils.sh and auto-analysis-utils.sh, reducing inline documentation in utilities.
