" auto-install vim-plug
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  "autocmd VimEnter * PlugInstall
  "autocmd VimEnter * PlugInstall | source $MYVIMRC
endif

call plug#begin('~/.config/nvim/autoload/plugged')

    " Better Syntax Support
    " Plug 'sheerun/vim-polyglot'
    
    " File Explorer
    " Plug 'scrooloose/nerdtree'
    " Plug 'preservim/nerdtree'
    " Plug 'Xuyuanp/nerdtree-git-plugin'
    " Plug 'tsony-tsonev/nerdtree-git-plugin'
    " Plug 'tiagofumo/vim-nerdtree-syntax-highlight' " Is this required?
    Plug 'ryanoasis/vim-devicons'
    
    " Auto pairs for '(' '[' '{' 
    Plug 'machakann/vim-sandwich' 
    Plug 'jiangmiao/auto-pairs' " having trouble changing defaults 
    Plug 'tpope/vim-surround' 
    Plug 'tpope/vim-repeat' 
    
    " Themes 
    Plug 'morhetz/gruvbox'  " Source grubox theme
    " Plug 'HerringtonDarkholme/yats.vim' " TS Syntax
    " Plug 'joshdick/onedark.vim'
    
    " Satus Line
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    
    " Startup Screen
    Plug 'mhinz/vim-startify'
    
    " Git Integration
    Plug 'mhinz/vim-signify'
    Plug 'airblade/vim-gitgutter'
    Plug 'tpope/vim-fugitive'
    Plug 'tpope/vim-rhubarb'
    Plug 'junegunn/gv.vim'
    
    " Quick Movements in Text
    " Plug 'justinmk/vim-sneak'
    Plug 'unblevable/quick-scope'
    
    " Fuzzy Search
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
    " Plug 'ctrlpvim/ctrlp.vim' " Not as elegant as FZF
    
    " File Manager etc 
    " Plug 'kevinhwang91/rnvimr', {'do': 'make sync'}
    " Plug 'airblade/vim-rooter'
    
    " Terminal
    Plug 'voldikss/vim-floaterm'
    
    " Look Up Key Bindings
    Plug 'liuchengxu/vim-which-key'
    
    " Change dates fast
    " Plug 'tpope/vim-speeddating'
    
    " IntelLisense
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
    " Keeping up to date with master
    " Plug 'neoclide/coc.nvim', {'do': 'yarn install --frozen-lockfile'}
    
    " Auto-Complete
    Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
    " Plug 'Valloric/YouCompleteMe'
    
    Plug 'jremmen/vim-ripgrep'
    
    " Undo tree
    Plug 'mbbill/undotree'
    
    " Zen mode
    Plug 'junegunn/goyo.vim'
    
    " Snippets
    " Plug 'SirVer/ultisnips'
    Plug 'honza/vim-snippets'

    " Comments
    Plug 'tpope/vim-commentary'
    " Plug 'jbgutierrez/vim-better-comments'
    
    " Echo doc
    " Plug 'Shougo/echodoc.vim'
    
    " Interactive code
    Plug 'https://github.com/vimwiki/vimwiki.git'
    " Plug 'metakirby5/codi.vim'

    " LaTeX Support
    Plug 'lervag/vimtex'
    
    " LaTeX Linting
    Plug 'dense-analysis/ale'

    " Spelling
    " Plug 'kopischke/unite-spell-suggest'




call plug#end()

" Automatically install missing plugins on startup
autocmd VimEnter *
  \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \|   PlugInstall --sync | q
  \| endif
