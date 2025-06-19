# Multi-Chapter Report Templates

This directory contains templates for multi-chapter documents such as books, theses, and comprehensive reports using the subfiles package for modular organization.

## File Structure

```
report/
├── README.md           # This documentation
├── Root.tex           # Master document template
└── chapters/          # Individual chapter templates
    ├── README.md      # Chapters documentation
    ├── ch01/          # Chapter 1 template
    │   └── ch01.tex   # Chapter 1 content
    └── ch02/          # Chapter 2 template
        └── ch02.tex   # Chapter 2 content
```

## Files

### Root.tex
Master document template that coordinates multiple chapters and provides overall structure.

**Features:**
- Document class configuration for books/reports
- Subfiles package integration for modular compilation
- Table of contents and navigation structure
- Bibliography and index management
- Consistent formatting across all chapters

**Structure:**
- Preamble with shared packages and settings
- Title page and front matter organization
- Chapter inclusion via `\subfile{}` commands
- Bibliography and appendices coordination
- Index and glossary integration

## Subdirectories

### [chapters/](chapters/README.md)
Individual chapter templates that can be compiled independently or as part of the main document.

## Template Architecture

### Modular Design
The subfiles package enables:
- **Independent compilation**: Each chapter compiles on its own
- **Shared preamble**: Common packages and settings from Root.tex
- **Coordinated numbering**: Consistent figure, table, and equation numbering
- **Cross-references**: References work within chapters and across document

### Document Hierarchy
```
Root.tex (master document)
├── Chapter 1 (chapters/ch01/ch01.tex)
├── Chapter 2 (chapters/ch02/ch02.tex)
├── Bibliography (shared)
└── Appendices (optional)
```

## Usage Workflow

### Project Setup
1. **Copy Root.tex**: Use as main document template
2. **Create chapters**: Copy chapter templates to `chapters/` subdirectories
3. **Configure**: Edit preamble and document metadata
4. **Include**: Add `\subfile{chapters/chXX/chXX}` to Root.tex

### Development Workflow
- **Chapter editing**: Work on individual chapters with fast compilation
- **Full document**: Compile Root.tex for complete document
- **Cross-references**: Use `\label{}` and `\ref{}` across chapters
- **Bibliography**: Centralized reference management in Root.tex

### Compilation Options
- **Individual chapter**: `pdflatex ch01.tex` (fast iteration)
- **Full document**: `pdflatex Root.tex` (complete preview)
- **Bibliography**: `bibtex Root` or `biber Root` for references

## Template Features

### Document Structure
- **Professional layout**: Book/report formatting with proper margins
- **Chapter organization**: Clear chapter breaks and numbering
- **Navigation aids**: Table of contents, list of figures/tables
- **Cross-referencing**: Automatic numbering and linking

### Academic Support
- **Citation management**: Integrated bibliography system
- **Mathematical notation**: Full mathematical package support
- **Figure management**: Coordinated figure and table numbering
- **Appendices**: Support for supplementary material

### Collaboration Features
- **Version control**: Git-friendly file structure
- **Multi-author**: Chapter-based author assignment
- **Review process**: Independent chapter review and compilation
- **Modular editing**: Parallel chapter development

## Integration

### With Neovim Workflow
- **Template loading**: `<leader>tr` for Root.tex, `<leader>tc` for chapters
- **VimTeX support**: Full compilation and preview integration
- **Navigation**: Quick jumping between chapters and sections
- **Project management**: Session support for multi-file projects

### With Academic Tools
- **Reference managers**: Compatible with Zotero, Mendeley, etc.
- **Collaboration**: ShareLaTeX/Overleaf compatible structure
- **Publishing**: Professional formatting for submission
- **Archival**: Complete project in organized structure

## Related Configuration
- [article.tex](../article.tex) - Single document template
- [vimtex.lua](../../lua/neotex/plugins/text/vimtex.lua) - LaTeX compilation
- [sessions.lua](../../lua/neotex/plugins/ui/sessions.lua) - Project session management

## Navigation

- [Chapter Templates →](chapters/README.md)
- [← Templates](../README.md)