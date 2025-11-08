# State-Based Orchestrator Refactor: Elegant State Management Throughout

## Metadata
- **Date**: 2025-11-07
- **Feature**: State-Based Orchestrator Architecture Refactor
- **Scope**: Refactor .claude/ orchestration system to use elegant state-based patterns, reducing needless complexity while maintaining robust performance
- **Estimated Phases**: 7 phases
- **Estimated Hours**: 85-125 hours over 8-12 weeks
- **Structure Level**: 0
- **Complexity Score**: 89.5 (High - comprehensive architectural refactor with state machine introduction)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Existing Plan Analysis](/home/benjamin/.config/.claude/specs/602_601_and_documentation_in_claude_docs_in_order_to/reports/001_existing_plan_analysis.md)
  - [State Management Synthesis](/home/benjamin/.config/.claude/specs/602_601_and_documentation_in_claude_docs_in_order_to/reports/002_state_management_synthesis.md)
  - [Implementation Review and Opportunities](/home/benjamin/.config/.claude/specs/602_601_and_documentation_in_claude_docs_in_order_to/reports/003_implementation_review_and_opportunities.md)

## Executive Summary

This plan refactors the .claude/ orchestration system to incorporate elegant state-based design patterns throughout, building on the hybrid orchestrator architecture goals (plan 003) while addressing fundamental state management issues identified in research. The refactor introduces a formal state machine abstraction, selective file-based state persistence following industry patterns (GitHub Actions), and unified checkpoint schema to eliminate needless complexity while providing robust, high-quality performance.

**Key Innovation**: Replace implicit phase-based state tracking with explicit state machine, adopt selective file-based state (not blanket stateless recalculation), and consolidate 3,420 lines of duplicated orchestration logic into 40% less code through state-driven architecture.

**Critical Findings from Research**:
- **Plan 003 gaps**: State management design lacks specificity, checkpoint schema undefined, hierarchical coordination patterns incomplete
- **State Management Reality**: File-based state is 5x faster than recalculation for expensive operations (30ms vs 150ms), industry standard (GitHub Actions, kubectl, Docker, Terraform), and enables 3 of 5 plan phases that are impossible with stateless recalculation
- **Architecture Opportunity**: Three orchestration commands (3,420 lines) implement same state machine with duplicated logic - 40% reduction possible through state machine abstraction

**Approach**:
1. **State Machine Foundation** (Phases 1-2): Create formal state machine library with explicit states, transitions, validation
2. **Selective State Persistence** (Phase 3): Implement GitHub Actions-style file-based state for 7 critical items (67% of analyzed state needs)
3. **Checkpoint Schema Formalization** (Phase 4): Define v2.0 schema with state machine state as first-class citizen
4. **Orchestrator Migration** (Phase 5): Migrate /coordinate, /orchestrate, /supervise to use state machine
5. **Hierarchical Supervision** (Phase 6): Implement state-aware supervisors with proper checkpoint coordination
6. **Performance Validation** (Phase 7): Verify 40-60% time savings, <30% context usage, 100% reliability

**Success Criteria**: 40% code reduction across orchestrators, 5x faster state operations for expensive calculations, 95% context reduction through hierarchical supervision, 100% file creation reliability maintained, zero regressions on existing workflows.

## Research Summary

### From Existing Plan Analysis (Report 001)

**Plan 003 Goals**:
- Extensibility: Rapid orchestrator creation (hours vs days)
- Scalability: 8-16+ agents via hierarchical supervision
- Maintainability: Enhanced existing libraries
- Reusability: Many specialized subagents coordinated by many orchestrators

**Identified Gaps in Plan 003**:
1. **Gap 1 - State Management Design Lacks Specificity**: Checkpoint schema for hierarchical workflows undefined, state transitions not enforced, failure recovery patterns missing
2. **Gap 2 - Hierarchical Supervisor Coordination Patterns Undefined**: Supervisor-to-worker communication protocol unspecified, metadata aggregation algorithm missing, partial failure handling not defined
3. **Gap 3 - Phase Dependencies for Hierarchical Workflows Undefined**: Track detection algorithm unspecified, cross-track dependencies not declared
4. **Gap 5 - Checkpoint Schema Not Defined**: Orchestrator checkpoint schema undefined, supervisor checkpoint schema missing, nested checkpoint structure for 2-level hierarchy unclear
5. **Gap 6 - Development Guide Scope Unclear**: Target audience undefined, coverage depth unspecified, template integration unclear

**Current State Management Approach** (from Plan 003):
- Subprocess isolation acceptance: Stateless recalculation pattern (every bash block recalculates variables)
- File-based persistence: Checkpoints saved to files, re-loaded in each bash block
- Library wrappers: `save_orchestrator_checkpoint()`, `restore_orchestrator_checkpoint()` proposed but schema undefined
- Limitation acknowledged: Subprocess isolation is bash tool limitation, re-sourcing required

### From State Management Synthesis (Report 002)

**Key Findings**:

**Industry Reality** (contradicts Plan 003 assumptions):
- File-based state is 5x faster than recalculation for expensive operations (30ms vs 150ms measured)
- GitHub Actions replaced command-based state with file-based in Oct 2022 - MORE reliable
- Production systems (kubectl, Docker, Terraform, Git, AWS CLI) universally use file-based state at massive scale
- Stateless recalculation creates hidden complexity through synchronization requirements (6+ locations)

**When File-Based State is Justified** (7 criteria):
1. State accumulates across subprocess boundaries (Phase 3 benchmarks)
2. Context reduction requires metadata aggregation (95% reduction via supervisor outputs)
3. Success criteria validation needs objective evidence (timestamped metrics)
4. Resumability is valuable (multi-hour migrations)
5. State is non-deterministic (user surveys, research findings)
6. Recalculation is expensive (>30ms) or impossible
7. Phase dependencies require prior phase outputs

**When Stateless Recalculation is Appropriate** (5 criteria):
1. Calculation is fast (<10ms) and deterministic
2. State is ephemeral (temporary variables)
3. Subprocess boundaries don't exist (single bash block)
4. Canonical source exists elsewhere (library-api.md)
5. File-based overhead exceeds recalculation cost

**Critical State Items** (from decision matrix):
- 10 of 15 analyzed state items (67%) justify file-based persistence
- 3 of 5 plan phases (60%) are impossible without file-based state
- 33% rejection rate proves systematic analysis, not blanket advocacy

