# XeLaTeX Incompatibility: xfakebold and pdfrender Package Errors

## Metadata
- **Date**: 2025-10-16
- **Scope**: XeLaTeX compilation errors in possible_worlds.tex after switching from pdfLaTeX
- **Primary Issue**: Package incompatibility with XeLaTeX engine
- **Error Pattern**: `\pdf@box` undefined control sequence, pdfrender warnings
- **Files Analyzed**:
  - `/home/benjamin/Documents/Philosophy/Papers/PossibleWorlds/JPL/possible_worlds.tex`
  - `/home/benjamin/.config/latexmk/latexmkrc`
  - `/home/benjamin/.config/nvim/lua/neotex/plugins/text/vimtex.lua`
  - Build logs from `build/possible_worlds.log`

## Executive Summary

The compilation errors you're seeing are **NOT** due to configuration problems, but rather **package incompatibility** between two LaTeX packages (`xfakebold` and `pdfrender`) and the XeLaTeX engine. These packages were designed for pdfLaTeX and rely on pdfTeX primitives that don't exist in XeLaTeX.

**Root Cause**: The global latexmk configuration now defaults to XeLaTeX (`$pdf_mode = 5`), but your document uses packages that are incompatible with XeLaTeX.

**Impact**: The document compiles but produces numerous errors in the bibliography (.bbl file) where hyperlinks are processed.

**Solution**: Either (1) switch back to pdfLaTeX for this document, or (2) remove/replace the incompatible packages.

## Error Analysis

### Primary Errors

1. **`\pdf@box` undefined control sequence** (86+ occurrences)
   - Location: `possible_worlds.bbl:61`
   - Context: Bibliography hyperlink processing via `breakurl` package
   - Root cause: `breakurl` and `pdfrender` packages use pdfTeX-specific commands

2. **"Package pdfrender Warning: Missing pdfTeX in PDF mode"** (line 233)
   - Explicit warning that pdfrender requires pdfTeX
   - XeLaTeX is NOT pdfTeX, despite both producing PDFs

### Secondary Warnings

3. **Font shape warnings** (200+ occurrences)
   - `Font shape 'TU/lmr/m/scit' undefined using 'TU/lmr/m/scsl' instead`
   - These are cosmetic fallbacks, not critical errors
   - XeLaTeX uses different font encoding (TU) than pdfLaTeX (OT1/T1)

## Technical Background

### XeLaTeX vs pdfLaTeX

| Feature | pdfLaTeX | XeLaTeX |
|---------|----------|---------|
| Font System | Type1 fonts, limited Unicode | OpenType, full Unicode |
| PDF Primitives | `\pdfliteral`, `\pdfobj`, etc. | Uses `xdvipdfmx` backend |
| Package Compatibility | 95%+ of packages | ~85% (some pdfTeX-only packages fail) |
| Use Case | Traditional LaTeX docs | Multilingual, modern fonts |

### Why These Packages Fail

**xfakebold** (line 68 of possible_worlds.tex):
- Depends on `pdfrender` package
- Uses `\pdfliteral` primitive for PDF rendering
- XeLaTeX doesn't have `\pdfliteral` (uses different PDF backend)

**pdfrender**:
- Explicitly checks for pdfTeX engine
- Issues warning: "Missing pdfTeX in PDF mode"
- Defines `\pdf@box` and related macros that require pdfTeX primitives

**Impact Chain**:
```
xfakebold
  └─> requires pdfrender
       └─> requires pdfTeX primitives (\pdfliteral, etc.)
            └─> NOT available in XeLaTeX
                 └─> \pdf@box undefined
                      └─> Cascading errors in .bbl file (hyperlinks)
```

## Why This Happened Now

### Before Optimization (pdfLaTeX default)

```perl
# Old behavior (implicit pdfLaTeX)
# latexmk would use pdflatex by default
```

- Document compiled with pdfLaTeX
- `xfakebold` and `pdfrender` worked correctly
- No errors

### After Optimization (XeLaTeX default)

```perl
# New global configuration
$pdf_mode = 5;  # XeLaTeX for Unicode support
```

- All LaTeX documents now compile with XeLaTeX by default
- Better Unicode support and modern fonts
- BUT: breaks pdfTeX-dependent packages

## Solutions

### Option 1: Per-Project Override (RECOMMENDED)

Create `.latexmkrc` in your project directory to override global settings:

**File**: `/home/benjamin/Documents/Philosophy/Papers/PossibleWorlds/JPL/.latexmkrc`

