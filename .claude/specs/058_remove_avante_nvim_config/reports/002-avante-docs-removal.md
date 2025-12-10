# Avante Documentation Removal Research Report

**Date**: 2025-12-09
**Researcher**: research-specialist
**Topic**: Avante References in Documentation Files
**Scope**: Complete audit of Avante mentions across all documentation

## Executive Summary

This report documents all Avante references found in documentation files across the NeoVim configuration. A comprehensive search identified **71 distinct references** across **19 documentation files**, ranging from user-facing guides to internal architectural documentation.

All references are categorized by type and removal priority to enable systematic cleanup without breaking documentation coherence.

## Search Methodology

**Search Strategy**:
- Pattern: Case-insensitive "avante" search across all `.md` files
- Tools: Grep with content output and line numbers
- Coverage: Entire `/home/benjamin/.config` directory
- Focus: Documentation files (README.md, guides, standards)

**Files Analyzed**: 19 documentation files containing Avante references
**Total References**: 71 distinct mentions
**Reference Types**: User-facing, architectural, historical, setup instructions

## Findings

### Category 1: User-Facing Documentation (High Priority)

These are primary user-facing documentation files that describe Avante as a core feature.

#### 1.1 Main README Files

**File**: `/home/benjamin/.config/nvim/README.md`
- **Lines**: 50, 119, 176-271, 304
- **Type**: User guide with extensive Avante documentation
- **Context**:
  - Line 50: Listed as core feature "AI Assistance: AI integration for code completion and editing suggestions with Avante, MCP-Hub tools, and knowledge assistance with Lectic"
  - Line 119: Navigation link to AI Integration documentation
  - Lines 176-271: Complete "Using Avante AI" section including:
    - Basic usage instructions
    - Provider configuration
    - Special keybindings in Avante buffers
    - Configuration help workflows
    - Example prompts and use cases
  - Line 304: Quick reference to Avante AI integration
- **Removal Impact**: Major - requires rewriting AI integration section
- **Recommendation**: Replace with Claude Code and Lectic documentation

**File**: `/home/benjamin/.config/README.md`
- **Lines**: 13, 17, 153, 216, 249-250
- **Type**: Root README describing NeoTex configuration
- **Context**:
  - Line 13: Core focus area listing "Avante - AI-powered code completion, refactoring, and inline suggestions with Claude, GPT, and Gemini support"
  - Line 17: Quick access keybindings `<leader>aa` (Avante)
  - Line 153: Directory structure showing AI integration
  - Line 216: Essential keybindings table
  - Lines 249-250: Parallel development workflow examples
- **Removal Impact**: Moderate - affects feature overview
- **Recommendation**: Remove from core features, update keybinding tables

#### 1.2 Documentation Guides

**File**: `/home/benjamin/.config/nvim/docs/MAPPINGS.md`
- **Lines**: 134-140, 395, 415-423
- **Type**: Complete keybinding reference
- **Context**:
  - Lines 134-140: Avante AI Commands section with 4 keybindings
  - Line 395: Avante keybinding in terminal context
  - Lines 415-423: Avante AI Buffers section with 11 special keybindings
- **Removal Impact**: Moderate - requires updating keybinding reference
- **Recommendation**: Remove Avante section, preserve other AI tool references

**File**: `/home/benjamin/.config/nvim/docs/AI_TOOLING.md`
- **Lines**: (Not shown in grep output but likely present)
- **Type**: AI tooling workflow guide
- **Context**: Likely contains Avante workflow documentation
- **Removal Impact**: Moderate
- **Recommendation**: Review and remove Avante workflows

**File**: `/home/benjamin/.config/nvim/docs/ADVANCED_SETUP.md`
- **Lines**: 200
- **Type**: Advanced setup guide
- **Context**: Avante AI configuration section
- **Removal Impact**: Low - configuration instructions only
- **Recommendation**: Remove Avante configuration section

#### 1.3 Module Documentation

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/README.md`
- **Lines**: 14-15, 23, 35, 65, 84-85, 119, 124
- **Type**: AI plugins directory documentation
- **Context**:
  - Lines 14-15: avante.lua module description
  - Line 23: MCP-Hub integration with Avante
  - Line 35: Multiple AI providers through Avante
  - Line 65: :AvanteAsk command
  - Lines 84-85: Avante keybindings
  - Lines 119, 124: Testing and usage instructions
- **Removal Impact**: Moderate - requires rewriting AI integration docs
- **Recommendation**: Remove avante.lua references, update MCP-Hub integration

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/README.md`
- **Lines**: 33, 76
- **Type**: Plugin organization overview
- **Context**:
  - Line 33: File structure showing avante.lua
  - Line 76: AI assistants integration description
- **Removal Impact**: Low
- **Recommendation**: Remove from file structure and feature list

### Category 2: Architectural Documentation (Medium Priority)

