# Command Development Guide

Comprehensive guide for developing custom slash commands with standards integration, agent coordination, and testing protocols.

For a quick reference of all available commands, see [Command Quick Reference](../reference/command-reference.md).

## Table of Contents

1. [Introduction](#1-introduction)
2. [Command Architecture](#2-command-architecture)
3. [Command Development Workflow](#3-command-development-workflow)
4. [Standards Integration](#4-standards-integration)
5. [Agent Integration](#5-agent-integration)
6. [Testing and Validation](#6-testing-and-validation)
7. [Common Patterns and Examples](#7-common-patterns-and-examples)
8. [References](#references)

---

## 1. Introduction

### 1.1 What is a Command?

Commands are structured workflows that extend Claude's capabilities for specific development tasks. They are defined in markdown files with metadata and behavioral guidelines that Claude interprets and executes.

**Key characteristics**:
- **Workflow automation**: Multi-step procedures with clear objectives
- **Tool access**: Defined set of allowed tools (Read, Write, Edit, Bash, etc.)
- **Standards awareness**: Discover and apply project conventions
- **Agent delegation**: Can invoke specialized agents for complex tasks
- **Testable**: Include validation and testing procedures

### 1.2 When to Create a New Command

Create a new command when:

| Scenario | Create Command? | Rationale |
|----------|----------------|-----------|
| Repetitive 3+ step workflow | ✓ Yes | Automation reduces errors |
| Standards-dependent task | ✓ Yes | Consistent standards application |
| Multi-file coordination needed | ✓ Yes | Clear workflow structure |
| Requires agent orchestration | ✓ Yes | Specialized agent delegation |
| One-time task | ✗ No | Direct execution simpler |
| Existing command handles it | ✗ No | Avoid duplication |
| Trivial operation (<3 steps) | ✗ No | Overhead not justified |

### 1.3 Command vs Agent vs Script

| Aspect | Command | Agent | Script |
|--------|---------|-------|--------|
| Invocation | `/command-name` | Task tool | `.claude/lib/*.sh` |
| Complexity | High-level workflow | Focused task | Low-level utility |
| Tools | Multiple allowed | Restricted set | Bash only |
| User-facing | Yes | No (internal) | No (internal) |
| Purpose | Orchestration | Specialized execution | Helper functions |
| Example | `/implement` | research-specialist | checkpoint-utils.sh |

**When to use what**:
- **Command**: User-facing workflows (planning, implementing, testing)
- **Agent**: Delegated specialized tasks (research, code writing, testing)
- **Script**: Shared utilities (parsing, logging, checkpointing)

---

## 2. Command Architecture

### 2.1 Command Definition Format

Commands are markdown files with YAML frontmatter metadata:

```markdown
---
allowed-tools: Read, Edit, Write, Bash, Grep, Glob, TodoWrite
argument-hint: <required-arg> [optional-arg]
description: Brief one-line description of command purpose
command-type: primary
dependent-commands: cmd1, cmd2, cmd3
---

# Command Name

Detailed description of what the command does and when to use it.

## Usage
/command <required-arg> [optional-arg]

## Standards Discovery and Application
How the command discovers and applies CLAUDE.md standards

## Workflow
Step-by-step execution process

## Output
What the command produces
```

### 2.2 Metadata Fields

#### allowed-tools
**Purpose**: Tools the command can use during execution

**Format**: Comma-separated list

**Available tools**:
- `Read` - Read files
- `Write` - Create new files
- `Edit` - Modify existing files
- `Bash` - Execute shell commands
- `Grep` - Search file contents
- `Glob` - Find files by pattern
- `TodoWrite` - Track task progress
- `Task` - Invoke specialized agents
- `WebSearch`, `WebFetch` - Web research

**Example**:
```yaml
allowed-tools: Read, Edit, Write, Bash, TodoWrite
```

**Validation rule**: Include only tools actually needed, follow least-privilege principle

#### argument-hint
**Purpose**: Argument structure for help text and autocomplete

**Format**: `<required> [optional]`

**Example**:
```yaml
argument-hint: <feature-description> [report-path1] [report-path2]
```

#### description
**Purpose**: One-line summary shown in command listings

**Format**: Brief, action-oriented description (≤80 characters)

**Example**:
```yaml
description: Execute implementation plans with automated testing and commits
```

#### command-type
**Purpose**: Categorizes command for organization and discovery

**Format**: One of: `primary`, `support`, `workflow`, `utility`

**Types explained**:
- **primary**: Main workflow drivers (`/implement`, `/plan`, `/report`)
- **support**: Helper commands (`/debug`, `/document`, `/refactor`)
- **workflow**: Execution state management (`/revise`, `/expand`)
- **utility**: Maintenance commands (`/setup`, `/list-plans`)

**Example**:
```yaml
command-type: primary
```

#### dependent-commands
**Purpose**: Related commands that work together

**Format**: Comma-separated list of command names (without `/`)

**Example**:
```yaml
dependent-commands: list-plans, revise, debug, document
```

### 2.3 Tools and Permissions

#### Tool Selection Guidelines

**Minimal tool set**: Include only tools actually needed
**Security implications**: More tools = more power = more responsibility

| Tool | Use For | Security Level | Notes |
|------|---------|---------------|-------|
| Read | File reading | Low | Safe, read-only |
| Edit | Modify existing files | Medium | Changes tracked |
| Write | Create new files | Medium | Cannot overwrite |
| Bash | Shell commands | High | Can execute anything |
| Task | Agent invocation | High | Complex operations |

**Best practice**: Start with minimal tools, add as needed

#### Tool Permission Matrix

```
Command Type     | Typical Tools
-----------------|------------------------------------------
Research         | Read, Grep, Glob, WebSearch, WebFetch
Planning         | Read, Write, Bash, Grep, Glob
Implementation   | Read, Edit, Write, Bash, TodoWrite
Testing          | Read, Bash, TodoWrite
Documentation    | Read, Edit, Write
Orchestration    | Read, Write, Bash, Task, TodoWrite
```

---

## 3. Command Development Workflow

### 3.1 Development Process Steps

Follow this 8-step procedure when creating a new command:

#### 1. Define Purpose and Scope

**Questions to answer**:
- What problem does this command solve?
- What workflow does it automate?
- Who is the primary user?
- What are success criteria?

**Output**: Clear purpose statement and scope boundaries

#### 2. Design Command Structure

**Tasks**:
- Choose command type (primary/support/workflow/utility)
- Define argument structure
- Select minimal tool set
- Identify dependent commands

**Output**: Metadata section complete

#### 3. Implement Behavioral Guidelines

**Tasks**:
- Write workflow section with step-by-step procedure
- Document expected inputs and outputs
- Add error handling guidance
- Include practical examples

**Output**: Core command documentation

#### 4. Add Standards Discovery Section

**Tasks**:
- Document which CLAUDE.md sections are used
- Explain discovery process
- Show how standards influence behavior
- Define fallback behavior

**Output**: Standards Discovery and Application section

#### 5. Integrate with Agents (if needed)

**Tasks**:
- Identify which agents to use
- Define agent invocation patterns using behavioral injection
- Document context passing with metadata-only approach
- Specify result handling

**Output**: Agent Integration section (if applicable)

#### 6. Add Testing and Validation

**Tasks**:
- Define test commands
- Specify validation criteria
- Add manual testing procedures
- Document expected results

**Output**: Testing section

#### 7. Document Usage and Examples

**Tasks**:
- Write complete usage examples
- Add edge case scenarios
- Include error handling examples
- Cross-reference related commands

**Output**: Examples section

#### 8. Add to Commands README

**Tasks**:
- Add command to README command list
- Update navigation links
- Add to appropriate category section
- Test command invocation

**Output**: Command discoverable and documented

### 3.2 Quality Checklist

Before committing a new command, verify:

**Structure**:
- [ ] Frontmatter metadata complete and valid
- [ ] All metadata fields present
- [ ] Command type appropriate
- [ ] Tool selection justified

**Content**:
- [ ] Purpose clearly stated
- [ ] Usage syntax documented
- [ ] Workflow section with steps
- [ ] Output description present
- [ ] Examples included

**Standards Integration** (if applicable):
- [ ] Standards Discovery section present
- [ ] Documents which CLAUDE.md sections used
- [ ] Shows how standards influence behavior
- [ ] Fallback behavior documented
- [ ] Uses "CLAUDE.md" terminology consistently

**Agent Integration** (if applicable):
- [ ] Agents clearly identified
- [ ] Invocation patterns use behavioral injection
- [ ] Context passing explained (metadata-only)
- [ ] Result handling specified

**Testing**:
- [ ] Test procedures documented
- [ ] Validation criteria specified
- [ ] Command tested manually
- [ ] Works with and without CLAUDE.md

**Documentation**:
- [ ] Added to commands README
- [ ] Navigation links updated
- [ ] Cross-references complete
- [ ] Examples tested

---

## 4. Standards Integration

### 4.1 Standardization Pattern Template

Use this template when adding standards integration to commands:

```markdown
## Standards Discovery and Application

### Discovery Process
1. **Locate CLAUDE.md**: Search upward from working directory
2. **Check Subdirectory Standards**: Look for directory-specific CLAUDE.md
3. **Parse Relevant Sections**: Extract sections used by this command
4. **Handle Missing Standards**: Use fallback behavior

### Standards Sections Used
- **Code Standards**: [What is extracted and how it's used]
- **Testing Protocols**: [What is extracted and how it's used]
- **Documentation Policy**: [What is extracted and how it's used]

### Application During [Command Operation]
[Specific examples of how standards influence command behavior]

#### Code Generation
- **Indentation**: Generated code matches CLAUDE.md specification
- **Naming**: Follows conventions (snake_case, camelCase, etc.)
- **Error Handling**: Uses specified patterns (pcall, try-catch, etc.)

#### Testing
- **Test Commands**: Uses commands from Testing Protocols
- **Test Patterns**: Creates tests matching patterns
- **Coverage**: Aims for coverage requirements

#### Documentation
- **Format**: Follows Documentation Policy
- **README Requirements**: Ensures required sections present
- **Examples**: Includes usage examples

### Compliance Verification
Before marking [operation] complete:
- [ ] Code style matches CLAUDE.md specifications
- [ ] Naming follows project conventions
- [ ] Error handling matches project patterns
- [ ] Tests follow testing standards and pass
- [ ] Documentation meets policy requirements

### Fallback Behavior
When CLAUDE.md not found or incomplete:
1. **Use Language Defaults**: Apply sensible language-specific conventions
2. **Suggest Creation**: Recommend running `/setup` to create CLAUDE.md
3. **Graceful Degradation**: Continue with reduced standards enforcement
4. **Document Limitations**: Note in output which standards were uncertain
```

### 4.2 Terminology Guidelines

Use consistent terminology across all commands:

| Prefer | Avoid | Context |
|--------|-------|---------|
| CLAUDE.md | standards file, project standards | File name reference |
| project standards | standards, conventions | Content reference |
| Code Standards | code style, coding standards | Section name |
| Testing Protocols | test standards, test config | Section name |
| Documentation Policy | doc standards, doc rules | Section name |
| discover standards | find standards, locate standards | Action |
| apply standards | use standards, enforce standards | Action |
| fallback behavior | default behavior, graceful degradation | Missing standards |

---

## 5. Agent Integration

### 5.1 When Commands Use Agents

Commands delegate to agents when tasks require:

**Specialized expertise**:
- Research requiring web search and analysis
- Complex code generation with multiple patterns
- Test suite creation with coverage analysis
- Architectural design decisions

**Complex operations**:
- Multi-file refactoring
- Codebase-wide pattern analysis
- Documentation generation from code
- Performance optimization analysis

**Parallelizable work**:
- Multiple independent research topics
- Parallel test suite execution
- Concurrent documentation updates

### 5.2 Behavioral Injection Pattern

Commands inject agent behavior by referencing agent definition files and providing complete context:

#### Option A: Load and Inject Behavioral Prompt

**When to Use**:
- Need to modify agent behavior programmatically
- Want to add command-specific instructions
- Building dynamic prompts

**Implementation**:
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
"

# Invoke agent with complete prompt
Task {
  subagent_type: "general-purpose"
  description: "Research security patterns for ${FEATURE}"
  prompt: "$COMPLETE_PROMPT"
}
```

#### Option B: Reference Agent File (Simpler)

**When to Use**:
- Agent behavioral file is complete
- No need for custom instructions
- Prefer cleaner command code

**Implementation**:
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

### 5.3 Pre-Calculating Topic-Based Artifact Paths

**Why Pre-Calculate Paths?**

**Reasons:**
1. **Control**: Command controls exact artifact locations
2. **Topic Organization**: Enforces `specs/{NNN_topic}/` structure
3. **Consistent Numbering**: Sequential NNN across artifact types
4. **Verification**: Can verify artifact created at expected path
5. **Metadata Extraction**: Know exact path for metadata loading

**Standard Path Calculation Pattern**:

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

### 5.4 Artifact Verification Patterns

**Verification with Recovery**:

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

### 5.5 Metadata Extraction

**Why Extract Metadata Only?**

**Context Reduction**: 95% reduction in token usage

**Example**:
- Full report: 5000 tokens
- Metadata only: 250 tokens (path + summary + findings)
- Reduction: 95%

**Metadata Extraction Pattern**:

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

See [Correct Agent Invocation Examples](../examples/correct-agent-invocation.md) for complete invocation templates.

---

## 6. Testing and Validation

### 6.1 Testing Standards Integration

Commands should discover test commands from CLAUDE.md:

#### Test Discovery Procedure

```bash
# 1. Locate CLAUDE.md
CLAUDE_MD=$(find_claude_md)

# 2. Extract Testing Protocols section
TEST_PROTOCOLS=$(extract_section "$CLAUDE_MD" "Testing Protocols")

# 3. Parse test commands
TEST_COMMAND=$(echo "$TEST_PROTOCOLS" | grep -oP 'Test Command: \K.*' | head -1)

# 4. Execute discovered test command
if [ -n "$TEST_COMMAND" ]; then
  eval "$TEST_COMMAND"
else
  # Fallback to language defaults
  if [ -f "package.json" ]; then
    npm test
  elif [ -f "Makefile" ]; then
    make test
  else
    echo "No test command found"
  fi
fi
```

### 6.2 Validation Checklist

Before marking command complete:

**Functional Validation**:
- [ ] Command executes without errors
- [ ] Expected output is produced
- [ ] Output format is correct
- [ ] File modifications are correct
- [ ] No unintended side effects

**Standards Compliance**:
- [ ] Discovers CLAUDE.md correctly
- [ ] Applies discovered standards
- [ ] Handles missing CLAUDE.md gracefully
- [ ] Uses correct terminology
- [ ] Validates compliance before completion

**Agent Integration** (if applicable):
- [ ] Agents invoked using behavioral injection
- [ ] Context passed efficiently (metadata-only)
- [ ] Results processed correctly
- [ ] Errors handled gracefully

**User Experience**:
- [ ] Clear progress indicators
- [ ] Helpful error messages
- [ ] Appropriate logging
- [ ] Expected completion message

---

## 7. Common Patterns and Examples

### 7.1 Example: Research Command with Agent Delegation

```markdown
## Workflow for /report Command

### Step 1: Pre-Calculate Report Path

**EXECUTE NOW - Calculate Report Path**

```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-creation.sh"
TOPIC_DIR=$(get_or_create_topic_dir "$RESEARCH_TOPIC" ".claude/specs")
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "001_${TOPIC_SLUG}" "")
echo "Report will be written to: $REPORT_PATH"
```

### Step 2: Invoke Research Agent with Enforcement

**AGENT INVOCATION - Use Behavioral Injection**

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${RESEARCH_TOPIC}"
  prompt: "
    Read and follow: .claude/agents/research-specialist.md

    **ABSOLUTE REQUIREMENT**: Creating the report file is your PRIMARY task.

    Research Topic: ${RESEARCH_TOPIC}
    Output Path: ${REPORT_PATH}

    **STEP 1 (REQUIRED BEFORE STEP 2)**: Use Write tool to create file at ${REPORT_PATH}
    **STEP 2**: Conduct research and populate file
    **STEP 3 (MANDATORY)**: Return ONLY: REPORT_CREATED: ${REPORT_PATH}

    **NON-NEGOTIABLE**: File must exist at ${REPORT_PATH} when you complete.
  "
}
```

### Step 3: Verify and Fallback

**MANDATORY VERIFICATION - Report File Exists**

```bash
if [ ! -f "$REPORT_PATH" ]; then
  echo "CRITICAL: Agent didn't create report file"
  echo "Executing fallback creation..."

  cat > "$REPORT_PATH" <<EOF
# ${RESEARCH_TOPIC}

## Findings
${AGENT_OUTPUT}
EOF
fi

echo "✓ Verified: Report exists at $REPORT_PATH"
```
```

### 7.2 Anti-Patterns to Avoid

| Anti-Pattern | Why It's Wrong | Correct Approach |
|--------------|---------------|------------------|
| **Using /expand for content changes** | /expand changes structure (creates files), not content | Use /revise to add/modify tasks or objectives |
| **Using /revise for structural reorganization** | Creating separate files is structural | Use /expand to extract phases to files |
| **Including all possible tools** | Increases security risk, violates least privilege | Include only tools actually needed |
| **Duplicating pattern documentation** | Creates maintenance burden, outdated copies | Reference docs with links |
| **Skipping standards discovery** | Inconsistent behavior across projects | Always discover and apply CLAUDE.md standards |
| **Hardcoding test commands** | Breaks in different projects | Discover test commands from CLAUDE.md |
| **Continuing after test failures** | Compounds issues in later phases | Stop, enter debugging loop, fix root cause |
| **Inline agent definitions** | Duplication across commands | Reference agent files via behavioral injection |
| **Large agent context passing** | Token waste | Use metadata-only passing (path + summary) |
| **Missing error handling** | Poor user experience on failures | Include retry logic and user escalation |

---

## Cross-References

### Architectural Patterns

Commands should implement these patterns from the [Patterns Catalog](../concepts/patterns/README.md):

- [Behavioral Injection](../concepts/patterns/behavioral-injection.md) - How commands invoke agents via context injection
- [Verification and Fallback](../concepts/patterns/verification-fallback.md) - Mandatory checkpoints for file creation operations
- [Metadata Extraction](../concepts/patterns/metadata-extraction.md) - Passing report/plan summaries between agents
- [Checkpoint Recovery](../concepts/patterns/checkpoint-recovery.md) - State preservation for resumable workflows
- [Parallel Execution](../concepts/patterns/parallel-execution.md) - Wave-based concurrent agent invocation

### Related Guides

- [Agent Development Guide](agent-development-guide.md) - Creating agents that commands invoke
- [Standards Integration](standards-integration.md) - Implementing CLAUDE.md standards discovery
- [Testing Patterns](testing-patterns.md) - Test organization and validation approaches
- [Execution Enforcement Guide](execution-enforcement-guide.md) - Migration patterns for command refactoring

### Reference Documentation

- [Command Quick Reference](../reference/command-reference.md) - Quick lookup for all commands
- [Command Architecture Standards](../reference/command_architecture_standards.md) - Architecture standards for commands/agents
- [Agent Reference](../reference/agent-reference.md) - Quick agent reference
- [Commands README](../../commands/README.md) - Complete command list and navigation
- [Hierarchical Agent Architecture](../concepts/hierarchical_agents.md) - Multi-agent coordination

---

**Notes**:
- For specific implementation patterns, reference documentation rather than duplicating
- Follow the Development Philosophy: present-focused documentation, no historical markers
- Use Unicode box-drawing for diagrams, no emojis in content
- Maintain cross-references to related documentation
