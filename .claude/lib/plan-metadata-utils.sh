#!/usr/bin/env bash
# plan-metadata-utils.sh
#
# DEPRECATED: This file has been consolidated into plan-core-bundle.sh
#
# For backward compatibility, this file sources plan-core-bundle.sh.
# Update your code to source plan-core-bundle.sh instead.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/plan-core-bundle.sh"

# Deprecated warning (suppressed by default to avoid spam)
if [[ "${SHOW_DEPRECATION_WARNINGS:-0}" == "1" ]]; then
  echo "WARNING: plan-metadata-utils.sh is deprecated. Use plan-core-bundle.sh instead." >&2
fi
