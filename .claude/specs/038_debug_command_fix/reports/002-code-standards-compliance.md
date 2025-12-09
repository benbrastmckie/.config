# Research Report: Code Standards and Infrastructure Compliance

## Executive Summary

This report documents the code standards, infrastructure requirements, and patterns that govern agent task invocations, behavioral file directives, and hard barrier validation in the .claude/ system. The research focuses on three critical areas: Task tool invocation patterns, behavioral file integration requirements, and hard barrier verification enforcement.

**Key Findings**:
1. **Task Tool Invocation Pattern** - Mandatory imperative directives with explicit "EXECUTE NOW: USE the Task tool" phrasing required before all Task blocks
2. **Behavioral File Integration** - Agent behavioral guidelines loaded via runtime injection with "Read and follow ALL instructions in:" pattern
3. **Hard Barrier Pattern** - Three-block structure (Setup/Execute/Verify) enforces mandatory delegation with fail-fast verification

## Findings

### 1. Task Tool Invocation Patterns

**Source**: `/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md` (Lines 99-294)

#### Required Pattern

All Task tool invocations MUST use imperative directive pattern with NO code block wrapper:

```markdown
**EXECUTE NOW**: USE the Task tool to invoke the [AGENT_NAME] agent.

Task {
  subagent_type: "general-purpose"
  description: "[Brief description] with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/[agent-file].md

    **Workflow-Specific Context**:
    - [Context Variable 1]: ${VAR1}
    - [Context Variable 2]: ${VAR2}
    - Output Path: ${OUTPUT_PATH}

    Execute [action] per behavioral guidelines.
    Return: [SIGNAL_NAME]: ${OUTPUT_PATH}
  "
}
```

#### Key Requirements

1. **Imperative Instruction**: "**EXECUTE NOW**: USE the Task tool..." phrase MUST precede Task block
2. **No Code Block Wrapper**: Remove ` ```yaml ` fences around Task block
3. **Inline Prompt**: Variables interpolated directly in prompt (no external file references)
4. **Completion Signal**: Agent must return explicit signal (e.g., `REPORT_CREATED: ${PATH}`)
5. **No Documentation Context**: Task blocks treated as executable code, not documentation examples

#### Prohibited Anti-Patterns

**Anti-Pattern 1: Naked Task Block**
```markdown
# WRONG: No imperative directive
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "..."
}
```
**Problem**: Claude interprets as documentation, not executable instruction.

**Anti-Pattern 2: Instructional Text Without Task Invocation**
```markdown
# WRONG: Describes action but doesn't perform it
Use the Task tool to invoke the research-specialist agent with the calculated paths.
```
**Problem**: Text describes what SHOULD happen but doesn't invoke the Task tool.

**Anti-Pattern 3: Incomplete EXECUTE NOW Directive**
```markdown
# WRONG: Missing "USE the Task tool" phrase
**EXECUTE NOW**: Invoke the research-specialist agent.

Task { ... }
```
**Problem**: Directive not explicit enough - must include "USE the Task tool" phrase.

**Anti-Pattern 4: Conditional Prefix Without EXECUTE Keyword**
```markdown
# WRONG: Reads as descriptive documentation
**If CONDITION**: USE the Task tool to invoke agent.

Task { ... }
```
**Problem**: Conditional prefix lacks explicit "EXECUTE" keyword that signals mandatory action.

**Correct Alternative**:
```markdown
**EXECUTE IF CONDITION**: USE the Task tool to invoke agent.

