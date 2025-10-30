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

### 7.2 When to Use Inline Templates

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

### 7.3 Anti-Patterns to Avoid

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

### 7.4 Dry-Run Mode Examples

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

### 7.5 Dashboard Progress Examples

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

### 7.6 Checkpoint Save/Restore Examples

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

### 7.7 Test Execution Patterns

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

### 7.8 Git Commit Patterns

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

### 7.9 Context Preservation Examples

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
