# Goose Utility Picker Design Research Report

## Metadata
- **Date**: 2025-12-09
- **Agent**: research-specialist
- **Topic**: Goose Utility Picker Design
- **Report Type**: codebase analysis

## Executive Summary

The Goose plugin architecture supports multiple utilities (recipes, sessions, config management) through a simple `<leader>aR` keybinding that uses `vim.ui.select` for recipe picking. The existing Claude Code picker demonstrates a sophisticated hierarchical design with Telescope integration, modular architecture, and multiple artifact types. A Goose picker utility should extend the current recipe-only implementation to manage sessions, configurations, and recipe parameters with the same semantic patterns as the Claude picker.

## Findings

### Finding 1: Current Goose Recipe Execution Pattern
- **Description**: The existing `<leader>aR` keybinding implements recipe selection via `vim.ui.select` with parameter input and ToggleTerm execution. The implementation is minimal (39 lines) and located inline within which-key.lua.
- **Location**: /home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua (lines 371-413)
- **Evidence**:
```lua
{ "<leader>aR", function()
  -- Find recipes in .goose/recipes/
  local cwd = vim.fn.getcwd()
  local recipe_dir = cwd .. "/.goose/recipes"

  -- Get recipe files
  local recipes = vim.fn.globpath(recipe_dir, "*.yaml", false, true)

  -- Build picker items
  local items = {}
  for _, path in ipairs(recipes) do
    local name = vim.fn.fnamemodify(path, ":t:r")
    table.insert(items, { name = name, path = path })
  end

  -- Use vim.ui.select for recipe picker
  vim.ui.select(items, {
    prompt = "Select recipe to run:",
    format_item = function(item) return item.name end,
  }, function(choice)
    if not choice then return end

    -- Ask for parameters (optional)
    vim.ui.input({ prompt = "Parameters (key=value, comma-separated, or empty): " }, function(params)
      local cmd = "goose run --recipe " .. vim.fn.shellescape(choice.path) .. " --interactive"
      if params and params ~= "" then
        for param in params:gmatch("[^,]+") do
          cmd = cmd .. " --params " .. vim.fn.trim(param)
        end
      end
      vim.cmd("TermExec cmd='" .. cmd .. "'")
    end)
  end)
end, desc = "goose run recipe", icon = "󰑮" }
```
- **Impact**: The current implementation provides a foundation for expansion but only handles recipes. There's no session management, configuration switching, or preview functionality. The inline implementation limits reusability and testability.

### Finding 2: Claude Code Picker Architecture as Reference Model
- **Description**: The Claude Code picker implements a sophisticated hierarchical architecture with Telescope integration, supporting commands, agents, docs, libraries, templates, hooks, TTS files, scripts, and tests. The picker uses a modular design with separation of concerns across display, operations, artifacts, and utilities.
- **Location**: /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/init.lua (lines 1-272)
- **Evidence**:
```lua
-- Main orchestration module structure
local M = {}

-- Telescope dependencies
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Local modules (modular architecture)
local parser = require("neotex.plugins.ai.claude.commands.parser")
local entries = require("neotex.plugins.ai.claude.commands.picker.display.entries")
local previewer = require("neotex.plugins.ai.claude.commands.picker.display.previewer")
local sync = require("neotex.plugins.ai.claude.commands.picker.operations.sync")
local edit = require("neotex.plugins.ai.claude.commands.picker.operations.edit")
local terminal = require("neotex.plugins.ai.claude.commands.picker.operations.terminal")

-- Context-aware Enter key: direct action execution (lines 72-132)
actions.select_default:replace(function()
  if selection.value.command then
    terminal.send_command_to_terminal(selection.value.command)
  elseif selection.value.entry_type == "agent" then
    edit.edit_artifact_file(selection.value.agent.filepath)
  -- ... 8+ artifact types handled
end)

-- Rich keybindings for operations
map("i", "<C-l>", function() ... end)  -- Load locally
map("i", "<C-u>", function() ... end)  -- Update from global
map("i", "<C-s>", function() ... end)  -- Save to global
map("i", "<C-e>", function() ... end)  -- Edit file
map("i", "<C-n>", function() ... end)  -- Create new
map("i", "<C-r>", function() ... end)  -- Run script
map("i", "<C-t>", function() ... end)  -- Run test
```
- **Impact**: The Claude picker demonstrates best practices for picker architecture: modular design enables maintainability, Telescope integration provides rich preview/filtering, multiple keybindings support diverse operations, and hierarchical display organizes complex artifact types. This architecture should be adapted for Goose utilities.

