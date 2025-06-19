# AI Integration for NeoVim

This directory contains modules for integrating various AI services and tools with NeoVim, enhancing your coding and writing experience with advanced AI capabilities.

## File Structure

```
ai/
├── README.md           # This documentation
├── init.lua           # AI plugins loader
├── avante.lua         # Avante AI assistant
├── claude-code.lua    # Claude Code integration
├── lectic.lua         # AI-assisted writing
├── mcp-hub.lua        # Model Context Protocol hub
└── util/              # AI utility modules
    ├── README.md      # AI utilities documentation
    ├── avante-highlights.lua # Theme-aware highlighting
    ├── avante-support.lua    # Avante management
    ├── avante_mcp.lua        # Avante/MCP integration
    ├── mcp_server.lua        # MCP server management
    ├── system-prompts.lua    # Prompt management
    ├── system-prompts.json   # Prompt storage
    └── tool_registry.lua     # AI tool registry
```

## Components

- **Avante Integration**: Connect with the Avante plugin for AI-assisted coding and chat
- **Claude Code Integration**: Seamless terminal integration with Claude Code CLI
- **Lectic Integration**: Add AI-assisted writing with structured prompts
- **MCP-Hub Integration**: Access multiple AI services through a unified hub
- **System Prompts**: Manage and customize AI behavior with templates

## Directory Structure

```
lua/neotex/plugins/ai/
├── README.md              # This file - overview and documentation
├── init.lua               # AI plugins loader with event registration
├── avante.lua             # Avante AI assistant configuration
├── claude-code.lua        # Claude Code terminal integration
├── lectic.lua             # Lectic AI writing integration
├── mcp-hub.lua            # MCP-Hub plugin configuration
└── util/                  # Utility modules for AI integration
    ├── README.md                    # Detailed utility module documentation
    ├── avante-highlights.lua        # Enhanced highlighting for Avante UI
    ├── avante-support.lua           # Avante model/provider/prompt management
    ├── avante_mcp.lua              # Avante-MCPHub integration layer
    ├── mcp_server.lua              # MCPHub server management
    ├── system-prompts.json          # System prompt templates storage
    ├── system-prompts.lua           # System prompts manager
    └── tool_registry.lua            # Hybrid tool registry for MCP scaling
```

### Utility Modules

The `util/` directory contains essential support modules for AI functionality:

- **Core Management**: Model selection, provider switching, and settings persistence
- **System Prompts**: Complete prompt management system with CRUD operations
- **MCPHub Integration**: Server management and Avante-MCPHub coordination with hybrid tool registry
- **Tool Registry**: Smart defaults and context-aware MCP tool selection for scalable integration
- **Visual Enhancement**: Theme-aware highlighting and UI improvements

For detailed documentation of utility modules, see [`util/README.md`](util/README.md).

## Available AI Features

### Avante AI Assistant

Avante provides a chat interface for AI-assisted coding and explanations.

**Key Features:**
- Multi-provider support (Claude, GPT, Gemini)
- Context-aware completion
- Code explanation and generation
- Documentation lookup
- Customizable system prompts

**Commands:**
- `AvanteAsk`: Ask a question or request code help
- `AvanteChat`: Start/open a chat session
- `AvanteEdit`: Edit selected text with AI assistance
- `AvanteRefresh`: Refresh your AI context
- `AvanteModel`: Select a specific AI model
- `AvanteProvider`: Choose the AI provider and model
- `AvantePrompt`: Select a system prompt
- `AvantePromptManager`: Manage system prompts
- `AvanteStop`: Stop ongoing generation

**Keymaps:**
- `<leader>ha`: Ask Avante AI a question
- `<leader>hc`: Start Avante chat
- `<leader>he`: Edit system prompts
- `<leader>hm`: Select AI model
- `<leader>hp`: Select system prompt
- `<leader>hs`: Edit selected text with AI
- `<leader>ht`: Toggle Avante AI interface

### Claude Code Terminal Integration

Claude Code provides a seamless terminal integration using the official `coder/claudecode.nvim` plugin for accessing Claude Code CLI directly within NeoVim.

