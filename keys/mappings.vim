" NOTES
" check mapping with :verbose map ____

" Unmappings
" nunmap <space>ft

" Easymotion
  " Move to line
  " map <Leader>l <Plug>(easymotion-bd-jk)
  " nmap <Leader>l <Plug>(easymotion-overwin-line)

  " Move to word
  map  <C-f> <Plug>(easymotion-bd-w)
  nmap <C-f> <Plug>(easymotion-overwin-w)

" Terminal mappings
nnoremap  <C-t> :FloatermToggle<CR>
tnoremap <C-t> <C-\><C-n>:FloatermToggle<CR>
" nnoremap  <leader>t :tab ter<CR>
" noremap! <leader>t <Esc>:FloatermToggle<CR>i
" tnoremap  <leader>d <C-\><C-n>:bd!<CR>

" Better nav for omnicomplete
inoremap <expr> <c-j> ("\<C-n>")
inoremap <expr> <c-k> ("\<C-p>")

" Use alt + hjkl to resize windows
" nnoremap <M-j>    :resize -2<CR>
" nnoremap <M-k>    :resize +2<CR>
nnoremap <M-h>    :vertical resize -2<CR>
nnoremap <M-l>    :vertical resize +2<CR>

" remap Y to what it should be
nnoremap <S-y> y$

" italics and bold
" vnoremap i <Plug>Ysurround ssiwi
" vnoremap <C-b> <S-s>b

" remap Return to save
nmap <CR> <plug>(vimtex-context-menu)

" Jump paragraph
" nmap <C-j> :NERDTreeToggle<CR>

" Drag lines
" xnoremap <silent> <M-k> :call wincent#mappings#visual#move_up()<CR>
" xnoremap <silent> <M-j> :call wincent#mappings#visual#move_down()<CR>
" vnoremap <M-j> :m '>+1<CR>gv
" vnoremap <M-k> :m '<-2<CR>gv
" nnoremap <M-j> <S-v> :m '>+1<CR>gv<esc>
" nnoremap <M-k> <S-v> :m '<-2<CR>gv<esc>
" inoremap <M-j> <esc><S-v> :m '>+1<CR>gv<esc>
" inoremap <M-k> <esc><S-v> :m '<-2<CR>gv<esc>
" vnoremap <M-j> dpgv
" vnoremap <M-k> dkPgv
" inoremap <M-j> <esc>:m'>+<CR>
" inoremap <M-k> <esc>:m-2<CR>
vnoremap <M-j> :m'>+<CR>gv
vnoremap <M-k> :m-2<CR>gv
nnoremap <M-j> ddp
nnoremap <M-k> ddkP
inoremap <M-j> <esc>ddp
inoremap <M-k> <esc>ddkP

  " Change next word instance
  " nnoremap c* Ncgn

" " Multiple Cursors
" let g:multi_cursor_use_default_mapping=0

" " Default mapping
"   let g:multi_cursor_start_word_key      = '<C-n>'
"   let g:multi_cursor_select_all_word_key = '<M-n>'
"   let g:multi_cursor_start_key           = 'g<C-n>'
"   let g:multi_cursor_select_all_key      = 'g<M-n>'
"   let g:multi_cursor_next_key            = '<C-n>'
"   let g:multi_cursor_prev_key            = '<C-p>'
"   let g:multi_cursor_skip_key            = '<C-x>'
"   let g:multi_cursor_quit_key            = '<Esc>'

" Jump forward, replacing <c-i> since idential to <tab>
" nnoremap <C-[> <C-i>
" nnoremap <C-]> <C-o>

" TAB in general mode will move to text buffer
nnoremap <BS> :bnext<CR>
" SHIFT-TAB will go back
nnoremap <S-TAB> :bprevious<CR>

" Alternate way to save
" nmap <C-s> <esc> \| :w<CR> 
" nmap <C-q> <esc> \| :wq<CR> 

" <TAB>: completion.
inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"

" Better tabbing
vnoremap > >gv
vnoremap < <gv
nnoremap > <S-v>><esc>
nnoremap < <S-v><<esc>

" Better window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Horizontal line movement
nnoremap <S-h> g^
nnoremap <S-l> g$
vnoremap <S-h> g^
vnoremap <S-l> g$

" Display line movements
" noremap <S-h> b
" noremap <S-j> gj
" noremap <S-k> gk
" noremap <S-l> w

" Open Manual for word
nnoremap <M-m> :execute "help " . expand("<cword>")<cr>
" noremap <C-m> :call <SNR>23_show_documentation()<CR>
" noremap <C-m> :help expand("<cword>")<cr>

" Display line movements
nnoremap <S-k> gk
nnoremap <S-j> gj
vnoremap <S-k> gk
vnoremap <S-j> gj

" nnoremap <Leader>o o<Esc>^Da
" nnoremap <Leader>O O<Esc>^Da

" Comment out line
nnoremap <C-\> :Commentary<CR>
vnoremap <C-\> :Commentary<CR>

