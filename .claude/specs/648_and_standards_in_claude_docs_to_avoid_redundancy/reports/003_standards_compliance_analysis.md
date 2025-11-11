# Standards Compliance Analysis for /coordinate Command Fixes

## Metadata
- **Report Type**: Standards Compliance Analysis
- **Research Date**: 2025-11-10
- **Research Topic**: Standards in .claude/docs/ relevant to coordinate command fixes
- **Scope**: Command architecture, bash execution, state management, verification patterns
- **Project Standards**: /home/benjamin/.config/CLAUDE.md

## Executive Summary

This analysis identifies architectural standards and patterns in `.claude/docs/` that /coordinate command fixes must follow to maintain consistency with established project architecture. The analysis covers five critical areas:

1. **Command Architecture Standards** (Standard 0, 11, 13, 14)
2. **Bash Block Execution Model** (subprocess isolation patterns)
3. **State Management Patterns** (selective persistence, stateless recalculation)
4. **Verification and Fallback Pattern** (Standard 0 requirements)
5. **Error Handling Guidelines** (fail-fast principles)

**Key Finding**: All /coordinate fixes must align with the state-based orchestration architecture, which provides centralized state management, validated transitions, and selective state persistence. The bash block execution model (subprocess isolation) is a foundational constraint that requires specific patterns for cross-block state management.

## 1. Command Architecture Standards

### Standard 0: Execution Enforcement

**Location**: `.claude/docs/reference/command_architecture_standards.md` (lines 52-463)

**Purpose**: Distinguish between descriptive documentation and mandatory execution directives using specific linguistic patterns and verification checkpoints.

**Key Requirements for /coordinate**:

1. **Imperative Language Patterns**:
   - Use "YOU MUST", "EXECUTE NOW", "MANDATORY" for critical steps
   - Avoid "should", "may", "can" in critical sections
   - Example: "YOU MUST invoke research agents in this exact sequence"

2. **Verification Checkpoints**:
   ```markdown
   **MANDATORY VERIFICATION - Report File Existence**

   After agents complete, YOU MUST execute this verification:

   ```bash
   for topic in "${!REPORT_PATHS[@]}"; do
     EXPECTED_PATH="${REPORT_PATHS[$topic]}"
     if [ ! -f "$EXPECTED_PATH" ]; then
       echo "CRITICAL: Report missing at $EXPECTED_PATH"
       # Fallback handling required
     fi
   done
   ```
   ```

3. **Phase 0 Requirement** (lines 309-416):
   - MUST pre-calculate all artifact paths before invoking subagents
   - Pattern: `get_or_create_topic_dir()`, `create_topic_artifact()`
   - Rationale: Orchestrator controls paths, not agents

4. **Relationship to Fail-Fast Policy** (lines 419-462):
   - Verification fallbacks DETECT errors (fail-fast compliant)
   - Bootstrap fallbacks HIDE errors (fail-fast violation)
   - Critical distinction: Detection vs. masking

**Application to /coordinate Fixes**:
- All file creation operations require MANDATORY VERIFICATION checkpoints
- Pre-calculate report paths in Phase 0
- Use imperative language for critical steps
- Verification checkpoints must include grep patterns matching state file format

### Standard 0.5: Subagent Prompt Enforcement

**Location**: `.claude/docs/reference/command_architecture_standards.md` (lines 464-975)

**Purpose**: Extension of Standard 0 for agent definition files, ensuring agents create files reliably.

**Key Patterns**:

1. **Sequential Step Dependencies**:
   ```markdown
   **STEP 1 (REQUIRED BEFORE STEP 2) - Pre-Calculate Report Path**

   EXECUTE NOW - Calculate the exact file path where you will write the report

   **STEP 2 (REQUIRED BEFORE STEP 3) - Conduct Research**

   YOU MUST investigate the codebase using Grep, Glob, and Read tools

   **STEP 3 (ABSOLUTE REQUIREMENT) - Create Report File**

   YOU MUST use the Write tool to create the report file at the exact path from Step 1
   ```

2. **File Creation as Primary Obligation**:
   - Elevate file creation to highest priority in agent behavioral files
   - Priority order: Create file → Populate content → Verify → Return confirmation

