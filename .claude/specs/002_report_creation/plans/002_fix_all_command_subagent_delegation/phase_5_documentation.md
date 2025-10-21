# Phase 5: Documentation and Examples

## Metadata
- **Phase**: 5 of 6
- **Parent Plan**: `/home/benjamin/.config/.claude/specs/002_report_creation/plans/002_fix_all_command_subagent_delegation.md`
- **Complexity**: High (8/10)
- **Estimated Time**: 3-4 hours
- **Status**: Not Started
- **Date Created**: 2025-10-20

## Phase Context

This is the **documentation consolidation phase** that captures all implementation knowledge and establishes standards for future development. This phase has high architectural significance because it prevents regression and educates future command/agent authors.

**Parent Plan Overview:**
- **Feature**: System-wide Behavioral Injection Pattern for Subagent Delegation
- **Overall Complexity**: High (78/100)
- **Timeline**: 14-18 hours across 6 phases
- **Root Problem**: Agents invoking slash commands + non-standard artifact organization

**Why This Phase Is Critical:**
1. **Knowledge Transfer**: Captures design decisions and rationale
2. **Regression Prevention**: Documents anti-patterns to avoid
3. **Standards Establishment**: Creates authoritative reference for development
4. **Onboarding**: Enables new contributors to understand patterns quickly
5. **Cross-Referencing**: Creates navigable documentation ecosystem
6. **Traceability**: Documents artifact organization and cross-reference requirements

**Documents to Create/Update:**
1. `.claude/docs/concepts/hierarchical_agents.md` - Add behavioral injection section
2. `.claude/docs/guides/agent-authoring-guide.md` - Complete from Phase 1 skeleton
3. `.claude/docs/guides/command-authoring-guide.md` - Complete from Phase 1 skeleton
4. `.claude/docs/troubleshooting/agent-delegation-issues.md` - New troubleshooting guide
5. `.claude/CHANGELOG.md` - Document all fixes and changes
6. `.claude/docs/examples/behavioral-injection-workflow.md` - New workflow example
7. `.claude/docs/examples/correct-agent-invocation.md` - New invocation examples
8. `.claude/docs/examples/reference-implementations.md` - Reference guide
9. `.claude/docs/guides/README.md` - Update index with new guides

## Objective

Create comprehensive documentation of the behavioral injection pattern, artifact organization standards, cross-reference requirements, anti-patterns, troubleshooting procedures, and examples to establish standards for all future command/agent development.

**Success Criteria:**
- ✅ All 9 documents created or updated
- ✅ Cross-reference network complete (all docs link to each other appropriately)
- ✅ Anti-patterns documented with "why wrong" explanations
- ✅ Correct patterns documented with code examples
- ✅ Troubleshooting guide covers 5+ common issues
- ✅ Examples directory has 3+ complete workflow examples
- ✅ CHANGELOG documents all fixes with file references
- ✅ Documentation quality validated (clarity, completeness, consistency)

## Architecture Overview

### Documentation Ecosystem Structure

```
.claude/docs/
├── concepts/
│   └── hierarchical_agents.md        [UPDATED] - Add behavioral injection section
├── guides/
│   ├── README.md                      [UPDATED] - Index of all guides
│   ├── agent-authoring-guide.md       [COMPLETED] - Agent best practices
│   └── command-authoring-guide.md     [COMPLETED] - Command patterns
├── troubleshooting/
│   └── agent-delegation-issues.md     [NEW] - Common problems and solutions
└── examples/
    ├── behavioral-injection-workflow.md  [NEW] - Complete workflow
    ├── correct-agent-invocation.md       [NEW] - Task tool examples
    └── reference-implementations.md      [NEW] - Links to exemplars

.claude/
└── CHANGELOG.md                       [UPDATED] - Document all fixes
```

### Cross-Reference Network

```
hierarchical_agents.md
    ├──> agent-authoring-guide.md (detailed agent patterns)
    ├──> command-authoring-guide.md (detailed command patterns)
    └──> troubleshooting/ (issue resolution)

agent-authoring-guide.md
    ├──> examples/correct-agent-invocation.md (code samples)
    ├──> examples/reference-implementations.md (working examples)
    ├──> command-authoring-guide.md (how commands invoke agents)
    └──> troubleshooting/ (debugging agent issues)

command-authoring-guide.md
    ├──> agent-authoring-guide.md (what agents can do)
    ├──> examples/behavioral-injection-workflow.md (complete workflow)
    ├──> examples/reference-implementations.md (/plan, /report, /debug)
    └──> troubleshooting/ (debugging command issues)

troubleshooting/agent-delegation-issues.md
    ├──> agent-authoring-guide.md (correct patterns)
    ├──> command-authoring-guide.md (invocation patterns)
    └──> examples/ (working examples to compare against)
```

**Key Design Principle**: Every document should link to at least 2 other documents, creating a navigable web of knowledge.

## Implementation Tasks

### Task 1: Update `.claude/docs/concepts/hierarchical_agents.md`

**Objective**: Add comprehensive section on behavioral injection pattern to existing hierarchical agents documentation

**Current State**: Document exists with hierarchical agent architecture overview
**Target State**: Document includes new section documenting behavioral injection pattern with anti-patterns, correct patterns, and cross-references

**Implementation Approach:**

**Step 1: Add New Section After Existing Content**

Insert new section: `## Behavioral Injection Pattern` after the existing "Context Management" section (estimated line ~300).

**Section Structure:**

```markdown
## Behavioral Injection Pattern

### Overview

The behavioral injection pattern is the correct way for commands to invoke agents while maintaining:
- Full control over artifact paths (topic-based organization)
- Metadata extraction before context bloat (95% reduction)
- No recursion risks
- Consistent with hierarchical architecture principles

### The Anti-Pattern

**WRONG**: Agent behavioral files instructing slash command usage

```
Primary Command (e.g., /orchestrate)
  ↓
Invokes Task tool → plan-architect agent
  ↓
Agent behavioral file: "Use SlashCommand to invoke /plan"
  ↓
Agent uses SlashCommand(/plan)
  ↓
Problems:
  ❌ Loss of control over artifact paths
  ❌ Cannot extract metadata before context bloat
  ❌ Recursion risk (agent → command → agent → ...)
  ❌ Violates hierarchical architecture
  ❌ Cannot enforce topic-based organization
```

**Why This Is Wrong:**
1. **Control Loss**: Command cannot pre-calculate artifact paths
2. **Context Bloat**: Cannot extract metadata before full artifact created
3. **Recursion Risk**: Circular delegation chains possible
4. **Organization Violation**: Cannot enforce topic-based structure
5. **Architectural Inconsistency**: Breaks command → agent → tool hierarchy

### The Correct Pattern

**RIGHT**: Command pre-calculates paths, injects behavioral prompt

```
Primary Command (e.g., /orchestrate)
  ↓
1. Calculate topic-based artifact path BEFORE agent invocation:
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
   TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE" "specs")
   PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")
   # Result: specs/027_feature/plans/027_implementation.md
  ↓
2. Load agent behavioral prompt (strip YAML frontmatter):
   AGENT_PROMPT=$(load_agent_behavioral_prompt "plan-architect")
  ↓
3. Inject complete context into Task invocation:
   Task {
     subagent_type: "general-purpose"
     prompt: "Read and follow behavioral guidelines from:
              ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

              You are acting as a Plan Architect Agent.

              **Feature**: ${FEATURE_DESCRIPTION}
              **Research Reports**: ${REPORT_PATHS}  # Cross-reference requirement
              **Plan Output Path**: ${PLAN_PATH}

              Create implementation plan at exact path provided.
              Include 'Research Reports' metadata section with all report paths.

              Return: {path, phase_count, complexity_score}"
   }
  ↓
Agent creates artifact directly using Write tool at PLAN_PATH
  ↓
Command verifies artifact exists:
  VERIFIED_PATH=$(verify_artifact_or_recover "$PLAN_PATH" "implementation")
  ↓
Command extracts metadata only (95% context reduction):
  PLAN_METADATA=$(extract_plan_metadata "$VERIFIED_PATH")
```

**Why This Is Correct:**
1. ✅ **Full Control**: Command calculates topic-based paths
2. ✅ **Metadata Extraction**: Can extract before context bloat
3. ✅ **No Recursion**: Agent uses Write/Read/Edit tools only
4. ✅ **Topic-Based Organization**: Enforces standard structure
5. ✅ **Cross-Referencing**: Can pass artifact paths for traceability
6. ✅ **Architectural Consistency**: Maintains command → agent → tool hierarchy

### Utilities for Behavioral Injection

Located in `.claude/lib/agent-loading-utils.sh`:

**Key Functions:**
- `load_agent_behavioral_prompt(agent_name)` - Load agent prompt, strip frontmatter
- `get_next_artifact_number(artifact_dir)` - Calculate next NNN
- `verify_artifact_or_recover(expected_path, topic_slug)` - Verify artifact with recovery

Located in `.claude/lib/artifact-creation.sh`:

**Key Functions:**
- `create_topic_artifact(topic_dir, artifact_type, name, subdirectory)` - Create artifact path
- `get_or_create_topic_dir(description, base_dir)` - Get or create topic directory

### Cross-Reference Requirements (Added in Revision 3)

**plan-architect agents must include Research Reports metadata:**

```markdown
## Metadata
- **Date**: 2025-10-20
- **Feature**: User authentication system
- **Research Reports**:
  - /path/to/specs/027_auth/reports/027_security_analysis.md
  - /path/to/specs/027_auth/reports/027_oauth_patterns.md
  - /path/to/specs/027_auth/reports/027_database_design.md
```

**doc-writer agents (summarizers) must include Artifacts Generated:**

```markdown
## Artifacts Generated

### Research Reports
- `/path/to/specs/027_auth/reports/027_security_analysis.md`
- `/path/to/specs/027_auth/reports/027_oauth_patterns.md`
- `/path/to/specs/027_auth/reports/027_database_design.md`

### Implementation Plan
- `/path/to/specs/027_auth/plans/027_implementation.md`

### Debug Reports
- (none)
```

**Why Cross-Referencing Matters:**
- Enables complete audit trail from summary → plan → research
- Supports traceability for compliance/review
- Allows quick navigation between related artifacts
- Documents research that informed implementation decisions

### Reference Implementations

Commands that correctly use behavioral injection pattern:

1. **`/plan` command** (`.claude/commands/plan.md` lines 132-167)
   - Pre-calculates plan path in topic-based structure
   - Invokes research-specialist agents with report paths
   - Invokes plan-architect with all research report paths
   - Verifies artifacts and extracts metadata
   - **Cross-references**: Plan includes research reports in metadata

2. **`/report` command** (`.claude/commands/report.md` lines 92-166)
   - Pre-calculates report path in topic-based structure
   - Invokes spec-updater agent with report path
   - Agent creates report directly using Write tool
   - Command verifies and extracts metadata

3. **`/debug` command** (`.claude/commands/debug.md` lines 186-230)
   - Pre-calculates debug report path in topic-based structure
   - Invokes debug-analyst agents in parallel
   - Each agent creates debug report at provided path
   - Command aggregates metadata only

### Further Reading

- **Agent Authoring**: See [Agent Authoring Guide](../guides/agent-authoring-guide.md)
- **Command Authoring**: See [Command Authoring Guide](../guides/command-authoring-guide.md)
- **Troubleshooting**: See [Agent Delegation Issues](../troubleshooting/agent-delegation-issues.md)
- **Examples**: See [Examples Directory](../examples/)
```

**Step 2: Update Cross-References**

Add links to new documentation in existing sections:
- In "Agent Templates" section, link to agent-authoring-guide.md
- In "Command Integration" section, link to command-authoring-guide.md
- In "Usage Example" section, link to examples/behavioral-injection-workflow.md

**Estimated Lines Added**: ~200 lines (within token budget for single task)

**Testing**:
```bash
# Verify section added
grep -n "## Behavioral Injection Pattern" .claude/docs/concepts/hierarchical_agents.md

# Verify cross-references work
grep -c "agent-authoring-guide\|command-authoring-guide" .claude/docs/concepts/hierarchical_agents.md
# Expected: 3+ references
```

---

### Task 2: Complete `.claude/docs/guides/agent-authoring-guide.md`