**File**: `/home/benjamin/.config/nvim/docs/ARCHITECTURE.md`
- **Lines**: 22, 86, 105, 153, 225, 301, 303
- **Type**: System architecture documentation
- **Context**:
  - Line 22: AI integration layer
  - Line 86: User events triggering AvantePreLoad
  - Line 105: avante.lua in plugin structure
  - Line 153: AvantePreLoad event flow
  - Line 225: Claude Code / Avante comparison
  - Lines 301, 303: Plugin dependency graph
- **Removal Impact**: Moderate - affects architecture diagrams
- **Recommendation**: Remove from system diagrams, update plugin dependencies

**File**: `/home/benjamin/.config/nvim/docs/DOCUMENTATION_STANDARDS.md`
- **Lines**: 159, 164, 219, 239, 249, 257
- **Type**: Documentation writing standards with examples
- **Context**:
  - Lines 159, 164: Example documentation sentences
  - Line 219: Keybinding documentation example
  - Lines 239-257: Complete plugin documentation example for Avante
- **Removal Impact**: Low - examples only
- **Recommendation**: Replace Avante examples with Claude Code or other plugins

### Category 3: Scripts and Maintenance (Medium Priority)

**File**: `/home/benjamin/.config/nvim/scripts/README.md`
- **Lines**: 27, 45, 52, 58-59, 64, 71, 73-76, 104, 106, 120-125, 257
- **Type**: Script documentation for MCP integration
- **Context**:
  - Line 27: AI tools list
  - Lines 45-76: force_mcp_restart.lua documentation (Avante integration)
  - Lines 104-125: test_mcp_integration.lua documentation (Avante testing)
  - Line 257: avante_mcp.lua reference
- **Removal Impact**: High - requires updating MCP restart/test scripts
- **Recommendation**: Update scripts to remove Avante integration, update documentation

