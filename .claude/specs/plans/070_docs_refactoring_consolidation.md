# Documentation Refactoring and Consolidation Implementation Plan

## Metadata
- **Date**: 2025-10-17
- **Feature**: Refactor .claude/docs/ for better organization and consolidation
- **Scope**: Eliminate content duplication (70% in artifact org files, 40% in agent files), reorganize using Diátaxis framework principles, preserve all content, update cross-references
- **Estimated Phases**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: Research findings from orchestration workflow (current conversation)

## Overview

The .claude/docs/ directory currently contains 34 markdown files with significant content duplication and organizational issues:
- **70% content overlap** in artifact organization files (directory-protocols.md, topic_based_organization.md, artifact_organization.md)
- **40% content overlap** in agent coordination files (hierarchical_agents.md, using-agents.md, spec_updater_guide.md)
- **Scattered concepts**: "metadata extraction" in 13 files, "topic-based organization" in 10 files, "agent invocation patterns" in 8 files
- **Size issues**: Files range from 2.2KB to 54KB with creating-commands.md at 54KB

This refactoring will:
1. Consolidate duplicate content into canonical locations
2. Organize documentation by content type (following Diátaxis framework principles)
3. Maintain all content without loss
4. Update all cross-references and maintain backward compatibility
5. Improve discoverability and reduce maintenance burden
6. Reduce total file count from 34 to ~30 files
7. Eliminate ~20KB of redundant content

## Success Criteria
- [ ] All duplicate content consolidated without information loss
- [ ] All files under 50KB target size
- [ ] README.md updated with new structure
- [ ] All cross-references updated (CLAUDE.md, command files, other docs)
- [ ] Backward compatibility maintained via README redirects
- [ ] All links verified working
- [ ] Documentation standards followed (no emojis, Unicode box-drawing, CommonMark)
- [ ] Git commit for each major consolidation phase

## Technical Design

### Diátaxis Framework Application
While a full Diátaxis reorganization (tutorials/how-to/reference/explanation) is out of scope, we'll apply key principles:
- **Consolidate by topic** rather than scattering across multiple files
- **Separate reference material** (command-reference.md, agent-reference.md) from guides
- **Keep files focused** on single topics (avoid mixing unrelated content)
- **Maintain 2-3 hierarchy levels** (docs/ with possible /archive/ and /guides/ subdirectories)

### Consolidation Strategy

#### 1. Artifact Organization Consolidation (Priority 1)
**Target**: Merge 3 files with 70% overlap into 1 canonical file

**Files to consolidate**:
- `directory-protocols.md` (7.2KB) - Keep as canonical location
- `topic_based_organization.md` (13KB) - Merge unique content into directory-protocols.md
- `artifact_organization.md` (30KB) - Merge unique content into directory-protocols.md

**Unique content preservation**:
- topic_based_organization.md: Gitignore compliance protocol section
- artifact_organization.md: Detailed lifecycle management utilities, 30-day retention policies

**Result**: Single `directory-protocols.md` (~35-40KB) covering all artifact organization topics

#### 2. Agent Coordination Consolidation (Priority 2)
**Target**: Consolidate agent patterns with 40% overlap

**Files to consolidate**:
- `hierarchical_agents.md` (37KB) - Keep as canonical agent coordination reference
- `using-agents.md` (27KB) - Keep for integration patterns, remove duplicated context preservation sections
- `spec_updater_guide.md` - Keep separate (specific agent guide)

**Consolidation approach**:
- Move all context preservation/metadata extraction content to hierarchical_agents.md
- Update using-agents.md to reference hierarchical_agents.md for context preservation
- Remove duplicated agent invocation behavioral injection (keep in using-agents.md as canonical)

**Result**: Clear separation - hierarchical_agents.md (architecture), using-agents.md (integration patterns)

#### 3. Command Development Streamlining (Priority 3)
**Target**: Address 35-50% overlap in command development docs

