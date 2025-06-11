return {
  {
    "saghen/blink.compat",
    version = "2.*",
    lazy = true,
    opts = {
      debug = false,
    },
  },
  {
    "saghen/blink.cmp",
    version = "1.*", 
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "saghen/blink.compat",
      "L3MON4D3/LuaSnip",
      "micangl/cmp-vimtex",
    },
    opts = {
      keymap = {
        preset = 'default',
        ['<C-k>'] = { 'select_prev', 'fallback' },
        ['<C-j>'] = { 'select_next', 'fallback' },
        ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<Tab>'] = { 'snippet_forward', 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'snippet_backward', 'select_prev', 'fallback' },
      },
      
      appearance = {
        kind_icons = {
          Function = "󰊕",
          Constructor = "",
          Text = "󰦨",
          Method = "",
          Field = "󰅪",
          Variable = "󱃮",
          Class = "",
          Interface = "",
          Module = "",
          Property = "",
          Unit = "",
          Value = "󰚯",
          Enum = "",
          Keyword = "",
          Snippet = "",
          Color = "󰌁",
          File = "",
          Reference = "",
          Folder = "",
          EnumMember = "",
          Constant = "󰀫",
          Struct = "",
          Event = "",
          Operator = "󰘧",
          TypeParameter = "",
        }
      },
      
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer', 'vimtex' },
        cmdline = function()
          local type = vim.fn.getcmdtype()
          if type == '/' or type == '?' then
            return { 'buffer' }
          elseif type == ':' then
            return { 'cmdline', 'path' }
          end
          return {}
        end,
        providers = {
          buffer = { 
            max_items = 8,
            keyword_length = 3,
          },
          snippets = { 
            opts = {
              friendly_snippets = false,
              search_paths = { vim.fn.stdpath("config") .. "/snippets" },
            }
          },
          vimtex = {
            name = 'vimtex',
            module = 'blink.compat.source',
            opts = {
              additional_information = {
                info_in_menu = true,
                info_in_window = true,
                info_max_length = 60,
                match_against_info = true,
                symbols_in_menu = true,
              },
              bibtex_parser = { enabled = true },
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
            },
          },
        }
      },
      
      trigger = {
        completion = {
          keyword_length = 1,
          debounce = 500,
        }
      },
      
      performance = {
        trigger_debounce_time = 500,
        throttle = 550,
        fetching_timeout = 80,
      },
    }
  }
}