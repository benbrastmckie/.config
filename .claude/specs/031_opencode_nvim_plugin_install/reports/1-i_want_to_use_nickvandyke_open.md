# Research Report: Switching from sudo-tee/opencode.nvim to NickvanDyke/opencode.nvim

**Date**: 2025-12-10
**Research Complexity**: 2
**Workflow Type**: research-and-revise
**Related Plan**: /home/benjamin/.config/.claude/specs/031_opencode_nvim_plugin_install/plans/001-opencode-nvim-plugin-install-plan.md

---

## Executive Summary

This research report analyzes the differences between sudo-tee/opencode.nvim and NickvanDyke/opencode.nvim to inform plan revision. The existing plan recommends sudo-tee variant but the user wants to use NickvanDyke variant instead.

**Key Findings**:
1. **Architecture**: NickvanDyke embeds opencode's native TUI within Neovim; sudo-tee creates a custom chat frontend
2. **Maturity**: NickvanDyke is more established (804 stars) with comprehensive documentation and health checks
3. **Dependencies**: Different core dependencies (snacks.nvim vs render-markdown.nvim)
4. **Configuration**: NickvanDyke uses `vim.g.opencode_opts` table; sudo-tee uses `setup()` function
5. **Keymaps**: Completely different keymap schemes requiring plan updates
6. **Context System**: NickvanDyke has powerful placeholder system (@this, @buffer, @diagnostics); sudo-tee has simpler context flags

**Recommendation**: Switching to NickvanDyke/opencode.nvim is viable and well-supported. The plan requires moderate revisions to dependencies, configuration structure, keymaps, and testing criteria.

---

## 1. Repository Analysis

### 1.1 NickvanDyke/opencode.nvim

**GitHub**: https://github.com/NickvanDyke/opencode.nvim

**Statistics**:
- Stars: 804
- Forks: 24
- Primary Language: Lua
- Status: Active development

**Description**: "Integrate the opencode AI assistant with Neovim — streamline editor-aware research, reviews, and requests."

**Design Philosophy**:
- Uses opencode's native TUI for simplicity
- Auto-connects to running opencode instances or manages integrated terminal
- Focuses on context injection via placeholder system
- Event-driven architecture with SSE forwarding

**Key Features**:
- Auto-connect to any running opencode instance matching Neovim's CWD
- Input prompts with completions, syntax highlighting, and normal-mode support
- Built-in prompt library with 9 predefined prompts (diagnostics, diff, document, explain, fix, implement, optimize, review, test)
- Context placeholder system (@this, @buffer, @buffers, @visible, @diagnostics, @quickfix, @diff, @grapple)
- Real-time buffer reloading when opencode edits files
- Statusline integration component
- Server-Sent-Events forwarding as Neovim autocmds
- Multi-provider support (snacks, kitty, wezterm, tmux, custom)

**Tested Version**: Opencode CLI v0.9.1 (API is undocumented but stable)

### 1.2 sudo-tee/opencode.nvim

**GitHub**: https://github.com/sudo-tee/opencode.nvim

**Design Philosophy**:
- Fork of goose.nvim by azorng
- Custom Neovim frontend with chat interface
- Workspace-persistent sessions
- Snapshot and restore system

**Key Features**:
- Chat interface within Neovim
- Persistent sessions tied to workspace
- Automatic snapshot creation at key moments
- Diff viewing (compare current state vs snapshot)
- File revert capabilities (individual or all files)
- Restore points before revert operations
- Custom highlight groups for theming

**Status**: Early development, may have bugs and breaking changes

**Required Version**: Opencode CLI v0.6.3+

---

## 2. Key Differences Analysis

### 2.1 Architecture Comparison

| Aspect | NickvanDyke/opencode.nvim | sudo-tee/opencode.nvim |
|--------|---------------------------|------------------------|
| **Interface Type** | Embeds opencode TUI | Custom chat frontend |
| **Terminal Provider** | Multi-provider (snacks/kitty/wezterm/tmux) | Custom terminal integration |
| **Session Management** | Uses opencode's native sessions | Workspace-persistent custom sessions |
| **Context Injection** | Placeholder system (@buffer, @this, etc.) | Boolean flags (include_buffer, include_diagnostics) |
| **Prompt Library** | 9 built-in prompts + custom | Custom prompt system |
| **Event System** | SSE forwarding via autocmds | Internal event handling |
| **Statusline** | Built-in component | No statusline support |
| **Health Check** | `:checkhealth opencode` available | No documented health check |

