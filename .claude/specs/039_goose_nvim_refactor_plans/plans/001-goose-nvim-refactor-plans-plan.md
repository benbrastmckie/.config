# Goose Neovim Multi-Provider Refactor Plan

## Metadata
- **Date**: 2025-12-09 (Revised)
- **Feature**: Extend goose.nvim with dynamic multi-provider support for Gemini and Claude Code
- **Status**: [COMPLETE]
- **Estimated Hours**: 5-7 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [Goose Agent Current Configuration Analysis](/home/benjamin/.config/.claude/specs/039_goose_nvim_refactor_plans/reports/001-goose-agent-configuration.md), [Gemini CLI and Claude Code Integration Research](/home/benjamin/.config/.claude/specs/039_goose_nvim_refactor_plans/reports/002-goose-llm-integration.md), [Goose Agent Refactoring Strategy](/home/benjamin/.config/.claude/specs/039_goose_nvim_refactor_plans/reports/003-goose-refactoring-strategy.md), [Gemini 3 Pro Integration with Goose CLI](/home/benjamin/.config/.claude/specs/039_goose_nvim_refactor_plans/reports/4-gemini_3_pro_goose_integration.md)

## Overview

This plan implements multi-provider support for goose.nvim, enabling automatic detection and switching between Gemini (free tier) and Claude Code (subscription) providers. The refactoring extends the current single-provider configuration with dynamic environment-based detection, health check validation, and comprehensive documentation updates.

**Current State**: goose.nvim is configured with Gemini provider only (`gemini-2.0-flash-exp`), but documentation describes a hybrid strategy using both Gemini and Claude Code.

**Target State**: Dynamic multi-provider configuration that automatically detects available authentication (GEMINI_API_KEY, claude CLI), enables provider switching via `<leader>ab`, validates configuration via `:checkhealth goose`, and provides clear setup/troubleshooting documentation.

## Success Criteria
- [ ] goose.nvim dynamically detects and configures both Gemini and Claude Code providers based on authentication
- [ ] Provider switching via `<leader>ab` shows available providers and persists selection
- [ ] `:checkhealth goose` validates provider authentication, CLI tools, and detects configuration conflicts
- [ ] README documents multi-provider setup with step-by-step instructions for both providers
- [ ] Configuration handles partial setup gracefully (only Gemini or only Claude Code available)
- [ ] No breaking changes to existing functionality (backward compatible)

## Implementation Phases

### Phase 1: Extend Provider Configuration with Dynamic Detection [COMPLETE]

**Objective**: Modify init.lua to support multi-provider configuration with automatic detection.

**Tasks**:
- [x] Read current goose init.lua configuration at `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua`
- [x] Wrap provider configuration in config function for dynamic setup
- [x] Implement Gemini model tier selection (free: `gemini-2.0-flash-exp`, advanced: `gemini-3-pro-preview-11-2025`)
- [x] Add `GEMINI_MODEL` environment variable support for user override (defaults to free tier)
- [x] Implement Gemini provider detection (check `vim.env.GEMINI_API_KEY` or `vim.fn.executable('gemini')`)
- [x] Implement Claude Code provider detection (check `vim.fn.executable('claude')` and parse `claude /status` output)
- [x] Build providers table dynamically based on detected authentication
- [x] Add warning notification when no providers detected
- [x] Add fallback to default Gemini free tier model if all detection fails
- [x] Move existing static provider config into dynamic detection logic
- [x] Test with only Gemini authentication using free tier model (current state)
- [x] Test with Gemini 3 Pro via `GEMINI_MODEL` environment variable
- [x] Test with both Gemini and Claude Code authentication

**Success Criteria**:
- [x] providers table includes google entry when GEMINI_API_KEY set or gemini CLI available
- [x] Gemini provider defaults to free tier model (`gemini-2.0-flash-exp`)
- [x] Gemini provider respects `GEMINI_MODEL` environment variable for model override
- [x] Gemini 3 Pro model (`gemini-3-pro-preview-11-2025`) configurable via environment variable
- [x] providers table includes claude-code entry when claude CLI authenticated with Pro/Max subscription
- [x] Warning displayed when no providers detected, with helpful setup instructions
- [x] Existing Gemini-only configuration continues working unchanged
- [x] Plugin loads without errors when both providers available

**Validation**:
```lua
-- Test dynamic detection
:lua print(vim.inspect(require('goose').config.providers))
-- Should show table with detected providers

-- Test warning (after unsetting all auth)
unset GEMINI_API_KEY
:e  -- Reload Neovim
-- Should show notification about no providers
```

**Dependencies**: none

### Phase 2: Implement Health Check Validation [COMPLETE]

