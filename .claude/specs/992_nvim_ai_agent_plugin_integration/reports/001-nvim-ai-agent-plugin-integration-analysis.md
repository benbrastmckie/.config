# Neovim AI Agent Plugin Integration Research Report

**Research Date**: 2025-12-05
**Research Complexity**: 3
**Objective**: Research Neovim integration options for Gemini CLI, Goose, OpenCode, and other AI coding agents that support Anthropic Max plan and Gemini APIs

---

## Executive Summary

This research identifies multiple viable options for integrating AI coding agents into Neovim with support for both Anthropic (Claude) and Google Gemini APIs. The landscape has matured significantly in 2025, with several production-ready solutions available.

**Top Recommendations**:
1. **codecompanion.nvim** - Best multi-provider solution with ACP support
2. **avante.nvim** - Best Cursor-like inline editing experience
3. **goose.nvim** - Best for autonomous agent workflows
4. **opencode.nvim** - Best terminal-integrated solution

All recommended options support both Anthropic Claude API and Google Gemini API, though some have limitations regarding the Anthropic Max subscription plan vs. API access.

---

## Critical Distinction: Anthropic Max Plan vs. API Access

### Important Clarification

**The Anthropic Max plan ($100-$200/month) is separate from API access and does not reduce or replace API costs.** Organizations using the API still pay token-based rates even if team members hold Max or Pro subscriptions.

- **Max Plan**: $100 (5× usage) or $200 (20× usage) for web/desktop Claude usage
- **API Pricing**: $0.25-$75 per million tokens depending on model
- **Claude Code Rate Limits**: Enforced since August 2025 for heavy users

**Impact on Integration**: Most Neovim plugins use API access directly, NOT the Max subscription. To use Anthropic models, you need an API key and will pay per-token rates regardless of your subscription status.

**Claude Code Adapter**: Some plugins (avante.nvim, codecompanion.nvim) support Claude Code via Agent Client Protocol (ACP), which does leverage the Max subscription through the claude-code CLI tool.

---

## Option 1: Gemini CLI Direct Integration

### Available Plugins

#### 1.1 marcinjahn/gemini-cli.nvim
- **Repository**: https://github.com/marcinjahn/gemini-cli.nvim
- **Created**: June 30, 2025
- **License**: MIT

**Features**:
- Gemini CLI terminal integration within Neovim
- Quick commands to add current buffer files using `@` syntax
- Send current buffer diagnostics to Gemini CLI
- Command selection UI with fuzzy search
- Fully documented Lua API for programmatic interaction
- Adapted from nvim-aider

**Pros**:
- Purpose-built for Gemini CLI
- Active recent development
- Clean API design

**Cons**:
- Limited to Gemini only (no Anthropic support)
- Requires separate Gemini CLI installation

#### 1.2 jonroosevelt/gemini-cli.nvim
- **Repository**: https://github.com/jonroosevelt/gemini-cli.nvim

**Features**:
- Toggle Gemini CLI in split window (vertical/horizontal)
- Automatically checks if gemini CLI is installed on startup
- Prompts to install gemini CLI if missing
- Sets EDITOR environment variable to nvim for Gemini CLI session
- Visual mode support: Select text and use `<leader>sg` to send to Gemini CLI

**Pros**:
- Simple, focused implementation
- Good installation automation

**Cons**:
- Limited to Gemini only
- Less feature-rich than marcinjahn version

#### 1.3 kiddos/gemini.nvim
- **Repository**: https://github.com/kiddos/gemini.nvim

**Features**:
- Direct Google Gemini API integration (not CLI-based)
- Code suggestions
- Unit test generation
- Code review commands
- Code explanation commands

**Pros**:
- Direct API integration (no CLI dependency)
- Good feature coverage

**Cons**:
- Gemini-only
- Less flexible than multi-provider solutions

### Recommendation: Gemini CLI Integration

**Verdict**: While these plugins work well, they're limited to Gemini only. Better to use a multi-provider solution that includes Gemini support unless you specifically only want Gemini.

---

## Option 2: Goose AI Agent Integration

### About Goose

