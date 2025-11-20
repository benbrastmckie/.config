#!/usr/bin/env bash
# Progress dashboard rendering with ANSI terminal support
#
# Provides real-time visual feedback during implementation workflows with:
# - Terminal capability detection
# - ANSI escape codes for in-place updates
# - Unicode box-drawing for professional layout
# - Graceful fallback to PROGRESS markers
#
# Usage:
#   source progress-dashboard.sh
#   initialize_dashboard "Plan Name" 5
#   update_dashboard_phase 2 "in_progress" "Running tests"
#   clear_dashboard

# ==============================================================================
# Terminal Capability Detection
# ==============================================================================

detect_terminal_capabilities() {
  # Check TERM environment variable
  if [[ -z "$TERM" ]] || [[ "$TERM" = "dumb" ]]; then
    echo '{"ansi_supported": false, "reason": "dumb_terminal"}'
    return
  fi

  # Check if running in interactive shell
  if [[ ! -t 1 ]]; then
    echo '{"ansi_supported": false, "reason": "non_interactive"}'
    return
  fi

  # Check for tput availability
  if ! command -v tput &> /dev/null; then
    echo '{"ansi_supported": false, "reason": "tput_missing"}'
    return
  fi

  # Test ANSI capabilities
  local colors
  colors=$(tput colors 2>/dev/null || echo "0")

  if [[ "$colors" -ge 8 ]]; then
    echo '{"ansi_supported": true, "colors": '"$colors"', "reason": "full_support"}'
  else
    echo '{"ansi_supported": false, "reason": "insufficient_colors"}'
  fi
}

# ==============================================================================
# ANSI Escape Codes
# ==============================================================================

# Cursor movement
readonly ANSI_CURSOR_UP="\033[{n}A"        # Move cursor up n lines
readonly ANSI_CURSOR_DOWN="\033[{n}B"      # Move cursor down n lines
readonly ANSI_CURSOR_FORWARD="\033[{n}C"   # Move cursor right n columns
readonly ANSI_CURSOR_BACK="\033[{n}D"      # Move cursor left n columns
readonly ANSI_CURSOR_SAVE="\033[s"         # Save cursor position
readonly ANSI_CURSOR_RESTORE="\033[u"      # Restore cursor position
readonly ANSI_CURSOR_HOME="\033[H"         # Move cursor to home (0,0)

# Screen manipulation
readonly ANSI_CLEAR_SCREEN="\033[2J"       # Clear entire screen
readonly ANSI_CLEAR_LINE="\033[2K"         # Clear entire line
readonly ANSI_CLEAR_TO_END="\033[0J"       # Clear from cursor to end of screen

# Colors (foreground)
readonly ANSI_FG_BLACK="\033[30m"
readonly ANSI_FG_RED="\033[31m"
readonly ANSI_FG_GREEN="\033[32m"
readonly ANSI_FG_YELLOW="\033[33m"
readonly ANSI_FG_BLUE="\033[34m"
readonly ANSI_FG_MAGENTA="\033[35m"
readonly ANSI_FG_CYAN="\033[36m"
readonly ANSI_FG_WHITE="\033[37m"
readonly ANSI_RESET="\033[0m"

# Text formatting
readonly ANSI_BOLD="\033[1m"
readonly ANSI_DIM="\033[2m"
readonly ANSI_UNDERLINE="\033[4m"

# Unicode box-drawing characters
readonly BOX_TL="┌"  # Top-left
readonly BOX_TR="┐"  # Top-right
readonly BOX_BL="└"  # Bottom-left
readonly BOX_BR="┘"  # Bottom-right
readonly BOX_H="─"   # Horizontal
readonly BOX_V="│"   # Vertical
readonly BOX_ML="├"  # Middle-left
readonly BOX_MR="┤"  # Middle-right

# Status icons
readonly ICON_COMPLETE="✓"
readonly ICON_IN_PROGRESS="→"
readonly ICON_PENDING="⬚"
readonly ICON_SKIPPED="⊘"
readonly ICON_FAILED="✗"

# ==============================================================================
# Dashboard Rendering Functions
# ==============================================================================

