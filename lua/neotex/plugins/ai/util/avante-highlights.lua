------------------------------------------------------------------------
-- Avante Enhanced Highlights and Visual Indicators
------------------------------------------------------------------------
-- This module provides streamlined visual indicators for Avante's UI,
-- focusing on the most important visual elements for an optimal experience.
--
-- Key Features:
-- 1. Essential diff highlighting for additions/deletions
-- 2. Gutter markers for better change visualization
-- 3. Theme-aware highlighting that adapts to your colorscheme
-- 4. Optimized for performance and visual clarity

local M = {}

-- Get the current theme's highlight values with smart fallbacks
-- This function is optimized to efficiently extract colors from your current theme
function M.get_theme_colors()
  local colors = {}
  
  -- Helper function to get highlight attributes with better error handling
  local function get_hl_attr(name, attr, fallback)
    local success, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if success and hl and hl[attr] then
      return string.format("#%06x", hl[attr])
    end
    
    -- Try alternative highlight groups if primary one isn't available
    if attr == "fg" and name == "DiffAdd" then
      -- Try GitSigns or other git highlighting as alternatives
      local alt_color = get_hl_attr("GitSignsAdd", attr) or 
                        get_hl_attr("GitGutterAdd", attr) or
                        get_hl_attr("SignAdd", attr)
      if alt_color then return alt_color end
    elseif attr == "fg" and name == "DiffDelete" then
      local alt_color = get_hl_attr("GitSignsDelete", attr) or 
                        get_hl_attr("GitGutterDelete", attr) or
                        get_hl_attr("SignDelete", attr)
      if alt_color then return alt_color end
    elseif attr == "fg" and name == "DiffChange" then
      local alt_color = get_hl_attr("GitSignsChange", attr) or 
                        get_hl_attr("GitGutterChange", attr) or
                        get_hl_attr("SignChange", attr)
      if alt_color then return alt_color end
    end
    
    return fallback
  end
  
  -- Extract core colors from theme with better fallbacks
  -- Using a more diverse set of highlight groups for better theme integration
  colors.add_fg = get_hl_attr("DiffAdd", "fg", "#a6e3a1")
  colors.add_bg = get_hl_attr("DiffAdd", "bg", "#1e332a")
  colors.del_fg = get_hl_attr("DiffDelete", "fg", "#f38ba8")
  colors.del_bg = get_hl_attr("DiffDelete", "bg", "#332a2e")
  colors.change_fg = get_hl_attr("DiffChange", "fg", "#89b4fa")
  colors.change_bg = get_hl_attr("DiffChange", "bg", "#2a2e33")
  colors.text_fg = get_hl_attr("Normal", "fg", "#cdd6f4")
  colors.text_bg = get_hl_attr("Normal", "bg", "#1e1e2e")
  colors.highlight_bg = get_hl_attr("CursorLine", "bg", "#313244")
  colors.cyan = get_hl_attr("Special", "fg", "#89dceb")
  
  return colors
end

-- Setup enhanced highlighting with focus on essential elements
function M.setup()
  -- Get theme-aware colors
  local colors = M.get_theme_colors()
  
  -- Define essential highlight groups for Avante
  -- Focused on the most important visual elements
  local highlights = {
    -- Core diff highlighting (essential)
    AvanteAddition = { fg = colors.add_fg, bg = colors.add_bg, bold = true },
    AvanteDeletion = { fg = colors.del_fg, bg = colors.del_bg, bold = true },
    AvanteModification = { fg = colors.change_fg, bg = colors.change_bg, bold = true },
    
    -- Cursor line indicator
    AvanteCursorLine = { bg = colors.highlight_bg, bold = true },
    
    -- Essential gutter indicators
    AvanteGutterAdd = { fg = colors.add_fg, bold = true },
    AvanteGutterDelete = { fg = colors.del_fg, bold = true },
    AvanteGutterChange = { fg = colors.change_fg, bold = true },
    
    -- Suggestion highlighting (essential for autocomplete)
    AvanteSuggestion = { fg = colors.cyan, bg = colors.text_bg, italic = true },
    AvanteSuggestionActive = { fg = colors.cyan, bg = colors.highlight_bg, bold = true },
    
    -- Status indicators (simplified)
    AvanteSuccess = { fg = colors.add_fg, bold = true },
    AvanteError = { fg = colors.del_fg, bold = true },
  }
  
  -- Apply highlight groups efficiently
  for name, attrs in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, attrs)
  end
  
  -- Setup minimal but effective gutter markers
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
  
  -- Setup streamlined autocommands
  local group = vim.api.nvim_create_augroup("AvanteHighlights", { clear = true })
  
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "Avante", "AvanteInput" },
    group = group,
    callback = function()
      -- Enable sign column for this buffer
      vim.opt_local.signcolumn = "yes:1"
      
      -- Update Avante's highlight groups
      M.update_avante_highlights()
    end,
  })
  
  -- Set up ColorScheme autocmd to update highlights when theme changes
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      -- Re-apply highlights based on new colorscheme
      local new_colors = M.get_theme_colors()
      M.apply_theme_aware_highlights(new_colors)
      -- Update Avante's highlight groups after a short delay
      vim.defer_fn(function()
        M.update_avante_highlights()
      end, 100)
    end
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

-- Apply highlight using current theme colors
-- Can be called with custom colors or will get them automatically
function M.apply_theme_aware_highlights(custom_colors)
  local colors = custom_colors or M.get_theme_colors()
  
  -- Update only the essential highlight groups
  vim.api.nvim_set_hl(0, "AvanteAddition", { fg = colors.add_fg, bg = colors.add_bg, bold = true })
  vim.api.nvim_set_hl(0, "AvanteDeletion", { fg = colors.del_fg, bg = colors.del_bg, bold = true })
  vim.api.nvim_set_hl(0, "AvanteModification", { fg = colors.change_fg, bg = colors.change_bg, bold = true })
  vim.api.nvim_set_hl(0, "AvanteCursorLine", { bg = colors.highlight_bg, bold = true })
  vim.api.nvim_set_hl(0, "AvanteGutterAdd", { fg = colors.add_fg, bold = true })
  vim.api.nvim_set_hl(0, "AvanteGutterDelete", { fg = colors.del_fg, bold = true })
  vim.api.nvim_set_hl(0, "AvanteGutterChange", { fg = colors.change_fg, bold = true })
  vim.api.nvim_set_hl(0, "AvanteSuggestion", { fg = colors.cyan, bg = colors.text_bg, italic = true })
  vim.api.nvim_set_hl(0, "AvanteSuggestionActive", { fg = colors.cyan, bg = colors.highlight_bg, bold = true })
  
  -- Return success status
  return true
end

-- Return the module
return M