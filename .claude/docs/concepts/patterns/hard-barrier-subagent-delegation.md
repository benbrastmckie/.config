# Hard Barrier Subagent Delegation Pattern

## Overview

The **Hard Barrier Pattern** enforces mandatory subagent delegation in orchestrator commands by using bash verification blocks as context barriers that prevent bypass. This pattern solves the architectural problem of orchestrators with permissive tool access performing subagent work directly instead of delegating via the Task tool.

**Pattern Type**: Architectural constraint
**Applies To**: Orchestrator commands (/ revise, /build, /expand, /collapse, /errors, /research, /debug, /repair)
**Enforcement**: Structural (bash blocks make bypass impossible)

---

## Problem Statement

### Observed Behavior

Orchestrator commands using pseudo-code Task invocation format (`Task { ... }`) allow Claude to interpret invocations as guidance rather than mandatory instructions. When orchestrators have permissive `allowed-tools` (Read, Edit, Write, Grep, Glob), they can bypass Task invocation and perform work directly.

**Impact**:
- **40-60% higher context usage** in orchestrator (performing subagent work inline)
- **No reusability** of logic across workflows
- **Architectural inconsistency** (unpredictable delegation)
- **Difficult to test** (inline work cannot be isolated)

**Root Causes**:
1. Pseudo-code format allows bypass
2. Permissive tool access enables direct work execution
3. No verification blocks enforce delegation
4. Lack of structural barriers between phases

### Example of Bypass

**Intended Flow**:
```
Orchestrator → Task(research-specialist) → Verification
```

**Actual Bypass**:
```
Orchestrator → [Uses Read/Grep directly to research] → Continues
              ↑ Task invocation skipped
```

---

## Solution: Setup → Execute → Verify Pattern

### Pattern Structure

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

### Key Principle

**Bash blocks between Task invocations make bypass impossible.** Claude cannot skip a bash verification block - it must execute to see the next prompt block.

---

## Implementation Templates

### Template 1: Research Phase Delegation (with Path Pre-Calculation)

The `/research` command demonstrates the full hard barrier pattern with path pre-calculation:

```markdown
## Block 1d: Report Path Pre-Calculation

```bash
set +H  # Disable history expansion

# Calculate report number (001, 002, 003...)
EXISTING_REPORTS=$(find "$RESEARCH_DIR" -name '[0-9][0-9][0-9]-*.md' 2>/dev/null | wc -l)
REPORT_NUMBER=$(printf "%03d" $((EXISTING_REPORTS + 1)))

# Generate report slug from workflow description (max 40 chars, kebab-case)
REPORT_SLUG=$(echo "${WORKFLOW_DESCRIPTION:-research}" | head -c 40 | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')

# Construct absolute report path
REPORT_PATH="${RESEARCH_DIR}/${REPORT_NUMBER}-${REPORT_SLUG}.md"

# Validate path is absolute
if [[ ! "$REPORT_PATH" =~ ^/ ]]; then
  log_command_error "validation_error" "Calculated REPORT_PATH is not absolute" "$REPORT_PATH"
  exit 1
fi

# Persist for Block 1e validation
append_workflow_state "REPORT_PATH" "$REPORT_PATH"

echo "Report Path: $REPORT_PATH"
```

## Block 1d-exec: Research Specialist Invocation

**HARD BARRIER**: This block MUST invoke research-specialist via Task tool.
Block 1e will FAIL if report not created at the pre-calculated path.

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

## Block 1e: Agent Output Validation (Hard Barrier)

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
```

**Key Improvements from Pre-Calculation Pattern**:
1. **Path is Known Before Agent Runs**: The orchestrator calculates `REPORT_PATH` before invoking the subagent
2. **Explicit Contract**: The Task prompt passes the exact path as a contract requirement
3. **No Guessing**: Block 1e validates the exact pre-calculated path (not searching for files)
4. **Fail-Fast**: Missing file means agent failed - no fallback to manual search

### Template 2: Plan Revision Delegation

```markdown
## Block 5a: Plan Revision Setup

```bash
set +H
set -e

# Source libraries
source "$CLAUDE_LIB/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Cannot load workflow-state-machine.sh" >&2
  exit 1
}
source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling.sh" >&2
  exit 1
}

