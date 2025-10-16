# Custom Agent Invocation in Claude Code Research Report

## Metadata
- **Date**: 2025-10-01
- **Scope**: Investigation of custom agent configuration and invocation in Claude Code
- **Primary Directory**: /home/benjamin/.config
- **Files Analyzed**:
  - `.claude/agents/*.md` (8 agent files)
  - `.claude/commands/*.md` (18 command files)
- **External Research**: Claude Code official documentation, community resources

## Executive Summary

The current implementation uses custom agent markdown files in `.claude/agents/` with names like `code-writer.md`, `doc-writer.md`, etc. However, Claude Code's Task tool only recognizes built-in subagent types (`general-purpose`, `statusline-setup`, `output-style-setup`), not custom agent names.

**Key Finding**: Custom agents in `.claude/agents/` are configuration files that define the agent's behavior when invoked, but they **cannot be directly invoked by name** using the `subagent_type` parameter in the Task tool. The Task tool only accepts predefined agent types.

**Recommended Approach**: Use `subagent_type: general-purpose` and include the custom agent's system prompt inline in the Task tool call, referencing the agent file's content for consistency.

## Current State Analysis

### Your Custom Agent Files

Location: `.claude/agents/`

```
code-writer.md          - Specialized in writing and modifying code
code-reviewer.md        - Analyzes code for refactoring
doc-writer.md           - Maintains documentation consistency
test-specialist.md      - Executes and analyzes test suites
plan-architect.md       - Creates structured implementation plans
research-specialist.md  - Conducts codebase analysis
debug-specialist.md     - Investigates issues and creates diagnostics
metrics-specialist.md   - Analyzes command execution metrics
```

Each file has:
- YAML frontmatter with `allowed-tools` and `description`
- Detailed system prompt describing role and capabilities
- Standards, guidelines, and behavioral instructions

### Task Tool Limitations

From Claude Code environment error when trying to invoke custom agents:

```
Error: Agent type 'plan-architect' not found.
Available agents: general-purpose, statusline-setup, output-style-setup
```

This reveals that:
1. **Built-in agent types** are hardcoded in Claude Code
2. **Custom agent names** are NOT recognized as `subagent_type` values
3. Only 3 agent types are available: `general-purpose`, `statusline-setup`, `output-style-setup`

## How Claude Code Subagents Actually Work

### Official Documentation Findings

From https://docs.claude.com/en/docs/claude-code/sub-agents:

**Subagent Definition**:
- Specialized AI assistants for task-specific workflows
- Stored as Markdown files with YAML frontmatter
- Can be created at project (`.claude/agents/`) or user (`~/.claude/agents/`) level

**Configuration Fields**:
```yaml
---
name: agent-name
description: Purpose of the subagent
tools: [optional tool access list]
model: [optional: sonnet, opus, haiku, or inherit]
---
```

**Invocation Methods**:
- **Automatic delegation**: Claude decides which subagent based on task description
- **Explicit mention**: Mention the subagent name in conversation
- **NOT via subagent_type parameter**: This is NOT documented as a valid invocation method

### The Gap: Task Tool vs Subagents

**Task Tool** (for parallel execution):
- Uses `subagent_type` parameter
- Only accepts: `general-purpose`, `statusline-setup`, `output-style-setup`
- Creates isolated context for task execution
- Returns results to caller

**Subagents** (for specialized assistance):
- Defined in `.claude/agents/` markdown files
- Invoked by mentioning name or automatic delegation
- NOT directly compatible with Task tool's `subagent_type`

**The Mismatch**:
Your command files use `subagent_type: "code-writer"` expecting to invoke the custom agent, but the Task tool doesn't support custom types.

## Current Implementation in Your Commands

### Before (Attempted Custom Invocation)

From `/home/benjamin/.config/.claude/commands/document.md`:

```yaml
Task {
  subagent_type: "doc-writer"  # NOT RECOGNIZED by Task tool
  description: "Update documentation for workflow"
  prompt: "..."
}
```

**Result**: Error - agent type not found

### After (Using general-purpose)

From `/home/benjamin/.config/.claude/commands/orchestrate.md`:

```yaml
Task {
  subagent_type: general-purpose
  description: "Research [aspect] for [feature]"
  prompt: "You are a research specialist focused on codebase analysis.
          [Full prompt with role and instructions]"
}
```

**Result**: Works, but doesn't use the custom agent file

## Recommended Solutions

### Option 1: Inline System Prompts (Current Approach)