**Application to /coordinate Fixes**:
- Agent behavioral files must use imperative language
- Sequential dependencies explicit in agent steps
- File creation marked as PRIMARY OBLIGATION

### Standard 11: Imperative Agent Invocation Pattern

**Location**: `.claude/docs/reference/command_architecture_standards.md` (lines 1173-1352)

**Purpose**: Ensure Task invocations use imperative instructions that signal immediate execution, preventing 0% agent delegation rate.

**Key Requirements**:

1. **Imperative Instruction**: Use explicit execution markers
   - Pattern: `**EXECUTE NOW**: USE the Task tool to invoke...`
   - Anti-pattern: "Example agent invocation:" (documentation-only)

2. **No Code Block Wrappers**: Task invocations must NOT be fenced
   - ❌ WRONG: ` ```yaml ... Task { ... } ... ``` `
   - ✅ CORRECT: `Task { ... }` (no fence)

3. **Agent Behavioral File Reference**: Direct reference to agent guidelines
   - Pattern: `Read and follow: .claude/agents/research-specialist.md`

4. **Completion Signal Requirement**: Agent must return explicit confirmation
   - Pattern: `Return: REPORT_CREATED: ${REPORT_PATH}`

**Historical Context**:
- Spec 438: /supervise agent delegation fix (0% → >90%)
- Spec 495: /coordinate and /research fixes (0% → >90%)
- Spec 057: /supervise robustness improvements

**Performance Metrics**:
- Agent delegation rate: >90% (all invocations execute)
- File creation rate: 100% (agents create artifacts at expected paths)
- Bootstrap reliability: 100% (fail-fast exposes configuration errors immediately)

**Application to /coordinate Fixes**:
- All Task invocations use imperative pattern
- No YAML code block wrappers around Task invocations
- Agent behavioral file references in all Task prompts
- Completion signals required for verification

### Standard 13: Project Directory Detection

**Location**: `.claude/docs/reference/command_architecture_standards.md` (lines 1457-1532)

**Purpose**: Commands MUST use `CLAUDE_PROJECT_DIR` for project-relative paths, not `${BASH_SOURCE[0]}`.

**Implementation**:
```bash
# Detect project directory if not already set
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
```

**Rationale**:
- `${BASH_SOURCE[0]}` unavailable in SlashCommand execution context
- Git-based detection handles worktrees correctly
- Consistent with library implementation patterns

**Application to /coordinate Fixes**:
- Every bash block must include Standard 13 detection
- All library sourcing uses `${CLAUDE_PROJECT_DIR}/.claude/lib/`
- No reliance on `${BASH_SOURCE[0]}` in command files

### Standard 14: Executable/Documentation File Separation

**Location**: `.claude/docs/reference/command_architecture_standards.md` (lines 1534-1689)

**Purpose**: Commands MUST separate executable logic from comprehensive documentation into distinct files.

**Pattern**: Two-file architecture
1. **Executable Command File** (`.claude/commands/command-name.md`)
   - Size: Target <250 lines (simple), max 1,200 lines (complex orchestrators)
   - Content: Bash blocks, phase markers, minimal inline comments

2. **Command Guide File** (`.claude/docs/guides/command-name-command-guide.md`)
   - Size: Unlimited (500-5,000 lines typical)
   - Content: Architecture, examples, troubleshooting, design decisions

**Benefits**:
- Meta-confusion elimination: 0% incident rate (was 75% pre-migration)
- Context reduction: 70% average reduction in executable file size
- Independent evolution: Logic changes don't touch docs

**Application to /coordinate Fixes**:
- Keep /coordinate executable lean (<1,200 lines)
- Move architecture explanations to coordinate-command-guide.md
- Single-line documentation reference in executable
- Validation: Run `.claude/tests/validate_executable_doc_separation.sh`

## 2. Bash Block Execution Model

### Overview

**Location**: `.claude/docs/concepts/bash-block-execution-model.md`

**Core Constraint**: Each bash block in Claude Code commands runs as a **separate subprocess**, not a subshell. This architectural constraint has significant implications for state management and variable persistence.

**Discovery**: Patterns discovered and validated through Specs 620 and 630 (100% test pass rate).

### Key Characteristics

**Subprocess Isolation**:
- Each bash block runs in completely separate process (different PID)
- All environment variables reset (exports lost)
- All bash functions lost (must re-source libraries)
- Trap handlers fire at block exit, not workflow exit
- **Only files persist across blocks**