**Files to consolidate**:
- `creating-commands.md` (54KB) - Keep but split if >50KB after adding unique content
- `command-patterns.md` (40KB) - Keep as pattern reference
- `command-examples.md` (35KB) - Keep as example reference

**Consolidation approach**:
- Review creating-commands.md for content that belongs in command-patterns.md
- Deduplicate checkpoint patterns between command-patterns.md and command-examples.md
- Ensure clear boundaries: creating-commands (comprehensive guide), command-patterns (pattern catalog), command-examples (concrete examples)

#### 4. Writing Standards Consolidation (Priority 4)
**Target**: Merge small related files

**Files to consolidate**:
- `development-philosophy.md` (2.2KB)
- `timeless_writing_guide.md` (14KB)

**Consolidation approach**:
- Merge into single `writing-standards.md` covering philosophy + timeless writing principles
- Result: Single ~16KB file on writing standards

#### 5. Checkpoint Documentation (Priority 5)
**Files to review**:
- `checkpoint_template_guide.md` - Verify unique content not duplicated in adaptive-planning-guide.md
- Consider consolidating if significant overlap

### Cross-Reference Update Strategy

**Files requiring cross-reference updates**:
1. `/home/benjamin/.config/CLAUDE.md` (directory_protocols section, development_workflow section, hierarchical_agent_architecture section)
2. `.claude/commands/*.md` (any commands referencing consolidated files)
3. `.claude/docs/README.md` (main documentation index)
4. Other docs cross-referencing consolidated files

**Update approach**:
- Phase 6 dedicated to cross-reference updates
- Use grep to find all references to consolidated files
- Update references to canonical locations
- Add README redirects for backward compatibility

### Backward Compatibility

**README.md redirect section**:
```markdown
## Deprecated Files (Redirects)

The following files have been consolidated:
- `topic_based_organization.md` → See [directory-protocols.md](directory-protocols.md)
- `artifact_organization.md` → See [directory-protocols.md](directory-protocols.md)
- `timeless_writing_guide.md` → See [writing-standards.md](writing-standards.md)
- `development-philosophy.md` → See [writing-standards.md](writing-standards.md)
```

## Implementation Phases

### Phase 1: Artifact Organization Consolidation [COMPLETED]
**Objective**: Merge directory-protocols.md, topic_based_organization.md, and artifact_organization.md into single canonical file
**Complexity**: High
**Estimated Time**: 45-60 minutes
**Actual Time**: ~60 minutes

Tasks:
- [x] Read all three files to understand complete content
- [x] Identify unique content in topic_based_organization.md (gitignore compliance)
- [x] Identify unique content in artifact_organization.md (lifecycle utilities, retention policies)
- [x] Create consolidated directory-protocols.md structure:
  - Overview and purpose
  - Specs directory structure (specs/{NNN_topic}/)
  - Artifact taxonomy (plans/, reports/, summaries/, debug/, scripts/, outputs/)
  - Topic-based organization (from topic_based_organization.md)
  - Gitignore compliance protocols (unique from topic_based_organization.md)
  - Artifact lifecycle management (unique from artifact_organization.md)
  - Retention policies (unique from artifact_organization.md)
  - Shell utilities for artifact operations
  - Cross-references to related docs
- [x] Merge content preserving all unique information
- [x] Ensure file size <50KB (target ~35-40KB) - Result: 27KB
- [x] Verify no content loss by comparing key concepts
- [x] Move old files to .claude/docs/archive/:
  - `mv topic_based_organization.md archive/`
  - `mv artifact_organization.md archive/`
- [x] Update archive/README.md with consolidation notes

