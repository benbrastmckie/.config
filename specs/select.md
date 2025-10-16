# vim.ui.select Refactoring Plan: Migrate to telescope-ui-select.nvim

## Overview

This plan details the migration from dressing.nvim to telescope-ui-select.nvim for all `vim.ui.select` functionality in the Neovim configuration. The goal is to achieve a cleaner, more consistent selection UI using Telescope throughout the entire configuration.

## Current State Analysis

### Dependencies Using dressing.nvim
1. **Avante.nvim** - Has dressing.nvim as a hard dependency
2. **Session Manager** - Lists dressing.nvim as a dependency

### Current vim.ui.select Usage
- **Himalaya Email Plugin**: Folder/account selection, restoration prompts, batch operations
- **Buffer Utilities**: File deletion confirmations (currently using misc.confirm)
- **Neo-tree**: File/directory deletion (currently using custom input)
- **Email Composer**: Send/discard confirmations (currently using misc.confirm)
- **Session Manager**: Session selection
- **Various Confirmations**: Throughout the codebase

### Files with Confirmation/Selection Logic
1. `/home/benjamin/.config/nvim/lua/neotex/util/confirm.lua` - Complex custom confirmation system
2. `/home/benjamin/.config/nvim/lua/neotex/util/misc.lua` - Contains misc.confirm function
3. `/home/benjamin/.config/nvim/lua/neotex/util/buffer.lua` - Uses misc.confirm
4. `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/neo-tree.lua` - Custom deletion confirmation
5. `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/email_composer.lua` - Uses misc.confirm
6. `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/main.lua` - Multiple vim.ui.select calls
7. `/home/benjamin/.config/nvim/lua/neotex/deprecated/dressing.lua` - To be removed

## Implementation Plan

### Phase 1: Setup telescope-ui-select

1. **Configure telescope-ui-select** in `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/telescope.lua`:
   ```lua
   -- Add to extensions configuration
   extensions = {
     ["ui-select"] = {
       require("telescope.themes").get_dropdown({
         winblend = 10,
         width = 0.3,
         prompt_title = "",
         results_title = "",
         previewer = false,
         layout_config = {
           height = 0.3,
         }
       })
     },
     -- ... existing extensions
   }
   
   -- Add to load_extension list
   load_extension = {
     "fzf",
     "yank_history", 
     "bibtex",
     "lazygit",
     "ui-select"  -- Add this
   },
   ```

### Phase 2: Remove Custom Confirmation Systems

1. **Delete custom confirm module**:
   - Delete `/home/benjamin/.config/nvim/lua/neotex/util/confirm.lua`
   - Remove "confirm" from module list in `/home/benjamin/.config/nvim/lua/neotex/util/init.lua`

2. **Update misc.lua** - Simplify the confirm function:
   ```lua
   -- Replace the existing misc.confirm with a wrapper that uses vim.ui.select
   function M.confirm(prompt, danger_default_no)
     local items = danger_default_no and {"No", "Yes"} or {"Yes", "No"}
     local result = false
     local done = false
     
     vim.ui.select(items, {
       prompt = prompt,
       kind = "confirmation"
     }, function(choice)
       result = choice == "Yes"
       done = true
     end)
     
     -- Simple wait for async completion
     vim.wait(5000, function() return done end, 10)
     return result
   end
   ```

### Phase 3: Update File-Specific Confirmations

1. **buffer.lua** - Update delete confirmation:
   ```lua
   -- Change from:
   if not misc.confirm('Delete file "' .. filename .. '"?', true) then
   
   -- To:
   local confirmed = false
   vim.ui.select({'Yes', 'No'}, {
     prompt = 'Delete file "' .. filename .. '"?',
   }, function(choice)
     confirmed = choice == 'Yes'
   end)
   if not confirmed then
     return
   end
   ```

