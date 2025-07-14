#!/usr/bin/env lua
-- Script to fix draft filenames with scientific notation

local function fix_draft_filenames(drafts_dir)
  print("Checking for draft files with scientific notation in: " .. drafts_dir)
  
  -- Get all files in cur directory
  local cur_dir = drafts_dir .. "/cur"
  local handle = io.popen("ls -1 " .. cur_dir .. " 2>/dev/null")
  if not handle then
    print("Error: Could not read directory")
    return
  end
  
  local files_to_fix = {}
  for filename in handle:lines() do
    -- Check if filename contains scientific notation (e+)
    if filename:match("e%+") then
      table.insert(files_to_fix, filename)
    end
  end
  handle:close()
  
  if #files_to_fix == 0 then
    print("No files with scientific notation found.")
    return
  end
  
  print("Found " .. #files_to_fix .. " files to fix:")
  for _, filename in ipairs(files_to_fix) do
    print("  " .. filename)
  end
  
  print("\nFix these files? (y/n)")
  local answer = io.read()
  if answer ~= "y" and answer ~= "Y" then
    print("Aborted.")
    return
  end
  
  -- Fix each file
  for _, old_filename in ipairs(files_to_fix) do
    -- Parse the old filename
    -- Format: timestamp.scientificnotation_unique.hostname,info:2,flags
    local timestamp, sci_part, unique, hostname, info, flags = 
      old_filename:match("^(%d+)%.([%de%+%.]+)_([^%.]+)%.([^,]+),([^:]+):2,(.*)$")
    
    if timestamp then
      -- Generate a new unique identifier using current time
      local new_unique = math.floor(os.clock() * 1000000) % 1000000
      local new_filename = string.format(
        "%s.%d_%d.%s,%s:2,%s",
        timestamp,
        new_unique,
        os.getpid and os.getpid() or 1234,
        hostname,
        info,
        flags
      )
      
      local old_path = cur_dir .. "/" .. old_filename
      local new_path = cur_dir .. "/" .. new_filename
      
      print("Renaming:")
      print("  From: " .. old_filename)
      print("  To:   " .. new_filename)
      
      os.rename(old_path, new_path)
    else
      print("Warning: Could not parse filename: " .. old_filename)
    end
  end
  
  print("\nDone!")
end

-- Get drafts directory from command line or use default
local drafts_dir = arg[1] or os.getenv("HOME") .. "/Mail/Gmail/.Drafts"
fix_draft_filenames(drafts_dir)