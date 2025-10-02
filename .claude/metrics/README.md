# Metrics Directory

Automated collection and storage of Claude Code command execution metrics for performance analysis, optimization, and usage pattern identification.

## Purpose

The metrics system provides:

- **Performance tracking** of command execution times
- **Usage patterns** showing frequently used commands
- **Success/failure rates** for reliability monitoring
- **Historical data** for trend analysis
- **Optimization targets** for improvement efforts

## Metrics Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Claude Code Command Execution                               │
│ User runs /implement, /test, /plan, etc.                   │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Stop Hook Event                                             │
│ Command completes, Stop hook triggered                      │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ post-command-metrics.sh                                     │
├─────────────────────────────────────────────────────────────┤
│ • Reads hook JSON (command, duration, status)              │
│ • Generates JSONL entry                                     │
│ • Appends to monthly metrics file                           │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Metrics File (YYYY-MM.jsonl)                               │
│ One file per month, JSONL format                           │
└─────────────────────────────────────────────────────────────┘
```

## Metrics Format

### File Naming
```
YYYY-MM.jsonl
```

Examples:
- `2025-10.jsonl` - October 2025
- `2025-11.jsonl` - November 2025

### JSONL Format
Each line is a JSON object representing one command execution:

```json
{"timestamp":"2025-10-01T12:34:56Z","operation":"implement","duration_ms":15234,"status":"success"}
{"timestamp":"2025-10-01T12:45:23Z","operation":"test","duration_ms":3421,"status":"success"}
{"timestamp":"2025-10-01T13:02:17Z","operation":"plan","duration_ms":8932,"status":"success"}
{"timestamp":"2025-10-01T13:15:44Z","operation":"implement","duration_ms":12456,"status":"error"}
```

### Field Descriptions

- **timestamp**: ISO 8601 UTC timestamp of command completion
- **operation**: Command name (without leading slash)
- **duration_ms**: Execution duration in milliseconds
- **status**: Command result ("success" or "error")

## Metrics Collection

### Automatic Collection
Metrics are collected automatically via the `post-command-metrics.sh` hook registered on the Stop event.

**Hook Input** (JSON via stdin):
```json
{
  "hook_event_name": "Stop",
  "command": "/implement",
  "duration_ms": 15234,
  "status": "success",
  "cwd": "/home/user/project"
}
```

**Hook Output** (appended to metrics file):
```json
{"timestamp":"2025-10-01T12:34:56Z","operation":"implement","duration_ms":15234,"status":"success"}
```

### Collection Logic
1. Hook receives JSON input from Claude Code
2. Extracts command, duration, and status
3. Generates timestamp in UTC
4. Normalizes command name (removes leading slash)
5. Creates JSONL entry
6. Appends to current month's metrics file
7. Creates metrics directory if needed
8. Always exits 0 (non-blocking)

### Monthly Rotation
Metrics files rotate automatically by month:
- October data goes to `2025-10.jsonl`
- November data goes to `2025-11.jsonl`
- No manual rotation needed

## Analyzing Metrics

### View Current Month
```bash
# Show all metrics for current month
cat .claude/metrics/$(date +%Y-%m).jsonl

# Pretty print with jq
cat .claude/metrics/$(date +%Y-%m).jsonl | jq
```

### Count Commands
```bash
# Total commands this month
wc -l .claude/metrics/$(date +%Y-%m).jsonl

