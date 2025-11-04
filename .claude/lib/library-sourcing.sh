#!/usr/bin/env bash
# library-sourcing.sh - Consolidated library sourcing for orchestration commands
# Version: 1.0.0
# Purpose: Provide unified library sourcing with consistent error handling
#
# Usage:
#   source .claude/lib/library-sourcing.sh
#   source_required_libraries || exit 1

# source_required_libraries() - Sources all required libraries for orchestration commands
#
# Parameters:
#   $@ - Optional additional libraries to source (beyond the core 7)
#
# Returns:
#   0 - All libraries sourced successfully
#   1 - One or more libraries failed to source
#
# Core Libraries sourced (in order):
#   1. workflow-detection.sh - Workflow scope detection functions
#   2. error-handling.sh - Error handling utilities
#   3. checkpoint-utils.sh - Checkpoint save/restore operations
#   4. unified-logger.sh - Progress logging utilities
#   5. unified-location-detection.sh - Project structure detection
#   6. metadata-extraction.sh - Report/plan metadata extraction
#   7. context-pruning.sh - Context management utilities
#
# Optional Libraries:
#   - dependency-analyzer.sh - Wave-based execution analysis (for /coordinate)
#
# Deduplication:
#   - Automatically removes duplicate library names before sourcing
#   - Preserves first occurrence order for unique libraries
#   - Debug output shows count of removed duplicates (if any)
#   - Trade-off: Not idempotent across multiple function calls (acceptable
#     because commands run in isolated processes)
#
# Error Handling:
#   - Fail-fast on any missing library
#   - Detailed error message includes library name and expected path
#   - Returns 1 on any failure (caller should exit)
source_required_libraries() {
  local start_time=$(date +%s%N)

  local claude_root
  claude_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

  local libraries=(
    "workflow-detection.sh"
    "error-handling.sh"
    "checkpoint-utils.sh"
    "unified-logger.sh"
    "unified-location-detection.sh"
    "metadata-extraction.sh"
    "context-pruning.sh"
  )

  # Add optional libraries from arguments
  if [[ $# -gt 0 ]]; then
    libraries+=("$@")
  fi

  # Deduplicate library list to prevent re-sourcing
  # Algorithm: O(n²) string matching (acceptable for n≈10 libraries)
  # Trade-off: Not idempotent across multiple calls (acceptable since commands
  # run in isolated processes and don't call source_required_libraries repeatedly)
  local unique_libs=()
  local seen=" "
  for lib in "${libraries[@]}"; do
    if [[ ! "$seen" =~ " $lib " ]]; then
      unique_libs+=("$lib")
      seen+="$lib "
    fi
  done

  # Debug logging: show deduplication results (only when DEBUG=1)
  if [[ ${#libraries[@]} -ne ${#unique_libs[@]} ]] && [[ "${DEBUG:-0}" == "1" ]]; then
    local removed_count=$((${#libraries[@]} - ${#unique_libs[@]}))
    echo "DEBUG: Library deduplication: ${#libraries[@]} input libraries -> ${#unique_libs[@]} unique libraries ($removed_count duplicates removed)" >&2
  fi

  # Use deduplicated list for sourcing
  libraries=("${unique_libs[@]}")

  local failed_libraries=()

  for lib in "${libraries[@]}"; do
    local lib_path="${claude_root}/lib/${lib}"

    if [[ ! -f "$lib_path" ]]; then
      failed_libraries+=("$lib (expected at: $lib_path)")
      continue
    fi

    # shellcheck disable=SC1090
    if ! source "$lib_path" 2>/dev/null; then
      failed_libraries+=("$lib (source failed)")
    fi
  done

  if [[ ${#failed_libraries[@]} -gt 0 ]]; then
    echo "ERROR: Failed to source required libraries:" >&2
    for failed_lib in "${failed_libraries[@]}"; do
      echo "  - $failed_lib" >&2
    done
    echo "" >&2
    echo "Please ensure all required libraries exist in: ${claude_root}/lib/" >&2
    return 1
  fi

  # Performance timing (if enabled)
  if [[ "${DEBUG_PERFORMANCE:-0}" == "1" ]]; then
    local end_time=$(date +%s%N)
    local duration_ms=$(( (end_time - start_time) / 1000000 ))
    echo "PERF: Library sourcing completed in ${duration_ms}ms (${#libraries[@]} libraries)" >&2
  fi

  return 0
}
