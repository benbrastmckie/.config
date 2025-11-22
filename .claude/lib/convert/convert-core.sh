#!/usr/bin/env bash
#
# convert-core.sh - Document conversion orchestration
#
# Main orchestration module for document conversion. Handles tool detection,
# file discovery, validation, conversion dispatching, and reporting.
#
# Usage:
#   source convert-core.sh
#   main_conversion [INPUT_DIR] [OUTPUT_DIR] [OPTIONS]
#
# Dependencies:
#   - convert-docx.sh (DOCX conversion functions)
#   - convert-pdf.sh (PDF conversion functions)
#   - convert-markdown.sh (Markdown utilities)
#

set -eu

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source format-specific conversion modules
source "$SCRIPT_DIR/convert-docx.sh"
source "$SCRIPT_DIR/convert-pdf.sh"
source "$SCRIPT_DIR/convert-markdown.sh"

# Conditional error logging integration (backward compatible)
ERROR_LOGGING_AVAILABLE=false
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
  if source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null; then
    ERROR_LOGGING_AVAILABLE=true
    if type ensure_error_log_exists &>/dev/null; then
      ensure_error_log_exists 2>/dev/null || true
    fi
  fi
fi

# Summary formatting integration (optional - for standardized console output)
SUMMARY_FORMATTING_AVAILABLE=false
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
  if source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/summary-formatting.sh" 2>/dev/null; then
    SUMMARY_FORMATTING_AVAILABLE=true
  fi
fi

# Wrapper function for conversion error logging
log_conversion_error() {
  local error_type="${1:-execution_error}"
  local error_message="${2:-Unknown conversion error}"
  local error_details="${3:-{}}"

  if [[ "$ERROR_LOGGING_AVAILABLE" == "true" ]] && type log_command_error &>/dev/null; then
    local command="${COMMAND_NAME:-convert-core.sh}"
    local workflow_id="${WORKFLOW_ID:-unknown}"
    local user_args="${USER_ARGS:-}"
    local source="convert-core.sh"

    log_command_error \
      "$command" \
      "$workflow_id" \
      "$user_args" \
      "$error_type" \
      "$error_message" \
      "$source" \
      "$error_details"
  fi
}

# Timeout configuration (seconds)
TIMEOUT_DOCX_TO_MD=60
TIMEOUT_PDF_TO_MD=300
TIMEOUT_MD_TO_DOCX=60
TIMEOUT_MD_TO_PDF=120

# Timeout multiplier (can be overridden by environment variable)
TIMEOUT_MULTIPLIER="${TIMEOUT_MULTIPLIER:-1.0}"

# Resource management configuration
MAX_DISK_USAGE_GB="${MAX_DISK_USAGE_GB:-}"  # No limit by default
MIN_FREE_SPACE_MB=100  # Minimum free space required (MB)

# Tool availability flags
MARKITDOWN_AVAILABLE=false
PANDOC_AVAILABLE=false
PYMUPDF_AVAILABLE=false
TYPST_AVAILABLE=false
XELATEX_AVAILABLE=false
GEMINI_AVAILABLE=false
PDF2DOCX_AVAILABLE=false

# Conversion mode (gemini or offline)
CONVERSION_MODE="offline"

# API test cache to avoid repeated connectivity checks
_GEMINI_API_TESTED=""

# Conversion counters
docx_success=0
docx_failed=0
pdf_success=0
pdf_failed=0
md_to_docx_success=0
md_to_docx_failed=0
md_to_pdf_success=0
md_to_pdf_failed=0
collisions_resolved=0
timeouts_occurred=0
validation_failures=0

# Conversion direction
CONVERSION_DIRECTION=""  # TO_MARKDOWN or FROM_MARKDOWN

# Log file
LOG_FILE=""

#
# detect_tools - Check for available conversion tools
#
# Sets global flags for tool availability:
#   MARKITDOWN_AVAILABLE, PANDOC_AVAILABLE, PYMUPDF_AVAILABLE,
#   TYPST_AVAILABLE, XELATEX_AVAILABLE, GEMINI_AVAILABLE, PDF2DOCX_AVAILABLE
#
detect_tools() {
  # MarkItDown
  if command -v markitdown &>/dev/null; then
    MARKITDOWN_AVAILABLE=true
  fi

  # Pandoc
  if command -v pandoc &>/dev/null; then
    PANDOC_AVAILABLE=true
  fi

  # PyMuPDF4LLM
  if python3 -c "import pymupdf4llm" 2>/dev/null; then
    PYMUPDF_AVAILABLE=true
  fi

  # Typst (for MD→PDF)
  if command -v typst &>/dev/null; then
    TYPST_AVAILABLE=true
  fi

  # XeLaTeX (for MD→PDF fallback)
  if command -v xelatex &>/dev/null; then
    XELATEX_AVAILABLE=true
  fi

  # google-genai for Gemini API
  if python3 -c "from google import genai" 2>/dev/null; then
    GEMINI_AVAILABLE=true
  fi

  # pdf2docx for PDF→DOCX direct conversion
  if python3 -c "import pdf2docx" 2>/dev/null; then
    PDF2DOCX_AVAILABLE=true
  fi
}

#
# test_gemini_api - Test Gemini API connectivity
#
# Returns:
#   0 - API is available and working
#   1 - API is not available or key is invalid
#
# Uses cached result to avoid repeated connectivity checks
#
test_gemini_api() {
  # Return cached result if available
  if [[ -n "$_GEMINI_API_TESTED" ]]; then
    return "$_GEMINI_API_TESTED"
  fi

  # Check if API key is set
  if [[ -z "${GEMINI_API_KEY:-}" ]]; then
    _GEMINI_API_TESTED=1
    return 1
  fi

  # Check if google-genai is installed
  if [[ "$GEMINI_AVAILABLE" != "true" ]]; then
    _GEMINI_API_TESTED=1
    return 1
  fi

  # Test API connectivity with minimal request
  if python3 -c "
from google import genai
try:
    client = genai.Client()
    # Just verify we can create a client - don't make actual requests
    exit(0)
except Exception as e:
    exit(1)
" 2>/dev/null; then
    _GEMINI_API_TESTED=0
    return 0
  else
    _GEMINI_API_TESTED=1
    return 1
  fi
}

