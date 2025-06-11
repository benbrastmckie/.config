# Blink.nvim LSP Configuration Refactor Plan

## Current State Analysis

### Current Dependencies (nvim-cmp ecosystem)
- **nvim-cmp**: Main completion engine
- **cmp-nvim-lsp**: LSP source for nvim-cmp
- **cmp-buffer**: Buffer text completion
- **cmp-path**: File path completion
- **cmp-cmdline**: Command line completion
- **cmp-git**: Git completion
- **cmp-spell**: Spell checking completion
- **cmp-vimtex**: VimTeX completion for LaTeX
- **LuaSnip**: Snippet engine
- **cmp_luasnip**: LuaSnip integration for nvim-cmp

### Current Configuration Structure
- `lspconfig.lua`: LSP server configuration with nvim-cmp capabilities
- `nvim-cmp.lua`: Extensive completion configuration (259 lines)
- `vimtex-cmp.lua`: VimTeX-specific completion setup
- `mason.nvim`: LSP server management

### Key Features in Current Setup
- Custom list handling for markdown files
- Extensive kind icons customization
- Performance optimizations (debounce, throttle)
- Complex Tab/Shift-Tab mappings for list integration
- Custom filtering for markdown list items
- Cmdline completion setup
- VimTeX integration for LaTeX

## Migration to Blink.nvim

### Phase 1: Core Installation & Basic Setup

#### 1.1 Dependencies
```lua
-- New dependencies to add
"saghen/blink.cmp"
"saghen/blink.compat"  -- Compatibility layer for nvim-cmp sources

-- Dependencies to remove
"hrsh7th/nvim-cmp"
"hrsh7th/cmp-nvim-lsp" 
"hrsh7th/cmp-buffer"
"hrsh7th/cmp-path"
"hrsh7th/cmp-cmdline"
"hrsh7th/cmp-git"
"hrsh7th/cmp-spell"
"saadparwaiz1/cmp_luasnip"
```

#### 1.2 Keep These Dependencies
```lua
-- Keep for LaTeX support via compatibility layer
"micangl/cmp-vimtex" -- Will work through blink.compat
"L3MON4D3/LuaSnip" -- Snippet engine (blink has native support)
```

### Phase 2: Configuration Migration

#### 2.1 Create New Blink Configuration File
**File**: `lua/neotex/plugins/lsp/blink-cmp.lua`

```lua
return {
  {
    "saghen/blink.compat",
    version = "2.*",
    lazy = true,
    opts = {
      debug = false, -- Set to true for debugging compatibility issues
    },
  },
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "saghen/blink.compat",
      "L3MON4D3/LuaSnip",
      "micangl/cmp-vimtex", -- VimTeX support via compatibility layer
    },
    opts = {
      -- Configuration will be detailed in Phase 3
    }
  }
}
```

#### 2.2 Update LSP Configuration
**File**: `lua/neotex/plugins/lsp/lspconfig.lua`

**Changes needed**:
- Remove `cmp-nvim-lsp` dependency
- Update capabilities configuration to use blink.cmp
- Replace line 57-60 capability enhancement

```lua
-- Old code (lines 57-60):
local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if ok then
  capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
end

-- New code:
local ok, blink = pcall(require, "blink.cmp")
if ok then
  capabilities = blink.get_lsp_capabilities(capabilities)
end
```

### Phase 3: Feature Mapping & Configuration

#### 3.1 Core Completion Sources
```lua
opts = {
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer', 'vimtex' },
    providers = {
      buffer = { 
        max_items = 8,
        keyword_length = 3, -- Match current nvim-cmp setting
      },
      snippets = { 
        opts = {
          friendly_snippets = false, -- We don't use this
          search_paths = { vim.fn.stdpath("config") .. "/snippets" },
        }
      },
      -- VimTeX integration via compatibility layer
      vimtex = {
        name = 'vimtex',
        module = 'blink.compat.source',
        opts = {
          -- Pass through cmp-vimtex configuration
          additional_information = {
            info_in_menu = true,
            info_in_window = true,
            info_max_length = 60,
            match_against_info = true,
            symbols_in_menu = true,
          },
          bibtex_parser = {
            enabled = true,
          },
          search = {
            browser = "xdg-open",
            default = "google_scholar",
            search_engines = {
              google_scholar = {
                name = "Google Scholar",
                get_url = function(query)
                  return string.format("https://scholar.google.com/scholar?hl=en&q=%s", query)
                end,
              },
            },
          },
        },
      },
    }
  }
}
```

#### 3.2 Appearance & Kind Icons
Map existing kind_icons (lines 23-56 in nvim-cmp.lua):
```lua
opts = {
  appearance = {
    kind_icons = {
      Function = "󰊕",
      Constructor = "",
      Text = "󰦨",
      Method = "",
      Field = "󰅪",
      Variable = "󱃮",
      Class = "",
      Interface = "",
      Module = "",
      Property = "",
      Unit = "",
      Value = "󰚯",
      Enum = "",
      Keyword = "",
      Snippet = "",
      Color = "󰌁",
      File = "",
      Reference = "",
      Folder = "",
      EnumMember = "",
      Constant = "󰀫",
      Struct = "",
      Event = "",
      Operator = "󰘧",
      TypeParameter = "",
    }
  }
}
```

