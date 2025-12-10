# Goose Plugin Documentation Update Research Report

**Date**: 2025-12-09
**Research Topic**: Goose Plugin Documentation Updates
**Scope**: Update goose/README.md to fit within the neovim AI plugin ecosystem

## Executive Summary

The current goose/README.md (931 lines) is comprehensive and well-structured, but lacks proper ecosystem context within the AI plugins directory. This research analyzed both the goose and claude plugin documentation to identify gaps, cross-linking opportunities, and alignment strategies.

### Key Findings

1. **Missing Ecosystem Context**: goose/README.md doesn't reference its position within the broader AI plugins ecosystem
2. **No Cross-References to Claude**: Despite both being AI assistants under the same parent directory, there's no documentation linking them
3. **Architectural Clarity Gap**: The relationship between goose.nvim (external plugin) and the internal picker system isn't emphasized like it is in claude/README.md
4. **Parent Directory Link Missing**: No navigation link to the parent ai/README.md
5. **Strengths to Preserve**: Excellent technical depth, comprehensive troubleshooting, and well-organized feature documentation

### Recommended Approach

Update goose/README.md with strategic additions (not rewrites) that:
- Add ecosystem context without duplicating technical content
- Cross-reference claude documentation appropriately
- Emphasize architectural separation (external plugin vs internal system)
- Improve navigation within the ai/ directory structure

## Findings

### 1. Current Documentation Structure Analysis

#### Goose README Structure (931 lines)
```
# goose.nvim Integration
├── Purpose
├── Features
├── Configuration
│   ├── Split Window Mode
│   ├── Plugin Specification
│   ├── Keybindings
│   └── Backend Configuration
├── Multi-Provider Configuration
├── Usage Workflows
├── Goose Modes
├── Recipes
├── Troubleshooting
├── Common Workflows
├── Configuration Files
├── Performance Notes
└── References
```

**Strengths**:
- Comprehensive technical documentation (split window mode, providers, recipes)
- Excellent troubleshooting section with specific solutions
- Clear usage examples and workflow documentation
- Well-documented recipe system with picker integration
- Detailed keybinding tables under `<leader>a` namespace

**Gaps**:
- No "Architectural Overview" section (compare to claude/README.md lines 11-19)
- Missing parent directory context and navigation
- No cross-reference to other AI plugins
- Doesn't emphasize external vs internal system separation

#### Claude README Structure (556 lines)
```
# Claude Code Integration
├── Purpose
├── Architectural Overview (lines 11-19) ★
│   └── External vs Internal separation emphasized
├── Core Features
├── Directory Structure (with line counts) ★
├── External Plugin Configuration (lines 131-137) ★
├── Usage
├── API Reference
├── Troubleshooting
└── Architecture and Implementation Details
```

**Relevant Patterns**:
- **Architectural Overview** section at the top sets context
- **External Plugin Configuration** section explicitly separates concerns
- **Line counts** in directory structure (e.g., "9,626 lines across 20 files")
- **Parent directory navigation** at bottom
- **Clear separation** between "what we use" vs "what we built"

### 2. Ecosystem Integration Gap

#### Current State
The goose/README.md operates in isolation:
- No mention of ai/ parent directory
- No reference to sibling plugins (claude, avante)
- Doesn't acknowledge being part of a multi-AI plugin ecosystem

#### Parent Directory Context (ai/README.md)
```markdown
## Subdirectories
- [claude/](claude/README.md) - Comprehensive internal Claude AI integration system (9,626+ lines across 20 files)

# Missing:
- [goose/](goose/README.md) - Goose AI agent integration with recipe system
```

The parent README references claude/ but not goose/, indicating the subdirectory structure is incomplete.

### 3. Cross-Referencing Opportunities

#### Where to Cross-Reference Claude

1. **Provider Comparison Context** (goose/README.md lines 258-274)
   - Currently shows Gemini vs Claude Code setup
   - Could add note: "For direct Claude API integration without subscription, see [../claude/README.md](../claude/README.md)"

