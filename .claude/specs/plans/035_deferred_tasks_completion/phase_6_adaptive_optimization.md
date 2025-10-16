# Phase 6: Adaptive Planning Optimization

## Phase Metadata
- **Phase Number**: 6
- **Parent Plan**: 035_deferred_tasks_completion.md
- **Objective**: Enable post-creation plan evaluation with auto-expansion and configurable thresholds
- **Complexity**: High (7/10)
- **Estimated Time**: 3-5 hours
- **Reference**: Report 028 Phases 1-2 (lines 640-671)
- **Status**: PENDING

## Overview

This phase transforms the adaptive planning workflow from **reactive** (expansion during implementation) to **proactive** (expansion after plan creation). Currently, the `/plan` command creates plans but doesn't evaluate whether phases need expansion until `/implement` runs, causing workflow interruptions mid-implementation. This phase adds automatic complexity evaluation after plan creation, configurable thresholds for expansion decisions, and user-friendly expansion recommendations.

### Current Problem (Report 028:221-268)

```
User: /plan "Implement OAuth2 authentication system"
      ↓
Agent generates plan (6 phases, Phase 3 has 15 tasks)
      ↓
Plan saved: specs/plans/046_oauth2_authentication.md (L0)
      ↓
User: /implement specs/plans/046_oauth2_authentication.md
      ↓
[LATER] /implement detects Phase 3 complexity > threshold
      ↓
/revise --auto-mode expand_phase
      ↓
Plan restructured to L1 mid-implementation [INTERRUPTION]
```

**Problem**: Expansion happens **during implementation**, not **after creation**

### Solution Workflow (Report 028:249-266)

```
User: /plan "Implement OAuth2 authentication system"
      ↓
Agent generates plan (6 phases, Phase 3 has 15 tasks)
      ↓
Plan saved: specs/plans/046_oauth2_authentication.md (L0)
      ↓
[AUTO] Evaluate each phase for complexity
      ↓
[AUTO] Phase 3 exceeds threshold → Expand immediately
      ↓
Plan restructured to L1: specs/plans/046_oauth2_authentication/
      ↓
User: /implement specs/plans/046_oauth2_authentication/
      ↓
Implementation proceeds smoothly (already expanded) [NO INTERRUPTION]
```

**Benefit**: Seamless workflow, plan ready for implementation

## Architecture Overview

### Workflow Shift: Reactive to Proactive

**Current Architecture (Reactive)**:
```
┌──────────────────────────────────────────────────┐
│ /plan command                                    │
│   1. Generate plan content                       │
│   2. Save to file (L0)                           │
│   3. Return path to user                         │
│   END - No evaluation                            │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│ /implement command (later)                       │
│   For each phase:                                │
│     1. Detect structure level                    │
│     2. Check expansion status                    │
│     3. [Step 1.55] Proactive expansion check     │
│     4. If complex: Recommend expansion           │
│     5. Implement phase                           │
│     6. [Step 3.4] Reactive expansion check       │
│     7. If triggered: /revise --auto-mode         │
│        [WORKFLOW INTERRUPTION]                   │
└──────────────────────────────────────────────────┘
```

**New Architecture (Proactive)**:
```
┌──────────────────────────────────────────────────┐
│ /plan command                                    │
│   1. Generate plan content                       │
│   2. Save to file (L0)                           │
│   3. [NEW] Evaluate each phase complexity        │
│   4. [NEW] Auto-expand phases > threshold        │
│   5. [NEW] Display recommendations               │
│   6. Return final plan path (L0 or L1)           │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│ /implement command (later)                       │
│   For each phase:                                │
│     1. Detect structure level                    │
│     2. Phase already expanded if needed          │
│     3. Implement phase smoothly                  │
│     4. [Step 3.4] Still checks for complexity    │
│        (handles changes during implementation)   │
│   [NO WORKFLOW INTERRUPTION]                     │
└──────────────────────────────────────────────────┘
```

### Integration Points

**Three Commands Modified**:

1. **`/plan` command** (primary changes):
   - Add post-creation evaluation loop
   - Source complexity-utils.sh
   - Invoke /expand for complex phases
   - Display recommendations table
   - Read thresholds from CLAUDE.md

2. **`/expand` command** (threshold integration):
   - Read EXPANSION_THRESHOLD from CLAUDE.md
   - Use in auto-analysis mode
   - Fall back to default 8.0 if not configured

3. **`/implement` command** (threshold integration):
   - Read REPLAN_LIMIT from CLAUDE.md
   - Use in adaptive planning loop prevention
   - Fall back to default 2 if not configured

### Configuration System Design

**CLAUDE.md-Based Configuration**:

```markdown
## Adaptive Planning Configuration
[Used by: /plan, /expand, /implement, /revise]

### Complexity Thresholds
- **Expansion Threshold**: 8.0 (phases with score > this auto-expand)
- **Task Count Threshold**: 5 (phases with > 5 tasks considered complex)
- **File Reference Threshold**: 10 (phases referencing > 10 files)
- **Replan Limit**: 2 (max replans per phase during implementation)
```

**Fallback System**:
- If CLAUDE.md not found: Use hardcoded defaults
- If section missing: Use hardcoded defaults
- If value malformed: Use hardcoded defaults
- Log which values are being used (configured vs default)

**Per-Project Customization**:
- Different projects have different complexity needs
- Research-heavy project: Lower threshold (6.0)
- Simple CRUD app: Higher threshold (10.0)
- Mission-critical: Conservative threshold (5.0)

### Complexity Evaluation Algorithm

**Phase Complexity Score Calculation** (from complexity-utils.sh):

```bash
calculate_phase_complexity() {
  local phase_name="${1:-}"
  local task_list="${2:-}"

  local score=0

  # High complexity keywords (weight: 3)
  if echo "$phase_name" | grep -qiE "refactor|architecture|redesign|migrate|security"; then
    score=$((score + 3))
  fi

  # Medium complexity keywords (weight: 2)
  if echo "$phase_name" | grep -qiE "implement|create|build|integrate|add"; then
    score=$((score + 2))
  fi

  # Task count contribution
  local task_count=$(echo "$task_list" | grep -c "^- \[ \]" || echo "0")
  local task_score=$(((task_count + 4) / 5))  # 1 point per 5 tasks
  score=$((score + task_score))

  echo "$score"
}
```

**Expansion Decision Logic**:
```bash
# Trigger expansion if:
# - Complexity score > EXPANSION_THRESHOLD (default 8.0), OR
# - Task count > TASK_COUNT_THRESHOLD (default 10)

if [ "$complexity_score" -gt "$EXPANSION_THRESHOLD" ] || \
   [ "$task_count" -gt "$TASK_COUNT_THRESHOLD" ]; then
  expand_phase "$phase_num"
fi
```

### Performance Considerations

**Additional Time Cost**:
- Complexity evaluation: <1 second per phase (very fast)
- Expansion (if triggered): 30-60 seconds per complex phase
- Example: Plan with 6 phases, 1 complex
  - Current: 10 sec /plan + [later] 60 sec expansion during /implement
  - New: 70 sec /plan (10 + 60)
  - **Net impact**: Same total time, better UX

**No Parallel Evaluation Needed**:
- Sequential evaluation: 6 phases × 1 sec = 6 seconds
- Parallel evaluation: 1 second (all at once)
- **Savings**: 5 seconds (not worth complexity)
- **Decision**: Keep sequential, simple implementation

**User Experience Impact**:
- **Positive**: No workflow interruptions during /implement
- **Neutral**: Plan creation slightly longer (but user sees progress)
- **Positive**: Plan ready for implementation immediately
- **Positive**: User can review expansion decisions before starting work

## Task 6.1: Post-Creation Phase Evaluation

### Implementation Design

**Where to Add Evaluation**:

Location: `/plan` command, after plan file is saved, before return to user

```bash
# Current /plan flow:
# 1. Parse arguments
# 2. Generate plan content
# 3. Write plan to file
# 4. [HERE: ADD POST-CREATION EVALUATION]
# 5. Return plan path to user
```

**Evaluation Loop Structure**:

