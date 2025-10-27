# Templates Directory Cleanup and Consolidation Plan

## Metadata
- **Date**: 2025-10-27
- **Feature**: Templates directory cleanup and consolidation
- **Scope**: Remove unused templates, relocate used templates to appropriate directories, remove .claude/templates/
- **Estimated Phases**: 5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: /home/benjamin/.config/.claude/specs/493_research_the_homebenjaminconfigclaudetemplates_dir/reports/493_overview.md

## Overview

This plan implements a systematic cleanup of the `.claude/templates/` directory based on comprehensive research findings. The goal is to:

1. **Remove obsolete templates** (2 files identified as no longer used)
2. **Relocate markdown templates** used by commands to `.claude/commands/shared/`
3. **Relocate YAML templates** to `.claude/commands/templates/`
4. **Update all references** in commands to point to new locations
5. **Remove the `.claude/templates/` directory** entirely

The research identified 26 files (240KB) with three distinct purposes:
- **YAML plan templates** (11 files, critical) - Used by `/plan-from-template`
- **Orchestration patterns** (3 files, critical) - Used by multiple commands for agent coordination
- **Structure documentation** (13 files, mostly redundant) - Some obsolete, some single-use

**Key Insight**: Agents embed templates inline; structure files are for reference only. This means careful relocation without breaking command workflows is essential.

## Success Criteria

- [ ] All obsolete templates removed (2 files identified)
- [ ] All YAML templates moved to `.claude/commands/templates/` (11 files)
- [ ] All markdown reference templates moved to `.claude/commands/shared/` (appropriate files)
- [ ] All command references updated to new paths
- [ ] No broken references (validated with grep)
- [ ] `.claude/templates/` directory removed
- [ ] All commands continue to work correctly
- [ ] README.md updated in target directories

## Technical Design

### Directory Structure (After)

```
.claude/commands/
├── templates/           # NEW: YAML plan templates
│   ├── README.md
│   ├── api-endpoint.yaml
│   ├── crud-feature.yaml
│   ├── debug-workflow.yaml
│   ├── documentation-update.yaml
│   ├── example-feature.yaml
│   ├── migration.yaml
│   ├── refactor-consolidation.yaml
│   ├── refactoring.yaml
│   ├── research-report.yaml
│   └── test-suite.yaml
├── shared/              # EXISTING: Markdown reference docs
│   ├── agent-invocation-patterns.md
│   ├── agent-tool-descriptions.md
│   ├── audit-checklist.md
│   ├── command-frontmatter.md
│   ├── debug-structure.md
│   ├── orchestration-patterns.md
│   ├── output-patterns.md
│   ├── readme-template.md
│   ├── refactor-structure.md
│   └── report-structure.md
└── *.md                 # Command files
```

### Files to Remove (Obsolete)

1. `artifact_research_invocation.md` - References deprecated artifact system
2. `spec-updater-test.yaml` - Test template for deprecated workflow

### Files to Relocate

**To `.claude/commands/templates/` (11 YAML files)**:
- api-endpoint.yaml
- crud-feature.yaml
- debug-workflow.yaml
- documentation-update.yaml
- example-feature.yaml
- migration.yaml
- refactor-consolidation.yaml
- refactoring.yaml
- research-report.yaml
- test-suite.yaml
- (plus README.md - will be created)

**To `.claude/commands/shared/` (9 markdown files)**:
- agent-invocation-patterns.md
- agent-tool-descriptions.md
- audit-checklist.md
- command-frontmatter.md
- debug-structure.md
- orchestration-patterns.md
- output-patterns.md
- readme-template.md
- refactor-structure.md
- report-structure.md

**Special Case**: `sub_supervisor_pattern.md` - Should move to `.claude/docs/patterns/` (not part of this cleanup)

### Reference Update Strategy

Commands reference templates using these patterns:
1. Direct file paths: `.claude/templates/filename.yaml`
2. Directory references: `.claude/templates/*.yaml`
3. Inline documentation references

