# Treesitter "out of range" Error Fix

## Problem
The error "Invalid 'end_col': out of range" occurs in treesitter/highlighter.lua when deleting lines or performing certain text operations.

## Root Cause
The error is caused by treesitter's parser state becoming desynchronized with the actual buffer content, particularly when:
- Lines are deleted from the buffer
- The parser still holds references to old positions
- Column calculations become invalid

## Implemented Solution

### 1. Enhanced Treesitter Configuration
Modified `lua/neotex/plugins/editor/treesitter.lua` to:
- Add sync settings to prevent parser state issues
- Include proper module configuration
- Set `sync_install = false` to avoid synchronous parser operations

### 2. Automatic Parser Synchronization
Added an autocmd that monitors `TextChanged` and `TextChangedI` events to:
- Check if the parser is in a valid state
- Automatically invalidate the parser when needed
- Use pcall for safe error handling

### 3. Error Recovery System
Created `after/plugin/treesitter-recovery.lua` which:
- Intercepts the specific "out of range" errors
- Downgrades them to debug level (preventing console spam)
- Triggers a debounced parser reset (100ms delay)
- Cleans up timers on buffer deletion

## How It Works
1. When you delete lines, if treesitter tries to highlight invalid positions, an error occurs
2. The error recovery system catches this specific error
3. It schedules a parser invalidation after 100ms (debounced)
4. The parser re-synchronizes with the buffer content
5. Highlighting continues normally

## Testing
To test the fix:
1. Open `/tmp/test_treesitter.lua`
2. Delete multiple lines quickly
3. The error should no longer appear in the console
4. Syntax highlighting should remain functional

## Benefits
- No user intervention required
- Errors are logged at debug level for troubleshooting
- Minimal performance impact (100ms debounce)
- Clean, maintainable solution
- Easy to remove when upstream fix is available