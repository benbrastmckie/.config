# Implementation Plan: Task #89

- **Task**: 89 - gmail_himalaya_folder_label_sync
- **Status**: [NOT STARTED]
- **Effort**: 1-2 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim

## Overview

This plan implements bidirectional folder/label synchronization between Gmail and Himalaya by modifying the mbsyncrc configuration. The current setup uses explicit folder patterns that prevent automatic discovery of new Gmail labels. By switching to wildcard patterns with proper exclusions and adding `Remove Both`, we enable full bidirectional sync where labels created in either Gmail or Himalaya automatically propagate to the other.

### Research Integration

Key findings from research-001.md:
- Current architecture: Gmail IMAP <-> mbsync <-> Local Maildir <-> Himalaya CLI
- Himalaya operates on local Maildir only; mbsync handles Gmail synchronization
- Current mbsyncrc uses explicit `Patterns "EuroTrip" "CrazyTown" "Letters"` - new labels do not auto-sync
- Solution: Change to `Patterns * ![Gmail]* !INBOX` with `Create Both`, `Expunge Both`, and `Remove Both`

## Goals & Non-Goals

**Goals**:
- Enable automatic discovery and sync of new Gmail labels created in browser
- Enable Himalaya-created folders to sync to Gmail without manual mbsyncrc edits
- Enable bidirectional folder deletion propagation
- Preserve existing folder sync behavior for current labels
- Document the new workflow for folder management

**Non-Goals**:
- Modifying Himalaya's Lua integration in Neovim (out of scope)
- Changing the Maildir backend architecture (keeping current two-tier design)
- Implementing Gmail API integration (staying with IMAP/mbsync)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Wildcard patterns sync unwanted system folders | Low | Low | Use exclusion patterns `![Gmail]*` and `!INBOX` |
| Accidental folder deletion propagates to Gmail | Medium | Medium | Create backup before changes; test with non-critical folder first |
| Breaking existing sync behavior | High | Low | Backup current config; test incrementally; revert if issues |
| Gmail rate limits during initial sync | Low | Low | Run initial sync during off-peak hours |

## Implementation Phases

### Phase 1: Backup Current Configuration [NOT STARTED]

**Goal**: Create a recoverable backup of current mbsyncrc before making changes.

**Tasks**:
- [ ] Create timestamped backup of `~/.mbsyncrc`
- [ ] Document current folder sync state by listing synced folders
- [ ] Verify backup is readable and complete

**Timing**: 10 minutes

**Files to modify**:
- None (backup only)

**Verification**:
- Backup file exists at `~/.mbsyncrc.backup.YYYYMMDD`
- Backup matches current configuration exactly
- Current folder list documented

---

### Phase 2: Modify mbsyncrc for Wildcard Patterns [NOT STARTED]

**Goal**: Update the gmail-folders channel to use wildcard patterns for automatic folder discovery.

**Tasks**:
- [ ] Edit `~/.mbsyncrc` to change `Patterns` line from explicit list to wildcard pattern
- [ ] Add `Remove Both` directive for folder deletion propagation
- [ ] Verify syntax is correct (no trailing whitespace, proper quoting)

**Timing**: 15 minutes

**Files to modify**:
- `~/.mbsyncrc` - Change gmail-folders channel configuration

**Changes**:
```diff
Channel gmail-folders
Far :gmail-remote:
Near :gmail-local:
-Patterns "EuroTrip" "CrazyTown" "Letters"
+Patterns * ![Gmail]* !INBOX
Create Both
Expunge Both
+Remove Both
SyncState *
```

**Verification**:
- Configuration file syntax valid
- No duplicate channel definitions
- Exclusion patterns correctly formatted

---

### Phase 3: Test Gmail-to-Himalaya Sync [NOT STARTED]

**Goal**: Verify that new labels created in Gmail browser appear in Himalaya after sync.

**Tasks**:
- [ ] Create a test label in Gmail web interface (e.g., "TestSyncFromGmail")
- [ ] Run `mbsync gmail-folders` to sync
- [ ] Verify folder appears in local Maildir (`~/Mail/Gmail/.TestSyncFromGmail/`)
- [ ] Verify folder visible in `himalaya folder list --account gmail`
- [ ] Delete test label in Gmail and verify propagation after sync

**Timing**: 20 minutes

**Files to modify**:
- None (testing only)

**Verification**:
- Test folder syncs from Gmail to local Maildir
- Test folder visible in Himalaya folder listing
- Deletion propagates after enabling `Remove Both`

---

### Phase 4: Test Himalaya-to-Gmail Sync [NOT STARTED]

**Goal**: Verify that folders created via Himalaya sync to Gmail as labels.

**Tasks**:
- [ ] Create a test folder via Himalaya: `himalaya folder add TestSyncFromHimalaya --account gmail`
- [ ] Run `mbsync gmail-folders` to sync to Gmail
- [ ] Verify label appears in Gmail web interface
- [ ] Delete folder via Himalaya and verify deletion propagates to Gmail after sync
- [ ] Clean up any test folders/labels

**Timing**: 20 minutes

**Files to modify**:
- None (testing only)

**Verification**:
- Test folder syncs from Himalaya to Gmail
- Test label visible in Gmail web interface
- Deletion propagates bidirectionally

---

### Phase 5: Update Documentation [NOT STARTED]

**Goal**: Document the new workflow and configuration for future reference.

**Tasks**:
- [ ] Create or update documentation noting the mbsyncrc changes
- [ ] Document the new folder management workflow:
  - Creating folders in Gmail (auto-syncs to Himalaya)
  - Creating folders in Himalaya (syncs to Gmail via mbsync)
  - Deleting folders (propagates bidirectionally)
- [ ] Note any limitations or caveats discovered during testing

**Timing**: 15 minutes

**Files to modify**:
- Documentation file (location TBD based on project structure)

**Verification**:
- Documentation accurately describes new behavior
- Workflow steps are clear and actionable

## Testing & Validation

- [ ] Backup created and verified before any changes
- [ ] mbsyncrc modification applied without syntax errors
- [ ] New Gmail labels auto-sync to Himalaya after `mbsync gmail-folders`
- [ ] Himalaya-created folders sync to Gmail as labels
- [ ] Folder deletions propagate bidirectionally
- [ ] Existing folders (EuroTrip, CrazyTown, Letters) remain synced
- [ ] No unwanted [Gmail]/* system folders appear in local Maildir

## Artifacts & Outputs

- `~/.mbsyncrc.backup.YYYYMMDD` - Backup of original configuration
- `~/.mbsyncrc` - Updated configuration (modified, not new)
- `specs/089_gmail_himalaya_folder_label_sync/summaries/implementation-summary-YYYYMMDD.md` - Completion summary

## Rollback/Contingency

If issues arise during or after implementation:

1. **Immediate Rollback**: Restore backup configuration
   ```bash
   cp ~/.mbsyncrc.backup.YYYYMMDD ~/.mbsyncrc
   mbsync gmail  # Re-sync to restore previous state
   ```

2. **Partial Rollback**: If only `Remove Both` causes issues
   - Edit mbsyncrc to remove `Remove Both` line
   - Keep wildcard patterns for folder discovery

3. **Investigation**: If unexpected folders sync
   - Check Patterns exclusion syntax
   - Add additional exclusion patterns as needed
   - Example: `!Drafts !Archive` if those cause issues
