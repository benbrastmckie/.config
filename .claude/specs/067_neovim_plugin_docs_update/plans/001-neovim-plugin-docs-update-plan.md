# Neovim AI Plugin Documentation Cross-Linking Implementation Plan

**Date**: 2025-12-09
**Feature**: Update Neovim documentation to provide balanced cross-linking between goose/README.md and claude/README.md without over-representing either plugin
**Status**: [NOT STARTED]
**Estimated Hours**: 4-6 hours
**Standards File**: /home/benjamin/.config/CLAUDE.md
**Research Reports**:
- [Goose Plugin Documentation Research](../reports/001-goose-plugin-documentation.md)
- [Claude Plugin Documentation Research](../reports/002-claude-plugin-documentation.md)
- [Neovim Documentation Cross-Linking Strategy](../reports/003-neovim-documentation-linking.md)

## Overview

This plan implements a balanced cross-linking strategy across the Neovim configuration documentation to integrate goose and Claude AI plugins equally without over-representing either. The research identified that current documentation lacks ecosystem context, has minimal cross-references between AI plugins, and creates perception of preference through documentation imbalance.

### Problem Statement

**Current State**:
- Claude README: 556 lines with 9,626 lines across 20 modules, operates in isolation
- Goose README: 931 lines with excellent technical depth, limited ecosystem integration
- No parent directory ecosystem context linking the AI plugins together
- Root and docs/ entry points don't mention both plugins with equal prominence
- Missing keybinding coordination documentation (both use `<leader>a` namespace with overlaps)

**Desired State**:
- Bidirectional cross-linking across 12 strategic documentation files
- Balanced presentation at all documentation tiers (Root → Docs → Module READMEs)
- Functional differentiation (when to use which tool) rather than preference signals
- Ecosystem awareness with clear navigation between related AI plugins

### Success Criteria

- [ ] Root README features section lists both Claude and Goose with equal detail
- [ ] docs/AI_TOOLING.md provides comprehensive comparison and use case guidance
- [ ] plugins/ai/README.md includes goose subdirectory reference parallel to Claude
- [ ] docs/MAPPINGS.md consolidates AI keybindings with overlap documentation
- [ ] All cross-references use parallel structure and balanced word counts (±10%)
- [ ] No subjective preference language in any documentation updates
- [ ] Link integrity validated for all relative paths
- [ ] Documentation follows clean-break philosophy (present state, no historical markers)

## Architecture

### Documentation Hierarchy

The Neovim configuration uses three-tier documentation structure:

```
Tier 1: Root Entry Points
├── nvim/README.md (580 lines) - Main configuration overview
└── docs/ (194 lines) - Central documentation index

Tier 2: Central Documentation
├── docs/AI_TOOLING.md - AI integration comprehensive coverage
├── docs/MAPPINGS.md - Complete keybinding reference
└── plugins/README.md (229 lines) - Plugin organization index

Tier 3: Module Documentation
├── plugins/ai/README.md (134 lines) - AI plugins overview
├── plugins/ai/claude/README.md (556 lines) - Claude deep docs
└── plugins/ai/goose/README.md (931 lines) - Goose deep docs
```

### Balanced Linking Strategy

**Principles**:
1. **Functional Differentiation**: Emphasize what each plugin is best for (Claude: sessions/worktrees, Goose: recipes/multi-provider)
2. **Parallel Structure**: Same detail level for both plugins at each documentation tier
3. **Depth-Appropriate**: Root/docs have overview, module READMEs have deep details
4. **Minimize Preference Signals**: Equal word counts, objective criteria, no subjective language

**Word Count Targets by Tier**:
- Root README: ~40 words per plugin (±5 words)
- docs/AI_TOOLING.md: ~100 words per plugin (±10 words)
- plugins/ai/README.md: ~60 words per plugin (±5 words)

### Update Locations

**Priority 1: Critical User Entry Points** (12 strategic files):
1. nvim/README.md - Features section
2. docs/AI_TOOLING.md - Complete AI overview
3. plugins/ai/README.md - Module index
4. docs/MAPPINGS.md - Keybinding reference
5. plugins/README.md - Plugin organization
6. lua/neotex/README.md - Namespace overview

**Priority 2: Plugin-Specific READMEs**:
7. plugins/ai/claude/README.md - Add ecosystem context
8. plugins/ai/goose/README.md - Add ecosystem context

