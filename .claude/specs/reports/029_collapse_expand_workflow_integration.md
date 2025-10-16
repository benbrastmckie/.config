# Collapse/Expand Workflow Integration Analysis

## Metadata
- **Date**: 2025-10-09
- **Scope**: Analysis of `/collapse` and `/expand` role in .claude/ workflows and optimization opportunities
- **Primary Commands**: collapse.md, expand.md, revise.md, implement.md
- **Primary Utility**: parse-adaptive-plan.sh
- **Files Analyzed**: 5 command files, 1 core utility library
- **Research Time**: 75 minutes

## Executive Summary

The `.claude/` system has **excellent expansion infrastructure** with **limited collapse integration**. Key findings:

**Current State**: ✅ Expansion Excellent, ⚠️ Collapse Underutilized
- `/expand`: Comprehensive command with complexity detection and agent integration
- `/collapse`: Fully implemented command but rarely invoked automatically
- `/revise`: **No automatic collapse/expand evaluation** (user's intuition is correct)
- `/implement`: ✅ Proactive expansion check (Step 1.55), ✅ Reactive expansion via adaptive planning (Step 3.4), ⚠️ Collapse check exists (Step 5.5) but purely informational

**Gap Identified**: `/revise` is a natural integration point for bidirectional plan optimization but currently only modifies content without structure optimization.

**Recommended Solution**: Add automatic expansion/collapse evaluation to `/revise` to create a comprehensive plan optimization workflow.

## Background

### Progressive Plan Structure

Plans evolve through three structure levels:

```
Level 0: Single File
  025_feature.md                    (All phases inline)

Level 1: Phase Expansion
  025_feature/
    ├── 025_feature.md              (Main plan with summaries)
    ├── phase_2_impl.md             (Expanded phase)
    └── phase_3_testing.md          (Expanded phase)

Level 2: Stage Expansion
  025_feature/
    ├── 025_feature.md              (Main plan)
    ├── phase_2_impl/               (Phase directory)
    │   ├── phase_2_impl.md         (Phase with stage summaries)
    │   ├── stage_1_backend.md      (Expanded stage)
    │   └── stage_2_frontend.md     (Expanded stage)
    └── phase_3_testing.md
```

### Commands that Modify Structure

**Direct Structure Commands**:
- `/expand [phase|stage] <path> <number>` - Expands phase or stage to separate file
- `/collapse [phase|stage] <path> <number>` - Collapses expanded phase or stage back

**Commands that Could Optimize Structure**:
- `/revise` - Modifies plan content (currently does not evaluate structure)
- `/implement` - Executes plan (has proactive expansion check, collapse opportunity detection)

## Current State Analysis

### 1. `/expand` Command - Comprehensive Implementation

**Features**:
- ✅ Progressive structure support (L0→L1, L1→L2)
- ✅ Complexity detection for agent research decisions
- ✅ Agent integration for complex phases (general-purpose agent)
- ✅ Metadata synchronization across all levels
- ✅ Cross-reference updates

**Complexity Thresholds** (expand.md:78-86):
```bash
# Complex Phase if:
- task_count > 5
- file_refs > 10
- Contains keywords: "consolidate", "refactor", "migrate"
```

**Agent Integration**:
- Complex phases → Task tool with general-purpose agent (300-500+ line specs)
- Simple phases → Direct expansion (200-300 lines)

**Quality**: ✅ Excellent - Production-ready, well-tested

### 2. `/collapse` Command - Complete but Manual

**Features**:
- ✅ Reverse expansion (L1→L0, L2→L1)
- ✅ Content preservation (all completion markers maintained)
- ✅ Three-way metadata updates (stage → phase → main plan)
- ✅ Automatic directory cleanup when last expansion collapses
- ✅ Safety checks (prevents collapsing phases with expanded stages)

**Safety Mechanisms** (collapse.md:108-110):
- Cannot collapse phase with expanded stages
- Must collapse stages first (L2→L1→L0 progression)

**Process**:
```
/collapse phase <plan> <number>
  ↓
Read expanded phase content
  ↓
Merge content back into main plan
  ↓
Update metadata (remove from Expanded Phases)
  ↓
Delete phase file
  ↓
[If last phase] Convert to L0 (move file, delete dir)
```

**Quality**: ✅ Excellent - Safe, reversible, well-implemented

**Current Usage**: ⚠️ Manual only - no automatic invocation

### 3. `/revise` Command - Content-Only Modification

**Current Behavior** (revise.md):

**Interactive Mode** (lines 11-96):
- User provides revision description
- Infers plan from conversation context
- Modifies plan content
- Adds revision history
- **Does NOT evaluate structure**

**Auto-Mode** (lines 98-490):
- Invoked by `/implement` during adaptive planning
- Four revision types:
  1. `expand_phase` - Invokes `/expand` when complexity detected
  2. `add_phase` - Inserts missing phase
  3. `split_phase` - Splits overly broad phase
  4. `update_tasks` - Modifies task list
- **ONLY expands, never collapses**

**Gap**: `/revise` modifies content but doesn't optimize structure bidirectionally

### 4. `/implement` Command - Proactive Expansion + Collapse Detection

**Expansion Integration**:

**Step 1.55: Proactive Expansion Check** (implement.md:398-472):
- **When**: BEFORE phase implementation
- **Method**: Agent-based judgment on phase complexity
- **Action**: Recommendation only (non-blocking)
- **Evaluation Criteria**:
  - Task complexity (not just count, but actual complexity)
  - Scope breadth (files, modules, subsystems touched)
  - Interrelationships between tasks
  - Potential for parallel work
  - Clarity vs detail tradeoff

**Step 3.4: Reactive Expansion (Adaptive Planning)** (implement.md:613-819):
- **When**: AFTER phase implementation (successful or with errors)
- **Method**: Trigger detection (complexity, test failures, scope drift)
- **Action**: Automatically invokes `/revise --auto-mode`
- **Triggers**:
  1. Complexity threshold exceeded (score > 8 or tasks > 10)
  2. Test failure patterns (2+ consecutive failures)
  3. Scope drift (manual flag or discovered work)

**Collapse Integration**:

**Step 5.5: Collapse Opportunity Detection** (implement.md:911-1014):
- **When**: AFTER phase completion and commit
- **Method**: Agent-based judgment on completed phase simplicity
- **Action**: Recommendation only (non-blocking)
- **Evaluation Criteria**:
  - Completion status (all tasks done)
  - Simplicity (task count and complexity)
  - Dependencies (minimal interdependencies)
  - Value vs simplicity (organizational value assessment)
  - Conceptual importance (should it stay separate?)

**Workflow**:
```
/implement Phase N
  ↓
[Step 1.55] Proactive expansion check
  → Recommendation: /expand phase <plan> N (if complex)
  ↓
Implement phase
  ↓
[Step 3.4] Reactive expansion (if triggered)
  → Auto-invokes: /revise --auto-mode expand_phase
  ↓
Phase complete
  ↓
Git commit
  ↓
[Step 5.5] Collapse opportunity detection
  → Recommendation: /collapse phase <plan> N (if simple and expanded)
```

**Quality**: ✅ Excellent proactive/reactive expansion, ✅ Collapse detection present but informational only

### 5. Adaptive Planning Logger Integration

**Logging** (implement.md:35):
- Uses `.claude/lib/adaptive-planning-logger.sh`
- Logs complexity checks, replan invocations, loop prevention
- Provides observability for adaptive planning

**NOT Currently Logged**:
- Collapse opportunity detections
- Manual collapse operations
- Structure optimization decisions

## Key Findings

### Finding 1: `/revise` Has No Structure Optimization

**Current `/revise` Capabilities**:
- ✅ Modify plan content (tasks, objectives, scope)
- ✅ Add/remove/split phases
- ✅ Update metadata and revision history
- ✅ Integration with `/implement` via auto-mode
- ❌ **NO expansion/collapse evaluation**

**User's Intuition is Correct**: `/revise` is a natural place to evaluate structure optimization.

**Why This Matters**:
- Users manually call `/revise` when rethinking plan organization
- `/revise` already modifies plans structurally (add/split phases)
- Opportunity to optimize structure automatically during revision

**Current Workflow** (manual):
```
User: /revise "Split Phase 3 into smaller phases"
  ↓
/revise splits Phase 3 → Phase 3, 4, 5
  ↓
[User must manually evaluate if any phases should now be collapsed]
  ↓
User: /collapse phase <plan> 4  [manual]
```

**Desired Workflow** (automatic):
```
User: /revise "Split Phase 3 into smaller phases"
  ↓
/revise splits Phase 3 → Phase 3, 4, 5
  ↓
[AUTO] Evaluate each affected phase for expansion/collapse
  ↓
[AUTO] Recommend: "Phase 4 is now simple enough to collapse"
```

### Finding 2: Expansion is Proactive, Collapse is Reactive

**Expansion**:
- ✅ Proactive check BEFORE implementation (/implement Step 1.55)
- ✅ Reactive check AFTER implementation (/implement Step 3.4 adaptive planning)
- ✅ Automatic expansion via `/revise --auto-mode`

**Collapse**:
- ⚠️ Detection only AFTER phase completion (/implement Step 5.5)
- ⚠️ Recommendation only (non-blocking, user must execute)
- ❌ **NO automatic collapse via `/revise --auto-mode`**

**Asymmetry**: Expansion is automatic and integrated, collapse is manual and advisory.

**Why This Matters**:
- Plans can expand automatically but not contract automatically
- Over time, plans may become over-expanded without user intervention
- User must remember to collapse manually after plan evolution

### Finding 3: `/implement` Collapse Detection is Informational Only

**Current Behavior** (implement.md:911-1014):

**Collapse Opportunity Detection**:
- Evaluates completed, expanded phases
- Provides recommendation with command
- Non-blocking: user can ignore or execute manually

**Why Informational Only**:
- Collapsing mid-implementation could confuse user
- User may want to review all phases before collapsing
- Timing: better to collapse after ALL phases complete

**Trade-off**:
- ✅ User control and visibility
- ✅ Avoids mid-workflow structure changes
- ❌ User must remember recommendations
- ❌ Recommendations may be ignored

### Finding 4: Adaptive Planning Lacks Collapse Support

**Auto-Mode Revision Types** (revise.md:165-320):

**Current Types**:
1. `expand_phase` - Expands complex phase
2. `add_phase` - Inserts missing phase
3. `split_phase` - Splits overly broad phase
4. `update_tasks` - Modifies task list

**Missing Type**:
5. `collapse_phase` - Collapses simple phase ❌

**Why This Matters**:
- `/implement` can trigger auto-expansion but not auto-collapse
- After splitting phases, no automatic collapse of resulting simple phases
- Asymmetric adaptation: plans grow but don't shrink

### Finding 5: No `/revise` Integration with Structure Evaluation

**Gap**: `/revise` modifies plan content but doesn't evaluate if structure should change.

**Scenarios Where Structure Evaluation Would Help**:

**Scenario 1: Content Simplification**
```
User: /revise "Remove database migration tasks, they're handled elsewhere"
  ↓
/revise removes 8 tasks from Phase 2
  ↓
Phase 2 now has only 3 tasks (was 11 tasks)
  ↓
[OPPORTUNITY] Phase 2 is now simple enough to collapse
  ↓
[MISSING] No automatic detection or recommendation
```

**Scenario 2: Content Expansion**
```
User: /revise "Add detailed security audit tasks to Phase 4"
  ↓
/revise adds 12 tasks to Phase 4
  ↓
Phase 4 now has 16 tasks (was 4 tasks)
  ↓
[OPPORTUNITY] Phase 4 is now complex enough to expand
  ↓
[MISSING] No automatic detection or recommendation
```

**Scenario 3: Phase Splitting**
```
User: /revise "Split Phase 3 into 3 smaller phases"
  ↓
/revise splits Phase 3 → Phase 3, 4, 5
  ↓
[OPPORTUNITY] Evaluate each new phase for structure needs
  ↓
[MISSING] No automatic expansion/collapse evaluation
```

### Finding 6: Progressive Utilities Support Both Operations Equally

**parse-adaptive-plan.sh Analysis**:

**Expansion Functions** (lines 14-577):
- `detect_structure_level` - Detects L0/L1/L2
- `is_plan_expanded`, `is_phase_expanded`, `is_stage_expanded`
- `list_expanded_phases`, `list_expanded_stages`
- `extract_phase_content`, `extract_stage_content`
- `revise_main_plan_for_phase`, `add_phase_metadata`
- `update_structure_level`, `update_expanded_phases`

**Collapse Functions** (lines 809-1077):
- `merge_phase_into_plan`, `merge_stage_into_phase`
- `remove_expanded_phase`, `remove_phase_expanded_stage`
- `has_remaining_phases`, `has_remaining_stages`
- `cleanup_plan_directory`, `cleanup_phase_directory`

**Symmetry**: ✅ Utilities support both expansion and collapse equally well

**Quality**: ✅ Production-ready, comprehensive, well-tested

**Gap**: Commands don't leverage collapse utilities as much as expansion utilities

## Optimization Opportunities

### Opportunity 1: Add Structure Evaluation to `/revise`

**Objective**: Automatically evaluate expansion/collapse opportunities when revising plans

**Implementation** (3-4 hours):

**Step 1: Add Post-Revision Structure Analysis**

After `/revise` completes content modifications:
```bash
# For each phase affected by revision
for phase_num in $(affected_phases); do
  # Check if phase is expanded
  is_expanded=$(./claude/lib/parse-adaptive-plan.sh is_phase_expanded "$plan_path" "$phase_num")

  if [ "$is_expanded" = "true" ]; then
    # Evaluate collapse opportunity
    should_collapse=$(evaluate_collapse_opportunity "$phase_num" "$plan_path")
    if [ "$should_collapse" = "true" ]; then
      recommend_collapse "$phase_num"
    fi
  else
    # Evaluate expansion opportunity
    should_expand=$(evaluate_expansion_opportunity "$phase_num" "$plan_path")
    if [ "$should_expand" = "true" ]; then
      recommend_expansion "$phase_num"
    fi
  fi
done
```

**Step 2: Create Evaluation Functions**

```bash
# Evaluate if expanded phase should be collapsed
evaluate_collapse_opportunity() {
  local phase_num="$1"
  local plan_path="$2"

  # Extract phase complexity
  local phase_file=$(./claude/lib/parse-adaptive-plan.sh get_phase_file "$plan_path" "$phase_num")
  local task_count=$(grep -c "^- \[ \]" "$phase_file")
  local complexity_score=$(calculate_complexity "$phase_file")

  # Collapse if: tasks <= 5 AND complexity < 6.0
  if [ "$task_count" -le 5 ] && (( $(echo "$complexity_score < 6.0" | bc -l) )); then
    echo "true"
  else
    echo "false"
  fi
}

# Evaluate if inline phase should be expanded
evaluate_expansion_opportunity() {
  local phase_num="$1"
  local plan_path="$2"

  # Extract phase content from main plan
  local plan_file="$plan_path"
  [ -d "$plan_path" ] && plan_file="$plan_path/$(basename "$plan_path").md"

  local phase_content=$(./claude/lib/parse-adaptive-plan.sh extract_phase_content "$plan_file" "$phase_num")
  local task_count=$(echo "$phase_content" | grep -c "^- \[ \]")
  local complexity_score=$(calculate_complexity_from_content "$phase_content")

  # Expand if: tasks > 10 OR complexity > 8.0
  if [ "$task_count" -gt 10 ] || (( $(echo "$complexity_score > 8.0" | bc -l) )); then
    echo "true"
  else
    echo "false"
  fi
}
```

**Step 3: Add Recommendations Section to Revision History**

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

**Benefits**:
- Automatic structure optimization guidance
- Integrated into existing `/revise` workflow
- Preserves user control (recommendations, not automatic changes)
- Natural timing: user is already thinking about plan organization

**Effort**: 3-4 hours (evaluation functions, recommendation display, integration)

**Impact**: ✅✅✅ High - transforms `/revise` into comprehensive plan optimization tool

### Opportunity 2: Add `collapse_phase` to Auto-Mode Revision Types

**Objective**: Enable automatic collapse during adaptive planning

**Implementation** (2-3 hours):

**Step 1: Add Collapse Revision Type**

In `/revise` auto-mode handler (revise.md):

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
    # Invoke /collapse phase
    phase_num="$current_phase"
    result=$(/collapse phase "$plan_path" "$phase_num")

    # Update metadata
    update_structure_level "$plan_path"

    # Return success response
    echo '{
      "status": "success",
      "action_taken": "collapsed_phase",
      "phase_collapsed": '$phase_num',
      "new_structure_level": '$new_level'
    }'
    ;;
