# Recipe Execution and Keybinding Integration Research

**Research Date**: 2025-12-09
**Researcher**: research-specialist agent
**Topic**: Recipe execution capability and &lt;leader&gt;aR keybinding refactoring
**Project**: /home/benjamin/.config

---

## Executive Summary

This research investigates the current &lt;leader&gt;aR recipe execution implementation in the Goose Neovim integration and documents the migration path to a unified picker-based interface. The current implementation uses `vim.ui.select` with basic recipe discovery, while the target architecture leverages the existing Telescope-based picker infrastructure used in the Claude commands picker for consistent UX and advanced features.

**Key Findings**:
- Current &lt;leader&gt;aR uses `vim.ui.select` for basic recipe selection with parameter input
- Recipes are YAML files stored in `.goose/recipes/` (project-specific) or `~/.config/goose/recipes/` (global)
- Recipe format follows Goose v1.0.0 specification with parameters, instructions, and subrecipes
- Existing Claude picker infrastructure (`neotex.plugins.ai.claude.commands.picker`) provides reusable patterns
- Migration path requires picker module creation, Telescope integration, and keybinding refactoring

---

## 1. Current &lt;leader&gt;aR Recipe Execution Implementation

### 1.1 Keybinding Definition

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` (lines 371-413)

```lua
{ "<leader>aR", function()
  -- Find recipes in .goose/recipes/
  local cwd = vim.fn.getcwd()
  local recipe_dir = cwd .. "/.goose/recipes"

  if vim.fn.isdirectory(recipe_dir) ~= 1 then
    vim.notify("No .goose/recipes/ directory found in " .. cwd, vim.log.levels.WARN)
    return
  end

  -- Get recipe files
  local recipes = vim.fn.globpath(recipe_dir, "*.yaml", false, true)
  if #recipes == 0 then
    vim.notify("No recipes found in " .. recipe_dir, vim.log.levels.WARN)
    return
  end

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
end, desc = "goose run recipe", icon = "󰑮" },
```

### 1.2 Current Workflow

1. **Discovery**: Scans `.goose/recipes/` for `*.yaml` files using `vim.fn.globpath()`
2. **Selection**: Presents list via `vim.ui.select()` (Telescope dropdown via `telescope-ui-select` extension)
3. **Parameters**: Prompts for comma-separated `key=value` pairs via `vim.ui.input()`
4. **Execution**: Launches `goose run --recipe <path> --interactive --params <params>` in ToggleTerm

**Limitations**:
- No recipe preview (description, parameters, instructions)
- No validation of parameter format or required parameters
- No fallback to global recipes (`~/.config/goose/recipes/`)
- No categorization or filtering (all recipes shown in flat list)
- No integration with existing picker infrastructure (duplicated logic)

---

## 2. Recipe File Format and Discovery

### 2.1 Recipe YAML Structure

Recipes follow Goose v1.0.0 specification (example from `.goose/recipes/create-plan.yaml`):

```yaml
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
    description: Research complexity level (1-4, default 3)

instructions: |
  You are executing a research-and-plan workflow...
  [Multi-step instructions with bash blocks and validation]

sub_recipes:
  - name: research-specialist
    path: ./subrecipes/research-specialist.yaml
    description: Phase 1 - Research phase

retry:
  max_attempts: 3
  checks:
    - type: shell
      command: "test -d {{ topic_path }}"
      description: "Verify topic directory created"
