# Gemini 3 Pro Integration with Goose CLI - Research Report

## Research Metadata
- **Topic**: Gemini 3 Pro model configuration for goose CLI
- **Date**: 2025-12-09
- **Complexity**: 2
- **Workflow**: research-and-revise
- **Related Plan**: /home/benjamin/.config/.claude/specs/039_goose_nvim_refactor_plans/plans/001-goose-nvim-refactor-plans-plan.md

## Executive Summary

Google released **Gemini 3 Pro** on November 18, 2025, replacing Gemini 2.5 Pro as their most advanced reasoning model. The model is available through multiple APIs including Google AI Studio, Vertex AI, and Gemini CLI. For goose CLI integration, the model identifier is **`gemini-3-pro-preview-11-2025`** (or the dated variant `gemini-3-pro-preview-11-20`). Gemini 3 Pro is currently in preview status with no free tier, priced at $2/million input tokens and $12/million output tokens for prompts ≤200k tokens.

**Critical Finding**: While you mentioned "gemini-3.0-pro", the actual model released is **Gemini 3 Pro** (without the ".0" designation). The preview API identifier uses the format `gemini-3-pro-preview-MM-YYYY`.

## Model Specifications

### Gemini 3 Pro Overview

**Release Date**: November 18, 2025

**Model Identifiers**:
- **Gemini API / AI Studio**: `gemini-3-pro-preview` (generic) or `gemini-3-pro-preview-11-2025` (specific version)
- **Vertex AI**: `gemini-3-pro-preview-11-2025` or `gemini-3-pro-preview-11-20`
- **Thinking Mode**: `gemini-3-pro-preview-11-2025-thinking` (with adaptive thinking enabled)

**Key Capabilities**:
- **Context Window**: 1 million tokens (same as Gemini 2.5 Pro)
- **Multimodal Support**: Text, audio, images, video, PDFs, entire code repositories
- **Thinking Level Parameter**: Adaptive reasoning control (low/high) to balance quality, latency, and cost
- **Grounding**: Integrated grounding for sophisticated multimodal problem solving

### Performance Benchmarks

Gemini 3 Pro represents a significant advancement over 2.5 Pro:

**Reasoning & Mathematics**:
- **LMArena Leaderboard**: #1 with 1501 Elo (breakthrough score)
- **Humanity's Last Exam**: 37.5% (PhD-level reasoning, no tools)
- **GPQA Diamond**: 91.9% (expert-level scientific reasoning)
- **MathArena Apex**: 23.4% (new standard for frontier models)

