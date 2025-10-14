# workflow-metrics.sh

Workflow metrics aggregation utility for performance analysis and reporting.

## Overview

`workflow-metrics.sh` provides comprehensive metrics aggregation from the adaptive planning system:
- **Workflow timing analysis** - Duration, phase counts, average times
- **Agent performance tracking** - Invocation stats, success rates, duration averages
- **Complexity evaluation metrics** - Method usage, discrepancies, agent invocation rates
- **Markdown report generation** - Human-readable performance summaries

## Features

### Workflow Time Aggregation

Extracts timing data from `adaptive-planning.log`:

```bash
workflow_metrics=$(aggregate_workflow_times)
echo "$workflow_metrics" | jq .
```

**Output format:**
```json
{
  "workflow_duration_seconds": 1847,
  "total_phases": 8,
  "completed_phases": 6,
  "avg_phase_time_seconds": 307
}
```

**Data sources:**
- `WORKFLOW_START` and `WORKFLOW_END` markers in log
- `PHASE_START` and `PHASE_COMPLETE` event counts
- Timestamp parsing using epoch conversion

### Agent Performance Tracking

Extracts agent metrics from `agent-registry.json`:

```bash
agent_metrics=$(aggregate_agent_metrics)
echo "$agent_metrics" | jq .
```

**Output format:**
```json
{
  "total_agents": 5,
  "agent_summary": [
    {
      "agent_type": "research-specialist",
      "invocations": 12,
      "successes": 11,
      "failures": 1,
      "success_rate": 91.67,
      "avg_duration": 45.3
    },
    {
      "agent_type": "code-writer",
      "invocations": 8,
      "successes": 8,
      "failures": 0,
      "success_rate": 100.0,
      "avg_duration": 122.5
    }
  ]
}
```

**Metrics calculated:**
- Success rate: `(successes / invocations) * 100`
- Average duration per agent type
- Total agent type count

### Complexity Evaluation Metrics

Analyzes complexity evaluation method usage from log:

```bash
complexity_metrics=$(aggregate_complexity_metrics)
echo "$complexity_metrics" | jq .
```

**Output format:**
```json
{
  "total_evaluations": 24,
  "threshold_only": 18,
  "agent_overrides": 3,
  "hybrid_averages": 3,
  "score_discrepancies": 2,
  "agent_invocation_rate": 25.0
}
```

**Evaluation methods:**
- **Threshold-only**: Complexity determined by threshold calculation alone
- **Agent overrides**: Complexity-analyzer agent overrode threshold decision
- **Hybrid averages**: Average of threshold and agent scores used
- **Score discrepancies**: Threshold and agent disagreed by >3 points

**Agent invocation rate**: Percentage of evaluations that invoked the agent (agent + hybrid)

### Performance Report Generation

Creates markdown-formatted performance reports:

```bash
generate_performance_report > report.md
```

**Report sections:**
1. **Workflow Summary** - Duration, phases, average time
2. **Agent Performance** - Per-agent statistics table
3. **Complexity Evaluation** - Method distribution and metrics

**Example output:**
```markdown
# Workflow Performance Report

**Generated**: 2025-10-13 14:32:15

## Workflow Summary

- **Total Duration**: 1847s (30m 47s)
- **Phases**: 6 / 8 completed
- **Average Phase Time**: 307s

## Agent Performance

- **Total Agents Used**: 5
- **Agent Invocation Summary**:
  - **research-specialist**: 12 invocations, 91% success rate, 45.3s avg
  - **code-writer**: 8 invocations, 100% success rate, 122.5s avg

## Complexity Evaluation

- **Total Evaluations**: 24
- **Agent Invocation Rate**: 25%
- **Threshold-Only**: 18
- **Agent Overrides**: 3
- **Hybrid Averages**: 3
- **Score Discrepancies**: 2
```

## Usage

### Basic Integration

