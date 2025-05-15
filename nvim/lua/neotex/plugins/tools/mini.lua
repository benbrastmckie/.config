-----------------------------------------------------
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
  event = { "VeryLazy" }, -- Load earlier to ensure comment functionality works
  dependencies = {
    "hrsh7th/nvim-cmp",   -- For integration with completion
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
        comment = '',        -- Toggle comment (operator-pending)
        comment_line = '',   -- Toggle comment on current line
        comment_visual = '', -- Toggle comment on visual selection
        textobject = '',     -- Text object for surrounding comment
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

    -- mini.surround has been deprecated and replaced with nvim-surround
    -- The configuration has been moved to lua/neotex/deprecated/mini.surround.lua
    -- The new implementation is in lua/neotex/plugins/coding/surround.lua

    -- Visual mode mappings are now handled by nvim-surround

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
        ['$'] = { action = 'open', pair = '$$', neigh_pattern = '[^\\].' },

        -- Move right upon closing character input
        [')'] = { action = 'close', pair = '()', neigh_pattern = '[^\\].' },
        [']'] = { action = 'close', pair = '[]', neigh_pattern = '[^\\].' },
        ['}'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\].' },
        ['>'] = { action = 'close', pair = '<>', neigh_pattern = '[^\\].' },

        -- Space padding (disabled to prevent issues with backspace in markdown lists)
        -- [' '] = {
        --   action = 'open',
        --   pair = '  ',
        --   neigh_pattern = '[%(%[{<]$'
        -- }
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
              -- LaTeX quotes - using custom implementation to ensure correct behavior
              -- Disable standard backtick and single quote pairing
              ['`'] = nil,
              ["'"] = nil,

              -- LaTeX math mode $ (simple explicit configuration)
              ['$'] = { action = 'open', pair = '$$', neigh_pattern = '[^\\].' }
            }
          }

          -- Custom mapping for backtick to handle LaTeX quotes properly
          vim.keymap.set('i', '`', function()
            -- Insert the opening backtick and the closing quote with cursor positioned between them
            return "`'<Left>"
          end, { buffer = true, expr = true, silent = true })

          -- Create a custom mapping for $ to handle closing/skipping
          vim.keymap.set('i', '$', function()
            local col = vim.api.nvim_win_get_cursor(0)[2]
            local line = vim.api.nvim_get_current_line()

            -- If the next character is $, skip over it instead of inserting a new one
            if col < #line and line:sub(col + 1, col + 1) == '$' then
              return "<Right>"
            end

            -- Otherwise insert $ normally, which will pair with minipairs
            return "$"
          end, { buffer = true, expr = true, silent = true })

          -- Simple and reliable mapping for $ to handle both pairing and skipping
          vim.keymap.set('i', '$', function()
            local col = vim.api.nvim_win_get_cursor(0)[2]
            local line = vim.api.nvim_get_current_line()

            -- If next character is $, skip over it instead of inserting a new one
            if col < #line and line:sub(col + 1, col + 1) == '$' then
              return "<Right>"
            end

            -- Otherwise insert a pair of $$ and position cursor between them
            return "$$<Left>"
          end, { buffer = true, expr = true, silent = true })
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
        D = require('mini.ai').gen_spec.pair('```', '```', {}),         -- Markdown code blocks
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
        start = 'ga',              -- Start alignment
        start_with_preview = 'gA', -- Start alignment with preview
      },

      -- Default options controlling alignment process
      options = {
        split_pattern = '',     -- Pattern used to split text
        justify_side = 'left',  -- Which side to justify: 'left', 'center', 'right'
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

    -- Comment keymaps are now defined in config/keymaps.lua and core/keymaps.lua
    -- to ensure consistent behavior

    -- This depends on which-key being installed
    local has_which_key, which_key = pcall(require, "which-key")
    if has_which_key then
      -- Note: surround mappings are defined in editor/which-key.lua
      
      -- Register which-key mappings for mini plugins
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
