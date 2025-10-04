#!/usr/bin/env bash
# Adaptive Plan Parsing Utility
# Provides unified interface for parsing plans across all three tiers
# Usage: parse-adaptive-plan.sh <function> <plan_path> [args...]

set -e

# Error handling
error() {
  echo "Error: $*" >&2
  exit 1
}

# Detect plan tier (1=single file, 2=phase directory, 3=hierarchical)
# Usage: detect_plan_tier <plan_path>
detect_plan_tier() {
  local plan_path="$1"

  # If path ends with .md and is a file -> Tier 1
  if [[ "$plan_path" == *.md ]] && [[ -f "$plan_path" ]]; then
    echo "1"
    return 0
  fi

  # If path is a directory
  if [[ -d "$plan_path" ]]; then
    # Check for overview file
    local plan_name=$(basename "$plan_path")
    local overview="$plan_path/$plan_name.md"

    if [[ ! -f "$overview" ]]; then
      error "Directory plan missing overview file: $overview"
    fi

    # Check metadata for Structure Tier field
    if grep -q "^- \*\*Structure Tier\*\*: 3" "$overview" 2>/dev/null; then
      echo "3"
      return 0
    elif grep -q "^- \*\*Structure Tier\*\*: 2" "$overview" 2>/dev/null; then
      echo "2"
      return 0
    fi

    # Fallback: detect by structure
    # If there are subdirectories starting with "phase_", it's Tier 3
    if find "$plan_path" -maxdepth 1 -type d -name "phase_*" | grep -q .; then
      echo "3"
      return 0
    fi

    # If there are phase_*.md files, it's Tier 2
    if find "$plan_path" -maxdepth 1 -type f -name "phase_*.md" | grep -q .; then
      echo "2"
      return 0
    fi

    error "Cannot determine tier for directory: $plan_path"
  fi

  error "Invalid plan path: $plan_path (must be .md file or directory)"
}

# Get path to plan overview file
# Usage: get_plan_overview <plan_path>
get_plan_overview() {
  local plan_path="$1"
  local tier=$(detect_plan_tier "$plan_path")

  case $tier in
    1)
      # Single file - the file itself is the overview
      echo "$plan_path"
      ;;
    2|3)
      # Directory - overview is <plan_name>/<plan_name>.md
      local plan_name=$(basename "$plan_path")
      echo "$plan_path/$plan_name.md"
      ;;
  esac
}

# List all phase files/directories for a plan
# Usage: list_plan_phases <plan_path>
list_plan_phases() {
  local plan_path="$1"
  local tier=$(detect_plan_tier "$plan_path")

  case $tier in
    1)
      # Tier 1: Extract phase numbers from single file
      grep "^### Phase [0-9]" "$plan_path" | sed 's/^### Phase \([0-9]\+\).*/\1/'
      ;;
    2)
      # Tier 2: List phase_*.md files
      find "$plan_path" -maxdepth 1 -type f -name "phase_*.md" | sort | while read -r f; do
        basename "$f"
      done
      ;;
    3)
      # Tier 3: List phase_* directories
      find "$plan_path" -maxdepth 1 -type d -name "phase_*" | sort | while read -r d; do
        basename "$d"
      done
      ;;
  esac
}

