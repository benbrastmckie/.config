#!/usr/bin/env bash
#
# Conversion Logger Library
# Provides structured logging for document conversion operations
#
# Usage:
#   source .claude/lib/conversion-logger.sh
#   init_conversion_log "$OUTPUT_DIR/conversion.log"
#   log_conversion_start "file.docx" "markdown"
#   log_conversion_success "file.docx" "file.md" "markitdown" 1500
#   log_conversion_failure "file.docx" "Error message" "markitdown"
#

set -euo pipefail

# Configuration
CONVERSION_LOG_FILE=""

# Only set readonly variables if not already set
if [[ -z "${CONVERSION_LOG_MAX_SIZE:-}" ]]; then
  readonly CONVERSION_LOG_MAX_SIZE=$((10 * 1024 * 1024))  # 10MB
fi

if [[ -z "${CONVERSION_LOG_MAX_FILES:-}" ]]; then
  readonly CONVERSION_LOG_MAX_FILES=5
fi

#
# init_conversion_log - Initialize conversion log file
#
# Arguments:
#   $1 - Log file path
#   $2 - Input directory (optional)
#   $3 - Output directory (optional)
#
init_conversion_log() {
  CONVERSION_LOG_FILE="$1"
  local input_dir="${2:-}"
  local output_dir="${3:-}"

  # Ensure log directory exists
  mkdir -p "$(dirname "$CONVERSION_LOG_FILE")"

  # Initialize with header
  cat > "$CONVERSION_LOG_FILE" <<EOF
========================================
Document Conversion Log
Started: $(date)
========================================

EOF

  if [[ -n "$input_dir" ]]; then
    echo "Input Directory: $input_dir" >> "$CONVERSION_LOG_FILE"
  fi

  if [[ -n "$output_dir" ]]; then
    echo "Output Directory: $output_dir" >> "$CONVERSION_LOG_FILE"
  fi

  echo "" >> "$CONVERSION_LOG_FILE"
}

#
# rotate_conversion_log_if_needed - Rotate log file if it exceeds max size
#
rotate_conversion_log_if_needed() {
  if [[ ! -f "$CONVERSION_LOG_FILE" ]]; then
    return 0
  fi

  local file_size
  file_size=$(stat -c%s "$CONVERSION_LOG_FILE" 2>/dev/null || stat -f%z "$CONVERSION_LOG_FILE" 2>/dev/null || echo 0)

  if (( file_size >= CONVERSION_LOG_MAX_SIZE )); then
    # Rotate logs: .log -> .log.1, .log.1 -> .log.2, etc.
    for ((i = CONVERSION_LOG_MAX_FILES - 1; i >= 1; i--)); do
      if [[ -f "${CONVERSION_LOG_FILE}.$i" ]]; then
        mv "${CONVERSION_LOG_FILE}.$i" "${CONVERSION_LOG_FILE}.$((i + 1))"
      fi
    done

    # Move current log to .1
    mv "$CONVERSION_LOG_FILE" "${CONVERSION_LOG_FILE}.1"

    # Remove oldest if we exceed max files
    if [[ -f "${CONVERSION_LOG_FILE}.$((CONVERSION_LOG_MAX_FILES + 1))" ]]; then
      rm "${CONVERSION_LOG_FILE}.$((CONVERSION_LOG_MAX_FILES + 1))"
    fi
  fi
}

#
# log_conversion_start - Log the start of a conversion
#
# Arguments:
#   $1 - Input file path
#   $2 - Target format (markdown, docx, pdf)
#
log_conversion_start() {
  local input_file="$1"
  local target_format="$2"

  rotate_conversion_log_if_needed

  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  echo "[$timestamp] START: $(basename "$input_file") -> $target_format" >> "$CONVERSION_LOG_FILE"
}

#
# log_conversion_success - Log a successful conversion
#
# Arguments:
#   $1 - Input file path
#   $2 - Output file path
#   $3 - Tool used (markitdown, pandoc, marker_pdf, pymupdf4llm)
#   $4 - Duration in milliseconds (optional)
#
log_conversion_success() {
  local input_file="$1"
  local output_file="$2"
  local tool_used="$3"
  local duration_ms="${4:-0}"

  rotate_conversion_log_if_needed

  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  local file_size
  if [[ -f "$output_file" ]]; then
    file_size=$(wc -c < "$output_file" 2>/dev/null || echo "0")
  else
    file_size="0"
  fi

  cat >> "$CONVERSION_LOG_FILE" <<EOF
[$timestamp] SUCCESS: $(basename "$input_file")
  Tool: $tool_used
  Output: $(basename "$output_file")
  Size: $file_size bytes
  Duration: ${duration_ms}ms

EOF
}

