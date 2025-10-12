local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local mux = wezterm.mux

-- Start maximized (commented out to avoid duplicate)

-- FONT
config.font_size = 12.0
config.font = wezterm.font('RobotoMono Nerd Font Mono')

-- PERFORMANCE
config.enable_wayland = true
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.max_fps = 120
config.animation_fps = 60
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

-- LAYOUT
config.initial_cols = 80
config.initial_rows = 24
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}
-- TAB BAR
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false

-- -- Option 1: Direct toggle_fullscreen (original approach)
-- wezterm.on('gui-startup', function(cmd)
--     local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
--     window:gui_window():toggle_fullscreen()
-- end)

-- Option 2: Maximize window (fills screen but keeps system bars)
wezterm.on('gui-startup', function(cmd)
    local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
    window:gui_window():maximize()
end)

-- -- Option 3: Using perform_action (often more reliable)
-- wezterm.on('gui-startup', function(cmd)
--     local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
--     local gui_window = window:gui_window()
--     gui_window:perform_action(wezterm.action.ToggleFullScreen, pane)
-- end)

-- APPEARANCE
config.window_decorations = "TITLE | RESIZE"  -- Shows title bar with minimize, maximize, close buttons
config.window_background_opacity = 0.9
config.text_background_opacity = 1.0
config.adjust_window_size_when_changing_font_size = false

-- Color scheme matching Kitty
config.colors = {
  foreground = '#d0d0d0',
  background = '#202020',
  cursor_bg = '#d0d0d0',
  cursor_fg = '#202020',
  selection_fg = '#202020',
  selection_bg = '#303030',
  
  ansi = {
    '#151515', -- black
    '#ac4142', -- red
    '#7e8d50', -- green
    '#e5b566', -- yellow
    '#6c99ba', -- blue
    '#9e4e85', -- magenta
    '#7dd5cf', -- cyan
    '#d0d0d0', -- white
  },
  brights = {
    '#505050', -- bright black
    '#ac4142', -- bright red
    '#7e8d50', -- bright green
    '#e5b566', -- bright yellow
    '#6c99ba', -- bright blue
    '#9e4e85', -- bright magenta
    '#7dd5cf', -- bright cyan
    '#f5f5f5', -- bright white
  },
}

-- GENERAL
config.default_prog = { '/usr/local/bin/fish' }
config.selection_word_boundary = " \t\n{}[]()\"'`"

-- SCROLLBACK
config.scrollback_lines = 10000
config.enable_scroll_bar = false

-- MOUSE SUPPORT
config.hide_mouse_cursor_when_typing = false  -- Keep mouse cursor visible when typing
config.mouse_bindings = {
  -- Right click to paste
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = wezterm.action.PasteFrom 'Clipboard',
  },
  -- Change selection to copy to clipboard
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor 'ClipboardAndPrimarySelection',
  },
  -- Middle click to paste from primary selection
  {
    event = { Down = { streak = 1, button = 'Middle' } },
    mods = 'NONE',
    action = wezterm.action.PasteFrom 'PrimarySelection',
  },
  -- Ctrl+Click to open URLs
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = wezterm.action.OpenLinkAtMouseCursor,
  },
}

-- TAB BAR
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.show_tabs_in_tab_bar = true
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 25

-- Smaller, sleeker tab bar styling
config.window_frame = {
  font = wezterm.font({ family = 'RobotoMono Nerd Font Mono', weight = 'Bold' }),
  font_size = 9.0,
  active_titlebar_bg = '#202020',
  inactive_titlebar_bg = '#202020',
}