### 2.2 Configuration Structure Differences

#### NickvanDyke Configuration Pattern
```lua
-- Pre-load configuration via init function
init = function()
  vim.g.opencode_opts = {
    provider = { enabled = "snacks", snacks = {} },
    events = {
      reload_on_edit = true,
      permission_requests = "notify",
    },
    ui = {
      input_provider = "snacks",
      picker_provider = "snacks",
    },
    context = {
      include_diagnostics = true,
      include_buffer = true,
      include_visible = true,
    },
  }
  vim.o.autoread = true
end
```

**Key Characteristics**:
- Uses `vim.g.opencode_opts` global variable
- Set in `init` function (before plugin loads)
- Requires `vim.o.autoread = true` for file reloading
- No `setup()` function call needed

#### sudo-tee Configuration Pattern
```lua
-- Post-load configuration via config function
config = function()
  require("opencode").setup({
    preferred_picker = "telescope",
    preferred_completion = "blink",
    default_global_keymaps = true,
    keymap_prefix = "<leader>o",
    ui = {
      window_width = 0.40,
      zoom_width = 0.8,
    },
    icons = {
      preset = "text",
    },
  })
end
```

**Key Characteristics**:
- Uses `require("opencode").setup(opts)` pattern
- Called in `config` function (after plugin loads)
- Direct table-based options
- Explicit keymap configuration

### 2.3 Dependency Differences

#### NickvanDyke Dependencies
```lua
dependencies = {
  { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
}
```

**Required**:
- `folke/snacks.nvim` (core dependency for input, picker, terminal)

**Optional**:
- `cbochs/grapple.nvim` (for @grapple context placeholder)

**Not Required**: render-markdown.nvim, blink.cmp, telescope (uses snacks for everything)

#### sudo-tee Dependencies
```lua
dependencies = {
  "nvim-lua/plenary.nvim",
  "MeanderingProgrammer/render-markdown.nvim",
  "saghen/blink.cmp", -- or hrsh7th/nvim-cmp
  -- Picker: snacks.nvim, telescope.nvim, fzf-lua, or mini.nvim
}
```

**Required**:
- `nvim-lua/plenary.nvim`
- `MeanderingProgrammer/render-markdown.nvim`
- One completion plugin (blink.cmp or nvim-cmp)
- One picker plugin (snacks, telescope, fzf-lua, or mini)

**Not Required**: grapple.nvim

### 2.4 Keymap Comparison

#### NickvanDyke Default Keymaps
| Keymap | Mode | Function | Description |
|--------|------|----------|-------------|
| `<C-a>` | n/v | `ask()` | Input prompt with context |
| `<C-x>` | n | `select()` | Choose from plugin actions |
| `ga` | n/v | `prompt()` | Add context to prompt |
| `<C-.>` | n | `toggle()` | Toggle interface |
| `<S-C-u>` | n | `session.half.page.up` | Scroll up |
| `<S-C-d>` | n | `session.half.page.down` | Scroll down |

**Additional Available Commands**:
- Session: `session.list`, `session.new`, `session.share`, `session.interrupt`, `session.compact`
- Navigation: `session.page.up/down`, `session.first`, `session.last`
- History: `session.undo`, `session.redo`
- Prompt: `prompt.submit`, `prompt.clear`
- Agent: `agent.cycle`

#### sudo-tee Default Keymaps (with `<leader>o` prefix)
| Keymap | Mode | Function | Description |
|--------|------|----------|-------------|
| `<leader>og` | n | `toggle_ui` | Toggle UI globally |
| `<leader>oi` | n | `open_input` | Open input window |
| `<leader>oo` | n | `open_output` | Open output window |
| `<leader>os` | n | `select_session` | Select session picker |
| `<leader>oR` | n | `rename_session` | Rename current session |
| `<leader>od` | n | `diff_open` | Open diff view |
| `<leader>oc` | n | `diff_close` | Close diff view |
| `<CR>` | n/i | `submit` (input) | Submit prompt |
| `~` | i | `file_mentions` (input) | Insert file mentions |
| `/` | i | `slash_commands` (input) | Insert slash commands |
| `<up>/<down>` | i | history navigation (input) | Browse history |
| `]]`/`[[` | n | message navigation (output) | Navigate messages |
| `i` | n | `focus_input` (output) | Focus input window |
| `<tab>` | n | `toggle_pane` (output) | Toggle pane |

