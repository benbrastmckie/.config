# /coordinate Command Architecture Analysis

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: /coordinate command architecture, state machine patterns, and workflow scope detection
- **Report Type**: Codebase analysis and architectural review
- **Complexity Level**: 2

## Executive Summary

The /coordinate command implements a state-based orchestration architecture using an 8-state finite state machine (initialize → research → plan → implement → test → debug → document → complete). The architecture achieves 48.9% code reduction across orchestrators through centralized state management libraries, workflow scope detection for automatic phase selection (4 workflow types: research-only, research-and-plan, full-implementation, debug-only), and selective file-based state persistence that delivers 67% performance improvement. Extension points for new workflow types exist at the workflow-scope-detection.sh pattern matching layer and state machine transition table.

## Findings

### 1. Core Architecture Components

The /coordinate command architecture consists of five primary components working together:

#### 1.1 State Machine Library (`/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`)

**Purpose**: Provides formal finite state machine abstraction for workflow orchestration

**Key Functions**:
- `sm_init(workflow_desc, command_name)` - Initialize state machine from workflow description (lines 86-130)
- `sm_transition(next_state)` - Validate and execute state transitions with two-phase commit (lines 224-263)
- `sm_load(checkpoint_file)` - Restore state machine from checkpoint with v1.3→v2.0 migration (lines 135-213)
- `sm_save(checkpoint_file)` - Save state machine to checkpoint in v2.0 schema (lines 349-416)

**State Enumeration** (8 core states, lines 36-43):
```bash
STATE_INITIALIZE="initialize"    # Phase 0: Setup, scope detection, path pre-calculation
STATE_RESEARCH="research"         # Phase 1: Research topic via specialist agents
STATE_PLAN="plan"                 # Phase 2: Create implementation plan
STATE_IMPLEMENT="implement"       # Phase 3: Execute implementation
STATE_TEST="test"                 # Phase 4: Run test suite
STATE_DEBUG="debug"               # Phase 5: Debug failures (conditional)
STATE_DOCUMENT="document"         # Phase 6: Update documentation (conditional)
STATE_COMPLETE="complete"         # Phase 7: Finalization, cleanup
```

**Transition Table** (lines 50-59):
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

**Key Architectural Principle**: Explicit state names replace implicit phase numbers, enabling fail-fast validation and clear state transitions.

#### 1.2 Workflow Scope Detection (`/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh`)

**Purpose**: Determine workflow scope from user description using pattern matching

**Detection Function** (lines 12-47):
```bash
detect_workflow_scope() {
  local workflow_description="$1"
  local scope="research-and-plan"  # Default fallback

  # Order matters: check more specific patterns first
  # Pattern 1: research-only (no action keywords)
  # Pattern 2: research-and-plan (has "plan" keyword)
  # Pattern 3: debug-only (has "fix|debug|troubleshoot")
  # Pattern 4: full-implementation (has "implement|build|add")
}
```

**Supported Workflow Types** (4 scopes):

1. **research-only**: Pure research with no implementation
   - Pattern: `^research.*` WITHOUT `(plan|implement|fix|debug|create|add|build)`
   - Example: "research authentication patterns"
   - States executed: initialize → research → complete

2. **research-and-plan**: Research followed by planning (MOST COMMON)
   - Pattern: `(plan|create.*plan|design)`
   - Example: "research auth to create plan"
   - States executed: initialize → research → plan → complete

3. **full-implementation**: Complete development workflow
   - Pattern: `(implement|build|add).*feature`
   - Example: "implement OAuth2 authentication"
   - States executed: initialize → research → plan → implement → test → [debug] → document → complete

4. **debug-only**: Debugging existing code
   - Pattern: `(fix|debug|troubleshoot)`
   - Example: "fix token refresh bug"
   - States executed: initialize → research → debug → complete

**Extension Point for "research-and-revise"**: The pattern matching logic at lines 25-44 can be extended to add a new workflow type by adding a new conditional block that checks for revision-related keywords.

#### 1.3 Workflow Initialization (`/home/benjamin/.config/.claude/lib/workflow-initialization.sh`)

**Purpose**: Consolidated Phase 0 initialization implementing 3-step pattern

