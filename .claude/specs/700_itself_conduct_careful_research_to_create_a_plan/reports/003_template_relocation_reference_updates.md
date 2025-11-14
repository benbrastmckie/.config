# Template Relocation and Reference Updates

## Metadata
- **Date**: 2025-11-13
- **Agent**: research-specialist (worker 3)
- **Topic**: Template relocation and reference updates
- **Report Type**: migration planning
- **Complexity Level**: 4

## Executive Summary

Analysis of template directory consolidation reveals split templates across `.claude/templates/` (1 file - sub-supervisor-template.md) and `.claude/commands/templates/` (11 YAML plan templates). Investigation shows 119 files reference `.claude/templates/` path across codebase. Recommended approach: (1) create `.claude/agents/templates/` directory, (2) move sub-supervisor-template.md to agent templates, (3) remove empty `.claude/templates/` directory, (4) update all 119 references using automated migration script with verification. This consolidation clarifies that plan templates belong with commands, agent templates belong with agents. Estimated effort: 3-4 hours including reference updates and testing.

## Current Template Organization

### Template Locations

**Location 1: `.claude/templates/`**
- Files: 1 (sub-supervisor-template.md)
- Size: 18,343 bytes
- Purpose: Agent sub-supervisor template
- Status: Misplaced (agent template in general templates directory)

**Location 2: `.claude/commands/templates/`**
- Files: 11 YAML plan templates + README.md
- Total Size: ~38KB
- Purpose: Plan templates for `/plan-from-template` command
- Status: Correct location (command-specific templates)

**Issue**: Templates split by type but location doesn't match purpose

### Template Content Analysis

**sub-supervisor-template.md** (in `.claude/templates/`):
```
Lines: ~490
Purpose: Template for creating hierarchical sub-supervisor agents
Contains:
- Agent metadata structure
- Execution protocol sections
- Worker invocation patterns
- Metadata aggregation logic
- Performance characteristics
Usage: Referenced by agent creation workflows
```

**YAML Plan Templates** (in `.claude/commands/templates/`):
1. `api-endpoint.yaml` - REST API endpoint implementation
2. `crud-feature.yaml` - CRUD operations implementation
3. `debug-workflow.yaml` - Debugging investigation workflow
4. `documentation-update.yaml` - Documentation sync planning
5. `example-feature.yaml` - Example template structure
6. `migration.yaml` - Database/API migration planning
7. `refactor-consolidation.yaml` - Code consolidation refactoring
8. `refactoring.yaml` - General refactoring planning
9. `research-report.yaml` - Research investigation planning
10. `test-suite.yaml` - Test infrastructure setup
11. `README.md` - Template catalog and usage guide

**Purpose**: Used by `/plan-from-template` command for rapid plan generation

## Reference Analysis

### Files Referencing `.claude/templates/`

**Total References**: 119 files

**Breakdown by Category**:

1. **Specifications** (~92 files):
   - Plans, reports, summaries referencing template patterns
   - Historical references from completed specs
   - Pattern documentation using templates as examples

2. **Documentation** (~15 files):
   - Reference docs citing template structure
   - Guide docs with template examples
   - Architecture docs describing template patterns

3. **Command Files** (~8 files):
   - Commands that create or use templates
   - Agent invocation patterns referencing sub-supervisor template
   - Orchestration patterns using template structures

4. **Library Files** (~4 files):
   - Template parsing utilities
   - Template integration libraries
   - Metadata extraction from templates

### Reference Pattern Analysis

**Pattern 1: Direct File References** (Most Common)
```markdown
See [Sub-Supervisor Template](.claude/templates/sub-supervisor-template.md)
```
**Count**: ~85 references
**Impact**: High - Requires path updates

**Pattern 2: Directory References**
```markdown
Templates are located in `.claude/templates/`
```
**Count**: ~20 references
**Impact**: Medium - May not need updates if general description

**Pattern 3: Code References**
```bash
TEMPLATE_PATH=".claude/templates/sub-supervisor-template.md"
```
**Count**: ~10 references
**Impact**: High - Breaks functionality if not updated

**Pattern 4: Historical/Archived References**
```markdown
(Historical note: Used .claude/templates/ prior to reorganization)
```
**Count**: ~4 references
**Impact**: Low - Can be preserved as historical context

### Critical References Requiring Updates

