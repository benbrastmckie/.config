# Goose Agent Refactoring Strategy

## Metadata
- **Date**: 2025-12-09
- **Agent**: research-coordinator (direct research)
- **Topic**: Goose Agent Refactoring Strategy
- **Report Type**: pattern recognition and implementation design

## Executive Summary

Refactoring strategy involves extending goose.nvim provider configuration to support multi-backend setup (Gemini + Claude Code), implementing environment-based provider detection, adding health checks for provider validation, and enhancing provider switching UX. Implementation follows Neovim best practices with lazy loading, minimal startup impact, and centralized configuration management.

## Findings

### Finding 1: Current Configuration Gaps
- **Description**: Analysis of current goose configuration reveals single-provider setup with documentation describing multi-provider capabilities
- **Location**: Synthesized from Report 001 (Finding 3) and Report 002 (Finding 1-7)
- **Evidence**:
  - Current: `providers = { google = { "gemini-2.0-flash-exp" } }`
  - Documented but not implemented: Claude Code pass-through integration
  - README describes hybrid strategy without technical implementation
  - Provider switching keybinding (`<leader>ab`) exists but limited utility with single provider
- **Impact**: Gap between documentation and implementation creates confusion. Multi-provider setup requires Lua configuration extension, environment variable handling, and provider validation logic.

### Finding 2: Goose Multi-Model and Lead/Worker Pattern
- **Description**: Goose CLI supports multi-model configuration with lead/worker pattern for cost optimization
- **Location**: Goose documentation on multi-model support
- **Evidence**:
  - Lead model handles complex reasoning, worker model handles simpler tasks
  - Supports cross-provider setups (e.g., Claude for planning, OpenAI for execution)
  - 20+ built-in providers in registry with metadata for required configuration
  - Custom OpenAI-compatible providers via YAML configuration
  - Registry metadata includes required keys, default models, OAuth support status
- **Impact**: Goose CLI architecture natively supports multi-provider scenarios. goose.nvim provider table leverages this by defining available providers for quick switching. Lead/worker pattern not directly applicable to nvim integration (UI-driven, not autonomous task routing), but demonstrates Goose's multi-provider design philosophy.

### Finding 3: lazy.nvim Best Practices for Environment Variables
- **Description**: Neovim plugin configuration patterns for environment variables and lazy loading
- **Location**: Neovim best practices documentation
- **Evidence**:
  - Set leader key before loading plugins: `vim.g.mapleader = " "`
  - Plugin lazy loading via command triggers: `cmd = { "Goose", "GooseOpenInput", "GooseClose" }`
  - Empty keys table prevents plugin-defined keymaps: `keys = {}`
  - Environment variables accessed via `vim.env` or `os.getenv()`
  - Config function runs on plugin load, can check environment and adjust setup
  - lazy-lock.json pins plugin versions for reproducibility
- **Impact**: Current goose configuration follows best practices (lazy loading, empty keys table). Extension should maintain these patterns. Environment variable detection belongs in config function, allowing dynamic provider table generation based on available authentication.

### Finding 4: Provider Health Check Patterns
- **Description**: Neovim health check system for validating plugin dependencies and configuration
- **Location**: Neovim lua-plugin and health check documentation
- **Evidence**:
  - Health checks defined in `lua/goose/health.lua` (if implemented)
  - Called via `:checkhealth goose` command
  - Can check:
    - Goose CLI installation (`vim.fn.executable('goose')`)
    - Provider CLI tools (claude CLI, gemini CLI)
    - Environment variables (`vim.env.GEMINI_API_KEY`, etc.)
    - Authentication status (call provider CLI with status commands)
  - Reports OK, WARN, or ERROR for each check
- **Impact**: Health check integration provides self-documenting provider setup validation. Users can diagnose configuration issues without consulting documentation. Should check both environment variables AND CLI tool availability for pass-through providers.

### Finding 5: Dynamic Provider Configuration Pattern
- **Description**: Strategy for environment-based provider detection and configuration
- **Location**: Synthesized from lazy.nvim patterns and multi-provider requirements
- **Evidence**: Lua pattern for dynamic provider detection:
```lua
config = function()
  local providers = {}

  -- Detect Gemini authentication
  if vim.env.GEMINI_API_KEY or vim.fn.executable('gemini') == 1 then
    providers.google = { "gemini-2.0-flash-exp", "gemini-2.5-pro" }
  end

  -- Detect Claude Code CLI and subscription
  if vim.fn.executable('claude') == 1 then
    -- Check authentication status
    local auth_check = vim.fn.system('claude /status 2>/dev/null')
    if vim.v.shell_error == 0 then
      providers["claude-code"] = { "opus-4", "sonnet-4" }
    end
  end

  require("goose").setup({
    prefered_picker = "telescope",
    default_global_keymaps = false,
    ui = { ... },
    providers = providers,
  })
end,
```
- **Impact**: Dynamic detection enables automatic provider availability based on authentication state. Eliminates manual configuration editing when adding/removing providers. Gracefully handles partial setup (only Gemini or only Claude Code available).

