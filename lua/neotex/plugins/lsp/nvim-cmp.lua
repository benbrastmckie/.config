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

    local check_backspace = function()
      local col = vim.fn.col "." - 1
      return col == 0 or vim.fn.getline("."):sub(col, col):match "%s"
    end

    local cmp = require("cmp")

    local luasnip = require("luasnip")

    -- local lspkind = require("lspkind") -- goes with lspkind.nvim above

    -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
    require("luasnip.loaders.from_vscode").lazy_load()

    --   פּ ﯟ   some other good icons
    local kind_icons = {
      Text = "",
      -- Text = "",
      Method = "m",
      Function = "",
      -- Function = "",
      Constructor = "",
      Field = "",
      Variable = "",
      Class = "",
      -- Class = "",
      Interface = "",
      Module = "",
      Property = "",
      Unit = "",
      Value = "",
      -- Value = "",
      Enum = "",
      Keyword = "",
      -- Keyword = "",
      Snippet = "",
      Color = "",
      -- Color = "",
      File = "",
      -- File = "",
      Reference = "",
      Folder = "",
      -- Folder = "",
      EnumMember = "",
      Constant = "",
      -- Constant = "",
      Struct = "",
      Event = "",
      Operator = "",
      TypeParameter = "",
      -- TypeParameter = "",
    }
    -- find more here: https://www.nerdfonts.com/cheat-sheet

    cmp.setup({
      completion = {
        completeopt = "menu,noselect",
        -- completeopt = "menuone,preview,noinsert",
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
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          -- if cmp.visible() then
          --   cmp.select_next_item()
          -- if luasnip.expandable() then
          --   luasnip.expand()
          if luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
          elseif check_backspace() then
              cmp.complete()
            fallback()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          -- if cmp.visible() then
          --   cmp.select_prev_item()
          if luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      }),
      -- formatting for autocompletion
      formatting = {
        -- NOTE: from Josean
        -- format = lspkind.cmp_format({
        --   maxwidth = 50,
        --   ellipsis_char = "...",
        -- }),
        fields = { "kind", "abbr", "menu" },
        format = function(entry, vim_item)
          -- Kind icons
          vim_item.kind = string.format("%s", kind_icons[vim_item.kind])
          vim_item.menu = ({
            -- omni = (vim.inspect(vim_item.menu):gsub('%"', "")),
            vimtex = (vim_item.menu ~= nil and vim_item.menu or "[VimTex]"),
            luasnip = "[Snippet]",
            nvim_lsp = "[LSP]",
            buffer = "[Buffer]",
            spell = "[Spell]",
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