esac
```

**Step 2: Define Collapse Trigger Context**

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

**Step 3: Update `/implement` to Trigger Auto-Collapse**

Modify Step 5.5 to invoke `/revise --auto-mode` instead of just recommending:

```bash
# In /implement Step 5.5 (collapse opportunity detection)
if [ "$collapse_recommended" = "true" ]; then
  # Build collapse context
  collapse_context=$(build_collapse_context "$phase_num" "$complexity_score" "$task_count")

  # Invoke /revise --auto-mode
  /revise "$plan_path" --auto-mode --context "$collapse_context"

  # Log action
  echo "Auto-collapsed Phase $phase_num (simple after completion)"
fi
```

**Benefits**:
- Symmetry with auto-expansion
- Plans automatically optimize structure bidirectionally
- Reduces plan bloat over time
- Consistent with adaptive planning philosophy

**Effort**: 2-3 hours (auto-mode handler, context definition, integration)

**Impact**: ✅✅ Medium-High - enables automatic plan structure optimization

### Opportunity 3: Add Collapse Logging to Adaptive Planning Logger

**Objective**: Track collapse operations for observability

**Implementation** (1 hour):

**Step 1: Add Collapse Event Types**

In `.claude/lib/adaptive-planning-logger.sh`:

```bash
# Log collapse opportunity detection
log_collapse_check() {
  local phase_num="$1"
  local complexity_score="$2"
  local threshold="$3"
  local triggered="$4"  # true/false

  log_event "INFO" "collapse_check" \
    "Phase $phase_num collapse check: complexity $complexity_score (threshold $threshold)" \
    "{\"phase\": $phase_num, \"complexity\": $complexity_score, \"threshold\": $threshold, \"triggered\": $triggered}"
}

