# Extend Command Picker with Agents and Hooks Research Report

## Metadata
- **Date**: 2025-10-01
- **Scope**: Extending `<leader>ac` picker to include agents and hooks with hierarchical display and enhanced Load All Commands functionality
- **Primary Directory**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/`
- **Files Analyzed**:
  - `picker.lua` (1040 lines) - Main picker implementation
  - `parser.lua` (200+ lines) - Command parsing and structure
  - `.claude/agents/` (8 agent files)
  - `.claude/hooks/` (3 hook files)
  - `.claude/commands/` (18 command files)
- **Related Reports**:
  - `017_claude_code_command_picker_synchronization.md` - Terminal state management
  - `033_load_all_commands_update_behavior.md` - Load All Commands enhancement

## Executive Summary

The current `<leader>ac` command picker displays Claude Code commands in a two-level hierarchy (primary commands with dependent commands). This report proposes extending the picker to include:

1. **Agents**: Display all agents from `.claude/agents/` listed under the commands that call them
2. **Hooks**: Display all hooks from `.claude/hooks/` listed under the hook events that trigger them
3. **Enhanced Load All**: Extend `[Load All Commands]` to also copy/replace agents and hooks from `~/.config/.claude/`

The hierarchical structure will be maintained using the existing tree-like display (├─, └─) with proper dependency tracking.

## Current Architecture Analysis

### Command Structure

The picker currently displays commands in this hierarchy:

```
  [Keyboard Shortcuts]                 Help
  [Load All Commands]                  Copy all global commands locally

* implement                            Execute implementation plan with...
  ├─ document                          Update all relevant documentation...
  ├─ debug                             Investigate issues and create...
  ├─ revise                            Revise the most recently discussed...
  ├─ list-summaries                    List all implementation summaries...
  ├─ update-plan                       Update an existing implementation...
  └─ list-plans                        List all implementation plans...

  orchestrate                          Coordinate subagents through...
  ├─ document                          Update all relevant documentation...
  ├─ test                              Run project-specific tests...
  ├─ debug                             Investigate issues and create...
  ├─ implement                         Execute implementation plan with...
  ├─ plan                              Create a detailed implementation...
  └─ report                            Research a topic and create...
```

### Key Files

#### picker.lua:20-102 - Entry Creation
```lua
local function create_picker_entries(structure)
  local entries = {}

  -- Add special entries (Load All, Help)
  -- Add primary commands and their dependents
  for _, primary_name in ipairs(sorted_primary_names) do
    local primary_data = structure.primary_commands[primary_name]

    -- Add dependent commands first (with indentation)
    for i, dependent in ipairs(dependents) do
      local indent_char = is_first and "└─" or "├─"
      -- Display with indentation
    end

    -- Add primary command
  end
end
```

#### parser.lua - Command Parsing
- Parses YAML frontmatter from `.md` files
- Extracts: `command-type`, `dependent-commands`, `allowed-tools`, `description`
- Builds hierarchical structure with `primary_commands` and their `dependents`

### Current Directory Structure

```
~/.config/.claude/
├── commands/           # 18 command files
│   ├── implement.md
│   ├── orchestrate.md
│   ├── plan.md
│   └── ...
├── agents/             # 8 agent files
│   ├── code-writer.md
│   ├── code-reviewer.md
│   ├── doc-writer.md
│   ├── test-specialist.md
│   ├── plan-architect.md
│   ├── research-specialist.md
│   ├── debug-specialist.md
│   └── metrics-specialist.md
└── hooks/              # 3 hook files
    ├── post-command-metrics.sh
    ├── session-start-restore.sh
    └── tts-dispatcher.sh
```

## Agent Dependencies Mapping

### Commands → Agents

Based on analysis of command files, here are the agent dependencies:

| Command | Agents Used |
|---------|-------------|
| **orchestrate** | research-specialist, plan-architect, code-writer, debug-specialist, doc-writer |
| **implement** | *(uses commands that use agents)* |
| **plan** | research-specialist, plan-architect |
| **report** | research-specialist |
| **debug** | debug-specialist |
| **document** | doc-writer |
| **refactor** | code-reviewer |
| **test** | test-specialist |
| **test-all** | test-specialist |

### Agent Descriptions

From `.claude/agents/` files:

```yaml
code-writer:
  description: "Specialized in writing and modifying code following project standards"
  tools: Read, Write, Edit, Bash, TodoWrite

