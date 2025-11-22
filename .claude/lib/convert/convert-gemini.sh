#!/usr/bin/env bash
# convert-gemini.sh - Gemini API PDF conversion wrapper
#
# Provides convert_pdf_gemini() function for PDF to Markdown conversion
# using the Gemini API. Falls back gracefully if API unavailable.
#
# Dependencies:
#   - Python 3
#   - google-genai package (pip install google-genai)
#   - GEMINI_API_KEY environment variable
#
# Usage:
#   source convert-gemini.sh
#   convert_pdf_gemini /path/to/input.pdf /path/to/output.md

# Get the directory where this script is located
GEMINI_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#
# convert_pdf_gemini - Convert PDF to Markdown using Gemini API
#
# Arguments:
#   $1 - Input PDF file path
#   $2 - Output Markdown file path
#
# Returns:
#   0 - Success
#   1 - API key not set or conversion failed
#   124 - Timeout (large PDF processing)
#
# The function will timeout after 120 seconds for large PDFs.
# On failure, the caller should fall back to local tools.
#
convert_pdf_gemini() {
  local pdf_path="$1"
  local output_path="$2"

  # Check API key
  if [[ -z "${GEMINI_API_KEY:-}" ]]; then
    return 1
  fi

  # Verify input file exists
  if [[ ! -f "$pdf_path" ]]; then
    echo "Error: PDF file not found: $pdf_path" >&2
    return 1
  fi

  # Determine timeout based on file size
  local file_size_mb
  file_size_mb=$(awk "BEGIN {printf \"%.0f\", $(wc -c < "$pdf_path") / (1024 * 1024)}")
  local timeout_secs=120

  # Increase timeout for larger files (approx 2 min per 50MB)
  if [[ $file_size_mb -gt 50 ]]; then
    timeout_secs=$((file_size_mb * 2 + 60))
    # Cap at 10 minutes
    if [[ $timeout_secs -gt 600 ]]; then
      timeout_secs=600
    fi
  fi

  # Call Python helper with timeout
  if command -v timeout &>/dev/null; then
    timeout "$timeout_secs" python3 "$GEMINI_SCRIPT_DIR/convert_gemini.py" "$pdf_path" > "$output_path" 2>/dev/null
    local exit_code=$?

    if [[ $exit_code -eq 124 ]]; then
      echo "Warning: Gemini conversion timed out after ${timeout_secs}s" >&2
      rm -f "$output_path" 2>/dev/null  # Clean up partial output
      return 124
    fi

    return $exit_code
  else
    # Fallback: run without timeout if timeout command not available
    python3 "$GEMINI_SCRIPT_DIR/convert_gemini.py" "$pdf_path" > "$output_path" 2>/dev/null
    return $?
  fi
}

#
# check_gemini_available - Check if Gemini API is available
#
# Returns:
#   0 - Gemini API is available and configured
#   1 - Gemini API is not available
#
check_gemini_available() {
  # Check API key is set
  if [[ -z "${GEMINI_API_KEY:-}" ]]; then
    return 1
  fi

  # Check google-genai is installed
  if ! python3 -c "from google import genai" 2>/dev/null; then
    return 1
  fi

  return 0
}

# Export functions for use when sourced
export -f convert_pdf_gemini 2>/dev/null || true
export -f check_gemini_available 2>/dev/null || true
