# Phase 7: Bidirectional Structure Optimization

## Phase Metadata
- **Phase Number**: 7
- **Parent Plan**: 035_deferred_tasks_completion.md
- **Objective**: Enable /revise to automatically evaluate and recommend expansion/collapse with auto-mode collapse support
- **Complexity**: High (8/10)
- **Estimated Time**: 6-8 hours (COMPLETED in ~6 hours)
- **Reference**: Report 029 Phases 1-3 (lines 377-623)
- **Status**: COMPLETED ✓

## Task Status
- **Task 7.1**: COMPLETED (Structure Evaluation to /revise) ✓
- **Task 7.2**: COMPLETED (Auto-Mode Collapse Support) ✓
- **Task 7.3**: COMPLETED (Collapse Logging) ✓

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Task 7.1: Add Structure Evaluation to /revise](#task-71-add-structure-evaluation-to-revise)
3. [Task 7.2: Add Auto-Mode Collapse Support](#task-72-add-auto-mode-collapse-support)
4. [Task 7.3: Add Collapse Logging](#task-73-add-collapse-logging)
5. [Workflow Analysis](#workflow-analysis)
6. [Integration and Dependencies](#integration-and-dependencies)
7. [Code Examples](#code-examples)

---

## Architecture Overview

### Bidirectional Structure Management Concept

The current `.claude/` system supports **expansion** (simple → complex) excellently but has limited **collapse** (complex → simple) integration. Phase 7 completes the bidirectional optimization loop:

**Current State**:
- ✅ Expansion: Automatic via `/implement` Step 3.4 adaptive planning
- ✅ Expansion: Recommendations via `/implement` Step 1.55 proactive check
- ⚠️ Collapse: Detection only via `/implement` Step 5.5 (informational)
- ❌ Collapse: No automatic execution
- ❌ `/revise`: No structure evaluation after content changes

**Phase 7 Additions**:
- ✅ `/revise`: Post-revision structure evaluation (both collapse and expansion recommendations)
- ✅ Auto-collapse: Automatic collapse via `/revise --auto-mode collapse_phase`
- ✅ Logging: Collapse operations tracked in adaptive-planning.log

### Integration Surface Area

Phase 7 touches **4 commands** and **1 core library**:

1. **`.claude/commands/revise.md`** (596 lines)
   - Add structure evaluation after content modifications
   - Add `collapse_phase` revision type to auto-mode
   - Display recommendations in revision history

2. **`.claude/commands/implement.sh`** (1553 lines)
   - Update Step 5.5 to trigger auto-collapse via `/revise --auto-mode`
   - Build collapse context JSON
   - Log collapse invocations

3. **`.claude/commands/collapse.sh`** (556 lines)
   - Add manual collapse logging
   - Integration point for logging functions

4. **`.claude/lib/adaptive-planning-logger.sh`** (297 lines)
   - Add `log_collapse_check()` function
   - Add `log_collapse_invocation()` function
   - Maintain consistency with expansion logging

5. **Utility libraries** (read-only dependencies):
   - `.claude/lib/parse-adaptive-plan.sh` - Structure detection
   - `.claude/lib/complexity-utils.sh` - Complexity scoring

### Structure Evaluation Algorithm

**Collapse Opportunity Detection**:
```
IF phase is expanded (in separate file)
  AND phase complexity ≤ threshold (tasks ≤5, score <6.0)
  AND phase completion = true (optional, stronger signal)
THEN recommend collapse
```

**Expansion Opportunity Detection**:
```
IF phase is inline (in main plan)
  AND phase complexity > threshold (tasks >10 OR score >8.0)
THEN recommend expansion
```

**Evaluation Context**:
- **When**: After `/revise` modifies plan content
- **What**: Evaluate all phases affected by revision
- **How**: Use existing complexity calculation + structure detection utilities
- **Output**: Recommendations displayed in revision history

### Auto-Mode Collapse Workflow

```
/implement Step 5.5 (Phase Complete)
    ↓
Detect: Phase expanded + simple + complete
    ↓
Build collapse_phase context JSON
    ↓
Invoke: /revise --auto-mode --context '{...}'
    ↓
/revise auto-mode handler:
  - Parse collapse_phase request
  - Invoke: /collapse phase <plan> <phase-num>
  - Update metadata (structure level, expanded phases)
  - Return success JSON
    ↓
/implement logs auto-collapse action
    ↓
Continue to next phase
```

### Logging and Observability Strategy

**Consistency with Expansion Logging**:

Existing expansion logging (from Phase 2):
- `log_complexity_check()` - Expansion opportunity detection
- `log_replan_invocation()` - Auto-expansion via `/revise --auto-mode`

New collapse logging (Phase 7):
- `log_collapse_check()` - Collapse opportunity detection
- `log_collapse_invocation()` - Manual and auto-collapse operations

**Log Event Types**:
- `collapse_check` - Collapse opportunity evaluated (INFO level)
- `collapse_invocation` - Collapse operation executed (INFO level)

**Log Queries**:
```bash
# Recent collapse checks
query_adaptive_log "collapse_check" 10

# Auto-collapse invocations only
query_adaptive_log "collapse_invocation" | jq 'select(.data.trigger=="auto")'

# All structure optimization events
query_adaptive_log | grep -E "collapse|complexity"
```

### Performance and Safety Considerations

**Performance**:
- Structure evaluation: ~0.5-1 second per phase (complexity calculation)
- Collapse operation: 2-5 seconds per phase (file I/O, metadata updates)
- Impact on `/revise`: +1-2 seconds for recommendations (acceptable)

**Safety**:
- Non-blocking recommendations: User retains full control
- Automatic collapse: Only triggered for truly simple, completed phases
- Metadata consistency: Three-way updates (stage → phase → main plan)
- Reversible operations: All collapses can be re-expanded if needed

**Edge Cases**:
- Phase with expanded stages: Cannot collapse (must collapse stages first)
- Incomplete phase: Collapse not recommended (completion unclear)
- Complex interdependencies: Keep expanded even if simple (judgment call)

---

## Task 7.1: Add Structure Evaluation to /revise

**Objective**: Automatically evaluate and recommend expansion/collapse opportunities after revising plan content.

**Estimated Time**: 3-4 hours

### Design Analysis

#### Post-Revision Evaluation Trigger

**When to Evaluate**:
- **Interactive mode**: After user-driven content modifications
- **Auto-mode**: After automated revisions (expand_phase, add_phase, split_phase, update_tasks)
- **Not triggered**: If revision fails or is read-only

**Which Revisions Trigger Evaluation**:
1. **Content simplification**: Removing tasks → May enable collapse
2. **Content expansion**: Adding tasks → May require expansion
3. **Phase splitting**: Creating new phases → Evaluate each new phase
4. **Phase updates**: Modifying existing phases → Re-evaluate affected phases

**Evaluation Scope**:
- Only evaluate phases **modified by the revision**
- Skip phases with no content changes
- Detect affected phases from revision history or edit operations

#### Affected Phases Detection

**Approach 1: Track During Revision** (Recommended)
```bash
# During revision process, maintain list of modified phases
AFFECTED_PHASES=()

# When phase content is modified
AFFECTED_PHASES+=("$PHASE_NUM")

# After all edits complete
for phase_num in "${AFFECTED_PHASES[@]}"; do
  evaluate_structure_opportunity "$phase_num"
done
```

**Approach 2: Analyze Revision Description**
```bash
# Parse revision history entry for mentioned phases
REVISION_ENTRY="Modified Phases: 2, 3, 5"
AFFECTED_PHASES=$(echo "$REVISION_ENTRY" | grep "Modified Phases:" | sed 's/.*: //' | tr ',' '\n')
```

#### Structure State Detection

**Use Existing Utilities**:
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/parse-adaptive-plan.sh"

# Check if phase is currently expanded
is_expanded=$(is_phase_expanded "$plan_path" "$phase_num")

if [ "$is_expanded" = "true" ]; then
  # Evaluate collapse opportunity
  evaluate_collapse_opportunity "$phase_num" "$plan_path"
else
  # Evaluate expansion opportunity
  evaluate_expansion_opportunity "$phase_num" "$plan_path"
fi
```

**Structure Detection Logic**:
- `is_phase_expanded()` returns "true" if phase file exists in plan directory
- `is_plan_expanded()` returns "true" if plan directory exists
- `get_phase_file()` returns path to expanded phase file (or empty if not expanded)

### Implementation: Evaluation Functions

#### Function: evaluate_collapse_opportunity()

**Purpose**: Determine if an expanded phase is simple enough to collapse back to inline.

**Implementation**:
```bash
#!/usr/bin/env bash
# Evaluate if expanded phase should be collapsed
# Args:
#   $1: phase_num
#   $2: plan_path
# Returns: "true" or "false"

evaluate_collapse_opportunity() {
  local phase_num="$1"
  local plan_path="$2"

  # Source utilities
  source "$CLAUDE_PROJECT_DIR/.claude/lib/parse-adaptive-plan.sh"
  source "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh"

  # Get phase file path
  local phase_file=$(get_phase_file "$plan_path" "$phase_num")

  if [ -z "$phase_file" ] || [ ! -f "$phase_file" ]; then
    echo "false"
    return 1
  fi

  # Extract phase content for analysis
  local phase_content=$(cat "$phase_file")
  local phase_name=$(grep "^### Phase $phase_num" "$phase_file" | head -1 | sed "s/^### Phase $phase_num:* //")

  # Count tasks (unchecked and checked)
  local task_count=$(echo "$phase_content" | grep -c "^- \[[ x]\]" || echo "0")

  # Calculate complexity score
  local complexity_score=$(calculate_phase_complexity "$phase_name" "$phase_content")

  # Collapse thresholds: tasks ≤ 5 AND complexity < 6.0
  if [ "$task_count" -le 5 ]; then
    # Use awk for floating point comparison
    if awk -v score="$complexity_score" 'BEGIN {exit !(score < 6.0)}'; then
      echo "true"
      return 0
    fi
  fi

  echo "false"
  return 1
}
```

**Thresholds Rationale**:
- **Tasks ≤ 5**: Simple phases with few tasks don't need separate files
- **Complexity < 6.0**: Medium-low complexity (from complexity-utils.sh scale)
- **AND condition**: Both must be true (conservative approach)

**Edge Cases**:
- Phase with expanded stages: Return "false" (cannot collapse)
- Missing phase file: Return "false" (not expanded)
- Malformed phase content: Default to "false" (safe fallback)

#### Function: evaluate_expansion_opportunity()

**Purpose**: Determine if an inline phase is complex enough to warrant expansion.

**Implementation**:
```bash
#!/usr/bin/env bash
# Evaluate if inline phase should be expanded
# Args:
#   $1: phase_num
#   $2: plan_path
# Returns: "true" or "false"

evaluate_expansion_opportunity() {
  local phase_num="$1"
  local plan_path="$2"

  # Source utilities
  source "$CLAUDE_PROJECT_DIR/.claude/lib/parse-adaptive-plan.sh"
  source "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh"

  # Determine main plan file location
  local plan_file="$plan_path"
  if [ -d "$plan_path" ]; then
    local plan_name=$(basename "$plan_path")
    plan_file="$plan_path/$plan_name.md"
  fi

  if [ ! -f "$plan_file" ]; then
    echo "false"
    return 1
  fi

  # Extract phase content from main plan
  local phase_content=$(extract_phase_content "$plan_file" "$phase_num")

  if [ -z "$phase_content" ]; then
    echo "false"
    return 1
  fi

  # Extract phase name
  local phase_name=$(echo "$phase_content" | grep "^### Phase $phase_num" | head -1 | sed "s/^### Phase $phase_num:* //")

  # Count tasks
  local task_count=$(echo "$phase_content" | grep -c "^- \[[ x]\]" || echo "0")

  # Calculate complexity score
  local complexity_score=$(calculate_phase_complexity "$phase_name" "$phase_content")

  # Expansion thresholds: tasks > 10 OR complexity > 8.0
  if [ "$task_count" -gt 10 ]; then
    echo "true"
    return 0
  fi

  # Use awk for floating point comparison
  if awk -v score="$complexity_score" 'BEGIN {exit !(score > 8.0)}'; then
    echo "true"
    return 0
  fi

  echo "false"
  return 1
}
```

**Thresholds Rationale**:
- **Tasks > 10**: Many tasks benefit from separate file organization
- **Complexity > 8.0**: High complexity (matches `/implement` Step 3.4 threshold)
- **OR condition**: Either criterion is sufficient (aggressive expansion)

**Relationship to /implement Step 1.55**:
- Step 1.55: Proactive expansion check (agent-based judgment, pre-implementation)
- Task 7.1: Post-revision evaluation (heuristic-based, after content changes)
- Both serve different purposes: proactive planning vs reactive optimization

#### Helper Function: get_affected_phases()

**Purpose**: Identify which phases were modified by the revision.

**Implementation**:
```bash
#!/usr/bin/env bash
# Get list of phases affected by revision
# Args:
#   $1: plan_path
#   $2: revision_description (from user input or auto-mode context)
# Returns: Space-separated list of phase numbers

get_affected_phases() {
  local plan_path="$1"
  local revision_desc="$2"

  # Approach 1: Parse revision description for phase mentions
  # Look for patterns: "Phase 2", "Phase 3 and 4", "Phases 2, 3, 5"
  local phases=$(echo "$revision_desc" | grep -oE "Phase [0-9]+" | sed 's/Phase //' | sort -n | uniq | tr '\n' ' ')

  # Approach 2: If no explicit mentions, check all phases (conservative)
  if [ -z "$phases" ]; then
    # Count total phases in plan
    local plan_file="$plan_path"
    if [ -d "$plan_path" ]; then
      local plan_name=$(basename "$plan_path")
      plan_file="$plan_path/$plan_name.md"
    fi

    local total_phases=$(grep -c "^### Phase [0-9]" "$plan_file" 2>/dev/null || echo "0")
    phases=$(seq 1 "$total_phases" | tr '\n' ' ')
  fi

  echo "$phases"
}
```

**Fallback Strategy**:
- If specific phases mentioned: Evaluate only those
- If no phases mentioned: Evaluate all phases (safe but slower)
- Future enhancement: Track phases via AFFECTED_PHASES array during edits

### Implementation: Structure Recommendations Display

#### Function: display_structure_recommendations()

**Purpose**: Format and display collapse/expansion recommendations in user-friendly format.

**Implementation**:
```bash
#!/usr/bin/env bash
# Display structure optimization recommendations
# Args:
#   $1: plan_path
#   $2: affected_phases (space-separated list)
# Output: Formatted recommendations

display_structure_recommendations() {
  local plan_path="$1"
  local affected_phases="$2"

  local collapse_recommendations=()
  local expansion_recommendations=()

  # Evaluate each affected phase
  for phase_num in $affected_phases; do
    # Check current state
    local is_expanded=$(is_phase_expanded "$plan_path" "$phase_num")

    if [ "$is_expanded" = "true" ]; then
      # Evaluate collapse
      local should_collapse=$(evaluate_collapse_opportunity "$phase_num" "$plan_path")
      if [ "$should_collapse" = "true" ]; then
        # Get phase details for display
        local phase_file=$(get_phase_file "$plan_path" "$phase_num")
        local task_count=$(grep -c "^- \[[ x]\]" "$phase_file" || echo "0")
        local phase_name=$(grep "^### Phase $phase_num" "$phase_file" | head -1 | sed "s/^### Phase $phase_num:* //" | sed 's/ \[.*\]$//')
        local complexity=$(calculate_phase_complexity "$phase_name" "$(cat "$phase_file")")

        collapse_recommendations+=("Phase $phase_num: $phase_name (${task_count} tasks, complexity ${complexity})")
      fi
    else
      # Evaluate expansion
      local should_expand=$(evaluate_expansion_opportunity "$phase_num" "$plan_path")
      if [ "$should_expand" = "true" ]; then
        # Get phase details
        local plan_file="$plan_path"
        if [ -d "$plan_path" ]; then
          plan_file="$plan_path/$(basename "$plan_path").md"
        fi

        local phase_content=$(extract_phase_content "$plan_file" "$phase_num")
        local task_count=$(echo "$phase_content" | grep -c "^- \[[ x]\]" || echo "0")
        local phase_name=$(echo "$phase_content" | grep "^### Phase $phase_num" | head -1 | sed "s/^### Phase $phase_num:* //" | sed 's/ \[.*\]$//')
        local complexity=$(calculate_phase_complexity "$phase_name" "$phase_content")

        expansion_recommendations+=("Phase $phase_num: $phase_name (${task_count} tasks, complexity ${complexity})")
      fi
    fi
  done

  # Display recommendations if any exist
  if [ ${#collapse_recommendations[@]} -gt 0 ] || [ ${#expansion_recommendations[@]} -gt 0 ]; then
    echo ""
    echo "**Structure Recommendations**:"

    # Collapse recommendations
    if [ ${#collapse_recommendations[@]} -gt 0 ]; then
      echo ""
      echo "*Collapse Opportunities (simple expanded phases):*"
      for rec in "${collapse_recommendations[@]}"; do
        local phase_num=$(echo "$rec" | grep -oE "Phase [0-9]+" | sed 's/Phase //')
        echo "- $rec"
        echo "  - Command: \`/collapse phase $(realpath "$plan_path") $phase_num\`"
      done
    fi

    # Expansion recommendations
    if [ ${#expansion_recommendations[@]} -gt 0 ]; then
      echo ""
      echo "*Expansion Opportunities (complex inline phases):*"
      for rec in "${expansion_recommendations[@]}"; do
        local phase_num=$(echo "$rec" | grep -oE "Phase [0-9]+" | sed 's/Phase //')
        echo "- $rec"
        echo "  - Command: \`/expand phase $(realpath "$plan_path") $phase_num\`"
      done
    fi
  fi
}
```

**Output Format**:
```markdown
**Structure Recommendations**:

*Collapse Opportunities (simple expanded phases):*
- Phase 3: Database Setup (4 tasks, complexity 3.2)
  - Command: `/collapse phase specs/plans/025_plan/ 3`

*Expansion Opportunities (complex inline phases):*
- Phase 5: Security Audit (14 tasks, complexity 9.5)
  - Command: `/expand phase specs/plans/025_plan/ 5`
```

**Integration Location**:
- Append to revision history section in main plan file
- Display after revision completion message
- Non-blocking: User can act on recommendations at any time

### Implementation: Integration into /revise Command

#### Modification Points in revise.md

**Location**: After content modification, before final output

**Pseudocode**:
```markdown
## Process

[Existing steps 1-4: Plan Discovery, Revision Scope, Report Integration, Revision Application]

5. **Structure Evaluation** (NEW)
   - Extract affected phases from revision
   - Evaluate collapse/expansion opportunities
   - Display recommendations

6. **Documentation** (Updated)
   - Add revision history to main plan
   - Include structure recommendations in revision entry
   - Reference any reports used
   - Note which files were modified
```

#### Implementation Approach

**Step 1: Add Evaluation After Content Changes**

In `/revise` command logic (after Edit/Write operations complete):

```bash
# After all revision edits complete
echo "Revision complete. Evaluating plan structure..."

# Source utilities
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/home/benjamin/.config}"
source "$CLAUDE_PROJECT_DIR/.claude/lib/parse-adaptive-plan.sh"

# Get affected phases (from revision description or all phases)
AFFECTED_PHASES=$(get_affected_phases "$PLAN_PATH" "$REVISION_DESCRIPTION")

# Display structure recommendations
if [ -n "$AFFECTED_PHASES" ]; then
  display_structure_recommendations "$PLAN_PATH" "$AFFECTED_PHASES"
fi
```

**Step 2: Update Revision History Section**

Use Edit tool to append recommendations to revision history:

```markdown
## Revision History

### [Date] - Revision N: [Description]
**Changes**: [changes description]
**Reason**: [reason]
**Modified Phases**: [phase list]

**Structure Recommendations**:
- Phase 3: Consider collapsing (now simple with 4 tasks, complexity 3.2)
  - Command: `/collapse phase <plan> 3`
- Phase 5: Consider expanding (now complex with 14 tasks, complexity 9.5)
  - Command: `/expand phase <plan> 5`
```

**Step 3: Handle Auto-Mode**

For `/revise --auto-mode`, include recommendations in JSON response:

```json
{
  "status": "success",
  "action_taken": "update_tasks",
  "plan_file": "/path/to/plan.md",
  "revision_summary": "Updated task list for Phase 3",
  "structure_recommendations": [
    {
      "type": "collapse",
      "phase": 3,
      "reason": "Simple phase with 4 tasks, complexity 3.2",
      "command": "/collapse phase /path/to/plan 3"
    }
  ]
}
```

**Note**: Auto-mode typically doesn't act on recommendations (just includes them in response). Manual collapse/expansion requires user decision.

### Testing Specification

**Test Case 1: Collapse Recommendation After Task Removal**
```bash
# Setup: Expanded phase with many tasks
/expand phase specs/plans/test_plan.md 2

# Action: Remove 8 tasks from Phase 2 via /revise
/revise "Remove database migration tasks from Phase 2"

# Expected: Recommendation to collapse Phase 2
# Output should include:
# - "Phase 2: ... (4 tasks, complexity 3.5)"
# - "Command: /collapse phase ... 2"
```

**Test Case 2: Expansion Recommendation After Task Addition**
```bash
# Setup: Inline phase with few tasks
# (Phase 3 has 5 tasks inline)

# Action: Add 10 security tasks to Phase 3
/revise "Add comprehensive security audit tasks to Phase 3"

# Expected: Recommendation to expand Phase 3
# Output should include:
# - "Phase 3: ... (15 tasks, complexity 9.0)"
# - "Command: /expand phase ... 3"
```

**Test Case 3: Mixed Recommendations After Phase Split**
```bash
# Setup: Single large phase

# Action: Split Phase 4 into three smaller phases
/revise "Split Phase 4 into Phases 4, 5, and 6"

# Expected: Evaluate all three new phases
# Possible outcomes:
# - Phase 4: Recommend collapse (if simple)
# - Phase 5: No recommendation (appropriate size)
# - Phase 6: Recommend expansion (if complex)
```

**Test Case 4: No Recommendations (Optimal Structure)**
```bash
# Setup: Well-structured plan with appropriate phase sizes

# Action: Minor text edits to objectives
/revise "Clarify Phase 2 objective wording"

# Expected: No structure recommendations
# (Phases are already optimally structured)
```

**Test Case 5: Edge Case - Phase with Expanded Stages**
```bash
# Setup: Phase 2 has expanded stages (Level 2)

# Action: Simplify Phase 2 tasks
/revise "Remove tasks from Phase 2"

# Expected: No collapse recommendation
# Reason: Cannot collapse phase with expanded stages
# (Must collapse stages first)
```

**Test Case 6: Auto-Mode Integration**
```bash
# Invoke /revise in auto-mode
/revise test_plan.md --auto-mode --context '{
  "revision_type": "update_tasks",
  "current_phase": 3,
  "reason": "Add error handling tasks",
  "task_operations": [...]
}'

# Expected: JSON response includes structure_recommendations array
# Recommendations present but not acted upon
```

---

## Task 7.2: Add Auto-Mode Collapse Support

**Objective**: Enable automatic collapse during adaptive planning, creating symmetry with auto-expansion.

**Estimated Time**: 2-3 hours

### Design Analysis

#### New Revision Type: collapse_phase

**Purpose**: Allow `/implement` to trigger automatic collapse via `/revise --auto-mode`.

**Relationship to Existing Revision Types**:

Existing auto-mode types:
1. `expand_phase` - Expands complex phase (automatic, triggers from complexity)
2. `add_phase` - Inserts missing phase (automatic, triggers from test failures)
3. `split_phase` - Splits broad phase (automatic, triggers from scope analysis)
4. `update_tasks` - Modifies task list (automatic, triggers from scope drift)

New type:
5. `collapse_phase` - Collapses simple phase (automatic, triggers from completion + simplicity)

**Symmetry**:
- `expand_phase` ↔ `collapse_phase`: Opposite operations
- Both invoked via `/revise --auto-mode`
- Both update metadata and structure level

#### Context Format for Collapse Requests

**JSON Schema**:
```json
{
  "revision_type": "collapse_phase",
  "current_phase": 3,
  "reason": "Phase 3 completed and now simple (4 tasks, complexity 3.5)",
  "suggested_action": "Collapse Phase 3 back into main plan",
  "simplicity_metrics": {
    "tasks": 4,
    "complexity_score": 3.5,
    "completion": true
  }
}
```

**Required Fields**:
- `revision_type`: Must be "collapse_phase"
- `current_phase`: Phase number to collapse
- `reason`: Human-readable explanation
- `suggested_action`: Description of recommended action

**Optional Fields**:
- `simplicity_metrics`: Supporting data for collapse decision
  - `tasks`: Task count
  - `complexity_score`: Calculated complexity (0-10)
  - `completion`: Whether phase is completed

**Validation**:
```bash
# Check required fields
if [ -z "$revision_type" ] || [ "$revision_type" != "collapse_phase" ]; then
  error "Invalid revision_type"
fi

if [ -z "$current_phase" ] || ! [[ "$current_phase" =~ ^[0-9]+$ ]]; then
  error "Invalid current_phase (must be number)"
fi

if [ -z "$reason" ]; then
  error "Missing required field: reason"
fi
```

#### Auto-Collapse Triggers in /implement Step 5.5

**Current Step 5.5 Behavior** (from implement.md:911-1014):
- After phase completion and commit
- Agent-based judgment on collapse opportunity
- **Recommendation only** (non-blocking, informational)

**New Step 5.5 Behavior** (with Task 7.2):
- After phase completion and commit
- Detect collapse opportunity (heuristic + completion check)
- **Invoke `/revise --auto-mode`** to actually collapse
- Log auto-collapse action

**Trigger Logic**:
```bash
# In /implement Step 5.5

# Check if phase is expanded and completed
IS_PHASE_EXPANDED=$(.claude/lib/parse-adaptive-plan.sh is_phase_expanded "$PLAN_PATH" "$CURRENT_PHASE")
IS_PHASE_COMPLETED=$(grep -q "\[COMPLETED\]" "$PHASE_FILE" && echo "true" || echo "false")

if [ "$IS_PHASE_EXPANDED" = "true" ] && [ "$IS_PHASE_COMPLETED" = "true" ]; then
  # Evaluate collapse opportunity
  SHOULD_COLLAPSE=$(evaluate_collapse_opportunity "$CURRENT_PHASE" "$PLAN_PATH")

  if [ "$SHOULD_COLLAPSE" = "true" ]; then
    # Build collapse context
    COLLAPSE_CONTEXT=$(build_collapse_context "$CURRENT_PHASE" "$PLAN_PATH")

    # Invoke /revise --auto-mode
    REVISE_RESULT=$(invoke_revise_auto_mode "$PLAN_PATH" "$COLLAPSE_CONTEXT")

    # Log and continue
    echo "Auto-collapsed Phase $CURRENT_PHASE (simple after completion)"
  fi
fi
```

**Differences from Step 1.55 (Proactive Expansion)**:
- Step 1.55: Agent-based judgment, pre-implementation, recommendation only
- Step 5.5: Heuristic-based, post-completion, automatic action
- Both non-blocking: Implementation continues regardless

### Implementation: collapse_phase Revision Type

#### Add Case to /revise Auto-Mode Handler

**Location**: In `/revise` auto-mode switch statement (after existing cases)

**Implementation**:
```bash
case "$revision_type" in
  expand_phase)
    # Existing implementation
    ;;
  add_phase)
    # Existing implementation
    ;;
  split_phase)
    # Existing implementation
    ;;
  update_tasks)
    # Existing implementation
    ;;
  collapse_phase)  # NEW
    # Parse collapse context
    local phase_num=$(echo "$context_json" | jq -r '.current_phase')
    local reason=$(echo "$context_json" | jq -r '.reason')
    local metrics=$(echo "$context_json" | jq -r '.simplicity_metrics // {}')

    # Validate phase is expanded
    local is_expanded=$(is_phase_expanded "$plan_path" "$phase_num")
    if [ "$is_expanded" != "true" ]; then
      # Return error: phase not expanded
      cat <<EOF
{
  "status": "error",
  "error_type": "invalid_state",
  "error_message": "Phase $phase_num is not expanded (cannot collapse inline phase)",
  "plan_file": "$plan_path"
}
EOF
      exit 1
    fi

    # Check for expanded stages
    local has_stages=$(find "$(dirname "$plan_path")/$(basename "$plan_path")/phase_${phase_num}_*" -type d 2>/dev/null | head -1)
    if [ -n "$has_stages" ]; then
      # Return error: has expanded stages
      cat <<EOF
{
  "status": "error",
  "error_type": "invalid_state",
  "error_message": "Phase $phase_num has expanded stages (collapse stages first)",
  "plan_file": "$plan_path"
}
EOF
      exit 1
    fi

    # Invoke /collapse phase command
    local collapse_result=$(/collapse phase "$plan_path" "$phase_num" 2>&1)
    local collapse_exit=$?

    if [ $collapse_exit -ne 0 ]; then
      # Collapse failed
      cat <<EOF
{
  "status": "error",
  "error_type": "collapse_failed",
  "error_message": "Collapse operation failed: $collapse_result",
  "plan_file": "$plan_path"
}
EOF
      exit 1
    fi

    # Update structure level metadata
    local new_level=$(detect_structure_level "$plan_path")
    update_structure_level "$plan_path" "$new_level"

    # Return success response
    cat <<EOF
{
  "status": "success",
  "action_taken": "collapsed_phase",
  "phase_collapsed": $phase_num,
  "reason": "$reason",
  "new_structure_level": $new_level,
  "updated_file": "$plan_path"
}
EOF
    ;;
  *)
    # Unknown revision type error
    ;;
esac
```

**Error Handling**:
- Invalid state: Phase not expanded → Return error JSON
- Invalid state: Phase has expanded stages → Return error JSON
- Collapse operation fails → Return error JSON with details
- Success → Return success JSON with metadata

**Metadata Updates**:
- Structure level: Automatically recalculated after collapse
- Expanded phases list: Updated by `/collapse` command
- Plan file path: May change if last phase (Level 1 → Level 0)

### Implementation: Auto-Collapse in /implement Step 5.5

#### Current Step 5.5 Location

**File**: `.claude/commands/implement.sh` (not .md)
**Lines**: 911-1014
**Current behavior**: Agent-based recommendation only

**Note**: implement.md is the documentation file. Actual implementation is in implement.sh (if it exists) or embedded in agent prompt.

#### New Auto-Collapse Logic

**Location**: After git commit succeeds, before moving to next phase

**Implementation**:
```bash
# /implement Step 5.5: Collapse Opportunity Detection
# (After phase completion, git commit, and plan update)

# Only check if phase is expanded and completed
if [ "$IS_PHASE_EXPANDED" = "true" ] && [ "$PHASE_COMPLETED" = "true" ]; then

  # Get phase file for complexity calculation
  PHASE_FILE=$(get_phase_file "$PLAN_PATH" "$CURRENT_PHASE")

  if [ -f "$PHASE_FILE" ]; then
    # Extract phase details
    PHASE_CONTENT=$(cat "$PHASE_FILE")
    PHASE_NAME=$(grep "^### Phase $CURRENT_PHASE" "$PHASE_FILE" | head -1 | sed "s/^### Phase $CURRENT_PHASE:* //")
    TASK_COUNT=$(grep -c "^- \[x\]" "$PHASE_FILE")

    # Calculate complexity
    COMPLEXITY_SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$PHASE_CONTENT")

    # Log collapse check
    log_collapse_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "6.0" "$([ $TASK_COUNT -le 5 ] && awk -v s="$COMPLEXITY_SCORE" 'BEGIN {exit !(s < 6.0)}' && echo 'true' || echo 'false')"

    # Check thresholds: tasks ≤ 5 AND complexity < 6.0
    if [ "$TASK_COUNT" -le 5 ]; then
      if awk -v score="$COMPLEXITY_SCORE" 'BEGIN {exit !(score < 6.0)}'; then

        # Build collapse context JSON
        COLLAPSE_CONTEXT=$(cat <<EOF
{
  "revision_type": "collapse_phase",
  "current_phase": $CURRENT_PHASE,
  "reason": "Phase $CURRENT_PHASE completed and now simple ($TASK_COUNT tasks, complexity $COMPLEXITY_SCORE)",
  "suggested_action": "Collapse Phase $CURRENT_PHASE back into main plan",
  "simplicity_metrics": {
    "tasks": $TASK_COUNT,
    "complexity_score": $COMPLEXITY_SCORE,
    "completion": true
  }
}
EOF
)

        # Invoke /revise --auto-mode
        echo "Triggering auto-collapse for Phase $CURRENT_PHASE..."
        REVISE_RESULT=$(invoke_slash_command "/revise $PLAN_PATH --auto-mode --context '$COLLAPSE_CONTEXT'")

        # Parse result
        REVISE_STATUS=$(echo "$REVISE_RESULT" | jq -r '.status')

        if [ "$REVISE_STATUS" = "success" ]; then
          # Collapse succeeded
          NEW_STRUCTURE_LEVEL=$(echo "$REVISE_RESULT" | jq -r '.new_structure_level')

          # Log collapse invocation
          log_collapse_invocation "$CURRENT_PHASE" "auto" "Phase simple after completion"

          echo "✓ Auto-collapsed Phase $CURRENT_PHASE (structure level now: $NEW_STRUCTURE_LEVEL)"

          # Update plan path if changed (Level 1 → Level 0)
          UPDATED_FILE=$(echo "$REVISE_RESULT" | jq -r '.updated_file')
          if [ "$UPDATED_FILE" != "$PLAN_PATH" ]; then
            PLAN_PATH="$UPDATED_FILE"
            echo "  Plan file updated: $PLAN_PATH"
          fi
        else
          # Collapse failed
          ERROR_MSG=$(echo "$REVISE_RESULT" | jq -r '.error_message')
          echo "⚠ Auto-collapse failed: $ERROR_MSG"
          echo "  Continuing with expanded structure"
        fi

      fi
    fi
  fi
fi

# Continue to next phase...
```

#### Helper Function: build_collapse_context()

**Purpose**: Generate collapse context JSON for `/revise --auto-mode`.

**Implementation**:
```bash
#!/usr/bin/env bash
# Build collapse context JSON
# Args:
#   $1: phase_num
#   $2: plan_path
# Output: JSON string

build_collapse_context() {
  local phase_num="$1"
  local plan_path="$2"

  # Get phase file
  local phase_file=$(get_phase_file "$plan_path" "$phase_num")

  if [ ! -f "$phase_file" ]; then
    echo "{}"
    return 1
  fi

  # Extract metrics
  local phase_content=$(cat "$phase_file")
  local phase_name=$(grep "^### Phase $phase_num" "$phase_file" | head -1 | sed "s/^### Phase $phase_num:* //" | sed 's/ \[.*\]$//')
  local task_count=$(grep -c "^- \[x\]" "$phase_file")
  local complexity=$(calculate_phase_complexity "$phase_name" "$phase_content")

  # Generate JSON
  cat <<EOF
{
  "revision_type": "collapse_phase",
  "current_phase": $phase_num,
  "reason": "Phase $phase_num completed and now simple ($task_count tasks, complexity $complexity)",
  "suggested_action": "Collapse Phase $phase_num back into main plan",
  "simplicity_metrics": {
    "tasks": $task_count,
    "complexity_score": $complexity,
    "completion": true
  }
}
EOF
}
```

### Testing Specification

**Test Case 1: Successful Auto-Collapse**
```bash
# Setup: Implement simple expanded phase
# - Phase 2 is expanded (Level 1)
# - Phase 2 has 4 tasks
# - All tasks complete

/implement test_plan.md 2

# Expected:
# - Phase 2 implementation succeeds
# - Git commit created
# - Auto-collapse triggered (tasks=4, complexity<6)
# - /revise --auto-mode invoked successfully
# - Phase 2 collapsed back to inline
# - Log: collapse_check with triggered=true
# - Log: collapse_invocation with trigger=auto
```

**Test Case 2: Auto-Collapse Skipped (Complex Phase)**
```bash
# Setup: Implement complex expanded phase
# - Phase 3 is expanded (Level 1)
# - Phase 3 has 12 tasks (complexity 8.5)
# - All tasks complete

/implement test_plan.md 3

# Expected:
# - Phase 3 implementation succeeds
# - Git commit created
# - Auto-collapse NOT triggered (complexity>6)
# - Phase 3 remains expanded
# - Log: collapse_check with triggered=false
```

**Test Case 3: Auto-Collapse Fails (Has Stages)**
```bash
# Setup: Implement phase with expanded stages
# - Phase 4 is expanded (Level 2)
# - Phase 4 has stage files
# - Phase is simple (4 tasks)

/implement test_plan.md 4

# Expected:
# - Phase 4 implementation succeeds
# - Auto-collapse attempted
# - /revise returns error: "has expanded stages"
# - Warning displayed
# - Implementation continues with expanded structure
```

**Test Case 4: Manual Collapse After Auto-Mode**
```bash
# Invoke collapse via /revise --auto-mode directly
/revise test_plan.md --auto-mode --context '{
  "revision_type": "collapse_phase",
  "current_phase": 2,
  "reason": "Test auto-collapse",
  "simplicity_metrics": {"tasks": 3, "complexity_score": 2.5}
}'

# Expected:
# - /collapse phase invoked
# - Structure level updated
# - Success JSON returned
```

**Test Case 5: Plan Conversion (Last Phase Collapse)**
```bash
# Setup: Plan with single expanded phase
# - Phase 1 is only expanded phase
# - Phase 1 simple and complete

/implement single_phase_plan.md 1

# Expected:
# - Auto-collapse triggered
# - Phase 1 collapsed
# - Plan converts: Level 1 → Level 0
# - Plan file moved from dir/plan.md to plan.md
# - Directory removed
# - new_structure_level = 0
```

**Test Case 6: Context Validation**
```bash
# Invalid context: missing required field
/revise test_plan.md --auto-mode --context '{
  "revision_type": "collapse_phase",
  "current_phase": 2
}'

# Expected:
# - Validation error
# - Error JSON: "Missing required field: reason"
```

---

## Task 7.3: Add Collapse Logging

**Objective**: Track collapse operations for observability, maintaining consistency with expansion logging.

**Estimated Time**: 1 hour

### Design Analysis

#### New Log Event Types

**Consistency with Expansion**:

Existing expansion events (from adaptive-planning-logger.sh):
- `complexity_check` → Expansion trigger evaluation
- `replan` → Expansion invocation via `/revise --auto-mode`

New collapse events:
- `collapse_check` → Collapse trigger evaluation
- `collapse_invocation` → Collapse operation (manual or auto)

**Event Type Design**:
```
collapse_check:
  - When: Collapse opportunity evaluated
  - Data: phase_num, complexity_score, threshold, triggered boolean
  - Level: INFO
  - Use: Track how often collapse is considered

collapse_invocation:
  - When: Collapse actually executed
  - Data: phase_num, trigger_type (manual/auto), reason
  - Level: INFO
  - Use: Track collapse operations for audit trail
```

#### Integration Points

**Three Integration Locations**:

1. **`/collapse` command** (manual invocations):
   - Log: `collapse_invocation` with trigger="manual"
   - Location: After phase collapse succeeds

2. **`/implement` Step 5.5** (auto-collapse trigger):
   - Log: `collapse_check` during evaluation
   - Log: `collapse_invocation` with trigger="auto" if executed
   - Location: In auto-collapse logic (Task 7.2)

3. **`/revise --auto-mode` collapse_phase** (auto-collapse handler):
   - Log: `collapse_invocation` with trigger="auto"
   - Location: In collapse_phase case (Task 7.2)
   - Note: May be redundant with /implement logging (choose one)

**Preferred Integration**:
- `/implement`: Log both check and invocation
- `/collapse`: Log invocation only (manual)
- `/revise`: Skip logging (already logged by caller)

### Implementation: Collapse Logging Functions

#### Function: log_collapse_check()

**Purpose**: Log collapse opportunity evaluation.

**Implementation** (add to `.claude/lib/adaptive-planning-logger.sh`):

```bash
#
# Log collapse opportunity evaluation
# Args:
#   $1: phase_num
#   $2: complexity_score
#   $3: threshold
#   $4: triggered (true/false)
#
log_collapse_check() {
  local phase_num="$1"
  local complexity_score="$2"
  local threshold="$3"
  local triggered="$4"

  local data
  data=$(printf '{"phase": %d, "complexity": %.1f, "threshold": %.1f, "triggered": %s}' \
    "$phase_num" "$complexity_score" "$threshold" "$triggered")

  local message="Collapse check: Phase $phase_num complexity $complexity_score (threshold $threshold) -> $triggered"

  write_log_entry "INFO" "collapse_check" "$message" "$data"
}
```

**Parameters**:
- `phase_num`: Phase number being evaluated (integer)
- `complexity_score`: Calculated complexity (float, e.g., 3.5)
- `threshold`: Threshold for collapse (typically 6.0)
- `triggered`: Boolean string ("true" or "false")

**Log Format**:
```
[2025-10-09T14:32:15Z] INFO collapse_check: Collapse check: Phase 3 complexity 3.5 (threshold 6.0) -> true | data={"phase": 3, "complexity": 3.5, "threshold": 6.0, "triggered": true}
```

**Usage Example**:
```bash
# In /implement Step 5.5
TRIGGERED="false"
if [ "$TASK_COUNT" -le 5 ] && awk -v s="$COMPLEXITY_SCORE" 'BEGIN {exit !(s < 6.0)}'; then
  TRIGGERED="true"
fi

log_collapse_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "6.0" "$TRIGGERED"
```

#### Function: log_collapse_invocation()

**Purpose**: Log collapse operation execution.

**Implementation** (add to `.claude/lib/adaptive-planning-logger.sh`):

```bash
#
# Log collapse invocation
# Args:
#   $1: phase_num
#   $2: trigger_type (manual|auto)
#   $3: reason
#
log_collapse_invocation() {
  local phase_num="$1"
  local trigger_type="$2"
  local reason="$3"

  # Validate trigger_type
  if [[ "$trigger_type" != "manual" && "$trigger_type" != "auto" ]]; then
    echo "Warning: Invalid trigger_type '$trigger_type', using 'manual'" >&2
    trigger_type="manual"
  fi

  local data
  data=$(printf '{"phase": %d, "trigger": "%s", "reason": "%s"}' \
    "$phase_num" "$trigger_type" "${reason//\"/\\\"}")

  local message="Collapsing phase $phase_num ($trigger_type): $reason"

  write_log_entry "INFO" "collapse_invocation" "$message" "$data"
}
```

**Parameters**:
- `phase_num`: Phase number being collapsed (integer)
- `trigger_type`: Either "manual" or "auto"
- `reason`: Human-readable explanation (string)

**Log Format**:
```
[2025-10-09T14:32:20Z] INFO collapse_invocation: Collapsing phase 3 (auto): Phase simple after completion | data={"phase": 3, "trigger": "auto", "reason": "Phase simple after completion"}
```

**Usage Examples**:
```bash
# Manual collapse (in /collapse command)
log_collapse_invocation "$PHASE_NUM" "manual" "User-initiated collapse"

# Auto-collapse (in /implement Step 5.5)
log_collapse_invocation "$CURRENT_PHASE" "auto" "Phase simple after completion"
```

#### Export Functions

**Add to export section** (end of adaptive-planning-logger.sh):

```bash
# Export functions for use in other scripts
export -f rotate_log_if_needed
export -f write_log_entry
export -f log_trigger_evaluation
export -f log_complexity_check
export -f log_test_failure_pattern
export -f log_scope_drift
export -f log_replan_invocation
export -f log_loop_prevention
export -f log_collapse_check      # NEW
export -f log_collapse_invocation # NEW
export -f query_adaptive_log
export -f get_adaptive_stats
```

### Implementation: Integration into Commands

#### Integration into /collapse Command

**Location**: After successful phase collapse, before final output

**Implementation**:
```bash
# In /collapse command (collapse.md or collapse.sh)
# After merge_phase_into_plan() succeeds

# Log manual collapse invocation
log_collapse_invocation "$PHASE_NUM" "manual" "User-initiated collapse via /collapse command"

echo "Phase $PHASE_NUM collapsed successfully"
```

**Error Handling**:
```bash
# Non-blocking: continue if logging fails
if ! log_collapse_invocation "$PHASE_NUM" "manual" "User-initiated collapse"; then
  echo "Warning: Failed to log collapse operation" >&2
fi
```

#### Integration into /implement Step 5.5

**Location**: In auto-collapse logic (from Task 7.2)

**Implementation**:
```bash
# Calculate complexity
COMPLEXITY_SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$PHASE_CONTENT")

# Log collapse check
TRIGGERED="false"
if [ "$TASK_COUNT" -le 5 ] && awk -v s="$COMPLEXITY_SCORE" 'BEGIN {exit !(s < 6.0)}'; then
  TRIGGERED="true"
fi

log_collapse_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "6.0" "$TRIGGERED"

# If triggered, invoke auto-collapse
if [ "$TRIGGERED" = "true" ]; then
  # Build context and invoke /revise --auto-mode
  REVISE_RESULT=$(invoke_slash_command "/revise ...")

  if [ "$REVISE_STATUS" = "success" ]; then
    # Log successful auto-collapse
    log_collapse_invocation "$CURRENT_PHASE" "auto" "Phase simple after completion"
  fi
fi
```

#### Integration into /revise --auto-mode

**Location**: In collapse_phase case (from Task 7.2)

**Decision**: Skip logging here (already logged by /implement caller)

**Rationale**:
- Avoid duplicate logs
- `/implement` has full context (trigger reason, metrics)
- `/revise` is just the execution mechanism

**Alternative**: Log at `/revise` level if called directly (not from /implement):
```bash
# Only log if not already logged by caller
if [ -z "$AUTO_LOGGED" ]; then
  log_collapse_invocation "$phase_num" "auto" "$reason"
fi
```

### Implementation: Log Queries

#### Query Recent Collapse Checks

**Command**:
```bash
# Show last 10 collapse checks
query_adaptive_log "collapse_check" 10
```

**Expected Output**:
```
[2025-10-09T14:32:15Z] INFO collapse_check: Collapse check: Phase 3 complexity 3.5 (threshold 6.0) -> true | data={"phase": 3, "complexity": 3.5, "threshold": 6.0, "triggered": true}
[2025-10-09T13:45:22Z] INFO collapse_check: Collapse check: Phase 2 complexity 7.2 (threshold 6.0) -> false | data={"phase": 2, "complexity": 7.2, "threshold": 6.0, "triggered": false}
```

#### Query Collapse Invocations

**Command**:
```bash
# Show all collapse invocations
query_adaptive_log "collapse_invocation"
```

**Expected Output**:
```
[2025-10-09T14:32:20Z] INFO collapse_invocation: Collapsing phase 3 (auto): Phase simple after completion | data={"phase": 3, "trigger": "auto", "reason": "Phase simple after completion"}
[2025-10-08T16:20:10Z] INFO collapse_invocation: Collapsing phase 2 (manual): User-initiated collapse | data={"phase": 2, "trigger": "manual", "reason": "User-initiated collapse"}
```

#### Filter by Trigger Type

**Command**:
```bash
# Show only auto-collapse invocations
query_adaptive_log "collapse_invocation" | jq 'select(.data.trigger=="auto")'
```

**Expected Output** (JSON parsed):
```json
{
  "timestamp": "2025-10-09T14:32:20Z",
  "level": "INFO",
  "event_type": "collapse_invocation",
  "message": "Collapsing phase 3 (auto): Phase simple after completion",
  "data": {
    "phase": 3,
    "trigger": "auto",
    "reason": "Phase simple after completion"
  }
}
```

**Note**: This requires parsing log lines as JSON. Current `query_adaptive_log` returns raw log lines.

**Enhanced Query** (if jq processing added):
```bash
# Parse log line and extract JSON data
query_adaptive_log "collapse_invocation" | while read line; do
  echo "$line" | sed 's/.*data=//' | jq 'select(.trigger=="auto")'
done
```

#### Combined Structure Optimization Query

**Command**:
```bash
# Show all structure optimization events (expansion + collapse)
query_adaptive_log | grep -E "collapse|complexity|expand" | tail -20
```

**Use Case**: Understand full structure evolution of a plan

### Testing Specification

**Test Case 1: Manual Collapse Logging**
```bash
# Execute manual collapse
/collapse phase specs/plans/test_plan/ 2

# Verify log entry
query_adaptive_log "collapse_invocation" | tail -1

# Expected:
# - Log entry with trigger="manual"
# - Phase number = 2
# - Reason mentions "User-initiated"
```

**Test Case 2: Auto-Collapse Logging (Full Flow)**
```bash
# Implement simple phase
/implement test_plan.md 3

# Verify logs
query_adaptive_log "collapse_check" | tail -1
query_adaptive_log "collapse_invocation" | tail -1

# Expected:
# - collapse_check log with triggered=true
# - collapse_invocation log with trigger="auto"
# - Both reference phase 3
```

**Test Case 3: Collapse Check Not Triggered**
```bash
# Implement complex phase
/implement test_plan.md 4

# Verify logs
query_adaptive_log "collapse_check" | tail -1

# Expected:
# - collapse_check log with triggered=false
# - No collapse_invocation log (skipped)
```

**Test Case 4: Log Format Consistency**
```bash
# Compare expansion and collapse log formats
query_adaptive_log "complexity_check" | head -1
query_adaptive_log "collapse_check" | head -1

# Expected:
# - Same log structure: [timestamp] LEVEL event_type: message | data={...}
# - Data JSON format consistent
# - Both use INFO level
```

**Test Case 5: Concurrent Logging**
```bash
# Run multiple operations in parallel (if supported)
/collapse phase plan1/ 2 &
/collapse phase plan2/ 3 &
wait

# Verify logs
query_adaptive_log "collapse_invocation" | tail -2

# Expected:
# - Both collapse operations logged
# - No log corruption or interleaving
# - Timestamps reflect actual execution order
```

**Test Case 6: Log Rotation**
```bash
# Generate many collapse operations to trigger rotation
for i in {1..1000}; do
  log_collapse_check 1 5.0 6.0 "false"
done

# Verify rotation
ls -lh .claude/logs/adaptive-planning.log*

# Expected:
# - Log rotated when exceeds 10MB
# - Old logs preserved (.log.1, .log.2, etc.)
# - Max 5 rotated files kept
```

---

## Workflow Analysis

### Current Workflow (Manual Structure Optimization)

**Scenario**: User revises plan and structure becomes suboptimal

```
User: /revise "Split Phase 3 into 3 smaller phases"
    ↓
/revise splits Phase 3 → Phase 3, 4, 5
    ↓
[User must manually evaluate structure]
    ↓
User notices Phase 4 is now simple
    ↓
User: /collapse phase <plan> 4
    ↓
Phase 4 collapsed manually
```

**Issues**:
- User must remember to evaluate structure after revisions
- Easy to overlook optimization opportunities
- Multiple manual steps required
- No automatic detection of simple/complex phases

### New Workflow with Task 7.1 (Recommendations)

**Scenario**: Same revision, automatic recommendations

```
User: /revise "Split Phase 3 into 3 smaller phases"
    ↓
/revise splits Phase 3 → Phase 3, 4, 5
    ↓
[AUTO] Structure evaluation triggered
    ↓
[AUTO] Evaluates Phases 3, 4, 5
    ↓
Recommendations displayed:
  - "Phase 4 is now simple (4 tasks). Consider: /collapse phase <plan> 4"
  - "Phase 5 is now complex (12 tasks). Consider: /expand phase <plan> 5"
    ↓
User executes recommended commands (or ignores)
```

**Benefits**:
- Automatic detection of optimization opportunities
- Clear, actionable recommendations
- User retains full control
- Reduces cognitive load

### New Workflow with Task 7.2 (Auto-Collapse)

**Scenario**: Implementation with automatic collapse

```
User: /implement <plan>
    ↓
Phase 3 implemented
    ↓
All tests pass
    ↓
Git commit created
    ↓
[AUTO] Collapse check (Step 5.5)
    ↓
[AUTO] Detect: Phase 3 expanded + simple (4 tasks) + complete
    ↓
[AUTO] Build collapse context JSON
    ↓
[AUTO] /revise --auto-mode collapse_phase
    ↓
[AUTO] /collapse phase invoked
    ↓
Phase 3 collapsed (structure simplified)
    ↓
Continue to Phase 4
```

**Benefits**:
- Fully automatic optimization
- No user intervention needed
- Plans stay optimally structured
- Logged for audit trail

### Before/After Comparison (Report 029 Reference)

**From Report 029 Lines 845-903**:

**Before Phase 7** (Current Workflow):
```
/revise "Split Phase 3 into 3 phases"
    ↓
Manual evaluation required
    ↓
User: /collapse phase <plan> 4 [manual]
```

**After Phase 7** (Optimized Workflow):
```
/revise "Split Phase 3 into 3 phases"
    ↓
[AUTO] Recommendations shown
    ↓
User: /collapse phase <plan> 4 [guided]
```

**After Phase 7 + Task 7.2** (Fully Automatic):
```
/implement <plan>
    ↓
[AUTO] Auto-collapse triggered
    ↓
Structure optimized automatically
```

### Performance Impact Analysis

**Task 7.1 Performance** (Recommendations):
- Structure evaluation: +0.5-1 second per affected phase
- Complexity calculation: Existing utility (no overhead)
- Total impact on `/revise`: +1-2 seconds
- **Acceptable**: Non-blocking, occurs after user action

**Task 7.2 Performance** (Auto-Collapse):
- Collapse opportunity check: +0.5 second
- Auto-collapse execution: +2-5 seconds (if triggered)
- Total impact on `/implement` per phase: +0.5-5 seconds
- **Acceptable**: Occurs after commit, non-blocking to workflow

**Task 7.3 Performance** (Logging):
- Log write overhead: <0.1 second per entry
- Log rotation: <0.5 second (only when file exceeds 10MB)
- **Negligible**: Async, non-blocking

### User Experience Improvements

**Better Discoverability**:
- Users learn about structure optimization through recommendations
- Clear commands provided (copy-paste ready)

**Reduced Manual Work**:
- No need to remember to check structure after revisions
- Automatic collapse during implementation reduces cleanup work

**Better Plan Quality**:
- Plans automatically maintain optimal structure
- Simple phases don't stay unnecessarily expanded
- Complex phases get flagged for expansion

**Audit Trail**:
- All structure optimizations logged
- Can review why/when phases were collapsed
- Helps debug plan evolution issues

---

## Integration and Dependencies

### Dependencies Between Tasks

**Task Dependency Graph**:
```
Task 7.1 (Structure Evaluation)
    ↓ (provides evaluation functions)
Task 7.2 (Auto-Mode Collapse)
    ↓ (triggers logging)
Task 7.3 (Collapse Logging)
```

**Execution Order**:
1. **Task 7.3 first**: Add logging functions to library
2. **Task 7.1 second**: Implement evaluation (independent of auto-mode)
3. **Task 7.2 last**: Implement auto-collapse (depends on 7.1 evaluation, 7.3 logging)

**Why This Order**:
- Task 7.3 is foundational (logging infrastructure)
- Task 7.1 can be tested independently
- Task 7.2 integrates both 7.1 and 7.3

### Integration with Adaptive Planning (Phase 2)

**Shared Infrastructure**:
- `adaptive-planning-logger.sh` - Extended with collapse logging
- Log file format - Consistent structure
- Query utilities - Work for both expansion and collapse

**Symmetry**:
```
Expansion Logging (Phase 2):
  - log_complexity_check()
  - log_replan_invocation()

Collapse Logging (Phase 7):
  - log_collapse_check()
  - log_collapse_invocation()
```

**Unified Queries**:
```bash
# All structure optimization events
query_adaptive_log | grep -E "complexity|collapse|expand"

# Statistics across both
get_adaptive_stats  # Could be enhanced to include collapse counts
```

### Interaction with /expand Command

**Complementary Operations**:
- `/expand`: Simple → Complex (user-initiated or auto via `/revise --auto-mode`)
- `/collapse`: Complex → Simple (user-initiated or auto via `/revise --auto-mode`)

**Bidirectional Workflow**:
```
Inline Phase
    ↓ [/expand or auto-expand]
Expanded Phase
    ↓ [implementation]
Completed Expanded Phase
    ↓ [/collapse or auto-collapse]
Inline Phase
```

**Reversal Safety**:
- Collapse can be reversed by `/expand`
- Expansion can be reversed by `/collapse`
- All operations preserve content
- Metadata stays consistent

### Compatibility with Existing /implement Workflow

**No Breaking Changes**:
- Task 7.1: Pure addition (recommendations appended)
- Task 7.2: Pure addition (auto-collapse is new behavior)
- Task 7.3: Pure addition (logging is observability only)

**Backward Compatibility**:
- Old plans work unchanged
- Existing checkpoints unaffected
- Logging is non-blocking

**Optional Features**:
- Auto-collapse can be disabled via flag (future enhancement)
- Recommendations can be suppressed (future enhancement)
- Logging always enabled (observability is always valuable)

---

## Code Examples

### Example 1: Complete Structure Evaluation (Both Collapse and Expansion)

**Scenario**: User revises plan, multiple phases affected

**Input**:
```bash
/revise "Remove 8 migration tasks from Phase 2, add 10 security tasks to Phase 5"
```

**Execution**:
```bash
#!/usr/bin/env bash
# After /revise completes content modifications

# Source utilities
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/home/benjamin/.config}"
source "$CLAUDE_PROJECT_DIR/.claude/lib/parse-adaptive-plan.sh"

# Detect affected phases from revision description
REVISION_DESC="Remove 8 migration tasks from Phase 2, add 10 security tasks to Phase 5"
AFFECTED_PHASES=$(get_affected_phases "$PLAN_PATH" "$REVISION_DESC")
# Returns: "2 5"

# Evaluate each affected phase
for phase_num in $AFFECTED_PHASES; do
  # Check if phase is expanded
  is_expanded=$(is_phase_expanded "$PLAN_PATH" "$phase_num")

  if [ "$is_expanded" = "true" ]; then
    # Expanded: evaluate collapse
    should_collapse=$(evaluate_collapse_opportunity "$phase_num" "$PLAN_PATH")

    if [ "$should_collapse" = "true" ]; then
      # Get details for recommendation
      phase_file=$(get_phase_file "$PLAN_PATH" "$phase_num")
      task_count=$(grep -c "^- \[[ x]\]" "$phase_file")
      phase_name=$(grep "^### Phase $phase_num" "$phase_file" | sed "s/^### Phase $phase_num:* //")
      complexity=$(calculate_phase_complexity "$phase_name" "$(cat "$phase_file")")

      echo "Collapse Recommendation:"
      echo "  Phase $phase_num: $phase_name ($task_count tasks, complexity $complexity)"
      echo "  Command: /collapse phase $PLAN_PATH $phase_num"
    fi
  else
    # Inline: evaluate expansion
    should_expand=$(evaluate_expansion_opportunity "$phase_num" "$PLAN_PATH")

    if [ "$should_expand" = "true" ]; then
      # Get details
      plan_file="$PLAN_PATH"
      [ -d "$PLAN_PATH" ] && plan_file="$PLAN_PATH/$(basename "$PLAN_PATH").md"

      phase_content=$(extract_phase_content "$plan_file" "$phase_num")
      task_count=$(echo "$phase_content" | grep -c "^- \[[ x]\]")
      phase_name=$(echo "$phase_content" | grep "^### Phase $phase_num" | sed "s/^### Phase $phase_num:* //")
      complexity=$(calculate_phase_complexity "$phase_name" "$phase_content")

      echo "Expansion Recommendation:"
      echo "  Phase $phase_num: $phase_name ($task_count tasks, complexity $complexity)"
      echo "  Command: /expand phase $PLAN_PATH $phase_num"
    fi
  fi
done
```

**Output**:
```
Collapse Recommendation:
  Phase 2: Database Migration (3 tasks, complexity 2.5)
  Command: /collapse phase specs/plans/025_plan/ 2

Expansion Recommendation:
  Phase 5: Security Audit (15 tasks, complexity 9.2)
  Command: /expand phase specs/plans/025_plan/ 5
```

### Example 2: Complete Auto-Mode Collapse with Context JSON

**Scenario**: `/implement` triggers auto-collapse after phase completion

**Phase Completion State**:
- Phase 3 expanded to separate file
- Phase 3 completed (all tasks marked [x])
- Phase 3 simple (4 tasks, complexity 3.5)

**Auto-Collapse Trigger**:
```bash
#!/usr/bin/env bash
# /implement Step 5.5: After git commit

# Check eligibility
IS_PHASE_EXPANDED=$(is_phase_expanded "$PLAN_PATH" "$CURRENT_PHASE")
IS_PHASE_COMPLETED=$(grep -q "\[COMPLETED\]" "$PHASE_FILE" && echo "true" || echo "false")

if [ "$IS_PHASE_EXPANDED" = "true" ] && [ "$IS_PHASE_COMPLETED" = "true" ]; then

  # Extract metrics
  PHASE_CONTENT=$(cat "$PHASE_FILE")
  PHASE_NAME=$(grep "^### Phase $CURRENT_PHASE" "$PHASE_FILE" | sed "s/^### Phase $CURRENT_PHASE:* //")
  TASK_COUNT=$(grep -c "^- \[x\]" "$PHASE_FILE")
  COMPLEXITY_SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$PHASE_CONTENT")

  # Log collapse check
  TRIGGERED="false"
  [ "$TASK_COUNT" -le 5 ] && awk -v s="$COMPLEXITY_SCORE" 'BEGIN {exit !(s < 6.0)}' && TRIGGERED="true"
  log_collapse_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "6.0" "$TRIGGERED"

  # Check thresholds
  if [ "$TASK_COUNT" -le 5 ]; then
    if awk -v score="$COMPLEXITY_SCORE" 'BEGIN {exit !(score < 6.0)}'; then

      # Build collapse context JSON
      COLLAPSE_CONTEXT=$(cat <<EOF
{
  "revision_type": "collapse_phase",
  "current_phase": $CURRENT_PHASE,
  "reason": "Phase $CURRENT_PHASE completed and now simple ($TASK_COUNT tasks, complexity $COMPLEXITY_SCORE)",
  "suggested_action": "Collapse Phase $CURRENT_PHASE back into main plan",
  "simplicity_metrics": {
    "tasks": $TASK_COUNT,
    "complexity_score": $COMPLEXITY_SCORE,
    "completion": true
  }
}
EOF
)

      # Invoke /revise --auto-mode
      echo "Triggering auto-collapse for Phase $CURRENT_PHASE..."
      REVISE_RESULT=$(/revise "$PLAN_PATH" --auto-mode --context "$COLLAPSE_CONTEXT")

      # Parse result
      REVISE_STATUS=$(echo "$REVISE_RESULT" | jq -r '.status')

      if [ "$REVISE_STATUS" = "success" ]; then
        # Log successful collapse
        log_collapse_invocation "$CURRENT_PHASE" "auto" "Phase simple after completion"

        # Display success
        NEW_LEVEL=$(echo "$REVISE_RESULT" | jq -r '.new_structure_level')
        echo "✓ Auto-collapsed Phase $CURRENT_PHASE (structure level: $NEW_LEVEL)"
      else
        # Log failure
        ERROR_MSG=$(echo "$REVISE_RESULT" | jq -r '.error_message')
        echo "⚠ Auto-collapse failed: $ERROR_MSG"
      fi
    fi
  fi
fi
```

**Collapse Context JSON**:
```json
{
  "revision_type": "collapse_phase",
  "current_phase": 3,
  "reason": "Phase 3 completed and now simple (4 tasks, complexity 3.5)",
  "suggested_action": "Collapse Phase 3 back into main plan",
  "simplicity_metrics": {
    "tasks": 4,
    "complexity_score": 3.5,
    "completion": true
  }
}
```

**Auto-Mode Handler Response**:
```json
{
  "status": "success",
  "action_taken": "collapsed_phase",
  "phase_collapsed": 3,
  "reason": "Phase 3 completed and now simple (4 tasks, complexity 3.5)",
  "new_structure_level": 1,
  "updated_file": "specs/plans/025_plan/025_plan.md"
}
```

### Example 3: Complete Logging Integration

**Scenario**: Manual collapse with full logging

**Command**:
```bash
/collapse phase specs/plans/025_plan/ 2
```

**Execution with Logging**:
```bash
#!/usr/bin/env bash
# /collapse command implementation

# Source utilities and logger
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/home/benjamin/.config}"
source "$CLAUDE_PROJECT_DIR/.claude/lib/parse-adaptive-plan.sh"
source "$CLAUDE_PROJECT_DIR/.claude/lib/adaptive-planning-logger.sh"

