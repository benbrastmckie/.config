# AI Integration for NeoVim

This directory contains modules for integrating various AI services and tools with NeoVim, enhancing your coding and writing experience with advanced AI capabilities.

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
    └── system-prompts.lua           # System prompts manager
```

### Utility Modules

The `util/` directory contains essential support modules for AI functionality:

- **Core Management**: Model selection, provider switching, and settings persistence
- **System Prompts**: Complete prompt management system with CRUD operations
- **MCPHub Integration**: Server management and Avante-MCPHub coordination
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

## Using MCP Tools in Avante

The MCP-Hub integration enables Avante to access and use tools provided by MCP-Hub, expanding Avante's capabilities beyond what's built-in.

### Architecture

The MCPHub integration uses an intelligent cross-platform approach:

1. **Environment Detection**: Automatically detects NixOS/Nix vs standard environments
2. **Smart Installation Choice**: Uses global installation when available, bundled otherwise
3. **Lazy Loading**: MCPHub loads via lazy.nvim when needed  
4. **Event-Based Triggering**: Uses `User AvantePreLoad` event for Avante integration
5. **Automatic Integration**: Just use Avante normally with `<leader>ha`, `<leader>hc`, or `<leader>ht`
6. **Installation Feedback**: Shows which installation method is being used
7. **Cross-Platform Reliability**: Works consistently across different systems

The `<leader>hx` command provides direct access to the MCPHub interface.

### Using MCP Tools in Prompts

The integration with MCPHub provides two ways to access tools in Avante:

#### 1. JSON Tool Syntax

You can use the standard JSON tool format:

```
I'd like you to use the MCP tool to search for information.

{
  "tool": "mcp",
  "input": {
    "tool": "websearch",
    "input": {
      "query": "latest Neovim release"
    }
  }
}
```

#### 2. Slash Commands (Recommended)

MCPHub automatically creates slash commands for all tools, making them easier to use:

```
What is the latest version of Neovim?

/websearch latest Neovim release version
```

The slash command format is more concise and supports auto-completion in Avante's interface.

### Supported MCP Tools

MCPHub provides access to these commonly available tools:

- `/websearch [query]`: Search the web for information
- `/weather [location]`: Get current weather information
- `/image_generate [prompt]`: Generate images from text descriptions
- `/executor [language] [code]`: Run code in a sandbox environment
- `/pdf [url]`: Extract and analyze content from PDF documents
- `/variables`: List all available variables from your servers
- `/servers`: List all connected servers and their status

Additional tools may be available depending on your specific MCPHub configuration and connected servers.

### Tool Parameters

Most tools accept parameters that can be provided in different ways:

```
# Simple query parameter
/websearch latest Neovim release

# Multiple parameters
/image_generate a cat sitting on a keyboard --style realistic --size 512x512

# Complex parameters using JSON
/executor {
  "language": "python",
  "code": "import math\nprint(math.sqrt(144))"
}
```

### Example Usage Patterns

Here are examples of effective MCPHub tool usage in Avante:

**Basic web search:**
```
What is the latest version of Neovim? Use MCPHub to find out.

/websearch latest Neovim release version
```

**Sequential tool usage:**
```
Can you help me understand this weather data and how it compares to historical averages?

/weather New York
Now let's compare this with historical data:
/websearch New York weather historical average
```

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

For more detailed information, refer to the individual module documentation or the help pages with `:h avante` or `:h lectic`.
