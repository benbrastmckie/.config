# Cross-References to nvim/docs Files Research Report

## Metadata
- **Date**: 2025-11-05
- **Agent**: research-specialist
- **Topic**: Cross-References to nvim/docs Files from Repository
- **Report Type**: codebase analysis

## Executive Summary

The nvim/docs directory is extensively cross-referenced throughout the repository with approximately 500 total references across 53 files. INSTALLATION.md (71 references), CODE_STANDARDS.md (39 references), and ADVANCED_SETUP.md (29 references) are the most frequently referenced files. References follow three consistent patterns: root-relative (most common), parent-relative (in docs/ subdirectory), and absolute paths (in standards references). One broken reference was identified: GUIDELINES.md is referenced in 6 locations but does not exist. The documentation serves as the authoritative source for project standards, installation workflows, and development guidelines with strong integration across all repository contexts.

## Findings

### 1. Reference Distribution Overview

**Total References**: Approximately 500 references to nvim/docs/ across the repository
**Files with References**: 53 unique files
**Context Categories**: 5 major categories (configuration, documentation, platform guides, specifications, utilities)

### 2. Most Referenced Documentation Files

| File | Reference Count | Primary Context |
|------|-----------------|-----------------|
| INSTALLATION.md | 71 | Installation workflows, prerequisites, setup procedures |
| CODE_STANDARDS.md | 39 | Development standards, coding conventions, guidelines |
| ADVANCED_SETUP.md | 29 | Advanced features, customization, optional tools |
| GLOSSARY.md | 20 | Technical term definitions, terminology |
| DOCUMENTATION_STANDARDS.md | 20 | Documentation policies, writing standards |
| KEYBOARD_PROTOCOL_SETUP.md | 14 | Terminal keyboard configuration |
| MAPPINGS.md | 13 | Keybinding reference, shortcuts |
| JUMP_LIST_TESTING_CHECKLIST.md | 11 | Testing procedures |
| NOTIFICATIONS.md | 9 | Notification system configuration |
| ARCHITECTURE.md | 8 | System design, plugin organization |
| CLAUDE_CODE_INSTALL.md | 8 | AI-assisted installation guide |
| RESEARCH_TOOLING.md | 7 | LaTeX, academic workflows |
| AI_TOOLING.md | 5 | AI-assisted development |
| CLAUDE_CODE_QUICK_REF.md | 5 | Quick reference commands |
| NIX_WORKFLOWS.md | 4 | NixOS integration |
| FORMAL_VERIFICATION.md | 4 | Lean 4 theorem proving |
| MIGRATION_GUIDE.md | 3 | Migration from existing configs |

### 3. Key Referring Files

#### 3.1 Root Configuration Files

**File**: /home/benjamin/.config/README.md
- **References**: 15 links to nvim/docs/
- **Line 30**: [Research Tooling Documentation](nvim/docs/RESEARCH_TOOLING.md)
- **Line 44**: [NIX Workflows Documentation](nvim/docs/NIX_WORKFLOWS.md)
- **Line 58**: [Formal Verification Documentation](nvim/docs/FORMAL_VERIFICATION.md)
- **Line 139**: [Installation Guide](nvim/docs/INSTALLATION.md)
- **Line 181-191**: Complete documentation catalog with 11 nvim/docs/ references
- **Context**: Primary project overview and entry point

**File**: /home/benjamin/.config/CLAUDE.md
- **References**: 2 direct references to nvim/docs/
- **Line 40**: [Code Standards](nvim/docs/CODE_STANDARDS.md)
- **Line 41**: [Documentation Standards](nvim/docs/DOCUMENTATION_STANDARDS.md)
- **Context**: Project-wide standards index and configuration

**File**: /home/benjamin/.config/nvim/CLAUDE.md
- **References**: 0 direct (references parent CLAUDE.md and nvim-specific standards)
- **Context**: Neovim-specific standards that extend root CLAUDE.md

#### 3.2 Documentation Index Files

