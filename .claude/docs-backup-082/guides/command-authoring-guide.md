# Command Authoring Guide

## Purpose

This guide provides comprehensive guidelines for command authors on how to properly invoke agents using the **behavioral injection pattern**.

**Target Audience**: Developers creating or modifying slash commands that use agents.

**Related Documentation**:
- [Agent Authoring Guide](agent-authoring-guide.md) - How to create agent behavioral files
- [Hierarchical Agent Architecture](../concepts/hierarchical_agents.md) - Overall architecture
- [Troubleshooting Guide](../troubleshooting/agent-delegation-issues.md) - Common issues

## Section 1: When to Use Agents vs Direct Implementation

### Use Agents When:

✅ **Complex Analysis Required**
- Codebase research across multiple files
- Pattern identification and comparison
- Security or performance analysis

✅ **Artifact Generation**
- Research reports with structured findings
- Implementation plans with phases
- Debug reports with root cause analysis

✅ **Parallel Execution Beneficial**
- Multiple independent research topics
- Parallel hypothesis testing
- Concurrent file analysis

### Use Direct Implementation When:

❌ **Simple File Operations**
- Single file creation
- Basic string replacement
- Directory creation

❌ **Sequential Dependencies**
- Each step depends on previous results
- Cannot be parallelized
- Requires intermediate validation

❌ **Command-Specific Logic**
- Path calculation
- Artifact verification
- Metadata extraction

### Decision Tree

```
Need specialized analysis?
  ↓ YES
  How many independent tasks?
    ↓ 2-4 tasks
    Invoke multiple agents in PARALLEL ✅
    ↓ 1 task
    Invoke single agent ✅
  ↓ NO
  Simple file operation?
    ↓ YES
    Direct implementation (Write/Edit tool) ✅
    ↓ NO
    Complex orchestration?
      ↓ YES
      Break into phases, use agents per phase ✅
```

## Section 2: Pre-Calculating Topic-Based Artifact Paths

### Why Pre-Calculate Paths?

**Reasons:**
1. **Control**: Command controls exact artifact locations
2. **Topic Organization**: Enforces `specs/{NNN_topic}/` structure
3. **Consistent Numbering**: Sequential NNN across artifact types
4. **Verification**: Can verify artifact created at expected path
5. **Metadata Extraction**: Know exact path for metadata loading

### Standard Path Calculation Pattern

```bash
# Source artifact creation utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"

# Step 1: Get or create topic directory
TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE_DESCRIPTION" "specs")
# Result: specs/042_authentication (creates if doesn't exist)

# Step 2: Calculate artifact path
ARTIFACT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "security_analysis" "")
# Result: specs/042_authentication/reports/042_security_analysis.md

# Step 3: Use path in agent invocation
echo "Artifact will be created at: $ARTIFACT_PATH"
```

### Topic-Based Directory Structure

**Reference**: `.claude/docs/README.md` lines 114-138

```
specs/042_authentication/
├── reports/          Research reports (gitignored)
│   ├── 042_security_analysis.md
│   ├── 042_best_practices.md
│   └── 042_framework_comparison.md
├── plans/            Implementation plans (gitignored)
│   ├── 042_implementation.md
│   └── phase_2_backend.md
├── summaries/        Workflow summaries (gitignored)
│   └── 042_workflow_summary.md
├── debug/            Debug reports (COMMITTED!)
│   └── 042_investigation_auth_failure.md
├── scripts/          Investigation scripts (temp)
└── outputs/          Test outputs (temp)
```

### Artifact Type Selection

| Artifact Type | Gitignored? | Use Case |
|---------------|-------------|----------|
| `reports/` | Yes | Research findings, analysis |
| `plans/` | Yes | Implementation plans |
| `summaries/` | Yes | Workflow summaries |
| `debug/` | **NO** | Debug reports (keep history!) |
| `scripts/` | Yes | Temporary investigation scripts |
| `outputs/` | Yes | Test outputs, temporary data |

### Path Calculation Utilities

**Function**: `get_or_create_topic_dir(description, base_dir)`
```bash
# Create or find topic directory
TOPIC_DIR=$(get_or_create_topic_dir "authentication system" "specs")
# Creates: specs/042_authentication (if doesn't exist)
# Returns: specs/042_authentication (if exists)
```

