# Spell Check Configuration

This directory contains custom spell check dictionaries and word lists for enhanced writing support in Neovim.

## File Structure

```
spell/
├── README.md           # This documentation
├── en.utf-8.add       # Custom word additions
└── en.utf-8.add.spl   # Compiled binary dictionary
```

## Files

### en.utf-8.add
Custom word additions to the English spell checker dictionary.

**Contents:**
- Technical terms and jargon specific to development and academic writing
- Proper nouns (names, places, organizations)
- Domain-specific vocabulary (philosophy, mathematics, computer science)
- Neologisms and modern terminology not in standard dictionaries

### en.utf-8.add.spl
Compiled binary version of the custom dictionary for efficient spell checking.

**Features:**
- Optimized binary format for fast spell check operations
- Automatically generated from the `.add` file
- Used by Vim's spell checker for real-time checking
- Updated automatically when `.add` file changes

## Functionality

### Custom Dictionary Management
- **Add words**: Use `zg` on a word to add it to the custom dictionary
- **Remove words**: Use `zug` to remove a word from the custom dictionary
- **Good words**: Mark words as correctly spelled in context
- **Temporary additions**: Add words for current session only

### Spell Check Integration
- **Real-time checking**: Misspelled words highlighted as you type
- **Suggestions**: `z=` provides spelling suggestions for word under cursor
- **Navigation**: `]s` and `[s` to move between misspelled words
- **Quick fixes**: Common corrections available through completion

### Academic Writing Support
Custom dictionary includes:
- **Technical terms**: Programming languages, software tools, frameworks
- **Academic vocabulary**: Research terminology, citation formats
- **Philosophy terms**: Specialized philosophical vocabulary and concepts
- **Mathematical notation**: Symbol names and mathematical terminology

## Configuration

### Spell Check Settings
Spell checking is configured in the main options:
- **Languages**: English (en) as primary, with support for additional languages
- **File types**: Enabled for text, markdown, LaTeX, and documentation files
- **Visual indicators**: Clear highlighting for misspelled words

### Custom Word Categories
Words are organized by category:
- **Technical**: Software development and computer science terms
- **Academic**: Research and scholarly writing vocabulary
- **Proper nouns**: Names, places, institutions
- **Domain-specific**: Field-specific terminology and jargon

## Usage Examples

### Adding New Words
```vim
" Position cursor on unknown word
zg          " Add word to custom dictionary
zG          " Add word for current session only
zw          " Mark word as wrong (remove from dictionary)
```

### Spell Check Navigation
```vim
]s          " Move to next misspelled word
[s          " Move to previous misspelled word
z=          " Show suggestions for word under cursor
1z=         " Accept first suggestion
```

### Dictionary Management
```vim
:spellgood word    " Add word to dictionary
:spellwrong word   " Mark word as misspelled
:spellundo word    " Remove word from custom additions
```

## File Format

### Plain Text Format (.add)
The `.add` file uses a simple plain text format:
- One word per line
- Case-sensitive entries
- UTF-8 encoding for international characters
- Comments not supported (use separate documentation)

### Binary Format (.spl)
The compiled `.spl` file:
- Generated automatically by Vim from `.add` file
- Binary format for efficient lookup
- Platform-independent
- Automatically updated when source changes

## Integration

### With Writing Workflow
- **Real-time feedback**: Immediate spelling error detection
- **Distraction-free**: Non-intrusive highlighting and correction
- **Context-aware**: Different dictionaries for different file types
- **Productivity**: Quick addition of technical terms to prevent interruption

### With File Types
- **Markdown**: Enabled for documentation and note-taking
- **LaTeX**: Academic writing with technical terminology
- **Text files**: General writing and correspondence
- **Comments**: Spell checking in code comments and documentation

## Maintenance

### Dictionary Updates
- **Regular review**: Periodically review custom additions
- **Cleanup**: Remove obsolete or incorrectly added words
- **Backup**: Version control the `.add` file for portability
- **Sharing**: Share custom dictionaries across team or projects

### Performance
- **Automatic compilation**: `.spl` file updates automatically
- **Efficient lookup**: Binary format provides fast spell checking
- **Memory usage**: Optimized for minimal memory footprint
- **Incremental updates**: Only changed words affect performance

## Related Configuration
- [options.lua](../lua/neotex/config/options.lua) - Spell check settings
- [autocmds.lua](../lua/neotex/config/autocmds.lua) - File type spell check automation
- [text/](../lua/neotex/plugins/text/) - Writing and documentation tools

## Navigation
- [← Parent Directory](README.md)