code-reviewer:
  description: "Analyzes code for refactoring opportunities based on project standards"
  tools: Read, Grep, Glob, TodoWrite

doc-writer:
  description: "Maintains documentation consistency and completeness"
  tools: Read, Write, Edit, Grep, Glob

test-specialist:
  description: "Executes and analyzes test suites"
  tools: Read, Bash, Grep, Glob, TodoWrite

plan-architect:
  description: "Creates structured implementation plans"
  tools: Read, Write, Grep, Glob, TodoWrite

research-specialist:
  description: "Conducts codebase analysis and best practices research"
  tools: Read, Grep, Glob, WebSearch, WebFetch

debug-specialist:
  description: "Investigates issues and creates diagnostic reports"
  tools: Read, Bash, Grep, Glob, WebSearch, WebFetch, TodoWrite

metrics-specialist:
  description: "Analyzes command execution metrics for performance insights"
  tools: Read, Bash, Grep, Glob
```

## Hook Dependencies Mapping

### Hook Events → Hooks

From `settings.local.json`, hooks are registered for specific events:

| Hook Event | Hooks Triggered |
|------------|-----------------|
| **Stop** | post-command-metrics.sh, tts-dispatcher.sh |
| **SessionStart** | session-start-restore.sh, tts-dispatcher.sh |
| **SessionEnd** | tts-dispatcher.sh |
| **SubagentStop** | tts-dispatcher.sh |
| **Notification** | tts-dispatcher.sh |

### Hook Descriptions

```yaml
post-command-metrics.sh:
  event: Stop
  description: "Collect command execution metrics for performance analysis"
  output: ".claude/metrics/YYYY-MM.jsonl"

session-start-restore.sh:
  event: SessionStart
  description: "Check for interrupted workflows and notify user on session start"
  checks: ".claude/state/*.json files"

tts-dispatcher.sh:
  events: Stop, SessionStart, SessionEnd, SubagentStop, Notification
  description: "Central dispatcher for all TTS notifications in Claude Code workflow"
  routes: "completion, permission, progress, error, idle, session messages"
```

## Proposed Picker Structure

### Enhanced Hierarchy Display

```
  [Keyboard Shortcuts]                 Help
  [Load All Commands]                  Copy all commands, agents, and hooks

* implement                            Execute implementation plan with...
  ├─ document                          Update all relevant documentation...
  ├─ debug                             Investigate issues and create...
  ├─ revise                            Revise the most recently discussed...
  ├─ list-summaries                    List all implementation summaries...
  ├─ update-plan                       Update an existing implementation...
  └─ list-plans                        List all implementation plans...

  orchestrate                          Coordinate subagents through...
  ├─ document                          Update all relevant documentation...
  ├─ test                              Run project-specific tests...
  ├─ debug                             Investigate issues and create...
  ├─ implement                         Execute implementation plan with...
  ├─ plan                              Create a detailed implementation...
  ├─ report                            Research a topic and create...
  ├─ [agent] code-writer               Write and modify code
  ├─ [agent] debug-specialist          Investigate and diagnose issues
  ├─ [agent] doc-writer                Update documentation
  ├─ [agent] plan-architect            Create implementation plans
  └─ [agent] research-specialist       Research patterns and practices

  plan                                 Create a detailed implementation...
  ├─ list-reports                      List all existing research reports...
  ├─ report                            Research a topic and create...
  ├─ [agent] plan-architect            Create implementation plans
  └─ [agent] research-specialist       Research patterns and practices