```

**Key Fields**:
- `name`: Recipe identifier (used in CLI invocation)
- `description`: Human-readable summary (for picker display)
- `parameters`: Array of parameter definitions with validation metadata
  - `key`: Parameter name (used in `{{ key }}` template substitution)
  - `input_type`: `string`, `number`, `boolean`, `file`, etc.
  - `requirement`: `required`, `optional`, `user_prompt` (prompts user if not provided)
  - `default`: Default value for optional parameters
  - `description`: Help text for parameter
- `instructions`: Multi-line text with Goose-specific directives and bash blocks
- `sub_recipes`: Nested recipe invocations (for orchestration workflows)
- `retry`: Hard barrier validation with shell checks

### 2.2 Recipe Storage Locations

**Project-Specific Recipes** (`.goose/recipes/`):
- Location: `/home/benjamin/.config/.goose/recipes/`
- Purpose: Workflow automation for this project (create-plan, implement, research, revise)
- Files:
  - `create-plan.yaml` (308 lines) - Research-and-plan workflow
  - `implement.yaml` (13,343 bytes) - Implementation orchestration
  - `research.yaml` (112 lines) - Research workflow
  - `revise.yaml` (11,968 bytes) - Plan revision workflow
- Subrecipes: `.goose/recipes/subrecipes/`
  - `plan-architect.yaml`
  - `research-specialist.yaml`
  - `topic-naming.yaml`
  - `implementer-coordinator.yaml`

**Global Recipes** (`~/.config/goose/recipes/`):
- Location: Not found in current setup (would be user-wide)
- Purpose: Cross-project reusable workflows

**Scheduled Recipes** (`~/.local/share/goose/scheduled_recipes/`):
- Purpose: Automated recurring tasks (not relevant for picker)

### 2.3 Recipe Discovery Pattern

```lua
-- Current implementation (project-only)
local cwd = vim.fn.getcwd()
local recipe_dir = cwd .. "/.goose/recipes"
local recipes = vim.fn.globpath(recipe_dir, "*.yaml", false, true)

-- Enhanced discovery (project + global)
local locations = {
  { path = vim.fn.getcwd() .. "/.goose/recipes", label = "Project" },
  { path = vim.fn.expand("~/.config/goose/recipes"), label = "Global" }
}

local recipes = {}
for _, loc in ipairs(locations) do
  if vim.fn.isdirectory(loc.path) == 1 then
    local files = vim.fn.globpath(loc.path, "*.yaml", false, true)
    for _, file in ipairs(files) do
      table.insert(recipes, {
        path = file,
        name = vim.fn.fnamemodify(file, ":t:r"),
        location = loc.label
      })
    end
  end
end
```

---

## 3. Recipe Execution Flow

### 3.1 Goose CLI Recipe Commands

**Recipe Validation**:
```bash
goose recipe validate <file>     # Validates YAML syntax and required fields
goose recipe list                # Lists available recipes
goose recipe deeplink <file>     # Generates shareable link
goose recipe open <file>         # Opens in Goose Desktop
```

**Recipe Execution**:
```bash
# Run recipe and exit when complete
goose run --recipe <path>

# Run recipe and continue in interactive mode
goose run --recipe <path> --interactive

# Run with parameters (can be specified multiple times)
goose run --recipe <path> --params key1=value1 --params key2=value2

# Preview recipe without execution
goose run --recipe <path> --explain

# Render recipe template (shows instructions with parameters substituted)
goose run --recipe <path> --render-recipe

# Debug with constraints
goose run --recipe <path> --debug --max-turns 5
```

### 3.2 Parameter Passing

**Current Implementation**:
```lua
-- Comma-separated string parsing
local params = "feature_description=Add dark mode,complexity=3"
for param in params:gmatch("[^,]+") do
  cmd = cmd .. " --params " .. vim.fn.trim(param)
end
-- Result: --params feature_description=Add dark mode --params complexity=3
```

**Issues**:
- Values with commas or equals signs break parsing
- No validation against recipe's parameter definitions
- No default value insertion
- No type checking

**Enhanced Approach**:
```lua
-- Parse recipe YAML to get parameter definitions
local recipe_data = parse_recipe_yaml(recipe_path)

-- Prompt for each required/user_prompt parameter
for _, param in ipairs(recipe_data.parameters) do
  if param.requirement == "required" or param.requirement == "user_prompt" then
    local value = vim.ui.input({
      prompt = param.description .. " (" .. param.key .. "): ",
      default = param.default
    })
    if value then
      params[param.key] = value
    end
  end
end

-- Build CLI command with proper escaping
local cmd_parts = { "goose run --recipe", vim.fn.shellescape(recipe_path), "--interactive" }
for key, value in pairs(params) do
  table.insert(cmd_parts, "--params " .. key .. "=" .. vim.fn.shellescape(value))
end
local cmd = table.concat(cmd_parts, " ")
```

---

## 4. Telescope Picker Integration Patterns

### 4.1 Existing Claude Picker Architecture

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/`

