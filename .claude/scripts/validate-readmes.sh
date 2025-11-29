#!/usr/bin/env bash
# validate-readmes.sh - Comprehensive README validation script
# Checks all READMEs in .claude/ directory for compliance with documentation standards

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Statistics
total_readmes=0
compliant_readmes=0
issues_found=0

# Get project root
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
CLAUDE_DIR="${CLAUDE_PROJECT_DIR}/.claude"

# Output file for detailed report
REPORT_FILE="${CLAUDE_DIR}/tmp/readme-validation-report.txt"
mkdir -p "$(dirname "$REPORT_FILE")"

# Comprehensive mode flag
COMPREHENSIVE=false
if [[ "${1:-}" == "--comprehensive" ]]; then
    COMPREHENSIVE=true
fi

echo "README Validation Report" > "$REPORT_FILE"
echo "========================" >> "$REPORT_FILE"
echo "Generated: $(date)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Print colored output
print_status() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Check if README has required sections
check_readme_structure() {
    local readme_path=$1
    local relative_path=${readme_path#$CLAUDE_DIR/}
    local has_issues=false

    total_readmes=$((total_readmes + 1))

    echo "" >> "$REPORT_FILE"
    echo "Checking: $relative_path" >> "$REPORT_FILE"
    echo "----------------------------------------" >> "$REPORT_FILE"

    # Check for purpose statement (should be in first few lines)
    if ! head -n 10 "$readme_path" | grep -q -E "^[A-Z].*\." 2>/dev/null; then
        echo "  ⚠ Missing clear purpose statement in first paragraph" >> "$REPORT_FILE"
        has_issues=true
        issues_found=$((issues_found + 1))
    fi

    # Check for Navigation section
    if ! grep -q "## Navigation" "$readme_path" 2>/dev/null; then
        echo "  ⚠ Missing ## Navigation section" >> "$REPORT_FILE"
        has_issues=true
        issues_found=$((issues_found + 1))
    fi

    # Check for parent directory link
    if ! grep -q "\[← " "$readme_path" 2>/dev/null; then
        echo "  ⚠ Missing parent directory link (← Parent)" >> "$REPORT_FILE"
        has_issues=true
        issues_found=$((issues_found + 1))
    fi

    # Check for emojis (UTF-8 encoding issues)
    # Only flag actual emojis (U+1F300-U+1F9FF), not Unicode symbols
    if grep -P '[\x{1F300}-\x{1F9FF}]' "$readme_path" > /dev/null 2>&1; then
        echo "  ⚠ Contains emoji characters (UTF-8 encoding issues)" >> "$REPORT_FILE"
        has_issues=true
        issues_found=$((issues_found + 1))
    fi

    if [[ "$COMPREHENSIVE" == true ]]; then
        # Check for broken relative links
        grep -o '\[.*\](\..*\.md)' "$readme_path" 2>/dev/null | while read -r link; do
            # Extract path from markdown link
            link_path=$(echo "$link" | sed 's/.*](\(.*\))/\1/')
            # Resolve relative to README location
            readme_dir=$(dirname "$readme_path")
            full_path=$(cd "$readme_dir" && realpath -m "$link_path" 2>/dev/null || echo "INVALID")

            if [[ "$full_path" == "INVALID" ]] || [[ ! -f "$full_path" ]]; then
                echo "  ⚠ Broken link: $link_path" >> "$REPORT_FILE"
                has_issues=true
                issues_found=$((issues_found + 1))
            fi
        done

        # Check if files listed in README actually exist
        # Look for code blocks or lists that might contain filenames
        grep -E '^\s*[-*]\s+[a-z0-9_-]+\.(sh|md|json)' "$readme_path" 2>/dev/null | while read -r line; do
            filename=$(echo "$line" | sed -E 's/^\s*[-*]\s+([a-z0-9_-]+\.(sh|md|json)).*/\1/')
            readme_dir=$(dirname "$readme_path")

            if [[ -n "$filename" ]] && [[ ! -f "$readme_dir/$filename" ]]; then
                echo "  ⚠ Listed file not found: $filename" >> "$REPORT_FILE"
                has_issues=true
                issues_found=$((issues_found + 1))
            fi
        done
    fi

    if [[ "$has_issues" == false ]]; then
        echo "  ✓ No issues found" >> "$REPORT_FILE"
        compliant_readmes=$((compliant_readmes + 1))
    fi
}

# Find all READMEs in .claude directory
echo "Scanning for README.md files in $CLAUDE_DIR..."
print_status "$BLUE" "Starting README validation..."
echo ""

# Exclude archive, specs, tmp, logs, and backups directories as per plan
# Use process substitution to avoid subshell issues with counters
while IFS= read -r readme; do
    check_readme_structure "$readme"
done < <(find "$CLAUDE_DIR" -type f -name "README.md" \
    ! -path "*/archive/*" \
    ! -path "*/specs/*" \
    ! -path "*/tmp/*" \
    ! -path "*/logs/*" \
    ! -path "*/backups/*" \
    | sort)

# Generate summary
echo "" >> "$REPORT_FILE"
echo "Summary" >> "$REPORT_FILE"
echo "=======" >> "$REPORT_FILE"
echo "Total READMEs checked: $total_readmes" >> "$REPORT_FILE"
echo "Compliant READMEs: $compliant_readmes" >> "$REPORT_FILE"
echo "READMEs with issues: $((total_readmes - compliant_readmes))" >> "$REPORT_FILE"
echo "Total issues found: $issues_found" >> "$REPORT_FILE"

compliance_pct=0
if [[ $total_readmes -gt 0 ]]; then
    compliance_pct=$((compliant_readmes * 100 / total_readmes))
fi
echo "Compliance rate: ${compliance_pct}%" >> "$REPORT_FILE"

# Print summary to console
echo ""
print_status "$BLUE" "Validation Summary:"
echo "Total READMEs checked: $total_readmes"
echo "Compliant READMEs: $compliant_readmes"
echo "READMEs with issues: $((total_readmes - compliant_readmes))"
echo "Total issues found: $issues_found"

if [[ $compliance_pct -ge 90 ]]; then
    print_status "$GREEN" "Compliance rate: ${compliance_pct}% ✓"
elif [[ $compliance_pct -ge 70 ]]; then
    print_status "$YELLOW" "Compliance rate: ${compliance_pct}% ⚠"
else
    print_status "$RED" "Compliance rate: ${compliance_pct}% ✗"
fi

echo ""
echo "Detailed report saved to: $REPORT_FILE"

# Check for missing READMEs in key directories
echo ""
print_status "$BLUE" "Checking for missing READMEs in key directories..."

missing_count=0

# Check backups directory
if [[ ! -f "$CLAUDE_DIR/data/backups/README.md" ]]; then
    print_status "$YELLOW" "  Missing: data/backups/README.md"
    missing_count=$((missing_count + 1))
fi

# Check data/registries directory
if [[ -d "$CLAUDE_DIR/data/registries" ]] && [[ ! -f "$CLAUDE_DIR/data/registries/README.md" ]]; then
    print_status "$YELLOW" "  Missing: data/registries/README.md"
    missing_count=$((missing_count + 1))
fi

if [[ $missing_count -eq 0 ]]; then
    print_status "$GREEN" "  No critical READMEs missing ✓"
else
    print_status "$YELLOW" "  $missing_count critical README(s) missing"
fi

echo ""
if [[ $compliance_pct -ge 90 ]] && [[ $missing_count -eq 0 ]]; then
    print_status "$GREEN" "Overall validation: PASS ✓"
    exit 0
else
    print_status "$YELLOW" "Overall validation: NEEDS IMPROVEMENT"
    exit 1
fi
