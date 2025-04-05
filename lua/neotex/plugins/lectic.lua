return {
  "gleachkr/lectic",
  lazy = true,
  -- Use both markdown and lectic.markdown filetypes
  ft = { "markdown", "lectic.markdown" },
  build = "npm install", -- Install dependencies
  -- Use the conditional directory trick to point to the neovim plugin
  cond = function(plugin)
    plugin.dir = plugin.dir .. '/extra/lectic.nvim'
    return true
  end,
  init = function()
    -- Create the autocmd group early
    vim.api.nvim_create_augroup("Lectic", { clear = true })

    -- Keymappings are now defined in which-key.lua to centralize all mappings

    -- Add filetype detection for .lec files if not already defined
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
      group = "Lectic",
      pattern = "*.lec",
      callback = function()
        vim.bo.filetype = "lectic.markdown"
      end
    })
  end,
  config = function()
    -- Create a global function to submit current lectic section
    -- (to be used by which-key.lua)
    function _G.SubmitLecticSection()
      -- Only run if we're in a lectic markdown buffer
      if vim.bo.filetype == "lectic.markdown" then
        -- Find the current section and send it
        require("lectic.submit").submit_current_section()
      else
        vim.notify("This command only works in Lectic files", vim.log.levels.WARN)
      end
    end

    -- Create a function to create a new Lectic file
    -- (to be used by which-key.lua)
    function _G.CreateNewLecticFile()
      -- Open a new buffer with .lec extension
      vim.cmd("enew")
      vim.cmd("setfiletype lectic.markdown")
      -- Prompt for filename since we'll let the ftdetect handle the extension
      vim.ui.input({ prompt = "Save Lectic file as: " }, function(filename)
        if filename and filename ~= "" then
          -- Make sure it has .lec extension
          if not filename:match("%.lec$") then
            filename = filename .. ".lec"
          end
          vim.cmd("write " .. filename)
        end
      end)
    end

    -- Register the command to use the plugin's submit function
    vim.api.nvim_create_user_command(
      'Lectic',
      function(opts)
        local start_line = opts.line1
        local end_line = opts.line2
        require("lectic.submit").submit_lectic(start_line, end_line)
      end,
      { range = "%" }
    )

    -- Configure any additional plugin settings
    vim.g.lectic_model = "gpt-4" -- Default model

    -- Create additional keymaps for Lectic files
    vim.api.nvim_create_autocmd("FileType", {
      group = "Lectic",
      pattern = "lectic.markdown",
      callback = function(ev)
        local bufnr = ev.buf

        -- Use the global manual folding settings from options.lua

        -- Also set standard markdown settings for this buffer
        vim.opt_local.conceallevel = 2     -- Enable concealing of syntax
        vim.opt_local.concealcursor = "nc" -- Conceal in normal and command mode

        -- Also handle markdown specific keymaps
        if vim.fn.exists("*set_markdown_keymaps") == 1 then
          _G.set_markdown_keymaps()
        end
      end
    })
  end,
  -- Define dependencies if needed
  dependencies = {
    "nvim-lua/plenary.nvim",          -- Required by many plugins
    "nvim-treesitter/nvim-treesitter" -- For better folding support
  }
}