# Validate and collapse phase
PHASE_NUM=2
PLAN_PATH="specs/plans/025_plan/"

# Execute collapse operation
merge_phase_into_plan "$PLAN_FILE" "$PHASE_FILE" "$PHASE_NUM"
remove_expanded_phase "$PLAN_FILE" "$PHASE_NUM"
rm "$PHASE_FILE"

# Update structure level
NEW_LEVEL=$(detect_structure_level "$PLAN_PATH")
update_structure_level "$PLAN_FILE" "$NEW_LEVEL"

# Log collapse invocation
log_collapse_invocation "$PHASE_NUM" "manual" "User-initiated collapse via /collapse command"

echo "Phase $PHASE_NUM collapsed successfully"
echo "Structure level: $NEW_LEVEL"
```

**Log Entry Created**:
```
[2025-10-09T15:45:30Z] INFO collapse_invocation: Collapsing phase 2 (manual): User-initiated collapse via /collapse command | data={"phase": 2, "trigger": "manual", "reason": "User-initiated collapse via /collapse command"}
```

**Query Log**:
```bash
$ query_adaptive_log "collapse_invocation" | tail -1
[2025-10-09T15:45:30Z] INFO collapse_invocation: Collapsing phase 2 (manual): User-initiated collapse via /collapse command | data={"phase": 2, "trigger": "manual", "reason": "User-initiated collapse via /collapse command"}
```

### Example 4: End-to-End Workflow

**Scenario**: Complete bidirectional structure optimization during implementation

**Initial State**:
- Plan has 5 phases (all inline, Level 0)
- Phase 3 is complex (12 tasks, complexity 9.0)

**Step 1: Implement Phase 3** (triggers expansion)
```bash
/implement plan.md 3