```bash
# After plan saved to file
plan_file="specs/plans/NNN_feature_name.md"

# Source complexity utilities
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/home/benjamin/.config}"
source "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh"

# Read thresholds from CLAUDE.md (with fallbacks)
EXPANSION_THRESHOLD=$(read_threshold "Expansion Threshold" "8.0")
TASK_COUNT_THRESHOLD=$(read_threshold "Task Count Threshold" "10")

# Parse total phases from plan
total_phases=$(grep -c "^### Phase [0-9]" "$plan_file")

# Track expanded phases
expanded_phases=""

# Evaluate each phase
for phase_num in $(seq 1 "$total_phases"); do
  # Extract phase content
  phase_content=$(extract_phase_content "$plan_file" "$phase_num")
  phase_name=$(echo "$phase_content" | grep "^### Phase $phase_num:" | sed 's/^### Phase [0-9]*: //')
  task_list=$(echo "$phase_content" | grep "^- \[ \]")

  # Calculate complexity
  complexity_score=$(calculate_phase_complexity "$phase_name" "$task_list")
  task_count=$(echo "$task_list" | wc -l)

  # Decide expansion
  if [ "$complexity_score" -gt "$EXPANSION_THRESHOLD" ] || \
     [ "$task_count" -gt "$TASK_COUNT_THRESHOLD" ]; then
    echo "Phase $phase_num complexity: $complexity_score (threshold: $EXPANSION_THRESHOLD)"
    echo "Auto-expanding Phase $phase_num: $phase_name"

    # Invoke /expand
    /expand phase "$plan_file" "$phase_num"

    # Track expansion
    expanded_phases="$expanded_phases $phase_num"

    # Update plan_file path (L0 → L1 on first expansion)
    plan_base=$(basename "$plan_file" .md)
    if [[ -d "specs/plans/$plan_base" ]]; then
      plan_file="specs/plans/$plan_base/$plan_base.md"
    fi
  fi
done

echo "Plan ready: $plan_file"
if [ -n "$expanded_phases" ]; then
  echo "Auto-expanded phases:$expanded_phases"
fi
```

**Auto-Expansion Decision Logic**:

```bash
# Expansion threshold comparison (use bc for float comparison)
if (( $(echo "$complexity_score > $EXPANSION_THRESHOLD" | bc -l) )); then
  should_expand=true
fi

# Task count threshold (integer comparison)
if [ "$task_count" -gt "$TASK_COUNT_THRESHOLD" ]; then
  should_expand=true
fi

# Expand if either threshold exceeded
if [ "$should_expand" = "true" ]; then
  /expand phase "$plan_file" "$phase_num"
fi
```

**Plan Path Updates (L0 → L1 Transitions)**:

```bash
# Before any expansion
plan_file="specs/plans/NNN_feature.md"  # L0 single file

# After first expansion
# /expand creates: specs/plans/NNN_feature/ directory
#                  specs/plans/NNN_feature/NNN_feature.md (main plan)
#                  specs/plans/NNN_feature/phase_N_name.md (expanded phase)

# Update path for subsequent evaluations
plan_base=$(basename "$plan_file" .md)
if [[ -d "specs/plans/$plan_base" ]]; then
  # Directory exists, plan is now L1
  plan_file="specs/plans/$plan_base/$plan_base.md"
fi

# Subsequent expansions use updated path
# /expand phase specs/plans/NNN_feature/NNN_feature.md M
```

### Complete Code Implementation

**Helper Function: Read Threshold from CLAUDE.md**

```bash
# Function: read_threshold
# Reads threshold value from CLAUDE.md with fallback
# Args: $1 = threshold name (e.g., "Expansion Threshold")
#       $2 = default value (e.g., "8.0")
# Returns: threshold value (configured or default)
read_threshold() {
  local threshold_name="$1"
  local default_value="$2"

  # Find CLAUDE.md
  local claude_md=""
  if [ -f "CLAUDE.md" ]; then
    claude_md="CLAUDE.md"
  elif [ -f "../CLAUDE.md" ]; then
    claude_md="../CLAUDE.md"
  elif [ -f "$CLAUDE_PROJECT_DIR/CLAUDE.md" ]; then
    claude_md="$CLAUDE_PROJECT_DIR/CLAUDE.md"
  fi

  if [ -z "$claude_md" ]; then
    echo "$default_value"
    return
  fi

  # Extract threshold value
  local threshold_value=$(grep -E "^\s*-\s+\*\*$threshold_name\*\*:" "$claude_md" | \
                          grep -oE '[0-9]+(\.[0-9]+)?' | head -1)

  # Validate threshold (must be numeric)
  if ! [[ "$threshold_value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "$default_value"
    return
  fi

  echo "$threshold_value"
}
```

**Helper Function: Extract Phase Content**

```bash
# Function: extract_phase_content
# Extracts phase section from plan file
# Args: $1 = plan file path
#       $2 = phase number
# Returns: phase content (heading + tasks + all subsections)
extract_phase_content() {
  local plan_file="$1"
  local phase_num="$2"

  # Use sed to extract phase section
  # From "### Phase N:" to next "### Phase" or "## " heading
  sed -n "/^### Phase $phase_num:/,/^### Phase\|^## /p" "$plan_file" | \
    sed '$d'  # Remove last line (next section heading)
}
```

**Main Post-Creation Evaluation Logic**

```bash
# Post-creation evaluation (add to /plan command after plan saved)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "POST-CREATION EVALUATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Source utilities
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/home/benjamin/.config}"
if [ ! -f "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh" ]; then
  echo "Warning: complexity-utils.sh not found, skipping evaluation"
  echo "Plan created: $plan_file"
  exit 0
fi

source "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh"

# Read thresholds
EXPANSION_THRESHOLD=$(read_threshold "Expansion Threshold" "8.0")
TASK_COUNT_THRESHOLD=$(read_threshold "Task Count Threshold" "10")

echo "Using thresholds:"
echo "  Expansion: $EXPANSION_THRESHOLD (complexity score)"
echo "  Task Count: $TASK_COUNT_THRESHOLD (tasks per phase)"
echo ""

# Parse total phases
total_phases=$(grep -c "^### Phase [0-9]" "$plan_file")
if [ "$total_phases" -eq 0 ]; then
  echo "No phases found in plan, skipping evaluation"
  echo "Plan created: $plan_file"
  exit 0
fi

echo "Evaluating $total_phases phases..."
echo ""

# Track expansions
expanded_count=0
expanded_phases=""

# Evaluate each phase
for phase_num in $(seq 1 "$total_phases"); do
  # Extract phase content
  phase_content=$(extract_phase_content "$plan_file" "$phase_num")
  phase_name=$(echo "$phase_content" | grep "^### Phase $phase_num:" | \
               sed 's/^### Phase [0-9]*: //' | sed 's/ *\*\*Objective\*\*.*//')
  task_list=$(echo "$phase_content" | grep "^- \[ \]")

  # Calculate metrics
  complexity_score=$(calculate_phase_complexity "$phase_name" "$task_list")
  task_count=$(echo "$task_list" | wc -l)

  # Decide expansion
  should_expand=false
  expansion_reason=""

  if (( $(echo "$complexity_score > $EXPANSION_THRESHOLD" | bc -l) )); then
    should_expand=true
    expansion_reason="complexity $complexity_score > threshold $EXPANSION_THRESHOLD"
  fi

  if [ "$task_count" -gt "$TASK_COUNT_THRESHOLD" ]; then
    should_expand=true
    if [ -n "$expansion_reason" ]; then
      expansion_reason="$expansion_reason AND $task_count tasks > $TASK_COUNT_THRESHOLD"
    else
      expansion_reason="$task_count tasks > threshold $TASK_COUNT_THRESHOLD"
    fi
  fi

  if [ "$should_expand" = "true" ]; then
    echo "Phase $phase_num: $phase_name"
    echo "  Complexity: $complexity_score | Tasks: $task_count"
    echo "  Reason: $expansion_reason"
    echo "  Action: Auto-expanding..."
    echo ""

    # Invoke /expand
    "$CLAUDE_PROJECT_DIR/.claude/commands/expand" phase "$plan_file" "$phase_num"

    # Track expansion
    expanded_count=$((expanded_count + 1))
    expanded_phases="$expanded_phases $phase_num"

    # Update plan_file path after first expansion (L0 → L1)
    plan_base=$(basename "$plan_file" .md)
    if [[ -d "specs/plans/$plan_base" ]]; then
      plan_file="specs/plans/$plan_base/$plan_base.md"
    fi

    echo ""
  else
    echo "Phase $phase_num: $phase_name (complexity $complexity_score, $task_count tasks) - OK"
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "EVALUATION COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Plan ready: $plan_file"

if [ "$expanded_count" -gt 0 ]; then
  echo "Auto-expanded $expanded_count phase(s):$expanded_phases"
  echo ""
  echo "Plan structure: Level 1 (phase-expanded)"
else
  echo ""
  echo "Plan structure: Level 0 (all phases inline)"
fi

echo ""
```

**Edge Cases Handled**:

1. **No complexity-utils.sh found**: Skip evaluation gracefully
2. **No phases in plan**: Skip evaluation, report zero phases
3. **Invalid threshold values**: Use fallback defaults
4. **Multiple expansions**: Track path updates correctly (L0 → L1 only once)
5. **Expansion failure**: Log error, continue with next phase
6. **Plan already L1**: Detect and use correct path for main plan file

