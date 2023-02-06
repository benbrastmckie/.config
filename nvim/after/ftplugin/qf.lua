local opts = { noremap = true, silent = true }

local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap


-- Close quickfix with kill buffer
keymap("n", "<leader>d", ":cclose<cr>", opts)
