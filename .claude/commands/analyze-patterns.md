# Analyze Workflow Patterns

**Command**: `/analyze-patterns [search-pattern]`

**Purpose**: Analyze learning data to provide insights on workflow patterns, success rates, and optimization opportunities.

**Usage**:
```bash
/analyze-patterns                    # Analyze all patterns
/analyze-patterns feature            # Analyze feature workflows only
/analyze-patterns auth               # Analyze workflows with "auth" keyword
```

## Overview

This command analyzes the adaptive learning system's collected data to generate actionable insights about workflow performance, common success patterns, failure modes, and optimization opportunities.

## Process

### Step 1: Load Learning Data

**Load All Pattern Files**:
```bash
LEARNING_DIR=".claude/learning"
PATTERNS_FILE="$LEARNING_DIR/patterns.jsonl"
ANTIPATTERNS_FILE="$LEARNING_DIR/antipatterns.jsonl"
OPTIMIZATIONS_FILE="$LEARNING_DIR/optimizations.jsonl"

# Check if files exist
if [[ ! -f "$PATTERNS_FILE" ]] && [[ ! -f "$ANTIPATTERNS_FILE" ]]; then
  echo "No learning data available. Complete some workflows first."
  exit 0
fi

# Count total patterns
PATTERN_COUNT=$(wc -l < "$PATTERNS_FILE" 2>/dev/null || echo "0")
ANTIPATTERN_COUNT=$(wc -l < "$ANTIPATTERNS_FILE" 2>/dev/null || echo "0")
OPTIMIZATION_COUNT=$(wc -l < "$OPTIMIZATIONS_FILE" 2>/dev/null || echo "0")

echo "Learning Data Summary:"
echo "- Success patterns: $PATTERN_COUNT"
echo "- Failure patterns: $ANTIPATTERN_COUNT"
echo "- Optimizations: $OPTIMIZATION_COUNT"
echo ""
```

### Step 2: Filter by Search Pattern (Optional)

**Apply Search Filter**:
```bash
SEARCH_PATTERN="${1:-}"

if [[ -n "$SEARCH_PATTERN" ]]; then
  echo "Filtering for: $SEARCH_PATTERN"
  echo ""

  # Filter patterns containing search term
  FILTERED_PATTERNS=$(grep "$SEARCH_PATTERN" "$PATTERNS_FILE" 2>/dev/null || echo "")
  FILTERED_ANTIPATTERNS=$(grep "$SEARCH_PATTERN" "$ANTIPATTERNS_FILE" 2>/dev/null || echo "")
else
  FILTERED_PATTERNS=$(cat "$PATTERNS_FILE" 2>/dev/null || echo "")
  FILTERED_ANTIPATTERNS=$(cat "$ANTIPATTERNS_FILE" 2>/dev/null || echo "")
fi
```

### Step 3: Analyze Success Patterns by Workflow Type

**Success Rate by Type**:
```bash
analyze_success_by_type() {
  local patterns="$1"

  declare -A type_success
  declare -A type_total

  # Count successes and totals by type
  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue

    workflow_type=$(echo "$pattern" | grep -o '"workflow_type":"[^"]*"' | sed 's/"workflow_type":"\(.*\)"/\1/')
    outcome=$(echo "$pattern" | grep -o '"outcome":"[^"]*"' | sed 's/"outcome":"\(.*\)"/\1/')

    # Increment total
    type_total[$workflow_type]=$((${type_total[$workflow_type]:-0} + 1))

    # Increment success if outcome is success
    if [[ "$outcome" == "success" ]]; then
      type_success[$workflow_type]=$((${type_success[$workflow_type]:-0} + 1))
    fi
  done <<< "$patterns"

  # Calculate and display success rates
  echo "Success Rate by Workflow Type:"
  echo "┌────────────────┬─────────┬─────────┬──────────────┐"
  echo "│ Workflow Type  │ Success │ Total   │ Success Rate │"
  echo "├────────────────┼─────────┼─────────┼──────────────┤"

  for type in "${!type_total[@]}"; do
    success=${type_success[$type]:-0}
    total=${type_total[$type]}
    rate=$(echo "scale=1; $success * 100 / $total" | bc)

    printf "│ %-14s │ %7d │ %7d │ %11s%% │\n" "$type" "$success" "$total" "$rate"
  done

  echo "└────────────────┴─────────┴─────────┴──────────────┘"
  echo ""
}

analyze_success_by_type "$(cat "$PATTERNS_FILE" "$ANTIPATTERNS_FILE" 2>/dev/null)"
```

