# Coordinate Command Infrastructure Analysis

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: Current .claude/ infrastructure analysis for coordinate command
- **Report Type**: Codebase analysis
- **Complexity Level**: 3

## Executive Summary

The `/coordinate` command uses a sophisticated state-based orchestration architecture with 58 library files totaling 1,505 lines for the command itself. The infrastructure is built on three pillars: (1) a formal state machine library replacing implicit phase tracking, (2) selective file-based state persistence using GitHub Actions patterns, and (3) comprehensive workflow initialization with path pre-calculation. Key reusable components include verification checkpoints achieving 90% token reduction, unified logging with progress markers, and behavioral injection for agent invocation. The architecture demonstrates mature fail-fast error handling, subprocess isolation patterns, and 95% context reduction through hierarchical supervision.

## Findings

### 1. State Machine Architecture (Core Foundation)

**Location**: `.claude/lib/workflow-state-machine.sh` (508 lines)

**Key Components**:
- **8 explicit states**: initialize, research, plan, implement, test, debug, document, complete
- **Transition table validation**: Prevents invalid state changes via predefined transition rules
- **Atomic state transitions**: Two-phase commit pattern (pre + post checkpoints)
- **Workflow scope integration**: Maps scope (research-only, research-and-plan, full-implementation) to terminal state

**State Transition Logic**:
```bash
# Lines 50-59: Transition table
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

**Validation Pattern** (lines 224-235):
```bash
# Phase 1: Validate transition is allowed
local valid_transitions="${STATE_TRANSITIONS[$CURRENT_STATE]}"

# Check if next_state is in valid_transitions (comma-separated)
if ! echo ",$valid_transitions," | grep -q ",$next_state,"; then
  echo "ERROR: Invalid transition: $CURRENT_STATE → $next_state" >&2
  echo "Valid transitions from $CURRENT_STATE: $valid_transitions" >&2
  return 1
fi
```

**Key Functions**:
- `sm_init()`: Initialize state machine from workflow description
- `sm_transition()`: Validate and execute state transitions
- `sm_load()`: Load state from checkpoint (supports v1.3→v2.0 migration)
- `sm_save()`: Save state machine to checkpoint file
- `sm_is_terminal()`: Check if workflow complete

**Reusability**: Both plans could leverage this state machine for their orchestration logic. The transition table provides clear workflow boundaries and prevents invalid state changes.

---

### 2. State Persistence Library (Performance Optimization)

**Location**: `.claude/lib/state-persistence.sh` (341 lines)

**Architecture**: GitHub Actions-style pattern (`$GITHUB_OUTPUT`, `$GITHUB_STATE`)

**Key Features**:
- **Selective persistence**: Only 7 critical items persisted to files (70% of analyzed state)
- **Performance**: 67% improvement (6ms → 2ms for CLAUDE_PROJECT_DIR detection)
- **Graceful degradation**: Falls back to stateless recalculation if state file missing
- **Atomic writes**: Temp file + mv pattern ensures no partial writes

**Core Functions**:
```bash
# Lines 115-142: Initialize workflow state (Block 1 only)
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
# Creates: .claude/tmp/workflow_${WORKFLOW_ID}.sh

# Lines 168-182: Load workflow state (Blocks 2+)
load_workflow_state "$WORKFLOW_ID"
# Sources state file to restore variables

# Lines 207-217: Append workflow state
append_workflow_state "RESEARCH_COMPLETE" "true"
# Appends: export RESEARCH_COMPLETE="true"
```

**Critical State Items** (lines 47-56 comments):
1. Supervisor metadata (P0): 95% context reduction, non-deterministic research findings
2. Benchmark dataset (P0): Phase 3 accumulation across 10 subprocess invocations
3. Implementation supervisor state (P0): 40-60% time savings via parallel execution tracking
4. Testing supervisor state (P0): Lifecycle coordination across sequential stages
5. Migration progress (P1): Resumable, audit trail for multi-hour migrations
6. Performance benchmarks (P1): Phase 3 dependency on Phase 2 data
7. POC metrics (P1): Success criterion validation

**JSON Checkpoint Pattern** (lines 240-258):
```bash
# Atomic write using temp file + mv
save_json_checkpoint "supervisor_metadata" "$SUPERVISOR_METADATA"
# File created: .claude/tmp/supervisor_metadata.json

