# Research Report: Existing Claude Code Picker Architecture

**Date**: 2025-12-15
**Topic**: Claude Code Picker Implementation Analysis
**Research Phase**: Codebase Analysis

---

## Executive Summary

The existing `<leader>ac` Claude Code picker is a sophisticated Telescope-based interface for managing Claude Code utilities. It provides a hierarchical display of commands, agents, hooks, TTS files, documentation, libraries, scripts, and tests with support for local/global artifact management.

---

## Architecture Overview

### Core Components

```
neotex/plugins/ai/claude/commands/picker/
├── picker.lua                  # Facade/public API
├── init.lua                    # Main orchestration
├── display/
│   ├── entries.lua            # Entry creation & formatting
│   └── previewer.lua          # Preview window content
├── operations/
│   ├── edit.lua               # Edit/load/save operations
│   ├── sync.lua               # Sync with global artifacts
│   └── terminal.lua           # Terminal command execution
├── utils/
│   ├── helpers.lua            # Helper utilities
│   └── scan.lua               # Directory scanning
└── artifacts/
    ├── metadata.lua           # Metadata extraction
    └── registry.lua           # Artifact type registry
```

### Module Responsibilities

#### 1. **picker.lua** (Facade)
- Public API entry point
- Delegates to internal implementation
- Single function: `show_commands_picker(opts)`

#### 2. **init.lua** (Orchestrator)
- Creates Telescope picker instance
- Manages keybindings (Enter, Ctrl-l, Ctrl-u, Ctrl-s, Ctrl-e, Ctrl-n, Ctrl-r, Ctrl-t)
- Coordinates between all other modules
- Handles entry selection and actions

#### 3. **display/entries.lua** (Entry Management)
- Creates picker entries from parsed structure
- Formats display strings with tree characters (├─, └─)
- Handles hierarchical sections:
  - Commands (with dependent commands and agents)
  - Hooks (grouped by event type)
  - Standalone Agents
  - TTS Files (by role: config, dispatcher, library)
  - Scripts
  - Tests
  - Templates
  - Lib utilities
  - Docs
  - Special entries (Help, Load All)

#### 4. **commands/parser.lua** (Data Source)
- Scans `.claude/commands/`, `.claude/agents/`, `.claude/hooks/`, `.claude/tts/`
- Parses YAML frontmatter from markdown files
- Builds hierarchical structure with dependencies
- Merges local and global artifacts (local overrides global)
- Creates `is_local` flags for display

---

## Key Design Patterns

### 1. **Local/Global Artifact Management**

```lua
-- Merge pattern from scan.lua
function M.merge_artifacts(local_artifacts, global_artifacts)
  local all_artifacts = {}
  local artifact_map = {}
  
  -- Local artifacts first (marked with is_local = true)
  for _, artifact in ipairs(local_artifacts) do
    artifact.is_local = true
    table.insert(all_artifacts, artifact)
    artifact_map[artifact.name] = true
  end
  
  -- Global artifacts only if not overridden
  for _, artifact in ipairs(global_artifacts) do
    if not artifact_map[artifact.name] then
      artifact.is_local = false
      table.insert(all_artifacts, artifact)
    end
  end
  
  return all_artifacts
end
```

**Visual Indicator**: Asterisk prefix (`*`) for local artifacts

### 2. **Hierarchical Display Structure**

Insertion order is **reversed** for descending sort:
- Last inserted appears at TOP
- Commands section inserted last → appears first
- Special entries (Help, Load All) inserted first → appear at bottom

Example display:
```
[Commands]                    Slash commands
  ├─ /create-plan             Create implementation plan
  │  ├─ plan-architect        Plan generation agent
  │  └─ /expand               Expand plan phases
  ├─ /implement               Execute implementation
  │  └─ implementer           Implementation agent
  ...
[Agents]                      Standalone AI agents
  ├─ researcher               Research specialist
  └─ tester                   Testing specialist
[Hooks]                       Event-triggered scripts
  ├─ Stop                     After command completion
  └─ SessionStart             When session begins
...
[Keyboard Shortcuts]          Help
[Load All Artifacts]          Sync commands, agents, hooks, TTS files
```

