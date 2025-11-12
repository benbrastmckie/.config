# CR Behavior Configuration Without Always Creating Newlines - Research Report

## Metadata
- **Date**: 2025-11-04
- **Agent**: research-specialist
- **Topic**: CR behavior configuration without always creating newlines
- **Report Type**: best practices analysis

## Executive Summary

The current configuration (autopairs.lua:105-120) uses `check_break_line_char()` which evaluates whether the cursor is between paired brackets, but this function may not accurately detect all non-bracket contexts. The recommended solution is to use the official `autopairs_cr()` API function, which properly handles both bracket expansion and normal CR behavior. With `map_cr = false` in setup, a custom mapping can integrate blink.cmp completion acceptance with conditional autopairs behavior, ensuring CR only expands pairs when truly between brackets and behaves normally otherwise.

## Findings

### Current Configuration Analysis

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/autopairs.lua`

**Setup Configuration** (lines 10-25):
- `map_cr = false` - Correctly disables autopairs' built-in CR mapping
- `check_ts = true` - Enables treesitter integration for context-aware pairing
- `enable_check_bracket_line = true` - Prevents duplicate closing brackets

**Current CR Mapping Implementation** (lines 105-120):
```lua
vim.keymap.set('i', '<CR>', function()
  if blink.is_visible() then
    blink.accept()
    return t('<Ignore>')
  else
    local npairs = require('nvim-autopairs')
    if npairs.check_break_line_char() then
      return t('<CR><C-o>O')
    else
      return t('<CR>')
    end
  end
end, { expr = true, silent = true, noremap = true, replace_keycodes = false })
```

**Issue Identified**:
- Uses `check_break_line_char()` for bracket detection (line 113)
- Manual implementation `<CR><C-o>O` (line 115) doesn't leverage autopairs' full logic
- May not respect all autopairs rules and conditions (with_cr, treesitter context, etc.)

### nvim-autopairs CR Handling APIs

**Official API Functions**:

1. **`autopairs_cr()`** - Primary CR handling function
   - Returns appropriate terminal codes based on cursor context
   - Respects all autopairs rules, treesitter integration, and conditions
   - Handles both bracket expansion and normal CR automatically

2. **`check_break_line_char()`** - Boolean detection function
   - Returns true if cursor is between pairs that should break
   - Useful for conditional logic but requires manual CR handling
   - Less comprehensive than `autopairs_cr()`

3. **`esc()`** - Terminal code helper
   - Safely wraps terminal codes for use in mappings
   - Example: `npairs.esc('<c-y>')` for accepting completion

### Integration Patterns

**Pattern 1: Official autopairs_cr() API** (Recommended)
```lua
local npairs = require('nvim-autopairs')
npairs.setup({ map_cr = false })

vim.keymap.set('i', '<CR>', function()
  if completion_menu_visible() then
    return accept_completion()
  else
    return npairs.autopairs_cr()
  end
end, { expr = true, noremap = true })
```

**Pattern 2: Manual check_break_line_char()** (Current approach)
```lua
vim.keymap.set('i', '<CR>', function()
  if completion_menu_visible() then
    return accept_completion()
  else
    if npairs.check_break_line_char() then
      return t('<CR><C-o>O')  -- Manual newline + indent
    else
      return t('<CR>')
    end
  end
end, { expr = true, noremap = true })
```

**Comparison**:
- Pattern 1: Uses autopairs' full logic including treesitter, rule conditions, indentation
- Pattern 2: Manual implementation bypasses autopairs' sophisticated context detection

### blink.cmp Integration Specifics

**Current Implementation** (autopairs.lua:90-124):
- Checks `blink.is_visible()` for completion menu state
- Calls `blink.accept()` when menu is visible
- Falls back to autopairs logic when menu is hidden

**blink.cmp CR Configuration** (blink-cmp.lua:76):
```lua
['<CR>'] = { 'accept', 'fallback' }
```
- This mapping is in blink.cmp's keymap configuration
- May conflict with custom CR mapping in autopairs.lua

**Integration Challenge**:
- Two separate CR mappings: one in blink-cmp.lua (line 76), one in autopairs.lua (line 105)
- The autopairs.lua mapping overrides blink-cmp.lua's mapping
- Need to ensure only one CR mapping exists or properly coordinate them

### Conditional CR Behavior with Rules

**Using `:with_cr()` Method**:
```lua
local Rule = require('nvim-autopairs.rule')
local cond = require('nvim-autopairs.conds')

