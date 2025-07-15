-- Mock Data for Himalaya Tests
-- Provides realistic test data for various scenarios

local M = {}

-- Sample email addresses
M.email_addresses = {
  personal = {
    "john.doe@gmail.com",
    "jane.smith@yahoo.com",
    "bob.wilson@outlook.com",
    "alice.johnson@proton.me"
  },
  work = {
    "michael.brown@company.com",
    "sarah.davis@enterprise.org",
    "david.miller@startup.io",
    "emma.taylor@business.net"
  },
  automated = {
    "noreply@github.com",
    "notifications@linkedin.com",
    "alerts@monitoring.service",
    "system@automated.com"
  }
}

-- Sample subject lines
M.subjects = {
  personal = {
    "Re: Weekend plans",
    "Happy Birthday!",
    "Photos from the trip",
    "Quick question about tomorrow"
  },
  work = {
    "Q4 Budget Review - Action Required",
    "Meeting Minutes: Product Roadmap",
    "Re: Project Alpha Status Update",
    "[URGENT] Server Maintenance Tonight"
  },
  newsletters = {
    "Your Weekly Tech Digest",
    "New features in v2.0",
    "Special offer ends soon!",
    "Industry News Roundup"
  }
}

-- Sample email bodies
M.bodies = {
  short = {
    "Thanks for the update!",
    "Sounds good to me.",
    "Let me know if you need anything else.",
    "Looking forward to it!"
  },
  medium = {
    [[Hi team,

Just wanted to give a quick update on the project status. We've completed the initial phase and are moving into testing.

Everything is on track for the deadline.

Best regards]],
    [[Hello,

I've reviewed the proposal and have a few questions:
1. What's the timeline for implementation?
2. Do we have budget approval?
3. Who will be the project lead?

Please let me know your thoughts.

Thanks]],
  },
  long = {
    [[Dear colleagues,

I hope this email finds you well. I wanted to take a moment to share some important updates regarding our upcoming initiatives.

First, I'd like to congratulate everyone on the successful completion of Project Alpha. The team's dedication and hard work have been truly exceptional, and the results speak for themselves. We've exceeded our targets by 15% and received outstanding feedback from stakeholders.

Moving forward, we have several key priorities:

1. **Q4 Planning**: We need to finalize our objectives for the final quarter. Please review the draft document shared earlier and provide your input by Friday.

2. **Resource Allocation**: Based on current projections, we may need to adjust our resource allocation. Department heads, please prepare updated requirements.

3. **Training Initiative**: The new system rollout is scheduled for next month. Mandatory training sessions will begin next week. Please check the calendar for your assigned slot.

4. **Holiday Schedule**: Remember to submit your holiday requests for December by the end of this week.

I'd also like to remind everyone about our team building event next Thursday. It's a great opportunity to celebrate our achievements and strengthen our collaboration.

If you have any questions or concerns, please don't hesitate to reach out.

Best regards,
Management Team]]
  }
}

-- Generate random email
function M.generate_email(options)
  options = options or {}
  
  local email_type = options.type or "personal"
  local from_addresses = M.email_addresses[email_type] or M.email_addresses.personal
  local subjects = M.subjects[email_type] or M.subjects.personal
  local body_length = options.body_length or "medium"
  local bodies = M.bodies[body_length] or M.bodies.medium
  
  -- Random selections
  local from = from_addresses[math.random(#from_addresses)]
  local subject = subjects[math.random(#subjects)]
  local body = bodies[math.random(#bodies)]
  
  -- Generate email
  local email = {
    id = "mock-" .. os.time() .. "-" .. math.random(1000),
    from = {
      email = from,
      name = from:match("([^@]+)"):gsub("%.", " "):gsub("^%l", string.upper)
    },
    to = options.to or { { 
      email = "user@example.com", 
      name = "Test User" 
    } },
    subject = subject,
    body = body,
    date = options.date or os.date("%Y-%m-%d %H:%M:%S"),
    folder = options.folder or "INBOX",
    flags = {
      read = options.read or false,
      flagged = options.flagged or false,
      answered = options.answered or false
    }
  }
  
  -- Add optional fields
  if options.cc then
    email.cc = options.cc
  end
  
  if options.attachments then
    email.attachments = options.attachments
  end
  
  if options.headers then
    email.headers = options.headers
  end
  
  return email
end

-- Generate email thread
function M.generate_thread(subject, count)
  count = count or 3
  local thread = {}
  local base_time = os.time() - (count * 3600)
  
  for i = 1, count do
    local is_reply = i > 1
    local email = M.generate_email({
      subject = is_reply and ("Re: " .. subject) or subject,
      date = os.date("%Y-%m-%d %H:%M:%S", base_time + (i * 3600)),
      read = i < count,
      answered = i < count
    })
    
    table.insert(thread, email)
  end
  
  return thread
end

-- Generate attachment
function M.generate_attachment(type)
  local attachments = {
    document = {
      filename = "report.pdf",
      mimetype = "application/pdf",
      size = 524288
    },
    image = {
      filename = "photo.jpg",
      mimetype = "image/jpeg",
      size = 2097152
    },
    spreadsheet = {
      filename = "data.xlsx",
      mimetype = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      size = 102400
    },
    text = {
      filename = "notes.txt",
      mimetype = "text/plain",
      size = 4096
    }
  }
  
  return attachments[type] or attachments.document
end

-- Generate folder structure
function M.generate_folders()
  return {
    {
      name = "INBOX",
      path = "INBOX",
      delimiter = ".",
      attributes = { "\\HasNoChildren" },
      message_count = math.random(50, 200)
    },
    {
      name = "Sent",
      path = "INBOX.Sent",
      delimiter = ".",
      attributes = { "\\Sent", "\\HasNoChildren" },
      message_count = math.random(20, 100)
    },
    {
      name = "Drafts",
      path = "INBOX.Drafts",
      delimiter = ".",
      attributes = { "\\Drafts", "\\HasNoChildren" },
      message_count = math.random(0, 10)
    },
    {
      name = "Trash",
      path = "INBOX.Trash",
      delimiter = ".",
      attributes = { "\\Trash", "\\HasNoChildren" },
      message_count = math.random(0, 50)
    },
    {
      name = "Archive",
      path = "INBOX.Archive",
      delimiter = ".",
      attributes = { "\\Archive", "\\HasNoChildren" },
      message_count = math.random(100, 1000)
    }
  }
end

-- Generate account configuration
function M.generate_account(name, type)
  local accounts = {
    gmail = {
      name = name or "Personal Gmail",
      email = "user@gmail.com",
      imap = {
        host = "imap.gmail.com",
        port = 993,
        ssl = true
      },
      smtp = {
        host = "smtp.gmail.com",
        port = 587,
        starttls = true
      },
      auth = "oauth2",
      maildir_path = "~/Mail/gmail"
    },
    outlook = {
      name = name or "Work Outlook",
      email = "user@company.com",
      imap = {
        host = "outlook.office365.com",
        port = 993,
        ssl = true
      },
      smtp = {
        host = "smtp.office365.com",
        port = 587,
        starttls = true
      },
      auth = "password",
      maildir_path = "~/Mail/outlook"
    }
  }
  
  return accounts[type] or accounts.gmail
end

return M