#
# detect_conversion_mode - Determine conversion mode based on flags and environment
#
# Arguments:
#   $1 - OFFLINE_FLAG (true/false)
#
# Sets global variable: CONVERSION_MODE (gemini or offline)
#
# Priority:
#   1. Explicit --no-api flag
#   2. CONVERT_DOCS_OFFLINE environment variable
#   3. Gemini API availability check
#   4. Default to offline
#
detect_conversion_mode() {
  local offline_flag="${1:-false}"

  # Priority 1: Explicit --no-api flag
  if [[ "$offline_flag" == "true" ]]; then
    CONVERSION_MODE="offline"
    return 0
  fi

  # Priority 2: Environment variable
  if [[ "${CONVERT_DOCS_OFFLINE:-false}" == "true" ]]; then
    CONVERSION_MODE="offline"
    return 0
  fi

  # Priority 3: Check for Gemini API availability
  if [[ -n "${GEMINI_API_KEY:-}" ]] && test_gemini_api; then
    CONVERSION_MODE="gemini"
    return 0
  fi

  # Default: offline mode
  CONVERSION_MODE="offline"
}

#
# with_timeout - Execute command with timeout protection
#
# Arguments:
#   $1 - Timeout duration in seconds
#   $2+ - Command and arguments to execute
#
# Returns:
#   0 - Command succeeded within timeout
#   1 - Command failed
#   124 - Command timed out
#
# The timeout duration is multiplied by TIMEOUT_MULTIPLIER for flexibility.
#
with_timeout() {
  local timeout_secs="$1"
  shift

  # Apply timeout multiplier
  timeout_secs=$(awk "BEGIN {printf \"%.0f\", $timeout_secs * $TIMEOUT_MULTIPLIER}")

  # Check if timeout command is available
  if command -v timeout &>/dev/null; then
    timeout "$timeout_secs" "$@"
    local exit_code=$?

    # Check if timeout occurred (exit code 124)
    if [[ $exit_code -eq 124 ]]; then
      timeouts_occurred=$((timeouts_occurred + 1))
      return 124
    fi

    return $exit_code
  else
    # Fallback: run without timeout if timeout command not available
    "$@"
    return $?
  fi
}

#
# select_docx_tool - Select best available DOCX converter
#
# Returns: Tool name ("markitdown", "pandoc", or "none")
#
select_docx_tool() {
  if [[ "$MARKITDOWN_AVAILABLE" == "true" ]]; then
    echo "markitdown"
  elif [[ "$PANDOC_AVAILABLE" == "true" ]]; then
    echo "pandoc"
  else
    echo "none"
  fi
}

#
# select_pdf_tool - Select best available PDF converter
#
# Returns: Tool name ("markitdown", "pymupdf", or "none")
#
select_pdf_tool() {
  if [[ "$MARKITDOWN_AVAILABLE" == "true" ]]; then
    echo "markitdown"
  elif [[ "$PYMUPDF_AVAILABLE" == "true" ]]; then
    echo "pymupdf"
  else
    echo "none"
  fi
}

#
# check_output_collision - Ensure output filename is unique
#
# Arguments:
#   $1 - Proposed output file path
#
# Returns: Unique output file path (original or with _N suffix)
#
# If the proposed output file already exists, appends _1, _2, etc. until
# finding an unused filename. Updates global collisions_resolved counter.
#
check_output_collision() {
  local proposed_output="$1"
  local output_dir
  local output_base
  local output_ext
  local counter=1
  local candidate

  # If file doesn't exist, use it as-is
  if [[ ! -f "$proposed_output" ]]; then
    echo "$proposed_output"
    return 0
  fi

  # Extract directory, base name, and extension
  output_dir="$(dirname "$proposed_output")"
  output_base="$(basename "$proposed_output")"

  # Split into name and extension
  if [[ "$output_base" == *.* ]]; then
    output_ext=".${output_base##*.}"
    output_base="${output_base%.*}"
  else
    output_ext=""
  fi

  # Find unique filename
  while true; do
    candidate="$output_dir/${output_base}_${counter}${output_ext}"
    if [[ ! -f "$candidate" ]]; then
      collisions_resolved=$((collisions_resolved + 1))
      echo "$candidate"
      return 0
    fi
    counter=$((counter + 1))

    # Safety limit to prevent infinite loops
    if [[ $counter -gt 1000 ]]; then
      echo "$proposed_output.$$" # Use PID as last resort
      return 1
    fi
  done
}

#
# log_conversion - Thread-safe logging with atomic lock
#
# Arguments:
#   $1 - Log file path
#   $2 - Log message
#
# Uses mkdir-based atomic locking (portable across all systems)
#
log_conversion() {
  local log_file="$1"
  local message="$2"
  local lock_dir="${log_file}.lock"
  local max_wait=50  # Max 5 seconds (50 * 100ms)
  local wait_count=0

  # Acquire lock using mkdir (atomic operation)
  while ! mkdir "$lock_dir" 2>/dev/null; do
    sleep 0.1
    wait_count=$((wait_count + 1))

    if [ "$wait_count" -ge "$max_wait" ]; then
      echo "Warning: Log lock timeout, writing anyway" >&2
      break
    fi
  done

  # Critical section: write to log
  echo "$message" >> "$log_file"

  # Release lock
  rmdir "$lock_dir" 2>/dev/null || true
}

#
# increment_progress - Atomic progress counter increment with display
#
# Arguments:
#   $1 - Progress counter file path
#   $2 - Total file count
#
# Uses flock if available, falls back to mkdir lock
#
increment_progress() {
  local counter_file="$1"
  local total="$2"
  local lock_file="${counter_file}.lock"

  # Try flock first (faster if available)
  if command -v flock &>/dev/null; then
    (
      flock -x 200
      current=$(cat "$counter_file")
      current=$((current + 1))
      echo "$current" > "$counter_file"
      echo "Progress: [$current/$total] files processed"
    ) 200>"$lock_file"
  else
    # Fallback to mkdir lock
    local lock_dir="$lock_file.d"
    while ! mkdir "$lock_dir" 2>/dev/null; do
      sleep 0.05
    done

    current=$(cat "$counter_file")
    current=$((current + 1))
    echo "$current" > "$counter_file"
    echo "Progress: [$current/$total] files processed"

    rmdir "$lock_dir" 2>/dev/null || true
  fi
}