**Module Structure**:
```
picker/
├── init.lua                      # Main orchestration (show_commands_picker)
├── display/
│   ├── entries.lua              # Entry formatting (create_picker_entries)
│   └── previewer.lua            # Preview window logic
├── operations/
│   ├── edit.lua                 # File editing actions
│   ├── sync.lua                 # Global/local synchronization
│   └── terminal.lua             # Terminal execution
├── utils/
│   ├── helpers.lua              # Notification, path utilities
│   └── scan.lua                 # Directory scanning
└── artifacts/
    ├── metadata.lua             # Artifact metadata extraction
    └── registry.lua             # Artifact registration
```

**Key Patterns**:
1. **Entry Creation**: `entries.create_picker_entries(structure)` builds Telescope-compatible entries
2. **Attach Mappings**: Custom key bindings in `attach_mappings` function
   - `<CR>`: Default action (execute/edit)
   - `<C-e>`: Edit file
   - `<C-l>`: Load artifact locally
   - `<C-u>`: Update from global
   - `<C-s>`: Save to global
   - `<C-n>`: Create new command
3. **Previewer**: Custom previewer for markdown/bash content
4. **Terminal Integration**: Uses ToggleTerm for command execution

### 4.2 Telescope Configuration

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/telescope.lua`

**UI-Select Integration** (lines 64-69):
```lua
extensions = {
  ["ui-select"] = {
    require("telescope.themes").get_dropdown({
      winblend = 10,
      previewer = false,
    })
  }
}
```

This means `vim.ui.select()` calls automatically use Telescope dropdown theme, which is why the current recipe picker already uses Telescope without explicit Telescope API calls.

**Available Themes**:
- `get_dropdown()` - Centered dropdown (current recipe picker uses this)
- `get_cursor()` - Small picker at cursor position
- `get_ivy()` - Bottom panel (like Claude commands picker)

### 4.3 Goose Picker Configuration

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua` (line 68)

```lua
prefered_picker = "telescope",  -- or 'fzf', 'mini.pick', 'snacks'
```

This indicates Goose plugin supports multiple picker backends, with Telescope as the preferred option. The picker infrastructure likely uses `vim.ui.select()` internally, which is why it integrates with `telescope-ui-select` extension.

---

## 5. Recipe Preview and Metadata Extraction

### 5.1 YAML Parsing in Lua

**Approach**: Use `vim.json.decode()` after converting YAML to JSON via external tool, or parse manually

**Simple Manual Parser** (for recipe preview):
```lua
local function parse_recipe_metadata(filepath)
  local lines = vim.fn.readfile(filepath)
  local metadata = {
    name = nil,
    description = nil,
    parameters = {}
  }

  local in_parameters = false
  local current_param = nil

  for _, line in ipairs(lines) do
    -- Top-level fields
    if line:match("^name:") then
      metadata.name = line:match("^name:%s*(.+)")
    elseif line:match("^description:") then
      metadata.description = line:match("^description:%s*(.+)")

    -- Parameters section
    elseif line:match("^parameters:") then
      in_parameters = true
    elseif in_parameters and line:match("^%s+- key:") then
      current_param = { key = line:match("key:%s*(.+)") }
      table.insert(metadata.parameters, current_param)
    elseif in_parameters and current_param then
      if line:match("^%s+input_type:") then
        current_param.input_type = line:match("input_type:%s*(.+)")
      elseif line:match("^%s+requirement:") then
        current_param.requirement = line:match("requirement:%s*(.+)")
      elseif line:match("^%s+description:") then
        current_param.description = line:match("description:%s*(.+)")
      elseif line:match("^%s+default:") then
        current_param.default = line:match("default:%s*(.+)")
      end

    -- End of parameters section
    elseif in_parameters and line:match("^%w") then
      in_parameters = false
      current_param = nil
    end
  end

  return metadata
end
```

### 5.2 Recipe Preview Window

**Preview Content Structure**:
```markdown
# Recipe: create-plan

**Description**: Research and create new implementation plan workflow

## Parameters

1. **feature_description** (string, required)
   - Natural language description of feature to implement

2. **complexity** (number, optional, default: 3)
   - Research complexity level (1-4, default 3)

3. **prompt_file** (string, optional)
   - Path to file containing long feature description

## Subrecipes

- research-specialist: Phase 1 - Research phase
- plan-architect: Phase 2 - Planning phase

## Execution

Run with: goose run --recipe .goose/recipes/create-plan.yaml --interactive
```