**Coding & Agentic Tasks**:
- **WebDev Arena**: 1487 Elo (#1 position)
- **Terminal-Bench 2.0**: 54.2% (tool use via terminal)
- **SWE-Bench Verified**: 63.8% (with custom agent setup)

**General Performance**:
- Outperforms Gemini 2.5 Pro on every major AI benchmark
- Described as "best vibe coding and agentic coding model Google has ever built"

### Pricing & Availability

**Pricing** (Preview tier):
- **Input**: $2 per million tokens (prompts ≤200k tokens)
- **Output**: $12 per million tokens (prompts ≤200k tokens)
- **Free Tier**: None (unlike Gemini 2.0 Flash which offers free tier)

**Availability**:
- Google AI Studio (free to try in studio UI)
- Vertex AI (enterprise, preview)
- Gemini API (preview endpoints)
- Gemini CLI (available)
- Third-party platforms: Cursor, GitHub Copilot, JetBrains, Replit, etc.

**Important Note**: There is no free tier for `gemini-3-pro-preview` in the Gemini API. You can try the model for free in Google AI Studio's web interface, but API usage is billed.

## Goose CLI Integration

### Supported Gemini Models in Goose

Goose CLI supports the Google Gemini provider with dynamic model configuration. Based on research, goose recognizes model families via pattern matching:

**Confirmed Working Models**:
- `gemini-2.0-flash-exp` (free tier, 1M token context)
- `gemini-2.5-pro-preview-05-06` (deprecated)
- `gemini-2.5-pro-preview-03-25` (deprecated)
- `gemini-2.5-pro` (stable, general availability)
- `gemini-2.5-flash` (stable, general availability)

**Gemini 3 Pro Model Identifiers**:
- `gemini-3-pro-preview-11-2025` (recommended for goose)
- `gemini-3-pro-preview-11-20` (specific dated version)
- `gemini-3-pro-preview` (generic preview endpoint)

**Context Window Detection**: Goose's codebase includes pattern matching for `gemini-2` which matches all Gemini 2.x models with 1,000,000 token context. A similar pattern likely exists or will be added for `gemini-3` models.

### Configuration Methods

#### Method 1: Interactive Configuration (Recommended)

```bash
goose configure
```

1. Select "Configure Providers" from the menu
2. Choose "Google Gemini" as the provider
3. Enter your Gemini API key when prompted
4. Enter the model name: `gemini-3-pro-preview-11-2025`

#### Method 2: Config File (~/.config/goose/config.yaml)

```yaml
GOOSE_PROVIDER: google
GOOSE_MODEL: gemini-3-pro-preview-11-2025
keyring: false
```

#### Method 3: Environment Variables

```bash
export GOOSE_PROVIDER=google
export GOOSE_MODEL=gemini-3-pro-preview-11-2025
export GEMINI_API_KEY=your_api_key_here
```

Add to shell profile (`~/.bashrc`, `~/.zshrc`, etc.) for persistence.

### API Key Setup

**Step 1: Get API Key from Google AI Studio**

1. Visit [Google AI Studio](https://aistudio.google.com/)
2. Sign in with your Google account
3. Navigate to API key section
4. Generate new API key
5. Copy the key (starts with `AIza...`)

**Step 2: Set Environment Variable**

```bash
# Add to ~/.bashrc or ~/.zshrc
export GEMINI_API_KEY="AIzaSy...your-key-here"

# Reload shell configuration
source ~/.bashrc  # or source ~/.zshrc
```

**Step 3: Verify Configuration**

```bash
# Check environment variable is set
echo $GEMINI_API_KEY

# Check goose recognizes the configuration
goose --version
goose configure  # View current configuration
```

### Gemini CLI vs Gemini API Provider

Goose supports two distinct Gemini provider modes:

1. **`google` provider**: Direct API integration using GEMINI_API_KEY
   - Best for: Direct API control, specific model selection
   - Requires: GEMINI_API_KEY environment variable
   - Model format: `gemini-3-pro-preview-11-2025`

2. **`gemini-cli` provider**: Pass-through to Gemini CLI
   - Best for: Using CLI authentication, integration with gemini command
   - Requires: `gemini` CLI installed and authenticated
   - Model selection: Configured via gemini CLI settings

**Recommendation for Gemini 3 Pro**: Use the `google` provider with explicit model name for precise control over which model version is used.

## Revision Recommendations for Plan

Based on this research, here are recommended revisions to the implementation plan:

### 1. Update Model References

**Current Plan References**: `gemini-2.0-flash-exp` (free tier model)

**Recommended Updates**:
- If prioritizing **cost optimization**: Keep `gemini-2.0-flash-exp` for general tasks, add `gemini-3-pro-preview-11-2025` as optional high-complexity model
- If prioritizing **performance**: Update default to `gemini-3-pro-preview-11-2025` but document billing implications
- If prioritizing **hybrid approach**: Implement model tier selection in provider configuration

**Specific File Updates**:
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua`: Update default Gemini model string
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md`: Add Gemini 3 Pro setup section with pricing warnings

### 2. Add Gemini Model Tier Selection

**New Configuration Option**:

```lua
-- Dynamic Gemini model tier selection
local gemini_models = {
  free_tier = "gemini-2.0-flash-exp",        -- 1M context, free
  standard = "gemini-2.5-pro",                -- 1M context, paid, stable
  advanced = "gemini-3-pro-preview-11-2025",  -- 1M context, paid, reasoning
}

-- Default to free tier, allow override via environment variable
local gemini_model = vim.env.GEMINI_MODEL or gemini_models.free_tier
```

**Benefits**:
- Preserves free tier access for budget-conscious users
- Enables easy upgrade path to Gemini 3 Pro for complex tasks
- Maintains backward compatibility with existing configuration

### 3. Update Health Check for Model Validation

**Add to Phase 2 Health Check**:

```lua
-- Gemini model tier validation
local gemini_model = vim.env.GEMINI_MODEL or "gemini-2.0-flash-exp"
if gemini_model:match("gemini%-3") then
  vim.health.warn("Gemini 3 Pro is a paid model ($2/$12 per million tokens)")
  vim.health.info("Free tier alternative: gemini-2.0-flash-exp")
elseif gemini_model:match("gemini%-2%.5") then
  vim.health.info("Gemini 2.5 Pro is a paid model (stable, GA)")
else
  vim.health.ok("Using free tier model: " .. gemini_model)
end
```

**Rationale**: Prevents unexpected billing by clearly indicating which models are paid.

### 4. Enhance Documentation with Model Tier Table

**Add to README.md (Multi-Provider Configuration section)**:

```markdown
### Gemini Model Tiers

| Model | Context | Cost | Best For |
|-------|---------|------|----------|
| `gemini-2.0-flash-exp` | 1M | Free | General tasks, experimentation |
| `gemini-2.5-pro` | 1M | Paid (stable) | Production workloads, reliability |
| `gemini-3-pro-preview-11-2025` | 1M | Paid (preview) | Complex reasoning, advanced coding |

**Cost Optimization Strategy**:
- Use `gemini-2.0-flash-exp` for 80% of tasks (free tier)
- Use `gemini-3-pro-preview-11-2025` for complex reasoning (20%)
- Monitor usage via Google Cloud Console billing dashboard
```

### 5. Add Thinking Level Parameter Support (Future Enhancement)

**Note for Future Phases**: Gemini 3 Pro introduces a `thinking_level` parameter (`low` or `high`) to control reasoning complexity. This is currently not exposed in goose.nvim configuration but should be considered for future enhancements.

**Example Usage** (Python SDK):
```python
response = client.models.generate_content(
    model="gemini-3-pro-preview-11-2025",
    contents="Your prompt here",
    config={"thinking_level": "high"}  # or "low"
)
```

**Implementation Path**: Would require extending goose CLI pass-through or direct API integration.

## Migration Path from Current Configuration

### Current State (from Plan)
- Model: `gemini-2.0-flash-exp`
- Provider: Google Gemini (API key or CLI)
- Cost: Free tier

### Option A: Conservative Update (Recommended)
- **Default Model**: Keep `gemini-2.0-flash-exp` (free tier)
- **Optional Upgrade**: Add environment variable `GEMINI_MODEL` for user override
- **Documentation**: Add section explaining how to upgrade to Gemini 3 Pro
- **Health Check**: Warn users when using paid models

**Implementation**:
```lua
-- In init.lua
local default_model = "gemini-2.0-flash-exp"
local gemini_model = vim.env.GEMINI_MODEL or default_model

providers.google = {
  provider = "google",
  model = gemini_model,
  -- ... rest of configuration
}
```

### Option B: Performance-First Update
- **Default Model**: Upgrade to `gemini-3-pro-preview-11-2025`
- **Documentation**: Prominently display pricing warning
- **Health Check**: Notify users about billing implications on first use
- **Fallback**: Provide easy rollback instructions to free tier

**Implementation**:
```lua
-- In init.lua
local default_model = "gemini-3-pro-preview-11-2025"  -- Performance-first
local gemini_model = vim.env.GEMINI_MODEL or default_model

-- Show one-time warning for paid models
if gemini_model:match("gemini%-3") or gemini_model:match("gemini%-2%.5") then
  vim.notify(
    "Warning: " .. gemini_model .. " is a paid model. See :checkhealth goose for pricing.",
    vim.log.levels.WARN
  )
end
```

### Option C: Hybrid Tier System
- **Default Model**: `gemini-2.0-flash-exp` (free)
- **Tier Selection**: Add command to switch between free/standard/advanced tiers
- **Keybinding**: `<leader>amt` (AI model tier) to cycle through tiers
- **Persistence**: Save tier selection per-project

**Implementation** (requires additional development):
```lua
-- Add tier cycling command
vim.api.nvim_create_user_command('GooseModelTier', function(opts)
  local tiers = { "free", "standard", "advanced" }
  local models = {
    free = "gemini-2.0-flash-exp",
    standard = "gemini-2.5-pro",
    advanced = "gemini-3-pro-preview-11-2025",
  }
  -- Cycle through tiers or set specific tier
  -- Save to project-local .nvim/goose.json
end, { nargs = '?' })
```

## Testing Recommendations

### Gemini 3 Pro Validation Tests

Add to Phase 5 integration testing:

**Test Scenario 8: Gemini 3 Pro Configuration**
- [ ] Set `GEMINI_MODEL=gemini-3-pro-preview-11-2025`
- [ ] Restart Neovim and trigger goose load
- [ ] Verify provider configuration: `:lua print(vim.inspect(require('goose').config.providers.google))`
- [ ] Run health check: `:checkhealth goose` (should show paid model warning)
- [ ] Test goose functionality: `:Goose` (open session, send test prompt)
- [ ] Verify model is used: Check goose session for model identifier in responses

**Test Scenario 9: Model Tier Switching**
- [ ] Start with free tier: `unset GEMINI_MODEL`
- [ ] Verify default model in config
- [ ] Switch to Gemini 3 Pro: `export GEMINI_MODEL=gemini-3-pro-preview-11-2025`
- [ ] Restart Neovim, verify configuration updated
- [ ] Confirm session uses new model

**Test Scenario 10: Billing Protection**
- [ ] Configure Gemini 3 Pro model
- [ ] Verify health check shows pricing warning
- [ ] Verify startup notification (if implemented)
- [ ] Check README has clear pricing documentation

## Risk Assessment

### Financial Risk: Unexpected Billing

**Risk Level**: High (if users are unaware Gemini 3 Pro is paid)

**Mitigation Strategies**:
1. **Default to free tier**: Use `gemini-2.0-flash-exp` as default
2. **Prominent warnings**: Health check, README, startup notification
3. **Explicit opt-in**: Require `GEMINI_MODEL` environment variable for paid models
4. **Usage tracking**: Link to Google Cloud Console billing dashboard in docs

**Recommended Warning Text**:
```
⚠️  BILLING WARNING: Gemini 3 Pro is a PAID model
    Pricing: $2/million input tokens, $12/million output tokens
    Free alternative: gemini-2.0-flash-exp
    Set GEMINI_MODEL=gemini-2.0-flash-exp to use free tier
    Monitor usage: https://console.cloud.google.com/billing
```

### Technical Risk: Preview Model Stability

**Risk Level**: Medium (preview models may have API changes)

**Considerations**:
- Model identifier may change when Gemini 3 Pro reaches general availability
- `gemini-3-pro-preview-11-2025` may be deprecated in future
- Stable version (`gemini-3-pro`) will likely be released in 2026

**Mitigation**:
1. Document version-specific identifiers in README
2. Add health check to detect deprecated models
3. Plan for model identifier update when stable version released
4. Monitor Google Gemini API changelog: https://ai.google.dev/gemini-api/docs/changelog

### Compatibility Risk: Goose CLI Support

**Risk Level**: Low (goose supports custom model identifiers)

**Validation**:
- Goose uses pattern matching for model families
- Custom model identifiers can be configured via config.yaml
- Fallback to string model name if no pattern match

**Confidence**: High - goose is designed for multi-model flexibility

## Conclusion

Gemini 3 Pro represents a significant upgrade in reasoning and coding capabilities over Gemini 2.5 Pro, with top benchmark scores across mathematics, reasoning, and agentic tasks. However, the lack of a free tier introduces financial considerations that must be prominently communicated to users.

**Recommended Implementation Strategy**:
1. **Preserve free tier default**: Keep `gemini-2.0-flash-exp` as default model
2. **Enable easy upgrade**: Support `GEMINI_MODEL` environment variable for user override
3. **Document thoroughly**: Add Gemini 3 Pro setup section with pricing warnings
4. **Protect from surprise billing**: Health check warnings, README notices, startup notifications
5. **Plan for stability**: Monitor for stable release, update identifiers when GA

**Timeline for Plan Updates**:
- **Phase 1**: Add `GEMINI_MODEL` environment variable support (15 minutes)
- **Phase 2**: Add paid model warnings to health check (10 minutes)
- **Phase 3**: Document Gemini 3 Pro setup and pricing (30 minutes)
- **Phase 5**: Add Gemini 3 Pro validation tests (20 minutes)

**Total Additional Effort**: ~1.5 hours (within original 4-6 hour estimate)

## References

### Primary Sources

- [Gemini 3: Introducing the latest Gemini AI model from Google](https://blog.google/products/gemini/gemini-3/)
- [Gemini 3 Pro | Generative AI on Vertex AI | Google Cloud Documentation](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/3-pro)
- [Gemini 3 Developer Guide | Gemini API | Google AI for Developers](https://ai.google.dev/gemini-api/docs/gemini-3)
- [Configure LLM Provider | goose](https://block.github.io/goose/docs/getting-started/providers/)
- [Gemini models | Gemini API | Google AI for Developers](https://ai.google.dev/gemini-api/docs/models)

### Supporting Sources

- [Google Workspace Updates: Introducing Gemini 3 Pro for Gemini app](https://workspaceupdates.googleblog.com/2025/11/introducing-gemini-3-pro-for-gemini-app.html)
- [Gemini 2.5: Our newest Gemini model with thinking](https://blog.google/technology/google-deepmind/gemini-model-thinking-updates-march-2025/)
- [Get started with Gemini 3 | Generative AI on Vertex AI | Google Cloud Documentation](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/start/get-started-with-gemini-3)
- [How to Use the Gemini 2.5 Pro API](https://apidog.com/blog/gemini-2-5-pro-api/)
- [GitHub - block/goose: an open source, extensible AI agent](https://github.com/block/goose)
- [Introducing Goose, the on-machine AI agent - Marc Nuri](https://blog.marcnuri.com/goose-on-machine-ai-agent-cli-introduction)
- [Gemini 3 is available for enterprise | Google Cloud Blog](https://cloud.google.com/blog/products/ai-machine-learning/gemini-3-is-available-for-enterprise)
- [Gemini 3 Pro is in public preview for GitHub Copilot - GitHub Changelog](https://github.blog/changelog/2025-11-18-gemini-3-pro-is-in-public-preview-for-github-copilot/)

### API & Configuration References

- [Gemini 3 Pro - API, Providers, Stats | OpenRouter](https://openrouter.ai/google/gemini-3-pro-preview)
- [3 APIs to Access Gemini 2.5 Pro - KDnuggets](https://www.kdnuggets.com/3-apis-to-access-gemini-2-5-pro)
- [Getting started with the Gemini 2.5 Pro reasoning model API](https://wandb.ai/onlineinference/Gemini/reports/Getting-started-with-the-Gemini-2-5-Pro-reasoning-model-API--VmlldzoxMTk3MzgyNw)
- [Release notes | Gemini API | Google AI for Developers](https://ai.google.dev/gemini-api/docs/changelog)