-- Disable CR expansion for specific pairs
autopairs.add_rules({
  Rule("$", "$", "tex"):with_cr(cond.none())  -- No expansion in LaTeX math
})
```

**Current Rules** (autopairs.lua:53-82):
- Space handling rules use `:with_cr(cond.none())` (line 59)
- LaTeX spacing rules properly configured with conditional CR
- Demonstrates understanding of rule-level CR control

### Best Practices from Community

**Recommendations from nvim-autopairs Documentation**:
1. Set `map_cr = false` when using custom completion integration
2. Use `autopairs_cr()` function for consistent behavior
3. Check completion menu visibility before calling autopairs functions
4. Use `expr = true` in keymap options for function-based mappings

**Common Pitfalls**:
1. Forgetting `replace_keycodes = false` in mapping options (can cause terminal code issues)
2. Using `check_break_line_char()` without understanding it only detects, doesn't execute
3. Manually implementing CR expansion instead of using `autopairs_cr()`
4. Not coordinating with completion plugin's CR mapping

## Recommendations

### Recommendation 1: Replace check_break_line_char() with autopairs_cr()

**Priority**: High

**Rationale**: The `autopairs_cr()` function is the official API that handles all autopairs logic including treesitter context, rule conditions, and proper indentation. It eliminates the need for manual CR handling.

**Implementation**:
```lua
-- In autopairs.lua, replace the setup_blink_integration function (lines 90-124)
local function setup_blink_integration()
  local ok, blink = pcall(require, 'blink.cmp')
  if not ok then return end

  if not blink.is_visible then
    return
  end

  local npairs = require('nvim-autopairs')

  -- Map CR to handle both completion and autopairs
  vim.keymap.set('i', '<CR>', function()
    if blink.is_visible() then
      -- Accept completion when menu is visible
      blink.accept()
      return ''  -- Return empty string after accepting
    else
      -- Use autopairs_cr() for automatic bracket expansion or normal CR
      return npairs.autopairs_cr()
    end
  end, { expr = true, silent = true, noremap = true, replace_keycodes = false })
end
```

**Benefits**:
- Respects all autopairs rules and treesitter integration
- Automatically handles bracket expansion only when appropriate
- Normal CR behavior in non-bracket contexts
- No manual terminal code manipulation needed

### Recommendation 2: Remove Redundant CR Mapping from blink-cmp.lua

**Priority**: Medium

**Rationale**: Having two CR mappings (one in blink-cmp.lua:76, one in autopairs.lua:105) creates conflicts. The autopairs.lua mapping overrides blink-cmp's mapping, making the blink-cmp configuration ineffective.

**Implementation**:
```lua
-- In blink-cmp.lua, modify the keymap section (around line 67-84)
keymap = {
  preset = 'default',
  ['<C-k>'] = { 'select_prev', 'fallback' },
  ['<C-j>'] = { 'select_next', 'fallback' },
  ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
  ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
  ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
  ['<C-e>'] = { 'hide', 'fallback' },
  -- Remove or comment out the CR mapping - handled by autopairs.lua
  -- ['<CR>'] = { 'accept', 'fallback' },
  ['<Tab>'] = {
    'snippet_forward',
    'select_and_accept',
    'fallback'
  },
  ['<S-Tab>'] = { 'snippet_backward', 'select_prev', 'fallback' },
},
```

**Benefits**:
- Single source of truth for CR behavior
- No mapping conflicts
- Clearer configuration maintenance

### Recommendation 3: Add Filetype-Specific CR Conditions (Optional Enhancement)

**Priority**: Low

**Rationale**: Some filetypes may benefit from different CR behavior. For example, LaTeX math mode or Markdown lists might want specialized handling.

**Implementation**:
```lua
-- In autopairs.lua, enhance setup_blink_integration function
local function setup_blink_integration()
  local ok, blink = pcall(require, 'blink.cmp')
  if not ok then return end

  if not blink.is_visible then
    return
  end

  local npairs = require('nvim-autopairs')

  vim.keymap.set('i', '<CR>', function()
    if blink.is_visible() then
      blink.accept()
      return ''
    else
      -- Optional: Add filetype-specific logic here
      local ft = vim.bo.filetype

      -- Example: Special handling for markdown
      if ft == 'markdown' then
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2]
        -- Check for list continuation, etc.
      end

      return npairs.autopairs_cr()
    end
  end, { expr = true, silent = true, noremap = true, replace_keycodes = false })
end
```

**Benefits**:
- Filetype-aware CR behavior
- Can integrate with other plugins (like autolist.lua)
- Maintains backward compatibility

### Recommendation 4: Verify Treesitter Integration

**Priority**: Medium

**Rationale**: The current configuration has `check_ts = true`, which enables treesitter-based context detection. This should prevent autopairs from operating in string/comment contexts, but it's worth verifying this works correctly with the new autopairs_cr() implementation.

**Validation Steps**:
1. Test CR behavior inside strings: `"hello|"` (cursor at |)
2. Test CR behavior inside comments: `// comment|`
3. Test CR behavior between brackets: `{|}`, `(|)`, `[|]`
4. Test CR behavior in normal text: `hello|world`

**Expected Results**:
- Strings/comments: Normal CR (no bracket expansion)
- Between brackets: Expanded CR with proper indentation
- Normal text: Normal CR
- After completion acceptance: Normal CR

### Recommendation 5: Consider Using blink.cmp's Native Integration (Future Enhancement)

**Priority**: Low

