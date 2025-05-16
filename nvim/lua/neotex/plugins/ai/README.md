# AI Integration for NeoVim

This directory contains modules for integrating various AI services and tools with NeoVim, enhancing your coding and writing experience with advanced AI capabilities.

## Components

- **Avante Integration**: Connect with the Avante plugin for AI-assisted coding and chat
- **Lectic Integration**: Add AI-assisted writing with structured prompts
- **MCP-Hub Integration**: Access multiple AI services through a unified hub
- **System Prompts**: Manage and customize AI behavior with templates

## Directory Structure

```
lua/neotex/plugins/ai/
├── README.md              # This file - overview and documentation
├── init.lua               # AI plugins loader with event registration
├── avante.lua             # Avante AI assistant configuration
├── lectic.lua             # Lectic AI writing integration
├── mcp-hub.lua            # MCP-Hub plugin configuration
└── util/                  # Utility modules for AI integration
    ├── avante-highlights.lua        # Enhanced highlighting for Avante UI
    ├── avante-support.lua           # Support functions for Avante configuration
    ├── system-prompts.json          # System prompt templates storage
    ├── system-prompts.lua           # System prompts manager
    ├── mcp_server.lua               # MCPHub server state management and control
    └── avante_mcp.lua               # Avante and MCPHub integration layer
```

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

### MCP-Hub Integration

MCP-Hub provides a unified interface to multiple AI services and tools.

**Key Features:**
- Access to multiple AI providers
- Web search capabilities
- Code execution in sandbox environments
- PDF document analysis
- Weather information
- Image generation and analysis

**Commands:**
- `MCPHub`: Open the MCP-Hub interface (available after loading Avante)
- `MCPHubStatus`: Check MCP-Hub connection status
- `MCPHubStart`: Manually start the MCP-Hub server
- `MCPAvante`: Open Avante with MCPHub integration
- `MCPAvanteTrigger`: Trigger loading of MCPHub plugin

**Implementation Details:**
- Uses advanced state management through `neotex.plugins.ai.util.mcp_server` module
- Event-driven architecture with `User AvantePreLoad` event
- Clean integration layer in `neotex.plugins.ai.util.avante_mcp` module
- Intelligent binary detection and execution logic
- Multiple server status verification mechanisms
- Self-healing error handling with fallbacks

## Using MCP Tools in Avante

The MCP-Hub integration enables Avante to access and use tools provided by MCP-Hub, expanding Avante's capabilities beyond what's built-in.

### Optimized Lazy-Loading Architecture

The MCPHub integration has been completely redesigned with a more reliable and efficient architecture:

1. **True Lazy Loading**: MCPHub only loads when explicitly needed, never at Neovim startup
2. **Event-Based Triggering**: Uses custom Neovim events for precise lazy loading
3. **State Management**: Centralized state tracking prevents duplicate server instances
4. **Automatic Integration**: Just use Avante normally with `<leader>ha`, `<leader>hc`, or `<leader>ht`
5. **Clean UI**: Minimal notifications - only success messages are shown
6. **Robust Server Detection**: Automatically verifies server is running with HTTP checks

The `<leader>hx` command provides a smart wrapper to open the MCPHub interface:
- Automatically loads the MCPHub plugin if not loaded
- Starts the server if it's not already running 
- Opens the MCPHub interface when ready
- Handles all edge cases with appropriate timing

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

**Tool with code execution:**
```
Can you write a Python function to calculate Fibonacci numbers and then test it?

Here's a function to calculate Fibonacci numbers:
```python
def fibonacci(n):
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a
```

Let's test it:
/executor python
def fibonacci(n):
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a

for i in range(10):
    print(f"fibonacci({i}) = {fibonacci(i)}")
```

### Integration Architecture

The MCPHub integration is implemented with a clean, modular architecture:

#### Key Components

1. **MCP-Hub Plugin Definition** (`lua/neotex/plugins/ai/mcp-hub.lua`)
   - Defines the plugin with true lazy loading 
   - Configures Lazy.nvim to only load on specific events
   - Configured to never load at startup
   - Sets up build and configuration functions

