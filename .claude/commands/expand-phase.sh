#!/usr/bin/env bash
set -euo pipefail

# /expand-phase - Expand Level 0 phase to detailed Level 1 phase file
# Usage: /expand-phase <plan-path> <phase-num>
# Creates enhanced phase files with implementation guidance

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
source "$SCRIPT_DIR/../utils/parse-adaptive-plan.sh"
source "$SCRIPT_DIR/../lib/error-utils.sh"
source "$SCRIPT_DIR/../lib/phase-enhancement.sh"

# Error handling
trap 'echo "Error on line $LINENO" >&2' ERR

# Parse command line arguments
plan_path="${1:-}"
phase_num="${2:-}"

if [[ -z "$plan_path" || -z "$phase_num" ]]; then
  echo "Usage: /expand-phase <plan-path> <phase-num>" >&2
  echo "" >&2
  echo "Example: /expand-phase specs/plans/028_system.md 3" >&2
  exit 1
fi

# Normalize plan path (handle both file and directory paths)
if [[ -d "$plan_path" ]]; then
  # For directory path, find the main plan file
  plan_file="$plan_path/$(basename "$plan_path").md"
  if [[ ! -f "$plan_file" ]]; then
    echo "Error: Plan file not found in directory: $plan_file" >&2
    exit 1
  fi
elif [[ -f "$plan_path" ]]; then
  plan_file="$plan_path"
else
  echo "Error: Invalid plan path: $plan_path" >&2
  exit 1
fi

# Validate plan file exists
if [[ ! -f "$plan_file" ]]; then
  echo "Error: Plan file not found: $plan_file" >&2
  exit 1
fi

# Validate phase number is integer and exists in plan
if ! [[ "$phase_num" =~ ^[0-9]+$ ]]; then
  echo "Error: Phase number must be an integer: $phase_num" >&2
  exit 1
fi

if ! grep -q "^### Phase ${phase_num}:" "$plan_file"; then
  echo "Error: Phase $phase_num not found in plan" >&2
  echo "Available phases:" >&2
  grep "^### Phase " "$plan_file" >&2
  exit 1
fi

# Detect current structure level (use original path before normalization)
current_level=$(detect_structure_level "$plan_path")
echo "Current structure level: $current_level"

# Check if phase already expanded
if [[ $(is_phase_expanded "$plan_path" "$phase_num") == "true" ]]; then
  echo "Warning: Phase $phase_num is already expanded" >&2
  phase_file=$(get_phase_file "$plan_path" "$phase_num")
  echo "Existing file: $phase_file" >&2
  exit 0
fi

# Handle first expansion (Level 0 → 1)
plan_dir=""
if [[ $current_level -eq 0 ]]; then
  echo "First expansion detected (Level 0 → 1)"

  # Create directory structure
  plan_dir="${plan_file%.md}"
  mkdir -p "$plan_dir"
  echo "Created directory: $plan_dir"

  # Move main plan to directory
  mv "$plan_file" "$plan_dir/$(basename "$plan_file")"
  plan_file="$plan_dir/$(basename "$plan_file")"
  echo "Moved plan to: $plan_file"

  # Update structure level metadata
  update_structure_level "$plan_file" 1
fi

# Cleanup on error for Level 0 → 1 transition
cleanup_on_error() {
  if [[ -n "$plan_dir" && -d "$plan_dir" && ! -f "$plan_dir/$(basename "${plan_dir}.md")" ]]; then
    echo "Cleaning up partial expansion..." >&2
    rmdir "$plan_dir" 2>/dev/null || true
  fi
}
trap cleanup_on_error EXIT

# Extract phase content from main plan
echo "Extracting Phase $phase_num content..."
phase_content=$(extract_phase_content "$plan_file" "$phase_num")

if [[ -z "$phase_content" ]]; then
  echo "Error: Could not extract Phase $phase_num" >&2
  exit 1
fi

# Generate phase file name
phase_name=$(extract_phase_name "$plan_file" "$phase_num")
phase_file="$(dirname "$plan_file")/phase_${phase_num}_${phase_name}.md"
echo "Creating phase file: $phase_file"

# Enhance phase content (expands from 30-50 lines to 80-150 lines)
echo "Enhancing phase content..."
enhanced_content=$(enhance_phase_content "$phase_content" "$phase_num" "$(basename "$plan_file")")

# Write enhanced phase content
echo "$enhanced_content" > "$phase_file"

# Add metadata to phase file
add_phase_metadata "$phase_file" "$phase_num" "$(basename "$plan_file")"

# Add update reminder
add_update_reminder "$phase_file" "Phase $phase_num" "$(basename "$plan_file")"

# Replace phase content with summary in main plan
echo "Revising main plan..."
revise_main_plan_for_phase "$plan_file" "$phase_num" "$(basename "$phase_file")"

# Update expanded phases metadata
update_expanded_phases "$plan_file" "$phase_num"

# Check for stage expansion recommendation and update metadata
stage_rec=$(grep "^\*\*Recommendation\*\*:" "$phase_file" 2>/dev/null | head -1 | sed 's/^\*\*Recommendation\*\*: //')
if [[ -n "$stage_rec" ]]; then
  update_stage_candidates "$plan_file" "$phase_num" "$stage_rec"
fi

# Success message
echo ""
echo "✓ Phase $phase_num expanded successfully"
echo "  Main plan: $plan_file"
echo "  Phase file: $phase_file"
echo ""
echo "Next: Edit $phase_file to add detailed implementation guidance"

# Remove error trap
trap - EXIT
