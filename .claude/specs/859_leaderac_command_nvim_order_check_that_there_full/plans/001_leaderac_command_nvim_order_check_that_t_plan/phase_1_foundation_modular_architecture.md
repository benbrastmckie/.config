# Phase 1 Expansion: Foundation - Modular Architecture

## Metadata
- **Phase Number**: 1
- **Parent Plan**: 001_leaderac_command_nvim_order_check_that_t_plan.md
- **Objective**: Establish modular architecture without changing functionality
- **Complexity**: High
- **Status**: IN PROGRESS

## Overview

This phase transforms the monolithic 3,385-line `picker.lua` into a modular architecture with 11 artifact types (commands, agents, hooks, TTS files, templates, lib utilities, docs, agent protocols, standards, data docs, settings). The refactor maintains identical functionality while establishing clean separation of concerns for future extensibility (Phase 2 will add scripts/ and tests/ artifact types).

**Critical Success Factors**:
- Zero functional changes (atomic cutover)
- All existing keybindings (`<leader>ac`) work identically
- External API (`show_commands_picker()`) preserved
- Test coverage ≥80% for new modules

**Architecture Strategy**: Facade pattern with modular backend. The existing `picker.lua` becomes a thin facade delegating to specialized modules, while `picker/init.lua` serves as the new modular entry point.

## 1. Current Usage Analysis (BLOCKING REQUIREMENT)

**Objective**: Map all external dependencies before any code changes to ensure atomic cutover.

### 1.1 External Call Sites

Based on grep analysis, `picker.lua` has these external integrations:

```lua
-- Primary entry point (nvim/lua/neotex/plugins/ai/claude/init.lua:16,106)
local commands_picker = require("neotex.plugins.ai.claude.commands.picker")
M.show_commands_picker = commands_picker.show_commands_picker

-- User command registration (nvim/lua/neotex/plugins/ai/claude/init.lua:145)
vim.api.nvim_create_user_command("ClaudeCommands", M.show_commands_picker, {...})

-- Which-key keybinding (nvim/lua/neotex/plugins/editor/which-key.lua:252)
{ "<leader>ac", "<cmd>ClaudeCommands<CR>", desc = "claude commands", icon = "󰘳" }

-- Visual mode handler (nvim/lua/neotex/plugins/editor/which-key.lua:253)
{ "<leader>ac", mode = "v", function() ... end }  -- sends to visual.lua, not picker
```

### 1.2 Public API Contract

```lua
-- File: picker.lua (current)
M.show_commands_picker(opts)
  -- @param opts table|nil Optional configuration
  --   opts.initial_mode = "insert"|"normal"  -- Telescope mode
  --   opts.default_text = string            -- Pre-fill search
  -- @return nil (opens Telescope picker)
```

**Verification Commands**:
```bash
# Find all require() statements
cd /home/benjamin/.config/nvim
rg "require.*picker" --type lua

# Find all function calls
rg "show_commands_picker|show_artifacts_picker" --type lua

# Check keybinding files
rg "leader.*ac" --type lua -i
```

### 1.3 Internal Dependencies

```lua
-- File: picker.lua (lines 1-14)
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local previewers = require("telescope.previewers")

-- Local modules
local parser = require("neotex.plugins.ai.claude.commands.parser")
local notify = require("neotex.util.notifications")
```

**No changes required** - these are internal implementation details.

### 1.4 Module State

```lua
-- File: picker.lua (line 3)
local M = {}

-- No persistent state stored in module
-- All state is local to show_commands_picker() function scope
```

**Implication**: Stateless design enables clean extraction to separate modules.

## 2. Module Architecture Design

### 2.1 Directory Structure

```
nvim/lua/neotex/plugins/ai/claude/commands/
├── picker.lua                    # FACADE (backward compat, 50 lines)
├── picker/
│   ├── init.lua                  # NEW ENTRY POINT (100 lines)
│   ├── artifacts/
│   │   ├── registry.lua          # ARTIFACT TYPE REGISTRY (200 lines)
│   │   ├── metadata.lua          # METADATA EXTRACTION (150 lines)
│   │   └── registry_spec.lua     # TESTS (250 lines)
│   ├── display/
│   │   ├── entries.lua           # ENTRY CREATION (300 lines)
│   │   ├── previewer.lua         # PREVIEW SYSTEM (400 lines)
│   │   └── entries_spec.lua      # TESTS (200 lines)
│   ├── operations/
│   │   ├── sync.lua              # LOAD ALL LOGIC (500 lines)
│   │   └── sync_spec.lua         # TESTS (300 lines)
│   └── utils/
│       ├── scan.lua              # DIR SCANNING (200 lines)
│       └── scan_spec.lua         # TESTS (150 lines)
└── parser.lua                    # UNCHANGED (existing module)
```

### 2.2 Module Responsibilities

#### 2.2.1 `picker/artifacts/registry.lua` (200 lines)

**Purpose**: Central registry of 11 artifact types with metadata, scanning, and formatting.