**Objective**: Complete the agent authoring guide skeleton created in Phase 1 with comprehensive anti-patterns, correct patterns, cross-reference requirements, and examples

**Current State**: Skeleton created in Phase 1 with basic structure
**Target State**: Complete guide with 7 sections, anti-patterns, correct patterns, cross-reference requirements, and tool usage guidelines

**Implementation Approach:**

**Section 1: Introduction (15 lines)**
```markdown
# Agent Authoring Guide

## Purpose

This guide documents best practices for creating agent behavioral files that follow the behavioral injection pattern and topic-based artifact organization standards.

**Target Audience**: Developers creating new agents or modifying existing agent behavioral files

**Key Principles**:
- Agents create artifacts directly (never invoke slash commands)
- Agents receive pre-calculated topic-based paths from commands
- Agents return metadata only (path + summary)
- Agents use Read/Write/Edit tools (not SlashCommand for artifacts)
```

**Section 2: Agent Behavioral File Structure (30 lines)**
```markdown
## Behavioral File Structure

### YAML Frontmatter (Optional)

```yaml
---
tools: Read, Write, Edit, Bash
description: Creates implementation plans from research reports
behavioral-guidelines: |
  Brief summary of agent role and key responsibilities
---
```

### Behavioral Instructions

After frontmatter, provide detailed behavioral instructions:

**Required Sections**:
1. **Role**: Clear statement of agent purpose
2. **Input Processing**: What the agent receives from command
3. **Task Execution**: Step-by-step execution instructions
4. **Output Format**: Structured output specification
5. **Error Handling**: How to handle failures
6. **Examples**: Sample invocations and outputs

**Formatting Guidelines**:
- Use markdown headers for organization
- Include code blocks for examples
- Use bullet points for task lists
- Emphasize critical instructions with **IMPORTANT** markers
```

**Section 3: What Agents Should Do (40 lines)**
```markdown
## What Agents Should Do

### ✅ Create Artifacts Directly

Agents receive pre-calculated artifact paths and create files directly:

```markdown
## Task Context

**Feature**: User authentication system
**Report Output Path**: /home/user/.config/specs/027_auth/reports/027_security.md

Create research report at exact path provided.
```

Agent implementation:
```python
# Agent uses Write tool
Write(
  file_path="/home/user/.config/specs/027_auth/reports/027_security.md",
  content=report_content
)
```

### ✅ Use Read/Write/Edit Tools

**Approved Tools**:
- `Read` - Read existing files
- `Write` - Create new files
- `Edit` - Modify existing files
- `Grep` - Search for patterns
- `Glob` - Find files
- `Bash` - Run commands
- `WebSearch` - Research online

### ✅ Return Metadata Only

After creating artifact, return structured metadata:

```json
{
  "artifact_path": "/path/to/artifact.md",
  "summary": "50-word summary of artifact content",
  "key_findings": ["finding1", "finding2"],
  "complexity_score": 7.5
}
```

### ✅ Include Cross-References (plan-architect and doc-writer agents)

**plan-architect agents** must include research reports in plan metadata:

```markdown
## Metadata
- **Research Reports**:
  - /path/to/report1.md
  - /path/to/report2.md
```

**doc-writer agents (summarizers)** must list all artifacts in summary:

```markdown
## Artifacts Generated
- Research Reports: [list all]
- Implementation Plan: [path]
- Debug Reports: [list all or none]
```
```

**Section 4: What Agents Should NOT Do (30 lines)**
```markdown
## What Agents Should NOT Do

### ❌ NEVER Invoke Slash Commands for Artifact Creation

**WRONG**:
```markdown
Use SlashCommand tool to invoke /plan with this feature description.
```

**Why Wrong**:
- Command loses control over artifact path
- Cannot enforce topic-based organization
- Cannot extract metadata before context bloat
- Recursion risk (agent → command → agent)

### ❌ NEVER Calculate Artifact Paths

**WRONG**:
```bash
REPORT_PATH="specs/reports/001_topic.md"  # Manual path construction
```

**Why Wrong**:
- Violates topic-based organization (should be specs/027_topic/reports/027_topic.md)
- Inconsistent numbering
- Command should calculate paths, not agent

### ❌ NEVER Return Full Artifact Content

**WRONG**:
```json
{
  "artifact_content": "...5000 lines of plan content..."
}
```

**Why Wrong**:
- Context bloat (no reduction achieved)
- Defeats metadata extraction purpose
- Return path + summary only
```

**Section 5: Anti-Patterns with Explanations (50 lines)**
```markdown
## Anti-Patterns

### Anti-Pattern 1: Agent Invokes Slash Command

**Example (from code-writer.md - FIXED)**:
```markdown
## Type A: Plan-Based Implementation

USE SlashCommand tool to invoke /implement with plan path.

Example:
SlashCommand("/implement specs/plans/001_feature.md")
```

**Why Wrong**:
- Creates recursion risk: /implement → code-writer → /implement → ...
- code-writer agent is invoked BY /implement, should not invoke it back
- Circular delegation chain

**Correct Pattern**:
```markdown
## Task Execution

You receive specific TASKS to execute (not plan paths).

Execute tasks directly using Write/Edit tools:
1. Read files to understand current state
2. Edit files to implement changes
3. Return task completion status
```

### Anti-Pattern 2: Agent Instructed to Invoke /plan

**Example (from plan-architect.md - FIXED)**:
```markdown
ABSOLUTE REQUIREMENT: YOU MUST use SlashCommand to invoke /plan.

SlashCommand("/plan User authentication system")
```

**Why Wrong**:
- plan-architect is invoked BY /plan command (or /orchestrate)
- Command should pre-calculate plan path
- Agent should create plan file directly
- Loss of control over plan path and metadata extraction

**Correct Pattern**:
```markdown
## Task Context

**Plan Output Path**: /path/to/specs/027_auth/plans/027_implementation.md
**Research Reports**:
  - /path/to/specs/027_auth/reports/027_security.md
  - /path/to/specs/027_auth/reports/027_oauth.md

Create implementation plan at exact path provided.

Include "Research Reports" metadata section with all report paths (for traceability).

Use Write tool to create plan file.
Return: {path, phase_count, complexity_score}
```

### Anti-Pattern 3: Agent Calculates Flat Artifact Path

**Example (WRONG)**:
```markdown
Calculate report path:
REPORT_NUM=$(ls specs/reports | wc -l)
REPORT_PATH="specs/reports/${REPORT_NUM}_topic.md"
```

**Why Wrong**:
- Creates flat structure (specs/reports/NNN_topic.md)
- Should use topic-based structure (specs/027_topic/reports/027_topic.md)
- Agent should receive path from command, not calculate it

**Correct Pattern**:
```markdown
## Task Context

**Report Output Path**: /path/to/specs/027_topic/reports/027_topic.md

Create report at exact path provided (do not calculate path yourself).
```
```

**Section 6: Correct Patterns with Examples (40 lines)**
```markdown
## Correct Patterns

### Pattern 1: Direct Artifact Creation

**Agent receives path, creates file directly:**

```markdown
You are acting as a Research Specialist.

**Topic**: OAuth 2.0 security considerations
**Report Output Path**: /path/to/specs/027_auth/reports/027_oauth_security.md

Research the topic and create report at exact path provided.

Use Write tool:
Write(
  file_path=REPORT_OUTPUT_PATH,
  content=report_with_frontmatter
)

Return metadata only:
{
  "path": "/path/to/specs/027_auth/reports/027_oauth_security.md",
  "summary": "Analysis of OAuth 2.0 security...",
  "key_findings": ["PKCE required", "Token rotation important"]
}
```

### Pattern 2: Plan Creation with Cross-References

**plan-architect creates plan with research report references:**

```markdown
You are acting as a Plan Architect.

**Feature**: User authentication with OAuth 2.0
**Research Reports**:
  - /path/to/specs/027_auth/reports/027_oauth_security.md
  - /path/to/specs/027_auth/reports/027_database_design.md
**Plan Output Path**: /path/to/specs/027_auth/plans/027_implementation.md

Create implementation plan at exact path provided.

IMPORTANT: Include research reports in plan metadata for traceability:

## Metadata
- **Date**: 2025-10-20
- **Research Reports**:
  - /path/to/specs/027_auth/reports/027_oauth_security.md
  - /path/to/specs/027_auth/reports/027_database_design.md

Return: {path, phase_count, complexity_score}
```

### Pattern 3: Summary with Complete Cross-References

**doc-writer (summarizer) lists all workflow artifacts:**

```markdown
You are acting as a Documentation Writer (Summarizer).

**Workflow**: User authentication implementation
**Artifacts Created**:
  - Research Reports: [list of paths]
  - Implementation Plan: [path]

Create workflow summary with complete artifact listing:

## Artifacts Generated

### Research Reports
- /path/to/specs/027_auth/reports/027_oauth_security.md
- /path/to/specs/027_auth/reports/027_database_design.md

### Implementation Plan
- /path/to/specs/027_auth/plans/027_implementation.md

This enables complete audit trail from summary to all artifacts.
```
```

**Section 7: Cross-References (20 lines)**
```markdown
## Cross-References

### Related Documentation

- **Hierarchical Agents Architecture**: [Behavioral Injection Pattern](../concepts/hierarchical_agents.md#behavioral-injection-pattern)
- **Command Authoring Guide**: [How commands invoke agents](./command-authoring-guide.md)
- **Troubleshooting**: [Common agent delegation issues](../troubleshooting/agent-delegation-issues.md)
- **Examples**: [Correct agent invocation examples](../examples/correct-agent-invocation.md)

### Reference Implementations

Agents that correctly follow patterns:
- `.claude/agents/research-specialist.md` - Creates reports directly
- `.claude/agents/debug-analyst.md` - Creates debug reports directly
- `.claude/agents/plan-architect.md` - Creates plans directly (FIXED in this project)
- `.claude/agents/doc-writer.md` - Creates summaries with complete cross-references

### Tool References

- Agent Loading Utilities: `.claude/lib/agent-loading-utils.sh`
- Artifact Creation Utilities: `.claude/lib/artifact-creation.sh`
```

**Estimated Total Lines**: ~225 lines (well within budget)

**Testing**:
```bash
# Verify all sections present
for section in "Introduction" "Behavioral File Structure" "What Agents Should Do" \
               "What Agents Should NOT Do" "Anti-Patterns" "Correct Patterns" \
               "Cross-References"; do
  grep -q "$section" .claude/docs/guides/agent-authoring-guide.md || \
    echo "Missing section: $section"
done

# Verify cross-references
grep -c "../concepts/hierarchical_agents\|../troubleshooting\|../examples" \
  .claude/docs/guides/agent-authoring-guide.md
# Expected: 4+ references
```

---

### Task 3: Complete `.claude/docs/guides/command-authoring-guide.md`

**Objective**: Complete the command authoring guide skeleton with comprehensive patterns for invoking agents, topic-based path calculation, and Task tool templates

**Current State**: Skeleton created in Phase 1
**Target State**: Complete 8-section guide with templates and examples

**Implementation Approach:**

**Sections 1-2: Introduction and Topic-Based Paths (detailed)**

```markdown
# Command Authoring Guide

## Introduction

This guide documents best practices for commands that invoke agents using the behavioral injection pattern with topic-based artifact organization.

**Target Audience**: Developers creating new slash commands or modifying existing commands

**Key Principles**:
- Commands pre-calculate topic-based artifact paths before agent invocation
- Commands inject behavioral prompts with complete context
- Commands verify artifacts created at expected paths
- Commands extract metadata only (95% context reduction)

## Topic-Based Artifact Paths

### Standard Directory Structure

From `.claude/docs/README.md` lines 114-138:

```
specs/{NNN_topic}/
├── reports/          Research reports (gitignored)
├── plans/            Implementation plans (gitignored)
├── summaries/        Workflow summaries (gitignored)
├── debug/            Debug reports (COMMITTED)
├── scripts/          Investigation scripts (gitignored)
└── outputs/          Test outputs (gitignored)
```

### Path Calculation Utilities

**ALWAYS use these utilities** (from `.claude/lib/artifact-creation.sh`):

```bash
# Get or create topic directory
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"

TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE_DESCRIPTION" "specs")
# Result: specs/027_user_authentication

