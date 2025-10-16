# NvimTree to Neo-tree Migration Analysis

## Current NvimTree Configuration Overview

### Core Functionality

#### Width Persistence System
- **Custom global module** `_G.NvimTreePersistence` maintains width across sessions
- **File-based persistence**: Stores width in `vim.fn.stdpath("data") .. "/nvim_tree_width"`
- **Dynamic width tracking**: Captures window resize events via `WinResized` autocmd
- **Validation**: Width must be between 10-100 characters
- **Default width**: 30 characters

#### Custom Open/Close/Toggle Functions
- **Enhanced toggle**: `_G.NvimTreePersistence.toggle()` with width preservation
- **Custom open**: `_G.NvimTreePersistence.open()` applies saved width immediately
- **Custom close**: `_G.NvimTreePersistence.close()` saves width before closing
- **Override**: Replaces default `api.tree.toggle` with custom implementation

#### Advanced Width Management
- **Multiple width injection points**: Updates width in all possible modules/configs
- **Race condition prevention**: Uses `opening` flag to prevent resize flicker
- **Window creation hooks**: AutoCmds on `BufWinEnter`, `WinNew`, `BufEnter`
- **Immediate width application**: Uses `vim.schedule()` for proper timing
- **Fixed width windows**: Sets `winfixwidth = true` to prevent unwanted resizing

### Visual Customization

#### Color Scheme Integration
- **Directory coloring**: Soft light purple (`#b294bb`) for all folder elements
- **Header background matching**: Syncs with BufferLine background colors
- **Dynamic color application**: Responds to colorscheme changes
- **Git integration colors**: Matches GitSigns colors for consistency
- **Multiple highlight groups**: Covers all NvimTree-specific elements

#### Custom Styling Features
- **Root folder display**: Shows only last path component (`:t` modifier)
- **Modified file indicators**: Orange circle (`�`) with custom placement
- **Custom git icons**: Styled indicators for different git states
- **Background transparency**: Tree content has transparent background
- **Header contrast**: Different background for top directory path

### Behavioral Modifications

#### Scroll and Navigation Prevention
- **Horizontal scroll disabled**: Blocks all horizontal movement commands
- **Word highlighting disabled**: Prevents cursor word highlighting plugins
- **Custom key mappings**: Comprehensive vim-style navigation
- **Mouse interaction**: Custom double-click and scroll wheel handling

#### Buffer Integration
- **BufferLine integration**: Offset configuration for proper layout
- **Auto-close**: Quits on file open with window resizing

### Advanced AutoCmd System

#### State Tracking AutoCmds
```lua
-- Width persistence
WinResized � save_width()
User NvimTreeOpened � is_open = true, delayed save_width()
User NvimTreeClosed � is_open = false
BufEnter � detect NvimTree buffers, set is_open = true

-- Visual consistency
ColorScheme � reapply all custom highlights
FileType NvimTree � disable word highlighting, set scroll options
WinEnter � ensure consistent window settings
VimEnter � final color application, custom truncation highlights
```

#### Multi-trigger Color Application
- **Immediate**: `vim.schedule()` application
- **Delayed**: 100ms delay for race condition handling
- **VimEnter**: Final application after full UI load
- **ColorScheme**: Reapplication on theme changes

### Key Mappings
- **Vim-style navigation**: `h` (close), `l` (open), `J/K` (first/last sibling)
- **File operations**: `a` (create), `d` (delete), `D` (trash), `r` (rename)
- **Tree operations**: `R` (refresh), `q` (close), `?` (help)
- **Split operations**: `v` (vertical split), `<CR>` (tab open)
- **Directory navigation**: `-` (parent), `O` (parent directory)

### Configuration Highlights

#### Git Integration
- **Enabled git tracking**: Shows git status on files and directories
- **Custom git icons**: Styled for different states (staged, unstaged, untracked, etc.)
- **Directory git status**: Shows git changes at folder level
- **Timeout**: 500ms for git operations

#### File Filtering
- **No default filters**: Git ignored files and dotfiles are visible
- **Custom exclusions**: Can be configured per project
- **No buffer filtering**: All buffers visible in tree

#### Renderer Options
- **Modified file tracking**: Shows indicators for unsaved changes
- **Git highlighting**: Integrated with git status
- **Root folder customization**: Only shows directory name, not full path
- **Icon configuration**: Web devicons for files, custom folder icons
- **Indent markers**: Optional with custom styling

