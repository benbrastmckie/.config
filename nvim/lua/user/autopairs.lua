-- Setup nvim-cmp.
local status_ok, npairs = pcall(require, "nvim-autopairs")
if not status_ok then
  return
end

npairs.setup {
  check_ts = true,
  ts_config = {
    lua = { "string", "source" },
    javascript = { "string", "template_string" },
    java = false,
  },
  disable_filetype = { "TelescopePrompt", "spectre_panel" },
  disable_in_macro = true,
  disable_in_replace_mode = true,
  enable_moveright = true,
  ignored_next_char = "",
  enable_check_bracket_line = true,  --- check bracket in same line
  -- enable_afterquote = true,  -- add bracket pairs after quote
  -- enable_bracket_in_quote = true,
  -- enable_abbr = false, -- trigger abbreviation
  -- fast_wrap = {
  --   map = "<C-l>",
  --   chars = { "$", "{", "[", "(", '"', "'" },
  --   pattern = string.gsub([=[[%'%"%)%>%]%)%}%,]]=], "%s+", ""),
  --   offset = 1, -- Offset from pattern match
  --   end_key = "L",
  --   keys = "qwertyuiopzxcvbnmasdfghjkl",
  --   check_comma = true,
  --   highlight = "PmenuSel",
  --   highlight_grey = "LineNr",
  --   -- highlight = 'Search',
  --   -- highlight_grey='Comment'
  -- },
}

local npairs = require'nvim-autopairs'

local Rule = require'nvim-autopairs.rule'

local cond = require'nvim-autopairs.conds'

npairs.add_rules({
  Rule("`","'","tex"),
  Rule("$","$","tex"),
  Rule(' ', ' ')
    :with_pair(function(opts)
      local pair = opts.line:sub(opts.col, opts.col + 1)
      return vim.tbl_contains({ '$$', '()', '{}', '[]' }, pair)
    end)
    :with_move(cond.none())
    :with_cr(cond.none())
    :with_del(function(opts)
      local col = vim.api.nvim_win_get_cursor(0)[2]
      local context = opts.line:sub(col - 1, col + 2)
      return vim.tbl_contains({ '$  $', '(  )', '{  }', '[  ]' }, context)
    end),
  Rule("$ "," ","tex")
    :with_pair(cond.not_after_regex(" "))
    :with_del(cond.none()),
  Rule("[ "," ","tex")
    :with_pair(cond.not_after_regex(" "))
    :with_del(cond.none()),
  Rule("{ "," ","tex")
    :with_pair(cond.not_after_regex(" "))
    :with_del(cond.none()),
  Rule("( "," ","tex")
    :with_pair(cond.not_after_regex(" "))
    :with_del(cond.none()),
  }
)


require('nvim-autopairs').get_rule('$'):with_move(function(opts)
  return opts.char == opts.next_char:sub(1, 1)
end)


local cmp_autopairs = require "nvim-autopairs.completion.cmp"
local cmp_status_ok, cmp = pcall(require, "cmp")
if not cmp_status_ok then
  return
end
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done { map_char = { tex = "" } })
