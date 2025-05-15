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

### Setup

The integration is automatically enabled when both MCP-Hub and Avante are loaded:

1. Start MCP-Hub first with `:MCPHub` command
2. Then use Avante as usual with `<leader>ha` or other Avante commands

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

## NixOS Integration

While MCP-Hub works across all platforms, special care has been taken to ensure smooth operation on NixOS through a dedicated integration batch.

### NixOS-Specific Features

- **Bundled Binary Mode**: Falls back to a bundled binary when global installation is not available
- **UVX Compatibility**: Works with UVX package manager, the recommended installation method
- **Home Manager Support**: Can be installed via home-manager for clean integration
- **Nix Flake Support**: Provides flake-based installation for reproducible deployment

### Installation Methods for NixOS

1. **UVX Method (Recommended)**
   - Install UVX via your flake or Nix config
   - MCP-Hub automatically detects and uses UVX for installation

2. **Bundled Binary Method**
   - Automatically falls back to a bundled binary approach when UVX is not available
   - Works within NixOS's pure environment constraints

3. **Flake-Based Installation**
   - For advanced users who prefer a fully flake-managed setup
   - Configuration available in a dedicated batch (see specs/PHASE4_IMPLEMENTATION.md)

For detailed information on the NixOS integration, check the documentation in `specs/PHASE4_IMPLEMENTATION.md` under "Batch 5: Nix Flake Integration".

## Troubleshooting

If you encounter issues with the AI integration:

1. Check if the AI service is properly configured with API keys
2. Ensure MCP-Hub is running with `:MCPHubStatus`
3. Verify the model selection with `:AvanteModel`
4. Check the system prompt with `:AvantePrompt`
5. Try stopping any ongoing generations with `:AvanteStop`
6. For NixOS-specific issues, run `:MCPHubDiagnose` for detailed diagnostics

### NixOS-Specific Troubleshooting

If you're experiencing issues on NixOS:

1. Run `:MCPHubDiagnose` to view detailed diagnostic information
2. Check if UVX is properly installed with `which uvx` in your terminal
3. Try manual installation with `:MCPHubInstallManual`
4. For flake-related issues, refer to the implementation notes in `specs/PHASE4_IMPLEMENTATION.md`

For more detailed information, refer to the individual module documentation or the help pages with `:h avante` or `:h lectic`.
