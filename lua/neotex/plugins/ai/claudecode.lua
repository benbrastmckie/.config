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
    -- Main toggle with <C-a> for Claude Code (works in all modes)
    { "<C-a>", "<cmd>ClaudeCode<CR>", desc = "Toggle Claude Code", mode = { "n", "i", "v", "t" } },
  },

  config = function(_, opts)
    require("claude-code").setup(opts)

    -- Helper function to get visual selection
    local function get_visual_selection()
      -- Get the visual selection marks
      local start_line, start_col = unpack(vim.api.nvim_buf_get_mark(0, '<'))
      local end_line, end_col = unpack(vim.api.nvim_buf_get_mark(0, '>'))
      
      -- Get the lines
      local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
      
      -- Handle single line selection
      if #lines == 1 then
        lines[1] = string.sub(lines[1], start_col + 1, end_col + 1)
      else
        -- Handle multi-line selection
        if #lines > 0 then
          lines[1] = string.sub(lines[1], start_col + 1)
          if #lines > 1 then
            lines[#lines] = string.sub(lines[#lines], 1, end_col + 1)
          end
        end
      end
      
      return table.concat(lines, '\n')
    end

    -- Function to send visual selection to Claude Code
    local function send_visual_to_claude()
      local selection = get_visual_selection()
      
      -- First ensure Claude Code terminal is open
      vim.cmd('ClaudeCode')
      
      -- Wait a bit for terminal to be ready
      vim.defer_fn(function()
        -- Find the Claude terminal buffer
        local claude_bufnr = nil
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          local bufname = vim.api.nvim_buf_get_name(bufnr)
          if bufname:match("claude") and vim.bo[bufnr].buftype == "terminal" then
            claude_bufnr = bufnr
            break
          end
        end
        
        if claude_bufnr then
          -- Get the terminal job id
          local chan = vim.bo[claude_bufnr].channel
          if chan and chan > 0 then
            -- Send the selection to the terminal
            vim.api.nvim_chan_send(chan, selection)
            -- Optionally add a newline to submit
            -- vim.api.nvim_chan_send(chan, '\n')
          end
        else
          vim.notify("Claude Code terminal not found", vim.log.levels.WARN)
        end
      end, 200)
    end

    -- Create commands for visual selection
    vim.api.nvim_create_user_command('ClaudeCodeSendVisual', send_visual_to_claude, { 
      range = true,
      desc = 'Send visual selection to Claude Code' 
    })

    -- Configure terminal behavior to match old setup
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "*claude*",
      callback = function()
        -- Make buffer unlisted to prevent it from appearing in tabs/bufferline
        vim.bo.buflisted = false
        
        -- Additional <C-a> mapping in terminal mode for consistency
        vim.api.nvim_buf_set_keymap(0, "t", "<C-a>", "<cmd>ClaudeCode<CR>", { noremap = true, desc = "Toggle Claude Code" })
      end,
    })
  end,
}
