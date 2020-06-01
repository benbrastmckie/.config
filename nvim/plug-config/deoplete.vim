  " This is new style from: https://github.com/lervag/vimtex/blob/master/doc/vimtex.txt#L712
  call deoplete#custom#var('omni', 'input_patterns', {
          \ 'tex': g:vimtex#re#deoplete
          \})
