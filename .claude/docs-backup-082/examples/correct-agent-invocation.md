# Correct Agent Invocation Examples

This document provides Task tool invocation examples demonstrating the correct behavioral injection pattern.

**Related Documentation**:
- [Command Authoring Guide](../guides/command-authoring-guide.md) - Complete command authoring patterns
- [Agent Authoring Guide](../guides/agent-authoring-guide.md) - Agent behavioral file creation
- [Behavioral Injection Workflow](./behavioral-injection-workflow.md) - Complete workflow example

## Overview

The Task tool is used to invoke specialized agents from commands. The correct pattern involves:
1. Commands pre-calculate topic-based artifact paths
2. Commands inject complete context (behavioral prompt + task + path)
3. Agents create artifacts at exact paths provided
4. Agents return metadata only (not full content)

## Example 1: Research Specialist Agent

### Scenario
Command needs to research authentication patterns for a feature.

### Path Calculation

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"

TOPIC_DIR=$(get_or_create_topic_dir "User Authentication" "specs")
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "auth_patterns" "")
# Result: specs/042_user_authentication/reports/042_auth_patterns.md
```

### Agent Invocation

```bash
Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent.

    **Research Topic**: Authentication patterns (JWT, sessions, OAuth)
    **Focus Areas**:
    - Security best practices
    - Performance considerations
    - Common pitfalls
    **Report Output Path**: ${REPORT_PATH}

    Create research report at the exact path provided.
    Return metadata: {path, summary (≤50 words), key_findings[]}
}
```

### Metadata Extraction

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"

# Verify artifact created
VERIFIED_PATH=$(verify_artifact_or_recover "$REPORT_PATH" "auth_patterns")

# Extract metadata only
METADATA=$(extract_report_metadata "$VERIFIED_PATH")
SUMMARY=$(echo "$METADATA" | jq -r '.summary')
FINDINGS=$(echo "$METADATA" | jq -r '.key_findings[]')

echo "Report summary: $SUMMARY"
echo "Key findings: $FINDINGS"
```

### Context Reduction
- Full report: ~5000 tokens
- Metadata only: ~250 tokens
- **Reduction**: 95%

## Example 2: Plan Architect Agent

### Scenario
Command needs to create implementation plan based on research reports.

### Path Calculation

```bash
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")
# Result: specs/042_user_authentication/plans/042_implementation.md
```

### Collect Research Report Paths

```bash
# From previous research phase
RESEARCH_REPORTS=(
  "specs/042_user_authentication/reports/042_auth_patterns.md"
  "specs/042_user_authentication/reports/043_database_design.md"
)

# Format for cross-referencing (Revision 3 requirement)
REPORT_REFS=""
for report in "${RESEARCH_REPORTS[@]}"; do
  REPORT_REFS+="  - $report\n"
done
```

### Agent Invocation

```bash
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are acting as a Plan Architect Agent.

    **Feature**: User authentication system
    **Research Reports**:
    ${REPORT_REFS}
    **Plan Output Path**: ${PLAN_PATH}

    **Requirements**:
    1. Create implementation plan at exact path provided
    2. Include "Research Reports" metadata section with all report paths
    3. Structure plan with phases, tasks, success criteria
    4. Estimate complexity and timeline

    Return metadata: {path, phase_count, complexity_score, estimated_hours}
}
```

### Metadata Extraction

```bash
# Verify plan created
VERIFIED_PLAN=$(verify_artifact_or_recover "$PLAN_PATH" "implementation")

# Extract plan metadata
PLAN_METADATA=$(extract_plan_metadata "$VERIFIED_PLAN")
PHASE_COUNT=$(echo "$PLAN_METADATA" | jq -r '.phases')
COMPLEXITY=$(echo "$PLAN_METADATA" | jq -r '.complexity')
```

## Example 3: Debug Analyst Agent (Parallel Invocations)

### Scenario
Command needs to investigate multiple potential root causes for a bug.

### Path Calculation (Multiple Agents)

