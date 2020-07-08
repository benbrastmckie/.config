" Map leader to which_key
nnoremap <silent> <leader> :silent WhichKey '<Space>'<CR>
vnoremap <silent> <leader> :silent <c-u> :silent WhichKeyVisual '<Space>'<CR>

" Create map to add keys to
let g:which_key_map =  {}
" Define a separator
let g:which_key_sep = '→'


" Not a fan of floating windows for this
let g:which_key_use_floating_win = 0

" Change the colors if you want
highlight default link WhichKey          Operator
highlight default link WhichKeySeperator DiffAdded
highlight default link WhichKeyGroup     Identifier
highlight default link WhichKeyDesc      Function

" Hide status line
autocmd! FileType which_key
autocmd  FileType which_key set laststatus=0 noshowmode noruler
  \| autocmd BufLeave <buffer> set laststatus=2 noshowmode ruler


" Single mappings
" let g:which_key_map['.'] = [ ':e $MYVIMRC'           , 'open init' ]
let g:which_key_map[';'] = [ ':Commands'             , 'commands' ]
let g:which_key_map['d'] = [ ':bd'                   , 'delete buffer']
let g:which_key_map['e'] = [ ':CocCommand explorer'  , 'explorer' ]
let g:which_key_map['f'] = [ ':BLines'               , 'find' ]
let g:which_key_map['F'] = [ ':Files ~'              , 'home files' ]
let g:which_key_map['k'] = [ ':CocDisable'           , 'kill coc' ]
let g:which_key_map['R'] = [ ':source $MYVIMRC'      , 'reload' ]
let g:which_key_map['r'] = [ ':CocEnable'            , 'restore coc' ]
let g:which_key_map['l'] = [ ':VimtexErrors'         , 'log' ]
let g:which_key_map['q'] = [ ':wqa'                  , 'quit' ]
let g:which_key_map['w'] = [ ':w'                    , 'write' ]
let g:which_key_map['z'] = [ 'Goyo'                  , 'zen' ]
let g:which_key_map['u'] = [ 'UndotreeToggle'        , 'undo' ]
let g:which_key_map.i = 'index'
let g:which_key_map.b = 'build'
let g:which_key_map.c = 'count'
let g:which_key_map.p = 'preview'

" let g:which_key_map[','] = [ 'Startify'              , 'start screen' ]
" let g:which_key_map['S'] = [ ':SSave'                , 'save session' ]
" let g:which_key_map.x = 'clean'
" let g:which_key_map['c'] = [ ':VimtexCountWords<CR>'      , 'count' ]
" let g:which_key_map['x'] = [ ':VimtexClean<CR>'           , 'clean' ]
" let g:which_key_map.u = 'undo'


" let g:which_key_map['='] = [ '<C-W>='                     , 'balance windows' ]
" let g:which_key_map['n'] = [ ':tabnew'                    , 'new buffer' ]
" let g:which_key_map['y'] = [ '<Plug>Ysurround'            , 'surround' ]
" let g:which_key_map['n'] = [ ':NERDTreeToggle'            , 'nerdtree' ]
" let g:which_key_map['p'] = [ ':Files'                     , 'search files' ]
" let g:which_key_map.f = 'float explorer'
" let g:which_key_map['h'] = [ '<C-W>s'                     , 'split below']
" let g:which_key_map.l = 'look up'
" let g:which_key_map['v'] = [ '<C-W>v'                     , 'split right']


" Group mappings

" Pandoc
let g:which_key_map.P = {
      \ 'name' : '+pandoc' ,
      \ 'w' : [':Pandoc docx'           , 'to word from open'],
      \ 'm' : [':Pandoc md'             , 'to markdown from open'],
      \ 'h' : [':Pandoc html'           , 'to html from open'],
      \ 'l' : [':Pandoc latex'          , 'to latex from open'],
      \ }

      " \ 'L' : [':terminal pandoc -s expand('%:t') -o expand('%:t').tex'       , 'to latex from file'],
      " \ 'm' : [':SDelete!'              , 'to markdown from file'],

