#!/usr/bin/env bash
# timestamp-utils.sh - Platform-independent timestamp utilities
#
# Provides cross-platform timestamp functions for:
# - File modification time retrieval
# - Timestamp formatting (ISO 8601)
# - Unix timestamp operations
# - Date formatting
#
# Functions:
#   get_file_mtime <file_path>
#   format_timestamp [unix_timestamp]
#   get_unix_time
#   get_iso_date
#   get_iso_timestamp

set -euo pipefail

# Source base utilities for common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/base-utils.sh"

# get_file_mtime <file_path>
# Returns: Unix timestamp of file modification time
# Handles both GNU (Linux) and BSD (macOS) stat commands
get_file_mtime() {
  local file="$1"

  if [[ -z "$file" ]]; then
    error "get_file_mtime: file path is required"
    return 1
  fi

  if [[ ! -f "$file" ]]; then
    error "get_file_mtime: file not found: $file"
    return 1
  fi

  # Try GNU stat first (Linux), then BSD stat (macOS)
  stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || {
    error "get_file_mtime: failed to get modification time for: $file"
    return 1
  }
}

# format_timestamp [unix_timestamp]
# Returns: ISO 8601 formatted timestamp (YYYY-MM-DD HH:MM:SS)
# If no timestamp provided, formats current time
# Handles both GNU and BSD date commands
format_timestamp() {
  local ts="${1:-$(date +%s)}"

  if [[ ! "$ts" =~ ^[0-9]+$ ]]; then
    error "format_timestamp: invalid timestamp: $ts"
    return 1
  fi

  # Try GNU date first (Linux), then BSD date (macOS)
  date -d "@$ts" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || \
  date -r "$ts" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || {
    error "format_timestamp: failed to format timestamp: $ts"
    return 1
  }
}

# get_unix_time
# Returns: Current Unix timestamp (seconds since epoch)
get_unix_time() {
  date '+%s'
}

# get_iso_date
# Returns: Current date in YYYY-MM-DD format
get_iso_date() {
  date '+%Y-%m-%d'
}

# get_iso_timestamp
# Returns: Current timestamp in ISO 8601 format (YYYY-MM-DD HH:MM:SS)
get_iso_timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

# compare_timestamps <timestamp1> <timestamp2>
# Returns: 0 if ts1 > ts2, 1 if ts1 <= ts2
# Useful for checking if one file is newer than another
compare_timestamps() {
  local ts1="$1"
  local ts2="$2"

  if [[ ! "$ts1" =~ ^[0-9]+$ ]] || [[ ! "$ts2" =~ ^[0-9]+$ ]]; then
    error "compare_timestamps: invalid timestamps: $ts1, $ts2"
    return 1
  fi

  [[ "$ts1" -gt "$ts2" ]]
}

# timestamp_diff <timestamp1> <timestamp2>
# Returns: Absolute difference in seconds between two timestamps
timestamp_diff() {
  local ts1="$1"
  local ts2="$2"

  if [[ ! "$ts1" =~ ^[0-9]+$ ]] || [[ ! "$ts2" =~ ^[0-9]+$ ]]; then
    error "timestamp_diff: invalid timestamps: $ts1, $ts2"
    return 1
  fi

  local diff=$((ts1 - ts2))
  echo "${diff#-}"  # Return absolute value
}

# Export functions for use by sourcing scripts
export -f get_file_mtime
export -f format_timestamp
export -f get_unix_time
export -f get_iso_date
export -f get_iso_timestamp
export -f compare_timestamps
export -f timestamp_diff
