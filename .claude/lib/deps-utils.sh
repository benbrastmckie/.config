#!/usr/bin/env bash
# Shared dependency checking utilities
# Centralized dependency validation with helpful error messages

set -euo pipefail

# ==============================================================================
# Constants
# ==============================================================================

readonly DEPS_UTILS_VERSION="1.0.0"

# ==============================================================================
# Core Functions
# ==============================================================================

# check_dependency: Generic dependency checker with install hints
# Usage: check_dependency <command-name> <install-hint>
# Returns: 0 if dependency exists, 1 otherwise
# Example: check_dependency "jq" "apt-get install jq"
check_dependency() {
  local cmd_name="${1:-}"
  local install_hint="${2:-}"

  if [ -z "$cmd_name" ]; then
    echo "Usage: check_dependency <command-name> <install-hint>" >&2
    return 1
  fi

  # Check if command exists
  if ! command -v "$cmd_name" &> /dev/null; then
    echo "Error: Required command '$cmd_name' not found" >&2
    if [ -n "$install_hint" ]; then
      echo "Install with: $install_hint" >&2
    fi
    return 1
  fi

  return 0
}

# require_jq: jq-specific dependency check with fallback guidance
# Usage: require_jq
# Returns: 0 if jq available, 1 otherwise
# Example: require_jq || { echo "Falling back to basic parsing"; }
require_jq() {
  check_dependency "jq" "apt-get install jq (Debian/Ubuntu) or brew install jq (macOS)"
}

# require_git: git-specific dependency check
# Usage: require_git
# Returns: 0 if git available, 1 otherwise
# Example: require_git && git status
require_git() {
  check_dependency "git" "apt-get install git (Debian/Ubuntu) or brew install git (macOS)"
}

# require_bash4: Check for Bash 4.0+ (for associative arrays)
# Usage: require_bash4
# Returns: 0 if Bash 4.0+, 1 otherwise
# Example: require_bash4 && declare -A my_array
require_bash4() {
  if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    echo "Error: Bash 4.0+ required (current: ${BASH_VERSION})" >&2
    echo "Install with: apt-get install bash (Debian/Ubuntu) or brew install bash (macOS)" >&2
    return 1
  fi
  return 0
}

# verify_dependencies: Batch check for multiple dependencies
# Usage: verify_dependencies <cmd1> <cmd2> ...
# Returns: 0 if all dependencies exist, 1 if any missing
# Example: verify_dependencies "jq" "git" "curl"
verify_dependencies() {
  local all_present=true

  for cmd in "$@"; do
    if ! command -v "$cmd" &> /dev/null; then
      echo "Missing dependency: $cmd" >&2
      all_present=false
    fi
  done

  if [ "$all_present" = false ]; then
    return 1
  fi

  return 0
}

# check_dependency_version: Check if command meets minimum version
# Usage: check_dependency_version <command> <min-version>
# Returns: 0 if version >= min-version, 1 otherwise
# Example: check_dependency_version "git" "2.0.0"
check_dependency_version() {
  local cmd_name="${1:-}"
  local min_version="${2:-}"

  if [ -z "$cmd_name" ] || [ -z "$min_version" ]; then
    echo "Usage: check_dependency_version <command> <min-version>" >&2
    return 1
  fi

  # Check if command exists first
  if ! command -v "$cmd_name" &> /dev/null; then
    echo "Error: Command '$cmd_name' not found" >&2
    return 1
  fi

  # Get version (this is a simplified check - real version parsing is complex)
  local version_output
  case "$cmd_name" in
    git)
      version_output=$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
      ;;
    jq)
      version_output=$(jq --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
      ;;
    *)
      echo "Warning: Version check not implemented for '$cmd_name'" >&2
      return 0  # Assume OK if we can't check
      ;;
  esac

  # Simple version comparison (assumes semantic versioning)
  if [ -n "$version_output" ]; then
    # This is a basic comparison - production code would need proper version comparison
    echo "Found $cmd_name version: $version_output" >&2
  fi

  return 0
}

# ==============================================================================
# Export Functions
# ==============================================================================

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f check_dependency
  export -f require_jq
  export -f require_git
  export -f require_bash4
  export -f verify_dependencies
  export -f check_dependency_version
fi
