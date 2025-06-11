# VimTeX Compatibility with blink.cmp Investigation

## Research Objective
Investigate the compatibility of VimTeX completion with blink.cmp to ensure LaTeX functionality is preserved during the migration from nvim-cmp.

## Current VimTeX Setup Analysis

### Current Configuration
**File**: `lua/neotex/plugins/lsp/vimtex-cmp.lua`

```lua
return {
  "micangl/cmp-vimtex",
  config = function()
    require('cmp_vimtex').setup({
      additional_information = {
        info_in_menu = true,
        info_in_window = true,
        info_max_length = 60,
        match_against_info = true,
        symbols_in_menu = true,
      },
      bibtex_parser = {
        enabled = true,
      },
      search = {
        browser = "xdg-open",
        default = "google_scholar",
        search_engines = {
          google_scholar = {
            name = "Google Scholar",
            get_url = require('cmp_vimtex').url_default_format("https://scholar.google.com/scholar?hl=en&q=%s"),
          },
        },
      },
    })
  end,
}
```

### Features Currently Used
- [ ] **Symbol completion**: LaTeX symbols and commands
- [ ] **Bibliography completion**: BibTeX references  
- [ ] **Additional information display**: Symbol info in menu and window
- [ ] **Search integration**: Google Scholar search capability
- [ ] **Symbol matching**: Match against symbol information

## blink.cmp Documentation Research

### Official Documentation Review
**Status**: COMPLETED

#### Built-in LaTeX Support
- ❌ **No native LaTeX completion**: blink.cmp does not have built-in LaTeX sources
- ✅ **Snippet support**: LuaSnip integration available for LaTeX snippets
- ❌ **No academic sources**: No built-in bibliography or citation sources

#### Extension/Plugin Support
- ✅ **Plugin architecture**: Supports custom sources via module system
- ✅ **Compatibility layer**: `blink.compat` enables nvim-cmp source usage
- ✅ **Custom source creation**: API available for creating new sources

### Key Findings

#### Available LaTeX Solutions
1. **blink-cmp-latex** (erooke/blink-cmp-latex)
   - Provides LaTeX symbol completion via Unicode
   - Configuration: `insert_command` function/boolean
   - Limited to symbol completion only

2. **cmp-pandoc-references** (jmbuhr/cmp-pandoc-references)
   - Bibliography completion for Pandoc/Markdown
   - Works with both nvim-cmp and blink.cmp
   - Requires `bibliography:` YAML metadata field

3. **blink.compat compatibility layer**
   - Allows using `cmp-vimtex` with blink.cmp
   - May have triggering differences due to lack of keyword patterns
   - Maintained by stefanboca, separate repository

#### Built-in Sources (blink.cmp core)
- buffer.lua
- complete_func.lua  
- cmdline (directory)
- lsp (directory)
- path (directory)
- snippets (directory)
- ❌ No LaTeX-specific sources

## VimTeX Integration Testing

### Test Environment Setup
- [ ] Create isolated test configuration
- [ ] Set up minimal LaTeX document for testing
- [ ] Document current completion behavior

### Test Cases
1. **Basic LaTeX Commands**
   - [ ] `\documentclass{}`
   - [ ] `\usepackage{}`
   - [ ] `\begin{}` / `\end{}`
   - [ ] Common math symbols

2. **Bibliography Completion**
   - [ ] `\cite{}`
   - [ ] `\citep{}`
   - [ ] `\citet{}`

3. **Math Mode Completion**
   - [ ] Greek letters (`\alpha`, `\beta`, etc.)
   - [ ] Math operators (`\sum`, `\int`, etc.)
   - [ ] Math environments

4. **Advanced Features**
   - [ ] Symbol information display
   - [ ] Search functionality
   - [ ] Custom macros

### Current Behavior Documentation

#### VimTeX Configuration Analysis
**File**: `lua/neotex/plugins/text/vimtex.lua`

Current VimTeX settings:
- **Viewer**: zathura_simple (Wayland compatible)
- **Context viewer**: okular for external PDF viewing
- **Formatting**: latexindent disabled
- **Indentation**: VimTeX auto-indent disabled
- **Quickfix**: Suppressed on save/build
- **Mappings**: Default VimTeX mappings disabled
- **Log filtering**: Underfull/Overfull warnings suppressed

#### LaTeX-specific Filetype Configuration
**File**: `after/ftplugin/tex.lua`

