-- PDF Viewer:
-- http://manpages.ubuntu.com/manpages/trusty/man5/zathurarc.5.html
vim.g['vimtex_view_method'] = 'zathura'
vim.g['vimtex_quickfix_mode'] =0

-- Ignore mappings
vim.g['vimtex_mappings_enabled'] = 0

-- Error Suppression:
-- https://github.com/lervag/vimtex/blob/master/doc/vimtex.txt

vim.g['vimtex_log_ignore'] = ({
  'Underfull',
  'Overfull',
  'specifier changed to',
  'Token not allowed in a PDF string',
})

vim.g['vimtex_context_pdf_viewer'] = 1
vim.g['vimtex_context_pdf_viewer'] = 'okular'

