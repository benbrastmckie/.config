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
- `patterns` - Analyze workflow patterns and learning data
- `all` - Analyze both agents and patterns (default)

**Search Pattern** (optional): Filter results by keyword

## Examples

```bash
# Analyze agent performance
/analyze agents

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

### Agent Analysis (`/analyze agents`)

Analyzes agent performance metrics from the agent registry and provides actionable insights.

**Process**:

1. **Read Agent Registry**
   - Load `.claude/agents/agent-registry.json`
   - Extract performance metrics for all agents

2. **Calculate Efficiency Scores**
   - Formula: `efficiency_score = (success_rate × 0.6) + (duration_score × 0.4)`
   - Duration score: `min(1.0, target_duration / actual_avg_duration)`

3. **Target Durations by Agent Type**:
   - research-specialist: 15000ms (15s)
   - plan-architect: 20000ms (20s)
   - code-writer: 12000ms (12s)
   - test-specialist: 10000ms (10s)
   - debug-assistant: 8000ms (8s)
   - doc-writer: 8000ms (8s)
   - default: 10000ms (10s)

4. **Generate Performance Report**:
   - Overall agent performance rankings
   - Efficiency scores with star ratings (★★★★★)
   - Success rates and average durations
   - Agents needing attention (efficiency < 75%)
   - Specific recommendations for underperformers

5. **Identify Issues**:
   - Low Success Rate (<90%): Agent frequently fails
   - Slow Execution: Agent exceeds target duration by >50%
   - High Variability: Inconsistent performance
   - No Recent Activity: Agent not used recently

**Output Example**:
```
=== Agent Performance Analysis ===

Overall Rankings:
1. ★★★★★ research-specialist (94% efficiency)
   Success: 98% | Avg Duration: 13.2s | Invocations: 245
   Status: Excellent performance

2. ★★★★☆ code-writer (82% efficiency)
   Success: 95% | Avg Duration: 14.8s | Invocations: 189
   Status: Good performance

3. ★★★☆☆ test-specialist (68% efficiency)
   Success: 85% | Avg Duration: 15.2s | Invocations: 67
   ⚠ Needs attention: Below target efficiency (75%)

Recommendations:
- test-specialist: Consider optimizing test detection logic
- debug-assistant: Increase success rate (currently 88%)
```

### Pattern Analysis (`/analyze patterns`)

Analyzes learning data to provide insights on workflow patterns, success rates, and optimization opportunities.

**Process**:

1. **Load Learning Data**
   - Patterns: `.claude/learning/patterns.jsonl`
   - Antipatterns: `.claude/learning/antipatterns.jsonl`
   - Optimizations: `.claude/learning/optimizations.jsonl`

2. **Filter by Search Pattern** (if provided)
   - Match workflow names, descriptions, or context
   - Show only relevant patterns

3. **Aggregate Statistics**
   - Success rate by workflow type
   - Common failure modes
   - Average execution time
   - Most frequent patterns

4. **Identify Trends**
   - Improving patterns (success rate increasing)
   - Degrading patterns (success rate decreasing)
   - Emerging patterns (new workflows)

5. **Generate Insights**
   - Most reliable workflows
   - Common antipatterns to avoid
   - Suggested optimizations
   - Workflow improvement opportunities

**Output Example**:
```
=== Workflow Pattern Analysis ===

Learning Data Summary:
- Success patterns: 45
- Failure patterns: 12
- Optimizations: 8

Top Patterns:
1. Feature Implementation (32 occurrences, 94% success)
   Avg Duration: 18.5 minutes
   Best Practice: Use /plan before /implement

2. Bug Fix Workflow (28 occurrences, 89% success)
   Avg Duration: 12.3 minutes
   Best Practice: Use /debug to analyze before fixing

Common Antipatterns:
- Skipping tests before commit (15 failures)
- Large uncommitted changes (8 failures)

Recommendations:
- Always run /test before commits
- Break large changes into smaller phases
```

### Combined Analysis (`/analyze all`)

Runs both agent and pattern analysis, providing a comprehensive view of system performance.

**Output**:
```
=== Comprehensive System Analysis ===

[Agent Performance section]
[Pattern Analysis section]

=== Overall System Health ===
- Agent Efficiency: 85% average
- Workflow Success Rate: 91%
- System Status: Healthy

Top Recommendations:
1. [Highest priority recommendation across both analyses]
2. [Second priority]
3. [Third priority]
```

## Integration with Other Commands

This command helps optimize the agential system by:

**For Users**:
- Understand which agents perform best
- Learn which workflows are most reliable
- Identify areas for improvement

**For System**:
- Guide agent improvements
- Inform adaptive planning decisions
- Support continuous learning

## Notes

- Analysis requires historical data (agent invocations, workflow completions)
- First run may show limited data
- Recommendations improve as more data is collected
- Use findings to refine workflows and agent usage

## Migration Note

**Previous Commands**:
- `/analyze-agents` → Use `/analyze agents`
- `/analyze-patterns` → Use `/analyze patterns`

These commands have been consolidated into `/analyze [type]` for a cleaner interface.
