# Avante Codebase Cleanup Research Report

**Date**: 2025-12-09
**Topic**: Complete removal of Avante plugin integration from Neovim configuration
**Scope**: All Lua files, bash scripts, documentation, and configuration files

---

## Executive Summary

This report catalogs all Avante-related code, imports, function calls, configuration blocks, and documentation references across the entire codebase. The research identifies **4 primary Lua modules, 9 supporting files, extensive documentation references, and multiple integration points** that must be removed to complete the Avante cleanup.

**Impact Classification**:
- **Functional**: Core plugin files, require statements, API calls, keybindings
- **Configuration**: lazy-lock.json entries, init.lua autocmds, keymaps configuration
- **Documentation**: README files, user guides, command references

---

## Findings

### 1. Core Plugin Files (Complete Removal Required)

#### 1.1 Main Plugin Configuration
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante.lua`
- **Lines**: 1-707 (entire file)
- **Impact**: CRITICAL - Main Avante plugin specification
- **Dependencies**:
  - `yetone/avante.nvim` plugin
  - `require("neotex.plugins.ai.avante.mcp.avante-support")`
  - `require("neotex.plugins.ai.avante.mcp.avante-highlights")`
  - `require("neotex.plugins.ai.avante.mcp.avante_mcp")`
  - `require("avante")` (external plugin)
  - `require("avante.config")` (external plugin config)
- **Key Functions**:
  - `create_avante_command()` - Command wrapper factory
  - `opts()` - Configuration builder (lines 253-665)
  - `config()` - Setup function (lines 666-679)
- **Global Variables**:
  - `_G.avante_cycle_state` - Model/provider state tracking
  - `_G.avante_first_open` - First-open notification flag
  - `_G.set_avante_keymaps` - Keymap registration function
- **User Commands Created**:
  - `:AvanteAsk`
  - `:AvanteChat`
  - `:AvanteToggle`
  - `:AvanteEdit`
  - `:AvanteClear`
  - `:AvanteModel`
  - `:AvanteProvider`
  - `:AvanteStop`
- **Action**: Delete entire file

#### 1.2 Avante Support Module
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/mcp/avante-support.lua`
- **Impact**: HIGH - Central management and configuration
- **Provides**:
  - Model cycling functionality
  - Settings persistence (`~/.local/share/nvim/avante/settings.lua`)
  - Provider/model management
  - Notification system
  - Command registration (`:AvanteModel`, `:AvanteProvider`, etc.)
- **Action**: Delete entire file

#### 1.3 Avante MCP Integration
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/mcp/avante_mcp.lua`
- **Impact**: HIGH - MCPHub integration coordinator
- **Provides**:
  - MCPHub extension loading
  - System prompt enhancement
  - Tool registry integration
  - Commands: `:AvanteAskWithMCP`, `:AvanteChatWithMCP`, `:MCPAvante`
- **Action**: Delete entire file

#### 1.4 Avante Highlights Module
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/mcp/avante-highlights.lua`
- **Impact**: MEDIUM - UI highlighting
- **Provides**:
  - Visual highlighting for Avante UI
  - Highlight groups: `AvanteAddition`, `AvanteDeletion`, `AvanteModification`, etc.
  - Theme integration
- **Action**: Delete entire file

### 2. Supporting Files in Avante Directory

**Directory**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/`

All files must be removed:

1. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/README.md`
   - Documentation for Avante integration architecture

2. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/mcp/README.md`
   - MCP integration documentation

3. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/mcp/tool_registry.lua`
   - Tool registry management

4. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/mcp/system-prompts.json`
   - System prompt definitions

5. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/mcp/system-prompts.lua`
   - System prompt manager

6. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/mcp/mcp_server.lua`
   - MCP server lifecycle management

**Action**: Delete entire `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/` directory tree

### 3. Integration Points Requiring Code Removal

#### 3.1 Init.lua Integration
**File**: `/home/benjamin/.config/nvim/init.lua`

**Line 92**: Avante preload autocmd trigger
```lua
vim.api.nvim_exec_autocmds("User", { pattern = "AvantePreLoad" })
```
**Action**: Remove this line (it's in the `ensure_mcphub_loaded()` function)

#### 3.2 Keymaps Configuration
**File**: `/home/benjamin/.config/nvim/lua/neotex/config/keymaps.lua`

**Lines to Remove**:
- Line 18: Comment mentioning Avante
- Line 23: `<C-c>` override comment for Avante/Telescope
- Line 24: `<C-g>` Toggle Avante comment
- Lines 81-84: Avante AI buffer keybindings section header
- Lines 217-247: `set_avante_keymaps()` function definition
- Lines 295: Comment about Avante buffers
- Lines 313-317: Global Avante toggle keybindings

**Specific Code Blocks**:
```lua
-- Line 217-247: Complete function removal
function _G.set_avante_keymaps()
  local function avante_map(mode, key, cmd, description)
    -- ... entire function body
  end
end

-- Lines 313-317: Global keybindings removal
map("n", "<C-g>", "<cmd>AvanteToggle<CR>", {}, "Toggle Avante")
map("i", "<C-g>", "<cmd>AvanteToggle<CR>", {}, "Toggle Avante")
map("v", "<C-g>", "<cmd>AvanteToggle<CR>", {}, "Toggle Avante")
map("t", "<C-g>", "<cmd>AvanteToggle<CR>", {}, "Toggle Avante")
```

**Action**: Remove all Avante-related keybindings and comments

#### 3.3 MCP-Hub Plugin Configuration
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/mcp-hub.lua`

**Lines to Remove**:
- Line 10: "Clean Avante integration" comment
- Line 31: `event = { "User AvantePreLoad" }` - Avante event trigger
- Lines 53-61: Avante extension configuration block

**Specific Code Block**:
```lua
-- Lines 53-61: Remove Avante extension config
extensions = {
  avante = {
    make_slash_commands = true,
    auto_approve = true,
    make_vars = true,
    show_result_in_chat = true,
  }
},
```

**Action**: Remove Avante extension configuration and event trigger

#### 3.4 Lualine UI Configuration
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/lualine.lua`

**Lines to Remove**:
- Lines 38-41: Avante filetype patterns in disabled_filetypes
- Lines 44-47: Avante filetype patterns in ignore_focus

**Specific Code Blocks**:
```lua
-- Lines 38-47: Remove from disabled_filetypes and ignore_focus
"Avante",
"AvanteInput",
"AvanteAsk",
"AvanteEdit"
```

**Action**: Remove Avante filetypes from lualine configuration

### 4. Package Management

#### 4.1 Lazy.nvim Lock File
**File**: `/home/benjamin/.config/nvim/lazy-lock.json`

**Line 5**: Avante plugin lock entry
```json
"avante.nvim": { "branch": "main", "commit": "d3ec7c7320151244f07252a73628b1417f694b06" },
```

**Action**: Remove this entry (will be regenerated by lazy.nvim after plugin removal)

### 5. Test/Script Files

#### 5.1 Force MCP Restart Script
**File**: `/home/benjamin/.config/nvim/scripts/force_mcp_restart.lua`

**Lines with Avante References**:
- Line 2: Comment "MCP Hub and Avante are properly integrated"
- Line 4: Print statement including "Avante restart"
- Line 13: "Loading Avante extension" message
- Line 17: `mcphub.load_extension("avante")`
- Line 18: "Avante extension loaded" message
- Lines 22-47: Avante configuration reload logic

**Action**: Update script to remove Avante-specific functionality, or delete if primarily Avante-focused

#### 5.2 MCP Integration Test Script
**File**: `/home/benjamin/.config/nvim/scripts/test_mcp_integration.lua`

**Lines with Avante References**:
- Line 1: Comment "verify MCP integration with Avante"
- Lines 19-30: Avante extension test block
- Line 99: Comment about `:AvanteRestartMCP` command

**Action**: Update test script to remove Avante test cases

### 6. Documentation Files

#### 6.1 Root README
**File**: `/home/benjamin/.config/README.md`

**Lines to Remove**:
- Line 13: "**Avante** - AI-powered code completion..." feature description
- Line 17: Quick Access keybinding `<leader>aa` (Avante)
- Line 153: Comment "ai/ # AI integration (Avante, Claude Code, MCP)"
- Line 216: Keybinding table entry for Avante AI chat
- Lines 249-250: Avante session examples

#### 6.2 Neovim README
**File**: `/home/benjamin/.config/nvim/README.md`

**Major Sections to Remove**:
- Line 50: "AI Assistance" mention of Avante
- Line 119: AI Integration link mentioning Avante
- Lines 176-267: Complete "Using Avante AI" section including:
  - Provider setup
  - Keybindings
  - Configuration examples
  - Usage patterns
  - Special keybindings in Avante buffers
  - Configuration help examples
- Line 304: Comment about Avante AI integration

#### 6.3 Scripts README
**File**: `/home/benjamin/.config/nvim/scripts/README.md`

**Lines to Remove**:
- Line 27: "AI: Avante, MCP-Hub..." listing
- Line 45: "Forces complete restart of MCP Hub and Avante integration"
- Lines 52-76: Complete force_mcp_restart.lua documentation section
- Lines 104-125: test_mcp_integration.lua documentation with Avante tests
- Line 257: Reference to `avante_mcp.lua` usage

#### 6.4 Mappings Documentation
**File**: `/home/benjamin/.config/nvim/docs/MAPPINGS.md`

**Lines to Remove**:
- Line 134: "**Avante AI Commands**" header
- Lines 137-140: Avante keybinding table
- Line 395: `<C-a>` Ask Avante keybinding
- Lines 415-423: "Avante AI Buffers" section with complete keybinding table

#### 6.5 AI Tooling Documentation
**File**: `/home/benjamin/.config/nvim/docs/AI_TOOLING.md` (referenced in docs/README.md)

**Expected Content**: Likely contains Avante configuration and usage documentation
**Action**: Review and remove Avante sections

#### 6.6 AI Plugins README
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/README.md`