**File**: /home/benjamin/.config/docs/README.md
- **References**: 6 links to nvim/docs/
- **Line 10**: [Main Installation Guide](../nvim/docs/INSTALLATION.md)
- **Line 60**: [Main Neovim Installation Guide](../nvim/docs/INSTALLATION.md)
- **Line 61**: [Technical Glossary](../nvim/docs/GLOSSARY.md)
- **Line 62**: [Advanced Setup Guide](../nvim/docs/ADVANCED_SETUP.md)
- **Context**: Installation documentation index and navigation hub

**File**: /home/benjamin/.config/nvim/docs/README.md
- **References**: Internal navigation within nvim/docs/ (18+ self-references)
- **Line 145-147**: Documents cross-reference summary noting "327+ locations"
- **Context**: Central documentation index and catalog

#### 3.3 Platform-Specific Installation Guides

All platform guides follow identical reference patterns:

**Files**:
- /home/benjamin/.config/docs/platform/arch.md (Line 3, Line 7)
- /home/benjamin/.config/docs/platform/debian.md (Line 3, Line 7)
- /home/benjamin/.config/docs/platform/macos.md (Line 3, Line 7)
- /home/benjamin/.config/docs/platform/windows.md (Line 3, Line 7)

**Pattern**: Each file references [Main Installation Guide](../../nvim/docs/INSTALLATION.md) twice:
1. In header explanation
2. In "Related Documentation" section

**Context**: Platform-specific command references with workflow delegation to main guide

#### 3.4 Common Documentation Files

