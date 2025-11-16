#!/bin/bash
# detect-empty-topics.sh
# Detects and optionally removes empty topic directories in .claude/specs/
#
# Usage:
#   ./detect-empty-topics.sh           # List empty topic directories
#   ./detect-empty-topics.sh --cleanup # Remove empty topic directories
#
# Topic directories match pattern: [0-9][0-9][0-9]_*
# Only truly empty directories are removed (rmdir fails if non-empty)

set -euo pipefail

# Configuration
CLEANUP=false
SPECS_ROOT=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --cleanup)
            CLEANUP=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--cleanup]"
            echo ""
            echo "Detects empty topic directories in .claude/specs/"
            echo ""
            echo "Options:"
            echo "  --cleanup    Remove detected empty directories"
            echo "  --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Detect specs root
detect_specs_root() {
    # Check for CLAUDE_SPECS_ROOT override (test isolation)
    if [[ -n "${CLAUDE_SPECS_ROOT:-}" ]]; then
        echo "$CLAUDE_SPECS_ROOT"
        return 0
    fi

    # Look for .claude/specs from current directory upward
    local current_dir="$PWD"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -d "$current_dir/.claude/specs" ]]; then
            echo "$current_dir/.claude/specs"
            return 0
        fi
        current_dir=$(dirname "$current_dir")
    done

    # Not found
    echo "ERROR: Could not locate .claude/specs directory" >&2
    echo "Run this script from within a project with .claude/specs/" >&2
    return 1
}

# Detect specs root
SPECS_ROOT=$(detect_specs_root)

# Validate specs root exists
if [[ ! -d "$SPECS_ROOT" ]]; then
    echo "ERROR: Specs root does not exist: $SPECS_ROOT" >&2
    exit 1
fi

# Find empty topic directories
# Pattern: [0-9][0-9][0-9]_* (three digits followed by underscore and description)
empty_topics=()

while IFS= read -r -d '' topic_dir; do
    # Check if directory is empty (no files or subdirectories)
    if [[ -z "$(ls -A "$topic_dir" 2>/dev/null)" ]]; then
        empty_topics+=("$topic_dir")
    fi
done < <(find "$SPECS_ROOT" -maxdepth 1 -type d -name '[0-9][0-9][0-9]_*' -print0 2>/dev/null)

# Report findings
if [[ ${#empty_topics[@]} -eq 0 ]]; then
    echo "✓ No empty topic directories found"
    exit 0
fi

# List empty directories
echo "Found ${#empty_topics[@]} empty topic director$([ ${#empty_topics[@]} -eq 1 ] && echo y || echo ies):"
for topic_dir in "${empty_topics[@]}"; do
    # Display relative to specs root
    relative_path="${topic_dir#$SPECS_ROOT/}"
    echo "  - $relative_path"
done

# Cleanup if requested
if [[ "$CLEANUP" == "true" ]]; then
    echo ""
    echo "Removing empty directories..."

    removed_count=0
    failed_count=0

    for topic_dir in "${empty_topics[@]}"; do
        relative_path="${topic_dir#$SPECS_ROOT/}"

        # Use rmdir (fails if directory is not empty)
        if rmdir "$topic_dir" 2>/dev/null; then
            echo "  ✓ Removed: $relative_path"
            ((removed_count++))
        else
            echo "  ✗ Failed to remove: $relative_path (not empty or permission denied)"
            ((failed_count++))
        fi
    done

    echo ""
    echo "Summary:"
    echo "  Removed: $removed_count"
    echo "  Failed:  $failed_count"

    if [[ $failed_count -gt 0 ]]; then
        exit 1
    fi
else
    echo ""
    echo "Run with --cleanup to remove these directories"
fi

exit 0