**Repository**: https://github.com/block/goose
**Developer**: Block (Jack Dorsey's company)
**Type**: Open source, extensible AI agent

Goose is an on-machine AI agent capable of automating complex development tasks from start to finish. More than just code suggestions, Goose can:
- Build entire projects from scratch
- Write and execute code
- Debug failures
- Orchestrate workflows
- Interact with external APIs autonomously

### LLM Provider Support

Goose supports **multiple providers** including:
- **Anthropic** (Claude models)
- **Google Gemini** (with free tier available)
- **OpenAI** (GPT models)
- **Databricks**
- **Groq**
- **Ollama** (local models)
- **OpenRouter**
- **Azure OpenAI**
- **Amazon Bedrock**

**Multi-model configuration**: Optimize performance and cost by using different models for different tasks.

**Recommended models**: Goose works best with Claude 4 models due to strong tool-calling capabilities.

### Neovim Integration: goose.nvim

**Repository**: https://github.com/azorng/goose.nvim
**GitHub Stars**: ~263 (newer project)

**Features**:
- Seamless Neovim integration with Goose AI agent
- Chat interface with editor context capture
- Persistent sessions tied to workspace
- Continuous conversations with AI assistant
- Quick model switching between providers

**Provider Support**:
- anthropic
- azure
- bedrock
- databricks
- google (Gemini)
- groq
- ollama
- openai
- openrouter

**Requirements**:
- Neovim 0.8.0+
- Goose CLI properly configured
- Access to at least one LLM provider (Anthropic, OpenAI, Gemini, etc.)

### ACP Integration via codecompanion.nvim and avante.nvim

Both codecompanion.nvim and avante.nvim support Goose via Agent Client Protocol (ACP), allowing you to use Goose as an agent without a dedicated plugin.

### Advantages

1. **True Agent Capabilities**: Goes beyond code suggestions to autonomous task execution
2. **Multi-Provider Flexibility**: Easy switching between Anthropic, Gemini, and others
3. **Free Tier Option**: Gemini offers generous free tier for experimentation
4. **Open Source**: Fully extensible and customizable
5. **Active Development**: Backed by Block with ongoing improvements

### Disadvantages

1. **Complexity**: More setup required than simpler plugins
2. **Resource Usage**: Autonomous agents can consume more tokens
3. **Maturity**: Neovim integration (goose.nvim) is newer (~263 stars vs 15k for avante)
4. **Learning Curve**: Agent workflows require different mental model than autocomplete

### Recommendation: Goose

**Verdict**: **Excellent choice for autonomous agent workflows**. The multi-provider support (including both Anthropic and Gemini) makes it ideal for your requirements. However, consider using it via codecompanion.nvim's ACP support rather than the standalone goose.nvim plugin for better integration.

---

## Option 3: OpenCode AI Agent Integration

### About OpenCode

**Repository**: https://github.com/opencode-ai/opencode
**Website**: https://opencode.ai
**Developer**: SST (formerly Serverless Stack)
**Type**: Open source AI coding agent built for the terminal

OpenCode is "The AI coding agent built for the terminal" with focus on TUI and seamless integration with Neovim and Tmux. Built by Neovim users for terminal-first workflows.

### LLM Provider Support

OpenCode supports **75+ LLM providers** via AI SDK and Models.dev:
- **Anthropic** (Claude) - Can log in with Claude Pro/Max account
- **Google Gemini**
- **OpenAI**
- **AWS Bedrock**
- **Groq**
- **Azure OpenAI**
- **OpenRouter**
- **Local models** via Ollama

**Authentication**:
- API keys stored securely in `~/.local/share/opencode/auth.json`
- Auto-detects environment variables (OPENAI_API_KEY, ANTHROPIC_API_KEY, etc.)
- Supports `.env` files in project root
- `/connect` command for managing provider credentials

**Subscription Integration**: You can log in with Anthropic to use your Claude Pro or Max account (not just API access).

### Neovim Integration Options

#### 3.1 NickvanDyke/opencode.nvim
**Repository**: https://github.com/NickvanDyke/opencode.nvim

**Features**:
- Auto-connects to any opencode running inside Neovim's CWD
- Provides integrated instance if none running
- Input prompts with completions, highlights, and normal-mode support
- Select prompts from library and define custom ones
- Inject relevant editor context (buffer, cursor, selection, diagnostics)
- Real-time buffer reload when opencode edits files
- Monitor opencode's state via statusline component

**Pros**:
- Most feature-complete opencode integration
- Strong editor-aware context injection
- Good UI/UX design

#### 3.2 sudo-tee/opencode.nvim
**Repository**: https://github.com/sudo-tee/opencode.nvim

**Features**:
- Bridge between Neovim and opencode AI agent
- Chat interface with editor context capture
- Two built-in agents:
  - **Build**: Full development with all tools enabled
  - **Plan**: Planning and analysis without file changes
- Press Alt+M to switch agents during session
- `@` trigger for file picker (supports fzf-lua, telescope, mini.pick, snacks)

**Pros**:
- Dual-agent approach (Build vs Plan)
- Good file picker integrations
- Focused on practical workflows

#### 3.3 cousine/opencode-context.nvim
**Repository**: https://github.com/cousine/opencode-context.nvim

**Features**:
- Interacts with opencode TUI session in tmux pane
- Direct tmux integration
- Auto-detects running opencode pane
- Sends keystrokes via `tmux send-keys`

**Pros**:
- Perfect for tmux users
- Keeps opencode visible in separate pane
- Minimal overhead

#### 3.4 ACP Integration

codecompanion.nvim and avante.nvim both support opencode via Agent Client Protocol (ACP).

### Tmux + Neovim Workflow

OpenCode's standout feature is **seamless Tmux integration**:
- Edit code in Neovim in one pane
- Run your project in another pane
- OpenCode AI agent in third pane
- All panes communicate bidirectionally

This "hybrid approach" is praised by many users as more productive than trying to do everything inside Neovim.

### Advantages

1. **Terminal-First Design**: Built specifically for terminal/Neovim workflows
2. **Tmux Integration**: Superior multi-pane workflow
3. **75+ Provider Support**: Widest provider compatibility
4. **Subscription Support**: Can use Claude Pro/Max subscription (not just API)
5. **Free Models Available**: Includes free model options
6. **Strong Authentication**: Secure credential storage with environment variable auto-detection

### Disadvantages

1. **Additional Tool**: Requires separate OpenCode installation
2. **Complexity**: More moving parts than integrated plugins
3. **Plugin Fragmentation**: Multiple competing Neovim plugins
4. **Less Polished**: Community reports it's "not perfect" with occasional issues

### Recommendation: OpenCode

**Verdict**: **Best for terminal-first workflows**, especially if you use Tmux. The 75+ provider support and Claude subscription integration are strong advantages. Consider the **NickvanDyke/opencode.nvim** plugin for best Neovim integration, or run OpenCode in a tmux pane alongside Neovim for maximum flexibility.

---

## Option 4: Multi-Provider Neovim Plugins

These plugins support multiple AI providers including both Anthropic and Gemini, providing the most flexibility.

### 4.1 codecompanion.nvim ⭐ TOP RECOMMENDATION

**Repository**: https://github.com/olimorris/codecompanion.nvim
**GitHub Stars**: ~4,500
**Description**: "✨ AI Coding, Vim Style"

#### Provider Support

**Direct API Support**:
- Anthropic (Claude)
- Google Gemini
- Copilot
- GitHub Models
- DeepSeek
- Mistral AI
- Novita
- Ollama
- OpenAI
- Azure OpenAI
- HuggingFace
- xAI

**Agent Client Protocol (ACP) Support**:
- Augment Code
- Cagent (Docker)
- Claude Code
- Codex
- Gemini CLI
- Goose
- Kimi CLI
- opencode

#### Key Features

1. **Multi-Provider Flexibility**: Mix and match providers per strategy
   - Example: Anthropic for chat, Copilot for inline, DeepSeek for cmd
2. **Chat Interface**: Resizable floating panel with conversation history
3. **Inline Edits**: Visual-mode mappings for quick edits
4. **Slash Commands**: Modular approach with extensible commands
5. **Context Profiles**: @ "profiles" for passing buffers, viewports, etc.
6. **Memory Files**: Supports CLAUDE.md, .cursor/rules, custom rules
7. **Native Super Diff**: Track agent edits with diff view
8. **ACP Integration**: Work with external agents seamlessly

#### Configuration Flexibility

- **Different adapters per strategy**: Chat vs inline vs cmd can use different models
- **Environment variables**: Plain names like "GEMINI_API_KEY" auto-detected
- **Command execution**: `cmd:op read op://personal/Gemini/credential` for 1Password integration
- **Memory support**: Project-specific rules and context

#### User Reviews

**Pros**:
- "Pragmatic, batteries-included toolkit"
- "Easier to pass buffers, viewports, etc."
- "Users love CodeCompanion for its documentation and simplicity"
- "Like Zed AI experience" (vs Avante being "like Cursor")
- Deep integration with Neovim native features (buffer management, LSP)
- Free tier option via GitHub Models

**Cons**:
- Fewer GitHub stars than Avante (~4.5k vs 15k)
- Chat-based workflow may not suit everyone

#### Advantages

1. **Most Comprehensive Provider Support**: 12+ direct providers + 8+ ACP agents
2. **Flexible Architecture**: Different providers for different tasks
3. **Excellent Documentation**: Users praise docs and simplicity
4. **Deep Neovim Integration**: Leverages native features well
5. **Active Development**: Regular updates and responsive maintainer
6. **Both API and Agent Support**: Direct API + ACP for maximum flexibility

#### Disadvantages

1. **Learning Curve**: Many features to learn
2. **Chat-Focused**: If you prefer inline editing, Avante may be better
3. **Requires Configuration**: More setup than simpler plugins

#### Recommendation

**BEST OVERALL CHOICE** for your requirements:
- ✅ Supports Anthropic Claude API
- ✅ Supports Google Gemini API
- ✅ Supports Claude Code (ACP) for Max plan usage
- ✅ Supports Gemini CLI (ACP)
- ✅ Supports Goose and opencode agents (ACP)
- ✅ Excellent documentation and community support
- ✅ Flexible enough to adapt to any workflow

---

### 4.2 avante.nvim

**Repository**: https://github.com/yetone/avante.nvim
**GitHub Stars**: ~15,000
**Description**: "Use your Neovim like using Cursor AI IDE!"

#### Provider Support

**Direct API Support**:
- Claude (Anthropic) - **Default provider**
- Google Gemini
- OpenAI
- Azure
- Cohere
- Copilot

**Agent Client Protocol (ACP) Support**:
- gemini-cli
- claude-code
- goose
- codex
- kimi-cli

#### Key Features

1. **Cursor-Like Experience**: Emulates Cursor AI IDE behavior
2. **Inline Editing**: Apply AI recommendations directly to source files
3. **Agentic Mode**: Uses tools to automatically generate code
4. **Legacy Mode**: Traditional code suggestions without tools
5. **Zen Mode**: CLI-like interface while using full Neovim capabilities
6. **ACP Integration**: All capabilities of Claude Code, Gemini-CLI, and Codex
7. **@file Feature**: Powerful file context injection

#### Configuration

**Claude Setup**:
- Endpoint: https://api.anthropic.com
- Default model: claude-3-5-sonnet-20241022
- Configurable temperature and max_tokens

**Gemini Setup**:
- Supports models like "gemini-2.5-pro-exp-03-25"
- Configurable timeout, temperature, max_tokens
- API key via GEMINI_API_KEY environment variable

**ACP Setup**:
- Gemini CLI: Install gemini CLI tool + set GEMINI_API_KEY
- Claude Code: Install acp-claude-code via npm + set ANTHROPIC_API_KEY

#### User Reviews

**Pros**:
- ~15k GitHub stars (most popular)
- "Active development, support for almost all models"
- "Well-optimized prompts, well-handled code diffs"
- "@file feature has made it 5x more powerful"
- Most traction in community
- Choose your own LLM provider

**Cons**:
- "Only allows you to edit buffers, so no conversations"
- "Has become too loaded, heavy and hard to use"
- "Poor documentation and complexity"
- "Buggy" with UI bugs and integration issues
- 203 open issues (vs 1 for CodeCompanion at one point)
- Only compatible with Neovim 0.10.1+

#### Critical User Feedback

> "do NOT get psyopped by avante.nvim, codecompanion is so much better. it's a zed-like claude (or any LLM) sidebar in your neovim. avante doesn't even support back-and-forth conversations, each message is standalone and everything you said before is forgotten!"

This is a strong critique highlighting Avante's lack of conversational memory.

#### Advantages

1. **Most Popular**: Largest community and most stars
2. **Cursor-Like UX**: If you like Cursor, you'll like Avante
3. **Inline Editing Focus**: Best for direct code modifications
4. **Feature-Rich**: Many modes (agentic, legacy, zen)
5. **Well-Tested Prompts**: Optimized for code generation

#### Disadvantages

1. **Complexity Issues**: Users report it's "too loaded"
2. **Buggy**: Multiple reports of UI bugs
3. **No Conversations**: Each message is standalone (major limitation)
4. **Poor Documentation**: Users complain about docs quality
5. **High Issue Count**: Many open issues suggest maintenance challenges
6. **Newer Neovim Only**: Requires 0.10.1+

#### Recommendation

**GOOD CHOICE** if you want Cursor-like inline editing, but be aware of limitations:
- ✅ Supports Anthropic Claude API
- ✅ Supports Google Gemini API
- ✅ Supports Claude Code (ACP)
- ✅ Supports Gemini CLI (ACP)
- ⚠️ No conversational memory (major limitation)
- ⚠️ Reported stability issues
- ⚠️ Complex and potentially "too heavy"

**Better for**: Users who primarily want inline editing without back-and-forth conversations.

**Not ideal for**: Users who want chat-based workflows or stable, simple tools.

---

### 4.3 folke/sidekick.nvim

**Repository**: https://github.com/folke/sidekick.nvim
**Description**: "Your Neovim AI sidekick"

#### Features

- Review and apply diffs
- Chat with AI assistants
- Direct access to AI CLIs without leaving Neovim
- Out-of-the-box support for:
  - Claude
  - Gemini
  - Grok
  - Codex
  - Copilot CLI
  - And more

#### Advantages

- From folke (respected Neovim plugin author)
- Clean, simple design
- Multi-provider support

#### Disadvantages

- Newer plugin (less community feedback)
- Less feature-rich than codecompanion/avante
- Limited documentation available

#### Recommendation

**EMERGING OPTION**: Worth watching due to folke's reputation, but less proven than codecompanion or avante. Consider if you value simplicity and trust folke's development approach.

---

### 4.4 claude-code.nvim Variants

Several plugins specifically target Claude Code integration:

#### greggh/claude-code.nvim
**Repository**: https://github.com/greggh/claude-code.nvim

**Features**:
- Toggle Claude Code in terminal window with single key press
- Support for command-line arguments (--continue, custom variants)
- Auto-detect and reload files modified by Claude Code

**Limitation**: Claude-only (no Gemini support)

#### coder/claudecode.nvim
**Repository**: https://github.com/coder/claudecode.nvim
**Description**: "🧩 Claude Code Neovim IDE Extension"

**Features**:
- First Neovim IDE integration for Claude Code
- Pure Lua implementation
- WebSocket-based MCP protocol (reverse-engineered from VS Code extension)
- Same AI-powered coding experience as official VS Code extension

**Limitation**: Claude-only (no Gemini support)

#### Recommendation

**NOT RECOMMENDED** for your use case because they only support Claude, not Gemini. Use codecompanion.nvim or avante.nvim for Claude Code support via ACP instead.

---

### 4.5 Other Multi-Provider Plugins

#### Minuet
- **Features**: Code completion as-you-type from OpenAI, Gemini, Claude, Ollama, Llama.cpp, Codestral
- **Type**: Autocomplete-focused (not chat/agent)
- **Cache optimizations** for improved performance

#### Gp.nvim
- **Features**: GPT prompt plugin for ChatGPT sessions & instructable text/code operations & speech to text
- **Providers**: OpenAI, Ollama, Anthropic
- **Note**: Missing Gemini support

---

## Comparative Analysis

### Provider Support Matrix

| Plugin | Anthropic API | Gemini API | Claude Code (ACP) | Gemini CLI (ACP) | Goose (ACP) | OpenCode (ACP) | Other Providers |
|--------|--------------|------------|-------------------|------------------|-------------|----------------|-----------------|
| **codecompanion.nvim** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 12+ direct, 8+ ACP |
| **avante.nvim** | ✅ (default) | ✅ | ✅ | ✅ | ✅ | ✅ | 6+ providers |
| **goose.nvim** | ✅ | ✅ | ❌ | ❌ | N/A (is Goose) | ❌ | 9+ providers |
| **opencode.nvim** | ✅ | ✅ | Via ACP in other plugins | Via ACP in other plugins | Via ACP in other plugins | N/A (is OpenCode) | 75+ providers |
| **sidekick.nvim** | ✅ | ✅ | ✅ | ✅ | Unknown | Unknown | Multiple |
| **claude-code.nvim** | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | None |
| **Gemini CLI plugins** | ❌ | ✅ | ❌ | N/A (is Gemini CLI) | ❌ | ❌ | None |

### Feature Comparison

| Plugin | Chat | Inline Edit | Agent | ACP | Conversations | Diff View | Context Injection |
|--------|------|-------------|-------|-----|---------------|-----------|-------------------|
| **codecompanion.nvim** | ✅ | ✅ | ✅ | ✅ | ✅ Persistent | ✅ Native | ✅ Profiles |
| **avante.nvim** | ⚠️ Limited | ✅ Strong | ✅ | ✅ | ❌ No memory | ✅ | ✅ @file |
| **goose.nvim** | ✅ | ✅ | ✅ Strong | ❌ | ✅ Persistent | Unknown | ✅ |
| **opencode.nvim** | ✅ | ✅ | ✅ | Via others | ✅ | ✅ | ✅ Strong |
| **sidekick.nvim** | ✅ | ✅ | ✅ | ✅ | Unknown | ✅ | Unknown |

### Workflow Style Comparison

| Plugin | Workflow Style | User Experience | Best For |
|--------|---------------|-----------------|----------|
| **codecompanion.nvim** | "Like Zed AI" | Chat sidebar with modular commands | Users who want flexibility and chat-based interaction |
| **avante.nvim** | "Like Cursor" | Inline editing with AI suggestions | Users who want Cursor-like inline modifications |
| **goose.nvim** | "Autonomous agent" | AI takes initiative, executes tasks | Users who want AI to handle complex workflows autonomously |
| **opencode.nvim** | "Terminal-first" | Tmux multi-pane with visible agent | Users with terminal/tmux workflows |

### User Sentiment Analysis

Based on community discussions:

**codecompanion.nvim**:
- 📈 "Users love CodeCompanion for its documentation and simplicity"
- 📈 "Easier to pass buffers, viewports, etc."
- 📈 "Pragmatic, batteries-included toolkit"
- 📉 Fewer stars than Avante

**avante.nvim**:
- 📈 "Most traction currently" (15k stars)
- 📈 "Well-optimized prompts, well-handled code diffs"
- 📈 "@file feature has made it 5x more powerful"
- 📉 "Has become too loaded, heavy and hard to use"
- 📉 "Buggy" with UI issues
- 📉 "Doesn't support back-and-forth conversations"

**goose.nvim**:
- 📈 "Goes beyond code suggestions"
- 📈 "Can build entire projects from scratch"
- 📉 Newer plugin (263 stars)
- 📉 More complex setup

**opencode.nvim**:
- 📈 "Seamless Tmux integration"
- 📈 "75+ provider support"
- 📈 "Built for terminal workflows"
- 📉 "Not perfect, still has issues"
- 📉 Multiple competing plugins

### Performance Considerations

**Resource Usage**:
- **Local models** (Ollama): Slower, higher CPU usage, but private
- **Cloud APIs**: Fast, low local resource usage, but costs tokens
- **Lazy loading**: All plugins benefit from lazy.nvim for startup performance

**Stability**:
- **codecompanion.nvim**: Reported as stable with responsive maintainer
- **avante.nvim**: Reports of bugs and UI issues
- **goose.nvim**: Limited stability reports (newer)
- **opencode.nvim**: "Not perfect" per user feedback

**Recommendations**:
- Keep plugins lazy-loaded with lazy.nvim
- Start with smaller models for exploratory prompts
- Set sane limits (max tokens, temperature) where supported
- Monitor token usage to control costs

---

## Agent Client Protocol (ACP) Deep Dive

### What is ACP?

Agent Client Protocol (ACP) standardizes communication between code editors and AI coding agents using JSON-RPC over stdio. The goal is similar to how the Language Server Protocol (LSP) unbundled language intelligence from monolithic IDEs.

**Benefits**:
- Switch between multiple agents without switching editors
- Use best-of-breed agents with your preferred editor
- Standardized interface reduces integration complexity

### ACP Support Status

**Editors Supporting ACP**:
- ✅ **Zed**: Created ACP, first-class support
- ✅ **Neovim**: Via codecompanion.nvim and avante.nvim
- ✅ **Emacs**: Via agent-shell plugin
- ⚠️ **Eclipse**: Prototype implementation
- ⚠️ **Toad**: Implementing ACP support

**Agents Supporting ACP**:
- ✅ **Gemini CLI**: Original launch partner, reference implementation
- ✅ **Claude Code**: Via Zed's SDK adapter (not native yet)
- ✅ **Goose**: Supported
- ✅ **opencode**: Supported
- ✅ **Augment Code**: Supported
- ✅ **Codex**: Supported
- ✅ **Kimi CLI**: Supported
- ⚠️ **Cagent** (Docker): Supported

### Native vs. Adapter Support

**Claude Code**: Currently uses an adapter that wraps Claude Code's SDK and translates to ACP's JSON RPC format. There's an open feature request (Issue #6686) for native ACP support.

**Gemini CLI**: Native ACP support as reference implementation.

### Recommendation

If you want to use **both Claude Code and Gemini CLI** with their respective subscription/free tier benefits, **ACP support is crucial**. Both codecompanion.nvim and avante.nvim provide ACP support, making them excellent choices.

---

## Cost Analysis

### API Costs

**Anthropic Claude API**:
- Claude 3.5 Haiku: $0.25 / $1.25 per million tokens
- Claude 3.5 Sonnet: $3 / $15 per million tokens
- Claude 4.1 Sonnet: $5 (input), $25 (output), $10 (thinking) per million tokens
- Claude 4.1 Opus: $20 (input), $80 (output), $40 (thinking) per million tokens

**Google Gemini API**:
- **Free tier available** with generous rate limits
- Excellent for experimentation without costs
- Paid tiers available for production use

**OpenAI API** (for comparison):
- GPT-4o: $5 / $15 per million tokens
- o1: $15 / $60 per million tokens

### Subscription vs. API

**Claude Max Plan** ($100-$200/month):
- **Does NOT reduce API costs**
- Web/desktop usage only
- Can purchase additional API usage at standard rates
- Useful for mixed usage (web + API)

**Claude Code Rate Limits**:
- Enforced since August 2025
- Heavy users need to plan for limits
- May need to purchase additional capacity

### Cost Optimization Strategies

1. **Use Gemini free tier** for experimentation and light usage
2. **Use smaller models** (Haiku, Gemini Flash) for routine tasks
3. **Reserve premium models** (Opus, GPT-4o) for complex problems
4. **Multi-model configuration** in Goose or OpenCode
5. **Set token limits** to prevent runaway costs
6. **Local models** (Ollama) for private/unlimited usage

### Recommended Cost Strategy

For your use case:
1. **Start with Gemini free tier** for daily coding assistance
2. **Add Anthropic API key** for complex tasks requiring Claude
3. **Consider Claude Max** if you use Claude extensively in web UI
4. **Monitor usage** and adjust model selection based on costs

---

## Implementation Recommendations

### Recommended Setup: codecompanion.nvim as Primary

**Why codecompanion.nvim**:
1. ✅ Best multi-provider support (12+ direct, 8+ ACP agents)
2. ✅ Excellent documentation and community feedback
3. ✅ Stable with responsive maintenance
4. ✅ Flexible architecture (different providers per strategy)
5. ✅ Supports both Anthropic and Gemini (your requirement)
6. ✅ ACP support for Claude Code and Gemini CLI
7. ✅ Deep Neovim integration

**Configuration Strategy**:
```lua
-- Example configuration approach (not complete)
require("codecompanion").setup({
  adapters = {
    -- Use Gemini (free tier) for chat
    gemini = require("codecompanion.adapters").use("gemini", {
      env = {
        api_key = "GEMINI_API_KEY"
      }
    }),
    -- Use Claude for complex code generation
    anthropic = require("codecompanion.adapters").use("anthropic", {
      env = {
        api_key = "ANTHROPIC_API_KEY"
      },
      schema = {
        model = {
          default = "claude-3-5-sonnet-20241022"
        }
      }
    }),
  },
  -- Configure strategies
  strategies = {
    chat = { adapter = "gemini" },      -- Use free Gemini for chat
    inline = { adapter = "anthropic" }, -- Use Claude for inline edits
    cmd = { adapter = "gemini" }        -- Use Gemini for commands
  }
})
```

### Alternative Setup: avante.nvim for Cursor-Like Experience

**Why avante.nvim**:
1. ✅ Best inline editing experience (Cursor-like)
2. ✅ Most popular (15k stars)
3. ✅ Supports both Anthropic (default) and Gemini
4. ⚠️ No conversational memory (limitation)
5. ⚠️ Reported stability issues

**Use if**: You primarily want inline code modifications rather than back-and-forth chat conversations.

### Complementary Tool: OpenCode in Tmux

**If you use Tmux**, consider running OpenCode in a separate pane:
- Edit in Neovim (one pane)
- OpenCode agent (second pane)
- Running processes (third pane)

**Benefits**:
- Visual feedback from agent
- Separation of concerns
- Terminal-first workflow
- 75+ provider support

**Install**:
```bash
npm i -g opencode-ai@latest
# or
brew install opencode
```

Then use either:
- **NickvanDyke/opencode.nvim**: Best Neovim integration
- **cousine/opencode-context.nvim**: Best Tmux integration
- **Manual**: Just run opencode in tmux pane without plugin

### Experimental Option: Goose for Autonomous Workflows

**If you want true agent capabilities**:
- Install Goose: https://github.com/block/goose
- Use goose.nvim: https://github.com/azorng/goose.nvim
- Or use via codecompanion.nvim ACP support

**Best for**: Complex, multi-step tasks where you want AI to work autonomously.

---

## Step-by-Step Implementation Plan

### Phase 1: Basic Setup (codecompanion.nvim)

1. **Install codecompanion.nvim** via your plugin manager (lazy.nvim, packer, etc.)
   ```lua
   {
     "olimorris/codecompanion.nvim",
     dependencies = {
       "nvim-lua/plenary.nvim",
       "nvim-treesitter/nvim-treesitter",
       "nvim-telescope/telescope.nvim", -- optional
     },
     config = function()
       require("codecompanion").setup({
         -- Initial configuration
       })
     end
   }
   ```

2. **Set up API keys**:
   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   export GEMINI_API_KEY="your-gemini-api-key"
   export ANTHROPIC_API_KEY="your-anthropic-api-key"
   ```

3. **Get API keys**:
   - Gemini: https://makersuite.google.com/app/apikey (free tier available)
   - Anthropic: https://console.anthropic.com/ (requires payment)

4. **Test basic functionality**:
   - Open Neovim
   - Try `:CodeCompanion` command
   - Test chat with Gemini (free tier)

### Phase 2: Multi-Provider Configuration

1. **Configure adapters** for different strategies:
   - Chat: Gemini (free tier)
   - Inline edits: Claude (better quality)
   - Commands: Gemini (cost optimization)

2. **Set up context profiles** with @ syntax:
   - @buffer: Current buffer
   - @viewport: Visible code
   - @diagnostics: LSP diagnostics

3. **Configure memory files**:
   - Create project-specific CLAUDE.md or .cursor/rules
   - Define coding standards and context

### Phase 3: ACP Integration (Optional)

**If using Claude Max plan**:
1. **Install Claude Code**:
   ```bash
   npm install -g @anthropics/acp-claude-code
   ```

2. **Install Gemini CLI**:
   ```bash
   # Follow instructions at: https://github.com/google-gemini/gemini-cli
   ```

3. **Configure ACP in codecompanion.nvim**:
   - Enable ACP support
   - Configure claude-code and gemini-cli agents
   - Test agent workflows

### Phase 4: Advanced Workflows (Optional)

**Option A: Add OpenCode for Terminal Workflows**
1. Install OpenCode CLI
2. Install NickvanDyke/opencode.nvim
3. Configure Tmux layout (if using Tmux)

**Option B: Add Goose for Autonomous Agents**
1. Install Goose CLI
2. Install goose.nvim OR use via codecompanion ACP
3. Test autonomous workflows

**Option C: Add avante.nvim for Inline Editing**
1. Install avante.nvim
2. Use for Cursor-like inline modifications
3. Use codecompanion for chat-based tasks

### Phase 5: Optimization

1. **Monitor costs**:
   - Track token usage per provider
   - Adjust model selection based on cost/quality tradeoff

2. **Fine-tune configuration**:
   - Adjust max_tokens and temperature per use case
   - Optimize context injection to reduce token usage
   - Set up key bindings for frequent operations

3. **Set up lazy loading**:
   - Ensure plugins are lazy-loaded with lazy.nvim
   - Maintain Neovim startup performance

---

## Decision Matrix

### Choose codecompanion.nvim if:
- ✅ You want maximum flexibility and multi-provider support
- ✅ You prefer chat-based workflows
- ✅ You value stability and good documentation
- ✅ You want to use different providers for different tasks
- ✅ You need both Anthropic API and Gemini API support
- ✅ You want ACP support for multiple agents

### Choose avante.nvim if:
- ✅ You want a Cursor-like inline editing experience
- ✅ You're comfortable with occasional bugs
- ✅ You don't need conversational memory
- ✅ You want the most popular/trendy option
- ❌ You need stable, production-ready tools
- ❌ You want chat-based back-and-forth conversations

### Choose opencode.nvim if:
- ✅ You use Tmux for your workflow
- ✅ You want terminal-first design
- ✅ You want 75+ provider support
- ✅ You want to see the agent working in a visible pane
- ❌ You want a pure-Neovim solution without external tools

### Choose goose.nvim if:
- ✅ You want true autonomous agent capabilities
- ✅ You're comfortable with complex setup
- ✅ You want AI to handle multi-step workflows independently
- ❌ You prefer simple, predictable tools
- ❌ You want mature, battle-tested plugins

### Use multiple plugins if:
- ✅ You want different tools for different tasks
- ✅ Example: codecompanion for chat + avante for inline editing
- ✅ Example: codecompanion + OpenCode in tmux pane
- ⚠️ Watch for plugin conflicts and complexity

---

## Advantages and Disadvantages Summary

### Option 1: Gemini CLI Direct Integration
**Advantages**:
- Purpose-built for Gemini
- Clean, focused API
- Good for Gemini-only workflows

**Disadvantages**:
- ❌ No Anthropic/Claude support
- ❌ Single-provider limitation
- ❌ Less flexible than multi-provider solutions

**Verdict**: Not recommended due to lack of Anthropic support.

---

### Option 2: Goose AI Agent (goose.nvim)
**Advantages**:
- ✅ True autonomous agent capabilities
- ✅ Multi-provider support (Anthropic, Gemini, OpenAI, etc.)
- ✅ Open source and extensible
- ✅ Gemini free tier available
- ✅ Strong tool-calling capabilities
- ✅ Can build entire projects autonomously

**Disadvantages**:
- ⚠️ More complex setup
- ⚠️ Newer Neovim integration (263 stars)
- ⚠️ Higher token consumption for autonomous tasks
- ⚠️ Steeper learning curve

**Verdict**: Excellent for autonomous workflows, but consider using via codecompanion ACP support instead of standalone plugin.

---

### Option 3: OpenCode AI Agent (opencode.nvim)
**Advantages**:
- ✅ Terminal-first design (perfect for Neovim users)
- ✅ 75+ LLM provider support (widest compatibility)
- ✅ Tmux integration (superior multi-pane workflow)
- ✅ Can use Claude Pro/Max subscription (not just API)
- ✅ Free models available
- ✅ Secure credential storage

**Disadvantages**:
- ⚠️ Requires separate OpenCode installation
- ⚠️ Multiple competing Neovim plugins
- ⚠️ More moving parts than integrated solutions
- ⚠️ User feedback: "not perfect," occasional issues

**Verdict**: Best for terminal/tmux workflows. Consider running in tmux pane alongside Neovim for maximum flexibility.

---

### Option 4A: codecompanion.nvim ⭐ TOP RECOMMENDATION
**Advantages**:
- ✅ **Most comprehensive provider support** (12+ direct, 8+ ACP)
- ✅ **Excellent documentation and simplicity**
- ✅ **Stable with responsive maintenance**
- ✅ **Flexible architecture** (different providers per task)
- ✅ **Both API and ACP support**
- ✅ **Deep Neovim integration**
- ✅ **Persistent conversations**
- ✅ **Native diff view**
- ✅ **Memory file support** (CLAUDE.md, .cursor/rules)
- ✅ **Free tier option** via GitHub Models

**Disadvantages**:
- ⚠️ Fewer stars than Avante (~4.5k vs 15k)
- ⚠️ Chat-focused (may not suit inline editing preference)
- ⚠️ Learning curve for all features

**Verdict**: **BEST OVERALL CHOICE** for your requirements. Supports both Anthropic and Gemini with excellent flexibility.

---

### Option 4B: avante.nvim
**Advantages**:
- ✅ **Most popular** (15k stars)
- ✅ **Cursor-like inline editing** experience
- ✅ **Feature-rich** (agentic mode, legacy mode, zen mode)
- ✅ **Well-optimized prompts**
- ✅ **@file feature** for powerful context
- ✅ **ACP support** (Claude Code, Gemini CLI, Goose, etc.)
- ✅ **Default Claude provider** with Gemini support

**Disadvantages**:
- ❌ **No conversational memory** (each message standalone)
- ❌ **Reported bugs and UI issues**
- ❌ **"Too loaded and heavy"** per user feedback
- ❌ **Poor documentation** per user feedback
- ❌ **High open issue count** (203 vs 1 for codecompanion)
- ❌ **Requires Neovim 0.10.1+**

**Verdict**: Good for Cursor-like inline editing, but significant limitations (no conversation memory) and stability concerns.

---

### Option 4C: Other Multi-Provider Plugins
**sidekick.nvim**:
- Advantages: From respected author (folke), clean design
- Disadvantages: Newer, less proven, limited documentation
- Verdict: Promising but wait for maturity

**claude-code.nvim variants**:
- Advantages: Purpose-built for Claude Code
- Disadvantages: Claude-only, no Gemini support
- Verdict: Not recommended (use codecompanion/avante for Claude Code via ACP)

**Minuet, Gp.nvim**:
- Advantages: Specialized features (autocomplete, speech-to-text)
- Disadvantages: Not full-featured chat/agent solutions
- Verdict: Consider as complementary tools, not primary solution

---

## Final Recommendations

### 🥇 Primary Recommendation: codecompanion.nvim

**Use codecompanion.nvim as your primary AI coding assistant.**

**Reasons**:
1. ✅ Supports both Anthropic Claude API and Google Gemini API (your requirement)
2. ✅ Excellent documentation and stability
3. ✅ Most flexible architecture (different providers for different tasks)
4. ✅ ACP support for Claude Code, Gemini CLI, Goose, and opencode
5. ✅ Persistent conversations (unlike avante.nvim)
6. ✅ Deep Neovim integration
7. ✅ Active maintenance and responsive community

**Configuration Strategy**:
- **Chat**: Use Gemini (free tier) for daily conversations
- **Inline edits**: Use Claude (better quality) for code modifications
- **Commands**: Use Gemini (cost optimization) for simple tasks
- **ACP agents**: Configure Claude Code and Gemini CLI if using subscriptions

---

### 🥈 Secondary Recommendation: OpenCode in Tmux

**If you use Tmux, run OpenCode in a separate pane alongside Neovim.**

**Reasons**:
1. ✅ Terminal-first design matches Neovim philosophy
2. ✅ Visual feedback from agent in dedicated pane
3. ✅ 75+ provider support (widest compatibility)
4. ✅ Can use Claude Pro/Max subscription
5. ✅ Separation of concerns (editor vs agent)

**Setup**:
- Pane 1: Neovim for editing
- Pane 2: OpenCode agent for AI assistance
- Pane 3: Running processes (tests, servers, etc.)

**Integration**: Use NickvanDyke/opencode.nvim or cousine/opencode-context.nvim for bidirectional communication.

---

### 🥉 Tertiary Recommendation: avante.nvim for Inline Editing

**Consider adding avante.nvim if you frequently need Cursor-like inline editing.**

**Use cases**:
- Quick inline code modifications
- Applying AI suggestions directly to files
- When you don't need back-and-forth conversations

**Caution**: Be aware of its limitations (no conversation memory, reported bugs) and consider it complementary to codecompanion, not a replacement.

---

### 🎯 Recommended Technology Stack

**Primary Setup** (Minimum):
```
Neovim + codecompanion.nvim
  └─ Gemini API (free tier for daily use)
  └─ Anthropic Claude API (for complex tasks)
```

**Enhanced Setup** (Recommended):
```
Neovim + codecompanion.nvim + OpenCode (Tmux)
  └─ Gemini API (free tier for chat)
  └─ Anthropic Claude API (for inline edits)
  └─ OpenCode (terminal agent, 75+ providers)
```

**Advanced Setup** (Power Users):
```
Neovim + codecompanion.nvim + avante.nvim + OpenCode (Tmux)
  ├─ codecompanion: Chat and agent orchestration
  ├─ avante: Inline editing (Cursor-like)
  ├─ OpenCode: Visible agent in tmux pane
  ├─ ACP: Claude Code + Gemini CLI integration
  └─ Multi-provider: Optimize cost and quality per task
```

---

## Implementation Checklist

### ✅ Phase 1: Foundation (Week 1)
- [ ] Install codecompanion.nvim via package manager
- [ ] Obtain Gemini API key (free tier)
- [ ] Obtain Anthropic API key (paid)
- [ ] Set up environment variables (GEMINI_API_KEY, ANTHROPIC_API_KEY)
- [ ] Test basic chat functionality with Gemini
- [ ] Test chat functionality with Claude

### ✅ Phase 2: Configuration (Week 1-2)
- [ ] Configure multi-provider adapters
- [ ] Set up strategy routing (chat → Gemini, inline → Claude)
- [ ] Configure context profiles (@buffer, @viewport, @diagnostics)
- [ ] Set up key bindings for frequent operations
- [ ] Create project-specific memory files (CLAUDE.md)
- [ ] Test inline editing with Claude
- [ ] Monitor token usage and costs

### ✅ Phase 3: ACP Integration (Week 2-3, Optional)
- [ ] Install Claude Code CLI (if using Max plan)
- [ ] Install Gemini CLI
- [ ] Configure ACP support in codecompanion.nvim
- [ ] Test Claude Code agent via ACP
- [ ] Test Gemini CLI agent via ACP
- [ ] Compare ACP vs. direct API usage

### ✅ Phase 4: OpenCode Integration (Week 3-4, Optional)
- [ ] Install OpenCode CLI
- [ ] Set up Tmux layout (3-pane: editor, agent, processes)
- [ ] Install NickvanDyke/opencode.nvim
- [ ] Configure bidirectional communication
- [ ] Test terminal-first workflow
- [ ] Evaluate vs. pure Neovim approach

### ✅ Phase 5: Advanced Features (Week 4+, Optional)
- [ ] Install avante.nvim for inline editing comparison
- [ ] Test Goose integration via codecompanion ACP
- [ ] Set up custom prompt library
- [ ] Configure slash commands and workflows
- [ ] Optimize token usage and model selection
- [ ] Document your configuration and workflow

---

## Troubleshooting Guide

### Issue: API Keys Not Recognized
**Solution**:
- Verify environment variables are set: `echo $GEMINI_API_KEY`
- Restart Neovim after setting env vars
- Check API key validity at provider console
- Try hardcoding in config temporarily for testing

### Issue: High Token Costs
**Solution**:
- Use Gemini free tier for routine tasks
- Set max_tokens limits in config
- Use smaller models (Haiku instead of Opus)
- Review and optimize context injection
- Monitor usage via provider dashboards

### Issue: Plugin Conflicts
**Solution**:
- Ensure lazy loading with lazy.nvim
- Check for overlapping key bindings
- Disable conflicting plugins temporarily for testing
- Review plugin documentation for known conflicts

### Issue: Slow Performance
**Solution**:
- Lazy load plugins with lazy.nvim
- Use streaming responses where available
- Reduce context size (fewer files in @file)
- Check network connectivity
- Try local models (Ollama) for instant responses

### Issue: ACP Agents Not Working
**Solution**:
- Verify CLI tools installed: `which claude-code`, `which gemini`
- Check API keys for respective services
- Review codecompanion ACP configuration
- Check for error messages in `:messages`
- Test CLI tools directly in terminal first

---

## Additional Resources

### Official Documentation
- **codecompanion.nvim**: https://codecompanion.olimorris.dev/
- **avante.nvim Wiki**: https://github.com/yetone/avante.nvim/wiki
- **Goose Documentation**: https://block.github.io/goose/docs/
- **OpenCode Documentation**: https://opencode.ai/docs/
- **Anthropic API Docs**: https://docs.anthropic.com/
- **Gemini API Docs**: https://ai.google.dev/docs

### Community Resources
- **Neovim AI Plugins List**: https://github.com/ColinKennedy/neovim-ai-plugins
- **awesome-neovim**: https://github.com/rockerBOO/awesome-neovim (AI section)
- **Neovim Discourse**: https://neovim.discourse.group/ (search "AI integration")

### Comparison Articles
- "Cursor for Neovim: I Tested Every Workaround vs Native Solution": https://dredyson.com/cursor-for-neovim-i-tested-every-workaround-vs-native-solution-the-best-options-compared/
- "How to transform your Neovim to Cursor in minutes": https://composio.dev/blog/how-to-transform-your-neovim-to-cursor-in-minutes
- "AI in Neovim (NeovimConf 2024)": https://www.joshmedeski.com/posts/ai-in-neovim-neovimconf-2024/

---

## Conclusion

After comprehensive research, **codecompanion.nvim emerges as the best overall solution** for integrating AI coding assistants into Neovim with support for both Anthropic Claude and Google Gemini APIs.

### Key Findings

1. **Multi-provider support is essential**: Single-provider plugins (Gemini CLI only or Claude-only) are too limiting.

2. **ACP is the future**: Agent Client Protocol enables using best-of-breed agents (Claude Code, Gemini CLI, Goose, opencode) with your editor.

3. **Workflow style matters**: Choose based on preference:
   - Chat-based → codecompanion.nvim
   - Inline editing → avante.nvim
   - Terminal-first → opencode in tmux
   - Autonomous → Goose integration

4. **Cost optimization is achievable**: Use Gemini free tier for routine tasks, Claude for complex work.

5. **Anthropic Max ≠ API access**: The $200/month Max plan doesn't reduce API costs; they're separate.

### Recommended Path Forward

**Start simple**:
1. Install codecompanion.nvim
2. Configure Gemini (free tier) and Claude API
3. Use for 1-2 weeks to establish baseline

**Expand thoughtfully**:
4. Add OpenCode in tmux if terminal workflow appeals
5. Add avante.nvim if inline editing is frequently needed
6. Experiment with ACP agents (Claude Code, Gemini CLI)

**Optimize continuously**:
7. Monitor costs and adjust provider selection
8. Refine configuration based on actual usage patterns
9. Stay updated with plugin developments

### Final Verdict

✅ **Primary**: codecompanion.nvim (multi-provider, stable, well-documented)
✅ **Secondary**: OpenCode in tmux (terminal-first, 75+ providers)
⚠️ **Optional**: avante.nvim (inline editing, with caution due to limitations)
🔬 **Experimental**: Goose integration (autonomous agents for advanced users)

This combination provides maximum flexibility, supports both required APIs (Anthropic and Gemini), and allows you to adapt your workflow as you discover what works best for your specific needs.

---

## Sources

- [GitHub - marcinjahn/gemini-cli.nvim](https://github.com/marcinjahn/gemini-cli.nvim)
- [GitHub - JonRoosevelt/gemini-cli.nvim](https://github.com/jonroosevelt/gemini-cli.nvim)
- [GitHub - u3ih/gemini.nvim](https://github.com/u3ih/gemini.nvim)
- [GitHub - kiddos/gemini.nvim](https://github.com/kiddos/gemini.nvim)
- [GitHub - meinside/gmn.nvim](https://github.com/meinside/gmn.nvim)
- [Feature: Neovim IDE Integration · Issue #5874 · google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli/issues/5874)
- [GitHub - azorng/goose.nvim](https://github.com/azorng/goose.nvim)
- [GitHub - block/goose](https://github.com/block/goose)
- [GitHub - olimorris/codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim)
- [GitHub - yetone/avante.nvim](https://github.com/yetone/avante.nvim)
- [Configure LLM Provider | goose](https://block.github.io/goose/docs/getting-started/providers/)
- [GitHub - NickvanDyke/opencode.nvim](https://github.com/NickvanDyke/opencode.nvim)
- [GitHub - sudo-tee/opencode.nvim](https://github.com/sudo-tee/opencode.nvim)
- [GitHub - cousine/opencode-context.nvim](https://github.com/cousine/opencode-context.nvim)
- [GitHub - sst/opencode](https://github.com/sst/opencode)
- [OpenCode | The open source AI coding agent](https://opencode.ai/)
- [Models | opencode](https://opencode.ai/docs/models/)
- [Providers | opencode](https://opencode.ai/docs/providers/)
- [GitHub - greggh/claude-code.nvim](https://github.com/greggh/claude-code.nvim)
- [GitHub - coder/claudecode.nvim](https://github.com/coder/claudecode.nvim)
- [GitHub - folke/sidekick.nvim](https://github.com/folke/sidekick.nvim)
- [Top 4 Claude Neovim Plugins & Integrations for 2025](https://skywork.ai/blog/claude-neovim-plugins-2025/)
- [Anthropic API Pricing: Complete Guide and Cost Optimization Strategies (2025)](https://www.finout.io/blog/anthropic-api-pricing)
- [How Anthropic's $200/month MAX Subscription Becomes a Steal](https://startupspells.com/p/anthropic-200-dollar-max-plan-steal-opus-api-pricing-strategy)
- [Claude Code: Rate limits, pricing, and alternatives | Blog — Northflank](https://northflank.com/blog/claude-rate-limits-claude-code-pricing-cost)
- [CodeCompanion vs Avante · Discussion #1209](https://github.com/olimorris/codecompanion.nvim/discussions/1209)
- [Community Debates Neovim AI Plugins: Avante vs CodeCompanion Lead the Pack](https://biggo.com/news/202502191322_neovim-ai-plugins-comparison)
- [Neovim users: what AI tools are you using? | Lobsters](https://lobste.rs/s/6san1l/neovim_users_what_ai_tools_are_you_using)
- [New in v17.18.0 - Agent Client Protocol in CodeCompanion](https://github.com/olimorris/codecompanion.nvim/discussions/2030)
- [Zed Adds ACP for External Agents (Gemini CLI Live)](https://www.vibesparking.com/en/blog/ai/zed/2025-08-28-zed-acp-gemini-cli-guide/)
- [Agent Client Protocol - Standardized AI Agent Integration](https://acpserver.org/)
- [How the Community is Driving ACP Forward — Zed's Blog](https://zed.dev/blog/acp-progress-report)
- [Vim vs Neovim 2025: Performance Comparison](https://markaicode.com/vim-vs-neovim-2025-performance-plugin-comparison/)
- [10 Awesome Neovim LLM Plugins You Should Try Now](https://apidog.com/blog/awesome-neovim-llm-plugins/)
- [GitHub - ColinKennedy/neovim-ai-plugins](https://github.com/ColinKennedy/neovim-ai-plugins)
- [How to transform your Neovim to Cursor in minutes - Composio](https://composio.dev/blog/how-to-transform-your-neovim-to-cursor-in-minutes)
- [AI in Neovim (NeovimConf 2024) | Josh Medeski](https://www.joshmedeski.com/posts/ai-in-neovim-neovimconf-2024/)
- [Cursor for Neovim: I Tested Every Workaround vs Native Solution](https://dredyson.com/cursor-for-neovim-i-tested-every-workaround-vs-native-solution-the-best-options-compared/)
- [Complete Guide to Using OpenCode with Neovim & Tmux](https://keebsforall.com/blogs/mechanical-keyboards-101/complete-guide-to-using-opencode-with-neovim-tmux)

---

**Report Completed**: 2025-12-05
**Total Sources**: 50+ web search results analyzed
**Research Depth**: Comprehensive analysis of all major options
**Recommendation Confidence**: High