```perl
# Project-specific latexmk configuration
# Override global XeLaTeX default for this document

$pdf_mode = 1;  # Use pdfLaTeX (compatible with xfakebold/pdfrender)

# Keep other global settings (build directory, etc.)
# These will still be inherited from ~/.config/latexmk/latexmkrc
```

**Why This Works**:
- Project-specific `.latexmkrc` overrides global `~/.config/latexmk/latexmkrc`
- Only this document uses pdfLaTeX
- Other documents can still use XeLaTeX (global default)
- Build artifacts still isolated in `build/` directory

**How to Apply**:
```bash
cd /home/benjamin/Documents/Philosophy/Papers/PossibleWorlds/JPL
echo '$pdf_mode = 1;  # Use pdfLaTeX for xfakebold compatibility' > .latexmkrc
latexmk -C  # Clean build artifacts
latexmk -pdf possible_worlds.tex  # Rebuild with pdfLaTeX
```

### Option 2: Remove Incompatible Packages

If you need XeLaTeX features (Unicode, modern fonts), remove the problematic packages:

**File**: `possible_worlds.tex:68`

```latex
% Before:
\usepackage{xfakebold}  % INCOMPATIBLE with XeLaTeX

% After (Option A - Remove entirely if not needed):
% \usepackage{xfakebold}

% After (Option B - Replace with XeLaTeX-native solution):
% XeLaTeX has built-in font manipulation via fontspec
\usepackage{fontspec}
% Use \textbf{} for bold (XeLaTeX handles this natively)
```

**Trade-offs**:
- Requires document changes
- May affect text appearance if xfakebold was used for specific effects
- Benefits: Full XeLaTeX Unicode support

### Option 3: Use VimTeX Keybindings

If you don't want a project-specific `.latexmkrc`, use the new keybindings:

- `<leader>lf` - Final build (uses global XeLaTeX, will show errors)
- Manual terminal command: `cd JPL && latexmk -pdf -pdflatex possible_worlds.tex`

**Note**: This requires typing the engine every time, less convenient than Option 1.

## Configuration Analysis

### What's Working Correctly

1. **Global latexmkrc** (`~/.config/latexmk/latexmkrc`):
   - XeLaTeX configuration is correct
   - Build isolation working (`build/` directory)
   - Error reporting functional

2. **VimTeX Configuration** (`vimtex.lua`):
   - Compiler method: `latexmk` ✓
   - Build directory: `build` ✓
   - XeLaTeX flags: correct ✓
   - Quickfix mode: enabled ✓

3. **Error Visibility**:
   - Errors ARE showing in quickfix window
   - This is desired behavior (Phase 1 goal achieved)

### What Needs Adjustment

**Global Configuration Decision**:
- Setting `$pdf_mode = 5` (XeLaTeX) globally is a trade-off
- **Pros**: Unicode support, modern fonts, future-proof
- **Cons**: Breaks some legacy packages (xfakebold, pdfrender, etc.)

**Recommendation**: Keep XeLaTeX as global default, use project-specific overrides for documents with incompatible packages.

## Lessons Learned for Configuration Improvement

### 1. Engine Compatibility Documentation

**Add to RESEARCH_TOOLING.md** under "LaTeX Compilation Optimization":

```markdown
### Engine Compatibility

**XeLaTeX Limitations**:
- Does NOT support pdfTeX-specific packages:
  - `xfakebold` (use `fontspec` instead)
  - `pdfrender` (no direct replacement)
  - `breakurl` (use `hyperref` with `breaklinks` option)
  - Any package using `\pdfliteral`, `\pdfobj`, `\pdf@box`

- **Common Error Pattern**: `\pdf@box undefined control sequence`
- **Solution**: Create project-specific `.latexmkrc` with `$pdf_mode = 1`

**When to Use pdfLaTeX**:
- Legacy documents with pdfTeX-dependent packages
- Springer/Elsevier templates (often use pdfTeX primitives)
- Documents using `xfakebold`, `pdfrender`, or similar packages

**When to Use XeLaTeX**:
- Documents requiring Unicode characters (Greek, Chinese, etc.)
- Modern OpenType font usage
- New documents without legacy package dependencies
```

### 2. Project-Specific Override Template

**Create**: `nvim/templates/latexmkrc-pdflatex`

```perl
# Project-specific latexmk configuration
# Use pdfLaTeX for compatibility with legacy packages

$pdf_mode = 1;  # pdfLaTeX (compatible with most packages)

# Inherits other settings from ~/.config/latexmk/latexmkrc:
# - Build directory isolation (build/)
# - Error reporting (-file-line-error)
# - Auxiliary file handling ($emulate_aux = 1)
```

