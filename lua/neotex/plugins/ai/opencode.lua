return {
  "NickvanDyke/opencode.nvim",
  event = "VeryLazy",
  dependencies = {
    -- Recommended for better prompt input
    { "folke/snacks.nvim", opts = { input = { enabled = true } } },
  },
  
  opts = {
    -- Terminal configuration
    terminal = {
      split_side = "right",  -- Consistent with your claude-code setup
      split_width_percentage = 0.40,  -- Slightly wider for better visibility
      auto_start = false,  -- Start manually when needed
    },
    
    -- Auto-reload settings
    auto_reload = {
      enabled = true,  -- Auto-reload buffers edited by OpenCode
      debounce_ms = 500,  -- Wait 500ms after last edit before reloading
    },
    
    -- Context injection settings
    context = {
      include_diagnostics = true,  -- Include LSP diagnostics in context
      include_cursor = true,  -- Include cursor position
      include_selection = true,  -- Include visual selection
      include_buffer = true,  -- Include current buffer content
    },
    
    -- Prompt library settings
    prompt_library = {
      enabled = true,
      custom_prompts = {
        -- Add custom prompts here as needed
        explain = "Explain this code in detail",
        optimize = "Suggest optimizations for this code",
        test = "Generate tests for this code",
        document = "Add documentation comments to this code",
      },
    },
  },
  
  keys = {
    -- Main toggle
    { "<leader>ot", function() require("opencode").toggle() end, desc = "Toggle OpenCode" },
    
    -- Ask commands
    { "<leader>oA", function() require("opencode").ask() end, desc = "Ask OpenCode (general)" },
    { "<leader>oa", function() require("opencode").ask("@cursor: ") end, desc = "Ask about code at cursor", mode = "n" },
    { "<leader>oa", function() require("opencode").ask("@selection: ") end, desc = "Ask about selection", mode = "v" },
    
    -- Context commands
    { "<leader>ob", function() require("opencode").add_buffer() end, desc = "Add buffer to OpenCode context" },
    { "<leader>od", function() require("opencode").add_directory() end, desc = "Add directory to OpenCode context" },
    
    -- Prompt library
    { "<leader>op", function() require("opencode").prompt_library() end, desc = "OpenCode prompt library" },
    
    -- Quick actions
    { "<leader>oe", function() require("opencode").ask("@cursor: Explain this code") end, desc = "Explain code at cursor" },
    { "<leader>or", function() require("opencode").ask("@cursor: Refactor this code") end, desc = "Refactor code at cursor" },
    { "<leader>of", function() require("opencode").ask("@cursor: Fix this code") end, desc = "Fix code at cursor" },
  },
  
  config = function(_, opts)
    -- Ensure autoread is enabled for auto-reload functionality
    vim.opt.autoread = true
    
    -- Set up OpenCode with the provided options
    require("opencode").setup(opts)
    
    -- Create user commands for convenience
    vim.api.nvim_create_user_command("OpenCodeToggle", function()
      require("opencode").toggle()
    end, { desc = "Toggle OpenCode terminal" })
    
    vim.api.nvim_create_user_command("OpenCodeAsk", function(args)
      require("opencode").ask(args.args)
    end, { 
      desc = "Ask OpenCode a question",
      nargs = "*",
    })
    
    vim.api.nvim_create_user_command("OpenCodeAddBuffer", function()
      local file = vim.fn.expand("%:p")
      if file ~= "" then
        require("opencode").add_buffer()
      else
        require('neotex.util.notifications').ai('No file to add to OpenCode context', require('neotex.util.notifications').categories.WARNING)
      end
    end, { desc = "Add current buffer to OpenCode context" })
    
    vim.api.nvim_create_user_command("OpenCodeAddDir", function()
      require("opencode").add_directory()
    end, { desc = "Add current directory to OpenCode context" })
    
    -- Set up autocmds to handle OpenCode events
    vim.api.nvim_create_autocmd("User", {
      pattern = "OpenCodeBufferModified",
      callback = function(event)
        -- This fires when OpenCode modifies a buffer
        -- You can add custom handling here if needed
        local bufname = vim.api.nvim_buf_get_name(event.buf)
        require('neotex.util.notifications').ai('OpenCode modified: ' .. vim.fn.fnamemodify(bufname, ':t'), require('neotex.util.notifications').categories.INFO)
      end,
    })
    
    -- Integration with existing AI tools
    vim.api.nvim_create_autocmd("User", {
      pattern = "OpenCodeStarted",
      callback = function()
        -- Notify that OpenCode has started
        require('neotex.util.notifications').ai('OpenCode terminal started', require('neotex.util.notifications').categories.SUCCESS)
      end,
    })
  end,
}