Update approach:
- Use `sed` for bulk path replacements
- Manual verification for complex references
- Test each command after updates

## Implementation Phases

### Phase 1: Preparation and Validation [COMPLETED]
**Objective**: Verify current state and create target directories
**Complexity**: Low

Tasks:
- [x] Create `.claude/commands/templates/` directory
- [x] Verify `.claude/commands/shared/` exists and is usable
- [x] Run comprehensive grep to catalog all template references
- [x] Generate reference update checklist (file → references mapping)
- [x] Backup `.claude/templates/` directory to safe location

Testing:
```bash
# Verify directories created
test -d /home/benjamin/.config/.claude/commands/templates || echo "FAIL: templates dir not created"
test -d /home/benjamin/.config/.claude/commands/shared || echo "FAIL: shared dir missing"

# Verify grep results saved
test -f /tmp/template-references.txt || echo "FAIL: reference catalog not created"
```

### Phase 2: Remove Obsolete Templates [COMPLETED]
**Objective**: Delete files with no active references
**Complexity**: Low

Tasks:
- [x] Validate zero references: `grep -r "artifact_research_invocation" .claude/commands/`
- [x] Validate zero references: `grep -r "spec-updater-test" .claude/commands/`
- [x] Remove `.claude/templates/artifact_research_invocation.md`
- [x] Remove `.claude/templates/spec-updater-test.yaml`
- [x] Document removal in `.claude/TODO.md` or changelog

Testing:
```bash
# Verify files removed
test ! -f /home/benjamin/.config/.claude/templates/artifact_research_invocation.md || echo "FAIL: obsolete file still exists"
test ! -f /home/benjamin/.config/.claude/templates/spec-updater-test.yaml || echo "FAIL: obsolete file still exists"

# Verify no broken references (should return nothing)
grep -r "artifact_research_invocation\|spec-updater-test" /home/benjamin/.config/.claude/commands/
```

### Phase 3: Relocate YAML Templates
**Objective**: Move all YAML plan templates to `.claude/commands/templates/`
**Complexity**: Medium

Tasks:
- [ ] Copy all YAML files from `.claude/templates/*.yaml` to `.claude/commands/templates/`
- [ ] Create `.claude/commands/templates/README.md` with usage documentation
- [ ] Update `/plan-from-template` command references (OLD: `.claude/templates/`, NEW: `.claude/commands/templates/`)
- [ ] Update any other commands referencing YAML templates
- [ ] Verify all YAML files accessible by testing `/plan-from-template --list-categories`

Testing:
```bash
# Verify all YAML files moved
yaml_count=$(ls /home/benjamin/.config/.claude/commands/templates/*.yaml 2>/dev/null | wc -l)
test "$yaml_count" -eq 10 || echo "FAIL: Expected 10 YAML files, found $yaml_count"

# Verify no references to old path
if grep -r "\.claude/templates/.*\.yaml" /home/benjamin/.config/.claude/commands/*.md; then
    echo "FAIL: Found references to old YAML template paths"
    exit 1
fi

# Test command functionality (if possible)
# /plan-from-template --list-categories
```

Files to move:
1. api-endpoint.yaml
2. crud-feature.yaml
3. debug-workflow.yaml
4. documentation-update.yaml
5. example-feature.yaml
6. migration.yaml
7. refactor-consolidation.yaml
8. refactoring.yaml
9. research-report.yaml
10. test-suite.yaml

### Phase 4: Relocate Markdown Reference Templates
**Objective**: Move markdown templates to `.claude/commands/shared/`
**Complexity**: Medium

Tasks:
- [ ] Copy markdown files to `.claude/commands/shared/` (see list below)
- [ ] Update `.claude/commands/shared/README.md` with new file descriptions
- [ ] Update command references: `/debug` command (debug-structure.md)
- [ ] Update command references: `/refactor` command (refactor-structure.md)
- [ ] Update command references: `/research` command (report-structure.md)
- [ ] Update command references: `/orchestrate` command (orchestration-patterns.md, agent-invocation-patterns.md, output-patterns.md)
- [ ] Update command references: Any commands referencing command-frontmatter.md
- [ ] Update command references: Any commands referencing agent-tool-descriptions.md
- [ ] Verify all references updated with comprehensive grep

