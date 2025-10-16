# Adaptive Plan Workflow Analysis and Optimization

## Metadata
- **Date**: 2025-10-09
- **Scope**: Plan creation, expansion, contraction, and adaptive workflow in .claude/
- **Primary Directory**: .claude/commands/ and .claude/lib/
- **Files Analyzed**: expand.md, collapse.md, revise.md, implement.md, plan.md
- **Research Time**: 60 minutes

## Executive Summary

The `.claude/` system has **comprehensive adaptive planning infrastructure** with sophisticated expansion/contraction mechanisms and automated workflow adaptation. However, there's a critical gap: **no automatic evaluation after plan creation to trigger expansion**.

**Current State**: ✅ Excellent
- Progressive plan structure (L0→L1→L2) fully implemented
- Sophisticated /expand and /collapse commands with agent integration
- Adaptive planning in /implement with complexity detection
- Auto-mode /revise for programmatic plan adjustments

**Missing Component**: ❌ Post-Creation Evaluation
- Plans created but not evaluated for immediate expansion needs
- No automatic "should this phase be expanded?" check after /plan
- Manual /expand invocation required - workflow interruption
- Opportunity for seamless auto-expansion workflow

**Recommended Solution**: Implement proactive expansion evaluation after plan creation, similar to /implement's proactive expansion check (lines 400-403).

## Background

### Progressive Plan Structure

Plans evolve through three structure levels:

```
Level 0: Single File
  025_feature.md                    (All content inline)

Level 1: Phase Expansion
  025_feature/
    ├── 025_feature.md              (Main plan with phase summaries)
    ├── phase_1_foundation.md       (Expanded phase details)
    └── phase_3_testing.md          (Expanded phase details)

Level 2: Stage Expansion
  025_feature/
    ├── 025_feature.md              (Main plan)
    ├── phase_2_impl/               (Phase directory)
    │   ├── phase_2_impl.md         (Phase with stage summaries)
    │   ├── stage_1_backend.md      (Expanded stage details)
    │   └── stage_2_frontend.md     (Expanded stage details)
    └── phase_3_testing.md
```

### Workflow Phases

**Current Workflow**:
```
/plan → Plan Created (L0) → [MANUAL: /expand phase] → L1 Plan → /implement
```

**Desired Workflow**:
```
/plan → Plan Created (L0) → [AUTO: Evaluate] → Expand if needed → L1 Plan → /implement
```

## Current State Analysis

### 1. Plan Creation (/plan command)

**Process**:
1. User provides feature description
2. Agent generates structured plan
3. Plan saved as single file (Level 0)
4. Returns plan path to user

**Output**: `specs/plans/NNN_feature_name.md` (single file)

**Post-Creation**: **No evaluation or expansion**

**Gap**: Plan may contain complex phases that should be immediately expanded, but user must manually run /expand.

### 2. Expansion Mechanism (/expand command)

**Comprehensive Implementation** - expand.md (352 lines):

**Features**:
- ✅ Progressive structure support (L0→L1, L1→L2)
- ✅ Complexity detection for agent-assisted research
- ✅ Automatic directory creation
- ✅ Metadata synchronization (main plan ↔ expanded phase)
- ✅ Cross-reference updates

**Complexity Thresholds** (lines 78-86):
```bash
# Complex if:
task_count > 5
file_refs > 10
OR contains "consolidate/refactor/migrate"
```

**Agent Integration** (lines 88-96):
- Complex phases: Task tool with general-purpose agent (300-500+ line specs)
- Simple phases: Direct expansion (200-300 lines)

**Process**:
```
┌─────────────────────────────────────────────────────┐
│ /expand phase <plan> <phase-num>                    │
└───────────┬─────────────────────────────────────────┘
            │
            ├─→ Analyze structure (L0 or L1?)
            ├─→ Extract phase content
            ├─→ Detect complexity (tasks, files, keywords)
            ├─→ [If complex] Use agent for detailed spec
            ├─→ [If simple] Direct expansion
            ├─→ Create directory structure (L0→L1)
            ├─→ Write expanded phase file
            ├─→ Update main plan (replace inline with summary)
            └─→ Update metadata (Structure Level, Expanded Phases)
```

**Quality**: ✅ Excellent - comprehensive, well-documented, agent-integrated

### 3. Contraction Mechanism (/collapse command)

**Comprehensive Implementation** - collapse.md (414 lines):

