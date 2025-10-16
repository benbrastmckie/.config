# LaTeX PDF Compilation Optimization Implementation Plan

## Metadata
- **Date**: 2025-10-16
- **Feature**: Optimize LaTeX PDF compilation for speed and reliability
- **Scope**: VimTeX configuration improvements, Tectonic integration, optional Typst support
- **Estimated Phases**: 5
- **Standards File**: /home/benjamin/.config/CLAUDE.md, /home/benjamin/.config/nvim/CLAUDE.md
- **Research Sources**: Orchestrated research on current implementation, XeLaTeX optimization, and Typst integration

## Overview

This plan addresses slow and unreliable LaTeX PDF compilation by implementing systematic optimizations to the current VimTeX + latexmk workflow. The approach provides multiple tiers of improvement:

1. **Tier 1 (Low-risk)**: Global latexmk configuration and VimTeX tuning
2. **Tier 2 (Moderate improvement)**: Tectonic integration as alternative compiler
3. **Tier 3 (Optional)**: Typst support for new documents

The implementation preserves existing LaTeX documents while dramatically improving compilation speed and reliability through better caching, modern tooling, and parallel compilation strategies.

## Success Criteria
- [ ] Global `.latexmkrc` configured with performance optimizations
- [ ] VimTeX properly configured with explicit compiler backend selection
- [ ] Tectonic available as alternative LaTeX engine with caching enabled
- [ ] Compilation speed improved by at least 30% on representative documents
- [ ] Build errors visible and actionable (quickfix mode configured)
- [ ] Optional Typst support functional for new documents
- [ ] Documentation updated with compilation workflow guidance

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Neovim (VimTeX)                          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Compilation Backend Selection                        │  │
│  │  - latexmk (default, optimized)                       │  │
│  │  - Tectonic (fast alternative)                        │  │
│  │  - Typst (new documents only)                         │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
┌───────────────┐  ┌──────────────┐  ┌──────────────┐
│   latexmk     │  │   Tectonic   │  │    Typst     │
│               │  │              │  │              │
│ • XeLaTeX     │  │ • Rust-based │  │ • Native     │
│ • LuaLaTeX    │  │ • Auto-cache │  │ • Fast       │
│ • pdfLaTeX    │  │ • XeTeX compat│ │ • New docs   │
│ • Draft mode  │  │ • Reproducible│ │ • Incremental│
│ • Caching     │  │              │  │              │
└───────────────┘  └──────────────┘  └──────────────┘
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  PDF Output │
                    │  (Sioyek)   │
                    └─────────────┘
```

### Key Design Decisions

1. **Global latexmkrc with local overrides**: System-wide optimizations in `~/.config/latexmk/latexmkrc`, project-specific settings can override
2. **Explicit engine configuration**: VimTeX will specify compiler backend rather than relying on defaults
3. **Tectonic as opt-in alternative**: Available via keybinding, not default (preserves compatibility)
4. **Typst separate filetype**: Independent from LaTeX workflow, invoked for `.typ` files
5. **Draft mode during editing**: Fast compilation with zero compression, final build on demand
6. **Visible errors**: Re-enable quickfix mode with smart filtering for actionable feedback

### Component Interactions

- **VimTeX** → **Global latexmkrc**: Inherits optimized defaults
- **VimTeX** → **Tectonic**: Alternative compilation via custom command
- **Neovim ftplugin** → **Typst**: Separate compilation workflow for `.typ` files
- **SyncTeX**: Maintained for all compilation backends (forward/inverse search)

## Implementation Phases

### Phase 1: Global latexmk Configuration and VimTeX Tuning
**Objective**: Establish optimized default compilation settings system-wide
**Complexity**: Low
**Estimated Time**: 30 minutes

Tasks:
- [ ] Create `~/.config/latexmk/` directory if not exists
- [ ] Write global `latexmkrc` with performance optimizations:
  - Set `$xelatex` with `-interaction=nonstopmode` and `-synctex=1`
  - Configure `$pdf_mode = 5` for XeLaTeX by default (or 4 for LuaLaTeX if preferred)
  - Enable `-file-line-error` for better error reporting
  - Set `$out_dir = 'build'` to isolate build artifacts
  - Configure `$emulate_aux = 1` for faster auxiliary file handling
  - Set `$max_repeat = 5` to prevent infinite recompilation loops
- [ ] Update VimTeX configuration in `nvim/lua/neotex/plugins/text/vimtex.lua`:
  - Set `vim.g.vimtex_compiler_method = 'latexmk'` (explicit)
  - Configure `vim.g.vimtex_compiler_latexmk` table with engine options
  - Re-enable quickfix mode: `vim.g.vimtex_quickfix_mode = 2` (quickfix window on errors)
  - Add quickfix filtering for common noise: `vim.g.vimtex_quickfix_ignore_filters`
- [ ] Document latexmk configuration in `nvim/docs/RESEARCH_TOOLING.md`

Testing:
```bash
# Test global latexmkrc
cd ~/Documents/Philosophy/Teaching/MIT/Logic/ForAllX/
latexmk -pvc forallx-logsem.tex