**Key Observations**:
- NickvanDyke uses Ctrl-based global keymaps (always available)
- sudo-tee uses leader-based namespace (`<leader>o`) and context-specific bindings
- NickvanDyke focuses on context injection workflow (ask → prompt → toggle)
- sudo-tee focuses on window management workflow (toggle → input → output → sessions)

---

## 3. Configuration Changes Required for Plan Revision

### 3.1 Plugin Specification Changes

#### Current Plan (sudo-tee)
```lua
return {
  "sudo-tee/opencode.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MeanderingProgrammer/render-markdown.nvim",
    "saghen/blink.cmp",
  },
  config = function()
    require("opencode").setup({
      preferred_picker = "telescope",
      preferred_completion = "blink",
      ui = { window_width = 0.40 },
      icons = { preset = "text" },
    })
  end,
}
```

#### Revised Plan (NickvanDyke)
```lua
return {
  "NickvanDyke/opencode.nvim",
  event = "VeryLazy",
  dependencies = {
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  init = function()
    vim.g.opencode_opts = {
      provider = {
        enabled = "snacks",
        snacks = {
          -- Terminal configuration (40% width standard)
          win = {
            position = "right",
            width = 0.40,
          },
        },
      },
      events = {
        reload_on_edit = true,
        permission_requests = "notify",
      },
      ui = {
        input_provider = "snacks",
        picker_provider = "snacks",
      },
      context = {
        include_diagnostics = true,
        include_buffer = true,
        include_visible = true,
      },
    }
    vim.o.autoread = true
  end,
  keys = {
    { "<C-a>", function() require("opencode").ask() end, desc = "OpenCode: Ask with context", mode = {"n", "v"} },
    { "<C-x>", function() require("opencode").select() end, desc = "OpenCode: Select action" },
    { "ga", function() require("opencode").prompt() end, desc = "OpenCode: Add context", mode = {"n", "v"} },
    { "<C-.>", function() require("opencode").toggle() end, desc = "OpenCode: Toggle" },
    { "<S-C-u>", function() require("opencode").command("session.half.page.up") end, desc = "OpenCode: Scroll up" },
    { "<S-C-d>", function() require("opencode").command("session.half.page.down") end, desc = "OpenCode: Scroll down" },
  },
  config = function()
    -- Run health check after plugin loads (deferred to avoid blocking)
    vim.defer_fn(function()
      vim.cmd("checkhealth opencode")
    end, 1000)
  end,
}
```

### 3.2 Dependency Updates

**Remove**:
- `nvim-lua/plenary.nvim` (not required by NickvanDyke)
- `MeanderingProgrammer/render-markdown.nvim` (not required by NickvanDyke)
- `saghen/blink.cmp` (not required; NickvanDyke has built-in completion)

**Add**:
- `folke/snacks.nvim` with `input`, `picker`, and `terminal` options enabled

**Optional Add**:
- `cbochs/grapple.nvim` (for @grapple context placeholder support)

**Impact**: User's existing `telescope.nvim` and `blink.cmp` remain but are not used by NickvanDyke variant.

### 3.3 Keymap Namespace Changes

**Current Plan**: Uses `<leader>o` prefix for all keymaps

**Revised Plan**: Uses Ctrl-based global keymaps (no leader prefix)

**User's Existing AI Plugin Keymaps**:
- Avante: `<leader>h` prefix
- Claude Code: `<leader>c` prefix
- Goose: `<leader>g` prefix

**Conflict Analysis**:
- `<C-a>`: May conflict with default increment number (rarely used in normal mode)
- `<C-x>`: May conflict with default decrement number (rarely used in normal mode)
- `ga`: Conflicts with default "print ascii value" command (rarely used)
- `<C-.>`: No standard Neovim conflict
- `<S-C-u>` / `<S-C-d>`: No standard Neovim conflict

**Recommendation**: Accept NickvanDyke's default keymaps as they are well-designed and minimal conflicts are acceptable. Document conflicts in README.

### 3.4 Configuration Options Mapping