```bash
#!/usr/bin/env bash
source .claude/lib/workflow-metrics.sh

# Get workflow timing metrics
workflow_times=$(aggregate_workflow_times)
duration=$(echo "$workflow_times" | jq -r '.workflow_duration_seconds')
echo "Workflow took ${duration}s"

# Get agent performance
agent_perf=$(aggregate_agent_metrics)
total_agents=$(echo "$agent_perf" | jq -r '.total_agents')
echo "Used $total_agents agent types"

# Get complexity evaluation stats
complexity=$(aggregate_complexity_metrics)
agent_rate=$(echo "$complexity" | jq -r '.agent_invocation_rate')
echo "Agent invoked in ${agent_rate}% of complexity evaluations"

# Generate full report
generate_performance_report > performance_report.md
```

### Integration with /analyze Command

The `/analyze` command uses these functions to provide performance insights:

```bash
/analyze agents  # Uses aggregate_agent_metrics()
/analyze patterns  # Uses aggregate_complexity_metrics()
/analyze all  # Uses all aggregation functions
```

### Filtering by Time Period

Extract metrics for specific time windows:

```bash
# Last 24 hours
recent_log=$(grep "$(date -d '24 hours ago' '+%Y-%m-%d')" .claude/logs/adaptive-planning.log)
echo "$recent_log" > /tmp/recent.log

# Temporarily point to filtered log
CLAUDE_PROJECT_DIR_BACKUP="$CLAUDE_PROJECT_DIR"
export CLAUDE_PROJECT_DIR="/tmp"
cp /tmp/recent.log /tmp/.claude/logs/adaptive-planning.log

# Aggregate metrics
aggregate_workflow_times

# Restore
export CLAUDE_PROJECT_DIR="$CLAUDE_PROJECT_DIR_BACKUP"
```

### Dashboard Integration

Use metrics to populate progress dashboard estimates:

```bash
# Get average phase time for estimates
avg_time=$(aggregate_workflow_times | jq -r '.avg_phase_time_seconds')
remaining_phases=$((total_phases - current_phase))
estimated_remaining=$((avg_time * remaining_phases))

# Pass to dashboard
render_dashboard "$plan_name" "$current_phase" "$total_phases" \
  "$phase_list" "$elapsed" "$estimated_remaining" \
  "$current_task" "$test_result" "$wave_info"
```

## API Reference

### aggregate_workflow_times()

Extracts timing data from adaptive-planning.log.

**Usage:**
```bash
workflow_metrics=$(aggregate_workflow_times)
```

**Returns:** JSON object
```json
{
  "workflow_duration_seconds": 1847,
  "total_phases": 8,
  "completed_phases": 6,
  "avg_phase_time_seconds": 307
}
```

**Error handling:**
- Returns `{"error": "Log file not found"}` if log missing
- Returns 0 values if no workflow markers found

**Log markers required:**
- `WORKFLOW_START` - Workflow beginning timestamp
- `WORKFLOW_END` - Workflow completion timestamp
- `PHASE_START` - Phase beginning events
- `PHASE_COMPLETE` - Phase completion events

---

### aggregate_agent_metrics()

Extracts agent performance from agent-registry.json.

**Usage:**
```bash
agent_metrics=$(aggregate_agent_metrics)
```

**Returns:** JSON object
```json
{
  "total_agents": 5,
  "agent_summary": [
    {
      "agent_type": "research-specialist",
      "invocations": 12,
      "successes": 11,
      "failures": 1,
      "success_rate": 91.67,
      "avg_duration": 45.3
    }
  ]
}
```

**Agent registry schema:**
```json
{
  "agents": {
    "agent-type": {
      "invocations": 12,
      "successes": 11,
      "failures": 1,
      "avg_duration": 45.3,
      "last_used": "2025-10-13T14:32:15Z"
    }
  }
}
```

**Error handling:**
- Returns `{"error": "Agent registry not found"}` if registry missing
- Returns 0 success_rate if no invocations recorded

---

### aggregate_complexity_metrics()

Extracts complexity evaluation statistics from log.

**Usage:**
```bash
complexity_metrics=$(aggregate_complexity_metrics)
```

**Returns:** JSON object
```json
{
  "total_evaluations": 24,
  "threshold_only": 18,
  "agent_overrides": 3,
  "hybrid_averages": 3,
  "score_discrepancies": 2,
  "agent_invocation_rate": 25.0
}
```