**Key Features:**
- Official Claude Code integration with WebSocket-based protocol
- Right side terminal split with native or Snacks terminal provider
- Context management - add files and directories to Claude Code context
- Visual selection sending to Claude Code
- Tree explorer integration support
- Auto-start functionality with configurable ports
- Pure Lua implementation for better performance

**Commands:**
- `ClaudeCode`: Toggle Claude Code terminal
- `ClaudeCodeSend`: Send visual selection to Claude Code
- `ClaudeCodeAdd <file-path>`: Add files/directories to Claude context
- `ClaudeCodeAddBuffer`: Add current buffer to Claude context
- `ClaudeCodeAddDir`: Add current directory to Claude context
- `ClaudeCodeToggle`: Alternative command to toggle Claude Code terminal

**Keymaps:**
- `<leader>ho`: Toggle Claude Code terminal
- `<leader>hb`: Add current buffer to Claude context
- `<leader>hr`: Add current directory to Claude context
- `<leader>cc`: Toggle Claude Code (alternative)
- `<leader>cs`: Send visual selection to Claude Code
- `<leader>ca`: Add current file to Claude context

**Configuration Options:**
The plugin uses a right side split with WebSocket communication:

```lua
opts = {
  -- Port range for WebSocket connection
  port_range = { min = 10000, max = 65535 },
  auto_start = true,     -- Automatically start Claude Code
  log_level = "info",    -- Logging level
  
  -- Terminal configuration
  terminal = {
    split_side = "right",  -- Open terminal on right side
    provider = "native",   -- Use native terminal (or "snacks")
    auto_close = true,     -- Auto-close terminal when Claude Code exits
  },
}
```

**Context Management Benefits:**
- Easily add current file or entire directories to Claude Code context
- Visual selection sending for focused assistance
- Tree explorer integration for file management
- WebSocket protocol for reliable communication

**Requirements:**
- Claude Code CLI installed and accessible in PATH
- plenary.nvim dependency (automatically handled)
- NeoVim 0.8.0+

**Usage Workflow:**
1. Press `<leader>ho` to toggle Claude Code terminal on the right
2. Add current file to context with `<leader>hb`
3. Add entire directory to context with `<leader>hr`
4. Select text and use `<leader>cs` to send selection to Claude
5. Use Claude Code CLI commands as normal in the terminal
6. Toggle the terminal off with `<leader>ho` again when done

### Lectic AI-Assisted Writing

Lectic provides an interactive writing environment with AI feedback.

**Key Features:**
- Integrated with Markdown workflow
- Focused AI feedback on writing
- Custom file format with YAML frontmatter
- Interactive conversations with AI
- MCP-Hub integration for multiple provider support

**Commands:**
- `Lectic`: Run Lectic AI on current file
- `LecticCreateFile`: Create new Lectic file with template
- `LecticSubmitSelection`: Submit selection with user message
- `LecticSelectProvider`: Select AI provider and model

**Keymaps:**
- `<leader>ml`: Run Lectic on current file
- `<leader>mn`: Create new Lectic file
- `<leader>ms`: Submit selection with message

### MCP-Hub Integration (Cross-Platform)

MCP-Hub provides a unified interface to multiple AI services and tools with intelligent installation detection for both NixOS and standard environments.

**Key Features:**
- Cross-platform compatibility (NixOS and standard systems)
- Automatic installation method detection
- Access to multiple AI providers
- Web search capabilities  
- Code execution in sandbox environments
- PDF document analysis
- Weather information
- Image generation and analysis

**Commands:**
- `MCPHub`: Open the MCP-Hub interface
- `MCPHubStatus`: Check MCP-Hub connection status  
- `<leader>hx`: Quick access to MCPHub interface

**Cross-Platform Installation:**
The configuration automatically detects your environment and chooses the best installation method:

- **NixOS/Nix Users**: Automatically uses bundled installation (no setup required)
- **Standard Users**: Uses global npm installation if available, falls back to bundled
- **Manual Installation**: Run `npm install -g mcp-hub@latest` for global installation

**Implementation Details:**
- **Environment Detection**: Automatically detects NixOS/Nix environments
- **Smart Installation**: Uses global mcp-hub if available, bundled otherwise  
- **Event-driven loading**: Loads on `User AvantePreLoad` event for integration
- **Clean configuration**: Minimal setup with automatic environment adaptation
- **Cross-platform troubleshooting**: Works reliably across different systems

