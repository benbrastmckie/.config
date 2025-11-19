#!/usr/bin/env bash
# debug-utils.sh - Utilities for debug command operations
#
# PURPOSE:
#   Provides functions for issue analysis, complexity calculation, and root cause
#   determination used by the /debug command.
#
# Source guard: Prevent multiple sourcing
if [ -n "${DEBUG_UTILS_SOURCED:-}" ]; then
  return 0
fi
export DEBUG_UTILS_SOURCED=1

# ==============================================================================
# Issue Analysis Functions
# ==============================================================================

# analyze_issue: Analyze issue description and identify potential causes
#
# PARAMETERS:
#   $1 - issue_description: Description of the issue to analyze
#
# RETURNS:
#   List of potential causes (newline-separated) on stdout
#
# EXAMPLE:
#   CAUSES=$(analyze_issue "Tests failing after refactor")
#   # Output:
#   # 1. Breaking changes in refactored code
#   # 2. Missing test updates for new interfaces
#   # 3. Dependency version mismatch
analyze_issue() {
  local issue_description="${1:-}"

  if [ -z "$issue_description" ]; then
    echo "No issue description provided"
    return 1
  fi

  local causes=""

  # Pattern matching for common issue types
  if echo "$issue_description" | grep -qi "test.*fail\|failing test\|test error"; then
    causes="${causes}1. Test assertions may not match updated implementation\n"
    causes="${causes}2. Missing test fixtures or mock data\n"
    causes="${causes}3. Race conditions in async tests\n"
    causes="${causes}4. Test environment configuration issues\n"
  fi

  if echo "$issue_description" | grep -qi "refactor\|change\|update"; then
    causes="${causes}1. Breaking changes in refactored code\n"
    causes="${causes}2. Missing updates to dependent modules\n"
    causes="${causes}3. Interface changes not propagated\n"
  fi

  if echo "$issue_description" | grep -qi "error\|exception\|crash"; then
    causes="${causes}1. Unhandled edge cases\n"
    causes="${causes}2. Null/nil reference errors\n"
    causes="${causes}3. Resource exhaustion\n"
    causes="${causes}4. Incorrect error handling\n"
  fi

  if echo "$issue_description" | grep -qi "import\|require\|module"; then
    causes="${causes}1. Missing dependencies\n"
    causes="${causes}2. Circular import issues\n"
    causes="${causes}3. Incorrect module paths\n"
    causes="${causes}4. Version incompatibilities\n"
  fi

  if echo "$issue_description" | grep -qi "performance\|slow\|timeout"; then
    causes="${causes}1. Inefficient algorithms or loops\n"
    causes="${causes}2. Missing database indexes\n"
    causes="${causes}3. Unnecessary I/O operations\n"
    causes="${causes}4. Memory leaks\n"
  fi

  if echo "$issue_description" | grep -qi "config\|setting\|environment"; then
    causes="${causes}1. Missing or incorrect configuration values\n"
    causes="${causes}2. Environment variable issues\n"
    causes="${causes}3. Configuration file not loaded\n"
  fi

  # Default causes if no patterns matched
  if [ -z "$causes" ]; then
    causes="1. Code logic errors\n"
    causes="${causes}2. Missing validation\n"
    causes="${causes}3. State management issues\n"
    causes="${causes}4. External dependency problems\n"
  fi

  echo -e "$causes"
  return 0
}

# calculate_issue_complexity: Calculate complexity score for an issue
#
# PARAMETERS:
#   $1 - issue_description: Description of the issue
#   $2 - potential_causes: Newline-separated list of potential causes
#
# RETURNS:
#   Complexity score (1-10) on stdout
#
# COMPLEXITY FACTORS:
#   - Number of potential causes (+1 per cause, max 4)
#   - Keywords indicating complexity (async, distributed, race condition)
#   - Multiple components mentioned (+2)
#   - Integration keywords (+2)
#
# EXAMPLE:
#   SCORE=$(calculate_issue_complexity "Race condition in async handler" "$CAUSES")
#   # Output: 7
calculate_issue_complexity() {
  local issue_description="${1:-}"
  local potential_causes="${2:-}"

  local score=1  # Base score

  # Factor 1: Number of potential causes (max +4)
  local cause_count
  cause_count=$(echo -e "$potential_causes" | grep -c "^[0-9]" 2>/dev/null || echo "0")
  if [ "$cause_count" -gt 4 ]; then
    cause_count=4
  fi
  score=$((score + cause_count))

  # Factor 2: Complexity keywords (+2 each, max +4)
  local keyword_score=0
  if echo "$issue_description" | grep -qi "async\|concurrent\|parallel"; then
    keyword_score=$((keyword_score + 2))
  fi
  if echo "$issue_description" | grep -qi "race condition\|deadlock\|race"; then
    keyword_score=$((keyword_score + 2))
  fi
  if echo "$issue_description" | grep -qi "distributed\|network\|api"; then
    keyword_score=$((keyword_score + 1))
  fi
  if [ "$keyword_score" -gt 4 ]; then
    keyword_score=4
  fi
  score=$((score + keyword_score))

  # Factor 3: Multiple components (+1)
  local component_count
  component_count=$(echo "$issue_description" | grep -o -i '\b\w*module\|\bcomponent\|\bservice\|\bsystem\b' | wc -l)
  if [ "$component_count" -gt 1 ]; then
    score=$((score + 1))
  fi

  # Cap at 10
  if [ "$score" -gt 10 ]; then
    score=10
  fi

  echo "$score"
  return 0
}

