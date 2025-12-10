# Implementation Plan: Complete Avante Plugin Removal

**Date**: 2025-12-09
**Feature**: Remove all traces of Avante plugin from Neovim configuration including code, documentation, and integration points
**Status**: [NOT STARTED]
**Estimated Hours**: 3-5 hours
**Standards File**: /home/benjamin/.config/CLAUDE.md
**Research Reports**:
- [Research Report: Avante Plugin Removal from Neovim Configuration](./../reports/001-avante-config-removal.md)
- [Avante Documentation Removal Research Report](./../reports/002-avante-docs-removal.md)
- [Avante Codebase Cleanup Research Report](./../reports/003-avante-codebase-cleanup.md)

---

## Overview

This plan executes the complete removal of the Avante AI plugin from the Neovim configuration, eliminating all code, configuration, documentation, and integration points. Research identified **25 files** containing Avante references across **6 major categories**: core plugin configuration, MCP integration layer, plugin loader/init system, global configuration, documentation, and deprecated files.

**Scope**:
- Delete 4 core Lua modules and entire `avante/` directory tree
- Remove integration points from 5 configuration files
- Update 2 utility scripts
- Clean up references in 15 documentation files
- Remove persistent data directory
- Verify no traces remain in codebase

**Key Risk Mitigation**:
- Phased removal with verification after each phase
- Preserve MCPHub functionality (independent of Avante)
- Test plugin loading and keybinding reassignment
- Create git branch for rollback capability

---

## Success Criteria

- [ ] All Avante plugin files deleted from `nvim/lua/neotex/plugins/ai/`
- [ ] Avante registration removed from plugin loader (`ai/init.lua`)
- [ ] All Avante-specific keybindings removed from `keymaps.lua`
- [ ] MCP-Hub Avante integration removed from `mcp-hub.lua`
- [ ] Lualine Avante filetype references removed
- [ ] Init.lua AvantePreLoad event trigger removed
- [ ] All Avante documentation sections removed from README files
- [ ] Scripts updated to remove Avante-specific functionality
- [ ] No `rg -i "avante"` matches found in codebase (excluding historical records)
- [ ] Neovim starts without errors after removal
- [ ] MCPHub functionality verified to work independently
- [ ] Lazy.nvim plugin sync completes successfully
- [ ] All freed keybindings documented

---

## Phase 1: Pre-Removal Preparation and Backup [NOT STARTED]

**Goal**: Create safety backups and document current state before making destructive changes.

**Tasks**:

### Task 1.1: Create Git Branch and Backup Points
**Description**: Establish rollback capability and backup critical configuration.

**Steps**:
1. Create dedicated branch for Avante removal:
   ```bash
   cd /home/benjamin/.config/nvim
   git checkout -b remove-avante-plugin
   git tag avante-pre-removal
   ```

2. Backup Avante user settings:
   ```bash
   mkdir -p /tmp/avante-backup
   cp -r ~/.local/share/nvim/avante/ /tmp/avante-backup/ 2>/dev/null || echo "No settings found"
   ```

3. Document current plugin state:
   ```bash
   cp lazy-lock.json /tmp/avante-backup/lazy-lock.json.backup
   ```

**Verification**:
- [ ] Branch `remove-avante-plugin` created
- [ ] Tag `avante-pre-removal` exists
- [ ] Backup directory `/tmp/avante-backup/` contains user settings (if any)
- [ ] Lock file backup created

**Estimated Time**: 15 minutes

---

### Task 1.2: Verify Dependency Usage
**Description**: Confirm which dependencies are Avante-exclusive and can be removed.

**Steps**:
1. Check dressing.nvim usage across plugins:
   ```bash
   rg "dressing" /home/benjamin/.config/nvim/lua/neotex/plugins/ --type lua
   ```

2. Check nui.nvim usage:
   ```bash
   rg "nui" /home/benjamin/.config/nvim/lua/neotex/plugins/ --type lua
   ```

3. Check img-clip.nvim usage:
   ```bash
   rg "img-clip" /home/benjamin/.config/nvim/lua/neotex/plugins/ --type lua
   ```