2. **Keybinding Coordination** (lines 119-168)
   - Both use `<leader>a` namespace (documented in ai/README.md)
   - Could add note: "Keybindings coordinated with other AI tools. See [AI Plugins Overview](../README.md#keybindings)"

3. **Session Management Philosophy** (lines 456-462)
   - Both have session persistence systems
   - Opportunity: Brief comparison note without detailed duplication

#### What NOT to Cross-Reference

**Anti-Pattern**: Avoid over-representation of claude documentation
- ❌ Don't redirect users to claude for goose-specific features
- ❌ Don't duplicate claude's feature descriptions in goose docs
- ❌ Don't suggest claude as a "better alternative" to goose
- ✅ Do provide context for ecosystem navigation
- ✅ Do note complementary use cases

### 4. Architectural Clarity Opportunities

#### Current Architecture Description (lines 75-116)
The goose README has a "Plugin Specification" section showing code, but lacks the explicit architectural framing that claude/README.md provides.

**Claude's Approach** (claude/README.md lines 11-19):
```markdown
## Architectural Overview

This module represents the **internal system** for Claude Code integration,
while `../claudecode.lua` serves as the **external plugin configuration layer**.
This separation follows clean architecture principles:

- **External dependencies** are isolated in plugin configs
- **Internal business logic** is organized in domain modules
- **Clear boundary** between "what we use" vs "what we built"
```

**Goose's Current Approach** (goose/README.md lines 5-16):
```markdown
## Purpose

This module integrates [goose.nvim](https://github.com/azorng/goose.nvim)
with the Neovim configuration, providing seamless AI agent capabilities...

## Features

- **Persistent Sessions**: Conversations tied to workspace...
```

**Opportunity**: Add similar architectural framing section before Features.

### 5. Directory Structure Documentation

#### Current State
The goose README mentions the picker subdirectory in passing:
- Line 242: "See [picker/README.md](picker/README.md) for complete API documentation."

This is the **only** reference to internal structure.

#### Claude's Approach (lines 85-129)
```markdown
## Directory Structure

**Total: 9,626 lines across 20 files**

```
ai/claude/
├── init.lua                      # Main entry point and public API (162 lines)
├── config.lua                    # Configuration management
├── README.md                     # This documentation file
│
├── core/                         # 3,800+ lines - Core business logic
│   ├── session.lua              # Core session management (461 lines)
...
```
```

**Opportunity**: Add similar comprehensive directory listing for goose.

### 6. Navigation and Discoverability

#### Missing Navigation Links
The goose README ends with "## References" (external links only), no internal navigation:
```markdown
## References

### Documentation
- [goose.nvim GitHub](https://github.com/azorng/goose.nvim) - Plugin documentation
- [Goose CLI Docs](https://block.github.io/goose/docs/getting-started/installation)
```

**Claude's Navigation Section** (lines 515-522):
```markdown
## Navigation

- [← Parent Directory](../README.md) - AI plugins overview
- [External Plugin Config](../claudecode.lua) - `claude-code.nvim` configuration
- [Core Modules](core/README.md) - Core business logic documentation
- [UI Components](ui/README.md) - User interface documentation
...
```

**Opportunity**: Add "Navigation" section before "References".

### 7. Documentation Quality Comparison

| Aspect | Goose README | Claude README | Notes |
|--------|--------------|---------------|-------|
| Technical Depth | ★★★★★ | ★★★★☆ | Goose more detailed on features |
| Ecosystem Context | ★☆☆☆☆ | ★★★★★ | Claude emphasizes integration |
| Architecture | ★★☆☆☆ | ★★★★★ | Claude has explicit overview |
| Troubleshooting | ★★★★★ | ★★★☆☆ | Goose more comprehensive |
| Navigation | ★★☆☆☆ | ★★★★★ | Claude has internal links |
| Line Count Metrics | ❌ | ✅ | Claude quantifies complexity |
| Parent Link | ❌ | ✅ | Claude links to ai/README.md |

