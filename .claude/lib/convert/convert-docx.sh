#!/usr/bin/env bash
#
# convert-docx.sh - DOCX conversion utilities
#
# Provides DOCX ↔ Markdown conversion functions using MarkItDown and Pandoc.
#
# Public API:
#   convert_docx(input_file, output_file) - DOCX→MD using MarkItDown
#   convert_docx_pandoc(input_file, output_file) - DOCX→MD using Pandoc
#   convert_md_to_docx(input_file, output_file) - MD→DOCX using Pandoc
#
# Dependencies:
#   - MarkItDown (optional, for DOCX→MD)
#   - Pandoc (optional, for DOCX→MD and MD→DOCX)
#   - with_timeout() function (from convert-core.sh)
#   - TIMEOUT_DOCX_TO_MD, TIMEOUT_MD_TO_DOCX (from convert-core.sh)
#

#
# convert_docx - Convert DOCX to Markdown using MarkItDown
#
# Arguments:
#   $1 - Input DOCX file path
#   $2 - Output Markdown file path
#
# Returns: 0 on success, 1 on failure
#
# Note: Requires with_timeout() and TIMEOUT_DOCX_TO_MD from convert-core.sh
#
convert_docx() {
  local input_file="$1"
  local output_file="$2"

  with_timeout "$TIMEOUT_DOCX_TO_MD" bash -c "markitdown '$input_file' > '$output_file' 2>/dev/null"
  return $?
}

#
# convert_docx_pandoc - Convert DOCX to Markdown using Pandoc
#
# Arguments:
#   $1 - Input DOCX file path
#   $2 - Output Markdown file path
#
# Returns: 0 on success, 1 on failure
#
# Creates an images/ directory for extracted media files
# Note: Requires with_timeout() and TIMEOUT_DOCX_TO_MD from convert-core.sh
#
convert_docx_pandoc() {
  local input_file="$1"
  local output_file="$2"
  local media_dir
  media_dir="$(dirname "$output_file")/images"

  mkdir -p "$media_dir"
  with_timeout "$TIMEOUT_DOCX_TO_MD" pandoc "$input_file" -t gfm --extract-media="$media_dir" --wrap=preserve -o "$output_file" 2>/dev/null
  return $?
}

#
# convert_md_to_docx - Convert Markdown to DOCX using Pandoc
#
# Arguments:
#   $1 - Input Markdown file path
#   $2 - Output DOCX file path
#
# Returns: 0 on success, 1 on failure
#
# Note: Requires with_timeout() and TIMEOUT_MD_TO_DOCX from convert-core.sh
#
convert_md_to_docx() {
  local input_file="$1"
  local output_file="$2"

  with_timeout "$TIMEOUT_MD_TO_DOCX" pandoc "$input_file" -o "$output_file" 2>/dev/null
  return $?
}