**High Priority** (Breaks functionality):
1. `.claude/lib/template-integration.sh` - Hardcoded template paths
2. `.claude/agents/research-sub-supervisor.md` - References sub-supervisor template
3. `.claude/docs/guides/hierarchical-supervisor-guide.md` - Template usage examples
4. `.claude/commands/orchestrate.md` - Agent creation using template
5. `.claude/commands/coordinate.md` - Sub-supervisor invocation patterns

**Medium Priority** (Documentation clarity):
6. `.claude/docs/reference/command_architecture_standards.md` - Template examples
7. `.claude/docs/concepts/hierarchical_agents.md` - Template patterns
8. `.claude/docs/architecture/state-based-orchestration-overview.md` - Template references

**Low Priority** (Historical context):
9. Spec reports and summaries with historical template references
10. Archived documentation with template citations

## Proposed Relocation Strategy

### Target Directory Structure

```
.claude/
├── agents/
│   ├── templates/                         # NEW DIRECTORY
│   │   ├── sub-supervisor-template.md     # MOVED FROM .claude/templates/
│   │   └── README.md                      # NEW FILE
│   ├── research-sub-supervisor.md
│   ├── research-specialist.md
│   └── ...
├── commands/
│   ├── templates/                         # EXISTING
│   │   ├── api-endpoint.yaml
│   │   ├── crud-feature.yaml
│   │   └── ... (11 YAML files + README)
│   └── ...
└── templates/                             # TO BE REMOVED (empty after move)
```

### Rationale for agents/templates/

**Why not keep in `.claude/templates/`?**
- Sub-supervisor template is agent-specific, not general-purpose
- Plan templates already in commands/templates/
- Empty .claude/templates/ directory serves no purpose

**Why agents/templates/ instead of agents/?**
- Separates template files from active agent definitions
- Allows for multiple agent templates in future
- Mirrors commands/templates/ pattern for consistency
- Clear namespace: agents/templates/ vs agents/{agent-name}.md

**Why not merge into commands/templates/?**
- Agent templates serve different purpose than plan templates
- Different usage patterns (agent creation vs plan generation)
- Different consumers (orchestrators vs planning commands)

## Migration Implementation Plan

### Phase 1: Create Target Directory Structure

**Tasks**:
1. Create `.claude/agents/templates/` directory
2. Create `.claude/agents/templates/README.md` documenting purpose

**README.md Content**:
```markdown
# Agent Templates

## Purpose
Templates for creating specialized agents in the .claude/agents/ directory.

## Available Templates
- [sub-supervisor-template.md](sub-supervisor-template.md) - Hierarchical sub-supervisor agent template

## Usage
Copy template to .claude/agents/{agent-name}.md and customize for your use case.

See [Agent Development Guide](../../docs/guides/agent-development-guide.md) for details.
```

**Verification**:
```bash
test -d .claude/agents/templates && echo "✓ Directory created"
test -f .claude/agents/templates/README.md && echo "✓ README created"
```

### Phase 2: Move Template File

**Tasks**:
1. Use `git mv` to preserve history
2. Verify file integrity after move

**Commands**:
```bash
git mv .claude/templates/sub-supervisor-template.md .claude/agents/templates/sub-supervisor-template.md
```

**Verification**:
```bash
# Verify move
test -f .claude/agents/templates/sub-supervisor-template.md && echo "✓ File moved"
test ! -f .claude/templates/sub-supervisor-template.md && echo "✓ Source removed"

# Verify content integrity
wc -l .claude/agents/templates/sub-supervisor-template.md
# Should show ~490 lines
```

### Phase 3: Update References (Automated)

**Create Migration Script**: `.claude/scripts/update-template-references.sh`

