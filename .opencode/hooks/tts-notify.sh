#!/bin/bash
# TTS notification hook for Claude Code completion
# Announces WezTerm tab number via Piper TTS when Claude stops
#
# Integration: Called from Stop hook in .opencode/settings.json
# Requirements: piper-tts, aplay (alsa-utils), jq, wezterm
#
# Configuration:
#   PIPER_MODEL - Path to piper voice model (default: ~/.local/share/piper/en_US-lessac-medium.onnx)
#   TTS_COOLDOWN - Seconds between notifications (default: 10)
#   TTS_ENABLED - Set to "0" to disable (default: 1)

set -uo pipefail

# Configuration with defaults
PIPER_MODEL="${PIPER_MODEL:-$HOME/.local/share/piper/en_US-lessac-medium.onnx}"
TTS_COOLDOWN="${TTS_COOLDOWN:-10}"
TTS_ENABLED="${TTS_ENABLED:-1}"

# State files
LAST_NOTIFY_FILE="/tmp/claude-tts-last-notify"
LOG_FILE="/tmp/claude-tts-notify.log"

# Helper: log message
log() {
    echo "[$(date -Iseconds)] $1" >> "$LOG_FILE"
}

# Helper: return success JSON for Stop hook
exit_success() {
    echo '{}'
    exit 0
}

# Check if TTS is disabled
if [[ "$TTS_ENABLED" != "1" ]]; then
    exit_success
fi

# Check if piper is available
if ! command -v piper &>/dev/null; then
    log "piper command not found - skipping TTS notification"
    exit_success
fi

# Check if model exists
if [[ ! -f "$PIPER_MODEL" ]]; then
    log "Piper model not found at $PIPER_MODEL - skipping TTS notification"
    exit_success
fi

# Check cooldown (simple time-based)
if [[ -f "$LAST_NOTIFY_FILE" ]]; then
    LAST_TIME=$(cat "$LAST_NOTIFY_FILE" 2>/dev/null || echo "0")
    NOW=$(date +%s)
    ELAPSED=$((NOW - LAST_TIME))
    if (( ELAPSED < TTS_COOLDOWN )); then
        log "Cooldown active: ${ELAPSED}s < ${TTS_COOLDOWN}s - skipping notification"
        exit_success
    fi
fi

# Get WezTerm tab info
TAB_LABEL=""
if [[ -n "${WEZTERM_PANE:-}" ]] && command -v wezterm &>/dev/null; then
    # Get all panes data
    ALL_PANES=$(wezterm cli list --format=json 2>/dev/null)

    # Get the tab_id for the current pane
    CURRENT_TAB_ID=$(echo "$ALL_PANES" | jq -r ".[] | select(.pane_id == $WEZTERM_PANE) | .tab_id" 2>/dev/null || echo "")

    # Check if we got a valid tab_id (workaround for != escaping bug)
    if [[ -n "$CURRENT_TAB_ID" ]] && ! [[ "$CURRENT_TAB_ID" == "null" ]]; then
        # Get list of unique tab_ids in the order they appear
        # WezTerm lists panes in tab order, so first occurrence gives us the position
        UNIQUE_TAB_IDS=$(echo "$ALL_PANES" | jq -r '[.[].tab_id] | unique | .[]')

        # Find the position (0-indexed) of current tab
        TAB_INDEX=0
        POSITION=0
        while IFS= read -r tab_id; do
            if [[ "$tab_id" == "$CURRENT_TAB_ID" ]]; then
                POSITION=$TAB_INDEX
                break
            fi
            ((TAB_INDEX++))
        done <<< "$UNIQUE_TAB_IDS"

        # Convert to 1-indexed for display
        TAB_NUM=$((POSITION + 1))
        TAB_LABEL="Tab $TAB_NUM: "
    fi
fi

# Simple message: just "Tab N"
MESSAGE="${TAB_LABEL%: }"  # Strip ": " suffix if present
if [[ -z "$MESSAGE" ]]; then
    MESSAGE="Tab"  # Fallback if tab detection failed
fi

# Speak using piper with paplay (background, tolerant of errors)
if command -v paplay &>/dev/null; then
    # paplay available (PulseAudio) - need to write to temp file first
    TEMP_WAV="/tmp/claude-tts-$$.wav"
    (timeout 10s bash -c "echo '$MESSAGE' | piper --model '$PIPER_MODEL' --output_file '$TEMP_WAV' 2>/dev/null && paplay '$TEMP_WAV' 2>/dev/null; rm -f '$TEMP_WAV'" &) || true
elif command -v aplay &>/dev/null; then
    # aplay available (ALSA)
    (timeout 10s bash -c "echo '$MESSAGE' | piper --model '$PIPER_MODEL' --output_file - 2>/dev/null | aplay -q 2>/dev/null" &) || true
else
    log "No audio player found (aplay or paplay) - skipping TTS notification"
    exit_success
fi

# Update cooldown timestamp
date +%s > "$LAST_NOTIFY_FILE"

log "Notification sent: $MESSAGE"

exit_success
