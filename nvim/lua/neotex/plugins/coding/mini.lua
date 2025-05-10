-----------------------------------------------------------
-- Mini.nvim Plugins for Coding Enhancement
-- 
-- This module configures mini.nvim plugins for coding enhancements:
-- - mini.pairs: Auto-close pairs of characters (replacing nvim-autopairs)
-- - Future: mini.surround, mini.comment, mini.cursorword
--
-- Mini.nvim provides a collection of minimal, independent, and fast 
-- Lua modules for Neovim that enhance various aspects of coding.
-----------------------------------------------------------

return {
  'echasnovski/mini.nvim',
  version = false,
  event = { "InsertEnter" }, -- Load on insert for performance
  dependencies = {
    "hrsh7th/nvim-cmp", -- For integration with completion
  },
  config = function()
    -- Configure mini.pairs for auto-closing pairs
    require('mini.pairs').setup({
      -- Global mappings. Do not use `map` inside `setup()` to avoid conflicts
      mappings = {
        -- Close pairs
        ['('] = { action = 'open', pair = '()', neigh_pattern = '[^\\].' },
        ['['] = { action = 'open', pair = '[]', neigh_pattern = '[^\\].' },
        ['{'] = { action = 'open', pair = '{}', neigh_pattern = '[^\\].' },
        ['<'] = { action = 'open', pair = '<>', neigh_pattern = '[^\\].' },
        ['"'] = { action = 'open', pair = '""', neigh_pattern = '[^\\].' },
        ["'"] = { action = 'open', pair = "''", neigh_pattern = '[^\\].' },
        ['`'] = { action = 'open', pair = '``', neigh_pattern = '[^\\].' },
        ['$'] = { action = 'open', pair = '$$', neigh_pattern = '[^\\].' }, -- For LaTeX

        -- Move right upon closing character input
        [')'] = { action = 'close', pair = '()', neigh_pattern = '[^\\].' },
        [']'] = { action = 'close', pair = '[]', neigh_pattern = '[^\\].' },
        ['}'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\].' },
        ['>'] = { action = 'close', pair = '<>', neigh_pattern = '[^\\].' },

        -- Space padding (for () [] {} <>)
        [' '] = {
          action = 'open',
          pair = '  ',
          neigh_pattern = '[%(%[{<]$'
        }
      },

      -- Disable for specific filetypes
      disable_filetype = { 'TelescopePrompt', 'spectre_panel' },

      -- Disable in specific modes
      modes = {
        insert = true,
        command = false,
        terminal = false,
      },
    })

    -- Add filetype-specific pairs
    -- For Lean
    if vim.fn.has('nvim-0.8') == 1 then
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'lean',
        callback = function()
          vim.b.minipairs_config = {
            mappings = {
              ['⟨'] = { action = 'open', pair = '⟨⟩', neigh_pattern = '[^\\].' },
              ['⟩'] = { action = 'close', pair = '⟨⟩', neigh_pattern = '[^\\].' },
              ['«'] = { action = 'open', pair = '«»', neigh_pattern = '[^\\].' },
              ['»'] = { action = 'close', pair = '«»', neigh_pattern = '[^\\].' },
              ['⟪'] = { action = 'open', pair = '⟪⟫', neigh_pattern = '[^\\].' },
              ['⟫'] = { action = 'close', pair = '⟪⟫', neigh_pattern = '[^\\].' },
              ['⦃'] = { action = 'open', pair = '⦃⦄', neigh_pattern = '[^\\].' },
              ['⦄'] = { action = 'close', pair = '⦃⦄', neigh_pattern = '[^\\].' },
            }
          }
        end,
      })
    end

    -- For TeX
    if vim.fn.has('nvim-0.8') == 1 then
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'tex',
        callback = function()
          vim.b.minipairs_config = {
            mappings = {
              ['`'] = { action = 'open', pair = '`\'', neigh_pattern = '[^\\].' },
              ['\''] = { action = 'close', pair = '`\'', neigh_pattern = '[^\\].' },
            }
          }
        end,
      })
    end

    -- Set up CMP integration manually using events
    local cmp = require('cmp')
    if cmp then
      cmp.event:on('confirm_done', function(evt)
        -- Skip for tex files
        if vim.bo.filetype == 'tex' then return end
        
        -- Get the completed item
        local entry = evt.entry
        local item = entry:get_completion_item()
        
        -- Check if we should insert a pair after completion
        if item.textEdit and item.textEdit.newText and item.textEdit.newText:match('[%(%[{<"\']$') then
          -- Get the last character
          local last_char = item.textEdit.newText:sub(-1)
          -- Use feedkeys to trigger the pairing behavior
          vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes(last_char, true, false, true),
            'i',
            true
          )
        end
      end)
    end
  end,
}