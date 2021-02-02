" let g:pandoc#biblio#sources = "t"
" let g:deoplete#omni_patterns = {}
" let g:deoplete#omni_patterns.pandoc= '@\w'
" let g:pandoc#modules#disabled = ["folding"]
" let g:pandoc#filetypes#handled = ["pandoc","markdown","latex"]
" let g:pandoc#filetypes#handled = ["pandoc","markdown"]
" let g:pandoc#filetypes#pandoc_markdown = 0
" let g:pandoc#folding#fdc = 0
" configuration for vim-pandoc and vim-rmarkdown

let g:pandoc#modules#disabled = ["folding"]
let g:pandoc#filetypes#pandoc_markdown = 0
" let g:pandoc#modules#disabled = 1

" let g:pandoc#syntax#conceal#use = 0
" autocmd FileType pandoc
"       \ if exists('#EnableFastFolds') |
"       \   autocmd! EnableFastFolds |
"       \   augroup! EnableFastFolds |
"       \ endif

" let g:pandoc#formatting#mode = 'hA'
" let g:pandoc#folding#fdc = 0
" let g:pandoc#folding#mode = 'syntax'
" let g:pandoc#folding#fastfolds = 1
" let g:pandoc#folding#fastfolds = 0
" let g:pandoc#syntax#conceal#use = 0
" let g:pandoc#filetypes#pandoc_markdown = 0
