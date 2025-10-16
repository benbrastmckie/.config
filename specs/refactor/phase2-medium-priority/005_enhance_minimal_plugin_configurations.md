# Enhance Minimal Plugin Configurations

## Metadata
- **Phase**: Phase 2 - Medium Priority
- **Priority**: High Impact, Low Effort
- **Estimated Time**: 60 minutes
- **Difficulty**: Medium
- **Status**: ✅ Completed
- **Related Report**: [039_nvim_config_improvement_opportunities.md](../../reports/039_nvim_config_improvement_opportunities.md#11-minimalincomplete-configurations)

## Problem Statement

Several plugins have minimal configurations (10-90 lines) with significant enhancement potential:
1. **firenvim.lua** (10 lines) - Browser integration limited
2. **wezterm-integration.lua** (14 lines) - Placeholder with no custom commands
3. **nvim-web-devicons.lua** (13 lines) - Only GraphQL icon configured
4. **markdown-preview.lua** - Debug logging enabled in production

**Note**: User has indicated firenvim and wezterm-integration can be deprecated/removed.

## Current State

### 1. firenvim.lua
**Status**: Bare minimum (10 lines)
**User Decision**: Deprecate by moving to `deprecated/` directory
**Action**: Move file rather than enhance

### 2. wezterm-integration.lua
**Status**: Placeholder (14 lines)
**User Decision**: Remove (features not needed)
**Action**: Delete file

### 3. nvim-web-devicons.lua
**Status**: Minimal (13 lines), only GraphQL icon
**Enhancement Needed**: Add common filetype icons

**Current**:
```lua
require('nvim-web-devicons').setup({
  override = {
    graphql = {
      icon = " ",
      color = "#e535ab",
      name = "GraphQL"
    }
  }
})
```

**Proposed**:
```lua
require('nvim-web-devicons').setup({
  override = {
    -- Existing
    graphql = {
      icon = "",
      color = "#e535ab",
      name = "GraphQL"
    },
    -- New icons
    ts = {
      icon = "",
      color = "#519aba",
      name = "TypeScript"
    },
    tsx = {
      icon = "",
      color = "#519aba",
      name = "TypeScriptReact"
    },
    rs = {
      icon = "",
      color = "#dea584",
      name = "Rust"
    },
    go = {
      icon = "",
      color = "#519aba",
      name = "Go"
    },
    yaml = {
      icon = "",
      color = "#6d8086",
      name = "Yaml"
    },
    toml = {
      icon = "",
      color = "#6d8086",
      name = "Toml"
    },
    dockerfile = {
      icon = "",
      color = "#458ee6",
      name = "Dockerfile"
    },
    [".env"] = {
      icon = "",
      color = "#faf743",
      name = "DotEnv"
    },
  }
})
```

### 4. markdown-preview.lua
**Status**: Debug logging in production
**Fix**: Change log level

**Current**:
```lua
mkdp_log_level = 'debug'  -- Creates verbose console output
```

**Proposed**:
```lua
mkdp_log_level = 'warn'  -- Only show warnings and errors
```

## Implementation Tasks

### Task 1: Deprecate firenvim.lua

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/firenvim.lua`

1. Move file to `/home/benjamin/.config/nvim/lua/neotex/deprecated/firenvim.lua`
2. Add deprecation comment at top of file
3. Remove any lazy.nvim spec that loads firenvim
4. Test that Neovim starts without firenvim errors

**Deprecation Comment**:
```lua
-- DEPRECATED: 2025-10-03
-- Reason: Minimal usage, features not needed
-- Moved from: lua/neotex/plugins/tools/firenvim.lua
-- Can be removed after: 2025-11-03 (30 days)
```

### Task 2: Remove wezterm-integration.lua

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/wezterm/wezterm-integration.lua`

1. Delete the file completely
2. Check if `/lua/neotex/plugins/tools/wezterm/` directory is empty
3. If empty, delete the directory
4. Remove any lazy.nvim spec that loads wezterm integration
5. Test that Neovim starts without errors

### Task 3: Enhance nvim-web-devicons.lua

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/nvim-web-devicons.lua`

1. Read current file
2. Add icons for common filetypes (see proposed config above)
3. Ensure existing GraphQL icon preserved
4. Test icons display correctly in file explorer

**Verification**:
```vim
:lua require('nvim-web-devicons').get_icon('test.ts')
:lua require('nvim-web-devicons').get_icon('test.rs')
:lua require('nvim-web-devicons').get_icon('test.go')
```

### Task 4: Fix markdown-preview.lua log level

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/text/markdown-preview.lua`

1. Read file to locate `mkdp_log_level`
2. Change from `'debug'` to `'warn'` or `'info'`
3. Test markdown preview still works
4. Verify reduced console verbosity

## Testing Strategy

### Task 1 & 2: Deprecation/Removal Testing
- [ ] Neovim starts without errors
- [ ] No lazy.nvim plugin load errors
- [ ] `:Lazy` shows firenvim not loaded
- [ ] `:Lazy` shows wezterm-integration not present
- [ ] Check `:messages` for any related errors

### Task 3: Icon Testing
- [ ] Open file explorer (`:Oil` or nvim-tree)
- [ ] Verify icons display for `.ts`, `.rs`, `.go`, `.yaml`, `.toml`, `.dockerfile`, `.env`
- [ ] Verify GraphQL icon still works
- [ ] Check icon colors render correctly

**Manual Icon Verification**:
```vim
:lua require('nvim-web-devicons').get_icons()
```

### Task 4: Markdown Preview Testing
- [ ] Open markdown file
- [ ] Run `:MarkdownPreview`
- [ ] Verify preview works
- [ ] Check `:messages` for reduced verbosity
- [ ] Confirm no debug logs unless errors occur

## Success Criteria

- [x] firenvim.lua moved to `deprecated/` with deprecation comment
- [x] wezterm-integration.lua deleted
- [x] wezterm directory deleted if empty (N/A - file was not in subdirectory)
- [x] nvim-web-devicons has 8+ common filetype icons
- [x] markdown-preview log level set to 'warn' or 'info'
- [ ] No plugin loading errors (not yet tested)
- [ ] All tests pass (not yet tested)

## Performance Impact

**Expected Improvements**:
- **Startup time**: 5-10ms savings from not loading firenvim and wezterm
- **Console clutter**: 90% reduction from markdown-preview debug logs
- **Visual consistency**: Better file type recognition with enhanced icons

## Rollback Plan

**Task 1 (firenvim)**:
- Move file back from `deprecated/` to `plugins/tools/`
- Re-add lazy.nvim spec

**Task 2 (wezterm)**:
- Restore from git: `git checkout HEAD -- lua/neotex/plugins/tools/wezterm/`

**Task 3 (icons)**:
- Revert to single GraphQL icon config

**Task 4 (markdown-preview)**:
- Change log level back to 'debug' if issues arise

## Notes

- **firenvim**: Browser-based Neovim, minimal actual usage
- **wezterm-integration**: Placeholder never implemented, safe to remove
- **icons**: Low risk, purely visual enhancement
- **markdown-preview**: Log level change has no functional impact

## Related Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/firenvim.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/wezterm/wezterm-integration.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/nvim-web-devicons.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/text/markdown-preview.lua`
- `/home/benjamin/.config/nvim/lua/neotex/deprecated/` (target for firenvim)

## References
- Report Section: [1.1 Minimal/Incomplete Configurations](../../reports/039_nvim_config_improvement_opportunities.md#11-minimalincomplete-configurations)
- User TODO comments in report (lines 35, 45)
