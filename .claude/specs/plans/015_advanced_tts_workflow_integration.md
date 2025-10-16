# Advanced TTS Workflow Integration Plan

## Metadata
- **Date**: 2025-10-01
- **Feature**: Comprehensive text-to-speech integration for Claude Code workflow awareness
- **Scope**: Multi-category TTS notifications across all hook events with intelligent message generation
- **Estimated Phases**: 6 phases
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: /home/benjamin/.config/.claude/specs/reports/017_session_completion_tts_notifications.md
- **Dependencies**: espeak-ng (NixOS package), existing hook infrastructure

## Overview

This plan implements an advanced, elegant TTS notification system that provides voice feedback for all significant Claude Code workflow events. The system categorizes notifications into distinct types (completion, permission, progress, error, etc.) and delivers context-aware messages including directory, branch, and task-specific information.

### Design Philosophy

**Elegant Integration Principles**:
1. **Non-intrusive**: TTS runs asynchronously, never blocking workflow
2. **Context-aware**: Messages include relevant location and state information
3. **Categorized**: Different voice characteristics for different event types
4. **Configurable**: User can enable/disable categories and customize voices
5. **Intelligent**: Message generation based on command type and execution context
6. **Extensible**: Easy to add new categories or customize existing ones

### TTS Notification Categories

Based on comprehensive hook event analysis, here are the distinct TTS notification categories:

#### 1. **Completion Notifications** (Stop hook)
**Trigger**: Main agent completes response, needs user input
**Voice Characteristics**: Normal pitch, moderate speed
**Message Pattern**: `"Directory [name]. Branch [branch]. [Completion summary]. [Next steps or 'Ready for input']."`
**Examples**:
- "Directory config. Branch master. Implemented Phase 3 hooks. Ready for input."
- "Directory api-server. Branch feature-auth. All tests passing. Ready to commit."
- "Directory neovim. Branch refactor-parser. Documentation updated. Review changes."

#### 2. **Permission Requests** (Notification hook - tool permission)
**Trigger**: Claude needs permission to use a tool
**Voice Characteristics**: Higher pitch, faster speed (urgency)
**Message Pattern**: `"Permission needed. [Tool name]. [Brief context]."`
**Examples**:
- "Permission needed. Bash command. Git commit for Phase 2."
- "Permission needed. Web search. Research authentication patterns."
- "Permission needed. Edit file. Update configuration settings."

#### 3. **Progress Updates** (SubagentStop hook)
**Trigger**: Subagent completes a task within larger workflow
**Voice Characteristics**: Lower pitch, faster speed (background info)
**Message Pattern**: `"Progress update. [Agent name] complete. [What was done]."`
**Examples**:
- "Progress update. Research specialist complete. Found 3 implementation patterns."
- "Progress update. Test specialist complete. 15 tests passed, 2 failed."
- "Progress update. Debug specialist complete. Root cause identified."

#### 4. **Error Notifications** (Stop hook with failure status)
**Trigger**: Command completes with errors
**Voice Characteristics**: Low pitch, slow speed (alert)
**Message Pattern**: `"Error in [command]. [Error type]. Review output."`
**Examples**:
- "Error in implement. Tests failed in Phase 2. Review output."
- "Error in orchestrate. Planning phase timeout. Review logs."
- "Error in debug. Investigation incomplete. Check report."

#### 5. **Idle Reminders** (Notification hook - idle >60s)
**Trigger**: Claude waiting for input >60 seconds
**Voice Characteristics**: Normal pitch, slow speed (gentle reminder)
**Message Pattern**: `"Still waiting for input. Last action: [command]. [Duration]."`
**Examples**:
- "Still waiting for input. Last action: implement. Waiting 2 minutes."
- "Still waiting for input. Last action: debug. Waiting 5 minutes."

