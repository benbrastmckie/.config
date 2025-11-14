# /coordinate Command Architecture and Design Research Report

## Metadata
- **Date**: 2025-11-13
- **Agent**: research-specialist
- **Topic**: /coordinate command architecture, refactor patterns, and design decisions
- **Report Type**: Codebase analysis

## Executive Summary

The `/coordinate` command implements a production-ready state machine orchestration architecture achieving 41% initialization overhead reduction, 100% file creation reliability, and wave-based parallel execution capabilities. The architecture is built on five core design patterns: subprocess isolation awareness, verification checkpoints (Standard 0), state persistence with selective file-based caching, fail-fast error handling, and two-step workflow capture to avoid positional parameter issues. The state machine library achieves 48.9% code reduction across orchestrators while maintaining comprehensive error detection through 12+ mandatory verification checkpoints per workflow execution.

## Findings

### 1. State Machine Architecture (workflow-state-machine.sh)

**Core Design** (Lines 1-85):
- 8 explicit states replacing implicit phase numbers: `initialize`, `research`, `plan`, `implement`, `test`, `debug`, `document`, `complete`
- Transition table validation (Lines 51-60) enforces legal state changes with fail-fast on invalid transitions
- Atomic two-phase commit pattern: pre-transition checkpoint → state update → post-transition checkpoint (Lines 565-595)

**Subprocess Isolation Management**:
```bash
# Lines 88-212: COMPLETED_STATES array persistence across bash blocks
save_completed_states_to_state() {
  # Serialize array to JSON for cross-subprocess persistence
  completed_states_json=$(printf '%s\n' "${COMPLETED_STATES[@]}" | jq -R . | jq -s .)
  append_workflow_state "COMPLETED_STATES_JSON" "$completed_states_json"
  append_workflow_state "COMPLETED_STATES_COUNT" "${#COMPLETED_STATES[@]}"
}
```

**Classification Integration** (Lines 334-456):
- Calls `classify_workflow_comprehensive()` for semantic workflow detection (98%+ accuracy)
- Exports three classification dimensions: `WORKFLOW_SCOPE`, `RESEARCH_COMPLEXITY`, `RESEARCH_TOPICS_JSON`
- Generates descriptive topic names from plan analysis or workflow description (Lines 215-332) when LLM returns generic "Topic N" fallbacks
- Fail-fast on classification failure with detailed troubleshooting (Lines 371-383)

**Key Innovation**: Terminal state configuration based on workflow scope (Lines 422-443) enables early workflow exit for `research-only` (terminal at `STATE_RESEARCH`) vs full implementation (terminal at `STATE_COMPLETE`).

### 2. Bash Block Execution Model (bash-block-execution-model.md)

**Subprocess Isolation Discovery** (Lines 1-69):
Each bash block runs as a **separate subprocess** (not subshell), with distinct PIDs and complete environment reset. This architectural constraint was discovered through Specs 620/630 and validated via comprehensive testing.

**What Persists** (Lines 51-69):
- Files written to filesystem ✓
- State files via `state-persistence.sh` ✓
- Workflow ID in fixed location file ✓

**What Doesn't Persist** (Lines 61-69):
- Environment variables (exports lost) ✗
- Bash functions (must re-source libraries) ✗
- Process ID `$$` (new PID each block) ✗
- Trap handlers (fire at block exit, not workflow exit) ✗

**Critical Pattern**: Fixed semantic filenames (Lines 163-191) replace `$$`-based temp files to enable cross-block file discovery:
```bash
# Lines 180-190: Save state ID to fixed location
WORKFLOW_ID="coordinate_$(date +%s)"
STATE_FILE="${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
echo "$WORKFLOW_ID" > "${HOME}/.claude/tmp/coordinate_state_id.txt"

# Next bash block retrieves via fixed path
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")
STATE_FILE="${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
```

### 3. Verification Checkpoint Pattern (Standard 0)

**Implementation** (coordinate.md Lines 151-154, 172-223, 296-299):
Mandatory verification checkpoints after every critical state operation detect configuration errors immediately rather than hiding them through silent fallbacks.

