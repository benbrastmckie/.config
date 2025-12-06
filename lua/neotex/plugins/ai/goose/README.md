# goose.nvim Integration

AI-assisted coding with Goose agent backend supporting multiple providers (Google Gemini, Claude Code).

## Purpose

This module integrates [goose.nvim](https://github.com/azorng/goose.nvim) with the Neovim configuration, providing seamless AI agent capabilities with persistent sessions, automatic context capture, and native diff review.

## Features

- **Persistent Sessions**: Conversations tied to workspace, preserved across Neovim restarts
- **Automatic Context**: Captures current file, selections, and editor state
- **Diff View**: Review and revert AI-generated changes before applying
- **Provider-Agnostic**: Switch between Gemini (free) and Claude Code (Max subscription)
- **Lazy Loading**: No impact on Neovim startup time
- **Integrated Keybindings**: All AI tools under `<leader>a` namespace in which-key.lua

## Configuration

### Plugin Specification

```lua
-- nvim/lua/neotex/plugins/ai/goose/init.lua
return {
  "azorng/goose.nvim",
  branch = "main",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MeanderingProgrammer/render-markdown.nvim",
  },
  config = function()
    require("goose").setup({
      prefered_picker = "telescope",
      default_global_keymaps = false,  -- Managed by which-key.lua
      ui = {
        window_width = 0.35,
        input_height = 0.15,
        layout = "right",
        display_model = true,
        display_goose_mode = true,
      },
      providers = {
        google = { "gemini-2.0-flash-exp" },
      },
    })
  end,
  cmd = { "Goose", "GooseOpenInput", "GooseClose" },
  keys = {},  -- Empty: keybindings in which-key.lua
}
```

### Keybindings

All goose.nvim keybindings are defined in `which-key.lua` under the `<leader>a` namespace:

| Mapping | Mode | Description |
|---------|------|-------------|
| `<leader>ag` | Normal | Toggle goose interface |
| `<leader>ag` | Visual | Send selection to goose with prompt |
| `<leader>ai` | Normal | Focus goose input window |
| `<leader>ao` | Normal | Focus goose output window |
| `<leader>af` | Normal | Toggle goose fullscreen mode |
| `<leader>ad` | Normal | Open goose diff view |
| `<leader>ab` | Normal | Switch goose backend/provider |
| `<leader>aq` | Normal | Close goose interface |

### Backend Configuration

#### Google Gemini (Free Tier)

1. Get API key from [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Configure Goose:
   ```bash
   goose configure
   # Select: Google Gemini
   # Enter: GOOGLE_API_KEY
   # Model: gemini-2.0-flash-exp
   ```

#### Claude Code (Max Subscription)

1. Subscribe to Claude Max at [claude.ai/upgrade](https://claude.ai/upgrade)
2. Install Claude Code CLI (already installed via NixOS)
3. Authenticate:
   ```bash
   claude auth login
   # IMPORTANT: Ensure ANTHROPIC_API_KEY is NOT set
   unset ANTHROPIC_API_KEY
   ```
4. Configure Goose:
   ```bash
   goose configure
   # Select: Claude Code
   # Uses pass-through mode (no API key needed)
   ```
5. Verify subscription billing:
   ```bash
   claude /status
   # Should show Max subscription info
   ```

#### Switching Providers

- **In Neovim**: Press `<leader>ab` to open provider configuration
- **In Terminal**: Run `goose configure` to reconfigure backend

## Usage Workflows

### Basic Chat Workflow

1. Open Neovim in a project directory
2. Press `<leader>ag` to toggle goose interface
3. Type your question or request in the input area
4. View AI response in the output area
5. Press `<leader>aq` to close when done

### Code Generation with Context

1. Select code in visual mode
2. Press `<leader>ag` to send selection to goose
3. Type your request (e.g., "refactor this function")
4. Review generated code in diff view (`<leader>ad`)
5. Accept or revert changes

### File Context with @ Mentions

1. Open goose input (`<leader>ai`)
2. Type `@` to trigger file picker
3. Select files to include in context
4. Write your prompt referencing the files
5. AI responds with full file context

### Diff Review Workflow

1. After goose generates code changes:
2. Press `<leader>ad` to open diff view
3. Review changes side-by-side
4. Use `:GooseDiffNext` / `:GooseDiffPrev` to navigate
5. Run `:GooseDiffRevertThis` or `:GooseDiffRevertAll` to undo

### Session Persistence

- Sessions are automatically saved to `~/.config/goose/sessions/`
- Each workspace has its own session history
- Sessions persist across Neovim restarts
- Use `:GooseSelectSession` to switch between sessions

## Goose Modes

### Chat Mode (Default)

- Conversation-only, no file edits
- Safe for exploratory questions
- Faster responses
- Switch: `:GooseModeChat`

### Auto Mode

- Full agent capabilities with file editing
- Can create, modify, and delete files
- Requires review via diff view
- Switch: `:GooseModeAuto`

## Troubleshooting

### Plugin Not Loading

**Issue**: `:Goose` command not found

**Solution**:
1. Run `:Lazy sync` to install plugins
2. Check `:checkhealth goose` for errors
3. Verify dependencies installed (plenary.nvim, render-markdown.nvim)
4. Restart Neovim

### Goose CLI Not Found

**Issue**: "goose: command not found"

**Solution**:
1. Verify NixOS installation: `goose --version`
2. Check PATH includes Goose CLI
3. Rebuild NixOS if needed: `sudo nixos-rebuild switch`

### Provider Authentication Errors

**Issue**: "Authentication failed" or "Invalid API key"

**Solution**:
1. Re-run `goose configure` with correct credentials
2. Verify API key is valid and not expired
3. For Claude Code: Ensure `ANTHROPIC_API_KEY` is NOT set
4. Check `~/.config/goose/config.yaml` for correct configuration

### API Charges Instead of Subscription

**Issue**: Claude usage shows API billing instead of Max subscription

**Solution**:
1. Check environment: `env | grep ANTHROPIC_API_KEY`
2. If set, unset it: `unset ANTHROPIC_API_KEY`
3. Re-authenticate: `claude auth login`
4. Verify with: `claude /status` (should show subscription)

### Session Persistence Not Working

**Issue**: Sessions don't persist across restarts

**Solution**:
1. Check directory permissions: `ls -la ~/.config/goose/sessions/`
2. Verify workspace detection (sessions tied to workspace root)
3. Clear stale sessions: `rm -rf ~/.config/goose/sessions/*`
4. Restart Neovim and test again

### Keybinding Conflicts

**Issue**: `<leader>a*` mappings not working

**Solution**:
1. Check for conflicts: `:verbose map <leader>a`
2. Verify which-key loaded: `:checkhealth which-key`
3. Test specific mapping: Press `<leader>a` and check goose entries
4. Review which-key.lua for duplicate mappings

## Common Workflows

### Code Review Assistant

```
Prompt: Review this function for performance and readability
Context: @current_file or visual selection
Mode: Chat mode
Provider: Gemini (fast, free)
```

### Refactoring Large Files

```
Prompt: Refactor this module to use modern patterns
Context: @file_to_refactor
Mode: Auto mode
Provider: Claude Code (better for complex refactoring)
Review: Use <leader>ad to review all changes before accepting
```

### Documentation Generation

```
Prompt: Generate comprehensive JSDoc comments for all functions
Context: @source_file
Mode: Auto mode
Provider: Either (simple task)
Review: Check generated comments in diff view
```

### Debugging Assistance

```
Prompt: Explain this error and suggest fixes: [paste error]
Context: @relevant_file
Mode: Chat mode
Provider: Claude Code (better reasoning)
```

### Test Generation

```
Prompt: Generate unit tests for all exported functions
Context: @source_file
Mode: Auto mode
Provider: Claude Code (better test coverage)
Review: Review generated tests in diff view
```

## Configuration Files

### goose.nvim Configuration

- **Location**: `nvim/lua/neotex/plugins/ai/goose/init.lua`
- **Purpose**: Plugin setup and UI configuration
- **Keybindings**: Disabled (managed by which-key.lua)

### Goose CLI Configuration

- **Location**: `~/.config/goose/config.yaml`
- **Purpose**: Provider credentials and model selection
- **Managed by**: `goose configure` command

### Session Storage

- **Location**: `~/.config/goose/sessions/`
- **Purpose**: Persistent conversation history per workspace
- **Format**: JSON files with session state

## Performance Notes

### Startup Time

- **Lazy Loading**: Plugin loads on first command use
- **Impact**: < 50ms with lazy.nvim
- **Trigger**: `:Goose` or any goose command
- **Which-key**: Mappings trigger lazy load via commands

### Response Times

- **Gemini 2.0 Flash**: 1-2 seconds for simple queries
- **Claude Code**: 2-3 seconds for complex reasoning
- **Context Size**: Larger context = longer response time
- **Streaming**: Responses stream in real-time

### Context Optimization

- **Use @ mentions**: Include only relevant files
- **Chat vs Auto**: Chat mode is faster (no file operations)
- **Model Selection**: Flash models faster, larger models more accurate
- **Session History**: Long sessions increase context size

## Cost Considerations

### Gemini Free Tier

- **Cost**: $0/month
- **Rate Limits**: 15 requests/minute, 1500 requests/day
- **Context**: 1M tokens (very generous)
- **Best For**: Learning, quick questions, simple tasks

### Claude Code Max Subscription

- **Cost**: $100/month (5x) or $200/month (20x)
- **Billing**: Flat monthly fee, no per-token charges
- **Pass-through**: Uses subscription directly (no API key)
- **Best For**: Production use, complex refactoring, large codebases

### Hybrid Strategy

- **Development**: Use Gemini for 80% of queries (free tier sufficient)
- **Production**: Use Claude Code for complex tasks requiring deep reasoning
- **Cost Savings**: Gemini free tier + Claude Max = predictable monthly cost

## References

### Documentation

- [goose.nvim GitHub](https://github.com/azorng/goose.nvim) - Plugin documentation
- [Goose CLI Docs](https://block.github.io/goose/docs/getting-started/installation) - CLI setup
- [Goose Providers](https://block.github.io/goose/docs/getting-started/providers/) - Provider configuration
- [Claude Code with Max](https://support.claude.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan) - Subscription setup

### Research Reports

- [001-nvim-ai-agent-plugin-integration-analysis.md](../../../.claude/specs/992_nvim_ai_agent_plugin_integration/reports/001-nvim-ai-agent-plugin-integration-analysis.md)
- [revision_goose_nvim_integration_research.md](../../../.claude/specs/992_nvim_ai_agent_plugin_integration/reports/revision_goose_nvim_integration_research.md)
- [002-which-key-ai-mapping-consolidation.md](../../../.claude/specs/992_nvim_ai_agent_plugin_integration/reports/002-which-key-ai-mapping-consolidation.md)

### Implementation Plan

- [001-nvim-ai-agent-plugin-integration-plan.md](../../../.claude/specs/992_nvim_ai_agent_plugin_integration/plans/001-nvim-ai-agent-plugin-integration-plan.md)

## Navigation

- [AI Plugins](../README.md) - Parent directory
- [Neovim Configuration](../../../../README.md) - Root README