```bash
#!/bin/bash
# Update all references from .claude/templates/ to .claude/agents/templates/

set -e

CLAUDE_DIR="${CLAUDE_PROJECT_DIR:-.}"
DRY_RUN=false

if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "DRY RUN MODE - No files will be modified"
fi

# Find all files with references to old path
OLD_PATH=".claude/templates/sub-supervisor-template.md"
NEW_PATH=".claude/agents/templates/sub-supervisor-template.md"

echo "Searching for references to $OLD_PATH..."

FILES=$(grep -rl "$OLD_PATH" "$CLAUDE_DIR" \
  --include="*.md" \
  --include="*.sh" \
  --include="*.yaml" \
  --exclude-dir=".git" \
  --exclude-dir="archive" \
  2>/dev/null || true)

if [ -z "$FILES" ]; then
  echo "No references found"
  exit 0
fi

FILE_COUNT=$(echo "$FILES" | wc -l)
echo "Found $FILE_COUNT files with references"

# Update each file
while IFS= read -r file; do
  if [ "$DRY_RUN" = true ]; then
    echo "Would update: $file"
    grep -n "$OLD_PATH" "$file" || true
  else
    echo "Updating: $file"
    # Use sed for in-place replacement
    sed -i "s|$OLD_PATH|$NEW_PATH|g" "$file"
  fi
done <<< "$FILES"

if [ "$DRY_RUN" = false ]; then
  echo "✓ Updated $FILE_COUNT files"
else
  echo "DRY RUN: Would update $FILE_COUNT files"
fi
```

**Execution**:
```bash
# Test with dry run
./scripts/update-template-references.sh --dry-run

# Review changes
# If acceptable, run actual update
./scripts/update-template-references.sh

# Verify updates
grep -r ".claude/templates/sub-supervisor-template.md" . \
  --include="*.md" --include="*.sh" \
  --exclude-dir=".git" --exclude-dir="archive"
# Should output nothing (all references updated)
```

### Phase 4: Handle Relative Path References

**Issue**: Some references use relative paths depending on file location

**Examples**:
- From `.claude/commands/`: `../templates/sub-supervisor-template.md`
- From `.claude/docs/guides/`: `../../templates/sub-supervisor-template.md`
- From `.claude/specs/*/reports/`: `../../../templates/sub-supervisor-template.md`

**Solution**: Update reference script to handle relative paths

```bash
# Additional patterns to search
RELATIVE_PATTERNS=(
  "../templates/sub-supervisor-template.md"
  "../../templates/sub-supervisor-template.md"
  "../../../templates/sub-supervisor-template.md"
  "../../../../templates/sub-supervisor-template.md"
)

# For each file, calculate correct relative path to new location
# Based on file's directory depth
```

**Recommendation**: Convert all to absolute paths from project root for consistency
- Old: `../../templates/sub-supervisor-template.md`
- New: `.claude/agents/templates/sub-supervisor-template.md`

**Justification**: Per CLAUDE.md link conventions guide, repository-relative paths preferred

### Phase 5: Remove Empty Directory

**Tasks**:
1. Verify `.claude/templates/` is empty
2. Remove directory with git rm

**Commands**:
```bash
# Verify empty
REMAINING=$(find .claude/templates -type f | wc -l)
if [ "$REMAINING" -eq 0 ]; then
  echo "✓ Directory empty, safe to remove"
  git rm -r .claude/templates
else
  echo "✗ Directory not empty: $REMAINING files remaining"
  find .claude/templates -type f
  exit 1
fi
```

**Verification**:
```bash
test ! -d .claude/templates && echo "✓ Directory removed"
```

### Phase 6: Update Documentation

**Files to Update**:

1. **`.claude/README.md`**
   - Update directory structure diagram
   - Remove `.claude/templates/` reference
   - Add `.claude/agents/templates/` reference

2. **`.claude/docs/reference/command_architecture_standards.md`**
   - Update template references
   - Document new template organization

3. **`.claude/docs/guides/agent-development-guide.md`**
   - Update sub-supervisor template path
   - Document agents/templates/ directory

4. **CLAUDE.md**
   - Update any template references in standards sections
   - Verify no broken links

**Testing**:
```bash
# Run link validation
./scripts/validate-links.sh

# Check for any remaining old references
grep -r "\.claude/templates" . \
  --include="*.md" \
  --exclude-dir=".git" \
  --exclude-dir="archive" \
  | grep -v "Historical\|historical\|Previously\|previously"
```

### Phase 7: Verification and Testing

**Verification Checklist**:
- [ ] All 119 references updated successfully
- [ ] No broken links (validate-links.sh passes)
- [ ] sub-supervisor-template.md accessible at new location
- [ ] agents/templates/README.md created and correct
- [ ] Empty .claude/templates/ directory removed
- [ ] Git history preserved (git log --follow shows move)
- [ ] Commands using template still work
- [ ] Documentation references correct