* document                             Update all relevant documentation...
  └─ [agent] doc-writer                Update documentation

  refactor                             Analyze code for refactoring...
  └─ [agent] code-reviewer             Review and analyze code

  [Hook Event] Stop                    After command completion
  ├─ post-command-metrics.sh           Collect execution metrics
  └─ tts-dispatcher.sh                 TTS notifications

  [Hook Event] SessionStart            When session begins
  ├─ session-start-restore.sh          Check for interrupted workflows
  └─ tts-dispatcher.sh                 TTS notifications

  [Hook Event] SessionEnd              When session ends
  └─ tts-dispatcher.sh                 TTS notifications

  [Hook Event] SubagentStop            After subagent completes
  └─ tts-dispatcher.sh                 TTS notifications

  [Hook Event] Notification            Permission/idle events
  └─ tts-dispatcher.sh                 TTS notifications
```

### Display Conventions

- **Commands**: Regular display, `*` prefix for local versions
- **Agents**: `[agent]` prefix, listed under commands that call them
- **Hooks**: `[Hook Event]` for event groups, hook scripts listed underneath
- **Indentation**: Same tree characters (├─, └─) for visual consistency

## Implementation Design

### 1. Extended Parser Module

Add functions to `parser.lua` to scan agents and hooks:

```lua
--- Scan .claude/agents/ directory for agent files
--- @param agents_dir string Path to agents directory
--- @return table Array of agent metadata
function M.scan_agents_directory(agents_dir)
  -- Scan for *.md files
  -- Parse YAML frontmatter
  -- Extract: name, description, allowed-tools
  -- Return array of agent data
end

--- Scan .claude/hooks/ directory for hook scripts
--- @param hooks_dir string Path to hooks directory
--- @return table Array of hook metadata
function M.scan_hooks_directory(hooks_dir)
  -- Scan for *.sh files
  -- Parse header comments
  -- Extract: name, description, hook events
  -- Return array of hook data
end

--- Build command-agent dependency map
--- @param commands table Command structure
--- @param agents table Agent data
--- @return table Map of command name → agents used
function M.build_agent_dependencies(commands, agents)
  -- Parse command files for subagent_type references
  -- Build reverse mapping: agent → commands that use it
  -- Return structured map
end

--- Build hook-event dependency map
--- @param hooks table Hook data
--- @param settings table Settings from settings.local.json
--- @return table Map of hook event → hooks triggered
function M.build_hook_dependencies(hooks, settings)
  -- Parse settings.local.json for hook registrations
  -- Build map of events → hooks
  -- Return structured map
end
```

### 2. Enhanced Entry Creation

Modify `create_picker_entries()` in `picker.lua`:

```lua
local function create_picker_entries(structure, agents, hooks)
  local entries = {}

  -- Add special entries (Help, Load All)
  table.insert(entries, { is_help = true, ... })
  table.insert(entries, { is_load_all = true, ... })

  -- Add primary commands with dependents AND agents
  for _, primary_name in ipairs(sorted_primary_names) do
    local primary_data = structure.primary_commands[primary_name]

    -- Get agents used by this command
    local command_agents = get_agents_for_command(primary_name, agents)

    -- Add dependent commands
    for i, dependent in ipairs(primary_data.dependents) do
      table.insert(entries, {
        name = dependent.name,
        display = format_dependent(dependent),
        command = dependent,
        is_primary = false,
        entry_type = "command"
      })
    end

    -- Add agents used by this command
    for i, agent in ipairs(command_agents) do
      table.insert(entries, {
        name = agent.name,
        display = format_agent(agent),
        agent = agent,
        is_primary = false,
        entry_type = "agent",
        parent = primary_name
      })
    end

    -- Add primary command
    table.insert(entries, {
      name = primary_name,
      display = format_primary(primary_command),
      command = primary_command,
      is_primary = true,
      entry_type = "command"
    })
  end

  -- Add hook event groups
  for event_name, event_hooks in pairs(hooks) do
    -- Add individual hooks
    for i, hook in ipairs(event_hooks) do
      table.insert(entries, {
        name = hook.name,
        display = format_hook(hook),
        hook = hook,
        is_primary = false,
        entry_type = "hook",
        parent = event_name
      })
    end

    -- Add hook event group header
    table.insert(entries, {
      name = event_name,
      display = format_hook_event(event_name),
      is_primary = true,
      entry_type = "hook_event"
    })
  end

  return entries
