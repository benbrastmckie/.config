 
let g:coc_global_extensions = [
  \ 'coc-snippets',
  \ 'coc-pairs',
  \ 'coc-floaterm',
  \ 'coc-vimtex',
  \ 'coc-explorer',
  \ 'coc-json',
  \ 'coc-yank',
  \ ]

  " \ 'coc-flutter',
  " \ 'coc-ultisnips',
  " \ 'coc-vimlsp',
  " \ 'coc-actions',
  " \ 'coc-emmet',
  " \ 'coc-tsserver',
  " \ 'coc-html',
  " \ 'coc-css',
  " \ 'coc-cssmodules',
  " \ 'coc-yaml',
  " \ 'coc-python',
  " \ 'coc-svg',
  " \ 'coc-xml',

" Navigate dropdown menu

" " Use <C-j> for jump to next placeholder, it's default of coc.nvim
" let g:coc_snippet_next = '<CR>'

" " Use <C-k> for jump to previous placeholder, it's default of coc.nvim
" let g:coc_snippet_prev = '<tab>'
      


" Completion triggers

" Make <CR> insert selection
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>" 

" " Make <CR> auto-select the first completion item
" inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm() : "\<C-g>u\<CR>"

" Highlight the symbol and its references when holding the cursor.
" autocmd CursorHold * silent call CocActionAsync('highlight')
" coc-config-float


" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}


" Explorer
  let g:coc_explorer_global_presets = {
  \   '.vim': {
  \      'root-uri': '~/.vim',
  \   },
  \   'floating': {
  \      'position': 'floating',
  \   },
  \   'floatingLeftside': {
  \      'position': 'floating',
  \      'floating-position': 'left-center',
  \      'floating-width': 50,
  \   },
  \   'floatingRightside': {
  \      'position': 'floating',
  \      'floating-position': 'left-center',
  \      'floating-width': 50,
  \   },
  \   'simplify': {
  \     'file.child.template': '[selection | clip | 1] [indent][icon | 1] [filename omitCenter 1]'
  \   }
  \ }

  autocmd BufEnter * if (winnr("$") == 1 && &filetype == 'coc-explorer') | q | endif

" OLD

" Use tab for trigger completion with characters ahead and navigate.
"   inoremap <silent><expr> <C-j>
"         \ pumvisible() ? "\<C-n>" :
"         \ <SID>check_back_space() ? "\<TAB>" :
"         \ coc#refresh()


" inoremap <silent><expr> <C-j>
"       \ pumvisible() ? coc#_select_confirm() :
"       \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
"       \ <SID>check_back_space() ? "\<TAB>" :
"       \ coc#refresh()

" function! s:check_back_space() abort
"   let col = col('.') - 1
"   return !col || getline('.')[col - 1]  =~# '\s'
" endfunction

" inoremap <expr><C-k> pumvisible() ? "\<C-p>" : "\<C-h>"


" inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<C-R>=UltiSnips#ExpandSnippet()"

" " Use tab for trigger completion with characters ahead and navigate.
" " NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" " other plugin before putting this into your config.
" inoremap <silent><expr> <TAB>
"       \ pumvisible() ? "\<C-n>" :
"       \ <SID>check_back_space() ? "\<TAB>" :
"       \ coc#refresh()
" inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" function! s:check_back_space() abort
"   let col = col('.') - 1
"   return !col || getline('.')[col - 1]  =~# '\s'
" endfunction

" " Make <CR> auto-select the first completion item and notify coc.nvim to
" " format on enter, <cr> could be remapped by other vim plugin
" inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                               \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
" function! Tab_Or_Complete()
" if col('.')>1 && strpart( getline('.'), col('.')-2, 3 ) =~ '^\w'
"   return "\<C-N>"
"     else
"   return "\<Tab>"
" endif
" endfunction

" inoremap <C-l> <C-R>=Tab_Or_Complete()<CR>

" " use <tab> for trigger completion and navigate to the next complete item
" function! s:check_back_space() abort
"   let col = col('.') - 1
"   return !col || getline('.')[col - 1]  =~ '\s'
" endfunction

" inoremap <silent><expr> <CR>
"       \ pumvisible() ? "\<C-n>" :
"       \ <SID>check_back_space() ? "\<Tab>" :
"       \ coc#refresh()
