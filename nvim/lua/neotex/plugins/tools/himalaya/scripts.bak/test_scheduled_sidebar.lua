-- Test script for scheduled email sidebar integration
-- Tests Phase 2.1 and 2.2 implementation

local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
local state = require('neotex.plugins.tools.himalaya.core.state')

print("Testing scheduled email sidebar integration...")

-- Initialize scheduler
scheduler.setup()

-- Create some test scheduled emails
local test_emails = {
  {
    email_data = {
      to = "john@example.com",
      subject = "Weekly report",
      body = "Here's the weekly report..."
    },
    delay = 60  -- 1 minute
  },
  {
    email_data = {
      to = "team@company.com",
      subject = "Meeting follow-up notes from today",
      body = "Thanks for attending..."
    },
    delay = 300  -- 5 minutes
  },
  {
    email_data = {
      to = "client@external.com",
      subject = "Project proposal v2",
      body = "Please find attached..."
    },
    delay = 1800  -- 30 minutes
  }
}

-- Schedule the test emails
print("\nScheduling test emails...")
for i, test in ipairs(test_emails) do
  local id = scheduler.schedule_email(test.email_data, "gmail", { delay = test.delay })
  print(string.format("  Scheduled email %d: %s (ID: %s)", i, test.email_data.subject, id))
end

-- Get scheduled emails
print("\nRetrieving scheduled emails...")
local scheduled = scheduler.get_scheduled_emails()
print(string.format("  Found %d scheduled emails", #scheduled))

-- Test countdown formatting
print("\nTesting countdown formatting...")
local test_times = {0, 30, 59, 60, 120, 3599, 3600, 7200}
for _, seconds in ipairs(test_times) do
  local formatted = scheduler.format_countdown(seconds)
  print(string.format("  %d seconds -> '%s'", seconds, formatted))
end

-- Open email sidebar to see scheduled emails
print("\nOpening email sidebar with scheduled emails...")
print("Run :HimalayaShowEmails to see the scheduled emails in the sidebar")
print("The countdown timers should update every second")

-- Show current queue status
local status = scheduler.get_queue_status()
print("\nQueue status:")
print(string.format("  Total: %d", status.total))
print(string.format("  Scheduled: %d", status.scheduled))
print(string.format("  Sent: %d", status.sent))

print("\nTest complete! Use :HimalayaShowEmails to see the sidebar with scheduled emails.")