# .claude/ Directory Cleanup Implementation Plan

## Metadata
- **Date**: 2025-11-13
- **Feature**: .claude/ directory cleanup for release readiness
- **Scope**: Template consolidation, file relocation, documentation updates, organizational standards
- **Estimated Phases**: 7
- **Estimated Hours**: 8-10
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 82.0
- **Research Reports**:
  - [Directory Structure Organization Analysis](../reports/001_directory_structure_organization_analysis.md)
  - [Scripts/Lib Consolidation Approach](../reports/002_scripts_lib_consolidation_approach.md)
  - [Template Relocation and Reference Updates](../reports/003_template_relocation_reference_updates.md)
  - [Documentation Updates and Organizational Standards](../reports/004_documentation_updates_organizational_standards.md)

## Overview

This plan consolidates the .claude/ directory structure to prepare for release by relocating templates to logical locations, removing misplaced files, updating documentation, and establishing clear organizational standards. The cleanup addresses template split across directories, scripts/lib distinction gaps, root-level misplaced files, and missing documentation that has caused developer confusion.

## Research Summary

Research identified four key improvement areas:

**Directory Structure** (Report 1):
- Templates illogically split: 1 agent template in .claude/templates/, 11 plan templates in commands/templates/
- validate_links_temp.sh misplaced at .claude/ root
- scripts/ and lib/ serve distinct purposes and should NOT be consolidated
- 119 files reference .claude/templates/ path requiring updates

**Scripts/Lib Distinction** (Report 2):
- scripts/: Standalone CLI tools (7 files) for validation, fixing, analysis
- lib/: Sourced function libraries (56 files) for commands/agents
- Previous spec 492 elimination attempt failed because directories serve different purposes
- No consolidation needed - organizational clarification required

**Template Migration** (Report 3):
- Create .claude/agents/templates/ for agent templates
- Move sub-supervisor-template.md from .claude/templates/ to agents/templates/
- Update 119 references using automated migration script
- Remove empty .claude/templates/ directory

**Documentation** (Report 4):
- Missing: scripts/README.md (7 operational tools undocumented)
- Misleading: lib/README.md title says "Standalone Utility Scripts" (incorrect)
- Gap: CLAUDE.md lacks directory organization standards and decision matrix
- Need: agents/templates/README.md for new directory

Recommended approach prioritizes high-impact, low-effort changes with automated reference updates and comprehensive verification.

## Success Criteria

- [ ] .claude/templates/ directory removed (empty after template relocation)
- [ ] agents/templates/ directory created with sub-supervisor-template.md
- [ ] validate_links_temp.sh relocated to scripts/ or deleted if redundant
- [ ] All 119 template references updated successfully
- [ ] Zero broken links (validate-links.sh passes)
- [ ] scripts/README.md created documenting operational tools
- [ ] lib/README.md title corrected and distinction clarified
- [ ] CLAUDE.md contains directory organization standards section
- [ ] agents/templates/README.md created
- [ ] Git history preserved for relocated files
- [ ] All documentation follows link conventions and writing standards

## Technical Design

### Architecture

**Directory Structure** (Final State):
```
.claude/
├── agents/
│   ├── templates/               # NEW - Agent templates
│   │   ├── sub-supervisor-template.md  # MOVED
│   │   └── README.md            # NEW
│   └── *.md                     # Existing agents
├── commands/
│   ├── templates/               # EXISTING - Plan templates (11 YAML files)
│   └── *.md                     # Existing commands
├── lib/                         # EXISTING - Sourced libraries (56 files)
├── scripts/                     # EXISTING - CLI tools (7+ files)
│   ├── validate-links.sh
│   ├── validate-docs-links.sh   # RELOCATED from root
│   └── README.md                # NEW
└── templates/                   # REMOVED (empty after migration)
```

**Reference Update Strategy**:
- Automated migration script with dry-run mode
- Pattern matching for absolute paths: `.claude/templates/sub-supervisor-template.md`
- Relative path calculation for context-sensitive references
- Verification checkpoints after each batch update