### 3. **Tree Character Logic**

```lua
local function format_command(command, indent_char, is_dependent)
  local prefix = command.is_local and "*" or " "
  local description = command.description or ""
  
  if is_dependent then
    return string.format(
      "%s   %s %-37s %s",  -- Extra indent for nested items
      prefix,
      indent_char,
      command.name,
      description
    )
  else
    return string.format(
      "%s %s %-38s %s",
      prefix,
      indent_char,
      command.name,
      description
    )
  end
end
```

Tree characters determined by position:
- `├─` for non-last items
- `└─` for last items
- Extra space for dependent/nested items

### 4. **Telescope Integration**

```lua
pickers.new(opts, {
  prompt_title = "Claude Commands",
  finder = finders.new_table {
    results = picker_entries,
    entry_maker = function(entry)
      return {
        value = entry,
        display = entry.display,
        ordinal = entry.name .. " " .. description,  -- Searchable text
      }
    end,
  },
  sorter = conf.generic_sorter({}),
  sorting_strategy = "descending",
  default_selection_index = 2,
  previewer = previewer.create_command_previewer(),
  attach_mappings = function(prompt_bufnr, map)
    -- Keybinding setup
  end,
}):find()
```

### 5. **Keybinding Architecture**

| Key | Action | Description |
|-----|--------|-------------|
| `<Enter>` | Context-aware execution | Run command or open file based on entry type |
| `<Ctrl-l>` | Load locally | Copy global artifact to local `.claude/` |
| `<Ctrl-u>` | Update from global | Replace local artifact with global version |
| `<Ctrl-s>` | Save to global | Save local artifact to `~/.config/.claude/` |
| `<Ctrl-e>` | Edit file | Open artifact in buffer |
| `<Ctrl-n>` | Create new command | Interactive command creation |
| `<Ctrl-r>` | Run script | Execute script with argument prompt |
| `<Ctrl-t>` | Run test | Execute test file |
| `<Esc>` | Close picker | Exit immediately |

### 6. **Entry Type System**

Each entry has an `entry_type` field:
- `"command"` - Slash commands (primary or dependent)
- `"agent"` - AI agent files
- `"hook_event"` - Hook event grouping (with hooks array)
- `"tts_file"` - TTS system files
- `"script"` - Standalone scripts
- `"test"` - Test files
- `"template"` - Template files
- `"lib"` - Library utilities
- `"doc"` - Documentation files
- `"special"` - Help/Load All entries
- `"heading"` - Section headers

---

## Frontmatter Parsing

Commands and agents use YAML frontmatter:

```yaml
---
command-type: primary
description: Create implementation plan from research
argument-hint: "<overview-path> [prompt]"
allowed-tools: ["bash", "read", "write", "task"]
dependent-commands: ["expand", "compress"]
agent-dependencies: ["plan-architect", "research-specialist"]
---
```

Parser converts to:
```lua
{
  command_type = "primary",
  description = "Create implementation plan from research",
  argument_hint = "<overview-path> [prompt]",
  allowed_tools = {"bash", "read", "write", "task"},
  dependent_commands = {"expand", "compress"},
  agent_dependencies = {"plan-architect", "research-specialist"},
}
```

---

## Directory Scanning

### Recursive Scanning for Nested Structures

```lua
function M.scan_directory_for_sync(global_dir, local_dir, subdir, extension, recursive)
  local global_path = global_dir .. "/.claude/" .. subdir
  local all_files = {}
  local seen = {}
  
  if recursive then
    -- Scan nested subdirectories with ** pattern
    local recursive_files = vim.fn.glob(global_path .. "/**/" .. extension, false, true)
    for _, global_file in ipairs(recursive_files) do
      seen[global_file] = true
      table.insert(all_files, global_file)
    end
    
    -- Scan top-level files separately
    local top_level_files = vim.fn.glob(global_path .. "/" .. extension, false, true)
    for _, global_file in ipairs(top_level_files) do
      if not seen[global_file] then
        table.insert(all_files, global_file)
      end
    end
  end
  
  return files
end
```

