# Research Report: Claude Code Artifact Picker Architecture

**Date**: 2025-12-09
**Topic**: Existing Claude Code Artifact Picker Implementation
**Status**: Complete
**Scope**: Architecture analysis for Goose recipe picker utility development

## Executive Summary

The Claude Code artifact picker (`<leader>ac` in Neovim) is a comprehensive Telescope-based hierarchical browser for managing Claude Code artifacts. It provides a production-ready architecture for multi-artifact discovery, preview, and management with interactive selection capabilities. This report analyzes the picker's structure, patterns, and infrastructure to inform the development of a Goose recipe picker utility.

## Architecture Overview

### Core Components

The picker is organized into a modular architecture with clear separation of concerns:

```
neotex/plugins/ai/claude/commands/
├── picker.lua                    # Facade (public API)
├── parser.lua                    # Artifact discovery & metadata extraction
└── picker/
    ├── init.lua                  # Main orchestration & Telescope integration
    ├── display/
    │   ├── entries.lua          # Entry creation & formatting
    │   └── previewer.lua        # Custom preview pane
    ├── operations/
    │   ├── edit.lua             # File editing operations
    │   ├── sync.lua             # Artifact synchronization (Load All)
    │   └── terminal.lua         # Command execution & terminal integration
    ├── artifacts/
    │   ├── registry.lua         # Artifact type definitions & metadata
    │   └── metadata.lua         # Description parsing for various file types
    └── utils/
        ├── scan.lua             # Directory scanning & merging
        └── helpers.lua          # Formatting utilities
```

### Key Design Patterns

#### 1. Registry-Based Artifact System

**Location**: `picker/artifacts/registry.lua`

The picker uses a central registry to define artifact types with metadata:

```lua
ARTIFACT_TYPES = {
  command = {
    name = "command",
    plural = "Commands",
    extension = ".md",
    subdirs = { "commands" },
    preserve_permissions = false,
    description_parser = "parse_command_description",
    heading = "[Commands]",
    heading_description = "Slash commands",
    tree_indent = " ",
    picker_visible = true,
    sync_enabled = true,
  },
  -- ... 11 total artifact types
}
```

**Benefits**:
- Easy to add new artifact types
- Centralized configuration for display, scanning, and behavior
- Type-safe artifact operations
- Consistent formatting across categories

#### 2. Hierarchical Entry Creation

**Location**: `picker/display/entries.lua`

Entries are created in reverse order for Telescope's descending sort:

```lua
-- Last inserted appears FIRST (descending sort)
function M.create_picker_entries(structure)
  local all_entries = {}

  -- Insert special entries (appear at bottom)
  insert(all_entries, special_entries)

  -- Insert docs, lib, templates, scripts, tests (middle)
  insert(all_entries, docs_entries)
  insert(all_entries, lib_entries)
  -- ...

  -- Insert commands section (appears at top)
  insert(all_entries, commands_entries)

  return all_entries
end
```

**Pattern**: Reverse insertion + descending sort = natural top-to-bottom display

#### 3. Parser-Based Discovery

**Location**: `parser.lua`

Multi-source artifact discovery with local-global fallback:

```lua
-- Discovers from both project and global directories
function M.parse_with_fallback(project_dir, global_dir)
  local merged = {}

  -- Local artifacts have priority (marked with is_local=true)
  local local_artifacts = scan(project_dir)
  local global_artifacts = scan(global_dir)

  -- Merge: local overrides global by name
  return merge_artifacts(local_artifacts, global_artifacts)
end
```

**Key Features**:
- Scans both `{project}/.claude/` and `~/.config/.claude/`
- Local artifacts override global by name
- Visual indicator (`*` prefix) for local artifacts
- Supports 11 artifact types (commands, agents, hooks, TTS, templates, lib, docs, scripts, tests, etc.)

#### 4. Custom Previewer

**Location**: `picker/display/previewer.lua`

Provides context-aware previews:

