# Distinct Workflows in Coordinate Research Report

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: Distinct workflows in coordinate command
- **Report Type**: codebase analysis
- **Complexity Level**: 3

## Executive Summary

The coordinate command implements a state machine architecture supporting 5 distinct workflow types (research-only, research-and-plan, research-and-revise, full-implementation, debug-only) with dynamic path selection based on workflow scope. Each workflow type has specific inputs (workflow description + LLM classification), outputs (research reports, plans, implementation artifacts), state transitions, and termination conditions. Research phase uses complexity-based coordination (hierarchical for ≥4 topics, flat for <4), while planning phase branches on workflow scope for plan creation vs revision.

## Findings

### 1. Workflow Classification System

**Location**: `/home/benjamin/.config/.claude/commands/coordinate.md:191-318`, `/home/benjamin/.config/.claude/agents/workflow-classifier.md:1-587`

The coordinate command begins with a **workflow classification phase** (Phase 0.1) that uses LLM-based semantic analysis to determine:

1. **Workflow Type** (5 types):
   - `research-only`: Information gathering without plan/implementation
   - `research-and-plan`: Research + new plan creation (no implementation)
   - `research-and-revise`: Research + existing plan revision
   - `full-implementation`: Complete cycle (research → plan → implement → test → debug → document)
   - `debug-only`: Root cause analysis and bug fixing

2. **Research Complexity** (1-4 scale):
   - Determines number of research topics
   - Controls coordination strategy (hierarchical vs flat)
   - Affects resource allocation (report paths, agent count)

3. **Research Topics** (structured JSON):
   - Topic count matches complexity exactly
   - Each topic has: short_name, detailed_description, filename_slug, research_focus
   - Topics generated via semantic analysis of workflow description

**Classification Invocation** (`coordinate.md:194-212`):
- Uses Task tool to invoke `workflow-classifier.md` agent
- Model: Haiku (fast semantic classification, <5s response)
- Output: JSON saved to workflow state via `append_workflow_state`
- Critical dependency: Next bash block requires `CLASSIFICATION_JSON` in state

**State Machine Initialization** (`coordinate.md:319-395`):
- Parses classification JSON to extract workflow_type, research_complexity, research_topics
- Calls `sm_init()` with 5 parameters: description, command name, workflow type, complexity, topics JSON
- Sets WORKFLOW_SCOPE (maps workflow_type to scope enum)
- Configures TERMINAL_STATE (determines when workflow completes)
- Exports environment variables and persists to state file

### 2. Five Workflow Types: Inputs, Outputs, and Transitions

#### Workflow Type 1: research-only

**Inputs**:
- Workflow description (natural language)
- Research complexity (1-4, from LLM classification)
- Research topics (JSON array from classification)

**Processing**:
- State sequence: `initialize → research → complete`
- Research coordination: Hierarchical (≥4 topics) or flat (<4 topics)
- Agent invocations: research-specialist agents (1-4 workers)

**Outputs**:
- Research reports: 1-4 markdown files at `$TOPIC_PATH/reports/NNN_topic_slug.md`
- OVERVIEW.md: Synthesized summary of all reports (if hierarchical)
- No plan file created
- No implementation artifacts

**Termination** (`coordinate.md:1164-1171`):
- Terminal state: `complete`
- Exit after research phase
- Display brief summary
- Clean up temp files

**State Transitions** (`coordinate.md:1163-1184`):
```bash
case "$WORKFLOW_SCOPE" in
  research-only)
    sm_transition "$STATE_COMPLETE"
    display_brief_summary
    exit 0
    ;;
esac
```

#### Workflow Type 2: research-and-plan

**Inputs**:
- Same as research-only (description, complexity, topics)
- No existing plan path required

**Processing**:
- State sequence: `initialize → research → plan → complete`
- Research phase: Same as research-only
- Planning phase: Task invokes `plan-architect.md` agent to create NEW plan

**Outputs**:
- Research reports: 1-4 markdown files
- Plan file: `$PLAN_PATH` (new plan at `$TOPIC_PATH/plans/001_plan_name.md`)
- No implementation artifacts

**Termination** (`coordinate.md:1644-1652`):
- Terminal state: `complete` (after plan phase)
- Exit after planning phase
- Display brief summary

**State Transitions** (`coordinate.md:1173-1184`, `1644-1672`):
```bash
# After research:
research-and-plan) sm_transition "$STATE_PLAN" ;;

# After planning:
research-and-plan) sm_transition "$STATE_COMPLETE"; exit 0 ;;
```

