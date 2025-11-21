# Command Development Guide

**Path**: docs → guides → command-development-guide.md

Comprehensive guide for developing custom slash commands with standards integration, agent coordination, and testing protocols.

For a quick reference of all available commands, see [Command Quick Reference](../reference/standards/command-reference.md).

## Table of Contents

1. [Introduction](#1-introduction)
2. [Command Architecture](#2-command-architecture)
3. [Command Development Workflow](#3-command-development-workflow)
4. [Standards Integration](#4-standards-integration)
5. [Agent Integration](#5-agent-integration)
6. [State Management Patterns](#6-state-management-patterns)
   - 6.1 [Introduction - Why State Management Matters](#61-introduction---why-state-management-matters)
   - 6.2 [Pattern Catalog](#62-pattern-catalog)
     - 6.2.1 [Pattern 1: Stateless Recalculation](#621-pattern-1-stateless-recalculation)
     - 6.2.2 [Pattern 2: Checkpoint Files](#622-pattern-2-checkpoint-files)
     - 6.2.3 [Pattern 3: File-based State](#623-pattern-3-file-based-state)
     - 6.2.4 [Pattern 4: Single Large Block](#624-pattern-4-single-large-block)
   - 6.3 [Decision Framework](#63-decision-framework)
     - 6.3.1 [Decision Criteria Table](#631-decision-criteria)
     - 6.3.2 [Decision Tree Diagram](#632-decision-tree)
   - 6.4 [Anti-Patterns](#64-anti-patterns)
   - 6.5 [Case Studies](#65-case-studies)
   - 6.6 [Cross-References](#66-cross-references)
7. [Testing and Validation](#7-testing-and-validation)
8. [Common Patterns and Examples](#8-common-patterns-and-examples)
9. [References](#9-references)

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

### 2.4 Executable/Documentation Separation Pattern

**Architecture Principle**: Separate execution logic from comprehensive documentation to eliminate meta-confusion loops and maintain lean, obviously-executable command files.

**Complete Pattern Documentation**: [Executable/Documentation Separation Pattern](../concepts/patterns/executable-documentation-separation.md) - Comprehensive documentation with case studies, metrics, anti-patterns, and migration checklists. This section provides practical implementation guidance; see the pattern document for architectural deep-dive.

#### Problem Statement

Mixed-purpose command files (executable code + extensive documentation) suffer from:
- **Meta-confusion loops**: Claude misinterprets documentation as conversational instructions
- **Recursive invocation bugs**: Attempts to "invoke /command" instead of executing as command
- **Context bloat**: Hundreds of lines of documentation loaded before first executable instruction
- **Maintenance burden**: Changes to docs or logic affect each other

#### Solution Architecture

**Two-file pattern aligned with Diataxis framework**:

1. **Executable Command** (`.claude/commands/command-name.md`)
   - **Purpose**: Lean execution script (target: <250 lines)
   - **Content**: Bash blocks, minimal inline comments, phase structure
   - **Documentation**: One-line link to guide file only

2. **Command Guide** (`.claude/docs/guides/command-name-command-guide.md`)
   - **Purpose**: Complete task-focused documentation (unlimited length)
   - **Content**: Architecture, examples, troubleshooting, design decisions
   - **Audience**: Developers and maintainers

#### Templates

Use these templates for creating new commands:

**Executable Template**: `.claude/docs/guides/templates/_template-executable-command.md`
**Guide Template**: `.claude/docs/guides/templates/_template-command-guide.md`

#### Migration Checklist

When splitting an existing command:

- [ ] Backup original file
- [ ] Identify executable sections (bash blocks + minimal context)
- [ ] Identify documentation sections (architecture, examples, design decisions)
- [ ] Create new lean executable (<250 lines)
- [ ] Extract documentation to guide file
- [ ] Add cross-references (executable → guide, guide → executable)
- [ ] Update CLAUDE.md with guide link
- [ ] Test execution (verify no meta-confusion loops)
- [ ] Verify all phases execute correctly
- [ ] Delete backup (clean-break approach)

#### File Size Guidelines

| File Type | Target Size | Maximum | Rationale |
|-----------|------------|---------|-----------|
| Executable | <200 lines | 250 lines | Obviously executable, minimal context |
| Guide | Unlimited | N/A | Documentation can grow without bloating executable |
| Template | <100 lines | 150 lines | Quick-start reference only |

#### Cross-Reference Convention

**In Executable File**:
```markdown
# /command-name - Brief Title

YOU ARE EXECUTING AS the [command-name] command.

**Documentation**: See `.claude/docs/guides/command-name-command-guide.md`
```

**In Guide File**:
```markdown
# /command-name Command - Complete Guide

**Executable**: `.claude/commands/command-name.md`
```

#### Benefits

✅ **Eliminates Meta-Confusion**: Execution files obviously executable
✅ **Maintainability**: Change logic or docs independently
✅ **Scalability**: Documentation grows without bloating executables
✅ **Fail-Fast**: Commands execute or error immediately
✅ **Clean Architecture**: Clear separation of concerns

#### Validation

Use `.claude/tests/validate_executable_doc_separation.sh` to verify:
- All command files under 250 lines
- All guides exist and are referenced
- Cross-references valid both directions

#### Migration Results

**Completed Migration** (2025-11-07): All major commands successfully migrated to this pattern.

| Command | Original Lines | New Lines | Reduction | Guide Lines |
|---------|---------------|-----------|-----------|-------------|
| `/coordinate` | 2,334 | 1,084 | 54% | 1,250 |
| `/orchestrate` | 5,439 | 557 | 90% | 4,882 |
| `/implement` | 2,076 | 220 | 89% | 921 |
| `/plan` | 1,447 | 229 | 84% | 460 |
| `/debug` | 810 | 202 | 75% | 375 |
| `/document` | 563 | 168 | 70% | 669 |
| `/test` | 200 | 149 | 26% | 666 |

**Key Achievements**:
- ✅ Average 70% reduction in executable file size
- ✅ All files under 250-line target (largest: coordinate at 1,084 lines)
- ✅ Comprehensive guides averaging 1,300 lines of documentation
- ✅ Bidirectional cross-references established
- ✅ Zero meta-confusion loops in testing
- ✅ Pattern validated across command types (orchestration, implementation, testing, documentation)

**Lessons Learned**:
- Large orchestration commands benefit most (54-90% reduction)
- Even "lean" commands (test.md at 200 lines) contained significant documentation (26% reduction)
- Migration checklist ensures consistent quality across commands
- Template-driven approach accelerates new command creation

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

## 4.5 Error Logging Integration

All commands MUST integrate centralized error logging for queryable error tracking and cross-workflow debugging. This enables the `/errors` command to query error history and supports troubleshooting with `/repair`.

### 4.5.1 Required Steps

**Step 1: Source Error Handling Library**

Early in command initialization (after LIB_DIR setup):

```bash
# Source error handling library
source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || {
  echo "Error: Cannot load error-handling library"
  exit 1
}
```

**Step 2: Set Workflow Metadata**

After argument parsing:

```bash
# Set workflow metadata for error context
COMMAND_NAME="/command-name"
WORKFLOW_ID="workflow_$(date +%s)"
USER_ARGS="$*"  # Capture original arguments
```

**Step 3: Initialize Error Log**

Before any error logging calls:

```bash
# Ensure error log exists
ensure_error_log_exists
```

**Step 4: Log Errors at All Error Points**

Use `log_command_error()` at validation, file, and execution error points:

```bash
# Validation errors
if [ -z "$required_arg" ]; then
  log_command_error "validation_error" \
    "Missing required argument: feature_description" \
    "Command usage: /command <arg1> <arg2>"
  exit 1
fi

# File errors
if [ ! -f "$plan_path" ]; then
  log_command_error "file_error" \
    "Plan file not found: $plan_path" \
    "Expected path from workflow initialization"
  exit 1
fi

# Execution errors
if ! some_critical_function; then
  log_command_error "execution_error" \
    "Critical function failed: some_critical_function" \
    "Return code: $?"
  exit 1
fi
```

### 4.5.2 Error Types

Use these standardized error types:

| Error Type | Usage | Example |
|------------|-------|---------|
| `validation_error` | Input validation failures | Missing required argument |
| `file_error` | File system operations failures | File not found, permission denied |
| `state_error` | Workflow state persistence issues | State file corrupted |
| `agent_error` | Subagent execution failures | Agent returned TASK_ERROR |
| `parse_error` | Output parsing failures | Invalid JSON from agent |
| `timeout_error` | Operation timeout errors | Network request timeout |
| `execution_error` | General execution failures | Command failed with non-zero exit |
| `dependency_error` | Missing or invalid dependencies | Required tool not installed |

### 4.5.3 Parsing Subagent Errors

If your command invokes agents, parse their error signals with `parse_subagent_error()`:

```bash
# After subagent execution
agent_output=$(Task { ... })

# Parse agent error signals
if echo "$agent_output" | grep -q "TASK_ERROR:"; then
  parse_subagent_error "$agent_output" "research-specialist"
  exit 1
fi
```

This automatically logs the agent error to the centralized log with full workflow context.

### 4.5.4 Testing Error Logging Integration

After implementing error logging:

```bash
# Test error logging works
/command-name <invalid-args>  # Trigger error intentionally

# Verify error logged
/errors --command /command-name --limit 1

# Check error details
/errors --type validation_error --limit 5
```

### 4.5.5 References

- [Error Handling Pattern](.claude/docs/concepts/patterns/error-handling.md) - Complete pattern documentation
- [Error Handling API Reference](.claude/docs/reference/library-api/error-handling.md) - Function signatures
- [Architecture Standard 17](.claude/docs/reference/architecture/error-handling.md#standard-17-centralized-error-logging-integration) - Requirement specification
- [Errors Command Guide](.claude/docs/guides/commands/errors-command-guide.md) - Query interface

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

### 5.2.1 Avoiding Documentation-Only Patterns

**Problem**: YAML code blocks containing Task invocations that are wrapped in markdown fences without imperative instructions create a 0% agent delegation rate because Claude interprets them as syntax examples rather than executable commands.

**Anti-Pattern Detection**:

Commands must NEVER use this pattern:

```markdown
❌ INCORRECT - Documentation-only pattern:

Example agent invocation:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "Read .claude/agents/research-specialist.md..."
}
```

This will never execute because it's wrapped in a code block.
```

**Correct Pattern - Executable Imperative Invocation**:

```markdown
✅ CORRECT - Imperative execution pattern:

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${RESEARCH_TOPIC}
    - Output Path: ${REPORT_PATH}
    - Project Standards: ${STANDARDS_FILE}

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

#### Pattern Identification

**How to Detect**:

Search for YAML blocks that might be documentation-only:

```bash
# Find all YAML blocks in command files
grep -n '```yaml' .claude/commands/*.md

# For each match, check if it's preceded by imperative instruction within 5 lines
# If no imperative instruction found, it's likely documentation-only
```

**Automated Detection Script**:

```bash
#!/bin/bash
# Detect documentation-only YAML blocks

for file in .claude/commands/*.md; do
  awk '/```yaml/{
    found=0
    for(i=NR-5; i<NR; i++) {
      if(lines[i] ~ /EXECUTE NOW|USE the Task tool|INVOKE AGENT/) found=1
    }
    if(!found) print FILENAME":"NR": Documentation-only YAML block detected"
  } {lines[NR]=$0}' "$file"
done
```

#### Conversion Guide

**Step 1: Identify Documentation-Only Blocks**

Run the detection script to find all YAML blocks without imperative instructions.

**Step 2: Classify Each Block**

For each block found:

1. **If it's a syntax reference** (showing what Task invocations look like):
   - Keep as-is but clearly mark as non-executable example
   - Add comment: "This is a syntax reference only, not an executable invocation"

2. **If it should invoke agents** (part of command workflow):
   - Remove code block wrapper (` ```yaml` and ` ``` `)
   - Add imperative instruction: `**EXECUTE NOW**: USE the Task tool...`
   - Remove "Example" prefix if present

**Step 3: Transform to Executable Pattern**

Before:
```markdown
Example invocation:

```yaml
Task {
  subagent_type: "general-purpose"
  prompt: "Research ${TOPIC}"
}
```
```

After:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC} with mandatory file creation"
  prompt: "
    Read and follow: .claude/agents/research-specialist.md

    Research Topic: ${TOPIC}
    Output Path: ${REPORT_PATH}

    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

**Step 4: Validate Conversion**

Create regression tests to ensure:
- All agent invocations have imperative instructions
- Zero documentation-only YAML blocks remain in executable context
- All invocations reference agent behavioral files
- All invocations require completion signals

#### Prevention

**Review Checklist for New Commands**:

When creating or modifying commands, ensure:

- [ ] No YAML code blocks in agent invocation sections (use imperative pattern instead)
- [ ] All Task invocations have `**EXECUTE NOW**` or similar imperative marker
- [ ] All Task invocations reference `.claude/agents/*.md` behavioral files
- [ ] All Task invocations require explicit completion signals (e.g., `REPORT_CREATED:`)
- [ ] Documentation examples clearly marked as non-executable if using code blocks

**Automated Testing** (add to test suite):

```bash
# Test: No documentation-only YAML blocks in commands
# Expected: Zero matches (all YAML blocks have imperative instructions)

test_no_documentation_only_yaml_blocks() {
  local violations=0

  for cmd_file in .claude/commands/*.md; do
    # Skip documentation section (usually first 100 lines)
    local yaml_blocks=$(tail -n +100 "$cmd_file" | grep -c '```yaml' || true)

    if [ "$yaml_blocks" -gt 0 ]; then
      echo "FAIL: $cmd_file has $yaml_blocks YAML blocks (should be 0)"
      ((violations++))
    fi
  done

  if [ "$violations" -eq 0 ]; then
    echo "PASS: No documentation-only YAML blocks found"
    return 0
  else
    return 1
  fi
}

---

## 8. Block Structure Optimization

### 8.1 Target Block Count

Commands SHOULD use 2-3 bash blocks maximum to minimize display noise in Claude Code:

| Block | Purpose | Operations |
|-------|---------|------------|
| **Setup** | Initialization | Argument capture, library sourcing, validation, state machine init, path allocation |
| **Execute** | Main workflow | Core processing, agent invocations, state transitions |
| **Cleanup** | Completion | Final validation, completion signal, summary output |

### 8.2 Consolidation Pattern

**Before** (6 blocks - excessive):
```markdown
Block 1: mkdir output dir
Block 2: source libraries
Block 3: validate config
Block 4: init state machine
Block 5: allocate workflow ID
Block 6: persist state
```

**After** (2 blocks - optimized):
```bash
# Block 1: Setup
set +H
mkdir -p "$DIR" 2>/dev/null
source "${LIB}/state-machine.sh" 2>/dev/null || exit 1
source "${LIB}/persistence.sh" 2>/dev/null || exit 1
validate_config || exit 1
sm_init "$DESC" "$CMD" "$TYPE" || exit 1
WORKFLOW_ID=$(allocate_workflow_id) || exit 1
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID" || exit 1
echo "Setup complete: $WORKFLOW_ID"
```

### 8.3 Output Suppression

Use output suppression within consolidated blocks:

**Library Sourcing (MANDATORY in Every Bash Block)**:

Each bash block is an independent process and MUST independently source all required libraries:

```bash
# MANDATORY: Source required libraries in EVERY bash block
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Cannot load state-persistence library" >&2
  exit 1
}

source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}

# MANDATORY: Verify critical functions are available after sourcing
if ! command -v load_workflow_state &>/dev/null; then
  echo "ERROR: load_workflow_state function not available after sourcing" >&2
  exit 1
}
```

**Why Mandatory Re-Sourcing?**:
- Bash blocks run in separate processes (subprocess isolation)
- Functions sourced in Block 1 are NOT available in Block 2+
- Each block must independently source its dependencies
- Failure to re-source causes "command not found" errors

**Key Requirements**:
1. Source ALL required libraries at start of EVERY block
2. Use fail-fast pattern (`|| { error; exit 1 }`) instead of error suppression
3. Verify critical function availability after sourcing
4. Never assume functions from previous blocks are available

**Single Summary Line**:
```bash
# After all setup operations
echo "Setup complete: $WORKFLOW_ID"
```

### 8.4 Benefits

- **50-67% reduction** in display noise
- **Faster execution** (fewer subprocess spawns)
- **Cleaner output** (single summary per block)
- **Easier debugging** (logical groupings)

### 8.5 Related Documentation

- [Bash Block Execution Model - Pattern 8](../concepts/bash-block-execution-model.md#pattern-8-block-count-minimization)
- [Output Formatting Standards](../reference/standards/output-formatting.md)
- [Command Authoring Standards](../reference/standards/command-authoring.md#output-suppression-requirements)
