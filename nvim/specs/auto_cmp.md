# Blink.cmp Autocomplete Enhancement Plan

## Overview
This document outlines the implementation plan to enhance autocomplete behavior in Neovim using blink.cmp, with specific focus on Tab and Return key functionality across different contexts.

## Current Issues
1. Tab completion for long words works in LaTeX files but not in other file formats
2. Tab behavior in command line doesn't insert the first item before cycling
3. Return key behavior needs to be consistent with requirements across different contexts
4. Snippets remain active after partial completion, causing Tab to jump back to unfilled fields

## Root Cause Analysis

### Why Tab Works Better in LaTeX
1. **Omni Source**: LaTeX files have the `omni` source enabled with VimTeX integration
2. **Score Offset**: Omni source has `score_offset = 100`, prioritizing its suggestions
3. **Min Keyword Length**: Omni source has `min_keyword_length = 0`, triggering immediately
4. **Context**: LaTeX context detection ensures suggestions appear when needed

### Issues in Other Filetypes
1. **Higher Min Keyword Length**: LSP (1 char) and buffer (2 chars) sources require more typing
2. **No Immediate Trigger**: Unlike LaTeX, other filetypes don't have a zero-length trigger source
3. **Conflicting Keymaps**: Markdown files have autolist plugin overriding Tab behavior
4. **Completion Menu Visibility**: Tab only works when completion menu is already visible

## Implementation Plan

### Phase 1: Core Configuration Changes

#### 1.1 Update Trigger Settings
```lua
-- In blink-cmp.lua, modify trigger settings
trigger = {
  prefetch_on_insert = true,
  show_in_snippet = true,
  show_on_keyword = true,
  show_on_trigger_character = true,
  show_on_blocked_trigger_characters = { '\n', '\t' }, -- Remove space
  show_on_accept_on_trigger_character = true,
  show_on_insert_on_trigger_character = true,
  show_on_x_blocked_trigger_characters = { "'", '"', '(' },
  -- Add new settings
  show_on_partial_word = true,  -- Show completion for partial words
  min_show_length = 1,          -- Show after 1 character
}
```

#### 1.2 Adjust Source Configuration
```lua
-- Reduce minimum keyword lengths for better triggering
sources = {
  default = { 'lsp', 'path', 'snippets', 'buffer' },
  providers = {
    lsp = {
      name = 'LSP',
      enabled = function(...) end, -- Keep existing
      min_keyword_length = 0,  -- Reduced from 1
      score_offset = 90,       -- High priority but below omni
    },
    buffer = {
      name = 'Buffer',
      enabled = function(...) end, -- Keep existing
      min_keyword_length = 1,  -- Reduced from 2
      score_offset = 50,
    },
  },
}
```

### Phase 2: Keymap Enhancements

#### 2.1 Buffer Tab Behavior
```lua
-- Enhanced Tab keymap for insert mode
['<Tab>'] = {
  function(cmp)
    -- If completion menu is visible, accept the selected item
    if cmp.is_visible() then
      return cmp.accept()
    -- If cursor is after a partial word, show completion
    elseif cmp.snippet_active() then
      return cmp.snippet_forward()
    else
      -- Trigger completion if we're after a word character
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      if col > 0 and line:sub(col, col):match('%w') then
        return cmp.show()
      end
    end
  end,
  'fallback'
},
```

#### 2.2 Return Key Behavior
```lua
-- Keep existing Return behavior but ensure it works consistently
['<CR>'] = {
  function(cmp)
    if cmp.is_visible() then
      -- Accept the currently selected item
      return cmp.accept()
    end
  end,
  'fallback'
},
```

### Phase 3: Command Line Specific Configuration

#### 3.1 Enhanced Command Line Keymaps
```lua
-- In cmdline configuration section
keymap = {
  preset = 'none',
  ['<C-k>'] = { 'select_prev', 'fallback' },
  ['<C-j>'] = { 'select_next', 'fallback' },
  ['<Tab>'] = {
    function(cmp)
      if cmp.is_visible() then
        -- First Tab: accept current selection
        -- Subsequent Tabs: cycle through options
        if not vim.g.blink_cmdline_tab_pressed then
          vim.g.blink_cmdline_tab_pressed = true
          return cmp.accept({ select = false })
        else
          return cmp.select_next()
        end
      end
    end,
    'fallback'
  },
  ['<S-Tab>'] = { 'select_prev', 'fallback' },
  ['<CR>'] = {
    function(cmp)
      if cmp.is_visible() then
        -- Always accept the current selection
        return cmp.accept()
      end
    end,
    'fallback'
  },
  ['<C-e>'] = { 'hide', 'fallback' },
}

-- Reset tab state when entering command line
vim.api.nvim_create_autocmd('CmdlineEnter', {
  callback = function()
    vim.g.blink_cmdline_tab_pressed = false
  end,
})
```

### Phase 4: Filetype-Specific Fixes

