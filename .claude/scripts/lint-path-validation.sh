#!/usr/bin/env bash
# lint-path-validation.sh
# Validates command files follow path validation and state restoration patterns
# Version: 1.0.0

set -euo pipefail

# Script metadata
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="lint-path-validation"

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Counters
ERROR_COUNT=0
WARNING_COUNT=0
FILES_CHECKED=0

# Usage information
usage() {
    cat <<EOF
Usage: $0 [OPTIONS] [FILES...]

Validates command files follow path validation and state restoration patterns.

OPTIONS:
    -h, --help              Show this help message
    -v, --version           Show version information
    --strict                Treat warnings as errors

PATTERNS VALIDATED:
    1. PATH MISMATCH anti-pattern (direct HOME check without PROJECT_DIR context)
    2. Missing defensive initialization after load_workflow_state
    3. Unquoted variable references in path operations
    4. validate_path_consistency usage

EXAMPLES:
    $0 .claude/commands/*.md
    $0 --strict .claude/commands/research.md
    $0 .claude/commands/create-plan.md .claude/commands/lean-plan.md

EXIT CODES:
    0 - No violations found
    1 - ERROR-level violations found
    2 - WARNING-level violations found (with --strict)

STANDARDS REFERENCE:
    See: .claude/docs/reference/standards/command-authoring.md
         Section: "Path Validation Patterns"
EOF
}

# Version information
version() {
    echo "$SCRIPT_NAME version $SCRIPT_VERSION"
}

# Log error violation
log_error() {
    local file="$1"
    local line_num="$2"
    local message="$3"

    echo -e "${RED}ERROR${NC}: $file:$line_num - $message"
    ERROR_COUNT=$((ERROR_COUNT + 1))
}

# Log warning violation
log_warning() {
    local file="$1"
    local line_num="$2"
    local message="$3"

    echo -e "${YELLOW}WARNING${NC}: $file:$line_num - $message"
    WARNING_COUNT=$((WARNING_COUNT + 1))
}

# Check for PATH MISMATCH anti-pattern
check_path_mismatch_antipattern() {
    local file="$1"
    local line_num=0
    local in_bash_block=false
    local found_home_check=false
    local found_project_dir_check=false
    local home_check_line=0
    local context_lines=()
    local CONTEXT_WINDOW=5

    # Read file line by line
    while IFS= read -r line; do
        line_num=$((line_num + 1))

        # Detect bash block boundaries
        if [[ "$line" =~ ^\`\`\`bash ]]; then
            in_bash_block=true
            found_home_check=false
            found_project_dir_check=false
            context_lines=()
            continue
        fi

        if [[ "$line" =~ ^\`\`\` ]] && [[ "$in_bash_block" == true ]]; then
            in_bash_block=false
            # Check if we found HOME check without PROJECT_DIR check at end of block
            if [[ "$found_home_check" == true ]] && [[ "$found_project_dir_check" == false ]]; then
                log_error "$file" "$home_check_line" "PATH MISMATCH anti-pattern: Direct HOME check without PROJECT_DIR context validation"
            fi
            continue
        fi

        # Skip if not in bash block
        if [[ "$in_bash_block" == false ]]; then
            continue
        fi

        # Maintain sliding context window
        context_lines+=("$line")
        if [[ ${#context_lines[@]} -gt $CONTEXT_WINDOW ]]; then
            context_lines=("${context_lines[@]:1}")
        fi

        # Look for PATH MISMATCH anti-pattern: if [[ "$STATE_FILE" =~ ^${HOME}/ ]]
        if [[ "$line" =~ \[\[.*STATE_FILE.*=~.*\^\$\{HOME\} ]] || [[ "$line" =~ \[\[.*STATE_FILE.*=~.*\^.*HOME/ ]]; then
            found_home_check=true
            home_check_line=$line_num

            # Look backward in context window for PROJECT_DIR check
            for context_line in "${context_lines[@]}"; do
                if [[ "$context_line" =~ CLAUDE_PROJECT_DIR.*=~.*HOME ]] || [[ "$context_line" =~ PROJECT_DIR.*=~.*HOME ]]; then
                    found_project_dir_check=true
                    break
                fi
            done
        fi

        # Look for PROJECT_DIR check in current line
        if [[ "$line" =~ CLAUDE_PROJECT_DIR.*=~.*HOME ]] || [[ "$line" =~ PROJECT_DIR.*=~.*HOME ]]; then
            found_project_dir_check=true
        fi

        # Reset if we find validate_path_consistency (correct pattern)
        if [[ "$line" =~ validate_path_consistency ]]; then
            found_home_check=false
            found_project_dir_check=false
        fi

    done < "$file"
}

# Check for missing defensive initialization after state restoration
check_defensive_initialization() {
    local file="$1"
    local line_num=0
    local in_bash_block=false
    local found_state_load=false
    local state_load_line=0
    local found_defensive_init=false
    local lines_since_state_load=0
    local MAX_LINES_AFTER_LOAD=20

    # Read file line by line
    while IFS= read -r line; do
        line_num=$((line_num + 1))

        # Detect bash block boundaries
        if [[ "$line" =~ ^\`\`\`bash ]]; then
            in_bash_block=true
            found_state_load=false
            found_defensive_init=false
            lines_since_state_load=0
            continue
        fi

        if [[ "$line" =~ ^\`\`\` ]] && [[ "$in_bash_block" == true ]]; then
            in_bash_block=false
            # Check if we found state load without defensive init
            if [[ "$found_state_load" == true ]] && [[ "$found_defensive_init" == false ]]; then
                log_warning "$file" "$state_load_line" "State restoration without defensive initialization (consider adding defaults for optional variables)"
            fi
            continue
        fi

        # Skip if not in bash block
        if [[ "$in_bash_block" == false ]]; then
            continue
        fi

        # Look for state restoration
        if [[ "$line" =~ load_workflow_state ]] || [[ "$line" =~ source.*state.*\.sh ]]; then
            found_state_load=true
            state_load_line=$line_num
            lines_since_state_load=0
        fi

        # Look for defensive initialization pattern
        if [[ "$found_state_load" == true ]]; then
            lines_since_state_load=$((lines_since_state_load + 1))

            # Pattern: VARIABLE="${VARIABLE:-default}"
            if [[ "$line" =~ ^[[:space:]]*[A-Z_]+=\"\$\{[A-Z_]+:-.*\}\" ]]; then
                found_defensive_init=true
            fi

            # Pattern: Comment mentioning defensive initialization
            if [[ "$line" =~ DEFENSIVE.*INITIALIZATION ]] || [[ "$line" =~ defensive.*variable.*init ]]; then
                found_defensive_init=true
            fi

            # Stop checking after MAX_LINES
            if [[ $lines_since_state_load -gt $MAX_LINES_AFTER_LOAD ]]; then
                if [[ "$found_defensive_init" == false ]]; then
                    log_warning "$file" "$state_load_line" "State restoration without defensive initialization within $MAX_LINES_AFTER_LOAD lines"
                fi
                found_state_load=false
            fi
        fi

    done < "$file"
}

# Check for unquoted variable references in path operations
check_unquoted_paths() {
    local file="$1"
    local line_num=0
    local in_bash_block=false

    # Read file line by line
    while IFS= read -r line; do
        line_num=$((line_num + 1))

        # Detect bash block boundaries
        if [[ "$line" =~ ^\`\`\`bash ]]; then
            in_bash_block=true
            continue
        fi

        if [[ "$line" =~ ^\`\`\` ]] && [[ "$in_bash_block" == true ]]; then
            in_bash_block=false
            continue
        fi

        # Skip if not in bash block
        if [[ "$in_bash_block" == false ]]; then
            continue
        fi

        # Skip comments
        if [[ "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi

        # Look for path operations with unquoted variables
        # Pattern: mkdir/rm/cp/mv followed by unquoted $VAR or ${VAR}
        if [[ "$line" =~ (mkdir|rm|cp|mv|cd)[[:space:]]+.*\$[A-Z_]+([^\"\'\/]|$) ]] && [[ ! "$line" =~ \".*\$[A-Z_]+.*\" ]]; then
            # Allow exceptions: arrays, arithmetic, etc.
            if [[ ! "$line" =~ \$\{[A-Z_]+\[@\]\} ]] && [[ ! "$line" =~ \$\(\( ]]; then
                log_warning "$file" "$line_num" "Potentially unquoted variable in path operation (consider quoting to handle spaces)"
            fi
        fi

    done < "$file"
}

# Check for proper validate_path_consistency usage
check_validate_path_consistency_usage() {
    local file="$1"
    local line_num=0
    local in_bash_block=false
    local found_home_check=false
    local found_validate_call=false
    local home_check_line=0

    # Read file line by line
    while IFS= read -r line; do
        line_num=$((line_num + 1))

        # Detect bash block boundaries
        if [[ "$line" =~ ^\`\`\`bash ]]; then
            in_bash_block=true
            found_home_check=false
            found_validate_call=false
            continue
        fi

        if [[ "$line" =~ ^\`\`\` ]] && [[ "$in_bash_block" == true ]]; then
            in_bash_block=false
            continue
        fi

        # Skip if not in bash block
        if [[ "$in_bash_block" == false ]]; then
            continue
        fi

        # Look for validate_path_consistency calls
        if [[ "$line" =~ validate_path_consistency ]]; then
            found_validate_call=true

            # Check for proper arguments
            if [[ ! "$line" =~ validate_path_consistency.*STATE_FILE.*PROJECT_DIR ]] && \
               [[ ! "$line" =~ validate_path_consistency.*\".*\".*\".*\" ]]; then
                log_warning "$file" "$line_num" "validate_path_consistency may be missing required arguments (STATE_FILE, PROJECT_DIR)"
            fi
        fi

    done < "$file"
}

# Main validation function
validate_file() {
    local file="$1"

    # Skip non-markdown files
    if [[ ! "$file" =~ \.md$ ]]; then
        return
    fi

    # Skip if file doesn't exist
    if [[ ! -f "$file" ]]; then
        log_error "$file" "0" "File not found"
        return
    fi

    FILES_CHECKED=$((FILES_CHECKED + 1))

    # Run checks
    check_path_mismatch_antipattern "$file"
    check_defensive_initialization "$file"
    check_unquoted_paths "$file"
    check_validate_path_consistency_usage "$file"
}

# Parse command line arguments
STRICT_MODE=false
FILES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--version)
            version
            exit 0
            ;;
        --strict)
            STRICT_MODE=true
            shift
            ;;
        -*)
            echo "Unknown option: $1" >&2
            echo "Run '$0 --help' for usage information" >&2
            exit 1
            ;;
        *)
            FILES+=("$1")
            shift
            ;;
    esac
done

# Validate at least one file provided
if [[ ${#FILES[@]} -eq 0 ]]; then
    echo "Error: No files specified" >&2
    echo "Run '$0 --help' for usage information" >&2
    exit 1
fi

# Validate each file
for file in "${FILES[@]}"; do
    validate_file "$file"
done

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Path Validation Pattern Validation Summary"
echo "═══════════════════════════════════════════════════════════"
echo "Files checked: $FILES_CHECKED"
echo -e "Errors: ${RED}$ERROR_COUNT${NC}"
echo -e "Warnings: ${YELLOW}$WARNING_COUNT${NC}"
echo "═══════════════════════════════════════════════════════════"

# Exit with appropriate code
if [[ $ERROR_COUNT -gt 0 ]]; then
    exit 1
elif [[ $WARNING_COUNT -gt 0 ]] && [[ "$STRICT_MODE" == true ]]; then
    exit 2
else
    exit 0
fi
