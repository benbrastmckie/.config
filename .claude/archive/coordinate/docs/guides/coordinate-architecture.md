# /coordinate Command - Complete Guide

**Executable**: `.claude/commands/coordinate.md`

**Quick Start**: Run `/coordinate "<workflow-description>"` - the command is self-executing.

---

## Table of Contents

1. [Overview](#overview)
2. [Command Syntax](#command-syntax)
3. [Architecture](#architecture)
4. [Workflow Types](#workflow-types)
5. [Wave-Based Parallel Execution](#wave-based-parallel-execution)
6. [Performance and Optimization](#performance-and-optimization)
7. [Error Handling](#error-handling)
8. [Library Dependencies](#library-dependencies)
9. [Usage Examples](#usage-examples)
10. [Troubleshooting](#troubleshooting)

---

## Overview

### Purpose

The `/coordinate` command orchestrates multi-agent workflows for research, planning, implementation, testing, debugging, and documentation. It provides clean architectural patterns with wave-based parallel execution achieving 40-60% time savings compared to sequential implementation.

### When to Use

- **Research-only workflows**: Explore a topic without creating implementation artifacts
- **Research-and-plan workflows**: Research to inform implementation planning (MOST COMMON)
- **Full-implementation workflows**: Complete feature development from research through documentation
- **Debug-only workflows**: Bug fixing without new implementation

### When NOT to Use

- Single-agent tasks (use direct Task tool invocation)
- Simple file edits (use Edit/Write tools directly)
- Tasks already handled by simpler commands (/plan, /implement, /test)

### Key Features

✅ **Automatic workflow detection**: Determines scope from natural language description
✅ **Wave-based parallel execution**: 40-60% time savings through dependency analysis
✅ **Fail-fast error handling**: Clear diagnostics with debugging guidance
✅ **Context optimization**: <30% context usage through metadata extraction and pruning
✅ **Checkpoint recovery**: Automatic resume from last completed phase
✅ **Progress markers**: Silent tracking for external monitoring

---

## Command Syntax

```bash
/coordinate <workflow-description>
```

**Arguments**:
- `<workflow-description>`: Natural language description of the workflow to execute

**Examples**:
- `/coordinate "research API authentication patterns"` - Research-only workflow
- `/coordinate "research the authentication module to create a refactor plan"` - Research-and-plan workflow
- `/coordinate "implement OAuth2 authentication for the API"` - Full-implementation workflow
- `/coordinate "fix the token refresh bug in auth.js"` - Debug-only workflow

**Workflow Scope Detection**:
The command automatically detects the workflow type from your description and executes only the appropriate phases:
- **research-only**: Keywords like "research [topic]" without "plan" or "implement"
- **research-and-plan**: Keywords like "research...to create plan", "analyze...for planning"
- **full-implementation**: Keywords like "implement", "build", "add feature", or plan path pattern (specs/*/plans/*.md)
- **research-and-revise**: Keywords like "revise [plan]", "update plan", "modify plan" (takes priority over plan path)
- **debug-only**: Keywords like "fix [bug]", "debug [issue]", "troubleshoot [error]"

**Note**: Scope detection prioritizes patterns in this order: (1) revision patterns, (2) plan paths, (3) research-only, (4) explicit implementation keywords, (5) other patterns. See [workflow-scope-detection.sh](.claude/lib/workflow-scope-detection.sh:25-89) for complete algorithm.

---

## Transcript Files vs Command Implementation

### Important Distinction

**coordinage_*.md files** in `.claude/specs/` are **execution transcripts** (log files), NOT command implementations.

| Type | Location | Purpose | Status |
|------|----------|---------|--------|
| **Command Implementation** | `.claude/commands/coordinate.md` | Executable bash blocks that Claude runs | Authoritative source |
| **Execution Transcript** | `.claude/specs/coordinage_*.md` | Log of actual command execution | Historical record |

### Why This Matters

Transcripts may contain error conditions that were addressed during execution:

**Example**: A transcript showing "scope detected as research-and-plan" when user ran "implement <plan>" indicates a scope detection **bug that existed at execution time**, not the current correct behavior.

### Correct Pattern Reference

When understanding how `/coordinate` works:

✅ **DO**: Read `.claude/commands/coordinate.md` (the actual command)
✅ **DO**: Review behavioral agent files (`.claude/agents/*.md`)
✅ **DO**: Check library functions (`.claude/lib/workflow-*.sh`)

❌ **DON'T**: Use transcripts as examples of correct patterns
❌ **DON'T**: Copy error conditions from transcripts as if they were intended behavior
❌ **DON'T**: Assume transcript naming means the file contains executable code

### Standard 11 Compliance

The `/coordinate` command is **100% compliant with Standard 11** (Imperative Agent Invocation Pattern):

**Correct Implementation** (coordinate.md:1169-1200):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator:

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation with wave-based parallel execution"
  timeout: 600000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    **Workflow-Specific Context**:
    - Plan File: $PLAN_PATH (absolute path)
    - Topic Directory: $TOPIC_PATH
    ...
  "
}
```

**Incorrect Pattern** (SlashCommand anti-pattern):
```markdown
# ❌ NEVER DO THIS in orchestration commands
SlashCommand("/implement <plan-path>")
```

See [Standard 11 Documentation](.claude/docs/reference/command_architecture_standards.md#standard-11) for complete requirements.

---

## Architecture

### Role: Workflow Orchestrator

**YOU ARE THE ORCHESTRATOR** for this multi-agent workflow.

**YOUR RESPONSIBILITIES**:
1. Pre-calculate ALL artifact paths before any agent invocations
2. Determine workflow scope (research-only, research-and-plan, full-implementation, debug-only)
3. Invoke specialized agents via Task tool with complete context injection
4. Verify agent outputs at mandatory checkpoints
5. Extract and aggregate metadata from agent results (forward message pattern)
6. Report final workflow status and artifact locations

**YOU MUST NEVER**:
1. Execute tasks yourself using Read/Grep/Write/Edit tools
2. Invoke other commands via SlashCommand tool (/plan, /implement, /debug, /document)
3. Modify or create files directly (except in Phase 0 setup)
4. Skip mandatory verification checkpoints
5. Continue workflow after verification failure

### Architectural Pattern

```
Phase 0: Pre-calculate paths → Create topic directory structure
  ↓
Phase 1-N: Invoke agents with pre-calculated paths → Verify → Extract metadata
  ↓
Completion: Report success + artifact locations
```

### Tools

**ALLOWED**:
- Task: ONLY tool for agent invocations
- TodoWrite: Track phase progress
- Bash: Verification checkpoints (ls, grep, wc)
- Read: Parse agent output files for metadata extraction (not for task execution)

**PROHIBITED**:
- SlashCommand: NEVER invoke /plan, /implement, /debug, or any command
- Write/Edit: NEVER create artifact files (agents do this)
- Grep/Glob: NEVER search codebase directly (agents do this)

### Why No Command Chaining

**CRITICAL PROHIBITION**: This command MUST NEVER invoke other commands via the SlashCommand tool.

**Wrong Pattern - Command Chaining** (causes context bloat and broken behavioral injection):

❌ INCORRECT - Do NOT do this:
```
SlashCommand with command: "/plan create auth feature"
```

**Problems with command chaining**:
1. **Context Bloat**: Entire /plan command prompt injected into your context (~2000 lines)
2. **Broken Behavioral Injection**: /plan's behavior not customizable via prompt
3. **Lost Control**: Cannot inject specific instructions or constraints
4. **No Metadata**: Get full output, not structured data for aggregation

**Correct Pattern - Direct Agent Invocation** (lean context, behavioral control):

✅ CORRECT - Do this instead:
```
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Plan Path: ${PLAN_PATH} (absolute path, pre-calculated)
    - Research Reports: [list of paths]
    - Project Standards: [path to CLAUDE.md]

    Execute planning following all guidelines in behavioral file.
    Return: PLAN_CREATED: ${PLAN_PATH}
  "
}
```

**Benefits of direct agent invocation**:
1. **Lean Context**: Only agent behavioral guidelines loaded (~200 lines)
2. **Behavioral Control**: Can inject custom instructions, constraints, templates
3. **Structured Output**: Agent returns metadata (path, status) not full summaries
4. **Verification Points**: Can verify file creation before continuing

### Side-by-Side Comparison

| Aspect | Command Chaining (❌) | Direct Agent Invocation (✅) |
|--------|---------------------|------------------------------|
| Context Usage | ~2000 lines (full command) | ~200 lines (agent guidelines) |
| Behavioral Control | Fixed (command prompt) | Flexible (custom instructions) |
| Output Format | Full text summaries | Structured metadata |
| Verification | None (black box) | Explicit checkpoints |
| Path Control | Agent calculates | Orchestrator pre-calculates |
| Role Separation | Blurred (orchestrator executes) | Clear (orchestrator delegates) |

### Enforcement

If you find yourself wanting to invoke /plan, /implement, /debug, or /document:

1. **STOP** - You are about to violate the architectural pattern
2. **IDENTIFY** - What task does that command perform?
3. **DELEGATE** - Invoke the appropriate agent directly via Task tool
4. **INJECT** - Provide the agent with behavioral guidelines and context
5. **VERIFY** - Check that the agent created the expected artifacts

**REMEMBER**: You are the **ORCHESTRATOR**, not the **EXECUTOR**. Delegate work to agents.

### Architectural Note: Planning Phase Design

The planning phase uses behavioral injection to invoke the plan-architect agent rather than the /plan slash command. This design choice:

1. **Maintains orchestrator-executor separation** (Standard 0 Phase 0)
   - Orchestrator pre-calculates PLAN_PATH
   - Agent receives path as injected context
   - No self-determination of artifact locations

2. **Enables path pre-calculation for artifact control**
   - PLAN_PATH calculated in Phase 0 initialization
   - Agent saves to exact path provided by orchestrator
   - Ensures predictable artifact location for verification

3. **Follows Standard 11** (Imperative Agent Invocation Pattern)
   - Imperative instruction: "**EXECUTE NOW**: USE the Task tool..."
   - Direct reference to agent behavioral file (.claude/agents/plan-architect.md)
   - No code block wrappers around Task invocation
   - Explicit completion signal: "Return: PLAN_CREATED: $PLAN_PATH"

4. **Prevents context bloat from nested command prompts**
   - Direct agent invocation: ~200 lines context
   - Command chaining: ~2000 lines context (10x overhead)
   - Enables <30% context usage target

5. **Enables metadata extraction for 95% context reduction**
   - Agent returns structured data (path + status)
   - Orchestrator extracts title + 50-word summary
   - No full plan content in orchestrator context

**The plan-architect agent receives**:
- Pre-calculated PLAN_PATH from orchestrator
- Research report paths as context
- Complete behavioral guidelines from .claude/agents/plan-architect.md
- Workflow-specific requirements injection (feature description, standards path, topic directory)

**Comparison with anti-pattern (command-to-command invocation)**:
- ❌ Wrong: `SlashCommand with command: "/plan create feature"`
- ✅ Correct: `Task { prompt: "Read and follow: .claude/agents/plan-architect.md" }`

See [Standard 11](./../reference/command_architecture_standards.md#standard-11) and [Behavioral Injection Pattern](./../concepts/patterns/behavioral-injection.md) for complete documentation.

### Architectural Note: Implementation Phase Design

The implementation phase uses behavioral injection to invoke the implementer-coordinator agent rather than the /implement slash command. This design choice:

1. **Enables wave-based parallel execution** (40-60% time savings)
   - implementer-coordinator uses dependency-analyzer.sh to build execution waves
   - Independent phases execute in parallel via implementation-executor subagents
   - Sequential phases execute in order as dependencies complete
   - Achieves significantly better performance than sequential /implement command

2. **Maintains orchestrator-executor separation** (Standard 0 Phase 0)
   - Orchestrator pre-calculates all artifact paths (REPORTS_DIR, PLANS_DIR, SUMMARIES_DIR, etc.)
   - Agent receives paths as injected context in Phase 0
   - No self-determination of artifact locations by agent
   - Ensures predictable artifact organization for verification

3. **Follows Standard 11** (Imperative Agent Invocation Pattern)
   - Imperative instruction: "**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator"
   - Direct reference to agent behavioral file (.claude/agents/implementer-coordinator.md)
   - No code block wrappers around Task invocation
   - Explicit completion signal: "Return: IMPLEMENTATION_COMPLETE: [summary]"
   - Complete context injection (plan path, artifact directories, execution requirements)

4. **Prevents context bloat from nested command prompts**
   - Direct agent invocation: ~400 lines context (agent behavioral file)
   - Command chaining: ~5000+ lines context (full /implement command prompt - 12.5x overhead!)
   - Critical for maintaining <30% context usage target throughout workflow

5. **Enables metadata extraction for 95% context reduction**
   - Agent returns structured completion signal with summary
   - Orchestrator verifies artifacts via file system checks
   - No full implementation details in orchestrator context
   - Verification checkpoint ensures 100% file creation reliability

**The implementer-coordinator agent receives**:
- Pre-calculated PLAN_PATH from orchestrator
- Pre-calculated artifact directories (REPORTS_DIR, PLANS_DIR, SUMMARIES_DIR, DEBUG_DIR, OUTPUTS_DIR, CHECKPOINT_DIR)
- Topic directory path for artifact organization
- Complete behavioral guidelines from .claude/agents/implementer-coordinator.md
- Execution requirements (wave-based parallel execution, automated testing, git commits, checkpoint state management)

**Wave-Based Execution Flow**:
1. implementer-coordinator reads plan and invokes dependency-analyzer
2. dependency-analyzer parses phase dependencies and calculates waves
3. Each wave executes in parallel via implementation-executor subagents
4. Coordinator collects metrics and aggregates results
5. Checkpoint state enables resume on failure

**Comparison with anti-pattern (command-to-command invocation)**:
- ❌ Wrong: `SlashCommand with command: "/implement $PLAN_PATH"` (5000+ lines context, sequential execution)
- ✅ Correct: `Task { prompt: "Read and follow: .claude/agents/implementer-coordinator.md" }` (400 lines context, wave-based parallel execution)

**Performance Benefits**:
- **Context Reduction**: 95% (5000+ tokens → ~400 tokens)
- **Time Savings**: 40-60% via parallel execution for plans with independent phases
- **Reliability**: 100% file creation via mandatory verification checkpoint
- **Agent Delegation**: 100% compliance with Standard 11

See [Standard 11](./../reference/command_architecture_standards.md#standard-11), [Behavioral Injection Pattern](./../concepts/patterns/behavioral-injection.md), and [implementer-coordinator agent](./../agents/implementer-coordinator.md) for complete documentation.

### Agent Invocation Architecture: Research Phase

The research phase uses **explicit conditional enumeration** to control agent invocations based on state-persisted complexity from sm_init(). This architectural pattern ensures the number of agents invoked matches the RESEARCH_COMPLEXITY value (1-4) calculated by comprehensive workflow classification, rather than defaulting to a fixed count or using hardcoded pattern matching.

#### Explicit Loop Requirement

**Critical Constraint**: Natural language instructions like "for EACH research topic (1 to $RESEARCH_COMPLEXITY)" are documentation templates, not executable iteration constraints. Claude interprets these as suggestions and examines available context (e.g., REPORT_PATH variables) to determine invocation count, which can lead to mismatches.

**Solution**: Two-part implementation pattern:

**Part 1: Bash Block** (Variable Preparation):
```bash
# Prepare variables for conditional agent invocations (1-4)
for i in $(seq 1 4); do
  REPORT_PATH_VAR="REPORT_PATH_$((i-1))"
  export "RESEARCH_TOPIC_${i}=Topic ${i}"
  export "AGENT_REPORT_PATH_${i}=${!REPORT_PATH_VAR}"
done
```

**Part 2: Markdown Section** (Conditional Task Invocations):
```markdown
**IF RESEARCH_COMPLEXITY >= 1** (always true):
Task { ... agent 1 invocation ... }

**IF RESEARCH_COMPLEXITY >= 2** (true for complexity 2-4):
Task { ... agent 2 invocation ... }

**IF RESEARCH_COMPLEXITY >= 3** (true for complexity 3-4):
Task { ... agent 3 invocation ... }

**IF RESEARCH_COMPLEXITY >= 4** (hierarchical research triggers, not this code path):
Task { ... agent 4 invocation ... }
```

**Why This Pattern Works**:

1. **Architectural Compliance**: Task tool invocations CANNOT be placed inside bash loops (behavioral injection constraint). Task invocations must occur in markdown sections between bash blocks.

2. **Explicit Control**: Conditional guards (`IF RESEARCH_COMPLEXITY >= N`) provide iteration control while respecting the markdown invocation requirement.

3. **Pattern Alignment**: Follows Standard 11 (Imperative Agent Invocation Pattern) with imperative instructions, behavioral file references, and explicit completion signals.

4. **Correctness**: Ensures agent count matches calculated complexity rather than examining pre-allocated array size.

#### Historical Context

**Problem** (Prior to Spec 676):
- Research phase used natural language template: "invoke agent for EACH research topic (1 to $RESEARCH_COMPLEXITY)"
- Claude examined context and found 4 pre-allocated REPORT_PATH variables (Phase 0 optimization)
- Result: Invoked 4 agents regardless of RESEARCH_COMPLEXITY value (often 2 for typical workflows)
- Impact: 100% time/token overhead (20-40 min → 10-20 min), ~25,000 tokens wasted per workflow

**Solution** (Spec 676):
- Replaced natural language template with explicit conditional enumeration
- Bash block prepares variables, markdown section controls invocation via conditional guards
- Result: Agent count now matches RESEARCH_COMPLEXITY (2 agents for typical workflows)
- Impact: 50% time/token savings for research phase

#### Pre-Calculated Array Size vs. Actual Usage

**Design Trade-off**:
- **REPORT_PATHS_COUNT**: Actual number of paths allocated (matches RESEARCH_COMPLEXITY from sm_init comprehensive classification)
- **RESEARCH_COMPLEXITY=1-4**: Complexity score from sm_init() comprehensive workflow classification (workflow-state-machine.sh)
- **Intent**: Allocate exactly N paths based on complexity, use all allocated paths during research phase

**Rationale**: After bug fix (Spec 687), REPORT_PATHS_COUNT always equals RESEARCH_COMPLEXITY. Both values come from sm_init() and are persisted to state. No recalculation occurs in research phase, ensuring consistency throughout workflow.

**Verification Pattern** (Updated 2025-11-12): Verification and discovery loops use REPORT_PATHS_COUNT to determine iteration bounds. This ensures verification checks exactly as many files as were allocated, even if RESEARCH_COMPLEXITY were to be accidentally recalculated (defense-in-depth pattern).

#### Performance Impact

**Phase 0 Pre-Allocation Benefits**:
- 85% token reduction vs. agent-based path detection
- 25x speedup (agent invocation overhead eliminated)
- Predictable artifact locations for verification

**Explicit Loop Control Benefits** (Spec 676):
- Eliminates unnecessary agent invocations (4 → 2 for typical workflows)
- 50% time savings for research phase (20-40 min → 10-20 min)
- 50% token savings for research phase (~25,000 tokens)
- Agent count matches user expectations based on workflow complexity

**Combined**: Phase 0 optimization + explicit loop control achieves both fast initialization AND correct agent invocation count.

#### References

- **Spec 676**: Root cause analysis and agent invocation loop fix
- **Phase 0 Optimization Guide**: `.claude/docs/guides/phase-0-optimization.md` - Pre-calculation strategy
- **Bash Block Execution Model**: `.claude/docs/concepts/bash-block-execution-model.md` - Subprocess isolation patterns
- **Standard 11**: Imperative Agent Invocation Pattern requirement

### Bash Block Execution Patterns

The `/coordinate` command uses multiple bash code blocks to orchestrate workflows. Each bash block executes in a separate subprocess, requiring careful state management and library sourcing.

#### Pattern 1: Fixed Semantic Filename (State ID File)

**Purpose**: Enable reliable state discovery across bash block boundaries

**Implementation**:
```bash
# Block 1: Create state ID file with fixed semantic filename
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"
```

**Why Fixed Semantic Filename**:
- **Predictable Location**: Subsequent blocks know exactly where to find state ID
- **No Discovery Required**: Avoid timestamp-based filenames that require glob/find
- **Subprocess Persistence**: File persists after first bash block exits

**Reference**: [bash-block-execution-model.md:163-191](./../concepts/bash-block-execution-model.md)

#### Pattern 6: Cleanup on Completion Only

**Purpose**: Prevent premature cleanup of state files

**Implementation**:
```bash
# Block 1: NO EXIT trap here
# State ID file should persist after this block exits

# ... intermediate blocks: NO EXIT traps ...

# Final completion block: Cleanup trap ONLY here
display_brief_summary() {
  # Manual cleanup (preferred over EXIT trap for coordinate)
  rm -f "${HOME}/.claude/tmp/coordinate_state_id.txt"
  rm -f "${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
}
```

**Why No Premature EXIT Traps**:
- **Subprocess Isolation**: EXIT traps fire when bash block exits (subprocess terminates)
- **Premature Cleanup**: Trap in Block 1 would delete state files before Block 2 runs
- **Fail-Fast**: Missing state files in subsequent blocks fail immediately with clear errors

**Reference**: [bash-block-execution-model.md:382-399](./../concepts/bash-block-execution-model.md)

#### Standard 15: Library Sourcing Order

**Purpose**: Ensure all library dependencies available before use

**Implementation** (ALL bash blocks follow this order):
```bash
# Step 1: Read state ID file (blocks 2+)
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")

# Step 2: Load workflow state BEFORE sourcing libraries
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
fi

# Step 3: Re-source libraries in dependency order
source "${LIB_DIR}/workflow-state-machine.sh"   # 1. State machine (no deps)
source "${LIB_DIR}/state-persistence.sh"        # 2. State persistence
source "${LIB_DIR}/error-handling.sh"           # 3. Error handling (needs state persistence)
source "${LIB_DIR}/verification-helpers.sh"     # 4. Verification (needs error handling)

# Step 4: Verification checkpoint
if ! command -v verify_file_created &>/dev/null; then
  echo "ERROR: Required functions not available after library sourcing" >&2
  exit 1
fi
```

**Why This Order**:
- **Load State First**: Prevents WORKFLOW_SCOPE reset by library re-initialization
- **Dependency Order**: Later libraries depend on earlier ones
- **Verification Checkpoint**: Fail-fast if libraries not loaded correctly

**Reference**: [Standard 15 (command_architecture_standards.md:2277-2413)](./../reference/command_architecture_standards.md#standard-15)

#### Standard 0: Execution Enforcement (Verification Checkpoints)

**Purpose**: Fail-fast when state files missing or functions unavailable

**Implementation**:
```bash
# After state ID file creation
verify_file_created "$COORDINATE_STATE_ID_FILE" "State ID file" "Initialization" || {
  handle_state_error "CRITICAL: State ID file not created" 1
}

# After library sourcing
verify_state_variable "WORKFLOW_SCOPE" || {
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not loaded" 1
}
```

**Why Verification Checkpoints**:
- **Fail-Fast**: Detect errors immediately, not in subsequent phases
- **Clear Diagnostics**: Error messages include context (what failed, where, why)
- **100% Reliability**: Prevents silent failures and undefined behavior

**Reference**: [Standard 0 (command_architecture_standards.md)](./../reference/command_architecture_standards.md#standard-0)

#### Complete Multi-Block Pattern

**3-Block Workflow Example**:
```bash
# ===== Block 1: Initialize =====
WORKFLOW_ID="coordinate_$(date +%s)"
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"

verify_file_created "$COORDINATE_STATE_ID_FILE" "State ID file" "Block 1"

# NO EXIT trap here (Pattern 6)

# ===== Block 2: Process =====
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
source "$STATE_FILE"  # Load BEFORE sourcing libraries

# Re-source libraries (Standard 15 order)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/error-handling.sh"

# Verify functions available
command -v handle_state_error &>/dev/null || exit 1

# NO EXIT trap here (Pattern 6)

# ===== Block 3: Complete =====
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
source "$STATE_FILE"

# Re-source libraries
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Cleanup ONLY in final block (Pattern 6)
rm -f "$COORDINATE_STATE_ID_FILE" "$STATE_FILE"
```

**Key Principles**:
1. **Pattern 1**: Fixed semantic filename for state ID file
2. **Pattern 6**: Cleanup only in final block
3. **Standard 15**: Load state before sourcing, maintain dependency order
4. **Standard 0**: Verification checkpoints at critical points

---

## Workflow Types

### Workflow Overview

This command coordinates multi-agent workflows through 7 phases:

```
Phase 0: Location and Path Pre-Calculation
  ↓
Phase 1: Research (2-4 parallel agents)
  ↓
Phase 2: Planning (conditional)
  ↓
Phase 3: Wave-Based Implementation (conditional, 40-60% time savings)
  │       Dependency Analysis → Wave Calculation → Parallel Execution
  │       Wave 1 [P1, P2, P3] ║ Phases in parallel within wave
  │       Wave 2 [P4, P5]     ║ Each wave waits for previous wave completion
  │       Wave 3 [P6]         ║ Dependencies determine wave boundaries
  ↓
Phase 4: Testing (conditional)
  ↓
Phase 5: Debug (conditional - only if tests fail)
  ↓
Phase 6: Documentation (conditional - only if implementation occurred)
```

### 1. Research-Only Workflow

**Phases**: 0-1 only

**Keywords**: "research [topic]" without "plan" or "implement"

**Use Case**: Pure exploratory research

**Artifacts**:
- Research reports in `specs/{NNN_topic}/reports/`
- No plan created
- No summary created

**Example**:
```bash
/coordinate "research API authentication patterns"
```

**Output**:
- 2-4 research reports (depending on topic complexity)
- Topic directory structure
- No implementation artifacts

### 2. Research-and-Plan Workflow (MOST COMMON)

**Phases**: 0-2 only

**Keywords**: "research...to create plan", "analyze...for planning"

**Use Case**: Research to inform planning

**Artifacts**:
- Research reports in `specs/{NNN_topic}/reports/`
- Implementation plan in `specs/{NNN_topic}/plans/`
- No summary (no implementation occurred)

**Example**:
```bash
/coordinate "research the authentication module to create a refactor plan"
```

**Output**:
- 2-4 research reports
- 1 implementation plan (Level 0)
- Topic directory structure

### 2a. Research-and-Revise Workflow

**Phases**: 0-2 only

**Keywords**: "revise the plan [path]", "update plan [path] to accommodate"

**Use Case**: Revision of existing plans based on new research findings

**Path Handling**: Unlike creation workflows (which generate NEW topic directories), revision workflows use EXISTING topic directories extracted from the provided plan path.

**Artifacts**:
- Research reports in existing `specs/{NNN_topic}/reports/`
- Updated plan in existing `specs/{NNN_topic}/plans/` (backup created before modification)
- No summary (no implementation occurred)

**Examples**:
```bash
# Simple syntax
/coordinate "Revise /home/user/.claude/specs/657_topic/plans/001_plan.md to accommodate new API"

# Complex syntax with "the plan"
/coordinate "Revise the plan /home/user/.claude/specs/657_topic/plans/001_plan.md to include caching"
```

**Path Extraction**:
The workflow initialization extracts the topic directory from the plan path:
- Given: `/home/user/.claude/specs/657_topic/plans/001_plan.md`
- Extracted topic: `657_topic`
- Reused directory: `/home/user/.claude/specs/657_topic/`

**Validation Requirements**:
1. Plan path must be provided in workflow description
2. Plan file must exist at specified path
3. Topic directory must exist (format: `specs/NNN_topic/`)
4. Topic must have `plans/` subdirectory

**Error Handling**:
If validation fails, the workflow fails fast with diagnostic information:
```
ERROR: research-and-revise workflow requires existing plan path
  Workflow description: Revise some plan
  Expected: Path format like 'Revise the plan /path/to/specs/NNN_topic/plans/NNN_plan.md...'

  Diagnostic:
    - Check workflow description contains full plan path
    - Verify scope detection exported EXISTING_PLAN_PATH
```

**Output**:
- 2-4 research reports (in existing topic directory)
- 1 updated plan (original backed up with timestamp)
- Existing topic directory reused (NOT created new)

**Difference from Creation Workflows**:
| Aspect | Creation Workflows | Revision Workflows |
|--------|-------------------|-------------------|
| Topic Directory | Generate NEW (e.g., `662_new_topic/`) | Use EXISTING (extracted from path) |
| Plan Discovery | N/A (creating new plan) | Extract from workflow description |
| Directory Structure | Create all subdirectories | Must already exist |
| Validation | None (new topic) | Plan exists, directory exists, structure valid |
| Path Format | Generated from description | Must match `/specs/NNN_topic/plans/NNN_plan.md` |

**Implementation Details**:
- Extraction function: `extract_topic_from_plan_path()` in `workflow-initialization.sh`
- Scope detection: `detect_workflow_scope()` exports `EXISTING_PLAN_PATH`
- Agent invocation: revision-specialist via Task tool (Standard 11 compliance)

See [Issue #661](../../../specs/661_and_the_standards_in_claude_docs_to_avoid/) for complete implementation details and test cases.

### 3. Full-Implementation Workflow

**Phases**: 0-4, 6 (Phase 5 conditional on test failures)

**Keywords**: "implement", "build", "add feature"

**Use Case**: Complete feature development

**Artifacts**:
- Research reports
- Implementation plan
- Code changes (multiple files)
- Test results
- Implementation summary
- Documentation updates (conditional)

**Example**:
```bash
/coordinate "implement OAuth2 authentication for the API"
```

**Output**:
- All research artifacts
- Implementation plan
- Modified/created code files
- Test execution results
- Implementation summary with cross-references
- Updated documentation

### 4. Debug-Only Workflow

**Phases**: 0, 1, 5 only

**Keywords**: "fix [bug]", "debug [issue]", "troubleshoot [error]"

**Use Case**: Bug fixing without new implementation

**Artifacts**:
- Debug analysis report
- Root cause analysis
- Proposed fix
- No new plan or summary

**Example**:
```bash
/coordinate "fix the token refresh bug in auth.js"
```

**Output**:
- Debug analysis report
- Root cause identification
- Fix implementation
- Verification test results

---