**Priority 3: Supporting Documentation**:
9. docs/README.md - Index entry
10. lua/neotex/util/README.md - Notification examples

**Files NOT Updated** (excluded by design):
- Deep implementation READMEs (claude/core/, goose/picker/) - too specific
- Unrelated plugin categories (text/, tools/, editor/) - no functional relationship
- Deprecated directories - avoid new references

## Implementation Phases

### Phase 1: Root Entry Point Updates [COMPLETE]

Update primary user touchpoints to introduce both AI plugins with balanced representation.

**Tasks**:
- [x] Update nvim/README.md features section (line 50)
  - Replace: "AI Assistance: AI integration for code completion and editing suggestions with Avante, MCP-Hub tools, and knowledge assistance with Lectic"
  - With: Bullet list format with Claude, Goose, Avante, Lectic with equal detail
  - Include direct links to each plugin's README
  - Functional differentiation: Claude (sessions/worktrees), Goose (multi-provider/recipes)
  - Target word count: ~40 words per plugin (±5)

- [x] Create comprehensive docs/AI_TOOLING.md update
  - Add "Overview" section explaining multiple AI assistant options
  - Create "AI Assistant Options" section with subsections for Claude Code, Goose, Avante
  - Each subsection: Complete documentation link, key features list, "Best For" guidance, keybindings
  - Add "Feature Comparison Matrix" table (Window Mode, Providers, Sessions, Recipes, Worktrees, Diff Review, MCP Tools, Best Use Case)
  - Preserve existing OpenCode/worktree content in "Advanced Workflows" section
  - Target word count: ~100 words per plugin overview (±10)
  - Ensure parallel structure across all three plugin sections

- [x] Update plugins/README.md AI section (line 76)
  - Expand inline preview with Claude, Goose, Avante entries
  - Parallel structure: claudecode.lua and goose/ with equal detail
  - Maintain existing link to comprehensive ai/README.md
  - One-line summary per plugin focusing on differentiation

**Success Criteria**:
- [x] Root README provides equal visibility to both plugins
- [x] AI_TOOLING.md enables informed tool selection with objective comparison
- [x] Word counts within ±10% variance targets
- [x] All links validated as working relative paths

**Validation**:
```bash
# Verify word counts
wc -w <(sed -n '/Claude Code/,/^###/p' docs/AI_TOOLING.md)
wc -w <(sed -n '/Goose AI Agent/,/^###/p' docs/AI_TOOLING.md)

# Validate links
grep -o '\[.*\](.*\.md)' nvim/README.md | sed 's/.*(\(.*\))/\1/' | while read link; do
  test -f "nvim/$link" && echo "OK: $link" || echo "BROKEN: $link"
done
```

### Phase 2: AI Plugin Organization Updates [COMPLETE]

Update AI plugin directory documentation to include goose with equal prominence to Claude.

**Tasks**:
- [x] Update plugins/ai/README.md subdirectories section
  - Add goose/ subdirectory reference parallel to claude/
  - Format: "- [goose/](goose/README.md) - AI-assisted coding with multi-provider backend and recipe system"
  - Maintain consistent detail level with Claude entry
  - Add goose/init.lua module documentation in Modules section
  - Include key features, configuration overview, keybindings reference

- [x] Update lua/neotex/README.md plugin organization (line 70)
  - Replace: "- **ai/** - AI-powered tooling (Copilot, GPT integration)"
  - With: Nested bullet structure showing claude/, goose/, avante/ subdirectories
  - One-line summaries with functional differentiation
  - Update outdated Copilot reference to current integrations

- [x] Create docs/MAPPINGS.md AI Tools section
  - Add "### AI Tools" heading with Claude Code and Goose subsections
  - Create parallel keybinding tables (Key, Mode, Description columns)
  - Document keybinding overlaps: `<leader>av`, `<leader>ar`, `<leader>at`
  - Add note: "Both plugins can coexist; context determines which bindings are active"
  - Link to full documentation for each plugin

**Success Criteria**:
- [x] plugins/ai/README.md shows goose/ subdirectory with equal prominence to claude/
- [x] Keybinding reference consolidates both plugins with overlap documentation
- [x] Module documentation maintains consistent structure across plugins
- [x] All relative paths validated

