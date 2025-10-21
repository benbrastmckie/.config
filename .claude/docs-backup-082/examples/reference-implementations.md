# Reference Implementations

This document identifies commands that correctly implement the behavioral injection pattern with topic-based artifact organization.

**Related Documentation**:
- [Command Authoring Guide](../guides/command-authoring-guide.md) - Complete command authoring patterns
- [Agent Authoring Guide](../guides/agent-authoring-guide.md) - Agent behavioral file creation
- [Behavioral Injection Workflow](./behavioral-injection-workflow.md) - Complete workflow example
- [Correct Agent Invocation](./correct-agent-invocation.md) - Task tool examples

## Overview

These commands serve as reference implementations for correct agent invocation patterns. Use them as templates when creating new commands or modifying existing ones.

**What Makes These Reference Implementations**:
- ✅ Pre-calculate topic-based artifact paths
- ✅ Inject complete context into agents
- ✅ Agents create artifacts at exact paths
- ✅ Extract metadata only (not full content)
- ✅ Include cross-references in metadata
- ✅ Achieve 90-95% context reduction

## Reference Commands

### /plan Command

**File**: `.claude/commands/plan.md`

**What It Does**: Creates implementation plans with optional research phase.

**Key Sections**:
- **Lines 63-195**: Research agent delegation (optional, for complex features)
- **Lines 196-285**: Plan architect agent invocation
- **Lines 286-325**: Artifact verification and metadata extraction

**Pattern Demonstrated**:

```bash
# 1. Calculate topic directory
TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE_DESCRIPTION" "specs")

# 2. Research phase (if needed) - parallel agents
for topic in "${RESEARCH_TOPICS[@]}"; do
  REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "$topic" "")
  # Invoke research-specialist agent with REPORT_PATH
done

# 3. Collect research report paths for cross-referencing
RESEARCH_REPORT_PATHS=$(find "$TOPIC_DIR/reports" -name "*.md")

# 4. Plan architect invocation
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")
Task {
  prompt: |
    **Research Reports**: ${RESEARCH_REPORT_PATHS}
    **Plan Output Path**: ${PLAN_PATH}
    Create plan with "Research Reports" metadata section.
}

# 5. Extract plan metadata
PLAN_METADATA=$(extract_plan_metadata "$PLAN_PATH")
```

**Why It's a Good Reference**:
- Topic-based path calculation (steps 1-2)
- Parallel research agents (2-4 agents)
- Pre-calculated paths for all artifacts
- Cross-references (plan includes research reports)
- Metadata-only extraction (95% context reduction)

**Use This As Template For**:
- Commands that create implementation plans
- Commands with optional research phase
- Commands needing parallel agent execution

### /report Command

**File**: `.claude/commands/report.md`

**What It Does**: Creates research reports for specified topics.

**Key Sections**:
- **Lines 92-166**: Spec-updater agent invocation
- **Lines 167-215**: Topic-based artifact organization
- **Lines 216-245**: Metadata extraction

**Pattern Demonstrated**:

```bash
# 1. Calculate topic directory
TOPIC=$(slugify "$RESEARCH_TOPIC")
TOPIC_DIR=$(get_or_create_topic_dir "$TOPIC" "specs")

# 2. Calculate report path
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "$TOPIC" "")

# 3. Invoke spec-updater agent
Task {
  prompt: |
    **Research Topic**: ${RESEARCH_TOPIC}
    **Report Output Path**: ${REPORT_PATH}
    Create report at exact path using Write tool.
}

# 4. Verify and extract metadata
VERIFIED_PATH=$(verify_artifact_or_recover "$REPORT_PATH" "$TOPIC")
METADATA=$(extract_report_metadata "$VERIFIED_PATH")
```

**Why It's a Good Reference**:
- Simple single-agent pattern
- Topic-based path calculation
- Agent creates artifact directly (no slash commands)
- Metadata extraction with verification
- Clear artifact path control

**Use This As Template For**:
- Single-agent workflows
- Research and analysis tasks
- Simple artifact creation commands

### /debug Command

**File**: `.claude/commands/debug.md`

**What It Does**: Investigates bugs and creates debug reports.

**Key Sections**:
- **Lines 65-248**: Parallel hypothesis investigation
- **Lines 186-230**: Debug analyst agent invocations
- **Lines 249-298**: Metadata aggregation and synthesis

**Pattern Demonstrated**:

