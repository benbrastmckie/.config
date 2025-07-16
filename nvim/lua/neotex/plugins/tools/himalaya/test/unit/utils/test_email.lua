-- Unit tests for email utilities

local test_framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')
local assert = test_framework.assert
local email_utils = require('neotex.plugins.tools.himalaya.utils.email')

local M = {}

function M.test_format_flags()
  -- Test all flags
  local flags = {
    seen = true,
    answered = true,
    flagged = true,
    draft = true
  }
  assert.equals(
    email_utils.format_flags(flags),
    'RA*D',
    'Should format all flags correctly'
  )
  
  -- Test no flags
  flags = {
    seen = false,
    answered = false,
    flagged = false,
    draft = false
  }
  assert.equals(
    email_utils.format_flags(flags),
    '    ',
    'Should show spaces for no flags'
  )
  
  -- Test nil flags
  assert.equals(
    email_utils.format_flags(nil),
    '  ',
    'Should handle nil flags'
  )
  
  -- Test partial flags
  flags = { seen = true, flagged = true }
  assert.equals(
    email_utils.format_flags(flags),
    'R * ',
    'Should format partial flags'
  )
end

function M.test_validate_email()
  -- Valid emails
  assert.truthy(
    email_utils.validate_email('test@example.com'),
    'Should validate simple email'
  )
  
  assert.truthy(
    email_utils.validate_email('user.name+tag@example.co.uk'),
    'Should validate complex email'
  )
  
  -- Invalid emails
  assert.falsy(
    email_utils.validate_email('invalid'),
    'Should reject invalid email'
  )
  
  assert.falsy(
    email_utils.validate_email('missing@domain'),
    'Should reject email without TLD'
  )
  
  assert.falsy(
    email_utils.validate_email(nil),
    'Should reject nil'
  )
end

