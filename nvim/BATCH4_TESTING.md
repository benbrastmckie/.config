# Batch 4 Testing Guide: Plugin Loading Structure

## Changes Implemented
- Created `lua/neotex/plugins/init.lua` with category-based plugin organization
- Updated `bootstrap.lua` to work with the new plugin structure
- Added fallback mechanism for backward compatibility
- Created `test_plugins.lua` for verification

## Testing Procedure

### Basic Functionality Test
1. Start NeoVim normally:
   ```bash
   nvim
   ```
2. Check for any error messages in the notification area
3. Verify key plugins are loaded and working (Telescope, Treesitter, etc.)

### Specific Test Script
1. Run the test script to verify plugin loading:
   ```bash
   nvim -u /home/benjamin/.config/nvim/init.lua --cmd "source /home/benjamin/.config/nvim/test_plugins.lua"
   ```
2. This will display a count of loaded plugins and verify key plugins

### Health Check
1. From within NeoVim, run:
   ```
   :checkhealth
   ```
2. Verify there are no errors related to plugin loading

## Expected Results
- All plugins should load correctly
- You should see "Using new modular plugin system" in the notifications
- The test script should show approximately the same number of plugins as before
- Key plugins (Telescope, Treesitter, etc.) should function normally

## Troubleshooting
If you encounter issues:

1. Check log files:
   ```bash
   tail -n 100 ~/.local/state/nvim/log
   ```

2. Try falling back to the old structure by temporarily renaming:
   ```bash
   mv ~/.config/nvim/lua/neotex/plugins/init.lua ~/.config/nvim/lua/neotex/plugins/init.lua.bak
   ```

3. Debug specific plugin issues by adding this to the top of the failing plugin file:
   ```lua
   vim.notify("Loading plugin: " .. debug.getinfo(1, "S").source:sub(2))
   ```

## Next Steps
After confirming the new plugin loading structure works correctly:

1. Move to Batch 5: URL Handling and Specialized Features
2. Consider adding more metadata to plugin categories to improve organization