#!/run/current-system/sw/bin/bash
# Session Start Restore Hook
# Purpose: Check for interrupted workflows and notify user on session start

# This hook is triggered on SessionStart event (startup or resume).
# It checks for workflow state files and displays helpful messages if found.

# Environment variables available:
# - $CLAUDE_PROJECT_DIR: Project root directory

# Ensure project directory is set
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
  exit 0
fi

# Check for state directory
STATE_DIR="$CLAUDE_PROJECT_DIR/.claude/state"

# If state directory doesn't exist, nothing to restore
if [ ! -d "$STATE_DIR" ]; then
  exit 0
fi

# Check for any state files
STATE_FILES=$(find "$STATE_DIR" -type f -name "*.json" 2>/dev/null)

# If no state files found, exit silently
if [ -z "$STATE_FILES" ]; then
  exit 0
fi

# Count state files
STATE_COUNT=$(echo "$STATE_FILES" | wc -l | tr -d ' ')

# Display helpful message
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│ Workflow State Detected                                     │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│ Found $STATE_COUNT interrupted workflow(s) in .claude/state/       │"
echo "│                                                             │"
echo "│ To resume a workflow, review the state files:              │"
echo "│   ls -la .claude/state/                                     │"
echo "│                                                             │"
echo "│ State files contain context for resuming work.             │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

# List state files with modification times
echo "State files:"
ls -lh "$STATE_DIR"/*.json 2>/dev/null | awk '{print "  - " $9 " (modified: " $6 " " $7 " " $8 ")"}'
echo ""

# Always exit successfully (non-blocking hook)
exit 0