function M.test_extract_emails()
  -- Single email
  local emails = email_utils.extract_emails('Contact me at test@example.com')
  assert.equals(#emails, 1, 'Should extract one email')
  assert.equals(emails[1], 'test@example.com', 'Should extract correct email')
  
  -- Multiple emails
  emails = email_utils.extract_emails('CC: alice@example.com, bob@test.org')
  assert.equals(#emails, 2, 'Should extract multiple emails')
  assert.equals(emails[1], 'alice@example.com', 'First email')
  assert.equals(emails[2], 'bob@test.org', 'Second email')
  
  -- No emails
  emails = email_utils.extract_emails('No emails here')
  assert.equals(#emails, 0, 'Should find no emails')
  
  -- Nil handling
  emails = email_utils.extract_emails(nil)
  assert.equals(#emails, 0, 'Should handle nil')
end

function M.test_parse_address()
  -- Full address
  local parsed = email_utils.parse_address('John Doe <john@example.com>')
  assert.equals(parsed.name, 'John Doe', 'Should parse name')
  assert.equals(parsed.email, 'john@example.com', 'Should parse email')
  
  -- Quoted name
  parsed = email_utils.parse_address('"Doe, John" <john@example.com>')
  assert.equals(parsed.name, 'Doe, John', 'Should handle quoted name')
  
  -- Plain email
  parsed = email_utils.parse_address('john@example.com')
  assert.falsy(parsed.name, 'Should have no name')
  assert.equals(parsed.email, 'john@example.com', 'Should parse plain email')
  
  -- No email format
  parsed = email_utils.parse_address('Just a name')
  assert.equals(parsed.name, 'Just a name', 'Should use as name')
  assert.falsy(parsed.email, 'Should have no email')
  
  -- Nil handling
  parsed = email_utils.parse_address(nil)
  assert.falsy(parsed, 'Should handle nil')
end

function M.test_format_address()
  -- With name
  assert.equals(
    email_utils.format_address('John Doe <john@example.com>'),
    'John Doe',
    'Should format name'
  )
  
  -- Email only
  assert.equals(
    email_utils.format_address('john@example.com'),
    'john@example.com',
    'Should format email'
  )
  
  -- Unknown
  assert.equals(
    email_utils.format_address(nil),
    'Unknown',
    'Should handle nil'
  )
end

function M.test_format_email_for_sending()
  -- Basic email
  local email_data = {
    from = 'sender@example.com',
    to = 'recipient@example.com',
    subject = 'Test Subject',
    body = 'Test body'
  }
  
  local formatted = email_utils.format_email_for_sending(email_data)
  assert.matches(formatted, 'From: sender@example%.com', 'Should have From header')
  assert.matches(formatted, 'To: recipient@example%.com', 'Should have To header')
  assert.matches(formatted, 'Subject: Test Subject', 'Should have Subject header')
  assert.matches(formatted, '\n\nTest body', 'Should have body after blank line')
  
  -- With CC and BCC
  email_data.cc = 'cc@example.com'
  email_data.bcc = 'bcc@example.com'
  formatted = email_utils.format_email_for_sending(email_data)
  assert.matches(formatted, 'Cc: cc@example%.com', 'Should have CC header')
  assert.matches(formatted, 'Bcc: bcc@example%.com', 'Should have BCC header')
  
  -- With custom headers
  email_data.headers = {
    ['X-Priority'] = '1',
    ['X-Custom'] = 'value'
  }
  formatted = email_utils.format_email_for_sending(email_data)
  assert.matches(formatted, 'X%-Priority: 1', 'Should have custom header')
  assert.matches(formatted, 'X%-Custom: value', 'Should have custom header')
end

function M.test_parse_email_content()
  -- Simple email
  local lines = {
    'From: sender@example.com',
    'To: recipient@example.com',
    'Subject: Test',
    '',
    'This is the body.',
    'Second line.'
  }
  
  local email = email_utils.parse_email_content(lines)
  assert.equals(email.headers.from, 'sender@example.com', 'Should parse From')
  assert.equals(email.headers.to, 'recipient@example.com', 'Should parse To')
  assert.equals(email.headers.subject, 'Test', 'Should parse Subject')
  assert.equals(email.body, 'This is the body.\nSecond line.', 'Should parse body')
  
  -- Header continuation
  lines = {
    'Subject: Very long',
    ' subject line',
    '',
    'Body'
  }
  email = email_utils.parse_email_content(lines)
  assert.equals(email.headers.subject, 'Very long subject line', 'Should handle continuation')
end

function M.test_create_reply()
  -- Simple reply
  local original = {
    headers = {
      from = 'sender@example.com',
      to = 'me@example.com',
      subject = 'Original Subject',
      message_id = '<123@example.com>',
      date = 'Mon, 1 Jan 2024'
    },
    body = 'Original message'
  }
  
  local reply = email_utils.create_reply(original, false)
  assert.equals(reply.headers.from, 'me@example.com', 'Should swap From/To')
  assert.equals(reply.headers.to, 'sender@example.com', 'Should swap From/To')
  assert.equals(reply.headers.subject, 'Re: Original Subject', 'Should add Re: prefix')
  assert.equals(reply.headers['in-reply-to'], '<123@example.com>', 'Should set In-Reply-To')
  assert.matches(reply.body, '> Original message', 'Should quote original')
  
  -- Reply with existing Re:
  original.headers.subject = 'Re: Already a reply'
  reply = email_utils.create_reply(original, false)
  assert.equals(reply.headers.subject, 'Re: Already a reply', 'Should not double Re:')
  
  -- Reply all
  original.headers.cc = 'cc1@example.com, cc2@example.com'
  reply = email_utils.create_reply(original, true)
  assert.matches(reply.headers.cc, 'cc1@example%.com', 'Should include CC')
  assert.matches(reply.headers.cc, 'cc2@example%.com', 'Should include CC')
end

function M.test_generate_message_id()
  local id1 = email_utils.generate_message_id()
  local id2 = email_utils.generate_message_id()
  
  assert.matches(id1, '^<.+@.+>$', 'Should have correct format')
  assert.truthy(id1 ~= id2, 'Should generate unique IDs')
end

function M.test_has_attachments()
  -- With attachments
  local content = [[
Content-Type: multipart/mixed; boundary="boundary"

--boundary
Content-Type: text/plain

Body text
--boundary
Content-Type: application/pdf
Content-Disposition: attachment; filename="file.pdf"
]]
  
  assert.truthy(
    email_utils.has_attachments(content),
    'Should detect multipart content'
  )
  
  -- No attachments
  content = "Content-Type: text/plain\n\nJust text"
  assert.falsy(
    email_utils.has_attachments(content),
    'Should not detect attachments in plain text'
  )
  
  -- Nil handling
  assert.falsy(
    email_utils.has_attachments(nil),
    'Should handle nil'
  )
end

return M