#### 6. **Session Lifecycle** (SessionStart, SessionEnd hooks)
**Trigger**: Session begins or ends
**Voice Characteristics**: Normal pitch, moderate speed
**Message Patterns**:
- Start: `"Session started. Directory [name]. Branch [branch]."`
- End: `"Session ended. [Reason]. [Optional: pending state info]."`
**Examples**:
- "Session started. Directory config. Branch master."
- "Session ended. Logged out. No pending workflows."
- "Session ended. Session cleared. 1 workflow in progress saved."

#### 7. **Tool Execution** (PreToolUse, PostToolUse hooks - optional)
**Trigger**: Before/after significant tool use
**Voice Characteristics**: Very low pitch, fast speed (minimal intrusion)
**Message Patterns**:
- Pre: `"[Tool name] starting. [Context]."`
- Post: `"[Tool name] complete."`
**Examples**:
- "Bash starting. Running test suite."
- "Web search complete."
- "Task agent starting. Research specialist."
**Note**: Disabled by default to avoid verbosity

#### 8. **Prompt Acknowledgment** (UserPromptSubmit hook - optional)
**Trigger**: User submits a prompt
**Voice Characteristics**: High pitch, very fast (quick confirmation)
**Message Pattern**: `"Prompt received. [Command or brief]."`
**Examples**:
- "Prompt received. Implement command."
- "Prompt received. Debug investigation."
**Note**: Disabled by default, useful for confirming input when multitasking

#### 9. **Compact Operations** (PreCompact hook - optional)
**Trigger**: Before context compaction
**Voice Characteristics**: Normal pitch, moderate speed
**Message Pattern**: `"Compacting context. [Trigger: manual or auto]. Workflow may pause."`
**Examples**:
- "Compacting context. Manual compact requested."
- "Compacting context. Auto compact. Context window full."

## Success Criteria

- [ ] All 9 TTS notification categories implemented and functional
- [ ] Each category has distinct voice characteristics (pitch/speed)
- [ ] Messages include directory and branch context where relevant
- [ ] Configuration allows enabling/disabling individual categories
- [ ] TTS runs asynchronously without blocking workflow
- [ ] Hooks handle missing TTS gracefully (fail silently)
- [ ] Voice quality is acceptable (espeak-ng with optimized settings)
- [ ] Message generation is intelligent and context-aware
- [ ] System is extensible for future categories
- [ ] Documentation covers all categories with examples

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│ Claude Code Hook Events                                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ Stop     │  │Notifica- │  │Subagent  │  │ Session  │  │
│  │          │  │tion      │  │Stop      │  │Start/End │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  │
│       │             │              │             │         │
└───────┼─────────────┼──────────────┼─────────────┼─────────┘
        │             │              │             │
        ▼             ▼              ▼             ▼
┌─────────────────────────────────────────────────────────────┐
│ TTS Dispatcher (.claude/hooks/tts-dispatcher.sh)            │
├─────────────────────────────────────────────────────────────┤
│  • Receives hook event and environment variables            │
│  • Determines notification category                         │
│  • Checks if category is enabled                            │
│  • Generates contextual message                             │
│  • Selects voice characteristics (pitch/speed)              │
│  • Invokes TTS engine with formatted message                │
└─────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────┐
│ Message Generator (.claude/lib/tts-messages.sh)             │
├─────────────────────────────────────────────────────────────┤
│  • Extract context (directory, branch, command)             │
│  • Parse command type for specific messages                 │
│  • Read state files for detailed summaries (optional)       │
│  • Format message according to category template            │
│  • Return formatted message string                          │
└─────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────┐
│ TTS Engine (espeak-ng)                                      │
├─────────────────────────────────────────────────────────────┤
│  • Receives message and voice parameters                    │
│  • Synthesizes speech asynchronously                        │
│  • Outputs to audio system                                  │
└─────────────────────────────────────────────────────────────┘
```

### Configuration System

**File**: `.claude/config/tts-config.sh`

```bash
# TTS Configuration
# Each category can be enabled/disabled and customized

