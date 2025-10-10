---
command-type: example
description: Template showing proper agent invocation via registry
allowed-tools: Read, Write, Edit, Bash, Task
---

# Example Command with Agent Registry

This is a template demonstrating how to invoke custom agents using the agent registry system.

## Overview

Since Claude Code's Task tool only supports built-in subagent types (`general-purpose`, `statusline-setup`, `output-style-setup`), we use the agent registry to load custom agent definitions and invoke them via `general-purpose`.

## Pattern 1: Using Agent Registry in Lua-based Workflows

For Neovim-based commands or workflows:

```lua
local agent_registry = require('neotex.plugins.ai.claude.agent_registry')

-- Get agent definition
local agent = agent_registry.get_agent('code-writer')

if not agent then
  print('Agent not found: code-writer')
  return
end

-- Option A: Format task prompt manually
local task_prompt = agent.system_prompt .. "\n\n" ..
                    "Task: Implement feature X\n\n" ..
                    "Context:\n" ..
                    "- Files: foo.lua, bar.lua\n" ..
                    "- Requirements: Follow project standards"

-- Option B: Use helper function
local task_prompt = agent_registry.format_task_prompt(
  'code-writer',
  'Implement feature X',
  'Files: foo.lua, bar.lua\nRequirements: Follow project standards'
)

-- Option C: Generate complete task config
local task_config = agent_registry.create_task_config(
  'code-writer',
  'Implement feature X',
  'Files: foo.lua, bar.lua\nRequirements: Follow project standards'
)

-- task_config contains:
-- {
--   subagent_type = "general-purpose",
--   description = "Implement feature X",  -- Auto-shortened to 3-5 words
--   prompt = "[agent system prompt + task + context]"
-- }
```

## Pattern 2: Using Agent Registry in Markdown Commands

For commands defined in `.claude/commands/*.md`:

```markdown
## Process

### 1. Load Agent Definition

First, determine which agent to use for this task. For code writing tasks, use the `code-writer` agent.

### 2. Prepare Task Context

Define the specific task and context:
- **Task**: Implement user authentication module
- **Context**:
  - Files to modify: auth.lua, user.lua
  - Requirements: Use bcrypt for hashing
  - Standards: Follow project Lua style guide

### 3. Invoke Agent via Task Tool

Use the agent registry to format the prompt:

Task {
  subagent_type: general-purpose
  description: "Implement user authentication module"
  prompt: "[Load code-writer agent system prompt]

Task: Implement user authentication module

Context:
- Files to modify: auth.lua, user.lua
- Requirements: Use bcrypt for password hashing
- Standards: Follow project Lua style guide from CLAUDE.md

Deliverables:
- Updated auth.lua with authentication logic
- Updated user.lua with user model
- Tests for authentication flow
  "
}
```

## Pattern 3: Multiple Agents in Sequence

For workflows requiring multiple specialized agents:

```lua
local agent_registry = require('neotex.plugins.ai.claude.agent_registry')

-- Phase 1: Research with research-specialist
local research_config = agent_registry.create_task_config(
  'research-specialist',
  'Investigate authentication patterns in codebase',
  'Focus: Existing auth implementations and standards'
)

-- Phase 2: Implementation with code-writer
local code_config = agent_registry.create_task_config(
  'code-writer',
  'Implement authentication module based on research',
  'Use findings from research phase'
)

-- Phase 3: Documentation with doc-writer
local doc_config = agent_registry.create_task_config(
  'doc-writer',
  'Document new authentication module',
  'Update API docs and user guide'
)

-- Phase 4: Testing with test-specialist
local test_config = agent_registry.create_task_config(
  'test-specialist',
  'Create comprehensive authentication tests',
  'Cover happy path, error cases, security scenarios'
)
```

## Available Agents

Query available agents dynamically:

```lua
local agent_registry = require('neotex.plugins.ai.claude.agent_registry')

-- List all agent names
local agents = agent_registry.list_agents()
-- Returns: {"code-reviewer", "code-writer", "debug-specialist", ...}

-- Validate agent exists
if agent_registry.validate_agent('code-writer') then
  -- Safe to use
end

-- Get agent metadata without loading full prompt
local info = agent_registry.get_agent_info('doc-writer')
-- Returns: {name, description, allowed_tools, filepath}

-- Get just the tools list
local tools = agent_registry.get_agent_tools('test-specialist')
-- Returns: {"Read", "Bash", "TodoWrite"}
```

## Error Handling

Always check for nil returns:

```lua
local agent_registry = require('neotex.plugins.ai.claude.agent_registry')

local task_config = agent_registry.create_task_config(
  'nonexistent-agent',
  'Do something',
  'Context here'
)

if not task_config then
  print('Error: Agent not found')
  -- Provide fallback or error message
  return
end

-- Safe to use task_config
```

## Benefits of Agent Registry

1. **Single Source of Truth**: Agent definitions in `.claude/agents/*.md` are the authoritative source
2. **Easy Updates**: Modify agent behavior by editing the agent file
3. **Consistency**: All commands using an agent get the same behavior
4. **Validation**: Registry validates agent existence before use
5. **Caching**: Agent definitions are cached for performance
6. **Project Overrides**: Project agents automatically override global agents

## Notes

- Agent files must be in `.claude/agents/` (project) or `~/.config/.claude/agents/` (global)
- Agent filenames determine agent names (e.g., `code-writer.md` → `code-writer`)
- Always use `subagent_type: general-purpose` in Task tool calls
- The agent registry handles formatting and prompt composition
- Reload registry with `agent_registry.reload_registry()` if agent files change during session