```lua
-- Shows different content based on entry type
create_command_previewer()
  - Commands: Full markdown content with syntax highlighting
  - Agents: Description + parent commands + tools + filepath
  - Category headings: Associated README.md content
  - Hook events: Description + associated scripts
  - Other artifacts: File content with metadata
```

**Features**:
- Markdown syntax highlighting
- 150-line preview limit with truncation indicator
- Cross-reference display (agents → commands that use them)
- Scrollable with `<C-u>`/`<C-d>` (native Telescope actions)

#### 5. Interactive Operations

**Location**: `picker/operations/`

Action-oriented keybindings for artifact management:

| Keybinding | Action | Implementation |
|------------|--------|----------------|
| `<CR>` | Execute action (context-aware) | `terminal.send_command_to_terminal()` or `edit.edit_artifact_file()` |
| `<C-l>` | Load artifact locally | `edit.load_artifact_locally()` + recursive deps |
| `<C-s>` | Save to global | `edit.save_artifact_to_global()` |
| `<C-e>` | Edit file | `edit.edit_artifact_file()` |
| `<C-n>` | Create new command | `terminal.create_new_command()` (via Claude Code) |
| `<C-r>` | Run script with args | `terminal.run_script_with_args()` (prompts for params) |
| `<C-t>` | Run test | `terminal.run_test()` |
| `<Esc>` | Close picker | `actions.close()` |

## Keybinding Discovery

### Primary Keybinding: `<leader>ac`

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua:248`

```lua
{ "<leader>ac", "<cmd>ClaudeCommands<CR>", desc = "claude commands", icon = "󰘳" }
```

### User Command Registration

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/init.lua:146`

```lua
vim.api.nvim_create_user_command("ClaudeCommands", M.show_commands_picker, {
  desc = "Browse Claude commands in hierarchical picker",
  nargs = 0,
})
```

### Entry Point Flow

```
<leader>ac
  → :ClaudeCommands
    → require("neotex.plugins.ai.claude").show_commands_picker()
      → require("neotex.plugins.ai.claude.commands.picker").show_commands_picker()
        → require("neotex.plugins.ai.claude.commands.picker.init").show_commands_picker(opts)
          → pickers.new(opts, { ... }):find()
```

## Data Management Patterns

### 1. Artifact Discovery Flow

```
User invokes picker
  ↓
parser.get_extended_structure()
  ↓
Scan multiple directories:
  - .claude/commands/
  - .claude/agents/
  - .claude/hooks/
  - .claude/tts/
  - .claude/templates/
  - .claude/lib/
  - .claude/docs/
  - .claude/scripts/
  - .claude/tests/
  ↓
Parse metadata from files:
  - YAML frontmatter (commands, agents)
  - Header comments (hooks, scripts)
  - Variable extraction (TTS config)
  ↓
Build dependencies:
  - Commands → Agents (agent_dependencies field)
  - Events → Hooks (settings.local.json parsing)
  ↓
Merge local + global (local overrides)
  ↓
Create picker entries with formatting
  ↓
Display in Telescope picker
```

### 2. Metadata Extraction

**Commands** (YAML frontmatter):
```yaml
---
command-type: primary | dependent
description: Command description
argument-hint: <arg1> [optional-arg]
allowed-tools: tool1, tool2
dependent-commands: cmd1, cmd2
parent-commands: cmd1, cmd2
agent-dependencies: agent1, agent2
---
```

**Agents** (YAML frontmatter):
```yaml
---
description: Agent description
allowed-tools: tool1, tool2
---
```

**Scripts/Hooks** (header comments):
```bash
#!/usr/bin/env bash
# Purpose: Script description
```

**TTS Config** (variable extraction):
```bash
TTS_ENABLED=true
TTS_PROVIDER=google
# ... extracts all TTS_* variables
```

### 3. Local-Global Resolution

**Strategy**: Two-tier hierarchy with local priority

