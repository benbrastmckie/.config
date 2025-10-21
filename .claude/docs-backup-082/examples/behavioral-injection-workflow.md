# Behavioral Injection Workflow - Complete Example

This document demonstrates a complete workflow using the behavioral injection pattern with topic-based artifact organization.

**Related Documentation**:
- [Agent Authoring Guide](../guides/agent-authoring-guide.md) - Creating agent behavioral files
- [Command Authoring Guide](../guides/command-authoring-guide.md) - Invoking agents from commands
- [Hierarchical Agent Architecture](../concepts/hierarchical_agents.md) - Overall system architecture

## Workflow: User Authentication Research and Planning

This example shows the complete lifecycle of a feature implementation request from initial research through planning, demonstrating:
- Topic-based artifact organization
- Behavioral injection pattern
- Metadata-only context passing
- Cross-reference requirements

### Step 1: Calculate Topic Directory

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"

FEATURE_DESCRIPTION="User authentication with OAuth 2.0"
TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE_DESCRIPTION" "specs")

echo "Topic directory: $TOPIC_DIR"
# Output: specs/027_user_authentication
```

**Key Points**:
- Topic directory calculated from feature description
- Sequential numbering (027 = next available number)
- All workflow artifacts will live in this directory
- Topic-based organization enforced from the start

### Step 2: Research Phase (Parallel Research Agents)

#### Calculate Research Report Paths

```bash
REPORT_OAUTH=$(create_topic_artifact "$TOPIC_DIR" "reports" "oauth_security" "")
REPORT_DB=$(create_topic_artifact "$TOPIC_DIR" "reports" "database_design" "")
REPORT_BEST_PRACTICES=$(create_topic_artifact "$TOPIC_DIR" "reports" "best_practices" "")

echo "Research reports:"
echo "  - $REPORT_OAUTH"
echo "  - $REPORT_DB"
echo "  - $REPORT_BEST_PRACTICES"
# Output:
#   - specs/027_user_authentication/reports/027_oauth_security.md
#   - specs/027_user_authentication/reports/028_database_design.md
#   - specs/027_user_authentication/reports/029_best_practices.md
```

**Key Points**:
- Paths pre-calculated BEFORE agent invocation
- Sequential numbering within topic directory (027, 028, 029)
- All reports in same `reports/` subdirectory
- Paths passed to agents (agents don't calculate paths)

#### Invoke Research Agents in Parallel

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/agent-loading-utils.sh"

# Load research-specialist behavioral prompt (optional)
AGENT_PROMPT=$(load_agent_behavioral_prompt "research-specialist")

# Invoke 3 research agents in parallel (single message, multiple Task calls)
Task {
  subagent_type: "general-purpose"
  description: "Research OAuth 2.0 security patterns"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent.

    **Research Topic**: OAuth 2.0 security patterns for authentication
    **Focus Areas**: Security best practices, common vulnerabilities, recommended flows
    **Report Output Path**: ${REPORT_OAUTH}

    Create research report at the exact path provided.
    Return metadata: {path, summary (≤50 words), key_findings[]}
}

Task {
  subagent_type: "general-purpose"
  description: "Research database design for auth"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent.

    **Research Topic**: Database schema design for user authentication
    **Focus Areas**: User table structure, session management, token storage
    **Report Output Path**: ${REPORT_DB}

    Create research report at the exact path provided.
    Return metadata: {path, summary (≤50 words), key_findings[]}
}

Task {
  subagent_type: "general-purpose"
  description: "Research authentication best practices"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent.

    **Research Topic**: Authentication implementation best practices
    **Focus Areas**: Password hashing, 2FA, session management, security headers
    **Report Output Path**: ${REPORT_BEST_PRACTICES}

    Create research report at the exact path provided.
    Return metadata: {path, summary (≤50 words), key_findings[]}
}
```

**Key Points**:
- All 3 agents invoked in parallel (single message)
- Each agent receives pre-calculated path
- Agents use `research-specialist.md` behavioral guidelines
- Agents return metadata only (not full content)
- 40-60% time savings vs sequential invocation

