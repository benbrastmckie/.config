#!/usr/bin/env bash
# artifact-operations.sh - Backward Compatibility Wrapper
# This file sources all modularized artifact operation utilities
# Maintained for backward compatibility - all existing code continues to work

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all modularized utilities
source "${SCRIPT_DIR}/base-utils.sh"
source "${SCRIPT_DIR}/unified-logger.sh"
source "${SCRIPT_DIR}/metadata-extraction.sh"
source "${SCRIPT_DIR}/hierarchical-agent-support.sh"
source "${SCRIPT_DIR}/artifact-registry.sh"
source "${SCRIPT_DIR}/artifact-creation.sh"
source "${SCRIPT_DIR}/report-generation.sh"
source "${SCRIPT_DIR}/artifact-cleanup.sh"
source "${SCRIPT_DIR}/artifact-cross-reference.sh"

# All functions from sourced modules are now available
# This wrapper maintains 100% backward compatibility
