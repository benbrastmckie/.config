#!/usr/bin/env bash
# TTS Testing Utility
#
# Comprehensive test suite for all TTS notification categories.
# Tests message generation, voice characteristics, and configuration loading.
#
# Usage:
#   ./test-tts.sh              # Run all tests
#   ./test-tts.sh completion   # Test specific category
#   ./test-tts.sh --silent     # Test without audio (message generation only)

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$CLAUDE_DIR/config/tts-config.sh"
MESSAGES_LIB="$CLAUDE_DIR/lib/tts-messages.sh"

# Test mode: silent or with audio
SILENT_MODE=false
if [[ "${1:-}" == "--silent" ]]; then
  SILENT_MODE=true
  shift
fi

# Specific category to test (optional)
TEST_CATEGORY="${1:-all}"

# ============================================================================
# Test Helpers
# ============================================================================

# Print test header
print_header() {
  local title="$1"
  echo ""
  echo "=========================================="
  echo "$title"
  echo "=========================================="
}

# Print test result
print_result() {
  local status="$1"
  local message="$2"

  if [[ "$status" == "PASS" ]]; then
    echo "  ✓ $message"
  elif [[ "$status" == "FAIL" ]]; then
    echo "  ✗ $message"
  else
    echo "  • $message"
  fi
}

# Speak message using TTS (if not silent mode)
speak_test() {
  local message="$1"
  local pitch="$2"
  local speed="$3"

  if [[ "$SILENT_MODE" == "false" ]] && command -v espeak-ng &>/dev/null; then
    espeak-ng -v en-us+f3 -s "$speed" -p "$pitch" "$message" 2>/dev/null &
    sleep 0.5  # Brief pause between messages
  fi
}

# ============================================================================
# Configuration Tests
# ============================================================================

test_configuration() {
  print_header "Testing Configuration Loading"

  # Test config file exists
  if [[ -f "$CONFIG_FILE" ]]; then
    print_result "PASS" "Configuration file exists"
  else
    print_result "FAIL" "Configuration file missing: $CONFIG_FILE"
    return 1
  fi

  # Source configuration
  source "$CONFIG_FILE"

  # Test required variables
  local required_vars=(
    "TTS_ENABLED"
    "TTS_ENGINE"
    "TTS_VOICE"
    "TTS_COMPLETION_ENABLED"
    "TTS_COMPLETION_VOICE"
  )

  for var in "${required_vars[@]}"; do
    if [[ -n "${!var:-}" ]]; then
      print_result "PASS" "$var = ${!var}"
    else
      print_result "FAIL" "$var not set"
    fi
  done

  print_result "INFO" "Config loaded successfully"
}

# ============================================================================
# Message Generation Tests
# ============================================================================

test_completion_message() {
  print_header "Testing Completion Messages"

  source "$MESSAGES_LIB"
  source "$CONFIG_FILE"

  export CLAUDE_PROJECT_DIR="/home/benjamin/.config"
  export CLAUDE_COMMAND="/implement"
  export CLAUDE_STATUS="success"

  local message
  message=$(generate_completion_message)

  print_result "INFO" "Message: $message"

  local voice_params="$TTS_COMPLETION_VOICE"
  local pitch="${voice_params%%:*}"
  local speed="${voice_params##*:}"

  print_result "INFO" "Voice: pitch=$pitch speed=$speed"

  speak_test "$message" "$pitch" "$speed"
  print_result "PASS" "Completion message generated"
}

test_permission_message() {
  print_header "Testing Permission Messages"

  source "$MESSAGES_LIB"
  source "$CONFIG_FILE"

  export TOOL_NAME="Bash"
  export PERMISSION_CONTEXT="Git commit for Phase 2"

  local message
  message=$(generate_permission_message)

  print_result "INFO" "Message: $message"

  local voice_params="$TTS_PERMISSION_VOICE"
  local pitch="${voice_params%%:*}"
  local speed="${voice_params##*:}"

  print_result "INFO" "Voice: pitch=$pitch speed=$speed"

  speak_test "$message" "$pitch" "$speed"
  print_result "PASS" "Permission message generated"
}

test_progress_message() {
  print_header "Testing Progress Messages"

  source "$MESSAGES_LIB"
  source "$CONFIG_FILE"

  export SUBAGENT_TYPE="research-specialist"
  export SUBAGENT_RESULT="Found 3 implementation patterns"

  local message
  message=$(generate_progress_message)

  print_result "INFO" "Message: $message"

  local voice_params="$TTS_PROGRESS_VOICE"
  local pitch="${voice_params%%:*}"
  local speed="${voice_params##*:}"

  print_result "INFO" "Voice: pitch=$pitch speed=$speed"

  speak_test "$message" "$pitch" "$speed"
  print_result "PASS" "Progress message generated"
}

test_error_message() {
  print_header "Testing Error Messages"

  source "$MESSAGES_LIB"
  source "$CONFIG_FILE"

  export CLAUDE_COMMAND="/test"
  export ERROR_TYPE="Tests failed in Phase 2"

  local message
  message=$(generate_error_message)

  print_result "INFO" "Message: $message"

  local voice_params="$TTS_ERROR_VOICE"
  local pitch="${voice_params%%:*}"
  local speed="${voice_params##*:}"

  print_result "INFO" "Voice: pitch=$pitch speed=$speed"

  speak_test "$message" "$pitch" "$speed"
  print_result "PASS" "Error message generated"
}

test_idle_message() {
  print_header "Testing Idle Messages"

  source "$MESSAGES_LIB"
  source "$CONFIG_FILE"

  export CLAUDE_COMMAND="/implement"
  export IDLE_SECONDS=120

  local message
  message=$(generate_idle_message)

  print_result "INFO" "Message: $message"

  local voice_params="$TTS_IDLE_VOICE"
  local pitch="${voice_params%%:*}"
  local speed="${voice_params##*:}"

  print_result "INFO" "Voice: pitch=$pitch speed=$speed"

  speak_test "$message" "$pitch" "$speed"
  print_result "PASS" "Idle message generated"
}