4. Document findings in removal notes:
   ```bash
   # Create findings file
   cat > /tmp/avante-backup/dependency-findings.txt << 'EOF'
   DEPENDENCY ANALYSIS:
   - dressing.nvim: [USED BY OTHER PLUGINS / AVANTE ONLY]
   - nui.nvim: [USED BY OTHER PLUGINS / AVANTE ONLY]
   - img-clip.nvim: [USED BY OTHER PLUGINS / AVANTE ONLY]
   EOF
   ```

**Verification**:
- [ ] Dependency usage documented
- [ ] Clear list of safe-to-remove vs. keep dependencies
- [ ] No shared dependencies will be broken

**Estimated Time**: 10 minutes

---

### Task 1.3: Document Current Keybindings
**Description**: Record all Avante keybindings for changelog and potential reassignment.

**Steps**:
1. Extract Avante keybindings from keymaps.lua:
   ```bash
   cat > /tmp/avante-backup/removed-keybindings.txt << 'EOF'
   REMOVED KEYBINDINGS:

   Global:
   - <C-g> (n/i/v/t modes): Toggle Avante

   Avante Buffers:
   - q: Close Avante
   - <C-c>: Clear chat history
   - <C-m>: Select model
   - <C-s>: Select provider
   - <C-x>: Stop generation
   - <CR>: Create new line override
   EOF
   ```

2. List all removed commands:
   ```bash
   cat >> /tmp/avante-backup/removed-keybindings.txt << 'EOF'

   REMOVED COMMANDS:
   - :AvanteAsk, :AvanteChat, :AvanteToggle, :AvanteEdit, :AvanteClear
   - :AvanteModel, :AvanteProvider, :AvanteStop
   - :AvanteSelectModel, :AvantePrompt, :AvantePromptManager, :AvantePromptEdit
   - :AvanteAskWithMCP, :AvanteChatWithMCP, :AvanteToggleWithMCP, :AvanteEditWithMCP
   - :MCPAvante, :AvanteRestartMCP, :MCPTest
   - :MCPToolsShow, :MCPPromptTest, :MCPSystemPromptTest, :MCPAvanteConfigTest
   - :MCPDebugToggle, :MCPForceReload, :MCPHubDiagnose
   EOF
   ```

**Verification**:
- [ ] All keybindings documented in backup file
- [ ] All commands listed for reference

**Estimated Time**: 10 minutes

---

## Phase 2: Core Plugin and Configuration Removal [NOT STARTED]

**Goal**: Delete main Avante plugin files and remove from plugin loader.

**Tasks**:

### Task 2.1: Remove Plugin Registration
**Description**: Remove Avante from plugin loader to prevent load attempts.

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/init.lua`

**Steps**:
1. Remove line 46: `"avante",` from `ai_plugins` array

**Verification**:
- [ ] `"avante",` entry removed from init.lua
- [ ] No syntax errors in init.lua
- [ ] File saved successfully

**Estimated Time**: 5 minutes

---

### Task 2.2: Delete Main Plugin Configuration
**Description**: Remove primary Avante plugin specification file.

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante.lua`

**Steps**:
1. Delete the file:
   ```bash
   rm /home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante.lua
   ```

**Verification**:
- [ ] File deleted successfully
- [ ] File no longer exists at path

**Estimated Time**: 2 minutes

---

### Task 2.3: Delete Avante Directory Tree
**Description**: Remove entire Avante integration directory with all MCP modules.

**Directory**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/`

**Steps**:
1. Delete directory recursively:
   ```bash
   rm -rf /home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/
   ```

2. Verify deletion:
   ```bash
   ls /home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/ 2>&1 | grep "No such file"
   ```

**Verification**:
- [ ] Directory deleted successfully
- [ ] No Avante directory exists
- [ ] All MCP integration modules removed

**Estimated Time**: 2 minutes

---

### Task 2.4: Remove Legacy System Prompts File
**Description**: Delete old system prompts location referenced as fallback.

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/util/system-prompts.json`

**Steps**:
1. Delete the file:
   ```bash
   rm /home/benjamin/.config/nvim/lua/neotex/plugins/ai/util/system-prompts.json
   ```

**Verification**:
- [ ] File deleted if it exists
- [ ] No errors if file already missing

**Estimated Time**: 2 minutes

---

## Phase 3: Global Configuration Cleanup [NOT STARTED]

**Goal**: Remove Avante integration points from global configuration files.

**Tasks**:

### Task 3.1: Remove Avante Keybindings
**Description**: Delete all Avante-related keybinding definitions and comments.

