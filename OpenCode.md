# OpenCode Configuration

## Build/Test/Lint Commands
- **Run all tests**: `./.claude/tests/run_all_tests.sh [--verbose]`
- **Run single test**: `bash /path/to/test_file.sh`
- **Neovim tests**: `:TestNearest`, `:TestFile`, `:TestSuite`, `:TestLast`
- **Lint (Neovim)**: `<leader>l` (nvim-lint)
- **Format (Neovim)**: `<leader>mp` (conform.nvim)
- **LaTeX compile**: `<leader>lc`, view with `<leader>lv`

## Code Style Guidelines
- **Indentation**: 2 spaces, expandtab
- **Line length**: ~100 characters (soft limit)
- **Naming**: snake_case for variables/functions, PascalCase for module tables
- **Imports**: At top of file, ordered by dependency
- **Error handling**: Use `pcall()` in Lua, `set -euo pipefail` in bash
- **Character encoding**: UTF-8 only, no emojis in file content

## Project Structure
- Core Neovim config: `lua/neotex/core/`, `lua/neotex/plugins/`
- Claude commands: `.claude/commands/`
- Tests: `.claude/tests/test_*.sh`
- Every directory must have README.md with purpose, modules, navigation links
- Follow existing patterns in neighboring files before adding new dependencies