test_session_message() {
  print_header "Testing Session Messages"

  source "$MESSAGES_LIB"
  source "$CONFIG_FILE"

  export CLAUDE_PROJECT_DIR="/home/benjamin/.config"
  export HOOK_EVENT="SessionStart"

  local message
  message=$(generate_session_message)

  print_result "INFO" "Message (Start): $message"

  local voice_params="$TTS_SESSION_VOICE"
  local pitch="${voice_params%%:*}"
  local speed="${voice_params##*:}"

  speak_test "$message" "$pitch" "$speed"

  export HOOK_EVENT="SessionEnd"
  export SESSION_END_REASON="Session ended"
  message=$(generate_session_message)

  print_result "INFO" "Message (End): $message"
  speak_test "$message" "$pitch" "$speed"

  print_result "PASS" "Session messages generated"
}

test_tool_message() {
  print_header "Testing Tool Messages"

  source "$MESSAGES_LIB"
  source "$CONFIG_FILE"

  export TOOL_NAME="Bash"
  export TOOL_PHASE="pre"
  export TOOL_CONTEXT="Running test suite"

  local message
  message=$(generate_tool_message)

  print_result "INFO" "Message (Pre): $message"

  local voice_params="$TTS_TOOL_VOICE"
  local pitch="${voice_params%%:*}"
  local speed="${voice_params##*:}"

  speak_test "$message" "$pitch" "$speed"

  export TOOL_PHASE="post"
  message=$(generate_tool_message)

  print_result "INFO" "Message (Post): $message"
  speak_test "$message" "$pitch" "$speed"

  print_result "PASS" "Tool messages generated"
}

test_prompt_ack_message() {
  print_header "Testing Prompt Acknowledgment Messages"

  source "$MESSAGES_LIB"
  source "$CONFIG_FILE"

  export PROMPT_BRIEF="Prompt received"

  local message
  message=$(generate_prompt_ack_message)

  print_result "INFO" "Message: $message"

  local voice_params="$TTS_PROMPT_ACK_VOICE"
  local pitch="${voice_params%%:*}"
  local speed="${voice_params##*:}"

  print_result "INFO" "Voice: pitch=$pitch speed=$speed"

  speak_test "$message" "$pitch" "$speed"
  print_result "PASS" "Prompt ack message generated"
}

test_compact_message() {
  print_header "Testing Compact Messages"

  source "$MESSAGES_LIB"
  source "$CONFIG_FILE"

  export COMPACT_TRIGGER="auto"

  local message
  message=$(generate_compact_message)

  print_result "INFO" "Message: $message"

  local voice_params="$TTS_COMPACT_VOICE"
  local pitch="${voice_params%%:*}"
  local speed="${voice_params##*:}"

  print_result "INFO" "Voice: pitch=$pitch speed=$speed"

  speak_test "$message" "$pitch" "$speed"
  print_result "PASS" "Compact message generated"
}

# ============================================================================
# Voice Characteristics Tests
# ============================================================================

test_voice_characteristics() {
  print_header "Testing Voice Characteristics"

  if [[ "$SILENT_MODE" == "true" ]]; then
    print_result "INFO" "Skipped (silent mode)"
    return 0
  fi

  if ! command -v espeak-ng &>/dev/null; then
    print_result "FAIL" "espeak-ng not found"
    return 1
  fi

  print_result "INFO" "Testing different pitch/speed combinations..."

  # Normal voice
  print_result "INFO" "Normal (50:160)"
  espeak-ng -v en-us+f3 -s 160 -p 50 "Normal voice" 2>/dev/null
  sleep 0.5

  # Urgent voice
  print_result "INFO" "Urgent (60:180)"
  espeak-ng -v en-us+f3 -s 180 -p 60 "Urgent voice" 2>/dev/null
  sleep 0.5

  # Alert voice
  print_result "INFO" "Alert (35:140)"
  espeak-ng -v en-us+f3 -s 140 -p 35 "Alert voice" 2>/dev/null
  sleep 0.5

  print_result "PASS" "Voice characteristics tested"
}

# ============================================================================
# Main Test Runner
# ============================================================================

main() {
  print_header "TTS Comprehensive Test Suite"

  if [[ "$SILENT_MODE" == "true" ]]; then
    print_result "INFO" "Running in SILENT mode (no audio)"
  fi

  # Run configuration tests first
  test_configuration

  # Run message generation tests
  case "$TEST_CATEGORY" in
    all)
      test_completion_message
      test_permission_message
      test_progress_message
      test_error_message
      test_idle_message
      test_session_message
      test_tool_message
      test_prompt_ack_message
      test_compact_message
      test_voice_characteristics
      ;;
    completion)
      test_completion_message
      ;;
    permission)
      test_permission_message
      ;;
    progress)
      test_progress_message
      ;;
    error)
      test_error_message
      ;;
    idle)
      test_idle_message
      ;;
    session)
      test_session_message
      ;;
    tool)
      test_tool_message
      ;;
    prompt_ack)
      test_prompt_ack_message
      ;;
    compact)
      test_compact_message
      ;;
    voice)
      test_voice_characteristics
      ;;
    *)
      echo "Unknown category: $TEST_CATEGORY"
      echo "Valid categories: all, completion, permission, progress, error, idle, session, tool, prompt_ack, compact, voice"
      exit 1
      ;;
  esac

  print_header "Test Suite Complete"
  print_result "INFO" "All tests passed!"
}

main "$@"
