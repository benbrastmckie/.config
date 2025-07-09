# Draft messages return only headers when using `message read` command

## Description

When reading draft emails using the `himalaya message read` command, only the headers are returned without the message body, even though the draft is correctly saved in the maildir with full content.

## Steps to Reproduce

1. Create a draft email with content:
```bash
cat > test_draft.eml << 'EOF'
From: user@example.com
To: recipient@example.com
Subject: Test Draft Subject

This is the body of the test draft.
It has multiple lines.

And paragraphs too.
EOF
```

2. Save the draft to himalaya:
```bash
cat test_draft.eml | himalaya message save --account gmail --folder Drafts
# Output: Message successfully saved to Drafts!
```

3. List drafts to get the ID:
```bash
himalaya envelope list --account gmail --folder Drafts
# Example output:
# | ID  | FLAGS | SUBJECT            | FROM         | DATE                   |
# |-----|-------|--------------------|--------------|------------------------|
# | 883 |       | Test Draft Subject | user@example | 2025-01-09 18:25+00:00 |
```

4. Try to read the draft:
```bash
himalaya message read 883 --account gmail --folder Drafts
# Output: From: user@example.com
# (Only the From header is returned, no other headers or body)
```

5. Verify the draft is correctly saved in maildir:
```bash
cat ~/Mail/Gmail/.Drafts/cur/[draft-file-name]
# Shows the complete email with all headers and body
```

## Expected Behavior

The `himalaya message read` command should return the complete draft email including:
- All headers (From, To, Subject, etc.)
- Empty line separator
- Full message body

Example expected output:
```
From: user@example.com
To: recipient@example.com
Subject: Test Draft Subject

This is the body of the test draft.
It has multiple lines.

And paragraphs too.
```

## Actual Behavior

Only partial headers are returned (typically just the "From" header), with no message body:
```
From: user@example.com
```

## Environment

- **Himalaya version**: [Run `himalaya --version` to get version]
- **OS**: Linux
- **Account type**: Gmail (using maildir backend)
- **Folder**: Drafts

## Additional Information

- The issue occurs with both `-o json` and `-o plain` output formats
- Regular emails (non-drafts) in INBOX and other folders read correctly with full content
- The draft files in maildir contain the complete email content, so the issue appears to be with the `message read` command specifically for drafts
- This issue affects email clients and plugins that depend on himalaya for draft management

## Workaround

As a temporary workaround, draft content can be read directly from the maildir files in `~/Mail/[Account]/.Drafts/cur/`, but this bypasses himalaya's ID mapping system.

## Impact

This bug prevents proper draft management in any application using himalaya as a backend, as drafts cannot be reopened for editing with their original content.