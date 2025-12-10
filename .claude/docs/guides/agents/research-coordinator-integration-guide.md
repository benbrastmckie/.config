# Research Coordinator Integration Guide

## Overview

The research-coordinator agent orchestrates parallel research-specialist invocations across multiple topics, providing 95% context reduction through metadata-only aggregation. This guide shows command authors how to invoke the coordinator and parse its outputs.

## Invocation Pattern

Commands invoke research-coordinator using the Task tool with structured parameters.

### Basic Invocation (Mode 1 - Automated Decomposition)

```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-coordinator agent.

Task {
  subagent_type: "general-purpose"
  description: "Coordinate parallel research across multiple topics"
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    You are acting as a Research Coordinator Agent with the tools and constraints defined in that file.

    research_request: 'OAuth2 authentication, session management, password security'
    research_complexity: 3
    report_dir: /home/user/.config/.claude/specs/045_auth/reports/
    topic_path: /home/user/.config/.claude/specs/045_auth
    context:
      feature_description: 'Implement OAuth2 authentication with session management'
  "
}
```

### Pre-Decomposed Invocation (Mode 2 - Manual Topic Control)

```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-coordinator agent.

Task {
  subagent_type: "general-purpose"
  description: "Coordinate parallel research with pre-defined topics"
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    You are acting as a Research Coordinator Agent with the tools and constraints defined in that file.

    research_request: 'Implement OAuth2 authentication with session management and password security'
    research_complexity: 3
    report_dir: /home/user/.config/.claude/specs/045_auth/reports/
    topic_path: /home/user/.config/.claude/specs/045_auth
    topics:
      - 'OAuth2 authentication implementation patterns'
      - 'Session management and token storage'
      - 'Password security best practices'
    report_paths:
      - /home/user/.config/.claude/specs/045_auth/reports/001-oauth2-authentication.md
      - /home/user/.config/.claude/specs/045_auth/reports/002-session-management.md
      - /home/user/.config/.claude/specs/045_auth/reports/003-password-security.md
    context:
      feature_description: 'Implement OAuth2 authentication with session management and password security'
  "
}
```

## Completion Signal Parsing

The coordinator returns a completion signal with workflow metrics for primary agent validation.

### Success Signal Format

```
RESEARCH_COORDINATOR_COMPLETE: SUCCESS
topics_processed: 3
reports_created: 3
context_reduction_pct: 95
execution_time_seconds: 45

RESEARCH_COMPLETE: 3
reports: [
  {"path": "/path/to/001-oauth2-authentication.md", "title": "OAuth2 Authentication Patterns", "findings_count": 12, "recommendations_count": 5},
  {"path": "/path/to/002-session-management.md", "title": "Session Management Strategies", "findings_count": 8, "recommendations_count": 4},
  {"path": "/path/to/003-password-security.md", "title": "Password Security Best Practices", "findings_count": 10, "recommendations_count": 6}
]
total_findings: 30
total_recommendations: 15
```

### Parsing Example

```bash
# Extract completion signal
if echo "$COORDINATOR_OUTPUT" | grep -q "RESEARCH_COORDINATOR_COMPLETE: SUCCESS"; then
  echo "Coordinator completed successfully"

  # Parse metrics
  TOPICS_PROCESSED=$(echo "$COORDINATOR_OUTPUT" | grep "^topics_processed:" | cut -d: -f2 | tr -d ' ')
  REPORTS_CREATED=$(echo "$COORDINATOR_OUTPUT" | grep "^reports_created:" | cut -d: -f2 | tr -d ' ')

  # Validate report count matches topics
  if [ "$REPORTS_CREATED" -eq "$TOPICS_PROCESSED" ]; then
    echo "All topics researched successfully ($REPORTS_CREATED/$TOPICS_PROCESSED)"
  else
    echo "WARNING: Partial research completion ($REPORTS_CREATED/$TOPICS_PROCESSED)"
  fi
else
  echo "ERROR: Coordinator did not return completion signal"
  # Check for TASK_ERROR signal
  if echo "$COORDINATOR_OUTPUT" | grep -q "TASK_ERROR:"; then
    ERROR_MSG=$(echo "$COORDINATOR_OUTPUT" | grep "TASK_ERROR:" | head -1)
    echo "Coordinator error: $ERROR_MSG"
  fi
fi
```

## Troubleshooting

### Empty Reports Directory

If the coordinator returns an empty reports directory, check:

1. **Invocation Plan File**: Check `$REPORT_DIR/.invocation-plan.txt` exists
   - If missing: STEP 2.5 was skipped (pre-execution barrier failed)
   - Solution: Verify research-coordinator.md is up-to-date

2. **Invocation Trace File**: Check `$REPORT_DIR/.invocation-trace.log` exists
   - If missing: STEP 3 Bash script did not execute
   - If exists but empty: Bash script ran but Task invocations skipped
   - Solution: Review STEP 3 execution directives

3. **Task Invocation Count**: Count `Status: INVOKED` entries in trace file
   - Expected count: Should equal topics count
   - If mismatch: Some Task invocations were skipped

4. **TASK_ERROR Signal**: Check coordinator output for error signals
   - Format: `TASK_ERROR: <error_type> - <error_message>`
   - Parse with `parse_subagent_error()` for error logging