**Implementation Pattern** (from Claude picker):
```lua
local previewer = require("telescope.previewers")

local recipe_previewer = previewer.new_buffer_previewer({
  title = "Recipe Details",
  define_preview = function(self, entry, status)
    local recipe_path = entry.value.path
    local metadata = parse_recipe_metadata(recipe_path)

    -- Build preview lines
    local lines = {
      "# Recipe: " .. metadata.name,
      "",
      "**Description**: " .. (metadata.description or "No description"),
      "",
      "## Parameters",
      ""
    }

    for i, param in ipairs(metadata.parameters) do
      local req_text = param.requirement or "optional"
      local default_text = param.default and (", default: " .. param.default) or ""
      table.insert(lines, string.format("%d. **%s** (%s, %s%s)",
        i, param.key, param.input_type or "string", req_text, default_text))
      if param.description then
        table.insert(lines, "   - " .. param.description)
      end
      table.insert(lines, "")
    end

    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
  end,
})
```

---

## 6. Migration Path: Refactoring &lt;leader&gt;aR to Picker Interface

### 6.1 Architecture Design

**New Module Structure**:
```
nvim/lua/neotex/plugins/ai/goose/picker/
├── init.lua                      # Main orchestration (show_recipe_picker)
├── discovery.lua                 # Recipe discovery (project + global)
├── metadata.lua                  # YAML parsing and metadata extraction
├── previewer.lua                 # Recipe preview window
├── execution.lua                 # Parameter prompting and CLI execution
└── README.md                     # Documentation
```

### 6.2 Phase 1: Create Picker Module

**File**: `nvim/lua/neotex/plugins/ai/goose/picker/init.lua`

```lua
local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values

local discovery = require("neotex.plugins.ai.goose.picker.discovery")
local metadata = require("neotex.plugins.ai.goose.picker.metadata")
local previewer = require("neotex.plugins.ai.goose.picker.previewer")
local execution = require("neotex.plugins.ai.goose.picker.execution")

--- Show the Goose recipe picker
--- @param opts table Telescope options
function M.show_recipe_picker(opts)
  opts = opts or {}

  -- Discover recipes from project and global locations
  local recipes = discovery.find_recipes()

  if #recipes == 0 then
    vim.notify("No Goose recipes found in .goose/recipes/ or ~/.config/goose/recipes/",
               vim.log.levels.WARN)
    return
  end

  -- Create picker
  pickers.new(opts, {
    prompt_title = "Goose Recipes",
    finder = finders.new_table({
      results = recipes,
      entry_maker = function(recipe)
        return {
          value = recipe,
          display = string.format("[%s] %s", recipe.location, recipe.name),
          ordinal = recipe.name .. " " .. (recipe.metadata.description or ""),
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = previewer.create_recipe_previewer(),
    attach_mappings = function(prompt_bufnr, map)
      -- Enter: Run recipe with parameter prompts
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        if not selection then return end

        actions.close(prompt_bufnr)
        execution.run_recipe(selection.value)
      end)

      -- Ctrl-e: Edit recipe file
      map("i", "<C-e>", function()
        local selection = action_state.get_selected_entry()
        if not selection then return end

        actions.close(prompt_bufnr)
        vim.cmd("edit " .. vim.fn.fnameescape(selection.value.path))
      end)

      -- Ctrl-p: Preview/explain recipe (dry run)
      map("i", "<C-p>", function()
        local selection = action_state.get_selected_entry()
        if not selection then return end

        actions.close(prompt_bufnr)
        local cmd = string.format("goose run --recipe %s --explain",
                                  vim.fn.shellescape(selection.value.path))
        vim.cmd("TermExec cmd='" .. cmd .. "'")
      end)

      -- Ctrl-v: Validate recipe
      map("i", "<C-v>", function()
        local selection = action_state.get_selected_entry()
        if not selection then return end

        local cmd = string.format("goose recipe validate %s",
                                  vim.fn.shellescape(selection.value.path))
        vim.fn.system(cmd)
        if vim.v.shell_error == 0 then
          vim.notify("Recipe is valid", vim.log.levels.INFO)
        else
          vim.notify("Recipe validation failed", vim.log.levels.ERROR)
        end
      end)

      return true
    end,
  }):find()
end

return M
```

