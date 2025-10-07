#!/usr/bin/env bash
# TTS Dispatcher Hook
#
# Central dispatcher for all TTS notifications in Claude Code workflow.
# Routes hook events to appropriate message generators and speaks messages
# using espeak-ng with category-specific voice characteristics.
#
# Hook Integration:
#   This script is designed to be called from various Claude Code hooks:
#   - Stop: Completion and error notifications
#   - SessionStart/SessionEnd: Session lifecycle
#   - SubagentStop: Progress updates
#   - Notification: Permission requests and idle reminders
#   - PreToolUse/PostToolUse: Tool execution (optional)
#   - UserPromptSubmit: Prompt acknowledgments (optional)
#   - PreCompact: Context compaction warnings (optional)
#
# Execution:
#   Always runs asynchronously (background) to avoid blocking workflow.
#   Exits 0 always for non-blocking behavior.
#   Fails silently if TTS unavailable or disabled.
#
# Environment Variables:
#   HOOK_EVENT - Hook event type (Stop, SessionStart, etc.)
#   CLAUDE_PROJECT_DIR - Project directory
#   CLAUDE_COMMAND - Command being executed
#   CLAUDE_STATUS - Command status
#   See tts-messages.sh for complete list

set -eo pipefail

# ============================================================================
# Hook Input Parsing
# ============================================================================

# Read JSON input from stdin (Claude Code passes hook data as JSON)
HOOK_INPUT=$(cat)

# Parse hook event name and other fields from JSON
# Uses jq if available, otherwise falls back to grep/sed
if command -v jq &>/dev/null; then
  HOOK_EVENT=$(echo "$HOOK_INPUT" | jq -r '.hook_event_name // "unknown"')
  CLAUDE_COMMAND=$(echo "$HOOK_INPUT" | jq -r '.command // ""')
  CLAUDE_STATUS=$(echo "$HOOK_INPUT" | jq -r '.status // "success"')
  CLAUDE_PROJECT_DIR=$(echo "$HOOK_INPUT" | jq -r '.cwd // ""')
  NOTIFICATION_MESSAGE=$(echo "$HOOK_INPUT" | jq -r '.message // ""')
else
  # Fallback parsing without jq
  HOOK_EVENT=$(echo "$HOOK_INPUT" | grep -o '"hook_event_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)".*/\1/' || echo "unknown")
  CLAUDE_COMMAND=$(echo "$HOOK_INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)".*/\1/' || echo "")
  CLAUDE_STATUS=$(echo "$HOOK_INPUT" | grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)".*/\1/' || echo "success")
  CLAUDE_PROJECT_DIR=$(echo "$HOOK_INPUT" | grep -o '"cwd"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)".*/\1/' || echo "")
  NOTIFICATION_MESSAGE=$(echo "$HOOK_INPUT" | grep -o '"message"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)".*/\1/' || echo "")
fi

# Export for use by message generation functions
export HOOK_EVENT CLAUDE_COMMAND CLAUDE_STATUS CLAUDE_PROJECT_DIR NOTIFICATION_MESSAGE

# ============================================================================
# Configuration and Setup
# ============================================================================

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration and message library
CONFIG_FILE="$CLAUDE_DIR/tts/tts-config.sh"
MESSAGES_LIB="$CLAUDE_DIR/tts/tts-messages.sh"

# Check if configuration exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  exit 0  # Fail silently if config missing
fi

# Source configuration
source "$CONFIG_FILE"

# Setup logging with fallback to temp directory
LOG_DIR="$CLAUDE_DIR/data/logs"
if [[ ! -d "$LOG_DIR" ]]; then
  mkdir -p "$LOG_DIR" 2>/dev/null || {
    # Fallback to temp if .claude/logs fails
    LOG_DIR="/tmp/claude-tts-logs-$$"
    mkdir -p "$LOG_DIR"
  }
fi

# Always log to verify hooks are firing
echo "[$(date -Iseconds)] Hook: EVENT=${HOOK_EVENT} CMD=${CLAUDE_COMMAND} STATUS=${CLAUDE_STATUS} DIR=${CLAUDE_PROJECT_DIR}" >> "$LOG_DIR/hook-debug.log" 2>&1

# Check if TTS globally enabled
if [[ "${TTS_ENABLED:-false}" != "true" ]]; then
  exit 0  # TTS disabled, exit silently
fi

# Source message library
if [[ ! -f "$MESSAGES_LIB" ]]; then
  exit 0  # Fail silently if library missing
fi

source "$MESSAGES_LIB"

# ============================================================================
# Event Type Detection
# ============================================================================

# Determine notification category from hook event
# Returns: category name (completion, permission) or exits with error for unsupported events
detect_category() {
  local event="${HOOK_EVENT:-unknown}"

  case "$event" in
    Stop)
      # All Stop events are completion
      echo "completion"
      ;;
    Notification)
      # All Notification events are permission
      echo "permission"
      ;;
    *)
      # Unsupported event type
      return 1
      ;;
  esac
}

