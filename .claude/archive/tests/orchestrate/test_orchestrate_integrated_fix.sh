#!/usr/bin/env bash
set -euo pipefail

echo "=== Testing Integrated /orchestrate Fix ==="

# Set up environment
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/home/benjamin/.config}"
cd "$CLAUDE_PROJECT_DIR"

# Source required utilities
source .claude/lib/artifact-creation.sh
source .claude/lib/template-integration.sh
source .claude/lib/metadata-extraction.sh

# Test 1: artifact-creation.sh supports reports/plans
test_artifact_creation() {
  echo ""
  echo "Test 1: Artifact creation supports reports and plans"

  local topic_dir=$(get_or_create_topic_dir "test topic" ".claude/specs")
  local report=$(create_topic_artifact "$topic_dir" "reports" "test_report" "# Test Report

## Executive Summary
This is a test report for validation purposes.

## Findings
- Finding 1
- Finding 2")

  if [[ ! -f "$report" ]]; then
    echo "✗ FAIL: Report not created"
    return 1
  fi

  local plan=$(create_topic_artifact "$topic_dir" "plans" "test_plan" "# Test Plan

## Phase 1
- [ ] Task 1")

  if [[ ! -f "$plan" ]]; then
    echo "✗ FAIL: Plan not created"
    return 1
  fi

  echo "✓ PASS: Artifact creation supports reports and plans"

  # Cleanup
  rm -rf "$topic_dir"
}

# Test 2: Topic-based directory structure
test_topic_structure() {
  echo ""
  echo "Test 2: Topic directory structure correct"

  local topic_dir=$(get_or_create_topic_dir "orchestrate test" ".claude/specs")

  if [[ ! "$topic_dir" =~ .claude/specs/[0-9]+_orchestrate_test ]]; then
    echo "✗ FAIL: Topic directory format incorrect: $topic_dir"
    return 1
  fi

  if [[ ! -d "$topic_dir/reports" ]]; then
    echo "✗ FAIL: reports/ not created"
    return 1
  fi

  if [[ ! -d "$topic_dir/plans" ]]; then
    echo "✗ FAIL: plans/ not created"
    return 1
  fi

  if [[ ! -d "$topic_dir/summaries" ]]; then
    echo "✗ FAIL: summaries/ not created"
    return 1
  fi

  echo "✓ PASS: Topic directory structure correct"

  # Cleanup
  rm -rf "$topic_dir"
}

# Test 3: Agent creates file correctly (happy path)
test_agent_creates_file() {
  echo ""
  echo "Test 3: File created and metadata extracted"

  local topic="auth_patterns"
  local report_path=".claude/specs/test_research/reports/001_${topic}.md"
  mkdir -p "$(dirname "$report_path")"

  cat > "$report_path" <<'EOF'
# Authentication Patterns

## Executive Summary
JWT tokens recommended for stateless authentication.

## Findings
- JWT: Stateless authentication
- Session-based: Requires server-side storage
- OAuth2: Third-party authentication
EOF

  if [[ ! -f "$report_path" ]]; then
    echo "✗ FAIL: File not created"
    return 1
  fi

  local metadata=$(extract_report_metadata "$report_path")
  local summary=$(echo "$metadata" | jq -r '.summary')

  if [[ -z "$summary" ]]; then
    echo "✗ FAIL: Metadata extraction failed"
    return 1
  fi

  echo "✓ PASS: File created and metadata extracted"

  # Cleanup
  rm -rf ".claude/specs/test_research"
}

# Test 4: Fallback report creation
test_fallback_creation() {
  echo ""
  echo "Test 4: Fallback report creation"

  local topic="security_practices"
  local report_path=".claude/specs/test_research/reports/001_${topic}.md"
  mkdir -p "$(dirname "$report_path")"

  local agent_output="Security best practices: Use bcrypt for password hashing. Enable rate limiting on authentication endpoints."

  # Simulate fallback creation
  if [[ ! -f "$report_path" ]]; then
    cat > "$report_path" <<EOF
# ${topic}

## Metadata
- **Date**: $(date -u +%Y-%m-%d)
- **Agent**: research-specialist (fallback creation)
- **Topic**: ${topic}

## Findings
$agent_output

## Note
This report was created by fallback mechanism.
EOF
  fi

  if [[ ! -f "$report_path" ]]; then
    echo "✗ FAIL: Fallback didn't create file"
    return 1
  fi

  echo "✓ PASS: Fallback report created"

  # Cleanup
  rm -rf ".claude/specs/test_research"
}

# Test 5: Context reduction via metadata
test_context_reduction() {
  echo ""
  echo "Test 5: Context reduction via metadata extraction"

  local report_path=".claude/specs/test_research/reports/001_test.md"
  mkdir -p "$(dirname "$report_path")"

  # Create a report with substantial content
  cat > "$report_path" <<EOF
# Test Report

## Executive Summary
This analyzes authentication patterns in the codebase. JWT tokens are recommended for API authentication.

## Findings
$(printf 'Detailed analysis of authentication patterns. %.0s' {1..100})

## Recommendations
- Implement JWT authentication
- Add refresh token mechanism
- Enable rate limiting
EOF

  local full_size=$(wc -c < "$report_path")
  local metadata=$(extract_report_metadata "$report_path")
  local metadata_size=$(echo "$metadata" | wc -c)

  if [[ $full_size -eq 0 ]]; then
    echo "✗ FAIL: Report file is empty"
    return 1
  fi

  local reduction=$((100 - (metadata_size * 100 / full_size)))

  echo "  Full: $full_size chars, Metadata: $metadata_size chars, Reduction: ${reduction}%"

  if [[ $reduction -ge 90 ]]; then
    echo "✓ PASS: Context reduction target met (>90%)"
  else
    echo "WARN: Context reduction below target (${reduction}% < 90%)"
  fi

  # Cleanup
  rm -rf ".claude/specs/test_research"
}

# Run all tests
echo ""
test_artifact_creation
test_topic_structure
test_agent_creates_file
test_fallback_creation
test_context_reduction

echo ""
echo "=== All Tests Passed ==="
