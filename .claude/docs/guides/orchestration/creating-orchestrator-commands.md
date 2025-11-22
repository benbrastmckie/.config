# Creating Orchestrator Commands Guide

**Version**: 1.0.0
**Last Updated**: 2025-11-17

## Overview

This guide provides patterns and best practices for creating orchestrator commands that leverage the state machine architecture and library-based reuse. Orchestrator commands coordinate multiple agents to execute complex workflows (research, planning, implementation, debugging, documentation).

**Key Principles**:
- Library-based reuse at runtime (not template-based generation)
- Hardcoded workflow type (no LLM classification)
- State machine integration with validated transitions
- Imperative agent invocation (Standard 11 compliance)
- Fail-fast verification checkpoints (no retries, no fallbacks)
- 150-200 lines per command (focused implementation)

## Command Structure

Every orchestrator command follows a five-section structure:

### 1. YAML Frontmatter

```yaml
---
allowed-tools: Task, TodoWrite, Bash, Read
argument-hint: <workflow-description>
description: [Workflow-specific description]
command-type: primary
dependent-agents: [Workflow-specific agents]
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
---
```

**Key Elements**:
- `allowed-tools`: Minimum set required (Task for agent delegation, TodoWrite for progress tracking, Bash for execution, Read for file access)
- `library-requirements`: Semantic version constraints for dependencies (format: `library-name.sh: ">=major.minor.patch"`)
- `dependent-agents`: List of agents this command invokes (for dependency tracking)

### 2. Workflow Description Capture

**Pattern**: Capture user input and extract any embedded flags

```bash
# Part 1: Capture Workflow Description

WORKFLOW_DESCRIPTION="$1"

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description required"
  echo "USAGE: /command-name <workflow-description>"
  exit 1
fi

# Parse optional flags (e.g., --complexity)
RESEARCH_COMPLEXITY="${DEFAULT_COMPLEXITY}"  # Command-specific default

# Support both embedded and explicit flag formats:
# - Embedded: /command "description --complexity 4"
# - Explicit: /command --complexity 4 "description"
if [[ "$WORKFLOW_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  # Strip flag from workflow description
  WORKFLOW_DESCRIPTION=$(echo "$WORKFLOW_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//')
fi

# Validation: reject invalid complexity values
if ! echo "$RESEARCH_COMPLEXITY" | grep -Eq "^[1-4]$"; then
  echo "ERROR: Invalid research complexity: $RESEARCH_COMPLEXITY (must be 1-4)" >&2
  exit 1
fi
```

**Customization Points**:
- `DEFAULT_COMPLEXITY`: Set per command based on typical workflow needs (1-4 scale)
- Add additional flags as needed (e.g., `--start-phase`, `--dry-run`)

### 3. State Machine Initialization

**Pattern**: Source libraries in correct order and initialize state machine

```bash
# Part 2: State Machine Initialization

# Detect project directory (bootstrap pattern)
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  # Fallback: search upward for .claude/ directory
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

export CLAUDE_PROJECT_DIR

# Source libraries in correct order
# CRITICAL: state-persistence.sh and workflow-state-machine.sh MUST be sourced first
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/library-version-check.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh"

# Verify library versions (fail-fast if incompatible)
check_library_requirements "$(cat <<'EOF'
workflow-state-machine.sh: ">=2.0.0"
state-persistence.sh: ">=1.5.0"
EOF
)" || exit 1

# Hardcode workflow type (replaces LLM classification)
WORKFLOW_TYPE="research-only"  # Command-specific value
TERMINAL_STATE="research"      # Command-specific value
COMMAND_NAME="research-report" # Command name (for state persistence)

# Initialize state machine with 5 parameters
# Parameters: description, command_name, workflow_type, research_complexity, research_topics_json
sm_init \
  "$WORKFLOW_DESCRIPTION" \
  "$COMMAND_NAME" \
  "$WORKFLOW_TYPE" \
  "$RESEARCH_COMPLEXITY" \
  "{}"  # Empty topics JSON (populated during research)
```

**sm_init() 5-Parameter Signature**:
1. `description`: User-provided workflow description
2. `command_name`: Command identifier (for state persistence)
3. `workflow_type`: Hardcoded workflow type (research-only, research-and-plan, etc.)
4. `research_complexity`: Complexity level (1-4 scale)
5. `research_topics_json`: JSON array of research topics (empty "{}" for auto-detection)

**Customization Points**:
- `WORKFLOW_TYPE`: Set per command (research-only, research-and-plan, research-and-revise, full-implementation, debug-only)
- `TERMINAL_STATE`: Set per workflow type (research, plan, debug, complete)
- `COMMAND_NAME`: Match command file name (without .md extension)

### 4. Phase Implementations

**Pattern**: Execute workflow-specific phases with imperative agent invocation

