# /plan Command Performance Optimization Analysis

## Metadata
- **Date**: 2025-11-29
- **Agent**: research-specialist
- **Topic**: Plan command systematic optimizations and performance improvements
- **Report Type**: codebase analysis

## Executive Summary

Analysis of the /plan command reveals multiple optimization opportunities across three primary categories: (1) redundant state operations causing unnecessary disk I/O, (2) sequential agent invocations that could run in parallel, and (3) inefficient library sourcing patterns. The command currently executes 3 sequential bash blocks with complete environment reconstruction between blocks, performs 6+ state file writes per execution, and sources 8+ libraries multiple times. Implementing the recommended optimizations could reduce execution time by 30-40% and improve user experience through consolidated output and faster response times.

## Findings

### 1. Redundant State Persistence Operations

**Location**: `/home/benjamin/.config/.claude/commands/plan.md`

**Current Implementation**:
- Block 1a (lines 160-261): Initializes state with `init_workflow_state()` and `sm_init()`
- Block 1c (lines 374-578): Calls `append_workflow_state()` 13 times for individual variables
- Block 2 (lines 612-881): Loads state, validates, and calls `save_completed_states_to_state()` twice
- Block 3 (lines 914-1171): Loads state again, validates, and calls `save_completed_states_to_state()` again

**Performance Impact**:
- Each `append_workflow_state()` call triggers a disk write operation
- State file is sourced 3 separate times (once per block)
- Multiple `grep` operations to validate state file contents
- Estimated overhead: 200-400ms per execution from redundant I/O

**Evidence**:
```bash
# Block 1c (lines 559-573): 13 individual append operations
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
append_workflow_state "USER_ARGS" "$USER_ARGS"
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
# ... 10 more append calls
```

Each append writes to disk individually rather than batching.

### 2. Sequential Agent Invocation Pattern

**Location**: `/home/benjamin/.config/.claude/commands/plan.md`

**Current Pattern**:
- Block 1b (lines 263-293): Topic naming agent invocation (Task tool)
- Block 1b validation (lines 295-368): Validates agent output with retry logic
- Block 1d (lines 580-607): Research-specialist agent invocation (Task tool)
- Block 2 (lines 610-881): Plan-architect agent invocation (Task tool)

**Sequential Dependency Chain**:
1. Topic naming agent → validate → extract topic name
2. Research specialist → validate reports
3. Plan architect → validate plan

**Optimization Opportunity**:
- Topic naming and research could potentially run in parallel (both only need FEATURE_DESCRIPTION)
- Validation blocks force sequential execution even when agents complete quickly
- No inherent dependency between topic naming and research gathering

**Evidence**:
Research agent prompt (line 593-597) only requires `FEATURE_DESCRIPTION`, same as topic naming agent (line 278).
```bash
# Both agents receive the same primary input
# Topic naming: "User Prompt: ${FEATURE_DESCRIPTION}"
# Research: "Research Topic: ${FEATURE_DESCRIPTION}"
```

### 3. Repeated Library Sourcing Across Blocks

**Location**: `/home/benjamin/.config/.claude/commands/plan.md`

**Current Implementation**:
- Block 1a (lines 122-145): Sources 6 libraries with three-tier pattern
- Block 1c (lines 436-449): Re-sources 3 libraries (state-persistence, error-handling, workflow-initialization)
- Block 2 (lines 634-659): Re-sources 3 libraries again
- Block 3 (lines 936-960): Re-sources 3 libraries again

**Libraries Sourced Multiple Times**:
1. `error-handling.sh` - 4 times (blocks 1a, 1c, 2, 3)
2. `state-persistence.sh` - 4 times (blocks 1a, 1c, 2, 3)
3. `workflow-state-machine.sh` - 3 times (blocks 1a, 2, 3)

**Performance Impact**:
- Each source operation reads and parses ~500-1500 lines of bash code
- Cumulative parsing overhead: ~4000+ lines parsed multiple times
- Functions are exported but environment doesn't persist across blocks
- Estimated overhead: 100-200ms from redundant sourcing