**Log patterns matched:**
- `evaluation_method.*threshold"` - Threshold-only evaluations
- `evaluation_method.*agent"` - Agent override evaluations
- `evaluation_method.*hybrid"` - Hybrid average evaluations
- `complexity_discrepancy` - Score disagreement events

**Agent invocation rate calculation:**
```
rate = ((agent_overrides + hybrid_averages) / total_evaluations) * 100
```

**Error handling:**
- Returns `{"error": "Log file not found"}` if log missing
- Returns 0 values if no evaluation events found

---

### generate_performance_report()

Creates markdown-formatted performance report.

**Usage:**
```bash
generate_performance_report > report.md
```

**Output:** Markdown text with three sections:
1. Workflow Summary
2. Agent Performance
3. Complexity Evaluation

**Dependencies:**
- Calls `aggregate_workflow_times()`
- Calls `aggregate_agent_metrics()`
- Calls `aggregate_complexity_metrics()`
- Uses `jq` for JSON extraction
- Uses `date` for timestamp formatting

**Report generation:**
- Current timestamp in header
- Duration formatted as minutes + seconds
- Agent summary as bulleted list
- All metrics rounded/formatted for readability

---

## Data Sources

### adaptive-planning.log

**Location:** `.claude/logs/adaptive-planning.log`

**Key markers:**
```
2025-10-13 14:00:00 INFO WORKFLOW_START plan=042_feature.md
2025-10-13 14:05:23 INFO PHASE_START phase=1 name="Setup"
2025-10-13 14:08:45 INFO PHASE_COMPLETE phase=1 duration=202s
2025-10-13 14:30:47 INFO WORKFLOW_END duration=1847s
```

**Complexity evaluation events:**
```
2025-10-13 14:05:30 INFO complexity_evaluation phase=2 evaluation_method="threshold" score=7.2
2025-10-13 14:10:15 INFO complexity_evaluation phase=3 evaluation_method="agent" score=9.1
2025-10-13 14:10:16 INFO complexity_discrepancy phase=3 threshold=6.5 agent=9.1 diff=2.6
```

**Log rotation:**
- Max size: 10MB
- Files retained: 5
- Managed by adaptive-planning-logger.sh

### agent-registry.json

**Location:** `.claude/agents/agent-registry.json`

**Schema:**
```json
{
  "schema_version": "1.0",
  "updated_at": "2025-10-13T14:32:15Z",
  "agents": {
    "research-specialist": {
      "invocations": 12,
      "successes": 11,
      "failures": 1,
      "avg_duration": 45.3,
      "total_duration": 543.6,
      "last_used": "2025-10-13T14:30:00Z",
      "last_error": null
    }
  }
}
```

**Update mechanism:**
- Updated by agent-registry.sh after each invocation
- Duration tracked in seconds (decimal)
- Last error captured for failure debugging

## Integration Examples

### With /implement Workflow

```bash
# At workflow start
log_adaptive_planning "INFO" "WORKFLOW_START" "plan=$plan_file"

# During phase execution
for phase in $(seq 1 "$total_phases"); do
  log_adaptive_planning "INFO" "PHASE_START" "phase=$phase"

  # Execute phase
  execute_phase "$phase"

  log_adaptive_planning "INFO" "PHASE_COMPLETE" "phase=$phase duration=${SECONDS}s"
done

# At workflow end
log_adaptive_planning "INFO" "WORKFLOW_END" "duration=${TOTAL_SECONDS}s"

# Generate report
generate_performance_report > "specs/reports/metrics/$(basename "$plan_file" .md)_performance.md"
```

### With /orchestrate Multi-Agent Workflows

```bash
# Track research phase agents
for topic in "${research_topics[@]}"; do
  agent_start=$(date +%s)

  invoke_agent "research-specialist" "$topic"

  agent_end=$(date +%s)
  agent_duration=$((agent_end - agent_start))

  # Metrics logged automatically by agent-registry.sh
done

# After workflow completion
agent_metrics=$(aggregate_agent_metrics)
echo "$agent_metrics" | jq '.agent_summary[] | select(.agent_type == "research-specialist")'
```