**What Persists vs What Doesn't**:

| Item | Persists? | Method |
|------|-----------|--------|
| Files | ✓ | Written to filesystem |
| State files | ✓ | Via state-persistence.sh |
| Workflow ID | ✓ | Fixed location file |
| Environment variables | ✗ | New process |
| Bash functions | ✗ | Not inherited |
| Process ID ($$) | ✗ | New PID per block |
| Trap handlers | ✗ | Fire at block exit |

### Validated Patterns

**Pattern 1: Fixed Semantic Filenames** (lines 163-191):
```bash
# ❌ ANTI-PATTERN: PID-based filename
cat > /tmp/workflow_$$.sh <<'EOF'
# File created: /tmp/workflow_12345.sh
EOF
# Next bash block (different PID): File not found

# ✓ RECOMMENDED: Fixed semantic filename
WORKFLOW_ID="coordinate_$(date +%s)"
STATE_FILE="${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
```

**Pattern 2: Save-Before-Source Pattern** (lines 193-224):
```bash
# Part 1: Initialize and save state ID
WORKFLOW_ID="coordinate_$(date +%s)"
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"

# Part 2: Load state ID and source state (in next bash block)
WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
STATE_FILE="${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
source "$STATE_FILE"
```

**Pattern 3: State Persistence Library** (lines 226-248):
```bash
# In each bash block:
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

# Update state
append_workflow_state "CURRENT_STATE" "research"
append_workflow_state "REPORT_COUNT" "3"
```

**Pattern 4: Library Re-sourcing with Source Guards** (lines 250-286):
```bash
# At start of EVERY bash block:
set +H  # CRITICAL: Disable history expansion

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

**Pattern 5: Cleanup on Completion Only** (lines 288-305):
```bash
# ❌ ANTI-PATTERN: Trap in early block
trap 'rm -f /tmp/workflow_*.sh' EXIT  # Fires at block exit

# ✓ RECOMMENDED: Trap only in completion function
display_brief_summary() {
  trap 'rm -f /tmp/workflow_*.sh' EXIT
  echo "Workflow complete"
}
```

### Critical Libraries for Re-sourcing

**Must re-source in EVERY bash block** (lines 307-359):

1. **workflow-state-machine.sh**: State machine operations
2. **state-persistence.sh**: GitHub Actions-style state files
3. **workflow-initialization.sh**: Path detection and initialization
4. **error-handling.sh**: Fail-fast error handling
5. **unified-logger.sh**: Progress markers and summaries (provides `emit_progress`, `display_brief_summary`)
6. **verification-helpers.sh**: File creation verification

**Common Errors from Missing Libraries**:
- `emit_progress: command not found` → Missing unified-logger.sh
- `display_brief_summary: command not found` → Missing unified-logger.sh
- `handle_state_error: command not found` → Missing error-handling.sh
- `sm_transition: command not found` → Missing workflow-state-machine.sh

**Application to /coordinate Fixes**:
- Include `set +H` at start of every bash block
- Re-source all 6 libraries in every bash block
- Use fixed semantic filenames (not $$-based)
- Only set cleanup traps in final completion function
- Always test bash block sequences with actual subprocess execution

## 3. State Management Patterns

### Coordinate State Management Architecture

**Location**: `.claude/docs/architecture/coordinate-state-management.md`

**Core Pattern**: Stateless Recalculation

**Definition**: Every bash block independently recalculates all variables it needs, without relying on state from previous blocks.

**Rationale**: Subprocess isolation (each bash block = separate process) means exports don't persist. Stateless recalculation is 30x faster than file-based state for simple variables (<1ms vs 30ms).

### Decision Matrix

**Use Stateless Recalculation When**:
- Variable count <10
- Recalculation cost <100ms
- Deterministic calculation
- No cross-invocation persistence needed
- **Examples**: CLAUDE_PROJECT_DIR, WORKFLOW_SCOPE, PHASES_TO_EXECUTE

**Use File-Based State When**:
- Recalculation cost >1 second
- State must persist across /coordinate invocations
- Heavy data structures (arrays with 100+ elements)
- **Examples**: Expensive codebase analysis, dependency graphs

**Performance Comparison**:
| Pattern | Overhead | When Cost is Acceptable |
|---------|----------|-------------------------|
| Stateless recalculation | <1ms | Always (negligible) |
| File-based state | 30ms I/O | Computation >1s (net savings) |
| Single large block | 0ms | <300 lines, no subagents |
| Checkpoint files | 50-100ms | Multi-phase workflows (amortized) |

### Selective State Persistence

**Location**: `.claude/docs/architecture/state-based-orchestration-overview.md` (lines 356-676)

**Pattern**: Hybrid approach combining stateless recalculation for fast operations with file-based state for critical items.

**Decision Criteria** (7 criteria):
1. State accumulates across subprocess boundaries
2. Context reduction requires metadata aggregation
3. Success criteria validation needs objective evidence
4. Resumability is valuable
5. State is non-deterministic
6. Recalculation is expensive (>30ms)
7. Phase dependencies require prior phase outputs

**Critical State Items Using File-Based Persistence** (7 of 10 analyzed = 70%):
- Supervisor metadata (95% context reduction)
- Benchmark dataset (Phase 3 accumulation)
- Implementation supervisor state (40-60% time savings)
- Testing supervisor state (lifecycle coordination)
- Migration progress (resumable)
- Performance benchmarks (Phase 3 dependency)
- POC metrics (success criterion validation)

**State Items Using Stateless Recalculation** (3 of 10 = 30%):
- File verification cache (10x faster than file I/O)
- Track detection results (deterministic, <1ms)
- Guide completeness checklist (markdown sufficient)

**GitHub Actions Pattern Adaptation**:
```bash
# Block 1: Initialize state file
STATE_FILE=$(init_workflow_state "coordinate_$$")

