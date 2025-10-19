#!/usr/bin/env bash
# Structure Validator
# Validates .claude/ directory structure and cross-references

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base-utils.sh"

# Validate cross-references in markdown files
validate_markdown_links() {
  local file="$1"
  local failed=0

  # Find markdown links: [text](path)
  while IFS= read -r link; do
    # Extract path from link
    local path
    path=$(echo "$link" | sed 's/.*(\(.*\)).*/\1/')

    # Skip external URLs
    if [[ "$path" =~ ^https?:// ]]; then
      continue
    fi

    # Resolve relative path
    local dir
    dir=$(dirname "$file")
    local full_path
    full_path=$(cd "$dir" && realpath --relative-to=. "$path" 2>/dev/null || echo "$path")

    # Check if file exists
    if [[ ! -f "$(dirname "$file")/$path" ]] && [[ ! -f "$full_path" ]]; then
      echo "  ✗ Broken link: $path (in $file)"
      ((failed++))
    fi
  done < <(grep -o "\[.*\](.*\.md)" "$file" 2>/dev/null || true)

  return $failed
}

# Validate all markdown files
validate_all_markdown() {
  local base_dir="${1:-.claude}"
  local total_failed=0

  echo "Validating markdown links in $base_dir..."

  while IFS= read -r file; do
    local file_failed
    if ! file_failed=$(validate_markdown_links "$file" 2>&1 | grep -c "✗" || echo "0"); then
      file_failed=0
    fi

    if [[ $file_failed -gt 0 ]]; then
      echo "  File: $file ($file_failed broken links)"
      total_failed=$((total_failed + file_failed))
    fi
  done < <(find "$base_dir" -name "*.md" -type f 2>/dev/null)

  if [[ $total_failed -eq 0 ]]; then
    echo "✓ All markdown links valid"
    return 0
  else
    echo "✗ Found $total_failed broken links"
    return 1
  fi
}

# Validate utility sourcing
validate_utility_sources() {
  local base_dir="${1:-.claude}"
  local failed=0

  echo "Validating utility source statements..."

  while IFS= read -r file; do
    while IFS= read -r source_line; do
      # Extract sourced file
      local sourced
      sourced=$(echo "$source_line" | sed 's/.*source[[:space:]]*"\?//' | sed 's/"\?$//' | sed 's/\${SCRIPT_DIR}/\.claude\/lib/')

      # Check if exists
      if [[ ! -f "$sourced" ]] && [[ ! -f ".claude/lib/$(basename "$sourced")" ]]; then
        echo "  ✗ Missing utility: $sourced (in $file)"
        ((failed++))
      fi
    done < <(grep "^[[:space:]]*source" "$file" 2>/dev/null || true)
  done < <(find "$base_dir" -name "*.sh" -type f 2>/dev/null)

  if [[ $failed -eq 0 ]]; then
    echo "✓ All utility sources valid"
    return 0
  else
    echo "✗ Found $failed missing utilities"
    return 1
  fi
}

# Run all validations
run_all_validations() {
  local base_dir="${1:-.claude}"
  local failed=0

  echo "╔════════════════════════════════════════╗"
  echo "║  .claude/ Structure Validation         ║"
  echo "╚════════════════════════════════════════╝"
  echo ""

  validate_all_markdown "$base_dir" || ((failed++))
  echo ""
  validate_utility_sources "$base_dir" || ((failed++))

  echo ""
  echo "╔════════════════════════════════════════╗"
  echo "║  Validation Results                    ║"
  echo "╚════════════════════════════════════════╝"
  echo ""

  if [[ $failed -eq 0 ]]; then
    echo "✓ All validations passed"
    return 0
  else
    echo "✗ $failed validation(s) failed"
    return 1
  fi
}

# Export functions
export -f validate_markdown_links
export -f validate_all_markdown
export -f validate_utility_sources
export -f run_all_validations

# If run directly, validate everything
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_all_validations
fi
