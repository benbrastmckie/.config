# TODO


## In Progress

- [ ] release
  - [ ] update notification system
  - [ ] list of features to advertise
  - [ ] list of changes
  - [x] gitexclude
  - [x] checkhealth
- [ ] delete neotex directory
- [ ] neo-tree
  - [ ] make esc cancel delete
- [ ] yank errors
  - [ ] pasting text gives: Content is not an image.
  - paste: Error executing lua: vim/_editor.lua:0: Vim:E21: Cannot make changes, 'modifiable' is off^@stack traceback:^@^I[C]: in function 'nvim_put'^@^Ivim/_editor.lua: in function <vim/_editor.lua:0>  
- [x] blink
  - [ ] tab in command mode
  - [x] no ghost text insertions
  - [.] snippets
    - [x] completion
    - [ ] strange tab behaviour
  - [x] revert to nvim-autopairs
    - [x] plan
    - [x] implement
    - [x] debug
  - [x] cmp
    - [x] improve super-tab
    - [x] plan
    - [x] implement
      - [x] first pass
      - [x] research
      - [x] second pass
    - [x] commands
    - [x] paths
    - [x] refactor directory
    - [x] document
- [.] ai
  - [:] claude-code
    - [.] mcp
    - [x] switch to https://github.com/coder/claudecode.nvim
  - [ ] avante
  - [ ] fix mappings in visual mode
    - [x] debug
    - [x] get mcp tools working
    - [x] reduce messages
    - [x] model is not right in shown message
    - [ ] don't need to cut and paste images
  - [ ] lectic
    - [ ] mcp
    - [ ] documentation
    - [ ] features
    - [ ] pull request
    - [ ] refactor config
  - [:] mcp tooling
    - [:] github
    - [:] git
    - [:] brave
    - [x] tavily
    - [:] agentQL
    - [x] context7
    - [:] fetch
  - [x] documentation
- [ ] lean
  - [ ] test autopairs
  - [ ] documentation
- [ ] appearances
  - bufferline and lualine
    - [x] remove light bar at the top when opening neovim
    - [x] remove lualine from start screen
    - [x] always show active tab (sometimes they seem to get lost/hidden)
    - [x] remove light color bar at the top right
    - buffer tabs sometimes get lost where the tab does not show for the open buffer
  - [ ] LazyGit
    - [ ] `<leader>gg` sometimes opens LazyGit blank
    - [ ] hard to get dialog boxes to close
  - which key
    - [ ] conflict message on <leader>w: 
      - There were issues reported with your **which-key** mappings.
      - Use `:checkhealth which-key` to find out more.
    - [x] refactor bindings
    - [x] Add icons
    - [x] make descriptions lowercase and at most two words
    - [x] improve organization of mappings
    - [:] make file-type dependent which commands appear
      - [.] check that all commands are still present
        - [ ] visual select mode for `<leader>hs`
  - [x] avante
    - [x] search/replace
    - [x] ask seems to only use one line
- [:] yanky
  - [ ] replace?
  - [x] fix error in kitty
- [:] mini
  - [ ] completion (works with blink?)
  - [ ] icons
  - [x] split/join
  - [x] align
  - [x] a/i
  - [x] diff
  - [x] cursorword
  - [x] comment
  - [x] surround
  - [x] pairs
