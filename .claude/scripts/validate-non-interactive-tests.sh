#!/usr/bin/env bash
# validate-non-interactive-tests.sh
#
# Validates implementation plans for non-interactive testing compliance.
# Detects interactive anti-patterns in test phases that block automated execution.
#
# Usage:
#   bash validate-non-interactive-tests.sh --file <plan-path>
#   bash validate-non-interactive-tests.sh --directory <dir-path>
#   bash validate-non-interactive-tests.sh --staged
#   bash validate-non-interactive-tests.sh --json

set -euo pipefail

# Three-tier library sourcing (Tier 1: Core libraries with fail-fast)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_LIB="${SCRIPT_DIR}/../lib"

source "${CLAUDE_LIB}/workflow/validation-utils.sh" 2>/dev/null || {
    echo "ERROR: Cannot load validation-utils library"
    echo "Path: ${CLAUDE_LIB}/workflow/validation-utils.sh"
    exit 1
}

source "${CLAUDE_LIB}/core/error-handling.sh" 2>/dev/null || {
    echo "ERROR: Cannot load error-handling library"
    echo "Path: ${CLAUDE_LIB}/core/error-handling.sh"
    exit 1
}

source "${CLAUDE_LIB}/core/state-persistence.sh" 2>/dev/null || {
    echo "ERROR: Cannot load state-persistence library"
    echo "Path: ${CLAUDE_LIB}/core/state-persistence.sh"
    exit 1
}

# Initialize error logging
ensure_error_log_exists
COMMAND_NAME="/validate-non-interactive-tests"
WORKFLOW_ID="validate_$(date +%s)"
USER_ARGS="$*"

# Anti-pattern regex patterns for detection
declare -a ANTI_PATTERNS=(
    '\b(manual|manually)\b'
    '\bskip\b(?!ped|ping|s)'
    '\bif needed\b'
    '\bverify visually\b'
    '\binspect (the )?output\b'
    '\boptional\b'
    '\bcheck (the )?results\b'
)

declare -a PATTERN_DESCRIPTIONS=(
    "Manual intervention keywords"
    "Skip directives"
    "Conditional/optional language"
    "Human inspection requirements"
    "Manual output inspection"
    "Optional execution indicators"
    "Manual result checking"
)

# Global counters
TOTAL_FILES_SCANNED=0
TOTAL_VIOLATIONS=0
ERROR_COUNT=0
WARNING_COUNT=0

# Output format (default: human-readable)
OUTPUT_FORMAT="human"

# Usage function
usage() {
    cat <<EOF
Usage: validate-non-interactive-tests.sh [OPTIONS]

Validates implementation plans for non-interactive testing compliance.
Detects interactive anti-patterns in test phases that block automated execution.

OPTIONS:
  --file <path>       Validate single plan file
  --directory <path>  Validate all plans in directory (recursive)
  --staged            Validate git staged .md files only
  --json              Output results in JSON format
  -h, --help          Show this help message

EXIT CODES:
  0   No ERROR-level violations found
  1   ERROR-level violations detected or validation failed

EXAMPLES:
  # Validate single plan
  bash validate-non-interactive-tests.sh --file .claude/specs/001_feature/plans/plan.md

  # Validate all plans in specs directory
  bash validate-non-interactive-tests.sh --directory .claude/specs/

  # Validate staged files (pre-commit hook)
  bash validate-non-interactive-tests.sh --staged

  # JSON output for CI integration
  bash validate-non-interactive-tests.sh --file plan.md --json

EOF
}