```bash
# Part 3: Phase Execution

# Phase 1: Research (example)
sm_transition "$STATE_RESEARCH"

# IMPERATIVE AGENT INVOCATION (Standard 11 compliance)
# - Precede with "EXECUTE NOW: USE the Task tool"
# - NO YAML code block wrappers (```yaml prohibited)
# - Reference agent behavioral file explicitly
# - Require completion signal

echo "EXECUTE NOW: USE the Task tool to invoke research-specialist agent"
echo ""
echo "Agent Behavioral Guidelines:"
echo "Read and follow ALL behavioral guidelines from: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md"
echo ""
echo "Completion Signal Required:"
echo "Return: REPORT_CREATED: \${REPORT_PATH}"
echo ""
echo "Research Parameters:"
echo "- Complexity: $RESEARCH_COMPLEXITY"
echo "- Topics: Auto-detect from workflow description"
echo "- Workflow Description: $WORKFLOW_DESCRIPTION"

# FAIL-FAST VERIFICATION (no fallback, exit 1 on failure)
if [ ! -d "$RESEARCH_DIR" ] || [ -z "$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null)" ]; then
  echo "ERROR: Research phase failed to create artifacts" >&2
  echo "DIAGNOSTIC: Expected reports directory: $RESEARCH_DIR" >&2
  exit 1
fi

# Persist completed state (call after every sm_transition)
save_completed_states_to_state()
```

**save_completed_states_to_state() Pattern**:
- Call after every `sm_transition()` to persist state
- Enables cross-bash-block coordination (GitHub Actions pattern)
- Required for checkpoint resume functionality

**Verification Checkpoint Pattern**:
1. Check for expected artifacts (files, directories)
2. Provide diagnostic information (expected paths, error context)
3. Exit with code 1 immediately on failure (NO RETRIES, NO FALLBACKS)

**Customization Points**:
- Add workflow-specific phases (plan, implement, test, debug, document)
- Adjust verification logic per phase (check different artifact types)
- Include phase-specific parameters in agent invocation

### 5. Terminal State Handling

**Pattern**: Transition to terminal state and display summary

```bash
# Part 4: Completion & Cleanup

# Conditional phase execution (workflow-specific)
case "$COMMAND_NAME" in
  research-report)
    # Research-only workflow: terminate after research
    sm_transition "$STATE_COMPLETE"
    echo "=== Research Complete ==="
    echo "Reports: $RESEARCH_DIR"
    exit 0
    ;;
  research-plan)
    # Research-and-plan workflow: continue to plan phase
    sm_transition "$STATE_PLAN"
    # ... plan phase implementation ...
    sm_transition "$STATE_COMPLETE"
    exit 0
    ;;
  build)
    # Full implementation workflow: implement → test → debug/document → complete
    sm_transition "$STATE_IMPLEMENT"
    # ... implementation phases ...
    sm_transition "$STATE_COMPLETE"
    exit 0
    ;;
esac
```

**Customization Points**:
- Add workflow-specific completion logic
- Display relevant summary information (created artifacts, test results, etc.)
- Clean up temporary state files (if not using checkpoint resume)

## Standard 11: Imperative Agent Invocation Patterns

**Requirement**: All agent invocations must use imperative patterns to ensure 100% file creation reliability.

### Imperative Pattern Elements

1. **Explicit Tool Invocation**: "EXECUTE NOW: USE the Task tool"
2. **NO YAML Wrappers**: Prohibit ```yaml code blocks (confuses Claude Code)
3. **Behavioral File Reference**: "Read and follow: .claude/agents/[name].md"
4. **Completion Signal**: "Return: ARTIFACT_CREATED: ${PATH}"

### Example: Research Agent Invocation

```bash
echo "EXECUTE NOW: USE the Task tool to invoke research-specialist agent"
echo ""
echo "YOU MUST:"
echo "1. Read behavioral guidelines: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md"
echo "2. Follow ALL behavioral requirements (Standard 0.5 enforcement)"
echo "3. Return completion signal: REPORT_CREATED: \${REPORT_PATH}"
echo ""
echo "Research Parameters:"
echo "- Complexity: $RESEARCH_COMPLEXITY"
echo "- Topics: Auto-detect from workflow description"
echo "- Workflow Description: $WORKFLOW_DESCRIPTION"
```

### Why Imperative Patterns Work

**Problem**: Without imperative patterns, Claude Code may:
- Describe what to do instead of doing it (60-80% file creation rate)
- Skip agent invocation entirely
- Invoke wrong agent or wrong tool

**Solution**: Imperative patterns enforce:
- Immediate action ("EXECUTE NOW")
- Specific tool usage ("USE the Task tool")
- Behavioral consistency (reference .md file)
- Verification signal (completion signal)

**Result**: 100% file creation reliability (vs 60-80% without patterns)