**Evidence**:
```bash
# Block 1a (line 131)
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1

# Block 1c (line 438) - SAME LIBRARY SOURCED AGAIN
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
```

### 4. Defensive State Validation Overhead

**Location**: `/home/benjamin/.config/.claude/commands/plan.md`

**Validation Pattern**:
- Block 2 (lines 700-780): 3 validation checkpoints with error logging
- Block 3 (lines 995-1070): 3 validation checkpoints with error logging
- Each checkpoint performs file existence checks, grep operations, JSON construction

**Specific Validations**:
```bash
# Block 2 (lines 701-721): STATE_FILE existence check
if [ -z "$STATE_FILE" ]; then
  log_command_error ... # JSON construction + logging
  echo "ERROR: State file path not set" >&2
  exit 1
fi

# Block 2 (lines 723-744): STATE_FILE file check
if [ ! -f "$STATE_FILE" ]; then
  log_command_error ... # JSON construction + logging
  echo "ERROR: State file not found" >&2
  exit 1
fi

# Block 2 (lines 757-780): Variable restoration check
if [ -z "${TOPIC_PATH:-}" ] || [ -z "${RESEARCH_DIR:-}" ]; then
  log_command_error ... # JSON construction + logging
  echo "ERROR: Critical variables not restored" >&2
  exit 1
fi
```

**Performance Impact**:
- 6 total validation blocks (3 in Block 2, 3 in Block 3)
- Each validation constructs JSON error details even on success path
- Redundant checks across blocks (same validations repeated)
- Estimated overhead: 50-100ms from defensive validation

### 5. Topic Naming Retry Logic Overhead

**Location**: `/home/benjamin/.config/.claude/commands/plan.md`, Block 1b validation (lines 349-368)

**Current Implementation**:
```bash
# Use validate_agent_output_with_retry with format validator
# - 3 retries with 10-second timeout each (30 seconds total + backoff)
# - Increased from 5s to 10s to allow Haiku agent more time for completion
validate_agent_output_with_retry "topic-naming-agent" "$TOPIC_NAME_FILE" "validate_topic_name_format" 10 3
```

**Performance Characteristics**:
- Haiku agent is optimized for <3 second response times (per agent spec line 18)
- 10-second timeout is 3x longer than expected agent completion
- 3 retries with exponential backoff could wait up to 30+ seconds on failures
- Most executions succeed on first attempt (Haiku is fast and reliable)

**Optimization Opportunity**:
- Reduce timeout from 10s to 5s (still provides 2x buffer over expected 3s)
- Consider reducing retries to 2 (failures are rare based on LLM reliability)
- Add fast-fail detection (if no output after 2s, likely permanent failure)

### 6. Context Preservation Issues Between Blocks

**Location**: `/home/benjamin/.config/.claude/commands/plan.md`

**Current Pattern**:
Each bash block must restore full execution context:
- Project directory detection (git operations or filesystem traversal)
- State ID file reading
- Workflow ID validation
- State file sourcing
- Error logging context restoration
- Environment variable exports

**Code Duplication Example**:
```bash
# Block 1c (lines 417-430): Project directory detection
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; then
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

# Block 2 (lines 635-644): IDENTICAL CODE DUPLICATED
# Block 3 (lines 936-945): IDENTICAL CODE DUPLICATED AGAIN
```

**Performance Impact**:
- Git operations on large repositories can take 50-100ms
- Filesystem traversal in deep directory structures adds overhead
- Code duplication = 3x execution of same detection logic
- Total overhead: 150-300ms from repeated detection

### 7. Unnecessary Defensive Trap Setup

**Location**: `/home/benjamin/.config/.claude/commands/plan.md`

**Current Implementation**:
- Block 2 (lines 618-622): Defensive trap setup BEFORE library sourcing
- Block 2 (lines 692-693): Defensive trap cleared, full trap set
- Block 3 (lines 920-924): Defensive trap setup BEFORE library sourcing
- Block 3 (lines 987-988): Defensive trap cleared, full trap set

