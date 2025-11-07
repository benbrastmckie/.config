# Command Development Guide

**Path**: docs → guides → command-development-guide.md

Comprehensive guide for developing custom slash commands with standards integration, agent coordination, and testing protocols.

For a quick reference of all available commands, see [Command Quick Reference](../reference/command-reference.md).

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

**Executable Template**: `.claude/docs/guides/_template-executable-command.md`
**Guide Template**: `.claude/docs/guides/_template-command-guide.md`

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
```

#### Standards Reference

This pattern is enforced by:
- **Standard 11**: Imperative Agent Invocation Pattern ([Command Architecture Standards](../reference/command_architecture_standards.md#standard-11))
- **Behavioral Injection Pattern**: Anti-Pattern section ([Behavioral Injection](../concepts/patterns/behavioral-injection.md#anti-pattern-documentation-only-yaml-blocks))

#### Code-Fenced Task Invocations Prevent Execution

YAML blocks wrapped in code fences (` ```yaml ... ``` `) cause a 0% agent delegation rate. All agent invocations appear as documentation examples rather than executable instructions, leading to silent failure where commands appear to work but no agents are invoked.

**Symptoms**:
- Agent delegation rate: 0%
- File creation rate: 0%
- Commands complete successfully but produce no artifacts

### 5.2.2 Code Fence Priming Effect

**Problem**: Code-fenced Task invocation examples (` ```yaml ... ``` `) establish a "documentation interpretation" pattern that causes Claude to treat subsequent unwrapped Task blocks as non-executable examples. This results in 0% agent delegation rate even when the actual Task invocations are structurally correct and lack code fences.

**Root Cause**: When Claude encounters a code-fenced Task example early in a command file (e.g., lines 62-79), it establishes a mental model that "Task blocks are documentation examples". This interpretation persists and applies to later Task invocations, preventing execution even when they are not code-fenced.

**Detection**:

```bash
# Check for code-fenced Task examples that could cause priming effect
grep -n '```yaml' .claude/commands/*.md | while read match; do
  file=$(echo "$match" | cut -d: -f1)
  line=$(echo "$match" | cut -d: -f2)

  # Check if Task invocation follows
  sed -n "$((line+1)),$((line+15))p" "$file" | grep -q "Task {" && \
    echo "Potential priming effect: $file:$line"
done
```

**Fix Pattern**:

1. **Remove code fences from Task examples**: Convert ` ```yaml ... ``` ` to unwrapped blocks
2. **Add HTML comments for clarity**: Use `<!-- This Task invocation is executable -->` above unwrapped examples (invisible to Claude)
3. **Keep anti-pattern examples fenced**: Examples marked with ❌ should remain code-fenced to prevent accidental execution
4. **Verify tool access**: Ensure agents have required tools (especially Bash) in allowed-tools frontmatter

**Before (Causes Priming Effect)**:

```markdown
**Example Pattern**:
```yaml
# ✅ CORRECT - Task invocation example
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "..."
}
```

Later in file...

**EXECUTE NOW**: Invoke research agent.

Task {
  subagent_type: "general-purpose"
  description: "Research authentication"
  prompt: "..."
}

Result: 0% delegation (priming effect from first code-fenced example)
```

**After (No Priming Effect)**:

```markdown
**Example Pattern**:

<!-- This Task invocation is executable -->
# ✅ CORRECT - Task invocation example
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "..."
}

Later in file...

**EXECUTE NOW**: Invoke research agent.

Task {
  subagent_type: "general-purpose"
  description: "Research authentication"
  prompt: "..."
}

Result: 100% delegation (no code fences, no priming effect)
```

**Detection Symptoms**:

A single code-fenced Task example early in a command file causes 0% agent delegation rate for all subsequent Task invocations, even when those invocations are structurally correct and lack code fences. The early code-fenced example establishes an interpretation pattern that prevents all later execution.

**Observable Effects**:
- Delegation rate: 0% (all Task invocations treated as documentation)
- Context usage: >80% (metadata extraction disabled)
- Streaming fallback errors: Present
- Parallel agent execution: 0 agents invoked

**Prevention Guidelines**:
- Never wrap executable Task invocations in code fences
- Use HTML comments for annotations (invisible to Claude)
- Move complex examples to external reference files (e.g., `.claude/docs/patterns/`)
- Test delegation rate after adding Task examples
- Ensure agents have Bash in allowed-tools for proper initialization

See also:
- [Behavioral Injection - Code Fence Priming Effect](../concepts/patterns/behavioral-injection.md#anti-pattern-code-fenced-task-examples-create-priming-effect)
- [Test Suite](../../tests/test_supervise_agent_delegation.sh) for validation

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

See [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) for complete invocation templates and examples.

---

## 5.5. Using Utility Libraries

### When to Use Libraries vs Agents

Commands should prefer utility libraries over agent invocation when:

**Deterministic Operations** (No AI reasoning needed):
- Location detection from user input
- Topic name sanitization
- Directory structure creation
- Plan file parsing
- Metadata extraction from structured files

**Performance Critical Paths**:
- Workflow initialization
- Checkpoint save/load operations
- Log file writes
- JSON/YAML parsing

**Context Window Optimization**:
- Libraries use 0 tokens (pure bash)
- Agents use 15k-75k tokens per invocation
- Example: `unified-location-detection.sh` saves 65k tokens vs `location-specialist` agent

### Common Library Usage Pattern

```bash
#!/usr/bin/env bash

# Get Claude config directory
CLAUDE_CONFIG="${CLAUDE_CONFIG:-${HOME}/.config}"

# Source the library
source "${CLAUDE_CONFIG}/.claude/lib/unified-location-detection.sh"

# Call library function
LOCATION_JSON=$(perform_location_detection "$USER_INPUT")

# Extract results (with jq fallback)
if command -v jq &>/dev/null; then
  TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
  REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
else
  # Fallback without jq
  TOPIC_PATH=$(echo "$LOCATION_JSON" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  REPORTS_DIR=$(echo "$LOCATION_JSON" | grep -o '"reports": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
fi

# MANDATORY VERIFICATION checkpoint
if [ ! -d "$TOPIC_PATH" ]; then
  echo "ERROR: Location detection failed - directory not created"
  exit 1
fi
```

### Available Libraries

**Core Utilities**:
- `unified-location-detection.sh` - Standardized location detection (<1s, 0 tokens vs 25s, 75k tokens for agent)
- `plan-core-bundle.sh` - Plan parsing and manipulation
- `metadata-extraction.sh` - Report/plan metadata extraction (99% context reduction)
- `checkpoint-utils.sh` - Checkpoint state management

**Agent Support**:
- `agent-registry-utils.sh` - Agent registration and discovery
- `hierarchical-agent-support.sh` - Multi-level agent coordination

**Workflow Support**:
- `unified-logger.sh` - Structured logging with rotation
- `error-handling.sh` - Standardized error handling
- `context-pruning.sh` - Context window optimization

See [Library API Reference](../reference/library-api.md) for complete function signatures and [Using Utility Libraries](using-utility-libraries.md) for detailed patterns and examples.

### Library Sourcing Patterns

Commands should choose the appropriate sourcing pattern based on their needs:

#### Pattern 1: Orchestration Commands (Core + Workflow Libraries)

Use `library-sourcing.sh` for orchestration commands that need core libraries plus optional workflow utilities:

```bash
#!/usr/bin/env bash
# Source library-sourcing.sh for automatic core library loading
source "$(dirname "${BASH_SOURCE[0]}")/../lib/library-sourcing.sh"

# Load core libraries (7) + additional workflow libraries
# Automatic deduplication prevents re-sourcing duplicates
source_required_libraries "dependency-analyzer.sh" "complexity-utils.sh" || exit 1

# All libraries now available:
# - Core: error-handling, checkpoint-utils, unified-logger, etc.
# - Workflow: dependency-analyzer, complexity-utils
```

**Benefits:**
- Automatic loading of 7 core libraries (error-handling, checkpoint-utils, unified-logger, unified-location-detection, metadata-extraction, context-pruning, workflow-detection)
- Deduplication prevents re-sourcing if library names appear in both core and parameter list
- Consistent library set across all orchestration commands
- Single function call instead of multiple source statements

**When to use:**
- Orchestration commands: `/orchestrate`, `/coordinate`, `/implement`, `/supervise`
- Commands requiring workflow utilities (checkpoints, complexity analysis, parallel execution)
- Commands that need the standard orchestration infrastructure

#### Pattern 2: Specialized Commands (Direct Sourcing)

Use direct sourcing for specialized commands with narrow library needs:

```bash
#!/usr/bin/env bash
# Source only the specific libraries needed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/../lib/convert-core.sh"
source "${SCRIPT_DIR}/../lib/conversion-logger.sh"

# Call specialized conversion functions
convert_file "$INPUT" "$OUTPUT"
```

**Benefits:**
- Avoids loading unnecessary core libraries
- Faster startup (fewer files sourced)
- Clear dependencies (explicitly lists what's needed)
- Appropriate for single-purpose commands

**When to use:**
- Document conversion commands
- Analysis commands
- Template-based commands
- Any command with 1-3 specific library dependencies

#### Pattern 3: Simple Commands (No Libraries)

Simple commands may not need any libraries:

```bash
#!/usr/bin/env bash
# No library dependencies - direct implementation

echo "Simple command executing..."
# Direct implementation without utility functions
```

**When to use:**
- Commands with trivial logic
- Commands that only invoke other commands/tools
- Commands where utilities would add unnecessary complexity

#### Deduplication Behavior

The `source_required_libraries()` function automatically deduplicates library names to prevent re-sourcing:

```bash
# Example: Duplicate library names
source_required_libraries \
  "dependency-analyzer.sh" \       # NEW (only this sourced)
  "checkpoint-utils.sh" \          # Already in core 7 (skipped)
  "error-handling.sh" \            # Already in core 7 (skipped)
  "metadata-extraction.sh"         # Already in core 7 (skipped)

# Debug output shows:
# DEBUG: Library deduplication: 11 input libraries -> 8 unique libraries (3 duplicates removed)
```

**How it works:**
- Combines core 7 libraries + your additional parameters into single array
- Removes duplicates using O(n²) string matching (acceptable for n≈10 libraries)
- Preserves first occurrence order for unique libraries
- Sources each unique library exactly once

**Performance:**
- Overhead: <0.01ms (negligible)
- Prevents duplicate sourcing that caused /coordinate timeout (>120s → <90s)
- 93% less code than memoization alternative (20 lines vs 310 lines)

#### Artifact Management Libraries

Artifact operations are split across two focused libraries:

```bash
# Artifact file creation and directory management
source .claude/lib/artifact-creation.sh

# Artifact tracking, querying, and validation
source .claude/lib/artifact-registry.sh
```

See [Library Classification](../../lib/README.md#library-classification) for complete details on available functions.

### 5.6 Path Calculation Best Practices

**CRITICAL**: Calculate paths in parent command scope, NOT in agent prompts.

#### Why This Matters

The Bash tool used by AI agents escapes command substitution `$(...)` for security purposes. This breaks path calculation that relies on sourcing libraries and capturing function output.

**Error Example**:
```bash
# This WILL FAIL in agent prompt:
LOCATION_JSON=$(perform_location_detection "$TOPIC" "false")

# Error: syntax error near unexpected token 'perform_location_detection'
```

#### Recommended Pattern

**Parent Command Responsibilities:**
1. Source libraries
2. Calculate all paths
3. Create directories
4. Pass absolute paths to agents

**Agent Responsibilities:**
1. Receive absolute paths
2. Execute tasks
3. NO path calculation

#### Correct Implementation

```bash
# ✓ CORRECT: Parent command calculates paths
source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/unified-location-detection.sh"
LOCATION_JSON=$(perform_location_detection "$TOPIC" "false")

# Extract all needed paths
TOPIC_DIR=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')

# Pre-calculate artifact path
REPORT_PATH="${REPORTS_DIR}/001_${SANITIZED_TOPIC}.md"
mkdir -p "$(dirname "$REPORT_PATH")"

# Pass absolute path to agent (no calculation needed)
Task {
  subagent_type: "general-purpose"
  prompt: "
    **Report Path**: $REPORT_PATH

    Create report at the exact path above.
  "
}
```

```bash
# ✗ WRONG: Attempting calculation in agent prompt
Task {
  prompt: "
    # This will fail due to bash escaping:
    REPORT_PATH=$(calculate_path '$TOPIC')
  "
}
```

#### Working vs Broken Bash Constructs

**Working in Agent Context:**
- Arithmetic: `VAR=$((expr))` ✓
- Sequential: `cmd1 && cmd2` ✓
- Pipes: `cmd1 | cmd2` ✓
- Sourcing: `source file.sh` ✓
- Conditionals: `[[ test ]] && action` ✓

**Broken in Agent Context:**
- Command substitution: `VAR=$(command)` ✗
- Backticks: `` VAR=`command` `` ✗

#### Performance Benefits

This pattern maintains optimal performance:
- Token usage: <11k per detection (85% reduction)
- Execution time: <1s for path calculation
- Reliability: 100% (no escaping issues)

**See also**: [Bash Tool Limitations](../troubleshooting/bash-tool-limitations.md) for detailed explanation and more examples.

---

## 6. State Management Patterns

### 6.1 Introduction - Why State Management Matters

Multi-block commands in Claude Code face a fundamental architectural constraint: **bash blocks execute in separate subprocesses**. This means variable exports and environment changes don't persist between blocks.

#### The Subprocess Isolation Constraint

When Claude executes bash code blocks via the Bash tool, each block runs in a completely separate subprocess, not a subshell. This architectural decision (GitHub issues #334, #2508) has critical implications:

```bash
# Block 1
export WORKFLOW_SCOPE="research-only"
export PHASES="1 2 3"

# Block 2 (separate subprocess - exports are gone!)
echo "$WORKFLOW_SCOPE"  # Empty!
echo "$PHASES"          # Empty!
```

**Why this matters**:
- Orchestration commands often span 5-7 bash blocks (one per phase)
- Variables like `WORKFLOW_SCOPE`, `PHASES_TO_EXECUTE`, `CLAUDE_PROJECT_DIR` needed across blocks
- Traditional shell programming patterns (export, source, eval) don't work
- State management becomes an explicit design decision

#### Available Patterns Overview

This guide documents 4 proven state management patterns, each optimized for different scenarios:

1. **Pattern 1: Stateless Recalculation** - Recalculate variables in every block (<1ms overhead)
2. **Pattern 2: Checkpoint Files** - Serialize state to `.claude/data/checkpoints/` for resumability
3. **Pattern 3: File-based State** - Cache expensive computation results (>1s operations)
4. **Pattern 4: Single Large Block** - Avoid state management by keeping all logic in one block

Each pattern has clear trade-offs in performance, complexity, and reliability. The decision framework in section 6.3 guides pattern selection based on command requirements.

---

### 6.2 Pattern Catalog

#### 6.2.1 Pattern 1: Stateless Recalculation

**Core Concept**: Every bash block recalculates all variables it needs from scratch. No reliance on previous blocks for state persistence.

**When to Use**:
- Multi-block orchestration commands
- <10 variables requiring persistence
- Recalculation cost <100ms per block
- Single-invocation workflows (no resumability needed)
- Commands invoking subagents via Task tool

**Pattern Definition**:

Stateless recalculation embraces subprocess isolation rather than fighting it. Variables are deterministically recomputed in every bash block using the same input data (`$WORKFLOW_DESCRIPTION`, command arguments, file contents).

**Key Principle**: Accept code duplication as an intentional trade-off for simplicity and reliability.

**Implementation Example** (from /coordinate):

```bash
# Block 1 - Phase 0 Initialization
# Standard 13: CLAUDE_PROJECT_DIR detection
CLAUDE_PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)

# Detect workflow scope
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

# Calculate phases to execute
case "$WORKFLOW_SCOPE" in
  "research-only")
    PHASES_TO_EXECUTE="1"
    ;;
  "research-and-plan")
    PHASES_TO_EXECUTE="1 2"
    ;;
  "full-implementation")
    PHASES_TO_EXECUTE="1 2 3 4 5 6"
    ;;
  "debug-only")
    PHASES_TO_EXECUTE="4"
    ;;
  *)
    echo "ERROR: Unknown workflow scope: $WORKFLOW_SCOPE"
    exit 1
    ;;
esac

# Defensive validation
if [ -z "$PHASES_TO_EXECUTE" ]; then
  echo "ERROR: PHASES_TO_EXECUTE not set (WORKFLOW_SCOPE=$WORKFLOW_SCOPE)"
  exit 1
fi
```

```bash
# Block 2 - Phase 1 Research (different subprocess)
# MUST recalculate everything - exports from Block 1 didn't persist

# Recalculate CLAUDE_PROJECT_DIR (same logic as Block 1)
CLAUDE_PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)

# Recalculate workflow scope (same function call as Block 1)
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

# Recalculate phases to execute (same case statement as Block 1)
case "$WORKFLOW_SCOPE" in
  "research-only")
    PHASES_TO_EXECUTE="1"
    ;;
  "research-and-plan")
    PHASES_TO_EXECUTE="1 2"
    ;;
  "full-implementation")
    PHASES_TO_EXECUTE="1 2 3 4 5 6"
    ;;
  "debug-only")
    PHASES_TO_EXECUTE="4"
    ;;
  *)
    echo "ERROR: Unknown workflow scope: $WORKFLOW_SCOPE"
    exit 1
    ;;
esac

# Defensive validation (repeated for reliability)
if [ -z "$PHASES_TO_EXECUTE" ]; then
  echo "ERROR: PHASES_TO_EXECUTE not set (WORKFLOW_SCOPE=$WORKFLOW_SCOPE)"
  exit 1
fi

# Now use PHASES_TO_EXECUTE to determine if Phase 1 should execute
if echo "$PHASES_TO_EXECUTE" | grep -q "1"; then
  # Execute Phase 1 research logic
  echo "Executing Phase 1: Research"
fi
```

**Code Duplication Strategy**:

Notice the CLAUDE_PROJECT_DIR detection, WORKFLOW_SCOPE calculation, and PHASES_TO_EXECUTE mapping are **identical** across blocks. This is intentional:

- **Overhead**: <1ms per variable recalculation
- **Total overhead**: 6 blocks × 3 variables × <1ms = <20ms
- **Alternative** (file-based state): 30ms I/O × 6 blocks = 180ms (9x slower!)
- **Benefit**: Zero I/O operations, deterministic, no synchronization issues

**Library Extraction Strategy**:

For complex calculations (>20 lines), extract to shared library function:

```bash
# .claude/lib/workflow-scope-detection.sh
detect_workflow_scope() {
  local workflow_description="$1"
  local scope=""

  if echo "$workflow_description" | grep -qiE 'research.*\(report|investigate|analyze'; then
    if echo "$workflow_description" | grep -qiE '\(plan|implement|design\)'; then
      scope="full-implementation"
    elif echo "$workflow_description" | grep -qiE 'create.*plan'; then
      scope="research-and-plan"
    else
      scope="research-only"
    fi
  elif echo "$workflow_description" | grep -qiE '\(debug|fix|troubleshoot\)'; then
    scope="debug-only"
  else
    scope="full-implementation"
  fi

  echo "$scope"
}

export -f detect_workflow_scope
```

Then every block sources the library and calls the function:

```bash
# Every block
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
```

**Trade-off Analysis**:

| Aspect | Advantage | Disadvantage |
|--------|-----------|--------------|
| **Performance** | <1ms overhead per variable | 50-80 lines code duplication |
| **Complexity** | Low (straightforward recalculation) | Synchronization burden (multiple copies) |
| **Reliability** | Deterministic (no I/O failures) | Manual updates required across blocks |
| **Maintainability** | No cleanup logic needed | Changes require multi-location updates |
| **I/O Operations** | None (pure computation) | N/A |
| **State Capacity** | Limited to fast-to-compute variables | Cannot handle expensive operations |

**Performance Characteristics**:

- **Per-variable overhead**: <1ms (measured for /coordinate)
- **Memory usage**: Negligible (variables recreated each block)
- **I/O operations**: Zero (pure computation)
- **Benchmark**: /coordinate with 6 blocks, 10 variables → <20ms total overhead
- **Scalability**: Linear (O(blocks × variables))

**Example Commands Using This Pattern**:

- `/coordinate` - Primary example (6 blocks, 10+ variables, <20ms overhead)
- `/orchestrate` - Similar multi-block workflow coordination
- Custom orchestration commands requiring subagent invocation

**Advantages**:

- ✓ **Simplicity**: No files to manage, no cleanup logic, straightforward mental model
- ✓ **Reliability**: Deterministic behavior, no cache staleness, no I/O failures
- ✓ **Performance**: <1ms per variable beats file I/O (30ms) for simple calculations
- ✓ **Debugging**: Self-contained blocks, no state synchronization issues
- ✓ **Testability**: Each block independently testable

**Disadvantages**:

- ✗ **Code Duplication**: 50-80 lines duplicated across blocks
- ✗ **Synchronization Burden**: Changes require updates across multiple blocks
- ✗ **Limited Applicability**: Cannot handle expensive computation (>100ms recalculation)
- ✗ **No Resumability**: State lost on process termination

**When NOT to Use**:

- Computation cost >100ms per block (consider Pattern 3: File-based State)
- Need resumability after interruptions (use Pattern 2: Checkpoint Files)
- >20 variables requiring persistence (complexity threshold)
- Resumable multi-phase workflows (use Pattern 2)

**Defensive Validation Pattern**:

Always validate critical variables after recalculation:

```bash
# Recalculate
PHASES_TO_EXECUTE=$(calculate_phases "$WORKFLOW_SCOPE")

# Defensive validation
if [ -z "$PHASES_TO_EXECUTE" ]; then
  echo "ERROR: PHASES_TO_EXECUTE not set (WORKFLOW_SCOPE=$WORKFLOW_SCOPE)"
  echo "DEBUG: Input was: $WORKFLOW_DESCRIPTION"
  exit 1
fi
```

**Mitigation for Code Duplication**:

1. **Extract to Library**: Functions >20 lines go to `.claude/lib/*.sh`
2. **Automated Testing**: Synchronization validation tests (see section 6.6)
3. **Comments**: Mark synchronization points with warnings
4. **Documentation**: Architecture docs explain duplication rationale

**See Also**:
- [Coordinate State Management Architecture](../architecture/coordinate-state-management.md) - Technical deep-dive
- Case Study 1: /coordinate Success Story (section 6.5)
- Anti-Pattern 2: Premature Optimization (section 6.4)

---

#### 6.2.2 Pattern 2: Checkpoint Files

**Core Concept**: Multi-phase workflows persist state to `.claude/data/checkpoints/` directory for resumability after interruptions.

**When to Use**:
- Multi-phase implementation workflows (>5 phases)
- Commands requiring >10 minutes execution time
- Workflows that may be interrupted (network failures, manual stops)
- Commands needing audit trail (checkpoint history)
- Resumable operations (restart from phase N)

**Pattern Definition**:

Checkpoint files serialize workflow state to JSON at phase boundaries, enabling full state restoration after process termination or interruption.

**Implementation Example** (from /implement):

```bash
# Source checkpoint utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/checkpoint-utils.sh"

# After Phase 1 completion
CHECKPOINT_DATA=$(cat <<EOF
{
  "command": "implement",
  "plan_path": "$PLAN_PATH",
  "current_phase": 1,
  "completed_phases": [1],
  "tests_passing": true,
  "files_modified": ["file1.lua", "file2.lua"],
  "git_commits": ["a3f8c2e"],
  "timestamp": "$(date -Iseconds)"
}
EOF
)

save_checkpoint "implement_${PROJECT_NAME}" "$CHECKPOINT_DATA"
echo "Checkpoint saved: Phase 1 complete"

# After Phase 2 completion
CHECKPOINT_DATA=$(cat <<EOF
{
  "command": "implement",
  "plan_path": "$PLAN_PATH",
  "current_phase": 2,
  "completed_phases": [1, 2],
  "tests_passing": true,
  "files_modified": ["file1.lua", "file2.lua", "file3.lua"],
  "git_commits": ["a3f8c2e", "b7d4e1f"],
  "timestamp": "$(date -Iseconds)"
}
EOF
)

save_checkpoint "implement_${PROJECT_NAME}" "$CHECKPOINT_DATA"
```

```bash
# Later invocation (after interruption) - restore state
CHECKPOINT_FILE=".claude/data/checkpoints/implement_${PROJECT_NAME}_latest.json"

if [ -f "$CHECKPOINT_FILE" ]; then
  echo "Found checkpoint - resuming workflow"

  # Restore state from checkpoint
  PLAN_PATH=$(jq -r '.plan_path' "$CHECKPOINT_FILE")
  CURRENT_PHASE=$(jq -r '.current_phase' "$CHECKPOINT_FILE")
  COMPLETED_PHASES=$(jq -r '.completed_phases[]' "$CHECKPOINT_FILE" | tr '\n' ' ')
  TESTS_PASSING=$(jq -r '.tests_passing' "$CHECKPOINT_FILE")

  # Calculate next phase to execute
  START_PHASE=$((CURRENT_PHASE + 1))

  echo "Resuming from Phase $START_PHASE"
  echo "Completed phases: $COMPLETED_PHASES"
  echo "Tests passing: $TESTS_PASSING"
else
  echo "No checkpoint found - starting from Phase 1"
  START_PHASE=1
fi
```

**Checkpoint File Structure**:

```
.claude/data/checkpoints/
├── implement_myproject_latest.json         # Current state
├── implement_myproject_001.json            # Historical checkpoint 1
├── implement_myproject_002.json            # Historical checkpoint 2
└── implement_myproject_003.json            # Historical checkpoint 3
```

**Checkpoint JSON Schema**:

```json
{
  "command": "implement",
  "plan_path": "/absolute/path/to/plan.md",
  "current_phase": 2,
  "completed_phases": [1, 2],
  "tests_passing": true,
  "files_modified": ["file1.lua", "file2.lua", "file3.lua"],
  "git_commits": ["a3f8c2e", "b7d4e1f"],
  "timestamp": "2025-11-05T15:23:45-05:00",
  "metadata": {
    "plan_complexity": 7.5,
    "total_phases": 5,
    "replan_count": 0
  }
}
```

**Checkpoint Lifecycle**:

1. **Creation**: After each phase completes successfully
2. **Update**: `_latest.json` always contains most recent state
3. **Rotation**: Historical checkpoints saved as `_NNN.json` (configurable retention)
4. **Restoration**: Read `_latest.json` on workflow restart
5. **Cleanup**: Delete checkpoints on successful workflow completion (optional)

**Trade-off Analysis**:

| Aspect | Advantage | Disadvantage |
|--------|-----------|--------------|
| **Resumability** | Full state restoration after interruption | 50-100ms I/O overhead per checkpoint |
| **Complexity** | Medium (checkpoint-utils.sh library) | Cleanup logic required |
| **Reliability** | Survives process termination | File I/O can fail (disk full, permissions) |
| **State Capacity** | Any size (JSON serialization) | Synchronization between checkpoint and reality |
| **Audit Trail** | Complete workflow history | Storage overhead (50-200KB per checkpoint) |
| **I/O Operations** | 2 per checkpoint (read + write) | N/A |

**Performance Characteristics**:

- **Checkpoint save**: 30-50ms (JSON serialization + file write)
- **Checkpoint load**: 20-30ms (file read + JSON parsing)
- **Total overhead**: 50-100ms per checkpoint
- **Acceptable for**: Hour-long workflows (0.1% overhead)
- **Not acceptable for**: Sub-minute workflows (10%+ overhead)

**Checkpoint Utilities Library**:

The `.claude/lib/checkpoint-utils.sh` library provides:

```bash
# Save checkpoint with automatic rotation
save_checkpoint() {
  local checkpoint_name="$1"
  local checkpoint_data="$2"
  local checkpoint_dir=".claude/data/checkpoints"

  mkdir -p "$checkpoint_dir"

  # Save as latest
  echo "$checkpoint_data" > "${checkpoint_dir}/${checkpoint_name}_latest.json"

  # Rotate to historical (optional)
  local count=$(ls "${checkpoint_dir}/${checkpoint_name}_"*.json 2>/dev/null | wc -l)
  cp "${checkpoint_dir}/${checkpoint_name}_latest.json" \
     "${checkpoint_dir}/${checkpoint_name}_$(printf '%03d' $count).json"
}

# Load most recent checkpoint
load_checkpoint() {
  local checkpoint_name="$1"
  local checkpoint_file=".claude/data/checkpoints/${checkpoint_name}_latest.json"

  if [ -f "$checkpoint_file" ]; then
    cat "$checkpoint_file"
    return 0
  else
    return 1
  fi
}

# Clean up checkpoints on successful completion
cleanup_checkpoints() {
  local checkpoint_name="$1"
  local checkpoint_dir=".claude/data/checkpoints"

  rm -f "${checkpoint_dir}/${checkpoint_name}"_*.json
  echo "Checkpoints cleaned up for: $checkpoint_name"
}
```

**Cleanup Considerations**:

**Retention Policy Options**:

1. **Keep Latest Only**: Delete historical checkpoints after each save
2. **Keep N Historical**: Retain last N checkpoints (e.g., N=5)
3. **Keep All Until Completion**: Delete all checkpoints only when workflow succeeds
4. **Keep Indefinitely**: Never delete (for audit trail)

**Recommended Policy** (for `/implement`):

```bash
# Keep latest + 3 historical checkpoints
CHECKPOINT_RETENTION=3

save_checkpoint_with_rotation() {
  local name="$1"
  local data="$2"
  local dir=".claude/data/checkpoints"

  # Save latest
  echo "$data" > "${dir}/${name}_latest.json"

  # Count existing historical checkpoints
  local count=$(ls "${dir}/${name}_"[0-9]*.json 2>/dev/null | wc -l)

  # Save new historical checkpoint
  cp "${dir}/${name}_latest.json" "${dir}/${name}_$(printf '%03d' $((count + 1))).json"

  # Clean old checkpoints if exceeds retention limit
  if [ $count -ge $CHECKPOINT_RETENTION ]; then
    ls -t "${dir}/${name}_"[0-9]*.json | tail -n +$((CHECKPOINT_RETENTION + 1)) | xargs rm -f
  fi
}
```

**Cleanup on Success**:

```bash
# After all phases complete successfully
cleanup_checkpoints "implement_${PROJECT_NAME}"
echo "Implementation complete - checkpoints cleaned up"
```

**Synchronization Validation**:

Critical: Checkpoint must accurately reflect reality.

```bash
# After phase completion
run_tests
TEST_STATUS=$?

if [ $TEST_STATUS -eq 0 ]; then
  TESTS_PASSING=true

  # Create git commit
  git add .
  git commit -m "feat: complete Phase $PHASE_NUMBER"
  COMMIT_HASH=$(git rev-parse HEAD)

  # Save checkpoint AFTER commit succeeds
  save_checkpoint "implement_${PROJECT_NAME}" "$(cat <<EOF
{
  "current_phase": $PHASE_NUMBER,
  "tests_passing": true,
  "git_commits": ["$COMMIT_HASH"]
}
EOF
  )"
else
  echo "ERROR: Tests failed - NOT saving checkpoint"
  exit 1
fi
```

**Example Commands Using This Pattern**:

- `/implement` - Primary example (multi-phase implementation with resumability)
- `/revise --auto-mode` - Iterative plan revision with checkpoints
- Long-running orchestration workflows (>10 minutes)

**Advantages**:

- ✓ **Resumability**: Full workflow restoration after any interruption
- ✓ **Audit Trail**: Complete history of workflow progression
- ✓ **State Capacity**: Unlimited (JSON can hold any data structure)
- ✓ **Flexibility**: Schema can evolve without breaking existing checkpoints

**Disadvantages**:

- ✗ **I/O Overhead**: 50-100ms per checkpoint (significant for fast workflows)
- ✗ **Complexity**: Requires checkpoint library, cleanup logic, rotation policy
- ✗ **Synchronization Risk**: Checkpoint may not reflect actual file system state
- ✗ **Failure Modes**: Disk full, permissions errors, JSON parsing failures

**When NOT to Use**:

- Single-invocation workflows (<10 minutes) - overhead not justified
- Simple commands (<5 phases) - resumability not needed
- Fast workflows (<1 minute) - overhead >10% of execution time

**See Also**:
- [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md) - Detailed implementation
- `.claude/lib/checkpoint-utils.sh` - Checkpoint utilities library
- Case Study 2: /implement Success Story (section 6.5)

---

#### 6.2.3 Pattern 3: File-based State

**Core Concept**: Heavy computation results cached to files to avoid re-execution on subsequent invocations.

**When to Use**:
- Computation cost >1 second per invocation
- Results reused across multiple command invocations
- Caching justifies 30ms I/O overhead
- Cache invalidation logic manageable

**Pattern Definition**:

File-based state caches expensive computation results (codebase analysis, dependency graphs, large dataset preprocessing) to files, avoiding re-computation on subsequent command invocations.

**Difference from Pattern 2**:
- Pattern 2 (Checkpoints): Intra-workflow state for resumability
- Pattern 3 (File-based): Inter-invocation caching for performance

**Implementation Example**:

```bash
# Expensive codebase analysis (5+ seconds)
ANALYSIS_CACHE=".claude/cache/codebase_analysis_${PROJECT_HASH}.json"

if [ -f "$ANALYSIS_CACHE" ]; then
  # Check cache freshness (modified in last 24 hours?)
  if [ "$(uname)" = "Darwin" ]; then
    CACHE_AGE=$(( $(date +%s) - $(stat -f%m "$ANALYSIS_CACHE") ))
  else
    CACHE_AGE=$(( $(date +%s) - $(stat -c%Y "$ANALYSIS_CACHE") ))
  fi

  if [ $CACHE_AGE -lt 86400 ]; then
    # Cache is fresh - use it
    ANALYSIS_RESULT=$(cat "$ANALYSIS_CACHE")
    echo "Using cached analysis (age: ${CACHE_AGE}s)"
  else
    # Cache is stale - regenerate
    echo "Cache expired (age: ${CACHE_AGE}s) - regenerating analysis..."
    ANALYSIS_RESULT=$(perform_expensive_analysis)
    echo "$ANALYSIS_RESULT" > "$ANALYSIS_CACHE"
  fi
else
  # No cache - compute and save
  echo "No cache found - running expensive analysis (5-10s)..."
  ANALYSIS_RESULT=$(perform_expensive_analysis)
  echo "$ANALYSIS_RESULT" > "$ANALYSIS_CACHE"
fi

# Use ANALYSIS_RESULT in command logic
echo "Analysis complete: $(echo "$ANALYSIS_RESULT" | jq -r '.summary')"
```

**Cache Invalidation Strategies**:

**1. Time-based Invalidation**:

```bash
# Cache expires after 24 hours
MAX_CACHE_AGE=86400  # seconds

if [ -f "$CACHE_FILE" ]; then
  CACHE_AGE=$(( $(date +%s) - $(stat -c%Y "$CACHE_FILE" 2>/dev/null || stat -f%m "$CACHE_FILE") ))

  if [ $CACHE_AGE -gt $MAX_CACHE_AGE ]; then
    echo "Cache expired - regenerating"
    rm "$CACHE_FILE"
  fi
fi
```

**2. Content-based Invalidation**:

```bash
# Cache invalidated when input files change
INPUT_FILES=("file1.lua" "file2.lua" "file3.lua")
INPUT_HASH=$(cat "${INPUT_FILES[@]}" | md5sum | cut -d' ' -f1)

CACHE_FILE=".claude/cache/analysis_${INPUT_HASH}.json"

if [ ! -f "$CACHE_FILE" ]; then
  echo "Input files changed - cache invalidated"
  RESULT=$(expensive_analysis "${INPUT_FILES[@]}")
  echo "$RESULT" > "$CACHE_FILE"
fi
```

**3. Manual Invalidation**:

```bash
# User flag to bypass cache
if [ "$NO_CACHE" = "true" ]; then
  echo "Cache bypass requested - running fresh analysis"
  RESULT=$(expensive_analysis)
else
  # Use cache if available
  if [ -f "$CACHE_FILE" ]; then
    RESULT=$(cat "$CACHE_FILE")
  else
    RESULT=$(expensive_analysis)
    echo "$RESULT" > "$CACHE_FILE"
  fi
fi
```

**4. Automatic File Modification Detection**:

```bash
# Invalidate cache if any source file modified since cache created
if [ -f "$CACHE_FILE" ]; then
  # Find newest source file
  NEWEST_SOURCE=$(find . -name "*.lua" -type f -exec stat -f%m {} \; | sort -rn | head -1)
  CACHE_MTIME=$(stat -f%m "$CACHE_FILE")

  if [ $NEWEST_SOURCE -gt $CACHE_MTIME ]; then
    echo "Source files modified - cache invalidated"
    rm "$CACHE_FILE"
  fi
fi
```

**Trade-off Analysis**:

| Aspect | Advantage | Disadvantage |
|--------|-----------|--------------|
| **Performance** | Avoid 1s+ re-computation | 30ms I/O overhead per cache access |
| **Complexity** | High (cache invalidation logic) | Staleness detection required |
| **Reliability** | Reduces computation load | Cache/reality synchronization issues |
| **Maintainability** | Cleanup logic required | Multiple failure modes (I/O, staleness) |
| **Storage** | Persistent across invocations | Disk space consumption |
| **I/O Operations** | 1 read per cache hit | Disk full errors possible |

**Performance Characteristics**:

- **Cache save**: 20-30ms (JSON serialization + file write)
- **Cache load**: 10-20ms (file read + JSON parsing)
- **Total overhead**: 30ms per cache operation
- **Break-even point**: Computation must cost >30ms to justify caching
- **Recommended threshold**: >1s computation (30x overhead amortization)

**Cache Directory Structure**:

```
.claude/cache/
├── codebase_analysis_abc123.json          # Analysis for project hash abc123
├── codebase_analysis_def456.json          # Analysis for project hash def456
├── dependency_graph_abc123.json           # Dependency graph cache
└── metadata.json                          # Cache metadata (creation times, sizes)
```

**Cleanup Considerations**:

**Cache Size Management**:

```bash
# Limit cache directory size to 100MB
MAX_CACHE_SIZE=$((100 * 1024 * 1024))  # bytes

cleanup_old_caches() {
  local cache_dir=".claude/cache"
  local current_size=$(du -sb "$cache_dir" 2>/dev/null | cut -f1)

  if [ $current_size -gt $MAX_CACHE_SIZE ]; then
    echo "Cache size ($current_size bytes) exceeds limit ($MAX_CACHE_SIZE bytes)"
    echo "Cleaning oldest cache files..."

    # Delete oldest files until under limit
    ls -t "$cache_dir"/*.json | tail -n +10 | xargs rm -f
  fi
}
```

**Automatic Cleanup on Command Exit**:

```bash
# Optional: Clean up caches older than 7 days on command exit
trap 'cleanup_stale_caches' EXIT

cleanup_stale_caches() {
  find .claude/cache -name "*.json" -mtime +7 -delete
  echo "Cleaned up caches older than 7 days"
}
```

**Example Use Cases**:

- **Codebase Complexity Analysis**: Parse all source files, calculate metrics (5-10s)
- **Dependency Graph Generation**: Traverse all imports/requires (3-5s)
- **Documentation Parsing**: Extract API signatures from all files (2-4s)
- **Cross-Repository Reference Resolution**: Query multiple Git repositories (10-30s)

**Example Commands** (hypothetical):

```bash
# /analyze-complexity command (hypothetical)
# Caches complexity metrics to avoid 5s re-computation
CACHE_FILE=".claude/cache/complexity_$(git rev-parse HEAD).json"

if [ -f "$CACHE_FILE" ]; then
  METRICS=$(cat "$CACHE_FILE")
else
  METRICS=$(analyze_complexity_for_all_files)  # 5-10s
  echo "$METRICS" > "$CACHE_FILE"
fi
```

**Advantages**:

- ✓ **Performance**: Avoid expensive re-computation (1s+ → 30ms)
- ✓ **Persistent**: Cache survives across command invocations
- ✓ **Scalable**: Handle large datasets via incremental caching

**Disadvantages**:

- ✗ **Complexity**: Cache invalidation logic required (not trivial)
- ✗ **Staleness Risk**: Cache may not reflect current state (synchronization issues)
- ✗ **Storage Overhead**: Disk space consumed by cache files (50-500MB)
- ✗ **Failure Modes**: Disk full, permissions errors, stale cache bugs

**When NOT to Use**:

- Computation cost <100ms (overhead >30% of computation time)
- Results change frequently (cache hit rate <50%)
- Complex invalidation logic (maintenance burden > time savings)
- Single-invocation workflows (cache not reused)

**Anti-Pattern Warning**:

Do NOT use file-based state for fast variables (<1ms calculation). This is **premature optimization**:

```bash
# ANTI-PATTERN: File-based state for fast variable
CACHE_FILE=".claude/cache/workflow_scope.txt"
if [ -f "$CACHE_FILE" ]; then
  WORKFLOW_SCOPE=$(cat "$CACHE_FILE")  # 30ms I/O
else
  WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # <1ms calculation
  echo "$WORKFLOW_SCOPE" > "$CACHE_FILE"
fi
# Result: 30x SLOWER than recalculation!

# CORRECT: Stateless recalculation (Pattern 1)
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # <1ms, no I/O
```

**See Also**:
- Anti-Pattern 2: Premature Optimization (section 6.4)
- Pattern 1: Stateless Recalculation (for <100ms operations)

---

#### 6.2.4 Pattern 4: Single Large Block

**Core Concept**: All command logic in one bash block, avoiding subprocess boundaries entirely.

**When to Use**:
- Simple utility commands (<300 lines total)
- No subagent invocation needed
- Simple file creation or template expansion operations
- 0ms overhead required

**Pattern Definition**:

Single large block avoids state management by keeping all logic within a single bash subprocess. Variables persist naturally within the process, eliminating recalculation overhead.

**Key Limitation**: Cannot invoke Task tool for subagent delegation (requires multiple bash blocks).

**Implementation Example**:

```bash
#!/usr/bin/env bash
# Simple utility command - all logic in single block

set -e

# Standard 13: CLAUDE_PROJECT_DIR detection
CLAUDE_PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)

# Parse arguments
FEATURE_NAME="$1"

if [ -z "$FEATURE_NAME" ]; then
  echo "ERROR: Feature name required"
  echo "Usage: /create-spec <feature-name>"
  exit 1
fi

# Variable calculations (persist throughout block)
SANITIZED_NAME=$(echo "$FEATURE_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
TIMESTAMP=$(date -Iseconds)
SPEC_NUMBER=$(find .claude/specs -maxdepth 1 -type d -name "[0-9]*" | wc -l)
SPEC_NUMBER=$((SPEC_NUMBER + 1))

# Create directory structure
TARGET_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${SPEC_NUMBER}_${SANITIZED_NAME}"
mkdir -p "$TARGET_DIR"/{plans,reports,summaries,debug}

# Create README.md
cat > "${TARGET_DIR}/README.md" <<EOF
# ${FEATURE_NAME}

**Spec Number**: ${SPEC_NUMBER}
**Created**: ${TIMESTAMP}

## Overview

[Feature description here]

## Artifacts

- \`plans/\` - Implementation plans
- \`reports/\` - Research reports
- \`summaries/\` - Implementation summaries
- \`debug/\` - Debug reports

## Status

- [ ] Research
- [ ] Planning
- [ ] Implementation
- [ ] Testing
- [ ] Documentation
EOF

# Verify creation
if [ ! -f "${TARGET_DIR}/README.md" ]; then
  echo "ERROR: File creation failed"
  exit 1
fi

# Output result
echo "✓ Created spec directory:"
echo "  Path: ${TARGET_DIR}"
echo "  Number: ${SPEC_NUMBER}"
echo "  Feature: ${FEATURE_NAME}"
echo "  Timestamp: ${TIMESTAMP}"
echo ""
echo "Next steps:"
echo "  1. Edit ${TARGET_DIR}/README.md with feature description"
echo "  2. Run /research <topic> to create initial research report"
echo "  3. Run /plan <description> to create implementation plan"
```

**Trade-off Analysis**:

| Aspect | Advantage | Disadvantage |
|--------|-----------|--------------|
| **Performance** | 0ms overhead (no recalculation) | Cannot invoke subagents (Task tool) |
| **Complexity** | Very Low (straightforward script) | Limited to <300 lines (transformation risk) |
| **Reliability** | No synchronization issues | All logic in single scope |
| **Maintainability** | Single location for all logic | Cannot leverage agent delegation |
| **State Management** | Not needed (variables persist) | N/A |
| **Debugging** | Simple (linear execution) | Large blocks harder to debug |

**Performance Characteristics**:

- **Overhead**: 0ms (no recalculation, no I/O)
- **Execution time**: Linear with script complexity
- **Memory**: Minimal (variables in single process)

**Line Count Threshold**:

Bash blocks >400 lines face increased risk of code transformation bugs. Recommended limits:

- **Safe**: <300 lines
- **Caution**: 300-400 lines
- **High Risk**: >400 lines (consider splitting)

**Limitations**:

**Cannot Invoke Task Tool**:

The Task tool requires separate bash blocks for agent invocations. Single-block commands cannot:

```bash
# IMPOSSIBLE in single-block command
# Task tool invocation requires separate bash block
USE the Task tool with subagent_type=research-specialist...
# This syntax is interpreted as instruction to Claude, not bash code
```

**Multi-block Required for Subagents**:

```bash
# Block 1: Invoke subagent
USE the Task tool with subagent_type=research-specialist
prompt="Research authentication patterns in the codebase"

# Block 2: Process subagent results (separate subprocess)
echo "Subagent completed research"
# Read subagent output and continue workflow
```

**No Phase Boundaries**:

Single-block commands cannot checkpoint progress. If command fails partway through, must restart from beginning.

**Limited Parallelism**:

Cannot launch parallel operations (all execution sequential).

**Use Cases**:

**Perfect For**:
- File creation utilities
- Template expansion commands
- Directory structure initialization
- Configuration file updates
- Simple transformations (<300 lines)

**Not Suitable For**:
- Commands requiring AI reasoning (need subagents)
- Multi-phase workflows (need checkpoints)
- Long-running operations (>5 minutes)
- Complex orchestration (need agent delegation)

**Example Commands** (hypothetical):

- `/create-spec` - Create spec directory structure
- `/init-command` - Initialize new slash command template
- `/update-config` - Update configuration file
- Simple git operations (add, commit, push)

**Advantages**:

- ✓ **Simplicity**: No state management needed
- ✓ **Performance**: 0ms overhead
- ✓ **Reliability**: No synchronization issues
- ✓ **Debugging**: Linear execution, easy to trace

**Disadvantages**:

- ✗ **Cannot Use Task Tool**: No subagent delegation
- ✗ **Line Count Limit**: >400 lines risks transformation bugs
- ✗ **No Resumability**: Must restart from beginning on failure
- ✗ **Limited Complexity**: Cannot handle multi-phase workflows

**When NOT to Use**:

- Command requires subagent invocation (use Pattern 1)
- Command >300 lines (split into multi-block)
- Need resumability (use Pattern 2)
- Complex orchestration workflows (use Pattern 1)

**See Also**:
- Pattern 1: Stateless Recalculation (for multi-block commands)
- Anti-Pattern 3: Over-Consolidation (section 6.4)

---

### 6.3 Decision Framework

#### 6.3.1 Decision Criteria

Use this table to evaluate which pattern fits your command requirements:

| Criteria | Pattern 1: Stateless | Pattern 2: Checkpoints | Pattern 3: File-based | Pattern 4: Single Block |
|----------|---------------------|------------------------|----------------------|------------------------|
| **Variable Count** | <10 | Any | Any | <10 |
| **Recalculation Cost** | <100ms | Any | >1s | N/A |
| **Command Complexity** | Any | >5 phases | Any | <300 lines |
| **Subagent Invocations** | Yes (required) | Yes | Yes | No (limitation) |
| **State Persistence** | Single invocation only | Across interruptions | Across invocations | Single invocation only |
| **Resumability** | No | Yes (checkpoint restore) | No | No |
| **Overhead** | <1ms per variable | 50-100ms per checkpoint | 30ms I/O per cache | 0ms |
| **Complexity** | Low | Medium | High | Very Low |
| **Cleanup Required** | No | Yes (checkpoint rotation) | Yes (cache invalidation) | No |
| **I/O Operations** | None | Read/write JSON | Read/write cache files | None |
| **Failure Modes** | Synchronization drift | Checkpoint corruption | Cache staleness | None (simplicity) |
| **Best For** | Orchestration commands | Long-running workflows | Expensive computation | Simple utilities |

#### 6.3.2 Decision Tree

Use this decision tree to quickly select the appropriate pattern:

```
                    START: Choose State Management Pattern
                                    |
                                    v
                    Does computation take >1 second?
                                    |
                    +---------------+---------------+
                    |                               |
                   YES                             NO
                    |                               |
                    v                               v
            Pattern 3:                 Does workflow have >5 phases
           File-based State               or need resumability?
         (Cache expensive                          |
          computation)              +---------------+---------------+
                                    |                               |
                                   YES                             NO
                                    |                               |
                                    v                               v
                            Pattern 2:                 Does command invoke
                          Checkpoint Files                 subagents?
                       (Multi-phase resumable)                      |
                                                    +---------------+---------------+
                                                    |                               |
                                                   YES                             NO
                                                    |                               |
                                                    v                               v
                                            Pattern 1:                    Is command <300 lines
                                        Stateless Recalc                     total logic?
                                     (Multi-block with                               |
                                      recalculation)                +---------------+---------------+
                                                                    |                               |
                                                                   YES                             NO
                                                                    |                               |
                                                                    v                               v
                                                            Pattern 4:                      Pattern 1:
                                                         Single Large Block              Stateless Recalc
                                                          (Simple utility)            (Split into blocks)
```

**ASCII Box Diagram**:

```
┌─────────────────────────────────────────────────────────────┐
│           State Management Pattern Decision Tree            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Q1: Computation cost >1s?                                  │
│    ├─ YES → Pattern 3 (File-based State)                   │
│    └─ NO → Continue to Q2                                   │
│                                                             │
│  Q2: Multi-phase workflow (>5 phases) or resumable?         │
│    ├─ YES → Pattern 2 (Checkpoint Files)                   │
│    └─ NO → Continue to Q3                                   │
│                                                             │
│  Q3: Invokes subagents (Task tool)?                         │
│    ├─ YES → Pattern 1 (Stateless Recalculation)            │
│    └─ NO → Continue to Q4                                   │
│                                                             │
│  Q4: Command <300 lines total?                              │
│    ├─ YES → Pattern 4 (Single Large Block)                 │
│    └─ NO → Pattern 1 (Stateless Recalc, split blocks)      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Quick Pattern Selection Reference

**Choose Pattern 1 (Stateless Recalculation)** when:
- Command invokes subagents via Task tool
- <10 variables need persistence
- Recalculation cost <100ms
- Single invocation (no resumability needed)
- Example: `/coordinate`, `/orchestrate`

**Choose Pattern 2 (Checkpoint Files)** when:
- Multi-phase workflow (>5 phases)
- Resumability required (interruption tolerance)
- Execution time >10 minutes
- State audit trail needed
- Example: `/implement`, long-running orchestration

**Choose Pattern 3 (File-based State)** when:
- Computation cost >1 second
- Results reused across invocations
- Caching justifies 30ms I/O overhead
- Cache invalidation logic manageable
- Example: Codebase analysis, dependency graphs

**Choose Pattern 4 (Single Large Block)** when:
- Command <300 lines total
- No subagent invocation needed
- Simple utility operation
- 0ms overhead required
- Example: File creation utilities, template expansion

---

### 6.4 Anti-Patterns

#### Anti-Pattern 1: Fighting the Tool Constraints

**Description**: Attempting to make exports work across Bash tool blocks or using workarounds to bypass subprocess isolation.

**Why It Fails**:
- Bash tool subprocess isolation (GitHub issues #334, #2508)
- Exports don't persist across tool invocations
- Workarounds are fragile and violate fail-fast principle

**Technical Explanation**:

The Bash tool launches each code block in a separate subprocess, not a subshell. This means:

```bash
# Block 1
export VAR="value"
export ANOTHER_VAR="data"

# Block 2 (completely separate subprocess)
echo "$VAR"          # Empty! Export didn't persist
echo "$ANOTHER_VAR"  # Empty! Export didn't persist
```

Subprocess boundaries are fundamental to the tool architecture and cannot be bypassed.

**Real Example from Spec 582**:

Early attempts tried global variable exports:

```bash
# Attempted solution (FAILED)
export WORKFLOW_SCOPE="research-and-plan"
export PHASES_TO_EXECUTE="1 2"

# Later block
if [ -z "$PHASES_TO_EXECUTE" ]; then
  echo "ERROR: Variable not set"  # This error occurred!
fi
```

**Why This Happened**:

Developers assumed bash blocks were subshells (where exports persist), not separate subprocesses (where they don't).

**Attempted Workarounds** (all failed):

1. **Global Environment Variables**: `export` doesn't persist
2. **eval $(previous_block)**: Previous block output not accessible
3. **Source Script Files**: Files must be created in separate blocks
4. **Named Pipes**: Complex, fragile, high failure rate

**What to Do Instead**:

Use Pattern 1 (Stateless Recalculation):

```bash
# Block 1
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")

# Block 2 (recalculate, don't rely on export)
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")
```

Or use Pattern 2 (Checkpoint Files) for complex state:

```bash
# Block 1
save_checkpoint "workflow" '{"scope": "research-only"}'

# Block 2
WORKFLOW_SCOPE=$(load_checkpoint "workflow" | jq -r '.scope')
```

**Lesson Learned**:

Work with tool constraints, not against them. Subprocess isolation is intentional (security, reliability). Accept it and choose appropriate state management pattern.

**Reference**: Specs 582-584 discovery phase

---

#### Anti-Pattern 2: Premature Optimization

**Description**: Using file-based state (Pattern 3) for fast calculations to avoid "code duplication".

**Why It Fails**:
- Adds 30ms I/O overhead for <1ms operation (30x slower!)
- Introduces cache invalidation complexity
- Creates new failure modes (disk full, permissions, staleness)
- Code is more complex, not simpler

**Technical Explanation**:

File I/O overhead (30ms) exceeds recalculation cost (<1ms) for simple variables:

```bash
# ANTI-PATTERN: File-based state for simple variable
VAR_CACHE=".claude/cache/workflow_scope.txt"
if [ -f "$VAR_CACHE" ]; then
  WORKFLOW_SCOPE=$(cat "$VAR_CACHE")  # 30ms I/O
else
  WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # <1ms calculation
  echo "$WORKFLOW_SCOPE" > "$VAR_CACHE"
fi
# Total time: 30ms cached, 31ms uncached (30x slower than recalculation!)

# CORRECT: Stateless recalculation (Pattern 1)
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # <1ms, no I/O, deterministic
```

**Performance Comparison**:

| Approach | First Invocation | Cached Invocation | Complexity | Failure Modes |
|----------|-----------------|-------------------|------------|---------------|
| **Recalculation** | <1ms | <1ms | Low | None |
| **File-based Cache** | 31ms (calc+write) | 30ms (read) | High | 4+ modes |

**Real Example from Spec 585**:

Research validation measured performance:

```bash
# Benchmark: Scope detection recalculation
time detect_workflow_scope "research authentication patterns"
# Result: 0.002s (2ms)

# Benchmark: File I/O (read + write)
time echo "test" > /tmp/bench.txt && cat /tmp/bench.txt
# Result: 0.031s (31ms)

# Verdict: Recalculation 15x faster than file I/O
```

**Why Developers Make This Mistake**:

- **Intuition**: "Code duplication is bad, caching is good"
- **Reality**: Code duplication is <1ms overhead, file caching is 30ms overhead
- **Lesson**: Measure performance before optimizing

**Additional Complexity Costs**:

```bash
# File-based state requires:
# 1. Cache invalidation logic (when to regenerate?)
# 2. Error handling (file not found, permissions, disk full)
# 3. Cleanup logic (prevent unbounded cache growth)
# 4. Testing (cache hit/miss scenarios)

# Stateless recalculation requires:
# - Nothing! Just call function again.
```

**What to Do Instead**:

Accept recalculation cost if <100ms. Only use file-based state when computation cost >1 second justifies I/O overhead.

**Decision Rule**:

```
if computation_cost < 100ms:
    use Pattern 1 (Stateless Recalculation)
elif computation_cost < 1s:
    evaluate trade-off (context-dependent)
else:  # computation_cost > 1s
    use Pattern 3 (File-based State) with cache invalidation
```

**Reference**: Spec 585 research validation

---

#### Anti-Pattern 3: Over-Consolidation

**Description**: Creating >400 line bash blocks to eliminate recalculation overhead.

**Why It Fails**:
- Code transformation risk at >400 lines (tool limitation)
- Readability degradation (harder to understand monolithic block)
- Cannot leverage Task tool for subagent delegation
- Single point of failure (entire block fails if one operation fails)

**Technical Explanation**:

Large bash blocks increase risk of code transformation bugs. The threshold is approximately 300-400 lines (empirically observed):

```bash
# ANTI-PATTERN: Monolithic 500-line block
# Block 1 (500 lines)
CLAUDE_PROJECT_DIR=$(detect_project_dir)
# ... 450 lines of logic ...
# All logic in single block (no recalculation, but risky transformation)
```

**Why 400 Lines is the Threshold**:

- **Context Window**: Large code blocks consume significant context
- **Transformation Risk**: Claude may inadvertently modify code during tool invocation
- **Debugging Difficulty**: Hard to isolate failures in 500-line block
- **Maintainability**: Large blocks harder to understand and modify

**Real Example from Spec 582**:

Initial attempts consolidated all Phase 0 logic into single block:

**Before Split** (Phase 6 analysis):
- Block size: 421 lines
- Risk: Code transformation bugs (threshold exceeded)
- Performance: 0ms recalculation overhead (but at what cost?)

**After Split** (chosen approach):
```bash
# Block 1: Phase 0 initialization (176 lines) ✓ Under threshold
# Block 2: Research setup (168 lines) ✓ Under threshold
# Block 3: Planning setup (77 lines) ✓ Under threshold
# Total recalculation overhead: <10ms
```

**Performance vs Risk Trade-off**:

| Approach | Overhead | Risk | Maintainability | Subagent Support |
|----------|----------|------|----------------|------------------|
| **Single 500-line block** | 0ms | HIGH | Low | No (Task tool blocked) |
| **3 blocks (<200 lines each)** | <10ms | Low | High | Yes (Task tool works) |

**Verdict**: 10ms overhead acceptable for 3x risk reduction.

**What to Do Instead**:

Split logic into multiple blocks (each <300 lines). Accept recalculation overhead (<10ms total) for safety and maintainability.

**Correct Approach** (from /coordinate after refactor):

```bash
# Block 1: Phase 0 initialization (176 lines)
CLAUDE_PROJECT_DIR=$(detect_project_dir)
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")
PHASES_TO_EXECUTE=$(calculate_phases "$WORKFLOW_SCOPE")
# ... initialization logic ...

# Block 2: Research setup (168 lines)
CLAUDE_PROJECT_DIR=$(detect_project_dir)  # Recalculate (deterministic)
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # <1ms overhead
PHASES_TO_EXECUTE=$(calculate_phases "$WORKFLOW_SCOPE")
# ... research logic ...

# Block 3: Planning setup (77 lines)
CLAUDE_PROJECT_DIR=$(detect_project_dir)  # Recalculate
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")
PHASES_TO_EXECUTE=$(calculate_phases "$WORKFLOW_SCOPE")
# ... planning logic ...

# Overhead: 3 blocks × 3 variables × <1ms = <10ms
# Benefit: Risk mitigation + Task tool support
```

**Block Size Guidelines**:

- **Safe**: <300 lines per block
- **Caution**: 300-400 lines (watch for issues)
- **Danger**: >400 lines (high transformation risk)

**When Consolidation is OK**:

If command is simple utility (<300 lines total), use Pattern 4 (Single Large Block):

```bash
# OK: Simple 250-line utility command
# Single block is safe and appropriate
```

**Reference**: Spec 582 discovery, Phase 6 analysis (deferred)

---

#### Anti-Pattern 4: Inconsistent Patterns

**Description**: Mixing state management approaches within same command (e.g., stateless recalculation for some variables, file-based state for others).

**Why It Fails**:
- Cognitive overhead (developers must track which variables use which pattern)
- Debugging complexity (is failure from recalculation or cache staleness?)
- Maintenance burden (multiple patterns to update)
- No performance benefit (overhead is per-pattern, not reduced by mixing)

**Technical Explanation**:

Mixing patterns creates mental model confusion:

```bash
# ANTI-PATTERN: Inconsistent patterns
# Block 1
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # Pattern 1: Recalculate
PHASES=$(cat .claude/cache/phases.txt)            # Pattern 3: File-based
CLAUDE_PROJECT_DIR=$(load_checkpoint "state" | jq -r '.project_dir')  # Pattern 2: Checkpoint

# Block 2
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # Pattern 1: Recalculate
PHASES=$(cat .claude/cache/phases.txt)            # Pattern 3: File-based
CLAUDE_PROJECT_DIR=$(load_checkpoint "state" | jq -r '.project_dir')  # Pattern 2: Checkpoint

# Developer must remember:
# - WORKFLOW_SCOPE is recalculated (deterministic)
# - PHASES is cached (may be stale)
# - CLAUDE_PROJECT_DIR is checkpointed (may be stale)
# Which variable failed? Was it stale cache or bad recalculation?
```

**Debugging Nightmare**:

```bash
# Bug report: "PHASES_TO_EXECUTE is wrong in Block 3"
# Possible causes:
# 1. Recalculation logic wrong? (check detect_workflow_scope)
# 2. Cache stale? (check .claude/cache/phases.txt modification time)
# 3. Checkpoint corrupted? (check checkpoint JSON integrity)
# 4. Wrong pattern used? (check which Block 3 uses)
# 5. Synchronization issue? (check if Block 1 and Block 3 use same pattern)
# → 5 failure modes to investigate vs 1 (if consistent pattern)
```

**Real Example from Specs 583-584**:

Attempted mixing stateless recalculation with checkpoint-style persistence:

```bash
# Block 1: Initialization
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # Stateless
save_checkpoint "state" "{\"phases\": \"$PHASES\"}"  # Checkpoint

# Block 2: Research
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # Stateless (consistent)
PHASES=$(load_checkpoint "state" | jq -r '.phases')  # Checkpoint (consistent)

# Block 3: Planning
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # Stateless (consistent)
PHASES=$(cat .claude/cache/phases.txt)  # File-based (INCONSISTENT!)

# Bug: Block 3 uses different pattern (file-based cache vs checkpoint)
# Result: PHASES may be different in Block 3 vs Block 2
# Debugging: Which is correct? Cache or checkpoint?
```

**What to Do Instead**:

Choose one pattern and apply consistently throughout command. Exceptions must be clearly documented.

**Correct Approach**:

```bash
# Pattern 1 applied consistently
# Block 1
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")
PHASES=$(calculate_phases "$WORKFLOW_SCOPE")
CLAUDE_PROJECT_DIR=$(detect_project_dir)

# Block 2
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # Consistent recalculation
PHASES=$(calculate_phases "$WORKFLOW_SCOPE")      # Consistent recalculation
CLAUDE_PROJECT_DIR=$(detect_project_dir)          # Consistent recalculation

# Block 3
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # Consistent
PHASES=$(calculate_phases "$WORKFLOW_SCOPE")      # Consistent
CLAUDE_PROJECT_DIR=$(detect_project_dir)          # Consistent

# Mental model: "All variables are recalculated in every block"
# Debugging: If variable wrong, check calculation function
# Maintenance: Update calculation function once, applies everywhere
```

**Documented Exceptions** (when necessary):

```bash
# Block 1
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # Pattern 1: Stateless
CODEBASE_ANALYSIS=$(cat .claude/cache/analysis.json)  # Pattern 3: File-based

# DOCUMENTED EXCEPTION: CODEBASE_ANALYSIS uses file-based caching because:
# 1. Computation cost: 5-10 seconds (too expensive to recalculate)
# 2. Cache invalidation: Content-based (analysis_${PROJECT_HASH}.json)
# 3. Overhead justified: 5s → 30ms (167x speedup)
# All other variables use Pattern 1 (Stateless Recalculation)
```

**Pattern Selection Rule**:

1. Choose primary pattern based on command requirements (see decision framework)
2. Apply primary pattern to ALL variables
3. Only deviate for exceptional cases (document WHY)

**Reference**: Specs 583-584, Spec 597 consistency breakthrough

---

### 6.5 Case Studies

#### Case Study 1: /coordinate - Stateless Recalculation Pattern

**Context**: Specs 582-594 explored various approaches to managing state across /coordinate's 6 bash blocks

**Problem**:
- 6 bash blocks (Phases 0-6) required variable persistence
- Exports don't work (subprocess isolation)
- 10+ variables needed across blocks (WORKFLOW_SCOPE, PHASES_TO_EXECUTE, CLAUDE_PROJECT_DIR, etc.)
- Initial attempts with file-based state added 30ms overhead per block (180ms total)

**Exploration Timeline**:

**Spec 582-584: Discovery Phase** (Fighting tool constraints)
- **Attempted**: Global exports (failed - subprocess isolation)
- **Attempted**: Temporary file persistence (worked but slow - 180ms overhead)
- **Result**: 48-line scope detection duplicated across 2 blocks
- **Learning**: Exports don't persist across bash tool invocations

**Spec 585: Research Validation**
- **Measured**: File I/O overhead = 30ms per operation
- **Measured**: Recalculation overhead = <1ms per variable
- **Conclusion**: File-based state 30x slower for simple variables
- **Decision**: Investigate recalculation-based approach

**Spec 593: Problem Mapping**
- **Identified**: 108 lines of duplicated code across blocks
- **Identified**: 3 synchronization points (CLAUDE_PROJECT_DIR, scope detection, PHASES_TO_EXECUTE)
- **Risk**: Synchronization drift between duplicate code locations
- **Quantified**: 48-line scope detection duplication highest risk

**Spec 597: Breakthrough - Stateless Recalculation**
- **Key Insight**: Accept code duplication as intentional trade-off
- **Pattern**: Recalculate all variables in every block (<1ms overhead each)
- **Benefits**: Deterministic, no I/O, simple mental model
- **Trade-off**: 50-80 lines duplication vs 180ms file I/O savings
- **Performance**: <10ms total overhead vs 180ms (18x faster!)

**Spec 598: Extension to Derived Variables**
- **Extended**: Pattern to PHASES_TO_EXECUTE mapping
- **Added**: Defensive validation after recalculation
- **Fixed**: overview-synthesis.sh missing from REQUIRED_LIBS
- **Result**: 100% reliability, <10ms total overhead

**Solution Implemented**:

```bash
# Every block recalculates what it needs
# Block 1 - Phase 0
CLAUDE_PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
PHASES_TO_EXECUTE=$(calculate_phases "$WORKFLOW_SCOPE")

# Block 2 - Phase 1 (different subprocess)
CLAUDE_PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
PHASES_TO_EXECUTE=$(calculate_phases "$WORKFLOW_SCOPE")

# Overhead: <1ms per block × 6 blocks = <6ms total
# Alternative (file-based): 30ms × 6 = 180ms (30x slower)
```

**Outcome**:
- ✓ 16/16 integration tests passing
- ✓ <10ms total recalculation overhead
- ✓ Zero I/O operations (pure computation)
- ✓ Deterministic behavior (no cache staleness)
- ✓ Simple mental model (no state synchronization)

**Lessons Learned**:

1. **Accept Duplication**: 50-80 lines duplication is acceptable trade-off for simplicity
2. **Work With Constraints**: Embrace tool constraints rather than fighting them
3. **Measure Performance**: Validate assumptions with benchmarks (recalc vs file I/O)
4. **Validate Pattern**: Extensive testing (16 integration tests) proves reliability
5. **Document Rationale**: Architecture documentation prevents future misguided refactor attempts

**Applicable To**:
- Multi-block orchestration commands
- Commands with <10 variables requiring persistence
- Workflows with recalculation cost <100ms
- Commands invoking subagents via Task tool

**References**:
- Specs: 582-584 (discovery), 585 (validation), 593 (mapping), 597 (breakthrough), 598 (extension)
- Architecture Doc: `.claude/docs/architecture/coordinate-state-management.md`

---

#### Case Study 2: /implement - Checkpoint Files Pattern

**Context**: Multi-phase implementation workflow requiring resumability after interruptions

**Problem**:
- 5+ phase implementation plans
- Execution time: 2-6 hours per plan
- Interruptions: Network failures, manual stops, system restarts
- State complexity: Current phase, completed phases, test status, git commits

**Pattern Choice Rationale**:

**Why Not Pattern 1 (Stateless Recalculation)?**
- Cannot recalculate "current phase" after interruption (state lost on process termination)
- Cannot determine which phases completed successfully (test results lost)
- Git commit hashes not recoverable (not deterministic from inputs)
- Implementation modifications not recalculable (real file system changes)

**Why Not Pattern 3 (File-based State)?**
- State changes frequently (every phase boundary) → cache churn
- Cache invalidation complex (which phase checkpoint is valid?)
- Not caching computation results - persisting workflow progress (different use case)

**Why Pattern 2 (Checkpoint Files)?**
- ✓ Perfect fit for resumable workflows
- ✓ Phase boundaries are natural checkpoint locations
- ✓ State serialization to JSON straightforward
- ✓ Checkpoint history provides audit trail
- ✓ 50-100ms overhead negligible for hour-long workflows

**Solution Implemented**:

```bash
# Source checkpoint utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/checkpoint-utils.sh"

# After each phase completion
CHECKPOINT_DATA=$(cat <<EOF
{
  "command": "implement",
  "plan_path": "$PLAN_PATH",
  "current_phase": $PHASE_NUMBER,
  "completed_phases": [1, 2, 3],
  "tests_passing": true,
  "files_modified": ["file1.lua", "file2.lua"],
  "git_commits": ["a3f8c2e", "b7d4e1f", "c9e5a2f"],
  "timestamp": "$(date -Iseconds)"
}
EOF
)

save_checkpoint "implement_${PROJECT_NAME}" "$CHECKPOINT_DATA"

# On workflow restart (after interruption)
if [ -f "$CHECKPOINT_FILE" ]; then
  PLAN_PATH=$(jq -r '.plan_path' "$CHECKPOINT_FILE")
  START_PHASE=$(($(jq -r '.current_phase' "$CHECKPOINT_FILE") + 1))
  echo "Resuming from phase $START_PHASE"
fi
```

**Outcome**:
- ✓ Full workflow resumability after interruptions
- ✓ 50-100ms overhead per checkpoint (acceptable for hour-long workflows)
- ✓ Audit trail of implementation progress
- ✓ State synchronized with reality (checkpoints after successful phase completion)

**Lessons Learned**:

1. **Right Tool for Job**: Checkpoint pattern perfect for resumable multi-phase workflows
2. **Phase Boundaries**: Natural checkpoint locations provide clear state transitions
3. **Overhead Acceptable**: 50-100ms negligible for hour-long workflows (0.1% overhead)
4. **JSON Serialization**: Flexible state structure, easy to extend with new fields

**Applicable To**:
- Long-running implementation workflows
- Multi-phase operations requiring resumability
- Commands needing audit trail
- Workflows with >5 phases

**References**:
- Implementation: `/implement` command
- Utilities: `.claude/lib/checkpoint-utils.sh`

---

### 6.6 Cross-References

**Architecture Documentation**:
- [Coordinate State Management Architecture](../architecture/coordinate-state-management.md) - Complete technical analysis with subprocess isolation explanation, decision matrix, troubleshooting guide

**Related Patterns**:
- [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md) - Detailed checkpoint implementation patterns
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Agent invocation across bash blocks

**Related Specifications**:
- Spec 597: Stateless Recalculation Breakthrough
- Spec 598: Extension to Derived Variables
- Spec 585: Research Validation (performance measurements)
- Spec 593: Comprehensive Problem Mapping

**Library References**:
- `.claude/lib/checkpoint-utils.sh` - Checkpoint save/restore utilities
- `.claude/lib/workflow-detection.sh` - Workflow scope detection
- `.claude/lib/unified-location-detection.sh` - Path calculation utilities

**Command Examples**:
- `/coordinate` - Stateless recalculation implementation
- `/implement` - Checkpoint files implementation
- `/orchestrate` - Similar multi-block patterns

**Standards**:
- [CLAUDE.md Development Philosophy](../../CLAUDE.md#development_philosophy) - Clean-break approach, fail-fast principles
- [Command Architecture Standards](../reference/command_architecture_standards.md) - Standard 13 (CLAUDE_PROJECT_DIR detection)

---
## 7. Testing and Validation

### 7.1 Testing Standards Integration

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

### 7.2 Validation Checklist

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
- [ ] Agents invoked with context injection only (no behavioral duplication)
- [ ] Agent prompts reference behavioral files, contain NO STEP sequences
- [ ] Context passed efficiently (metadata-only)
- [ ] Results processed correctly
- [ ] Errors handled gracefully

**User Experience**:
- [ ] Clear progress indicators
- [ ] Helpful error messages
- [ ] Appropriate logging
- [ ] Expected completion message

---

## 8. Common Patterns and Examples

### 8.1 Example: Research Command with Agent Delegation

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

### Step 2: Invoke Research Agent with Behavioral File Reference

**AGENT INVOCATION - Reference Behavioral File, Inject Context Only**

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${RESEARCH_TOPIC} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${RESEARCH_TOPIC}
    - Output Path: ${REPORT_PATH} (absolute path, pre-calculated)
    - Project Standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

**Why This Pattern Works**:
- research-specialist.md contains complete behavioral guidelines (646 lines)
- Agent reads behavioral file and follows all step-by-step instructions automatically
- Command only injects workflow-specific context (paths, parameters)
- No duplication: single source of truth maintained in behavioral file
- Reduction: ~150 lines → ~15 lines per invocation (90% reduction)

**✓ CORRECT**: This example shows context injection only (parameters, file paths)

**✗ INCORRECT**: Do not add STEP 1/2/3 instructions inline (reference behavioral file instead). Example of anti-pattern:
```yaml
# ❌ BAD - Duplicating behavioral content
Task {
  prompt: "
    STEP 1: Analyze codebase...
    STEP 2: Create report file...
    STEP 3: Verify and return...
    [150+ lines of agent behavioral procedures]
  "
}
```

See [Template vs Behavioral Distinction](../reference/template-vs-behavioral-distinction.md) for decision criteria on what qualifies as context (inline OK) vs behavioral content (reference agent file).

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

### 8.2 When to Use Inline Templates

**Structural templates** are command execution patterns that MUST be inline. These are NOT behavioral content and should not be moved to agent files.

**Inline Required** - Structural Templates:

1. **Task Invocation Blocks**
   ```yaml
   Task {
     subagent_type: "general-purpose"
     description: "Research topic"
     prompt: "..."
   }
   ```
   - **Why inline**: Commands must parse this structure to invoke agents
   - **Context**: Command/orchestrator responsibility

2. **Bash Execution Blocks**
   ```bash
   # EXECUTE NOW
   source .claude/lib/artifact-creation.sh
   REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "001" "")
   ```
   - **Why inline**: Commands must execute these operations directly
   - **Context**: Command/orchestrator responsibility

3. **Verification Checkpoints**
   ```markdown
   **MANDATORY VERIFICATION**: After agent completes, verify:
   - Report file exists at $REPORT_PATH
   - Report contains all required sections
   ```
   - **Why inline**: Orchestrator (command) is responsible for verification
   - **Context**: Command/orchestrator responsibility

4. **JSON Schemas**
   ```json
   {
     "report_metadata": {
       "title": "string",
       "summary": "string (max 50 words)"
     }
   }
   ```
   - **Why inline**: Commands must parse and validate data structures
   - **Context**: Command/orchestrator responsibility

5. **Critical Warnings**
   ```markdown
   **CRITICAL**: Never create empty directories.
   **IMPORTANT**: File creation operations MUST be verified.
   ```
   - **Why inline**: Execution-critical constraints that commands enforce
   - **Context**: Command/orchestrator responsibility

**NOT Inline** - Behavioral Content (Reference Agent Files):

- Agent STEP sequences: `STEP 1/2/3` procedural instructions
- File creation workflows: `PRIMARY OBLIGATION` blocks
- Agent verification steps: Agent-internal quality checks
- Output format specifications: Templates for agent responses

These belong in `.claude/agents/*.md` files and are referenced via behavioral injection pattern.

See [Template vs Behavioral Distinction](../reference/template-vs-behavioral-distinction.md) for complete decision criteria.

### 8.3 Anti-Patterns to Avoid

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

### 8.4 Dry-Run Mode Examples

Dry-run mode allows users to preview command execution without making changes or invoking agents. Commands supporting dry-run include `/orchestrate`, `/implement`, `/revise`, and `/plan`.

**Dry-Run Flag Usage**:
```bash
# Basic dry-run
/orchestrate "Add user authentication" --dry-run

# Dry-run with other flags
/implement plan_file.md --dry-run --starting-phase 3
```

**Example: /orchestrate Dry-Run Output**:
```
┌─────────────────────────────────────────────────────────────┐
│ Workflow: Add user authentication with JWT tokens (Dry-Run)│
├─────────────────────────────────────────────────────────────┤
│ Workflow Type: feature  |  Estimated Duration: ~28 minutes  │
│ Complexity: Medium-High  |  Agents Required: 6              │
├─────────────────────────────────────────────────────────────┤
│ Phase 1: Research (Parallel - 3 agents)           ~8min    │
│   ├─ research-specialist: "JWT authentication patterns"    │
│   ├─ research-specialist: "Security best practices"        │
│   └─ research-specialist: "Token refresh strategies"       │
│                                                              │
│ Phase 2: Planning (Sequential)                    ~5min    │
│   └─ plan-architect: Synthesize research into plan         │
│                                                              │
│ Phase 3: Implementation (Adaptive)                ~12min   │
│   └─ code-writer: Execute plan phase-by-phase              │
│                                                              │
│ Phase 4: Debugging (Conditional)                  ~0min    │
│   └─ debug-specialist: Skipped (no test failures)          │
│                                                              │
│ Phase 5: Documentation (Sequential)               ~3min    │
│   └─ doc-writer: Update docs and generate summary          │
├─────────────────────────────────────────────────────────────┤
│ Execution Summary:                                           │
│   Total Phases: 5  |  Conditional Phases: 1  |  Parallel: Yes│
│   Estimated Time: 28 minutes (20min with parallelism)      │
└─────────────────────────────────────────────────────────────┘
```

**Workflow Type Detection**:
```
feature      → Full workflow (research, planning, implementation, documentation)
refactor     → Skip research if standards exist
debug        → Start with debug phase
investigation → Research-only (skip implementation)
```

### 8.5 Dashboard Progress Examples

Dashboard-style progress tracking provides real-time visibility into long-running operations. Commands using dashboards include `/implement`, `/orchestrate`, and `/test-all`.

**Example: /implement Dashboard Output**:
```
╔════════════════════════════════════════════════════════════╗
║ Implementation Progress: User Authentication System        ║
╠════════════════════════════════════════════════════════════╣
║ Plan: specs/plans/042_user_authentication.md              ║
║ Progress: Phase 3/5 (60%)                                  ║
║ Duration: 5h 23m elapsed  |  Est. Remaining: 3h 15m        ║
╠════════════════════════════════════════════════════════════╣
║ ✓ Phase 1: Database Schema (COMPLETE)          2h 45m     ║
║   ✓ All 8 tasks complete                                   ║
║   ✓ Tests passing (test_user_model.lua)                    ║
║   ✓ Commit: a3f8c2e "feat: implement user database schema" ║
║                                                            ║
║ ✓ Phase 2: Authentication Service (COMPLETE)   3h 12m     ║
║   ✓ All 12 tasks complete                                  ║
║   ✓ Tests passing (test_auth_service.lua)                  ║
║   ✓ Commit: b7d4e1f "feat: implement JWT auth service"     ║
║                                                            ║
║ ⚙ Phase 3: API Endpoints (IN PROGRESS)         1h 23m     ║
║   ✓ Task 1-7 complete                                      ║
║   ⚙ Task 8: Implement /auth/refresh endpoint              ║
║   ○ Task 9-10 pending                                      ║
║                                                            ║
║ ○ Phase 4: Token Refresh (PENDING)             Est. 1.5h  ║
║ ○ Phase 5: Integration Testing (PENDING)       Est. 1.75h ║
╠════════════════════════════════════════════════════════════╣
║ Status Legend: ✓ Complete | ⚙ In Progress | ○ Pending    ║
╚════════════════════════════════════════════════════════════╝
```

**Status Indicators**:
```
✓ Complete
⚙ In Progress
○ Pending
✗ Failed
⚠ Warning
```

### 8.6 Checkpoint Save/Restore Examples

Checkpoints enable resumability for long-running operations that may be interrupted. Commands using checkpoints include `/implement`, `/orchestrate`, and `/revise --auto-mode`.

**Checkpoint Save Pattern**:
```bash
# Source checkpoint utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/checkpoint-utils.sh"

# Create checkpoint data
CHECKPOINT_DATA=$(cat <<EOF
{
  "command": "implement",
  "plan_path": "$PLAN_PATH",
  "current_phase": $CURRENT_PHASE,
  "completed_phases": $COMPLETED_PHASES,
  "tests_passing": $TESTS_PASSING,
  "timestamp": "$(date -Iseconds)"
}
EOF
)

# Save checkpoint
if save_checkpoint "implement_${PROJECT_NAME}" "$CHECKPOINT_DATA"; then
  echo "✓ Checkpoint saved"
fi
```

**Checkpoint Restore Pattern**:
```bash
# Check for existing checkpoint
CHECKPOINT_FILE=".claude/checkpoints/implement_${PROJECT_NAME}_latest.json"

if [ -f "$CHECKPOINT_FILE" ]; then
  # Display checkpoint info
  CHECKPOINT_TIME=$(jq -r '.timestamp' "$CHECKPOINT_FILE")
  CHECKPOINT_PHASE=$(jq -r '.current_phase' "$CHECKPOINT_FILE")

  echo "Found checkpoint from $CHECKPOINT_TIME"
  read -p "Resume from phase $CHECKPOINT_PHASE? (y/n): " RESUME

  if [ "$RESUME" = "y" ]; then
    # Load checkpoint
    PLAN_PATH=$(jq -r '.plan_path' "$CHECKPOINT_FILE")
    START_PHASE=$((CHECKPOINT_PHASE + 1))
    echo "✓ Resuming from phase $START_PHASE"
  fi
fi
```

**Checkpoint Structure**:
```json
{
  "command": "implement",
  "plan_path": "/absolute/path/to/plan.md",
  "current_phase": 2,
  "completed_phases": [1, 2],
  "tests_passing": true,
  "files_modified": ["migrations/001_create_users.lua"],
  "git_commits": ["a3f8c2e", "b7d4e1f"],
  "timestamp": "2025-10-12T16:45:30-04:00"
}
```

### 8.7 Test Execution Patterns

Consistent test execution patterns across commands for validation. Commands using test execution include `/implement`, `/test`, and `/test-all`.

**Phase-Level Test Execution**:
```bash
# After completing phase tasks, run phase tests
echo "Running tests for Phase $CURRENT_PHASE..."

# Extract test commands from phase tasks
TEST_COMMANDS=$(grep -E "^\s*-\s*\[.\]\s*(Run|Test):" "$PLAN_FILE" | \
                grep -A1 "Phase $CURRENT_PHASE" | \
                sed 's/^.*: //')

if [ -n "$TEST_COMMANDS" ]; then
  while IFS= read -r TEST_CMD; do
    echo "  Executing: $TEST_CMD"
    if eval "$TEST_CMD"; then
      echo "  ✓ Test passed"
    else
      echo "  ✗ Test failed"
      TESTS_PASSING=false
      break
    fi
  done <<< "$TEST_COMMANDS"
else
  # No explicit test commands - use default pattern
  if [ -f "tests/run_tests.lua" ]; then
    lua tests/run_tests.lua
  elif [ -f "pytest.ini" ]; then
    pytest tests/
  elif [ -f "package.json" ]; then
    npm test
  fi
fi
```

**Test Framework Detection**:
```bash
detect_test_framework() {
  # Lua testing
  if [ -f "tests/run_tests.lua" ] || [ -f "spec/init.lua" ]; then
    echo "lua"
    return 0
  fi

  # Python testing
  if [ -f "pytest.ini" ] || [ -f "setup.py" ]; then
    echo "pytest"
    return 0
  fi

  # JavaScript/Node testing
  if [ -f "package.json" ] && grep -q "\"test\":" package.json; then
    echo "npm"
    return 0
  fi

  echo "unknown"
  return 1
}
```

### 8.8 Git Commit Patterns

Consistent git commit patterns for automated commits during implementation phases. Commands creating commits include `/implement`, `/document`, and `/orchestrate`.

**Phase Completion Commit**:
```bash
# After phase completes successfully
echo "Creating git commit for Phase $CURRENT_PHASE..."

COMMIT_MSG=$(cat <<EOF
feat: implement Phase $CURRENT_PHASE - $PHASE_NAME

Automated implementation of phase $CURRENT_PHASE from implementation plan.

Changes:
$(git diff --cached --name-status | sed 's/^/- /')

Tests: All passing
Plan: $PLAN_PATH

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)

# Stage and commit
git add .
if git commit -m "$COMMIT_MSG"; then
  COMMIT_HASH=$(git rev-parse --short HEAD)
  echo "✓ Commit created: $COMMIT_HASH"
fi
```

**Commit Message Structure**:
```
<type>: <subject>

<body>

<footer>
```

**Types**:
```
feat:     New feature implementation
fix:      Bug fix
refactor: Code refactoring
docs:     Documentation changes
test:     Test additions or modifications
chore:    Build/tooling changes
```

**Pre-Commit Validation**:
```bash
pre_commit_validation() {
  echo "Validating changes before commit..."

  # Check for syntax errors
  if ! find . -name "*.lua" -exec luacheck {} \;; then
    echo "✗ Syntax errors detected"
    return 1
  fi

  # Check tests pass
  if ! run_tests; then
    echo "✗ Tests failing"
    return 1
  fi

  echo "✓ Pre-commit validation passed"
  return 0
}
```

### 8.9 Context Preservation Examples

**Metadata-Only Passing Example** (Standard 6):

Traditional approach passes full content (15,000 tokens):
```bash
REPORT_1=$(cat specs/reports/001_jwt_patterns.md)    # 5000 tokens
REPORT_2=$(cat specs/reports/002_security.md)        # 5000 tokens
REPORT_3=$(cat specs/reports/003_integration.md)     # 5000 tokens

# Pass to planning agent (15,000 tokens!)
Task {
  prompt: "Research Reports: $REPORT_1 $REPORT_2 $REPORT_3"
}
```

Metadata-only approach (250 tokens):
```bash
# Extract metadata (not full content)
for report in "${REPORTS[@]}"; do
  METADATA=$(extract_report_metadata "$report")
  REPORT_REFS+=("$METADATA")
done

# Pass metadata only (250 tokens - 99% reduction)
Task {
  prompt: "Research Reports (reference): ${REPORT_REFS[@]}
           Use Read tool to access full content selectively if needed."
}
```

**Benefits**: 15,000 tokens → 250 tokens (98% reduction), full details preserved in files.

**Forward Message Pattern** (Standard 7):

Traditional re-summarization (400 tokens overhead):
```bash
# Research completes
RESEARCH_SUMMARY="Research found JWT patterns with HMAC-SHA256..."

# Planning phase
Task { prompt: "Prior Research: $RESEARCH_SUMMARY" }
```

Forward message approach (0 tokens overhead):
```bash
# Research completes
HANDOFF=$(forward_message "$RESEARCH_RESULT")  # Extract agent's summary

# Planning phase - use agent's original words
Task { prompt: "Previous Phase: $HANDOFF" }
```

**Benefits**: Eliminates 200-300 tokens per transition, preserves agent's structure.

**Context Pruning Example** (Standard 8):

Without pruning (29,000 tokens accumulated):
```bash
# Research: 15,000 tokens
# Planning: +3,000 = 18,000 tokens
# Implementation: +10,000 = 28,000 tokens
# Documentation: +1,000 = 29,000 tokens
```

With aggressive pruning (1,500 tokens):
```bash
# After research: prune to metadata (750 tokens)
prune_subagent_output "$output" "$METADATA"

# After planning: prune to metadata (1,000 tokens total)
prune_phase_metadata --keep-recent 1

# After implementation: (1,500 tokens total)
prune_phase_metadata --keep-recent 0
```

**Benefits**: 29,000 tokens → 1,500 tokens (95% reduction), enables long-running workflows.

---

## Common Mistakes and Solutions

This section documents frequent errors when developing commands and their resolutions.

### Mistake 1: Agent Invocation Wrapped in Code Blocks

**Problem**: Agent invocations placed inside markdown code fences (```yaml```) prevent execution.

❌ **Incorrect**:
```markdown
Research should be conducted as follows:

```yaml
Task {
  subagent_type: "general-purpose"
  ...
}
```
```

✅ **Correct**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-analyst.

Provide context via behavioral injection pattern:
- Read and follow: .claude/agents/research-analyst.md
- Inject operational context
- Signal completion with REPORT_CREATED:
```

**Solution**: Remove code fences, use imperative instructions, invoke Task tool directly.

**See**: [Standard 11: Imperative Agent Invocation](../reference/command_architecture_standards.md#standard-11)

### Mistake 2: Missing Verification Checkpoints

**Problem**: Files created without verification, leading to silent failures and 0% creation rate.

❌ **Incorrect**:
```bash
# Create report
cat > /path/to/report.md <<EOF
content
EOF

# Assume success, continue...
```

✅ **Correct**:
```bash
# Create report
cat > /path/to/report.md <<EOF
content
EOF

# MANDATORY VERIFICATION
if [ ! -f /path/to/report.md ]; then
  echo "ERROR: File creation failed"
  echo "FALLBACK: Attempting Write tool..."
  # Fallback mechanism
fi

# VERIFY CONTENT (not placeholder)
if grep -q "TODO" /path/to/report.md; then
  echo "ERROR: File contains placeholder content"
fi
```

**Solution**: Add verification after every file creation, implement fallback mechanisms.

**See**: [Verification and Fallback Pattern](../concepts/patterns/verification-fallback.md)

### Mistake 3: Using "Should/May/Can" Instead of "Must/Will/Shall"

**Problem**: Permissive language creates documentation instead of executable instructions.

❌ **Incorrect**:
```markdown
The command should create a report.
Agents may be invoked for research.
You can use the behavioral injection pattern.
```

✅ **Correct**:
```markdown
The command MUST create a report.
Agents WILL be invoked for research.
You SHALL use the behavioral injection pattern.
```

**Solution**: Replace all permissive language with imperative directives.

**See**: [Imperative Language Guide](imperative-language-guide.md)

### Mistake 4: Invoking Commands with SlashCommand Tool

**Problem**: Commands invoking other commands via SlashCommand create role ambiguity and context bloat.

❌ **Incorrect**:
```yaml
SlashCommand { command: "/research topic" }
```

✅ **Correct**:
```yaml
Task {
  subagent_type: "general-purpose"
  prompt: "
    Read and follow: .claude/agents/research-analyst.md
    You are acting as Research Analyst.

    Research the following topic: [details]...
  "
}
```

**Solution**: Use Task tool with behavioral injection pattern instead of SlashCommand.

**See**: [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md)

### Mistake 5: Missing Completion Signals

**Problem**: Agents complete work but supervisors can't detect completion, leading to workflow hangs.

❌ **Incorrect**:
```markdown
Agent prompt:
"Research authentication patterns and create a report."
```

✅ **Correct**:
```markdown
Agent prompt:
"Research authentication patterns and create a report.

SIGNAL COMPLETION: When research is complete, output:
REPORT_CREATED: /full/path/to/report.md"
```

**Solution**: Always require explicit completion signals (REPORT_CREATED:, PLAN_CREATED:, etc.).

**See**: [Behavioral Injection Pattern - Completion Signals](../concepts/patterns/behavioral-injection.md#completion-signals)

### Mistake 6: Passing Full Content Instead of Metadata

**Problem**: Passing full report/plan content between agents causes context bloat.

❌ **Incorrect** (15,000 tokens):
```yaml
prompt: "
  Previous research findings:
  [Full 15,000 token report content pasted here]

  Use these findings to create plan...
"
```

✅ **Correct** (750 tokens):
```yaml
prompt: "
  Previous research: See .claude/specs/027/reports/001_auth.md

  Summary: OAuth 2.0 recommended for API authentication
  Key findings: [50-word summary]

  Use report reference to create plan...
"
```

**Solution**: Pass metadata (path + 50-word summary), not full content. 95% context reduction.

**See**: [Metadata Extraction Pattern](../concepts/patterns/metadata-extraction.md)

### Mistake 7: No Fail-Fast Error Handling

**Problem**: Errors in early steps propagate silently, causing cascading failures.

❌ **Incorrect**:
```bash
mkdir -p /path/to/dir
cd /path/to/dir
cat > report.md <<EOF
content
EOF
# No error checking
```

✅ **Correct**:
```bash
set -e  # Exit on error

mkdir -p /path/to/dir || {
  echo "ERROR: Failed to create directory"
  exit 1
}

cd /path/to/dir || {
  echo "ERROR: Failed to change directory"
  exit 1
}

cat > report.md <<EOF
content
EOF

[ -f report.md ] || {
  echo "ERROR: File creation failed"
  exit 1
}
```

**Solution**: Use `set -e`, check critical operations, fail fast with clear messages.

**See**: [Error Handling Flowchart](../quick-reference/error-handling-flowchart.md)

### Mistake 8: Relative Paths Without Verification

**Problem**: Relative paths break when working directory changes unexpectedly.

❌ **Incorrect**:
```bash
cat reports/001_findings.md  # Assumes current directory
```

✅ **Correct**:
```bash
# Option 1: Use absolute paths
cat /home/benjamin/.config/.claude/specs/027/reports/001_findings.md

# Option 2: Verify working directory
pwd  # Confirm location
ls reports/ || {
  echo "ERROR: reports/ directory not found in $(pwd)"
  exit 1
}
cat reports/001_findings.md
```

**Solution**: Prefer absolute paths, verify working directory, check paths exist.

**See**: [Error Handling Flowchart - File Errors](../quick-reference/error-handling-flowchart.md#b-file-operation-errors)

### Mistake 9: Synchronous Agent Dependencies

**Problem**: Launching agents sequentially when they could run in parallel, missing 40-60% time savings.

❌ **Incorrect** (sequential, 120 min):
```yaml
Task { research OAuth }    # 40 min
Task { research JWT }      # 40 min
Task { research sessions } # 40 min
```

✅ **Correct** (parallel, 40 min):
```yaml
# Launch all three in single message (parallel execution)
Task { research OAuth }
Task { research JWT }
Task { research sessions }
```

**Solution**: Launch independent agents in parallel (single message, multiple Task blocks).

**See**: [Parallel Execution Pattern](../concepts/patterns/parallel-execution.md)

### Mistake 10: Excessive Template Content Inline

**Problem**: Duplicating large templates in command files instead of referencing agent behavior files.

❌ **Incorrect** (3,000 lines duplicated):
```markdown
## Agent Prompt Template

[3,000 lines of agent behavior pasted inline]
```

✅ **Correct** (reference):
```markdown
## Agent Invocation

Agents MUST follow behavioral specifications:

- Research: `.claude/agents/research-analyst.md`
- Planning: `.claude/agents/plan-architect.md`
- Implementation: `.claude/agents/implementation-researcher.md`

Use behavioral injection pattern to reference these files.
```

**Solution**: Reference agent behavioral files, don't duplicate inline.

**See**: [Standard 7: Reference Don't Duplicate](../reference/command_architecture_standards.md#standard-7)

### Quick Diagnostic Checklist

When command isn't working as expected, check:

- [ ] Agent invocations use imperative pattern (not code blocks)
- [ ] File creation has verification checkpoints
- [ ] All required actions use MUST/WILL/SHALL
- [ ] Agents invoked via Task tool (not SlashCommand)
- [ ] Completion signals required (REPORT_CREATED:, etc.)
- [ ] Metadata passed instead of full content
- [ ] Fail-fast error handling (`set -e`, explicit checks)
- [ ] Absolute paths used or working directory verified
- [ ] Independent agents launched in parallel
- [ ] Templates referenced, not duplicated inline

### Troubleshooting Resources

- [Agent Delegation Troubleshooting](../troubleshooting/agent-delegation-troubleshooting.md) - Complete delegation debug guide
- [Orchestration Troubleshooting](../guides/orchestration-troubleshooting.md) - Workflow debugging
- [Error Handling Flowchart](../quick-reference/error-handling-flowchart.md) - Quick error diagnosis
- [Command Architecture Standards](../reference/command_architecture_standards.md) - All 11 standards

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
