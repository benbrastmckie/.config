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
- Jupyter notebook detection and styling
- Custom HTML comment highlighting
- Markdown-specific nvim-surround configuration
- Preview and export capabilities
- Syntax highlighting enhancements
- Table editing and formatting

**Markdown Surrounds:**
Markdown files have custom surround configurations (via `nvim-surround.buffer_setup`):

| Key | Surround | Result | Description |
|-----|----------|--------|-------------|
| `b` | Bold | `**text**` | Double asterisk emphasis |
| `i` | Italic | `*text*` | Single asterisk emphasis |
| `` ` `` | Code | `` `text` `` | Inline code with backticks |
| `c` | Code block | `` ```lang\ntext\n``` `` | Fenced code block (prompts for language) |
| `l` | Link | `[text](url)` | Markdown link (prompts for URL) |
| `~` | Strikethrough | `~~text~~` | GFM strikethrough |

**Usage Examples:**
```vim
" In a markdown file with cursor on 'word':
ysiw + b  ->  **word**        " Make word bold
ysiw + i  ->  *word*          " Make word italic
ysiw + `  ->  `word`          " Make word inline code
ysiw + c  ->  ```python       " Create code block (prompts for language)
                word
              ```
ysiw + l  ->  [word](url)     " Create link (prompts for URL)
ysiw + ~  ->  ~~word~~        " Strikethrough word
```

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
- LaTeX-specific nvim-surround configuration
- LaTeX compilation and preview via VimTeX
- Citation and bibliography management
- Mathematical notation support
- Document structure navigation
- Template integration
- Full-line syntax highlighting (synmaxcol=0)
- Which-key LaTeX command mappings

**LaTeX Surrounds:**
LaTeX files have custom surround configurations (via `nvim-surround.buffer_setup`):

| Key | Surround | Result | Description |
|-----|----------|--------|-------------|
| `e` | Environment | `\begin{env}...\end{env}` | LaTeX environment (prompts for name) |
| `b` | Bold | `\textbf{text}` | Bold text formatting |
| `i` | Italic | `\textit{text}` | Italic text formatting |
| `t` | Typewriter | `\texttt{text}` | Monospace text formatting |
| `q` | Single quotes | `` `text' `` | LaTeX single quotes |
| `Q` | Double quotes | `` ``text'' `` | LaTeX double quotes |
| `$` | Math mode | `$text$` | Inline math mode |

**Usage Examples:**
```vim
" In a LaTeX file with cursor on 'word':
ysiw + b  ->  \textbf{word}       " Make word bold
ysiw + i  ->  \textit{word}       " Make word italic
ysiw + t  ->  \texttt{word}       " Make word typewriter
ysiw + $  ->  $word$              " Wrap in math mode
ysiw + e  ->  \begin{equation}    " Create environment (prompts for name)
                word
              \end{equation}
ysiw + q  ->  `word'              " LaTeX single quotes
ysiw + Q  ->  ``word''            " LaTeX double quotes
```

**LaTeX Keybindings:**
See which-key mappings registered in the file for `<leader>l` (LaTeX commands) and `<leader>T` (templates).

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