# Research Report: Avante Plugin Removal from Neovim Configuration

**Date**: 2025-12-09
**Topic**: Complete enumeration of Avante plugin references for clean removal
**Scope**: Neovim configuration directory (`/home/benjamin/.config/nvim`)
**Research Method**: Comprehensive grep search, file analysis, and dependency mapping

---

## Executive Summary

This report documents all Avante plugin references discovered across the Neovim configuration. The plugin has deep integration with MCP-Hub, custom keybindings, commands, and extensive support infrastructure. A total of **25 files** contain Avante references across **6 major categories**:

1. **Core Plugin Configuration** (1 file)
2. **MCP Integration Layer** (6 files)
3. **Plugin Loader/Init System** (2 files)
4. **Global Configuration** (3 files)
5. **Documentation** (12 files)
6. **Deprecated/Archive** (1 file)

---

## Findings

### Category 1: Core Plugin Configuration

**Priority: CRITICAL** - These files define the main Avante plugin specification and must be removed first.

#### 1.1 Main Plugin Specification
- **File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante.lua`
- **Lines**: 707 total (entire file)
- **Type**: Primary plugin configuration
- **Content Summary**:
  - Lazy.nvim plugin specification for `yetone/avante.nvim`
  - Provider configurations (Claude, OpenAI, Gemini)
  - MCP-Hub integration setup
  - Custom tools configuration
  - System prompt management (dynamic function-based)
  - Extensive autocmd setup for integration
  - Dependencies: dressing.nvim, plenary.nvim, nui.nvim, img-clip.nvim
  - Build command: `make`
  - Event: `VeryLazy`
  - Version check: Neovim 0.10.1+

**Key Integration Points**:
- References `neotex.plugins.ai.avante.mcp.avante-highlights` (line 37)
- References `neotex.plugins.ai.avante.mcp.avante_mcp` (line 51)
- References `neotex.plugins.ai.avante.mcp.avante-support` (lines 115, 225, 255, 605)
- Creates commands: AvanteAsk, AvanteChat, AvanteToggle, AvanteEdit (lines 57-60)
- FileType autocmd for `Avante` and `AvanteInput` (lines 63, 228)
- LazyDone autocmd (line 128)
- VimEnter autocmd (line 177)

---

### Category 2: MCP Integration Layer

**Priority: CRITICAL** - Support modules that provide Avante-specific functionality.

#### 2.1 MCP Integration Coordinator
- **File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/mcp/avante_mcp.lua`
- **Lines**: 417 total (entire file)
- **Type**: MCP-Hub integration utilities
- **Functions**:
  - `with_mcp()` - Ensures MCPHub availability before running Avante
  - `register_commands()` - Creates AvanteXXXWithMCP command variants
  - `setup_autocmds()` - FileType autocmd for Avante buffers
  - `generate_enhanced_prompt()` - Dynamic system prompt generation
  - `open_mcphub()` - Direct MCPHub interface opener
- **Commands Created**:
  - AvanteAskWithMCP, AvanteChatWithMCP, AvanteToggleWithMCP, AvanteEditWithMCP
  - MCPAvante, MCPHubOpen, AvanteRestartMCP, MCPTest
  - MCPToolsShow, MCPPromptTest, MCPSystemPromptTest, MCPAvanteConfigTest
  - MCPDebugToggle, MCPForceReload, MCPHubDiagnose

**Dependencies**:
- Requires `neotex.plugins.ai.avante.mcp.mcp_server`
- Requires `neotex.plugins.ai.avante.mcp.tool_registry`

