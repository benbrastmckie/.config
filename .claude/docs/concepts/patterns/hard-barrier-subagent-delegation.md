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

### Template 1: Research Phase Delegation

```markdown
## Block 4a: Research Setup

```bash
set +H  # Disable history expansion
set -e  # Fail-fast

# Source libraries (three-tier pattern)
source "$CLAUDE_LIB/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Cannot load workflow-state-machine.sh" >&2
  exit 1
}
source "$CLAUDE_LIB/workflow/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Cannot load state-persistence.sh" >&2
  exit 1
}
source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling.sh" >&2
  exit 1
}

# State transition blocks progression (fail-fast gate)
sm_transition "RESEARCH" || {
  log_command_error "state_error" \
    "Failed to transition to RESEARCH state" \
    "sm_transition returned non-zero exit code"
  exit 1
}

# Pre-calculate paths for subagent
RESEARCH_DIR="${TOPIC_PATH}/reports"
SPECS_DIR="${TOPIC_PATH}"

# Create directories
mkdir -p "$RESEARCH_DIR"

# Persist variables for next block
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"
append_workflow_state "SPECS_DIR" "$SPECS_DIR"

# Checkpoint reporting
echo "[CHECKPOINT] Research setup complete - ready for research-specialist invocation"
```

## Block 4b: Research Execution

**CRITICAL BARRIER**: This block MUST invoke research-specialist via Task tool.
Verification block (4c) will FAIL if artifacts not created.

**EXECUTE NOW**: Invoke research-specialist subagent

Task {
  subagent_type: "general-purpose"
  description: "Research [TOPIC]"
  prompt: |
    Read and follow ALL instructions in: .claude/agents/research-specialist.md

    Research Topic: ${RESEARCH_TOPIC}
    Output Directory: ${RESEARCH_DIR}
    Complexity: ${COMPLEXITY}

    Create research reports analyzing:
    - [Specific research area 1]
    - [Specific research area 2]
    - [Specific research area 3]

    Return completion signal when done.
}

## Block 4c: Research Verification

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

# Fail-fast if directory missing
if [[ ! -d "$RESEARCH_DIR" ]]; then
  log_command_error "verification_error" \
    "Research directory not found: $RESEARCH_DIR" \
    "research-specialist should have created this directory"
  echo "ERROR: VERIFICATION FAILED - Research directory missing"
  echo "Recovery: Check research-specialist agent logs, re-run command"
  exit 1
fi

# Fail-fast if no reports created
REPORT_COUNT=$(find "$RESEARCH_DIR" -name "*.md" -type f 2>/dev/null | wc -l)
if [[ "$REPORT_COUNT" -eq 0 ]]; then
  log_command_error "verification_error" \
    "No research reports found in $RESEARCH_DIR" \
    "research-specialist should have created at least one report"
  echo "ERROR: VERIFICATION FAILED - No research reports found"
  echo "Recovery: Verify research-specialist completed, check for errors"
  exit 1
fi

# Persist report count for next phase
append_workflow_state "REPORT_COUNT" "$REPORT_COUNT"

# Checkpoint reporting
echo "[CHECKPOINT] Research verification complete - $REPORT_COUNT reports created"
```
```

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

## Related Documentation

- [Hierarchical Agents Overview](../hierarchical-agents-overview.md)
- [Hierarchical Agent Examples](../hierarchical-agents-examples.md) - Example 6
- [Error Handling Pattern](./error-handling.md)
- [State-Based Orchestration](../../architecture/state-based-orchestration-overview.md)
- [/revise Command Guide](../../guides/commands/revise-command-guide.md)