**Validation**:
```bash
# Check subdirectory references are balanced
grep -A 1 "claude/" plugins/ai/README.md
grep -A 1 "goose/" plugins/ai/README.md

# Validate MAPPINGS.md table structure
grep "| Key | Mode | Description |" docs/MAPPINGS.md | wc -l  # Should be 2 (one per plugin)
```

### Phase 3: Plugin-Specific README Enhancements [COMPLETE]

Add ecosystem context to both Claude and Goose READMEs without disrupting existing technical documentation.

**Tasks**:
- [x] Update plugins/ai/claude/README.md
  - Add "AI Plugin Ecosystem" section after Purpose (after line 19)
  - Content: Brief overview of Claude, goose, Avante with functional differentiation
  - Add "When to Use Claude vs Goose" subsection with objective criteria
  - Update "External Plugin Configuration" section with goose provider backend note
  - Update Navigation section with "AI Plugin Ecosystem" subsection linking to goose and Avante
  - Add comparison note in "Command System" section referencing goose recipes

- [x] Update plugins/ai/goose/README.md
  - Add "Architectural Overview" section after Purpose (insert at line 17)
  - Content: External plugin vs internal configuration separation
  - Add "Directory Structure" section after Features (insert at line 118)
  - Add "AI Ecosystem Context" note in Multi-Provider Configuration section
  - Content: Distinguish Claude Code backend from claude/ directory integration
  - Add "Navigation" section after References
  - Add keybinding coordination note in Keybindings section

- [x] Update parent plugins/ai/README.md
  - Ensure Subdirectories section lists goose/ (parallel to claude/)
  - Format: "- [goose/](goose/README.md) - Goose AI agent integration with multi-provider support and recipe picker system"

**Success Criteria**:
- [x] Both READMEs have ecosystem context sections with parallel structure
- [x] Cross-references provide navigation without duplication
- [x] Provider clarification prevents Claude Code vs claude/ confusion
- [x] Architectural clarity emphasizes external vs internal separation
- [x] No existing content disrupted (additions only)

**Validation**:
```bash
# Check ecosystem sections exist
grep "AI Plugin Ecosystem" plugins/ai/claude/README.md
grep "Architectural Overview" plugins/ai/goose/README.md

# Verify Navigation sections have parallel structure
grep -A 5 "## Navigation" plugins/ai/claude/README.md
grep -A 5 "## Navigation" plugins/ai/goose/README.md
```

### Phase 4: Supporting Documentation Updates [COMPLETE]

Update supporting documentation for completeness and consistency.

**Tasks**:
- [x] Update docs/README.md index entry (line 47)
  - Current: "| [AI_TOOLING.md](AI_TOOLING.md) | AI integration tools (Avante, Claude Code, MCP Hub) and configuration | 22K |"
  - Add Goose to tool listing
  - Update description to mention comparison/guidance content

- [x] Update lua/neotex/util/README.md notification examples (line 77)
  - Add AI notification examples using both Claude and Goose
  - Demonstrate notify.ai() usage with both plugins
  - Show category usage for AI operations (USER_ACTION vs BACKGROUND)

**Success Criteria**:
- [x] Documentation index reflects complete AI plugin coverage
- [x] Notification examples show both plugins using same system
- [x] Updates maintain existing documentation structure

### Phase 5: Link Integrity and Validation [COMPLETE]

Comprehensive validation of all documentation updates.

**Tasks**:
- [x] Validate all relative path links
  - Run link checker on all updated documentation files
  - Verify bidirectional cross-references work correctly
  - Test navigation paths: Root → docs/AI_TOOLING.md → plugins/ai/README.md → plugin-specific READMEs

- [x] Verify content balance and standards compliance
  - Check word count variance within ±10% targets
  - Verify parallel structure in comparison sections
  - Ensure no subjective preference language
  - Validate functional differentiation clarity

- [x] Test user experience flows
  - New user discovery: Can they find both plugins from root README?
  - Power user navigation: Can they reach detailed docs efficiently?
  - Keybinding reference: Are overlaps clearly documented?
  - Use case guidance: Is it clear when to use which tool?

- [x] Documentation standards validation
  - Present-tense, no historical markers
  - Working code examples with correct paths
  - Purpose statements for all updated sections
  - Navigation links to parent/related docs

