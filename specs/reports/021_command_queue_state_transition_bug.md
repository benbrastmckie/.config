# Debug Report: Command Queue State Transition Bug

## Metadata
- **Date**: 2025-09-30
- **Report Number**: 021
- **Issue**: Commands queued before Claude Code starts don't execute after terminal opens
- **Severity**: High
- **Type**: Debugging investigation - State machine logic error
- **Related Reports**:
  - [020_command_insertion_autocommand_architecture.md](020_command_insertion_autocommand_architecture.md) - Implementation context
- **Related Plans**:
  - [012_event_driven_command_insertion.md](../plans/012_event_driven_command_insertion.md) - Recent implementation

## Problem Statement

### User-Reported Behavior

User selects a command (e.g., `/cleanup`) from the `<leader>ac` picker before Claude Code is running:

**Expected Behavior**:
1. Command queued
2. Claude Code opens
3. Terminal detected as ready
4. Command executes automatically

**Actual Behavior**:
1. Command queued ✓
2. Claude Code opens ✓
3. Terminal detected as ready ✓
4. **Command does NOT execute** ✗
5. User left in insert mode in Claude terminal
6. Command sits in queue indefinitely

### Debug Log Analysis

Critical sequence from user's debug output:

```
Queued command '/cleanup' - Claude Code will open automatically
[DEBUG] CommandQueue: Command queued
[DEBUG] CommandQueue: Queuing command due to Claude state

[Claude Code opens]

DEBUG: TermOpen fired for terminal: term://~/.config//478601...
[DEBUG] TerminalMonitor: TermOpen event for Claude Code terminal
[DEBUG] TerminalMonitor: Detected Claude terminal by name, using event-driven detection
[DEBUG] TerminalMonitor: Starting to monitor Claude terminal
[DEBUG] TerminalMonitor: Channel validation result
[DEBUG] TerminalMonitor: Channel validation successful on TermOpen
[DEBUG] TerminalMonitor: Claude Code detected as ready
[DEBUG] TerminalMonitor: Notifying command queue of Claude readiness

[CRITICAL ERROR]
[DEBUG] CommandQueue: Invalid state transition attempted  ← BUG HERE
[DEBUG] CommandQueue: Claude Code detected as ready
```

The state transition is **rejected** and command processing never happens.

## Investigation Process

### Step 1: Trace Command Flow

**picker.lua:314-389** - `send_command_to_terminal()`
```lua
-- Line 350: Queue the command
local success = command_queue.send_command(command_text, "picker", 1)

-- Lines 354-365: If queued and Claude not available, open Claude
if not queue_state.claude_available and queue_state.queue_size > 0 then
  local open_success = pcall(claude_code.toggle)
end
```

**command-queue.lua:697-750** - `M.send_command()`
```lua
-- Line 701: Try to find Claude terminal
local buf, channel = find_claude_terminal()

-- Line 704: Check current state
local current_state = claude_state_machine.current_state

-- Lines 706-733: If Claude ready, execute immediately
if buf and channel and current_state == CLAUDE_STATES.READY then
  -- Execute immediately
else
  -- Lines 734-750: Queue the command
  debug_log("Queuing command due to Claude state", {...})

  -- Lines 744-746: CRITICAL CODE PATH
  if buf and current_state == CLAUDE_STATES.WAITING then
    transition_state(CLAUDE_STATES.STARTING, buf, "terminal_detected_for_command")
  end

  return M.queue_command(command_text, source, priority)
end
```

### Step 2: Identify State Machine Logic

**State Machine Definition** (command-queue.lua:39-56):
```lua
local CLAUDE_STATES = {
  STARTING = "starting",    -- Claude Code initializing
  READY = "ready",         -- Ready for commands
  EXECUTING = "executing", -- Processing command
  WAITING = "waiting"      -- Not available or crashed
}

local claude_state_machine = {
  current_state = CLAUDE_STATES.WAITING,  -- Initial state
  last_transition = 0,
  buffer = nil,
  transitions = {},
  persistence_enabled = false
}
```

**Valid Transitions** (command-queue.lua:119-124):
```lua
local valid_transitions = {
  [CLAUDE_STATES.WAITING] = { CLAUDE_STATES.STARTING },              -- ✓
  [CLAUDE_STATES.STARTING] = { CLAUDE_STATES.READY, CLAUDE_STATES.WAITING },  -- ✓
  [CLAUDE_STATES.READY] = { CLAUDE_STATES.EXECUTING, CLAUDE_STATES.WAITING }, -- ✓
  [CLAUDE_STATES.EXECUTING] = { CLAUDE_STATES.READY, CLAUDE_STATES.WAITING }  -- ✓
}
```

