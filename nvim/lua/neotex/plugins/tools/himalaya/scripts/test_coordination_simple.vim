" Simple test script for Phase 4 coordination
" Run with: nvim -u NONE -S test_coordination_simple.vim

" Source minimal init
set runtimepath+=/home/benjamin/.config/nvim

" Test the coordination module
lua << EOF
-- Add paths
package.path = package.path .. ";/home/benjamin/.config/nvim/lua/?.lua"

-- Simple test function
local function test_coordination()
  print("Testing Phase 4: Multi-Instance Coordination")
  print("=" .. string.rep("=", 50))
  
  -- Load coordinator
  local ok, coordinator = pcall(require, 'neotex.plugins.tools.himalaya.sync.coordinator')
  if not ok then
    print("❌ Failed to load coordinator: " .. tostring(coordinator))
    return
  end
  
  print("✅ Coordinator module loaded successfully")
  
  -- Test basic properties
  print("\nChecking coordinator properties:")
  print("  - Coordination file: " .. coordinator.config.coordination_file)
  print("  - Heartbeat interval: " .. coordinator.config.heartbeat_interval .. "s")
  print("  - Takeover threshold: " .. coordinator.config.takeover_threshold .. "s")
  print("  - Sync cooldown: " .. coordinator.config.sync_cooldown .. "s")
  
  -- Test initialization
  print("\nTesting initialization...")
  local ok2, err = pcall(coordinator.init)
  if ok2 then
    print("✅ Coordinator initialized successfully")
    print("  - Instance ID: " .. (coordinator.instance_id or "nil"))
    print("  - Is Primary: " .. tostring(coordinator.is_primary))
  else
    print("❌ Initialization failed: " .. tostring(err))
  end
  
  -- Test coordination file operations
  print("\nTesting coordination file operations...")
  local ok3, data = pcall(coordinator.read_coordination_file)
  if ok3 then
    print("✅ Read coordination file successfully")
    if data.primary then
      print("  - Primary exists: " .. data.primary.instance_id)
    else
      print("  - No primary coordinator")
    end
    if data.last_sync_time then
      print("  - Last sync: " .. (os.time() - data.last_sync_time) .. " seconds ago")
    end
  else
    print("❌ Failed to read coordination file: " .. tostring(data))
  end
  
  -- Test sync permission
  print("\nTesting sync permission...")
  local should_sync = coordinator.should_allow_sync()
  print("  - Should allow sync: " .. tostring(should_sync))
  
  -- Cleanup
  coordinator.cleanup()
  print("\n✅ Phase 4 coordination tests completed!")
end

-- Run test
test_coordination()
EOF

" Exit
quit!