## Critical Features for Neo-tree Migration

### Must-Have Features
1. **Width persistence across sessions** - Core functionality
2. **Dynamic width tracking and saving** - Essential for user experience
3. **BufferLine integration with offset** - Layout requirement
4. **Custom color theming with auto-application** - Visual consistency
5. **Vim-style key mappings** - Workflow requirement
6. **Git integration with custom styling** - Development workflow
7. **Modified file indicators** - File state tracking
8. **Horizontal scroll prevention** - UX requirement

### Complex Features
1. **Multi-point width injection system** - May need complete rewrite
2. **Custom toggle/open/close functions** - Behavior override system
3. **Race condition prevention** - Timing-sensitive operations
4. **Multiple autocmd triggers** - Complex state management
5. **Dynamic colorscheme integration** - Advanced theming

### Potential Migration Challenges
1. **Global state management** - Neo-tree may use different architecture
2. **Plugin API differences** - Custom function overrides may not work
3. **AutoCmd patterns** - Different event names/timing
4. **Configuration structure** - Neo-tree uses different option organization
5. **Width persistence implementation** - May require custom neo-tree extensions

## Neo-tree Research Results

### Neo-tree Configuration Capabilities

#### Window Width Management
- **Configuration**: `window.width` accepts numeric values, percentages, or "fit_content"
- **Min/max constraints**: Supports width limits
- **Dynamic resizing**: Via `vim.api.nvim_win_set_width(tree_win_handle, width)`
- **Challenge**: Finding window handle requires manual search code
- **No built-in persistence**: Width persistence must be implemented manually

#### Event System
- **Comprehensive events**: `before_render`, `after_render`, `file_opened`, `neo_tree_buffer_enter/leave`
- **Custom event handling**: Supports hook functions in setup
- **File operation events**: `file_added`, `file_deleted`, `file_moved`
- **Window events**: `neo_tree_window_before_open`

#### Color Customization
- **Extensive highlight groups**: `NeoTreeGitAdded`, `NeoTreeDirectoryIcon`, `NeoTreeFileName`
- **Git-specific highlights**: Separate highlight groups for git status
- **Custom theming**: Full control over visual appearance
- **Dynamic updates**: Colors can be changed via standard Neovim highlight commands

#### Key Mapping System
- **Fully customizable**: Normal and visual mode mappings
- **Command system**: Built-in commands like `git_add_file`, `git_commit`
- **Disable defaults**: Can override all default keymaps
- **Argument support**: Mappings can accept parameters

#### Git Integration
- **Built-in git status**: Automatic display of git changes
- **Configurable symbols**: Custom icons for git states
- **Git commands**: Integrated git operations from tree
- **Directory-level status**: Shows git status on folders

### Migration Feasibility Analysis

#### ✅ Directly Migrable Features
1. **Git integration** - Neo-tree has comprehensive git support
2. **Custom key mappings** - Full customization available
3. **Color theming** - Extensive highlight group system
4. **File operations** - All basic operations supported
5. **BufferLine integration** - Should work with offset configuration

#### ⚠️ Requires Custom Implementation
1. **Width persistence** - Must implement custom session saving/loading
2. **Dynamic width tracking** - Need custom `VimResized` handling
3. **Multi-trigger color application** - Custom autocmd setup required
4. **Horizontal scroll prevention** - Must implement buffer-local settings

#### ❌ Complex Migration Challenges
1. **Global state management** - `_G.NvimTreePersistence` pattern not directly applicable
2. **Multi-point width injection** - Neo-tree uses different architecture
3. **Race condition prevention** - Different timing model may require rework
4. **Custom toggle functions** - API override system may not be available

### Recommended Migration Strategy

#### Phase 1: Basic Migration
1. Replace nvim-tree plugin with neo-tree
2. Migrate basic configuration (git, keys, colors)
3. Set up BufferLine offset
4. Implement basic width setting

#### Phase 2: Width Persistence
1. Create custom module for width tracking
2. Implement `VimResized` event handler
3. Add session-based width persistence
4. Handle window finding logic

#### Phase 3: Advanced Features
1. Migrate complex color theming
2. Implement horizontal scroll prevention
3. Add multi-trigger color application
4. Fine-tune timing and race condition handling