2. **Server Management** (`lua/neotex/plugins/ai/util/mcp_server.lua`)
   - Central state management for MCPHub server
   - Intelligent executable detection for all platforms
   - Multiple server status verification mechanisms
   - Handles server lifecycle (start, stop, check)
   - Provides server status tracking and commands

3. **Integration Layer** (`lua/neotex/plugins/ai/util/avante_mcp.lua`)
   - Clean API for Avante to interact with MCPHub
   - Handles event triggering for lazy loading
   - Manages command registration
   - Seamless autocommand integration
   - Self-healing error handling

4. **Event Registration** (`lua/neotex/plugins/ai/init.lua`)
   - Sets up custom events for plugin communication
   - Initializes integration layer after plugins are loaded
   - Registers handlers for AvantePreLoad event
   - Enables direct plugin loading when needed

#### Loading Sequence

1. User triggers Avante with a keybinding like `<leader>ha`
2. This fires the `AvantePreLoad` event to load MCPHub
3. Lazy.nvim loads the MCPHub plugin in response to the event
4. The plugin is configured and initialized
5. The server manager starts the MCPHub server
6. HTTP status checks verify the server is running
7. Success message "MCPHub server ready" is displayed
8. Avante command executes with full MCPHub integration

## System Prompts

The system prompts manager allows you to define and switch between different AI personalities and behaviors.

### Available Prompts

- **Expert**: Mathematics, logic, and computer science expert
- **Coder**: Focused on code implementation with minimal explanation
- **Tutor**: Educational assistant focused on clear explanations

### Managing Prompts

- Use `AvantePromptManager` to open the system prompts manager
- Use `AvantePrompt` to quickly select a system prompt
- Use `<leader>hp` to select a system prompt

### Creating Custom Prompts

1. Run `:AvantePromptManager`
2. Select "Create New Prompt"
3. Enter the prompt ID, name, and description
4. Edit the system prompt text in the buffer that opens
5. Press Enter to save

## Cross-Platform Installation

MCP-Hub works across all platforms with smart environment detection that ensures the right installation approach is used for your system.

### Platform-Specific Features

- **Standard Environments**: Uses global npm installation on most systems
- **Environments without npm**: Falls back to bundled binary approach automatically
- **NixOS Integration**: Special handling for NixOS's unique package environment
- **Auto-Installation**: Automatically runs installation script for NixOS users on first launch
- **UVX Compatibility**: Works with UVX package manager for both NixOS and standard environments
- **Diagnostics**: Enhanced diagnostics to help troubleshoot any installation issues

### Installation Methods

1. **Global npm (Standard Users)**
   - Default for most systems with Node.js/npm installed
   - Clean installation using `npm install -g mcp-hub@latest`
   - Automatically detected and configured
   - No special configuration needed

2. **Auto-Installation for NixOS (Improved)**
   - Automatically runs the installation script for NixOS users during plugin build
   - No manual steps required - installation happens before plugin setup
   - Runs synchronously to ensure the binary is ready when needed
   - Creates a flag file to ensure it only runs once
   - Checks binary existence even if flag file exists
   - Falls back to manual installation if auto-installation fails

3. **UVX Method (Recommended for NixOS)**
   - Install UVX via your flake or Nix config
   - MCP-Hub automatically detects and uses UVX for installation
   - No errors or additional configuration needed

4. **Bundled Binary Method (Fallback)**
   - Automatically used when global installation is not available
   - Works within NixOS's pure environment constraints
   - Also works on standard systems without npm
   - Uses wrapper script on NixOS for proper path resolution

5. **Manual Path Configuration (Custom)**
   - Set `vim.g.mcp_hub_path` to a specific binary location
   - Useful for custom installations or unusual environments
   - Example: `vim.g.mcp_hub_path = "/path/to/your/mcp-hub"`

For detailed information on the NixOS integration, check the documentation in:
- `specs/BUNDLED.md` for bundled binary approach
- `specs/SOLUTION.md` for comprehensive installation solutions

## Troubleshooting

If you encounter issues with the AI integration:

1. Check if the AI service is properly configured with API keys
2. Ensure MCP-Hub is running with `:MCPHubStatus`
3. If MCP-Hub isn't running, start it manually with `:MCPHubStart`
4. Try loading Avante first, which will automatically load MCPHub
5. Verify the model selection with `:AvanteModel`
6. Check the system prompt with `:AvantePrompt`
7. Try stopping any ongoing generations with `:AvanteStop`