" UndoTree bindings
nnoremap <space>u :UndotreeToggle<CR> \| <C-w>h

" LaTeX bindings
nnoremap <space>c :VimtexCountWords<CR> 
" nnoremap <space>b :VimtexCompile<CR>
" nnoremap <space>i :VimtexTocOpen<CR>
" nnoremap <space>i :VimtexTocToggle<CR> \| <C-w>h
" nnoremap <space>p :VimtexView<CR> 
" nnoremap <space>x :VimtexClean<CR>
" nnoremap <space>l :VimtexLabelsToggle<CR> 

" UndotreeToggle
nnoremap <space>u :UndotreeToggle<CR> 

" Fuzzy Search
nnoremap <C-p> :Files<CR>

" NERDTree bindings
" nmap <C-n> :NERDTreeToggle<CR>

" Explorer
" nmap <space>f :w \| :CocCommand explorer --preset floating<CR>

" Ranger
" nmap <space>r :RnvimrToggle<CR>

" Coc Autocomplete Toggle
" nnoremap <expr> <space>r yourConditionExpression ? ':q!<cr>':':bd<cr>'

" Kill search on escape
nnoremap <esc> :noh<return><esc>

" Spelling: http://vimdoc.sourceforge.net/htmldoc/spell.html
nnoremap <C-s> a<C-X><C-S>

" function! FzfSpellSink(word)
"   exe 'normal! "_ciw'.a:word
" endfunction
" function! FzfSpell()
"   let suggestions = spellsuggest(expand("<cword>"))
"   return fzf#run({'source': suggestions, 'sink': function("FzfSpellSink"), 'down': 10 })
" endfunction
" nnoremap z= :call FzfSpell()<CR>


" Use tab for trigger completion with characters ahead and navigate.
inoremap <silent><expr> <C-j>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"


" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Jump though hunks
" nmap <leader>gj <plug>(signify-next-hunk)
" nmap <leader>gk <plug>(signify-prev-hunk)
"nmap <leader>gJ 9999<leader>gJ
"nmap <leader>gK 9999<leader>gk

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
" nmap <silent> gy <Plug>(coc-type-definition)
" nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
" nnoremap <silent> K :call <SID>show_documentation()<CR>

" Introduce function text object
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
" xmap if <Plug>(coc-funcobj-i)
" xmap af <Plug>(coc-funcobj-a)
" omap if <Plug>(coc-funcobj-i)
" omap af <Plug>(coc-funcobj-a)

" Use <TAB> for selections ranges.
" NOTE: Requires 'textDocument/selectionRange' support from the language server.
" coc-tsserver, coc-python are the examples of servers that support it.
" nmap <silent> <TAB> <Plug>(coc-range-select)
" xmap <silent> <TAB> <Plug>(coc-range-select)

" Registers
" nnoremap c "cc
" vnoremap c "cc
" nnoremap C vg_"cc
" vnoremap C g_"cc
" nnoremap d "dd
" vnoremap d "dd
" nnoremap D vg_"dd
" vnoremap D g_"dd
" nnoremap y "xy
" vnoremap y "xy
" nnoremap p "xp
" vnoremap p "xp

" Unmappings
" unmap <C-t>
" nnoremap <C-t> <Nop>

" nnoremap <Space>hs <Nop>
" nnoremap <Space>hu <Nop>

" " Markdown
let g:markdown_mapping_switch_status = '<Space>ms'
" nnoremap <Space>ft <Space>mf
" nmap <C-s> <Plug>MarkdownPreview
" nmap <M-s> <Plug>MarkdownPreviewStop
" nmap <C-p> <Plug>MarkdownPreviewToggle

" GitGutterHunk
  " nmap ghp <Plug>(GitGutterPreviewHunk)
  " nmap ghs <Plug>(GitGutterStageHunk)
  " nmap ghu <Plug>(GitGutterUndoHunk)

" Snippets in Coc
  " Use <C-l> for trigger snippet expand.
  imap <C-l> <Plug>(coc-snippets-expand)

  " Use <C-j> for select text for visual placeholder of snippet.
  " vmap <C-j> <Plug>(coc-snippets-select)

  " Use <C-j> for jump to next placeholder, it's default of coc.nvim
  let g:coc_snippet_next = '<CR>'

  " Use <C-k> for jump to previous placeholder, it's default of coc.nvim
  let g:coc_snippet_prev = '<TAB>'

  " Use <C-j> for both expand and jump (make expand higher priority.)
  " imap <C-j> <Plug>(coc-snippets-expand-jump)

  " let g:UltiSnipsExpandTrigger='<Nop>'
  " let g:UltiSnipsJumpForwardTrigger = '<TAB>'
  " let g:UltiSnipsJumpBackwardTrigger = '<S-TAB>'

" scroll through autocomplete in commandline tab-menu
cnoremap <C-j> <C-n>
cnoremap <C-k> <C-p>

" online_thesaurus_map_keys
" nnoremap <C-m> :OnlineThesaurusCurrentWord<CR>




