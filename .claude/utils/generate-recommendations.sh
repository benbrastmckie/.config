#!/usr/bin/env bash
# Generate workflow recommendations from similar patterns
# Usage: generate-recommendations.sh <similar-patterns-json>

set -euo pipefail

SIMILAR_PATTERNS="${1:?Similar patterns JSON required}"

# Check if any patterns provided
PATTERN_COUNT=$(echo "$SIMILAR_PATTERNS" | grep -o '{' | wc -l)

if [[ $PATTERN_COUNT -eq 0 ]]; then
  echo "No similar workflows found. No recommendations available."
  exit 0
fi

# Extract common research topics
extract_research_topics() {
  local patterns="$1"
  declare -A topic_counts

  # Find all research_topics arrays
  while IFS= read -r topic; do
    [[ -z "$topic" ]] && continue
    # Count occurrences
    count="${topic_counts[$topic]:-0}"
    topic_counts[$topic]=$((count + 1))
  done < <(echo "$patterns" | grep -o '"research_topics":\[.*\]' | tr -d '[]"' | tr ',' '\n' | sed 's/research_topics://g')

  # Sort by count and output top 3
  local sorted_topics=""
  for topic in "${!topic_counts[@]}"; do
    count="${topic_counts[$topic]}"
    sorted_topics+="$count|$topic"$'\n'
  done

  echo "$sorted_topics" | sort -rn | head -3 | cut -d'|' -f2
}

# Calculate average implementation time
calculate_avg_time() {
  local patterns="$1"
  local times=""
  local count=0

  while IFS= read -r time; do
    [[ -z "$time" ]] && continue
    times+="$time "
    ((count++))
  done < <(echo "$patterns" | grep -o '"implementation_time":[0-9]\+' | grep -o '[0-9]\+')

  if [[ $count -eq 0 ]]; then
    echo "0"
    return
  fi

  # Calculate average
  local sum=0
  for time in $times; do
    sum=$((sum + time))
  done

  echo $((sum / count))
}

# Identify parallelization opportunities
check_parallelization() {
  local patterns="$1"

  # Count how many used parallelization
  local parallel_count
  parallel_count=$(echo "$patterns" | grep -c '"parallelization_used":true' || echo "0")

  if [[ $parallel_count -gt 0 ]]; then
    echo "true"
  else
    echo "false"
  fi
}

# Extract successful phase structures
extract_phase_structures() {
  local patterns="$1"

  # Get all phase counts
  local phases=""
  while IFS= read -r phase_count; do
    [[ -z "$phase_count" ]] && continue
    phases+="$phase_count "
  done < <(echo "$patterns" | grep -o '"plan_phases":[0-9]\+' | grep -o '[0-9]\+')

  # Find most common phase count
  echo "$phases" | tr ' ' '\n' | sort | uniq -c | sort -rn | head -1 | awk '{print $2}'
}

# Extract agent selections
extract_agent_recommendations() {
  local patterns="$1"

  # Find agent_selection fields
  echo "$patterns" | grep -o '"agent_selection":{[^}]*}' | head -3
}

# Calculate average similarity score
calculate_avg_similarity() {
  local patterns="$1"
  local scores=""
  local count=0

  while IFS= read -r score; do
    [[ -z "$score" ]] && continue
    scores+="$score "
    ((count++))
  done < <(echo "$patterns" | grep -o '"similarity_score":[0-9.]\+' | grep -o '[0-9.]\+')

  if [[ $count -eq 0 ]]; then
    echo "0.0"
    return
  fi

  # Calculate average (using bc for decimal math)
  local sum="0"
  for score in $scores; do
    sum=$(echo "$sum + $score" | bc -l)
  done

  echo "scale=2; $sum / $count" | bc -l
}

# Generate recommendation report
echo "📊 Learning Recommendation (based on $PATTERN_COUNT similar workflows)"
echo ""

# Similarity score
AVG_SIMILARITY=$(calculate_avg_similarity "$SIMILAR_PATTERNS")
SIMILARITY_PCT=$(echo "scale=0; $AVG_SIMILARITY * 100 / 1" | bc)
echo "Similarity: ${SIMILARITY_PCT}% match to previous workflows"
echo ""

# Research topics
RESEARCH_TOPICS=$(extract_research_topics "$SIMILAR_PATTERNS")
if [[ -n "$RESEARCH_TOPICS" ]]; then
  echo "Research Topics:"
  while IFS= read -r topic; do
    [[ -z "$topic" ]] && continue
    echo "- $topic (used in similar workflows)"
  done <<< "$RESEARCH_TOPICS"
  echo ""
fi

# Plan structure
RECOMMENDED_PHASES=$(extract_phase_structures "$SIMILAR_PATTERNS")
if [[ -n "$RECOMMENDED_PHASES" ]] && [[ "$RECOMMENDED_PHASES" != "0" ]]; then
  echo "Plan Structure:"
  echo "- Recommended phases: $RECOMMENDED_PHASES"
  echo "- Successful pattern: Incremental implementation with testing"

  # Parallelization
  PARALLELIZATION_RECOMMENDED=$(check_parallelization "$SIMILAR_PATTERNS")
  if [[ "$PARALLELIZATION_RECOMMENDED" == "true" ]]; then
    echo "- Parallelization opportunity: Consider parallel phase execution"
  fi
  echo ""
fi

# Time estimate
AVG_TIME=$(calculate_avg_time "$SIMILAR_PATTERNS")
if [[ $AVG_TIME -gt 0 ]]; then
  HOURS=$((AVG_TIME / 3600))
  MINUTES=$(( (AVG_TIME % 3600) / 60 ))

  echo "Time Estimate:"
  echo "- Similar workflows: ${HOURS}h ${MINUTES}min average"
  echo "- Complexity: Medium (based on phase count)"
  echo ""
fi

# Agent recommendations
AGENT_RECOMMENDATIONS=$(extract_agent_recommendations "$SIMILAR_PATTERNS")
if [[ -n "$AGENT_RECOMMENDATIONS" ]]; then
  echo "Agent Selection:"
  echo "- code-writer for implementation phases (recommended)"
  echo "- test-specialist for testing phases (if applicable)"
  echo ""
fi

echo "Apply these recommendations? [y/n]"