# Load with graceful degradation
METADATA=$(load_json_checkpoint "supervisor_metadata")
# Returns: JSON content if exists, {} if missing
```

**Reusability**: Both plans need subprocess state persistence. This library provides battle-tested patterns for cross-block state management without relying on export (which doesn't work across subprocess boundaries).

---

### 3. Workflow Initialization Library (Path Pre-Calculation)

**Location**: `.claude/lib/workflow-initialization.sh` (347 lines)

**Three-Step Pattern** (lines 85-309):
1. **Scope detection**: Determine workflow type (research-only, research-and-plan, full-implementation)
2. **Path pre-calculation**: Calculate all artifact paths upfront (85% token reduction vs agent-based detection)
3. **Directory structure creation**: Lazy creation (only topic root initially)

**Key Function** (lines 85-310):
```bash
initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"

# Exports (35+ variables):
# - LOCATION, PROJECT_ROOT, SPECS_ROOT
# - TOPIC_NUM, TOPIC_NAME, TOPIC_PATH
# - REPORT_PATHS (array serialized to REPORT_PATH_0..REPORT_PATH_3)
# - PLAN_PATH, IMPL_ARTIFACTS, DEBUG_REPORT, SUMMARY_PATH
# - Tracking: SUCCESSFUL_REPORT_COUNT, TESTS_PASSING
```

**Idempotent Topic Creation** (uses `topic-utils.sh`):
```bash
# Lines 152-157: Calculate topic metadata
topic_name=$(sanitize_topic_name "$workflow_description")
topic_num=$(get_or_create_topic_number "$specs_root" "$topic_name")

# get_or_create_topic_number() checks for existing topics first
# Prevents topic number incrementing on each bash block invocation
```

**Subprocess Isolation Pattern** (lines 236-249):
```bash
# Arrays cannot be exported across subprocess boundaries
# Solution: Serialize to individual variables
export REPORT_PATH_0="${report_paths[0]}"
export REPORT_PATH_1="${report_paths[1]}"
export REPORT_PATH_2="${report_paths[2]}"
export REPORT_PATH_3="${report_paths[3]}"
export REPORT_PATHS_COUNT=4

# Reconstruction function for subsequent blocks
reconstruct_report_paths_array() {
  REPORT_PATHS=()
  for i in $(seq 0 $((REPORT_PATHS_COUNT - 1))); do
    var_name="REPORT_PATH_$i"
    REPORT_PATHS+=("${!var_name}")
  done
}
```

**Reusability**: The path pre-calculation pattern eliminates 85% of context overhead. Both plans should use this initialization pattern for deterministic artifact locations.

---

### 4. Verification Checkpoint Pattern (Fail-Fast Enforcement)

**Location**: `.claude/lib/verification-helpers.sh` (130 lines)

**Token Reduction**: 90% reduction at checkpoints (38 lines → 1 line, ~3,150 tokens saved per workflow)

**Core Function** (lines 73-126):
```bash
verify_file_created "$file_path" "$item_desc" "$phase_name"

# Success path: Single character output
if [ -f "$file_path" ] && [ -s "$file_path" ]; then
  echo -n "✓"  # No newline - allows multiple checks on one line
  return 0
else
  # Failure path: 38-line diagnostic with directory analysis, fix commands
  return 1
fi
```

**Usage Pattern in coordinate.md** (lines 542-545):
```bash
echo -n "  Report $i/$RESEARCH_COMPLEXITY: "
if verify_file_created "$REPORT_PATH" "Research report $i" "Research"; then
  FILE_SIZE=$(stat -f%z "$REPORT_PATH" 2>/dev/null || echo "unknown")
  echo " verified ($FILE_SIZE bytes)"
