#!/bin/bash
# Scope Detection Library for /coordinate Command
# Provides centralized workflow scope detection logic

# detect_workflow_scope: Determine workflow scope from description
# Args:
#   $1: workflow_description - The workflow description to analyze
# Returns:
#   Prints one of: research-only, research-and-plan, research-and-revise, full-implementation, debug-only
# Usage:
#   WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
detect_workflow_scope() {
  local workflow_description="$1"
  local scope="research-and-plan"  # Default fallback

  # Validation
  if [ -z "$workflow_description" ]; then
    echo "ERROR: detect_workflow_scope: workflow_description parameter is empty" >&2
    echo "research-and-plan"  # Return default on error
    return 1
  fi

  # Order matters: check more specific patterns first
  # Check for research-only pattern (avoids ! in compound condition to prevent history expansion)
  if echo "$workflow_description" | grep -Eiq "^research.*"; then
    if echo "$workflow_description" | grep -Eiq "(plan|implement|fix|debug|create|add|build)"; then
      # Has action keywords - not research-only, will be classified below
      :
    else
      # Pure research with no action keywords
      scope="research-only"
    fi
  fi

  # Check other patterns if not already set to research-only
  if [ "$scope" != "research-only" ]; then
    # Check for research-and-revise pattern (specific before general)
    # Matches: "research X and revise Y", "analyze X to update plan", etc.
    if echo "$workflow_description" | grep -Eiq "(research|analyze).*(and |then |to ).*(revise|update.*plan|modify.*plan)"; then
      scope="research-and-revise"
    elif echo "$workflow_description" | grep -Eiq "(plan|create.*plan|design)"; then
      scope="research-and-plan"
    elif echo "$workflow_description" | grep -Eiq "(fix|debug|troubleshoot)"; then
      scope="debug-only"
    elif echo "$workflow_description" | grep -Eiq "(implement|build|add|create).*feature"; then
      scope="full-implementation"
    fi
  fi

  echo "$scope"
}

export -f detect_workflow_scope