# Create backup BEFORE subagent invocation
BACKUP_PATH="${PLAN_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$PLAN_PATH" "$BACKUP_PATH"

# Verify backup created successfully
if [[ ! -f "$BACKUP_PATH" ]] || [[ ! -s "$BACKUP_PATH" ]]; then
  log_command_error "file_error" \
    "Backup creation failed: $BACKUP_PATH" \
    "File missing or empty after cp command"
  exit 1
fi

# State transition blocks progression
sm_transition "PLAN" || {
  log_command_error "state_error" \
    "Failed to transition to PLAN state" \
    "sm_transition returned non-zero exit code"
  exit 1
}

# Persist backup path
append_workflow_state "BACKUP_PATH" "$BACKUP_PATH"

# Checkpoint reporting
echo "[CHECKPOINT] Backup created at $BACKUP_PATH - ready for plan-architect"
```

## Block 5b: Plan Revision Execution

**CRITICAL BARRIER**: This block MUST invoke plan-architect via Task tool.
Verification block (5c) will FAIL if plan not modified.

**EXECUTE NOW**: Invoke plan-architect subagent

Task {
  subagent_type: "general-purpose"
  description: "Revise implementation plan"
  prompt: |
    Read and follow ALL instructions in: .claude/agents/plan-architect.md

    Operation Mode: plan revision
    Existing Plan Path: ${PLAN_PATH}
    Backup Path: ${BACKUP_PATH}
    Revision Details: ${REVISION_DETAILS}

    Research Reports: ${REPORT_COUNT} reports in ${RESEARCH_DIR}

    Use Edit tool (NOT Write) to revise the existing plan.
    Preserve all [COMPLETE] phase markers.
    Update Revision History section.

    Return PLAN_REVISED signal when done.
}

## Block 5c: Plan Revision Verification

```bash
set +H
set -e

# Source libraries
source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling.sh" >&2
  exit 1
}

# Restore persisted variables
source ~/.claude/data/state/[WORKFLOW]_*.state 2>/dev/null || true

# Verify backup still exists
if [[ ! -f "$BACKUP_PATH" ]]; then
  log_command_error "verification_error" \
    "Backup file missing: $BACKUP_PATH" \
    "Backup should exist after plan-architect completion"
  echo "ERROR: VERIFICATION FAILED - Backup missing"
  exit 1
fi

# Verify plan was modified (timestamp check)
if [[ ! "$PLAN_PATH" -nt "$BACKUP_PATH" ]]; then
  # If timestamp check inconclusive, try content comparison
  if diff -q "$PLAN_PATH" "$BACKUP_PATH" >/dev/null 2>&1; then
    log_command_error "verification_error" \
      "Plan file not modified (identical to backup)" \
      "plan-architect should have made changes via Edit tool"
    echo "ERROR: VERIFICATION FAILED - Plan unchanged"
    echo "Recovery: Review plan-architect output, ensure meaningful revision"
    exit 1
  fi
fi

# Checkpoint reporting
echo "[CHECKPOINT] Plan revision verified - plan modified successfully"
```
```

---

## Pattern Requirements

### 1. CRITICAL BARRIER Label

All Execute blocks (Nb) must include this directive:

```markdown
**CRITICAL BARRIER**: This block MUST invoke [AGENT_NAME] via Task tool.
Verification block (Nc) will FAIL if [EXPECTED_ARTIFACT] not created.
```

### 2. Fail-Fast Verification

All Verify blocks (Nc) must:
- Check for expected artifacts (directories, files, counts)
- Exit with code 1 on verification failure
- Log errors via `log_command_error`
- Provide recovery instructions

**Example**:
```bash
if [[ ! -f "$EXPECTED_FILE" ]]; then
  log_command_error "verification_error" \
    "Expected file not found: $EXPECTED_FILE" \
    "Agent [NAME] should have created this file"
  echo "ERROR: VERIFICATION FAILED"
  echo "Recovery: [SPECIFIC RECOVERY STEPS]"
  exit 1
fi
```