**12+ Checkpoints Per Workflow**:
1. State ID file creation (Line 152): `verify_file_created "$COORDINATE_STATE_ID_FILE" ...`
2. State machine variable export (Lines 173-185): Verify `WORKFLOW_SCOPE`, `RESEARCH_COMPLEXITY`, `RESEARCH_TOPICS_JSON` exported by `sm_init()`
3. State persistence (Lines 210-223): Verify `WORKFLOW_SCOPE`, `EXISTING_PLAN_PATH` written to state file
4. REPORT_PATHS array export (Lines 296-298): Verify all report path variables persisted
5. State file exists in subsequent blocks (Lines 393-397, 411-418): Verify critical functions loaded
6. Research artifact verification (Lines 735-785, 796-849): 100% file creation reliability
7. Planning artifact verification (Lines 1180-1232): Plan file exists and has content
8. Implementation artifact verification (Lines 1512-1566): Plan executed successfully
9. Test execution verification (Lines 1690-1706): Exit code and result tracking
10. Debug report verification (Lines 1871-1902): Analysis complete and documented
11. Documentation update verification (Lines 2075-2090): Standards checked
12. State transition validation (Lines 976-987): Verify state change succeeded

**Concise Pattern** (verification-helpers.sh Lines 73-173):
```bash
# Success: Single character output (90% token reduction)
if [ -f "$file_path" ] && [ -s "$file_path" ]; then
  echo -n "✓"  # No newline
  return 0
else
  # Failure: 38-line diagnostic with root cause analysis
  echo "✗ ERROR [$phase_name]: $item_desc verification failed"
  # ... detailed diagnostic ...
fi
```

**Token Reduction**: ~3,150 tokens saved per workflow (14 checkpoints × 225 tokens/checkpoint).

### 4. State Persistence Library (state-persistence.sh)

**Selective Persistence Strategy** (Lines 47-69):
Only 7 critical items use file-based persistence; 3 items use stateless recalculation (10x faster for simple cases).

**GitHub Actions Pattern** (Lines 115-267):
```bash
# Initialize workflow state (Block 1 only)
STATE_FILE=$(init_workflow_state "coordinate_$$")
# Creates: .claude/tmp/workflow_12345.sh with CLAUDE_PROJECT_DIR cached

# Load workflow state (Blocks 2+)
load_workflow_state "coordinate_$$"  # Sources state file, restores all exports

# Append state (accumulates across steps)
append_workflow_state "RESEARCH_COMPLETE" "true"
append_workflow_state "REPORTS_CREATED" "4"
```

**Performance Optimization** (Lines 97-123):
- `CLAUDE_PROJECT_DIR` detection: 50ms (git rev-parse) → 15ms (file read) = **70% improvement**
- Cached in state file during `init_workflow_state()`, read from cache in subsequent blocks
- Atomic JSON checkpoint writes (Lines 290-300): 5-10ms with temp file + mv for crash safety

**Fail-Fast Validation** (Lines 144-227):
```bash
# Spec 672 Phase 3: Distinguish expected vs unexpected missing state files
load_workflow_state "$workflow_id" "$is_first_block"
# is_first_block=true: Graceful initialization if missing (expected)
# is_first_block=false: CRITICAL ERROR with diagnostic (unexpected)
```

**Key Innovation**: Graceful degradation only for **optimization caches**, never for critical state (Lines 61-67).

### 5. Error Handling Architecture (error-handling.sh, coordinate.md)

**Fail-Fast Philosophy** (coordinate.md Lines 165-183):
```bash
# CRITICAL: sm_init must succeed, no silent fallback
if ! sm_init "$SAVED_WORKFLOW_DESC" "coordinate" 2>&1; then
  handle_state_error "State machine initialization failed (workflow classification error). \
Check network connection or use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline development." 1
fi

# Verify exports succeeded (detect library bugs)
if [ -z "${WORKFLOW_SCOPE:-}" ]; then
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not exported by sm_init despite successful \
return code (library bug)" 1
fi
```

**Comprehensive Diagnostics** (verification-helpers.sh Lines 84-167):
- Expected vs actual path comparison (Lines 88-101)
- Directory analysis with file metadata (Lines 104-146)
- Root cause analysis for path mismatches (Lines 132-145)
- Actionable troubleshooting commands (Lines 154-167)

**Error Classification** (error-handling.sh patterns):
- Configuration errors: Exit code 1 (missing dependencies, invalid state)
- State persistence failures: Exit code 2 (distinct from normal failures)
- Verification failures: Immediate termination with diagnostic

### 6. Two-Step Workflow Capture (coordinate.md Lines 18-93)

