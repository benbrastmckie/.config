# Command & Prompt Management Options Analysis
*Analysis conducted on 2025-09-24*

## Executive Summary

This document analyzes different approaches for managing standard commands and prompt components that can be loaded into new Claude Code projects. The goal is to provide a picker interface for selecting multiple commands/prompts with preview functionality, then loading them into the project's Claude directory.

## Core Requirements Analysis

**Primary Workflow**:
1. Open new project in Neovim
2. Launch picker with standard commands/prompt library
3. Multi-select items with `<space>` and navigate with arrow keys
4. Preview selected items before confirming
5. Submit selections to load into project's Claude directory
6. Use loaded commands easily within Claude Code

**Component Types**:
- **Standard Commands**: Pre-built Claude Code commands for common tasks
- **Prompt Components**: Modular prompt pieces for composition
- **Instructions**: Best practices and guidelines for prompt engineering

## Option 1: Telescope-Based Multi-Select System

### Architecture
```
~/.config/nvim/lua/neotex/ai-claude/
├── library/
│   ├── commands/
│   │   ├── code-review.md
│   │   ├── debugging.md
│   │   ├── refactoring.md
│   │   └── testing.md
│   ├── prompts/
│   │   ├── components/
│   │   │   ├── context-gathering.md
│   │   │   ├── code-analysis.md
│   │   │   └── output-formatting.md
│   │   └── instructions/
│   │       ├── best-practices.md
│   │       └── tone-guidelines.md
│   └── metadata/
│       └── library-index.json
├── project-loader.lua
└── telescope-picker.lua
```

### Implementation Details

**Telescope Configuration**:
```lua
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Custom multi-select command loader
local function load_claude_commands()
  pickers.new({}, {
    prompt_title = "Claude Command Library",
    finder = finders.new_table({
      results = library_items,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.title,
          preview_command = { "cat", entry.path },
        }
      end
    }),
    mappings = {
      i = {
        ["<Space>"] = actions.toggle_selection,
        ["<CR>"] = function(prompt_bufnr)
          local selections = action_state.get_current_picker(prompt_bufnr):get_multi_selection()
          actions.close(prompt_bufnr)
          load_selections_to_project(selections)
        end,
      },
    },
    attach_mappings = function(_, map)
      map("i", "<C-p>", actions.preview_scrolling_up)
      map("i", "<C-n>", actions.preview_scrolling_down)
      return true
    end,
  }):find()
end
```

**Advantages**:
- ✅ Native Neovim integration
- ✅ Excellent preview functionality
- ✅ Familiar interface for Neovim users
- ✅ Built-in multi-select with `<Tab>/<S-Tab>`
- ✅ Customizable keymaps (can use `<Space>` for toggle)
- ✅ Extensible with custom actions

**Disadvantages**:
- ⚠️ Requires Telescope dependency
- ⚠️ Limited to Neovim environment
- ⚠️ Custom keymap needed for `<Space>` toggle

### File Format Strategy
```markdown
---
title: "Code Review Command"
category: "code-analysis"
tags: ["review", "quality", "best-practices"]
claude_command: true
description: "Comprehensive code review with security and performance focus"
variables:
  - name: "file_pattern"
    description: "File pattern to review (e.g., '*.py')"
    default: "*"
  - name: "focus_areas"
    description: "Specific areas to focus on"
    default: "security, performance, maintainability"
---

# Code Review Command

Please perform a comprehensive code review of the files matching `{{file_pattern}}`.

Focus on:
- {{focus_areas}}
- Code organization and structure
- Potential bugs or edge cases
- Documentation quality

## Output Format
- Summary of findings
- Specific recommendations with line numbers
- Security concerns (if any)
- Performance optimization opportunities
```

## Option 2: Custom Modal Interface

### Architecture
```
ai-claude/
├── ui/
│   ├── modal.lua
│   ├── preview.lua
│   └── selection-state.lua
├── library/
│   └── [same as Option 1]
└── loader.lua
```

