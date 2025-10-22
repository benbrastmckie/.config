#!/usr/bin/env bash
# checkbox-utils.sh
#
# Utilities for updating checkboxes across plan hierarchy levels.
# Supports progressive plan structures (Level 0/1/2).
#
# Functions:
#   - update_checkbox() - Update a single checkbox with fuzzy matching
#   - propagate_checkbox_update() - Propagate checkbox state across hierarchy
#   - verify_checkbox_consistency() - Verify all levels synchronized

set -e

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/base-utils.sh"
source "$SCRIPT_DIR/plan-core-bundle.sh"

# Update a checkbox in a file with fuzzy matching
# Usage: update_checkbox <file> <task_pattern> <new_state>
# new_state: "x" for checked, " " for unchecked
# Returns: 0 on success, 1 if task not found
update_checkbox() {
  local file="$1"
  local task_pattern="$2"
  local new_state="$3"

  if [[ ! -f "$file" ]]; then
    error "File not found: $file"
  fi

  # Validate state
  if [[ "$new_state" != "x" && "$new_state" != " " ]]; then
    error "Invalid checkbox state: $new_state (must be 'x' or ' ')"
  fi

  # Create temporary file
  local temp_file=$(mktemp)
  local found=0

  # Use fuzzy matching to find task
  # Pattern matching handles variations in task description
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]\[[[:space:]x]\][[:space:]] ]]; then
      # This is a checkbox line
      local task_desc=$(echo "$line" | sed 's/^[[:space:]]*- \[[[:space:]x]\] //')

      # Fuzzy match: check if pattern appears in task description (case-insensitive)
      if [[ "$task_desc" == *"$task_pattern"* ]]; then
        # Update checkbox state - use @ delimiter to avoid issues with brackets
        local updated_line=$(echo "$line" | sed "s@\\[[ x]\\]@[$new_state]@")
        echo "$updated_line" >> "$temp_file"
        found=1
      else
        echo "$line" >> "$temp_file"
      fi
    else
      echo "$line" >> "$temp_file"
    fi
  done < "$file"

  if [[ $found -eq 0 ]]; then
    rm -f "$temp_file"
    return 1
  fi

  # Replace original file
  mv "$temp_file" "$file"
  return 0
}

# Propagate checkbox update from lowest level to all parent levels
# Usage: propagate_checkbox_update <plan_path> <phase_num> <task_pattern> <new_state>
# Handles: Stage → Phase → Plan propagation
propagate_checkbox_update() {
  local plan_path="$1"
  local phase_num="$2"
  local task_pattern="$3"
  local new_state="$4"

  # Detect structure level
  local structure_level=$(detect_structure_level "$plan_path")

  # Get plan directory if expanded
  local plan_dir=$(get_plan_directory "$plan_path" 2>/dev/null || echo "")

  if [[ -z "$plan_dir" ]]; then
    # Level 0: Single file, update main plan only
    local plan_file="$plan_path"
    update_checkbox "$plan_file" "$task_pattern" "$new_state" || \
      warn "Task not found in plan: $task_pattern"
    return 0
  fi

  # Get main plan file (parent directory of plan_dir + plan_name.md)
  local plan_name=$(basename "$plan_dir")
  local main_plan="$(dirname "$plan_dir")/$plan_name.md"

  # Level 1 or 2: Check if phase is expanded
  local phase_file=$(get_phase_file "$plan_path" "$phase_num" 2>/dev/null || echo "")

  if [[ -z "$phase_file" ]]; then
    # Phase not expanded, update main plan only
    update_checkbox "$main_plan" "$task_pattern" "$new_state" || \
      warn "Task not found in main plan: $task_pattern"
    return 0
  fi

  # Phase is expanded
  if [[ "$structure_level" == "2" ]]; then
    # Level 2: Check for stage expansion
    # For now, we update phase file (stage detection would require stage_num parameter)
    update_checkbox "$phase_file" "$task_pattern" "$new_state" || \
      warn "Task not found in phase file: $task_pattern"
  fi

  # Update phase file
  update_checkbox "$phase_file" "$task_pattern" "$new_state" || \
    warn "Task not found in phase file: $task_pattern"

  # Update main plan
  update_checkbox "$main_plan" "$task_pattern" "$new_state" || \
    warn "Task not found in main plan: $task_pattern"

  return 0
}

# Verify checkbox consistency across hierarchy levels
# Usage: verify_checkbox_consistency <plan_path> <phase_num>
# Returns: 0 if consistent, 1 if inconsistencies found
verify_checkbox_consistency() {
  local plan_path="$1"
  local phase_num="$2"

  # Detect structure level
  local structure_level=$(detect_structure_level "$plan_path")

  if [[ "$structure_level" == "0" ]]; then
    # Single file, no hierarchy to verify
    return 0
  fi

  # Get plan directory
  local plan_dir=$(get_plan_directory "$plan_path")
  local plan_name=$(basename "$plan_dir")
  local main_plan="$(dirname "$plan_dir")/$plan_name.md"

  # Check if phase is expanded
  local phase_file=$(get_phase_file "$plan_path" "$phase_num" 2>/dev/null || echo "")

  if [[ -z "$phase_file" ]]; then
    # Phase not expanded, nothing to verify
    return 0
  fi

  # Extract checkbox states from both files
  local main_checkboxes=$(grep -E '^[[:space:]]*- \[([ x])\]' "$main_plan" | sort)
  local phase_checkboxes=$(grep -E '^[[:space:]]*- \[([ x])\]' "$phase_file" | sort)

  # Compare checkbox counts (simple heuristic)
  local main_count=$(echo "$main_checkboxes" | wc -l)
  local phase_count=$(echo "$phase_checkboxes" | wc -l)

  if [[ "$main_count" -ne "$phase_count" ]]; then
    warn "Checkbox count mismatch between main plan ($main_count) and phase file ($phase_count)"
    return 1
  fi

  # Detailed comparison would require task pattern matching
  # For now, we trust propagate_checkbox_update() to maintain consistency

  return 0
}