# Commands by operation
cat .claude/metrics/$(date +%Y-%m).jsonl | jq -r '.operation' | sort | uniq -c | sort -rn
```

### Average Duration
```bash
# Average duration per operation
cat .claude/metrics/*.jsonl | jq -s '
  group_by(.operation) |
  map({
    operation: .[0].operation,
    count: length,
    avg_ms: (map(.duration_ms) | add / length | floor),
    total_ms: (map(.duration_ms) | add)
  }) |
  sort_by(-.count)
'
```

### Success Rate
```bash
# Success rate by operation
cat .claude/metrics/*.jsonl | jq -s '
  group_by(.operation) |
  map({
    operation: .[0].operation,
    total: length,
    success: (map(select(.status == "success")) | length),
    error: (map(select(.status == "error")) | length),
    success_rate: ((map(select(.status == "success")) | length) / length * 100 | floor)
  })
'
```

### Slow Commands
```bash
# Find slowest command executions
cat .claude/metrics/*.jsonl | jq -s 'sort_by(-.duration_ms) | .[0:10]'
```

### Usage Over Time
```bash
# Commands per day
cat .claude/metrics/*.jsonl | jq -r '.timestamp' | cut -d'T' -f1 | sort | uniq -c
```

### Error Analysis
```bash
# Show all errors
cat .claude/metrics/*.jsonl | jq 'select(.status == "error")'

# Errors by operation
cat .claude/metrics/*.jsonl | jq -r 'select(.status == "error") | .operation' | sort | uniq -c
```

## Metrics Reports

### Monthly Summary
```bash
#!/usr/bin/env bash
# Generate monthly metrics summary

MONTH=$(date +%Y-%m)
METRICS_FILE=".claude/metrics/$MONTH.jsonl"

echo "Metrics Summary for $MONTH"
echo "=============================="
echo ""

echo "Total Commands: $(wc -l < "$METRICS_FILE")"
echo ""

echo "Commands by Type:"
cat "$METRICS_FILE" | jq -r '.operation' | sort | uniq -c | sort -rn
echo ""

echo "Average Duration by Operation:"
cat "$METRICS_FILE" | jq -s 'group_by(.operation) | map({op: .[0].operation, avg_ms: (map(.duration_ms) | add / length | floor)}) | .[] | "\(.op): \(.avg_ms)ms"'
echo ""

echo "Success Rate:"
TOTAL=$(wc -l < "$METRICS_FILE")
SUCCESS=$(grep -c '"success"' "$METRICS_FILE")
echo "$SUCCESS / $TOTAL ($(($SUCCESS * 100 / $TOTAL))%)"
```

### Performance Trends
```bash
#!/usr/bin/env bash
# Show performance trends over time

for file in .claude/metrics/*.jsonl; do
  month=$(basename "$file" .jsonl)
  avg=$(cat "$file" | jq -s 'map(.duration_ms) | add / length | floor')
  echo "$month: ${avg}ms average"
done
```

## Optimization Use Cases

### Identify Slow Commands
Use metrics to find commands that take too long:

```bash
# Commands averaging over 10 seconds
cat .claude/metrics/*.jsonl | jq -s '
  group_by(.operation) |
  map({
    operation: .[0].operation,
    avg_ms: (map(.duration_ms) | add / length)
  }) |
  map(select(.avg_ms > 10000))
'
```

### Find Failing Commands
Identify commands with high error rates:

```bash
# Commands with >10% error rate
cat .claude/metrics/*.jsonl | jq -s '
  group_by(.operation) |
  map({
    operation: .[0].operation,
    error_rate: ((map(select(.status == "error")) | length) / length * 100)
  }) |
  map(select(.error_rate > 10))
'
```

### Usage Patterns
Understand which commands are used most:

```bash
# Top 5 most used commands
cat .claude/metrics/*.jsonl | jq -r '.operation' | sort | uniq -c | sort -rn | head -5
```

## Maintenance

### Cleanup Old Metrics
```bash
# Remove metrics older than 6 months
find .claude/metrics -name "*.jsonl" -mtime +180 -delete
```

### Archive Metrics
```bash
# Archive old metrics
mkdir -p .claude/metrics/archive
mv .claude/metrics/2024-*.jsonl .claude/metrics/archive/
```

### Export Metrics
```bash
# Export to CSV
cat .claude/metrics/*.jsonl | jq -r '[.timestamp, .operation, .duration_ms, .status] | @csv' > metrics.csv
```

## Integration with Tools

### Custom Analysis Scripts
Create custom analysis tools in `.claude/bin/`:

```bash
#!/usr/bin/env bash
# .claude/bin/analyze-metrics.sh

# Your custom metrics analysis
cat .claude/metrics/*.jsonl | jq -s 'your-analysis-here'
```

### Metrics Specialist Agent
Use the metrics-specialist agent for detailed analysis:

```markdown
I'll analyze the metrics using the metrics-specialist agent.

Task: Analyze October 2025 metrics
Focus: Performance trends, slow commands, error rates
Output: Report with optimization recommendations
```

## Privacy and Security

### Data Stored
Metrics contain:
- **Command names**: Which commands were run
- **Timestamps**: When commands were run
- **Durations**: How long commands took
- **Status**: Success or error

Metrics do NOT contain:
- Command arguments
- File contents
- User input
- File paths
- Error messages

### Local Storage
- Metrics are stored locally in `.claude/metrics/`
- Never transmitted externally
- Not included in git by default (should be in .gitignore)

### Sensitive Operations
If you have sensitive command names, consider:
- Adding `.claude/metrics/` to `.gitignore`
- Periodically cleaning old metrics
- Using generic operation names

## Troubleshooting

### No Metrics Being Collected

**Check 1: Hook Registered**
```bash
cat .claude/settings.local.json | jq '.hooks.Stop'
# Should show post-command-metrics.sh
```

**Check 2: Hook Executable**
```bash
ls -l .claude/hooks/post-command-metrics.sh
# Should have execute permission
```

**Check 3: Metrics Directory**
```bash
ls -la .claude/metrics/
# Should exist and be writable
```

**Check 4: Test Hook Manually**
```bash
echo '{"hook_event_name":"Stop","command":"/test","duration_ms":1000,"status":"success"}' | \
  .claude/hooks/post-command-metrics.sh

# Check if entry added
tail -1 .claude/metrics/$(date +%Y-%m).jsonl
```

### Metrics File Corruption

**Check JSONL Format**
```bash
# Validate each line is valid JSON
while IFS= read -r line; do
  echo "$line" | jq empty || echo "Invalid: $line"
done < .claude/metrics/$(date +%Y-%m).jsonl
```

**Repair Corrupted File**
```bash
# Extract valid JSON lines
grep '^{.*}$' .claude/metrics/2025-10.jsonl > .claude/metrics/2025-10.jsonl.tmp
mv .claude/metrics/2025-10.jsonl.tmp .claude/metrics/2025-10.jsonl
```

## Documentation Standards

All metrics documentation follows standards:

- **NO emojis** in file content
- **Unicode box-drawing** for diagrams
- **Clear examples** with syntax highlighting
- **CommonMark** specification

See [/home/benjamin/.config/nvim/docs/GUIDELINES.md](../../nvim/docs/GUIDELINES.md) for complete standards.

## Navigation

### Related
- [← Parent Directory](../README.md)
- [hooks/](../hooks/README.md) - Metrics collection hook
- [agents/metrics-specialist.md](../agents/metrics-specialist.md) - Metrics analysis agent

### Configuration
- [settings.local.json](../settings.local.json) - Hook registration

## Quick Reference

### Common Commands
```bash
# View current month
cat .claude/metrics/$(date +%Y-%m).jsonl | jq

# Count by operation
cat .claude/metrics/*.jsonl | jq -r '.operation' | sort | uniq -c

# Average duration
cat .claude/metrics/*.jsonl | jq -s 'map(.duration_ms) | add / length'

# Success rate
cat .claude/metrics/*.jsonl | jq -s 'map(select(.status == "success")) | length'

# Slowest commands
cat .claude/metrics/*.jsonl | jq -s 'sort_by(-.duration_ms) | .[0:10]'

# Errors only
cat .claude/metrics/*.jsonl | jq 'select(.status == "error")'
```

### Analysis Examples
```bash
# Which command is slowest on average?
cat .claude/metrics/*.jsonl | jq -s 'group_by(.operation) | map({op: .[0].operation, avg: (map(.duration_ms) | add / length)}) | sort_by(-.avg) | .[0]'

# Which day had most activity?
cat .claude/metrics/*.jsonl | jq -r '.timestamp' | cut -d'T' -f1 | sort | uniq -c | sort -rn | head -1

# Error rate per command
cat .claude/metrics/*.jsonl | jq -s 'group_by(.operation) | map({op: .[0].operation, errors: map(select(.status == "error")) | length, total: length}) | map({op: .op, rate: (.errors / .total * 100)})'
```
