return {
  "windwp/nvim-autopairs",
  event = { "InsertEnter" },
  config = function()
    local autopairs = require("nvim-autopairs")
    local Rule = require('nvim-autopairs.rule')
    local cond = require('nvim-autopairs.conds')

    -- Basic setup with treesitter integration
    autopairs.setup({
      check_ts = true,                      -- enable treesitter
      ts_config = {
        lua = { "string" },                 -- don't add pairs in lua string treesitter nodes
        javascript = { "template_string" }, -- don't add pairs in javscript template_string treesitter nodes
        java = false,                       -- don't check treesitter on java
        lean = false,                       -- disable treesitter for lean (custom rules)
      },
      disable_filetype = { "TelescopePrompt", "spectre_panel" },
      disable_in_macro = true,
      disable_in_replace_mode = true,
      enable_moveright = true,
      ignored_next_char = "",
      enable_check_bracket_line = true, -- check bracket in same line
    })

    -- Add Lean-specific unicode mathematical pairs
    local lean_rules = {
      Rule("⟨", "⟩", "lean"),  -- angle brackets
      Rule("(", ")", "lean"),
      Rule("[", "]", "lean"),
      Rule("{", "}", "lean"),
      Rule("`", "`", "lean"),
      Rule("'", "'", "lean"),
      Rule("«", "»", "lean"),  -- guillemets
      Rule("⟪", "⟫", "lean"),  -- mathematical double angle brackets
      Rule("⦃", "⦄", "lean"),  -- mathematical white curly brackets
    }

    for _, rule in ipairs(lean_rules) do
      autopairs.add_rule(rule)
    end

    -- Add LaTeX-specific rules
    autopairs.add_rules({
      -- TeX backtick to apostrophe conversion
      Rule("`", "'", "tex"),
      
      -- Dollar sign pairs for math mode
      Rule("$", "$", "tex"),
      
      -- Space handling for pairs - adds space inside brackets in math contexts
      Rule(' ', ' ')
          :with_pair(function(opts)
            local pair = opts.line:sub(opts.col, opts.col + 1)
            return vim.tbl_contains({ '$$', '()', '{}', '[]', '<>' }, pair)
          end)
          :with_move(cond.none())
          :with_cr(cond.none())
          :with_del(function(opts)
            local col = vim.api.nvim_win_get_cursor(0)[2]
            local context = opts.line:sub(col - 1, col + 2)
            return vim.tbl_contains({ '$  $', '(  )', '{  }', '[  ]', '<  >' }, context)
          end),
      
      -- Context-aware spacing rules for LaTeX
      Rule("$ ", " ", "tex")
          :with_pair(cond.not_after_regex(" "))
          :with_del(cond.none()),
      Rule("[ ", " ", "tex")
          :with_pair(cond.not_after_regex(" "))
          :with_del(cond.none()),
      Rule("{ ", " ", "tex")
          :with_pair(cond.not_after_regex(" "))
          :with_del(cond.none()),
      Rule("( ", " ", "tex")
          :with_pair(cond.not_after_regex(" "))
          :with_del(cond.none()),
      Rule("< ", " ", "tex")
          :with_pair(cond.not_after_regex(" "))
          :with_del(cond.none()),
    })

    -- Enhanced dollar sign behavior for LaTeX math mode
    autopairs.get_rule('$'):with_move(function(opts)
      return opts.char == opts.next_char:sub(1, 1)
    end)

    -- Custom blink.cmp integration using community workaround
    local function setup_blink_integration()
      local ok, blink = pcall(require, 'blink.cmp')
      if not ok then return end

      -- Check if blink.cmp has the visibility check method
      if not blink.is_visible then
        -- If blink.cmp doesn't support autopairs integration yet, skip setup
        vim.notify("blink.cmp autopairs integration not available", vim.log.levels.WARN)
        return
      end

      -- Use community-proposed solution from GitHub issue #477
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      
      -- Override CR keymap to include autopairs callback
      vim.keymap.set('i', '<CR>', function()
        if blink.is_visible() then
          return blink.accept({ 
            callback = cmp_autopairs.on_confirm_done({
              filetypes = {
                tex = false, -- Disable for tex (conflicts with LaTeX spacing rules)
                lean = true  -- Enable for lean
              }
            })
          })
        else
          return '<CR>'
        end
      end, { expr = true, silent = true, desc = "Accept completion with autopairs" })
    end

    -- Initialize blink.cmp integration
    setup_blink_integration()
  end,
}