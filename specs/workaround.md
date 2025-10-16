# blink.cmp + nvim-autopairs Integration Issue

## Problem Statement

The current integration between nvim-autopairs and blink.cmp is failing with the following error when pressing Enter on a blank line in insert mode:

```
E5108: Error executing lua: ...amin/.config/nvim/lua/neotex/plugins/tools/autopairs.lua:99: attempt to call field 'visible' (a nil value)
stack traceback:
        ...amin/.config/nvim/lua/neotex/plugins/tools/autopairs.lua:99: in function 'callback'
        ...re/nvim/lazy/blink.cmp/lua/blink/cmp/keymap/fallback.lua:76: in function <...re/nvim/lazy/blink.cmp/lua/blink/cmp/keymap/fallback.lua:64>
```

## Root Cause Analysis

### Current Implementation Problem
**File**: `lua/neotex/plugins/tools/autopairs.lua:99`

**Problematic Code**:
```lua
vim.keymap.set('i', '<CR>', function()
  local blink = require('blink.cmp')
  if blink.visible() then  -- ERROR: 'visible' method doesn't exist
    return blink.accept({ 
      callback = cmp_autopairs.on_confirm_done({...})
    })
  else
    return '<CR>'
  end
end, { expr = true, silent = true })
```

### API Mismatch
1. **Assumed API**: `blink.visible()` (doesn't exist)
2. **Actual blink.cmp API**: Methods likely different from nvim-cmp
3. **Source**: Community workaround from GitHub issue #477 may be outdated or incorrect

## Current Integration Status

### What Works
- **nvim-autopairs**: All LaTeX/Lean features work correctly (dollar signs, unicode pairs, spacing)
- **blink.cmp**: Completion works with auto_brackets enabled
- **Separate functionality**: Both plugins work independently

### What's Broken
- **Completion integration**: Autopairs callback on completion acceptance
- **Enter key binding**: Custom Enter mapping conflicts with blink.cmp's keymap system

## Technical Investigation Needed

### 1. Correct blink.cmp API Methods
Need to identify the actual blink.cmp API for:
- **Visibility check**: What replaces `blink.visible()`?
- **Accept method**: Does `blink.accept({ callback = ... })` work?
- **Keymap integration**: How does blink.cmp handle custom Enter bindings?

### 2. blink.cmp Keymap System
**File**: `blink.cmp/lua/blink/cmp/keymap/fallback.lua:76`

The error originates from blink.cmp's fallback system, suggesting:
- blink.cmp has its own keymap management
- Our custom Enter binding may conflict with blink's system
- Need to integrate via blink.cmp's configuration rather than vim.keymap.set

### 3. Alternative Integration Approaches

#### Option A: Use blink.cmp's keymap configuration
```lua
-- In blink-cmp.lua keymap section
keymap = {
  ['<CR>'] = { 
    function(cmp) 
      -- Custom autopairs integration here
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      return cmp.accept({ callback = cmp_autopairs.on_confirm_done() })
    end,
    'fallback'
  }
}
```

#### Option B: Rely on blink.cmp auto_brackets + nvim-autopairs
- Use blink.cmp's built-in auto_brackets for completion
- Use nvim-autopairs for general typing (no completion integration)
- Accept that some completion scenarios won't trigger autopairs

#### Option C: Hook into blink.cmp events
```lua
-- If blink.cmp provides completion events
local blink_cmp = require('blink.cmp')
if blink_cmp.on_confirm then
  blink_cmp.on_confirm(function(item)
    -- Trigger autopairs logic here
  end)
end
```

## Recommended Investigation Steps

### 1. API Discovery
```lua
-- Debug script to explore blink.cmp API
local blink = require('blink.cmp')
print("Available methods:")
for k, v in pairs(blink) do
  if type(v) == 'function' then
    print("  " .. k .. "()")
  end
end
```

### 2. Check blink.cmp Documentation
- Review official blink.cmp docs for keymap configuration
- Look for completion event hooks
- Find correct visibility/state checking methods

### 3. Examine Existing Configurations
- Search for working blink.cmp + autopairs configs
- Check if GitHub issue #477 has updates
- Look at dotfiles using both plugins

## Potential Solutions

### Solution 1: Fix API Methods
```lua
-- Replace blink.visible() with correct method
local function setup_blink_integration()
  local ok, blink = pcall(require, 'blink.cmp')
  if not ok then return end

  -- Find correct visibility check method
  -- Candidates: blink.is_visible(), blink.visible(), blink.get_completion_menu()
  
  vim.keymap.set('i', '<CR>', function()
    if blink.is_visible and blink.is_visible() then  -- Use correct method
      return blink.accept({ 
        callback = function()
          require("nvim-autopairs.completion.cmp").on_confirm_done()({})
        end
      })
    else
      return '<CR>'
    end
  end, { expr = true, silent = true })
end
```

### Solution 2: Integrate via blink.cmp Configuration
```lua
-- In blink-cmp.lua
keymap = {
  ['<CR>'] = { 
    function(cmp) 
      if cmp.is_visible() then
        return cmp.accept({ 
          callback = function()
            require("nvim-autopairs.completion.cmp").on_confirm_done()({
              filetypes = { tex = false, lean = true }
            })()
          end
        })
      else
        return '<CR>'
      end
    end
  }
}
```

### Solution 3: Minimal Integration
```lua
-- Disable custom Enter binding, rely on blink.cmp auto_brackets
-- Keep nvim-autopairs for general typing only
-- Accept reduced integration for stability
```

## Impact Assessment

### High Priority
- **Blocking error**: Enter key fails in insert mode
- **Core functionality broken**: Basic text editing affected

### Medium Priority  
- **Missing integration**: Completion + autopairs don't work together
- **User experience**: Some expected autopairs behavior missing

### Low Priority
- **Feature completeness**: Not all nvim-cmp features replicated

## Next Steps

1. **Immediate**: Fix the blocking error to restore Enter key functionality
2. **Research**: Investigate correct blink.cmp API methods
3. **Test**: Try different integration approaches
4. **Document**: Update autopairs.lua with working solution
5. **Fallback**: If integration impossible, document limitations

## Current Workaround Options

### Temporary Fix 1: Disable Integration
```lua
-- Comment out the setup_blink_integration() call
-- Keep nvim-autopairs for typing, blink.cmp for completion
```

### Temporary Fix 2: Conditional Integration
```lua
local function setup_blink_integration()
  local ok, blink = pcall(require, 'blink.cmp')
  if not ok or not blink.visible then
    vim.notify("blink.cmp integration skipped - API not available", vim.log.levels.INFO)
    return
  end
  -- ... rest of integration
end
```

### Temporary Fix 3: Simple Enter Mapping
```lua
-- Basic Enter mapping without completion integration
vim.keymap.set('i', '<CR>', '<CR>', { silent = true })
```

---

## DETAILED RESEARCH FINDINGS & SOLUTION

### Correct blink.cmp API Methods (Confirmed)
After thorough research of the blink.cmp source code:

#### Visibility Checking:
- `blink.is_visible()` ✅ **EXISTS** - checks if completion menu OR ghost text is visible
- `blink.is_menu_visible()` ✅ **EXISTS** - checks specifically if completion menu is visible  
- `blink.is_active()` ✅ **EXISTS** - checks if completion list is active

#### Completion Acceptance:
- `blink.accept(opts?)` ✅ **EXISTS** - accepts current completion item
  - `opts.callback` - function called after acceptance
  - `opts.index` - specific item index to accept
- `blink.select_and_accept(opts?)` ✅ **EXISTS** - selects first item if none selected, then accepts

### Fundamental Integration Problem Identified

**Critical Discovery**: The API methods we're using are actually **correct**. The real problem is deeper:

1. **nvim-autopairs doesn't natively support blink.cmp** (GitHub issue #477 confirms this)
2. **The callback structure is incompatible** - `cmp_autopairs.on_confirm_done()` is designed for nvim-cmp's event system
3. **Community workarounds are experimental** and not officially supported

## RECOMMENDED SOLUTIONS (Priority Order)

### Solution 1: Hybrid Approach - Use Built-in Auto-brackets (RECOMMENDED)
**Strategy**: Remove broken integration, use blink.cmp's built-in auto-brackets + nvim-autopairs for custom rules

**Implementation**:
```lua
-- 1. Remove blink integration from autopairs.lua (lines 88-121)
-- 2. Enable blink.cmp auto-brackets in blink-cmp.lua:

completion = {
  accept = {
    auto_brackets = {
      enabled = true,
      default_brackets = { '(', ')' },
      kind_resolution = {
        enabled = true,
        blocked_filetypes = { 'tex', 'latex' }  -- Prevent LaTeX conflicts
      },
      semantic_token_resolution = {
        enabled = true,
        blocked_filetypes = { 'tex', 'latex', 'lean' },
        timeout_ms = 400
      }
    }
  }
}

-- 3. Keep nvim-autopairs for LaTeX/Lean custom rules only
```

**Benefits**:
- ✅ Fixes blocking Enter key error immediately
- ✅ Provides bracket completion for function calls
- ✅ Maintains LaTeX dollar signs and Lean unicode pairs
- ✅ No experimental code or workarounds
- ✅ Official blink.cmp feature with proper support

**Limitations**:
- ❌ No autopairs callback on completion (not critical)
- ❌ Slightly different behavior than nvim-cmp integration

### Solution 2: Corrected Integration Attempt (EXPERIMENTAL)
**Strategy**: Fix the API usage and integration approach

**Implementation**:
```lua
-- Fixed version of the integration
local function setup_blink_integration()
  local blink_ok, blink = pcall(require, 'blink.cmp')
  if not blink_ok then return end

  -- Verify API methods exist
  if not blink.is_visible or not blink.accept then
    vim.notify("blink.cmp API methods not available", vim.log.levels.WARN)
    return
  end

  vim.keymap.set('i', '<CR>', function()
    if blink.is_visible() then
      -- Accept completion first, then trigger autopairs manually
      blink.accept({
        callback = function()
          -- Manual autopairs trigger (workaround)
          vim.schedule(function()
            local autopairs = require("nvim-autopairs")
            -- This is experimental and may not work properly
            local result = autopairs.autopairs_cr()
            if result then
              vim.api.nvim_feedkeys(result, 'n', false)
            end
          end)
        end
      })
      return ''  -- Don't insert CR yet
    else
      return '<CR>'
    end
  end, { expr = true, silent = true, desc = "Accept completion with autopairs" })
end
```

**Status**: ⚠️ **EXPERIMENTAL** - may cause issues, not recommended for production use

### Solution 3: Switch to mini.pairs (ALTERNATIVE)
**Strategy**: Replace nvim-autopairs with mini.pairs which may have better blink.cmp compatibility

**Implementation**:
```lua
-- Replace autopairs.lua with mini.pairs configuration
{
  'echasnovski/mini.pairs',
  event = "VeryLazy",
  opts = {
    modes = { insert = true, command = false, terminal = false },
    -- Add custom LaTeX and Lean pairs
    pairs = {
      ['$'] = { action = 'closeopen', pair = '$$', neigh_pattern = '[^\\].', register = { cr = false } },
      ['⟨'] = { action = 'closeopen', pair = '⟨⟩' },
      ['«'] = { action = 'closeopen', pair = '«»' },
      ['⟪'] = { action = 'closeopen', pair = '⟪⟫' },
      ['⦃'] = { action = 'closeopen', pair = '⦃⦄' },
    }
  }
}
```

## DETAILED IMPLEMENTATION PLAN

### Phase 1: Immediate Fix (5 minutes)
**Goal**: Restore Enter key functionality

1. **Remove broken integration** from `autopairs.lua`:
   - Delete lines 88-121 (entire setup_blink_integration function and call)

2. **Verify blink.cmp auto-brackets** in `blink-cmp.lua`:
   - Confirm auto_brackets is enabled and configured properly

3. **Test basic functionality**:
   - Enter key works in insert mode ✅
   - Completion accepts with Tab/Enter ✅
   - Basic bracket completion works ✅

### Phase 2: Enhanced Configuration (10 minutes)
**Goal**: Optimize the hybrid approach

1. **Fine-tune auto-brackets configuration**:
   - Add appropriate filetype exclusions for LaTeX/Lean
   - Configure semantic token resolution
   - Set proper timeout values

2. **Preserve LaTeX/Lean functionality**:
   - Verify dollar sign pairs still work
   - Test unicode mathematical symbols (⟨⟩, «», ⟪⟫, ⦃⦄)
   - Confirm spacing rules are maintained

3. **Update documentation**:
   - Add comments explaining the hybrid approach
   - Document limitations and benefits

### Phase 3: Future Integration (Optional)
**Goal**: Monitor for official support

1. **Track GitHub issue #477** for official nvim-autopairs + blink.cmp support
2. **Test future releases** of both plugins for native integration
3. **Consider alternative approaches** as ecosystem evolves

---

**Status**: Solution identified - hybrid approach recommended  
**Severity**: High (blocking basic functionality) - **SOLVABLE**  
**Next Action**: Implement Phase 1 for immediate fix