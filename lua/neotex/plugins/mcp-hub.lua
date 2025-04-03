return {
  "ravitemer/mcphub.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",   -- Required for Job and HTTP requests
  },
  cmd = "MCPHub",                            -- lazy load by default
  build = "bundled_build.lua",               -- Use bundled approach for NixOS
  config = function()
    require("mcphub").setup({
      use_bundled_binary = true,             -- Use the bundled binary for NixOS
      debug = true,                          -- Enable debug logging to help troubleshoot
    })
  end,
}