Testing:
```bash
# Verify all markdown files moved
expected_files="agent-invocation-patterns agent-tool-descriptions audit-checklist command-frontmatter debug-structure orchestration-patterns output-patterns readme-template refactor-structure report-structure"

for file in $expected_files; do
    test -f "/home/benjamin/.config/.claude/commands/shared/${file}.md" || echo "FAIL: $file.md not moved"
done

# Verify no references to old template path
if grep -r "\.claude/templates/" /home/benjamin/.config/.claude/commands/*.md | grep -v "\.claude/commands/templates/"; then
    echo "FAIL: Found references to old .claude/templates/ path"
    exit 1
fi

# Verify README.md updated
grep -q "agent-invocation-patterns.md" /home/benjamin/.config/.claude/commands/shared/README.md || echo "FAIL: README not updated"
```

Files to move:
1. agent-invocation-patterns.md
2. agent-tool-descriptions.md
3. audit-checklist.md
4. command-frontmatter.md
5. debug-structure.md
6. orchestration-patterns.md
7. output-patterns.md
8. readme-template.md
9. refactor-structure.md
10. report-structure.md

Command references to update (minimum):
- `/debug` → debug-structure.md
- `/refactor` → refactor-structure.md
- `/research` → report-structure.md
- `/orchestrate` → orchestration-patterns.md, agent-invocation-patterns.md, output-patterns.md
- `/plan-from-template` → command-frontmatter.md (if referenced)
- Multiple commands → agent-invocation-patterns.md (17+ references according to research)

### Phase 5: Cleanup and Validation
**Objective**: Remove old directory and verify system integrity
**Complexity**: Low

Tasks:
- [ ] Run comprehensive validation: `grep -r "\.claude/templates" .claude/commands/` (should find only `.claude/commands/templates/`)
- [ ] Verify all commands load successfully (syntax check)
- [ ] Remove remaining files from `.claude/templates/` (README.md, sub_supervisor_pattern.md if still there)
- [ ] Remove `.claude/templates/` directory
- [ ] Update CLAUDE.md references (if any) to point to new locations
- [ ] Update `.claude/commands/README.md` to document new template locations
- [ ] Run smoke test: `/plan-from-template --list-categories`
- [ ] Run smoke test: Load `/orchestrate`, `/debug`, `/refactor`, `/research` commands

Testing:
```bash
# Verify old directory removed
test ! -d /home/benjamin/.config/.claude/templates || echo "FAIL: Old templates directory still exists"

# Verify no broken references
broken_refs=$(grep -r "\.claude/templates/" /home/benjamin/.config/.claude/commands/*.md 2>/dev/null | grep -v "\.claude/commands/templates/" | wc -l)
test "$broken_refs" -eq 0 || echo "FAIL: Found $broken_refs broken template references"

# Verify critical commands load (basic syntax validation)
for cmd in orchestrate debug refactor research plan-from-template; do
    if ! grep -q "^# " "/home/benjamin/.config/.claude/commands/${cmd}.md" 2>/dev/null; then
        echo "FAIL: Command ${cmd}.md appears malformed"
    fi
done

# Verify template directory structure
test -d /home/benjamin/.config/.claude/commands/templates || echo "FAIL: New templates dir missing"
test -d /home/benjamin/.config/.claude/commands/shared || echo "FAIL: Shared dir missing"
```

## Testing Strategy

### Pre-Implementation Validation
1. Catalog all existing template references with grep
2. Save catalog for comparison after migration
3. Verify backup exists

### Per-Phase Testing
Each phase includes specific validation commands (see phase descriptions above)

