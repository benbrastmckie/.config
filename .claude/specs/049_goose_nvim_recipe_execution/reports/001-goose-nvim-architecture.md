# goose.nvim Plugin Architecture and APIs

**Research Date**: 2025-12-09
**Topic**: goose.nvim plugin structure, available APIs for recipe execution, sidebar component architecture, and current plugin capabilities for running commands in neovim
**Status**: Complete

---

## Executive Summary

goose.nvim is a neovim plugin that wraps the goose CLI (an AI agent system) and provides a rich sidebar-based UI for interacting with goose sessions. The plugin is built on a modular architecture with clear separation between core execution logic, UI components, and integration layers.

**Key Findings**:
- goose.nvim acts as a wrapper around the goose CLI binary, not a pure Lua implementation
- The plugin provides a sidebar UI with input/output panes for chat-based agent interaction
- Core execution uses the plenary.job library to spawn goose CLI processes
- API layer exposes functions for opening UI, running prompts, and managing sessions
- Current recipe execution system (custom picker) bypasses the sidebar and uses ToggleTerm for terminal output

---

## Plugin Structure

### Core Modules

The plugin is organized into the following module hierarchy (located at `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/`):

#### 1. Core Execution Layer
- **`core.lua`**: Main orchestration module
  - `M.open(opts)`: Opens the goose sidebar UI
  - `M.run(prompt, opts)`: Executes a prompt through goose CLI
  - `M.stop()`: Stops running goose jobs
  - `M.select_session()`: Session picker for loading existing sessions
  - Handles session management and UI lifecycle

- **`job.lua`**: Goose CLI process management
  - `M.build_args(prompt)`: Constructs goose CLI arguments
  - `M.execute(prompt, handlers)`: Spawns goose process with plenary.job
  - `M.stop(job)`: Terminates running goose process
  - Provides callbacks: `on_start`, `on_stdout`, `on_stderr`, `on_exit`

#### 2. API Layer
- **`api.lua`**: Public API functions exposed to users
  - `M.open_input()`: Open sidebar with input focus
  - `M.open_output()`: Open sidebar with output focus
  - `M.close()`: Close sidebar windows
  - `M.run(prompt)`: Execute prompt in current session
  - `M.run_new_session(prompt)`: Execute prompt in new session
  - `M.toggle()`: Toggle sidebar visibility
  - `M.stop()`: Stop running jobs
  - Defines all user commands (`:Goose`, `:GooseRun`, etc.)

#### 3. UI Components (lua/goose/ui/)
- **`ui.lua`**: Main UI orchestration
  - `create_windows()`: Creates sidebar window layout
  - `render_output()`: Renders goose responses in output pane
  - `focus_input()`/`focus_output()`: Window focus management
  - `write_to_input()`: Programmatically write to input buffer
  - `scroll_to_bottom()`: Auto-scroll output pane

- **`window_config.lua`**: Window layout configuration
- **`topbar.lua`**: Status bar showing provider/model/mode
- **`output_renderer.lua`**: Markdown rendering for goose responses
- **`session_formatter.lua`**: Session history formatting
- **`navigation.lua`**: Window navigation keybindings

#### 4. State and Context
- **`state.lua`**: Global plugin state
  - `state.active_session`: Current session object
  - `state.windows`: Sidebar window handles
  - `state.goose_run_job`: Running job reference
  - `state.last_focused_goose_window`: Focus tracking

- **`session.lua`**: Session persistence
  - `M.get_sessions()`: List all saved sessions
  - `M.get_by_name(session_id)`: Load session by ID
  - `M.export(session_name)`: Export session as JSON

- **`context.lua`**: File context management
  - `M.add_file(path)`: Add file to goose context
  - `M.format_message(prompt)`: Format prompt with context
  - `M.unload_attachments()`: Clear temporary context

---

## Available APIs for Recipe Execution

### Current Execution Flow (Sidebar-Based)

The standard goose execution flow uses the sidebar UI:

```lua
-- From core.lua
function M.run(prompt, opts)
  M.before_run(opts)  -- Opens sidebar, stops existing jobs

  -- Execute via job.lua
  job.execute(prompt, {
    on_start = function() M.after_run(prompt) end,
    on_output = function(output)
      -- Reload modified files, set session ID
      vim.cmd('checktime')
    end,
    on_error = function(err)
      vim.notify(err, vim.log.levels.ERROR)
      ui.close_windows(state.windows)
    end,
    on_exit = function()
      state.goose_run_job = nil
    end
  })
end
```

