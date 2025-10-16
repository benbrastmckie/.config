# Nvim Unicode Display Issue Report

## Problem Description

When viewing UTF-8 encoded files containing mathematical Unicode characters in nvim, the characters are being displayed incorrectly. For example:

- `¬¬A ⊢ A` is displayed as `Â¬Â¬A â¢ A`
- `→` (arrow) is displayed as `â`
- `∃` (exists) is displayed with replacement characters
- `∧` (and) is displayed incorrectly

## Root Cause

The file is correctly encoded in UTF-8, but nvim is interpreting it with a different encoding (likely Latin-1/ISO-8859-1). This causes multi-byte UTF-8 sequences to be misinterpreted as multiple single-byte characters.

### Technical Details

UTF-8 encodes Unicode characters using 1-4 bytes:
- `¬` (NOT) = `0xC2 0xAC` in UTF-8
- When interpreted as Latin-1: `0xC2` = `Â` and `0xAC` = `¬`
- Result: `¬` appears as `Â¬`

## Nvim Configuration Solutions

Add these settings to your nvim configuration file (`~/.config/nvim/init.vim` or `~/.config/nvim/init.lua`):

### For init.vim:
```vim
" Set encoding to UTF-8
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8,latin1

" Ensure terminal encoding is UTF-8
set termencoding=utf-8

" Enable multibyte support
set bomb
set binary

" Set script encoding for vim config itself
scriptencoding utf-8

" Ensure proper display of Unicode
set ambiwidth=single

" Optional: Set font that supports Unicode
if has("gui_running")
  set guifont=DejaVu\ Sans\ Mono:h12
endif
```

### For init.lua:
```lua
-- Set encoding to UTF-8
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.fileencodings = "utf-8,latin1"

-- Ensure terminal encoding is UTF-8
vim.opt.termencoding = "utf-8"

-- Enable multibyte support
vim.opt.bomb = true
vim.opt.binary = true

-- Ensure proper display of Unicode
vim.opt.ambiwidth = "single"

-- Optional: Set font that supports Unicode
if vim.fn.has("gui_running") == 1 then
  vim.opt.guifont = "DejaVu Sans Mono:h12"
end
```

## Terminal Configuration

Also ensure your terminal emulator is configured correctly:

### Check terminal locale:
```bash
echo $LANG
echo $LC_ALL
echo $LC_CTYPE
```

These should show UTF-8 values like `en_US.UTF-8`.

### Set locale if needed:
```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
```

Add these to your `~/.bashrc` or `~/.zshrc` to make permanent.

## Font Requirements

Ensure your terminal font supports Unicode characters:
- **Recommended fonts**: DejaVu Sans Mono, Source Code Pro, Fira Code, JetBrains Mono
- **Test**: Type `:echo "¬¬A ⊢ A → ∃x"` in nvim to verify characters display correctly

## Troubleshooting Steps

1. **Check current encoding in nvim**:
   ```vim
   :set encoding?
   :set fileencoding?
   :set fileencodings?
   ```

2. **Check file encoding**:
   ```vim
   :set fileencoding?
   :set bomb?
   ```

3. **Force reload with UTF-8**:
   ```vim
   :e ++enc=utf-8
   ```

4. **Check if characters are correct in file**:
   ```vim
   :set list
   :set listchars=tab:>-,trail:·,nbsp:·
   ```

## Test Characters

After applying the configuration, these characters should display correctly:

| Character | Name | Unicode | UTF-8 Bytes |
|-----------|------|---------|-------------|
| ¬ | NOT | U+00AC | C2 AC |
| ⊢ | TURNSTILE | U+22A2 | E2 8A A2 |
| → | RIGHTWARD ARROW | U+2192 | E2 86 92 |
| ∃ | EXISTS | U+2203 | E2 88 83 |
| ∀ | FOR ALL | U+2200 | E2 88 80 |
| ∈ | ELEMENT OF | U+2208 | E2 88 88 |
| ⊑ | SQUARE IMAGE OF | U+2291 | E2 8A 91 |
| ∧ | LOGICAL AND | U+2227 | E2 88 A7 |
| ⊔ | SQUARE CUP | U+2294 | E2 8A 94 |
| φ | GREEK PHI | U+03C6 | CF 86 |

## Alternative: ASCII Fallback

If Unicode display continues to be problematic, consider using ASCII alternatives:
- `~` for `¬`
- `|-` for `⊢`
- `->` for `→`
- `EXISTS` for `∃`
- `FORALL` for `∀`
- `in` for `∈`
- `<=` for `⊑`
- `AND` for `∧`
- `U` for `⊔`
- `phi` for `φ`

## Verification

Create a test file with this content:
```
Mathematical Logic Symbols Test:
¬¬A ⊢ A
∃x ∈ S: P(x) ∧ Q(x)
∀y: y ⊑ z → f(y) ⊔ g(y)
φ ≠ ψ
```

If these display correctly after applying the configuration, the issue is resolved.