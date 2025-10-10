# NixOS Workflows

## Purpose

This document describes NixOS system management integration in the NeoVim configuration, including system rebuilding, package management, development environments, and Nix language support.

## NixOS Management Commands

### System Operations

The configuration provides convenient keybindings for common NixOS operations:

| Key | Command | Description |
|-----|---------|-------------|
| `<leader>nr` | Rebuild system | `sudo nixos-rebuild switch --flake .` |
| `<leader>nh` | Apply home-manager | `home-manager switch --flake .` |
| `<leader>nu` | Update dependencies | `nix flake update` |
| `<leader>ng` | Garbage collection | `nix-collect-garbage -d` |
| `<leader>nd` | Development shell | `nix develop` |

**Configuration**: `lua/neotex/plugins/editor/which-key.lua` (NixOS management section)

### Rebuild Workflow

```
┌─────────────────────────────────────┐
│ Edit Nix Configuration              │
│ • Modify /etc/nixos/configuration.nix│
│ • Update flake.nix                  │
│ • Edit home-manager config          │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ Rebuild System                      │
│ <leader>nr                          │
│ • Evaluates configuration           │
│ • Builds new system                 │
│ • Activates new generation          │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ Verify Changes                      │
│ • Check services: systemctl status  │
│ • Verify packages: which [command]  │
│ • Rollback if needed: <leader>nr    │
└─────────────────────────────────────┘
```

## Package Management

### Finding Packages

**Web Resources**:

| Key | Action | URL |
|-----|--------|-----|
| `<leader>np` | Open NixOS packages | https://search.nixos.org/packages |
| `<leader>nm` | Open MyNixOS | https://mynixos.com |

**Command Line Search**:
```bash
# Search for package
nix search nixpkgs [package-name]

# Show package details
nix-env -qa --description [package-name]

# Check if package exists in current channel
nix-env -qaP | grep [package-name]
```

### Installing Packages

**System-Wide Installation**:
1. Add package to `/etc/nixos/configuration.nix`:
   ```nix
   environment.systemPackages = with pkgs; [
     git
     neovim
     ripgrep
   ];
   ```
2. Rebuild system: `<leader>nr`

**User-Level Installation** (Home Manager):
1. Add to `home.nix` or equivalent:
   ```nix
   home.packages = with pkgs; [
     fzf
     fd
   ];
   ```
2. Apply changes: `<leader>nh`

**Temporary Installation**:
```bash
# Install for current session
nix-shell -p [package-name]

# Use package immediately
nix run nixpkgs#[package-name]
```

## Flake Management

### Flake Structure

Typical Nix flake organization:
```
flake.nix              # Main flake configuration
├── inputs             # Dependencies (nixpkgs, home-manager, etc.)
├── outputs            # System configurations
│   ├── nixosConfigurations
│   └── homeConfigurations
└── flake.lock         # Lock file with exact versions
```

### Updating Flakes

**Update All Inputs**:
```vim
" In NeoVim
<leader>nu
```

This runs `nix flake update` which:
1. Checks all flake inputs for updates
2. Updates `flake.lock` with new versions
3. Does not activate changes (requires rebuild)

**Update Specific Input**:
```bash
nix flake lock --update-input nixpkgs
```

**After Update**:
- Review changes in `flake.lock`
- Rebuild to apply: `<leader>nr`
- Rollback if issues: `sudo nixos-rebuild switch --rollback`

## Development Environments

### Nix Development Shell

Enter project-specific development environment:

```vim
" In NeoVim
<leader>nd
```

This runs `nix develop`, which:
1. Reads `flake.nix` or `shell.nix` in current directory
2. Provides specified packages and environment variables
3. Enters shell with development tools available

### Common Development Patterns

**Python Development**:
```nix
# shell.nix or flake.nix devShell
{
  buildInputs = with pkgs; [
    python311
    python311Packages.pip
    python311Packages.virtualenv
  ];
}
```

**Rust Development**:
```nix
{
  buildInputs = with pkgs; [
    rustc
    cargo
    rust-analyzer
  ];
}
```

**Node.js Development**:
```nix
{
  buildInputs = with pkgs; [
    nodejs_20
    nodePackages.npm
  ];
}
```

### Project Setup

1. **Create `flake.nix`** in project root:
   ```nix
   {
     description = "Project development environment";

     inputs = {
       nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
     };

     outputs = { self, nixpkgs }:
       let
         system = "x86_64-linux";
         pkgs = nixpkgs.legacyPackages.${system};
       in {
         devShells.${system}.default = pkgs.mkShell {
           buildInputs = with pkgs; [
             # Add development dependencies here
           ];
         };
       };
   }
   ```

2. **Enter environment**: `<leader>nd`
3. **Work on project** with available tools
4. **Exit**: `exit` or `Ctrl-D`

## Nix Language Support

### Tree-sitter Nix Highlighting

Syntax highlighting for Nix files is provided by Tree-sitter:

