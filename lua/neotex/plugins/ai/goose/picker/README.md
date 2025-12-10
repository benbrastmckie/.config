# Goose Recipe Picker

## Purpose

The Goose Recipe Picker is a comprehensive Telescope-based interface for managing and executing Goose recipes. It provides recipe discovery, rich previews, and native sidebar execution using direct CLI invocation with `goose run --recipe <path>`. Output streams to the goose.nvim sidebar.

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
- **execution.lua**: Executes recipes via direct `goose run --recipe <path>` CLI invocation with sidebar output

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
goose run --recipe <path> executed via plenary.job
  ↓
Goose sidebar opens with streaming output
  ↓
Recipe executes with output rendered in sidebar
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

Run a recipe in goose.nvim sidebar using direct CLI execution.

**Parameters:**
- `recipe_path` (string): Absolute path to recipe file
- `metadata` (table): Parsed recipe metadata

**Returns:** nil

**Side Effects:**
- Executes `goose run --recipe <path>` via plenary.job
- Opens goose sidebar automatically
- Recipe output streams to sidebar with real-time updates
- Session state managed via goose.state module

**Error Handling:**
- Validates recipe file exists before execution
- Validates goose.nvim is installed
- Shows error notification for job failures
- Gracefully handles missing recipe metadata

**Note:** This function bypasses goose.nvim's built-in job builder (which only supports `--text` flag) and directly invokes the Goose CLI with `--recipe` flag. This ensures recipes are executed as intended rather than sent as literal text to the LLM.

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

Recipes execute via direct CLI invocation with `goose run --recipe <path>`:

- **Direct CLI Execution**: Uses `goose run --recipe <path>` for proper recipe invocation
- **Streaming Output**: Output streams to sidebar via plenary.job with real-time updates
- **Session Integration**: Recipe executions create/resume goose sessions (`<leader>av`)
- **Job Management**: Use `<leader>at` or `:GooseStop` to cancel running recipes
- **Split Window**: Sidebar respects `window_type = "split"` configuration

**Important**: The execution module bypasses goose.nvim's `job.build_args()` which only supports `--text` flag. This prevents recipes from being sent as literal text to the LLM (which would cause "I'm not familiar with..." errors).

## Integration Points

### Telescope

The picker uses Telescope's picker framework including:
- **Finders**: Custom finder for recipe entries
- **Sorters**: Generic fuzzy sorter for recipe names
- **Previewers**: Custom previewer for recipe metadata display
- **Actions**: Custom actions for recipe operations (execute, edit, validate)

### goose.nvim

Recipe execution uses direct CLI invocation with plenary.job:

```lua
-- Load goose modules for UI integration
local state = require('goose.state')
local ui = require('goose.ui.ui')
local goose_core = require('goose.core')
local Job = require('plenary.job')

-- Open sidebar
goose_core.open({ focus = 'output', new_session = true })

-- Build CLI args: goose run --recipe <path>
local args = { 'run', '--recipe', recipe_path }

-- Execute via plenary.job with output streaming to sidebar
state.goose_run_job = Job:new({
  command = 'goose',
  args = args,
  on_stdout = function(_, out)
    -- Handle streaming output
  end,
  on_exit = function()
    state.goose_run_job = nil
    ui.render_output()
  end
})
state.goose_run_job:start()
```

This approach:
- Uses proper Goose CLI `--recipe` flag for recipe execution
- Bypasses goose.nvim's job builder which only supports `--text` (not `--recipe`)
- Leverages goose.nvim's sidebar UI via state and ui modules
- Integrates with `:GooseStop` for job cancellation via `state.goose_run_job`

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

### LLM Says "I'm not familiar with /recipe:..."

**Symptoms**: Gemini or other LLM responds with "I'm not familiar with the /recipe:create-plan command"

**Cause**: This occurs when recipes are sent as literal text via `goose run --text "/recipe:name"` instead of proper CLI invocation with `goose run --recipe <path>`.

**Solutions**:
1. Verify you have the latest `execution.lua` with direct CLI execution
2. Check the execution module uses `--recipe` flag: `grep -n "recipe" ~/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua`
3. The fix should show `{ 'run', '--recipe', recipe_path }` in the args

**Technical Background**: goose.nvim's `job.build_args()` only supports `--text` flag, so our execution module bypasses it and directly invokes the Goose CLI with `--recipe` flag via plenary.job.

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