" Templates
let g:which_key_map.t = {
      \ 'name' : '+templates' ,
      \ 'p' : [':read ~/.config/nvim/templates/PhilPaper.tex'           , 'PhilPaper.tex'],
      \ 'l' : [':read ~/.config/nvim/templates/Letter.tex'           , 'Letter.tex'],
      \ 'h' : [':read ~/.config/nvim/templates/HandOut.tex'           , 'HandOut.tex'],
      \ 'b' : [':read ~/.config/nvim/templates/PhilBeamer.tex'           , 'PhilBeamer.tex'],
      \ 's' : [':read ~/.config/nvim/templates/SubFile.tex'           , 'SubFile.tex'],
      \ 'm' : [':read ~/.config/nvim/templates/MultipleAnswer.tex'           , 'MultipleAnswer.tex'],
      \ }

" Sessions
let g:which_key_map.S = {
      \ 'name' : '+session' ,
      \ 's' : [':SSave'                , 'save session'],
      \ 'd' : [':SDelete!'              , 'delete session'],
      \ }

" Markdown
let g:which_key_map.m = {
      \ 'name' : '+markdown' ,
      \ 'p' : ['<Plug>MarkdownPreview'           , 'preview'],
      \ 'k' : ['<Plug>MarkdownPreviewStop'       , 'kill'],
      \ 'm' : ['<Plug>MarkdownPreviewToggle'     , 'toggle'],
      \ 's' : [':call markdown#SwitchStatus()<CR>'   , 'select'],
      \ }

" y is for you surround
let g:which_key_map.s = {
      \ 'name' : '+surround' ,
      \ 's' : ['<Plug>Ysurround'         , 'surround'],
      \ 'c' : ['<Plug>Csurround'         , 'change'],
      \ 'd' : ['<Plug>Dsurround'         , 'delete'],
      \ 'k' : ['dss'                     , 'kill'],
      \ }


" a is for actions
let g:which_key_map.a = {
      \ 'name' : '+actions' ,
      \ 'y' : [':CocList -A --normal yank'  , 'yank display'],
      \ 'n' : [':set nonumber!'             , 'line-numbers'],
      \ 'k' : [':VimtexClean'               , 'kill aux files'],
      \ 'r' : [':set norelativenumber!'     , 'relative line nums'],
      \ 's' : [':let @/ = ""'               , 'remove search highlight'],
      \ 'v' : [':Vista!!'                   , 'tag viewer'],
      \ }


      " \ 't' : [':FloatermToggle'         , 'terminal'],
      " \ 'c' : [':ColorizerToggle'        , 'colorizer'],


" " b is for buffer
" let g:which_key_map.b = {
"       \ 'name' : '+buffer' ,
"       \ '1' : ['b1'        , 'buffer 1']        ,
"       \ '2' : ['b2'        , 'buffer 2']        ,
"       \ 'd' : ['bd'        , 'delete-buffer']   ,
"       \ 'f' : ['bfirst'    , 'first-buffer']    ,
"       \ 'h' : ['Startify'  , 'home-buffer']     ,
"       \ 'l' : ['blast'     , 'last-buffer']     ,
"       \ 'n' : ['bnext'     , 'next-buffer']     ,
"       \ 'p' : ['bprevious' , 'previous-buffer'] ,
"       \ '?' : ['Buffers'   , 'fzf-buffer']      ,
"       \ }