### Finding 3: Goose Configuration and Recipe Structure
- **Description**: Goose maintains configuration in `~/.config/goose/config.yaml` (3 lines: provider, model, mode) and recipes in `.goose/recipes/` with YAML structure including parameters, instructions, sub_recipes, retry checks, and checkpoints. The configuration is minimal but recipes are comprehensive with workflow orchestration capabilities.
- **Location**: /home/benjamin/.config/goose/config.yaml (lines 1-3), /home/benjamin/.config/.goose/recipes/create-plan.yaml (lines 1-308)
- **Evidence**:
```yaml
# config.yaml (simple 3-line configuration)
GOOSE_PROVIDER: gemini-cli
GOOSE_MODEL: gemini-3-pro-preview-11-2025
GOOSE_MODE: auto

# create-plan.yaml (comprehensive recipe structure)
name: create-plan
description: Research and create new implementation plan workflow

parameters:
  - key: feature_description
    input_type: string
    requirement: user_prompt
    description: Natural language description of feature to implement

  - key: complexity
    input_type: number
    requirement: optional
    default: 3

instructions: |
  You are executing a research-and-plan workflow that creates comprehensive research reports...

  ## STEP 1: Initialize Workflow State
  ## STEP 2: Research Phase - Invoke Research Workflow
  ## STEP 3: Standards Injection
  ## STEP 4: Planning Phase - Invoke Plan Architect
  ## STEP 5: Return Completion Signal

sub_recipes:
  - name: research-specialist
    path: ./subrecipes/research-specialist.yaml
  - name: plan-architect
    path: ./subrecipes/plan-architect.yaml

retry:
  max_attempts: 3
  checks:
    - type: shell
      command: "test -d {{ topic_path }}"
```
- **Impact**: Goose utilities extend beyond simple recipe execution to include: session management (list/resume/switch), configuration management (provider/model/mode switching), recipe parameter discovery and validation, and recipe history tracking. A picker utility should expose all these capabilities through a unified interface.

### Finding 4: Goose Plugin UI Configuration and Provider Detection
- **Description**: The goose.nvim plugin implements multi-provider detection (Gemini CLI, Claude Code) with dynamic configuration, provider status checking, and UI configuration for window layout, mode selection, and keybindings. The plugin uses lazy loading with command triggers.
- **Location**: /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua (lines 14-95), which-key.lua (lines 414-456)
- **Evidence**:
```lua
-- Dynamic provider detection (init.lua lines 14-64)
local providers = {}
local warnings = {}

-- Detect Gemini provider (API key or CLI authentication)
local has_gemini_api = vim.env.GEMINI_API_KEY ~= nil
local has_gemini_cli = vim.fn.executable("gemini") == 1

if has_gemini_api or has_gemini_cli then
  local gemini_model = vim.env.GEMINI_MODEL or "gemini-3-pro-preview-11-2025"
  providers.google = { gemini_model }
end

-- Detect Claude Code provider (CLI authentication with Pro/Max subscription)
local has_claude_cli = vim.fn.executable("claude") == 1
if has_claude_cli then
  local status_output = vim.fn.system("claude /status 2>&1")
  local is_authenticated = status_output:match("Logged in") ~= nil
  local has_subscription = status_output:match("Pro") ~= nil or status_output:match("Max") ~= nil
  if is_authenticated and has_subscription then
    providers["claude-code"] = { "claude-sonnet-4-5-20250929" }
  end
end

-- Provider backend keybinding (which-key.lua lines 414-455)
{ "<leader>ab", function()
  -- Build status message
  local status = {}
  if has_gemini_api or has_gemini_cli then
    table.insert(status, "[OK] Gemini" .. tier_info)
  end
  if has_claude_cli and is_authenticated and has_subscription then
    table.insert(status, "[OK] Claude Code")
  end

  vim.notify("Provider Status:\n\n" .. table.concat(status, "\n"), vim.log.levels.INFO)
  vim.defer_fn(function()
    vim.cmd("GooseConfigureProvider")
  end, 1000)
end, desc = "goose backend/provider", icon = "󰒓" }
```
- **Impact**: Provider management is currently hardcoded in keybindings and relies on goose.nvim commands. A picker utility should integrate provider status checking, model selection, and mode switching into a unified interface with session and recipe management.