If MCPHub commands aren't available:
1. Launch Avante first with `<leader>ha` or `<leader>hc`
2. Wait for the "MCPHub server ready" message
3. Then try running `:MCPHub` to open the interface

### Quick Solutions for NixOS

If you're having trouble with MCP-Hub on NixOS, try these solutions in order:

1. **Use the wrapper script approach**:
   ```lua
   -- In your plugin configuration
   local setup_config = {
     use_bundled_binary = false,
     cmd = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/mcp-hub-wrapper"),
     cmdArgs = {},
     -- other settings...
   }
   ```

2. **Run the NixOS installation script**:
   ```bash
   bash ~/.config/nvim/scripts/mcp-hub-nixos-install.sh
   ```

3. **Use the MCPHubInstallManual command**:
   ```
   :MCPHubInstallManual
   ```

4. **Set MCP_HUB_PATH environment variable**:
   ```lua
   -- In your init.lua
   vim.g.mcp_hub_path = "~/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/mcp-hub-wrapper"
   ```

### Full Command Reference

| Command | Description |
|---------|-------------|
| `:MCPHub` | Launch the MCP-Hub interface |
| `:MCPHubDiagnose` | Display diagnostics information |
| `:MCPHubRebuild` | Rebuild the bundled binary |
| `:MCPHubInstallManual` | Install using alternative method |
| `:MCPHubStatus` | Check connection status |
| `:MCPHubStart` | Manually start the MCPHub server |
| `:MCPAvanteTrigger` | Trigger loading of MCPHub plugin |
| `:MCPAvante` | Open Avante with MCPHub integration |

### Standard Environment Troubleshooting

If you're experiencing issues on a standard (non-NixOS) environment:

1. Run `:MCPHubDiagnose` to view detailed installation information
2. Check if global mcp-hub is installed with `npm list -g | grep mcp-hub`
3. Try reinstalling mcp-hub globally with `npm install -g mcp-hub@latest`
4. If npm install fails, try the bundled approach: `:MCPHubRebuild`
5. For permission issues, use `sudo npm install -g mcp-hub@latest` or set up npm for global packages without sudo

### NixOS-Specific Troubleshooting

If you're experiencing issues on NixOS:

1. Run `:MCPHubDiagnose` to view detailed diagnostic information
2. Check if auto-installation has run by looking for the flag file: `cat ~/.local/share/nvim/mcp-hub/nixos_installed`
3. Try triggering a manual installation with `:MCPHubInstallManual`
4. Run the installation script manually: `bash ~/.config/nvim/scripts/mcp-hub-nixos-install.sh`
5. Check if UVX is properly installed with `which uvx` in your terminal
6. Delete the flag file to trigger auto-installation again: `rm ~/.local/share/nvim/mcp-hub/nixos_installed`
7. Check if binary exists: 
   ```bash
   ls -la ~/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/node_modules/.bin/mcp-hub
   ```
8. Check Node.js: 
   ```bash
   node --version
   ```
9. Check wrapper script:
   ```bash
   cat ~/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/mcp-hub-wrapper
   ```
10. Check if MCPHub loads properly with Avante:
    ```
    :MCPHubStatus
    :AvanteAsk "Test question"
    :MCPHubStatus  # Check again after using Avante
    ```

### Installation Scripts

Two installation scripts are available:

1. `/home/benjamin/.config/nvim/scripts/install-mcp-hub.sh`
   - Basic installation script

2. `/home/benjamin/.config/nvim/scripts/mcp-hub-nixos-install.sh`
   - Advanced installation with better error handling

### Best Solution for NixOS

The most reliable approach for NixOS is:

1. Run the installation script: `bash ~/.config/nvim/scripts/mcp-hub-nixos-install.sh`
2. Use the wrapper script approach in your config
3. Restart Neovim and use Avante with `<leader>ha` or `<leader>hc`
4. Check MCPHub status with `:MCPHubStatus`

For more detailed information, refer to the individual module documentation or the help pages with `:h avante` or `:h lectic`.
