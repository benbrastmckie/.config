#!/usr/bin/env bash
#
# batch-conversion.sh - Template for batch document conversion workflows
#
# This template demonstrates how to use the document-converter skill
# for complex batch conversion scenarios with custom logic.
#
# Usage:
#   ./batch-conversion.sh <input_dir> <output_dir> [options]
#
# Options:
#   --timeout-multiplier N   Multiply all timeouts by N
#   --concurrent N           Set concurrent conversion limit
#   --max-disk-gb N          Set disk usage limit (GB)
#   --tool markitdown|pandoc Force specific tool
#
# Example:
#   ./batch-conversion.sh ~/docs ~/output --concurrent 8 --timeout-multiplier 2.0
#

set -euo pipefail

# Get absolute path to skill directory
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source conversion core library (via symlink)
# shellcheck disable=SC1091
source "$SKILL_DIR/scripts/convert-core.sh" 2>/dev/null || {
  echo "Error: Cannot load conversion library"
  echo "Expected: $SKILL_DIR/scripts/convert-core.sh"
  exit 1
}

#
# Configuration defaults
#

INPUT_DIR=""
OUTPUT_DIR="./converted_output"
TIMEOUT_MULT=1.0
CONCURRENT=4
MAX_DISK=10
FORCE_TOOL=""

#
# parse_args - Parse command-line arguments
#
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --timeout-multiplier)
        TIMEOUT_MULT="$2"
        shift 2
        ;;
      --concurrent)
        CONCURRENT="$2"
        shift 2
        ;;
      --max-disk-gb)
        MAX_DISK="$2"
        shift 2
        ;;
      --tool)
        FORCE_TOOL="$2"
        shift 2
        ;;
      -*)
        echo "Unknown option: $1"
        echo "Usage: $0 <input_dir> <output_dir> [options]"
        exit 1
        ;;
      *)
        if [ -z "$INPUT_DIR" ]; then
          INPUT_DIR="$1"
        elif [ -z "$OUTPUT_DIR" ]; then
          OUTPUT_DIR="$1"
        else
          echo "Too many arguments"
          exit 1
        fi
        shift
        ;;
    esac
  done

  # Validate required arguments
  if [ -z "$INPUT_DIR" ]; then
    echo "Error: Input directory required"
    echo "Usage: $0 <input_dir> <output_dir> [options]"
    exit 1
  fi

  if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory not found: $INPUT_DIR"
    exit 1
  fi
}

#
# configure_environment - Set environment variables for conversion
#
configure_environment() {
  export TIMEOUT_MULTIPLIER="$TIMEOUT_MULT"
  export MAX_CONCURRENT_CONVERSIONS="$CONCURRENT"
  export MAX_DISK_USAGE_GB="$MAX_DISK"

  echo "Batch Conversion Configuration:"
  echo "  Input: $INPUT_DIR"
  echo "  Output: $OUTPUT_DIR"
  echo "  Timeout multiplier: $TIMEOUT_MULT"
  echo "  Concurrent conversions: $CONCURRENT"
  echo "  Max disk usage: ${MAX_DISK}GB"

  if [ -n "$FORCE_TOOL" ]; then
    echo "  Forced tool: $FORCE_TOOL"
  fi

  echo ""
}

#
# force_tool_selection - Override tool detection if requested
#
force_tool_selection() {
  if [ -z "$FORCE_TOOL" ]; then
    return
  fi

  case "$FORCE_TOOL" in
    markitdown)
      PANDOC_AVAILABLE=false
      PYMUPDF_AVAILABLE=false
      echo "Forcing MarkItDown (disabling Pandoc, PyMuPDF4LLM)"
      ;;
    pandoc)
      MARKITDOWN_AVAILABLE=false
      PYMUPDF_AVAILABLE=false
      echo "Forcing Pandoc (disabling MarkItDown, PyMuPDF4LLM)"
      ;;
    pymupdf)
      MARKITDOWN_AVAILABLE=false
      echo "Forcing PyMuPDF4LLM (disabling MarkItDown)"
      ;;
    *)
      echo "Warning: Unknown tool '$FORCE_TOOL', ignoring"
      ;;
  esac
}

#
# main - Main conversion workflow
#
main() {
  echo "=== Document Converter - Batch Conversion Template ==="
  echo ""

  # Parse arguments
  parse_args "$@"

  # Configure environment
  configure_environment

  # Detect available tools
  echo "Detecting conversion tools..."
  detect_tools

  echo "Tool availability:"
  echo "  MarkItDown: $MARKITDOWN_AVAILABLE"
  echo "  Pandoc: $PANDOC_AVAILABLE"
  echo "  PyMuPDF4LLM: $PYMUPDF_AVAILABLE"
  echo "  Typst: $TYPST_AVAILABLE"
  echo "  XeLaTeX: $XELATEX_AVAILABLE"
  echo ""

  # Override tool selection if requested
  force_tool_selection

  # Execute main conversion
  echo "Starting batch conversion..."
  echo ""

  if main_conversion "$INPUT_DIR" "$OUTPUT_DIR"; then
    echo ""
    echo "=== Conversion Complete ==="
    echo "Output: $OUTPUT_DIR"
    echo "Log: $OUTPUT_DIR/conversion.log"
    echo ""

    # Display summary from conversion log
    if [ -f "$OUTPUT_DIR/conversion.log" ]; then
      echo "Summary:"
      grep "Conversion Statistics" -A 10 "$OUTPUT_DIR/conversion.log" || true
    fi

    exit 0
  else
    echo ""
    echo "=== Conversion Failed ==="
    echo "Check log: $OUTPUT_DIR/conversion.log"
    exit 1
  fi
}

# Execute main with all arguments
main "$@"
