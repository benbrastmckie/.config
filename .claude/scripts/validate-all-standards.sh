#!/usr/bin/env bash
# validate-all-standards.sh - Unified standards validation orchestrator
# Version: 1.0.0
#
# Orchestrates all validation scripts with unified reporting and selective execution.
# Single entry point for pre-commit hooks and CI/CD integration.
#
# Usage:
#   bash validate-all-standards.sh --all              # Run all validators
#   bash validate-all-standards.sh --sourcing         # Library sourcing only
#   bash validate-all-standards.sh --readme           # README validation only
#   bash validate-all-standards.sh --links            # Link validation only
#   bash validate-all-standards.sh --suppression      # Error suppression only
#   bash validate-all-standards.sh --conditionals     # Bash conditionals only
#   bash validate-all-standards.sh --staged           # Staged files only (pre-commit)
#   bash validate-all-standards.sh --dry-run          # Show what would be checked
#   bash validate-all-standards.sh --help             # Show help
#
# Exit codes:
#   0 - All checks passed (or only warnings)
#   1 - One or more ERROR-level violations found
#   2 - Script error (invalid options, missing dependencies)
#
# See: .claude/docs/reference/standards/enforcement-mechanisms.md

set -eo pipefail

# Colors for output (with terminal detection)
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  NC=''
fi

# Detect project directory
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  # Fallback: search upward for .claude/ directory
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

if [ -z "${PROJECT_DIR:-}" ] || [ ! -d "$PROJECT_DIR/.claude" ]; then
  echo -e "${RED}ERROR${NC}: Cannot find project directory with .claude/" >&2
  exit 2
fi

# Script paths
SCRIPTS_DIR="$PROJECT_DIR/.claude/scripts"
LINT_DIR="$SCRIPTS_DIR/lint"
TESTS_UTILS_DIR="$PROJECT_DIR/.claude/tests/utilities"

# Validator definitions
# Format: name|script_path|severity|file_filter
VALIDATORS=(
  "library-sourcing|${LINT_DIR}/check-library-sourcing.sh|ERROR|*.md"
  "error-suppression|${TESTS_UTILS_DIR}/lint_error_suppression.sh|ERROR|*.md"
  "bash-conditionals|${TESTS_UTILS_DIR}/lint_bash_conditionals.sh|ERROR|*.sh,*.md"
  "error-logging-coverage|${LINT_DIR}/check-error-logging-coverage.sh|ERROR|*.md"
  "unbound-variables|${LINT_DIR}/check-unbound-variables.sh|ERROR|*.md"
  "hard-barrier-compliance|${SCRIPTS_DIR}/validate-hard-barrier-compliance.sh|ERROR|commands/*.md"
  "task-invocation|${SCRIPTS_DIR}/lint-task-invocation-pattern.sh|ERROR|*.md"
  "argument-capture|${SCRIPTS_DIR}/lint-argument-capture.sh|WARNING|commands/*.md"
  "checkpoint-format|${SCRIPTS_DIR}/lint-checkpoint-format.sh|WARNING|commands/*.md"
  "readme-structure|${SCRIPTS_DIR}/validate-readmes.sh|WARNING|README.md"
  "link-validity|${SCRIPTS_DIR}/validate-links-quick.sh|WARNING|*.md"
  "plan-metadata|${LINT_DIR}/validate-plan-metadata.sh|ERROR|specs/*/plans/*.md"
)

# Counters
ERROR_COUNT=0
WARNING_COUNT=0
PASS_COUNT=0
SKIP_COUNT=0

# Options
RUN_ALL=false
RUN_SOURCING=false
RUN_SUPPRESSION=false
RUN_CONDITIONALS=false
RUN_ERROR_LOGGING=false
RUN_UNBOUND_VARS=false
RUN_HARD_BARRIER=false
RUN_TASK_INVOCATION=false
RUN_ARGUMENT_CAPTURE=false
RUN_CHECKPOINTS=false
RUN_README=false
RUN_LINKS=false
RUN_PLANS=false
STAGED_ONLY=false
DRY_RUN=false