# determine_root_cause: Determine most likely root cause from evidence
#
# PARAMETERS:
#   $1 - potential_causes: Newline-separated list of potential causes
#   $2 - evidence: Collected evidence (code analysis, git history, logs)
#
# RETURNS:
#   Most likely root cause on stdout
#
# EXAMPLE:
#   ROOT_CAUSE=$(determine_root_cause "$CAUSES" "$EVIDENCE")
#   # Output: "Missing test updates for new interfaces"
determine_root_cause() {
  local potential_causes="${1:-}"
  local evidence="${2:-}"

  # Simple scoring: count evidence matches for each cause keyword
  local best_cause=""
  local best_score=0

  # Extract first cause as default
  best_cause=$(echo -e "$potential_causes" | head -1 | sed 's/^[0-9]*\. //')

  # Check evidence for keywords from each cause
  while IFS= read -r cause; do
    # Strip number prefix
    local cause_text
    cause_text=$(echo "$cause" | sed 's/^[0-9]*\. //')

    if [ -z "$cause_text" ]; then
      continue
    fi

    # Count keyword matches in evidence
    local match_score=0

    # Extract keywords (words > 4 chars)
    for keyword in $(echo "$cause_text" | tr ' ' '\n' | grep -E '^.{4,}$'); do
      if echo "$evidence" | grep -qi "$keyword"; then
        match_score=$((match_score + 1))
      fi
    done

    if [ "$match_score" -gt "$best_score" ]; then
      best_score=$match_score
      best_cause=$cause_text
    fi
  done <<< "$(echo -e "$potential_causes")"

  echo "$best_cause"
  return 0
}

# verify_root_cause: Verify root cause with additional checks
#
# PARAMETERS:
#   $1 - root_cause: The proposed root cause
#
# RETURNS:
#   Verification status and confidence on stdout
#
# EXAMPLE:
#   VERIFICATION=$(verify_root_cause "Missing test updates")
#   # Output: "Verification: LIKELY (confidence: HIGH)"
verify_root_cause() {
  local root_cause="${1:-}"

  if [ -z "$root_cause" ]; then
    echo "Verification: UNABLE (no root cause provided)"
    return 1
  fi

  local confidence="MEDIUM"
  local status="LIKELY"

  # Check for specific verifiable patterns
  if echo "$root_cause" | grep -qi "missing\|not found\|undefined"; then
    confidence="HIGH"
    status="CONFIRMED"
  elif echo "$root_cause" | grep -qi "race\|timing\|async"; then
    confidence="LOW"
    status="SUSPECTED"
  elif echo "$root_cause" | grep -qi "configuration\|setting\|environment"; then
    confidence="HIGH"
    status="LIKELY"
  fi

  echo "Verification: $status (confidence: $confidence)"
  return 0
}

# ==============================================================================
# Evidence Collection Utilities
# ==============================================================================

# collect_file_evidence: Collect evidence from files matching pattern
#
# PARAMETERS:
#   $1 - pattern: Error pattern to search for
#   $2 - file_types: Comma-separated file extensions (default: lua,sh,md)
#
# RETURNS:
#   File paths with matches on stdout
#
# EXAMPLE:
#   FILES=$(collect_file_evidence "undefined function" "lua,sh")
collect_file_evidence() {
  local pattern="${1:-}"
  local file_types="${2:-lua,sh,md}"

  if [ -z "$pattern" ]; then
    return 1
  fi

  local include_args=""
  IFS=',' read -ra TYPES <<< "$file_types"
  for type in "${TYPES[@]}"; do
    include_args="$include_args --include=*.$type"
  done

  # shellcheck disable=SC2086
  grep -r -l "$pattern" . $include_args 2>/dev/null | head -20
  return 0
}

# collect_git_evidence: Collect recent git changes for files
#
# PARAMETERS:
#   $1 - file_paths: Space-separated list of file paths
#   $2 - days: Number of days to look back (default: 7)
#
# RETURNS:
#   Git log entries on stdout
#
# EXAMPLE:
#   CHANGES=$(collect_git_evidence "file1.lua file2.lua" 7)
collect_git_evidence() {
  local file_paths="${1:-}"
  local days="${2:-7}"

  if [ -z "$file_paths" ]; then
    return 1
  fi

  # shellcheck disable=SC2086
  git log --oneline --since="${days} days ago" -- $file_paths 2>/dev/null | head -20
  return 0
}

# Export functions for use in subshells
export -f analyze_issue
export -f calculate_issue_complexity
export -f determine_root_cause
export -f verify_root_cause
export -f collect_file_evidence
export -f collect_git_evidence
