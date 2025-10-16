# Reply to Jupytext.nvim Issue

I've investigated this issue and found the root causes. Here's what's happening and how to fix it:

## The Problem

You're encountering two separate issues related to Neovim API changes:

### 1. Health Check Error
```
ERROR Failed to run healthcheck for "jupytext" plugin. Exception:
...al/share/nvim/lazy/jupytext.nvim/lua/jupytext/health.lua:4: attempt to call field 'report_start' (a nil value)
```

This occurs because the plugin uses the old Neovim health check API. In Neovim 0.10+, the health check API changed from:
- `vim.health.report_start()` ? `vim.health.start()`
- `vim.health.report_ok()` ? `vim.health.ok()`
- `vim.health.report_error()` ? `vim.health.error()`

### 2. Notebook Reading Error
```
Error executing lua callback: ...cal/share/nvim/lazy/jupytext.nvim/lua/jupytext/utils.lua:16: attempt to index a nil value
```

This happens because the `get_ipynb_metadata` function doesn't handle:
- File reading failures
- Invalid JSON content
- Missing metadata fields

## The Solution

If you're using the latest version of jupytext.nvim from the repository, these issues should now be fixed. Make sure to update your plugin:

```vim
:Lazy sync
```

Or if using another plugin manager, update jupytext.nvim to the latest version.

## Temporary Workaround

If you're still experiencing issues after updating, you can apply this temporary patch by creating a file at `~/.config/nvim/after/plugin/jupytext_patches.lua`:

```lua
-- Patches for jupytext.nvim to work with Neovim 0.10+
local ok, _ = pcall(require, "jupytext")
if not ok then
  return
end

-- Patch the health check module
package.loaded["jupytext.health"] = nil
local health_module = {}

health_module.check = function()
  local health = vim.health or require("health")
  health.start("jupytext.nvim")
  
  local result = vim.fn.system("jupytext --version")
  
  if vim.v.shell_error == 0 then
    health.ok("Jupytext is available: " .. vim.trim(result))
  else
    health.error("Jupytext is not available", { "Install jupytext via `pip install jupytext`" })
  end
end

package.preload["jupytext.health"] = function()
  return health_module
end

-- Patch the utils module for better error handling
package.loaded["jupytext.utils"] = nil
local utils_module = {}

local language_extensions = {
  python = "py",
  julia = "jl",
  r = "r",
  R = "r",
  bash = "sh",
}

local language_names = {
  python3 = "python",
}

utils_module.get_ipynb_metadata = function(filename)
  local file = io.open(filename, "r")
  if not file then
    vim.notify("Could not open notebook file: " .. filename, vim.log.levels.ERROR)
    return { language = "python", extension = "py" }
  end
  
  local content = file:read("a")
  file:close()
  
  local ok, data = pcall(vim.json.decode, content)
  if not ok or not data or not data.metadata then
    return { language = "python", extension = "py" }
  end
  
  local language = nil
  if data.metadata.kernelspec then
    language = data.metadata.kernelspec.language or language_names[data.metadata.kernelspec.name]
  end
  
  language = language or "python"
  local extension = language_extensions[language] or "txt"
  
  return { language = language, extension = extension }
end

utils_module.get_jupytext_file = function(filename, extension)
  local fileroot = vim.fn.fnamemodify(filename, ":r")
  return fileroot .. "." .. extension
end

utils_module.check_key = function(tbl, key)
  for tbl_key, _ in pairs(tbl) do
    if tbl_key == key then
      return true
    end
  end
  return false
end

package.preload["jupytext.utils"] = function()
  return utils_module
end
```

## What Changed in the Fix

The maintainers have updated the plugin to:

1. **Use the new Neovim 0.10+ health check API**
   - Changed `vim.health.report_start` to `vim.health.start`
   - Changed `vim.health.report_ok` to `vim.health.ok`
   - Changed `vim.health.report_error` to `vim.health.error`

2. **Add proper error handling in `get_ipynb_metadata`**
   - Safe file opening with error checking
   - Proper JSON parsing with error handling
   - Fallback values when metadata is missing
   - Better handling of missing kernelspec information

## Verification

After updating or applying the patch, you should be able to:
1. Run `:checkhealth jupytext` without errors
2. Open `.ipynb` files without the Lua callback error
3. See proper error messages if a notebook file is corrupted or missing metadata

Let me know if you continue to experience issues after updating.