#### 4.1 Markdown Compatibility
```lua
-- Add to ftplugin/markdown.lua or in autocmd
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function()
    -- Override autolist Tab mapping to check for completion first
    vim.keymap.set('i', '<Tab>', function()
      local cmp = require('blink.cmp')
      if cmp.is_visible() then
        return cmp.accept()
      else
        -- Fall back to autolist behavior
        return require('autolist').operations.tab_handler()
      end
    end, { buffer = true, expr = true })
  end,
})
```

### Phase 5: Snippet Management

#### 5.1 Auto-exit Snippet Mode
```lua
-- Add snippet auto-exit functionality
vim.api.nvim_create_autocmd({ 'CursorMoved', 'InsertLeave' }, {
  callback = function()
    local cmp = require('blink.cmp')
    -- Check if we've moved outside the snippet region
    if cmp.snippet_active() then
      local luasnip = require('luasnip')
      local current_buf = vim.api.nvim_get_current_buf()
      local cursor = vim.api.nvim_win_get_cursor(0)
      
      -- If cursor is outside snippet boundaries, exit snippet mode
      if not luasnip.in_snippet() or luasnip.session.current_nodes[current_buf] == nil then
        luasnip.unlink_current()
      end
    end
  end,
})
```

#### 5.2 Enhanced Tab Behavior with Snippet Exit
```lua
-- Modified Tab keymap to handle snippet exit
['<Tab>'] = {
  function(cmp)
    local luasnip = require('luasnip')
    
    -- If completion menu is visible, accept the selected item
    if cmp.is_visible() then
      return cmp.accept()
    -- If in snippet, check if we should continue or exit
    elseif luasnip.expand_or_locally_jumpable() then
      -- Check if cursor has moved away from snippet fields
      if luasnip.locally_jumpable(1) then
        return cmp.snippet_forward()
      else
        -- Exit snippet mode if no more jumps
        luasnip.unlink_current()
      end
    else
      -- Trigger completion if we're after a word character
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      if col > 0 and line:sub(col, col):match('%w') then
        return cmp.show()
      end
    end
  end,
  'fallback'
},
```

#### 5.3 Explicit Snippet Exit Keymap
```lua
-- Add explicit snippet exit key (optional)
vim.keymap.set({ 'i', 's' }, '<C-l>', function()
  local luasnip = require('luasnip')
  if luasnip.session.current_nodes[vim.api.nvim_get_current_buf()] then
    luasnip.unlink_current()
  end
end, { desc = 'Exit snippet mode' })
```

### Phase 6: Auto-show Completion

#### 6.1 Smart Auto-show Function
```lua
-- Add auto-show completion after typing
vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChangedP' }, {
  callback = function()
    local cmp = require('blink.cmp')
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    
    -- Check if we're typing a word
    if col > 0 then
      local before_cursor = line:sub(1, col)
      local word_pattern = '%w+$'
      local partial_word = before_cursor:match(word_pattern)
      
      -- Show completion if we have a partial word of 2+ characters
      if partial_word and #partial_word >= 2 and not cmp.is_visible() then
        cmp.show()
      end
    end
  end,
})
```

## Testing Plan

### 1. Buffer Completion Tests
- [ ] Test Tab completion in Python files for long variable names
- [ ] Test Tab completion in JavaScript files for method names
- [ ] Test Tab completion in Markdown files (ensure autolist compatibility)
- [ ] Test Return key accepts first suggestion in all filetypes
- [ ] Test snippet expansion with Tab in various filetypes

### 2. Command Line Tests
- [ ] Test `:` command completion with Tab (should insert first match)
- [ ] Test multiple Tab presses (should cycle through options)
- [ ] Test Return key (should accept current selection)
- [ ] Test `/` search completion behavior
- [ ] Test `?` reverse search completion behavior

### 3. Edge Cases
- [ ] Test completion at beginning of line
- [ ] Test completion after punctuation
- [ ] Test completion with mixed case words
- [ ] Test completion in comments vs code
- [ ] Test with LSP server disconnected

### 4. Snippet Tests
- [ ] Test snippet with partial field completion (exit early)
- [ ] Test Tab behavior after leaving snippet incomplete
- [ ] Test auto-exit on cursor movement outside snippet
- [ ] Test explicit snippet exit with Ctrl-L
- [ ] Test snippet behavior across different filetypes

## Rollback Plan
If issues arise:
1. Keep original `blink-cmp.lua` as backup
2. Revert keymap changes individually
3. Disable auto-show functionality if it's too aggressive
4. Re-enable filetype-specific overrides if needed

## Alternative Approaches

### Option A: Context-Aware Tab
Instead of always accepting on Tab, make it context-aware:
- In code: Accept completion
- After space: Insert tab
- In string: Check for completion first

### Option B: Different Trigger Key
Use a different key (e.g., `<C-n>`) for explicit completion trigger while keeping Tab for navigation.

### Option C: Preset Modification
Create a custom preset that combines 'default' and 'super-tab' behaviors from blink.cmp.

## Notes
- Monitor performance impact of reduced `min_keyword_length`
- Consider adding debouncing if auto-show becomes too aggressive
- May need to adjust `score_offset` values based on testing
- Command line Tab behavior might need refinement based on user feedback