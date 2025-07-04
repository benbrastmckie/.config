# LaTeX Templates

A comprehensive collection of LaTeX templates for academic writing, presentations, and formal documents, optimized for philosophy and mathematical work.

## File Structure

```
templates/
├── README.md           # This documentation
├── article.tex         # Academic paper template
├── arc_tikz.tex        # TikZ diagrams and modal logic
├── beamer_slides.tex   # Presentation template
├── glossary.tex        # Symbol definitions
├── handout.tex         # Educational materials
├── letter.tex          # Professional correspondence
├── report/             # Multi-chapter documents
│   ├── README.md       # Report documentation
│   ├── Root.tex        # Master document
│   └── chapters/       # Individual chapters
└── springer/           # Publisher templates
    ├── README.md       # Springer documentation
    ├── sn-article.tex  # Springer Nature article
    └── sn-jnl.cls      # Document class file
```

## Available Templates

### Academic Papers & Articles

| Template | Key Binding | Description |
|----------|-------------|-------------|
| **article.tex** | `<leader>tp` | Comprehensive academic article template with advanced theorem environments, citations, and philosophical paper formatting |
| **springer/sn-article.tex** | `<leader>ts` | Official Springer Nature journal submission template with multiple citation styles and publisher requirements |

### Presentations & Visual Content

| Template | Key Binding | Description |
|----------|-------------|-------------|
| **beamer_slides.tex** | `<leader>tb` | Dark-themed presentation template with mathematical notation support and structured slide organization |
| **arc_tikz.tex** | `<leader>ta` | Creates modal logic diagrams and philosophical tree structures with pre-configured TikZ styles and example diagrams |

### Educational Materials

| Template | Key Binding | Description |
|----------|-------------|-------------|
| **handout.tex** | `<leader>th` | Clean educational handout template with proof tree support and custom formatting for course materials |
| **letter.tex** | `<leader>tl` | Professional letter template with academic styling and Palatino typography |

### Multi-Document Projects

| Template | Key Binding | Description |
|----------|-------------|-------------|
| **report/Root.tex** | `<leader>tr` | Multi-chapter book/report template supporting modular file organization with subfiles package |
| **report/ch01.tex** | `<leader>tc` | Individual chapter templates that compile independently but integrate with the main report structure |

### Reference & Support Files

| Template | Key Binding | Description |
|----------|-------------|-------------|
| **glossary.tex** | `<leader>tg` | Reusable glossary definitions for mathematical and logical symbols to be included in main documents |

## Loading Templates

Templates are loaded using which-key bindings under the `<leader>t` prefix:

```vim
<leader>tp  -- Load PhilPaper.tex (article.tex)
<leader>tl  -- Load Letter.tex
<leader>tg  -- Load Glossary.tex
<leader>th  -- Load HandOut.tex
<leader>tb  -- Load PhilBeamer.tex (beamer_slides.tex)
<leader>ts  -- Load SubFile.tex (springer template)
<leader>tr  -- Load Root.tex (multi-chapter template)
<leader>ta  -- Load TikZ Arc template (arc_tikz.tex)
<leader>tc  -- Load Chapter template
```

## Template Categories

### Philosophy & Academic Writing
- **article.tex**: Full-featured academic paper with theorem environments (T, L, P prefixes), natbib citations, glossary support
- **springer/sn-article.tex**: Publisher-compliant template with structured abstract, keywords, multiple reference styles
- **glossary.tex**: Symbol definitions for operators, logical constructs, and mathematical notation

### Presentations & Diagrams
- **beamer_slides.tex**: Dark theme with mathematical symbols and citation commands
- **arc_tikz.tex**: Modal logic diagrams, tree structures, reflexive relations, and proof tableaux

### Educational & Correspondence
- **handout.tex**: Course materials with Palatino font, proof trees, custom enumerate formatting
- **letter.tex**: Formal correspondence with clean layout and professional styling

### Large Documents
- **report/Root.tex**: Master document with subfiles package, table of contents, chapter organization
- **report/ch0X.tex**: Modular chapters with independent compilation capability

## Key Features

### Mathematical & Logical Support
- Pre-configured mathematical packages (amsmath, amsthm, amssymb)
- Theorem environments with custom prefixes
- Modal logic symbols and operators
- Proof tree and tableau support

### Citation & Bibliography
- natbib and biblatex compatibility
- Multiple citation styles (APS, Vancouver, Chicago, mathphys)
- Hyperlinked references and cross-references

### Document Structure
- Subfiles package for modular organization
- Custom section commands with navigation
- Table of contents and glossary integration
- Appendices and declaration sections

### Typography & Formatting
- Palatino and professional font choices
- Custom margins and spacing
- Dark themes for presentations
- Clean educational layouts

## Template Structure

```
templates/
   article.tex           # Main academic paper template
   arc_tikz.tex         # TikZ diagrams and modal logic
   beamer_slides.tex    # Presentation template
   glossary.tex         # Symbol definitions
   handout.tex          # Educational materials
   letter.tex           # Formal correspondence
   report/              # Multi-document templates
      Root.tex         # Master document
      chapters/        # Individual chapters
          ch01/ch01.tex
          ch02/ch02.tex
   springer/            # Publisher templates
       sn-article.tex   # Springer Nature article
       sn-jnl.cls       # Document class file
```

## Usage Examples

### Starting a New Paper
```vim
<leader>tp  " Load article.tex template
" Edit content, add \input{glossary} if needed
```

### Creating a Presentation
```vim
<leader>tb  " Load beamer template with dark theme
" Add slides using \begin{frame}...\end{frame}
```

### Multi-Chapter Project
```vim
<leader>tr  " Load Root.tex as master document
<leader>tc  " Load chapter template for each chapter
" Use \subfile{chapters/ch01/ch01} in Root.tex
```

### Publisher Submission
```vim
<leader>ts  " Load Springer Nature template
" Select appropriate reference style
" Fill in author information and abstract
```

## Dependencies

### Required Packages
- **Core**: amsmath, amsthm, amssymb, natbib/biblatex
- **Graphics**: tikz, pgfplots, graphicx
- **Structure**: subfiles, hyperref, cleveref
- **Specialty**: glossaries-extra, beamer, proof trees

### External Tools
- **LaTeX Distribution**: TeXLive or MiKTeX
- **Bibliography**: BibTeX or Biber
- **PDF Viewer**: Configured through VimTeX

## Integration

Templates integrate with the Neovim LaTeX workflow:
- **VimTeX**: Compilation and viewing (`<leader>b`, `<leader>v`)
- **Which-key**: Template selection and documentation
- **Telescope**: Template search and selection
- **LSP**: LaTeX language server support for editing

## Related Documentation

- [VimTeX Configuration](../lua/neotex/plugins/text/vimtex.lua) - LaTeX editing setup
- [Which-key Mappings](../lua/neotex/plugins/editor/which-key.lua) - Complete keymap reference
- [Text Plugins](../lua/neotex/plugins/text/README.md) - LaTeX tooling overview

## Navigation

- [Report Templates →](report/README.md)
- [Springer Templates →](springer/README.md)
- [Snippets →](../snippets/README.md)
- [Text Plugins →](../lua/neotex/plugins/text/README.md)
- [← Main Configuration](../README.md)