#### Workflow Type 3: research-and-revise

**Inputs**:
- Workflow description (MUST contain existing plan path)
- Research complexity (1-4)
- Research topics
- **CRITICAL**: Existing plan path extracted from description (coordinate.md:365-380)

**Processing**:
- State sequence: `initialize → research → plan → complete`
- Research phase: Same as other workflows
- Planning phase: Task invokes `plan-architect.md` agent with `EXISTING_PLAN_PATH` to REVISE plan (not create new)

**Outputs**:
- Research reports: 1-4 markdown files
- Backup plan: Original plan backed up to `$TOPIC_PATH/plans/backups/`
- Revised plan: Updated plan at `$EXISTING_PLAN_PATH`
- No implementation artifacts

**Special Handling** (`coordinate.md:1323-1371`):
```bash
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
  # Verify EXISTING_PLAN_PATH loaded
  # Task invokes plan-architect with revision mode
fi
```

**Termination**:
- Same as research-and-plan (terminal state after planning)

**State Transitions**:
- Same as research-and-plan

#### Workflow Type 4: full-implementation

**Inputs**:
- Workflow description
- Research complexity
- Research topics
- No plan path (will be created)

**Processing**:
- State sequence: `initialize → research → plan → implement → test → (debug if failures) → (document if tests pass) → complete`
- All phases executed in order
- Implementation phase: Uses implementer-coordinator agent
- Testing phase: Runs comprehensive test suite
- Conditional phases: debug (on test failures), document (on test success)

**Outputs**:
- Research reports: 1-4 markdown files
- Plan file: `$PLAN_PATH` (implementation plan)
- Implementation artifacts: Code changes, commits (via implementer-coordinator)
- Test results: Test execution logs
- Documentation updates: (if document phase runs)

**Termination**:
- Terminal state: `complete` (after all phases)
- Exit after document phase OR debug phase (if unfixable)

**State Transitions** (`coordinate.md:1654-1672`):
```bash
# After planning:
full-implementation) sm_transition "$STATE_IMPLEMENT" ;;

# After implementation:
sm_transition "$STATE_TEST"

# After testing (conditional):
if tests_passed; then
  sm_transition "$STATE_DOCUMENT"
else
  sm_transition "$STATE_DEBUG"
fi

# After debug (conditional):
if can_retry; then
  sm_transition "$STATE_TEST"  # Retry
else
  sm_transition "$STATE_COMPLETE"  # Give up
fi

# After document:
sm_transition "$STATE_COMPLETE"
```

#### Workflow Type 5: debug-only

**Inputs**:
- Workflow description (describes bug to fix)
- Research complexity (for root cause analysis)
- Research topics (focused on debugging)

**Processing**:
- State sequence: `initialize → research → plan → debug → complete`
- Research phase: Investigate bug patterns, error logs
- Planning phase: Create debug strategy plan
- Debug phase: Execute debug plan (skip implement/test)

**Outputs**:
- Research reports: Debug-focused analysis
- Debug plan: Strategy for fixing bug
- Debug artifacts: Root cause analysis, fix attempts

**Termination**:
- Terminal state: `complete` (after debug phase)

**State Transitions** (`coordinate.md:1661-1667`):
```bash
# After planning:
debug-only) sm_transition "$STATE_DEBUG" ;;

# After debug:
sm_transition "$STATE_COMPLETE"
```

### 3. Research Phase: Hierarchical vs Flat Coordination

**Coordination Strategy Selection** (`coordinate.md:677-689`):
```bash
USE_HIERARCHICAL_RESEARCH=$([ $RESEARCH_COMPLEXITY -ge 4 ] && echo "true" || echo "false")
```

**Hierarchical Coordination** (Complexity ≥4):
- **Agent**: research-sub-supervisor.md
- **Pattern**: Supervisor coordinates 4+ research-specialist workers in parallel
- **Context Reduction**: 95.6% (supervisor aggregates metadata, not full reports)
- **Output**: OVERVIEW.md synthesized from all worker reports
- **Invocation** (`coordinate.md:698-723`): Single Task to supervisor, supervisor spawns workers

**Flat Coordination** (Complexity <4):
- **Agent**: research-specialist.md (invoked directly, 1-3 times)
- **Pattern**: Sequential or parallel invocations of research-specialist
- **No Supervisor**: Orchestrator directly manages workers
- **Output**: Individual reports (no OVERVIEW.md synthesis)
- **Invocation** (`coordinate.md:724-846`): Multiple Tasks to research-specialist agents

