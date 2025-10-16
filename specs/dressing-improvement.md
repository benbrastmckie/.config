# vim.ui.select/input Improvement Plan: Optimize dressing.nvim Usage

## Overview

This plan details the optimization of dressing.nvim usage throughout the Neovim configuration. Rather than replacing dressing.nvim, we'll leverage its strengths: lightweight core with the ability to use different backends (telescope, fzf, builtin) based on context. The goal is to achieve consistency, remove redundant code, and create a maintainable selection/input system.

## Why Keep dressing.nvim

1. **Lightweight by default** - Uses simple floating windows for basic prompts
2. **Backend flexibility** - Can use telescope for complex selections, builtin for simple Yes/No
3. **Enhances BOTH select and input** - Complete UI enhancement solution
4. **Smart backend selection** - Can choose backend based on number of items or type
5. **Already working well** - Currently providing the nice UI you see

## Current State Analysis

### Dressing.nvim Status
- **Loaded by**: Avante.nvim (as dependency)
- **Configuration**: None (using defaults)
- **Deprecated config exists**: `/home/benjamin/.config/nvim/lua/neotex/deprecated/dressing.lua`

### Current Issues
1. **No explicit configuration** - Missing opportunity to optimize
2. **Complex confirm.lua module** - Tries to work around vim.ui.select instead of using it
3. **Inconsistent patterns** - Mix of vim.fn.input, misc.confirm, and custom solutions
4. **No backend optimization** - Not leveraging dressing's ability to use different backends

## Implementation Plan

### Phase 1: Create Proper Dressing Configuration

1. **Move dressing config to active plugins** - Create `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/dressing.lua`:
```lua
return {
  "stevearc/dressing.nvim",
  lazy = false,  -- Load immediately to enhance UI
  priority = 1000,  -- Load before other UI plugins
  config = function()
    require('dressing').setup({
      input = {
        -- Enhanced input settings
        enabled = true,
        default_prompt = "Input:",
        trim_prompt = true,
        border = "rounded",
        relative = "cursor",
        prefer_width = 40,
        width = nil,
        max_width = { 140, 0.9 },
        min_width = { 20, 0.2 },
        win_options = {
          winblend = 0,
          wrap = false,
        },
        mappings = {
          n = {
            ["<Esc>"] = "Close",
            ["<CR>"] = "Confirm",
          },
          i = {
            ["<C-c>"] = "Close",
            ["<CR>"] = "Confirm",
            ["<Up>"] = "HistoryPrev",
            ["<Down>"] = "HistoryNext",
          },
        },
      },
      select = {
        -- Enhanced select settings
        enabled = true,
        backend = { "telescope", "builtin" },  -- Use telescope for many items, builtin for few
        trim_prompt = true,
        
        -- Telescope configuration for complex selections
        telescope = require('telescope.themes').get_dropdown({
          winblend = 10,
          width = 0.5,
          prompt_title = "",
          results_title = "",
          previewer = false,
          layout_config = {
            height = 0.4,
          }
        }),
        
        -- Builtin configuration for simple selections (Yes/No, etc)
        builtin = {
          border = "rounded",
          relative = "cursor",
          width = nil,
          max_width = { 80, 0.4 },
          min_width = { 40, 0.2 },
          height = nil,
          max_height = 0.3,
          min_height = { 3, 0.1 },
          mappings = {
            ["<Esc>"] = "Close",
            ["<C-c>"] = "Close",
            ["<CR>"] = "Confirm",
            ["j"] = "Next",
            ["k"] = "Previous",
          },
        },
        
        -- Smart backend selection based on context
        get_config = function(opts)
          if opts.kind == 'codeaction' then
            return {
              backend = "telescope",
              telescope = require('telescope.themes').get_cursor({})
            }
          end
          
          -- Use builtin for confirmations (2-3 items)
          if opts.kind == 'confirmation' or (opts.items and #opts.items <= 3) then
            return {
              backend = "builtin",
              builtin = {
                relative = "cursor",
                width = 30,
                height = 4,
              }
            }
          end
          
          -- Use telescope for many items
          return {
            backend = "telescope"
          }
        end,
      },
    })
  end
}
```

### Phase 2: Simplify Confirmation System

1. **Remove complex confirm.lua**:
   - Delete `/home/benjamin/.config/nvim/lua/neotex/util/confirm.lua`
   - Remove "confirm" from module list in `/home/benjamin/.config/nvim/lua/neotex/util/init.lua`

2. **Create simple confirmation utilities in misc.lua**:
```lua
-- Add these utility functions to misc.lua

-- Standard Yes/No confirmation
function M.confirm(prompt, danger_default_no)
  local items = danger_default_no and {"No", "Yes"} or {"Yes", "No"}
  local choice = nil
  local done = false
  
  vim.ui.select(items, {
    prompt = prompt,
    kind = "confirmation",  -- Tells dressing to use builtin backend
  }, function(selected)
    choice = selected
    done = true
  end)
  
  -- Simple wait for async completion
  vim.wait(5000, function() return done end, 10)
  return choice == "Yes"
end

-- Confirmation with custom options
function M.select_choice(prompt, choices, opts)
  opts = opts or {}
  local choice = nil
  local done = false
  
  vim.ui.select(choices, {
    prompt = prompt,
    kind = opts.kind or "selection",
    format_item = opts.format_item,
  }, function(selected)
    choice = selected
    done = true
  end)
  
  vim.wait(5000, function() return done end, 10)
  return choice
end

-- Quick confirm with icons
function M.confirm_action(action_type, target)
  local prompts = {
    delete = { icon = "🗑️", text = "Delete", danger = true },
    save = { icon = "💾", text = "Save", danger = false },
    send = { icon = "📧", text = "Send", danger = false },
    discard = { icon = "❌", text = "Discard", danger = true },
  }
  
  local config = prompts[action_type] or { icon = "❓", text = action_type, danger = false }
  local prompt = string.format("%s %s %s?", config.icon, config.text, target or "")
  
  return M.confirm(prompt, config.danger)
end
```

