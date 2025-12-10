# goose.nvim Integration

AI-assisted coding with Goose agent backend supporting multiple providers (Gemini CLI, Claude Code).

## Purpose

This module integrates [goose.nvim](https://github.com/azorng/goose.nvim) with the Neovim configuration, providing seamless AI agent capabilities with persistent sessions, automatic context capture, and native diff review.

## Features

- **Persistent Sessions**: Conversations tied to workspace, preserved across Neovim restarts
- **Automatic Context**: Captures current file, selections, and editor state
- **Diff View**: Review and revert AI-generated changes before applying
- **Provider-Agnostic**: Switch between Gemini CLI (default) and Claude Code (Max subscription)
- **Lazy Loading**: No impact on Neovim startup time
- **Integrated Keybindings**: All AI tools under `<leader>a` namespace in which-key.lua

## Configuration

### Split Window Mode (GitHub Issue #82)

As of 2025-12-09, goose.nvim uses split window mode instead of floating windows for better integration with Neovim's standard window navigation workflow.

**Key Benefits**:
- Seamless integration with `<C-h/j/k/l>` split navigation keybindings
- Consistent UX with other sidebar plugins (neo-tree, toggleterm, lean.nvim)
- Works with standard Neovim window management commands (`:wincmd`, `:split`, etc.)
- Participates in Neovim's window layout system automatically

**Window Layout**:
```
┌───────────────────┬──────────────┐
│                   │              │
│   Main Editor     │   Goose      │
│   Window          │   Output     │
│                   │   (35%)      │
│                   ├──────────────┤
│                   │   Goose      │
│                   │   Input      │
│                   │   (15%)      │
└───────────────────┴──────────────┘
```

**Configuration Options**:
```lua
ui = {
  window_type = "split",     -- Split window mode (not floating)
  window_width = 0.35,       -- 35% of screen width
  input_height = 0.15,       -- 15% for input area
  layout = "right",          -- Right sidebar ("left" also supported)
  fullscreen = false,
  display_model = true,
  display_goose_mode = true,
}
```

**Navigation Integration**:
- `<C-l>`: Move from main editor to goose output window
- `<C-h>`: Move from goose to main editor
- `<C-j>`: Move down (e.g., goose output → goose input)
- `<C-k>`: Move up (e.g., goose input → goose output)

**Multi-Sidebar Support**:
```
┌──────────┬───────────────────┬──────────────┐
│ neo-tree │   Main Editor     │   Goose      │
│ (left)   │                   │   (right)    │
└──────────┴───────────────────┴──────────────┘
```

Navigation flows naturally: `neo-tree` ← `<C-h/l>` → `main` ← `<C-h/l>` → `goose`

**Reference**: https://github.com/azorng/goose.nvim/issues/82

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
      default_mode = "auto",           -- Full agent capabilities by default
      ui = {
        window_type = "split",     -- Split window mode (not floating)
        window_width = 0.35,       -- 35% of screen width
        input_height = 0.15,       -- 15% for input area
        layout = "right",          -- Right sidebar positioning
        fullscreen = false,
        display_model = true,
        display_goose_mode = true,
      },
      providers = {
        google = { "gemini-3-pro-preview-11-2025" },
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
| `<leader>ag` | Normal | Toggle goose chat interface |
| `<leader>ag` | Visual | Send selection to goose with prompt |
| `<leader>ai` | Normal | Focus goose input window |
| `<leader>ao` | Normal | Focus goose output window |
| `<leader>af` | Normal | Toggle goose fullscreen mode |
| `<leader>ad` | Normal | Open goose diff view |
| `<leader>aA` | Normal | Switch to auto mode (full agent) |
| `<leader>aC` | Normal | Switch to chat mode (no file edits) |
| `<leader>aR` | Normal | Run recipe (Telescope picker) |
| `<leader>ab` | Normal | Switch goose backend/provider |
| `<leader>aq` | Normal | Close goose interface |

## Recipe Picker

The recipe picker (`<leader>aR`) provides a Telescope-based interface for discovering, previewing, and executing Goose recipes from both project-local and global directories.

### Features

- **Dual-Location Discovery**: Scans both `.goose/recipes/` (project) and `~/.config/goose/recipes/` (global)
- **Rich Preview**: Shows recipe name, description, parameters, subrecipes, and execution command
- **Parameter Prompting**: Interactive prompts with type validation (string, number, boolean)
- **Context-Aware Keybindings**: Multiple actions available within the picker
- **Location Labels**: Distinguishes `[Project]` vs `[Global]` recipes

### Picker Keybindings

When the recipe picker is open:

| Key | Action | Description |
|-----|--------|-------------|
| `<CR>` | Execute | Run selected recipe with parameter prompts |
| `<C-e>` | Edit | Open recipe YAML file in buffer for editing |
| `<C-p>` | Preview | Run recipe in preview mode (--explain flag) |
| `<C-v>` | Validate | Validate recipe syntax using goose CLI |
| `<C-r>` | Refresh | Reload recipe list without closing picker |
| `<C-u>` | Scroll Up | Scroll preview window up (Telescope native) |
| `<C-d>` | Scroll Down | Scroll preview window down (Telescope native) |

### Recipe Discovery Paths

The picker searches for recipes in the following order:

1. **Project Recipes**: `.goose/recipes/` (searches upward from current directory)
2. **Global Recipes**: `~/.config/goose/recipes/` (user-wide recipes)

Project recipes take priority when duplicate names exist.

### Usage Example

1. Press `<leader>aR` to open the recipe picker
2. Navigate recipes with arrow keys or fuzzy search
3. Review recipe details in the preview window
4. Press `<CR>` to execute the selected recipe
5. Enter parameter values when prompted (with type validation)
6. Recipe executes in ToggleTerm with interactive mode

### Parameter Types

The picker validates parameter types during prompting:

- **string**: Non-empty text value
- **number**: Numeric value (validated via `tonumber()`)
- **boolean**: `true`/`false`/`yes`/`no`/`1`/`0`

### Direct Invocation

You can also invoke the picker programmatically:

```lua
-- Open recipe picker
require("neotex.plugins.ai.goose.picker").show_recipe_picker()

-- Or use the user command
:GooseRecipes
```

### Architecture

The picker module is organized into focused components:

- **init.lua**: Telescope integration and keybinding orchestration
- **discovery.lua**: Recipe file discovery from project and global directories
- **metadata.lua**: YAML parsing for recipe metadata extraction
- **previewer.lua**: Custom Telescope previewer for recipe details
- **execution.lua**: Parameter prompting, validation, and ToggleTerm execution

See [picker/README.md](picker/README.md) for complete API documentation.

### Backend Configuration

#### Gemini CLI (Default)

1. Install Gemini CLI: `npm install -g @anthropic-ai/gemini-cli` or via your package manager
2. Authenticate:
   ```bash
   gemini auth login
   # Follow browser authentication flow
   ```
3. Configure Goose:
   ```bash
   goose configure
   # Select: Gemini CLI
   # Model: gemini-3.0-pro (or your preferred model)
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

## Multi-Provider Configuration

The goose.nvim integration automatically detects available providers based on authentication and enables seamless switching between Gemini CLI and Claude Code.

### Automatic Detection

The configuration dynamically detects providers on plugin load:

1. **Gemini CLI Detection**:
   - Checks `gemini` CLI authentication (Google account)
   - Respects `GEMINI_MODEL` environment variable for model override

2. **Claude Code Detection**:
   - Checks `claude` CLI installation and authentication
   - Validates Pro/Max subscription via `claude /status`
   - Excludes if only Free tier or no subscription

3. **Fallback Behavior**:
   - If no providers detected, shows warning with setup instructions
   - Use `:checkhealth goose` to diagnose configuration issues

### Setup Instructions

#### Gemini CLI Setup (Default)

1. Install Gemini CLI via your package manager or npm
2. Authenticate:
   ```bash
   gemini auth login
   # Follow browser authentication flow
   ```
3. Verify with `:checkhealth goose`

**Model Override** (Optional):
```bash
export GEMINI_MODEL="gemini-3.0-pro"
# Add to ~/.bashrc or ~/.zshrc for persistence
```

#### Claude Code Setup (Pro/Max Subscription)

**Prerequisites**: Active Claude Pro or Max subscription

1. Subscribe at [claude.ai/upgrade](https://claude.ai/upgrade)
2. Install claude CLI (NixOS: already installed)
3. Authenticate:
   ```bash
   claude auth login
   # Follow browser authentication flow
   ```
4. **CRITICAL**: Ensure `ANTHROPIC_API_KEY` is not set (causes API billing conflict):
   ```bash
   # Check for API key
   env | grep ANTHROPIC_API_KEY

   # If found, unset it
   unset ANTHROPIC_API_KEY
   ```
5. Verify subscription status:
   ```bash
   claude /status
   # Should show "Logged in" with Pro or Max subscription
   ```
6. Restart Neovim and verify with `:checkhealth goose`

#### Environment Persistence

**Fish Shell** (`~/.config/fish/conf.d/private.fish`):
```fish
# Gemini CLI Configuration (optional model override)
# set -gx GEMINI_MODEL "gemini-3.0-pro"

# Claude Code Configuration
# Ensure ANTHROPIC_API_KEY is NOT set (conflicts with subscription)
# set -e ANTHROPIC_API_KEY  # Uncomment if previously set
```

**Bash/Zsh** (`~/.bashrc` or `~/.zshrc`):
```bash
# Gemini CLI Configuration (optional model override)
# export GEMINI_MODEL="gemini-3.0-pro"

# Claude Code Configuration
# Ensure ANTHROPIC_API_KEY is NOT set (conflicts with subscription)
# unset ANTHROPIC_API_KEY  # Uncomment if previously set
```

**Verification Commands**:
```bash
# Check environment variables
env | grep GEMINI
env | grep ANTHROPIC

# Verify CLIs
gemini --version
claude /status

# Test in Neovim
nvim
:checkhealth goose
```

### Troubleshooting Multi-Provider

#### No Providers Detected

**Issue**: Warning "Goose: No providers configured" on plugin load

**Solution**:
1. Run `:checkhealth goose` to see detailed diagnostics
2. For Gemini CLI: Authenticate with `gemini auth login`
3. For Claude Code: Install `claude` CLI and run `claude auth login`
4. Verify CLIs: `gemini --version` and `claude /status`
5. Restart Neovim after configuration changes

#### Provider Not Switching

**Issue**: `<leader>ab` shows only one provider despite both configured

**Solution**:
1. Check health status: `:checkhealth goose`
2. Verify both providers show OK status
3. For Claude Code: Ensure Pro/Max subscription active (`claude /status`)
4. Reload Neovim configuration: `:source $MYVIMRC`
5. Test provider detection: `:lua print(vim.inspect(require('goose').config.providers))`

#### API Key Conflict (Claude Code)

**Issue**: Claude usage shows API billing instead of subscription

**Solution**:
1. Check for API key: `env | grep ANTHROPIC_API_KEY`
2. If found, this overrides subscription billing
3. Unset the variable:
   ```bash
   unset ANTHROPIC_API_KEY
   ```
4. Remove from shell profile (edit ~/.bashrc or ~/.zshrc)
5. Re-authenticate: `claude auth login`
6. Verify subscription: `claude /status` (should show Pro/Max)
7. Run `:checkhealth goose` (should show ERROR if API key still set)

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

### Auto Mode (Default)

- Full agent capabilities with file editing
- Can create, modify, and delete files
- Executes tools and extensions autonomously
- Review changes via diff view (`<leader>ad`)
- Switch: `:GooseModeAuto` or `/mode auto`

### Chat Mode

- Conversation-only, no file edits
- Safe for exploratory questions
- Faster responses
- Switch: `:GooseModeChat` or `/mode chat`

## Recipes

Recipes are reusable workflow configurations that package instructions, extensions, and parameters into shareable templates. They enable repeatable agentic workflows for common tasks.

### Recipe Workflow Overview

**Important**: The goose.nvim floating window (`<leader>ag`) is for interactive chat only. Recipes must be run via CLI or the recipe picker.

| Action | Method |
|--------|--------|
| **Interactive chat** | Neovim: `<leader>ag` (floating window) |
| **Run recipe from Neovim** | Neovim: `<leader>aR` (picker + ToggleTerm) |
| **Run recipe from CLI** | Terminal: `goose run --recipe file.yaml` |
| **Run recipe interactively** | Terminal: `goose run --recipe file.yaml --interactive` |
| **Save current chat as recipe** | In-session: `/recipe filename.yaml` |

### Running Recipes from Neovim

Press `<leader>aR` to open the recipe picker:
1. Shows all `.yaml` files in `.goose/recipes/`
2. Select a recipe from the list
3. Optionally enter parameters (e.g., `feature_description=Add dark mode,complexity=3`)
4. Recipe runs in ToggleTerm with `--interactive` flag

This opens goose in a terminal window where you can interact with the recipe execution.

### Running Recipes (CLI)

Recipes must be launched from the command line. Use a terminal split or run before opening Neovim:

```bash
# Run recipe (executes and exits)
goose run --recipe ~/.config/goose/recipes/code-review.yaml

# Run recipe interactively (stays in session after recipe completes)
goose run --recipe code-review.yaml --interactive

# Run with parameters
goose run --recipe code-review.yaml --params focus_area=security

# Preview what a recipe will do
goose run --recipe code-review.yaml --explain

# Validate recipe syntax
goose recipe validate code-review.yaml
```

### Creating Recipes from Chat

While in an active goose session (via `<leader>ag` or CLI), you can save your current conversation as a reusable recipe:

```
/recipe                        # Saves to ./recipe.yaml
/recipe my-workflow.yaml       # Saves to custom filename
```

This captures your conversation's instructions, context, and workflow into a YAML file you can rerun later.

### Slash Commands in Session

These commands work in the goose floating window input:

| Command | Description |
|---------|-------------|
| `/mode auto` | Switch to auto mode (file editing enabled) |
| `/mode chat` | Switch to chat mode (conversation only) |
| `/recipe [file]` | Save current conversation as recipe |
| `/clear` | Clear chat history |
| `/summarize` | Summarize conversation to reduce context |
| `/plan [message]` | Enter planning mode |
| `/endplan` | Exit planning mode |
| `/exit` | End session |
| `/?` | Show help |

### Recipe Structure

```yaml
version: "1.0.0"
title: "Code Review Assistant"
description: "Automated code review with best practices"
instructions: "Review code focusing on {{ focus_area }}"
prompt: "Analyze the repository"
parameters:
  - key: focus_area
    input_type: string
    requirement: required
    description: "Review focus (performance, security, etc.)"
extensions:
  - type: builtin
    name: developer
```

### Recipe CLI Commands

| Command | Description |
|---------|-------------|
| `goose recipe list` | List available recipes |
| `goose recipe validate <file>` | Validate recipe syntax |
| `goose recipe deeplink <file>` | Generate shareable link |
| `goose recipe open <file>` | Open in Goose Desktop |

### Recipe Storage

- **Project recipes**: `.goose/recipes/` (project-specific workflows)
- **Global recipes**: `~/.config/goose/recipes/`
- **Scheduled recipes**: `~/.local/share/goose/scheduled_recipes/`
- **Team recipes**: Set `GOOSE_RECIPE_GITHUB_REPO=user/repo` to share via GitHub

### Testing Project Recipes

For projects with recipes in `.goose/recipes/`, use this workflow:

**List available recipes**:
```bash
# From project root
ls -la .goose/recipes/
goose recipe list
```

**Preview a recipe before running**:
```bash
goose run --recipe .goose/recipes/create-plan.yaml --explain
```

**Run a recipe**:
```bash
# Run and exit when complete
goose run --recipe .goose/recipes/create-plan.yaml

# Run interactively (continue chatting after recipe completes)
goose run --recipe .goose/recipes/create-plan.yaml --interactive

# Run with parameters
goose run --recipe .goose/recipes/create-plan.yaml \
  --params feature_description="Add user authentication" \
  --params complexity=3
```

**Validate recipe syntax**:
```bash
goose recipe validate .goose/recipes/create-plan.yaml
```

**Test subrecipes**:
```bash
# Subrecipes are in .goose/recipes/subrecipes/
goose run --recipe .goose/recipes/subrecipes/research-specialist.yaml --explain
```

**Debug recipe execution**:
```bash
# Enable debug output
goose run --recipe .goose/recipes/create-plan.yaml --debug

# Limit iterations for testing
goose run --recipe .goose/recipes/create-plan.yaml --max-turns 5
```

**Example: Testing the create-plan workflow**:
```bash
cd ~/.config  # or your project root

# 1. Preview what the recipe will do
goose run --recipe .goose/recipes/create-plan.yaml --explain

# 2. Run interactively to observe and intervene
goose run --recipe .goose/recipes/create-plan.yaml --interactive \
  --params feature_description="Implement dark mode toggle"

# 3. Check outputs in specs/ directory
ls -la .claude/specs/
```

### Creating Recipes from Scratch

1. Create a YAML file with required fields (`version`, `title`, `description`)
2. Add `instructions` or `prompt` (at least one required)
3. Define `parameters` for dynamic values using `{{ param_name }}` syntax
4. Specify required `extensions` (MCP servers)
5. Validate with `goose recipe validate <file>`

### Typical Workflows

**Ad-hoc Chat** (most common):
1. Press `<leader>ag` to open goose in Neovim
2. Type questions/requests in the input window
3. Review changes with `<leader>ad` (diff view)

**Recipe-Based Workflow**:
1. Create or obtain a recipe YAML file
2. Run from terminal: `goose run --recipe file.yaml --interactive`
3. Recipe executes its instructions, then you can continue chatting

**Save Workflow as Recipe**:
1. Have a productive goose session in Neovim
2. Type `/recipe my-workflow.yaml` to save it
3. Reuse later: `goose run --recipe my-workflow.yaml`

### Recipe Use Cases

- **Code Reviews**: Consistent review process across team
- **Documentation**: Generate docs with standard format
- **Security Audits**: Repeatable security analysis
- **Onboarding**: Automate environment setup
- **Testing**: Generate test suites with consistent patterns

## Troubleshooting

### Split Window Mode Issues

#### goose Opens as Floating Window

**Issue**: Split mode not activating despite `window_type = "split"` configuration.

**Solution**:
1. Verify configuration: `grep -n "window_type" ~/.config/nvim/lua/neotex/plugins/ai/goose/init.lua`
2. Expected output: `window_type = "split"`
3. Restart Neovim completely: `:qa` and reopen
4. Check goose.nvim version supports split mode (requires recent version)
5. Force reload plugin: `:Lazy reload goose.nvim`
6. Verify with: `:lua print(vim.inspect(require('goose').config.ui))`

#### Split Navigation Not Working

**Issue**: `<C-h/j/k/l>` keybindings don't move between windows with goose open.

**Solution**:
1. Check keybinding configuration: `:verbose map <C-h>`
   - Expected: Shows `<C-w>h` mapping in normal mode
2. Test navigation manually: `:wincmd l` (should move to right window)
3. Check for plugin conflicts: `:verbose map <C-l>`
   - Look for other plugins overriding navigation keys
4. Verify goose windows are splits, not floating:
   ```vim
   :lua print(vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative)
   " Expected: empty string (indicates split window)
   ```
5. Check keymaps file loaded: `:scriptnames | grep keymaps.lua`

#### Window Separator Not Visible

**Issue**: Can't see separation line between goose output and input windows.

**Solution**:
1. Check autocmd loaded:
   ```vim
   :autocmd FileType goose-input
   " Should show winbar autocmd
   ```
2. Verify `WinSeparator` highlight group defined:
   ```vim
   :highlight WinSeparator
   " Should show color configuration
   ```
3. Try different colorscheme: `:colorscheme <another-theme>`
4. Manually set highlight: `:highlight WinSeparator guifg=#444444`
5. Check winbar in goose input window:
   ```vim
   " Focus goose input window, then:
   :set winbar?
   " Should show box-drawing character separator
   ```

#### Multi-Sidebar Layout Conflicts

**Issue**: goose split conflicts with neo-tree or other sidebars.

**Solution**:
1. Open sidebars in correct order:
   - Left sidebar first (neo-tree): `:Neotree toggle`
   - Right sidebar second (goose): `<leader>ag`
2. Check window layout: `:lua print(vim.fn.winnr('$'))` (total window count)
3. Verify splitright option: `:set splitright?` (should be `splitright`)
4. Test without other sidebars: Close neo-tree and test goose alone
5. Check for custom window management plugins that might interfere

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
Provider: Gemini CLI
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

- **Gemini CLI**: 2-4 seconds for complex queries
- **Claude Code**: 2-3 seconds for complex reasoning
- **Context Size**: Larger context = longer response time
- **Streaming**: Responses stream in real-time

### Context Optimization

- **Use @ mentions**: Include only relevant files
- **Chat vs Auto**: Chat mode is faster (no file operations)
- **Model Selection**: Flash models faster, larger models more accurate
- **Session History**: Long sessions increase context size

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

### Implementation Plans

- [001-nvim-ai-agent-plugin-integration-plan.md](../../../.claude/specs/992_nvim_ai_agent_plugin_integration/plans/001-nvim-ai-agent-plugin-integration-plan.md) - Initial goose.nvim integration
- [001-goose-sidebar-split-refactor-plan.md](../../../.claude/specs/057_goose_sidebar_split_refactor/plans/001-goose-sidebar-split-refactor-plan.md) - Split window mode implementation (Issue #82)

## Navigation

- [AI Plugins](../README.md) - Parent directory
- [Neovim Configuration](../../../../README.md) - Root README
