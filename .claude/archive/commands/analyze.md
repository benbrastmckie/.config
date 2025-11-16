---
allowed-tools: Read, Bash
argument-hint: [type] [search-pattern]
description: Analyze system performance metrics and patterns (agents, patterns, or all)
command-type: utility
---

# Analyze System Performance

I'll analyze system performance metrics based on the specified type.

## Usage

```bash
/analyze [type] [search-pattern]
```

**Types**:
- `agents` - Analyze agent performance metrics and efficiency
- `metrics` - Analyze command metrics, bottlenecks, and usage trends
- `patterns` - (Not implemented) Reserved for future workflow pattern analysis
- `all` - Analyzes both agents and metrics

**Search Pattern** (optional): Filter results by keyword

## Examples

```bash
# Analyze agent performance
/analyze agents           # Last 30 days (default)
/analyze agents 7         # Last 7 days
/analyze agents 90        # Last 90 days

# Analyze command metrics
/analyze metrics          # Last 30 days (default)
/analyze metrics 7        # Last 7 days
/analyze metrics 90       # Last 90 days

# Analyze workflow patterns
/analyze patterns

# Analyze everything
/analyze all
/analyze  # Same as 'all'

# Filter patterns by keyword
/analyze patterns auth
/analyze patterns feature
```

## Analysis Types

### Agent Analysis (`/analyze agents [timeframe]`)

Analyzes agent performance metrics from both the agent registry and per-invocation JSONL metrics, providing detailed insights with tool usage patterns and error analysis.

**Usage**:
```bash
/analyze agents        # Last 30 days (default)
/analyze agents 7      # Last 7 days
/analyze agents 90     # Last 90 days
```

**Process**:

1. **Load Agent Data**
   - Read `.claude/agents/agent-registry.json` for aggregate metrics
   - Parse `.claude/data/metrics/agents/*.jsonl` for detailed per-invocation data
   - Filter by timeframe (default: 30 days)

2. **Calculate Comprehensive Statistics**
   - Overall success/failure rates
   - Duration statistics (avg, min, max, median)
   - Tool usage aggregation and percentages
   - Error type classification and counts
   - Recent performance trends (7-day vs 30-day)

3. **Calculate Efficiency Scores**
   - Formula: `efficiency_score = (success_rate × 0.6) + (duration_score × 0.4)`
   - Duration score: `min(1.0, target_duration / actual_avg_duration)`

4. **Target Durations by Agent Type**:
   - research-specialist: 15000ms (15s)
   - plan-architect: 20000ms (20s)
   - code-writer: 12000ms (12s)
   - test-specialist: 10000ms (10s)
   - debug-assistant: 8000ms (8s)
   - doc-writer: 8000ms (8s)
   - default: 10000ms (10s)

5. **Generate Enhanced Performance Report**:
   - Overall agent performance rankings with efficiency scores
   - Star ratings (★★★★★) for visual assessment
   - Success rates with detailed breakdown (successes/total)
   - Average durations with trend indicators (↑↓)
   - **Tool usage analysis** with ASCII bar charts
   - **Common errors** with examples and occurrence counts
   - **Performance trends** comparing recent to overall
   - **Data-driven recommendations** for improvements

6. **Identify Issues**:
   - Low Success Rate (<90%): Agent frequently fails
   - Slow Execution: Agent exceeds target duration by >50%
   - High Error Count: Specific error types recurring
   - Declining Performance: Recent metrics worse than overall
   - No Recent Activity: Agent not used recently

**Enhanced Output Example**:
```
=== Agent Performance Analysis ===
Timeframe: Last 30 days
Generated: 2025-10-11 15:30:22

Overall Rankings:
1. ★★★★★ research-specialist (94% efficiency)
   Success: 98% (240/245) | Avg Duration: 13.2s | Invocations: 245
   Status: Excellent performance

   Tool Usage (top 3):
   Read            ████████████████████  45% (108 calls)
   WebSearch       █████████████         30% (72 calls)
   Write           ███████               15% (36 calls)

   Recent Performance:
   - Last 7 days: 96% success (23/24)
   - Avg duration trend: ↓ improving (was 14.1s)

2. ★★★★☆ code-writer (82% efficiency)
   Success: 95% (179/189) | Avg Duration: 14.8s | Invocations: 189
   Status: Good performance

   Tool Usage (top 3):
   Edit            ████████████████      40% (302 calls)
   Read            ██████████████        35% (264 calls)
   Bash            ██████                15% (113 calls)

   Common Errors:
   - syntax_error: 5 occurrences
   - test_failure: 3 occurrences

   Recommendation: Review syntax validation before commits

3. ★★★☆☆ test-specialist (68% efficiency)
   Success: 85% (57/67) | Avg Duration: 15.2s | Invocations: 67
   ⚠ Needs attention: Below target efficiency (75%)

   Tool Usage (top 3):
   Bash            ████████████████████████  60% (241 calls)
   Read            ██████████                25% (100 calls)
   Grep            ████                      10% (40 calls)

   Common Errors:
   - test_failure: 7 occurrences
     Example: `Test execution failed: Command 'npm test' exited with code 1`
   - timeout: 3 occurrences
     Example: `Test timeout after 30s`

   Recommendation: Investigate test timeout issues, optimize test execution

---

Detailed Reports:
Run `/analyze agents <agent-name>` for agent-specific details
Run `/analyze agents --compare <agent1> <agent2>` for side-by-side comparison
```

