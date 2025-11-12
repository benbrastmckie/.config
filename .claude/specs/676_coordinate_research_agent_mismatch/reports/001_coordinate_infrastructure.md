# Coordinate Command Infrastructure Analysis

## Metadata
- **Date**: 2025-11-12
- **Agent**: research-specialist
- **Topic**: /coordinate command infrastructure analysis
- **Report Type**: codebase analysis

## Executive Summary

The /coordinate command implements a state machine-based orchestration pattern with 7 core workflow states (initialize, research, plan, implement, test, debug, document, complete). Agent invocation uses the Task tool with behavioral injection pattern, passing absolute report paths pre-calculated during initialization. State persistence uses GitHub Actions-style workflow files with selective file-based caching for expensive operations. Verification checkpoints ensure mandatory file creation at phase boundaries with fail-fast error handling.

Key architectural components: state machine library (workflow-state-machine.sh, 668 lines), state persistence library (state-persistence.sh, 386 lines), verification helpers (verification-helpers.sh, 371 lines), error handling (error-handling.sh, 875 lines), and workflow initialization (workflow-initialization.sh, ~100+ lines estimated).

## Findings

### 1. Agent Invocation Patterns

**Location**: `.claude/commands/coordinate.md:446-490` (Research Phase)

The /coordinate command invokes agents using the Task tool with behavioral injection pattern:

```markdown
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

**Pattern Analysis**:
- **Behavioral injection**: Agent reads behavioral file (research-specialist.md) for detailed instructions
- **Context injection**: Workflow-specific variables passed via prompt (Report Path, Topic, Complexity)
- **Mandatory file creation**: Agent MUST create file at pre-calculated absolute path
- **Completion signal**: Agent returns `REPORT_CREATED: <path>` upon success
- **Timeout**: 5 minutes (300000ms) per research agent invocation

**Agent Count**: 7 invocations total across workflow phases:
- Research phase: 1-4 agents (based on RESEARCH_COMPLEXITY, line 415-435)
- Planning phase: 1 agent (plan-architect or revision-specialist, line 910-962)
- Implementation phase: 1 agent (implementer-coordinator, line 1300-1329)
- Debug phase: 1 agent (via /debug command delegation, line 1673-1686)
- Documentation phase: 1 agent (via /document command delegation, line 1882-1895)

### 2. State Management Architecture

**Location**: `.claude/lib/workflow-state-machine.sh`

**State Machine Design**:
- 8 core states: initialize, research, plan, implement, test, debug, document, complete
- State transition table (lines 50-60): Defines valid transitions between states
- Terminal state: Determined by workflow scope (research-only → research, full-implementation → complete)
- Atomic transitions: Two-phase commit (pre-checkpoint + state update + post-checkpoint, lines 363-409)

**State Persistence Pattern** (`.claude/lib/state-persistence.sh`):
- GitHub Actions-style workflow state files (init_workflow_state, load_workflow_state, append_workflow_state)
- Fixed semantic filenames: `~/.claude/tmp/workflow_${WORKFLOW_ID}.sh` (not $$-based, survives bash block boundaries)
- Selective state caching: 7 critical items use file-based persistence (supervisor metadata, benchmark data, implementation state)
- Performance: 67% improvement for CLAUDE_PROJECT_DIR detection (6ms file read vs 50ms git rev-parse)
- Graceful degradation: Missing state files trigger recalculation (non-critical items) or fail-fast (critical items)

**Key State Variables**:
- `CURRENT_STATE`: Current workflow state (persisted across bash blocks)
- `WORKFLOW_SCOPE`: Detected scope (research-only, research-and-plan, full-implementation, debug-only, research-and-revise)
- `TERMINAL_STATE`: Final state for this workflow scope
- `COMPLETED_STATES`: Array of completed states (history tracking, Spec 672 Phase 2)
- `WORKFLOW_DESCRIPTION`: User-provided workflow description
- `REPORT_PATHS`: Array of pre-calculated report paths (serialized to state)

### 3. Bash Block Execution Model

**Location**: `.claude/docs/concepts/bash-block-execution-model.md` (referenced in coordinate.md:135-139)

**Subprocess Isolation Constraint**:
- Each bash block executes in separate subprocess (Claude Code architecture)
- Variables do not persist across blocks unless exported to state file
- Functions lost across boundaries → re-source libraries in every block

**Validated Patterns**:
1. **Fixed semantic filenames** (coordinate.md:136-138): Use `~/.claude/tmp/coordinate_state_id.txt` instead of `$$` which changes per block
2. **Save-before-source pattern** (coordinate.md:84-86): Save WORKFLOW_DESCRIPTION before sourcing libraries that pre-initialize it
3. **Library re-sourcing** (coordinate.md:350-372): Source state machine + persistence → Load state → Source error handling → Source additional libraries
4. **Pattern 5 preservation** (coordinate.md:367): Error handling library sourcing after load_workflow_state() preserves loaded state

**Anti-Patterns to Avoid**:
- $$-based identifiers (change per block)
- export assumptions (subprocess boundaries)
- premature EXIT traps (trigger in subshells during initialization)

### 4. Verification Checkpoint Implementation

**Location**: `.claude/lib/verification-helpers.sh`

**Verification Functions**:
1. `verify_file_created(file_path, item_desc, phase_name)` (lines 73-170):
   - Success: Outputs single character "✓" (90% token reduction)
   - Failure: 38-line diagnostic with directory analysis, file listing, root cause suggestions
   - Returns 0 on success, 1 on failure

2. `verify_state_variable(var_name)` (lines 223-280):
   - Verifies variable exists in state file with correct export format
   - Pattern: `^export ${var_name}=` matches state-persistence.sh format
   - Diagnostic output on failure with troubleshooting steps

3. `verify_state_variables(state_file, var_names...)` (lines 302-370):
   - Batch verification of multiple variables
   - Reports missing variables with file diagnostics

**Checkpoint Locations in coordinate.md**:
- Initialization: State ID file creation (line 141-143)
- Research phase: Report file verification (lines 671-724)
- Planning phase: Plan file verification (lines 1051-1103)
- Implementation phase: Plan execution verification (lines 1379-1437)
- Debug phase: Debug report verification (lines 1739-1771)

**Fail-Fast Pattern**:
- Verification failures call `handle_state_error()` which logs error context and exits
- Error messages use 5-component format (what failed, expected behavior, diagnostic commands, context, recommended action)
- Retry logic: Max 2 retries per state (tracked in workflow state)

### 5. Library Dependencies and Sourcing Order

**Location**: `.claude/commands/coordinate.md:349-372` (Standard 15: Library Sourcing Order)

**Critical Sourcing Order**:
1. **State machine + persistence** (FIRST): Needed for load_workflow_state()
2. **Load workflow state** (BEFORE other libraries): Prevents WORKFLOW_SCOPE reset
3. **Error handling + verification** (Pattern 5): Preserves loaded state
4. **Additional libraries**: workflow-initialization.sh, unified-logger.sh, etc.

**Library Dependencies**:
- **Core state libraries** (2 files):
  - workflow-state-machine.sh (668 lines): State enumeration, transition table, sm_init/sm_transition/sm_execute
  - state-persistence.sh (386 lines): init_workflow_state, load_workflow_state, append_workflow_state, JSON checkpoint operations

- **Verification and error handling** (2 files):
  - verification-helpers.sh (371 lines): verify_file_created, verify_state_variable, verify_state_variables
  - error-handling.sh (875 lines): classify_error, retry_with_backoff, handle_state_error, escalate_to_user

- **Workflow utilities** (~5+ files):
  - workflow-initialization.sh: initialize_workflow_paths, extract_topic_from_plan_path
  - workflow-scope-detection.sh: detect_workflow_scope (supports revision patterns)
  - unified-logger.sh: emit_progress, log functions
  - checkpoint-utils.sh: save_checkpoint, restore_checkpoint
  - metadata-extraction.sh: extract_report_metadata, extract_plan_metadata

- **Conditional loading** (coordinate.md:196-217): Required libraries vary by workflow scope (research-only loads 6 libs, full-implementation loads 10 libs)

### 6. Error Handling and Fail-Fast Mechanisms

**Location**: `.claude/lib/error-handling.sh:739-851` (handle_state_error function)

**Five-Component Error Message Format**:
1. What failed (line 767): "ERROR in state '$current_state': $error_message"
2. Expected behavior (lines 771-789): State-specific expected outcomes
3. Diagnostic commands (lines 792-802): Shell commands to investigate issue
4. Context (lines 806-811): Workflow metadata (description, scope, state, paths)
5. Recommended action (lines 826-848): Retry count, next steps, resume command

**Error Classification** (lines 16-48):
- Transient: Locked files, timeouts, temporary unavailability (retry with backoff)
- Permanent: Code-level issues (fix underlying problem)
- Fatal: Out of space, permission denied (user intervention required)

**Retry Logic**:
- Max 2 retries per state (tracked via `RETRY_COUNT_${state}` in workflow state)
- Exponential backoff: retry_with_backoff(max_attempts, base_delay_ms, command)
- Extended timeout: retry_with_timeout increases timeout 1.5x per attempt

**Fail-Fast Triggers** (coordinate.md verification checkpoints):
- Missing state file when expected (load_workflow_state with is_first_block=false, state-persistence.sh:204-225)
- State variable not persisted after append (verify_state_variable, verification-helpers.sh:223-280)
- Agent failed to create report file (verify_file_created, coordinate.md:671-724)
- Invalid state transition (sm_transition validation, workflow-state-machine.sh:363-374)

### 7. Path Pre-Calculation (Phase 0 Optimization)

**Location**: `.claude/commands/coordinate.md:265-283` (Artifact path calculation)

**Pre-Calculated Paths**:
```bash
REPORTS_DIR="${TOPIC_PATH}/reports"
PLANS_DIR="${TOPIC_PATH}/plans"
SUMMARIES_DIR="${TOPIC_PATH}/summaries"
DEBUG_DIR="${TOPIC_PATH}/debug"
OUTPUTS_DIR="${TOPIC_PATH}/outputs"
CHECKPOINT_DIR="${HOME}/.claude/data/checkpoints"
```

**Benefits**:
- 85% token reduction: Paths calculated once in Phase 0, injected into agents (not recalculated per agent)
- Consistent artifact locations: All agents use same directory structure
- Bash block persistence: Paths saved to workflow state, available across blocks

**Dynamic Path Discovery** (coordinate.md:567-596):
- Research agents create descriptive filenames (e.g., `001_auth_patterns.md`)
- Workflow initialization pre-calculates generic names (e.g., `001_topic1.md`)
- Dynamic discovery reconciles: Find actual files created, update REPORT_PATHS array
- Discovery executes BEFORE verification to prevent false failures

**Report Path Array Serialization** (coordinate.md:248-263):
- Array serialized to individual variables: `REPORT_PATH_0`, `REPORT_PATH_1`, etc.
- Count stored: `REPORT_PATHS_COUNT`
- Reconstruction function: `reconstruct_report_paths_array()` (coordinate.md:419)

### 8. Agent Behavioral Files

**Location**: `.claude/agents/` (22 agent files found)

**Key Agents Used by /coordinate**:
1. **research-specialist.md** (671 lines): 4-step execution (verify path → create file → research → verify)
2. **plan-architect.md**: Create implementation plans with phase dependencies
3. **revision-specialist.md**: Revise existing plans for research-and-revise workflows
4. **implementer-coordinator.md**: Wave-based parallel implementation with testing/commits
5. **research-sub-supervisor.md**: Hierarchical coordination for ≥4 research topics (95% context reduction)

**Behavioral File Pattern**:
- Mandatory completion signals: `REPORT_CREATED: <path>`, `PLAN_CREATED: <path>`, etc.
- Progress markers: `PROGRESS: <brief-message>` emitted at milestones
- 28 completion criteria (research-specialist.md:322-411): File creation, content completeness, research quality, process compliance
- Defensive verification: File existence, size, content quality checks before returning
- Non-compliance consequences: Orchestrator fallback creation, quality degradation

## Recommendations

### 1. Agent Invocation Pattern Consistency
**Issue**: Current Task invocations in coordinate.md follow Standard 11 (Imperative Agent Invocation Pattern) but require careful maintenance to preserve this pattern.

**Recommendation**:
- Validate all agent invocations use imperative instructions (`**EXECUTE NOW**: USE the Task tool...`)
- Ensure no code block wrappers around Task invocations
- Verify explicit completion signals required (e.g., `REPORT_CREATED:`)
- Use validation tools: `.claude/lib/validate-agent-invocation-pattern.sh`

### 2. State Persistence Reliability
**Issue**: State files must survive bash block boundaries, but cleanup traps or premature deletion can cause failures.

**Recommendation**:
- Use fixed semantic filenames exclusively (no $$-based paths)
- Implement fail-fast validation in load_workflow_state (Spec 672 Phase 3)
- Add defensive state file existence checks before critical operations
- Document bash block execution model constraints in command files

### 3. Verification Checkpoint Standardization
**Issue**: Verification logic is consistent but scattered across 5 phase handlers in coordinate.md.

**Recommendation**:
- Extract common verification pattern to helper function (already exists: verify_file_created)
- Use concise checkpoint pattern (coordinate.md:288-302): Single-line success, multi-line failure
- Apply 90% token reduction pattern consistently across all phases
- Document checkpoint pattern in command development guide

### 4. Error Recovery Strategy
**Issue**: Current retry logic is basic (max 2 retries per state), may not handle all transient failures optimally.

**Recommendation**:
- Implement error classification (transient vs permanent) for smarter retries
- Use exponential backoff for network-related operations
- Add parallel operation partial failure handling (handle_partial_failure function exists)
- Escalate to user after retry exhaustion with clear recovery options

### 5. Library Sourcing Robustness
**Issue**: Library sourcing order is critical but errors are hard to diagnose if incorrect.

**Recommendation**:
- Add verification checkpoint after library sourcing (coordinate.md:374-382 pattern)
- Check critical functions available: verify_state_variable, handle_state_error
- Provide diagnostic output if sourcing fails (missing files, wrong order)
- Document Standard 15 (Library Sourcing Order) compliance in all orchestration commands

### 6. Path Calculation Validation
**Issue**: Dynamic path discovery can fail if agents create files with unexpected naming patterns.

**Recommendation**:
- Enforce strict naming convention in agent behavioral files (NNN_descriptive_name.md)
- Add validation step after discovery to ensure all expected files found
- Fall back to generic names if discovery finds no matches
- Log discovery results for debugging (coordinate.md:593-596 pattern)

## References

### Command Files
- `.claude/commands/coordinate.md` (1986 lines): Main orchestration command
  - Line 18-39: Workflow description capture (Part 1)
  - Line 46-328: State machine initialization (Part 2)
  - Line 332-793: Research phase handler
  - Line 798-1232: Planning phase handler
  - Line 1236-1478: Implementation phase handler
  - Line 1482-1605: Testing phase handler
  - Line 1609-1814: Debug phase handler (conditional)
  - Line 1818-1977: Documentation phase handler (conditional)

### Library Files
- `.claude/lib/workflow-state-machine.sh` (668 lines): State machine abstraction
  - Lines 34-44: State enumeration (8 core states)
  - Lines 50-60: State transition table
  - Lines 214-270: sm_init function (scope detection, terminal state configuration)
  - Lines 363-409: sm_transition function (atomic state transitions)

- `.claude/lib/state-persistence.sh` (386 lines): GitHub Actions-style state persistence
  - Lines 115-142: init_workflow_state (state file creation)
  - Lines 185-227: load_workflow_state (fail-fast validation mode)
  - Lines 252-262: append_workflow_state (key-value accumulation)
  - Lines 285-303: save_json_checkpoint (atomic JSON writes)

- `.claude/lib/verification-helpers.sh` (371 lines): Concise verification patterns
  - Lines 73-170: verify_file_created (90% token reduction)
  - Lines 223-280: verify_state_variable (single variable check)
  - Lines 302-370: verify_state_variables (batch verification)

- `.claude/lib/error-handling.sh` (875 lines): Error classification and recovery
  - Lines 26-48: classify_error (transient/permanent/fatal classification)
  - Lines 236-266: retry_with_backoff (exponential backoff retry)
  - Lines 739-851: handle_state_error (5-component error format with retry tracking)

- `.claude/lib/workflow-initialization.sh` (~100+ lines, partial read): Phase 0 path calculation
  - Lines 78-100: extract_topic_from_plan_path (research-and-revise support)

### Agent Files
- `.claude/agents/research-specialist.md` (671 lines): Research agent with mandatory file creation
  - Lines 24-70: Step 1.5 - Parent directory creation
  - Lines 72-118: Step 2 - File creation FIRST (before research)
  - Lines 120-144: Step 3 - Research execution and incremental updates
  - Lines 146-198: Step 4 - Verification and return confirmation
  - Lines 322-411: 28 completion criteria for quality enforcement

### Documentation
- `.claude/docs/concepts/bash-block-execution-model.md`: Subprocess isolation patterns and validated approaches
- `.claude/docs/reference/command_architecture_standards.md`: Standard 11 (Imperative Agent Invocation), Standard 15 (Library Sourcing Order)
- `.claude/docs/guides/coordinate-command-guide.md`: Complete usage guide with troubleshooting
