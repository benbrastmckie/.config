#!/bin/bash
# Performance Analysis Script for /coordinate Command
# Analyzes performance logs and provides summary statistics

CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
LOG_FILE="${CLAUDE_PROJECT_DIR}/.claude/data/logs/coordinate-performance.log"

if [ ! -f "$LOG_FILE" ]; then
  echo "ERROR: Performance log file not found: $LOG_FILE"
  echo ""
  echo "To generate performance data, run:"
  echo "  DEBUG_PERFORMANCE=1 /coordinate \"<workflow description>\""
  exit 1
fi

echo "═══════════════════════════════════════════════════════════════"
echo " /coordinate Performance Summary"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Count total workflows logged
total_workflows=$(cut -d, -f1 "$LOG_FILE" | sort -u | wc -l)
echo "Total Workflows Logged: $total_workflows"
echo ""

# Average phase durations
echo "Average Phase Durations:"
for phase in 0 1 2 3 4 5 6; do
  phase_data=$(grep "phase_${phase}," "$LOG_FILE" 2>/dev/null)
  if [ -n "$phase_data" ]; then
    avg=$(echo "$phase_data" | cut -d, -f3 | sed 's/ms//' | awk '{sum+=$1; count++} END {if (count>0) print sum/count; else print 0}')
    count=$(echo "$phase_data" | wc -l)
    printf "  Phase %d: %6.1f ms (n=%d)\n" "$phase" "$avg" "$count"
  fi
done
echo ""

# Total workflow duration (sum of all phases)
echo "Total Workflow Duration (Average):"
workflow_timestamps=$(cut -d, -f1 "$LOG_FILE" | sort -u)
for timestamp in $workflow_timestamps; do
  workflow_phases=$(grep "^${timestamp}," "$LOG_FILE")
  workflow_total=$(echo "$workflow_phases" | cut -d, -f3 | sed 's/ms//' | awk '{sum+=$1} END {print sum}')
  echo "$workflow_total"
done | awk '{sum+=$1; count++} END {printf "  Average: %.1f ms (%d workflows)\n", sum/count, count}'
echo ""

# Recent performance (last 5 workflows)
echo "Recent Performance (Last 5 Workflows):"
recent_timestamps=$(cut -d, -f1 "$LOG_FILE" | sort -u | tail -5)
for timestamp in $recent_timestamps; do
  workflow_phases=$(grep "^${timestamp}," "$LOG_FILE")
  workflow_total=$(echo "$workflow_phases" | cut -d, -f3 | sed 's/ms//' | awk '{sum+=$1} END {print sum}')
  workflow_date=$(echo "$timestamp" | cut -d'T' -f1)
  workflow_time=$(echo "$timestamp" | cut -d'T' -f2 | cut -d'+' -f1 | cut -d'-' -f1)
  printf "  %s %s: %6.0f ms\n" "$workflow_date" "$workflow_time" "$workflow_total"
done
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Log File: $LOG_FILE"
echo "Total Entries: $(wc -l < "$LOG_FILE")"
echo ""
