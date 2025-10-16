# Agent Registry Plan Relevance Analysis

## Metadata
- **Date**: 2025-10-01
- **Scope**: Analysis of whether plan 025 (Agent Registry with Dynamic Loading) is still relevant given Workaround 1 (Natural Language Explicit Invocation) from report 019
- **Primary Directory**: `nvim/` and `.claude/`
- **Files Analyzed**:
  - `nvim/specs/plans/025_agent_registry_with_dynamic_loading.md`
  - `.claude/specs/reports/019_custom_agent_invocation_workarounds.md`
- **Related Plans**: Plan 025
- **Related Reports**: Report 019, Report 035

## Executive Summary

**Question**: Is the Agent Registry implementation plan (025) still relevant if we use Workaround 1 (Natural Language Explicit Invocation)?

**Answer**: **Yes, but with modified scope and different value proposition.**

The Agent Registry provides complementary value to Workaround 1 by solving **different problems**:
- **Workaround 1** solves: How to invoke custom agents from Claude Code
- **Agent Registry** solves: How to avoid duplicating agent definitions across Neovim-based workflows

**Recommendation**: **Proceed with Phase 1-2 of Plan 025**, but **defer/skip Phase 3-4** since command integration is now better handled by Workaround 1.

## Analysis

### Context: Two Different Ecosystems

The analysis reveals a critical distinction between two separate ecosystems:

#### 1. Claude Code Ecosystem (`.claude/`)
- **Agents**: `.claude/agents/*.md` files
- **Commands**: `.claude/commands/*.md` files (slash commands)
- **Invocation**: Natural language in markdown files
- **Report 019 addresses**: How to invoke agents from Claude Code commands

#### 2. Neovim/Lua Ecosystem (`nvim/lua/`)
- **Agents**: Same `.claude/agents/*.md` files (shared)
- **Workflows**: Lua code in Neovim plugins
- **Invocation**: Programmatic via Lua API
- **Plan 025 addresses**: How to use agents from Lua code in Neovim

### Workaround 1 Applicability

**What Workaround 1 Solves**:
```markdown
# In .claude/commands/plan.md (slash command)

Use the plan-architect agent to create a detailed implementation plan for $ARGUMENTS

Instructions for the plan-architect agent:
- Read research findings from provided reports
- Follow project standards in CLAUDE.md
- Create multi-phase plan with testing strategy
```

**Advantages**:
- ✅ Works in Claude Code markdown commands
- ✅ No code required
- ✅ Natural language invocation
- ✅ Leverages Claude's automatic agent selection

**Limitations for Neovim/Lua Workflows**:
- ❌ Not accessible from Lua code
- ❌ Can't be used in Neovim plugins programmatically
- ❌ No API for Lua-based automation
- ❌ Manual string concatenation if you need dynamic prompts

### Agent Registry Value Proposition (Post-Workaround 1)

**What Agent Registry Solves** (still relevant):

1. **Programmatic Access from Lua**:
```lua
-- In Neovim Lua plugin code
local agent_registry = require('neotex.plugins.ai.claude.agent_registry')
local agent = agent_registry.get_agent('plan-architect')

-- Dynamic prompt generation
local task_prompt = agent.system_prompt .. "\n\nTask: " .. user_input
```

2. **DRY for Neovim Workflows**:
```lua
-- Without registry (duplication)
local code_writer_prompt = [[
  I am a specialized code writer agent...
  [300 lines of agent definition]
]]

-- With registry (single source of truth)
local agent = agent_registry.get_agent('code-writer')
local prompt = agent.system_prompt  -- Loaded from .claude/agents/code-writer.md
```

3. **Agent Metadata Access**:
```lua
-- List all available agents in a Neovim picker
local agents = agent_registry.list_agents()
for _, agent_name in ipairs(agents) do
  local info = agent_registry.get_agent_info(agent_name)
  print(agent_name, info.description, info.allowed_tools)
end
```

4. **Integration with Neovim UI**:
```lua
-- Example: Agent picker in Neovim
local agents = agent_registry.list_agents()
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')

pickers.new({}, {
  prompt_title = "Select Agent",
  finder = finders.new_table({
    results = agents,
    entry_maker = function(agent_name)
      local info = agent_registry.get_agent_info(agent_name)
      return {
        value = agent_name,
        display = agent_name .. " - " .. info.description,
        ordinal = agent_name,
      }
    end,
  }),
}):find()
```

### Scope Adjustment for Plan 025