render_dashboard() {
  local plan_name="$1"
  local current_phase="$2"
  local total_phases="$3"
  local phase_list="$4"         # JSON array of phase info
  local elapsed_seconds="$5"
  local estimated_remaining="$6"
  local current_task="$7"
  local last_test_result="$8"   # JSON: {name, status}
  local wave_info="$9"           # JSON: {wave_num, total_waves, phases_in_wave, parallel}

  # Check terminal capabilities
  local capabilities
  capabilities=$(detect_terminal_capabilities)
  local ansi_supported
  ansi_supported=$(echo "$capabilities" | jq -r '.ansi_supported')

  if [[ "$ansi_supported" != "true" ]]; then
    # Fallback to PROGRESS markers
    render_progress_markers "$plan_name" "$current_phase" "$total_phases"
    return
  fi

  # Calculate dashboard dimensions
  local width=65
  local dashboard_lines=11

  # Save cursor position
  echo -ne "$ANSI_CURSOR_SAVE"

  # Clear dashboard area (move up, clear lines)
  for ((i=0; i<dashboard_lines; i++)); do
    echo -ne "\033[1A"  # Move up 1 line
  done

  # Render header
  render_box_line "$BOX_TL" "$BOX_H" "$BOX_TR" "$width"
  render_text_line "$BOX_V" "Implementation Progress: $plan_name" "$BOX_V" "$width"
  render_box_line "$BOX_ML" "$BOX_H" "$BOX_MR" "$width"

  # Render phase list
  local completed=0
  while IFS= read -r phase_json; do
    if [[ -z "$phase_json" ]]; then continue; fi

    local phase_num phase_name phase_status
    phase_num=$(echo "$phase_json" | jq -r '.number')
    phase_name=$(echo "$phase_json" | jq -r '.name')
    phase_status=$(echo "$phase_json" | jq -r '.status')

    local icon color
    case "$phase_status" in
      "completed")
        icon="$ICON_COMPLETE"
        color="$ANSI_FG_GREEN"
        completed=$((completed + 1))
        ;;
      "in_progress")
        icon="$ICON_IN_PROGRESS"
        color="$ANSI_FG_YELLOW"
        ;;
      "pending")
        icon="$ICON_PENDING"
        color="$ANSI_FG_WHITE"
        ;;
      "skipped")
        icon="$ICON_SKIPPED"
        color="$ANSI_FG_CYAN"
        completed=$((completed + 1))
        ;;
      "failed")
        icon="$ICON_FAILED"
        color="$ANSI_FG_RED"
        ;;
    esac

    local status_text
    case "$phase_status" in
      "completed") status_text="Complete" ;;
      "in_progress") status_text="In Progress" ;;
      "pending") status_text="Pending" ;;
      "skipped") status_text="Skipped" ;;
      "failed") status_text="Failed" ;;
    esac

    # Render phase line with color and icon
    local phase_text="Phase $phase_num: $phase_name"
    local dots_count=$((width - 4 - ${#phase_text} - ${#status_text} - 3))
    if [[ $dots_count -lt 0 ]]; then dots_count=0; fi
    local dots=$(printf "%${dots_count}s" | tr ' ' '.')

    echo -ne "$BOX_V ${color}${phase_text} ${dots} ${icon} ${status_text}${ANSI_RESET} $BOX_V\n"
  done < <(echo "$phase_list" | jq -c '.[]')

  # Render progress bar
  render_box_line "$BOX_ML" "$BOX_H" "$BOX_MR" "$width"
  local progress_percent=$((completed * 100 / total_phases))
  local bar_width=28
  local filled=$((progress_percent * bar_width / 100))
  local empty=$((bar_width - filled))
  local progress_bar=$(printf "%${filled}s" | tr ' ' '█')$(printf "%${empty}s" | tr ' ' '░')

  render_text_line "$BOX_V" "Progress: [$progress_bar] $progress_percent% ($completed/$total_phases phases)" "$BOX_V" "$width"

  # Render time estimates
  local elapsed_formatted estimated_formatted
  elapsed_formatted=$(format_duration "$elapsed_seconds")
  estimated_formatted=$(format_duration "$estimated_remaining")
  render_text_line "$BOX_V" "Elapsed: $elapsed_formatted  |  Estimated Remaining: ~$estimated_formatted" "$BOX_V" "$width"

  # Render current task and test result
  render_box_line "$BOX_ML" "$BOX_H" "$BOX_MR" "$width"
  render_text_line "$BOX_V" "Current Task: $current_task" "$BOX_V" "$width"

  if [[ -n "$last_test_result" ]] && [[ "$last_test_result" != "{}" ]]; then
    local test_name test_status test_icon test_color
    test_name=$(echo "$last_test_result" | jq -r '.name')
    test_status=$(echo "$last_test_result" | jq -r '.status')

    if [[ "$test_status" = "pass" ]]; then
      test_icon="$ICON_COMPLETE"
      test_color="$ANSI_FG_GREEN"
    else
      test_icon="$ICON_FAILED"
      test_color="$ANSI_FG_RED"
    fi

    local test_text="Last Test: $test_name"
    local test_dots_count=$((width - 4 - ${#test_text} - 6))
    if [[ $test_dots_count -lt 0 ]]; then test_dots_count=0; fi
    local test_dots=$(printf "%${test_dots_count}s" | tr ' ' '.')

    echo -ne "$BOX_V ${test_text} ${test_dots} ${test_color}${test_icon} ${test_status^^}${ANSI_RESET} $BOX_V\n"
  fi

  # Render wave info (if parallel execution)
  if [[ -n "$wave_info" ]] && [[ "$wave_info" != "{}" ]]; then
    render_box_line "$BOX_ML" "$BOX_H" "$BOX_MR" "$width"
    local wave_num total_waves phases_in_wave parallel
    wave_num=$(echo "$wave_info" | jq -r '.wave_num')
    total_waves=$(echo "$wave_info" | jq -r '.total_waves')
    phases_in_wave=$(echo "$wave_info" | jq -r '.phases_in_wave')
    parallel=$(echo "$wave_info" | jq -r '.parallel')

    local wave_text="Wave Info: Wave $wave_num of $total_waves ($phases_in_wave)"
    if [[ "$parallel" = "true" ]]; then
      wave_text="$wave_text - Parallel"
    else
      wave_text="$wave_text - Sequential"
    fi

    render_text_line "$BOX_V" "$wave_text" "$BOX_V" "$width"
  fi

  # Render footer
  render_box_line "$BOX_BL" "$BOX_H" "$BOX_BR" "$width"

  # Restore cursor position
  echo -ne "$ANSI_CURSOR_RESTORE"
}

# Helper: Render box line (top, middle, bottom)
render_box_line() {
  local left="$1" mid="$2" right="$3" width="$4"
  local line_width=$((width - 2))
  echo -ne "$left$(printf "%${line_width}s" | tr ' ' "$mid")$right\n"
}

# Helper: Render text line with left/right borders
render_text_line() {
  local left="$1" text="$2" right="$3" width="$4"
  local text_len=${#text}
  local padding=$((width - text_len - 4))
  if [[ $padding -lt 0 ]]; then padding=0; fi
  echo -ne "$left $text$(printf "%${padding}s")$right\n"
}

# Helper: Format duration in seconds to human-readable
format_duration() {
  local seconds="$1"
  local minutes=$((seconds / 60))
  local remaining_seconds=$((seconds % 60))

  if [[ $minutes -gt 0 ]]; then
    echo "${minutes}m ${remaining_seconds}s"
  else
    echo "${seconds}s"
  fi
}

# Fallback: Render progress markers (traditional output)
render_progress_markers() {
  local plan_name="$1"
  local current_phase="$2"
  local total_phases="$3"

  echo "PROGRESS: Phase $current_phase/$total_phases - $plan_name"
}

# ==============================================================================
# Dashboard Update Functions
# ==============================================================================

initialize_dashboard() {
  local plan_name="$1"
  local total_phases="$2"

  # Reserve space for dashboard (print empty lines)
  for ((i=0; i<11; i++)); do
    echo ""
  done

  # Initial render
  render_dashboard "$plan_name" 1 "$total_phases" '[]' 0 0 "Initializing..." '{}' '{}'
}

update_dashboard_phase() {
  local phase_num="$1"
  local phase_status="$2"
  local current_task="$3"

  # Update phase status in state
  # Re-render dashboard with new state
  # (Implementation depends on state management)
  # This is a placeholder - actual implementation would maintain dashboard state
  echo "Dashboard update: Phase $phase_num -> $phase_status, Task: $current_task" >&2
}

clear_dashboard() {
  # Clear dashboard area on completion or error
  local dashboard_lines=11

  for ((i=0; i<dashboard_lines; i++)); do
    echo -ne "\033[1A${ANSI_CLEAR_LINE}"
  done
}

# Export functions for use in commands
export -f detect_terminal_capabilities
export -f render_dashboard
export -f initialize_dashboard
export -f update_dashboard_phase
export -f clear_dashboard
export -f render_progress_markers
export -f render_box_line
export -f render_text_line
export -f format_duration
