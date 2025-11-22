# Output Formatting Standards

Comprehensive standards for command output formatting to ensure clean, readable Claude Code display with minimal visual noise.

## Table of Contents

1. [Core Principles](#core-principles)
2. [Output Suppression Patterns](#output-suppression-patterns)
3. [Block Consolidation Patterns](#block-consolidation-patterns)
4. [Comment Standards](#comment-standards)
5. [Output vs Error Distinction](#output-vs-error-distinction)
6. [Related Documentation](#related-documentation)

---

## Core Principles

### Principle 1: Suppress Success Output

Success messages, progress indicators, and intermediate state updates create display noise without adding value. Suppress all non-essential output.

### Principle 2: Preserve Error Visibility

Errors, warnings, and final summaries MUST remain visible. The goal is noise reduction, not silence.

### Principle 3: Minimize Bash Block Count

Each bash block creates a separate display element. Consolidate related operations into fewer blocks.

### Principle 4: Single Summary Line per Block

Each block should output a single summary line showing the net result, not individual operation results.

### Principle 5: WHAT Not WHY in Comments

Comments in executable files describe what the code does, not why it was designed that way. Design rationale belongs in guides.

---

## Output Suppression Patterns

### Library Sourcing Suppression

**Problem**: Library sourcing produces verbose output (function definitions, initialization messages).

**Pattern (Correct - Fail-Fast)**:
```bash
source "${LIB_DIR}/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
```

**Why**: Redirects verbose library output to /dev/null while preserving error handling via fail-fast pattern. The `|| { exit 1 }` ensures sourcing failures are caught.

**IMPORTANT - When Error Suppression is NOT Appropriate**:

Error suppression should NEVER be used for:
- Critical operations (state persistence, library loading)
- Operations where failure must be detected
- Function calls that need error capture

**Anti-Pattern (Hides Failures)**:
```bash
# WRONG: Suppresses errors, hides failures
save_completed_states_to_state 2>/dev/null

# WRONG: Prevents error detection
library_function || true
```

**Correct Pattern (Explicit Error Handling)**:
```bash
# RIGHT: Explicit error checking
if ! save_completed_states_to_state; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "Failed to persist state transitions" \
    "bash_block" \
    "$(jq -n --arg file "$STATE_FILE" '{state_file: $file}')"

  echo "ERROR: State persistence failed" >&2
  exit 1
fi
```

**Guidelines for Error Suppression**:
1. **Use for**: Non-critical directory creation, verbose library output
2. **Don't use for**: State persistence, critical operations, function calls
3. **Always provide**: Fail-fast alternative (`|| { exit 1 }`) for critical operations
4. **Always check**: Return codes for operations that can fail

### MANDATORY: Error Suppression on Critical Libraries

The following libraries MUST use fail-fast pattern. Bare `2>/dev/null` is PROHIBITED:

**Tier 1 Critical Libraries** (fail-fast required):
- `state-persistence.sh`
- `workflow-state-machine.sh`
- `error-handling.sh`
- `library-version-check.sh`

**Prohibited Pattern** (will fail linter):
```bash
source "${CLAUDE_LIB}/workflow/workflow-state-machine.sh" 2>/dev/null
```

**Required Pattern** (linter-compliant):
```bash
source "${CLAUDE_LIB}/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
```

**Rationale**: Bare suppression hides critical failures, causing exit code 127 errors much later in execution with no diagnostic information. Infrastructure fixes remediated 86+ instances of bare error suppression across 7 workflow commands (build.md, debug.md, plan.md, research.md, repair.md, revise.md, optimize-claude.md).

**Detection**: Linter flags `source.*2>/dev/null$` without fail-fast handler on critical libraries.

### Automated Detection: Library Sourcing Linter

The library sourcing linter validates error suppression patterns:

```bash
bash .claude/scripts/lint/check-library-sourcing.sh
```

**Linter Detects**:
- Bare error suppression on critical libraries (state-persistence.sh, workflow-state-machine.sh, error-handling.sh)
- Function calls without library sourcing in same bash block
- Missing defensive function availability checks

**Remediation Statistics**: Infrastructure fixes remediated 86+ instances of bare error suppression across 7 workflow commands (build.md, debug.md, plan.md, research.md, repair.md, revise.md, optimize-claude.md).

**Pre-Commit Enforcement**: The linter runs automatically via pre-commit hooks to prevent new violations.

**See Also**:
- [Exit Code 127 Troubleshooting Guide](../../troubleshooting/exit-code-127-command-not-found.md)
- [Bash Block Execution Model - Anti-Patterns](../../concepts/bash-block-execution-model.md#anti-pattern-7-bare-error-suppression-on-critical-libraries)
- [Linting Bash Sourcing Guide](../../guides/development/linting-bash-sourcing.md)

### Directory Operations Suppression

**Problem**: mkdir, cp, mv operations produce unnecessary output.

**Pattern**:
```bash
mkdir -p "$OUTPUT_DIR" 2>/dev/null || true
```

**Why**: Directory operations either succeed silently or are handled elsewhere. The `|| true` prevents script exit on non-critical failures.

### Single Summary Line Pattern

**Problem**: Multiple echo statements create visual noise.

**Anti-Pattern** (incorrect):
```bash
echo "Starting workflow initialization..."
echo "Loading state machine..."
echo "Validating configuration..."
echo "Setting up directories..."
echo "Initialization complete"
```

**Pattern** (correct):
```bash
# Perform all operations silently
source "$LIB" 2>/dev/null || exit 1
validate_config || exit 1
mkdir -p "$DIR" 2>/dev/null

# Single summary line
echo "Setup complete: $WORKFLOW_ID"
```

### Debug Log Pattern

**Problem**: Debug output clutters production display.

**Pattern**:
```bash
if [ "${DEBUG:-false}" = "true" ]; then
  echo "DEBUG: Variable value: $VAR" >&2
fi
```

**Why**: Debug output controlled by environment variable and sent to stderr.

### Command Output Suppression

**Problem**: Sub-command output adds noise when only status matters.

**Pattern**:
```bash
if git add -A >/dev/null 2>&1; then
  echo "Changes staged"
else
  echo "ERROR: Git staging failed" >&2
  exit 1
fi
```

---

## Block Consolidation Patterns

### Target Block Count

Commands SHOULD use 2-3 bash blocks maximum:

| Block Type | Purpose | Examples |
|-----------|---------|----------|
| **Setup** | Capture, validate, source, init, allocate | Argument capture, library sourcing, workflow ID allocation |
| **Execute** | Main workflow logic | Core processing, agent invocations, state transitions |
| **Cleanup** | Verify, complete, summary | Final validation, completion signal, summary output |

### Block Consolidation Rules

1. **Combine consecutive operations** that don't require intermediate verification
2. **Separate operations** that need explicit checkpoints or error handling
3. **Keep Task invocations** in their own block (for response visibility)
4. **Consolidate library sourcing** into single setup block

### Before/After Example

**Before** (6 blocks - excessive):
```markdown
Block 1: mkdir output dir
Block 2: source libraries
Block 3: validate config
Block 4: init state machine
Block 5: allocate workflow ID
Block 6: persist state
```

**After** (2 blocks - optimized):
```markdown
Block 1 (Setup):
- mkdir output dir
- source libraries
- validate config
- init state machine
- allocate workflow ID
- persist state

Block 2 (Execute):
- main workflow logic
```

### Consolidation Benefits

- **50-67% reduction** in display noise (6 blocks to 2-3)
- **Faster execution** (fewer subprocess spawns)
- **Cleaner output** (single summary per block)
- **Easier debugging** (logical groupings)

### Block Structure Template

```bash
# Block 1: Setup
set +H
mkdir -p "$DIR" 2>/dev/null
source "${LIB}/state-machine.sh" 2>/dev/null || exit 1
source "${LIB}/persistence.sh" 2>/dev/null || exit 1
sm_init "$DESC" "$CMD" "$TYPE" || exit 1
WORKFLOW_ID=$(allocate_workflow_id) || exit 1
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID" || exit 1
echo "Setup complete: $WORKFLOW_ID"
```

---

## Comment Standards

### WHAT Not WHY Enforcement

Comments in executable files (commands, agents) describe WHAT the code does. Design rationale (WHY) belongs in guide files.

### Correct Patterns

```bash
# Load state management functions
source lib.sh

# Validate required variables
[ -z "$VAR" ] && exit 1

# Initialize workflow with captured description
sm_init "$DESC" "$CMD"
```

### Incorrect Patterns

```bash
# We source this here because subprocess isolation requires re-sourcing
# in every bash block since functions don't persist across boundaries
source lib.sh  # WRONG: explains WHY, not WHAT

# We need this check because the state machine won't initialize
# correctly without these values and will cause silent failures
[ -z "$VAR" ] && exit 1  # WRONG: justification belongs in guide
```

### Where WHY Content Belongs

- **Guides** (`.claude/docs/guides/`): Explain design decisions, patterns, trade-offs
- **Concepts** (`.claude/docs/concepts/`): Document architectural principles
- **Reference** (`.claude/docs/reference/`): Specify standards and requirements

### Comment Density Guidelines

- **Commands**: Minimal comments (WHAT only), <250 lines total
- **Agents**: Brief section comments, <400 lines total
- **Libraries**: Function documentation (what, parameters, returns)

---

## Output vs Error Distinction

### What to Suppress

| Category | Examples | Action |
|----------|----------|--------|
| Success messages | "File created", "Operation complete" | Suppress with >/dev/null |
| Progress indicators | "Processing...", "Loading..." | Remove entirely |
| Intermediate state | "Setting X to Y", "Validated Z" | Suppress |
| Library initialization | Function definitions, module loads | Suppress with 2>/dev/null |

### What to Preserve

| Category | Examples | Action |
|----------|----------|--------|
| Errors | "ERROR: File not found" | Print to stderr |
| Warnings | "WARN: Deprecated pattern" | Print to stderr |
| Final summaries | "Setup complete: workflow_123" | Single line per block |
| User-needed data | File paths, URLs, identifiers | Print explicitly |

### Stderr vs Stdout

```bash
# Errors to stderr
echo "ERROR: Configuration invalid" >&2

# Warnings to stderr
echo "WARN: Using deprecated pattern" >&2

# Success summaries to stdout
echo "Setup complete: $WORKFLOW_ID"
```

### Relationship to Error Enhancement

Output suppression applies to **success and progress output only**. Errors remain verbose per [Error Enhancement Guide](../guides/patterns/error-enhancement-guide.md) standards:

- Errors use WHICH/WHAT/WHERE structure
- Errors include resolution guidance
- Errors are not suppressed

---

## Console Summary Standards
[Used by: /research, /plan, /debug, /build, /revise, /repair, /expand, /collapse]

### Purpose and Scope

Console summaries are concise completion messages (15-25 lines) displayed when commands finish. They serve as navigation aids directing users to comprehensive artifact files (.md in reports/, plans/, summaries/).

**Key Distinction**:
- **Console Summary**: 15-25 lines, terminal stdout, scannable format, emoji markers allowed
- **Summary Artifact**: 150-250 lines, .md file in summaries/, comprehensive details, no emoji

### Required Structure

All artifact-producing commands MUST use this 4-section format:

```bash
cat << EOF
=== [Command] Complete ===

Summary: [2-3 sentence narrative explaining what was accomplished and why it matters]

Phases:
  • Phase 1: [Title or "Complete"]
  • Phase 2: [Title or "Complete"]
  [Only shown if workflow has phases]

Artifacts:
  📄 Plan: /absolute/path/to/plan.md
  📊 Reports: /absolute/path/to/reports/ (N files)
  ✅ Summary: /absolute/path/to/summary.md
  [Grouped by artifact type, emoji-prefixed]

Next Steps:
  • Review [artifact]: cat /absolute/path
  • [Command-specific action 1]
  • [Command-specific action 2]
EOF
```

### Section Requirements

#### Summary Section

**Requirements**:
- 2-3 sentences maximum
- Explain WHAT was accomplished (scope, scale)
- Explain WHY it matters (purpose, value)
- Use narrative language, not technical jargon

**Examples**:
```bash
# Good: WHAT + WHY
Summary: Analyzed authentication system across 12 files and identified 3 implementation strategies. Research provides foundation for secure JWT-based authentication plan with refresh token support.

# Bad: Too technical, no context
Summary: Completed research phase. Files written to /path/to/reports/.
```

#### Phases Section

**Requirements**:
- Only include if workflow has distinct phases
- One bullet per phase with completion status
- Use `•` for bullets, not `-` or `*`
- Show phase title if available, otherwise "Complete"

**Examples**:
```bash
# With titles
Phases:
  • Phase 1: Project Structure Analysis - Complete
  • Phase 2: API Integration Implementation - Complete
  • Phase 3: Testing and Validation - Complete

# Minimal (when titles not available)
Phases:
  • Phase 1: Complete
  • Phase 2: Complete
```

**Omit entirely** if workflow has no phases (e.g., /research, /plan in single-phase mode).

#### Artifacts Section

**Requirements**:
- One line per artifact type, grouped logically
- Use emoji markers from vocabulary below
- Always use absolute paths (never relative)
- Show file count for directories with `(N files)` notation
- Order: Primary artifacts first (plans, reports), then supporting (debug, checkpoints)

**Path Format Rules**:
- **Single file**: `📄 Plan: /absolute/path/to/plan.md`
- **Directory with files**: `📊 Reports: /absolute/path/to/reports/ (3 files)`
- **Empty directory**: Omit entirely (don't show)

**Emoji Vocabulary**:
| Emoji | Artifact Type | Usage |
|-------|--------------|-------|
| 📄 | Plan files | .md files in plans/ directory |
| 📊 | Research reports | .md files in reports/ directory |
| ✅ | Implementation summaries | .md files in summaries/ directory |
| 🔧 | Debug artifacts | Files in debug/ directory |
| 📁 | Generic directory | When specific type doesn't apply |
| 💾 | Checkpoint files | .json files in checkpoints/ |

**Examples**:
```bash
# Multiple artifact types
Artifacts:
  📄 Plan: /home/user/.config/.claude/specs/027_auth/plans/027_auth_plan.md
  📊 Reports: /home/user/.config/.claude/specs/027_auth/reports/ (2 files)
  ✅ Summary: /home/user/.config/.claude/specs/027_auth/summaries/027_auth_summary.md

# Single artifact
Artifacts:
  📄 Plan: /home/user/.config/.claude/specs/027_auth/plans/027_auth_plan.md

# With debug output
Artifacts:
  📄 Plan: /home/user/.config/.claude/specs/027_auth/plans/027_auth_plan.md
  🔧 Debug: /home/user/.config/.claude/specs/027_auth/debug/ (5 files)
```

#### Next Steps Section

**Requirements**:
- 2-4 actionable commands user can copy-paste
- First step MUST be reviewing primary artifact
- Use absolute paths in commands
- Be command-specific (not generic)
- Use `•` for bullets, not `-` or `*`

**Examples**:
```bash
# Good: Specific, actionable, with paths
Next Steps:
  • Review plan: cat /home/user/.config/.claude/specs/027_auth/plans/027_auth_plan.md
  • Begin implementation: /build /home/user/.config/.claude/specs/027_auth/plans/027_auth_plan.md
  • Review research: cat /home/user/.config/.claude/specs/027_auth/reports/001_auth_strategies.md

# Bad: Generic, no paths
Next Steps:
  • Review the plan file
  • Run /build if ready
  • Check the reports
```

### Length Targets

| Section | Target Length | Notes |
|---------|--------------|-------|
| Summary | 2-3 sentences | ~40-80 words total |
| Phases | 1 line per phase | Omit if no phases |
| Artifacts | 1-5 lines | One per artifact type |
| Next Steps | 2-4 lines | Actionable commands |
| **Total** | **15-25 lines** | Including headers and spacing |

### Relationship to Summary Artifacts

**Console Summary** (this section):
- Concise completion message
- Terminal stdout display
- Navigation to artifacts
- Emoji markers allowed

**Summary Artifact** (.md file):
- Comprehensive implementation details
- 150-250 lines typical
- Created by agents in summaries/
- No emoji (file content standard)

**Division of Labor**:
```
User completes /build
    ↓
Console Summary (15-25 lines)
  • What was accomplished
  • Where to find details
  • What to do next
    ↓
User reviews Summary Artifact (150-250 lines)
  • Phase-by-phase breakdown
  • Test results and metrics
  • Implementation decisions
  • Git commit history
```

### Terminal Output Emoji Policy

**Allowed**: Emoji markers in terminal stdout for visual scanning (📄 📊 ✅ 🔧)

**Not Allowed**: Emoji in file artifacts (.md files in plans/, reports/, summaries/)

**Rationale**: Terminal output is ephemeral and benefits from visual markers. File artifacts are permanent documentation requiring UTF-8 compatibility and plain-text parsing.

See [Code Standards - Emoji Policy](code-standards.md#general-principles) for complete policy.

### Implementation Notes

**Variable Substitution**:
```bash
# Use existing command variables
PLAN_PATH="/path/to/plan.md"
RESEARCH_DIR="/path/to/reports"
SUMMARY_PATH="/path/to/summary.md"

cat << EOF
Artifacts:
  📄 Plan: $PLAN_PATH
  📊 Reports: $RESEARCH_DIR/ ($(ls "$RESEARCH_DIR" | wc -l) files)
  ✅ Summary: $SUMMARY_PATH
EOF
```

**Phase Title Extraction** (Optional):
```bash
# Simple approach: Use phase status only
Phases:
  • Phase 1: Complete
  • Phase 2: Complete

# Advanced approach: Extract titles from plan file (future enhancement)
PHASE_1_TITLE=$(grep "^### Phase 1:" "$PLAN_PATH" | sed 's/### Phase 1: //')
Phases:
  • Phase 1: $PHASE_1_TITLE
```

**Error Output Preservation**:

Console summary format applies to SUCCESS output only. Error messages remain verbose per [Error Enhancement Guide](../guides/patterns/error-enhancement-guide.md):

```bash
if [ $? -ne 0 ]; then
  # Error output (verbose, structured)
  echo "ERROR: Plan generation failed" >&2
  echo "WHICH: Planning agent execution" >&2
  echo "WHAT: Agent returned non-zero exit code" >&2
  echo "WHERE: Phase 2 - Strategy Selection" >&2
  exit 1
fi

# Success output (concise console summary)
cat << EOF
=== Plan Complete ===
Summary: Created 5-phase implementation plan...
EOF
```

### Command-Specific Guidance

| Command | Primary Artifacts | Typical Phases | Next Steps Focus |
|---------|------------------|---------------|------------------|
| /research | 📊 Reports (1-3 files) | None | Review reports, run /plan |
| /plan | 📊 Reports, 📄 Plan | None | Review plan, run /build |
| /debug | 🔧 Debug, 📄 Plan | 3-4 phases | Review debug analysis, run /build |
| /build | ✅ Summary, 📄 Plan | 3-5 phases | Review summary, check tests |
| /revise | 📄 Plan (updated), 📁 Backup | None | Review changes, run /build |
| /repair | 📊 Error Analysis, 📄 Repair Plan | None | Review analysis, run /build |
| /expand | 📄 Expanded Phases | None | Review expanded phases, continue /build |
| /collapse | 📄 Plan (collapsed) | None | Review collapsed plan, resume work |

---

## Related Documentation

### Core References
- [Code Standards](code-standards.md) - Overall code standards including output patterns
- [Command Authoring Standards](command-authoring-standards.md) - Execution directive and task patterns
- [Command Architecture Standards](../architecture/overview.md) - Command file design requirements

### Patterns and Concepts
- [Bash Block Execution Model](../concepts/bash-block-execution-model.md) - Subprocess isolation patterns
- [Executable/Documentation Separation](../concepts/patterns/executable-documentation-separation.md) - WHAT vs WHY separation

### Guides
- [Logging Patterns](../guides/patterns/logging-patterns.md) - Complete logging and output guidance
- [Error Enhancement Guide](../guides/patterns/error-enhancement-guide.md) - Structured error messages
- [Command Development Guide](../guides/development/command-development/command-development-fundamentals.md) - Complete command development

### Templates
- [Bash Block Template](../guides/templates/_template-bash-block.md) - Standard bash block structure

---

**Last Updated**: 2025-11-18
**Spec Reference**: 794_001_comprehensive_output_formatting_refactormd_to
