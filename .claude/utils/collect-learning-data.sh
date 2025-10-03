#!/usr/bin/env bash
# Collect workflow pattern data for adaptive learning
# Usage: collect-learning-data.sh <workflow-type> <outcome> <data-json>

set -euo pipefail

WORKFLOW_TYPE="${1:?Workflow type required (feature|refactor|debug|investigation)}"
OUTCOME="${2:?Outcome required (success|partial|failed)}"
DATA_JSON="${3:?Workflow data JSON required}"

LEARNING_DIR=".claude/learning"
PRIVACY_FILTER="$LEARNING_DIR/privacy-filter.yaml"

# Check if learning is disabled
if [[ "${CLAUDE_LEARNING_DISABLED:-0}" == "1" ]] || [[ -f "$LEARNING_DIR/.opt-out" ]]; then
  echo "Learning disabled, skipping data collection"
  exit 0
fi

# Ensure learning directory exists
mkdir -p "$LEARNING_DIR"

# Apply privacy filters to data
apply_privacy_filters() {
  local data="$1"

  # File path anonymization
  data=$(echo "$data" | sed 's|/home/[^/]\+/|/home/user/|g')
  data=$(echo "$data" | sed 's|/Users/[^/]\+/|/Users/user/|g')
  data=$(echo "$data" | sed 's|C:\\Users\\[^\\]\+|C:\\Users\\user|g')

  # Remove sensitive keywords
  local sensitive_keywords=(
    "password" "passwd" "secret" "api_key" "api-key" "apikey"
    "token" "auth_token" "access_token" "refresh_token"
    "credential" "credentials" "private_key" "ssh_key" "certificate"
  )

  for keyword in "${sensitive_keywords[@]}"; do
    # Remove entire fields containing sensitive keywords
    data=$(echo "$data" | grep -v "\"$keyword\":" || echo "$data")
  done

  # Sanitize error messages (keep only filename, not full path)
  data=$(echo "$data" | sed 's|in file .*/\([^/]\+\)|in file \1|g')

  # Anonymize emails
  data=$(echo "$data" | sed 's|[a-zA-Z0-9._%+-]\+@[a-zA-Z0-9.-]\+\.[a-zA-Z]\{2,\}|user@example.com|g')

  # Anonymize IP addresses
  data=$(echo "$data" | sed 's|\b\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}\b|0.0.0.0|g')

  echo "$data"
}

# Extract key metrics from workflow data
extract_metrics() {
  local data="$1"

  # Use grep and sed to extract fields (simplified JSON parsing)
  local feature_keywords
  local plan_phases
  local implementation_time
  local test_success_rate
  local error_count
  local research_topics
  local parallelization_used

  feature_keywords=$(echo "$data" | grep -o '"feature_keywords":\[.*\]' || echo '[]')
  plan_phases=$(echo "$data" | grep -o '"plan_phases":[0-9]\+' | grep -o '[0-9]\+' || echo '0')
  implementation_time=$(echo "$data" | grep -o '"implementation_time":[0-9]\+' | grep -o '[0-9]\+' || echo '0')
  test_success_rate=$(echo "$data" | grep -o '"test_success_rate":[0-9.]\+' | grep -o '[0-9.]\+' || echo '1.0')
  error_count=$(echo "$data" | grep -o '"error_count":[0-9]\+' | grep -o '[0-9]\+' || echo '0')
  research_topics=$(echo "$data" | grep -o '"research_topics":\[.*\]' || echo '[]')
  parallelization_used=$(echo "$data" | grep -o '"parallelization_used":\(true\|false\)' | grep -o '\(true\|false\)' || echo 'false')

  # Construct pattern JSON
  cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "workflow_type": "$WORKFLOW_TYPE",
  "feature_keywords": $feature_keywords,
  "plan_phases": $plan_phases,
  "implementation_time": $implementation_time,
  "test_success_rate": $test_success_rate,
  "error_count": $error_count,
  "research_topics": $research_topics,
  "parallelization_used": $parallelization_used,
  "outcome": "$OUTCOME"
}
EOF
}

