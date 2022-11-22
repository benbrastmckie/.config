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
  -- enable_check_bracket_line = false,
  -- fast_wrap = {
  --   map = "<M-e>",
  --   chars = { "{", "[", "(", '"', "'" },
  --   pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
  --   offset = 0, -- Offset from pattern match
  --   end_key = "$",
  --   keys = "qwertyuiopzxcvbnmasdfghjkl",
  --   check_comma = true,
  --   highlight = "PmenuSel",
  --   highlight_grey = "LineNr",
  -- },
}

local Rule = require('nvim-autopairs.rule')
local npairs = require('nvim-autopairs')

-- npairs.add_rule(Rule("$$","$$","tex"))
npairs.add_rules({
  Rule("`","'","tex"),
  Rule("$","$","tex"),
  Rule("$ "," ","tex"),
  Rule("[ "," ","tex"),
  Rule("{ "," ","tex"),
  Rule("( "," ","tex"),
  }
)

-- npairs.add_rules({
--   Rule("$$","$$","tex")
--     :with_pair(function(opts)
--         print(vim.inspect(opts))
--         if opts.line=="aa $$" then
--         -- don't add pair on that line
--           return false
--         end
--     end)
--    }
-- )



local cmp_autopairs = require "nvim-autopairs.completion.cmp"
local cmp_status_ok, cmp = pcall(require, "cmp")
if not cmp_status_ok then
  return
end
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done { map_char = { tex = "" } })