### 3. State Transitions as Gates

All Setup blocks (Na) must include state transition with verification:

```bash
sm_transition "STATE_NAME" || {
  log_command_error "state_error" \
    "Failed to transition to STATE_NAME" \
    "sm_transition returned non-zero exit code"
  exit 1
}
```

### 4. Variable Persistence

All Setup blocks must persist variables needed by Execute and Verify blocks:

```bash
append_workflow_state "VAR_NAME" "$VAR_VALUE"
```

All Verify blocks must restore persisted state:

```bash
source ~/.claude/data/state/[WORKFLOW]_*.state 2>/dev/null || true
```

### 5. Checkpoint Reporting

All blocks should report checkpoints for debugging:

```bash
echo "[CHECKPOINT] [BLOCK_NAME] complete - [STATUS_SUMMARY]"
```

### 6. Error Logging Integration

All verification failures must log errors:

```bash
log_command_error "error_type" \
  "Error message" \
  "Additional context/details"
```

**Error Types**: `verification_error`, `state_error`, `agent_error`, `file_error`

---

## Anti-Patterns

### Don't: Merge Bash + Task in Single Block

**❌ Wrong** (bypass possible):
```markdown
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

**✅ Correct** (bypass impossible):
```markdown
## Block 4a: Research Setup
```bash
RESEARCH_DIR="/path/to/reports"
mkdir -p "$RESEARCH_DIR"
```

## Block 4b: Research Execution
Task { ... }

## Block 4c: Research Verification
```bash
REPORT_COUNT=$(find "$RESEARCH_DIR" ...)
```
```

### Don't: Soft Verification (Warnings Only)

**❌ Wrong**:
```bash
if [[ ! -f "$EXPECTED_FILE" ]]; then
  echo "WARNING: File not found, continuing anyway"
fi
# Continues execution
```

**✅ Correct**:
```bash
if [[ ! -f "$EXPECTED_FILE" ]]; then
  log_command_error "verification_error" "..." "..."
  echo "ERROR: VERIFICATION FAILED"
  exit 1  # Fail-fast
fi
```

### Don't: Skip Error Logging

**❌ Wrong**:
```bash
if [[ ! -f "$FILE" ]]; then
  echo "ERROR: File missing"
  exit 1
fi
```

**✅ Correct**:
```bash
if [[ ! -f "$FILE" ]]; then
  log_command_error "verification_error" \
    "File missing: $FILE" \
    "Agent should have created this file"
  echo "ERROR: File missing"
  exit 1
fi
```

### Don't: Omit Checkpoint Reporting

**❌ Wrong**:
```bash
sm_transition "STATE"
mkdir -p "$DIR"
# No checkpoint
```

**✅ Correct**:
```bash
sm_transition "STATE"
mkdir -p "$DIR"
echo "[CHECKPOINT] Setup complete - ready for agent invocation"
```

---

## When to Use

Apply hard barrier pattern when:

1. **Orchestrator has permissive tool access**: Read, Edit, Write, Grep, Glob
2. **Subagent work must be isolated**: For reusability across workflows
3. **Delegation enforcement is critical**: Architecture requires consistent patterns
4. **Error recovery needs explicit checkpoints**: For debugging and resume

**Commands Requiring Hard Barriers**:
- `/build` (implementer-coordinator)
- `/collapse` (plan-architect)
- `/debug` (debug-analyst, plan-architect)
- `/errors` (errors-analyst)
- `/expand` (plan-architect)
- `/plan` (research-specialist, plan-architect)
- `/repair` (repair-analyst, plan-architect)
- `/research` (research-specialist)
- `/revise` (research-specialist, plan-architect)
- `/todo` (todo-analyzer)

---

## Benefits

### Architectural

1. **100% Delegation Success**: Bypass structurally impossible
2. **Modular Architecture**: Clear separation of orchestrator vs specialist roles
3. **Reusable Components**: Agents callable from multiple commands
4. **Predictable Workflow**: Consistent delegation pattern

### Operational

1. **Context Efficiency**: 40-60% reduction in orchestrator token usage
2. **Error Recovery**: Explicit checkpoints enable resume from failure
3. **Debuggability**: Checkpoint markers trace execution flow
4. **Maintainability**: Clear block structure, easy to understand

### Quality

1. **Testable**: Each block can be tested independently
2. **Observable**: Checkpoint reporting and error logging
3. **Recoverable**: Fail-fast with recovery instructions
4. **Standards-Compliant**: Enforces error logging, state transitions

---

## Troubleshooting

### Issue: Verification Block Not Executing

**Symptoms**: Command completes without verification errors, even though agent failed

**Cause**: Blocks merged - bash code after Task in same block won't execute if Task fails

**Solution**: Split into separate blocks (4a, 4b, 4c)

### Issue: State Variables Not Available in Verify Block

**Symptoms**: Variables like `$RESEARCH_DIR` undefined in Block Nc

**Cause**: Variables not persisted, or state file not sourced

**Solution**:
```bash
# In Setup block (Na):
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"

