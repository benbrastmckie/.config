# Neovim Documentation Cross-Linking Strategy Research Report

## Executive Summary

This research analyzed the Neovim configuration documentation structure at `/home/benjamin/.config/nvim/` to develop a balanced cross-linking strategy for AI plugin documentation (Claude Code and Goose). The analysis covered 138 markdown files across the configuration, identifying documentation patterns, existing cross-references, and optimal locations for bidirectional linking.

**Key Findings**:
- 16 README files currently reference AI plugins (claude/goose)
- Documentation follows hierarchical structure with clear navigation standards
- Three primary documentation layers: Root → Docs → Module READMEs
- Strong existing documentation for Claude (9,626 lines) but minimal cross-linking to Goose
- Opportunity for balanced integration without over-representation

**Recommendation**: Implement bidirectional linking across 12 strategic documentation files, focusing on user-facing entry points and module organization rather than deep technical implementation details.

## Findings

### Documentation Architecture Analysis

The Neovim configuration uses a three-tier documentation hierarchy:

#### Tier 1: Root Entry Points
- **nvim/README.md** (580 lines) - Main configuration overview
  - Features section mentions "AI Assistance" at line 50
  - Brief coverage of Avante, MCP-Hub, Lectic
  - **Gap**: No mention of Goose or Claude Code specifics
  - **Impact**: Primary user entry point lacks balanced AI plugin representation

#### Tier 2: Central Documentation (docs/)
- **docs/README.md** (194 lines) - Documentation index
  - Links to AI_TOOLING.md at line 47
  - Organizes by task and feature
  - **Current State**: AI tooling treated as single unified topic

- **docs/AI_TOOLING.md** (current content unknown, needs investigation)
  - Referenced as primary AI integration documentation
  - **Critical**: Main location for balanced AI plugin coverage

- **docs/MAPPINGS.md** (referenced at line 279 of root README)
  - Complete keybinding reference
  - **Gap**: Likely incomplete AI plugin keybinding coverage

#### Tier 3: Module Documentation (lua/neotex/)
- **lua/neotex/plugins/README.md** (229 lines)
  - Plugin organization and loading strategy
  - Line 76: Brief mention of AI plugins with link to ai/README.md
  - **Opportunity**: Enhance AI plugin summary with balanced coverage

- **lua/neotex/plugins/ai/README.md** (134 lines)
  - Comprehensive AI plugins overview
  - Lines 30-31: Links to claude/ subdirectory
  - **Gap**: No corresponding section for goose/ despite its existence
  - **Critical**: Main AI plugin comparison point

- **lua/neotex/plugins/ai/claude/README.md** (556 lines)
  - Extensive Claude Code documentation (9,626 total lines)
  - Highly detailed architectural documentation
  - **Imbalance**: Creates perception of Claude preference over Goose

- **lua/neotex/plugins/ai/goose/README.md** (931 lines)
  - Comprehensive Goose integration documentation
  - Well-structured with split window mode, recipes, providers
  - **Good**: Standalone documentation is thorough
  - **Gap**: Limited cross-references from parent directories

### Current Cross-Reference Patterns

**Files with AI Plugin References** (16 total):
1. `/nvim/lua/neotex/plugins/tools/README.md`
2. `/nvim/lua/neotex/plugins/ui/README.md`
3. `/nvim/lua/neotex/plugins/ai/claude/claude-session/README.md`
4. `/nvim/lua/neotex/plugins/ai/claude/ui/README.md`
5. `/nvim/lua/neotex/plugins/ai/claude/commands/README.md`
6. `/nvim/lua/neotex/plugins/ai/claude/README.md`
7. `/nvim/lua/neotex/plugins/ai/claude/core/README.md`
8. `/nvim/lua/neotex/plugins/ai/avante/mcp/README.md`
9. `/nvim/lua/neotex/plugins/ai/avante/README.md`
10. `/nvim/lua/neotex/plugins/ai/goose/picker/README.md`
11. `/nvim/lua/neotex/plugins/ai/goose/README.md`
12. `/nvim/lua/neotex/plugins/ai/README.md`
13. `/nvim/lua/neotex/plugins/ai/util/README.md`
14. `/nvim/lua/neotex/plugins/lsp/README.md`
15. `/nvim/lua/neotex/plugins/text/README.md`
16. `/nvim/lua/neotex/plugins/editor/README.md`