**Lines to Remove**:
- Lines 14-15: avante.lua module description
- Line 23: "MCP-Hub integration plugin... clean Avante integration..."
- Line 35: "Multiple AI providers - Claude, GPT, Gemini support through Avante"
- Lines 65, 84-85: Avante command examples and keybindings
- Line 119: Test individual plugins reference to avante

### 7. Comment and Inline Documentation References

#### 7.1 Scattered Code Comments

**Files with Avante comments**:
1. `/home/benjamin/.config/nvim/lua/neotex/config/keymaps.lua` - Multiple inline comments
2. `/home/benjamin/.config/nvim/scripts/force_mcp_restart.lua` - Integration comments
3. `/home/benjamin/.config/nvim/scripts/test_mcp_integration.lua` - Test comments
4. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/mcp-hub.lua` - Feature comments

**Action**: Review each file and remove all Avante-related comments

---

## Recommendations

### Removal Strategy

#### Phase 1: File Deletion (No Code Impact)
1. Delete entire `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/` directory
2. Delete `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante.lua`
3. Delete `/home/benjamin/.config/nvim/lazy-lock.json` (will regenerate)

#### Phase 2: Configuration Cleanup (Code Changes Required)
1. **keymaps.lua**:
   - Remove `set_avante_keymaps()` function (lines 217-247)
   - Remove global `<C-g>` keybindings (lines 313-317)
   - Remove all Avante-related comments

2. **init.lua**:
   - Remove `pattern = "AvantePreLoad"` autocmd trigger (line 92)

3. **mcp-hub.lua**:
   - Remove `event = { "User AvantePreLoad" }` (line 31)
   - Remove `extensions.avante` configuration block (lines 53-61)

4. **lualine.lua**:
   - Remove Avante filetypes from `disabled_filetypes` (lines 38-41)
   - Remove Avante filetypes from `ignore_focus` (lines 44-47)

#### Phase 3: Script/Test Updates
1. **force_mcp_restart.lua**:
   - Option A: Delete entire script if primarily Avante-focused
   - Option B: Remove Avante-specific code blocks (lines 13-47)

2. **test_mcp_integration.lua**:
   - Remove Avante extension tests (lines 19-30)
   - Update test comments

#### Phase 4: Documentation Cleanup
1. Update all README files to remove Avante references:
   - Root README.md
   - nvim/README.md
   - nvim/scripts/README.md
   - nvim/docs/MAPPINGS.md
   - nvim/lua/neotex/plugins/ai/README.md

2. Remove complete Avante sections from user guides

#### Phase 5: Verification
1. Run `:checkhealth` in Neovim to verify no broken dependencies
2. Test MCPHub functionality without Avante integration
3. Verify keybindings work correctly (especially `<C-g>` reassignment potential)
4. Confirm no lazy.nvim errors on startup
5. Search for remaining references: `rg -i "avante" nvim/`

### Risk Mitigation

**Potential Issues**:
1. **MCPHub Integration**: Removing Avante extension may affect MCPHub functionality
   - **Mitigation**: Test MCPHub commands after removal

2. **Keybinding Conflicts**: `<C-g>` will become available for reassignment
   - **Mitigation**: Document freed keybindings for future use

3. **Global State**: `_G.avante_*` variables may be referenced elsewhere
   - **Mitigation**: Search for `_G.avante` before committing changes

4. **User Muscle Memory**: Users accustomed to Avante keybindings
   - **Mitigation**: Document removed keybindings in changelog/migration guide

### Testing Checklist

- [ ] Neovim starts without errors
- [ ] No lazy.nvim plugin load failures
- [ ] MCPHub commands work (`:MCPHub`, `:MCPHubStatus`)
- [ ] No undefined function errors for removed Avante functions
- [ ] Lualine renders correctly
- [ ] Keymaps load without errors
- [ ] No references to `avante` in `rg -i "avante" nvim/` output
- [ ] Documentation builds/renders correctly
- [ ] All tests pass (if applicable)

### File Count Summary

**Deletions**:
- 4 core Lua modules (avante.lua + 3 in avante/mcp/)
- 5 supporting files (READMEs, JSON, registry)
- 1 directory tree (avante/)
- 1 lock file entry (regenerates automatically)

**Modifications**:
- 5 configuration files (keymaps, init, mcp-hub, lualine, lazy-lock)
- 2 script files (force_mcp_restart, test_mcp_integration)
- 6 documentation files (various READMEs and guides)

**Total Impact**: 11 file deletions, 13 file modifications

---

## Additional Notes

### Global Variables to Monitor

After removal, ensure these global variables are not referenced elsewhere:
- `_G.avante_cycle_state`
- `_G.avante_first_open`
- `_G.set_avante_keymaps`

### Commands to Verify Removal

```bash
# Search for remaining Avante references (case-insensitive)
rg -i "avante" nvim/

# Search for global Avante variables
rg "_G\.avante" nvim/

# Check for require statements
rg 'require.*avante' nvim/

# Verify file deletion
ls -la nvim/lua/neotex/plugins/ai/avante/

# Test Neovim startup
nvim --headless -c "checkhealth" -c "quit"
```

### Preserved Functionality

**What remains after Avante removal**:
- MCPHub core functionality (independent of Avante)
- Claude Code integration (separate AI tool)
- MCP server management
- Tool registry (if not Avante-specific)
- System prompt management (if not Avante-specific)

**What needs alternative solutions**:
- AI-powered code completion (consider Copilot, Codeium, or other alternatives)
- Inline suggestions (may need different plugin)
- Multi-provider AI support (Avante's unique feature)

---

## Conclusion

This research identifies a comprehensive list of Avante-related code spanning 4 core modules, 9 supporting files, and extensive integration points across configuration, keybindings, and documentation. The recommended phased approach ensures systematic removal while minimizing risk of breaking existing functionality.

**Next Steps**:
1. Review this report with project maintainers
2. Create backup/branch before starting removal
3. Execute Phase 1-5 removal strategy
4. Run verification testing checklist
5. Update project changelog with removed features
6. Consider migration guide for users dependent on Avante features