**Objective**: Create comprehensive health check module for provider validation.

**Tasks**:
- [x] Create `/home/benjamin/.config/nvim/lua/goose/health.lua` file
- [x] Implement M.check() function with vim.health API
- [x] Add goose CLI installation check (vim.fn.executable('goose'))
- [x] Add Gemini provider section checking GEMINI_API_KEY and gemini CLI
- [x] Add Gemini model tier validation (detect paid models via pattern matching)
- [x] Add billing warning for Gemini 3 Pro models (`gemini-3-pro-*` pattern)
- [x] Add info message suggesting free tier alternative (`gemini-2.0-flash-exp`)
- [x] Add Claude Code provider section checking claude CLI and authentication status
- [x] Add API key conflict check (detect ANTHROPIC_API_KEY with claude CLI)
- [x] Use appropriate health levels (ok/warn/error/info) for each check
- [x] Add actionable remediation steps for each failure
- [x] Test health check with no providers configured
- [x] Test health check with partial configuration (Gemini free tier only)
- [x] Test health check with Gemini 3 Pro model (should show billing warning)
- [x] Test health check with full multi-provider setup
- [x] Test health check with API key conflict scenario

**Success Criteria**:
- [x] `:checkhealth goose` command runs without errors
- [x] Health check reports goose CLI status (OK or ERROR with install instructions)
- [x] Gemini provider section shows authentication status (API key or CLI login)
- [x] Gemini model tier section shows current model and pricing (free vs paid)
- [x] Billing warning displayed for Gemini 3 Pro models with pricing details ($2/$12 per million tokens)
- [x] Free tier alternative suggested when paid model detected
- [x] Claude Code provider section shows CLI and subscription status
- [x] API key conflict detected and reported as ERROR with unset instructions
- [x] Each failed check includes actionable remediation steps

**Validation**:
```vim
" Test with no authentication
:checkhealth goose
" Should show WARNs for both providers

" Test with Gemini free tier
export GEMINI_API_KEY="test-key"
:checkhealth goose
" Should show OK for Gemini, free tier model info, WARN for Claude Code

" Test with Gemini 3 Pro (paid model)
export GEMINI_API_KEY="test-key"
export GEMINI_MODEL="gemini-3-pro-preview-11-2025"
:checkhealth goose
" Should show WARN about paid model billing, suggest free tier alternative

" Test with API key conflict
export ANTHROPIC_API_KEY="test-key"
:checkhealth goose
" Should show ERROR about conflict
```

**Dependencies**: Phase 1 (requires dynamic provider configuration to test against)

### Phase 3: Update Documentation with Multi-Provider Setup [COMPLETE]

**Objective**: Update README with comprehensive multi-provider configuration, setup instructions, and troubleshooting.

**Tasks**:
- [x] Read current README at `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md`
- [x] Add "Multi-Provider Configuration" section after line 106 (Backend Configuration section)
- [x] Document automatic detection behavior for both providers
- [x] Add "Gemini Model Tiers" subsection with model comparison table (free vs paid)
- [x] Document Gemini 3 Pro setup with explicit pricing warning ($2/$12 per million tokens)
- [x] Add step-by-step Gemini setup (API key and Google account login options)
- [x] Document `GEMINI_MODEL` environment variable for model tier selection
- [x] Add step-by-step Claude Code setup (CLI install, auth login, API key unset warning)
- [x] Document .env file persistence strategy for both providers and model selection
- [x] Add "Troubleshooting Multi-Provider" subsection with common issues
- [x] Add "Optimizing Multi-Provider Usage" section with cost optimization strategy
- [x] Document when to use Gemini free tier vs Gemini 3 Pro vs Claude Code
- [x] Add recommended usage distribution (80% free tier, 20% advanced models)
- [x] Add usage examples showing provider and model tier switching workflow
- [x] Document `:checkhealth goose` as primary validation tool for model tier verification
- [x] Update existing cost considerations section to reference multi-provider and multi-tier optimization

**Success Criteria**:
- [x] README includes complete setup instructions for both Gemini and Claude Code
- [x] Gemini model tier table shows comparison (free tier vs Gemini 3 Pro)
- [x] Gemini 3 Pro pricing documented prominently with billing warnings
- [x] Each provider has authentication options documented (API key vs CLI)
- [x] Model tier selection via `GEMINI_MODEL` environment variable documented
- [x] Troubleshooting section addresses common issues (no providers, not switching, billing conflicts, unexpected charges)
- [x] Cost optimization section provides clear usage guidelines (80% free tier, 20% advanced models)
- [x] Recommended usage distribution documented for Gemini free/paid and Claude Code
- [x] Health check integration referenced in troubleshooting workflow with model tier validation
- [x] Provider and model tier persistence documented (.env files, shell profiles)

