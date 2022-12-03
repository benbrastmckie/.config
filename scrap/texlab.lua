require "lspconfig".texlab.setup{}

local config = {
    cache_activate = true,
    cache_filetypes = { 'tex', 'bib' },
    cache_root = vim.fn.stdpath('cache'),
    reverse_search_edit_cmd = vim.cmd.edit,
    file_permission_mode = 438,
}