## MCP Tool Integration

Avante includes a sophisticated MCP (Model Context Protocol) tool integration that automatically selects and uses the most relevant tools based on conversation context. The system uses a hybrid tool registry with smart defaults to provide seamless access to documentation, search, and development tools.

### Architecture

The MCP integration features an intelligent, scalable approach:

1. **Environment Detection**: Automatically detects NixOS/Nix vs standard environments
2. **Smart Installation Choice**: Uses global installation when available, bundled otherwise
3. **Hybrid Tool Registry**: Context-aware tool selection with persona-specific defaults
4. **Dynamic Enhancement**: Tools added based on conversation keywords and context
5. **Token Budgeting**: Prevents context bloat while ensuring relevant tools are available
6. **Parameter Mapping**: Automatic API compatibility handling for different MCP servers
7. **Lazy Loading**: MCPHub loads via lazy.nvim when needed
8. **Event-Based Triggering**: Uses `User AvantePreLoad` event for Avante integration
9. **Automatic Integration**: Works seamlessly with standard Avante commands
10. **Cross-Platform Reliability**: Works consistently across different systems

### Smart Tool Selection

The hybrid tool registry automatically selects relevant MCP tools based on:

- **Persona Defaults**: Each persona (researcher, coder, tutor, expert) has curated default tools
- **Context Enhancement**: Conversation keywords trigger additional relevant tools
- **Priority Management**: High-priority tools included first within token budget
- **Token Budgeting**: Maximum 2000 tokens for tool descriptions, 8 tools max per conversation
- **Automatic Library Detection**: Recognizes library/framework mentions and selects Context7
- **Multi-Step Workflows**: Handles complex tool sequences automatically

The `<leader>hx` command provides direct access to the MCPHub interface.

### Available MCP Servers and Tools

The integration provides access to 5 powerful MCP servers with 44+ tools:

#### Context7 (Library Documentation) - 2 Tools
- **Server**: `github.com/upstash/context7-mcp`
- **Tools**: 
  - `resolve-library-id`: Find Context7-compatible library IDs for any library
  - `get-library-docs`: Retrieve comprehensive up-to-date documentation
- **Usage**: Perfect for getting current documentation for React, Vue, Express, TypeScript, etc.
- **Features**: Smart library resolution, topic-focused docs, trust-scored results

#### Tavily (Web Search & Crawling) - 4 Tools  
- **Server**: `tavily`
- **Tools**:
  - `tavily-search`: AI-optimized web search with real-time results
  - `tavily-extract`: Extract and process content from specific URLs
  - `tavily-crawl`: Systematic website crawling with configurable depth
  - `tavily-map`: Map and analyze website structure and navigation
- **Usage**: Current news, research, real-time information, content analysis
- **Features**: Country filtering, content depth control, domain inclusion/exclusion

#### GitHub Integration - 26 Tools
- **Server**: `github`
- **Tools**: Complete GitHub API integration including:
  - Repository management (create, fork, search, file operations)
  - Issue tracking (create, update, comment, search)
  - Pull request operations (create, review, merge, status checks)
  - Branch management and commit history
  - User and code search across GitHub
- **Usage**: Full GitHub workflow integration for repository operations
- **Features**: Supports personal and organization repositories, comprehensive API coverage

#### Git (Local Repository Management) - 11 Tools
- **Server**: `git`
- **Tools**:
  - `git_status`: Working tree status and staging area
  - `git_diff_*`: View unstaged, staged, and cross-branch changes
  - `git_add/commit/reset`: Stage files, create commits, unstage changes
  - `git_log/show`: View commit history and specific commit contents
  - `git_create_branch/checkout`: Branch creation and switching
- **Usage**: Local Git repository operations without remote dependencies
- **Features**: Complete local Git workflow, branch management, history access

#### Fetch (Web Content Extraction) - 1 Tool
- **Server**: `fetch`
- **Tools**:
  - `fetch`: Retrieve web content and convert HTML to markdown
- **Usage**: Extract content from specific web pages for analysis
- **Features**: Configurable length limits, raw HTML option, automatic markdown conversion