**Core Function** (lines 85-310):
```bash
initialize_workflow_paths(workflow_description, workflow_scope) {
  # STEP 1: Scope validation (silent - coordinate.md displays summary)
  # STEP 2: Path pre-calculation (all artifact paths calculated upfront)
  # STEP 3: Directory structure creation (lazy: only topic root created)
}
```

**Path Pre-Calculation** (lines 235-268):
- Research phase: 4 report paths pre-calculated (`REPORT_PATH_0` through `REPORT_PATH_3`)
- Planning phase: Plan path with descriptive naming (`${topic_num}_${topic_name}_plan.md`)
- Implementation: Artifacts directory path
- Debug: Debug analysis report path
- Documentation: Summary path

**Subprocess Isolation Pattern** (lines 244-249):
```bash
# Arrays cannot be exported across subprocess boundaries, so we export
# individual REPORT_PATH_0, REPORT_PATH_1, etc. variables
export REPORT_PATH_0="${report_paths[0]}"
export REPORT_PATH_1="${report_paths[1]}"
export REPORT_PATH_2="${report_paths[2]}"
export REPORT_PATH_3="${report_paths[3]}"
export REPORT_PATHS_COUNT=4
```

**Reconstruction Helper** (lines 322-346):
```bash
reconstruct_report_paths_array() {
  # Rebuilds REPORT_PATHS array from individual variables in subsequent bash blocks
}
```

#### 1.4 State Persistence (`/home/benjamin/.config/.claude/lib/state-persistence.sh`)

**Purpose**: GitHub Actions-style selective file-based state persistence

**Key Functions** (lines 115-200):
- `init_workflow_state(workflow_id)` - Create state file with initial environment
- `load_workflow_state(workflow_id)` - Source state file to restore variables
- `append_workflow_state(key, value)` - Append new key-value pair (GitHub Actions pattern)

**Performance Characteristics** (lines 42-45):
- CLAUDE_PROJECT_DIR detection: 50ms (git rev-parse) → 15ms (file read) = 67% improvement
- JSON checkpoint write: 5-10ms (atomic write)
- JSON checkpoint read: 2-5ms (cat + jq)
- Graceful degradation overhead: <1ms

**Critical State Items** (lines 47-59):
1. Supervisor metadata - 95% context reduction
2. Benchmark dataset - Phase 3 accumulation
3. Implementation supervisor state - Parallel execution tracking
4. Testing supervisor state - Lifecycle coordination
5. Migration progress - Resumable workflows
6. Performance benchmarks - Phase dependencies
7. POC metrics - Success validation

**State File Pattern** (lines 131-136):
```bash
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh"

cat > "$STATE_FILE" <<EOF
export CLAUDE_PROJECT_DIR="$CLAUDE_PROJECT_DIR"
export WORKFLOW_ID="$workflow_id"
export STATE_FILE="$STATE_FILE"
EOF
```

#### 1.5 Workflow Detection (`/home/benjamin/.config/.claude/lib/workflow-detection.sh`)

**Purpose**: Smart pattern matching for workflow scope detection

**Detection Algorithm** (lines 74-80):
1. Test ALL patterns against the prompt simultaneously
2. Collect phase requirements from all matching patterns
3. Compute union of required phases
4. Select minimal workflow type that includes all required phases

**Pattern Phase Mappings** (lines 24-29):
- research-only: phases {0, 1}
- research-and-plan: phases {0, 1, 2}
- full-implementation: phases {0, 1, 2, 3, 4, 6} + conditional {5}
- debug-only: phases {0, 1, 5}

**Selection Priority** (lines 30-35):
1. If phases include {3} → full-implementation (largest workflow)
2. If phases include {5} but not {3} → debug-only
3. If phases include {2} → research-and-plan
4. If phases include only {0, 1} → research-only

**Conditional Phases** (runtime logic, lines 36-39):
- Phase 5 (Debug): Runs only if Phase 4 (Testing) fails
- Phase 4 (Testing): Always runs if Phase 3 (Implementation) runs
- Phase 6 (Documentation): Runs only if 100% of tests pass

### 2. /coordinate Command Structure

The command file (`/home/benjamin/.config/.claude/commands/coordinate.md`) implements a two-part initialization pattern followed by state-based handlers.

