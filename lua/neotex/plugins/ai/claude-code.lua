return {
  "greggh/claude-code.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    -- Window configuration
    window = {
      split_ratio = 0.40,        -- 40% width, matching old config
      position = "vertical",     -- Vertical split (sidebar)
      enter_insert = true,       -- Auto-enter insert mode
      hide_numbers = true,       -- Clean terminal appearance
      hide_signcolumn = true,
    },

    -- File refresh detection
    refresh = {
      enable = true,             -- Enable file change detection
      updatetime = 100,
      timer_interval = 1000,
      show_notifications = true, -- Show when files are refreshed
    },

    -- Git configuration
    git = {
      use_git_root = true,       -- Set working directory to git root
    },

    -- Shell configuration to suppress pushd output
    shell = {
      separator = "&&",
      pushd_cmd = "pushd >/dev/null 2>&1",  -- Suppress pushd output
      popd_cmd = "popd >/dev/null 2>&1",    -- Suppress popd output
    },

    -- Base command
    command = "claude",

    -- Command variants for different modes
    command_variants = {
      continue = "--continue",
      resume = "--resume",
      verbose = "--verbose",
    },

    -- Keymaps configuration - disabled here as we define them in keys
    keymaps = {
      toggle = {
        normal = false,          -- Disable default keymaps
        terminal = false,
      },
      window_navigation = true,  -- Keep window navigation enabled
      scrolling = true,          -- Keep scrolling enabled
    },
  },

  keys = {
    -- Main toggle with <C-c> to match old behavior
    { "<C-c>", "<cmd>ClaudeCode<CR>", desc = "Toggle Claude Code", mode = { "n", "i", "v", "t" } },

    -- Leader mappings for additional functionality
    { "<leader>ac", "<cmd>ClaudeCode<CR>", desc = "Toggle Claude Code" },
    { "<leader>acc", "<cmd>ClaudeCodeContinue<CR>", desc = "Continue Claude conversation" },
    { "<leader>acr", "<cmd>ClaudeCodeResume<CR>", desc = "Resume Claude conversation (picker)" },
    { "<leader>acv", "<cmd>ClaudeCodeVerbose<CR>", desc = "Claude Code with verbose logging" },
  },

  config = function(_, opts)
    require("claude-code").setup(opts)

    -- Configure terminal behavior to match old setup
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "*claude*",
      callback = function()
        -- Make buffer unlisted to prevent it from appearing in tabs/bufferline
        vim.bo.buflisted = false

        -- Keep escape within terminal instead of exiting to normal mode
        vim.api.nvim_buf_set_keymap(0, "t", "<Esc>", "<Esc>", { noremap = true })

        -- Use double escape or leader+escape to exit terminal mode
        vim.api.nvim_buf_set_keymap(0, "t", "<Esc><Esc>", "<C-\\><C-n>", { noremap = true, desc = "Exit terminal mode" })
        vim.api.nvim_buf_set_keymap(0, "t", "<leader><Esc>", "<C-\\><C-n>", { noremap = true, desc = "Exit terminal mode" })

        -- Additional <C-c> mapping in terminal mode for consistency
        vim.api.nvim_buf_set_keymap(0, "t", "<C-c>", "<cmd>ClaudeCode<CR>", { noremap = true, desc = "Toggle Claude Code" })
      end,
    })
  end,
}
