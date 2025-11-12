#!/usr/bin/env bash
# Manual End-to-End Integration Tests for Hybrid Workflow Classification
#
# Purpose: Verify hybrid classification works correctly in real /coordinate workflows
# Status: Manual test script - requires real LLM integration to execute
#
# These tests validate:
# 1. Problematic edge case is fixed (research-and-revise false positive)
# 2. Normal classification works
# 3. Revision cases work correctly
# 4. Fallback to regex is transparent
#
# Prerequisites:
# - LLM classifier must be able to process requests (requires real AI assistant integration)
# - /coordinate command must be functional
# - CLAUDE_PROJECT_DIR must be set correctly

set -euo pipefail

echo "=========================================="
echo "Manual E2E Tests: Hybrid Classification"
echo "=========================================="
echo
echo "IMPORTANT: These tests require manual execution with real LLM integration."
echo "The LLM classifier uses file-based signaling that requires the AI assistant"
echo "to process classification requests in real-time."
echo
echo "To run these tests manually:"
echo "1. Ensure hybrid mode is enabled (default)"
echo "2. Run each test case below"
echo "3. Verify the expected scope is detected"
echo "4. Check debug logs for classification method"
echo
echo "=========================================="
echo

# Test Case 1: Problematic edge case (from issue #670)
echo "Test 1: Problematic Edge Case"
echo "------------------------------"
echo "Description: User discussing workflow types (not requesting them)"
echo "Input: 'research the research-and-revise workflow misclassification issue'"
echo "Expected: research-and-plan (intent: research and create plan to fix issue)"
echo "Regex behavior: incorrectly returns research-and-revise (false positive)"
echo "LLM behavior: should correctly identify intent as research-and-plan"
echo
echo "Command to run:"
echo "  WORKFLOW_CLASSIFICATION_DEBUG=1 \\"
echo "    /coordinate 'research the research-and-revise workflow misclassification issue'"
echo
echo "Verification:"
echo "  - Check debug logs for 'Scope Detection: mode=hybrid, method=llm, scope=research-and-plan'"
echo "  - Workflow should proceed to research and planning phases"
echo "  - No errors about missing plan paths"
echo
read -p "Press Enter to see Test 2..."
echo

# Test Case 2: Normal classification case
echo "Test 2: Normal Case"
echo "-------------------"
echo "Description: Standard research-and-plan workflow"
echo "Input: 'research authentication patterns and create implementation plan'"
echo "Expected: research-and-plan"
echo "LLM behavior: should correctly identify as research-and-plan"
echo "Fallback: regex would also return research-and-plan (agreement)"
echo
echo "Command to run:"
echo "  /coordinate 'research authentication patterns and create implementation plan'"
echo
echo "Verification:"
echo "  - Workflow proceeds to research phase"
echo "  - Planning phase executes after research"
echo "  - No implementation phase runs"
echo
read -p "Press Enter to see Test 3..."
echo

# Test Case 3: Revision case
echo "Test 3: Revision Case"
echo "---------------------"
echo "Description: Revising an existing plan"
echo "Input: 'Revise the plan at specs/042_auth/plans/001_plan.md based on new requirements'"
echo "Expected: research-and-revise"
echo "LLM behavior: should correctly identify revision intent"
echo "Fallback: regex would also return research-and-revise (agreement)"
echo
echo "Command to run:"
echo "  /coordinate 'Revise the plan at specs/042_auth/plans/001_plan.md based on new requirements'"
echo
echo "Verification:"
echo "  - Workflow extracts EXISTING_PLAN_PATH"
echo "  - Research phase analyzes existing plan"
echo "  - Revision phase updates the plan"
echo
read -p "Press Enter to see Test 4..."
echo

