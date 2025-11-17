# Current Coordinate Command Architecture

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: Current Coordinate Command Architecture
- **Report Type**: codebase analysis
- **Complexity Level**: 3

## Executive Summary

The coordinate command implements a state-based orchestration architecture using a two-phase initialization pattern, workflow classification via AI agents, and selective file-based state persistence. Workflow determination is handled by a dedicated workflow-classifier agent that performs semantic analysis to classify workflows into 5 types (research-only, research-and-plan, research-and-revise, full-implementation, debug-only) with complexity scoring (1-4). State management uses a GitHub Actions-style pattern with state files persisted to .claude/tmp/, and cross-bash-block coordination is achieved through explicit state restoration at the beginning of each bash block.

## Findings

### 1. Workflow Detection and Classification Mechanism

**Primary Classification Method: Dedicated AI Agent**

The coordinate command uses a dedicated `workflow-classifier` agent for semantic workflow analysis rather than keyword matching (lines 194-213 in coordinate.md):

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Classify workflow intent for orchestration"
  model: "haiku"
  timeout: 30000
  prompt: "Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/workflow-classifier.md

    **Workflow-Specific Context**:
    - Workflow Description: $SAVED_WORKFLOW_DESC
    - Command Name: coordinate

    **CRITICAL**: Return structured JSON classification."
}
```

**Classification Output Structure** (workflow-classifier.md:220-241):

The classifier returns a JSON object with:
- `workflow_type`: One of 5 enumerated types (research-only, research-and-plan, research-and-revise, full-implementation, debug-only)
- `confidence`: Float 0.0-1.0 indicating classification certainty
- `research_complexity`: Integer 1-4 indicating research scope and topic count
- `research_topics`: Array of topic objects with `short_name`, `detailed_description`, `filename_slug`, and `research_focus`
- `reasoning`: Brief explanation of classification decision (1-3 sentences)

**Semantic Analysis Rules** (workflow-classifier.md:90-109):

The classifier performs semantic intent analysis with explicit edge case handling:
1. **Quoted keywords indicate topic, not intent**: "research the 'implement' command" → research-only (not full-implementation)
2. **Negations are respected**: "don't revise, create new plan" → research-and-plan (not research-and-revise)
3. **Primary intent determines classification**: Multiple phases mentioned → highest scope wins
4. **Context matters over keywords**: Analyzes user's actual goal, not just presence of action verbs

**Critical Validation**: Topic count MUST exactly match research_complexity score (classifier enforces this at lines 196-200).

### 2. State Management and Persistence Architecture

**State Persistence Pattern: GitHub Actions Style** (state-persistence.sh:1-77)

The coordinate command uses file-based state persistence following the GitHub Actions pattern:
- State files stored in `.claude/tmp/workflow_{workflow_id}.sh`
- Each state file contains bash export statements: `export KEY="value"`
- State loaded by sourcing the file in subsequent bash blocks
- EXIT trap ensures cleanup on workflow termination

**State Initialization** (coordinate.md:46-186):

Two-step initialization pattern to avoid positional parameter issues:
1. **Part 1** (lines 17-42): Capture workflow description to temp file
2. **Part 2** (lines 46-186): Main initialization logic reads description and initializes state machine

**Critical State Variables** (workflow-state-machine.sh:388-508):

The state machine exports and persists 5 core variables:
- `WORKFLOW_SCOPE`: Workflow type (same as workflow_type from classification)
- `RESEARCH_COMPLEXITY`: Research depth (1-4)
- `RESEARCH_TOPICS_JSON`: JSON array of research topics
- `TERMINAL_STATE`: Terminal state for this workflow (computed from workflow_type)
- `CURRENT_STATE`: Current state (initialized to "initialize")

**State Restoration Pattern** (coordinate.md:220-259):

Each bash block follows explicit state restoration:
```bash
# Load state ID file
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")

