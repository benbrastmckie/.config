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
├── init.lua               # AI plugins loader
├── lectic.lua             # Lectic AI writing integration
├── mcp-hub.lua            # MCP-Hub plugin configuration and integration
└── util/                  # Utility modules for AI integration
    ├── avante-highlights.lua        # Enhanced highlighting for Avante UI
    ├── avante-support.lua           # Support functions for Avante configuration
    ├── system-prompts.json          # System prompt templates storage
    └── system-prompts.lua           # System prompts manager
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
- `MCPHub`: Start the MCP-Hub service
- `MCPHubStatus`: Check MCP-Hub service status
- `MCPHubSettings`: View/edit MCP-Hub configuration
- `MCPHubDiagnose`: Run diagnostics for MCP-Hub
- `MCPHubRebuild`: Rebuild the MCP-Hub bundled binary

## Using MCP Tools in Avante

The MCP-Hub integration enables Avante to access and use tools provided by MCP-Hub, expanding Avante's capabilities beyond what's built-in.

### Lazy-Loading Setup

The integration is now fully automated with smart lazy-loading:

1. MCPHub only launches when Avante is opened, not at Neovim startup
2. Just use Avante directly with `<leader>ha`, `<leader>hc`, or `<leader>ht` 
3. MCPHub will automatically load in the background when needed
4. No manual steps required - everything is handled automatically

The `<leader>hx` command is available if you want to manually start MCPHub.

### Using MCP Tools in Prompts

To use MCP tools in your Avante prompts, use the following syntax:

```
I'd like you to use the MCP tool to [task description].

For example:
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

### Supported MCP Tools

Depending on your MCP-Hub configuration, the following tools might be available:

- `websearch`: Search the web for information
- `weather`: Get weather information for a location
- `executor`: Execute code in a sandbox environment
- `image`: Generate or analyze images
- `pdf`: Extract information from PDF documents

### Example Usage

Here's an example of using the MCP websearch tool with Avante:

1. Open Avante with `<leader>ha`
2. Type the following prompt:

```
What is the latest version of Neovim? Use the MCP tools to find out.

{
  "tool": "mcp",
  "input": {
    "tool": "websearch",
    "input": {
      "query": "latest Neovim release version"
    }
  }
}
```

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
- `MCPHUB_README.md` for quick troubleshooting guide

## Troubleshooting

If you encounter issues with the AI integration:

1. Check if the AI service is properly configured with API keys
2. Ensure MCP-Hub is running with `:MCPHubStatus`
3. Verify the model selection with `:AvanteModel`
4. Check the system prompt with `:AvantePrompt`
5. Try stopping any ongoing generations with `:AvanteStop`
6. Run `:MCPHubDiagnose` for detailed diagnostics on any platform

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
7. See detailed options in `MCPHUB_README.md` for additional solutions

For more detailed information, refer to the individual module documentation or the help pages with `:h avante` or `:h lectic`.