**State Transition Validation** (command-queue.lua:126-134):
```lua
if not valid_transitions[old_state] or not vim.tbl_contains(valid_transitions[old_state], new_state) then
  debug_log("Invalid state transition attempted", {
    from = old_state,
    to = new_state,
    reason = reason,
    buffer = buf
  })
  return  -- TRANSITION REJECTED - STATE UNCHANGED
end
```

### Step 3: Trace the Bug

**Scenario**: User queues command before Claude Code exists

1. **Command Selection**: User presses `<leader>ac`, selects `/cleanup`
   - picker.lua calls `command_queue.send_command("/cleanup", "picker", 1)`

2. **Command Queueing** (command-queue.lua:697-750):
   - `find_claude_terminal()` returns `buf=nil, channel=nil` (Claude not running)
   - `current_state` = `CLAUDE_STATES.WAITING`
   - Goes to else branch (line 734)
   - **Line 744 check**: `if buf and current_state == CLAUDE_STATES.WAITING`
     - `buf` is **nil** (Claude not running)
     - Condition is **false**
     - **WAITING → STARTING transition NEVER happens**
   - Command queued, state remains **WAITING**

3. **Claude Opens**: picker.lua calls `claude_code.toggle()`
   - TermOpen event fires
   - terminal-monitor.lua detects Claude terminal
   - Channel validation succeeds

4. **Ready Signal** (terminal-monitor.lua → command-queue.lua:819-827):
   ```lua
   function M.on_claude_ready(buf)
     queue_stats.claude_detections = queue_stats.claude_detections + 1
     debug_log("Claude Code detected as ready", { buffer = buf })

     -- Attempts transition: WAITING → READY
     transition_state(CLAUDE_STATES.READY, buf, "terminal_monitor_ready")
     queue_stats.last_state_change = os.time()
   end
   ```

5. **State Transition Rejection** (command-queue.lua:126-134):
   - Current state: **WAITING**
   - Requested state: **READY**
   - Valid transitions from WAITING: `{ STARTING }` only
   - **WAITING → READY is INVALID**
   - Transition rejected, debug message logged
   - **Command processing never triggered**

## Findings

### Root Cause

**Invalid state transition path in event-driven architecture**

The state machine expects this flow:
```
WAITING → STARTING → READY → EXECUTING
```

But the actual flow is:
```
WAITING → [attempt READY] → REJECTED → stays WAITING
```

**Why This Happens**:

1. **Line 744-746** in `send_command()` should transition to STARTING, but:
   ```lua
   if buf and current_state == CLAUDE_STATES.WAITING then
     transition_state(CLAUDE_STATES.STARTING, buf, "terminal_detected_for_command")
   end
   ```
   - Requires `buf` (buffer number) to be valid
   - When Claude doesn't exist yet, `buf` is `nil`
   - Condition fails, no transition happens

2. **Line 825** in `on_claude_ready()` assumes state is STARTING:
   ```lua
   transition_state(CLAUDE_STATES.READY, buf, "terminal_monitor_ready")
   ```
   - Tries WAITING → READY (invalid)
   - Should try STARTING → READY (valid)
   - But state never transitioned to STARTING

### Contributing Factors

1. **Missing State Transition on Queue**: When command is queued without an existing terminal, no state transition happens
2. **Assumption in on_claude_ready**: Assumes state will be STARTING when it's called
3. **No Fallback Logic**: State machine has no recovery path for this scenario

### Evidence

**From Debug Logs**:
```
[DEBUG] CommandQueue: Queuing command due to Claude state
current_state = "waiting"
has_terminal = false
```

Then later:
```
[DEBUG] CommandQueue: Invalid state transition attempted
from = "waiting"
to = "ready"
reason = "terminal_monitor_ready"
```

**From Code Inspection**:
- command-queue.lua:744 requires `buf` to be non-nil
- command-queue.lua:825 assumes STARTING state
- command-queue.lua:120 only allows WAITING → STARTING

## Proposed Solutions

### Option 1: Fix on_claude_ready to Handle WAITING State (Recommended)

**Approach**: Allow `on_claude_ready` to transition from WAITING directly

