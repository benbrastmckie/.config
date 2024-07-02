return {
  "hrsh7th/nvim-cmp",
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = {
    "hrsh7th/cmp-buffer", -- source for text in buffer
    "hrsh7th/cmp-path", -- source for file system paths
    "L3MON4D3/LuaSnip", -- snippet engine
    "saadparwaiz1/cmp_luasnip", -- for autocompletion
    -- "rafamadriz/friendly-snippets", -- useful snippets
    -- "onsails/lspkind.nvim", -- vs-code like pictograms
    "hrsh7th/cmp-cmdline",
    "petertriho/cmp-git",
    "f3fora/cmp-spell",
    "micangl/cmp-vimtex",
    -- "aspeddro/cmp-pandoc.nvim",
  },
  config = function()

    local cmp = require("cmp")

    local luasnip = require("luasnip")

    local kind_icons = {
      article = "󰧮",
      book = "",
      incollection = "󱓷",
      Function = "󰊕",
      Constructor = "",
      Text = "󰦨",
      Method = "",
      Field = "󰅪",
      Variable = "󱃮",
      Class = "",
      Interface = "",
      Module = "",
      Property = "",
      Unit = "",
      Value = "󰚯",
      Enum = "",
      Keyword = "",
      Snippet = "",
      Color = "󰌁",
      -- Color = "",
      File = "",
      Reference = "",
      Folder = "",
      EnumMember = "",
      -- spell = "",
      -- EnumMember = "",
      Constant = "󰀫",
      Struct = "",
      -- Struct = "",
      Event = "",
      Operator = "󰘧",
      TypeParameter = "",
    }
    -- find more here: https://www.nerdfonts.com/cheat-sheet

    cmp.setup({
      completion = {
        completeopt = "menu,noselect",
        -- completeopt = "menuone,preview,noinsert,noselect",
        keyword_length = 1,
      },
      snippet = { -- configure how nvim-cmp interacts with snippet engine
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-k>"] = cmp.mapping(cmp.mapping.select_prev_item(), { "i", "c" }),
        ["<C-j>"] = cmp.mapping(cmp.mapping.select_next_item(), { "i", "c" }),
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        -- ["<C-n>"] = cmp.mapping.complete(), -- show completion suggestions
        -- ["<C-h>"] = cmp.mapping.abort(), -- close completion window
        -- ["<C-l>"] = cmp.mapping.confirm({ select = false }),
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
        -- supertab
        ["<Tab>"] = cmp.mapping(function(fallback)
          if luasnip.expandable() then
            luasnip.expand()
          elseif luasnip.locally_jumpable(1) then
            luasnip.jump(1)
          elseif cmp.visible() then
            cmp.select_next_item()
          else
            fallback()
          end
        end, { "i", "s" }),
          -- BONEYARD
          -- if luasnip.expand_or_locally_jumpable() then
          --   luasnip.expand_or_jump()
          -- elseif luasnip.locally_jumpable() then
          --   luasnip.jump()
          --   cmp.confirm()
          -- elseif has_words_before() then
          --  cmp.complete()
        ["<S-Tab>"] = cmp.mapping(function() -- could be: function(fallback) -- OR: function(delete-two-spaces????)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.locally_jumpable(-1) then
            luasnip.jump(-1)
          else
            -- fallback()
          end
        end, { "i", "s" }),
      }),
      -- formatting for autocompletion
      formatting = {
        fields = { "kind", "abbr", "menu" },
        format = function(entry, vim_item)
          vim_item.kind = string.format("%s", kind_icons[vim_item.kind]) -- Kind icons
          vim_item.menu = ({
            -- vimtex = (vim_item.menu ~= nil and vim_item.menu or "[VimTex]"),
            -- vimtex = test_fn(vim_item.menu, entry.source.name),
            vimtex = vim_item.menu,
            luasnip = "[Snippet]",
            nvim_lsp = "[LSP]",
            buffer = "[Buffer]",
            spell = "[Spell]",
            -- orgmode = "[Org]",
            -- latex_symbols = "[Symbols]",
            cmdline = "[CMD]",
            path = "[Path]",
          })[entry.source.name]
          return vim_item
        end,
      },
      -- sources for autocompletion
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" }, -- snippets
        { name = "vimtex" },
        -- { name = "orgmode" },
        -- { name = "pandoc" },
        -- { name = "omni" },
        { name = "buffer", keyword_length = 3 }, -- text within current buffer
        { name = "spell",
          keyword_length = 4,
          option = {
              keep_all_entries = false,
              enable_in_context = function()
                  return true
              end
          },
        },
        { name = "path" },
      }),
      confirm_opts = {
        behavior = cmp.ConfirmBehavior.Replace,
        select = false,
      },
      view = {
        entries = 'custom',
      },
      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
        -- completion = {
        --   border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
        -- },
        -- documentation = {
        --   border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
        -- },
      },
      performance = {
         trigger_debounce_time = 500,
         throttle = 550,
         fetching_timeout = 80,
      },
    })

    -- `/` cmdline setup.
    cmp.setup.cmdline('/', {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        {name = 'buffer'}
      }
    })

    -- `:` cmdline setup.
    cmp.setup.cmdline(':', {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        {name = 'path'},
        {name = 'cmdline'}
      }
    })

  end,
}