```bash
# 1. Calculate topic directory
ISSUE_SLUG=$(slugify "$ISSUE_DESCRIPTION")
TOPIC_DIR=$(get_or_create_topic_dir "$ISSUE_SLUG" "specs")

# 2. Calculate debug report paths (one per hypothesis)
DEBUG_REPORT_1=$(create_topic_artifact "$TOPIC_DIR" "debug" "hypothesis_1" "")
DEBUG_REPORT_2=$(create_topic_artifact "$TOPIC_DIR" "debug" "hypothesis_2" "")
DEBUG_REPORT_3=$(create_topic_artifact "$TOPIC_DIR" "debug" "hypothesis_3" "")

# 3. Invoke debug-analyst agents in parallel (single message)
Task { prompt: "**Debug Report Path**: ${DEBUG_REPORT_1} ..." }
Task { prompt: "**Debug Report Path**: ${DEBUG_REPORT_2} ..." }
Task { prompt: "**Debug Report Path**: ${DEBUG_REPORT_3} ..." }

# 4. Extract metadata from all debug reports
METADATA_1=$(extract_debug_metadata "$DEBUG_REPORT_1")
METADATA_2=$(extract_debug_metadata "$DEBUG_REPORT_2")
METADATA_3=$(extract_debug_metadata "$DEBUG_REPORT_3")

# 5. Synthesize findings (metadata only)
ROOT_CAUSE=$(aggregate_root_causes "$METADATA_1" "$METADATA_2" "$METADATA_3")
```

**Why It's a Good Reference**:
- Parallel agent execution (3+ agents)
- Multiple hypothesis investigation
- Pre-calculated paths for all agents
- Metadata aggregation (not full content)
- Time savings: 60-70% vs sequential

**Use This As Template For**:
- Parallel investigation workflows
- Multiple hypothesis testing
- Commands needing multiple specialized agents

### /orchestrate Command (After Phase 3 Fix)

**File**: `.claude/commands/orchestrate.md`

**What It Does**: Coordinates end-to-end workflows (research → planning → implementation → documentation).

**Key Sections**:
- **Lines 417-617**: Research phase with parallel agents
- **Lines 1086-1150**: Planning phase with behavioral injection
- **Lines 1234-1389**: Summary phase with cross-references

**Pattern Demonstrated**:

```bash
# Research Phase
for topic in "${RESEARCH_TOPICS[@]}"; do
  REPORT_PATH=$(create_topic_artifact "$WORKFLOW_TOPIC_DIR" "reports" "$topic" "")
  # Invoke research-specialist agents in parallel
done

# Planning Phase (behavioral injection - Phase 3 fix)
PLAN_PATH=$(create_topic_artifact "$WORKFLOW_TOPIC_DIR" "plans" "implementation" "")
RESEARCH_REPORTS=$(find "$WORKFLOW_TOPIC_DIR/reports" -name "*.md")
Task {
  prompt: |
    **Research Reports**: ${RESEARCH_REPORTS}
    **Plan Output Path**: ${PLAN_PATH}
    Include "Research Reports" metadata section.
}

# Summary Phase (cross-references - Revision 3)
SUMMARY_PATH=$(create_topic_artifact "$WORKFLOW_TOPIC_DIR" "summaries" "workflow" "")
ALL_ARTIFACTS="
Research Reports: ${RESEARCH_REPORTS}
Implementation Plan: ${PLAN_PATH}
"
Task {
  prompt: |
    **Summary Output Path**: ${SUMMARY_PATH}
    **Artifacts Generated**: ${ALL_ARTIFACTS}
    Include "Artifacts Generated" section with all paths.
}
```

**Why It's a Good Reference**:
- Multi-phase workflow coordination
- Behavioral injection pattern (planning phase)
- Cross-reference requirements (Revision 3)
- Metadata-only passing between phases
- Context reduction: 95% (168.9k → <30k tokens)

**Use This As Template For**:
- Complex multi-phase workflows
- Commands coordinating multiple agents
- Workflows requiring cross-referenced artifacts

## Common Patterns Across Reference Implementations

### Pattern 1: Topic-Based Path Calculation

**All reference implementations**:
```bash
# Always calculate topic directory first
TOPIC_DIR=$(get_or_create_topic_dir "$DESCRIPTION" "specs")

# Then calculate artifact paths within topic
ARTIFACT_PATH=$(create_topic_artifact "$TOPIC_DIR" "$TYPE" "$NAME" "")
```

**Why**: Enforces topic-based organization, sequential numbering, consistent structure.

### Pattern 2: Pre-Calculate Before Agent Invocation

**All reference implementations**:
```bash
# WRONG: Don't do this
Task { prompt: "Create report in appropriate location." }

# RIGHT: Do this
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "research" "")
Task { prompt: "**Report Output Path**: ${REPORT_PATH}" }
```

**Why**: Commands control paths, agents execute at exact locations.

### Pattern 3: Metadata-Only Extraction

**All reference implementations**:
```bash
# After agent creates artifact
METADATA=$(extract_report_metadata "$REPORT_PATH")
SUMMARY=$(echo "$METADATA" | jq -r '.summary')  # 50 words, not full content

# NOT this
FULL_CONTENT=$(cat "$REPORT_PATH")  # ❌ Context bloat
```

