# Orchestration Guide - Examples

## Navigation

This document is part of a multi-part guide:
- [Overview](orchestration-guide-overview.md) - Quick start, architecture, and artifact-based aggregation
- [Patterns](orchestration-guide-patterns.md) - Context pruning, user workflows, and error recovery
- **Examples** (this file) - Wave-based execution and behavioral injection examples
- [Troubleshooting](orchestration-guide-troubleshooting.md) - Common issues, diagnostics, and reference

---

## Wave-Based Parallel Execution

### Overview

Wave-based execution (from Plan 080) enables parallel implementation of independent plan phases while respecting dependency constraints. This provides 40-60% time savings compared to sequential execution.

### Dependency-Driven Wave Organization

**Phase Dependency Syntax**:
```yaml
## Dependencies
- depends_on: [phase_1, phase_2]
- blocks: [phase_5, phase_6]
```

**Wave Calculation**:
1. **Wave 1**: All phases with no dependencies (empty `depends_on` list)
2. **Wave 2**: Phases dependent only on Wave 1 phases
3. **Wave N**: Phases dependent only on phases in previous waves

**Example from Plan 080**:
```
Plan with 6 phases:
- Phase 1: Setup (no dependencies)               → Wave 1
- Phase 2: Database (no dependencies)            → Wave 1
- Phase 3: API (depends_on: [phase_2])          → Wave 2
- Phase 4: Auth (depends_on: [phase_2])         → Wave 2
- Phase 5: Integration (depends_on: [phase_3, phase_4]) → Wave 3
- Phase 6: Testing (depends_on: [phase_5])      → Wave 4

Execution:
Wave 1: Phases 1, 2 in parallel (200s max, not 380s sum)
Wave 2: Phases 3, 4 in parallel (210s max, not 420s sum)
Wave 3: Phase 5 sequential (180s)
Wave 4: Phase 6 sequential (150s)

Total: 740s (vs 1,140s sequential)
Savings: 35%
```

### Implementer-Coordinator Subagent

The implementer-coordinator manages wave-based execution:

**Responsibilities**:
1. Parse plan hierarchy (Level 0 → Level 1 → Level 2)
2. Extract dependency metadata from all phases/stages
3. Build dependency graph and calculate waves
4. Invoke implementation-executor subagents in parallel per wave
5. Monitor wave completion before starting next wave
6. Update plan hierarchy with progress checkboxes

**Context Injection** (Behavioral Injection Pattern):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Coordinate wave-based implementation"
  prompt: |
    Read: .claude/agents/implementer-coordinator.md

    **Plan Path**: ${PLAN_PATH}
    **Topic Directory**: ${TOPIC_DIR}

    Execute wave-based implementation:
    1. Parse plan hierarchy and dependencies
    2. Calculate waves
    3. Invoke executors in parallel per wave
    4. Update plan files with progress
    5. Return wave execution summary
}
```

**Output** (Metadata Only):
```json
{
  "waves_executed": 4,
  "phases_completed": 6,
  "time_saved": "35%",
  "failures": [],
  "checkpoint_path": ".claude/data/checkpoints/implement_027_auth.json"
}
```

### Progress Tracking Across Plan Hierarchy

Wave execution updates all levels of plan hierarchy:

**Level 2** (Stage file):
```markdown
### Stage 1: Database Schema
- [x] Design user table
- [x] Design session table
- [ ] Create migration scripts
```

**Level 1** (Phase file aggregates stages):
```markdown
### Phase 2: Database Implementation
**Progress**: 2/3 stages complete (67%)
- [x] Stage 1: Database Schema (2/3 tasks)
- [ ] Stage 2: Query Layer
- [ ] Stage 3: Testing
```

**Level 0** (Main plan aggregates phases):
```markdown
### Phase 2: Database Implementation
**Status**: In Progress (Wave 1)
**Progress**: 2/9 total tasks complete (22%)

See [phase_2_database.md](phase_2_database.md) for details.
```

**Checkpoint Propagation**:
Each executor creates checkpoints containing:
- Current wave number
- Phase/stage completion status
- Task-level checkbox states
- Updated plan file paths (all levels)
- Next wave to execute

### Cross-References to Patterns

**Wave-based execution implements**:
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Commands control orchestration
- [Parallel Execution Pattern](../concepts/patterns/parallel-execution.md) - Concurrent wave execution
- [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md) - Wave state preservation
- [Hierarchical Supervision Pattern](../concepts/patterns/hierarchical-supervision.md) - Coordinator → Executors

---

## Behavioral Injection Example: Complete Workflow

This section demonstrates a complete workflow using the behavioral injection pattern with topic-based artifact organization, showing research through planning phases.

**Key Concepts**:
- Topic-based artifact organization
- Behavioral injection pattern
- Metadata-only context passing
- Cross-reference requirements

### Workflow: User Authentication Research and Planning

#### Step 1: Calculate Topic Directory

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact/artifact-creation.sh"

FEATURE_DESCRIPTION="User authentication with OAuth 2.0"
TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE_DESCRIPTION" "specs")

echo "Topic directory: $TOPIC_DIR"
# Output: specs/027_user_authentication
```