**GitHub Actions Pattern for .claude/**:
```bash
# Initialize state file (Block 1)
init_workflow_state() {
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_$$.sh"
  cat > "$STATE_FILE" <<EOF
export CLAUDE_PROJECT_DIR="$CLAUDE_PROJECT_DIR"
export WORKFLOW_ID="$$"
EOF
  trap "rm -f '$STATE_FILE'" EXIT
  echo "$STATE_FILE"
}

# Load state (Blocks 2+)
load_workflow_state() {
  if [ -f "$STATE_FILE" ]; then
    source "$STATE_FILE"
  else
    init_workflow_state  # Fallback: graceful degradation
  fi
}

# Append state (GitHub Actions $GITHUB_OUTPUT pattern)
append_workflow_state() {
  echo "export ${1}=\"${2}\"" >> "$STATE_FILE"
}
```

**Recommended Library**: `state-persistence.sh` (200 lines) wrapping existing checkpoint patterns

### From Implementation Review and Opportunities (Report 003)

**Current Architecture**:
- **3 orchestration commands**: /coordinate (1,084 lines), /orchestrate (557 lines), /supervise (1,779 lines) = 3,420 total
- **50 shared libraries**: 352 total functions, substantial overlap
- **Common 7-phase workflow**: Location → Research → Plan → Implement → Test → Debug → Document
- **Stateless recalculation**: Every bash block recalculates variables (emerged after 13 refactor attempts)
- **Subprocess isolation constraint**: Each bash block = separate process, exports don't persist

**Complexity Hotspots**:
1. **Phase 0 duplication**: ~200 lines × 3 commands = 600 lines (library sourcing, path detection, scope detection)
2. **Checkpoint schema evolution**: 4 migrations (1.0 → 1.1 → 1.2 → 1.3), manual migration functions required
3. **Error context variations**: Orchestrate-specific error contexts (100+ lines), custom formatting per command
4. **Redundant libraries**: workflow-detection.sh (207 lines) vs workflow-scope-detection.sh (50 lines)

**Key Insights**:
1. **Subprocess constraint is architectural, not temporary**: Only applies within single command execution, irrelevant for cross-invocation state
2. **Three commands = three implementations of same state machine**: All implement initialize → research → plan → implement → test → debug → document
3. **Stateless recalculation vs true state machine**: Current pattern optimizes within-execution, state machine optimizes across-execution and clarity
4. **Workflow scope detection = state machine initial state selector**: Phase filtering is state machine configuration disguised
5. **Checkpoint schema is state machine state serialization**: Already a state object, just not used consistently
6. **Redundancy signals missing abstraction**: Duplicate scope detection indicates no central state machine ownership

**Recommendations from Report 003**:
1. Introduce formal state machine abstraction (40% complexity reduction)
2. Consolidate redundant scope detection (257 lines eliminated)
3. Formalize checkpoint schema as state object (20% reliability improvement)
4. Extract shared Phase 0 initialization (18% code reduction)
5. Implement state-based error context (100 lines eliminated)
6. Adopt idempotent state transition pattern (atomic transitions, safe retry)

**Industry Best Practices** (from web search):
- **Temporal**: State machines with explicit states, transitions, retries, timeouts
- **Apache Airflow**: 10+ years production hardening, DAG-based workflows
- **AWS Step Functions**: Resume failed workflows midstream, skip succeeded steps
- **Bash FSM Pattern**: Endless loop with case branch, state file persisted to disk, each handler sets next state

## Success Criteria

- [ ] **Phase 1**: State machine library created (workflow-state-machine.sh, 400-600 lines), 8 core states defined, transition table validated, 20+ tests passing
- [ ] **Phase 2**: State machine integrated into checkpoint schema v2.0, migration path defined (v1.3 → v2.0), backward compatibility maintained
- [ ] **Phase 3**: State persistence library created (state-persistence.sh, 200 lines), GitHub Actions pattern implemented, 7 critical state items using file-based state, fallback to recalculation working
- [ ] **Phase 4**: Checkpoint schema v2.0 formalized, state machine state as first-class citizen, supervisor checkpoint schema defined, nested checkpoint structure for 2-level hierarchy documented
- [ ] **Phase 5**: /coordinate migrated to state machine (40% code reduction from 1,084 → 650 lines), zero regressions, all existing tests passing
- [ ] **Phase 6**: State-aware supervisors implemented (research, implementation, testing), checkpoint coordination working, 95% context reduction achieved
- [ ] **Phase 7**: Performance validated (40-60% time savings, <30% context usage, 100% file creation reliability), documentation complete
- [ ] **All Phases**: Zero regressions on existing orchestrators, measurable performance improvements, comprehensive test coverage (>80%)

## Technical Design

### State Machine Architecture

**State Enumeration** (explicit, not implicit phase numbers):
```bash
# Core workflow states
STATE_INITIALIZE="initialize"       # Phase 0: Setup, scope detection, path pre-calculation
STATE_RESEARCH="research"           # Phase 1: Research topic via specialist agents
STATE_PLAN="plan"                   # Phase 2: Create implementation plan
STATE_IMPLEMENT="implement"         # Phase 3: Execute implementation
STATE_TEST="test"                   # Phase 4: Run test suite
STATE_DEBUG="debug"                 # Phase 5: Debug failures (conditional)
STATE_DOCUMENT="document"           # Phase 6: Update documentation (conditional)
STATE_COMPLETE="complete"           # Phase 7: Finalization, cleanup
```

**State Transition Table** (defines valid transitions):
```bash
declare -A STATE_TRANSITIONS=(
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

**State Machine Core Functions**:
```bash
# Initialize new state machine from workflow description
sm_init() {
  local workflow_desc="$1"
  local command_name="$2"

  # Detect workflow scope (research-only, research-and-plan, full, debug-only)
  local scope=$(detect_workflow_scope "$workflow_desc")

  # Configure state machine based on scope
  case "$scope" in
    research-only)      TERMINAL_STATE="research" ;;
    research-and-plan)  TERMINAL_STATE="plan" ;;
    full-implementation) TERMINAL_STATE="complete" ;;
    debug-only)         TERMINAL_STATE="debug" ;;
  esac

  # Create initial state
  CURRENT_STATE="$STATE_INITIALIZE"
  save_state_machine_checkpoint
}

# Load state machine from checkpoint
sm_load() {
  local checkpoint_file="$1"

  # Load checkpoint using v2.0 schema
  local checkpoint_json=$(load_json_checkpoint "$checkpoint_file")
  CURRENT_STATE=$(echo "$checkpoint_json" | jq -r '.state_machine.current_state')
  COMPLETED_STATES=$(echo "$checkpoint_json" | jq -r '.state_machine.completed_states[]')
}

# Transition to next state (validates against transition table)
sm_transition() {
  local next_state="$1"

  # Phase 1: Validate transition is allowed
  local valid_transitions="${STATE_TRANSITIONS[$CURRENT_STATE]}"
  if ! echo "$valid_transitions" | grep -q "$next_state"; then
    echo "ERROR: Invalid transition: $CURRENT_STATE → $next_state" >&2
    echo "Valid transitions from $CURRENT_STATE: $valid_transitions" >&2
    return 1
  fi

  # Phase 2: Save pre-transition checkpoint (atomic state transition)
  save_state_machine_checkpoint "pre_transition"

  # Phase 3: Update state
  CURRENT_STATE="$next_state"
  COMPLETED_STATES+=("$CURRENT_STATE")

  # Phase 4: Save post-transition checkpoint
  save_state_machine_checkpoint "post_transition"
}

# Execute handler for current state
sm_execute() {
  local state="$CURRENT_STATE"

  # Delegate to state-specific handler
  case "$state" in
    initialize)  execute_initialize_phase ;;
    research)    execute_research_phase ;;
    plan)        execute_plan_phase ;;
    implement)   execute_implement_phase ;;
    test)        execute_test_phase ;;
    debug)       execute_debug_phase ;;
    document)    execute_document_phase ;;
    complete)    execute_complete_phase ;;
    *)
      echo "ERROR: Unknown state: $state" >&2
      return 1
      ;;
  esac
}
```

### Selective State Persistence (GitHub Actions Pattern)

**State Persistence Library** (state-persistence.sh):
```bash
# Initialize state file (Block 1)
init_workflow_state() {
  local workflow_id="${1:-$$}"

  # Detect CLAUDE_PROJECT_DIR ONCE (not in every block)
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

  # Create state file
  STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh"

  cat > "$STATE_FILE" <<EOF
export CLAUDE_PROJECT_DIR="$CLAUDE_PROJECT_DIR"
export WORKFLOW_ID="$workflow_id"
export STATE_FILE="$STATE_FILE"
EOF

  # Cleanup on exit
  trap "rm -f '$STATE_FILE'" EXIT

  echo "$STATE_FILE"
}

# Load state (Blocks 2+)
load_workflow_state() {
  local workflow_id="${1:-$$}"
  local state_file="${CLAUDE_PROJECT_DIR:-$HOME}/.claude/tmp/workflow_${workflow_id}.sh"

  if [ -f "$state_file" ]; then
    source "$state_file"
    return 0
  else
    # Fallback: recalculate if state file missing (graceful degradation)
    init_workflow_state "$workflow_id" >/dev/null
    return 1
  fi
}

# Append state (GitHub Actions $GITHUB_OUTPUT pattern)
append_workflow_state() {
  local key="$1"
  local value="$2"
  echo "export ${key}=\"${value}\"" >> "$STATE_FILE"
}

# Save complex data as JSON checkpoint
save_json_checkpoint() {
  local checkpoint_name="$1"
  local json_data="$2"
  local checkpoint_file="${CLAUDE_PROJECT_DIR}/.claude/tmp/${checkpoint_name}.json"

  # Atomic write
  echo "$json_data" > "${checkpoint_file}.tmp"
  mv "${checkpoint_file}.tmp" "$checkpoint_file"
}

# Load JSON checkpoint
load_json_checkpoint() {
  local checkpoint_name="$1"
  local checkpoint_file="${CLAUDE_PROJECT_DIR}/.claude/tmp/${checkpoint_name}.json"

  if [ -f "$checkpoint_file" ]; then
    cat "$checkpoint_file"
  else
    echo "{}" # Empty JSON object if missing
  fi
}

# Append JSONL log (benchmarks, metrics)
append_jsonl_log() {
  local log_name="$1"
  local json_entry="$2"
  local log_file="${CLAUDE_PROJECT_DIR}/.claude/tmp/${log_name}.jsonl"

  echo "$json_entry" >> "$log_file"
}
```

**Critical State Items Using File-Based Persistence** (7 of 10 analyzed):
1. **Supervisor metadata** (P0): 95% context reduction, non-deterministic research findings
2. **Benchmark dataset** (P0): Phase 3 accumulation across 10 subprocess invocations
3. **Implementation supervisor state** (P0): 40-60% time savings via parallel execution tracking
4. **Testing supervisor state** (P0): Lifecycle coordination across sequential stages
5. **Migration progress** (P1): Resumable, audit trail for multi-hour migrations
6. **Performance benchmarks** (P1): Phase 3 dependency on Phase 2 data
7. **POC metrics** (P1): Success criterion validation (timestamped phase breakdown)

**State Items Using Stateless Recalculation** (3 of 10 analyzed):
1. **File verification cache**: Recalculation 10x faster than file I/O
2. **Track detection results**: Deterministic, <1ms recalculation
3. **Guide completeness checklist**: Markdown checklist sufficient

### Checkpoint Schema v2.0 (State Machine First-Class)

**Schema Definition**:
```json
{
  "version": "2.0",
  "state_machine": {
    "current_state": "research",
    "completed_states": ["initialize"],
    "transition_table": {
      "initialize": "research",
      "research": "plan,complete",
      "plan": "implement,complete",
      "implement": "test",
      "test": "debug,document",
      "debug": "test,complete",
      "document": "complete",
      "complete": ""
    },
    "workflow_config": {
      "scope": "research-and-plan",
      "description": "Research authentication patterns and create implementation plan",
      "command": "coordinate",
      "topic_path": "/home/user/.claude/specs/042_auth"
    }
  },
  "phase_data": {
    "research": {
      "reports_created": ["report1.md", "report2.md"],
      "context_usage_tokens": 12500,
      "duration_ms": 45000
    }
  },
  "supervisor_state": {
    "research_supervisor": {
      "supervisor_name": "research-sub-supervisor",
      "worker_count": 4,
      "worker_status": ["completed", "completed", "completed", "completed"],
      "aggregated_metadata": {
        "topics_researched": 4,
        "reports_created": ["path1", "path2", "path3", "path4"],
        "summary": "Combined 50-word summary from all workers",
        "key_findings": ["finding1", "finding2", "finding3"]
      }
    }
  },
  "error_state": {
    "last_error": null,
    "retry_count": 0,
    "failed_state": null
  },
  "metadata": {
    "checkpoint_id": "coordinate_20251107_143022",
    "project_name": "claude-config",
    "created_at": "2025-11-07T14:30:22Z",
    "updated_at": "2025-11-07T14:35:10Z"
  }
}
```

**Migration Path** (v1.3 → v2.0):
```bash
migrate_checkpoint_v1_to_v2() {
  local v1_checkpoint="$1"

  # Read v1 checkpoint
  local v1_json=$(cat "$v1_checkpoint")

  # Extract v1 fields
  local current_phase=$(echo "$v1_json" | jq -r '.current_phase')
  local completed_phases=$(echo "$v1_json" | jq -r '.completed_phases[]')

  # Map phase number to state name
  local current_state=$(map_phase_to_state "$current_phase")

  # Build v2 checkpoint
  local v2_json=$(jq -n \
    --arg current_state "$current_state" \
    --argjson completed_states "$(echo "$completed_phases" | jq -R . | jq -s 'map(tonumber | tostring | map_phase_to_state)')" \
    '{
      version: "2.0",
      state_machine: {
        current_state: $current_state,
        completed_states: $completed_states,
        transition_table: {
          initialize: "research",
          research: "plan,complete",
          plan: "implement,complete",
          implement: "test",
          test: "debug,document",
          debug: "test,complete",
          document: "complete",
          complete: ""
        }
      }
    }')

  echo "$v2_json"
}
```

### Hierarchical Supervisor Checkpoint Coordination

**Supervisor Checkpoint Schema** (extends v2.0):
```json
{
  "supervisor_state": {
    "research_supervisor": {
      "supervisor_id": "research_sub_supervisor_20251107_143030",
      "supervisor_name": "research-sub-supervisor",
      "worker_count": 4,
      "workers": [
        {
          "worker_id": "research_specialist_1",
          "topic": "authentication patterns",
          "status": "completed",
          "output_path": "/path/to/report1.md",
          "duration_ms": 12000,
          "metadata": {
            "title": "Authentication Patterns Research",
            "summary": "Analysis of session-based auth, JWT tokens, OAuth2 flows",
            "key_findings": ["finding1", "finding2"]
          }
        },
        {
          "worker_id": "research_specialist_2",
          "topic": "authorization patterns",
          "status": "completed",
          "output_path": "/path/to/report2.md",
          "duration_ms": 10500,
          "metadata": {
            "title": "Authorization Patterns Research",
            "summary": "RBAC, ABAC, policy-based access control comparison",
            "key_findings": ["finding3", "finding4"]
          }
        }
      ],
      "aggregated_metadata": {
        "topics_researched": 4,
        "reports_created": ["path1", "path2", "path3", "path4"],
        "summary": "Combined summary: Authentication and authorization patterns analyzed across 4 dimensions",
        "key_findings": ["finding1", "finding2", "finding3", "finding4"],
        "total_duration_ms": 45000,
        "context_tokens": 1000
      }
    }
  }
}
```

**Supervisor-to-Worker Communication Protocol**:
```bash
# In orchestrator bash block
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
load_workflow_state "coordinate_$$"

# Invoke supervisor (hierarchical pattern for 4+ topics)
SUPERVISOR_RESULT=$(invoke_hierarchical_supervisor \
  "research-sub-supervisor" \
  4 \
  "authentication,authorization,session,password" \
  "$RESEARCH_PROMPT")

# Save supervisor metadata to checkpoint
save_json_checkpoint "supervisor_metadata" "$SUPERVISOR_RESULT"

# Append to workflow state
append_workflow_state "SUPERVISOR_METADATA_PATH" "${CLAUDE_PROJECT_DIR}/.claude/tmp/supervisor_metadata.json"
```

**Supervisor Behavioral File Pattern** (.claude/agents/research-sub-supervisor.md):
```markdown
**STEP 3: Invoke Workers in Parallel**

USE the Task tool to invoke 4 research-specialist workers simultaneously:

**Worker 1 - Authentication Patterns**:
Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/user/.config/.claude/agents/research-specialist.md

    Research topic: Authentication patterns
    Output: /path/to/report1.md

    Return: REPORT_CREATED: /path/to/report1.md
}

**Worker 2 - Authorization Patterns**:
Task { ... }

**Worker 3 - Session Management**:
Task { ... }

**Worker 4 - Password Security**:
Task { ... }

**STEP 4: Aggregate Worker Metadata**

After all workers complete:

1. Extract metadata from each worker output (title, summary, key findings)
2. Aggregate into single summary:
   - Topics researched: 4
   - Reports created: [path1, path2, path3, path4]
   - Combined summary: "Authentication, authorization, session, and password patterns analyzed"
   - Key findings: Merge top 2 findings from each worker
3. Save aggregated metadata to checkpoint using state-persistence.sh
4. Return aggregated metadata ONLY (not full worker outputs) for 95% context reduction

**STEP 5: Return Aggregated Metadata**

Return format:
SUPERVISOR_COMPLETE: {
  "supervisor_id": "research_sub_supervisor_20251107_143030",
  "topics_researched": 4,
  "reports_created": ["path1", "path2", "path3", "path4"],
  "summary": "...",
  "key_findings": ["...", "...", "..."]
}
```

### Orchestrator State Machine Integration

**Orchestrator Command Structure** (coordinate.md):
```bash
# Block 1: Initialize state machine
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"

# Initialize workflow state (GitHub Actions pattern)
STATE_FILE=$(init_workflow_state "coordinate_$$")

# Initialize state machine
sm_init "$WORKFLOW_DESCRIPTION" "coordinate"

# State machine now owns: scope, paths, libraries, checkpoint
# Block 2: Execute state machine

source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
load_workflow_state "coordinate_$$"

# Main state machine loop
while [ "$CURRENT_STATE" != "$STATE_COMPLETE" ]; do
  # Execute current state
  sm_execute

  # Determine next state based on results
  case "$CURRENT_STATE" in
    research)
      if [ "$WORKFLOW_SCOPE" == "research-only" ]; then
        sm_transition "$STATE_COMPLETE"
      else
        sm_transition "$STATE_PLAN"
      fi
      ;;
    plan)
      if [ "$WORKFLOW_SCOPE" == "research-and-plan" ]; then
        sm_transition "$STATE_COMPLETE"
      else
        sm_transition "$STATE_IMPLEMENT"
      fi
      ;;
    test)
      if [ "$TESTS_PASSING" == "true" ]; then
        sm_transition "$STATE_DOCUMENT"
      else
        sm_transition "$STATE_DEBUG"
      fi
      ;;
    # ... other transitions
  esac
done
```

## Implementation Phases

### Phase 1: State Machine Foundation Library
dependencies: []

**Objective**: Create formal state machine library with explicit states, transition table, and validation

**Complexity**: Medium-High

**Tasks**:
- [x] **Create State Machine Library**: Implement workflow-state-machine.sh (400-600 lines)
  - [x] Define 8 core state constants (initialize, research, plan, implement, test, debug, document, complete)
  - [x] Implement state transition table (declare -A STATE_TRANSITIONS)
  - [x] Create `sm_init()` - Initialize state machine from workflow description and scope
  - [x] Create `sm_load()` - Load state machine from checkpoint file
  - [x] Create `sm_current_state()` - Get current state
  - [x] Create `sm_transition()` - Validate and execute state transition (atomic two-phase commit)
  - [x] Create `sm_execute()` - Execute handler for current state
  - [x] Create `sm_save()` - Save state machine to checkpoint
  - [x] Add state transition validation (invalid transitions return error)
  - [x] Add state history tracking (completed_states array)
- [x] **Workflow Scope Integration**: Connect state machine to existing scope detection
  - [x] Integrate with workflow-detection.sh (use existing detect_workflow_scope)
  - [x] Map workflow scope to terminal state (research-only → research, research-and-plan → plan, full → complete)
  - [x] Configure transition table based on scope (research-only disables plan/implement/test transitions)
- [x] **Testing**: Comprehensive state machine validation
  - [x] Test: State initialization (8 states defined, transition table validated)
  - [x] Test: Valid transitions (initialize → research, research → plan, etc.)
  - [x] Test: Invalid transition rejection (initialize → implement returns error)
  - [x] Test: State history tracking (completed_states appends correctly)
  - [x] Test: Workflow scope configuration (research-only terminates at research state)
  - [x] Test: Atomic state transitions (pre-transition checkpoint, post-transition checkpoint)
  - [x] Test: State machine save and load (checkpoint persistence)
  - [x] Create `.claude/tests/test_state_machine.sh` (20+ tests)
- [x] **Documentation**: State machine architecture guide
  - [x] Create `.claude/docs/architecture/workflow-state-machine.md` (1000-1500 lines)
  - [x] Document state enumeration and transition table
  - [x] Document state handler interface (what each state does)
  - [x] Document extension guide (adding new states/transitions)
  - [x] Add state transition diagram (ASCII or mermaid)
  - [x] Document atomic transition pattern (two-phase commit)

**Testing**:
```bash
# Test state machine core functionality
bash .claude/tests/test_state_machine.sh
# Expected: 20+ tests passing

# Test invalid transitions
sm_init "Research authentication" "coordinate"
sm_transition "implement"  # Should fail - can't skip research/plan
# Expected: Error message, transition rejected
```

**Expected Duration**: 15-25 hours (2-3 weeks)

**Deliverables**:
- `.claude/lib/workflow-state-machine.sh` (400-600 lines)
- `.claude/tests/test_state_machine.sh` (20+ tests)
- `.claude/docs/architecture/workflow-state-machine.md` (1000-1500 lines)

**Success Criteria**:
- [x] 8 states defined with clear enumeration
- [x] Transition table validated (all valid transitions defined)
- [x] Invalid transition rejection working (error messages clear)
- [x] Atomic state transitions implemented (two-phase commit)
- [x] 20+ state machine tests passing (50 tests passing)
- [x] Documentation complete with state diagram

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (50 state machine tests, 100% pass rate)
- [x] Git commit created: `feat(602): complete Phase 1 - State Machine Foundation` (commit 75cda312)
- [x] Checkpoint saved (state machine library established)

[COMPLETED] Phase 1 completed on 2025-11-07

---

### Phase 2: Checkpoint Schema v2.0 Integration
dependencies: [1]

**Objective**: Integrate state machine into checkpoint schema v2.0 with migration path from v1.3

**Complexity**: Medium

**Tasks**:
- [ ] **Define Checkpoint Schema v2.0**: Formalize state machine as first-class citizen
  - [ ] Define JSON schema for v2.0 (state_machine, phase_data, supervisor_state, error_state, metadata sections)
  - [ ] Add `state_machine` section (current_state, completed_states, transition_table, workflow_config)
  - [ ] Add `supervisor_state` section (supervisor checkpoints for hierarchical coordination)
  - [ ] Add `error_state` section (last_error, retry_count, failed_state)
  - [ ] Preserve `phase_data` section for backward compatibility
  - [ ] Document schema in checkpoint-utils.sh header comments
- [ ] **Implement v1.3 → v2.0 Migration**: Convert existing checkpoints to new schema
  - [ ] Create `migrate_checkpoint_v1_to_v2()` function in checkpoint-utils.sh
  - [ ] Map phase numbers to state names (0 → initialize, 1 → research, etc.)
  - [ ] Preserve completed_phases as completed_states
  - [ ] Add default transition table to migrated checkpoints
  - [ ] Validate migrated checkpoints (schema validation)
  - [ ] Test migration with real v1.3 checkpoints from /coordinate, /orchestrate, /supervise
- [ ] **Update Checkpoint Functions**: Modify existing checkpoint-utils.sh functions for v2.0
  - [ ] Update `save_checkpoint()` to write v2.0 schema
  - [ ] Update `restore_checkpoint()` to read v2.0 schema (with v1.3 fallback migration)
  - [ ] Update `validate_checkpoint()` to validate v2.0 schema
  - [ ] Add `save_state_machine_checkpoint()` wrapper for state machine-specific saves
  - [ ] Add `load_state_machine_checkpoint()` wrapper for state machine-specific loads
  - [ ] Maintain backward compatibility (auto-detect v1.3 and migrate on load)
- [ ] **Testing**: Checkpoint schema validation and migration
  - [ ] Test: v2.0 checkpoint save and load (state machine fields preserved)
  - [ ] Test: v1.3 checkpoint auto-migration (detects v1.3, migrates to v2.0 on load)
  - [ ] Test: Phase number to state name mapping (0 → initialize, 1 → research, etc.)
  - [ ] Test: Schema validation (invalid v2.0 checkpoints rejected)
  - [ ] Test: Backward compatibility (v1.3 checkpoints loadable)
  - [ ] Test: State machine state persistence (current_state, completed_states saved correctly)
  - [ ] Create `.claude/tests/test_checkpoint_schema_v2.sh` (15+ tests)
- [ ] **Documentation**: Checkpoint schema v2.0 reference
  - [ ] Update `.claude/docs/reference/library-api.md` with v2.0 schema documentation
  - [ ] Document migration path (v1.3 → v2.0) with examples
  - [ ] Add schema validation examples
  - [ ] Document state machine checkpoint functions

**Testing**:
```bash
# Test checkpoint schema v2.0
bash .claude/tests/test_checkpoint_schema_v2.sh
# Expected: 15+ tests passing

# Test migration from v1.3
migrate_checkpoint_v1_to_v2 "/path/to/v1.3/checkpoint.json"
# Expected: Valid v2.0 checkpoint with state machine fields
```

**Expected Duration**: 10-15 hours (1-2 weeks)

**Deliverables**:
- Updated `.claude/lib/checkpoint-utils.sh` (+150-250 lines for v2.0 support)
- `migrate_checkpoint_v1_to_v2()` function
- `.claude/tests/test_checkpoint_schema_v2.sh` (15+ tests)
- Updated `.claude/docs/reference/library-api.md` (v2.0 schema documentation)

**Success Criteria**:
- [ ] v2.0 schema defined and documented
- [ ] State machine as first-class citizen in checkpoint
- [ ] v1.3 → v2.0 migration working (auto-detect and migrate)
- [ ] Backward compatibility maintained (v1.3 checkpoints loadable)
- [ ] 15+ checkpoint schema tests passing
- [ ] Schema validation working (invalid checkpoints rejected)

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (15+ checkpoint schema tests)
- [ ] Git commit created: `feat(602): complete Phase 2 - Checkpoint Schema v2.0`
- [ ] Checkpoint saved (v2.0 schema established)

---

### Phase 3: Selective State Persistence Library
dependencies: [1]

**Objective**: Implement GitHub Actions-style state persistence for 7 critical state items

**Complexity**: Medium

**Tasks**:
- [ ] **Create State Persistence Library**: Implement state-persistence.sh (200 lines)
  - [ ] Implement `init_workflow_state()` - Initialize state file with CLAUDE_PROJECT_DIR detection
  - [ ] Implement `load_workflow_state()` - Load state file with fallback to recalculation
  - [ ] Implement `append_workflow_state()` - GitHub Actions $GITHUB_OUTPUT pattern
  - [ ] Implement `save_json_checkpoint()` - Atomic write for structured data
  - [ ] Implement `load_json_checkpoint()` - Read checkpoint with validation
  - [ ] Implement `append_jsonl_log()` - Append-only benchmark logging
  - [ ] Add EXIT trap for state file cleanup (prevent leakage)
  - [ ] Add graceful degradation (missing state file → recalculate)
- [ ] **Identify Critical State Items**: Apply decision criteria to select file-based state
  - [ ] P0: Supervisor metadata (95% context reduction, non-deterministic)
  - [ ] P0: Benchmark dataset (Phase 3 accumulation across 10 invocations)
  - [ ] P0: Implementation supervisor state (40-60% time savings tracking)
  - [ ] P0: Testing supervisor state (lifecycle coordination)
  - [ ] P1: Migration progress (resumable, audit trail)
  - [ ] P1: Performance benchmarks (Phase 3 dependency on Phase 2)
  - [ ] P1: POC metrics (success criterion validation)
  - [ ] Document: File verification cache → stateless (10x faster)
  - [ ] Document: Track detection → stateless (<1ms)
  - [ ] Document: Guide checklist → stateless (markdown sufficient)
- [ ] **Performance Optimization**: CLAUDE_PROJECT_DIR detection cached
  - [ ] Measure baseline: `git rev-parse --show-toplevel` cost (expected 50ms)
  - [ ] Implement: Detect once in init_workflow_state, cache in state file
  - [ ] Measure improvement: State file read cost (expected 15ms)
  - [ ] Validate: 70% improvement (50ms → 15ms for subsequent blocks)
- [ ] **Testing**: State persistence validation
  - [ ] Test: State file initialization (CLAUDE_PROJECT_DIR detected and cached)
  - [ ] Test: State file loading (subsequent blocks read cached value)
  - [ ] Test: Append workflow state (GitHub Actions pattern working)
  - [ ] Test: JSON checkpoint save and load (atomic writes, validation)
  - [ ] Test: JSONL log appending (benchmarks accumulated)
  - [ ] Test: Graceful degradation (missing state file → fallback works)
  - [ ] Test: EXIT trap cleanup (state file removed on exit)
  - [ ] Test: Performance improvement (50ms → 15ms validated)
  - [ ] Create `.claude/tests/test_state_persistence.sh` (15+ tests)
- [ ] **Documentation**: State persistence patterns
  - [ ] Update `.claude/docs/architecture/coordinate-state-management.md` with accurate performance data
  - [ ] Add "Selective State Persistence" section documenting 7 critical items
  - [ ] Add "Performance Reality Check" section (file-based 5x faster for expensive ops)
  - [ ] Document GitHub Actions pattern adaptation for .claude/
  - [ ] Add decision criteria (when file-based vs stateless)
  - [ ] Update `.claude/docs/reference/library-api.md` with state-persistence.sh API

**Testing**:
```bash
# Test state persistence
bash .claude/tests/test_state_persistence.sh
# Expected: 15+ tests passing

# Test performance improvement
time git rev-parse --show-toplevel  # Baseline
# Expected: ~50ms

STATE_FILE=$(init_workflow_state "test_$$")
time load_workflow_state "test_$$"  # Cached
# Expected: ~15ms (70% improvement)
```

**Expected Duration**: 10-15 hours (1-2 weeks)

**Deliverables**:
- `.claude/lib/state-persistence.sh` (200 lines)
- `.claude/tests/test_state_persistence.sh` (15+ tests)
- Updated `.claude/docs/architecture/coordinate-state-management.md` (accurate performance data)
- Updated `.claude/docs/reference/library-api.md` (state-persistence.sh API)

**Success Criteria**:
- [ ] 7 critical state items identified and documented
- [ ] GitHub Actions pattern implemented (init, load, append)
- [ ] Graceful degradation working (fallback to recalculation)
- [ ] 70% performance improvement validated (50ms → 15ms)
- [ ] 15+ state persistence tests passing
- [ ] Decision criteria documented (file-based vs stateless)

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (15+ state persistence tests)
- [ ] Git commit created: `feat(602): complete Phase 3 - Selective State Persistence`
- [ ] Checkpoint saved (state persistence library established)

---

### Phase 4: Hierarchical Supervisor Checkpoint Schema
dependencies: [2, 3]

**Objective**: Define supervisor checkpoint schema for 2-level hierarchical coordination

**Complexity**: Medium

**Tasks**:
- [ ] **Define Supervisor Checkpoint Schema**: Extend v2.0 schema with supervisor fields
  - [ ] Add `supervisor_state` section to v2.0 schema
  - [ ] Define supervisor fields: supervisor_id, supervisor_name, worker_count, workers[], aggregated_metadata
  - [ ] Define worker fields: worker_id, topic, status, output_path, duration_ms, metadata
  - [ ] Define aggregated_metadata fields: topics_researched, reports_created, summary, key_findings, total_duration_ms, context_tokens
  - [ ] Document nested checkpoint structure (orchestrator → supervisor → workers)
  - [ ] Add supervisor checkpoint validation
- [ ] **Implement Supervisor-to-Worker Protocol**: Define communication pattern
  - [ ] Document supervisor invocation pattern (orchestrator bash block → supervisor via Task tool)
  - [ ] Document worker invocation pattern (supervisor behavioral file → workers via Task tool)
  - [ ] Define completion signals (SUPERVISOR_COMPLETE: with aggregated metadata)
  - [ ] Define metadata aggregation algorithm (combine worker metadata → supervisor summary)
  - [ ] Define partial failure handling (2/3 workers succeed → report success + failure context)
  - [ ] Create supervisor communication protocol document
- [ ] **Supervisor Behavioral File Template**: Create reusable supervisor pattern
  - [ ] Create `.claude/templates/sub-supervisor-template.md` (400-600 lines)
  - [ ] Section: Worker invocation (parallel Task invocations)
  - [ ] Section: Metadata extraction (parse worker outputs)
  - [ ] Section: Metadata aggregation (combine into supervisor summary)
  - [ ] Section: Checkpoint coordination (save supervisor state using state-persistence.sh)
  - [ ] Section: Error handling (partial failures, supervisor crash recovery)
  - [ ] Add validation: Template used to create research-sub-supervisor.md
- [ ] **Testing**: Supervisor checkpoint validation
  - [ ] Test: Supervisor checkpoint schema (supervisor_state fields validated)
  - [ ] Test: Nested checkpoint structure (orchestrator → supervisor → workers)
  - [ ] Test: Metadata aggregation (4 workers → 1 supervisor summary)
  - [ ] Test: Partial failure handling (2/3 workers → success + failure context)
  - [ ] Test: Supervisor state persistence (save_json_checkpoint working)
  - [ ] Create `.claude/tests/test_supervisor_checkpoint.sh` (12+ tests)
- [ ] **Documentation**: Supervisor checkpoint reference
  - [ ] Create `.claude/docs/architecture/hierarchical-supervisor-coordination.md` (800-1200 lines)
  - [ ] Document supervisor checkpoint schema
  - [ ] Document supervisor-to-worker communication protocol
  - [ ] Document metadata aggregation algorithm
  - [ ] Document partial failure handling patterns
  - [ ] Add supervisor checkpoint examples
  - [ ] Update `.claude/docs/reference/library-api.md` with supervisor checkpoint functions

**Testing**:
```bash
# Test supervisor checkpoint
bash .claude/tests/test_supervisor_checkpoint.sh
# Expected: 12+ tests passing

# Test metadata aggregation
WORKER_METADATA='[{"title": "Auth", "summary": "..."}, {"title": "OAuth", "summary": "..."}]'
AGGREGATED=$(aggregate_worker_metadata "$WORKER_METADATA")
# Expected: Single supervisor summary with combined findings
```

**Expected Duration**: 12-18 hours (2 weeks)

**Deliverables**:
- Updated checkpoint schema v2.0 (supervisor_state section)
- `.claude/templates/sub-supervisor-template.md` (400-600 lines)
- `.claude/tests/test_supervisor_checkpoint.sh` (12+ tests)
- `.claude/docs/architecture/hierarchical-supervisor-coordination.md` (800-1200 lines)
- Updated `.claude/docs/reference/library-api.md` (supervisor checkpoint API)

**Success Criteria**:
- [ ] Supervisor checkpoint schema defined and validated
- [ ] Nested checkpoint structure documented (2-level hierarchy)
- [ ] Metadata aggregation algorithm specified
- [ ] Partial failure handling defined
- [ ] 12+ supervisor checkpoint tests passing
- [ ] Template validated (research-sub-supervisor.md created successfully)

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (12+ supervisor checkpoint tests)
- [ ] Git commit created: `feat(602): complete Phase 4 - Supervisor Checkpoint Schema`
- [ ] Checkpoint saved (supervisor coordination established)

---

### Phase 5: Orchestrator Migration to State Machine
dependencies: [1, 2, 3]

**Objective**: Migrate /coordinate to state machine architecture with 40% code reduction

**Complexity**: High

**Tasks**:
- [ ] **Migrate /coordinate Phase 0**: Replace 200 lines with state machine initialization
  - [ ] Replace library sourcing duplication with state machine init
  - [ ] Replace CLAUDE_PROJECT_DIR detection with state persistence (init_workflow_state)
  - [ ] Replace scope detection with state machine configuration (sm_init)
  - [ ] Replace path pre-calculation with state machine path management
  - [ ] Verify: Phase 0 reduced from ~200 lines → ~50 lines (75% reduction)
- [ ] **Migrate /coordinate Phase Loop**: Replace phase-based loop with state machine loop
  - [ ] Replace phase number tracking with state machine (CURRENT_STATE)
  - [ ] Replace phase filtering with state transition table
  - [ ] Replace manual checkpoint saves with sm_transition (atomic checkpoints)
  - [ ] Add state machine main loop (while CURRENT_STATE != STATE_COMPLETE)
  - [ ] Add state-based phase execution (sm_execute calls execute_*_phase)
- [ ] **Migrate /coordinate Error Handling**: Use state-based error context
  - [ ] Replace orchestrate-specific error formatting with state-based formatting
  - [ ] Add failed_state tracking to error_state checkpoint section
  - [ ] Add state transition retry logic (max 2 retries per state)
  - [ ] Simplify error messages (state provides context)
- [ ] **Testing**: /coordinate state machine validation
  - [ ] Test: All 4 workflow scopes (research-only, research-and-plan, full, debug-only)
  - [ ] Test: State transitions (initialize → research → plan → implement → test → document → complete)
  - [ ] Test: State machine checkpoint persistence (resume from interruption)
  - [ ] Test: Error handling (failed state tracked, retry logic working)
  - [ ] Test: Performance (40% code reduction validated: 1,084 → ~650 lines)
  - [ ] Test: Zero regressions (all existing /coordinate tests passing)
  - [ ] Update `.claude/tests/test_orchestration_commands.sh` with state machine tests
- [ ] **Migrate /orchestrate and /supervise**: Apply same state machine pattern
  - [ ] Migrate /orchestrate Phase 0 and main loop (557 → ~350 lines, 37% reduction)
  - [ ] Migrate /supervise Phase 0 and main loop (1,779 → ~1,100 lines, 38% reduction)
  - [ ] Verify zero regressions on both commands
  - [ ] Total code reduction: 3,420 → 2,100 lines (39% reduction)
- [ ] **Documentation**: State machine migration guide
  - [ ] Create `.claude/docs/guides/state-machine-migration-guide.md` (600-900 lines)
  - [ ] Document migration steps (Phase 0, main loop, error handling)
  - [ ] Add before/after code examples
  - [ ] Document common migration issues and solutions
  - [ ] Add testing requirements for migration

**Testing**:
```bash
# Test /coordinate state machine migration
bash .claude/tests/test_orchestration_commands.sh
# Expected: All /coordinate tests passing (zero regressions)

# Test all workflow scopes
/coordinate "Research authentication patterns"  # research-only
# Expected: State machine terminates at STATE_RESEARCH

/coordinate "Research and plan authentication system"  # research-and-plan
# Expected: State machine terminates at STATE_PLAN

# Measure code reduction
wc -l .claude/commands/coordinate.md
# Expected: ~650 lines (40% reduction from 1,084)
```

**Expected Duration**: 20-30 hours (3-4 weeks)

**Deliverables**:
- Migrated `/coordinate.md` (~650 lines, 40% reduction from 1,084)
- Migrated `/orchestrate.md` (~350 lines, 37% reduction from 557)
- Migrated `/supervise.md` (~1,100 lines, 38% reduction from 1,779)
- Updated `.claude/tests/test_orchestration_commands.sh` (state machine tests)
- `.claude/docs/guides/state-machine-migration-guide.md` (600-900 lines)

**Success Criteria**:
- [ ] 40% code reduction across all 3 orchestrators (3,420 → 2,100 lines)
- [ ] Zero regressions (all existing tests passing)
- [ ] All 4 workflow scopes working correctly
- [ ] State machine checkpoint persistence working
- [ ] State-based error handling simplified
- [ ] Migration guide complete with examples

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (all orchestration tests + zero regressions)
- [ ] Git commit created: `feat(602): complete Phase 5 - Orchestrator Migration`
- [ ] Checkpoint saved (state machine migration complete)

---

### Phase 6: State-Aware Hierarchical Supervisors
dependencies: [4, 5]

**Objective**: Implement state-aware supervisors with proper checkpoint coordination

**Complexity**: Medium-High

**Tasks**:
- [ ] **Create Research Sub-Supervisor**: Implement research-sub-supervisor.md with state awareness
  - [ ] Implement worker invocation (4 research-specialist workers in parallel)
  - [ ] Implement metadata extraction (parse worker REPORT_CREATED signals)
  - [ ] Implement metadata aggregation (combine 4 worker summaries → 1 supervisor summary)
  - [ ] Implement checkpoint coordination (save supervisor_state using state-persistence.sh)
  - [ ] Add partial failure handling (2/3 workers succeed → report success + context)
  - [ ] Add context reduction validation (supervisor output << worker outputs)
  - [ ] File: `.claude/agents/research-sub-supervisor.md` (400-600 lines)
- [ ] **Create Implementation Sub-Supervisor**: Track-level coordination with state
  - [ ] Implement track detection (frontend, backend, testing via file path patterns)
  - [ ] Implement cross-track dependency management (frontend waits for backend)
  - [ ] Implement parallel track execution (3 implementation-executor agents)
  - [ ] Implement metadata aggregation per track (files_modified, duration, status)
  - [ ] Implement checkpoint coordination (save impl_supervisor_state)
  - [ ] Add 40-60% time savings tracking (parallel vs sequential)
  - [ ] File: `.claude/agents/implementation-sub-supervisor.md` (500-700 lines)
- [ ] **Create Testing Sub-Supervisor**: Lifecycle coordination with state
  - [ ] Implement sequential stages (generation → execution → validation)
  - [ ] Implement parallel workers within stages (unit, integration, e2e generators)
  - [ ] Implement test metrics tracking (total_tests, passed/failed, coverage %)
  - [ ] Implement metadata aggregation (test counts + coverage + failures)
  - [ ] Implement checkpoint coordination (save test_supervisor_state)
  - [ ] File: `.claude/agents/testing-sub-supervisor.md` (400-600 lines)
- [ ] **Integrate Supervisors into /coordinate**: Add conditional hierarchical coordination
  - [ ] Add research supervisor logic (≥4 topics → hierarchical, <4 → flat)
  - [ ] Add implementation supervisor logic (domain_count ≥3 OR complexity ≥10 → hierarchical)
  - [ ] Add testing supervisor logic (test_count ≥20 OR test_types ≥2 → hierarchical)
  - [ ] Add supervisor checkpoint loading (load supervisor_state from checkpoint)
  - [ ] Add supervisor metadata passing (95% context reduction validation)
- [ ] **Testing**: Hierarchical supervisor validation
  - [ ] Test: Research supervisor (4 workers → 95% context reduction)
  - [ ] Test: Implementation supervisor (3 tracks → 40-60% time savings)
  - [ ] Test: Testing supervisor (sequential stages, parallel workers)
  - [ ] Test: Supervisor checkpoint persistence (supervisor_state saved/loaded)
  - [ ] Test: Partial failure handling (2/3 workers → success + failure context)
  - [ ] Test: Context reduction (supervisor output << worker outputs)
  - [ ] Test: Conditional invocation (thresholds trigger hierarchical correctly)
  - [ ] Create `.claude/tests/test_hierarchical_supervisors.sh` (20+ tests)
- [ ] **Documentation**: Hierarchical supervisor usage guide
  - [ ] Create `.claude/docs/guides/hierarchical-supervisor-guide.md` (1000-1500 lines)
  - [ ] Document when to use hierarchical supervision (decision matrix)
  - [ ] Document supervisor behavioral file structure
  - [ ] Document checkpoint coordination patterns
  - [ ] Document metadata aggregation algorithms
  - [ ] Add supervisor troubleshooting guide

**Testing**:
```bash
# Test hierarchical supervisors
bash .claude/tests/test_hierarchical_supervisors.sh
# Expected: 20+ tests passing

# Test research supervisor
/coordinate "Research auth, oauth, session, password"  # 4 topics
# Expected: Uses research-sub-supervisor, 95% context reduction

# Test implementation supervisor
/coordinate "Implement auth with frontend + backend + testing"
# Expected: Uses implementation-sub-supervisor, 40-60% time savings
```

**Expected Duration**: 25-35 hours (3-4 weeks)

**Deliverables**:
- `.claude/agents/research-sub-supervisor.md` (400-600 lines)
- `.claude/agents/implementation-sub-supervisor.md` (500-700 lines)
- `.claude/agents/testing-sub-supervisor.md` (400-600 lines)
- Updated `/coordinate.md` (supervisor integration)
- `.claude/tests/test_hierarchical_supervisors.sh` (20+ tests)
- `.claude/docs/guides/hierarchical-supervisor-guide.md` (1000-1500 lines)

**Success Criteria**:
- [ ] 95% context reduction through research supervisor
- [ ] 40-60% time savings through implementation supervisor
- [ ] Sequential lifecycle coordination through testing supervisor
- [ ] Conditional invocation working (thresholds trigger correctly)
- [ ] 20+ hierarchical supervisor tests passing
- [ ] Supervisor checkpoint persistence working

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (20+ hierarchical supervisor tests)
- [ ] Git commit created: `feat(602): complete Phase 6 - State-Aware Supervisors`
- [ ] Checkpoint saved (hierarchical supervision established)

---

### Phase 7: Performance Validation and Documentation
dependencies: [5, 6]

**Objective**: Validate performance improvements and complete comprehensive documentation

**Complexity**: Low-Medium

**Tasks**:
- [ ] **Performance Benchmarking**: Measure actual improvements vs targets
  - [ ] Benchmark: Code reduction (3,420 → 2,100 lines = 39% reduction)
  - [ ] Benchmark: State operation performance (150ms → 30ms = 80% improvement for expensive ops)
  - [ ] Benchmark: Context reduction (95% via supervisors)
  - [ ] Benchmark: Time savings (40-60% via parallel execution)
  - [ ] Benchmark: File creation reliability (100% maintained)
  - [ ] Run 10+ workflows with state machine orchestrators
  - [ ] Collect metrics: execution time, context usage, reliability rate
  - [ ] Compare against baseline (pre-state-machine orchestrators)
- [ ] **Regression Testing**: Verify zero regressions on existing functionality
  - [ ] Test: All 4 workflow scopes on all 3 orchestrators
  - [ ] Test: Checkpoint resume (interruption → resume from checkpoint)
  - [ ] Test: Error handling (state transitions on failure)
  - [ ] Test: Agent delegation (100% delegation reliability)
  - [ ] Test: Verification checkpoints (file creation validation)
  - [ ] Run full test suite: `.claude/tests/run_all_tests.sh`
  - [ ] Expected: 100% pass rate (zero regressions)
- [ ] **Documentation Completion**: Comprehensive state-based architecture documentation
  - [ ] Update `.claude/docs/concepts/hierarchical_agents.md` with state-aware supervisors
  - [ ] Update `.claude/docs/guides/orchestration-best-practices.md` with state machine patterns
  - [ ] Update `CLAUDE.md` with state-based orchestrator architecture overview
  - [ ] Create `.claude/docs/architecture/state-based-orchestration-overview.md` (1500-2000 lines)
  - [ ] Section: State machine architecture (states, transitions, lifecycle)
  - [ ] Section: Selective state persistence (decision criteria, patterns)
  - [ ] Section: Hierarchical supervisor coordination (checkpoint schema, protocols)
  - [ ] Section: Performance characteristics (benchmarks, trade-offs)
  - [ ] Section: Migration from phase-based to state-based (lessons learned)
  - [ ] Add cross-links between all documentation files
- [ ] **Developer Guides**: Practical guides for using state-based orchestrators
  - [ ] Create `.claude/docs/guides/state-machine-orchestrator-development.md` (800-1200 lines)
  - [ ] Section: Creating new orchestrators using state machine
  - [ ] Section: Adding new states and transitions
  - [ ] Section: Implementing state handlers
  - [ ] Section: Using selective state persistence
  - [ ] Section: Integrating hierarchical supervisors
  - [ ] Section: Troubleshooting state machine issues
  - [ ] Add code examples for each section
- [ ] **Performance Report**: Document achieved improvements
  - [ ] Create `.claude/specs/602_*/reports/performance_validation_report.md`
  - [ ] Section: Code reduction metrics (before/after line counts)
  - [ ] Section: State operation performance (recalculation vs file-based)
  - [ ] Section: Context reduction metrics (supervisor aggregation)
  - [ ] Section: Time savings metrics (parallel execution)
  - [ ] Section: Reliability metrics (file creation, verification)
  - [ ] Section: Regression test results (zero regressions validated)

**Testing**:
```bash
# Run full test suite
bash .claude/tests/run_all_tests.sh
# Expected: 100% pass rate (zero regressions)