```lua
-- Special case: When in ~/.config, treat as local
if project_dir == global_dir then
  all_artifacts.is_local = true
end

-- Normal case: Merge with local priority
local merged = {}
for name, artifact in pairs(local_artifacts) do
  artifact.is_local = true
  merged[name] = artifact  -- Local overrides
end
for name, artifact in pairs(global_artifacts) do
  if not merged[name] then  -- Only add if not local
    artifact.is_local = false
    merged[name] = artifact
  end
end
```

**Visual Indicator**: `*` prefix for local artifacts in picker display

## UX Patterns

### 1. Categorical Organization

Artifacts grouped by type with visual headings:

```
[Commands]                    Slash commands
* ├─ create-plan             Create implementation plans
  ├─ [agent] plan-architect  AI planning specialist
  └─ list-reports            List available reports

[Agents]                      Standalone AI agents
  └─ metrics-specialist      Performance analysis

[Hook Events]                 Event-triggered scripts
* ├─ Stop                    After command completion
  ├─ post-command-metrics.sh Collect metrics
  └─ tts-notification.sh     Voice notification

[Load All Artifacts]          Sync all global artifacts
[Keyboard Shortcuts]          Help
```

**Display Order** (top to bottom):
1. Commands (with nested agents/dependents)
2. Standalone Agents
3. Hook Events
4. TTS Files
5. Templates
6. Libraries
7. Documentation
8. Scripts
9. Tests
10. Special entries (Load All, Help)

### 2. Tree Character Indentation

Consistent visual hierarchy with tree characters:

- **Commands/Agents**: 1-space indent
  ```
  * plan
    ├─ [agent] plan-architect
    └─ list-reports
  ```

- **Hook Events**: 2-space indent (distinguishing marker)
  ```
  * Stop
    ├─ post-command-metrics.sh
    └─ tts-notification.sh
  ```

- **Preview Cross-References**: 3-space indent
  ```
  Commands that use this agent:
     ├─ plan
     └─ revise
  ```

### 3. Interactive Selection

**Enter Key**: Context-aware action execution

```lua
actions.select_default:replace(function()
  local selection = action_state.get_selected_entry()

  -- Commands: Insert into terminal
  if selection.value.command then
    terminal.send_command_to_terminal(selection.value.command)

  -- Agents/Docs/Lib/etc: Open for editing
  elseif selection.value.entry_type == "agent" then
    edit.edit_artifact_file(selection.value.agent.filepath)

  -- Load All: Batch sync operation
  elseif selection.value.is_load_all then
    sync.load_all_globally()
  end
end)
```

### 4. Batch Operations

**Load All Artifacts** (`[Load All Artifacts]` entry):

```
User selects [Load All Artifacts]
  ↓
scan_all_for_sync()
  - Scans 11 artifact types
  - Recursive scanning for nested files (lib/, docs/, tests/)
  - Reports new/conflict counts per category
  ↓
Display sync strategy dialog:
  - Replace all + add new (N total)
  - Add new only, preserve local (M new)
  - Interactive mode (per-file decisions)
  - Cancel
  ↓
Execute chosen strategy
  ↓
Show completion notification
  ↓
Refresh picker to show updated status
```

**Sync Statistics Example**:
```
Synced 449 artifacts (including conflicts):
  Commands: 14 | Agents: 30 | Hooks: 4 | TTS: 3 | Templates: 0
  49 lib (49 nested) | 238 docs (237 nested) | Protocols: 2
  Data: 3 | 12 scripts (3 nested) | 102 tests (102 nested) | 5 skills (5 nested)
```

## Infrastructure Analysis

### 1. Telescope Integration

**Dependencies**:
- `telescope.pickers` - Picker UI
- `telescope.finders` - Entry management
- `telescope.actions` - Keybinding actions
- `telescope.action_state` - Selection state
- `telescope.config` - Configuration values

