#!/usr/bin/env bash
# Core Plan Parsing Functions
# Provides essential content extraction and parsing functions for implementation plans
# Usage: Source this file to use parsing functions

set -e

# Error handling
error() {
  echo "Error: $*" >&2
  exit 1
}

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

# Export functions for sourcing
export -f error
export -f extract_phase_name
export -f extract_phase_content
export -f extract_stage_name
export -f extract_stage_content