```bash
TOPIC_DIR=$(get_or_create_topic_dir "Token Refresh Bug" "specs")
DEBUG_REPORT_1=$(create_topic_artifact "$TOPIC_DIR" "debug" "timing_issue" "")
DEBUG_REPORT_2=$(create_topic_artifact "$TOPIC_DIR" "debug" "expiry_config" "")
DEBUG_REPORT_3=$(create_topic_artifact "$TOPIC_DIR" "debug" "database_locking" "")
```

### Parallel Agent Invocation (Single Message)

```bash
# Hypothesis 1: Timing issue
Task {
  subagent_type: "general-purpose"
  description: "Investigate timing issue hypothesis"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

    You are acting as a Debug Analyst Agent.

    **Issue**: Token refresh fails after 1 hour
    **Hypothesis**: Race condition in token refresh timing
    **Failed Tests**: test_token_refresh, test_expired_token
    **Debug Report Path**: ${DEBUG_REPORT_1}

    Investigate this hypothesis and create debug report at exact path.
    Return metadata: {path, summary (≤50 words), root_cause, proposed_fix}
}

# Hypothesis 2: Expiry configuration
Task {
  subagent_type: "general-purpose"
  description: "Investigate expiry configuration hypothesis"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

    You are acting as a Debug Analyst Agent.

    **Issue**: Token refresh fails after 1 hour
    **Hypothesis**: Token expiration time misconfigured
    **Failed Tests**: test_token_refresh, test_expired_token
    **Debug Report Path**: ${DEBUG_REPORT_2}

    Investigate this hypothesis and create debug report at exact path.
    Return metadata: {path, summary (≤50 words), root_cause, proposed_fix}
}

# Hypothesis 3: Database locking
Task {
  subagent_type: "general-purpose"
  description: "Investigate database locking hypothesis"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

    You are acting as a Debug Analyst Agent.

    **Issue**: Token refresh fails after 1 hour
    **Hypothesis**: Database lock prevents token update
    **Failed Tests**: test_token_refresh, test_expired_token
    **Debug Report Path**: ${DEBUG_REPORT_3}

    Investigate this hypothesis and create debug report at exact path.
    Return metadata: {path, summary (≤50 words), root_cause, proposed_fix}
}
```

### Aggregate Metadata

```bash
# Extract metadata from all debug reports
METADATA_1=$(extract_debug_metadata "$DEBUG_REPORT_1")
METADATA_2=$(extract_debug_metadata "$DEBUG_REPORT_2")
METADATA_3=$(extract_debug_metadata "$DEBUG_REPORT_3")

# Identify most likely root cause
ROOT_CAUSE_1=$(echo "$METADATA_1" | jq -r '.root_cause')
ROOT_CAUSE_2=$(echo "$METADATA_2" | jq -r '.root_cause')
ROOT_CAUSE_3=$(echo "$METADATA_3" | jq -r '.root_cause')

echo "Hypotheses investigated:"
echo "  1. Timing: $ROOT_CAUSE_1"
echo "  2. Configuration: $ROOT_CAUSE_2"
echo "  3. Database: $ROOT_CAUSE_3"
```

### Performance Benefit
- 3 agents in parallel: ~2-3 minutes total
- 3 agents sequential: ~6-9 minutes total
- **Time savings**: 60-70%

## Example 4: Doc-Writer Agent (Summarizer)

### Scenario
Command needs to create workflow summary with cross-references to all artifacts.

### Path Calculation

```bash
SUMMARY_PATH=$(create_topic_artifact "$TOPIC_DIR" "summaries" "workflow_summary" "")
# Result: specs/042_user_authentication/summaries/042_workflow_summary.md
```

### Collect All Artifact Paths

```bash
# Collect all artifacts from workflow
ALL_REPORTS=(
  "specs/042_user_authentication/reports/042_auth_patterns.md"
  "specs/042_user_authentication/reports/043_database_design.md"
)
ALL_PLANS=(
  "specs/042_user_authentication/plans/042_implementation.md"
)
ALL_DEBUG=(
  # None for this workflow
)

# Format for cross-referencing
ARTIFACTS_SECTION="
Research Reports:
$(for r in "${ALL_REPORTS[@]}"; do echo "  - $r"; done)

Implementation Plans:
$(for p in "${ALL_PLANS[@]}"; do echo "  - $p"; done)

Debug Reports:
$([ ${#ALL_DEBUG[@]} -eq 0 ] && echo "  - (none)" || for d in "${ALL_DEBUG[@]}"; do echo "  - $d"; done)
"
```