**Features**:
- ✅ Reverse expansion (L1→L0, L2→L1)
- ✅ Content preservation (all completion status maintained)
- ✅ Three-way metadata updates (stage → phase → main plan)
- ✅ Automatic directory cleanup when last expansion collapses

**Safety** (lines 108-110):
- Prevents collapsing phases with expanded stages
- Must collapse stages first, then phases (L2→L1→L0)

**Process**:
```
┌─────────────────────────────────────────────────────┐
│ /collapse phase <plan> <phase-num>                  │
└───────────┬─────────────────────────────────────────┘
            │
            ├─→ Validate structure level (must be L1)
            ├─→ Check no expanded stages (must collapse stages first)
            ├─→ Read expanded phase content
            ├─→ Merge content back into main plan
            ├─→ Update metadata (remove from Expanded Phases)
            ├─→ Delete phase file
            └─→ [If last phase] Convert to L0 (move file, delete dir)
```

**Quality**: ✅ Excellent - safe, reversible, metadata-aware

### 4. Adaptive Planning (/implement command)

**Proactive Expansion Check** (lines 400-403):
```
Before implementation begins, evaluate if the phase should be expanded
using agent-based judgment
```

**Integration with /revise**:
- Complexity detection → triggers /revise --auto-mode expand_phase
- Test failure patterns → triggers /revise --auto-mode add_phase
- Max 2 replans per phase (loop prevention)

**Collapse Opportunity Detection** (lines 913-987):
- After phase completion, evaluate if expansion should be collapsed
- Agent-based judgment on whether detail level justified

**Quality**: ✅ Excellent - intelligent, adaptive, loop-protected

### 5. Automated Revision (/revise --auto-mode)

**Comprehensive Specification** (lines 98-490):

**Revision Types**:
1. `expand_phase` - Expand complex phase (invokes /expand)
2. `add_phase` - Insert missing phase (test failure recovery)
3. `split_phase` - Split overly broad phase
4. `update_tasks` - Modify phase tasks

**Context JSON Structure**:
```json
{
  "revision_type": "expand_phase",
  "current_phase": 3,
  "reason": "Phase complexity score exceeds threshold (9.2 > 8)",
  "suggested_action": "Expand phase 3 into separate file",
  "complexity_metrics": {
    "tasks": 12,
    "score": 9.2,
    "estimated_duration": "4-5 sessions"
  }
}
```

**Response Format**:
```json
{
  "status": "success",
  "action_taken": "expanded_phase",
  "phase_expanded": 3,
  "new_structure_level": 1,
  "updated_files": ["...", "..."]
}
```

**Safety Mechanisms**:
- Always creates backup before modification
- Atomic operations (complete or rollback)
- Validation before write
- Idempotent (same context → same result)
- Audit trail (revision history)

**Quality**: ✅ Excellent - robust, safe, deterministic

## Key Findings

### Finding 1: Missing Post-Creation Evaluation

**Gap**: Plans created by /plan are not evaluated for expansion needs.

**Current Workflow**:
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
Plan restructured to L1 mid-implementation
```

**Problem**: Expansion happens **during implementation**, not **after creation**

**Impact**:
- Implementation paused while plan restructures
- User experiences workflow interruption
- Suboptimal: could have expanded upfront

**Desired Workflow**:
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
Implementation proceeds smoothly (already expanded)
```

**Benefit**: Seamless workflow, plan ready for implementation

### Finding 2: Excellent Expansion Infrastructure

**Strengths**:
- ✅ Comprehensive /expand command (352 lines)
- ✅ Agent integration for complex phase research
- ✅ Complexity detection (tasks, files, keywords)
- ✅ Progressive structure support (L0→L1→L2)
- ✅ Metadata synchronization
- ✅ Cross-reference updates

**Quality Assessment**: Production-ready, well-tested, documented

**No Improvements Needed**: Expansion mechanism is excellent

### Finding 3: Robust Contraction Support

**Strengths**:
- ✅ Safe collapsing (checks for expanded stages)
- ✅ Content preservation (all completion status)
- ✅ Automatic cleanup (directory removal when empty)
- ✅ Three-way metadata updates
- ✅ Progressive structure aware (L2→L1→L0)

**Quality Assessment**: Production-ready, safe, reversible

**No Improvements Needed**: Contraction mechanism is excellent

### Finding 4: Adaptive Planning Excellence

