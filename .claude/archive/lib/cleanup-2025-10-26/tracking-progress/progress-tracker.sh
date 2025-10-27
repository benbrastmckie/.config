#!/usr/bin/env bash
# .claude/lib/progress-tracker.sh
# Real-time progress visualization for wave-based implementation
#
# This utility provides:
# 1. Wave-based progress display with Unicode box-drawing
# 2. Progress bars for each phase/executor
# 3. State persistence to JSON files
# 4. Real-time updates during execution
#
# Usage:
#  source .claude/lib/progress-tracker.sh
#  initialize_progress_state "$plan_path" "$topic_path" "$dependency_analysis"
#  update_phase_progress "$wave_num" "$phase_id" "$tasks_completed" "$current_task"
#  display_wave_progress

set -euo pipefail

# ============================================================================
# GLOBAL STATE
# ============================================================================

# Implementation state file location
STATE_DIR="${HOME}/.config/.claude/data/states"
STATE_FILE=""

# ============================================================================
# STATE INITIALIZATION
# ============================================================================

# Initialize implementation state
# Input: plan_path, topic_path, dependency_analysis (JSON)
# Output: Creates state file and initializes structure
initialize_progress_state() {
  local plan_path="$1"
  local topic_path="$2"
  local dependency_analysis="$3"

  # Create state directory if needed
  mkdir -p "$STATE_DIR"

  # Generate state file name from topic path
  local topic_name
  topic_name=$(basename "$topic_path")
  STATE_FILE="$STATE_DIR/implementation_state_${topic_name}.json"

  # Extract structure level
  local structure_level
  structure_level=$(detect_plan_structure_level "$plan_path")

  # Extract waves from dependency analysis
  local waves
  waves=$(echo "$dependency_analysis" | jq '.waves')

  # Initialize state
  cat > "$STATE_FILE" <<EOF
{
  "plan_path": "$plan_path",
  "topic_path": "$topic_path",
  "structure_level": $structure_level,
  "start_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "waves": $(echo "$waves" | jq '[.[] | {
    wave_number: .wave_number,
    status: "pending",
    start_time: null,
    end_time: null,
    phases: [.phases[] | {
      phase_id: .,
      phase_name: "",
      status: "pending",
      executor_id: null,
      tasks_completed: 0,
      tasks_total: 0,
      current_task: "",
      commit_hash: null,
      checkpoint_path: null
    }]
  }]'),
  "metrics": $(echo "$dependency_analysis" | jq '.metrics')
}
EOF

  echo "$STATE_FILE"
}

# Detect plan structure level
# Input: plan_path
# Output: 0 (inline), 1 (phase files), or 2 (stage files)
detect_plan_structure_level() {
  local plan_path="$1"
  local plan_dir
  plan_dir=$(dirname "$plan_path")
  local plan_name
  plan_name=$(basename "$plan_path" .md)
  local plan_subdir="$plan_dir/$plan_name"

  if [[ ! -d "$plan_subdir" ]]; then
    echo "0"
    return 0
  fi

  if ls "$plan_subdir"/phase_*.md >/dev/null 2>&1; then
    if ls "$plan_subdir"/phase_*/ >/dev/null 2>&1; then
      echo "2"
    else
      echo "1"
    fi
  else
    echo "0"
  fi
}

# ============================================================================
# STATE UPDATES
# ============================================================================