#### Original Plan Phases
1. ✅ **Phase 1**: Agent Registry Module (Lua) - **KEEP**
2. ✅ **Phase 2**: Helper Functions and Utilities - **KEEP**
3. ⚠️ **Phase 3**: Command Integration Examples - **MODIFY/DEFER**
4. ⚠️ **Phase 4**: Documentation and Testing - **MODIFY**

#### Recommended Scope Changes

**Phase 1 & 2: Proceed as Planned**
- Implement the Lua agent registry module
- Add helper functions for programmatic access
- Full value for Neovim/Lua workflows

**Phase 3: Modify Significantly**
Original intent was to integrate with `.claude/commands/*.md` files:
```markdown
# Original Phase 3 goal
- [ ] Create bash helper script: `.claude/lib/invoke-agent.sh`
- [ ] Update `/orchestrate` command documentation
- [ ] Update `/plan` command documentation
```

**New Phase 3 Goal**: Focus on Neovim integration instead:
```markdown
# Modified Phase 3 goal
- [ ] Create Neovim commands that use agent registry
- [ ] Add Telescope picker for agent selection
- [ ] Create keymaps for common agent workflows
- [ ] Example: <leader>ap to pick agent and execute task
```

**Phase 4: Modify Documentation Focus**
Original focus was on command integration:
```markdown
# Original Phase 4
- [ ] Update command documentation with agent usage
```

**New Focus**: Document Neovim/Lua usage:
```markdown
# Modified Phase 4
- [ ] Document agent_registry Lua API
- [ ] Example Neovim workflows using agents
- [ ] Telescope picker setup guide
- [ ] Migration guide (if users have inline agent definitions in Lua)
```

### Use Case Comparison

#### Use Case 1: Invoke Agent from Slash Command
**Solution**: ✅ **Workaround 1** (Natural Language Explicit Invocation)
```markdown
# .claude/commands/plan.md
Use the plan-architect agent to create an implementation plan for $ARGUMENTS
```
**Agent Registry**: ❌ Not needed for this use case

---

#### Use Case 2: Invoke Agent from Lua Code
**Solution**: ✅ **Agent Registry** (Plan 025)
```lua
-- nvim/lua/neotex/plugins/ai/workflows/planning.lua
local agent_registry = require('neotex.plugins.ai.claude.agent_registry')
local agent = agent_registry.get_agent('plan-architect')

local function create_plan(feature_name)
  local prompt = agent.system_prompt .. "\n\nCreate plan for: " .. feature_name
  -- Invoke Claude API with prompt
end
```
**Workaround 1**: ❌ Not applicable (no Lua API)

---

#### Use Case 3: Dynamic Agent Selection in Neovim
**Solution**: ✅ **Agent Registry** (Plan 025)
```lua
-- Telescope picker to select and invoke agent
local agents = agent_registry.list_agents()
-- Show picker, user selects agent, execute task
```
**Workaround 1**: ❌ Not designed for programmatic selection

---

#### Use Case 4: Avoid Duplication in Lua Workflows
**Solution**: ✅ **Agent Registry** (Plan 025)
```lua
-- Single source of truth: .claude/agents/code-writer.md
local agent = agent_registry.get_agent('code-writer')
-- Use agent.system_prompt across multiple Lua modules
```
**Workaround 1**: ❌ Only works in markdown commands

---

#### Use Case 5: List Available Agents in Neovim UI
**Solution**: ✅ **Agent Registry** (Plan 025)
```lua
local agents = agent_registry.list_agents()
for _, name in ipairs(agents) do
  print(name)
end
```
**Workaround 1**: ❌ No programmatic access

### Comparison Matrix

| Capability | Workaround 1 | Agent Registry | Winner |
|------------|-------------|----------------|---------|
| **Invoke from Claude Code commands** | ✅ Natural language | ❌ Not designed for this | Workaround 1 |
| **Invoke from Lua code** | ❌ No Lua API | ✅ Full Lua API | Agent Registry |
| **Dynamic prompt generation** | ⚠️ Manual concat | ✅ Programmatic | Agent Registry |
| **DRY for markdown commands** | ✅ Single mention | N/A | Workaround 1 |
| **DRY for Lua workflows** | ❌ Not applicable | ✅ Cached loading | Agent Registry |
| **Agent discovery/listing** | ❌ Manual | ✅ `list_agents()` | Agent Registry |
| **Metadata access** | ❌ Parse manually | ✅ Structured API | Agent Registry |
| **Neovim UI integration** | ❌ No API | ✅ Lua integration | Agent Registry |
| **Tool restriction** | ❌ Not enforced | ⚠️ Accessible but not enforced | Neither |
| **Setup complexity** | Low | Medium | Workaround 1 |
| **Maintenance** | Low | Low (self-discovering) | Tie |