# Block 2+: Load workflow state
load_workflow_state "coordinate_$$"

# Append new state (GitHub Actions $GITHUB_OUTPUT pattern)
append_workflow_state "RESEARCH_COMPLETE" "true"
```

**Performance**:
- `init_workflow_state()`: ~6ms (includes git rev-parse)
- `load_workflow_state()`: ~2ms (file read)
- **Improvement**: 67% faster (6ms → 2ms)

**Application to /coordinate Fixes**:
- Use stateless recalculation for WORKFLOW_SCOPE, PHASES_TO_EXECUTE
- Use file-based state for CLAUDE_PROJECT_DIR (6ms → 2ms savings)
- Re-source state-persistence.sh in every bash block
- Apply decision criteria systematically (not blanket file-based)

### Verification Checkpoint Pattern

**Location**: `.claude/docs/architecture/coordinate-state-management.md` (lines 722-824)

**Critical Requirement**: Verification must account for export format used by `state-persistence.sh`.

**State File Format**:
```bash
# From state-persistence.sh:216
echo "export ${key}=\"${value}\"" >> "$STATE_FILE"

# Example state file:
export CLAUDE_PROJECT_DIR="/path/to/project"
export WORKFLOW_ID="coordinate_1762816945"
export REPORT_PATHS_COUNT="4"
export REPORT_PATH_0="/path/to/report1.md"
```

**Verification Pattern (Correct)**:
```bash
# State file format: "export VAR="value"" (per state-persistence.sh)
if grep -q "^export VARIABLE_NAME=" "$STATE_FILE" 2>/dev/null; then
  echo "✓ Variable verified"
else
  echo "✗ Variable missing"
  exit 1
fi
```

**Anti-Pattern (Incorrect)**:
```bash
# DON'T: This pattern won't match export format
if grep -q "^VARIABLE_NAME=" "$STATE_FILE" 2>/dev/null; then
  echo "✓ Variable verified"  # Will never execute
