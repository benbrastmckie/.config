# Implementation Plan: goose.nvim Integration with Gemini CLI and Claude Code Max

## Plan Metadata

**Date**: 2025-12-05 (Revised)
**Feature**: Integrate goose.nvim for AI-assisted coding with Gemini CLI and Claude Code Max
**Status**: [COMPLETE]
**Estimated Hours**: 3-4 hours
**Standards File**: /home/benjamin/.config/CLAUDE.md
**Research Reports**:
- [001-nvim-ai-agent-plugin-integration-analysis.md](../reports/001-nvim-ai-agent-plugin-integration-analysis.md)
- [revision_goose_nvim_integration_research.md](../reports/revision_goose_nvim_integration_research.md)
- [002-which-key-ai-mapping-consolidation.md](../reports/002-which-key-ai-mapping-consolidation.md)

---

## Strategic Overview

### Selected Solution

**Primary Choice: goose.nvim** with Goose CLI as the AI agent backend

**Why goose.nvim**:
- Seamless Neovim integration with Goose AI agent
- Persistent sessions tied to workspace (continuous conversations)
- Automatic context capture (current file, selections, editor state)
- Modular architecture (UI rendering, context collection, job execution, session management)
- Native diff view for reviewing agent-generated changes
- Provider-agnostic: switch between Gemini and Claude Code easily
- Subscription-based billing via Claude Code Max (predictable costs)

**Provider Strategy**:
1. **Phase A**: Google Gemini (free tier) for initial setup and learning
2. **Phase B**: Claude Code Max subscription for production use

**Cost Benefits**:
- Gemini free tier: $0/month for initial testing
- Claude Max: $100-$200/month flat (no per-token surprises)
- Pass-through provider: Uses Claude Code CLI with Max subscription directly

### Architecture Design