**Logging Integration** (if adaptive-planning-logger available):

```bash
# After each expansion decision
if [ -f "$CLAUDE_PROJECT_DIR/.claude/lib/adaptive-planning-logger.sh" ]; then
  source "$CLAUDE_PROJECT_DIR/.claude/lib/adaptive-planning-logger.sh"

  # Log complexity check
  triggered=$([ "$should_expand" = "true" ] && echo "true" || echo "false")
  log_complexity_check "$phase_num" "$complexity_score" "$EXPANSION_THRESHOLD" "$triggered"

  # Log expansion invocation
  if [ "$should_expand" = "true" ]; then
    log_expansion_invocation "$phase_num" "post_creation" "$expansion_reason"
  fi
fi
```

**Error Handling for Complexity Calculation**:

```bash
# Wrap complexity calculation in error handler
complexity_score=$(calculate_phase_complexity "$phase_name" "$task_list" 2>/dev/null || echo "0")

# Validate score is numeric
if ! [[ "$complexity_score" =~ ^[0-9]+$ ]]; then
  echo "Warning: Invalid complexity score for Phase $phase_num, using 0"
  complexity_score=0
fi
```

### Testing Specification

**Test 1: Simple Plan (No Expansions Triggered)**

```bash
# Setup
cat > test_simple_plan.md <<'EOF'
# Test Feature

### Phase 1: Setup
**Objective**: Initialize project
- [ ] Create directory
- [ ] Add README

### Phase 2: Implementation
**Objective**: Build feature
- [ ] Write code
- [ ] Add tests

### Phase 3: Documentation
**Objective**: Document feature
- [ ] Update docs
EOF

# Execute
/plan test_simple_plan.md

# Verify
# - Output shows "Evaluating 3 phases..."
# - Each phase shows "OK" (no expansion)
# - Final message: "Plan structure: Level 0 (all phases inline)"
# - File exists: test_simple_plan.md
# - No directory created

test -f "test_simple_plan.md" && echo "PASS: Single file preserved"
test ! -d "test_simple_plan" && echo "PASS: No directory created"
```

**Test 2: Complex Plan (Multiple Phases Expand)**

```bash
# Setup
cat > test_complex_plan.md <<'EOF'
# Test Feature

### Phase 1: Architecture Refactor
**Objective**: Redesign system architecture
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
- [ ] Task 4
- [ ] Task 5
- [ ] Task 6
- [ ] Task 7
- [ ] Task 8
- [ ] Task 9
- [ ] Task 10
- [ ] Task 11

### Phase 2: Simple Setup
**Objective**: Initialize
- [ ] Task 1
- [ ] Task 2

### Phase 3: Migrate Database
**Objective**: Database migration
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
- [ ] Task 4
- [ ] Task 5
- [ ] Task 6
EOF

# Execute
/plan test_complex_plan.md

# Verify
# - Phase 1 expanded (11 tasks > 10 + "refactor" keyword)
# - Phase 2 NOT expanded (2 tasks, low complexity)
# - Phase 3 expanded (6 tasks + "migrate" keyword)
# - Final structure: Level 1
# - Directory exists with main plan and 2 expanded phase files

test -d "test_complex_plan" && echo "PASS: Directory created"
test -f "test_complex_plan/test_complex_plan.md" && echo "PASS: Main plan in directory"
test -f "test_complex_plan/phase_1_architecture_refactor.md" && echo "PASS: Phase 1 expanded"
test -f "test_complex_plan/phase_3_migrate_database.md" && echo "PASS: Phase 3 expanded"
```

**Test 3: Plan Structure Transitions (L0 → L1)**

```bash
# Setup: Plan with 1 complex phase (should trigger L0 → L1)

# Execute
/plan test_transition.md

# Verify
# 1. First expansion creates directory
ls -la | grep "test_transition/" && echo "PASS: Directory created on first expansion"

# 2. Main plan moved to directory
test -f "test_transition/test_transition.md" && echo "PASS: Main plan in directory"

# 3. Expanded phase file created
test -f "test_transition/phase_1_complex.md" && echo "PASS: Phase 1 expanded file"

# 4. Original file no longer at top level
test ! -f "test_transition.md" && echo "PASS: Original file moved"

# 5. Subsequent expansions use directory path
# (verify by checking that second expansion doesn't recreate directory)
```

**Test 4: Workflow (No Implementation Interruption)**

```bash
# Setup: Create complex plan with auto-expansion

# Step 1: Create plan (auto-expands Phase 3)
/plan "Complex OAuth2 system" > output.txt

# Verify auto-expansion happened
grep "Auto-expanded.*phase.*3" output.txt && echo "PASS: Phase 3 auto-expanded"

# Step 2: Implement plan
plan_path=$(grep "Plan ready:" output.txt | sed 's/Plan ready: //')
/implement "$plan_path" 1  # Start from Phase 1

# Verify no mid-implementation expansion
# /implement should NOT trigger /revise --auto-mode for Phase 3
# (Phase 3 already expanded, complexity check skipped)

# Check logs for expansion events
if [ -f ".claude/logs/adaptive-planning.log" ]; then
  # Should NOT find "replan" or "expand" events for Phase 3 during /implement
  grep -q "phase.*3.*expand.*during.*implement" .claude/logs/adaptive-planning.log && \
    echo "FAIL: Phase 3 expanded during implement (should have been pre-expanded)" || \
    echo "PASS: No mid-implementation expansion (pre-expanded worked)"
fi
```

**Test 5: Threshold Customization**

```bash
# Setup: Configure low threshold in CLAUDE.md
cat >> CLAUDE.md <<'EOF'
## Adaptive Planning Configuration

### Complexity Thresholds
- **Expansion Threshold**: 4.0
- **Task Count Threshold**: 5
EOF

# Create plan with moderate complexity
cat > test_threshold.md <<'EOF'
### Phase 1: Implement Feature
**Objective**: Add new feature
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
- [ ] Task 4
- [ ] Task 5
- [ ] Task 6
EOF

# Execute
/plan test_threshold.md

# Verify
# - Phase 1 should expand with low threshold (6 tasks > 5)
# - With default threshold (10), it would NOT expand

test -f "test_threshold/phase_1_implement_feature.md" && \
  echo "PASS: Low threshold triggered expansion" || \
  echo "FAIL: Threshold not applied"

# Cleanup
# Remove Adaptive Planning Configuration from CLAUDE.md
```

## Task 6.2: Configurable Complexity Thresholds

### CLAUDE.md Configuration Section Design

**Complete Section Template**:

```markdown
## Adaptive Planning Configuration
[Used by: /plan, /expand, /implement, /revise]

### Complexity Thresholds

The following thresholds control when plans are automatically expanded or revised during creation and implementation.

#### Expansion Threshold
- **Default**: 8.0
- **Range**: 0.0 - 15.0
- **Description**: Phases with complexity score above this threshold are automatically expanded to separate files
- **When to Adjust**:
  - Lower (4.0-6.0): Research-heavy projects requiring detailed documentation per phase
  - Higher (10.0-12.0): Simple CRUD applications with straightforward implementations
  - Very Low (2.0-4.0): Mission-critical projects requiring maximum organization

#### Task Count Threshold
- **Default**: 10
- **Range**: 5 - 20
- **Description**: Phases with more tasks than this threshold are expanded regardless of complexity score
- **When to Adjust**:
  - Lower (5-7): Projects preferring smaller, focused phase files
  - Higher (15-20): Projects comfortable with larger inline phases

#### File Reference Threshold
- **Default**: 10
- **Range**: 5 - 30
- **Description**: Phases referencing more files than this threshold increase complexity score
- **When to Adjust**:
  - Lower (5): Modular codebases with many small files
  - Higher (20): Monolithic codebases with fewer large files

#### Replan Limit
- **Default**: 2
- **Range**: 1 - 5
- **Description**: Maximum number of automatic replans allowed per phase during implementation (loop prevention)
- **When to Adjust**:
  - Lower (1): Conservative projects wanting manual review after first replan
  - Higher (3-4): Experimental projects accepting more iteration (use with caution)

### Usage Examples

**Research Project** (detailed documentation preferred):
```markdown
### Complexity Thresholds
- **Expansion Threshold**: 5.0
- **Task Count Threshold**: 7
- **File Reference Threshold**: 8
- **Replan Limit**: 2
```

**Simple Web App** (larger inline phases acceptable):
```markdown
### Complexity Thresholds
- **Expansion Threshold**: 10.0
- **Task Count Threshold**: 15
- **File Reference Threshold**: 15
- **Replan Limit**: 2
```

**Mission-Critical System** (maximum organization):
```markdown
### Complexity Thresholds
- **Expansion Threshold**: 3.0
- **Task Count Threshold**: 5
- **File Reference Threshold**: 5
- **Replan Limit**: 1
```
```

