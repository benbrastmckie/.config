return {
  "aspeddro/cmp-pandoc.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    -- "jbyuki/nabla.nvim",
  },
  -- What types of files cmp-pandoc works.
  -- 'pandoc', 'markdown' and 'rmd' (Rmarkdown)
  -- @type: table of string
  filetypes = { "pandoc", "markdown", "rmd" },
  -- Customize bib documentation
  bibliography = {
    -- Enable bibliography documentation
    -- @type: boolean
    documentation = true,
    -- Fields to show in documentation
    -- @type: table of string
    fields = { "type", "title", "author", "year" },
  },
  -- Crossref
  crossref = {
    -- Enable documetation
    -- @type: boolean
    documentation = true,
    -- Use nabla.nvim to render LaTeX equation to ASCII
    -- @type: boolean
    enable_nabla = false,
  }
}