### 8. Recipe System Documentation Excellence

The goose README's recipe documentation (lines 482-652) is **exemplary** and should be preserved without modification:
- Comprehensive workflow table (line 486-495)
- Clear distinction between Neovim and CLI usage
- Excellent picker documentation reference
- Detailed testing workflow (lines 590-651)

**No cross-linking needed here** - this is goose-specific functionality with no claude equivalent.

### 9. Keybinding Namespace Analysis

Both plugins share `<leader>a` namespace (documented in ai/README.md lines 82-89):

**Goose Keybindings** (goose/README.md lines 119-168):
- `<leader>aa` - Toggle goose chat interface
- `<leader>aR` - Run recipe (Telescope picker)
- `<leader>ag` - Goose run
- `<leader>av` - Select session
- (15+ total mappings)

**Claude Keybindings** (ai/README.md lines 82-89):
- `<leader>ac` - Send selection to Claude / Claude commands
- `<leader>as` - Claude sessions
- `<leader>av` - View worktrees
- `<leader>aw` - Create worktree

**Conflict**: Both use `<leader>av` for different features (goose: select session, claude: view worktrees)

**Recommendation**: Document this coordination explicitly with note pointing to ai/README.md for complete keymap.

### 10. Provider Configuration Excellence

The goose README's multi-provider configuration section (lines 280-380) is **outstanding**:
- Automatic detection logic
- Clear setup instructions for Gemini and Claude Code
- Excellent troubleshooting for API key conflicts
- Environment persistence examples for Fish/Bash/Zsh

**Opportunity**: Add brief note distinguishing "Claude Code" (subscription via goose backend) from "Claude API" (direct integration in claude/ directory) to prevent user confusion.

## Recommendations

### 1. Add Architectural Overview Section

**Location**: After "Purpose" section (insert at line 17)

**Content**:
```markdown
## Architectural Overview

This module represents the **Neovim configuration layer** for goose.nvim integration,
while the external [goose.nvim](https://github.com/azorng/goose.nvim) plugin provides
the core AI agent functionality. This separation follows clean architecture principles:

- **External plugin** (azorng/goose.nvim) - AI agent core, session management, provider abstraction
- **Internal configuration** (this directory) - Neovim-specific integration, keybindings, recipe picker
- **Clear boundary** between "plugin we use" vs "extensions we built"

**Key Internal Extensions**:
- Custom recipe picker with Telescope integration (see [picker/README.md](picker/README.md))
- Coordinated keybindings within `<leader>a` namespace (see [AI Plugins Overview](../README.md))
- Split window mode configuration optimized for multi-sidebar workflows
```

**Rationale**: Mirrors claude/README.md structure, sets context early, emphasizes internal vs external.

### 2. Add Directory Structure Section

**Location**: After "Features" section (insert at line 118)

**Content**:
```markdown
## Directory Structure

**Internal Extensions: 5 modules in picker/ subdirectory**

```
nvim/lua/neotex/plugins/ai/goose/
├── init.lua                      # Main plugin specification (117 lines)
├── README.md                     # This documentation file (931 lines)
│
└── picker/                       # Recipe picker system (5 modules)
    ├── init.lua                 # Telescope integration and keybindings
    ├── discovery.lua            # Recipe discovery (project + global)
    ├── metadata.lua             # YAML parsing and validation
    ├── previewer.lua            # Custom Telescope previewer
    ├── execution.lua            # Native sidebar execution via goose.core.run()
    └── README.md                # Picker API documentation
```

**External Plugin Configuration**:
- `../goose/init.lua` - Main goose.nvim plugin spec (configured via lazy.nvim)
- External plugin: [azorng/goose.nvim](https://github.com/azorng/goose.nvim)

See [picker/README.md](picker/README.md) for complete recipe picker API documentation.
```