**Configuration**:
```lua
pickers.new(opts, {
  prompt_title = "Claude Commands",
  finder = finders.new_table {
    results = picker_entries,
    entry_maker = function(entry) ... end,
  },
  sorter = conf.generic_sorter({}),
  sorting_strategy = "descending",  -- Key: enables reverse insertion pattern
  default_selection_index = 2,     -- Skip heading, select first item
  previewer = custom_previewer,
  attach_mappings = function(prompt_bufnr, map) ... end,
})
```

### 2. File System Operations

**Directory Creation**:
```lua
-- Automatic parent directory creation
vim.fn.mkdir(vim.fn.fnamemodify(dest, ":h"), "p")
```

**Permission Preservation** (shell scripts):
```lua
if type_config.preserve_permissions then
  vim.fn.system(string.format("chmod +x %s", dest))
end
```

**File Copying**:
```lua
vim.fn.writefile(vim.fn.readfile(source), dest)
```

### 3. Metadata Parsing

**YAML Frontmatter** (commands, agents):
```lua
local function parse_frontmatter(content)
  local frontmatter_pattern = "^%-%-%-\n(.-)%-%-%-"
  local frontmatter_text = content:match(frontmatter_pattern)

  local metadata = {}
  for line in frontmatter_text:gmatch("[^\n]+") do
    local key, value = line:match("^([%w%-_]+):%s*(.+)")
    if key and value then
      metadata[key:gsub("%-", "_")] = vim.trim(value)
    end
  end
  return metadata
end
```

**Header Comments** (scripts, hooks):
```lua
local function parse_script_description(filepath)
  local content = vim.fn.readfile(filepath)
  for _, line in ipairs(content) do
    local desc = line:match("^#%s*Purpose:%s*(.+)")
    if desc then return vim.trim(desc) end
  end
  return ""
end
```

### 4. Terminal Integration

**Command Execution** (Claude Code):
```lua
function terminal.send_command_to_terminal(command)
  -- 1. Open Claude Code if not running
  if not claude_code_running() then
    vim.cmd("ClaudeCode")
    vim.wait(500)  -- Allow terminal to initialize
  end

  -- 2. Focus Claude Code terminal buffer
  local term_buf = find_claude_code_buffer()
  vim.api.nvim_set_current_buf(term_buf)

  -- 3. Enter insert mode
  vim.cmd("startinsert")

  -- 4. Send command via feedkeys (reliable input method)
  local cmd_text = "/" .. command.name
  vim.api.nvim_feedkeys(cmd_text, "t", false)
end
```

## Reusable Patterns for Goose Picker

### 1. Registry-Based Architecture

**Recommendation**: Use central registry for recipe types

```lua
-- Analogous to artifact registry
RECIPE_TYPES = {
  utility = {
    name = "utility",
    plural = "Utilities",
    extension = ".yaml",
    subdirs = { "recipes" },
    heading = "[Utilities]",
    heading_description = "General-purpose recipes",
    pattern_filter = nil,  -- Optional filter (e.g., "^util%-")
  },
  automation = {
    name = "automation",
    plural = "Automation",
    extension = ".yaml",
    subdirs = { "recipes" },
    heading = "[Automation]",
    heading_description = "Workflow automation recipes",
  },
  -- ... more recipe categories
}
```

### 2. Multi-Source Scanning

**Recommendation**: Support both local and global recipes

```lua
-- Similar to command discovery
local project_recipes = scan_directory(vim.fn.getcwd() .. "/.goose/recipes")
local global_recipes = scan_directory(vim.fn.expand("~/.config/goose/recipes"))
local merged_recipes = merge_artifacts(project_recipes, global_recipes)
```

### 3. Hierarchical Display

**Recommendation**: Use category headings + tree characters

```
[Utilities]                   General-purpose recipes
* ├─ code-review              Review code with AI feedback
  └─ doc-generator            Generate documentation

[Automation]                  Workflow automation
  └─ test-runner              Run test suites automatically
```

### 4. Interactive Preview

**Recommendation**: Show recipe metadata in preview pane

