#!/usr/bin/env bash
# Progressive Planning Utilities
# Shared functions for progressive expansion/collapse operations
# Used by: /collapse-phase, /collapse-stage commands

set -e

# Source base utilities and parsing functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/base-utils.sh"

if [[ -f "$SCRIPT_DIR/../lib/plan-core-bundle.sh" ]]; then
  source "$SCRIPT_DIR/../lib/plan-core-bundle.sh"
fi

# === LAST-ITEM DETECTION ===

# Detect if collapsing the last expanded entity (phase or stage)
#
# Usage: detect_last_item <plan-or-phase-path> <entity-type> <entity-num>
#
# Arguments:
#   plan-or-phase-path: Path to plan directory or phase directory
#   entity-type: "phase" or "stage"
#   entity-num: Number of entity being collapsed
#
# Returns:
#   0 (true) if this is the last expanded item
#   1 (false) if other items are still expanded
#
# Examples:
#   detect_last_item "specs/plans/025_feature" "phase" "2"
#   detect_last_item "specs/plans/025_feature/phase_3_impl" "stage" "1"
#
detect_last_item() {
  local path="$1"
  local entity_type="$2"
  local entity_num="$3"

  [[ -z "$path" ]] && error "detect_last_item: path required"
  [[ -z "$entity_type" ]] && error "detect_last_item: entity_type required (phase|stage)"
  [[ -z "$entity_num" ]] && error "detect_last_item: entity_num required"

  if [[ "$entity_type" == "phase" ]]; then
    # Count remaining phase files after collapsing this one
    local phase_count=$(find "$path" -maxdepth 1 -type f -name "phase_*.md" | wc -l)

    # If only 1 phase file exists, this is the last one
    if [[ $phase_count -eq 1 ]]; then
      return 0  # true - last item
    else
      return 1  # false - other phases exist
    fi

  elif [[ "$entity_type" == "stage" ]]; then
    # Count remaining stage files after collapsing this one
    local stage_count=$(find "$path" -maxdepth 1 -type f -name "stage_*.md" | wc -l)

    # If only 1 stage file exists, this is the last one
    if [[ $stage_count -eq 1 ]]; then
      return 0  # true - last item
    else
      return 1  # false - other stages exist
    fi

  else
    error "detect_last_item: invalid entity_type '$entity_type' (must be phase|stage)"
  fi
}

# === CONTENT MERGING ===