### Finding 5: Telescope and vim.ui.select Integration Patterns
- **Description**: Neovim picker patterns support both Telescope (rich preview, filtering, custom keybindings) and vim.ui.select (simple selection, graceful degradation). The telescope-ui-select.nvim extension bridges core vim.ui.select to Telescope, while dressing.nvim enables custom telescope fields for enhanced UIs. The toggleterm-manager.nvim demonstrates terminal buffer management with Telescope integration.
- **Location**: External references (GitHub and documentation sources)
- **Evidence**:
From web research:
- `telescope-ui-select.nvim` sets `vim.ui.select` to telescope, enabling core Neovim features (like `vim.lsp.buf.code_action()`) to use Telescope pickers
- `dressing.nvim` extends `vim.ui.select` opts with a `telescope` field for custom picker configuration: "If a user has both dressing and telescope installed, they will get your custom picker UI. If either of those are not true, the selection UI will gracefully degrade to whatever the user has configured for vim.ui.select"
- `toggleterm-manager.nvim` provides Telescope extension for ToggleTerm buffers with customizable result fields and six pre-defined actions mappable to keybindings
- `:TermSelect` command in toggleterm.nvim uses `vim.ui.select` for terminal selection: "This can be useful if you have a lot of terminals and want to open a specific one"
- **Impact**: A Goose picker should use Telescope as the primary implementation with vim.ui.select fallback for environments without Telescope. The picker should leverage telescope-ui-select for consistent UX with other Neovim features and implement preview windows for recipe instructions, session details, and configuration values.

### Finding 6: Recipe Discovery and Session Management Infrastructure
- **Description**: The Goose ecosystem maintains recipes in `.goose/recipes/` (9 files including subrecipes), supports session persistence (location unclear from config.yaml), and provides CLI commands for recipe operations (list, validate, deeplink, run). The recipe structure supports parameters, sub_recipes, retry logic, and checkpoints for workflow orchestration.
- **Location**: /home/benjamin/.config/.goose/recipes/ (9 YAML files discovered)
- **Evidence**:
Recipe files discovered:
```
/home/benjamin/.config/.goose/recipes/revise.yaml
/home/benjamin/.config/.goose/recipes/implement.yaml
/home/benjamin/.config/.goose/recipes/create-plan.yaml
/home/benjamin/.config/.goose/recipes/research.yaml
/home/benjamin/.config/.goose/recipes/tests/test-params.yaml
/home/benjamin/.config/.goose/recipes/subrecipes/plan-architect.yaml
/home/benjamin/.config/.goose/recipes/subrecipes/implementer-coordinator.yaml
/home/benjamin/.config/.goose/recipes/subrecipes/topic-naming.yaml
/home/benjamin/.config/.goose/recipes/subrecipes/research-specialist.yaml
```