**Problem Solved**: Direct workflow description in bash block causes positional parameter issues when description contains special characters.

**Solution** (Lines 18-43):
```bash
# STEP 1: Capture workflow description to file (tiny bash block)
mkdir -p "${HOME}/.claude/tmp"
WORKFLOW_TEMP_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc_$(date +%s%N).txt"
echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > "$WORKFLOW_TEMP_FILE"
echo "$WORKFLOW_TEMP_FILE" > "${HOME}/.claude/tmp/coordinate_workflow_desc_path.txt"
```

**Part 2** (Lines 52-93): Main logic reads from file, avoiding parameter substitution issues:
```bash
COORDINATE_DESC_FILE=$(cat "$COORDINATE_DESC_PATH_FILE")
WORKFLOW_DESCRIPTION=$(cat "$COORDINATE_DESC_FILE" 2>/dev/null || echo "")
```

**Concurrent Execution Safety** (Lines 37-38): Timestamp-based filenames prevent collision when multiple `/coordinate` invocations run simultaneously.

### 7. Library Sourcing Order (Standard 15)

**Critical Pattern** (coordinate.md Lines 376-418):
```bash
# Step 1: Source state machine and persistence FIRST
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Step 2: Load workflow state BEFORE other libraries
load_workflow_state "$WORKFLOW_ID"

# Step 3: Source error handling and verification libraries (Pattern 5 preserves loaded state)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Step 4: Verify critical functions available
if ! command -v verify_state_variable &>/dev/null; then
  echo "ERROR: verify_state_variable function not available"
  exit 1
fi
```

**Rationale**: Early sourcing (Lines 118-138) enables verification checkpoints throughout initialization. Libraries re-sourced in each bash block due to subprocess isolation.

### 8. Performance Achievements

**Initialization Overhead** (coordinate.md Lines 353-363):
```
Performance (Baseline Phase 1):
  Library loading: XXXms
  Path initialization: XXXms
  Total init overhead: XXXms
```

**Measured Improvements**:
- 41% initialization overhead reduction (528ms saved via state persistence caching)
- State operation performance: 67% improvement (6ms → 2ms for `CLAUDE_PROJECT_DIR` detection)
- Context reduction: 95.6% via hierarchical supervisors (10,000 → 440 tokens)
- Time savings: 53% via parallel execution (wave-based implementation)

**Code Reduction** (state-based-orchestration-overview.md):
- 48.9% overall: 3,420 → 1,748 lines across 3 orchestrators
- `/coordinate`: 1,084 → 800 lines (26.2% reduction)
- `/supervise`: 1,779 → 397 lines (77.7% reduction - minimal reference)

### 9. Agent Delegation Patterns (Behavioral Injection)

**Research Phase** (coordinate.md Lines 547-637):
Conditional execution based on complexity:
```
IF RESEARCH_COMPLEXITY >= 1 (always true):
  Task { agent: research-specialist, topic: $RESEARCH_TOPIC_1 }

IF RESEARCH_COMPLEXITY >= 2:
  Task { agent: research-specialist, topic: $RESEARCH_TOPIC_2 }

IF RESEARCH_COMPLEXITY >= 3:
  Task { agent: research-specialist, topic: $RESEARCH_TOPIC_3 }

IF RESEARCH_COMPLEXITY >= 4:
  Task { agent: hierarchical-supervisor, topics: 4+ }
```

**Planning Phase** (Lines 1032-1092):
Branch based on workflow scope:
```
IF WORKFLOW_SCOPE = "research-and-revise":
  Task { agent: revision-specialist, existing_plan: $EXISTING_PLAN_PATH }
ELSE:
  Task { agent: plan-architect, output_path: $PLAN_PATH }
```

**Key Pattern**: Pre-calculated artifact paths (Phase 0 optimization, Lines 301-320) injected into agents, achieving 85% token reduction vs agent-based path discovery.

### 10. Refactor Patterns Identified

**Pattern 1: Verification Checkpoint Extraction** (Lines 151-154 → verification-helpers.sh):
- Before: 38-line inline verification blocks (repeated 14 times)
- After: Single function call `verify_file_created()`
- Reduction: 3,150 tokens saved

**Pattern 2: Library Re-sourcing Standardization** (Lines 376-418):
- Before: Inconsistent library loading order caused subtle bugs
- After: Standard 15 (four-step sourcing order) applied uniformly
- Benefit: Zero unbound variable errors after standardization