fi
```

**Historical Bug** (Spec 644):
- Grep patterns searched for `^REPORT_PATHS_COUNT=` but state file contained `export REPORT_PATHS_COUNT="4"`
- Impact: Critical (blocked all coordinate workflows)
- Fix: Added `export ` prefix to grep patterns

**Best Practices**:
1. Always include `export ` prefix in grep patterns
2. Add clarifying comments documenting expected format
3. Test verification logic to catch false negatives/positives
4. Check actual state file during debugging

**Application to /coordinate Fixes**:
- All verification checkpoints must use `^export VAR_NAME=` pattern
- Add comments referencing state-persistence.sh format
- Test verification logic with actual state files
- Document format in verification checkpoint comments

## 4. Verification and Fallback Pattern

### Overview

**Location**: `.claude/docs/concepts/patterns/verification-fallback.md`

**Purpose**: MANDATORY VERIFICATION checkpoints with fallback file creation mechanisms achieve 100% file creation rates.

**Pattern Components**:
1. **Path Pre-Calculation**: Calculate all file paths before execution
2. **Verification Checkpoints**: MANDATORY VERIFICATION after each file creation
3. **Fallback Mechanisms**: Create missing files if verification fails (DETECTION not MASKING)

### Relationship to Fail-Fast Policy

**Key Distinction** (lines 19-58):

**Detection (Fail-Fast Component)**:
- MANDATORY VERIFICATION exposes file creation failures immediately
- No silent continuation when expected files missing
- Clear diagnostics showing exactly what failed
- Workflow terminates with troubleshooting guidance

**Agent Responsibility (Fail-Fast Enforcement)**:
- Agents must create their own artifacts using Write tool
- Orchestrator verifies existence (detection mechanism)
- Orchestrator does NOT create placeholder files (would mask agent failures)
- Missing files indicate agent behavioral issues requiring fixes

**Critical Distinction** (Spec 057):
- **Bootstrap fallbacks**: HIDE configuration errors → PROHIBITED
- **Verification checkpoints**: DETECT tool failures → REQUIRED
- **Placeholder file creation**: MASK agent failures → PROHIBITED
- **Optimization fallbacks**: Performance caches only → ACCEPTABLE

**Why This Aligns With Fail-Fast**:
- Agent completes → file missing → CRITICAL error logged
- Workflow terminates immediately (not after all phases)
- Clear troubleshooting steps guide user to root cause
- No placeholder files masking agent failures
- Result: 100% file creation through proper agent implementation

### Implementation

**Step 1: Path Pre-Calculation** (lines 80-101):
```markdown
## EXECUTE NOW - Calculate Paths

MANDATORY: Calculate ALL file paths before proceeding to execution

1. Determine project root: /home/benjamin/.config
2. Calculate topic directory: specs/027_authentication/
3. Assign report paths:
   REPORT_1="${topic_dir}/reports/001_oauth_patterns.md"
```

**Step 2: MANDATORY VERIFICATION Checkpoints** (lines 103-125):
```markdown
## MANDATORY VERIFICATION - Report Creation

EXECUTE NOW (REQUIRED BEFORE NEXT STEP):

1. Verify report file exists:
   ls -la specs/027_authentication/reports/001_oauth_patterns.md

2. Verify file size > 0:
   [ -s specs/027_authentication/reports/001_oauth_patterns.md ] && echo "✓ File created"

3. If verification fails, proceed to FALLBACK MECHANISM
```

**Step 3: Fallback File Creation** (lines 127-150):
```markdown
## FALLBACK MECHANISM - Manual File Creation

TRIGGER: File verification failed

EXECUTE IMMEDIATELY:

1. Create file directly using Write tool
2. MANDATORY VERIFICATION (repeat)
3. If still fails, escalate to user with error details
```

### Performance Impact

**Measurable Improvements** (lines 386-434):

| Command | Before Pattern | After Pattern | Improvement |
|---------|---------------|---------------|-------------|
| /report | 7/10 (70%) | 10/10 (100%) | +43% |
| /plan | 6/10 (60%) | 10/10 (100%) | +67% |
| /implement | 8/10 (80%) | 10/10 (100%) | +25% |
| **Average** | **7/10 (70%)** | **10/10 (100%)** | **+43%** |

**Downstream Reliability**:
- Before: 30% of workflows fail due to missing files from earlier phases
- After: 0% workflow failures due to missing files

**Application to /coordinate Fixes**:
- Pre-calculate all report paths in Phase 0
- Add MANDATORY VERIFICATION after research phase
- Verification checkpoints detect agent failures immediately
- No placeholder file creation (fail-fast compliant)
- Document verification checkpoint format (export prefix)

## 5. Error Handling Guidelines

### Fail-Fast Principles

**Location**: Multiple sources (command_architecture_standards.md, coordinate-state-management.md)

**Core Principle**: Expose errors immediately through clear diagnostics, don't hide them through silent fallbacks.

**Three Types of Fallbacks**:

1. **Bootstrap Fallbacks** (PROHIBITED):
   - Hide configuration errors through silent function definitions
   - Example: `command -v foo || foo() { echo "foo not found"; }`
   - Violates fail-fast by masking missing dependencies

2. **Verification Fallbacks** (REQUIRED):
   - Detect tool/agent failures immediately, terminate with diagnostics
   - Example: MANDATORY VERIFICATION checkpoints
   - Implements fail-fast by exposing errors

3. **Optimization Fallbacks** (ACCEPTABLE):
   - Performance caches only, graceful degradation for non-critical features
   - Example: State file missing → recalculate (graceful degradation)
   - Acceptable because no hidden errors

### Error Handling Patterns

**Pattern 1: Enhanced Diagnostics** (Standard 13):
```bash
if [ -f "$LIB_DIR/library-sourcing.sh" ]; then
  source "$LIB_DIR/library-sourcing.sh"