**Documentation for Each Threshold**:

1. **Expansion Threshold**: Controls automatic phase expansion
   - **What it controls**: Phase complexity score threshold for auto-expansion
   - **When it's checked**: After /plan creation, during /implement (reactive fallback)
   - **Effect**: Phases with score > threshold expanded to separate files
   - **Adjustment guide**: Lower = more organization, higher = simpler structure

2. **Task Count Threshold**: Alternative expansion trigger
   - **What it controls**: Maximum tasks per inline phase before expansion
   - **When it's checked**: Same as Expansion Threshold
   - **Effect**: Phases with tasks > threshold expanded regardless of complexity
   - **Adjustment guide**: Lower = smaller phases, higher = larger phases

3. **File Reference Threshold**: Complexity score contributor
   - **What it controls**: When file references increase complexity score
   - **When it's checked**: During complexity calculation
   - **Effect**: Phases referencing > threshold files get higher scores
   - **Adjustment guide**: Match project's file organization style

4. **Replan Limit**: Loop prevention
   - **What it controls**: Max automatic replans during /implement
   - **When it's checked**: Before invoking /revise --auto-mode
   - **Effect**: Prevents infinite replan loops, escalates to user
   - **Adjustment guide**: 1-2 conservative, 3+ experimental (risky)

### Threshold Reading Implementation

**Enhanced read_threshold Function** (with validation):

```bash
# Function: read_threshold
# Reads threshold from CLAUDE.md with validation and fallback
# Args: $1 = threshold name (e.g., "Expansion Threshold")
#       $2 = default value (e.g., "8.0")
#       $3 = min value (optional, e.g., "0.0")
#       $4 = max value (optional, e.g., "15.0")
# Returns: validated threshold value
read_threshold() {
  local threshold_name="$1"
  local default_value="$2"
  local min_value="${3:-0}"
  local max_value="${4:-100}"

  # Find CLAUDE.md (search upward)
  local claude_md=""
  local search_dir="$(pwd)"

  while [ "$search_dir" != "/" ]; do
    if [ -f "$search_dir/CLAUDE.md" ]; then
      claude_md="$search_dir/CLAUDE.md"
      break
    fi
    search_dir=$(dirname "$search_dir")
  done

  # Check project directory
  if [ -z "$claude_md" ] && [ -n "$CLAUDE_PROJECT_DIR" ]; then
    if [ -f "$CLAUDE_PROJECT_DIR/CLAUDE.md" ]; then
      claude_md="$CLAUDE_PROJECT_DIR/CLAUDE.md"
    fi
  fi

  # No CLAUDE.md found, use default
  if [ -z "$claude_md" ]; then
    echo "$default_value"
    return
  fi

  # Extract threshold value
  # Pattern: - **Threshold Name**: value
  local threshold_value=$(grep -E "^\s*-\s+\*\*$threshold_name\*\*:" "$claude_md" | \
                          grep -oE '[0-9]+(\.[0-9]+)?' | head -1)

  # No threshold found, use default
  if [ -z "$threshold_value" ]; then
    echo "$default_value"
    return
  fi

  # Validate threshold is numeric
  if ! [[ "$threshold_value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Warning: Invalid threshold '$threshold_value' for '$threshold_name', using default" >&2
    echo "$default_value"
    return
  fi

  # Range validation (use bc for float comparison)
  if (( $(echo "$threshold_value < $min_value" | bc -l) )) || \
     (( $(echo "$threshold_value > $max_value" | bc -l) )); then
    echo "Warning: Threshold '$threshold_value' for '$threshold_name' out of range [$min_value, $max_value], using default" >&2
    echo "$default_value"
    return
  fi

  # Valid threshold
  echo "$threshold_value"
}
```

**Usage in Commands**:

```bash
# In /plan command (Task 6.1 implementation)
EXPANSION_THRESHOLD=$(read_threshold "Expansion Threshold" "8.0" "0.0" "15.0")
TASK_COUNT_THRESHOLD=$(read_threshold "Task Count Threshold" "10" "5" "20")
FILE_REFERENCE_THRESHOLD=$(read_threshold "File Reference Threshold" "10" "5" "30")

# In /expand command (auto-analysis mode)
EXPANSION_THRESHOLD=$(read_threshold "Expansion Threshold" "8.0" "0.0" "15.0")

# In /implement command (replan limit)
REPLAN_LIMIT=$(read_threshold "Replan Limit" "2" "1" "5")
```

### Command Updates

**Update 1: /plan Command** (integrate threshold reading):

```bash
# In /plan command, before post-creation evaluation loop

# Read thresholds from CLAUDE.md
EXPANSION_THRESHOLD=$(read_threshold "Expansion Threshold" "8.0" "0.0" "15.0")
TASK_COUNT_THRESHOLD=$(read_threshold "Task Count Threshold" "10" "5" "20")

# Show which thresholds are being used
echo "Complexity Thresholds:"
if grep -q "Expansion Threshold" CLAUDE.md 2>/dev/null; then
  echo "  Expansion: $EXPANSION_THRESHOLD (configured in CLAUDE.md)"
else
  echo "  Expansion: $EXPANSION_THRESHOLD (default, not configured)"
fi

if grep -q "Task Count Threshold" CLAUDE.md 2>/dev/null; then
  echo "  Task Count: $TASK_COUNT_THRESHOLD (configured in CLAUDE.md)"
else
  echo "  Task Count: $TASK_COUNT_THRESHOLD (default, not configured)"
fi

echo ""
```

**Update 2: /expand Command** (read threshold for auto-analysis):

```bash
# In /expand command, auto-analysis mode section

# Read expansion threshold
EXPANSION_THRESHOLD=$(read_threshold "Expansion Threshold" "8.0" "0.0" "15.0")

echo "Auto-Analysis Mode: Using expansion threshold $EXPANSION_THRESHOLD"
echo ""

# Use threshold in complexity checks
# (pass to complexity_estimator agent as context)
```

**Update 3: /implement Command** (read replan limit):

```bash
# In /implement command, Step 3.4 (adaptive planning detection)

# Read replan limit from CLAUDE.md
REPLAN_LIMIT=$(read_threshold "Replan Limit" "2" "1" "5")

# Check replan count against limit
if [ "$PHASE_REPLAN_COUNT" -ge "$REPLAN_LIMIT" ]; then
  echo "=========================================="
  echo "Warning: Replanning Limit Reached"
  echo "=========================================="
  echo "Phase: $CURRENT_PHASE"
  echo "Replans: $PHASE_REPLAN_COUNT (max $REPLAN_LIMIT)"
  echo ""
  echo "Configured limit: $REPLAN_LIMIT (from CLAUDE.md)"
  echo "Recommendation: Manual review required"
  echo "=========================================="

  SKIP_REPLAN=true
fi
```

**Show Configuration Source in Verbose Output**:

```bash
# Helper function to show threshold source
show_threshold_source() {
  local threshold_name="$1"
  local threshold_value="$2"
  local default_value="$3"

  if [ "$threshold_value" = "$default_value" ]; then
    echo "  $threshold_name: $threshold_value (default)"
  else
    echo "  $threshold_name: $threshold_value (configured in CLAUDE.md)"
  fi
}

# Usage in commands
show_threshold_source "Expansion Threshold" "$EXPANSION_THRESHOLD" "8.0"
show_threshold_source "Task Count Threshold" "$TASK_COUNT_THRESHOLD" "10"
show_threshold_source "Replan Limit" "$REPLAN_LIMIT" "2"
```

### Testing Specification

**Test 1: Default Behavior (No Config in CLAUDE.md)**

```bash
# Setup: Ensure no Adaptive Planning Configuration in CLAUDE.md
# (or test in directory without CLAUDE.md)

# Execute /plan
/plan "Test feature with moderate complexity"

# Verify
# - Output shows "Expansion Threshold: 8.0 (default, not configured)"
# - Thresholds use hardcoded defaults (8.0, 10, etc.)
# - Expansion decisions use default thresholds

grep -q "8.0 (default" output.txt && echo "PASS: Default threshold used"
```

**Test 2: Custom Thresholds (Configured in CLAUDE.md)**

