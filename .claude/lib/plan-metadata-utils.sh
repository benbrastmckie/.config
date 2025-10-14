#!/usr/bin/env bash
# Plan Metadata Manipulation
# Provides functions for managing plan metadata and content revisions
# Usage: Source this file to use metadata manipulation functions

set -e

# Source error handling from parse-plan-core if needed
if ! declare -f error > /dev/null 2>&1; then
  error() {
    echo "Error: $*" >&2
    exit 1
  }
fi

# Revise main plan to replace phase content with summary and link
# Usage: revise_main_plan_for_phase <plan_file> <phase_num> <phase_filename>
revise_main_plan_for_phase() {
  local plan_file="$1"
  local phase_num="$2"
  local phase_filename="$3"

  # Extract objective from phase
  local objective=$(grep "^\*\*Objective\*\*:" "$plan_file" | awk -v phase="$phase_num" '
    NR == phase { sub(/^\*\*Objective\*\*: /, ""); print; exit }
  ')

  if [[ -z "$objective" ]]; then
    objective="See phase file for details"
  fi

  # Create temporary file
  local temp_file=$(mktemp)

  # Replace phase content with summary
  awk -v phase="$phase_num" -v obj="$objective" -v link="$phase_filename" '
    /^### Phase / {
      # Match phase number in field 3 (handles both "Phase 3:" and "Phase 3 Name")
      # Field 1 = "###", Field 2 = "Phase", Field 3 = number (possibly with colon)
      phase_field = $3
      gsub(/:/, "", phase_field)  # Remove colon if present
      phase_match = (phase_field == phase)
      if (phase_match) {
        in_phase = 1
        # Print heading
        print
        # Print summary
        print "**Objective**: " obj
        print "**Status**: [PENDING]"
        print ""
        print "For detailed tasks and implementation, see [Phase " phase " Details](" link ")"
        print ""
        next
      } else if (in_phase) {
        in_phase = 0
      }
    }
    /^## / && in_phase {
      # New major section, end skipping
      in_phase = 0
    }
    !in_phase { print }
  ' "$plan_file" > "$temp_file"

  mv "$temp_file" "$plan_file"
}

# Add phase metadata to phase file
# Usage: add_phase_metadata <phase_file> <phase_num> <parent_plan_name>
add_phase_metadata() {
  local phase_file="$1"
  local phase_num="$2"
  local parent_plan="$3"

  # Create temporary file
  local temp_file=$(mktemp)

  # Add metadata after phase heading
  awk -v num="$phase_num" -v parent="$parent_plan" '
    /^### Phase / && !metadata_added {
      print
      print ""
      print "## Metadata"
      print "- **Phase Number**: " num
      print "- **Parent Plan**: " parent
      print ""
      metadata_added = 1
      next
    }
    { print }
  ' "$phase_file" > "$temp_file"

  mv "$temp_file" "$phase_file"
}