else
  echo "ERROR: Required library not found: library-sourcing.sh"
  echo ""
  echo "Expected location: $LIB_DIR/library-sourcing.sh"
  echo ""
  echo "Diagnostic information:"
  echo "  CLAUDE_PROJECT_DIR: ${CLAUDE_PROJECT_DIR}"
  echo "  LIB_DIR: ${LIB_DIR}"
  echo "  Current directory: $(pwd)"
  echo ""
  exit 1
fi
```

**Pattern 2: Immediate Validation**:
- Validate state transitions (state machine)
- Validate verification checkpoint results
- Fail immediately with clear error messages
- Provide troubleshooting guidance in error output

**Pattern 3: No Silent Degradation**:
- Don't continue execution after critical failures
- Don't create placeholder files when agents fail
- Don't hide missing dependencies with empty functions
- Exit codes must reflect actual failures

**Application to /coordinate Fixes**:
- Enhanced error messages for library sourcing failures
- Fail-fast when verification checkpoints fail
- No placeholder file creation
- Clear diagnostic output showing root cause
- Exit immediately on configuration errors

## 6. State-Based Orchestration Architecture

### Overview

**Location**: `.claude/docs/architecture/state-based-orchestration-overview.md`

**Purpose**: Comprehensive refactor introducing formal state machines, selective file-based state persistence, and hierarchical supervisor coordination.

**Key Achievements**:
- Code reduction: 48.9% (3,420 → 1,748 lines across 3 orchestrators)
- State operations: 67% faster (6ms → 2ms for CLAUDE_PROJECT_DIR detection)
- Context reduction: 95.6% via hierarchical supervisors
- File creation reliability: 100% maintained

### Core Components

**1. State Machine Library** (`workflow-state-machine.sh`):
- 8 explicit states (initialize, research, plan, implement, test, debug, document, complete)
- Transition table validation
- Atomic state transitions with checkpoint coordination
- 50 tests passing

**2. State Persistence Library** (`state-persistence.sh`):
- GitHub Actions-style workflow state files
- Selective file-based persistence (7 critical items)
- Graceful degradation to stateless recalculation
- 67% performance improvement

**3. Checkpoint Schema V2.0**:
- State machine as first-class citizen
- Supervisor coordination support
- Error state tracking with retry logic
- Backward compatible with V1.3

### Architecture Principles

**1. Explicit Over Implicit** (lines 89-108):
```bash
# Before (Phase-Based):
CURRENT_PHASE=1  # What does "1" mean?

