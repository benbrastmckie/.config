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
METRICS_DIR="$CLAUDE_PROJECT_DIR/.claude/data/metrics"
mkdir -p "$METRICS_DIR"

# Generate metrics file path (monthly rotation: YYYY-MM.jsonl)
METRICS_FILE="$METRICS_DIR/$(date +%Y-%m).jsonl"

# Collect metrics data
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Try standard env vars first
COMMAND="${CLAUDE_COMMAND:-}"
DURATION="${CLAUDE_DURATION_MS:-}"
STATUS="${CLAUDE_STATUS:-}"

# Fallback: Parse from stdin JSON if env vars missing
if [ -z "$COMMAND" ] && [ -t 0 ]; then
  # If stdin is a terminal (no piped input), use defaults
  COMMAND="unknown"
  DURATION="0"
  STATUS="unknown"
elif [ -z "$COMMAND" ]; then
  # Stop hook receives JSON event on stdin
  EVENT_JSON=$(cat)
  if command -v jq &> /dev/null; then
    COMMAND=$(echo "$EVENT_JSON" | jq -r '.command // "unknown"' 2>/dev/null || echo "unknown")
    DURATION=$(echo "$EVENT_JSON" | jq -r '.duration_ms // 0' 2>/dev/null || echo "0")
    STATUS=$(echo "$EVENT_JSON" | jq -r '.status // "unknown"' 2>/dev/null || echo "unknown")
  else
    # Fallback to basic parsing if jq not available
    COMMAND=$(echo "$EVENT_JSON" | grep -o '"command":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    DURATION=$(echo "$EVENT_JSON" | grep -o '"duration_ms":[0-9]*' | cut -d':' -f2 || echo "0")
    STATUS=$(echo "$EVENT_JSON" | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
  fi
fi

# Extract operation name from command (e.g., /implement -> implement)
OPERATION=$(echo "$COMMAND" | sed 's|^/||')

# Create JSONL entry with enhanced fields
METRICS_ENTRY=$(cat <<EOF
{"timestamp":"$TIMESTAMP","operation":"$OPERATION","duration_ms":$DURATION,"status":"$STATUS"}
EOF
)

# Append to metrics file
echo "$METRICS_ENTRY" >> "$METRICS_FILE"

# Always exit successfully (non-blocking hook)
exit 0