#### 40% Window Width Standard
**sudo-tee**: `ui.window_width = 0.40`
**NickvanDyke**: `provider.snacks.win.width = 0.40` (terminal window configuration)

#### Icon Preset (Emoji-Free)
**sudo-tee**: `icons.preset = "text"`
**NickvanDyke**: No icon configuration needed (uses terminal rendering, inherits from opencode TUI)

#### Picker Integration
**sudo-tee**: `preferred_picker = "telescope"`
**NickvanDyke**: `ui.picker_provider = "snacks"` (snacks only, no telescope support)

**Impact**: NickvanDyke uses snacks.nvim picker instead of telescope. This is acceptable as snacks provides equivalent functionality.

#### Completion Integration
**sudo-tee**: `preferred_completion = "blink"`
**NickvanDyke**: `ui.input_provider = "snacks"` (built-in completion via snacks.input)

**Impact**: NickvanDyke has built-in completion for commands, file mentions, and subagents via `<Tab>` in input mode.

---

## 4. Feature Comparison

### 4.1 Core Features

| Feature | NickvanDyke | sudo-tee | Notes |
|---------|-------------|----------|-------|
| **Terminal Integration** | Embedded TUI | Custom frontend | NickvanDyke closer to native opencode experience |
| **Context Injection** | Placeholder system | Boolean flags | NickvanDyke more flexible (@this, @buffer, @diagnostics, etc.) |
| **Prompt Library** | 9 built-in prompts | Custom prompts | NickvanDyke has pre-defined library |
| **Session Management** | Native opencode sessions | Workspace-persistent | Both functional, different approaches |
| **Buffer Reloading** | Automatic real-time | Manual/on-save | NickvanDyke more responsive |
| **Statusline** | Built-in component | Not available | NickvanDyke advantage |
| **Event System** | SSE via autocmds | Internal events | NickvanDyke more extensible |
| **Health Check** | `:checkhealth opencode` | Not documented | NickvanDyke better diagnostics |
| **Multi-Provider** | snacks/kitty/wezterm/tmux | Single provider | NickvanDyke more flexible |

### 4.2 Context Placeholder System (NickvanDyke Unique)

NickvanDyke's context placeholder system is a major differentiator:

**Available Placeholders**:
- `@this` - Visual selection or cursor position
- `@buffer` - Current buffer content
- `@buffers` - All open buffers
- `@visible` - Visible text on screen
- `@diagnostics` - Current buffer diagnostics
- `@quickfix` - Quickfix list entries
- `@diff` - Git diff of current file
- `@grapple` - grapple.nvim tags (requires grapple plugin)

**Usage Example**:
```
Fix the errors in @this using context from @diagnostics
```

**Benefit**: More granular control over what context is sent to opencode, reducing token usage and improving relevance.

### 4.3 Snapshot/Restore Features (sudo-tee Unique)

sudo-tee provides comprehensive snapshot and restore capabilities:

**Features**:
- Automatic snapshots after prompts and changes
- Diff view (compare current vs snapshot)
- File-level revert (revert single file to snapshot)
- Session-wide revert (revert all files)
- Restore points before revert (undo revert operation)

**NickvanDyke Equivalent**: Uses opencode's native history (session.undo/session.redo) which operates at conversation level rather than file snapshot level.

**Impact**: If user heavily relies on granular file-level revert, sudo-tee is better. If native opencode history is sufficient, NickvanDyke is fine.

---

## 5. Testing Implications

### 5.1 Updated Test Checklist for NickvanDyke

**Prerequisites Verification** (Phase 1):
- [ ] Verify opencode CLI v0.9.1+ (current v1.0.119 is compatible)
- [ ] Check snacks.nvim availability (may need to install)
- [ ] Verify `<C-a>`, `<C-x>`, `ga`, `<C-.>` keymaps not in use
- [ ] Check grapple.nvim if @grapple context desired (optional)

**Core Functionality** (Phase 4):
- [ ] Test `<C-a>` (ask): Input prompt with context injection
- [ ] Test `<C-x>` (select): Choose from plugin actions via picker
- [ ] Test `ga` (prompt): Add context to existing prompt
- [ ] Test `<C-.>` (toggle): Toggle terminal interface
- [ ] Test `<S-C-u>` / `<S-C-d>`: Scroll navigation
- [ ] Verify terminal position (right side, 40% width)
- [ ] Test context placeholders: @this, @buffer, @diagnostics
- [ ] Verify buffer reload on opencode edits
- [ ] Test built-in prompts: diagnostics, diff, explain, fix, review
- [ ] Test history browsing with `<Up>` in input mode
- [ ] Test completion with `<Tab>` in input mode

