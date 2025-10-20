# Agent Authoring Guide

## Purpose

This guide provides comprehensive guidelines for creating agent behavioral files that follow the **behavioral injection pattern** - the correct architectural approach for command/agent interactions in the Claude Code system.

**Target Audience**: Developers creating new agent behavioral files or modifying existing ones.

**Related Documentation**:
- [Command Authoring Guide](command-authoring-guide.md) - How commands invoke agents
- [Hierarchical Agent Architecture](../concepts/hierarchical_agents.md) - Overall architecture
- [Troubleshooting Guide](../troubleshooting/agent-delegation-issues.md) - Common issues

## Section 1: Agent Behavioral Files Overview

### What Are Agent Behavioral Files?

Agent behavioral files (`.claude/agents/*.md`) define specialized agent behavior for specific tasks:
- **research-specialist.md**: Conducts codebase research and creates reports
- **plan-architect.md**: Creates implementation plans from requirements
- **code-writer.md**: Executes code changes from task specifications
- **debug-analyst.md**: Investigates bugs and creates debug reports
- **doc-writer.md**: Creates documentation and workflow summaries

### Agent Lifecycle

1. **Command invokes agent**: Primary command uses Task tool to invoke agent
2. **Agent receives context**: Command injects behavioral prompt + task-specific context
3. **Agent executes**: Agent uses Read/Write/Edit tools to complete task
4. **Agent returns metadata**: Path + summary + key findings (NOT full content)
5. **Command processes**: Command verifies artifact and extracts metadata

### Agent Responsibilities

**Agents SHOULD:**
- ✅ Create artifacts directly using Write tool
- ✅ Use Read/Edit tools to analyze and modify files
- ✅ Use Grep/Glob tools for codebase discovery
- ✅ Return structured metadata (path, summary, findings)
- ✅ Follow topic-based artifact organization

**Agents SHOULD NOT:**
- ❌ Invoke slash commands (use SlashCommand tool for artifact creation)
- ❌ Make assumptions about artifact paths (use provided ARTIFACT_PATH)
- ❌ Return full artifact content (metadata only)
- ❌ Create artifacts outside topic-based structure

## Section 2: The Behavioral Injection Pattern

### Pattern Overview

The behavioral injection pattern separates concerns:
- **Commands**: Orchestration, path calculation, verification, metadata extraction
- **Agents**: Execution, artifact creation, analysis

### How It Works

```
1. Command Pre-Calculates Path
   ↓
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
   TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE" "specs")
   ARTIFACT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "research" "")
   # Result: specs/042_feature/reports/042_research.md

2. Command Loads Agent Behavioral Prompt
   ↓
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/agent-loading-utils.sh"
   AGENT_PROMPT=$(load_agent_behavioral_prompt "research-specialist")

3. Command Injects Complete Context
   ↓
   Task {
     subagent_type: "general-purpose"
     prompt: |
       $AGENT_PROMPT

       **Task**: Research authentication patterns
       **Artifact Path**: $ARTIFACT_PATH
       **Success Criteria**: Create report at exact path
   }

4. Agent Creates Artifact
   ↓
   (Agent uses Write tool to create file at ARTIFACT_PATH)

5. Command Verifies and Extracts Metadata
   ↓
   VERIFIED=$(verify_artifact_or_recover "$ARTIFACT_PATH" "research")
   METADATA=$(extract_report_metadata "$VERIFIED")
```

### Why This Pattern?

**Benefits:**
- 📍 **Path Control**: Commands control exact artifact locations
- 📦 **Topic Organization**: All artifacts in topic-based structure
- 🔢 **Consistent Numbering**: Sequential NNN across artifact types
- 🎯 **Context Reduction**: 95% reduction via metadata-only passing
- 🚫 **No Recursion**: Agents never invoke commands that invoked them
- 🏗️ **Architectural Consistency**: All commands follow same pattern

## Section 3: Anti-Patterns and Why They're Wrong

### Anti-Pattern 1: Agent Invokes Slash Command

**WRONG:**
```markdown
# plan-architect.md

## Step 1: Create Implementation Plan

**CRITICAL**: You MUST use the SlashCommand tool to invoke /plan:

SlashCommand {
  command: "/plan ${FEATURE_DESCRIPTION}"
}
```