end
```

### 3. Enhanced Previewer

Update `create_command_previewer()` to handle agents and hooks:

```lua
local function create_command_previewer()
  return previewers.new_buffer_previewer({
    define_preview = function(self, entry, status)
      if entry.value.entry_type == "agent" then
        -- Display agent information
        local agent = entry.value.agent
        local lines = {
          "━━━ " .. agent.name .. " (Agent) ━━━",
          "",
          "**Type**: Subagent",
          "",
          "**Description**:",
          agent.description,
          "",
          "**Allowed Tools**:",
          table.concat(agent.allowed_tools, ", "),
          "",
          "**Used By**:",
        }

        -- List commands that use this agent
        for _, cmd in ipairs(agent.parent_commands) do
          table.insert(lines, "  • " .. cmd)
        end

        table.insert(lines, "")
        table.insert(lines, "**File**: " .. agent.filepath)

        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")

      elseif entry.value.entry_type == "hook" then
        -- Display hook information
        local hook = entry.value.hook
        local lines = {
          "━━━ " .. hook.name .. " (Hook) ━━━",
          "",
          "**Type**: Hook Script",
          "",
          "**Description**:",
          hook.description,
          "",
          "**Triggered By**:",
          table.concat(hook.events, ", "),
          "",
          "**Script**: " .. hook.filepath,
        }

        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")

      elseif entry.value.entry_type == "hook_event" then
        -- Display hook event information
        local event_name = entry.value.name
        local lines = {
          "━━━ " .. event_name .. " Hook Event ━━━",
          "",
          "**Type**: Hook Event",
          "",
          "**Description**:",
          get_hook_event_description(event_name),
          "",
          "**When Triggered**:",
          get_hook_event_trigger_info(event_name),
          "",
          "**Registered Hooks**:",
        }

        -- List hooks for this event
        for _, hook in ipairs(entry.value.hooks) do
          table.insert(lines, "  • " .. hook.name)
        end

        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")

      else
        -- Existing command preview logic
        -- ...
      end
    end,
  })
end
```

### 4. Enhanced Load All Commands

Modify `load_all_commands_locally()` to include agents and hooks:

```lua
local function load_all_globally()
  local project_dir = vim.fn.getcwd()
  local global_dir = vim.fn.expand("~/.config")

  -- Don't load if we're in the global directory
  if project_dir == global_dir then
    notify.editor("Already in the global directory", notify.categories.STATUS)
    return 0
  end

  -- Scan global directories
  local global_commands_dir = global_dir .. "/.claude/commands"
  local global_agents_dir = global_dir .. "/.claude/agents"
  local global_hooks_dir = global_dir .. "/.claude/hooks"

  local commands_to_sync = scan_directory_for_sync(global_commands_dir, ".md")
  local agents_to_sync = scan_directory_for_sync(global_agents_dir, ".md")
  local hooks_to_sync = scan_directory_for_sync(global_hooks_dir, ".sh")

  local total_new = commands_to_sync.new_count + agents_to_sync.new_count + hooks_to_sync.new_count
  local total_update = commands_to_sync.update_count + agents_to_sync.update_count + hooks_to_sync.update_count

  -- Show confirmation dialog
  local message = string.format(
    "Load all from global directory?\n\n" ..
    "Commands:\n" ..
    "  - Copy %d new commands\n" ..
    "  - Replace %d existing commands\n\n" ..
    "Agents:\n" ..
    "  - Copy %d new agents\n" ..
    "  - Replace %d existing agents\n\n" ..
    "Hooks:\n" ..
    "  - Copy %d new hooks\n" ..
    "  - Replace %d existing hooks\n\n" ..
    "Local-only items will not be affected.",
    commands_to_sync.new_count, commands_to_sync.update_count,
    agents_to_sync.new_count, agents_to_sync.update_count,
    hooks_to_sync.new_count, hooks_to_sync.update_count
  )

  local choice = vim.fn.confirm(message, "&Yes\n&No", 2)
  if choice ~= 1 then
    notify.editor("Load all cancelled", notify.categories.STATUS)
    return 0
  end

  -- Create local directories if needed
  local local_commands_dir = project_dir .. "/.claude/commands"
  local local_agents_dir = project_dir .. "/.claude/agents"
  local local_hooks_dir = project_dir .. "/.claude/hooks"

  vim.fn.mkdir(local_commands_dir, "p")
  vim.fn.mkdir(local_agents_dir, "p")
  vim.fn.mkdir(local_hooks_dir, "p")

  -- Sync all items
  local commands_synced = sync_files(commands_to_sync, global_commands_dir, local_commands_dir)
  local agents_synced = sync_files(agents_to_sync, global_agents_dir, local_agents_dir)
  local hooks_synced = sync_files(hooks_to_sync, global_hooks_dir, local_hooks_dir)

  -- Report results
  notify.editor(
    string.format(
      "Loaded: %d commands, %d agents, %d hooks",
      commands_synced.total,
      agents_synced.total,
      hooks_synced.total
    ),
    notify.categories.SUCCESS
  )

  return commands_synced.total + agents_synced.total + hooks_synced.total
