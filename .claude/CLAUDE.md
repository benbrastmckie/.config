# Neovim Configuration Development System

A structured task management and agent orchestration system for Neovim configuration maintenance, specializing in Lua development, plugin management, and editor customization.

## Quick Reference

- **Task List**: @.claude/specs/TODO.md
- **Machine State**: @.claude/specs/state.json
- **Error Tracking**: @.claude/specs/errors.json
- **Architecture**: @.claude/ARCHITECTURE.md

## System Overview

This system manages the development and maintenance of a comprehensive Neovim configuration. The development workflow uses numbered tasks with structured research → plan → implement cycles.

### Project Structure

```
nvim/
├── init.lua                     # Main entry point
├── lua/neotex/                  # Main configuration namespace
│   ├── bootstrap.lua            # Plugin system initialization
│   ├── config/                  # Core settings (options, keymaps, autocmds)
│   ├── core/                    # Fundamental utilities
│   ├── plugins/                 # Plugin configurations by category
│   │   ├── ai/                  # AI integrations (Claude, Goose, Avante)
│   │   ├── editor/              # Editor enhancements (telescope, which-key)
│   │   ├── lsp/                 # Language server integration
│   │   ├── text/                # Format-specific tools (LaTeX, Markdown)
│   │   ├── tools/               # Development tools (git, snippets)
│   │   └── ui/                  # UI components (neo-tree, lualine)
│   └── util/                    # Utility functions
├── after/                       # Post-load configurations (ftplugin)
├── docs/                        # Documentation
├── tests/                       # Test suites
└── .claude/specs/               # Task management artifacts
```

## Task Management

### Status Markers
Tasks progress through these states:
- `[NOT STARTED]` - Initial state
- `[RESEARCHING]` → `[RESEARCHED]` - Research phase
- `[PLANNING]` → `[PLANNED]` - Planning phase
- `[IMPLEMENTING]` → `[COMPLETED]` - Implementation phase
- `[BLOCKED]`, `[ABANDONED]`, `[PARTIAL]` - Terminal/exception states

### Task Artifact Paths
```
.claude/specs/{NUMBER}_{SLUG}/
├── reports/                    # Research artifacts
│   └── research-{NNN}.md
├── plans/                      # Implementation plans
│   └── implementation-{NNN}.md
└── summaries/                  # Completion summaries
    └── implementation-summary-{DATE}.md
```

### Language-Based Routing

Tasks have a `Language` field that determines tool selection:

| Language | Research Tools | Implementation Tools |
|----------|----------------|---------------------|
| `lua` | WebSearch, WebFetch, Read, Grep | Read, Write, Edit, Bash(nvim:*) |
| `general` | WebSearch, WebFetch, Read | Read, Write, Edit, Bash |
| `meta` | Read, Grep, Glob | Write, Edit |

## Command Workflows

### /task - Create or manage tasks
```
/task "Description"          # Create new task
/task --recover 343-345      # Recover from archive
/task --divide 326           # Split into subtasks
/task --sync                 # Sync TODO.md with state.json
/task --abandon 343-345      # Archive tasks
```

### /research N [focus] - Research a task
1. Validate task exists
2. Update status to [RESEARCHING]
3. Execute research (language-routed)
4. Create report in .claude/specs/{N}_{SLUG}/reports/
5. Update status to [RESEARCHED]
6. Git commit

### /plan N - Create implementation plan
1. Validate task is [RESEARCHED] or [NOT STARTED]
2. Update status to [PLANNING]
3. Create phased plan with steps
4. Write to .claude/specs/{N}_{SLUG}/plans/
5. Update status to [PLANNED]
6. Git commit

### /implement N - Execute implementation
1. Validate task is [PLANNED] or [IMPLEMENTING]
2. Load plan, find resume point
3. Update status to [IMPLEMENTING]
4. Execute phases sequentially
5. Update status to [COMPLETED]
6. Create summary, git commit

### /revise N - Create new plan version
Increments plan version (implementation-002.md, etc.)

### /review - Analyze codebase
Code review and architecture analysis

### /todo - Archive completed tasks
Moves completed/abandoned tasks to archive/

### /errors - Analyze error patterns
Reads errors.json, creates fix plans

### /meta - System builder
Interactive agent system generator

## State Synchronization

**Critical**: TODO.md and state.json must stay synchronized.

### Two-Phase Update Pattern
1. Read both files
2. Prepare updates in memory
3. Write state.json first (machine state)
4. Write TODO.md second (user-facing)
5. If either fails, log error

### state.json Structure
```json
{
  "next_project_number": 9,
  "active_projects": [
    {
      "project_number": 1,
      "project_name": "task_slug",
      "status": "planned",
      "language": "lua",
      "priority": "high"
    }
  ]
}
```

## Git Commit Conventions

Commits are scoped to task operations:
```
task {N}: create {title}
task {N}: complete research
task {N}: create implementation plan
task {N} phase {P}: {phase_name}
task {N}: complete implementation
todo: archive {N} completed tasks
errors: create fix plan for {N} errors
```

## Neovim/Lua Development

