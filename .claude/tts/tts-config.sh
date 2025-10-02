#!/usr/bin/env bash
# TTS Configuration for Claude Code
#
# This file configures text-to-speech notifications for all Claude Code workflow events.
# Each notification category can be individually enabled/disabled and customized.
#
# Quick Start:
# 1. Enable/disable TTS globally: TTS_ENABLED=true|false
# 2. Enable/disable specific categories: TTS_*_ENABLED=true|false
# 3. Customize voice characteristics: TTS_*_VOICE="pitch:speed"
#    - Pitch: 0-99 (lower = deeper voice)
#    - Speed: Words per minute (typical range: 120-220)
#
# Example Customizations:
#   # Disable all progress updates
#   TTS_PROGRESS_ENABLED=false
#
#   # Make errors more alerting
#   TTS_ERROR_VOICE="20:120"  # Very low, very slow
#
#   # Use male voice
#   TTS_VOICE="en-us+m3"

# ============================================================================
# Global Settings
# ============================================================================

# Master enable/disable switch for all TTS notifications
TTS_ENABLED=true

# TTS engine to use (espeak-ng is default, alternatives: festival, pico-tts)
TTS_ENGINE="espeak-ng"

# Default voice (espeak-ng voices: en-us+f3=female, en-us+m3=male)
# Run 'espeak-ng --voices' to see all available voices
TTS_VOICE="en-us+f3"

# Default speech speed in words per minute
TTS_DEFAULT_SPEED=160

# ============================================================================
# Category Enablement
# ============================================================================
# Each category corresponds to different Claude Code workflow events.
# Disable categories you find too verbose or distracting.

# Completion Notifications (Stop hook)
# Triggered when Claude completes a response and is ready for input
TTS_COMPLETION_ENABLED=true

# Commands that don't require TTS notifications (space-separated list)
# These are typically informational commands that don't leave Claude waiting for input
TTS_SILENT_COMMANDS="/clear /help /version /status /list /list-plans /list-reports /list-summaries"

# Permission Requests (Notification hook - tool permission)
# Triggered when Claude needs permission to use a tool
TTS_PERMISSION_ENABLED=true

# Progress Updates (SubagentStop hook)
# Triggered when subagents complete tasks within larger workflows
TTS_PROGRESS_ENABLED=true

# Error Notifications (Stop hook with failure status)
# Triggered when commands complete with errors
TTS_ERROR_ENABLED=true

# Idle Reminders (Notification hook - idle >60s)
# Triggered when Claude waits for input for more than 60 seconds
TTS_IDLE_ENABLED=true

# Session Lifecycle (SessionStart, SessionEnd hooks)
# Triggered when sessions begin or end
TTS_SESSION_ENABLED=true

# Tool Execution (PreToolUse, PostToolUse hooks)
# Triggered before/after significant tool use
# NOTE: Disabled by default - can be very verbose
TTS_TOOL_ENABLED=false

# Prompt Acknowledgment (UserPromptSubmit hook)
# Triggered when user submits a prompt
# NOTE: Disabled by default - quick confirmation useful when multitasking
TTS_PROMPT_ACK_ENABLED=false

# Compact Operations (PreCompact hook)
# Triggered before context compaction
# NOTE: Disabled by default - rarely needed
TTS_COMPACT_ENABLED=false

# ============================================================================
# Voice Characteristics per Category
# ============================================================================
# Format: "pitch:speed"
#   pitch: 0-99 (0=lowest, 50=normal, 99=highest)
#   speed: words per minute (typical range: 120-220)
#
# Different voice characteristics help distinguish notification types
# without needing to listen to the full message.

# Completion: Normal voice for task completion
TTS_COMPLETION_VOICE="50:160"

# Permission: Higher pitch, faster for urgency
TTS_PERMISSION_VOICE="60:180"

# Progress: Lower pitch, faster for background info
TTS_PROGRESS_VOICE="40:180"

# Error: Low pitch, slower for alert/attention
TTS_ERROR_VOICE="35:140"

# Idle: Normal pitch, slower for gentle reminder
TTS_IDLE_VOICE="50:140"

# Session: Normal voice for lifecycle events
TTS_SESSION_VOICE="50:160"

# Tool: Very low, very fast for minimal intrusion
TTS_TOOL_VOICE="30:200"

# Prompt Ack: High pitch, very fast for quick confirmation
TTS_PROMPT_ACK_VOICE="70:220"

# Compact: Normal voice
TTS_COMPACT_VOICE="50:160"

# ============================================================================
# Message Verbosity
# ============================================================================

# Include directory name in context messages
TTS_INCLUDE_DIRECTORY=true

# Include git branch in context messages
TTS_INCLUDE_BRANCH=true

# Include operation duration in messages (only for long operations)
TTS_INCLUDE_DURATION=false

# ============================================================================
# Advanced Options
# ============================================================================

# Minimum operation duration in milliseconds to trigger TTS
# Operations faster than this won't generate notifications
TTS_MIN_DURATION_MS=1000

# Enable state file support for detailed summaries
# When enabled, commands can write detailed state to .claude/state/last-completion.json
# for richer TTS messages
TTS_STATE_FILE_ENABLED=false

# Debug mode: Log TTS invocations to .claude/logs/tts.log
TTS_DEBUG=true

# ============================================================================
# Extension Points
# ============================================================================
# To add new TTS categories:
# 1. Add TTS_YOURCATEGORY_ENABLED=true|false above
# 2. Add TTS_YOURCATEGORY_VOICE="pitch:speed" above
# 3. Update .claude/tts/tts-messages.sh with generate_yourcategory_message()
# 4. Update .claude/hooks/tts-dispatcher.sh to handle the new category
# 5. Register the hook in .claude/settings.local.json
