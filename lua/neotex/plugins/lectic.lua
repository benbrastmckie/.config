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

    -- Create keymapping to open Lectic
    vim.keymap.set("n", "<leader>ml", function()
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
    end, { desc = "Open Lectic interface" })

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

        -- Enable folding for Lectic files specifically, overriding global settings
        -- This is buffer-local and won't affect other files
        vim.opt_local.foldenable = true
        vim.opt_local.foldmethod = "expr"
        vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.opt_local.foldlevel = 1 -- Show top-level headings but fold others

        -- Also set standard markdown settings for this buffer
        vim.opt_local.conceallevel = 2     -- Enable concealing of syntax
        vim.opt_local.concealcursor = "nc" -- Conceal in normal and command mode

        -- Submit current section/prompt
        vim.keymap.set("n", "<leader>ms", function()
          -- Find the current section and send it
          require("lectic.submit").submit_current_section()
        end, { buffer = bufnr, desc = "Submit current Lectic section" })

        -- Toggle all folding (foldenable) for the buffer
        vim.keymap.set("n", "<leader>mf", function()
          -- Toggle foldenable for the entire buffer
          if vim.wo.foldenable then
            vim.wo.foldenable = false
            vim.notify("Folding disabled", vim.log.levels.INFO)
          else
            vim.wo.foldenable = true
            vim.notify("Folding enabled", vim.log.levels.INFO)
          end
        end, { buffer = bufnr, desc = "Toggle all folding" })

        -- Toggle individual fold under cursor
        vim.keymap.set("n", "<leader>mz", function()
          -- Try to toggle fold safely
          local status, err = pcall(function()
            -- Get current line
            local line = vim.fn.line(".")
            local fold_closed = vim.fn.foldclosed(line)

            if fold_closed == -1 then
              -- No closed fold at cursor, try to create/close one
              vim.cmd("normal! zc")
            else
              -- Fold exists and is closed, open it
              vim.cmd("normal! zo")
            end
          end)

          if not status then
            -- Handle the case where there are no folds
            if string.match(tostring(err), "E490") then
              vim.notify("No fold found at cursor", vim.log.levels.INFO)
            else
              vim.notify("Error toggling fold: " .. tostring(err), vim.log.levels.ERROR)
            end
          end
        end, { buffer = bufnr, desc = "Toggle fold under cursor" })

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
