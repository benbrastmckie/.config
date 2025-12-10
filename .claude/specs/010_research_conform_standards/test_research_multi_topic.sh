#!/bin/bash
# test_research_multi_topic.sh - Test multi-topic research mode

set -e

FAILED=0
TEST_DIR="/home/benjamin/.config/.claude/specs/010_research_conform_standards"

echo "========================================="
echo "Test Suite: Multi-Topic Research Mode"
echo "========================================="
echo ""

# Test 3: Multi-topic decomposition logic
echo "Test 3: Multi-topic decomposition validation"
echo "--------------------------------------------"

# Check decomposition logic exists
if grep -q "IFS=',' read -ra PARTS" /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Comma decomposition logic found"
else
  echo "FAIL: Missing comma decomposition logic"
  FAILED=1
fi

if grep -q "IFS=' and ' read -ra SUB_PARTS" /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Conjunction decomposition logic found"
else
  echo "FAIL: Missing conjunction decomposition logic"
  FAILED=1
fi

# Check for multi-topic mode detection
if grep -q 'USE_MULTI_TOPIC="true"' /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Multi-topic mode flag found"
else
  echo "FAIL: Missing multi-topic mode flag"
  FAILED=1
fi

# Check for complexity-based mode detection
if grep -q 'if \[ "\${RESEARCH_COMPLEXITY:-2}" -ge 3 \]' /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Complexity-based mode detection found"
else
  echo "FAIL: Missing complexity-based mode detection"
  FAILED=1
fi

echo ""

# Test 4: Array handling patterns
echo "Test 4: Array handling patterns"
echo "-------------------------------"

# Check for array length checks
if grep -q '\${#TOPICS_ARRAY\[@\]}' /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Array length checks found"
else
  echo "FAIL: Missing array length checks"
  FAILED=1
fi

# Check for array iteration patterns
if grep -q 'for i in "\${!TOPICS_ARRAY\[@\]}"' /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Safe array iteration pattern found"
else
  echo "FAIL: Missing safe array iteration pattern"
  FAILED=1
fi

# Check for array element access with quotes
if grep -q '\${TOPICS_ARRAY\[\$i\]}' /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Array element access pattern found"
else
  echo "FAIL: Missing array element access"
  FAILED=1
fi

echo ""

# Test 5: Fallback logic for decomposition edge cases
echo "Test 5: Decomposition edge case handling"
echo "----------------------------------------"

# Check for fallback to single-topic mode
if grep -q 'if \[ \${#TOPICS_ARRAY\[@\]} -lt 2 \]' /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Fallback logic for insufficient topics found"
else
  echo "FAIL: Missing fallback logic"
  FAILED=1
fi

# Check for array reset in fallback
if grep -q 'TOPICS_ARRAY=("$WORKFLOW_DESCRIPTION")' /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Array reset in fallback found"
else
  echo "FAIL: Missing array reset in fallback"
  FAILED=1
fi

echo ""

# Test 6: Report path pre-calculation for multiple topics
echo "Test 6: Report path pre-calculation"
echo "-----------------------------------"

# Check for report path loop
if grep -q 'for i in "\${!TOPICS_ARRAY\[@\]}"' /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Report path calculation loop found"
else
  echo "FAIL: Missing report path calculation loop"
  FAILED=1
fi

# Check for sequential numbering
if grep -q 'REPORT_NUM=\$(printf "%03d"' /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Sequential report numbering found"
else
  echo "FAIL: Missing sequential report numbering"
  FAILED=1
fi

# Check for slug generation
if grep -q 'REPORT_SLUG=\$(echo "$TOPIC"' /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Report slug generation found"
else
  echo "FAIL: Missing report slug generation"
  FAILED=1
fi

echo ""

# Test 7: State persistence for multi-topic data
echo "Test 7: State persistence for arrays"
echo "------------------------------------"

# Check for pipe-separated list creation
if grep -q 'TOPICS_LIST=\$(printf "%s|"' /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Topics list serialization found"
else
  echo "FAIL: Missing topics list serialization"
  FAILED=1
fi

if grep -q 'REPORT_PATHS_LIST=\$(printf "%s|"' /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Report paths list serialization found"
else
  echo "FAIL: Missing report paths list serialization"
  FAILED=1
fi

# Check for state persistence calls
if grep -q 'append_workflow_state "TOPICS_LIST"' /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Topics list persistence found"
else
  echo "FAIL: Missing topics list persistence"
  FAILED=1
fi

if grep -q 'append_workflow_state "REPORT_PATHS_LIST"' /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Report paths list persistence found"
else
  echo "FAIL: Missing report paths list persistence"
  FAILED=1
fi

echo ""

# Test 8: Coordinator routing logic
echo "Test 8: Coordinator vs specialist routing"
echo "-----------------------------------------"

# Check for routing decision based on complexity
if grep -q "research-coordinator" /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Coordinator invocation path found"
else
  echo "FAIL: Missing coordinator invocation"
  FAILED=1
fi

if grep -q "research-specialist" /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Specialist invocation path found"
else
  echo "FAIL: Missing specialist invocation"
  FAILED=1
fi

# Check for multi-topic parameter passing
if grep -q "topics: \${TOPICS_LIST}" /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Topics list passed to coordinator"
else
  echo "FAIL: Missing topics list parameter"
  FAILED=1
fi

if grep -q "report_paths: \${REPORT_PATHS_LIST}" /home/benjamin/.config/.claude/commands/research.md; then
  echo "PASS: Report paths list passed to coordinator"
else
  echo "FAIL: Missing report paths list parameter"
  FAILED=1
fi

echo ""
echo "========================================="
if [ $FAILED -eq 0 ]; then
  echo "RESULT: ALL TESTS PASSED"
  echo "========================================="
  exit 0
else
  echo "RESULT: SOME TESTS FAILED"
  echo "========================================="
  exit 1
fi