#### 3.3 Keymap Migration
Map existing keymaps (lines 88-169 in nvim-cmp.lua):
```lua
opts = {
  keymap = {
    preset = 'default',
    ['<C-k>'] = { 'select_prev', 'fallback' },
    ['<C-j>'] = { 'select_next', 'fallback' },
    ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
    ['<CR>'] = { 'accept', 'fallback' },
    -- Note: Complex Tab/Shift-Tab markdown list handling will need 
    -- to be reimplemented or handled differently in blink.cmp
    ['<Tab>'] = { 'snippet_forward', 'select_next', 'fallback' },
    ['<S-Tab>'] = { 'snippet_backward', 'select_prev', 'fallback' },
  }
}
```

#### 3.4 Performance Settings
```lua
opts = {
  trigger = {
    completion = {
      keyword_length = 1,
      debounce = 500, -- Match current trigger_debounce_time
    }
  },
  -- Match current performance settings from nvim-cmp.lua
  performance = {
    trigger_debounce_time = 500,
    throttle = 550,
    fetching_timeout = 80,
  },
}
```

### Phase 4: Special Feature Handling

#### 4.1 Markdown List Integration
**Challenge**: Current setup has complex markdown list handling (lines 67-82, 98-169)

**Solution Options**:
1. **Custom enabled function** for markdown files:
```lua
opts = {
  enabled = function()
    -- Check if we're in a markdown file and in a list item
    if vim.bo.filetype == "markdown" then
      local line = vim.fn.getline(".")
      for _, pattern in ipairs({"-", "*", "+", "%d%."}) do
        if line:match("^%s*" .. pattern .. "%s") then
          if _G._prevent_cmp_menu == true then
            return false
          end
        end
      end
    end
    return true
  end,
}
```

2. **Simplified approach**: Remove complex markdown handling initially and add back if needed

#### 4.2 VimTeX Integration ✅ SOLVED
**Solution**: Use blink.compat compatibility layer

**Implementation**: Already configured in Phase 3.1 with full cmp-vimtex functionality:
- Symbol completion
- Bibliography parsing  
- Information display
- Search integration

#### 4.3 Cmdline Completion
**Solution**: Blink.cmp has built-in cmdline support:
```lua
opts = {
  sources = {
    cmdline = function()
      local type = vim.fn.getcmdtype()
      if type == '/' or type == '?' then
        return { 'buffer' }
      elseif type == ':' then
        return { 'cmdline', 'path' }
      end
      return {}
    end,
  }
}
```

### Phase 5: Implementation Steps

#### 5.1 Preparation
1. **Backup current configuration**
2. **Test current setup thoroughly** to document behavior
3. **Review blink.cmp documentation** for latest features
4. **Check VimTeX compatibility** options

#### 5.2 Implementation Order
1. **Create blink-cmp.lua** with basic configuration
2. **Update lspconfig.lua** capability handling
3. **Disable nvim-cmp.lua** (rename to .lua.bak)
4. **Test basic LSP completion**
5. **Add appearance customization**
6. **Implement keymaps**
7. **Add performance settings**
8. **Handle special features** (markdown, VimTeX)
9. **Remove old dependencies** from package manager

#### 5.3 Testing Checklist
- [ ] Basic LSP completion works
- [ ] Snippet expansion works  
- [ ] File path completion works
- [ ] Buffer completion works
- [ ] Cmdline completion works
- [ ] **VimTeX completion works via blink.compat**
  - [ ] LaTeX symbol completion
  - [ ] Bibliography references (\cite{})
  - [ ] Environment completion (\begin{})
  - [ ] Math symbol completion
  - [ ] Information display in menu/window
  - [ ] Google Scholar search functionality
- [ ] Markdown list behavior (may need adjustment)
- [ ] Performance is acceptable
- [ ] All custom keymaps work
- [ ] Visual appearance matches expectations

### Phase 6: Cleanup

#### 6.1 Files to Remove/Archive
- `lua/neotex/plugins/lsp/nvim-cmp.lua` → move to deprecated
- `lua/neotex/plugins/lsp/vimtex-cmp.lua` → **REMOVE** (configuration moved to blink-cmp.lua)

#### 6.2 Dependencies to Remove
Update lazy-lock.json will automatically update when these are removed:
- cmp-buffer
- cmp-cmdline  
- cmp-git
- cmp-nvim-lsp
- cmp-path
- cmp-spell
- cmp_luasnip
- nvim-cmp

#### 6.3 Dependencies to Keep/Add
- **Keep**: LuaSnip (blink.cmp has native support)
- **Keep**: cmp-vimtex (used via blink.compat)
- **Add**: blink.compat (compatibility layer)
- **Add**: blink.cmp (main completion engine)

## Risk Assessment

