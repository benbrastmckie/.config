# Jupyter Notebook Integration

This directory contains Jupyter notebook support for editing `.ipynb` files within Neovim.

## File Structure

```
jupyter/
├── README.md           # This documentation
├── init.lua           # Main Jupyter configuration
├── autocommands.lua   # Jupyter-specific autocommands
└── styling.lua        # Visual styling for notebooks
```

## Files

### init.lua
Main Jupyter plugin configuration and setup.

**Features:**
- Jupyter notebook file type support
- Cell navigation and execution
- Kernel management integration
- Output formatting and display

### autocommands.lua
Automatic behaviors for Jupyter notebook files.

**Features:**
- Auto-formatting on save
- Cell boundary detection
- Syntax highlighting adjustments
- File type specific behaviors

### styling.lua
Visual styling and appearance for Jupyter notebooks.

**Features:**
- Cell separator highlighting
- Output block formatting
- Markdown cell rendering
- Code cell syntax highlighting
- Custom colors and themes

## Functionality

### Cell Management
- Navigate between code and markdown cells
- Execute individual cells or entire notebooks
- Insert, delete, and reorder cells
- Convert between cell types

### Kernel Integration
- Connect to Jupyter kernels
- Execute code with live output
- Variable inspection and debugging
- Multiple language support (Python, R, Julia)

### Visual Features
- Syntax highlighting for multiple languages
- Markdown rendering within cells
- Output formatting (tables, plots, HTML)
- Cell type indicators and boundaries

## Keybindings

Jupyter-specific keybindings are available under `<leader>j` when editing `.ipynb` files:
- Cell execution and navigation
- Kernel management commands
- Output handling and clearing
- Export and conversion options

## Dependencies

Requires external Jupyter installation:
```bash
pip install jupyter notebook
# or
conda install jupyter
```

## Related Configuration
- [ftdetect/ipynb.lua](../../../../after/ftdetect/ipynb.lua) - File type detection
- [ftplugin/](../../../../after/ftplugin/) - File type specific settings
- [editor/telescope.lua](../../editor/telescope.lua) - Jupyter file search integration

## Navigation

- [← Text Plugins](../README.md)
- [← Plugins Overview](../../README.md)