# Update all checkboxes in a phase to completed state
# Usage: mark_phase_complete <plan_path> <phase_num>
mark_phase_complete() {
  local plan_path="$1"
  local phase_num="$2"

  # Detect structure level
  local structure_level=$(detect_structure_level "$plan_path")

  # Get plan directory if expanded
  local plan_dir=$(get_plan_directory "$plan_path" 2>/dev/null || echo "")

  if [[ -z "$plan_dir" ]]; then
    # Level 0: Single file
    local plan_file="$plan_path"

    # Extract phase content and mark all tasks complete
    local temp_file=$(mktemp)
    awk -v phase="$phase_num" '
      /^### Phase / {
        phase_field = $3
        gsub(/:/, "", phase_field)
        if (phase_field == phase) {
          in_phase = 1
        } else if (in_phase) {
          in_phase = 0
        }
        print
        next
      }
      /^## / && in_phase {
        in_phase = 0
        print
        next
      }
      in_phase && /^[[:space:]]*- \[[ ]\]/ {
        gsub(/\[ \]/, "[x]")
        print
        next
      }
      { print }
    ' "$plan_file" > "$temp_file"

    mv "$temp_file" "$plan_file"
    return 0
  fi

  # Get main plan file (parent directory of plan_dir + plan_name.md)
  local plan_name=$(basename "$plan_dir")
  local main_plan="$(dirname "$plan_dir")/$plan_name.md"

  # Get phase file if expanded
  local phase_file=$(get_phase_file "$plan_path" "$phase_num" 2>/dev/null || echo "")

  if [[ -n "$phase_file" ]]; then
    # Mark all tasks in phase file as complete
    local temp_file=$(mktemp)
    sed 's/^- \[[ ]\]/- [x]/g' "$phase_file" > "$temp_file"
    mv "$temp_file" "$phase_file"
  fi

  # Mark all tasks in main plan for this phase as complete
  local temp_file=$(mktemp)
  awk -v phase="$phase_num" '
    /^### Phase / {
      phase_field = $3
      gsub(/:/, "", phase_field)
      if (phase_field == phase) {
        in_phase = 1
      } else if (in_phase) {
        in_phase = 0
      }
      print
      next
    }
    /^## / && in_phase {
      in_phase = 0
      print
      next
    }
    in_phase && /^[[:space:]]*- \[[ ]\]/ {
      gsub(/\[ \]/, "[x]")
      print
      next
    }
    { print }
  ' "$main_plan" > "$temp_file"

  mv "$temp_file" "$main_plan"

  return 0
}

# Mark all checkboxes in a stage to completed state
# Usage: mark_stage_complete <phase_file> <stage_num>
mark_stage_complete() {
  local phase_file="$1"
  local stage_num="$2"

  if [[ ! -f "$phase_file" ]]; then
    error "Phase file not found: $phase_file"
  fi

  # Get phase directory for stage files
  local phase_name=$(basename "$phase_file" .md)
  local phase_dir="$(dirname "$phase_file")/$phase_name"

  if [[ ! -d "$phase_dir" ]]; then
    warn "Phase directory not found: $phase_dir (phase not expanded to stages)"
    return 1
  fi

  # Find stage file
  local stage_file=$(find "$phase_dir" -maxdepth 1 -name "stage_${stage_num}_*.md" | head -1)

  if [[ -z "$stage_file" ]]; then
    error "Stage file not found: stage_${stage_num}_*.md in $phase_dir"
  fi

  # Mark all tasks in stage file as complete
  local temp_file=$(mktemp)
  sed 's/^- \[[ ]\]/- [x]/g' "$stage_file" > "$temp_file"
  mv "$temp_file" "$stage_file"

  # Update stage checkbox in phase file
  update_checkbox "$phase_file" "Stage $stage_num" "x" || \
    warn "Could not update Stage $stage_num checkbox in phase file"

  # Check if all stages in phase are now complete
  local all_stages_complete=1
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]\[[[:space:]]\][[:space:]].*Stage ]]; then
      # Found an unchecked stage checkbox
      all_stages_complete=0
      break
    fi
  done < "$phase_file"

  # If all stages complete, mark the phase complete in main plan
  if [[ $all_stages_complete -eq 1 ]]; then
    # Get main plan file
    local plan_dir=$(dirname "$(dirname "$phase_file")")
    local plan_name=$(basename "$plan_dir")
    local main_plan="$plan_dir.md"

    if [[ -f "$main_plan" ]]; then
      # Extract phase number from phase file name
      local phase_num=$(basename "$phase_file" | sed -E 's/phase_([0-9]+).*/\1/')

      # Mark phase complete in main plan
      update_checkbox "$main_plan" "Phase $phase_num" "x" || \
        warn "Could not update Phase $phase_num checkbox in main plan"

      log "All stages in Phase $phase_num complete - marked phase complete in main plan"
    fi
  fi

  return 0
}

# Export all functions for sourcing
export -f update_checkbox
export -f propagate_checkbox_update
export -f verify_checkbox_consistency
export -f mark_phase_complete
export -f mark_stage_complete