else
  VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
fi
```

**Diagnostic Output on Failure**:
- Error header with phase and description
- Expected vs found status (file missing vs empty)
- Directory diagnostic (exists, file count, recent files)
- Actionable fix commands

**Integration Count**: Used 14 times in coordinate.md (lines 200-257, 468-518, 529-579, 792-835, etc.)

**Reusability**: Essential for both plans. Provides standardized verification with detailed diagnostics only on failure.

---

### 5. Agent Invocation Patterns (Behavioral Injection)

**Pattern**: Task tool invocation with behavioral file references (not SlashCommand)

**Example from coordinate.md** (lines 379-395):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Coordinate research across 4+ topics with 95% context reduction"
  timeout: 600000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-sub-supervisor.md

    **Supervisor Inputs**:
    - Topics: [comma-separated list of $RESEARCH_COMPLEXITY topics]
    - Output directory: $TOPIC_PATH/reports
    - State file: $STATE_FILE
    - Supervisor ID: research_sub_supervisor_$(date +%s)

    **CRITICAL**: Invoke all research-specialist workers in parallel, aggregate metadata, save supervisor checkpoint.

    Return: SUPERVISOR_COMPLETE: {supervisor_id, aggregated_metadata}
  "
}
```

**Key Characteristics**:
1. **Imperative instructions**: "Read and follow ALL behavioral guidelines"
2. **Direct reference**: Absolute path to behavioral file (`.claude/agents/*.md`)
3. **Explicit completion signals**: `REPORT_CREATED:`, `SUPERVISOR_COMPLETE:`, etc.
4. **Context injection**: Pass workflow-specific variables (TOPIC_PATH, STATE_FILE, etc.)

**Agent Count**: 22 specialized agents in `.claude/agents/`
- research-specialist.md: Codebase research, report creation
- plan-architect.md: Implementation plan creation
- research-sub-supervisor.md: Hierarchical research coordination (≥4 topics)
- implementation-sub-supervisor.md: Parallel implementation coordination
- testing-sub-supervisor.md: Sequential test lifecycle coordination

**Verification Pattern** (Standard 11: Imperative Agent Invocation):
- Validation library: `.claude/lib/validate-agent-invocation-pattern.sh`
- Test suite: `.claude/tests/test_orchestration_commands.sh`
- Anti-pattern detection: No code block wrappers, no documentation-only YAML

**Reusability**: Both plans need agent delegation. The behavioral injection pattern ensures reliable invocation with explicit completion signals.

---

### 6. Library Sourcing Infrastructure

**Location**: `.claude/lib/library-sourcing.sh` (122 lines)

**Pattern**: Consolidated sourcing with deduplication (lines 42-121)
```bash
source_required_libraries() {
  local libraries=(
    "workflow-detection.sh"
    "error-handling.sh"
    "checkpoint-utils.sh"
    "unified-logger.sh"
    "unified-location-detection.sh"
    "metadata-extraction.sh"
    "context-pruning.sh"
  )

  # Deduplicate and source with error tracking
  # Returns 0 on success, 1 on any failure
}
```

**Re-sourcing Pattern in coordinate.md** (lines 298-309, repeated in every bash block):
```bash
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/unified-logger.sh"
source "${LIB_DIR}/verification-helpers.sh"
```

**Source Guard Pattern** (from workflow-state-machine.sh lines 19-23):
```bash
# Source guard: Prevent multiple sourcing
if [ -n "${WORKFLOW_STATE_MACHINE_SOURCED:-}" ]; then
  return 0
fi
export WORKFLOW_STATE_MACHINE_SOURCED=1
```

**Scope-Based Library Loading** (coordinate.md lines 131-144):
```bash
case "$WORKFLOW_SCOPE" in
  research-only)
    REQUIRED_LIBS=("workflow-detection.sh" "unified-logger.sh" "overview-synthesis.sh" "error-handling.sh")
    ;;
  full-implementation)
    REQUIRED_LIBS=("workflow-detection.sh" "unified-logger.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "dependency-analyzer.sh" "context-pruning.sh" "error-handling.sh")
    ;;
esac
```

