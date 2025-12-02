#!/usr/bin/env bash
# lint-checkpoint-format.sh
# Validates command files follow standardized checkpoint format
# Version: 1.0.0

set -euo pipefail

# Script metadata
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="lint-checkpoint-format"

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Counters
ERROR_COUNT=0
WARNING_COUNT=0
FILES_CHECKED=0
CHECKPOINT_COUNT=0

# Usage information
usage() {
    cat <<EOF
Usage: $0 [OPTIONS] [FILES...]

Validates command files follow the standardized checkpoint format.

OPTIONS:
    -h, --help              Show this help message
    -v, --version           Show version information
    --strict                Treat warnings as errors

CHECKPOINT FORMAT:
    Standard 3-line format:
    1. [CHECKPOINT] {Phase name} complete
    2. Context: KEY=value, KEY2=value
    3. Ready for: {Next action description}

PATTERNS VALIDATED:
    1. [CHECKPOINT] marker present
    2. "complete" or "ready" status word
    3. Context line with KEY=value pairs
    4. "Ready for:" directive

EXAMPLES:
    $0 .claude/commands/*.md
    $0 --strict .claude/commands/repair.md
    $0 .claude/commands/plan.md .claude/commands/research.md

EXIT CODES:
    0 - No violations found
    1 - ERROR-level violations found
    2 - WARNING-level violations found (with --strict)

STANDARDS REFERENCE:
    See: .claude/docs/reference/standards/output-formatting.md
         Section: "Checkpoint Reporting Format"
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

# Check checkpoint format in file
check_checkpoint_format() {
    local file="$1"
    local line_num=0
    local in_bash_block=false
    local checkpoint_line=0
    local checkpoint_text=""
    local has_context_line=false
    local has_ready_line=false
    local lines_since_checkpoint=0

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
            # Reset checkpoint tracking when exiting bash block
            if [[ $checkpoint_line -gt 0 ]]; then
                # Validate checkpoint completeness before resetting
                if [[ "$has_context_line" == false ]]; then
                    log_warning "$file" "$checkpoint_line" "Checkpoint missing 'Context:' line (recommended for observability)"
                fi
                if [[ "$has_ready_line" == false ]]; then
                    log_warning "$file" "$checkpoint_line" "Checkpoint missing 'Ready for:' line (recommended for workflow clarity)"
                fi
            fi
            checkpoint_line=0
            has_context_line=false
            has_ready_line=false
            lines_since_checkpoint=0
            continue
        fi

        # Skip if not in bash block
        if [[ "$in_bash_block" == false ]]; then
            continue
        fi

        # Track lines since last checkpoint marker
        if [[ $checkpoint_line -gt 0 ]]; then
            lines_since_checkpoint=$((lines_since_checkpoint + 1))

            # If we've gone more than 5 lines past checkpoint without Context/Ready, warn
            if [[ $lines_since_checkpoint -gt 5 ]]; then
                if [[ "$has_context_line" == false ]]; then
                    log_warning "$file" "$checkpoint_line" "Checkpoint missing 'Context:' line within 5 lines"
                fi
                if [[ "$has_ready_line" == false ]]; then
                    log_warning "$file" "$checkpoint_line" "Checkpoint missing 'Ready for:' line within 5 lines"
                fi
                # Reset to avoid duplicate warnings
                checkpoint_line=0
                has_context_line=false
                has_ready_line=false
                lines_since_checkpoint=0
            fi
        fi

        # Look for [CHECKPOINT] marker
        if [[ "$line" =~ \[CHECKPOINT\] ]]; then
            CHECKPOINT_COUNT=$((CHECKPOINT_COUNT + 1))

            # Save checkpoint info for validation
            checkpoint_line=$line_num
            checkpoint_text="$line"
            has_context_line=false
            has_ready_line=false
            lines_since_checkpoint=0

            # Check for status word (complete/ready)
            if [[ ! "$line" =~ (complete|ready|finished|done) ]]; then
                log_warning "$file" "$line_num" "Checkpoint missing status word (complete/ready/finished/done)"
            fi

            # Check for proper format
            if [[ ! "$line" =~ echo.*\[CHECKPOINT\] ]] && [[ ! "$line" =~ printf.*\[CHECKPOINT\] ]]; then
                # Checkpoint not in echo/printf command (might be in comment or malformed)
                log_warning "$file" "$line_num" "Checkpoint not in echo/printf command (verify format)"
            fi

            continue
        fi

        # Look for Context line (must follow checkpoint)
        if [[ $checkpoint_line -gt 0 ]] && [[ "$line" =~ Context: ]]; then
            has_context_line=true

            # Verify KEY=value format
            if [[ ! "$line" =~ [A-Z_]+= ]]; then
                log_warning "$file" "$line_num" "Context line missing KEY=value format (use UPPERCASE_KEYS)"
            fi

            continue
        fi

        # Look for Ready for line (must follow checkpoint)
        if [[ $checkpoint_line -gt 0 ]] && [[ "$line" =~ Ready[[:space:]]for: ]]; then
            has_ready_line=true
            continue
        fi

    done < "$file"

    # Final checkpoint validation (if file ends in bash block)
    if [[ $checkpoint_line -gt 0 ]]; then
        if [[ "$has_context_line" == false ]]; then
            log_warning "$file" "$checkpoint_line" "Checkpoint missing 'Context:' line (recommended for observability)"
        fi
        if [[ "$has_ready_line" == false ]]; then
            log_warning "$file" "$checkpoint_line" "Checkpoint missing 'Ready for:' line (recommended for workflow clarity)"
        fi
    fi
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
    check_checkpoint_format "$file"
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
echo "Checkpoint Format Validation Summary"
echo "═══════════════════════════════════════════════════════════"
echo "Files checked: $FILES_CHECKED"
echo "Checkpoints found: $CHECKPOINT_COUNT"
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
