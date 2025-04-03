return {
  "ravitemer/mcphub.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",   -- Required for Job and HTTP requests
  },
  cmd = "MCPHub",                            -- lazy load by default
  build = function()
    -- Custom build function for NixOS using uvx
    local Job = require("plenary.job")
    Job:new({
      command = "uvx",
      args = {"install", "mcp-hub"},
      on_exit = function(j, return_val)
        if return_val == 0 then
          print("Successfully installed mcp-hub with uvx")
        else
          print("Failed to install mcp-hub with uvx")
          print(table.concat(j:stderr_result(), "\n"))
        end
      end,
    }):sync()
  end,
  config = function()
    require("mcphub").setup({
      use_bundled_binary = false,            -- Don't use bundled binary for NixOS
      cmd = "uvx",                           -- Use uvx to run mcp-hub
      cmdArgs = {"run", "mcp-hub"},          -- Arguments to pass to uvx
      debug = true,                          -- Enable debug logging to help troubleshoot
    })
  end,
}
