" auto-install plugins upon starting
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  "autocmd VimEnter * PlugInstall
  "autocmd VimEnter * PlugInstall | source $MYVIMRC
endif

call plug#begin('~/.config/nvim/autoload/plugged')

" APPEARANCE

" Themes 
    Plug 'morhetz/gruvbox'  " Source grubox theme
    " Plug 'HerringtonDarkholme/yats.vim' " TS Syntax
    " Plug 'joshdick/onedark.vim'
    
" Satus Line
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    
" Startup Screen
    Plug 'mhinz/vim-startify'
    

" FILE MANAGEMENT

" File Explorer
    Plug 'ryanoasis/vim-devicons' "adds icons to coc-explorer
    " Plug 'scrooloose/nerdtree'
    " Plug 'preservim/nerdtree'
    " Plug 'Xuyuanp/nerdtree-git-plugin'
    " Plug 'tsony-tsonev/nerdtree-git-plugin'
    " Plug 'tiagofumo/vim-nerdtree-syntax-highlight' " Is this required?
    
" Git Integration
    Plug 'mhinz/vim-signify'
    Plug 'airblade/vim-gitgutter'
    Plug 'tpope/vim-fugitive'
    Plug 'tpope/vim-rhubarb'
    Plug 'junegunn/gv.vim'

" Fuzzy Search
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
    " Plug 'jremmen/vim-ripgrep'
    " Plug 'ctrlpvim/ctrlp.vim' " Not as elegant as FZF
    
" Undo tree
    Plug 'mbbill/undotree'
    

" TEXT SUPPORT

" LaTeX Support
    Plug 'lervag/vimtex'
    Plug 'dense-analysis/ale' " LaTeX Linting

" Markdown
    Plug 'gabrielelana/vim-markdown'
    Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
    " Plug 'godlygeek/tabular'
    " Plug 'plasticboy/vim-markdown'    
    
" Pandoc: conflict with markdown auto-indent and syntax highlighting
    Plug 'vim-pandoc/vim-pandoc'
    Plug 'vim-pandoc/vim-pandoc-syntax' " Syntax not as good

" Better Syntax Support
    " Plug 'sheerun/vim-polyglot'
    
" Spelling
    " Plug 'kopischke/unite-spell-suggest'

" VimWiki
    " Plug 'vimwiki/vimwiki'

" Templates
    " Plug 'KabbAmine/vBox.vim'
    " Plug 'tibabit/vim-templates'
    " Plug 'aperezdc/vim-template'


" ADDITIONAL FUNCTIONS

" IntelLisense
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
      " Keeping up to date with master
      " Plug 'neoclide/coc.nvim', {'do': 'yarn install --frozen-lockfile'}
    Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
    " Plug 'Valloric/YouCompleteMe'
    
" Look Up Key Bindings
    Plug 'liuchengxu/vim-which-key'
    
" Snippets
    Plug 'SirVer/ultisnips'
    " Plug 'honza/vim-snippets'

" Comments
    Plug 'tpope/vim-commentary'
    " Plug 'jbgutierrez/vim-better-comments'

" Auto pairs for '(' '[' '{' etc.
    Plug 'machakann/vim-sandwich' 
    Plug 'jiangmiao/auto-pairs' 
    Plug 'tpope/vim-surround' 
    Plug 'tpope/vim-repeat' 
    
" Quick Movements in Text
    Plug 'unblevable/quick-scope'
    " Plug 'justinmk/vim-sneak'
    
" Terminal
    Plug 'voldikss/vim-floaterm'
    
" Multiple Cursors
    Plug 'terryma/vim-multiple-cursors'

" Zen mode
    Plug 'junegunn/goyo.vim'
    
    






call plug#end()

" Automatically install missing plugins on startup
autocmd VimEnter *
  \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \|   PlugInstall --sync | q
  \| endif