# Log collapse invocation
log_collapse_invocation() {
  local phase_num="$1"
  local trigger_type="$2"  # "manual" or "auto"
  local reason="$3"

  log_event "INFO" "collapse_invocation" \
    "Collapsing phase $phase_num ($trigger_type): $reason" \
    "{\"phase\": $phase_num, \"trigger\": \"$trigger_type\", \"reason\": \"$reason\"}"
}
```

**Step 2: Integrate Logging into Commands**

```bash
# In /collapse command
log_collapse_invocation "$phase_num" "manual" "User-initiated collapse"

# In /implement Step 5.5
log_collapse_check "$phase_num" "$complexity_score" "6.0" "$triggered"
if [ "$triggered" = "true" ]; then
  log_collapse_invocation "$phase_num" "auto" "Phase simple after completion"
fi

# In /revise auto-mode (collapse_phase)
log_collapse_invocation "$phase_num" "auto" "$reason"
```

**Benefits**:
- Consistent observability with expansion logging
- Audit trail for structure optimization
- Debug support for collapse decisions

**Effort**: 1 hour (logging functions, integration)

**Impact**: ✅ Low-Medium - improves debugging and transparency

### Opportunity 4: Bidirectional Structure Optimization in `/revise`

**Objective**: Automatically apply structure optimization after user revisions

**Implementation** (4-5 hours):

**Step 1: Add `--optimize-structure` Flag**

```bash
/revise <revision-details> [--optimize-structure] [report-path1] ...
```

**Behavior**:
- Evaluate all phases after revision
- Automatically collapse simple phases
- Automatically expand complex phases
- Show summary of structure changes

**Step 2: Implement Optimization Logic**

```bash
if [ "$optimize_structure" = "true" ]; then
  echo "Optimizing plan structure..."

  # Collapse simple expanded phases
  for phase_num in $(list_expanded_phases "$plan_path"); do
    if should_collapse "$phase_num"; then
      echo "  Collapsing Phase $phase_num (now simple)..."
      /collapse phase "$plan_path" "$phase_num"
    fi
  done

  # Expand complex inline phases
  for phase_num in $(list_inline_phases "$plan_path"); do
    if should_expand "$phase_num"; then
      echo "  Expanding Phase $phase_num (now complex)..."
      /expand phase "$plan_path" "$phase_num"
    fi
  done

  echo "Structure optimization complete"