#### 2.1 Two-Part Initialization Pattern (lines 17-242)

**Part 1: Workflow Description Capture** (lines 17-38):
```bash
# STEP 1: Capture workflow description to file
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > "${HOME}/.claude/tmp/coordinate_workflow_desc.txt"
```

**Why This Pattern**: Avoids positional parameter issues across bash block boundaries. The description is written to a fixed-location file that persists between subprocess invocations.

**Part 2: Main State Machine Initialization** (lines 42-242):
1. Read workflow description from file (lines 62-80)
2. Save description before sourcing libraries (lines 82-85)
3. Source state machine and persistence libraries (lines 88-104)
4. Initialize workflow state file (lines 109-114)
5. Initialize state machine (line 124)
6. Source required libraries based on scope (lines 134-155)
7. Initialize workflow paths (lines 168-172)
8. Verify state persistence (lines 203-218)
9. Transition to research state (lines 221-222)

**Critical Save-Before-Source Pattern** (lines 82-85):
```bash
# CRITICAL: Save workflow description BEFORE sourcing libraries
# Libraries pre-initialize WORKFLOW_DESCRIPTION="" which overwrites parent value
SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"
export SAVED_WORKFLOW_DESC
```

**Performance Instrumentation** (lines 50-240):
```bash
PERF_START_TOTAL=$(date +%s%N)
# ... initialization logic ...
PERF_END_INIT=$(date +%s%N)
PERF_TOTAL_MS=$(( (PERF_END_INIT - PERF_START_TOTAL) / 1000000 ))
echo "Total init overhead: ${PERF_TOTAL_MS}ms"
```

#### 2.2 State Handler Pattern

Each state has a dedicated bash block section that:
1. Re-sources libraries (functions lost across bash blocks)
2. Loads workflow state from fixed location
3. Verifies current state matches expected state
4. Executes state-specific logic (usually agent invocation)
5. Performs mandatory verification checkpoint
6. Transitions to next state

**Research State Handler** (lines 244-661):
- Determine research complexity (1-4 topics) based on workflow keywords (lines 301-314)
- Choose hierarchical (≥4 topics) vs flat (<4 topics) coordination (lines 321-334)
- Invoke research-specialist agents in parallel (lines 369-390)
- Verify all research reports created (lines 548-601)
- Transition to plan or complete based on scope (lines 638-658)

**Planning State Handler** (lines 663-924):
- Reconstruct report paths from state (lines 718-721)
- Invoke plan-architect agent with research reports (lines 732-758)
- Verify plan file created at expected path (lines 811-854)
- Transition to implement or complete based on scope (lines 896-921)

**Implementation State Handler** (lines 926-1067):
- Invoke /implement command via Task tool (lines 984-1002)
- Record implementation complete checkpoint (lines 1036-1060)
- Transition to test state (lines 1062-1064)

**Testing State Handler** (lines 1069-1188):
- Run comprehensive test suite (lines 1126-1134)
- Save test exit code to state (lines 1136-1137)
- Transition to debug (if tests failed) or document (if tests passed) (lines 1170-1187)

**Debug State Handler** (lines 1190-1375):
- Invoke /debug command for test failure analysis (lines 1248-1263)
- Verify debug report created (lines 1300-1331)
- Transition to complete (manual fix required) (lines 1364-1373)

**Documentation State Handler** (lines 1377-1515):
- Invoke /document command to update docs (lines 1435-1450)
- Transition to complete (lines 1508-1510)

### 3. Bash Block Execution Model

The architecture uses subprocess isolation where each bash block runs in a separate process. This constrains how state can be managed.

**Subprocess Isolation Constraint** (discovered in Specs 620/630):
- Each bash block = new bash process
- Variables from previous blocks are NOT inherited
- Arrays cannot be exported across boundaries
- File-based persistence required for cross-block state

**Save-Before-Source Pattern** (lines 82-85 in coordinate.md):
```bash
SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"
export SAVED_WORKFLOW_DESC
# Source libraries (which reset WORKFLOW_DESCRIPTION="")
# Use SAVED_WORKFLOW_DESC in subsequent calls
```

**Fixed Semantic Filenames** (lines 64, 113):
```bash
COORDINATE_DESC_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc.txt"
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
# NOT using $$ which changes per bash block
```