**Function**: `create_topic_artifact(topic_dir, artifact_type, name, content)`
```bash
# Calculate next artifact path with sequential numbering
ARTIFACT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "security" "")
# Scans: specs/042_authentication/reports/ for max NNN
# Creates: specs/042_authentication/reports/043_security.md
# Returns: Full path to artifact
```

**Function**: `get_next_artifact_number(artifact_dir)`
```bash
# Get next sequential number
NEXT_NUM=$(get_next_artifact_number "specs/042_auth/reports")
# Result: "043" (if max existing is 042)
```

### Common Mistakes

**❌ WRONG: Manual Path Construction**
```bash
# DON'T DO THIS
REPORT_PATH="specs/reports/${FEATURE}.md"  # Flat structure, no numbering
```

**❌ WRONG: Hardcoded Numbers**
```bash
# DON'T DO THIS
REPORT_PATH="specs/042_auth/reports/042_security.md"  # May conflict with existing
```

**✅ CORRECT: Use Utilities**
```bash
# DO THIS
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE" "specs")
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "security" "")
```

## Section 3: Behavioral Injection Approaches

### Option A: Load and Inject Behavioral Prompt

**When to Use:**
- Need to modify agent behavior programmatically
- Want to add command-specific instructions
- Building dynamic prompts

**Implementation:**
```bash
# Load agent behavioral file
source "${CLAUDE_PROJECT_DIR}/.claude/lib/agent-loading-utils.sh"
AGENT_PROMPT=$(load_agent_behavioral_prompt "research-specialist")

# Build complete prompt with injected context
COMPLETE_PROMPT="$AGENT_PROMPT

## Task Context (Injected by Command)
**Feature**: ${FEATURE_DESCRIPTION}
**Research Focus**: Security patterns
**Report Output Path**: ${REPORT_PATH}
**Success Criteria**: Create report at exact path with security recommendations

## Additional Instructions
- Focus on authentication security
- Include OWASP Top 10 considerations
- Provide code examples
"

# Invoke agent with complete prompt
Task {
  subagent_type: "general-purpose"
  description: "Research security patterns for ${FEATURE}"
  prompt: "$COMPLETE_PROMPT"
}
```

**Advantages:**
- Full control over prompt content
- Can inject dynamic requirements
- Can override agent defaults

**Disadvantages:**
- More verbose
- Need to manage prompt assembly
- Risk of malformed prompts

### Option B: Reference Agent File (Simpler)

**When to Use:**
- Agent behavioral file is complete
- No need for custom instructions
- Prefer cleaner command code

**Implementation:**
```bash
# Calculate path (still required)
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "security" "")

# Invoke agent with file reference
Task {
  subagent_type: "general-purpose"
  description: "Research security patterns for ${FEATURE}"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent.

    **Research Focus**: Security patterns
    **Feature**: ${FEATURE_DESCRIPTION}
    **Report Output Path**: ${REPORT_PATH}

    Create the research report at the exact path provided.
    Return metadata: {path, summary, key_findings}
}
```

**Advantages:**
- Cleaner command code
- Agent file is single source of truth
- Easier to maintain

**Disadvantages:**
- Less flexibility for customization
- Agent file must be complete

### Which Approach to Use?

| Scenario | Recommended Approach |
|----------|---------------------|
| Standard agent invocation | **Option B** (reference file) |
| Need custom instructions | **Option A** (load + inject) |
| Building complex prompts | **Option A** (load + inject) |
| Simple, clean commands | **Option B** (reference file) |

## Section 4: Task Tool Invocation Templates

### Template 1: Research Agent

**Use Case**: Conduct codebase research and create report

```bash
# Pre-calculate topic-based path
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE_DESCRIPTION" "specs")
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "${RESEARCH_TOPIC}" "")

# Invoke research-specialist agent
Task {
  subagent_type: "general-purpose"
  description: "Research ${RESEARCH_TOPIC} for ${FEATURE_DESCRIPTION}"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent.

    **Research Focus**: ${RESEARCH_TOPIC}
    **Feature**: ${FEATURE_DESCRIPTION}
    **Report Output Path**: ${REPORT_PATH}

    Tasks:
    1. Search codebase for existing implementations
    2. Identify relevant patterns and utilities
    3. Research best practices
    4. Document alternative approaches

    Return metadata only: {path, summary, key_findings[]}
}

# After agent completes, verify artifact
source "${CLAUDE_PROJECT_DIR}/.claude/lib/agent-loading-utils.sh"
VERIFIED_PATH=$(verify_artifact_or_recover "$REPORT_PATH" "$RESEARCH_TOPIC")

# Extract metadata (not full content!)
METADATA=$(extract_report_metadata "$VERIFIED_PATH")
```