From README documentation (lines 427-486):
```markdown
## Recipe CLI Commands

| Command | Description |
|---------|-------------|
| `goose recipe list` | List available recipes |
| `goose recipe validate <file>` | Validate recipe syntax |
| `goose recipe deeplink <file>` | Generate shareable link |
| `goose recipe open <file>` | Open in Goose Desktop |

## Recipe Storage

- **Project recipes**: `.goose/recipes/` (project-specific workflows)
- **Global recipes**: `~/.config/goose/recipes/`
- **Scheduled recipes**: `~/.local/share/goose/scheduled_recipes/`
- **Team recipes**: Set `GOOSE_RECIPE_GITHUB_REPO=user/repo` to share via GitHub

## Session Persistence

- Sessions are automatically saved to `~/.config/goose/sessions/`
- Each workspace has its own session history
- Sessions persist across Neovim restarts
- Use `:GooseSelectSession` to switch between sessions
```
- **Impact**: A picker utility must integrate with multiple storage locations (project/global/scheduled/team recipes) and session directories. The picker should parse recipe metadata (name, description, parameters), validate recipe files before execution, display session history with timestamps, and provide quick access to recipe management commands (validate, deeplink, edit).

### Finding 7: Neovim Picker Infrastructure Analysis
- **Description**: The Neovim configuration supports Telescope with standard setup (`prefered_picker = "telescope"` in goose.nvim), but the current recipe picker uses vanilla `vim.ui.select` without Telescope integration. The which-key configuration provides icon support and hierarchical grouping, which should be leveraged for a unified Goose utilities picker.
- **Location**: /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua (line 68), which-key.lua (lines 244-457)
- **Evidence**:
```lua
-- goose.nvim configuration specifies Telescope preference
require("goose").setup({
  prefered_picker = "telescope", -- or 'fzf', 'mini.pick', 'snacks'
  default_global_keymaps = false,  -- Managed by which-key
  -- ... other config
})

-- which-key provides grouping and icons for AI commands
wk.add({
  { "<leader>a", group = "ai", icon = "󰚩", mode = { "n", "v" } },

  -- Claude commands use hierarchical organization
  { "<leader>ac", "<cmd>ClaudeCommands<CR>", desc = "claude commands", icon = "󰘳" },
  { "<leader>as", function() require("neotex.plugins.ai.claude").resume_session() end, desc = "claude sessions", icon = "󰑐" },

  -- Goose commands are flat, single-purpose bindings
  { "<leader>ag", "<cmd>Goose<CR>", desc = "goose toggle", icon = "󰚩" },
  { "<leader>aR", function() ... end, desc = "goose run recipe", icon = "󰑮" },
  { "<leader>ab", function() ... end, desc = "goose backend/provider", icon = "󰒓" },
  { "<leader>aq", "<cmd>GooseClose<CR>", desc = "goose quit", icon = "󰅖" },
})
```
- **Impact**: The infrastructure exists for Telescope integration but isn't leveraged. A unified Goose utilities picker should consolidate multiple single-purpose keybindings (`<leader>aR`, `<leader>ab`) into a hierarchical picker similar to Claude's `<leader>ac`. This would reduce keybinding clutter, provide better discoverability, and enable preview functionality for recipes, sessions, and configuration options.

## Recommendations

### 1. **Modular Picker Architecture** (Priority: HIGH)
**Rationale**: The current inline implementation in which-key.lua (Finding 1) is not maintainable or testable. The Claude picker demonstrates a proven modular design (Finding 2) with separation of concerns.

**Design Pattern**:
```
nvim/lua/neotex/plugins/ai/goose/picker/
├── init.lua                  # Main orchestration (show_goose_picker)
├── display/
│   ├── entries.lua          # Entry formatting for hierarchical display
│   └── previewer.lua        # Preview window for recipes/sessions/config
├── operations/
│   ├── recipes.lua          # Recipe execution, parameter input, validation
│   ├── sessions.lua         # Session listing, resume, delete
│   └── config.lua           # Provider switching, model selection, mode toggle
└── utils/
    ├── parser.lua           # YAML recipe parsing, session file reading
    └── helpers.lua          # Notifications, validation, error handling
```

**Action Items**:
1. Create modular directory structure at `nvim/lua/neotex/plugins/ai/goose/picker/`
2. Extract recipe execution logic from which-key.lua into `operations/recipes.lua`
3. Implement Telescope picker in `init.lua` following Claude picker patterns (lines 42-268)
4. Create preview windows for recipe instructions, session details, and provider status
5. Replace inline keybinding with `{ "<leader>aG", function() require("neotex.plugins.ai.goose.picker").show_goose_picker() end, desc = "goose utilities", icon = "󰑮" }`