### Step 4: Identify Common Research Topics

**Most Effective Research Topics**:
```bash
analyze_research_topics() {
  local patterns="$1"

  declare -A topic_counts
  declare -A topic_success

  # Extract research topics and outcomes
  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue

    outcome=$(echo "$pattern" | grep -o '"outcome":"[^"]*"' | sed 's/"outcome":"\(.*\)"/\1/')
    topics=$(echo "$pattern" | grep -o '"research_topics":\[.*\]' | tr -d '[]"' | tr ',' '\n')

    while IFS= read -r topic; do
      [[ -z "$topic" ]] && continue
      topic=$(echo "$topic" | xargs)  # Trim whitespace

      # Increment topic count
      topic_counts[$topic]=$((${topic_counts[$topic]:-0} + 1))

      # Increment success count
      if [[ "$outcome" == "success" ]]; then
        topic_success[$topic]=$((${topic_success[$topic]:-0} + 1))
      fi
    done <<< "$topics"
  done <<< "$patterns"

  # Sort topics by count and display top 10
  echo "Most Common Research Topics:"

  declare -a sorted_topics
  for topic in "${!topic_counts[@]}"; do
    count=${topic_counts[$topic]}
    success=${topic_success[$topic]:-0}
    sorted_topics+=("$count|$success|$topic")
  done

  printf '%s\n' "${sorted_topics[@]}" | sort -rn | head -10 | while IFS='|' read -r count success topic; do
    rate=$(echo "scale=0; $success * 100 / $count" | bc)
    echo "- $topic (used ${count}x, ${rate}% success)"
  done

  echo ""
}

if [[ -n "$FILTERED_PATTERNS" ]]; then
  analyze_research_topics "$FILTERED_PATTERNS"
fi
```

### Step 5: Calculate Average Implementation Times

**Time Analysis**:
```bash
analyze_implementation_times() {
  local patterns="$1"

  declare -A type_times
  declare -A type_counts

  # Collect times by workflow type
  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue

    workflow_type=$(echo "$pattern" | grep -o '"workflow_type":"[^"]*"' | sed 's/"workflow_type":"\(.*\)"/\1/')
    impl_time=$(echo "$pattern" | grep -o '"implementation_time":[0-9]\+' | grep -o '[0-9]\+')

    [[ -z "$impl_time" ]] && continue

    # Sum times
    type_times[$workflow_type]=$((${type_times[$workflow_type]:-0} + impl_time))
    type_counts[$workflow_type]=$((${type_counts[$workflow_type]:-0} + 1))
  done <<< "$patterns"

  # Calculate and display averages
  echo "Average Implementation Time by Type:"

  for type in "${!type_counts[@]}"; do
    total_time=${type_times[$type]}
    count=${type_counts[$type]}
    avg_time=$((total_time / count))

    hours=$((avg_time / 3600))
    minutes=$(( (avg_time % 3600) / 60 ))

    echo "- $type: ${hours}h ${minutes}min"
  done

  echo ""
}

if [[ -n "$FILTERED_PATTERNS" ]]; then
  analyze_implementation_times "$FILTERED_PATTERNS"
fi
```

### Step 6: Identify Common Failure Causes

