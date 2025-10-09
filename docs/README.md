# Installation Documentation Index

This directory contains platform-specific installation guides and shared installation procedures.

## Quick Start

New to this configuration? Start here:

1. **Choose your path**:
   - **Quick Setup**: Follow the [Main Installation Guide](../nvim/docs/INSTALLATION.md) for a streamlined installation
   - **Platform-Specific**: Select your operating system below for detailed OS-specific instructions

2. **Platform Installation Guides**:
   - [Arch Linux](platform/arch.md) - Installation on Arch-based systems
   - [Debian/Ubuntu](platform/debian.md) - Installation on Debian-based systems
   - [macOS](platform/macos.md) - Installation on macOS
   - [Windows](platform/windows.md) - Installation on Windows

## Common Installation Procedures

These guides contain shared procedures referenced by platform-specific guides:

- [Prerequisites](common/prerequisites.md) - Core dependencies and their purposes
- [Zotero Setup](common/zotero-setup.md) - Bibliography management configuration
- [Terminal Setup](common/terminal-setup.md) - Optional terminal customization
- [Git Configuration](common/git-config.md) - SSH keys and authentication

## Additional Resources

- [Learning Git](LearningGit.md) - Git tutorial and workflow guide
- [Cheat Sheet](CheatSheet.md) - Quick reference for common commands

## Getting Started Decision Tree

```
Are you installing for the first time?
├─ Yes → Start with Main Installation Guide (nvim/docs/INSTALLATION.md)
│         Follow Quick Start section for fastest setup
│
└─ No → Installing on a specific OS?
   ├─ Yes → Choose your platform guide above
   │         for OS-specific package manager commands
   │
   └─ No → Setting up advanced features?
            → See nvim/docs/ADVANCED_SETUP.md
```

## Documentation Structure

This documentation is organized for accessibility:

- **Main Guide** (nvim/docs/INSTALLATION.md): Quick-start-first approach for new users
- **Platform Guides** (platform/): OS-specific commands and procedures
- **Common Procedures** (common/): Shared setup steps to reduce duplication
- **Glossary** (nvim/docs/GLOSSARY.md): Technical term definitions
- **Advanced Setup** (nvim/docs/ADVANCED_SETUP.md): Optional features and customization

## Navigation

- [Main Neovim Installation Guide](../nvim/docs/INSTALLATION.md)
- [Technical Glossary](../nvim/docs/GLOSSARY.md)
- [Advanced Setup Guide](../nvim/docs/ADVANCED_SETUP.md)