**How it works**:
- Use `subagent_type: general-purpose`
- Include full system prompt inline in Task call
- Maintain agent files as documentation/templates

**Advantages**:
- ✅ Works with current Claude Code
- ✅ Full control over agent behavior
- ✅ Visible in command files

**Disadvantages**:
- ❌ Duplicates agent definitions
- ❌ Harder to maintain consistency
- ❌ Agent files become unused

**Implementation**:
```yaml
# In command file (e.g., document.md)
Task {
  subagent_type: general-purpose
  description: "Update documentation for workflow"
  prompt: "You are a documentation writer specialized in maintaining documentation consistency.

  # Read from agent file for consistency
  [Copy content from .claude/agents/doc-writer.md]

  Task: Update documentation for [changes]
  Context: [specific context for this invocation]

  Requirements:
  - Follow Documentation Policy from CLAUDE.md
  - Update cross-references
  - Use Unicode box-drawing for diagrams

  Output: List of updated files"
}
```

### Option 2: Read Agent File Content (Recommended)

**How it works**:
- Store agent definitions in `.claude/agents/*.md`
- In command, read agent file and include content in prompt
- Use `subagent_type: general-purpose` but with standardized agent content

**Advantages**:
- ✅ Single source of truth for agent behavior
- ✅ Easy to update agent definitions
- ✅ Agent files are actively used
- ✅ Consistency across all usages

**Disadvantages**:
- ⚠️ Requires reading file before Task call
- ⚠️ Slightly more complex command structure

**Implementation**:
```yaml
# In command file (e.g., document.md)

# Step 1: Read agent definition
Read agent file: .claude/agents/doc-writer.md

# Step 2: Invoke with agent content
Task {
  subagent_type: general-purpose
  description: "Update documentation for workflow"
  prompt: "[Content from doc-writer.md system prompt]

  Task: Update documentation for [changes]
  Context: [specific context]
  Requirements: [specific requirements]
  Output: [expected output]"
}
```

### Option 3: Hybrid Approach with Agent Registry

**How it works**:
- Create a helper function/module that maps agent names to their content
- Commands reference agent by name
- System reads and injects agent content

**Advantages**:
- ✅ Clean command syntax
- ✅ Centralized agent management
- ✅ Easy to add/modify agents

**Disadvantages**:
- ⚠️ Requires infrastructure code
- ⚠️ More complex setup

**Implementation**:

Create `.claude/lib/agent-loader.sh` or similar:
```lua
-- neotex.claude.agent_loader
local M = {}

local agent_definitions = {
  ["code-writer"] = "/.claude/agents/code-writer.md",
  ["doc-writer"] = "/.claude/agents/doc-writer.md",
  -- etc.
}

function M.load_agent_prompt(agent_name)
  local agent_file = agent_definitions[agent_name]
  if not agent_file then
    return nil
  end

  -- Read file and extract system prompt section
  -- Return prompt content
end

function M.invoke_agent(agent_name, task_description, context)
  local agent_prompt = M.load_agent_prompt(agent_name)

  return {
    subagent_type = "general-purpose",
    description = task_description,
    prompt = agent_prompt .. "\n\n" .. context
  }
end

return M
```

Then in commands:
```markdown
Use agent-loader to invoke doc-writer agent with task context
```

## Best Practices for Custom Agents

### 1. Agent File Structure

```markdown
---
allowed-tools: Tool1, Tool2, Tool3
description: One-line description
---

# Agent Name

I am a specialized agent focused on [primary responsibility].

## Core Capabilities
[List of what this agent does]

## Standards Compliance
[Project-specific standards this agent follows]

## Behavioral Guidelines
[How this agent approaches tasks]

## Expected Input
[What information this agent needs]

## Expected Output
[What format this agent returns]
```

### 2. Command File Integration

**Explicit Role Definition**:
```yaml
Task {
  subagent_type: general-purpose
  description: "Brief task description"
  prompt: "You are a [role] specialized in [expertise].

  [Core capabilities and guidelines from agent file]

  Task: [Specific task to perform]
  Context: [Task-specific context]
  Requirements: [Task-specific requirements]
  Output: [Expected output format]

  [Tool usage instructions]
  [Project standards reference]"
}
```

### 3. Consistency Maintenance

**Keep Agent Files Updated**:
- Agent files remain source of truth
- Update agent file when changing agent behavior
- Copy updated content to all command files using that agent

**Version Comments**:
```markdown
---
allowed-tools: Read, Write, Edit
description: Documentation writer
version: 2.0  # Updated 2025-10-01
---
```