**Changes Required**:
```lua
-- In command-queue.lua:819-827
function M.on_claude_ready(buf)
  queue_stats.claude_detections = queue_stats.claude_detections + 1
  debug_log("Claude Code detected as ready", { buffer = buf })

  local current_state = claude_state_machine.current_state

  -- Handle both WAITING and STARTING states
  if current_state == CLAUDE_STATES.WAITING then
    -- Transition through STARTING to READY
    transition_state(CLAUDE_STATES.STARTING, buf, "terminal_detected_ready")
    transition_state(CLAUDE_STATES.READY, buf, "terminal_monitor_ready")
  elseif current_state == CLAUDE_STATES.STARTING then
    -- Normal path
    transition_state(CLAUDE_STATES.READY, buf, "terminal_monitor_ready")
  else
    debug_log("on_claude_ready called in unexpected state", {
      current_state = current_state,
      buffer = buf
    })
  end

  queue_stats.last_state_change = os.time()
end
```

**Pros**:
- Fixes the issue at the source
- Handles both code paths (with/without existing terminal)
- Minimal changes required
- No state machine definition changes

**Cons**:
- Two transitions in one function (less clean)
- Logs will show both transitions

### Option 2: Queue Command Always Transitions to STARTING

**Approach**: Always transition to STARTING when queueing, even without buffer

**Changes Required**:
```lua
-- In command-queue.lua:734-749
else
  -- Claude not ready, starting, or executing - queue the command
  debug_log("Queuing command due to Claude state", {...})

  -- Always transition to STARTING when queueing
  -- (was: if buf and current_state == CLAUDE_STATES.WAITING)
  if current_state == CLAUDE_STATES.WAITING then
    -- Don't require buf - we're expecting Claude to open
    transition_state(CLAUDE_STATES.STARTING, nil, "command_queued_awaiting_claude")
  end

  return M.queue_command(command_text, source, priority)
end
```

**Pros**:
- More accurate state representation (we ARE starting Claude)
- Single transition path
- Cleaner logs

**Cons**:
- State machine has buffer=nil during STARTING
- Might need validation in other places

### Option 3: Allow WAITING → READY Transition (Not Recommended)

**Approach**: Modify state machine to allow direct WAITING → READY

**Changes Required**:
```lua
-- In command-queue.lua:119-124
local valid_transitions = {
  [CLAUDE_STATES.WAITING] = { CLAUDE_STATES.STARTING, CLAUDE_STATES.READY },  -- Added READY
  [CLAUDE_STATES.STARTING] = { CLAUDE_STATES.READY, CLAUDE_STATES.WAITING },
  [CLAUDE_STATES.READY] = { CLAUDE_STATES.EXECUTING, CLAUDE_STATES.WAITING },
  [CLAUDE_STATES.EXECUTING] = { CLAUDE_STATES.READY, CLAUDE_STATES.WAITING }
}
```

**Pros**:
- Simplest code change
- No multi-step transitions needed

