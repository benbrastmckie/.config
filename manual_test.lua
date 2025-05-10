-- Manually set up utility modules and test command registration
print("Manually initializing utility modules...")

-- Load neotex.utils and call setup explicitly
local utils = require("neotex.utils")
if type(utils) == "table" and utils.setup then
  print("Calling utils.setup()...")
  utils.setup()
end

-- Test if the buffer utility module has been set up properly
local buffer = require("neotex.utils.buffer")
if type(buffer) == "table" and buffer.setup then
  print("Calling buffer.setup()...")
  buffer.setup()
end

-- Test if the misc utility module has been set up properly
local misc = require("neotex.utils.misc")
if type(misc) == "table" and misc.setup then
  print("Calling misc.setup()...")
  misc.setup()
end

-- Now check if commands were created
local function command_exists(cmd_name)
  local ok = pcall(vim.api.nvim_get_commands, {}, { [cmd_name] = true })
  return ok
end

-- Sleep briefly to allow commands to register
vim.cmd("sleep 1000m")

print("\nAfter manual initialization:")
print("ReloadConfig command exists: " .. tostring(command_exists("ReloadConfig")))
print("BufCloseOthers command exists: " .. tostring(command_exists("BufCloseOthers")))
print("TrimWhitespace command exists: " .. tostring(command_exists("TrimWhitespace")))
print("ToggleLineNumbers command exists: " .. tostring(command_exists("ToggleLineNumbers")))