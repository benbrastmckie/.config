#!/usr/bin/env bash
#
# Test Script: Debug-Only Workflow
#
# Tests /supervise with a debug/fix request
# Expected: Skip research/plan, go directly to debug phase

set -euo pipefail

echo "=== Testing Debug-Only Workflow ==="
echo "Request: 'fix token refresh bug'"
echo ""

# This would be executed via Claude Code's /supervise command:
# /supervise "fix token refresh bug"

# Expected behavior:
# 1. Workflow scope detected as: debug-only
# 2. Phases 1-2: Skipped (no research/planning for bug fixes)
# 3. Phase 5: Debug agent invoked directly
# 4. Phase 5: Debug report created with root cause and fix
# 5. Phase 6: Summary documentation created
# 6. Final output: Debug report with fix recommendations

# Verification points:
# [ ] Workflow scope: debug-only
# [ ] No research reports
# [ ] No plan file
# [ ] Debug report created
# [ ] Summary documentation created
# [ ] Progress markers: Phases 5-6 only

echo "Test script created - manual execution required via Claude Code"
echo "Run: /supervise 'fix token refresh bug'"
