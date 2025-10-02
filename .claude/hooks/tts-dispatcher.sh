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

# Determine notification category from hook event and context
# Returns: category name (completion, permission, progress, error, etc.)
detect_category() {
  local event="${HOOK_EVENT:-unknown}"
  local status="${CLAUDE_STATUS:-success}"

  # If HOOK_EVENT not set, try to infer from script name or other context
  if [[ "$event" == "unknown" ]]; then
    # Check if we're being called from a specific hook by looking at caller
    local script_name
    script_name=$(basename "${BASH_SOURCE[1]:-}" 2>/dev/null || echo "")

    # Default to completion for Stop-like behavior
    event="Stop"
  fi

  case "$event" in
    Stop)
      # Completion or error based on status
      if [[ "$status" == "error" ]] || [[ "$status" == "failed" ]]; then
        echo "error"
      else
        echo "completion"
      fi
      ;;
    SessionStart | SessionEnd)
      echo "session"
      ;;
    SubagentStop)
      echo "progress"
      ;;
    Notification)
      # Permission request or idle reminder
      local notification_type="${NOTIFICATION_TYPE:-permission}"
      if [[ "$notification_type" == "idle" ]]; then
        echo "idle"
      else
        echo "permission"
      fi
      ;;
    PreToolUse | PostToolUse)
      echo "tool"
      ;;
    UserPromptSubmit)
      echo "prompt_ack"
      ;;
    PreCompact)
      echo "compact"
      ;;
    *)
      # Default to completion
      echo "completion"
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
  local var_name

  case "$category" in
    completion)
      var_name="TTS_COMPLETION_ENABLED"
      ;;
    permission)
      var_name="TTS_PERMISSION_ENABLED"
      ;;
    progress)
      var_name="TTS_PROGRESS_ENABLED"
      ;;
    error)
      var_name="TTS_ERROR_ENABLED"
      ;;
    idle)
      var_name="TTS_IDLE_ENABLED"
      ;;
    session)
      var_name="TTS_SESSION_ENABLED"
      ;;
    tool)
      var_name="TTS_TOOL_ENABLED"
      ;;
    prompt_ack)
      var_name="TTS_PROMPT_ACK_ENABLED"
      ;;
    compact)
      var_name="TTS_COMPACT_ENABLED"
      ;;
    *)
      return 1  # Unknown category disabled by default
      ;;
  esac

  # Check if variable is set to true
  local enabled="${!var_name:-false}"
  if [[ "$enabled" == "true" ]]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Voice Parameter Extraction
# ============================================================================

# Get voice parameters for category
# Args: $1 - category name
# Returns: "pitch:speed" string
get_voice_params() {
  local category="$1"
  local var_name

  case "$category" in
    completion)
      var_name="TTS_COMPLETION_VOICE"
      ;;
    permission)
      var_name="TTS_PERMISSION_VOICE"
      ;;
    progress)
      var_name="TTS_PROGRESS_VOICE"
      ;;
    error)
      var_name="TTS_ERROR_VOICE"
      ;;
    idle)
      var_name="TTS_IDLE_VOICE"
      ;;
    session)
      var_name="TTS_SESSION_VOICE"
      ;;
    tool)
      var_name="TTS_TOOL_VOICE"
      ;;
    prompt_ack)
      var_name="TTS_PROMPT_ACK_VOICE"
      ;;
    compact)
      var_name="TTS_COMPACT_VOICE"
      ;;
    *)
      echo "50:160"  # Default voice params
      return
      ;;
  esac

  echo "${!var_name:-50:160}"
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
  if [[ "${TTS_DEBUG:-false}" == "true" ]]; then
    local log_dir="$CLAUDE_DIR/logs"
    mkdir -p "$log_dir"
    echo "[$(date -Iseconds)] [$HOOK_EVENT] $message (pitch:$pitch speed:$speed)" >> "$log_dir/tts.log"
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
  category=$(detect_category)

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