### 2. **Hierarchical Display with Multiple Utility Categories** (Priority: HIGH)
**Rationale**: Goose utilities span recipes, sessions, and configuration (Findings 3, 4, 6) but lack a unified interface. The Claude picker demonstrates hierarchical organization with 8+ artifact types (Finding 2), which reduces keybinding clutter (Finding 7) and improves discoverability.

**Hierarchy Design**:
```
┌─────────────────────────────────────────────────────┐
│ 🎯 Goose Utilities                                   │
├─────────────────────────────────────────────────────┤
│ ━━━ RECIPES ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│   📋 create-plan      - Research and create plan    │
│   📋 implement        - Execute implementation plan │
│   📋 research         - Research workflow           │
│   📋 revise           - Revise implementation plan  │
│                                                      │
│ ━━━ SESSIONS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│   💬 workspace-abc123 - 3 msgs, 2h ago (active)     │
│   💬 feature-xyz789   - 15 msgs, 1d ago             │
│   💬 debug-session    - 8 msgs, 3d ago              │
│                                                      │
│ ━━━ CONFIGURATION ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│   ⚙️  Provider: gemini-cli (✓ OK)                   │
│   ⚙️  Model: gemini-3-pro-preview-11-2025           │
│   ⚙️  Mode: auto (file editing enabled)             │
│                                                      │
│ ━━━ RECIPE MANAGEMENT ━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│   📦 Validate all recipes                           │
│   📦 Refresh recipe cache                           │
│   📦 Open global recipes directory                  │
└─────────────────────────────────────────────────────┘
```

**Entry Types**:
- `heading` - Section separators (non-selectable)
- `recipe` - Executable recipes with parameter input
- `session` - Resumable sessions with preview
- `config_item` - Configuration values (provider, model, mode)
- `management_action` - Recipe/session management operations

**Action Items**:
1. Implement `entries.lua` with hierarchical entry generation (headings, recipes, sessions, config, management)
2. Create `previewer.lua` with context-aware preview (recipe instructions for recipes, session messages for sessions, provider status for config)
3. Add icon mappings: `📋` recipes, `💬` sessions, `⚙️` config, `📦` management
4. Implement entry filtering by type (optional: allow user to filter by category)

### 3. **Rich Keybindings for Context-Aware Operations** (Priority: MEDIUM)
**Rationale**: The Claude picker provides 7 keybindings for diverse operations (Finding 2). The current Goose implementation only supports Enter to execute (Finding 1). Context-aware keybindings enable power users to perform operations efficiently.

**Keybinding Mapping**:
```lua
-- Context-aware Enter key (primary action)
<CR>    - Recipe: Execute with parameter input → ToggleTerm
        - Session: Resume in ToggleTerm
        - Config: Open provider/model/mode picker
        - Management: Execute action (validate, refresh, open directory)

-- Secondary operations
<C-e>   - Edit: Open recipe YAML or session file in buffer
<C-p>   - Preview: Toggle preview window visibility
<C-v>   - Validate: Run `goose recipe validate <file>` for recipes
<C-d>   - Delete: Delete session or recipe file (with confirmation)
<C-r>   - Refresh: Reload picker data (recipes, sessions, config)
<C-l>   - Link: Generate deeplink for recipe sharing
<C-h>   - Help: Show keybinding help overlay
```

**Special Keybindings for Recipes**:
```lua
<C-a>   - Run recipe with all parameters (skip interactive input)
<C-i>   - Run recipe in interactive mode (default)
<C-x>   - Run recipe with --explain flag (preview mode)
<C-m>   - Run recipe with --max-turns limit (debugging)
```

**Action Items**:
1. Implement keybinding mapping in `init.lua` using `attach_mappings` pattern (Claude picker lines 61-267)
2. Create `operations/recipes.lua` with functions: `execute_recipe`, `validate_recipe`, `generate_deeplink`, `edit_recipe`
3. Create `operations/sessions.lua` with functions: `resume_session`, `delete_session`, `view_session_details`
4. Create `operations/config.lua` with functions: `switch_provider`, `select_model`, `toggle_mode`
5. Add help overlay with `<C-h>` showing all available keybindings