fi
```

**Step 3: Add Optimization Summary**

```markdown
## Structure Optimization

Applied during revision:
- **Collapsed**: Phase 3 (4 tasks, complexity 3.2)
- **Expanded**: Phase 5 (14 tasks, complexity 9.5)
- **Result**: Structure optimized from Level 1 to Level 1 (net neutral)
```

**Benefits**:
- One-command structure optimization
- User can review changes before accepting
- Natural workflow during plan revision

**Effort**: 4-5 hours (flag handling, optimization logic, summary generation)

**Impact**: ✅✅✅ High - provides comprehensive structure optimization

### Opportunity 5: Smart Collapse During Implementation Completion

**Objective**: Automatically collapse when ALL phases complete

**Implementation** (2 hours):

**Step 1: Detect Plan Completion**

In `/implement` final summary generation:

```bash
# After all phases complete
if all_phases_complete; then
  echo "All phases complete. Evaluating final structure optimization..."

  # Evaluate each expanded phase
  for phase_num in $(list_expanded_phases "$plan_path"); do
    if should_collapse "$phase_num"; then
      echo "  Collapsing Phase $phase_num (simple)..."
      /collapse phase "$plan_path" "$phase_num"
      collapsed_phases="$collapsed_phases $phase_num"
    fi
  done

  if [ -n "$collapsed_phases" ]; then
    echo "Collapsed phases: $collapsed_phases"
    echo "Plan structure optimized after implementation"
  fi