### 4. Testing Agent Behavior

**Create Test Commands**:
```markdown
# .claude/commands/test-agent-doc-writer.md
Test the doc-writer agent with a simple task to verify behavior
```

## Migration Strategy

### Phase 1: Document Current State
- [ ] List all agent files and their purposes
- [ ] List all commands using agents
- [ ] Map agent names to command usages

### Phase 2: Standardize Agent Files
- [ ] Ensure all agent files have consistent structure
- [ ] Add version tracking
- [ ] Document expected input/output

### Phase 3: Update Command Files
- [ ] Choose approach (Option 1, 2, or 3)
- [ ] Update each command file to use general-purpose with inline prompts
- [ ] Test each command with updated agent invocation
- [ ] Document the pattern for future commands

### Phase 4: Create Helper Infrastructure (if using Option 3)
- [ ] Create agent loader utility
- [ ] Update commands to use utility
- [ ] Document utility usage

## Recommendations

### Immediate Actions

1. **Standardize on Option 2** (Read Agent File Content):
   - Maintains single source of truth
   - Agent files remain useful
   - Clear separation between agent definition and task context

2. **Update Command File Pattern**:
```markdown
# [Command Name]

## Agent Invocation Pattern

For [task type], use the [agent-name] agent:

1. Read agent definition: `.claude/agents/[agent-name].md`
2. Extract system prompt content
3. Invoke with general-purpose:

```yaml
Task {
  subagent_type: general-purpose
  description: "Brief task description"
  prompt: "[Agent system prompt from file]

  Task: [Specific task]
  Context: [Task context]
  Output: [Expected format]"
}
```
```

3. **Document the Pattern**:
   - Add to CLAUDE.md under "Agent Usage"
   - Include examples for each agent type
   - Explain why custom names don't work

### Long-term Considerations

**If Claude Code adds custom agent support**:
- Watch for updates to Task tool
- Be ready to migrate from inline prompts to `subagent_type: "custom-name"`
- Maintain agent files for easy transition

**If staying with current approach**:
- Consider building agent loader utility (Option 3)
- Automate prompt generation from agent files
- Add validation to ensure command prompts match agent definitions

## Technical Details

### Agent File Parsing

Current agent files use YAML frontmatter:

```yaml
---
allowed-tools: Read, Write, Edit, Bash, TodoWrite
description: Specialized in writing and modifying code
---
```

**Available Fields** (from documentation):
- `name`: Identifier (filename typically)
- `description`: One-line purpose
- `tools`: Optional tool restriction list
- `model`: Optional model selection

**System Prompt**: Everything after frontmatter

### Task Tool Parameters

**Official Parameters**:
```typescript
{
  subagent_type: "general-purpose" | "statusline-setup" | "output-style-setup"
  description: string  // Short description (3-5 words)
  prompt: string       // Full task prompt with context
  timeout?: number     // Optional timeout in ms
}
```

**Not Supported**:
- Custom agent type names
- Agent file references
- Dynamic agent loading

## Conclusion

**Answer to Your Question**: "Can commands directly call custom subagents?"

**No**, not in the current Claude Code implementation. The `subagent_type` parameter only accepts built-in types (`general-purpose`, etc.), not custom agent names.

**Solution**: Use `subagent_type: general-purpose` and include your custom agent's system prompt inline or read it from the agent file before invoking the Task tool.

**Your agent files** (code-writer.md, doc-writer.md, etc.) serve as:
1. **Templates** for system prompts to include in Task calls
2. **Documentation** of agent behavior and standards
3. **Single source of truth** for agent definitions

**Recommendation**: Adopt Option 2 (Read Agent File Content) to:
- Keep agent files as active source of truth
- Ensure consistency across all command usages
- Make agent updates easy (change file once, affects all commands)
- Maintain clear separation between agent definition and task context

## References

### External Documentation
- [Claude Code Subagents Official Docs](https://docs.claude.com/en/docs/claude-code/sub-agents)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)

### Local Files
- `/home/benjamin/.config/.claude/agents/` - Custom agent definitions
- `/home/benjamin/.config/.claude/commands/` - Command files using agents
- Error message: "Agent type 'plan-architect' not found. Available agents: general-purpose, statusline-setup, output-style-setup"

### Related Issues
- Commands were updated from custom agents to `general-purpose` due to unavailability
- Picker now correctly shows no agents for `orchestrate` (because `general-purpose` isn't in `.claude/agents/`)
- Need to decide whether to keep custom agent files or remove them
