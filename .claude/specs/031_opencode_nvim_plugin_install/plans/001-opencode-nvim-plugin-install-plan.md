# Implementation Plan: Opencode.nvim Plugin Installation

**Date**: 2025-12-10 (Revised)
**Feature**: Install opencode.nvim plugin in Neovim configuration with full integration
**Status**: [NOT STARTED]
**Estimated Hours**: 2-4 hours
**Standards File**: /home/benjamin/.config/CLAUDE.md
**Research Reports**:
- [Opencode.nvim Plugin Installation](../reports/001-opencode-nvim-plugin-install.md)
- [Neovim Configuration Integration](../reports/002-neovim-config-integration.md)
- [Opencode CLI Integration with Neovim](../reports/003-opencode-cli-nvim-integration.md)
- [NickvanDyke opencode.nvim Research](../reports/1-i_want_to_use_nickvandyke_open.md)

---

## Overview

This plan implements opencode.nvim plugin integration into the user's existing Neovim configuration. The implementation follows the user's modular plugin architecture under `lua/neotex/plugins/ai/` and adheres to established standards for emoji-free configuration, consistent UI sizing (40% window width), and keymap organization.

Based on comprehensive research and user preference, this plan uses **NickvanDyke/opencode.nvim** for the implementation. This variant provides a mature, feature-rich solution with powerful context placeholders (@this, @buffer, @diagnostics), built-in prompt library, statusline integration, and embedded TUI experience that closely matches native opencode functionality.

**Keymap Integration Strategy**: All default plugin keymaps will be DISABLED. Keymaps will be explicitly defined in the user's configuration:
- Leader-based keymaps (`<leader>ao*`) in `which-key.lua` under the existing AI menu (`<leader>a`)
- Non-leader keymaps (toggle) in `keymaps.lua` for centralized management
- Goose-related mappings will be commented out for later removal

---

## Success Criteria

- [ ] opencode.nvim plugin successfully installed via lazy.nvim
- [ ] Plugin configuration file created at `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/opencode.lua`
- [ ] Plugin registered in ai_plugins loader list
- [ ] All required dependencies installed (snacks.nvim)
- [ ] Configuration follows user's standards (40% width terminal, right side)
- [ ] All default keymaps disabled in plugin configuration
- [ ] Leader-based keymaps added to which-key.lua under `<leader>ao` (opencode) submenu
- [ ] Global toggle keymap added to keymaps.lua
- [ ] Context placeholders functional (@this, @buffer, @diagnostics)
- [ ] OpenCode CLI (v1.0.119) verified and compatible
- [ ] Health check passes (`:checkhealth opencode`)
- [ ] Built-in prompt library accessible
- [ ] Goose mappings commented out in which-key.lua
- [ ] Documentation updated in plugin README

---

## Phase Dependencies

```
Phase 1 (Prerequisites Verification)
  |
  v
Phase 2 (Plugin Configuration Creation) [depends: Phase 1]
  |
  v
Phase 3 (Plugin Registration) [depends: Phase 2]
  |
  v
Phase 3.5 (Keymap Integration) [depends: Phase 3]
  |
  v
Phase 4 (Testing and Validation) [depends: Phase 3.5]
  |
  v
Phase 5 (Documentation) [depends: Phase 4]
```

---

## Implementation Phases

### Phase 1: Prerequisites Verification [IN PROGRESS]

**Purpose**: Verify all prerequisites are met before plugin installation

**Tasks**:
- [ ] Verify opencode CLI installation and version
  - Location: `/run/current-system/sw/bin/opencode`
  - Required version: v0.9.1+ for NickvanDyke variant (current: v1.0.119)
  - Command: `opencode --version`
- [ ] Check existing dependency status
  - Verify `folke/snacks.nvim` (may need installation)
  - Check `cbochs/grapple.nvim` (optional for @grapple context)
- [ ] Verify plugin loader structure
  - Check `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/init.lua` exists
  - Confirm ai_plugins list pattern
  - Review safe_require error handling