# Create artifact path in topic directory
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "security_analysis" "")
# Result: specs/027_user_authentication/reports/027_security_analysis.md

PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")
# Result: specs/027_user_authentication/plans/027_implementation.md

SUMMARY_PATH=$(create_topic_artifact "$TOPIC_DIR" "summaries" "workflow_summary" "")
# Result: specs/027_user_authentication/summaries/027_workflow_summary.md
```

### Why Topic-Based Structure

1. **Centralized Discovery**: All artifacts for one feature in one directory
2. **Consistent Numbering**: Same NNN prefix across all artifact types
3. **Clear Lifecycle**: Gitignore policy varies by artifact type
4. **Cross-Referencing**: Easy relative paths within topic
5. **Scalability**: Supports complex multi-artifact workflows

### NEVER Do This (Anti-Pattern)

```bash
# WRONG: Manual path construction (flat structure)
REPORT_NUM=$(find specs/reports -name "*.md" | wc -l)
REPORT_PATH="specs/reports/${REPORT_NUM}_topic.md"

# Problems:
# - Flat structure (not topic-based)
# - Race condition in number calculation
# - No topic directory for related artifacts
# - Inconsistent numbering across artifact types
```

### Path Calculation Example

Complete example from /orchestrate planning phase:

```bash
# Source utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"

# Get workflow description from user input
WORKFLOW_DESCRIPTION="User authentication system"

# Get or create topic directory
TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESCRIPTION" "specs")
echo "Topic directory: $TOPIC_DIR"
# Output: specs/027_user_authentication

# Calculate paths for all artifact types
RESEARCH_REPORT_1=$(create_topic_artifact "$TOPIC_DIR" "reports" "oauth_security" "")
RESEARCH_REPORT_2=$(create_topic_artifact "$TOPIC_DIR" "reports" "database_design" "")
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")
SUMMARY_PATH=$(create_topic_artifact "$TOPIC_DIR" "summaries" "workflow_summary" "")

# All artifacts share same topic directory and NNN prefix
# - specs/027_user_authentication/reports/027_oauth_security.md
# - specs/027_user_authentication/reports/027_database_design.md
# - specs/027_user_authentication/plans/027_implementation.md
# - specs/027_user_authentication/summaries/027_workflow_summary.md
```
```

**Sections 3-7: Behavioral Injection, Templates, Verification (structured outlines)**

```markdown
## Section 3: Behavioral Injection Approaches

### Option A: Reference Agent File (Simpler - RECOMMENDED)

```markdown
Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are acting as a Research Specialist.

    **Topic**: OAuth 2.0 security
    **Report Output Path**: ${REPORT_PATH}

    Create research report at exact path provided.
    Return: {path, summary, key_findings}
}
```

### Option B: Load and Inject Prompt (Advanced)

Use when you need to modify behavioral instructions dynamically.

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/agent-loading-utils.sh"
AGENT_PROMPT=$(load_agent_behavioral_prompt "research-specialist")

COMPLETE_PROMPT="$AGENT_PROMPT

## Task Context
**Topic**: ${TOPIC}
**Report Output Path**: ${REPORT_PATH}
"

Task {
  subagent_type: "general-purpose"
  prompt: "$COMPLETE_PROMPT"
}
```

### When to Use Each Approach

- **Option A (Reference)**: Default choice for most cases, simpler and clearer
- **Option B (Load+Inject)**: When you need to programmatically modify instructions

## Section 4: Task Tool Invocation Templates

### Template 1: Research Agent Invocation

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC}"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are acting as a Research Specialist.

    **Topic**: ${TOPIC}
    **Report Output Path**: ${REPORT_PATH}

    Create comprehensive research report at exact path provided.

    Include:
    - Executive summary
    - Key findings (3-5 bullets)
    - Technical details
    - Recommendations

    Return JSON metadata:
    {
      "path": "${REPORT_PATH}",
      "summary": "50-word summary",
      "key_findings": ["finding1", "finding2"],
      "recommendations": ["rec1", "rec2"]
    }
}
```

### Template 2: Plan Creation Agent Invocation (with Cross-References)

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan for ${FEATURE}"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are acting as a Plan Architect.

    **Feature**: ${FEATURE_DESCRIPTION}
    **Research Reports**:
$(for report in "${RESEARCH_REPORT_PATHS[@]}"; do echo "      - $report"; done)
    **Plan Output Path**: ${PLAN_PATH}

    Create implementation plan at exact path provided.

    IMPORTANT - Cross-Reference Requirements:
    - Include "Research Reports" metadata section with all report paths
    - This enables traceability from plan to research

    ## Metadata
    - **Date**: $(date +%Y-%m-%d)
    - **Research Reports**:
$(for report in "${RESEARCH_REPORT_PATHS[@]}"; do echo "      - $report"; done)

    Return JSON metadata:
    {
      "path": "${PLAN_PATH}",
      "phase_count": N,
      "complexity_score": X.X,
      "estimated_hours": N
    }
}
```

### Template 3: Summarizer Agent Invocation (with Complete Cross-References)

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create workflow summary"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/doc-writer.md

    You are acting as a Documentation Writer (Summarizer).

    **Workflow**: ${WORKFLOW_DESCRIPTION}
    **Summary Output Path**: ${SUMMARY_PATH}

    **Artifacts to Reference**:
    Research Reports:
$(for report in "${RESEARCH_REPORT_PATHS[@]}"; do echo "      - $report"; done)
    Implementation Plan:
      - ${PLAN_PATH}

    Create workflow summary with complete artifact listing:

    ## Artifacts Generated

    ### Research Reports
$(for report in "${RESEARCH_REPORT_PATHS[@]}"; do echo "    - $report"; done)

    ### Implementation Plan
    - ${PLAN_PATH}

    ### Debug Reports
    - (none)

    This enables complete audit trail of workflow artifacts.

    Return JSON metadata:
    {
      "path": "${SUMMARY_PATH}",
      "workflow_name": "...",
      "artifact_count": N
    }
}
```

## Section 5: Artifact Verification Patterns

### Basic Verification

```bash
# After agent completes, verify artifact exists
if [[ ! -f "$REPORT_PATH" ]]; then
  echo "ERROR: Agent did not create report at expected path: $REPORT_PATH" >&2
  exit 1
fi
```

### Verification with Recovery

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/agent-loading-utils.sh"

# Verify with path mismatch recovery
VERIFIED_PATH=$(verify_artifact_or_recover "$EXPECTED_PATH" "topic_slug")

if [[ $? -ne 0 ]]; then
  echo "ERROR: Artifact not found and recovery failed" >&2
  exit 1
fi

# Use verified path for subsequent operations
echo "Artifact verified at: $VERIFIED_PATH"
```

### Verify Topic-Based Organization

```bash
# Verify artifact is in topic-based directory structure
if [[ ! "$REPORT_PATH" =~ ^specs/[0-9]{3}_[^/]+/reports/ ]]; then
  echo "ERROR: Report path not in topic-based structure: $REPORT_PATH" >&2
  echo "Expected format: specs/NNN_topic/reports/NNN_artifact.md" >&2
  exit 1
fi
```

## Section 6: Metadata Extraction

### Extract Report Metadata

```bash
# Extract metadata, NOT full content (95% context reduction)
REPORT_METADATA=$(extract_report_metadata "$VERIFIED_PATH")

# Parse structured metadata
SUMMARY=$(echo "$REPORT_METADATA" | jq -r '.summary')
KEY_FINDINGS=$(echo "$REPORT_METADATA" | jq -r '.key_findings[]')

# Store metadata only (not full report content)
echo "Report summary: $SUMMARY"
```

### Extract Plan Metadata

```bash
PLAN_METADATA=$(extract_plan_metadata "$PLAN_PATH")

PHASE_COUNT=$(echo "$PLAN_METADATA" | jq -r '.phase_count')
COMPLEXITY=$(echo "$PLAN_METADATA" | jq -r '.complexity')

echo "Plan has $PHASE_COUNT phases, complexity: $COMPLEXITY"
```

## Section 7: Reference Implementations

### /plan Command

Location: `.claude/commands/plan.md` lines 132-167

**Pattern Demonstrated**:
- Research phase: Invokes 2-4 research-specialist agents in parallel
- Each agent receives topic-based report path
- Plan architect receives all research report paths
- Plan includes research reports in metadata (cross-reference)

### /report Command

Location: `.claude/commands/report.md` lines 92-166

**Pattern Demonstrated**:
- Pre-calculates topic-based report path
- Invokes spec-updater agent with report path
- Verifies report created at exact path
- Extracts metadata only

### /debug Command

Location: `.claude/commands/debug.md` lines 186-230

**Pattern Demonstrated**:
- Parallel investigation (2-3 debug-analyst agents)
- Each agent receives topic-based debug report path
- Aggregates metadata from all agents
- Debug reports committed to git (debug/ subdirectory)
```

**Section 8: Artifact Organization (detailed)**

```markdown
## Topic-Based Artifact Organization

### Directory Structure Patterns

#### Simple Artifact (Single File)

```
specs/027_user_authentication/
└── reports/
    └── 027_security_analysis.md
```

Create with:
```bash
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "security_analysis" "")
```

#### Complex Artifact (Multiple Files from One Task)

```
specs/027_user_authentication/
└── reports/
    └── 027_research/              # Subdirectory for multiple reports
        ├── 027_oauth_security.md
        ├── 027_database_design.md
        └── 027_api_patterns.md
```

Create with:
```bash
# First, create subdirectory artifact
RESEARCH_SUBDIR=$(create_topic_artifact "$TOPIC_DIR" "reports" "research" "")
# Result: specs/027_user_authentication/reports/027_research/027_research.md

# Extract subdirectory path
RESEARCH_DIR=$(dirname "$RESEARCH_SUBDIR")/$(basename "$RESEARCH_SUBDIR" .md)
mkdir -p "$RESEARCH_DIR"

# Create individual reports in subdirectory
REPORT_1="${RESEARCH_DIR}/027_oauth_security.md"
REPORT_2="${RESEARCH_DIR}/027_database_design.md"
REPORT_3="${RESEARCH_DIR}/027_api_patterns.md"
```

#### Plan with Expanded Phases

```
specs/027_user_authentication/
└── plans/
    └── 027_implementation/              # Plan subdirectory
        ├── 027_implementation.md        # Level 0 (main plan)
        ├── phase_2_authentication.md    # Level 1 (expanded phase)
        ├── phase_5_testing.md           # Level 1 (expanded phase)
        └── phase_5_testing/             # Level 2 (stages)
            ├── stage_1_unit_tests.md
            └── stage_2_integration_tests.md
```

### Numbering Conventions

**Consistent NNN Prefix**: All artifacts in same topic directory share same NNN prefix

Example topic directory `specs/027_user_authentication/`:
- `027_oauth_security.md` (report)
- `027_database_design.md` (report)
- `027_implementation.md` (plan)
- `027_workflow_summary.md` (summary)

All share `027` prefix, indicating they belong to same topic.

### Gitignore Requirements

Per `.claude/.gitignore`:

```gitignore
# Gitignored (temporary/intermediate artifacts)
specs/*/reports/
specs/*/plans/
specs/*/summaries/
specs/*/scripts/
specs/*/outputs/

# Committed (permanent record)
specs/*/debug/
```

**Why Different Policies**:
- **reports/plans/summaries**: Regenerable, gitignored to reduce repo size
- **debug**: Historical record of issues, committed for audit trail

### Cross-Referencing Within Topics

All artifacts in same topic directory can use relative paths:

From `specs/027_auth/plans/027_implementation.md`:
```markdown
## Research Reports
- [OAuth Security](../reports/027_oauth_security.md)
- [Database Design](../reports/027_database_design.md)
```

From `specs/027_auth/summaries/027_workflow_summary.md`:
```markdown
## Artifacts Generated
- [Security Analysis](../reports/027_oauth_security.md)
- [Implementation Plan](../plans/027_implementation.md)
```

### Complete Workflow Example