```lua
-- Artifact type definitions (11 types)
local M = {}

-- Artifact type configuration
M.ARTIFACT_TYPES = {
  command = {
    name = "command",
    plural = "Commands",
    extension = ".md",
    subdirs = {"commands"},
    preserve_permissions = false,
    description_parser = "parse_command_description",  -- via parser.lua
    heading = "[Commands]",
    heading_description = "Slash commands",
  },
  agent = {
    name = "agent",
    plural = "Agents",
    extension = ".md",
    subdirs = {"agents"},
    preserve_permissions = false,
    description_parser = "parse_agent_description",
    heading = "[Agents]",
    heading_description = "AI assistants",
  },
  hook_event = {
    name = "hook_event",
    plural = "Hook Events",
    extension = ".sh",
    subdirs = {"hooks"},
    preserve_permissions = true,
    description_parser = "parse_script_description",
    heading = "[Hook Events]",
    heading_description = "Event-triggered scripts",
    -- Special: hooks are grouped by event name
    group_by_event = true,
  },
  tts_file = {
    name = "tts_file",
    plural = "TTS Files",
    extension = ".sh",
    subdirs = {"tts", "hooks"},  -- Multiple directories
    preserve_permissions = true,
    description_parser = "parse_script_description",
    heading = "[TTS Files]",
    heading_description = "Text-to-speech scripts",
    -- Special: filter for tts-*.sh pattern
    pattern_filter = "^tts%-",
  },
  template = {
    name = "template",
    plural = "Templates",
    extension = ".yaml",
    subdirs = {"templates"},
    preserve_permissions = false,
    description_parser = "parse_template_description",
    heading = "[Templates]",
    heading_description = "YAML templates",
  },
  lib = {
    name = "lib",
    plural = "Lib Utilities",
    extension = ".sh",
    subdirs = {"lib"},
    preserve_permissions = true,
    description_parser = "parse_script_description",
    heading = "[Lib Utilities]",
    heading_description = "Shell libraries",
  },
  doc = {
    name = "doc",
    plural = "Docs",
    extension = ".md",
    subdirs = {"docs"},
    preserve_permissions = false,
    description_parser = "parse_doc_description",
    heading = "[Docs]",
    heading_description = "Documentation files",
  },
  -- Note: agent_protocol, standard, data_doc, settings are scanned but
  -- not displayed in picker (used by sync operations only)
}

--- Get artifact type configuration
---@param type_name string Artifact type name
---@return table|nil Configuration table or nil if not found
function M.get_type(type_name)
  return M.ARTIFACT_TYPES[type_name]
end

--- Get all artifact types
---@return table Map of type_name -> config
function M.get_all_types()
  return M.ARTIFACT_TYPES
end

--- Check if artifact type should preserve file permissions
---@param type_name string Artifact type name
---@return boolean True if permissions should be preserved
function M.should_preserve_permissions(type_name)
  local config = M.get_type(type_name)
  return config and config.preserve_permissions or false
end

--- Format artifact for display in picker
---@param artifact table Artifact data with name, description, is_local
---@param type_name string Artifact type
---@param indent_char string Tree character (├─ or └─)
---@return string Formatted display string
function M.format_artifact(artifact, type_name, indent_char)
  local prefix = artifact.is_local and "*" or " "
  local description = artifact.description or ""

  -- Strip redundant prefixes
  description = description:gsub("^Specialized in ", "")

  -- Format: "* ├─ artifact-name     Description text"
  -- Standard 1-space indent (agents, templates, lib, docs, commands)
  -- Exception: hook events use 2-space indent (distinguishing marker)
  local indent_spaces = type_name == "hook_event" and "  " or " "

  return string.format(
    "%s%s%s %-38s %s",
    prefix,
    indent_spaces,
    indent_char,
    artifact.name,
    description
  )
end

--- Format heading for artifact section
---@param type_name string Artifact type
---@return string Formatted heading display
function M.format_heading(type_name)
  local config = M.get_type(type_name)
  if not config then
    return ""
  end

  return string.format(
    "%-40s %s",
    config.heading,
    config.heading_description
  )
end

return M
```

**Key Design Decisions**:
1. **Data-driven configuration**: All artifact types defined declaratively
2. **Extensibility**: Adding scripts/ and tests/ in Phase 2 requires only adding entries to `ARTIFACT_TYPES`
3. **Formatting logic centralized**: Single source of truth for display format
4. **Type-safe accessors**: Explicit functions prevent typos

## 3. Testing Strategy

### 3.1 Test Infrastructure Setup

```lua
-- File: picker/artifacts/registry_spec.lua (250 lines)
local registry = require("neotex.plugins.ai.claude.commands.picker.artifacts.registry")

describe("artifacts.registry", function()
  describe("get_type", function()
    it("returns configuration for valid type", function()
      local config = registry.get_type("command")
      assert.is_not_nil(config)
      assert.equals("command", config.name)
      assert.equals(".md", config.extension)
    end)

    it("returns nil for invalid type", function()
      local config = registry.get_type("nonexistent")
      assert.is_nil(config)
    end)
  end)

  describe("should_preserve_permissions", function()
    it("returns true for executable types", function()
      assert.is_true(registry.should_preserve_permissions("hook_event"))
      assert.is_true(registry.should_preserve_permissions("lib"))
      assert.is_true(registry.should_preserve_permissions("tts_file"))
    end)

    it("returns false for non-executable types", function()
      assert.is_false(registry.should_preserve_permissions("command"))
      assert.is_false(registry.should_preserve_permissions("template"))
    end)
  end)
end)
```