# Test VimTeX integration
nvim ~/Documents/Philosophy/Teaching/MIT/Logic/ForAllX/forallx-logsem.tex
# In nvim: <leader>lc to compile, check quickfix window appears
```

Expected Outcome:
- Compilation uses configured engine (XeLaTeX or LuaLaTeX)
- Build artifacts isolated in `build/` directory
- Errors visible in quickfix window
- Baseline compilation speed measured for comparison

### Phase 2: Draft Mode and Fast Iteration Setup
**Objective**: Enable fast draft compilation during editing, final build on demand
**Complexity**: Low
**Estimated Time**: 20 minutes

Tasks:
- [ ] Add draft mode configuration to global `latexmkrc`:
  - Define `$draft_mode` variable (set via environment or command-line)
  - Configure XeLaTeX draft flags: `-output-driver='xdvipdfmx -z0'` (zero compression)
  - Add conditional for final build mode (full compression, optimizations)
- [ ] Update VimTeX commands in `nvim/after/ftplugin/tex.lua`:
  - Add `<leader>ld` keybinding for draft mode compilation
  - Add `<leader>lf` keybinding for final mode compilation (existing `<leader>lc` becomes default)
  - Set draft mode as default for `<leader>lc` (fast iteration)
- [ ] Configure continuous compilation: `vim.g.vimtex_compiler_latexmk.continuous = 1` for draft mode

Testing:
```bash
# Test draft mode speed
time latexmk -pvc -e '$draft_mode=1' test_document.tex

# Test final mode quality
time latexmk -e '$draft_mode=0' test_document.tex

