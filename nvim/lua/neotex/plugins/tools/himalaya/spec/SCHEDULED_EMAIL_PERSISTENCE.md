# Scheduled Email Persistence Specification

## Overview

This specification defines how scheduled emails persist between Neovim sessions and are shared across multiple Neovim instances. The current in-memory queue is lost when Neovim exits, which is unacceptable for email scheduling functionality.

## Requirements

### Functional Requirements
- **FR1**: Scheduled emails MUST persist across Neovim restarts
- **FR2**: Scheduled emails MUST be shared between multiple Neovim instances
- **FR3**: Email queue MUST be atomically updated to prevent corruption
- **FR4**: System MUST handle concurrent access from multiple instances
- **FR5**: Failed or corrupted persistence MUST NOT break the scheduler
- **FR6**: System MUST automatically cleanup expired/sent emails
- **FR7**: Persistence format MUST be human-readable for debugging

### Non-Functional Requirements
- **NFR1**: File operations MUST be atomic to prevent data corruption
- **NFR2**: Queue loading MUST complete within 100ms for responsiveness
- **NFR3**: File size MUST remain reasonable (<1MB for 1000 emails)
- **NFR4**: System MUST be resilient to file system issues
- **NFR5**: Performance MUST not degrade with multiple instances

## Architecture

### Storage Strategy

**Primary Storage**: JSON file with atomic writes
- **Location**: `~/.config/himalaya/scheduled_emails.json`
- **Format**: Structured JSON with metadata and email data
- **Backup**: Automatic backup files for corruption recovery

**Lock Strategy**: File-based locking with timeout
- **Lock File**: `~/.config/himalaya/scheduled_emails.lock`
- **Timeout**: 5 seconds maximum lock duration
- **Recovery**: Automatic stale lock detection and cleanup

### Data Structure

```json
{
  "version": "1.0",
  "created": "2024-01-01T10:00:00Z",
  "last_modified": "2024-01-01T12:30:00Z",
  "queue": {
    "email_123456789": {
      "id": "email_123456789",
      "scheduled_for": 1704110400,
      "created_at": 1704103200,
      "status": "pending",
      "account": "gmail",
      "attempts": 0,
      "last_attempt": null,
      "email_data": {
        "to": "user@example.com",
        "subject": "Test Email",
        "body": "Email content...",
        "from": "sender@gmail.com",
        "cc": null,
        "bcc": null
      },
      "metadata": {
        "nvim_instance": "nvim_12345",
        "created_by": "user@hostname",
        "file_refs": []
      }
    }
  },
  "statistics": {
    "total_scheduled": 1,
    "total_sent": 0,
    "total_failed": 0,
    "total_cancelled": 0
  }
}
```

### File Operations

#### Atomic Write Pattern
```lua
1. Write to temporary file: scheduled_emails.tmp
2. Acquire exclusive lock: scheduled_emails.lock
3. Validate current file (if exists)
4. Move temp file to final location
5. Release lock
6. Remove temp file (if still exists)
```

#### Read Pattern
```lua
1. Check if file exists
2. Acquire shared lock (with timeout)
3. Read and validate JSON
4. Parse into queue structure
5. Release lock
6. Handle corruption gracefully
```

## Implementation

### Core Persistence Module

**File**: `lua/neotex/plugins/tools/himalaya/core/persistence.lua`

```lua
local M = {}

-- Configuration
M.config = {
  queue_file = vim.fn.expand('~/.config/himalaya/scheduled_emails.json'),
  lock_file = vim.fn.expand('~/.config/himalaya/scheduled_emails.lock'),
  backup_dir = vim.fn.expand('~/.config/himalaya/backups/'),
  lock_timeout = 5000, -- 5 seconds
  max_backups = 10,
  auto_cleanup_interval = 300, -- 5 minutes
}

-- Core Functions
function M.save_queue(queue)
function M.load_queue()
function M.acquire_lock(timeout)
function M.release_lock(lock_handle)
function M.backup_queue_file()
function M.validate_queue_data(data)
function M.cleanup_expired_emails(queue)
function M.get_instance_id()
```

