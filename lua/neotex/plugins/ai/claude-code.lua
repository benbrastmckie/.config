return {
  "coder/claudecode.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    -- Port range for WebSocket connection
    port_range = { min = 10000, max = 65535 },
    auto_start = true,     -- Automatically start Claude Code
    log_level = "info",    -- Logging level
    
    -- Terminal configuration
    terminal = {
      split_side = "right",  -- Open terminal on right side (matches your preference)
      split_width_percentage = 0.40,  -- Set sidebar width to 40% of screen (default is 30%)
      provider = "native",   -- Use native terminal (or "snacks" if you have it)
      auto_close = true,     -- Auto-close terminal when Claude Code exits
    },
    
    -- Diff configuration - attempt to disable diff functionality
    diff_opts = {
      auto_close_on_accept = true,
      vertical_split = false,       -- Use horizontal split instead of vertical
      open_in_current_tab = true,
      keep_terminal_focus = true,   -- Keep focus on terminal
      show_diff_stats = false,      -- Disable diff statistics
      enabled = false,              -- Try to disable diff functionality entirely
    },
  },
  
  -- NOTE: Key mappings are now defined in which-key.lua under the AI HELP group
  -- to avoid conflicts with other leader mappings
  keys = {
    -- Add <C-c> as a global toggle for Claude Code
    { "<C-c>", "<cmd>ClaudeCodeFocus<CR>", mode = "n", desc = "Toggle Claude Code" },
  },
  
  config = function(_, opts)
    require("claudecode").setup(opts)
    
    -- Multiple approaches to disable the open_diff tool
    
    -- Approach 1: Immediate override attempt
    local function override_diff_tool()
      local ok, tools = pcall(require, "claudecode.tools")
      if ok and tools and tools.tools then
        if tools.tools.openDiff then
          tools.tools.openDiff.handler = function(params)
            -- Completely disable diff functionality - just return success
            return { content = {} }
          end
          vim.notify("Claude Code: open_diff tool disabled", vim.log.levels.INFO)
        end
        
        -- Also try to disable any variants
        if tools.tools.open_diff then
          tools.tools.open_diff.handler = function(params)
            return { content = {} }
          end
        end
        
        if tools.tools["open-diff"] then
          tools.tools["open-diff"].handler = function(params)
            return { content = {} }
          end
        end
      end
    end
    
    -- Approach 2: Schedule override for after plugin load
    vim.schedule(override_diff_tool)
    
    -- Approach 3: Delayed override with multiple attempts
    for i = 1, 5 do
      vim.defer_fn(override_diff_tool, i * 500) -- Try every 500ms for 2.5 seconds
    end
    
    -- Approach 4: Hook into Claude Code events if available
    vim.api.nvim_create_autocmd("User", {
      pattern = "ClaudeCodeReady",
      callback = override_diff_tool,
      once = true,
    })
    
    -- Clean up any existing Claude Code related buffers on startup
    vim.schedule(function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local bufname = vim.api.nvim_buf_get_name(buf)
        local filetype = vim.bo[buf].filetype
        if bufname:match("claude%-code") or bufname:match("ClaudeCode") or
           bufname:match("claude") or bufname:match("Claude") or
           bufname:match("%.diff$") or bufname:match("%.patch$") or
           filetype == "diff" and (bufname:match("^/tmp/") or bufname:match("^/var/")) then
          vim.bo[buf].buflisted = false
          vim.bo[buf].bufhidden = "wipe"
        end
      end
    end)
    
    -- Create additional commands for convenience (maintaining compatibility)
    vim.api.nvim_create_user_command("ClaudeCodeToggle", function()
      vim.cmd("ClaudeCode")
    end, { desc = "Toggle Claude Code terminal" })
    
    -- Command to add current buffer to Claude context
    vim.api.nvim_create_user_command("ClaudeCodeAddBuffer", function()
      local file = vim.fn.expand("%:p")
      if file ~= "" then
        vim.cmd("ClaudeCodeAdd " .. file)
      else
        require('neotex.util.notifications').ai('No file to add to Claude context', require('neotex.util.notifications').categories.WARNING)
      end
    end, { desc = "Add current buffer to Claude Code context" })
    
    -- Command to add current directory to Claude context
    vim.api.nvim_create_user_command("ClaudeCodeAddDir", function()
      local cwd = vim.fn.getcwd()
      vim.cmd("ClaudeCodeAdd " .. cwd)
    end, { desc = "Add current directory to Claude Code context" })
    
    -- Prevent Claude Code from creating a new tab
    local function prevent_claude_tab()
      vim.defer_fn(function()
        -- Check if we're in a 'claude' tab that was just created
        local current_tab = vim.fn.tabpagenr()
        local tab_name = vim.fn.bufname()
        
        if tab_name:match("claude") and vim.fn.tabpagenr("$") > 1 then
          -- Get the windows in the current tab
          local wins = vim.api.nvim_tabpage_list_wins(0)
          
          -- If this tab only has the claude window, move it to the previous tab
          if #wins == 1 then
            local buf = vim.api.nvim_win_get_buf(wins[1])
            vim.cmd("tabprevious")
            vim.cmd("vsplit")
            vim.api.nvim_win_set_buf(0, buf)
            vim.cmd("tabnext " .. current_tab)
            vim.cmd("tabclose")
            vim.cmd("wincmd L")  -- Move to right side
          end
        end
      end, 50)  -- Small delay to let the tab creation complete
    end
    
    -- Hook into tab creation
    vim.api.nvim_create_autocmd("TabNew", {
      callback = prevent_claude_tab
    })
    
    -- Set up autocmd to configure Claude Code buffers
    vim.api.nvim_create_autocmd({"TermOpen", "BufEnter", "BufWinEnter", "BufAdd", "BufNew"}, {
      pattern = "*",
      callback = function(event)
        local bufname = vim.api.nvim_buf_get_name(event.buf)
        local filetype = vim.bo[event.buf].filetype
        -- Check if this is any Claude Code related buffer (terminal, diff, or any other)
        if bufname:match("claude%-code") or bufname:match("ClaudeCode") or 
           bufname:match("claude") or bufname:match("Claude") or
           bufname:match("%.diff$") or bufname:match("%.patch$") or
           filetype == "diff" and (bufname:match("^/tmp/") or bufname:match("^/var/")) then
          -- Make the buffer unlisted so it doesn't appear in tabline
          vim.bo[event.buf].buflisted = false
          -- Set bufhidden to wipe to remove it completely when hidden
          vim.bo[event.buf].bufhidden = "wipe"
          
          -- Set buffer-local keymaps for Claude Code terminal
          -- Pass escape directly to Claude Code without leaving insert mode
          vim.api.nvim_buf_set_keymap(event.buf, 't', '<Esc>', [[<Esc>]], { noremap = true, silent = true })
          -- Use <C-\><C-n> to exit terminal mode and enter Neovim normal mode
          vim.api.nvim_buf_set_keymap(event.buf, 't', '<C-\\><C-n>', '<C-\\><C-n>', { noremap = true, desc = "Exit terminal mode to Neovim normal mode" })
          -- Alternative: use <leader><Esc> to exit terminal mode to Neovim normal mode
          vim.api.nvim_buf_set_keymap(event.buf, 't', '<leader><Esc>', '<C-\\><C-n>', { noremap = true, desc = "Exit terminal mode to Neovim normal mode" })
          -- Use <C-c> to toggle the Claude Code sidebar (close the window)
          vim.api.nvim_buf_set_keymap(event.buf, 't', '<C-c>', '<C-\\><C-n>:close<CR>', { noremap = true, silent = true, desc = "Toggle Claude Code sidebar closed" })
        end
      end,
    })
  end,
}