### Template 2: Plan Creation Agent

**Use Case**: Create implementation plan from requirements and research

```bash
# Pre-calculate topic-based plan path
TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE_DESCRIPTION" "specs")
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")

# Collect research report paths (if available)
RESEARCH_REPORTS=$(find "$TOPIC_DIR/reports" -name "*.md" 2>/dev/null | tr '\n' ',' || echo "")

# Invoke plan-architect agent
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan for ${FEATURE_DESCRIPTION}"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are acting as a Plan Architect Agent.

    **Feature**: ${FEATURE_DESCRIPTION}
    **Research Reports**: ${RESEARCH_REPORTS}
    **Plan Output Path**: ${PLAN_PATH}

    Create implementation plan with:
    - Metadata section (include "Research Reports" list)
    - Phases with tasks
    - Testing strategy
    - Success criteria

    Return metadata: {path, phase_count, complexity_score}
}

# Verify plan created
VERIFIED_PATH=$(verify_artifact_or_recover "$PLAN_PATH" "implementation")

# Extract plan metadata
PLAN_METADATA=$(extract_plan_metadata "$VERIFIED_PATH")
```

### Template 3: Debug Analysis Agent

**Use Case**: Investigate bug with parallel hypothesis testing

```bash
# Generate hypotheses (command logic)
HYPOTHESES='[
  {"hypothesis": "authentication token expiry", "priority": "high"},
  {"hypothesis": "database connection pool exhausted", "priority": "medium"},
  {"hypothesis": "race condition in cache update", "priority": "medium"}
]'

HYPOTHESIS_COUNT=$(echo "$HYPOTHESES" | jq 'length')

# Invoke multiple debug-analyst agents IN PARALLEL (single message!)
TOPIC_DIR=$(get_or_create_topic_dir "$ISSUE_DESCRIPTION" "specs")

for i in $(seq 0 $((HYPOTHESIS_COUNT - 1))); do
  HYPOTHESIS=$(echo "$HYPOTHESES" | jq -r ".[$i].hypothesis")
  PRIORITY=$(echo "$HYPOTHESES" | jq -r ".[$i].priority")

  # Calculate artifact path for this hypothesis
  SLUG="${HYPOTHESIS// /_}"
  DEBUG_PATH=$(create_topic_artifact "$TOPIC_DIR" "debug" "investigation_${SLUG}" "")

  # Invoke agent (all in ONE message for parallel execution)
  Task {
    subagent_type: "general-purpose"
    description: "Investigate: ${HYPOTHESIS}"
    prompt: |
      Read and follow behavioral guidelines from:
      ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

      You are acting as a Debug Analyst Agent.

      **Issue**: ${ISSUE_DESCRIPTION}
      **Hypothesis**: ${HYPOTHESIS}
      **Priority**: ${PRIORITY}
      **Artifact Path**: ${DEBUG_PATH}

      Investigate this hypothesis and create debug report at exact path.
      Return metadata: {path, summary, findings, proposed_fixes}
  }
done

# CRITICAL: All Task invocations above MUST be in ONE message for parallel execution!
```

### Template 4: Documentation Agent

**Use Case**: Create workflow summary with cross-references

```bash
# Calculate summary path
TOPIC_DIR="specs/042_authentication"  # Existing topic from workflow
SUMMARY_PATH=$(create_topic_artifact "$TOPIC_DIR" "summaries" "workflow_summary" "")

# Collect all artifact paths from workflow
RESEARCH_REPORTS=$(find "$TOPIC_DIR/reports" -name "*.md" | tr '\n' ',')
PLAN_PATH=$(find "$TOPIC_DIR/plans" -name "*.md" | head -1)
DEBUG_REPORTS=$(find "$TOPIC_DIR/debug" -name "*.md" | tr '\n' ',' || echo "")

# Invoke doc-writer agent
Task {
  subagent_type: "general-purpose"
  description: "Create workflow summary for ${FEATURE}"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/doc-writer.md

    You are acting as a Documentation Writer Agent.

    **Workflow**: ${FEATURE_DESCRIPTION}
    **Summary Output Path**: ${SUMMARY_PATH}

    **Artifacts Generated**:
    - Research Reports: ${RESEARCH_REPORTS}
    - Implementation Plan: ${PLAN_PATH}
    - Debug Reports: ${DEBUG_REPORTS}

    Create workflow summary including:
    - Executive summary
    - Artifacts Generated section (with all paths)
    - Key decisions made
    - Lessons learned

    Return metadata: {path, summary}
}
```

