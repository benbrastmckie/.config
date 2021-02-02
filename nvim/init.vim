" NOTES
" Although anything in ~/.config/nvim/plugin will automatically be sourced, I find it convenient to individually source config files so as to be able to easily comment out config files that are not needed while leaving them intact.

" GENERAL
source $HOME/.config/nvim/general/settings.vim
source $HOME/.config/nvim/vim-plug/plugins.vim

" TEXT SUPPORT
source $HOME/.config/nvim/plug-config/vimtex.vim
source $HOME/.config/nvim/plug-config/markdown.vim
source $HOME/.config/nvim/plug-config/markdown-preview.vim

" FILE MANAGEMENT
source $HOME/.config/nvim/plug-config/start-screen.vim
source $HOME/.config/nvim/plug-config/fzf.vim
source $HOME/.config/nvim/plug-config/gitgutter.vim
source $HOME/.config/nvim/plug-config/signify.vim

" AUTOCOMPLETE
source $HOME/.config/nvim/plug-config/coc.vim
source $HOME/.config/nvim/plug-config/deoplete.vim
source $HOME/.config/nvim/plug-config/ultisnips.vim
source $HOME/.config/nvim/plug-config/autopairs.vim
source $HOME/.config/nvim/plug-config/vim-surruound.vim

" ADDITIONAL FUNCTIONS
source $HOME/.config/nvim/plug-config/quickscope.vim
source $HOME/.config/nvim/plug-config/floaterm.vim
source $HOME/.config/nvim/plug-config/goyo.vim
source $HOME/.config/nvim/plug-config/multicursor.vim

" MAPPINGS
source $HOME/.config/nvim/keys/which-key.vim
source $HOME/.config/nvim/keys/mappings.vim

" APPEARANCE
source $HOME/.config/nvim/themes/gruvbox.vim
source $HOME/.config/nvim/themes/airline.vim

" ABANDONED
" source $HOME/.config/nvim/plug-config/pandoc.vim
" source $HOME/.config/nvim/plug-config/vbox.vim
" source $HOME/.config/nvim/plug-config/templates.vim
" source $HOME/.config/nvim/plug-config/nerdtree.vim
" source $HOME/.config/nvim/plug-config/vim-commentary.vim
" source $HOME/.config/nvim/plug-config/rnvimr.vim
" source $HOME/.config/nvim/plug-config/sneak.vim
" source $HOME/.config/nvim/themes/onedark.vim
" source $HOME/.config/nvim/keys/mappings.vim

