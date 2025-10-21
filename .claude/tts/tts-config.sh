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
# Only two categories are used in this simplified TTS system:
#   - completion: Task completion notifications
#   - permission: Tool permission requests
#
# All other event types (progress, error, session, etc.) are not supported
# in this simplified configuration focused on minimal, uniform notifications.

# Completion Notifications (Stop hook)
# Triggered when Claude completes a response and is ready for input
# Message format: "directory, branch"
TTS_COMPLETION_ENABLED=true

# Permission Requests (Notification hook)
# Triggered when Claude needs permission to use a tool
# Message format: "directory, branch" (same as completion)
TTS_PERMISSION_ENABLED=true

# Commands that don't require TTS notifications (space-separated list)
# These are typically informational commands that don't leave Claude waiting
TTS_SILENT_COMMANDS="/clear /help /version /status /list /list-plans /list-reports /list-summaries"

# ============================================================================
# Voice Characteristics
# ============================================================================
# Format: "pitch:speed"
#   pitch: 0-99 (0=lowest, 50=normal, 99=highest)
#   speed: words per minute (typical range: 120-220)
#
# All notifications use the same voice for consistency and simplicity.

# Unified voice parameters for all TTS notifications
TTS_VOICE_PARAMS="50:160"

# To customize voice characteristics:
#   TTS_VOICE_PARAMS="35:140"  # Lower, slower voice
#   TTS_VOICE_PARAMS="60:180"  # Higher, faster voice

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

# Debug mode: Log TTS invocations to .claude/data/logs/tts.log
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
