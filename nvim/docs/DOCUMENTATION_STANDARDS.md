# Documentation Standards

## Purpose

This document defines the standards and conventions for all documentation in the NeoVim configuration. These standards prioritize clarity, current-state accuracy, and maintainability while explicitly rejecting historical commentary and cruft.

## Core Principles

### Present-State Focus

Documentation must describe the current implementation only. Historical context, migration notes, and change descriptions belong in git history, not in documentation.

**Prohibited**:
- Historical markers: "(New)", "(Updated)", "(Old)", "(Legacy)", "(Deprecated)", version numbers
- Temporal language: "previously", "now supports", "recently added", "in the latest version"
- Migration guides embedded in feature documentation
- Changelog-style commentary in code or docs

**Required**:
- Clear description of what exists now
- Current behavior and capabilities
- Present-tense technical accuracy
- Timeless writing that assumes current implementation always existed

### Clean-Break Philosophy

Documentation must reflect clean, coherent design without explaining backward compatibility or legacy decisions.

**When refactoring**:
- Remove all references to deprecated patterns
- Document only the current implementation
- Delete migration notes after transition completes
- Treat documentation as if the current design always existed

**Priority**: Coherent, maintainable documentation > Historical completeness

### Accuracy and Completeness

Every documented feature must:
- Accurately reflect current implementation
- Include working examples with correct paths and commands
- Reference actual file locations with line numbers where helpful
- Be verifiable by reading the source code

## Documentation Structure

### Directory Organization

```
nvim/
├── README.md                    # Project overview, quick start, navigation hub
├── docs/                        # Central documentation directory
│   ├── DOCUMENTATION_STANDARDS.md  # This file
│   ├── CODE_STANDARDS.md          # Lua coding conventions
│   ├── INSTALLATION.md            # Setup and installation procedures
│   ├── ARCHITECTURE.md            # System architecture and design
│   ├── AI_TOOLING.md              # AI development tools and workflows
│   ├── RESEARCH_TOOLING.md        # LaTeX, Markdown, and research features
│   ├── NIX_WORKFLOWS.md           # NixOS integration and workflows
│   ├── FORMAL_VERIFICATION.md     # Model-checker and Lean integration
│   ├── MAPPINGS.md                # Keybinding reference
│   └── NOTIFICATIONS.md           # Notification system documentation
├── lua/neotex/                  # Source code with inline module docs
│   ├── README.md                # Namespace overview and module index
│   ├── plugins/                 # Plugin configurations
│   │   ├── README.md            # Plugin organization and loading
│   │   ├── ai/README.md         # AI tooling plugins
│   │   ├── editor/README.md     # Editor enhancement plugins
│   │   ├── lsp/README.md        # LSP and completion plugins
│   │   ├── text/README.md       # Text editing and writing plugins
│   │   ├── tools/README.md      # Development tools
│   │   └── ui/README.md         # UI enhancement plugins
│   ├── config/README.md         # Configuration modules
│   ├── core/README.md           # Core functionality modules
│   └── util/README.md           # Utility functions
└── templates/                   # LaTeX and document templates
    └── README.md                # Template catalog and usage
```

### README Requirements

Every directory must have a README.md containing:

1. **Purpose Statement**: One-paragraph description of the directory's role
2. **Module Documentation**: For each file/module in the directory:
   - Module name and purpose
   - Primary functions/exports
   - Dependencies and requirements
   - Usage examples (if applicable)
3. **Navigation Links**: Links to parent README and subdirectory READMEs
4. **Related Documentation**: Links to relevant docs/ files

**Format Example**:

```markdown
# Directory Name

Purpose: [One paragraph describing this directory's role in the system]

## Modules

### module_name.lua

Purpose: [What this module does]

**Primary Exports**:
- `function_name(args)` - Description
- `variable_name` - Description

**Dependencies**: [Required modules or plugins]

**Usage**:
```lua
-- Example code
local module = require("neotex.category.module_name")
module.setup()
```

### another_module.lua

[Similar structure...]

## Subdirectories

- [subdirectory/](subdirectory/) - Brief description

## Navigation

- [Parent Directory](../) - Parent description
- [Root Documentation](../../docs/) - Central docs

## Related Documentation

- [CODE_STANDARDS.md](../../docs/CODE_STANDARDS.md) - Coding conventions
- [ARCHITECTURE.md](../../docs/ARCHITECTURE.md) - System design
```

### Central Documentation (docs/)

