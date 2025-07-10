# Multi-Instance Auto-Sync Coordination

## Executive Summary

This specification addresses the issue where multiple Neovim instances each start their own auto-sync timer, leading to excessive sync frequency and resource usage. The solution implements an elegant primary/secondary coordinator election system that ensures only one instance manages auto-sync across all running Neovim sessions.

## Problem Statement

When multiple Neovim sessions are open:
- Each instance starts a 15-minute auto-sync timer
- With 3 instances, syncs occur every 5 minutes (3x more frequent)
- Lock contention occurs when syncs overlap
- Unnecessary network and CPU usage
- Potential rate limiting from email providers

## Solution Overview

### Primary/Secondary Coordination

1. **Automatic Election**: First instance becomes primary coordinator
2. **Heartbeat System**: Primary sends heartbeat every 30 seconds
3. **Automatic Failover**: If primary exits, another instance takes over
4. **Shared State**: Coordination via `~/.config/himalaya/sync_coordinator.json`
5. **Sync Cooldown**: Enforces minimum 5 minutes between syncs

### Key Features

- **Zero Configuration**: Works automatically with sensible defaults
- **Graceful Degradation**: Falls back to normal behavior if coordination fails
- **Debug Transparency**: Coordination status visible only in debug mode
- **Status Command**: `:HimalayaSyncStatus` shows coordination state

## Implementation Details

### 1. Coordinator Module (`sync/coordinator.lua`)

- Manages instance registration and primary election
- Implements heartbeat mechanism for liveness detection
- Enforces sync cooldown across all instances
- Handles cleanup on instance exit

### 2. Modified Sync Manager

- Checks coordinator before initiating auto-sync
- Records sync completion for cross-instance tracking
- Shows role in debug notifications

### 3. Integration Points

- **Existing State System**: Leverages `persistence.get_instance_id()`
- **Notification System**: Uses `BACKGROUND` category for debug-only messages
- **Lock System**: Complements existing mbsync file locking

## User Experience

### Normal Mode (Default)
- No visible changes - auto-sync "just works"
- Only one instance syncs at configured intervals
- Seamless failover if primary exits

### Debug Mode
- Shows which instance is primary coordinator
- Displays sync cooldown status
- Logs coordination decisions

### Status Command
```
:HimalayaSyncStatus

# Himalaya Sync Coordination Status

## Current Instance
  Instance ID: nvim_1704123456_7890
  Role: Primary Coordinator
  PID: 12345

## Primary Coordinator
  Instance: nvim_1704123456_7890
  PID: 12345
  Last Heartbeat: 5 seconds ago
  Status: Active

## Sync History
  Last Sync: 3 minutes ago
  By Instance: nvim_1704123456_7890
  Cooldown: 2 minutes remaining
```

## Benefits

1. **Resource Efficiency**: Reduces sync frequency to configured interval
2. **Network Friendly**: Prevents excessive API calls
3. **Transparent**: No user configuration required
4. **Reliable**: Automatic failover ensures syncs continue
5. **Debuggable**: Clear visibility into coordination state

## Testing

1. Open 3+ Neovim instances
2. Run `:HimalayaSyncStatus` to verify primary election
3. Close primary instance and verify failover
4. Check that sync frequency matches configuration

## Future Enhancements

- Load-balanced folder sync (different instances sync different folders)
- Priority-based coordinator election (prefer long-running instances)
- Sync scheduling optimization based on email patterns
- Integration with system idle detection

## Configuration

```lua
sync = {
  coordination = {
    enabled = true,              -- Enable coordination
    heartbeat_interval = 30,     -- Seconds between heartbeats
    takeover_threshold = 60,     -- Seconds before takeover
    sync_cooldown = 300,         -- Minimum seconds between syncs
  }
}
```

This elegant solution solves the multi-instance sync problem while maintaining the simplicity and reliability users expect from the Himalaya plugin.