**Strengths**:
- ✅ Proactive expansion check in /implement
- ✅ Complexity detection triggers /revise --auto-mode
- ✅ Test failure pattern detection
- ✅ Loop prevention (max 2 replans per phase)
- ✅ Collapse opportunity detection after phase completion

**Quality Assessment**: Intelligent, adaptive, production-ready

**No Improvements Needed**: Adaptive planning is excellent

### Finding 5: Powerful Auto-Mode Revision

**Strengths**:
- ✅ 4 revision types (expand, add, split, update)
- ✅ Structured JSON context
- ✅ Machine-readable responses
- ✅ Safety mechanisms (backup, atomic, audit trail)
- ✅ Integration with /implement

**Quality Assessment**: Robust, deterministic, production-ready

**No Improvements Needed**: Auto-mode revision is excellent

### Finding 6: Complexity Thresholds Documented

**Current Thresholds** (expand.md:78-86):
```
Complex Phase:
- task_count > 5
- file_refs > 10
- keywords: consolidate, refactor, migrate
```

**Usage**:
- /expand: Determines if agent research needed
- /implement: Triggers expansion during execution

**Consistency**: ✅ Same thresholds used across commands

**Opportunity**: Make thresholds configurable (env vars or CLAUDE.md)

## Gaps and Optimization Opportunities

### Gap 1: No Post-Creation Evaluation

**Missing Component**: Automatic phase complexity evaluation after /plan

**Current State**:
```bash
# /plan command
1. Generate plan
2. Save to file
3. Return path
# END - No evaluation
```

**Desired State**:
```bash
# /plan command
1. Generate plan
2. Save to file (L0)
3. Evaluate each phase complexity
4. If any phase > threshold:
   - Automatically expand phase
   - Update structure level
   - Log expansion in plan history
5. Return final plan path (L0 or L1)
```

**Implementation Approach**:

Add to /plan command (after plan creation):

```bash
# After plan saved
plan_file="specs/plans/NNN_feature.md"

# Source complexity utilities
source .claude/lib/complexity-utils.sh

# Evaluate each phase
for phase_num in {1..${total_phases}}; do
  # Calculate complexity score
  complexity_score=$(calculate_phase_complexity "$phase_num" "$plan_file")

  if (( $(echo "$complexity_score > 8.0" | bc -l) )); then
    echo "Phase $phase_num complexity: $complexity_score (threshold: 8.0)"
    echo "Auto-expanding Phase $phase_num..."

    # Invoke /expand
    /expand phase "$plan_file" "$phase_num"

    # Update plan_file path if structure changed
    plan_base=$(basename "$plan_file" .md)
    if [[ -d "specs/plans/$plan_base" ]]; then
      plan_file="specs/plans/$plan_base/"
    fi
  fi
done

echo "Plan ready: $plan_file"
```

**Benefits**:
- Plan optimally structured before implementation
- No mid-implementation interruptions
- Seamless user experience

**Effort**: 2-3 hours (integrate complexity detection into /plan)

### Gap 2: No Complexity Threshold Configuration

**Current State**: Hardcoded threshold (8.0) in multiple places

**Locations**:
- expand.md: "Complex if: >5 tasks OR >10 files"
- implement.md: "complexity score > 8"
- revise.md: "threshold 8.0"

**Problem**: Users cannot adjust sensitivity

**Desired State**: Configurable thresholds in CLAUDE.md

**Implementation**:

**CLAUDE.md**:
```markdown
## Adaptive Planning Configuration
[Used by: /plan, /expand, /implement, /revise]

### Complexity Thresholds
- **Expansion Threshold**: 8.0 (phases with score > this auto-expand)
- **Task Count Threshold**: 5 (phases with > 5 tasks considered complex)
- **File Reference Threshold**: 10 (phases referencing > 10 files)
- **Replan Limit**: 2 (max replans per phase)
```

**Commands**:
```bash
# Read threshold from CLAUDE.md
EXPANSION_THRESHOLD=$(grep "Expansion Threshold" CLAUDE.md | grep -oE '[0-9.]+' | head -1)
EXPANSION_THRESHOLD=${EXPANSION_THRESHOLD:-8.0}  # Default if not found

# Use in complexity check
if (( $(echo "$complexity_score > $EXPANSION_THRESHOLD" | bc -l) )); then
  # Expand phase
fi
```

**Benefits**:
- Users tune sensitivity per project
- Different projects have different needs
- Centralized configuration