```bash
# Setup: Add configuration to CLAUDE.md
cat >> CLAUDE.md <<'EOF'
## Adaptive Planning Configuration

### Complexity Thresholds
- **Expansion Threshold**: 5.0
- **Task Count Threshold**: 7
- **Replan Limit**: 3
EOF

# Execute /plan
/plan "Test feature" > output.txt

# Verify
# - Output shows "Expansion Threshold: 5.0 (configured in CLAUDE.md)"
# - Expansion happens at lower threshold
# - More phases expanded than with default

grep -q "5.0 (configured" output.txt && echo "PASS: Custom threshold read"
grep -q "Auto-expanding" output.txt && echo "PASS: Custom threshold applied"
```

**Test 3: Invalid Threshold Values**

```bash
# Setup: Add invalid values to CLAUDE.md
cat >> CLAUDE.md <<'EOF'
## Adaptive Planning Configuration

### Complexity Thresholds
- **Expansion Threshold**: invalid_value
- **Task Count Threshold**: -5
- **Replan Limit**: 100
EOF

# Execute /plan
/plan "Test feature" 2>&1 | tee output.txt

# Verify
# - Warning shown for invalid "Expansion Threshold"
# - Warning shown for "Task Count Threshold" out of range
# - Warning shown for "Replan Limit" out of range
# - Defaults used instead

grep -q "Invalid threshold.*Expansion" output.txt && echo "PASS: Invalid value detected"
grep -q "out of range.*Task Count" output.txt && echo "PASS: Range check works"
grep -q "using default" output.txt && echo "PASS: Fallback to default"
```

**Test 4: Threshold Range Validation**

```bash
# Setup: Configure edge values
cat > CLAUDE.md <<'EOF'
## Adaptive Planning Configuration

### Complexity Thresholds
- **Expansion Threshold**: 15.0
- **Task Count Threshold**: 20
- **Replan Limit**: 5
EOF

# Execute
EXPANSION_THRESHOLD=$(read_threshold "Expansion Threshold" "8.0" "0.0" "15.0")
TASK_COUNT_THRESHOLD=$(read_threshold "Task Count Threshold" "10" "5" "20")
REPLAN_LIMIT=$(read_threshold "Replan Limit" "2" "1" "5")

# Verify edge values accepted
[ "$EXPANSION_THRESHOLD" = "15.0" ] && echo "PASS: Max expansion threshold accepted"
[ "$TASK_COUNT_THRESHOLD" = "20" ] && echo "PASS: Max task count accepted"
[ "$REPLAN_LIMIT" = "5" ] && echo "PASS: Max replan limit accepted"

# Test out-of-range values
cat > CLAUDE.md <<'EOF'
## Adaptive Planning Configuration

### Complexity Thresholds
- **Expansion Threshold**: 20.0
- **Task Count Threshold**: 100
EOF

EXPANSION_THRESHOLD=$(read_threshold "Expansion Threshold" "8.0" "0.0" "15.0")
TASK_COUNT_THRESHOLD=$(read_threshold "Task Count Threshold" "10" "5" "20")

# Verify out-of-range rejected, defaults used
[ "$EXPANSION_THRESHOLD" = "8.0" ] && echo "PASS: Out-of-range expansion rejected"
[ "$TASK_COUNT_THRESHOLD" = "10" ] && echo "PASS: Out-of-range task count rejected"
```

**Test 5: Fallback Behavior (CLAUDE.md Not Found)**

```bash
# Setup: Work in directory without CLAUDE.md
mkdir /tmp/test_no_config
cd /tmp/test_no_config

# Execute
EXPANSION_THRESHOLD=$(read_threshold "Expansion Threshold" "8.0")

# Verify
# - No error or warning
# - Default value returned
[ "$EXPANSION_THRESHOLD" = "8.0" ] && echo "PASS: Fallback to default when CLAUDE.md missing"
```

## Task 6.3: Expansion Recommendations Display

### Display Design

**Complexity Table Format**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE COMPLEXITY ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase 1: Foundation Setup
  Complexity: 2.1 | Tasks: 3 | Status: ✓ Simple

Phase 2: Core Implementation
  Complexity: 4.5 | Tasks: 7 | Status: ✓ Medium

Phase 3: Architecture Refactor
  Complexity: 9.2 | Tasks: 12 | Status: ⚠ High - EXPANSION RECOMMENDED
  Command: /expand phase specs/plans/046_oauth2.md 3

Phase 4: Testing
  Complexity: 3.8 | Tasks: 5 | Status: ✓ Simple

Phase 5: Documentation
  Complexity: 7.5 | Tasks: 8 | Status: ✓ Medium

Phase 6: Deployment
  Complexity: 2.3 | Tasks: 4 | Status: ✓ Simple

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RECOMMENDATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1 phase recommended for expansion:

  Phase 3: Architecture Refactor
  Reason: Complexity 9.2 exceeds threshold 8.0, 12 tasks
  Command: /expand phase specs/plans/046_oauth2.md 3

To expand now:
  /expand phase specs/plans/046_oauth2.md 3

To expand later:
  You can expand during implementation if phases prove complex.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Visual Indicators**:
- `✓` Green indicator for simple phases (complexity ≤ 5)
- `✓` Green indicator for medium phases (complexity 5-8)
- `⚠` Yellow indicator for complex phases (complexity > 8)
- `✗` Red indicator for critical phases (complexity > 10) [rare]

**Color Coding** (ANSI escape codes):

```bash
# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage
echo -e "${GREEN}✓${NC} Simple"
echo -e "${YELLOW}⚠${NC} High - EXPANSION RECOMMENDED"
```

### Complete Implementation

**Helper Function: Get Complexity Level and Indicator**

```bash
# Function: get_complexity_indicator
# Returns visual indicator and color for complexity score
# Args: $1 = complexity score
# Returns: colored indicator + level text
get_complexity_indicator() {
  local score="$1"
  local GREEN='\033[0;32m'
  local YELLOW='\033[1;33m'
  local RED='\033[0;31m'
  local NC='\033[0m'

  if (( $(echo "$score <= 2" | bc -l) )); then
    echo -e "${GREEN}✓${NC} Trivial"
  elif (( $(echo "$score <= 5" | bc -l) )); then
    echo -e "${GREEN}✓${NC} Simple"
  elif (( $(echo "$score <= 8" | bc -l) )); then
    echo -e "${GREEN}✓${NC} Medium"
  elif (( $(echo "$score <= 10" | bc -l) )); then
    echo -e "${YELLOW}⚠${NC} High - EXPANSION RECOMMENDED"
  else
    echo -e "${RED}✗${NC} Critical - EXPANSION RECOMMENDED"
  fi
}
```

**Main Display Function**:

```bash
# Function: display_complexity_analysis
# Shows complexity table for all phases with recommendations
# Args: $1 = plan file path
#       $2 = expansion threshold
#       $3 = task count threshold
display_complexity_analysis() {
  local plan_file="$1"
  local expansion_threshold="$2"
  local task_count_threshold="$3"

  # Colors
  local BLUE='\033[0;34m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[1;33m'
  local NC='\033[0m'

  # Parse total phases
  local total_phases=$(grep -c "^### Phase [0-9]" "$plan_file")

  # Arrays to track recommendations
  local -a recommended_phases
  local -a recommended_reasons
  local -a recommended_commands

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${BLUE}PHASE COMPLEXITY ANALYSIS${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Analyze each phase
  for phase_num in $(seq 1 "$total_phases"); do
    # Extract phase info
    phase_content=$(extract_phase_content "$plan_file" "$phase_num")
    phase_name=$(echo "$phase_content" | grep "^### Phase $phase_num:" | \
                 sed 's/^### Phase [0-9]*: //' | sed 's/ *\*\*Objective\*\*.*//')
    task_list=$(echo "$phase_content" | grep "^- \[ \]")

    # Calculate metrics
    complexity_score=$(calculate_phase_complexity "$phase_name" "$task_list")
    task_count=$(echo "$task_list" | wc -l)

    # Determine recommendation
    local recommend=false
    local reason=""

    if (( $(echo "$complexity_score > $expansion_threshold" | bc -l) )); then
      recommend=true
      reason="Complexity $complexity_score exceeds threshold $expansion_threshold"
    fi

    if [ "$task_count" -gt "$task_count_threshold" ]; then
      recommend=true
      if [ -n "$reason" ]; then
        reason="$reason, $task_count tasks exceeds threshold $task_count_threshold"
      else
        reason="$task_count tasks exceeds threshold $task_count_threshold"
      fi
    fi

    # Get indicator
    indicator=$(get_complexity_indicator "$complexity_score")

    # Display phase analysis
    echo "Phase $phase_num: $phase_name"
    echo "  Complexity: $complexity_score | Tasks: $task_count | Status: $indicator"

    # Store recommendation if needed
    if [ "$recommend" = true ]; then
      recommended_phases+=("$phase_num")
      recommended_reasons+=("$reason")
      recommended_commands+=("/expand phase $plan_file $phase_num")
      echo -e "  ${YELLOW}Recommendation: Expand to separate file${NC}"
    fi

    echo ""
  done

  # Show recommendations section
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${BLUE}RECOMMENDATIONS${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if [ ${#recommended_phases[@]} -eq 0 ]; then
    echo -e "${GREEN}All phases are appropriately scoped for inline format.${NC}"
    echo ""
    echo "No expansion needed at this time. Phases can be expanded during"
    echo "implementation if they prove more complex than anticipated."
  else
    echo "${#recommended_phases[@]} phase(s) recommended for expansion:"
    echo ""

    for i in "${!recommended_phases[@]}"; do
      local phase_num="${recommended_phases[$i]}"
      local reason="${recommended_reasons[$i]}"
      local command="${recommended_commands[$i]}"

      # Get phase name again
      phase_content=$(extract_phase_content "$plan_file" "$phase_num")
      phase_name=$(echo "$phase_content" | grep "^### Phase $phase_num:" | \
                   sed 's/^### Phase [0-9]*: //' | sed 's/ *\*\*Objective\*\*.*//')

      echo "  Phase $phase_num: $phase_name"
      echo "  Reason: $reason"
      echo -e "  Command: ${BLUE}$command${NC}"
      echo ""
    done

    echo "To expand now:"
    for command in "${recommended_commands[@]}"; do
      echo -e "  ${BLUE}$command${NC}"
    done
    echo ""
    echo "To expand later:"
    echo "  You can expand during implementation if phases prove complex."
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}
```