**Documentation Standards Integration**:
- All READMEs follow Documentation Policy from CLAUDE.md
- Directory organization standards added as new CLAUDE.md section
- Decision matrix for file placement decisions
- Clear examples and anti-examples

### Component Interactions

**Phase Dependencies**:
- Phase 1 (prepare) → Phases 2, 3 (independent) → Phases 4, 5 (verification) → Phase 6 (documentation) → Phase 7 (validation)
- Phases 2 and 3 can run in parallel (independent file operations)
- Phase 4 depends on completion of Phases 2 and 3
- Phase 6 depends on completion of all structural changes

### Migration Safety

**Git History Preservation**:
- Use `git mv` for all file relocations (preserves history)
- Incremental commits: structure creation → file moves → reference updates
- Rollback plan prepared before execution

**Verification Approach**:
- Dry-run mode for all automated scripts
- Link validation after each documentation update
- Functional testing for affected commands
- Reference count verification (before/after)

## Implementation Phases

### Phase 1: Preparation and Analysis
dependencies: []

**Objective**: Analyze current state, create migration infrastructure, verify assumptions

**Complexity**: Low

Tasks:
- [ ] Examine validate_links_temp.sh functionality and compare with scripts/validate-links.sh
- [ ] Determine if validate_links_temp.sh is unique or redundant (file: /home/benjamin/.config/.claude/validate_links_temp.sh)
- [ ] Create automated reference update script at .claude/scripts/update-template-references.sh
- [ ] Add dry-run mode to reference update script
- [ ] Add verification logic to reference update script (count before/after, detect failures)
- [ ] Verify count of template references: `grep -r ".claude/templates/" . --include="*.md" --include="*.sh" | wc -l`
- [ ] Document expected reference count (should be ~119 files)
- [ ] Create rollback script for template reference updates
- [ ] Test rollback script on sample files

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
# Verify validate_links_temp.sh analysis
test -f .claude/validate_links_temp.sh && echo "✓ Temp file exists"
diff .claude/validate_links_temp.sh .claude/scripts/validate-links.sh || echo "Files differ"

# Verify reference update script created
test -f .claude/scripts/update-template-references.sh && echo "✓ Script created"
chmod +x .claude/scripts/update-template-references.sh

# Test dry-run mode
./.claude/scripts/update-template-references.sh --dry-run
```

Expected Duration: 1 hour

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (validation script functional, dry-run works)
- [ ] Git commit created: `feat(700): complete Phase 1 - Preparation and Analysis`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Template Directory Structure Setup
dependencies: [1]

**Objective**: Create target directory structure for agent templates and READMEs

**Complexity**: Low

Tasks:
- [ ] Create .claude/agents/templates/ directory: `mkdir -p .claude/agents/templates`
- [ ] Create agents/templates/README.md documenting purpose, available templates, and usage (file: /home/benjamin/.config/.claude/agents/templates/README.md)
- [ ] Add sub-supervisor-template.md reference to README (even though file not yet moved)
- [ ] Add cross-reference to Agent Development Guide in README
- [ ] Add cross-reference to commands/templates/ for plan templates
- [ ] Verify directory structure created correctly
- [ ] Test README markdown syntax and links

Testing:
```bash
# Verify directory created
test -d .claude/agents/templates && echo "✓ Directory created"

# Verify README created
test -f .claude/agents/templates/README.md && echo "✓ README created"

# Check README size (should be >2KB for comprehensive doc)
FILE_SIZE=$(wc -c < .claude/agents/templates/README.md)
[ "$FILE_SIZE" -ge 2000 ] && echo "✓ README comprehensive"