```lua
-- Preview content for recipes
function create_recipe_previewer()
  return previewers.new_buffer_previewer({
    define_preview = function(self, entry, status)
      local recipe = entry.value.recipe

      -- Extract from YAML
      local name = recipe.name
      local description = recipe.description
      local toolkit = recipe.toolkit
      local version = recipe.version
      local accelerators = recipe.accelerators or {}

      -- Format preview
      local preview_lines = {
        "Recipe: " .. name,
        "",
        description,
        "",
        "Toolkit: " .. toolkit,
        "Version: " .. version,
        "",
      }

      if #accelerators > 0 then
        table.insert(preview_lines, "Accelerators:")
        for _, acc in ipairs(accelerators) do
          table.insert(preview_lines, "  - " .. acc)
        end
      end

      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, preview_lines)
    end
  })
end
```

### 5. Parameter Handling

**Recommendation**: Prompt for recipe parameters before execution

```lua
-- Similar to script execution with args
function run_recipe_with_params(recipe_path, recipe_name)
  vim.ui.input({
    prompt = "Parameters (key=value, comma-separated, or empty): "
  }, function(params)
    local cmd = "goose run --recipe " .. vim.fn.shellescape(recipe_path)

    if params and params ~= "" then
      for param in params:gmatch("[^,]+") do
        cmd = cmd .. " --params " .. vim.fn.trim(param)
      end
    end

    vim.cmd("TermExec cmd='" .. cmd .. "'")
  end)
end
```

### 6. Keybinding Strategy

**Recommendation**: Use similar keybinding pattern

| Keybinding | Action | Goose Equivalent |
|------------|--------|------------------|
| `<CR>` | Execute recipe | Run recipe with parameter prompt |
| `<C-e>` | Edit recipe file | Open recipe YAML for editing |
| `<C-l>` | Load recipe locally | Copy from global to project |
| `<C-s>` | Save to global | Copy from project to global |
| `<C-n>` | Create new recipe | Prompt Goose to generate recipe |
| `<Esc>` | Close picker | Standard close action |

## Implementation Recommendations

### 1. Module Structure

```
nvim/lua/goose/picker/
├── init.lua                  # Main orchestration
├── registry.lua              # Recipe type definitions
├── scanner.lua               # Directory scanning
├── parser.lua                # YAML parsing & metadata
├── display/
│   ├── entries.lua          # Entry creation & formatting
│   └── previewer.lua        # Custom preview pane
├── operations/
│   ├── execute.lua          # Recipe execution
│   ├── edit.lua             # File editing
│   └── sync.lua             # Recipe synchronization
└── utils/
    ├── helpers.lua          # Formatting utilities
    └── terminal.lua         # Goose terminal integration
```

### 2. Recipe Discovery

**Directories to scan**:
- `{project}/.goose/recipes/` (local recipes)
- `~/.config/goose/recipes/` (global recipes)
- `~/.goose/recipes/` (user-wide recipes, if supported)

**File pattern**: `*.yaml` (Goose recipes use YAML format)

### 3. Metadata Extraction

**Recipe YAML Structure** (from existing Goose recipes):
```yaml
---
name: Recipe Name
version: 1.0.0
description: Recipe description
toolkit:
  name: toolkit-name
  version: 1.0.0
accelerators:
  - accelerator-1
  - accelerator-2
---
```

**Parser**:
```lua
function parse_recipe_metadata(filepath)
  local content = vim.fn.readfile(filepath)
  local yaml_text = table.concat(content, "\n")

  -- Use vim.fn.json_decode with YAML-to-JSON conversion
  -- or implement simple YAML parser for key fields

  return {
    name = extract_yaml_field(yaml_text, "name"),
    description = extract_yaml_field(yaml_text, "description"),
    toolkit = extract_yaml_field(yaml_text, "toolkit"),
    version = extract_yaml_field(yaml_text, "version"),
    accelerators = extract_yaml_array(yaml_text, "accelerators"),
  }
end
```