**Why**: 95% context reduction, maintains <30% context usage.

### Pattern 4: Cross-Reference Requirements (Revision 3)

**plan-architect agents**:
```markdown
## Metadata
- **Research Reports**:
  - specs/042_auth/reports/042_security.md
  - specs/042_auth/reports/043_patterns.md
```

**doc-writer agents (summarizers)**:
```markdown
## Artifacts Generated

### Research Reports
- specs/042_auth/reports/042_security.md
- specs/042_auth/reports/043_patterns.md

### Implementation Plan
- specs/042_auth/plans/042_implementation.md
```

**Why**: Enables audit trail, traceability, quick navigation.

### Pattern 5: Parallel Agent Execution

**When multiple agents needed**:
```bash
# Single message, multiple Task calls
Task { ... agent 1 ... }
Task { ... agent 2 ... }
Task { ... agent 3 ... }

# NOT separate messages (slower)
Task { ... agent 1 ... }
# (wait)
Task { ... agent 2 ... }
```

**Why**: 40-60% time savings, all agents start simultaneously.

## Anti-Patterns (Do NOT Use These Commands as Reference)

### ❌ OLD /orchestrate (Before Phase 3 Fix)

**Problem**: plan-architect agent invoked /plan command

**Why Wrong**:
- Loss of control over plan path
- No metadata extraction (context bloat)
- Violates behavioral injection pattern

**Fixed In**: Phase 3 (commit c2954f3f)

### ❌ OLD /implement (Before Phase 2 Fix)

**Problem**: code-writer agent invoked /implement command (recursion risk)

**Why Wrong**:
- Circular delegation chain (/implement → code-writer → /implement)
- Infinite recursion possible
- Violates command/agent separation

**Fixed In**: Phase 2 (commit aa33d0db)

### ❌ Any Command That Loads Full Artifact Content

**Problem**: Commands that load full reports/plans into context

**Why Wrong**:
- Context bloat (5000+ tokens per artifact)
- No context reduction achieved
- May exceed context limits
- Violates metadata-only passing principle

**Correct Approach**: Use `extract_report_metadata()` instead

## How to Use This Guide

### Starting a New Command

1. **Choose reference implementation**:
   - Single agent → Use `/report` as template
   - Parallel agents → Use `/debug` as template
   - Multi-phase workflow → Use `/orchestrate` as template

2. **Copy key patterns**:
   - Topic-based path calculation
   - Agent invocation structure
   - Metadata extraction

3. **Adapt for your use case**:
   - Replace agent types (research-specialist, plan-architect, etc.)
   - Adjust artifact types (reports, plans, debug, etc.)
   - Add cross-references if needed

### Modifying an Existing Command

1. **Check current pattern**:
   - Does it pre-calculate paths? (Should: Yes)
   - Do agents invoke slash commands? (Should: No)
   - Does it extract metadata only? (Should: Yes)

2. **Compare to reference implementation**:
   - Find similar reference command
   - Identify differences
   - Apply reference pattern

3. **Test with validators**:
   - Run `.claude/tests/validate_command_behavioral_injection.sh`
   - Run `.claude/tests/validate_topic_based_artifacts.sh`
   - Verify 0 violations

### Learning from Reference Implementations

**Read in this order**:
1. `/report` - Simplest pattern (single agent)
2. `/plan` - Adds research phase (parallel agents)
3. `/debug` - Demonstrates parallel investigation
4. `/orchestrate` - Complete multi-phase workflow

**For each reference**:
- Read "Key Sections" to find relevant code
- Study path calculation approach
- Note agent invocation structure
- Observe metadata extraction
- Check cross-reference handling

## Validation

### Verify Your Command Follows Reference Patterns

```bash
# Run behavioral injection compliance check
.claude/tests/validate_command_behavioral_injection.sh your-command.md

# Run topic-based artifact organization check
.claude/tests/validate_topic_based_artifacts.sh

# Run anti-pattern detection
.claude/tests/validate_no_agent_slash_commands.sh
```

**Expected Results**:
- ✅ 0 violations in all validators
- ✅ All artifact paths in topic-based structure
- ✅ No slash command invocations from agents

## See Also

- [Command Authoring Guide](../guides/command-authoring-guide.md) - Complete command patterns
- [Agent Authoring Guide](../guides/agent-authoring-guide.md) - Agent behavioral files
- [Behavioral Injection Workflow](./behavioral-injection-workflow.md) - Complete workflow
- [Correct Agent Invocation](./correct-agent-invocation.md) - Task tool examples
- [Troubleshooting Guide](../troubleshooting/agent-delegation-issues.md) - Common issues