# Usage
show_help() {
  cat <<'EOF'
validate-all-standards.sh - Unified standards validation orchestrator

USAGE:
  bash validate-all-standards.sh [OPTIONS]

OPTIONS:
  --all              Run all validators
  --sourcing         Run library sourcing linter only
  --suppression      Run error suppression linter only
  --conditionals     Run bash conditionals linter only
  --error-logging    Run error logging coverage linter only
  --unbound-vars     Run unbound variables linter only
  --hard-barrier     Run hard barrier compliance validator only
  --task-invocation  Run task invocation pattern linter only
  --argument-capture Run argument capture pattern linter only
  --checkpoints      Run checkpoint format linter only
  --readme           Run README structure validation only
  --links            Run link validation only
  --plans            Run plan metadata validation only
  --staged           Check only staged files (for pre-commit)
  --dry-run          Show what would be checked, don't run validators
  --help             Show this help message

VALIDATORS:
  library-sourcing      Validates bash three-tier sourcing pattern (ERROR)
  error-suppression     Detects error suppression anti-patterns (ERROR)
  bash-conditionals     Detects preprocessing-unsafe conditionals (ERROR)
  error-logging-coverage Validates error logging coverage >= 80% (ERROR)
  unbound-variables     Detects unsafe variable expansions (ERROR)
  hard-barrier-compliance Validates hard barrier subagent delegation (ERROR)
  task-invocation       Validates imperative Task tool invocation pattern (ERROR)
  argument-capture      Validates 2-block argument capture pattern (WARNING)
  checkpoint-format     Validates standardized checkpoint format (WARNING)
  readme-structure      Validates README.md structure (WARNING)
  link-validity         Validates internal markdown links (WARNING)
  plan-metadata         Validates plan metadata compliance (ERROR)

SEVERITY:
  ERROR   - Blocking: commit rejected, must be fixed
  WARNING - Informational: commit proceeds, should be addressed

EXIT CODES:
  0 - All checks passed (or only warnings)
  1 - One or more ERROR-level violations found
  2 - Script error

EXAMPLES:
  # Run all validators
  bash validate-all-standards.sh --all

  # Pre-commit hook usage
  bash validate-all-standards.sh --staged

  # Check specific categories
  bash validate-all-standards.sh --sourcing --suppression

DOCUMENTATION:
  See .claude/docs/reference/standards/enforcement-mechanisms.md
EOF
}

# Parse arguments
parse_args() {
  if [ $# -eq 0 ]; then
    show_help
    exit 0
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      --all)
        RUN_ALL=true
        ;;
      --sourcing)
        RUN_SOURCING=true
        ;;
      --suppression)
        RUN_SUPPRESSION=true
        ;;
      --conditionals)
        RUN_CONDITIONALS=true
        ;;
      --error-logging)
        RUN_ERROR_LOGGING=true
        ;;
      --unbound-vars)
        RUN_UNBOUND_VARS=true
        ;;
      --hard-barrier)
        RUN_HARD_BARRIER=true
        ;;
      --task-invocation)
        RUN_TASK_INVOCATION=true
        ;;
      --argument-capture)
        RUN_ARGUMENT_CAPTURE=true
        ;;
      --checkpoints)
        RUN_CHECKPOINTS=true
        ;;
      --readme)
        RUN_README=true
        ;;
      --links)
        RUN_LINKS=true
        ;;
      --plans)
        RUN_PLANS=true
        ;;
      --staged)
        STAGED_ONLY=true
        ;;
      --dry-run)
        DRY_RUN=true
        ;;
      --help|-h)
        show_help
        exit 0
        ;;
      *)
        echo -e "${RED}ERROR${NC}: Unknown option: $1" >&2
        echo "Run with --help for usage" >&2
        exit 2
        ;;
    esac
    shift
  done

  # If specific validators selected, don't run all
  if $RUN_SOURCING || $RUN_SUPPRESSION || $RUN_CONDITIONALS || $RUN_ERROR_LOGGING || $RUN_UNBOUND_VARS || $RUN_HARD_BARRIER || $RUN_TASK_INVOCATION || $RUN_ARGUMENT_CAPTURE || $RUN_CHECKPOINTS || $RUN_README || $RUN_LINKS; then
    RUN_ALL=false
  fi
}