**Rationale**: As of the research (Issue #477 on nvim-autopairs), there's discussion about native blink.cmp support. Monitor this issue for official integration patterns that might emerge.

**Action Items**:
- Watch nvim-autopairs Issue #477 for updates
- Consider migrating to official integration if/when available
- Current custom implementation is acceptable interim solution

**Benefits**:
- Official support means better maintenance
- Potential performance improvements
- Reduced custom code maintenance

## References

### Codebase Files Analyzed

1. `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/autopairs.lua`
   - Line 10-25: Setup configuration with `map_cr = false`
   - Line 24: `map_cr = false` setting
   - Line 59: Example of `:with_cr(cond.none())` usage in space handling rules
   - Line 90-124: `setup_blink_integration()` function implementation
   - Line 105-120: Current CR keymap using `check_break_line_char()`
   - Line 113: `npairs.check_break_line_char()` call
   - Line 115: Manual `<CR><C-o>O` implementation

2. `/home/benjamin/.config/nvim/lua/neotex/plugins/lsp/blink-cmp.lua`
   - Line 76: CR mapping in blink.cmp keymap configuration
   - Line 67-84: Complete keymap section
   - Line 224-283: Completion configuration section

3. `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/mini.lua`
   - Line 36-37: Comment noting mini.pairs was removed in favor of nvim-autopairs

### External Documentation

1. **nvim-autopairs GitHub Repository**
   - URL: https://github.com/windwp/nvim-autopairs
   - Main README with API documentation
   - `map_cr` option documentation
   - `autopairs_cr()` function reference

2. **nvim-autopairs Wiki - Custom Rules**
   - URL: https://github.com/windwp/nvim-autopairs/wiki/Custom-rules
   - `:with_cr()` method documentation
   - Conditional rule examples

3. **nvim-autopairs Wiki - Rules API**
   - URL: https://github.com/windwp/nvim-autopairs/wiki/Rules-API
   - Complete rules API reference
   - Condition functions (cond.none(), etc.)

4. **nvim-autopairs Issue #112**
   - URL: https://github.com/windwp/nvim-autopairs/issues/112
   - Discussion about disabling `map_cr` for custom completion integration
   - Example implementations with `autopairs_cr()`

5. **nvim-autopairs Issue #477**
   - URL: https://github.com/windwp/nvim-autopairs/issues/477
   - Feature request for blink.cmp support
   - Current status of blink.cmp integration
   - Community workarounds and patterns

6. **blink.cmp GitHub Repository**
   - URL: https://github.com/Saghen/blink.cmp
   - Completion plugin documentation
   - Keymap configuration reference

7. **blink.cmp Discussion #157**
   - URL: https://github.com/Saghen/blink.cmp/discussions/157
   - Community discussion about autopairs integration
   - Alternative approaches and solutions

### Key API Functions

1. **`npairs.autopairs_cr()`**
   - Primary function for handling CR with autopairs
   - Returns appropriate terminal codes based on context
   - Respects all rules, conditions, and treesitter integration

2. **`npairs.check_break_line_char()`**
   - Boolean detection function
   - Returns true if cursor is between pairs that should expand
   - Requires manual CR implementation when true

3. **`npairs.esc(str)`**
   - Terminal code helper function
   - Safely wraps terminal codes for keymap functions

4. **`blink.is_visible()`**
   - Checks if blink.cmp completion menu is visible
   - Used for conditional CR behavior

5. **`blink.accept()`**
   - Accepts currently selected completion item
   - Called when CR pressed with menu visible

## Implementation Status

- **Status**: Implementation Complete
- **Implementation Date**: 2025-11-04
- **Implementation Plan**: [../plans/001_i_am_having_trouble_configuring_nvim_to_properly_e_plan.md](../plans/001_i_am_having_trouble_configuring_nvim_to_properly_e_plan.md)

### Changes Made

This research identified the optimal pattern for conditional CR behavior that only expands between pairs without always creating newlines.

1. **Phase 1**: Implemented recommended `autopairs_cr()` API pattern
   - Used official API instead of manual `check_break_line_char()`
   - Automatic context detection and rule respect
   - File: `nvim/lua/neotex/plugins/tools/autopairs.lua`

2. **Phase 2**: Removed redundant CR mapping
   - Eliminated keymap conflict identified in section 3
   - Single source of truth for CR behavior
   - File: `nvim/lua/neotex/plugins/lsp/blink-cmp.lua`

3. **Phase 3**: Validated all conditional behaviors
   - CR only expands between pairs (primary requirement)
   - Normal CR preserved in other contexts
   - Completion acceptance works correctly

4. **Phase 4**: Documentation complete

### Anti-Patterns Avoided

- NOT using `map_cr = true` (would cause always-newline behavior)
- NOT using `<Ignore>` return value (causes extra newlines)
- NOT keeping duplicate CR mappings (causes conflicts)

### Key Research Findings Applied

- Completion check first, then autopairs logic (section 3)
- Return empty string after completion (section 4.1)
- Use official `autopairs_cr()` API (section 2.1)
- Conditional behavior via function keymap with `expr = true` (section 3)