fi
```

**Timing Advantage**:
- User has completed all work
- Full context of plan execution available
- Can see which phases were truly simple vs complex
- Good time for cleanup and consolidation

**Benefits**:
- Automatic post-implementation cleanup
- Plans stored in optimal structure
- Reduces repository clutter

**Effort**: 2 hours (completion detection, batch collapse)

**Impact**: ✅✅ Medium - improves plan quality long-term

## Recommended Implementation Priority

### Phase 1: `/revise` Structure Evaluation (Opportunity 1)

**Why First**:
- User's original intuition - natural integration point
- High impact, moderate effort
- Provides immediate value without breaking changes
- Foundation for other improvements

**Deliverables**:
- Post-revision structure analysis
- Expansion/collapse evaluation functions
- Recommendation display in revision history

**Effort**: 3-4 hours

**Impact**: ✅✅✅ High

### Phase 2: Auto-Mode Collapse Support (Opportunity 2)

**Why Second**:
- Builds on Phase 1 evaluation logic
- Enables adaptive planning symmetry
- Integrates with existing `/implement` workflow
- Natural progression from recommendations to automation

**Deliverables**:
- `collapse_phase` revision type
- Auto-collapse integration in `/implement` Step 5.5
- Collapse context definition

**Effort**: 2-3 hours

**Impact**: ✅✅ Medium-High

### Phase 3: Collapse Logging (Opportunity 3)

**Why Third**:
- Complements Phase 2 automation
- Low effort, good incremental value
- Improves debugging and transparency
- Consistent with existing logging infrastructure

**Deliverables**:
- Collapse logging functions
- Integration into `/collapse`, `/revise`, `/implement`
- Audit trail for structure optimization

**Effort**: 1 hour

**Impact**: ✅ Low-Medium

### Phase 4: Bidirectional Optimization Flag (Opportunity 4)

**Why Fourth** (Optional):
- Advanced feature for power users
- Builds on Phases 1-2
- Higher complexity, optional enhancement
- Can be deferred if time-constrained

**Deliverables**:
- `--optimize-structure` flag
- Automatic collapse + expand logic
- Optimization summary

**Effort**: 4-5 hours

**Impact**: ✅✅✅ High (but optional)

### Phase 5: Smart Completion Collapse (Opportunity 5)

**Why Fifth** (Optional):
- Nice-to-have optimization
- Dependent on Phase 2
- Lower priority, can be deferred
- Best done after observing user behavior

**Deliverables**:
- Plan completion detection
- Batch collapse on completion
- Summary of optimizations

**Effort**: 2 hours

**Impact**: ✅✅ Medium (but optional)

## Performance Considerations

### Evaluation Overhead

**Complexity Calculation**: ~0.5-1 second per phase
**Structure Detection**: < 0.1 second (uses file system checks)
**Collapse/Expand Operation**: 2-5 seconds per phase

**Impact on `/revise`**:
- Phase 1 (recommendations only): +1-2 seconds per revision
- Phase 4 (automatic optimization): +5-15 seconds per revision

**Acceptable Trade-off**: Structure optimization worth extra seconds

### Logging Overhead

**Adaptive Planning Logger**: Negligible (<0.1 second per log entry)
**Log File Size**: Minimal (rotates at 10MB, 5 files max)

**Impact**: None - logging is async and lightweight

## Workflow Comparison

### Current Workflow (Manual Structure Optimization)

```
User: /revise "Split Phase 3 into 3 phases"
  ↓
