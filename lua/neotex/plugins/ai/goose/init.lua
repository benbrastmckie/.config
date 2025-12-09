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
    -- Dynamic multi-provider detection
    local providers = {}
    local warnings = {}

    -- Detect Gemini provider (API key or CLI authentication)
    local has_gemini_api = vim.env.GEMINI_API_KEY ~= nil and vim.env.GEMINI_API_KEY ~= ""
    local has_gemini_cli = vim.fn.executable("gemini") == 1

    if has_gemini_api or has_gemini_cli then
      -- Gemini model tier selection (Gemini 3 Pro default, override via GEMINI_MODEL)
      local gemini_model = vim.env.GEMINI_MODEL or "gemini-3-pro-preview-11-2025"
      providers.google = { gemini_model }
    else
      table.insert(warnings, "Gemini: No API key (GEMINI_API_KEY) or CLI authentication found")
    end

    -- Detect Claude Code provider (CLI authentication with Pro/Max subscription)
    local has_claude_cli = vim.fn.executable("claude") == 1
    if has_claude_cli then
      -- Parse `claude /status` to check authentication and subscription
      local status_output = vim.fn.system("claude /status 2>&1")
      local is_authenticated = status_output:match("Logged in") ~= nil
      local has_subscription = status_output:match("Pro") ~= nil or status_output:match("Max") ~= nil

      if is_authenticated and has_subscription then
        providers["claude-code"] = { "claude-sonnet-4-5-20250929" }
      else
        if not is_authenticated then
          table.insert(warnings, "Claude Code: CLI installed but not authenticated (run: claude auth login)")
        elseif not has_subscription then
          table.insert(warnings, "Claude Code: Authenticated but no Pro/Max subscription detected")
        end
      end
    else
      table.insert(warnings, "Claude Code: CLI not found (install from https://claude.com/download)")
    end

    -- Warning if no providers detected
    if vim.tbl_count(providers) == 0 then
      vim.notify(
        "Goose: No providers configured\n\n" ..
        "Setup instructions:\n" ..
        "- Gemini: Set GEMINI_API_KEY or authenticate with `gemini auth login`\n" ..
        "- Claude Code: Install claude CLI and run `claude auth login`\n\n" ..
        "Run :checkhealth goose for detailed diagnostics",
        vim.log.levels.WARN,
        { title = "Goose Provider Setup Required" }
      )
      -- Fallback to default Gemini 3 Pro model
      providers.google = { "gemini-3-pro-preview-11-2025" }
    end

    require("goose").setup({
      -- Picker (auto-detect telescope if available)
      prefered_picker = "telescope", -- or 'fzf', 'mini.pick', 'snacks'

      -- CRITICAL: Disable default keymaps (managed by which-key.lua)
      default_global_keymaps = false,

      -- Default to auto mode for full agent capabilities (file editing, tool use)
      default_mode = "auto",

      -- UI Settings
      ui = {
        window_width = 0.35, -- 35% of screen width
        input_height = 0.15, -- 15% for input area
        fullscreen = false,
        layout = "right", -- Sidebar on right
        floating_height = 0.8,
        display_model = true, -- Show model in winbar
        display_goose_mode = true, -- Show mode in winbar
      },

      -- Dynamic provider configuration
      providers = providers,
    })
  end,
  cmd = { "Goose", "GooseOpenInput", "GooseClose" },
  -- Keybindings managed by which-key.lua (Phase 3)
  -- Empty keys table to prevent plugin-defined keybindings
  keys = {},
}