# /implement Step 3.4: Adaptive planning triggered
# - Complexity score 9.0 > threshold 8.0
# - Auto-invokes: /revise --auto-mode expand_phase
# - Phase 3 expanded to separate file
# - Structure level: 0 → 1
```

**Step 2: Continue Implementation** (complete Phase 3)
```bash
# Phase 3 implementation continues in expanded file
# All 12 tasks completed
# Tests pass
# Git commit created
```

**Step 3: Auto-Collapse Check** (Step 5.5)
```bash
# After implementation, Phase 3 now has 4 tasks (8 removed during implementation)
# Complexity recalculated: 3.2 (originally 9.0)
# Auto-collapse triggered:
#   - Phase expanded: true
#   - Phase completed: true
#   - Tasks: 4 ≤ 5
#   - Complexity: 3.2 < 6.0
#
# Auto-invokes: /revise --auto-mode collapse_phase
# Phase 3 collapsed back inline
# Structure level: 1 → 0
```

**Logs Generated**:
```
[2025-10-09T14:00:00Z] INFO complexity_check: Phase 3 complexity check: score 9.0 (threshold 8) -> triggered
[2025-10-09T14:00:05Z] INFO replan: Replanning invoked: expand_phase -> success
[2025-10-09T14:15:30Z] INFO collapse_check: Collapse check: Phase 3 complexity 3.2 (threshold 6.0) -> true
[2025-10-09T14:15:35Z] INFO collapse_invocation: Collapsing phase 3 (auto): Phase simple after completion
```

**Final State**:
- Plan back to Level 0 (all phases inline)
- Phase 3 completed with 4 tasks
- Full audit trail in logs

---

## Summary

Phase 7 completes the bidirectional structure optimization loop, enabling plans to automatically expand when complex and collapse when simple. The three tasks work together to provide:

1. **Task 7.1**: Intelligent recommendations after plan revisions
2. **Task 7.2**: Automatic collapse during implementation
3. **Task 7.3**: Complete observability via logging

**Key Benefits**:
- Plans maintain optimal structure automatically
- Reduces manual optimization work
- Full audit trail of structure evolution
- Symmetric expansion/collapse operations

**Integration Points**:
- `/revise`: Structure evaluation and auto-mode collapse handler
- `/implement`: Auto-collapse triggers in Step 5.5
- `/collapse`: Manual collapse logging
- `adaptive-planning-logger.sh`: Collapse logging functions

**Estimated Completion Time**: 6-8 hours total
- Task 7.1: 3-4 hours
- Task 7.2: 2-3 hours
- Task 7.3: 1 hour