### Essential Commands
```bash
# Run all tests with plenary
nvim --headless -c "PlenaryBustedDirectory tests/"

# Run specific test file
nvim --headless -c "PlenaryBustedFile tests/picker/scan_recursive_spec.lua"

# Run tests with verbose output
nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

# Check for Lua syntax errors
luacheck lua/
```

### Test-Driven Development
All implementations follow TDD:
1. Write failing test first
2. Implement minimal code to pass
3. Refactor while tests pass

### Lua Code Style
- **Indentation**: 2 spaces, expandtab
- **Line length**: ~100 characters
- **Imports**: At the top of the file, ordered by dependency
- **Module structure**: Organized in `neotex.core` and `neotex.plugins` namespaces
- **Plugin definitions**: Table-based with lazy.nvim format
- **Function style**: Use local functions where possible
- **Error handling**: Use pcall for operations that might fail
- **Naming**: Descriptive, lowercase names with underscores

### Module Pattern
```lua
-- lua/neotex/plugins/category/plugin-name.lua
return {
  "author/plugin-name",
  event = "VeryLazy",  -- or specific events
  dependencies = { "dep/plugin" },
  opts = {
    -- configuration options
  },
  config = function(_, opts)
    require("plugin-name").setup(opts)
  end,
}
```

### Plugin Directory Structure
```
lua/neotex/plugins/
├── ai/                  # AI integrations
│   ├── init.lua         # Category loader
│   ├── claude.lua       # Claude Code integration
│   └── goose.lua        # Goose AI integration
├── editor/              # Editor enhancements
├── lsp/                 # Language server configs
├── text/                # Format-specific (LaTeX, Markdown)
├── tools/               # Development tools
└── ui/                  # UI components
```

## Testing Patterns

### Framework
- **Busted**: Primary Lua testing framework
- **plenary.nvim**: Neovim-specific testing utilities

### Assertion Patterns
```lua
-- Correct: Use is_nil/is_not_nil for string:match()
assert.is_not_nil(str:match("pattern"))   -- Match found
assert.is_nil(str:match("pattern"))       -- Match not found

-- WRONG: match() returns string/nil, not boolean
-- assert.is_true(str:match("pattern"))   -- FAILS
-- assert.is_false(str:match("pattern"))  -- FAILS
```

### Test File Organization
- Test files: `*_spec.lua` or `test_*.lua`
- Test location: `tests/` directory
- Test framework: busted with plenary.nvim

## Rules References

Core rules (automatically applied based on file paths):
- @.claude/rules/state-management.md - Task state patterns (paths: .claude/specs/**)
- @.claude/rules/git-workflow.md - Commit conventions
- @.claude/rules/neovim-lua.md - Neovim/Lua development patterns (paths: **/*.lua)
- @.claude/rules/error-handling.md - Error recovery patterns (paths: .claude/**)
- @.claude/rules/artifact-formats.md - Report/plan formats (paths: .claude/specs/**)
- @.claude/rules/workflows.md - Command lifecycle patterns (paths: .claude/**)

## Project Context Imports

Domain knowledge (load as needed):
- @.claude/context/project/neovim/domain/neovim-api.md - Neovim API patterns
- @.claude/context/project/neovim/domain/lua-patterns.md - Lua idioms
- @.claude/context/project/neovim/domain/plugin-ecosystem.md - Plugin selection
- @.claude/context/project/neovim/tools/lazy-nvim.md - Plugin manager

## Documentation Requirements

### README per Directory
Every subdirectory must contain a README.md with:
- **Purpose**: Clear explanation of directory's role
- **Module Documentation**: Documentation for each file
- **Usage Examples**: Code examples where applicable
- **Navigation Links**: Links to parent and subdirectories

### Character Encoding
- **UTF-8 encoding** for all files
- **NO EMOJIS in file content** - causes encoding issues
- Use Unicode box-drawing characters for diagrams (┌─┐│└┘├┤┬┴┼)
- Plain text alternatives: `[DONE]`, `[FAIL]`, `[WARN]`, `[INFO]`

## Error Handling

### On Command Failure
- Keep task in current status (don't regress)
- Log error to errors.json if persistent
- Preserve partial progress for resume

### On Timeout
- Mark current phase [PARTIAL]
- Next /implement resumes from incomplete phase

## Session Patterns

### Starting Work on a Task
```
1. Read TODO.md to find task
2. Check current status
3. Use appropriate command (/research, /plan, /implement)
```

### Resuming Interrupted Work
```
1. /implement N automatically detects resume point
2. Continues from last incomplete phase
3. No manual intervention needed
```

## Key Development Principles

- **TDD Mandatory**: Write tests BEFORE implementation
- **No Backwards Compatibility**: Clean breaks when improving
- **Fail-Fast**: Early validation, clear error messages
- **Explicit Data Flow**: No hidden state
- **Graceful Degradation**: Use pcall, provide fallbacks

### Quality Standards
- All new Lua modules must have test coverage
- Public APIs require comprehensive tests
- All subdirectories require README.md
- Documentation must be present-state (no historical markers)

## Important Notes

- Always update status BEFORE starting work (preflight)
- Always update status AFTER completing work (postflight)
- State.json is source of truth for machine operations
- TODO.md is source of truth for user visibility
- Git commits are non-blocking (failures logged, not fatal)
- Neovim-specific standards in nvim/CLAUDE.md extend this file
