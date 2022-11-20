local cmp_status_ok, cmp = pcall(require, "cmp")
if not cmp_status_ok then
  return
end

local snip_status_ok, luasnip = pcall(require, "luasnip")
if not snip_status_ok then
  return
end

require("luasnip/loaders/from_vscode").lazy_load()

local check_backspace = function()
  local col = vim.fn.col "." - 1
  return col == 0 or vim.fn.getline("."):sub(col, col):match "%s"
end

--   פּ ﯟ   some other good icons
local kind_icons = {
  Text = "",
  Method = "m",
  Function = "",
  Constructor = "",
  Field = "",
  Variable = "",
  Class = "",
  Interface = "",
  Module = "",
  Property = "",
  Unit = "",
  Value = "",
  Enum = "",
  Keyword = "",
  Snippet = "",
  Color = "",
  File = "",
  Reference = "",
  Folder = "",
  EnumMember = "",
  Constant = "",
  Struct = "",
  Event = "",
  Operator = "",
  TypeParameter = "",
}
-- find more here: https://www.nerdfonts.com/cheat-sheet

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body) -- For `luasnip` users.
    end,
  },
  mapping = {
    ["<C-k>"] = cmp.mapping.select_prev_item(),
		["<C-j>"] = cmp.mapping.select_next_item(),
    ["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-1), { "i", "c" }),
    ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(1), { "i", "c" }),
    -- ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
    -- ["<C-y>"] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
    ["<C-e>"] = cmp.mapping {
      i = cmp.mapping.abort(),
      c = cmp.mapping.close(),
    },

    -- Accept currently selected item. If none selected, `select` first item.
    -- Set `select` to `false` to only confirm explicitly selected items.
    ["<CR>"] = cmp.mapping.confirm { select = false },
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expandable() then
        luasnip.expand()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      elseif check_backspace() then
        fallback()
      else
        fallback()
      end
    end, {
      "i",
      "s",
    }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, {
      "i",
      "s",
    }),
  },
  formatting = {
    fields = { "kind", "abbr", "menu" },
    format = function(entry, vim_item)
      -- Kind icons
      vim_item.kind = string.format("%s", kind_icons[vim_item.kind])
      -- vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind) -- This concatonates the icons with the name of the item kind
      vim_item.menu = ({
        nvim_lsp = "[LSP]",
        luasnip = "[Snippet]",
        buffer = "[Buffer]",
        path = "[Path]",
        cmdline = "[LSP]",
      })[entry.source.name]
      return vim_item
    end,
  },
  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "buffer" },
    { name = "dictionary" },
    { name = "path" },
    { name = "cmdline" }, -- was causing trouble
    { name = "lua-latex-symbols",
      option = { cache = true },
      filetype = { "tex", "latex" },
    }
      -- The `cache` option is used to determine whether to generate the list of symbols every time you start Neovim, or if it should be stored in a cache file to save time. I strongly do not advise changing this option because the data used for this plugin has not been updated since 2011.
    -- { name = "dictionary" },
  },
  confirm_opts = {
    behavior = cmp.ConfirmBehavior.Replace,
    select = false,
  },
  window = {
    documentation = {
      border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
    },
  },
  experimental = {
    ghost_text = true,
    native_menu = false,
  },
}


-- TODO was trying to get <C-j>, <C-k> to work in the command line
-- cmp-cmdline
-- `/` cmdline setup.
cmp.setup.cmdline('/', {
  mapping = cmp.mapping.preset.cmdline({
    -- ['<C-j>'] = cmp.mapping(cmp.mapping.select_next_item()),
    -- ['<C-k>'] = cmp.mapping(cmp.mapping.select_prev_item()),
    ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
  }),
  sources = {
    { name = 'buffer' }
  }
})

-- `:` cmdline setup.
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline({
    -- ['<C-j>'] = cmp.mapping(cmp.mapping.select_next_item()),
    -- ['<C-k>'] = cmp.mapping(cmp.mapping.select_prev_item()),
    ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
  }),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline',
      option = {
        ignore_cmds = { 'Man', '!' }
      }
    },
    mapping = cmp.mapping.preset.cmdline({}), -- fixes supertab
  }),
})

-- -- Conseal menu if text after cursor, or no text before cursor
-- api.nvim_create_autocmd(
--   {"TextChangedI", "TextChangedP"},
--   {
--     callback = function()
--       local line = vim.api.nvim_get_current_line()
--       local cursor = vim.api.nvim_win_get_cursor(0)[2]
--
--       local current = string.sub(line, cursor, cursor + 1)
--       if current == "." or current == "," or current == " " then
--         require('cmp').close()
--       end
--
--       local before_line = string.sub(line, 1, cursor + 1)
--       local after_line = string.sub(line, cursor + 1, -1)
--       if not string.match(before_line, '^%s+$') then
--         if after_line == "" or string.match(before_line, " $") or string.match(before_line, "%.$") then
--           require('cmp').complete()
--         end
--       end
--   end,
--   pattern = "*"
-- })