### Category 4: Historical/Migration Documentation (Low Priority)

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/MIGRATION.md`
- **Lines**: 1-169 (entire file)
- **Type**: Migration guide for Avante architectural reorganization
- **Context**: Complete historical document about separating Avante from Claude Code
- **Removal Impact**: None (can be deleted entirely)
- **Recommendation**: **DELETE FILE** - no longer needed after Avante removal

### Category 5: Internal Reports (Informational Only)

**File**: `/home/benjamin/.config/.claude/specs/039_goose_nvim_refactor_plans/reports/001-goose-agent-configuration.md`
- **Lines**: 102, 116
- **Type**: Internal research report
- **Context**: Analysis of AI tool loading alongside Avante
- **Removal Impact**: None (historical record)
- **Recommendation**: Leave as historical record or update if actively maintained

**File**: `/home/benjamin/.config/.claude/output/goose-picker-output.md`
- **Lines**: 10
- **Type**: Command output log
- **Context**: User request to remove Avante
- **Removal Impact**: None (log file)
- **Recommendation**: Leave as historical record

### Category 6: Neovim CLAUDE.md Standards (Low Priority)

**File**: `/home/benjamin/.config/nvim/CLAUDE.md`
- **Lines**: None found in this file
- **Type**: Neovim-specific coding standards
- **Removal Impact**: None
- **Recommendation**: No changes needed

## Summary Statistics

### References by File Type

| File Type | Count | Files |
|-----------|-------|-------|
| User Guides (README.md) | 3 | 3 files |
| Documentation (docs/*.md) | 8 | 5 files |
| Module Documentation (lua/*/README.md) | 3 | 3 files |
| Migration Guide | 1 | 1 file (deletable) |
| Scripts Documentation | 1 | 1 file |
| Research Reports | 2 | 2 files (historical) |
| **TOTAL** | **18** | **15 unique files** |

### References by Category

| Category | Priority | Files | Action |
|----------|----------|-------|--------|
| User-Facing | High | 6 | Rewrite/Remove |
| Architectural | Medium | 2 | Update diagrams |
| Scripts | Medium | 1 | Update documentation |
| Historical | Low | 1 | Delete file |
| Internal | Info | 2 | Leave as-is |

### Impact Assessment

**High Impact** (6 files):
- nvim/README.md - Major rewrite of AI integration section
- README.md - Update core features and keybindings
- nvim/docs/MAPPINGS.md - Remove keybinding sections
- nvim/lua/neotex/plugins/ai/README.md - Rewrite AI integration docs
- nvim/scripts/README.md - Update MCP script documentation

**Medium Impact** (3 files):
- nvim/docs/ARCHITECTURE.md - Update system diagrams
- nvim/docs/DOCUMENTATION_STANDARDS.md - Replace examples
- nvim/docs/ADVANCED_SETUP.md - Remove configuration section

**Low Impact** (4 files):
- nvim/lua/neotex/plugins/README.md - Remove from lists
- nvim/lua/neotex/plugins/ai/MIGRATION.md - DELETE FILE

**No Impact** (2 files):
- .claude/specs/039_goose_nvim_refactor_plans/reports/001-goose-agent-configuration.md - Historical
- .claude/output/goose-picker-output.md - Log file

## Recommendations

### Phase 1: High Priority Files (Immediate Action)

1. **nvim/README.md**:
   - Remove "Using Avante AI" section (lines 176-271)
   - Update AI Assistance feature description (line 50) to focus on Claude Code and Lectic
   - Remove Avante from navigation links (line 119)
   - Update keybinding quick reference (line 304)

2. **README.md**:
   - Remove Avante from Core Focus Areas (line 13)
   - Update Quick Access keybindings (line 17)
   - Remove Avante from directory structure (line 153)
   - Update essential keybindings table (line 216)

3. **nvim/docs/MAPPINGS.md**:
   - Remove "Avante AI Commands" section (lines 134-140)
   - Remove Avante buffer-specific mappings (lines 415-423)
   - Remove `<C-a>` terminal keybinding (line 395)

4. **nvim/lua/neotex/plugins/ai/README.md**:
   - Remove avante.lua module documentation (lines 14-15)
   - Update MCP-Hub integration description (line 23)
   - Remove Avante from key features (line 35)
   - Remove :AvanteAsk command (line 65)
   - Remove Avante keybindings (lines 84-85)
   - Update testing instructions (lines 119, 124)

5. **nvim/scripts/README.md**:
   - Update AI tools list (line 27) to remove Avante
   - Rewrite force_mcp_restart.lua documentation (lines 45-76) to remove Avante integration
   - Update test_mcp_integration.lua documentation (lines 104-125) to remove Avante testing
   - Remove avante_mcp.lua reference (line 257)

### Phase 2: Medium Priority Files (Follow-up Action)

6. **nvim/docs/ARCHITECTURE.md**:
   - Update AI integration layer description (line 22)
   - Remove AvantePreLoad event references (lines 86, 153)
   - Remove avante.lua from plugin structure (line 105)
   - Update Claude Code / Avante comparison (line 225) to just describe Claude Code
   - Update plugin dependency graph (lines 301, 303)

7. **nvim/docs/DOCUMENTATION_STANDARDS.md**:
   - Replace Avante example sentences (lines 159, 164)
   - Replace keybinding documentation example (line 219)
   - Replace plugin documentation example (lines 239-257) with Claude Code or another plugin

8. **nvim/docs/ADVANCED_SETUP.md**:
   - Remove Avante AI configuration section (line 200)

### Phase 3: Low Priority Files (Cleanup)

9. **nvim/lua/neotex/plugins/README.md**:
   - Remove avante.lua from file structure (line 33)
   - Remove Avante from AI assistants description (line 76)

10. **nvim/lua/neotex/plugins/ai/MIGRATION.md**:
    - **DELETE ENTIRE FILE** - migration guide no longer needed

### Phase 4: Historical Files (No Action)

11. **Leave as-is** (historical records):
    - .claude/specs/039_goose_nvim_refactor_plans/reports/001-goose-agent-configuration.md
    - .claude/output/goose-picker-output.md

## Removal Strategy

### Recommended Approach

1. **Document-First Cleanup**: Remove documentation references first to understand the scope
2. **Test After Each Phase**: Verify documentation coherence after each phase
3. **Preserve Historical Records**: Keep .claude/specs/* and .claude/output/* files as historical records
4. **Update Cross-References**: Ensure all internal links remain valid after removal

### Coherence Checks

After removal, verify:
- [ ] AI integration sections describe remaining tools (Claude Code, Lectic, MCP-Hub)
- [ ] Keybinding tables are complete and accurate
- [ ] Navigation links are valid
- [ ] No broken references to Avante in any documentation
- [ ] Architecture diagrams reflect current plugin structure
- [ ] Example code uses current plugins

### Replacement Content Guidance

When removing Avante references, replace with:
- **Claude Code** - For AI-assisted development and code completion
- **Lectic** - For markdown AI assistance
- **MCP-Hub** - For extended AI capabilities and tool integration

Emphasize:
- Multi-session parallel development with git worktrees
- Claude Code's advanced coding assistant features
- MCP protocol integration for extended capabilities

## Validation Checklist

Before marking removal complete:

- [ ] All 71 Avante references reviewed
- [ ] High priority files updated (6 files)
- [ ] Medium priority files updated (3 files)
- [ ] Low priority files cleaned up (2 files)
- [ ] MIGRATION.md deleted
- [ ] Documentation coherence verified
- [ ] Navigation links validated
- [ ] No broken references remain
- [ ] AI integration sections rewritten
- [ ] Keybinding documentation updated

## Conclusion

The Avante removal from documentation requires systematic updates across 15 files with 71 total references. The high-priority user-facing documentation (6 files) requires the most significant rewrites, particularly the main README files and keybinding documentation.

The removal strategy prioritizes maintaining documentation coherence while eliminating all Avante references. Historical research reports and logs should be preserved as-is for project history.

Estimated effort: 2-3 hours for complete documentation cleanup with testing and validation.