**Health Check** (Phase 4):
- [ ] Run `:checkhealth opencode`
- [ ] Verify all health checks pass
- [ ] Document any warnings or errors

**Session Management**:
- [ ] Test session.new, session.list, session.share commands
- [ ] Verify session persistence across toggles
- [ ] Test session.undo / session.redo history

**Event System**:
- [ ] Test buffer auto-reload on file edits
- [ ] Verify permission request notifications
- [ ] Test OpencodeEvent autocmd forwarding (if applicable)

### 5.2 Removed Tests (sudo-tee Specific)

**Remove from Test Checklist**:
- [ ] Test session rename (`<leader>oR`) - not available in NickvanDyke
- [ ] Test diff view (`<leader>od` / `<leader>oc`) - different approach
- [ ] Test snapshot restoration - native history only
- [ ] Test file-level revert - not available
- [ ] Test restore points - not available
- [ ] Test telescope integration - uses snacks picker
- [ ] Test blink.cmp integration - uses snacks input

---

## 6. Documentation Updates Required

### 6.1 Plugin README Updates

**Section: Installation**
- Replace sudo-tee repository with NickvanDyke repository
- Update dependency list: remove plenary/render-markdown, add snacks.nvim
- Note grapple.nvim as optional dependency

**Section: Configuration**
- Replace `setup()` function example with `vim.g.opencode_opts` table
- Document `init` function pattern
- Add `vim.o.autoread = true` requirement
- Update 40% width configuration path

**Section: Keymaps**
- Replace `<leader>o` prefix with Ctrl-based keymaps
- Document `<C-a>`, `<C-x>`, `ga`, `<C-.>` bindings
- Add keymap conflict warnings (ga, Ctrl-a, Ctrl-x)
- Document available commands (session.*, prompt.*, agent.*)

**Section: Features**
- Add context placeholder system documentation
- Document built-in prompt library (9 prompts)
- Add statusline integration example
- Document event system (OpencodeEvent autocmds)
- Remove snapshot/restore feature documentation

**Section: Usage Examples**
- Update workflow: ask → prompt → toggle (not toggle → input → output)
- Add context placeholder usage examples
- Document prompt library usage
- Add history browsing and completion examples

**Section: Troubleshooting**
- Add `:checkhealth opencode` command
- Document buffer auto-reload issues (requires autoread)
- Add provider configuration troubleshooting
- Document snacks.nvim dependency issues

### 6.2 Alternative Plugin Section

**Update**: Remove "Alternative Implementation: NickvanDyke/opencode.nvim" appendix and replace with "Alternative Implementation: sudo-tee/opencode.nvim" since plan now uses NickvanDyke as primary.

**When to Choose sudo-tee**:
- Need granular file-level snapshot and revert capabilities
- Prefer custom chat interface over native TUI
- Want workspace-persistent sessions with detailed history
- Require explicit diff viewing before accepting changes

---

## 7. Migration Path from Current Plan

### 7.1 Phase-by-Phase Changes

**Phase 1: Prerequisites Verification**
- **Change**: Update CLI version requirement from v0.6.3+ to v0.9.1+ (already met by v1.0.119)
- **Change**: Replace dependency checklist:
  - Remove: plenary.nvim, render-markdown.nvim, blink.cmp, telescope
  - Add: snacks.nvim (with input, picker, terminal modules)
  - Add (optional): grapple.nvim
- **Change**: Update keymap conflict check from `<leader>o` to `<C-a>`, `<C-x>`, `ga`, `<C-.>`

**Phase 2: Plugin Configuration Creation**
- **Change**: Replace entire configuration structure:
  - From: `config` function with `setup()` call
  - To: `init` function with `vim.g.opencode_opts` table
- **Change**: Update dependencies list
- **Change**: Replace opts table structure (see Section 3.1)
- **Change**: Move keymaps to `keys` table in lazy.nvim spec
- **Change**: Add `vim.o.autoread = true` in init function
- **Change**: Add deferred health check in config function