end
```

### 5. Action Mappings for Agents and Hooks

Add keyboard shortcuts specific to agents and hooks:

```lua
attach_mappings = function(prompt_bufnr, map)
  -- Existing command mappings (Enter, Ctrl-l, Ctrl-u, Ctrl-s, Ctrl-e, Ctrl-n)

  -- View agent/hook file on Enter (for agent/hook entries)
  actions.select_default:replace(function()
    local selection = action_state.get_selected_entry()
    if selection then
      if selection.value.entry_type == "agent" then
        -- Open agent file in preview or buffer
        local agent = selection.value.agent
        actions.close(prompt_bufnr)
        vim.cmd.edit(agent.filepath)

      elseif selection.value.entry_type == "hook" then
        -- Open hook script in buffer
        local hook = selection.value.hook
        actions.close(prompt_bufnr)
        vim.cmd.edit(hook.filepath)

      elseif selection.value.entry_type == "hook_event" then
        -- Show hook event details (no action on Enter)

      elseif selection.value.is_load_all then
        -- Load all commands, agents, and hooks
        load_all_globally()
        actions.close(prompt_bufnr)
        vim.defer_fn(function()
          M.show_commands_picker(opts)
        end, 50)

      elseif selection.value.command and not selection.value.is_help then
        -- Existing command insertion logic
        actions.close(prompt_bufnr)
        send_command_to_terminal(selection.value.command)
      end
    end
  end)

  -- Ctrl-l: Load agent/hook locally
  map("i", "<C-l>", function()
    local selection = action_state.get_selected_entry()
    if selection then
      if selection.value.entry_type == "agent" then
        load_agent_locally(selection.value.agent)
        refresh_picker()
      elseif selection.value.entry_type == "hook" then
        load_hook_locally(selection.value.hook)
        refresh_picker()
      elseif selection.value.entry_type == "command" then
        -- Existing command load logic
      end
    end
  end)

  -- Ctrl-u: Update agent/hook from global
  map("i", "<C-u>", function()
    local selection = action_state.get_selected_entry()
    if selection then
      if selection.value.entry_type == "agent" then
        update_agent_from_global(selection.value.agent)
        refresh_picker()
      elseif selection.value.entry_type == "hook" then
        update_hook_from_global(selection.value.hook)
        refresh_picker()
      elseif selection.value.entry_type == "command" then
        -- Existing command update logic
      end
    end
  end)

  -- Ctrl-s: Save agent/hook to global
  map("i", "<C-s>", function()
    local selection = action_state.get_selected_entry()
    if selection then
      if selection.value.entry_type == "agent" then
        save_agent_to_global(selection.value.agent)
        refresh_picker()
      elseif selection.value.entry_type == "hook" then
        save_hook_to_global(selection.value.hook)
        refresh_picker()
      elseif selection.value.entry_type == "command" then
        -- Existing command save logic
      end
    end
  end)

  return true