#### Extract Metadata (Not Full Content)

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"

# Verify artifacts created
VERIFIED_OAUTH=$(verify_artifact_or_recover "$REPORT_OAUTH" "oauth_security")
VERIFIED_DB=$(verify_artifact_or_recover "$REPORT_DB" "database_design")
VERIFIED_BEST=$(verify_artifact_or_recover "$REPORT_BEST_PRACTICES" "best_practices")

# Extract metadata only (95% context reduction)
METADATA_OAUTH=$(extract_report_metadata "$VERIFIED_OAUTH")
METADATA_DB=$(extract_report_metadata "$VERIFIED_DB")
METADATA_BEST=$(extract_report_metadata "$VERIFIED_BEST")

# Parse metadata
SUMMARY_OAUTH=$(echo "$METADATA_OAUTH" | jq -r '.summary')
SUMMARY_DB=$(echo "$METADATA_DB" | jq -r '.summary')
SUMMARY_BEST=$(echo "$METADATA_BEST" | jq -r '.summary')

echo "Research complete. Metadata extracted:"
echo "  OAuth: $SUMMARY_OAUTH"
echo "  Database: $SUMMARY_DB"
echo "  Best Practices: $SUMMARY_BEST"

# Context reduction: 3 reports x 5000 tokens = 15000 tokens
#                    3 metadata x 250 tokens = 750 tokens
#                    Reduction: 95% (15000 → 750)
```

**Key Points**:
- Artifacts verified at expected paths
- Metadata extracted (title + 50-word summary + findings)
- Full report content NOT loaded into memory
- 95% context reduction achieved
- Original reports saved to disk for on-demand loading

### Step 3: Planning Phase (Plan Architect Agent)

#### Calculate Plan Path

```bash
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")

echo "Plan path: $PLAN_PATH"
# Output: specs/027_user_authentication/plans/027_implementation.md
```

**Key Points**:
- Plan path in same topic directory as reports
- Sequential numbering continues (027)
- Plan path calculated BEFORE agent invocation

#### Invoke Plan Architect Agent

```bash
# Collect research report paths for cross-referencing
RESEARCH_REPORTS="
  - ${VERIFIED_OAUTH}
  - ${VERIFIED_DB}
  - ${VERIFIED_BEST}
"

# Invoke plan-architect agent
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan for user authentication"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are acting as a Plan Architect Agent.

    **Feature**: User authentication with OAuth 2.0
    **Research Reports**: ${RESEARCH_REPORTS}
    **Plan Output Path**: ${PLAN_PATH}

    **Context from Research**:
    - OAuth Security: ${SUMMARY_OAUTH}
    - Database Design: ${SUMMARY_DB}
    - Best Practices: ${SUMMARY_BEST}

    **Requirements**:
    1. Create implementation plan at exact path provided
    2. Include "Research Reports" metadata section with all report paths
    3. Structure plan with phases, tasks, success criteria
    4. Reference research findings in plan phases

    Return metadata: {path, phase_count, complexity_score, estimated_hours}
}
```

**Key Points**:
- Agent receives research summaries (not full reports)
- Agent receives all research report paths for cross-referencing
- Agent creates plan at exact path provided
- Agent includes "Research Reports" metadata section (Revision 3 requirement)
- Agent uses Write tool (not SlashCommand)

#### Extract Plan Metadata

```bash
# Verify plan created
VERIFIED_PLAN=$(verify_artifact_or_recover "$PLAN_PATH" "implementation")

# Extract plan metadata
PLAN_METADATA=$(extract_plan_metadata "$VERIFIED_PLAN")
PHASE_COUNT=$(echo "$PLAN_METADATA" | jq -r '.phases')
COMPLEXITY=$(echo "$PLAN_METADATA" | jq -r '.complexity')
ESTIMATED_HOURS=$(echo "$PLAN_METADATA" | jq -r '.time_estimate')

