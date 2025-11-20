#!/usr/bin/env bash
# library-version-check.sh - Semantic version compatibility verification for .claude/ libraries
#
# Version: 1.0.0
# Last Modified: 2025-11-17
#
# This utility validates library version compatibility using semantic versioning (semver).
# Commands can specify required library versions in YAML frontmatter, and this utility
# ensures loaded libraries meet version requirements.
#
# Usage:
#   source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/library-version-check.sh"
#   check_library_version "workflow-state-machine.sh" ">=2.0.0"
#   check_library_version "state-persistence.sh" ">=1.5.0"
#
# Exit Codes:
#   0 - Version requirement met
#   1 - Version requirement not met
#   2 - Library not sourced or version variable not found
#   3 - Invalid version format

set -euo pipefail

# Source guard
if [ -n "${LIBRARY_VERSION_CHECK_SOURCED:-}" ]; then
  return 0
fi
export LIBRARY_VERSION_CHECK_SOURCED=1
export LIBRARY_VERSION_CHECK_VERSION="1.0.0"

# ==============================================================================
# Semantic Version Comparison Functions
# ==============================================================================

# Parse semantic version into major.minor.patch components
# Args: $1 = version string (e.g., "2.0.0")
# Output: Three space-separated integers (e.g., "2 0 0")
parse_semver() {
  local version="$1"

  # Validate format (major.minor.patch)
  if ! echo "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "ERROR: Invalid semantic version format: $version (expected: major.minor.patch)" >&2
    return 3
  fi

  # Extract components
  local major=$(echo "$version" | cut -d. -f1)
  local minor=$(echo "$version" | cut -d. -f2)
  local patch=$(echo "$version" | cut -d. -f3)

  echo "$major $minor $patch"
}

# Compare two semantic versions
# Args: $1 = version1, $2 = operator (=, <, >, <=, >=), $3 = version2
# Returns: 0 if comparison true, 1 if false
compare_versions() {
  local version1="$1"
  local operator="$2"
  local version2="$3"

  # Parse versions
  read -r major1 minor1 patch1 <<< "$(parse_semver "$version1")" || return 3
  read -r major2 minor2 patch2 <<< "$(parse_semver "$version2")" || return 3

  # Compare major.minor.patch lexicographically
  local ver1_num=$((major1 * 10000 + minor1 * 100 + patch1))
  local ver2_num=$((major2 * 10000 + minor2 * 100 + patch2))

  case "$operator" in
    "="|"==")
      [ "$ver1_num" -eq "$ver2_num" ]
      ;;
    "<")
      [ "$ver1_num" -lt "$ver2_num" ]
      ;;
    ">")
      [ "$ver1_num" -gt "$ver2_num" ]
      ;;
    "<=")
      [ "$ver1_num" -le "$ver2_num" ]
      ;;
    ">=")
      [ "$ver1_num" -ge "$ver2_num" ]
      ;;
    *)
      echo "ERROR: Invalid comparison operator: $operator (expected: =, <, >, <=, >=)" >&2
      return 3
      ;;
  esac
}

# ==============================================================================
# Library Version Checking
# ==============================================================================

# Check library version against requirement
# Args: $1 = library_name (e.g., "workflow-state-machine.sh")
#       $2 = version_requirement (e.g., ">=2.0.0")
# Returns: 0 if requirement met, 1-3 for errors
check_library_version() {
  local library_name="$1"
  local requirement="$2"

  # Extract operator and version from requirement
  local operator=""
  local required_version=""

  if [[ "$requirement" =~ ^(>=|<=|>|<|=)([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
    operator="${BASH_REMATCH[1]}"
    required_version="${BASH_REMATCH[2]}"
  else
    echo "ERROR: Invalid version requirement format: $requirement (expected: operator + version, e.g., >=2.0.0)" >&2
    return 3
  fi

  # Determine version variable name from library name
  # workflow-state-machine.sh → WORKFLOW_STATE_MACHINE_VERSION
  # state-persistence.sh → STATE_PERSISTENCE_VERSION
  local var_name=$(echo "$library_name" | sed 's/\.sh$//' | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  var_name="${var_name}_VERSION"

  # Check if library is sourced (version variable exists)
  if [ -z "${!var_name:-}" ]; then
    echo "ERROR: Library not sourced or version variable not found: $library_name ($var_name not set)" >&2
    echo "HINT: Ensure library is sourced before calling check_library_version()" >&2
    return 2
  fi

  local actual_version="${!var_name}"

  # Compare versions
  if compare_versions "$actual_version" "$operator" "$required_version"; then
    return 0  # Version requirement met
  else
    echo "ERROR: Library version requirement not met: $library_name" >&2
    echo "  Required: $requirement" >&2
    echo "  Actual: $actual_version" >&2
    return 1
  fi
}

# Validate multiple library requirements from YAML frontmatter format
# Args: $1 = requirements string (newline-separated, format: "library_name: version_requirement")
# Example:
#   check_library_requirements "$(cat <<'EOF'
#   workflow-state-machine.sh: ">=2.0.0"
#   state-persistence.sh: ">=1.5.0"
#   EOF
#   )"
# Returns: 0 if all requirements met, 1-3 for errors
check_library_requirements() {
  local requirements="$1"
  local failures=0

  # Parse each requirement line
  while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # Extract library name and version requirement
    # Format: "library-name.sh: \">=1.0.0\""
    if [[ "$line" =~ ^[[:space:]]*([^:]+):[[:space:]]*\"([^\"]+)\" ]]; then
      local lib_name="${BASH_REMATCH[1]}"
      local version_req="${BASH_REMATCH[2]}"

      # Check version requirement
      if ! check_library_version "$lib_name" "$version_req"; then
        ((failures++))
      fi
    fi
  done <<< "$requirements"

  if [ "$failures" -gt 0 ]; then
    echo "ERROR: $failures library version requirement(s) not met" >&2
    return 1
  fi

  return 0
}

# ==============================================================================
# Utility Functions
# ==============================================================================

# Display library versions for debugging
# Usage: show_library_versions
show_library_versions() {
  echo "=== Loaded Library Versions ==="

  # List known libraries
  local libraries=(
    "WORKFLOW_STATE_MACHINE_VERSION"
    "STATE_PERSISTENCE_VERSION"
    "LIBRARY_VERSION_CHECK_VERSION"
  )

  for var_name in "${libraries[@]}"; do
    if [ -n "${!var_name:-}" ]; then
      local lib_name=$(echo "$var_name" | sed 's/_VERSION$//' | tr '[:upper:]' '[:lower:]' | tr '_' '-')
      echo "  $lib_name.sh: ${!var_name}"
    fi
  done
}
