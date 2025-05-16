-- Fix the MCPHub wrapper script for NixOS
local function fix_mcphub_wrapper()
  local wrapper_path = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/mcp-hub-wrapper")
  
  -- Check if the wrapper already exists
  if vim.fn.filereadable(wrapper_path) ~= 1 then
    vim.notify("MCP-Hub wrapper script not found at: " .. wrapper_path, vim.log.levels.ERROR)
    return
  end
  
  -- Create the improved wrapper script content
  local wrapper_content = [[#!/bin/bash
# MCP-Hub wrapper script for NixOS compatibility
# Fixed by Neovim config

# Path to the bundled MCP-Hub binary
MCPHUB_BINARY="/home/benjamin/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/node_modules/.bin/mcp-hub"
MCPHUB_JS="/home/benjamin/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/node_modules/mcp-hub/dist/cli.js"

# Environment setup for NixOS
export NODE_PATH="$(dirname "$MCPHUB_BINARY")/../.."
export PATH="$PATH:$(dirname "$MCPHUB_BINARY")"

# For debugging
echo "Starting MCP-Hub with node" > /tmp/mcphub-wrapper.log

# Check if node is available
if ! command -v node &> /dev/null; then
    echo "Error: node command not found" >> /tmp/mcphub-wrapper.log
    exit 127
fi

# Execute the binary with node explicitly
if [ -f "$MCPHUB_JS" ]; then
  # Print debug info
  echo "Using node: $(which node)" >> /tmp/mcphub-wrapper.log
  echo "Running: $MCPHUB_JS" >> /tmp/mcphub-wrapper.log
  echo "NODE_PATH: $NODE_PATH" >> /tmp/mcphub-wrapper.log
  
  # Run with node explicitly
  exec node "$MCPHUB_JS" "$@"
else
  echo "Error: MCP-Hub script not found at $MCPHUB_JS" >> /tmp/mcphub-wrapper.log
  exit 1
fi
]]
  
  -- Write the wrapper script
  local file = io.open(wrapper_path, "w")
  if file then
    file:write(wrapper_content)
    file:close()
    
    -- Make it executable
    vim.fn.system("chmod +x " .. wrapper_path)
    vim.notify("Fixed MCP-Hub wrapper script at: " .. wrapper_path, vim.log.levels.INFO)
  else
    vim.notify("Failed to update wrapper script at: " .. wrapper_path, vim.log.levels.ERROR)
  end
end

-- Execute the function
fix_mcphub_wrapper()