# Determine target file based on outcome
determine_target_file() {
  local outcome="$1"

  case "$outcome" in
    success)
      echo "$LEARNING_DIR/patterns.jsonl"
      ;;
    partial|failed)
      echo "$LEARNING_DIR/antipatterns.jsonl"
      ;;
    *)
      echo "ERROR: Unknown outcome: $outcome" >&2
      exit 1
      ;;
  esac
}

# Opt-in confirmation (if enabled)
if [[ "${CLAUDE_LEARNING_OPT_IN:-0}" == "1" ]]; then
  echo "Learning data collection (opt-in mode)"
  echo "Workflow: $WORKFLOW_TYPE ($OUTCOME)"
  echo ""
  echo "Data to collect (privacy filtered):"
  FILTERED_DATA=$(apply_privacy_filters "$DATA_JSON")
  PATTERN_DATA=$(extract_metrics "$FILTERED_DATA")
  echo "$PATTERN_DATA" | head -c 500  # Show first 500 chars
  echo ""
  echo -n "Collect this data? [y/N] "
  read -r confirm

  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Learning data collection cancelled"
    exit 0
  fi
fi

# Apply privacy filters
FILTERED_DATA=$(apply_privacy_filters "$DATA_JSON")

# Extract metrics and construct pattern
PATTERN_DATA=$(extract_metrics "$FILTERED_DATA")

# Determine target file
TARGET_FILE=$(determine_target_file "$OUTCOME")

# Append to appropriate file (JSONL format)
echo "$PATTERN_DATA" >> "$TARGET_FILE"

# Log collection event
LOG_FILE="$LEARNING_DIR/collection.log"
echo "$(date -Iseconds) | $WORKFLOW_TYPE | $OUTCOME | Collected" >> "$LOG_FILE"

echo "Learning data collected: $TARGET_FILE"

# Apply retention policy (delete patterns older than 6 months)
RETENTION_DAYS=180  # 6 months

if [[ -f "$LEARNING_DIR/patterns.jsonl" ]]; then
  # Create temporary file with recent patterns only
  TEMP_FILE=$(mktemp)
  CUTOFF_DATE=$(date -d "180 days ago" -Iseconds 2>/dev/null || date -v-180d -Iseconds 2>/dev/null || echo "")

  if [[ -n "$CUTOFF_DATE" ]]; then
    while IFS= read -r line; do
      TIMESTAMP=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | sed 's/"timestamp":"\(.*\)"/\1/')
      if [[ "$TIMESTAMP" > "$CUTOFF_DATE" ]]; then
        echo "$line" >> "$TEMP_FILE"
      fi
    done < "$LEARNING_DIR/patterns.jsonl"

    # Replace old file with filtered file
    mv "$TEMP_FILE" "$LEARNING_DIR/patterns.jsonl"
  fi
fi

# Same for antipatterns
if [[ -f "$LEARNING_DIR/antipatterns.jsonl" ]]; then
  TEMP_FILE=$(mktemp)
  CUTOFF_DATE=$(date -d "180 days ago" -Iseconds 2>/dev/null || date -v-180d -Iseconds 2>/dev/null || echo "")

  if [[ -n "$CUTOFF_DATE" ]]; then
    while IFS= read -r line; do
      TIMESTAMP=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | sed 's/"timestamp":"\(.*\)"/\1/')
      if [[ "$TIMESTAMP" > "$CUTOFF_DATE" ]]; then
        echo "$line" >> "$TEMP_FILE"
      fi
    done < "$LEARNING_DIR/antipatterns.jsonl"

    mv "$TEMP_FILE" "$LEARNING_DIR/antipatterns.jsonl"
  fi
fi

echo "Retention policy applied (patterns older than $RETENTION_DAYS days removed)"