### Scheduler Integration

**File**: `lua/neotex/plugins/tools/himalaya/core/scheduler.lua`

#### Initialization Changes
```lua
-- Replace in-memory queue with persistent queue
function M.init()
  -- Load existing queue from disk
  local persistence = require('neotex.plugins.tools.himalaya.core.persistence')
  M.queue = persistence.load_queue() or {}
  
  -- Start background sync timer
  M.start_persistence_sync()
  
  -- Start cleanup timer
  M.start_cleanup_timer()
end
```

#### Queue Modification Pattern
```lua
function M.schedule_email(email_data, scheduled_for)
  -- Generate unique ID
  local id = M.generate_email_id()
  
  -- Create email item
  local item = {
    id = id,
    scheduled_for = scheduled_for,
    created_at = os.time(),
    status = 'pending',
    account = state.get_current_account(),
    attempts = 0,
    email_data = email_data,
    metadata = {
      nvim_instance = persistence.get_instance_id(),
      created_by = vim.env.USER .. '@' .. vim.fn.hostname(),
    }
  }
  
  -- Update in-memory queue
  M.queue[id] = item
  
  -- Persist to disk
  M.persist_queue()
  
  return id
end
```

### Concurrency Handling

#### Lock Management
```lua
function M.with_queue_lock(operation, timeout)
  local lock_handle = persistence.acquire_lock(timeout or 5000)
  if not lock_handle then
    error("Failed to acquire queue lock")
  end
  
  local success, result = pcall(operation)
  persistence.release_lock(lock_handle)
  
  if not success then
    error(result)
  end
  
  return result
end
```

#### Multi-Instance Synchronization
```lua
-- Periodic sync from disk (every 30 seconds)
function M.sync_from_disk()
  local disk_queue = persistence.load_queue()
  if not disk_queue then return end
  
  -- Merge changes from other instances
  for id, item in pairs(disk_queue) do
    if not M.queue[id] or item.last_modified > M.queue[id].last_modified then
      M.queue[id] = item
    end
  end
  
  -- Remove emails that were cancelled/sent by other instances
  for id, item in pairs(M.queue) do
    if not disk_queue[id] and item.status == 'pending' then
      M.queue[id] = nil
    end
  end
end
```

### Error Handling

#### Corruption Recovery
```lua
function M.recover_from_corruption()
  logger.warn("Queue file corrupted, attempting recovery")
  
  -- Try backup files in reverse chronological order
  local backups = persistence.get_backup_files()
  
  for _, backup_file in ipairs(backups) do
    local queue = persistence.load_queue_from_file(backup_file)
    if queue and persistence.validate_queue_data(queue) then
      logger.info("Recovered queue from backup: " .. backup_file)
      return queue
    end
  end
  
  -- If all backups fail, start with empty queue
  logger.warn("All recovery attempts failed, starting with empty queue")
  return {}
end
```

#### Lock Timeout Handling
```lua
function M.handle_lock_timeout()
  -- Check if lock file is stale
  local lock_age = persistence.get_lock_age()
  
  if lock_age > M.config.lock_timeout then
    logger.warn("Removing stale lock file")
    persistence.remove_stale_lock()
    return true
  end
  
  return false
end
```

### Performance Optimizations

#### Lazy Loading
```lua
-- Only load queue when first accessed
local queue_loaded = false

function M.get_queue()
  if not queue_loaded then
    M.queue = persistence.load_queue() or {}
    queue_loaded = true
  end
  return M.queue
end
```

#### Incremental Persistence
```lua
-- Only persist when queue actually changes
local queue_dirty = false

function M.mark_queue_dirty()
  queue_dirty = true
end

function M.auto_persist()
  if queue_dirty then
    M.persist_queue()
    queue_dirty = false
  end
end
```

#### Background Cleanup
```lua
function M.start_cleanup_timer()
  vim.fn.timer_start(M.config.auto_cleanup_interval * 1000, function()
    M.cleanup_expired_emails()
    M.cleanup_old_backups()
  end, { ['repeat'] = -1 })
end
```