**Library Re-sourcing Pattern** (every state handler):
```bash
# Re-source libraries (functions lost across bash block boundaries)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
```

### 4. Extension Points for "Research-and-Revise" Workflow

To add a new workflow type like "research-and-revise", modifications would be needed at four layers:

#### 4.1 Workflow Scope Detection Layer

**File**: `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh`

**Extension Point**: Lines 23-44 (pattern matching section)

**Proposed Addition**:
```bash
# Pattern 5: Research-and-revise
# Keywords: "research...and revise", "analyze...for revision"
# Phases: {0, 1, 2} (same as research-and-plan but different terminal behavior)
if echo "$workflow_desc" | grep -Eiq "(research|analyze).*(and |for |to ).*(revise|revision|update.*plan)"; then
  match_research_revise=1
fi
```

**Selection Logic Update** (after line 150):
```bash
# If revision needed → research-and-revise
if [ $needs_revision -eq 1 ]; then
  echo "research-and-revise"
  return
fi
```

#### 4.2 State Machine Transition Table

**File**: `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`

**No changes needed** - research-and-revise would use same state transitions as research-and-plan:
- initialize → research → plan → complete
- The "revise" behavior happens within the plan state by invoking /revise instead of /plan

#### 4.3 Terminal State Mapping

**File**: `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`

**Extension Point**: Lines 104-121 (sm_init function)

**Proposed Addition**:
```bash
case "$WORKFLOW_SCOPE" in
  research-only)
    TERMINAL_STATE="$STATE_RESEARCH"
    ;;
  research-and-plan)
    TERMINAL_STATE="$STATE_PLAN"
    ;;
  research-and-revise)
    TERMINAL_STATE="$STATE_PLAN"  # Same terminal as research-and-plan
    ;;
  full-implementation)
    TERMINAL_STATE="$STATE_COMPLETE"
    ;;
  debug-only)
    TERMINAL_STATE="$STATE_DEBUG"
    ;;
esac
```

#### 4.4 Planning State Handler

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`

**Extension Point**: Lines 732-758 (plan-architect invocation)

**Proposed Modification**:
```bash
# Check workflow scope to determine planning vs revision
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
  # Invoke /revise command instead of plan-architect
  # Task invocation for revise-architect agent
else
  # Existing plan-architect invocation
fi
```

### 5. Verification and Error Handling Patterns

The architecture implements fail-fast verification checkpoints throughout.

#### 5.1 Mandatory Verification Checkpoints

**Research Phase** (lines 548-601):
```bash
# ===== MANDATORY VERIFICATION CHECKPOINT: Flat Research =====
VERIFICATION_FAILURES=0
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  if verify_file_created "$REPORT_PATH" ...; then
    SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
  else
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
    FAILED_REPORT_PATHS+=("$REPORT_PATH")
  fi
done

if [ $VERIFICATION_FAILURES -gt 0 ]; then
  handle_state_error "Research specialists failed to create expected artifacts" 1
fi
```

**Planning Phase** (lines 811-854):
```bash
# ===== MANDATORY VERIFICATION CHECKPOINT: Planning Phase =====
if verify_file_created "$PLAN_PATH" "Implementation plan" "Planning"; then
  VERIFICATION_FAILED=false
else
  VERIFICATION_FAILED=true
fi

if [ "$VERIFICATION_FAILED" = "true" ]; then
  echo "TROUBLESHOOTING:"
  echo "1. Review /plan command output..."
  handle_state_error "/plan command failed to create expected plan file" 1
fi
```

#### 5.2 State Verification Pattern

Every state handler begins with verification (lines 283-294, 701-712, etc.):
```bash
# Verify we're in expected state
if [ "$CURRENT_STATE" != "$STATE_RESEARCH" ]; then
  echo "ERROR: Expected state '$STATE_RESEARCH' but current state is '$CURRENT_STATE'"
  exit 1
