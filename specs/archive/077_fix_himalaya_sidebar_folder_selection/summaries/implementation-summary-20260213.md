# Implementation Summary: Task #77

**Completed**: 2026-02-13
**Duration**: 15 minutes

## Changes Made

Fixed himalaya sidebar folder selection to include INBOX and sort folders by usage priority. The fix modifies the `get_folders()` and `scan_maildir_folders()` functions to:

1. Guarantee INBOX presence - checks if INBOX is in the folder list after CLI results, inserts it at position 1 if missing (addresses himalaya CLI not returning INBOX for Maildir++ backends)
2. Apply priority-based sorting - defines folder priority map (INBOX=1, Sent=2, Drafts=3, All_Mail=4, Trash=5) and sorts folders by priority, with alphabetical ordering for equal-priority folders

## Files Modified

- `lua/neotex/plugins/tools/himalaya/utils.lua` - Added INBOX guarantee check and priority sorting to both `get_folders()` (lines 91-122) and `scan_maildir_folders()` (lines 155-173) for consistency across CLI and fallback code paths

## Verification

- Module loading: SUCCESS - `require('neotex.plugins.tools.himalaya.utils')` loads without errors
- Test mode folders: INBOX appears first, followed by Sent, Drafts, Trash
- Sorting logic test: PASSED - comprehensive test with mixed order folders verified expected output order
  - Priority folders: INBOX, Sent, Drafts, All_Mail, Trash (positions 1-5)
  - Non-priority folders: Archives, Personal, Work (alphabetized, positions 6-8)

## Notes

- Both `get_folders()` and `scan_maildir_folders()` were updated to ensure consistent sorting regardless of which code path is executed
- The sorting comparator handles both table and string folder representations for robustness
- No changes required to picker UI code (`pick_folder`) since the sorting is applied at the data source
