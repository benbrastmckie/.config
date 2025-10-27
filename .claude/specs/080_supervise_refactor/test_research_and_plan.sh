#!/usr/bin/env bash
#
# Test Script: Research-and-Plan Workflow
#
# Tests /supervise with a research + plan request
# Expected: 4 research agents, research overview, plan file created

set -euo pipefail

echo "=== Testing Research-and-Plan Workflow ==="
echo "Request: 'research oauth to create plan'"
echo ""

# This would be executed via Claude Code's /supervise command:
# /supervise "research oauth to create plan"

# Expected behavior:
# 1. Workflow scope detected as: research-and-plan
# 2. Phase 1: 4 research agents invoked in parallel
# 3. Phase 1: Research overview created
# 4. Phase 2: Implementation plan created based on research
# 5. Phases 3-6: Skipped (not in scope)
# 6. Final output: Research reports + implementation plan

# Verification points:
# [ ] Workflow scope: research-and-plan
# [ ] 4 research reports created
# [ ] Research overview created
# [ ] Implementation plan created
# [ ] No implementation artifacts
# [ ] Progress markers: Phases 1-2 only

echo "Test script created - manual execution required via Claude Code"
echo "Run: /supervise 'research oauth to create plan'"
