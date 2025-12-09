# Goose.nvim Gemini Configuration Implementation Plan

## Metadata
- **Date**: 2025-12-06
- **Feature**: Fix goose.nvim Gemini provider configuration to enable AI-powered sidebar with recipe support
- **Status**: [COMPLETE]
- **Estimated Hours**: 3-5 hours
- **Complexity Score**: 42.0
- **Structure Level**: 0
- **Estimated Phases**: 5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Goose.nvim Gemini Configuration Analysis](../reports/001-goose-nvim-gemini-config-analysis.md)

## Overview

This plan addresses the critical provider/model mismatch between goose.nvim plugin configuration and goose CLI backend configuration that prevents Gemini-powered AI assistance from working correctly in the Neovim sidebar. The root cause is a configuration inconsistency: goose.nvim is configured for the `google` provider with `gemini-2.0-flash-exp` model, while the goose CLI backend is configured for the `gemini-cli` provider with `gemini-3.0-pro` model.

The implementation will align both configurations to use the `google` provider (Gemini API direct) for simpler integration, better goose.nvim compatibility, and reduced dependencies. This approach eliminates the need for the gemini CLI tool as an intermediary and enables proper model selection through the goose.nvim UI.

## Research Summary

Key findings from research analysis:

1. **Configuration Mismatch Identified**: goose.nvim expects `google` provider but goose CLI is configured for `gemini-cli` provider - these are NOT interchangeable backends
2. **Environment Already Configured**: `GEMINI_API_KEY` is set and both goose CLI (v1.13.1) and gemini CLI (v0.18.4) are installed
3. **Provider Backend Differences**: The `google` provider makes direct API calls to Gemini API, while `gemini-cli` shells out to the gemini CLI binary
4. **Recipe System Ready**: Goose recipes (research.yaml, create-plan.yaml, implement.yaml, revise.yaml) are already implemented and ready to use
5. **Documentation Gap**: Current README lacks provider alignment instructions, leading to configuration confusion

Recommended approach: Strategy 1 (Align to Google Provider) for simplicity, better goose.nvim integration, and consistent model naming.

## Success Criteria

- [ ] goose CLI configuration shows `GOOSE_PROVIDER: google` and `GOOSE_MODEL: gemini-2.0-flash-exp`
- [ ] `GOOGLE_API_KEY` environment variable is set (aliased from `GEMINI_API_KEY`)
- [ ] goose.nvim sidebar opens successfully and responds to prompts using Gemini
- [ ] All goose recipes (research, create-plan, revise, implement) execute successfully from terminal
- [ ] Recipe invocation from Neovim sidebar works correctly
- [ ] Provider selection UI in goose.nvim displays and functions correctly
- [ ] goose.nvim README documentation includes provider alignment instructions
- [ ] Session persistence works across Neovim restarts

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Neovim Editor                            │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              goose.nvim Plugin                       │  │
│  │  - Provider: google                                  │  │
│  │  - Model: gemini-2.0-flash-exp                       │  │
│  └──────────────┬───────────────────────────────────────┘  │
│                 │ Invokes                                   │
└─────────────────┼───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│                  Goose CLI Backend                          │
│  Configuration: ~/.config/goose/config.yaml                │
│  - GOOSE_PROVIDER: google      ◄── ALIGNED                 │
│  - GOOSE_MODEL: gemini-2.0-flash-exp  ◄── ALIGNED          │
│  - GOOSE_MODE: auto                                        │
│  Environment: GOOGLE_API_KEY (aliased from GEMINI_API_KEY) │
└──────────────────┬──────────────────────────────────────────┘
                   │ Direct API Calls
                   ▼
┌─────────────────────────────────────────────────────────────┐
│              Google Gemini REST API                         │
│  - Model: gemini-2.0-flash-exp                             │
│  - Authentication: GOOGLE_API_KEY                          │
│  - Free Tier: 15 req/min, 1500 req/day                     │
└─────────────────────────────────────────────────────────────┘
```

### Configuration Strategy

**Alignment Approach (Strategy 1 - Google Provider)**:
- Change goose CLI from `gemini-cli` provider to `google` provider
- Keep goose.nvim configuration unchanged (already correct)
- Alias `GOOGLE_API_KEY` to existing `GEMINI_API_KEY` value
- Eliminate dependency on gemini CLI binary (optional going forward)

**Rationale**:
1. **Simpler Integration**: Direct HTTP API calls vs shelling out to CLI tool
2. **Better Compatibility**: goose.nvim documentation focuses on `google` provider
3. **Consistent Naming**: Both configurations use same model name (`gemini-2.0-flash-exp`)
4. **Fewer Dependencies**: No external CLI tool required in the data path
5. **Better UI Support**: Model selection in goose.nvim UI works correctly

### Component Changes

**Files to Modify**:
1. `~/.config/goose/config.yaml` - Reconfigure via `goose configure` command
2. `~/.bashrc` or `~/.zshrc` - Add `GOOGLE_API_KEY` environment variable export
3. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md` - Add provider alignment documentation