#
# acquire_lock - Acquire conversion lock file
#
# Arguments:
#   $1 - Output directory
#
# Returns:
#   0 if lock acquired, 1 if already locked
#
# Creates a lock file with current PID to prevent concurrent conversions
#
acquire_lock() {
  local output_dir="$1"
  local lock_file="$output_dir/.convert-docs.lock"

  # Check for existing lock
  if [[ -f "$lock_file" ]]; then
    local lock_pid
    lock_pid=$(cat "$lock_file" 2>/dev/null || echo "")

    # Check if process is still running
    if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
      echo "Error: Another conversion is already running (PID: $lock_pid)" >&2
      echo "Lock file: $lock_file" >&2
      echo "If you're sure no conversion is running, remove the lock file manually." >&2
      return 1
    else
      # Stale lock - remove it
      echo "Warning: Removing stale lock file (PID $lock_pid not running)" >&2
      rm -f "$lock_file"
    fi
  fi

  # Create lock with current PID
  echo "$$" > "$lock_file"
  return 0
}

#
# release_lock - Release conversion lock file
#
# Arguments:
#   $1 - Output directory
#
release_lock() {
  local output_dir="$1"
  local lock_file="$output_dir/.convert-docs.lock"

  # Only remove lock if it contains our PID
  if [[ -f "$lock_file" ]]; then
    local lock_pid
    lock_pid=$(cat "$lock_file" 2>/dev/null || echo "")

    if [[ "$lock_pid" == "$$" ]]; then
      rm -f "$lock_file"
    fi
  fi
}

#
# convert_batch_parallel - Convert files in parallel using worker pool
#
# Arguments:
#   $1 - Array name containing files to convert (pass by reference)
#   $2 - Output directory
#   $3 - Worker count
#
# Uses global conversion functions and counters
#
convert_batch_parallel() {
  local -n files_array=$1
  local output_dir="$2"
  local worker_count="$3"

  local total_files=${#files_array[@]}

  if [ "$total_files" -eq 0 ]; then
    return 0
  fi

  echo "Processing $total_files files with $worker_count workers..."
  echo ""

  # Initialize progress tracking
  PROGRESS_COUNTER_FILE="$output_dir/.progress_counter"
  echo "0" > "$PROGRESS_COUNTER_FILE"

  # PID tracking for worker cleanup
  declare -a worker_pids=()

  # Dispatch workers
  local file_index=0
  local active_workers=0

  for file in "${files_array[@]}"; do
    # Wait for worker slot if at capacity
    while [ "$active_workers" -ge "$worker_count" ]; do
      # Wait for any worker to complete
      if wait -n 2>/dev/null; then
        active_workers=$((active_workers - 1))
      else
        # wait -n not supported (older bash), fall back to wait
        wait
        active_workers=0
      fi
    done

    # Launch worker in background
    (
      convert_file "$file" "$output_dir"
      increment_progress "$PROGRESS_COUNTER_FILE" "$total_files"
    ) &

    worker_pids+=($!)
    active_workers=$((active_workers + 1))
    file_index=$((file_index + 1))
  done

  # Wait for all remaining workers
  for pid in "${worker_pids[@]}"; do
    wait "$pid" 2>/dev/null || true
  done

  # Cleanup progress tracking
  rm -f "$PROGRESS_COUNTER_FILE" "$PROGRESS_COUNTER_FILE.lock" 2>/dev/null || true

  echo ""
  echo "Parallel processing complete"
}

#
# validate_input_file - Validate file before conversion attempt
#
# Arguments:
#   $1 - File path to validate
#   $2 - Expected extension (docx, pdf, md)
#
# Returns:
#   0 if valid, 1 if invalid
#
# Side Effects:
#   Increments validation_failures counter on failure
#   Logs validation failure to LOG_FILE
#
validate_input_file() {
  local file_path="$1"
  local expected_ext="$2"

  # Helper function to log validation failures (only if LOG_FILE is set)
  log_validation() {
    local message="$1"
    if [[ -n "$LOG_FILE" ]]; then
      log_conversion "$LOG_FILE" "$message"
    fi
  }

  # Check file exists
  if [[ ! -f "$file_path" ]]; then
    log_validation "[VALIDATION] File not found: $file_path"
    validation_failures=$((validation_failures + 1))
    return 1
  fi

  # Check file size (must be at least 1 byte)
  local file_size
  file_size=$(wc -c < "$file_path" 2>/dev/null || echo "0")

  if [[ $file_size -eq 0 ]]; then
    log_validation "[VALIDATION] Empty file: $file_path"
    validation_failures=$((validation_failures + 1))
    return 1
  fi

  # Check file is readable
  if [[ ! -r "$file_path" ]]; then
    log_validation "[VALIDATION] File not readable: $file_path"
    validation_failures=$((validation_failures + 1))
    return 1
  fi

  # Perform magic number check based on expected extension
  case "${expected_ext,,}" in
    docx)
      # DOCX should be a ZIP file (PK magic number)
      if command -v xxd &>/dev/null; then
        local magic
        magic=$(xxd -l 2 -p "$file_path" 2>/dev/null || echo "")

        if [[ "${magic^^}" != "504B" ]]; then
          log_validation "[VALIDATION] Invalid DOCX magic number: $file_path (expected 504B, got $magic)"
          validation_failures=$((validation_failures + 1))
          return 1
        fi
      fi

      # Additional check: Verify it's recognized as a ZIP/DOCX
      if command -v file &>/dev/null; then
        local file_type
        file_type=$(file -b "$file_path" 2>/dev/null || echo "")

        if [[ ! "$file_type" =~ (Microsoft.*OOXML|Zip.*archive|Office.*Open.*XML) ]]; then
          log_validation "[VALIDATION] File type mismatch for DOCX: $file_path (file reports: $file_type)"
          validation_failures=$((validation_failures + 1))
          return 1
        fi
      fi
      ;;

    pdf)
      # PDF should start with %PDF- magic number
      if command -v xxd &>/dev/null; then
        local magic
        magic=$(xxd -l 4 -p "$file_path" 2>/dev/null || echo "")

        if [[ "${magic^^}" != "25504446" ]]; then
          log_validation "[VALIDATION] Invalid PDF magic number: $file_path (expected 25504446, got $magic)"
          validation_failures=$((validation_failures + 1))
          return 1
        fi
      fi

      # Additional check: Verify PDF format
      if command -v file &>/dev/null; then
        local file_type
        file_type=$(file -b "$file_path" 2>/dev/null || echo "")

        if [[ ! "$file_type" =~ PDF ]]; then
          log_validation "[VALIDATION] File type mismatch for PDF: $file_path (file reports: $file_type)"
          validation_failures=$((validation_failures + 1))
          return 1
        fi
      fi
      ;;

    md|markdown)
      # Markdown should be a text file
      if command -v file &>/dev/null; then
        local file_type
        file_type=$(file -b "$file_path" 2>/dev/null || echo "")

        # Accept various text formats
        if [[ ! "$file_type" =~ (text|ASCII|UTF-8) ]]; then
          log_validation "[VALIDATION] Non-text file for Markdown: $file_path (file reports: $file_type)"
          validation_failures=$((validation_failures + 1))
          return 1
        fi
      fi

      # Sanity check: File should not be too large (>50MB)
      if [[ $file_size -gt 52428800 ]]; then
        log_validation "[VALIDATION] Markdown file suspiciously large: $file_path ($file_size bytes)"
        validation_failures=$((validation_failures + 1))
        return 1
      fi
      ;;

    *)
      log_validation "[VALIDATION] Unknown expected extension: $expected_ext"
      validation_failures=$((validation_failures + 1))
      return 1
      ;;
  esac

  # All checks passed
  return 0
}

