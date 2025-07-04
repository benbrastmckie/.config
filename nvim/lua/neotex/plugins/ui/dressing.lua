return {
  "stevearc/dressing.nvim",
  lazy = false,  -- Load immediately to enhance UI
  priority = 1000,  -- Load before other UI plugins
  config = function()
    require('dressing').setup({
      input = {
        -- Enhanced input settings
        enabled = true,
        default_prompt = "Input:",
        trim_prompt = true,
        border = "rounded",
        relative = "cursor",
        prefer_width = 40,
        width = nil,
        max_width = { 140, 0.9 },
        min_width = { 20, 0.2 },
        win_options = {
          winblend = 0,
          wrap = false,
        },
        mappings = {
          n = {
            ["<Esc>"] = "Close",
            ["<CR>"] = "Confirm",
          },
          i = {
            ["<C-c>"] = "Close",
            ["<CR>"] = "Confirm",
            ["<Up>"] = "HistoryPrev",
            ["<Down>"] = "HistoryNext",
          },
        },
      },
      select = {
        -- Enhanced select settings
        enabled = true,
        backend = { "telescope", "builtin" },  -- Use telescope for many items, builtin for few
        trim_prompt = true,
        
        -- Telescope configuration for complex selections
        telescope = require('telescope.themes').get_dropdown({
          winblend = 10,
          width = 0.5,
          prompt_title = "",
          results_title = "",
          previewer = false,
          layout_config = {
            height = 0.4,
          }
        }),
        
        -- Builtin configuration for simple selections (Yes/No, etc)
        builtin = {
          border = "rounded",
          relative = "cursor",
          width = nil,
          max_width = { 80, 0.4 },
          min_width = { 40, 0.2 },
          height = nil,
          max_height = 0.3,
          min_height = { 3, 0.1 },
          mappings = {
            ["<Esc>"] = "Close",
            ["<C-c>"] = "Close",
            ["<CR>"] = "Confirm",
            ["j"] = "Next",
            ["k"] = "Previous",
          },
        },
        
        -- Smart backend selection based on context
        get_config = function(opts)
          if opts.kind == 'codeaction' then
            return {
              backend = "telescope",
              telescope = require('telescope.themes').get_cursor({})
            }
          end
          
          -- Use telescope for confirmations to match session picker style
          if opts.kind == 'confirmation' then
            return {
              backend = "telescope",
              telescope = require('telescope.themes').get_dropdown({
                winblend = 10,
                width = 0.3,
                prompt_title = "",
                results_title = "",
                previewer = false,
                layout_config = {
                  height = 0.15,
                }
              })
            }
          end
          
          -- Use builtin only for very small lists (2 items) without confirmation kind
          if opts.items and #opts.items <= 2 and opts.kind ~= 'confirmation' then
            return {
              backend = "builtin",
              builtin = {
                relative = "cursor",
                width = 30,
                height = 3,
                min_height = 3,
                max_height = 3,
              }
            }
          end
          
          -- Use telescope for many items
          return {
            backend = "telescope"
          }
        end,
      },
    })
  end
}