Features provided:
- **nvim-surround LaTeX environments**: `e` for environments, `Q`/`q` for quotes
- **Text formatting surrounds**: `b` (bold), `i` (italic), `t` (typewriter), `$` (math)
- **PDF annotation extraction**: PdfAnnots() function
- **Syntax highlighting**: Full-line highlighting enabled (synmaxcol=0)
- **Commented completion setup**: Shows previous cmp setup for omni completion

#### Current Completion Sources
From `lua/neotex/plugins/lsp/nvim-cmp.lua`:
```lua
sources = cmp.config.sources({
  { name = "nvim_lsp" },
  { name = "luasnip" },
  { name = "vimtex" },        -- LaTeX completion
  { name = "buffer", keyword_length = 3 },
  { name = "spell", keyword_length = 4 },
  { name = "path" },
})
```

#### VimTeX Source Features (from cmp-vimtex)
- **Symbol completion**: LaTeX commands and symbols
- **Bibliography parsing**: BibTeX file integration
- **Information display**: Symbol descriptions in menu/window
- **Search integration**: Google Scholar lookup capability
- **Symbol matching**: Match against symbol information

## Compatibility Options Investigation

### Option 1: blink.compat + cmp-vimtex
**Approach**: Use existing cmp-vimtex with blink.compat compatibility layer

**Configuration**:
```lua
{
  'saghen/blink.compat',
  version = '2.*',
  lazy = true,
  opts = {},
},
{
  'saghen/blink.cmp',
  dependencies = { 'micangl/cmp-vimtex' },
  opts = {
    sources = {
      default = { 'lsp', 'vimtex', 'snippets', 'buffer' },
      providers = {
        vimtex = {
          name = 'vimtex',
          module = 'blink.compat.source',
        },
      },
    },
  },
}
```

**Pros**:
- ✅ Preserves all current cmp-vimtex functionality
- ✅ Minimal configuration changes needed
- ✅ Maintains bibliography and search features

**Cons**:
- ⚠️ Potential triggering differences (keyword patterns)
- ⚠️ Additional dependency (blink.compat)
- ⚠️ May have performance differences

### Option 2: blink-cmp-latex + cmp-pandoc-references
**Approach**: Use community plugins for LaTeX support

**Configuration**:
```lua
{
  'saghen/blink.cmp',
  dependencies = {
    'erooke/blink-cmp-latex',
    'jmbuhr/cmp-pandoc-references',
  },
  opts = {
    sources = {
      default = { 'lsp', 'latex', 'references', 'snippets', 'buffer' },
      providers = {
        latex = {
          name = 'Latex',
          module = 'blink-cmp-latex',
        },
        references = {
          name = 'pandoc_references',
          module = 'cmp-pandoc-references.blink',
        },
      },
    },
  },
}
```

**Pros**:
- ✅ Native blink.cmp integration
- ✅ Potentially better performance
- ✅ No compatibility layer needed

**Cons**:
- ❌ Limited LaTeX symbol completion only
- ❌ Requires YAML bibliography metadata
- ❌ Loss of VimTeX-specific features
- ❌ No comprehensive LaTeX command completion

### Option 3: Hybrid Approach
**Approach**: Use blink.cmp for general completion, keep nvim-cmp for LaTeX

**Configuration**:
```lua
-- Conditional setup based on filetype
if vim.bo.filetype == 'tex' then
  -- Use nvim-cmp for LaTeX files
else
  -- Use blink.cmp for other files
end
```

**Pros**:
- ✅ Preserves full LaTeX functionality
- ✅ Gets blink.cmp benefits for other files
- ✅ No risk to LaTeX workflow

**Cons**:
- ❌ Complex configuration maintenance
- ❌ Inconsistent UX across filetypes
- ❌ Increased memory usage
- ❌ Potential conflicts between completion systems

### Option 4: LSP + Snippets Only
**Approach**: Use texlab LSP + LuaSnip for LaTeX completion

**Configuration**:
```lua
-- Rely on texlab LSP + custom snippets
sources = { 'lsp', 'snippets', 'buffer' }
```

**Pros**:
- ✅ Simplified setup
- ✅ Native blink.cmp integration
- ✅ Good LSP-based completion

**Cons**:
- ❌ Loss of bibliography integration
- ❌ No symbol search functionality
- ❌ Reduced LaTeX-specific features

## Testing Results

