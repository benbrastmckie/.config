#!/usr/bin/env bash
# Find similar workflows using multi-factor similarity scoring
# Usage: match-similar-workflows.sh <current-workflow-json>

set -euo pipefail

CURRENT_WORKFLOW="${1:?Current workflow JSON required}"
LEARNING_DIR=".claude/learning"
PATTERNS_FILE="$LEARNING_DIR/patterns.jsonl"

# Check if patterns file exists
if [[ ! -f "$PATTERNS_FILE" ]]; then
  echo "[]"  # No patterns available
  exit 0
fi

# Extract current workflow attributes
CURRENT_KEYWORDS=$(echo "$CURRENT_WORKFLOW" | grep -o '"feature_keywords":\[.*\]' | sed 's/"feature_keywords"://' || echo '[]')
CURRENT_TYPE=$(echo "$CURRENT_WORKFLOW" | grep -o '"workflow_type":"[^"]*"' | sed 's/"workflow_type":"\(.*\)"/\1/' || echo '')
CURRENT_PHASES=$(echo "$CURRENT_WORKFLOW" | grep -o '"plan_phases":[0-9]\+' | grep -o '[0-9]\+' || echo '0')

# Calculate Jaccard similarity for keyword sets
jaccard_similarity() {
  local set1="$1"
  local set2="$2"

  # Convert JSON arrays to space-separated words
  local words1
  local words2
  words1=$(echo "$set1" | tr -d '[]"' | tr ',' ' ')
  words2=$(echo "$set2" | tr -d '[]"' | tr ',' ' ')

  # Calculate intersection and union
  local intersection=0
  local union=0

  # Create associative arrays (simplified approach)
  declare -A seen

  # Add all words to union and mark seen
  for word in $words1; do
    seen[$word]=1
    ((union++))
  done

  for word in $words2; do
    if [[ -n "${seen[$word]:-}" ]]; then
      ((intersection++))
    else
      ((union++))
    fi
  done

  # Calculate Jaccard index
  if [[ $union -eq 0 ]]; then
    echo "0.0"
  else
    echo "scale=2; $intersection / $union" | bc -l
  fi
}

# Calculate similarity score for a pattern
calculate_similarity() {
  local pattern="$1"

  # Extract pattern attributes
  local pattern_keywords
  local pattern_type
  local pattern_phases

  pattern_keywords=$(echo "$pattern" | grep -o '"feature_keywords":\[.*\]' | sed 's/"feature_keywords"://' || echo '[]')
  pattern_type=$(echo "$pattern" | grep -o '"workflow_type":"[^"]*"' | sed 's/"workflow_type":"\(.*\)"/\1/' || echo '')
  pattern_phases=$(echo "$pattern" | grep -o '"plan_phases":[0-9]\+' | grep -o '[0-9]\+' || echo '0')

  # Factor 1: Keyword similarity (Jaccard index) - weight 0.6
  local keyword_sim
  keyword_sim=$(jaccard_similarity "$CURRENT_KEYWORDS" "$pattern_keywords")

  # Factor 2: Workflow type match - weight 0.3
  local type_match=0.0
  if [[ "$CURRENT_TYPE" == "$pattern_type" ]]; then
    type_match=1.0
  fi

  # Factor 3: Phase count similarity (±2 tolerance) - weight 0.1
  local phase_match=0.0
  local phase_diff=$((CURRENT_PHASES - pattern_phases))
  phase_diff=${phase_diff#-}  # Absolute value
  if [[ $phase_diff -le 2 ]]; then
    phase_match=1.0
  fi

  # Combined score
  echo "scale=2; ($keyword_sim * 0.6) + ($type_match * 0.3) + ($phase_match * 0.1)" | bc -l
}

# Find all patterns and calculate similarity scores
SIMILARITY_THRESHOLD=0.7  # 70%
MATCHED_PATTERNS="[]"
MATCH_COUNT=0

while IFS= read -r pattern; do
  [[ -z "$pattern" ]] && continue

  # Calculate similarity score
  SCORE=$(calculate_similarity "$pattern")

  # Check if above threshold
  if (( $(echo "$SCORE >= $SIMILARITY_THRESHOLD" | bc -l) )); then
    # Add to matched patterns with score
    PATTERN_WITH_SCORE=$(echo "$pattern" | sed "s/^{/{\"similarity_score\":$SCORE,/")

    if [[ $MATCH_COUNT -eq 0 ]]; then
      MATCHED_PATTERNS="[$PATTERN_WITH_SCORE"
    else
      MATCHED_PATTERNS="$MATCHED_PATTERNS,$PATTERN_WITH_SCORE"
    fi

    ((MATCH_COUNT++))
  fi
done < "$PATTERNS_FILE"

# Close JSON array
if [[ $MATCH_COUNT -gt 0 ]]; then
  MATCHED_PATTERNS="$MATCHED_PATTERNS]"
fi

# Sort by similarity score (descending) and return top 3
echo "$MATCHED_PATTERNS" | head -c 10000  # Limit output size

# Return top 3 matches (simplified - would use jq in production)
# For now, just return all matches (caller can limit)