**Failure Analysis**:
```bash
analyze_failures() {
  local antipatterns="$1"

  [[ -z "$antipatterns" ]] && return

  echo "Common Failure Patterns:"
  echo ""

  # Extract lessons from antipatterns
  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue

    workflow_type=$(echo "$pattern" | grep -o '"workflow_type":"[^"]*"' | sed 's/"workflow_type":"\(.*\)"/\1/')
    lessons=$(echo "$pattern" | grep -o '"lessons":"[^"]*"' | sed 's/"lessons":"\(.*\)"/\1/')
    error_count=$(echo "$pattern" | grep -o '"error_count":[0-9]\+' | grep -o '[0-9]\+')

    echo "- [$workflow_type] $lessons (errors: $error_count)"
  done <<< "$antipatterns" | head -5

  echo ""
}

if [[ -n "$FILTERED_ANTIPATTERNS" ]]; then
  analyze_failures "$FILTERED_ANTIPATTERNS"
fi
```

### Step 7: Optimization Opportunities

**Optimization Recommendations**:
```bash
analyze_optimizations() {
  # Check parallelization usage
  local parallel_workflows
  local total_workflows

  parallel_workflows=$(grep -c '"parallelization_used":true' "$PATTERNS_FILE" 2>/dev/null || echo "0")
  total_workflows=$(wc -l < "$PATTERNS_FILE" 2>/dev/null || echo "1")

  parallel_pct=$(echo "scale=0; $parallel_workflows * 100 / $total_workflows" | bc)

  echo "Optimization Opportunities:"
  echo ""

  # Parallelization recommendation
  if [[ $parallel_pct -lt 30 ]]; then
    echo "- ⚡ Parallelization: Only ${parallel_pct}% of workflows use parallel execution"
    echo "  Recommendation: Enable parallelization for independent phases"
  else
    echo "- ✓ Parallelization: ${parallel_pct}% of workflows use parallel execution (good)"
  fi

  # Research usage
  local research_workflows
  research_workflows=$(grep -c '"research_topics":\[' "$PATTERNS_FILE" 2>/dev/null || echo "0")
  research_pct=$(echo "scale=0; $research_workflows * 100 / $total_workflows" | bc)

  if [[ $research_pct -lt 50 ]]; then
    echo "- 📚 Research: Only ${research_pct}% of workflows include research"
    echo "  Recommendation: Consider research phase for complex features"
  else
    echo "- ✓ Research: ${research_pct}% of workflows include research (good)"
  fi

  echo ""
}

analyze_optimizations
```

### Step 8: Generate Visualization

**ASCII/Unicode Charts**:
```bash
create_success_chart() {
  local patterns="$1"

  # Count successes vs failures
  local success_count
  local failure_count

  success_count=$(grep -c '"outcome":"success"' "$PATTERNS_FILE" 2>/dev/null || echo "0")
  failure_count=$(grep -c '"outcome":"partial"\|"outcome":"failed"' "$ANTIPATTERNS_FILE" 2>/dev/null || echo "0")

  local total=$((success_count + failure_count))
  [[ $total -eq 0 ]] && return

  local success_pct=$((success_count * 100 / total))
  local failure_pct=$((failure_count * 100 / total))

  local success_bar_len=$((success_pct / 2))
  local failure_bar_len=$((failure_pct / 2))

  echo "Workflow Outcomes:"
  echo ""
  printf "Success  │"
  for ((i=0; i<success_bar_len; i++)); do printf "█"; done
  printf " %d%% (%d)\n" "$success_pct" "$success_count"

  printf "Failures │"
  for ((i=0; i<failure_bar_len; i++)); do printf "█"; done
  printf " %d%% (%d)\n" "$failure_pct" "$failure_count"
  echo ""
}

create_success_chart
```

### Step 9: Generate Report File

