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

## Wave-Based Parallel Execution

### Overview

Wave-based execution enables parallel implementation of independent phases, achieving 40-60% time savings compared to sequential execution.

### How It Works

**1. Dependency Analysis**: Parse implementation plan to identify phase dependencies
- Uses `dependency-analyzer.sh` library
- Extracts `dependencies: [N, M]` from each phase
- Builds directed acyclic graph (DAG) of phase relationships

**2. Wave Calculation**: Group phases into waves using Kahn's algorithm
- Wave 1: All phases with no dependencies
- Wave 2: Phases depending only on Wave 1 phases
- Wave N: Phases depending only on previous waves

**3. Parallel Execution**: Execute all phases within a wave simultaneously
- Invoke implementer-coordinator agent for wave orchestration
- Agent spawns implementation-executor agents in parallel (one per phase)
- Wait for all phases in wave to complete before next wave

**4. Wave Checkpointing**: Save state after each wave completes
- Enables resume from wave boundary on interruption
- Tracks wave number, completed phases, pending phases

### Example Wave Execution

```
Plan with 8 phases:
  Phase 1: dependencies: []
  Phase 2: dependencies: []
  Phase 3: dependencies: [1]
  Phase 4: dependencies: [1]
  Phase 5: dependencies: [2]
  Phase 6: dependencies: [3, 4]
  Phase 7: dependencies: [5]
  Phase 8: dependencies: [6, 7]

Wave Calculation Result:
  Wave 1: [Phase 1, Phase 2]          ← 2 phases in parallel (0 dependencies)
  Wave 2: [Phase 3, Phase 4, Phase 5] ← 3 phases in parallel (only depend on Wave 1)
  Wave 3: [Phase 6, Phase 7]          ← 2 phases in parallel (only depend on Waves 1-2)
  Wave 4: [Phase 8]                   ← 1 phase (depends on Wave 3)

Time Savings:
  Sequential: 8 phases × avg_time = 8T
  Wave-based: 4 waves × avg_time = 4T
  Savings: 50% (actual savings depend on phase distribution)
```

### Performance Impact

- **Best case**: 60% time savings (many independent phases)
- **Typical case**: 40-50% time savings (moderate dependencies)
- **Worst case**: 0% savings (fully sequential dependencies)
- **No overhead** for plans with <3 phases (single wave)

### Library Integration

See `.claude/lib/dependency-analyzer.sh` for complete wave calculation implementation.

---

## Plan Naming Convention

Plans created by `/coordinate` follow a descriptive naming pattern to improve repository navigation and discoverability.

### Format

**Pattern**: `{NNN}_{topic_name}_plan.md`

Where:
- **NNN**: Three-digit sequential number (001, 002, 003...)
- **topic_name**: Sanitized workflow description (via `sanitize_topic_name()`)

### Sanitization Algorithm

The topic name is generated by `workflow-initialization.sh` using the `sanitize_topic_name()` function from `topic-utils.sh`:

1. Extract meaningful path components (last 2-3 segments if path provided)
2. Remove filler words ("research", "analyze", "the", "to", "for")
3. Filter stopwords (40+ common English words like "and", "or", "with")
4. Convert to lowercase snake_case
5. Truncate to 50 characters preserving whole words

### Examples

| Workflow Description | Generated Plan Name |
|---------------------|-------------------|
| `fix authentication bug` | `001_fix_authentication_bug_plan.md` |
| `implement user dashboard` | `002_implement_user_dashboard_plan.md` |
| `research /nvim/docs directory` | `003_nvim_docs_directory_plan.md` |
| `refactor state machine for coordinate` | `004_refactor_state_machine_coordinate_plan.md` |

### Why Descriptive Names

- **Context at a glance**: See what the plan is about without opening the file
- **Grep/find friendly**: Search by feature keywords (`find . -name "*auth*_plan.md"`)
- **Consistency**: Matches topic directory naming pattern
- **Navigation**: Improves repository discovery and organization

### Implementation Notes

**NEVER** use generic names like `001_implementation.md` - these provide no context and defeat the purpose of topic-based organization.

The plan path is:
1. Calculated by `workflow-initialization.sh` using `sanitize_topic_name()`
2. Exported as `PLAN_PATH` variable
3. Persisted to workflow state via `state-persistence.sh`
4. Loaded in subsequent bash blocks for verification

The `/coordinate` command trusts this calculated value rather than recalculating or hardcoding paths, following the "single source of truth" principle.

### Related Files

- **Topic naming algorithm**: `.claude/lib/topic-utils.sh` (`sanitize_topic_name()`)
- **Path initialization**: `.claude/lib/workflow-initialization.sh` (`initialize_workflow_paths()`)
- **State persistence**: `.claude/lib/state-persistence.sh` (`append_workflow_state()`, `load_workflow_state()`)
- **Directory protocols**: `.claude/docs/concepts/directory-protocols.md` (topic structure documentation)

### Regression Prevention

A regression test in `.claude/tests/test_orchestration_commands.sh` (Test Suite 5) validates:
- `sanitize_topic_name()` produces expected output
- No hardcoded generic plan paths in `coordinate.md`
- `PLAN_PATH` is properly saved to and loaded from workflow state

Run `./test_orchestration_commands.sh` to verify plan naming implementation.

---

## Performance and Optimization

### Context Usage Targets

**Target**: <30% context usage throughout workflow

**Phase-by-Phase Optimization**:

- **Phase 1 (Research)**: 80-90% reduction via metadata extraction
  - Extract title, summary, key findings only
  - Prune full report content after extraction

- **Phase 2 (Planning)**: 80-90% reduction + pruning research if plan-only workflow
  - Extract plan metadata (phases, complexity, dependencies)
  - Prune research reports after plan creation (if plan-only)

- **Phase 3 (Implementation)**: Aggressive pruning of wave metadata
  - Prune research/planning artifacts after wave calculation
  - Retain only current wave context

- **Phase 4 (Testing)**: Metadata only
  - Pass/fail status retained for potential debugging
  - Prune full test output after summary extraction

- **Phase 5 (Debug)**: Conditional execution
  - Only runs if tests fail
  - Prune test output after debug completion

- **Phase 6 (Documentation)**: Final pruning
  - <30% context usage overall achieved

### File Creation Rate

**Target**: 100% file creation reliability

**Implementation**: Fail-fast verification checkpoints

**Pattern**:
```bash
# Agent invocation
Task { ... }

# MANDATORY VERIFICATION
if [ ! -f "$EXPECTED_PATH" ]; then
  echo "❌ ERROR: Agent failed to create expected file"
  echo "   Expected: $EXPECTED_PATH"
  echo "   Found: File does not exist"
  # ... diagnostic information ...
  exit 1
fi
```