" " s is for search
" let g:which_key_map.? = {
"       \ 'name' : '+search' ,
"       \ '/' : [':History/'     , 'history'],
"       \ ';' : [':Commands'     , 'commands'],
"       \ 'a' : [':Ag'           , 'text Ag'],
"       \ 'b' : [':BLines'       , 'current buffer'],
"       \ 'B' : [':Buffers'      , 'open buffers'],
"       \ 'c' : [':Commits'      , 'commits'],
"       \ 'C' : [':BCommits'     , 'buffer commits'],
"       \ 'f' : [':Files'        , 'files'],
"       \ 'g' : [':GFiles'       , 'git files'],
"       \ 'G' : [':GFiles?'      , 'modified git files'],
"       \ 'h' : [':History'      , 'file history'],
"       \ 'H' : [':History:'     , 'command history'],
"       \ 'l' : [':Lines'        , 'lines'] ,
"       \ 'm' : [':Marks'        , 'marks'] ,
"       \ 'M' : [':Maps'         , 'normal maps'] ,
"       \ 'p' : [':Helptags'     , 'help tags'] ,
"       \ 'P' : [':Tags'         , 'project tags'],
"       \ 's' : [':Snippets'     , 'snippets'],
"       \ 's' : [':Snippets'     , 'snippets'],
"       \ 'S' : [':Colors'       , 'color schemes'],
"       \ 't' : [':Rg'           , 'text Rg'],
"       \ 'T' : [':BTags'        , 'buffer tags'],
"       \ 'w' : [':Windows'      , 'search windows'],
"       \ 'y' : [':Filetypes'    , 'file types'],
"       \ 'z' : [':FZF'          , 'FZF'],
"       \ }

" g is for git
let g:which_key_map.g = {
      \ 'name' : '+git' ,
      \ 'a' : [':Git add .'                        , 'add all'],
      \ 'A' : [':Git add %'                        , 'add current'],
      \ 'b' : [':Git blame'                        , 'blame'],
      \ 'B' : [':GBrowse'                          , 'browse'],
      \ 'c' : [':Git commit'                       , 'commit'],
      \ 'd' : [':Git diff'                         , 'diff'],
      \ 'D' : [':Gdiffsplit'                       , 'diff split'],
      \ 'G' : [':GGrep'                            , 'git grep'],
      \ 's' : [':Gstatus'                          , 'status'],
      \ 'h' : [':GitGutterLineHighlightsToggle'    , 'highlight hunks'],
      \ 'l' : [':Git log'                          , 'log'],
      \ 'P' : [':Git push'                         , 'push'],
      \ 'p' : [':Git pull'                         , 'pull'],
      \ 'r' : [':GRemove'                          , 'remove'],
      \ 'g' : [':FloatermNew lazygit'              , 'lazygit'],
      \ 't' : [':GitGutterSignsToggle'             , 'toggle signs'],
      \ 'v' : [':GV'                               , 'view commits'],
      \ 'V' : [':GV!'                              , 'view buffer commits'],
      \ }

  " nmap ghp <Plug>(GitGutterPreviewHunk)
  " nmap ghs <Plug>(GitGutterStageHunk)
  " nmap ghu <Plug>(GitGutterUndoHunk)


" \ 'H' : ['<Plug>(GitGutterPreviewHunk)'      , 'preview hunk'],
" \ 'j' : ['<Plug>(GitGutterNextHunk)'         , 'next hunk'],
" \ 'k' : ['<Plug>(GitGutterPrevHunk)'         , 'prev hunk'],
" \ 's' : ['<Plug>(GitGutterStageHunk)'        , 'stage hunk'],
" \ 'u' : ['<Plug>(GitGutterUndoHunk)'         , 'undo hunk'],

" " t is for terminal
" let g:which_key_map.t = {
"       \ 'name' : '+terminal' ,
"       \ ';' : [':FloatermNew --wintype=popup --height=6'        , 'terminal'],
"       \ 'f' : [':FloatermNew fzf'                               , 'fzf'],
"       \ 'g' : [':FloatermNew lazygit'                           , 'git'],
"       \ 'd' : [':FloatermNew lazydocker'                        , 'docker'],
"       \ 'n' : [':FloatermNew node'                              , 'node'],
"       \ 'N' : [':FloatermNew nnn'                               , 'nnn'],
"       \ 'p' : [':FloatermNew python'                            , 'python'],
"       \ 'r' : [':FloatermNew ranger'                            , 'ranger'],
"       \ 't' : [':FloatermToggle'                                , 'toggle'],
"       \ 'y' : [':FloatermNew ytop'                              , 'ytop'],
"       \ 's' : [':FloatermNew ncdu'                              , 'ncdu'],
"       \ }


" Register which key map
call which_key#register('<Space>', "g:which_key_map")
