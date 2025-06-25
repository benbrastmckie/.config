-- Test script to verify progress updates stop immediately

local sync_completed = false

-- Simulate the sync completion
local function simulate_sync()
  print("Sync started...")
  
  -- Simulate progress checks
  local check_count = 0
  local function schedule_next_check()
    vim.defer_fn(function()
      if not sync_completed then
        check_count = check_count + 1
        print("Progress update " .. check_count .. " (sync still running)")
        schedule_next_check()
      else
        print("Progress updates stopped - sync completed!")
      end
    end, 1000) -- 1 second for testing
  end
  
  -- Start progress after 2 seconds
  vim.defer_fn(function()
    if not sync_completed then
      schedule_next_check()
    end
  end, 2000)
  
  -- Simulate sync completion after 4 seconds
  vim.defer_fn(function()
    sync_completed = true
    print("Sync completed! (progress should stop now)")
  end, 4000)
end

simulate_sync()