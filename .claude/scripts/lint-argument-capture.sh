#!/usr/bin/env bash
# lint-argument-capture.sh
# Validates command files follow 2-block argument capture pattern
# Version: 1.0.0

set -euo pipefail

# Script metadata
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="lint-argument-capture"

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

Validates command files follow the standardized 2-block argument capture pattern.

OPTIONS:
    -h, --help              Show this help message
    -v, --version           Show version information
    --strict                Treat warnings as errors

PATTERNS VALIDATED:
    1. Two-block structure (capture block + validation block)
    2. Temp file cleanup after argument capture
    3. YOUR_DESCRIPTION_HERE substitution pattern
    4. No inline argument parsing in capture block

EXAMPLES:
    $0 .claude/commands/*.md
    $0 --strict .claude/commands/repair.md
    $0 .claude/commands/plan.md .claude/commands/research.md

EXIT CODES:
    0 - No violations found
    1 - ERROR-level violations found
    2 - WARNING-level violations found (with --strict)

STANDARDS REFERENCE:
    See: .claude/docs/reference/standards/command-authoring.md
         Section: "Standardized 2-Block Argument Capture Pattern"
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

# Check if file has 2-block argument capture pattern
check_argument_capture_pattern() {
    local file="$1"
    local content
    local line_num=0
    local in_bash_block=false
    local capture_block_found=false
    local validation_block_found=false
    local capture_block_line=0
    local has_temp_file_cleanup=false
    local has_direct_parsing=false

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

        # Look for YOUR_DESCRIPTION_HERE pattern (argument capture block marker)
        if [[ "$line" =~ YOUR_DESCRIPTION_HERE ]]; then
            if [[ "$capture_block_found" == false ]]; then
                capture_block_found=true
                capture_block_line=$line_num
            fi
        fi

        # Look for temp file creation (argument capture pattern)
        if [[ "$line" =~ ARGS_FILE.*mktemp ]]; then
            capture_block_found=true
            capture_block_line=$line_num
        fi

        # Look for temp file cleanup
        if [[ "$line" =~ rm.*ARGS_FILE ]] || [[ "$line" =~ rm.*\$\{ARGS_FILE\} ]]; then
            has_temp_file_cleanup=true
        fi

        # Look for validation block (argument parsing after capture)
        if [[ "$line" =~ source.*\$\{ARGS_FILE\} ]] || [[ "$line" =~ \[\[.*-f.*ARGS_FILE ]]; then
            validation_block_found=true
        fi

        # Detect anti-pattern: inline parsing in capture block
        if [[ "$capture_block_found" == true ]] && [[ "$validation_block_found" == false ]]; then
            if [[ "$line" =~ ^[[:space:]]*while.*getopt ]] || [[ "$line" =~ ^[[:space:]]*case.*\$ ]]; then
                has_direct_parsing=true
                log_warning "$file" "$line_num" "Inline argument parsing detected in capture block (consider separating into validation block)"
            fi
        fi

    done < "$file"

    # Validate patterns
    if [[ "$capture_block_found" == true ]]; then
        # Check for temp file cleanup
        if [[ "$has_temp_file_cleanup" == false ]]; then
            log_warning "$file" "$capture_block_line" "Argument capture block missing temp file cleanup (rm \${ARGS_FILE})"
        fi

        # Check for validation block
        if [[ "$validation_block_found" == false ]]; then
            log_warning "$file" "$capture_block_line" "Argument capture block not followed by validation block (2-block pattern recommended)"
        fi
    fi
}

# Check if file uses legacy direct argument pattern
check_legacy_pattern() {
    local file="$1"
    local content
    local line_num=0
    local in_bash_block=false
    local has_direct_dollar_access=false

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

        # Look for direct $1, $2, etc. access (legacy pattern)
        if [[ "$line" =~ ^[[:space:]]*[A-Z_]+.*=.*\$[1-9] ]] && [[ ! "$line" =~ shift ]]; then
            has_direct_dollar_access=true
            # This is informational only - legacy pattern is acceptable
            # log_warning "$file" "$line_num" "Legacy direct argument access pattern detected (consider 2-block pattern for new commands)"
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
    check_argument_capture_pattern "$file"
    check_legacy_pattern "$file"
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
echo "Argument Capture Pattern Validation Summary"
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