**Arguments Built by job.lua**:
```lua
-- job.lua: M.build_args(prompt)
local args = {
  "run",           -- goose CLI subcommand
  "--text", message,  -- Prompt with context
  "--name", session_name,  -- Session ID
  "--resume"       -- Resume existing session
}
```

**Key Characteristics**:
- Uses `goose run --text` for chat-based interaction
- Output is streamed to sidebar output pane via `on_stdout` callback
- Session state is managed automatically
- UI is opened before execution and shows real-time output

---

## Recipe Execution Capabilities

### Goose CLI Recipe Support

The goose CLI provides native recipe support via `goose run --recipe`:

```bash
# Recipe execution syntax
goose run --recipe <RECIPE_NAME or FULL_PATH>
          --params <KEY=VALUE>
          --interactive        # Continue in interactive mode
          --explain            # Show recipe metadata
          --render-recipe      # Print rendered recipe
```

**Recipe Features**:
- YAML-based template system with parameters
- Parameter validation (required, optional, user_prompt)
- Interactive and non-interactive modes
- Recipe deeplinking and validation

### Plugin Integration: Custom Recipe Picker

The configuration includes a custom recipe picker implementation (separate from goose.nvim core):

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/`

**Modules**:
1. **`discovery.lua`**: Finds recipes in project (.goose/recipes/) and global (~/.config/goose/recipes/)
2. **`metadata.lua`**: Parses YAML recipe metadata
3. **`previewer.lua`**: Telescope preview window for recipe content
4. **`execution.lua`**: Parameter prompting and command execution
5. **`init.lua`**: Telescope picker UI orchestration

**Current Execution Method** (from execution.lua):
```lua
function M.run_recipe(recipe_path, metadata)
  local params = M.prompt_for_parameters(metadata.parameters)
  local cmd = M.build_command(recipe_path, params)

  -- ISSUE: Uses ToggleTerm instead of goose sidebar
  local toggleterm = require('toggleterm')
  toggleterm.exec(cmd)  -- Opens terminal, bypasses goose UI
end
```

**Command Format**:
```bash
goose run --recipe '/path/to/recipe.yaml'
          --interactive
          --params key1=value1,key2=value2
```

---

## Key Findings

### 1. goose.nvim Architecture Strengths
- **Modular Design**: Clear separation of concerns (core, api, ui, state)
- **Plenary.job Integration**: Robust process management with callbacks
- **Session Persistence**: Automatic session saving and resumption
- **Real-time Streaming**: Output rendered incrementally as goose responds
- **UI Framework**: Full sidebar UI with input/output panes, markdown rendering

### 2. Recipe Execution Gap
The custom recipe picker does NOT integrate with goose.nvim's sidebar system:
- Recipes executed via ToggleTerm (external terminal)
- Output does NOT appear in goose sidebar
- No session integration (each recipe run is isolated)
- No real-time streaming to UI

### 3. Available Integration Points

To execute recipes through the goose sidebar, the following API functions are available:

**Option A: Direct API Call**
```lua
local goose_api = require('goose.api')
goose_api.run(prompt)  -- Uses current session, shows in sidebar
```

**Option B: Core Module (More Control)**
```lua
local goose_core = require('goose.core')
goose_core.run(prompt, {
  ensure_ui = true,      -- Ensure sidebar is open
  new_session = false,   -- Use existing session
  focus = "output"       -- Focus output pane after execution
})
```

**Option C: Job Module (Low-Level)**
```lua
local goose_job = require('goose.job')
goose_job.execute(prompt, {
  on_start = function() ... end,
  on_output = function(output) ... end,
  on_error = function(err) ... end,
  on_exit = function() ... end
})
```

---

## Recommendations

### 1. Recipe Execution Integration Strategy

**Replace ToggleTerm with goose.api.run()**:
- Build recipe command as text prompt
- Pass to `goose.api.run()` instead of `toggleterm.exec()`
- Output will appear in goose sidebar automatically
- Session state preserved for follow-up interactions

**Example Refactored Code**:
```lua
-- execution.lua: M.run_recipe()
function M.run_recipe(recipe_path, metadata)
  local params = M.prompt_for_parameters(metadata.parameters)

  -- Build recipe CLI invocation as text
  local recipe_cmd = M.build_command(recipe_path, params)

  -- Use goose.nvim API instead of ToggleTerm
  local goose_api = require('goose.api')
  goose_api.run(recipe_cmd)  -- Execute in sidebar
