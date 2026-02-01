#!/usr/bin/env bash
# Claude Code SessionStart hook - signals Neovim when ready
# Called by Claude Code when session starts (see ~/.claude/settings.json)
# Logs to /tmp/claude-ready-signal.log for debugging

LOG_FILE="/tmp/claude-ready-signal.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

if [ -n "$NVIM" ]; then
  log "Hook triggered, NVIM=$NVIM"

  # Use v:lua.require() syntax for correct Lua evaluation in Neovim
  # The module path must match the actual location of terminal-state.lua
  result=$(nvim --server "$NVIM" --remote-expr \
    'v:lua.require("neotex.plugins.ai.claude.claude-session.terminal-state").on_claude_ready()' \
    2>&1)
  exit_code=$?

  log "Result: ${result:-vim.NIL} (exit: $exit_code)"
else
  log "Hook triggered but NVIM not set (not running inside Neovim terminal)"
fi
