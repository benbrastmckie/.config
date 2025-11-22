# Orchestrator Command Standards Research Report

## Metadata
- **Date**: 2025-11-21
- **Agent**: research-specialist
- **Topic**: Common patterns across /build, /plan, /debug orchestrator commands
- **Report Type**: pattern recognition

## Executive Summary

Analysis of /build, /plan, and /debug commands reveals a consistent 5-section structure with state machine integration, behavioral injection for agent invocation, and fail-fast verification patterns. These standards should be applied to /convert-docs to ensure uniformity across orchestrator commands and enable features like checkpoint resume, error logging, and progress tracking.

## Findings

### 1. Command Structure Standard (5 Sections)

**Source**: `/home/benjamin/.config/.claude/docs/guides/orchestration/creating-orchestrator-commands.md` (lines 18-36)

Every orchestrator command follows a five-section structure:

1. **YAML Frontmatter** - metadata and dependencies
2. **Workflow Description Capture** - argument parsing and validation
3. **State Machine Initialization** - library sourcing and sm_init
4. **Phase Implementations** - workflow-specific phases
5. **Terminal State Handling** - completion and cleanup

### 2. YAML Frontmatter Pattern

**Source**: `/home/benjamin/.config/.claude/commands/build.md` (lines 1-13), `/home/benjamin/.config/.claude/commands/plan.md` (lines 1-14), `/home/benjamin/.config/.claude/commands/debug.md` (lines 1-14)

Standard frontmatter elements:

```yaml
---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob
argument-hint: <description> [--options]
description: One-line workflow description
command-type: primary
dependent-agents:
  - agent-name-1
  - agent-name-2
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
documentation: See .claude/docs/guides/commands/command-guide.md
---
```

### 3. Three-Tier Library Sourcing Pattern

**Source**: `/home/benjamin/.config/.claude/commands/build.md` (lines 76-100), `/home/benjamin/.config/.claude/docs/guides/commands/build-command-guide.md` (lines 119-141)

Each bash block must re-source libraries due to subprocess isolation:

```bash
# Tier 1: Critical Foundation (fail-fast required)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Tier 2: Workflow Support (graceful degradation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/checkpoint-utils.sh" 2>/dev/null || true

# Tier 3: Command-Specific (optional)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || true
```

### 4. State Machine Integration

**Source**: `/home/benjamin/.config/.claude/commands/build.md` (lines 216-298), `/home/benjamin/.config/.claude/docs/guides/orchestration/creating-orchestrator-commands.md` (lines 83-131)

State machine initialization pattern:

```bash
# Hardcode workflow type (no LLM classification)
WORKFLOW_TYPE="research-and-plan"  # or "full-implementation", "debug-only"
TERMINAL_STATE="plan"  # or "complete", "debug"
COMMAND_NAME="/command"

WORKFLOW_ID="${COMMAND_NAME}_$(date +%s)"

# Initialize state machine with 5 parameters
sm_init \
  "$WORKFLOW_DESCRIPTION" \
  "$COMMAND_NAME" \
  "$WORKFLOW_TYPE" \
  "$RESEARCH_COMPLEXITY" \
  "{}"  # research topics JSON
```

State transitions:
```bash
sm_transition "$STATE_RESEARCH"  # → sm_transition "$STATE_PLAN" → etc.
save_completed_states_to_state   # Persist after every transition
```

### 5. Imperative Agent Invocation (Standard 11)

**Source**: `/home/benjamin/.config/.claude/docs/guides/orchestration/creating-orchestrator-commands.md` (lines 237-278)

All agent invocations use imperative patterns:

```markdown
**EXECUTE NOW**: USE the Task tool to invoke [agent-name] agent.

Task {
  subagent_type: "general-purpose"
  description: "[5-10 word description]"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/[agent-name].md

    **Workflow-Specific Context**:
    - Input: ...
    - Output: ...

    Return: COMPLETION_SIGNAL: [path]
  "
}
```

**Key Requirements**:
- "EXECUTE NOW: USE the Task tool" directive
- NO YAML code block wrappers
- Reference agent behavioral file explicitly
- Require completion signal

### 6. Error Logging Integration

**Source**: `/home/benjamin/.config/.claude/commands/build.md` (lines 90-96, 253-278)

Every command initializes error logging:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
ensure_error_log_exists

# Set command metadata
COMMAND_NAME="/command"
USER_ARGS="$*"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

Error logging on failures:
```bash
log_command_error \
  "$COMMAND_NAME" \
  "$WORKFLOW_ID" \
  "$USER_ARGS" \
  "state_error" \
  "Description of error" \
  "bash_block_N" \
  "$(jq -n --arg state "$STATE" '{target_state: $state}')"
```

### 7. Console Summary Pattern

**Source**: `/home/benjamin/.config/.claude/commands/build.md` (lines 1519-1563)