# Check if validator should run based on options
should_run_validator() {
  local name="$1"

  if $RUN_ALL; then
    return 0
  fi

  case "$name" in
    library-sourcing)
      $RUN_SOURCING && return 0
      ;;
    error-suppression)
      $RUN_SUPPRESSION && return 0
      ;;
    bash-conditionals)
      $RUN_CONDITIONALS && return 0
      ;;
    error-logging-coverage)
      $RUN_ERROR_LOGGING && return 0
      ;;
    unbound-variables)
      $RUN_UNBOUND_VARS && return 0
      ;;
    hard-barrier-compliance)
      $RUN_HARD_BARRIER && return 0
      ;;
    task-invocation)
      $RUN_TASK_INVOCATION && return 0
      ;;
    argument-capture)
      $RUN_ARGUMENT_CAPTURE && return 0
      ;;
    checkpoint-format)
      $RUN_CHECKPOINTS && return 0
      ;;
    readme-structure)
      $RUN_README && return 0
      ;;
    link-validity)
      $RUN_LINKS && return 0
      ;;
    plan-metadata)
      $RUN_PLANS && return 0
      ;;
  esac

  return 1
}

# Get staged files matching pattern
get_staged_files() {
  local pattern="$1"
  local staged_files=""

  if $STAGED_ONLY; then
    # Get staged files matching pattern
    # Handle multiple patterns separated by comma
    for pat in ${pattern//,/ }; do
      local matches
      matches=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -E "${pat//\*/.*}" || true)
      if [ -n "$matches" ]; then
        staged_files="$staged_files $matches"
      fi
    done
    echo "$staged_files"
  fi
}

# Run a single validator
run_validator() {
  local name="$1"
  local script="$2"
  local severity="$3"
  local file_filter="$4"

  echo -e "${BLUE}Running${NC}: $name"

  # Check script exists
  if [ ! -f "$script" ]; then
    echo -e "  ${YELLOW}SKIP${NC}: Script not found: $script"
    SKIP_COUNT=$((SKIP_COUNT + 1))
    return 0
  fi

  # Dry run mode
  if $DRY_RUN; then
    echo -e "  ${BLUE}DRY-RUN${NC}: Would run $script"
    if $STAGED_ONLY; then
      local staged
      staged=$(get_staged_files "$file_filter")
      if [ -n "$staged" ]; then
        echo -e "  Files: $staged"
      else
        echo -e "  Files: (no staged files match $file_filter)"
      fi
    fi
    return 0
  fi

  # Staged mode: check if any staged files match
  if $STAGED_ONLY; then
    local staged_files
    staged_files=$(get_staged_files "$file_filter")

    if [ -z "$staged_files" ]; then
      echo -e "  ${BLUE}SKIP${NC}: No staged files match $file_filter"
      SKIP_COUNT=$((SKIP_COUNT + 1))
      return 0
    fi

    # For staged mode, pass staged files to validator if it supports file arguments
    # Currently, most validators check all relevant files, so we just run them
  fi

  # Run validator
  local output
  local exit_code=0

  # Some validators need explicit file arguments
  case "$name" in
    argument-capture|checkpoint-format)
      # These validators need file paths
      local target_files
      if $STAGED_ONLY; then
        target_files=$(get_staged_files "$file_filter")
        if [ -z "$target_files" ]; then
          echo -e "  ${BLUE}SKIP${NC}: No staged files match $file_filter"
          SKIP_COUNT=$((SKIP_COUNT + 1))
          return 0
        fi
        output=$(bash "$script" $target_files 2>&1) || exit_code=$?
      else
        # Find all matching files in commands directory
        target_files=$(find "$PROJECT_DIR/.claude/commands" -name "*.md" -type f 2>/dev/null || true)
        if [ -z "$target_files" ]; then
          echo -e "  ${BLUE}SKIP${NC}: No command files found"
          SKIP_COUNT=$((SKIP_COUNT + 1))
          return 0
        fi
        output=$(bash "$script" $target_files 2>&1) || exit_code=$?
      fi
      ;;
    plan-metadata)
      # Plan metadata validator checks one file at a time
      local target_files
      local all_output=""
      local any_errors=false

      if $STAGED_ONLY; then
        target_files=$(get_staged_files "$file_filter")
      else
        # Find all plan files
        target_files=$(find "$PROJECT_DIR/.claude/specs" -path "*/plans/*.md" -type f 2>/dev/null | sort || true)
      fi

      if [ -z "$target_files" ]; then
        echo -e "  ${BLUE}SKIP${NC}: No plan files found"
        SKIP_COUNT=$((SKIP_COUNT + 1))
        return 0
      fi

      # Validate each plan file individually
      for plan_file in $target_files; do
        local plan_output
        local plan_exit=0
        plan_output=$(bash "$script" "$plan_file" 2>&1) || plan_exit=$?

        if [ $plan_exit -ne 0 ]; then
          any_errors=true
          all_output+="$plan_file:\n$plan_output\n\n"
        fi
      done

      if $any_errors; then
        output="$all_output"
        exit_code=1
      else
        output="All plan files validated successfully"
        exit_code=0
      fi
      ;;
    *)
      # Most validators discover files themselves
      output=$(bash "$script" 2>&1) || exit_code=$?
      ;;
  esac

  if [ $exit_code -eq 0 ]; then
    echo -e "  ${GREEN}PASS${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    if [ "$severity" = "ERROR" ]; then
      echo -e "  ${RED}FAIL${NC} (ERROR - blocking)"
      ERROR_COUNT=$((ERROR_COUNT + 1))
    else
      echo -e "  ${YELLOW}FAIL${NC} (WARNING - non-blocking)"
      WARNING_COUNT=$((WARNING_COUNT + 1))
    fi

    # Show output (indented)
    if [ -n "$output" ]; then
      echo "$output" | sed 's/^/    /'
    fi
  fi

  echo ""
}