#### 2.2 Avante Support Module
- **File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/mcp/avante-support.lua`
- **Lines**: 561 total (entire file)
- **Type**: Model/provider management and persistence
- **Functions**:
  - `get_provider_models()` - Provider model definitions
  - `load_settings()` / `save_settings()` - Persistent settings storage
  - `apply_settings()` - Runtime configuration updates
  - `init()` - Startup initialization
  - `model_select()` - Interactive model selector
  - `provider_select()` - Interactive provider selector
  - `stop_generation()` - Cancel inflight requests
  - `setup_commands()` - Register user commands
  - `show_model_notification()` - First-open notification
- **Commands Created**:
  - AvanteModel, AvanteProvider, AvanteStop
  - AvantePrompt, AvantePromptManager, AvantePromptEdit
  - AvanteSelectModel
- **Settings File**: `~/.local/share/nvim/avante/settings.lua` (persistent storage)

**Provider Models Defined**:
- Claude: claude-3-5-sonnet-20241022, claude-3-7-sonnet-20250219, claude-4-sonnet-20250514, claude-3-opus-20240229
- OpenAI: gpt-4o, gpt-4-turbo, gpt-4, gpt-3.5-turbo
- Gemini: gemini-2.5-pro-preview-03-25, gemini-2.0-flash

#### 2.3 Avante Highlights
- **File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/mcp/avante-highlights.lua`
- **Lines**: 194 total (entire file)
- **Type**: Theme-aware visual indicators
- **Highlight Groups Created**:
  - AvanteAddition, AvanteDeletion, AvanteModification
  - AvanteCursorLine
  - AvanteGutterAdd, AvanteGutterDelete, AvanteGutterChange
  - AvanteSuggestion, AvanteSuggestionActive
  - AvanteSuccess, AvanteError
- **Sign Definitions**:
  - AvanteAddSign, AvanteDelSign, AvanteChangeSign
- **Autocmds**:
  - FileType autocmd for Avante/AvanteInput
  - ColorScheme autocmd for theme updates

#### 2.4 System Prompts Module
- **File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/mcp/system-prompts.lua`
- **Lines**: Exists (not read in detail)
- **Type**: System prompt management
- **Referenced By**: avante-support.lua (lines 418, 428, 438, 485)

#### 2.5 System Prompts Data
- **File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/mcp/system-prompts.json`
- **Lines**: Exists (JSON data file)
- **Type**: System prompt definitions storage

#### 2.6 Tool Registry
- **File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/mcp/tool_registry.lua`
- **Lines**: Exists (not read in detail)
- **Type**: MCP tool registration and context-aware selection
- **Referenced By**: avante_mcp.lua (line 4)

#### 2.7 MCP Server Module
- **File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/mcp/mcp_server.lua`
- **Lines**: Exists (not read in detail)
- **Type**: MCP server state management
- **Referenced By**: avante_mcp.lua (line 3)

#### 2.8 MCP Integration README
- **File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/mcp/README.md`
- **Lines**: Exists (documentation)
- **Type**: MCP integration documentation

#### 2.9 Avante Directory README
- **File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante/README.md`
- **Lines**: Exists (documentation)
- **Type**: Avante plugin overview documentation

---

### Category 3: Plugin Loader/Init System

**Priority: CRITICAL** - Files that register Avante in the plugin loading system.

