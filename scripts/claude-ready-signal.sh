#!/usr/bin/env bash
# Claude Code SessionStart hook - signals Neovim when ready

if [ -n "$NVIM" ]; then
  # Escape terminal mode first (<C-\><C-n>), then execute Lua command
  # This prevents the command from appearing as text in Claude's terminal
  nvim --server "$NVIM" --remote-send \
    '<C-\\><C-n>:lua require("neotex.plugins.ai.claude.utils.terminal-state").on_claude_ready()<CR>'
fi