# Run performance benchmarks
bash .claude/tests/benchmark_state_machine_performance.sh
# Expected: 39% code reduction, 80% state operation improvement, 95% context reduction, 40-60% time savings

# Test all workflow scopes on all orchestrators
for scope in research-only research-and-plan full debug-only; do
  /coordinate "Test $scope workflow"
done
# Expected: All workflows complete successfully
```

**Expected Duration**: 15-20 hours (2-3 weeks)

**Deliverables**:
- Performance benchmark results (10+ workflows measured)
- `.claude/docs/architecture/state-based-orchestration-overview.md` (1500-2000 lines)
- `.claude/docs/guides/state-machine-orchestrator-development.md` (800-1200 lines)
- Performance validation report (`.claude/specs/602_*/reports/performance_validation_report.md`)
- Updated CLAUDE.md (state-based architecture section)
- Updated orchestration-best-practices.md (state machine patterns)
- Updated hierarchical_agents.md (state-aware supervisors)

**Success Criteria**:
- [ ] 39% code reduction validated (3,420 → 2,100 lines)
- [ ] 80% state operation improvement validated (150ms → 30ms)
- [ ] 95% context reduction validated (supervisor aggregation)
- [ ] 40-60% time savings validated (parallel execution)
- [ ] 100% file creation reliability maintained
- [ ] Zero regressions (100% test pass rate)
- [ ] Comprehensive documentation complete

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (full test suite, 100% pass rate)
- [ ] Git commit created: `feat(602): complete Phase 7 - Performance Validation`
- [ ] Checkpoint saved (state-based refactor complete)

---

## Testing Strategy

### Unit Testing
- **State Machine Tests**: 20+ tests for state transitions, validation, checkpoint persistence
- **Checkpoint Schema Tests**: 15+ tests for v2.0 schema, migration, backward compatibility
- **State Persistence Tests**: 15+ tests for GitHub Actions pattern, performance, fallback
- **Supervisor Checkpoint Tests**: 12+ tests for nested schema, metadata aggregation
- **Total**: 62+ unit tests

### Integration Testing
- **Orchestrator Tests**: All 4 workflow scopes × 3 orchestrators = 12 integration tests
- **Hierarchical Supervisor Tests**: 20+ tests for supervisor coordination, metadata aggregation
- **End-to-End Tests**: 10+ complete workflows with benchmarking
- **Total**: 42+ integration tests

### Regression Testing
- **Existing Test Suite**: All existing orchestration tests must pass (zero regressions)
- **Checkpoint Compatibility**: v1.3 checkpoints must load and migrate correctly
- **Agent Delegation**: 100% delegation reliability maintained
- **Total**: 50+ regression tests

### Performance Testing
- **State Operation Performance**: 80% improvement validated (150ms → 30ms)
- **Code Reduction**: 39% reduction validated (3,420 → 2,100 lines)
- **Context Reduction**: 95% reduction validated (supervisor aggregation)
- **Time Savings**: 40-60% validated (parallel execution)
- **Total**: 10+ performance benchmarks

**Overall Test Coverage**: >80% for all new code

## Documentation Requirements

### Architecture Documentation
- `.claude/docs/architecture/workflow-state-machine.md` (1000-1500 lines) - State machine design
- `.claude/docs/architecture/hierarchical-supervisor-coordination.md` (800-1200 lines) - Supervisor protocols
- `.claude/docs/architecture/state-based-orchestration-overview.md` (1500-2000 lines) - Complete architecture

### Developer Guides
- `.claude/docs/guides/state-machine-migration-guide.md` (600-900 lines) - Migration steps
- `.claude/docs/guides/state-machine-orchestrator-development.md` (800-1200 lines) - Development guide
- `.claude/docs/guides/hierarchical-supervisor-guide.md` (1000-1500 lines) - Supervisor usage

### Reference Documentation
- Updated `.claude/docs/reference/library-api.md` - State machine, state persistence, supervisor APIs
- Updated `CLAUDE.md` - State-based architecture overview
- Updated `.claude/docs/guides/orchestration-best-practices.md` - State machine patterns

### Templates
- `.claude/templates/sub-supervisor-template.md` (400-600 lines) - Supervisor behavioral file template

**Total Documentation**: ~10,000 lines of comprehensive documentation

## Dependencies

### External Dependencies
- Existing `.claude/lib/checkpoint-utils.sh` (828 lines) - Extended for v2.0 schema
- Existing `.claude/lib/workflow-detection.sh` (207 lines) - Used for scope detection
- Existing `.claude/lib/error-handling.sh` (752 lines) - Extended for state-based errors

### Internal Dependencies
- Phase 1 → Phase 2: State machine required for checkpoint schema integration
- Phase 1 → Phase 3: State machine required for state persistence
- Phase 2 → Phase 5: Checkpoint v2.0 required for orchestrator migration
- Phase 3 → Phase 5: State persistence required for orchestrator migration
- Phase 4 → Phase 6: Supervisor checkpoint schema required for supervisor implementation
- Phase 5 → Phase 6: State machine orchestrators required for supervisor integration
- Phase 5, 6 → Phase 7: All components required for performance validation

**Critical Path**: Phase 1 → Phase 2 → Phase 5 → Phase 6 → Phase 7 (longest dependency chain)

## Risk Mitigation

### Risk 1: State Machine Abstraction Increases Complexity
**Probability**: Medium | **Impact**: High

**Mitigation**:
- Keep state machine simple (8 states, clear transitions)
- Provide comprehensive documentation and examples
- Implement gradually (one orchestrator at a time)
- Maintain backward compatibility (v1.3 checkpoints still work)
- Add extensive testing (62+ unit tests)

**Rollback Plan**: Revert to phase-based orchestrators if state machine proves too complex. Checkpoint v2.0 schema supports both approaches.

### Risk 2: Migration Breaks Existing Workflows
**Probability**: Medium | **Impact**: Critical

**Mitigation**:
- Migrate one orchestrator at a time (/coordinate first)
- Run full regression tests after each migration
- Maintain git checkpoints before each migration
- Test all 4 workflow scopes after migration
- Validate zero regressions (100% test pass rate)

**Rollback Plan**: Git revert to pre-migration state if any orchestrator breaks. Each phase is atomic with commit checkpoints.

### Risk 3: File-Based State Introduces I/O Performance Issues
**Probability**: Low | **Impact**: Medium

**Mitigation**:
- Use selective state persistence (only 7 critical items)
- Implement atomic writes (temp file + mv)
- Add graceful degradation (fallback to recalculation)
- Measure performance (80% improvement validated)
- Use append-only logs for benchmarks (JSONL)

**Rollback Plan**: Disable file-based state for specific items if performance degrades. Decision criteria documented for reverting to stateless.

### Risk 4: Supervisor Coordination Adds Complexity
**Probability**: Medium | **Impact**: Medium

**Mitigation**:
- Use conditional invocation (only for ≥4 agents)
- Provide supervisor template (400-600 lines)
- Document supervisor patterns thoroughly
- Test supervisor coordination extensively (20+ tests)
- Maintain flat coordination fallback

**Rollback Plan**: Disable hierarchical supervision and use flat coordination only. Orchestrators support both patterns.

### Risk 5: Checkpoint Schema Migration Breaks Resume
**Probability**: Low | **Impact**: High

**Mitigation**:
- Implement auto-detection (v1.3 vs v2.0)
- Test migration with real v1.3 checkpoints
- Maintain backward compatibility (v1.3 always migrates)
- Add schema validation (reject invalid checkpoints)
- Document migration path clearly

**Rollback Plan**: If v2.0 migration fails, load v1.3 checkpoint directly without state machine features. Phase-based fields still present for compatibility.

## Migration Path for Existing Orchestrators

### Migration Order (Risk-Based)
1. **/coordinate first** (1,084 lines, production-ready, clean architecture) - Lowest risk
   - Expected reduction: 1,084 → 650 lines (40% reduction)
   - Validation: All 4 workflow scopes tested
   - Rollback: Git revert if tests fail
2. **/orchestrate second** (557 lines, experimental, simpler) - Medium risk
   - Expected reduction: 557 → 350 lines (37% reduction)
   - Validation: Experimental features preserved
   - Rollback: Git revert if tests fail
3. **/supervise third** (1,779 lines, development, most complex) - Highest risk
   - Expected reduction: 1,779 → 1,100 lines (38% reduction)
   - Validation: Sequential patterns preserved
   - Rollback: Git revert if tests fail

**Total Expected Code Reduction**: 3,420 → 2,100 lines (39% reduction)

### Testing Requirements Per Migration
- Run full test suite before migration (establish baseline)
- Run full test suite after migration (detect regressions)
- Test all 4 workflow types (research-only, research-and-plan, full, debug-only)
- Validate performance metrics (context usage, execution time, file creation rate)
- Require 100% test pass rate before proceeding to next orchestrator

### Checkpoint Compatibility
- v1.3 checkpoints auto-migrate to v2.0 on load
- v2.0 checkpoints backward compatible (phase fields preserved)
- Migration tested with real checkpoints from all 3 orchestrators
- Schema validation rejects invalid checkpoints

## Success Metrics

### Phase 1 Success Metrics
- [ ] 8 states defined with clear enumeration
- [ ] Transition table validated (all valid transitions defined)
- [ ] 20+ state machine tests passing
- [ ] Documentation complete (workflow-state-machine.md)

### Phase 2 Success Metrics
- [ ] v2.0 schema defined and documented
- [ ] v1.3 → v2.0 migration working (auto-detect and migrate)
- [ ] 15+ checkpoint schema tests passing
- [ ] Backward compatibility maintained

### Phase 3 Success Metrics
- [ ] 7 critical state items identified and documented
- [ ] 70% performance improvement validated (50ms → 15ms)
- [ ] 15+ state persistence tests passing
- [ ] Graceful degradation working

### Phase 4 Success Metrics
- [ ] Supervisor checkpoint schema defined
- [ ] Metadata aggregation algorithm specified
- [ ] 12+ supervisor checkpoint tests passing
- [ ] Template validated (research-sub-supervisor.md created)

### Phase 5 Success Metrics
- [ ] 40% code reduction (3,420 → 2,100 lines)
- [ ] Zero regressions (all existing tests passing)
- [ ] All 4 workflow scopes working
- [ ] Migration guide complete

### Phase 6 Success Metrics
- [ ] 95% context reduction through research supervisor
- [ ] 40-60% time savings through implementation supervisor
- [ ] 20+ hierarchical supervisor tests passing
- [ ] Supervisor checkpoint persistence working

### Phase 7 Success Metrics
- [ ] Performance validated (all targets met)
- [ ] Zero regressions (100% test pass rate)
- [ ] Comprehensive documentation complete
- [ ] Performance report published

### Overall Success Metrics
- [ ] **Code Reduction**: 39% reduction (3,420 → 2,100 lines)
- [ ] **State Operation Performance**: 80% improvement (150ms → 30ms)
- [ ] **Context Reduction**: 95% via supervisor aggregation
- [ ] **Time Savings**: 40-60% via parallel execution
- [ ] **Reliability**: 100% file creation rate maintained
- [ ] **Test Coverage**: >80% for all new code
- [ ] **Zero Regressions**: 100% existing test pass rate
- [ ] **Documentation**: 10,000+ lines of comprehensive documentation

## Next Steps

Once approved, implementation can proceed via:

```bash
# Begin Phase 1 implementation
/implement /home/benjamin/.config/.claude/specs/602_601_and_documentation_in_claude_docs_in_order_to/plans/001_state_based_orchestrator_refactor.md
```

**Expected Outcomes**:
- ✅ 39% code reduction across orchestrators (3,420 → 2,100 lines)
- ✅ Explicit state machine architecture (8 states, clear transitions)
- ✅ Selective file-based state (7 critical items, 5x faster for expensive ops)
- ✅ Formalized checkpoint schema v2.0 (state machine first-class)
- ✅ State-aware hierarchical supervisors (95% context reduction)
- ✅ 40-60% time savings via parallel execution
- ✅ 100% file creation reliability maintained
- ✅ Zero regressions on existing workflows
- ✅ Comprehensive documentation (10,000+ lines)
- ✅ Industry-standard state management (GitHub Actions pattern)
- ✅ Elegant, maintainable architecture (reduced needless complexity)
