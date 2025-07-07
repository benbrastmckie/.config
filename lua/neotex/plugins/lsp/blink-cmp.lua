return {
  {
    "saghen/blink.compat",
    version = "2.*",
    lazy = true,
    opts = {
      debug = false,
      impersonate_nvim_cmp = true,
    },
  },
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "saghen/blink.compat",
      "L3MON4D3/LuaSnip",
      {
        "micangl/cmp-vimtex",
        config = function()
          require('cmp_vimtex').setup({
            additional_information = {
              info_in_menu = true,
              info_in_window = true,
              info_max_length = 60,
              match_against_info = true,
              symbols_in_menu = true,
            },
            bibtex_parser = {
              enabled = true,
            },
            search = {
              browser = "xdg-open",
              default = "google_scholar",
              search_engines = {
                google_scholar = {
                  name = "Google Scholar",
                  get_url = function(query)
                    return string.format("https://scholar.google.com/scholar?hl=en&q=%s", query)
                  end,
                },
              },
            },
          })
        end,
      },
    },
    config = function(_, opts)
      require('blink.cmp').setup(opts)

      -- Simple LaTeX setup - let blink.cmp handle everything through VimTeX compatibility
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "tex",
        callback = function()
          -- Set omnifunc for VimTeX integration
          vim.bo.omnifunc = 'vimtex#complete#omnifunc'
        end,
      })
    end,

    opts = {
      snippets = {
        preset = 'luasnip'
      },

      keymap = {
        preset = 'default',
        ['<C-k>'] = { 'select_prev', 'fallback' },
        ['<C-j>'] = { 'select_next', 'fallback' },
        ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
        ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<C-e>'] = { 'hide', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<Tab>'] = { 'snippet_forward', 'select_and_accept', 'fallback' },
        ['<S-Tab>'] = { 'snippet_backward', 'select_prev', 'fallback' },
      },

      appearance = {
        kind_icons = {
          Text = "󰦨",
          Method = "󰆧",
          Function = "󰊕",
          Constructor = "",
          Field = "󰇽",
          Variable = "󰂡",
          Class = "󰠱",
          Interface = "",
          Module = "",
          Property = "󰜢",
          Unit = "",
          Value = "󰎠",
          Enum = "",
          Keyword = "󰌋",
          Snippet = "",
          Color = "󰏘",
          File = "󰈙",
          Reference = "",
          Folder = "󰉋",
          EnumMember = "",
          Constant = "󰀫",
          Struct = "",
          Event = "",
          Operator = "󰘧",
          TypeParameter = "󰅲",
        }
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
        per_filetype = {
          tex = { 'lsp', 'omni', 'snippets', 'path', 'buffer' }, -- Use 'omni' instead of 'vimtex'
          lua = { 'lsp', 'path', 'snippets', 'buffer' },
          python = { 'lsp', 'path', 'snippets', 'buffer' },
        },
        providers = {
          lsp = {
            name = 'lsp',
            enabled = function()
              -- Disable LSP source in LaTeX reference contexts to avoid duplicates with VimTeX
              if vim.bo.filetype == 'tex' then
                local line = vim.api.nvim_get_current_line()
                local col = vim.api.nvim_win_get_cursor(0)[2]
                local before_cursor = line:sub(1, col)

                -- Disable in reference contexts only (keep for citations and general editing)
                if before_cursor:match('\\ref{[^}]*$') or
                    before_cursor:match('\\[Cc]ref{[^}]*$') or
                    before_cursor:match('\\eqref{[^}]*$') or
                    before_cursor:match('\\autoref{[^}]*$') then
                  return false
                end
              end
              return true
            end,
            max_items = 100,
            min_keyword_length = 1,
            score_offset = 0,
            fallbacks = { 'buffer' },
          },
          path = {
            name = 'path',
            enabled = function()
              -- Disable path source in LaTeX citation and reference contexts
              if vim.bo.filetype == 'tex' then
                local line = vim.api.nvim_get_current_line()
                local col = vim.api.nvim_win_get_cursor(0)[2]
                local before_cursor = line:sub(1, col)

                -- Keep enabled for include/input contexts, disable for citations and references
                if before_cursor:match('\\cite[%w]*{[^}]*$') or
                    before_cursor:match('\\citep?[%w]*{[^}]*$') or
                    before_cursor:match('\\citet?[%w]*{[^}]*$') or
                    before_cursor:match('\\ref{[^}]*$') or
                    before_cursor:match('\\[Cc]ref{[^}]*$') or
                    before_cursor:match('\\eqref{[^}]*$') or
                    before_cursor:match('\\autoref{[^}]*$') then
                  return false
                end
              end
              return true
            end,
            max_items = 20,
            min_keyword_length = 1,
          },
          buffer = {
            name = 'buffer',
            enabled = function()
              -- Disable buffer source in LaTeX citation and reference contexts
              if vim.bo.filetype == 'tex' then
                local line = vim.api.nvim_get_current_line()
                local col = vim.api.nvim_win_get_cursor(0)[2]
                local before_cursor = line:sub(1, col)

                -- Disable in citation and reference contexts
                if before_cursor:match('\\cite[%w]*{[^}]*$') or
                    before_cursor:match('\\citep?[%w]*{[^}]*$') or
                    before_cursor:match('\\citet?[%w]*{[^}]*$') or
                    before_cursor:match('\\ref{[^}]*$') or
                    before_cursor:match('\\[Cc]ref{[^}]*$') or
                    before_cursor:match('\\eqref{[^}]*$') or
                    before_cursor:match('\\autoref{[^}]*$') then
                  return false
                end
              end
              return true
            end,
            max_items = 8,
            min_keyword_length = 2,
            fallbacks = {},
          },
          omni = {
            name = 'omni',
            enabled = function()
              return vim.bo.filetype == 'tex' and vim.bo.omnifunc ~= ''
            end,
            async = true,
            timeout_ms = 5000,
            max_items = 50,
            min_keyword_length = 0,
            score_offset = 100,
          },
          cmdline = {
            name = 'cmdline',
            enabled = true,
            max_items = 50,
            min_keyword_length = 1,
          },
        },
      },

      -- trigger = {
      --   completion = {
      --     keyword_length = 1,
      --     blocked_trigger_characters = { ' ', '\n', '\t' },
      --     show_in_snippet = true,
      --     debounce = 60,
      --   },
      --   signature_help = {
      --     enabled = false,
      --   },
      -- },

      completion = {
        accept = {
          auto_brackets = {
            enabled = true,
            default_brackets = { '(', ')' },
            kind_resolution = {
              enabled = true,
              blocked_filetypes = { 'tex', 'latex' } -- Avoid conflicts with LaTeX
            },
            semantic_token_resolution = {
              enabled = true,
              blocked_filetypes = { 'tex', 'latex', 'lean' },
              timeout_ms = 400
            }
          }
        },
        trigger = {
          prefetch_on_insert = true,
          show_in_snippet = true,
          show_on_keyword = true,
          show_on_trigger_character = true,
          show_on_blocked_trigger_characters = { ' ', '\n', '\t' },
          show_on_accept_on_trigger_character = true,
          show_on_insert_on_trigger_character = true,
          show_on_x_blocked_trigger_characters = { "'", '"', '(' }
        },
        menu = {
          max_height = 15,
          auto_show = true,
          draw = {
            treesitter = { "lsp" },
            columns = {
              { 'kind_icon' },
              { 'label',    'label_description', gap = 1 }
            },
            components = {
              kind_icon = {
                text = function(ctx) return ' ' .. ctx.kind_icon .. ' ' end,
                highlight = function(ctx)
                  return { { group = ctx.kind_hl, priority = 20000 } }
                end
              }
            }
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 250,
          treesitter_highlighting = true,
        },
        ghost_text = {
          enabled = false,
        },
      },

      -- fuzzy = {
      --   use_typo_resistance = true,
      --   use_frecency = true,
      --   use_proximity = true,
      --   sorts = { 'label', 'kind', 'score' },
      -- },

      cmdline = {
        enabled = true,
        completion = {
          menu = {
            auto_show = true
          },
          trigger = {
            show_on_blocked_trigger_characters = {},
            show_on_x_blocked_trigger_characters = {}
          }
        },
        sources = function()
          local type = vim.fn.getcmdtype()
          if type == '/' or type == '?' then
            return { 'buffer' }
          elseif type == ':' then
            return { 'cmdline', 'path' }
          end
          return {}
        end,
        keymap = {
          preset = 'default',
          ['<C-k>'] = { 'select_prev', 'fallback' },
          ['<C-j>'] = { 'select_next', 'fallback' },
          ['<CR>'] = { 'accept_and_enter', 'fallback' },
          ['<C-e>'] = { 'hide', 'fallback' },
          ['<Tab>'] = { 'select_and_accept', 'fallback' },
        },
      },
    }
  }
}

