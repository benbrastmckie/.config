#!/bin/bash
# WezTerm task number hook for Claude Code
# Sets TASK_NUMBER user variable via OSC 1337 when Claude commands include task numbers
#
# Integration: Called from UserPromptSubmit hook in .claude/settings.json
# Requirements: wezterm with user variable support, jq for JSON parsing
#
# Parses prompts for /research N, /plan N, /implement N, /revise N patterns
# and sets/clears the TASK_NUMBER user variable accordingly.
#
# Note: Claude Code hooks run with redirected stdio (stdout is a socket),
# so we must write the escape sequence directly to the pane's TTY.

set -euo pipefail

# Helper: return success JSON for hook
exit_success() {
    echo '{}'
    exit 0
}

# Only run in WezTerm
if [[ -z "${WEZTERM_PANE:-}" ]]; then
    exit_success
fi

# Get user prompt from Claude Code hook input
PROMPT="${CLAUDE_USER_PROMPT:-}"

# Extract task number from Claude commands
# Matches: /research N, /plan N, /implement N, /revise N
TASK_NUMBER=""
if [[ "$PROMPT" =~ ^[[:space:]]*/?(research|plan|implement|revise)[[:space:]]+([0-9]+) ]]; then
    TASK_NUMBER="${BASH_REMATCH[2]}"
fi

# Get the TTY for the current pane from WezTerm CLI
# Claude Code hooks have redirected stdio, so we cannot use /dev/tty
PANE_TTY=$(wezterm cli list --format=json 2>/dev/null | \
    jq -r ".[] | select(.pane_id == $WEZTERM_PANE) | .tty_name" 2>/dev/null || echo "")

# Check if we found a writable TTY
if [[ -z "$PANE_TTY" ]] || [[ ! -w "$PANE_TTY" ]]; then
    exit_success
fi

if [[ -n "$TASK_NUMBER" ]]; then
    # Set TASK_NUMBER user variable via OSC 1337
    # Format: OSC 1337 ; SetUserVar=name=base64_value ST
    TASK_VALUE=$(echo -n "$TASK_NUMBER" | base64 | tr -d '\n')
    printf '\033]1337;SetUserVar=TASK_NUMBER=%s\007' "$TASK_VALUE" > "$PANE_TTY"
fi
# Note: We don't clear TASK_NUMBER when pattern doesn't match to allow
# persistence during Claude Code sessions. The Neovim integration (task 791)
# handles clearing on terminal close. This prevents conflicts between the
# shell hook and Neovim's task number monitoring.

exit_success
