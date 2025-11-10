---
allowed-tools: [List, Your, Tools, Here]
argument-hint: <required-arg> [optional-arg]
description: Brief one-line description of what this command does
---

# /command-name - Brief Title

YOU ARE EXECUTING AS the [command-name] command.

**Documentation**: See `.claude/docs/guides/command-name-command-guide.md` for complete architecture, usage examples, and troubleshooting.

---

## Phase 0: Initialization

[EXECUTION-CRITICAL: Execute this bash block immediately]

```bash
set +H  # Disable history expansion to prevent bad substitution errors
# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Phase 0 logic here
# Inline comments explain WHAT is being done, not WHY (WHY belongs in guide)
echo "Phase 0: Initialization complete"
```

---

## Phase 1: [Second Phase Name]

[EXECUTION-CRITICAL: Execute next phase]

```bash
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
# Add only the libraries your command needs from this list:
# source "${LIB_DIR}/workflow-state-machine.sh"
# source "${LIB_DIR}/state-persistence.sh"
# source "${LIB_DIR}/workflow-initialization.sh"
# source "${LIB_DIR}/error-handling.sh"
# source "${LIB_DIR}/unified-logger.sh"  # Provides emit_progress and logging functions
# source "${LIB_DIR}/verification-helpers.sh"

# Phase 1 logic here
echo "Phase 1: [Phase name] complete"
```

---

## Phase N: [Final Phase Name]

[EXECUTION-CRITICAL: Final phase execution]

```bash
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
# Add only the libraries your command needs from this list:
# source "${LIB_DIR}/workflow-state-machine.sh"
# source "${LIB_DIR}/state-persistence.sh"
# source "${LIB_DIR}/workflow-initialization.sh"
# source "${LIB_DIR}/error-handling.sh"
# source "${LIB_DIR}/unified-logger.sh"  # Provides emit_progress and logging functions
# source "${LIB_DIR}/verification-helpers.sh"

# Final phase logic
echo "All phases complete"
```

---

**Troubleshooting**: See `.claude/docs/guides/command-name-command-guide.md` for common issues and solutions.