### Metadata Extraction

```lua
-- From metadata.lua
function M.parse_doc_description(filepath)
  local first_line = vim.fn.readfile(filepath, '', 1)[1]
  if first_line and first_line:match("^# ") then
    return first_line:gsub("^# ", "")
  end
  return ""
end

function M.parse_script_description(filepath)
  local lines = vim.fn.readfile(filepath, '', 10)
  for _, line in ipairs(lines) do
    local desc = line:match("^# (.+)")
    if desc and not desc:match("^!/") then  -- Skip shebang
      return desc
    end
  end
  return ""
end
```

---

## Preview System

Preview window shows:
- Command files: Full markdown content
- Agents: Frontmatter + description
- Scripts: First 50 lines with syntax highlighting
- Hooks: Event associations + file content

```lua
function M.create_command_previewer()
  return previewers.new_buffer_previewer {
    title = "Preview",
    define_preview = function(self, entry, status)
      local filepath = entry.value.filepath or 
                      (entry.value.command and entry.value.command.filepath) or
                      (entry.value.agent and entry.value.agent.filepath)
      
      if filepath and vim.fn.filereadable(filepath) == 1 then
        conf.buffer_previewer_maker(filepath, self.state.bufnr, {
          bufname = self.state.bufname,
          winid = self.state.winid,
        })
      end
    end,
  }
end
```

---

## Keybinding Registration

Located in `neotex/plugins/editor/which-key.lua`:

```lua
{ "<leader>ac", "<cmd>ClaudeCommands<CR>", desc = "claude commands", icon = "󰘳" }
```

User command defined in `neotex/plugins/ai/claude/init.lua`:

```lua
vim.api.nvim_create_user_command("ClaudeCommands", function()
  commands_picker.show_commands_picker()
end, { desc = "Show Claude commands picker" })
```

---

## Special Features

### 1. Load All Artifacts

Syncs all artifacts from `~/.config/.claude/` to local `.claude/`:
- Commands
- Agents  
- Hooks
- TTS files
- Templates
- Lib utilities
- Docs
- Settings

### 2. Skip README Files

```lua
local is_readme = filename == "README.md"
if not is_readme then
  -- Process file
end
```

### 3. Help Entry

Shows keyboard shortcuts when selected (non-actionable).

### 4. Agent Dependencies

Commands show which agents they use:
```
├─ /create-plan             Create implementation plan
│  ├─ plan-architect        Plan generation agent
│  └─ research-specialist   Research coordination
```

Built by parsing:
1. `agent-dependencies` frontmatter field
2. `subagent_type:` references in markdown content

---

## File Paths

### Global Directory
`~/.config/.claude/`

### Local Directory  
`<project>/.claude/`

### Search Priority
1. Local artifacts (marked with `*`)
2. Global artifacts (unmarked)

Local overrides global when same name exists.

---

## Recommendations for .opencode/ Picker

### Reusable Patterns
1. ✅ Modular directory structure (picker/display/, picker/operations/, picker/utils/)
2. ✅ Hierarchical entry system with tree characters
3. ✅ Local/global merge with visual indicators
4. ✅ Context-aware Enter key behavior
5. ✅ Metadata extraction from file headers
6. ✅ Telescope integration with custom previewer
7. ✅ Recursive directory scanning

### Adaptations Needed
1. `.opencode/` has different structure (no hooks, TTS; has context/, workflows/)
2. Commands are in `command/` not `commands/`
3. Agents are in `agent/` not `agents/`
4. Additional sections: context/, workflows/, templates/, domain/, processes/, standards/
5. May not need local/global distinction (single location?)
6. Different keybindings (no Ctrl-l/Ctrl-u/Ctrl-s if no sync operations)

---

## Next Steps

1. Analyze .opencode/ directory structure in detail
2. Determine which artifacts should be displayed in picker
3. Define entry types for .opencode/ artifacts
4. Design keybinding scheme for .opencode/ picker
5. Determine if local/global sync is needed for .opencode/