Testing:
```bash
# Verify consolidated file exists and is properly formatted
test -f .claude/docs/directory-protocols.md
wc -l .claude/docs/directory-protocols.md  # Should be substantial

# Verify old files moved to archive
test -f .claude/docs/archive/topic_based_organization.md
test -f .claude/docs/archive/artifact_organization.md

# Check for key concepts in consolidated file
grep -q "topic-based organization" .claude/docs/directory-protocols.md
grep -q "gitignore compliance" .claude/docs/directory-protocols.md
grep -q "artifact lifecycle" .claude/docs/directory-protocols.md
grep -q "retention policies" .claude/docs/directory-protocols.md
```

Git Commit:
```bash
git add .claude/docs/directory-protocols.md .claude/docs/archive/
git commit -m "docs: Consolidate artifact organization documentation

Merged topic_based_organization.md and artifact_organization.md into
directory-protocols.md as single canonical reference for specs/
organization.

Changes:
- Consolidated 3 files (70% overlap) into 1 comprehensive guide
- Preserved unique gitignore compliance protocols
- Preserved artifact lifecycle management utilities
- Moved old files to archive/ for reference
- Result: ~35KB single source vs 50KB across 3 files

Part of documentation refactoring (Plan 070)"
```

### Phase 2: Agent Coordination Consolidation
**Objective**: Consolidate context preservation patterns between hierarchical_agents.md and using-agents.md
**Complexity**: Medium
**Estimated Time**: 30-45 minutes

Tasks:
- [ ] Read hierarchical_agents.md to identify context preservation sections
- [ ] Read using-agents.md to identify duplicated content
- [ ] Identify what to keep in each file:
  - hierarchical_agents.md: Multi-level coordination, metadata extraction, context pruning, recursive supervision
  - using-agents.md: Agent invocation patterns, integration patterns, behavioral injection
- [ ] Remove duplicated metadata extraction content from using-agents.md
- [ ] Add clear cross-references in using-agents.md: "For context preservation patterns, see [hierarchical_agents.md](hierarchical_agents.md)"
- [ ] Remove duplicated agent invocation behavioral injection from hierarchical_agents.md
- [ ] Add clear cross-reference in hierarchical_agents.md: "For agent invocation patterns, see [using-agents.md](using-agents.md)"
- [ ] Verify both files remain cohesive after deduplication
- [ ] Ensure clear boundaries: hierarchical_agents.md (architecture), using-agents.md (integration)

Testing:
```bash
# Verify files still exist and are properly structured
test -f .claude/docs/hierarchical_agents.md
test -f .claude/docs/using-agents.md

# Check for cross-references
grep -q "using-agents.md" .claude/docs/hierarchical_agents.md
grep -q "hierarchical_agents.md" .claude/docs/using-agents.md

# Verify key concepts in correct files
grep -q "metadata extraction" .claude/docs/hierarchical_agents.md
grep -q "behavioral injection" .claude/docs/using-agents.md
grep -q "context pruning" .claude/docs/hierarchical_agents.md

# Check file sizes reasonable
ls -lh .claude/docs/hierarchical_agents.md
ls -lh .claude/docs/using-agents.md
```

Git Commit:
```bash
git add .claude/docs/hierarchical_agents.md .claude/docs/using-agents.md
git commit -m "docs: Deduplicate agent coordination documentation

Removed overlapping content between hierarchical_agents.md and
using-agents.md while preserving all information.

Changes:
- Consolidated context preservation in hierarchical_agents.md
- Consolidated agent invocation patterns in using-agents.md
- Added cross-references between files
- Clear separation: architecture vs integration patterns
- Eliminated ~40% content overlap

Part of documentation refactoring (Plan 070)"
```

### Phase 3: Writing Standards Consolidation
**Objective**: Merge development-philosophy.md and timeless_writing_guide.md into single writing-standards.md
**Complexity**: Low
**Estimated Time**: 20-30 minutes

Tasks:
- [ ] Read development-philosophy.md (2.2KB) - project values, refactoring principles
- [ ] Read timeless_writing_guide.md (14KB) - documentation writing principles
- [ ] Create new writing-standards.md with sections:
  - Development Philosophy (from development-philosophy.md)
  - Timeless Writing Principles (from timeless_writing_guide.md)
  - Documentation Standards (synthesis of both)