**Integration into /plan Command**:

```bash
# In /plan command, after post-creation evaluation (Task 6.1)

# Calculate and display complexity analysis for all phases
display_complexity_analysis "$plan_file" "$EXPANSION_THRESHOLD" "$TASK_COUNT_THRESHOLD"
```

**Interactive Expansion Prompt (Optional)**:

```bash
# After displaying recommendations, optionally prompt user

if [ ${#recommended_phases[@]} -gt 0 ]; then
  echo ""
  read -p "Expand recommended phases now? (y/n): " answer

  if [[ "$answer" =~ ^[Yy]$ ]]; then
    for phase_num in "${recommended_phases[@]}"; do
      echo "Expanding Phase $phase_num..."
      /expand phase "$plan_file" "$phase_num"

      # Update plan path after first expansion
      plan_base=$(basename "$plan_file" .md)
      if [[ -d "specs/plans/$plan_base" ]]; then
        plan_file="specs/plans/$plan_base/$plan_base.md"
      fi
    done

    echo ""
    echo "All recommended phases expanded."
    echo "Plan ready: $plan_file"
  else
    echo ""
    echo "Skipping expansion. You can expand later using the commands above."
  fi
fi
```

### Display Examples

**Example 1: All Simple Phases**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE COMPLEXITY ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase 1: Setup
  Complexity: 1.5 | Tasks: 2 | Status: ✓ Trivial

Phase 2: Implementation
  Complexity: 3.2 | Tasks: 5 | Status: ✓ Simple

Phase 3: Testing
  Complexity: 2.8 | Tasks: 4 | Status: ✓ Simple

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RECOMMENDATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

All phases are appropriately scoped for inline format.

No expansion needed at this time. Phases can be expanded during
implementation if they prove more complex than anticipated.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Example 2: Mixed Complexity**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE COMPLEXITY ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase 1: Foundation
  Complexity: 2.1 | Tasks: 3 | Status: ✓ Simple

Phase 2: Core Implementation
  Complexity: 6.5 | Tasks: 8 | Status: ✓ Medium

Phase 3: Architecture Refactor
  Complexity: 9.2 | Tasks: 12 | Status: ⚠ High - EXPANSION RECOMMENDED
  Recommendation: Expand to separate file

Phase 4: Testing
  Complexity: 4.1 | Tasks: 6 | Status: ✓ Simple

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RECOMMENDATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1 phase(s) recommended for expansion:

  Phase 3: Architecture Refactor
  Reason: Complexity 9.2 exceeds threshold 8.0, 12 tasks
  Command: /expand phase specs/plans/046_oauth2.md 3

To expand now:
  /expand phase specs/plans/046_oauth2.md 3

To expand later:
  You can expand during implementation if phases prove complex.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Example 3: Multiple Complex Phases**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE COMPLEXITY ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase 1: Database Migration
  Complexity: 8.5 | Tasks: 11 | Status: ⚠ High - EXPANSION RECOMMENDED
  Recommendation: Expand to separate file

Phase 2: API Refactor
  Complexity: 9.8 | Tasks: 15 | Status: ⚠ High - EXPANSION RECOMMENDED
  Recommendation: Expand to separate file

Phase 3: Security Hardening
  Complexity: 10.2 | Tasks: 13 | Status: ✗ Critical - EXPANSION RECOMMENDED
  Recommendation: Expand to separate file

Phase 4: Documentation
  Complexity: 3.1 | Tasks: 5 | Status: ✓ Simple

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RECOMMENDATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

3 phase(s) recommended for expansion:

  Phase 1: Database Migration
  Reason: Complexity 8.5 exceeds threshold 8.0, 11 tasks exceeds threshold 10
  Command: /expand phase specs/plans/050_system_overhaul.md 1

  Phase 2: API Refactor
  Reason: Complexity 9.8 exceeds threshold 8.0, 15 tasks exceeds threshold 10
  Command: /expand phase specs/plans/050_system_overhaul.md 2

  Phase 3: Security Hardening
  Reason: Complexity 10.2 exceeds threshold 8.0, 13 tasks exceeds threshold 10
  Command: /expand phase specs/plans/050_system_overhaul.md 3

To expand now:
  /expand phase specs/plans/050_system_overhaul.md 1
  /expand phase specs/plans/050_system_overhaul.md 2
  /expand phase specs/plans/050_system_overhaul.md 3

To expand later:
  You can expand during implementation if phases prove complex.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Expand recommended phases now? (y/n): _
```

### Testing Specification

**Test 1: Display Formatting (All Simple)**

```bash
# Setup: Create plan with simple phases
cat > test_display_simple.md <<'EOF'
### Phase 1: Setup
- [ ] Task 1
- [ ] Task 2

### Phase 2: Build
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
EOF

# Execute
display_complexity_analysis "test_display_simple.md" "8.0" "10"

# Verify
# - Table shows 2 phases
# - Both marked with ✓
# - No recommendations section with expansion commands
# - "All phases appropriately scoped" message shown
```

**Test 2: Color Output**

```bash
# Execute display with color
display_complexity_analysis "test_plan.md" "8.0" "10" | tee output.txt

# Verify ANSI color codes present
grep -q '\033\[0;32m' output.txt && echo "PASS: Green color code present"
grep -q '\033\[1;33m' output.txt && echo "PASS: Yellow color code present"
grep -q '✓' output.txt && echo "PASS: Checkmark symbol present"
grep -q '⚠' output.txt && echo "PASS: Warning symbol present"
```

**Test 3: Recommendation Accuracy**

```bash
# Setup: Plan with one complex phase
cat > test_rec_accuracy.md <<'EOF'
### Phase 1: Simple
- [ ] Task 1

### Phase 2: Architecture Refactor
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
- [ ] Task 4
- [ ] Task 5
- [ ] Task 6
- [ ] Task 7
- [ ] Task 8
- [ ] Task 9
- [ ] Task 10
- [ ] Task 11

### Phase 3: Simple
- [ ] Task 1
EOF

# Execute
display_complexity_analysis "test_rec_accuracy.md" "8.0" "10" > output.txt

# Verify
# - Recommendations section shows exactly 1 phase
# - Phase 2 recommended (11 tasks > 10 + "refactor" keyword)
# - Reason mentions both complexity and task count
# - Correct command shown: /expand phase test_rec_accuracy.md 2

grep -q "1 phase(s) recommended" output.txt && echo "PASS: Correct count"
grep -q "Phase 2: Architecture Refactor" output.txt && echo "PASS: Correct phase identified"
grep -q "/expand phase test_rec_accuracy.md 2" output.txt && echo "PASS: Correct command"
```

**Test 4: Interactive Prompt (If Implemented)**

```bash
# Setup: Plan with recommended expansion

# Execute with yes input
echo "y" | /plan test_interactive.md

# Verify
# - Prompt shown: "Expand recommended phases now? (y/n):"
# - Expansion executed
# - Plan structure changed to L1

test -d "test_interactive/" && echo "PASS: Interactive expansion worked"

# Execute with no input
echo "n" | /plan test_interactive2.md

