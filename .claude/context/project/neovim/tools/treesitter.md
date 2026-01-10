# Treesitter in Neovim

## Overview
nvim-treesitter provides advanced syntax highlighting, code navigation, and text objects through incremental parsing. It understands code structure rather than using regex patterns.

## Setup

### Basic Configuration
```lua
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    ensure_installed = {
      "bash", "c", "lua", "luadoc",
      "markdown", "markdown_inline",
      "python", "query", "vim", "vimdoc",
    },
    highlight = { enable = true },
    indent = { enable = true },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
```

## Parser Installation

### Commands
```vim
:TSInstall lua          " Install lua parser
:TSInstall all          " Install all maintained parsers
:TSUpdate               " Update all parsers
:TSUninstall lua        " Remove parser
```

### Automatic Installation
```lua
opts = {
  auto_install = true,  -- Install missing parsers on enter
}
```

### Ensure Installed
```lua
opts = {
  ensure_installed = {
    "bash", "c", "cpp", "css", "go", "html",
    "javascript", "json", "lua", "markdown",
    "python", "rust", "typescript", "vim", "yaml",
  },
}
```

## Highlighting

### Enable/Disable
```lua
opts = {
  highlight = {
    enable = true,
    disable = { "latex" },  -- Disable for specific languages
    -- Or disable for large files
    disable = function(lang, buf)
      local max_size = 100 * 1024  -- 100KB
      local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
      if ok and stats and stats.size > max_size then
        return true
      end
    end,
    additional_vim_regex_highlighting = false,
  },
}
```

### Custom Captures
```lua
-- In after/queries/lua/highlights.scm
;; Highlight @variable.builtin as Constant
(identifier) @variable.builtin
  (#eq? @variable.builtin "self")
  (#set! "priority" 200)
```

## Indentation

### Enable Tree-based Indent
```lua
opts = {
  indent = {
    enable = true,
    disable = { "python" },  -- Fallback to vim indent
  },
}
```

## Incremental Selection

### Configuration
```lua
opts = {
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<CR>",
      node_incremental = "<CR>",
      scope_incremental = false,
      node_decremental = "<BS>",
    },
  },
}
```

### Usage
- `<CR>` in normal mode starts selection
- `<CR>` expands to next larger syntax node
- `<BS>` shrinks to previous smaller node

## Text Objects

### nvim-treesitter-textobjects Plugin
```lua
return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
          ["aa"] = "@parameter.outer",
          ["ia"] = "@parameter.inner",
        },
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = {
          ["]m"] = "@function.outer",
          ["]]"] = "@class.outer",
        },
        goto_previous_start = {
          ["[m"] = "@function.outer",
          ["[["] = "@class.outer",
        },
      },
      swap = {
        enable = true,
        swap_next = {
          ["<leader>a"] = "@parameter.inner",
        },
        swap_previous = {
          ["<leader>A"] = "@parameter.inner",
        },
      },
    },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
```

### Available Text Objects
| Object | Description |
|--------|-------------|
| `@function.outer` | Whole function |
| `@function.inner` | Function body |
| `@class.outer` | Whole class |
| `@class.inner` | Class body |
| `@parameter.inner` | Parameter value |
| `@parameter.outer` | Parameter with comma |
| `@block.inner` | Block contents |
| `@block.outer` | Whole block |
| `@conditional.inner` | Condition body |
| `@conditional.outer` | Whole conditional |
| `@loop.inner` | Loop body |
| `@loop.outer` | Whole loop |
| `@comment.outer` | Comment |
| `@call.inner` | Call arguments |
| `@call.outer` | Whole call |

## Queries

### Query Location
```
~/.config/nvim/after/queries/{lang}/
├── highlights.scm    -- Highlighting
├── indents.scm       -- Indentation
├── folds.scm         -- Folding
├── injections.scm    -- Language injection
└── textobjects.scm   -- Text objects
```

### Query Syntax
```scheme
;; Match function definitions
(function_definition
  name: (identifier) @function.name)

;; Match with predicates
(string) @string
  (#match? @string "TODO")

;; Capture groups
(function_call
  name: (identifier) @function
  arguments: (arguments) @function.args)
```

### Common Predicates
| Predicate | Description |
|-----------|-------------|
| `#eq?` | Exact string match |
| `#match?` | Regex match |
| `#lua-match?` | Lua pattern match |
| `#contains?` | Contains substring |
| `#any-of?` | Match any of values |
| `#set!` | Set metadata |

## Language Injection

### Inject in Queries
```scheme
;; In injections.scm
(
  (comment) @injection.content
  (#set! injection.language "comment")
)

;; Inject markdown in Lua docstrings
(
  (string_content) @injection.content
  (#set! injection.language "markdown")
  (#match? @injection.content "^---")
)
```

### Common Injections
- Lua strings as regex patterns
- HTML in template literals
- SQL in string literals
- Markdown in docstrings

## Folding

### Enable Treesitter Folding
```lua
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevel = 99  -- Start with all folds open
```

### Custom Fold Queries
```scheme
;; In folds.scm
(function_definition) @fold
(class_definition) @fold
```

## Playground

### Treesitter Playground Plugin
```lua
return {
  "nvim-treesitter/playground",
  cmd = "TSPlaygroundToggle",
}
```

### Commands
```vim
:TSPlaygroundToggle    " Show AST
:TSHighlightCapturesUnderCursor
:TSNodeUnderCursor
```

## Troubleshooting

### Check Status
```vim
:TSInstallInfo         " List installed parsers
:checkhealth nvim-treesitter
```

### Force Parser Reinstall
```vim
:TSInstall! lua        " Force reinstall
```

### Debug Highlighting
```vim
:TSHighlightCapturesUnderCursor
:Inspect               " Built-in (Neovim 0.9+)
```

### Common Issues
1. **No highlighting**: Check parser installed with `:TSInstallInfo`
2. **Slow**: Disable for large files (see disable function)
3. **Wrong indent**: Disable treesitter indent for that language
4. **Missing text objects**: Check query files exist
