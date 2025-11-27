#!/usr/bin/env bash
# Post-Buffer-Opener Hook
# Purpose: Automatically open primary workflow artifacts in Neovim after command completion
#
# DESIGN PHILOSOPHY: Zero Overhead Outside Neovim
#   This hook follows fail-fast, fail-silent design. When running outside Neovim,
#   it exits immediately (< 1ms) with no side effects. No JSON parsing, no file I/O,
#   no RPC attempts. Claude Code works identically with or without this hook.
#
# One-File Guarantee: Hook ensures at most one buffer opens per command execution
#
# Zero Undo Impact: Opening a new buffer does not affect existing buffers' undo trees
#
# Architecture:
#   0. FIRST: Check $NVIM environment variable - exit 0 immediately if unset
#   1. Check BUFFER_OPENER_ENABLED - exit 0 if explicitly disabled
#   2. Parse JSON input to get command name and status
#   3. Access terminal buffer output via Neovim RPC
#   4. Extract ALL completion signals from output
#   5. Apply priority logic to select PRIMARY artifact only (one file)
#   6. Open selected artifact in Neovim via RPC
#
# Priority Logic:
#   PLAN_CREATED/PLAN_REVISED (priority 1) > IMPLEMENTATION_COMPLETE/summary_path (priority 2) >
#   DEBUG_REPORT_CREATED (priority 3) > REPORT_CREATED (priority 4)
#
#   Example: /optimize-claude creates 4 REPORT_CREATED + 1 PLAN_CREATED
#            -> Hook opens ONLY the plan (priority 1 wins)
#   Example: /build returns IMPLEMENTATION_COMPLETE with summary_path: /path/to/summary.md
#            -> Hook extracts and opens the summary path
#
# Requirements (only when running inside Neovim terminal):
#   - $NVIM environment variable (set automatically by Neovim terminal)
#   - nvim command in PATH
#   - Command must output completion signal (PLAN_CREATED, etc.)
#
# Configuration:
#   - Set BUFFER_OPENER_ENABLED=false to disable
#   - Set BUFFER_OPENER_DEBUG=true for debug logging

# === FAIL-FAST: Exit immediately if not in Neovim terminal ===
# This check MUST be first - ensures zero overhead when running outside Neovim
[[ -z "${NVIM:-}" ]] && exit 0

# === Feature toggle check ===
[[ "${BUFFER_OPENER_ENABLED:-true}" == "false" ]] && exit 0

# === Debug logging function (only if enabled) ===
debug_log() {
  if [[ "${BUFFER_OPENER_DEBUG:-false}" == "true" ]]; then
    local log_file="${CLAUDE_PROJECT_DIR:-.}/.claude/tmp/buffer-opener-debug.log"
    mkdir -p "$(dirname "$log_file")" 2>/dev/null
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$log_file"
  fi
}

debug_log "Hook triggered, NVIM=$NVIM"

# === Parse JSON input from Claude Code ===
# Stop hook receives JSON event on stdin:
# {"hook_event_name":"Stop","command":"/plan","status":"success","cwd":"..."}
EVENT_JSON=$(cat)

debug_log "Received JSON: $EVENT_JSON"

# Extract fields using jq if available, otherwise fallback
if command -v jq &>/dev/null; then
  HOOK_EVENT=$(echo "$EVENT_JSON" | jq -r '.hook_event_name // ""' 2>/dev/null)
  COMMAND=$(echo "$EVENT_JSON" | jq -r '.command // ""' 2>/dev/null)
  STATUS=$(echo "$EVENT_JSON" | jq -r '.status // ""' 2>/dev/null)
else
  # Fallback to basic parsing if jq not available
  HOOK_EVENT=$(echo "$EVENT_JSON" | grep -o '"hook_event_name":"[^"]*"' | cut -d'"' -f4)
  COMMAND=$(echo "$EVENT_JSON" | grep -o '"command":"[^"]*"' | cut -d'"' -f4)
  STATUS=$(echo "$EVENT_JSON" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
fi

debug_log "Parsed: hook_event=$HOOK_EVENT, command=$COMMAND, status=$STATUS"

# === Eligibility checks ===
# Only process Stop events with success status
[[ "$HOOK_EVENT" != "Stop" ]] && exit 0
[[ "$STATUS" != "success" ]] && exit 0

# Only process workflow commands that produce artifacts
case "$COMMAND" in
  /plan|/research|/build|/debug|/repair|/revise|/optimize-claude|/errors)
    debug_log "Eligible command: $COMMAND"
    ;;
  *)
    debug_log "Skipping non-artifact command: $COMMAND"
    exit 0
    ;;
esac

# === Access terminal buffer output via Neovim RPC ===
# Get the last 100 lines of terminal output (sufficient for completion signals)
TERMINAL_OUTPUT=$(timeout 5 nvim --server "$NVIM" --remote-expr 'join(getbufline(bufnr("%"), max([1, line("$")-100]), "$"), "\n")' 2>/dev/null)