## Section 5: Artifact Verification Patterns

### Basic Verification

```bash
# After agent completes
ARTIFACT_PATH="specs/042_auth/reports/042_security.md"

# Verify file exists
if [ ! -f "$ARTIFACT_PATH" ]; then
  echo "Error: Agent did not create artifact at expected path"
  exit 1
fi

echo "✓ Artifact verified at: $ARTIFACT_PATH"
```

### Verification with Recovery

```bash
# Use recovery utility
source "${CLAUDE_PROJECT_DIR}/.claude/lib/agent-loading-utils.sh"

EXPECTED_PATH="specs/042_auth/reports/042_security.md"
TOPIC_SLUG="security"  # Search term for recovery

VERIFIED_PATH=$(verify_artifact_or_recover "$EXPECTED_PATH" "$TOPIC_SLUG")

if [ $? -eq 0 ]; then
  echo "✓ Artifact found at: $VERIFIED_PATH"

  if [ "$VERIFIED_PATH" != "$EXPECTED_PATH" ]; then
    echo "⚠ Path mismatch recovered (agent used different number)"
  fi
else
  echo "✗ Artifact not found, recovery failed"
  exit 1
fi
```

### Topic-Based Verification

```bash
# Verify artifact is in topic-based structure
ARTIFACT_PATH="specs/042_auth/reports/042_security.md"

# Check path format
if [[ ! "$ARTIFACT_PATH" =~ ^specs/[0-9]{3}_[^/]+/(reports|plans|debug|summaries)/ ]]; then
  echo "Error: Artifact not in topic-based structure"
  echo "Expected format: specs/{NNN_topic}/{artifact_type}/{NNN}_name.md"
  echo "Got: $ARTIFACT_PATH"
  exit 1
fi

echo "✓ Artifact follows topic-based organization"
```

### Verification with Fallback Creation

```bash
# Attempt verification, create fallback if needed
VERIFIED_PATH=$(verify_artifact_or_recover "$ARTIFACT_PATH" "$TOPIC_SLUG" 2>/dev/null)

if [ $? -ne 0 ]; then
  echo "⚠ Agent did not create artifact, creating fallback"

  # Create minimal fallback artifact
  cat > "$ARTIFACT_PATH" <<EOF
# ${FEATURE} Research Report

## Metadata
- **Status**: Fallback (agent failed to create)
- **Date**: $(date -u +%Y-%m-%d)

## Note
This is a fallback artifact created because the agent did not
create the expected report.

Manual intervention required.
EOF

  echo "✓ Fallback artifact created at: $ARTIFACT_PATH"
  VERIFIED_PATH="$ARTIFACT_PATH"
fi
```

## Section 6: Metadata Extraction

### Why Extract Metadata Only?

**Context Reduction**: 95% reduction in token usage

**Example**:
- Full report: 5000 tokens
- Metadata only: 250 tokens (path + summary + findings)
- Reduction: 95%

### Metadata Extraction Pattern

```bash
# Source metadata extraction utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"

# Extract report metadata
REPORT_METADATA=$(extract_report_metadata "$REPORT_PATH")

# Parse metadata fields
SUMMARY=$(echo "$REPORT_METADATA" | jq -r '.summary')
KEY_FINDINGS=$(echo "$REPORT_METADATA" | jq -r '.key_findings[]')
RECOMMENDATIONS=$(echo "$REPORT_METADATA" | jq -r '.recommendations[]')

echo "Report: $REPORT_PATH"
echo "Summary: $SUMMARY"
echo "Findings: $KEY_FINDINGS"
```

### Metadata Format (JSON)

```json
{
  "path": "specs/042_auth/reports/042_security.md",
  "summary": "Research on authentication security patterns for web applications...",
  "key_findings": [
    "OWASP recommends bcrypt for password hashing",
    "JWT tokens should expire within 15 minutes",
    "Multi-factor authentication reduces breach risk by 99%"
  ],
  "recommendations": [
    "Implement JWT with short expiry times",
    "Add MFA support to authentication flow",
    "Use bcrypt with cost factor 12"
  ],
  "file_paths": [
    "src/auth/authentication.js",
    "src/auth/token-manager.js"
  ]
}
```

### Metadata Extraction Functions

