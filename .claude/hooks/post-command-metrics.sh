#!/run/current-system/sw/bin/bash
# Post-Command Metrics Hook
# Purpose: Collect command execution metrics for performance analysis

# This hook is triggered on the Stop event after each command completes.
# It collects timestamp, command name, duration, and status, appending to a JSONL file.

# Environment variables available:
# - $CLAUDE_PROJECT_DIR: Project root directory
# - $CLAUDE_COMMAND: Command that was executed
# - $CLAUDE_DURATION_MS: Execution duration in milliseconds
# - $CLAUDE_STATUS: Execution status (success/failure)

# Ensure project directory is set
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
  exit 0
fi

# Create metrics directory if it doesn't exist
METRICS_DIR="$CLAUDE_PROJECT_DIR/.claude/metrics"
mkdir -p "$METRICS_DIR"

# Generate metrics file path (monthly rotation: YYYY-MM.jsonl)
METRICS_FILE="$METRICS_DIR/$(date +%Y-%m).jsonl"

# Collect metrics data
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
COMMAND="${CLAUDE_COMMAND:-unknown}"
DURATION="${CLAUDE_DURATION_MS:-0}"
STATUS="${CLAUDE_STATUS:-unknown}"

# Extract operation name from command (e.g., /implement -> implement)
OPERATION=$(echo "$COMMAND" | sed 's|^/||')

# Create JSONL entry
METRICS_ENTRY=$(cat <<EOF
{"timestamp":"$TIMESTAMP","operation":"$OPERATION","duration_ms":$DURATION,"status":"$STATUS"}
EOF
)

# Append to metrics file
echo "$METRICS_ENTRY" >> "$METRICS_FILE"

# Always exit successfully (non-blocking hook)
exit 0