### 6.3 Phase 2: Recipe Discovery Module

**File**: `nvim/lua/neotex/plugins/ai/goose/picker/discovery.lua`

```lua
local M = {}

--- Discover recipes from project and global locations
--- @return table List of recipe entries with metadata
function M.find_recipes()
  local recipes = {}

  local locations = {
    {
      path = vim.fn.getcwd() .. "/.goose/recipes",
      label = "Project",
      priority = 1  -- Project recipes first
    },
    {
      path = vim.fn.expand("~/.config/goose/recipes"),
      label = "Global",
      priority = 2
    }
  }

  for _, loc in ipairs(locations) do
    if vim.fn.isdirectory(loc.path) == 1 then
      local files = vim.fn.globpath(loc.path, "*.yaml", false, true)
      for _, filepath in ipairs(files) do
        local name = vim.fn.fnamemodify(filepath, ":t:r")
        local metadata = require("neotex.plugins.ai.goose.picker.metadata").parse(filepath)

        table.insert(recipes, {
          name = name,
          path = filepath,
          location = loc.label,
          priority = loc.priority,
          metadata = metadata
        })
      end
    end
  end

  -- Sort by priority (project first), then alphabetically
  table.sort(recipes, function(a, b)
    if a.priority ~= b.priority then
      return a.priority < b.priority
    end
    return a.name < b.name
  end)

  return recipes
end

return M
```

### 6.4 Phase 3: Metadata Extraction Module

**File**: `nvim/lua/neotex/plugins/ai/goose/picker/metadata.lua`

(See section 5.1 for `parse_recipe_metadata` implementation)

### 6.5 Phase 4: Execution Module

**File**: `nvim/lua/neotex/plugins/ai/goose/picker/execution.lua`

```lua
local M = {}

--- Run recipe with interactive parameter prompting
--- @param recipe table Recipe entry with path and metadata
function M.run_recipe(recipe)
  local metadata = recipe.metadata
  local params = {}

  -- Prompt for each required/user_prompt parameter
  for _, param in ipairs(metadata.parameters) do
    if param.requirement == "required" or param.requirement == "user_prompt" then
      local prompt_text = string.format("%s (%s): ",
                                        param.description or param.key,
                                        param.key)

      vim.ui.input({
        prompt = prompt_text,
        default = param.default
      }, function(value)
        if value and value ~= "" then
          params[param.key] = value
        elseif param.requirement == "required" then
          vim.notify("Required parameter not provided: " .. param.key,
                     vim.log.levels.ERROR)
          return
        end
      end)
    end
  end

  -- Build command
  local cmd_parts = {
    "goose run --recipe",
    vim.fn.shellescape(recipe.path),
    "--interactive"
  }

  for key, value in pairs(params) do
    table.insert(cmd_parts, "--params " .. key .. "=" .. vim.fn.shellescape(value))
  end

  local cmd = table.concat(cmd_parts, " ")

  -- Execute in ToggleTerm
  vim.cmd("TermExec cmd='" .. cmd .. "'")
end

return M
```

### 6.6 Phase 5: Update Keybinding

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua`

**Replace lines 371-413 with**:
```lua
{ "<leader>aR", function()
  require("neotex.plugins.ai.goose.picker").show_recipe_picker()
end, desc = "goose run recipe", icon = "󰑮" },
```

---

## 7. Integration with Existing Goose Module

### 7.1 Goose Plugin Structure

**Current Structure**:
```
nvim/lua/neotex/plugins/ai/goose/
├── init.lua          # Plugin configuration
└── README.md         # Documentation
```

**Enhanced Structure**:
```
nvim/lua/neotex/plugins/ai/goose/
├── init.lua          # Plugin configuration
├── README.md         # Documentation
└── picker/
    ├── init.lua      # Recipe picker orchestration
    ├── discovery.lua # Recipe discovery
    ├── metadata.lua  # YAML parsing
    ├── previewer.lua # Recipe preview
    ├── execution.lua # CLI execution
    └── README.md     # Picker documentation
