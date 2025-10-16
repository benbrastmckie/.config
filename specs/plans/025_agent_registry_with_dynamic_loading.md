# ❌ OBSOLETE: Agent Registry with Dynamic Loading Implementation Plan

## Status: OBSOLETE - DO NOT IMPLEMENT

**Date Marked Obsolete**: 2025-10-01
**Reason**: Superseded by Workaround 1 (Natural Language Explicit Invocation)
**Replacement**: See `.claude/specs/reports/019_custom_agent_invocation_workarounds.md`

## Why This Plan Is Obsolete

Based on research documented in `specs/reports/036_agent_registry_relevance_analysis.md`:

1. **Agent registry only valuable for Neovim/Lua programmatic workflows** - Not needed for `.claude/commands/*.md` integration
2. **Commands should use Workaround 1** - Natural language invocation: `"Use the [agent-name] agent to [task]"`
3. **Parser already provides everything needed** - Agent scanning for picker display (no programmatic invocation required)
4. **User chose picker-centric approach** - Agent registry infrastructure removed by user decision (2025-10-01)

## Recommended Approach

For managing agents in `.claude/commands/*.md` files:

```markdown
# Instead of programmatic invocation (what this plan proposed)
Task {
  subagent_type: general-purpose
  prompt: "[AGENT_PROMPT:plan-architect] ..."
}

# Use natural language (Workaround 1 - simpler and better)
Use the plan-architect agent to create an implementation plan for $ARGUMENTS
```

## What To Use Instead

- **For commands**: Natural language explicit invocation (Workaround 1)
- **For picker**: Parser.lua provides agent scanning (already implemented)
- **For management**: Command picker (`<leader>ac`) manages all artifacts

---

## Original Plan Below (For Historical Reference Only)

## Metadata
- **Date**: 2025-10-01
- **Feature**: Hybrid agent registry system for clean agent invocation in commands
- **Scope**: Agent loader module, command integration, validation, testing
- **Estimated Phases**: 4
- **Complexity**: Medium
- **Standards File**: /home/benjamin/.config/CLAUDE.md, /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: /home/benjamin/.config/nvim/specs/reports/035_custom_agent_invocation_in_claude_code.md

## Overview

~~Implement Option 3 (Hybrid Approach with Agent Registry) from the research report to provide the best product experience for managing custom agents. This creates infrastructure for clean agent invocation without duplicating agent definitions across command files.~~

### Current State
- Custom agents defined in `.claude/agents/*.md` files (8 agents)
- Commands use `subagent_type: general-purpose` with inline prompts
- Agent definitions duplicated or manually copied into commands
- No centralized agent management

### Target State
- Lua module providing agent registry and loading
- Commands reference agents by name via helper module
- Single source of truth for agent definitions
- Automatic prompt generation from agent files
- Validation and error handling for missing/invalid agents

## Success Criteria
- [x] Agent loader module reads and caches agent definitions
- [x] Commands can invoke agents by name with clean syntax
- [x] Agent prompt includes full system prompt from file
- [x] Validation prevents invalid agent names
- [x] Documentation updated with usage examples
- [x] All 8 existing agents accessible via registry
- [x] Easy to add new agents without code changes

## Technical Design

### Architecture Decisions

