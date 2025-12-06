# Research Report: goose.nvim Integration with Gemini CLI and Claude Code Max

**Date**: 2025-12-05
**Topic**: Revision research for goose.nvim-focused Neovim AI integration
**Complexity**: 2

---

## Executive Summary

This research report provides findings to support revising the original plan from codecompanion.nvim to a goose.nvim-focused approach. The user wants to integrate goose.nvim with Gemini CLI (free tier) for initial setup and Claude Code Max subscription for premium usage.

---

## Key Findings

### 1. goose.nvim Plugin Architecture

**Repository**: [azorng/goose.nvim](https://github.com/azorng/goose.nvim)

goose.nvim provides seamless Neovim integration with the Goose AI agent, creating a chat interface while capturing editor context (current file, selections) to enhance prompts. Key characteristics:

- **Persistent Sessions**: Maintains workspace-tied sessions for continuous conversations
- **Context Capture**: Automatically captures current file, selections, and editor state
- **Modular Architecture**: Separates UI rendering, context collection, job execution, and session management
- **Multiple Picker Support**: Works with fzf-lua, telescope, mini.pick, and snacks

**Requirements**:
- Neovim 0.8.0+
- Goose CLI installed and configured
- plenary.nvim dependency
- render-markdown.nvim (optional, for enhanced rendering)

### 2. Goose CLI Provider Configuration

**Configuration Location**: `~/.config/goose/config.yaml`

**Supported Providers** (relevant to user request):

| Provider | Environment Variable | Notes |
|----------|---------------------|-------|
| Anthropic | `ANTHROPIC_API_KEY` | Best with Claude 4 models, strong tool-calling |
| Google Gemini | `GOOGLE_API_KEY` | Free tier available, up to 1M token context |
| Claude Code | OAuth/Subscription | Uses Max subscription, no API key needed |

**Important**: Goose supports "pass-through" providers that work with existing CLI tools (like Claude Code), allowing subscription-based usage instead of per-token API charges.

### 3. Claude Code Max Integration with Goose

**Key Finding**: Goose can use Claude Code as a model provider, leveraging the Max subscription ($100-$200/month) instead of API tokens.

**Configuration Path**:
1. Install Claude Code CLI
2. Authenticate with Max subscription credentials (NOT API key)
3. Configure Goose to use "Claude Code" as provider via `goose configure`

**Critical Warning**: If `ANTHROPIC_API_KEY` is set, Claude Code will use API billing instead of Max subscription. Must remove/unset this variable for subscription-based usage.

### 4. Gemini Free Tier for Initial Setup

**Benefits**:
- Free tier available for cost-effective initial testing
- 1 million token context window (Gemini 2.x models)
- Multimodal capabilities (text, images)
- Good for routine tasks and learning the workflow

**Recommended Model**: `gemini-2.0-flash-exp` for fast responses during development

### 5. goose.nvim Configuration Options

**Complete Configuration Structure**:

```lua
require('goose').setup({
  -- Picker Selection (auto-detects available picker)
  prefered_picker = nil, -- 'telescope', 'fzf', 'mini.pick', 'snacks'

  -- Keymaps
  default_global_keymaps = true,
  keymap = {
    global = {
      toggle = '<leader>gg',
      open_input = '<leader>gi',
      open_input_new_session = '<leader>gI',
      open_output = '<leader>go',
      toggle_focus = '<leader>gt',
      close = '<leader>gq',
      toggle_fullscreen = '<leader>gf',
      select_session = '<leader>gs',
      goose_mode_chat = '<leader>gmc',
      goose_mode_auto = '<leader>gma',
      configure_provider = '<leader>gp',
      open_config = '<leader>g.',
      inspect_session = '<leader>g?',
      diff_open = '<leader>gd',
      diff_next = '<leader>g]',
      diff_prev = '<leader>g[',
      diff_close = '<leader>gc',
      diff_revert_all = '<leader>gra',
      diff_revert_this = '<leader>grt',
    },
    window = {
      submit = '<cr>',
      close = '<esc>',
      stop = '<C-c>',
      next_message = ']]',
      prev_message = '[[',
      mention_file = '@',
      toggle_pane = '<tab>',
      prev_prompt_history = '<up>',
      next_prompt_history = '<down>',
    }
  },

  -- UI Settings
  ui = {
    window_width = 0.35,
    input_height = 0.15,
    fullscreen = false,
    layout = "right", -- "center" or "right"
    floating_height = 0.8,
    display_model = true,
    display_goose_mode = true,
  },

  -- Provider Configuration (for quick switching)
  providers = {
    google = { "gemini-2.0-flash-exp" },
    anthropic = { "claude-sonnet-4-0" },
    -- Claude Code configured via goose configure, not here
  },

  -- Custom system instructions
  system_instructions = "",
})
```

### 6. Workflow Strategy

**Recommended Two-Phase Approach**:

**Phase A: Gemini CLI Setup (Free Tier)**
1. Install Goose CLI
2. Configure with Google Gemini provider
3. Install goose.nvim in Neovim
4. Test basic workflows with free tier

**Phase B: Claude Code Max Upgrade**
1. Subscribe to Claude Max plan
2. Install Claude Code CLI
3. Authenticate with subscription (NOT API key)
4. Configure Goose to use Claude Code provider
5. Switch between providers based on task complexity

---

## Architecture Comparison

### Original Plan (codecompanion.nvim)
- Direct API calls to Anthropic/Google
- Strategy routing (chat → Gemini, inline → Claude)
- 12+ provider adapters built-in
- Per-token API costs

### Revised Plan (goose.nvim)
- Goose CLI as intermediary
- Pass-through to Claude Code subscription (flat monthly cost)
- Provider switching via `goose configure` or `<leader>gp`
- Unified agent interface with autonomous capabilities

---

## Cost Analysis

| Approach | Monthly Cost | Notes |
|----------|--------------|-------|
| Gemini Free Tier | $0 | Rate limited, good for learning |
| Claude API | Variable (~$0.003-$0.015/1K tokens) | Pay-per-use, unpredictable costs |
| Claude Max | $100-$200/month flat | Unlimited within usage tier, includes Claude Code |

**Recommendation**: Start with Gemini free tier for setup/testing, then transition to Claude Max for production use. Max plan provides better cost predictability and includes Claude Code integration natively.

---

## Sources

- [goose.nvim GitHub](https://github.com/azorng/goose.nvim)
- [Goose CLI Documentation](https://block.github.io/goose/docs/getting-started/installation)
- [Goose Provider Configuration](https://block.github.io/goose/docs/getting-started/providers/)
- [Claude Code with Max Plan](https://support.claude.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan)
- [Goose AI Agent Overview](https://github.com/block/goose)
- [Neovim AI Plugins List](https://github.com/ColinKennedy/neovim-ai-plugins)