### Key Insights

**Complementary, Not Competing**:
- Workaround 1 is for **Claude Code markdown commands**
- Agent Registry is for **Neovim Lua workflows**
- They solve different problems in different contexts

**Agent Registry Still Valuable For**:
1. **Programmatic access** to agent definitions from Lua
2. **Neovim plugin integration** (pickers, commands, automation)
3. **DRY principle** for Lua-based workflows
4. **Agent discovery and metadata** access
5. **Dynamic workflow generation** in Neovim

**Workaround 1 Makes Phase 3-4 Less Relevant**:
- Original plan focused on `.claude/commands/` integration
- Workaround 1 provides better solution for that context
- Should shift focus to **Neovim-specific** integration

## Recommendations

### Immediate Actions

**1. Proceed with Phase 1-2 of Plan 025** ✅
- Implement agent registry Lua module
- Add helper functions for programmatic access
- Full value for Neovim/Lua ecosystem

**2. Skip/Defer Original Phase 3** ⚠️
- Don't create bash helper scripts for commands
- Don't update `.claude/commands/*.md` with registry patterns
- Use Workaround 1 for all command-based agent invocation

**3. Redefine Phase 3 for Neovim Integration** 🔄
Focus on Neovim-specific use cases:
- Telescope picker for agent selection
- Neovim commands using agent registry
- Example Lua workflows
- Keymap integration

**4. Update Phase 4 Documentation** 🔄
- Document Lua API thoroughly
- Provide Neovim integration examples
- Explain when to use Agent Registry vs Workaround 1
- Add comparison guide

### Decision Matrix: Which Approach to Use?

**Use Workaround 1 (Natural Language Explicit Invocation) when**:
- ✅ Working in `.claude/commands/*.md` files (slash commands)
- ✅ Simple agent invocation with static prompts
- ✅ No need for programmatic control
- ✅ Want minimal setup complexity
- ✅ Targeting Claude Code environment

**Use Agent Registry (Plan 025) when**:
- ✅ Working in Neovim Lua code
- ✅ Need programmatic agent access
- ✅ Building Neovim plugins or workflows
- ✅ Dynamic prompt generation required
- ✅ Need agent metadata/discovery
- ✅ Creating Neovim UI integrations (pickers, menus)

**Example Decision Tree**:
```
Are you writing code in .claude/commands/*.md?
├─ YES → Use Workaround 1
└─ NO → Are you writing Lua code in nvim/?
    ├─ YES → Use Agent Registry
    └─ NO → Neither may be needed
```

### Migration Strategy

**For Existing .claude/commands/ Files**:
1. Remove any Task tool invocations with custom `subagent_type`
2. Replace with Workaround 1 pattern:
   ```markdown
   Use the [agent-name] agent to [task description]
   ```
3. Keep it simple - let Claude handle agent selection

**For Neovim Lua Workflows**:
1. Implement Agent Registry (Phase 1-2)
2. Replace inline agent definitions with registry calls
3. Add Neovim integration (modified Phase 3)
4. Document patterns (modified Phase 4)

**No Migration Needed Between Them**:
- They serve different contexts
- Can coexist without conflict
- Both read from same `.claude/agents/*.md` files

### Updated Plan 025 Summary

**Keep (High Value)**:
- ✅ Phase 1: Agent Registry Module
- ✅ Phase 2: Helper Functions and Utilities

**Modify (Redirect Focus)**:
- 🔄 Phase 3: Neovim Integration (not command integration)
- 🔄 Phase 4: Lua/Neovim Documentation (not command docs)

**Skip (Superseded by Workaround 1)**:
- ❌ Bash helper scripts for commands
- ❌ Command integration examples
- ❌ Updating `.claude/commands/*.md` with registry patterns

**New Estimated Timeline**:
- Phase 1: 2-3 hours (unchanged)
- Phase 2: 1 hour (unchanged)
- Phase 3: 1-2 hours (redirected to Neovim integration)
- Phase 4: 1 hour (redirected to Lua/Neovim docs)

Total: 5-7 hours (similar to original estimate)

## Plan 026 Analysis: Bulk Migration to Agent Registry

### Plan Overview