# Restore workflow state
load_workflow_state "$WORKFLOW_ID"
```

**Verification Checkpoints** (coordinate.md:140-180):

State persistence is validated at critical points using verification functions:
- `verify_file_created()`: Ensures files exist at expected paths
- `verify_state_variable()`: Ensures variables persisted to state file
- `verify_state_variables()`: Batch verification of multiple variables

**Fail-Fast Validation** (coordinate.md:261-293):

The command uses fail-fast validation with diagnostic messages when state loading fails:
- Missing classification JSON triggers detailed error with troubleshooting steps
- Invalid JSON triggers immediate failure with content diagnostic
- Missing required fields trigger explicit error messages

### 3. State Machine Architecture and Transitions

**8 Core Workflow States** (workflow-state-machine.sh:33-44):

Explicit state enumeration replaces implicit phase numbers:
- `initialize`: Setup, scope detection, path pre-calculation
- `research`: Research topic via specialist agents
- `plan`: Create implementation plan
- `implement`: Execute implementation
- `test`: Run test suite
- `debug`: Debug failures (conditional)
- `document`: Update documentation (conditional)
- `complete`: Finalization, cleanup

**State Transition Table** (workflow-state-machine.sh:50-60):

Valid transitions defined as comma-separated lists:
```bash
declare -gA STATE_TRANSITIONS=(
  [initialize]="research"
  [research]="plan,complete"        # Can skip to complete for research-only
  [plan]="implement,complete"       # Can skip to complete for research-and-plan
  [implement]="test"
  [test]="debug,document"           # Conditional: debug if failed, document if passed
  [debug]="test,complete"           # Retry testing or complete if unfixable
  [document]="complete"
  [complete]=""                     # Terminal state
)
```

**Terminal State Mapping** (workflow-state-machine.sh:463-483):

Workflow scope determines terminal state:
- research-only → terminate at `research` state
- research-and-plan → terminate at `plan` state
- research-and-revise → terminate at `plan` state
- full-implementation → terminate at `complete` state
- debug-only → terminate at `debug` state

**State Transition Validation** (workflow-state-machine.sh:599-647):

The `sm_transition()` function enforces valid transitions:
1. Validate next_state is in valid_transitions list
2. Save pre-transition checkpoint
3. Update CURRENT_STATE
4. Add to COMPLETED_STATES history (avoiding duplicates)
5. Save post-transition checkpoint
6. Persist COMPLETED_STATES array to state file

### 4. Cross-Bash-Block Coordination and Subprocess Isolation

**Subprocess Isolation Challenge** (coordinate.md:220-233):

Each bash block executes in separate subprocess with its own PID:
- Environment variables do NOT persist across bash blocks
- File-based persistence enables cross-block communication
- State must be restored at the beginning of EACH bash block

**State Restoration Pattern** (coordinate.md:586-608):

Standard 15 library sourcing order:
1. Source state machine and persistence libraries FIRST
2. Load workflow state BEFORE other libraries (prevents WORKFLOW_SCOPE reset)
3. Source error handling and verification libraries
4. Source additional libraries

**Performance Instrumentation** (coordinate.md:54-567):

Performance metrics span multiple bash blocks:
- `PERF_START_TOTAL`: Start time persisted in initialization
- `PERF_AFTER_LIBS`: Library loading complete timestamp
- `PERF_AFTER_PATHS`: Path initialization complete timestamp
- `PERF_END_INIT`: Initialization complete timestamp
- All metrics persisted to state file for cross-block access

**Array Persistence** (workflow-state-machine.sh:88-212):

COMPLETED_STATES array persisted using JSON serialization:
```bash
save_completed_states_to_state() {
  # Serialize array to JSON
  completed_states_json=$(printf '%s\n' "${COMPLETED_STATES[@]}" | jq -R . | jq -s .)

  # Save to workflow state
  append_workflow_state "COMPLETED_STATES_JSON" "$completed_states_json"
  append_workflow_state "COMPLETED_STATES_COUNT" "${#COMPLETED_STATES[@]}"
}
```

Load function reconstructs array from JSON using `mapfile -t COMPLETED_STATES`.

### 5. Research Phase Execution Strategy

**Hierarchical vs Flat Coordination** (coordinate.md:677-691):

Research complexity determines coordination strategy:
- **Complexity ≥ 4**: Hierarchical supervision via research-sub-supervisor agent (95.6% context reduction)
- **Complexity < 4**: Flat coordination with direct parallel agent invocation

**Conditional Agent Invocation** (coordinate.md:728-799):

Explicit conditional guards control agent count:
```markdown
**IF RESEARCH_COMPLEXITY >= 1** (always true):
Task { ... research Topic 1 ... }