#
# log_conversion_failure - Log a failed conversion
#
# Arguments:
#   $1 - Input file path
#   $2 - Error message
#   $3 - Tool attempted (optional)
#
log_conversion_failure() {
  local input_file="$1"
  local error_message="$2"
  local tool_attempted="${3:-unknown}"

  rotate_conversion_log_if_needed

  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  cat >> "$CONVERSION_LOG_FILE" <<EOF
[$timestamp] FAILURE: $(basename "$input_file")
  Tool: $tool_attempted
  Error: $error_message

EOF
}

#
# log_conversion_fallback - Log a fallback attempt
#
# Arguments:
#   $1 - Input file path
#   $2 - Primary tool that failed
#   $3 - Fallback tool being tried
#
log_conversion_fallback() {
  local input_file="$1"
  local primary_tool="$2"
  local fallback_tool="$3"

  rotate_conversion_log_if_needed

  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  echo "[$timestamp] FALLBACK: $(basename "$input_file") - $primary_tool failed, trying $fallback_tool" >> "$CONVERSION_LOG_FILE"
}

#
# log_tool_detection - Log tool detection results
#
# Arguments:
#   $1 - Tool name
#   $2 - Available (true/false)
#   $3 - Version (optional)
#
log_tool_detection() {
  local tool_name="$1"
  local available="$2"
  local version="${3:-unknown}"

  rotate_conversion_log_if_needed

  if [[ "$available" == "true" ]]; then
    echo "TOOL DETECTION: $tool_name - AVAILABLE ($version)" >> "$CONVERSION_LOG_FILE"
  else
    echo "TOOL DETECTION: $tool_name - NOT AVAILABLE" >> "$CONVERSION_LOG_FILE"
  fi
}

#
# log_phase_start - Log the start of a conversion phase
#
# Arguments:
#   $1 - Phase name (TOOL DETECTION, CONVERSION, VALIDATION, etc.)
#
log_phase_start() {
  local phase_name="$1"

  rotate_conversion_log_if_needed

  cat >> "$CONVERSION_LOG_FILE" <<EOF

========================================
$phase_name PHASE
========================================

EOF
}

#
# log_phase_end - Log the end of a conversion phase
#
# Arguments:
#   $1 - Phase name
#
log_phase_end() {
  local phase_name="$1"

  rotate_conversion_log_if_needed

  cat >> "$CONVERSION_LOG_FILE" <<EOF
========================================
END: $phase_name PHASE
========================================

EOF
}

#
# log_validation_check - Log a validation check result
#
# Arguments:
#   $1 - File path
#   $2 - Check type (size, structure, magic_number)
#   $3 - Result (pass/fail/warning)
#   $4 - Details
#
log_validation_check() {
  local file_path="$1"
  local check_type="$2"
  local result="$3"
  local details="$4"

  rotate_conversion_log_if_needed

  local symbol
  case "$result" in
    pass) symbol="✓" ;;
    fail) symbol="✗" ;;
    warning) symbol="⚠" ;;
    *) symbol="·" ;;
  esac

  echo "VALIDATION [$symbol $result]: $(basename "$file_path") - $check_type - $details" >> "$CONVERSION_LOG_FILE"
}

#
# log_summary - Log conversion summary statistics
#
# Arguments:
#   $1 - Total files processed
#   $2 - Successful conversions
#   $3 - Failed conversions
#   $4 - Validation failures
#
log_summary() {
  local total="$1"
  local successes="$2"
  local failures="$3"
  local validation_failures="${4:-0}"

  rotate_conversion_log_if_needed

  cat >> "$CONVERSION_LOG_FILE" <<EOF

========================================
CONVERSION SUMMARY
========================================
Total Files Processed: $total
  Successful: $successes
  Failed: $failures
  Validation Failures: $validation_failures

Completed: $(date)
========================================
EOF
}

# Export functions for use in other scripts
export -f init_conversion_log
export -f rotate_conversion_log_if_needed
export -f log_conversion_start
export -f log_conversion_success
export -f log_conversion_failure
export -f log_conversion_fallback
export -f log_tool_detection
export -f log_phase_start
export -f log_phase_end
export -f log_validation_check
export -f log_summary