/revise splits Phase 3 → Phase 3, 4, 5
  ↓
User notices Phase 4 is now simple
  ↓
User: /collapse phase <plan> 4
  ↓
Manual collapse executed
```

**Issues**:
- User must remember to evaluate structure
- Easy to forget or overlook optimization opportunities
- Multiple manual steps required

### Optimized Workflow (Phase 1: Recommendations)

```
User: /revise "Split Phase 3 into 3 phases"
  ↓
/revise splits Phase 3 → Phase 3, 4, 5
  ↓
[AUTO] Structure evaluation
  ↓
Recommendation shown: "Phase 4 is now simple (4 tasks). Consider: /collapse phase <plan> 4"
  ↓
User executes: /collapse phase <plan> 4
```

**Benefits**:
- Automatic detection and suggestion
- User still in control
- Clear guidance on what to do

### Optimized Workflow (Phase 2: Auto-Collapse)

```
User: /implement <plan>
  ↓
Phase 3 complete
  ↓
[AUTO] Collapse check
  ↓
[AUTO] /revise --auto-mode collapse_phase
  ↓
Phase 3 collapsed (simple after completion)
  ↓
Continue to Phase 4
```

**Benefits**:
- Fully automatic optimization
- No user intervention needed
- Plans stay optimally structured

## Integration with Other Commands

### `/plan` Integration (Future)

**Opportunity**: Evaluate initial plan structure after creation

```
/plan "Feature X"
  ↓