**IF RESEARCH_COMPLEXITY >= 2**:
Task { ... research Topic 2 ... }

**IF RESEARCH_COMPLEXITY >= 3**:
Task { ... research Topic 3 ... }

**IF RESEARCH_COMPLEXITY >= 4**:
Task { ... research Topic 4 ... }
```

**Report Path Pre-Allocation** (coordinate.md:473-484):

Report paths allocated dynamically based on research complexity:
- `REPORT_PATHS_COUNT` set to match `RESEARCH_COMPLEXITY`
- Individual variables created: `REPORT_PATH_0`, `REPORT_PATH_1`, etc.
- Each variable persisted to state file for cross-bash-block access

**Research Topic Extraction** (coordinate.md:742-762):

Topics reconstructed from JSON state using `mapfile`:
```bash
mapfile -t RESEARCH_TOPICS < <(echo "$RESEARCH_TOPICS_JSON" | jq -r '.[]')
```

Descriptive topic names from classification replace generic "Topic N" labels.

### 6. Library Sourcing and Dependency Management

**Scope-Based Library Loading** (coordinate.md:400-422):

Different workflow scopes require different library sets:
- **research-only**: 7 libraries (basic orchestration)
- **research-and-plan/research-and-revise**: 9 libraries (adds planning support)
- **full-implementation**: 11 libraries (adds implementation and context pruning)
- **debug-only**: 9 libraries (adds debugging support)

**Library Sourcing Function** (coordinate.md:416-422):

Uses `source_required_libraries()` with fail-fast error handling:
```bash
if source_required_libraries "${REQUIRED_LIBS[@]}"; then
  : # Success - libraries loaded
else
  echo "ERROR: Failed to source required libraries"
  exit 1
fi
```

**Standard 15 Enforcement** (coordinate.md:594-615):

Strict library sourcing order prevents variable overwrites:
1. State machine and persistence libraries first (needed for load_workflow_state)
2. Load workflow state before other libraries (prevents WORKFLOW_SCOPE reset)
3. Error handling and verification libraries
4. Additional domain-specific libraries

## Recommendations

### 1. Centralize Classification State Persistence

**Current Issue**: Classification JSON is saved to state by the workflow-classifier agent (workflow-classifier.md:531-586), but this creates tight coupling between agent and coordinate command.

**Recommendation**: Move classification state persistence into coordinate.md immediately after Task invocation:
```bash
# After workflow-classifier Task completes
CLASSIFICATION_JSON=$(cat "${HOME}/.claude/tmp/llm_response_${WORKFLOW_ID}.json")
append_workflow_state "CLASSIFICATION_JSON" "$CLASSIFICATION_JSON"
```

**Benefits**:
- Reduces agent behavioral file complexity
- Makes state persistence explicit in orchestrator
- Easier to debug state loading failures

### 2. Add State Machine Status Checkpoint

**Current Gap**: State machine transitions are logged but not validated between bash blocks. If a bash block fails mid-transition, state could be inconsistent.

**Recommendation**: Add `sm_print_status()` call after each state restoration:
```bash
load_workflow_state "$WORKFLOW_ID"
sm_print_status  # Validates state machine consistency
```

**Benefits**:
- Early detection of state inconsistencies
- Clear diagnostic output for debugging
- Validates transition table integrity

### 3. Document Workflow Scope to Terminal State Mapping

**Current Gap**: The mapping from workflow scope to terminal state is scattered across workflow-state-machine.sh (lines 463-483) and not documented in coordinate-command-guide.md.

**Recommendation**: Create a decision matrix table in coordinate-command-guide.md:

| Workflow Scope | Terminal State | Phases Executed |
|---------------|---------------|-----------------|
| research-only | research | initialize → research |
| research-and-plan | plan | initialize → research → plan |
| research-and-revise | plan | initialize → research → plan (with existing plan context) |
| full-implementation | complete | initialize → research → plan → implement → test → debug/document → complete |
| debug-only | debug | initialize → debug |

**Benefits**:
- Clearer workflow expectations for users
- Easier troubleshooting of early termination
- Better understanding of scope implications

### 4. Add Complexity Threshold Configuration

**Current Observation**: Hierarchical supervision threshold is hardcoded at 4 topics (coordinate.md:678).

**Recommendation**: Make threshold configurable via environment variable:
```bash
HIERARCHICAL_THRESHOLD="${COORDINATE_HIERARCHICAL_THRESHOLD:-4}"
USE_HIERARCHICAL_RESEARCH=$([ $RESEARCH_COMPLEXITY -ge $HIERARCHICAL_THRESHOLD ] && echo "true" || echo "false")
```

**Benefits**:
- Allows experimentation with different thresholds
- Supports project-specific optimization
- Easier to adjust based on performance metrics

### 5. Strengthen Array Persistence Validation

**Current Gap**: COMPLETED_STATES array persistence has optional validation (count mismatch triggers warning but doesn't fail).

**Recommendation**: Upgrade validation to fail-fast:
```bash
if [ "${#COMPLETED_STATES[@]}" -ne "$COMPLETED_STATES_COUNT" ]; then
  handle_state_error "CRITICAL: COMPLETED_STATES count mismatch (expected $COMPLETED_STATES_COUNT, got ${#COMPLETED_STATES[@]})" 1