**Decision Rationale** (from state-based-orchestration-overview.md:520-618):
- Context window limits: 4+ workers × 2,500 tokens = 10,000+ tokens (risks overflow)
- Hierarchical supervision reduces context to 440 tokens (95.6% reduction)
- Flat coordination acceptable for <4 workers (manageable context)

### 4. Planning Phase: Branching on Workflow Scope

**Planning Agent**: `plan-architect.md`

**Branch 1: New Plan Creation** (research-and-plan, full-implementation, debug-only):
- Task invocation (`coordinate.md:1373-1418`): Standard plan-architect call
- Input: Research reports (REPORT_PATHS_JSON)
- Output: New plan file at `$PLAN_PATH`
- No backup required (no existing plan)

**Branch 2: Plan Revision** (research-and-revise):
- Task invocation (`coordinate.md:1344-1371`): plan-architect with EXISTING_PLAN_PATH
- Input: Research reports + existing plan path
- Output: Revised plan at `$EXISTING_PLAN_PATH` + backup at `$TOPIC_PATH/plans/backups/`
- Requires plan path in workflow description

**Verification Logic** (`coordinate.md:1450-1599`):
```bash
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
  VERIFY_PATH="$EXISTING_PLAN_PATH"  # Verify revised plan
else
  VERIFY_PATH="$PLAN_PATH"  # Verify new plan
fi

verify_file_created "$VERIFY_PATH" "Plan file" "Planning" || {
  handle_state_error "Plan file not created" 1
}
```

### 5. State Machine Architecture

**State Enumeration** (`workflow-state-machine.sh:34-43`):
```bash
STATE_INITIALIZE="initialize"
STATE_RESEARCH="research"
STATE_PLAN="plan"
STATE_IMPLEMENT="implement"
STATE_TEST="test"
STATE_DEBUG="debug"
STATE_DOCUMENT="document"
STATE_COMPLETE="complete"
```

**Transition Table** (`workflow-state-machine.sh:50-59`):
```bash
declare -gA STATE_TRANSITIONS=(
  [initialize]="research"
  [research]="plan,complete"        # research-only can skip to complete
  [plan]="implement,complete"       # research-and-plan can skip to complete
  [implement]="test"
  [test]="debug,document"           # Conditional based on test results
  [debug]="test,complete"           # Retry or give up
  [document]="complete"
  [complete]=""                     # Terminal state
)
```

**Scope-to-Terminal-State Mapping**:
- `research-only` → terminal at `research` (skip plan)
- `research-and-plan` → terminal at `plan` (skip implement)
- `research-and-revise` → terminal at `plan` (skip implement)
- `full-implementation` → terminal at `complete` (all phases)
- `debug-only` → terminal at `debug` (skip implement/test)

**Transition Validation** (`workflow-state-machine.sh:223-237`):
- sm_transition() validates against STATE_TRANSITIONS table
- Rejects invalid transitions (e.g., initialize → implement)
- Atomic checkpoint save with state update

### 6. Cross-Workflow Data Flow

**Workflow State Persistence** (GitHub Actions pattern):
- State file: `~/.claude/tmp/workflow_${WORKFLOW_ID}.sh`
- Variables persisted across bash blocks: WORKFLOW_SCOPE, TERMINAL_STATE, CURRENT_STATE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON, REPORT_PATHS_JSON, PLAN_PATH, EXISTING_PLAN_PATH (if applicable)
- Load pattern: `load_workflow_state "$WORKFLOW_ID"` at start of each bash block

**Report Path Serialization** (`coordinate.md:473-490`):
- Array exported to indexed variables: REPORT_PATH_0, REPORT_PATH_1, etc.
- Count saved: REPORT_PATHS_COUNT
- Reconstruction in next block: Loop over count, eval indexed variables

**Classification Result Flow**:
1. workflow-classifier agent generates JSON
2. Agent saves to state: `append_workflow_state "CLASSIFICATION_JSON" "$json"`
3. Coordinate loads from state: `CLASSIFICATION_JSON="${CLASSIFICATION_JSON}"`
4. Parse with jq: `WORKFLOW_TYPE=$(echo "$CLASSIFICATION_JSON" | jq -r '.workflow_type')`

## Recommendations

### 1. Workflow Type Documentation Matrix

Create a decision matrix table in coordinate-command-guide.md showing:
- User intent → Workflow type mapping
- Example commands for each type
- Expected outputs per type
- State transition diagram per type