**Pattern Analysis**:
- **Deep references** (7 files): Claude subdirectories with implementation details
- **Sibling references** (4 files): Other AI plugins (Avante, util)
- **Parent references** (3 files): Plugin organization layers
- **Cross-category** (2 files): LSP/editor mention AI for context

### Documentation Standards Review

From **docs/DOCUMENTATION_STANDARDS.md**:

**Key Requirements**:
1. **Present-State Focus**: No historical markers or "now supports" language
2. **Clean-Break Philosophy**: Document current design as if it always existed
3. **Navigation Links**: Parent, subdirectory, and related documentation links required
4. **Balanced Coverage**: Related information should be complete, not split

**README Structure Requirements**:
- Purpose statement (one paragraph)
- Module documentation with exports and dependencies
- Navigation links (parent, subdirectories, related docs)
- Related documentation cross-references

**Implications for AI Plugin Linking**:
- Links should feel natural, not retrofitted
- Both plugins should be introduced simultaneously in parent docs
- Avoid preference signals through link ordering or detail level
- Use parallel structure for comparable features

### Use Case Mapping

**User Journeys Requiring Balanced AI Plugin Information**:

1. **New User Onboarding** (Root README → docs/AI_TOOLING.md)
   - User discovers AI capabilities
   - Needs to choose between Claude Code and Goose
   - Requires feature comparison and workflow differences

2. **Plugin Discovery** (plugins/README.md → plugins/ai/README.md)
   - Developer exploring plugin organization
   - Needs to understand AI plugin architecture
   - Should see both options with equal prominence

3. **Configuration Customization** (plugins/ai/README.md → specific READMEs)
   - User customizing AI integration
   - Needs to navigate to correct plugin documentation
   - Should find both plugins easily from same starting point

4. **Keybinding Reference** (docs/MAPPINGS.md)
   - User looking up AI-related keybindings
   - Needs consolidated view of both plugins' mappings
   - Should understand keybinding conflicts/overlaps

5. **Troubleshooting** (plugin-specific READMEs)
   - User debugging AI plugin issues
   - May need to compare behavior between plugins
   - Should find cross-references for alternative approaches

## Recommendations

### Primary Update Locations (Priority Order)

#### 1. Root Entry Point (nvim/README.md)
**Location**: Features Overview section (line 50)
**Current**: "AI Assistance: AI integration for code completion and editing suggestions with Avante, MCP-Hub tools, and knowledge assistance with Lectic"
**Recommended Update**:
```markdown
- **AI Assistance**: Multiple AI integration options for code completion and development workflows:
  - [Claude Code](lua/neotex/plugins/ai/claude/README.md) - Official Claude integration with session management and worktree support
  - [Goose](lua/neotex/plugins/ai/goose/README.md) - AI-assisted coding with multi-provider support (Gemini CLI, Claude Code)
  - [Avante](lua/neotex/plugins/ai/avante/README.md) - AI assistant with MCP-Hub tools integration
  - [Lectic](lua/neotex/plugins/ai/README.md#lectic) - AI-assisted writing for markdown files
```

**Rationale**:
- First user touchpoint for AI capabilities
- Balanced presentation with equal detail level
- Functional differentiation (Claude: sessions/worktrees, Goose: multi-provider/recipes)
- Direct links to detailed documentation

