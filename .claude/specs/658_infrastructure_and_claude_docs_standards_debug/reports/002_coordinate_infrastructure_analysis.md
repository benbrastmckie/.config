# Coordinate Command Infrastructure Analysis

## Metadata
- **Date**: 2025-11-11
- **Agent**: research-specialist
- **Topic**: Coordinate command infrastructure, state machine patterns, workflow initialization, and verification checkpoint mechanisms
- **Report Type**: codebase analysis

## Executive Summary

The /coordinate command implements a sophisticated state-based orchestration architecture with eight explicit workflow states (initialize, research, plan, implement, test, debug, document, complete), managing multi-agent workflows through subprocess isolation patterns, file-based state persistence, and fail-fast verification checkpoints. The infrastructure achieves 41% initialization overhead reduction through state persistence caching while maintaining 100% reliability through mandatory verification checkpoints and bash block execution constraints. Three research delegation patterns are supported: flat coordination (<4 topics), hierarchical supervision (≥4 topics), and both leverage metadata extraction for 95% context reduction.

## Findings

### 1. Coordinate Command Architecture

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md` (1,630 lines)

**Two-Step Execution Pattern** (Lines 17-244):
- **Part 1: Workflow Description Capture** (Lines 17-38)
  - Captures user's workflow description to fixed location file: `${HOME}/.claude/tmp/coordinate_workflow_desc.txt`
  - Solves positional parameter issues across bash block boundaries
  - Uses `set +H` directive to disable history expansion (prevents bad substitution errors)

- **Part 2: Main Initialization Logic** (Lines 42-244)
  - Reads workflow description from fixed location file
  - Critical pattern: Save workflow description BEFORE sourcing libraries (Line 82-85)
    - Libraries pre-initialize `WORKFLOW_DESCRIPTION=""` which would overwrite parent value
    - Uses `SAVED_WORKFLOW_DESC` variable to preserve value across library sourcing
  - Sources state machine and state persistence libraries
  - Initializes workflow state using GitHub Actions pattern
  - Saves workflow ID to fixed location: `${HOME}/.claude/tmp/coordinate_state_id.txt`
  - NO trap handler in initialization (files must persist for subsequent blocks)

**Performance Tracking** (Lines 50, 158, 174, 234-243):
- Baseline Phase 1 metrics instrumentation
- Three performance markers:
  - Library loading: PERF_AFTER_LIBS
  - Path initialization: PERF_AFTER_PATHS
  - Total initialization: PERF_END_INIT
- Reports: Library loading time, Path initialization time, Total init overhead

**State Machine Initialization** (Lines 86-106):
- Sources workflow-state-machine.sh (provides 8 state constants and transition functions)
- Sources state-persistence.sh (GitHub Actions-style state file management)
- Generates unique workflow ID: `coordinate_$(date +%s)` (timestamp-based for reproducibility)
- Initializes workflow state file via `init_workflow_state()`
- Saves workflow ID, description, scope, and terminal state to workflow state

**Required Library Sourcing** (Lines 131-155):
- Scope-based library loading using library-sourcing.sh
- Four workflow scopes with different library requirements:
  - `research-only`: 7 libraries (detection, logger, location, synthesis, error)
  - `research-and-plan`: 9 libraries (adds metadata, checkpoint)
  - `full-implementation`: 11 libraries (adds dependency, context-pruning)
  - `debug-only`: 9 libraries (same as research-and-plan)

**Path Pre-calculation** (Lines 160-195):
- Sources workflow-initialization.sh
- Calls `initialize_workflow_paths()` with workflow description and scope
- Sets TOPIC_PATH, PLAN_PATH, and 4 REPORT_PATH variables
- Exports individual report path variables (REPORT_PATH_0 through REPORT_PATH_3)
- Serializes report paths array to state (subprocess isolation pattern)

**Mandatory Verification Checkpoint** (Lines 203-218):
- Verifies all REPORT_PATH variables written to state file
- Uses concise verification pattern from verification-helpers.sh
- Builds VARS_TO_CHECK array dynamically (REPORT_PATHS_COUNT + individual paths)
- Calls `verify_state_variables()` - returns ✓ on success, diagnostic on failure
- Fail-fast: exits with `handle_state_error()` if verification fails

**State Transition** (Lines 221-224):
- Transitions from initialize to research state via `sm_transition()`
- Updates workflow state file with new CURRENT_STATE
- Emits timestamp for audit trail

### 2. State Machine Pattern

**File**: `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (513 lines)

**State Enumeration** (Lines 36-43):
- 8 core workflow states (explicit, not implicit phase numbers):
  - STATE_INITIALIZE="initialize" (Phase 0)
  - STATE_RESEARCH="research" (Phase 1)
  - STATE_PLAN="plan" (Phase 2)
  - STATE_IMPLEMENT="implement" (Phase 3)
  - STATE_TEST="test" (Phase 4)
  - STATE_DEBUG="debug" (Phase 5)
  - STATE_DOCUMENT="document" (Phase 6)
  - STATE_COMPLETE="complete" (Phase 7)

**State Transition Table** (Lines 50-59):
- Defines valid state transitions (comma-separated next states)
- Key transitions:
  - research → plan,complete (can skip to complete for research-only)
  - plan → implement,complete (can skip to complete for research-and-plan)
  - test → debug,document (conditional: debug if failed, document if passed)
  - debug → test,complete (retry testing or complete if unfixable)
  - complete → "" (terminal state, no transitions)

