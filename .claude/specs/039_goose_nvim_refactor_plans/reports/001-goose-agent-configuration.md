# Goose Agent Current Configuration Analysis

## Metadata
- **Date**: 2025-12-09
- **Agent**: research-coordinator (direct research)
- **Topic**: Goose Agent Current Configuration Analysis
- **Report Type**: codebase analysis

## Executive Summary

The goose agent is currently integrated into the Neovim configuration as a lazy-loaded AI assistant plugin with support for Google Gemini (free tier). Configuration includes UI customization, telescope picker integration, and comprehensive keybindings under `<leader>a` namespace. The plugin is properly structured with disabled default keymaps to avoid conflicts, using which-key for centralized keymap management.

## Findings

### Finding 1: Plugin Configuration and Dependencies
- **Description**: goose.nvim is configured as a lazy-loaded plugin with explicit dependencies
- **Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua` (lines 1-42)
- **Evidence**:
```lua
return {
  "azorng/goose.nvim",
  branch = "main",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        anti_conceal = { enabled = false },
      },
    },
  },
```
- **Impact**: Plugin uses lazy.nvim loading strategy with command triggers (`Goose`, `GooseOpenInput`, `GooseClose`), ensuring no startup time penalty. Dependencies are properly declared for async operations (plenary) and markdown rendering.

### Finding 2: UI Configuration and Layout
- **Description**: Comprehensive UI configuration with right-sidebar layout and size customization
- **Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua` (lines 22-30)
- **Evidence**:
```lua
ui = {
  window_width = 0.35, -- 35% of screen width
  input_height = 0.15, -- 15% for input area
  fullscreen = false,
  layout = "right", -- Sidebar on right
  floating_height = 0.8,
  display_model = true, -- Show model in winbar
  display_goose_mode = true, -- Show mode in winbar
},
```
- **Impact**: UI is configured for optimal workflow with right sidebar (non-intrusive), visible model/mode indicators in winbar for context awareness, and balanced input/output proportions. Default to windowed mode with fullscreen toggle available.

### Finding 3: Provider Configuration (Gemini Only)
- **Description**: Currently configured for Google Gemini provider only, no Claude Code integration
- **Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua` (lines 32-35)
- **Evidence**:
```lua
providers = {
  google = { "gemini-2.0-flash-exp" },
},
```
- **Impact**: Only one provider configured (Google Gemini). No multi-provider setup for Claude Code or other LLM backends. This is the primary gap that needs addressing for the refactoring plan.

### Finding 4: Centralized Keymap Management
- **Description**: Default keymaps disabled in plugin, all bindings managed by which-key.lua
- **Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua` (line 19), `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` (lines 362-370)
- **Evidence**:
```lua
-- In goose/init.lua:
default_global_keymaps = false,

-- In which-key.lua:
{ "<leader>ag", "<cmd>Goose<CR>", desc = "goose toggle", icon = "󰚩" },
{ "<leader>ag", "<cmd>Goose<CR>", desc = "goose with selection", icon = "󰚩", mode = "v" },
{ "<leader>ai", "<cmd>GooseOpenInput<CR>", desc = "goose input", icon = "󰭹" },
{ "<leader>ao", "<cmd>GooseOpenOutput<CR>", desc = "goose output", icon = "󰆍" },
{ "<leader>af", "<cmd>GooseToggleFullscreen<CR>", desc = "goose fullscreen", icon = "󰊓" },
{ "<leader>ad", "<cmd>GooseDiff<CR>", desc = "goose diff", icon = "󰦓" },
{ "<leader>ab", "<cmd>GooseConfigureProvider<CR>", desc = "goose backend/provider", icon = "󰒓" },
{ "<leader>aq", "<cmd>GooseClose<CR>", desc = "goose quit", icon = "󰅖" },
```
- **Impact**: Follows Neovim configuration standards with centralized keymap management. Prevents keymap conflicts, provides consistent `<leader>a` namespace for all AI tools, includes goose-specific keybindings for provider switching (`<leader>ab`), fullscreen toggle, and diff view.

