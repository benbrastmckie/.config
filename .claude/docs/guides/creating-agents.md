# Creating Custom Agents

Guide for creating and maintaining custom Claude Code agents.

## Overview

Custom agents are specialized AI assistants defined in `.claude/agents/*.md` files. They provide consistent, focused behavior for specific tasks like code writing, documentation, testing, or debugging.

## Agent File Structure

### Location

- **Project agents**: `.claude/agents/` (takes priority)
- **Global agents**: `~/.config/.claude/agents/` (fallback)

### File Format

```markdown
---
allowed-tools: Tool1, Tool2, Tool3
description: One-line description of agent purpose
---

# Agent Name

System prompt defining agent behavior and capabilities.

## Core Capabilities

[What this agent does]

## Standards Compliance

[Project-specific standards this agent follows]

## Behavioral Guidelines

[How this agent approaches tasks]

## Expected Input

[What information this agent needs to function effectively]

## Expected Output

[What format/structure this agent returns]
```

### Naming Convention

- **Filename**: `agent-name.md` (lowercase, hyphens)
- **Agent Name**: Derived from filename without `.md`
- **Display Name**: Formatted in agent file header

Examples:
- `code-writer.md` → agent name: `code-writer`
- `debug-specialist.md` → agent name: `debug-specialist`

## Frontmatter Fields

### allowed-tools (required)

Comma-separated list of tools the agent can use.

```yaml
allowed-tools: Read, Write, Edit, Bash, TodoWrite
```

**Common Tool Combinations**:

**Code Writer**: Read, Write, Edit, Bash, TodoWrite
**Documentation Writer**: Read, Write, Edit, Grep, Glob
**Research**: Read, Grep, Glob, WebSearch, WebFetch
**Testing**: Read, Bash, Grep, TodoWrite
**Debugging**: Read, Bash, Grep, Glob, WebSearch

**Rationale for Tool Combinations**: These groupings ensure agents have sufficient tools for their task while maintaining security through restriction. Inline requirements (Standard 1) mean agents must be self-contained with appropriate tool access, not relying on external helper agents.

