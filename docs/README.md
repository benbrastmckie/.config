# Neovim Documentation

Welcome to the comprehensive documentation for this Neovim configuration. This directory contains all guides, references, and standards for using and extending this setup.

## Quick Start

**New Users**: Start with [Installation Guide](INSTALLATION.md) for step-by-step setup instructions.

**Existing Neovim Users**: See [Migration Guide](MIGRATION_GUIDE.md) to preserve your customizations.

**AI-Assisted Setup**: Use [Claude Code Installation](CLAUDE_CODE_INSTALL.md) for guided installation with automated checks.

## Documentation Catalog

### Setup and Installation

| Document | Purpose | Size |
|----------|---------|------|
| [INSTALLATION.md](INSTALLATION.md) | Primary installation guide with prerequisites and setup steps | 11K |
| [CLAUDE_CODE_INSTALL.md](CLAUDE_CODE_INSTALL.md) | AI-assisted installation with troubleshooting and dependency checking | 44K |
| [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) | Comprehensive guide for migrating from existing Neovim configurations | 26K |
| [ADVANCED_SETUP.md](ADVANCED_SETUP.md) | Advanced configuration options and customization | 6.5K |
| [KEYBOARD_PROTOCOL_SETUP.md](KEYBOARD_PROTOCOL_SETUP.md) | Terminal keyboard protocol configuration for advanced keybindings | 6.8K |

### Development Standards

| Document | Purpose | Size |
|----------|---------|------|
| [CODE_STANDARDS.md](CODE_STANDARDS.md) | Lua coding standards, conventions, and best practices | 28K |
| [DOCUMENTATION_STANDARDS.md](DOCUMENTATION_STANDARDS.md) | Documentation writing standards and style guide | 16K |
| [FORMAL_VERIFICATION.md](FORMAL_VERIFICATION.md) | Testing methodologies and formal verification practices | 12K |

### Reference Documentation

| Document | Purpose | Size |
|----------|---------|------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | System architecture, initialization flow, and component organization | 18K |
| [MAPPINGS.md](MAPPINGS.md) | Complete keymap reference for all plugins and features | 21K |
| [GLOSSARY.md](GLOSSARY.md) | Technical terms and definitions for Neovim concepts | 5.0K |
| [CLAUDE_CODE_QUICK_REF.md](CLAUDE_CODE_QUICK_REF.md) | Quick reference for Claude Code commands and workflows | 5.7K |
| [JUMP_LIST_TESTING_CHECKLIST.md](JUMP_LIST_TESTING_CHECKLIST.md) | Testing checklist for jump list functionality | 6.5K |

### Feature Documentation

| Document | Purpose | Size |
|----------|---------|------|
| [RESEARCH_TOOLING.md](RESEARCH_TOOLING.md) | Research workflows and tooling for academic and technical work | 14K |
| [NIX_WORKFLOWS.md](NIX_WORKFLOWS.md) | Nix package manager workflows and integration | 11K |
| [NOTIFICATIONS.md](NOTIFICATIONS.md) | Notification system configuration and usage | 18K |

## Documentation by Task

### Getting Started
1. [Installation Guide](INSTALLATION.md) - First-time setup
2. [Glossary](GLOSSARY.md) - Understand terminology
3. [Architecture](ARCHITECTURE.md) - Learn the system structure

### Daily Usage
1. [Mappings](MAPPINGS.md) - Find keyboard shortcuts
2. [AI Tooling](AI_TOOLING.md) - Use AI features
3. [Research Tooling](RESEARCH_TOOLING.md) - Research workflows

### Development
1. [Code Standards](CODE_STANDARDS.md) - Write clean Lua code
2. [Documentation Standards](DOCUMENTATION_STANDARDS.md) - Write good docs
3. [Formal Verification](FORMAL_VERIFICATION.md) - Test your code

### Configuration
1. [Advanced Setup](ADVANCED_SETUP.md) - Customize configuration
2. [Keyboard Protocol](KEYBOARD_PROTOCOL_SETUP.md) - Terminal setup
3. [Notifications](NOTIFICATIONS.md) - Configure notifications

## Common Tasks