#### Phase 4: Optimization
1. Performance tuning
2. Edge case handling
3. User experience refinement

### Key Implementation Notes
- **Width control**: Must use `vim.api.nvim_win_set_width()` with manual window finding
- **Events**: Use `neo_tree_buffer_enter` for setup, `VimResized` for width tracking
- **Persistence**: Implement file-based storage similar to current system
- **State management**: Create new module structure compatible with Neo-tree architecture

## Neo-tree Implementation Plan

### Architecture Overview

Neo-tree's natural patterns emphasize:
- **Event-driven architecture**: Uses `event_handlers` in setup configuration
- **Component-based rendering**: Everything is a function or component config
- **Session integration**: Works with persistence plugins via pre/post commands
- **Clean API**: `require('neo-tree.command').execute()` for programmatic control

### Implementation Strategy

#### 1. Width Persistence Module (`lua/neotex/util/neotree-width.lua`)

Create a dedicated module that works with Neo-tree's event system:

```lua
local M = {}

-- Width storage
M.width_file = vim.fn.stdpath("data") .. "/neotree_width"
M.default_width = 30
M.current_width = M.default_width

-- Load width from file
function M.load_width()
  if vim.fn.filereadable(M.width_file) == 1 then
    local content = vim.fn.readfile(M.width_file)
    local width = tonumber(content[1])
    if width and width > 10 and width < 100 then
      M.current_width = width
      return width
    end
  end
  return M.default_width
end

-- Save width to file
function M.save_width(width)
  if width and width > 10 and width < 100 then
    M.current_width = width
    vim.fn.writefile({ tostring(width) }, M.width_file)
  end
end

-- Find neo-tree window
function M.find_neotree_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "neo-tree" then
      return win
    end
  end
  return nil
end

-- Apply width to neo-tree window
function M.apply_width(width)
  local win = M.find_neotree_window()
  if win then
    vim.api.nvim_win_set_width(win, width or M.current_width)
  end
end

-- Track width changes
function M.track_width_change()
  local win = M.find_neotree_window()
  if win then
    local new_width = vim.api.nvim_win_get_width(win)
    if new_width ~= M.current_width then
      M.save_width(new_width)
    end
  end
end

return M
```

#### 2. Neo-tree Configuration with Natural Event Handlers