# Print summary
print_summary() {
  echo "=========================================="
  echo "VALIDATION SUMMARY"
  echo "=========================================="
  echo -e "Passed:   ${GREEN}${PASS_COUNT}${NC}"
  echo -e "Errors:   ${RED}${ERROR_COUNT}${NC}"
  echo -e "Warnings: ${YELLOW}${WARNING_COUNT}${NC}"
  echo -e "Skipped:  ${SKIP_COUNT}"
  echo ""

  if [ $ERROR_COUNT -gt 0 ]; then
    echo -e "${RED}FAILED${NC}: $ERROR_COUNT error(s) must be fixed before committing"
    echo ""
    echo "Fix violations or use 'git commit --no-verify' to bypass (document justification)"
    echo ""
    echo "See: .claude/docs/reference/standards/enforcement-mechanisms.md"
    return 1
  elif [ $WARNING_COUNT -gt 0 ]; then
    echo -e "${YELLOW}PASSED${NC} with $WARNING_COUNT warning(s)"
    echo "Warnings should be addressed but do not block commits"
    return 0
  else
    echo -e "${GREEN}PASSED${NC}: All checks passed"
    return 0
  fi
}

# Main
main() {
  parse_args "$@"

  echo "=========================================="
  echo "Standards Validation"
  echo "=========================================="
  echo "Project: $PROJECT_DIR"
  if $STAGED_ONLY; then
    echo "Mode: Staged files only"
  else
    echo "Mode: Full validation"
  fi
  if $DRY_RUN; then
    echo "Mode: Dry run (no execution)"
  fi
  echo ""

  # Run validators
  for validator in "${VALIDATORS[@]}"; do
    IFS='|' read -r name script severity filter <<< "$validator"

    if should_run_validator "$name"; then
      run_validator "$name" "$script" "$severity" "$filter"
    fi
  done

  # Print summary and exit with appropriate code
  print_summary
}

main "$@"
