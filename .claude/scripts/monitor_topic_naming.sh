#!/usr/bin/env bash
#
# Topic Naming Compliance Monitoring Script
#
# Monitors new topic directories created post-deployment to validate
# enhanced sanitization is working correctly across all commands.
#
# Usage:
#   ./monitor_topic_naming.sh --report                    # Generate compliance report
#   ./monitor_topic_naming.sh --baseline                  # Create baseline snapshot
#   ./monitor_topic_naming.sh --check NNN_topic_name      # Check single topic

set -eo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPECS_DIR="${CLAUDE_CONFIG:-$HOME/.config}/.claude/specs"
BASELINE_FILE="${SCRIPT_DIR}/../data/topic_naming_baseline.txt"
MONITOR_LOG="${SCRIPT_DIR}/../logs/topic_naming_monitor.log"

# Ensure log directory exists
mkdir -p "$(dirname "$MONITOR_LOG")"

# Parse arguments
MODE="report"
SINGLE_TOPIC=""

for arg in "$@"; do
  case $arg in
    --report)
      MODE="report"
      ;;
    --baseline)
      MODE="baseline"
      ;;
    --check)
      MODE="check"
      ;;
    --check=*)
      MODE="check"
      SINGLE_TOPIC="${arg#*=}"
      ;;
    *)
      if [ "$MODE" = "check" ] && [ -z "$SINGLE_TOPIC" ]; then
        SINGLE_TOPIC="$arg"
      fi
      ;;
  esac
done

# Validation functions
has_artifact_reference() {
  local topic_name="$1"

  # Check for artifact numbering (001_, NNN_)
  if [[ "$topic_name" =~ [0-9]{3}_ ]]; then
    echo "artifact_numbering"
    return 0
  fi

  # Check for file extensions
  if [[ "$topic_name" =~ \.(md|txt|sh|json|yaml) ]]; then
    echo "file_extension"
    return 0
  fi

  # Check for artifact directory names
  if [[ "$topic_name" =~ (reports|plans|summaries|debug|scripts|outputs|artifacts|backups) ]]; then
    echo "artifact_directory"
    return 0
  fi

  # Check for common basenames
  if [[ "$topic_name" =~ (readme|claude|output|plan|report|summary) ]]; then
    echo "common_basename"
    return 0
  fi

  return 1
}

