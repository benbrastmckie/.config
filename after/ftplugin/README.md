# File Type Plugin Settings

This directory contains file type specific configurations that are loaded automatically when editing files of particular types.

## File Structure

```
ftplugin/
├── README.md           # This documentation
├── lean.lua           # Lean theorem prover settings
├── lectic.markdown.lua # Academic markdown settings
├── markdown.lua       # General markdown settings
├── python.lua         # Python development settings
└── tex.lua            # LaTeX settings
```

## Files

### lean.lua
Configuration for Lean theorem prover files (`.lean`).

**Features:**
- Custom indentation settings (2 spaces)
- Lean-specific keybindings and commands
- Integration with Lean language server
- Theorem proving workflow optimizations

### lectic.markdown.lua
Enhanced Markdown configuration for academic writing.

**Features:**
- Academic writing optimizations
- Citation management integration
- Enhanced formatting for scholarly documents
- Bibliography and reference handling

### markdown.lua
General Markdown file configuration.

**Features:**
- Markdown-specific editing settings
- Preview and export capabilities
- Syntax highlighting enhancements
- Table editing and formatting

### python.lua
Python development environment configuration.

**Features:**
- Python-specific indentation (4 spaces)
- Debugging and testing integrations
- Virtual environment support
- Code execution and REPL integration

### tex.lua
LaTeX document preparation configuration.

**Features:**
- LaTeX compilation and preview
- Citation and bibliography management
- Mathematical notation support
- Document structure navigation
- Template integration

## File Type Behavior

These configurations are loaded automatically based on file extensions:
- `.lean` → lean.lua
- `.md`, `.markdown` → markdown.lua (and lectic.markdown.lua for academic)
- `.py` → python.lua
- `.tex`, `.latex`, `.cls`, `.sty` → tex.lua

## Related Configuration
- [ftdetect/](../ftdetect/README.md) - File type detection rules
- [plugins/text/](../../lua/neotex/plugins/text/) - Language-specific plugins
- [plugins/lsp/](../../lua/neotex/plugins/lsp/) - Language server configurations

## Navigation
- [← Parent Directory](../README.md)