**File**: `/home/benjamin/.config/nvim/lua/neotex/config/keymaps.lua`

**Steps**:
1. Remove `set_avante_keymaps()` function (lines 217-247)
2. Remove global `<C-g>` keybindings (lines 313-317)
3. Remove/update comments mentioning Avante:
   - Line 18: Comment referencing Avante toggles
   - Line 23-24: Documentation for `<C-c>` and `<C-g>` Avante keybindings
   - Lines 81-84: "AVANTE AI BUFFER KEYBINDINGS" section header
   - Line 149: Comment about AI keybindings
   - Line 295: Comment about Avante buffer context

**Verification**:
- [ ] `set_avante_keymaps()` function removed
- [ ] Global `<C-g>` keybindings removed
- [ ] All Avante comments removed or updated
- [ ] File syntax valid (no Lua errors)
- [ ] `<C-g>` keybinding freed for future use

**Estimated Time**: 15 minutes

---

### Task 3.2: Remove Init.lua Integration
**Description**: Remove Avante preload event trigger from main init file.

**File**: `/home/benjamin/.config/nvim/init.lua`

**Steps**:
1. Remove line 92 (AvantePreLoad event trigger):
   ```lua
   vim.api.nvim_exec_autocmds("User", { pattern = "AvantePreLoad" })
   ```
   This line is inside the `_G.ensure_mcphub_loaded()` function (lines 90-124).

2. Review whether entire `ensure_mcphub_loaded()` function is needed:
   - If MCPHub needs independent lazy-loading: Keep function, remove only AvantePreLoad line
   - If function is Avante-specific: Remove entire function

**Verification**:
- [ ] AvantePreLoad event trigger removed
- [ ] MCPHub loading still works if needed independently
- [ ] No Lua syntax errors

**Estimated Time**: 10 minutes

---

### Task 3.3: Remove Avante Autocmd
**Description**: Delete Avante-specific FileType autocmd from autocmds configuration.

**File**: `/home/benjamin/.config/nvim/lua/neotex/config/autocmds.lua`

**Steps**:
1. Remove lines 23-27 (Avante markdown autocmd):
   ```lua
   -- FileType autocmd for */avante.nvim.md
   ```

**Verification**:
- [ ] Avante autocmd removed
- [ ] No syntax errors in autocmds.lua
- [ ] Other autocmds unaffected

**Estimated Time**: 5 minutes

---

### Task 3.4: Remove MCP-Hub Avante Integration
**Description**: Remove Avante extension configuration from MCP-Hub plugin.

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/mcp-hub.lua`

**Steps**:
1. Remove line 10: "Clean Avante integration" comment
2. Remove line 31: `event = { "User AvantePreLoad" }` event trigger
3. Remove lines 53-61: Avante extension configuration block:
   ```lua
   extensions = {
     avante = {
       make_slash_commands = true,
       auto_approve = true,
       make_vars = true,
       show_result_in_chat = true,
     }
   },
   ```

**Verification**:
- [ ] Avante extension config removed
- [ ] AvantePreLoad event removed
- [ ] MCPHub still loads correctly
- [ ] No Lua syntax errors

**Estimated Time**: 10 minutes

---

### Task 3.5: Remove Lualine Avante Filetypes
**Description**: Remove Avante filetypes from Lualine UI configuration.

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/lualine.lua`

**Steps**:
1. Remove Avante filetypes from `disabled_filetypes` (lines 38-41):
   - "Avante"
   - "AvanteInput"
   - "AvanteAsk"
   - "AvanteEdit"

2. Remove same filetypes from `ignore_focus` (lines 44-47)

**Verification**:
- [ ] Avante filetypes removed from disabled_filetypes
- [ ] Avante filetypes removed from ignore_focus
- [ ] Lualine configuration valid
- [ ] No syntax errors

**Estimated Time**: 5 minutes

---

### Task 3.6: Remove Lazy Lock File Entry
**Description**: Remove Avante plugin entry from Lazy.nvim lock file.

**File**: `/home/benjamin/.config/nvim/lazy-lock.json`

**Steps**:
1. Remove line 5:
   ```json
   "avante.nvim": { "branch": "main", "commit": "d3ec7c7320151244f07252a73628b1417f694b06" },
   ```