### With /analyze Command

```bash
#!/usr/bin/env bash
# .claude/commands/analyze.md implementation

source .claude/lib/workflow-metrics.sh

analyze_type="${1:-all}"

case "$analyze_type" in
  agents)
    echo "## Agent Performance Analysis"
    aggregate_agent_metrics | jq .
    ;;

  patterns)
    echo "## Complexity Pattern Analysis"
    aggregate_complexity_metrics | jq .
    ;;

  all)
    generate_performance_report
    ;;
esac
```

### Custom Metric Queries

```bash
# Find slowest agent type
aggregate_agent_metrics | \
  jq -r '.agent_summary | sort_by(.avg_duration) | reverse | .[0] |
  "\(.agent_type): \(.avg_duration)s average"'

# Find agent with lowest success rate
aggregate_agent_metrics | \
  jq -r '.agent_summary | sort_by(.success_rate) | .[0] |
  "\(.agent_type): \(.success_rate)% success rate"'

# Calculate total time spent in agents
aggregate_agent_metrics | \
  jq -r '.agent_summary | map(.invocations * .avg_duration) | add |
  "Total agent time: \(.)s"'

# Find complexity evaluation method distribution
aggregate_complexity_metrics | \
  jq -r '"Threshold: \(.threshold_only), Agent: \(.agent_overrides), Hybrid: \(.hybrid_averages)"'
```

## Performance Considerations

- **Log parsing overhead**: Minimal - uses grep for pattern matching
- **JSON processing**: Efficient jq queries with no redundant parsing
- **Memory usage**: Low - streams data without loading full log into memory
- **File I/O**: Read-only operations, no file locking issues

**Optimization tips:**
- Filter logs by date range before aggregation for faster processing
- Cache aggregation results when generating multiple reports
- Use compressed log archives for historical analysis

## Troubleshooting

### No metrics returned

**Check:**
1. Does `.claude/logs/adaptive-planning.log` exist?
2. Does `.claude/agents/agent-registry.json` exist?
3. Are workflow markers present in log?
4. Is log file readable?

**Debug:**
```bash
source .claude/lib/workflow-metrics.sh

# Check log existence
ls -lh "$CLAUDE_PROJECT_DIR/.claude/logs/adaptive-planning.log"

# Check for workflow markers
grep "WORKFLOW_START\|WORKFLOW_END" "$CLAUDE_PROJECT_DIR/.claude/logs/adaptive-planning.log"

# Check registry
cat "$CLAUDE_PROJECT_DIR/.claude/agents/agent-registry.json" | jq .
```

### Zero duration or phase counts

**Cause:** Log markers missing or malformed

**Solution:** Ensure workflow logging is enabled:
```bash
source .claude/lib/adaptive-planning-logger.sh
log_adaptive_planning "INFO" "WORKFLOW_START" "plan=test.md"
```

### Agent metrics empty

**Cause:** Agent registry not initialized or no agents invoked

**Solution:** Check agent registry initialization:
```bash
source .claude/lib/agent-registry.sh
initialize_agent_registry
```

### Invalid JSON output

**Cause:** jq parsing error or missing dependencies

**Debug:**
```bash
# Test jq availability
command -v jq || echo "jq not installed"

# Test JSON validity
aggregate_workflow_times | jq . || echo "Invalid JSON"
```

### Timezone issues with timestamps

**Cause:** Date parsing assumes local timezone

**Solution:** Set TZ environment variable:
```bash
export TZ=UTC
aggregate_workflow_times
```

## Related

- `adaptive-planning-logger.sh` - Logs workflow events parsed by this utility
- `agent-registry.sh` - Maintains agent metrics consumed by this utility
- `complexity-utils.sh` - Logs complexity evaluations tracked here
- `/analyze` command - Primary consumer of these metrics
- `/implement` command - Generates workflow timing data

## Version

Added in Plan 043 Phase 5 (2025-10-13)

Schema: Workflow metrics v1.0