### Finding 5: Documentation and Integration Patterns
- **Description**: Comprehensive README with workflows, troubleshooting, and provider configuration instructions
- **Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md` (lines 1-363)
- **Evidence**: README covers:
  - Feature overview (persistent sessions, automatic context, diff view, provider-agnostic design)
  - Backend configuration for both Gemini (free tier) and Claude Code Max (subscription)
  - Usage workflows (chat, code generation, file context with @ mentions, diff review, session persistence)
  - Goose modes (Chat vs Auto mode)
  - Troubleshooting section with common issues
  - Performance notes and cost considerations
  - Hybrid strategy recommendations (Gemini for development, Claude Code for production)
- **Impact**: Documentation is well-structured and includes instructions for Claude Code integration, but the actual implementation in init.lua only configures Gemini. README describes intended multi-provider setup that isn't implemented.

### Finding 6: AI Plugin Loader Architecture
- **Description**: goose is part of a safe-loading AI plugin system with error handling
- **Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/init.lua` (lines 8-59)
- **Evidence**:
```lua
local ai_plugins = {
  "avante",
  "claudecode",
  "goose",
  "lectic",
  "mcp-hub",
}

for _, plugin_name in ipairs(ai_plugins) do
  local plugin_spec = safe_require("neotex.plugins.ai." .. plugin_name)
  if plugin_spec then
    table.insert(plugins, plugin_spec)
  end
end
```
- **Impact**: goose is loaded alongside other AI tools (avante, claudecode, lectic, mcp-hub) with error handling via safe_require(). This modular architecture allows each AI tool to be independently configured and loaded.

### Finding 7: Lazy Loading Strategy
- **Description**: Plugin uses command-based lazy loading with empty keys table
- **Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua` (lines 38-41)
- **Evidence**:
```lua
cmd = { "Goose", "GooseOpenInput", "GooseClose" },
-- Keybindings managed by which-key.lua (Phase 3)
-- Empty keys table to prevent plugin-defined keybindings
keys = {},
```
- **Impact**: Plugin loads only when `:Goose` or related commands are invoked, keeping startup time fast (<50ms according to README:299). Empty keys table ensures which-key manages all bindings, preventing duplicate key registrations.

## Recommendations

1. **Multi-Provider Configuration**: Extend providers table in init.lua to include Claude Code configuration alongside Gemini. Current single-provider setup doesn't match the multi-provider design described in README. Requires adding provider definitions for anthropic/claude backends with appropriate model selections.

2. **Conditional Provider Loading**: Implement environment-based provider selection (check for GOOGLE_API_KEY, ANTHROPIC_API_KEY, or claude CLI authentication) to automatically enable available providers. This would support the documented hybrid strategy without manual configuration switching.

3. **Provider Switching Keybinding Enhancement**: The `<leader>ab` keybinding calls `:GooseConfigureProvider`, but with only one provider configured, this command has limited utility. Once multi-provider support is added, document the provider switching workflow more prominently in the README usage section.

4. **Configuration Validation**: Add health check integration (`:checkhealth goose`) to validate provider configurations, API key presence, and CLI tool availability. This would catch configuration issues early, especially when adding Claude Code support.

5. **Cost Tracking Integration**: Given the hybrid strategy described in README (Gemini free + Claude Max), consider adding usage tracking to help users monitor which provider is being used for each session. This could be displayed in the winbar alongside the model name.

## References

### Configuration Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua` (lines 1-42) - Plugin specification and setup
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md` (lines 1-363) - Comprehensive documentation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/init.lua` (lines 1-60) - AI plugin loader
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` (lines 362-370) - Goose keybindings

### External References
- [goose.nvim GitHub](https://github.com/azorng/goose.nvim) - Upstream plugin repository
- [Goose CLI Documentation](https://block.github.io/goose/docs/getting-started/installation) - CLI setup guide
- [Claude Code with Max](https://support.claude.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan) - Subscription integration