fi
```

**Benefits**:
- Prevents silent state corruption
- Catches serialization bugs early
- Maintains state integrity guarantees

## References

### Command Files
- /home/benjamin/.config/.claude/commands/coordinate.md:0-799 - Main coordinate command implementation
- /home/benjamin/.config/.claude/commands/coordinate.md:17-42 - Part 1: Workflow description capture
- /home/benjamin/.config/.claude/commands/coordinate.md:46-186 - Part 2: State machine initialization
- /home/benjamin/.config/.claude/commands/coordinate.md:194-213 - Workflow classification agent invocation
- /home/benjamin/.config/.claude/commands/coordinate.md:220-259 - State restoration pattern
- /home/benjamin/.config/.claude/commands/coordinate.md:400-422 - Scope-based library loading
- /home/benjamin/.config/.claude/commands/coordinate.md:576-799 - Research phase execution

### Library Files
- /home/benjamin/.config/.claude/lib/workflow-state-machine.sh:1-906 - State machine library
- /home/benjamin/.config/.claude/lib/workflow-state-machine.sh:33-44 - 8 core workflow states
- /home/benjamin/.config/.claude/lib/workflow-state-machine.sh:50-60 - State transition table
- /home/benjamin/.config/.claude/lib/workflow-state-machine.sh:88-212 - Array persistence functions
- /home/benjamin/.config/.claude/lib/workflow-state-machine.sh:334-508 - sm_init function
- /home/benjamin/.config/.claude/lib/workflow-state-machine.sh:599-647 - sm_transition function
- /home/benjamin/.config/.claude/lib/state-persistence.sh:0-199 - State persistence library
- /home/benjamin/.config/.claude/lib/state-persistence.sh:116-143 - init_workflow_state function
- /home/benjamin/.config/.claude/lib/state-persistence.sh:186-199 - load_workflow_state function

### Agent Files
- /home/benjamin/.config/.claude/agents/workflow-classifier.md:1-587 - Workflow classifier agent
- /home/benjamin/.config/.claude/agents/workflow-classifier.md:44-109 - Semantic classification rules
- /home/benjamin/.config/.claude/agents/workflow-classifier.md:220-241 - Classification output format
- /home/benjamin/.config/.claude/agents/workflow-classifier.md:531-586 - State persistence instructions

### Documentation Files
- /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md:0-149 - State-based orchestration overview
- /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md:23-65 - Architecture achievements and metrics