### Finding 6: Provider Switching UX Enhancement
- **Description**: Current `<leader>ab` keybinding calls `:GooseConfigureProvider`, but UX can be enhanced
- **Location**: Analyzed from Report 001 (Finding 4) and goose.nvim capabilities
- **Evidence**:
  - Current: `{ "<leader>ab", "<cmd>GooseConfigureProvider<CR>", desc = "goose backend/provider", icon = "󰒓" }`
  - goose.nvim `providers` table creates selectable provider/model list
  - Telescope picker shows available providers when multiple configured
  - Provider selection persists in session
  - Could display provider status (authenticated, quota remaining, subscription plan)
- **Impact**: Multi-provider configuration automatically enables provider picker on `<leader>ab`. No additional implementation needed for basic switching UX. Enhanced UX (showing auth status, quotas) would require goose.nvim upstream changes or custom Lua wrapper function.

### Finding 7: Configuration File Locations and Precedence
- **Description**: goose CLI and goose.nvim configuration locations and priority
- **Location**: goose documentation and Neovim configuration standards
- **Evidence**:
  - **goose CLI config**: `~/.config/goose/config.yaml` (managed by `goose configure`)
  - **goose CLI sessions**: `~/.config/goose/sessions/` (automatic session persistence)
  - **Gemini .env file**: `.gemini/.env` in project/home directory (auto-loaded by Gemini CLI)
  - **goose.nvim config**: `nvim/lua/neotex/plugins/ai/goose/init.lua` (Neovim plugin spec)
  - **Environment variables**: Shell-level, inherited by Neovim and goose CLI
  - **Precedence**: Environment variables > .env files > config.yaml
- **Impact**: Multi-layer configuration system requires clear documentation. goose CLI configuration (`config.yaml`) sets default provider, but goose.nvim `providers` table overrides for quick switching. Environment variables take highest precedence for authentication. Users may need to coordinate between CLI config and nvim config.

### Finding 8: Refactoring Phases and Risk Mitigation
- **Description**: Proposed phased refactoring approach with backward compatibility
- **Location**: Synthesized from configuration analysis and best practices
- **Evidence**: Three-phase refactoring approach:
  1. **Phase 1 - Provider Configuration Extension**:
     - Extend providers table with claude-code entry
     - Maintain existing google provider
     - No breaking changes (additive only)
     - Test with single provider first (current behavior)
  2. **Phase 2 - Dynamic Provider Detection**:
     - Add environment variable checks in config function
     - Build providers table dynamically
     - Fallback to static config if detection fails
     - Log provider detection results for debugging
  3. **Phase 3 - Health Checks and Documentation**:
     - Implement `:checkhealth goose` validations
     - Update README with multi-provider setup instructions
     - Add troubleshooting section for authentication issues
     - Document environment variable requirements
- **Impact**: Phased approach reduces risk of breaking existing functionality. Each phase independently testable. Early phases provide value (multi-provider support) before completing full enhancement (health checks). Backward compatibility maintained throughout.

## Recommendations

1. **Implement Dynamic Multi-Provider Configuration** (Priority: HIGH):
   ```lua
   -- In nvim/lua/neotex/plugins/ai/goose/init.lua
   config = function()
     local providers = {}

     -- Always include Gemini if API key present or CLI available
     if vim.env.GEMINI_API_KEY or vim.fn.executable('gemini') == 1 then
       providers.google = {
         "gemini-2.0-flash-exp",
         "gemini-2.5-pro"  -- For complex reasoning
       }
     end

     -- Include Claude Code if CLI authenticated and subscription active
     if vim.fn.executable('claude') == 1 then
       local auth_check = vim.fn.system('claude /status 2>/dev/null')
       if vim.v.shell_error == 0 and auth_check:match('[Pp]ro') or auth_check:match('[Mm]ax') then
         providers["claude-code"] = {
           "opus-4",   -- For complex refactoring
           "sonnet-4"  -- For general tasks
         }
       end
     end

     -- Warn if no providers available
     if vim.tbl_count(providers) == 0 then
       vim.notify(
         "goose.nvim: No LLM providers configured. Set GEMINI_API_KEY or install/auth Claude CLI.",
         vim.log.levels.WARN
       )
       -- Provide default to prevent plugin error
       providers.google = { "gemini-2.0-flash-exp" }
     end

     require("goose").setup({
       prefered_picker = "telescope",
       default_global_keymaps = false,
       ui = {
         window_width = 0.35,
         input_height = 0.15,
         fullscreen = false,
         layout = "right",
         floating_height = 0.8,
         display_model = true,
         display_goose_mode = true,
       },
       providers = providers,
     })
   end,
   ```
   **Rationale**: Dynamic detection enables automatic multi-provider support based on authentication state. Maintains backward compatibility with static configuration. Provides helpful warnings when no providers available.