### High Risk ✅ MITIGATED
- ~~**VimTeX integration**: May lose LaTeX completion functionality~~ → **SOLVED** via blink.compat
- **Markdown list behavior**: Complex custom logic may not translate
- **Autolist integration**: Current Tab/Shift-Tab behavior is intricate

### Medium Risk  
- **Snippet integration**: LuaSnip should work but needs testing
- **Performance impact**: Should improve but needs verification
- **Cmdline completion**: Feature parity needs validation
- **blink.compat reliability**: Dependency on third-party compatibility layer

### Low Risk
- **Basic LSP completion**: Should work out of the box
- **File/buffer completion**: Standard features in blink.cmp
- **Appearance**: Highly customizable

## Migration Timeline

### Week 1: Research & Preparation
- [ ] Study blink.cmp documentation thoroughly
- [ ] Test VimTeX compatibility options  
- [ ] Document current behavior precisely

### Week 2: Core Implementation
- [ ] Implement basic blink.cmp setup
- [ ] Migrate LSP configuration
- [ ] Test core functionality

### Week 3: Feature Migration
- [ ] Implement appearance customization
- [ ] Add performance settings
- [ ] Handle special features

### Week 4: Testing & Refinement
- [ ] Comprehensive testing
- [ ] Performance comparison
- [ ] Final adjustments and cleanup

## Success Criteria

1. **Functional parity**: All current completion sources work
2. **Performance improvement**: Faster completion responses
3. **Maintained UX**: No degradation in user experience
4. **Code simplification**: Reduced configuration complexity
5. **LaTeX support**: VimTeX completion preserved
6. **Markdown behavior**: List handling works as expected

## Rollback Plan

If migration fails:
1. Restore `nvim-cmp.lua` from backup
2. Re-enable nvim-cmp in plugin manager
3. Revert lspconfig changes
4. Remove blink.cmp configuration

Files to backup before starting:
- `lua/neotex/plugins/lsp/lspconfig.lua`
- `lua/neotex/plugins/lsp/nvim-cmp.lua`
- `lua/neotex/plugins/lsp/vimtex-cmp.lua`
- `lazy-lock.json`

## Complete Configuration Example

### Final blink-cmp.lua Configuration
```lua
return {
  {
    "saghen/blink.compat",
    version = "2.*",
    lazy = true,
    opts = {
      debug = false,
    },
  },
  {
    "saghen/blink.cmp",
    version = "1.*", 
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "saghen/blink.compat",
      "L3MON4D3/LuaSnip",
      "micangl/cmp-vimtex",
    },
    opts = {
      keymap = {
        preset = 'default',
        ['<C-k>'] = { 'select_prev', 'fallback' },
        ['<C-j>'] = { 'select_next', 'fallback' },
        ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<Tab>'] = { 'snippet_forward', 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'snippet_backward', 'select_prev', 'fallback' },
      },
      
      appearance = {
        kind_icons = {
          Function = "󰊕", Constructor = "", Text = "󰦨", Method = "",
          Field = "󰅪", Variable = "󱃮", Class = "", Interface = "",
          Module = "", Property = "", Unit = "", Value = "󰚯",
          Enum = "", Keyword = "", Snippet = "", Color = "󰌁",
          File = "", Reference = "", Folder = "", EnumMember = "",
          Constant = "󰀫", Struct = "", Event = "", Operator = "󰘧",
          TypeParameter = "",
        }
      },
      
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer', 'vimtex' },
        cmdline = function()
          local type = vim.fn.getcmdtype()
          if type == '/' or type == '?' then
            return { 'buffer' }
          elseif type == ':' then
            return { 'cmdline', 'path' }
          end
          return {}
        end,
        providers = {
          buffer = { 
            max_items = 8,
            keyword_length = 3,
          },
          snippets = { 
            opts = {
              friendly_snippets = false,
              search_paths = { vim.fn.stdpath("config") .. "/snippets" },
            }
          },
          vimtex = {
            name = 'vimtex',
            module = 'blink.compat.source',
            opts = {
              additional_information = {
                info_in_menu = true,
                info_in_window = true,
                info_max_length = 60,
                match_against_info = true,
                symbols_in_menu = true,
              },
              bibtex_parser = { enabled = true },
              search = {
                browser = "xdg-open",
                default = "google_scholar",
                search_engines = {
                  google_scholar = {
                    name = "Google Scholar",
                    get_url = function(query)
                      return string.format("https://scholar.google.com/scholar?hl=en&q=%s", query)
                    end,
                  },
                },
              },
            },
          },
        }
      },
      
      trigger = {
        completion = {
          keyword_length = 1,
          debounce = 500,
        }
      },
      
      performance = {
        trigger_debounce_time = 500,
        throttle = 550,
        fetching_timeout = 80,
      },
    }
  }
}
```

## Documentation References

- Main repository: https://github.com/Saghen/blink.nvim
- blink.cmp specific: https://github.com/Saghen/blink.cmp  
- blink.compat: https://github.com/Saghen/blink.compat
- Documentation site: https://cmp.saghen.dev
- VimTeX research: lua/neotex/plugins/lsp/specs/vimtex_blink.md