Task { ... }
```

#### Edge Case Patterns

**Iteration Loop Invocations**:
- Each invocation point (initial + loop) requires separate imperative directive
- Same agent invoked multiple times = multiple directives needed

**Conditional Invocations**:
- Use "**EXECUTE IF CONDITION**:" prefix OR
- Separate bash conditional check before standard "**EXECUTE NOW**:" directive

**Multiple Agents in Sequence**:
- Each agent requires its own imperative directive
- Don't use single directive for multiple Task blocks

#### Model Specification

Task invocations can specify model tier explicitly:

```markdown
Task {
  subagent_type: "general-purpose"
  model: "opus" | "sonnet" | "haiku"
  description: "..."
  prompt: "..."
}
```

**Model Selection Guidelines**:
- `"opus"`: Complex reasoning, proof search, sophisticated delegation logic
- `"sonnet"`: Balanced orchestration, standard implementation tasks
- `"haiku"`: Deterministic coordination, mechanical processing

**Precedence Order**:
1. Task invocation `model:` field (highest priority)
2. Agent frontmatter `model:` field (fallback)
3. System default model (last resort)

#### Validation

Automated linter enforces Task invocation patterns:

```bash
bash .claude/scripts/lint-task-invocation-pattern.sh <command-file>

# Detects:
# - ERROR: Task { without EXECUTE NOW directive
# - ERROR: Instructional text without actual Task invocation
# - ERROR: Incomplete EXECUTE NOW directive (missing 'Task tool')
```

### 2. Behavioral File Integration Requirements

**Source**: `/home/benjamin/.config/.claude/docs/reference/standards/agent-behavioral-guidelines.md`

#### Runtime Behavioral Injection Pattern

Agents receive behavior through runtime injection in Task prompts rather than hardcoded instructions:

```markdown
Task {
  subagent_type: "general-purpose"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Topic: ${RESEARCH_TOPIC}
    - Output Path: ${REPORT_PATH}

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

#### Key Principles

1. **Single Source of Truth**: Behavioral guidelines exist in ONE location only (`.claude/agents/*.md`)
2. **Runtime Loading**: Commands reference behavioral files via "Read and follow ALL instructions in:" pattern
3. **Context Injection**: Workflow-specific context passed as variables in prompt
4. **Completion Signals**: Agents must return explicit completion signals for verification

#### Behavioral File Structure

Agents use markdown format with distinct sections:

```markdown
# Agent Name

## Purpose
Brief description of agent role

## STEP 1: [Action Name]
Detailed step-by-step instructions

## STEP 2: [Action Name]
Next action with behavioral constraints

## Output Format
Expected return signal format
```

#### Directory Creation Policy

**Requirement**: Agents MUST use lazy directory creation - creating directories only immediately before writing files.

**Correct Pattern**:
```bash
REPORT_PATH="${REPORTS_DIR}/001_research_report.md"

# Immediately before Write tool
ensure_artifact_directory "$REPORT_PATH" || {
  echo "ERROR: Failed to create parent directory for report" >&2
  exit 1
}

# Write tool creates file - directory guaranteed to exist
```

**Anti-Pattern: Eager Directory Creation**:
```bash
# WRONG: Creating directories at agent startup
mkdir -p "$REPORTS_DIR"
mkdir -p "$DEBUG_DIR"
mkdir -p "$SUMMARIES_DIR"

# If agent fails before writing files, empty directories persist
```

**Impact**: Over 400-500 empty directories accumulated before this pattern was remediated.

#### State Persistence Policy

**Requirement**: Agents with `allowed-tools: None` MUST NOT attempt to persist state directly. They MUST use output-based patterns.

**Output-Based Pattern**:
```yaml
# Agent frontmatter
allowed-tools: None
```

Agent returns structured data for parent command to persist:
```
CLASSIFICATION_COMPLETE: {"type": "feature", "complexity": 3}
```

**Why Direct Persistence Fails**:
1. **No bash execution**: `allowed-tools: None` agents cannot execute bash commands
2. **Subprocess isolation**: Task tool creates isolated subprocess with no parent context
3. **No shared memory**: Agent cannot access parent's STATE_FILE variable

#### Error Return Protocol

**Requirement**: Agents MUST return structured error signals for parent command parsing and centralized logging.

**Error Signal Format**:
```markdown
ERROR_CONTEXT: {
  "error_type": "validation_error",
  "message": "Required file not found",
  "details": {"expected": "/path/to/file.md"}
}

TASK_ERROR: validation_error - Required file not found: /path/to/file.md
```

**Standardized Error Types**:
- `state_error` - Workflow state persistence issues
- `validation_error` - Input validation failures
- `agent_error` - Subagent execution failures
- `parse_error` - Output parsing failures
- `file_error` - File system operations failures
- `timeout_error` - Operation timeout errors
- `execution_error` - General execution failures
- `dependency_error` - Missing or invalid dependencies

**Parent Command Integration**:
```bash
AGENT_OUTPUT="$(...)"  # Capture task output

# Parse and log any errors
parse_subagent_error "$AGENT_OUTPUT" "research-specialist"
```

#### Tool Access Guidelines

**Classification Agents**:
```yaml
allowed-tools: None
model: haiku-4.5
timeout: 30000ms
```
- Fast, cheap classification/routing
- Return structured JSON or signals
- No file access, no execution

**Analysis Agents**:
```yaml
allowed-tools: Read, Grep, Glob
model: sonnet-4.5
timeout: 120000ms
```
- Read codebase, search patterns
- Return analysis results
- No file modification

**Implementation Agents**:
```yaml
allowed-tools: Read, Write, Edit, Bash
model: sonnet-4.5
timeout: 300000ms
```
- Full file modification capabilities
- Can execute bash commands
- Can create commits

### 3. Hard Barrier Subagent Delegation Pattern

**Source**: `/home/benjamin/.config/.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md`

#### Problem Statement

Orchestrator commands using pseudo-code Task invocation format allow Claude to bypass delegation and perform work directly when they have permissive tool access (Read, Edit, Write, Grep, Glob).

**Impact**:
- 40-60% higher context usage in orchestrator
- No reusability of logic across workflows
- Architectural inconsistency (unpredictable delegation)
- Difficult to test (inline work cannot be isolated)

#### Solution: Setup → Execute → Verify Pattern

Split each delegation phase into **3 sub-blocks**:

```
Block N: Phase Name
├── Block Na: Setup
│   ├── State transition (fail-fast gate)
│   ├── Variable persistence (paths, metadata)
│   └── Checkpoint reporting
├── Block Nb: Execute [CRITICAL BARRIER]
│   └── Task invocation (MANDATORY)
└── Block Nc: Verify
    ├── Artifact existence check
    ├── Fail-fast on missing outputs
    └── Error logging with recovery hints
```

**Key Principle**: Bash blocks between Task invocations make bypass impossible. Claude cannot skip a bash verification block.

#### Implementation Template: Research Phase Delegation

**Block Na: Setup**
```bash
set +H  # Disable history expansion

# Calculate report number (001, 002, 003...)
EXISTING_REPORTS=$(find "$RESEARCH_DIR" -name '[0-9][0-9][0-9]-*.md' 2>/dev/null | wc -l)
REPORT_NUMBER=$(printf "%03d" $((EXISTING_REPORTS + 1)))

# Generate report slug from workflow description
REPORT_SLUG=$(echo "${WORKFLOW_DESCRIPTION:-research}" | head -c 40 | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')

# Construct absolute report path
REPORT_PATH="${RESEARCH_DIR}/${REPORT_NUMBER}-${REPORT_SLUG}.md"

# Validate path is absolute
if [[ ! "$REPORT_PATH" =~ ^/ ]]; then
  log_command_error "validation_error" "Calculated REPORT_PATH is not absolute" "$REPORT_PATH"
  exit 1
fi

# Persist for Block Nc validation
append_workflow_state "REPORT_PATH" "$REPORT_PATH"

echo "Report Path: $REPORT_PATH"
```

**Block Nb: Execute**
```markdown
**HARD BARRIER**: This block MUST invoke research-specialist via Task tool.
Block Nc will FAIL if report not created at the pre-calculated path.

**EXECUTE NOW**: Invoke research-specialist subagent

Task {
  subagent_type: "general-purpose"
  description: "Research ${WORKFLOW_DESCRIPTION} with mandatory file creation"
  prompt: |
    Read and follow ALL instructions in: .claude/agents/research-specialist.md

    **Input Contract (Hard Barrier Pattern)**:
    - Report Path: ${REPORT_PATH}
    - Output Directory: ${RESEARCH_DIR}
    - Research Topic: ${WORKFLOW_DESCRIPTION}

    **CRITICAL**: You MUST create the report file at the EXACT path specified above.
    The orchestrator has pre-calculated this path and will validate it exists.

    Return completion signal: REPORT_CREATED: ${REPORT_PATH}
}
```

**Block Nc: Verify**
```bash
set +H

# Restore REPORT_PATH from state
source "$STATE_FILE"

echo "Expected report path: $REPORT_PATH"

# HARD BARRIER: Report file MUST exist
if [ ! -f "$REPORT_PATH" ]; then
  log_command_error "agent_error" \
    "research-specialist failed to create report file" \
    "Expected: $REPORT_PATH"
  echo "ERROR: HARD BARRIER FAILED - Report file not found"
  exit 1
fi

# Validate report is not empty or too small
REPORT_SIZE=$(wc -c < "$REPORT_PATH" 2>/dev/null || echo 0)
if [ "$REPORT_SIZE" -lt 100 ]; then
  log_command_error "validation_error" \
    "Report file too small ($REPORT_SIZE bytes)" \
    "Agent may have failed during write"
  exit 1
fi

# Validate report contains required sections
if ! grep -q "## Findings" "$REPORT_PATH" 2>/dev/null; then
  echo "WARNING: Report may be incomplete - missing Findings section"
fi

echo "Agent output validated: Report file exists ($REPORT_SIZE bytes)"
echo "Hard barrier passed - proceeding to Block 2"
```

#### Pattern Requirements

1. **CRITICAL BARRIER Label**: All Execute blocks must include directive stating verification will fail if artifact not created

2. **Fail-Fast Verification**: All Verify blocks must:
   - Check for expected artifacts (directories, files, counts)
   - Exit with code 1 on verification failure
   - Log errors via `log_command_error`
   - Provide recovery instructions

3. **State Transitions as Gates**: All Setup blocks must include state transition with verification:
   ```bash
   sm_transition "STATE_NAME" || {
     log_command_error "state_error" \
       "Failed to transition to STATE_NAME" \
       "sm_transition returned non-zero exit code"
     exit 1
   }
   ```

4. **Variable Persistence**: All Setup blocks must persist variables needed by Execute and Verify blocks via `append_workflow_state`

5. **Checkpoint Reporting**: All blocks should report checkpoints for debugging:
   ```bash
   echo "[CHECKPOINT] [BLOCK_NAME] complete - [STATUS_SUMMARY]"
   ```

6. **Error Logging Integration**: All verification failures must log errors before exit

#### Enhanced Diagnostics

When verification blocks detect missing artifacts, enhanced diagnostics distinguish between:
1. **File at wrong location** - Agent created artifact but in unexpected directory
2. **File not created** - Agent failed to create artifact at all
3. **Silent failure** - Agent executed but produced no output

**Diagnostic Pattern**:
```bash
if [[ ! -f "$expected_artifact_path" ]]; then
  echo "❌ Hard barrier verification failed: Artifact file not found"
  echo "Expected: $expected_artifact_path"

  # Search for file in parent and topic directories
  local artifact_name=$(basename "$expected_artifact_path")
  local topic_dir=$(dirname "$(dirname "$expected_artifact_path")")
  local found_files=$(find "$topic_dir" -name "$artifact_name" 2>/dev/null || true)

  if [[ -n "$found_files" ]]; then
    echo "📍 Found at alternate location(s):"
    echo "$found_files" | while read -r file; do
      echo "  - $file"
    done
    log_command_error "agent_error" "Agent created file at wrong location" \
      "expected=$expected_artifact_path, found=$found_files"
  else
    echo "❌ Not found anywhere in topic directory: $topic_dir"
    log_command_error "agent_error" "Agent failed to create artifact file" \
      "expected=$expected_artifact_path, topic_dir=$topic_dir"
  fi

  exit 1
fi
```

#### Anti-Patterns

**Don't: Merge Bash + Task in Single Block**
```markdown
# WRONG: Bypass possible
## Block 4: Research Phase

```bash
RESEARCH_DIR="/path/to/reports"
mkdir -p "$RESEARCH_DIR"
```

**EXECUTE NOW**: Invoke research-specialist

Task { ... }

```bash
# Verification here
REPORT_COUNT=$(find "$RESEARCH_DIR" ...)
```
```

**Don't: Soft Verification (Warnings Only)**
```bash
# WRONG: Continues execution despite failure
if [[ ! -f "$EXPECTED_FILE" ]]; then
  echo "WARNING: File not found, continuing anyway"
fi
```

**Don't: Skip Error Logging**
```bash
# WRONG: No centralized error logging
if [[ ! -f "$FILE" ]]; then
  echo "ERROR: File missing"
  exit 1
fi
```

#### When to Use Hard Barrier Pattern

Apply hard barrier pattern when:
1. **Orchestrator has permissive tool access**: Read, Edit, Write, Grep, Glob
2. **Subagent work must be isolated**: For reusability across workflows
3. **Delegation enforcement is critical**: Architecture requires consistent patterns
4. **Error recovery needs explicit checkpoints**: For debugging and resume

**Commands Requiring Hard Barriers**:
- `/implement` (implementer-coordinator)
- `/collapse` (plan-architect)
- `/debug` (debug-analyst, plan-architect)
- `/errors` (errors-analyst)
- `/expand` (plan-architect)
- `/plan` (research-specialist, plan-architect)
- `/repair` (repair-analyst, plan-architect)
- `/research` (research-specialist)
- `/revise` (research-specialist, plan-architect)
- `/todo` (todo-analyzer)

#### Benefits

**Architectural**:
- 100% delegation success (bypass structurally impossible)
- Modular architecture with clear separation of roles
- Reusable components callable from multiple commands
- Predictable workflow patterns

**Operational**:
- 40-60% reduction in orchestrator token usage
- Error recovery via explicit checkpoints
- Checkpoint markers trace execution flow
- Clear block structure for maintenance

**Quality**:
- Testable blocks (independent testing possible)
- Observable via checkpoint reporting and error logging
- Recoverable via fail-fast with recovery instructions
- Standards-compliant (enforces error logging, state transitions)

### 4. Hierarchical Agent Architecture Integration

**Source**: `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md`

#### Core Principles

1. **Hierarchical Supervision**: Agents organized in hierarchy where supervisors coordinate worker agents
2. **Behavioral Injection**: Agents receive behavior through runtime injection rather than hardcoded instructions
3. **Metadata-Only Context Passing**: Between hierarchy levels, pass metadata summaries rather than full content (95%+ context reduction)
4. **Single Source of Truth**: Agent behavioral guidelines exist in ONE location only

#### Agent Roles

| Role | Purpose | Tools | Invoked By |
|------|---------|-------|------------|
| **Orchestrator** | Coordinates workflow phases | All | User command |
| **Supervisor** | Coordinates parallel workers | Task | Orchestrator |
| **Specialist** | Executes specific tasks | Domain-specific | Supervisor |

#### Communication Flow

1. Command → Orchestrator: User invokes slash command
2. Orchestrator → Supervisor: Pre-calculates paths, invokes supervisor
3. Supervisor → Workers: Invokes parallel worker agents
4. Workers → Supervisor: Return metadata (path + summary)
5. Supervisor → Orchestrator: Return aggregated metadata
6. Orchestrator → User: Display results

#### Context Efficiency

Traditional approach: 4 Workers × 2,500 tokens = 10,000 tokens to orchestrator

Hierarchical approach:
- 4 Workers × 2,500 tokens → Supervisor
- Supervisor extracts 110 tokens/worker = 440 tokens to orchestrator
- **Reduction: 95.6%**

### 5. Bash Block Execution Model

**Source**: `/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md` (Lines 34-90)

#### Mandatory Three-Tier Sourcing Pattern

All bash blocks in `.claude/commands/` MUST follow the three-tier sourcing pattern:

```bash
# 1. Bootstrap: Detect project directory
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
    current_dir="$(dirname "$current_dir")"
  done
fi
export CLAUDE_PROJECT_DIR

# 2. Source Critical Libraries (Tier 1 - FAIL-FAST REQUIRED)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2; exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2; exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2; exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" 2>/dev/null || {
  echo "ERROR: Failed to source validation-utils.sh" >&2; exit 1
}

# 3. Optional Libraries (Tier 2/3 - graceful degradation allowed)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/summary-formatting.sh" 2>/dev/null || true
```

#### Three-Tier Library Classification

| Tier | Libraries | Error Handling | Rationale |
|------|-----------|----------------|-----------|
| **Tier 1: Critical Foundation** | state-persistence.sh, workflow-state-machine.sh, error-handling.sh, validation-utils.sh | Fail-fast required | Core state management and validation; failure causes exit 127 later or data integrity issues |
| **Tier 2: Workflow Support** | workflow-initialization.sh, checkpoint-utils.sh, unified-logger.sh | Graceful degradation | Non-critical; commands can proceed without |
| **Tier 3: Command-Specific** | checkbox-utils.sh, summary-formatting.sh | Optional | Feature-specific; missing causes partial functionality |

#### Why This Pattern is Mandatory

Each bash block in Claude Code runs in a **new subprocess**. Variables and functions from previous blocks are NOT available. Without re-sourcing libraries, function calls fail with exit code 127 ("command not found").

#### Enforcement

- **Linter**: `.claude/scripts/lint/check-library-sourcing.sh` validates all commands
- **Pre-commit**: Violations block commits (use `--no-verify` only with documented justification)
- **CI**: Linter runs in validation pipeline before tests

### 6. Error Logging Requirements

**Source**: `/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md` (Lines 92-163)

#### Mandatory Pattern

All commands MUST integrate centralized error logging:

```bash
# 1. Source error-handling library (Tier 1 - fail-fast required)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}

# 2. Initialize error log
ensure_error_log_exists

# 3. Set workflow metadata
COMMAND_NAME="/command"
WORKFLOW_ID="command_$(date +%s)"
USER_ARGS="$*"

# 4. Setup bash error trap (catches unlogged errors automatically)
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# 5. Log errors before exit (for validation failures)
if [ -z "$REQUIRED_ARG" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" "Required argument missing" "argument_validation" \
    "$(jq -n --arg provided "$*" '{provided_args: $provided}')"
  echo "ERROR: Required argument missing" >&2
  exit 1
fi
```

#### Error Type Selection Guide

| Error Type | When to Use | Example |
|------------|-------------|---------|
| `validation_error` | Invalid user input (arguments, flags) | Missing required arg, invalid flag |
| `file_error` | File I/O failures (missing, unreadable) | File not found, permission denied |
| `state_error` | State management failures (missing state, restoration) | State file missing, variable not restored |
| `agent_error` | Subagent invocation failures | Agent timeout, agent returned error signal |
| `parse_error` | Output parsing failures | Invalid JSON, unexpected format |
| `execution_error` | General execution failures | Command not found, library function failed |
| `initialization_error` | Early initialization failures (pre-trap) | Error before error-handling.sh loaded |

#### Error Logging Coverage Target

80%+ of error exit points MUST call `log_command_error` before `exit 1`.

#### Bash Error Trap Automatic Coverage

The `setup_bash_error_trap` function automatically logs:
- Command failures (exit code 127, "command not found")
- Unbound variable errors (`set -u` violations)
- All bash-level errors not explicitly logged

## Recommendations

### For /debug Command Fix

1. **Task Invocation Pattern**:
   - Verify all Task blocks have "**EXECUTE NOW**: USE the Task tool..." directive
   - Remove any code block wrappers (` ```yaml `) around Task blocks
   - Ensure prompts use inline behavioral file injection: "Read and follow ALL instructions in: agent.md"

2. **Hard Barrier Pattern**:
   - Split agent delegation phases into Setup/Execute/Verify blocks (Na/Nb/Nc)
   - Add CRITICAL BARRIER labels to Execute blocks
   - Implement fail-fast verification with error logging in Verify blocks
   - Pre-calculate artifact paths in Setup blocks before agent invocation

3. **Error Logging Integration**:
   - Ensure all bash blocks source error-handling.sh with fail-fast
   - Set COMMAND_NAME, WORKFLOW_ID, USER_ARGS metadata
   - Setup bash error trap via `setup_bash_error_trap`
   - Log all validation failures via `log_command_error` before exit

4. **Behavioral File Compliance**:
   - Verify agent behavioral files use lazy directory creation (call `ensure_artifact_directory` immediately before Write)
   - Ensure agents with `allowed-tools: None` use output-based pattern (no direct state persistence)
   - Validate agents return structured error signals using standardized error types

5. **Library Sourcing**:
   - Follow three-tier sourcing pattern in all bash blocks
   - Tier 1 libraries (state-persistence.sh, workflow-state-machine.sh, error-handling.sh, validation-utils.sh) require fail-fast handlers
   - Use graceful degradation (|| true) for Tier 2/3 libraries only

### General Standards Compliance

1. **Validation Before Deployment**:
   ```bash
   # Validate Task invocation patterns
   bash .claude/scripts/lint-task-invocation-pattern.sh .claude/commands/debug.md

   # Validate library sourcing
   bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/debug.md

   # Validate hard barrier compliance
   bash .claude/scripts/validate-hard-barrier-compliance.sh --command debug

   # Validate agent behavioral files
   bash .claude/scripts/validate-agent-behavioral-file.sh .claude/agents/debug-analyst.md
   ```

2. **Pre-Commit Integration**: All validators run automatically on staged `.claude/` files via pre-commit hooks

3. **Error Logging Coverage**: Target 80%+ coverage for all error exit points with explicit `log_command_error` calls

4. **Documentation**: Update command guide files in `.claude/docs/guides/commands/` with implementation details, troubleshooting, and examples

## Cross-References

- [Command Authoring Standards](../../../.claude/docs/reference/standards/command-authoring.md) - Complete Task invocation patterns and requirements
- [Agent Behavioral Guidelines](../../../.claude/docs/reference/standards/agent-behavioral-guidelines.md) - Agent-specific constraints and policies
- [Hard Barrier Subagent Delegation Pattern](../../../.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md) - Complete pattern documentation with examples
- [Hierarchical Agents Overview](../../../.claude/docs/concepts/hierarchical-agents-overview.md) - Multi-agent coordination architecture
- [Code Standards](../../../.claude/docs/reference/standards/code-standards.md) - General code standards and bash library sourcing requirements
- [Enforcement Mechanisms](../../../.claude/docs/reference/standards/enforcement-mechanisms.md) - Validation tools and pre-commit integration

## Metadata

- **Research Date**: 2025-12-09
- **Research Topic**: Code Standards and Infrastructure Compliance
- **Sources Analyzed**: 5 documentation files (command-authoring.md, agent-behavioral-guidelines.md, hard-barrier-subagent-delegation.md, hierarchical-agents-overview.md, code-standards.md)
- **Key Patterns Documented**: Task tool invocation, behavioral file integration, hard barrier verification, three-tier library sourcing, error logging integration
- **Validation Tools Identified**: lint-task-invocation-pattern.sh, check-library-sourcing.sh, validate-hard-barrier-compliance.sh, validate-agent-behavioral-file.sh