## Migration Strategy

### Phase 1: Add Persistence Layer ✅ COMPLETED
1. ✅ Create persistence module with file operations
2. ✅ Add queue loading/saving to scheduler  
3. ✅ Maintain backward compatibility
4. ✅ Atomic write operations with temporary files
5. ✅ Automatic backup creation and cleanup
6. ✅ Corruption recovery with graceful fallback
7. ✅ Comprehensive validation and error handling

**Implementation Status**: Phase 1 is fully implemented and tested. Scheduled emails now persist across Neovim sessions using JSON file storage with atomic writes and automatic backups.

**Files Created/Modified**:
- `core/persistence.lua` - New persistence module with file operations
- `core/scheduler.lua` - Modified to use persistence module
- `scripts/test_persistence.lua` - Test script for validation

**Key Features Implemented**:
- JSON file storage at `~/.config/himalaya/scheduled_emails.json`
- Atomic writes using temporary files for data integrity
- Automatic backup creation with configurable retention (5 backups)
- Corruption detection and recovery from backups
- Comprehensive data validation
- Graceful error handling and logging
- Automatic cleanup of expired emails
- Health check functionality

### Phase 2: Enable Multi-Instance Support
1. Add file locking mechanism
2. Implement periodic sync from disk
3. Add conflict resolution

### Phase 3: Add Resilience Features
1. Implement backup and recovery
2. Add corruption detection
3. Add performance monitoring

## Testing Strategy

### Unit Tests
- File operations (read, write, lock)
- Queue serialization/deserialization
- Corruption recovery
- Lock timeout handling

### Integration Tests
- Multi-instance scenarios
- Concurrent access patterns
- File system failure simulation
- Performance under load

### Manual Testing
- Open multiple Neovim instances
- Schedule emails in different instances
- Restart Neovim during scheduling
- Simulate file corruption

## Configuration

### User Configuration Options
```lua
-- In user's Himalaya config
config.scheduler = {
  persistence = {
    enabled = true,
    queue_file = "~/.config/himalaya/scheduled_emails.json",
    backup_count = 10,
    sync_interval = 30, -- seconds
    lock_timeout = 5000, -- milliseconds
  }
}
```

### Environment Variables
- `HIMALAYA_QUEUE_FILE`: Override default queue file location
- `HIMALAYA_NO_PERSISTENCE`: Disable persistence for testing

## Security Considerations

### File Permissions
- Queue file: 600 (owner read/write only)
- Lock file: 644 (readable by all, writable by owner)
- Backup directory: 700 (owner access only)

### Data Sanitization
- Email content MUST be validated before persistence
- No sensitive data in metadata fields
- Automatic cleanup of old/expired entries

## Monitoring and Debugging

### Logging
- All file operations logged at DEBUG level
- Lock acquisition/release logged
- Queue modifications logged with timestamps
- Errors logged with full context

### Health Checks
```lua
function M.health_check()
  return {
    queue_file_exists = vim.fn.filereadable(M.config.queue_file) == 1,
    queue_file_writable = vim.fn.filewritable(M.config.queue_file) == 1,
    lock_file_stale = persistence.is_lock_stale(),
    queue_size = vim.tbl_count(M.queue),
    last_sync = M.last_sync_time,
  }
end
```

## Future Enhancements

### Advanced Features
- Network-based queue sharing (multiple machines)
- Queue encryption for sensitive emails
- Advanced conflict resolution strategies
- Queue analytics and reporting
- Integration with external schedulers

### Performance Improvements
- Binary format for large queues
- Incremental file updates
- Memory-mapped file access
- Queue sharding for scale

## Conclusion

This specification provides a robust foundation for scheduled email persistence that addresses all requirements while maintaining performance and reliability. The implementation prioritizes data integrity, concurrent access safety, and graceful error recovery.

The phased approach allows for incremental deployment while maintaining backward compatibility. The comprehensive testing strategy ensures reliability across various failure scenarios.