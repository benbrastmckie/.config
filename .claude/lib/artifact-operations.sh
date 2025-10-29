#!/usr/bin/env bash
# artifact-operations.sh - DEPRECATED backward-compatibility shim
# Version: 1.0.0 (Shim)
#
# DEPRECATED: This library has been split into:
#   - artifact-creation.sh - Functions for creating new artifacts
#   - artifact-registry.sh - Functions for tracking and querying artifacts
#
# Migration Timeline:
#   - 2025-10-29: Shim created for backward compatibility
#   - 2025-12-01: Target date for updating all 77 command references
#   - 2026-01-01: Shim removal scheduled (1-2 releases after creation)
#
# Usage (DEPRECATED):
#   source .claude/lib/artifact-operations.sh  # Old way
#
# Migration (RECOMMENDED):
#   source .claude/lib/artifact-creation.sh   # For create_artifact(), etc.
#   source .claude/lib/artifact-registry.sh   # For query_artifacts(), etc.
#
# Please update your code to use the split libraries directly.

# Source both split libraries to maintain backward compatibility
# Use BASH_SOURCE[0] to locate files relative to this shim
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "$script_dir/artifact-creation.sh" ]]; then
  echo "ERROR: artifact-creation.sh not found at: $script_dir/artifact-creation.sh" >&2
  echo "This shim requires both split libraries to be present." >&2
  return 1
fi

if [[ ! -f "$script_dir/artifact-registry.sh" ]]; then
  echo "ERROR: artifact-registry.sh not found at: $script_dir/artifact-registry.sh" >&2
  echo "This shim requires both split libraries to be present." >&2
  return 1
fi

# shellcheck disable=SC1091
source "$script_dir/artifact-creation.sh" || {
  echo "ERROR: Failed to source artifact-creation.sh" >&2
  return 1
}

# shellcheck disable=SC1091
source "$script_dir/artifact-registry.sh" || {
  echo "ERROR: Failed to source artifact-registry.sh" >&2
  return 1
}

# Emit deprecation warning to stderr (only once per process)
if [[ -z "${ARTIFACT_OPS_DEPRECATION_WARNING_SHOWN:-}" ]]; then
  echo "WARNING: artifact-operations.sh is deprecated. Use artifact-creation.sh and artifact-registry.sh directly." >&2
  echo "         This shim will be removed in a future release. See migration guide in file header." >&2
  export ARTIFACT_OPS_DEPRECATION_WARNING_SHOWN=1
fi
