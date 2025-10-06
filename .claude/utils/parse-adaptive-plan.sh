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
# Note: Legacy function for backward compatibility - use detect_structure_level for progressive plans
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

# === PROGRESSIVE STRUCTURE DETECTION FUNCTIONS ===

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

# Extract phase name from phase heading
# Usage: extract_phase_name <plan_file> <phase_num>
extract_phase_name() {
  local plan_file="$1"
  local phase_num="$2"

  # Extract phase heading like "### Phase 2: Implementation"
  local heading=$(grep "^### Phase ${phase_num}:" "$plan_file" | head -1)
  if [[ -z "$heading" ]]; then
    error "Phase $phase_num not found in plan"
  fi

  # Extract name after colon, convert to lowercase, replace spaces with underscores
  local name=$(echo "$heading" | sed "s/^### Phase ${phase_num}: //" | sed 's/ \[.*\]$//' | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
  echo "$name"
}

# Extract full phase content from plan file
# Usage: extract_phase_content <plan_file> <phase_num>
extract_phase_content() {
  local plan_file="$1"
  local phase_num="$2"

  # Extract everything from the phase heading to the next phase heading or end of phases section
  awk -v phase="$phase_num" '
    /^### Phase / {
      phase_match = ($3 ~ "^" phase ":")
      if (phase_match) {
        in_phase = 1
        print
        next
      } else if (in_phase) {
        exit
      }
    }
    /^## / && in_phase {
      # New major section, end extraction
      exit
    }
    in_phase { print }
  ' "$plan_file"
}

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
      phase_match = ($3 ~ "^" phase ":")
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
        next
      }
      { print }
    ' "$plan_file" > "$temp_file"
    mv "$temp_file" "$plan_file"
  fi
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
  local name=$(echo "$heading" | sed "s/^#### Stage ${stage_num}: //" | sed 's/ \[.*\]$//' | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
  echo "$name"
}

# Extract full stage content from phase file
# Usage: extract_stage_content <phase_file> <stage_num>
extract_stage_content() {
  local phase_file="$1"
  local stage_num="$2"

  # Extract everything from the stage heading to the next stage heading or end of section
  awk -v stage="$stage_num" '
    /^#### Stage / {
      stage_match = ($3 ~ "^" stage ":")
      if (stage_match) {
        in_stage = 1
        print
        next
      } else if (in_stage) {
        exit
      }
    }
    /^### / && in_stage {
      # New phase section, end extraction
      exit
    }
    /^## / && in_stage {
      # New major section, end extraction
      exit
    }
    in_stage { print }
  ' "$phase_file"
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

# === END PROGRESSIVE STRUCTURE DETECTION FUNCTIONS ===

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

Functions (Legacy Tier System):
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

Functions (Progressive Structure):
  detect_structure_level <plan_path>
    Returns: 0, 1, or 2

  is_plan_expanded <plan_path>
    Returns: true or false

  get_plan_directory <plan_path>
    Returns: Path to plan directory if expanded

  is_phase_expanded <plan_path> <phase_num>
    Returns: true or false

  get_phase_file <plan_path> <phase_num>
    Returns: Path to phase file if expanded

  is_stage_expanded <plan_path> <phase_num> <stage_num>
    Returns: true or false

  list_expanded_phases <plan_path>
    Returns: Space-separated list of expanded phase numbers

  list_expanded_stages <plan_path> <phase_num>
    Returns: Space-separated list of expanded stage numbers

Functions (Progressive Expansion Utilities):
  extract_phase_name <plan_file> <phase_num>
    Returns: Phase name for file naming (e.g., "implementation")

  extract_phase_content <plan_file> <phase_num>
    Returns: Full phase content from plan file

  revise_main_plan_for_phase <plan_file> <phase_num> <phase_filename>
    Replaces phase content with summary and link

  add_phase_metadata <phase_file> <phase_num> <parent_plan_name>
    Adds metadata section to phase file

  add_update_reminder <phase_file> <phase_description> <parent_plan_name>
    Adds update reminder to end of phase file

  update_structure_level <plan_file> <level>
    Updates Structure Level metadata

  update_expanded_phases <plan_file> <phase_num>
    Adds phase to Expanded Phases list

  extract_stage_name <phase_file> <stage_num>
    Returns: Stage name for file naming (e.g., "backend")

  extract_stage_content <phase_file> <stage_num>
    Returns: Full stage content from phase file

  revise_phase_file_for_stage <phase_file> <stage_num> <stage_filename>
    Replaces stage content with summary and link

  add_stage_metadata <stage_file> <stage_num> <parent_phase_name>
    Adds metadata section to stage file

  update_phase_expanded_stages <phase_file> <stage_num>
    Adds stage to Expanded Stages list in phase file

  update_plan_expanded_stages <plan_file> <phase_num> <stage_num>
    Updates Expanded Stages dict in main plan

Examples:
  $0 detect_tier specs/plans/024_feature/
  $0 detect_structure_level specs/plans/025_feature.md
  $0 is_plan_expanded specs/plans/025_feature.md
  $0 get_plan_directory specs/plans/025_feature.md
  $0 is_phase_expanded specs/plans/025_feature/ 2
  $0 list_expanded_phases specs/plans/025_feature/
  $0 extract_phase_name specs/plans/025_feature.md 2
  $0 extract_phase_content specs/plans/025_feature.md 2
EOF
    exit 1
  fi

  local function="$1"
  shift

  case "$function" in
    # Legacy tier system functions
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
    # Progressive structure functions
    detect_structure_level)
      detect_structure_level "$@"
      ;;
    is_plan_expanded)
      is_plan_expanded "$@"
      ;;
    get_plan_directory)
      get_plan_directory "$@"
      ;;
    is_phase_expanded)
      is_phase_expanded "$@"
      ;;
    get_phase_file)
      get_phase_file "$@"
      ;;
    is_stage_expanded)
      is_stage_expanded "$@"
      ;;
    list_expanded_phases)
      list_expanded_phases "$@"
      ;;
    list_expanded_stages)
      list_expanded_stages "$@"
      ;;
    # Progressive expansion utility functions
    extract_phase_name)
      extract_phase_name "$@"
      ;;
    extract_phase_content)
      extract_phase_content "$@"
      ;;
    revise_main_plan_for_phase)
      revise_main_plan_for_phase "$@"
      ;;
    add_phase_metadata)
      add_phase_metadata "$@"
      ;;
    add_update_reminder)
      add_update_reminder "$@"
      ;;
    update_structure_level)
      update_structure_level "$@"
      ;;
    update_expanded_phases)
      update_expanded_phases "$@"
      ;;
    extract_stage_name)
      extract_stage_name "$@"
      ;;
    extract_stage_content)
      extract_stage_content "$@"
      ;;
    revise_phase_file_for_stage)
      revise_phase_file_for_stage "$@"
      ;;
    add_stage_metadata)
      add_stage_metadata "$@"
      ;;
    update_phase_expanded_stages)
      update_phase_expanded_stages "$@"
      ;;
    update_plan_expanded_stages)
      update_plan_expanded_stages "$@"
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