if [[ -z "$TERMINAL_OUTPUT" ]]; then
  debug_log "Failed to get terminal output"
  exit 0
fi

debug_log "Got terminal output (${#TERMINAL_OUTPUT} chars)"

# === Extract completion signals with priority logic ===
# Priority 1: PLAN_CREATED or PLAN_REVISED (highest)
ARTIFACT_PATH=""

# Check for PLAN_CREATED (highest priority)
if [[ -z "$ARTIFACT_PATH" ]]; then
  PLAN_PATH=$(echo "$TERMINAL_OUTPUT" | grep -oP 'PLAN_CREATED:\s*\K[^\s]+' | tail -1)
  if [[ -n "$PLAN_PATH" ]]; then
    ARTIFACT_PATH="$PLAN_PATH"
    debug_log "Found PLAN_CREATED: $ARTIFACT_PATH"
  fi
fi

# Check for PLAN_REVISED (same priority as PLAN_CREATED)
if [[ -z "$ARTIFACT_PATH" ]]; then
  REVISED_PATH=$(echo "$TERMINAL_OUTPUT" | grep -oP 'PLAN_REVISED:\s*\K[^\s]+' | tail -1)
  if [[ -n "$REVISED_PATH" ]]; then
    ARTIFACT_PATH="$REVISED_PATH"
    debug_log "Found PLAN_REVISED: $ARTIFACT_PATH"
  fi
fi

# Priority 2: IMPLEMENTATION_COMPLETE with summary_path (for /build)
if [[ -z "$ARTIFACT_PATH" ]]; then
  # /build returns multi-line format with summary_path field
  SUMMARY_PATH=$(echo "$TERMINAL_OUTPUT" | grep -oP 'summary_path:\s*\K[^\s]+' | tail -1)
  if [[ -n "$SUMMARY_PATH" ]]; then
    ARTIFACT_PATH="$SUMMARY_PATH"
    debug_log "Found summary_path: $ARTIFACT_PATH"
  fi
fi

# Priority 3: DEBUG_REPORT_CREATED
if [[ -z "$ARTIFACT_PATH" ]]; then
  DEBUG_PATH=$(echo "$TERMINAL_OUTPUT" | grep -oP 'DEBUG_REPORT_CREATED:\s*\K[^\s]+' | tail -1)
  if [[ -n "$DEBUG_PATH" ]]; then
    ARTIFACT_PATH="$DEBUG_PATH"
    debug_log "Found DEBUG_REPORT_CREATED: $ARTIFACT_PATH"
  fi
fi

# Priority 4: REPORT_CREATED (lowest - research reports)
if [[ -z "$ARTIFACT_PATH" ]]; then
  REPORT_PATH=$(echo "$TERMINAL_OUTPUT" | grep -oP 'REPORT_CREATED:\s*\K[^\s]+' | tail -1)
  if [[ -n "$REPORT_PATH" ]]; then
    ARTIFACT_PATH="$REPORT_PATH"
    debug_log "Found REPORT_CREATED: $ARTIFACT_PATH"
  fi
fi

# === Validate artifact path ===
if [[ -z "$ARTIFACT_PATH" ]]; then
  debug_log "No completion signal found in output"
  exit 0
fi

# Validate file exists
if [[ ! -f "$ARTIFACT_PATH" ]]; then
  debug_log "Artifact file not found: $ARTIFACT_PATH"
  exit 0
fi

debug_log "Valid artifact: $ARTIFACT_PATH"

# === Open artifact in Neovim via RPC ===
# Use vim.schedule to safely open buffer from terminal context
# The Lua module handles context detection (vsplit in terminal, edit otherwise)

# Escape path for Lua string
ESCAPED_PATH=$(printf '%q' "$ARTIFACT_PATH")

# Try to use the buffer-opener module if available, otherwise fallback to basic vsplit
OPEN_CMD="pcall(function()
  local ok, opener = pcall(require, 'neotex.plugins.ai.claude.util.buffer-opener')
  if ok and opener and opener.open_artifact then
    opener.open_artifact('$ARTIFACT_PATH')
  else
    vim.cmd('vsplit ' .. vim.fn.fnameescape('$ARTIFACT_PATH'))
  end
end)"

# Execute via nvim remote-send (non-blocking)
timeout 5 nvim --server "$NVIM" --remote-send "<C-\\><C-n>:lua vim.schedule(function() $OPEN_CMD end)<CR>" 2>/dev/null

if [[ $? -eq 0 ]]; then
  debug_log "Successfully sent open command for: $ARTIFACT_PATH"
else
  debug_log "Failed to send open command"
fi

# Always exit successfully (non-blocking hook)
exit 0
