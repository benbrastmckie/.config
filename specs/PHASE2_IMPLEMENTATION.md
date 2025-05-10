# Phase 2 Implementation Plan: Mini Ecosystem and Simple Plugin Updates

This document outlines a detailed, incremental approach to implementing Phase 2 of the NeoVim configuration refactoring. Each step is designed to be small, testable, and reversible if issues occur.

## Implementation Steps

### ✅ Batch 1: Mini.pairs Integration

**Goal**: Replace autopairs with mini.pairs while maintaining functionality.

1. **Create plugins/coding directory** ✓
   - Create `lua/neotex/plugins/coding/` directory
   - Create basic `init.lua` to load submodules

2. **Create mini module** ✓
   - Create `lua/neotex/plugins/coding/mini.lua`
   - Add basic setup for mini.nvim plugin
   - Implement mini.pairs for the initial configuration

3. **Update bootstrap.lua** ✓
   - Uncomment the coding plugins import in bootstrap.lua
   - Test: Verify NeoVim starts without errors and plugin loads

4. **Configure mini.pairs** ✓
   - Add detailed configuration matching autopairs functionality:
     - Default pairs for basic characters
     - Filetype-specific rules
     - Disable in select filetypes if needed
   - Test: Verify basic pair insertion works

5. **Compare with autopairs** ✓
   - Test against existing autopairs behavior
   - Fix any differences in behavior
   - Check both insert and normal modes

**Testing**: ✓
- Verify NeoVim starts without errors
- Test basic pair insertion ((), [], {}, '')
- Test deletion behavior (deleting opening should remove closing)
- Test with markdown, LaTeX, and code files
- Check for any regressions against previous behavior

**Commit**: "Add mini.pairs replacing autopairs" ✓

### ✅ Batch 2: Mini.surround Integration

**Goal**: Replace surround with mini.surround while maintaining functionality.

1. **Analyze current surround usage** ✓
   - Review current keymappings and usage patterns
   - Document any custom configurations

2. **Add mini.surround to mini.lua** ✓
   - Extend mini.lua configuration with mini.surround
   - Configure to match existing surround behavior

3. **Configure and test mappings** ✓
   - Ensure key mappings match existing surround plugin
   - Add extra mappings from the existing configuration

4. **Handle custom surroundings** ✓
   - Configure any custom surround patterns (LaTeX, markdown, etc.)
   - Test with each filetype

**Testing**: ✓
- Test surrounding words with various characters
- Test deleting surroundings
- Test changing surroundings
- Test visual mode surrounding
- Verify consistency with previous behavior

**Commit**: "Add mini.surround replacing surround.lua" ✓

### ✅ Batch 3: Mini.comment Integration

**Goal**: Replace comment plugin with mini.comment while maintaining functionality.

1. **Analyze current comment usage** ✓
   - Review current keymappings
   - Document any custom configurations

2. **Add mini.comment to mini.lua** ✓
   - Extend mini.lua configuration with mini.comment
   - Configure to match existing comment behavior

3. **Configure and test keymaps** ✓
   - Set up keymappings matching previous configuration
   - Test line and block commenting

4. **Handle custom filetypes** ✓
   - Configure for specialized filetypes (LaTeX, markdown, etc.)
   - Test with each filetype

**Testing**: ✓
- Test commenting/uncommenting single lines
- Test commenting/uncommenting blocks
- Test with various file types (Lua, Python, LaTeX, etc.)
- Verify integration with existing key mappings

**Commit**: "Add mini.comment replacing Comment.nvim" ✓

### ✅ Batch 4: Mini.cursorword Integration

**Goal**: Replace local-highlight with mini.cursorword while maintaining functionality.

1. **Analyze current highlighting usage** ✓
   - Review current settings for word highlighting
   - Document any custom configurations

2. **Add mini.cursorword to mini.lua** ✓
   - Extend mini.lua configuration with mini.cursorword
   - Configure highlighting styles to match existing plugin

3. **Configure appearance options** ✓
   - Set delay options
   - Set highlight styles
   - Customize exclusion patterns

4. **Test and refine highlighting** ✓
   - Verify highlighting works correctly
   - Adjust highlight style if needed

**Testing**: ✓
- Test word highlighting behavior
- Check delay/debounce functionality
- Test with various file types
- Verify exclusion patterns work correctly

**Commit**: "Add mini.cursorword replacing local-highlight" ✓

### ✅ Batch 5: Additional Mini Plugins

**Goal**: Add additional mini plugins that enhance the configuration.

1. **Add mini.ai (text objects)** ✓
   - Add mini.ai to mini.lua
   - Configure for various text objects
   - Set up key mappings
   - Test with various text objects

2. **Add mini.splitjoin** ✓
   - Add mini.splitjoin to mini.lua
   - Configure for different constructs
   - Set up key mappings
   - Test with various constructs

3. **Add mini.align** ✓
   - Add mini.align to mini.lua
   - Configure for different alignment types
   - Set up key mappings
   - Test with various alignment scenarios

4. **Add mini.diff** ✓
   - Add mini.diff to mini.lua (if needed)
   - Configure for inline diffs
   - Test with various diff scenarios

**Testing**: ✓
- Test each plugin individually
- Verify key mappings work correctly
- Test with various file types
- Ensure no conflicts with existing functionality

**Commit**: "Add additional mini plugins for enhanced functionality" ✓

### ✅ Batch 6: Todo-comments Integration