```bash
#!/usr/bin/env bash
# Complete workflow: research → plan → summary with topic-based organization

FEATURE_DESCRIPTION="User authentication with OAuth 2.0"

# 1. Get or create topic directory
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE_DESCRIPTION" "specs")
echo "Topic directory: $TOPIC_DIR"

# 2. Calculate research report paths
REPORT_1=$(create_topic_artifact "$TOPIC_DIR" "reports" "oauth_security" "")
REPORT_2=$(create_topic_artifact "$TOPIC_DIR" "reports" "database_design" "")

# 3. Invoke research agents (agents create reports at provided paths)
# ...Task invocations...

# 4. Calculate plan path
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")

# 5. Invoke plan architect with research report paths
# Plan will include "Research Reports" metadata section with $REPORT_1, $REPORT_2

# 6. Calculate summary path
SUMMARY_PATH=$(create_topic_artifact "$TOPIC_DIR" "summaries" "workflow_summary" "")

# 7. Invoke summarizer with all artifact paths
# Summary will include "Artifacts Generated" section with all paths

# Final topic directory structure:
# specs/027_user_authentication/
#   ├── reports/
#   │   ├── 027_oauth_security.md
#   │   └── 027_database_design.md
#   ├── plans/
#   │   └── 027_implementation.md
#   └── summaries/
#       └── 027_workflow_summary.md
```
```

**Estimated Total Lines**: ~350 lines

**Testing**:
```bash
# Verify all sections
grep -c "^## " .claude/docs/guides/command-authoring-guide.md
# Expected: 8 sections

# Verify code examples
grep -c '```bash' .claude/docs/guides/command-authoring-guide.md
# Expected: 10+ code blocks
```

---

### Task 4: Create `.claude/docs/troubleshooting/agent-delegation-issues.md`

**Objective**: Create comprehensive troubleshooting guide covering 5 common issues with symptoms, diagnosis, and solutions

**Implementation Approach:**

```markdown
# Troubleshooting Agent Delegation Issues

This guide covers common issues encountered when commands invoke agents using the behavioral injection pattern.

## Issue 1: Agent Invokes Slash Command Instead of Creating Artifact

### Symptoms
- Agent output contains "Using SlashCommand tool to invoke /plan"
- Unexpected command execution during agent run
- Recursive delegation warnings in logs
- Artifact created but at unexpected path

### Diagnosis

**Step 1: Check agent behavioral file**
```bash
grep -n "SlashCommand\|invoke.*slash\|use.*command" .claude/agents/AGENT_NAME.md
```

**Step 2: Run anti-pattern detector**
```bash
.claude/tests/validate_no_agent_slash_commands.sh
```

Expected output if problem exists:
```
❌ VIOLATION: plan-architect.md contains SlashCommand invocation
64:  ABSOLUTE REQUIREMENT: YOU MUST use SlashCommand to invoke /plan
```

### Solution

**Fix the agent behavioral file**:

```bash
# Remove SlashCommand instructions
# Edit .claude/agents/AGENT_NAME.md

# Remove lines like:
#   "Use SlashCommand to invoke /plan"
#   "YOU MUST invoke /report command"
#   "Call /implement to execute plan"

# Replace with:
#   "Create artifact at ARTIFACT_PATH using Write tool"
#   "Return metadata: {path, summary, key_findings}"
```

**Update command to inject path**:

```bash
# In command file (e.g., orchestrate.md)

# Calculate path before agent invocation
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")

# Inject path into agent prompt
Task {
  prompt: "Create plan at ${PLAN_PATH} using Write tool"
}
```

### Verification
```bash
# Re-run anti-pattern detector
.claude/tests/validate_no_agent_slash_commands.sh
# Expected: ✅ All agent behavioral files clean
```

---

## Issue 2: Artifact Not Found at Expected Path

### Symptoms
- "ERROR: Expected artifact not found: /path/to/artifact.md"
- Agent completed successfully but file missing
- Command fails during verification step

### Diagnosis

**Step 1: Check if artifact created at different path**
```bash
find specs -name "*TOPIC*" -type f
```

**Step 2: Check agent output for actual path**
```bash
# Review agent output in command logs
grep -i "created\|wrote\|path" /tmp/command_execution.log
```

**Step 3: Verify path format**
```bash
echo "$EXPECTED_PATH"
# Should be topic-based: specs/027_topic/reports/027_artifact.md
# NOT flat structure: specs/reports/027_artifact.md
```

### Solution

**Option A: Use verify_artifact_or_recover (has built-in recovery)**

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/agent-loading-utils.sh"

VERIFIED_PATH=$(verify_artifact_or_recover "$EXPECTED_PATH" "topic_slug")

if [[ $? -ne 0 ]]; then
  echo "ERROR: Artifact not found and recovery failed" >&2
  exit 1
fi

echo "Using artifact at: $VERIFIED_PATH"
```

**Option B: Verify agent prompt clearly specified path**

```markdown
# In agent invocation, make path explicit
Task {
  prompt: |
    **IMPORTANT**: Create artifact at EXACT path provided (do not calculate path yourself)

    **Artifact Path**: ${ABSOLUTE_PATH}

    Verify you are writing to: ${ABSOLUTE_PATH}
}
```

**Option C: Add fallback artifact creation**

```bash
if [[ ! -f "$EXPECTED_PATH" ]]; then
  echo "WARNING: Agent did not create artifact, creating fallback" >&2

  # Create minimal artifact as fallback
  cat > "$EXPECTED_PATH" <<EOF
# Fallback Artifact
Agent did not create artifact at expected path.
EOF
fi
```

### Verification
```bash
# Verify artifact exists at expected path
test -f "$EXPECTED_PATH" && echo "✅ Artifact found" || echo "❌ Artifact missing"
```

---

## Issue 3: Context Reduction Not Achieved

### Symptoms
- Command context usage >30% (target: <30%)
- Full artifact content stored in memory
- Performance degradation in multi-agent workflows
- Command slows down after each agent invocation

### Diagnosis

**Step 1: Check if full artifacts loaded**
```bash
grep -n "cat.*REPORT_PATH\|Read.*content\|full_content" command_file.md
```

If found, command is loading full artifact content (anti-pattern).

**Step 2: Verify metadata extraction used**
```bash
grep -n "extract.*metadata\|jq.*summary" command_file.md
```

If NOT found, command may be storing full artifacts.

### Solution

**Extract metadata only (not full content)**:

```bash
# WRONG: Load full content
REPORT_CONTENT=$(cat "$REPORT_PATH")
# Problem: Stores thousands of lines in memory

# CORRECT: Extract metadata only
REPORT_METADATA=$(extract_report_metadata "$REPORT_PATH")
SUMMARY=$(echo "$REPORT_METADATA" | jq -r '.summary')
KEY_FINDINGS=$(echo "$REPORT_METADATA" | jq -r '.key_findings[]')

# Store metadata, not content
echo "Report summary: $SUMMARY"
echo "Key findings: $KEY_FINDINGS"
```

**Metadata extraction utilities**:

```bash
# From .claude/lib/metadata-extraction.sh
extract_report_metadata() {
  local report_path="$1"

  # Extract title (first heading)
  local title=$(grep -m 1 "^# " "$report_path" | sed 's/^# //')

  # Extract summary (first 50 words after frontmatter)
  local summary=$(sed -n '/^---$/,/^---$/!p' "$report_path" | \
                  head -100 | tr '\n' ' ' | \
                  sed 's/^[[:space:]]*//' | \
                  cut -d' ' -f1-50)

  # Return JSON metadata
  jq -n \
    --arg path "$report_path" \
    --arg title "$title" \
    --arg summary "$summary" \
    '{path: $path, title: $title, summary: $summary}'
}
```

### Verification
```bash
# Monitor context usage
# Context reduction achieved when metadata used instead of full content
# Target: 95% reduction (5000 tokens → 250 tokens per artifact)
```

---

## Issue 4: Recursion Risk or Infinite Loops

### Symptoms
- "/implement invoked /implement" warnings
- Agent execution timeout
- Circular delegation detected in logs
- Command never completes

### Diagnosis

**Step 1: Identify recursion pattern**
```bash
# Check if agent invokes the command that invoked it
# Example: code-writer agent invoking /implement

grep -n "SlashCommand.*implement" .claude/agents/code-writer.md
```

**Step 2: Trace delegation chain**
```
/implement command
  ↓
Invokes code-writer agent
  ↓
code-writer behavioral file: "Use SlashCommand to invoke /implement"
  ↓
/implement command (RECURSION!)
```

### Solution

**Remove recursive invocation from agent**:

```bash
# Edit .claude/agents/code-writer.md

# REMOVE these lines:
#   "USE /implement command for plan-based implementation"
#   "YOU MUST use /implement command with this path"
#   "USE SlashCommand tool to invoke /implement"

# ADD clarification:
## CRITICAL: Do NOT Invoke Slash Commands