Plan 026 proposes a bulk migration of all `.claude/commands/*.md` files to use the agent registry pattern by:
1. Replacing `subagent_type: "agent-name"` with `subagent_type: general-purpose`
2. Loading agent prompts from `.claude/agents/*.md` via agent registry
3. Injecting agent system prompts into Task prompts

**Target Commands**:
- `/plan` - Uses plan-architect, research-specialist
- `/debug` - Uses debug-specialist
- `/document` - Uses doc-writer
- `/orchestrate` - Uses multiple agents (5+)
- `/report` - Uses research-specialist

**Migration Pattern** (from Plan 026):
```markdown
Task {
  subagent_type: general-purpose
  description: "Create implementation plan"
  prompt: "[AGENT_PROMPT:plan-architect]

Task: Create implementation plan for feature X
Context: ...
  "
}
```

### Relevance Assessment: ❌ **NOT RELEVANT - Superseded by Workaround 1**

**Critical Finding**: Plan 026 is **obsolete** given Workaround 1 from Report 019.

**Why Plan 026 Is No Longer Needed**:

1. **Workaround 1 is Simpler and Better**:
```markdown
# Plan 026 approach (complex)
Task {
  subagent_type: general-purpose
  prompt: "[AGENT_PROMPT:plan-architect]

  Task: Create plan for feature X"
}

# Workaround 1 approach (simple)
Use the plan-architect agent to create a plan for feature X
```

2. **No Agent Registry Needed for Commands**:
   - Plan 026 requires implementing agent registry (Plan 025)
   - Then requires migration script to update all commands
   - Workaround 1 works immediately without any infrastructure

3. **Workaround 1 Provides Same Outcome**:
   - Both invoke custom agents from commands
   - Both load agent system prompts
   - Workaround 1 leverages Claude's built-in agent selection
   - Plan 026 manually replicates what Claude does automatically

4. **Maintenance Burden**:
   - Plan 026: Maintain migration script, token replacement, validation
   - Workaround 1: Zero maintenance - just mention agent name

5. **Complexity Comparison**:

| Aspect | Plan 026 | Workaround 1 | Winner |
|--------|----------|-------------|---------|
| **Setup Required** | Implement agent registry + migration script | None | Workaround 1 |
| **Code to Maintain** | Migration script + token replacement | None | Workaround 1 |
| **Command Syntax** | `[AGENT_PROMPT:name]` tokens + Task tool | Natural language | Workaround 1 |
| **Agent Selection** | Manual prompt injection | Automatic by Claude | Workaround 1 |
| **Error Handling** | Custom validation | Built-in | Workaround 1 |
| **Readability** | Complex YAML + tokens | Plain English | Workaround 1 |

### Why Plan 026 Was Created

Plan 026 was created **before** discovering Workaround 1. It was designed to solve:
- "Agent type 'X' not found" errors
- Need to use custom agents from commands

**These problems are now solved by Workaround 1** without any of the complexity.

### Migration Recommendation

**For `.claude/commands/*.md` files**:

❌ **Do NOT implement Plan 026**

✅ **Instead, use Workaround 1** for all commands:

**Example Migration** (plan.md):

```markdown
# BEFORE (broken)
Task {
  subagent_type: "plan-architect"
  description: "Create plan"
  prompt: "..."
}

# DO NOT migrate to Plan 026 pattern (unnecessary complexity)
Task {
  subagent_type: general-purpose
  prompt: "[AGENT_PROMPT:plan-architect] ..."
}

# CORRECT: Migrate to Workaround 1 (simple)
Use the plan-architect agent to create an implementation plan for $ARGUMENTS

Instructions for the plan-architect agent:
- Follow project standards in CLAUDE.md
- Create multi-phase plan with testing
- Output to specs/plans/NNN_feature_name.md
```

### Updated Command Integration Strategy

**Original Strategy** (Plan 026):
1. Implement agent registry (Plan 025)
2. Create migration script
3. Migrate all commands with `[AGENT_PROMPT:name]` tokens
4. Maintain token replacement system

**New Strategy** (Workaround 1):
1. ~~Implement agent registry~~ - Only for Neovim/Lua (Plan 025 Phase 1-2)
2. ~~Create migration script~~ - Not needed
3. Update commands to use natural language explicit invocation
4. ~~Maintain token system~~ - Not needed

**Actual Migration Steps**:
```bash
# 1. For each command in .claude/commands/*.md
# 2. Find Task { subagent_type: "agent-name" ... }
# 3. Replace with: "Use the [agent-name] agent to [task]"
# 4. Done - no tooling needed
```