2. Alternative approach - delete lock file entirely (will regenerate):
   ```bash
   rm /home/benjamin/.config/nvim/lazy-lock.json
   ```

**Verification**:
- [ ] Avante entry removed from lock file OR lock file deleted
- [ ] Valid JSON syntax if modified (no trailing commas)

**Estimated Time**: 5 minutes

---

## Phase 4: Scripts and Utilities Cleanup [NOT STARTED]

**Goal**: Update or remove Avante-specific scripts and test utilities.

**Tasks**:

### Task 4.1: Remove Force MCP Restart Script
**Description**: Delete Avante-specific MCP restart script.

**File**: `/home/benjamin/.config/nvim/scripts/force_mcp_restart.lua`

**Steps**:
1. Determine if script is primarily Avante-focused or has other uses
2. If Avante-only: Delete entire file:
   ```bash
   rm /home/benjamin/.config/nvim/scripts/force_mcp_restart.lua
   ```
3. If has other uses: Remove Avante-specific sections (lines 13-47)

**Verification**:
- [ ] File deleted OR Avante sections removed
- [ ] No syntax errors if modified
- [ ] MCPHub restart functionality preserved if needed

**Estimated Time**: 10 minutes

---

### Task 4.2: Update MCP Integration Test Script
**Description**: Remove Avante test cases from MCP integration test suite.

**File**: `/home/benjamin/.config/nvim/scripts/test_mcp_integration.lua`

**Steps**:
1. Remove Avante extension test block (lines 19-30)
2. Remove comment about `:AvanteRestartMCP` command (line 99)
3. Update test script header comment to remove "Avante" reference (line 1)

**Verification**:
- [ ] Avante test cases removed
- [ ] Test script still valid for MCPHub testing
- [ ] No syntax errors

**Estimated Time**: 10 minutes

---

## Phase 5: Documentation Cleanup [NOT STARTED]

**Goal**: Remove all Avante references from user-facing and technical documentation.

**Tasks**:

### Task 5.1: Update Root README
**Description**: Remove Avante from main configuration README.

**File**: `/home/benjamin/.config/README.md`

**Steps**:
1. Remove line 13: "**Avante** - AI-powered code completion..." from core features
2. Remove line 17: `<leader>aa` (Avante) from quick access keybindings
3. Update line 153: Remove Avante from directory structure comment
4. Remove line 216: Avante keybinding from essential keybindings table
5. Update lines 249-250: Remove Avante session examples

**Verification**:
- [ ] All Avante references removed
- [ ] AI integration section focuses on Claude Code and Lectic
- [ ] Markdown syntax valid
- [ ] Links still work

**Estimated Time**: 15 minutes

---

### Task 5.2: Update Neovim Main README
**Description**: Remove extensive Avante documentation from Neovim README.

**File**: `/home/benjamin/.config/nvim/README.md`

**Steps**:
1. Update line 50: Remove Avante from "AI Assistance" feature description
2. Update line 119: Update AI Integration navigation link
3. Remove lines 176-267: Complete "Using Avante AI" section including:
   - Overview and provider information
   - Usage examples
   - Special keybindings table
   - Configuration help section
   - Troubleshooting guidance
4. Remove line 304: Avante keybinding quick reference

**Verification**:
- [ ] "Using Avante AI" section removed
- [ ] AI integration section rewritten to focus on Claude Code/Lectic
- [ ] Navigation links updated
- [ ] Markdown valid

**Estimated Time**: 20 minutes

---

### Task 5.3: Update Scripts README
**Description**: Remove Avante-specific script documentation.

**File**: `/home/benjamin/.config/nvim/scripts/README.md`

**Steps**:
1. Update line 27: Remove Avante from AI tools list
2. Remove lines 45-125: force_mcp_restart.lua and test_mcp_integration.lua sections documenting Avante integration
3. Update line 257: Remove avante_mcp.lua reference
4. Update line 274: Remove Avante from prerequisites

**Verification**:
- [ ] Avante script documentation removed
- [ ] MCP-Hub documentation preserved
- [ ] Markdown syntax valid

**Estimated Time**: 15 minutes

---

### Task 5.4: Update Mappings Documentation
**Description**: Remove Avante keybinding documentation.

**File**: `/home/benjamin/.config/nvim/docs/MAPPINGS.md`