**Pattern**:
```bash
# Defensive trap (temporary)
trap 'echo "ERROR: Block 2 initialization failed ..." >&2; exit 1' ERR

# Load libraries...

# Clear defensive trap, set full trap
_clear_defensive_trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

**Performance Impact**:
- Trap setup/teardown has minimal cost (<1ms) but adds code complexity
- Double error handling (defensive + full trap) creates maintenance burden
- Defensive trap provides limited value (library sourcing failures already caught)

### 8. Agent Prompt Complexity

**Location**: `/home/benjamin/.config/.claude/agents/research-specialist.md`, `/home/benjamin/.config/.claude/agents/plan-architect.md`

**Research Specialist Agent**:
- 684 lines of behavioral guidelines
- 28 completion criteria to verify
- Complex multi-step execution process (4 required steps)
- Extensive progress streaming requirements
- Detailed error handling protocol

**Plan Architect Agent**:
- 1,113 lines of behavioral guidelines
- 44 completion criteria to verify
- Dual operation modes (creation vs revision)
- Complex complexity calculation and tier selection
- Extensive template patterns and examples

**Performance Impact**:
- Large behavioral files consume context tokens (estimated 3000-5000 tokens each)
- Agents must process extensive instructions before executing
- Potential for confusion or misinterpretation with complex multi-step protocols
- Estimated overhead: Longer LLM response times due to instruction processing

**Evidence**:
Research specialist has 400+ lines of step-by-step execution instructions with multiple checkpoints, verification requirements, and completion criteria. This cognitive load may slow agent execution.

### 9. Workflow State Machine Complexity

**Location**: `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh`

**Function Analysis** (from grep results):
- 15+ exported functions for state management
- Multiple state transition validations
- Complex metadata extraction and caching
- JSON serialization for every state change

**State Operations in /plan**:
1. `sm_init()` - Initialize state machine (Block 1a, line 220)
2. `sm_transition($STATE_RESEARCH)` - Transition to research (Block 1a, line 238)
3. `sm_transition($STATE_PLAN)` - Transition to plan (Block 2, line 835)
4. `sm_transition($STATE_COMPLETE)` - Transition to complete (Block 3, line 1108)
5. `save_completed_states_to_state()` - Persist transitions (Blocks 2 & 3)

**Performance Impact**:
- Each transition validates state, updates metadata, writes to disk
- Completed states saved multiple times (blocks 2 and 3)
- State machine abstraction adds overhead vs direct state file updates
- Estimated overhead: 50-100ms from state machine operations

### 10. Output Formatting in Summary Block

**Location**: `/home/benjamin/.config/.claude/commands/plan.md`, Block 3 (lines 1136-1161)

**Current Implementation**:
```bash
# Source summary formatting library
source "${CLAUDE_LIB}/core/summary-formatting.sh" 2>/dev/null || {
  echo "ERROR: Failed to load summary-formatting library" >&2
  exit 1
}

# Extract phase count and estimated hours from plan
PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" 2>/dev/null || echo "0")
ESTIMATED_HOURS=$(grep "Estimated Hours:" "$PLAN_PATH" | head -1 | sed 's/.*: //' 2>/dev/null || echo "unknown")

# Build summary text
SUMMARY_TEXT="Created implementation plan with $PHASE_COUNT phases..."

# Build artifacts section
ARTIFACTS="  📊 Reports: $RESEARCH_DIR/ ($REPORT_COUNT files)..."

# Build next steps
NEXT_STEPS="  • Review plan: cat $PLAN_PATH..."

