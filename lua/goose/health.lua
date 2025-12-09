-- Health check module for goose.nvim multi-provider configuration
-- Validates CLI tools, authentication, and provider configuration

local M = {}

-- Health check implementation using vim.health API
function M.check()
  vim.health.start("Goose CLI")

  -- Check goose CLI installation
  if vim.fn.executable("goose") == 1 then
    vim.health.ok("goose CLI found")
  else
    vim.health.error("goose CLI not found", {
      "Install goose CLI from: https://github.com/block/goose",
      "Or use package manager: pipx install goose-ai",
    })
    return -- Exit early if goose CLI missing
  end

  -- Gemini Provider Health
  vim.health.start("Gemini Provider")

  local has_gemini_api = vim.env.GEMINI_API_KEY ~= nil and vim.env.GEMINI_API_KEY ~= ""
  local has_gemini_cli = vim.fn.executable("gemini") == 1

  if has_gemini_api then
    vim.health.ok("GEMINI_API_KEY environment variable set")
  elseif has_gemini_cli then
    vim.health.ok("gemini CLI found (Google account authentication)")
  else
    vim.health.warn("Gemini provider not configured", {
      "Option 1: Set GEMINI_API_KEY environment variable",
      "  Get API key from: https://aistudio.google.com/apikey",
      "Option 2: Authenticate with gemini CLI",
      "  Install: pip install google-gemini-cli",
      "  Login: gemini auth login",
    })
  end

  -- Gemini Model Tier Validation
  local gemini_model = vim.env.GEMINI_MODEL or "gemini-3-pro-preview-11-2025"

  if gemini_model:match("^gemini%-3%-pro") then
    vim.health.ok("Using Gemini 3 Pro (default): " .. gemini_model)
    vim.health.info("Pricing: $2.00 input / $12.00 output per million tokens")
  elseif gemini_model == "gemini-2.0-flash-exp" then
    vim.health.info("Using Gemini free tier model: " .. gemini_model)
    vim.health.info("Free tier: 15 requests/min, 1500 requests/day")
  elseif gemini_model:match("^gemini%-2%.5%-pro") then
    vim.health.info("Using Gemini 2.5 Pro model: " .. gemini_model .. " (paid tier)")
  else
    vim.health.info("Using custom Gemini model: " .. gemini_model)
  end

  -- Claude Code Provider Health
  vim.health.start("Claude Code Provider")

  local has_claude_cli = vim.fn.executable("claude") == 1
  local claude_authenticated = false

  if has_claude_cli then
    vim.health.ok("claude CLI found")

    -- Check authentication by running a minimal prompt
    -- Claude CLI has no status command, so we test with a simple prompt
    local test_output = vim.fn.system('claude -p "test" 2>&1')
    local exit_code = vim.v.shell_error

    if exit_code == 0 and test_output ~= "" and not test_output:match("error") then
      vim.health.ok("Authenticated (verified with test prompt)")
      claude_authenticated = true
    else
      vim.health.warn("claude CLI not authenticated or not working", {
        "Run: claude auth login",
        "Requires Pro or Max subscription",
        "Error: " .. (test_output or "unknown"),
      })
    end

    -- Check for API key conflict
    local has_anthropic_api = vim.env.ANTHROPIC_API_KEY ~= nil and vim.env.ANTHROPIC_API_KEY ~= ""
    if has_anthropic_api then
      vim.health.error("ANTHROPIC_API_KEY conflict detected", {
        "Using claude CLI with ANTHROPIC_API_KEY set may cause billing issues",
        "ANTHROPIC_API_KEY uses pay-per-token API billing",
        "claude CLI uses subscription-based billing (Pro/Max)",
        "Unset ANTHROPIC_API_KEY to avoid API charges:",
        "  unset ANTHROPIC_API_KEY",
        "  Add to .bashrc/.zshrc to persist",
      })
    end
  else
    vim.health.warn("claude CLI not found", {
      "Install claude CLI from: https://claude.com/download",
      "Requires Claude Pro or Max subscription",
      "Authenticate with: claude auth login",
    })
  end

  -- Configuration Summary
  vim.health.start("Provider Configuration")

  local configured_providers = {}
  if has_gemini_api or has_gemini_cli then
    table.insert(configured_providers, "Gemini (" .. gemini_model .. ")")
  end
  if claude_authenticated then
    table.insert(configured_providers, "Claude Code")
  end

  if #configured_providers > 0 then
    vim.health.ok("Configured providers: " .. table.concat(configured_providers, ", "))
  else
    vim.health.error("No providers configured", {
      "At least one provider must be configured",
      "See Gemini Provider and Claude Code Provider sections above for setup",
    })
  end
end

return M
