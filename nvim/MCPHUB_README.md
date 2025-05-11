# MCP-Hub for NixOS

This document provides a quick reference for using MCP-Hub on NixOS.

## Quick Solutions

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

## Commands Reference

| Command | Description |
|---------|-------------|
| `:MCPHub` | Launch the MCP-Hub interface |
| `:MCPHubDiagnose` | Display diagnostics information |
| `:MCPHubRebuild` | Rebuild the bundled binary |
| `:MCPHubInstallManual` | Install using alternative method |
| `:MCPHubStatus` | Check connection status |
| `:MCPHubSettings` | Edit settings |

## Installation Scripts

Two installation scripts are available:

1. `/home/benjamin/.config/nvim/scripts/install-mcp-hub.sh`
   - Basic installation script

2. `/home/benjamin/.config/nvim/scripts/mcp-hub-nixos-install.sh`
   - Advanced installation with better error handling

## Documentation

Detailed documentation is available in these files:

- `/home/benjamin/.config/nvim/specs/BUNDLED.md` - Main documentation for bundled approach
- `/home/benjamin/.config/nvim/specs/SOLUTION.md` - Summary of all solutions implemented

## Troubleshooting

If MCP-Hub isn't working:

1. Check diagnostics: `:MCPHubDiagnose`
2. Check if binary exists: 
   ```bash
   ls -la ~/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/node_modules/.bin/mcp-hub
   ```
3. Check Node.js: 
   ```bash
   node --version
   ```
4. Check wrapper script:
   ```bash
   cat ~/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/mcp-hub-wrapper
   ```

## Best Solution for NixOS

The most reliable approach for NixOS is:

1. Run the installation script: `bash ~/.config/nvim/scripts/mcp-hub-nixos-install.sh`
2. Use the wrapper script approach in your config
3. Restart Neovim and run `:MCPHub`