fi
```

#### 5.3 Checkpoint Requirements

After each phase, a checkpoint summary is displayed (lines 607-636):
```bash
# ===== CHECKPOINT REQUIREMENT: Research Phase Complete =====
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: Research Phase Complete"
echo "═══════════════════════════════════════════════════════"
echo "  Artifacts Created:"
echo "    - Research reports: ${#SUCCESSFUL_REPORT_PATHS[@]}/$RESEARCH_COMPLEXITY"
echo "  Next Action:"
echo "    - Proceeding to: Planning phase"
echo "═══════════════════════════════════════════════════════"
```

### 6. Agent Delegation Pattern

The /coordinate command delegates work to specialized agents using the Task tool with behavioral injection.

#### 6.1 Research Specialist Invocation

**Flat Research** (lines 369-390):
```bash
Task {
  subagent_type: "general-purpose"
  description: "Research [topic name] with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [actual topic name]
    - Report Path: [REPORT_PATHS[$i-1] for topic $i]
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: [RESEARCH_COMPLEXITY value]

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [exact absolute path to report file]
  "
}
```

**Key Pattern Elements**:
- Behavioral file reference at top of prompt
- Workflow-specific context section
- Absolute paths for all file locations
- Expected return format specified
- Timeout appropriate for research depth

#### 6.2 Research Specialist Behavioral File

**File**: `/home/benjamin/.config/.claude/agents/research-specialist.md`

**Execution Process** (lines 24-198):

**STEP 1** - Receive and verify report path (lines 24-45):
```bash
REPORT_PATH="[PATH PROVIDED IN YOUR PROMPT]"
if [[ ! "$REPORT_PATH" =~ ^/ ]]; then
  echo "CRITICAL ERROR: Path is not absolute: $REPORT_PATH"
  exit 1
fi
```

**STEP 1.5** - Ensure parent directory exists (lines 47-70):
```bash
source .claude/lib/unified-location-detection.sh
ensure_artifact_directory "$REPORT_PATH"
```

**STEP 2** - Create report file FIRST (lines 72-118):
```markdown
# [Topic] Research Report

## Metadata
## Executive Summary
[Placeholder]
## Findings
[Will be filled]
## Recommendations
## References
```

**STEP 3** - Conduct research and update report (lines 120-145)

**STEP 4** - Verify and return confirmation (lines 147-198):
```bash
if [ ! -f "$REPORT_PATH" ]; then
  echo "CRITICAL ERROR: Report file not found"
  exit 1
fi

# Return ONLY path confirmation
REPORT_CREATED: [EXACT ABSOLUTE PATH FROM STEP 1]
```

**28 Completion Criteria** (lines 322-411):
- 5 file creation requirements
- 7 content completeness requirements
- 5 research quality requirements
- 6 process compliance requirements
- 4 return format requirements
- 1 verification command requirement

### 7. Performance Characteristics

**Code Reduction**: 48.9% (3,420 → 1,748 lines across 3 orchestrators)
- /coordinate: 1,084 → 800 lines (26.2%)
- /orchestrate: 557 → 551 lines (1.1%)
- /supervise: 1,779 → 397 lines (77.7%)

**State Operation Performance**: 67% improvement (6ms → 2ms for CLAUDE_PROJECT_DIR detection)

**Context Reduction**: 95.6% via hierarchical supervisors (10,000 → 440 tokens)

**Time Savings**: 53% via parallel execution

**Reliability Metrics**:
- Agent delegation rate: >90%
- File creation reliability: 100% (mandatory verification checkpoints)
- Bootstrap reliability: 100% (fail-fast exposes configuration errors)

## Recommendations

### 1. Extend Workflow Scope Detection for "Research-and-Revise"

Add new workflow pattern to `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh`:

```bash
# Pattern 5: Research-and-revise
# Keywords: "research...and revise", "research...then update plan"
# Phases: {0, 1, 2} (same states as research-and-plan)
if echo "$workflow_desc" | grep -Eiq "(research|analyze).*(and |then |to ).*(revise|update.*plan|modify.*plan)"; then
  match_research_revise=1
