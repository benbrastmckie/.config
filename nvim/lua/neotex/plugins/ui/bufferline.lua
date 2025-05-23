return {
  "akinsho/bufferline.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  version = "*",
  config = function()
    local bufferline = require('bufferline')
    bufferline.setup({
      options = {
        mode = "buffers",
        custom_filter = function(buf_number, buf_numbers)
          -- filter out quickfix buffers
          local buf_ft = vim.bo[buf_number].filetype
          if buf_ft == "qf" then -- qf is the filetype for quickfix windows
            return false
          end
          return true
        end,
        separator_style = "slant",
        close_command = "bdelete! %d",       -- can be a string | function, see "Mouse actions"
        right_mouse_command = "bdelete! %d", -- can be a string | function | false, see "Mouse actions"
        diagnostics = false,                 -- OR: | "nvim_lsp"
        diagnostics_update_in_insert = false,
        show_tab_indicators = false,
        show_close_icon = false,
        -- numbers = "ordinal", -- Display buffer numbers as ordinal numbers
        -- sort_by = 'insert_after_current', -- OR: 'insert_at_end' | 'tabs' | 'extension' | 'relative_directory' | 'directory' | 'id' |
        sort_by = function(buffer_a, buffer_b)
          -- add custom logic
          local modified_a = vim.fn.getftime(buffer_a.path)
          local modified_b = vim.fn.getftime(buffer_b.path)
          return modified_a > modified_b
        end,
        offsets = {
          {
            filetype = "NvimTree",
            -- text = "Explorer",
            text = function()
              return vim.fn.getcwd()
            end,
            highlight = "BufferLineFill", -- Use BufferLineFill to match the background
            text_align = "left",
            separator = "", -- use a "true" to enable the default, or set your own character
            -- padding = 1
          }
        },
        hover = {
          enabled = true,
          delay = 30,
          reveal = { 'close' }
        },
        vim.api.nvim_create_autocmd("User", {
          pattern = "AlphaReady",
          desc = "disable tabline for alpha",
          callback = function()
            vim.opt.showtabline = 0
          end,
        }),
        vim.api.nvim_create_autocmd("BufUnload", {
          buffer = 0,
          desc = "enable tabline after alpha",
          callback = function()
            vim.opt.showtabline = 2
          end,
        }),
      },
    })

    -- Set up autocmd for quickfix windows
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "qf",
      callback = function()
        vim.opt_local.buflisted = false    -- Don't list in buffers
        vim.opt_local.bufhidden = "wipe"   -- Wipe buffer when hidden
      end,
    })
  end,
}
