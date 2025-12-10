# Goose Recipe Picker

## Purpose

The Goose Recipe Picker is a comprehensive Telescope-based interface for managing and executing Goose recipes. It provides recipe discovery, rich previews, and native sidebar execution using `goose.core.run()` with `/recipe:<name>` commands. Parameters are prompted conversationally in the goose chat interface.

## Architecture

### Module Structure

```
nvim/lua/neotex/plugins/ai/goose/picker/
├── init.lua          # Main orchestration, Telescope integration, keybindings
├── discovery.lua     # Recipe discovery (project + global), priority sorting
├── metadata.lua      # YAML parsing, parameter extraction, validation rules
├── previewer.lua     # Recipe preview window with markdown formatting
├── execution.lua     # Native sidebar execution via goose.core.run()
└── README.md         # This file
```

### Component Responsibilities

- **init.lua**: Entry point exposing `show_recipe_picker()`, Telescope configuration, keybinding attachment
- **discovery.lua**: Scans `.goose/recipes/` (project) and `~/.config/goose/recipes/` (global), returns merged recipe list
- **metadata.lua**: Parses YAML to extract recipe name, description, parameters, subrecipes
- **previewer.lua**: Custom Telescope previewer displaying recipe metadata in markdown format
- **execution.lua**: Executes recipes via `goose.core.run()` with `/recipe:<name>` command in native sidebar

## Data Flow

```
User presses <leader>aR
  ↓
init.show_recipe_picker() invoked
  ↓
discovery.find_recipes() scans directories
  ↓
metadata.parse() extracts YAML for each recipe
  ↓
Telescope picker displays entries with previewer
  ↓
User selects recipe, presses <CR>
  ↓
execution.run_recipe_in_sidebar() called
  ↓
goose.core.run("/recipe:<name>") executes
  ↓
Goose sidebar opens with recipe context
  ↓
Goose prompts for parameters conversationally
  ↓
Recipe executes with streaming output in sidebar
```

## API Reference

### init.lua

#### `show_recipe_picker(opts)`

Show the Goose recipe picker with Telescope.

**Parameters:**
- `opts` (table|nil): Optional Telescope configuration overrides

**Returns:** nil

**Example:**
```lua
require("neotex.plugins.ai.goose.picker").show_recipe_picker()
```

#### `setup()`

Initialize picker module and register user commands.

**Returns:** nil

### discovery.lua

#### `find_recipes()`

Find all recipes from project and global directories.

**Returns:** table - List of recipe entries with fields:
- `name` (string): Recipe filename without extension
- `path` (string): Absolute path to recipe file
- `location` (string): "[Project]" or "[Global]"
- `priority` (number): Sort priority (1=project, 2=global)

#### `get_recipe_path(recipe_name, location)`

Get absolute path for a recipe file.

**Parameters:**
- `recipe_name` (string): Recipe filename (with or without .yaml extension)
- `location` (string): "project" or "global"

**Returns:** string|nil - Absolute path to recipe file, or nil if not found

### metadata.lua

#### `parse(recipe_path)`

Parse recipe metadata from YAML file.

**Parameters:**
- `recipe_path` (string): Absolute path to recipe YAML file

**Returns:** table|nil - Parsed metadata structure with fields:
- `name` (string): Recipe name
- `description` (string): Recipe description
- `parameters` (table): Array of parameter definitions
- `sub_recipes` (table): Array of subrecipe references
- `instructions` (string): Recipe instructions

#### `extract_parameters(yaml_content)`

Extract parameters section from YAML content.

**Parameters:**
- `yaml_content` (string): Full YAML file content

**Returns:** table - Array of parameter definitions with fields:
- `key` (string): Parameter name
- `input_type` (string): "string", "number", "boolean"
- `requirement` (string): "required", "optional", "user_prompt"
- `description` (string): Parameter description
- `default` (any): Default value (if optional)

### previewer.lua

#### `create_recipe_previewer()`

Create a custom recipe previewer for Telescope.

**Returns:** table - Telescope previewer instance

#### `format_preview(metadata, recipe_path)`

Format recipe metadata for preview display.

**Parameters:**
- `metadata` (table): Parsed recipe metadata from `metadata.parse()`
- `recipe_path` (string): Absolute path to recipe file

**Returns:** table - Array of formatted lines for preview buffer