**For Reports**:
```bash
extract_report_metadata() {
  local report_path="$1"
  # Returns JSON with: path, summary, key_findings, recommendations, file_paths
}
```

**For Plans**:
```bash
extract_plan_metadata() {
  local plan_path="$1"
  # Returns JSON with: path, phase_count, complexity_score, estimated_hours
}
```

**For Debug Reports**:
```bash
extract_debug_metadata() {
  local debug_path="$1"
  # Returns JSON with: path, summary, findings, proposed_fixes, priority
}
```

## Section 7: Reference Implementations

### Example 1: `/plan` Command (Research Phase)

**File**: `/home/benjamin/.config/.claude/commands/plan.md` (lines 132-167)

**Pattern**: Parallel research with topic-based paths

```bash
# Calculate topic directory
TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE_DESCRIPTION" "specs")

# Invoke 2-3 research agents in parallel (SINGLE message!)
for topic in "patterns" "best_practices" "alternatives"; do
  REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "${topic}" "")

  Task {
    subagent_type: "general-purpose"
    description: "Research ${topic} for ${FEATURE}"
    prompt: |
      Read and follow behavioral guidelines from:
      /home/benjamin/.config/.claude/agents/research-specialist.md

      You are acting as a Research Specialist Agent.

      Research Focus: ${topic}
      Feature: ${FEATURE_DESCRIPTION}
      Report Output Path: ${REPORT_PATH}

      Return metadata: {path, summary, key_findings[]}
  }
done

# After all agents complete, extract metadata
RESEARCH_METADATA=$(for report in "$TOPIC_DIR"/reports/*.md; do
  extract_report_metadata "$report"
done)
```

**Key Learnings**:
- ✅ Pre-calculates topic-based paths
- ✅ Invokes agents in parallel (single message)
- ✅ Extracts metadata only (no full content)
- ✅ Uses topic directory for all artifacts

### Example 2: `/report` Command (Spec Updater Integration)

**File**: `/home/benjamin/.config/.claude/commands/report.md` (lines 92-166)

**Pattern**: Report creation + cross-reference updates

```bash
# Create report (via agent or direct)
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "$TOPIC" "")

# ... (report creation logic)

# Invoke spec-updater agent to maintain cross-references
Task {
  subagent_type: "general-purpose"
  description: "Update cross-references for new report"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/spec-updater.md

    You are acting as a Spec Updater Agent.

    Context:
    - Report created at: ${REPORT_PATH}
    - Topic directory: ${TOPIC_DIR}
    - Related plan (if exists): ${PLAN_PATH}
    - Operation: report_creation

    Update cross-references between report and plan.
    Return: {status, plan_files_modified[], warnings[]}
}
```

