# Gemini CLI and Claude Code Integration Research

## Metadata
- **Date**: 2025-12-09
- **Agent**: research-coordinator (direct research)
- **Topic**: Gemini CLI and Claude Code Integration
- **Report Type**: best practices and integration patterns

## Executive Summary

Gemini CLI offers a free tier with 1,000 daily requests via Google account authentication, using API keys or service accounts. Claude Code supports Pro ($20/month) and Max plans ($100-$200/month) with pass-through mode integration in goose, allowing subscription-based usage without per-token billing. Both providers support environment variable configuration and can coexist in multi-provider setups.

## Findings

### Finding 1: Gemini CLI Authentication Methods
- **Description**: Gemini CLI supports three authentication methods optimized for different use cases
- **Location**: Google Gemini CLI documentation
- **Evidence**: Authentication options include:
  1. **Google Account Login** (Recommended for individual developers):
     - Free Gemini Code Assist license via personal Google account
     - Access to Gemini 2.5 Pro with 1 million token context window
     - 60 requests per minute, 1,000 requests per day at no charge
  2. **API Key Method**:
     - Obtain key from Google AI Studio
     - Set `GEMINI_API_KEY` environment variable
     - Simpler than OAuth, single-key approach
     - Uses `x-goog-api-key` HTTP header for authentication
  3. **Vertex AI Service Account**:
     - For non-interactive environments, CI/CD pipelines
     - Requires JSON credentials file with "Vertex AI User" role
     - Set `GOOGLE_APPLICATION_CREDENTIALS` to JSON file path
- **Impact**: Multiple authentication paths provide flexibility. API key method aligns with goose.nvim current configuration pattern, while Google account login offers best free tier benefits (1,000 daily requests vs typical API limits).

### Finding 2: Gemini Pricing Tiers and Quotas
- **Description**: Gemini offers free tier, paid subscriptions, and pay-as-you-go options with generous quotas
- **Location**: Gemini CLI documentation on pricing and quotas
- **Evidence**:
  - **Free Tier**: 60 requests/minute, 1,000 requests/day (no charges)
  - **Paid Tiers**: Google AI Pro and AI Ultra (currently for web products only, not API usage)
  - **Pay-As-You-Go**: For professional use and long-running tasks
  - **Important Note**: Google One AI Premium and similar web-based subscription plans do NOT apply to API/CLI usage
- **Impact**: Free tier is sufficient for most development workflows. API/CLI usage separate from web subscription plans means users need API authentication, not web subscriptions. Current goose configuration (`gemini-2.0-flash-exp`) aligns with free tier model availability.

### Finding 3: Claude Code Subscription Plans and Usage Limits
- **Description**: Claude Code offers three subscription tiers with 5-hour usage windows and automatic model switching
- **Location**: Claude support documentation and pricing guides
- **Evidence**:
  - **Pro Plan** ($20/month):
    - Ideal for repositories under 1,000 lines of code
    - ~45 messages or 10-40 prompts per 5-hour window
    - Sonnet 4 model access only
  - **Max 5x** ($100/month):
    - For moderate usage or larger repositories
    - ~225 messages or 50-200 prompts per 5-hour window
    - ~140-280 hours of Sonnet 4, 15-35 hours of Opus 4 weekly
    - Auto-switches Opus 4 → Sonnet 4 at 20% usage
  - **Max 20x** ($200/month):
    - For power users
    - ~900 messages or 200-800 prompts per 5-hour window
    - ~240-480 hours of Sonnet 4, 24-40 hours of Opus 4 weekly
    - Auto-switches Opus 4 → Sonnet 4 at 50% usage
  - **Usage System**: 5-hour rolling windows (not fixed reset times), usage shared between Claude.ai chat and Claude Code
- **Impact**: Subscription-based model provides predictable costs vs pay-per-token. Usage windows reset every 5 hours from first prompt. Max plans provide automatic fallback to faster Sonnet model when quota decreasing, optimizing resource usage.

### Finding 4: Goose CLI Provider Pass-Through Mode
- **Description**: Goose supports pass-through providers for Claude Code, Cursor Agent, and Gemini CLI subscriptions
- **Location**: Goose CLI documentation on pass-through providers
- **Evidence**:
  - Pass-through providers integrate with existing CLI tools (Anthropic, Cursor, Google)
  - Allows using existing subscriptions through goose interface
  - Adds session management, persistence, and workflow integration to CLI tools
  - Automatic filtering of goose extensions from system prompts (Claude Code has own tool ecosystem)
  - Provides session persistence, conversation history export, goose recipes, and scheduled tasks
  - Configuration: Set `GOOSE_PROVIDER=claude-code` environment variable or use `goose configure`
  - Requires Claude CLI installed and authenticated before configuring goose
  - Provider converts goose messages to Claude's JSON format and parses responses
- **Impact**: Pass-through mode eliminates per-token API costs by using subscription directly. Adds goose workflow features (session persistence, recipes) to Claude Code. Requires separate CLI installation and authentication step before goose configuration.

### Finding 5: Claude Code Pass-Through Configuration
- **Description**: Specific configuration requirements for Claude Code provider in goose
- **Location**: Goose CLI provider documentation
- **Evidence**:
  - **Environment Variable**: `GOOSE_PROVIDER=claude-code`
  - **Command Path Variable**: `CLAUDE_CODE_COMMAND` (default: `claude`)
  - **Context Limit**: 200,000 tokens
  - **Authentication**: Must have Claude CLI installed and authenticated first
  - **Subscription Requirement**: Active Claude Code subscription (Pro or Max)
  - **Important**: ANTHROPIC_API_KEY should NOT be set (conflicts with pass-through mode)