Plan created with 6 phases
  ↓
[FUTURE] Evaluate each phase complexity
  ↓
Auto-expand complex phases immediately
```

**Benefits**: Plans optimally structured from creation

**Note**: This is covered by report 028 (post-creation evaluation)

### `/orchestrate` Integration (Future)

**Opportunity**: Structure optimization during multi-agent workflows

```
/orchestrate "Complex feature"
  ↓
Plan created by plan-architect
  ↓
[FUTURE] Evaluate plan structure
  ↓
Optimize before implementation begins
```

**Benefits**: Multi-agent workflows produce optimally structured plans

## Summary

### Current State

**Strengths**:
- ✅ Excellent `/expand` and `/collapse` commands
- ✅ Comprehensive progressive utilities (parse-adaptive-plan.sh)
- ✅ Proactive expansion in `/implement` (Step 1.55)
- ✅ Reactive expansion via adaptive planning (Step 3.4)
- ✅ Collapse detection in `/implement` (Step 5.5)

**Gaps**:
- ❌ `/revise` has no structure evaluation (user's intuition correct)
- ❌ Collapse is manual, expansion is automatic (asymmetry)
- ❌ No auto-mode collapse support
- ❌ No collapse logging in adaptive planning logger

### Recommended Improvements

**Priority 1: `/revise` Structure Evaluation** (3-4 hours)
- Add post-revision expansion/collapse recommendations
- Natural integration point for structure optimization
- High impact, moderate effort

**Priority 2: Auto-Mode Collapse Support** (2-3 hours)
- Enable automatic collapse during adaptive planning
- Symmetry with auto-expansion
- Medium-high impact

**Priority 3: Collapse Logging** (1 hour)
- Track collapse operations for observability
- Complement existing expansion logging
- Low effort, good incremental value

**Total Core Effort**: 6-8 hours for Phases 1-3

**Optional Enhancements**: 6-7 hours for Phases 4-5

### Expected Benefits

1. **User-Requested Feature**: `/revise` structure evaluation addresses user's correct intuition
2. **Bidirectional Optimization**: Plans can grow AND shrink automatically
3. **Reduced Manual Work**: Automatic recommendations reduce user cognitive load
4. **Better Plan Quality**: Plans stay optimally structured over time
5. **Consistent with Adaptive Philosophy**: Extends existing adaptive planning to structure optimization

## References

### Command Documentation Analyzed

1. **collapse.md** (414 lines) - Phase/stage collapse with safety checks
2. **expand.md** (352 lines) - Phase/stage expansion with agent integration
3. **revise.md** (596 lines) - Interactive and automated plan revision
4. **implement.md** (1553 lines) - Implementation with proactive/reactive expansion
5. **parse-adaptive-plan.sh** (1298 lines) - Progressive structure utilities

### Complexity Thresholds

**Expansion** (expand.md:78-86):
- Task count > 5
- File references > 10
- Keywords: consolidate, refactor, migrate

**Collapse** (should mirror expansion):
- Task count ≤ 5
- Complexity score < 6.0
- No expanded sub-phases

### Progressive Structure Levels

- **Level 0**: Single file (NNN_feature.md)
- **Level 1**: Phase expansion (NNN_feature/)
- **Level 2**: Stage expansion (NNN_feature/phase_N/)

### Related Reports

- **Report 028**: Adaptive plan workflow analysis (post-creation evaluation)
- **Report 027**: Artifact creation workflow (not directly related but shows spec-reality gaps)

