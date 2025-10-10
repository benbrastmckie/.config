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
- `patterns` - (Not implemented) Reserved for future workflow pattern analysis
- `all` - Currently equivalent to `agents` only

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

**Status**: Not Implemented

This feature was planned for analyzing workflow patterns from historical learning data, but the learning system was removed (see Plan 034) due to:
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

**Current Behavior**: Equivalent to `/analyze agents`

Currently runs only agent performance analysis. Pattern analysis is not implemented (see Pattern Analysis section above).

**Output**:
Same as `/analyze agents` output.

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
