#!/usr/bin/env bash
# Phase Classifier Library for /lean-implement command
# Version: 1.0.0
#
# Provides 2-tier phase type detection algorithm to classify plan phases
# as "lean" (theorem proving) or "software" (implementation).

set -euo pipefail

# Library version for compatibility checking
PHASE_CLASSIFIER_VERSION="1.0.0"

# === PHASE TYPE DETECTION ===
# 2-tier classification algorithm for plan phases
#
# Tier 1: Phase-specific metadata (strongest signal)
#   - lean_file: metadata present -> lean
#
# Tier 2: Keyword and extension analysis
#   - Lean indicators: .lean, theorem, lemma, sorry, tactic, mathlib
#   - Software indicators: .ts, .js, .py, .sh, implement, create, write tests
#
# Default: "software" (conservative approach for ambiguous phases)
#
# Arguments:
#   $1 - Phase content (multiline string)
#   $2 - Phase number (for logging)
#
# Returns:
#   Echoes "lean" or "software"
#   Exit code 0 on success
detect_phase_type() {
  local phase_content="$1"
  local phase_num="${2:-0}"

  # Tier 1: Check for lean_file metadata (strongest signal)
  if echo "$phase_content" | grep -qE "^lean_file:"; then
    echo "lean"
    return 0
  fi

  # Tier 2: Keyword and extension analysis

  # Lean indicators (case-insensitive for keywords)
  if echo "$phase_content" | grep -qiE '\.(lean)\b|theorem\b|lemma\b|sorry\b|tactic\b|mathlib\b|lean_(goal|build|leansearch)'; then
    echo "lean"
    return 0
  fi

  # Check for Lean-specific task patterns
  if echo "$phase_content" | grep -qiE 'prove\s+(theorem|lemma)|proof\s+of|mathlib\s+integration|induction\s+on'; then
    echo "lean"
    return 0
  fi

  # Software indicators (file extensions)
  if echo "$phase_content" | grep -qE '\.(ts|js|py|sh|md|json|yaml|toml|tsx|jsx|css|html)\b'; then
    echo "software"
    return 0
  fi

  # Software indicators (action verbs)
  if echo "$phase_content" | grep -qiE 'implement\b|create\b|write tests\b|setup\b|configure\b|deploy\b|build\b|refactor\b|migrate\b'; then
    echo "software"
    return 0
  fi

  # Default: software (conservative approach)
  echo "software"
}

# === BUILD ROUTING MAP ===
# Parses plan file and builds routing map for all phases
#
# Arguments:
#   $1 - Plan file path (absolute)
#   $2 - Execution mode (auto|lean-only|software-only)
#
# Returns:
#   Echoes routing map as newline-separated entries: phase_num:type:lean_file
#   Exit code 0 on success, 1 on failure
build_routing_map() {
  local plan_file="$1"
  local execution_mode="${2:-auto}"

  if [ ! -f "$plan_file" ]; then
    echo "ERROR: Plan file not found: $plan_file" >&2
    return 1
  fi

  local total_phases
  total_phases=$(grep -c "^### Phase [0-9]" "$plan_file" 2>/dev/null || echo "0")

  if [ "$total_phases" -eq 0 ]; then
    echo "ERROR: No phases found in plan file" >&2
    return 1
  fi

  local routing_map=""

  for phase_num in $(seq 1 "$total_phases"); do
    # Extract phase content (from phase heading to next phase or EOF)
    local phase_content
    phase_content=$(awk -v target="$phase_num" '
      BEGIN { in_phase=0; found=0 }
      /^### Phase / {
        if (found) exit
        if (index($0, "Phase " target ":") > 0) {
          in_phase=1
          found=1
          print
          next
        }
      }
      in_phase { print }
    ' "$plan_file")

    if [ -z "$phase_content" ]; then
      continue
    fi

    # Classify phase
    local phase_type
    phase_type=$(detect_phase_type "$phase_content" "$phase_num")

    # Extract lean_file if present
    local lean_file_path="none"
    if [ "$phase_type" = "lean" ]; then
      lean_file_path=$(echo "$phase_content" | grep -E "^lean_file:" | sed 's/^lean_file:[[:space:]]*//' | head -1)
      if [ -z "$lean_file_path" ]; then
        lean_file_path="none"
      fi
    fi

    # Apply mode filter
    case "$execution_mode" in
      lean-only)
        if [ "$phase_type" != "lean" ]; then
          continue
        fi
        ;;
      software-only)
        if [ "$phase_type" = "lean" ]; then
          continue
        fi
        ;;
    esac

    # Add to routing map
    if [ -n "$routing_map" ]; then
      routing_map="${routing_map}