end
```

### 2. Alternative: Native Recipe Support in goose.nvim

Extend goose.nvim's `job.lua` to support recipe arguments:
```lua
function M.build_args(prompt, opts)
  opts = opts or {}

  if opts.recipe_path then
    -- Recipe mode
    local args = { "run", "--recipe", opts.recipe_path }
    if opts.params then
      table.insert(args, "--params")
      table.insert(args, opts.params)
    end
    if opts.interactive then
      table.insert(args, "--interactive")
    end
    return args
  else
    -- Standard prompt mode
    return { "run", "--text", prompt, ... }
  end
end
```

### 3. UI Enhancement: Recipe Picker Keybinding

Add new keybinding in picker to execute recipe in sidebar:
- `<CR>`: Execute in ToggleTerm (current behavior)
- `<C-s>`: Execute in goose sidebar (new)
- `<C-p>`: Preview with --explain (current)

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Interface                           │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐      │
│  │  Recipe Picker│  │ Goose Sidebar │  │   ToggleTerm  │      │
│  │  (Telescope)  │  │ (Input/Output)│  │   (Terminal)  │      │
│  └───────┬───────┘  └───────┬───────┘  └───────┬───────┘      │
│          │                  │                  │                │
└──────────┼──────────────────┼──────────────────┼────────────────┘
           │                  │                  │
           │                  │                  │
┌──────────▼──────────────────▼──────────────────▼────────────────┐
│                         API Layer                                │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  goose.api: open_input(), run(), close(), ...              ││
│  └────────────────────────────┬────────────────────────────────┘│
│                               │                                  │
│  ┌────────────────────────────▼────────────────────────────────┐│
│  │  goose.core: open(), run(), stop(), select_session()       ││
│  └────────────────────────────┬────────────────────────────────┘│
└───────────────────────────────┼──────────────────────────────────┘
                                │
┌───────────────────────────────▼──────────────────────────────────┐
│                      Execution Layer                             │
│  ┌────────────────────────────┬────────────────────────────────┐│
│  │  goose.job                 │  goose.ui                      ││
│  │  - build_args()            │  - create_windows()            ││
│  │  - execute() [plenary.job] │  - render_output()             ││
│  │  - stop()                  │  - focus_input/output()        ││
│  └────────────────────────────┴────────────────────────────────┘│
└───────────────────────────────┬──────────────────────────────────┘
                                │
┌───────────────────────────────▼──────────────────────────────────┐
│                      Goose CLI Binary                            │
│  goose run --text "prompt"                                       │
│  goose run --recipe path.yaml --params key=val --interactive     │
└──────────────────────────────────────────────────────────────────┘
```

**Current Issue**: Recipe picker bypasses goose.api/core and calls goose CLI directly via ToggleTerm.

---

## Relevant File Paths

### goose.nvim Core Plugin
- `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/`
  - `api.lua` - Public API (200 lines, 21 functions)
  - `core.lua` - Core orchestration (150 lines)
  - `job.lua` - Process management (80 lines)
  - `state.lua` - Global state
  - `ui/ui.lua` - UI orchestration
  - `session.lua` - Session persistence

### Custom Recipe Picker Extension
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/`
  - `init.lua` - Plugin configuration (96 lines)
  - `picker/init.lua` - Telescope picker (148 lines)
  - `picker/execution.lua` - Recipe execution (191 lines, **ISSUE HERE**)
  - `picker/discovery.lua` - Recipe finding (120 lines)
  - `picker/metadata.lua` - YAML parsing
  - `picker/previewer.lua` - Preview window

### Goose Configuration
- `/home/benjamin/.config/goose/config.yaml` - Goose CLI config
- `/home/benjamin/.config/.goose/recipes/` - Project recipes
- `~/.config/goose/recipes/` - Global recipes

---

## Related Documentation

- goose CLI help: `goose run --help`
- Recipe documentation: `goose recipe --help`
- plenary.job: https://github.com/nvim-lua/plenary.nvim
- ToggleTerm: https://github.com/akinsho/toggleterm.nvim

---

## Notes

- goose.nvim version in use: azorng/goose.nvim (main branch)
- Neovim version: Modern (supports lua, plenary, telescope)
- Recipe system is a goose CLI feature, not plugin-specific
- Current picker implementation predates investigation of goose.nvim's native capabilities
