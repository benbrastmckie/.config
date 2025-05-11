------------------------------------------------------------------------
-- Avante Enhanced Highlights and Visual Indicators
------------------------------------------------------------------------
-- This module provides enhanced visual indicators for Avante's UI,
-- particularly for diff views and suggestions
--
-- Features:
-- 1. Enhanced diff highlighting for additions/deletions
-- 2. Gutter markers for changes
-- 3. Inline preview styles
-- 4. Distinct coloring for different types of changes

local M = {}

-- Setup enhanced highlighting
function M.setup()
  -- Define highlight groups for Avante
  local highlights = {
    -- Diff highlighting (enhanced)
    AvanteAddition = { fg = "#a6e3a1", bg = "#1e332a", bold = true },     -- Bright green on dark green bg
    AvanteDeletion = { fg = "#f38ba8", bg = "#332a2e", bold = true },     -- Bright red on dark red bg
    AvanteModification = { fg = "#89b4fa", bg = "#2a2e33", bold = true }, -- Bright blue on dark blue bg
    AvanteChange = { fg = "#f9e2af", bg = "#332e2a", bold = true },       -- Bright yellow on dark yellow bg
    
    -- Cursor line indicator
    AvanteCursorLine = { bg = "#313244", bold = true },                   -- Highlight current change
    
    -- Gutter indicators
    AvanteGutterAdd = { fg = "#a6e3a1", bold = true },                    -- Green indicator in gutter
    AvanteGutterDelete = { fg = "#f38ba8", bold = true },                 -- Red indicator in gutter
    AvanteGutterChange = { fg = "#89b4fa", bold = true },                 -- Blue indicator in gutter
    
    -- Inline preview
    AvanteInlinePreview = { fg = "#cdd6f4", bg = "#1e1e2e", italic = true }, -- Softer text for preview
    AvanteInlinePreviewBorder = { fg = "#89b4fa" },                       -- Border for inline preview
    
    -- Suggestion highlighting
    AvanteSuggestion = { fg = "#89dceb", bg = "#1e1e2e", italic = true }, -- Cyan for suggestions
    AvanteSuggestionActive = { fg = "#89dceb", bg = "#313244", bold = true }, -- Active suggestion
    
    -- Status indicators
    AvanteSuccess = { fg = "#a6e3a1", bold = true },                      -- Success indicator
    AvanteError = { fg = "#f38ba8", bold = true },                        -- Error indicator
    AvanteWarning = { fg = "#f9e2af", bold = true },                      -- Warning indicator
    AvanteInfo = { fg = "#89b4fa", bold = true },                         -- Info indicator
    
    -- Progress indicators
    AvanteProgress = { fg = "#cba6f7", bold = true },                     -- Progress indicator
    AvanteProgressDone = { fg = "#a6e3a1", bold = true },                 -- Completed progress
  }
  
  -- Apply highlight groups
  for name, attrs in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, attrs)
  end
  
  -- Create the sign column markers
  local signs = {
    { name = "AvanteAddSign", text = "▎", texthl = "AvanteGutterAdd" },
    { name = "AvanteDelSign", text = "▎", texthl = "AvanteGutterDelete" },
    { name = "AvanteChangeSign", text = "▎", texthl = "AvanteGutterChange" },
  }
  
  for _, sign in ipairs(signs) do
    vim.fn.sign_define(sign.name, {
      text = sign.text,
      texthl = sign.texthl,
      linehl = "",
      numhl = "",
    })
  end
  
  -- Setup autocommands to apply enhanced highlights to Avante buffers
  local group = vim.api.nvim_create_augroup("AvanteHighlights", { clear = true })
  
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "Avante", "AvanteInput" },
    group = group,
    callback = function(opts)
      local bufnr = opts.buf
      
      -- Enable sign column for this buffer
      vim.opt_local.signcolumn = "yes:1"
      
      -- Update Avante's highlight groups
      M.update_avante_highlights()
    end,
  })
  
  -- Return success status
  return true
end

-- Update Avante's highlight configuration
function M.update_avante_highlights()
  -- Ensure avante config is updated to use our highlight groups
  vim.defer_fn(function()
    local ok, avante_config = pcall(require, "avante.config")
    if ok and avante_config and avante_config.override then
      avante_config.override({
        highlights = {
          diff = {
            add = "AvanteAddition",
            delete = "AvanteDeletion", 
            change = "AvanteModification",
            current = "AvanteCursorLine",
          },
          suggestion = {
            default = "AvanteSuggestion",
            active = "AvanteSuggestionActive",
          },
        },
      })
    end
  end, 100)
end

-- Get the current theme's highlight values or provide fallbacks
function M.get_theme_colors()
  local colors = {}
  
  -- Try to get colors from current colorscheme
  local function get_hl_attr(name, attr)
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    if hl and hl[attr] then
      return string.format("#%06x", hl[attr])
    end
    return nil
  end
  
  -- Try to extract colors from existing highlight groups
  colors.add_fg = get_hl_attr("DiffAdd", "fg") or "#a6e3a1"
  colors.add_bg = get_hl_attr("DiffAdd", "bg") or "#1e332a"
  colors.del_fg = get_hl_attr("DiffDelete", "fg") or "#f38ba8"
  colors.del_bg = get_hl_attr("DiffDelete", "bg") or "#332a2e"
  colors.change_fg = get_hl_attr("DiffChange", "fg") or "#89b4fa"
  colors.change_bg = get_hl_attr("DiffChange", "bg") or "#2a2e33"
  colors.text_fg = get_hl_attr("Normal", "fg") or "#cdd6f4"
  colors.text_bg = get_hl_attr("Normal", "bg") or "#1e1e2e"
  
  return colors
end

-- Apply highlight using current theme colors
function M.apply_theme_aware_highlights()
  local colors = M.get_theme_colors()
  
  -- Update highlight groups based on current theme
  vim.api.nvim_set_hl(0, "AvanteAddition", { fg = colors.add_fg, bg = colors.add_bg, bold = true })
  vim.api.nvim_set_hl(0, "AvanteDeletion", { fg = colors.del_fg, bg = colors.del_bg, bold = true })
  vim.api.nvim_set_hl(0, "AvanteModification", { fg = colors.change_fg, bg = colors.change_bg, bold = true })
  vim.api.nvim_set_hl(0, "AvanteGutterAdd", { fg = colors.add_fg, bold = true })
  vim.api.nvim_set_hl(0, "AvanteGutterDelete", { fg = colors.del_fg, bold = true })
  vim.api.nvim_set_hl(0, "AvanteGutterChange", { fg = colors.change_fg, bold = true })
  
  -- Return success status
  return true
end

-- Return the module
return M