**Files to Preserve**:
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua` - Already correct (no changes needed)
- `/home/benjamin/.config/.goose/recipes/*.yaml` - Recipe files work with any provider
- `/home/benjamin/.config/.goosehints` - Optional update to match new provider

## Implementation Phases

### Phase 1: Configuration Backup and Preparation [COMPLETE]
dependencies: []

**Objective**: Safely backup current configurations and prepare environment for provider migration.

**Complexity**: Low

**Tasks**:
- [x] Backup current goose CLI config: `cp ~/.config/goose/config.yaml ~/.config/goose/config.yaml.backup.$(date +%Y%m%d_%H%M%S)`
- [x] Backup current shell profile (determine if using bashrc or zshrc): `cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d)` or `cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d)`
- [x] Verify `GEMINI_API_KEY` environment variable is set: `echo $GEMINI_API_KEY`
- [x] Document current configuration state for rollback reference
- [x] Verify goose CLI version supports google provider: `goose --version` (expect v1.13.1)

**Testing**:
```bash
# Verify backups created
test -f ~/.config/goose/config.yaml.backup.* && echo "✓ Config backup exists"
test -f ~/.bashrc.backup.* -o -f ~/.zshrc.backup.* && echo "✓ Shell profile backup exists"

# Verify API key set
[ -n "$GEMINI_API_KEY" ] && echo "✓ GEMINI_API_KEY is set" || echo "✗ GEMINI_API_KEY not set"
```

**Expected Duration**: 0.5 hours

---

### Phase 2: Goose CLI Provider Reconfiguration [COMPLETE]
dependencies: [1]

**Objective**: Reconfigure goose CLI to use `google` provider with `gemini-2.0-flash-exp` model.

**Complexity**: Medium

**Tasks**:
- [x] Set `GOOGLE_API_KEY` environment variable temporarily: `export GOOGLE_API_KEY="$GEMINI_API_KEY"`
- [x] Run `goose configure` command interactively
- [x] Select "Google Gemini" option (NOT "Gemini CLI")
- [x] Enter API key when prompted (use `$GOOGLE_API_KEY` value)
- [x] Select model: `gemini-2.0-flash-exp`
- [x] Keep mode as `auto` (default)
- [x] Verify config.yaml updated correctly: `cat ~/.config/goose/config.yaml`
- [x] Confirm provider is `google` and model is `gemini-2.0-flash-exp`

**Testing**:
```bash
# Verify configuration file updated
grep -q "GOOSE_PROVIDER: google" ~/.config/goose/config.yaml && echo "✓ Provider set to google"
grep -q "GOOSE_MODEL: gemini-2.0-flash-exp" ~/.config/goose/config.yaml && echo "✓ Model set correctly"
grep -q "GOOSE_MODE: auto" ~/.config/goose/config.yaml && echo "✓ Mode set to auto"

# Test basic goose CLI invocation
goose --help > /dev/null && echo "✓ Goose CLI functional"
```

**Expected Duration**: 1 hour

---

### Phase 3: Environment Variable Configuration [COMPLETE]
dependencies: [2]

**Objective**: Persist `GOOGLE_API_KEY` environment variable in shell profile for permanent configuration.

**Complexity**: Low

**Tasks**:
- [x] Determine active shell (bash or zsh): `echo $SHELL`
- [x] Add environment variable export to appropriate profile file
- [x] Use format: `export GOOGLE_API_KEY="${GEMINI_API_KEY:-AIzaSyD6BiVzXhbhXFLqdbh_TmtAhiJG7EXFtqw}"`
- [x] Add comment documenting purpose: `# Goose Provider Configuration - google provider uses GOOGLE_API_KEY`
- [x] Source updated profile to apply changes: `source ~/.bashrc` or `source ~/.zshrc`
- [x] Verify variable set in new shell session: Open new terminal and `echo $GOOGLE_API_KEY`

**Testing**:
```bash
# Verify environment variable in current shell
[ -n "$GOOGLE_API_KEY" ] && echo "✓ GOOGLE_API_KEY set in current session"

# Verify persistence in profile
if [ -n "$BASH_VERSION" ]; then
  grep -q "GOOGLE_API_KEY" ~/.bashrc && echo "✓ Variable added to bashrc"
elif [ -n "$ZSH_VERSION" ]; then
  grep -q "GOOGLE_API_KEY" ~/.zshrc && echo "✓ Variable added to zshrc"
fi

# Test in new shell
bash -c 'echo $GOOGLE_API_KEY' | grep -q "AIza" && echo "✓ Variable persists in new bash session"
```

**Expected Duration**: 0.5 hours

---

### Phase 4: Integration Testing and Validation [COMPLETE]
dependencies: [3]

**Objective**: Verify goose CLI, goose.nvim, and recipe system work correctly with new provider configuration.

**Complexity**: Medium

**Tasks**:
- [x] Test goose CLI from terminal with simple prompt: `echo "List files in current directory" | goose`
- [x] Test recipe execution from terminal: `goose run --recipe ~/.config/.goose/recipes/research.yaml --params topic="test integration"`
- [x] Open Neovim and test goose sidebar: `:Goose`
- [x] Enter test prompt in goose sidebar: "What files are in this project?"
- [x] Verify Gemini responds correctly in sidebar
- [x] Test provider selection UI: Press `<leader>ab` in goose sidebar to verify google provider is active
- [x] Test file context feature: Use `@` in goose input to attach file, verify context captured
- [x] Close and reopen Neovim, verify session persistence works
- [x] Test all goose recipes (research, create-plan, revise, implement) from terminal
- [x] Verify no error messages in Neovim or terminal output

**Testing**:
```bash
# Test CLI integration
echo "Test prompt" | goose 2>&1 | grep -q "gemini" && echo "✓ CLI integration working"

# Test recipe discovery
goose run --recipe ~/.config/.goose/recipes/research.yaml --help 2>&1 | grep -q "recipe" && echo "✓ Recipe system accessible"

# Neovim integration test (manual)
# Open Neovim, run:
# :Goose
# Enter: "Hello, can you see this?"
# Expected: Gemini responds
```

**Expected Duration**: 1.5 hours

---

### Phase 5: Documentation Update [COMPLETE]
dependencies: [4]

**Objective**: Update goose.nvim README with provider alignment instructions to prevent future configuration issues.

**Complexity**: Low

**Tasks**:
- [x] Read current README.md: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md`
- [x] Add "Provider Alignment" section after "Backend Configuration" (after line 78)
- [x] Document the provider/model synchronization requirement
- [x] Include step-by-step reconfiguration instructions
- [x] Add provider comparison table (google vs gemini-cli)
- [x] Document environment variable requirements (`GOOGLE_API_KEY` vs `GEMINI_API_KEY`)
- [x] Add troubleshooting section for common provider mismatch symptoms
- [x] Include verification commands for checking configuration state
- [x] Update .goosehints file to reflect new provider configuration (optional)

**Testing**:
```bash
# Verify documentation added
grep -q "Provider Alignment" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md && echo "✓ Provider Alignment section added"

# Verify key content present
grep -q "GOOGLE_API_KEY" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md && echo "✓ Environment variable documented"
grep -q "goose configure" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md && echo "✓ Reconfiguration steps documented"

# Verify formatting (markdown validation)
mdl /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md 2>/dev/null || echo "Note: Install mdl for markdown linting"
```

**Expected Duration**: 1 hour

## Testing Strategy

### Pre-Configuration Testing
- Verify current state (provider mismatch documented)
- Confirm backups created before any changes
- Test rollback procedure with backups

### Configuration Testing
- Validate goose CLI configuration file format
- Verify environment variables set correctly
- Test goose CLI functionality in isolation

### Integration Testing
- Test goose CLI with google provider from terminal
- Test goose.nvim sidebar with Gemini responses
- Test all goose recipes (research, create-plan, revise, implement)
- Test recipe invocation from Neovim sidebar
- Verify session persistence across restarts

### UI Testing
- Test goose sidebar toggle keybindings
- Test provider selection UI functionality
- Test file context feature with @ mentions
- Test diff view feature
- Verify markdown rendering in sidebar

### Regression Testing
- Ensure existing goose.nvim features still work
- Verify recipe system functionality preserved
- Test model selection UI
- Confirm no breaking changes to workflow

### Error Handling Testing
- Test with invalid API key (expect clear error message)
- Test with network disconnected (expect graceful handling)
- Test with missing recipe file (expect helpful error)
- Test with invalid recipe parameters (expect prompts)

## Documentation Requirements

### Files to Update

1. **`/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md`**
   - Add "Provider Alignment (IMPORTANT)" section after line 78
   - Document provider/model synchronization requirement
   - Include reconfiguration steps (goose configure)
   - Add provider comparison table
   - Add environment variable documentation
   - Include troubleshooting section

2. **`/home/benjamin/.config/.goosehints`** (Optional)
   - Update `GOOSE_PROVIDER: google` (currently shows `gemini-cli`)
   - Update `GOOSE_MODEL: gemini-2.0-flash-exp` (currently shows `gemini-3.0-pro`)
   - Keep `GOOSE_MODE: auto` unchanged

### Documentation Sections to Add

**Provider Alignment Section** (to be added to README.md):
- Explanation of provider/backend relationship
- Why goose.nvim and goose CLI must match
- Step-by-step alignment verification
- Reconfiguration instructions
- Provider comparison (google vs gemini-cli)
- Environment variable requirements

**Troubleshooting Section** (to be added to README.md):
- Symptom: Goose sidebar not responding
- Symptom: Model selection UI not working
- Symptom: API key errors
- Verification commands
- Rollback instructions

## Dependencies

### External Dependencies
- **goose CLI** (v1.13.1): Already installed at `/home/benjamin/.nix-profile/bin/goose`
- **Google Gemini API**: Requires `GOOGLE_API_KEY` environment variable (alias of existing `GEMINI_API_KEY`)
- **goose.nvim plugin**: Already installed via lazy.nvim
- **plenary.nvim**: Required by goose.nvim (already installed)
- **render-markdown.nvim**: Required by goose.nvim (already installed)

### Optional Dependencies
- **gemini CLI** (v0.18.4): No longer required for google provider (can be kept for alternative workflows)
- **telescope.nvim**: Used for file picker in goose.nvim (already configured)

### Environment Prerequisites
- Shell profile file (`~/.bashrc` or `~/.zshrc`): Accessible for editing
- Neovim: Running and accessible
- Internet connection: Required for Gemini API calls
- Google Gemini API access: Free tier (15 req/min, 1500 req/day)

### Configuration Prerequisites
- Current goose CLI config backed up
- Shell profile backed up
- `GEMINI_API_KEY` currently set (verified: AIzaSyD6BiVzXhbhXFLqdbh_TmtAhiJG7EXFtqw)
- goose.nvim plugin configuration already correct (no changes needed)

## Risk Assessment

### Low Risk
- Configuration changes are reversible (backups created in Phase 1)
- goose.nvim plugin config doesn't need modification (already correct)
- Recipe files are provider-agnostic (work with both google and gemini-cli)

### Medium Risk
- Shell profile modifications could affect other tools (mitigated by using conditional export)
- API key variable name change requires verification across environment

### Mitigation Strategies
1. **Backup Strategy**: Create timestamped backups before any changes
2. **Incremental Testing**: Test each phase before proceeding to next
3. **Rollback Plan**: Document rollback procedure using backups
4. **Verification Commands**: Include explicit verification steps after each change
5. **Documentation**: Comprehensive troubleshooting section for future reference

## Rollback Procedure

If issues occur, rollback using these steps:

```bash
# 1. Restore goose CLI configuration
cp ~/.config/goose/config.yaml.backup.[timestamp] ~/.config/goose/config.yaml

# 2. Restore shell profile
cp ~/.bashrc.backup.[date] ~/.bashrc
# OR
cp ~/.zshrc.backup.[date] ~/.zshrc

# 3. Source restored profile
source ~/.bashrc
# OR
source ~/.zshrc

# 4. Verify rollback
cat ~/.config/goose/config.yaml
echo $GOOGLE_API_KEY
echo $GEMINI_API_KEY

# 5. Test goose CLI
goose --help
```

## Success Metrics

- Configuration alignment verified (100% match between goose.nvim and goose CLI)
- All integration tests passing (CLI, Neovim, recipes)
- Documentation complete with troubleshooting guide
- No regression in existing goose.nvim functionality
- Session persistence working across restarts
- Zero errors in goose sidebar operation

## Notes

- This plan uses Strategy 1 (Align to Google Provider) from research report
- Gemini CLI tool can remain installed but won't be used in the provider chain
- Recipe system already converted to `user_prompt` parameter style (spec 999)
- Configuration changes are minimal (1 file + 1 environment variable)
- Total estimated time: 3-5 hours including testing and documentation