- [ ] Merge content preserving all information
- [ ] Ensure consistent tone and structure
- [ ] Move old files to archive/:
  - `mv development-philosophy.md archive/`
  - `mv timeless_writing_guide.md archive/`
- [ ] Update archive/README.md with consolidation notes

Testing:
```bash
# Verify new file exists
test -f .claude/docs/writing-standards.md
wc -l .claude/docs/writing-standards.md  # Should be ~400-500 lines

# Verify old files archived
test -f .claude/docs/archive/development-philosophy.md
test -f .claude/docs/archive/timeless_writing_guide.md

# Check for key concepts
grep -q "development philosophy" .claude/docs/writing-standards.md
grep -q "timeless writing" .claude/docs/writing-standards.md
grep -q "refactoring principles" .claude/docs/writing-standards.md
grep -q "documentation standards" .claude/docs/writing-standards.md
```

Git Commit:
```bash
git add .claude/docs/writing-standards.md .claude/docs/archive/
git commit -m "docs: Consolidate writing and philosophy documentation

Merged development-philosophy.md and timeless_writing_guide.md into
single writing-standards.md covering project values and documentation
principles.

Changes:
- Combined 2 files (2.2KB + 14KB) into cohesive ~16KB guide
- Preserved refactoring principles and timeless writing guidance
- Moved old files to archive/
- Improved discoverability with unified standards

Part of documentation refactoring (Plan 070)"
```

### Phase 4: Command Development Streamlining
**Objective**: Review and deduplicate command development documentation (creating-commands.md, command-patterns.md, command-examples.md)
**Complexity**: Medium
**Estimated Time**: 30-45 minutes

Tasks:
- [ ] Read creating-commands.md (54KB) to identify content that belongs in command-patterns.md
- [ ] Read command-patterns.md and command-examples.md to identify checkpoint pattern duplication
- [ ] Move pure patterns from creating-commands.md to command-patterns.md if found
- [ ] Deduplicate checkpoint patterns between command-patterns.md and command-examples.md:
  - Keep pattern description in command-patterns.md
  - Keep concrete examples in command-examples.md
  - Add cross-references between files
- [ ] Ensure clear boundaries:
  - creating-commands.md: Comprehensive development guide
  - command-patterns.md: Pattern catalog (descriptions and structure)
  - command-examples.md: Concrete reusable examples
- [ ] Add cross-references between the three files
- [ ] Verify creating-commands.md is under or near 50KB target

Testing:
```bash
# Verify all three files exist
test -f .claude/docs/creating-commands.md
test -f .claude/docs/command-patterns.md
test -f .claude/docs/command-examples.md

# Check file sizes
ls -lh .claude/docs/creating-commands.md  # Should be ~50KB or less
ls -lh .claude/docs/command-patterns.md
ls -lh .claude/docs/command-examples.md

# Verify cross-references exist
grep -q "command-patterns.md" .claude/docs/creating-commands.md
grep -q "command-examples.md" .claude/docs/creating-commands.md
grep -q "creating-commands.md" .claude/docs/command-patterns.md

# Check for proper content separation
grep -q "checkpoint" .claude/docs/command-patterns.md
grep -q "checkpoint" .claude/docs/command-examples.md
```

Git Commit:
```bash
git add .claude/docs/creating-commands.md .claude/docs/command-patterns.md .claude/docs/command-examples.md
git commit -m "docs: Streamline command development documentation

Deduplicated content between creating-commands.md, command-patterns.md,
and command-examples.md while maintaining clear boundaries.

Changes:
- Removed checkpoint pattern duplication (35-50% overlap)
- Established clear file purposes: guide vs patterns vs examples
- Added cross-references between files
- Ensured creating-commands.md near 50KB target

Part of documentation refactoring (Plan 070)"
```