**NEVER** use SlashCommand tool to invoke:
- /implement (recursion risk - YOU are invoked BY /implement)
- /plan (plan creation is /plan command's responsibility)
- /report (research is research-specialist's responsibility)

**ALWAYS** use Read/Write/Edit tools to modify code directly.
```

**Clarify agent role**:

```markdown
## Role

You are a Code Writer agent responsible for EXECUTING tasks, not parsing plans.

**You Receive**: Specific code change tasks from /implement command
**You Do**: Execute tasks using Read/Write/Edit tools
**You Return**: Task completion status

**You Do NOT**: Invoke /implement command (that's what invoked you!)
```

### Verification
```bash
# Verify no recursion instructions
grep -i "invoke.*implement\|use.*implement\|call.*implement" .claude/agents/code-writer.md
# Expected: No matches (or only in anti-pattern warning)
```

---

## Issue 5: Artifacts Not in Topic-Based Directories

### Symptoms
- Reports created at `specs/reports/001_topic.md` (flat structure)
- Plans created at `specs/plans/001_implementation.md` (flat structure)
- Artifacts scattered instead of centralized in topic directories
- Inconsistent numbering across different artifact types
- Cannot find related artifacts easily

### Diagnosis

**Step 1: Check artifact paths**
```bash
# Find artifacts in flat structure (anti-pattern)
find specs/reports -maxdepth 1 -name "*.md" 2>/dev/null
find specs/plans -maxdepth 1 -name "*.md" 2>/dev/null

# Expected: Empty (no flat structure artifacts)
# If found: Artifacts not following topic-based organization
```

**Step 2: Check if command uses create_topic_artifact()**
```bash
grep -n "create_topic_artifact" .claude/commands/COMMAND_NAME.md
```

If NOT found, command is manually constructing paths (anti-pattern).

**Step 3: Check for manual path construction**
```bash
grep -nE 'specs/(reports|plans|summaries)/.*\.md' .claude/commands/COMMAND_NAME.md
```

If found, command is using flat structure instead of topic-based.

**Step 4: Run validation script**
```bash
.claude/tests/validate_topic_based_artifacts.sh
```

Expected output if problem exists:
```
❌ VIOLATION: Found reports in flat structure specs/reports/
001_security_analysis.md
002_database_design.md
Expected: specs/{NNN_topic}/reports/{NNN}_report.md
```

### Solution

**Always use topic-based path utilities**:

```bash
# WRONG: Manual path construction (flat structure)
REPORT_NUM=$(find specs/reports -name "*.md" | wc -l)
REPORT_PATH="specs/reports/${REPORT_NUM}_topic.md"

# Problems:
# - Flat structure (not topic-based)
# - Race condition in numbering
# - No centralized topic directory
# - Cannot find related artifacts

# CORRECT: Topic-based structure with utility
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"

# Get or create topic directory
TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE_DESCRIPTION" "specs")
# Result: specs/027_user_authentication

# Create artifact in topic directory
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "security_analysis" "")
# Result: specs/027_user_authentication/reports/027_security_analysis.md

# Benefits:
# - Topic-based structure (centralized)
# - Consistent numbering (027 across all artifacts)
# - Easy to find related artifacts (all in specs/027_*)
# - Safe concurrent numbering
```

**Complete workflow example**:

```bash
#!/usr/bin/env bash
# Correct topic-based artifact organization

FEATURE="User authentication system"

# Source utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"

# Get topic directory (creates if doesn't exist)
TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE" "specs")
echo "Topic directory: $TOPIC_DIR"
# Output: specs/027_user_authentication

# Calculate paths for all artifact types
REPORT_1=$(create_topic_artifact "$TOPIC_DIR" "reports" "oauth_security" "")
REPORT_2=$(create_topic_artifact "$TOPIC_DIR" "reports" "database_design" "")
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")
SUMMARY_PATH=$(create_topic_artifact "$TOPIC_DIR" "summaries" "workflow_summary" "")

# Result:
# specs/027_user_authentication/
#   ├── reports/
#   │   ├── 027_oauth_security.md
#   │   └── 027_database_design.md
#   ├── plans/
#   │   └── 027_implementation.md
#   └── summaries/
#       └── 027_workflow_summary.md

# All artifacts share:
# - Same topic directory (027_user_authentication)
# - Same NNN prefix (027)
# - Organized by artifact type (reports/, plans/, summaries/)
```

**Migrate existing flat artifacts**:

```bash
#!/usr/bin/env bash
# Migrate flat structure to topic-based structure

# Find flat artifacts
FLAT_REPORTS=$(find specs/reports -maxdepth 1 -name "*.md" 2>/dev/null)

for old_path in $FLAT_REPORTS; do
  # Extract artifact name
  artifact_name=$(basename "$old_path" .md | sed 's/^[0-9]\{3\}_//')

  # Create topic directory
  TOPIC_DIR=$(get_or_create_topic_dir "$artifact_name" "specs")

  # Calculate new topic-based path
  new_path=$(create_topic_artifact "$TOPIC_DIR" "reports" "$artifact_name" "")

  # Move artifact
  mv "$old_path" "$new_path"

  echo "Migrated: $old_path → $new_path"
done
```

### Verification

```bash
# Verify no flat structure artifacts
.claude/tests/validate_topic_based_artifacts.sh
# Expected: ✅ Topic-based artifact organization validated

# Verify all artifacts in topic directories
find specs -maxdepth 1 -type d -name "[0-9][0-9][0-9]_*"
# Expected: List of topic directories

# Verify artifacts follow pattern
find specs/027_*/reports -name "027_*.md"
# Expected: All reports with matching NNN prefix
```

### References

- **Directory Structure**: `.claude/docs/README.md` lines 114-138
- **Artifact Utilities**: `.claude/lib/artifact-creation.sh`
- **Command Guide**: [Topic-Based Artifact Paths](../guides/command-authoring-guide.md#topic-based-artifact-paths)

---

## Summary

### Quick Diagnosis Checklist

```bash
# 1. Check for slash command anti-pattern
.claude/tests/validate_no_agent_slash_commands.sh

# 2. Check for behavioral injection compliance
.claude/tests/validate_command_behavioral_injection.sh

# 3. Check for topic-based organization
.claude/tests/validate_topic_based_artifacts.sh

# 4. Check agent behavioral files
grep -r "SlashCommand" .claude/agents/

# 5. Check artifact paths
find specs -name "*.md" | head -20
```

### Common Root Causes

1. **Agent invokes slash command** → Remove SlashCommand instructions from agent
2. **Path mismatch** → Use verify_artifact_or_recover() with recovery
3. **Context bloat** → Extract metadata only, not full content
4. **Recursion** → Clarify agent role (execute tasks, not invoke commands)
5. **Flat structure** → Use create_topic_artifact() for topic-based organization

### Getting Help

- **Guides**: See `.claude/docs/guides/` for authoring best practices
- **Examples**: See `.claude/docs/examples/` for working implementations
- **Architecture**: See `.claude/docs/concepts/hierarchical_agents.md` for pattern details
```

**Estimated Lines**: ~550 lines (Issue 5 is most detailed per requirements)

**Testing**:
```bash
# Verify 5 issues documented
grep -c "^## Issue" .claude/docs/troubleshooting/agent-delegation-issues.md
# Expected: 5

# Verify each issue has required sections
for issue in {1..5}; do
  echo "Issue $issue:"
  grep -A 100 "^## Issue $issue" .claude/docs/troubleshooting/agent-delegation-issues.md | \
    grep -c "### Symptoms\|### Diagnosis\|### Solution"
done
# Expected: 3 for each issue
```

---

### Task 5: Update `.claude/CHANGELOG.md`

**Objective**: Document all fixes, additions, and changes from this implementation plan

**Implementation Approach:**

```markdown
# .claude/CHANGELOG.md

## [Unreleased]

### Fixed

- **System-wide Agent Delegation Anti-Pattern** (#002_report_creation): Fixed critical
  anti-pattern where agents were instructed to invoke slash commands instead of creating
  artifacts directly. This violated the behavioral injection pattern and prevented proper
  context management.

  **Affected Commands**:
  - `/orchestrate` (plan-architect agent → /plan command) - FIXED: plan-architect now
    creates plans directly at pre-calculated topic-based paths
  - `/implement` (code-writer agent → /implement recursion) - FIXED: removed all
    /implement invocation instructions from code-writer

  **Impact**:
  - 95% context reduction achieved in /orchestrate planning phase (168.9k → <30k tokens)
  - Zero recursion risk in /implement
  - Full control over artifact paths and metadata extraction
  - Consistent with /plan, /report, /debug reference implementations

  **Files Modified**:
  - `.claude/agents/plan-architect.md` (lines 64-88 removed)
  - `.claude/agents/code-writer.md` (lines 11, 29, 53 removed, Type A section removed)
  - `.claude/commands/orchestrate.md` (planning phase refactored, lines 1086-1150)

- **Artifact Organization Non-Compliance** (#002_report_creation): Enforced topic-based
  artifact organization standard from `.claude/docs/README.md` (lines 114-138) across
  all commands. All artifacts now created in `specs/{NNN_topic}/reports/`,
  `specs/{NNN_topic}/plans/`, `specs/{NNN_topic}/summaries/`, etc. using
  `create_topic_artifact()` utility.

  **Problem**: Artifacts were scattered in flat structures (specs/reports/, specs/plans/)
  instead of centralized topic-based directories.

  **Solution**: All commands now use topic-based path calculation utilities, ensuring:
  - Centralized artifact discovery (all workflow artifacts in one topic directory)
  - Consistent numbering (same NNN prefix across all artifact types)
  - Clear lifecycle (gitignore policy varies by artifact type)
  - Easy cross-referencing (relative paths within topic)

  **Files Modified**:
  - `.claude/commands/orchestrate.md` (research + planning phases)
  - `.claude/commands/plan.md` (verification added)
  - `.claude/commands/report.md` (verification added)
  - `.claude/commands/debug.md` (verification added)

- **Missing Cross-Reference Requirements** (#002_report_creation, Revision 3): Added
  requirements for plans to reference research reports and summaries to reference all
  workflow artifacts, enabling complete audit trails.

  **plan-architect agents**: Must include "Research Reports" metadata section
  **doc-writer agents (summarizers)**: Must include "Artifacts Generated" section

  **Files Modified**:
  - `.claude/agents/plan-architect.md` (cross-reference requirement added)
  - `.claude/agents/doc-writer.md` (cross-reference requirement clarified)
  - `.claude/commands/orchestrate.md` (agent invocations updated with cross-reference context)

### Added

- **Agent Loading Utilities** (#002_report_creation): Created `.claude/lib/agent-loading-utils.sh`
  with utilities for behavioral injection pattern:
  - `load_agent_behavioral_prompt(agent_name)` - Load agent prompt, strip YAML frontmatter
  - `get_next_artifact_number(artifact_dir)` - Calculate next NNN artifact number
  - `verify_artifact_or_recover(expected_path, topic_slug)` - Verify artifact with path recovery

  **Usage**: All commands can now easily implement behavioral injection pattern

- **Comprehensive Documentation** (#002_report_creation):
  - `.claude/docs/guides/agent-authoring-guide.md` - Complete guide for creating agent
    behavioral files (7 sections, anti-patterns, correct patterns, cross-reference requirements)
  - `.claude/docs/guides/command-authoring-guide.md` - Complete guide for commands invoking
    agents (8 sections, topic-based paths, Task tool templates, artifact organization)
  - `.claude/docs/troubleshooting/agent-delegation-issues.md` - Troubleshooting guide with
    5 common issues (symptoms, diagnosis, solutions, including topic-based organization)
  - `.claude/docs/examples/behavioral-injection-workflow.md` - Complete workflow example
  - `.claude/docs/examples/correct-agent-invocation.md` - Task tool invocation examples
  - `.claude/docs/examples/reference-implementations.md` - Guide to /plan, /report, /debug

  **Cross-Reference Network**: All documents link to each other, creating navigable knowledge base

- **Validation Tests** (#002_report_creation):
  - `.claude/tests/validate_no_agent_slash_commands.sh` - Anti-pattern detection for agent files
  - `.claude/tests/validate_command_behavioral_injection.sh` - Pattern compliance for commands
  - `.claude/tests/validate_topic_based_artifacts.sh` - Topic-based organization validation
  - `.claude/tests/test_code_writer_no_recursion.sh` - code-writer recursion test
  - `.claude/tests/test_orchestrate_planning_behavioral_injection.sh` - orchestrate planning test
  - `.claude/tests/test_agent_loading_utils.sh` - utility function tests
  - `.claude/tests/e2e_orchestrate_full_workflow.sh` - E2E orchestrate test (includes cross-reference validation)
  - `.claude/tests/e2e_implement_plan_execution.sh` - E2E implement test
  - `.claude/tests/test_all_fixes_integration.sh` - Master integration test runner

  **Coverage**: 100% agent files, 100% commands with agents, all artifact paths

### Changed

- **`.claude/docs/concepts/hierarchical_agents.md`** (#002_report_creation): Added
  "Behavioral Injection Pattern" section documenting anti-patterns, correct patterns,
  utilities, cross-reference requirements, and reference implementations with examples

- **`.claude/agents/code-writer.md`** (#002_report_creation): Removed /implement invocation
  instructions (lines 11, 29, 53) and "Type A: Plan-Based Implementation" section to
  eliminate recursion risk. Added explicit anti-pattern warning.

- **`.claude/agents/plan-architect.md`** (#002_report_creation): Removed SlashCommand(/plan)
  instructions (lines 64-88). Agent now creates plans directly at provided paths. Added
  cross-reference requirement for research reports in plan metadata (Revision 3).

- **`.claude/commands/orchestrate.md`** (#002_report_creation): Planning phase refactored
  (lines 1086-1150) to use behavioral injection with pre-calculated topic-based plan paths.
  Research phase verified for topic-based compliance. Summary phase updated to pass all
  artifact paths for cross-referencing (Revision 3).

- **`.claude/tests/run_all_tests.sh`** (#002_report_creation): Added new validation tests
  and integration tests to test suite

### Deprecated

- **Agent Slash Command Invocation Pattern** (anti-pattern): Agent behavioral files
  instructing agents to invoke slash commands (e.g., "Use SlashCommand to invoke /plan")
  are now deprecated and flagged by automated validation.

- **Flat Artifact Structure** (anti-pattern): Creating artifacts in flat structures
  (specs/reports/, specs/plans/) instead of topic-based directories is now deprecated
  and flagged by validation.

- **Commands Delegating to Other Commands via Agents** (anti-pattern): Commands should
  invoke agents directly, not delegate to other commands via agents (e.g., orchestrate
  → plan-architect → /plan is wrong).

### Metrics

- **Context Reduction**: 95% reduction in /orchestrate planning phase (168.9k → <30k tokens)
- **Test Coverage**: 12 test files covering all fixes (unit, component, validation, integration, E2E)
- **Documentation**: 9 documents created/updated (guides, troubleshooting, examples, concepts)
- **Anti-Pattern Detection**: 100% agent files validated, 0 violations after fixes
- **Artifact Organization**: 100% topic-based compliance after fixes
- **Cross-Reference Coverage**: Plans reference all research reports, summaries reference all artifacts

### Migration Guide

**For Command Authors**:
1. Use `create_topic_artifact()` for all artifact path calculations
2. Never invoke other slash commands via agents
3. Pre-calculate paths before agent invocation
4. Extract metadata only, not full content
5. See [Command Authoring Guide](.claude/docs/guides/command-authoring-guide.md)

**For Agent Authors**:
1. Never use SlashCommand tool to invoke artifact-creating commands
2. Use Read/Write/Edit tools to create artifacts directly
3. Create artifacts at exact paths provided by command
4. Return metadata only (path + summary)
5. Include cross-references when required (plan-architect, doc-writer)
6. See [Agent Authoring Guide](.claude/docs/guides/agent-authoring-guide.md)

**For Troubleshooting**:
- See [Troubleshooting Guide](.claude/docs/troubleshooting/agent-delegation-issues.md)
- Run validation: `.claude/tests/validate_no_agent_slash_commands.sh`
- Check compliance: `.claude/tests/validate_topic_based_artifacts.sh`
```

**Estimated Lines**: ~200 lines

**Testing**:
```bash
# Verify sections present
grep -c "^### Fixed\|^### Added\|^### Changed\|^### Deprecated\|^### Metrics\|^### Migration Guide" \
  .claude/CHANGELOG.md
# Expected: 6 sections

# Verify file references
grep -c ".claude/\(agents\|commands\|docs\|tests\|lib\)" .claude/CHANGELOG.md
# Expected: 20+ file references
```

---

### Task 6: Create Examples Directory

**Objective**: Create 3 example documents demonstrating correct patterns with outlines and key code

**Files to Create**:
1. `.claude/docs/examples/behavioral-injection-workflow.md`
2. `.claude/docs/examples/correct-agent-invocation.md`
3. `.claude/docs/examples/reference-implementations.md`

**Implementation Approach:**

**Example 1: behavioral-injection-workflow.md (outline format)**

```markdown
# Behavioral Injection Workflow - Complete Example

This document demonstrates a complete workflow using the behavioral injection pattern with topic-based artifact organization.

## Workflow: User Authentication Research and Planning

### Step 1: Calculate Topic Directory

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"

FEATURE_DESCRIPTION="User authentication with OAuth 2.0"
TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE_DESCRIPTION" "specs")

echo "Topic directory: $TOPIC_DIR"
# Output: specs/027_user_authentication
```

### Step 2: Research Phase (Parallel Research Agents)

**Calculate research report paths**:
```bash
REPORT_OAUTH=$(create_topic_artifact "$TOPIC_DIR" "reports" "oauth_security" "")
REPORT_DB=$(create_topic_artifact "$TOPIC_DIR" "reports" "database_design" "")

echo "Research reports:"
echo "  - $REPORT_OAUTH"
echo "  - $REPORT_DB"
```

**Invoke research-specialist agents**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research OAuth 2.0 security"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Topic**: OAuth 2.0 security considerations
    **Report Output Path**: ${REPORT_OAUTH}

    Create comprehensive research report.
    Return: {path, summary, key_findings}
}

Task {
  subagent_type: "general-purpose"
  description: "Research database design"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Topic**: Database design for user authentication
    **Report Output Path**: ${REPORT_DB}

    Create comprehensive research report.
    Return: {path, summary, key_findings}
}
```

**Extract metadata from both reports** (95% context reduction):
```bash
OAUTH_METADATA=$(extract_report_metadata "$REPORT_OAUTH")
DB_METADATA=$(extract_report_metadata "$REPORT_DB")

OAUTH_SUMMARY=$(echo "$OAUTH_METADATA" | jq -r '.summary')
DB_SUMMARY=$(echo "$DB_METADATA" | jq -r '.summary')
```

### Step 3: Planning Phase (Plan Architect Agent)

**Calculate plan path**:
```bash
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")

echo "Plan path: $PLAN_PATH"
# Output: specs/027_user_authentication/plans/027_implementation.md
```

**Invoke plan-architect agent with research report paths** (cross-reference):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    **Feature**: User authentication with OAuth 2.0
    **Research Reports**:
      - ${REPORT_OAUTH}
      - ${REPORT_DB}
    **Plan Output Path**: ${PLAN_PATH}

    Create implementation plan at exact path provided.

    IMPORTANT - Include cross-references in plan metadata:
    ## Metadata
    - **Research Reports**:
      - ${REPORT_OAUTH}
      - ${REPORT_DB}

    Return: {path, phase_count, complexity_score}
}
```

**Extract plan metadata**:
```bash
PLAN_METADATA=$(extract_plan_metadata "$PLAN_PATH")
PHASE_COUNT=$(echo "$PLAN_METADATA" | jq -r '.phase_count')
COMPLEXITY=$(echo "$PLAN_METADATA" | jq -r '.complexity')

echo "Plan has $PHASE_COUNT phases, complexity: $COMPLEXITY"
```

### Step 4: Workflow Summary (Summarizer Agent)

**Calculate summary path**:
```bash
SUMMARY_PATH=$(create_topic_artifact "$TOPIC_DIR" "summaries" "workflow_summary" "")

echo "Summary path: $SUMMARY_PATH"
# Output: specs/027_user_authentication/summaries/027_workflow_summary.md
```

**Invoke doc-writer agent with all artifact paths** (complete cross-reference):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create workflow summary"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/doc-writer.md

    **Workflow**: User authentication implementation
    **Summary Output Path**: ${SUMMARY_PATH}

    **Artifacts to Reference**:
    Research Reports:
      - ${REPORT_OAUTH}
      - ${REPORT_DB}
    Implementation Plan:
      - ${PLAN_PATH}

    Create workflow summary with complete artifact cross-references:

    ## Artifacts Generated

    ### Research Reports
    - ${REPORT_OAUTH}
    - ${REPORT_DB}

    ### Implementation Plan
    - ${PLAN_PATH}

    Return: {path, artifact_count}
}
```

### Final Directory Structure

```
specs/027_user_authentication/
├── reports/
│   ├── 027_oauth_security.md          (created by research-specialist)
│   └── 027_database_design.md         (created by research-specialist)
├── plans/
│   └── 027_implementation.md          (created by plan-architect, references reports)
└── summaries/
    └── 027_workflow_summary.md        (created by doc-writer, references all artifacts)
