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

## Checkpoint Reporting Format

Checkpoints are intermediate progress markers in multi-block workflows that provide visibility into workflow state without verbose logging.

### Purpose and Scope

Checkpoints serve three purposes:

1. **Progress Visibility**: Show workflow advancement between bash blocks
2. **Context Preservation**: Persist critical variables for cross-block access
3. **Resume Readiness**: Indicate next phase or agent invocation

**When to Use Checkpoints**:
- Between major workflow phases (setup complete, validation complete, delegation ready)
- Before agent invocations (all context prepared)
- After state transitions (entering new phase, completing phase)

**When NOT to Use Checkpoints**:
- Within single bash blocks (use regular echo statements)
- For error messages (use stderr with ERROR prefix)
- For final completion (use Console Summary format instead)

### Standard Checkpoint Format

All checkpoints MUST use this structure:

```bash
echo "[CHECKPOINT] {Phase Name} complete"
echo "Context: {KEY}={VALUE}, {KEY}={VALUE}"
echo "Ready for: {Next Action}"
```

**Format Rules**:
- First line: `[CHECKPOINT]` marker, phase name, "complete" status
- Second line: "Context:" prefix followed by comma-separated KEY=VALUE pairs
- Third line: "Ready for:" prefix describing next action

### Checkpoint Template

```bash
# After completing setup phase
echo "[CHECKPOINT] Setup phase complete"
echo "Context: WORKFLOW_ID=${WORKFLOW_ID}, TOPIC_DIR=${TOPIC_DIR}, COMPLEXITY=${COMPLEXITY}"
echo "Ready for: Agent delegation"

# After validation
echo "[CHECKPOINT] Validation complete"
echo "Context: PLAN_FILE=${PLAN_FILE}, PHASE_COUNT=${PHASE_COUNT}, STARTING_PHASE=${STARTING_PHASE}"
echo "Ready for: Implementation execution"

# After state transition
echo "[CHECKPOINT] Phase 1 complete"
echo "Context: REPORTS_CREATED=${REPORT_COUNT}, NEXT_PHASE=2"
echo "Ready for: Planning phase"
```

### Context Variable Guidelines

**Include in Context Line**:
- Workflow identifiers (WORKFLOW_ID, STATE_ID)
- File paths needed by subsequent blocks (PLAN_FILE, TOPIC_DIR, REPORT_PATH)
- Counters and indices (PHASE_COUNT, CURRENT_PHASE, ITERATION)
- Configuration flags (DRY_RUN, COMPLEXITY, DEBUG_MODE)

**Exclude from Context Line**:
- Verbose descriptions or multi-line values
- Internal implementation details
- Temporary variables not persisted to state

**Format**:
```bash
# Good: Concise, relevant, parseable
echo "Context: WORKFLOW_ID=workflow_1234, PHASE=2, DRY_RUN=false"

# Bad: Verbose, unparseable
echo "Context: The workflow ID is workflow_1234 and we are in phase 2"
```

### Ready For Guidelines

The "Ready for" line describes the next workflow action in human-readable terms:

**Good Examples**:
- "Ready for: Agent delegation to research-specialist"
- "Ready for: Implementation of Phase 2"
- "Ready for: Validation and testing"
- "Ready for: State transition to build phase"

**Bad Examples**:
- "Ready for: Next step" (too vague)
- "Ready for: Bash block 3 execution" (implementation detail)
- "Ready for: See plan.md for details" (not actionable)

### Checkpoint Placement

Place checkpoints at natural workflow boundaries:

```bash
# Block 1: Setup
set +H
source libs.sh 2>/dev/null || exit 1
sm_init "$DESC" "$CMD" "$TYPE" || exit 1
WORKFLOW_ID=$(allocate_workflow_id) || exit 1

echo "[CHECKPOINT] Setup complete"
echo "Context: WORKFLOW_ID=${WORKFLOW_ID}, CMD=${CMD}"
echo "Ready for: Argument validation"

# Block 2: Validation
set +H
load_workflow_state "$WORKFLOW_ID"
validate_args || exit 1

echo "[CHECKPOINT] Validation complete"
echo "Context: WORKFLOW_ID=${WORKFLOW_ID}, ARGS_VALID=true"
echo "Ready for: Agent delegation"

# Block 3: Agent Invocation
# Task tool invocation here...
```