#### 3.1 AI Plugins Init
- **File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/init.lua`
- **Line 46**: `"avante",` in `ai_plugins` array
- **Type**: Plugin loader registration
- **Impact**: Tells init system to load `neotex.plugins.ai.avante` module

#### 3.2 Main Init File
- **File**: `/home/benjamin/.config/nvim/init.lua`
- **Line 92**: `vim.api.nvim_exec_autocmds("User", { pattern = "AvantePreLoad" })`
- **Lines 90-124**: `_G.ensure_mcphub_loaded()` function definition
- **Type**: Global MCPHub integration for Avante
- **Impact**: AvantePreLoad event triggers MCPHub lazy-loading

---

### Category 4: Global Configuration

**Priority: IMPORTANT** - Configuration files that reference Avante keybindings and behavior.

#### 4.1 Keymaps Configuration
- **File**: `/home/benjamin/.config/nvim/lua/neotex/config/keymaps.lua`
- **References**: 28 matches
- **Lines**:
  - 18: Comment referencing Avante toggles
  - 23-24: Documentation for `<C-c>` and `<C-g>` Avante keybindings
  - 81-84: AVANTE AI BUFFER KEYBINDINGS documentation section
  - 149: Comment about AI keybindings
  - 217-244: `_G.set_avante_keymaps()` function definition
  - 295: Comment about Avante buffer context
  - 313-317: Global Avante toggle keybindings (`<C-g>` in n/i/v/t modes)

**Keybindings to Remove**:
- Global: `<C-g>` - Toggle Avante (all modes)
- Avante buffers: `q` - Close Avante
- Avante buffers: `<C-c>` - Clear chat history
- Avante buffers: `<C-m>` - Select model
- Avante buffers: `<C-s>` - Select provider
- Avante buffers: `<C-x>` - Stop generation
- Avante buffers: `<CR>` - Create new line override

#### 4.2 Autocmds Configuration
- **File**: `/home/benjamin/.config/nvim/lua/neotex/config/autocmds.lua`
- **Lines 23-27**: FileType autocmd for Avante help markdown file
- **Pattern**: `*/avante.nvim.md`
- **Type**: Special markdown handling for Avante documentation

#### 4.3 Lazy-lock.json
- **File**: `/home/benjamin/.config/nvim/lazy-lock.json`
- **Line 5**: `"avante.nvim": { "branch": "main", "commit": "d3ec7c7320151244f07252a73628b1417f694b06" }`
- **Type**: Lazy.nvim plugin lock file
- **Impact**: Pins Avante plugin version

---

### Category 5: Documentation

**Priority: OPTIONAL** - Documentation files referencing Avante features and usage.

#### 5.1 Main README
- **File**: `/home/benjamin/.config/nvim/README.md`
- **References**: 32 matches (lines 50, 119, 176-267, 304)
- **Sections**:
  - Line 50: Feature list - "AI Assistance: AI integration for code completion and editing suggestions with Avante..."
  - Line 119: AI Integration navigation link
  - Lines 176-267: Complete "Using Avante AI" section with:
    - Overview and provider information
    - Usage examples
    - Special keybindings table
    - Configuration help section
    - Troubleshooting guidance
  - Line 304: Quick access reference to Avante keybindings

#### 5.2 Scripts README
- **File**: `/home/benjamin/.config/nvim/scripts/README.md`
- **References**: 20 matches (lines 27, 45-125, 257, 274)
- **Sections**:
  - Line 27: AI tools list
  - Lines 45-125: Complete force_mcp_restart.lua section documenting Avante MCP integration restart
  - Lines 104-125: test_mcp_integration.lua section documenting Avante integration testing
  - Line 257: Related files reference
  - Line 274: Prerequisites mentioning Avante configuration

#### 5.3 Documentation Standards
- **File**: `/home/benjamin/.config/nvim/docs/DOCUMENTATION_STANDARDS.md`
- **References**: 9 matches (lines 159, 164, 219, 239, 249, 257)
- **Content**:
  - Lines 159, 164: Examples using Avante in documentation patterns
  - Line 219: Keybinding table example with Avante
  - Lines 239-257: Complete plugin documentation example for Avante

#### 5.4 Mappings Documentation
- **File**: `/home/benjamin/.config/nvim/docs/MAPPINGS.md`
- **References**: 14 matches (lines 134-140, 395, 415-423)
- **Sections**:
  - Lines 134-140: Avante AI Commands keybinding table
  - Line 395: `<C-a>` Ask Avante in toggleterm context
  - Lines 415-423: Complete "Avante AI Buffers" section with buffer-local keybindings

#### 5.5 Scripts (Lua)
- **File**: `/home/benjamin/.config/nvim/scripts/force_mcp_restart.lua`
- **Lines**: 2, 4, 13, 17, 18, 22, 24, 26, 29, 42-45
- **Type**: MCP/Avante restart script
- **Content**: Script to force restart MCP Hub and reload Avante configuration

#### 5.6 Scripts (Test Integration)
- **File**: `/home/benjamin/.config/nvim/scripts/test_mcp_integration.lua`
- **Lines**: Multiple (19-86)
- **Type**: MCP/Avante integration test script
- **Content**: Comprehensive test suite for MCPHub-Avante integration

#### 5.7-5.8 Legacy System Prompt Files
- **File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/util/system-prompts.json`
- **Type**: Old system prompts location (legacy)
- **Note**: Referenced by avante_mcp.lua line 131 as fallback path