## Standard 0.5: Agent Behavioral Requirements

**Requirement**: All agent behavioral files (.claude/agents/*.md) must enforce sequential dependencies and mandatory actions.

### Behavioral Pattern Elements

1. **Mandatory Actions**: "YOU MUST [action]" (not "Consider [action]")
2. **Sequential Dependencies**: "STEP 1 REQUIRED BEFORE STEP 2"
3. **Fail-Fast Requirements**: "Exit with code 1 if [condition]"
4. **Completion Signals**: "Return: ARTIFACT_CREATED: ${PATH}"

### Example: Agent Behavioral File Header

```markdown
# Research Specialist Agent

YOU MUST perform these steps in order:

1. REQUIRED: Extract research topics from workflow description
   - If no topics detected, exit with code 1 and diagnostic message
2. REQUIRED: Generate research report for each topic
   - Use Read, Grep, Glob tools (NOT Bash commands)
   - Directory creation: Agents use `ensure_artifact_directory()` at write-time (lazy creation)
   - Commands do NOT pre-create artifact subdirectories (reports/, plans/, debug/)
3. REQUIRED: Return completion signal
   - Format: REPORT_CREATED: ${REPORT_PATH}

STEP 1 REQUIRED BEFORE STEP 2 (fail-fast if skipped)
```

## State Machine Integration Patterns

### sm_init() Invocation

All commands use the same 5-parameter signature:

```bash
sm_init \
  "$WORKFLOW_DESCRIPTION" \
  "$COMMAND_NAME" \
  "$WORKFLOW_TYPE" \
  "$RESEARCH_COMPLEXITY" \
  "$RESEARCH_TOPICS_JSON"
```

### sm_transition() Usage

Call `sm_transition()` when moving to a new state:

```bash
# Example: transition to research state
sm_transition "$STATE_RESEARCH"

# ... execute research phase ...

# Persist completed state
save_completed_states_to_state

# Example: transition to plan state
sm_transition "$STATE_PLAN"
```

### Terminal State Mapping

**Workflow Type → Terminal State**:
- `research-only` → `research`
- `research-and-plan` → `plan`
- `research-and-revise` → `plan`
- `full-implementation` → `complete`
- `debug-only` → `debug`

### State Persistence Pattern

After every `sm_transition()`, call `save_completed_states_to_state()`:

```bash
sm_transition "$STATE_RESEARCH"
save_completed_states_to_state  # Persist state for cross-bash-block coordination
```

This enables:
- Checkpoint resume (pick up where left off)
- Cross-bash-block coordination (GitHub Actions pattern)
- State history tracking (audit trail)

## Fail-Fast Verification Patterns

### Philosophy

**Fail-Fast Approach** (aligned with clean-break philosophy):
- No retry logic
- No fallback mechanisms
- No graceful degradation
- Exit with code 1 immediately on any failure
- Clear diagnostic messages

### Verification Checkpoint Template

```bash
# After agent invocation
if [ ! -d "$EXPECTED_DIR" ] || [ -z "$(find "$EXPECTED_DIR" -name '*.md' 2>/dev/null)" ]; then
  echo "ERROR: Phase failed to create expected artifacts" >&2
  echo "DIAGNOSTIC: Expected directory: $EXPECTED_DIR" >&2
  echo "DIAGNOSTIC: Agent invocation may have failed" >&2
  echo "SOLUTION: Check agent behavioral file and logs" >&2
  exit 1
fi
```

### Common Verification Patterns

**File Existence**:
```bash
[ -f "$FILE_PATH" ] || { echo "ERROR: Expected file not created: $FILE_PATH" >&2; exit 1; }
```

**Directory Non-Empty**:
```bash
[ -n "$(ls -A "$DIR_PATH" 2>/dev/null)" ] || { echo "ERROR: Directory empty: $DIR_PATH" >&2; exit 1; }
```

**Specific File Pattern**:
```bash
[ -n "$(find "$DIR_PATH" -name '*.md' 2>/dev/null)" ] || { echo "ERROR: No .md files found in $DIR_PATH" >&2; exit 1; }
```

**JSON Structure Validation**:
```bash
jq -e '.topics | length > 0' "$METADATA_FILE" >/dev/null 2>&1 || { echo "ERROR: Invalid metadata structure" >&2; exit 1; }
```

## Hierarchical Supervision Threshold

**Unified Threshold**: Complexity ≥8 across ALL phases (research, planning, implementation)

### Implementation Pattern

```bash
# Research phase with hierarchical supervision
if [ "$RESEARCH_COMPLEXITY" -ge 4 ]; then
  # Use hierarchical supervision (research-sub-supervisor)
  echo "EXECUTE NOW: USE the Task tool to invoke research-sub-supervisor agent"
  echo "Hierarchical mode: research-sub-supervisor coordinates $RESEARCH_COMPLEXITY sub-agents"
else
  # Use flat coordination (research-specialist)
  echo "EXECUTE NOW: USE the Task tool to invoke research-specialist agent"
  echo "Flat mode: research-specialist handles all topics directly"
fi
```

**Rationale**: Unified threshold (≥8) eliminates user-facing inconsistency and aligns with existing complexity scoring patterns.

## Example Commands

### Example 1: Research-Only Command (/research)

**Workflow Type**: `research-only`
**Terminal State**: `research`
**Phases**: Research → Complete
**Complexity**: 150-200 lines

See: `.claude/commands/research.md` (created in Phase 2)

### Example 2: Research-and-Plan Command (/plan)

**Workflow Type**: `research-and-plan`
**Terminal State**: `plan`
**Phases**: Research → Plan → Complete
**Complexity**: 150-200 lines

See: `.claude/commands/plan.md` (created in Phase 3)

### Example 3: Build Command (/build)

**Workflow Type**: `full-implementation`
**Terminal State**: `complete`
**Phases**: Implement → Test → Debug/Document → Complete
**Complexity**: 150-200 lines

See: `.claude/commands/build.md` (created in Phase 4)

## Anti-Patterns

### ❌ Template-Based Generation

**Problem**: Creating a 600-800 line template file with substitution markers.

**Why Bad**:
- Maintenance burden (5 nearly-identical files)
- Breaking changes impact all commands simultaneously
- Violates library-based reuse pattern

**Solution**: Create commands directly (150-200 lines each), use library functions at runtime.

### ❌ Fallback Mechanisms

**Problem**: Trying to gracefully handle failures with retry logic or fallback creation.

**Why Bad**:
- Increases command complexity by 60-70%
- Hides underlying issues (masks agent failures)
- Contradicts fail-fast philosophy

**Solution**: Exit with code 1 immediately on any failure with clear diagnostics.

### ❌ Inline Behavioral Duplication

**Problem**: Duplicating agent behavioral guidelines in command files (100+ lines of inline instructions).

**Why Bad**:
- Leads to inconsistency (107-255 lines of duplication in legacy commands)
- Harder to maintain (update behavioral patterns in multiple places)
- Increases context size (85-90% context reduction lost)

**Solution**: Reference agent behavioral file (`.claude/agents/[name].md`) and use imperative patterns.

### ❌ Implicit Phase Tracking

**Problem**: Using numeric phase variables without state machine integration.

**Why Bad**:
- No transition validation (can skip phases)
- No state history tracking (can't audit workflow)
- Hard to debug (no clear state representation)

**Solution**: Use `sm_transition()` for all phase changes with validated transitions.

## Testing Patterns

### Unit Testing (Per Command)

```bash
# Test command syntax validation
test -f .claude/commands/research.md || exit 1

# Test YAML frontmatter parsing
grep -q "allowed-tools: Task" .claude/commands/research.md || exit 1

# Test state machine integration
grep -q "sm_init" .claude/commands/research.md || exit 1
grep -q "sm_transition" .claude/commands/research.md || exit 1
```

### Integration Testing (End-to-End)

```bash
# Test command execution
/research "authentication patterns in codebase"

# Verify outputs (FAIL-FAST: exit 1 if any check fails)
test -d .claude/specs/*/reports/ || exit 1  # Research reports created
test ! -f .claude/specs/*/plans/*.md  # No plan file created (expected)

# Verify state machine
grep "TERMINAL_STATE=research" ~/.claude/tmp/workflow_*.sh || exit 1
grep "WORKFLOW_TYPE=research-only" ~/.claude/tmp/workflow_*.sh || exit 1
```

### Feature Preservation Testing

```bash
# Test delegation rate (target: >90%)
# Test context usage (target: <300 tokens per agent)
# Test file creation reliability (target: 100%)
# Test state machine transitions (all valid)
```

See: [Phase 6 Expansion](../../specs/743_coordinate_command_working_reasonably_well_more/artifacts/expansion_phase_6.md) for complete testing framework.

## Reference Documentation

### Related Guides
- [State Machine Architecture](.claude/docs/architecture/state-based-orchestration-overview.md)
- [Command Standards](.claude/docs/reference/standards/command-reference.md)
- [Agent Development Guide](.claude/docs/guides/development/agent-development/agent-development-fundamentals.md)
- [Testing Protocols](.claude/docs/reference/standards/testing-protocols.md)

### Existing Commands (Examples)
- `/coordinate` - Comprehensive orchestrator with all features
- `/plan` - Planning command with state machine integration
- `/implement` - Implementation command with checkpoint resume

### Library Reference
- `workflow-state-machine.sh` v2.0.0 - State machine functions
- `state-persistence.sh` v1.5.0 - State persistence utilities
- `library-version-check.sh` v1.0.0 - Version compatibility verification