end
```

## File Management Functions

### Agent Management

```lua
--- Load agent locally from global directory
--- @param agent table Agent data
--- @param silent boolean Don't show notifications
--- @return boolean success
local function load_agent_locally(agent, silent)
  -- Similar to load_command_locally
  -- Copy from ~/.config/.claude/agents/ to .claude/agents/
  -- Show notification
end

--- Update local agent from global version
--- @param agent table Agent data
--- @param silent boolean Don't show notifications
--- @return boolean success
local function update_agent_from_global(agent, silent)
  -- Similar to update_command_from_global
  -- Overwrite local agent with global version
end

--- Save local agent to global directory
--- @param agent table Agent data
--- @param silent boolean Don't show notifications
--- @return boolean success
local function save_agent_to_global(agent, silent)
  -- Similar to save_command_to_global
  -- Copy from .claude/agents/ to ~/.config/.claude/agents/
end
```

### Hook Management

```lua
--- Load hook locally from global directory
--- @param hook table Hook data
--- @param silent boolean Don't show notifications
--- @return boolean success
local function load_hook_locally(hook, silent)
  -- Copy from ~/.config/.claude/hooks/ to .claude/hooks/
  -- Preserve executable permissions
  -- Show notification
end

--- Update local hook from global version
--- @param hook table Hook data
--- @param silent boolean Don't show notifications
--- @return boolean success
local function update_hook_from_global(hook, silent)
  -- Overwrite local hook with global version
  -- Preserve executable permissions
end

--- Save local hook to global directory
--- @param hook table Hook data
--- @param silent boolean Don't show notifications
--- @return boolean success
local function save_hook_to_global(hook, silent)
  -- Copy from .claude/hooks/ to ~/.config/.claude/hooks/
  -- Preserve executable permissions
end
```

## Display Formatting

### Format Functions

```lua
--- Format agent entry for display
--- @param agent table Agent data
--- @param indent_char string Tree character (├─ or └─)
--- @return string Formatted display string
local function format_agent(agent, indent_char)
  local is_local = agent.is_local
  local prefix = is_local and "*" or " "
  local display_name = "[agent] " .. agent.name

  return string.format(
    "%s %s %-38s %s",
    prefix,
    indent_char,
    display_name,
    agent.description or ""
  )
end

--- Format hook entry for display
--- @param hook table Hook data
--- @param indent_char string Tree character (├─ or └─)
--- @return string Formatted display string
local function format_hook(hook, indent_char)
  local is_local = hook.is_local
  local prefix = is_local and "*" or " "
  local display_name = hook.name

  return string.format(
    "%s %s %-38s %s",
    prefix,
    indent_char,
    display_name,
    hook.description or ""
  )
end

--- Format hook event header for display
--- @param event_name string Hook event name (Stop, SessionStart, etc.)
--- @return string Formatted display string
local function format_hook_event(event_name)
  local display_name = "[Hook Event] " .. event_name
  local description = get_hook_event_description(event_name)

  return string.format(
    "%-42s %s",
    display_name,
    description
  )