# Add update reminder to phase file
# Usage: add_update_reminder <phase_file> <phase_description> <parent_plan_name>
add_update_reminder() {
  local phase_file="$1"
  local phase_desc="$2"
  local parent_plan="$3"

  # Append to end of file
  cat >> "$phase_file" <<EOF

## Update Reminder
When phase complete, mark $phase_desc as [COMPLETED] in main plan: \`$parent_plan\`
EOF
}

# Update Structure Level metadata in plan file
# Usage: update_structure_level <plan_file> <level>
update_structure_level() {
  local plan_file="$1"
  local level="$2"

  # Check if metadata exists
  if grep -q "^- \*\*Structure Level\*\*:" "$plan_file"; then
    # Update existing
    sed -i "s/^- \*\*Structure Level\*\*:.*/- **Structure Level**: $level/" "$plan_file"
  else
    # Add after other metadata (after Structure Tier if exists, or after Plan Number)
    local temp_file=$(mktemp)
    awk -v lvl="$level" '
      /^- \*\*Structure Tier\*\*:/ {
        print
        print "- **Structure Level**: " lvl
        next
      }
      /^- \*\*Plan Number\*\*:/ {
        print
        if (!added) {
          print "- **Structure Level**: " lvl
          added = 1
        }
        next
      }
      { print }
    ' "$plan_file" > "$temp_file"
    mv "$temp_file" "$plan_file"
  fi
}

# Update Expanded Phases metadata
# Usage: update_expanded_phases <plan_file> <phase_num>
update_expanded_phases() {
  local plan_file="$1"
  local phase_num="$2"

  # Get current expanded phases
  local current=$(grep "^- \*\*Expanded Phases\*\*:" "$plan_file" 2>/dev/null | sed 's/^- \*\*Expanded Phases\*\*: \[\(.*\)\]/\1/')

  # Add new phase number if not already present
  if [[ -z "$current" ]]; then
    new_list="[$phase_num]"
  elif [[ ! "$current" =~ (^|, )$phase_num(,|$) ]]; then
    new_list="[$current, $phase_num]"
  else
    # Already in list
    return 0
  fi

  # Update or add metadata
  if grep -q "^- \*\*Expanded Phases\*\*:" "$plan_file"; then
    sed -i "s/^- \*\*Expanded Phases\*\*:.*/- **Expanded Phases**: $new_list/" "$plan_file"
  else
    # Add after Structure Level
    local temp_file=$(mktemp)
    awk -v list="$new_list" '
      /^- \*\*Structure Level\*\*:/ {
        print
        print "- **Expanded Phases**: " list
        added = 1
        next
      }
      { print }
    ' "$plan_file" > "$temp_file"
    mv "$temp_file" "$plan_file"
  fi
}

# Update Stage Expansion Candidates metadata
# Usage: update_stage_candidates <plan_file> <phase_num> <is_candidate>
update_stage_candidates() {
  local plan_file="$1"
  local phase_num="$2"
  local is_candidate="$3"  # "Yes" or "No"

  # Only add if candidate is "Yes"
  if [[ "$is_candidate" != "Yes" ]]; then
    return 0
  fi

  # Get current candidates
  local current=$(grep "^- \*\*Stage Expansion Candidates\*\*:" "$plan_file" 2>/dev/null | sed 's/^- \*\*Stage Expansion Candidates\*\*: \[\(.*\)\]/\1/')

  # Add phase number if not already present
  if [[ -z "$current" ]]; then
    new_list="[$phase_num]"
  elif [[ ! "$current" =~ (^|, )$phase_num(,|$) ]]; then
    new_list="[$current, $phase_num]"
  else
    # Already in list
    return 0
  fi

  # Update or add metadata
  if grep -q "^- \*\*Stage Expansion Candidates\*\*:" "$plan_file"; then
    sed -i "s/^- \*\*Stage Expansion Candidates\*\*:.*/- **Stage Expansion Candidates**: $new_list/" "$plan_file"
  else
    # Add after Expanded Phases
    local temp_file=$(mktemp)
    awk -v list="$new_list" '
      /^- \*\*Expanded Phases\*\*:/ {
        print
        print "- **Stage Expansion Candidates**: " list
        next
      }
      { print }
    ' "$plan_file" > "$temp_file"
    mv "$temp_file" "$plan_file"
  fi
}

# Revise phase file to replace stage content with summary and link
# Usage: revise_phase_file_for_stage <phase_file> <stage_num> <stage_filename>
revise_phase_file_for_stage() {
  local phase_file="$1"
  local stage_num="$2"
  local stage_filename="$3"

  # Extract objective from stage
  local objective=$(grep "^\*\*Objective\*\*:" "$phase_file" | awk -v stage="$stage_num" '
    NR == stage { sub(/^\*\*Objective\*\*: /, ""); print; exit }
  ')

  if [[ -z "$objective" ]]; then
    objective="See stage file for details"
  fi

  # Create temporary file
  local temp_file=$(mktemp)

  # Replace stage content with summary
  awk -v stage="$stage_num" -v obj="$objective" -v link="$stage_filename" '
    /^#### Stage / {
      stage_match = ($3 ~ "^" stage ":")
      if (stage_match) {
        in_stage = 1
        # Print heading
        print
        # Print summary
        print "**Objective**: " obj
        print ""
        print "For detailed tasks, see [Stage " stage " Details](" link ")"
        print ""
        next
      } else if (in_stage) {
        in_stage = 0
      }
    }
    /^### / && in_stage {
      # New phase section, end skipping
      in_stage = 0
    }
    /^## / && in_stage {
      # New major section, end skipping
      in_stage = 0
    }
    !in_stage { print }
  ' "$phase_file" > "$temp_file"

  mv "$temp_file" "$phase_file"
}

# Add stage metadata to stage file
# Usage: add_stage_metadata <stage_file> <stage_num> <parent_phase_name>
add_stage_metadata() {
  local stage_file="$1"
  local stage_num="$2"
  local parent_phase="$3"

  # Create temporary file
  local temp_file=$(mktemp)

  # Add metadata after stage heading
  awk -v num="$stage_num" -v parent="$parent_phase" '
    /^#### Stage / && !metadata_added {
      print
      print ""
      print "## Metadata"
      print "- **Stage Number**: " num
      print "- **Parent Phase**: " parent
      print ""
      metadata_added = 1
      next
    }
    { print }
  ' "$stage_file" > "$temp_file"

  mv "$temp_file" "$stage_file"
}

# Update Expanded Stages metadata in phase file
# Usage: update_phase_expanded_stages <phase_file> <stage_num>
update_phase_expanded_stages() {
  local phase_file="$1"
  local stage_num="$2"

  # Get current expanded stages
  local current=$(grep "^- \*\*Expanded Stages\*\*:" "$phase_file" 2>/dev/null | sed 's/^- \*\*Expanded Stages\*\*: \[\(.*\)\]/\1/')

  # Add new stage number if not already present
  if [[ -z "$current" ]]; then
    new_list="[$stage_num]"
  elif [[ ! "$current" =~ (^|, )$stage_num(,|$) ]]; then
    new_list="[$current, $stage_num]"
  else
    # Already in list
    return 0
  fi

  # Update or add metadata
  if grep -q "^- \*\*Expanded Stages\*\*:" "$phase_file"; then
    sed -i "s/^- \*\*Expanded Stages\*\*:.*/- **Expanded Stages**: $new_list/" "$phase_file"
  else
    # Add after Phase Number
    local temp_file=$(mktemp)
    awk -v list="$new_list" '
      /^- \*\*Parent Plan\*\*:/ {
        print
        print "- **Expanded Stages**: " list
        next
      }
      { print }
    ' "$phase_file" > "$temp_file"
    mv "$temp_file" "$phase_file"
  fi
}

# Update Expanded Stages metadata in main plan (dict format: {phase: [stages]})
# Usage: update_plan_expanded_stages <plan_file> <phase_num> <stage_num>
update_plan_expanded_stages() {
  local plan_file="$1"
  local phase_num="$2"
  local stage_num="$3"

  # Get current expanded stages (dict format)
  local current=$(grep "^- \*\*Expanded Stages\*\*:" "$plan_file" 2>/dev/null | sed 's/^- \*\*Expanded Stages\*\*: //')

  # If no existing expanded stages, create new dict
  if [[ -z "$current" ]]; then
    new_dict="{$phase_num: [$stage_num]}"
  else
    # Parse existing dict and update
    # This is a simplified version - assumes well-formed input
    if echo "$current" | grep -q "$phase_num:"; then
      # Phase already has stages, add to list
      # Extract current stage list for this phase
      local phase_stages=$(echo "$current" | sed -n "s/.*$phase_num: \[\([^]]*\)\].*/\1/p")
      if [[ ! "$phase_stages" =~ (^|, )$stage_num(,|$) ]]; then
        # Add stage to list
        new_dict=$(echo "$current" | sed "s/$phase_num: \[$phase_stages\]/$phase_num: [$phase_stages, $stage_num]/")
      else
        # Already in list
        return 0
      fi
    else
      # Phase not in dict, add new entry
      # Remove closing brace, add new entry, add closing brace
      new_dict=$(echo "$current" | sed "s/}$/, $phase_num: [$stage_num]}/")
    fi
  fi

  # Update or add metadata
  if grep -q "^- \*\*Expanded Stages\*\*:" "$plan_file"; then
    # Escape special characters for sed
    local escaped_dict=$(echo "$new_dict" | sed 's/[&/\]/\\&/g')
    sed -i "s/^- \*\*Expanded Stages\*\*:.*/- **Expanded Stages**: $escaped_dict/" "$plan_file"
  else
    # Add after Expanded Phases
    local temp_file=$(mktemp)
    awk -v dict="$new_dict" '
      /^- \*\*Expanded Phases\*\*:/ {
        print
        print "- **Expanded Stages**: " dict
        next
      }
      { print }
    ' "$plan_file" > "$temp_file"
    mv "$temp_file" "$plan_file"
  fi
}

# Merge phase file content back into main plan
# Usage: merge_phase_into_plan <plan_file> <phase_file> <phase_num>
merge_phase_into_plan() {
  local plan_file="$1"
  local phase_file="$2"
  local phase_num="$3"

  # Create temporary files
  local phase_content_file=$(mktemp)
  local temp_file=$(mktemp)

  # Extract phase content (skip metadata and update reminder sections)
  awk '
    /^## Update Reminder/ { exit }
    /^## Metadata/ { in_metadata = 1; next }
    in_metadata && /^$/ { in_metadata = 0; next }
    in_metadata && /^- \*\*/ { next }
    { print }
  ' "$phase_file" > "$phase_content_file"

  # Replace summary in main plan with full content
  awk -v phase="$phase_num" -v content_file="$phase_content_file" '
    BEGIN { in_phase = 0 }
    /^### Phase / {
      phase_match = ($3 ~ "^" phase ":")
      if (phase_match && !in_phase) {
        in_phase = 1
        # Insert full phase content from file
        while ((getline line < content_file) > 0) {
          print line
        }
        close(content_file)
        next
      } else if (in_phase && !phase_match) {
        # Different phase found, stop skipping
        in_phase = 0
        print
        next
      }
    }
    # Skip lines while in the phase being replaced
    in_phase { next }
    # Print all other lines
    { print }
  ' "$plan_file" > "$temp_file"

  mv "$temp_file" "$plan_file"
  rm -f "$phase_content_file"
}

# Merge stage file content back into phase file
# Usage: merge_stage_into_phase <phase_file> <stage_file> <stage_num>
merge_stage_into_phase() {
  local phase_file="$1"
  local stage_file="$2"
  local stage_num="$3"

  # Create temporary files
  local stage_content_file=$(mktemp)
  local temp_file=$(mktemp)

  # Extract stage content (skip metadata and update reminder sections)
  awk '
    /^## Update Reminder/ { exit }
    /^## Metadata/ { in_metadata = 1; next }
    in_metadata && /^$/ { in_metadata = 0; next }
    in_metadata && /^- \*\*/ { next }
    { print }
  ' "$stage_file" > "$stage_content_file"

  # Replace summary in phase file with full content
  awk -v stage="$stage_num" -v content_file="$stage_content_file" '
    BEGIN { in_stage = 0 }
    /^#### Stage / {
      stage_match = ($3 ~ "^" stage ":")
      if (stage_match && !in_stage) {
        in_stage = 1
        # Insert full stage content from file
        while ((getline line < content_file) > 0) {
          print line
        }
        close(content_file)
        next
      } else if (in_stage && !stage_match) {
        # Different stage found, stop skipping
        in_stage = 0
        print
        next
      }
    }
    /^### / && in_stage {
      # New phase section, stop skipping
      in_stage = 0
      print
      next
    }
    # Skip lines while in the stage being replaced
    in_stage { next }
    # Print all other lines
    { print }
  ' "$phase_file" > "$temp_file"

  mv "$temp_file" "$phase_file"
  rm -f "$stage_content_file"
}

# Remove phase from Expanded Phases metadata
# Usage: remove_expanded_phase <plan_file> <phase_num>
remove_expanded_phase() {
  local plan_file="$1"
  local phase_num="$2"

  # Get current expanded phases
  local current=$(grep "^- \*\*Expanded Phases\*\*:" "$plan_file" 2>/dev/null | sed 's/^- \*\*Expanded Phases\*\*: \[\(.*\)\]/\1/')

  if [[ -z "$current" ]]; then
    return 0
  fi

  # Remove phase number from list
  local new_list=$(echo "$current" | sed "s/\b$phase_num\b//g" | sed 's/, ,/,/g' | sed 's/^, //g' | sed 's/, $//g')

  if [[ -z "$new_list" ]]; then
    # No more expanded phases, remove the line
    sed -i "/^- \*\*Expanded Phases\*\*:/d" "$plan_file"
  else
    # Update with new list
    sed -i "s/^- \*\*Expanded Phases\*\*:.*/- **Expanded Phases**: [$new_list]/" "$plan_file"
  fi
}

# Remove stage from Expanded Stages metadata in phase file
# Usage: remove_phase_expanded_stage <phase_file> <stage_num>
remove_phase_expanded_stage() {
  local phase_file="$1"
  local stage_num="$2"

  # Get current expanded stages
  local current=$(grep "^- \*\*Expanded Stages\*\*:" "$phase_file" 2>/dev/null | sed 's/^- \*\*Expanded Stages\*\*: \[\(.*\)\]/\1/')

  if [[ -z "$current" ]]; then
    return 0
  fi

  # Remove stage number from list
  local new_list=$(echo "$current" | sed "s/\b$stage_num\b//g" | sed 's/, ,/,/g' | sed 's/^, //g' | sed 's/, $//g')

  if [[ -z "$new_list" ]]; then
    # No more expanded stages, remove the line
    sed -i "/^- \*\*Expanded Stages\*\*:/d" "$phase_file"
  else
    # Update with new list
    sed -i "s/^- \*\*Expanded Stages\*\*:.*/- **Expanded Stages**: [$new_list]/" "$phase_file"
  fi
}

# Remove stage from Expanded Stages metadata in main plan
# Usage: remove_plan_expanded_stage <plan_file> <phase_num> <stage_num>
remove_plan_expanded_stage() {
  local plan_file="$1"
  local phase_num="$2"
  local stage_num="$3"

  # Get current expanded stages (dict format)
  local current=$(grep "^- \*\*Expanded Stages\*\*:" "$plan_file" 2>/dev/null | sed 's/^- \*\*Expanded Stages\*\*: //')

  if [[ -z "$current" ]]; then
    return 0
  fi

  # Extract stage list for this phase
  local phase_stages=$(echo "$current" | sed -n "s/.*$phase_num: \[\([^]]*\)\].*/\1/p")

  if [[ -z "$phase_stages" ]]; then
    return 0
  fi

  # Remove stage from list
  local new_stages=$(echo "$phase_stages" | sed "s/\b$stage_num\b//g" | sed 's/, ,/,/g' | sed 's/^, //g' | sed 's/, $//g')

  if [[ -z "$new_stages" ]]; then
    # No more stages for this phase, remove phase entry
    local new_dict=$(echo "$current" | sed "s/, *$phase_num: \[[^]]*\]//g" | sed "s/$phase_num: \[[^]]*\], *//g")
    if [[ "$new_dict" == "{}" ]] || [[ -z "$new_dict" ]]; then
      # No more expanded stages at all, remove line
      sed -i "/^- \*\*Expanded Stages\*\*:/d" "$plan_file"
    else
      sed -i "s#^- \*\*Expanded Stages\*\*:.*#- **Expanded Stages**: $new_dict#" "$plan_file"
    fi
  else
    # Update stage list for phase
    local new_dict=$(echo "$current" | sed "s/$phase_num: \[$phase_stages\]/$phase_num: [$new_stages]/")
    sed -i "s#^- \*\*Expanded Stages\*\*:.*#- **Expanded Stages**: $new_dict#" "$plan_file"
  fi
}

# Export functions for sourcing
export -f error
export -f revise_main_plan_for_phase
export -f add_phase_metadata
export -f add_update_reminder
export -f update_structure_level
export -f update_expanded_phases
export -f update_stage_candidates
export -f revise_phase_file_for_stage
export -f add_stage_metadata
export -f update_phase_expanded_stages
export -f update_plan_expanded_stages
export -f merge_phase_into_plan
export -f merge_stage_into_phase
export -f remove_expanded_phase
export -f remove_phase_expanded_stage
export -f remove_plan_expanded_stage
