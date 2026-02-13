# Research Report: Task #81

**Task**: Implement Himalaya Email Thread Grouping
**Date**: 2026-02-13
**Focus**: Research himalaya CLI thread support and implementation strategy for sidebar thread grouping

## Summary

Himalaya CLI v1.1.0 does not natively support email threading at the envelope list level. However, it provides access to Message-ID, In-Reply-To, and References headers via the `message read` command, enabling client-side thread grouping implementation in the Neovim plugin. The implementation will require fetching headers for emails and building a thread tree using the JWZ threading algorithm or a simplified variant.

## Findings

### 1. Himalaya CLI Threading Capabilities

**Current State**: Himalaya CLI does not provide built-in thread grouping. The `envelope list` command returns flat email lists without threading metadata.

**Envelope List Output (JSON)**:
```json
{
  "id": "2959",
  "flags": ["Seen"],
  "subject": "LOGOS LABORATORIES - trademark notification",
  "from": {"name": null, "addr": "account.services@trademarksoncall.com"},
  "to": {"name": null, "addr": "benbrastmckie@gmail.com"},
  "date": "2026-02-13 05:26+00:00",
  "has_attachment": false
}
```

Note: No Message-ID, In-Reply-To, or References fields in envelope output.

**Threading Headers Available via Message Read**:
Tested with `himalaya message read 2976 --header Message-ID --header In-Reply-To --header References`:
```
Message-ID: <MW4PR01MB6403F499B90BF1A77E94E48CF360A@MW4PR01MB6403.prod.exchangelabs.com>
In-Reply-To: <CAM_cz-9zDLU6X6iaujDah7ZEihCftVoZ+1Cd9fP1r_EOgY19ug@mail.gmail.com>
References: SJ0PR01MB6414366DA482F409F82A44B0F363A@SJ0PR01MB6414.prod.exchangelabs.com ...
```

### 2. GitHub Issues Analysis

**Issue #569 "Gmail threads vs himalaya emails"** (March 2025):
- Describes fundamental mismatch between Gmail's label-based threading and IMAP's folder-based model
- Maintainer noted: "every action is tied up to a folder or mailbox. IMAP works this way by design. This makes the thread feature barely usable, because messages are usually in different folders."
- No active development on native threading support

**Conclusion**: Native himalaya threading support is not imminent; client-side implementation is the path forward.

### 3. JWZ Threading Algorithm

The industry-standard algorithm for email threading (used by Netscape, Mozilla, RFC 5256):

**Key Steps**:
1. Build ID table mapping Message-IDs to container objects
2. Parse References/In-Reply-To to establish parent-child relationships
3. Find root set (messages without parents)
4. Prune empty containers
5. Sort siblings by date

**Headers Used**:
- **Message-ID**: Unique identifier for each email
- **In-Reply-To**: Parent message's Message-ID (single reference)
- **References**: Full thread history (space-separated Message-IDs, oldest first)

### 4. Current Plugin Architecture Analysis

**Relevant Files**:
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - Main email list rendering
- `lua/neotex/plugins/tools/himalaya/ui/sidebar.lua` - Sidebar window management
- `lua/neotex/plugins/tools/himalaya/utils/email.lua` - Email parsing utilities
- `lua/neotex/plugins/tools/himalaya/features/headers.lua` - Header management (existing)
- `lua/neotex/plugins/tools/himalaya/data/cache.lua` - Email caching

**Existing TODO in email_list.lua**:
```lua
-- TODO: Implement email threading/conversation view
```

**Current Data Flow**:
1. `utils.get_emails_async()` fetches envelope list from himalaya
2. `M.format_email_list()` renders flat list with checkboxes, sender, subject, date
3. `sidebar.update_content()` displays in sidebar buffer
4. Page caching via `page_cache` for instant pagination

**Headers Module Capability**:
The `features/headers.lua` module already has `M.get_headers(email_id)` that can fetch arbitrary headers and `M.parse_headers(raw_headers)` for parsing.

### 5. Implementation Strategy Options

