#!/usr/bin/env bash
# Claude Code SessionStart hook - signals Neovim when ready

if [ -n "$NVIM" ]; then
  # Use --remote-expr to execute Lua directly in Neovim context
  # This avoids sending keystrokes to the terminal window
  nvim --server "$NVIM" --remote-expr \
    'luaeval("require(\"neotex.plugins.ai.claude.utils.terminal-state\").on_claude_ready()")' \
    >/dev/null 2>&1
fi
