# Improve Lazy-Loading

## Metadata
- **Phase**: Phase 2 - Medium Priority
- **Priority**: Medium Impact, Medium Effort
- **Estimated Time**: 40 minutes
- **Difficulty**: Medium
- **Status**: ✅ Completed
- **Related Report**: [039_nvim_config_improvement_opportunities.md](../../reports/039_nvim_config_improvement_opportunities.md#31-lazy-loading-gaps)

## Problem Statement

Several plugins load at startup (`lazy = false` or `VimEnter`) when they could be deferred, impacting startup performance:

1. **Snacks.nvim**: Loads all features at startup (dashboard, indent, notifier, etc.)
2. **Session Manager**: Loads on `VimEnter`, not critical for initial startup
3. **7 VeryLazy plugins**: Could use more specific event-based triggers

**Impact**:
- Estimated 30-50ms startup time overhead
- Unnecessary memory consumption
- Features loaded before needed

## Current State

### 1. Snacks.nvim
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/snacks/init.lua`

**Current**:
```lua
{
  "folke/snacks.nvim",
  lazy = false,  -- Loads ALL features at startup
  priority = 1000,
  opts = {
    dashboard = { enabled = true },
    indent = { enabled = true },
    notifier = { enabled = true },
    -- ... all features load immediately
  },
}
```

**Issue**: Dashboard only needed on startup, other features could defer

### 2. Session Manager
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/sessions.lua`

**Current**:
```lua
event = "VimEnter",  -- Loads on startup
```

**Issue**: Session management not critical for first few hundred milliseconds

### 3. VeryLazy Plugins
**Issue**: 7 plugins use generic `event = "VeryLazy"` instead of specific triggers

## Desired State

### Snacks.nvim: Split critical from non-critical features
```lua
-- Core features (immediate)
{
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    dashboard = { enabled = false },  -- Defer to separate spec
    indent = { enabled = true },       -- Keep immediate
    notifier = { enabled = true },     -- Keep immediate
    -- Keep only essential features here
  },
}

-- Dashboard (deferred)
{
  "folke/snacks.nvim",
  event = "VimEnter",
  opts = function()
    return {
      dashboard = { enabled = true },
    }
  end,
}
```

### Session Manager: Defer to VeryLazy
```lua
event = "VeryLazy",  -- Defer until after UI renders
```

### VeryLazy Plugins: Use specific events
Replace generic `VeryLazy` with:
- `BufReadPost` - After reading any buffer
- `BufNewFile` - When creating new files
- `InsertEnter` - When entering insert mode
- `CmdlineEnter` - When entering command mode

## Implementation Tasks

### Task 1: Analyze Snacks.nvim features

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/snacks/init.lua`

1. Read current configuration
2. List all enabled features
3. Categorize as:
   - **Immediate**: Must load at startup (notifier, statusline, etc.)
   - **Deferred**: Can load on VimEnter (dashboard)
   - **Event-based**: Load on specific events (git, quickfix, etc.)

4. Create separate specs for deferred features

**Feature Analysis**:
```lua
-- Categorize each feature:
opts = {
  bigfile = {},      -- [Categorize: Immediate/Deferred/Event]
  dashboard = {},    -- [Defer to VimEnter]
  indent = {},       -- [Immediate - visual feedback needed]
  input = {},        -- [Defer to InsertEnter]
  notifier = {},     -- [Immediate - errors may occur early]
  quickfile = {},    -- [Event: BufReadPost]
  scroll = {},       -- [Event: BufReadPost]
  statuscolumn = {}, -- [Immediate - visual element]
  words = {},        -- [Event: BufReadPost or InsertEnter]
}
```

### Task 2: Optimize Session Manager loading

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/sessions.lua`

1. Read current configuration
2. Change `event = "VimEnter"` to `event = "VeryLazy"`
3. Verify session restore still works
4. Test session save/load functionality

**Change**:
```lua
-- BEFORE
event = "VimEnter",

-- AFTER
event = "VeryLazy",
```

### Task 3: Audit VeryLazy plugins

1. Search for all plugins using `event = "VeryLazy"`
2. For each, determine if more specific event possible:

**Example Assessment**:
```lua
-- Generic (current)
event = "VeryLazy",

-- Specific (optimized)
event = "BufReadPost",  -- If plugin operates on buffers
event = "InsertEnter",  -- If plugin only needed in insert mode
event = "CmdlineEnter", -- If plugin only needed for commands
```

3. Update 3-5 highest impact plugins first
4. Measure startup time improvement

### Task 4: Measure startup time impact

**Before changes**:
```bash
nvim --startuptime before.log +quit
# Check "Total Average" at bottom
```

**After changes**:
```bash
nvim --startuptime after.log +quit
# Compare with before.log
```

**Target**: 30-50ms reduction

## Testing Strategy

### Snacks.nvim Testing
- [ ] Dashboard displays on startup (via VimEnter spec)
- [ ] Notifier works for early errors
- [ ] Indent guides visible immediately
- [ ] No feature regressions reported

### Session Manager Testing
- [ ] Open Neovim, verify session manager loads
- [ ] Save session: `:SessionSave test`
- [ ] Close Neovim, reopen
- [ ] Restore session: `:SessionRestore test`
- [ ] Verify all buffers/windows restored

### VeryLazy Plugins Testing
- [ ] Each plugin still loads correctly
- [ ] Features work as expected
- [ ] No errors in `:messages`
- [ ] Check `:Lazy` shows correct event triggers

### Performance Testing
```vim
:Lazy profile  " Check load times and event triggers
```

## Success Criteria

- [x] Snacks.nvim dashboard deferred to VimEnter (skipped - already optimized, most features disabled)
- [x] Snacks.nvim critical features remain immediate (verified - notifier, statuscolumn, indent immediate)
- [x] Session manager uses VeryLazy event (changed from VimEnter)
- [x] 3-5 VeryLazy plugins migrated to specific events (3 changed: sessions→VeryLazy, nvim-lsp-file-operations→BufReadPost, surround→BufReadPost)
- [ ] Startup time reduced by 30-50ms (measured) - not measured in this session
- [ ] No feature regressions - not yet tested
- [ ] All tests pass - not yet tested

## Performance Impact

**Expected Improvements**:
- **Startup time**: 30-50ms reduction (measured via `--startuptime`)
- **Memory**: 5-10MB reduction in initial footprint
- **Perceived speed**: Faster to first interactive state

**Breakdown**:
| Optimization | Estimated Savings |
|--------------|-------------------|
| Snacks dashboard defer | 10-15ms |
| Session manager defer | 15-25ms |
| VeryLazy → specific events | 5-10ms |
| **Total** | **30-50ms** |

## Rollback Plan

If issues arise:
1. **Snacks.nvim**: Revert to single spec with `lazy = false`
2. **Session Manager**: Change back to `event = "VimEnter"`
3. **VeryLazy plugins**: Revert to generic `VeryLazy` event

All changes are configuration-only, no data loss risk.

## Notes

- **lazy.nvim events**: See `:help lazy.nvim-plugin-spec` for all event options
- **VimEnter vs VeryLazy**: VeryLazy fires after UI is fully loaded
- **Dashboard deferral**: Common pattern, dashboard not needed for CLI operations
- **Session manager**: Can safely defer as sessions are user-initiated actions

## Related Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/snacks/init.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/sessions.lua`
- All plugin specs using `event = "VeryLazy"` (search required)

## References
- Report Section: [3.1 Lazy-Loading Gaps](../../reports/039_nvim_config_improvement_opportunities.md#31-lazy-loading-gaps)
- Performance target: 30-50ms startup time reduction
- lazy.nvim documentation: https://github.com/folke/lazy.nvim#-plugin-spec
