#!/bin/bash
# Claude Code SessionStart hook - signals Neovim when ready

if [ -n "$NVIM" ]; then
  nvim --server "$NVIM" --remote-send \
    ':lua require("neotex.plugins.ai.claude.utils.terminal-state").on_claude_ready()<CR>'
fi