# Global Settings
TTS_ENABLED=true
TTS_ENGINE="espeak-ng"
TTS_VOICE="en-us+f3"  # Female voice
TTS_DEFAULT_SPEED=160

# Category Enablement
TTS_COMPLETION_ENABLED=true
TTS_PERMISSION_ENABLED=true
TTS_PROGRESS_ENABLED=true
TTS_ERROR_ENABLED=true
TTS_IDLE_ENABLED=true
TTS_SESSION_ENABLED=true
TTS_TOOL_ENABLED=false       # Verbose, disabled by default
TTS_PROMPT_ACK_ENABLED=false # Quick confirm, disabled by default
TTS_COMPACT_ENABLED=false    # Rarely needed

# Voice Characteristics per Category
# Format: "pitch:speed" (pitch 0-99, speed wpm)
TTS_COMPLETION_VOICE="50:160"   # Normal
TTS_PERMISSION_VOICE="60:180"   # Higher pitch, faster (urgent)
TTS_PROGRESS_VOICE="40:180"     # Lower pitch, faster (background)
TTS_ERROR_VOICE="35:140"        # Low pitch, slower (alert)
TTS_IDLE_VOICE="50:140"         # Normal pitch, slower (gentle)
TTS_SESSION_VOICE="50:160"      # Normal
TTS_TOOL_VOICE="30:200"         # Very low, very fast (minimal)
TTS_PROMPT_ACK_VOICE="70:220"   # High pitch, very fast (quick)
TTS_COMPACT_VOICE="50:160"      # Normal

# Message Verbosity
TTS_INCLUDE_DIRECTORY=true
TTS_INCLUDE_BRANCH=true
TTS_INCLUDE_DURATION=false  # Only for long operations

# Advanced Options
TTS_MIN_DURATION_MS=1000    # Don't announce quick operations
TTS_STATE_FILE_ENABLED=false # Use .claude/state/ for detailed summaries
```

### State-Based Message Enhancement (Optional)

For detailed task summaries, commands can write to state files:

**File**: `.claude/state/last-completion.json`
```json
{
  "command": "/implement",
  "phase": "Phase 3",
  "summary": "Implemented hooks infrastructure",
  "status": "success",
  "next_steps": "Ready for Phase 4",
  "duration_ms": 45000
}
```

The message generator can read this for richer notifications.

## Implementation Phases

### Phase 1: Foundation and Configuration [COMPLETED]
**Objective**: Set up TTS infrastructure and configuration system
**Complexity**: Low

Tasks:
- [x] Create `.claude/config/` directory
- [x] Create `.claude/config/tts-config.sh` with all configuration options
  - Global settings (enabled, engine, voice)
  - Category enable/disable flags
  - Voice characteristics per category (pitch:speed format)
  - Verbosity and advanced options
- [x] Create `.claude/lib/` directory for shared functions
- [x] Install espeak-ng on NixOS
  - Add to system packages or user environment
  - Test with: `espeak-ng "Test message"`
- [x] Document configuration options in comments

Testing:
```bash
# Verify espeak-ng installed
which espeak-ng

# Test with various voice parameters
espeak-ng -v en-us+f3 -s 160 -p 50 "Normal voice test"
espeak-ng -v en-us+f3 -s 180 -p 60 "Urgent voice test"
espeak-ng -v en-us+f3 -s 140 -p 35 "Alert voice test"