**Analysis Functions** (from `.claude/lib/analyze-metrics.sh`):
- `parse_agent_jsonl(agent_type, timeframe)` - Extract JSONL records
- `calculate_agent_stats(agent_type, timeframe)` - Compute statistics
- `identify_common_errors(agent_type, timeframe)` - Error analysis
- `analyze_tool_usage(agent_type, timeframe)` - Tool usage with ASCII charts

### Metrics Analysis (`/analyze metrics [timeframe]`)

Analyzes command execution metrics, identifies bottlenecks, and provides data-driven optimization recommendations.

**Process**:

1. **Load Metrics Data**
   - Read from `.claude/data/metrics/*.jsonl`
   - Filter by timeframe (default: 30 days)
   - Parse JSONL format with jq

2. **Analyze Usage Trends**
   - Count operations by type
   - Calculate success rates
   - Generate ASCII bar charts for visualization
   - Identify most-used commands

3. **Identify Bottlenecks**
   - Find slowest operations (top 5)
   - Identify most common failures
   - Calculate failure rates by operation type

4. **Template Effectiveness**
   - Compare template vs manual planning times
   - Calculate time savings percentage
   - Assess template adoption rate

5. **Generate Recommendations**
   - Suggest optimizations for slow operations
   - Recommend improvements for high-failure commands
   - Identify template creation opportunities

**Arguments**:
- `timeframe` (optional): Days to analyze (default: 30)
  - Examples: `7`, `30`, `90`

**Output Example**:
```
=== Metrics Analysis Report ===

Generated: 2025-10-09 16:45:23
Timeframe: Last 30 days

---

## Usage Trends (Last 30 Days)

### Command Usage

plan                      45 ████████████████████████████████████████
implement                 38 ████████████████████████████████████
plan-from-template        25 ███████████████████████████
test                      20 ████████████████████████
report                    15 ██████████████████

### Success Rate

- Total operations: 143
- Successful: 135
- Success rate: 94%

## Performance Bottlenecks

### Slowest Operations

- implement: 180s (180000ms)
- plan: 45s (45000ms)
- report: 30s (30000ms)
- setup: 12s (12000ms)
- test: 8s (8000ms)

### Most Common Failures

- test: 5 failures
- implement: 3 failures

## Template Effectiveness Analysis

- Template-based planning: 15s average
- Manual planning: 45s average
- Time savings: 67% faster with templates

## Optimization Recommendations

### High-Failure Operations

- **test**: 5 failures detected
  - Review error handling and validation
  - Add defensive checks for edge cases
  - Consider adding pre-flight validation

### Performance Optimization Opportunities

- **implement**: 180s average
  - Profile for bottlenecks
  - Consider caching frequently accessed data
  - Review I/O operations for optimization

### Template Adoption

- Manual planning used 45 times vs 25 template-based
  - Consider creating templates for common patterns
  - Review recent manual plans for template opportunities
  - Promote template usage for faster planning
```

**Report Generation**:

The command can optionally save reports to `specs/reports/`:

```bash
# Generate and save report
source .claude/lib/analyze-metrics.sh
REPORT_NUM=$(ls specs/reports/*.md 2>/dev/null | grep -o '[0-9]\{3\}' | sort -n | tail -1 | awk '{printf "%03d", $1+1}')
REPORT_NUM=${REPORT_NUM:-001}
generate_metrics_report 30 "specs/reports/${REPORT_NUM}_metrics_analysis.md"
```

### Pattern Analysis (`/analyze patterns`)

**Status**: Not Implemented

This feature was planned for analyzing workflow patterns from historical learning data, but the learning system was removed due to:
- Limited value in single-user environment
- High maintenance complexity
- Cold start problem (requires months of data)
- Better alternatives (templates provide reliable patterns upfront)

**Alternative Approaches**:
- Use `/plan-from-template` for proven workflow patterns
- Review project metrics in `.claude/data/metrics/*.jsonl` manually
- Consult implementation summaries in `specs/summaries/` for successful workflows

**Reserved for Future**:
If workflow pattern analysis is needed in the future, consider:
- External analytics tools (process metrics JSONL files)
- Metrics visualization dashboard
- Multi-user collaborative learning (team-wide patterns)

### Combined Analysis (`/analyze all`)

**Behavior**: Runs both agent and metrics analysis

Executes comprehensive system analysis including:
1. Agent performance analysis (see Agent Analysis section)
2. Command metrics analysis (see Metrics Analysis section)

Pattern analysis is not implemented (see Pattern Analysis section).

**Output**:
Combined output from `/analyze agents` and `/analyze metrics` with a separator between sections.

## Integration with Other Commands

This command helps optimize the agential system by:

**For Users**:
- Understand which agents perform best
- Identify agents needing optimization
- Guide workflow improvements

**For System**:
- Guide agent improvements
- Inform adaptive planning decisions

## Notes

- Analysis requires historical data from agent registry
- First run may show limited data if agents haven't been used
- Recommendations improve as more agents are invoked
- Use findings to refine agent usage and workflows

## Migration Note

**Previous Commands**:
- `/analyze-agents` → Use `/analyze agents`
- `/analyze-patterns` → Use `/analyze patterns`

These commands have been consolidated into `/analyze [type]` for a cleaner interface.
