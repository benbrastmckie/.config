" https://github.com/machakann/vim-sandwich/blob/master/doc/sandwich.txt
runtime macros/sandwich/keymap/surround.vim " for vim-sandwich
" set timeout timeoutlen=500 ttimeoutlen=0 " does not work otherwise
  " fixed this by using which-key for <Plug>Ysurround
  " fixed this by using which-key for dss
autocmd FileType tex let b:surround_{char2nr("q")} = "`\r'"
autocmd FileType tex let b:surround_{char2nr('Q')} = "``\r''"
autocmd FileType tex let b:surround_{char2nr('i')} = "\\textit{\r}"
autocmd FileType tex let b:surround_{char2nr('b')} = "\\textbf{\r}"
autocmd FileType tex let b:surround_{char2nr('t')} = "\\texttt{\r}"
" autocmd FileType tex let b:surround_{char2nr('s')} = "\\textsc{\r}"
autocmd FileType tex let b:surround_{char2nr('c')} = "\\corner{\r}"
autocmd FileType tex let b:surround_{char2nr('s')} = "\\set{\r}"
autocmd FileType tex let b:surround_{char2nr('$')} = "$\r$"

" let g:sandwich#recipes += [
" 	\   {'buns': ['{ ', ' }'], 'nesting': 1, 'match_syntax': 1,
" 	\    'kind': ['add', 'replace'], 'action': ['add'], 'input': ['{']},
" 	\
" 	\   {'buns': ['[ ', ' ]'], 'nesting': 1, 'match_syntax': 1,
" 	\    'kind': ['add', 'replace'], 'action': ['add'], 'input': ['[']},
" 	\
" 	\   {'buns': ['( ', ' )'], 'nesting': 1, 'match_syntax': 1,
" 	\    'kind': ['add', 'replace'], 'action': ['add'], 'input': ['(']},
" 	\
" 	\   {'buns': ['{\s*', '\s*}'],   'nesting': 1, 'regex': 1,
" 	\    'match_syntax': 1, 'kind': ['delete', 'replace', 'textobj'],
" 	\    'action': ['delete'], 'input': ['{']},
" 	\
" 	\   {'buns': ['\[\s*', '\s*\]'], 'nesting': 1, 'regex': 1,
" 	\    'match_syntax': 1, 'kind': ['delete', 'replace', 'textobj'],
" 	\    'action': ['delete'], 'input': ['[']},
" 	\
" 	\   {'buns': ['(\s*', '\s*)'],   'nesting': 1, 'regex': 1,
" 	\    'match_syntax': 1, 'kind': ['delete', 'replace', 'textobj'],
" 	\    'action': ['delete'], 'input': ['(']},
" 	\ ]