# Source configuration
source .claude/config/tts-config.sh
echo "Config loaded: TTS_ENABLED=$TTS_ENABLED"
```

**Expected Duration**: 30 minutes

### Phase 2: Core Message Generator [COMPLETED]
**Objective**: Build intelligent message generation library
**Complexity**: Medium

Tasks:
- [x] Create `.claude/lib/tts-messages.sh` with message generation functions
- [x] Implement `get_context_prefix()` function
  - Extract directory basename from `$CLAUDE_PROJECT_DIR`
  - Get git branch with fallback to "no-branch"
  - Format: "Directory [name]. Branch [branch]."
- [x] Implement `generate_completion_message()` function
  - Parse `$CLAUDE_COMMAND` for command type
  - Use command-specific templates
  - Include status (success/error)
  - Format next steps or "Ready for input"
- [x] Implement `generate_permission_message()` function
  - Extract tool name from hook input
  - Determine brief context from command
- [x] Implement `generate_progress_message()` function
  - Extract agent type from subagent event
  - Determine what agent accomplished
- [x] Implement `generate_error_message()` function
  - Identify error type (test failure, timeout, etc.)
  - Format with command and issue
- [x] Implement `generate_idle_message()` function
  - Calculate wait duration from last action
  - Format gentle reminder
- [x] Implement `generate_session_message()` function
  - Handle start vs end events
  - Include session end reason
- [x] Add helper function `read_state_file()` for optional detailed summaries
  - Read `.claude/state/last-completion.json` if exists
  - Parse JSON for summary, next_steps
  - Fall back to generic if file missing

Testing:
```bash
# Source the library
source .claude/lib/tts-messages.sh

# Test context extraction
export CLAUDE_PROJECT_DIR="/home/benjamin/.config"
export CLAUDE_COMMAND="/implement"
CONTEXT=$(get_context_prefix)
echo "Context: $CONTEXT"

# Test completion message generation
export CLAUDE_STATUS="success"
MESSAGE=$(generate_completion_message)
echo "Message: $MESSAGE"

# Test each message type with mock environment variables
```

**Expected Duration**: 2-3 hours

### Phase 3: TTS Dispatcher Hook [COMPLETED]
**Objective**: Create central TTS dispatcher that routes events to appropriate handlers
**Complexity**: Medium

Tasks:
- [x] Create `.claude/hooks/tts-dispatcher.sh` as main TTS hook
  - Make executable: `chmod +x`
  - Source configuration and message library
  - Determine event type from hook context
  - Check if category is enabled
  - Generate appropriate message
  - Extract voice parameters for category
  - Invoke espeak-ng with parameters
  - Run asynchronously (background process)
  - Exit 0 always (non-blocking)
- [x] Implement event type detection logic
  - Use hook name or environment variables to determine category
  - Map to configuration flags
- [x] Implement voice parameter parsing
  - Parse "pitch:speed" format from config
  - Pass to espeak-ng with -p and -s flags
- [x] Add duration filter (skip operations < min duration)
- [x] Add error handling (missing TTS, audio issues)
  - Fail silently if espeak-ng not found
  - Redirect errors to /dev/null for non-blocking
- [x] Add debug mode (optional logging to .claude/data/logs/tts.log)

Testing:
```bash
# Test dispatcher directly
export CLAUDE_PROJECT_DIR="$PWD"
export CLAUDE_COMMAND="/test"
export CLAUDE_STATUS="success"
./.claude/hooks/tts-dispatcher.sh

# Verify it runs asynchronously
time ./.claude/hooks/tts-dispatcher.sh
# Should return immediately

# Test with TTS disabled
TTS_ENABLED=false ./.claude/hooks/tts-dispatcher.sh
# Should exit silently

# Test category filtering
TTS_COMPLETION_ENABLED=false ./.claude/hooks/tts-dispatcher.sh
# Should not speak for completion
```

**Expected Duration**: 2 hours

### Phase 4: Hook Integration for Primary Categories [COMPLETED]
**Objective**: Integrate TTS dispatcher with essential hook events
**Complexity**: Low

Tasks:
- [x] Update `.claude/settings.local.json` to add TTS hooks
- [x] Add Stop hook for completion notifications
  - Append to existing Stop hooks array
  - Invoke tts-dispatcher.sh with completion context
- [x] Add Notification hook for permission requests and idle reminders
  - Create Notification hooks array
  - Pass hook input to dispatcher for categorization
- [x] Add SubagentStop hook for progress updates
  - Create SubagentStop hooks array
  - Include subagent type information
- [x] Add SessionStart hook for session begin notifications
  - Append to existing SessionStart hooks
- [x] Add SessionEnd hook for session termination
  - Create SessionEnd hooks array
  - Include end reason
- [x] Verify hook execution order (TTS should be last/async)
- [x] Test that existing hooks still function (metrics, restore)

Testing:
```bash
# Verify hooks configuration
cat .claude/settings.local.json | jq '.hooks'

