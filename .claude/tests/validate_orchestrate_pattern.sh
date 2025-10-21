#!/usr/bin/env bash
# Test wrapper for orchestrate architectural pattern validation
# Calls the main validation script from lib/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATION_SCRIPT="${SCRIPT_DIR}/../lib/validate-orchestrate-pattern.sh"

# Call the main validation script
bash "$VALIDATION_SCRIPT"