### Functionality Matrix
| Feature | Current (cmp-vimtex) | blink.cmp Option 1 | blink.cmp Option 2 | blink.cmp Option 3 |
|---------|---------------------|-------------------|-------------------|-------------------|
| Symbol completion | ✓ | [TBD] | [TBD] | [TBD] |
| Bibliography | ✓ | [TBD] | [TBD] | [TBD] |
| Info display | ✓ | [TBD] | [TBD] | [TBD] |
| Search integration | ✓ | [TBD] | [TBD] | [TBD] |
| Performance | [BASELINE] | [TBD] | [TBD] | [TBD] |

### Performance Comparison
[TO BE COMPLETED AFTER TESTING]

### User Experience Comparison
[TO BE COMPLETED AFTER TESTING]

## Recommendations

### Primary Recommendation: Option 1 (blink.compat + cmp-vimtex)

**Rationale**:
- Preserves all existing LaTeX functionality
- Minimal risk of breaking current workflow
- Easiest migration path with most compatibility
- Allows gradual optimization later

**Implementation Strategy**:
1. Start with Option 1 for immediate migration
2. Test thoroughly with real LaTeX documents
3. If performance/functionality issues arise, consider Option 4
4. If unsatisfied with compatibility layer, evaluate Option 2

### Fallback Options

**If Option 1 fails**:
- **Option 4**: LSP + Snippets (acceptable functionality loss for stability)
- **Option 3**: Hybrid approach (if LaTeX is absolutely critical)

**Not recommended**:
- **Option 2**: Too much functionality loss for bibliography-heavy work

### Implementation Priority

1. **HIGH**: Test Option 1 (blink.compat) in isolated environment
2. **MEDIUM**: Create comprehensive LaTeX snippet library for Option 4 fallback
3. **LOW**: Investigate Option 3 hybrid approach complexity

## Implementation Plan

### If Compatible
- [ ] Configuration changes needed
- [ ] Testing steps
- [ ] Migration timeline

### If Not Compatible
- [ ] Alternative solutions
- [ ] Development requirements
- [ ] Timeline considerations

## Risk Assessment

### High Risk Scenarios
- [ ] Complete loss of LaTeX completion functionality
- [ ] Significant performance degradation
- [ ] Loss of bibliography integration

### Mitigation Strategies
- [ ] Rollback procedures
- [ ] Alternative solutions
- [ ] Gradual migration approach

## Research Log

### 2025-01-06 - Initial Setup
- Created research document structure
- Identified current VimTeX configuration
- Outlined testing approach and compatibility options

### 2025-01-06 - Documentation Review COMPLETED
- ❌ **No native LaTeX support** in blink.cmp core
- ✅ **Found community solutions**: blink-cmp-latex, cmp-pandoc-references
- ✅ **Discovered compatibility layer**: blink.compat for nvim-cmp sources
- ✅ **Analyzed current setup**: Comprehensive cmp-vimtex configuration documented

### 2025-01-06 - Compatibility Research COMPLETED  
- ✅ **Option 1**: blink.compat + cmp-vimtex (RECOMMENDED)
- ❌ **Option 2**: Community plugins (insufficient features)
- ⚠️ **Option 3**: Hybrid approach (complex)
- ⚠️ **Option 4**: LSP-only (reduced functionality)

### NEXT: Compatibility Testing
- [ ] Create isolated test environment
- [ ] Test Option 1 with real LaTeX documents
- [ ] Document performance and functionality results

## Conclusion

**LaTeX compatibility with blink.cmp is FEASIBLE** through the blink.compat compatibility layer.

**Key Findings**:
1. **No native LaTeX support** in blink.cmp requires external solutions
2. **blink.compat + cmp-vimtex** provides the best migration path
3. **Minimal configuration changes** needed for Option 1
4. **Full feature preservation** possible with compatibility layer
5. **Low-risk migration** strategy identified

**Confidence Level**: HIGH for successful migration with acceptable trade-offs

## Next Steps
1. **Create test configuration** for blink.compat + cmp-vimtex
2. **Test with representative LaTeX documents** (symbols, bibliography, environments)
3. **Document any performance or functionality differences**
4. **Update main refactor plan** with LaTeX-specific considerations

---

## References
- [blink.cmp Documentation](https://cmp.saghen.dev)
- [cmp-vimtex Repository](https://github.com/micangl/cmp-vimtex)
- [VimTeX Documentation](https://github.com/lervag/vimtex)