**Phase 3: Plugin Registration**
- **No Change**: Still add "opencode" to ai_plugins list
- **No Change**: Plugin loader pattern remains the same

**Phase 4: Testing and Validation**
- **Change**: Replace entire test checklist (see Section 5.1)
- **Change**: Add health check validation (`:checkhealth opencode`)
- **Change**: Update keymap tests to new bindings
- **Change**: Add context placeholder tests
- **Change**: Add buffer auto-reload tests
- **Remove**: Snapshot/restore tests, telescope tests, blink.cmp tests

**Phase 5: Documentation**
- **Change**: Update all documentation sections (see Section 6)
- **Change**: Replace sudo-tee examples with NickvanDyke patterns
- **Change**: Add context placeholder documentation
- **Change**: Document built-in prompt library
- **Change**: Replace "Alternative: NickvanDyke" with "Alternative: sudo-tee"

### 7.2 Configuration File Template (Final)

```lua
return {
  "NickvanDyke/opencode.nvim",
  event = "VeryLazy",
  dependencies = {
    {
      "folke/snacks.nvim",
      opts = {
        input = {},
        picker = {},
        terminal = {},
      },
    },
    -- Optional: for @grapple context placeholder
    -- { "cbochs/grapple.nvim" },
  },
  init = function()
    -- Pre-load configuration via global variable
    vim.g.opencode_opts = {
      provider = {
        enabled = "snacks",
        snacks = {
          -- Terminal window configuration (40% width standard)
          win = {
            position = "right",
            width = 0.40,
          },
        },
      },
      events = {
        reload_on_edit = true,
        permission_requests = "notify",
      },
      ui = {
        input_provider = "snacks",
        picker_provider = "snacks",
      },
      context = {
        include_diagnostics = true,
        include_buffer = true,
        include_visible = true,
      },
    }
    -- Required for automatic buffer reloading
    vim.o.autoread = true
  end,
  keys = {
    { "<C-a>", function() require("opencode").ask() end, desc = "OpenCode: Ask with context", mode = {"n", "v"} },
    { "<C-x>", function() require("opencode").select() end, desc = "OpenCode: Select action" },
    { "ga", function() require("opencode").prompt() end, desc = "OpenCode: Add context", mode = {"n", "v"} },
    { "<C-.>", function() require("opencode").toggle() end, desc = "OpenCode: Toggle" },
    { "<S-C-u>", function() require("opencode").command("session.half.page.up") end, desc = "OpenCode: Scroll up" },
    { "<S-C-d>", function() require("opencode").command("session.half.page.down") end, desc = "OpenCode: Scroll down" },
  },
  config = function()
    -- Run health check after plugin loads (deferred to avoid blocking)
    vim.defer_fn(function()
      vim.cmd("checkhealth opencode")
    end, 1000)
  end,
}
```

---

## 8. Risk Analysis

### 8.1 Compatibility Risks

**Risk**: Opencode CLI API undocumented
- **Severity**: Low
- **Mitigation**: NickvanDyke tests against v0.9.1; user has v1.0.119 (newer, likely compatible)
- **Fallback**: Downgrade opencode CLI if breaking changes exist (unlikely)

**Risk**: snacks.nvim not installed
- **Severity**: Low
- **Mitigation**: lazy.nvim will auto-install as dependency
- **Fallback**: Manual installation via `:Lazy sync`

**Risk**: Keymap conflicts with user's existing mappings
- **Severity**: Medium
- **Conflicts**: `ga` (print ascii), `<C-a>` (increment), `<C-x>` (decrement)
- **Mitigation**: Document conflicts; user can override in `keys` table if needed
- **Fallback**: Create custom keymaps if conflicts are problematic

**Risk**: Terminal provider (snacks) issues
- **Severity**: Low
- **Mitigation**: NickvanDyke supports multiple providers (kitty, wezterm, tmux, custom)
- **Fallback**: Switch to alternative provider in config

### 8.2 Feature Gaps

**Gap**: No file-level snapshot/revert like sudo-tee
- **Impact**: User must use opencode's native history (session.undo/redo) or git for rollback
- **Severity**: Medium (depends on user workflow)
- **Mitigation**: Document native history commands and git integration

**Gap**: No custom chat interface styling
- **Impact**: Uses opencode TUI styling (cannot theme beyond terminal colors)
- **Severity**: Low (TUI is well-designed and themeable via terminal)
- **Mitigation**: None needed; terminal theming should suffice

