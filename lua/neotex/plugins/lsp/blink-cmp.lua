return {
  {
    "saghen/blink.compat",
    version = "2.*",
    lazy = true,
    config = function()
      require('blink.compat').setup({
        debug = false,
        impersonate_nvim_cmp = true,
      })
    end,
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
      
      -- Custom LaTeX citation completion handler
      local function setup_latex_completion()
        -- Create autocmd for LaTeX files
        vim.api.nvim_create_autocmd("FileType", {
          pattern = "tex",
          callback = function()
            -- Custom function to handle citation completion
            local function latex_complete()
              local line = vim.api.nvim_get_current_line()
              local col = vim.api.nvim_win_get_cursor(0)[2]
              local before_cursor = line:sub(1, col)
              
              -- Check if we're in a citation context
              if before_cursor:match('\\cite[%w]*{[^}]*$') or 
                 before_cursor:match('\\citep?[%w]*{[^}]*$') or
                 before_cursor:match('\\citet?[%w]*{[^}]*$') then
                -- Use VimTeX omnifunc for citations
                return vim.fn['vimtex#complete#omnifunc'](vim.fn.col('.') - 1, '')
              end
              
              return nil -- Let blink.cmp handle other cases
            end
            
            -- Override Tab key for citation contexts in LaTeX
            vim.keymap.set('i', '<Tab>', function()
              local line = vim.api.nvim_get_current_line()
              local col = vim.api.nvim_win_get_cursor(0)[2]
              local before_cursor = line:sub(1, col)
              
              -- In citation context, hide blink.cmp and trigger VimTeX completion
              if before_cursor:match('\\cite[%w]*{[^}]*$') or 
                 before_cursor:match('\\citep?[%w]*{[^}]*$') or
                 before_cursor:match('\\citet?[%w]*{[^}]*$') then
                -- Hide blink.cmp menu if visible
                local blink = require('blink.cmp')
                if blink.is_visible() then
                  blink.hide()
                end
                return '<C-x><C-o>'
              else
                -- Use blink.cmp's Tab handling
                local blink = require('blink.cmp')
                if blink.is_visible() then
                  return blink.accept()
                else
                  return '<Tab>'
                end
              end
            end, { expr = true, buffer = true, desc = "Smart LaTeX completion" })
            
            -- Set omnifunc to VimTeX for this buffer
            vim.bo.omnifunc = 'vimtex#complete#omnifunc'
            
            -- Context detection function
            local function get_latex_context()
              local line = vim.api.nvim_get_current_line()
              local col = vim.api.nvim_win_get_cursor(0)[2]
              local before_cursor = line:sub(1, col)
              
              -- Citation contexts
              if before_cursor:match('\\cite[%w]*{[^}]*$') or 
                 before_cursor:match('\\citep?[%w]*{[^}]*$') or
                 before_cursor:match('\\citet?[%w]*{[^}]*$') then
                return 'citation'
              end
              
              -- Reference contexts
              if before_cursor:match('\\ref{[^}]*$') or
                 before_cursor:match('\\[Cc]ref{[^}]*$') or
                 before_cursor:match('\\eqref{[^}]*$') or
                 before_cursor:match('\\autoref{[^}]*$') then
                return 'reference'
              end
              
              -- Package contexts
              if before_cursor:match('\\usepackage{[^}]*$') or
                 before_cursor:match('\\RequirePackage{[^}]*$') then
                return 'package'
              end
              
              -- Begin/end environment contexts
              if before_cursor:match('\\begin{[^}]*$') or
                 before_cursor:match('\\end{[^}]*$') then
                return 'environment'
              end
              
              return 'general'
            end
            
            -- Simple setup - let the source-level filtering handle context awareness
            vim.bo.omnifunc = 'vimtex#complete#omnifunc'
            
            -- Auto-trigger VimTeX completion in citation contexts
            vim.api.nvim_create_autocmd("TextChangedI", {
              buffer = 0,
              callback = function()
                local context = get_latex_context()
                
                if context == 'citation' then
                  local line = vim.api.nvim_get_current_line()
                  local col = vim.api.nvim_win_get_cursor(0)[2]
                  local before_cursor = line:sub(1, col)
                  
                  -- Only trigger if we have some content to complete
                  local content = before_cursor:match('\\cite[%w]*{([^}]*)$')
                  if content and #content > 0 then
                    vim.defer_fn(function()
                      if vim.fn.mode() == 'i' and get_latex_context() == 'citation' then
                        -- Set completion options to prevent auto-selection
                        local old_completeopt = vim.o.completeopt
                        vim.o.completeopt = 'menu,noselect'
                        
                        -- Trigger VimTeX omnifunc
                        vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<C-x><C-o>', true, false, true), 'n')
                        
                        -- Restore original completeopt after completion
                        vim.defer_fn(function()
                          vim.o.completeopt = old_completeopt
                        end, 200)
                      end
                    end, 100)
                  end
                end
              end,
            })
            
            -- Manual completion with context awareness
            vim.keymap.set('i', '<C-n>', function()
              local context = get_latex_context()
              
              if context == 'citation' or context == 'reference' or context == 'package' or context == 'environment' then
                return '<C-x><C-o>' -- Use VimTeX omnifunc
              else
                -- Use blink.cmp for general contexts
                local blink = require('blink.cmp')
                blink.show()
                return ''
              end
            end, { expr = true, buffer = true, desc = "Context-aware LaTeX completion" })
          end,
        })
      end
      
      -- Set up the LaTeX completion after a brief delay
      vim.defer_fn(setup_latex_completion, 100)
      
      -- Set default Tab behavior for non-LaTeX files
      vim.keymap.set('i', '<Tab>', function()
        if vim.bo.filetype == 'tex' then
          -- LaTeX files have their own Tab handler set up above
          return '<Tab>'
        else
          -- Standard blink.cmp Tab behavior
          local blink = require('blink.cmp')
          if blink.is_visible() then
            return blink.accept()
          else
            return '<Tab>'
          end
        end
      end, { expr = true, desc = "Smart Tab completion" })
    end,
    
    opts = {
      keymap = {
        preset = 'default',
        ['<C-k>'] = { 'select_prev', 'fallback' },
        ['<C-j>'] = { 'select_next', 'fallback' },
        ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' },
        -- Tab is handled specially for LaTeX files, so we'll set it conditionally
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
        per_filetype = {
          tex = { 'lsp', 'vimtex', 'snippets', 'buffer' }
        },
        providers = {
          buffer = { 
            max_items = 8,
            keyword_length = 3,
            -- Disable buffer source in citation contexts
            enabled = function()
              if vim.bo.filetype == 'tex' then
                local line = vim.api.nvim_get_current_line()
                local col = vim.api.nvim_win_get_cursor(0)[2]
                local before_cursor = line:sub(1, col)
                
                -- Disable in citation contexts
                if before_cursor:match('\\cite[%w]*{[^}]*$') or 
                   before_cursor:match('\\citep?[%w]*{[^}]*$') or
                   before_cursor:match('\\citet?[%w]*{[^}]*$') then
                  return false
                end
              end
              return true
            end,
          },
          snippets = { 
            min_keyword_length = 1,
            -- Disable snippets in citation contexts
            enabled = function()
              if vim.bo.filetype == 'tex' then
                local line = vim.api.nvim_get_current_line()
                local col = vim.api.nvim_win_get_cursor(0)[2]
                local before_cursor = line:sub(1, col)
                
                if before_cursor:match('\\cite[%w]*{[^}]*$') or 
                   before_cursor:match('\\citep?[%w]*{[^}]*$') or
                   before_cursor:match('\\citet?[%w]*{[^}]*$') then
                  return false
                end
              end
              return true
            end,
            opts = {
              friendly_snippets = false,
              search_paths = { vim.fn.stdpath("config") .. "/snippets" },
            }
          },
          vimtex = {
            name = 'vimtex',
            module = 'blink.compat.source',
            score_offset = 100, -- Give VimTeX higher priority
            opts = {
              trigger_characters = { '\\', '{', '}', ',', ' ' },
            },
          },
        }
      },
      
      cmdline = {
        sources = function()
          local type = vim.fn.getcmdtype()
          if type == '/' or type == '?' then
            return { 'buffer' }
          elseif type == ':' then
            return { 'cmdline', 'path' }
          end
          return {}
        end,
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