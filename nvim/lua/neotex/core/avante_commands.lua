-- Avante Commands Module
-- This file contains commands for Avante AI assistant

local M = {}

-- Define the AvanteStop command
function M.setup_stop_command()
  vim.api.nvim_create_user_command("AvanteStop", function()
    -- Try direct access to the llm module first
    local ok, llm = pcall(require, "avante.llm")
    if ok and llm and type(llm.cancel_inflight_request) == "function" then
      llm.cancel_inflight_request()
      vim.notify("Stopped Avante generation", vim.log.levels.INFO)
      return
    end
    
    -- Fall back to the API module as a second attempt
    local ok_api, api = pcall(require, "avante.api")
    if ok_api and api and type(api.stop) == "function" then
      api.stop()
      vim.notify("Stopped Avante generation", vim.log.levels.INFO)
      return
    end
    
    -- If both approaches fail, notify the user
    vim.notify("Failed to stop Avante generation - model may still be running", vim.log.levels.WARN)
  end, { desc = "Stop Avante generation in progress" })
end

return M