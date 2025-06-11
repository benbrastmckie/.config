-- Debug citation completion
print("=== Citation Completion Debug ===")

-- Check if VimTeX is loaded
print("VimTeX loaded:", vim.g.loaded_vimtex)

-- Check if cmp_vimtex is available
local cmp_vimtex_ok, cmp_vimtex = pcall(require, 'cmp_vimtex')
print("cmp_vimtex available:", cmp_vimtex_ok)

-- Check if blink.compat is working
local compat_ok, compat = pcall(require, 'blink.compat')
print("blink.compat available:", compat_ok)

-- Check if blink.cmp sources are configured
local blink_ok, blink = pcall(require, 'blink.cmp')
if blink_ok then
  print("blink.cmp loaded successfully")

  -- Try to get the current configuration
  local config_ok, config = pcall(function()
    return require('blink.cmp.config')
  end)

  if config_ok then
    print("blink.cmp config available")
    -- Check if vimtex source is in the providers
    if config.sources and config.sources.providers then
      print("vimtex provider configured:", config.sources.providers.vimtex ~= nil)
    end
  end
end

-- Check current filetype
print("Current filetype:", vim.bo.filetype)

-- Check if we're in a tex file context
if vim.bo.filetype == "tex" then
  print("In LaTeX file - checking VimTeX functionality")

  -- Check if VimTeX provides completion function
  if vim.fn.exists('*vimtex#complete#omnifunc') == 1 then
    print("VimTeX omnifunc available")
  else
    print("VimTeX omnifunc NOT available")
  end
end

print("=== End Debug ===")