- [:] email
  - [ ] features
    - [ ] save-drafts
      - [ ] q:save-draft
    - [ ] trash
    - [.] sync
      - [x] smart_sync using himalaya
      - [ ] sidebar status for smart_sync
      - [ ] auto_sync when nvim opens
    - [ ] email extras
      - [ ] https://github.com/pimalaya/himalaya?tab=readme-ov-file#faq
      - [ ] attachments
      - [ ] images
      - [ ] add header field to email
    - [ ] autocomplete
      - [ ] addresses in the form: Name <user@domain>
    - [x] email
      - [x] gs:send
      - [x] start cursor in email field
      - [x] tab fields
    - [x] remove/fix mappings
  - [:] sidebar
    - [x] batch operation
      - [x] spec
      - [x] colors for stared and unread
      - [x] make `<space>` work
      - [x] fix visual select
      - [x] remove boxes
    - [x] appearances
      - [ ] `<leader>mz` leaves an extra line when already up to date
      - [ ] confirm messages use return/escape
      - [ ] "Himalaya closed" can be removed
      - [x] header
        - [ ] Page 1 | 200 emails
      - [x] remove 'unlocked' that shows on start
      - [x] subject in bold
      - [x] unicode icons instead of emojis
        - [x]  Syncing (3s): 0/1 folders - Authenticating
      - [x] make sync more responsive
        - [x] avoid bumping email list
      - [x] change 'Himalaya - gmail - INBOX' to 'Himalaya - Gmail - INBOX'
      - [x] wizard output
      - [x] health output
      - [x] read email color updates slowly
    - [ ] hover and buffers
      - [ ] spec
      - [ ] hover emails
      - [ ] reply/forward/compose in buffers
  - [ ] documentation
    - [ ] spec
    - [ ] refactor
    - [ ] works with non-nix just as well?
  - [ ] publish plugin
  - [x] remove GMAIL_CLIENT_ID from private.fish?
  - [x] install himalaya
  - [x] get mbsync to work
  - [x] build himalaya-nvim plugin
    - [x] test
    - [x] make all keymaps run through which-key
    - [x] preview html in browser
    - [x] document
    - [x] simplify by removing development/testing elements
    - [x] centralize all <leader> mappings in which-key.lua
 [.] docs
  - [ ] api
  - [ ] READMEs
  - [ ] learning git
  - [x] cheatsheet
  - [x] readme
  - [:] installation
    - [:] mac
    - [:] arch
    - [:] debian
    - [:] windows
  - [x] ai video
  - [x] website
  - wiki
 [ ] undo tree commands
 [ ] checkhealth
  - [ ] install all missing programs in checkhealth
  - [x] error: client 2 quit with exit code 127 and signal 0
  - [x] error detected BufWritePre Autocommand for "\*"
 [ ] update cheatsheet
 [ ] github issues
  - [ ] consolidate add-ons
  - [ ] forks #73
  - [ ] thesaurus #69
  - [ ] blacktex #67
  - [ ] neomutt #65
  - [ ] cheat sheet #62
  - [ ] zathura themes #51
  - [ ] math conceal #48
  - [ ] latex snippets #47
  - [ ] format plugin #44
  - [ ] bare repo #35
  - [x] .gitignore #77
    - [x] should I create a personal branch?
    - [x] exclude local files
    - [x] close issue

## Completed

- [x] nvimtree
  - [x] don't resize when deleting file for open buffer
  - [x] replace with neo-tree
- [x] scripts
    - [x] reduce
    - [x] document
- [x] latex
  - [x] switch from zathura to sioyek: https://github.com/ahrm/sioyek
  - [x] highlighting
  - [x] pairs
  - [x] surround
    - [x] Fix LaTeX quote formatting with backtick positioning cursor between backtick and quote
    - [x] Fix surround keybindings conflict between mini.surround and which-key
      - [x] Aligned key references in documentation with actual keybindings
      - [x] Fixed mismatch between `<leader>ss` (surround) vs `<leader>sa` (add surrounding)
      - [x] Fixed mismatch between `<leader>sc` (change) vs `<leader>sr` (replace)
      - [x] Fixed API calls by using the correct mini.surround functions
      - [x] Updated commands to directly use require('mini.surround').function_name()
      - [x] Corrected visual mode mapping to use add('visual') method
- [x] autolist
  - [x] add in-progress field
  - [x] remove box command
- [x] todo-comments
- [x] snacks
  - [x] research plugins
  - [x] update which-key
  - [x] remove redundant plugins
    - [x] alpha
    - [x] lazygit
    - [x] indent-line
    - [x] dressing
  - [x] change indent line color