# Compare PDF sizes (draft should be larger due to zero compression)
ls -lh build/*.pdf
```

Expected Outcome:
- Draft mode compilation 20-40% faster than full build
- Draft PDFs viewable with all content (just larger file size)
- Final build produces optimized PDF for distribution

### Phase 3: Tectonic Integration as Alternative Backend
**Objective**: Provide Tectonic as fast, reproducible alternative LaTeX engine
**Complexity**: Medium
**Estimated Time**: 45 minutes

Tasks:
- [ ] Install Tectonic: `nix profile install nixpkgs#tectonic` (or appropriate package manager)
- [ ] Test Tectonic compilation: `tectonic --synctex test.tex`
- [ ] Add Tectonic compiler configuration to `vimtex.lua`:
  - Define custom compiler: `vim.g.vimtex_compiler_tectonic` table
  - Configure build options: `--synctex`, `--keep-logs`, `--keep-intermediates`
  - Set output directory to match latexmk (`build/`)
- [ ] Add Tectonic-specific keybindings in `tex.lua`:
  - `<leader>lt` to compile with Tectonic
  - `<leader>lT` for Tectonic continuous mode (watch for changes)
- [ ] Create wrapper script `~/.local/bin/tectonic-build.sh` for consistent invocation:
  - Handles SyncTeX path mapping
  - Manages cache directory (`~/.cache/tectonic/`)
  - Provides verbose output for debugging
- [ ] Update `RESEARCH_TOOLING.md` with Tectonic usage guide

Testing:
```bash
# Test Tectonic standalone
tectonic --synctex ~/Documents/Philosophy/Teaching/MIT/Logic/ForAllX/forallx-logsem.tex

# Test VimTeX Tectonic integration
nvim test_document.tex
# In nvim: <leader>lt to compile with Tectonic

# Verify SyncTeX forward/inverse search works
# In nvim: <leader>lv (view PDF), Ctrl+Click in Sioyek should jump to nvim
```

Expected Outcome:
- Tectonic compiles LaTeX documents successfully
- Auto-downloads missing packages on first run
- Subsequent compilations use cached packages (faster)
- SyncTeX integration functional with Sioyek
- Tectonic available as alternative, not breaking existing latexmk workflow

### Phase 4: Advanced Optimizations (TikZ, Preamble, Includes)
**Objective**: Implement advanced techniques for large/complex documents
**Complexity**: Medium
**Estimated Time**: 40 minutes

Tasks:
- [ ] Create template for preamble precompilation:
  - New file: `nvim/templates/article-precompiled.tex`
  - Demonstrate `mylatexformat` package usage for format file generation
  - Document workflow: compile preamble once, reuse for fast iterations
- [ ] Add TikZ externalization template:
  - New file: `nvim/templates/article-tikz-external.tex`
  - Configure `\usetikzlibrary{external}` with proper paths
  - Add latexmkrc snippet for TikZ external compilation
- [ ] Document `\includeonly` workflow for large documents:
  - Add section to `RESEARCH_TOOLING.md`
  - Provide example of chapter-based document structure
  - Explain how to compile only modified chapters
- [ ] Create helper function in `tex.lua` for toggling `\includeonly`:
  - `<leader>li` to prompt for chapter/section to compile
  - Modifies `\includeonly{}` in document preamble
  - Re-compiles with selected sections only

Testing:
```bash
# Test preamble precompilation (manual)
cd nvim/templates/
pdflatex -ini -job-name="preamble" "&pdflatex preamble.tex\dump"
pdflatex "&preamble" article-precompiled.tex

# Test TikZ externalization
nvim nvim/templates/article-tikz-external.tex
# Compile multiple times, verify TikZ figures only regenerate when changed
```

Expected Outcome:
- Preamble precompilation template available for complex documents
- TikZ externalization reduces recompilation time for graphics-heavy docs
- `\includeonly` workflow documented and accessible
- Helper function makes selective compilation convenient

### Phase 5: Optional Typst Support for New Documents
**Objective**: Enable Typst compilation for new documents, separate from LaTeX workflow
**Complexity**: Low
**Estimated Time**: 30 minutes

Tasks:
- [ ] Install Typst: `nix profile install nixpkgs#typst` (or appropriate package manager)
- [ ] Create Typst ftplugin: `nvim/after/ftplugin/typst.lua`
  - Set up buffer-local keybindings: `<leader>tc` (compile), `<leader>tw` (watch mode)
  - Configure compilation command: `typst compile --watch %`
  - Set up PDF viewer integration (reuse Sioyek or alternative)
- [ ] Add Typst templates:
  - `nvim/templates/typst-article.typ` - basic article
  - `nvim/templates/typst-report.typ` - report with sections
  - `nvim/templates/typst-beamer.typ` - presentation (equivalent to LaTeX beamer)
- [ ] Configure Typst LSP if available (typst-lsp):
  - Add to `nvim/lua/neotex/plugins/lsp/config.lua`
  - Enable completion, diagnostics, hover
- [ ] Document Typst workflow in `RESEARCH_TOOLING.md`:
  - When to use Typst vs LaTeX
  - MiTeX package for LaTeX math compatibility
  - Bibliography management (BibTeX support)

Testing:
```bash
# Test Typst compilation
typst compile nvim/templates/typst-article.typ

# Test watch mode
typst compile --watch test_document.typ &
# Edit document, verify auto-recompilation

# Test VimTeX-like workflow in Neovim
nvim test_document.typ
# In nvim: <leader>tc to compile, <leader>tw for watch mode
```

Expected Outcome:
- Typst available for new documents with fast compilation
- Templates provide starting points for common document types
- Workflow similar to VimTeX (compile, view, watch)
- Clear documentation guides when to choose Typst vs LaTeX
- MiTeX documented for users needing LaTeX math compatibility

## Testing Strategy

### Baseline Performance Measurement
Before implementing optimizations, measure baseline compilation times:
```bash
# Representative documents:
cd ~/Documents/Philosophy/Teaching/MIT/Logic/ForAllX/
time latexmk -pdf forallx-logsem.tex

# Record metrics:
# - First compilation (cold): ___ seconds
# - Incremental compilation (warm): ___ seconds
# - Full rebuild after clean: ___ seconds
```

### Phase-by-Phase Testing
After each phase:
1. Measure compilation time for same representative documents
2. Verify output PDF quality (no regressions)
3. Test SyncTeX forward/inverse search
4. Check error reporting and quickfix functionality
5. Document improvements in phase testing notes

### Integration Testing
After all phases complete:
```bash
# Test multiple compilation backends on same document
latexmk -pdf test.tex          # Default (optimized latexmk)
tectonic --synctex test.tex    # Tectonic alternative
typst compile test.typ         # Typst for comparison

# Compare metrics:
# - Compilation speed
# - PDF file size
# - Error reporting quality
# - SyncTeX accuracy
```

### Performance Targets
- **Phase 1**: 10-15% speed improvement from global config
- **Phase 2**: Additional 20-30% improvement in draft mode
- **Phase 3**: Tectonic 5-20% faster on first run (after cache warm)
- **Phase 4**: 40-60% improvement for documents using advanced techniques
- **Phase 5**: Typst 3-4× faster than LaTeX (for Typst documents)

**Overall Target**: 30-50% compilation speed improvement for typical LaTeX documents

## Documentation Requirements

### Files to Update
1. **`nvim/docs/RESEARCH_TOOLING.md`**:
   - Add "LaTeX Compilation Optimization" section
   - Document latexmk configuration and rationale
   - Explain draft vs final mode workflow
   - Provide Tectonic usage guide
   - Document advanced optimization techniques
   - Add Typst integration guide

2. **`nvim/after/ftplugin/tex.lua`**:
   - Comment new keybindings with descriptions
   - Document Tectonic integration
   - Explain helper functions (includeonly toggle)

3. **`nvim/templates/README.md`**:
   - Document new LaTeX templates (precompiled preamble, TikZ external)
   - Document Typst templates and use cases

4. **Global latexmkrc**:
   - Inline comments explaining each optimization
   - References to latexmk documentation
   - Examples of project-specific overrides

### New Documentation
Create `~/.config/latexmk/README.md`:
- Explain global vs project-specific configuration
- Document performance tuning options
- Provide troubleshooting guide for common issues

## Dependencies

### System Dependencies
- **latexmk** (already installed, verify ≥4.73 for performance fixes)
- **XeLaTeX / LuaLaTeX** (already installed, v4.83)
- **Tectonic** (Phase 3): Install via Nix or package manager
- **Typst** (Phase 5, optional): Install via Nix or package manager
- **SyncTeX** (already available in TeX distributions)

### Neovim Plugin Dependencies
- **VimTeX** (already installed and configured)
- **nvim-treesitter** (for Typst syntax highlighting in Phase 5)
- **typst-lsp** (optional, Phase 5, for Typst language server)

### Installation Commands
```bash
# Tectonic (Phase 3)
nix profile install nixpkgs#tectonic
# or: cargo install tectonic (if using Rust toolchain)

# Typst (Phase 5)
nix profile install nixpkgs#typst
# or: cargo install --git https://github.com/typst/typst

# Typst LSP (optional, Phase 5)
nix profile install nixpkgs#typst-lsp
# or: cargo install typst-lsp
```

## Risk Assessment and Mitigation

### Risk: Global latexmkrc breaks project-specific workflows
**Likelihood**: Low
**Impact**: Medium
**Mitigation**:
- Test with existing project latexmkrc (`ForAllX/.latexmkrc`)
- Document override mechanism in global config
- Provide fallback: comments in global config allow easy disabling

### Risk: Tectonic compatibility issues with complex packages
**Likelihood**: Medium
**Impact**: Medium
**Mitigation**:
- Keep latexmk as default, Tectonic as opt-in alternative
- Document known incompatibilities (rare, but some packages)
- Fallback: use latexmk if Tectonic fails

### Risk: Draft mode produces unexpected output
**Likelihood**: Low
**Impact**: Low
**Mitigation**:
- Draft mode only affects compression, not content
- Final mode easily accessible via `<leader>lf`
- Clearly label draft vs final in keybinding documentation

### Risk: Typst adoption creates confusion about when to use what
**Likelihood**: Medium
**Impact**: Low
**Mitigation**:
- Clear documentation: "Use Typst for NEW documents, keep LaTeX for existing"
- Separate filetypes prevent accidental mixing
- Templates guide appropriate usage

### Risk: SyncTeX breaks with Tectonic or Typst
**Likelihood**: Low (Tectonic), Medium (Typst)
**Impact**: Medium
**Mitigation**:
- Test SyncTeX integration thoroughly in Phase 3/5
- Tectonic has good SyncTeX support (similar to XeTeX)
- Typst SyncTeX support improving, document workarounds if needed

## Notes

### Research Findings Incorporated
This plan integrates findings from parallel research on:
1. **Current implementation**: VimTeX + latexmk, no explicit engine config, suppressed errors
2. **XeLaTeX optimization**: latexrun (35% faster), Tectonic (Rust-based with caching), draft modes
3. **Typst integration**: 3-4× speed improvement, MiTeX for LaTeX math, hybrid workflows feasible

### Design Philosophy
- **Preserve existing workflows**: All LaTeX documents continue working unchanged
- **Opt-in improvements**: New tools (Tectonic, Typst) available but not forced
- **Incremental adoption**: Each phase provides value independently
- **Clear migration path**: Documentation guides users from basic to advanced optimizations

### Future Enhancements (Out of Scope)
- Parallel compilation for multi-part documents
- Cloud-based compilation (Overleaf-style)
- Automated package management beyond Tectonic
- AI-powered error interpretation and fixes
- Integration with citation managers (Zotero, etc.)

### Complexity Analysis
**Overall Complexity**: Low-Medium
- Phases 1-2: Low complexity, high impact
- Phase 3: Medium complexity, moderate impact
- Phase 4: Medium complexity, high impact for specific use cases
- Phase 5: Low complexity, optional/exploratory

**Total Estimated Time**: 2.5-3 hours for full implementation

### Success Metrics
1. **Speed**: 30%+ improvement in typical compilation times
2. **Reliability**: Errors visible and actionable, fewer compilation failures
3. **Usability**: Clear keybindings and documentation, easy to adopt
4. **Flexibility**: Multiple backends available for different use cases
5. **Compatibility**: All existing LaTeX documents compile without changes

---

*This plan follows project standards from `/home/benjamin/.config/CLAUDE.md` and `/home/benjamin/.config/nvim/CLAUDE.md`. Implementation can proceed phase-by-phase with testing and git commits after each phase.*