# Start a wave
# Input: wave_number
start_wave() {
  local wave_num="$1"

  if [[ ! -f "$STATE_FILE" ]]; then
    >&2 echo "ERROR: State file not initialized"
    return 1
  fi

  local wave_index=$((wave_num - 1))

  jq ".waves[$wave_index].status = \"in_progress\" | .waves[$wave_index].start_time = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" \
    "$STATE_FILE" > "${STATE_FILE}.tmp"
  mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

# Complete a wave
# Input: wave_number
complete_wave() {
  local wave_num="$1"

  if [[ ! -f "$STATE_FILE" ]]; then
    >&2 echo "ERROR: State file not initialized"
    return 1
  fi

  local wave_index=$((wave_num - 1))

  jq ".waves[$wave_index].status = \"completed\" | .waves[$wave_index].end_time = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" \
    "$STATE_FILE" > "${STATE_FILE}.tmp"
  mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

# Update phase progress
# Input: wave_number, phase_id, tasks_completed, tasks_total, current_task
update_phase_progress() {
  local wave_num="$1"
  local phase_id="$2"
  local tasks_completed="$3"
  local tasks_total="$4"
  local current_task="$5"

  if [[ ! -f "$STATE_FILE" ]]; then
    >&2 echo "ERROR: State file not initialized"
    return 1
  fi

  local wave_index=$((wave_num - 1))

  # Update phase in wave
  jq ".waves[$wave_index].phases |= map(
    if .phase_id == \"$phase_id\" then
      .tasks_completed = $tasks_completed |
      .tasks_total = $tasks_total |
      .current_task = \"$current_task\" |
      .status = \"in_progress\"
    else
      .
    end
  )" "$STATE_FILE" > "${STATE_FILE}.tmp"
  mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

# Complete a phase
# Input: wave_number, phase_id, commit_hash
complete_phase() {
  local wave_num="$1"
  local phase_id="$2"
  local commit_hash="$3"

  if [[ ! -f "$STATE_FILE" ]]; then
    >&2 echo "ERROR: State file not initialized"
    return 1
  fi

  local wave_index=$((wave_num - 1))

  jq ".waves[$wave_index].phases |= map(
    if .phase_id == \"$phase_id\" then
      .status = \"completed\" |
      .commit_hash = \"$commit_hash\"
    else
      .
    end
  )" "$STATE_FILE" > "${STATE_FILE}.tmp"
  mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

# Mark phase as failed
# Input: wave_number, phase_id, error_summary
fail_phase() {
  local wave_num="$1"
  local phase_id="$2"
  local error_summary="$3"

  if [[ ! -f "$STATE_FILE" ]]; then
    >&2 echo "ERROR: State file not initialized"
    return 1
  fi

  local wave_index=$((wave_num - 1))

  jq ".waves[$wave_index].phases |= map(
    if .phase_id == \"$phase_id\" then
      .status = \"failed\" |
      .error_summary = \"$error_summary\"
    else
      .
    end
  )" "$STATE_FILE" > "${STATE_FILE}.tmp"
  mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

# ============================================================================
# PROGRESS VISUALIZATION
# ============================================================================

# Generate progress bar
# Input: percentage (0-100)
# Output: Unicode progress bar string
generate_progress_bar() {
  local percent="$1"
  local bar_length=30

  # Calculate filled and empty sections
  local filled=$((bar_length * percent / 100))
  local empty=$((bar_length - filled))

  # Generate bar using Unicode block characters
  local bar=""
  for ((i=0; i<filled; i++)); do
    bar+="█"
  done
  for ((i=0; i<empty; i++)); do
    bar+="░"
  done

  echo "$bar"
}

# Display wave-based progress
# Input: none (reads from STATE_FILE)
display_wave_progress() {
  if [[ ! -f "$STATE_FILE" ]]; then
    >&2 echo "ERROR: State file not initialized"
    return 1
  fi

  local state
  state=$(cat "$STATE_FILE")

  # Extract metrics
  local total_phases
  total_phases=$(echo "$state" | jq '.metrics.total_phases')
  local waves_count
  waves_count=$(echo "$state" | jq '.waves | length')
  local parallel_phases
  parallel_phases=$(echo "$state" | jq '.metrics.parallel_phases')
  local seq_time
  seq_time=$(echo "$state" | jq -r '.metrics.sequential_estimated_time')
  local par_time
  par_time=$(echo "$state" | jq -r '.metrics.parallel_estimated_time')
  local savings
  savings=$(echo "$state" | jq -r '.metrics.time_savings_percentage')

  # Header
  echo "╔═══════════════════════════════════════════════════════════╗"
  echo "║ WAVE-BASED IMPLEMENTATION PROGRESS            ║"
  echo "╠═══════════════════════════════════════════════════════════╣"
  echo "║ Total Phases: $(printf '%-40s' "$total_phases")   ║"
  echo "║ Waves: $(printf '%-49s' "$waves_count")║"
  echo "║ Parallel Phases: $(printf '%-37s' "$parallel_phases")   ║"
  echo "║ Sequential Time: $(printf '%-37s' "$seq_time")   ║"
  echo "║ Parallel Time: $(printf '%-39s' "$par_time")   ║"
  echo "║ Time Savings: $(printf '%-40s' "$savings")   ║"
  echo "╠═══════════════════════════════════════════════════════════╣"

  # Display each wave
  local waves
  waves=$(echo "$state" | jq -c '.waves[]')

  while IFS= read -r wave; do
    local wave_num
    wave_num=$(echo "$wave" | jq '.wave_number')
    local wave_status
    wave_status=$(echo "$wave" | jq -r '.status')
    local phase_count
    phase_count=$(echo "$wave" | jq '.phases | length')

    # Wave header
    local wave_label="Wave $wave_num"
    if [[ $phase_count -gt 1 ]]; then
      wave_label+=" ($phase_count phases, PARALLEL)"
    else
      wave_label+=" ($phase_count phase)"
    fi

    echo "║ $(printf '%-58s' "$wave_label")║"

    # Wave status icon
    local status_icon
    case "$wave_status" in
      completed)
        status_icon="✓ Complete"
        ;;
      in_progress)
        status_icon="⏳ In Progress"
        ;;
      failed)
        status_icon="✗ Failed"
        ;;
      *)
        status_icon="⏸ Waiting"
        ;;
    esac
    echo "║ $(printf '%-58s' "$status_icon")║"

    # Display phases in wave
    local phases
    phases=$(echo "$wave" | jq -c '.phases[]')

    while IFS= read -r phase; do
      local phase_id
      phase_id=$(echo "$phase" | jq -r '.phase_id')
      local phase_status
      phase_status=$(echo "$phase" | jq -r '.status')
      local tasks_done
      tasks_done=$(echo "$phase" | jq '.tasks_completed')
      local tasks_total
      tasks_total=$(echo "$phase" | jq '.tasks_total')

      # Phase header
      echo "║ ├─ $(printf '%-53s' "$phase_id")║"

      # Progress bar (if tasks available)
      if [[ $tasks_total -gt 0 ]]; then
        local percent=$((tasks_done * 100 / tasks_total))
        local bar
        bar=$(generate_progress_bar "$percent")
        echo "║ │  └─ $(printf '%-48s' "$bar $percent% ($tasks_done/$tasks_total)")║"

        # Current task (if in progress)
        if [[ "$wave_status" == "in_progress" && "$phase_status" == "in_progress" ]]; then
          local current_task
          current_task=$(echo "$phase" | jq -r '.current_task' | cut -c1-50)
          if [[ -n "$current_task" ]]; then
            echo "║ │     Current: $(printf '%-41s' "$current_task")║"
          fi
        fi
      fi

      # Commit hash (if completed)
      if [[ "$phase_status" == "completed" ]]; then
        local commit_hash
        commit_hash=$(echo "$phase" | jq -r '.commit_hash // "N/A"')
        echo "║ │     Commit: $(printf '%-42s' "$commit_hash")║"
      fi

      # Error (if failed)
      if [[ "$phase_status" == "failed" ]]; then
        local error_summary
        error_summary=$(echo "$phase" | jq -r '.error_summary // "Unknown error"' | cut -c1-45)
        echo "║ │     Error: $(printf '%-43s' "$error_summary")║"
      fi

    done <<< "$phases"

    echo "╠═══════════════════════════════════════════════════════════╣"

  done <<< "$waves"

  # Overall progress
  local total_tasks=0
  local completed_tasks=0

  while IFS= read -r wave; do
    local phases
    phases=$(echo "$wave" | jq -c '.phases[]')

    while IFS= read -r phase; do
      local tasks_done
      tasks_done=$(echo "$phase" | jq '.tasks_completed')
      local tasks_total
      tasks_total=$(echo "$phase" | jq '.tasks_total')

      total_tasks=$((total_tasks + tasks_total))
      completed_tasks=$((completed_tasks + tasks_done))
    done <<< "$phases"
  done <<< "$waves"

  if [[ $total_tasks -gt 0 ]]; then
    local overall_percent=$((completed_tasks * 100 / total_tasks))
    local overall_bar
    overall_bar=$(generate_progress_bar "$overall_percent")
    echo "║ Overall Progress: $(printf '%-38s' "$overall_bar $overall_percent%")║"
    echo "║ Tasks: $(printf '%-49s' "$completed_tasks/$total_tasks")║"
  fi

  # Calculate elapsed time
  local start_time
  start_time=$(echo "$state" | jq -r '.start_time')
  local elapsed_seconds
  elapsed_seconds=$(( $(date +%s) - $(date -d "$start_time" +%s) ))
  local elapsed_hours=$((elapsed_seconds / 3600))
  local elapsed_mins=$(( (elapsed_seconds % 3600) / 60 ))
  echo "║ Elapsed Time: $(printf '%-40s' "${elapsed_hours}h ${elapsed_mins}m")   ║"

  echo "╚═══════════════════════════════════════════════════════════╝"
}