**Validation**:
```bash
# Verify documentation completeness
grep -A 10 "Multi-Provider Configuration" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md
# Should show section with automatic detection, environment setup, troubleshooting

# Verify Gemini model tier documentation
grep -A 10 "Gemini Model Tiers" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md
# Should show table with free tier, Gemini 2.5 Pro, Gemini 3 Pro comparison

# Verify Gemini 3 Pro pricing warning
grep -i "gemini-3-pro" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md
# Should show pricing details ($2/$12 per million tokens)

# Verify cost optimization section
grep -A 5 "Optimizing Multi-Provider Usage" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md
# Should show usage distribution (80% free tier, 20% advanced models)
```

**Dependencies**: Phase 2 (health check must exist to reference in troubleshooting)

### Phase 4: Add Provider Status Enhancement [COMPLETE]

**Objective**: Enhance provider switching keybinding to show status before opening picker.

**Tasks**:
- [x] Read current which-key configuration at `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` (lines 362-370)
- [x] Modify `<leader>ab` keybinding from command string to function
- [x] Implement provider status detection (check environment variables and CLI tools)
- [x] Build status message array with checkmarks for available providers
- [x] Display notification with provider status (vim.notify)
- [x] Add 1-second delay before opening provider picker (vim.defer_fn)
- [x] Test status display with no providers configured
- [x] Test status display with Gemini only
- [x] Test status display with both providers
- [x] Verify provider picker still opens after status display

**Success Criteria**:
- [x] Pressing `<leader>ab` shows provider availability status notification
- [x] Status message includes checkmarks for configured providers, X for missing ones
- [x] Notification displays for 1 second before picker opens
- [x] Provider picker functionality unchanged (still switches providers)
- [x] Status detection logic matches health check logic (consistent results)

**Validation**:
```vim
" Test with partial configuration
export GEMINI_API_KEY="test-key"
" Press <leader>ab
" Should show: "✓ Gemini (Free Tier)\n✗ Claude Code (not configured)"
" Then open provider picker
```

**Dependencies**: Phase 1 (requires multi-provider configuration to display)

### Phase 5: Integration Testing and Validation [COMPLETE]

**Objective**: Comprehensive testing of multi-provider functionality across all scenarios.

**Tasks**:
- [x] Create test script to validate all provider detection scenarios
- [x] Test Scenario 1: No authentication (neither Gemini nor Claude)
- [x] Test Scenario 2: Gemini API key only (free tier default)
- [x] Test Scenario 3: Gemini API key with Gemini 3 Pro model via `GEMINI_MODEL`
- [x] Test Scenario 4: Gemini CLI authentication only
- [x] Test Scenario 5: Claude CLI authenticated with Pro subscription
- [x] Test Scenario 6: Claude CLI authenticated with Max subscription
- [x] Test Scenario 7: Both Gemini (free tier) and Claude authenticated
- [x] Test Scenario 8: Both Gemini (3 Pro) and Claude authenticated
- [x] Test Scenario 9: API key conflict (ANTHROPIC_API_KEY set with claude CLI)
- [x] Verify Gemini model tier selection persists for session
- [x] Verify provider switching persists for session
- [x] Verify lazy loading still works (no startup time penalty)
- [x] Verify all existing keybindings unchanged
- [x] Test provider picker shows both providers when available
- [x] Run health check in each scenario and verify output (including model tier warnings)

**Success Criteria**:
- [x] All 9 authentication scenarios handled correctly (including Gemini 3 Pro)
- [x] Provider table matches available authentication in each scenario
- [x] Gemini model tier correctly detected and configured (free tier default)
- [x] Health check results accurate for each scenario (including billing warnings)
- [x] Gemini 3 Pro billing warning displayed when configured
- [x] Provider switching works in multi-provider scenarios
- [x] Model tier selection persists correctly via `GEMINI_MODEL` environment variable
- [x] No errors in Neovim startup or plugin loading
- [x] Lazy loading verified (goose only loads on :Goose command)
- [x] Existing functionality unchanged (backward compatible)

**Validation**:
```bash
# Run automated test script
bash test_goose_providers.sh

# Manual validation
# 1. Check startup time: nvim --startuptime startup.log
# 2. Verify goose not loaded: :lua print(package.loaded['goose'])
# 3. Trigger load: :Goose
# 4. Verify providers: :lua print(vim.inspect(require('goose').config.providers))
# 5. Verify model tier: :lua print(require('goose').config.providers.google.model)
# 6. Test Gemini 3 Pro: export GEMINI_MODEL="gemini-3-pro-preview-11-2025" && nvim
# 7. Test switching: <leader>ab (select provider from picker)
# 8. Verify health: :checkhealth goose (should show model tier and billing warnings)
```

