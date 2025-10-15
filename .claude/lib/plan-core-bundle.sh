#!/usr/bin/env bash
# plan-core-bundle.sh
#
# Bundled planning utilities for common plan operations.
# Combines: parse-plan-core.sh, plan-metadata-utils.sh, plan-structure-utils.sh
#
# This bundle is created because these three utilities are always sourced together.
# Total: ~1,143 lines (138 + 607 + 396)
#
# Functions from parse-plan-core.sh:
#   - extract_phase_name() - Extract phase name from heading
#   - extract_phase_content() - Extract full phase content
#   - extract_stage_name() - Extract stage name from heading
#   - extract_stage_content() - Extract full stage content
#
# Functions from plan-metadata-utils.sh:
#   - revise_main_plan_for_phase() - Replace phase content with summary
#   - add_phase_metadata() - Add metadata to phase file
#   - add_update_reminder() - Add reminder to phase file
#   - update_structure_level() - Update structure level metadata
#   - update_expanded_phases() - Update expanded phases metadata
#   - update_stage_candidates() - Update stage expansion candidates
#   - revise_phase_file_for_stage() - Replace stage content with summary
#   - add_stage_metadata() - Add metadata to stage file
#   - update_phase_expanded_stages() - Update expanded stages in phase
#   - update_plan_expanded_stages() - Update expanded stages in plan
#   - merge_phase_into_plan() - Merge phase file back into plan
#   - merge_stage_into_phase() - Merge stage file back into phase
#   - remove_expanded_phase() - Remove phase from metadata
#   - remove_phase_expanded_stage() - Remove stage from phase metadata
#   - remove_plan_expanded_stage() - Remove stage from plan metadata
#
# Functions from plan-structure-utils.sh:
#   - detect_structure_level() - Detect plan structure level (0/1/2)
#   - is_plan_expanded() - Check if plan has directory
#   - get_plan_directory() - Get plan directory path
#   - is_phase_expanded() - Check if phase is expanded
#   - get_phase_file() - Get phase file path
#   - is_stage_expanded() - Check if stage is expanded
#   - list_expanded_phases() - List expanded phase numbers
#   - list_expanded_stages() - List expanded stage numbers
#   - has_remaining_phases() - Check if directory has phases
#   - has_remaining_stages() - Check if phase has stages
#   - cleanup_plan_directory() - Move plan file and delete directory
#   - cleanup_phase_directory() - Move phase file and delete directory

set -e

# Source base utilities for common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/base-utils.sh"

# ============================================================================
# SECTION 1: CORE PARSING (from parse-plan-core.sh - 138 lines)
# ============================================================================

# Extract phase name from phase heading
# Usage: extract_phase_name <plan_file> <phase_num>
extract_phase_name() {
  local plan_file="$1"
  local phase_num="$2"

  # Extract phase heading - handles both "### Phase 2: Implementation" and "### Phase 2 Implementation"
  local heading=$(grep "^### Phase ${phase_num}" "$plan_file" | grep -v '```' | head -1)
  if [[ -z "$heading" ]]; then
    error "Phase $phase_num not found in plan"
  fi

  # Extract name after phase number (with or without colon)
  # Remove optional colon, status tags, convert to lowercase, replace spaces with underscores
  # Also remove special characters that are invalid in filenames
  local name=$(echo "$heading" | sed "s/^### Phase ${phase_num}:* //" | sed 's/ \[.*\]$//' | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -d '/:*?"<>|&')
  echo "$name"
}