### 4. **Recipe Parameter Discovery and Validation** (Priority: MEDIUM)
**Rationale**: Recipes define parameters with types, requirements, and defaults (Finding 3). The current implementation uses comma-separated string input without validation (Finding 1). Structured parameter input improves UX and prevents execution errors.

**Parameter Discovery Flow**:
```lua
-- 1. Parse recipe YAML to extract parameters
local recipe = parser.parse_recipe_yaml(recipe_path)
local params = recipe.parameters  -- Array of parameter definitions

-- 2. Present interactive parameter input (one-by-one or batch)
for _, param in ipairs(params) do
  if param.requirement == "required" or param.requirement == "user_prompt" then
    vim.ui.input({
      prompt = param.description .. " [" .. param.input_type .. "]: ",
      default = param.default
    }, function(value)
      validated_params[param.key] = validate_param(value, param.input_type)
    end)
  end
end

-- 3. Build goose command with validated parameters
local cmd = "goose run --recipe " .. recipe_path .. " --interactive"
for key, value in pairs(validated_params) do
  cmd = cmd .. " --params " .. key .. "=" .. vim.fn.shellescape(value)
end
```

**Validation Rules**:
- `input_type: string` - Accept any non-empty string
- `input_type: number` - Validate numeric input (tonumber)
- `input_type: boolean` - Convert to true/false
- `requirement: required` - Prompt must be answered (no empty input)
- `requirement: optional` - Use default if not provided

**Action Items**:
1. Create `utils/parser.lua` with `parse_recipe_yaml(path)` function using Lua YAML library or bash fallback
2. Implement parameter validation functions: `validate_string`, `validate_number`, `validate_boolean`
3. Create interactive parameter input flow in `operations/recipes.lua`
4. Display parameter metadata in preview window (name, type, requirement, default, description)
5. Cache parsed recipes for performance (invalidate on file modification)

### 5. **Session Management Integration** (Priority: MEDIUM)
**Rationale**: Goose sessions persist in `~/.config/goose/sessions/` (Finding 6) but lack Neovim integration beyond the goose.nvim floating window. The picker should provide session listing, resume, and cleanup functionality similar to Claude's session management (Finding 2).

**Session Discovery**:
```lua
-- 1. List session files
local session_dir = vim.fn.expand("~/.config/goose/sessions/")
local session_files = vim.fn.globpath(session_dir, "*.json", false, true)

-- 2. Parse session metadata
local sessions = {}
for _, path in ipairs(session_files) do
  local content = vim.fn.readfile(path)
  local session = vim.fn.json_decode(table.concat(content, "\n"))
  table.insert(sessions, {
    id = session.session_id,
    workspace = session.workspace,
    message_count = #session.messages,
    last_modified = vim.fn.getftime(path),
    is_active = check_active_session(session.session_id)
  })
end

-- 3. Sort by last_modified (most recent first)
table.sort(sessions, function(a, b) return a.last_modified > b.last_modified end)
```

**Session Operations**:
- **Resume**: Execute `goose --resume <session_id>` in ToggleTerm
- **Delete**: Remove session file with confirmation dialog
- **View Details**: Preview session messages, timestamps, and workspace context
- **Cleanup**: Delete old sessions (configurable age threshold)

**Action Items**:
1. Create `operations/sessions.lua` with session discovery and parsing logic
2. Implement session entry formatting with workspace, message count, and time ago
3. Add session preview with message history (last N messages)
4. Integrate with ToggleTerm for session resumption
5. Add session cleanup command (delete sessions older than N days)

### 6. **Provider and Configuration Management** (Priority: LOW)
**Rationale**: Provider detection is duplicated in goose.nvim init.lua and which-key.lua (Finding 4). The picker should consolidate provider status checking, model selection, and mode switching into a unified interface.