# Print standardized summary
print_artifact_summary "Plan" "$SUMMARY_TEXT" "" "$ARTIFACTS" "$NEXT_STEPS"
```

**Performance Impact**:
- Additional library sourcing in final block (summary-formatting.sh)
- Multiple grep operations on plan file to extract metadata
- String concatenation and formatting operations
- Minimal impact (<50ms) but adds complexity

## Recommendations

### High-Impact Optimizations (30-40% improvement potential)

#### 1. Consolidate State Operations
**Implementation**:
- Batch all `append_workflow_state()` calls into single operation
- Reduce state saves from 6+ to 2-3 (initialization, phase transitions, completion)
- Use in-memory state buffer pattern with deferred writes

**Expected Improvement**: 150-300ms per execution

**Code Change Example**:
```bash
# Instead of:
append_workflow_state "VAR1" "$VAR1"
append_workflow_state "VAR2" "$VAR2"
# ... 11 more individual writes

# Use bulk append:
append_workflow_state_bulk <<EOF
VAR1=$VAR1
VAR2=$VAR2
VAR3=$VAR3
# ... all variables
EOF
```

#### 2. Reduce Bash Block Count from 3 to 1-2
**Implementation**:
- Combine blocks 1a, 1b, 1c into single initialization block
- Keep agent invocations in separate blocks only if necessary for user feedback
- Eliminate redundant environment reconstruction

**Expected Improvement**: 200-400ms per execution

**Rationale**:
Current 3-block structure forces environment rebuilding 3 times. Single block maintains context and eliminates redundant operations.

#### 3. Optimize Library Sourcing Pattern
**Implementation**:
- Source guard pattern (already implemented in some libraries, line 16-18 in workflow-initialization.sh)
- Ensure all libraries use `LIBRARY_NAME_SOURCED` guards
- Verify exports persist across blocks (may require environment preservation)

**Expected Improvement**: 100-200ms per execution

**Code Change Example**:
```bash
# Add to all libraries:
if [ -n "${ERROR_HANDLING_SOURCED:-}" ]; then
  return 0
fi
export ERROR_HANDLING_SOURCED=1
```

### Medium-Impact Optimizations (10-20% improvement potential)

#### 4. Streamline Validation Checkpoints
**Implementation**:
- Move validation to helper function (validate once, reuse result)
- Reduce redundant validations between blocks
- Remove defensive trap pattern (library sourcing already error-safe)

**Expected Improvement**: 50-100ms per execution

#### 5. Optimize Topic Naming Timeout
**Implementation**:
- Reduce timeout from 10s to 5s (still provides 2x buffer)
- Reduce retries from 3 to 2 (failures are rare)
- Add early failure detection (no output after 3s = permanent failure)

**Expected Improvement**: Reduces worst-case scenario from 30s to 15s (rare but impactful)

**Code Change**:
```bash
# Line 357: Change from
validate_agent_output_with_retry "topic-naming-agent" "$TOPIC_NAME_FILE" "validate_topic_name_format" 10 3

