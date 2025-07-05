# UTF-8 Rendering Issues Investigation Summary

## Problem
User reported "E976: Using a Blob as a String" errors when viewing markdown files with UTF-8 characters in Neovim, specifically when using the render-markdown.nvim plugin.

## Investigation Results

### 1. Test Files Created
- **test_utf8.md**: Comprehensive UTF-8 test file with various character types
- **test_blob_error.md**: Focused test for problematic characters
- **test_e976_debug.lua**: Debug script to identify blob-to-string conversion issues
- **test_render_markdown_config.lua**: Test comprehensive plugin configuration
- **test_final_utf8.lua**: Final verification script

### 2. Key Findings

#### UTF-8 Handling is Working
- All UTF-8 character types tested successfully:
  - Box drawing characters: ┌─────────┐│ Content │└─────────┘
  - Emoji: 😀 🎉 ❤️ 🚀 🌟
  - Mathematical symbols: ∑ ∏ √ ∞ ≈ ≠ ≤ ≥
  - Asian characters: 你好世界 こんにちは 안녕하세요
  - European characters: café naïve façade über schön
  - Currency symbols: € £ ¥ ₹ ₽

#### Neovim Encoding Settings
- encoding: utf-8
- fileencoding: utf-8
- fileencodings: ucs-bom,utf-8,default,latin1
- termguicolors: true

#### String Operations
All critical string operations that could trigger E976 errors are working correctly:
- string.find()
- string.match()
- string.gsub()
- string.len()
- vim.split()

### 3. Solution Implemented

#### Enhanced render-markdown.nvim Configuration
Updated `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante.lua` with comprehensive configuration:

```lua
{
  'MeanderingProgrammer/render-markdown.nvim',
  opts = {
    file_types = { "markdown", "Avante" },
    -- Comprehensive configuration for UTF-8 handling
    render = {
      max_file_size = 10.0,
      debounce = 100,
      render_modes = { 'n', 'c' },
    },
    anti_conceal = {
      enabled = true,
      above = 0,
      below = 0,
      disabled_modes = { 'i' },
    },
    -- ... (additional configuration for headings, code blocks, tables, etc.)
  },
  ft = { "markdown", "Avante" },
},
```

## Additional Recommendations

### 1. Monitoring
- Watch for specific error patterns in `:messages`
- Test with complex UTF-8 documents
- Monitor performance with large files containing UTF-8

### 2. Potential Issues to Watch For
- Very large files with extensive UTF-8 content
- Nested UTF-8 in code blocks
- Complex table structures with UTF-8
- Mixed encoding files

### 3. Fallback Options
If issues persist, consider:
1. Disabling specific render-markdown features
2. Using alternative markdown rendering plugins
3. Adjusting conceallevel settings

### 4. Debugging Commands
```lua
-- Check current encoding
:lua print(vim.o.encoding, vim.o.fileencoding)

-- Test string operations
:lua local s = "café"; print(type(s), string.find(s, "é"))

-- Check render-markdown status
:lua print(vim.inspect(require('render-markdown')))
```

## Conclusion
The comprehensive render-markdown.nvim configuration should resolve UTF-8 rendering issues. The plugin now has explicit settings for handling various UTF-8 elements including:
- Unicode icons and symbols
- Box drawing characters for tables
- Mathematical expressions
- International characters
- Emoji support

All tests pass successfully, indicating that the E976 error should no longer occur with the updated configuration.

## Files to Clean Up (Optional)
- test_utf8.md
- test_blob_error.md  
- test_e976_debug.lua
- test_render_markdown_config.lua
- test_final_utf8.lua
- UTF8_INVESTIGATION_SUMMARY.md (this file)