2. **Add Health Check Implementation** (Priority: MEDIUM):
   Create `nvim/lua/goose/health.lua` with comprehensive checks:
   ```lua
   local M = {}
   local health = vim.health

   function M.check()
     health.start("goose.nvim configuration")

     -- Check goose CLI
     if vim.fn.executable('goose') == 1 then
       health.ok("goose CLI found")
     else
       health.error("goose CLI not found in PATH", {
         "Install goose CLI from https://github.com/block/goose",
         "Verify installation: goose --version"
       })
     end

     -- Check Gemini provider
     health.start("Gemini Provider")
     if vim.env.GEMINI_API_KEY then
       health.ok("GEMINI_API_KEY environment variable set")
     elseif vim.fn.executable('gemini') == 1 then
       health.ok("Gemini CLI found (authenticated via Google account)")
     else
       health.warn("Gemini provider not configured", {
         "Set GEMINI_API_KEY environment variable",
         "Or run: gemini auth login"
       })
     end

     -- Check Claude Code provider
     health.start("Claude Code Provider")
     if vim.fn.executable('claude') == 1 then
       local status = vim.fn.system('claude /status 2>/dev/null')
       if vim.v.shell_error == 0 then
         health.ok("Claude CLI authenticated: " .. status:match('[^\n]+'))
       else
         health.warn("Claude CLI not authenticated", {
           "Run: claude auth login"
         })
       end
     else
       health.info("Claude CLI not found (optional)", {
         "Install for Claude Code pass-through support",
         "See: https://support.claude.com/en/articles/11145838"
       })
     end

     -- Check for API key conflicts
     if vim.env.ANTHROPIC_API_KEY and vim.fn.executable('claude') == 1 then
       health.error("ANTHROPIC_API_KEY conflicts with Claude Code subscription", {
         "Unset ANTHROPIC_API_KEY to use subscription (not pay-per-token)",
         "Run: unset ANTHROPIC_API_KEY"
       })
     end
   end

   return M
   ```
   **Rationale**: Health checks provide self-documenting validation. Users can diagnose issues without consulting documentation. Detects common misconfigurations (API key conflicts, missing authentication).

3. **Update README with Multi-Provider Setup** (Priority: HIGH):
   Add comprehensive section after line 106 in README.md:
   ```markdown
   ### Multi-Provider Configuration

   goose.nvim supports multiple LLM providers simultaneously. Provider availability is detected automatically based on authentication.

   #### Automatic Detection

   The plugin checks for:
   - **Gemini**: `GEMINI_API_KEY` environment variable or `gemini` CLI authentication
   - **Claude Code**: `claude` CLI installation and active subscription

   Run `:checkhealth goose` to verify provider configuration.

   #### Environment Setup

   **Gemini (Free Tier)**:
   ```bash
   # Option 1: API Key (recommended for individual developers)
   export GEMINI_API_KEY="your-api-key-here"

   # Option 2: Google Account (for Gemini Code Assist license)
   gemini auth login
   ```

   **Claude Code (Subscription)**:
   ```bash
   # Install Claude CLI (via NixOS or manual)
   claude auth login

   # CRITICAL: Unset API key to use subscription
   unset ANTHROPIC_API_KEY

   # Verify subscription status
   claude /status  # Should show Pro or Max plan
   ```

   #### Provider Persistence

   Use a `.env` file for persistent authentication:
   ```bash
   # Create .gemini/.env in home directory
   echo "GEMINI_API_KEY=your-key" > ~/.gemini/.env
   ```

   Gemini CLI automatically loads this file. For Claude Code, use shell profile (`~/.bashrc`, `~/.zshrc`).

   #### Troubleshooting Multi-Provider

   **No providers available**:
   - Run `:checkhealth goose` to see which providers are detected
   - Check environment variables: `:lua print(vim.env.GEMINI_API_KEY)`
   - Verify CLI tools: `:!which claude` and `:!which gemini`

   **Provider not switching**:
   - Press `<leader>ab` to open provider picker
   - Select desired provider from telescope list
   - Provider persists for current session

   **Claude Code billing instead of subscription**:
   - Check: `:lua print(vim.env.ANTHROPIC_API_KEY)` should return `nil`
   - If set, unset it: `unset ANTHROPIC_API_KEY` in shell
   - Restart Neovim after unsetting
   ```
   **Rationale**: Clear documentation reduces support burden. Step-by-step instructions for each provider. Troubleshooting section addresses common issues. Health check integration reference provides validation path.