# Test Case 4: Fallback behavior (force timeout)
echo "Test 4: Fallback Case"
echo "---------------------"
echo "Description: LLM timeout triggers automatic regex fallback"
echo "Input: 'research auth patterns'"
echo "Expected: research-and-plan (via regex fallback)"
echo "LLM behavior: times out (forced via WORKFLOW_CLASSIFICATION_TIMEOUT=0)"
echo "Fallback: regex returns research-and-plan"
echo
echo "Command to run:"
echo "  WORKFLOW_CLASSIFICATION_TIMEOUT=0 \\"
echo "    WORKFLOW_CLASSIFICATION_DEBUG=1 \\"
echo "    /coordinate 'research auth patterns'"
echo
echo "Verification:"
echo "  - Debug logs show: 'Scope Detection: mode=hybrid, method=regex-fallback'"
echo "  - Workflow proceeds normally (fallback is transparent)"
echo "  - No error messages visible to user"
echo "  - Workflow completes successfully"
echo
read -p "Press Enter to see Test 5..."
echo

# Test Case 5: LLM-only mode (fail-fast)
echo "Test 5: LLM-Only Mode (Fail-Fast)"
echo "----------------------------------"
echo "Description: Verify fail-fast behavior when LLM unavailable"
echo "Input: 'plan authentication feature'"
echo "Expected: Error with clear message (no fallback in llm-only mode)"
echo "LLM behavior: fails (no real LLM available)"
echo "Fallback: none (llm-only mode disables fallback)"
echo
echo "Command to run:"
echo "  WORKFLOW_CLASSIFICATION_MODE=llm-only \\"
echo "    /coordinate 'plan authentication feature'"
echo
echo "Verification:"
echo "  - Error message: 'LLM classification failed in llm-only mode'"
echo "  - Workflow returns default scope: research-and-plan"
echo "  - Clear error messaging (fail-fast philosophy)"
echo
read -p "Press Enter to see Test 6..."
echo

# Test Case 6: Mode switching
echo "Test 6: Mode Switching"
echo "----------------------"
echo "Description: Verify environment variable mode switching works"
echo "Input: 'implement user authentication'"
echo "Expected: full-implementation (in any mode)"
echo
echo "Command to run (regex-only):"
echo "  WORKFLOW_CLASSIFICATION_MODE=regex-only \\"
echo "    /coordinate 'implement user authentication'"
echo
echo "Command to run (hybrid):"
echo "  WORKFLOW_CLASSIFICATION_MODE=hybrid \\"
echo "    /coordinate 'implement user authentication'"
echo
echo "Verification:"
echo "  - Both modes should return full-implementation"
echo "  - Regex mode: immediate classification"
echo "  - Hybrid mode: may use LLM or fallback to regex"
echo "  - Results should be identical"
echo
echo

echo "=========================================="
echo "Manual Testing Complete"
echo "=========================================="
echo
echo "Summary of Manual Tests:"
echo "1. ✓ Test 1: Edge case (discussing workflow types)"
echo "2. ✓ Test 2: Normal case (research-and-plan)"
echo "3. ✓ Test 3: Revision case (research-and-revise)"
echo "4. ✓ Test 4: Fallback behavior (timeout → regex)"
echo "5. ✓ Test 5: LLM-only fail-fast"
echo "6. ✓ Test 6: Mode switching"
echo
echo "Acceptance Criteria:"
echo "- [ ] All test cases produce correct scope"
echo "- [ ] Problematic case fixed (Test 1)"
echo "- [ ] Debug logs show classification method"
echo "- [ ] Fallback transparent to user (Test 4)"
echo "- [ ] Workflow completes successfully in all cases"
echo
echo "Notes:"
echo "- Tests 1, 4 require real LLM integration to verify"
echo "- Tests 2, 3, 6 can be verified with regex-only mode"
echo "- Test 5 verifies fail-fast error handling"
echo
echo "To test in regex-only mode (no LLM required):"
echo "  export WORKFLOW_CLASSIFICATION_MODE=regex-only"
echo "  # Run Tests 2, 3, 6"
echo
echo "To test hybrid mode (requires LLM):"
echo "  export WORKFLOW_CLASSIFICATION_MODE=hybrid  # default"
echo "  # Run all tests"
echo