**Rationale**: Quantifies internal contributions, clarifies what's ours vs theirs, provides navigation.

### 3. Add Ecosystem Context Note

**Location**: In "Multi-Provider Configuration" section after line 282

**Content**:
```markdown
### AI Ecosystem Context

This goose integration is part of a multi-AI plugin ecosystem in the `ai/` directory:

- **goose.nvim** (this plugin) - Multi-provider AI agent with recipe system (Gemini, Claude Code)
- **claude/** - Direct Claude API integration with session management ([details](../claude/README.md))
- **avante/** - Multi-provider AI assistant (Claude, GPT, Gemini) with inline suggestions

**Provider Clarification**:
- **"Claude Code" backend** (this plugin) - Requires Claude Pro/Max subscription, used via goose
- **"Claude API" direct** (claude/ directory) - Requires ANTHROPIC_API_KEY, independent integration

For keybinding coordination across AI tools, see [AI Plugins Overview](../README.md#keybindings).
```

**Rationale**: Prevents confusion between Claude Code (goose backend) and claude/ directory, provides ecosystem map without over-representation.

### 4. Add Navigation Section

**Location**: After "References" section (append at end, before final line)

**Content**:
```markdown
## Navigation

- [← Parent Directory](../README.md) - AI plugins overview and keybinding coordination
- [Recipe Picker](picker/README.md) - Custom Telescope picker API documentation
- [Neovim Configuration](../../../../README.md) - Root configuration documentation
- [goose.nvim Plugin](https://github.com/azorng/goose.nvim) - External plugin repository
```

**Rationale**: Improves discoverability, links to parent for keybinding context, separates internal vs external links.

### 5. Add Keybinding Coordination Note

**Location**: In "Keybindings" section after line 121

**Content**:
```markdown
All goose.nvim keybindings are defined in `which-key.lua` under the `<leader>a` namespace,
coordinated with other AI plugins (claude, avante). See [AI Plugins Overview](../README.md#keybindings)
for complete keymap across all AI tools.

**Note**: The `<leader>av` mapping (Select session) is goose-specific. Claude uses this binding
for worktree management, so ensure only one plugin is active when using this key.
```

**Rationale**: Addresses keybinding conflict discovered in analysis, points to authoritative source.

### 6. Update Parent Directory README

**Location**: In `ai/README.md`, update "Subdirectories" section (line 29)

**Current**:
```markdown
## Subdirectories

- [claude/](claude/README.md) - Comprehensive internal Claude AI integration system (9,626+ lines across 20 files)
```

**Updated**:
```markdown
## Subdirectories

- [claude/](claude/README.md) - Comprehensive internal Claude AI integration system (9,626+ lines across 20 files)
- [goose/](goose/README.md) - Goose AI agent integration with multi-provider support and recipe picker system
```

**Rationale**: Completes the parent directory's subdirectory listing, improves discoverability.

### 7. Provider Clarification in Backend Configuration

**Location**: In "Backend Configuration" section after line 258

**Content**:
```markdown
#### Provider Clarification

goose.nvim supports multiple AI backends through its provider system:

1. **Gemini CLI** (Default) - Free tier available, no subscription required
2. **Claude Code** (Pro/Max Subscription) - Paid subscription via claude.ai

**Note**: "Claude Code" is a subscription-based backend for goose.nvim, distinct from the
direct Claude API integration in `../claude/`. If you need Claude API access without a
subscription, see [claude/README.md](../claude/README.md) for the ANTHROPIC_API_KEY approach.
```

**Rationale**: Prevents user confusion between Claude Code backend and claude/ directory, clarifies cost implications.

## Implementation Strategy