**Option A: Full JWZ Algorithm (Complex)**
- Fetch headers for all visible emails via `message read --header` commands
- Build complete thread tree
- Render as collapsible hierarchy
- **Pros**: Industry standard, handles edge cases
- **Cons**: Multiple CLI calls per page load, complex tree rendering

**Option B: Subject-Based Grouping (Simple)**
- Group emails by normalized subject (strip Re:, AW:, Fwd: prefixes)
- Display most recent email per thread group
- Show thread count indicator
- **Pros**: No additional CLI calls, simple implementation
- **Cons**: Less accurate (unrelated emails may share subjects)

**Option C: Hybrid Approach (Recommended)**
- Use subject-based grouping for initial display (fast)
- Fetch threading headers on-demand when expanding a thread
- Cache threading metadata for future use
- **Pros**: Best UX (fast initial load, accurate when needed)
- **Cons**: Medium complexity

### 6. Subject Normalization Patterns

Common reply/forward prefixes to strip:
- `Re:`, `RE:`, `re:`
- `AW:` (German)
- `Fwd:`, `FW:`, `fwd:`
- `Antwort:` (German)
- `SV:` (Swedish/Norwegian)
- `Rif:` (Italian)

Normalized subject regex:
```lua
subject:gsub("^%s*[Rr][Ee]:%s*", "")
       :gsub("^%s*[Aa][Ww]:%s*", "")
       :gsub("^%s*[Ff][Ww][Dd]?:%s*", "")
       :gsub("^%s*", "")
```

### 7. Display Format Considerations

**Current Format**:
```
[ ] Bailey Fernandez | AW: Meeting?  2026-02-12 10:59
[ ] Bailey Fernandez | AW: Meeting?  2026-02-12 07:58
[ ] Bailey Fernandez | AW: Meeting?  2026-02-11 21:15
```

**Proposed Thread View Format**:
```
[ ] Bailey Fernandez | Meeting? (5 messages)  2026-02-12 10:59
    [ ] Bailey Fernandez | AW: Meeting?       2026-02-12 10:59
    [ ] benbrastmckie   | Re: Meeting?        2026-02-12 10:59
    [ ] Bailey Fernandez | AW: Meeting?       2026-02-12 07:58
    ...
```

Or collapsed view:
```
[ ][5] Bailey Fernandez | Meeting?  2026-02-12 10:59
```

Where `[5]` indicates 5 messages in thread.

## Recommendations

1. **Start with Option C (Hybrid Approach)**:
   - Phase 1: Implement subject-based grouping for immediate benefit
   - Phase 2: Add header-based threading for accurate thread reconstruction
   - Phase 3: Add UI for expanding/collapsing thread groups

2. **Data Structure**: Create a thread index structure:
```lua
{
  threads = {
    ["normalized_subject"] = {
      emails = {...},  -- Sorted by date descending
      latest_date = "2026-02-12 10:59",
      thread_count = 5,
      has_unread = true
    }
  }
}
```

3. **UI Changes**:
   - Add thread count indicator to email list entries
   - Implement keybinding to expand/collapse threads (e.g., `zo`/`zc` or `Tab`)
   - Show visual indentation for thread hierarchy

4. **Configuration**:
   - Add toggle for thread grouping (default: enabled)
   - Add option for default view (collapsed/expanded)

## References

- [Himalaya GitHub Repository](https://github.com/pimalaya/himalaya)
- [Himalaya Issue #569: Gmail threads vs himalaya emails](https://github.com/pimalaya/himalaya/issues/569)
- [JWZ Threading Algorithm](https://www.jwz.org/doc/threading.html)
- [RFC 5256: IMAP SORT and THREAD Extensions](https://datatracker.ietf.org/doc/html/rfc5256)
- [Email Threading Headers Guide](https://cr.yp.to/immhf/thread.html)
- [Creating Email Threads - MailerSend Guide](https://developers.mailersend.com/guides/creating-email-threads)

## Next Steps

1. Create implementation plan with phased approach
2. Design thread data structure and caching strategy
3. Implement subject normalization function
4. Add thread grouping to format_email_list()
5. Implement thread count indicator in UI
6. Add expand/collapse keybindings
7. Test with real email threads