#### Agent Registry Module
- **Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/agent_registry.lua`
- **Purpose**: Central registry for loading and caching agent definitions
- **Dependencies**: plenary.path for file operations
- **API**:
  - `get_agent(name)` - Load agent definition by name
  - `list_agents()` - List all available agents
  - `validate_agent(name)` - Check if agent exists
  - `get_agent_prompt(name)` - Extract system prompt only

#### Agent File Structure

Agents in `.claude/agents/*.md`:
```markdown
---
allowed-tools: Tool1, Tool2
description: Brief description
---

# Agent Name

System prompt content...
```

**Extracted Components**:
- `name`: From filename (e.g., `code-writer`)
- `description`: From YAML frontmatter
- `allowed_tools`: From YAML frontmatter (list)
- `system_prompt`: Everything after frontmatter
- `filepath`: Full path to agent file

#### Command Integration Pattern

**Before** (manual inline):
```markdown
Task {
  subagent_type: general-purpose
  prompt: "You are a code writer specialized in...
          [300 lines of agent definition]

          Task: Implement feature X"
}
```

**After** (using registry):
```markdown
Load agent: code-writer
Task context: Implement feature X with requirements Y

Generate task prompt using agent registry
Invoke with general-purpose subagent type
```

Or in Lua-based workflows:
```lua
local agent_registry = require('neotex.plugins.ai.claude.agent_registry')
local agent = agent_registry.get_agent('code-writer')

local task_prompt = agent.system_prompt .. "\n\nTask: Implement feature X"
```

### Data Structures

```lua
-- Agent definition structure
Agent = {
  name = "code-writer",
  description = "Specialized in writing...",
  allowed_tools = {"Read", "Write", "Edit", "Bash"},
  system_prompt = "I am a specialized agent focused on...",
  filepath = "/path/to/.claude/agents/code-writer.md"
}

-- Agent cache (in registry module)
local agent_cache = {
  ["code-writer"] = Agent,
  ["doc-writer"] = Agent,
  -- etc.
}
```

## Implementation Phases

### Phase 1: Agent Registry Module
**Objective**: Create core agent registry infrastructure
**Complexity**: Medium

Tasks:
- [ ] Create module file: `lua/neotex/plugins/ai/claude/agent_registry.lua`
- [ ] Add `scan_agent_directories()` function
  - Scan `.claude/agents/` (project) and `~/.config/.claude/agents/` (global)
  - Return list of agent filenames
  - Handle missing directories gracefully
- [ ] Add `parse_agent_file(filepath)` function
  - Use plenary.path to read file
  - Parse YAML frontmatter for metadata
  - Extract system prompt (content after frontmatter)
  - Return Agent structure or nil on error
- [ ] Add `build_agent_registry()` function
  - Scan agent directories
  - Parse each agent file
  - Build cache table keyed by agent name
  - Handle duplicates (project agents override global)
- [ ] Add `get_agent(name)` function
  - Lazy load on first call
  - Return cached agent if available
  - Return nil if agent not found
- [ ] Add `list_agents()` function
  - Return array of agent names
  - Sorted alphabetically
- [ ] Add `validate_agent(name)` function
  - Return true if agent exists
  - Return false otherwise
- [ ] Add `get_agent_prompt(name)` function
  - Return system_prompt field only
  - Return nil if agent not found
- [ ] Add error handling with pcall
  - Wrap file operations in pcall
  - Log errors but don't crash
  - Return nil on errors

Testing:
```lua
:lua local registry = require('neotex.plugins.ai.claude.agent_registry')
:lua local agents = registry.list_agents()
:lua vim.print(agents)
:lua local agent = registry.get_agent('code-writer')
:lua vim.print(agent.name, agent.description)
:lua vim.print(registry.get_agent_prompt('code-writer'))
```

Expected outcomes:
- Registry loads all 8 agents successfully
- Project agents override global if duplicates
- Graceful handling of missing agents
- Fast cached access after first load

### Phase 2: Helper Functions and Utilities
**Objective**: Add convenience functions for common agent operations
**Complexity**: Low

Tasks:
- [ ] Add `format_task_prompt(agent_name, task_description, context)` function
  - Load agent by name
  - Combine system prompt + task description + context
  - Return formatted prompt string
  - Handle missing agent gracefully
- [ ] Add `create_task_config(agent_name, task_description, context)` function
  - Generate complete task configuration
  - Return: `{ subagent_type = "general-purpose", description = ..., prompt = ... }`
  - 3-5 word description from task_description
  - Full prompt from agent + context
- [ ] Add `get_agent_tools(agent_name)` function
  - Return allowed_tools list
  - Return nil if agent not found
  - Useful for documenting agent capabilities
- [ ] Add `reload_registry()` function
  - Clear cache
  - Re-scan agent directories
  - Useful for development/testing
- [ ] Add `get_agent_info(agent_name)` function
  - Return agent metadata without full prompt
  - Lightweight alternative to get_agent()
  - Return: `{ name, description, allowed_tools, filepath }`
- [ ] Add module-level caching
  - Cache agent registry on first access
  - Provide `force_reload` parameter for refreshing

Testing:
```lua
:lua local registry = require('neotex.plugins.ai.claude.agent_registry')
:lua local prompt = registry.format_task_prompt('code-writer', 'Implement X', 'Requirements: Y')
:lua print(prompt:sub(1, 200))
:lua local config = registry.create_task_config('doc-writer', 'Update docs', 'Files: README.md')
:lua vim.print(config)
:lua print('Tools:', vim.inspect(registry.get_agent_tools('code-writer')))
```

Expected outcomes:
- Helper functions simplify agent usage
- Task configuration generation is automatic
- All functions handle errors gracefully

### Phase 3: Command Integration Examples
**Objective**: Update example commands to use agent registry
**Complexity**: Medium

Tasks:
- [ ] Create example helper script: `.claude/lib/invoke-agent.sh`
  - Bash wrapper for invoking agents from markdown commands
  - Reads agent definition and formats for Claude Code
  - Usage: `invoke-agent <agent-name> <task-description> <context-file>`
- [ ] Update `/orchestrate` command documentation
  - Add "Using Agent Registry" section
  - Show how to invoke agents via registry
  - Example with code-writer agent
- [ ] Update `/plan` command documentation
  - Show plan-architect agent usage via registry
  - Document task description format
- [ ] Update `/document` command documentation
  - Show doc-writer agent usage via registry
- [ ] Create example command template: `.claude/commands/example-with-agent.md`
  - Template showing proper agent invocation
  - Comments explaining each part
  - Copy-paste ready for new commands
- [ ] Update `/debug` command to use debug-specialist via registry
- [ ] Add agent registry usage to `/implement` command

Testing:
```bash
# Test bash helper
.claude/lib/invoke-agent.sh code-writer "Implement feature" "context.txt"

# Test in Neovim with updated commands
# Run each updated command and verify agent is properly invoked
```

Expected outcomes:
- Commands have clear, maintainable agent invocations
- No duplication of agent definitions
- Easy to understand and modify
- Template available for new commands

### Phase 4: Documentation and Testing
**Objective**: Complete documentation and comprehensive testing
**Complexity**: Low

Tasks:
- [ ] Create module documentation: `lua/neotex/plugins/ai/claude/README.md`
  - Document agent_registry module API
  - Include usage examples
  - Document data structures
- [ ] Update main project documentation
  - Add "Agent Registry" section to nvim/lua/neotex/plugins/ai/claude/README.md
  - Explain how to add new agents
  - Explain how to use agents in commands
- [ ] Create agent development guide: `.claude/docs/agent-development-guide.md`
  - How to create a new agent
  - Agent file structure and requirements
  - Best practices for agent design
  - How to test agents
- [ ] Add agent registry to CLAUDE.md standards
  - Document recommended agent usage pattern
  - Add to "Agent Usage" section
- [ ] Create test suite for agent registry
  - Test agent loading (valid and invalid)
  - Test caching behavior
  - Test override behavior (project vs global)
  - Test helper functions
  - Test error handling
- [ ] Add examples to `.claude/examples/` directory
  - Example 1: Simple agent invocation
  - Example 2: Agent with custom context
  - Example 3: Multiple agents in sequence
  - Example 4: Error handling
- [ ] Update agent files with standardized structure
  - Ensure all 8 agents have consistent format
  - Add "Expected Input" and "Expected Output" sections
  - Add version field to frontmatter

Testing:
```lua
-- Test suite (run in Neovim)
:lua local registry = require('neotex.plugins.ai.claude.agent_registry')

-- Test 1: Load all agents
:lua assert(#registry.list_agents() == 8)

-- Test 2: Get specific agent
:lua local agent = registry.get_agent('code-writer')
:lua assert(agent ~= nil and agent.name == 'code-writer')

-- Test 3: Invalid agent
:lua assert(registry.get_agent('nonexistent') == nil)

-- Test 4: Validation
:lua assert(registry.validate_agent('code-writer') == true)
:lua assert(registry.validate_agent('nonexistent') == false)

-- Test 5: Prompt extraction
:lua local prompt = registry.get_agent_prompt('doc-writer')
:lua assert(prompt and prompt:find('documentation'))

-- Test 6: Task config generation
:lua local config = registry.create_task_config('test-specialist', 'Run tests', 'File: foo.lua')
:lua assert(config.subagent_type == 'general-purpose')
:lua assert(config.prompt:find('test'))

-- Test 7: Reload
:lua registry.reload_registry()
:lua assert(#registry.list_agents() == 8)

-- Test 8: Agent tools
:lua local tools = registry.get_agent_tools('code-writer')
:lua assert(vim.tbl_contains(tools, 'Write'))
```

Expected outcomes:
- Complete, clear documentation
- All test cases pass
- Easy for others to understand and extend
- Agent files standardized

## Testing Strategy

### Unit Testing
- Test each registry function independently
- Mock file system for error conditions
- Verify caching behavior
- Test all helper functions

### Integration Testing
- Test with actual agent files
- Test from Neovim command invocation
- Test bash helper script
- Verify no performance degradation

### Edge Cases
- Missing agent files
- Malformed YAML frontmatter
- Empty agent files
- Duplicate agent names (project vs global)
- Special characters in agent names
- Very long system prompts
- Missing .claude/agents/ directory

## Documentation Requirements

### Code Documentation
- [ ] Add LuaLS annotations to all functions
- [ ] Add inline comments for complex logic
- [ ] Document expected return values
- [ ] Document error conditions

### User Documentation
- [ ] Agent Registry module README
- [ ] Agent Development Guide
- [ ] Usage examples in command files
- [ ] Update CLAUDE.md with patterns

### Developer Documentation
- [ ] Module architecture diagram
- [ ] Data flow documentation
- [ ] Extension points for custom behavior

## Dependencies

### External Dependencies
- plenary.nvim (already dependency)
- YAML frontmatter parser (existing from parser.lua)

### Internal Dependencies
- Uses parser.lua's parse_frontmatter function
- Follows patterns from parser.lua for consistency

### File Dependencies
- `.claude/agents/*.md` files
- `~/.config/.claude/agents/*.md` files

## Risk Assessment

### Medium Risk
- **Agent file format changes**: If agent format changes, registry breaks
  - Mitigation: Version field in frontmatter, backward compatibility
- **Performance with many agents**: Registry scan might be slow
  - Mitigation: Lazy loading, caching, benchmark with 50+ agents

### Low Risk
- **Code complexity**: Registry is straightforward lookup table
  - Mitigation: Keep functions small and focused
- **Maintenance**: New agents require no code changes
  - Mitigation: Self-discovering system

## Notes

### Design Decisions

**Why Lua Module over Bash Script**:
- Native to Neovim environment
- Better error handling
- Caching support
- Easier to integrate with existing Lua code

**Why Lazy Loading**:
- Faster startup (don't scan on require)
- Only pay cost when actually using agents
- Easy to force reload when needed

**Why Project-Over-Global Priority**:
- Matches existing command/hook behavior
- Allows per-project customization
- Global agents as fallback/defaults

**Agent Name from Filename**:
- Simple, predictable naming
- No need for `name` field in frontmatter
- Consistent with command naming

### Implementation Timeline
Estimated 4-6 hours total:
- Phase 1: 2-3 hours (core module)
- Phase 2: 1 hour (helpers)
- Phase 3: 1-2 hours (integration)
- Phase 4: 1 hour (docs and tests)

### Future Enhancements
- Hot reload on agent file changes
- Agent dependency tracking
- Agent version compatibility checking
- Agent metrics (usage tracking)
- Agent validation (check for required fields)
- Agent templates for quick creation

### Migration Path

From current state:
1. Implement agent registry module
2. Update one command as example
3. Gradually migrate other commands
4. Keep backward compatibility (inline prompts still work)

No breaking changes - existing commands continue to work.