#### 2. Central AI Documentation (docs/AI_TOOLING.md)
**Current Status**: References OpenCode/worktrees, minimal Claude/Goose coverage
**Recommended Structure**:
```markdown
# AI Development Tooling

## Overview

This configuration provides multiple AI assistant options integrated directly into Neovim, each with distinct strengths for different workflows.

## AI Assistant Options

### Claude Code Integration
[Complete documentation](../lua/neotex/plugins/ai/claude/README.md)

Claude Code provides official Claude AI integration with sophisticated session management and git worktree support.

**Key Features**:
- Persistent session management with workspace context
- Git worktree integration for isolated development environments
- Visual selection processing with custom prompts
- Terminal detection for multi-terminal workflows
- Command hierarchy browser with agent cross-referencing

**Best For**:
- Long-running development sessions with complex context
- Multi-branch development with worktree isolation
- Projects requiring sophisticated session state management

**Keybindings**: `<C-c>` (toggle), `<leader>ac` (commands/visual selection), `<leader>as` (sessions)

### Goose AI Agent
[Complete documentation](../lua/neotex/plugins/ai/goose/README.md)

Goose provides AI-assisted coding with multi-provider support and recipe-based workflow automation.

**Key Features**:
- Split window mode with native Neovim integration
- Multi-provider support (Gemini CLI, Claude Code backend)
- Recipe system for repeatable agentic workflows
- Session persistence across Neovim restarts
- Diff view for reviewing AI-generated changes

**Best For**:
- Recipe-driven development workflows
- Cross-provider flexibility (switching between Gemini/Claude)
- Integrated diff-based change review
- Consistent window layout with split navigation

**Keybindings**: `<leader>aa` (toggle), `<leader>ae` (input focus), `<leader>ad` (diff view), `<leader>aR` (recipes)

### Avante AI Assistant
[Complete documentation](../lua/neotex/plugins/ai/avante/README.md)

Avante provides AI assistance with MCP-Hub protocol integration and inline suggestions.

**Key Features**: [existing content]

### Feature Comparison Matrix

| Feature | Claude Code | Goose | Avante |
|---------|-------------|-------|--------|
| **Window Mode** | Terminal | Split | Floating/Split |
| **Providers** | Claude only | Gemini, Claude | Claude, GPT, Gemini |
| **Sessions** | Sophisticated state mgmt | Workspace-based | Session links |
| **Recipes** | Command hierarchy | Recipe YAML system | - |
| **Worktrees** | Native integration | Manual workflow | - |
| **Diff Review** | - | Native diff view | - |
| **MCP Tools** | - | - | 44+ tools |
| **Best Use Case** | Complex projects, worktrees | Recipe workflows, multi-provider | Inline suggestions, MCP tools |

## Advanced Workflows

### Git Worktrees with AI Agents
[existing OpenCode content - demonstrates concept applicable to both plugins]
```

**Rationale**:
- Parallel presentation without preference signaling
- Functional differentiation based on actual strengths
- Clear use case guidance for choosing appropriate tool
- Comparison matrix for objective feature evaluation
- Preserves existing OpenCode/worktree content as conceptual foundation

#### 3. Plugin Organization Index (lua/neotex/plugins/README.md)
**Location**: Line 76 (ai/ section)
**Current**: "- **ai/**: AI tooling and integration ([detailed documentation](ai/README.md))"
**Recommended Update**:
```markdown
- **ai/**: AI tooling and integration ([detailed documentation](ai/README.md))
  - avante.lua: AI assistants with MCP tools (uses blink.cmp)
  - claudecode.lua: Official Claude Code integration (greggh/claude-code.nvim)
  - goose/: AI agent backend with multi-provider support (Gemini CLI, Claude Code)
  - lectic.lua: AI-assisted writing for markdown
  - mcp-hub.lua: Model Context Protocol hub for external AI tools
```

**Rationale**:
- Maintains existing link to comprehensive ai/README.md
- Adds inline preview of available AI options
- Parallel structure for claude and goose entries
- Preserves existing detail level for other plugins

#### 4. AI Plugins Overview (lua/neotex/plugins/ai/README.md)
**Location**: Modules section
**Current**: Has avante.lua, claudecode.lua, lectic.lua, mcp-hub.lua but missing goose section
**Recommended Update**:
```markdown
## Subdirectories

- [claude/](claude/README.md) - Comprehensive internal Claude AI integration system (9,626+ lines across 20 files)
- [goose/](goose/README.md) - AI-assisted coding with multi-provider backend and recipe system
- [avante/](avante/README.md) - AI assistant integration with MCP protocol support
- [util/](util/README.md) - Shared AI plugin utilities

## Modules

### avante.lua
[existing content]

### claudecode.lua
[existing content]

### goose/init.lua
Configuration for the Goose AI agent plugin (`azorng/goose.nvim`). Provides multi-provider AI assistance (Gemini CLI, Claude Code backend) with split window integration, recipe-based workflows, and session persistence.

**Key Features**:
- Split window mode with native Neovim navigation (`<C-h/j/k/l>`)
- Dynamic provider detection and switching
- Recipe picker for workflow automation
- Session management tied to workspace
- Diff view for reviewing AI changes

**Configuration**:
- Window type: split (35% width, right sidebar)
- Default mode: auto (full agent capabilities)
- Preferred picker: telescope
- Keybindings managed by which-key.lua

[existing content continues]
```