# To:
validate_agent_output_with_retry "topic-naming-agent" "$TOPIC_NAME_FILE" "validate_topic_name_format" 5 2
```

#### 6. Simplify Agent Behavioral Files
**Implementation**:
- Extract common patterns to shared behavioral templates
- Reduce instruction redundancy across agents
- Create concise "quick reference" versions for simple operations

**Expected Improvement**: Faster LLM processing, reduced context consumption

**Note**: This is a larger refactoring effort but would benefit all commands using agents.

### Low-Impact Optimizations (5-10% improvement potential)

#### 7. Cache Project Directory Detection
**Implementation**:
- Detect CLAUDE_PROJECT_DIR once in block 1a
- Export to environment or state file
- Reuse in subsequent blocks without re-detection

**Expected Improvement**: 50-100ms per execution

#### 8. Optimize State File Format
**Implementation**:
- Consider JSON or structured format vs bash variable format
- Enable batch reads without sourcing (use jq instead)
- Reduce grep operations for validation

**Expected Improvement**: 25-50ms per execution

**Trade-off**: Increased complexity, requires rewriting state-persistence.sh

### System-Wide Improvements

#### 9. Parallel Agent Execution (where dependencies allow)
**Implementation**:
- Execute topic naming and research in parallel when both only need FEATURE_DESCRIPTION
- Use background processes or Claude parallel task execution
- Synchronize before plan-architect invocation

**Expected Improvement**: Potential 20-40% reduction in wall-clock time for research-heavy plans

**Complexity**: Requires careful dependency analysis and error handling coordination

#### 10. Progress Streaming Optimization
**Implementation**:
- Reduce progress marker emissions (currently very verbose in agents)
- Batch progress updates (emit every N operations, not every operation)
- Consider async progress reporting vs inline

**Expected Improvement**: Cleaner output, slight performance gain

## References

### Files Analyzed

#### Primary Implementation
- `/home/benjamin/.config/.claude/commands/plan.md` (1,182 lines) - Main command implementation

#### Agent Specifications
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (684 lines) - Research agent behavioral file
- `/home/benjamin/.config/.claude/agents/plan-architect.md` (1,113 lines) - Planning agent behavioral file
- `/home/benjamin/.config/.claude/agents/topic-naming-agent.md` (500 lines) - Topic naming agent behavioral file

#### Core Libraries
- `/home/benjamin/.config/.claude/lib/core/state-persistence.sh` - State management (not fully examined)
- `/home/benjamin/.config/.claude/lib/core/error-handling.sh` - Error handling and logging
- `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh` - State machine implementation
- `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` (200+ lines) - Path initialization
- `/home/benjamin/.config/.claude/lib/plan/topic-utils.sh` (150+ lines) - Topic directory utilities
- `/home/benjamin/.config/.claude/lib/plan/plan-core-bundle.sh` (1,160 lines) - Plan manipulation utilities

#### Supporting Libraries
- `/home/benjamin/.config/.claude/lib/workflow/metadata-extraction.sh` - Metadata extraction utilities
- `/home/benjamin/.config/.claude/lib/workflow/context-pruning.sh` - Context size optimization
- `/home/benjamin/.config/.claude/lib/workflow/checkpoint-utils.sh` - Checkpoint management

### Key Performance Patterns Identified

1. **Three-Tier Sourcing Pattern** (lines 122-145, plan.md):
   - Tier 1: Critical libraries with fail-fast (state, workflow, error handling)
   - Tier 2: Support libraries with graceful degradation
   - Pattern is sound but executed redundantly across blocks

2. **State Persistence Pattern** (scattered throughout):
   - `init_workflow_state()` - Creates state file
   - `append_workflow_state()` - Individual variable writes
   - `save_completed_states_to_state()` - Persist transitions
   - Multiple writes per execution create I/O overhead

3. **Validation Pattern** (blocks 2 & 3):
   - Defensive validation at block entry
   - Error logging with JSON construction
   - Repeated validations across blocks

4. **Agent Invocation Pattern**:
   - Sequential execution with validation between agents
   - No parallelization despite limited dependencies
   - Retry logic with conservative timeouts

### Performance Measurement Recommendations

To validate optimization impact, implement timing instrumentation:

```bash
# Add to beginning of each block
BLOCK_START=$(date +%s%N)

# Add to end of each block
BLOCK_END=$(date +%s%N)
BLOCK_DURATION=$(( (BLOCK_END - BLOCK_START) / 1000000 ))
echo "DEBUG: Block N completed in ${BLOCK_DURATION}ms" >&2
```

Track metrics:
- Total execution time (end-to-end)
- Per-block execution time
- Agent response times
- State I/O operations count
- Library sourcing time

### Next Steps for Implementation

1. **Immediate (Quick Wins)**:
   - Reduce topic naming timeout to 5s (#5)
   - Add source guards to all libraries (#3)
   - Cache project directory detection (#7)

2. **Short-term (1-2 weeks)**:
   - Consolidate bash blocks (#2)
   - Batch state operations (#1)
   - Streamline validations (#4)

3. **Medium-term (1-2 months)**:
   - Simplify agent behavioral files (#6)
   - Implement parallel agent execution (#9)
   - Optimize state file format (#8)

4. **Long-term (Strategic)**:
   - System-wide context optimization
   - Agent instruction refactoring
   - Performance monitoring dashboard