Each docs/ file should:

1. **Focus on a Coherent Topic**: Architecture, tooling category, workflows, standards
2. **Provide Complete Coverage**: Don't split related information across files
3. **Include Working Examples**: All code examples must be current and functional
4. **Cross-Reference Appropriately**: Link to related docs and source READMEs

## Content Standards

### Technical Writing Style

**Voice and Tone**:
- Present tense, active voice
- Direct and concise
- Technical precision over marketing language
- Assume knowledgeable reader (Vim/NeoVim user)

**Good Examples**:
- "The LSP system provides code completion through blink.cmp"
- "Avante integrates with Claude, GPT, and Gemini providers"
- "Sessions persist automatically when exiting NeoVim"

**Bad Examples**:
- "We recently updated the LSP system to use blink.cmp"
- "Avante now supports multiple providers including Claude"
- "Sessions are automatically persisted (new feature!)"

### Code Examples

All code examples must:
- Use correct syntax highlighting (specify language)
- Reference actual file paths and line numbers when helpful
- Include necessary context (requires, setup calls)
- Be copy-pastable and functional

**Format**:

```markdown
**Example**: Setting up custom LSP configuration

In `lua/neotex/plugins/lsp/lspconfig.lua:42-56`:

```lua
local lspconfig = require("lspconfig")

lspconfig.lua_ls.setup({
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
    },
  },
})
```
```

### File References

When referencing code:
- Use absolute paths from project root: `nvim/lua/neotex/module.lua`
- Include line numbers for specific functions: `nvim/lua/neotex/module.lua:42-56`
- Link to source files in navigation sections

### Keybinding Documentation

Keybindings should be documented:

1. **In MAPPINGS.md**: Complete reference organized by category
2. **In Feature Docs**: Relevant keybindings for that feature
3. **In Module READMEs**: Module-specific mappings

**Format**:

```markdown
### AI Tools

| Key | Mode | Description | Source |
|-----|------|-------------|--------|
| `<leader>aa` | n | Open Avante chat | `plugins/ai/avante.lua:45` |
| `<C-c>` | n | Toggle Claude Code | `plugins/ai/claudecode.lua:23` |
| `<leader>ac` | v | Send selection to Claude | `plugins/ai/claudecode.lua:67` |
```

### Plugin Documentation

For each plugin configuration:

1. **Plugin Identification**: Name, source repository
2. **Purpose**: What problem it solves
3. **Key Features**: What functionality it provides
4. **Configuration**: Notable settings and customizations
5. **Keybindings**: Relevant mappings
6. **Dependencies**: Required plugins or external tools
7. **File Location**: Where it's configured

**Example**:

```markdown
## Avante (yetone/avante.nvim)

Multi-provider AI coding assistant with inline suggestions and chat interface.

**Key Features**:
- Support for Claude, GPT, Gemini, and other providers
- Inline code suggestions and diff preview
- Contextual chat with project awareness
- Custom prompt templates

**Configuration**: `lua/neotex/plugins/ai/avante.lua`

**Primary Settings**:
- Provider: Claude Sonnet 4.5
- Auto-suggestions: Enabled
- Diff style: Inline with unified view

**Keybindings**:
- `<leader>aa`: Open Avante chat
- `<leader>at`: Toggle suggestions
- `<leader>ar`: Refresh context

**Dependencies**:
- API key in environment: `ANTHROPIC_API_KEY`
- Tree-sitter for syntax awareness

**Related**: See [AI_TOOLING.md](AI_TOOLING.md) for complete AI workflow documentation
```

## Formatting Standards

### Markdown Conventions

- **Headings**: Use ATX-style headers (`#`, `##`, `###`)
- **Lists**: Use `-` for unordered, `1.` for ordered
- **Code Blocks**: Always specify language (```lua, ```bash, etc.)
- **Emphasis**: `*italic*` for emphasis, `**bold**` for strong emphasis, `` `code` `` for inline code
- **Links**: Use reference-style links for repeated URLs, inline for one-offs
- **Tables**: Use GitHub Flavored Markdown table syntax with alignment

### Diagrams and Visual Elements

**Unicode Box-Drawing** (Required):
- Use Unicode box-drawing characters for diagrams
- No ASCII art (`+`, `-`, `|` style)

**Example**:

```
Configuration Loading Flow
┌─────────────────────────────────────────────────────────────┐
│ init.lua                                                    │
│ • Set leader key                                            │
│ • Suppress deprecated warnings                              │
│ • Load neotex.bootstrap                                     │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ neotex.bootstrap                                            │
│ • Install/update lazy.nvim                                  │
│ • Validate lazy-lock.json                                   │
│ • Load plugins from lua/neotex/plugins/                     │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ neotex.config                                               │
│ • Load options (config/options.lua)                         │
│ • Initialize notifications (config/notifications.lua)       │
│ • Setup keymaps (config/keymaps.lua)                        │
│ • Configure autocmds (config/autocmds.lua)                  │
└─────────────────────────────────────────────────────────────┘
```

**No Emojis**:
- Emojis cause encoding issues and inconsistent rendering
- Use text indicators: `NOTE:`, `WARNING:`, `IMPORTANT:`, `TIP:`

### Character Encoding

- UTF-8 only
- No emojis or non-standard Unicode
- Box-drawing characters are acceptable (part of UTF-8 standard)

## Special Documentation Types

### Architecture Documentation

Architecture docs should include:
- System component diagram
- Data flow diagrams
- Module dependency graph
- Initialization sequence
- Plugin loading order

### API Reference

For modules with public APIs:
- Function signatures with type information
- Parameter descriptions
- Return value descriptions
- Example usage
- Error conditions

**Format**:

```markdown
### module.function_name(param1, param2)

Description of what the function does.

**Parameters**:
- `param1` (string): Description of param1
- `param2` (table|nil): Description of param2, optional

**Returns**:
- (boolean): Success status
- (string|nil): Error message on failure

**Example**:
```lua
local success, err = module.function_name("value", { option = true })
if not success then
  vim.notify("Error: " .. err, vim.log.levels.ERROR)
end
```

**Errors**:
- Throws error if param1 is empty
- Returns false if param2 validation fails
```

### Workflow Documentation

Workflow docs should describe:
- Trigger or starting point
- Step-by-step procedure
- Expected outcomes
- Error handling
- Related workflows

## Documentation Maintenance

### When to Update Documentation

Documentation must be updated:
- When adding new features or modules
- When modifying existing behavior
- When refactoring code structure
- When removing deprecated features

### Update Process

1. **Identify Affected Docs**: Determine which files need updates
2. **Update Source READMEs**: Start with module-level READMEs
3. **Update Central Docs**: Update docs/ files for broader context
4. **Verify Examples**: Test all code examples for accuracy
5. **Update Cross-References**: Ensure all links are valid
6. **Remove Historical Content**: Delete any introduced temporal language

### Quality Checklist

Before committing documentation:

- [ ] No historical commentary or temporal language
- [ ] All code examples tested and functional
- [ ] File paths and line numbers verified
- [ ] Cross-references valid and complete
- [ ] Unicode box-drawing for diagrams (no ASCII art)
- [ ] No emojis in content
- [ ] Present tense, active voice throughout
- [ ] Assumes current implementation always existed
- [ ] Related READMEs updated
- [ ] Central docs updated if needed

## Migration Notes

### Removing Historical Content

When refactoring documentation:

1. **Identify Historical Markers**: Search for prohibited terms
2. **Rewrite in Present Tense**: Transform to current-state description
3. **Delete Migration Guides**: Remove transition documentation
4. **Consolidate Related Updates**: Merge related changes into single coherent description
5. **Verify Accuracy**: Ensure rewritten content reflects current implementation

### Example Transformation

**Before** (historical):
```markdown
## Session Management

The session system was recently updated to use UUID-based session IDs instead
of timestamp-based IDs. This new approach (introduced in v2.0) provides better
session isolation and prevents collisions.

Previously, sessions were identified by their creation timestamp, but this
caused issues in the old implementation when multiple sessions started
simultaneously. The current UUID system solves this problem.
```

**After** (present-state):
```markdown
## Session Management

The session system uses UUID-based session IDs to ensure unique identification
and prevent collisions. Each session receives a cryptographically random UUID
on creation, providing reliable isolation even when multiple sessions start
simultaneously.
```

## Related Documentation

- [CODE_STANDARDS.md](CODE_STANDARDS.md) - Lua coding conventions and patterns

## Notes

This standards document applies to all documentation in the NeoVim configuration, including:
- All README.md files throughout the codebase
- All files in nvim/docs/
- Inline documentation in Lua source files
- Comments in configuration files

The standards prioritize maintainability and accuracy. When in doubt, prefer clarity and current-state focus over historical context or comprehensive changelog-style documentation.