### Partial Research Completion

If some reports are missing (partial completion):

1. Check individual research-specialist failures in coordinator output
2. Coordinator operates in partial success mode (≥50% threshold)
3. Missing reports indicate specific topic research failures
4. Review research-specialist error logs for failed topics

### Invalid Completion Signal

If `RESEARCH_COORDINATOR_COMPLETE: SUCCESS` signal is missing:

1. Check for `TASK_ERROR:` signal instead (workflow failure)
2. Verify coordinator output is complete (not truncated by context limit)
3. Check for early-exit errors in STEP 4 validation
4. Review invocation plan and trace files for diagnostic information

## Fixed Issues

### Coordinator Early Return Bug (Fixed 2025-12-09)

**Problem**: Research-coordinator was skipping Task invocations in STEP 3, returning prematurely after 11 tool uses instead of invoking research-specialist agents. This caused:
- Empty reports directories forcing expensive fallback behavior (5.3x cost multiplier)
- Context efficiency degradation from 95% reduction to 0-50%
- Silent failures without error signals

**Root Cause**: STEP 3 used placeholder syntax `(use TOPICS[0])` and conditional language `if TOPICS array length > 1` that the agent model interpreted as "documentation templates" rather than "executable directives."

**Fix Applied**:
1. **STEP 3 Refactor**: Replaced placeholder patterns with Bash-generated concrete Task invocations
2. **STEP 2.5 Addition**: Added pre-execution validation barrier requiring invocation plan file creation
3. **STEP 4 Enhancement**: Added multi-layer validation (plan file → trace file → reports)
4. **Error Trap Handler**: Added mandatory error return protocol with TASK_ERROR signal

**Validation**:
- Invocation plan file exists at `$REPORT_DIR/.invocation-plan.txt` (proves STEP 2.5 executed)
- Invocation trace file exists at `$REPORT_DIR/.invocation-trace.log` (proves STEP 3 executed)
- Trace count matches expected invocations (proves all Task invocations executed)
- Reports count matches topics count (proves hard barrier validation passed)

**Impact**: Coordinator now achieves 100% invocation rate with no silent failures. Primary agents no longer need fallback invocation logic.

## Performance Metrics

- **Context Reduction**: 95% (110 tokens per report vs 2,500 tokens full content)
- **Parallel Execution**: 2-5 research-specialist agents invoked simultaneously
- **Time Savings**: 40-60% vs sequential research invocation
- **Reliability**: 100% invocation rate with multi-layer validation

## Integration Examples

### /create-plan Command Integration

```bash
# Invoke research-coordinator for complexity >= 3 plans
if [ "$COMPLEXITY" -ge 3 ]; then
  echo "Invoking research-coordinator for multi-topic research..."

  # Use Task tool to invoke coordinator
  # (Task invocation pattern shown above)

  # Parse coordinator output
  if echo "$COORDINATOR_OUTPUT" | grep -q "RESEARCH_COORDINATOR_COMPLETE: SUCCESS"; then
    # Success - use metadata-only reports
    REPORT_COUNT=$(echo "$COORDINATOR_OUTPUT" | grep "^reports_created:" | cut -d: -f2 | tr -d ' ')
    echo "Research coordination successful: $REPORT_COUNT reports created"
  else
    # Failure - fallback to direct research-specialist invocation (deprecated)
    echo "WARNING: Coordinator failed, using fallback invocation pattern"
  fi
fi
```

### /lean-plan Command Integration

```bash
# Pre-decompose Lean-specific research topics
TOPICS=(
  "Mathlib theorems for group homomorphism"
  "Proof automation strategies with tactics"
  "Lean 4 project structure patterns"
  "Mathlib style guide compliance"
)

# Calculate report paths
REPORT_PATHS=()
for i in "${!TOPICS[@]}"; do
  TOPIC="${TOPICS[$i]}"
  REPORT_NUM=$(printf "%03d" $((i + 1)))
  REPORT_PATHS+=("$REPORT_DIR/${REPORT_NUM}-$(echo "$TOPIC" | tr ' ' '-').md")
done

# Invoke coordinator with pre-decomposed topics (Mode 2)
# (Task invocation pattern shown above with topics and report_paths arrays)
```

## Best Practices

1. **Always Use Completion Signal**: Parse `RESEARCH_COORDINATOR_COMPLETE: SUCCESS` to validate success
2. **Validate Report Count**: Check `reports_created` matches `topics_processed`
3. **Use Metadata-Only**: Avoid loading full report content into context (defeats purpose)
4. **Handle TASK_ERROR**: Parse error signals with `parse_subagent_error()` for error logging
5. **Check Trace File**: On failure, inspect `.invocation-trace.log` for diagnostic information
6. **Use Mode 2 for Control**: Pre-decompose topics when exact control needed (e.g., Lean-specific topics)

## See Also

- [Hierarchical Agent Architecture](../../concepts/hierarchical-agents-overview.md)
- [Research Coordinator Pattern Example](../../concepts/hierarchical-agents-examples.md#example-7)
- [Error Handling Pattern](../../concepts/patterns/error-handling.md)
- [Research Invocation Standards](../../reference/standards/research-invocation-standards.md)