**Gap**: No telescope integration
- **Impact**: Uses snacks.nvim picker instead of telescope
- **Severity**: Low (snacks picker is feature-complete)
- **Mitigation**: None needed; snacks is a modern, well-maintained alternative

### 8.3 Benefits of Switching

**Benefit**: More mature plugin (804 stars, active development)
**Benefit**: Better diagnostics (`:checkhealth opencode`)
**Benefit**: Powerful context placeholder system (@this, @buffer, @diagnostics)
**Benefit**: Built-in prompt library (diagnostics, diff, fix, review, etc.)
**Benefit**: Real-time buffer reloading on file edits
**Benefit**: Statusline integration component
**Benefit**: Multi-provider support (more flexible terminal integration)
**Benefit**: Event system via autocmds (more extensible)

---

## 9. Recommendations

### 9.1 Primary Recommendation

**Switch to NickvanDyke/opencode.nvim** as the primary implementation. The plugin is more mature, better documented, has superior diagnostics, and provides a richer feature set (context placeholders, prompt library, statusline, multi-provider support). The revised plan will require moderate changes but is fully achievable within the 2-4 hour estimate.

### 9.2 Configuration Recommendations

1. **Use snacks.nvim provider** (default) for best integration
2. **Enable autoread** (`vim.o.autoread = true`) for buffer reloading
3. **Accept default keymaps** (minimal conflicts, well-designed)
4. **Document keymap conflicts** in README (ga, Ctrl-a, Ctrl-x)
5. **Run health check** after installation (`:checkhealth opencode`)
6. **Add grapple.nvim** if user wants @grapple context (optional)

### 9.3 Documentation Recommendations

1. **Document context placeholders prominently** - this is a killer feature
2. **Provide workflow examples** - ask → prompt → toggle pattern
3. **List built-in prompts** - users may not discover them otherwise
4. **Add statusline integration example** - useful for seeing opencode state
5. **Keep sudo-tee as alternative** - document when to choose it (snapshot/revert needs)

### 9.4 Testing Recommendations

1. **Test health check first** - validates entire setup quickly
2. **Test context placeholders** - core differentiator, ensure they work
3. **Test buffer auto-reload** - critical feature, requires autoread
4. **Test built-in prompts** - verify prompt library is functional
5. **Test keymap conflicts** - especially ga, Ctrl-a, Ctrl-x

---

## 10. Conclusion

Switching from sudo-tee/opencode.nvim to NickvanDyke/opencode.nvim is a sound decision. NickvanDyke provides:
- **More mature codebase** (804 stars, active development)
- **Better developer experience** (health checks, diagnostics)
- **Richer feature set** (context placeholders, prompt library, statusline)
- **Greater flexibility** (multi-provider support, event system)
- **Closer to native opencode** (embeds TUI vs custom frontend)

The revised plan will require:
- **Dependency changes**: Replace plenary/render-markdown with snacks.nvim
- **Configuration restructure**: `vim.g.opencode_opts` instead of `setup()`
- **Keymap updates**: Ctrl-based instead of `<leader>o` prefix
- **Test checklist updates**: New features, remove snapshot tests
- **Documentation rewrites**: New workflow, features, and examples

**Estimated Revision Time**: 1-2 hours (within original 2-4 hour estimate)

**Risk Level**: Low (well-documented plugin, clear migration path, minimal conflicts)

**Next Steps**: Update implementation plan with findings from this report, focusing on Phase 2 (configuration) and Phase 4 (testing) revisions.

---

## Sources

- [GitHub - NickvanDyke/opencode.nvim](https://github.com/NickvanDyke/opencode.nvim)
- [GitHub - sudo-tee/opencode.nvim](https://github.com/sudo-tee/opencode.nvim)
- [opencode.nvim/README.md at main · NickvanDyke/opencode.nvim](https://github.com/NickvanDyke/opencode.nvim/blob/main/README.md)
- [opencode - nixvim docs](https://nix-community.github.io/nixvim/plugins/opencode/index.html)
- [Complete Guide to Using OpenCode with Neovim & Tmux](https://keebsforall.com/blogs/mechanical-keyboards-101/complete-guide-to-using-opencode-with-neovim-tmux)