# Verify
# - Prompt shown
# - Expansion skipped
# - Plan remains L0

test -f "test_interactive2.md" && \
  test ! -d "test_interactive2/" && \
  echo "PASS: Interactive skip worked"
```

## Workflow Analysis

### Before/After Comparison (Report 028:754-792)

**BEFORE Implementation**:
```
┌─────────────────────────────────────────────────────────┐
│ User invokes: /plan "Feature X"                        │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ /plan creates: specs/plans/046_feature.md (L0)         │
│ Time: ~10 seconds                                       │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ User invokes: /implement specs/plans/046_feature.md    │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ Phase 1-2 implement successfully                        │
│ Time: ~20 minutes                                       │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ Phase 3: /implement detects complexity > 8.0            │
│ [WORKFLOW INTERRUPTION]                                 │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ Auto-invoke: /revise --auto-mode expand_phase          │
│ Plan restructured: specs/plans/046_feature/ (L1)       │
│ Time: ~60 seconds                                       │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ Resume implementation with expanded phase               │
│ User experience: Confused by mid-implementation pause   │
└─────────────────────────────────────────────────────────┘

Total time: 10 sec (plan) + 60 sec (expansion during implement) = 70 sec
User experience: ❌ Interrupted workflow
```

**AFTER Implementation**:
```
┌─────────────────────────────────────────────────────────┐
│ User invokes: /plan "Feature X"                        │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ /plan creates: specs/plans/046_feature.md (L0)         │
│ Time: ~10 seconds                                       │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ [NEW] Post-creation evaluation                          │
│ - Phase 1: 2.1 (simple) ✓                               │
│ - Phase 2: 4.5 (medium) ✓                               │
│ - Phase 3: 9.2 (high) ⚠ → Auto-expand                   │
│ Time: ~60 seconds (evaluation + expansion)              │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ Plan ready: specs/plans/046_feature/ (L1)              │
│ Display: Complexity table + recommendations             │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ User invokes: /implement specs/plans/046_feature/      │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ Phase 1-3 implement smoothly (Phase 3 already expanded)│
│ [NO INTERRUPTION]                                       │
│ Time: ~25 minutes                                       │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ All phases complete                                     │
│ User experience: Seamless workflow                      │
└─────────────────────────────────────────────────────────┘

Total time: 70 sec (plan with evaluation + expansion) = 70 sec
User experience: ✓ Seamless, plan ready for implementation
```

### Performance Impact Analysis

**Time Comparison**:
- Before: 10 sec (/plan) + [later] 60 sec (expansion during /implement)
- After: 70 sec (/plan with evaluation)
- **Net difference**: 0 seconds (same total time)

**User Experience Impact**:
- Before: ❌ Workflow interruption mid-implementation
- After: ✓ Seamless implementation, plan ready upfront

**Overhead Analysis**:
- Complexity evaluation: <1 sec per phase × 6 phases = ~6 sec
- Expansion (if triggered): 30-60 sec per complex phase
- Total overhead: Negligible (evaluation), moved from /implement to /plan

### Integration with Existing /implement Workflow

**Relationship to Step 1.55 (Proactive Expansion Check)**:

From implement.md Step 1.55:
```
Before implementation begins, evaluate if the phase should be expanded
using agent-based judgment.
```

**With Phase 6 Implementation**:
- **At /plan time**: Complexity-based auto-expansion (Task 6.1)
- **At /implement time** (Step 1.55): Still evaluates phases proactively
  - Why? Handles phases that became complex after plan creation
  - Why? User might have skipped auto-expansion (if interactive)
  - Why? Thresholds might have changed between /plan and /implement

**Relationship to Step 3.4 (Reactive Expansion Check)**:

From implement.md Step 3.4:
```
After each phase implementation (successful or with errors), check if
plan revision is needed.
```

**With Phase 6 Implementation**:
- **At /plan time**: Prevents most reactive expansions
- **At /implement Step 3.4**: Still checks for complexity triggers
  - Why? Handles complexity discovered **during** implementation
  - Why? Handles test failure patterns (different trigger)
  - Why? Handles scope drift (manual flag)

**Complementary, Not Redundant**:
- `/plan` (Task 6.1): Proactive evaluation based on **plan content**
- `/implement` Step 1.55: Proactive evaluation based on **context before starting**
- `/implement` Step 3.4: Reactive evaluation based on **implementation experience**

All three work together for optimal planning structure.

## Code Examples

### Example 1: Complete Evaluation Loop

```bash
#!/bin/bash
# Post-creation evaluation (complete implementation)

set -euo pipefail

# Configuration
PLAN_FILE="specs/plans/046_oauth2_auth.md"
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/home/benjamin/.config}"

# Source utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh"

# Read thresholds from CLAUDE.md
read_threshold() {
  local threshold_name="$1"
  local default_value="$2"

  # Find CLAUDE.md
  local claude_md=""
  if [ -f "CLAUDE.md" ]; then
    claude_md="CLAUDE.md"
  elif [ -f "$CLAUDE_PROJECT_DIR/CLAUDE.md" ]; then
    claude_md="$CLAUDE_PROJECT_DIR/CLAUDE.md"
  fi

  [ -z "$claude_md" ] && echo "$default_value" && return

  # Extract value
  local value=$(grep -E "^\s*-\s+\*\*$threshold_name\*\*:" "$claude_md" | \
                grep -oE '[0-9]+(\.[0-9]+)?' | head -1)

  # Validate
  [[ "$value" =~ ^[0-9]+(\.[0-9]+)?$ ]] && echo "$value" || echo "$default_value"
}

# Read thresholds
EXPANSION_THRESHOLD=$(read_threshold "Expansion Threshold" "8.0")
TASK_COUNT_THRESHOLD=$(read_threshold "Task Count Threshold" "10")

echo "Thresholds: Expansion=$EXPANSION_THRESHOLD, Tasks=$TASK_COUNT_THRESHOLD"
echo ""

# Parse phases
total_phases=$(grep -c "^### Phase [0-9]" "$PLAN_FILE")
echo "Evaluating $total_phases phases..."
echo ""

# Track expansions
expanded_count=0

# Evaluate each phase
for phase_num in $(seq 1 "$total_phases"); do
  # Extract phase content
  phase_content=$(sed -n "/^### Phase $phase_num:/,/^### Phase\|^## /p" "$PLAN_FILE" | sed '$d')
  phase_name=$(echo "$phase_content" | grep "^### Phase $phase_num:" | \
               sed 's/^### Phase [0-9]*: //' | sed 's/ *\*\*Objective\*\*.*//')
  task_list=$(echo "$phase_content" | grep "^- \[ \]")

  # Calculate complexity
  complexity_score=$(calculate_phase_complexity "$phase_name" "$task_list")
  task_count=$(echo "$task_list" | wc -l)

  # Decide expansion
  should_expand=false
  if (( $(echo "$complexity_score > $EXPANSION_THRESHOLD" | bc -l) )); then
    should_expand=true
  fi
  if [ "$task_count" -gt "$TASK_COUNT_THRESHOLD" ]; then
    should_expand=true
  fi

  # Expand if needed
  if [ "$should_expand" = "true" ]; then
    echo "Phase $phase_num: $phase_name (complexity $complexity_score, $task_count tasks)"
    echo "  Auto-expanding..."

    "$CLAUDE_PROJECT_DIR/.claude/commands/expand" phase "$PLAN_FILE" "$phase_num"

    expanded_count=$((expanded_count + 1))

    # Update path
    plan_base=$(basename "$PLAN_FILE" .md)
    if [[ -d "specs/plans/$plan_base" ]]; then
      PLAN_FILE="specs/plans/$plan_base/$plan_base.md"
    fi
  else
    echo "Phase $phase_num: $phase_name (complexity $complexity_score, $task_count tasks) - OK"
  fi
done

echo ""
echo "Evaluation complete. Expanded $expanded_count phases."
echo "Plan ready: $PLAN_FILE"
```

### Example 2: Threshold Reading Function

```bash
# Complete threshold reading with validation

