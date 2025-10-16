# Template System Research Report
*Research conducted on 2025-09-24*

## Executive Summary

This report analyzes existing template systems, prompt management solutions, and command saving patterns across Neovim, VSCode, and AI coding assistants to inform the design of a template system for constructing high-quality prompts and saving commands for Claude Code integration.

## Key Findings

### 1. Neovim Template & Snippet Ecosystem

**LuaSnip Dominance**
- LuaSnip is the de-facto standard snippet engine for Neovim (Lua-based)
- Supports multiple loading methods: VSCode-style, custom directories, Lua loader
- Features hot reload with file watching (both autocmd and libuv)
- Lazy loading capabilities defer loading until actually needed
- Extensive configuration options for history, region checking, and autosnippets

**Modern AI Integration (2024-2025 Trends)**
- **model.nvim**: Focuses specifically on "interacting with LLMs and building editor integrated prompts"
- **codegpt-ng.nvim**: "Minimalist command-based AI plugin" with "powerful template system"
- **Gp.nvim**: ChatGPT integration with instructable text/code operations
- **ChatGPT.nvim**: Effortless natural language generation

### 2. AI Coding Assistant Prompt Management

**VSCode/GitHub Copilot**
- **Prompt Files**: Markdown-based reusable prompts stored in `.github/prompts/` folders
- Two scopes: Workspace-specific and global
- **Chat Participants**: Domain-specific context collectors (@workspace, @terminal, etc.)
- **Slash Commands**: Intent-specific commands (/explain, /fix, /tests)
- **Agent Mode**: High-level task specification with autonomous planning and execution

**Cursor AI**
- Built on VSCode fork with enhanced AI workflows
- Context-aware chat (⌘ + L) with drag & drop folder support
- "Apply from Chat" feature for direct code application
- Side-by-side AI interface with code editing

**System Prompt Collections**
- GitHub repositories contain thousands of system prompts from major AI tools
- Leaked prompts from Claude Code, Cursor, Devin, Replit, and others
- Comprehensive insights into prompt engineering patterns

### 3. Command History & Management Patterns

**Dotfiles Ecosystem**
- **chezmoi** (16,087 stars): Cross-machine dotfile management with templating
- **yadm** (5,919 stars): System-specific alternate files, encryption, bootstrap actions
- **GNU Stow**: Symlink farm manager for package organization

**Configuration Patterns**
- Shell history settings: HISTCONTROL, histappend, HISTSIZE/HISTFILESIZE
- Version control integration (Git) for change tracking
- Template-based configuration with naming conventions and style guidelines
- Repository structure: tool-specific directories (bash/, vim/, git/)

## Architecture Patterns Analysis

### Template Loading Strategies
1. **Lazy Loading**: Load templates only when needed (LuaSnip approach)
2. **Hot Reload**: File watching for real-time updates
3. **Multiple Sources**: VSCode-style, custom directories, programmatic
4. **Scoped Access**: Workspace-specific vs global availability

### Prompt Management Models
1. **File-Based**: Markdown prompts in structured directories (.github/prompts/)
2. **Programmatic**: Lua-based template definitions with variables
3. **Context-Aware**: Integration with editor state and project context
4. **Command Integration**: Slash commands and chat participants for intent

### Command Saving Patterns
1. **History Persistence**: Shell-like command history with search
2. **Template Variables**: Parameterized commands with substitution
3. **Categorization**: Organized by task type, project, or domain
4. **Versioning**: Track changes to saved commands over time

## Recommendations for Claude Code Integration

### 1. Hybrid Architecture
- **File-based templates** stored in `ai-claude/templates/` directory
- **Lua configuration** for programmatic template management
- **Hot reload** capability for development workflow

### 2. Template Structure
```
ai-claude/
├── templates/
│   ├── code-review/
│   ├── debugging/
│   ├── documentation/
│   └── refactoring/
├── commands/
│   ├── saved-commands.json
│   └── command-history.json
└── config/
    └── template-config.lua
```

### 3. Core Features
- **Template Variables**: Support for `{{variable}}` substitution
- **Context Integration**: Access to current buffer, selection, project info
- **Command History**: Persistent storage of successful commands
- **Quick Access**: Fuzzy finder integration for template/command selection
- **Scoping**: Project-specific and global template collections

### 4. User Interface Patterns
- **Telescope Integration**: Fuzzy finding for templates and commands
- **Completion Support**: nvim-cmp integration for template variables
- **Command Palette**: VSCode-style command interface
- **Chat Integration**: Direct application of template results

## Technical Implementation Considerations

### Storage Format
- **Templates**: Markdown files with YAML frontmatter for metadata
- **Commands**: JSON for structured data with search indexing
- **Configuration**: Lua for flexible programmatic control

### Integration Points
- **LuaSnip**: Leverage existing snippet infrastructure
- **Telescope**: Use for selection and preview interfaces
- **nvim-cmp**: Template variable completion
- **Claude Code API**: Direct integration with prompt submission

### Performance Considerations
- Lazy loading of templates to minimize startup time
- Caching of parsed templates and command history
- Asynchronous file operations for hot reload
- Indexing for fast search of large template collections

## Competitive Analysis Summary

| Feature | LuaSnip | VSCode Copilot | Cursor | Our Opportunity |
|---------|---------|----------------|---------|-----------------|
| Hot Reload | ✅ | ❌ | ❌ | Differentiation |
| Context Awareness | ❌ | ✅ | ✅ | Must-have |
| Template Variables | ✅ | ✅ | ❌ | Standard feature |
| Command History | ❌ | ❌ | ❌ | Innovation opportunity |
| AI Integration | ❌ | ✅ | ✅ | Core requirement |

## Next Steps

1. **Prototype Development**: Build minimal viable template system
2. **User Testing**: Validate template format and workflow
3. **Integration Planning**: Define Claude Code API integration points
4. **Documentation**: Create template authoring guidelines
5. **Migration Path**: Plan import from existing snippet/template systems

---
*This report provides the foundation for designing a comprehensive template system that combines the best practices from existing solutions while addressing the specific needs of Claude Code integration in Neovim.*