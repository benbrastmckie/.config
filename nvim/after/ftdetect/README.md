# File Type Detection

This directory contains file type detection rules for custom file formats.

## File Structure

```
ftdetect/
├── README.md           # This documentation
└── ipynb.lua          # Jupyter notebook detection
```

## Files

### ipynb.lua
Provides file type detection for Jupyter Notebook files (`.ipynb`).

**Functionality:**
- Detects `.ipynb` files and sets filetype to `ipynb`
- Enables Jupyter-specific features and syntax highlighting
- Integrates with Jupyter plugin configurations

**Usage:**
File type detection runs automatically when opening files. The `ipynb` filetype triggers:
- Custom syntax highlighting for JSON-based notebook structure
- Jupyter-specific keybindings and commands
- Integration with kernel management and cell execution

## Related Configuration
- [ftplugin/](../ftplugin/README.md) - File type specific settings
- [plugins/text/jupyter/](../../lua/neotex/plugins/text/jupyter/) - Jupyter plugin configuration

## Navigation
- [← Parent Directory](../README.md)