Standardized completion summary:

```bash
# Source summary formatting library
source "${CLAUDE_LIB}/core/summary-formatting.sh" 2>/dev/null || {
  echo "ERROR: Failed to load summary-formatting library" >&2
  exit 1
}

# Build sections
SUMMARY_TEXT="..."
PHASES="  - Phase 1: Complete\n  - Phase 2: Complete"
ARTIFACTS="  - Plan: $PLAN_PATH\n  - Summary: $SUMMARY_PATH"
NEXT_STEPS="  - Review: cat $PATH\n  - Build: /build $PATH"

# Print standardized summary
print_artifact_summary "Command" "$SUMMARY_TEXT" "$PHASES" "$ARTIFACTS" "$NEXT_STEPS"
```

### 8. Fail-Fast Verification Pattern

**Source**: `/home/benjamin/.config/.claude/docs/guides/orchestration/creating-orchestrator-commands.md` (lines 369-409)

After agent invocation:

```bash
# FAIL-FAST VERIFICATION (no fallback, exit 1 on failure)
if [ ! -d "$EXPECTED_DIR" ] || [ -z "$(find "$EXPECTED_DIR" -name '*.md' 2>/dev/null)" ]; then
  echo "ERROR: Phase failed to create expected artifacts" >&2
  echo "DIAGNOSTIC: Expected directory: $EXPECTED_DIR" >&2
  exit 1
fi
```

**Philosophy**:
- No retry logic
- No fallback mechanisms
- No graceful degradation
- Exit with code 1 immediately
- Clear diagnostic messages

## Application to /convert-docs

### Current Gaps

Based on the existing plan (`001_convert_docs_fidelity_llm_practices_plan.md`), /convert-docs does NOT currently implement:

1. State machine integration (no sm_init, sm_transition)
2. Three-tier library sourcing pattern
3. Error logging integration
4. Console summary formatting
5. Checkpoint/resume capability

### Required Changes

To align with orchestrator standards, /convert-docs should add:

1. **YAML Frontmatter** with library-requirements
2. **State machine initialization** for tracking conversion progress
3. **Error logging** for queryable failure tracking
4. **Console summary** using print_artifact_summary()
5. **Checkpoint support** for large batch conversions

## Recommendations

### Recommendation 1: Add Standard YAML Frontmatter

```yaml
---
allowed-tools: Task, Bash, Read, Write
argument-hint: <input-dir> <output-dir> [--no-api]
description: Convert documents between Markdown, DOCX, and PDF formats
command-type: primary
dependent-agents:
  - document-converter (skill)
library-requirements:
  - error-handling.sh: ">=1.0.0"
documentation: See .claude/docs/guides/commands/convert-docs-command-guide.md
---
```

### Recommendation 2: Implement Three-Tier Library Sourcing

Even though /convert-docs is simpler than /build, it should follow the sourcing pattern for consistency:

```bash
# Tier 1: Critical Foundation (fail-fast required)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Tier 2: Conversion Support (critical for conversion)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/convert/convert-core.sh" 2>/dev/null || {
  echo "ERROR: Failed to source convert-core.sh" >&2
  exit 1
}
```

### Recommendation 3: Add Error Logging Integration

```bash
ensure_error_log_exists
COMMAND_NAME="/convert-docs"
USER_ARGS="$INPUT_DIR $OUTPUT_DIR"
WORKFLOW_ID="convert_$(date +%s)"
export COMMAND_NAME USER_ARGS WORKFLOW_ID
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

### Recommendation 4: Add Console Summary

After conversion completion:
```bash
source "${CLAUDE_LIB}/core/summary-formatting.sh" 2>/dev/null || exit 1

SUMMARY_TEXT="Converted $SUCCESS_COUNT of $TOTAL_COUNT documents in ${CONVERSION_MODE} mode."
ARTIFACTS="  - Output: $OUTPUT_DIR ($SUCCESS_COUNT files)"
NEXT_STEPS="  - Review: ls -lh $OUTPUT_DIR\n  - Check log: cat $OUTPUT_DIR/conversion.log"

print_artifact_summary "Convert" "$SUMMARY_TEXT" "" "$ARTIFACTS" "$NEXT_STEPS"
```

## References

- `/home/benjamin/.config/.claude/commands/build.md` (lines 1-13, 76-100, 216-298, 1519-1563)
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 1-14, 118-146)
- `/home/benjamin/.config/.claude/commands/debug.md` (lines 1-14, 168-222)
- `/home/benjamin/.config/.claude/docs/guides/orchestration/creating-orchestrator-commands.md` (lines 18-36, 83-131, 237-278, 369-409)
- `/home/benjamin/.config/.claude/docs/guides/commands/build-command-guide.md` (lines 119-141)
- `/home/benjamin/.config/.claude/docs/guides/orchestration/orchestration-troubleshooting.md` (lines 119-145)