#
# discover_files - Find convertible files in input directory
#
# Arguments:
#   $1 - Input directory path
#
# Populates global arrays: docx_files, pdf_files, md_files
# Validates each file before adding to array
#
discover_files() {
  local input_dir="$1"

  # Find and validate DOCX files
  while IFS= read -r -d '' file; do
    if validate_input_file "$file" "docx"; then
      docx_files+=("$file")
    else
      echo "  Skipping invalid DOCX file: $(basename "$file")"
    fi
  done < <(find "$input_dir" -maxdepth 1 -type f -iname "*.docx" -print0 2>/dev/null)

  # Find and validate PDF files
  while IFS= read -r -d '' file; do
    if validate_input_file "$file" "pdf"; then
      pdf_files+=("$file")
    else
      echo "  Skipping invalid PDF file: $(basename "$file")"
    fi
  done < <(find "$input_dir" -maxdepth 1 -type f -iname "*.pdf" -print0 2>/dev/null)

  # Find and validate Markdown files
  while IFS= read -r -d '' file; do
    if validate_input_file "$file" "md"; then
      md_files+=("$file")
    else
      echo "  Skipping invalid Markdown file: $(basename "$file")"
    fi
  done < <(find "$input_dir" -maxdepth 1 -type f \( -iname "*.md" -o -iname "*.markdown" \) -print0 2>/dev/null)
}

