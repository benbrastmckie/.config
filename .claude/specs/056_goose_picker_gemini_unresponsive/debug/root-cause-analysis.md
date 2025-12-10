# Root Cause Analysis: Goose Picker Gemini Unresponsive

**Date**: 2025-12-09
**Issue**: Goose picker with Gemini provider not responding - no output when selecting create-plan or entering text

## Summary

The Gemini 3 Pro preview model has **exceeded its daily quota limit**, causing intermittent API failures.

## Root Cause

```
[API Error: You have exhausted your daily quota on this model.]
```

The `gemini-3-pro-preview-11-2025` model used by goose.nvim has a daily request quota. When this quota is exhausted:
- API requests fail with exit code 1
- Error message: "Request failed: Command failed with exit code: Some(1)"
- goose.nvim doesn't display the underlying Gemini error to the user

## Evidence

1. **Session analysis** (`goose session export`):
   - User message `msg_20251209_1_8` (topic input) has no corresponding assistant response
   - Session shows sequential user messages without intervening assistant responses

2. **Direct CLI testing**:
   ```bash
   $ gemini --prompt "Hello"
   Error: You have exhausted your daily quota on this model.
   ```

3. **Full error trace** (from `/tmp/gemini-client-error-*.json`):
   - `ClassifierStrategy failed`
   - `Failed to generate JSON content`
   - Daily quota exhausted

## Why This Appears Intermittent

The quota system has timing-based reset mechanics:
- Requests may succeed early in a session when quota is available
- Later requests fail when quota is consumed
- After quota reset (next day), requests work again briefly

## Affected Components

1. **gemini-cli** (`~/.nix-profile/bin/gemini`) - Direct API client
2. **goose CLI** - Uses gemini-cli as provider
3. **goose.nvim** - Plugin orchestrates goose CLI calls

## Solutions

### Immediate (Use Alternative Model)

1. **Switch to free-tier model** (if available):
   ```yaml
   # ~/.config/goose/config.yaml
   GOOSE_PROVIDER: gemini-cli
   GOOSE_MODEL: gemini-2.0-flash-exp  # Free tier model
   ```

2. **Use API key instead of CLI auth**:
   - Set `GEMINI_API_KEY` environment variable
   - Uses pay-per-use billing (no daily quota)
   - Configure goose to use `google` provider instead of `gemini-cli`

3. **Switch to Claude Code provider**:
   - If Claude Pro/Max subscription is available
   - Update goose config to use `claude-code` provider

### Long-term

1. **goose.nvim enhancement**: Display actual error messages from goose stderr
2. **Quota monitoring**: Add quota status check before API calls
3. **Fallback provider**: Configure secondary provider when primary fails

## Configuration Files

- **Goose config**: `~/.config/goose/config.yaml`
- **goose.nvim setup**: `nvim/lua/neotex/plugins/ai/goose/init.lua`

## Current Config

```yaml
# ~/.config/goose/config.yaml
GOOSE_PROVIDER: gemini-cli
GOOSE_MODEL: gemini-3-pro-preview-11-2025
GOOSE_MODE: auto
```

## Recommended Fix

Edit `~/.config/goose/config.yaml`:

```yaml
GOOSE_PROVIDER: gemini-cli
GOOSE_MODEL: gemini-2.0-flash-exp  # Free tier with higher daily limits
GOOSE_MODE: auto
```

Or set environment variable to use API key:
```bash
export GEMINI_API_KEY="your-api-key-here"
```

Then update goose config:
```yaml
GOOSE_PROVIDER: google
GOOSE_MODEL: gemini-3-pro-preview-11-2025
GOOSE_MODE: auto
```