**State Machine Variables** (Lines 64-79):
- Uses conditional initialization pattern to preserve values across library re-sourcing:
  - `CURRENT_STATE="${CURRENT_STATE:-${STATE_INITIALIZE}}"`
  - `TERMINAL_STATE="${TERMINAL_STATE:-${STATE_COMPLETE}}"`
  - `WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"`
  - `WORKFLOW_DESCRIPTION="${WORKFLOW_DESCRIPTION:-}"`
  - `COMMAND_NAME="${COMMAND_NAME:-}"`
- Arrays cannot use conditional initialization: `declare -ga COMPLETED_STATES=()`
- Constants remain readonly: `readonly STATE_INITIALIZE="initialize"`

**sm_init()** (Lines 88-135):
- Initializes new state machine from workflow description
- Detects workflow scope using workflow-detection.sh
- Maps scope to terminal state:
  - research-only → STATE_RESEARCH
  - research-and-plan → STATE_PLAN
  - research-and-revise → STATE_PLAN
  - full-implementation → STATE_COMPLETE
  - debug-only → STATE_DEBUG
- Sets CURRENT_STATE to STATE_INITIALIZE
- Clears COMPLETED_STATES array

**sm_transition()** (Lines 229-268):
- Validates transition is allowed via STATE_TRANSITIONS table
- Atomic two-phase commit pattern (pre + post checkpoints)
- Updates CURRENT_STATE variable
- Adds to COMPLETED_STATES history (avoids duplicates)
- Checkpoint coordination placeholders (requires checkpoint-utils.sh integration)

**Checkpoint Schema V2.0** (Lines 393-420):
- `sm_save()` function creates state machine checkpoint
- JSON structure with state_machine wrapper:
  - current_state, completed_states, transition_table
  - workflow_config: {scope, description, command}
- Atomic write pattern: builds JSON with jq, writes to file

**sm_load()** (Lines 140-218):
- Loads state machine from checkpoint file
- Three checkpoint format support:
  1. v2.0: {.state_machine: {...}} wrapper
  2. Direct state machine format: {current_state: ...}
  3. v1.3 migration: Maps phase numbers to state names
- Auto-migrates v1.3 checkpoints to state-based format
- Graceful degradation if checkpoint file missing

### 3. Workflow Initialization Library

**File**: `/home/benjamin/.config/.claude/lib/workflow-initialization.sh` (370 lines)

**Purpose**: Consolidate Phase 0 initialization (350+ lines → ~100 lines per command)

**3-Step Initialization Pattern** (Lines 85-332):

**STEP 1: Scope Detection** (Lines 100-114):
- Validates workflow scope (research-only, research-and-plan, full-implementation, debug-only)
- Silent validation (only errors to stderr)
- Coordinate.md displays user-facing summary

**STEP 2: Path Pre-Calculation** (Lines 116-282):
- Detects project root via CLAUDE_PROJECT_DIR
- Determines specs directory (prefer .claude/specs, fallback to specs/)
- Calculates topic metadata using topic-utils.sh:
  - `sanitize_topic_name()` - Convert workflow description to snake_case
  - `get_or_create_topic_number()` - Idempotent topic number (reuses existing if found)
- Key insight: Calculate topic_name FIRST, then get topic number (prevents incrementing on each bash block)
- Calculates topic path: `${specs_root}/${topic_num}_${topic_name}`
- Pre-calculates ALL artifact paths (exported to calling script):
  - Research phase: 4 report paths (001_topic1.md through 004_topic4.md)
  - Planning phase: plan path (001_{topic_name}_plan.md)
  - Implementation phase: artifacts directory
  - Debug phase: debug report path
  - Documentation phase: summary path
