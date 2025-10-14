#!/usr/bin/env bash
# validation-utils.sh - Common validation and parameter checking utilities
#
# Provides reusable validation functions for:
# - Parameter existence checks
# - File and directory validation
# - Number validation
# - Path validation
# - Choice validation
#
# Functions:
#   require_param <param_name> <param_value> [error_message]
#   validate_file_exists <file_path> [error_message]
#   validate_dir_exists <dir_path> [error_message]
#   validate_number <value> [error_message]
#   validate_positive_number <value> [error_message]
#   validate_path_safe <path> [error_message]
#   validate_choice <value> <choices...>

set -euo pipefail

# Simple error function (avoid sourcing error-utils.sh to prevent circular dependencies)
error() {
  echo "Error: $*" >&2
}

# require_param <param_name> <param_value> [error_message]
# Exits with error if parameter is empty
# Returns: 0 if parameter is valid, 1 if empty
require_param() {
  local name="$1"
  local value="$2"
  local msg="${3:-Parameter '$name' is required}"

  if [[ -z "$value" ]]; then
    error "$msg"
    return 1
  fi
  return 0
}

# validate_file_exists <file_path> [error_message]
# Returns: 0 if file exists, 1 if not found
validate_file_exists() {
  local file="$1"
  local msg="${2:-File not found: $file}"

  if [[ ! -f "$file" ]]; then
    error "$msg"
    return 1
  fi
  return 0
}

# validate_dir_exists <dir_path> [error_message]
# Returns: 0 if directory exists, 1 if not found
validate_dir_exists() {
  local dir="$1"
  local msg="${2:-Directory not found: $dir}"

  if [[ ! -d "$dir" ]]; then
    error "$msg"
    return 1
  fi
  return 0
}

# validate_number <value> [error_message]
# Returns: 0 if value is a valid number (positive integer), 1 otherwise
validate_number() {
  local value="$1"
  local msg="${2:-Invalid number: $value}"

  if [[ ! "$value" =~ ^[0-9]+$ ]]; then
    error "$msg"
    return 1
  fi
  return 0
}

# validate_positive_number <value> [error_message]
# Returns: 0 if value is a positive number (> 0), 1 otherwise
validate_positive_number() {
  local value="$1"
  local msg="${2:-Value must be a positive number: $value}"

  if ! validate_number "$value" "$msg"; then
    return 1
  fi

  if [[ "$value" -eq 0 ]]; then
    error "$msg"
    return 1
  fi

  return 0
}

# validate_float <value> [error_message]
# Returns: 0 if value is a valid float/decimal number, 1 otherwise
validate_float() {
  local value="$1"
  local msg="${2:-Invalid float: $value}"

  if [[ ! "$value" =~ ^[0-9]+\.?[0-9]*$ ]] && [[ ! "$value" =~ ^[0-9]*\.[0-9]+$ ]]; then
    error "$msg"
    return 1
  fi
  return 0
}

# validate_path_safe <path> [error_message]
# Validates that a path doesn't contain dangerous characters or sequences
# Returns: 0 if path is safe, 1 if suspicious
validate_path_safe() {
  local path="$1"
  local msg="${2:-Unsafe path detected: $path}"

  # Check for dangerous patterns
  if [[ "$path" =~ \.\./|\.\.\\ ]] || [[ "$path" =~ ^/ && ! "$path" =~ ^/home/ && ! "$path" =~ ^/tmp/ ]]; then
    error "$msg"
    return 1
  fi

  return 0
}

# validate_choice <value> <choices...>
# Validates that a value is one of the allowed choices
# Returns: 0 if valid choice, 1 if invalid
# Example: validate_choice "$mode" "sequential" "parallel" "hybrid"
validate_choice() {
  local value="$1"
  shift
  local choices=("$@")

  if [[ -z "$value" ]]; then
    error "validate_choice: value is required"
    return 1
  fi

  if [[ ${#choices[@]} -eq 0 ]]; then
    error "validate_choice: no choices provided"
    return 1
  fi

  for choice in "${choices[@]}"; do
    if [[ "$value" == "$choice" ]]; then
      return 0
    fi
  done

  local choices_str
  choices_str=$(printf ", %s" "${choices[@]}")
  choices_str="${choices_str:2}"  # Remove leading ", "

  error "Invalid choice: '$value'. Must be one of: $choices_str"
  return 1
}

# validate_boolean <value> [error_message]
# Validates that a value is a boolean (true/false, yes/no, 1/0)
# Returns: 0 if valid boolean, 1 otherwise
validate_boolean() {
  local value="$1"
  local msg="${2:-Invalid boolean: $value}"

  case "${value,,}" in  # Convert to lowercase
    true|false|yes|no|1|0)
      return 0
      ;;
    *)
      error "$msg"
      return 1
      ;;
  esac
}

# validate_not_empty <value> <field_name> [error_message]
# Validates that a value is not empty or whitespace-only
# Returns: 0 if not empty, 1 if empty
validate_not_empty() {
  local value="$1"
  local field_name="$2"
  local msg="${3:-Field '$field_name' cannot be empty}"

  if [[ -z "${value// /}" ]]; then  # Remove all spaces and check if empty
    error "$msg"
    return 1
  fi
  return 0
}

# validate_file_readable <file_path> [error_message]
# Validates that a file exists and is readable
# Returns: 0 if readable, 1 otherwise
validate_file_readable() {
  local file="$1"
  local msg="${2:-File not readable: $file}"

  if [[ ! -r "$file" ]]; then
    error "$msg"
    return 1
  fi
  return 0
}

# validate_file_writable <file_path> [error_message]
# Validates that a file is writable (or parent directory is writable for new files)
# Returns: 0 if writable, 1 otherwise
validate_file_writable() {
  local file="$1"
  local msg="${2:-File not writable: $file}"

  if [[ -f "$file" ]]; then
    if [[ ! -w "$file" ]]; then
      error "$msg"
      return 1
    fi
  else
    local dir
    dir="$(dirname "$file")"
    if [[ ! -w "$dir" ]]; then
      error "Directory not writable: $dir"
      return 1
    fi
  fi
  return 0
}

# Export functions for use by sourcing scripts
export -f require_param
export -f validate_file_exists
export -f validate_dir_exists
export -f validate_number
export -f validate_positive_number
export -f validate_float
export -f validate_path_safe
export -f validate_choice
export -f validate_boolean
export -f validate_not_empty
export -f validate_file_readable
export -f validate_file_writable
