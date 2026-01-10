# Neovim Context README

## Purpose
Neovim-specific context for configuration development. Use these files for Lua patterns, plugin development, testing, and editor customization workflows. Extends core system context with Neovim/Lua domain knowledge.

## Canonical Sources
- Core system standards: `core/standards/`
- Orchestration patterns: `core/orchestration/`
- Artifact formats: `core/formats/`
- Status markers: `core/standards/status-markers.md`

## Neovim-Specific Files

### Domain
- `domain/neovim-api.md` - vim.api, vim.fn, vim.opt, vim.keymap patterns
- `domain/lua-patterns.md` - Module patterns, metatables, error handling idioms
- `domain/plugin-ecosystem.md` - lazy.nvim, plugin categories, selection criteria
- `domain/lsp-integration.md` - nvim-lspconfig, mason.nvim, completion engines

### Standards
- `standards/lua-style-guide.md` - Indentation, naming, module structure
- `standards/documentation-requirements.md` - README format, function docs
- `standards/testing-standards.md` - busted, plenary.nvim, assertion patterns

### Patterns
- `patterns/plugin-definition.md` - lazy.nvim specs, lazy loading, dependencies
- `patterns/keymapping.md` - vim.keymap.set, which-key, leader patterns
- `patterns/autocommand.md` - autocmd groups, common events, buffer-local

### Tools
- `tools/lazy-nvim.md` - Package manager installation, specs, lock files
- `tools/telescope.md` - Picker creation, extensions, finder/previewer/sorter
- `tools/treesitter.md` - Parser installation, queries, text objects

### Processes
- `processes/plugin-development.md` - Structure, testing, publishing workflow
- `processes/debugging.md` - :messages, print, DAP, profiling
- `processes/maintenance.md` - Updates, breaking changes, performance

### Templates
- Reserved for future template files

## Usage Guidance
- Start with nvim/CLAUDE.md for project-specific standards
- Use these context files for deep domain knowledge
- Load minimal context per task (relevant files only)
- Prefer nvim/docs/ for implementation details

## Directory Structure
```
neovim/
├── README.md              # This file
├── domain/                # Neovim/Lua concepts
│   ├── neovim-api.md
│   ├── lua-patterns.md
│   ├── plugin-ecosystem.md
│   └── lsp-integration.md
├── standards/             # Coding and documentation standards
│   ├── lua-style-guide.md
│   ├── documentation-requirements.md
│   └── testing-standards.md
├── patterns/              # Common configuration patterns
│   ├── plugin-definition.md
│   ├── keymapping.md
│   └── autocommand.md
├── tools/                 # Tool integrations
│   ├── lazy-nvim.md
│   ├── telescope.md
│   └── treesitter.md
├── processes/             # Development workflows
│   ├── plugin-development.md
│   ├── debugging.md
│   └── maintenance.md
└── templates/             # Reserved
```

## Navigation
- [Parent: Project Context](../README.md)
- [Core Context](../../core/README.md)
