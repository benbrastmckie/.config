-- Create the mcp-hub-wrapper script for NixOS compatibility
local function create_mcphub_wrapper()
  local plugin_dir = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim")
  local bundled_dir = plugin_dir .. "/bundled/mcp-hub"
  local wrapper_path = bundled_dir .. "/mcp-hub-wrapper"
  local binary_path = bundled_dir .. "/node_modules/.bin/mcp-hub"
  
  -- Check if the wrapper already exists
  if vim.fn.filereadable(wrapper_path) == 1 then
    vim.notify("MCP-Hub wrapper script already exists at: " .. wrapper_path, vim.log.levels.INFO)
    return
  end
  
  -- Check if the binary exists
  if vim.fn.filereadable(binary_path) ~= 1 then
    vim.notify("MCP-Hub binary not found at: " .. binary_path, vim.log.levels.ERROR)
    return
  end
  
  -- Create the wrapper script content
  local wrapper_content = [[#!/bin/bash
# MCP-Hub wrapper script for NixOS compatibility
# Automatically created by Neovim config

# Path to the bundled MCP-Hub binary
MCPHUB_BINARY="]] .. binary_path .. [["

# Environment setup for NixOS
export NODE_PATH="$(dirname "$MCPHUB_BINARY")/../.."
export PATH="$PATH:$(dirname "$MCPHUB_BINARY")"

# Execute the binary with all arguments passed to this script
if [ -x "$MCPHUB_BINARY" ]; then
  exec "$MCPHUB_BINARY" "$@"
else
  echo "Error: MCP-Hub binary not found or not executable at $MCPHUB_BINARY"
  exit 1
fi
]]
  
  -- Create the directories if they don't exist
  if vim.fn.isdirectory(bundled_dir) == 0 then
    vim.fn.mkdir(bundled_dir, "p")
  end
  
  -- Write the wrapper script
  local file = io.open(wrapper_path, "w")
  if file then
    file:write(wrapper_content)
    file:close()
    
    -- Make it executable
    vim.fn.system("chmod +x " .. wrapper_path)
    vim.notify("Created MCP-Hub wrapper script at: " .. wrapper_path, vim.log.levels.INFO)
  else
    vim.notify("Failed to create wrapper script at: " .. wrapper_path, vim.log.levels.ERROR)
  end
end

-- Execute the function
create_mcphub_wrapper()