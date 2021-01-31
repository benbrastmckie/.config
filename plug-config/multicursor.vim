" NOTE: https://github.com/mg979/vim-visual-multi/wiki

" NOTE:
" If you instead want to disable a specific mapping, set it to an empty string:
" let g:VM_maps['Find Under'] = ''                    " disable find under

" NOTE: Mappings with \\ are meant prefixed by the VM_leader

let g:VM_default_mappings = 0                           " disables below
let g:VM_mouse_mappings = 1
let g:VM_leader = ','
let g:VM_maps = {}                                      " init dictionary
" let g:VM_custom_remaps = {'<c-p>': '[', '<c-x>': 'q'}   " use <c-p> to find backwards, <c-s> to skip a match


" NOTE: permanant mappings below are enabled by default
let g:VM_maps['Find Under']                  = '<C-n>'
let g:VM_maps['Find Subword Under']          = '<C-n>'
" let g:VM_maps["Select All"]                  = '<C-A>'
" let g:VM_maps["Start Regex Search"]          = '<C-/>'
" let g:VM_maps["Add Cursor Down"]             = '<C-Down>'
" let g:VM_maps["Add Cursor Up"]               = '<C-Up>'
" let g:VM_maps["Add Cursor At Pos"]           = '\\\'

" let g:VM_maps["Visual Regex"]                = '\\/'
" let g:VM_maps["Visual All"]                  = '\\A' 
" let g:VM_maps["Visual Add"]                  = '\\a'
" let g:VM_maps["Visual Find"]                 = '\\f'
" let g:VM_maps["Visual Cursors"]              = '\\c'


" NOTE: permanant mappings below are not enabled by default
let g:VM_maps["Undo"] = 'u'                             " 
let g:VM_maps["Redo"] = '<C-r>'                         " 
" let g:VM_maps["Select Cursor Down"]          = '<M-C-Down>'
" let g:VM_maps["Select Cursor Up"]            = '<M-C-Up>'

" let g:VM_maps["Erase Regions"]               = '\\gr'

let g:VM_maps["Mouse Cursor"]                = '<C-LeftMouse>'
let g:VM_maps["Mouse Word"]                  = '<C-RightMouse>'
let g:VM_maps["Mouse Column"]                = '<M-C-RightMouse>'


" NOTE: buffer mappings below are enabled by default
let g:VM_maps["Switch Mode"]                 = '<Tab>'

let g:VM_maps["Find Next"]                   = ']'
let g:VM_maps["Find Prev"]                   = '['
" let g:VM_maps["Goto Next"]                   = '}'
" let g:VM_maps["Goto Prev"]                   = '{'
" let g:VM_maps["Seek Next"]                   = '<C-f>'
" let g:VM_maps["Seek Prev"]                   = '<C-b>'
let g:VM_maps["Skip Region"]                 = '<C-x>'
let g:VM_maps["Remove Region"]               = '<C-p>'
" let g:VM_maps["Invert Direction"]            = 'o'
" let g:VM_maps["Find Operator"]               = "m"
let g:VM_maps["Surround"]                    = 'S'
let g:VM_maps["Replace Pattern"]             = 'R'

" let g:VM_maps["Tools Menu"]                  = '\\`'
" let g:VM_maps["Show Registers"]              = '\\"'
" let g:VM_maps["Case Setting"]                = '\\c'
" let g:VM_maps["Toggle Whole Word"]           = '\\w'
" let g:VM_maps["Transpose"]                   = '\\t'
" let g:VM_maps["Align"]                       = '\\a'
" let g:VM_maps["Duplicate"]                   = '\\d'
" let g:VM_maps["Rewrite Last Search"]         = '\\r'
" let g:VM_maps["Merge Regions"]               = '\\m'
" let g:VM_maps["Split Regions"]               = '\\s'
" let g:VM_maps["Remove Last Region"]          = '\\q'
" let g:VM_maps["Visual Subtract"]             = '\\s'
" let g:VM_maps["Case Conversion Menu"]        = '\\C'
" let g:VM_maps["Search Menu"]                 = '\\S'

" let g:VM_maps["Run Normal"]                  = '\\z'
" let g:VM_maps["Run Last Normal"]             = '\\Z'
" let g:VM_maps["Run Visual"]                  = '\\v'
" let g:VM_maps["Run Last Visual"]             = '\\V'
" let g:VM_maps["Run Ex"]                      = '\\x'
" let g:VM_maps["Run Last Ex"]                 = '\\X'
let g:VM_maps["Run Macro"]                   = '\\@'
" let g:VM_maps["Align Char"]                  = '\\<'
" let g:VM_maps["Align Regex"]                 = '\\>'
" let g:VM_maps["Numbers"]                     = '\\n'
" let g:VM_maps["Numbers Append"]              = '\\N'
" let g:VM_maps["Zero Numbers"]                = '\\0n'
" let g:VM_maps["Zero Numbers Append"]         = '\\0N'
" let g:VM_maps["Shrink"]                      = "\\-"
" let g:VM_maps["Enlarge"]                     = "\\+"

" let g:VM_maps["Toggle Block"]                = '\\<BS>'
" let g:VM_maps["Toggle Single Region"]        = '\\<CR>'
" let g:VM_maps["Toggle Multiline"]            = '\\M'