# Display compact progress (single line)
# Input: none (reads from STATE_FILE)
display_compact_progress() {
  if [[ ! -f "$STATE_FILE" ]]; then
    return 1
  fi

  local state
  state=$(cat "$STATE_FILE")

  # Count completed waves
  local total_waves
  total_waves=$(echo "$state" | jq '.waves | length')
  local completed_waves
  completed_waves=$(echo "$state" | jq '[.waves[] | select(.status == "completed")] | length')

  # Count completed phases
  local total_phases=0
  local completed_phases=0

  local waves
  waves=$(echo "$state" | jq -c '.waves[]')

  while IFS= read -r wave; do
    local phase_count
    phase_count=$(echo "$wave" | jq '.phases | length')
    total_phases=$((total_phases + phase_count))

    local completed_count
    completed_count=$(echo "$wave" | jq '[.phases[] | select(.status == "completed")] | length')
    completed_phases=$((completed_phases + completed_count))
  done <<< "$waves"

  echo "Wave $((completed_waves + 1))/$total_waves | Phases: $completed_phases/$total_phases"
}

# ============================================================================
# SUMMARY GENERATION
# ============================================================================

# Generate implementation summary
# Input: none (reads from STATE_FILE)
# Output: Summary text
generate_implementation_summary() {
  if [[ ! -f "$STATE_FILE" ]]; then
    >&2 echo "ERROR: State file not initialized"
    return 1
  fi

  local state
  state=$(cat "$STATE_FILE")

  # Extract metrics
  local total_phases
  total_phases=$(echo "$state" | jq '.metrics.total_phases')
  local waves_count
  waves_count=$(echo "$state" | jq '.waves | length')

  # Count completed and failed phases
  local completed_phases=0
  local failed_phases=0
  local git_commits=()

  local waves
  waves=$(echo "$state" | jq -c '.waves[]')

  while IFS= read -r wave; do
    local phases
    phases=$(echo "$wave" | jq -c '.phases[]')

    while IFS= read -r phase; do
      local status
      status=$(echo "$phase" | jq -r '.status')

      if [[ "$status" == "completed" ]]; then
        ((completed_phases++))
        local commit_hash
        commit_hash=$(echo "$phase" | jq -r '.commit_hash // ""')
        if [[ -n "$commit_hash" ]]; then
          git_commits+=("$commit_hash")
        fi
      elif [[ "$status" == "failed" ]]; then
        ((failed_phases++))
      fi
    done <<< "$phases"
  done <<< "$waves"

  # Calculate elapsed time
  local start_time
  start_time=$(echo "$state" | jq -r '.start_time')
  local elapsed_seconds
  elapsed_seconds=$(( $(date +%s) - $(date -d "$start_time" +%s) ))
  local elapsed_hours=$(echo "scale=1; $elapsed_seconds / 3600" | bc)

  # Determine status
  local status
  if [[ $failed_phases -gt 0 ]]; then
    if [[ $completed_phases -gt 0 ]]; then
      status="partial"
    else
      status="failed"
    fi
  else
    status="completed"
  fi

  # Generate summary
  cat <<EOF
═══════════════════════════════════════════════════════
WAVE-BASED IMPLEMENTATION REPORT
═══════════════════════════════════════════════════════
Status: $status
Waves Executed: $waves_count
Total Phases: $total_phases
Successful: $completed_phases
Failed: $failed_phases
Elapsed Time: ${elapsed_hours} hours
Time Savings: $(echo "$state" | jq -r '.metrics.time_savings_percentage')
Git Commits: ${#git_commits[@]}
═══════════════════════════════════════════════════════
EOF

  # List failed phases if any
  if [[ $failed_phases -gt 0 ]]; then
    echo ""
    echo "FAILED PHASES:"

    while IFS= read -r wave; do
      local phases
      phases=$(echo "$wave" | jq -c '.phases[]')

      while IFS= read -r phase; do
        local status
        status=$(echo "$phase" | jq -r '.status')

        if [[ "$status" == "failed" ]]; then
          local phase_id
          phase_id=$(echo "$phase" | jq -r '.phase_id')
          local error_summary
          error_summary=$(echo "$phase" | jq -r '.error_summary // "Unknown error"')
          echo "- $phase_id: $error_summary"
        fi
      done <<< "$phases"
    done <<< "$waves"
  fi

  # List git commits
  if [[ ${#git_commits[@]} -gt 0 ]]; then
    echo ""
    echo "GIT COMMITS:"
    for commit in "${git_commits[@]}"; do
      echo "- $commit"
    done
  fi
}

# ============================================================================
# CLEANUP
# ============================================================================

# Clean up state file
cleanup_state() {
  if [[ -f "$STATE_FILE" ]]; then
    rm -f "$STATE_FILE"
  fi
}

# ============================================================================
# MAIN ENTRY POINT (for testing)
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Test mode - display existing state if available
  if [[ -n "${1:-}" && -f "$1" ]]; then
    STATE_FILE="$1"
    display_wave_progress
  else
    echo "Usage: $0 <state-file>"
    echo "Or source this file to use the functions"
  fi
fi