**Success Criteria**:
- [x] All relative paths resolve correctly
- [x] Word count variance within acceptable range (±10%)
- [x] No broken links or invalid references
- [x] Documentation follows clean-break philosophy
- [x] User can discover both plugins from any entry point

**Validation Commands**:
```bash
# Link integrity check
find nvim -name "*.md" -exec grep -Ho '\[.*\](.*\.md)' {} \; | \
  sed 's/.*(\(.*\))/\1/' | sort -u | while read link; do
    test -f "$link" && echo "OK: $link" || echo "BROKEN: $link"
  done

# Word count variance check
CLAUDE_WORDS=$(sed -n '/### Claude Code/,/^###/p' docs/AI_TOOLING.md | wc -w)
GOOSE_WORDS=$(sed -n '/### Goose AI Agent/,/^###/p' docs/AI_TOOLING.md | wc -w)
VARIANCE=$((200 * ($CLAUDE_WORDS - $GOOSE_WORDS) / ($CLAUDE_WORDS + $GOOSE_WORDS)))
echo "Word count variance: ${VARIANCE}% (target: ±10%)"

# Subjective language check
grep -iE "(better|worse|superior|inferior|simpler|harder|easier|difficult)" \
  nvim/README.md docs/AI_TOOLING.md plugins/ai/README.md
```

## Technical Details

### File Paths

**Updated Files**:
- `/home/benjamin/.config/nvim/README.md`
- `/home/benjamin/.config/nvim/docs/README.md`
- `/home/benjamin/.config/nvim/docs/AI_TOOLING.md`
- `/home/benjamin/.config/nvim/docs/MAPPINGS.md`
- `/home/benjamin/.config/nvim/lua/neotex/README.md`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/README.md`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/README.md`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/README.md`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md`
- `/home/benjamin/.config/nvim/lua/neotex/util/README.md`

### Documentation Standards

**Clean-Break Philosophy**:
- Document current design as if it always existed
- No historical markers ("now supports", "recently added")
- Present-tense language throughout

**Balanced Representation**:
- Word count variance within ±10% at each documentation tier
- Parallel structure for comparable elements
- Objective criteria for differentiation (window mode, providers, features)
- No subjective language (avoid "better", "more powerful", "simpler")