```

### 7.2 Picker Module Initialization

**No changes needed to `init.lua`**: The picker is invoked directly from keybinding, similar to how Claude picker is invoked from `:ClaudeCommands` command.

**Optional Enhancement**: Add command for direct invocation:
```lua
-- In init.lua config function
vim.api.nvim_create_user_command("GooseRecipes", function()
  require("neotex.plugins.ai.goose.picker").show_recipe_picker()
end, {
  desc = "Open Goose recipe picker"
})
```

---

## 8. Testing and Validation

### 8.1 Recipe Discovery Tests

**Test Cases**:
1. Empty recipe directories (should show "no recipes" notification)
2. Project recipes only (should display with [Project] label)
3. Global recipes only (should display with [Global] label)
4. Both locations (should merge and sort project-first)
5. Invalid YAML files (should skip gracefully)

### 8.2 Metadata Parsing Tests

**Test Recipes** (`.goose/recipes/tests/test-params.yaml`):
```yaml
name: test-params
description: Test recipe with various parameter types

parameters:
  - key: required_string
    input_type: string
    requirement: required
    description: A required string parameter

  - key: optional_number
    input_type: number
    requirement: optional
    default: 42
    description: An optional number with default

  - key: user_prompt_file
    input_type: file
    requirement: user_prompt
    description: A file path parameter

instructions: |
  Test recipe for parameter handling
```

**Validation**:
- All parameters parsed correctly
- Required/optional/user_prompt requirements detected
- Default values extracted
- Descriptions available for prompts

### 8.3 Execution Tests

**Manual Test Workflow**:
1. Open picker: `<leader>aR`
2. Select recipe with parameters
3. Verify parameter prompts appear in correct order
4. Enter values and verify CLI command construction
5. Confirm recipe executes in ToggleTerm

**Edge Cases**:
- Empty parameter input (should use default or show error for required)
- Special characters in values (should be properly escaped)
- Canceling parameter input (should abort execution)

---

## 9. Reference Implementations

### 9.1 Claude Commands Picker

**Key Lessons**:
- Use Telescope themes for consistent UI (`get_ivy()` for full picker)
- Implement context-aware `<CR>` action (different behavior per entry type)
- Provide multiple keybindings for power users (`<C-e>`, `<C-l>`, `<C-u>`, etc.)
- Show metadata in display string (`[Project] recipe-name`)
- Use `vim.defer_fn()` for picker refresh after async operations

**Reusable Patterns**:
```lua
-- Entry display with metadata badge
display = string.format("[%s] %s", entry.metadata_badge, entry.name)

-- Context-aware enter key
actions.select_default:replace(function()
  local selection = action_state.get_selected_entry()
  if selection.value.is_heading then return end  -- Skip headings
  -- ... dispatch to appropriate action
end)

-- Preview scrolling
map("i", "<C-u>", actions.preview_scrolling_up)
map("i", "<C-d>", actions.preview_scrolling_down)
```

### 9.2 Telescope UI-Select Integration

**Current Setup**: All `vim.ui.select()` calls automatically use Telescope dropdown theme

**Implications**: If we keep using `vim.ui.select()` for parameter input, it will use Telescope automatically. However, for multi-parameter recipes, we may want a dedicated parameter input form.

**Alternative: Parameter Form Picker**:
```lua
-- Instead of multiple vim.ui.input() calls, show all parameters in one picker
local function prompt_parameters(parameters)
  local param_values = {}

  -- Create picker for parameter selection
  pickers.new({}, {
    prompt_title = "Recipe Parameters (Enter to edit, <C-d> to run)",
    finder = finders.new_table({
      results = parameters,
      entry_maker = function(param)
        local value = param_values[param.key] or param.default or ""
        return {
          value = param,
          display = string.format("%s = %s", param.key, value),
          ordinal = param.key
        }
      end
    }),
    -- ... attach_mappings for editing individual parameters
  }):find()

  return param_values
