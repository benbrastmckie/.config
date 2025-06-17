# After Directory

This directory contains configurations that are loaded after Neovim's built-in scripts, providing file type specific settings and detection rules.

## File Structure

```
after/
├── README.md           # This documentation
├── ftdetect/          # File type detection rules
│   ├── README.md      # Detection documentation
│   └── ipynb.lua      # Jupyter notebook detection
└── ftplugin/          # File type specific settings
    ├── README.md      # Plugin documentation
    ├── lean.lua       # Lean theorem prover settings
    ├── lectic.markdown.lua # Academic markdown
    ├── markdown.lua   # General markdown settings
    ├── python.lua     # Python development settings
    └── tex.lua        # LaTeX settings
```

## Purpose

The `after/` directory in Neovim is special - its contents are loaded after all other configuration files. This ensures that these settings take precedence and can override default behaviors.

## Subdirectories

### [ftdetect/](ftdetect/README.md) - File Type Detection
Custom file type detection rules for specialized file formats.

**Key Features:**
- Jupyter notebook (`.ipynb`) file type detection
- Custom file extension handling
- Integration with plugin-specific file types

### [ftplugin/](ftplugin/README.md) - File Type Plugin Settings
File type specific configurations that are loaded automatically when editing files of particular types.

**Key Features:**
- Language-specific editing settings (indentation, formatting)
- Custom keybindings per file type
- Plugin configurations for specific languages
- Academic writing optimizations

## Configuration Loading Order

1. **Core Neovim**: Built-in configurations load first
2. **Plugin configurations**: Regular plugin setup
3. **After directory**: These configurations load last, overriding defaults

This loading order ensures that file type specific settings can properly override plugin defaults and provide the most appropriate behavior for each file type.

## File Type Support

### Programming Languages
- **Python**: Development environment with debugging and testing
- **Lean**: Theorem prover with specialized mathematical notation
- **LaTeX**: Academic document preparation and compilation

### Document Formats
- **Markdown**: General and academic writing with preview capabilities
- **Jupyter**: Interactive notebook editing and execution
- **Plain text**: General text editing optimizations

### Integration Benefits
- **Consistent behavior**: File type detection ensures proper plugin activation
- **Context-aware**: Settings adapt automatically to file content
- **Override capability**: Can customize behavior per file type
- **Performance**: Lazy loading based on actual file types encountered

## Related Configuration
- [lua/neotex/config/](../lua/neotex/config/) - Core configuration modules
- [lua/neotex/plugins/text/](../lua/neotex/plugins/text/) - Text processing plugins
- [lua/neotex/plugins/lsp/](../lua/neotex/plugins/lsp/) - Language server configurations

## Navigation
- [← Parent Directory](README.md)