- Exports individual REPORT_PATH_0 through REPORT_PATH_3 variables (arrays don't export across subprocess boundaries)
- Sets REPORT_PATHS_COUNT=4 for reconstruction in subsequent blocks

**research-and-revise Workflow Discovery** (Lines 262-282):
- For research-and-revise scope: discovers most recent existing plan
- Uses find with ls -t to sort by modification time
- Exports EXISTING_PLAN_PATH for use in planning phase
- Fail-fast if no existing plan found in ${topic_path}/plans

**STEP 3: Directory Structure Creation** (Lines 188-228):
- Calls `create_topic_structure()` from topic-utils.sh
- Creates ONLY topic root directory (lazy subdirectory creation)
- Subdirectories (reports/, plans/, summaries/, debug/) created on-demand when files written
- Verification checkpoint: Checks topic root exists after creation
- Comprehensive diagnostic on failure (parent dir status, permissions, disk space commands)
- Fail-fast: Returns 1 on verification failure

**Variable Exports** (Lines 309-332):
- Exports 20+ path variables to calling script
- Tracking variables: SUCCESSFUL_REPORT_COUNT, TESTS_PASSING, IMPLEMENTATION_OCCURRED
- Silent completion - coordinate.md displays user-facing output

**reconstruct_report_paths_array()** (Lines 345-369):
- Reconstructs REPORT_PATHS array from exported REPORT_PATH_N variables
- Defensive checks:
  - Verify REPORT_PATHS_COUNT is set (default to 0 if missing)
  - Verify each REPORT_PATH_N variable exists before accessing (${!var_name+x} pattern)
  - Skip missing variables with warning
- Handles subprocess isolation where arrays don't persist

### 4. State Persistence Library

**File**: `/home/benjamin/.config/.claude/lib/state-persistence.sh` (341 lines)

**GitHub Actions Pattern** (Lines 87-217):
- Three core functions modeling GitHub Actions $GITHUB_OUTPUT pattern:
  1. `init_workflow_state()` - Create state file with initial variables
  2. `append_workflow_state()` - Append key-value pairs (export statements)
  3. `load_workflow_state()` - Source state file to restore variables

**init_workflow_state()** (Lines 115-142):
- Detects CLAUDE_PROJECT_DIR ONCE (not in every block) - key performance optimization
- Creates .claude/tmp/ directory
- Creates state file: `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh`
- Writes initial export statements (CLAUDE_PROJECT_DIR, WORKFLOW_ID, STATE_FILE)
- Returns state file path (calling script sets trap for cleanup)
- Performance: 70% improvement (50ms git rev-parse → 15ms file read)

**load_workflow_state()** (Lines 168-182):
- Sources workflow state file to restore exported variables
- Graceful degradation: Falls back to init_workflow_state if file missing
- Performance: ~15ms (file read) vs ~50ms (git rev-parse fallback)

**append_workflow_state()** (Lines 207-217):
- Appends export statement to state file
- Format: `export KEY="value"`
- Performance: <1ms (simple echo >> redirect)
- No file locks needed (single writer per workflow)

**JSON Checkpoint Functions** (Lines 219-295):
- `save_json_checkpoint()` - Atomic write with temp file + mv
- `load_json_checkpoint()` - Cat file or return {} if missing
- Use cases: Supervisor metadata, benchmark datasets, metrics
- Performance: Write 5-10ms (atomic), Read 2-5ms (cat + jq)

**JSONL Log Functions** (Lines 297-340):
- `append_jsonl_log()` - Append JSON entry to JSONL file
- Use cases: Benchmark logging, performance metrics, POC metrics
- Performance: <1ms (echo >> redirect)
- Streaming friendly (no file rewrites)

**Decision Criteria for File-Based State** (Lines 61-68):
- State accumulates across subprocess boundaries
- Context reduction requires metadata aggregation (95%)
- Success criteria validation needs objective evidence
- Resumability is valuable (multi-hour migrations)
- State is non-deterministic (user surveys, research findings)
- Recalculation is expensive (>30ms) or impossible
- Phase dependencies require prior phase outputs

### 5. Verification Checkpoint Mechanisms

**File**: `/home/benjamin/.config/.claude/lib/verification-helpers.sh` (218 lines)

**verify_file_created()** (Lines 73-126):
- Verifies file exists and has content (not empty)
- Concise success path: Single character "✓" with no newline
- Verbose failure path: 38-line diagnostic with:
  - Error header with phase and description
  - Expected vs found status
  - Directory diagnostic (exists, file count, recent files)
  - Actionable fix commands
- Returns 0 on success, 1 on failure (bash convention)
- Token reduction: 90% at checkpoints (3,150 tokens saved per workflow)

**verify_state_variables()** (Lines 149-217):
- Verifies multiple variables exist in state file
- Defensive check: Verify state file exists before grep operations
- Checks each variable with grep for `^export VAR_NAME=` pattern
- Concise success: Single character "✓"
- Failure diagnostic:
  - Lists missing variables with ❌ marker
  - Shows state file size and variable count
  - Displays first 20 lines of state file
  - Troubleshooting steps (append_workflow_state calls, set +H directive, permissions)

**Integration in /coordinate** (Line 203-218 of coordinate.md):
- Verification checkpoint AFTER state persistence operations
- Verifies REPORT_PATHS_COUNT + all REPORT_PATH_N variables
- Builds VARS_TO_CHECK array dynamically
- Calls `verify_state_variables()` with state file and variable list
- Fail-fast: Uses `handle_state_error()` on verification failure

### 6. Bash Block Execution Model

**File**: `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md` (737 lines)

**Subprocess Isolation Architecture** (Lines 9-48):
- Each bash block runs as SEPARATE SUBPROCESS, not subshell
- Process ID ($$) changes between blocks
- All environment variables reset (exports lost)
- All bash functions lost (must re-source libraries)
- Trap handlers fire at block exit, not workflow exit
- Files written to disk are ONLY communication channel

**What Persists vs What Doesn't** (Lines 50-68):
- Persists: Files, State files, Workflow ID (fixed location), Directories
- Does NOT persist: Environment variables, Bash functions, Process ID ($$), Trap handlers, Current directory

**Pattern 1: Fixed Semantic Filenames** (Lines 168-191):
- Problem: Using $$ for temp filenames causes files to be "lost" across blocks
- Solution: Use fixed, semantically meaningful filenames based on workflow context
- Example: `WORKFLOW_ID="coordinate_$(date +%s)"` (timestamp-based)
- Save workflow ID to fixed location: `${HOME}/.claude/tmp/coordinate_state_id.txt`
- Load in subsequent blocks: `WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")`

**Pattern 2: Save-Before-Source Pattern** (Lines 193-224):
- Save state ID to fixed location file before sourcing state
- Part 1: Initialize and save state ID (Bash Block 1)
- Part 2: Load state ID and source state (Bash Block 2+)
- Example:
  ```bash
  # Block 1
  echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"
  # Block 2+
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
  STATE_FILE="${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
  source "$STATE_FILE"
  ```

**Pattern 3: State Persistence Library** (Lines 226-248):
- Use .claude/lib/state-persistence.sh for standardized state management
- Re-source library in each bash block (functions lost across boundaries)
- Load workflow state via `load_workflow_state()`
- Update state via `append_workflow_state()`
- No manual file writes needed

**Pattern 4: Library Re-sourcing with Source Guards** (Lines 250-286):
- MUST re-source all libraries in EVERY bash block
- CRITICAL: Include `set +H` at start of every block (prevents bad substitution)
- MUST include unified-logger.sh for emit_progress and display_brief_summary
- Source guards in libraries prevent duplicate execution
- Example:
  ```bash
  set +H  # CRITICAL
  source "${LIB_DIR}/workflow-state-machine.sh"
  source "${LIB_DIR}/state-persistence.sh"
  source "${LIB_DIR}/verification-helpers.sh"
  ```

**Pattern 5: Conditional Variable Initialization** (Lines 288-381):
- Problem: Library variables reset when re-sourced, overwriting loaded values
- Solution: Use `${VAR:-default}` parameter expansion
- Preserves existing values, initializes to default if unset
- Example from workflow-state-machine.sh:
  ```bash
  WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
  CURRENT_STATE="${CURRENT_STATE:-initialize}"
  ```
- Real-world use case: Fixes bug where WORKFLOW_SCOPE reset to "" after loading from state

**Pattern 6: Cleanup on Completion Only** (Lines 383-400):
- Problem: Trap handlers in early blocks fire at block exit, not workflow exit
- Solution: Only set cleanup traps in final completion function
- Trap fires when final block exits (workflow end)

**Critical Libraries for Re-sourcing** (Lines 402-454):
- 6 core libraries required in EVERY bash block for orchestration commands:
  1. workflow-state-machine.sh (state operations)
  2. state-persistence.sh (GitHub Actions-style state)
  3. workflow-initialization.sh (path detection)
  4. error-handling.sh (fail-fast error handling)
  5. unified-logger.sh (emit_progress, display_brief_summary)
  6. verification-helpers.sh (verify_file_created)
- Common errors from missing libraries documented (command not found symptoms)

### 7. Research Agent Delegation Patterns

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md` (Lines 246-672)

**Research Phase State Handler** (Lines 251-337):

**Research Complexity Detection** (Lines 302-318):
- Base complexity: 2 topics (default)
- Patterns increasing complexity:
  - +1 for: integrate, migration, refactor, architecture
  - +2 for: multi-system, cross-platform, distributed, microservices
- Patterns decreasing complexity:
  - -1 for: fix/update/modify + one/single/small

**Hierarchical vs Flat Decision** (Lines 320-336):
- Threshold: ≥4 topics uses hierarchical supervision
- <4 topics uses flat coordination
- Save decision to workflow state: USE_HIERARCHICAL_RESEARCH, RESEARCH_COMPLEXITY
- Variables used in next bash block for conditional execution

**Option A: Hierarchical Research Supervision** (Lines 342-365):
- Execute IF `USE_HIERARCHICAL_RESEARCH == "true"`
- Invokes research-sub-supervisor.md via Task tool
- Supervisor coordinates 4+ research-specialist workers in parallel
- Returns aggregated metadata: {supervisor_id, worker_count, reports_created[], summary, key_findings[], context_tokens}
- Context reduction: 95% (~10,000 → ~500 tokens)

**Option B: Flat Research Coordination** (Lines 367-393):
- Execute IF `USE_HIERARCHICAL_RESEARCH == "false"`
- Invokes research-specialist.md for EACH topic via Task tool
- Parallel execution: 1 to RESEARCH_COMPLEXITY agents
- Each agent returns: `REPORT_CREATED: [absolute path]`
- Pre-calculated report paths: REPORT_PATHS[0..3] from workflow initialization

**Research Verification** (Lines 395-672):

**Dynamic Report Path Discovery** (Lines 529-548):
- Problem: Research agents create descriptive filenames (001_auth_patterns.md)
- Workflow-initialization.sh pre-calculates generic names (001_topic1.md)
- Solution: Discover actual created files, update REPORT_PATHS array
- Pattern matching: Find files matching NNN_*.md in reports directory
- Fallback: Keep original generic path if no file discovered

**Hierarchical Verification** (Lines 454-520):
- Loads supervisor checkpoint via `load_json_checkpoint()`
- Extracts report paths from supervisor checkpoint JSON
- Iterates through supervisor-managed reports
- Calls `verify_file_created()` for each report
- Tracks VERIFICATION_FAILURES count
- Fail-fast: Uses `handle_state_error()` if failures > 0
- Displays supervisor summary and context reduction metrics

**Flat Verification** (Lines 550-603):
- Iterates through RESEARCH_COMPLEXITY reports
- Calls `verify_file_created()` for each REPORT_PATHS[i]
- Tracks VERIFICATION_FAILURES count and SUCCESSFUL_REPORT_PATHS array
- Fail-fast: Uses `handle_state_error()` if failures > 0
- Troubleshooting guidance: Review agent, check invocation, verify path calculation

**State Persistence** (Lines 605-613):
- Saves SUCCESSFUL_REPORT_PATHS to JSON in workflow state
- Defensive JSON handling: Handle empty arrays explicitly to prevent jq parse errors
- Pattern:
  ```bash
  if [ ${#SUCCESSFUL_REPORT_PATHS[@]} -eq 0 ]; then
    REPORT_PATHS_JSON="[]"
  else
    REPORT_PATHS_JSON="$(printf '%s\n' "${SUCCESSFUL_REPORT_PATHS[@]}" | jq -R . | jq -s .)"
  fi
  ```

**Research Phase Complete Checkpoint** (Lines 615-672):
- Displays checkpoint banner with phase status
- Shows artifacts created count and mode (hierarchical/flat)
- Verification status confirmation
- Next action based on workflow scope
- State transition logic:
  - research-only → complete (terminal)
  - research-and-plan/full-implementation/debug-only → plan
- Updates CURRENT_STATE via `sm_transition()` and `append_workflow_state()`

### 8. Research Sub-Supervisor Agent

**File**: `/home/benjamin/.config/.claude/agents/research-sub-supervisor.md` (300 lines)

**Agent Metadata** (Lines 1-17):
- Agent Type: Sub-Supervisor (Hierarchical Coordination)
- Capability: Coordinates 4+ research-specialist agents in parallel
- Context Reduction: 95% (returns aggregated metadata only)
- Invocation: Via Task tool from orchestrator
- Model: sonnet-4.5 (hierarchical coordination, parallel worker invocation)

**Purpose** (Lines 19-27):
- Parallel Execution: All workers execute simultaneously (40-60% time savings)
- Metadata Aggregation: Combine worker outputs into supervisor summary (95% context reduction)
- Checkpoint Coordination: Save supervisor state for resume capability
- Partial Failure Handling: Handle scenarios where some workers fail

**Inputs** (Lines 29-46):
- Required inputs JSON structure:
  ```json
  {
    "topics": ["topic1", "topic2", "topic3", "topic4"],
    "output_directory": "/path/to/reports",
    "state_file": "/path/to/.claude/tmp/workflow_$$.sh",
    "supervisor_id": "research_sub_supervisor_TIMESTAMP"
  }
  ```

**Expected Outputs** (Lines 48-63):
- Aggregated metadata ONLY (not full worker outputs):
  ```json
  {
    "supervisor_id": "research_sub_supervisor_20251107_143030",
    "worker_count": 4,
    "reports_created": ["/path1", "/path2", "/path3", "/path4"],
    "summary": "Combined 50-100 word summary integrating all research findings",
    "key_findings": ["finding1", "finding2", "finding3", "finding4"],
    "total_duration_ms": 45000,
    "context_tokens": 500
  }
  ```
- Context Reduction: ~500 tokens vs ~10,000 tokens (95% reduction)

**Execution Protocol** (Lines 67-300):

**STEP 1: Load Workflow State** (Lines 69-87):
- Sources state-persistence.sh library
- Loads workflow state via `load_workflow_state()`
- Verifies CLAUDE_PROJECT_DIR is set
- Fail-fast if state not loaded

**STEP 2: Parse Inputs** (Lines 92-121):
- Extracts topics, output_dir, supervisor_id from orchestrator prompt
- Validates all required inputs present
- Converts comma-separated topics to array: `IFS=',' read -ra TOPIC_ARRAY`
- Calculates WORKER_COUNT from array length

**STEP 3: Invoke Workers in Parallel** (Lines 125-212):
- CRITICAL: Send SINGLE message with multiple Task tool invocations
- For each topic: Invoke research-specialist.md via Task tool
- Report path calculation: `${OUTPUT_DIR}/NNN_{TOPIC_SLUG}.md`
- Worker input requirements:
  - Research topic from TOPIC_ARRAY
  - Report path (absolute, pre-calculated)
- Worker completion signal: `REPORT_CREATED: /path/to/report`
- WAIT: Workers execute in parallel, do not proceed until all complete

**STEP 4: Extract Worker Metadata** (Lines 214-245):
- Sources metadata-extraction.sh library
- Parses worker completion signals via grep: `REPORT_CREATED:\s*\K.*`
- Extracts metadata from each worker report file via `extract_report_metadata()`
- Metadata structure: {title, summary, key_findings, recommendations}

**STEP 5: Aggregate Worker Metadata** (Lines 247-300+):
- Builds workers array with jq combining worker metadata
- Each worker entry: {worker_id, topic, status, output_path, duration_ms, metadata}
- Aggregates into supervisor summary (50-100 words integrating all findings)

### 9. Error Handling Infrastructure

**File**: `/home/benjamin/.config/.claude/lib/error-handling.sh` (875 lines)

**Error Classification** (Lines 15-48):
- Three error types: transient, permanent, fatal
- `classify_error()` - Classify based on keywords:
  - Transient: locked, busy, timeout, temporary, unavailable, try again
  - Fatal: out of space, disk full, permission denied, no such file, corrupted
  - Default: permanent (code-level issues)
- `suggest_recovery()` - Recovery suggestions by error type

**Detailed Error Analysis** (Lines 80-230):
- `detect_error_type()` - Detect specific error types:
  - syntax, test_failure, file_not_found, import_error, null_error, timeout, permission
- `extract_location()` - Extract file location from error message (file:line format)
- `generate_suggestions()` - Error-specific suggestions for fixing:
  - Syntax: Check brackets, quotes, linter usage
  - Test failure: Check setup, data, race conditions, isolation
  - File not found: Path spelling, relative path, gitignore, create file
  - Import error: Package installation, import path, rebuild dependencies
  - Null error: Add checks, verify initialization, function returns
  - Timeout: Increase timeout, optimize, check loops, network retries
  - Permission: Check permissions, verify access, sudo, locked file

**Retry Logic** (Lines 232-344):
- `retry_with_backoff()` - Retry command with exponential backoff
  - Parameters: max_attempts, base_delay_ms, command
  - Returns 0 if succeeds, 1 if all retries exhausted
- `retry_with_timeout()` - Generate retry metadata with extended timeout
  - Calculates new timeout (1.5x increase per attempt)
  - Returns JSON with retry metadata
- `retry_with_fallback()` - Generate fallback retry metadata with reduced toolset
  - Full toolset: Read,Write,Edit,Bash
  - Reduced toolset: Read,Write (avoids complex operations)

**Error Logging** (Lines 346-386):
- Error log directory: `.claude/data/logs/`
- `log_error_context()` - Log error with context for debugging
  - Creates structured error log with timestamp, type, location, message, context data, stack trace
  - Returns path to error log file

**User Escalation** (Lines 388-479):
- `escalate_to_user()` - Present error with recovery options
  - Displays error message and recovery suggestions
  - Returns user's choice (empty if non-interactive)
- `escalate_to_user_parallel()` - Format escalation for parallel operations
  - Parses error context JSON (operation, failed_count, total_count)
  - Displays numbered recovery options
  - Returns selected option or first option if non-interactive

**Parallel Operation Error Recovery** (Lines 537-610):
- `handle_partial_failure()` - Process successful ops, report failures
  - Validates JSON input
  - Extracts total, successful, failed counts
  - Separates successful_operations and failed_operations
  - Returns enhanced JSON with can_continue and requires_retry fields
  - Displays partial failure banner with details

**State Machine Error Handler** (Lines 738-874):
- `handle_state_error()` - Workflow error handler with state context
  - Five-component error message format:
    1. What failed (error message)
    2. Expected state/behavior
    3. Diagnostic commands (cat state, ls topic, bash -n libraries)
    4. Context (workflow, scope, state, terminal, topic path)
    5. Recommended action (retry count, fix guidance)
  - Retry counter tracking (max 2 retries per state)
  - State persistence via `append_workflow_state()`
  - Fail-fast exit with specified exit code

### 10. Topic Utilities Library

**File**: `/home/benjamin/.config/.claude/lib/topic-utils.sh` (228 lines)

**get_next_topic_number()** (Lines 18-34):
- Finds all directories matching NNN_* pattern
- Extracts numbers, sorts numerically, takes max
- Returns next number (001 for empty, or max+1)
- Uses `10#$max_num` to force decimal interpretation

**get_or_create_topic_number()** (Lines 36-58):
- Idempotent topic number assignment
- Checks for existing topic with exact name match
- Returns existing topic number if found
- Falls back to get_next_topic_number() if no match
- Solves topic inconsistency issue (prevents incrementing on each bash block)

**sanitize_topic_name()** (Lines 60-141):
- 8-step algorithm to convert workflow description to snake_case:
  1. Extract path components (last 2-3 meaningful segments)
  2. Remove full paths from description
  3. Convert to lowercase
  4. Remove filler prefixes (carefully research, analyze, etc.)
  5. Remove stopwords (40+ common English words)
  6. Combine path components with cleaned description
  7. Clean up formatting (multiple underscores, leading/trailing)
  8. Intelligent truncation (preserve whole words, max 50 chars)
- Examples:
  - "Research the /home/user/nvim/docs directory" → "nvim_docs_directory"
  - "fix the token refresh bug" → "fix_token_refresh_bug"

**create_topic_structure()** (Lines 143-165):
- Creates ONLY topic root directory (lazy subdirectory creation)
- Subdirectories created on-demand when files are written
- Verification checkpoint: Checks topic root exists after creation
- Returns 0 on success, 1 on failure
- Prevents empty directories in specs structure

**find_matching_topic()** (Lines 167-200):
- Optional function for intelligent topic merging
- Extracts keywords from description
- Searches for matching directory names
- Returns list of matching topic directories
- Currently not used by coordinate Phase 0 optimization

## Recommendations

### 1. Document Expected Behavior for Topic Path Detection

**Issue**: Topic path calculation in workflow-initialization.sh is complex, involving multiple functions and idempotency checks. Debugging requires understanding the interaction between `sanitize_topic_name()` and `get_or_create_topic_number()`.

**Recommendation**: Create integration test that validates:
- Topic path consistency across multiple bash block invocations (idempotency test)
- Topic name sanitization edge cases (paths with spaces, special characters, very long names)
- Topic number reuse when topic already exists
- Topic number increment when new topic created

**Expected Behavior Documentation** (add to workflow-initialization.sh):
```markdown
## Topic Path Detection Algorithm

1. Extract topic name from workflow description via sanitize_topic_name()
2. Check for existing topic directory matching NNN_<topic_name> pattern
3. If exists: Reuse existing topic number (idempotent)
4. If not exists: Calculate next sequential number and create new topic
5. Return topic path: ${specs_root}/${topic_num}_${topic_name}

## Idempotency Guarantee

Multiple invocations with same workflow description MUST return same topic path:
- Bash Block 1: "research auth" → /specs/042_research_auth
- Bash Block 2: "research auth" → /specs/042_research_auth (same)
- Bash Block 3: "research auth" → /specs/042_research_auth (same)

Without idempotency: topic number would increment on each block (042, 043, 044)
```

### 2. Clarify Report Path Calculation vs Discovery

**Issue**: workflow-initialization.sh pre-calculates generic report paths (001_topic1.md), but research agents create descriptive filenames (001_auth_patterns.md). The coordinate.md discovery logic (Lines 529-548) reconciles this, but the interaction is not immediately obvious.

**Recommendation**: Add explicit documentation in workflow-initialization.sh explaining the two-phase pattern:

```markdown
## Report Path Pre-calculation vs Discovery

**Phase 0 (Initialization)**: Pre-calculate generic paths for state persistence
- REPORT_PATH_0="/specs/042_auth/reports/001_topic1.md"
- REPORT_PATH_1="/specs/042_auth/reports/002_topic2.md"
- These are exported for subprocess communication

**Phase 1 (Research)**: Agents create descriptive filenames
- Agent 1 creates: 001_auth_patterns.md
- Agent 2 creates: 002_oauth_flows.md

**Phase 1 (Verification)**: Discovery reconciles paths
- Glob search: Find files matching 001_*.md, 002_*.md
- Update REPORT_PATHS array with actual filenames
- Fallback: Use generic path if no file discovered

**Why This Pattern**: Generic paths enable state persistence before research executes,
while descriptive names improve artifact organization and developer experience.
```

### 3. Add Verification Checkpoint Reference Documentation

**Issue**: Verification checkpoints are critical to fail-fast reliability but scattered across coordinate.md. No central reference exists for checkpoint locations and what each verifies.

**Recommendation**: Create `.claude/docs/reference/coordinate-verification-checkpoints.md`:

```markdown
# Coordinate Verification Checkpoints

## State Persistence Checkpoint (Line 203-218)
**Location**: After report path serialization
**Verifies**: REPORT_PATHS_COUNT + REPORT_PATH_0..3 in workflow state file
**Failure**: handle_state_error() with diagnostic output

## Research Phase Checkpoint (Lines 463-603)
**Location**: After research agent invocation
**Verifies**: All research report files exist and have content
**Modes**: Hierarchical (supervisor checkpoint) or Flat (individual reports)
**Failure**: handle_state_error() with troubleshooting guidance

## Planning Phase Checkpoint (Lines 899-951)
**Location**: After plan creation/revision
**Verifies**: Plan file exists at PLAN_PATH or EXISTING_PLAN_PATH
**Failure**: handle_state_error() with path analysis and file listing

## Implementation Phase Checkpoint (Lines 1141-1165)
**Location**: After /implement execution
**Verifies**: Implementation complete status (delegated to /implement)
**Failure**: N/A (implementation handles own verification)

## Debug Phase Checkpoint (Lines 1405-1436)
**Location**: After /debug execution
**Verifies**: Debug report exists at DEBUG_REPORT_PATH
**Failure**: handle_state_error() with troubleshooting guidance
```

### 4. Document Research Delegation Decision Matrix

**Issue**: The decision between hierarchical and flat research coordination is based on RESEARCH_COMPLEXITY >= 4, but the rationale for this threshold is not documented.

**Recommendation**: Add decision matrix documentation to coordinate-command-guide.md:

```markdown
## Research Delegation Decision Matrix

| Topic Count | Pattern | Coordination Overhead | Context Reduction | Total Time | Recommended |
|---|---|---|---|---|---|
| 1-3 topics | Flat | Low (0 supervisors) | Moderate (3x reports) | Fast | ✓ Flat |
| 4-6 topics | Hierarchical | Medium (1 supervisor) | High (95% reduction) | Fast | ✓ Hierarchical |
| 7+ topics | Hierarchical | Medium (1 supervisor) | High (95% reduction) | Medium | ✓ Hierarchical |

**Threshold Rationale**: 4 topics
- Context budget: 4 full reports approach context limit (~10,000 tokens)
- Supervisor overhead: 1 supervisor + 4 workers = 5 agents (acceptable)
- Context savings: 95% reduction (10,000 → 500 tokens) justifies overhead
- Time savings: 40-60% faster than sequential (parallel execution)

**When to Adjust Threshold**:
- Increase to 5-6: If research topics are simple (small reports)
- Decrease to 3: If research topics are complex (large reports)
- Never below 2: Flat coordination always faster for 1-2 topics
```

### 5. Create Bash Block Execution Quick Reference

**Issue**: bash-block-execution-model.md is comprehensive (737 lines) but lacks quick reference for common patterns during development.

**Recommendation**: Add "Quick Reference" section to bash-block-execution-model.md:

```markdown
## Quick Reference

### Every Bash Block Must Include (Lines 1-15)
```bash
set +H  # CRITICAL: Disable history expansion
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
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"
```

### State Persistence Pattern
```bash
# Save variable to state (Block N)
append_workflow_state "MY_VAR" "value"

# Load variable from state (Block N+1)
load_workflow_state "$WORKFLOW_ID"
echo "$MY_VAR"  # "value"
```

### Array Persistence Pattern
```bash
# Save array to state (Block N)
for i in "${!MY_ARRAY[@]}"; do
  append_workflow_state "MY_ARRAY_$i" "${MY_ARRAY[$i]}"
done
append_workflow_state "MY_ARRAY_COUNT" "${#MY_ARRAY[@]}"

# Load array from state (Block N+1)
load_workflow_state "$WORKFLOW_ID"
for i in $(seq 0 $((MY_ARRAY_COUNT - 1))); do
  var_name="MY_ARRAY_$i"
  MY_ARRAY+=("${!var_name}")
done
```

### Verification Checkpoint Pattern
```bash
# Verify file created
if verify_file_created "$FILE_PATH" "Description" "Phase Name"; then
  echo " verified"
else
  handle_state_error "File verification failed" 1
fi
```
```

### 6. Add Troubleshooting Section to coordinate-command-guide.md

**Issue**: Common coordination failures (research agents not creating files, state variables missing, topic path inconsistency) lack centralized troubleshooting guidance.

**Recommendation**: Create troubleshooting section covering:

```markdown
## Common Issues and Solutions

### Issue 1: Research Reports Not Created at Expected Paths
**Symptom**: Verification checkpoint fails with "Report file does not exist"
**Cause**: Mismatch between pre-calculated paths and agent-created filenames

**Diagnosis**:
```bash
# Check actual files created
ls -la "${TOPIC_PATH}/reports/"
# Check expected paths
echo "$REPORT_PATH_0"
echo "$REPORT_PATH_1"
```

**Solution**: Discovery logic (Lines 529-548) should reconcile paths automatically
- If discovery fails: Check agent completion signal format (must be: REPORT_CREATED: path)
- If paths still mismatch: Check sanitize_topic_name() output matches agent filename

### Issue 2: WORKFLOW_SCOPE Reset to Empty String
**Symptom**: Workflow proceeds to unintended phases
**Cause**: Library re-sourcing overwrites loaded value

**Diagnosis**:
```bash
# Check workflow state file
cat "$STATE_FILE" | grep WORKFLOW_SCOPE
# Should show: export WORKFLOW_SCOPE="research-and-plan"
```

**Solution**: Conditional variable initialization pattern (Pattern 5)
- Verify workflow-state-machine.sh uses: WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
- Verify load_workflow_state() called BEFORE sourcing libraries
- Check SAVED_WORKFLOW_DESC pattern in coordinate.md (Line 82-85)

### Issue 3: Topic Path Inconsistency Across Bash Blocks
**Symptom**: Different topic numbers calculated in each block (042, 043, 044)
**Cause**: get_next_topic_number() increments instead of get_or_create_topic_number()

**Diagnosis**:
```bash
# Check topic directories created
ls -la "${SPECS_ROOT}/"
# Should show single topic directory, not multiple
```

**Solution**: Use get_or_create_topic_number() (idempotent, reuses existing)
- workflow-initialization.sh already implements this (Line 157)
- If still seeing multiple: Check sanitize_topic_name() returns same value each time
```

## References

### Core Files Analyzed

- `/home/benjamin/.config/.claude/commands/coordinate.md` (1,630 lines)
  - Two-step execution pattern: Lines 17-244
  - Research phase state handler: Lines 246-672
  - Research complexity detection: Lines 302-318
  - Hierarchical vs flat decision: Lines 320-336
  - Dynamic report path discovery: Lines 529-548
  - Verification checkpoints: Lines 203-218, 463-603, 899-951

- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (513 lines)
  - State enumeration: Lines 36-43
  - State transition table: Lines 50-59
  - Conditional variable initialization: Lines 64-79
  - sm_init(): Lines 88-135
  - sm_transition(): Lines 229-268
  - sm_save(): Lines 393-420
  - sm_load(): Lines 140-218

- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh` (370 lines)
  - initialize_workflow_paths(): Lines 85-332
  - STEP 1 (Scope Detection): Lines 100-114
  - STEP 2 (Path Pre-calculation): Lines 116-282
  - STEP 3 (Directory Creation): Lines 188-228
  - reconstruct_report_paths_array(): Lines 345-369

- `/home/benjamin/.config/.claude/lib/state-persistence.sh` (341 lines)
  - init_workflow_state(): Lines 115-142
  - load_workflow_state(): Lines 168-182
  - append_workflow_state(): Lines 207-217
  - save_json_checkpoint(): Lines 240-258
  - load_json_checkpoint(): Lines 279-295

- `/home/benjamin/.config/.claude/lib/verification-helpers.sh` (218 lines)
  - verify_file_created(): Lines 73-126
  - verify_state_variables(): Lines 149-217

- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md` (737 lines)
  - Subprocess isolation architecture: Lines 9-48
  - Pattern 1 (Fixed Semantic Filenames): Lines 168-191
  - Pattern 2 (Save-Before-Source): Lines 193-224
  - Pattern 3 (State Persistence Library): Lines 226-248
  - Pattern 4 (Library Re-sourcing): Lines 250-286
  - Pattern 5 (Conditional Initialization): Lines 288-381
  - Pattern 6 (Cleanup on Completion): Lines 383-400
  - Critical libraries reference: Lines 402-454

- `/home/benjamin/.config/.claude/lib/error-handling.sh` (875 lines)
  - Error classification: Lines 15-48
  - Detailed error analysis: Lines 80-230
  - Retry logic: Lines 232-344
  - User escalation: Lines 388-479
  - handle_state_error(): Lines 738-874

- `/home/benjamin/.config/.claude/lib/topic-utils.sh` (228 lines)
  - get_next_topic_number(): Lines 18-34
  - get_or_create_topic_number(): Lines 36-58
  - sanitize_topic_name(): Lines 60-141
  - create_topic_structure(): Lines 143-165

- `/home/benjamin/.config/.claude/agents/research-sub-supervisor.md` (300 lines)
  - Agent metadata: Lines 1-17
  - Purpose and capabilities: Lines 19-27
  - Inputs specification: Lines 29-46
  - Expected outputs: Lines 48-63
  - Execution protocol: Lines 67-300

### Related Documentation

- `.claude/docs/architecture/state-based-orchestration-overview.md` - Complete state-based orchestration architecture
- `.claude/docs/guides/coordinate-command-guide.md` - Coordinate usage patterns and troubleshooting
- `.claude/docs/guides/state-machine-orchestrator-development.md` - Creating new orchestrators using state machine
- `.claude/docs/concepts/patterns/verification-fallback.md` - Verification checkpoint pattern documentation
- `.claude/docs/reference/command_architecture_standards.md` - Standard 0 (Execution Enforcement)
