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
- **full-implementation**: Keywords like "implement", "build", "add feature"
- **debug-only**: Keywords like "fix [bug]", "debug [issue]", "troubleshoot [error]"

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

---

## Troubleshooting

### Common Issues

#### Issue 1: Verification Checkpoint Failures

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

**Cause**:
- Ambiguous workflow description
- Missing keywords for scope detection
- Library function issue

**Solution**:
```bash
# Be more explicit with keywords
# Instead of: "look at authentication"
# Use: "research authentication patterns"

# Check scope detection logic
cat .claude/lib/workflow-scope-detection.sh

# Test scope detection manually
source .claude/lib/workflow-scope-detection.sh
detect_workflow_scope "your description here"
```

#### Issue 3: Context Budget Exceeded

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

## See Also

- [Orchestration Best Practices Guide](./orchestration-best-practices.md) - Unified framework for all orchestration commands
- [Orchestration Troubleshooting Guide](./orchestration-troubleshooting.md) - Debugging procedures
- [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md) - State preservation
- [Parallel Execution Pattern](../concepts/patterns/parallel-execution.md) - Wave-based execution details
- [Metadata Extraction Pattern](../concepts/patterns/metadata-extraction.md) - Context optimization
- [Context Management Pattern](../concepts/patterns/context-management.md) - Pruning techniques
- [Command Reference](../reference/command-reference.md) - Quick syntax reference
- [State Management Documentation](../architecture/coordinate-state-management.md) - Subprocess isolation patterns
