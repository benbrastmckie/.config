#!/usr/bin/env bash
# README scaffolding utility
# Generates template-based README.md files with navigation links

set -euo pipefail

# Generate README.md for a directory
# Args: $1 = directory path, $2 = force flag (optional)
generate_readme() {
  local target_dir="$1"
  local force="${2:-false}"
  local readme_file="$target_dir/README.md"

  # Check if directory exists
  if [[ ! -d "$target_dir" ]]; then
    echo "Error: Directory $target_dir does not exist" >&2
    return 1
  fi

  # Check if README already exists
  if [[ -f "$readme_file" ]] && [[ "$force" != "true" ]]; then
    echo "README already exists at $readme_file (use --force to overwrite)"
    return 0
  fi

  # Detect parent directory and parent README
  local parent_dir
  parent_dir=$(dirname "$target_dir")
  local parent_readme=""
  if [[ -f "$parent_dir/README.md" ]] && [[ "$parent_dir" != "$target_dir" ]]; then
    parent_readme="../README.md"
  fi

  # List files in directory (exclude hidden, README itself, common build artifacts)
  local files=()
  while IFS= read -r file; do
    files+=("$file")
  done < <(find "$target_dir" -maxdepth 1 -type f ! -name "README.md" ! -name ".*" ! -name "*.pyc" ! -name "*.o" ! -name "*.so" | sort)

  # List subdirectories (exclude hidden, common build directories)
  local subdirs=()
  while IFS= read -r dir; do
    subdirs+=("$dir")
  done < <(find "$target_dir" -maxdepth 1 -type d ! -path "$target_dir" ! -name ".*" ! -name "__pycache__" ! -name "node_modules" ! -name "dist" ! -name "build" ! -name "target" | sort)

  # Get directory name for title
  local dir_name
  dir_name=$(basename "$target_dir")

  # Generate README content
  {
    echo "# $dir_name"
    echo ""
    echo "[FILL IN: Purpose] - Clear explanation of this directory's role"
    echo ""

    # Contents section (files)
    if [[ ${#files[@]} -gt 0 ]]; then
      echo "## Contents"
      echo ""
      for file in "${files[@]}"; do
        local filename
        filename=$(basename "$file")
        echo "- \`$filename\` - [FILL IN: Description]"
      done
      echo ""
    fi

    # Modules/Components section (subdirectories)
    if [[ ${#subdirs[@]} -gt 0 ]]; then
      echo "## Modules"
      echo ""
      for dir in "${subdirs[@]}"; do
        local dirname
        dirname=$(basename "$dir")
        echo "- [\`$dirname/\`](./$dirname/) - [FILL IN: Description]"
      done
      echo ""
    fi

    # Usage section (conditional)
    if [[ ${#files[@]} -gt 0 ]] && [[ "$dir_name" != "docs" ]] && [[ "$dir_name" != "examples" ]]; then
      echo "## Usage"
      echo ""
      echo "[FILL IN: Code examples or usage instructions]"
      echo ""
    fi

    # Navigation section
    echo "## Navigation"
    echo ""
    if [[ -n "$parent_readme" ]]; then
      echo "- [Parent Directory]($parent_readme)"
    fi
    if [[ ${#subdirs[@]} -gt 0 ]]; then
      echo "- Subdirectories:"
      for dir in "${subdirs[@]}"; do
        local dirname
        dirname=$(basename "$dir")
        echo "  - [\`$dirname/\`](./$dirname/)"
      done
    fi
  } > "$readme_file"

  echo "Generated README at $readme_file"
}

# Find directories without README.md
# Args: $1 = root directory
# Returns: List of directories (one per line)
find_directories_without_readme() {
  local root_dir="${1:-.}"

  if [[ ! -d "$root_dir" ]]; then
    echo "Error: Directory $root_dir does not exist" >&2
    return 1
  fi

  # Find all directories that:
  # 1. Don't have README.md
  # 2. Have at least 2 significant files OR at least 1 subdirectory
  # 3. Exclude common build/cache directories
  find "$root_dir" -type d \
    ! -path "*/\.*" \
    ! -path "*/node_modules/*" \
    ! -path "*/dist/*" \
    ! -path "*/build/*" \
    ! -path "*/target/*" \
    ! -path "*/__pycache__/*" \
    ! -path "*/.pytest_cache/*" \
    2>/dev/null | while read -r dir; do

    # Skip if README exists
    if [[ -f "$dir/README.md" ]]; then
      continue
    fi

    # Count significant files (exclude hidden, build artifacts)
    local file_count
    file_count=$(find "$dir" -maxdepth 1 -type f ! -name ".*" ! -name "*.pyc" ! -name "*.o" 2>/dev/null | wc -l)

    # Count subdirectories (exclude hidden, build dirs)
    local subdir_count
    subdir_count=$(find "$dir" -maxdepth 1 -type d ! -path "$dir" ! -name ".*" ! -name "__pycache__" ! -name "node_modules" 2>/dev/null | wc -l)

    # Include directory if it has ≥2 files OR ≥1 subdirectory
    if [[ $file_count -ge 2 ]] || [[ $subdir_count -ge 1 ]]; then
      echo "$dir"
    fi
  done
}

# Generate READMEs for all eligible directories
# Args: $1 = root directory, $2 = force flag (optional)
generate_all_readmes() {
  local root_dir="${1:-.}"
  local force="${2:-false}"

  echo "Scanning $root_dir for directories without README.md..."
  echo ""

  local dirs_without_readme
  mapfile -t dirs_without_readme < <(find_directories_without_readme "$root_dir")

  if [[ ${#dirs_without_readme[@]} -eq 0 ]]; then
    echo "No directories found that need README.md"
    return 0
  fi

  echo "Found ${#dirs_without_readme[@]} directories without README.md"
  echo ""

  local generated=0
  local skipped=0

  for dir in "${dirs_without_readme[@]}"; do
    if generate_readme "$dir" "$force"; then
      ((generated++))
    else
      ((skipped++))
    fi
  done

  echo ""
  echo "=== Summary ==="
  echo "Generated: $generated READMEs"
  echo "Skipped: $skipped directories"

  # Calculate coverage
  local total_dirs
  total_dirs=$(find "$root_dir" -type d ! -path "*/\.*" ! -path "*/node_modules/*" 2>/dev/null | wc -l)
  local dirs_with_readme
  dirs_with_readme=$(find "$root_dir" -name "README.md" 2>/dev/null | wc -l)
  local coverage
  coverage=$(awk "BEGIN {printf \"%.1f\", ($dirs_with_readme / $total_dirs) * 100}")

  echo "Coverage: $dirs_with_readme/$total_dirs directories ($coverage%)"
}

# Command-line interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  COMMAND=""
  TARGET_DIR="."
  FORCE=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force)
        FORCE=true
        shift
        ;;
      --find)
        COMMAND="find"
        shift
        ;;
      --generate-all)
        COMMAND="generate-all"
        shift
        ;;
      *)
        if [[ -z "$COMMAND" ]]; then
          COMMAND="generate"
        fi
        TARGET_DIR="$1"
        shift
        ;;
    esac
  done

  case "$COMMAND" in
    find)
      find_directories_without_readme "$TARGET_DIR"
      ;;
    generate-all)
      generate_all_readmes "$TARGET_DIR" "$FORCE"
      ;;
    generate|*)
      generate_readme "$TARGET_DIR" "$FORCE"
      ;;
  esac
fi
