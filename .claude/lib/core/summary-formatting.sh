#!/usr/bin/env bash
# summary-formatting.sh - Standardized console summary formatting for artifact-producing commands
#
# Provides print_artifact_summary() function for consistent console output
# following standards from .claude/docs/reference/standards/output-formatting.md
#
# Usage:
#   source "${CLAUDE_LIB}/core/summary-formatting.sh" 2>/dev/null || exit 1
#   print_artifact_summary "command_name" "summary_text" "phases" "artifacts" "next_steps"

# Print standardized console summary for artifact-producing commands
#
# Arguments:
#   $1 - command_name: Display name (e.g., "Research", "Plan", "Build")
#   $2 - summary_text: 2-3 sentence narrative of what/why
#   $3 - phases: Bullet list of phases (empty string to omit section)
#   $4 - artifacts: Emoji-prefixed artifact paths, one per line
#   $5 - next_steps: Bullet list of actionable commands
#
# Returns:
#   0 on success
#   1 on validation failure
#
# Example:
#   print_artifact_summary \
#     "Research" \
#     "Analyzed 15 files and identified 3 strategies. Research provides foundation for secure auth plan." \
#     "" \
#     "📊 Reports: /path/to/reports/ (2 files)" \
#     "• Review reports: cat /path/file.md
#   • Create plan: /plan \"feature description\""
#
print_artifact_summary() {
  local command_name="$1"
  local summary_text="$2"
  local phases="$3"
  local artifacts="$4"
  local next_steps="$5"

  # Validate required parameters
  if [ -z "$command_name" ]; then
    echo "ERROR: print_artifact_summary requires command_name parameter" >&2
    return 1
  fi

  if [ -z "$summary_text" ]; then
    echo "ERROR: print_artifact_summary requires summary_text parameter" >&2
    return 1
  fi

  if [ -z "$artifacts" ]; then
    echo "ERROR: print_artifact_summary requires artifacts parameter" >&2
    return 1
  fi

  if [ -z "$next_steps" ]; then
    echo "ERROR: print_artifact_summary requires next_steps parameter" >&2
    return 1
  fi

  # Print formatted summary
  cat << EOF
=== $command_name Complete ===

Summary: $summary_text

EOF

  # Include Phases section only if provided
  if [ -n "$phases" ]; then
    cat << EOF
Phases:
$phases

EOF
  fi

  # Print Artifacts section
  cat << EOF
Artifacts:
$artifacts

Next Steps:
$next_steps
EOF
}

# Export function for use in commands
export -f print_artifact_summary