4. **Add Provider Status Indicator** (Priority: LOW):
   Enhance provider switching keybinding to show status:
   ```lua
   -- In which-key.lua
   { "<leader>ab", function()
     -- Show provider status before switching
     local providers = {}
     if vim.env.GEMINI_API_KEY or vim.fn.executable('gemini') == 1 then
       table.insert(providers, "✓ Gemini (Free Tier)")
     else
       table.insert(providers, "✗ Gemini (not configured)")
     end

     if vim.fn.executable('claude') == 1 and vim.fn.system('claude /status 2>/dev/null'):match('[Pp]ro\|[Mm]ax') then
       table.insert(providers, "✓ Claude Code (Subscription)")
     else
       table.insert(providers, "✗ Claude Code (not configured)")
     end

     vim.notify("Available providers:\n" .. table.concat(providers, "\n"), vim.log.levels.INFO)
     vim.defer_fn(function()
       vim.cmd("GooseConfigureProvider")
     end, 1000)
   end, desc = "goose backend/provider", icon = "󰒓" },
   ```
   **Rationale**: Pre-switch status display helps users understand provider availability. Visual confirmation before opening picker. Low priority since `:checkhealth goose` provides same information.

5. **Document Cost Optimization Strategy** (Priority: MEDIUM):
   Add section to README after Cost Considerations (line 318):
   ```markdown
   ### Optimizing Multi-Provider Usage

   With Gemini free tier (1,000 requests/day) and Claude Code subscription, optimize costs:

   **Use Gemini For** (Free Tier):
   - Code review and analysis
   - Quick questions and documentation
   - Learning and experimentation
   - Simple refactoring tasks
   - Test generation for small functions

   **Use Claude Code For** (Subscription):
   - Complex refactoring (large files, architectural changes)
   - Deep debugging with multi-file context
   - Production code generation
   - Large codebase analysis
   - Critical security reviews

   **Switching Strategy**:
   1. Start with Gemini for all queries
   2. Switch to Claude Code (`<leader>ab`) when:
      - Gemini response is unsatisfactory
      - Task requires deep reasoning (200K token context)
      - Working on production/critical code
   3. Monitor usage: Gemini has 1,000 daily requests, Claude has 5-hour windows

   **Cost Example**:
   - Gemini: $0/month (free tier sufficient for 80% of queries)
   - Claude Code Max 5x: $100/month (for remaining 20% complex tasks)
   - Total: $100/month vs $300-500/month pay-per-token for same usage
   ```
   **Rationale**: Clear cost optimization guidelines help users maximize free tier. Usage patterns based on task complexity. Switching strategy prevents overuse of paid subscription. Cost comparison justifies subscription investment.

## References

### Internal Configuration Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua` (lines 1-42) - Current plugin configuration
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md` (lines 1-363) - Current documentation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` (lines 362-370) - Provider switching keybinding

### External Documentation
- [Configure LLM Provider (Goose)](https://block.github.io/goose/docs/getting-started/providers/) - Official provider configuration guide
- [Multi-Model Approach in Goose](https://block.github.io/goose/blog/2025/06/16/multi-model-in-goose/) - Lead/worker pattern documentation
- [goose.nvim GitHub Repository](https://github.com/azorng/goose.nvim) - Plugin source and configuration examples
- [Neovim Lua Configuration Guide](https://vonheikemen.github.io/devlog/tools/configuring-neovim-using-lua/) - Lua configuration best practices
- [Neovim Best Practices](https://github.com/lumen-oss/nvim-best-practices) - Modern Lua plugin development standards
- [lazy.nvim Plugin Manager](https://github.com/folke/lazy.nvim) - Lazy loading and plugin management

### Research Reports
- Report 001: Goose Agent Current Configuration Analysis - Current state and gaps
- Report 002: Gemini CLI and Claude Code Integration - Authentication and pricing details
