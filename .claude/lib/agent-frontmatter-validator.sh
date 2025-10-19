#!/usr/bin/env bash
# Validate agent behavioral file frontmatter and structure

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base-utils.sh"

# Validate agent frontmatter (if present)
# Args:
#   $1 - Path to agent behavioral file
# Returns:
#   0 if valid, 1 if issues found (warnings only, not errors)
validate_agent_frontmatter() {
  local behavioral_file="$1"
  local warnings=0

  if [[ ! -f "$behavioral_file" ]]; then
    error "Behavioral file not found: $behavioral_file"
    return 1
  fi

  local agent_name
  agent_name=$(basename "$behavioral_file" .md)

  # Check if frontmatter exists
  local has_frontmatter=0
  if head -1 "$behavioral_file" | grep -q "^---$"; then
    has_frontmatter=1
  fi

  if [[ $has_frontmatter -eq 1 ]]; then
    echo "  Checking frontmatter for $agent_name..."

    # Extract frontmatter
    local frontmatter
    frontmatter=$(sed -n '1,/^---$/p' "$behavioral_file" | sed '1d;$d')

    # Check for recommended fields (not required, just warnings)
    local recommended_fields=("description" "allowed-tools")

    for field in "${recommended_fields[@]}"; do
      if ! echo "$frontmatter" | grep -q "^$field:"; then
        echo "    ⚠ Recommended field '$field' not found in frontmatter"
        ((warnings++))
      fi
    done

    # Validate frontmatter is valid YAML-ish (basic check)
    if ! echo "$frontmatter" | grep -q ":"; then
      echo "    ⚠ Frontmatter appears malformed (no key:value pairs found)"
      ((warnings++))
    fi
  else
    echo "  No frontmatter found for $agent_name (optional, using content-based extraction)"
  fi

  # Check for key sections (recommended but not required)
  local recommended_sections=("## " "### ")
  local has_sections=0

  for section_marker in "${recommended_sections[@]}"; do
    if grep -q "^${section_marker}" "$behavioral_file"; then
      has_sections=1
      break
    fi
  done

  if [[ $has_sections -eq 0 ]]; then
    echo "    ⚠ No markdown sections found (recommended for structure)"
    ((warnings++))
  fi

  # Check file size (should have meaningful content)
  local file_size
  file_size=$(wc -l < "$behavioral_file")

  if [[ $file_size -lt 10 ]]; then
    echo "    ⚠ File appears very short ($file_size lines - may need more detail)"
    ((warnings++))
  fi

  if [[ $warnings -eq 0 ]]; then
    echo "    ✓ No issues found"
  else
    echo "    Found $warnings warnings (non-critical)"
  fi

  return 0
}

# Validate all agents in directory
# Args:
#   $1 - Agents directory (optional, defaults to .claude/agents)
# Returns:
#   0 always (warnings don't fail validation)
validate_all_agents() {
  local agents_dir="${1:-.claude/agents}"
  local total_files=0
  local total_warnings=0

  echo "Validating agent behavioral files in $agents_dir..."
  echo ""

  # Find all agent files
  while IFS= read -r behavioral_file; do
    ((total_files++))

    local file_warnings
    file_warnings=$(validate_agent_frontmatter "$behavioral_file" 2>&1 | grep -c "⚠" || true)
    total_warnings=$((total_warnings + file_warnings))

    validate_agent_frontmatter "$behavioral_file"
    echo ""
  done < <(find "$agents_dir" -maxdepth 1 -name "*.md" \
    ! -name "README.md" \
    ! -name "*-usage.md" \
    -type f | sort)

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Validation Summary:"
  echo "  Files checked: $total_files"
  echo "  Total warnings: $total_warnings"
  if [[ $total_warnings -eq 0 ]]; then
    echo "  ✓ All agent files look good!"
  else
    echo "  ⚠ Some agents have minor issues (non-critical)"
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  return 0
}

# Export functions
export -f validate_agent_frontmatter
export -f validate_all_agents

# If run directly, validate all agents
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  agents_dir="${1:-.claude/agents}"
  validate_all_agents "$agents_dir"
fi
