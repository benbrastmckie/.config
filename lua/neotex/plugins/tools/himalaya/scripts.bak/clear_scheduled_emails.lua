-- Clear all scheduled emails
-- Run this to clean up after failed tests

local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
local persistence = require('neotex.plugins.tools.himalaya.core.persistence')

-- Stop scheduler
if scheduler.timer then
  scheduler.stop_processing()
end

-- Clear queue
scheduler.queue = {}

-- Save empty queue to disk
persistence.save_queue({})

print("Cleared all scheduled emails")