end
```

---

## 10. Implementation Recommendations

### 10.1 Phase-Based Rollout

**Phase 1: Basic Picker** (Minimal viable implementation)
- Create `picker/init.lua` with Telescope integration
- Implement basic recipe discovery (project-only)
- Use existing `vim.ui.input()` for parameters
- Refactor keybinding to use new picker
- **Deliverable**: Functional picker with same UX as current implementation

**Phase 2: Enhanced Discovery** (Improved recipe management)
- Add global recipe support (`~/.config/goose/recipes/`)
- Implement metadata parsing for preview
- Add recipe preview window
- **Deliverable**: Rich recipe browsing experience

**Phase 3: Advanced Features** (Power user capabilities)
- Multi-parameter form picker
- Recipe validation (`<C-v>`)
- Recipe preview/explain (`<C-p>`)
- Recipe editing (`<C-e>`)
- **Deliverable**: Full-featured recipe management interface

### 10.2 Code Reuse Strategy

**Leverage Claude Picker Patterns**:
- `entries.lua` pattern for display string formatting
- `previewer.lua` pattern for markdown preview
- `terminal.lua` pattern for ToggleTerm integration
- `helpers.lua` pattern for notifications and path utilities

**Share Utilities**:
- Create `nvim/lua/neotex/util/yaml.lua` for YAML parsing (usable by both Claude and Goose pickers)
- Create `nvim/lua/neotex/util/terminal.lua` for shared ToggleTerm helpers

### 10.3 Testing Strategy

1. **Unit Tests** (using `plenary.nvim`):
   - `metadata_spec.lua`: Test YAML parsing edge cases
   - `discovery_spec.lua`: Test recipe discovery logic
   - `execution_spec.lua`: Test CLI command construction

2. **Integration Tests**:
   - Create test recipes in `.goose/recipes/tests/`
   - Verify end-to-end workflow (pick → prompt → execute)

3. **Manual Testing**:
   - Test with existing project recipes (`create-plan.yaml`, `implement.yaml`)
   - Verify parameter substitution in CLI commands
   - Confirm ToggleTerm execution

---

## 11. Migration Checklist

- [ ] Create `nvim/lua/neotex/plugins/ai/goose/picker/` directory
- [ ] Implement `picker/init.lua` (Telescope integration)
- [ ] Implement `picker/discovery.lua` (recipe discovery)
- [ ] Implement `picker/metadata.lua` (YAML parsing)
- [ ] Implement `picker/previewer.lua` (recipe preview)
- [ ] Implement `picker/execution.lua` (CLI execution)
- [ ] Update keybinding in `which-key.lua`
- [ ] Create `picker/README.md` (documentation)
- [ ] Write unit tests for metadata parsing
- [ ] Write integration tests for discovery
- [ ] Test with existing project recipes
- [ ] Test with global recipes (if any)
- [ ] Update `nvim/lua/neotex/plugins/ai/goose/README.md` with picker documentation

---

## 12. Appendix: Recipe Examples

### 12.1 Project Recipe: create-plan.yaml

**Purpose**: Research-and-plan workflow orchestration
**Parameters**: `feature_description`, `complexity`, `prompt_file`
**Subrecipes**: `research-specialist`, `plan-architect`
**Validation**: Hard barrier checks for topic directory, report size, plan size, phase count

**Key Features**:
- Multi-step workflow with state transitions
- Bash block execution for directory setup
- Template substitution (`{{ feature_description }}`)
- Retry checks for artifact validation

### 12.2 Global Recipe Example: generate-commit-message.yaml

**Purpose**: Generate conventional commit messages from staged changes
**Parameters**: `commit_format` (conventional/standard/custom)
**Extensions**: `developer` (builtin Goose extension)
**Activities**: Auto-detected use cases for recipe suggestions

**Key Features**:
- Simple single-step recipe
- Conditional formatting based on parameter
- Git integration via `developer` extension

---

## Conclusion

The current `<leader>aR` implementation provides basic recipe execution via `vim.ui.select`, but lacks preview, validation, and advanced discovery features. By creating a dedicated picker module following the Claude picker architecture patterns, we can deliver a rich recipe management experience with:

1. **Unified Discovery**: Project and global recipe support
2. **Rich Preview**: Metadata extraction and preview window
3. **Intelligent Execution**: Parameter validation and type-aware prompting
4. **Power User Features**: Recipe editing, validation, and dry-run preview
5. **Consistent UX**: Telescope integration matching existing picker patterns

The migration path is straightforward: create modular picker components, refactor the keybinding, and incrementally add advanced features. The existing Telescope infrastructure and Claude picker patterns provide proven templates for implementation.

**RESEARCH_COMPLETE**: /home/benjamin/.config/.claude/specs/046_goose_picker_utility_recipes/reports/003-goose-recipes-keybinding.md