### Phase 3: Update Usage Throughout Codebase

1. **buffer.lua** - Keep using misc.confirm but simplified:
```lua
-- No change needed, already uses:
if not misc.confirm('Delete file "' .. filename .. '"?', true) then
  return
end

-- Or could use new helper:
if not misc.confirm_action('delete', 'file "' .. filename .. '"') then
  return
end
```

2. **neo-tree.lua** - Update to use vim.ui.select:
```lua
["d"] = function(state)
  local tree = state.tree
  local node = tree:get_node()
  if node.type == "file" or node.type == "directory" then
    local misc = require('neotex.util.misc')
    local filename = node.name
    local item_type = node.type == "directory" and "directory" or "file"
    
    if misc.confirm_action('delete', item_type .. ' "' .. filename .. '"') then
      local fs_actions = require("neo-tree.sources.filesystem.lib.fs_actions")
      fs_actions.delete_node(node.path, function()
        require("neo-tree.sources.manager").refresh("filesystem")
      end, true)
    end
  end
end,
```

3. **email_composer.lua** - Update to use consistent pattern:
```lua
-- For send confirmation:
local misc = require('neotex.util.misc')
if misc.confirm_action('send', 'email to ' .. email.to) then
  -- send email logic
end

-- For discard confirmation:
local message = modified and 'unsaved email draft' or 'email draft'
if misc.confirm_action('discard', message) then
  -- discard logic
end
```

### Phase 4: Remove Dependencies and Redundancies

1. **Session Manager** - Remove explicit dressing dependency:
```lua
dependencies = {
  "nvim-lua/plenary.nvim",
  -- Remove: "stevearc/dressing.nvim",  -- Will be loaded globally
  -- Remove: "nvim-telescope/telescope-ui-select.nvim",  -- Not needed with dressing
},
```

2. **Avante.nvim** - Keep as is (already has dressing as dependency)

3. **Delete deprecated config**:
   - Delete `/home/benjamin/.config/nvim/lua/neotex/deprecated/dressing.lua`

### Phase 5: Standardize Patterns

1. **Create documentation** for standard patterns:

```lua
-- STANDARD PATTERNS FOR SELECTIONS

-- 1. Simple Yes/No confirmation (safe action)
local misc = require('neotex.util.misc')
if misc.confirm("Continue?") then
  -- action
end

-- 2. Dangerous confirmation (defaults to No)
if misc.confirm("Delete all files?", true) then
  -- dangerous action
end

-- 3. Action confirmations with icons
if misc.confirm_action('delete', 'important.txt') then
  -- delete file
end

-- 4. Multiple choice selection
local choice = misc.select_choice("Choose option:", {
  "Option 1",
  "Option 2", 
  "Cancel"
})
if choice and choice ~= "Cancel" then
  -- handle choice
end

-- 5. Direct vim.ui.select for complex cases
vim.ui.select(folders, {
  prompt = "Select folder:",
  format_item = function(item)
    return "📁 " .. item
  end
}, function(choice)
  if choice then
    -- handle selection
  end
end)

-- 6. Text input with vim.ui.input
vim.ui.input({
  prompt = "Enter name: ",
  default = current_name,
}, function(input)
  if input and input ~= "" then
    -- handle input
  end
end)
```

## Advanced Dressing Configuration

### Context-Aware Backend Selection

The configuration uses `get_config` to intelligently choose backends:

1. **Code Actions** → Telescope (many items, need search)
2. **Confirmations** → Builtin (2-3 items, quick selection)
3. **File/Folder Lists** → Telescope (searchable lists)
4. **Small Lists (≤3)** → Builtin (lightweight)

### Visual Consistency

- **Rounded borders** throughout
- **Cursor-relative positioning** for context
- **Consistent keymappings** across backends
- **Icon usage** for visual clarity

## Benefits of This Approach

1. **Leverages dressing's strengths** - Smart backend selection
2. **Minimal code** - No custom confirmation modules
3. **Consistency** - Same patterns everywhere
4. **Performance** - Lightweight for simple prompts, powerful for complex ones
5. **Flexibility** - Easy to adjust backend selection rules
6. **Both select and input** - Complete UI enhancement

## Testing Plan

1. **Simple confirmations** should use builtin floating window
2. **File/folder selections** should use telescope
3. **Input prompts** should show floating input box
4. **All existing functionality** should work unchanged

## Migration Steps

1. Create new dressing config
2. Update misc.lua with new utilities
3. Remove confirm.lua and update init.lua
4. Test each confirmation type
5. Update individual files if needed
6. Remove deprecated files

## Future Enhancements

1. **Custom format_item functions** for specific types
2. **Theme integration** for consistent colors
3. **Animation settings** for smoother transitions
4. **Context-specific icons** in prompts

This approach maintains the lightweight nature of dressing while providing a consistent, powerful selection system throughout your configuration.