fi
```

**Rationale**: Keeps detection logic centralized and follows existing pattern matching conventions.

**Location**: After line 44 in workflow-scope-detection.sh

### 2. Modify Planning State Handler to Support Revision

Update `/home/benjamin/.config/.claude/commands/coordinate.md` planning state handler (lines 732-758) to check workflow scope:

```bash
# Determine planning vs revision based on scope
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
  # Invoke /revise agent instead of plan-architect
  Task {
    subagent_type: "general-purpose"
    description: "Revise existing plan based on research findings"
    prompt: "
      Read and follow ALL behavioral guidelines from:
      /home/benjamin/.config/.claude/agents/revise-architect.md

      **Workflow-Specific Context**:
      - Research Reports: ${REPORT_PATHS[@]}
      - Existing Plan Path: [to be determined - needs discovery logic]
      - Revision Scope: $WORKFLOW_DESCRIPTION

      Return: PLAN_REVISED: [path]
    "
  }
else
  # Existing plan-architect invocation for new plans
fi
```

**Rationale**: Reuses existing state handler structure while branching logic based on workflow scope.

**Location**: Lines 732-758 in coordinate.md

### 3. Add Plan Discovery Logic for Revision Workflows

The research-and-revise workflow needs to discover which plan to revise. Add to workflow-initialization.sh:

```bash
# For research-and-revise scope, discover most recent plan
if [ "$workflow_scope" = "research-and-revise" ]; then
  # Find most recent plan file in topic directory
  EXISTING_PLAN=$(find "$topic_path/plans" -name "*.md" -type f -print0 |
                  xargs -0 ls -t | head -1)

  if [ -z "$EXISTING_PLAN" ]; then
    echo "ERROR: research-and-revise requires existing plan but none found" >&2
    return 1
  fi

  export EXISTING_PLAN_PATH="$EXISTING_PLAN"
fi
```

**Rationale**: Revision workflows operate on existing plans, so discovery logic is needed before the planning state handler executes.

**Location**: Add after line 256 in workflow-initialization.sh (after plan_path calculation)

### 4. Create Revise-Architect Agent Behavioral File

Create new agent file `.claude/agents/revise-architect.md` following the research-specialist pattern:

**Key Sections**:
- STEP 1: Receive and verify existing plan path and research report paths
- STEP 2: Read existing plan to understand current structure
- STEP 3: Analyze research reports for relevant findings
- STEP 4: Update plan file with revisions (using Edit tool, not Write)
- STEP 5: Verify changes and return confirmation

**Critical Differences from Plan-Architect**:
- Uses Edit tool instead of Write (modifying existing file)
- Must preserve plan structure and completed phases
- Focuses on incorporating new research findings
- Returns PLAN_REVISED instead of PLAN_CREATED

**Rationale**: Revision logic is sufficiently different from plan creation to warrant a dedicated agent with revision-specific behavioral guidelines.

### 5. Update State Machine Terminal State Mapping

Add research-and-revise to terminal state mapping in workflow-state-machine.sh (line 117):

```bash
case "$WORKFLOW_SCOPE" in
  research-only)
    TERMINAL_STATE="$STATE_RESEARCH"
    ;;
  research-and-plan)
    TERMINAL_STATE="$STATE_PLAN"
    ;;
  research-and-revise)
    TERMINAL_STATE="$STATE_PLAN"  # Same terminal as research-and-plan
    ;;
  # ... existing cases ...
esac
```

**Rationale**: research-and-revise has same state sequence as research-and-plan (initialize → research → plan → complete), just different behavior in the plan state.

**Location**: Lines 104-121 in workflow-state-machine.sh

## References

### Core Architecture Files
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` - State machine implementation (lines 1-508)
- `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh` - Scope detection (lines 1-50)
- `/home/benjamin/.config/.claude/lib/workflow-detection.sh` - Pattern matching algorithm (lines 1-207)
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh` - Phase 0 initialization (lines 1-347)
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` - GitHub Actions-style persistence (lines 1-200)

### Command Implementation
- `/home/benjamin/.config/.claude/commands/coordinate.md` - Main orchestrator (lines 1-1525)

### Agent Behavioral Files
- `/home/benjamin/.config/.claude/agents/research-specialist.md` - Research agent (lines 1-671)

### Documentation
- `/home/benjamin/.config/CLAUDE.md` - Project standards and architecture overview
- `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md` - Complete architecture reference (mentioned in CLAUDE.md)
- `/home/benjamin/.config/.claude/docs/guides/state-machine-orchestrator-development.md` - Development guide (mentioned in CLAUDE.md)
