#!/usr/bin/env bash
# parse-adaptive-plan.sh - Compatibility shim for refactored utilities
# This script sources the new modular utilities and provides compatibility
# with the old parse-adaptive-plan.sh interface for tests

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Source the utility modules (wrappers removed, using direct modules)
source "$LIB_DIR/plan-core-bundle.sh" 2>/dev/null || true
source "$LIB_DIR/progressive-planning-utils.sh" 2>/dev/null || true

# If called as a script (not sourced), execute the requested function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Get function name and arguments
  func_name="$1"
  shift

  # Check if function exists and call it
  if declare -f "$func_name" > /dev/null; then
    "$func_name" "$@"
  else
    echo "Error: Function '$func_name' not found" >&2
    echo "Available functions are defined in:" >&2
    echo "  - plan-structure-utils.sh" >&2
    echo "  - plan-metadata-utils.sh" >&2
    echo "  - progressive-planning-utils.sh" >&2
    echo "  - parse-plan-core.sh" >&2
    exit 1
  fi
fi