### Phase 1: Core Structural Updates (Low Risk)
1. Add Architectural Overview section (Recommendation #1)
2. Add Directory Structure section (Recommendation #2)
3. Add Navigation section (Recommendation #4)
4. Update parent ai/README.md (Recommendation #6)

**Estimated Impact**: 50 lines added, no existing content modified

### Phase 2: Ecosystem Integration (Medium Risk)
1. Add Ecosystem Context Note (Recommendation #3)
2. Add Keybinding Coordination Note (Recommendation #5)
3. Add Provider Clarification (Recommendation #7)

**Estimated Impact**: 30 lines added, no existing content modified

### Phase 3: Validation
1. Verify all cross-reference links are valid
2. Test navigation flow from ai/README.md → goose/README.md → picker/README.md
3. Verify no duplication between goose and claude documentation
4. Check for consistent terminology (e.g., "internal system" vs "external plugin")

## Anti-Patterns to Avoid

### 1. Over-Representation of Claude
❌ **Don't**: "For better AI integration, use claude/ instead of goose"
✅ **Do**: "For direct Claude API access, see claude/. For multi-provider support, use goose"

### 2. Duplication of Technical Content
❌ **Don't**: Copy claude's session management explanation into goose docs
✅ **Do**: Note that both have session management, link for comparison if needed

### 3. Minimizing Goose's Strengths
❌ **Don't**: Frame goose as "just a plugin wrapper"
✅ **Do**: Emphasize internal extensions (recipe picker, split mode config, etc.)

### 4. Breaking Existing Navigation
❌ **Don't**: Move or restructure existing sections
✅ **Do**: Add new sections in logical positions without disrupting flow

### 5. Creating Circular References
❌ **Don't**: goose → claude → goose → claude linking loops
✅ **Do**: goose → ai/ ← claude (parent directory as hub)

## Success Metrics

### Documentation Quality
- [ ] Architectural overview clearly separates external plugin from internal extensions
- [ ] Directory structure quantifies internal contributions
- [ ] Navigation enables one-click access to parent and subdirectories
- [ ] Cross-references provide context without duplication

### Ecosystem Integration
- [ ] Parent ai/README.md lists goose/ subdirectory
- [ ] Goose README links to ai/ parent for keybinding coordination
- [ ] Provider clarification prevents Claude Code vs claude/ confusion
- [ ] Keybinding conflicts are documented

### Preservation of Strengths
- [ ] Recipe system documentation remains comprehensive (lines 482-652)
- [ ] Troubleshooting section remains detailed (lines 686-814)
- [ ] Split window mode documentation preserved (lines 19-73)
- [ ] Multi-provider setup instructions unchanged (lines 280-380)

## Appendix: Cross-Reference Decision Matrix

| Goose Section | Cross-Link to Claude? | Rationale |
|---------------|------------------------|-----------|
| Purpose | No | Standalone introduction |
| Architectural Overview | Yes (brief) | Context within ai/ ecosystem |
| Features | No | Goose-specific functionality |
| Configuration | No | Plugin-specific settings |
| Keybindings | Yes (coordination note) | Shared `<leader>a` namespace |
| Backend Configuration | Yes (provider clarification) | Prevent Claude Code confusion |
| Multi-Provider | Yes (brief API note) | Distinguish subscription vs API |
| Usage Workflows | No | Goose-specific workflows |
| Recipes | No | Goose-unique feature |
| Troubleshooting | No | Plugin-specific solutions |
| Navigation | Yes (parent link) | Directory structure navigation |
| References | No | External links only |

## Conclusion

The goose/README.md is technically excellent but lacks ecosystem context. Strategic additions totaling ~80 lines will integrate it into the ai/ plugin ecosystem without compromising its technical depth or over-representing claude documentation. The recommended updates emphasize:

1. **Architectural clarity** - External plugin vs internal extensions
2. **Ecosystem awareness** - Part of multi-AI plugin system
3. **Navigation improvement** - Links to parent and subdirectories
4. **Provider clarification** - Prevent Claude Code vs claude/ confusion
5. **Strength preservation** - Keep excellent recipe and troubleshooting docs intact

These updates follow the claude/README.md structure as a template while respecting goose's unique strengths and avoiding duplication.