```
┌─────────────────────────────────────────────────────────────┐
│                    Neovim + goose.nvim                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Provider Configuration (via goose configure):               │
│  ┌────────────┬────────────────────────────────────────┐   │
│  │ Phase A    │ Google Gemini (free tier)               │   │
│  │ Phase B    │ Claude Code (Max subscription)          │   │
│  └────────────┴────────────────────────────────────────┘   │
│                                                              │
│  Context Capture (automatic):                                │
│  • Current file/buffer                                       │
│  • Visual selections                                         │
│  • @mention file picker                                      │
│  • Session history                                           │
│                                                              │
│  Goose Modes:                                                │
│  • Chat mode: Conversation-only                              │
│  • Auto mode: Full agent capabilities (file edits)           │
│                                                              │
│  Diff Integration:                                           │
│  • View file changes (<leader>ad)                            │
│  • Navigate diffs (<leader>a] / a[)                          │
│  • Revert changes (<leader>ar via goose)                     │
│                                                              │
└─────────────────────────────────────────────────────────────┘

Backend:
┌─────────────────────────────────────────────────────────────┐
│                      Goose CLI                               │
├─────────────────────────────────────────────────────────────┤
│  Config: ~/.config/goose/config.yaml                         │
│  Providers: Google Gemini, Claude Code (pass-through)        │
│  Tool calling: Native support for code edits                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Success Criteria

- [ ] Goose CLI installed and configured with Google Gemini
- [ ] goose.nvim installed via lazy.nvim with dependencies
- [ ] Basic chat workflow functional with Gemini free tier
- [ ] Key bindings configured in which-key.lua (under `<leader>a` namespace)
- [ ] Diff view functional for reviewing agent changes (`<leader>ad`)
- [ ] Provider switching working (`<leader>ab`)
- [ ] Claude Code Max subscription configured (Phase B)
- [ ] Pass-through provider working (no API key charges)
- [ ] Session persistence working across Neovim restarts
- [ ] Documentation created for usage and configuration

---

## Implementation Phases

### Phase 1: Goose CLI Configuration [COMPLETE]

**Objective**: Configure Goose CLI with Google Gemini provider (CLI already installed via NixOS)

**Prerequisites** (already satisfied):
- Goose CLI installed via NixOS
- Gemini CLI installed via NixOS

**Tasks**:

1. **Verify Goose CLI installation**
   - Run: `goose --version`
   - Confirm goose is available in PATH

2. **Obtain Gemini API key** (if not already configured)
   - Visit https://aistudio.google.com/app/apikey
   - Create new API key for Goose
   - Note: Free tier has rate limits but sufficient for learning

3. **Configure Goose with Gemini**
   - Run: `goose configure`
   - Select "Google Gemini" from provider list
   - Enter `GOOGLE_API_KEY` when prompted
   - Select model: `gemini-2.0-flash-exp` (recommended for speed)
   - Verify config saved to `~/.config/goose/config.yaml`

4. **Test Goose CLI**
   - Navigate to a project directory
   - Run: `goose session`
   - Test basic prompts (ask about files, request code changes)
   - Verify Gemini responses are working
   - Exit session with `/exit`

**Artifacts**:
- `~/.config/goose/config.yaml` with Gemini provider configured
- Gemini API key stored in config

**Dependencies**: None (NixOS provides goose-cli)

---

### Phase 2: goose.nvim Installation [COMPLETE]

**Objective**: Install and configure goose.nvim plugin in Neovim

**Tasks**:

1. **Create plugin configuration file**
   - Create: `nvim/lua/neotex/plugins/ai/goose/init.lua`
   - Configure lazy.nvim spec with dependencies

2. **Plugin specification**:
```lua
return {
  "azorng/goose.nvim",
  branch = "main",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        anti_conceal = { enabled = false },
      },
    },
  },
  config = function()
    require("goose").setup({
      -- Configuration in Phase 3
    })
  end,
  cmd = { "Goose", "GooseOpenInput", "GooseToggle" },
  -- Keybindings managed by which-key.lua (Phase 3)
  -- Empty keys table to prevent plugin-defined keybindings
  keys = {},
}
```

**NOTE**: All keybindings will be defined in which-key.lua under the `<leader>a` namespace to maintain consistency with other AI tools (Claude, Avante, Lectic).

3. **Install and verify**
   - Run `:Lazy sync` in Neovim
   - Verify goose.nvim installed without errors
   - Check dependencies (plenary.nvim, render-markdown.nvim)
   - Run `:checkhealth goose` if available

4. **Test basic integration**
   - Open Neovim in a project directory
   - Run `:Goose` or `:GooseToggle`
   - Verify chat interface opens
   - Test basic prompt with Gemini backend

**Artifacts**:
- `nvim/lua/neotex/plugins/ai/goose/init.lua` - plugin spec
- Plugin installed via lazy.nvim

**Dependencies**: Phase 1 completion

---

### Phase 3: Key Bindings and UI Configuration [COMPLETE]

**Objective**: Configure key bindings in which-key.lua and UI settings in goose.nvim

**Keybinding Design Philosophy**:
- All AI-related keybindings use the `<leader>a` prefix (consistent with Claude, Avante, Lectic)
- Keybindings are defined in `which-key.lua` for discoverability and consistency
- Only essential operations are mapped to avoid clutter
- Plugin-level keybindings are disabled (`default_global_keymaps = false`)

**Currently Used `<leader>a` Letters** (DO NOT USE):
- a (Avante ask), c (Claude commands), e (Avante edit), l (Lectic run)
- m (Avante model), n (New Lectic file), p (Avante provider), P (Lectic provider)
- r (Restore worktree), s (Claude sessions), t (Toggle TTS), v (View worktrees)
- w (Create worktree), x (MCP Hub), y (Yolo mode)

**Available Letters for goose.nvim** (12 available):
- **b, d, f, g, h, i, j, k, o, q, u, z**

**Tasks**:

1. **Configure goose.nvim setup** (disable internal keymaps):
```lua
require("goose").setup({
  -- Picker (auto-detect telescope if available)
  prefered_picker = "telescope",  -- or 'fzf', 'mini.pick', 'snacks'

  -- CRITICAL: Disable default keymaps (managed by which-key.lua)
  default_global_keymaps = false,

  -- UI Settings
  ui = {
    window_width = 0.35,        -- 35% of screen width
    input_height = 0.15,        -- 15% for input area
    fullscreen = false,
    layout = "right",           -- Sidebar on right
    floating_height = 0.8,
    display_model = true,       -- Show model in winbar
    display_goose_mode = true,  -- Show mode in winbar
  },

  -- Provider shortcuts
  providers = {
    google = { "gemini-2.0-flash-exp" },
  },
})
```

2. **Add keybindings to which-key.lua** (after line 265, after MCP Hub):

**File**: `nvim/lua/neotex/plugins/editor/which-key.lua`

```lua
-- Goose AI commands (using available <leader>a letters)
{ "<leader>ag", "<cmd>GooseToggle<CR>", desc = "goose toggle", icon = "󰚩" },
{ "<leader>ag", "<cmd>GooseSendSelection<CR>", desc = "goose with selection", icon = "󰚩", mode = "v" },
{ "<leader>ai", "<cmd>GooseOpenInput<CR>", desc = "goose input", icon = "󰭹" },
{ "<leader>ao", "<cmd>GooseOpenOutput<CR>", desc = "goose output", icon = "󰆍" },
{ "<leader>af", "<cmd>GooseToggleFullscreen<CR>", desc = "goose fullscreen", icon = "󰊓" },
{ "<leader>ad", "<cmd>GooseDiffOpen<CR>", desc = "goose diff", icon = "󰦓" },
{ "<leader>ab", "<cmd>GooseConfigureProvider<CR>", desc = "goose backend/provider", icon = "󰒓" },
{ "<leader>aq", "<cmd>GooseClose<CR>", desc = "goose quit", icon = "󰅖" },
```

**Essential Mappings Breakdown** (8 total - keeping minimal):
| Mapping | Letter | Description | Rationale |
|---------|--------|-------------|-----------|
| `<leader>ag` | g | Toggle goose interface | Primary entry point (g=goose) |
| `<leader>ag` (visual) | g | Send selection to goose | Context-aware prompting |
| `<leader>ai` | i | Focus input window | Quick prompt input (i=input) |
| `<leader>ao` | o | Focus output window | View responses (o=output) |
| `<leader>af` | f | Toggle fullscreen | More screen real estate (f=fullscreen) |
| `<leader>ad` | d | Open diff view | Review changes (d=diff) |
| `<leader>ab` | b | Switch backend/provider | Model selection (b=backend) |
| `<leader>aq` | q | Close goose | Exit interface (q=quit) |

**Non-essential operations** (accessible via commands, not mapped):
- `:GooseSelectSession` - Session management
- `:GooseModeChat` / `:GooseModeAuto` - Mode switching
- `:GooseDiffNext` / `:GooseDiffPrev` - Diff navigation
- `:GooseDiffRevertAll` / `:GooseDiffRevertThis` - Change reversion

3. **Test key bindings**
   - Open Neovim and test each keybinding
   - Verify `<leader>ag` toggles interface
   - Test visual mode selection → `<leader>ag`
   - Test `@` mention for file context (buffer-local)
   - Test diff view with `<leader>ad`
   - Verify no conflicts with existing `<leader>a*` mappings

4. **Verify which-key integration**
   - Press `<leader>a` and verify goose commands appear in menu
   - Confirm icons display correctly
   - Check descriptions are accurate

**Artifacts**:
- Updated `which-key.lua` with goose keybindings (8 new mappings)
- goose.nvim configuration with disabled internal keymaps
- Key bindings documentation in goose/README.md

**Dependencies**: Phase 2 completion

---

### Phase 4: Claude Code Max Integration [COMPLETE]

**Objective**: Configure Claude Code as pass-through provider for subscription-based usage

**Tasks**:

1. **Subscribe to Claude Max**
   - Visit https://claude.ai/upgrade
   - Select Max plan ($100/month for 5x usage or $200/month for 20x)
   - Complete subscription setup

2. **Install Claude Code CLI**
   - Follow instructions at https://claude.ai/code
   - Install via npm or download
   - Verify installation: `claude --version`

3. **Configure Claude Code authentication**
   - Run: `claude auth login`
   - Login with Max subscription credentials
   - **CRITICAL**: Ensure `ANTHROPIC_API_KEY` is NOT set in environment
     - If set, Claude Code uses API billing instead of subscription
     - Unset with: `unset ANTHROPIC_API_KEY`
   - Verify with: `claude /status` (should show subscription info)

4. **Configure Goose with Claude Code provider**
   - Run: `goose configure`
   - Select "Claude Code" from provider list
   - This uses pass-through mode (no API key needed)
   - Verify config updated in `~/.config/goose/config.yaml`

5. **Update goose.nvim provider shortcuts**:
```lua
providers = {
  google = { "gemini-2.0-flash-exp" },
  -- Claude Code is configured via goose configure
  -- Switch with <leader>ab or goose configure
},
```

6. **Test Claude Code integration**
   - Open Neovim with goose.nvim
   - Switch provider with `<leader>ab` or run `goose configure`
   - Test prompt requiring code generation
   - Verify responses from Claude
   - Check `/status` confirms subscription usage

**Artifacts**:
- Claude Max subscription active
- Claude Code CLI installed and authenticated
- Goose configured with Claude Code provider
- Environment verified (no ANTHROPIC_API_KEY)

**Dependencies**: Phase 3 completion

---

### Phase 5: Documentation and Validation [COMPLETE]

**Objective**: Create documentation and validate complete workflow

**Tasks**:

1. **Create configuration documentation**
   - Document installation steps for Goose CLI
   - Document goose.nvim setup
   - Document provider switching workflow
   - Create troubleshooting guide

2. **Test complete workflow**
   - Test Gemini provider: basic chat, code suggestions
   - Test Claude Code provider: complex code generation
   - Test context capture with file mentions (@)
   - Test diff review and revert workflow
   - Test session persistence (close/reopen Neovim)
   - Test provider switching mid-session

3. **Validate performance**
   - Check Neovim startup time (lazy loading should have no impact)
   - Verify chat responsiveness
   - Test with large files/context

4. **Create usage examples**
   - Document common workflows (code review, refactoring, debugging)
   - Create prompt templates for frequent tasks
   - Document best practices for each provider

**Artifacts**:
- README.md in `nvim/lua/neotex/plugins/ai/goose/`
- Troubleshooting guide
- Usage examples and prompt templates

**Dependencies**: Phase 4 completion

---

## Technical Considerations

### Configuration File Structure

```
nvim/lua/neotex/plugins/ai/
├── goose/
│   └── init.lua              # goose.nvim configuration
├── claude/                   # Existing claude config (preserve)
└── README.md                 # AI integrations overview
```

### API Key Security

**Best Practices**:
1. **Gemini API Key**: Store in `~/.config/goose/config.yaml` (managed by goose configure)
2. **Claude Code**: Uses OAuth authentication with Max subscription (no API key needed)
3. **CRITICAL**: Do NOT set `ANTHROPIC_API_KEY` when using Claude Code Max
   - This causes API billing instead of subscription billing
4. **Git**: Ensure `~/.config/goose/` is in `.gitignore` if syncing dotfiles

### Performance Considerations

**Lazy Loading Strategy**:
```lua
{
  "azorng/goose.nvim",
  cmd = { "Goose", "GooseOpenInput", "GooseToggle" },
  keys = {},  -- Empty: keybindings managed by which-key.lua
  -- Only loads when commands used
  -- Note: which-key.lua mappings trigger lazy load via commands
}
```

**Keybinding Organization** (all AI tools use `<leader>a` prefix):
- goose.nvim: `<leader>ag`, `<leader>ai`, `<leader>ao`, `<leader>af`, `<leader>ad`, `<leader>ab`, `<leader>aq`
- Claude Code: `<leader>ac`, `<leader>as`, `<leader>av`, `<leader>aw`, `<leader>ar`
- Avante: `<leader>aa`, `<leader>ae`, `<leader>ap`, `<leader>am`, `<leader>ax`
- Lectic: `<leader>al`, `<leader>an`, `<leader>aP` (conditional on `.lec`/`.md` files)
- Custom: `<leader>at` (TTS), `<leader>ay` (yolo mode)

**Context Optimization**:
- Use `@` mention for selective file inclusion (vs entire buffer)
- Gemini 2.x models support 1M token context
- Claude via Max subscription handles large contexts well
- Chat mode for quick questions, Auto mode for file edits

### Integration with Existing Configuration

**Compatibility Checks**:
1. Verify no key binding conflicts with existing `<leader>a` mappings (see Phase 3 letter allocation)
2. Ensure plenary.nvim is available (required dependency)
3. Optional: telescope.nvim for file picker integration
4. Verify Neovim version ≥ 0.8.0

**Preserve Existing**:
- Keep existing `nvim/lua/neotex/plugins/ai/claude/` configuration
- Keep existing `nvim/lua/neotex/plugins/ai/avante.lua` configuration
- goose.nvim and other AI integrations can coexist
- All AI tools share the `<leader>a` namespace (no conflicts due to careful letter allocation)

**which-key.lua Organization**:
- All AI keybindings centralized in which-key.lua (lines 244-361+)
- Global toggles (`<C-c>`, `<C-g>`) remain in keymaps.lua for quick access
- Conditional mappings (e.g., Lectic) use `cond = function()` for filetype-specific features
- Plugin specs should have empty `keys = {}` tables (keybindings managed by which-key.lua)

---

## Risk Mitigation

### High-Priority Risks

**Risk 1: Goose CLI Not in PATH**
- **Mitigation**: Verify NixOS package is installed and available
- **Monitoring**: Run `goose --version` to confirm
- **Recovery**: Check NixOS configuration, rebuild if needed

**Risk 2: Provider Authentication Issues**
- **Mitigation**: Test each provider independently before integration
- **Monitoring**: Check `goose configure` output
- **Recovery**: Re-run configuration, verify API keys

**Risk 3: Claude Code Uses API Instead of Subscription**
- **Mitigation**: Verify ANTHROPIC_API_KEY is unset before authentication
- **Monitoring**: Check `claude /status` for subscription confirmation
- **Recovery**: Unset env var, re-authenticate

### Medium-Priority Risks

**Risk 4: Key Binding Conflicts**
- **Mitigation**: Use `<leader>a` namespace with carefully allocated letters (g, i, o, f, d, b, q)
- **Monitoring**: Test after installation; run `:verbose map <leader>a` to check conflicts
- **Recovery**: Choose different available letter (h, j, k, u, z still available)

**Risk 5: Session Persistence Issues**
- **Mitigation**: Verify `~/.config/goose/` directory permissions
- **Recovery**: Clear sessions, restart

---

## Dependencies

### Required Dependencies

**External Tools** (NixOS-managed):
- Goose CLI - already installed via NixOS
- Gemini CLI - already installed via NixOS
- Claude Code CLI (for Phase 4, Max subscription)

**Neovim Plugins**:
- `nvim-lua/plenary.nvim` - Lua utility functions (required)
- `MeanderingProgrammer/render-markdown.nvim` - Markdown rendering (optional but recommended)

**Optional Dependencies**:
- `nvim-telescope/telescope.nvim` - Enhanced file picker
- `folke/lazy.nvim` - Plugin manager (assumed present)

**External Services**:
- Google Gemini API key (free tier available)
- Claude Max subscription ($100-$200/month) for Phase 4

### System Requirements

- NixOS with goose-cli and gemini-cli packages
- Neovim ≥ 0.8.0 (verify with `:version`)
- Internet connectivity for AI provider access

---

## Testing Strategy

### Manual Testing Checklist

**Phase 1 Tests**:
- [ ] `goose --version` returns version info (NixOS package working)
- [ ] `goose configure` completes with Gemini provider
- [ ] `goose session` works in terminal
- [ ] Config saved to `~/.config/goose/config.yaml`

**Phase 2 Tests**:
- [ ] goose.nvim installed via lazy.nvim
- [ ] No errors on `:Lazy sync`
- [ ] `:Goose` command available
- [ ] Chat interface opens correctly
- [ ] Gemini responds to prompts

**Phase 3 Tests**:
- [ ] `<leader>ag` toggles interface
- [ ] `<leader>ag` (visual) sends selection to goose
- [ ] `<leader>ai` opens input with focus
- [ ] `<leader>ao` opens output with focus
- [ ] `<leader>af` toggles fullscreen
- [ ] `<leader>ad` opens diff view
- [ ] `<leader>ab` opens provider selection
- [ ] `<leader>aq` closes goose interface
- [ ] `@` mention shows file picker (buffer-local)
- [ ] All mappings appear in which-key menu under `<leader>a`
- [ ] No conflicts with existing `<leader>a*` mappings
- [ ] Session persistence working

**Phase 4 Tests**:
- [ ] Claude Code CLI installed
- [ ] `claude /status` shows Max subscription
- [ ] Goose configured with Claude Code provider
- [ ] Provider switching works (`<leader>ab`)
- [ ] Claude responses received successfully

**Phase 5 Tests**:
- [ ] Documentation complete
- [ ] All workflows documented
- [ ] Troubleshooting guide accurate

### Performance Testing

**Startup Time**:
```bash
# Before integration
nvim --startuptime startup_before.log +q