-- Tab bar colors
config.colors.tab_bar = {
  background = '#1a1a1a',
  
  active_tab = {
    bg_color = '#3a3a3a',
    fg_color = '#d0d0d0',
    intensity = 'Bold',
    underline = 'None',
    italic = false,
    strikethrough = false,
  },
  
  inactive_tab = {
    bg_color = '#202020',
    fg_color = '#808080',
    intensity = 'Normal',
  },
  
  inactive_tab_hover = {
    bg_color = '#2a2a2a',
    fg_color = '#a0a0a0',
    italic = false,
  },
  
  new_tab = {
    bg_color = '#1a1a1a',
    fg_color = '#808080',
  },
  
  new_tab_hover = {
    bg_color = '#2a2a2a',
    fg_color = '#a0a0a0',
  },
}

-- Custom tab title formatting with cleaner look
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local edge_background = '#1a1a1a'
  local background = tab.is_active and '#3a3a3a' or '#202020'
  local foreground = tab.is_active and '#d0d0d0' or '#808080'
  
  local title = tostring(tab.tab_index + 1)
  
  -- Add separator between tabs
  local separator = tab.tab_index < #tabs - 1 and '│' or ''
  
  return {
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = ' ' .. title .. ' ' },
    { Background = { Color = edge_background } },
    { Foreground = { Color = '#404040' } },
    { Text = separator },
  }
end)

-- LEADER KEY - Ctrl+Space just like Kitty
config.leader = { key = 'Space', mods = 'CTRL', timeout_milliseconds = 1000 }

-- Visual bell instead of audio
config.audible_bell = 'Disabled'
config.visual_bell = {
  fade_in_function = 'EaseIn',
  fade_in_duration_ms = 75,
  fade_out_function = 'EaseOut',
  fade_out_duration_ms = 75,
  target = 'CursorColor',
}

-- KEYBINDINGS
config.keys = {
  -- Fullscreen toggle (Alt+Enter is the WezTerm default)
  {
    key = 'Enter',
    mods = 'ALT',
    action = wezterm.action.ToggleFullScreen,
  },
  
  -- Tab management with Ctrl+Space leader
  {
    key = 'c',
    mods = 'LEADER',
    action = wezterm.action.SpawnTab 'CurrentPaneDomain',
  },
  {
    key = 'k',
    mods = 'LEADER',
    action = wezterm.action.CloseCurrentTab { confirm = true },
  },
  {
    key = 'n',
    mods = 'LEADER',
    action = wezterm.action.ActivateTabRelative(1),
  },
  {
    key = 'p',
    mods = 'LEADER',
    action = wezterm.action.ActivateTabRelative(-1),
  },

  -- Font size adjustment matching Kitty
  {
    key = '=',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.IncreaseFontSize,
  },
  {
    key = '+',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.IncreaseFontSize,
  },
  {
    key = '-',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.DecreaseFontSize,
  },
  
  -- Copy/Paste with Ctrl+Shift (leaves Ctrl+C unbound for terminal use)
  {
    key = 'c',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.CopyTo 'Clipboard',
  },
  {
    key = 'v',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.PasteFrom 'Clipboard',
  },
  
  
  -- Search mode
  {
    key = '/',
    mods = 'LEADER',
    action = wezterm.action.Search { CaseSensitiveString = '' },
  },
  
  -- Copy mode (vim-like scrolling)
  {
    key = '[',
    mods = 'LEADER',
    action = wezterm.action.ActivateCopyMode,
  },
  
  -- Command palette (useful for discovering commands)
  {
    key = 'P',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivateCommandPalette,
  },
}

-- Enable copy on select (similar to Kitty's copy_on_select = yes)
config.selection_word_boundary = " \t\n{}[]()\"'`"

-- Smart selection patterns for double-click
config.quick_select_patterns = {
  -- URLs
  'https?://[\\w\\.-]+\\S*',
  -- File paths
  '(?:[\\w\\-\\.]+)?(?:/[\\w\\-\\.]+)+',
  -- Email addresses
  '[\\w\\.-]+@[\\w\\.-]+\\.[\\w]+',
  -- IP addresses
  '\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b',
  -- Hex colors
  '#[0-9a-fA-F]{3,8}',
}

return config