**Steps**:
1. Remove lines 134-140: "Avante AI Commands" section with keybinding table
2. Update line 395: Remove `<C-a>` Ask Avante reference in toggleterm context
3. Remove lines 415-423: "Avante AI Buffers" section with buffer-local keybindings

**Verification**:
- [ ] Avante keybinding sections removed
- [ ] Other AI tool keybindings preserved
- [ ] Table syntax valid

**Estimated Time**: 10 minutes

---

### Task 5.5: Update AI Plugins README
**Description**: Remove Avante module documentation from AI plugins directory.

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/README.md`

**Steps**:
1. Remove lines 14-15: avante.lua module description
2. Update line 23: Rewrite MCP-Hub integration description to remove Avante
3. Update line 35: Remove Avante from AI providers description
4. Remove line 65: :AvanteAsk command example
5. Remove lines 84-85: Avante keybindings
6. Update lines 119, 124: Remove Avante from testing instructions

**Verification**:
- [ ] Avante module documentation removed
- [ ] AI integration section rewritten
- [ ] Other plugins documented correctly

**Estimated Time**: 15 minutes

---

### Task 5.6: Update Documentation Standards
**Description**: Replace Avante examples in documentation standards.

**File**: `/home/benjamin/.config/nvim/docs/DOCUMENTATION_STANDARDS.md`

**Steps**:
1. Replace lines 159, 164: Update example sentences to use different plugin
2. Update line 219: Replace Avante keybinding example
3. Replace lines 239-257: Replace complete Avante plugin documentation example with Claude Code or another plugin

**Verification**:
- [ ] All Avante examples replaced with appropriate alternatives
- [ ] Documentation standards still clear and helpful
- [ ] Examples use current plugins

**Estimated Time**: 15 minutes

---

### Task 5.7: Update Architecture Documentation
**Description**: Remove Avante from system architecture documentation.

**File**: `/home/benjamin/.config/nvim/docs/ARCHITECTURE.md`

**Steps**:
1. Update line 22: Remove Avante from AI integration layer description
2. Remove lines 86, 153: Remove AvantePreLoad event references
3. Update line 105: Remove avante.lua from plugin structure
4. Update line 225: Remove Claude Code / Avante comparison, focus only on Claude Code
5. Update lines 301, 303: Update plugin dependency graph

**Verification**:
- [ ] Avante removed from architecture diagrams
- [ ] System architecture accurately reflects current state
- [ ] Plugin dependencies correct

**Estimated Time**: 15 minutes

---

### Task 5.8: Update Advanced Setup Guide
**Description**: Remove Avante configuration section.

**File**: `/home/benjamin/.config/nvim/docs/ADVANCED_SETUP.md`

**Steps**:
1. Remove line 200: Avante AI configuration section

**Verification**:
- [ ] Avante configuration section removed
- [ ] Other setup instructions intact

**Estimated Time**: 5 minutes

---

### Task 5.9: Update Plugin Organization README
**Description**: Remove Avante from plugin overview documentation.

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/README.md`

**Steps**:
1. Update line 33: Remove avante.lua from file structure
2. Update line 76: Remove Avante from AI assistants integration description

**Verification**:
- [ ] Avante removed from file structure listing
- [ ] AI integration description updated

**Estimated Time**: 5 minutes

---