**Reusability**: Library sourcing pattern essential for both plans. Source guards prevent duplicate sourcing overhead.

---

### 7. Error Handling and Recovery

**Location**: `.claude/lib/error-handling.sh` (estimated 300+ lines based on sample)

**Error Classification** (lines 16-48):
```bash
readonly ERROR_TYPE_TRANSIENT="transient"  # Retry with backoff
readonly ERROR_TYPE_PERMANENT="permanent"  # Code-level fixes needed
readonly ERROR_TYPE_FATAL="fatal"          # User intervention required

classify_error() {
  local error_message="${1:-}"

  # Transient: locked, busy, timeout, temporary
  # Fatal: out of space, disk full, permission denied
  # Default: permanent (code-level issues)
}
```

**Recovery Suggestions** (lines 54-77):
```bash
suggest_recovery() {
  case "$error_type" in
    "$ERROR_TYPE_TRANSIENT")
      echo "Retry with exponential backoff (2-3 attempts)"
      ;;
    "$ERROR_TYPE_PERMANENT")
      echo "Analyze error message for code-level issues"
      echo "Consider using /debug for investigation"
      ;;
    "$ERROR_TYPE_FATAL")
      echo "User intervention required"
      echo "Check system resources (disk space, permissions)"
      ;;
  esac
}
```

**State Error Handler** (used throughout coordinate.md):
```bash
handle_state_error "Workflow initialization failed" 1
# Logs error, suggests recovery, exits with code 1
```

**Reusability**: Error classification and recovery suggestions apply to both plans. Provides consistent error reporting with actionable diagnostics.

---

### 8. Unified Logging (Progress and Metrics)

**Location**: `.claude/lib/unified-logger.sh` (estimated 400+ lines based on sample)

**Progress Markers** (lines 54-130):
```bash
# Log rotation (10MB max, 5 files retained)
rotate_log_file "$log_file" "$max_size" "$max_files"

# Structured logging
write_log_entry "INFO" "trigger_eval" "$message" "$metrics"
# Format: [timestamp] LEVEL event_type: message | data=json
```

**Progress Emission Pattern** (used in coordinate.md):
```bash
emit_progress "1" "State: Research (parallel agent invocation)"
emit_progress "2" "Research complete, transitioning to Planning"
emit_progress "3" "Planning complete, transitioning to Implementation"
```

**Display Functions**:
- `display_brief_summary()`: End-of-workflow summary
- `emit_progress()`: Phase progress markers
- `log_complexity_check()`: Adaptive planning metrics
- `log_trigger_evaluation()`: Replan trigger analysis

**Reusability**: Both plans need progress visibility. Unified logging provides consistent output format across all orchestration commands.

---

### 9. Topic Utilities (Deterministic Naming)

**Location**: `.claude/lib/topic-utils.sh` (estimated 300+ lines based on sample)

**Key Functions** (lines 18-58):
```bash
# Get next topic number (001, 002, 003...)
get_next_topic_number "$specs_root"

# Idempotent topic creation (reuses existing if found)
get_or_create_topic_number "$specs_root" "$topic_name"

# Sanitize workflow description to valid topic name
sanitize_topic_name "Research the nvim/docs directory"
# Returns: "nvim_docs_directory"
```

**Sanitization Algorithm** (lines 78-100):
1. Extract path components (last 2-3 meaningful segments)
2. Remove full paths from description
3. Convert to lowercase
4. Remove filler prefixes ("carefully research", "analyze", etc.)
5. Remove stopwords (preserving action verbs and technical terms)
6. Combine path components with cleaned description
7. Clean up formatting (multiple underscores, leading/trailing)
8. Intelligent truncation (preserve whole words, max 50 chars)