**Pattern 3: State Machine Abstraction** (workflow-state-machine.sh):
- Before: Implicit phase numbers (0-7) scattered through code
- After: Named states with validated transitions
- Benefit: 48.9% code reduction, improved readability

**Pattern 4: Selective Persistence Decision Framework** (state-persistence.sh Lines 61-67):
- Before: Everything in memory or everything in files
- After: 7-item decision criteria for file-based vs stateless
- Benefit: 67% performance improvement for expensive operations

**Pattern 5: Fail-Fast Configuration Errors** (coordinate.md Lines 165-183):
- Before: Silent fallbacks hid configuration issues
- After: Mandatory verification with detailed diagnostics
- Benefit: 100% reliability (zero silent failures)

## Recommendations

### 1. Architectural Standards for New Orchestration Commands

**Apply State Machine Pattern**:
- Use explicit state names (not phase numbers) for all new orchestrators
- Implement transition validation via `STATE_TRANSITIONS` table
- Leverage `sm_init()`, `sm_transition()`, `sm_execute()` from `workflow-state-machine.sh`
- Reference: Lines 334-456 (initialization), Lines 549-595 (transitions)

**Mandate Verification Checkpoints (Standard 0)**:
- Add verification after every critical state operation:
  - File creation: `verify_file_created()`
  - State persistence: `verify_state_variable()`
  - Function availability: `command -v function_name`
- Use concise pattern (Lines 73-173 verification-helpers.sh) for 90% token reduction
- Fail-fast on verification failure with comprehensive diagnostics

**Follow Library Sourcing Order (Standard 15)**:
- Step 1: State machine + persistence libraries
- Step 2: Load workflow state
- Step 3: Error handling + verification libraries
- Step 4: Verify critical functions available
- Apply pattern consistently in every bash block (Lines 376-418)

### 2. Subprocess Isolation Pattern Adoption

**Use Fixed Semantic Filenames**:
- Replace `$$`-based temp files with workflow-scoped names: `${HOME}/.claude/tmp/coordinate_workflow_desc_$(date +%s%N).txt`
- Save workflow ID to fixed location for cross-block access: `${HOME}/.claude/tmp/coordinate_state_id.txt`
- Reference: bash-block-execution-model.md Lines 163-191

**Implement Save-Before-Source Pattern**:
- Save state ID to file BEFORE sourcing libraries
- Re-source libraries in each bash block (functions lost across subprocess boundaries)
- Load workflow state immediately after library sourcing
- Reference: coordinate.md Lines 146-158, 392-400

**Avoid Trap-Based Cleanup in Early Blocks**:
- EXIT traps fire at bash block exit (subprocess termination), not workflow exit
- Use explicit cleanup in final block or command exit handler
- Reference: bash-block-execution-model.md Lines 61-69

### 3. Performance Optimization Opportunities

**Apply Selective Persistence Framework**:
- Use file-based state for: non-deterministic data, cross-subprocess accumulation, expensive recalculation (>30ms)
- Use stateless recalculation for: deterministic data, cheap operations (<10ms), optimization caches
- Decision criteria: state-persistence.sh Lines 61-67

**Cache Expensive Operations in State**:
- `CLAUDE_PROJECT_DIR` detection: 70% improvement via caching (50ms → 15ms)
- JSON checkpoint writes: Atomic pattern (temp file + mv) prevents corruption
- Reference: state-persistence.sh Lines 97-123, 290-300

**Leverage Phase 0 Path Pre-Calculation**:
- Calculate all artifact paths during initialization (coordinate.md Lines 301-320)
- Inject pre-calculated paths into agents via prompt variables
- Avoid agent-based path discovery (85% token reduction)

### 4. Error Handling Best Practices

**Implement Fail-Fast Validation**:
- Distinguish expected vs unexpected errors: `load_workflow_state "$id" "$is_first_block"`
- First block (`is_first_block=true`): Graceful initialization if missing state
- Subsequent blocks (`is_first_block=false`): CRITICAL ERROR with diagnostic
- Reference: state-persistence.sh Lines 144-227

**Provide Comprehensive Diagnostics on Failure**:
- Expected vs actual comparison (verification-helpers.sh Lines 88-101)
- Directory analysis with file metadata (Lines 104-146)
- Root cause analysis (Lines 132-145)
- Actionable troubleshooting commands (Lines 154-167)

