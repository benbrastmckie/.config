# Creating Claude Code Commands

Comprehensive guide for developing custom slash commands with standards integration, agent coordination, and testing protocols.

## Table of Contents

1. [Introduction](#1-introduction)
2. [Command Architecture](#2-command-architecture)
3. [Command Development Workflow](#3-command-development-workflow)
4. [Standards Integration](#4-standards-integration)
5. [Agent Integration](#5-agent-integration)
6. [Testing and Validation](#6-testing-and-validation)
7. [Common Patterns and Examples](#7-common-patterns-and-examples)
8. [References](#references)

For a quick reference of all available commands, see [Command Quick Reference](command-reference.md).

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

### 2.3 Command Types

#### Decision Criteria

| Type | When to Use | User Frequency | Complexity | Example |
|------|-------------|----------------|------------|---------|
| Primary | Core development workflow | Daily | High | /implement |
| Support | Specialized assistance | Weekly | Medium | /debug |
| Workflow | State management | Per-feature | Medium | /revise |
| Utility | Maintenance, setup | Monthly | Low | /setup |

#### Migration Path

Commands can be promoted as they mature:
1. **utility** → Use internally, low visibility
2. **support** → Proven useful, document well
3. **workflow** → Integrates with main workflows
4. **primary** → Core to development process

### 2.4 Tools and Permissions

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

### 2.5 Behavioral Guidelines Structure

Commands have these standard sections:

#### Required Sections

1. **Purpose statement**: Clear objective
2. **Usage syntax**: Command invocation format
3. **Workflow**: Step-by-step procedure
4. **Output**: Expected results

#### Optional Sections (add as needed)

5. **Standards Discovery**: How standards are found and applied
6. **Agent Integration**: Which agents are used and why
7. **Testing**: Validation procedures
8. **Error Handling**: Failure recovery strategies
9. **Examples**: Concrete usage scenarios

#### Behavioral Guidelines Template

```markdown
## Workflow

### Step 1: [Action Name]
**Objective**: [What this step accomplishes]

**Actions**:
1. [Specific action]
2. [Specific action]

**Tools used**: [Tool names]

**Expected output**: [What gets created/modified]

### Step 2: [Action Name]
...
```

---

## 3. Command Development Workflow

### 3.1 Standards Discovery and Integration

#### 5-Step Standards Integration Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: Locate CLAUDE.md                                    │
│ Search upward from working directory                         │
│ - ./CLAUDE.md                                                │
│ - ../CLAUDE.md                                               │
│ - ../../CLAUDE.md (until repository root)                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│ Step 2: Check Subdirectory Standards                        │
│ Look for directory-specific overrides                        │
│ - src/frontend/CLAUDE.md (more specific)                     │
│ - CLAUDE.md (general)                                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│ Step 3: Parse Relevant Sections                             │
│ Extract sections used by command                             │
│ - Code Standards (indentation, naming)                       │
│ - Testing Protocols (test commands)                          │
│ - Documentation Policy (README requirements)                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│ Step 4: Apply Standards During Execution                    │
│ - Code generation follows conventions                        │
│ - Tests run using discovered commands                        │
│ - Documentation matches format                               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│ Step 5: Verify Compliance Before Completion                 │
│ - Check code style matches standards                         │
│ - Ensure tests pass                                          │
│ - Validate documentation completeness                        │
└─────────────────────────────────────────────────────────────┘
```

#### Implementation Example

```bash
# Search for CLAUDE.md
find_claude_md() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/CLAUDE.md" ]; then
      echo "$dir/CLAUDE.md"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

# Extract Code Standards section
grep -A 20 "## Code Standards" "$CLAUDE_MD_PATH"
```

### 3.2 Command Selection Decision Tree

Use this decision tree when users need to modify plans or reports:

```
Need to modify plan or report?
│
├─ Content changes (add/modify/remove information)?
│  └─ Use: /revise
│     Examples:
│     - Add tasks to phase
│     - Update phase objectives
│     - Add new phase
│     - Update report findings
│
└─ Structural changes (reorganize files)?
   ├─ Make phase/stage MORE detailed (separate file)?
   │  └─ Use: /expand
   │     Examples:
   │     - Phase has 15+ tasks
   │     - Phase becoming complex
   │     - Extract stage to file
   │
   └─ Make phase/stage LESS detailed (merge to parent)?
      └─ Use: /collapse
         Examples:
         - Phase now simple (3 tasks)
         - Simplify structure
         - Merge stage back
```

#### Common Scenarios

**Scenario 1: Add database migration task**
- Type: Content change
- Command: `/revise "Add database migration task to Phase 2"`
- Reason: Adding task is content, not structure

**Scenario 2: Phase has 15 tasks, hard to track**
- Type: Structural problem
- Command: `/expand phase specs/plans/025_feature.md 3`
- Reason: Extract phase for better organization

**Scenario 3: Update research findings**
- Type: Content change
- Command: `/revise "Update security findings" specs/reports/010_*.md`
- Reason: Modifying report content

### 3.3 Development Process Steps

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
- Define agent invocation patterns
- Document context passing
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

### 3.4 Quality Checklist

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
- [ ] Invocation patterns documented
- [ ] Context passing explained
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

### 4.2 Required Sections

#### Discovery Process
**Purpose**: Explains how standards are found

**Content**:
- Search algorithm (upward directory traversal)
- Subdirectory override behavior
- Section parsing approach
- Fallback strategy

#### Standards Sections Used
**Purpose**: Documents which CLAUDE.md sections the command consumes

**Content**: List each section with:
- Section name
- What content is extracted
- How it influences command behavior

**Example**:
```markdown
- **Code Standards**: Extracts indentation (2 spaces), naming (snake_case),
  error handling (pcall). Applied during code generation to ensure consistency.
```

#### Application
**Purpose**: Shows concrete examples of standards in action

**Content**: Specific scenarios where standards change command behavior

**Example**:
```markdown
When CLAUDE.md specifies:
- Indentation: 2 spaces → Generated code uses 2 spaces
- Test Command: :TestSuite → Command runs :TestSuite after changes
```

#### Compliance Verification
**Purpose**: Defines how standards adherence is checked

**Content**: Checklist of validation steps before completion

#### Fallback Behavior
**Purpose**: Handles missing or incomplete standards gracefully

**Content**: Strategy when CLAUDE.md absent or lacks required sections

### 4.3 Terminology Guidelines

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

**Glossary**:
- **CLAUDE.md**: Project standards file in repository
- **Standards discovery**: Process of locating and parsing CLAUDE.md
- **Standards application**: Using discovered standards during execution
- **Subdirectory override**: More specific CLAUDE.md overrides parent
- **Fallback**: Behavior when CLAUDE.md missing or incomplete

### 4.4 Standards Discovery Implementation

#### Bash Implementation Example

```bash
#!/bin/bash

# Find CLAUDE.md starting from current directory
find_claude_md() {
  local dir="$PWD"
  local found_files=()

  # Search upward until repository root
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/CLAUDE.md" ]; then
      found_files+=("$dir/CLAUDE.md")
    fi

    # Stop at git repository root
    if [ -d "$dir/.git" ]; then
      break
    fi

    dir=$(dirname "$dir")
  done

  # Return most specific (first found)
  if [ ${#found_files[@]} -gt 0 ]; then
    echo "${found_files[0]}"
    return 0
  fi

  return 1
}

# Extract section from CLAUDE.md
extract_section() {
  local file="$1"
  local section="$2"

  # Extract from section heading to next same-level heading or EOF
  awk -v section="$section" '
    /^## / {
      if ($0 ~ section) { found=1; next }
      else if (found) { exit }
    }
    found { print }
  ' "$file"
}

# Usage example
if CLAUDE_MD=$(find_claude_md); then
  echo "Found CLAUDE.md: $CLAUDE_MD"

  # Extract Code Standards
  CODE_STANDARDS=$(extract_section "$CLAUDE_MD" "Code Standards")

  # Extract Testing Protocols
  TEST_PROTOCOLS=$(extract_section "$CLAUDE_MD" "Testing Protocols")
else
  echo "CLAUDE.md not found, using defaults"
  # Apply language-specific defaults
fi
```

### 4.5 Fallback Behavior

#### Fallback Strategy Flowchart

```
Command starts
     │
     ↓
Search for CLAUDE.md
     │
     ├─ Found ────────┐
     │                ↓
     │           Parse sections
     │                ↓
     │           Use standards
     │                ↓
     │           Execute command
     │
     └─ Not found ───┐
                     ↓
          Log: "CLAUDE.md not found"
                     ↓
          Use language defaults:
          - Python: PEP 8
          - JavaScript: 2 spaces, camelCase
          - Lua: 2 spaces, snake_case
                     ↓
          Suggest: "Run /setup to create CLAUDE.md"
                     ↓
          Execute command with defaults
```

#### Language-Specific Defaults

| Language | Indentation | Naming | Line Length | Error Handling |
|----------|-------------|--------|-------------|----------------|
| Python | 4 spaces | snake_case | 79 chars | try/except |
| JavaScript | 2 spaces | camelCase | 80 chars | try/catch |
| Lua | 2 spaces | snake_case | 100 chars | pcall |
| Shell | 2 spaces | snake_case | 80 chars | set -e |
| Go | tabs | camelCase | 120 chars | if err != nil |

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

#### Command-Agent Relationship Matrix

| Command | Agents Used | Purpose | Invocation Type |
|---------|-------------|---------|-----------------|
| /report | research-specialist | Web research, codebase analysis | Single |
| /plan | plan-architect | Create structured plans | Single |
| /plan (with research) | research-specialist → plan-architect | Research then plan | Sequential |
| /implement | code-writer | Code generation by phase | Sequential |
| /orchestrate | All agents | Full workflow coordination | Parallel + Sequential |
| /debug | debug-specialist | Issue investigation | Single |
| /document | doc-writer | Documentation updates | Single |
| /refactor | code-analyzer | Code quality analysis | Single |
| /test | test-specialist | Test creation and execution | Single |

### 5.2 Agent Invocation Patterns

**Reference**: See detailed patterns in [command-patterns.md#agent-invocation-patterns](command-patterns.md#agent-invocation-patterns)

#### Essential Invocation Template

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Brief task (3-5 words)"
  prompt: "Read and follow behavioral guidelines from:
          /path/to/.claude/agents/agent-name.md

          You are acting as [Agent Name] with the tools and
          constraints defined in that file.

          [Specific task instructions]

          Context:
          - [Context item 1]
          - [Context item 2]

          Expected Output:
          [Format and deliverables]
  "
}
```

**Key components**:
1. **Behavioral guidelines reference**: Points to agent definition file
2. **Role assignment**: Explicit agent identity
3. **Task context**: Relevant project information
4. **Clear objective**: What needs to be accomplished
5. **Output format**: Structure of expected results

### 5.3 Behavioral Injection

**Concept**: Commands inject behavioral guidelines into agent prompts to ensure agents operate within defined constraints and use appropriate tools.

**Why it works**:
- Agents read their definition file at task start
- Definition specifies allowed tools and constraints
- Clear role assignment ensures focused execution
- Context passing provides necessary information

**Example**:

```markdown
Read and follow the behavioral guidelines from:
/home/benjamin/.config/.claude/agents/research-specialist.md

You are acting as a research specialist with the tools and
constraints defined in that file.

## Task
Research existing authentication patterns in the codebase.

## Context
- Project: User management system
- Focus: OAuth 2.0 implementation
- Existing code: src/auth/

## Expected Output
Markdown report with:
1. Current authentication approach
2. Identified patterns
3. Recommendations for OAuth integration
```

### 5.4 Agent Selection Criteria

#### Decision Table

| Need | Agent | Tools | Typical Output | When to Use |
|------|-------|-------|----------------|-------------|
| Research | research-specialist | Read, Grep, Glob, WebSearch | Report file | Understanding needed |
| Planning | plan-architect | Read, Write, Bash | Plan file | Structured plan needed |
| Implementation | code-writer | Read, Edit, Write, Bash | Code changes | Feature implementation |
| Testing | test-specialist | Read, Write, Bash | Test files | Test creation |
| Documentation | doc-writer | Read, Edit, Write | README updates | Doc synchronization |
| Debugging | debug-specialist | Read, Grep, Bash | Debug report | Issue investigation |
| GitHub | github-specialist | Read, Bash | PR, issues | GitHub operations |

#### Complexity Scoring

Use this scoring to decide whether to delegate to agent:

| Factor | Points | Threshold |
|--------|--------|-----------|
| Multiple files (3+) | +2 | |
| Research required | +3 | |
| Complex logic | +2 | |
| Standards application | +1 | |
| Testing needed | +1 | |
| **Total ≥ 5** | **Delegate to agent** | |
| **Total < 5** | **Direct execution** | |

**Example**:
- Feature: Add authentication (4 files, research needed, complex, tests)
- Score: 2 + 3 + 2 + 1 = 8 points
- **Decision**: Delegate to code-writer agent

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

#### Expected CLAUDE.md Format

```markdown
## Testing Protocols

### Test Commands
- Full suite: `.claude/tests/run_all_tests.sh`
- Single test: `.claude/tests/test_specific.sh`
- Coverage: `coverage run && coverage report`

### Test Patterns
- Test files: `test_*.sh`
- Test location: `.claude/tests/`

### Coverage Requirements
- New code: ≥80% coverage
- Baseline: ≥60% coverage
```

### 6.2 Command-Specific Test Requirements

#### By Command Type

**Primary Commands**:
- [ ] End-to-end workflow test
- [ ] Standards discovery test
- [ ] Output validation test
- [ ] Error handling test
- [ ] Resumability test (if applicable)

**Support Commands**:
- [ ] Input validation test
- [ ] Output format test
- [ ] Edge case handling
- [ ] Error recovery test

**Workflow Commands**:
- [ ] State management test
- [ ] File structure test
- [ ] Metadata update test
- [ ] Rollback capability test

**Utility Commands**:
- [ ] Configuration test
- [ ] Validation test
- [ ] Help output test

### 6.3 Validation Checklist

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
- [ ] Agents invoked correctly
- [ ] Context passed completely
- [ ] Results processed correctly
- [ ] Errors handled gracefully

**User Experience**:
- [ ] Clear progress indicators
- [ ] Helpful error messages
- [ ] Appropriate logging
- [ ] Expected completion message

### 6.4 Manual Testing Procedures

#### Test Procedure Template

```markdown
## Manual Test: [Test Name]

### Setup
1. [Preparation step]
2. [Create test environment]

### Execution
1. Run: `/command <args>`
2. [Monitor output]
3. [Check intermediate results]

### Expected Results
- [Expected output 1]
- [Expected file creation/modification]
- [Expected final state]

### Cleanup
1. [Remove test artifacts]
2. [Reset environment]

### Pass Criteria
- [ ] All expected outputs present
- [ ] No errors in execution
- [ ] State transitions correct
```

#### Example: Test /plan Command

```markdown
## Manual Test: Plan Creation with Research

### Setup
1. Create test report: `specs/reports/test/001_auth_research.md`
2. Ensure CLAUDE.md exists with Code Standards section
3. Clear any existing plans

### Execution
1. Run: `/plan "Add OAuth authentication" specs/reports/test/001_auth_research.md`
2. Monitor for:
   - Standards discovery message
   - Research report reference
   - Phase generation progress
3. Check created plan file

### Expected Results
- Plan file created: `specs/plans/NNN_oauth_authentication.md`
- Plan metadata includes:
  - Standards File reference
  - Research report link
  - Phase count (3-5 phases expected)
- Plan follows CLAUDE.md conventions:
  - Code style matches project
  - Test commands from Testing Protocols

### Cleanup
1. Remove test plan: `rm specs/plans/NNN_oauth_authentication.md`
2. Remove test report: `rm specs/reports/test/001_auth_research.md`

### Pass Criteria
- [x] Plan created with correct structure
- [x] Standards referenced in plan
- [x] Research report linked
- [x] No errors during execution
```

---

## 7. Common Patterns and Examples

### 7.1 Pattern Categories

For detailed implementation patterns, see [command-patterns.md](command-patterns.md):

- **Agent Invocation Patterns**: Basic, parallel, sequential agent chains
- **Checkpoint Management**: Saving and restoring state
- **Error Recovery**: Automatic retry, error classification
- **Artifact Referencing**: Pass-by-reference for large outputs
- **Testing Integration**: Test discovery, phase-by-phase testing
- **Progress Streaming**: TodoWrite integration, progress markers
- **Standards Discovery**: Upward search, section extraction
- **Logger Initialization**: Setup with fallbacks
- **Pull Request Creation**: GitHub CLI integration
- **Parallel Execution Safety**: Wave-based execution with fail-fast

### 7.2 Complete Command Example

Here's a fictional `/analyze-code` command demonstrating all concepts:

```markdown
---
allowed-tools: Read, Grep, Glob, Bash, Task, TodoWrite
argument-hint: <directory> [--complexity] [--coverage]
description: Analyze code quality and provide improvement recommendations
command-type: support
dependent-commands: refactor, test
---

# Analyze Code

Performs comprehensive code analysis including complexity metrics, test coverage, and standards compliance.

## Usage
/analyze-code <directory> [--complexity] [--coverage]

## Standards Discovery and Application

### Discovery Process
1. **Locate CLAUDE.md**: Search upward from target directory
2. **Check Subdirectory Standards**: Use directory-specific CLAUDE.md if exists
3. **Parse Relevant Sections**: Extract Code Standards, Testing Protocols
4. **Handle Missing Standards**: Use language-specific defaults

### Standards Sections Used
- **Code Standards**: Extract naming conventions, error handling patterns, indentation rules
- **Testing Protocols**: Extract coverage requirements, test patterns

### Application During Analysis
Code is analyzed against discovered standards:
- **Naming**: Verify functions/variables follow conventions
- **Indentation**: Check consistency with CLAUDE.md specification
- **Error Handling**: Identify missing error handling per standards
- **Coverage**: Compare actual coverage vs requirements

### Fallback Behavior
When CLAUDE.md missing:
1. Use language-specific defaults (PEP 8 for Python, etc.)
2. Suggest running `/setup` to create CLAUDE.md
3. Include note in report about which standards were applied

## Agent Integration

This command uses the code-analyzer agent for complex analysis:

```
Task {
  subagent_type: "general-purpose"
  description: "Analyze code quality metrics"
  prompt: "Read and follow behavioral guidelines from:
          /path/to/.claude/agents/code-analyzer.md

          You are acting as a code analyzer with the tools
          defined in that file.

          ## Task
          Analyze code in <directory> for:
          1. Complexity metrics
          2. Standards compliance
          3. Test coverage
          4. Improvement opportunities

          ## Standards Reference
          Apply standards from: <CLAUDE.md path>

          ## Expected Output
          Markdown report with sections:
          - Complexity Analysis
          - Standards Compliance
          - Coverage Report
          - Recommendations (prioritized)
  "
}
```

## Workflow

### Step 1: Initialize Analysis
**Objective**: Set up analysis environment and discover standards

**Actions**:
1. Validate target directory exists
2. Discover CLAUDE.md standards
3. Extract Code Standards and Testing Protocols
4. Initialize TodoWrite tracking

**Tools used**: Read, Bash, TodoWrite

### Step 2: Gather Code Metrics
**Objective**: Collect complexity, coverage, and standards data

**Actions**:
1. Scan directory for source files (Glob)
2. Calculate complexity metrics per file (Bash: cyclomatic complexity)
3. Run coverage analysis (Bash: coverage tool)
4. Check standards compliance (Grep: patterns)

**Tools used**: Glob, Bash, Grep

### Step 3: Invoke Analysis Agent
**Objective**: Generate comprehensive analysis report

**Actions**:
1. Prepare context (metrics, standards, files)
2. Invoke code-analyzer agent (Task)
3. Receive analysis report

**Tools used**: Task

### Step 4: Generate Recommendations
**Objective**: Create prioritized improvement list

**Actions**:
1. Parse agent report
2. Prioritize issues by severity
3. Link to refactor command for fixes
4. Create summary with next steps

**Tools used**: Read

## Output

Creates analysis report: `<directory>/analysis_report_YYYYMMDD.md`

Format:
```markdown
# Code Analysis Report: <directory>

Date: YYYY-MM-DD
Standards: <CLAUDE.md path>

## Complexity Analysis
- Total files: N
- High complexity: N files (list)
- Average complexity: X

## Standards Compliance
- Naming: X% compliant
- Error handling: X% compliant
- Indentation: X% compliant

## Test Coverage
- Current: X%
- Target: Y% (from CLAUDE.md)
- Uncovered files: (list)

## Recommendations
1. [High priority] Fix X
2. [Medium priority] Improve Y
3. [Low priority] Consider Z

## Next Steps
- Run `/refactor <file>` to address issues
- Run `/test <target>` to increase coverage
```

## Testing

### Validation
- [ ] Discovers CLAUDE.md correctly
- [ ] Analyzes all source files in directory
- [ ] Agent invocation successful
- [ ] Report generated with all sections
- [ ] Recommendations are actionable

### Test Command
```bash
# Create test directory with sample code
# Run: /analyze-code test_project --complexity --coverage
# Verify report created and contains expected sections
```

## Examples

### Example 1: Analyze with Standards
```
User: /analyze-code src/auth --complexity

Output:
- Discovered CLAUDE.md: /project/CLAUDE.md
- Code Standards: snake_case, 2 spaces, pcall
- Analyzing 15 files in src/auth...
- Invoking code-analyzer agent...
- Report created: src/auth/analysis_report_20251012.md

Findings:
- 3 files exceed complexity threshold
- 85% standards compliant
- 72% test coverage (target: 80%)

Recommendations:
1. Refactor login.lua (complexity: 15)
2. Add error handling to session.lua
3. Increase test coverage for oauth.lua
```

### Example 2: Analyze without CLAUDE.md
```
User: /analyze-code src/utils --coverage

Output:
- CLAUDE.md not found, using Lua defaults
- Suggestion: Run /setup to create CLAUDE.md
- Analyzing 8 files in src/utils...
- Using defaults: 2 spaces, snake_case, 60% coverage
- Report created: src/utils/analysis_report_20251012.md
```
```

### 7.3 Standards Integration Example

**Scenario**: Implementing /document command with standards integration

**Step-by-step walkthrough**:

#### Before: Command Without Standards
```markdown
# Document Command

Updates all README files in the project.

## Workflow
1. Find all README files
2. Update each with new content
3. Report completion
```

#### After: Command With Standards Integration

```markdown
# Document Command

Updates all README files following project Documentation Policy.

## Standards Discovery and Application

### Discovery Process
1. **Locate CLAUDE.md**: Search upward from working directory
2. **Parse Documentation Policy**: Extract README requirements and format rules
3. **Handle Missing Standards**: Use sensible defaults

### Standards Sections Used
- **Documentation Policy**: Extract README requirements (Purpose, Module Documentation, Usage Examples, Navigation Links), format rules (CommonMark, no emojis, Unicode box-drawing)

### Application During Documentation
Documentation Policy influences:
- **README Structure**: Ensures required sections present
- **Format**: Follows specified format (CommonMark, UTF-8)
- **Content**: Includes required elements (purpose, examples, links)

### Compliance Verification
Before completing:
- [ ] All required README sections present
- [ ] Format matches Documentation Policy
- [ ] No emojis (if specified in policy)
- [ ] Navigation links working

### Fallback Behavior
When Documentation Policy missing:
- Use standard README structure (Purpose, Usage, License)
- Follow CommonMark specification
- Suggest creating CLAUDE.md with /setup

## Workflow
1. Discover Documentation Policy from CLAUDE.md
2. Find all README files matching policy scope
3. Update each README following policy requirements
4. Verify compliance
5. Report completion with compliance summary
```

**Key improvements**:
- Explicit standards discovery
- Clear section usage documentation
- Application examples
- Compliance verification
- Fallback strategy

### 7.4 Agent Integration Example

**Scenario**: Using research-specialist agent in /report command

```markdown
## Workflow for /report Command

### Step 1: Invoke Research Agent

Delegate research to research-specialist agent:

Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: "Read and follow behavioral guidelines from:
          /home/benjamin/.config/.claude/agents/research-specialist.md

          You are acting as a research specialist with the tools
          and constraints defined in that file.

          ## Research Topic
          OAuth 2.0 authentication implementation best practices

          ## Focus Areas
          1. Industry best practices (2025 standards)
          2. Existing implementations in popular frameworks
          3. Security considerations
          4. Integration patterns

          ## Research Scope
          - Web search for current best practices
          - Code examples from established libraries
          - Security advisories and recommendations

          ## Expected Output
          Create research report file:
          - Path: specs/reports/auth_practices/001_oauth2_best_practices.md
          - Format: Markdown with sections for each focus area
          - Include: Links to sources, code examples, recommendations

          ## Success Criteria
          - Comprehensive coverage of OAuth 2.0 implementation
          - Recent sources (prefer 2024-2025)
          - Actionable recommendations for implementation
  "
}

### Step 2: Monitor Progress

Agent emits progress markers:
- PROGRESS: Searching for OAuth 2.0 best practices...
- PROGRESS: Analyzing security advisories...
- PROGRESS: Reviewing framework implementations...
- PROGRESS: Creating report file...

### Step 3: Validate Output

Check agent created report:
- File exists: specs/reports/auth_practices/001_oauth2_best_practices.md
- Contains all required sections
- Includes actionable recommendations
- Sources cited

### Step 4: Report Completion

Return to user:
- Report created: specs/reports/auth_practices/001_oauth2_best_practices.md
- Research coverage: OAuth 2.0 implementation, security, integration
- Key finding: [One-sentence summary]
- Ready for use in /plan command
```

**Key elements**:
1. **Behavioral injection**: Reference to agent definition file
2. **Clear task**: Specific research scope
3. **Expected output**: File creation with format
4. **Success criteria**: Quality requirements
5. **Progress monitoring**: Track agent progress
6. **Validation**: Verify deliverables

### 7.5 Anti-Patterns to Avoid

| Anti-Pattern | Why It's Wrong | Correct Approach |
|--------------|---------------|------------------|
| **Using /expand for content changes** | /expand changes structure (creates files), not content | Use /revise to add/modify tasks or objectives |
| **Using /revise for structural reorganization** | Creating separate files is structural | Use /expand to extract phases to files |
| **Including all possible tools** | Increases security risk, violates least privilege | Include only tools actually needed |
| **Duplicating pattern documentation** | Creates maintenance burden, outdated copies | Reference command-patterns.md with links |
| **Skipping standards discovery** | Inconsistent behavior across projects | Always discover and apply CLAUDE.md standards |
| **Hardcoding test commands** | Breaks in different projects | Discover test commands from CLAUDE.md |
| **Continuing after test failures** | Compounds issues in later phases | Stop, enter debugging loop, fix root cause |
| **Inline agent definitions** | Duplication across commands | Reference agent files via behavioral injection |
| **Large agent context passing** | Token waste | Use artifact referencing (pass paths, not content) |
| **Missing error handling** | Poor user experience on failures | Include retry logic and user escalation |

**Explanation Examples**:

**Anti-pattern**: Hardcoding test commands
```markdown
# BAD: Hardcoded test command
## Workflow
1. Implement feature
2. Run: `npm test`  # Hardcoded!
3. Commit if passing
```

**Correct approach**: Discover from CLAUDE.md
```markdown
# GOOD: Discovered test command
## Workflow
1. Implement feature
2. Discover test command from CLAUDE.md Testing Protocols
3. Run discovered test command (e.g., :TestSuite, npm test, pytest)
4. Commit if passing
```

---

## References

- **[Command Quick Reference](command-reference.md)** - Quick lookup for all commands
- **[Command Patterns](command-patterns.md)** - Reusable implementation patterns
- **[Agent Reference](agent-reference.md)** - Quick agent reference (created in Phase 4)
- **[Agent Development Guide](creating-agents.md)** - How to create agents (renamed from agent-development-guide.md in Phase 4)
- **[Standards Integration Guide](standards-integration.md)** - Standards integration details (created in Phase 4)
- **[Commands README](../commands/README.md)** - Complete command list and navigation

---

**Notes**:
- This guide consolidates command-standardization-checklist.md, command-standards-flow.md, and command-selection-guide.md
- For specific implementation patterns, always reference command-patterns.md rather than duplicating
- Follow the Development Philosophy: present-focused documentation, no historical markers
- Use Unicode box-drawing for diagrams, no emojis in content
- Maintain cross-references to related documentation