### Implementation Approach

**Custom Modal with Preview**:
```lua
local function create_command_modal()
  local modal = {
    items = load_library_items(),
    selected = {},
    current_index = 1,
    preview_win = nil,
    selection_win = nil,
  }

  -- Create floating windows
  modal.selection_win = create_selection_window(modal.items)
  modal.preview_win = create_preview_window()

  -- Keymaps
  vim.keymap.set('n', '<Space>', function()
    toggle_selection(modal.current_index)
  end, { buffer = modal.selection_win })

  vim.keymap.set('n', '<CR>', function()
    load_selected_items(modal.selected)
    close_modal(modal)
  end, { buffer = modal.selection_win })
end
```

**Advantages**:
- ✅ No external dependencies
- ✅ Full control over UI/UX
- ✅ Can implement exact keymap requirements
- ✅ Custom preview functionality
- ✅ Lightweight implementation

**Disadvantages**:
- ⚠️ More development work required
- ⚠️ Need to implement fuzzy search separately
- ⚠️ Less battle-tested than Telescope
- ⚠️ Preview functionality needs custom implementation

## Option 3: Hybrid Telescope + Custom Actions

### Architecture
```
ai-claude/
├── library/          # Same as Option 1
├── telescope/
│   ├── claude-picker.lua
│   ├── actions.lua
│   └── previewers.lua
├── project/
│   ├── loader.lua
│   └── installer.lua
└── commands/
    ├── init.lua
    └── registry.lua
```

### Implementation Strategy

**Enhanced Telescope with Custom Actions**:
```lua
local claude_actions = {
  toggle_with_space = function(prompt_bufnr)
    actions.toggle_selection(prompt_bufnr)
    actions.move_selection_next(prompt_bufnr)
  end,

  load_to_project = function(prompt_bufnr)
    local picker = action_state.get_current_picker(prompt_bufnr)
    local selections = picker:get_multi_selection()

    if vim.tbl_isempty(selections) then
      selections = { picker:get_selection() }
    end

    actions.close(prompt_bufnr)
    project_loader.install_commands(selections)

    vim.notify(string.format("Loaded %d items to project", #selections))
  end,
}

local function claude_command_picker()
  pickers.new({}, {
    prompt_title = "Claude Command Library",
    finder = claude_finders.library_finder(),
    previewer = claude_previewers.command_previewer(),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(_, map)
      map("i", "<Space>", claude_actions.toggle_with_space)
      map("n", "<Space>", claude_actions.toggle_with_space)
      map("i", "<CR>", claude_actions.load_to_project)
      map("n", "<CR>", claude_actions.load_to_project)
      return true
    end,
  }):find()
end
```

**Advantages**:
- ✅ Best of both worlds
- ✅ Leverages Telescope's proven functionality
- ✅ Custom actions for exact workflow
- ✅ Professional preview and search
- ✅ Easy to extend and maintain

**Disadvantages**:
- ⚠️ Telescope dependency
- ⚠️ Moderate complexity

## Option 4: Command Palette Integration

### Architecture
```
ai-claude/
├── palette/
│   ├── commands.json
│   ├── provider.lua
│   └── executor.lua
├── library/          # Same as Option 1
└── integration/
    ├── which-key.lua
    ├── legendary.lua
    └── commander.lua
```

### Implementation Approach

**Command Palette Style**:
```lua
-- Integration with existing command palette systems
local commands = {
  {
    name = "Claude: Load Standard Commands",
    cmd = function()
      local items = load_library_with_categories()
      show_categorized_picker(items)
    end,
    keys = "<leader>cl",
  },
  {
    name = "Claude: Quick Load Common Set",
    cmd = function()
      load_preset("common-development")
    end,
    keys = "<leader>cq",
  },
}
```

**Advantages**:
- ✅ Integrates with existing Neovim workflows
- ✅ Can work with which-key, legendary, commander
- ✅ Familiar command palette paradigm
- ✅ Easy discovery

