#!/usr/bin/env bash
#
# adaptive-planning-logger.sh
#
# DEPRECATED: This file has been consolidated into unified-logger.sh
#
# For backward compatibility, this file sources unified-logger.sh.
# Update your code to source unified-logger.sh instead.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/unified-logger.sh"

# Deprecated warning (suppressed by default to avoid spam)
if [[ "${SHOW_DEPRECATION_WARNINGS:-0}" == "1" ]]; then
  echo "WARNING: adaptive-planning-logger.sh is deprecated. Use unified-logger.sh instead." >&2
fi
