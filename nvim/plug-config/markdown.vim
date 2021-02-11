" INDENTING
  let g:markdown_enable_insert_mode_leader_mappings = 0
  " let g:markdown_enable_mappings = 0  " turning this on kills the nice
  " indent feature which drags the bullet with the tab
  " let g:markdown_enable_insert_mode_mappings = 1

  " This is the indent on tab feature I like
    " inoremap <silent> <buffer> <script> <expr> <Tab>
    "   \ <SID>IsAnEmptyListItem() \|\| <SID>IsAnEmptyQuote() ? '<C-O>:call <SID>Indent(1)<CR>' : '<Tab>'
    " inoremap <silent> <buffer> <script> <expr> <S-Tab>
    "   \ <SID>IsAnEmptyListItem() \|\| <SID>IsAnEmptyQuote() ? '<C-O>:call <SID>Indent(0)<CR>' : '<Tab>'

" FOLDING
  let g:vim_markdown_folding_disabled = 1 " big increase in speed