2. **neo-tree.lua** - Replace custom input with vim.ui.select:
   ```lua
   ["d"] = function(state)
     local tree = state.tree
     local node = tree:get_node()
     if node.type == "file" or node.type == "directory" then
       local filename = node.name
       local item_type = node.type == "directory" and "directory" or "file"
       
       vim.ui.select({'Yes', 'No'}, {
         prompt = string.format('Delete %s "%s"?', item_type, filename),
       }, function(choice)
         if choice == 'Yes' then
           local fs_actions = require("neo-tree.sources.filesystem.lib.fs_actions")
           fs_actions.delete_node(node.path, function()
             require("neo-tree.sources.manager").refresh("filesystem")
           end, true)
         end
       end)
     end
   end,
   ```

3. **email_composer.lua** - Update send/discard confirmations:
   ```lua
   -- For send confirmation:
   vim.ui.select({'Yes', 'No'}, {
     prompt = 'Send email to ' .. email.to .. '?',
   }, function(choice)
     if choice == 'Yes' then
       -- send email logic
     end
   end)
   
   -- For discard confirmation:
   local message = modified and 'Discard unsaved email draft?' or 'Discard email draft?'
   vim.ui.select({'No', 'Yes'}, {  -- No first for dangerous action
     prompt = message,
   }, function(choice)
     if choice == 'Yes' then
       -- discard logic
     end
   end)
   ```

### Phase 4: Handle Dependencies

1. **Avante.nvim Dependency**:
   - Since Avante requires dressing.nvim, we cannot remove it from dependencies
   - However, we can prevent dressing from affecting vim.ui.select by configuring it
   - Add to Avante's config section:
   ```lua
   config = function(_, opts)
     -- Disable dressing's select enhancement
     if pcall(require, "dressing") then
       require("dressing.config").options.select.enabled = false
     end
     -- Rest of Avante config...
   end
   ```

2. **Session Manager**:
   - Remove dressing.nvim from its dependencies list
   - It will use telescope-ui-select automatically

### Phase 5: Cleanup

1. **Remove deprecated files**:
   - Delete `/home/benjamin/.config/nvim/lua/neotex/deprecated/dressing.lua`

2. **Update documentation**:
   - Update any README files that mention confirmation systems
   - Document the standardized vim.ui.select usage pattern

## Standard Patterns

### Basic Yes/No Confirmation
```lua
vim.ui.select({'Yes', 'No'}, {
  prompt = 'Continue with action?',
}, function(choice)
  if choice == 'Yes' then
    -- perform action
  end
end)
```

### Dangerous Action (No as default)
```lua
vim.ui.select({'No', 'Yes'}, {  -- No listed first
  prompt = 'Delete all files?',
}, function(choice)
  if choice == 'Yes' then
    -- perform dangerous action
  end
end)
```

### Multiple Options
```lua
local options = {'Option 1', 'Option 2', 'Option 3', 'Cancel'}
vim.ui.select(options, {
  prompt = 'Choose an option:',
}, function(choice)
  if choice and choice ~= 'Cancel' then
    -- handle selection
  end
end)
```

## Benefits

1. **Consistency**: All selections use Telescope UI
2. **Power**: Fuzzy finding for longer lists (folders, accounts, etc.)
3. **Simplicity**: No custom confirmation code to maintain
4. **Integration**: Leverages existing Telescope configuration and keybindings
5. **Clean Architecture**: Removes hidden dependency complexity

## Testing Plan

1. Test each confirmation type:
   - File deletion (`<leader>ak`)
   - Neo-tree file/directory deletion
   - Email send/discard
   - Himalaya folder/account selection
   - Session restoration

2. Verify Telescope features work:
   - Fuzzy filtering in selection lists
   - Escape to cancel
   - Enter to confirm
   - Standard Telescope navigation

## Rollback Plan

If issues arise:
1. Re-enable dressing select in Avante config
2. Revert to previous misc.confirm implementation
3. All vim.ui.select calls will continue working with dressing

## Notes

- vim.ui.input will remain unenhanced (command line style) after removing dressing
- This is acceptable as it's rarely used in the configuration
- If input enhancement is needed later, consider a minimal solution