# In Verify block (Nc):
source ~/.claude/data/state/[WORKFLOW]_*.state 2>/dev/null || true
```

### Issue: Verification Passes But Artifact Quality Poor

**Symptoms**: Verification confirms artifact exists, but content is incomplete

**Cause**: Verification only checks existence, not quality

**Solution**: Add quality checks:
```bash
# Check file size (should be > 100 bytes for real content)
FILE_SIZE=$(stat -f%z "$FILE" 2>/dev/null || stat -c%s "$FILE" 2>/dev/null)
if [[ "$FILE_SIZE" -lt 100 ]]; then
  log_command_error "verification_error" \
    "Artifact too small: $FILE ($FILE_SIZE bytes)" \
    "Agent may have created empty or minimal file"
  exit 1
fi
```

---

## Enhanced Diagnostics

### Overview

When verification blocks detect missing artifacts, enhanced diagnostics help distinguish between:
1. **File at wrong location** - Agent created artifact but in unexpected directory
2. **File not created** - Agent failed to create artifact at all
3. **Silent failure** - Agent executed but produced no output

This diagnostic approach significantly reduces debugging time by providing actionable error context.

### Diagnostic Strategy

**Search Pattern**:
```bash
# Enhanced hard barrier verification with diagnostics
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

### Diagnostic Output Examples

**Case 1: File at Wrong Location**
```
❌ Hard barrier verification failed: Artifact file not found
Expected: /specs/123_feature/summaries/implement-summary.md

📍 Found at alternate location(s):
  - /specs/123_feature/implement-summary.md
  - /specs/123_feature/outputs/implement-summary.md

⚠️  This indicates the agent created the file but not in the expected directory.
```

**Case 2: File Not Created**
```
❌ Hard barrier verification failed: Artifact file not found
Expected: /specs/123_feature/summaries/implement-summary.md

❌ Not found anywhere in topic directory: /specs/123_feature

⚠️  This indicates the agent failed to create the artifact file.
```

**Case 3: Silent Failure (Agent Tool Use Count)**
```
❌ Hard barrier verification failed: Artifact file not found
Expected: /specs/123_feature/summaries/implement-summary.md

❌ Not found anywhere in topic directory: /specs/123_feature

Agent tool uses: 0
⚠️  Warning: Agent may have failed silently (no tool uses recorded)
```

### Error Log Integration

Enhanced diagnostics create distinct error log entries for different failure modes:

**Location Mismatch**:
```json
{
  "error_type": "agent_error",
  "message": "Agent created file at wrong location",
  "context": {
    "expected": "/specs/123/summaries/summary.md",
    "found": "/specs/123/summary.md"
  }
}
```

**File Not Created**:
```json
{
  "error_type": "agent_error",
  "message": "Agent failed to create artifact file",
  "context": {
    "expected": "/specs/123/summaries/summary.md",
    "topic_dir": "/specs/123",
    "searched_pattern": "*summary*.md"
  }
}
```

### Troubleshooting Workflow