```

### Key Benefits Demonstrated

1. **Topic-Based Organization**: All artifacts centralized in one topic directory
2. **Consistent Numbering**: All share 027 prefix
3. **Behavioral Injection**: All agents received pre-calculated paths
4. **Metadata Extraction**: Only metadata stored in memory (95% reduction)
5. **No Recursion**: No slash command invocations from agents
6. **Cross-References**: Complete audit trail (summary → plan → reports)
7. **Parallel Execution**: Research agents ran concurrently

### Context Usage Metrics

- **Without behavioral injection**: ~150k tokens (full artifacts in memory)
- **With behavioral injection**: <30k tokens (metadata only)
- **Context reduction**: 95%

## See Also

- [Agent Authoring Guide](../guides/agent-authoring-guide.md)
- [Command Authoring Guide](../guides/command-authoring-guide.md)
- [Reference Implementations](./reference-implementations.md)
```

**Example 2: correct-agent-invocation.md (focused on Task tool)**

```markdown
# Correct Agent Invocation Examples

Task tool invocation patterns for different agent types.

## Pattern 1: Research Specialist Invocation

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research OAuth 2.0 security"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are acting as a Research Specialist.

    **Topic**: OAuth 2.0 security considerations
    **Report Output Path**: /path/to/specs/027_auth/reports/027_oauth_security.md
    **Scope**: Focus on PKCE, token rotation, and refresh token security

    Create comprehensive research report at exact path provided.

    Include:
    - Executive summary
    - Key findings (3-5 bullets)
    - Security recommendations
    - Implementation patterns

    Return JSON metadata:
    {
      "path": "/path/to/specs/027_auth/reports/027_oauth_security.md",
      "summary": "50-word summary",
      "key_findings": ["finding1", "finding2"],
      "recommendations": ["rec1", "rec2"]
    }
}
```

## Pattern 2: Plan Architect Invocation (with Cross-References)

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan for user auth"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are acting as a Plan Architect.

    **Feature**: User authentication with OAuth 2.0
    **Complexity**: High (Score: 8/10)
    **Research Reports**:
      - /path/to/specs/027_auth/reports/027_oauth_security.md
      - /path/to/specs/027_auth/reports/027_database_design.md
      - /path/to/specs/027_auth/reports/027_api_patterns.md
    **Plan Output Path**: /path/to/specs/027_auth/plans/027_implementation.md

    Create implementation plan at exact path provided.

    IMPORTANT - Cross-Reference Requirements:
    Include "Research Reports" metadata section with all report paths:

    ## Metadata
    - **Date**: 2025-10-20
    - **Research Reports**:
      - /path/to/specs/027_auth/reports/027_oauth_security.md
      - /path/to/specs/027_auth/reports/027_database_design.md
      - /path/to/specs/027_auth/reports/027_api_patterns.md

    This enables traceability from plan to research.

    Return JSON metadata:
    {
      "path": "/path/to/specs/027_auth/plans/027_implementation.md",
      "phase_count": 6,
      "complexity_score": 8.0,
      "estimated_hours": 18
    }
}
```

## Pattern 3: Debug Analyst Invocation (Parallel)

```markdown
# Invoke 3 debug analysts in parallel (different hypotheses)

Task {
  subagent_type: "general-purpose"
  description: "Investigate authentication failure root cause (hypothesis 1)"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

    **Issue**: Authentication failing with 401 after recent OAuth update
    **Hypothesis**: Token validation logic changed
    **Debug Report Path**: /path/to/specs/027_auth/debug/027_token_validation.md

    Investigate hypothesis and create debug report.
    Return: {path, hypothesis_validated, root_cause, proposed_fix}
}

Task {
  subagent_type: "general-purpose"
  description: "Investigate authentication failure root cause (hypothesis 2)"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

    **Issue**: Authentication failing with 401 after recent OAuth update
    **Hypothesis**: Database schema migration incomplete
    **Debug Report Path**: /path/to/specs/027_auth/debug/027_database_schema.md

    Investigate hypothesis and create debug report.
    Return: {path, hypothesis_validated, root_cause, proposed_fix}
}

Task {
  subagent_type: "general-purpose"
  description: "Investigate authentication failure root cause (hypothesis 3)"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

    **Issue**: Authentication failing with 401 after recent OAuth update
    **Hypothesis**: Environment configuration missing
    **Debug Report Path**: /path/to/specs/027_auth/debug/027_environment_config.md

    Investigate hypothesis and create debug report.
    Return: {path, hypothesis_validated, root_cause, proposed_fix}
}

# All 3 agents run in parallel, command aggregates findings
```

## Pattern 4: Summarizer Invocation (Complete Cross-References)

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create workflow summary with artifact audit trail"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/doc-writer.md

    You are acting as a Documentation Writer (Summarizer).

    **Workflow**: User authentication system implementation
    **Summary Output Path**: /path/to/specs/027_auth/summaries/027_workflow_summary.md

    **Artifacts Generated During Workflow**:
    Research Reports:
      - /path/to/specs/027_auth/reports/027_oauth_security.md
      - /path/to/specs/027_auth/reports/027_database_design.md
      - /path/to/specs/027_auth/reports/027_api_patterns.md
    Implementation Plan:
      - /path/to/specs/027_auth/plans/027_implementation.md
    Debug Reports:
      - /path/to/specs/027_auth/debug/027_token_validation.md

    Create workflow summary at exact path provided.

    IMPORTANT - Include complete artifact listing for audit trail:

    ## Artifacts Generated

    ### Research Reports
    - /path/to/specs/027_auth/reports/027_oauth_security.md
    - /path/to/specs/027_auth/reports/027_database_design.md
    - /path/to/specs/027_auth/reports/027_api_patterns.md

    ### Implementation Plan
    - /path/to/specs/027_auth/plans/027_implementation.md

    ### Debug Reports
    - /path/to/specs/027_auth/debug/027_token_validation.md

    Return JSON metadata:
    {
      "path": "/path/to/specs/027_auth/summaries/027_workflow_summary.md",
      "workflow_name": "User authentication system",
      "artifact_count": 5
    }
}
```

## Common Anti-Patterns to Avoid

### ❌ WRONG: Agent calculates path

```markdown
Task {
  prompt: |
    Calculate report path:
    REPORT_NUM=$(ls specs/reports | wc -l)
    REPORT_PATH="specs/reports/${REPORT_NUM}_topic.md"
}
```

### ✅ CORRECT: Command calculates path

```bash
# Command calculates before invocation
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "topic" "")

Task {
  prompt: |
    **Report Output Path**: ${REPORT_PATH}
    Create report at exact path provided.
}
```

### ❌ WRONG: Agent invokes slash command

```markdown
Task {
  prompt: |
    Use SlashCommand tool to invoke /plan with feature description.
}
```

### ✅ CORRECT: Agent creates artifact directly