### 4. Category Organization

**Proposed Categories**:
1. **Utilities** - General-purpose recipes (code review, doc generation)
2. **Automation** - Workflow automation (test runners, CI/CD)
3. **Development** - Development workflows (scaffolding, refactoring)
4. **Analysis** - Code analysis (linting, security scanning)

**Dynamic Discovery**: Parse category from recipe filename or metadata field

### 5. Terminal Integration

**Goose Command Execution**:
```lua
function execute_recipe(recipe)
  -- Check if Goose terminal is open
  local goose_term = find_goose_terminal()

  if not goose_term then
    -- Open Goose terminal with recipe
    vim.cmd("Goose")
    vim.wait(500)
  end

  -- Prompt for parameters
  vim.ui.input({
    prompt = "Recipe parameters (key=value, comma-separated): "
  }, function(params)
    local cmd = "goose run --recipe " .. recipe.filepath .. " --interactive"

    if params and params ~= "" then
      for param in params:gmatch("[^,]+") do
        cmd = cmd .. " --params " .. vim.fn.trim(param)
      end
    end

    -- Execute in terminal
    vim.cmd("TermExec cmd='" .. cmd .. "'")
  end)
end
```

### 6. Picker Configuration

**Telescope Setup**:
```lua
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

pickers.new(opts, {
  prompt_title = "Goose Recipes",
  finder = finders.new_table {
    results = recipe_entries,
    entry_maker = function(entry)
      return {
        value = entry,
        display = entry.display,
        ordinal = entry.name .. " " .. entry.description,
      }
    end,
  },
  sorter = conf.generic_sorter({}),
  sorting_strategy = "descending",
  default_selection_index = 2,
  previewer = create_recipe_previewer(),
  attach_mappings = function(prompt_bufnr, map)
    -- Define keybindings
    actions.select_default:replace(function()
      local selection = action_state.get_selected_entry()
      actions.close(prompt_bufnr)
      execute_recipe(selection.value.recipe)
    end)

    map("i", "<C-e>", function()
      local selection = action_state.get_selected_entry()
      actions.close(prompt_bufnr)
      vim.cmd("edit " .. selection.value.recipe.filepath)
    end)

    -- Add more keybindings...

    return true
  end,
}):find()
```

## Technical Considerations

### 1. YAML Parsing

**Challenge**: Neovim lacks native YAML parser

**Options**:
1. **Simple key-value extraction** (recommended for MVP):
   ```lua
   local function extract_yaml_field(content, field)
     return content:match(field .. ":%s*([^\n]+)")
   end
   ```

2. **External YAML library**:
   - Use `lyaml` Lua library (requires external dependency)
   - Call `yq` command-line tool (requires system binary)

3. **JSON conversion**:
   - Convert YAML to JSON via external tool
   - Use `vim.fn.json_decode()`

**Recommendation**: Start with simple pattern matching for key fields, upgrade to library if complex YAML parsing needed.

### 2. Recipe Parameter Handling

**Challenge**: Recipes may require dynamic parameters

**Solution**: Two-tier prompting system

1. **Basic prompt** (for all recipes):
   ```lua
   vim.ui.input({ prompt = "Parameters (key=value): " }, function(params) ... end)
   ```

2. **Structured prompt** (for recipes with known params):
   ```lua
   -- Parse parameter definitions from recipe metadata
   local params = recipe.parameters or {}

   for _, param in ipairs(params) do
     vim.ui.input({
       prompt = param.name .. " (" .. param.description .. "): ",
       default = param.default,
     }, function(value) ... end)
   end
   ```

### 3. Goose Terminal Detection

**Challenge**: Detecting if Goose terminal is already open

**Solution**: Buffer name pattern matching

```lua
function find_goose_terminal()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local bufname = vim.api.nvim_buf_get_name(buf)
    if bufname:match("goose") and vim.bo[buf].buftype == "terminal" then
      return buf
    end
  end
  return nil
end
```