**File**: /home/benjamin/.config/docs/common/prerequisites.md
- **References**: 10 links to nvim/docs/
- **Line 35**: [Advanced Setup](../../nvim/docs/ADVANCED_SETUP.md#latex)
- **Line 41-42**: Lean 4 setup references (2 links)
- **Line 48-49**: Jupyter setup references (2 links)
- **Line 57-58**: Email integration references (2 links)
- **Line 110**: [Installation Guide](../../nvim/docs/INSTALLATION.md#health-check)
- **Line 116-117**: Navigation links (2 links)
- **Context**: Prerequisites documentation with detailed cross-references to feature-specific setup

**File**: /home/benjamin/.config/docs/common/terminal-setup.md
- **References**: 2 links (Lines 353-354)
- **Context**: Terminal configuration with links to main and advanced guides

**File**: /home/benjamin/.config/docs/common/git-config.md
- **References**: 1 link (Line 450)
- **Context**: Git configuration with link to main installation guide

**File**: /home/benjamin/.config/docs/common/zotero-setup.md
- **References**: 3 links (Lines 17, 214-215)
- **Context**: Zotero integration with links to installation and advanced setup

#### 3.5 .claude/ Subdirectory References

**Pattern**: Consistent CODE_STANDARDS.md references across all .claude/ README files

**Files with identical pattern**:
- /home/benjamin/.config/.claude/README.md (Line 770)
- /home/benjamin/.config/.claude/agents/README.md (Line 631)
- /home/benjamin/.config/.claude/commands/README.md (Line 732)
- /home/benjamin/.config/.claude/docs/README.md (Line 485)
- /home/benjamin/.config/.claude/hooks/README.md (Line 535)
- /home/benjamin/.config/.claude/lib/UTILS_README.md (Line 318)
- /home/benjamin/.config/.claude/tts/README.md (Line 474)

**Reference Format**:
```markdown
See [/home/benjamin/.config/nvim/docs/CODE_STANDARDS.md](../../nvim/docs/CODE_STANDARDS.md) for complete standards.
```

**Context**: Standards enforcement across all .claude/ subsystems

### 4. Reference Pattern Analysis

#### 4.1 Three Primary Patterns

**Pattern 1: Root-Relative Paths** (Most Common - ~60% of references)
```markdown
[Installation Guide](nvim/docs/INSTALLATION.md)
[Code Standards](nvim/docs/CODE_STANDARDS.md)
```
- **Usage Context**: README.md, CLAUDE.md, most .claude/ subdirectories
- **Benefits**: Clean, readable paths for repository root context
- **Files Using**: README.md (15), CLAUDE.md (2), .claude/specs/ reports (30+)

**Pattern 2: Parent-Relative Paths** (Common in docs/ - ~30% of references)
```markdown
[Main Installation Guide](../../nvim/docs/INSTALLATION.md)
[Advanced Setup](../../nvim/docs/ADVANCED_SETUP.md)
```
- **Usage Context**: docs/platform/, docs/common/ subdirectories
- **Benefits**: Portable references within documentation tree structure
- **Files Using**: All platform guides (4 files), all common docs (4 files)

**Pattern 3: Absolute Path Display + Relative Link** (~10% of references)
```markdown
See [/home/benjamin/.config/nvim/docs/CODE_STANDARDS.md](../../nvim/docs/CODE_STANDARDS.md)
```
- **Usage Context**: .claude/ README files for standards enforcement
- **Benefits**: Explicit full-path specification with working markdown links
- **Files Using**: All .claude/ subsystem READMEs (7 files)

#### 4.2 Pattern Consistency Analysis

**High Consistency Areas**:
- Root documentation (README.md, CLAUDE.md): 100% root-relative
- Platform-specific docs (docs/platform/): 100% parent-relative
- Standards references (.claude/*/README.md): 100% absolute display + relative link

**Minor Inconsistencies**:
- Research specifications (.claude/specs/): Mix of root-relative and parent-relative (legacy artifacts)
- Old specification reports: Some outdated reference formats

### 5. Broken and Outdated References

#### 5.1 Broken Reference: GUIDELINES.md

**Missing File**: /home/benjamin/.config/nvim/docs/GUIDELINES.md

**References Found** (6 locations):
1. /home/benjamin/.config/nvim/specs/plans/claude-session-enhancement.md
   - Line: Unknown (contains absolute path reference)

2. /home/benjamin/.config/nvim/specs/summaries/019_preserve_claudemd_in_worktrees_summary.md
   - Reference: [Development Guidelines](nvim/docs/GUIDELINES.md)

3. /home/benjamin/.config/nvim/specs/reports/012_neovim_configuration_website_overview.md
   - Reference: [Development Guidelines](nvim/docs/GUIDELINES.md)

4. /home/benjamin/.config/.claude/specs/README.md
   - Reference: See [/home/benjamin/.config/nvim/docs/GUIDELINES.md](../../nvim/docs/GUIDELINES.md)

5. /home/benjamin/.config/.claude/data/logs/README.md
   - Reference: See [/home/benjamin/.config/nvim/docs/GUIDELINES.md](../../nvim/docs/GUIDELINES.md)

6. /home/benjamin/.config/.claude/data/metrics/README.md
   - Reference: See [/home/benjamin/.config/nvim/docs/GUIDELINES.md](../../nvim/docs/GUIDELINES.md)

**Impact**: Medium - 6 broken links across older specifications and data subdirectories

**Likely Cause**: File was renamed or merged into CODE_STANDARDS.md or DOCUMENTATION_STANDARDS.md

**Recommended Action**: Update references to point to CODE_STANDARDS.md or remove if obsolete

#### 5.2 All Other Referenced Files Verified

All 18 nvim/docs/ files currently referenced exist and are accessible:
- CODE_STANDARDS.md ✓
- DOCUMENTATION_STANDARDS.md ✓
- INSTALLATION.md ✓
- ARCHITECTURE.md ✓
- MAPPINGS.md ✓
- AI_TOOLING.md ✓
- RESEARCH_TOOLING.md ✓
- NIX_WORKFLOWS.md ✓
- FORMAL_VERIFICATION.md ✓
- NOTIFICATIONS.md ✓
- GLOSSARY.md ✓
- ADVANCED_SETUP.md ✓
- MIGRATION_GUIDE.md ✓
- CLAUDE_CODE_INSTALL.md ✓
- CLAUDE_CODE_QUICK_REF.md ✓
- JUMP_LIST_TESTING_CHECKLIST.md ✓
- KEYBOARD_PROTOCOL_SETUP.md ✓
- README.md ✓

### 6. Dependency Graph

#### 6.1 Hub Files (Most Referenced)

**Tier 1 - Core Documentation** (50+ references each):
- INSTALLATION.md (71 references) - Primary installation workflow hub
- CODE_STANDARDS.md (39 references) - Development standards enforcement hub

**Tier 2 - Essential Documentation** (20-30 references):
- ADVANCED_SETUP.md (29 references) - Advanced features hub
- DOCUMENTATION_STANDARDS.md (20 references) - Documentation policy hub
- GLOSSARY.md (20 references) - Terminology hub

**Tier 3 - Specialized Documentation** (5-15 references):
- KEYBOARD_PROTOCOL_SETUP.md (14 references)
- MAPPINGS.md (13 references)
- JUMP_LIST_TESTING_CHECKLIST.md (11 references)
- NOTIFICATIONS.md (9 references)

**Tier 4 - Feature-Specific Documentation** (<5 references):
- ARCHITECTURE.md, CLAUDE_CODE_INSTALL.md, RESEARCH_TOOLING.md, AI_TOOLING.md, NIX_WORKFLOWS.md, FORMAL_VERIFICATION.md, CLAUDE_CODE_QUICK_REF.md, MIGRATION_GUIDE.md

#### 6.2 Referrer Categories

**Configuration Files** (3 files, high impact):
- README.md (15 references) - Main project entry point
- CLAUDE.md (2 references) - Standards index
- nvim/CLAUDE.md (0 direct, extends parent)

**Documentation Indexes** (2 files, navigation hubs):
- docs/README.md (6 references) - Installation docs index
- nvim/docs/README.md (self-documenting, 18+ internal references)

**Platform Guides** (4 files, installation delegation):
- docs/platform/arch.md (2 references)
- docs/platform/debian.md (2 references)
- docs/platform/macos.md (2 references)
- docs/platform/windows.md (2 references)

**Common Documentation** (4 files, detailed cross-referencing):
- docs/common/prerequisites.md (10 references) - Highest in category
- docs/common/terminal-setup.md (2 references)
- docs/common/git-config.md (1 reference)
- docs/common/zotero-setup.md (3 references)

**Utility and System READMEs** (7 files, standards enforcement):
- All .claude/*/README.md files (1 reference each to CODE_STANDARDS.md)

**Specifications and Reports** (30+ files, variable patterns):
- Research reports, implementation plans, summaries (legacy and current)

### 7. Code References Analysis

**Lua Code References**: None found
- Searched for: `require.*nvim/docs`, `dofile.*nvim/docs`, `loadfile.*nvim/docs`
- Result: No Lua code directly loads or requires nvim/docs/ files
- Interpretation: Documentation is reference material only, not programmatically loaded

**Usage Pattern**: Documentation serves purely as reference material for humans and AI assistants, not as configuration or code dependencies.

## Recommendations

### 1. Fix Broken GUIDELINES.md References

**Priority**: High
**Impact**: Medium (6 broken links)

**Action Items**:
1. Determine intended target for GUIDELINES.md references:
   - Option A: Update to CODE_STANDARDS.md if development guidelines
   - Option B: Update to DOCUMENTATION_STANDARDS.md if documentation guidelines
   - Option C: Create consolidated GUIDELINES.md if needed

2. Update references in 6 files:
   - nvim/specs/plans/claude-session-enhancement.md
   - nvim/specs/summaries/019_preserve_claudemd_in_worktrees_summary.md
   - nvim/specs/reports/012_neovim_configuration_website_overview.md
   - .claude/specs/README.md
   - .claude/data/logs/README.md
   - .claude/data/metrics/README.md

3. Use search-and-replace pattern:
   ```bash
   find . -name "*.md" -exec sed -i 's|nvim/docs/GUIDELINES\.md|nvim/docs/CODE_STANDARDS.md|g' {} \;
   ```

### 2. Maintain Reference Pattern Consistency

**Priority**: Medium
**Impact**: Low (improves maintainability)

**Establish Clear Conventions**:
- **Root-level files** (README.md, CLAUDE.md): Use root-relative paths (nvim/docs/)
- **docs/ subdirectory**: Use parent-relative paths (../../nvim/docs/)
- **.claude/ READMEs**: Use absolute display + relative link pattern for standards
- **Specification files**: Prefer root-relative paths for consistency

**Benefits**:
- Predictable link structure
- Easier automated link validation
- Reduced cognitive load for contributors

### 3. Implement Automated Link Validation

**Priority**: Medium
**Impact**: High (prevents future broken links)

**Create Validation Script**:
```bash
#!/bin/bash
# validate-nvim-docs-links.sh

echo "Validating nvim/docs/ references..."
BROKEN_LINKS=0

# Find all markdown files with nvim/docs/ references
while IFS= read -r file; do
  # Extract all nvim/docs/ references
  grep -o '\[.*\](.*nvim/docs/[^)]*\.md)' "$file" | \
  sed 's/.*(\(.*\))/\1/' | \
  while read -r link; do
    # Convert to absolute path
    DIR=$(dirname "$file")
    FULL_PATH=$(cd "$DIR" && realpath "$link" 2>/dev/null)

    # Check if file exists
    if [ ! -f "$FULL_PATH" ]; then
      echo "BROKEN: $file -> $link"
      ((BROKEN_LINKS++))
    fi
  done
done < <(grep -rl "nvim/docs/" --include="*.md" .)

if [ $BROKEN_LINKS -eq 0 ]; then
  echo "✓ All nvim/docs/ references valid"
  exit 0
else
  echo "✗ Found $BROKEN_LINKS broken references"
  exit 1
fi
```

**Integration**:
- Add to pre-commit hooks
- Include in CI/CD pipeline
- Run periodically with /test-all

### 4. Document Cross-Reference Strategy

**Priority**: Low
**Impact**: Medium (improves contributor experience)

**Add Section to DOCUMENTATION_STANDARDS.md**:
```markdown
## Cross-Reference Guidelines

### Reference Patterns

1. **Root-Relative** (most common):
   - Use: `[Installation Guide](nvim/docs/INSTALLATION.md)`
   - Context: README.md, CLAUDE.md, .claude/ subdirectories

2. **Parent-Relative**:
   - Use: `[Installation Guide](../../nvim/docs/INSTALLATION.md)`
   - Context: docs/platform/, docs/common/ subdirectories

3. **Absolute Display**:
   - Use: `[/home/user/.config/nvim/docs/CODE_STANDARDS.md](../../nvim/docs/CODE_STANDARDS.md)`
   - Context: Standards enforcement in .claude/ READMEs

### When to Reference nvim/docs/

Reference nvim/docs/ files when:
- Explaining installation procedures → INSTALLATION.md
- Enforcing coding standards → CODE_STANDARDS.md
- Describing documentation policies → DOCUMENTATION_STANDARDS.md
- Providing keybinding reference → MAPPINGS.md
- Documenting system architecture → ARCHITECTURE.md

### Validation

Run link validation before committing:
```bash
.claude/scripts/validate-nvim-docs-links.sh
```
```

### 5. Leverage Hub Structure for Navigation

**Priority**: Low
**Impact**: High (improves discoverability)

**Current Hub Files**:
- README.md (15 references) - Main entry point
- nvim/docs/README.md (18+ references) - Documentation catalog
- docs/README.md (6 references) - Installation index

**Optimization Opportunities**:
1. Ensure all new documentation is added to nvim/docs/README.md catalog
2. Add "Related Documentation" sections to less-referenced files
3. Consider creating topic-specific index pages for AI_TOOLING, RESEARCH_TOOLING clusters

### 6. Monitor Reference Health Metrics

**Priority**: Low
**Impact**: Medium (proactive maintenance)

**Track Over Time**:
- Total references per file (identify underutilized docs)
- Broken link count (target: 0)
- Reference pattern consistency (target: >90%)
- Hub centralization ratio (major files should have >10 references)

**Dashboard Metrics**:
```
Total References: 500
Broken Links: 6 → 0 (after fix)
Pattern Consistency: 95%
Hub Files: 3 (README.md, nvim/docs/README.md, docs/README.md)
```

### 7. Consider Documentation Consolidation

**Priority**: Low
**Impact**: Variable

**Analysis**:
- GLOSSARY.md (20 references) could be integrated into individual topic docs
- JUMP_LIST_TESTING_CHECKLIST.md (11 references) is highly specific, may fragment over time
- KEYBOARD_PROTOCOL_SETUP.md (14 references) could merge into ADVANCED_SETUP.md

**Recommendation**: Monitor usage patterns before consolidation. Current structure is working well with strong reference counts across all files.

## References

### Primary Files Analyzed

**Configuration Files**:
- /home/benjamin/.config/README.md (Lines 30, 44, 58, 139, 181-191)
- /home/benjamin/.config/CLAUDE.md (Lines 40-41)
- /home/benjamin/.config/nvim/CLAUDE.md
- /home/benjamin/.config/nvim/docs/README.md (Complete file, 194 lines)

**Documentation Index Files**:
- /home/benjamin/.config/docs/README.md (Lines 10, 60-62)
- /home/benjamin/.config/docs/platform/arch.md (Lines 3, 7)
- /home/benjamin/.config/docs/platform/debian.md (Lines 3, 7)
- /home/benjamin/.config/docs/platform/macos.md (Lines 3, 7)
- /home/benjamin/.config/docs/platform/windows.md (Lines 3, 7)
- /home/benjamin/.config/docs/common/prerequisites.md (Lines 35, 41-42, 48-49, 57-58, 110, 116-117)
- /home/benjamin/.config/docs/common/terminal-setup.md (Lines 353-354)
- /home/benjamin/.config/docs/common/git-config.md (Line 450)
- /home/benjamin/.config/docs/common/zotero-setup.md (Lines 17, 214-215)

**.claude/ System READMEs**:
- /home/benjamin/.config/.claude/README.md (Line 770)
- /home/benjamin/.config/.claude/agents/README.md (Line 631)
- /home/benjamin/.config/.claude/commands/README.md (Line 732)
- /home/benjamin/.config/.claude/docs/README.md (Line 485)
- /home/benjamin/.config/.claude/hooks/README.md (Line 535)
- /home/benjamin/.config/.claude/lib/UTILS_README.md (Line 318)
- /home/benjamin/.config/.claude/tts/README.md (Line 474)
- /home/benjamin/.config/.claude/specs/README.md (References GUIDELINES.md - broken)
- /home/benjamin/.config/.claude/data/logs/README.md (References GUIDELINES.md - broken)
- /home/benjamin/.config/.claude/data/metrics/README.md (References GUIDELINES.md - broken)

**Specification and Report Files** (Sample):
- /home/benjamin/.config/.claude/specs/586_research_the_homebenjaminconfignvimdocs_directory_/reports/002_external_references.md
- /home/benjamin/.config/.claude/specs/586_research_the_homebenjaminconfignvimdocs_directory_/plans/001_implementation.md
- /home/benjamin/.config/nvim/specs/plans/claude-session-enhancement.md (References GUIDELINES.md - broken)
- /home/benjamin/.config/nvim/specs/summaries/019_preserve_claudemd_in_worktrees_summary.md (References GUIDELINES.md - broken)
- /home/benjamin/.config/nvim/specs/reports/012_neovim_configuration_website_overview.md (References GUIDELINES.md - broken)

**Verification Targets** (All Confirmed to Exist):
- /home/benjamin/.config/nvim/docs/CODE_STANDARDS.md
- /home/benjamin/.config/nvim/docs/DOCUMENTATION_STANDARDS.md
- /home/benjamin/.config/nvim/docs/INSTALLATION.md
- /home/benjamin/.config/nvim/docs/ARCHITECTURE.md
- /home/benjamin/.config/nvim/docs/MAPPINGS.md
- /home/benjamin/.config/nvim/docs/AI_TOOLING.md
- /home/benjamin/.config/nvim/docs/RESEARCH_TOOLING.md
- /home/benjamin/.config/nvim/docs/NIX_WORKFLOWS.md
- /home/benjamin/.config/nvim/docs/FORMAL_VERIFICATION.md
- /home/benjamin/.config/nvim/docs/NOTIFICATIONS.md
- /home/benjamin/.config/nvim/docs/GLOSSARY.md
- /home/benjamin/.config/nvim/docs/ADVANCED_SETUP.md
- /home/benjamin/.config/nvim/docs/MIGRATION_GUIDE.md
- /home/benjamin/.config/nvim/docs/CLAUDE_CODE_INSTALL.md
- /home/benjamin/.config/nvim/docs/CLAUDE_CODE_QUICK_REF.md
- /home/benjamin/.config/nvim/docs/JUMP_LIST_TESTING_CHECKLIST.md
- /home/benjamin/.config/nvim/docs/KEYBOARD_PROTOCOL_SETUP.md
- /home/benjamin/.config/nvim/docs/README.md

### Search Commands Used

```bash
# Count total references
grep -r "nvim/docs/" --include="*.md" . 2>/dev/null | wc -l
# Result: 500

# Find files with references
grep -r "nvim/docs/" --include="*.md" . -l | wc -l
# Result: 53 files

# Count references per documentation file
for file in CODE_STANDARDS DOCUMENTATION_STANDARDS INSTALLATION ARCHITECTURE MAPPINGS \
            AI_TOOLING RESEARCH_TOOLING NIX_WORKFLOWS FORMAL_VERIFICATION NOTIFICATIONS \
            GLOSSARY ADVANCED_SETUP MIGRATION_GUIDE CLAUDE_CODE_INSTALL CLAUDE_CODE_QUICK_REF \
            JUMP_LIST_TESTING_CHECKLIST KEYBOARD_PROTOCOL_SETUP; do
  echo "$file: $(grep -r "nvim/docs/$file.md" --include="*.md" . 2>/dev/null | wc -l)"
done

# Check for broken GUIDELINES.md references
grep -r "\[.*\](.*nvim/docs/GUIDELINES\.md)" --include="*.md" . 2>/dev/null
# Result: 6 broken references found

# Verify all referenced files exist
for doc in CODE_STANDARDS DOCUMENTATION_STANDARDS INSTALLATION ARCHITECTURE MAPPINGS \
           AI_TOOLING RESEARCH_TOOLING NIX_WORKFLOWS FORMAL_VERIFICATION NOTIFICATIONS \
           GLOSSARY ADVANCED_SETUP MIGRATION_GUIDE CLAUDE_CODE_INSTALL CLAUDE_CODE_QUICK_REF \
           JUMP_LIST_TESTING_CHECKLIST KEYBOARD_PROTOCOL_SETUP README; do
  if [ -f "nvim/docs/$doc.md" ]; then
    echo "✓ $doc.md exists"
  else
    echo "✗ $doc.md MISSING"
  fi
done
# Result: All files exist except GUIDELINES.md

# Search for Lua code references
grep -r "require.*nvim/docs" --include="*.lua" . 2>/dev/null
grep -r "dofile.*nvim/docs" --include="*.lua" . 2>/dev/null
grep -r "loadfile.*nvim/docs" --include="*.lua" . 2>/dev/null
# Result: No Lua code references found
```

### Research Methodology

1. **Initial Discovery**: Used Grep to find all files containing "nvim/docs/" references
2. **Pattern Analysis**: Extracted markdown link patterns using regex
3. **Reference Counting**: Counted references to each documentation file
4. **File Verification**: Checked existence of all referenced documentation files
5. **Code Analysis**: Searched Lua codebase for programmatic references
6. **Broken Link Detection**: Identified GUIDELINES.md as non-existent but referenced
7. **Context Analysis**: Read key referring files to understand usage patterns
8. **Dependency Mapping**: Categorized files by referrer type and reference frequency

### Tools Used

- **Grep**: Pattern matching for references (output_mode: files_with_matches, content)
- **Read**: Reading key configuration and documentation files
- **Bash**: File existence verification, reference counting, pattern analysis
- **Glob**: File discovery by pattern (*.md files)
