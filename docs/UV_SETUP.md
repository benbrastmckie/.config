# Setting Up UV Package Manager for MCP-Hub

This Neovim configuration uses the `uv` package manager for installing and running MCP-Hub. This document explains how to set up `uv` on different platforms.

## What is UV?

[UV](https://github.com/astral-sh/uv) is a modern, fast package manager for Python and Node.js written in Rust. It's designed to be a drop-in replacement for pip and npm with significant speed improvements and better dependency resolution.

## Installing UV

### On macOS

Using Homebrew:
```bash
brew install astral-sh/tap/uv
```

### On Linux (Ubuntu/Debian)

Using curl:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Or using apt (if available):
```bash
sudo apt update
sudo apt install uv
```

### On NixOS

Using nix-env:
```bash
nix-env -iA nixpkgs.uv
```

Or add to your configuration.nix/home.nix:
```nix
environment.systemPackages = with pkgs; [
  uv
];
```

### On Windows

Using Scoop:
```bash
scoop install uv
```

Or using Chocolatey:
```bash
choco install uv
```

## Verifying Installation

To verify that UV is installed correctly:

```bash
uv --version
```

This should display the version of UV installed on your system.

## Installing MCP-Hub with UV

Once UV is installed, you can manually install MCP-Hub with:

```bash
uv install mcp-hub
```

This should be done automatically by the Neovim configuration, but you can run it manually if needed.

## Troubleshooting

### Common Issues

1. **Command not found**:
   If you get "command not found" when running `uv`, make sure it's in your PATH.

2. **Permission denied**:
   If you get permission errors, try running with `sudo` or check file permissions.

3. **Installation fails**:
   Try running `uv install mcp-hub --verbose` to see more detailed error messages.

### Platform-Specific Issues

#### NixOS

If you're on NixOS and get dependency resolution errors, try:

```bash
nix-shell -p nodePackages.mcp-hub
```

Then run Neovim from that shell.

#### Windows

On Windows, you might need to run your terminal as administrator for global installations. Alternatively, use a user-scoped installation with:

```bash
uv install --user mcp-hub
```

## Getting Help

If you're still having issues:

- Check the [UV GitHub repository](https://github.com/astral-sh/uv) for detailed documentation
- Refer to the [MCP-Hub documentation](https://github.com/ravitemer/mcphub.nvim) for specific package requirements
- Look at the error messages in Neovim (run `:MCPHubStatus` to see recent errors)