**Cons**:
- Breaks state machine semantics (STARTING state becomes optional)
- STARTING state loses its meaning
- Harder to debug (can't tell if Claude was already starting)
- Less accurate state representation

## Recommendations

### Priority 1: Implement Option 1 (Fix on_claude_ready)

**Rationale**:
- Safest fix with minimal risk
- Handles the actual bug in the callback
- No state machine definition changes
- Preserves state machine semantics

**Implementation**:
1. Modify `M.on_claude_ready()` to check current state
2. If WAITING, transition through STARTING to READY
3. If STARTING, transition directly to READY
4. Add debug logging for both paths

### Priority 2: Add State Machine Validation

**Add defensive checks**:
```lua
-- In command-queue.lua, add to on_claude_ready:
if current_state == CLAUDE_STATES.READY or current_state == CLAUDE_STATES.EXECUTING then
  debug_log("on_claude_ready called but already ready/executing", {
    current_state = current_state,
    buffer = buf
  })
  return  -- Don't transition
end
```

### Priority 3: Enhanced Debug Logging

**Add to transition_state**:
```lua
-- Log invalid transitions with more context
if not valid_transitions[old_state] or not vim.tbl_contains(valid_transitions[old_state], new_state) then
  debug_log("Invalid state transition attempted", {
    from = old_state,
    to = new_state,
    reason = reason,
    buffer = buf,
    valid_transitions_from_current = valid_transitions[old_state],
    queue_size = #command_queue,
    stack_trace = debug.traceback()  -- For debugging
  })
  return
end
```

## Next Steps

### Immediate Actions

1. **Implement Option 1**: Modify `on_claude_ready()` to handle WAITING state
2. **Test Scenario**:
   - Close all Claude terminals
   - Select command from `<leader>ac`
   - Verify command executes when Claude opens
3. **Verify Logs**: Confirm state transitions: WAITING → STARTING → READY

### Testing Checklist

- [ ] Command queued before Claude starts → executes when Claude ready
- [ ] Command selected with Claude already open → executes immediately
- [ ] Multiple commands queued → all execute in sequence
- [ ] State machine logs show valid transitions only
- [ ] No "Invalid state transition" messages
- [ ] Command queue size decreases after execution

### Long-Term Improvements

1. **State Machine Documentation**: Add state diagram to command-queue.lua
2. **Comprehensive State Tests**: Unit tests for all transition paths
3. **State Machine Visualization**: Debug command to show current state
4. **Timeout Handling**: If STARTING state persists too long, reset to WAITING

## Technical Architecture

### Current State Machine (Buggy)

```
┌─────────────────────────────────────────────────────────────┐
│                     User Interaction                        │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ├─ Claude Running?
                 │  ├─ Yes → Execute immediately
                 │  └─ No ↓
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ command_queue.send_command()                                │
│  - find_claude_terminal() → buf=nil, channel=nil           │
│  - current_state = WAITING                                  │
│  - Line 744: if buf and current_state == WAITING           │
│    [buf is nil, condition FALSE]                            │
│  - NO TRANSITION TO STARTING                                │
│  - queue_command() called                                   │
│  - State remains: WAITING                                   │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ picker.lua opens Claude Code                                │
│  - claude_code.toggle()                                     │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ TermOpen Event                                              │
│  - terminal-monitor.lua detects Claude                      │
│  - Channel validation succeeds                              │
│  - M.on_claude_ready(buf) called                           │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ on_claude_ready() [BUG HERE]                                │
│  - current_state = WAITING                                  │
│  - Attempts: transition_state(READY, ...)                  │
│  - Valid from WAITING: { STARTING } only                    │
│  - WAITING → READY is INVALID                               │
│  - Transition REJECTED                                      │
│  - Command processing never triggered                       │
└─────────────────────────────────────────────────────────────┘
                 ↓
           [END - BUG]
     Command sits in queue
```

### Fixed State Machine (Option 1)

```
┌─────────────────────────────────────────────────────────────┐
│                     User Interaction                        │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ command_queue.send_command()                                │
│  - Queue command                                            │
│  - State remains: WAITING                                   │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ picker.lua opens Claude Code                                │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ TermOpen Event                                              │
│  - M.on_claude_ready(buf) called                           │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ on_claude_ready() [FIXED]                                   │
│  - Check current_state                                      │
│  - if WAITING:                                              │
│    1. transition_state(STARTING, ...)    [VALID]            │
│    2. transition_state(READY, ...)       [VALID]            │
│  - else if STARTING:                                        │
│    1. transition_state(READY, ...)       [VALID]            │
│  - State now: READY                                         │
│  - Triggers: process_pending_commands()  [Line 167-173]     │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ process_pending_commands()                                  │
│  - Dequeue command                                          │
│  - Execute via nvim_chan_send                               │
│  - Command inserted into Claude terminal                    │
└─────────────────────────────────────────────────────────────┘
                 ↓
           [SUCCESS]
```

## Files Affected

### Primary File (Bug Location)
- **lua/neotex/plugins/ai/claude/core/command-queue.lua**
  - Line 819-827: `M.on_claude_ready()` - Needs state check
  - Line 744-746: `send_command()` - Context for why state isn't STARTING

### Related Files (Context)
- **lua/neotex/plugins/ai/claude/commands/picker.lua**
  - Line 350-365: Calls send_command and opens Claude

- **lua/neotex/plugins/ai/claude/core/terminal-monitor.lua**
  - Calls on_claude_ready when TermOpen fires

## References

### Related Reports
1. [020_command_insertion_autocommand_architecture.md](020_command_insertion_autocommand_architecture.md) - Research for event-driven implementation
2. [012_event_driven_command_insertion.md](../plans/012_event_driven_command_insertion.md) - Implementation plan

### Code Locations
1. command-queue.lua:819-827 - `M.on_claude_ready()` (bug location)
2. command-queue.lua:119-124 - State machine valid transitions
3. command-queue.lua:744-746 - Conditional STARTING transition
4. command-queue.lua:167-173 - Command processing trigger
5. picker.lua:350-365 - Command queueing and Claude opening

### External References
- Neovim state machine patterns
- Event-driven architecture best practices
- Command queue synchronization patterns

---

**Report Status**: Complete
**Root Cause**: Identified - Invalid state transition WAITING → READY
**Solution**: Implement Option 1 - Fix on_claude_ready() to handle WAITING state
**Priority**: High - Breaks recently implemented feature
**Next Action**: Create implementation plan and fix