### Post-Implementation Validation
1. **Reference integrity**: `grep -r "\.claude/templates" .claude/` should only find `.claude/commands/templates/`
2. **Command functionality**: Test commands that use templates
   - `/plan-from-template --list-categories` (should list all templates)
   - `/orchestrate` (should load without errors)
   - `/debug`, `/refactor`, `/research` (should reference new paths)
3. **File completeness**: Verify all expected files in new locations
4. **Directory removal**: Verify `.claude/templates/` no longer exists

### Rollback Plan
If critical issues discovered:
1. Restore from backup: `cp -r /backup/.claude/templates /home/benjamin/.config/.claude/`
2. Revert command changes: `git checkout .claude/commands/`
3. Remove new directories: `rm -rf .claude/commands/templates`

## Documentation Requirements

### Files to Update
1. **`.claude/commands/templates/README.md`** (create new)
   - Document all YAML template files
   - Explain usage with `/plan-from-template`
   - Include variable syntax guide

2. **`.claude/commands/shared/README.md`** (update existing)
   - Add entries for all relocated markdown files
   - Update any references to old `.claude/templates/` path

3. **`.claude/commands/README.md`** (update)
   - Update template location references
   - Add note about template migration

4. **`CLAUDE.md`** (update if needed)
   - Update any references to `.claude/templates/`
   - Update project_commands section if it references templates

## Dependencies

### Prerequisites
- Backup of `.claude/templates/` directory
- Write access to `.claude/commands/` directory
- Git working directory clean (for easy rollback)

### External Dependencies
None - all changes are internal file relocations

## Notes

### Design Decisions

1. **Why two directories?**
   - `.claude/commands/templates/` for YAML files (runtime loaded by `/plan-from-template`)
   - `.claude/commands/shared/` for markdown reference docs (read by multiple commands)
   - Separation matches usage pattern: operational vs. reference

2. **Why not inline structure templates?**
   - Research suggests inlining for single-use templates
   - This plan focuses on relocation only (no substantial command changes per user request)
   - Inlining can be done in future optimization phase

3. **Why keep separate from agents?**
   - Agents embed templates inline (self-contained)
   - Command reference docs serve different purpose (developer documentation)
   - Research confirms agents don't read `.claude/templates/` files

### Future Optimization Opportunities

Based on research findings, future phases could:
1. Inline single-use structures into commands (debug-structure.md → `/debug`)
2. Merge redundant files (agent-tool-descriptions.md → command-frontmatter.md)
3. Consolidate refactoring templates (refactoring.yaml + refactor-consolidation.yaml)
4. Move sub_supervisor_pattern.md to `.claude/docs/patterns/`

These are explicitly excluded from this plan per user requirements (no substantial command changes).

### Risk Assessment

**Low Risk**:
- File moves (reversible with backup)
- Path updates (automated with sed)

**Medium Risk**:
- Breaking command functionality if references missed
- Mitigation: Comprehensive grep validation, per-phase testing

**High Risk**:
- None identified (no code logic changes, no schema changes)

### Validation Checklist

Before declaring completion:
- [ ] All YAML files in `.claude/commands/templates/`
- [ ] All markdown files in `.claude/commands/shared/`
- [ ] Zero references to `.claude/templates/` (except `.claude/commands/templates/`)
- [ ] `/plan-from-template --list-categories` works
- [ ] All commands load without errors
- [ ] README files updated
- [ ] Old directory removed
- [ ] Backup preserved

## Estimated Timeline

- **Phase 1**: 30 minutes (preparation)
- **Phase 2**: 15 minutes (removal)
- **Phase 3**: 45 minutes (YAML relocation)
- **Phase 4**: 90 minutes (markdown relocation, most references)
- **Phase 5**: 30 minutes (cleanup and validation)

**Total**: ~3.5 hours

## Cross-References

- **Research Report**: `.claude/specs/493_research_the_homebenjaminconfigclaudetemplates_dir/reports/493_overview.md`
- **Command Development Guide**: `.claude/docs/guides/command-development-guide.md`
- **Template System Docs**: `.claude/templates/README.md` (will be relocated)
- **Project Standards**: `CLAUDE.md` § code_standards