- **Impact**: Pass-through configuration is straightforward with environment variables. Key requirement is ensuring `ANTHROPIC_API_KEY` is unset to avoid API billing instead of subscription usage. 200,000 token context limit sufficient for large codebases.

### Finding 6: Multi-Provider Strategy and Cost Optimization
- **Description**: Hybrid provider strategy for cost-effective AI agent usage
- **Location**: Goose README and Claude Code documentation
- **Evidence**: Current goose README (Finding 5 from Report 001) recommends:
  - **Development**: Use Gemini for 80% of queries (free tier sufficient, 1,000 daily requests)
  - **Production**: Use Claude Code for complex tasks requiring deep reasoning
  - **Cost Model**: Gemini free tier + Claude Max = predictable monthly cost ($100-$200)
  - **Provider Switching**: Use `<leader>ab` keybinding or `:GooseConfigureProvider` command
  - **Use Case Alignment**:
    - Gemini: Learning, quick questions, simple tasks, code review, documentation
    - Claude Code: Production refactoring, complex debugging, test generation, large codebases
- **Impact**: Hybrid strategy maximizes free tier usage while maintaining access to premium model for critical tasks. Provider switching capability already documented in current configuration, but not implemented with multiple provider definitions.

### Finding 7: Environment Variable Persistence and Configuration
- **Description**: Gemini CLI supports .env file configuration for persistent credentials
- **Location**: Gemini CLI authentication documentation
- **Evidence**:
  - **Recommended Location**: `.gemini/.env` in project directory or home directory
  - **Search Order**: Current directory upward, then `~/.gemini/.env`, then `~/.env`
  - **Auto-Loading**: Gemini CLI automatically loads variables from first `.env` file found
  - **Environment Variables**:
    - `GEMINI_API_KEY` for API key authentication
    - `GOOGLE_APPLICATION_CREDENTIALS` for service account authentication
  - **Goose Integration**: Goose reads same environment variables when using gemini provider
- **Impact**: `.env` file pattern aligns with standard development workflows. Allows per-project or global authentication configuration. Gemini CLI auto-loading means goose can inherit authentication without additional configuration steps.

## Recommendations

1. **Implement Multi-Provider Configuration**: Extend goose.nvim init.lua providers table to include both Gemini and Claude Code providers. Configuration should support:
   ```lua
   providers = {
     google = { "gemini-2.0-flash-exp" },
     ["claude-code"] = { "opus-4", "sonnet-4" },  -- Pass-through to Claude CLI
   }
   ```
   This enables the documented hybrid strategy without external `goose configure` command.

2. **Add Environment Variable Documentation**: Update goose README with clear instructions for setting up environment variables for multi-provider authentication:
   - `GEMINI_API_KEY` for Gemini provider
   - `GOOSE_PROVIDER` for default provider selection (optional)
   - `CLAUDE_CODE_COMMAND` for custom Claude CLI paths (optional)
   - Emphasize unsetting `ANTHROPIC_API_KEY` to avoid API billing conflicts

3. **Implement Provider Health Checks**: Add provider validation to check:
   - Gemini: `GEMINI_API_KEY` present or Google account authenticated
   - Claude Code: `claude` CLI available in PATH and authenticated (`claude /status` command)
   - Display provider availability status in `:checkhealth goose` output

4. **Create Provider Switching UX**: Enhance `<leader>ab` keybinding to show:
   - Available providers (based on health check)
   - Current active provider
   - Usage information (free tier quota remaining, subscription plan for Claude)
   - Quick switch between providers with visual confirmation

5. **Document Pass-Through Mode Limitations**: Add section to README about pass-through provider caveats from goose documentation:
   - Not all goose features fully supported
   - May have platform or capability limitations
   - Advanced debugging sometimes required
   - Claude Code filters goose extensions (has own tool ecosystem)

6. **Add Cost Tracking and Provider Analytics**: Implement optional usage tracking to help users:
   - Count Gemini free tier usage (toward 1,000 daily limit)
   - Display which provider was used for each session
   - Warn when approaching free tier limits
   - Show estimated Claude Code usage window consumption

## References

### External Documentation
- [Google Gemini CLI GitHub Repository](https://github.com/google-gemini/gemini-cli) - Official Gemini CLI source and documentation
- [Gemini CLI Authentication Setup](https://google-gemini.github.io/gemini-cli/docs/get-started/authentication.html) - Authentication methods and configuration
- [Gemini CLI Quotas and Pricing](https://geminicli.com/docs/quota-and-pricing/) - Free tier limits and paid options
- [Gemini API Key Guide](https://blog.laozhang.ai/technical-tutorial/gemini-api-key-complete-guide-to-googles-ai-api-in-2025/) - Complete API authentication guide
- [Using Claude Code with Pro or Max Plan](https://support.claude.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan) - Official Claude Code subscription documentation
- [Claude Code Pricing Plans Comparison](https://mcpcat.io/guides/which-claude-code-plan-to-choose/) - Pro vs Max 5x vs Max 20x detailed comparison
- [Goose CLI Providers Guide](https://block.github.io/goose/docs/guides/cli-providers/) - Pass-through provider configuration documentation

### Internal References
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua` (lines 32-35) - Current provider configuration
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md` (lines 68-106) - Backend configuration instructions
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md` (lines 318-338) - Cost considerations and hybrid strategy
