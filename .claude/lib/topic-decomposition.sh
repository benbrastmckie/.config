#!/bin/bash
# .claude/lib/topic-decomposition.sh
# Topic decomposition utility for hierarchical research

decompose_research_topic() {
  local research_topic="$1"
  local min_subtopics="${2:-2}"
  local max_subtopics="${3:-4}"

  # Validate inputs
  if [ -z "$research_topic" ]; then
    echo "ERROR: Research topic is required" >&2
    return 1
  fi

  # Use Task tool to decompose topic into subtopics
  # This leverages LLM to intelligently identify subtopics
  local decomposition_prompt="Analyze this research topic and identify $min_subtopics to $max_subtopics focused subtopics:

Research Topic: $research_topic

Requirements:
1. Each subtopic should be focused and specific (not overly broad)
2. Subtopics should cover different aspects of the main topic
3. Subtopics should be relatively independent (minimal overlap)
4. Return ONLY subtopic names, one per line, no numbering or bullets

Example for 'Authentication patterns and security':
jwt_implementation_patterns
oauth2_flows_and_providers
session_management_strategies
security_best_practices

Output Format (one per line):
subtopic_1_name
subtopic_2_name
subtopic_3_name
..."

  # Execute decomposition (Task tool invocation)
  # Note: In actual implementation, this uses Task tool
  # For utility function, we output the prompt for command to execute
  echo "$decomposition_prompt"
}

validate_subtopic_name() {
  local subtopic="$1"

  # Check snake_case format
  if [[ ! "$subtopic" =~ ^[a-z][a-z0-9_]*$ ]]; then
    echo "ERROR: Subtopic must be snake_case: $subtopic" >&2
    return 1
  fi

  # Check length (max 50 chars)
  if [ ${#subtopic} -gt 50 ]; then
    echo "ERROR: Subtopic name too long (max 50): $subtopic" >&2
    return 1
  fi

  return 0
}

calculate_subtopic_count() {
  local research_topic="$1"
  local word_count=$(echo "$research_topic" | wc -w)

  # Simple heuristic: More words = more subtopics
  # 1-3 words: 2 subtopics
  # 4-6 words: 3 subtopics
  # 7+ words: 4 subtopics

  if [ "$word_count" -le 3 ]; then
    echo 2
  elif [ "$word_count" -le 6 ]; then
    echo 3
  else
    echo 4
  fi
}

# Export functions for use in other scripts
export -f decompose_research_topic
export -f validate_subtopic_name
export -f calculate_subtopic_count