### Phase 5: Update Documentation Index and Cross-References in Docs
**Objective**: Update .claude/docs/README.md to reflect consolidation changes
**Complexity**: Medium
**Estimated Time**: 30-45 minutes

Tasks:
- [ ] Read current .claude/docs/README.md structure
- [ ] Update "Documentation Structure" section:
  - Remove topic_based_organization.md
  - Remove artifact_organization.md
  - Remove timeless_writing_guide.md
  - Remove development-philosophy.md
  - Add writing-standards.md
  - Update directory-protocols.md description to reflect expanded scope
- [ ] Update "Key Documents" sections:
  - Update directory-protocols.md entry with new comprehensive description
  - Add writing-standards.md entry
  - Remove entries for consolidated files
- [ ] Add "Deprecated Files (Redirects)" section:
  ```markdown
  ## Deprecated Files (Redirects)

  The following files have been consolidated for better organization:
  - `topic_based_organization.md` → [directory-protocols.md](directory-protocols.md)
  - `artifact_organization.md` → [directory-protocols.md](directory-protocols.md)
  - `timeless_writing_guide.md` → [writing-standards.md](writing-standards.md)
  - `development-philosophy.md` → [writing-standards.md](writing-standards.md)

  Archived versions available in [archive/](archive/) directory.
  ```
- [ ] Update "Navigation" sections:
  - Update all references to consolidated files
  - Add writing-standards.md to appropriate sections
- [ ] Update "Quick Reference by Role" if needed
- [ ] Verify all links work and point to correct files
- [ ] Update "Architecture and System Patterns" section:
  - Update Topic-Based Organization entry to reflect directory-protocols.md
  - Update Spec Maintenance cross-references
- [ ] Verify README.md follows documentation standards (no emojis, clear structure)

Testing:
```bash
# Verify README.md exists and was modified
test -f .claude/docs/README.md
git diff .claude/docs/README.md | head -20

# Check for new entries
grep -q "writing-standards.md" .claude/docs/README.md
grep -q "Deprecated Files" .claude/docs/README.md

# Check for removed entries (should NOT find in main sections)
grep -v "archive" .claude/docs/README.md | grep -q "topic_based_organization.md" && echo "ERROR: Should be removed" || echo "OK: Removed from main sections"

# Verify all links in README are valid
# Extract markdown links and check files exist
grep -o '\[.*\]([^)]*\.md)' .claude/docs/README.md | sed 's/.*(\(.*\))/\1/' | while read link; do
  test -f ".claude/docs/$link" || test -f ".claude/$link" || echo "BROKEN LINK: $link"
done
```

Git Commit:
```bash
git add .claude/docs/README.md
git commit -m "docs: Update README.md for documentation consolidation

Updated main documentation index to reflect consolidation changes and
provide redirect information for deprecated files.

Changes:
- Updated structure to reflect new writing-standards.md
- Updated directory-protocols.md description (expanded scope)
- Added Deprecated Files section with redirects
- Updated navigation and cross-references
- Verified all links working

Part of documentation refactoring (Plan 070)"
```

### Phase 6: Update CLAUDE.md and Command Cross-References
**Objective**: Update all cross-references in CLAUDE.md and command files to point to consolidated documentation
**Complexity**: High
**Estimated Time**: 45-60 minutes

Tasks:
- [ ] Search for references to consolidated files in CLAUDE.md:
  ```bash
  grep -n "topic_based_organization.md\|artifact_organization.md\|timeless_writing_guide.md\|development-philosophy.md" CLAUDE.md
  ```
- [ ] Update CLAUDE.md sections:
  - `directory_protocols` section: Update any references to topic_based_organization.md or artifact_organization.md
  - `development_philosophy` section: Update reference to point to writing-standards.md
  - `development_workflow` section: Update artifact organization references
  - `hierarchical_agent_architecture` section: Verify hierarchical_agents.md references are correct