**Examples**:
- "Research the /home/user/nvim/docs directory" → "nvim_docs_directory"
- "fix the token refresh bug" → "fix_token_refresh_bug"
- "research authentication patterns to create implementation plan" → "authentication_patterns_create_implementation"

**Reusability**: Topic naming consistency critical for both plans. Prevents topic number drift across bash blocks.

---

### 10. Bash Block Execution Model (Subprocess Isolation)

**Documentation**: `.claude/docs/concepts/bash-block-execution-model.md`

**Critical Constraints**:
1. **Subprocess isolation**: Each bash block runs in separate process
2. **No export persistence**: Export doesn't work across block boundaries
3. **No $$ consistency**: Process ID changes per block
4. **No trap inheritance**: EXIT traps don't persist across blocks

**Validated Patterns** (from Specs 620/630):
```bash
# Pattern 1: Fixed semantic filenames (not $$-based)
COORDINATE_DESC_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc.txt"
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"

# Pattern 2: Save-before-source pattern
SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"
export SAVED_WORKFLOW_DESC
# ... source libraries that may overwrite WORKFLOW_DESCRIPTION ...
WORKFLOW_DESCRIPTION="$SAVED_WORKFLOW_DESC"

# Pattern 3: Library re-sourcing in every bash block
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
# ... (source guards prevent redundant execution)
```

