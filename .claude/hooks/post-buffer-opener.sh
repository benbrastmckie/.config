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

# === ANSI Code Stripping ===
# Strip ANSI escape codes from input for reliable pattern matching
# Handles: colors (\e[31m), cursor movement (\e[1A), reset (\e[0m), OSC sequences, etc.
# Terminal buffers contain these codes which break regex pattern matching
strip_ansi() {
  # Remove CSI sequences (colors, cursor, etc.) and OSC sequences (title, etc.)
  sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' | sed 's/\x1b\][0-9]*;[^\x07]*\x07//g'
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

# === Stop Hook Timing and Multi-Block Execution ===
# CRITICAL INSIGHT: The Stop hook fires when Claude FINISHES RESPONDING, not when bash blocks finish executing.
#
# Execution Timeline:
#   1. Command starts (Block 1a-1c: setup, state init, topic naming)
#   2. Task tool delegation (Block 1d: invoke research-specialist/plan-architect/etc.)
#   3. Claude finishes responding → Stop hook fires ← WE ARE HERE
#   4. [After Claude's response] Block 2 executes (verification and signal output: "REPORT_CREATED: path")
#
# Problem: Stop hook fires at step 3, but REPORT_CREATED signal is output in step 4
# Solution: Wait for Block 2 to execute before reading terminal buffer
#
# The BUFFER_OPENER_DELAY provides time for multi-block commands to complete execution
# and flush their completion signals to the terminal buffer.
#
# Configuration:
#   BUFFER_OPENER_DELAY=0.3  # Default: 300ms delay (suitable for most systems)
#   BUFFER_OPENER_DELAY=0.2  # Fast systems with local Neovim
#   BUFFER_OPENER_DELAY=0.5  # Slower systems or heavy load
#   BUFFER_OPENER_DELAY=0.8  # Remote/SSH connections
#   BUFFER_OPENER_DELAY=0    # Disable delay (diagnostic mode - expect failures)

# Apply delay before reading terminal buffer (if enabled)
DELAY="${BUFFER_OPENER_DELAY:-0.3}"
if [[ "$DELAY" != "0" ]] && [[ "$DELAY" != "0.0" ]]; then
  debug_log "Applying ${DELAY}s delay before reading terminal buffer (allows Block 2 execution)"
  sleep "$DELAY"
else
  debug_log "Delay disabled (BUFFER_OPENER_DELAY=0) - reading terminal immediately"
fi

# === Access terminal buffer output via Neovim RPC ===
# Get the last 100 lines of terminal output (sufficient for completion signals)
TERMINAL_OUTPUT=$(timeout 5 nvim --server "$NVIM" --remote-expr 'join(getbufline(bufnr("%"), max([1, line("$")-100]), "$"), "\n")' 2>/dev/null)

if [[ -z "$TERMINAL_OUTPUT" ]]; then
  debug_log "Failed to get terminal output"
  exit 0
fi

debug_log "Got terminal output (${#TERMINAL_OUTPUT} chars)"

