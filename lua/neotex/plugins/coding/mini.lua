-----------------------------------------------------------
-- Mini.nvim Plugins for Coding Enhancement
-- 
-- This module configures mini.nvim plugins for coding enhancements:
-- - mini.pairs: Auto-close pairs of characters (replacing nvim-autopairs)
-- - mini.surround: Surround text with characters (replacing nvim-surround)
-- - Future: mini.comment, mini.cursorword
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
    -- Configure mini.surround for surrounding text
    require('mini.surround').setup({
      -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        add = 'sa', -- Add surrounding in Normal and Visual modes
        delete = 'sd', -- Delete surrounding
        find = 'sf', -- Find surrounding (to the right)
        find_left = 'sF', -- Find surrounding (to the left)
        highlight = 'sh', -- Highlight surrounding
        replace = 'sc', -- Replace surrounding
        update_n_lines = 'sn', -- Update `n_lines`
        
        -- Add surrounding in visual mode with Shift+s like nvim-surround
        suffix_last = 'l', -- Suffix to search with "prev" method
        suffix_next = 'n', -- Suffix to search with "next" method
      },
      
      -- How to search for surrounding (first inside current line, then inside
      -- neighborhood). Each element of search path should be one of 'cover', 'prev',
      -- 'next', 'nearest'.
      search_method = 'cover_or_next',
      
      -- Number of lines within which surrounding is searched
      n_lines = 20,
      
      -- Whether to respect selection type (character/line/block)
      respect_selection_type = true,
      
      -- Duration (in ms) of highlight when calling `MiniSurround.highlight()`
      highlight_duration = 500,
      
      -- Custom surrounding patterns
      custom_surroundings = {
        -- LaTeX-specific surroundings
        ['$'] = { output = { left = '$', right = '$' } },
        ['\\'] = { output = { left = '\\(', right = '\\)' } },
        ['E'] = { output = { left = '\\begin{equation}', right = '\\end{equation}' } },
        ['A'] = { output = { left = '\\begin{align}', right = '\\end{align}' } },
        ['I'] = { output = { left = '\\textit{', right = '}' } },
        ['B'] = { output = { left = '\\textbf{', right = '}' } },
        ['T'] = { output = { left = '\\texttt{', right = '}' } },
        
        -- Markdown surroundings
        ['*'] = { output = { left = '*', right = '*' } },
        ['_'] = { output = { left = '_', right = '_' } },
        ['`'] = { output = { left = '`', right = '`' } },
        ['~'] = { output = { left = '~~', right = '~~' } },
        ['c'] = { output = { left = '```', right = '```' } },
      },
    })
    
    -- Add <S-s> mapping in visual mode to match nvim-surround
    vim.api.nvim_set_keymap('x', '<S-s>', 'sa', { noremap = true, silent = true })
    
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
    
    -- Add which-key mappings for mini.surround to match previous surround plugin
    -- This depends on which-key being installed
    local has_which_key, which_key = pcall(require, "which-key")
    if has_which_key then
      which_key.register({
        ["<leader>s"] = {
          name = "SURROUND",
          s = { "sa", "surround" },
          d = { "sd", "delete" },
          c = { "sc", "change" },
          f = { "sf", "find" },
          h = { "sh", "highlight" },
        },
      })
    end
  end,
}