### Example Command Migrations

**plan.md**:
```markdown
# Before
Task {
  subagent_type: "plan-architect"
  ...
}

# After (Workaround 1)
Use the plan-architect agent to create a structured implementation plan for $ARGUMENTS
```

**orchestrate.md**:
```markdown
# Before (multiple agents)
Task { subagent_type: "research-specialist" ... }
Task { subagent_type: "plan-architect" ... }
Task { subagent_type: "code-writer" ... }

# After (Workaround 1)
1. Use the research-specialist agent to investigate [topic]
2. Use the plan-architect agent to create plan based on research
3. Use the code-writer agent to implement the plan
```

### What Happens to Plan 026?

**Status**: ❌ **OBSOLETE - Do Not Implement**

**Rationale**:
- Solving a problem that Workaround 1 solves more elegantly
- Adds unnecessary complexity (migration script, token system)
- Requires Plan 025 infrastructure that's only valuable for Neovim/Lua
- Manual simple text edits are faster than writing migration tooling

**Action Items**:
- [ ] Mark Plan 026 as obsolete in metadata
- [ ] Update plan with deprecation notice
- [ ] Reference Workaround 1 as replacement
- [ ] Keep plan for historical reference only

### Updated Plan 025 Implications

With Plan 026 obsolete, Plan 025 scope becomes clearer:

**Plan 025 Phases**:
- ✅ **Phase 1-2**: Implement agent registry for **Neovim/Lua only**
- ❌ **Phase 3-4**: ~~Command integration~~ - Use Workaround 1 instead

**Revised Plan 025 Phase 3**:
- Focus on **Neovim integration** (Telescope pickers, keymaps)
- Skip `.claude/commands/` integration entirely
- Document Workaround 1 for command users

## Conclusion

### Plan 025 (Agent Registry): ✅ Relevant with Modified Scope

**The Agent Registry (Plan 025) is still highly relevant and valuable**, but for **different reasons** than originally planned.

**Original Value Proposition** (Pre-Report 019):
- Avoid duplicating agent definitions in `.claude/commands/*.md` files
- Provide programmatic invocation for both commands and Lua

**New Value Proposition** (Post-Report 019):
- ~~Avoid duplicating agent definitions in `.claude/commands/*.md` files~~ ← Superseded by Workaround 1
- Provide programmatic invocation for ~~both commands and~~ Lua ← Scoped to Lua only
- **NEW**: Enable rich Neovim integrations (pickers, commands, automation)
- **NEW**: Support dynamic workflow generation in Neovim
- **NEW**: Provide agent discovery and metadata APIs

**Recommendation**: **Proceed with Plan 025** with modified scope:
1. **Implement Phase 1-2** as originally planned (Lua module + helpers)
2. **Redirect Phase 3** to focus on Neovim integration instead of command integration
3. **Update Phase 4** documentation to reflect Neovim/Lua focus
4. **Use Workaround 1** for all `.claude/commands/*.md` agent invocations

### Plan 026 (Bulk Migration): ❌ Obsolete - Do Not Implement

**Plan 026 is completely obsolete** and should **not be implemented**.

**Why**:
- Workaround 1 provides simpler, better solution for command-based agent invocation
- Agent registry only needed for Neovim/Lua workflows, not commands
- Migration script adds unnecessary complexity
- Manual text edits using Workaround 1 pattern are trivial

**Replacement**: **Use Workaround 1** for all `.claude/commands/*.md` files

**Action**: Mark Plan 026 as deprecated, reference Workaround 1 as replacement

### Summary Decision Matrix

| Plan | Status | Scope | Rationale |
|------|--------|-------|-----------|
| **025** | ✅ Proceed (modified) | Neovim/Lua only | Valuable for programmatic Lua workflows |
| **026** | ❌ Obsolete | N/A | Superseded by simpler Workaround 1 |

### Final Recommendations

1. **Plan 025**: Implement Phase 1-2, redirect Phase 3-4 to Neovim integration
2. **Plan 026**: Mark as obsolete, do not implement
3. **Commands**: Migrate all `.claude/commands/*.md` to use Workaround 1 pattern
4. **Documentation**: Update both plans with new scope and deprecation notices

This approach:
- ✅ Leverages best solution for each context
- ✅ Avoids unnecessary complexity
- ✅ Enables powerful Neovim integrations
- ✅ Maintains single source of truth for agent definitions
- ✅ Uses simplest possible approach for commands (Workaround 1)

## References

