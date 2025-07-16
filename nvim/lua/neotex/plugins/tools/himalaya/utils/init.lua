-- Himalaya Utils Module
-- Provides backward compatibility and unified exports

local M = {}

-- Load sub-modules
local string_utils = require('neotex.plugins.tools.himalaya.utils.string')
local email_utils = require('neotex.plugins.tools.himalaya.utils.email')
local cli_utils = require('neotex.plugins.tools.himalaya.utils.cli')
local file_utils = require('neotex.plugins.tools.himalaya.utils.file')
local async_utils = require('neotex.plugins.tools.himalaya.utils.async')

-- Export sub-modules for direct access
M.string = string_utils
M.email = email_utils
M.cli = cli_utils
M.file = file_utils
M.async = async_utils

-- ========================================
-- Backward Compatibility Wrappers
-- These ensure existing code continues to work
-- ========================================

-- String utilities (backward compatibility)
M.truncate_string = string_utils.truncate_string
M.format_date = string_utils.format_date
M.format_from = string_utils.format_from
M.format_size = string_utils.format_size

-- Email utilities (backward compatibility)
M.format_flags = email_utils.format_flags
M.format_email_for_sending = email_utils.format_email_for_sending
M.parse_email_content = email_utils.parse_email_content
M.validate = email_utils

-- CLI utilities (backward compatibility)
M.execute_himalaya = cli_utils.execute_himalaya

-- Async utilities (backward compatibility) 
M.fn = async_utils
M.perf = {
  measure = async_utils.async,
  benchmark = function(fn, iterations)
    iterations = iterations or 100
    local times = {}
    
    for i = 1, iterations do
      local start = vim.loop.hrtime()
      fn()
      local duration = (vim.loop.hrtime() - start) / 1000000
      table.insert(times, duration)
    end
    
    table.sort(times)
    local sum = 0
    for _, time in ipairs(times) do
      sum = sum + time
    end
    
    return {
      min = times[1],
      max = times[#times],
      avg = sum / iterations,
      median = times[math.floor(#times / 2)],
      iterations = iterations
    }
  end
}

-- Table utilities (for backward compatibility)
M.table = {
  deep_merge = function(t1, t2)
    local result = vim.deepcopy(t1)
    
    for k, v in pairs(t2) do
      if type(v) == "table" and type(result[k]) == "table" then
        result[k] = M.table.deep_merge(result[k], v)
      else
        result[k] = v
      end
    end
    
    return result
  end,
  
  filter = function(tbl, predicate)
    local result = {}
    
    for k, v in pairs(tbl) do
      if predicate(v, k) then
        result[k] = v
      end
    end
    
    return result
  end,
  
  map = function(tbl, mapper)
    local result = {}
    
    for k, v in pairs(tbl) do
      result[k] = mapper(v, k)
    end
    
    return result
  end,
  
  group_by = function(tbl, key_fn)
    local result = {}
    
    for _, item in ipairs(tbl) do
      local key = key_fn(item)
      result[key] = result[key] or {}
      table.insert(result[key], item)
    end
    
    return result
  end
}

return M