**Disadvantages**:
- ⚠️ Less visual than dedicated picker
- ⚠️ May not support complex multi-select well
- ⚠️ Preview functionality limited

## Prompt Component Composition Systems

### Modular Prompt Architecture

```
ai-claude/library/prompts/
├── components/
│   ├── personas/
│   │   ├── senior-developer.md
│   │   ├── security-expert.md
│   │   └── code-reviewer.md
│   ├── contexts/
│   │   ├── codebase-analysis.md
│   │   ├── debugging-session.md
│   │   └── feature-implementation.md
│   ├── instructions/
│   │   ├── step-by-step.md
│   │   ├── security-focus.md
│   │   └── performance-focus.md
│   └── outputs/
│       ├── json-format.md
│       ├── markdown-report.md
│       └── action-items.md
└── templates/
    ├── code-review-complete.yaml
    ├── debugging-session.yaml
    └── feature-planning.yaml
```

### Component Composition Interface

```lua
local function create_prompt_composer()
  local composer = {
    selected_components = {
      persona = nil,
      context = nil,
      instructions = {},
      output = nil,
    },
    preview_buffer = nil,
  }

  -- Multi-stage selection process
  return telescope_multi_stage_picker(composer)
end
```

### Template System with Variables

```yaml
# templates/code-review-complete.yaml
name: "Comprehensive Code Review"
description: "Full code review with security and performance analysis"
components:
  persona: "senior-developer"
  context: "codebase-analysis"
  instructions:
    - "step-by-step"
    - "security-focus"
    - "performance-focus"
  output: "markdown-report"
variables:
  file_pattern: "*.{js,ts,py}"
  focus_areas: "security, performance, maintainability"
  depth: "comprehensive"
```

## Recommended Implementation Strategy

### Phase 1: Core Infrastructure
1. **Telescope-based picker** (Option 3 - Hybrid approach)
2. **Markdown-based library format** with YAML frontmatter
3. **Simple file-based storage** in `~/.config/nvim/lua/neotex/ai-claude/library/`

### Phase 2: Enhanced Features
1. **Prompt component composition system**
2. **Template variables and substitution**
3. **Project-specific customization**

### Phase 3: Advanced Workflows
1. **Command history and analytics**
2. **Auto-suggestion based on project type**
3. **Integration with existing Claude Code features**

### Recommended File Structure

```
~/.config/nvim/lua/neotex/ai-claude/
├── library/
│   ├── commands/           # Standard Claude commands
│   ├── prompts/           # Prompt components
│   ├── templates/         # Composed templates
│   └── presets/          # Quick-load presets
├── project/
│   ├── loader.lua        # Project loading logic
│   ├── installer.lua     # File installation
│   └── manager.lua       # Project-specific management
├── ui/
│   ├── telescope-picker.lua
│   ├── actions.lua
│   ├── previewers.lua
│   └── finders.lua
└── init.lua             # Main entry point
```

### Key Benefits of Recommended Approach

1. **Familiar Interface**: Leverages Telescope's proven UX
2. **Flexible Storage**: Markdown with metadata for easy editing
3. **Extensible**: Can add prompt composition later
4. **Standard Compliant**: Works with existing Neovim ecosystem
5. **Project Isolation**: Clean separation of global library vs project files

### Alternative Processes to Consider

**VS Code Style Approach**:
- Store templates in `.claude/` directory at project root
- Use JSON schema for validation
- Implement workspace-scoped vs global scoped templates

**Dotfiles Integration**:
- Store common commands in dotfiles
- Sync across machines with chezmoi/yadm
- Version control for template evolution

**Plugin Ecosystem Integration**:
- Integrate with existing snippet systems (LuaSnip)
- Use mason.nvim pattern for package management
- Leverage lazy.nvim for plugin-style loading

---

*This analysis provides a comprehensive foundation for implementing a command and prompt management system that balances functionality, usability, and maintainability while integrating seamlessly with the existing Neovim ecosystem.*