read_threshold() {
  local threshold_name="$1"
  local default_value="$2"
  local min_value="${3:-0}"
  local max_value="${4:-100}"

  # Find CLAUDE.md (search upward from pwd)
  local claude_md=""
  local search_dir="$(pwd)"

  while [ "$search_dir" != "/" ]; do
    if [ -f "$search_dir/CLAUDE.md" ]; then
      claude_md="$search_dir/CLAUDE.md"
      break
    fi
    search_dir=$(dirname "$search_dir")
  done

  # Check project directory as fallback
  if [ -z "$claude_md" ] && [ -n "$CLAUDE_PROJECT_DIR" ]; then
    if [ -f "$CLAUDE_PROJECT_DIR/CLAUDE.md" ]; then
      claude_md="$CLAUDE_PROJECT_DIR/CLAUDE.md"
    fi
  fi

  # No CLAUDE.md found
  if [ -z "$claude_md" ]; then
    echo "$default_value"
    return
  fi

  # Extract threshold value
  local threshold_value=$(grep -E "^\s*-\s+\*\*$threshold_name\*\*:" "$claude_md" | \
                          grep -oE '[0-9]+(\.[0-9]+)?' | head -1)

  # No threshold found
  if [ -z "$threshold_value" ]; then
    echo "$default_value"
    return
  fi

  # Validate numeric
  if ! [[ "$threshold_value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Warning: Invalid threshold '$threshold_value', using default" >&2
    echo "$default_value"
    return
  fi

  # Range validation
  if (( $(echo "$threshold_value < $min_value" | bc -l) )) || \
     (( $(echo "$threshold_value > $max_value" | bc -l) )); then
    echo "Warning: Threshold out of range [$min_value, $max_value], using default" >&2
    echo "$default_value"
    return
  fi

  # Valid threshold
  echo "$threshold_value"
}

# Usage examples
EXPANSION_THRESHOLD=$(read_threshold "Expansion Threshold" "8.0" "0.0" "15.0")
TASK_COUNT_THRESHOLD=$(read_threshold "Task Count Threshold" "10" "5" "20")
REPLAN_LIMIT=$(read_threshold "Replan Limit" "2" "1" "5")
```

### Example 3: Display Formatting

```bash
# Display complexity table with colors and indicators

display_complexity_analysis() {
  local plan_file="$1"
  local expansion_threshold="$2"
  local task_count_threshold="$3"

  # Colors
  local GREEN='\033[0;32m'
  local YELLOW='\033[1;33m'
  local RED='\033[0;31m'
  local BLUE='\033[0;34m'
  local NC='\033[0m'

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${BLUE}PHASE COMPLEXITY ANALYSIS${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Parse phases
  local total_phases=$(grep -c "^### Phase [0-9]" "$plan_file")
  local -a recommended_phases

  for phase_num in $(seq 1 "$total_phases"); do
    # Extract phase info
    phase_content=$(sed -n "/^### Phase $phase_num:/,/^### Phase\|^## /p" "$plan_file" | sed '$d')
    phase_name=$(echo "$phase_content" | grep "^### Phase $phase_num:" | \
                 sed 's/^### Phase [0-9]*: //' | sed 's/ *\*\*Objective\*\*.*//')
    task_list=$(echo "$phase_content" | grep "^- \[ \]")

    # Calculate metrics
    complexity_score=$(calculate_phase_complexity "$phase_name" "$task_list")
    task_count=$(echo "$task_list" | wc -l)

    # Get indicator
    local indicator
    if (( $(echo "$complexity_score <= 2" | bc -l) )); then
      indicator="${GREEN}✓${NC} Trivial"
    elif (( $(echo "$complexity_score <= 5" | bc -l) )); then
      indicator="${GREEN}✓${NC} Simple"
    elif (( $(echo "$complexity_score <= 8" | bc -l) )); then
      indicator="${GREEN}✓${NC} Medium"
    else
      indicator="${YELLOW}⚠${NC} High - EXPANSION RECOMMENDED"
    fi

    # Display
    echo "Phase $phase_num: $phase_name"
    echo -e "  Complexity: $complexity_score | Tasks: $task_count | Status: $indicator"

    # Track recommendations
    if (( $(echo "$complexity_score > $expansion_threshold" | bc -l) )) || \
       [ "$task_count" -gt "$task_count_threshold" ]; then
      recommended_phases+=("$phase_num")
      echo -e "  ${YELLOW}Recommendation: Expand to separate file${NC}"
    fi

    echo ""
  done

  # Show recommendations
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${BLUE}RECOMMENDATIONS${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if [ ${#recommended_phases[@]} -eq 0 ]; then
    echo -e "${GREEN}All phases are appropriately scoped for inline format.${NC}"
  else
    echo "${#recommended_phases[@]} phase(s) recommended for expansion:"
    echo ""
    for phase_num in "${recommended_phases[@]}"; do
      echo -e "  ${BLUE}/expand phase $plan_file $phase_num${NC}"
    done
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}
```

### Example 4: Integration (All Three Tasks Together)

```bash
#!/bin/bash
# Complete integration example for /plan command

set -euo pipefail

# After plan is created and saved...
plan_file="specs/plans/050_new_feature.md"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "POST-CREATION EVALUATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Source utilities
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/home/benjamin/.config}"
source "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh"

# Task 6.2: Read configurable thresholds
EXPANSION_THRESHOLD=$(read_threshold "Expansion Threshold" "8.0" "0.0" "15.0")
TASK_COUNT_THRESHOLD=$(read_threshold "Task Count Threshold" "10" "5" "20")

echo "Using thresholds:"
echo "  Expansion: $EXPANSION_THRESHOLD"
echo "  Task Count: $TASK_COUNT_THRESHOLD"
echo ""

# Task 6.1: Post-creation phase evaluation
total_phases=$(grep -c "^### Phase [0-9]" "$plan_file")
echo "Evaluating $total_phases phases..."
echo ""

for phase_num in $(seq 1 "$total_phases"); do
  # Extract phase content
  phase_content=$(sed -n "/^### Phase $phase_num:/,/^### Phase\|^## /p" "$plan_file" | sed '$d')
  phase_name=$(echo "$phase_content" | grep "^### Phase $phase_num:" | sed 's/^### Phase [0-9]*: //')
  task_list=$(echo "$phase_content" | grep "^- \[ \]")

  # Calculate complexity
  complexity_score=$(calculate_phase_complexity "$phase_name" "$task_list")
  task_count=$(echo "$task_list" | wc -l)

  # Auto-expand if needed
  if (( $(echo "$complexity_score > $EXPANSION_THRESHOLD" | bc -l) )) || \
     [ "$task_count" -gt "$TASK_COUNT_THRESHOLD" ]; then
    echo "Phase $phase_num: Auto-expanding (complexity $complexity_score, $task_count tasks)"

    "$CLAUDE_PROJECT_DIR/.claude/commands/expand" phase "$plan_file" "$phase_num"

    # Update path
    plan_base=$(basename "$plan_file" .md)
    if [[ -d "specs/plans/$plan_base" ]]; then
      plan_file="specs/plans/$plan_base/$plan_base.md"
    fi
  else
    echo "Phase $phase_num: OK (complexity $complexity_score, $task_count tasks)"
  fi
done

echo ""

# Task 6.3: Display expansion recommendations
display_complexity_analysis "$plan_file" "$EXPANSION_THRESHOLD" "$TASK_COUNT_THRESHOLD"

echo "Plan ready: $plan_file"
echo ""
```

## Deliverables

1. **Post-creation phase evaluation** in /plan command
2. **Configurable thresholds** section in CLAUDE.md template
3. **Threshold reading logic** in /plan, /expand, /implement
4. **Expansion recommendations display** in plan output
5. **Tests** validating auto-expansion and configuration

## Files Modified

- `.claude/commands/plan.md` - Add post-creation evaluation (Task 6.1)
- `.claude/commands/expand.md` - Read thresholds from CLAUDE.md (Task 6.2)
- `.claude/commands/implement.md` - Read thresholds from CLAUDE.md (Task 6.2)
- `CLAUDE.md` - Add Adaptive Planning Configuration section template (Task 6.2)

## Notes

**Implementation Phases from Report 028**:
- ✅ Phase 1: Post-Creation Evaluation (Task 6.1)
- ✅ Phase 2: Configurable Thresholds (Task 6.2)
- ⏸️ Phase 3: Expansion Recommendations (Task 6.3 - display only, not preview flags)
- ⏸️ Phase 4: Preview Flags (deferred - `--dry-run` for /expand)
- ⏸️ Phase 5: Smart Re-Evaluation (deferred - post-revision complexity check)

**Future Optimization**:
- Use `/expand phase` command to create detailed specifications for Phases 3-5
- Report 028 provides complete implementation guidance for deferred phases

**Workflow Improvement**:
```
BEFORE:
  /plan → Plan (L0) → /implement → [Pause] → Auto-expand → Resume

AFTER:
  /plan → [Auto-evaluate] → Auto-expand → Plan (L1) → /implement → [Smooth]
```

**Report Reference**: See `.claude/specs/reports/028_adaptive_plan_workflow_analysis.md` for:
- Complete workflow analysis (lines 1-68)
- Post-creation evaluation gap (lines 221-268)
- Full 5-phase roadmap (lines 638-717)
- Performance considerations (lines 719-753)