```markdown
Task {
  prompt: |
    **Plan Output Path**: ${PLAN_PATH}
    Create plan at exact path using Write tool.
}
```

## See Also

- [Agent Authoring Guide](../guides/agent-authoring-guide.md)
- [Command Authoring Guide](../guides/command-authoring-guide.md)
- [Behavioral Injection Workflow](./behavioral-injection-workflow.md)
```

**Example 3: reference-implementations.md (guide format)**

```markdown
# Reference Implementations

This document identifies commands that correctly implement the behavioral injection pattern with topic-based artifact organization.

## Overview

These commands serve as reference implementations for correct agent invocation patterns. Use them as templates when creating new commands or modifying existing ones.

## Reference Commands

### /plan Command

**File**: `.claude/commands/plan.md`

**Key Sections**:
- Lines 132-167: Research specialist invocation
- Lines 168-215: Plan architect invocation
- Lines 216-245: Artifact verification and metadata extraction

**Pattern Demonstrated**:
- Topic-based path calculation using `create_topic_artifact()`
- Parallel research agent invocation (2-4 agents)
- Pre-calculated paths for all artifacts
- Metadata-only extraction (95% context reduction)
- Cross-references: Plan includes research reports in metadata

**Key Code**:
```bash
# Calculate topic directory
TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE_DESCRIPTION" "specs")

# Calculate research report paths
REPORT_1=$(create_topic_artifact "$TOPIC_DIR" "reports" "architecture" "")
REPORT_2=$(create_topic_artifact "$TOPIC_DIR" "reports" "patterns" "")

# Invoke research agents with pre-calculated paths
# (see plan.md lines 132-167)

# Calculate plan path
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")

# Invoke plan-architect with all research report paths
# Plan includes "Research Reports" metadata section
```

### /report Command

**File**: `.claude/commands/report.md`

**Key Sections**:
- Lines 92-135: Topic directory calculation
- Lines 136-166: Spec-updater invocation
- Lines 167-195: Artifact verification

**Pattern Demonstrated**:
- Topic-based report path calculation
- Single agent invocation (spec-updater)
- Agent creates report directly using Write tool
- Verification with `verify_artifact_or_recover()`

**Key Code**:
```bash
# Calculate topic directory from report topic
TOPIC_DIR=$(get_or_create_topic_dir "$REPORT_TOPIC" "specs")

# Calculate report path
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "$topic_slug" "")

# Invoke spec-updater agent
Task {
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/spec-updater.md

    **Report Output Path**: ${REPORT_PATH}
    Create report at exact path provided.
}

# Verify and extract metadata
VERIFIED_PATH=$(verify_artifact_or_recover "$REPORT_PATH" "$topic_slug")
REPORT_METADATA=$(extract_report_metadata "$VERIFIED_PATH")
```

### /debug Command

**File**: `.claude/commands/debug.md`

**Key Sections**:
- Lines 158-185: Topic directory calculation
- Lines 186-230: Parallel debug-analyst invocation
- Lines 231-265: Metadata aggregation

**Pattern Demonstrated**:
- Parallel agent invocation (2-3 debug-analyst agents)
- Each agent investigates different hypothesis
- Topic-based debug report paths (in debug/ subdirectory)
- Debug reports committed to git (not gitignored)
- Metadata-only aggregation

**Key Code**:
```bash
# Calculate topic directory
TOPIC_DIR=$(get_or_create_topic_dir "$ISSUE_DESCRIPTION" "specs")

# Calculate debug report paths (one per hypothesis)
DEBUG_1=$(create_topic_artifact "$TOPIC_DIR" "debug" "hypothesis_1" "")
DEBUG_2=$(create_topic_artifact "$TOPIC_DIR" "debug" "hypothesis_2" "")
DEBUG_3=$(create_topic_artifact "$TOPIC_DIR" "debug" "hypothesis_3" "")

# Invoke debug-analyst agents in parallel
# Each agent creates debug report at provided path

# Aggregate metadata (not full reports)
for debug_report in "$DEBUG_1" "$DEBUG_2" "$DEBUG_3"; do
  METADATA=$(extract_report_metadata "$debug_report")
  # Aggregate findings
done
```

## Common Patterns Across All References

### 1. Topic Directory Calculation

```bash
# ALWAYS use utility (never manual construction)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
TOPIC_DIR=$(get_or_create_topic_dir "$DESCRIPTION" "specs")
```

### 2. Artifact Path Calculation

```bash
# ALWAYS use create_topic_artifact()
ARTIFACT_PATH=$(create_topic_artifact "$TOPIC_DIR" "artifact_type" "name" "")

# Result format: specs/027_topic/artifact_type/027_name.md
```

### 3. Agent Invocation

```markdown
Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/AGENT_NAME.md

    **Artifact Output Path**: ${ARTIFACT_PATH}
    Create artifact at exact path provided.
}
```

### 4. Artifact Verification

```bash
# Use verification with recovery
source "${CLAUDE_PROJECT_DIR}/.claude/lib/agent-loading-utils.sh"
VERIFIED_PATH=$(verify_artifact_or_recover "$EXPECTED_PATH" "topic_slug")
```

### 5. Metadata Extraction

```bash
# Extract metadata only (not full content)
METADATA=$(extract_report_metadata "$VERIFIED_PATH")
SUMMARY=$(echo "$METADATA" | jq -r '.summary')
```

## Anti-Patterns (Do NOT Use These Commands as Reference)

### ❌ OLD /orchestrate (before fix)

**Problem**: plan-architect agent invoked /plan command
**File**: Older version of `.claude/commands/orchestrate.md`
**Why Wrong**: Loss of control over plan path, no metadata extraction

### ❌ OLD /implement (before fix)

**Problem**: code-writer agent invoked /implement (recursion risk)
**File**: Older version of `.claude/agents/code-writer.md`
**Why Wrong**: Circular delegation chain

## How to Use This Guide

1. **Starting new command**: Use /plan or /report as template
2. **Multiple agents in parallel**: Use /plan (research phase) or /debug
3. **Single agent**: Use /report
4. **Complex workflows**: Use /plan (research → planning phases)

## See Also