#### 5.9 Architecture Documentation
- **File**: `/home/benjamin/.config/nvim/docs/ARCHITECTURE.md`
- **Type**: System architecture documentation
- **Match**: Contains "ensure_mcphub" reference

---

### Category 6: Deprecated/Archive

**Priority: OPTIONAL** - Historical references that can be safely removed.

#### 6.1 Implementation Summary (Deprecated)
- **File**: `/home/benjamin/.config/nvim/deprecated/task-delegation/IMPLEMENTATION_SUMMARY.md`
- **Line 151**: `avante_plugin,` reference
- **Type**: Deprecated implementation documentation

---

## Dependency Analysis

### Direct Dependencies (Managed by Lazy.nvim)
These plugins are declared as dependencies in avante.lua and may become unused after Avante removal:

1. **stevearc/dressing.nvim** - Used by Avante for UI select enhancements (line 682)
   - NOTE: Also used by other plugins, verify before removal
2. **nvim-lua/plenary.nvim** - Utility library (line 683)
   - NOTE: Widely used, DO NOT remove
3. **MunifTanjim/nui.nvim** - UI component library (line 684)
   - NOTE: Used by other plugins, verify before removal
4. **nvim-tree/nvim-web-devicons** - Icon library (line 686)
   - NOTE: Widely used, DO NOT remove
5. **HakonHarnes/img-clip.nvim** - Image clipboard integration (line 690)
   - Verify if used elsewhere before removal

### Indirect Dependencies
1. **MCPHub.nvim** - MCP server integration (referenced throughout but lazy-loaded)
   - NOTE: Used independently, DO NOT remove
2. **blink.cmp** - Mentioned in comment as replacement for nvim-cmp (line 685)
   - Not an Avante dependency

### MCP Integration Modules
These Avante-specific modules will become unused:

1. `neotex.plugins.ai.avante.mcp.mcp_server`
2. `neotex.plugins.ai.avante.mcp.tool_registry`
3. `neotex.plugins.ai.avante.mcp.system-prompts`
4. `neotex.plugins.ai.avante.mcp.avante-highlights`
5. `neotex.plugins.ai.avante.mcp.avante-support`
6. `neotex.plugins.ai.avante.mcp.avante_mcp`

---

## Global State Impact

### Global Variables
- `_G.avante_cycle_state` - Provider/model state tracking
- `_G.provider_models` - Available AI models
- `_G.avante_first_open` - First open notification flag
- `_G.current_avante_prompt` - Current system prompt info
- `_G.avante_last_response_time` - Response timing tracking
- `_G.set_avante_keymaps` - Keymap setup function
- `_G.mcphub_server_started` - Server state (shared with MCPHub)
- `_G.ensure_mcphub_loaded` - MCPHub loader function (partially Avante-specific)

### User Commands
Commands that will be removed:

**From avante.lua (init section)**:
- AvanteAsk, AvanteChat, AvanteToggle, AvanteEdit

**From avante-support.lua**:
- AvanteModel, AvanteProvider, AvanteStop
- AvantePrompt, AvantePromptManager, AvantePromptEdit
- AvanteSelectModel

**From avante_mcp.lua**:
- AvanteAskWithMCP, AvanteChatWithMCP, AvanteToggleWithMCP, AvanteEditWithMCP
- MCPAvante, MCPHubOpen, AvanteRestartMCP, MCPTest
- MCPToolsShow, MCPPromptTest, MCPSystemPromptTest, MCPAvanteConfigTest
- MCPDebugToggle, MCPForceReload, MCPHubDiagnose

### Autocmd Groups
- "AvanteHighlights" - Highlight refresh autocmd group
- "AvantePromptAttribution" - Prompt attribution autocmd group

### Persistent Data
- `~/.local/share/nvim/avante/settings.lua` - User settings storage
- `~/.local/share/nvim/avante/` - Data directory

---

## Recommendations

