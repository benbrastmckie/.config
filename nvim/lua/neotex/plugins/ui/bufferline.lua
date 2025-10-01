return {
  "akinsho/bufferline.nvim",
  lazy = true,
  event = "BufAdd", -- Only load when multiple buffers exist
  dependencies = { "nvim-tree/nvim-web-devicons" },
  version = "*",
  init = function()
    -- Hide the tabline completely at startup
    vim.opt.showtabline = 0
    
    -- Create an autocmd that will only show tabline when we have more than 1 buffer
    vim.api.nvim_create_autocmd("BufAdd", {
      callback = function()
        local buffers = vim.fn.getbufinfo({buflisted = 1})
        if #buffers > 1 then
          vim.opt.showtabline = 2
        end
      end,
      desc = "Show bufferline when multiple buffers exist"
    })
  end,
  config = function()
    -- Simple initial setup with minimal features
    local bufferline = require('bufferline')
    bufferline.setup({
      options = {
        mode = "buffers",
        always_show_bufferline = false, -- Only show when more than one buffer
        diagnostics = false, -- Disable diagnostics integration initially
        diagnostics_update_in_insert = false,
        show_tab_indicators = false,
        show_close_icon = false,
        
        -- Simple filter to exclude quickfix windows and claude-code terminals
        custom_filter = function(buf_number, buf_numbers)
          local buf_ft = vim.bo[buf_number].filetype
          local buf_name = vim.api.nvim_buf_get_name(buf_number)
          -- Exclude quickfix windows
          if buf_ft == "qf" then
            return false
          end
          -- Exclude claude-code terminal buffers
          if string.match(buf_name, "claude%-code") then
            return false
          end
          return true
        end
      }
    })
    
    -- Set up autocmd for quickfix windows immediately
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "qf",
      callback = function()
        vim.opt_local.buflisted = false
        vim.opt_local.bufhidden = "wipe"
      end,
    })
    
    -- Defer loading the full configuration
    vim.defer_fn(function()
      bufferline.setup({
        options = {
          mode = "buffers",
          custom_filter = function(buf_number, buf_numbers)
            -- filter out quickfix buffers and claude-code terminals
            local buf_ft = vim.bo[buf_number].filetype
            local buf_name = vim.api.nvim_buf_get_name(buf_number)
            if buf_ft == "qf" then -- qf is the filetype for quickfix windows
              return false
            end
            -- Exclude claude-code terminal buffers
            if string.match(buf_name, "claude%-code") then
              return false
            end
            return true
          end,
          separator_style = "slant",
          close_command = "bdelete! %d",
          right_mouse_command = "bdelete! %d",
          diagnostics = false,
          diagnostics_update_in_insert = false,
          show_tab_indicators = false,
          show_close_icon = false,
          sort_by = function(buffer_a, buffer_b)
            -- add custom logic
            local modified_a = vim.fn.getftime(buffer_a.path)
            local modified_b = vim.fn.getftime(buffer_b.path)
            return modified_a > modified_b
          end,
          offsets = {
            {
              filetype = "neo-tree",
              text = function()
                return vim.fn.getcwd()
              end,
              highlight = "BufferLineFill",
              text_align = "left",
              separator = "",
            }
          },
          hover = {
            enabled = true,
            delay = 30,
            reveal = { 'close' }
          },
        },
      })
      
      -- Set up alpha integration after full config is loaded
      vim.api.nvim_create_autocmd("User", {
        pattern = "AlphaReady",
        desc = "disable tabline for alpha",
        callback = function()
          vim.opt.showtabline = 0
        end,
      })
      
      vim.api.nvim_create_autocmd("BufUnload", {
        buffer = 0,
        desc = "enable tabline after alpha",
        callback = function()
          vim.opt.showtabline = 2
        end,
      })

      -- Enhanced tabline visibility management
      -- Ensures bufferline stays visible when switching between normal buffers,
      -- terminals, and sidebars while maintaining "hide on single buffer" behavior
      local function ensure_tabline_visible()
        local buffers = vim.fn.getbufinfo({buflisted = 1})
        if #buffers > 1 then
          vim.opt.showtabline = 2
        elseif #buffers <= 1 then
          vim.opt.showtabline = 0
        end
      end

      -- Enhanced event handlers to preserve bufferline visibility
      -- Handles window/buffer switches to terminals, sidebars, and back
      vim.api.nvim_create_autocmd({"BufEnter", "WinEnter"}, {
        callback = function()
          local filetype = vim.bo.filetype

          -- Don't show tabline on alpha dashboard
          if filetype == "alpha" then
            vim.opt.showtabline = 0
            return
          end

          -- Update tabline visibility based on buffer count
          ensure_tabline_visible()
        end,
        desc = "Preserve bufferline visibility across window switches"
      })

      -- Restore tabline visibility when leaving terminal
      vim.api.nvim_create_autocmd("TermLeave", {
        pattern = "*",
        callback = function()
          vim.defer_fn(ensure_tabline_visible, 10)
        end,
        desc = "Restore bufferline when leaving terminal"
      })

      -- Update tabline visibility when buffers are deleted
      vim.api.nvim_create_autocmd("BufDelete", {
        callback = function()
          vim.defer_fn(ensure_tabline_visible, 10)
        end,
        desc = "Update bufferline visibility on buffer deletion"
      })
    end, 200)
  end,
}