- [ ] Search for references in command files:
  ```bash
  grep -r "topic_based_organization.md\|artifact_organization.md\|timeless_writing_guide.md\|development-philosophy.md" .claude/commands/
  ```
- [ ] Update command files with references to:
  - Replace topic_based_organization.md → directory-protocols.md
  - Replace artifact_organization.md → directory-protocols.md
  - Replace timeless_writing_guide.md → writing-standards.md
  - Replace development-philosophy.md → writing-standards.md
- [ ] Search for references in other documentation files:
  ```bash
  grep -r "topic_based_organization.md\|artifact_organization.md\|timeless_writing_guide.md\|development-philosophy.md" .claude/docs/ --exclude-dir=archive
  ```
- [ ] Update any remaining references in docs/
- [ ] Verify all cross-references point to correct consolidated files
- [ ] Test a sample command to ensure it can still find referenced documentation

Testing:
```bash
# Verify no references to old files remain outside archive/
grep -r "topic_based_organization.md" . --exclude-dir=archive --exclude-dir=.git | grep -v "070_docs_refactoring" || echo "OK: No remaining references"
grep -r "artifact_organization.md" . --exclude-dir=archive --exclude-dir=.git | grep -v "070_docs_refactoring" || echo "OK: No remaining references"
grep -r "timeless_writing_guide.md" . --exclude-dir=archive --exclude-dir=.git | grep -v "070_docs_refactoring" || echo "OK: No remaining references"
grep -r "development-philosophy.md" . --exclude-dir=archive --exclude-dir=.git | grep -v "070_docs_refactoring" || echo "OK: No remaining references"

# Verify new references exist
grep -q "directory-protocols.md" CLAUDE.md
grep -q "writing-standards.md" CLAUDE.md || echo "Note: May not be referenced in CLAUDE.md"

# Verify CLAUDE.md is still valid
test -f CLAUDE.md
head -50 CLAUDE.md | grep -q "# "
```

Git Commit:
```bash
git add CLAUDE.md .claude/commands/ .claude/docs/
git commit -m "docs: Update cross-references for documentation consolidation

Updated all references to consolidated documentation files across
CLAUDE.md, command files, and other documentation.

Changes:
- Updated CLAUDE.md sections with new file references
- Updated command files referencing old documentation
- Updated cross-references in remaining docs
- Verified all links point to correct consolidated files

Completes documentation refactoring (Plan 070)

Result:
- 30 organized files (from 34)
- ~20KB redundancy eliminated
- All content preserved
- Improved discoverability and maintainability"
```

## Testing Strategy

### Phase-by-Phase Testing
Each phase includes specific tests to verify:
- Files consolidated correctly
- No content loss
- Cross-references updated
- Git commits successful

### Final Validation Tests

After all phases complete:

```bash
# 1. Verify file count reduction
find .claude/docs -name "*.md" -not -path "*/archive/*" | wc -l
# Expected: ~30 files (down from 34)

# 2. Verify all archived files have archive notes
test -f .claude/docs/archive/README.md
grep -q "topic_based_organization.md" .claude/docs/archive/README.md
grep -q "artifact_organization.md" .claude/docs/archive/README.md

# 3. Verify no broken links in main documentation
.claude/tests/test_documentation_links.sh

# 4. Verify CLAUDE.md is still valid
grep -q "directory_protocols" CLAUDE.md
grep -q "development_philosophy" CLAUDE.md

# 5. Verify key consolidated files exist and are properly sized
test -f .claude/docs/directory-protocols.md
test -f .claude/docs/writing-standards.md
ls -lh .claude/docs/directory-protocols.md | awk '{print $5}'  # Should be ~35-40KB
ls -lh .claude/docs/writing-standards.md | awk '{print $5}'  # Should be ~16KB

# 6. Test documentation standards compliance
.claude/lib/validate-docs.sh .claude/docs/
# Checks for: no emojis, proper markdown, working links

# 7. Verify README.md redirect section exists
grep -q "Deprecated Files" .claude/docs/README.md

# 8. Integration test: Verify a command can still read standards
# Test /plan command can discover CLAUDE.md and referenced docs
echo "Testing command can access documentation..."
# (Manual test by running a command)
```