### execution.lua

#### `run_recipe_in_sidebar(recipe_path, metadata)`

Run a recipe in goose.nvim sidebar using native `goose.core.run()`.

**Parameters:**
- `recipe_path` (string): Absolute path to recipe file (used for name extraction)
- `metadata` (table): Parsed recipe metadata

**Returns:** nil

**Side Effects:**
- Executes `/recipe:<name>` command via `goose.core.run()`
- Opens goose sidebar automatically
- Goose handles parameter prompting conversationally
- Recipe output streams to sidebar with markdown rendering

**Error Handling:**
- Validates goose.nvim is installed
- Shows error notification if goose.core module unavailable
- Gracefully handles missing recipe metadata

#### `prompt_for_parameters(parameters)`

Prompt user for recipe parameters.

**Parameters:**
- `parameters` (table): Array of parameter definitions from metadata

**Returns:** table - Dictionary of parameter key-value pairs

#### `validate_param(value, param_type)`

Validate parameter value against type definition.

**Parameters:**
- `value` (string): User-provided parameter value
- `param_type` (string): Expected type ("string", "number", "boolean")

**Returns:** boolean, any - Valid flag and converted value

#### `_serialize_params(params)`

Serialize parameters table to key=value,key2=value2 format for goose CLI.

**Parameters:**
- `params` (table): Dictionary of parameter key-value pairs

**Returns:** string - Serialized parameter string (empty string if no params)

#### `validate_recipe(recipe_path)`

Validate recipe syntax using goose CLI.

**Parameters:**
- `recipe_path` (string): Absolute path to recipe file

**Returns:** nil

## Usage Examples

### Basic Recipe Execution

```lua
-- Open picker and select recipe
require("neotex.plugins.ai.goose.picker").show_recipe_picker()

-- Or use keybinding
-- Press <leader>aR in normal mode
```

### Programmatic Recipe Execution

```lua
local execution = require("neotex.plugins.ai.goose.picker.execution")
local metadata = require("neotex.plugins.ai.goose.picker.metadata")

-- Parse recipe
local recipe_path = vim.fn.expand("~/.config/goose/recipes/create-plan.yaml")
local meta = metadata.parse(recipe_path)

-- Execute in sidebar with parameters
execution.run_recipe_in_sidebar(recipe_path, meta)
```

### Recipe Discovery

```lua
local discovery = require("neotex.plugins.ai.goose.picker.discovery")

-- Find all recipes
local recipes = discovery.find_recipes()
for _, recipe in ipairs(recipes) do
  print(string.format("%s: %s", recipe.location, recipe.name))
end
```

## Keybindings

The recipe picker provides the following context-aware keybindings:

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>aR` | Open Picker | Open Goose recipe picker (global keybinding) |
| `<CR>` | Execute Recipe | Run selected recipe in sidebar with parameter prompts |
| `<C-e>` | Edit Recipe | Open recipe YAML file in buffer for editing |
| `<C-p>` | Preview Recipe | Run recipe in preview mode (--explain flag) |
| `<C-v>` | Validate Recipe | Validate recipe syntax using goose CLI |
| `<C-r>` | Refresh Picker | Reload recipe list without closing picker |
| `<C-u>` | Scroll Up | Scroll preview window up (Telescope native) |
| `<C-d>` | Scroll Down | Scroll preview window down (Telescope native) |

### Recipe Execution in Sidebar

Recipes execute via goose.nvim's native `/recipe:<name>` command in the sidebar:

- **Native Integration**: Uses `goose.core.run()` for seamless sidebar execution
- **Conversational Parameters**: Goose prompts for required parameters in the chat
- **Markdown Rendering**: Code blocks, headers, and formatting automatically applied
- **Session Integration**: Recipe executions create/resume goose sessions (`<leader>av`)
- **Job Management**: Use `<leader>at` or `:GooseStop` to cancel running recipes
- **Split Window**: Sidebar respects `window_type = "split"` configuration

## Integration Points

### Telescope

The picker uses Telescope's picker framework including:
- **Finders**: Custom finder for recipe entries
- **Sorters**: Generic fuzzy sorter for recipe names
- **Previewers**: Custom previewer for recipe metadata display
- **Actions**: Custom actions for recipe operations (execute, edit, validate)

### goose.nvim

Recipe execution uses goose.nvim's native `goose.core.run()` function:

```lua
-- Load goose.core module
local goose_core = require('goose.core')