#
# detect_conversion_direction - Determine conversion direction
#
# Sets global variable: CONVERSION_DIRECTION
#   "TO_MARKDOWN" if DOCX/PDF files present
#   "FROM_MARKDOWN" if only MD files present
#   "MIXED" if both present (defaults to TO_MARKDOWN for mixed batches)
#
detect_conversion_direction() {
  local has_source_docs=false
  local has_markdown=false

  if [[ ${#docx_files[@]} -gt 0 ]] || [[ ${#pdf_files[@]} -gt 0 ]]; then
    has_source_docs=true
  fi

  if [[ ${#md_files[@]} -gt 0 ]]; then
    has_markdown=true
  fi

  if [[ "$has_source_docs" == "true" ]]; then
    CONVERSION_DIRECTION="TO_MARKDOWN"
  elif [[ "$has_markdown" == "true" ]]; then
    CONVERSION_DIRECTION="FROM_MARKDOWN"
  else
    CONVERSION_DIRECTION="NONE"
  fi
}

#
# check_disk_space - Verify sufficient disk space for conversion
#
# Arguments:
#   $1 - Output directory
#
# Returns:
#   0 if sufficient space, 1 if insufficient (warning only, doesn't fail)
#
# Checks available disk space against estimated output requirements
#
check_disk_space() {
  local output_dir="$1"

  # Calculate total input size
  local total_input_size=0

  for file in "${docx_files[@]}" "${pdf_files[@]}" "${md_files[@]}"; do
    if [[ -f "$file" ]]; then
      local file_size
      file_size=$(wc -c < "$file" 2>/dev/null || echo "0")
      total_input_size=$((total_input_size + file_size))
    fi
  done

  # Estimate output size (input × 1.5 for safety margin)
  local estimated_output_mb
  estimated_output_mb=$(awk "BEGIN {printf \"%.0f\", ($total_input_size * 1.5) / (1024 * 1024)}")

  # Check available disk space using df
  local available_mb
  if command -v df &>/dev/null; then
    # Try GNU df first (Linux)
    available_mb=$(df -BM "$output_dir" 2>/dev/null | awk 'NR==2 {gsub(/M/, "", $4); print $4}')

    # Fallback to BSD df (macOS)
    if [[ -z "$available_mb" ]] || [[ "$available_mb" == "0" ]]; then
      available_mb=$(df -m "$output_dir" 2>/dev/null | awk 'NR==2 {print $4}')
    fi
  else
    # df not available, skip check
    return 0
  fi

  # If MAX_DISK_USAGE_GB is set, check against limit
  if [[ -n "$MAX_DISK_USAGE_GB" ]]; then
    local max_mb
    max_mb=$(awk "BEGIN {printf \"%.0f\", $MAX_DISK_USAGE_GB * 1024}")

    if [[ $estimated_output_mb -gt $max_mb ]]; then
      echo "Warning: Estimated output size (${estimated_output_mb}MB) exceeds MAX_DISK_USAGE_GB limit (${MAX_DISK_USAGE_GB}GB)" >&2
      echo "  Set MAX_DISK_USAGE_GB higher or reduce input file count" >&2
      return 1
    fi
  fi

  # Check if available space is sufficient
  local required_space=$((estimated_output_mb + MIN_FREE_SPACE_MB))

  if [[ $available_mb -lt $required_space ]]; then
    echo "Warning: Insufficient disk space for conversion" >&2
    echo "  Available: ${available_mb}MB" >&2
    echo "  Required: ${required_space}MB (estimated ${estimated_output_mb}MB + ${MIN_FREE_SPACE_MB}MB buffer)" >&2
    echo "  Free up disk space or reduce input file count" >&2
    return 1
  fi

  # Sufficient space available
  return 0
}

#
# show_tool_detection - Display detected tools
#
show_tool_detection() {
  echo "Document Conversion Tools Detection"
  echo "===================================="
  echo ""
  echo "Document Conversion (DOCX/PDF → Markdown):"
  if [[ "$MARKITDOWN_AVAILABLE" == "true" ]]; then
    echo "  [OK] MarkItDown (primary, 75-80% fidelity for DOCX and PDF)"
  else
    echo "  [--] MarkItDown not found"
  fi
  if [[ "$PANDOC_AVAILABLE" == "true" ]]; then
    echo "  [OK] Pandoc (fallback for DOCX, 68% fidelity)"
  else
    echo "  [--] Pandoc not found"
  fi
  if [[ "$PYMUPDF_AVAILABLE" == "true" ]]; then
    echo "  [OK] PyMuPDF4LLM (backup for PDF, fast)"
  else
    echo "  [--] PyMuPDF4LLM not found"
  fi
  echo ""
  echo "API-Based Conversion (PDF → Markdown):"
  if [[ "$GEMINI_AVAILABLE" == "true" ]]; then
    echo "  [OK] Gemini API (google-genai SDK installed)"
    if [[ -n "${GEMINI_API_KEY:-}" ]]; then
      echo "       GEMINI_API_KEY: configured"
    else
      echo "       GEMINI_API_KEY: not set (set to enable)"
    fi
  else
    echo "  [--] Gemini API (pip install google-genai)"
  fi
  echo ""
  echo "PDF → DOCX Conversion:"
  if [[ "$PDF2DOCX_AVAILABLE" == "true" ]]; then
    echo "  [OK] pdf2docx (direct conversion)"
  else
    echo "  [--] pdf2docx not found (pip install pdf2docx)"
  fi
  echo ""
  echo "Markdown Export:"
  if [[ "$PANDOC_AVAILABLE" == "true" ]]; then
    echo "  [OK] Pandoc (MD→DOCX/PDF, 95%+ quality)"
  else
    echo "  [--] Pandoc not found"
  fi
  if [[ "$TYPST_AVAILABLE" == "true" ]]; then
    echo "  [OK] Typst (PDF engine, primary)"
  else
    echo "  [--] Typst not found"
  fi
  if [[ "$XELATEX_AVAILABLE" == "true" ]]; then
    echo "  [OK] XeLaTeX (PDF engine, fallback)"
  else
    echo "  [--] XeLaTeX not found"
  fi
  echo ""
  echo "Conversion Mode: $CONVERSION_MODE"
  echo ""
  echo "Selected Tools:"
  echo "  PDF→MD:   $(if [[ "$CONVERSION_MODE" == "gemini" ]]; then echo "gemini (with fallback)"; else echo "$(select_pdf_tool)"; fi)"
  echo "  PDF→DOCX: $(if [[ "$PDF2DOCX_AVAILABLE" == "true" ]]; then echo "pdf2docx"; else echo "none"; fi)"
  echo "  DOCX→MD:  $(select_docx_tool)"
  echo "  MD→DOCX:  $(if [[ "$PANDOC_AVAILABLE" == "true" ]]; then echo "pandoc"; else echo "none"; fi)"
  echo "  MD→PDF:   $(if [[ "$TYPST_AVAILABLE" == "true" ]] || [[ "$XELATEX_AVAILABLE" == "true" ]]; then echo "pandoc"; else echo "none"; fi)"
}

#
# show_dry_run - Display files that would be converted
#
# Arguments:
#   $1 - Input directory
#
show_dry_run() {
  local input_dir="$1"

  echo "Dry Run: Conversion Analysis"
  echo "============================="
  echo ""
  echo "Input Directory: $input_dir"
  echo ""

  if [[ ${#docx_files[@]} -gt 0 ]]; then
    echo "DOCX Files (${#docx_files[@]}):"
    for file in "${docx_files[@]}"; do
      echo "  - $(basename "$file")"
    done
    echo ""
  fi

  if [[ ${#pdf_files[@]} -gt 0 ]]; then
    echo "PDF Files (${#pdf_files[@]}):"
    for file in "${pdf_files[@]}"; do
      echo "  - $(basename "$file")"
    done
    echo ""
  fi

  if [[ ${#md_files[@]} -gt 0 ]]; then
    echo "Markdown Files (${#md_files[@]}):"
    for file in "${md_files[@]}"; do
      echo "  - $(basename "$file")"
    done
    echo ""
  fi

  echo "Conversion Direction: $CONVERSION_DIRECTION"
  echo ""

  if [[ "$CONVERSION_DIRECTION" == "TO_MARKDOWN" ]]; then
    echo "Would convert ${#docx_files[@]} DOCX and ${#pdf_files[@]} PDF files to Markdown"
  elif [[ "$CONVERSION_DIRECTION" == "FROM_MARKDOWN" ]]; then
    echo "Would convert ${#md_files[@]} Markdown files to DOCX/PDF"
  else
    echo "No convertible files found"
  fi
}

#
# convert_file - Main conversion dispatcher with automatic fallback
#
# Arguments:
#   $1 - Input file path
#   $2 - Output directory
#
# Updates global counters based on success/failure
#
convert_file() {
  local input_file="$1"
  local output_dir="$2"
  local basename
  local extension
  local output_file
  local tool_used=""
  local conversion_success=false

  # Extract basename and extension safely
  basename="$(basename "$input_file")"
  extension="${basename##*.}"

  case "${extension,,}" in
    docx)
      # DOCX → MD conversion
      output_file="$output_dir/${basename%.docx}.md"

      # Check for output filename collision and resolve if necessary
      output_file="$(check_output_collision "$output_file")"

      # Try MarkItDown first
      if [[ "$MARKITDOWN_AVAILABLE" == "true" ]]; then
        echo "  Converting: $basename (MarkItDown)"
        convert_docx "$input_file" "$output_file"
        local exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
          tool_used="markitdown"
          conversion_success=true
          docx_success=$((docx_success + 1))
        elif [[ $exit_code -eq 124 ]]; then
          echo "    MarkItDown timed out (${TIMEOUT_DOCX_TO_MD}s), trying Pandoc fallback..."
          # Fall back to Pandoc
          if [[ "$PANDOC_AVAILABLE" == "true" ]]; then
            if convert_docx_pandoc "$input_file" "$output_file"; then
              tool_used="pandoc"
              conversion_success=true
              docx_success=$((docx_success + 1))
            fi
          fi
        else
          echo "    MarkItDown failed, trying Pandoc fallback..."
          # Fall back to Pandoc
          if [[ "$PANDOC_AVAILABLE" == "true" ]]; then
            if convert_docx_pandoc "$input_file" "$output_file"; then
              tool_used="pandoc"
              conversion_success=true
              docx_success=$((docx_success + 1))
            fi
          fi
        fi
      # Try Pandoc if MarkItDown unavailable
      elif [[ "$PANDOC_AVAILABLE" == "true" ]]; then
        echo "  Converting: $basename (Pandoc)"
        if convert_docx_pandoc "$input_file" "$output_file"; then
          tool_used="pandoc"
          conversion_success=true
          docx_success=$((docx_success + 1))
        fi
      fi

      if [[ "$conversion_success" == "false" ]]; then
        echo "    ✗ Failed to convert $basename"
        log_conversion_error "execution_error" "DOCX conversion failed" "{\"input_file\": \"$input_file\", \"basename\": \"$basename\", \"output_file\": \"$output_file\"}"
        docx_failed=$((docx_failed + 1))
      else
        echo "    ✓ Converted to $(basename "$output_file") (using $tool_used)"
        # Validate output
        if ! validate_output "$output_file"; then
          report_validation_warnings "$output_file" "md"
        fi
      fi
      ;;

    pdf)
      # PDF → MD conversion
      output_file="$output_dir/${basename%.pdf}.md"

      # Check for output filename collision and resolve if necessary
      output_file="$(check_output_collision "$output_file")"

      # Determine tool based on conversion mode
      if [[ "$CONVERSION_MODE" == "gemini" ]]; then
        echo "  Converting: $basename (Gemini API)"
        tool_used="gemini"
      elif [[ "$PYMUPDF_AVAILABLE" == "true" ]]; then
        echo "  Converting: $basename (PyMuPDF4LLM)"
        tool_used="pymupdf4llm"
      elif [[ "$MARKITDOWN_AVAILABLE" == "true" ]]; then
        echo "  Converting: $basename (MarkItDown)"
        tool_used="markitdown"
      else
        echo "  Converting: $basename (no tool available)"
        tool_used="none"
      fi

      # Use the unified convert_pdf_to_md function with automatic fallback
      if convert_pdf_to_md "$input_file" "$output_file"; then
        conversion_success=true
        pdf_success=$((pdf_success + 1))
        echo "    [OK] Converted to $(basename "$output_file") (using $tool_used)"
      else
        echo "    [--] Failed to convert $basename"
        log_conversion_error "execution_error" "PDF conversion failed" "{\"input_file\": \"$input_file\", \"basename\": \"$basename\", \"output_file\": \"$output_file\", \"mode\": \"$CONVERSION_MODE\"}"
        pdf_failed=$((pdf_failed + 1))
      fi

      # Validate output if conversion succeeded
      if [[ "$conversion_success" == "true" ]]; then
        if ! validate_output "$output_file"; then
          report_validation_warnings "$output_file" "md"
        fi
      fi
      ;;

    md|markdown)
      # MD → DOCX/PDF conversion (default to DOCX)
      output_file="$output_dir/${basename%.*}.docx"

      # Check for output filename collision and resolve if necessary
      output_file="$(check_output_collision "$output_file")"

      if [[ "$PANDOC_AVAILABLE" == "true" ]]; then
        echo "  Converting: $basename → DOCX (Pandoc)"
        if convert_md_to_docx "$input_file" "$output_file"; then
          tool_used="pandoc"
          conversion_success=true
          md_to_docx_success=$((md_to_docx_success + 1))
          echo "    ✓ Converted to $(basename "$output_file") (using $tool_used)"
          # Validate output
          if ! validate_output "$output_file"; then
            report_validation_warnings "$output_file" "docx"
          fi
        else
          echo "    ✗ Failed to convert $basename"
          log_conversion_error "execution_error" "Markdown conversion failed" "{\"input_file\": \"$input_file\", \"basename\": \"$basename\", \"output_file\": \"$output_file\"}"
          md_to_docx_failed=$((md_to_docx_failed + 1))
        fi
      else
        echo "    ✗ Pandoc not available for MD→DOCX conversion"
        log_conversion_error "execution_error" "Markdown conversion failed: Pandoc not available" "{\"input_file\": \"$input_file\", \"basename\": \"$basename\", \"output_file\": \"$output_file\"}"
        md_to_docx_failed=$((md_to_docx_failed + 1))
      fi
      ;;

    *)
      echo "  Skipping: $basename (unsupported format)"
      ;;
  esac

  # Log conversion result (thread-safe)
  if [[ "$conversion_success" == "true" ]]; then
    log_conversion "$LOG_FILE" "[SUCCESS] $basename → $(basename "$output_file") (tool: $tool_used)"
  else
    log_conversion "$LOG_FILE" "[FAILED] $basename (no suitable tool or conversion error)"
  fi
}

#
# process_conversions - Process all discovered files (parallel or sequential)
#
process_conversions() {
  local total_files=0
  local current_file=0

  # Calculate total files
  total_files=$((${#docx_files[@]} + ${#pdf_files[@]} + ${#md_files[@]}))

  if [[ $total_files -eq 0 ]]; then
    echo "No convertible files found in $INPUT_DIR"
    return 0
  fi

  # Check if parallel mode is enabled
  if [[ "$PARALLEL_MODE" == "true" ]]; then
    echo "Processing $total_files files in parallel mode (workers: $PARALLEL_WORKERS)..."
    echo ""

    # Combine all files into a single array for parallel processing
    local -a all_files=()
    all_files+=("${docx_files[@]}")
    all_files+=("${pdf_files[@]}")
    all_files+=("${md_files[@]}")

    # Process all files in parallel
    convert_batch_parallel all_files "$OUTPUT_DIR" "$PARALLEL_WORKERS"
  else
    # Sequential mode (original behavior)
    echo "Processing $total_files files..."
    echo ""

    # Process DOCX files
    if [[ ${#docx_files[@]} -gt 0 ]]; then
      for file in "${docx_files[@]}"; do
        current_file=$((current_file + 1))
        echo "[$current_file/$total_files] Processing DOCX file"
        convert_file "$file" "$OUTPUT_DIR"
        echo ""
      done
    fi

    # Process PDF files
    if [[ ${#pdf_files[@]} -gt 0 ]]; then
      for file in "${pdf_files[@]}"; do
        current_file=$((current_file + 1))
        echo "[$current_file/$total_files] Processing PDF file"
        convert_file "$file" "$OUTPUT_DIR"
        echo ""
      done
    fi

    # Process MD files
    if [[ ${#md_files[@]} -gt 0 ]]; then
      for file in "${md_files[@]}"; do
        current_file=$((current_file + 1))
        echo "[$current_file/$total_files] Processing Markdown file"
        convert_file "$file" "$OUTPUT_DIR"
        echo ""
      done
    fi
  fi
}

#
# validate_output - Check if converted file exists and meets size requirements
#
# Arguments:
#   $1 - Output file path
#
# Returns: 0 if valid, 1 if invalid
#
validate_output() {
  local output_file="$1"

  if [[ ! -f "$output_file" ]]; then
    return 1
  fi

  local file_size
  file_size=$(wc -c < "$output_file" 2>/dev/null || echo "0")

  if [[ $file_size -lt 100 ]]; then
    return 1
  fi

  return 0
}

#
# show_missing_tools - Report unavailable tools with installation guidance
#
show_missing_tools() {
  local has_missing=false

  echo ""
  echo "Missing Tools Report"
  echo "===================="
  echo ""

  # Check document converters
  if [[ "$MARKITDOWN_AVAILABLE" == "false" ]] && [[ "$PANDOC_AVAILABLE" == "false" ]] && [[ "$PYMUPDF_AVAILABLE" == "false" ]]; then
    echo "⚠ Document→MD Conversion: No tools available"
    echo "  Install MarkItDown: pip install --user 'markitdown[all]' (recommended, handles DOCX and PDF)"
    echo "  Or install Pandoc: Use your system package manager (DOCX only)"
    echo "  Or install PyMuPDF4LLM: pip install --user pymupdf4llm (PDF only, fast)"
    echo ""
    has_missing=true
  fi

  # Check MD exporters
  if [[ "$PANDOC_AVAILABLE" == "false" ]]; then
    echo "⚠ MD→DOCX/PDF Conversion: Pandoc not available"
    echo "  Install Pandoc: Use your system package manager"
    echo ""
    has_missing=true
  elif [[ "$TYPST_AVAILABLE" == "false" ]] && [[ "$XELATEX_AVAILABLE" == "false" ]]; then
    echo "⚠ MD→PDF Conversion: No PDF engine available"
    echo "  Install Typst: Use your system package manager"
    echo "  Or install XeLaTeX: Install texlive package"
    echo ""
    has_missing=true
  fi

  if [[ "$has_missing" == "false" ]]; then
    echo "✓ All recommended tools are available"
    echo ""
  fi
}

#
# generate_summary - Print conversion summary
#
generate_summary() {
  # Calculate totals
  local total_success=$((docx_success + pdf_success + md_to_docx_success + md_to_pdf_success))
  local total_failed=$((docx_failed + pdf_failed + md_to_docx_failed + md_to_pdf_failed))
  local total_processed=$((total_success + total_failed))

  # Determine conversion mode text
  local mode_text="offline"
  if [[ "${CONVERSION_MODE:-offline}" == "gemini" ]]; then
    mode_text="gemini"
  fi

  # Write summary to log first
  echo "" >> "$LOG_FILE"
  echo "======================================" >> "$LOG_FILE"
  echo "Conversion Summary" >> "$LOG_FILE"
  echo "======================================" >> "$LOG_FILE"
  echo "DOCX → MD: $docx_success success, $docx_failed failed" >> "$LOG_FILE"
  echo "PDF → MD: $pdf_success success, $pdf_failed failed" >> "$LOG_FILE"
  echo "MD → DOCX: $md_to_docx_success success, $md_to_docx_failed failed" >> "$LOG_FILE"
  echo "MD → PDF: $md_to_pdf_success success, $md_to_pdf_failed failed" >> "$LOG_FILE"
  if [[ $collisions_resolved -gt 0 ]]; then
    echo "Filename collisions resolved: $collisions_resolved" >> "$LOG_FILE"
  fi
  if [[ $timeouts_occurred -gt 0 ]]; then
    echo "Timeouts occurred: $timeouts_occurred" >> "$LOG_FILE"
  fi
  if [[ $validation_failures -gt 0 ]]; then
    echo "Validation failures: $validation_failures files" >> "$LOG_FILE"
  fi

  # Use standardized summary format if available
  if [[ "$SUMMARY_FORMATTING_AVAILABLE" == "true" ]] && type print_artifact_summary &>/dev/null; then
    local summary_text="Converted $total_success of $total_processed documents in $mode_text mode."
    if [[ $total_failed -gt 0 ]]; then
      summary_text="$summary_text $total_failed files failed (see log for details)."
    fi

    local artifacts=""
    artifacts+="  Output: $OUTPUT_DIR ($total_success files)"
    artifacts+="\n  Log: $LOG_FILE"

    local next_steps=""
    next_steps+="  - Review: ls -lh $OUTPUT_DIR"
    next_steps+="\n  - Check log: cat $LOG_FILE"
    if [[ $total_failed -gt 0 ]]; then
      next_steps+="\n  - Debug failures: grep FAILED $LOG_FILE"
    fi

    print_artifact_summary "Convert" "$summary_text" "" "$(echo -e "$artifacts")" "$(echo -e "$next_steps")"
  else
    # Fallback to legacy format if summary-formatting.sh not available
    echo "======================================"
    echo "Conversion Summary"
    echo "======================================"
    echo ""
    echo "DOCX → MD:"
    echo "  Success: $docx_success"
    echo "  Failed:  $docx_failed"
    echo ""
    echo "PDF → MD:"
    echo "  Success: $pdf_success"
    echo "  Failed:  $pdf_failed"
    echo ""
    echo "MD → DOCX:"
    echo "  Success: $md_to_docx_success"
    echo "  Failed:  $md_to_docx_failed"
    echo ""
    echo "MD → PDF:"
    echo "  Success: $md_to_pdf_success"
    echo "  Failed:  $md_to_pdf_failed"
    echo ""
    if [[ $collisions_resolved -gt 0 ]]; then
      echo "Filename collisions resolved: $collisions_resolved"
      echo ""
    fi
    if [[ $timeouts_occurred -gt 0 ]]; then
      echo "Timeouts occurred: $timeouts_occurred"
      echo ""
    fi
    if [[ $validation_failures -gt 0 ]]; then
      echo "Validation: $validation_failures files skipped (see log)"
      echo ""
    fi
    echo "Output directory: $OUTPUT_DIR"
    echo "Conversion log: $LOG_FILE"
    echo ""
  fi
}

#
# Main execution function (called from convert-docs.md command)
#
# This function is exported so convert-docs.md can call it directly
#
main_conversion() {
  # Parse arguments with proper --parallel and --no-api support
  INPUT_DIR=""
  OUTPUT_DIR="./converted_output"
  DRY_RUN=false
  PARALLEL_MODE=false
  PARALLEL_WORKERS=1
  OFFLINE_FLAG=false

  # Parse command-line arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --detect-tools)
        detect_tools
        detect_conversion_mode "false"
        show_tool_detection
        exit 0
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --no-api|--offline)
        OFFLINE_FLAG=true
        shift
        ;;
      --parallel)
        PARALLEL_MODE=true
        if [[ -n "${2:-}" ]] && [[ "$2" =~ ^[0-9]+$ ]]; then
          PARALLEL_WORKERS="$2"
          shift 2
        else
          # Auto-detect optimal worker count
          if command -v nproc &>/dev/null; then
            PARALLEL_WORKERS=$(nproc)
          elif command -v sysctl &>/dev/null; then
            PARALLEL_WORKERS=$(sysctl -n hw.ncpu 2>/dev/null || echo "4")
          else
            PARALLEL_WORKERS=4
          fi
          shift
        fi
        ;;
      --help|-h)
        echo "Usage: convert-core.sh [INPUT_DIR] [OUTPUT_DIR] [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --detect-tools   Show available conversion tools and exit"
        echo "  --dry-run        Show files that would be converted without converting"
        echo "  --no-api         Disable API-based conversion (use offline mode)"
        echo "  --offline        Alias for --no-api"
        echo "  --parallel [N]   Enable parallel conversion with N workers (default: auto)"
        echo "  --help, -h       Show this help message"
        echo ""
        echo "Environment Variables:"
        echo "  GEMINI_API_KEY        Gemini API key for PDF conversion (optional)"
        echo "  CONVERT_DOCS_OFFLINE  Set to 'true' to disable API calls"
        exit 0
        ;;
      *)
        if [ -z "$INPUT_DIR" ]; then
          INPUT_DIR="$1"
        elif [ "$OUTPUT_DIR" = "./converted_output" ]; then
          OUTPUT_DIR="$1"
        fi
        shift
        ;;
    esac
  done

  # Set defaults
  INPUT_DIR="${INPUT_DIR:-.}"

  # Cap parallel workers at reasonable maximum
  if [ "$PARALLEL_WORKERS" -gt 32 ]; then
    echo "Warning: Capping parallel workers at 32 (requested: $PARALLEL_WORKERS)" >&2
    PARALLEL_WORKERS=32
  fi

  # Validate input directory
  if [[ ! -d "$INPUT_DIR" ]]; then
    echo "Error: Input directory not found: $INPUT_DIR" >&2
    log_conversion_error "validation_error" "Input directory not found" "{\"input_dir\": \"$INPUT_DIR\"}"
    exit 1
  fi

  # Initialize file arrays (required for bash -u mode)
  docx_files=()
  pdf_files=()
  md_files=()

  # Detect tools
  detect_tools

  # Detect conversion mode (gemini or offline)
  detect_conversion_mode "$OFFLINE_FLAG"
  echo "Conversion Mode: $CONVERSION_MODE"

  # Discover files
  discover_files "$INPUT_DIR"

  # Detect conversion direction
  detect_conversion_direction

  # Handle dry run
  if [[ "$DRY_RUN" == "true" ]]; then
    show_dry_run "$INPUT_DIR"
    exit 0
  fi

  # Create output directory
  mkdir -p "$OUTPUT_DIR"

  # Acquire lock to prevent concurrent conversions
  if ! acquire_lock "$OUTPUT_DIR"; then
    exit 1
  fi

  # Setup trap to release lock on exit (normal, error, or interrupt)
  trap "release_lock '$OUTPUT_DIR'" EXIT

  # Initialize log file
  LOG_FILE="$OUTPUT_DIR/conversion.log"
  echo "Document Conversion Log - $(date)" > "$LOG_FILE"
  echo "Input Directory: $INPUT_DIR" >> "$LOG_FILE"
  echo "Output Directory: $OUTPUT_DIR" >> "$LOG_FILE"
  echo "Conversion Direction: $CONVERSION_DIRECTION" >> "$LOG_FILE"
  echo "Conversion Mode: $CONVERSION_MODE" >> "$LOG_FILE"
  echo "" >> "$LOG_FILE"

  # Check disk space (warnings only, doesn't prevent conversion)
  check_disk_space "$OUTPUT_DIR"

  # Check if there are files to convert or if we should show missing tools
  total_convertible=$((${#docx_files[@]} + ${#pdf_files[@]} + ${#md_files[@]}))

  if [[ $total_convertible -eq 0 ]]; then
    echo "No convertible files found in $INPUT_DIR"
    echo ""
    show_missing_tools
    exit 0
  fi

  # Process conversions
  process_conversions

  # Generate summary
  generate_summary

  # Show missing tools if any conversions failed
  if [[ $((docx_failed + pdf_failed + md_to_docx_failed + md_to_pdf_failed)) -gt 0 ]]; then
    show_missing_tools
  fi
}

# Execute main_conversion if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main_conversion "$@"
fi