end
```

## Help Text Updates

Update the keyboard shortcuts help in the previewer:

```lua
if entry.value.is_help then
  vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {
    "Keyboard Shortcuts:",
    "",
    "  Enter (CR)  - Insert command / View agent/hook file",
    "  Ctrl-n      - Create new command (opens Claude Code with prompt)",
    "  Ctrl-l      - Load command/agent/hook locally (copies with dependencies)",
    "  Ctrl-u      - Update command/agent/hook from global version (overwrites local)",
    "  Ctrl-s      - Save local command/agent/hook to global (share across projects)",
    "  Ctrl-e      - Edit command (loads locally first if needed)",
    "  Escape      - Close picker",
    "",
    "Navigation:",
    "  Ctrl-j/k    - Move selection down/up",
    "  Ctrl-d      - Scroll preview down",
    "",
    "Picker Structure:",
    "  Primary commands - Main workflow commands",
    "  ├─ dependent   - Supporting commands called by primary",
    "  ├─ [agent] name - Subagents used by primary command",
    "  └─ dependent   - Commands/agents may appear under multiple primaries",
    "",
    "  [Hook Event] Name - Hook event group",
    "  ├─ hook-script.sh - Hook triggered by this event",
    "  └─ hook-script.sh - Multiple hooks may be registered per event",
    "",
    "Indicators:",
    "  *  - Item defined locally in project (.claude/)",
    "       Local items override global ones from .config/",
    "  (no *) - Global item from ~/.config/.claude/",
    "",
    "Item Management:",
    "  Ctrl-n - Create new command with Claude Code assistance",
    "  Ctrl-l - Copies global item to local (preserves local if exists)",
    "  Ctrl-u - Updates/overwrites local with global version",
    "  Ctrl-s - Saves local item to global (requires local item)",
    "  [Load All Commands] - Batch copies new and replaces existing:",
    "                        • Commands (.claude/commands/)",
    "                        • Agents (.claude/agents/)",
    "                        • Hooks (.claude/hooks/)",
    "                        (preserves local-only items)",
    "  The picker refreshes after changes to show updated status",
    "",
    "Note: Items are loaded from both project and .config directories"
  })
  return
end
```

## Hook Event Descriptions

```lua
local hook_event_descriptions = {
  Stop = "Triggered after command completion",
  SessionStart = "Triggered when Claude Code session begins",
  SessionEnd = "Triggered when Claude Code session ends",
  SubagentStop = "Triggered when subagent completes a task",
  Notification = "Triggered for permission requests and idle reminders",
  PreToolUse = "Triggered before tool execution",
  PostToolUse = "Triggered after tool execution",
  UserPromptSubmit = "Triggered when user submits a prompt",
  PreCompact = "Triggered before context compaction",
}

local function get_hook_event_description(event_name)
  return hook_event_descriptions[event_name] or "Unknown event"