### Progress Streaming

**Format**: Silent PROGRESS: markers at each phase boundary

**Example**:
```
PROGRESS: [Phase 0] - Initialization complete
PROGRESS: [Phase 1] - Invoking 4 research agents in parallel
PROGRESS: [Phase 1] - All research agents completed
PROGRESS: [Phase 2] - Planning phase started
```

**Use Case**: Enables external monitoring without verbose output

---

## Error Handling

### Fail-Fast Philosophy

**Principle**: "One clear execution path, fail fast with full context"

**Key Behaviors**:
- **NO retries**: Single execution attempt per operation
- **NO fallbacks**: If operation fails, report why and exit
- **Clear diagnostics**: Every error shows exactly what failed and why
- **Debugging guidance**: Every error includes steps to diagnose the issue
- **Partial research success**: Continue if ≥50% of parallel agents succeed (Phase 1 only)

**Why Fail-Fast?**
- More predictable behavior (no hidden retry loops)
- Easier to debug (clear failure point, no retry state)
- Easier to improve (fix root cause, not mask with retries)
- Faster feedback (immediate failure notification)

### Error Message Structure

Every error message follows this structure:

```
❌ ERROR: [What failed]
   Expected: [What was supposed to happen]
   Found: [What actually happened]

DIAGNOSTIC INFORMATION:
  - [Specific check that failed]
  - [File system state or error details]
  - [Why this might have happened]

What to check next:
  1. [First debugging step]
  2. [Second debugging step]
  3. [Third debugging step]

Example commands to debug:
  ls -la [path]
  cat [file]
  grep [pattern] [file]
```

### Partial Failure Handling

**Phase 1 (Research)**: Continues if ≥50% of parallel agents succeed

**All Other Phases**: Fail immediately on any agent failure

**Rationale**: Research phase uses multiple parallel agents for redundancy. Other phases have single-agent execution where failure indicates fundamental issues.

---

## Library Dependencies

### Required Libraries

All libraries are required for proper operation. If any library is missing, the command will fail immediately with clear diagnostic information.

**Why All Required?**: Fail-fast philosophy requires all dependencies to be present. Missing libraries indicate configuration issues that should be fixed, not worked around.

### Library List

1. **workflow-detection.sh** - Workflow scope detection and phase execution control
   - `detect_workflow_scope()` - Determine workflow type from description
   - `should_run_phase()` - Check if phase executes for current scope

2. **error-handling.sh** - Error classification and diagnostic message generation
   - `classify_error()` - Classify error type (transient/permanent/fatal)
   - `suggest_recovery()` - Suggest recovery action based on error type
   - `detect_error_type()` - Detect specific error category
   - `extract_location()` - Extract file:line from error message
   - `generate_suggestions()` - Generate error-specific suggestions

3. **checkpoint-utils.sh** - Workflow resume capability and state management
   - `save_checkpoint()` - Save workflow checkpoint for resume
   - `restore_checkpoint()` - Load most recent checkpoint
   - `checkpoint_get_field()` - Extract field from checkpoint
   - `checkpoint_set_field()` - Update field in checkpoint

4. **unified-logger.sh** - Progress tracking and event logging
   - `emit_progress()` - Emit silent progress marker

5. **unified-location-detection.sh** - Topic directory structure creation
   - Topic number allocation
   - Directory structure creation
   - Path calculation

6. **metadata-extraction.sh** - Context reduction via metadata-only passing
   - Report metadata extraction
   - Plan metadata extraction
   - Summary generation

7. **context-pruning.sh** - Context optimization between phases
   - Phase data cleanup
   - Subagent output pruning
   - Context budget management