### Related Documents
- [Plan 025: Agent Registry with Dynamic Loading](../plans/025_agent_registry_with_dynamic_loading.md) - ✅ Relevant (modified scope)
- [Plan 026: Bulk Migration to Agent Registry](../plans/026_bulk_migration_commands_to_agent_registry.md) - ❌ Obsolete
- [Report 019: Custom Agent Invocation Workarounds](../../.claude/specs/reports/019_custom_agent_invocation_workarounds.md) - ✅ Primary reference for Workaround 1
- [Report 035: Custom Agent Invocation in Claude Code](./035_custom_agent_invocation_in_claude_code.md)

### Ecosystem Boundaries
- **Claude Code**: `.claude/` directory - markdown commands, **use Workaround 1**
- **Neovim**: `nvim/lua/` directory - Lua code, **use Agent Registry (Plan 025)**

### Decision Points
1. ✅ **Keep Agent Registry for Neovim/Lua ecosystem** (Plan 025 Phase 1-2)
2. ✅ **Use Workaround 1 for Claude Code markdown commands** (supersedes Plan 026)
3. 🔄 **Modify Plan 025 Phase 3-4 scope to focus on Neovim**
4. ❌ **Skip command integration** (superseded by Workaround 1)
5. ❌ **Mark Plan 026 as obsolete** (superseded by Workaround 1)

## ADDENDUM: Agent Registry Removed (2025-10-01)

### User Decision: Picker-Centric Approach

After analysis, the user chose to **remove the agent registry entirely** and focus on the picker as the single management interface.

### Actions Taken

**Files Deleted**:
- `nvim/lua/neotex/plugins/ai/claude/agent_registry.lua` (301 lines)
- `nvim/lua/neotex/plugins/ai/claude/agent_registry_spec.lua` (test file)
- `nvim/specs/summaries/024_agent_registry_with_dynamic_loading.md`

**Files Updated**:
- `nvim/lua/neotex/plugins/ai/claude/README.md` - Removed agent registry section, documented picker approach
- `nvim/specs/plans/025_agent_registry_with_dynamic_loading.md` - Marked as OBSOLETE
- `nvim/specs/plans/026_bulk_migration_commands_to_agent_registry.md` - Marked as OBSOLETE

**New Plan Created**:
- `nvim/specs/plans/024_extend_picker_with_agents_and_hooks_FINAL.md` - Complete picker implementation plan without agent registry

### Rationale

1. **Agent registry only valuable for programmatic Lua workflows** - User doesn't need this
2. **Picker provides all required management** - Load, update, save, edit via `<leader>ac`
3. **Commands use Workaround 1** - Natural language invocation is simpler
4. **Parser already provides everything** - No duplicate scanning infrastructure needed
5. **Simpler architecture** - ~600 lines of code removed, easier to maintain

### Final Architecture

**Parser** (`commands/parser.lua`):
- Scans `.claude/agents/*.md` for metadata
- Scans `.claude/hooks/*.sh` for metadata
- Scans `.claude/config/*.sh` for TTS configs (to be added)
- Returns structured data for picker display

**Picker** (`commands/picker.lua`):
- Single management interface via `<leader>ac`
- Display, preview, edit all artifact types
- File operations: load, update, save
- Batch operations: Load All synchronization

**Commands** (`.claude/commands/*.md`):
- Use Workaround 1 for agent invocation
- Pattern: `Use the [agent-name] agent to [task]`
- No programmatic invocation infrastructure

### Impact

- ✅ Cleaner codebase (~600 lines removed)
- ✅ Single source of truth (picker + parser)
- ✅ No confusion about two parallel systems
- ✅ Focus on what user actually needs
- ✅ Easier to maintain and understand

### Updated Recommendations

**For managing agents**:
- ✅ Use `<leader>ac` picker (view, edit, load, save)
- ✅ Use parser for scanning (no duplicate system)

**For invoking agents in commands**:
- ✅ Use Workaround 1 (natural language)
- ❌ Don't use agent registry (removed)
- ❌ Don't use Plan 025/026 (obsolete)

---

*Report generated: 2025-10-01*
*Updated: 2025-10-01 (Agent registry removed)*
*Analysis context: Comparing Plan 025 and Plan 026 with Report 019 Workaround 1*
*Original Recommendation Plan 025: Proceed with modified scope (Neovim/Lua only)*
*Original Recommendation Plan 026: Mark as obsolete - Do not implement*
*Final Decision: Agent registry removed entirely, picker-centric approach chosen*