**Anti-Patterns to Avoid**:
- $$-based state file IDs (changes per block)
- Assuming export persists (it doesn't)
- Setting traps in sourced functions (immediate cleanup)
- Indirect expansion ${!var} without set +H (Bash tool preprocessing issues)

**Coordinate Implementation** (lines 32-38, 104-113):
```bash
# Part 1: Capture workflow description to fixed file
echo "research auth patterns" > "${HOME}/.claude/tmp/coordinate_workflow_desc.txt"

# Part 2: Read from fixed file (not $$ which changes)
COORDINATE_DESC_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc.txt"
WORKFLOW_DESCRIPTION=$(cat "$COORDINATE_DESC_FILE" 2>/dev/null || echo "")
```

**Reusability**: Understanding subprocess isolation is critical for both plans. The save-before-source and fixed-filename patterns are essential for cross-block state management.

---

## Infrastructure Metrics

### Library Ecosystem
- **Total libraries**: 58 files in `.claude/lib/`
- **Coordinate command**: 1,505 lines
- **State machine library**: 508 lines
- **State persistence library**: 341 lines
- **Workflow initialization**: 347 lines
- **Verification helpers**: 130 lines

### Performance Characteristics
- **State persistence**: 67% improvement (6ms → 2ms)
- **Context reduction**: 95% via hierarchical supervisors
- **Token reduction**: 90% at verification checkpoints (3,150 tokens saved/workflow)
- **Path pre-calculation**: 85% token reduction vs agent-based detection
- **Time savings**: 40-60% via wave-based parallel implementation

### Reliability Metrics
- **Agent delegation rate**: >90% (verified across all orchestration commands)
- **File creation reliability**: 100% (mandatory verification checkpoints)
- **Bootstrap reliability**: 100% (fail-fast exposes configuration errors immediately)
- **Test coverage**: 127 core state machine tests (100% pass rate)

---

## Recommendations

### 1. Leverage State Machine for Both Plans

**Rationale**: The state machine library provides validated transitions, checkpoint coordination, and terminal state detection. Both Plan A (state-based) and Plan B (simplified) benefit from this foundation.

**Implementation**:
- Use `sm_init()` for workflow initialization
- Use `sm_transition()` for state changes (validates transitions automatically)
- Use `sm_is_terminal()` for completion detection
- Use `sm_save()`/`sm_load()` for checkpoint persistence

**Example**:
```bash
sm_init "$WORKFLOW_DESCRIPTION" "coordinate"
# ... execute phase ...
sm_transition "$STATE_RESEARCH"
# ... execute next phase ...
if sm_is_terminal; then
  display_brief_summary
  exit 0
fi
```

---

### 2. Adopt State Persistence Patterns for Cross-Block State

**Rationale**: Subprocess isolation makes export unreliable. State persistence provides battle-tested patterns for cross-block variable sharing.

**Implementation**:
- Use `init_workflow_state()` in first bash block
- Use `load_workflow_state()` in subsequent blocks
- Use `append_workflow_state()` to add new variables
- Use fixed semantic filenames (not $$-based)

**Critical State Items**:
- Workflow ID and description
- Topic paths and artifact locations
- Report paths array (serialized to individual variables)
- Verification counters and phase status

**Example**:
```bash
# Block 1: Initialize
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"

# Block 2+: Load
load_workflow_state "$WORKFLOW_ID"
echo "Loaded TOPIC_PATH: $TOPIC_PATH"
```

---

### 3. Use Workflow Initialization for Path Pre-Calculation

**Rationale**: 85% token reduction vs agent-based detection. Provides deterministic artifact paths for all phases.

**Implementation**:
```bash
initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"
# Exports: TOPIC_PATH, PLAN_PATH, REPORT_PATHS, etc.
```

**Benefits**:
- Idempotent topic creation (prevents number drift)
- Pre-calculated paths for all artifacts
- Lazy directory creation (only topic root initially)
- Subprocess-safe serialization (arrays → individual vars)

---

### 4. Implement Mandatory Verification Checkpoints

**Rationale**: 100% file creation reliability achieved through fail-fast verification. 90% token reduction at checkpoints.

**Implementation**:
```bash
VERIFICATION_FAILURES=0

for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  echo -n "  Report $i: "
  if verify_file_created "$REPORT_PATH" "Research report $i" "Research"; then
    echo " verified"
  else
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
  fi
done

if [ $VERIFICATION_FAILURES -gt 0 ]; then
  handle_state_error "Research artifacts verification failed" 1
fi
```

**Checkpoint Frequency**: After every phase that creates artifacts (research, planning, implementation, debug)

---

### 5. Follow Behavioral Injection Pattern for Agent Invocation

**Rationale**: Standard 11 compliance. Reliable agent invocation with explicit completion signals.

**Implementation**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research topic with mandatory file creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Context**:
    - Report Path: $REPORT_PATH
    - Topic: $RESEARCH_TOPIC

    Return: REPORT_CREATED: $REPORT_PATH
  "
}
```

**Requirements**:
- Direct reference to behavioral file (absolute path)
- Imperative instructions ("Read and follow ALL")
- Context injection (workflow-specific variables)
- Explicit completion signal (REPORT_CREATED:, PLAN_CREATED:, etc.)

---

### 6. Re-Source Libraries in Every Bash Block

**Rationale**: Functions don't persist across subprocess boundaries. Source guards prevent redundant execution overhead.

**Implementation**:
```bash
# Standard re-sourcing block (use in every bash block)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/unified-logger.sh"
source "${LIB_DIR}/verification-helpers.sh"
```

**Pattern Count**: 11 re-sourcing blocks in coordinate.md (once per bash block)

---

### 7. Use Progress Markers for User Visibility

**Rationale**: Provides workflow progress feedback without verbose logging. Essential for long-running orchestrations.

**Implementation**:
```bash
emit_progress "1" "State: Research (parallel agent invocation)"
emit_progress "2" "Research complete, transitioning to Planning"
emit_progress "3" "Planning complete, transitioning to Implementation"
```

**Integration**: Used 7 times in coordinate.md (one per major state transition)

---

### 8. Apply Save-Before-Source Pattern for Variable Protection

**Rationale**: Libraries may pre-initialize variables (e.g., `WORKFLOW_DESCRIPTION=""`), overwriting parent values.

**Implementation**:
```bash
# CRITICAL: Save workflow description BEFORE sourcing libraries
SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"
export SAVED_WORKFLOW_DESC

# Source libraries (may overwrite WORKFLOW_DESCRIPTION)
source "${LIB_DIR}/workflow-state-machine.sh"