### Automatic MCP Tool Usage

Avante automatically selects and uses MCP tools based on your questions - no explicit tool mentions required. The system intelligently routes queries to the most appropriate tools:

**Library/Framework Questions → Context7:**
```
How do I implement authentication in Next.js?
Show me React hooks for state management
Get Vue 3 Composition API documentation
```

**Current Information → Tavily:**
```
What are the latest JavaScript frameworks in 2024?
Recent security vulnerabilities in Node.js
Current web development trends
```

**Development Operations → GitHub/Git:**
```
Show me popular Neovim plugins
Create a feature branch for authentication
What are the recent commits in this repository?
```

Avante automatically:
1. **Detects** the type of information needed
2. **Selects** appropriate MCP tools from the registry
3. **Executes** multi-step workflows (e.g., resolve library → get documentation)
4. **Returns** comprehensive, up-to-date results

### Behind the Scenes: Automatic Tool Workflows

When you ask library-related questions, Avante automatically executes sophisticated workflows:

**Context7 Documentation Workflow:**
1. **Resolve Library ID**: Maps library names to Context7-compatible identifiers
2. **Retrieve Documentation**: Gets specific topic documentation with proper parameters
3. **Parameter Mapping**: Handles API compatibility automatically

**Tavily Search Workflow:**
1. **Query Optimization**: Formats queries for AI-optimized search
2. **Result Filtering**: Applies appropriate filters based on context
3. **Content Extraction**: Processes results for relevant information

**Multi-Library Support:**
```
I need to integrate Prisma ORM with Express.js for a REST API
```
→ Automatically resolves both Prisma and Express.js documentation

### Intelligent Tool Selection Examples

The system automatically chooses the right tools based on conversation context:

**Documentation Queries:**
- "How do I use React hooks?" → **Context7** (official React documentation)
- "Vue 3 Composition API examples" → **Context7** (Vue.js documentation)
- "Express.js middleware setup" → **Context7** (Express.js documentation)
- "TypeScript utility types" → **Context7** (TypeScript documentation)

**Current Information Queries:**
- "Latest JavaScript trends 2024" → **Tavily** (current web search)
- "Recent Node.js security updates" → **Tavily** (current news)
- "Modern CSS frameworks comparison" → **Tavily** (current analysis)

**Development Queries:**
- "Popular Neovim LSP plugins" → **GitHub** (repository search)
- "Git workflow best practices" → **Git** + **Tavily** (local Git + current practices)
- "Create feature branch" → **Git** (local repository operations)

**Multi-Tool Workflows:**
- "Integrate Prisma with Next.js" → **Context7** (both Prisma and Next.js docs)
- "Modern authentication with React" → **Context7** (React docs) + **Tavily** (current patterns)
- "Deploy Express app to GitHub Pages" → **Context7** (Express docs) + **GitHub** (deployment)

### MCP Tools Commands

Additional commands for MCP integration and tool registry management:

- `:MCPHub`: Access MCPHub interface to see all server status
- `:MCPHubStatus`: Check connection status of all MCP servers
- `:MCPHubDiagnose`: Comprehensive MCP Hub connection diagnosis
- `:MCPToolsShow [persona]`: Show selected tools for a specific persona
- `:MCPPromptTest [persona] [context]`: Test enhanced prompt generation with context
- `:MCPSystemPromptTest`: Check current Avante system prompt configuration
- `:MCPAvanteConfigTest`: Verify Avante configuration and disabled tools
- `:MCPForceReload`: Force reload Avante configuration with MCP fixes
- `:MCPDebugToggle`: Toggle MCPHub debug mode for verbose logging

### Current MCP Server Status

**✅ All 5 MCP Servers Active:**
- **Context7**: 2 tools (library documentation)
- **Tavily**: 4 tools (web search and crawling)  
- **GitHub**: 26 tools (complete GitHub API)
- **Git**: 11 tools (local repository management)
- **Fetch**: 1 tool (web content extraction)

**Total: 44+ MCP tools available in Avante**

### Troubleshooting MCP Tools

If MCP tools show connection or usage errors:

1. **Diagnose Connection**: Run `:MCPHubDiagnose` for comprehensive status check
2. **Check Hub Status**: Verify MCP Hub is running with `:MCPHubStatus`
3. **View Server Status**: Use `:MCPHub` to see detailed server information
4. **Reload Configuration**: Run `:MCPForceReload` to refresh Avante settings
5. **Test Tool Selection**: Use `:MCPToolsShow expert` to verify tool registry
6. **Enable Debug Mode**: Run `:MCPDebugToggle` to see detailed MCPHub startup messages

**Advanced Troubleshooting Scripts**: For deeper diagnosis and repair, see [`scripts/README.md`](../../../../scripts/README.md):

- **Complete Integration Test**: `scripts/test_mcp_integration.lua` - Comprehensive MCP setup verification
- **Force MCP Restart**: `scripts/force_mcp_restart.lua` - Complete MCP integration restart
- **Individual Tool Testing**: `scripts/test_mcp_tools.lua` - Test Context7 and Tavily directly
- **Plugin Analysis**: `scripts/check_plugins.lua` - Verify plugin loading and organization

**Quick Script Usage**:
```vim
:luafile scripts/test_mcp_integration.lua  " Full integration test
:luafile scripts/force_mcp_restart.lua     " Force MCP restart
:luafile scripts/test_mcp_tools.lua        " Test individual tools
```

**Key Features:**
- **Automatic Parameter Mapping**: Handles API compatibility across different MCP servers
- **Intelligent Tool Selection**: Context-aware selection based on conversation content
- **Multi-Step Workflows**: Seamlessly chains multiple tool calls for complex queries
- **Token Budget Management**: Prevents context overflow while maintaining functionality
- **Cross-Platform Compatibility**: Works reliably on NixOS and standard systems
- **Zero-Configuration**: Automatic setup with smart defaults for all personas

### Integration Details

#### Plugin Configuration

**MCP-Hub Plugin Definition** (`lua/neotex/plugins/ai/mcp-hub.lua`)
- Cross-platform lazy.nvim plugin specification
- Environment detection for NixOS vs standard systems
- Intelligent installation method selection
- Automatic fallback to bundled installation when needed
- Dependencies: `plenary.nvim`
- Loads on specific commands and events

#### Loading Sequence

1. User triggers Avante with a keybinding like `<leader>ha`
2. This fires the `AvantePreLoad` event to load MCPHub
3. Lazy.nvim loads the MCPHub plugin in response to the event
4. MCPHub plugin initializes using its built-in functionality
5. Avante command executes with MCPHub integration available


## System Prompts

The system prompts manager provides complete prompt management with default personalities (Expert, Coder, Tutor) and full CRUD operations.

**Quick Access:**
- `:AvantePrompt` - Select from available prompts
- `:AvantePromptManager` - Full management interface
- `<leader>hp` - Quick prompt selection