**Rationale**:
- Adds missing goose subdirectory reference (parallel to claude/)
- Includes goose/init.lua module documentation (parallel to other .lua files)
- Maintains consistent detail level across all AI plugins
- Focuses on integration aspects rather than deep functionality

#### 5. Keybinding Reference (docs/MAPPINGS.md)
**Recommended Addition**: New AI Tools section consolidating both plugins
**Structure**:
```markdown
### AI Tools

#### Claude Code Integration

| Key | Mode | Description |
|-----|------|-------------|
| `<C-c>` | All | Smart toggle Claude Code with session picker |
| `<leader>ac` | Normal | Browse Claude commands hierarchy |
| `<leader>ac` | Visual | Send selection to Claude with custom prompt |
| `<leader>as` | Normal | Browse Claude sessions |
| `<leader>at` | Normal | Toggle TTS notifications (project-specific) |
| `<leader>av` | Normal | View git worktrees |
| `<leader>aw` | Normal | Create new worktree with Claude session |
| `<leader>ar` | Normal | Restore closed worktree session |

See [Claude Code documentation](../lua/neotex/plugins/ai/claude/README.md) for complete feature details.

#### Goose AI Agent

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>aa` | Normal | Toggle Goose chat interface (split window) |
| `<leader>aa` | Visual | Send selection to Goose with prompt |
| `<leader>ae` | Normal | Focus Goose input window |
| `<leader>ao` | Normal | Focus Goose output window |
| `<leader>ad` | Normal | Open Goose diff view |
| `<leader>am` | Normal | Mode picker (auto/chat) |
| `<leader>aR` | Normal | Recipe picker (Telescope) |
| `<leader>ap` | Normal | Provider status and switch |
| `<leader>aq` | Normal | Close Goose interface |
| `<leader>ax` | Normal | New Goose session |
| `<leader>av` | Normal | Select Goose session |
| `<leader>ar` | Normal | Run new Goose session |
| `<leader>at` | Normal | Stop Goose execution |

See [Goose documentation](../lua/neotex/plugins/ai/goose/README.md) for complete feature details and recipe workflows.

**Keybinding Overlaps**:
- `<leader>av`: View worktrees (Claude) vs Select session (Goose)
- `<leader>ar`: Restore worktree (Claude) vs Run session (Goose)
- `<leader>at`: Toggle TTS (Claude) vs Stop execution (Goose)