# === Strip ANSI codes for reliable pattern matching ===
# Terminal buffer contains ANSI escape codes that break regex extraction
CLEAN_OUTPUT=$(echo "$TERMINAL_OUTPUT" | strip_ansi)
ANSI_BYTES_REMOVED=$((${#TERMINAL_OUTPUT} - ${#CLEAN_OUTPUT}))
debug_log "Cleaned terminal output (${#CLEAN_OUTPUT} chars, removed $ANSI_BYTES_REMOVED ANSI bytes)"

# === Diagnostic: Dump terminal output line-by-line to debug log ===
# This helps diagnose timing issues where Block 2 may not have executed yet
if [[ "${BUFFER_OPENER_DEBUG:-false}" == "true" ]]; then
  debug_log "=== TERMINAL OUTPUT DUMP BEGIN ==="
  debug_log "Total lines in terminal output:"
  line_count=0
  while IFS= read -r line; do
    ((line_count++))
    debug_log "Line $line_count: $line"
  done <<< "$TERMINAL_OUTPUT"
  debug_log "Total lines dumped: $line_count"
  debug_log "=== TERMINAL OUTPUT DUMP END ==="

  # Check for Block execution markers
  debug_log "=== BLOCK EXECUTION MARKERS ==="
  if echo "$TERMINAL_OUTPUT" | grep -q "Block 1d"; then
    debug_log "✓ Block 1d PRESENT (Task tool delegation)"
  else
    debug_log "✗ Block 1d ABSENT"
  fi

  if echo "$TERMINAL_OUTPUT" | grep -q "Verifying research artifacts"; then
    debug_log "✓ Block 2 PRESENT (Verification and signal output)"
  else
    debug_log "✗ Block 2 ABSENT (This confirms timing race - Block 2 hasn't executed yet)"
  fi

  # Check for REPORT_CREATED signal
  debug_log "=== COMPLETION SIGNAL CHECK ==="
  if echo "$TERMINAL_OUTPUT" | grep -q "REPORT_CREATED:"; then
    debug_log "✓ REPORT_CREATED signal PRESENT"
  else
    debug_log "✗ REPORT_CREATED signal ABSENT (Expected if Block 2 hasn't executed)"
  fi

  if echo "$TERMINAL_OUTPUT" | grep -q "PLAN_CREATED:"; then
    debug_log "✓ PLAN_CREATED signal PRESENT"
  else
    debug_log "✗ PLAN_CREATED signal ABSENT"
  fi
  debug_log "=== DIAGNOSTIC CHECKS COMPLETE ==="
fi

# === Extract completion signals with priority logic ===
# Uses CLEAN_OUTPUT (ANSI-stripped) for reliable pattern matching
# Includes fallback patterns for robustness

# Helper function: Extract path with primary and fallback patterns
# Returns path if valid file exists, empty otherwise
extract_signal_path() {
  local signal_name="$1"
  local input="$2"
  local path=""

  # Primary: Perl regex (grep -oP) - fast and precise
  path=$(echo "$input" | grep -oP "${signal_name}:\s*\K[^\s]+" 2>/dev/null | tail -1)

  # Fallback: sed-based extraction if grep -oP fails or returns empty
  if [[ -z "$path" ]]; then
    path=$(echo "$input" | sed -n "s/.*${signal_name}:[[:space:]]*\([^[:space:]]*\).*/\1/p" | tail -1)
    if [[ -n "$path" ]]; then
      debug_log "Used sed fallback for $signal_name"
    fi
  fi

  # Validate path exists as a file
  if [[ -n "$path" ]] && [[ -f "$path" ]]; then
    echo "$path"
    return
  fi

  # Path might have trailing garbage - try cleaning it
  if [[ -n "$path" ]]; then
    local cleaned_path="${path%%[^/a-zA-Z0-9._-]*}"
    if [[ -n "$cleaned_path" ]] && [[ -f "$cleaned_path" ]]; then
      debug_log "Cleaned path: $path -> $cleaned_path"
      echo "$cleaned_path"
      return
    fi
  fi

  # No valid path found
  echo ""
}

# Priority 1: PLAN_CREATED or PLAN_REVISED (highest)
ARTIFACT_PATH=""

# Check for PLAN_CREATED (highest priority)
if [[ -z "$ARTIFACT_PATH" ]]; then
  PLAN_PATH=$(extract_signal_path "PLAN_CREATED" "$CLEAN_OUTPUT")
  if [[ -n "$PLAN_PATH" ]]; then
    ARTIFACT_PATH="$PLAN_PATH"
    debug_log "Found PLAN_CREATED: $ARTIFACT_PATH"
  fi
fi

# Check for PLAN_REVISED (same priority as PLAN_CREATED)
if [[ -z "$ARTIFACT_PATH" ]]; then
  REVISED_PATH=$(extract_signal_path "PLAN_REVISED" "$CLEAN_OUTPUT")
  if [[ -n "$REVISED_PATH" ]]; then
    ARTIFACT_PATH="$REVISED_PATH"
    debug_log "Found PLAN_REVISED: $ARTIFACT_PATH"
  fi
fi

# Priority 2: IMPLEMENTATION_COMPLETE with summary_path (for /build)
if [[ -z "$ARTIFACT_PATH" ]]; then
  SUMMARY_PATH=$(extract_signal_path "summary_path" "$CLEAN_OUTPUT")
  if [[ -n "$SUMMARY_PATH" ]]; then
    ARTIFACT_PATH="$SUMMARY_PATH"
    debug_log "Found summary_path: $ARTIFACT_PATH"
  fi
fi

# Priority 3: DEBUG_REPORT_CREATED
if [[ -z "$ARTIFACT_PATH" ]]; then
  DEBUG_PATH=$(extract_signal_path "DEBUG_REPORT_CREATED" "$CLEAN_OUTPUT")
  if [[ -n "$DEBUG_PATH" ]]; then
    ARTIFACT_PATH="$DEBUG_PATH"
    debug_log "Found DEBUG_REPORT_CREATED: $ARTIFACT_PATH"
  fi
fi

# Priority 4: REPORT_CREATED (lowest - research reports)
if [[ -z "$ARTIFACT_PATH" ]]; then
  REPORT_PATH=$(extract_signal_path "REPORT_CREATED" "$CLEAN_OUTPUT")
  if [[ -n "$REPORT_PATH" ]]; then
    ARTIFACT_PATH="$REPORT_PATH"
    debug_log "Found REPORT_CREATED: $ARTIFACT_PATH"
  fi
fi

# === Validate artifact path ===
# Note: extract_signal_path already validates file existence
if [[ -z "$ARTIFACT_PATH" ]]; then
  debug_log "No completion signal found in output (checked CLEAN_OUTPUT with $ANSI_BYTES_REMOVED ANSI bytes removed)"
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