-- Build /recipe:<name> command
local recipe_name = metadata.name or vim.fn.fnamemodify(recipe_path, ':t:r')
local prompt = string.format('/recipe:%s', recipe_name)

-- Execute via goose.core.run() - handles sidebar, job management, and streaming
goose_core.run(prompt)
```

This approach:
- Uses goose's native recipe command syntax (`/recipe:<name>`)
- Lets goose handle parameter prompting conversationally in the chat
- Leverages goose.nvim's built-in sidebar UI and session management
- Integrates with `:GooseStop` for job cancellation

### which-key

Keybinding registration via which-key for icon display and documentation:
```lua
{ "<leader>aR", function()
  require("neotex.plugins.ai.goose.picker").show_recipe_picker()
end, desc = "goose run recipe (sidebar)", icon = "󰑮" }
```

## Testing

### Unit Tests

Test files located in `tests/goose/picker/`:
- `metadata_spec.lua`: YAML parsing, parameter extraction, validation
- `discovery_spec.lua`: Recipe discovery, sorting, location labeling
- `execution_spec.lua`: Parameter validation, CLI command construction

### Running Tests

```bash
# Run all picker tests
nvim --headless -c "PlenaryBustedDirectory tests/goose/picker/ {minimal_init = 'tests/minimal_init.lua'}"

# Run specific test file
nvim --headless -c "PlenaryBustedFile tests/goose/picker/metadata_spec.lua {minimal_init = 'tests/minimal_init.lua'}"
```

### Integration Tests

Integration tests verify end-to-end workflows:
- Recipe discovery from actual directories
- Metadata parsing for all discovered recipes
- Recipe execution via goose.core.run()
- Keybinding simulation and validation

## Troubleshooting

### Picker Fails to Open

**Symptoms**: Lua error when pressing `<leader>aR`

**Solutions**:
1. Check Telescope is installed: `:checkhealth telescope`
2. Verify picker module loads: `:lua require("neotex.plugins.ai.goose.picker")`
3. Check for Lua errors in `:messages`

### No Recipes Found

**Symptoms**: Picker shows "No recipes found" notification

**Solutions**:
1. Verify recipe directories exist:
   - Project: `.goose/recipes/` in current directory or parent
   - Global: `~/.config/goose/recipes/`
2. Check recipe files have `.yaml` extension
3. Verify recipes have valid YAML syntax

### Parameter Prompting Fails

**Symptoms**: Error when executing recipe with parameters

**Solutions**:
1. Check parameter definitions in recipe YAML
2. Verify `input_type` is valid: "string", "number", "boolean"
3. Verify `requirement` is valid: "required", "optional", "user_prompt"
4. Check parameter values pass type validation

### Recipe Execution Fails

**Symptoms**: Recipe doesn't execute in sidebar

**Solutions**:
1. Verify goose CLI is installed: `which goose`
2. Check goose.nvim is installed: `:checkhealth goose`
3. Verify sidebar can open: `<leader>aa` or `:Goose`
4. Test goose.core module: `:lua print(vim.inspect(require('goose.core')))`
5. Check `:messages` for Lua errors

### Sidebar Not Opening

**Symptoms**: Recipe execution fails with error about goose.core

**Solutions**:
1. Manually open sidebar first: `<leader>aa` or `:Goose`
2. Verify goose.nvim is properly configured in init.lua
3. Check goose.core loads: `:lua require('goose.core')`
4. Restart Neovim and try again

### Preview Window Not Updating

**Symptoms**: Preview shows old content when navigating recipes

**Solutions**:
1. Press `<C-r>` to refresh picker
2. Check for Lua errors in `:messages`
3. Verify metadata parsing doesn't error for selected recipe

## Future Enhancements

### Planned Features (Post-MVP)

- **Session Management**: Extend picker to include session listing and resume
- **Configuration Management**: Add provider and configuration switching
- **Recipe Creation Wizard**: AI-assisted recipe generation from natural language
- **Batch Operations**: Load all recipes, recipe synchronization
- **Advanced Filtering**: Filter by category, parameters, subrecipes

See main implementation plan for detailed enhancement specifications.