### Agent Invocation

```bash
Task {
  subagent_type: "general-purpose"
  description: "Create workflow summary"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/doc-writer.md

    You are acting as a Documentation Writer Agent (Summarizer role).

    **Workflow**: User authentication feature development
    **Summary Output Path**: ${SUMMARY_PATH}

    **Artifacts Generated**:
    ${ARTIFACTS_SECTION}

    **Requirements**:
    1. Create summary at exact path provided
    2. Include "Artifacts Generated" section with all artifact paths
    3. Summarize workflow phases (research → planning → implementation)
    4. Document key decisions and lessons learned

    Return metadata: {path, summary (≤100 words)}
}
```

### Cross-Reference Validation

The summary should include complete cross-references (Revision 3 requirement):

```markdown
## Artifacts Generated

### Research Reports
- specs/042_user_authentication/reports/042_auth_patterns.md
- specs/042_user_authentication/reports/043_database_design.md

### Implementation Plans
- specs/042_user_authentication/plans/042_implementation.md

### Debug Reports
- (none)
```

This enables:
- Complete audit trail (summary → plan → research)
- Traceability for compliance/review
- Easy navigation between related artifacts

## Anti-Pattern Examples

### ❌ WRONG: Command doesn't pre-calculate path

```bash
# Don't do this
Task {
  prompt: |
    Research authentication patterns.
    Create report in an appropriate location.  # ❌ Agent calculates path
}
```

**Problems**:
- Agent may not follow topic-based organization
- Command cannot verify artifact location
- Cannot extract metadata (don't know path)

### ❌ WRONG: Agent invokes slash command

```bash
# Don't do this
Task {
  prompt: |
    Use SlashCommand to invoke /report command.  # ❌ Recursion risk
}
```

**Problems**:
- Loss of control over artifact path
- Cannot extract metadata before context bloat
- Recursion risk (agent → command → agent)

### ❌ WRONG: Command loads full artifact content

```bash
# Don't do this
FULL_REPORT=$(cat "$REPORT_PATH")  # ❌ Context bloat
Task {
  prompt: |
    Here is the full report:
    $FULL_REPORT  # ❌ Wastes context
}
```

**Problems**:
- Context bloat (5000 tokens vs 250 tokens)
- No context reduction achieved
- May exceed context limits

### ✅ CORRECT: Pre-calculate path, extract metadata only

```bash
# Do this
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "research" "")

Task {
  prompt: |
    **Report Output Path**: ${REPORT_PATH}
    Create report at exact path provided.
}

# Extract metadata only
METADATA=$(extract_report_metadata "$REPORT_PATH")
SUMMARY=$(echo "$METADATA" | jq -r '.summary')  # ✅ 250 tokens
```

## Pattern Summary

**Correct Behavioral Injection Pattern**:
1. ✅ Commands pre-calculate topic-based paths
2. ✅ Commands inject complete context (prompt + path)
3. ✅ Agents create artifacts at exact paths
4. ✅ Agents return metadata only
5. ✅ Commands extract metadata (95% reduction)

**Anti-Patterns to Avoid**:
1. ❌ Agents calculating their own paths
2. ❌ Agents invoking slash commands
3. ❌ Commands loading full artifact content
4. ❌ Missing cross-references in metadata

## See Also

- [Command Authoring Guide](../guides/command-authoring-guide.md) - Complete command patterns
- [Agent Authoring Guide](../guides/agent-authoring-guide.md) - Agent behavioral files
- [Behavioral Injection Workflow](./behavioral-injection-workflow.md) - Complete workflow example
- [Reference Implementations](./reference-implementations.md) - Working command examples
- [Troubleshooting Guide](../troubleshooting/agent-delegation-issues.md) - Common issues