# ============================================================================
# Category Enablement Check
# ============================================================================

# Check if category is enabled in configuration
# Args: $1 - category name
# Returns: 0 if enabled, 1 if disabled
is_category_enabled() {
  local category="$1"

  case "$category" in
    completion)
      [[ "${TTS_COMPLETION_ENABLED:-false}" == "true" ]]
      ;;
    permission)
      [[ "${TTS_PERMISSION_ENABLED:-false}" == "true" ]]
      ;;
    *)
      return 1  # Unknown categories disabled
      ;;
  esac
}

# ============================================================================
# Voice Parameter Extraction
# ============================================================================

# Get voice parameters for category
# Returns: "pitch:speed" string (unified for all categories)
get_voice_params() {
  echo "${TTS_VOICE_PARAMS:-50:160}"
}

# Parse pitch and speed from voice params string
# Args: $1 - voice params ("pitch:speed")
# Returns: pitch value
get_pitch() {
  local params="$1"
  echo "${params%%:*}"
}

# Args: $1 - voice params ("pitch:speed")
# Returns: speed value
get_speed() {
  local params="$1"
  echo "${params##*:}"
}

# ============================================================================
# TTS Execution
# ============================================================================

# Speak message using espeak-ng
# Args: $1 - message, $2 - pitch, $3 - speed
speak_message() {
  local message="$1"
  local pitch="$2"
  local speed="$3"
  local voice="${TTS_VOICE:-en-us+f3}"
  local engine="${TTS_ENGINE:-espeak-ng}"

  # Check if TTS engine available
  if ! command -v "$engine" &>/dev/null; then
    return 0  # Fail silently if engine not found
  fi

  # Debug logging if enabled
  if [[ "${TTS_DEBUG:-false}" == "true" ]] && [[ -d "$LOG_DIR" ]]; then
    echo "[$(date -Iseconds)] [$HOOK_EVENT] $message (pitch:$pitch speed:$speed)" >> "$LOG_DIR/tts.log" 2>&1
  fi

  # Speak asynchronously, redirect errors to avoid blocking
  "$engine" -v "$voice" -s "$speed" -p "$pitch" "$message" &>/dev/null &
}

# ============================================================================
# Silent Command Check
# ============================================================================

# Check if current command should be silent (no TTS)
# Returns: 0 if should be silent, 1 otherwise
is_silent_command() {
  local command="${CLAUDE_COMMAND:-}"

  # If no command set, don't silence
  if [[ -z "$command" ]]; then
    return 1
  fi

  # Check if command is in silent list
  local silent_commands="${TTS_SILENT_COMMANDS:-}"
  if [[ -z "$silent_commands" ]]; then
    return 1
  fi

  # Normalize command (strip leading /)
  local normalized_command="${command#/}"

  # Check each silent command
  for silent_cmd in $silent_commands; do
    local normalized_silent="${silent_cmd#/}"
    if [[ "$normalized_command" == "$normalized_silent" ]]; then
      return 0
    fi
  done

  return 1
}

# ============================================================================
# Main Dispatcher Logic
# ============================================================================

main() {
  # Detect notification category
  local category
  category=$(detect_category) || exit 0  # Exit if unsupported event

  # For completion category, check if command should be silent
  if [[ "$category" == "completion" ]] && is_silent_command; then
    exit 0  # Silent command, no TTS
  fi

  # Check if category is enabled
  if ! is_category_enabled "$category"; then
    exit 0  # Category disabled, exit silently
  fi

  # Generate message for category
  local message
  message=$(generate_message "$category")

  # If no message generated, exit
  if [[ -z "$message" ]]; then
    exit 0
  fi

  # Get voice parameters for category
  local voice_params
  voice_params=$(get_voice_params "$category")

  local pitch
  pitch=$(get_pitch "$voice_params")

  local speed
  speed=$(get_speed "$voice_params")

  # Speak the message (asynchronously)
  speak_message "$message" "$pitch" "$speed"

  # Always exit successfully (non-blocking)
  exit 0
}

# Run main dispatcher
main "$@"