**Functional Testing**:
```bash
# Test 1: Verify template accessible
test -f .claude/agents/templates/sub-supervisor-template.md && echo "✓ Template found"

# Test 2: Verify no old references
REFS=$(grep -r "\.claude/templates/sub-supervisor" . \
  --include="*.md" --include="*.sh" \
  --exclude-dir=".git" --exclude-dir="archive" | wc -l)
if [ "$REFS" -eq 0 ]; then
  echo "✓ No old references found"
else
  echo "✗ Found $REFS old references"
  exit 1
fi

# Test 3: Verify link validation passes
./scripts/validate-links.sh || echo "✗ Broken links detected"

# Test 4: Verify git history preserved
git log --follow .claude/agents/templates/sub-supervisor-template.md | head -20
# Should show history from .claude/templates/sub-supervisor-template.md
```

## Reference Update Strategy

### Automated vs Manual Updates

**Automated Updates** (Recommended for bulk):
- Use script for 119 file updates
- Consistent replacement pattern
- Verification built-in
- Reversible via git

**Manual Updates** (Required for complex cases):
- Files with context-sensitive references
- Historical notes that should remain
- Complex relative path calculations
- Custom formatting

### Update Prioritization

**Tier 1: Critical (Must update before migration)**
- Library files with hardcoded paths
- Command files with template usage
- Agent files referencing template

**Tier 2: High (Update during migration)**
- Documentation with template examples
- Reference guides with template links
- Architecture docs with template patterns

**Tier 3: Low (Update after migration)**
- Historical spec reports
- Archived documentation
- Completed summaries

### Rollback Plan

If migration encounters issues:

```bash
# Rollback commands
git reset --hard HEAD  # If not committed
# OR
git revert <commit>    # If already committed

# Restore old structure
git mv .claude/agents/templates/sub-supervisor-template.md .claude/templates/sub-supervisor-template.md
rm -rf .claude/agents/templates

# Re-run old reference pattern (create rollback script)
./scripts/rollback-template-references.sh
```

## Success Criteria

- [ ] `.claude/agents/templates/` directory created with README
- [ ] `sub-supervisor-template.md` moved to agents/templates/
- [ ] All 119 references updated to new path
- [ ] Zero broken links (validate-links.sh passes)
- [ ] `.claude/templates/` directory removed
- [ ] Git history preserved for template file
- [ ] Documentation updated and accurate
- [ ] No functional regressions (commands still work)
- [ ] Migration script created and tested
- [ ] Rollback plan documented and tested

## Effort Estimation

### Time Breakdown

| Phase | Task | Duration | Complexity |
|-------|------|----------|------------|
| 1 | Create directory structure | 10 min | Low |
| 2 | Move template file | 5 min | Low |
| 3 | Create migration script | 45 min | Medium |
| 4 | Test migration script | 30 min | Medium |
| 5 | Execute migration | 15 min | Low |
| 6 | Handle relative paths | 30 min | Medium |
| 7 | Remove empty directory | 5 min | Low |
| 8 | Update documentation | 45 min | Medium |
| 9 | Verification and testing | 30 min | Medium |
| **Total** | | **3.5 hours** | **Medium** |

### Risk Assessment

**Low Risk**:
- Git mv preserves history
- Automated script ensures consistency
- Link validation catches errors
- Rollback plan available

**Medium Risk**:
- 119 references is large update surface
- Relative path complexity could cause issues
- Historical references might need special handling

**Mitigation**:
- Dry-run mode for all automated changes
- Incremental commits (directory create, file move, reference updates)
- Comprehensive testing before final commit
- Rollback script prepared in advance

## Key Findings

1. **Templates are split illogically**: Agent template in general directory, plan templates in commands/
2. **Large reference count**: 119 files reference old path (requires careful migration)
3. **Automation essential**: Manual updates impractical for 119 references
4. **History preservation critical**: Use git mv, not copy/delete
5. **Testing required**: Link validation must pass before completion

## Recommendations

1. **Create agents/templates/** - Logical home for agent templates
2. **Automate reference updates** - Script-based migration with verification
3. **Preserve git history** - Use git mv for file relocation
4. **Comprehensive testing** - Verify links, functionality, documentation
5. **Incremental commits** - Separate structure, move, and update commits
6. **Rollback readiness** - Prepare and test rollback procedure

**Priority**: Medium-High (cleanup needed for release, but not blocking)
**Complexity**: Medium (automated approach reduces manual effort)
**Impact**: High organizational clarity, correct template placement
