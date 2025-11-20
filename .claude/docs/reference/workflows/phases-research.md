# Workflow Phases: Research

**Related Documents**:
- [Overview](workflow-phases-overview.md) - Phase coordination
- [Planning](workflow-phases-planning.md) - Plan creation
- [Implementation](workflow-phases-implementation.md) - Code execution

---

## Research Phase (Parallel Execution)

The research phase coordinates multiple specialized agents to investigate different aspects of the workflow in parallel, then verifies all research outputs before proceeding.

## When to Use

- **Complex workflows** requiring investigation of existing patterns, best practices, alternatives, or constraints
- **Medium+ complexity** (keywords: implement, add with research, redesign, architecture)
- **Skip for simple tasks** (keywords: fix, update single file, small change)

## Quick Overview

1. Analyze workflow complexity and determine thinking mode
2. Identify 2-4 research topics based on complexity
3. Launch research-specialist agents in parallel (single message, multiple Task calls)
4. Monitor agent execution and collect report paths
5. Verify reports exist at expected paths (with automatic path mismatch recovery)
6. Save checkpoint with research outputs

## Execution Procedure

### Step 1: Complexity Analysis

Calculate complexity score:

```
score = keywords("implement"/"architecture") x 3
      + keywords("add"/"improve") x 2
      + keywords("security"/"breaking") x 4
      + estimated_files / 5
      + (research_topics - 1) x 2

Thinking Mode:
- 0-3: standard (no special mode)
- 4-6: "think" (moderate)
- 7-9: "think hard" (complex)
- 10+: "think harder" (critical)
```

### Step 2: Identify Research Topics

Based on complexity, identify 2-4 topics:

```bash
# Low complexity (score 0-4): 2 topics
# Medium complexity (score 5-7): 3 topics
# High complexity (score 8+): 4 topics

TOPICS=("existing_patterns" "best_practices")
if [ $SCORE -gt 4 ]; then
  TOPICS+=("security_considerations")
fi
if [ $SCORE -gt 7 ]; then
  TOPICS+=("performance_implications")
fi
```

### Step 3: Pre-Calculate Report Paths

Calculate ABSOLUTE paths before invocation:

```bash
TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESC" ".claude/specs")

declare -A REPORT_PATHS
for i in "${!TOPICS[@]}"; do
  topic="${TOPICS[$i]}"
  num=$(printf "%03d" $((i + 1)))
  REPORT_PATHS["$topic"]="${TOPIC_DIR}/reports/${num}_${topic}.md"
done
```

### Step 4: Invoke Research Agents (Parallel)

**CRITICAL**: Send ALL Task invocations in SINGLE message.

```markdown
**EXECUTE NOW**: Launch research agents in parallel

Task {
  subagent_type: "general-purpose"
  description: "Research existing patterns"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    Research Topic: Existing patterns in codebase
    Output Path: ${REPORT_PATHS["existing_patterns"]}
    Thinking Mode: ${THINKING_MODE}

    Return: CREATED: ${REPORT_PATHS["existing_patterns"]}
}

Task {
  subagent_type: "general-purpose"
  description: "Research best practices"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    Research Topic: Best practices for ${FEATURE}
    Output Path: ${REPORT_PATHS["best_practices"]}
    Thinking Mode: ${THINKING_MODE}

    Return: CREATED: ${REPORT_PATHS["best_practices"]}
}
```

### Step 5: Monitor Execution

Emit progress markers:

```
PROGRESS: Research Phase Started
PROGRESS: [Agent 1/3] Analyzing existing patterns
PROGRESS: [Agent 2/3] Researching best practices
PROGRESS: [Agent 3/3] Investigating security
PROGRESS: Research Phase Complete
```

### Step 6: Verify Reports

Verify all expected files exist:

```bash
verified=0
failed=0

for topic in "${!REPORT_PATHS[@]}"; do
  path="${REPORT_PATHS[$topic]}"

  if [ -f "$path" ]; then
    echo "Verified: $path"
    ((verified++))
  else
    echo "MISSING: $path"
    ((failed++))
  fi
done

# Proceed if >= 50% verified
if [ $verified -ge $((${#REPORT_PATHS[@]} / 2)) ]; then
  echo "Verification passed: $verified/${#REPORT_PATHS[@]}"
else
  echo "CRITICAL: Too many reports missing"
  exit 1
fi
```

### Step 7: Save Checkpoint

```bash
CHECKPOINT='{
  "current_phase": "planning",
  "research": {
    "reports": ['"$(printf '"%s",' "${REPORT_PATHS[@]}" | sed 's/,$//')"'],
    "thinking_mode": "'$THINKING_MODE'",
    "complexity_score": '$SCORE'
  }
}'

save_checkpoint "orchestrate" "$CHECKPOINT"
```

## Path Mismatch Recovery

If agent creates file at wrong path:

```bash
# Detect mismatch
ACTUAL_PATH=$(echo "$AGENT_OUTPUT" | grep -oP 'CREATED:\s*\K.+')

if [ "$ACTUAL_PATH" != "$EXPECTED_PATH" ]; then
  # Move to correct location
  mv "$ACTUAL_PATH" "$EXPECTED_PATH"
  echo "Recovered: Moved $ACTUAL_PATH -> $EXPECTED_PATH"
fi
```

## Example Timing

```
Complexity Analysis: 2s
Topic Identification: 1s
Path Calculation: 1s
Agent Invocation: 45s (parallel)
  - Agent 1: 40s
  - Agent 2: 45s
  - Agent 3: 42s
Verification: 3s
Checkpoint: 1s

Total: ~53s (sequential would be ~127s)
Parallel Speedup: 58%
```

## Key Requirements

1. **Always use absolute paths** - Never relative
2. **Parallel invocation** - Single message, multiple Tasks
3. **Verify before proceeding** - Check files exist
4. **Save checkpoint** - Persist state for recovery

---

## Related Documentation

- [Overview](workflow-phases-overview.md)
- [Planning Phase](workflow-phases-planning.md)
- [Research Specialist Agent](../../agents/research-specialist.md)