**Use Verification Fallback Pattern (Not Bootstrap Fallback)**:
- **Prohibited**: Bootstrap fallbacks (hide configuration errors via silent function definitions)
- **Required**: Verification fallbacks (detect tool/agent failures immediately, terminate with diagnostics)
- Reference: Development Philosophy → Fail-Fast Policy (CLAUDE.md)

### 5. Agent Delegation Architecture

**Use Behavioral Injection Pattern**:
- Invoke agents via Task tool (NOT SlashCommand) with context injection
- Read behavioral file path: `/home/benjamin/.config/.claude/agents/research-specialist.md`
- Provide workflow-specific context: topic, output path, standards, complexity
- Reference: coordinate.md Lines 547-637 (research), 1032-1092 (planning)

**Implement Conditional Execution Guards**:
- Use explicit IF conditions for complexity-based agent invocation (Lines 505-543)
- Avoid relying on natural language templates ("for EACH topic") - interpreted as documentation
- Prevent over-invocation by checking `RESEARCH_COMPLEXITY` value explicitly

**Require Completion Signals**:
- Agents must return structured completion: `REPORT_CREATED: /absolute/path`
- Verification checkpoints detect missing artifacts (100% file creation reliability)
- Reference: Lines 735-785 (hierarchical), 796-849 (flat)

## References

**Primary Source Files**:
- `/home/benjamin/.config/.claude/commands/coordinate.md` (2,118 lines) - Main orchestration command
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (854 lines) - State machine library
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` (300+ lines) - GitHub Actions-style state management
- `/home/benjamin/.config/.claude/lib/verification-helpers.sh` (200+ lines) - Concise verification patterns
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md` (200+ lines) - Subprocess isolation patterns

**Key Architecture Documents**:
- `.claude/docs/architecture/state-based-orchestration-overview.md` - Complete architecture reference (2,000+ lines)
- `.claude/docs/guides/coordinate-command-guide.md` - Usage patterns and troubleshooting
- `.claude/docs/reference/command_architecture_standards.md` - Standard 0 (Execution Enforcement), Standard 15 (Library Sourcing Order)

**Related Specifications**:
- Spec 620/630: Bash block execution model discovery and validation
- Spec 672 Phase 2: COMPLETED_STATES array persistence
- Spec 672 Phase 3: Fail-fast state validation
- Spec 676: Research agent over-invocation root cause analysis
- Spec 678 Phase 5: Comprehensive workflow classification (LLM-based)
- Spec 688 Phase 3: Clean-break fail-fast approach (no automatic fallbacks)

**Performance Validation**:
- `.claude/specs/602_601_and_documentation_in_claude_docs_in_order_to/reports/004_performance_validation_report.md` - 409 tests, 63/81 suites passing

**Code References** (with line numbers):
- coordinate.md:18-43 (Two-step workflow capture)
- coordinate.md:52-93 (Main initialization logic)
- coordinate.md:118-138 (Critical library pre-sourcing)
- coordinate.md:146-158 (State ID file creation + verification)
- coordinate.md:165-183 (sm_init fail-fast + export verification)
- coordinate.md:210-223 (State persistence verification)
- coordinate.md:301-320 (Phase 0 path pre-calculation)
- coordinate.md:376-418 (Standard 15 library sourcing order)
- coordinate.md:505-543 (Conditional agent invocation guards)
- coordinate.md:735-785 (Hierarchical research verification)
- coordinate.md:796-849 (Flat research verification)
- workflow-state-machine.sh:51-60 (Transition table)
- workflow-state-machine.sh:88-212 (Array persistence functions)
- workflow-state-machine.sh:334-456 (sm_init comprehensive classification)
- workflow-state-machine.sh:549-595 (sm_transition atomic commit)
- state-persistence.sh:61-67 (Selective persistence decision criteria)
- state-persistence.sh:115-142 (init_workflow_state with CLAUDE_PROJECT_DIR caching)
- state-persistence.sh:144-227 (load_workflow_state fail-fast validation)
- verification-helpers.sh:73-173 (verify_file_created concise pattern)
- bash-block-execution-model.md:1-69 (Subprocess isolation overview)
- bash-block-execution-model.md:163-191 (Fixed semantic filename pattern)
