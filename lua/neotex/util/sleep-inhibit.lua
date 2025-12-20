-- Sleep Inhibitor for Neovim
--
-- Prevents system sleep and idle suspension during active editing sessions
-- using systemd-inhibit. Provides manual control and automatic cleanup on exit.

local M = {}

-- Module state
M._state = {
  inhibit_job_id = nil,
  is_active = false,
}

-- Constants
local INHIBIT_COMMAND = {
  "systemd-inhibit",
  "--what=sleep:idle",
  "--who=Neovim",
  "--why=Preventing sleep during editing",
  "--mode=block",
  "sleep", "infinity"
}

--- Enable sleep inhibitor
---
--- Starts a background systemd-inhibit process to prevent system sleep
--- and idle suspension. Only one inhibitor can be active at a time.
---
---@return boolean success True if inhibitor started successfully
function M.enable()
  -- Check if already active
  if M._state.is_active then
    vim.notify(
      "Sleep inhibitor already active",
      vim.log.levels.INFO
    )
    return true
  end

  -- Check if systemd-inhibit is available
  if vim.fn.executable("systemd-inhibit") == 0 then
    vim.notify(
      "systemd-inhibit not found - sleep inhibitor unavailable",
      vim.log.levels.ERROR
    )
    return false
  end

  -- Start inhibitor process
  local job_id = vim.fn.jobstart(INHIBIT_COMMAND, {
    on_exit = function(_, exit_code, _)
      if exit_code ~= 0 and M._state.is_active then
        vim.notify(
          string.format("Sleep inhibitor exited unexpectedly (code: %d)", exit_code),
          vim.log.levels.WARN
        )
        M._state.is_active = false
        M._state.inhibit_job_id = nil
      end
    end,
    on_stderr = function(_, data, _)
      if data and #data > 0 then
        local error_msg = table.concat(data, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
        if error_msg ~= "" then
          vim.notify(
            string.format("Sleep inhibitor error: %s", error_msg),
            vim.log.levels.ERROR
          )
        end
      end
    end,
  })

  -- Check if job started successfully
  if job_id <= 0 then
    vim.notify(
      "Failed to start sleep inhibitor process",
      vim.log.levels.ERROR
    )
    return false
  end

  -- Update state
  M._state.inhibit_job_id = job_id
  M._state.is_active = true

  vim.notify(
    "Sleep inhibitor enabled",
    vim.log.levels.INFO
  )

  return true
end

--- Disable sleep inhibitor
---
--- Stops the background systemd-inhibit process and allows normal
--- system sleep and idle suspension behavior.
---
---@return boolean success True if inhibitor stopped successfully
function M.disable()
  -- Check if active
  if not M._state.is_active then
    vim.notify(
      "Sleep inhibitor not active",
      vim.log.levels.INFO
    )
    return true
  end

  -- Stop the job
  if M._state.inhibit_job_id then
    local ok = pcall(vim.fn.jobstop, M._state.inhibit_job_id)
    if not ok then
      vim.notify(
        "Failed to stop sleep inhibitor process",
        vim.log.levels.WARN
      )
      -- Reset state anyway since job may be dead
      M._state.inhibit_job_id = nil
      M._state.is_active = false
      return false
    end
  end

  -- Update state
  M._state.inhibit_job_id = nil
  M._state.is_active = false

  vim.notify(
    "Sleep inhibitor disabled",
    vim.log.levels.INFO
  )

  return true
end

--- Toggle sleep inhibitor on/off
---
--- Convenience function to enable or disable the inhibitor based on
--- current state.
---
---@return boolean success True if toggle operation succeeded
function M.toggle()
  if M._state.is_active then
    return M.disable()
  else
    return M.enable()
  end
end

--- Get current inhibitor status
---
--- Returns information about the current state of the sleep inhibitor.
---
---@return table status Status information with fields: active (boolean), job_id (number|nil)
function M.status()
  return {
    active = M._state.is_active,
    job_id = M._state.inhibit_job_id,
  }
end

--- Show status message
---
--- Displays a notification with the current inhibitor status.
function M.show_status()
  local status = M.status()
  local status_msg = status.active
    and string.format("Sleep inhibitor: ACTIVE (job %d)", status.job_id)
    or "Sleep inhibitor: INACTIVE"

  vim.notify(status_msg, vim.log.levels.INFO)
end

--- Setup function for module initialization
---
--- Creates autocommands for automatic cleanup on Neovim exit.
---
---@param opts table|nil Optional configuration (reserved for future use)
function M.setup(opts)
  opts = opts or {}

  -- Create augroup for cleanup
  local augroup = vim.api.nvim_create_augroup("SleepInhibitor", { clear = true })

  -- Ensure inhibitor is stopped on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
      if M._state.is_active then
        -- Silent cleanup on exit (no notifications)
        if M._state.inhibit_job_id then
          pcall(vim.fn.jobstop, M._state.inhibit_job_id)
        end
        M._state.inhibit_job_id = nil
        M._state.is_active = false
      end
    end,
    desc = "Cleanup sleep inhibitor on Neovim exit",
  })
end

return M
