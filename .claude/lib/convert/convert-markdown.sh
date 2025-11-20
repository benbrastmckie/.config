#!/usr/bin/env bash
#
# convert-markdown.sh - Markdown validation and structure analysis utilities
#
# Provides utilities for analyzing and validating Markdown file structure.
#
# Public API:
#   check_structure(md_file) - Analyze markdown structure (headings, tables)
#   report_validation_warnings(output_file, file_type) - Report validation warnings
#
# Dependencies:
#   - validate_output() function (from convert-core.sh)
#

#
# check_structure - Analyze converted Markdown file structure
#
# Arguments:
#   $1 - Markdown file path
#
# Returns: String with structure statistics (e.g., "5 headings, 2 tables")
#
# Counts headings (lines starting with #) and tables (lines starting with |)
#
check_structure() {
  local md_file="$1"

  if [[ ! -f "$md_file" ]]; then
    echo "0 headings, 0 tables"
    return
  fi

  local heading_count
  local table_count

  heading_count=$(grep -c '^#' "$md_file" 2>/dev/null || echo "0")
  table_count=$(grep -c '^\|' "$md_file" 2>/dev/null || echo "0")

  echo "$heading_count headings, $table_count tables"
}

#
# report_validation_warnings - Report warnings for suspicious output
#
# Arguments:
#   $1 - Output file path
#   $2 - File type (md, docx, pdf)
#
# Checks for common issues:
#   - File not created
#   - Very small file size (<100 bytes)
#   - No headings in Markdown output
#
# Prints warning messages to stdout
#
report_validation_warnings() {
  local output_file="$1"
  local file_type="$2"

  if [[ ! -f "$output_file" ]]; then
    echo "    ⚠ Warning: Output file not created"
    return
  fi

  local file_size
  file_size=$(wc -c < "$output_file" 2>/dev/null || echo "0")

  if [[ $file_size -lt 100 ]]; then
    echo "    ⚠ Warning: Output file very small ($file_size bytes)"
  fi

  # Check Markdown structure if applicable
  if [[ "$file_type" == "md" ]]; then
    local structure
    structure=$(check_structure "$output_file")
    local heading_count
    heading_count=$(echo "$structure" | cut -d' ' -f1)

    if [[ $heading_count -eq 0 ]]; then
      echo "    ⚠ Warning: No headings found in Markdown output"
    fi
  fi
}