### Verbosity Balance

**Minimal Checkpoint** (simple workflows):
```bash
echo "[CHECKPOINT] Setup complete"
echo "Context: WORKFLOW_ID=${WORKFLOW_ID}"
echo "Ready for: Execution"
```

**Detailed Checkpoint** (complex workflows):
```bash
echo "[CHECKPOINT] Multi-phase setup complete"
echo "Context: WORKFLOW_ID=${WORKFLOW_ID}, TOPIC_DIR=${TOPIC_DIR}, REPORTS=${REPORTS_DIR}, PLANS=${PLANS_DIR}, COMPLEXITY=${COMPLEXITY}, ITERATION=${ITERATION}/5"
echo "Ready for: Wave 1 agent delegation (3 parallel agents)"
```

**Guideline**: Include only variables that help user understand workflow state or debug issues.

### Integration with State Persistence

Checkpoints complement but don't replace state persistence:

```bash
# Persist to state file (for cross-block access)
append_workflow_state "TOPIC_DIR" "$TOPIC_DIR"
append_workflow_state "COMPLEXITY" "$COMPLEXITY"

# Checkpoint for user visibility
echo "[CHECKPOINT] Setup complete"
echo "Context: TOPIC_DIR=${TOPIC_DIR}, COMPLEXITY=${COMPLEXITY}"
echo "Ready for: Agent delegation"
```

**Division of Labor**:
- **State Persistence**: All variables needed by subsequent bash blocks
- **Checkpoints**: User-facing summary of persisted state

### Anti-Patterns

**Anti-Pattern 1: Checkpoint Without Context**
```bash
# Bad: No context variables
echo "[CHECKPOINT] Setup complete"
echo "Ready for: Next phase"
```

**Anti-Pattern 2: Verbose Context**
```bash
# Bad: Multi-line descriptions
echo "[CHECKPOINT] Setup complete"
echo "Context: The workflow has been initialized with ID workflow_1234"
echo "and the topic directory is /path/to/topic which contains plans"
echo "Ready for: Agent delegation"
```

**Anti-Pattern 3: Implementation Details**
```bash
# Bad: Exposes internal bash block numbering
echo "[CHECKPOINT] Block 2 complete"
echo "Context: About to run Block 3"
echo "Ready for: Block 4 execution"
```

### Relationship to Console Summaries

**Checkpoints** (this section):
- Intermediate progress markers
- 3 lines per checkpoint
- Between bash blocks
- Context variables