**Benefit**: Users can quickly identify which workflow type matches their intent without reading agent behavioral files.

**Implementation**: Add table to coordinate-command-guide.md Section 2 (Usage Patterns), using the 5 workflow types as rows and inputs/outputs/transitions as columns.

### 2. Explicit Workflow Type Validation

Add validation checkpoint after classification to verify workflow type is one of the 5 supported types. Current code assumes LLM returns valid type but doesn't enforce.

**Location**: `coordinate.md:296-310` (after parsing WORKFLOW_TYPE from JSON)

**Pattern**:
```bash
VALID_TYPES="research-only|research-and-plan|research-and-revise|full-implementation|debug-only"
if ! echo "$WORKFLOW_TYPE" | grep -Eq "^($VALID_TYPES)$"; then
  handle_state_error "Invalid workflow type from classifier: $WORKFLOW_TYPE
  Valid types: $VALID_TYPES" 1
fi
```

**Benefit**: Fail-fast on LLM hallucinations or classifier bugs, preventing undefined behavior in downstream phases.

### 3. Hierarchical Threshold Configuration

Extract hardcoded hierarchical threshold (≥4) to configuration variable for easier tuning.

**Current**: `USE_HIERARCHICAL_RESEARCH=$([ $RESEARCH_COMPLEXITY -ge 4 ] && echo "true" || echo "false")`

**Proposed**:
```bash
HIERARCHICAL_RESEARCH_THRESHOLD="${HIERARCHICAL_RESEARCH_THRESHOLD:-4}"
USE_HIERARCHICAL_RESEARCH=$([ $RESEARCH_COMPLEXITY -ge $HIERARCHICAL_RESEARCH_THRESHOLD ] && echo "true" || echo "false")
```

**Benefit**: Allows experimentation with threshold (e.g., ≥3 for smaller projects) without code changes. Can be set via environment variable or CLAUDE.md configuration.

### 4. Workflow Scope Transition Guard

Add defensive check before each state transition to ensure transition is valid for current workflow scope.

**Example** (before `sm_transition "$STATE_IMPLEMENT"`):
```bash
if [ "$WORKFLOW_SCOPE" = "research-only" ] || [ "$WORKFLOW_SCOPE" = "research-and-plan" ]; then
  handle_state_error "BUG: Attempting to transition to implement in $WORKFLOW_SCOPE workflow" 1
fi
```

**Benefit**: Catches logic bugs where workflow scope checks are missed, preventing invalid state transitions.

### 5. Research Coordination Mode Logging

Add explicit logging of which coordination mode (hierarchical vs flat) was selected and why.

**Location**: After `USE_HIERARCHICAL_RESEARCH` calculation (coordinate.md:677-689)

**Pattern**:
```bash
echo "Research coordination mode selected: $([ "$USE_HIERARCHICAL_RESEARCH" = "true" ] && echo "Hierarchical" || echo "Flat")"
echo "  Reason: Research complexity is $RESEARCH_COMPLEXITY (threshold: ≥4 for hierarchical)"
echo "  Context reduction: $([ "$USE_HIERARCHICAL_RESEARCH" = "true" ] && echo "95.6% via supervisor" || echo "N/A (direct agent invocation)")"
```

**Benefit**: Makes workflow execution more transparent, helps users understand why their workflow uses hierarchical vs flat coordination.

## References

### Codebase Files Analyzed

- `/home/benjamin/.config/.claude/commands/coordinate.md:1-2500` - Main coordinate command implementation
- `/home/benjamin/.config/.claude/agents/workflow-classifier.md:1-587` - LLM-based workflow classification agent
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh:1-300` - State machine library with state enumeration and transitions
- `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh:1-182` - Workflow scope detection and classification
- `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md:1-1750` - State-based orchestration architecture documentation

### Key Line References

- Workflow classification invocation: `coordinate.md:194-212`
- State machine initialization: `coordinate.md:319-395`
- Hierarchical threshold decision: `coordinate.md:677-689`
- Research-only termination: `coordinate.md:1164-1171`
- Research-and-plan termination: `coordinate.md:1644-1652`
- Research-and-revise special handling: `coordinate.md:1323-1371`
- Full-implementation state sequence: `coordinate.md:1654-1672`
- Debug-only state transitions: `coordinate.md:1661-1667`
- State transition table: `workflow-state-machine.sh:50-59`
- Scope detection modes: `workflow-scope-detection.sh:28-84`
