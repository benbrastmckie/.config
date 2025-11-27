#!/bin/bash
# .claude/tests/test_report_multi_agent_pattern.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Source utilities
source "$CLAUDE_ROOT/lib/artifact/artifact-creation.sh" 2>/dev/null || {
  echo "WARNING: artifact-creation.sh not found, using mock functions"
  get_or_create_topic_dir() { echo "/tmp/test_topic_dir"; }
  get_next_artifact_number() { echo "1"; }
}
source "$CLAUDE_ROOT/lib/artifact/artifact-registry.sh" 2>/dev/null || true
source "$CLAUDE_ROOT/lib/plan/topic-decomposition.sh"

# Test data
TEST_TOPIC="test_authentication_patterns"
TEST_RESEARCH_DIR="$CLAUDE_ROOT/specs/test_$(date +%s)"

echo "========================================="
echo "Testing Hierarchical Multi-Agent Research Pattern"
echo "========================================="

cleanup() {
  echo "Cleaning up test artifacts..."
  rm -rf "$TEST_RESEARCH_DIR"
}

trap cleanup EXIT

echo ""
echo "Test 1: Topic Decomposition"
echo "----------------------------"

# Test decomposition utility
subtopic_count=$(calculate_subtopic_count "$TEST_TOPIC")
echo "Expected subtopic count: $subtopic_count"

if [ "$subtopic_count" -lt 2 ] || [ "$subtopic_count" -gt 4 ]; then
  echo "ERROR: Invalid subtopic count: $subtopic_count (expected 2-4)"
  exit 1
fi

echo "✓ Topic decomposition produced valid count"

echo ""
echo "Test 2: Path Pre-Calculation"
echo "----------------------------"

# Create test topic directory
TOPIC_DIR="$TEST_RESEARCH_DIR/001_test_topic"
mkdir -p "$TOPIC_DIR/reports"
echo "Topic directory: $TOPIC_DIR"

# Test subtopics (simulated from decomposition)
TEST_SUBTOPICS=("jwt_patterns" "oauth_flows" "session_management")

# Calculate paths
declare -A TEST_PATHS
RESEARCH_SUBDIR="${TOPIC_DIR}/reports/001_test_research"
mkdir -p "$RESEARCH_SUBDIR"

for subtopic in "${TEST_SUBTOPICS[@]}"; do
  NEXT_NUM=$(find "$RESEARCH_SUBDIR" -name "[0-9][0-9][0-9]_*.md" 2>/dev/null | wc -l)
  NEXT_NUM=$((NEXT_NUM + 1))
  TEST_PATH="${RESEARCH_SUBDIR}/$(printf "%03d" "$NEXT_NUM")_${subtopic}.md"
  TEST_PATHS["$subtopic"]="$TEST_PATH"

  echo "  $subtopic: $TEST_PATH"

  # Verify absolute path
  if [[ ! "$TEST_PATH" =~ ^/ ]]; then
    echo "ERROR: Path is not absolute: $TEST_PATH"
    exit 1
  fi
done

echo "✓ All paths calculated and verified as absolute"

echo ""
echo "Test 3: Report Creation (Simulated)"
echo "----------------------------"

# Simulate research-specialist agent creating reports
for subtopic in "${TEST_SUBTOPICS[@]}"; do
  REPORT_PATH="${TEST_PATHS[$subtopic]}"

  # Create minimal report (simulating agent behavior)
  cat > "$REPORT_PATH" <<EOF
# $subtopic Research Report

## Metadata
- **Date**: $(date +%Y-%m-%d)
- **Agent**: research-specialist (test)
- **Topic**: $subtopic

## Executive Summary

Test report for $subtopic.

## Findings

Test findings for $subtopic.

## Recommendations

1. Test recommendation 1
2. Test recommendation 2
3. Test recommendation 3

## References

- test/file1.lua:123
- test/file2.lua:456
EOF

  if [ ! -f "$REPORT_PATH" ]; then
    echo "ERROR: Failed to create report: $REPORT_PATH"
    exit 1
  fi

  echo "✓ Created subtopic report: $subtopic"
done

echo "✓ All subtopic reports created"

echo ""
echo "Test 4: Overview Report Creation (Simulated)"
echo "----------------------------"

