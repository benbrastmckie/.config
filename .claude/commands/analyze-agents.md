---
allowed-tools: Read, Bash
description: Analyze agent performance metrics and generate insights report
command-type: utility
---

# Analyze Agent Performance

I'll analyze agent performance metrics from the agent registry and provide actionable insights.

## Process

### 1. Read Agent Registry
I'll read `.claude/agents/agent-registry.json` to load all agent performance metrics.

### 2. Calculate Efficiency Scores
For each agent, I'll calculate an efficiency score using:

```
efficiency_score = (success_rate × 0.6) + (duration_score × 0.4)

where:
  duration_score = min(1.0, target_duration / actual_avg_duration)
```

**Target Durations by Agent Type:**
- research-specialist: 15000ms (15s)
- plan-architect: 20000ms (20s)
- code-writer: 12000ms (12s)
- test-specialist: 10000ms (10s)
- debug-assistant: 8000ms (8s)
- doc-writer: 8000ms (8s)
- default: 10000ms (10s)

### 3. Generate Performance Report
The report will include:
- Overall agent performance rankings
- Efficiency scores with star ratings (★★★★★)
- Success rates and average durations
- Agents needing attention (efficiency < 75%)
- Specific recommendations for underperformers

### 4. Identify Issues
Common issues to check:
- **Low Success Rate (<90%)**: Agent frequently fails
- **Slow Execution**: Agent exceeds target duration by >50%
- **High Variability**: Inconsistent performance
- **No Recent Activity**: Agent not used recently

### 5. Provide Recommendations
Based on detected issues, I'll suggest:
- Configuration adjustments (timeouts, retries)
- Prompt improvements
- Tool selection optimization
- Agent redesign suggestions

## Report Format

```markdown
# Agent Performance Report

**Analysis Date**: [YYYY-MM-DD HH:MM UTC]
**Registry Updated**: [last_updated from metadata]

## Performance Summary

| Agent | Efficiency | Success Rate | Avg Duration | Status |
|-------|-----------|--------------|--------------|---------|
| research-specialist | ★★★★★ 94% | 98.7% | 12.4s | ✓ Good |
| code-writer | ★★★★☆ 89% | 95.6% | 13.8s | ✓ Good |
| plan-architect | ★★★★☆ 91% | 93.2% | 18.2s | ✓ Good |
| test-specialist | ★★★☆☆ 76% | 88.1% | 14.5s | ⚠ Needs Attention |

## Detailed Analysis

### research-specialist
- **Efficiency**: 94% (★★★★★)
- **Success Rate**: 98.7% (156/158 successful)
- **Avg Duration**: 12.4s (target: 15s)
- **Last Execution**: 2025-10-03 18:45:00Z
- **Status**: ✓ Performing well

### test-specialist
- **Efficiency**: 76% (★★★☆☆)
- **Success Rate**: 88.1% (45/51 successful)
- **Avg Duration**: 14.5s (target: 10s)
- **Last Execution**: 2025-10-03 17:30:00Z
- **Status**: ⚠ Needs attention

**Issues Detected**:
- Success rate below 90% threshold
- Execution 45% slower than target
- 6 failures in last 51 invocations

**Recommendations**:
- Review timeout settings, consider increasing to 15s
- Analyze recent failures for common patterns
- Check test environment stability
- Consider adding retry logic for flaky test detection

## Overall Health

- **Total Agents**: 4
- **Healthy Agents** (>85% efficiency): 3
- **Needs Attention** (<85% efficiency): 1
- **Total Invocations**: 312
- **Overall Success Rate**: 94.2%

## Recommendations

1. **test-specialist**: Investigate timeout issues and test environment
2. **General**: Continue monitoring, performance is generally strong
3. **Next Review**: Schedule analysis after 50 more invocations
```

## Edge Cases

### No Agent Data
If agent-registry.json is empty or doesn't exist:
```
No agent performance data available yet.

To start collecting metrics:
1. Run workflows that use agents (/orchestrate, /plan, /implement)
2. Agent metrics will be automatically collected via SubagentStop hook
3. Re-run /analyze-agents after some agent activity
```

### Single Agent
If only one agent has data, provide focused analysis on that agent.

### Fresh Registry
If agents have very few invocations (<5), note that statistics may not be reliable yet.

## Usage Examples

```bash
# Basic usage
/analyze-agents

# After running several workflows
/orchestrate "Feature requiring research and planning"
/implement some_plan.md
/analyze-agents  # See updated metrics
```

## Implementation Notes

- Efficiency scoring weights success (60%) higher than speed (40%)
- Star ratings: ★★★★★ (90%+), ★★★★☆ (80-89%), ★★★☆☆ (70-79%), ★★☆☆☆ (60-69%), ★☆☆☆☆ (<60%)
- Agents with <5 invocations show a warning about limited data
- Duration targets are configurable based on agent complexity
- Report focuses on actionable recommendations, not just data

Let me analyze your agent performance metrics.