# Merge markdown content from source file into target file at specific section
#
# Usage: merge_markdown_sections <source-file> <target-file> <section-marker>
#
# Arguments:
#   source-file: Path to file with content to merge (e.g., phase file)
#   target-file: Path to file to merge into (e.g., main plan)
#   section-marker: Regex pattern to identify section (e.g., "^### Phase 2:")
#
# Returns:
#   Merged content on stdout
#
# Algorithm:
#   1. Read target file until section marker
#   2. Insert full content from source file
#   3. Skip old section content in target (until next same-level heading or EOF)
#   4. Continue with rest of target file
#
# Example:
#   merge_markdown_sections "phase_2_impl.md" "025_feature.md" "^### Phase 2:"
#
merge_markdown_sections() {
  local source_file="$1"
  local target_file="$2"
  local section_marker="$3"

  [[ -z "$source_file" ]] && error "merge_markdown_sections: source_file required"
  [[ -z "$target_file" ]] && error "merge_markdown_sections: target_file required"
  [[ -z "$section_marker" ]] && error "merge_markdown_sections: section_marker required"

  [[ ! -f "$source_file" ]] && error "merge_markdown_sections: source file not found: $source_file"
  [[ ! -f "$target_file" ]] && error "merge_markdown_sections: target file not found: $target_file"

  # Read source content (skip metadata header if present)
  local source_content=""
  local in_metadata=false
  local metadata_done=false

  while IFS= read -r line; do
    # Skip YAML frontmatter in source
    if [[ "$line" == "---" ]] && [[ "$in_metadata" == false ]] && [[ "$metadata_done" == false ]]; then
      in_metadata=true
      continue
    elif [[ "$line" == "---" ]] && [[ "$in_metadata" == true ]]; then
      in_metadata=false
      metadata_done=true
      continue
    elif [[ "$in_metadata" == true ]]; then
      continue
    fi

    # Accumulate source content
    source_content+="$line"$'\n'
  done < "$source_file"

  # Merge into target file
  local in_section=false
  local section_level=""

  while IFS= read -r line; do
    # Check if we've reached the section to replace
    if [[ "$line" =~ $section_marker ]]; then
      in_section=true
      # Determine section level (count # symbols)
      section_level=$(echo "$line" | grep -o "^#*" | wc -c)
      section_level=$((section_level - 1))  # Adjust for newline

      # Output the source content instead of target section
      echo "$source_content"
      continue
    fi

    # If in section, skip lines until we hit next same-level or higher heading
    if [[ "$in_section" == true ]]; then
      # Check if this is a heading
      if [[ "$line" =~ ^#{1,6}[[:space:]] ]]; then
        local current_level=$(echo "$line" | grep -o "^#*" | wc -c)
        current_level=$((current_level - 1))

        # If same or higher level heading, section is done
        if [[ $current_level -le $section_level ]]; then
          in_section=false
          echo "$line"
        fi
        # Otherwise skip (lower level heading within section)
      fi
      # Skip all other lines while in section
      continue
    fi

    # Not in section - output line as-is
    echo "$line"
  done < "$target_file"
}

# === METADATA UPDATES ===

# Update expansion metadata in plan file
#
# Usage: update_expansion_metadata <plan-file> <operation> <entity-type> <entity-id>
#
# Arguments:
#   plan-file: Path to plan file (e.g., 025_feature.md)
#   operation: "expand" or "collapse"
#   entity-type: "phase" or "stage"
#   entity-id: Entity number (e.g., "2" for Phase 2)
#
# Operations:
#   expand + phase: Add phase to Expanded Phases list, set Structure Level 1
#   collapse + phase: Remove phase from Expanded Phases list, set Level 0 if last
#   expand + stage: Add stage to Expanded Stages dict, set Structure Level 2
#   collapse + stage: Remove stage from Expanded Stages dict, set Level 1 if last
#
# Returns:
#   Updated file content on stdout
#
# Example:
#   update_expansion_metadata "025_feature.md" "collapse" "phase" "2"
#
update_expansion_metadata() {
  local plan_file="$1"
  local operation="$2"
  local entity_type="$3"
  local entity_id="$4"

  [[ -z "$plan_file" ]] && error "update_expansion_metadata: plan_file required"
  [[ -z "$operation" ]] && error "update_expansion_metadata: operation required (expand|collapse)"
  [[ -z "$entity_type" ]] && error "update_expansion_metadata: entity_type required (phase|stage)"
  [[ -z "$entity_id" ]] && error "update_expansion_metadata: entity_id required"

  [[ ! -f "$plan_file" ]] && error "update_expansion_metadata: plan file not found: $plan_file"

  # Create temporary file for output
  local temp_file="${plan_file}.tmp"

  if [[ "$entity_type" == "phase" ]]; then
    # Update Phase-level metadata
    awk -v op="$operation" -v id="$entity_id" '
      BEGIN { in_metadata = 0; found_expanded = 0; found_level = 0 }

      # Detect metadata section
      /^## Metadata/ { in_metadata = 1 }
      /^## [^M]/ { if (in_metadata) in_metadata = 0 }

      # Update Expanded Phases line
      in_metadata && /^\- \*\*Expanded Phases\*\*:/ {
        found_expanded = 1
        # Extract current list
        match($0, /\[(.*)\]/, arr)
        current = arr[1]

        if (op == "collapse") {
          # Remove id from list
          gsub("(^|, )" id "($|, )", "", current)
          gsub(", ,", ",", current)
          gsub("^, ", "", current)
          gsub(", $", "", current)

          # Print updated line
          if (current == "") {
            print "- **Expanded Phases**: []"
          } else {
            print "- **Expanded Phases**: [" current "]"
          }
        } else {
          # Add id to list (for expand operation)
          if (current == "") {
            print "- **Expanded Phases**: [" id "]"
          } else if (!match(current, "(^|, )" id "($|, )")) {
            print "- **Expanded Phases**: [" current ", " id "]"
          } else {
            print $0  # Already in list
          }
        }
        next
      }

      # Update Structure Level line
      in_metadata && /^\- \*\*Structure Level\*\*:/ {
        found_level = 1
        # Determine new level based on operation and current expanded phases
        if (op == "collapse") {
          # Will be determined after we know if last item
          print "- **Structure Level**: 0"
        } else {
          print "- **Structure Level**: 1"
        }
        next
      }

      # Print all other lines
      { print }

      # Add metadata if missing
      END {
        if (in_metadata && !found_expanded) {
          print "- **Expanded Phases**: []"
        }
        if (in_metadata && !found_level) {
          if (op == "collapse") {
            print "- **Structure Level**: 0"
          } else {
            print "- **Structure Level**: 1"
          }
        }
      }
    ' "$plan_file" > "$temp_file"

  elif [[ "$entity_type" == "stage" ]]; then
    # Update Stage-level metadata (more complex - dictionary format)
    # For now, simplified version that updates Expanded Stages list
    awk -v op="$operation" -v id="$entity_id" '
      BEGIN { in_metadata = 0 }

      # Detect metadata section
      /^## Metadata/ { in_metadata = 1 }
      /^## [^M]/ { if (in_metadata) in_metadata = 0 }

      # Update Expanded Stages line (simplified list format)
      in_metadata && /^\- \*\*Expanded Stages\*\*:/ {
        match($0, /\[(.*)\]/, arr)
        current = arr[1]

        if (op == "collapse") {
          # Remove id from list
          gsub("(^|, )" id "($|, )", "", current)
          gsub(", ,", ",", current)
          gsub("^, ", "", current)
          gsub(", $", "", current)

          if (current == "") {
            print "- **Expanded Stages**: []"
          } else {
            print "- **Expanded Stages**: [" current "]"
          }
        } else {
          if (current == "") {
            print "- **Expanded Stages**: [" id "]"
          } else if (!match(current, "(^|, )" id "($|, )")) {
            print "- **Expanded Stages**: [" current ", " id "]"
          } else {
            print $0
          }
        }
        next
      }

      # Update Structure Level for stages
      in_metadata && /^\- \*\*Structure Level\*\*:/ {
        if (op == "collapse") {
          print "- **Structure Level**: 1"
        } else {
          print "- **Structure Level**: 2"
        }
        next
      }

      # Print all other lines
      { print }
    ' "$plan_file" > "$temp_file"

  else
    error "update_expansion_metadata: invalid entity_type '$entity_type' (must be phase|stage)"
  fi

  # Replace original with updated content
  cat "$temp_file"
  rm -f "$temp_file"
}

# === ATOMIC OPERATIONS ===

# Perform file operation with rollback capability
#
# Usage: atomic_operation <operation-function> <target-files...>
#
# Arguments:
#   operation-function: Name of function to execute (must be defined in calling scope)
#   target-files: One or more file paths that will be modified
#
# Returns:
#   0 on success (operation completed successfully)
#   1 on failure (operation failed, rollback performed)
#
# Algorithm:
#   1. Create backup copies of all target files
#   2. Execute operation function
#   3. If operation succeeds: Delete backups
#   4. If operation fails: Restore from backups
#
# Example:
#   my_operation() {
#     echo "new content" > "$1"
#   }
#   atomic_operation my_operation "file.txt"
#
atomic_operation() {
  local operation_func="$1"
  shift
  local target_files=("$@")

  [[ -z "$operation_func" ]] && error "atomic_operation: operation function required"
  [[ ${#target_files[@]} -eq 0 ]] && error "atomic_operation: at least one target file required"

  # Check if operation function exists
  if ! declare -f "$operation_func" > /dev/null; then
    error "atomic_operation: function '$operation_func' not found"
  fi

  # Create backups
  local backup_files=()
  for file in "${target_files[@]}"; do
    if [[ -f "$file" ]]; then
      local backup="${file}.backup.$$"
      cp "$file" "$backup" || {
        # Cleanup any backups created so far
        for bf in "${backup_files[@]}"; do
          rm -f "$bf"
        done
        error "atomic_operation: failed to create backup of $file"
      }
      backup_files+=("$backup")
    fi
  done

  # Execute operation
  if "$operation_func" "${target_files[@]}"; then
    # Success - remove backups
    for backup in "${backup_files[@]}"; do
      rm -f "$backup"
    done
    return 0
  else
    # Failure - rollback
    echo "atomic_operation: operation failed, rolling back..." >&2

    local i=0
    for file in "${target_files[@]}"; do
      if [[ -f "${backup_files[$i]}" ]]; then
        mv "${backup_files[$i]}" "$file"
      fi
      ((i++))
    done

    error "atomic_operation: operation failed and rolled back"
  fi
}

# === VALIDATION FUNCTIONS ===

# Validate that content was preserved during merge
#
# Usage: validate_content_preservation <original-file> <merged-file> <section-marker>
#
# Arguments:
#   original-file: File with original content
#   merged-file: File after merge
#   section-marker: Section that should contain the content
#
# Returns:
#   0 if content preserved
#   1 if content appears lost or corrupted
#
validate_content_preservation() {
  local original="$1"
  local merged="$2"
  local section="$3"

  [[ ! -f "$original" ]] && error "validate_content_preservation: original file not found"
  [[ ! -f "$merged" ]] && error "validate_content_preservation: merged file not found"

  # Extract section from merged file
  local merged_section=$(awk -v section="$section" '
    BEGIN { in_section = 0; level = 0 }

    $0 ~ section {
      in_section = 1
      match($0, /^#+/, m)
      level = length(m[0])
      print
      next
    }

    in_section && /^#+/ {
      match($0, /^#+/, m)
      if (length(m[0]) <= level) {
        exit
      }
      print
      next
    }

    in_section { print }
  ' "$merged")

  # Check if section has substantial content
  local line_count=$(echo "$merged_section" | wc -l)

  if [[ $line_count -lt 5 ]]; then
    echo "Warning: Merged section appears too short ($line_count lines)" >&2
    return 1
  fi

  return 0
}

# Export functions for use in other scripts
export -f detect_last_item
export -f merge_markdown_sections
export -f update_expansion_metadata
export -f atomic_operation
export -f validate_content_preservation
