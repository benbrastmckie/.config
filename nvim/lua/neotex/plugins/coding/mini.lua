-----------------------------------------------------------
-- Mini.nvim Plugins for Coding Enhancement
-- 
-- This module configures mini.nvim plugins for coding enhancements:
-- - mini.pairs: Auto-close pairs of characters (replacing nvim-autopairs)
-- - mini.surround: Surround text with characters (replacing nvim-surround)
-- - mini.comment: Comment toggling (replacing Comment.nvim)
-- - mini.cursorword: Highlights word occurrences (replacing local-highlight)
-- - mini.ai: Enhanced text objects for working with brackets, quotes, etc.
-- - mini.splitjoin: Toggle between single-line and multi-line code constructs
-- - mini.align: Align text in columns based on delimiters
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
    -- Configure mini.cursorword for highlighting word occurrences
    require('mini.cursorword').setup({
      -- Delay in ms for highlighting other word instances
      delay = 100,
      
      -- Minimum word length to start highlighting (same as local-highlight)
      min_word_length = 1,
      
      -- Whether to disable highlighting in insert mode (same as local-highlight)
      disable_in_insert = true,
      
      -- List of filetypes to disable highlighting
      excluded_filetypes = { 'NvimTree', 'TelescopePrompt' },
      
      -- List of buffer types to disable highlighting
      excluded_buftypes = { 'help', 'terminal', 'nofile', 'quickfix', 'prompt' },
      
      -- Pattern for disabling highlighting for certain words
      disallowed_words = nil,
    })
    
    -- Configure mini.comment for toggling comments
    require('mini.comment').setup({
      -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        -- Disable default keys
        comment = '', -- Toggle comment (operator-pending)
        comment_line = '', -- Toggle comment on current line
        comment_visual = '', -- Toggle comment on visual selection
        textobject = '', -- Text object for surrounding comment
      },
      
      -- Hook functions to be executed at certain stage of commenting
      hooks = {
        -- Default tree-sitter mode for TSContextComment replacement
        pre = function()
          -- Detect filetype-specific comment string using treesitter
          -- This mimics nvim-ts-context-commentstring functionality
          local function get_context_commentstring()
            -- TSContextComment compatibility
            local has_treesitter, ts = pcall(require, 'nvim-treesitter.ts_utils')
            
            if not has_treesitter then
              return nil
            end
            
            -- Get comment string based on cursor position and language
            local node = ts.get_node_at_cursor()
            if not node then
              return nil
            end
            
            -- Try to get comment string based on language
            local ft = vim.bo.filetype
            
            -- Simple mapping for common languages with mixed comment styles
            local lang_comment_strings = {
              jsx = { line_comment = "//", block_comment = { "/*", "*/" } },
              tsx = { line_comment = "//", block_comment = { "/*", "*/" } },
              javascript = { line_comment = "//", block_comment = { "/*", "*/" } },
              typescript = { line_comment = "//", block_comment = { "/*", "*/" } },
              vue = { line_comment = "//", block_comment = { "/*", "*/" } },
              svelte = { line_comment = "//", block_comment = { "/*", "*/" } },
              php = { line_comment = "//", block_comment = { "/*", "*/" } },
            }
            
            if lang_comment_strings[ft] then
              return lang_comment_strings[ft].line_comment
            end
            
            return nil
          end
          
          -- Get comment string from context
          local comment_string = get_context_commentstring()
          if comment_string then
            -- Update comment string for current buffer
            vim.bo.commentstring = comment_string .. " %s"
          end
        end,
      },
    })
    
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
    
    -- Configure the highlight group for mini.cursorword to match local-highlight
    vim.api.nvim_set_hl(0, 'MiniCursorword', { link = 'Pmenu' })
    
    -- Add support for toggling cursorword highlighting (mapped to <leader>ah in which-key)
    _G.LocalHighlightToggle = function()
      if vim.b.minicursorword_disable then
        -- It's currently disabled, enable it
        vim.b.minicursorword_disable = false
        vim.notify("Word highlighting enabled", vim.log.levels.INFO)
      else
        -- It's currently enabled, disable it
        vim.b.minicursorword_disable = true
        vim.notify("Word highlighting disabled", vim.log.levels.INFO)
      end
    end
    
    -- Configure mini.ai for enhanced text objects
    require('mini.ai').setup({
      -- Table with textobject id as fields, textobject specification as values.
      -- Text objects can be used:
      -- - In operator-pending mode to create mapping like `di(` (delete inside brackets)
      -- - In visual mode to extend selection like `va'` (visually select around quotes)
      custom_textobjects = {
        -- Common objects
        o = require('mini.ai').gen_spec.treesitter({ 
          a = { "@block.outer", "@conditional.outer", "@loop.outer" },
          i = { "@block.inner", "@conditional.inner", "@loop.inner" },
        }, {}),
        f = require('mini.ai').gen_spec.treesitter({ 
          a = "@function.outer", 
          i = "@function.inner" 
        }, {}),
        c = require('mini.ai').gen_spec.treesitter({ 
          a = "@class.outer", 
          i = "@class.inner" 
        }, {}),
        -- User-defined objects
        D = require('mini.ai').gen_spec.pair('```', '```', {}), -- Markdown code blocks
        m = require('mini.ai').gen_spec.pair('\\begin{', '\\end{', {}), -- LaTeX environment
      },
      
      -- How to search for object (first inside current line, then inside
      -- neighborhood). One of 'cover', 'cover_or_next', 'cover_or_prev',
      -- 'cover_or_nearest', 'next', 'prev', 'nearest'.
      search_method = 'cover_or_nearest',
      
      -- Whether to disable showing non-error feedback
      silent = false,
    })
    
    -- Configure mini.splitjoin for toggling between single/multi-line constructs
    require('mini.splitjoin').setup({
      -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        toggle = 'gS', -- Toggle "split or join" on current line
        split = '',    -- Split current item
        join = '',     -- Join items within current line
      },
      
      -- Split options for different item types (each is table with options)
      split = {
        hooks_pre = {},
        hooks_post = {},
      },
      
      -- Join options for different item types
      join = {
        hooks_pre = {},
        hooks_post = {},
      },
    })
    
    -- Configure mini.align for text alignment
    require('mini.align').setup({
      -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        start = 'ga',          -- Start alignment
        start_with_preview = 'gA', -- Start alignment with preview
      },
      
      -- Default options controlling alignment process
      options = {
        split_pattern = '',    -- Pattern used to split text
        justify_side = 'left', -- Which side to justify: 'left', 'center', 'right'
        delimiter_pattern = '', -- Pattern for delimiter to be emphasized
        
        -- Options for merging delimiter and adjacent spaces into one
        merge_delimiter = true,
        
        -- Whether to add spaces for alignment
        spaces_to_add = true,
      },
      
      -- Predefined steps to be used inside user steps
      steps = {
        -- Functions applied in sequence to create expression which
        -- will be evaluated for each delimiter to get its column
        -- for alignment
        pre_process = {},
        
        -- Functions applied in sequence for each part to align
        align = {},
        
        -- Functions applied in sequence for to adjust space
        adjust = {},
        
        -- Functions applied in sequence for post-processing
        post_process = {},
      },
    })
    
    -- mini.diff has been removed to avoid conflicts with gitsigns.nvim
    
    -- Set up custom keymappings for mini.comment to match Comment.nvim
    -- Normal mode comment toggle
    vim.keymap.set('n', '<C-;>', function()
      require('mini.comment').toggle_lines(vim.fn.line('.'), vim.fn.line('.'))
    end, { desc = "Toggle comment on current line" })
    
    -- Visual mode comment toggle
    vim.keymap.set('x', '<C-;>', function()
      local start_row, _ = unpack(vim.api.nvim_buf_get_mark(0, '<'))
      local end_row, _ = unpack(vim.api.nvim_buf_get_mark(0, '>'))
      require('mini.comment').toggle_lines(start_row, end_row)
    end, { desc = "Toggle comment on selection" })
    
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
      
      -- Register new which-key mappings for new mini plugins
      which_key.register({
        ["<leader>x"] = {
          name = "TEXT OPERATIONS",
          a = { "ga", "align" },
          A = { "gA", "align with preview" },
          s = { "gS", "split/join toggle" },
        },
      })
    end
  end,
}