**Link Conventions**:
- Relative paths for all internal documentation links
- Anchor links for section references (#heading-name)
- Bidirectional cross-references where appropriate
- Navigation links follow parent → child → sibling pattern

### Keybinding Overlaps

Both plugins use `<leader>a` namespace with these overlaps:

| Keybinding | Claude | Goose | Resolution |
|------------|--------|-------|------------|
| `<leader>av` | View worktrees | Select session | Context-dependent (both can coexist) |
| `<leader>ar` | Restore worktree | Run session | Context-dependent (both can coexist) |
| `<leader>at` | Toggle TTS | Stop execution | Context-dependent (both can coexist) |

Documentation must explicitly note these overlaps and explain coexistence behavior.

## Dependencies

### Prerequisites
- Existing documentation files accessible at specified paths
- Write access to nvim configuration directory
- Research reports available for reference

### External Dependencies
- None (documentation-only changes)

### Related Components
- All Neovim AI plugin documentation
- Project documentation standards (CLAUDE.md, DOCUMENTATION_STANDARDS.md)

## Testing Strategy

### Link Integrity Testing
```bash
# Test all markdown links in updated files
for file in nvim/README.md docs/AI_TOOLING.md plugins/ai/README.md; do
  echo "Checking $file..."
  grep -o '\[.*\](.*\.md[#\w-]*)' "$file" | \
    sed 's/.*(\([^#]*\).*/\1/' | \
    while read link; do
      test -f "$link" && echo "  ✓ $link" || echo "  ✗ BROKEN: $link"
    done
done
```

### Content Balance Testing
```bash
# Verify word count balance in docs/AI_TOOLING.md
echo "Claude section:"
sed -n '/### Claude Code/,/^###/p' docs/AI_TOOLING.md | wc -w
echo "Goose section:"
sed -n '/### Goose AI Agent/,/^###/p' docs/AI_TOOLING.md | wc -w
echo "Target variance: ±10%"
```

### Standards Compliance Testing
```bash
# Check for historical markers (anti-pattern)
grep -iE "(now|recently|updated|changed|added|previous)" \
  docs/AI_TOOLING.md plugins/ai/README.md

# Check for subjective language (anti-pattern)
grep -iE "(better|worse|superior|inferior|recommend|prefer)" \
  docs/AI_TOOLING.md plugins/ai/README.md
```

### User Experience Testing
- [ ] New user can discover both AI plugins from root README within 30 seconds
- [ ] Power user can navigate to plugin-specific docs in ≤3 clicks
- [ ] Keybinding reference clearly shows both plugins and overlaps
- [ ] Use case guidance enables informed tool selection

## Rollback Plan

### Backup Strategy
Before making changes:
```bash
# Create timestamped backup of all files to be modified
BACKUP_DIR="$HOME/.config/nvim/.backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

FILES=(
  "README.md"
  "docs/README.md"
  "docs/AI_TOOLING.md"
  "docs/MAPPINGS.md"
  "lua/neotex/README.md"
  "lua/neotex/plugins/README.md"
  "lua/neotex/plugins/ai/README.md"
  "lua/neotex/plugins/ai/claude/README.md"
  "lua/neotex/plugins/ai/goose/README.md"
  "lua/neotex/util/README.md"
)

for file in "${FILES[@]}"; do
  cp "nvim/$file" "$BACKUP_DIR/"
done

echo "Backup created at $BACKUP_DIR"
```

### Rollback Procedure
If issues are discovered:
```bash
# Restore from most recent backup
BACKUP_DIR=$(ls -td $HOME/.config/nvim/.backup-* | head -1)
for file in "${FILES[@]}"; do
  cp "$BACKUP_DIR/$(basename $file)" "nvim/$file"
done
echo "Rolled back from $BACKUP_DIR"
```

## Risk Assessment

### Risk 1: Documentation Drift
**Probability**: Medium
**Impact**: Medium
**Mitigation**:
- Use relative links (robust to directory moves)
- Add quarterly documentation review to maintenance schedule
- Consider pre-commit hook for markdown link validation

### Risk 2: Over-Linking Creating Cognitive Overload
**Probability**: Low
**Impact**: Low
**Mitigation**:
- Limit cross-references to high-value scenarios (use cases, configuration, troubleshooting)
- Follow research recommendations for appropriate linking depth
- Prefer parent ai/README.md for ecosystem overview

### Risk 3: Inconsistent Voice Between Plugin READMEs
**Probability**: Low
**Impact**: Low
**Mitigation**:
- Use consistent section naming across plugins
- Align terminology in cross-references
- Follow parallel structure guidelines in this plan

### Risk 4: User Confusion About Tool Selection
**Probability**: Medium (if not addressed properly)
**Impact**: High
**Mitigation**:
- Include "When to Use" sections with objective criteria
- Provide feature comparison matrix in docs/AI_TOOLING.md
- Use functional differentiation throughout documentation

## Open Questions

- [ ] Should docs/MAPPINGS.md be created if it doesn't exist, or should keybinding documentation live elsewhere?
- [ ] Is the ±10% word count variance target acceptable, or should it be stricter?
- [ ] Should we add a decision tree diagram in docs/AI_TOOLING.md for visual tool selection guidance?
- [ ] Are there additional cross-references beyond the 12 strategic files that would add value?

## References

### Research Reports
- [Goose Plugin Documentation Research](../reports/001-goose-plugin-documentation.md) - Analysis of goose/README.md structure, gaps, and opportunities
- [Claude Plugin Documentation Research](../reports/002-claude-plugin-documentation.md) - Analysis of claude/README.md and comparison with goose
- [Neovim Documentation Cross-Linking Strategy](../reports/003-neovim-documentation-linking.md) - Documentation architecture analysis and balanced linking strategy

### Documentation Standards
- `/home/benjamin/.config/CLAUDE.md` - Project configuration and standards
- `/home/benjamin/.config/nvim/CLAUDE.md` - Neovim-specific guidelines
- `/home/benjamin/.config/nvim/docs/DOCUMENTATION_STANDARDS.md` - README structure and style guide

### Related Files
- `/home/benjamin/.config/nvim/README.md` - Root configuration overview
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/README.md` - AI plugins overview
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/README.md` - Claude documentation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md` - Goose documentation