OVERVIEW_PATH="${RESEARCH_SUBDIR}/OVERVIEW.md"

# Simulate research-synthesizer creating overview
cat > "$OVERVIEW_PATH" <<EOF
# $TEST_TOPIC - Research Overview

## Metadata
- **Date**: $(date +%Y-%m-%d)
- **Research Topic**: $TEST_TOPIC
- **Subtopic Reports**: ${#TEST_SUBTOPICS[@]}

## Executive Summary

This research investigated ${#TEST_SUBTOPICS[@]} focused subtopics related to $TEST_TOPIC.

Key insights:
- Test insight 1
- Test insight 2

## Subtopic Reports

$(for i in "${!TEST_SUBTOPICS[@]}"; do
  subtopic="${TEST_SUBTOPICS[$i]}"
  num=$(printf "%03d" $((i + 1)))
  echo "### ${subtopic//_/ }"
  echo ""
  echo "**Report**: [./${num}_${subtopic}.md](./${num}_${subtopic}.md)"
  echo ""
  echo "Summary of ${subtopic} findings."
  echo ""
done)

## Cross-Cutting Themes

### Theme 1: Test Theme

Observed across all subtopics.

## Synthesized Recommendations

### High Priority

1. **Test Recommendation** (from: all subtopics)

## References

- test/file1.lua:123
- test/file2.lua:456
EOF

if [ ! -f "$OVERVIEW_PATH" ]; then
  echo "ERROR: Failed to create overview report"
  exit 1
fi

echo "✓ Overview report created"

# Verify overview contains links to subtopics
for subtopic in "${TEST_SUBTOPICS[@]}"; do
  if ! grep -q "$subtopic" "$OVERVIEW_PATH"; then
    echo "ERROR: Overview missing reference to: $subtopic"
    exit 1
  fi
done

echo "✓ Overview contains links to all subtopics"

echo ""
echo "Test 5: Artifact Structure Verification"
echo "----------------------------"

# Verify directory structure
if [ ! -d "$RESEARCH_SUBDIR" ]; then
  echo "ERROR: Research subdirectory not created"
  exit 1
fi

echo "✓ Research subdirectory created: $RESEARCH_SUBDIR"

# Count artifacts
SUBTOPIC_COUNT=$(find "$RESEARCH_SUBDIR" -name "*.md" -not -name "OVERVIEW.md" | wc -l)
if [ "$SUBTOPIC_COUNT" -ne ${#TEST_SUBTOPICS[@]} ]; then
  echo "ERROR: Expected ${#TEST_SUBTOPICS[@]} subtopic reports, found $SUBTOPIC_COUNT"
  exit 1
fi

echo "✓ Correct number of subtopic reports: $SUBTOPIC_COUNT"

if [ ! -f "$OVERVIEW_PATH" ]; then
  echo "ERROR: Overview report not found"
  exit 1
fi

echo "✓ Overview report exists"

echo ""
echo "Test 6: Subtopic Name Validation"
echo "----------------------------"

# Test subtopic validation (all subtopics should be snake_case)
for subtopic in "${TEST_SUBTOPICS[@]}"; do
  if ! validate_subtopic_name "$subtopic"; then
    echo "ERROR: Subtopic validation failed for: $subtopic"
    exit 1
  fi
done

echo "✓ All subtopic names valid (snake_case)"

echo ""
echo "Test 7: File Naming Convention"
echo "----------------------------"

# Verify all files follow NNN_name.md pattern
for report_file in "$RESEARCH_SUBDIR"/*.md; do
  basename=$(basename "$report_file")

  # OVERVIEW.md is special case (allowed)
  if [ "$basename" = "OVERVIEW.md" ]; then
    continue
  fi

  # Check NNN_name.md pattern
  if [[ ! "$basename" =~ ^[0-9]{3}_[a-z_]+\.md$ ]]; then
    echo "ERROR: File doesn't match naming pattern: $basename"
    exit 1
  fi
done

echo "✓ All files follow naming convention (NNN_name.md or OVERVIEW.md)"

echo ""
echo "========================================="
echo "All tests passed!"
echo "========================================="
echo ""
echo "Artifact structure created:"
find "$RESEARCH_SUBDIR" -type f -name "*.md" | sort

exit 0