- [Agent Authoring Guide](../guides/agent-authoring-guide.md)
- [Command Authoring Guide](../guides/command-authoring-guide.md)
- [Behavioral Injection Workflow](./behavioral-injection-workflow.md)
- [Correct Agent Invocation](./correct-agent-invocation.md)
```

**Estimated Total**: ~350 lines across 3 files

**Testing**:
```bash
# Verify all 3 examples created
ls -1 .claude/docs/examples/*.md | wc -l
# Expected: 3

# Verify cross-references in examples
grep -r "../guides\|../troubleshooting\|../concepts" .claude/docs/examples/ | wc -l
# Expected: 10+ cross-references
```

---

## Cross-Reference Network

### Linking Strategy

After completing all 6 tasks, verify cross-reference network:

```bash
#!/usr/bin/env bash
# Verify cross-reference network

echo "Cross-Reference Network Validation"
echo "==================================="

# hierarchical_agents.md should link to guides and troubleshooting
HIERARCHICAL_LINKS=$(grep -c "../guides\|../troubleshooting\|../examples" \
  .claude/docs/concepts/hierarchical_agents.md)
echo "hierarchical_agents.md: $HIERARCHICAL_LINKS links (expected: 4+)"

# agent-authoring-guide.md should link to examples and troubleshooting
AGENT_GUIDE_LINKS=$(grep -c "../examples\|../troubleshooting\|../concepts" \
  .claude/docs/guides/agent-authoring-guide.md)
echo "agent-authoring-guide.md: $AGENT_GUIDE_LINKS links (expected: 4+)"

# command-authoring-guide.md should link to examples and troubleshooting
COMMAND_GUIDE_LINKS=$(grep -c "../examples\|../troubleshooting\|../guides" \
  .claude/docs/guides/command-authoring-guide.md)
echo "command-authoring-guide.md: $COMMAND_GUIDE_LINKS links (expected: 4+)"

# troubleshooting should link to guides and examples
TROUBLESHOOTING_LINKS=$(grep -c "../guides\|../examples\|../concepts" \
  .claude/docs/troubleshooting/agent-delegation-issues.md)
echo "agent-delegation-issues.md: $TROUBLESHOOTING_LINKS links (expected: 3+)"

# Examples should link to guides
EXAMPLE_LINKS=$(grep -r "../guides" .claude/docs/examples/ | wc -l)
echo "examples/ directory: $EXAMPLE_LINKS links to guides (expected: 6+)"

echo ""
echo "All documents should link to at least 2 other documents."
echo "Cross-reference network enables navigation between related docs."
```

### Visual Network

```
                  hierarchical_agents.md
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
agent-authoring-guide  command-authoring-guide  troubleshooting/
        │                  │                  │
        │                  │                  │
        └────────┬─────────┴─────────┬────────┘
                 │                   │
                 ▼                   ▼
          examples/         CHANGELOG.md
    (behavioral-injection,
     correct-invocation,
     reference-impls)
```

**Every Document Should**:
- Link to at least 2 related documents
- Be linked from at least 2 documents
- Provide clear navigation paths

---

## Testing Strategy

### Documentation Quality Checks

```bash
#!/usr/bin/env bash
# Documentation quality validation

echo "Documentation Quality Checks"
echo "============================"

# Check 1: All documents exist
EXPECTED_DOCS=(
  ".claude/docs/concepts/hierarchical_agents.md"
  ".claude/docs/guides/agent-authoring-guide.md"
  ".claude/docs/guides/command-authoring-guide.md"
  ".claude/docs/troubleshooting/agent-delegation-issues.md"
  ".claude/CHANGELOG.md"
  ".claude/docs/examples/behavioral-injection-workflow.md"
  ".claude/docs/examples/correct-agent-invocation.md"
  ".claude/docs/examples/reference-implementations.md"
)

for doc in "${EXPECTED_DOCS[@]}"; do
  if [[ -f "$doc" ]]; then
    echo "✅ $doc"
  else
    echo "❌ $doc (MISSING)"
  fi
done

# Check 2: Minimum line counts (structure validation)
echo ""
echo "Document Size Validation"
echo "------------------------"

MIN_LINES_HIERARCHICAL=150
ACTUAL_LINES=$(wc -l < .claude/docs/concepts/hierarchical_agents.md)
if [ "$ACTUAL_LINES" -ge "$MIN_LINES_HIERARCHICAL" ]; then
  echo "✅ hierarchical_agents.md: $ACTUAL_LINES lines (min: $MIN_LINES_HIERARCHICAL)"
else
  echo "❌ hierarchical_agents.md: $ACTUAL_LINES lines (too short, min: $MIN_LINES_HIERARCHICAL)"
fi

MIN_LINES_AGENT_GUIDE=200
ACTUAL_LINES=$(wc -l < .claude/docs/guides/agent-authoring-guide.md)
if [ "$ACTUAL_LINES" -ge "$MIN_LINES_AGENT_GUIDE" ]; then
  echo "✅ agent-authoring-guide.md: $ACTUAL_LINES lines (min: $MIN_LINES_AGENT_GUIDE)"
else
  echo "❌ agent-authoring-guide.md: $ACTUAL_LINES lines (too short, min: $MIN_LINES_AGENT_GUIDE)"
fi

MIN_LINES_COMMAND_GUIDE=300
ACTUAL_LINES=$(wc -l < .claude/docs/guides/command-authoring-guide.md)
if [ "$ACTUAL_LINES" -ge "$MIN_LINES_COMMAND_GUIDE" ]; then
  echo "✅ command-authoring-guide.md: $ACTUAL_LINES lines (min: $MIN_LINES_COMMAND_GUIDE)"
else
  echo "❌ command-authoring-guide.md: $ACTUAL_LINES lines (too short, min: $MIN_LINES_COMMAND_GUIDE)"
fi

MIN_LINES_TROUBLESHOOTING=400
ACTUAL_LINES=$(wc -l < .claude/docs/troubleshooting/agent-delegation-issues.md)
if [ "$ACTUAL_LINES" -ge "$MIN_LINES_TROUBLESHOOTING" ]; then
  echo "✅ agent-delegation-issues.md: $ACTUAL_LINES lines (min: $MIN_LINES_TROUBLESHOOTING)"
else
  echo "❌ agent-delegation-issues.md: $ACTUAL_LINES lines (too short, min: $MIN_LINES_TROUBLESHOOTING)"
fi

# Check 3: Code block counts (verify examples present)
echo ""
echo "Code Example Validation"
echo "-----------------------"

for doc in "${EXPECTED_DOCS[@]}"; do
  CODE_BLOCKS=$(grep -c '```' "$doc" 2>/dev/null || echo 0)
  # Divide by 2 (opening and closing ```)
  CODE_BLOCKS=$((CODE_BLOCKS / 2))

  if [ "$CODE_BLOCKS" -ge 3 ]; then
    echo "✅ $doc: $CODE_BLOCKS code blocks"
  else
    echo "⚠️  $doc: $CODE_BLOCKS code blocks (expected: 3+)"
  fi
done

# Check 4: Cross-reference validation
echo ""
echo "Cross-Reference Validation"
echo "--------------------------"

TOTAL_CROSS_REFS=$(grep -r "../" .claude/docs/guides/ .claude/docs/examples/ \
  .claude/docs/troubleshooting/ .claude/docs/concepts/hierarchical_agents.md 2>/dev/null | \
  grep -c "\.md")

if [ "$TOTAL_CROSS_REFS" -ge 20 ]; then
  echo "✅ Total cross-references: $TOTAL_CROSS_REFS (expected: 20+)"
else
  echo "❌ Total cross-references: $TOTAL_CROSS_REFS (too few, expected: 20+)"
fi

echo ""
echo "============================"
echo "Documentation Quality Check Complete"
```

### Cross-Reference Validation

```bash
#!/usr/bin/env bash
# Verify all cross-reference links are valid

echo "Cross-Reference Link Validation"
echo "================================"

ALL_DOCS=$(find .claude/docs -name "*.md" 2>/dev/null)

BROKEN_LINKS=0

for doc in $ALL_DOCS; do
  # Extract all relative links
  LINKS=$(grep -oE '\[.*\]\(\.\./[^)]+\.md\)' "$doc" | \
          grep -oE '\(\.\./[^)]+\.md\)' | \
          tr -d '()' || true)

  for link in $LINKS; do
    # Convert relative link to absolute path
    doc_dir=$(dirname "$doc")
    target_path=$(cd "$doc_dir" && realpath "$link" 2>/dev/null || echo "INVALID")

    if [[ "$target_path" == "INVALID" ]] || [[ ! -f "$target_path" ]]; then
      echo "❌ BROKEN: $doc -> $link"
      BROKEN_LINKS=$((BROKEN_LINKS + 1))
    fi
  done
done

if [ $BROKEN_LINKS -eq 0 ]; then
  echo "✅ All cross-reference links valid"
  exit 0
else
  echo "❌ Found $BROKEN_LINKS broken cross-reference links"
  exit 1
fi
```

### Consistency Verification

```bash
#!/usr/bin/env bash
# Verify consistent terminology across all documentation

echo "Terminology Consistency Check"
echo "=============================="

# Check 1: Consistent "behavioral injection" spelling
BEHAVIORAL_INJECTION=$(grep -r "behavioral injection" .claude/docs/ 2>/dev/null | wc -l)
BEHAVIOURAL_INJECTION=$(grep -r "behavioural injection" .claude/docs/ 2>/dev/null | wc -l)

if [ "$BEHAVIOURAL_INJECTION" -eq 0 ]; then
  echo "✅ Consistent spelling: 'behavioral injection' ($BEHAVIORAL_INJECTION occurrences)"
else
  echo "❌ Inconsistent spelling: 'behavioural injection' found ($BEHAVIOURAL_INJECTION occurrences)"
fi

# Check 2: Consistent "topic-based" vs "topic based"
TOPIC_BASED=$(grep -r "topic-based" .claude/docs/ 2>/dev/null | wc -l)
TOPIC_BASED_SPACE=$(grep -r "topic based" .claude/docs/ 2>/dev/null | wc -l)

if [ "$TOPIC_BASED_SPACE" -eq 0 ]; then
  echo "✅ Consistent spelling: 'topic-based' ($TOPIC_BASED occurrences)"
else
  echo "⚠️  Found 'topic based' (space) $TOPIC_BASED_SPACE times (should be 'topic-based')"
fi

# Check 3: Consistent agent naming
PLAN_ARCHITECT=$(grep -r "plan-architect" .claude/docs/ 2>/dev/null | wc -l)
PLAN_ARCHITECT_WRONG=$(grep -r "plan_architect\|planarchitect" .claude/docs/ 2>/dev/null | wc -l)

if [ "$PLAN_ARCHITECT_WRONG" -eq 0 ]; then
  echo "✅ Consistent agent naming: 'plan-architect' ($PLAN_ARCHITECT occurrences)"
else
  echo "❌ Inconsistent agent naming found ($PLAN_ARCHITECT_WRONG occurrences)"
fi

echo ""
echo "=============================="
echo "Terminology Check Complete"
```

---

## Success Criteria & Timeline

### Acceptance Criteria

**Documentation Completeness:**
- [ ] All 9 documents created or updated
- [ ] All documents have ≥3 code examples
- [ ] All documents cross-reference ≥2 other documents
- [ ] Total ≥20 cross-references across documentation ecosystem

**Content Quality:**
- [ ] Behavioral injection pattern documented with anti-patterns
- [ ] Topic-based artifact organization documented
- [ ] Cross-reference requirements documented (plan-architect, doc-writer)
- [ ] 5+ troubleshooting issues with symptoms/diagnosis/solutions
- [ ] 3+ complete workflow examples

**Standards Compliance:**
- [ ] All code examples use `create_topic_artifact()` utility
- [ ] All examples demonstrate topic-based structure
- [ ] No manual path construction in examples
- [ ] All agent invocations use Task tool correctly

**Validation:**
- [ ] Documentation quality checks pass (all documents exist)
- [ ] Cross-reference validation passes (no broken links)
- [ ] Terminology consistency checks pass
- [ ] All code blocks properly formatted with syntax highlighting

### Timeline Breakdown

**Task 1: Update hierarchical_agents.md** (45 minutes)
- Add behavioral injection section (~200 lines)
- Update cross-references
- Verify section integration

**Task 2: Complete agent-authoring-guide.md** (60 minutes)
- Complete all 7 sections
- Add anti-patterns with explanations
- Add correct patterns with examples
- Add cross-reference requirements

**Task 3: Complete command-authoring-guide.md** (75 minutes)
- Complete all 8 sections (topic-based paths detailed)
- Add Task tool templates
- Add artifact organization section
- Add complete workflow examples

**Task 4: Create troubleshooting guide** (60 minutes)
- Document 5 common issues
- Add symptoms, diagnosis, solutions for each
- Issue 5 (topic-based directories) most detailed
- Add code examples for fixes

**Task 5: Update CHANGELOG** (30 minutes)
- Document all fixes in Fixed section
- Document all additions in Added section
- Document all changes in Changed section
- Add metrics and migration guide

**Task 6: Create examples directory** (30 minutes)
- Create 3 example documents
- Focus on structure and key patterns
- Add cross-references

**Total Estimated Time**: 3-4 hours

**Parallel Work Opportunities**:
- Tasks 1, 2, 3 can be worked in parallel (different files)
- Tasks 4, 5, 6 can be worked after Tasks 1-3 complete
- Testing can begin as soon as first 3 tasks complete

### Deliverables Summary

**Updated Documents** (3):
- `.claude/docs/concepts/hierarchical_agents.md` - Add behavioral injection section
- `.claude/CHANGELOG.md` - Document all fixes and changes
- `.claude/docs/guides/README.md` - Update index with new guides

**Completed Guides** (2):
- `.claude/docs/guides/agent-authoring-guide.md` - 7 sections, complete
- `.claude/docs/guides/command-authoring-guide.md` - 8 sections, complete

**New Documents** (4):
- `.claude/docs/troubleshooting/agent-delegation-issues.md` - 5 issues
- `.claude/docs/examples/behavioral-injection-workflow.md` - Complete workflow
- `.claude/docs/examples/correct-agent-invocation.md` - Task tool examples
- `.claude/docs/examples/reference-implementations.md` - Reference guide

**Total**: 9 documents created or updated

### Verification Steps

After completing all tasks:

```bash
# Step 1: Run documentation quality checks
bash .claude/tests/validate_documentation_quality.sh

# Step 2: Run cross-reference validation
bash .claude/tests/validate_cross_references.sh

# Step 3: Run terminology consistency checks
bash .claude/tests/validate_terminology_consistency.sh

# Step 4: Manual review
# - Read each document for clarity
# - Verify code examples work
# - Test cross-reference navigation
# - Check for typos and formatting issues

# Step 5: Integration with Phase 6
# Phase 6 (Integration Testing) will verify documentation by:
# - Running all validation scripts
# - Testing troubleshooting solutions actually work
# - Verifying examples execute successfully
# - Checking cross-references are navigable
```

---

## Notes

### Design Decisions

**Decision 1: Documentation-First Approach**
- **Rationale**: Documentation captures implementation knowledge before it's lost
- **Benefit**: Enables knowledge transfer, prevents regression, supports onboarding
- **Trade-off**: Takes time, but pays dividends in long-term maintainability

**Decision 2: Extensive Cross-Referencing**
- **Rationale**: Documents more useful when they link to related content
- **Benefit**: Creates navigable documentation ecosystem, reduces duplicate content
- **Trade-off**: More links to maintain, but vastly improves usability

**Decision 3: Multiple Documentation Types**
- **Guides**: How-to documentation (agent authoring, command authoring)
- **Concepts**: Architectural documentation (hierarchical agents)
- **Troubleshooting**: Problem-solution documentation
- **Examples**: Reference implementations and workflows
- **Rationale**: Different learning styles need different documentation types
- **Benefit**: Comprehensive coverage for all user types

**Decision 4: Detailed Troubleshooting Guide**
- **Rationale**: Most users will encounter issues, need quick solutions
- **Benefit**: Reduces support burden, enables self-service debugging
- **Trade-off**: Requires maintaining troubleshooting guide as code evolves

**Decision 5: Cross-Reference Requirements in Revision 3**
- **Rationale**: Traceability critical for audit trails and understanding research provenance
- **Benefit**: Complete workflow documentation from summary → plan → research reports
- **Documented**: In agent-authoring-guide.md Section 3, command-authoring-guide.md Section 4

### Integration with Other Phases

**Phase 1 Dependencies**:
- Agent authoring guide and command authoring guide skeletons created in Phase 1
- This phase completes those guides with full content

**Phase 4 Integration**:
- Validation scripts documented in troubleshooting guide
- Troubleshooting guide references validation scripts for diagnosis

**Phase 6 Integration**:
- Documentation validated in Phase 6 integration tests
- Troubleshooting solutions tested to verify they work
- Examples executed to verify correctness

### Maintenance Considerations

**Keeping Documentation Current**:
- Update agent-authoring-guide.md when creating new agent patterns
- Update command-authoring-guide.md when creating new commands
- Add new troubleshooting issues as they're discovered
- Update examples when utilities change

**Documentation Review Triggers**:
- New command created → Update command-authoring-guide.md
- New agent created → Update agent-authoring-guide.md
- New utility created → Update relevant guides with usage examples
- Bug fixed → Consider adding to troubleshooting guide

### Success Metrics

**Quantitative**:
- 9 documents created/updated ✓
- ≥20 cross-references ✓
- ≥30 code examples across all docs ✓
- 5 troubleshooting issues documented ✓
- 100% documentation quality checks passing ✓

**Qualitative**:
- Documentation clear and easy to understand
- Code examples work when copy-pasted
- Troubleshooting solutions resolve issues
- Cross-references enable navigation
- Examples demonstrate best practices

**Long-Term**:
- New contributors can onboard using guides
- Common issues self-resolved via troubleshooting guide
- Zero new anti-pattern violations (education effective)
- Documentation remains current and useful

---

## Spec Updater Checklist

- [ ] Ensure all documentation files in appropriate directories
- [ ] Verify cross-references use correct relative paths
- [ ] Confirm examples directory created under docs/
- [ ] Verify CHANGELOG follows standard format
- [ ] Confirm all code blocks use proper syntax highlighting
- [ ] Verify troubleshooting guide committed (permanent reference)
- [ ] Update guides/README.md with new guide references