# Get tasks for a specific phase
# Usage: get_phase_tasks <plan_path> <phase_num>
get_phase_tasks() {
  local plan_path="$1"
  local phase_num="$2"
  local tier=$(detect_plan_tier "$plan_path")

  case $tier in
    1)
      # Tier 1: Extract from single file between phase headers
      awk -v phase="$phase_num" '
        /^### Phase / {
          if ($3 == phase":") in_phase = 1
          else in_phase = 0
        }
        in_phase && /^- \[[ x]\]/ { print }
      ' "$plan_path"
      ;;
    2)
      # Tier 2: Read from phase_N_*.md file
      local phase_file=$(find "$plan_path" -maxdepth 1 -name "phase_${phase_num}_*.md" | head -1)
      if [[ -z "$phase_file" ]]; then
        error "Phase $phase_num file not found in $plan_path"
      fi
      grep "^- \[[ x]\]" "$phase_file" || true
      ;;
    3)
      # Tier 3: Read from all stage files in phase directory
      local phase_dir=$(find "$plan_path" -maxdepth 1 -type d -name "phase_${phase_num}_*" | head -1)
      if [[ -z "$phase_dir" ]]; then
        error "Phase $phase_num directory not found in $plan_path"
      fi

      # Get tasks from all stage files
      find "$phase_dir" -type f -name "stage_*.md" | sort | while read -r stage; do
        grep "^- \[[ x]\]" "$stage" || true
      done
      ;;
  esac
}

# Mark a specific task as complete
# Usage: mark_task_complete <plan_path> <phase_num> <task_num>
mark_task_complete() {
  local plan_path="$1"
  local phase_num="$2"
  local task_num="$3"
  local tier=$(detect_plan_tier "$plan_path")

  case $tier in
    1)
      # Tier 1: Update in single file
      # Find the Nth unchecked task in the specified phase
      local temp_file=$(mktemp)
      awk -v phase="$phase_num" -v task="$task_num" '
        /^### Phase / {
          if ($3 == phase":") { in_phase = 1; task_count = 0 }
          else in_phase = 0
        }
        in_phase && /^- \[ \]/ {
          task_count++
          if (task_count == task) {
            sub(/\[ \]/, "[x]")
          }
        }
        { print }
      ' "$plan_path" > "$temp_file"
      mv "$temp_file" "$plan_path"
      ;;
    2)
      # Tier 2: Update in phase file
      local phase_file=$(find "$plan_path" -maxdepth 1 -name "phase_${phase_num}_*.md" | head -1)
      if [[ -z "$phase_file" ]]; then
        error "Phase $phase_num file not found"
      fi

      local temp_file=$(mktemp)
      awk -v task="$task_num" '
        /^- \[ \]/ {
          task_count++
          if (task_count == task) {
            sub(/\[ \]/, "[x]")
          }
        }
        { print }
      ' "$phase_file" > "$temp_file"
      mv "$temp_file" "$phase_file"
      ;;
    3)
      # Tier 3: Update in appropriate stage file
      local phase_dir=$(find "$plan_path" -maxdepth 1 -type d -name "phase_${phase_num}_*" | head -1)
      if [[ -z "$phase_dir" ]]; then
        error "Phase $phase_num directory not found"
      fi

      # Count tasks across stage files to find the right one
      local current_count=0
      find "$phase_dir" -type f -name "stage_*.md" | sort | while read -r stage; do
        local stage_task_count=$(grep -c "^- \[ \]" "$stage" || echo 0)
        local next_count=$((current_count + stage_task_count))

        if (( task_num > current_count && task_num <= next_count )); then
          # This is the right stage file
          local stage_task_num=$((task_num - current_count))
          local temp_file=$(mktemp)

          awk -v task="$stage_task_num" '
            /^- \[ \]/ {
              task_count++
              if (task_count == task) {
                sub(/\[ \]/, "[x]")
              }
            }
            { print }
          ' "$stage" > "$temp_file"
          mv "$temp_file" "$stage"
          break
        fi

        current_count=$next_count
      done
      ;;
  esac
}

