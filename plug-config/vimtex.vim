" PDF Viewer:
" http://manpages.ubuntu.com/manpages/trusty/man5/zathurarc.5.html
let g:latex_view_general_viewer = 'zathura'
let g:vimtex_view_method = 'zathura'
let g:vimtex_quickfix_mode=0

" Ignore mappings
let g:vimtex_mappings_enabled = 0

" Error Suppression:
" https://github.com/lervag/vimtex/blob/master/doc/vimtex.txt

let g:tex_flavor = 'latex'
let g:vimtex_log_ignore = [
        \ 'Underfull',
        \ 'Overfull',
        \ 'specifier changed to',
        \ 'Token not allowed in a PDF string',
      \ ]
" let g:vimtex_quickfix_latexlog = {
"           \ 'overfull' : 0,
"           \ 'underfull' : 0,
"           \ 'packages' : {
"           \   'default' : 0,
"           \ },
"           \}
" let g:vimtex_quickfix_ignored_warnings = [
"         \ 'Underfull',
"         \ 'Overfull',
"         \ 'specifier changed to',
"         \ 'Token not allowed in a PDF string',
"       \ ]

" let g:vimtex_log_verbose = "0"