# Scan plan file for anti-patterns in test phases
scan_plan_file() {
    local plan_file="$1"
    local violations_found=0

    # Extract test phases using awk
    local test_phases=$(awk '
        /^### Phase.*[Tt]est/ { in_test_phase=1; phase_content="" }
        /^### Phase/ && !/[Tt]est/ { in_test_phase=0 }
        /^## / && !/^### / { in_test_phase=0 }
        in_test_phase==1 { phase_content = phase_content $0 "\n" }
        END { print phase_content }
    ' "$plan_file")

    # If no test phases found, return success
    if [ -z "$test_phases" ]; then
        return 0
    fi

    # Apply anti-pattern regex patterns
    local line_num=1
    while IFS= read -r line; do
        for i in "${!ANTI_PATTERNS[@]}"; do
            local pattern="${ANTI_PATTERNS[$i]}"
            local description="${PATTERN_DESCRIPTIONS[$i]}"

            # Use grep with Perl regex for pattern matching
            if echo "$line" | grep -qP "$pattern"; then
                # Generate violation report
                local context_start=$((line_num - 1))
                local context_end=$((line_num + 1))
                local context=$(sed -n "${context_start},${context_end}p" "$plan_file" 2>/dev/null || echo "$line")

                # Classify severity (all explicit interactive directives are ERROR)
                local severity="ERROR"
                ERROR_COUNT=$((ERROR_COUNT + 1))

                # Record violation
                if [ "$OUTPUT_FORMAT" = "json" ]; then
                    # JSON output handled in format_validation_report
                    :
                else
                    echo "[$severity] $plan_file:$line_num"
                    echo "  Pattern: $description"
                    echo "  Matched: $(echo "$line" | grep -oP "$pattern" | head -1)"
                    echo "  Context:"
                    echo "$context" | sed 's/^/    /'
                    echo ""
                fi

                violations_found=1
                TOTAL_VIOLATIONS=$((TOTAL_VIOLATIONS + 1))
            fi
        done
        line_num=$((line_num + 1))
    done <<< "$(cat "$plan_file")"

    return $violations_found
}

# Format validation report
format_validation_report() {
    if [ "$OUTPUT_FORMAT" = "json" ]; then
        cat <<EOF
{
  "total_files_scanned": $TOTAL_FILES_SCANNED,
  "total_violations": $TOTAL_VIOLATIONS,
  "error_count": $ERROR_COUNT,
  "warning_count": $WARNING_COUNT,
  "exit_code": $([ $ERROR_COUNT -gt 0 ] && echo 1 || echo 0)
}
EOF
    else
        echo "=========================================="
        echo "Non-Interactive Testing Validation Report"
        echo "=========================================="
        echo ""
        echo "Summary Statistics:"
        echo "  Files scanned:  $TOTAL_FILES_SCANNED"
        echo "  Violations:     $TOTAL_VIOLATIONS"
        echo "  ERROR-level:    $ERROR_COUNT"
        echo "  WARNING-level:  $WARNING_COUNT"
        echo ""

        if [ $ERROR_COUNT -gt 0 ]; then
            echo "RESULT: FAILED (ERROR-level violations detected)"
            echo ""
            echo "Remediation: Review violations above and replace interactive"
            echo "patterns with programmatic validation commands."
            echo ""
            echo "See: .claude/docs/reference/standards/non-interactive-testing-standard.md"
        else
            echo "RESULT: PASSED (No ERROR-level violations)"
        fi
        echo ""
    fi
}

# Main execution
main() {
    local mode=""
    local target_path=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file)
                mode="file"
                target_path="$2"
                shift 2
                ;;
            --directory)
                mode="directory"
                target_path="$2"
                shift 2
                ;;
            --staged)
                mode="staged"
                shift
                ;;
            --json)
                OUTPUT_FORMAT="json"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "ERROR: Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Validate mode specified
    if [ -z "$mode" ]; then
        echo "ERROR: No validation mode specified"
        usage
        exit 1
    fi

    # Execute validation based on mode
    case "$mode" in
        file)
            if [ ! -f "$target_path" ]; then
                log_command_error "file_error" \
                    "Plan file not found" \
                    "Path: $target_path"
                echo "ERROR: File not found: $target_path"
                exit 1
            fi

            TOTAL_FILES_SCANNED=1
            scan_plan_file "$target_path" || true
            ;;

        directory)
            if [ ! -d "$target_path" ]; then
                log_command_error "file_error" \
                    "Directory not found" \
                    "Path: $target_path"
                echo "ERROR: Directory not found: $target_path"
                exit 1
            fi

            # Find all .md files in directory recursively
            while IFS= read -r plan_file; do
                TOTAL_FILES_SCANNED=$((TOTAL_FILES_SCANNED + 1))
                scan_plan_file "$plan_file" || true
            done < <(find "$target_path" -type f -name "*.md" 2>/dev/null)
            ;;

        staged)
            # Get git staged .md files
            local staged_files=$(git diff --cached --name-only --diff-filter=ACM | grep '\.md$' || true)

            if [ -z "$staged_files" ]; then
                echo "No staged .md files found"
                exit 0
            fi

            while IFS= read -r plan_file; do
                if [ -f "$plan_file" ]; then
                    TOTAL_FILES_SCANNED=$((TOTAL_FILES_SCANNED + 1))
                    scan_plan_file "$plan_file" || true
                fi
            done <<< "$staged_files"
            ;;
    esac

    # Format and output report
    format_validation_report

    # Exit code logic
    if [ $ERROR_COUNT -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

main "$@"