### Phase 1: Preparation (Pre-Removal)
1. **Backup Current Configuration**
   - Snapshot current settings: `~/.local/share/nvim/avante/settings.lua`
   - Backup configuration: `~/.config/nvim/lua/neotex/plugins/ai/avante/`
   - Document current provider/model preferences

2. **Verify Dependency Usage**
   - Check if dressing.nvim is used by other plugins (likely yes)
   - Verify nui.nvim usage by other plugins (likely yes)
   - Confirm img-clip.nvim is Avante-exclusive (check other plugins)

3. **Test Environment**
   - Ensure alternative AI solution is ready (Claude Code, Goose, Lectic)
   - Verify MCP-Hub remains functional independently

### Phase 2: Code Removal (Ordered by Priority)

**Step 1: Remove Plugin Registration (CRITICAL)**
```bash
# Remove from plugin loader
File: nvim/lua/neotex/plugins/ai/init.lua
Remove line 46: "avante",
```

**Step 2: Remove Main Plugin Configuration (CRITICAL)**
```bash
# Delete primary configuration file
rm nvim/lua/neotex/plugins/ai/avante.lua

# Delete entire MCP integration directory
rm -rf nvim/lua/neotex/plugins/ai/avante/
```

**Step 3: Remove Global Configuration References (IMPORTANT)**
```bash
# File: nvim/lua/neotex/config/keymaps.lua
- Remove lines 217-244 (_G.set_avante_keymaps function)
- Remove lines 313-317 (Global <C-g> keybindings)
- Update comments on lines 18, 23-24, 81-84, 149, 295

# File: nvim/lua/neotex/config/autocmds.lua
- Remove lines 23-27 (Avante markdown autocmd)

# File: nvim/init.lua
- Remove/modify lines 90-124 (_G.ensure_mcphub_loaded function)
  * Consider preserving if MCPHub needs it independently
- Remove line 92 (AvantePreLoad event trigger)
  * Only if no other code uses this event
```

**Step 4: Remove Lock File Entry (IMPORTANT)**
```bash
# File: nvim/lazy-lock.json
Remove line 5: "avante.nvim": { ... }

# Or regenerate lock file
rm nvim/lazy-lock.json
# Restart Neovim to regenerate
```

**Step 5: Update Documentation (OPTIONAL)**
```bash
# File: nvim/README.md
- Remove lines 176-267 ("Using Avante AI" section)
- Update line 50 (remove Avante from feature list)
- Update line 119 (update AI Integration link)
- Remove line 304 (Avante keybinding reference)

# File: nvim/scripts/README.md
- Remove lines 45-125 (force_mcp_restart.lua section)
- Remove Avante references from lines 27, 257, 274

# File: nvim/docs/DOCUMENTATION_STANDARDS.md
- Remove/update examples on lines 159, 164, 219, 239-257

# File: nvim/docs/MAPPINGS.md
- Remove lines 134-140 (Avante AI Commands table)
- Remove lines 415-423 (Avante AI Buffers section)
- Update line 395 (toggleterm <C-a> reference)
```

**Step 6: Remove Scripts (OPTIONAL)**
```bash
# Delete Avante-specific scripts
rm nvim/scripts/force_mcp_restart.lua
rm nvim/scripts/test_mcp_integration.lua
```

**Step 7: Remove Legacy Files (OPTIONAL)**
```bash
# Remove old system prompts location
rm nvim/lua/neotex/plugins/ai/util/system-prompts.json

# Clean deprecated references
# Edit: nvim/deprecated/task-delegation/IMPLEMENTATION_SUMMARY.md
Remove line 151: avante_plugin,
```

**Step 8: Clean Persistent Data (OPTIONAL)**
```bash
# Remove Avante user data
rm -rf ~/.local/share/nvim/avante/
```

### Phase 3: Verification

1. **Syntax Check**
   - Run `nvim --headless "+Lazy! sync" +qa` to test plugin loading
   - Check for Lua syntax errors: `luacheck nvim/lua/`