**Why It's Wrong:**
- ❌ Loss of path control (can't pre-calculate artifact location)
- ❌ Cannot extract metadata before context bloat
- ❌ Breaks topic-based organization (slash command may use different structure)
- ❌ Violates separation of concerns (agent doing orchestration)
- ❌ Makes testing difficult (can't mock agent behavior)

**Impact:**
- Context bloat: 168.9k tokens (no reduction)
- Artifacts may be created in wrong locations
- Inconsistent numbering across workflows

### Anti-Pattern 2: Agent Invokes Command That Invoked It

**WRONG:**
```markdown
# code-writer.md

## Type A: Plan-Based Implementation

If you receive a plan file path, use /implement to execute it:

SlashCommand {
  command: "/implement ${PLAN_PATH}"
}
```

**Why It's Wrong:**
- ❌ **Recursion risk**: /implement → code-writer → /implement → ∞
- ❌ Infinite loops possible
- ❌ Agent misunderstanding its role (executor, not orchestrator)

**Impact:**
- Risk of infinite recursion
- Timeouts and failures
- Confused responsibility boundaries

### Anti-Pattern 3: Manual Path Construction

**WRONG:**
```markdown
# research-specialist.md

Create report at: specs/reports/${TOPIC}.md
```

**Why It's Wrong:**
- ❌ Breaks topic-based organization (flat structure)
- ❌ Inconsistent numbering (no NNN prefix)
- ❌ Difficult artifact discovery (scattered locations)
- ❌ Non-compliant with `.claude/docs/README.md` standards

**Impact:**
- Reports created in flat structure: `specs/reports/topic.md`
- Should be: `specs/042_topic/reports/042_topic.md`
- Loss of centralized artifact organization

## Section 4: Correct Patterns with Examples

### Pattern 1: Agent Creates Artifact at Provided Path

**CORRECT:**
```markdown
# plan-architect.md

## Step 1: Receive Task Context

You will receive:
- **Feature Description**: The feature to implement
- **Research Reports**: Paths to research that informs the plan
- **Plan Output Path**: EXACT path where plan must be created

## Step 2: Create Implementation Plan

Use the Write tool to create the plan at the EXACT path provided:

Write {
  file_path: "${PLAN_PATH}"  # Use exact path from context
  content: |
    # ${FEATURE} Implementation Plan

    ## Metadata
    - **Research Reports**: (paths provided in context)

    ## Phases
    ...
}

## Step 3: Return Metadata

Return structured metadata:
{
  "path": "${PLAN_PATH}",
  "phase_count": N,
  "complexity_score": XX,
  "estimated_hours": YY
}
```

**Why It's Correct:**
- ✅ Agent uses provided path (no assumptions)
- ✅ Uses Write tool (not SlashCommand)
- ✅ Returns metadata only (no full content)
- ✅ Clear separation of concerns

### Pattern 2: Agent Uses Read/Write/Edit Tools

**CORRECT:**
```markdown
# code-writer.md

## Step 1: Receive Task List

You will receive specific code change TASKS (NOT plan file paths).

## Step 2: Execute Tasks

For each task:

1. Read existing files (if modifying):
   Read { file_path: "/path/to/file.js" }

2. Make changes:
   Edit {
     file_path: "/path/to/file.js"
     old_string: "old code"
     new_string: "new code"
   }

3. Create new files (if needed):
   Write {
     file_path: "/path/to/new-file.js"
     content: "..."
   }

## CRITICAL: Tool Usage

**ALWAYS use:** Read, Write, Edit, Grep, Glob, Bash
**NEVER use:** SlashCommand (for /implement, /plan, /report, etc.)
```

**Why It's Correct:**
- ✅ Uses appropriate tools for file operations
- ✅ No slash command invocations
- ✅ Clear role: execute tasks, not orchestrate workflows

### Pattern 3: Research Agent with Topic-Based Artifacts

**CORRECT:**
```markdown
# research-specialist.md

## Step 1: Receive Research Context

You will receive:
- **Research Focus**: Topic to research (patterns, best practices, alternatives)
- **Feature Description**: Context for research
- **Report Output Path**: EXACT topic-based path (specs/{NNN_topic}/reports/{NNN}_topic.md)

## Step 2: Conduct Research

Use Grep, Glob, Read tools to:
1. Search codebase for existing implementations
2. Identify relevant patterns and utilities
3. Research best practices
4. Document alternative approaches

## Step 3: Create Report at Exact Path

Write {
  file_path: "${REPORT_PATH}"  # Topic-based path from context
  content: |
    # ${TOPIC} Research Report

    ## Executive Summary
    (50-word summary)

    ## Findings
    ...

    ## Recommendations
    ...
}

## Step 4: Return Metadata

{
  "path": "${REPORT_PATH}",
  "summary": "50-word summary",
  "key_findings": ["finding 1", "finding 2"],
  "recommendations": ["rec 1", "rec 2"]
}
```

**Why It's Correct:**
- ✅ Uses provided topic-based path
- ✅ Metadata-only return (95% context reduction)
- ✅ Clear research methodology
- ✅ Structured output format

## Section 5: Tool Usage Guidelines

### Allowed Tools (for Agents)

#### File Operations
- **Read**: Read file contents for analysis
- **Write**: Create new files at provided paths
- **Edit**: Modify existing files with exact string replacement

#### Code Discovery
- **Grep**: Search file contents with regex patterns
- **Glob**: Find files matching glob patterns
- **WebSearch**: Research external documentation (when needed)

#### Execution
- **Bash**: Run commands for testing, validation, file operations

### Restricted Tools (for Agents)

#### SlashCommand Tool
- **NEVER** use SlashCommand for:
  - `/plan` - Plan creation is command's responsibility
  - `/report` - Report creation is direct (not via command)
  - `/implement` - Implementation orchestration is command's responsibility
  - `/debug` - Debug workflow is command's responsibility

**Exceptions** (when SlashCommand IS allowed):
- Agent needs to delegate to another specialized command (rare)
- Explicitly instructed in behavioral file (with clear rationale)
- Example: doc-writer invoking `/list reports` to discover artifacts

### Tool Selection Decision Tree

```
Need to create artifact?
  ↓
  Is ARTIFACT_PATH provided in context?
    ↓ YES
    Use Write tool with exact path ✅
    ↓ NO
    ERROR: Agent should not assume paths ❌

Need to modify existing file?
  ↓
  Use Edit tool with old_string/new_string ✅

Need to search codebase?
  ↓
  Content search → Grep ✅
  File search → Glob ✅

Need to execute command?
  ↓
  File operation (cp, mv, mkdir) → Bash ✅
  Slash command (/plan, /implement) → NEVER ❌
```

## Section 6: Reference Implementations

### Example 1: research-specialist.md

**File**: `/home/benjamin/.config/.claude/agents/research-specialist.md`

**Pattern Used**: Topic-based artifact creation with metadata return

**Key Features:**
- Receives pre-calculated REPORT_PATH from command
- Uses Write tool to create report at exact path
- Returns metadata only (path + summary + findings)
- No slash command invocations

**Invocation Pattern** (from `/plan` command):
```markdown
Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    Research Focus: ${TOPIC}
    Feature: ${FEATURE_DESCRIPTION}
    Report Output Path: specs/042_feature/reports/042_research.md
}
```

**Why It's Correct:**
- Command pre-calculates topic-based path
- Command injects path into agent context
- Agent creates artifact at exact path
- Agent returns metadata only

### Example 2: debug-analyst.md

**File**: `/home/benjamin/.config/.claude/agents/debug-analyst.md`

**Pattern Used**: Parallel hypothesis investigation with artifact creation

**Key Features:**
- Receives hypothesis + ARTIFACT_PATH from command
- Investigates root cause using Grep/Read/Bash tools
- Creates debug report at topic-based path (specs/{NNN}/debug/{NNN}_investigation.md)
- Returns metadata with findings and proposed fixes

**Invocation Pattern** (from `/debug` command):
```markdown
Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/debug-analyst.md

    Investigation Context:
    - Issue: ${ISSUE_DESCRIPTION}
    - Hypothesis: ${HYPOTHESIS}
    - Artifact Path: specs/027_bugfix/debug/027_investigation_${HYPOTHESIS}.md
}
```

**Why It's Correct:**
- Command generates hypotheses (orchestration)
- Command invokes multiple debug-analyst agents in parallel
- Each agent investigates one hypothesis independently
- Agents return metadata only (context reduction)

### Example 3: spec-updater.md

**File**: `/home/benjamin/.config/.claude/agents/spec-updater.md`

**Pattern Used**: Cross-reference management between artifacts

**Key Features:**
- Updates plan metadata with report references
- Updates report with plan references
- Validates bidirectional cross-references
- Used by /report, /plan commands after artifact creation

**Invocation Pattern** (from `/report` command):
```markdown
Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/spec-updater.md

    Context:
    - Report created at: ${REPORT_PATH}
    - Topic directory: ${TOPIC_DIR}
    - Related plan (if exists): ${PLAN_PATH}
    - Operation: report_creation
}
```

**Why It's Correct:**
- Agent manages cross-references (specialized task)
- Agent receives artifact paths (no path calculation)
- Agent uses Edit tool to update metadata sections
- Agent returns cross-reference status (metadata)

## Section 7: Cross-Reference Requirements

### Plan-Architect Agent

**Requirement**: Plans MUST reference all research reports that informed them.

**Implementation**:
```markdown
# plan-architect.md

## Metadata Section

All plans must include a "Research Reports" section:

## Metadata
- **Date**: YYYY-MM-DD
- **Feature**: ${FEATURE_DESCRIPTION}
- **Research Reports**:
  - ${RESEARCH_REPORT_PATH_1}
  - ${RESEARCH_REPORT_PATH_2}
  - ...

This enables traceability from plan to research.
```

**Why It Matters:**
- Audit trail: Which research informed which plan decisions
- Discoverability: Easy to find related artifacts
- Validation: Ensures research phase completed before planning

### Doc-Writer Agent (Summarizer)

**Requirement**: Workflow summaries MUST reference all artifacts generated.

**Implementation**:
```markdown
# doc-writer.md

## Artifacts Generated Section

All workflow summaries must include:

## Artifacts Generated

### Research Reports
- ${RESEARCH_REPORT_PATH_1}
- ${RESEARCH_REPORT_PATH_2}
- ...

### Implementation Plan
- ${PLAN_PATH}

### Debug Reports (if applicable)
- ${DEBUG_REPORT_PATH_1}
- ...

This provides complete workflow audit trail.
```

**Why It Matters:**
- Complete workflow history
- Easy artifact discovery
- Enables workflow validation
- Supports /list-summaries command

### Cross-Reference Format

**Absolute Paths** (in command contexts):
```
/home/benjamin/.config/.claude/specs/042_auth/reports/042_security.md
```

**Relative Paths** (within same topic):
```
../reports/042_security.md  (from plans/ to reports/)
./042_implementation.md      (within same directory)
```

**Why Relative Paths Within Topics:**
- Topic directories may move
- Relative paths remain valid
- Easier to read and maintain

## Best Practices Summary

### DO:
- ✅ Use provided ARTIFACT_PATH (no assumptions)
- ✅ Create artifacts in topic-based structure
- ✅ Return metadata only (path + summary + findings)
- ✅ Use Read/Write/Edit tools for file operations
- ✅ Include cross-references in metadata sections
- ✅ Follow established patterns from reference implementations

### DON'T:
- ❌ Invoke slash commands for artifact creation
- ❌ Construct artifact paths manually
- ❌ Return full artifact content (context bloat)
- ❌ Create artifacts outside topic structure
- ❌ Invoke commands that invoked you (recursion)
- ❌ Make assumptions about project structure

### Testing Your Agent

1. **Unit Test**: Test agent in isolation with mocked inputs
2. **Integration Test**: Test agent invocation from command
3. **Anti-Pattern Check**: Scan for SlashCommand usage
4. **Metadata Validation**: Verify metadata-only return
5. **Path Compliance**: Verify topic-based artifact paths

## Troubleshooting

See [Agent Delegation Troubleshooting Guide](../troubleshooting/agent-delegation-issues.md) for:
- Agent invokes slash command instead of creating artifact
- Artifact not found at expected path
- Context reduction not achieved
- Recursion risk or infinite loops
- Artifacts not in topic-based directories

## Related Documentation

- [Command Authoring Guide](command-authoring-guide.md) - How to invoke agents from commands
- [Hierarchical Agent Architecture](../concepts/hierarchical_agents.md) - Overall system architecture
- [Topic-Based Artifact Organization](../README.md) - Directory structure standards
- [Reference Implementations](../examples/reference-implementations.md) - Complete examples