8. **dependency-analyzer.sh** - Wave-based execution and dependency graph analysis
   - Dependency graph construction
   - Wave calculation (Kahn's algorithm)
   - Topological sorting

### Checkpoint Resume

**Behavior**: Checkpoints saved after Phases 1-4. Auto-resumes from last completed phase on startup.

**Process**:
1. Validate checkpoint exists and is recent
2. Skip completed phases
3. Resume seamlessly from next phase

**See**: [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md) - Schema and implementation details

### Progress Markers

**Format**: `PROGRESS: [Phase N] - [action]`

**Documentation**: See [Orchestration Best Practices → Standardized Progress Markers](./orchestration-best-practices.md#standardized-progress-markers) for format specification, implementation details, parsing examples, and external tool integration.

---

## Usage Examples

### Example 1: Research-Only Workflow

```bash
/coordinate "research GraphQL federation patterns for microservices"
```

**Expected Output**:
```
Phase 0: Initialization complete
PROGRESS: [Phase 0] - Topic directory created

Phase 1: Research
PROGRESS: [Phase 1] - Invoking 4 research agents in parallel
  Agent 1: Architecture patterns
  Agent 2: Implementation examples
  Agent 3: Performance considerations
  Agent 4: Best practices

PROGRESS: [Phase 1] - All research agents completed

✅ Workflow complete: research-only

Artifacts created:
  - specs/042_graphql_federation_patterns_for_microservices/reports/001_architecture_patterns.md
  - specs/042_graphql_federation_patterns_for_microservices/reports/002_implementation_examples.md
  - specs/042_graphql_federation_patterns_for_microservices/reports/003_performance_considerations.md
  - specs/042_graphql_federation_patterns_for_microservices/reports/004_best_practices.md
```

### Example 2: Research-and-Plan Workflow

```bash
/coordinate "research authentication patterns to create OAuth2 implementation plan"
```

**Expected Output**:
```
Phase 0: Initialization complete
PROGRESS: [Phase 0] - Topic directory created

Phase 1: Research
PROGRESS: [Phase 1] - Invoking 4 research agents in parallel
  [... agent details ...]
PROGRESS: [Phase 1] - All research agents completed

Phase 2: Planning
PROGRESS: [Phase 2] - Invoking plan-architect agent
PROGRESS: [Phase 2] - Implementation plan created

✅ Workflow complete: research-and-plan

Artifacts created:
  - specs/043_oauth2_implementation/reports/ (4 reports)
  - specs/043_oauth2_implementation/plans/001_oauth2_implementation_plan.md
```

### Example 3: Full-Implementation Workflow

```bash
/coordinate "implement user profile page with avatar upload"
```

**Expected Output**:
```
Phase 0: Initialization complete
Phase 1: Research complete (4 reports)
Phase 2: Planning complete (1 plan with 6 phases)
Phase 3: Wave-Based Implementation
  Dependency analysis: 3 waves identified
  Wave 1: [Phase 1, Phase 2] ✓
  Wave 2: [Phase 3, Phase 4, Phase 5] ✓
  Wave 3: [Phase 6] ✓
Phase 4: Testing
  Test suite: 23/23 tests passed ✓
Phase 6: Documentation
  Updated: README.md, API.md ✓

✅ Workflow complete: full-implementation

Artifacts created:
  - specs/044_user_profile_with_avatar/reports/ (4 reports)
  - specs/044_user_profile_with_avatar/plans/001_implementation_plan.md
  - specs/044_user_profile_with_avatar/summaries/001_implementation_summary.md
  - src/components/UserProfile.tsx (created)
  - src/api/profileApi.ts (modified)
  - tests/UserProfile.test.tsx (created)
```

### Example 4: Debug-Only Workflow

```bash
/coordinate "fix the infinite loop in the token refresh logic"
```

**Expected Output**:
```
Phase 0: Initialization complete
Phase 1: Root Cause Analysis
  Analyzing: src/auth/tokenRefresh.ts
  Issue identified: Race condition in refresh state
Phase 5: Debug and Fix
  Fix applied: Added mutex lock
  Tests: 5/5 passed ✓

✅ Workflow complete: debug-only

Artifacts created:
  - specs/045_token_refresh_infinite_loop_fix/reports/001_debug_analysis.md
  - src/auth/tokenRefresh.ts (modified)
```

### Example 5: Research-and-Revise Workflow

**Use Case**: Update existing implementation plan based on new research findings

```bash
/coordinate "Revise the plan /home/benjamin/.config/.claude/specs/042_auth/plans/001_auth_plan.md to accommodate recent security research"
```

**Expected Output**:
```
Phase 0: Initialization complete
  - Scope detected: research-and-revise
  - Existing plan: /home/benjamin/.config/.claude/specs/042_auth/plans/001_auth_plan.md
  - EXISTING_PLAN_PATH saved to workflow state ✓

Phase 1: Research (2 agents in parallel)
  - Security best practices analysis
  - Authentication vulnerabilities assessment

Phase 2: Planning (revision-specialist agent invoked)
  - Backup created: 001_auth_plan.md.backup-20251111-120000 ✓
  - Plan revised with security findings
  - Completed phases preserved
  - Revision history updated

✅ Workflow complete: research-and-revise

Artifacts created:
  - specs/042_auth/reports/001_security_analysis.md
  - specs/042_auth/reports/002_vulnerability_assessment.md
  - specs/042_auth/plans/001_auth_plan.md (updated)
  - specs/042_auth/plans/001_auth_plan.md.backup-20251111-120000
```

**Key Differences from Other Workflows**:
- Uses existing topic directory (doesn't create new)
- Invokes revision-specialist agent (not plan-architect)
- Creates timestamped backup before modification
- Preserves completed phases in plan
- Updates revision history section
- Terminal state is "plan" (doesn't proceed to implementation)

**Scope Detection**:
research-and-revise workflow requires both:
1. Revision keyword ("revise", "update plan", "modify plan")
2. Full absolute path to existing plan file

**Path Requirements**:
- MUST be absolute path (starts with `/`)
- MUST match pattern `/specs/NNN_topic/plans/NNN_plan.md`
- Plan file MUST exist before /coordinate is invoked

**Common Errors**:
- "research-and-revise workflow requires existing plan path" → Missing plan path in workflow description
- "Extracted plan path does not exist" → Typo in path or file doesn't exist
- "EXISTING_PLAN_PATH not restored from workflow state" → Bug in Phase 1 (should not occur after Spec 665 fix)

---

## Troubleshooting

### Common Issues

#### Issue 1: "command not found" Errors During Initialization

**Symptom**: `/coordinate` fails with `verify_state_variable: command not found` or `handle_state_error: command not found`

**Root Cause**: Library sourcing order violation - functions called before libraries sourced

**Error Examples**:
```
bash: verify_state_variable: command not found
bash: handle_state_error: command not found
bash: verify_file_created: command not found
```

**Fix**: Verify library sourcing order in coordinate.md

The /coordinate command must source libraries in this order:

```bash
# 1. State machine core (lines 88-105)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# 2. Error handling and verification (lines 107-127) - BEFORE any function calls
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# 3. Additional libraries (line 192+)
source_required_libraries "${REQUIRED_LIBS[@]}"
```

**Verification Commands**:
```bash
# Check sourcing order
grep -n "^source.*error-handling.sh" .claude/commands/coordinate.md
grep -n "^source.*verification-helpers.sh" .claude/commands/coordinate.md
# Both should appear before line 150 (before first function calls)

# Validate with automated test
bash .claude/tests/test_library_sourcing_order.sh
```

**Root Cause Details**:
- Each bash block runs in a separate subprocess
- Functions don't persist across bash block boundaries
- Libraries must be sourced in EVERY block that uses their functions
- Premature function calls (before sourcing) cause "command not found" errors

**Fixed In**: Spec 675 (2025-11-11) - Moved error-handling.sh and verification-helpers.sh sourcing to immediately after state-persistence.sh (lines 107-127), before any verification checkpoints or error handling calls.

**See Also**:
- [Bash Block Execution Model](../concepts/bash-block-execution-model.md#function-availability-and-sourcing-order) - Complete sourcing order documentation
- [Spec 675](../../specs/675_infrastructure_and_the_claude_docs_standards/) - Library sourcing order fix

#### Issue 2: Verification Checkpoint Failures

**Symptom**: "CRITICAL: State file verification failed - variables not written"

**Root Cause Check**:
1. Inspect state file: `cat "$STATE_FILE"`
2. Check if variables present with `export` prefix
3. If variables exist → grep pattern issue (see Spec 644)
4. If variables missing → actual write failure

**Fixed Issues**:
- **Spec 644** (2025-11-10): Grep pattern didn't match export format. Variables were correctly written as `export VAR="value"` but verification checked for `^VAR=` pattern, causing false negatives.

**Solution if variables exist**:
The variables are correctly written. This is a verification pattern bug. Update grep patterns to include `export` prefix:

```bash
# Correct pattern
if grep -q "^export VARIABLE_NAME=" "$STATE_FILE"; then
  echo "✓ Variable verified"
fi
```

**Solution if variables truly missing**:
```bash
# Check append_workflow_state function
source .claude/lib/state-persistence.sh
type append_workflow_state  # Should show function definition

# Check file permissions
ls -la "$STATE_FILE"
df -h "$STATE_FILE"  # Check disk space
```

See [Verification Checkpoint Pattern](../architecture/coordinate-state-management.md#verification-checkpoint-pattern) for complete documentation.

#### Issue 3: State ID File Not Found / State Persistence Failures

**Symptom**: `/coordinate` fails with "State ID file not found" or "CRITICAL: State ID file not created"

**Error Examples**:
```
ERROR: State ID file does not exist
   Expected path: /home/user/.claude/tmp/coordinate_state_id.txt

CRITICAL: State ID file not created at /home/user/.claude/tmp/coordinate_state_id.txt

TROUBLESHOOTING:
  1. Verify init_workflow_state() was called in first bash block
  2. Check STATE_FILE variable was saved to state correctly
  3. Verify workflow ID file exists and contains valid ID
  4. Ensure no premature cleanup of state files
```

**Root Cause**: One of two bugs fixed in Spec 661:
1. **Premature EXIT trap**: Trap in Block 1 deletes state ID file when block exits
2. **Timestamp-based filename**: Discovery pattern fails across subprocess boundaries

**Diagnostic Steps**:

1. **Check if state ID file exists** after Block 1:
```bash
# Run coordinate command, then immediately check:
ls -la "${HOME}/.claude/tmp/coordinate_state_id.txt"

# If missing → EXIT trap fired prematurely (Bug 1)
# If exists → Good, proceed to step 2
```

2. **Check for premature EXIT trap** in Block 1:
```bash
# Search for EXIT trap in first bash block (should NOT exist)
head -200 .claude/commands/coordinate.md | grep "trap.*EXIT.*coordinate_state_id"

# If found → Bug 1 (premature EXIT trap)
# If not found → Pattern 6 correctly implemented
```

3. **Verify fixed semantic filename** used:
```bash
# Check for fixed location (correct pattern)
grep 'COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"' \
  .claude/commands/coordinate.md

# If not found → Check for old timestamp pattern (incorrect)
grep 'COORDINATE_STATE_ID_FILE=.*$(date' .claude/commands/coordinate.md
```

4. **Test state persistence** across bash blocks:
```bash
# Run comprehensive test suite
bash .claude/tests/test_coordinate_exit_trap_timing.sh
bash .claude/tests/test_coordinate_bash_block_fixes_integration.sh
```

**Fixed In**: Spec 661 (2025-11-11) - Implemented two critical fixes:

**Fix 1: State ID File Persistence** (Pattern 1 + Pattern 6)
- Changed from timestamp-based to fixed semantic filename
- Removed premature EXIT trap from Block 1
- Moved cleanup to final completion function only

**Fix 2: Library Sourcing Order** (Standard 15)
- Load workflow state BEFORE re-sourcing libraries
- Maintain consistent dependency order in ALL bash blocks
- Add verification checkpoints after library initialization

**Resolution**:

If you encounter this issue, verify both fixes are applied:

```bash
# 1. Verify Pattern 1 (Fixed Semantic Filename)
grep -q 'COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"' \
  .claude/commands/coordinate.md && echo "✓ Pattern 1 OK" || echo "✗ Pattern 1 MISSING"

# 2. Verify Pattern 6 (No premature EXIT trap)
! head -200 .claude/commands/coordinate.md | grep -q "trap.*EXIT.*coordinate_state_id" \
  && echo "✓ Pattern 6 OK" || echo "✗ Pattern 6 VIOLATED"

# 3. Verify Standard 15 (Library sourcing order)
bash .claude/tests/test_library_sourcing_order.sh
```

**Why These Patterns Matter**:

- **Pattern 1 (Fixed Semantic Filename)**: Subsequent bash blocks need predictable location to find state ID
- **Pattern 6 (Cleanup on Completion Only)**: EXIT traps fire when bash block exits (subprocess termination), causing premature cleanup
- **Standard 15 (Library Sourcing Order)**: Loading state before sourcing prevents WORKFLOW_SCOPE reset

**Common Mistakes to Avoid**:

❌ **Wrong**: Timestamp-based state ID filename
```bash
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_$(date +%s%N).txt"
# Problem: Subsequent blocks don't know the timestamp
```

✅ **Correct**: Fixed semantic filename
```bash
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
# Solution: Predictable location for all blocks
```

❌ **Wrong**: EXIT trap in Block 1
```bash
trap 'rm -f "$COORDINATE_STATE_ID_FILE"' EXIT
# Problem: Fires when Block 1 exits, before Block 2 runs
```

✅ **Correct**: Cleanup in final block only
```bash
# Block 1, 2, N-1: NO EXIT traps
# Block N (final): Manual cleanup or trap here
rm -f "$COORDINATE_STATE_ID_FILE" "$STATE_FILE"
```

**See Also**:
- [Bash Block Execution Patterns](#bash-block-execution-patterns) - Complete documentation of all patterns
- [Spec 661](../../specs/661_and_the_standards_in_claude_docs_to_avoid/) - State persistence and library sourcing fixes
- [test_coordinate_exit_trap_timing.sh](../../tests/test_coordinate_exit_trap_timing.sh) - 9 tests validating Pattern 1 + Pattern 6
- [test_coordinate_bash_block_fixes_integration.sh](../../tests/test_coordinate_bash_block_fixes_integration.sh) - 7 integration tests

---

#### Issue 2: Agent Failed to Create Expected File

**Symptoms**:
- Error message: "Agent failed to create expected file"
- Verification checkpoint fails
- Workflow terminates

**Cause**:
- Agent behavioral file missing or incorrect
- Agent misinterpreted instructions
- File system permissions issue
- Path calculation error

**Solution**:
```bash
# Check if agent behavioral file exists
ls -la .claude/agents/research-specialist.md

# Check topic directory permissions
ls -la specs/

# Verify path calculation
echo $REPORT_PATH

# Check agent output for error messages
# (agent output is shown before verification checkpoint)
```

#### Issue 2: Workflow Scope Detection Incorrect

**Symptoms**:
- Wrong phases execute
- Expected phases skipped
- Workflow type mismatch
- "implement <plan-path>" detected as research-and-plan instead of full-implementation

**Root Causes**:
1. **Ambiguous workflow description** - Missing clear keywords
2. **Plan path not recognized** - Path doesn't match `specs/[0-9]+_*/plans/*.md` pattern
3. **Revision pattern takes priority** - "revise...plan" keywords override plan path detection
4. **Outdated scope detection logic** - Bug fixed in Spec 664 (2025-11-11)

**Solution - Test Scope Detection**:
```bash
# Enable debug logging to see detection rationale
export DEBUG_SCOPE_DETECTION=1

# Test scope detection manually
source .claude/lib/workflow-scope-detection.sh
detect_workflow_scope "implement specs/661_auth/plans/001_implementation.md"
# Expected output: full-implementation

# Test revision pattern priority
detect_workflow_scope "revise specs/027_auth/plans/001_plan.md based on feedback"
# Expected output: research-and-revise

# Check detection algorithm (should see priority order comments)
cat .claude/lib/workflow-scope-detection.sh | grep -A 5 "PRIORITY"
```

**Solution - Be More Explicit**:
```bash
# ❌ Ambiguous (will default to research-and-plan)
/coordinate "look at authentication"

# ✅ Explicit research-only
/coordinate "research authentication patterns"

# ✅ Explicit full-implementation (keyword)
/coordinate "implement new authentication feature"

# ✅ Explicit full-implementation (plan path)
/coordinate "implement specs/042_auth/plans/001_oauth.md"

# ✅ Explicit research-and-revise
/coordinate "revise the authentication plan based on security review"
```

**Solution - Check Algorithm Priority**:

Scope detection follows this priority order (as of Spec 664):
1. **Revision patterns** (`revise|update|modify...plan...`)
2. **Plan paths** (`specs/*/plans/*.md`)
3. **Research-only** (`research...` without action keywords)
4. **Explicit implementation** (`implement|execute` keyword)
5. **Other patterns** (`plan`, `debug`, `build feature`, etc.)

If detection seems wrong, check which pattern matched first:
```bash
# View complete detection function
cat .claude/lib/workflow-scope-detection.sh

# Run comprehensive test suite
bash .claude/tests/test_workflow_scope_detection.sh
```

**Fixed in Spec 664** (2025-11-11):
- Plan path detection now recognizes absolute/relative paths and explicit "implement" keyword
- Priority order clarified to handle revision vs implementation correctly
- 20 comprehensive test cases added to prevent regression

---

#### Issue 2a: Revision Workflow Creates New Topic Instead of Using Existing

**Symptoms**:
- Revision workflow creates NEW topic directory (e.g., `662_plans_001_...`)
- Error: "research-and-revise workflow requires /path/to/662_plans_001_.../plans directory but it does not exist"
- Expected EXISTING topic directory not used (e.g., should use `657_topic`)

**Root Cause**:
Path initialization didn't extract topic from provided plan path. This was fixed in Issue #661.

**Solution**:
Ensure you're running latest version with Issue #661 fix:
```bash
# Check if extract_topic_from_plan_path function exists
grep -n "extract_topic_from_plan_path" .claude/lib/workflow-initialization.sh

# Should show function definition around line 78
# If not found, you need to update to latest version
```

**Workaround (if fix not available)**:
Navigate to the existing topic directory before running coordinate:
```bash
cd .claude/specs/657_existing_topic/
/coordinate "Revise the plan ./plans/001_plan.md to accommodate changes"
```

**Correct Workflow Description Format**:
```bash
# Include FULL absolute path to plan file
/coordinate "Revise the plan /home/user/.claude/specs/657_topic/plans/001_plan.md to accommodate new requirements"

# NOT just: "Revise 001_plan.md"
# NOT just: "Update the plan to accommodate..."
```

---

#### Issue 2b: Revision Workflow Fails with "EXISTING_PLAN_PATH not set"

**Symptoms**:
- Error: "ERROR: research-and-revise workflow requires existing plan path"
- Error: "Workflow description: [your description]"
- Error: "Check workflow description contains full plan path"

**Root Cause**:
Workflow description doesn't contain a recognizable plan path for scope detection to extract.

**Solution**:
Include the complete plan path in your workflow description:
```bash
# ✓ CORRECT - Full absolute path
/coordinate "Revise the plan /home/user/.claude/specs/657_topic/plans/001_plan.md to add caching"

# ✗ WRONG - No path
/coordinate "Revise the implementation plan to add caching"

# ✗ WRONG - Relative path without context
/coordinate "Revise plans/001_plan.md to add caching"
```

**Verification**:
Test if scope detection can extract the path:
```bash
source .claude/lib/workflow-scope-detection.sh
WORKFLOW_DESCRIPTION="Revise the plan /path/to/specs/657_topic/plans/001_plan.md"
detect_workflow_scope "$WORKFLOW_DESCRIPTION"
# Should output: research-and-revise
echo $EXISTING_PLAN_PATH
# Should output: /path/to/specs/657_topic/plans/001_plan.md
```

---

#### Issue 2c: Revision Workflow Fails with "Plan file does not exist"

**Symptoms**:
- Error: "ERROR: Specified plan file does not exist"
- Error: "Plan path: /path/to/plan.md"
- Error: "Verify file path is correct: test -f ..."

**Root Cause**:
The path provided in workflow description points to a non-existent file.

**Solution**:
```bash
# Verify the plan file exists
ls -la /home/user/.claude/specs/657_topic/plans/001_plan.md

# Check for typos in path
# Common issues:
#   - Wrong topic number (657 vs 658)
#   - Wrong plan number (001 vs 002)
#   - .md extension missing or wrong

# List available plans
ls -la .claude/specs/*/plans/*.md

# Copy exact path to avoid typos
realpath .claude/specs/657_topic/plans/001_plan.md
# Then paste into workflow description
```

---

#### Issue 2d: Revision Workflow Fails with "Topic directory does not exist"

**Symptoms**:
- Error: "ERROR: Extracted topic directory does not exist"
- Error: "Topic directory: /path/to/specs/NNN_topic"
- Error: "Extracted from: /path/to/plan.md"

**Root Cause**:
Plan path format is malformed or topic directory was deleted.

**Solution**:
```bash
# Verify topic directory exists
ls -la .claude/specs/657_topic/

# Check path format matches expected structure
# Expected: /path/to/specs/NNN_topic/plans/NNN_plan.md
#                         └────────┘ └───┘
#                         topic dir   plans subdir

# If topic directory doesn't exist, this may not be a revision workflow
# Create a new plan instead:
/coordinate "research topic and create new plan"
```

---

#### Issue 2e: EXISTING_PLAN_PATH Not Persisting Across Bash Blocks

**Symptom**: Error "EXISTING_PLAN_PATH not restored from workflow state" during planning phase

**Root Cause**: Subprocess isolation - `export` in library function doesn't persist to parent bash block

**Technical Details**:
- Each bash block in coordinate.md runs as separate subprocess
- `export EXISTING_PLAN_PATH` in workflow-scope-detection.sh creates subprocess variable
- Variable lost when subprocess exits (before next bash block executes)
- **Solution**: Save to workflow state file immediately after extraction

**How It Was Fixed (Spec 665)**:

In coordinate.md (after sm_init, lines 127-153):
```bash
# ADDED: Extract and save EXISTING_PLAN_PATH for research-and-revise workflows
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
  # Extract plan path from workflow description
  if echo "$SAVED_WORKFLOW_DESC" | grep -Eq "/specs/[0-9]+_[^/]+/plans/"; then
    EXISTING_PLAN_PATH=$(echo "$SAVED_WORKFLOW_DESC" | grep -oE "/[^ ]+\.md" | head -1)
    export EXISTING_PLAN_PATH

    # CRITICAL: Verify file exists before proceeding
    if [ ! -f "$EXISTING_PLAN_PATH" ]; then
      handle_state_error "Extracted plan path does not exist: $EXISTING_PLAN_PATH" 1
    fi

    echo "✓ Extracted existing plan path: $EXISTING_PLAN_PATH"
  else
    handle_state_error "research-and-revise workflow requires plan path in description" 1
  fi
fi

# ADDED: Save EXISTING_PLAN_PATH to state for bash block persistence
if [ -n "${EXISTING_PLAN_PATH:-}" ]; then
  append_workflow_state "EXISTING_PLAN_PATH" "$EXISTING_PLAN_PATH"
fi
```

**Verification**:
```bash
# Check workflow state file contains EXISTING_PLAN_PATH
cat "${HOME}/.claude/tmp/workflow_coordinate_*.sh" | grep EXISTING_PLAN_PATH

# Expected: export EXISTING_PLAN_PATH="/absolute/path/to/plan.md"
```

**See Also**:
- [Bash Block Execution Model](.claude/docs/concepts/bash-block-execution-model.md)
- [State Persistence Pattern](.claude/docs/concepts/patterns/state-persistence.md)
- [Spec 665 Implementation Plan](../specs/665_research_the_output_homebenjaminconfigclaudespecs/plans/001_coordinate_fixes_implementation_plan.md)

---

#### Issue 3: JQ Parse Errors (Empty Report Arrays)

**Symptom**: `jq: parse error: Invalid numeric literal at line 1, column...`

**Cause**: Empty or malformed `REPORT_PATHS_JSON` variable when parsing report paths from state

**When It Occurs**:
- Research phase produces no reports (edge case)
- REPORT_PATHS_JSON not initialized
- Malformed JSON from previous phase

**Solution**: Fixed in Spec 652 (coordinate.md lines 605-611, 727-739)

The coordinate command now:
- Explicitly handles empty arrays: `REPORT_PATHS_JSON="[]"`
- Validates JSON before parsing: `jq empty 2>/dev/null`
- Falls back to empty array on malformed JSON
- Logs success: "Loaded N report paths from state"

**Verification**:
```bash
# Test empty array handling
SUCCESSFUL_REPORT_PATHS=()
if [ ${#SUCCESSFUL_REPORT_PATHS[@]} -eq 0 ]; then
  REPORT_PATHS_JSON="[]"
fi
echo "$REPORT_PATHS_JSON" | jq empty && echo "✓ Valid JSON"

# Test malformed JSON recovery
REPORT_PATHS_JSON="invalid json"
if echo "$REPORT_PATHS_JSON" | jq empty 2>/dev/null; then
  echo "Valid JSON"
else
  echo "✓ Fallback to empty array triggered"
  REPORT_PATHS=()
fi
```

**Related Tests**: `.claude/tests/test_coordinate_error_fixes.sh` - Tests 1, 2, 4

---

#### Issue 4: Missing State File Errors

**Symptom**: `grep: /path/to/state: No such file or directory`

**Cause**: State file accessed before creation or after premature deletion

**When It Occurs**:
- State file not initialized in first bash block
- Workflow ID file missing or corrupted
- Premature EXIT trap cleanup
- File system issues

**Solution**: Fixed in Spec 652 (verification-helpers.sh lines 155-167)

The `verify_state_variables()` function now:
- Checks file existence BEFORE grep operations
- Provides clear diagnostic error messages
- Lists expected file path
- Suggests troubleshooting steps

**Error Message**:
```
✗ ERROR: State file does not exist
   Expected path: /path/to/state/file

TROUBLESHOOTING:
  1. Verify init_workflow_state() was called in first bash block
  2. Check STATE_FILE variable was saved to state correctly
  3. Verify workflow ID file exists and contains valid ID
  4. Ensure no premature cleanup of state files
```

**Verification**:
```bash
# Test missing file detection
STATE_FILE="/tmp/nonexistent.state"
VARS=("VAR1" "VAR2")
if verify_state_variables "$STATE_FILE" "${VARS[@]}" 2>/dev/null; then
  echo "ERROR: Should have failed"
else
  echo "✓ Missing file detected correctly"
fi
```

**Related Tests**: `.claude/tests/test_coordinate_error_fixes.sh` - Test 4

---

#### Issue 5: State Transition Validation Failures

**Symptom**: `ERROR: Expected state 'plan' but current state is 'implement'`

**Cause**: State validation logic out of sync with state machine transitions

**When It Occurs**:
- sm_transition not called before validation
- State not persisted to workflow state
- Subprocess state restoration failure
- State machine transition error

**Solution**: Fixed in Spec 652 (coordinate.md lines 221-224, 660-663, 1002-1005)

The coordinate command now:
- Logs state transitions with timestamps
- Calls `sm_transition()` BEFORE validation
- Persists state immediately after transition
- Provides enhanced error diagnostics

**Transition Logging**:
```bash
Transitioning from research to plan
sm_transition "$STATE_PLAN"
append_workflow_state "CURRENT_STATE" "$STATE_PLAN"
State transition complete: 2025-11-10 14:30:45
```

**Enhanced Error Message**:
```
ERROR: State transition validation failed
  Expected: plan
  Actual: implement

TROUBLESHOOTING:
  1. Verify sm_transition was called in previous bash block
  2. Check workflow state file for CURRENT_STATE value
  3. Verify workflow scope: full-implementation
  4. Review state machine transition logs above
```

**Verification**:
```bash
# Test state transitions
source .claude/lib/workflow-state-machine.sh
sm_init "Test" "coordinate"
sm_transition "$STATE_RESEARCH"
[ "$CURRENT_STATE" = "$STATE_RESEARCH" ] && echo "✓ Transition works"
```

**Related Tests**: `.claude/tests/test_coordinate_error_fixes.sh` - Test 5

---

#### Issue 6: Context Budget Exceeded

**Symptoms**:
- Token limit warnings
- Performance degradation
- Out of memory errors

**Cause**:
- Metadata extraction failed
- Context pruning not applied
- Large artifact files retained in context

**Solution**:
```bash
# Check context pruning library
cat .claude/lib/context-pruning.sh

# Verify metadata extraction
cat .claude/lib/metadata-extraction.sh

# Review artifact sizes
du -sh specs/042_*/reports/*
```

#### Issue 4: Wave Execution Hangs

**Symptoms**:
- Implementation phase stuck
- No progress for extended period
- Partial wave completion

**Cause**:
- Circular dependencies in plan
- Agent failure mid-wave
- Dependency analyzer error

**Solution**:
```bash
# Check plan dependencies for cycles
grep -A 5 "dependencies:" specs/*/plans/*.md

# Verify dependency analyzer
cat .claude/lib/dependency-analyzer.sh

# Check agent logs for failures
cat .claude/data/logs/coordinate-*.log

# Resume from checkpoint
# (automatic on next /coordinate invocation)
```

#### Issue 5: Variables Not Exported from Functions (Subshell Export Bug)

**Symptom**: Variables set by function not available after call

**Error Examples**:
```
ERROR: initialize_workflow_paths() requires WORKFLOW_SCOPE as second argument
WORKFLOW_SCOPE: <not set>
```

**Cause**: Command substitution creates subshell (see [Bash Block Execution Model](../concepts/bash-block-execution-model.md))

**Example**:
```bash
# WRONG - creates subshell:
RESULT=$(my_function)  # Subshell - exports don't propagate

# CORRECT - parent shell:
my_function >/dev/null  # Parent shell - exports available
RESULT="$EXPORTED_VAR"  # Use exported variable
```

**Fixed In**: Spec 683 - coordinate.md line 165 (sm_init call pattern)

**Root Cause Details**:
- Command substitution `$(...)` creates subprocess
- `export` statements in subprocess don't affect parent shell
- Parent shell never sees the exported variables
- Functions must be called directly (not via command substitution) to export to parent

**Solution**:
```bash
# Incorrect pattern (don't use):
COMPLEXITY=$(sm_init "$workflow_desc" "coordinate")

# Correct pattern (use this):
sm_init "$workflow_desc" "coordinate" >/dev/null
# Variables now available: $WORKFLOW_SCOPE, $RESEARCH_COMPLEXITY, $RESEARCH_TOPICS_JSON
```

**See Also**:
- [Bash Block Execution Model](../concepts/bash-block-execution-model.md#subprocess-isolation) - Complete subprocess patterns
- [Spec 683 Bug #1 Fix](../../specs/683_coordinate_critical_bug_fixes/plans/001_coordinate_bug_fixes.md#bug-1-subshell-export-fix-completed) - Complete root cause analysis

#### Issue 6: Verification Mismatch Between Allocated and Invoked Agents

**Symptom**: Research phase fails with verification error showing mismatch between expected and actual report counts

**Error Examples**:
```
Dynamic path discovery complete: 0/2 files discovered
MANDATORY VERIFICATION: Research Phase Artifacts
Checking 2 research reports...

  Report 1/2: ✗ ERROR [Research]: Research report 1/2 verification failed

❌ CRITICAL: Research artifact verification failed
   2 reports not created at expected paths
```

**Yet**:
- 3 research agents were actually invoked (Task 1, 2, 3 all completed)
- 3 report files were created (001, 002, 003 all exist)
- Verification expects 2 but finds 3

**Root Cause**: RESEARCH_COMPLEXITY was calculated correctly by `sm_init()` in Phase 0 (initialize), but then immediately recalculated using hardcoded regex patterns in Phase 1 (research). This created a mismatch between:
- **Allocated paths**: Based on sm_init complexity (e.g., 2)
- **Invoked agents**: Based on recalculated complexity (e.g., 3 due to "integrate" keyword match)
- **Verification loops**: Based on recalculated complexity (checking for 2 or 3, inconsistent)

**Impact**: ~40-50% of workflows containing keywords like "integrate", "migration", "refactor", "architecture" experienced verification failures despite successful research completion.

**Fixed In**: Spec 687 (2025-11-12) - Removed hardcoded recalculation entirely

**Solution Applied**:
1. **Phase 1 (Research Handler)**: Removed lines 419-432 (hardcoded pattern matching), replaced with state load validation and fallback warning
2. **Dynamic Discovery Loop**: Changed from `$RESEARCH_COMPLEXITY` to `$REPORT_PATHS_COUNT` (line 691)
3. **Verification Loop**: Changed from `$RESEARCH_COMPLEXITY` to `$REPORT_PATHS_COUNT` (line 797)
4. **State Machine Library**: Added critical comments documenting that RESEARCH_COMPLEXITY must never be recalculated after sm_init()

**Verification**:
```bash
# Verify hardcoded recalculation removed
grep -n "RESEARCH_COMPLEXITY=[0-9]" .claude/commands/coordinate.md
# Should only show fallback at line ~427, not multiple assignments

# Verify loops use REPORT_PATHS_COUNT
grep -n "seq 1.*REPORT_PATHS_COUNT" .claude/commands/coordinate.md
# Should show lines 691 (discovery) and 797 (verification)

# Test with "integrate" keyword (previously triggered bug)
/coordinate "Research how to integrate authentication patterns"
# Should succeed with consistency: N agents invoked, N reports verified
```

**Fallback Behavior**: If RESEARCH_COMPLEXITY is not loaded from state (defensive check), command falls back to complexity=2 with a warning to stderr.

**See Also**:
- [Root Cause Analysis Report](../../specs/coordinate_command_error/reports/001_root_cause_analysis.md) - Complete 484-line analysis
- [Bug Fix Implementation Plan](../../specs/coordinate_command_error/plans/001_fix_research_complexity_bug.md) - 5-phase fix plan
- [Spec 678](../../specs/678_coordinate_haiku_classification/) - Comprehensive classification integration

### Debug Mode

**Enable verbose logging**:
```bash
export COORDINATE_DEBUG=1
/coordinate "your workflow"
```

**Output**: Detailed logging of:
- Library function calls
- Path calculations
- Agent invocations
- Verification checkpoints
- Context pruning operations

### Getting Help

- Check [Orchestration Best Practices Guide](./orchestration-best-practices.md) for patterns
- Review [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md)
- See [Hierarchical Agent Architecture](../concepts/hierarchical_agents.md)
- Consult [Command Reference](../reference/command-reference.md) for quick syntax

---

## Phase 4 Improvements: State Variable Verification and Concurrent Workflow Isolation

This section documents improvements implemented in Spec 672 Phase 4 to enhance state management reliability and concurrent workflow support.

### State Variable Verification Checkpoints

**Purpose**: Prevent unbound variable errors by verifying state persistence immediately after critical operations.

**Pattern**: Use `verify_state_variable()` function from `verification-helpers.sh` after state writes.

**Example**:
```bash
# After sm_init
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"

# Verification checkpoint (fail-fast if persistence failed)
verify_state_variable "WORKFLOW_SCOPE" || {
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not persisted to state after sm_init" 1
}
```

**Verification Points in /coordinate**:
1. **WORKFLOW_SCOPE** - After sm_init (line 151)
2. **REPORT_PATHS_COUNT** - After array export (line 233)
3. **EXISTING_PLAN_PATH** - For research-and-revise workflows (line 160)

**Benefits**:
- Fail-fast error detection (catches state persistence failures immediately)
- Comprehensive diagnostics (shows expected format, state file path, troubleshooting steps)
- Prevents cascading errors (stops workflow before unbound variable errors occur)

**Reference**: See [verify_state_variable() documentation](../lib/verification-helpers.sh)

### Concurrent Workflow Isolation

**Purpose**: Allow multiple `/coordinate` workflows to run simultaneously without state file interference.

**Problem**: Old pattern used fixed location for state ID file, causing concurrent workflows to overwrite each other's state.

**Solution**: Unique timestamp-based state ID files per workflow.

**Old Pattern** (concurrent workflows interfere):
```bash
# Fixed location - all workflows use same file
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"
```

**New Pattern** (concurrent workflows isolated):
```bash
# Block 1: Create unique state ID file
TIMESTAMP=$(date +%s%N)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_${TIMESTAMP}.txt"
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"

# Persist path to workflow state
append_workflow_state "COORDINATE_STATE_ID_FILE" "$COORDINATE_STATE_ID_FILE"

# Cleanup trap (removes file after workflow completes)
trap "rm -f '$COORDINATE_STATE_ID_FILE' 2>/dev/null || true" EXIT

# Block 2+: Load with backward compatibility
COORDINATE_STATE_ID_FILE_OLD="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE_OLD" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE_OLD")
  load_workflow_state "$WORKFLOW_ID"

  # Check if workflow uses new unique pattern
  if [ -n "${COORDINATE_STATE_ID_FILE:-}" ] && [ "$COORDINATE_STATE_ID_FILE" != "$COORDINATE_STATE_ID_FILE_OLD" ]; then
    # New pattern: COORDINATE_STATE_ID_FILE from workflow state
    : # Already set
  else
    # Old pattern: Use fixed location (backward compatibility)
    COORDINATE_STATE_ID_FILE="$COORDINATE_STATE_ID_FILE_OLD"
  fi
fi
```

**Benefits**:
- Concurrent workflow support (2+ workflows can run simultaneously)
- Backward compatibility (old workflows using fixed location still work)
- Automatic cleanup (trap removes state ID file when workflow exits)
- No race conditions (each workflow has isolated state)

**Testing**: See `.claude/tests/test_concurrent_workflows.sh` (5 tests, 100% pass rate)

### Defensive Array Reconstruction Pattern

**Purpose**: Prevent unbound variable errors when reconstructing arrays from workflow state.

**Problem**: Array variables are lost across bash block boundaries (subprocess isolation). When reconstructing arrays from indexed variables, missing variables cause unbound variable errors.

**Solution**: Generic `reconstruct_array_from_indexed_vars()` function with defensive checks.

**Pattern**:
```bash
# Generic reconstruction with defensive handling
reconstruct_array_from_indexed_vars() {
  local array_name="$1"
  local count_var_name="$2"
  local var_prefix="${3:-${array_name%S}}"  # Default: remove trailing 'S'

  # Defensive: Default to 0 if count variable unset
  local count="${!count_var_name:-0}"

  # Clear target array
  eval "${array_name}=()"

  # Reconstruct with defensive checks
  for ((i=0; i<count; i++)); do
    local var_name="${var_prefix}_${i}"

    # Defensive: Check if indexed variable exists
    if [ -n "${!var_name+x}" ]; then
      eval "${array_name}+=(\"${!var_name}\")"
    else
      echo "WARNING: $var_name missing from state (expected $count elements, skipping)" >&2
    fi
  done
}

# Usage
reconstruct_array_from_indexed_vars "REPORT_PATHS" "REPORT_PATHS_COUNT" "REPORT_PATH"
```

**Key Features**:
- **Defensive count check**: `${!count_var_name:-0}` prevents errors if count unset
- **Variable existence check**: `${!var_name+x}` tests if indexed variable exists
- **Graceful degradation**: Warns about missing variables instead of crashing
- **Reusable**: Works for any array type (reports, plans, artifacts)

**Reference**: See [workflow-initialization.sh](../lib/workflow-initialization.sh)

### Fail-Fast State Validation

**Purpose**: Distinguish expected vs unexpected missing state files for better error detection.

**Problem**: Missing state files can be expected (first bash block) or unexpected (subsequent blocks after state corruption). Old pattern treated both cases the same.

**Solution**: `is_first_block` parameter to `load_workflow_state()`.

**Pattern**:
```bash
# Block 1: Initialize state (missing state file is expected)
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

# Block 2+: Load state (missing state file is critical error)
load_workflow_state "$WORKFLOW_ID" false  # is_first_block=false

# Inside load_workflow_state():
load_workflow_state() {
  local workflow_id="$1"
  local is_first_block="${2:-false}"

  if [ ! -f "$STATE_FILE" ]; then
    if [ "$is_first_block" = "true" ]; then
      # Expected: Initialize new state
      init_workflow_state "$workflow_id"
      return 0
    else
      # Unexpected: Critical error
      echo "CRITICAL ERROR: Workflow state file missing" >&2
      echo "  Expected: $STATE_FILE" >&2
      echo "  Workflow ID: $workflow_id" >&2
      echo "  This indicates state corruption or premature cleanup" >&2
      return 2  # Distinct error code for fail-fast errors
    fi
  fi

  # Load state
  source "$STATE_FILE"
}
```

**Benefits**:
- Fail-fast error detection (unexpected missing files cause immediate failure)
- Clear diagnostics (distinguishes initialization vs corruption)
- Distinct error codes (0=success, 1=expected init, 2=critical error)

**Reference**: See [state-persistence.sh](../lib/state-persistence.sh)

### Decision Guide for State Variables

When implementing new state variables, use the [State Variable Decision Guide](./state-variable-decision-guide.md) to choose between file-based persistence and stateless recalculation.

**Quick decision**:
- **File-based persistence**: Expensive to compute (>100ms), non-deterministic, external dependencies, state mutations, arrays
- **Stateless recalculation**: Cheap (<10ms), deterministic, derived from persisted variables

**Examples**:
- ✓ Persist: `WORKFLOW_ID`, `REPORT_PATHS`, `COMPLETED_STATES`, `COORDINATE_STATE_ID_FILE`
- ✗ Don't persist: `REPORTS_DIR="${TOPIC_PATH}/reports"` (derived, <1ms)

---

## See Also

- [Orchestration Best Practices Guide](./orchestration-best-practices.md) - Unified framework for all orchestration commands
- [Orchestration Troubleshooting Guide](./orchestration-troubleshooting.md) - Debugging procedures
- [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md) - State preservation
- [Parallel Execution Pattern](../concepts/patterns/parallel-execution.md) - Wave-based execution details
- [Metadata Extraction Pattern](../concepts/patterns/metadata-extraction.md) - Context optimization
- [Context Management Pattern](../concepts/patterns/context-management.md) - Pruning techniques
- [Command Reference](../reference/command-reference.md) - Quick syntax reference
- [State Management Documentation](../architecture/coordinate-state-management.md) - Subprocess isolation patterns
