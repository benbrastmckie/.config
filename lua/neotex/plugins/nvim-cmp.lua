return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-buffer", -- source for text in buffer
    "hrsh7th/cmp-path", -- source for file system paths
    "L3MON4D3/LuaSnip", -- snippet engine
    "saadparwaiz1/cmp_luasnip", -- for autocompletion
    "rafamadriz/friendly-snippets", -- useful snippets
    "onsails/lspkind.nvim", -- vs-code like pictograms
  },
  config = function()

    local check_backspace = function()
      local col = vim.fn.col "." - 1
      return col == 0 or vim.fn.getline("."):sub(col, col):match "%s"
    end

    local cmp = require("cmp")

    local luasnip = require("luasnip")

    local lspkind = require("lspkind")

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

    local cmp_window = require "cmp.config.window"

    local cmp_mapping = require "cmp.config.mapping"

    cmp.setup({
      completion = {
        completeopt = "menu,menuone,preview,noselect",
        keyword_length = 1,
      },
      snippet = { -- configure how nvim-cmp interacts with snippet engine
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
        ["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        -- ["<C-n>"] = cmp.mapping.complete(), -- show completion suggestions
        ["<C-h>"] = cmp.mapping.abort(), -- close completion window
        ["<C-l>"] = cmp.mapping.confirm({ select = false }),
        -- ["<Tab>"] = cmp_mapping(function(fallback)
        --   -- if cmp.visible() then
        --   --   cmp.select_next_item()
        --   if luasnip.expand_or_locally_jumpable() then
        --     luasnip.expand_or_jump()
        --   elseif jumpable(1) then
        --     luasnip.jump(1)
        --   elseif has_words_before() then
        --     -- cmp.complete()
        --     fallback()
        --   else
        --     fallback()
        --   end
        -- end, { "i", "s" }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          -- elseif luasnip.expandable() then
          --   luasnip.expand()
          elseif luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
          elseif check_backspace() then
              cmp.complete()
            fallback()
          else
            fallback()
          end
        end, { "i", "s" }),
        -- ["<S-Tab>"] = cmp_mapping(function(fallback)
        --   if cmp.visible() then
        --     cmp.select_prev_item()
        --   elseif luasnip.jumpable(-1) then
        --     luasnip.jump(-1)
        --   else
        --     fallback()
        --   end
        -- end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          -- if cmp.visible() then
          --   cmp.select_prev_item()
          if luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
        -- ["<CR>"] = cmp_mapping(function(fallback)
        --   if cmp.visible() then
        --     -- local confirm_opts = vim.deepcopy(lvim.builtin.cmp.confirm_opts) -- avoid mutating the original opts below
        --     local is_insert_mode = function()
        --       return vim.api.nvim_get_mode().mode:sub(1, 1) == "i"
        --     end
        --     if is_insert_mode() then -- prevent overwriting brackets
        --       confirm_opts.behavior = ConfirmBehavior.Insert
        --     end
        --     local entry = cmp.get_selected_entry()
        --     local is_copilot = entry and entry.source.name == "copilot"
        --     if is_copilot then
        --       confirm_opts.behavior = ConfirmBehavior.Replace
        --       confirm_opts.select = true
        --     end
        --     if cmp.confirm(confirm_opts) then
        --       return -- success, exit early
        --     end
        --   end
        --   fallback() -- if not exited early, always fallback
        -- end),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
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
          -- vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind) -- This concatonates the icons with the name of the item kind
          vim_item.menu = ({
            -- omni = (vim.inspect(vim_item.menu):gsub('%"', "")),
            -- vimtex = (vim_item.menu ~= nil and vim_item.menu or ""),
            -- vimtex = vim_item.menu,
            vimtex = "[VimTex]" .. (vim_item.menu ~= nil and vim_item.menu or ""),
            nvim_lsp = "[LSP]",
            luasnip = "[Snippet]",
            buffer = "[Buffer]",
            spell = "[Spell]",
            latex_symbols = "[Symbols]",
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
        -- { name = "omni" },
        { name = "buffer" }, -- text within current buffer
        { name = "spell",
          keyword_length = 4,
          option = {
              keep_all_entries = false,
              enable_in_context = function()
                  return true
              end
          },
        },
        { name = "latex_symbols",
          filetype = { "tex", "latex" },
          option = { cache = true }, -- avoids reloading each time
        },
        { name = "path" },
      }),
      -- configure lspkind for vs-code like pictograms in completion menu
      confirm_opts = {
        behavior = cmp.ConfirmBehavior.Replace,
        select = false,
      },
      view = {
        entries = 'custom',
      },
      window = {
        documentation = {
          border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
        }
      },
      performance = {
         trigger_debounce_time = 500,
         throttle = 550,
         fetching_timeout = 80,
      },
    })
  end,
}