For detailed prompt management documentation, see [`util/README.md`](util/README.md#system-promptslua).

## Cross-Platform Installation

MCP-Hub works across all platforms with intelligent environment detection that automatically chooses the best installation method for your system.

### Automatic Environment Detection

The configuration automatically detects your environment and selects the appropriate installation method:

- **NixOS Detection**: Checks for `/etc/NIXOS`, `NIX_STORE` environment variable, or `nix` executable
- **Global Installation Check**: Tests if `mcp-hub` is available globally via npm
- **Smart Fallback**: Uses bundled installation when global installation is not available

### Platform-Specific Features

- **Standard Environments**: Prefers global npm installation when available
- **NixOS/Nix Environments**: Uses bundled installation for compatibility
- **Environments without npm**: Automatically falls back to bundled binary approach
- **No Manual Configuration**: Works out-of-the-box on any platform
- **Installation Feedback**: Shows which method is being used in notifications

### Installation Methods

The system automatically chooses between these methods based on your environment:

1. **Global npm Installation (Preferred for Standard Systems)**
   - Used when `mcp-hub` is globally available via npm
   - Install manually with: `npm install -g mcp-hub@latest`
   - Automatically detected and used when available
   - Provides the best performance and stability

2. **Bundled Installation (Automatic Fallback)**
   - Used on NixOS or when global installation is not available
   - Automatically downloads and installs mcp-hub locally via lazy.nvim
   - No manual setup required - handles everything automatically
   - Works in isolated environments like NixOS
   - Uses lazy.nvim's `build = "bundled_build.lua"` mechanism

3. **Manual Installation (Optional)**
   - For users who want to install globally on any system
   - Run: `npm install -g mcp-hub@latest`
   - The configuration will automatically detect and use it
   - Useful for users who prefer global package management

### Cross-Platform Experience

**All Users:** The configuration automatically detects your environment and chooses the optimal installation method. No manual configuration needed - just start using Avante with `<leader>ha` and MCPHub will be available automatically.

**Optional Manual Installation:** Run `npm install -g mcp-hub@latest` for global installation on standard systems (provides best performance).

## Troubleshooting

### General AI Integration Issues

1. Check if the AI service is properly configured with API keys
2. Ensure MCP-Hub is running with `:MCPHubStatus`
3. Try loading Avante first, which will automatically load MCPHub
4. Verify the model selection with `:AvanteModel`
5. Check the system prompt with `:AvantePrompt`
6. Try stopping any ongoing generations with `:AvanteStop`

### MCPHub Installation Issues

**Check Installation Method:**
- Look for "MCPHub ready (bundled installation)" or "MCPHub ready (global installation)" message
- This tells you which method is being used

**If MCPHub fails to load:**

1. **For Standard Users:**
   - Try installing globally: `npm install -g mcp-hub@latest`
   - Restart NeoVim and check if it detects the global installation
   - If still failing, the bundled fallback should activate automatically

2. **For NixOS Users:**
   - The bundled installation should work automatically
   - If failing, check if Node.js is available: `node --version`
   - Try running `:Lazy build mcphub.nvim` to rebuild the bundled installation

3. **If MCPHub commands aren't available:**
   - Launch Avante first with `<leader>ha` or `<leader>hc`
   - Wait for the "MCPHub ready" message
   - Then try running `:MCPHub` to open the interface

### Environment-Specific Solutions

**For Standard Users (Linux/macOS/Windows):**
1. Install globally for best performance: `npm install -g mcp-hub@latest`
2. Restart NeoVim to detect the global installation
3. If npm is not available, the bundled fallback will activate automatically

**For NixOS/Nix Users:**
1. The bundled installation should work automatically - no action needed
2. If Node.js is missing, ensure it's available in your environment
3. Try rebuilding: `:Lazy build mcphub.nvim`
4. Check the bundled installation: `ls -la ~/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/`

### Quick Reference

| Command | Description |
|---------|-------------|
| `:MCPHub` | Launch the MCP-Hub interface |
| `:MCPHubStatus` | Check connection status |
| `:Lazy build mcphub.nvim` | Rebuild bundled installation |
| `<leader>hx` | Quick access to MCPHub interface |

### Installation Verification

**Check which method is active:**
- Look for "MCPHub ready (bundled installation)" or "MCPHub ready (global installation)" in notifications
- Run `:MCPHubStatus` to verify connection

**Manual global installation (optional):**
```bash
npm install -g mcp-hub@latest
```

**Cross-platform compatibility verified** - the configuration automatically adapts to your environment and provides reliable MCPHub integration regardless of whether you're using NixOS, standard Linux, macOS, or Windows.

### Debug Mode

By default, MCPHub operates in quiet mode to keep the interface clean. You can enable debug mode for troubleshooting:

**Enable Debug Mode:**
```vim
:MCPDebugToggle
```

**Or set globally in your configuration:**
```lua
vim.g.mcphub_debug_mode = true
```

**Debug mode shows:**
- MCPHub startup messages ("MCPHub ready (bundled NixOS installation)")
- Process cleanup notifications
- Detailed connection information

For more detailed information, refer to the individual module documentation or the help pages with `:h avante` or `:h lectic`.

## Navigation

- [AI Utilities →](util/README.md)
- [Tools Plugins →](../tools/README.md)
- [Editor Plugins →](../editor/README.md)
- [LSP Configuration →](../lsp/README.md)
- [UI Plugins →](../ui/README.md)
- [Text Plugins →](../text/README.md)
- [← Plugins Overview](../README.md)