### 3. Quickfix Filtering Enhancement

Add to `vimtex.lua` quickfix filters to suppress font shape warnings:

```lua
vim.g.vimtex_quickfix_ignore_filters = {
  'Underfull',
  'Overfull',
  'specifier changed to',
  'Token not allowed in a PDF string',
  'Package hyperref Warning',
  'Font shape.*undefined',  -- NEW: Filter font shape fallback warnings
  'Missing pdfTeX in PDF mode',  -- NEW: XeLaTeX package warnings
}
```

### 4. Improved Global Configuration

**Update**: `~/.config/latexmk/latexmkrc`

Add comment about project overrides:

```perl
# PDF Generation Mode
# 1 = pdflatex, 4 = lualatex, 5 = xelatex
$pdf_mode = 5;  # Use XeLaTeX for Unicode and modern font support

# NOTE: XeLaTeX is incompatible with some pdfTeX-specific packages:
#   - xfakebold, pdfrender, breakurl (use pdfTeX primitives)
#   - Solution: Create project .latexmkrc with $pdf_mode = 1
#   - Example: echo '$pdf_mode = 1;' > .latexmkrc
```

### 5. VimTeX Keybinding Enhancement

**Optional**: Add keybinding to quickly create project override:

**File**: `nvim/after/ftplugin/tex.lua`

```lua
-- Add keybinding for creating pdflatex override
{ "<leader>lp", function()
  local override = "$pdf_mode = 1;  # Use pdfLaTeX for compatibility\n"
  local file = vim.fn.getcwd() .. "/.latexmkrc"
  vim.fn.writefile({override}, file)
  print("Created " .. file .. " with pdfLaTeX override")
end, desc = "pdflatex override", icon = "󰿆", buffer = 0 },
```

## Immediate Action Plan

1. **Fix the current document** (5 minutes):
   ```bash
   cd /home/benjamin/Documents/Philosophy/Papers/PossibleWorlds/JPL
   echo '$pdf_mode = 1;  # Use pdfLaTeX for xfakebold compatibility' > .latexmkrc
   latexmk -C
   latexmk -pdf possible_worlds.tex
   ```

2. **Update documentation** (10 minutes):
   - Add engine compatibility section to `RESEARCH_TOOLING.md`
   - Add comment to global `latexmkrc` about overrides

3. **Enhance quickfix filtering** (5 minutes):
   - Add font shape and pdfTeX warning filters to `vimtex.lua`

4. **Test other LaTeX documents** (as needed):
   - Check if other documents have similar issues
   - Create project-specific `.latexmkrc` where needed

## References

### Relevant Files
- **Document**: `/home/benjamin/Documents/Philosophy/Papers/PossibleWorlds/JPL/possible_worlds.tex:68` (xfakebold usage)
- **Global Config**: `/home/benjamin/.config/latexmk/latexmkrc:6` ($pdf_mode = 5)
- **VimTeX Config**: `/home/benjamin/.config/nvim/lua/neotex/plugins/text/vimtex.lua:24` (-xelatex flag)
- **Build Log**: `/home/benjamin/Documents/Philosophy/Papers/PossibleWorlds/JPL/build/possible_worlds.log` (error details)

### Related Documentation
- XeLaTeX documentation: https://ctan.org/pkg/xetex
- pdfrender package: https://ctan.org/pkg/pdfrender
- xfakebold package: https://ctan.org/pkg/xfakebold
- latexmk manual: https://mg.readthedocs.io/latexmk.html

### TeX Stack Exchange Discussions
- "xfakebold with XeLaTeX": https://tex.stackexchange.com/q/370021
- "pdfrender incompatible with XeLaTeX": https://tex.stackexchange.com/q/429826
- "Project-specific latexmkrc": https://tex.stackexchange.com/q/34856

## Conclusion

The errors are **expected behavior** when using XeLaTeX with pdfTeX-dependent packages. This is not a configuration bug, but rather a **compatibility issue** that requires a project-specific solution.

**Key Takeaway**: Global XeLaTeX default is valuable for modern documents, but legacy documents with pdfTeX packages need project-specific overrides. This is a standard practice in LaTeX workflows.

The configuration improvements from the optimization plan (build isolation, error visibility, draft mode) are all working correctly. The only adjustment needed is adding per-project overrides for documents with incompatible packages.