echo "Plan created: $PHASE_COUNT phases, $COMPLEXITY complexity, ~$ESTIMATED_HOURS hours"
# Output: Plan created: 6 phases, Medium complexity, ~14 hours
```

**Key Points**:
- Plan verified at expected path
- Metadata extracted (phase count, complexity, time estimate)
- Full plan NOT loaded into memory yet
- Context reduction maintained

### Step 4: Create Workflow Summary

#### Calculate Summary Path

```bash
SUMMARY_PATH=$(create_topic_artifact "$TOPIC_DIR" "summaries" "research_and_planning" "")

echo "Summary path: $SUMMARY_PATH"
# Output: specs/027_user_authentication/summaries/027_research_and_planning.md
```

#### Invoke Doc-Writer Agent (Summarizer)

```bash
# Collect all artifact paths for cross-referencing
ALL_ARTIFACTS="
Research Reports:
  - ${VERIFIED_OAUTH}
  - ${VERIFIED_DB}
  - ${VERIFIED_BEST}

Implementation Plan:
  - ${VERIFIED_PLAN}
"

Task {
  subagent_type: "general-purpose"
  description: "Create workflow summary for authentication feature"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/doc-writer.md

    You are acting as a Documentation Writer Agent (Summarizer role).

    **Workflow**: User authentication research and planning
    **Summary Output Path**: ${SUMMARY_PATH}

    **Artifacts Generated**:
    ${ALL_ARTIFACTS}

    **Requirements**:
    1. Create summary at exact path provided
    2. Include "Artifacts Generated" section with all artifact paths
    3. Summarize research findings and plan overview
    4. Document key decisions and rationale

    Return metadata: {path, summary (≤100 words)}
}
```

**Key Points**:
- Summary includes cross-references to all artifacts (Revision 3 requirement)
- Enables complete audit trail (summary → plan → research)
- Summary created at topic-based path
- All workflow artifacts in single topic directory

### Step 5: Complete Workflow Artifact Structure

Final artifact structure:

```
specs/027_user_authentication/
├── reports/
│   ├── 027_oauth_security.md            (research report 1)
│   ├── 028_database_design.md           (research report 2)
│   └── 029_best_practices.md            (research report 3)
├── plans/
│   └── 027_implementation.md            (plan with cross-references to reports)
└── summaries/
    └── 027_research_and_planning.md     (summary with cross-references to all artifacts)
```

**Key Points**:
- All artifacts in single topic directory
- Sequential numbering across artifact types
- Clear artifact lifecycle (reports → plan → summary)
- Complete cross-reference network
- Easy navigation and discoverability

## Context Reduction Metrics

**Without Behavioral Injection**:
- Research phase: 3 reports x 5000 tokens = 15000 tokens
- Planning phase: 15000 tokens + plan 3000 tokens = 18000 tokens
- Total context: 18000 tokens (90% of available context)

**With Behavioral Injection**:
- Research phase: 3 metadata x 250 tokens = 750 tokens
- Planning phase: 750 tokens + plan metadata 200 tokens = 950 tokens
- Total context: 950 tokens (5% of available context)

**Reduction**: 95% (18000 → 950 tokens)

## Benefits Demonstrated

1. **Topic-Based Organization**: All artifacts in single directory (easy navigation)
2. **Behavioral Injection**: Commands control orchestration, agents execute
3. **Metadata-Only Passing**: 95% context reduction throughout workflow
4. **Parallel Execution**: 40-60% time savings with parallel agents
5. **Cross-Referencing**: Complete audit trail from summary to research
6. **Path Control**: Commands pre-calculate paths (consistent numbering)
7. **No Recursion**: Agents use Write tool (never SlashCommand)

## See Also

- [Agent Authoring Guide](../guides/agent-authoring-guide.md) - Creating agent behavioral files
- [Command Authoring Guide](../guides/command-authoring-guide.md) - Invoking agents from commands
- [Correct Agent Invocation](./correct-agent-invocation.md) - Task tool examples
- [Reference Implementations](./reference-implementations.md) - Working command examples
- [Troubleshooting Guide](../troubleshooting/agent-delegation-issues.md) - Common issues and solutions