# Restore from saved value
sm_init "$SAVED_WORKFLOW_DESC" "coordinate"
```

**Location in coordinate.md**: Lines 79-82, 120-121

---

### 9. Avoid Bash Tool Preprocessing Issues

**Rationale**: The Bash tool preprocesses bash blocks (including history expansion) before sending to interpreter. This causes issues with certain bash features.

**Known Issues**:
- History expansion (`!` operator) causes "bad substitution" errors
- Indirect expansion (`${!var}`) gets corrupted even with `set +H`

**Mitigations**:
```bash
# Disable history expansion (first line of every bash block)
set +H

# Avoid ! operator (use alternative patterns)
# Bad:  if ! verify_file_created "$PATH"; then
# Good: if verify_file_created "$PATH"; then ... else ... fi

# Avoid indirect expansion (use eval instead)
# Bad:  value="${!var_name}"
# Good: eval "value=\$$var_name"
```

**Location in coordinate.md**: Lines 32, 48, 294, etc. (set +H in every bash block)

---

### 10. Implement Checkpoint Requirements After Each Phase

**Rationale**: Provides clear workflow boundaries, verification status, and next actions. Essential for resumable workflows.

**Template**:
```bash
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: [Phase Name] Complete"
echo "═══════════════════════════════════════════════════════"
echo "Phase status before transitioning to next state:"
echo ""
echo "  Artifacts Created:"
echo "    - [List artifacts]"
echo ""
echo "  Verification Status:"
echo "    - [Verification results]"
echo ""
echo "  Next Action:"
echo "    - Proceeding to: [Next phase]"
echo "═══════════════════════════════════════════════════════"
echo ""
```

**Location in coordinate.md**: Lines 587-617 (research), 842-874 (planning), 1017-1040 (implementation), etc.

---

## References

### Core Libraries
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (lines 1-508)
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` (lines 1-341)
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh` (lines 1-347)
- `/home/benjamin/.config/.claude/lib/verification-helpers.sh` (lines 1-130)
- `/home/benjamin/.config/.claude/lib/unified-logger.sh` (lines 1-150+)
- `/home/benjamin/.config/.claude/lib/error-handling.sh` (lines 1-100+)
- `/home/benjamin/.config/.claude/lib/library-sourcing.sh` (lines 1-122)
- `/home/benjamin/.config/.claude/lib/topic-utils.sh` (lines 1-100+)

### Command Implementation
- `/home/benjamin/.config/.claude/commands/coordinate.md` (1,505 lines)
  - State initialization: lines 17-281
  - Research phase: lines 283-642
  - Planning phase: lines 644-905
  - Implementation phase: lines 907-1048
  - Testing phase: lines 1050-1169
  - Debug phase: lines 1171-1356
  - Documentation phase: lines 1358-1496

### Agent Behavioral Files
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (671 lines)
- `/home/benjamin/.config/.claude/agents/plan-architect.md` (150+ lines)
- `/home/benjamin/.config/.claude/agents/research-sub-supervisor.md`
- `/home/benjamin/.config/.claude/agents/implementation-sub-supervisor.md`
- `/home/benjamin/.config/.claude/agents/testing-sub-supervisor.md`

### Documentation
- `.claude/docs/concepts/bash-block-execution-model.md` - Subprocess isolation patterns
- `.claude/docs/architecture/state-based-orchestration-overview.md` - State machine architecture
- `.claude/docs/reference/command_architecture_standards.md` - Standard 11 (behavioral injection)

### Test Suites
- `.claude/tests/test_state_machine.sh` - 127 core tests (100% pass rate)
- `.claude/tests/test_orchestration_commands.sh` - Agent invocation validation
- `.claude/tests/validate_executable_doc_separation.sh` - Pattern compliance

### Specifications
- Spec 620: Bash history expansion errors (bash block execution model discovery)
- Spec 630: State persistence report path fixes (subprocess isolation patterns)
- Spec 602: State-based orchestration performance validation