# Extract full phase content from plan file
# Usage: extract_phase_content <plan_file> <phase_num>
extract_phase_content() {
  local plan_file="$1"
  local phase_num="$2"

  # Extract everything from the phase heading to the next phase heading or end of phases section
  # IMPORTANT: Skip code blocks when detecting phase boundaries to avoid treating
  # code examples (like "### Not a phase") as actual phase headers
  awk -v phase="$phase_num" '
    # Track code block state (fenced with ```)
    /^```/ {
      in_code_block = !in_code_block
      if (in_phase) print
      next
    }

    # Only detect phase boundaries outside code blocks
    /^### Phase / && !in_code_block {
      # Match phase number in field 3 (handles both "Phase 3:" and "Phase 3 Name")
      # Field 1 = "###", Field 2 = "Phase", Field 3 = number (possibly with colon)
      phase_field = $3
      gsub(/:/, "", phase_field)  # Remove colon if present
      phase_match = (phase_field == phase)
      if (phase_match) {
        in_phase = 1
        print
        next
      } else if (in_phase) {
        exit
      }
    }

    # Only end on major sections outside code blocks
    /^## / && in_phase && !in_code_block {
      exit
    }

    in_phase { print }
  ' "$plan_file"
}

# Extract stage name from stage heading
# Usage: extract_stage_name <phase_file> <stage_num>
extract_stage_name() {
  local phase_file="$1"
  local stage_num="$2"

  # Extract stage heading like "#### Stage 1: Backend Setup"
  local heading=$(grep "^#### Stage ${stage_num}:" "$phase_file" | head -1)
  if [[ -z "$heading" ]]; then
    error "Stage $stage_num not found in phase"
  fi

  # Extract name after colon, convert to lowercase, replace spaces with underscores
  # Also remove special characters that are invalid in filenames
  local name=$(echo "$heading" | sed "s/^#### Stage ${stage_num}: //" | sed 's/ \[.*\]$//' | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -d '/:*?"<>|')
  echo "$name"
}

# Extract full stage content from phase file
# Usage: extract_stage_content <phase_file> <stage_num>
extract_stage_content() {
  local phase_file="$1"
  local stage_num="$2"

  # Extract everything from the stage heading to the next stage heading or end of section
  # IMPORTANT: Skip code blocks when detecting stage boundaries
  awk -v stage="$stage_num" '
    # Track code block state (fenced with ```)
    /^```/ {
      in_code_block = !in_code_block
      if (in_stage) print
      next
    }

    # Only detect stage boundaries outside code blocks
    /^#### Stage / && !in_code_block {
      stage_match = ($3 ~ "^" stage ":")
      if (stage_match) {
        in_stage = 1
        print
        next
      } else if (in_stage) {
        exit
      }
    }

    # Only end on section boundaries outside code blocks
    /^### / && in_stage && !in_code_block {
      # New phase section, end extraction
      exit
    }
    /^## / && in_stage && !in_code_block {
      # New major section, end extraction
      exit
    }

    in_stage { print }
  ' "$phase_file"
}

# ============================================================================
# SECTION 2: METADATA UTILITIES (from plan-metadata-utils.sh - 607 lines)
# ============================================================================

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

# ============================================================================
# SECTION 3: STRUCTURE UTILITIES (from plan-structure-utils.sh - 396 lines)
# ============================================================================

# Detect structure level for progressive plans (0=single file, 1=phase files, 2=stage files)
# Usage: detect_structure_level <plan_path>
detect_structure_level() {
  local plan_path="$1"

  # If plan is a single file (not in directory) -> Level 0
  if [[ "$plan_path" == *.md ]] && [[ -f "$plan_path" ]]; then
    local plan_dir=$(dirname "$plan_path")
    local plan_base=$(basename "$plan_path" .md)

    # Check if directory exists for this plan
    if [[ -d "$plan_dir/$plan_base" ]]; then
      # Plan has been expanded to directory
      plan_path="$plan_dir/$plan_base"
    else
      # Pure single file - Level 0
      echo "0"
      return 0
    fi
  fi

  # If path is a directory, check for phase/stage expansions
  if [[ -d "$plan_path" ]]; then
    local plan_name=$(basename "$plan_path")

    # Check for phase directories (indicates Level 2)
    if find "$plan_path" -maxdepth 1 -type d -name "phase_*" | grep -q .; then
      echo "2"
      return 0
    fi

    # Check for phase files (indicates Level 1)
    if find "$plan_path" -maxdepth 1 -type f -name "phase_*.md" | grep -q .; then
      echo "1"
      return 0
    fi

    # Directory exists but no expansions found - check metadata
    local overview="$plan_path/$plan_name.md"
    if [[ -f "$overview" ]]; then
      if grep -q "^- \*\*Structure Level\*\*: 2" "$overview" 2>/dev/null; then
        echo "2"
        return 0
      elif grep -q "^- \*\*Structure Level\*\*: 1" "$overview" 2>/dev/null; then
        echo "1"
        return 0
      elif grep -q "^- \*\*Structure Level\*\*: 0" "$overview" 2>/dev/null; then
        echo "0"
        return 0
      fi
    fi

    # Fallback: directory exists but unclear - assume Level 0
    echo "0"
    return 0
  fi

  error "Invalid plan path: $plan_path"
}

# Check if plan has been expanded (has directory)
# Usage: is_plan_expanded <plan_path>
# Returns: "true" or "false"
is_plan_expanded() {
  local plan_path="$1"

  # If plan is a file
  if [[ "$plan_path" == *.md ]] && [[ -f "$plan_path" ]]; then
    local plan_dir=$(dirname "$plan_path")
    local plan_base=$(basename "$plan_path" .md)

    # Check if directory exists
    if [[ -d "$plan_dir/$plan_base" ]]; then
      echo "true"
      return 0
    else
      echo "false"
      return 0
    fi
  fi

  # If plan is already a directory path
  if [[ -d "$plan_path" ]]; then
    echo "true"
    return 0
  fi

  echo "false"
  return 0
}

# Get plan directory if expanded, empty string if not
# Usage: get_plan_directory <plan_path>
get_plan_directory() {
  local plan_path="$1"

  # If plan is a file
  if [[ "$plan_path" == *.md ]] && [[ -f "$plan_path" ]]; then
    local plan_dir=$(dirname "$plan_path")
    local plan_base=$(basename "$plan_path" .md)

    # Check if directory exists
    if [[ -d "$plan_dir/$plan_base" ]]; then
      echo "$plan_dir/$plan_base"
      return 0
    else
      echo ""
      return 1
    fi
  fi

  # If plan is already a directory
  if [[ -d "$plan_path" ]]; then
    echo "$plan_path"
    return 0
  fi

  echo ""
  return 1
}

# Check if specific phase is expanded (has file or directory)
# Usage: is_phase_expanded <plan_path> <phase_num>
# Returns: "true" or "false"
is_phase_expanded() {
  local plan_path="$1"
  local phase_num="$2"

  local plan_dir=$(get_plan_directory "$plan_path")
  if [[ -z "$plan_dir" ]]; then
    # Plan not expanded, so phases can't be expanded
    echo "false"
    return 0
  fi

  # Check for phase file
  if find "$plan_dir" -maxdepth 1 -type f -name "phase_${phase_num}_*.md" | grep -q .; then
    echo "true"
    return 0
  fi

  # Check for phase directory
  if find "$plan_dir" -maxdepth 1 -type d -name "phase_${phase_num}_*" | grep -q .; then
    echo "true"
    return 0
  fi

  echo "false"
  return 0
}

# Get phase file path if expanded, empty string if not
# Usage: get_phase_file <plan_path> <phase_num>
get_phase_file() {
  local plan_path="$1"
  local phase_num="$2"

  local plan_dir=$(get_plan_directory "$plan_path")
  if [[ -z "$plan_dir" ]]; then
    echo ""
    return 1
  fi

  # Check for phase directory first (takes precedence)
  local phase_dir=$(find "$plan_dir" -maxdepth 1 -type d -name "phase_${phase_num}_*" 2>/dev/null | head -1)
  if [[ -n "$phase_dir" ]]; then
    # Phase is in directory - return phase file inside directory
    local phase_file=$(find "$phase_dir" -maxdepth 1 -type f -name "phase_${phase_num}_*.md" 2>/dev/null | head -1)
    if [[ -n "$phase_file" ]]; then
      echo "$phase_file"
      return 0
    fi
  fi

  # Check for phase file in plan directory
  local phase_file=$(find "$plan_dir" -maxdepth 1 -type f -name "phase_${phase_num}_*.md" 2>/dev/null | head -1)
  if [[ -n "$phase_file" ]]; then
    echo "$phase_file"
    return 0
  fi

  echo ""
  return 1
}

# Check if specific stage is expanded (has file)
# Usage: is_stage_expanded <plan_path> <phase_num> <stage_num>
# Returns: "true" or "false"
is_stage_expanded() {
  local plan_path="$1"
  local phase_num="$2"
  local stage_num="$3"

  local plan_dir=$(get_plan_directory "$plan_path")
  if [[ -z "$plan_dir" ]]; then
    echo "false"
    return 0
  fi

  # Get phase directory
  local phase_dir=$(find "$plan_dir" -maxdepth 1 -type d -name "phase_${phase_num}_*" 2>/dev/null | head -1)
  if [[ -z "$phase_dir" ]]; then
    # Phase not in directory, so stages can't be expanded
    echo "false"
    return 0
  fi

  # Check for stage file in phase directory
  if find "$phase_dir" -maxdepth 1 -type f -name "stage_${stage_num}_*.md" | grep -q .; then
    echo "true"
    return 0
  fi

  echo "false"
  return 0
}

# List expanded phase numbers
# Usage: list_expanded_phases <plan_path>
# Returns: space-separated list of phase numbers
list_expanded_phases() {
  local plan_path="$1"

  local plan_dir=$(get_plan_directory "$plan_path")
  if [[ -z "$plan_dir" ]]; then
    # Plan not expanded
    echo ""
    return 0
  fi

  # Find all phase files and directories
  local phases=""

  # Phase files
  for file in "$plan_dir"/phase_*_*.md; do
    if [[ -f "$file" ]]; then
      local filename=$(basename "$file" .md)
      local phase_num=$(echo "$filename" | sed 's/^phase_\([0-9]*\)_.*/\1/')
      phases="$phases $phase_num"
    fi
  done

  # Phase directories
  for dir in "$plan_dir"/phase_*; do
    if [[ -d "$dir" ]]; then
      local dirname=$(basename "$dir")
      local phase_num=$(echo "$dirname" | sed 's/^phase_\([0-9]*\)_.*/\1/')
      # Avoid duplicates
      if [[ ! "$phases" =~ (^| )$phase_num( |$) ]]; then
        phases="$phases $phase_num"
      fi
    fi
  done

  # Sort and output
  echo "$phases" | tr ' ' '\n' | grep -v '^$' | sort -n | tr '\n' ' ' | sed 's/ $//'
}

# List expanded stage numbers for a phase
# Usage: list_expanded_stages <plan_path> <phase_num>
# Returns: space-separated list of stage numbers
list_expanded_stages() {
  local plan_path="$1"
  local phase_num="$2"

  local plan_dir=$(get_plan_directory "$plan_path")
  if [[ -z "$plan_dir" ]]; then
    echo ""
    return 0
  fi

  # Get phase directory
  local phase_dir=$(find "$plan_dir" -maxdepth 1 -type d -name "phase_${phase_num}_*" 2>/dev/null | head -1)
  if [[ -z "$phase_dir" ]]; then
    # Phase not in directory
    echo ""
    return 0
  fi

  # Find all stage files
  local stages=""
  for file in "$phase_dir"/stage_*_*.md; do
    if [[ -f "$file" ]]; then
      local filename=$(basename "$file" .md)
      local stage_num=$(echo "$filename" | sed 's/^stage_\([0-9]*\)_.*/\1/')
      stages="$stages $stage_num"
    fi
  done

  # Sort and output
  echo "$stages" | tr ' ' '\n' | grep -v '^$' | sort -n | tr '\n' ' ' | sed 's/ $//'
}

# Check if directory has any remaining phase files/directories
# Usage: has_remaining_phases <plan_dir>
# Returns: "true" or "false"
has_remaining_phases() {
  local plan_dir="$1"

  # Check for phase files (not the main plan)
  local plan_name=$(basename "$plan_dir")
  if find "$plan_dir" -maxdepth 1 -type f -name "phase_*.md" | grep -q .; then
    echo "true"
    return 0
  fi

  # Check for phase directories
  if find "$plan_dir" -maxdepth 1 -type d -name "phase_*" | grep -q .; then
    echo "true"
    return 0
  fi

  echo "false"
  return 0
}

# Check if phase directory has any remaining stage files
# Usage: has_remaining_stages <phase_dir>
# Returns: "true" or "false"
has_remaining_stages() {
  local phase_dir="$1"

  if find "$phase_dir" -maxdepth 1 -type f -name "stage_*.md" | grep -q .; then
    echo "true"
    return 0
  fi

  echo "false"
  return 0
}

# Move plan file back to parent and delete directory (Level 1 → 0)
# Usage: cleanup_plan_directory <plan_dir>
cleanup_plan_directory() {
  local plan_dir="$1"
  local plan_name=$(basename "$plan_dir")
  local plan_file="$plan_dir/$plan_name.md"
  local parent_dir=$(dirname "$plan_dir")
  local target_file="$parent_dir/$plan_name.md"

  # Move plan file to parent
  mv "$plan_file" "$target_file"

  # Delete empty directory
  rmdir "$plan_dir"

  echo "$target_file"
}

# Move phase file back to parent and delete directory (Level 2 → 1)
# Usage: cleanup_phase_directory <phase_dir>
cleanup_phase_directory() {
  local phase_dir="$1"
  local phase_name=$(basename "$phase_dir")
  local phase_file="$phase_dir/$phase_name.md"
  local parent_dir=$(dirname "$phase_dir")
  local target_file="$parent_dir/$phase_name.md"

  # Move phase file to parent
  mv "$phase_file" "$target_file"

  # Delete empty directory
  rmdir "$phase_dir"

  echo "$target_file"
}

# Export all functions for sourcing
export -f extract_phase_name
export -f extract_phase_content
export -f extract_stage_name
export -f extract_stage_content
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
export -f detect_structure_level
export -f is_plan_expanded
export -f get_plan_directory
export -f is_phase_expanded
export -f get_phase_file
export -f is_stage_expanded
export -f list_expanded_phases
export -f list_expanded_stages
export -f has_remaining_phases
export -f has_remaining_stages
export -f cleanup_plan_directory
export -f cleanup_phase_directory