**See Also**: [Command Architecture Standards](../reference/command_architecture_standards.md#agent-file-standards) for complete tool selection guidelines.

## Agent Output Requirements

### Metadata Extraction Compatibility

When designing agents for multi-agent workflows, ensure outputs are compatible with metadata extraction utilities:

**For Research Agents**:
```markdown
## Executive Summary
[50-word summary of findings - REQUIRED for extract_report_metadata()]

## Key Findings
- [Finding 1 with file:line references]
- [Finding 2 with file:line references]

## Recommendations
1. [Recommendation 1]
2. [Recommendation 2]
```

**For Planning Agents**:
```markdown
## Metadata
- **Complexity**: Low/Medium/High
- **Time Estimate**: N-M hours
- **Phases**: N

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2
```

**For Implementation Agents**:
```markdown
Output Format:
```
IMPLEMENTATION_COMPLETE: true
FILES_MODIFIED: [list]
TESTS_PASSED: [count]
```
```

**Why This Matters**: Structured outputs enable `extract_report_metadata()` and `forward_message()` utilities to extract metadata (path + 50-word summary) instead of passing full content between agents, achieving 99% context reduction.

**See Also**: [Hierarchical Agents Guide](../concepts/hierarchical_agents.md#metadata-extraction) for complete metadata extraction patterns.

### Structural Annotations (Standard 5)

Add annotations to agent file templates to guide future refactoring:

```markdown
## Behavioral Guidelines
[EXECUTION-CRITICAL: These guidelines define core agent behavior and must remain inline]

### Tool Usage
[INLINE-REQUIRED: Tool invocation patterns must stay in agent definition]

**Research Pattern**:
```bash
# ALWAYS search codebase before researching externally
grep -r "pattern" lib/ src/
```

### Output Format
[EXAMPLE-ONLY: Can be supplemented with external examples]

Return structured JSON with status, artifacts[], summary.
```

**Annotation Types**:
- `[EXECUTION-CRITICAL]` - Cannot be moved to external files
- `[INLINE-REQUIRED]` - Must stay inline for proper agent behavior
- `[REFERENCE-OK]` - Can be supplemented with external references
- `[EXAMPLE-ONLY]` - Can be moved to external files if core example remains

**See Also**: [Command Architecture Standards](../reference/command_architecture_standards.md#standard-5) for complete structural annotation guidelines.

### description (required)

Brief one-line description of agent's purpose.

```yaml
description: Specialized in writing and modifying code following project standards
```

**Best Practices**:
- Keep under 80 characters
- Focus on primary capability
- Mention key differentiator
- Use active voice

## System Prompt Structure

### 1. Introduction

Clear statement of agent identity and purpose.

```markdown
# Code Writer Agent

I am a specialized agent focused on generating and modifying code according to project standards. My role is to implement features, fix bugs, and make code changes while ensuring compliance with established conventions.
```

### 2. Core Capabilities

Detailed breakdown of what the agent does.

```markdown
## Core Capabilities

### Code Generation
- Write new modules, functions, and classes
- Create configuration files
- Generate boilerplate code following project patterns
- Implement features based on specifications

### Code Modification
- Refactor existing code for clarity or performance
- Fix bugs with targeted changes
- Update code to match new requirements
- Apply standards-compliant formatting
```

**Guidelines**:
- Use hierarchical structure (###, ####)
- List specific capabilities
- Include examples where helpful
- Be concrete, not vague

### 3. Standards Compliance

Reference to project standards the agent must follow.

```markdown
## Standards Compliance

I follow all guidelines in CLAUDE.md:
- Lua style: 2-space indent, snake_case naming
- Documentation: README.md in every directory
- Error handling: Use pcall for operations that might fail
- Testing: Comprehensive tests for all public APIs
```

**Best Practices**:
- Reference CLAUDE.md explicitly
- List specific standards relevant to agent
- Include language-specific requirements
- Mention testing expectations

### 4. Behavioral Guidelines

How the agent approaches tasks and makes decisions.

```markdown
## Behavioral Guidelines

### Task Management
- Break complex tasks into phases using TodoWrite
- Mark todos in_progress before starting work
- Complete todos immediately after finishing
- Keep one task in_progress at a time

### Code Quality
- Prefer editing existing files over creating new ones
- Follow DRY principle (Don't Repeat Yourself)
- Write clear, self-documenting code
- Add comments for complex logic only
```

**Guidelines**:
- Describe decision-making process
- Explain priorities and trade-offs
- Include workflow expectations
- Define quality standards

### 5. Expected Input

What information the agent needs to function effectively.

```markdown
## Expected Input

To function effectively, I need:
- **Task Description**: Clear statement of what to implement
- **Context**: Relevant files, functions, or modules
- **Requirements**: Specific constraints or standards to follow
- **Acceptance Criteria**: How to verify success

Example task format:
```
Task: Implement user authentication module

Context:
- Files: auth.lua, user.lua
- Database: PostgreSQL with pgcrypto extension
- Framework: Lua + OpenResty

Requirements:
- Use bcrypt for password hashing
- JWT tokens for session management
- Rate limiting on login attempts

Acceptance Criteria:
- All tests pass
- Documentation updated
- No security warnings from linter
```
```

**Best Practices**:
- Provide clear examples
- Specify required vs optional info
- Include format guidelines
- Show ideal input structure

### 6. Expected Output

What format/structure the agent returns.

```markdown
## Expected Output

I will deliver:

1. **Code Changes**: Modified or new files following project standards
2. **Tests**: Comprehensive test coverage for new functionality
3. **Documentation**: Updated README files and inline documentation
4. **Summary**: Brief description of changes made

Output format:
```
Completed: [Task description]

Changes:
- Modified: auth.lua (added bcrypt hashing)
- Modified: user.lua (added User model)
- Created: auth_spec.lua (authentication tests)
- Updated: README.md (authentication docs)

Testing: All tests pass (15/15)
```
```

**Guidelines**:
- Specify deliverables clearly
- Include success indicators
- Show output format
- Mention verification steps

## Creating a New Agent

### Step 1: Choose Agent Purpose

Identify the specific role and responsibilities.

**Questions to ask**:
- What tasks will this agent handle?
- What makes this agent different from existing agents?
- What specialized knowledge does it need?
- What tools will it require?

### Step 2: Define Agent File

Create `.claude/agents/new-agent.md`:

```markdown
---
allowed-tools: Read, Write, Edit
description: Brief description of agent purpose
---

# New Agent

System prompt content here...
```

### Step 3: Write System Prompt

Follow the structure above:
1. Introduction
2. Core Capabilities
3. Standards Compliance
4. Behavioral Guidelines
5. Expected Input
6. Expected Output

### Step 4: Test the Agent

Use the agent registry to verify it loads correctly:

```lua
local agent_registry = require('neotex.plugins.ai.claude.agent_registry')

-- Reload to pick up new agent
agent_registry.reload_registry()

-- Verify it exists
local agents = agent_registry.list_agents()
print(vim.inspect(agents))

-- Test loading
local agent = agent_registry.get_agent('new-agent')
if agent then
  print('Agent loaded successfully')
  print('Tools: ' .. table.concat(agent.allowed_tools, ', '))
else
  print('ERROR: Agent failed to load')
end
```

### Step 5: Create Test Task

Test with a simple task to verify behavior:

```lua
local task_config = agent_registry.create_task_config(
  'new-agent',
  'Simple test task',
  'Minimal context for testing'
)

print('Task config: ' .. vim.inspect(task_config))
```

## Best Practices

### DO

- **Be Specific**: Define clear, focused capabilities
- **Reference Standards**: Explicitly mention CLAUDE.md
- **Provide Examples**: Show expected input/output formats
- **Use Active Voice**: "I implement features" not "Features are implemented"
- **Test Thoroughly**: Verify agent loads and behaves correctly
- **Version Control**: Track agent changes in git
- **Document Updates**: Note when and why agent changed

### DON'T

- **Be Vague**: Avoid general statements like "I do things well"
- **Duplicate Existing Agents**: Check if capability exists first
- **Over-Promise**: Only list tools you actually need
- **Ignore Standards**: Always reference project conventions
- **Skip Testing**: Always verify agent loads correctly
- **Use Emojis**: Keep to UTF-8 text, no emoji characters

## Common Patterns

### Specialized Code Agent

Focus on specific language or framework:

```markdown
---
allowed-tools: Read, Write, Edit, Bash, Grep
description: Specialized in React TypeScript development
---

# React TypeScript Specialist

I am an expert in React and TypeScript, focused on building modern web applications following best practices.

## Core Capabilities
- Component development with hooks
- State management (Context, Redux, Zustand)
- Type-safe props and interfaces
- Performance optimization
- Accessibility (WCAG 2.1)
```

### Documentation Agent

Focus on writing and maintaining docs:

```markdown
---
allowed-tools: Read, Write, Edit, Grep, Glob
description: Maintains comprehensive project documentation
---

# Documentation Writer

I specialize in creating and maintaining clear, consistent documentation for software projects.

## Core Capabilities
- README files for all directories
- API documentation
- User guides and tutorials
- Architecture diagrams (Unicode box-drawing)
- Changelog maintenance
```

### Analysis Agent

Focus on investigation without modification:

```markdown
---
allowed-tools: Read, Grep, Glob, WebSearch, WebFetch
description: Analyzes codebases and provides insights
---

# Code Analyst

I conduct thorough analysis of codebases without making modifications, providing insights and recommendations.

## Core Capabilities
- Architecture analysis
- Dependency mapping
- Performance profiling
- Security auditing
- Best practice recommendations
```

## Troubleshooting

### Agent Not Loading

**Symptom**: `agent_registry.get_agent('my-agent')` returns nil

**Possible causes**:
1. Wrong filename or location
2. Malformed YAML frontmatter
3. Missing required fields

**Solution**:
```lua
-- Check available agents
local agents = agent_registry.list_agents()
print(vim.inspect(agents))

-- Reload registry
agent_registry.reload_registry()

-- Verify file exists
local path = require('plenary.path')
local agent_file = path:new('.claude/agents/my-agent.md')
print('File exists: ' .. tostring(agent_file:exists()))
```

### Tools Not Parsed

**Symptom**: `agent.allowed_tools` is empty

**Possible causes**:
1. Missing comma between tools
2. Wrong field name (should be `allowed-tools` with hyphen)
3. Malformed frontmatter

**Solution**: Check frontmatter format:
```markdown
---
allowed-tools: Read, Write, Edit
---
```

### Agent Behaving Incorrectly

**Symptom**: Agent not following instructions

**Possible causes**:
1. System prompt too vague
2. Conflicting instructions
3. Missing context in task invocation

**Solution**:
1. Review system prompt for clarity
2. Add specific examples
3. Include more context when creating task

## Resources

- **Agent Registry API**: `nvim/lua/neotex/plugins/ai/claude/agent_registry.lua`
- **Usage Examples**: `.claude/commands/example-with-agent.md`
- **Research Report**: `specs/reports/035_custom_agent_invocation_in_claude_code.md`
- **Implementation Plan**: `specs/plans/025_agent_registry_with_dynamic_loading.md`
- **Existing Agents**: `.claude/agents/*.md` - Study these for reference

## Maintenance

### Updating Existing Agents

1. Edit agent file in `.claude/agents/`
2. Test with agent registry
3. Commit changes to version control
4. Document what changed and why

### Deprecating Agents

If an agent is no longer needed:

1. Move to `.claude/agents/deprecated/`
2. Update any commands that used it
3. Document deprecation reason
4. Keep file for historical reference

### Agent Versioning

Add version info to frontmatter:

```yaml
---
allowed-tools: Read, Write, Edit
description: Code writer agent
version: 2.0
last-updated: 2025-10-01
---
```
