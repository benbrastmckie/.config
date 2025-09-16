return {
  "coder/claudecode.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    -- Port range for WebSocket connection
    port_range = { min = 10000, max = 65535 },
    auto_start = true,
    log_level = "info",
    
    -- Terminal configuration
    terminal = {
      split_side = "right",
      split_width_percentage = 0.40,
      provider = "native",
      auto_close = true,  -- Auto-close terminal when switching away
      show_native_term_exit_tip = false,  -- Disable the "Press Ctrl-\ Ctrl-N" message
    },
    
    -- Diff configuration - minimize diff disruption
    diff_opts = {
      auto_close_on_accept = true,  -- Auto-close diff after accepting
      vertical_split = false,  -- Use horizontal split to be less intrusive
      open_in_current_tab = false,  -- Don't take over current tab
      keep_terminal_focus = true,  -- Keep focus on terminal, not diff
    },
    
    -- Don't auto-focus terminal after sending content
    focus_after_send = false,
  },
  
  keys = {
    -- Main toggle with <C-c> - uses built-in ClaudeCodeFocus for smart toggle
    { "<C-c>", "<cmd>ClaudeCodeFocus<CR>", desc = "Toggle Claude Code sidebar", mode = { "n", "i", "v", "t" } },
    
    -- Additional convenience mappings
    { "<leader>ac", "<cmd>ClaudeCode<CR>", desc = "Start/restart Claude Code" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<CR>", desc = "Focus/toggle Claude Code" },
    { "<leader>as", "<cmd>ClaudeCodeSend<CR>", desc = "Send selection to Claude", mode = "v" },
    { "<leader>aa", "<cmd>ClaudeCodeAdd %<CR>", desc = "Add current file to Claude context" },
  },
  
  config = function(_, opts)
    require("claudecode").setup(opts)
    
    -- Configure escape key behavior in Claude Code terminal
    -- This keeps escape within the terminal instead of exiting to Neovim normal mode
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "*claude*",
      callback = function()
        -- Make buffer unlisted to prevent it from appearing in tabs/bufferline
        -- This keeps the buffer accessible via <C-c> but not via :bnext/:bprev or tabs
        vim.bo.buflisted = false
        
        -- In Claude Code terminal, don't let escape exit to normal mode
        -- Use Ctrl-\ Ctrl-n if you need to exit to normal mode
        vim.api.nvim_buf_set_keymap(0, "t", "<Esc>", "<Esc>", { noremap = true })
        
        -- Alternative: Use double escape or leader+escape to exit terminal mode
        vim.api.nvim_buf_set_keymap(0, "t", "<Esc><Esc>", "<C-\\><C-n>", { noremap = true, desc = "Exit terminal mode" })
        vim.api.nvim_buf_set_keymap(0, "t", "<leader><Esc>", "<C-\\><C-n>", { noremap = true, desc = "Exit terminal mode" })
      end,
    })
  end,
}