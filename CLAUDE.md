# NeoVim Configuration Guidelines

## Build/Test/Lint Commands
- **Lint**: `vim.keymap.set("n", "<leader>l", function() lint.try_lint() end)`
- **Format**: `vim.keymap.set({"n", "v"}, "<leader>mp", function() conform.format() end)`
- **Test**: `:TestNearest` (current test), `:TestFile` (all tests in file), `:TestSuite` (all tests), `:TestLast` (repeat)
- **Single test**: Position cursor on test function and run `:TestNearest`

## Code Style Guidelines
- **Indentation**: 2 spaces (no tabs)
- **Line length**: ~100 characters
- **Imports**: Top of file, ordered by dependency
- **Naming**: Lowercase with underscores for variables/functions
- **Functions**: Prefer local functions
- **Error handling**: Use pcall for operations that might fail
- **Comments**: Document keymaps and complex logic

## Directory Structure
- Core functionality in `lua/neotex/core/`
- Plugin configurations in `lua/neotex/plugins/`
- LSP settings in `lua/neotex/plugins/lsp/`
- Filetype-specific settings in `after/ftplugin/`

## Language-Specific Formatters
- **JavaScript/TypeScript**: prettier
- **Python**: isort + black (88 char line limit)
- **Lua**: stylua (double quotes, 2-space indent)
- **Markdown/CSS/HTML/YAML/JSON**: prettier