**Goal**: Add todo-comments.nvim for enhanced TODO highlighting and navigation.

1. **Create extras directory** ✓
   - Create `lua/neotex/plugins/extras/` directory
   - Create basic `init.lua` to load submodules

2. **Implement todo-comments** ✓
   - Create `lua/neotex/plugins/extras/todo-comments.lua`
   - Configure keywords, colors, and patterns
   - Set up Telescope integration

3. **Update bootstrap.lua** ✓
   - Uncomment the extras plugins import in bootstrap.lua
   - Test: Verify NeoVim starts without errors and plugin loads

4. **Configure keybindings** ✓
   - Set up key mappings for todo navigation
   - Add integration with existing keymapping structure

**Testing**: ✓
- Add various TODO comments and check highlighting
- Test searching for TODOs with Telescope
- Verify color coding works correctly
- Test with different comment styles

**Commit**: "Add todo-comments.nvim for enhanced TODO tracking" ✓

### ✅ Batch 7: Conform.nvim Integration

**Goal**: Add conform.nvim for improved code formatting.

1. **Create formatting module** ✓
   - Create `lua/neotex/plugins/extras/formatting.lua`
   - Configure basic plugin structure

2. **Configure formatters by filetype** ✓
   - Set up formatters for Lua
   - Set up formatters for Python
   - Set up formatters for web languages (JS, TS, etc.)
   - Set up formatters for other languages as needed

3. **Configure key mappings** ✓
   - Set up `<leader>mp` mapping for formatting
   - Add additional mappings as needed

4. **Add format-on-save functionality** ✓
   - Configure autocommands for format-on-save (optional)
   - Make it configurable per filetype

**Testing**: ✓
- Test formatting with each configured formatter
- Verify key mappings work correctly
- Test with various file types
- Ensure format-on-save works if enabled

**Commit**: "Add conform.nvim for code formatting" ✓

### ✅ Batch 8: Nvim-lint Integration

**Goal**: Add nvim-lint for improved code linting.

1. **Create linting module** ✓
   - Create `lua/neotex/plugins/extras/linting.lua`
   - Configure basic plugin structure

2. **Configure linters by filetype** ✓
   - Set up linters for Lua
   - Set up linters for Python
   - Set up linters for web languages (JS, TS, etc.)
   - Set up linters for other languages as needed

3. **Configure key mappings** ✓
   - Set up `<leader>l` mapping for linting
   - Add additional mappings as needed

4. **Add lint-on-save functionality** ✓
   - Configure autocommands for lint-on-save (optional)
   - Make it configurable per filetype

**Testing**: ✓
- Test linting with each configured linter
- Verify key mappings work correctly
- Test with various file types
- Ensure lint-on-save works if enabled

**Commit**: "Add nvim-lint for code linting" ✓

### Batch 9: Yanky.nvim Optimization

**Goal**: Optimize yanky.nvim for better performance and user experience.

1. **Analyze current yanky configuration**
   - Review current settings and usage patterns
   - Identify performance bottlenecks

2. **Update yanky configuration**
   - Create `lua/neotex/plugins/editor/yanky.lua`
   - Optimize settings for better performance
   - Add enhanced features if available

3. **Configure key mappings**
   - Review and optimize key mappings
   - Ensure consistency with overall keymap structure

4. **Add Telescope integration**
   - Enhance yank history with Telescope
   - Add key mappings for Telescope integration

**Testing**:
- Test yanking and pasting functionality
- Verify clipboard integration works correctly
- Test yank history navigation
- Measure performance improvements if possible

**Commit**: "Optimize yanky.nvim for better performance"

### Batch 10: Directory Structure Cleanup

**Goal**: Finalize directory structure and clean up old files.

1. **Move existing plugin files to categories**
   - Move remaining plugin files to appropriate category directories
   - Update imports and references

2. **Update bootstrap.lua**
   - Uncomment remaining category imports
   - Remove old import methods
   - Update initialization logic if needed

3. **Clean up configuration**
   - Remove or deprecate old plugin files
   - Ensure backward compatibility where needed
   - Update README and documentation

4. **Final testing**
   - Verify all functionality works correctly
   - Check for any errors or warnings
   - Ensure seamless user experience

**Testing**:
- Comprehensive testing of all changed functionality
- Check :checkhealth for any issues
- Test startup time and performance
- Verify all keymappings work correctly

**Commit**: "Complete Phase 2 implementation and directory structure"

## Testing Between Batches

After each batch, verify that:

1. NeoVim starts without errors
2. Core functionality works (editing, navigation, key mappings)
3. The specific plugin functionality works as expected
4. No regressions in other areas
5. Run `:checkhealth` to verify plugin health

## Rollback Plan

If issues occur:

1. Revert the problematic commit
2. If a specific file is causing problems, restore only that file
3. Document any issues encountered for future reference

## Final Verification

After completing all batches:

1. Restart NeoVim freshly to verify clean startup
2. Test all major functionality:
   - General editing and navigation
   - Plugin features (mini ecosystem, formatting, linting, etc.)
   - LSP functionality
   - Special features (Jupyter, LaTeX, etc.)
3. Check startup time (`nvim --startuptime startup.log`)
4. Review logs for any warnings or errors
5. Test on different file types (Lua, Python, Markdown, LaTeX)

Once everything is confirmed working correctly, you can proceed to Phase 3 of the refactoring process.