**Key Learnings**:
- ✅ Uses specialized agent for cross-reference management
- ✅ Agent receives artifact paths (doesn't calculate them)
- ✅ Agent uses Edit tool to update metadata sections
- ✅ Returns status metadata (not full content)

### Example 3: `/debug` Command (Parallel Hypothesis Testing)

**File**: `/home/benjamin/.config/.claude/commands/debug.md` (lines 186-230)

**Pattern**: Parallel debug analysis with topic-based debug/ artifacts

```bash
# Generate hypotheses (command logic, not agent)
HYPOTHESES=$(analyze_issue_and_generate_hypotheses "$ISSUE_DESCRIPTION")

# Invoke debug-analyst agents in parallel
TOPIC_DIR=$(get_or_create_topic_dir "$ISSUE_DESCRIPTION" "specs")

for hypothesis in "${HYPOTHESES[@]}"; do
  DEBUG_PATH=$(create_topic_artifact "$TOPIC_DIR" "debug" "investigation_${hypothesis}" "")

  Task {
    subagent_type: "general-purpose"
    description: "Investigate: ${hypothesis}"
    prompt: |
      Read and follow behavioral guidelines from:
      /home/benjamin/.config/.claude/agents/debug-analyst.md

      You are acting as a Debug Analyst Agent.

      Issue: ${ISSUE_DESCRIPTION}
      Hypothesis: ${hypothesis}
      Artifact Path: ${DEBUG_PATH}

      Create debug report at exact path.
      Return metadata: {path, summary, findings, proposed_fixes}
  }
done
```

**Key Learnings**:
- ✅ Parallel agent invocation (all in one message)
- ✅ Debug reports in topic-based debug/ subdirectory
- ✅ Debug reports COMMITTED to git (unlike other artifacts)
- ✅ Each agent investigates one hypothesis independently

## Section 8: Topic-Based Artifact Organization

### Directory Structure Standards

**Reference**: `.claude/docs/README.md` lines 114-138

### Topic Directory Creation

```bash
# Get or create topic directory
TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE_DESCRIPTION" "specs")

# How it works:
# 1. Slugifies feature description: "User Authentication" → "user_authentication"
# 2. Finds existing topic dir: specs/042_user_authentication (if exists)
# 3. Creates new topic dir: specs/043_user_authentication (if doesn't exist)
# 4. Returns: absolute path to topic directory
```

### Artifact Numbering Conventions

**Sequential Numbering**: NNN format (001, 042, 127)

**Numbering Scope**:
- Topic number: Unique across all topics in specs/
- Artifact number: Sequential within artifact_type subdirectory

**Example**:
```
specs/042_authentication/     ← Topic number 042
├── reports/
│   ├── 042_security.md       ← Artifact number matches topic
│   ├── 043_best_practices.md ← Next sequential number
│   └── 044_frameworks.md     ← Next sequential number
└── plans/
    ├── 042_implementation.md ← Artifact numbering independent of reports/
    └── 043_rollback_plan.md  ← Next sequential in plans/
```

### Subdirectory Patterns for Complex Artifacts

**Multiple Reports from One Task**:
```
specs/042_auth/reports/042_research/
├── 042_security_patterns.md
├── 042_authentication_methods.md
└── 042_framework_comparison.md
```

**Structured Plan with Expanded Phases**:
```
specs/042_auth/plans/042_implementation/
├── 042_implementation.md          # Level 0 (main plan)
├── phase_2_backend.md             # Level 1 (expanded phase)
├── phase_4_integration.md         # Level 1 (expanded phase)
└── phase_2/                       # Level 2 (stages)
    ├── stage_1_database.md
    └── stage_2_api.md
```

### Gitignore Requirements

**Gitignored** (ephemeral artifacts):
- `reports/` - Research findings (regenerate as needed)
- `plans/` - Implementation plans (regenerate as needed)
- `summaries/` - Workflow summaries (regenerate as needed)
- `scripts/` - Temporary investigation scripts
- `outputs/` - Test outputs, temporary data

**Committed** (historical artifacts):
- `debug/` - Debug reports (preserve debugging history!)

**Why debug/ is committed**:
- Historical record of bugs and fixes
- Learning resource for future debugging
- Audit trail for root cause analysis

### Cross-Referencing Within Topics

**Relative Paths** (within same topic):
```markdown
## Related Artifacts

- Implementation Plan: [../plans/042_implementation.md](../plans/042_implementation.md)
- Security Research: [./042_security.md](./042_security.md)
```

**Absolute Paths** (across topics):
```markdown
## Dependencies

- Authentication Plan: [/home/benjamin/.config/.claude/specs/042_auth/plans/042_implementation.md]
```

**Why Relative Paths Within Topics**:
- Topic directories may move or be copied
- Relative paths remain valid
- Easier to read and maintain

## Best Practices Summary

### DO:
- ✅ Pre-calculate artifact paths using `create_topic_artifact()`
- ✅ Use topic-based structure (`specs/{NNN_topic}/`)
- ✅ Invoke multiple agents in parallel (single message)
- ✅ Verify artifacts after agent completion
- ✅ Extract metadata only (95% context reduction)
- ✅ Include cross-references in all artifacts
- ✅ Follow reference implementations (/plan, /report, /debug)

### DON'T:
- ❌ Let agents calculate their own paths
- ❌ Use flat directory structure (specs/reports/)
- ❌ Invoke agents sequentially when parallel possible
- ❌ Load full artifact content into context
- ❌ Skip artifact verification
- ❌ Hardcode artifact numbers
- ❌ Construct paths manually (use utilities)

## Troubleshooting

See [Agent Delegation Troubleshooting Guide](../troubleshooting/agent-delegation-issues.md) for:
- Agent invokes slash command instead of creating artifact
- Artifact not found at expected path
- Context reduction not achieved
- Artifacts not in topic-based directories

## Related Documentation

- [Agent Authoring Guide](agent-authoring-guide.md) - How to create agent behavioral files
- [Hierarchical Agent Architecture](../concepts/hierarchical_agents.md) - Overall system architecture
- [Topic-Based Artifact Organization](../README.md) - Directory structure standards
