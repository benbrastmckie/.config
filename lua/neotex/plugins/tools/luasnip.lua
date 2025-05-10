return {
  "L3MON4D3/LuaSnip",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    -- Attempt to load jsregexp directly first
    local status = pcall(require, "jsregexp")
    
    -- If direct loading fails, try to find it in Nix store (for NixOS)
    if not status and vim.fn.has("unix") == 1 then
      local jsregexp_paths = vim.fn.glob("/nix/store/*-jsregexp-*/share/lua/5.1", false, true)
      if #jsregexp_paths > 0 then
        -- Add the first found path to package.path
        package.path = package.path .. ";" .. jsregexp_paths[1] .. "/?.lua"
        -- Also add the corresponding .so path
        local so_path = vim.fn.fnamemodify(jsregexp_paths[1], ":h:h") .. "/lib/lua/5.1/?.so"
        package.cpath = package.cpath .. ";" .. so_path
      end
    end
    
    -- Load snippets
    require("luasnip.loaders.from_snipmate").load({ paths = "~/.config/nvim/snippets/" })
  end
}