### Task 5.10: Delete Migration Guide
**Description**: Remove obsolete Avante migration documentation.

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/MIGRATION.md`

**Steps**:
1. Delete entire file:
   ```bash
   rm /home/benjamin/.config/nvim/lua/neotex/plugins/ai/MIGRATION.md
   ```

**Verification**:
- [ ] File deleted successfully
- [ ] No references to migration guide in other docs

**Estimated Time**: 2 minutes

---

### Task 5.11: Update Deprecated Implementation Summary
**Description**: Remove Avante reference from deprecated documentation.

**File**: `/home/benjamin/.config/nvim/deprecated/task-delegation/IMPLEMENTATION_SUMMARY.md`

**Steps**:
1. Remove line 151: `avante_plugin,` reference

**Verification**:
- [ ] Reference removed
- [ ] Document still readable

**Estimated Time**: 2 minutes

---

## Phase 6: Persistent Data Cleanup [NOT STARTED]

**Goal**: Remove Avante user data and persistent storage.

**Tasks**:

### Task 6.1: Remove Avante Data Directory
**Description**: Delete Avante settings and persistent data.

**Directory**: `~/.local/share/nvim/avante/`

**Steps**:
1. Remove data directory:
   ```bash
   rm -rf ~/.local/share/nvim/avante/
   ```

**Verification**:
- [ ] Directory deleted successfully
- [ ] No Avante data remains in `~/.local/share/nvim/`

**Estimated Time**: 2 minutes

---

## Phase 7: Verification and Testing [NOT STARTED]

**Goal**: Ensure complete removal and verify no broken functionality.

**Tasks**:

### Task 7.1: Search for Remaining References
**Description**: Comprehensive search for any missed Avante references.

**Steps**:
1. Search for "avante" (case-insensitive):
   ```bash
   rg -i "avante" /home/benjamin/.config/nvim/ --type lua --type md --type json
   ```

2. Search for global Avante variables:
   ```bash
   rg "_G\.avante" /home/benjamin/.config/nvim/
   ```

3. Search for require statements:
   ```bash
   rg 'require.*avante' /home/benjamin/.config/nvim/
   ```

4. Document any findings and determine if they should be removed

**Verification**:
- [ ] No Avante references found in active code
- [ ] Any historical references (e.g., in `.claude/specs/`) are intentional
- [ ] No require statements for Avante modules

**Estimated Time**: 10 minutes

---

### Task 7.2: Test Neovim Startup
**Description**: Verify Neovim starts without errors after removal.

**Steps**:
1. Start Neovim in headless mode:
   ```bash
   nvim --headless -c "checkhealth" -c "quit"
   ```

2. Check for Lazy.nvim errors:
   ```bash
   nvim --headless "+Lazy! sync" +qa
   ```

3. Start Neovim normally and verify:
   - No error messages on startup
   - Plugin loading completes
   - No missing module errors

**Verification**:
- [ ] Neovim starts without errors
- [ ] No Avante-related error messages
- [ ] Lazy.nvim sync completes successfully
- [ ] No missing require() errors

**Estimated Time**: 10 minutes

---

### Task 7.3: Verify MCPHub Independence
**Description**: Confirm MCPHub functionality works without Avante.

**Steps**:
1. Start Neovim and test MCPHub commands:
   - `:MCPHub` (if command exists)
   - `:MCPHubStatus` (if command exists)
   - Verify MCP server starts correctly

2. Check MCPHub integration:
   - Verify no Avante extension loading errors
   - Confirm tools registry works independently

**Verification**:
- [ ] MCPHub commands work correctly
- [ ] No Avante extension errors
- [ ] MCP server functionality intact

**Estimated Time**: 10 minutes

---

### Task 7.4: Test Keybinding Configuration
**Description**: Verify keybindings load correctly and `<C-g>` is freed.

**Steps**:
1. Start Neovim and check for keybinding errors
2. Verify `<C-g>` is no longer mapped to Avante:
   ```vim
   :verbose map <C-g>
   ```
3. Test other AI tool keybindings remain functional

**Verification**:
- [ ] Keymaps load without errors
- [ ] `<C-g>` is unmapped or available for reassignment
- [ ] Other AI keybindings work correctly

**Estimated Time**: 5 minutes

---

### Task 7.5: Test Lualine UI
**Description**: Verify Lualine renders correctly without Avante filetypes.

**Steps**:
1. Open various file types
2. Verify statusline renders correctly
3. Check for any Lualine errors in `:messages`

**Verification**:
- [ ] Lualine renders correctly
- [ ] No errors about Avante filetypes
- [ ] Statusline functional across all file types

**Estimated Time**: 5 minutes

---

### Task 7.6: Verify Documentation Coherence
**Description**: Ensure all documentation is coherent and links are valid.

**Steps**:
1. Review updated README files:
   - AI integration sections make sense without Avante
   - Keybinding tables are complete
   - No broken references

2. Check internal links:
   - Navigation links work
   - Cross-references valid

3. Verify AI tooling documentation describes remaining tools clearly

**Verification**:
- [ ] All documentation coherent and complete
- [ ] No broken links or references
- [ ] AI integration documented accurately
- [ ] Alternative tools (Claude Code, Lectic) properly highlighted

**Estimated Time**: 15 minutes

---

### Task 7.7: Run Lua Syntax Check
**Description**: Verify no Lua syntax errors in modified files.

**Steps**:
1. Run luacheck if available:
   ```bash
   luacheck /home/benjamin/.config/nvim/lua/ --no-unused --no-redefined
   ```

2. Manually check modified files for syntax issues if luacheck unavailable

**Verification**:
- [ ] No Lua syntax errors
- [ ] All modified files parse correctly
- [ ] No undefined variable references

**Estimated Time**: 5 minutes

---

## Phase 8: Post-Removal Finalization [NOT STARTED]

**Goal**: Commit changes and document removal for future reference.

**Tasks**:

### Task 8.1: Document Freed Keybindings
**Description**: Create record of available keybindings for future reassignment.

**Steps**:
1. Create keybinding reassignment document:
   ```bash
   cat > /home/benjamin/.config/nvim/docs/FREED_KEYBINDINGS.md << 'EOF'
   # Freed Keybindings After Avante Removal

   ## Global Keybindings Available for Reassignment

   - `<C-g>` (all modes: n/i/v/t) - Previously: Toggle Avante

   ## Buffer-Local Patterns Available

   The following patterns are now available for AI buffer interactions:
   - `q` - Close/quit pattern
   - `<C-c>` - Clear/cancel pattern
   - `<C-m>` - Model selection pattern
   - `<C-s>` - Settings/provider pattern
   - `<C-x>` - Stop/cancel pattern

   ## Removed Commands

   All Avante commands have been removed. Consider these alternatives:
   - Claude Code commands for AI assistance
   - Lectic commands for markdown AI
   - MCP-Hub commands for extended capabilities
   EOF
   ```

**Verification**:
- [ ] Keybinding document created
- [ ] Available keybindings clearly listed
- [ ] Alternative tools documented

**Estimated Time**: 10 minutes

---

### Task 8.2: Create Changelog Entry
**Description**: Document removal for project history.

**Steps**:
1. Add changelog entry (create CHANGELOG.md if doesn't exist):
   ```markdown
   ## [Unreleased] - 2025-12-09

   ### Removed
   - **BREAKING**: Removed Avante AI plugin and all integrations
     - Deleted core plugin files (`avante.lua`, `avante/` directory)
     - Removed all Avante keybindings (global `<C-g>` now available)
     - Removed 25+ Avante-specific commands
     - Removed MCP-Hub Avante extension integration
     - Cleaned up documentation (15 files updated)
     - Deleted persistent data directory
     - Reason: Consolidating AI tooling to Claude Code and Lectic

   ### Migration Notes
   - Users should use Claude Code for AI-assisted development
   - Markdown AI assistance now via Lectic
   - MCP-Hub remains functional for extended capabilities
   - See `/docs/FREED_KEYBINDINGS.md` for available keybindings
   ```

**Verification**:
- [ ] Changelog entry created
- [ ] Removal documented with rationale
- [ ] Migration guidance provided

**Estimated Time**: 10 minutes

---

### Task 8.3: Commit Changes
**Description**: Create atomic commit with all Avante removal changes.

**Steps**:
1. Stage all changes:
   ```bash
   cd /home/benjamin/.config/nvim
   git add -A
   ```

2. Create comprehensive commit:
   ```bash
   git commit -m "Remove Avante plugin and all integrations

   BREAKING CHANGE: Complete removal of Avante AI plugin

   Removed:
   - Core plugin files (avante.lua, avante/ directory tree)
   - Plugin loader registration
   - All keybindings (global <C-g> now available)
   - 25+ Avante commands
   - MCP-Hub Avante extension integration
   - Lualine Avante filetype handling
   - Persistent data directory
   - Documentation across 15 files
   - Test/utility scripts

   Migration:
   - Use Claude Code for AI development assistance
   - Use Lectic for markdown AI
   - MCP-Hub remains independent
   - See docs/FREED_KEYBINDINGS.md for keybinding reassignment

   Research: See .claude/specs/058_remove_avante_nvim_config/reports/
   Plan: .claude/specs/058_remove_avante_nvim_config/plans/001-remove-avante-nvim-config-plan.md"
   ```

3. Create tag for this removal:
   ```bash
   git tag avante-removed
   ```

**Verification**:
- [ ] All changes committed
- [ ] Commit message comprehensive
- [ ] Tag created for reference

**Estimated Time**: 5 minutes

---

### Task 8.4: Final Verification Checklist
**Description**: Complete final checklist ensuring all removal criteria met.

**Steps**:
1. Run through verification checklist:
   - [ ] No `rg -i "avante"` matches in active code
   - [ ] Neovim starts without errors
   - [ ] Lazy.nvim sync successful
   - [ ] MCPHub works independently
   - [ ] Keybindings load correctly
   - [ ] Lualine renders properly
   - [ ] Documentation coherent
   - [ ] All freed keybindings documented
   - [ ] Changelog updated
   - [ ] Changes committed

2. Test one final Neovim session:
   - Open various file types
   - Use remaining AI tools (Claude Code, Lectic)
   - Verify no Avante-related errors
   - Confirm workflow remains productive

**Verification**:
- [ ] All verification criteria passed
- [ ] Final test session successful
- [ ] Ready to merge branch (if applicable)

**Estimated Time**: 10 minutes

---

## Phase Dependencies

- **Phase 2** depends on **Phase 1** (backup before deletion)
- **Phase 3** depends on **Phase 2** (plugin files deleted before config cleanup)
- **Phase 4** depends on **Phase 3** (config cleaned before scripts)
- **Phase 5** can run in parallel with **Phase 4** (documentation independent)
- **Phase 6** can run after **Phase 2** (data cleanup after plugin removal)
- **Phase 7** depends on **Phases 2-6** (verification after all changes)
- **Phase 8** depends on **Phase 7** (finalization after verification)

---

## Risk Assessment

### High Risk Areas
- **Plugin Loader Modification**: Breaking init.lua or ai/init.lua could prevent Neovim startup
  - Mitigation: Git branch with rollback capability, test after each change
- **MCPHub Integration**: Removing Avante extension could affect MCPHub functionality
  - Mitigation: Verify MCPHub independence, test commands after removal
- **Keybinding Conflicts**: Removing keymaps could break workflow
  - Mitigation: Document all removed keybindings, test keymaps thoroughly

### Medium Risk Areas
- **Documentation Coherence**: Removing sections could leave broken references
  - Mitigation: Review all updated docs, validate links
- **Lock File Management**: Improper lazy-lock.json modification could break plugin sync
  - Mitigation: Delete and regenerate if uncertain about JSON syntax

### Low Risk Areas
- **Script Removal**: Test scripts are not critical to core functionality
  - Mitigation: Keep backups, can restore if needed
- **Deprecated Files**: Already marked deprecated, safe to remove
  - Mitigation: None needed

---

## Rollback Procedure

If issues arise during removal:

1. **Immediate Rollback**:
   ```bash
   cd /home/benjamin/.config/nvim
   git checkout avante-pre-removal
   git checkout master  # or main branch
   git branch -D remove-avante-plugin
   ```

2. **Partial Rollback** (specific file):
   ```bash
   git checkout avante-pre-removal -- path/to/file
   ```

3. **Restore User Data**:
   ```bash
   cp -r /tmp/avante-backup/avante/ ~/.local/share/nvim/
   ```

4. **Regenerate Lock File**:
   ```bash
   cp /tmp/avante-backup/lazy-lock.json.backup lazy-lock.json
   nvim --headless "+Lazy! restore" +qa
   ```

---

## Post-Implementation Notes

### Alternative AI Tools After Removal

**Claude Code**:
- AI-assisted development
- Code completion and refactoring
- Multi-session parallel development

**Lectic**:
- Markdown AI assistance
- Documentation generation

**MCP-Hub**:
- Extended AI capabilities via MCP protocol
- Tool integration independent of Avante

### Keybinding Reassignment Opportunities

The freed `<C-g>` keybinding (all modes) is ideal for:
- Quick access to frequently used tools
- Toggle functionality for commonly used features
- Alternative AI tool integration

### Estimated Time Summary

- Phase 1: 35 minutes (preparation)
- Phase 2: 11 minutes (core removal)
- Phase 3: 50 minutes (config cleanup)
- Phase 4: 20 minutes (scripts)
- Phase 5: 112 minutes (documentation)
- Phase 6: 2 minutes (data cleanup)
- Phase 7: 60 minutes (verification)
- Phase 8: 35 minutes (finalization)

**Total Estimated Time**: 5 hours 25 minutes

Actual time may vary based on:
- Complexity of documentation rewrites
- Thoroughness of verification testing
- Need for adjustments during implementation
