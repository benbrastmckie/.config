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
      -- Reference: https://github.com/azorng/goose.nvim/issues/82
      -- window_type = "split": Enables split window mode
      --   - Integrates with <C-h/l> split navigation keybindings
      --   - Consistent UX with neo-tree, toggleterm, lean.nvim sidebars
      --   - Works with standard Neovim window management commands
      ui = {
        window_type = "split", -- Enable split window mode (instead of floating)
        window_width = 0.35, -- 35% of screen width
        input_height = 0.15, -- 15% for input area
        fullscreen = false,
        layout = "right", -- Right sidebar positioning (botright vsplit)
        floating_height = 0.8, -- Retained for compatibility
        display_model = true, -- Show model in winbar
        display_goose_mode = true, -- Show mode in winbar
      },

      -- Dynamic provider configuration
      providers = providers,
    })

    -- Fix: Add visible horizontal separator between goose output and input panes
    -- The native WinSeparator is invisible by default, so we add a winbar to the
    -- input window to create a visible thin divider line
    local function set_goose_input_winbar()
      local win = vim.api.nvim_get_current_win()
      local width = vim.api.nvim_win_get_width(win)
      -- Create line exactly fitting window width (no truncation needed)
      vim.wo[win].winbar = "%#WinSeparator#" .. string.rep("─", width)
    end

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "goose-input" },
      callback = set_goose_input_winbar,
    })

    -- Update winbar on window resize
    vim.api.nvim_create_autocmd("WinResized", {
      callback = function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.bo[buf].filetype
          if ft == "goose-input" then
            local width = vim.api.nvim_win_get_width(win)
            vim.wo[win].winbar = "%#WinSeparator#" .. string.rep("─", width)
          end
        end
      end,
    })
  end,
  cmd = { "Goose", "GooseOpenInput", "GooseClose" },
  -- Keybindings managed by which-key.lua (Phase 3)
  -- Empty keys table to prevent plugin-defined keybindings
  keys = {},
}