- [ ] Analyze existing AI keymap structure
  - Review `<leader>a` AI menu in which-key.lua for available letters
  - Identify existing submenu patterns (e.g., lectic uses `<leader>al`, `<leader>an`, `<leader>ak`)
  - Plan opencode submenu under `<leader>ao` prefix
  - Review keymaps.lua for non-leader toggle patterns (`<C-c>` for Claude, `<C-g>` for Avante)
- [ ] Identify default opencode keymaps to disable
  - `<C-a>`: conflicts with increment number (Vim default)
  - `<C-x>`: conflicts with decrement number (Vim default)
  - `ga`: conflicts with print ascii value (Vim default)
  - `<C-.>`: potential conflict, should be explicit
  - `<S-C-u>`, `<S-C-d>`: scroll navigation
- [ ] Verify Neovim version compatibility
  - Required: Neovim >= 0.9
  - Command: `nvim --version`

**Success Criteria**:
- [ ] OpenCode CLI v1.0.119 confirmed functional
- [ ] All dependency plugins identified (installed or pending)
- [ ] Plugin loader pattern understood and documented
- [ ] Available letters under `<leader>ao` prefix identified
- [ ] Default keymaps to disable documented
- [ ] Non-leader toggle key selected (recommend `<C-o>` if available)
- [ ] Neovim version meets requirements

**Outputs**:
- Prerequisites checklist with status for each item
- List of dependencies requiring installation (snacks.nvim, optionally grapple.nvim)
- Keymap allocation plan for opencode integration

---

### Phase 2: Plugin Configuration Creation [COMPLETE]

**Purpose**: Create plugin specification file following user's modular architecture

**Tasks**:
- [x] Create plugin specification file
  - Path: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/opencode.lua`
  - Follow lazy.nvim spec pattern from existing AI plugins
  - Include event-based loading (`event = "VeryLazy"`)
- [x] Configure dependencies
  - Add `folke/snacks.nvim` with `input`, `picker`, and `terminal` options
  - Optionally add `cbochs/grapple.nvim` for @grapple context placeholder
- [x] Configure plugin options via init function
  - Use `vim.g.opencode_opts` table (not `setup()` function)
  - Set `provider.enabled = "snacks"`
  - Configure terminal window: `provider.snacks.win.position = "right"`, `width = 0.40`
  - Enable events: `reload_on_edit = true`, `permission_requests = "notify"`
  - Set UI providers: `input_provider = "snacks"`, `picker_provider = "snacks"`
  - Configure context: `include_diagnostics`, `include_buffer`, `include_visible`
  - Set `vim.o.autoread = true` for buffer reloading
- [x] **DISABLE all default keymaps in plugin**
  - Set empty `keys = {}` table in lazy.nvim spec (prevents plugin keymaps)
  - OR configure `vim.g.opencode_opts.keys = {}` to disable at plugin level
  - Verify no default mappings are created on plugin load
- [x] Add config function
  - Run deferred health check: `vim.cmd("checkhealth opencode")`
  - Use 1000ms delay to avoid blocking startup

**Success Criteria**:
- [x] Plugin spec file created with correct structure
- [x] All dependencies declared in dependencies list
- [x] Configuration follows user's standards (40% width terminal, right side)
- [x] **All default keymaps disabled** (empty keys table)
- [x] Init function properly sets `vim.g.opencode_opts` and `autoread`

**Outputs**:
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/opencode.lua` file
- Configuration matches user's style and standards
- No default keymaps active from plugin

---

### Phase 3: Plugin Registration [COMPLETE]

**Purpose**: Register opencode plugin in ai_plugins loader