- [x] mcphub
  - [x] debug mcp tools in avante
  - [x] create user guide
  - [x] run tests to confirm that mcp works with avante
  - [x] confirm that non-nix users won't get errors
  - [x] move mcp-memory out of the .config/ directory
  - [x] lazy load when avante starts
  - [x] move `mcphub-loader.lua` to `util/`
  - [x] make `bash ~/.config/nvim/scripts/mcp-hub-nixos-install.sh` automatic if both:
    - [x] system is NixOS
    - [x] mcphub has not already been installed
  - [x] reduce notifications
- [x] move the following from `editor/` into `tools/`
  - [x] autolist.lua
  - [x] mini.lua
  - [x] surround.lua
  - [x] todo-comments.lua
  - [x] yanky.lua
- [x] move `sessions.lua` the following from `editor/` into `ui/`
- [x] move the following from `tools/` into `editor/`
  - [x] autolist.lua
  - [x] sessions.lua
  - [x] telescope.lua
  - [x] toggleterm.lua
  - [x] treesitter.lua
- [x] remove redundant files between directories
  - [x] Remove duplicate files from editor directory
  - [x] Remove duplicate files from tools directory
  - [x] Move sessions.lua to ui directory
- [x] Move modules in `plugins/coding` into `plugins/editor` and remove `plugins/coding` altogether
- [x] Remove `gh_dashboard.lua`
- [x] folding
  - [x] refine mappings
- [x] lectic
- [x] PdfAnnots in nixos
- [x] indents
  - [x] stop indents when adding brackets
  - [x] test vimtex indent
  - [x] change to 2 from 4
  - [x] add indents inside enumerate
- [x] avante
  - [x] add keybinding for asking about terminal errors
- [x] lean
  - [x] close infoview before buffer
- [x] bibexport in nixos
- [x] syntax highlighting in help
- [x] markdown tab=4
- [x] cmp-vimtex global file
- [x] system open in nvim-tree
- [x] zathura top bar
- [x] clean up end of options.lua
- [x] missing icons
- [x] integrate old todos
- [x] vertical lines extend through wrapped lines
  - [x] requires upstream change to nvim
- [x] revise snippets
  - [x] check fields
  - [x] check tabs
- [x] tab stops working in insert mode
  - [x] can't reproduce: check to see if behaviour returns
- [x] autolist
  - [x] remove highlighting of boxes in markdown
  - [x] move config out of plugins.lua
    - [x] submitted issue
  - [x] move bindings into whichkey
    - [x] submitted issue
  - [x] create empty checkbox
    - [x] submited issue

- [x] improve `autolist.lua`
  - [x] make <S-TAB> in insert mode on a list un-indent one tab
  - [x] check for autocommands or other autolist configuration that could be consolidated, improved, or better organized
  - [x] prevent autolist from creating a new indented line when creating a new line from a line that ends with ':'
  - [x] fix errors on tabbing on a bullet item in insert mode:
    - Failed to recalculate list: ...jamin/.config/nvim/lua/neotex/plugins/tools/autolist.lua:137: attempt to call field 'force_recalculate' (a nil value)
  - [x] remove message when line is indented or recalculated
  - [x] hitting 'o' or 'O' in normal mode on a line that ends with a colon still creates a list below (turn this off)
  - [x] fails to create new bullet when hitting <CR> in insert mode
  - [x] make TAB act normally if not on the beginning of a line on a bulleted list
  - [x] make shift-tab work (does nothing currently)
  - [x] look to see what improvements can be made to make things simpler and more systematic
  - [x] make <C-N> cycle in the reverse
  - [x] fix directory structure
- [x] jupyter
  - [x] fix directory structure
- [x] mini.pairs
  - [x] Fails to pass over closing ', ", and `
- [x] snacks
  - [x] move into `tools/`