2. **Functional Verification**
   - Start Neovim and verify no Avante-related errors
   - Confirm `<C-g>` keybinding is freed (or reassigned)
   - Verify MCPHub still works independently
   - Test alternative AI plugins (Claude Code, Goose, Lectic)

3. **Dependency Cleanup** (If Applicable)
   - If img-clip.nvim is unused: Remove from lazy-lock.json
   - Regenerate lazy-lock.json: `rm lazy-lock.json` and restart Neovim

4. **Global State Cleanup**
   - Verify no Avante-related global variables persist after startup
   - Confirm all Avante commands are unregistered

### Phase 4: Post-Removal Optimization

1. **Keymap Reassignment**
   - Consider reassigning freed `<C-g>` keybinding
   - Document removed keybindings in CHANGELOG

2. **Documentation Update**
   - Update AI integration guide to focus on remaining tools
   - Update ARCHITECTURE.md if Avante was mentioned

3. **Commit Changes**
   - Atomic commit with clear message: "Remove Avante plugin and all integrations"
   - Tag commit for potential rollback: `git tag avante-removal-point`

---

## Risk Assessment

### Low Risk
- Documentation removal (can be regenerated)
- Deprecated file cleanup
- Script removal

### Medium Risk
- Keymap removal (may need reassignment)
- Global function removal (verify no external dependencies)
- Autocmd removal (check for FileType conflicts)

### High Risk
- Plugin loader modification (could break plugin loading)
- Lock file modification (requires Lazy.nvim sync)
- MCPHub integration removal (verify independence)

### Rollback Strategy
1. Create git branch before removal: `git checkout -b remove-avante`
2. Commit incrementally after each phase
3. Tag rollback points: `git tag avante-pre-removal`
4. Test thoroughly before merging to main branch

---

## Files Summary

**Total Files**: 25

**By Category**:
- Core Plugin Configuration: 1
- MCP Integration Layer: 9
- Plugin Loader/Init: 2
- Global Configuration: 3
- Documentation: 9
- Deprecated: 1

**By Priority**:
- CRITICAL: 10 files (must remove)
- IMPORTANT: 4 files (should remove)
- OPTIONAL: 11 files (nice to clean up)

**Directory Tree** (files to remove):
```
nvim/
├── init.lua (modify: remove AvantePreLoad, _G.ensure_mcphub_loaded)
├── lazy-lock.json (modify: remove avante.nvim entry)
├── lua/neotex/
│   ├── config/
│   │   ├── autocmds.lua (modify: remove Avante autocmd)
│   │   └── keymaps.lua (modify: remove Avante keymaps)
│   └── plugins/ai/
│       ├── init.lua (modify: remove "avante" from array)
│       ├── avante.lua (DELETE)
│       ├── avante/ (DELETE entire directory)
│       │   ├── README.md
│       │   └── mcp/
│       │       ├── avante_mcp.lua
│       │       ├── avante-support.lua
│       │       ├── avante-highlights.lua
│       │       ├── mcp_server.lua
│       │       ├── tool_registry.lua
│       │       ├── system-prompts.lua
│       │       ├── system-prompts.json
│       │       └── README.md
│       └── util/
│           └── system-prompts.json (DELETE - legacy)
├── scripts/
│   ├── force_mcp_restart.lua (DELETE)
│   └── test_mcp_integration.lua (DELETE)
└── docs/ (UPDATE all documentation files)
```

---

## Conclusion

The Avante plugin has comprehensive integration throughout the Neovim configuration with:
- **1 main plugin file** (707 lines)
- **6 MCP integration modules** (extensive support infrastructure)
- **25+ user commands** across multiple modules
- **7 global keybindings** (including buffer-local)
- **4 global variables** and state tracking
- **Multiple autocmd groups** for integration
- **Extensive documentation** across 5+ files

**Removal Complexity**: **HIGH**
The plugin has deep integration with MCP-Hub and extensive support infrastructure. However, removal is straightforward if done systematically following the phased approach above.

**Estimated Time**: 30-60 minutes (including testing and verification)

**Recommended Approach**: Create a dedicated branch, follow the 4-phase process, test thoroughly before merging.
