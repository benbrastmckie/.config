## Code Standards
[Used by: /implement, /refactor, /plan]

### General Principles
- **Indentation**: 2 spaces, expandtab
- **Line length**: ~100 characters (soft limit)
- **Naming**: snake_case for variables/functions, PascalCase for module tables
- **Error Handling**: Use defensive programming patterns with structured error messages (WHICH/WHAT/WHERE) and integrate centralized error logging - See [Defensive Programming Patterns](.claude/docs/concepts/patterns/defensive-programming.md), [Error Handling Pattern](.claude/docs/concepts/patterns/error-handling.md), and [Error Enhancement Guide](.claude/docs/guides/patterns/error-enhancement-guide.md)
- **Documentation**: Every directory must have a README.md
- **Character Encoding**: UTF-8 only
- **Emoji Policy**:
  - **File Content**: NO emoji in artifact files (.md, .sh, .lua, .json, etc.) - ensures UTF-8 compatibility and plain-text parsing
  - **Terminal Output**: Emoji markers ALLOWED in console output (stdout/stderr) for visual scanning - see [Console Summary Standards](output-formatting.md#console-summary-standards) for approved vocabulary

### Language-Specific Standards
- **Lua**: See [Neovim Configuration Guidelines](nvim/CLAUDE.md) for detailed Lua standards
- **Markdown**: Use Unicode box-drawing for diagrams, follow CommonMark spec
- **Shell Scripts**: Follow ShellCheck recommendations, use bash -e for error handling

### Command and Agent Architecture Standards
[Used by: All slash commands and agent development]

- **Command files** (`.claude/commands/*.md`) are AI execution scripts, not traditional code
- **Executable instructions** must be inline, not replaced by external references
- **Templates** must be complete and copy-paste ready (agent prompts, JSON schemas, bash commands)
- **Critical warnings** (CRITICAL, IMPORTANT, NEVER) must stay in command files
- **Reference files** (`shared/`, `templates/`, `docs/`) provide supplemental context only
- **Imperative Language**: All required actions use MUST/WILL/SHALL (never should/may/can) - See [Imperative Language Guide](.claude/docs/archive/guides/patterns/execution-enforcement/execution-enforcement-overview.md)
- **Behavioral Injection**: Commands invoke agents via Task tool with context injection (not SlashCommand) - See [Behavioral Injection Pattern](.claude/docs/concepts/patterns/behavioral-injection.md)
- **Verification and Fallback**: All file creation operations require MANDATORY VERIFICATION checkpoints - See [Verification and Fallback Pattern](.claude/docs/concepts/patterns/verification-fallback.md)
- **Robustness Patterns**: Apply systematic robustness patterns for reliable command development - See [Robustness Framework](.claude/docs/concepts/robustness-framework.md)
- See [Command Architecture Standards](../architecture/overview.md) for complete guidelines

### Mandatory Bash Block Sourcing Pattern
[Used by: All commands with bash blocks]

All bash blocks in `.claude/commands/` MUST follow the three-tier sourcing pattern. This is NOT optional - violations are caught by linter and pre-commit hooks.

**Required Pattern (Every Bash Block)**:

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

**Three-Tier Library Classification**:

| Tier | Libraries | Error Handling | Rationale |
|------|-----------|----------------|-----------|
| **Tier 1: Critical Foundation** | state-persistence.sh, workflow-state-machine.sh, error-handling.sh, validation-utils.sh | Fail-fast required | Core state management and validation; failure causes exit 127 later or data integrity issues |
| **Tier 2: Workflow Support** | workflow-initialization.sh, checkpoint-utils.sh, unified-logger.sh | Graceful degradation | Non-critical; commands can proceed without |
| **Tier 3: Command-Specific** | checkbox-utils.sh, summary-formatting.sh | Optional | Feature-specific; missing causes partial functionality |

**Enforcement**:
- **Linter**: `.claude/scripts/lint/check-library-sourcing.sh` validates all commands
- **Pre-commit**: Violations block commits (use `--no-verify` only with documented justification)
- **CI**: Linter runs in validation pipeline before tests

**Why This Pattern is Mandatory**:

Each bash block in Claude Code runs in a **new subprocess**. Variables and functions from previous blocks are NOT available. Without re-sourcing libraries, function calls fail with exit code 127 ("command not found").

See [Bash Block Execution Model](../../concepts/bash-block-execution-model.md) for complete subprocess isolation documentation and [Exit Code 127 Troubleshooting Guide](../../troubleshooting/exit-code-127-command-not-found.md) for debugging failures.

### Error Logging Requirements
[Used by: All commands and agents]

All commands MUST integrate centralized error logging for queryable error tracking and cross-workflow debugging. Error logging enables the `/errors` and `/repair` commands to analyze failure patterns and generate fix plans.

**Mandatory Pattern (Every Command)**:

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

**Error Type Selection Guide**:

| Error Type | When to Use | Example |
|------------|-------------|---------|
| `validation_error` | Invalid user input (arguments, flags) | Missing required arg, invalid flag |
| `file_error` | File I/O failures (missing, unreadable) | File not found, permission denied |
| `state_error` | State management failures (missing state, restoration) | State file missing, variable not restored |
| `agent_error` | Subagent invocation failures | Agent timeout, agent returned error signal |
| `parse_error` | Output parsing failures | Invalid JSON, unexpected format |
| `execution_error` | General execution failures | Command not found, library function failed |
| `initialization_error` | Early initialization failures (pre-trap) | Error before error-handling.sh loaded |

**Error Logging Coverage Target**: 80%+ of error exit points MUST call `log_command_error` before `exit 1`.

**Bash Error Trap Automatic Coverage**: The `setup_bash_error_trap` function automatically logs:
- Command failures (exit code 127, "command not found")
- Unbound variable errors (`set -u` violations)
- All bash-level errors not explicitly logged

**State Restoration Validation** (multi-block commands):

```bash
# Block 2+ (after load_workflow_state)
load_workflow_state "$WORKFLOW_ID" false

# Validate critical variables restored
validate_state_restoration "COMMAND_NAME" "WORKFLOW_ID" "PLAN_PATH" || {
  echo "ERROR: State restoration failed" >&2
  exit 1
}
```

**Enforcement**:
- **Linter**: `.claude/scripts/lint/check-error-logging-coverage.sh` validates 80% coverage threshold
- **Pre-commit**: Coverage violations block commits
- **Bash Error Traps**: Catch unlogged errors automatically

See [Error Handling Pattern](../../concepts/patterns/error-handling.md) for complete integration requirements and [Errors Command Guide](../../guides/commands/errors-command-guide.md) for error consumption workflow.

### Output Suppression Patterns
[Used by: All commands and agents]

Commands MUST suppress verbose output to maintain clean Claude Code display:

**Library Sourcing**: Suppress output while preserving error handling
```bash
source "${LIB_DIR}/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
```

**Directory Operations**: Suppress non-critical operations
```bash
mkdir -p "$OUTPUT_DIR" 2>/dev/null || true
```

**Single Summary Line**: One output per block instead of multiple progress messages
```bash
# After all operations complete
echo "Setup complete: $WORKFLOW_ID"
```

**WHAT not WHY Comments**: Comments describe what code does, not why it was designed that way
```bash
# Load state management functions (correct - WHAT)
source lib.sh

# We source here because subprocess isolation requires... (incorrect - WHY)
```

See [Output Formatting Standards](output-formatting.md) for comprehensive patterns and [Bash Block Execution Model](.claude/docs/concepts/bash-block-execution-model.md#pattern-8-block-count-minimization) for block consolidation.

### Directory Creation Anti-Patterns
[Used by: All commands and agents]

Commands MUST NOT create artifact subdirectories eagerly during setup. Use the lazy directory creation pattern where directories are created only when files are written.

**NEVER: Eager Subdirectory Creation**

This anti-pattern creates empty directories that persist when workflows fail or are interrupted:

```bash
# WRONG: Eager directory creation in command setup
initialize_workflow_paths "$TOPIC_NAME" || exit 1

RESEARCH_DIR="${TOPIC_PATH}/reports"
DEBUG_DIR="${TOPIC_PATH}/debug"
PLANS_DIR="${TOPIC_PATH}/plans"

# Creates directories immediately (VIOLATES lazy creation standard)
mkdir -p "$RESEARCH_DIR"
mkdir -p "$DEBUG_DIR"
mkdir -p "$PLANS_DIR"

# If workflow fails before agent writes files, empty directories persist
```

**Impact**: Each failed workflow creates 1-3 empty subdirectories. Over 400-500+ empty directories accumulated before this pattern was remediated (Spec 869 root cause analysis). Empty directories create false signals during debugging and violate the lazy creation standard documented in [Directory Protocols](../../concepts/directory-protocols.md).

**ALWAYS: Lazy Directory Creation in Agents**

Agents create parent directories on-demand when writing files using `ensure_artifact_directory()`:

```bash
# CORRECT: Command setup (path assignment only, no mkdir)
initialize_workflow_paths "$TOPIC_NAME" || exit 1

RESEARCH_DIR="${TOPIC_PATH}/reports"
DEBUG_DIR="${TOPIC_PATH}/debug"
PLANS_DIR="${TOPIC_PATH}/plans"

# No mkdir here - agents handle lazy creation

# In agent behavioral guidelines (e.g., research-specialist.md)
source .claude/lib/core/unified-location-detection.sh

REPORT_PATH="${RESEARCH_DIR}/001_report.md"

# Ensure parent directory exists (lazy creation pattern)
ensure_artifact_directory "$REPORT_PATH" || {
  echo "ERROR: Failed to create parent directory for report" >&2
  exit 1
}

# Write tool creates file (parent directory guaranteed to exist)
# Directory created ONLY when file is written
```

**Benefits**: No empty directories when workflows fail, consistent with lazy creation standard, simpler command code, agents have full control over directory lifecycle.

**Exception: Atomic Directory+File Creation**

When directory creation is immediately followed by file creation in the same bash block, eager creation is acceptable:

```bash
# ACCEPTABLE: Atomic directory+file creation (revise.md example)
BACKUP_DIR="${TOPIC_PATH}/backups"
mkdir -p "$BACKUP_DIR"
cp "$PLAN_PATH" "${BACKUP_DIR}/$(basename "$PLAN_PATH").backup_$(date +%s)"
# File written immediately after mkdir - no empty directory risk
```

**Audit Checklist**:
- Commands MUST NOT use `mkdir -p $RESEARCH_DIR`, `$DEBUG_DIR`, `$PLANS_DIR`, or `$SUMMARIES_DIR`
- Agents MUST call `ensure_artifact_directory()` before writing artifact files
- Only exception: Atomic directory+file creation where file write follows immediately in same bash block
- Verify with: `grep 'mkdir -p "\$.*_DIR"' .claude/commands/*.md` (should only match atomic patterns)

**See Also**:
- [Directory Protocols - Lazy Directory Creation](../../concepts/directory-protocols.md#lazy-directory-creation)
- [Unified Location Detection API](../../concepts/directory-protocols.md#unified-location-detection-library) - `ensure_artifact_directory()` function documentation
- [Error Case Study: Spec 869](../../troubleshooting/common-issues.md) - Empty debug/ directory root cause analysis

### Architectural Separation

**Executable/Documentation Separation Pattern**: Commands and agents separate lean executable logic from comprehensive documentation to eliminate meta-confusion loops and enable independent evolution.

**Pattern**:
- **Executable Files** (`.claude/commands/*.md`, `.claude/agents/*.md`): Lean execution scripts (<250 lines for commands, <400 lines for agents) containing bash blocks, phase markers, and minimal inline comments (WHAT not WHY)
- **Guide Files** (`.claude/docs/guides/*-command-guide.md`): Comprehensive task-focused documentation (unlimited length) with architecture, examples, troubleshooting, and design decisions

**Templates**:
- New Command: Start with [_template-executable-command.md](.claude/docs/guides/templates/_template-executable-command.md)
- Command Guide: Use [_template-command-guide.md](.claude/docs/guides/templates/_template-command-guide.md)

**Complete Pattern Documentation**:
- [Executable/Documentation Separation Pattern](.claude/docs/concepts/patterns/executable-documentation-separation.md) - Complete pattern with case studies and metrics
- [Command Development Guide - Section 2.4](.claude/docs/guides/development/command-development/command-development-fundamentals.md#24-executabledocumentation-separation-pattern) - Practical implementation instructions
- [Standard 14](../architecture/overview.md#standard-14-executabledocumentation-file-separation) - Formal architectural requirement

**Benefits**: 70% average reduction in executable file size, zero meta-confusion incidents, independent documentation growth, fail-fast execution

### Development Guides
- [Command Development Guide](.claude/docs/guides/development/command-development/command-development-fundamentals.md) - Complete guide to creating and maintaining slash commands
- [Agent Development Guide](.claude/docs/guides/development/agent-development/agent-development-fundamentals.md) - Complete guide to creating and maintaining specialized agents
- [Model Selection Guide](.claude/docs/guides/development/model-selection-guide.md) - Guide to choosing Claude model tiers (Haiku/Sonnet/Opus) for agents with cost/quality optimization

## Mandatory Patterns
[Used by: /implement, /build, /plan]

This section documents patterns that are MANDATORY and enforced by automated tooling. Violations will block commits and must be fixed.

### Bash Library Sourcing

**Requirement**: All bash blocks MUST follow the three-tier sourcing pattern.

**Enforcement**: `check-library-sourcing.sh` linter, pre-commit hooks

**Pattern**:
```bash
# Tier 1: Critical libraries - MUST have fail-fast handlers
source "${CLAUDE_LIB}/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2; exit 1
}
source "${CLAUDE_LIB}/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2; exit 1
}
source "${CLAUDE_LIB}/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2; exit 1
}

# Tier 2/3: Non-critical libraries - graceful degradation allowed
source "${CLAUDE_LIB}/core/summary-formatting.sh" 2>/dev/null || true
```

**Why Mandatory**: Each bash block runs in a new subprocess. Functions from previous blocks are NOT available. Without re-sourcing, function calls fail with exit code 127.

**NEVER**: Source critical libraries without fail-fast handlers:
```bash
# WRONG: Bare suppression hides failures
source "${CLAUDE_LIB}/workflow/workflow-state-machine.sh" 2>/dev/null
```

See [Bash Block Execution Model](../../concepts/bash-block-execution-model.md) for complete subprocess isolation documentation.

### Error Suppression Policy

**Requirement**: State persistence functions MUST NOT have errors suppressed.

**Enforcement**: `lint_error_suppression.sh`

**NEVER**:
```bash
# WRONG: Suppresses state persistence errors
save_completed_states_to_state 2>/dev/null
save_completed_states_to_state || true
```

**ALWAYS**:
```bash
# CORRECT: Explicit error handling
if ! save_completed_states_to_state 2>&1; then
  echo "ERROR: State persistence failed" >&2
  log_command_error "state_error" "State persistence failed" ""
  exit 1
fi
```

**NEVER**: Use deprecated state paths:
```bash
# WRONG: Deprecated paths
STATE_FILE=".claude/data/states/workflow.sh"
STATE_FILE=".claude/data/workflows/workflow.sh"

# CORRECT: Standard path
STATE_FILE=".claude/tmp/workflow_${WORKFLOW_ID}.sh"
```

### Directory Creation Policy

**Requirement**: Commands MUST NOT create artifact subdirectories eagerly during setup.

**Enforcement**: Manual review, agent behavioral guidelines

**NEVER**:
```bash
# WRONG: Eager creation in command setup
mkdir -p "$RESEARCH_DIR"
mkdir -p "$DEBUG_DIR"
mkdir -p "$PLANS_DIR"
```

**ALWAYS**: Use lazy directory creation in agents:
```bash
# CORRECT: In agent, immediately before Write tool
ensure_artifact_directory "$REPORT_PATH" || exit 1
# Write tool creates file (directory guaranteed to exist)
```

**Exception**: Atomic directory+file creation in same bash block is acceptable.

See [Directory Creation Anti-Patterns](#directory-creation-anti-patterns) for complete documentation.

### TODO.md Backup Pattern

**Standard**: Use git commits for TODO.md backups, not file-based backups.

- Create git commit before modifying TODO.md
- Include workflow context in commit message
- Check for uncommitted changes before committing
- See [Backup Policy](../templates/backup-policy.md#git-based-backup-for-todomd) for complete pattern

**Example**:
```bash
# Check for uncommitted changes
if ! git diff --quiet "$TODO_PATH" 2>/dev/null; then
  git add "$TODO_PATH"
  git commit -m "chore: snapshot TODO.md before /todo update

Workflow ID: ${WORKFLOW_ID}
Command: /todo ${USER_ARGS}"
fi
```

**Recovery**:
```bash
# View recent commits
git log --oneline .claude/TODO.md

# Restore from commit
git checkout <commit-hash> -- .claude/TODO.md
```

## Enforcement
[Used by: pre-commit hooks, CI validation]

### Automated Validation

The following validators enforce code standards:

| Validator | Enforces | Severity |
|-----------|----------|----------|
| check-library-sourcing.sh | Bash three-tier sourcing, fail-fast handlers | ERROR |
| lint_error_suppression.sh | Error suppression anti-patterns | ERROR |
| lint_bash_conditionals.sh | Preprocessing-safe conditionals | ERROR |
| validate-links.sh | Internal link validity | WARNING |

### Validation Commands

```bash
# Run all validators
bash .claude/scripts/validate-all-standards.sh --all

# Run specific validators
bash .claude/scripts/lint/check-library-sourcing.sh
bash .claude/tests/utilities/lint_error_suppression.sh
bash .claude/tests/utilities/lint_bash_conditionals.sh
bash .claude/scripts/validate-links-quick.sh
```

### Pre-Commit Integration

Pre-commit hooks automatically run validators on staged files. Violations block commits.

Bypass with justification:
```bash
git commit --no-verify -m "Emergency: [documented reason for bypass]"
```

**Warning**: Bypassing should be rare and documented. Violations will be caught in CI.

See [Enforcement Mechanisms Reference](enforcement-mechanisms.md) for complete enforcement details.

### Internal Link Conventions
[Used by: /document, /plan, /implement, all documentation]

**Standard**: All internal markdown links must use relative paths from the current file location.

**Format**:
- Same directory: `[File](file.md)`
- Parent directory: `[File](../file.md)`
- Subdirectory: `[File](subdir/file.md)`
- With anchor: `[Section](file.md#section-name)`

**Prohibited**:
- Absolute filesystem paths: `/home/user/.config/file.md`
- Repository-relative without base: `.claude/docs/file.md` (from outside .claude/)

**Validation**:
- Run `.claude/scripts/validate-links-quick.sh` before committing
- Full validation: `.claude/scripts/validate-links.sh`

**Template Placeholders** (Allowed):
- `{variable}` - Template variable
- `NNN_topic` - Placeholder pattern
- `$ENV_VAR` - Environment variable

**Historical Documentation** (Preserve as-is):
- Spec reports, summaries, and completed plans may have broken links documenting historical states
- Only fix if link prevents understanding current system

See the Link Conventions section above for complete standards.