### 4. Category Auto-Detection

**Challenge**: Organizing recipes into logical categories

**Options**:
1. **Filename prefix**: `util-code-review.yaml`, `auto-test-runner.yaml`
2. **Metadata field**: `category: utilities` in YAML frontmatter
3. **Directory structure**: `recipes/utilities/`, `recipes/automation/`

**Recommendation**: Use directory structure (easiest to implement, most intuitive)

## Performance Considerations

### 1. File Scanning

**Optimization**: Cache recipe metadata

```lua
local recipe_cache = {}
local cache_timeout = 300  -- 5 minutes

function get_recipes_with_cache()
  local current_time = os.time()

  if recipe_cache.timestamp and (current_time - recipe_cache.timestamp) < cache_timeout then
    return recipe_cache.recipes
  end

  -- Scan and parse recipes
  local recipes = scan_and_parse_recipes()

  recipe_cache = {
    recipes = recipes,
    timestamp = current_time,
  }

  return recipes
end
```

### 2. Large Recipe Collections

**Optimization**: Lazy loading of preview content

```lua
define_preview = function(self, entry, status)
  -- Only read file when preview is visible
  vim.defer_fn(function()
    local content = vim.fn.readfile(entry.value.recipe.filepath)
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, content)
  end, 50)  -- Small delay to avoid blocking
end
```

### 3. Recursive Directory Scanning

**Optimization**: Use vim.fn.glob with depth limit

```lua
function scan_recipes_recursive(base_dir, max_depth)
  local recipes = {}
  local depth = 0

  local function scan_dir(dir, current_depth)
    if current_depth >= max_depth then return end

    local files = vim.fn.glob(dir .. "/*.yaml", false, true)
    vim.list_extend(recipes, files)

    local subdirs = vim.fn.glob(dir .. "/*", false, true)
    for _, subdir in ipairs(subdirs) do
      if vim.fn.isdirectory(subdir) == 1 then
        scan_dir(subdir, current_depth + 1)
      end
    end
  end

  scan_dir(base_dir, 0)
  return recipes
end
```

## Testing Strategy

### 1. Unit Tests

**Test Modules**:
- `scanner.lua` - Directory scanning and merging
- `parser.lua` - YAML parsing and metadata extraction
- `registry.lua` - Recipe type configuration
- `display/entries.lua` - Entry creation and formatting

**Example Test**:
```lua
describe("recipe scanner", function()
  it("discovers recipes in directory", function()
    local recipes = scanner.scan_directory("/test/recipes")
    assert.is_not_nil(recipes)
    assert.is_true(#recipes > 0)
  end)

  it("merges local and global recipes", function()
    local local_recipes = {{ name = "test", is_local = true }}
    local global_recipes = {{ name = "test", is_local = false }}
    local merged = scanner.merge_artifacts(local_recipes, global_recipes)

    assert.equals(1, #merged)
    assert.is_true(merged[1].is_local)  -- Local overrides global
  end)
end)
```

### 2. Integration Tests

**Test Scenarios**:
- Recipe picker opens successfully
- Keybindings trigger correct actions
- Preview pane displays recipe metadata
- Recipe execution sends correct command to terminal

### 3. Manual Testing

**Test Cases**:
1. Open picker with empty recipe directory → shows no recipes message
2. Open picker with recipes → displays categorized list
3. Select recipe → prompts for parameters and executes
4. Edit recipe → opens YAML file in buffer
5. Load recipe locally → copies from global to project
6. Create new recipe → prompts Goose to generate recipe

## Dependencies

### Required

- `telescope.nvim` - Picker UI framework
- `plenary.nvim` - File system utilities (Telescope dependency)
- `nvim-treesitter` - Syntax highlighting for preview pane (optional but recommended)

### Optional

- `lyaml` - YAML parsing library (only if complex YAML parsing needed)
- `goose.nvim` - Goose terminal integration (already exists in codebase)