## Documentation Requirements

### Files to Update
1. `.claude/docs/README.md` - Main documentation index (Phase 5)
2. `CLAUDE.md` - Project configuration cross-references (Phase 6)
3. `.claude/docs/archive/README.md` - Archive index with consolidation notes (Phases 1, 3)
4. Command files referencing consolidated docs (Phase 6)

### Documentation Standards Compliance
All consolidated files must follow:
- No emojis in content
- Unicode box-drawing for diagrams
- Clear, concise language
- Code examples with syntax highlighting
- CommonMark specification
- Proper cross-references to related docs

## Dependencies

### Prerequisites
- Git working directory is clean (or acceptable to have changes)
- Backup of .claude/docs/ directory (recommended)
- Understanding of current documentation structure

### External Dependencies
None - all work is internal to .claude/docs/ directory

## Risk Assessment

### High Risk Areas
1. **Content Loss**: Risk of losing unique information during consolidation
   - **Mitigation**: Careful reading and comparison before merging; move old files to archive/ instead of deleting

2. **Broken References**: Risk of breaking cross-references in CLAUDE.md or commands
   - **Mitigation**: Phase 6 dedicated to finding and updating all references; comprehensive grep testing

3. **File Size Bloat**: Risk of consolidated files exceeding 50KB target
   - **Mitigation**: Monitor file sizes during consolidation; split if necessary

### Medium Risk Areas
1. **Incomplete Deduplication**: Risk of missing duplicated content
   - **Mitigation**: Research phase identified specific overlaps; systematic checking during consolidation

2. **Cross-Reference Complexity**: Risk of circular references or unclear documentation structure
   - **Mitigation**: Clear boundaries defined in technical design; README.md provides navigation

### Low Risk Areas
1. **Git History**: Consolidation may make git history less clear
   - **Mitigation**: Archive old files; clear commit messages explaining consolidation

## Notes

### Consolidation Principles
1. **Preserve all content**: Nothing is deleted, only reorganized
2. **Archive old files**: Move to archive/ instead of deleting for reference
3. **Clear boundaries**: Each file has a clear, focused purpose
4. **Cross-reference liberally**: Help readers find related information
5. **Follow Diátaxis principles**: Separate reference from guides, consolidate by topic

### Post-Consolidation Maintenance
After consolidation, documentation maintenance should be easier:
- Single source of truth for each topic (no need to update 3 files)
- Clearer boundaries between files (less confusion about where content belongs)
- Better discoverability (fewer files, better organization)
- Reduced maintenance burden (20KB less content to maintain)

### Future Improvements
Potential future enhancements (out of scope for this plan):
- Full Diátaxis reorganization (tutorials/how-to/reference/explanation subdirectories)
- Automated link checking in CI/CD
- Documentation versioning strategy
- Interactive documentation navigation

### Estimated Total Time
- Phase 1 (Artifact Org): 45-60 minutes
- Phase 2 (Agent Coordination): 30-45 minutes
- Phase 3 (Writing Standards): 20-30 minutes
- Phase 4 (Command Development): 30-45 minutes
- Phase 5 (README Update): 30-45 minutes
- Phase 6 (Cross-References): 45-60 minutes
- **Total**: 3.3-4.8 hours

### Success Metrics
- File count: 34 → ~30 (12% reduction)
- Content duplication: ~20KB eliminated
- File size compliance: All files <50KB
- Cross-references: 100% updated
- Content preservation: 100% (verified by testing)
- Documentation standards: 100% compliance