end
```

## Migration Strategy

### Phase 1: Parser Extensions
1. Add `scan_agents_directory()` to parser.lua
2. Add `scan_hooks_directory()` to parser.lua
3. Add `build_agent_dependencies()` to parser.lua
4. Add `build_hook_dependencies()` to parser.lua
5. Test parsing functions independently

### Phase 2: Picker Integration
1. Modify `create_picker_entries()` to accept agents and hooks
2. Add agent entries under command dependents
3. Add hook event groups with hook entries
4. Test hierarchical display

### Phase 3: Previewer Enhancement
1. Add agent preview handling
2. Add hook preview handling
3. Add hook event preview handling
4. Update help text

### Phase 4: File Management
1. Implement `load_agent_locally()`
2. Implement `load_hook_locally()`
3. Implement `update_agent_from_global()`
4. Implement `update_hook_from_global()`
5. Implement `save_agent_to_global()`
6. Implement `save_hook_to_global()`

### Phase 5: Load All Enhancement
1. Extend `load_all_globally()` to scan agents
2. Extend `load_all_globally()` to scan hooks
3. Update confirmation dialog
4. Test batch operations

### Phase 6: Action Mappings
1. Update Enter action for agents and hooks
2. Update Ctrl-l for agents and hooks
3. Update Ctrl-u for agents and hooks
4. Update Ctrl-s for agents and hooks
5. Test all keyboard shortcuts

## Testing Checklist

### Unit Tests
- [ ] Parser correctly scans `.claude/agents/` directory
- [ ] Parser correctly scans `.claude/hooks/` directory
- [ ] Agent-command dependencies correctly mapped
- [ ] Hook-event dependencies correctly mapped

### Integration Tests
- [ ] Agents appear under correct commands in picker
- [ ] Hooks appear under correct events in picker
- [ ] Tree characters (├─, └─) display correctly
- [ ] Local indicator (*) shows for local agents/hooks
- [ ] Preview displays agent information correctly
- [ ] Preview displays hook information correctly
- [ ] Preview displays hook event information correctly

### File Operations
- [ ] Ctrl-l loads agent locally
- [ ] Ctrl-l loads hook locally (preserves permissions)
- [ ] Ctrl-u updates agent from global
- [ ] Ctrl-u updates hook from global
- [ ] Ctrl-s saves agent to global
- [ ] Ctrl-s saves hook to global
- [ ] Load All copies new agents
- [ ] Load All copies new hooks
- [ ] Load All replaces existing agents
- [ ] Load All replaces existing hooks
- [ ] Load All preserves local-only items

### User Experience
- [ ] Enter on agent opens agent file
- [ ] Enter on hook opens hook script
- [ ] Enter on command inserts command
- [ ] Help text updated with agent/hook info
- [ ] Confirmation dialog shows agent/hook counts
- [ ] Notifications show agent/hook operations
- [ ] Picker refreshes after operations

## Benefits

### Discoverability
- **Agents**: Users can see which agents are available and which commands use them
- **Hooks**: Users can understand the hook system and what scripts are triggered
- **Dependencies**: Clear visualization of command→agent and event→hook relationships

### Portability
- **Load All**: One-click setup of complete `.claude/` infrastructure
- **Consistency**: Ensures agents and hooks are synchronized across projects
- **Versioning**: Easy to update global versions and propagate to projects

### Maintainability
- **Hierarchical View**: Natural organization shows relationships at a glance
- **Unified Interface**: Single picker for all `.claude/` artifacts
- **Edit in Place**: Direct access to agent and hook files for customization

## Implementation Estimate

| Phase | Effort | Description |
|-------|--------|-------------|
| Parser Extensions | 2-3 hours | Add scanning and dependency mapping functions |
| Picker Integration | 3-4 hours | Modify entry creation and display logic |
| Previewer Enhancement | 2-3 hours | Add agent/hook preview handling |
| File Management | 3-4 hours | Implement load/update/save functions for agents and hooks |
| Load All Enhancement | 2-3 hours | Extend batch operations |
| Action Mappings | 2-3 hours | Update keyboard shortcuts |
| Testing | 3-4 hours | Comprehensive testing |
| **Total** | **17-24 hours** | Full implementation and testing |

## Future Enhancements

### Agent Templates
- Add "Create New Agent" command (similar to Ctrl-n for commands)
- Provide agent templates with standard structure

### Hook Management
- Add hook enablement toggle directly from picker
- Show which hooks are currently active
- Add hook testing/debugging tools

### Dependency Visualization
- Show reverse dependencies (commands that depend on this agent)
- Highlight missing dependencies
- Suggest related agents/commands

### Search and Filter
- Filter by agent type
- Filter by hook event
- Search across commands, agents, and hooks

## Conclusion

This enhancement significantly improves the `<leader>ac` picker by providing complete visibility into the `.claude/` infrastructure. By extending the existing two-level hierarchy to include agents and hooks, users gain:

1. **Complete Picture**: All `.claude/` artifacts in one interface
2. **Easy Transfer**: One-click synchronization across projects
3. **Clear Dependencies**: Visual representation of command→agent and event→hook relationships
4. **Unified Management**: Consistent operations (load, update, save) across all artifact types

The implementation builds on the existing picker architecture, reusing proven patterns for hierarchical display, file management, and keyboard shortcuts.

## References

### Primary Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua` - Picker implementation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/parser.lua` - Command parsing
- `/home/benjamin/.config/.claude/agents/` - Agent definitions (8 files)
- `/home/benjamin/.config/.claude/hooks/` - Hook scripts (3 files)
- `/home/benjamin/.config/.claude/commands/` - Command definitions (18 files)
- `/home/benjamin/.config/.claude/settings.local.json` - Hook registrations

### Related Reports
- `017_claude_code_command_picker_synchronization.md` - Terminal state management
- `033_load_all_commands_update_behavior.md` - Load All Commands enhancement

### Documentation
- `.claude/docs/tts-integration-guide.md` - TTS system documentation
- `.claude/config/tts-config.sh` - TTS configuration reference