**Configuration Display**:
```lua
-- Current configuration (parsed from ~/.config/goose/config.yaml)
local config = {
  provider = "gemini-cli",  -- or "claude-code"
  model = "gemini-3-pro-preview-11-2025",
  mode = "auto"  -- or "chat"
}

-- Provider status (dynamic detection)
local provider_status = {
  gemini = {
    available = has_gemini_cli,
    authenticated = check_gemini_auth(),
    models = { "gemini-3-pro-preview-11-2025", "gemini-2.0-flash-exp" }
  },
  claude_code = {
    available = has_claude_cli,
    authenticated = check_claude_auth(),
    subscription = check_claude_subscription(),  -- Pro/Max
    models = { "claude-sonnet-4-5-20250929" }
  }
}
```

**Configuration Operations**:
- **Switch Provider**: Show provider picker (gemini-cli, claude-code) with status indicators
- **Select Model**: Show model picker for current provider (filtered by tier)
- **Toggle Mode**: Switch between auto (file editing) and chat (conversation only)
- **View Status**: Preview current config with provider authentication details

**Action Items**:
1. Create `operations/config.lua` with config reading/writing functions
2. Implement provider detection logic (consolidate from init.lua and which-key.lua)
3. Add config entries to picker hierarchy (provider, model, mode)
4. Create config preview with provider status, authentication, and available models
5. Implement config update flow with YAML file writing

## References

### Files Analyzed

- [/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua] (lines 1-801) - Keybinding configuration and current recipe picker implementation
- [/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua] (lines 1-96) - goose.nvim plugin configuration and provider detection
- [/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md] (lines 1-698) - Goose integration documentation and usage workflows
- [/home/benjamin/.config/goose/config.yaml] (lines 1-3) - Goose configuration file structure
- [/home/benjamin/.config/.goose/recipes/create-plan.yaml] (lines 1-308) - Example recipe structure with parameters and workflow orchestration
- [/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/init.lua] (lines 1-162) - Claude module public API and integration patterns
- [/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/ui/pickers.lua] (lines 1-273) - Claude session picker implementation
- [/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua] (lines 1-18) - Claude commands picker facade
- [/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/init.lua] (lines 1-272) - Claude picker orchestration with hierarchical display and rich keybindings

### Recipe Files Discovered

- [/home/benjamin/.config/.goose/recipes/revise.yaml]
- [/home/benjamin/.config/.goose/recipes/implement.yaml]
- [/home/benjamin/.config/.goose/recipes/create-plan.yaml]
- [/home/benjamin/.config/.goose/recipes/research.yaml]
- [/home/benjamin/.config/.goose/recipes/tests/test-params.yaml]
- [/home/benjamin/.config/.goose/recipes/subrecipes/plan-architect.yaml]
- [/home/benjamin/.config/.goose/recipes/subrecipes/implementer-coordinator.yaml]
- [/home/benjamin/.config/.goose/recipes/subrecipes/topic-naming.yaml]
- [/home/benjamin/.config/.goose/recipes/subrecipes/research-specialist.yaml]

### External Documentation

- [GitHub - nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - Telescope fuzzy finder plugin documentation
- [GitHub - nvim-telescope/telescope-ui-select.nvim](https://github.com/nvim-telescope/telescope-ui-select.nvim) - Telescope extension for vim.ui.select integration
- [GitHub - stevearc/dressing.nvim](https://github.com/stevearc/dressing.nvim) - Plugin for improving vim.ui interfaces with custom telescope fields
- [GitHub - ibhagwan/fzf-lua](https://github.com/ibhagwan/fzf-lua) - Alternative fuzzy finder with vim.ui.select support
- [GitHub - akinsho/toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) - Terminal management plugin with TermSelect command
- [GitHub - ryanmsnyder/toggleterm-manager.nvim](https://github.com/ryanmsnyder/toggleterm-manager.nvim) - Telescope extension for ToggleTerm buffer management
- [Telescope | LazyVim](http://www.lazyvim.org/extras/editor/telescope) - LazyVim Telescope configuration examples
- [LazyVim 14 Breaking Changes](https://www.lorenzobettini.it/2024/12/lazyvim-14-some-new-and-breaking-features/) - Migration from Telescope to fzf-lua as default picker