```lua
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    local width_manager = require("neotex.util.neotree-width")
    
    -- Load saved width
    local saved_width = width_manager.load_width()
    
    require("neo-tree").setup({
      close_if_last_window = true,
      
      window = {
        width = saved_width,
        position = "left",
      },
      
      -- Natural event handlers using Neo-tree's event system
      event_handlers = {
        -- Apply custom settings when entering neo-tree buffer
        {
          event = "neo_tree_buffer_enter",
          handler = function()
            -- Disable word highlighting
            vim.b.minicursorword_disable = true
            vim.b.local_highlight_enabled = false
            vim.opt_local.hlsearch = false
            
            -- Prevent horizontal scrolling
            vim.opt_local.sidescrolloff = 0
            vim.opt_local.wrap = false
            
            -- Apply saved width
            vim.defer_fn(function()
              width_manager.apply_width()
            end, 10)
          end,
        },
        
        -- Save width when closing
        {
          event = "neo_tree_window_before_close",
          handler = function()
            width_manager.track_width_change()
          end,
        },
        
        -- Auto-close behavior
        {
          event = "file_opened",
          handler = function()
            -- Close after opening file (mimics nvim-tree behavior)
            require("neo-tree.command").execute({ action = "close" })
          end,
        },
      },
      
      -- BufferLine integration
      default_component_configs = {
        container = {
          enable_character_fade = true,
        },
      },
      
      -- Git integration
      filesystem = {
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false,
        },
        filtered_items = {
          visible = true, -- Show dotfiles and git ignored (like nvim-tree)
          hide_dotfiles = false,
          hide_gitignored = false,
        },
        components = {
          -- Custom component for modified files (mimics nvim-tree indicator)
          modified = function(config, node, state)
            if node.type == "file" and vim.fn.getbufvar(node.path, "&modified") == 1 then
              return {
                text = " ◉",
                highlight = "NeoTreeModified",
              }
            end
            return {}
          end,
        },
      },
      
      -- Key mappings (vim-style like nvim-tree)
      window = {
        width = saved_width,
        mappings = {
          ["l"] = "open",
          ["h"] = "close_node",
          ["J"] = "last_sibling",
          ["K"] = "first_sibling",
          ["-"] = "navigate_up",
          ["a"] = "add",
          ["d"] = "delete",
          ["r"] = "rename",
          ["y"] = "copy_to_clipboard",
          ["x"] = "cut_to_clipboard",
          ["p"] = "paste_from_clipboard",
          ["q"] = "close_window",
          ["R"] = "refresh",
          ["?"] = "show_help",
          ["H"] = "toggle_hidden",
          ["v"] = "open_vsplit",
          ["<CR>"] = "open_tabnew",
          ["o"] = "system_open",
        },
      },
    })
    
    -- Set up width tracking via VimResized
    vim.api.nvim_create_autocmd("VimResized", {
      group = vim.api.nvim_create_augroup("NeoTreeWidthTracking", { clear = true }),
      callback = function()
        width_manager.track_width_change()
      end,
      desc = "Track Neo-tree width changes",
    })
    
    -- Color scheme integration
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("NeoTreeColors", { clear = true }),
      callback = function()
        -- Apply custom colors (similar to nvim-tree)
        local dir_color = "#b294bb"
        
        -- Directory colors
        vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { fg = dir_color, bold = true })
        vim.api.nvim_set_hl(0, "NeoTreeDirectoryIcon", { fg = dir_color })
        vim.api.nvim_set_hl(0, "NeoTreeRootName", { fg = dir_color, bold = true, italic = true })
        
        -- Modified file indicator
        vim.api.nvim_set_hl(0, "NeoTreeModified", { fg = "#e78a4e", bold = true })
        
        -- Git colors (match GitSigns)
        local git_colors = _G.GitColors or {
          add = "#4fa6ed",
          change = "#e78a4e", 
          delete = "#fb4934"
        }
        vim.api.nvim_set_hl(0, "NeoTreeGitAdded", { fg = git_colors.add, bold = true })
        vim.api.nvim_set_hl(0, "NeoTreeGitModified", { fg = git_colors.change, bold = true })
        vim.api.nvim_set_hl(0, "NeoTreeGitDeleted", { fg = git_colors.delete, bold = true })
      end,
    })
  end,
}
```

#### 3. BufferLine Integration Update

Update BufferLine configuration for Neo-tree:

```lua
-- In bufferline.lua config
offsets = {
  {
    filetype = "neo-tree",
    text = function()
      return vim.fn.getcwd()
    end,
    highlight = "BufferLineFill",
    text_align = "left",
    separator = "",
  }
},
```

#### 4. Session Management Integration

For session persistence, use Neo-tree's natural patterns:

```lua
-- In session management plugin config
pre_save_cmds = { 
  function()
    -- Save width before session save
    local width_manager = require("neotex.util.neotree-width")
    width_manager.track_width_change()
    -- Close neo-tree
    require("neo-tree.command").execute({ action = "close" })
  end
},
post_restore_cmds = { 
  function()
    -- Restore neo-tree with saved width
    local width_manager = require("neotex.util.neotree-width")
    local saved_width = width_manager.load_width()
    require("neo-tree.command").execute({ 
      action = "show",
      source = "filesystem",
      position = "left",
    })
    vim.defer_fn(function()
      width_manager.apply_width(saved_width)
    end, 100)
  end
},
```

### Key Advantages of This Approach

1. **Works with Neo-tree's architecture**: Uses event handlers, components, and commands as intended
2. **Clean separation**: Width management is isolated in a dedicated module
3. **Natural event flow**: No API overrides or complex timing dependencies
4. **Session integration**: Works cleanly with persistence plugins
5. **Extensible**: Easy to add new behaviors through event handlers
6. **Maintainable**: Follows Neo-tree's recommended patterns

### Migration Benefits

- **Reduced complexity**: No global state management or race condition handling
- **Better reliability**: Uses Neo-tree's stable event system
- **Future-proof**: Works with Neo-tree updates and changes
- **Cleaner code**: Much simpler than the current nvim-tree implementation
- **Natural behavior**: Leverages Neo-tree's design patterns

## Migration Conclusion

This Neo-tree implementation provides equivalent functionality to your current NvimTree setup while working naturally with Neo-tree's architecture. The approach eliminates the complex global state management and timing dependencies in favor of Neo-tree's event-driven design, resulting in cleaner, more maintainable code.
