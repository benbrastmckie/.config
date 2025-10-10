#!/usr/bin/env bash
# TTS Message Generator Library
#
# This library provides intelligent message generation for all TTS notification categories.
# Each function generates context-aware messages based on Claude Code workflow events.
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/tts-messages.sh"
#   MESSAGE=$(generate_completion_message)
#   echo "$MESSAGE"
#
# Environment Variables Expected:
#   CLAUDE_PROJECT_DIR - Project directory path
#   CLAUDE_COMMAND - Command being executed (e.g., /implement, /test)
#   CLAUDE_STATUS - Command status (success, error, etc.)
#   HOOK_EVENT - Hook event type (Stop, SessionStart, etc.)
#
# Functions:
#   get_context_prefix() - Extract directory and branch context
#   generate_completion_message() - Completion notifications
#   generate_permission_message() - Permission requests
#   generate_progress_message() - Subagent progress updates
#   generate_error_message() - Error notifications
#   generate_idle_message() - Idle reminders
#   generate_session_message() - Session lifecycle
#   read_state_file() - Read optional state file for detailed summaries

# ============================================================================
# Context Extraction
# ============================================================================

# Get context prefix with directory and branch information
# Returns: "[directory], [branch]" (comma provides pause)
get_context_prefix() {
  local dir_name="unknown"
  local branch_name="no-branch"

  # Extract directory name
  if [[ -n "$CLAUDE_PROJECT_DIR" ]]; then
    dir_name=$(basename "$CLAUDE_PROJECT_DIR")
  fi

  # Get git branch if available
  if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]] && command -v git &>/dev/null; then
    local git_branch
    git_branch=$(git -C "$CLAUDE_PROJECT_DIR" branch --show-current 2>/dev/null)
    if [[ -n "$git_branch" ]]; then
      branch_name="$git_branch"
    fi
  fi

  echo "$dir_name, $branch_name"
}

# ============================================================================
# State File Reading (Optional)
# ============================================================================

# Read state file for detailed command summaries
# Returns: JSON content if file exists, empty string otherwise
read_state_file() {
  local state_file="${CLAUDE_PROJECT_DIR:-}/.claude/state/last-completion.json"

  if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]] && [[ -f "$state_file" ]]; then
    cat "$state_file" 2>/dev/null
  else
    echo ""
  fi
}

# Extract field from JSON state file
# Args: $1 - field name (e.g., "summary", "next_steps")
# Returns: Field value or empty string
get_state_field() {
  local field="$1"
  local state
  state=$(read_state_file)

  if [[ -n "$state" ]] && command -v jq &>/dev/null; then
    echo "$state" | jq -r ".$field // empty" 2>/dev/null
  else
    echo ""
  fi
}

# ============================================================================
# Message Generators
# ============================================================================

# Generate completion notification message
# Triggered: Stop hook when command completes
# Format: "[directory], [branch]"
generate_completion_message() {
  local context
  context=$(get_context_prefix)

  echo "$context"
}

# Generate permission request message
# Triggered: Notification hook for tool permissions
# Format: "directory, branch" (same as completion)
generate_permission_message() {
  get_context_prefix
}

# Generate progress update message
# Triggered: SubagentStop hook
# Format: "Progress update. [Agent name] complete. [What was done]."
generate_progress_message() {
  local agent="${SUBAGENT_TYPE:-agent}"
  local result="${SUBAGENT_RESULT:-task}"

  # Clean up agent type name
  agent=$(echo "$agent" | sed 's/-/ /g')

  local message="Progress update. $agent complete."

  if [[ -n "$result" ]]; then
    message="$message $result."
  fi

  echo "$message"
}

# Generate error notification message
# Triggered: Stop hook with error status
# Format: "Error in [command]. [Error type]. Review output."
generate_error_message() {
  local command="${CLAUDE_COMMAND:-command}"
  local error_type="${ERROR_TYPE:-Error occurred}"

  # Clean up command name
  command=$(echo "$command" | sed 's/^\/*//')

  local message="Error in $command. $error_type. Review output."

  echo "$message"
}

# Generate idle reminder message
# Triggered: Notification hook after 60+ seconds idle
# Format: "Still waiting for input. Last action: [command]. [Duration]."
generate_idle_message() {
  local last_command="${CLAUDE_COMMAND:-command}"
  local idle_seconds="${IDLE_SECONDS:-60}"

  # Clean up command name
  last_command=$(echo "$last_command" | sed 's/^\/*//')

  # Format duration
  local duration
  if [[ $idle_seconds -lt 120 ]]; then
    duration="Waiting 1 minute"
  else
    local minutes=$((idle_seconds / 60))
    duration="Waiting $minutes minutes"
  fi

  local message="Still waiting for input. Last action: $last_command. $duration."

  echo "$message"
}

# Generate session lifecycle message
# Triggered: SessionStart or SessionEnd hooks
# Format (Start): "Session started. Directory [name]. Branch [branch]."
# Format (End): "Session ended. [Reason]. [Optional: pending state info]."
generate_session_message() {
  local event="${HOOK_EVENT:-session}"

  if [[ "$event" == "SessionStart" ]]; then
    local context
    context=$(get_context_prefix)
    echo "Session started. $context"
  else
    local reason="${SESSION_END_REASON:-Session ended}"
    local pending="${PENDING_WORKFLOWS:-}"

    local message="$reason."

    if [[ -n "$pending" ]]; then
      message="$message $pending."
    fi

    echo "$message"
  fi
}

# Generate tool execution message
# Triggered: PreToolUse or PostToolUse hooks
# Format (Pre): "[Tool name] starting. [Context]."
# Format (Post): "[Tool name] complete."
generate_tool_message() {
  local tool="${TOOL_NAME:-tool}"
  local phase="${TOOL_PHASE:-pre}"
  local context="${TOOL_CONTEXT:-}"

  if [[ "$phase" == "pre" ]]; then
    local message="$tool starting."
    if [[ -n "$context" ]]; then
      message="$message $context."
    fi
    echo "$message"
  else
    echo "$tool complete."
  fi
}

# Generate prompt acknowledgment message
# Triggered: UserPromptSubmit hook
# Format: "Prompt received. [Command or brief]."
generate_prompt_ack_message() {
  local prompt_brief="${PROMPT_BRIEF:-Prompt received}"
  echo "$prompt_brief."
}

# Generate compact operation message
# Triggered: PreCompact hook
# Format: "Compacting context. [Trigger: manual or auto]. Workflow may pause."
generate_compact_message() {
  local trigger="${COMPACT_TRIGGER:-manual}"
  echo "Compacting context. $trigger compact. Workflow may pause."
}

# ============================================================================
# Message Routing
# ============================================================================

# Main message generator - routes to appropriate function based on category
# Args: $1 - category (completion, permission)
# Returns: Generated message
generate_message() {
  local category="$1"

  case "$category" in
    completion)
      generate_completion_message
      ;;
    permission)
      generate_permission_message
      ;;
    *)
      echo "Notification."  # Fallback
      ;;
  esac
}
