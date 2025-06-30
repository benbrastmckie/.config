# Sync Status Display Specification

## Problem Statement

The current sync status display shows confusing and inconsistent numbers that jump around wildly during email synchronization, making it impossible for users to understand the actual progress of their sync operation.

### Current Behavior

During a sync operation, the status displays show values like:
- `= Syncing (1m 5s): 1 new to download`
- `= Syncing (1m 25s): 24500 to upload` 
- `= Syncing (1m 50s): 26590/26590 synced`
- `= Syncing (1m 55s): 26323 new to download`
- `= Syncing (2m 10s): 267/267 synced`
- `= Syncing (4m 45s): 8 new to download`
- `= Syncing (5m 15s): 797 new to download`

These numbers:
1. Jump from small to large values unpredictably (1 � 24500 � 26590 � 26323 � 267 � 8 � 797)
2. Switch between different types of operations (download/upload/synced) without clear context
3. Don't provide a clear sense of overall progress or completion percentage
4. Eventually result in sync failure with error code 1

### Desired Behavior

Users want to see clear incremental progress like:
- `= Syncing (2m 15s): 45/120 emails`
- A consistent count that shows how many emails have been processed and how many remain
- Clear indication of what operation is being performed (downloading, uploading, etc.)

## Technical Analysis

### mbsync Output Format

mbsync provides progress information in the following format:
```
C: 1/2 B: 3/4 F: +13/13 *23/42 #0/0 -0/0 N: +0/7 *0/0 #0/0
```

Where:
- `C: X/Y` - Channels processed (X) of total (Y)
- `B: X/Y` - Mailboxes (folders) processed (X) of total (Y)
- `F:` - Far side (server) operations:
  - `+X/Y` - Messages added (X) of total to add (Y)
  - `*X/Y` - Messages updated (X) of total to update (Y)
  - `#X/Y` - Messages flagged (X) of total to flag (Y)
  - `-X/Y` - Messages deleted (X) of total to delete (Y)
- `N:` - Near side (local) operations with same format as F:

### Current Implementation Issues

1. **Mixed Operation Types**: The parser is capturing different types of operations (adds, updates, flags, deletes) but displaying them inconsistently
2. **Cumulative vs Current**: mbsync reports cumulative totals, not current progress for a single operation
3. **Multiple Passes**: mbsync may make multiple passes over folders, causing numbers to reset or jump
4. **Context Loss**: Without knowing which folder/channel is being processed, numbers lack context

### Root Causes

1. **Parser Complexity**: The current parser tries to extract too many different metrics without understanding the context
2. **Display Logic**: The display logic doesn't differentiate between operation types or provide context
3. **State Management**: Progress state isn't properly tracked across different sync phases

## Proposed Solution

### 1. Simplify Progress Tracking

Focus on the most meaningful metrics:
- Current folder being synced
- Overall channel progress (X/Y channels)
- Current operation type (downloading, uploading, etc.)
- Estimated time remaining (if possible)

### 2. Context-Aware Display

Show progress with clear context:
```
= Syncing INBOX (1/5 folders): Downloading messages...
= Syncing Sent (2/5 folders): Uploading 45 messages...
= Syncing All_Mail (3/5 folders): Updating flags...
```

### 3. Operation Grouping

Group similar operations and show aggregate progress:
- Instead of showing individual add/update/flag operations
- Show total messages being processed for current folder
- Use folder-level progress as primary indicator

### 4. Progressive Disclosure

Provide different levels of detail:
- Simple mode: `= Syncing (2m 15s): 3/5 folders`
- Detailed mode: `= Syncing All_Mail (3/5): 1,234/5,678 messages`
- Debug mode: Full mbsync counter display

## Implementation Plan

### Phase 1: Research
- Study mbsync verbose output patterns in detail
- Test with different mailbox sizes and sync scenarios
- Understand the relationship between counters and actual progress

### Phase 2: Parser Refactor
- Simplify parse_progress() to focus on key metrics
- Add context tracking (current folder, operation type)
- Implement proper state management for multi-phase syncs

### Phase 3: Display Enhancement
- Create clear, consistent progress messages
- Add folder-level progress tracking
- Implement progressive disclosure options

### Phase 4: Testing
- Test with various email accounts and folder structures
- Verify progress accuracy and consistency
- Ensure no performance regression

## Alternative Approaches

### Option 1: Time-Based Progress
Show elapsed time and current operation without counts:
- `= Syncing (2m 15s): Processing INBOX...`
- `= Syncing (3m 45s): Processing All_Mail...`

### Option 2: Folder-Only Progress
Focus solely on folder completion:
- `= Syncing:  INBOX  Sent � All_Mail � Drafts � Trash`

### Option 3: Percentage-Based
Calculate approximate percentage based on folders and operations:
- `= Syncing: 60% complete (3/5 folders)`

## Success Criteria

1. Progress display shows consistent, understandable numbers
2. Users can gauge how much work remains
3. No confusing number jumps or resets
4. Clear indication of current operation
5. Works reliably across different email providers and folder structures

## Implementation Completed

### Changes Made

1. **Simplified Progress Tracking** in `sync/mbsync.lua`:
   - Focus on folder-level progress as primary indicator
   - Track current folder and message counts per folder
   - Accumulate overall statistics (+new, ↻updated, -deleted)
   - Remove confusing cumulative counters

2. **Clearer Display Logic** in `ui/main.lua`:
   - Primary display: "X/Y folders" with current folder name
   - Secondary display: Message progress for current folder
   - Compact statistics using icons (+, ↻, -)
   - Progressive disclosure based on available data

3. **Expected Display Examples**:
   ```
   🔄 Syncing (1m 5s): 2/5 folders - INBOX (45/120)
   🔄 Syncing (2m 10s): 3/5 folders - Sent - Uploading
   🔄 Syncing (3m 15s): 5/5 folders | +234 ↻45 -2
   ```

### Benefits

- Clear folder-based progress gives users context
- Per-folder message counts show granular progress
- Overall statistics provide summary without confusion
- No more jumping numbers or misleading totals