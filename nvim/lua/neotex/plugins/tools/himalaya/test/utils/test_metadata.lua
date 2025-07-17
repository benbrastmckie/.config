local M = {}

-- Validate test metadata structure
M.validate_metadata = function(metadata)
  local required_fields = {"name", "count", "category"}
  for _, field in ipairs(required_fields) do
    if not metadata[field] then
      error(string.format("Missing required field: %s", field))
    end
  end
  
  if type(metadata.count) ~= "number" or metadata.count < 0 then
    error("count must be a non-negative number")
  end
  
  local valid_categories = {"unit", "feature", "integration", "command", "performance"}
  if not vim.tbl_contains(valid_categories, metadata.category) then
    error(string.format("Invalid category: %s", metadata.category))
  end
  
  return true
end

-- Create standardized test interface
M.create_test_interface = function(metadata, test_functions)
  M.validate_metadata(metadata)
  
  return {
    test_metadata = metadata,
    get_test_count = function() return metadata.count end,
    get_test_list = function()
      local names = {}
      for name, _ in pairs(test_functions) do
        table.insert(names, name:gsub("^test_", ""):gsub("_", " "))
      end
      return names
    end,
    run = function()
      -- Execute tests and return standardized results
      local results = {
        total = metadata.count,
        passed = 0,
        failed = 0,
        errors = {},
        success = false,
        details = {}
      }
      
      for name, func in pairs(test_functions) do
        local ok, err = pcall(func)
        if ok then
          results.passed = results.passed + 1
        else
          results.failed = results.failed + 1
          table.insert(results.errors, {
            test = name,
            error = tostring(err)
          })
        end
      end
      
      results.success = results.failed == 0
      return results
    end
  }
end

return M