Based on diagnostic output:

1. **File at wrong location** → Check agent prompt for directory path ambiguity
2. **File not created** → Review agent output for errors, check permissions
3. **Silent failure (0 tool uses)** → Agent may have refused task or hit context limit

### Validation

Commands using enhanced diagnostics:
- `/implement` (implementer-coordinator summary verification)
- `/research` (research-specialist report verification)
- `/plan` (plan-architect plan verification)
- `/revise` (plan-architect revised plan verification)

---

## Compliance Checklist

Use this checklist when implementing or auditing hard barrier pattern compliance:

### Setup Block (Na)
- [ ] State transition with fail-fast: `sm_transition "$STATE" || exit 1`
- [ ] Variable persistence: `append_workflow_state "VAR" "$VAR"`
- [ ] Checkpoint reporting: `echo "[CHECKPOINT] Setup complete"`
- [ ] Error logging context: `export COMMAND_NAME USER_ARGS WORKFLOW_ID`

### Execute Block (Nb)
- [ ] CRITICAL BARRIER label: `**CRITICAL BARRIER**: This block MUST invoke subagent via Task tool`
- [ ] Task invocation ONLY (no bash code in execute block)
- [ ] Delegation warning: `This Task invocation CANNOT be bypassed`
- [ ] Behavioral injection: `Read and follow ALL behavioral guidelines from: agent.md`

### Verify Block (Nc)
- [ ] Library re-sourcing (subprocess isolation): `source lib/core/state-persistence.sh`
- [ ] Artifact existence checks: `[ -f "$FILE" ] || exit 1`
- [ ] Fail-fast verification: `exit 1` on any verification failure
- [ ] Error logging: `log_command_error "verification_error" "message" "details"`
- [ ] Recovery instructions: `RECOVERY: Re-run command, check agent logs`
- [ ] Checkpoint reporting: `echo "[CHECKPOINT] Verification complete"`

### Documentation
- [ ] Command listed in "Commands Requiring Hard Barriers" section above
- [ ] Block numbering follows Na/Nb/Nc pattern (e.g., 4a/4b/4c)

### Automated Validation

Run compliance validator to verify all requirements:

```bash
# Validate all commands
bash .claude/scripts/validate-hard-barrier-compliance.sh

# Validate single command
bash .claude/scripts/validate-hard-barrier-compliance.sh --command revise

# Verbose output for debugging
bash .claude/scripts/validate-hard-barrier-compliance.sh --verbose
```

See [Enforcement Mechanisms](../../reference/standards/enforcement-mechanisms.md) for pre-commit integration.

---

## Task Invocation Requirements

### Mandatory Imperative Directives

All Task tool invocations MUST be preceded by an explicit imperative directive. Pseudo-code syntax or instructional text patterns are PROHIBITED.

**Required Pattern**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the [AGENT_NAME] agent.

Task {
  subagent_type: "general-purpose"
  description: "Brief description"
  prompt: "..."
}
```

**Key Requirements**:
1. **Imperative instruction**: "**EXECUTE NOW**: USE the Task tool..." (explicit command to Claude)
2. **No code block wrapper**: Remove ` ```yaml ` fences around Task block
3. **No instructional text**: Don't use "# Use the Task tool to invoke..." comments without actual Task invocation
4. **Completion signal**: Agent must return explicit signal (e.g., `REPORT_CREATED: ${PATH}`)

### Anti-Pattern: Pseudo-Code Syntax

**❌ PROHIBITED** (pseudo-code - will be skipped):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: |
    Read and follow ALL instructions in: agent.md
}
```

**Problem**: No imperative directive tells Claude to USE the Task tool. Claude interprets this as documentation, not executable code.

**✅ CORRECT** (imperative directive):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research topic with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${TOPIC}
    - Output Path: ${REPORT_PATH}

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

### Anti-Pattern: Instructional Text Without Task Invocation

**❌ PROHIBITED** (instructional text without actual invocation):
```markdown
## Phase 3: Agent Delegation