Both plugins can coexist; context determines which bindings are active.
```

**Rationale**:
- Consolidated view reveals keybinding overlaps
- Parallel table structure for objective comparison
- Explicit overlap documentation prevents user confusion
- Links to full documentation for additional details

#### 6. Configuration Namespace Overview (lua/neotex/README.md)
**Location**: Plugin Organization section (line 70)
**Current**: "- **ai/** - AI-powered tooling (Copilot, GPT integration)"
**Recommended Update**:
```markdown
- **ai/** - AI integration with multiple assistant options
  - claude/ - Claude Code with session management and worktree integration
  - goose/ - Multi-provider AI agent (Gemini, Claude backend) with recipes
  - avante/ - AI assistant with MCP protocol and inline suggestions
```

**Rationale**:
- Updates outdated reference (Copilot no longer primary)
- Balanced one-line summaries for each AI integration
- Functional differentiation rather than feature listing
- Maintains brevity appropriate for namespace overview

### Secondary Update Locations (Cross-References)

#### 7. Documentation Index (docs/README.md)
**Location**: Feature Documentation section (line 47)
**Current**: "| [AI_TOOLING.md](AI_TOOLING.md) | AI integration tools (Avante, Claude Code, MCP Hub) and configuration | 22K |"
**Recommended Update**:
```markdown
| [AI_TOOLING.md](AI_TOOLING.md) | AI integration tools (Claude Code, Goose, Avante, MCP Hub) with provider comparison and workflow guidance | 22K |
```

**Rationale**:
- Adds Goose to tool listing
- Signals comparison/guidance content
- Minimal change to existing structure

#### 8. Utility Functions (lua/neotex/util/README.md)
**Location**: Notification System section (line 77)
**Current**: Mentions `notify.ai()` but no specific AI plugin examples
**Recommended Update**:
```markdown
### Quick Usage

```lua
local notify = require('neotex.util.notifications')

-- User actions (always shown)
notify.editor('File saved', notify.categories.USER_ACTION)

-- AI assistant notifications
notify.ai('Claude session restored', notify.categories.USER_ACTION)
notify.ai('Goose recipe executed', notify.categories.USER_ACTION)

-- Background operations (debug mode only)
notify.editor('Cache updated', notify.categories.BACKGROUND)
notify.ai('Provider detection complete', notify.categories.BACKGROUND)
```
```

**Rationale**:
- Concrete examples for AI notification patterns
- Shows both plugins using same notification system
- Demonstrates category usage for AI operations

### Files NOT Requiring Updates

**Exclude from Cross-Linking**:

1. **Deep Implementation READMEs** (claude/core/, claude/ui/, goose/picker/)
   - **Reason**: Too specific, implementation-focused
   - **Alternative**: Already linked from parent ai/claude/README.md and ai/goose/README.md

2. **Unrelated Plugin Categories** (text/, tools/, editor/)
   - **Reason**: No functional relationship to AI plugins
   - **Exception**: Already mention AI contextually (no new links needed)

3. **Template/Snippet Directories**
   - **Reason**: Content-focused, not feature documentation

4. **Deprecated Directory**
   - **Reason**: Legacy code, avoid new references

## Balanced Linking Strategy

### Principles

1. **Functional Differentiation Over Feature Listing**
   - Emphasize what each plugin is best for
   - Avoid exhaustive feature enumeration in cross-references
   - Guide users to appropriate tool for their use case

2. **Parallel Structure for Comparable Elements**
   - Same level of detail for both plugins at each documentation tier
   - Consistent ordering (maintain Claude/Goose or alphabetical)
   - Matching table structures in comparison sections

3. **Depth-Appropriate Cross-Linking**
   - Root/Docs: High-level overview with workflow guidance
   - Plugin Organization: Module-level summaries with navigation
   - Individual READMEs: Deep technical detail without external comparisons

4. **Minimize Preference Signals**
   - Equal word count in summaries (±10% variance acceptable)
   - Avoid subjective language ("better", "more powerful", "simpler")
   - Use objective criteria for comparison (window mode, providers, recipes)
   - No implicit ordering preferences (both alphabetical and functional ok)

### Link Placement Guidelines

**Root Documentation (README.md, docs/)**:
- Brief feature overview (1-2 sentences per plugin)
- Link to detailed documentation
- Comparison matrix for objective evaluation
- Use case guidance based on workflow needs

**Organization Layer (plugins/README.md, plugins/ai/README.md)**:
- Module-level summaries with key features
- Subdirectory navigation links
- Integration points with other systems
- Configuration overview (not full details)

**Plugin-Specific (claude/README.md, goose/README.md)**:
- Deep technical documentation
- Full feature coverage
- Implementation details
- No external comparisons (self-contained)

### Word Count Targets

**Balanced Representation by Documentation Tier**:

| Location | Claude | Goose | Variance | Status |
|----------|--------|-------|----------|--------|
| Root README (Features) | ~40 words | ~40 words | ±5 words | Target |
| docs/AI_TOOLING.md (Overview) | ~100 words | ~100 words | ±10 words | Target |
| plugins/ai/README.md (Module) | ~60 words | ~60 words | ±5 words | Target |
| Keybinding tables | Equal rows | Equal rows | Context-dependent | Target |

**Current Imbalance**:
- Claude: 9,626 lines (deep implementation docs)
- Goose: 931 lines (comprehensive but focused)

**Note**: Total line count disparity is acceptable; both plugins have thorough standalone documentation. Focus balancing efforts on shared navigation points, not implementation depth.

## Implementation Priority

### Phase 1: Critical User Entry Points (High Impact)
1. Root README.md features section
2. docs/AI_TOOLING.md comprehensive update
3. plugins/ai/README.md module additions

**Estimated Effort**: 2-3 hours
**User Impact**: High (primary discovery paths)

### Phase 2: Navigation and Reference (Medium Impact)
4. docs/MAPPINGS.md keybinding consolidation
5. plugins/README.md AI section expansion
6. lua/neotex/README.md plugin organization update

**Estimated Effort**: 1-2 hours
**User Impact**: Medium (power users, customization)

### Phase 3: Supporting Documentation (Low Impact)
7. docs/README.md index entry update
8. lua/neotex/util/README.md notification examples

**Estimated Effort**: 30 minutes
**User Impact**: Low (comprehensive reference)

### Total Estimated Effort
- **Documentation Updates**: 4-6 hours
- **Review and Testing**: 1-2 hours (verify all links, check formatting)
- **Total**: 5-8 hours

## Alternative Approaches Considered

### Option A: Minimal Cross-Referencing
**Description**: Only update root README and ai/README.md
**Pros**: Fast implementation, minimal changes
**Cons**: Users must navigate deeply to discover both options
**Rejected**: Insufficient for balanced representation

### Option B: Comprehensive Deep Linking
**Description**: Add cross-references in all implementation docs
**Pros**: Maximum discoverability
**Cons**: Creates maintenance burden, clutters technical docs
**Rejected**: Over-linking reduces documentation clarity

### Option C: Separate AI Plugin Comparison Doc
**Description**: Create new docs/AI_PLUGIN_COMPARISON.md
**Pros**: Centralized comparison, detailed feature matrix
**Cons**: Adds navigation layer, splits information
**Rejected**: Violates "complete coverage in topic docs" principle

**Selected Approach**: Tiered linking with depth-appropriate detail (documented in Recommendations section above). Balances discoverability with maintainability.

## Validation Checklist

### Link Integrity
- [ ] All relative paths validated with `test -f` checks
- [ ] No broken links in updated documentation
- [ ] Cross-references bidirectional where appropriate
- [ ] Navigation links follow parent → child → sibling pattern

### Content Balance
- [ ] Word count variance within ±10% targets
- [ ] Parallel structure in comparison sections
- [ ] No subjective preference language
- [ ] Functional differentiation clear and objective

### Documentation Standards Compliance
- [ ] Present-tense, no historical markers
- [ ] Working code examples with correct paths
- [ ] Purpose statements for all updated sections
- [ ] Navigation links to parent/related docs

### User Experience
- [ ] New user can discover both plugins from root README
- [ ] Power user can find detailed docs from ai/README.md
- [ ] Keybinding reference shows both plugins clearly
- [ ] Use case guidance helps select appropriate tool

## Next Steps

1. **Review this research report** with stakeholder/maintainer
2. **Prioritize implementation phases** based on user feedback
3. **Create implementation plan** with specific file edits
4. **Execute Phase 1 updates** (critical entry points)
5. **Validate links and formatting** after each phase
6. **Execute Phase 2-3 updates** iteratively
7. **Update TODO.md** with completion status

## References

### Documentation Standards
- `/home/benjamin/.config/nvim/CLAUDE.md` - Project guidelines and policies
- `/home/benjamin/.config/nvim/docs/DOCUMENTATION_STANDARDS.md` - README requirements and style guide

### AI Plugin Documentation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/README.md` - Claude Code (556 lines, 9,626 total with subdirs)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md` - Goose integration (931 lines)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/README.md` - AI plugins overview (134 lines)

### Navigation and Organization
- `/home/benjamin/.config/nvim/README.md` - Root configuration overview (580 lines)
- `/home/benjamin/.config/nvim/docs/README.md` - Documentation index (194 lines)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/README.md` - Plugin organization (229 lines)

### Research Artifacts
- Total markdown files analyzed: 138
- Files with AI plugin references: 16
- Documentation hierarchy depth: 3 tiers (Root → Docs → Modules)