- **Language**: Nix expression language
- **File Types**: `.nix` files
- **Features**: Syntax highlighting, indentation, folding

**Configuration**: Automatic through `nvim-treesitter` with Nix parser

### LSP for Nix

While not currently configured by default, LSP support can be added:

**Available LSP Servers**:
- **nil**: Nix language server
- **rnix-lsp**: Nix language server (older)

**To Enable**:
1. Install LSP server: Add to system packages
2. Configure in `lspconfig.lua`:
   ```lua
   lspconfig.nil_ls.setup({})
   ```
3. Restart NeoVim

## Garbage Collection

### Manual Cleanup

```vim
" In NeoVim
<leader>ng
```

This runs `nix-collect-garbage -d`, which:
1. Removes old generations
2. Deletes unused store paths
3. Frees disk space

**Effect**: Removes previous system generations, making rollback impossible

### Automatic Cleanup

Configure automatic garbage collection in `/etc/nixos/configuration.nix`:

```nix
nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 30d";
};
```

### Storage Management

**Check Disk Usage**:
```bash
# Show Nix store size
du -sh /nix/store

# Show generations
nix-env --list-generations

# Delete specific generation
nix-env --delete-generations [number]
```

**Optimize Store**:
```bash
# Remove duplicate files
nix-store --optimise
```

## System Rollback

If a rebuild causes issues, rollback to previous generation:

**Command Line**:
```bash
# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# List available generations
nix-env --list-generations --profile /nix/var/nix/profiles/system

# Boot specific generation
sudo nixos-rebuild switch --switch-generation [number]
```

**Boot Menu**:
- Reboot system
- Select "NixOS - [previous generation]" in GRUB
- System boots with previous configuration

## Configuration Workflow

### Typical Development Cycle

1. **Edit Configuration**
   - Open `/etc/nixos/configuration.nix` or `flake.nix`
   - Make changes (add packages, modify services, etc.)
   - Save file

2. **Test Build** (optional)
   ```bash
   nixos-rebuild test --flake .
   ```
   This activates changes without making boot default

3. **Apply Changes**
   ```vim
   <leader>nr
   ```
   Rebuilds and makes changes permanent

4. **Verify**
   - Check that services work: `systemctl status [service]`
   - Verify packages available: `which [command]`
   - Test functionality

5. **Rollback if Needed**
   ```bash
   sudo nixos-rebuild switch --rollback
   ```

### Home Manager Workflow

For user-specific configuration:

1. **Edit** `home.nix` or equivalent
2. **Apply**: `<leader>nh`
3. **Verify**: Check that dotfiles and packages updated
4. **Rollback**: `home-manager generations` and select previous

## Integration with NeoVim

### NixOS-Specific Considerations

**Plugin Installation**:
- Plugins managed through `lazy.nvim`, not system packages
- LSP servers can be system-wide (via Nix) or Mason-installed

**Path Configuration**:
- NixOS uses `/nix/store/` for packages
- System paths configured in `/etc/nixos/configuration.nix`
- User paths configured through home-manager

**Environment Variables**:
- Set in NixOS configuration for system-wide effect
- Set in `home.nix` for user-specific settings

### Configuration Management

This NeoVim configuration can be managed through Nix:

**Option 1: System Package**:
```nix
environment.systemPackages = with pkgs; [
  neovim
];
```

**Option 2: Home Manager**:
```nix
programs.neovim = {
  enable = true;
  # Additional configuration here
};
```

**Option 3: Manual Installation** (current approach):
- NeoVim installed through Nix
- Configuration in `~/.config/nvim/`
- Managed separately from NixOS configuration

## Quick Reference

### Common Commands

| Operation | Keybinding | Command |
|-----------|------------|---------|
| System rebuild | `<leader>nr` | `sudo nixos-rebuild switch --flake .` |
| Home-manager | `<leader>nh` | `home-manager switch --flake .` |
| Update flake | `<leader>nu` | `nix flake update` |
| Dev shell | `<leader>nd` | `nix develop` |
| Garbage collect | `<leader>ng` | `nix-collect-garbage -d` |
| Package search | `<leader>np` | Opens https://search.nixos.org |

### File Locations

| Purpose | Path |
|---------|------|
| System config | `/etc/nixos/configuration.nix` |
| Flake config | `/etc/nixos/flake.nix` |
| Home config | `~/.config/home-manager/home.nix` |
| Store | `/nix/store/` |
| Profiles | `/nix/var/nix/profiles/` |

## Related Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture overview
- [INSTALLATION.md](INSTALLATION.md) - Initial setup and installation
- [Editor Plugins README](../lua/neotex/plugins/editor/README.md) - Plugin configurations

## Notes

NixOS integration provides:
- **Declarative system configuration**: Reproducible system state
- **Easy rollback**: Previous generations always available
- **Development environments**: Project-specific tool versions
- **Package management**: Consistent package versions across system

These workflows integrate NixOS system management directly into the NeoVim editing experience, reducing context switching between editor and terminal.
