local api = vim.api

-- close help, man, qf, lspinfo with 'q'
api.nvim_create_autocmd(
  "FileType",
  {
    pattern = { "man", "help", "qf", "lspinfo" },   -- "startuptime",
    command = "nnoremap <buffer><silent> q :close<CR>",
  }
)