check_length_violation() {
  local topic_name="$1"
  local length=${#topic_name}

  if [ $length -gt 35 ]; then
    echo "$length"
    return 0
  fi

  return 1
}

check_semantic_clarity() {
  local topic_name="$1"

  # Simple heuristic: semantic if it contains technical/domain terms
  # Non-semantic if only meta-words or too short

  if [ ${#topic_name} -lt 3 ]; then
    echo "too_short"
    return 1
  fi

  # Check for only meta-words (simplified check)
  if [[ "$topic_name" =~ ^(create|update|research|plan|implement|analyze|fix)$ ]]; then
    echo "only_meta_word"
    return 1
  fi

  # Otherwise assume semantic
  return 0
}

# Baseline creation
create_baseline() {
  echo "Creating baseline snapshot of existing topics..."

  if [ ! -d "$SPECS_DIR" ]; then
    echo "ERROR: Specs directory not found: $SPECS_DIR"
    exit 1
  fi

  # List all current topic directories
  ls -1d "$SPECS_DIR"/[0-9][0-9][0-9]_* 2>/dev/null | \
    xargs -n1 basename > "$BASELINE_FILE" || true

  local count=$(wc -l < "$BASELINE_FILE" 2>/dev/null || echo 0)
  echo "Baseline created: $count existing topics"
  echo "Baseline file: $BASELINE_FILE"
  echo ""
  echo "New topics created after this baseline will be monitored for compliance."
}

# Single topic check
check_single_topic() {
  local topic="$1"
  local topic_name=$(echo "$topic" | sed 's/^[0-9][0-9][0-9]_//')

  echo "========================================"
  echo "Topic Name Compliance Check"
  echo "========================================"
  echo "Topic: $topic"
  echo "Name: $topic_name"
  echo "Length: ${#topic_name} chars"
  echo ""

  local violations=0

  # Check artifact references
  local artifact_type
  if artifact_type=$(has_artifact_reference "$topic_name"); then
    echo "✗ VIOLATION: Artifact reference ($artifact_type)"
    violations=$((violations + 1))
  else
    echo "✓ No artifact references"
  fi

  # Check length
  local length
  if length=$(check_length_violation "$topic_name"); then
    echo "✗ VIOLATION: Length exceeds limit ($length > 35 chars)"
    violations=$((violations + 1))
  else
    echo "✓ Length within limit (${#topic_name} ≤ 35 chars)"
  fi

  # Check semantic clarity
  local clarity_issue
  if ! clarity_issue=$(check_semantic_clarity "$topic_name"); then
    echo "⚠ WARNING: Potential semantic clarity issue ($clarity_issue)"
  else
    echo "✓ Semantic clarity acceptable"
  fi

  echo ""
  if [ $violations -eq 0 ]; then
    echo "Result: COMPLIANT"
    return 0
  else
    echo "Result: NON-COMPLIANT ($violations violations)"
    return 1
  fi
}

# Generate compliance report
generate_report() {
  echo "========================================"
  echo "Topic Naming Compliance Report"
  echo "========================================"
  echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""

  # Load baseline
  if [ ! -f "$BASELINE_FILE" ]; then
    echo "WARNING: No baseline found. Creating baseline now..."
    create_baseline
    echo ""
    echo "No new topics to analyze. Run this command again after creating new topics."
    return 0
  fi

  local baseline_count=$(wc -l < "$BASELINE_FILE" 2>/dev/null || echo 0)
  echo "Baseline: $baseline_count existing topics"
  echo ""

  # Find new topics (created after baseline)
  local new_topics=()
  while IFS= read -r topic; do
    if ! grep -q "^$topic\$" "$BASELINE_FILE" 2>/dev/null; then
      new_topics+=("$topic")
    fi
  done < <(ls -1d "$SPECS_DIR"/[0-9][0-9][0-9]_* 2>/dev/null | xargs -n1 basename || true)

  local new_count=${#new_topics[@]}
  echo "New Topics: $new_count (since baseline)"
  echo ""

  if [ $new_count -eq 0 ]; then
    echo "No new topics to analyze."
    return 0
  fi

  # Analyze compliance
  local artifact_violations=0
  local length_violations=0
  local total_length=0
  local semantic_warnings=0

  echo "Analyzing new topics..."
  echo ""

  for topic in "${new_topics[@]}"; do
    local topic_name=$(echo "$topic" | sed 's/^[0-9][0-9][0-9]_//')
    local length=${#topic_name}
    total_length=$((total_length + length))

    # Check violations
    if has_artifact_reference "$topic_name" >/dev/null; then
      artifact_violations=$((artifact_violations + 1))
      echo "  ✗ $topic (artifact reference)"
    elif check_length_violation "$topic_name" >/dev/null; then
      length_violations=$((length_violations + 1))
      echo "  ✗ $topic (length: $length chars)"
    elif ! check_semantic_clarity "$topic_name" >/dev/null; then
      semantic_warnings=$((semantic_warnings + 1))
      echo "  ⚠ $topic (semantic clarity)"
    else
      echo "  ✓ $topic"
    fi
  done

  echo ""
  echo "========================================"
  echo "Compliance Metrics"
  echo "========================================"
  echo ""

  local avg_length=$((total_length / new_count))
  local compliant=$((new_count - artifact_violations - length_violations))
  local compliance_pct=$((compliant * 100 / new_count))

  echo "Artifact References: $artifact_violations ($(( artifact_violations * 100 / new_count ))%)"
  echo "Length Violations (>35 chars): $length_violations ($(( length_violations * 100 / new_count ))%)"
  echo "Average Length: $avg_length chars"
  echo "Semantic Clarity Warnings: $semantic_warnings ($(( semantic_warnings * 100 / new_count ))%)"
  echo ""
  echo "Overall Compliance: $compliant/$new_count ($compliance_pct%)"
  echo ""

  # Success criteria
  local success=true
  if [ $artifact_violations -gt 0 ]; then
    echo "✗ FAIL: Artifact references detected (target: 0%)"
    success=false
  else
    echo "✓ PASS: No artifact references (0%)"
  fi

  if [ $avg_length -gt 35 ]; then
    echo "✗ FAIL: Average length exceeds target ($avg_length > 35 chars)"
    success=false
  else
    echo "✓ PASS: Average length within target ($avg_length ≤ 35 chars)"
  fi

  if [ $compliance_pct -lt 95 ]; then
    echo "✗ FAIL: Compliance below target ($compliance_pct% < 95%)"
    success=false
  else
    echo "✓ PASS: Compliance meets target ($compliance_pct% ≥ 95%)"
  fi

  echo ""
  if $success; then
    echo "OVERALL: PASS"
    return 0
  else
    echo "OVERALL: FAIL"
    return 1
  fi
}

# Main execution
main() {
  case $MODE in
    baseline)
      create_baseline
      ;;
    check)
      if [ -z "$SINGLE_TOPIC" ]; then
        echo "ERROR: No topic specified for check"
        echo "Usage: $0 --check NNN_topic_name"
        exit 1
      fi
      check_single_topic "$SINGLE_TOPIC"
      ;;
    report)
      generate_report
      ;;
    *)
      echo "ERROR: Unknown mode: $MODE"
      exit 1
      ;;
  esac
}

main