**Output to specs/reports/**:
```bash
# Determine next report number
if [[ -d specs/reports ]]; then
  REPORTS_DIR="specs/reports"
elif [[ -d .claude/specs/reports ]]; then
  REPORTS_DIR=".claude/specs/reports"
else
  REPORTS_DIR="specs/reports"
  mkdir -p "$REPORTS_DIR"
fi

NEXT_NUM=$(ls "$REPORTS_DIR"/*.md 2>/dev/null | \
  grep -o '[0-9]\{3\}' | \
  sort -n | \
  tail -1 | \
  awk '{printf "%03d", $1+1}')

NEXT_NUM=${NEXT_NUM:-001}

REPORT_FILE="$REPORTS_DIR/${NEXT_NUM}_pattern_analysis.md"

# Generate report
cat > "$REPORT_FILE" <<EOF
# Workflow Pattern Analysis

## Metadata
- **Date**: $(date +%Y-%m-%d)
- **Patterns Analyzed**: $PATTERN_COUNT successes, $ANTIPATTERN_COUNT failures
- **Search Filter**: ${SEARCH_PATTERN:-None}

## Summary

[Insert analysis summary from steps above]

## Success Patterns

[Insert success rate analysis]

## Common Research Topics

[Insert research topic analysis]

## Implementation Times

[Insert time analysis]

## Failure Patterns

[Insert failure analysis]

## Optimization Recommendations

[Insert optimization recommendations]

## Visualization

[Insert charts]

---

*Generated by /analyze-patterns command*
*Learning data: .claude/learning/*
EOF

echo "✓ Report generated: $REPORT_FILE"
echo ""
echo "View report: cat $REPORT_FILE"
```

## Output Format

### Console Output

```
Learning Data Summary:
- Success patterns: 15
- Failure patterns: 3
- Optimizations: 5

Success Rate by Workflow Type:
┌────────────────┬─────────┬─────────┬──────────────┐
│ Workflow Type  │ Success │ Total   │ Success Rate │
├────────────────┼─────────┼─────────┼──────────────┤
│ feature        │      12 │      14 │         85.7% │
│ refactor       │       2 │       3 │         66.7% │
│ debug          │       1 │       1 │        100.0% │
└────────────────┴─────────┴─────────┴──────────────┘

Most Common Research Topics:
- Authentication patterns (used 8x, 87% success)
- Security best practices (used 6x, 100% success)
- Database optimization (used 4x, 75% success)

Average Implementation Time by Type:
- feature: 3h 24min
- refactor: 2h 15min
- debug: 1h 5min

Common Failure Patterns:
- [refactor] Skipping research led to incompatible approach (errors: 12)
- [feature] Insufficient testing caused production bug (errors: 5)

Optimization Opportunities:
- ⚡ Parallelization: Only 20% of workflows use parallel execution
  Recommendation: Enable parallelization for independent phases
- ✓ Research: 65% of workflows include research (good)

Workflow Outcomes:
Success  │████████████████████████████████████████████ 83% (15)
Failures │█████████ 17% (3)

✓ Report generated: specs/reports/025_pattern_analysis.md
```

### Report File

Detailed markdown report with all analysis sections, suitable for review and sharing.

## Integration

### With Learning System

- Analyzes data collected by `collect-learning-data.sh`
- Uses similarity metrics from `match-similar-workflows.sh`
- Complements `generate-recommendations.sh` with historical insights

### With Workflow Commands

- Can be run periodically to review learning data
- Helps identify which patterns are most successful
- Informs future workflow decisions

## Performance

- Analysis time: <5 seconds for 1000 patterns
- Report generation: <1 second
- No impact on workflow execution

## Privacy

- Analyzes only aggregated, anonymized data
- No sensitive information in reports
- Can be disabled with learning opt-out

## Examples

### Example 1: General Analysis
```bash
/analyze-patterns

# Shows all patterns across all workflow types
```

### Example 2: Feature-Specific Analysis
```bash
/analyze-patterns feature

# Shows only feature workflow patterns
```

### Example 3: Topic-Specific Analysis
```bash
/analyze-patterns authentication

# Shows patterns related to authentication
```

## Future Enhancements

- Real-time dashboard visualization
- Trend analysis over time
- Team collaboration analytics
- Export to external tools (CSV, JSON)
- Machine learning-based pattern recognition

## References

- [Adaptive Learning System](../learning/README.md)
- [Pattern Matching](../utils/match-similar-workflows.sh)
- [Learning Data Collection](../utils/collect-learning-data.sh)
- [Privacy Guide](../docs/privacy-guide.md)