# Validate markdown syntax
# (Visual inspection or markdown linter)
```

Expected Duration: 30 minutes

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (directory exists, README created and comprehensive)
- [ ] Git commit created: `feat(700): complete Phase 2 - Template Directory Structure Setup`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Relocate Root-Level File
dependencies: [1]

**Objective**: Move or delete validate_links_temp.sh from .claude/ root based on Phase 1 analysis

**Complexity**: Low

Tasks:
- [ ] Based on Phase 1 analysis, choose Option A (move) or Option B (delete)
- [ ] Option A: Move to scripts/validate-docs-links.sh using `git mv .claude/validate_links_temp.sh .claude/scripts/validate-docs-links.sh`
- [ ] Option A: Verify functionality after move: `./.claude/scripts/validate-docs-links.sh`
- [ ] Option B: Delete redundant file using `git rm .claude/validate_links_temp.sh`
- [ ] Search for any references to validate_links_temp.sh: `grep -r "validate_links_temp" . --exclude-dir=".git"`
- [ ] Update any found references to new location or remove if file deleted
- [ ] Verify .claude/ root contains no misplaced files: `ls .claude/*.sh 2>/dev/null`

Testing:
```bash
# Verify file relocated or deleted
test ! -f .claude/validate_links_temp.sh && echo "✓ Root cleaned"

# If moved, verify new location
if [ -f .claude/scripts/validate-docs-links.sh ]; then
  echo "✓ File relocated to scripts/"
  # Test functionality
  ./.claude/scripts/validate-docs-links.sh
fi

# Verify no references to old name
REF_COUNT=$(grep -r "validate_links_temp" . --exclude-dir=".git" 2>/dev/null | wc -l)
[ "$REF_COUNT" -eq 0 ] && echo "✓ No old references"
```

Expected Duration: 15 minutes

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (root cleaned, file relocated or deleted, no old references)
- [ ] Git commit created: `feat(700): complete Phase 3 - Relocate Root-Level File`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Template File Migration
dependencies: [1, 2]

**Objective**: Move sub-supervisor-template.md to agents/templates/ and update all references

**Complexity**: High

Tasks:
- [ ] Verify agents/templates/ directory exists (from Phase 2)
- [ ] Use git mv to relocate template: `git mv .claude/templates/sub-supervisor-template.md .claude/agents/templates/sub-supervisor-template.md`
- [ ] Verify file integrity after move: `wc -l .claude/agents/templates/sub-supervisor-template.md` (should be ~490 lines)
- [ ] Run reference update script in dry-run mode: `./.claude/scripts/update-template-references.sh --dry-run`
- [ ] Review dry-run output for any unexpected changes
- [ ] Execute actual reference updates: `./.claude/scripts/update-template-references.sh`
- [ ] Verify reference count updated: `grep -r ".claude/agents/templates/sub-supervisor-template.md" . | wc -l` (should be ~119)
- [ ] Verify no old references remain: `grep -r ".claude/templates/sub-supervisor-template.md" . --exclude-dir=".git" --exclude-dir="archive" | wc -l` (should be 0)
- [ ] Handle any relative path references requiring manual updates
- [ ] Test affected commands still work (/orchestrate, /coordinate)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
# Verify template moved
test -f .claude/agents/templates/sub-supervisor-template.md && echo "✓ Template moved"
test ! -f .claude/templates/sub-supervisor-template.md && echo "✓ Source removed"

# Verify content integrity
LINE_COUNT=$(wc -l < .claude/agents/templates/sub-supervisor-template.md)
[ "$LINE_COUNT" -ge 450 ] && echo "✓ Content intact (~490 lines)"

# Verify references updated
NEW_REFS=$(grep -r ".claude/agents/templates/sub-supervisor-template.md" . --exclude-dir=".git" | wc -l)
echo "New references: $NEW_REFS (expected ~119)"

# Verify old references gone
OLD_REFS=$(grep -r ".claude/templates/sub-supervisor-template.md" . --exclude-dir=".git" --exclude-dir="archive" | wc -l)
[ "$OLD_REFS" -eq 0 ] && echo "✓ No old references"

# Test git history preserved
git log --follow .claude/agents/templates/sub-supervisor-template.md | head -20
```

Expected Duration: 2 hours (including reference updates and verification)

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (template moved, references updated, no old references, git history preserved)
- [ ] Git commit created: `feat(700): complete Phase 4 - Template File Migration`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Remove Empty Directory
dependencies: [4]

**Objective**: Remove .claude/templates/ directory after verifying it's empty

**Complexity**: Low

Tasks:
- [ ] Verify .claude/templates/ is empty: `find .claude/templates -type f | wc -l` (should be 0)
- [ ] List any remaining files if directory not empty: `find .claude/templates -type f`
- [ ] If empty, remove directory: `git rm -r .claude/templates`
- [ ] If not empty, investigate remaining files before proceeding
- [ ] Verify directory removed: `test ! -d .claude/templates`
- [ ] Update any documentation referencing .claude/templates/ directory

Testing:
```bash
# Verify directory empty before removal
REMAINING=$(find .claude/templates -type f 2>/dev/null | wc -l)
if [ "$REMAINING" -eq 0 ]; then
  echo "✓ Directory empty, safe to remove"
else
  echo "✗ Directory not empty: $REMAINING files"
  find .claude/templates -type f
  exit 1
fi

# After removal, verify gone
test ! -d .claude/templates && echo "✓ Directory removed"

# Check for any references to old directory in docs
grep -r "\.claude/templates/" . --include="*.md" --exclude-dir=".git" | grep -v "Historical\|historical"
```

Expected Duration: 15 minutes

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (directory empty, removed, no active references)
- [ ] Git commit created: `feat(700): complete Phase 5 - Remove Empty Directory`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Documentation Updates
dependencies: [4, 5]

**Objective**: Create and update all documentation for organizational clarity

**Complexity**: Medium

Tasks:
- [ ] Create scripts/README.md documenting operational CLI tools (file: /home/benjamin/.config/.claude/scripts/README.md)
- [ ] Include scripts/ vs lib/ comparison section in scripts/README.md
- [ ] Document all 7+ current scripts with purposes
- [ ] Add naming conventions and when to use scripts/ section
- [ ] Update lib/README.md title from "Standalone Utility Scripts" to "Sourced Function Libraries"
- [ ] Add "Purpose vs scripts/" section to lib/README.md
- [ ] Add decision matrix to lib/README.md
- [ ] Add directory organization standards section to CLAUDE.md (file: /home/benjamin/.config/CLAUDE.md)
- [ ] Include purpose-based directory structure subsections in CLAUDE.md
- [ ] Add file placement decision matrix to CLAUDE.md
- [ ] Add anti-patterns section to CLAUDE.md directory standards
- [ ] Update .claude/README.md directory structure diagram
- [ ] Update .claude/docs/troubleshooting/broken-links-troubleshooting.md with script references
- [ ] Add cross-references between all updated READMEs

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
# Verify all READMEs created
test -f .claude/scripts/README.md && echo "✓ scripts/README.md created"
test -f .claude/agents/templates/README.md && echo "✓ agents/templates/README.md created"

# Verify CLAUDE.md updated
grep "Directory Organization Standards" CLAUDE.md && echo "✓ CLAUDE.md section added"
grep "Decision Matrix" CLAUDE.md && echo "✓ Decision matrix present"

# Verify lib/README.md title corrected
grep "Sourced Function Libraries" .claude/lib/README.md && echo "✓ Title corrected"

# Check README sizes (should be comprehensive)
for readme in .claude/scripts/README.md .claude/agents/templates/README.md; do
  SIZE=$(wc -c < "$readme" 2>/dev/null || echo 0)
  [ "$SIZE" -ge 2000 ] && echo "✓ $readme comprehensive"
done
```

Expected Duration: 3 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (all READMEs created, CLAUDE.md updated, sizes comprehensive)
- [ ] Git commit created: `feat(700): complete Phase 6 - Documentation Updates`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 7: Final Verification and Validation
dependencies: [6]

**Objective**: Comprehensive validation of all changes, link checking, and functionality testing

**Complexity**: Medium

Tasks:
- [ ] Run full link validation: `./.claude/scripts/validate-links.sh`
- [ ] Fix any broken links discovered
- [ ] Verify all READMEs have required sections (Purpose, Contents, Usage, Navigation)
- [ ] Test code examples in all updated documentation
- [ ] Verify no emojis in documentation: `grep -r "[\u{1F600}-\u{1F64F}]" .claude/docs/ .claude/*.md`
- [ ] Check markdown syntax for all updated files
- [ ] Test affected commands: /orchestrate, /coordinate (verify agent template access)
- [ ] Verify naming consistency across scripts/ and lib/ directories
- [ ] Run performance smoke test: `./.claude/scripts/analyze-coordinate-performance.sh` if logs available
- [ ] Verify git history preserved for all moved files: `git log --follow {file}`
- [ ] Check for any remaining references to old paths
- [ ] Create summary of changes for commit message
- [ ] Update this plan with completion status

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
# Comprehensive validation suite
echo "=== Link Validation ==="
./.claude/scripts/validate-links.sh || echo "✗ Broken links detected"

echo "=== Reference Verification ==="
OLD_TEMPLATE_REFS=$(grep -r ".claude/templates/sub-supervisor" . --exclude-dir=".git" --exclude-dir="archive" | wc -l)
[ "$OLD_TEMPLATE_REFS" -eq 0 ] && echo "✓ No old template references"

echo "=== README Completeness ==="
for readme in .claude/scripts/README.md .claude/agents/templates/README.md; do
  grep -q "Purpose" "$readme" && echo "✓ $readme has Purpose"
  grep -q "Navigation" "$readme" && echo "✓ $readme has Navigation"
done

echo "=== Git History ==="
git log --follow .claude/agents/templates/sub-supervisor-template.md | head -5
if [ -f .claude/scripts/validate-docs-links.sh ]; then
  git log --follow .claude/scripts/validate-docs-links.sh | head -5
fi

echo "=== Functional Testing ==="
# Test commands that use sub-supervisor template still work
# (Visual verification or command invocation)

echo "=== Success Criteria Checklist ==="
test ! -d .claude/templates && echo "✓ .claude/templates/ removed"
test -d .claude/agents/templates && echo "✓ agents/templates/ created"
test -f .claude/agents/templates/sub-supervisor-template.md && echo "✓ Template relocated"
test ! -f .claude/validate_links_temp.sh && echo "✓ Root file relocated"
test -f .claude/scripts/README.md && echo "✓ scripts/README.md created"
grep -q "Sourced Function Libraries" .claude/lib/README.md && echo "✓ lib/README.md corrected"
grep -q "Directory Organization Standards" CLAUDE.md && echo "✓ CLAUDE.md updated"
```

Expected Duration: 1.5 hours

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (all validation checks pass, no broken links, functionality verified)
- [ ] Git commit created: `feat(700): complete Phase 7 - Final Verification and Validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit-Level Testing

**Template Migration**:
- Verify file integrity after move (line count, content hash)
- Test reference update script on sample files
- Validate relative path calculations

**Documentation**:
- Markdown syntax validation
- Link validation for all updated files
- Code example testing (all examples must work)

### Integration Testing

**Cross-Reference Validation**:
- All links between READMEs work
- CLAUDE.md references to docs/ work
- Troubleshooting guides reference correct scripts

**Functional Testing**:
- Commands using sub-supervisor template work (/orchestrate, /coordinate)
- Scripts in scripts/ execute correctly
- Libraries in lib/ source correctly

### Regression Testing

**Git History**:
- Verify `git log --follow` shows complete history for moved files
- Test rollback procedure (dry-run)

**Reference Integrity**:
- No old path references remain (except in archive/)
- All 119 template references updated
- Historical references preserved where appropriate

### Acceptance Testing

**Success Criteria Verification**:
Run comprehensive validation suite (Phase 7) checking:
- Directory structure matches design
- Documentation complete and correct
- Links validated (validate-links.sh passes)
- Functionality preserved (commands work)
- Git history preserved (log --follow works)

**Performance**:
- Link validation runs in <30 seconds
- No regression in command execution time
- Documentation load time acceptable

## Documentation Requirements

### New Documentation Created

1. **scripts/README.md**:
   - Purpose and scope
   - Current scripts catalog
   - When to use scripts/ vs lib/
   - Naming conventions
   - Usage examples
   - Cross-references

2. **agents/templates/README.md**:
   - Available templates
   - Template usage instructions
   - Creating new templates
   - vs commands/templates/ distinction
   - Cross-references

### Existing Documentation Updated

1. **CLAUDE.md**:
   - Directory Organization Standards section (new)
   - File placement decision matrix
   - Anti-patterns documentation
   - Cross-references to README files

2. **lib/README.md**:
   - Title correction
   - Purpose vs scripts/ section
   - Decision matrix
   - Clarified scope

3. **.claude/README.md**:
   - Directory structure diagram
   - Organization principles
   - Cross-references

4. **broken-links-troubleshooting.md**:
   - Updated script references
   - New scripts/ location

### Documentation Standards Compliance

All documentation updates must:
- Follow link conventions (relative paths)
- Use UTF-8 encoding (no emojis)
- Include required README sections
- Use imperative language (MUST/WILL/SHALL)
- Provide code examples
- Include navigation links
- Pass link validation

## Dependencies

### External Dependencies

**Git**:
- git mv for file relocation (preserves history)
- git log --follow for history verification

**Bash Utilities**:
- grep, sed for reference updates
- find for directory analysis
- wc for file counting

### Internal Dependencies

**Scripts**:
- validate-links.sh (link validation)
- update-template-references.sh (created in Phase 1)

**Libraries**:
- No new library dependencies
- Existing libraries remain unchanged

### Phase Dependencies

**Parallel Execution Opportunities**:
- Phases 2 and 3 can run in parallel (independent operations)
- Phase 1 must complete before Phases 2 and 3
- Phases 4 and 5 must be sequential
- Phase 6 depends on completion of structural changes (Phases 4-5)
- Phase 7 depends on all previous phases

### Rollback Dependencies

**Rollback Plan**:
If issues arise, rollback in reverse phase order:
1. Phase 7 → Phase 6 (documentation updates)
2. Phase 6 → Phase 5 (directory removal)
3. Phase 5 → Phase 4 (template migration)
4. Phase 4 → Phase 3 (root file relocation)
5. Phase 3 → Phase 2 (directory creation)

Rollback script created in Phase 1 provides automated reversion.

## Risk Mitigation

### High-Risk Areas

**Template Reference Updates** (119 files):
- Risk: Broken references if script fails
- Mitigation: Dry-run mode, incremental commits, rollback script
- Verification: Reference count check before/after

**Git History Loss**:
- Risk: File history lost if using copy instead of git mv
- Mitigation: Enforce git mv usage, verify with git log --follow
- Verification: History check in Phase 7

**Documentation Link Breaks**:
- Risk: Broken cross-references after path changes
- Mitigation: Link validation after each documentation update
- Verification: validate-links.sh in Phase 7

### Medium-Risk Areas

**Relative Path Complexity**:
- Risk: Some references use relative paths requiring manual updates
- Mitigation: Script handles common patterns, manual review for edge cases
- Verification: Grep for remaining old paths

**Command Functionality**:
- Risk: Commands fail if template path incorrect
- Mitigation: Test affected commands (/orchestrate, /coordinate) after migration
- Verification: Functional testing in Phase 7

### Low-Risk Areas

**Directory Structure Changes**:
- Risk: Low - creating and removing empty directories
- Mitigation: Verify empty before removal
- Verification: Directory existence checks

## Notes

**Complexity Calculation**:
```
Score = Base(feature type) + Tasks/2 + Files*3 + Integrations*5
      = 10 (refactor) + 60/2 + 6*3 + 4*5
      = 10 + 30 + 18 + 20
      = 78.0
```

**Expansion Hint**: Complexity score of 78.0 is approaching threshold of 50 for phase expansion. If any phase becomes too complex during implementation, consider using `/expand phase` command to break it into separate files for better organization.

**Estimated Effort Breakdown**:
- Phase 1 (Preparation): 1 hour
- Phase 2 (Directory Setup): 30 minutes
- Phase 3 (Root File): 15 minutes
- Phase 4 (Template Migration): 2 hours
- Phase 5 (Directory Removal): 15 minutes
- Phase 6 (Documentation): 3 hours
- Phase 7 (Validation): 1.5 hours
- **Total**: 8.5 hours

**Key Success Factors**:
1. Automated reference updates reduce manual effort from days to hours
2. Git mv preserves history for complete audit trail
3. Incremental commits enable easy rollback
4. Comprehensive validation ensures no regressions
5. Documentation standards prevent future organizational confusion