"
    fi
    routing_map="${routing_map}${phase_num}:${phase_type}:${lean_file_path}"
  done

  echo "$routing_map"
}

# === GET PHASE INFO ===
# Extracts phase information from routing map entry
#
# Arguments:
#   $1 - Routing map entry (phase_num:type:lean_file)
#
# Returns:
#   Sets PHASE_NUM, PHASE_TYPE, LEAN_FILE_PATH variables
get_phase_info() {
  local entry="$1"

  PHASE_NUM=$(echo "$entry" | cut -d: -f1)
  PHASE_TYPE=$(echo "$entry" | cut -d: -f2)
  LEAN_FILE_PATH=$(echo "$entry" | cut -d: -f3-)

  if [ "$LEAN_FILE_PATH" = "none" ]; then
    LEAN_FILE_PATH=""
  fi

  export PHASE_NUM PHASE_TYPE LEAN_FILE_PATH
}

# === COUNT PHASES BY TYPE ===
# Counts phases of each type in routing map
#
# Arguments:
#   $1 - Routing map (newline-separated entries)
#
# Returns:
#   Sets LEAN_COUNT, SOFTWARE_COUNT variables
count_phases_by_type() {
  local routing_map="$1"

  LEAN_COUNT=0
  SOFTWARE_COUNT=0

  while IFS=: read -r phase_num phase_type lean_file; do
    if [ "$phase_type" = "lean" ]; then
      LEAN_COUNT=$((LEAN_COUNT + 1))
    else
      SOFTWARE_COUNT=$((SOFTWARE_COUNT + 1))
    fi
  done <<< "$routing_map"

  export LEAN_COUNT SOFTWARE_COUNT
}

# === VALIDATE ROUTING MAP ===
# Validates routing map has at least one executable phase
#
# Arguments:
#   $1 - Routing map (newline-separated entries)
#
# Returns:
#   Exit code 0 if valid, 1 if empty
validate_routing_map() {
  local routing_map="$1"

  if [ -z "$routing_map" ]; then
    echo "ERROR: Routing map is empty - no phases to execute" >&2
    return 1
  fi

  count_phases_by_type "$routing_map"

  if [ "$LEAN_COUNT" -eq 0 ] && [ "$SOFTWARE_COUNT" -eq 0 ]; then
    echo "ERROR: No phases to execute after mode filtering" >&2
    return 1
  fi

  return 0
}

# === CLASSIFICATION CONFIDENCE ===
# Returns confidence level for phase classification
# (For future enhancement - not currently used)
#
# Arguments:
#   $1 - Phase content
#   $2 - Detected phase type
#
# Returns:
#   Echoes "high", "medium", or "low"
get_classification_confidence() {
  local phase_content="$1"
  local phase_type="$2"

  # Tier 1 metadata = high confidence
  if echo "$phase_content" | grep -qE "^lean_file:"; then
    echo "high"
    return 0
  fi

  # Multiple strong indicators = high confidence
  local indicator_count=0

  if [ "$phase_type" = "lean" ]; then
    echo "$phase_content" | grep -qiE '\.lean\b' && indicator_count=$((indicator_count + 1))
    echo "$phase_content" | grep -qiE 'theorem\b' && indicator_count=$((indicator_count + 1))
    echo "$phase_content" | grep -qiE 'lemma\b' && indicator_count=$((indicator_count + 1))
    echo "$phase_content" | grep -qiE 'sorry\b' && indicator_count=$((indicator_count + 1))
    echo "$phase_content" | grep -qiE 'mathlib\b' && indicator_count=$((indicator_count + 1))
  else
    echo "$phase_content" | grep -qE '\.(ts|js|py)\b' && indicator_count=$((indicator_count + 1))
    echo "$phase_content" | grep -qiE 'implement\b' && indicator_count=$((indicator_count + 1))
    echo "$phase_content" | grep -qiE 'create\b' && indicator_count=$((indicator_count + 1))
    echo "$phase_content" | grep -qiE 'write tests\b' && indicator_count=$((indicator_count + 1))
  fi

  if [ "$indicator_count" -ge 3 ]; then
    echo "high"
  elif [ "$indicator_count" -ge 1 ]; then
    echo "medium"
  else
    echo "low"
  fi
}