- [x] Nvim Tree
  - [x] Make heading background color match the background color of buffer line
  - [x] Persistent pane size for nvimtree until restarting neovim
  - [x] fix error: Error detected while processing WinResized Autocommands for "\*": Error executing lua callback: ...enjamin/.config/nvim/lua/neotex/plugins/ui/nvim-tree.lua:82: attempt to call field 'get_win_id' (a nil value) stack traceback: ...enjamin/.config/nvim/lua/neotex/plugins/ui/nvim-tree.lua:82: in function <...enjamin/.config/nvim/lua/neotex/plugins/ui/nvim-tree.lua:81>
  - [x] fix two-step open
  - [x] reduce notifications
- [x] yanky picker
- [x] todo-comments
  - [x] make icons more stylized
- [x] comment lines
  - [x] errors for many lines selected
  - [x] only comments one line selected
  - [x] eventually comments all lines selected
- [x] buffers
  - [x] <leader>gg sometimes opens LazyGit blank
  - [x] always show active tab (sometimes they seem to get lost/hidden)
- [x] optimize
* [x] switch undotree to https://github.com/debugloop/telescope-undo.nvim
* [x] cmp-vimtex
* [x] nvim-tree
  - [x] commands not all working
  - [x] cant navigate explorer when no file is open
* [x] lags in terminal
* [x] latexmk
* [x] E248 error
* [x] replace <Tab> with <C-j> in cmd and search
* [x] add recent mac install tip from issues
* [x] toggle lsp: replace kill and load in whichkey with toggle
  - [x] submitted issue
  - [x] test suggestion
* [x] how to change root directory
  - [x] do i need project.nvim?
* [x] alpha: turn off auto create sessions
  - [x] created issue
* [x] PdfAnnots: convert from vimscript to lua
  - [x] submitted issue
* [x] undo does not work in md after checkmark
  - [x] autolist causing problems?
  - [x] auto-recalculate does not work after turning off problem code
* [x] WhichKey: checking conflicting keymaps
* [x] treesitter only load md and tex
* [x] shift-m gives error
* [x] indenting
  - [x] can't get autolist to work
  - [x] tab stops indenting after one tab
  - [x] indents on new line in enumerate
  - [x] adding braces can cause unwanted indentation
* [x] pandoc
  - [x] plugin
  - [x] bindings
  - [x] WhichKey
* [x] nvim-tree default mappings don't work
* [x] zathura freezes on suspend
* [x] can't close quickfix with space-d
* [x] bibexport does not always work?
* [x] lsp
  - [x] import from zotero
    - [x] created vimtex issue
    - [x] got MWE working
    - [x] find bug: .bib is too long
    - [x] fix bug
  - [x] navigate command and search with <C-j>, <C-k>
  - [x] spelling in lsp menu
  - [x] errors when starting a line with a backslash
  - [x] prevent menu from poping up without entering text
  - [x] creating a new line should not trigger lsp menu
  - [x] snippets
* [x] update nvim
  - [x] backup zotero
  - [x] remove zotero
  - [x] update arch
  - [x] install zotero
  - [x] update nvim
* [x] autopairs
  - [ ] add single bracket if in open pair
  - [x] move through second $
  - [x] only add spaces when between two $$
  - [x] add brackets regardless of characters following
  - [x] back tick should give latex quotes
  - [x] skip outside end of pair
* [x] customise latex snippets
  - [ ] convert to lua for context dependent snippets
  - [x] add snippets
  - [x] snippets it and bf adding new line
  - [x] snippets for it bf etc
* [x] colors
  - [x] make underlining word shading instead
* [x] WhichKey
  - [x] sessions
  - [x] surround
  - [x] git
  - [x] vimtex
* [x] decode linter symbols and commands
* [x] vimtex menu check
* [x] add telescope search text through all files in project
* [x] markdown
  - [x] turn off certain functions in markdown
* [x] autolist
  - [x] no bullet following colon
* [x] sessions in start screen
* [x] ftplugin
  - [x] fix errors in tex and md files
* [x] add latex surround objects
* [x] markdown toggle bullets
  - [x] need to extend cycle
* [x] lsp no menu without typing
  - [x] could refine cmd-commandline plugin which was the problem