# After (State-Based):
CURRENT_STATE="research"  # Explicit, self-documenting
sm_transition "plan"  # Validated against transition table
```

**2. Validated Transitions** (lines 110-128):
- State machine enforces valid state changes
- Invalid transitions rejected at runtime
- Documents allowed workflow paths

**3. Centralized State Lifecycle** (lines 130-145):
- Single state machine library owns all state lifecycle operations
- Atomic transitions with coordinated checkpoint saves
- Consistent error state tracking across all orchestrators

**4. Selective State Persistence** (lines 147-158):
- File-based when: Expensive (>30ms), non-deterministic, accumulates
- Stateless when: Fast (<10ms), deterministic, ephemeral

**5. Hierarchical Context Reduction** (lines 160-179):
- Pass metadata summaries, not full content
- 95.6% context reduction achieved
- Enables 4+ parallel workers without context overflow

### When to Use State-Based Orchestration

**Use state-based orchestration when**:
- Workflow has complex conditional transitions (test → debug vs test → document)
- Multiple orchestrators share similar phase structure
- Context reduction is critical (4+ parallel workers)
- Resumability from checkpoints is required

**Use simpler approaches when**:
- Workflow is linear with no conditional branches
- Single-purpose command with no state coordination
- Performance overhead of state management exceeds benefits

**Application to /coordinate Fixes**:
- /coordinate already uses state-based architecture
- Fixes must maintain state machine patterns
- Use sm_transition for state changes
- Atomic transitions with checkpoint coordination
- Follow selective state persistence decision matrix

## Recommendations for /coordinate Command Fixes

### 1. Command Architecture Compliance

**Standard 0 (Execution Enforcement)**:
- Use imperative language for all critical steps ("YOU MUST", "EXECUTE NOW", "MANDATORY")
- Add MANDATORY VERIFICATION checkpoints after all file creation operations
- Include verification fallbacks that DETECT errors (not mask them)
- Pre-calculate all artifact paths in Phase 0

**Standard 11 (Imperative Agent Invocation)**:
- All Task invocations use imperative pattern: `**EXECUTE NOW**: USE the Task tool...`
- No YAML code block wrappers around Task invocations
- Direct references to agent behavioral files
- Completion signals required for verification

**Standard 13 (Project Directory Detection)**:
- Include Standard 13 detection in every bash block
- Use `${CLAUDE_PROJECT_DIR}` for all library sourcing
- No reliance on `${BASH_SOURCE[0]}`

**Standard 14 (Executable/Documentation Separation)**:
- Keep /coordinate executable lean (<1,200 lines)
- Move architecture explanations to coordinate-command-guide.md
- Validate with `.claude/tests/validate_executable_doc_separation.sh`

### 2. Bash Block Execution Model Compliance

**Pattern 1: Fixed Semantic Filenames**:
- Use `coordinate_$(date +%s)` not `$$` for workflow IDs
- Store workflow ID in fixed location file

**Pattern 2: Library Re-sourcing**:
- Include `set +H` at start of every bash block
- Re-source all 6 critical libraries in every block:
  - workflow-state-machine.sh
  - state-persistence.sh
  - workflow-initialization.sh
  - error-handling.sh
  - unified-logger.sh
  - verification-helpers.sh

**Pattern 3: Cleanup Traps**:
- Only set cleanup traps in final completion function
- Not in early bash blocks (fire at block exit)

### 3. State Management Compliance

**Stateless Recalculation**:
- Use for WORKFLOW_SCOPE, PHASES_TO_EXECUTE (<1ms recalculation)
- Recalculate in every bash block that needs the variable

**File-Based State Persistence**:
- Use for CLAUDE_PROJECT_DIR (6ms → 2ms savings)
- Use for supervisor metadata (95% context reduction)
- Apply decision criteria systematically

**Verification Checkpoint Format**:
- All grep patterns must include `^export VAR_NAME=` prefix
- Add comments referencing state-persistence.sh format
- Test verification logic with actual state files

### 4. Verification and Fallback Compliance

**Path Pre-Calculation**:
- Calculate all report paths in Phase 0
- Use `get_or_create_topic_dir()`, `create_topic_artifact()`

**Verification Checkpoints**:
- Add MANDATORY VERIFICATION after research phase
- Use correct grep pattern with `export ` prefix
- Clear diagnostic output on verification failure

**Fallback Mechanism**:
- Verification fallbacks DETECT errors (fail-fast compliant)
- No placeholder file creation (would mask agent failures)
- Escalate to user with troubleshooting guidance

### 5. Error Handling Compliance

**Fail-Fast Principles**:
- Enhanced error messages for library sourcing failures
- Fail immediately when verification checkpoints fail
- No silent degradation or placeholder files
- Exit codes reflect actual failures

**Diagnostic Output**:
- Show CLAUDE_PROJECT_DIR, LIB_DIR, current directory
- Indicate expected file locations
- Provide troubleshooting steps

### 6. State-Based Architecture Compliance

**State Machine**:
- Use `sm_transition` for all state changes
- Atomic transitions with checkpoint coordination
- Follow transition table validation

**Selective Persistence**:
- Apply decision criteria (7 criteria) systematically
- Use file-based for expensive/non-deterministic state
- Use stateless for fast/deterministic calculations

## Summary

/coordinate command fixes must align with:

1. **Command Architecture Standards**: Standards 0, 11, 13, 14
2. **Bash Block Execution Model**: Subprocess isolation patterns, library re-sourcing
3. **State Management Patterns**: Selective persistence, stateless recalculation decision matrix
4. **Verification and Fallback Pattern**: MANDATORY VERIFICATION checkpoints with fail-fast compliance
5. **Error Handling Guidelines**: Fail-fast principles, enhanced diagnostics
6. **State-Based Orchestration Architecture**: Centralized state machine, atomic transitions

**Key Architectural Principles**:
- Explicit over implicit (named states, not phase numbers)
- Validated transitions (state machine enforcement)
- Centralized lifecycle (single state machine library)
- Selective persistence (file-based when justified, stateless otherwise)
- Hierarchical context reduction (metadata aggregation)
- Fail-fast error detection (verification fallbacks DETECT, not HIDE)

**Testing Requirements**:
- Test bash block sequences with actual subprocess execution
- Validate verification checkpoint format with real state files
- Ensure 100% file creation rate maintained
- Confirm >90% agent delegation rate
- Verify fail-fast behavior (no silent failures)

## References

### Primary Documentation

1. **Command Architecture Standards**
   - Path: `.claude/docs/reference/command_architecture_standards.md`
   - Standards: 0, 0.5, 11, 13, 14
   - Lines: 2,325 (comprehensive reference)

2. **Bash Block Execution Model**
   - Path: `.claude/docs/concepts/bash-block-execution-model.md`
   - Lines: 642 (complete subprocess isolation documentation)
   - Discovery: Specs 620, 630

3. **Coordinate State Management**
   - Path: `.claude/docs/architecture/coordinate-state-management.md`
   - Lines: 1,485 (complete decision matrix)
   - Discovery: Specs 582-600

4. **Verification and Fallback Pattern**
   - Path: `.claude/docs/concepts/patterns/verification-fallback.md`
   - Lines: 448 (100% file creation rate patterns)
   - Discovery: Plan 077

5. **State-Based Orchestration Overview**
   - Path: `.claude/docs/architecture/state-based-orchestration-overview.md`
   - Lines: 1,749 (complete architecture reference)
   - Implementation: Spec 602 (7 phases)

### Supporting Documentation

6. **Execution Enforcement Guide**
   - Path: `.claude/docs/guides/execution-enforcement-guide.md`
   - Consolidates imperative language rules
   - Cross-reference: Archived imperative-language-guide.md

7. **Fail-Fast Policy Analysis**
   - Path: `.claude/specs/634_001_coordinate_improvementsmd_implements/reports/001_fail_fast_policy_analysis.md`
   - Complete fallback taxonomy
   - Critical distinction: Detection vs. masking

### Historical Context

8. **Spec 620**: Bash history expansion fixes (subprocess isolation discovery)
9. **Spec 630**: State persistence architecture (report path loss fixes)
10. **Spec 644**: Coordinate verification checkpoint fix (export prefix)
11. **Spec 438**: /supervise agent delegation fix (Standard 11)
12. **Spec 495**: /coordinate and /research agent delegation fixes
13. **Spec 057**: /supervise robustness improvements (fail-fast policy)

### Testing and Validation

14. **Test Suite**: `.claude/tests/`
    - test_state_machine.sh (50 tests)
    - test_coordinate_verification.sh (3 tests)
    - test_orchestration_commands.sh (comprehensive)
    - validate_executable_doc_separation.sh (pattern compliance)

### Project Configuration

15. **CLAUDE.md**: `/home/benjamin/.config/CLAUDE.md`
    - Complete standards index
    - Section references for all patterns

## Metadata

- **Files Analyzed**: 5 primary, 10 supporting
- **Total Lines Reviewed**: 8,000+ lines
- **Standards Identified**: 5 major (0, 0.5, 11, 13, 14)
- **Patterns Documented**: 15 validated patterns
- **Test Coverage**: 127 state machine tests, 18 state persistence tests, 19 supervisor tests
- **Research Date**: 2025-11-10
- **Research Duration**: 2 hours