This phase invokes the research-specialist agent.
Use the Task tool to invoke the agent with the calculated paths.
```

**Problem**: Instructional text describes what SHOULD happen but doesn't actually invoke the Task tool. Claude reads the instruction but performs no action.

**✅ CORRECT** (actual Task invocation):
```markdown
## Phase 3: Agent Delegation

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "..."
}
```

### Edge Case Patterns

#### Iteration Loop Invocations

When Task invocations occur inside iteration loops, the SAME invocation must have an imperative directive EACH time it appears in the control flow.

**Example** (from `/implement` command):
```markdown
## Block 5: Initial Implementation Attempt

**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Implement phase ${STARTING_PHASE}"
  prompt: "..."
}

## Block 7: Iteration Loop (if work remains)

```bash
if [ "$WORK_REMAINING" != "0" ]; then
  ITERATION=$((ITERATION + 1))
  echo "Iteration $ITERATION required"
fi
```

**EXECUTE NOW**: USE the Task tool to re-invoke implementer-coordinator for next iteration.

Task {
  subagent_type: "general-purpose"
  description: "Continue implementation (iteration ${ITERATION})"
  prompt: "..."
}
```

**Key Point**: Both Task blocks (initial and loop) require imperative directives, even though they invoke the same agent.

#### Conditional Invocations

When Task invocations occur conditionally (based on flags or workflow state), use conditional imperative directives.

**Pattern**:
```markdown
**EXECUTE IF** coverage below threshold: USE the Task tool to invoke test-executor.

Task {
  subagent_type: "general-purpose"
  description: "Run test suite"
  prompt: "..."
}
```

**Alternative** (explicit conditional in bash):
```bash
if [ "$COVERAGE" -lt "$THRESHOLD" ]; then
  echo "Coverage insufficient - re-running tests"
fi
```

**EXECUTE NOW**: USE the Task tool to invoke test-executor.

Task { ... }
```

#### Multiple Agents in Sequence

When multiple agents are invoked sequentially, each requires its own imperative directive.

**Example**:
```markdown
## Block 3a: Research Phase

**EXECUTE NOW**: USE the Task tool to invoke research-specialist.

Task { ... }

## Block 3b: Planning Phase

**EXECUTE NOW**: USE the Task tool to invoke plan-architect.

Task { ... }
```

**Don't**: Use single directive for multiple Task blocks ("Execute the following agents...").

### Canonical Example

The `/supervise` command fix (commit 0b710aff) demonstrates correct Task invocation pattern:

**Before** (pseudo-code):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Supervise implementation"
  prompt: |
    Read instructions from: supervise-agent.md
}
```

**After** (imperative):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the supervise-agent.

Task {
  subagent_type: "general-purpose"
  description: "Supervise implementation with monitoring"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/supervise-agent.md

    **Workflow-Specific Context**:
    - Plan Path: ${PLAN_PATH}
    - Topic Path: ${TOPIC_PATH}
    - Iteration: ${ITERATION}

    Execute supervision per behavioral guidelines.
    Return: SUPERVISION_COMPLETE: ${SUMMARY_PATH}
  "
}
```

### Validation

The lint-task-invocation-pattern.sh linter enforces these requirements:

```bash
# Detect naked Task blocks
bash .claude/scripts/lint-task-invocation-pattern.sh <command-file>

# Errors reported:
# - "Task { without EXECUTE NOW directive"
# - "Instructional text without actual Task invocation"
# - "Incomplete EXECUTE NOW directive (missing 'Task tool')"
```

See [Command Authoring Standards](../../reference/standards/command-authoring.md#task-tool-invocation-patterns) for complete Task invocation patterns.

---

## Related Documentation

- [Hierarchical Agents Overview](../hierarchical-agents-overview.md)
- [Hierarchical Agent Examples](../hierarchical-agents-examples.md) - Example 6
- [Error Handling Pattern](./error-handling.md)
- [State-Based Orchestration](../../architecture/state-based-orchestration-overview.md)
- [/revise Command Guide](../../guides/commands/revise-command-guide.md)
- [Command Authoring Standards](../../reference/standards/command-authoring.md#task-tool-invocation-patterns)