**Tasks**:
- [x] Read current ai_plugins list
  - Path: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/init.lua`
  - Identify current plugins: avante, claudecode, goose, lectic, mcp-hub
- [x] Add "opencode" to ai_plugins list
  - Insert alphabetically or at end of list
  - Maintain consistent formatting
  - Preserve existing safe_require pattern
- [x] Verify loader logic
  - Confirm safe_require handles missing modules gracefully
  - Check error notification pattern
  - Ensure table.insert pattern matches existing code
- [x] Test lazy.nvim detection
  - Verify plugin appears in `:Lazy` interface
  - Check that lazy.nvim can locate the spec file

**Success Criteria**:
- [x] "opencode" added to ai_plugins list
- [x] Plugin loader successfully requires opencode.lua
- [x] No syntax errors in init.lua
- [x] Plugin visible in `:Lazy` interface

**Outputs**:
- Modified `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/init.lua`
- Plugin registered in loader system

---

### Phase 3.5: Keymap Integration [COMPLETE]

**Purpose**: Add opencode keymaps to which-key.lua and keymaps.lua following user's configuration patterns

**Tasks**:
- [x] Add opencode leader keymaps to which-key.lua under `<leader>a` AI group
  - Create `<leader>ao` submenu group for opencode (matches pattern: `<leader>al` for lectic)
  - `<leader>aoo`: opencode toggle (primary interaction)
  - `<leader>aoa`: opencode ask with context (normal/visual mode)
  - `<leader>aos`: opencode select action picker
  - `<leader>aop`: opencode prompt/add context (normal/visual mode)
  - `<leader>aob`: opencode buffer context (@buffer)
  - `<leader>aod`: opencode diagnostics context (@diagnostics)
  - `<leader>aon`: opencode new session
  - `<leader>aol`: opencode session list
  - Icons should follow existing pattern (use appropriate nerd font icons)
- [x] Add global toggle keymap to keymaps.lua
  - Add `<C-o>` (or suitable alternative) for opencode toggle in all modes
  - Follow pattern established by `<C-c>` (Claude) and `<C-g>` (Avante)
  - Add to AI/ASSISTANT GLOBAL KEYS section with documentation
- [x] Comment out ALL goose-related mappings in which-key.lua
  - `<leader>ad`: goose diff
  - `<leader>ag`: goose toggle
  - `<leader>ai`: goose inspect session
  - `<leader>aj`: goose run recipe
  - `<leader>ak`: goose kill
  - `<leader>am`: goose mode picker
  - `<leader>an`: goose new session
  - `<leader>ap`: goose provider
  - `<leader>ar`: goose revert this
  - `<leader>as`: goose session (NOTE: conflicts with existing `<leader>as` claude sessions - resolve)
  - `<leader>au`: goose undo all
  - Add comment header: `-- Goose AI commands (COMMENTED OUT: 2025-12-10 - Pending removal)`
- [x] Update keybinding documentation header in which-key.lua
  - Add opencode keymaps to the documentation block at top of file
- [x] Update keybinding documentation header in keymaps.lua
  - Add opencode toggle to AI/ASSISTANT GLOBAL KEYBINDINGS table

**Success Criteria**:
- [x] All opencode keymaps under `<leader>ao` prefix work correctly
- [x] Global toggle (`<C-o>` or alternative) works in all modes
- [x] All goose mappings commented out with dated comment
- [x] No keymap conflicts with existing bindings
- [x] Documentation headers updated in both files

**Outputs**:
- Modified `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua`
- Modified `/home/benjamin/.config/nvim/lua/neotex/config/keymaps.lua`
- Keymaps follow established patterns and work without conflicts

---

### Phase 4: Testing and Validation [COMPLETE]

**Purpose**: Verify plugin installation, configuration, and functionality

**Tasks**:
- [x] Perform plugin installation
  - Restart Neovim (or source configuration)
  - Run `:Lazy sync` to install opencode.nvim and dependencies
  - Verify no installation errors in `:Lazy` output
  - Check `:messages` for any error messages
- [x] Verify dependencies installed
  - Check snacks.nvim loaded
  - Verify grapple.nvim (if configured)
- [x] Run health check first
  - Command: `:checkhealth opencode`
  - Review any warnings or errors
  - Document health check results
  - Verify all health checks pass
- [x] **Verify default keymaps are disabled**
  - Confirm `<C-a>` still increments numbers (Vim default)
  - Confirm `<C-x>` still decrements numbers (Vim default)
  - Confirm `ga` still shows ascii value (Vim default)
  - Confirm no plugin keymaps were created
- [x] Test custom leader keymaps (which-key.lua)
  - `<leader>ao` submenu appears in which-key popup
  - `<leader>aoo`: toggle works correctly
  - `<leader>aoa`: ask with context (normal/visual mode)
  - `<leader>aos`: select action picker opens
  - `<leader>aop`: prompt/add context works
  - `<leader>aob`: buffer context injection (@buffer)
  - `<leader>aod`: diagnostics context injection (@diagnostics)
  - `<leader>aon`: creates new session
  - `<leader>aol`: lists sessions
- [x] Test global toggle keymap (keymaps.lua)
  - `<C-o>` (or chosen key) toggles opencode in normal mode
  - Toggle works in insert mode
  - Toggle works in visual mode
  - Toggle works in terminal mode
- [x] Verify goose mappings are disabled
  - Confirm `<leader>ag` does NOT trigger goose
  - Confirm other goose mappings are inactive
  - No errors when pressing former goose keymaps
- [x] Test context placeholder system
  - Test @this (visual selection or cursor position)
  - Test @buffer (current buffer content)
  - Test @diagnostics (current buffer diagnostics)
  - Test @visible (visible text on screen)
  - Test @diff (git diff of current file)
  - Verify placeholder expansion in prompts
- [x] Test built-in prompt library
  - Access prompt library via `<leader>aos` select action
  - Test diagnostics prompt
  - Test diff prompt
  - Test explain prompt
  - Test fix prompt
  - Test review prompt
- [x] Test terminal integration
  - Verify terminal opens on right side
  - Check terminal width (40% of window)
  - Test terminal auto-connect to opencode instance
  - Verify TUI rendering within Neovim
- [x] Test buffer auto-reload
  - Make edit via opencode
  - Verify buffer reloads automatically
  - Check autoread setting active
- [x] Test session management
  - `<leader>aol`: lists available sessions
  - `<leader>aon`: creates new session
  - Verify session persistence across toggles
- [x] Verify CLI integration
  - Send prompt and verify opencode CLI processes it
  - Check response rendering in TUI
  - Test file editing via opencode
- [x] Verify no keymap conflicts
  - Claude Code toggle (`<C-c>`) still works
  - Avante toggle (`<C-g>`) still works
  - Existing `<leader>a` Claude keymaps still work
  - Existing `<leader>a` Lectic keymaps still work

**Success Criteria**:
- [x] Plugin and dependencies installed without errors
- [x] Health check passes
- [x] **All default plugin keymaps confirmed disabled**
- [x] All custom leader keymaps functional (`<leader>ao*`)
- [x] Global toggle keymap functional in all modes
- [x] **All goose mappings confirmed disabled**
- [x] Context placeholders work correctly
- [x] Built-in prompt library accessible
- [x] Terminal renders correctly (right side, 40% width)
- [x] Buffer auto-reload functional
- [x] Session management works as expected
- [x] OpenCode CLI integration verified
- [x] No conflicts with existing AI plugin keymaps

**Outputs**:
- Test results summary
- List of any issues encountered and resolutions
- Health check output
- Confirmation of keymap integration success

---

### Phase 5: Documentation [COMPLETE]

**Purpose**: Document installation and usage for future reference

**Tasks**:
- [x] Update plugin README
  - Add opencode to list of AI plugins
  - Document leader keymaps under `<leader>ao` submenu:
    - `<leader>aoo`: toggle opencode interface
    - `<leader>aoa`: ask with context
    - `<leader>aos`: select action picker
    - `<leader>aop`: add prompt context
    - `<leader>aob`: inject buffer context
    - `<leader>aod`: inject diagnostics context
    - `<leader>aon`: new session
    - `<leader>aol`: list sessions
  - Document global toggle keymap: `<C-o>` (or chosen alternative)
  - Note: All default plugin keymaps disabled intentionally
  - Note dependencies: snacks.nvim, optionally grapple.nvim
- [x] Document context placeholder system
  - Explain @this, @buffer, @buffers, @visible, @diagnostics, @quickfix, @diff, @grapple
  - Provide usage examples: "Fix errors in @this using @diagnostics"
  - Document benefits: granular control, reduced token usage
- [x] Document built-in prompt library
  - List 9 built-in prompts: diagnostics, diff, document, explain, fix, implement, optimize, review, test
  - Explain how to access via `<leader>aos` select action
  - Provide prompt customization examples
- [x] Document configuration options
  - Explain `vim.g.opencode_opts` table structure
  - Document 40% terminal width standard
  - Note snacks.nvim provider configuration
  - Explain `vim.o.autoread = true` requirement for buffer reloading
  - Document disabled keymaps decision and rationale
- [x] Create usage examples
  - Basic workflow: toggle (`<leader>aoo`), ask (`<leader>aoa`), add context (`<leader>aop`)
  - Quick toggle: `<C-o>` for rapid access
  - Context injection: visual select + `<leader>aoa` with @this placeholder
  - Prompt library: `<leader>aos` to access built-in prompts
  - Session management: `<leader>aol` to list, `<leader>aon` for new
  - Buffer auto-reload: automatic updates when opencode edits files
- [x] Document statusline integration
  - Provide statusline component example
  - Explain how to display opencode state in statusline
- [x] Add troubleshooting section
  - Health check: `:checkhealth opencode`
  - OpenCode CLI version requirements (v0.9.1+)
  - Buffer auto-reload issues (requires autoread)
  - snacks.nvim dependency issues
  - Provider configuration problems
  - Keymap troubleshooting (if keymaps not working, check which-key/keymaps.lua)
- [x] Document goose deprecation
  - Note goose mappings commented out with date (2025-12-10)
  - Reference future removal plan
- [x] Update CHANGELOG or commit message
  - Summarize installation and configuration
  - Note research-driven decision for NickvanDyke variant
  - Document keymap strategy (disable defaults, explicit integration)
  - Note goose mappings commented out
  - Reference research reports for rationale

**Success Criteria**:
- [x] Plugin README updated with opencode section
- [x] All leader keymaps (`<leader>ao*`) documented
- [x] Global toggle keymap documented
- [x] Context placeholder system documented prominently
- [x] Built-in prompt library documented
- [x] Configuration options documented (including disabled keymaps)
- [x] Usage examples provided with correct keymaps
- [x] Statusline integration documented
- [x] Troubleshooting guide added
- [x] Goose deprecation noted
- [x] Changes documented in CHANGELOG or commit

**Outputs**:
- Updated `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/README.md` (or create if missing)
- Usage examples and troubleshooting guide
- Commit-ready documentation

---

## Rollback Strategy

If installation fails or causes issues:

1. **Remove from ai_plugins list**: Remove "opencode" entry from `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/init.lua`
2. **Delete plugin spec**: Remove `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/opencode.lua`
3. **Clean lazy.nvim cache**: Run `:Lazy clean` to remove installed plugin
4. **Restart Neovim**: Fully restart to clear any loaded modules
5. **Verify restoration**: Check that other AI plugins still function correctly

---

## Notes

- This plan follows the user's modular plugin architecture and coding standards
- Research reports identified NickvanDyke/opencode.nvim as preferred implementation per user request
- NickvanDyke variant provides mature, feature-rich solution with 804 GitHub stars
- Configuration uses `vim.g.opencode_opts` table via `init` function (not `setup()`)
- Context placeholder system (@this, @buffer, @diagnostics) is a key differentiator
- Built-in prompt library provides 9 predefined prompts (diagnostics, diff, explain, fix, review, etc.)
- Configuration adheres to 40% terminal width standard on right side

### Keymap Strategy (Revised 2025-12-10)

- **All default plugin keymaps DISABLED** to avoid conflicts with Vim defaults:
  - `<C-a>` (increment), `<C-x>` (decrement), `ga` (print ascii) preserved as Vim defaults
- **Leader keymaps** defined in which-key.lua under `<leader>ao` submenu:
  - Follows established pattern (e.g., `<leader>al` for lectic)
  - All opencode functionality accessible via `<leader>ao*` prefix
- **Global toggle** defined in keymaps.lua:
  - `<C-o>` (or suitable alternative) for quick toggle
  - Follows pattern of `<C-c>` (Claude) and `<C-g>` (Avante)
- **Goose mappings commented out** (pending removal):
  - All `<leader>a[dgijkmnprsu]` goose keymaps disabled
  - Dated comment for tracking: `COMMENTED OUT: 2025-12-10`

### Dependencies
- snacks.nvim (required)
- grapple.nvim (optional for @grapple context)

### CLI Requirements
- OpenCode CLI v1.0.119 is already installed and compatible (exceeds v0.9.1+ requirement)
- Health check (`:checkhealth opencode`) available for diagnostics