### 3.2 Manual Testing Checklist

**Pre-refactor verification**:
```bash
# 1. Test basic picker launch
nvim -c "lua require('neotex.plugins.ai.claude.commands.picker').show_commands_picker()"

# 2. Test keybinding
# In nvim: <leader>ac (normal mode)

# 3. Test visual mode integration
# In nvim visual mode: <leader>ac
# Expected: Should trigger visual.lua, not picker

# 4. Test :ClaudeCommands user command
:ClaudeCommands
```

**Post-refactor verification** (same tests, identical behavior expected):
```bash
# 1. Test new modular entry point
nvim -c "lua require('neotex.plugins.ai.claude.commands.picker.init').show_commands_picker()"

# 2. Test facade compatibility
nvim -c "lua require('neotex.plugins.ai.claude.commands.picker').show_commands_picker()"

# 3. All keybindings and user commands (unchanged)
```

## 4. Implementation Plan

### Task Breakdown with Dependencies

```
[1] Map current usage (BLOCKING - 2 hours)
    - Run grep commands documented in Section 1.1
    - Verify external call sites
    - Document current keybinding configuration

[2] Create directory structure (1 hour)
    └── depends on: [1]
    - mkdir picker/artifacts picker/display picker/operations picker/utils

[3] Implement artifacts.registry (3 hours)
    └── depends on: [2]
    - Define ARTIFACT_TYPES table
    - Implement get_type, should_preserve_permissions
    - Implement format_artifact, format_heading
    - Write registry_spec.lua tests (target 85% coverage)

[4] Implement artifacts.metadata (2 hours)
    └── depends on: [2]
    - Extract parse_template_description from picker.lua
    - Extract parse_script_description from picker.lua
    - Extract parse_doc_description from picker.lua

[5] Implement utils.scan (3 hours)
    └── depends on: [2]
    - Extract scan_directory logic
    - Implement merge_artifacts
    - Implement scan_for_sync
    - Write scan_spec.lua tests (target 80% coverage)

[6] Implement display.entries (4 hours)
    └── depends on: [3, 4, 5]
    - Extract create_picker_entries from picker.lua
    - Implement _add_commands_section (hierarchical logic)
    - Write entries_spec.lua tests (target 80% coverage)

[7] Implement display.previewer (3 hours)
    └── depends on: [3]
    - Extract create_command_previewer from picker.lua
    - Implement _get_filepath, _create_metadata_header

[8] Implement operations.sync (4 hours)
    └── depends on: [3, 5]
    - Extract sync_files, load_all_with_strategy
    - Write sync_spec.lua tests (target 80% coverage)

[9] Implement picker/init.lua (2 hours)
    └── depends on: [6, 7, 8]
    - Create show_commands_picker orchestrator

[10] Create picker.lua facade (0.5 hours)
    └── depends on: [9]
    - Forward show_commands_picker to picker/init.lua

[11] Test facade compatibility (1 hour)
    └── depends on: [10]
    - Run all manual tests

[12] Verify all existing functionality (1.5 hours)
    └── depends on: [11]
    - Test all artifact types
```

**Total estimated time**: 10 hours

## 5. Acceptance Criteria

### 5.1 Functional Requirements

- [ ] `<leader>ac` in normal mode opens picker (identical behavior)
- [ ] All 11 artifact types displayed correctly
- [ ] Hierarchical command display with dependents/agents
- [ ] Preview shows file contents with syntax highlighting
- [ ] "Load All" operation works with merge/replace strategies
- [ ] Local artifacts marked with `*` prefix
- [ ] Tree characters (├─, └─) display correctly

### 5.2 Non-Functional Requirements

- [ ] Startup time unchanged (lazy loading preserved)
- [ ] No new dependencies added
- [ ] All existing keybindings work identically
- [ ] Test coverage ≥80% for new modules
- [ ] Code follows Neovim Lua standards (CODE_STANDARDS.md)
- [ ] No emojis in file content (encoding policy)

### 5.3 Testing Requirements

- [ ] Unit tests pass for registry, scan, entries, sync modules
- [ ] Manual tests pass (Section 3.2)
- [ ] Regression tests pass (empty project, mixed project, sync operations)
- [ ] External integration verified (init.lua, which-key.lua)

## Summary

This specification provides a complete blueprint for Phase 1 implementation:

1. **Architecture**: Facade pattern with 7 specialized modules
2. **Artifact types**: 11 existing types preserved, extensible to 13+ in Phase 2
3. **Testing**: 80%+ coverage with unit tests + manual verification
4. **Compatibility**: Zero breaking changes, atomic cutover
5. **Performance**: Lazy loading, caching, batch operations preserved

**Next steps**: Begin implementation with Task [1] (map current usage), then proceed through dependency graph to Task [12] (final verification).