**Effort**: 1-2 hours (read thresholds from CLAUDE.md)

### Gap 3: No Expansion Preview

**Current State**: /expand immediately creates files

**Problem**: Users cannot preview expansion without committing

**Desired Feature**: `--dry-run` flag for /expand

**Implementation**:

```bash
/expand phase <plan> <phase-num> --dry-run

Output:
┌─────────────────────────────────────────────────────┐
│ Expansion Preview: Phase 3                          │
├─────────────────────────────────────────────────────┤
│ Complexity: 9.2 (threshold: 8.0)                    │
│ Tasks: 12 (threshold: 5)                            │
│ Files: 15 (threshold: 10)                           │
│ Agent Research: Yes (complex phase)                 │
│                                                     │
│ Files to Create:                                    │
│ - specs/plans/025_feature/ (directory)              │
│ - specs/plans/025_feature/025_feature.md (main)     │
│ - specs/plans/025_feature/phase_3_impl.md (expanded)│
│                                                     │
│ Estimated Lines: 450-600 (agent research)           │
│                                                     │
│ Structure Change: Level 0 → Level 1                 │
└─────────────────────────────────────────────────────┘

Run without --dry-run to execute expansion.
```

**Benefits**:
- User reviews impact before expansion
- Transparency in decision-making
- Confidence in adaptive system

**Effort**: 1 hour (add --dry-run flag, skip file writes)

### Gap 4: No Collapse Preview

**Current State**: /collapse immediately merges and deletes files

**Problem**: Users cannot preview collapse without committing

**Desired Feature**: `--dry-run` flag for /collapse

**Implementation**: Similar to expansion preview

**Benefits**: Same as expansion preview

**Effort**: 1 hour (add --dry-run flag, skip file operations)

### Optimization 1: Parallel Phase Evaluation

**Current State**: Sequential phase evaluation (if implemented)

**Opportunity**: Evaluate all phases in parallel

**Implementation**:

```bash
# After plan creation
# Launch parallel complexity evaluations

declare -A phase_complexities
for phase_num in {1..${total_phases}}; do
  (
    complexity=$(calculate_phase_complexity "$phase_num" "$plan_file")
    echo "$phase_num:$complexity"
  ) &
done

# Wait for all evaluations
wait

# Collect results
for result in $(jobs -p); do
  # Parse phase_num:complexity
  # Expand if needed
done
```

**Benefits**:
- Faster evaluation (parallel processing)
- Scales to plans with many phases

**Trade-off**: More complex code, marginal time savings

**Effort**: 2 hours

**Recommendation**: Defer - sequential is sufficient for most plans

### Optimization 2: Smart Re-Evaluation After Revision

**Current State**: /revise updates plan, no re-evaluation

**Opportunity**: Re-evaluate complexity after major revisions

**Scenario**:
```
User: /revise "Split Phase 3 into 3 smaller phases"
      ↓
Phase 3 (15 tasks, complexity 10.2) split into:
  - Phase 3 (5 tasks, complexity 3.8)
  - Phase 4 (5 tasks, complexity 3.5)
  - Phase 5 (5 tasks, complexity 4.1)
      ↓
[OPPORTUNITY] Phase 3 was expanded (L1), but now simple enough to collapse
      ↓
[AUTO] Suggest collapse: "Phase 3 complexity reduced. Collapse recommended."
```

**Implementation**:

Add to /revise (after revision applied):

```bash
# After revision
if [[ "$revision_type" == "split_phase" ]]; then
  # Re-evaluate affected phases
  for phase_num in $(affected_phases); do
    complexity=$(calculate_phase_complexity "$phase_num" "$plan_file")

    # Check if expanded phase now simple
    if is_expanded "$phase_num" && (( $(echo "$complexity < 6.0" | bc -l) )); then
      echo "Phase $phase_num complexity reduced to $complexity"
      echo "Consider collapsing: /collapse phase <plan> $phase_num"
    fi
  done
fi
```

**Benefits**:
- Plans stay optimally structured
- Avoid over-expansion
- User guidance on cleanup

**Effort**: 2 hours

**Recommendation**: Implement - adds intelligence to revision workflow

### Optimization 3: Expansion Recommendation in Plan Output

**Current State**: /plan returns path, user must know to check complexity

**Opportunity**: Display expansion recommendations in plan output

**Implementation**:

```bash
# /plan output
Plan created: specs/plans/046_oauth2_authentication.md
Phases: 6
Complexity: Medium

Phase Complexity Analysis:
  Phase 1: 2.1 (Low) ✓
  Phase 2: 4.5 (Medium) ✓
  Phase 3: 9.2 (High) ⚠ Expansion recommended
  Phase 4: 3.8 (Low) ✓
  Phase 5: 7.5 (Medium) ✓
  Phase 6: 2.3 (Low) ✓

Recommended Actions:
  /expand phase specs/plans/046_oauth2_authentication.md 3

Would you like to auto-expand Phase 3 now? (y/n):
```

**Benefits**:
- User awareness of complex phases
- Informed decision on expansion
- Interactive workflow

**Effort**: 1 hour

**Recommendation**: Implement - improves user experience

## Recommended Implementation Plan

### Phase 1: Post-Creation Evaluation (High Priority)

**Objective**: Enable automatic phase evaluation after plan creation

**Tasks**:
1. Integrate complexity-utils.sh into /plan command
2. Add phase-by-phase complexity evaluation loop
3. Auto-expand phases exceeding threshold
4. Log expansions in plan history
5. Test with complex plans (6+ phases, some with >10 tasks)

**Deliverable**: Plans auto-expand before user sees them

**Effort**: 2-3 hours

**Impact**: ✅✅✅ High - transforms user experience

### Phase 2: Configurable Thresholds (Medium Priority)

**Objective**: Make complexity thresholds user-configurable

**Tasks**:
1. Add "Adaptive Planning Configuration" section to CLAUDE.md template
2. Update commands to read thresholds from CLAUDE.md
3. Use fallback defaults if not found
4. Document configuration in command help

**Deliverable**: Users can tune expansion sensitivity

**Effort**: 1-2 hours

**Impact**: ✅✅ Medium - flexibility for diverse projects

### Phase 3: Expansion Recommendations (Medium Priority)

**Objective**: Show expansion recommendations in /plan output

**Tasks**:
1. Calculate complexity for all phases after plan creation
2. Display summary table with ✓/⚠ indicators
3. Show recommended /expand commands
4. Optionally prompt for interactive expansion

**Deliverable**: Users see which phases should be expanded

**Effort**: 1 hour

**Impact**: ✅✅ Medium - transparency and guidance

### Phase 4: Preview Flags (Low Priority)

**Objective**: Add --dry-run to /expand and /collapse

**Tasks**:
1. Add --dry-run flag parsing
2. Display preview without file operations
3. Show structure changes, files affected, estimated lines

**Deliverable**: Users can preview expansions/collapses

**Effort**: 2 hours (1 hour per command)

**Impact**: ✅ Low - nice-to-have, not critical

### Phase 5: Smart Re-Evaluation (Low Priority)

**Objective**: Re-evaluate complexity after major revisions

**Tasks**:
1. Add post-revision complexity check
2. Detect when expanded phases become simple
3. Suggest collapses when appropriate

**Deliverable**: Plans stay optimally structured

**Effort**: 2 hours

**Impact**: ✅ Low - optimization, not critical

## Performance Considerations

### Current Performance

**Plan Creation**: Fast (~5-10 seconds for 6-phase plan)

**Expansion** (with agent):
- Complex phase: 30-60 seconds (agent research + file write)
- Simple phase: 5-10 seconds (direct expansion)

**Complexity Evaluation**: Very fast (<1 second per phase)

### Impact of Post-Creation Evaluation

**Additional Time**:
- Complexity evaluation: <1 second (all phases)
- Expansion (if triggered): 30-60 seconds per complex phase

**Example**:
- Plan with 6 phases, 1 complex (Phase 3)
- Current: 10 sec /plan + [later] 60 sec expansion during /implement
- With auto-eval: 70 sec /plan (10 + 60)
- Net impact: Same total time, better user experience

**Recommendation**: Acceptable trade-off - seamless workflow worth extra seconds upfront

### Parallel Evaluation Benefit

**Sequential** (6 phases): 6 × 1 sec = 6 seconds
**Parallel** (6 phases): 1 second (all at once)

**Savings**: 5 seconds

**Recommendation**: Not worth complexity for 5-second savings

## Workflow Comparison

### Current Workflow

```
User: /plan "Feature X"
      ↓ [10 sec]
Plan Created (L0)
      ↓
User: /implement <plan>
      ↓ [Phase 1-2 complete]
/implement detects Phase 3 complexity
      ↓ [Pause]
Auto-expand Phase 3
      ↓ [60 sec restructuring]
Resume implementation
      ↓
[Continue...]
```