### Installation and Setup
- **First Installation**: [Installation Guide](INSTALLATION.md) → [Quick Start](INSTALLATION.md#quick-start)
- **Migration**: [Migration Guide](MIGRATION_GUIDE.md) → [Preservation Strategy](MIGRATION_GUIDE.md#preservation-strategy)
- **AI-Assisted**: [Claude Code Install](CLAUDE_CODE_INSTALL.md) → [Phase 1: Dependencies](CLAUDE_CODE_INSTALL.md#phase-1-dependencies)
- **Advanced Config**: [Advanced Setup](ADVANCED_SETUP.md) → [Customization](ADVANCED_SETUP.md#customization)

### Finding Information
- **Keyboard Shortcuts**: [Mappings](MAPPINGS.md) - Complete keymap reference
- **Technical Terms**: [Glossary](GLOSSARY.md) - Definitions and explanations
- **System Design**: [Architecture](ARCHITECTURE.md) - How components work together
- **Quick Reference**: [Claude Code Quick Ref](CLAUDE_CODE_QUICK_REF.md) - Common commands

### Using Features
- **Research Workflows**: [Research Tooling](RESEARCH_TOOLING.md) - Academic and technical research
- **Nix Integration**: [Nix Workflows](NIX_WORKFLOWS.md) - Package management
- **Notifications**: [Notifications](NOTIFICATIONS.md) - Configure alerts and messages

### Development
- **Coding**: [Code Standards](CODE_STANDARDS.md) - Lua conventions and patterns
- **Documentation**: [Documentation Standards](DOCUMENTATION_STANDARDS.md) - Writing guidelines
- **Testing**: [Formal Verification](FORMAL_VERIFICATION.md) - Test methodologies
- **Jump Lists**: [Testing Checklist](JUMP_LIST_TESTING_CHECKLIST.md) - Specific test cases

## Documentation Standards

All documentation in this directory follows [Documentation Standards](DOCUMENTATION_STANDARDS.md):

- **Present-State Focus**: Describe what is, not what was or will be
- **No Historical Markers**: Avoid "previously", "now supports", "(New)", "(Updated)"
- **Clear Navigation**: Every document has parent/index/related links
- **Consistent Formatting**: Standard structure and style across all files
- **Single Source of Truth**: Each topic has one authoritative document
- **Smart Cross-Referencing**: Related docs link bidirectionally

## Prerequisites and Dependencies

See [Installation Guide - Prerequisites](INSTALLATION.md#prerequisites) for:
- Required dependencies (Neovim, Git, Nerd Fonts)
- Optional dependencies (LSP servers, formatters, linters)
- Platform-specific installation guides
- Version requirements and compatibility

## Directory Structure

```
nvim/docs/
├── README.md (this file)              # Documentation index and navigation hub
├── INSTALLATION.md                     # Primary installation guide
├── CLAUDE_CODE_INSTALL.md             # AI-assisted installation
├── MIGRATION_GUIDE.md                 # Migration from existing configs
├── ADVANCED_SETUP.md                  # Advanced configuration
├── KEYBOARD_PROTOCOL_SETUP.md         # Terminal keyboard setup
├── CODE_STANDARDS.md                  # Lua coding standards
├── DOCUMENTATION_STANDARDS.md         # Documentation style guide
├── FORMAL_VERIFICATION.md             # Testing methodologies
├── ARCHITECTURE.md                    # System architecture
├── MAPPINGS.md                        # Complete keymap reference
├── GLOSSARY.md                        # Technical glossary
├── CLAUDE_CODE_QUICK_REF.md          # Claude Code quick reference
├── JUMP_LIST_TESTING_CHECKLIST.md    # Jump list testing
├── AI_TOOLING.md                      # AI integration documentation
├── RESEARCH_TOOLING.md                # Research workflows
├── NIX_WORKFLOWS.md                   # Nix integration
├── NOTIFICATIONS.md                   # Notification system
└── templates/                         # Configuration templates
    └── gitignore-template
```

## Cross-Reference Summary

This documentation is referenced by 327+ locations across the repository:

- **Root README.md**: 16+ references to installation and setup guides
- **Parent Directory (nvim/)**: 8 references to standards and architecture
- **Platform Guides (docs/platform/)**: 8 references to installation procedures
- **Common Documentation (docs/common/)**: 8 references to standards
- **Specification Reports**: Multiple references to standards and architecture

## Maintenance

### Adding New Documentation
1. Create file following [Documentation Standards](DOCUMENTATION_STANDARDS.md)
2. Add entry to this README.md in appropriate category
3. Add navigation links (parent, index, related)
4. Update cross-references in related files
5. Verify all links work

### Updating Documentation
1. Follow [Present-State Documentation](DOCUMENTATION_STANDARDS.md#present-state-documentation) guidelines
2. Update cross-references if structure changes
3. Verify no broken links introduced
4. Update this README.md if purpose or scope changes

### Link Validation
```bash
# Check for broken links in docs/
cd /home/benjamin/.config/nvim/docs
for file in *.md; do
  echo "Validating $file"
  grep -o '\[.*\](.*\.md)' "$file" | sed 's/.*(\(.*\))/\1/' | \
    while read link; do
      test -f "$link" || echo "Broken link in $file: $link"
    done
done
```

## Navigation

- [← Parent Directory (nvim/)](../README.md)
- [← Root Documentation](../../docs/README.md)
- [← Repository Root](../../README.md)

## Related Documentation

- [Neovim Configuration Guidelines](../CLAUDE.md) - Project-specific standards for nvim/
- [Main CLAUDE.md](../../CLAUDE.md) - Repository-wide standards and workflow
- [Root Documentation Index](../../docs/README.md) - Platform guides and common documentation
