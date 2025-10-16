# Claude Squad NixOS Integration Specification

## Project Overview

**Claude Squad** is a terminal application that manages multiple AI terminal agents (Claude Code, Codex, Gemini) in separate workspaces using tmux sessions. It provides a unified interface for switching between different AI assistants and managing their separate contexts.

## Repository Information

- **Repository**: https://github.com/smtg-ai/claude-squad
- **License**: AGPL-3.0
- **Language**: Go (85.8%)
- **Build System**: GoReleaser
- **Binary Name**: `claude-squad` (aliased as `cs`)

## Dependencies Analysis

### System Dependencies
1. **tmux** - Required for workspace management and session handling
2. **gh** (GitHub CLI) - Required for GitHub integration features

### Build Dependencies
- **Go 1.23.0+** (with toolchain go1.24.1)
- **CGO_ENABLED=0** (static linking)

### Go Module Dependencies
- `github.com/charmbracelet/bubbles` - TUI components
- `github.com/charmbracelet/bubbletea` - TUI framework
- `github.com/spf13/cobra` - CLI framework
- `github.com/go-git/go-git/v5` - Git operations

## Current Installation Method Analysis

The official install script performs:
1. Platform and architecture detection (linux/darwin/windows, amd64/arm64)
2. Downloads pre-built binary from GitHub releases
3. Installs to `$HOME/.local/bin` (or custom `$BIN_DIR`)
4. Creates shell alias `cs` for `claude-squad`
5. Automatically installs dependencies (tmux, gh) via system package managers
6. Updates shell profile to add binary to PATH

## NixOS Implementation Strategy

### 1. Package Definition Approach

**Option A: Overlay with buildGoModule (Recommended)**
- Create custom overlay in flake.nix
- Use `buildGoModule` to build from source
- Ensure tmux and gh are runtime dependencies
- Install binary as both `claude-squad` and `cs`

**Option B: Binary Download**
- Download pre-built binary from GitHub releases
- Wrap with required dependencies
- Less reliable for reproducibility

### 2. Implementation Plan

#### Step 1: Create Claude Squad Overlay
```nix
claudeSquadOverlay = final: prev: {
  claude-squad = final.buildGoModule rec {
    pname = "claude-squad";
    version = "latest"; # or specific version
    
    src = final.fetchFromGitHub {
      owner = "smtg-ai";
      repo = "claude-squad";
      rev = "v${version}";
      sha256 = ""; # Need to calculate
    };
    
    vendorHash = ""; # Need to calculate from go.sum
    
    nativeBuildInputs = with final; [ go ];
    
    buildInputs = with final; [ tmux gh ];
    
    postInstall = ''
      # Create 'cs' alias
      ln -s $out/bin/claude-squad $out/bin/cs
    '';
    
    meta = with final.lib; {
      description = "Terminal app that manages multiple AI terminal agents";
      homepage = "https://github.com/smtg-ai/claude-squad";
      license = licenses.agpl3Only;
      maintainers = [ ];
      platforms = platforms.linux ++ platforms.darwin;
    };
  };
};
```

#### Step 2: Update Flake Configuration
- Add `claudeSquadOverlay` to the overlays list in `flake.nix`
- Include in both `unstablePackagesOverlay` and `nixpkgsConfig.overlays`

#### Step 3: Update Home Manager Configuration
- Add `claude-squad` to `home.packages` in `home.nix`
- Ensure tmux and gh are also available (likely already present)

#### Step 4: Integration with update.sh
- No changes needed to `update.sh` - it will automatically rebuild with new overlay

### 3. File Structure Changes

```
/home/benjamin/.dotfiles/
|-- flake.nix (add claude-squad overlay)
|-- home.nix (add claude-squad to packages)
|-- specs/
  |-- claude_squad.md (this file)
|-- update.sh (no changes needed)
```

### 4. Runtime Requirements Verification

Ensure the following are available in the user environment:
- `tmux` - for session management
- `gh` - for GitHub operations
- `git` - for repository operations (already available)

### 5. Testing Strategy

1. **Build Test**: Verify package builds successfully
2. **Runtime Test**: Verify `claude-squad` and `cs` commands work
3. **Dependency Test**: Verify tmux and gh integration works
4. **Update Test**: Verify `update.sh` correctly rebuilds system

### 6. Potential Issues and Solutions

#### Issue: Go Module Hash Changes
**Solution**: Use `lib.fakeHash` initially, then update with correct hash from build error

#### Issue: Dependency Conflicts
**Solution**: Ensure tmux and gh versions are compatible with claude-squad requirements

#### Issue: Binary Not Found in PATH
**Solution**: Verify both `claude-squad` and `cs` are properly symlinked in `$out/bin`

### 7. Version Management Strategy

**Initial Approach**: Use latest release tag
**Future Approach**: Pin to specific version for stability
**Update Process**: Manually update version and hashes when new releases available

### 8. Security Considerations

- AGPL-3.0 license requires source code availability for modifications
- Static compilation (CGO_ENABLED=0) reduces runtime dependencies
- No network access required during build (vendored dependencies)

### 9. Implementation Steps Summary

1. **Create overlay definition** in `flake.nix`
2. **Calculate vendorHash** using `nix-prefetch-git` or build attempts
3. **Add to home.nix packages** list
4. **Test build and installation** with `update.sh`
5. **Verify functionality** of `claude-squad` and `cs` commands
6. **Document usage** and maintenance procedures

## Expected Benefits

- **Reproducible builds** via Nix
- **Automatic dependency management** (tmux, gh)
- **System-wide availability** via home-manager
- **Easy updates** via existing `update.sh` workflow
- **No manual PATH management** required

## Implementation Results

### Successfully Implemented ✅

**Overlay Configuration**: Created `claudeSquadOverlay` in `flake.nix` at lines 41-73
- **Version**: 1.0.8 (latest as of 2025-07-06)
- **Source Hash**: `sha256-mzW9Z+QN4EQ3JLFD3uTDT2/c+ZGLzMqngl3o5TVBZN0=`
- **Vendor Hash**: `sha256-BduH6Vu+p5iFe1N5svZRsb9QuFlhf7usBjMsOtRn2nQ=`

**Package Installation**: Added to `home.nix` packages list at lines 41-42
- `claude-squad` - Main binary
- `gh` - GitHub CLI dependency 
- `cs` - Symlinked alias created automatically

**Build Verification**: Package builds successfully
- Binary location: `/nix/store/sg1wg84354z27kdld9gdl13cy184gkdg-claude-squad-1.0.8/bin/`
- Both `claude-squad` and `cs` commands available
- Version reported: 1.0.5 (embedded version in source)
- Dependencies: tmux (system), gh (home-manager)

**Integration**: Works with existing `update.sh` script
- No modifications needed to update script
- Automatic rebuild and installation via home-manager

### Usage Commands

```bash
# Main command
claude-squad

# Alias 
cs

# Show version
claude-squad version
cs version

# Help
claude-squad --help
cs --help

# Available subcommands
claude-squad completion  # Shell autocompletion
claude-squad debug       # Debug info
claude-squad reset       # Reset instances
```

## Maintenance Requirements

- **Monitor upstream releases** for version updates in `flake.nix:45`
- **Update vendorHash** when Go dependencies change in `flake.nix:54`
- **Update source hash** when updating version in `flake.nix:51`
- **Test compatibility** with NixOS updates
- **Update documentation** as needed