**User Experience**: Workflow interruption mid-implementation

### Optimized Workflow (Recommended)

```
User: /plan "Feature X"
      ↓ [10 sec]
Plan Created (L0)
      ↓ [Auto-evaluate]
Detect Phase 3 complexity
      ↓ [60 sec auto-expand]
Plan Ready (L1)
      ↓
User: /implement <plan>
      ↓
[Smooth implementation, no interruptions]
```

**User Experience**: Seamless, plan ready for implementation

## Standards Compliance

### CLAUDE.md Integration

Current standards references:
- ✅ Progressive plan structure documented
- ✅ Complexity thresholds mentioned
- ✅ Commands reference CLAUDE.md

**Recommended Addition**:
```markdown
## Adaptive Planning Configuration
[Used by: /plan, /expand, /implement, /revise]

### Complexity Thresholds
- **Expansion Threshold**: 8.0
- **Task Count Threshold**: 5
- **File Reference Threshold**: 10
- **Replan Limit**: 2

### Auto-Expansion
- **Enabled**: true (auto-expand after plan creation)
- **Preview Mode**: false (set true for --dry-run default)

### Collapse Detection
- **Threshold**: 6.0 (suggest collapse if complexity < this)
```

### Command Integration

All commands follow consistent patterns:
- ✅ Use parse-adaptive-plan.sh utilities
- ✅ Support progressive structures
- ✅ Update metadata consistently
- ✅ Create revision history

**No Changes Needed**: Standards compliance is excellent

## Summary

### Current State Assessment

**Infrastructure**: ✅✅✅ Excellent (9/10)
- Comprehensive /expand and /collapse commands
- Sophisticated adaptive planning in /implement
- Robust auto-mode /revise with 4 revision types
- Progressive structure fully supported
- Safety mechanisms in place

**Workflow**: ⚠ Good but incomplete (7/10)
- Expansion happens during implementation (reactive)
- Should happen after plan creation (proactive)
- Manual /expand invocation required
- Workflow interruption mid-implementation

### Recommended Improvements

**Priority 1: Post-Creation Evaluation** (2-3 hours)
- Add automatic phase complexity evaluation after /plan
- Auto-expand phases exceeding threshold
- Plan ready for implementation without interruptions

**Priority 2: Configurable Thresholds** (1-2 hours)
- Make thresholds user-configurable in CLAUDE.md
- Different projects have different needs

**Priority 3: Expansion Recommendations** (1 hour)
- Display which phases should be expanded
- Show recommended /expand commands
- Interactive option to expand immediately

**Total Effort**: 4-6 hours for all three priorities

### Expected Benefits

1. **Seamless Workflow**: Plans optimally structured before implementation
2. **No Interruptions**: Expansion happens upfront, not mid-implementation
3. **Better UX**: User sees plan ready for implementation
4. **Flexibility**: Configurable thresholds per project
5. **Transparency**: Users understand expansion decisions

### No Changes Needed

The following are excellent and require no modifications:
- ✅ /expand command (comprehensive, agent-integrated)
- ✅ /collapse command (safe, reversible)
- ✅ /implement proactive checks (intelligent, adaptive)
- ✅ /revise auto-mode (robust, deterministic)
- ✅ Progressive structure support (L0→L1→L2)

## References

### Command Documentation Analyzed

1. **expand.md** (352 lines) - Phase/stage expansion with agent integration
2. **collapse.md** (414 lines) - Phase/stage contraction with safety checks
3. **revise.md** (596 lines) - Interactive and automated plan revision
4. **implement.md** (excerpts) - Proactive expansion/collapse checks
5. **plan.md** (excerpts) - Plan creation process

### Utility Libraries

- `.claude/lib/complexity-utils.sh` - Phase complexity calculation
- `.claude/lib/parse-adaptive-plan.sh` - Plan structure parsing
- `.claude/lib/checkpoint-utils.sh` - Workflow state management

### Progressive Structure Levels

- **Level 0**: Single file (NNN_feature.md)
- **Level 1**: Phase expansion (NNN_feature/)
- **Level 2**: Stage expansion (NNN_feature/phase_N/)

### Complexity Thresholds

- Expansion threshold: 8.0 (score)
- Task count threshold: 5 tasks
- File reference threshold: 10 files
- Keywords: consolidate, refactor, migrate