**Console Summaries** (see [Console Summary Standards](#console-summary-standards)):
- Final completion message
- 15-25 lines total
- At workflow end
- Comprehensive artifacts listing

**Example Flow**:
```
[User runs /build plan.md]
  ↓
[CHECKPOINT] Setup complete
Context: WORKFLOW_ID=wf_123, PLAN_FILE=/path/plan.md
Ready for: Phase 1 implementation
  ↓
[Task tool invokes implementer]
  ↓
[CHECKPOINT] Phase 1 complete
Context: PHASE=1, FILES_MODIFIED=5
Ready for: Phase 2 implementation
  ↓
[...phases 2-5...]
  ↓
=== Build Complete ===
Summary: Implemented 5 phases across 23 files...
Artifacts:
  ✅ Summary: /path/summary.md
  ...
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

## Testing Strategy Section Format

Commands that write tests during implementation (e.g., /implement) should include a Testing Strategy section in their summary files to enable test-only execution by downstream commands (e.g., /test).

### Required Fields

The Testing Strategy section MUST include:

1. **Test Files Created**: List of test file paths with descriptions
2. **Test Execution Requirements**: Framework, test command, coverage target, expected tests
3. **Coverage Measurement**: How coverage is calculated

### Standard Format

```markdown
## Testing Strategy

### Test Files Created
- `/absolute/path/to/test_auth.sh` - Authentication unit tests (8 tests)
- `/absolute/path/to/test_api.sh` - API integration tests (12 tests)
- `/absolute/path/to/test_validation.sh` - Input validation tests (6 tests)

### Test Execution Requirements
- **Framework**: Bash test framework (existing .claude/tests/ patterns)
- **Test Command**: `bash test_auth.sh && bash test_api.sh && bash test_validation.sh`
- **Coverage Target**: 80%
- **Expected Tests**: 26 total tests (8 unit, 12 integration, 6 validation)

### Coverage Measurement
Coverage calculated via test execution output parsing. Each test file reports passed/failed counts.
```

### Field Descriptions

**Test Files Created**:
- Use absolute paths (not relative)
- Include test count and brief description
- List all test files in execution order

**Test Execution Requirements**:
- Framework: Test framework used (bash, pytest, jest, etc.)
- Test Command: Exact command to run all tests (must be runnable from project root)
- Coverage Target: Percentage threshold (default: 80%)
- Expected Tests: Total count and breakdown by type

**Coverage Measurement**:
- How coverage percentage is calculated
- Framework-specific coverage tools if applicable
- Fallback methods if coverage tool unavailable

### Parsing by Downstream Commands

Commands consuming Testing Strategy sections should use this parsing logic:

```bash
# Extract Testing Strategy section
TEST_STRATEGY=$(sed -n '/^## Testing Strategy$/,/^## /p' "$SUMMARY_FILE" | head -n -1)

# Extract test command
TEST_COMMAND=$(echo "$TEST_STRATEGY" | grep "^\*\*Test Command\*\*:" | sed 's/.*: //' | tr -d '`')

# Extract coverage target
COVERAGE_TARGET=$(echo "$TEST_STRATEGY" | grep "^\*\*Coverage Target\*\*:" | sed 's/.*: //' | tr -d '%')

# Extract test files
TEST_FILES=$(echo "$TEST_STRATEGY" | sed -n '/^### Test Files Created$/,/^###/p' | grep "^- \`" | sed 's/.*`\(.*\)`.*/\1/')

# Extract expected test count
EXPECTED_TESTS=$(echo "$TEST_STRATEGY" | grep "^\*\*Expected Tests\*\*:" | sed 's/.*: //' | grep -oE '[0-9]+' | head -1)
```

### Validation

Implementation commands should validate Testing Strategy section before returning:

```bash
# Check Testing Strategy section exists
if ! grep -q "^## Testing Strategy$" "$SUMMARY_FILE"; then
  echo "WARNING: Summary missing Testing Strategy section"
  echo "         /test command may not be able to execute tests"
fi

# Check required fields present
REQUIRED_FIELDS=("Test Files Created" "Test Command" "Coverage Target")
for field in "${REQUIRED_FIELDS[@]}"; do
  if ! grep -q "**${field}**:" "$SUMMARY_FILE"; then
    echo "WARNING: Testing Strategy missing required field: $field"
  fi
done
```

### Example: /implement → /test Workflow

**Step 1: /implement creates summary with Testing Strategy**
```bash
/implement specs/042_auth/plans/001_auth_plan.md
# Creates: specs/042_auth/summaries/001-iteration-1-implementation-summary.md
# Summary includes Testing Strategy section with test files and execution command
```

**Step 2: /test reads Testing Strategy and executes tests**
```bash
/test specs/042_auth/plans/001_auth_plan.md
# Auto-discovers summary: 001-iteration-1-implementation-summary.md
# Parses Testing Strategy section
# Runs test command with coverage loop
# Creates: outputs/test_results_iter1_*.md
```

### Anti-Patterns

**Incomplete Testing Strategy** (missing fields):
```markdown
## Testing Strategy

Tests are in test/ directory.
```
This lacks required fields and cannot be parsed by downstream commands.

**Relative Paths** (non-portable):
```markdown
### Test Files Created
- `../tests/test_auth.sh` - Authentication tests
```
Use absolute paths to avoid execution directory issues.

**Non-Runnable Test Command** (requires manual edits):
```markdown
- **Test Command**: `bash test_*.sh` (expand glob manually)
```
Provide exact, runnable command string.

### Related Documentation

- [Testing Protocols](testing-protocols.md) - Complete test writing and execution standards
- [Implement-Test Workflow Guide](./../../guides/workflows/implement-test-workflow.md) - Summary-based handoff patterns
- [Command Integration Patterns](command-authoring.md#command-integration-patterns) - Summary-based handoff implementation

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