# Get phase status (complete|incomplete|not_started)
# Usage: get_phase_status <plan_path> <phase_num>
get_phase_status() {
  local plan_path="$1"
  local phase_num="$2"
  local tier=$(detect_plan_tier "$plan_path")

  case $tier in
    1)
      # Tier 1: Check for [COMPLETED] marker or all tasks done
      local phase_header=$(grep "^### Phase ${phase_num}:" "$plan_path" || echo "")

      if echo "$phase_header" | grep -q "\[COMPLETED\]"; then
        echo "complete"
        return 0
      fi

      # Count checked vs unchecked tasks
      local tasks=$(get_phase_tasks "$plan_path" "$phase_num")
      local total=$(echo "$tasks" | wc -l)
      local checked=$(echo "$tasks" | grep -c "\[x\]" || echo 0)
      local unchecked=$(echo "$tasks" | grep -c "\[ \]" || echo 0)

      if (( total == 0 )); then
        echo "not_started"
      elif (( unchecked == 0 )); then
        echo "complete"
      else
        echo "incomplete"
      fi
      ;;
    2)
      # Tier 2: Check phase file for completion
      local phase_file=$(find "$plan_path" -maxdepth 1 -name "phase_${phase_num}_*.md" | head -1)
      if [[ -z "$phase_file" ]]; then
        echo "not_started"
        return 0
      fi

      if grep -q "^## \[COMPLETED\]" "$phase_file" || grep -q "^# .* \[COMPLETED\]" "$phase_file"; then
        echo "complete"
        return 0
      fi

      local total=$(grep -c "^- \[[ x]\]" "$phase_file" || echo 0)
      local checked=$(grep -c "^- \[x\]" "$phase_file" || echo 0)

      if (( total == 0 )); then
        echo "not_started"
      elif (( checked == total )); then
        echo "complete"
      else
        echo "incomplete"
      fi
      ;;
    3)
      # Tier 3: Check phase overview and all stage files
      local phase_dir=$(find "$plan_path" -maxdepth 1 -type d -name "phase_${phase_num}_*" | head -1)
      if [[ -z "$phase_dir" ]]; then
        echo "not_started"
        return 0
      fi

      local overview="$phase_dir/phase_${phase_num}_overview.md"
      if [[ -f "$overview" ]] && grep -q "\[COMPLETED\]" "$overview"; then
        echo "complete"
        return 0
      fi

      # Check all stage files
      local all_complete=true
      local any_started=false

      find "$phase_dir" -type f -name "stage_*.md" | while read -r stage; do
        local total=$(grep -c "^- \[[ x]\]" "$stage" || echo 0)
        local checked=$(grep -c "^- \[x\]" "$stage" || echo 0)

        if (( total > 0 )); then
          any_started=true
          if (( checked < total )); then
            all_complete=false
          fi
        fi
      done

      if $all_complete && $any_started; then
        echo "complete"
      elif $any_started; then
        echo "incomplete"
      else
        echo "not_started"
      fi
      ;;
  esac
}

# Main function dispatcher
main() {
  if [[ $# -lt 2 ]]; then
    cat <<EOF
Usage: $0 <function> <plan_path> [args...]

Functions:
  detect_tier <plan_path>
    Returns: 1, 2, or 3

  get_overview <plan_path>
    Returns: Path to overview file

  list_phases <plan_path>
    Returns: List of phase files/directories

  get_tasks <plan_path> <phase_num>
    Returns: List of tasks for phase

  mark_complete <plan_path> <phase_num> <task_num>
    Marks task N in phase as complete

  get_status <plan_path> <phase_num>
    Returns: complete, incomplete, or not_started

Examples:
  $0 detect_tier specs/plans/024_feature/
  $0 list_phases specs/plans/024_feature/
  $0 get_tasks specs/plans/024_feature/ 1
  $0 mark_complete specs/plans/024_feature/ 1 3
  $0 get_status specs/plans/024_feature/ 1
EOF
    exit 1
  fi

  local function="$1"
  shift

  case "$function" in
    detect_tier)
      detect_plan_tier "$@"
      ;;
    get_overview)
      get_plan_overview "$@"
      ;;
    list_phases)
      list_plan_phases "$@"
      ;;
    get_tasks)
      get_phase_tasks "$@"
      ;;
    mark_complete)
      mark_task_complete "$@"
      ;;
    get_status)
      get_phase_status "$@"
      ;;
    *)
      error "Unknown function: $function"
      ;;
  esac
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
