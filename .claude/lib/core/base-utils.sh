#!/bin/bash
# base-utils.sh
#
# Base utility functions with NO external dependencies.
# This file is sourced by all other utilities to break circular dependencies.
#
# Functions:
#   - error() - Print error message and exit
#   - warn() - Print warning message
#   - info() - Print info message
#   - debug() - Print debug message (if DEBUG=1)
#   - require_command() - Check if command exists
#   - require_file() - Check if file exists
#
# Usage:
#   source "$CLAUDE_PROJECT_DIR/.claude/lib/core/base-utils.sh"

set -euo pipefail

# error <message>
#
# Print error message to stderr and exit with status 1
error() {
  echo "Error: $*" >&2
  exit 1
}

# warn <message>
#
# Print warning message to stderr
warn() {
  echo "Warning: $*" >&2
}

# info <message>
#
# Print info message to stdout
info() {
  echo "Info: $*"
}

# debug <message>
#
# Print debug message if DEBUG=1
debug() {
  if [ "${DEBUG:-0}" = "1" ]; then
    echo "Debug: $*" >&2
  fi
}

# require_command <command-name>
#
# Check if command exists, error if not
require_command() {
  local cmd="$1"
  if ! command -v "$cmd" &> /dev/null; then
    error "Required command not found: $cmd"
  fi
}

# require_file <file-path>
#
# Check if file exists, error if not
require_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    error "Required file not found: $file"
  fi
}

# require_dir <directory-path>
#
# Check if directory exists, error if not
require_dir() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    error "Required directory not found: $dir"
  fi
}