**Dependencies**: Phase 1, Phase 2, Phase 3, Phase 4 (requires all components implemented)

## Testing Strategy

**Unit Testing**:
- Provider detection logic (environment variables and CLI checks)
- Health check validation functions
- Status display formatting

**Integration Testing**:
- Multi-provider configuration with goose.nvim setup
- Provider switching via telescope picker
- Lazy loading behavior preservation
- Keybinding integration via which-key

**Scenario Testing**:
- All 7 authentication scenarios documented in Phase 5
- Edge cases (missing CLIs, invalid API keys, subscription lapsed)
- Configuration conflicts (API keys vs subscriptions)

**Regression Testing**:
- Existing Gemini-only configuration continues working
- No startup time increase
- All existing keybindings functional
- UI configuration unchanged

## Risk Mitigation

**Risk 1: Breaking Existing Configuration**
- **Mitigation**: Additive-only changes, maintain backward compatibility
- **Fallback**: Default to Gemini provider if detection fails
- **Testing**: Verify existing Gemini-only setup continues working in Phase 1

**Risk 2: API Key Conflict (Billing vs Subscription)**
- **Mitigation**: Health check explicitly detects ANTHROPIC_API_KEY with claude CLI
- **Prevention**: Documentation emphasizes unsetting API key for subscriptions
- **Testing**: Scenario 7 in Phase 5 validates conflict detection

**Risk 3: Claude CLI Authentication Parsing**
- **Mitigation**: Graceful fallback if `claude /status` output format changes
- **Prevention**: Use pattern matching for Pro/Max detection (handles variations)
- **Testing**: Test with actual Claude CLI output in multiple subscription states

**Risk 4: Startup Time Penalty**
- **Mitigation**: Keep detection in config function (runs on :Goose, not startup)
- **Prevention**: Use vim.fn.executable() (fast) instead of vim.fn.system() when possible
- **Testing**: Measure startup time before/after refactor

## Rollback Plan

If critical issues discovered after implementation:

1. **Immediate Rollback**: Restore init.lua to single-provider static configuration
2. **Partial Rollback**: Keep multi-provider config but disable dynamic detection
3. **Documentation Rollback**: Revert README to original state

**Rollback Command**:
```bash
# Restore from git history
git checkout HEAD~1 nvim/lua/neotex/plugins/ai/goose/init.lua
git checkout HEAD~1 nvim/lua/neotex/plugins/ai/goose/README.md
```

## Dependencies and Prerequisites

**External Dependencies**:
- goose CLI (already installed, validated in research)
- Gemini CLI (optional, for Google account authentication)
- Claude CLI (optional, for Claude Code pass-through)

**Configuration Dependencies**:
- lazy.nvim plugin manager (already configured)
- telescope.nvim for provider picker (already configured)
- which-key.nvim for keybindings (already configured)
- render-markdown.nvim for goose output (already configured)

**Authentication Dependencies** (user setup):
- GEMINI_API_KEY environment variable OR gemini CLI authentication
- Claude CLI installed and authenticated (for Claude Code support)

## Post-Implementation Validation

After completing all phases:

1. Run `:checkhealth goose` - all checks should pass or provide clear remediation
2. Test provider switching workflow - both providers available and selectable
3. Verify no startup time regression - goose lazy loads on command
4. Validate documentation accuracy - follow README setup steps for both providers
5. Test with multiple Neovim instances - provider selection persists per-session
6. Verify goose session persistence - sessions saved/restored correctly with either provider

## Notes

**Design Decisions**:
- Dynamic detection over static configuration (enables automatic multi-provider support)
- Health check integration for self-documenting validation (reduces support burden)
- Backward compatibility priority (additive-only changes, no breaking changes)
- Documentation-driven approach (comprehensive setup/troubleshooting guides)

**Future Enhancements** (not in scope):
- Provider usage tracking (count requests toward free tier limits)
- Automatic provider selection based on task complexity
- Cost analytics dashboard (show Gemini vs Claude usage distribution)
- Session-level provider persistence (remember provider per project)

**References**:
- [goose.nvim GitHub](https://github.com/azorng/goose.nvim) - Upstream plugin repository
- [Goose CLI Providers Guide](https://block.github.io/goose/docs/guides/cli-providers/) - Pass-through provider documentation
- [Gemini CLI Authentication](https://google-gemini.github.io/gemini-cli/docs/get-started/authentication.html) - Gemini auth setup
- [Claude Code with Max](https://support.claude.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan) - Claude Code subscription integration