## Migration Path

### Phase 1: MVP (Basic Picker)

- [ ] Create directory structure
- [ ] Implement recipe scanner (basic directory scanning)
- [ ] Implement simple YAML parser (key-value extraction)
- [ ] Create basic Telescope picker
- [ ] Add recipe execution keybinding (`<CR>`)
- [ ] Add file editing keybinding (`<C-e>`)

### Phase 2: Enhanced Features

- [ ] Add recipe categories and headings
- [ ] Implement custom previewer
- [ ] Add local-global recipe support
- [ ] Implement recipe synchronization (`<C-l>`, `<C-s>`)
- [ ] Add recipe creation helper (`<C-n>`)

### Phase 3: Advanced Features

- [ ] Add recipe parameter prompting
- [ ] Implement recipe caching
- [ ] Add recipe metadata validation
- [ ] Create recipe templates
- [ ] Add batch operations (Load All)

## Security Considerations

### 1. Recipe Validation

**Risk**: Malicious recipes could execute arbitrary code

**Mitigation**:
- Validate recipe structure before execution
- Show preview of commands that will be executed
- Require user confirmation for recipes from untrusted sources

```lua
function validate_recipe(recipe_path)
  local content = vim.fn.readfile(recipe_path)

  -- Check for suspicious patterns
  local dangerous_patterns = {
    "rm %-rf",      -- Recursive deletion
    "curl.*|.*sh",  -- Piped shell execution
    "eval",         -- Code evaluation
  }

  for _, pattern in ipairs(dangerous_patterns) do
    if content:match(pattern) then
      vim.notify(
        "Warning: Recipe contains potentially dangerous command: " .. pattern,
        vim.log.levels.WARN
      )
      return false
    end
  end

  return true
end
```

### 2. Path Traversal

**Risk**: Malicious recipe paths could access files outside project

**Mitigation**:
- Validate recipe paths stay within allowed directories
- Use absolute paths for recipe files

```lua
function validate_recipe_path(recipe_path)
  local allowed_dirs = {
    vim.fn.getcwd() .. "/.goose/recipes",
    vim.fn.expand("~/.config/goose/recipes"),
  }

  local normalized_path = vim.fn.resolve(recipe_path)

  for _, allowed_dir in ipairs(allowed_dirs) do
    if normalized_path:find(allowed_dir, 1, true) == 1 then
      return true
    end
  end

  return false
end
```

## Conclusion

The Claude Code artifact picker provides a robust, production-ready architecture for hierarchical artifact management. Key patterns to adopt for Goose recipe picker:

1. **Registry-based system** for recipe type definitions
2. **Multi-source scanning** with local-global resolution
3. **Categorical organization** with visual headings
4. **Interactive preview** showing recipe metadata
5. **Context-aware actions** via keybindings
6. **Terminal integration** for recipe execution

The modular architecture and clear separation of concerns make it straightforward to adapt this pattern for Goose recipes. The existing infrastructure (Telescope integration, file operations, metadata parsing) can be directly reused with minimal modifications.

**Next Steps**:
1. Create initial module structure following Claude picker pattern
2. Implement basic recipe scanner with YAML parsing
3. Build Telescope picker with category support
4. Add recipe execution via Goose terminal
5. Extend with advanced features (parameter prompting, synchronization)

## References

**Source Files**:
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` - Keybinding definitions
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/init.lua` - Entry point
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/init.lua` - Main picker orchestration
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/parser.lua` - Artifact discovery
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry.lua` - Artifact type registry
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/display/entries.lua` - Entry creation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/README.md` - Comprehensive documentation

**Related Documentation**:
- Telescope.nvim API documentation
- Goose CLI documentation (recipe format)
- Existing Goose Neovim integration (`nvim/lua/goose/`)

---

RESEARCH_COMPLETE: /home/benjamin/.config/.claude/specs/046_goose_picker_utility_recipes/reports/001-claude-artifact-picker-research.md
