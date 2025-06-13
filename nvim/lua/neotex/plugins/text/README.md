# Text Format Plugins

This directory contains plugins that provide specialized support for various text formats and languages:

## Document Formats
- LaTeX integration (vimtex)
- Jupyter notebook support (jupyter)
- Markdown preview (markdown-preview)

## Programming Languages
- Lean theorem prover integration (lean)

These plugins provide enhanced editing, navigation, and visualization capabilities specific to different text formats and languages, offering a more tailored experience for working with specialized content types.

## Features

### LaTeX Features
- Document compilation and viewing
- Table of contents navigation 
- Syntax highlighting and autocompletion
- Context-sensitive commands
- Bibliography management

### Jupyter Notebook Features
- Cell execution and navigation
- REPL integration
- Styling and visual enhancements
- Support for notebook conversion

### Lean Features
- Interactive theorem proving interface
- Info view for goals and context
- Enhanced syntax highlighting

### Markdown Features
- Live preview rendering
- Custom styling
- Export capabilities

## Plugin Analysis

To verify text format plugins are properly loaded and organized:

```vim
:luafile scripts/check_plugins.lua
```

This will show the TEXT category with plugins like vimtex.lua, markdown-preview.lua, lean.lua, and jupyter components. See [`scripts/README.md`](../../../scripts/README.md) for complete script documentation and the main [plugins README](../README.md#plugin-analysis-and-maintenance) for more details.