# After integration
nvim --startuptime startup_after.log +q

# Should show < 50ms increase with lazy loading
```

---

## Rollback Strategy

### Quick Rollback

**Disable Plugin**:
```lua
-- In lazy.nvim spec
{
  "azorng/goose.nvim",
  enabled = false,  -- Disable without uninstalling
}
```

### Full Uninstall

1. Remove goose.nvim spec from lazy.nvim configuration
2. Run `:Lazy clean` to remove plugin
3. Delete configuration: `rm -rf nvim/lua/neotex/plugins/ai/goose/`
4. Remove keybindings from which-key.lua (lines added for goose: `<leader>ag`, `<leader>ai`, `<leader>ao`, `<leader>af`, `<leader>ad`, `<leader>ab`, `<leader>aq`)
5. (Optional) Remove Goose config: `rm -rf ~/.config/goose/`
6. (Optional) Remove Claude Code: `npm uninstall -g @anthropic-ai/claude-code`
7. Note: Goose CLI managed by NixOS - remove from configuration.nix if desired
8. Restart Neovim and verify clean state

---

## Future Enhancements

### Post-Implementation Ideas

1. **Custom System Instructions**
   - Project-specific agent behavior via `system_instructions` config
   - Different instructions per project type (Lua, Python, etc.)

2. **Workflow Templates**
   - Pre-defined prompts for code review
   - Refactoring assistance templates
   - Documentation generation workflows

3. **Multi-Model Optimization**
   - Use Gemini for quick questions (free tier)
   - Use Claude for complex code generation
   - Automatic routing based on task type (future feature)

4. **Integration with Development Workflow**
   - LSP error context injection
   - Git diff review assistance
   - Test generation from code

---

## Success Metrics

### Quantitative Metrics

- **Installation Success**: Complete setup within 2 hours
- **Performance**: Neovim startup time increase < 50ms with lazy loading
- **Cost**: Gemini free tier sufficient for 80%+ of daily usage in Phase A
- **Response Time**: Chat responses arrive within 2-3 seconds

### Qualitative Metrics

- **Usability**: Can use chat and diff review without referring to docs
- **Reliability**: No crashes during normal operation
- **Flexibility**: Easy provider switching via `<leader>ab`
- **Integration**: Natural fit with existing Neovim workflow (all AI tools under `<leader>a`)

---

## Timeline Estimate

### Phase A: Gemini Setup (1-1.5 hours)
- Phase 1: 15-20 minutes (Goose CLI configuration only - already installed via NixOS)
- Phase 2: 20-30 minutes (goose.nvim installation and basic testing)
- Phase 3: 20-30 minutes (keybindings and UI configuration)

### Phase B: Claude Code Max (1-2 hours)
- Phase 4: 1-1.5 hours (subscription, CLI, authentication, testing)
- Phase 5: 30-45 minutes (documentation and final validation)

### Total: 3-4 hours (reduced due to NixOS pre-installed CLIs)

---

## References

### Primary Documentation
- [goose.nvim GitHub](https://github.com/azorng/goose.nvim)
- [Goose CLI Documentation](https://block.github.io/goose/docs/getting-started/installation)
- [Goose Provider Configuration](https://block.github.io/goose/docs/getting-started/providers/)
- [Claude Code with Max Plan](https://support.claude.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan)

### Research Reports
- [001-nvim-ai-agent-plugin-integration-analysis.md](../reports/001-nvim-ai-agent-plugin-integration-analysis.md) - Original comprehensive analysis
- [revision_goose_nvim_integration_research.md](../reports/revision_goose_nvim_integration_research.md) - goose.nvim-focused research

### Community Resources
- [Goose AI Agent](https://github.com/block/goose)
- [Neovim AI Plugins List](https://github.com/ColinKennedy/neovim-ai-plugins)
- [Google AI Studio](https://aistudio.google.com/app/apikey) - Gemini API key

---

## Notes

### Key Decisions

1. **Selected goose.nvim over codecompanion.nvim** because:
   - Direct Goose AI agent integration
   - Pass-through provider for Claude Max subscription
   - Persistent sessions tied to workspace
   - Native diff view for code changes
   - Simpler configuration (single backend)

2. **Two-phase provider strategy**:
   - Phase A: Gemini free tier for learning and setup
   - Phase B: Claude Code Max for production use
   - Predictable monthly cost vs per-token API billing

3. **Claude Code pass-through mode**:
   - Uses Max subscription directly (no API key)
   - Must ensure ANTHROPIC_API_KEY is NOT set
   - Better cost predictability

### Design Principles

1. **Start with Free Tier**: Use Gemini for initial setup and learning
2. **Subscription-Based Billing**: Avoid per-token surprises with Max plan
3. **Lazy Loading**: No startup impact on Neovim
4. **Simple Configuration**: Single backend (Goose CLI) manages providers
5. **NixOS Integration**: Leverage system-managed CLI tools
6. **Documentation Driven**: Clear setup and usage documentation

---

**Plan Created**: 2025-12-05
**Plan Revised**: 2025-12-05 (Focus on goose.nvim with Gemini CLI + Claude Code Max)
**Plan Updated**: 2025-12-05 (Adapted for NixOS with pre-installed CLIs)
**Plan Revised**: 2025-12-05 (Consolidated all AI keybindings under `<leader>a` namespace in which-key.lua)
**Research Depth**: Targeted (goose.nvim, Goose CLI, Claude Code integration, which-key.lua mapping analysis)
**Recommendation Confidence**: High
**Implementation Readiness**: Ready to proceed

---

## Keybinding Quick Reference

### All AI Tools Under `<leader>a` Namespace

| Plugin | Mappings | Description |
|--------|----------|-------------|
| **goose.nvim** | `<leader>ag` | Toggle goose interface |
| | `<leader>ai` | Focus goose input |
| | `<leader>ao` | Focus goose output |
| | `<leader>af` | Toggle goose fullscreen |
| | `<leader>ad` | Open goose diff view |
| | `<leader>ab` | Switch goose backend/provider |
| | `<leader>aq` | Close goose |
| **Claude Code** | `<leader>ac` | Claude commands picker |
| | `<leader>as` | Claude sessions |
| | `<leader>av` | View worktrees |
| | `<leader>aw` | Create worktree |
| | `<leader>ar` | Restore worktree |
| **Avante** | `<leader>aa` | Avante ask |
| | `<leader>ae` | Avante edit (visual) |
| | `<leader>ap` | Avante provider |
| | `<leader>am` | Avante model |
| | `<leader>ax` | MCP Hub |
| **Lectic** | `<leader>al` | Lectic run |
| | `<leader>an` | New Lectic file |
| | `<leader>aP` | Lectic provider |
| **Custom** | `<leader>at` | Toggle TTS |
| | `<leader>ay` | Toggle yolo mode |

### Global Toggles (keymaps.lua)

| Mapping | Description |
|---------|-------------|
| `<C-c>` | Toggle Claude Code (all modes) |
| `<C-g>` | Toggle Avante (all modes) |

### Available Letters for Future AI Tools

**h, j, k, u, z** (5 letters still available under `<leader>a`)