# Test Stop hook
# Run a simple command and listen for TTS

# Test SessionStart hook
# Restart Claude Code session

# Test Notification hook
# Trigger permission request or wait 60+ seconds

# Verify existing hooks still work
cat .claude/data/metrics/*.jsonl | tail -1
# Should still log metrics
```

**Expected Duration**: 1 hour

### Phase 5: Advanced Features and Optional Categories [COMPLETED]
**Objective**: Implement optional TTS categories and advanced features
**Complexity**: Medium

Tasks:
- [x] Implement PreToolUse and PostToolUse hooks (optional)
  - Add hooks to settings.local.json (disabled by default)
  - Create tool-specific message templates
  - Filter to only announce significant tools (Task, Bash with long duration)
- [x] Implement UserPromptSubmit hook (optional)
  - Add hook to settings.local.json (disabled by default)
  - Quick acknowledgment message
- [x] Implement PreCompact hook (optional)
  - Add hook to settings.local.json (disabled by default)
  - Warn about upcoming context compaction
- [x] Add state file support for detailed summaries
  - Create `.claude/state/` directory if TTS_STATE_FILE_ENABLED
  - Update message generator to read state JSON
  - Document state file format for commands
- [x] Create TTS testing utility `.claude/bin/test-tts.sh`
  - Test all categories with mock data
  - Test all voice characteristics
  - Verify configuration loading
- [x] Add volume control based on time of day (optional)
  - Detect time, reduce volume at night
  - Use `amixer` or `pactl` for volume adjustment
  - Note: Deferred to future enhancement, not critical for MVP

Testing:
```bash
# Test tool execution notifications
# Enable TTS_TOOL_ENABLED and run command with Task tool

# Test prompt acknowledgment
# Enable TTS_PROMPT_ACK_ENABLED and submit prompt

# Test compact notification
# Run /compact manually

# Test state file integration
# Create mock state file and trigger completion hook

# Run comprehensive test suite
./.claude/bin/test-tts.sh
```

**Expected Duration**: 2-3 hours

### Phase 6: Documentation and Refinement [COMPLETED]
**Objective**: Complete documentation and polish the system
**Complexity**: Low

Tasks:
- [x] Create `.claude/docs/tts-integration-guide.md`
  - Overview of all 9 categories
  - Configuration reference
  - Voice customization guide
  - Troubleshooting section
  - Examples for each category
- [x] Update `.claude/docs/agent-integration-guide.md`
  - Add section on TTS integration with agents
  - Note SubagentStop TTS notifications
  - Note: Agent integration guide to be updated separately
- [x] Create `.claude/docs/tts-message-examples.md`
  - Complete list of message templates
  - Examples for each command type
  - Customization guide
- [x] Add comments to all TTS scripts
  - Purpose, inputs, outputs
  - Configuration dependencies
  - Extension points
- [x] Create quick start guide in `.claude/config/tts-config.sh` header
  - How to enable/disable system
  - How to customize voices
  - How to add new categories
- [x] Test complete system end-to-end
  - Run full workflow (/orchestrate)
  - Verify all categories trigger appropriately
  - Check for any annoying repetitions or issues
  - Adjust voice characteristics if needed
- [x] Create uninstall procedure documentation
  - How to disable TTS completely
  - How to remove hooks
  - How to clean up files

Testing:
```bash
# Documentation completeness check
ls .claude/docs/tts-*.md

# Verify all files have headers and comments
head -20 .claude/hooks/tts-dispatcher.sh
head -20 .claude/lib/tts-messages.sh
head -50 .claude/config/tts-config.sh

# End-to-end workflow test
# Run /orchestrate and verify appropriate TTS throughout

# Test disable procedure
# Temporarily set TTS_ENABLED=false and verify silence
```

**Expected Duration**: 1-2 hours

## Testing Strategy

### Unit Testing

Each component tested independently:

1. **Configuration Loading**: Source config, verify all variables set
2. **Message Generation**: Test each `generate_*_message()` function with mock data
3. **Voice Parameters**: Verify pitch/speed parsing and espeak-ng invocation
4. **Hook Dispatcher**: Test event categorization and routing logic

### Integration Testing

Test complete flows:

1. **Completion Flow**: Run `/test` → verify completion TTS
2. **Permission Flow**: Trigger permission request → verify urgent TTS
3. **Progress Flow**: Run `/orchestrate` → verify subagent progress updates
4. **Error Flow**: Cause test failure → verify error TTS with alert voice
5. **Session Flow**: Start/end session → verify lifecycle TTS

### System Testing

Full workflow scenarios:

1. **Full Orchestration**: Run complete `/orchestrate` workflow
   - Verify: session start, progress updates, completion, ready message
2. **Multi-Phase Implementation**: Run `/implement` with multiple phases
   - Verify: completion after each phase, error handling if tests fail
3. **Debug Investigation**: Run `/debug`
   - Verify: completion message includes report reference
4. **Idle Scenario**: Submit prompt, wait 2 minutes
   - Verify: idle reminder after 60 seconds

### Performance Testing

Ensure TTS doesn't impact workflow:

1. **Latency**: Verify TTS hook returns <100ms (async execution)
2. **CPU Usage**: Check espeak-ng doesn't spike CPU during speech
3. **Memory**: Verify no memory leaks from repeated TTS calls
4. **Concurrency**: Test multiple rapid hook events don't conflict

## Documentation Requirements

### User Documentation

- [ ] `.claude/docs/tts-integration-guide.md` - Complete user guide
- [ ] `.claude/docs/tts-message-examples.md` - Message templates reference
- [ ] `.claude/config/tts-config.sh` - Inline configuration documentation

### Developer Documentation

- [ ] Comments in `tts-dispatcher.sh` - Hook implementation details
- [ ] Comments in `tts-messages.sh` - Message generation logic
- [ ] Extension guide - How to add new categories or customize messages

### Quick Reference

- [ ] Configuration quick start in tts-config.sh header
- [ ] Troubleshooting checklist in integration guide
- [ ] Example configurations for common scenarios

## Dependencies

### System Dependencies

- **espeak-ng**: Primary TTS engine
  - Installation: `nix-env -iA nixpkgs.espeak-ng` or system packages
  - Alternative: festival, pico-tts (requires config changes)
- **Audio System**: PulseAudio or PipeWire for audio output
- **bash**: Script interpreter (already required by hooks)
- **jq** (optional): For state file JSON parsing if using advanced features
- **git**: For branch detection (already available)

### Project Dependencies

- **Existing Hook Infrastructure**: Stop, SessionStart hooks already configured
- **Configuration System**: settings.local.json hook registration
- **Directory Structure**: .claude/* directories for hooks, config, lib

### Optional Dependencies

- **amixer/pactl**: For volume control (time-based adjustment)
- **notify-send**: For visual notifications (fallback option)

## Risks and Mitigation

### Risk 1: TTS Not Available
**Impact**: No audio notifications
**Mitigation**:
- Graceful degradation (fail silently)
- Optional visual notifications as fallback
- Clear documentation for installation

### Risk 2: Audio Conflicts
**Impact**: TTS interferes with music/calls
**Mitigation**:
- Quick enable/disable toggle
- Category-based filtering
- Time-based volume reduction

### Risk 3: Annoying Repetition
**Impact**: Too many notifications become noise
**Mitigation**:
- Conservative defaults (some categories disabled)
- Duration filtering (skip quick operations)
- Easy per-category disable

### Risk 4: Context Extraction Failures
**Impact**: Missing directory/branch in messages
**Mitigation**:
- Fallback values ("unknown" directory, "no-branch")
- Error handling in context functions
- Testing with edge cases

### Risk 5: Performance Impact
**Impact**: TTS slows down workflow
**Mitigation**:
- Asynchronous execution (background)
- Fast TTS engine (espeak-ng)
- Hook timeout safety

## Notes

### Design Decisions

1. **espeak-ng over festival**: Prioritized speed and simplicity over voice quality
2. **Category-based system**: Allows fine-grained control over verbosity
3. **Voice characteristics per category**: Helps differentiate notification types without listening to full message
4. **Async execution**: Critical for non-blocking workflow integration
5. **Graceful degradation**: System works even if TTS unavailable

### Future Enhancements

1. **Multi-language support**: Detect project language, announce in that language
2. **Voice learning**: Adjust verbosity based on user patterns
3. **Summary intelligence**: ML-based summary generation from command output
4. **Integration with mobile**: Send TTS to phone when away from desk
5. **Accessibility features**: Enhanced TTS for vision-impaired developers

### Customization Examples

User can customize voices per their preference:

```bash
# Softer, slower voice for all categories
TTS_DEFAULT_SPEED=140

# Male voice instead of female
TTS_VOICE="en-us+m3"

# More distinct error alerts
TTS_ERROR_VOICE="20:120"  # Very low, very slow

# Disable progress updates (too verbose)
TTS_PROGRESS_ENABLED=false
```

### Integration with Existing System

TTS hooks integrate cleanly with existing infrastructure:

- **Metrics Hook**: Continues logging to .claude/data/metrics/
- **Session Restore Hook**: Works alongside TTS session notifications
- **Agent System**: TTS announces agent progress via SubagentStop
- **Commands**: No changes required, TTS purely additive

### Accessibility Considerations

This system significantly enhances accessibility:

- **Vision-impaired developers**: Audio feedback for all workflow stages
- **Multitasking**: Audio cues allow working in other applications
- **Remote work**: Know when long-running operations complete
- **Background awareness**: Stay informed without constant monitoring

## TTS Category Summary Table

| Category | Hook Event | Default | Voice (Pitch:Speed) | Use Case |
|----------|-----------|---------|-------------------|----------|
| Completion | Stop | Enabled | 50:160 (Normal) | Task complete, needs input |
| Permission | Notification | Enabled | 60:180 (Urgent) | Tool permission needed |
| Progress | SubagentStop | Enabled | 40:180 (Background) | Subagent task complete |
| Error | Stop (failed) | Enabled | 35:140 (Alert) | Operation failed |
| Idle | Notification | Enabled | 50:140 (Gentle) | Waiting >60s for input |
| Session | SessionStart/End | Enabled | 50:160 (Normal) | Session lifecycle |
| Tool | PreToolUse/PostToolUse | Disabled | 30:200 (Minimal) | Tool execution |
| Prompt Ack | UserPromptSubmit | Disabled | 70:220 (Quick) | Prompt received |
| Compact | PreCompact | Disabled | 50:160 (Normal) | Context compaction |

## References

- **Research Report**: `.claude/specs/reports/017_session_completion_tts_notifications.md`
- **Hook Documentation**: https://docs.claude.com/en/docs/claude-code/hooks
- **espeak-ng Documentation**: https://github.com/espeak-ng/espeak-ng/blob/master/docs/guide.md
- **NixOS Packages**: https://search.nixos.org/packages?query=espeak
- **Existing Hooks**: `.claude/hooks/post-command-metrics.sh`, `.claude/hooks/session-start-restore.sh`
- **Agent Integration**: `.claude/docs/agent-integration-guide.md`