**Key Points**:
- Topic directory calculated from feature description
- Sequential numbering (027 = next available number)
- All workflow artifacts will live in this directory

#### Step 2: Research Phase (Parallel Research Agents)

**Calculate Research Report Paths**:

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

**Invoke Research Agents in Parallel**:

```bash
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
    Return metadata: {path, summary (<=50 words), key_findings[]}
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
    Return metadata: {path, summary (<=50 words), key_findings[]}
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
    Return metadata: {path, summary (<=50 words), key_findings[]}
}
```

**Key Points**:
- All 3 agents invoked in parallel (single message)
- Each agent receives pre-calculated path
- Agents use `research-specialist.md` behavioral guidelines
- Agents return metadata only (not full content)
- 40-60% time savings vs sequential invocation

**Extract Metadata**:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/metadata-extraction.sh"

# Verify artifacts created
VERIFIED_OAUTH=$(verify_artifact_or_recover "$REPORT_OAUTH" "oauth_security")
VERIFIED_DB=$(verify_artifact_or_recover "$REPORT_DB" "database_design")
VERIFIED_BEST=$(verify_artifact_or_recover "$REPORT_BEST_PRACTICES" "best_practices")

# Extract metadata only (95% context reduction)
METADATA_OAUTH=$(extract_report_metadata "$VERIFIED_OAUTH")
METADATA_DB=$(extract_report_metadata "$VERIFIED_DB")
METADATA_BEST=$(extract_report_metadata "$VERIFIED_BEST")

# Context reduction: 3 reports x 5000 tokens = 15000 tokens
#                    3 metadata x 250 tokens = 750 tokens
#                    Reduction: 95% (15000 → 750)
```

#### Step 3: Planning Phase (Plan Architect Agent)

**Calculate Plan Path**:

```bash
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")

echo "Plan path: $PLAN_PATH"
# Output: specs/027_user_authentication/plans/027_implementation.md
```

**Invoke Plan Architect Agent**:

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
- Agent includes "Research Reports" metadata section
- Agent uses Write tool (not SlashCommand)

#### Step 4: Complete Workflow Artifact Structure

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

**Benefits Demonstrated**:
1. **Topic-Based Organization**: All artifacts in single directory (easy navigation)
2. **Behavioral Injection**: Commands control orchestration, agents execute
3. **Metadata-Only Passing**: 95% context reduction throughout workflow
4. **Parallel Execution**: 40-60% time savings with parallel agents
5. **Cross-Referencing**: Complete audit trail from summary to research
6. **Path Control**: Commands pre-calculate paths (consistent numbering)
7. **No Recursion**: Agents use Write tool (never SlashCommand)

**Context Reduction Metrics**:

**Without Behavioral Injection**:
- Research phase: 3 reports x 5000 tokens = 15000 tokens
- Planning phase: 15000 tokens + plan 3000 tokens = 18000 tokens
- Total context: 18000 tokens (90% of available context)

**With Behavioral Injection**:
- Research phase: 3 metadata x 250 tokens = 750 tokens
- Planning phase: 750 tokens + plan metadata 200 tokens = 950 tokens
- Total context: 950 tokens (5% of available context)

**Reduction**: 95% (18000 → 950 tokens)

---

## Advanced Features

### Hierarchy Review

After operations complete, the system analyzes plan structure:

```
Reviewing plan hierarchy...

Hierarchy Analysis:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Current Structure:
  - Level: 1 (phase expansion)
  - Total Phases: 5
  - Expanded: 2
  - Balance: Good

Optimization Opportunities:

1. Phase 2: Authentication (complexity 9)
   Recommendation: Expand into stages
   Reason: Still highly complex after expansion

2. Phases 4-5: Testing and Deployment
   Recommendation: Consider merging
   Reason: Closely related, similar complexity
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Second-Round Analysis

The system can re-analyze to find new candidates:

```
Running second-round analysis...

New Expansion Candidates:
  - Phase 2: Authentication (complexity increased to 9)

Would you like to proceed with second-round expansion? (y/n):
```

### User Approval Gates

You control when operations proceed:

```
Recommendations Ready for Review
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Operations to perform:
  1. Expand phase 2 into stages
  2. Merge phases 4 and 5

Estimated time: 60s

Proceed with these operations? (y/n):
```

---

## See Also

- [Agent Development Guide](../guides/development/agent-development/agent-development-fundamentals.md) - Creating agent behavioral files
- [Command Development Guide](../guides/development/command-development/command-development-fundamentals.md) - Invoking agents from commands
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Pattern details
- [Troubleshooting Guide](../troubleshooting/agent-delegation-troubleshooting.md) - Common issues and solutions

---

## Related Documentation

- [Overview](orchestration-guide-overview.md) - Quick start, architecture, and artifact-based aggregation
- [Patterns](orchestration-guide-patterns.md) - Context pruning, user workflows, and error recovery
- [Troubleshooting](orchestration-guide-troubleshooting.md) - Common issues, diagnostics, and reference
