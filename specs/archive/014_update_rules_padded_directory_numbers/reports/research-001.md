# Research Report: Task #14

**Task**: 14 - update_rules_padded_directory_numbers
**Date**: 2026-02-02
**Focus**: Review rules files and directory protocols documentation to understand current padded directory number patterns and required updates

## Summary

The codebase has implemented 3-digit zero-padded directory numbers for task directories (e.g., `014_task_slug/` instead of `14_task_slug/`), but the documentation has not been updated to reflect this change. This research identifies all files that reference the old `{N}_{SLUG}` pattern and need to be updated to `{NNN}_{SLUG}`.

## Findings

### Current State Analysis

**Actual Directory Convention in Use**:
```
specs/
├── 014_update_rules_padded_directory_numbers/
├── 015_update_task_command_padded_dirs/
├── 016_update_workflow_commands_padded_paths/
├── 017_update_skills_padded_paths/
├── 018_update_agents_padded_paths/
├── 029_update_documentation_padded_paths/
├── 030_migrate_existing_directories_padded/
└── archive/
```

**Documentation Convention** (outdated):
- `{N}` = Unpadded task number (documented)
- `{NNN}` = 3-digit padded (only used for artifact versions)

### Placeholder Conventions Table (artifact-formats.md, lines 11-20)

Current definition states:
```markdown
| `{N}` | Unpadded integer | Task numbers, counts | `389`, `task 389:`, `{N}_{SLUG}` |
| `{NNN}` | 3-digit padded | Artifact versions | `001`, `research-001.md` |

**Key distinction**: Task numbers (`{N}`) are unpadded because they grow indefinitely.
Artifact versions (`{NNN}`) are padded because they rarely exceed 999 per task.
```

**Issue**: This description is now incorrect. Task directory numbers should be 3-digit padded for lexicographic sorting.

### Files Requiring Updates

The grep search found **100+ references** to `{N}_{SLUG}` across 38 files. The primary files requiring updates for this task (14) are:

#### 1. artifact-formats.md (PRIMARY TARGET)
**Path**: `.claude/rules/artifact-formats.md`

**Lines to update**:
- Line 13: Change `{N}_{SLUG}` example to `{NNN}_{SLUG}` or introduce new placeholder
- Line 20: Update "Key distinction" explanation
- Line 24: `specs/{N}_{SLUG}/reports/research-{NNN}.md`
- Line 58: `specs/{N}_{SLUG}/plans/implementation-{NNN}.md`
- Line 109: `specs/{N}_{SLUG}/summaries/implementation-summary-{DATE}.md`
- Line 136: `specs/{N}_{SLUG}/reports/error-report-{DATE}.md`

#### 2. state-management.md (PRIMARY TARGET)
**Path**: `.claude/rules/state-management.md`

**Lines to update**:
- Line 91: `"path": "specs/334_task_slug_here/reports/research-001.md"` - Example path
- Line 210: `- **Research**: [specs/{N}_{SLUG}/reports/research-001.md]`
- Line 216: `- **Plan**: [specs/{N}_{SLUG}/plans/implementation-001.md]`
- Line 223: `- **Summary**: [specs/{N}_{SLUG}/summaries/implementation-summary-20260108.md]`
- Line 232: `specs/{NUMBER}_{SLUG}/` directory structure
- Line 249: Directory creation example

### Files for Related Tasks (Not This Task)

The following files will be updated by tasks 15-18 and 29:
- **Task 15**: task.md command
- **Task 16**: implement.md, plan.md, revise.md, research.md commands
- **Task 17**: All skill files (skill-*.md)
- **Task 18**: All agent files (*-agent.md)
- **Task 29**: Documentation files (guides, context files)

### Recommended Placeholder Convention Change

**Option A: Redefine {N} to mean padded** (Not recommended)
- Would require understanding that `{N}` in directory context means padded
- Inconsistent with general integer semantics

**Option B: Use {NNN} for directory numbers** (Recommended)
- Explicit: `specs/{NNN}_{SLUG}/` clearly indicates 3-digit padding
- Consistent: `{NNN}` already means 3-digit padded in artifact context
- Clear: Distinct from `{N}` used in commit messages, task references

**Proposed Updated Table**:
```markdown
| Placeholder | Format | Usage | Examples |
|-------------|--------|-------|----------|
| `{N}` | Unpadded integer | Task numbers in text, commits | `389`, `task 389:` |
| `{NNN}` | 3-digit padded | Directory numbers, artifact versions | `014`, `research-001.md` |
| `{P}` | Unpadded integer | Phase numbers | `1`, `phase 1:` |
| `{DATE}` | YYYYMMDD | Date stamps in filenames | `20260111` |
| `{ISO_DATE}` | YYYY-MM-DD | ISO dates in content | `2026-01-11` |
| `{SLUG}` | snake_case | Task slug from title | `fix_bug_name` |
```

## Recommendations

### For artifact-formats.md

1. **Update placeholder table** (lines 11-20):
   - Change `{N}_{SLUG}` usage to specify that directories use `{NNN}_{SLUG}`
   - Update examples: `014` instead of `389` for directory context
   - Revise "Key distinction" to note directories also use padding for sorting

2. **Update all path templates** (lines 24, 58, 109, 136):
   - Change `specs/{N}_{SLUG}/` to `specs/{NNN}_{SLUG}/`

### For state-management.md

1. **Update example path** (line 91):
   - Change `specs/334_task_slug_here/` to `specs/334_task_slug_here/` (3 digits already)
   - Actually: keep example numeric value but clarify it would be `334` not `0334` since we use 3-digit padding only for numbers under 1000

2. **Update artifact linking section** (lines 210, 216, 223):
   - Change `specs/{N}_{SLUG}/` to `specs/{NNN}_{SLUG}/`

3. **Update directory structure example** (line 232):
   - Change `specs/{NUMBER}_{SLUG}/` to `specs/{NNN}_{SLUG}/`

4. **Update directory creation examples** (lines 247-257):
   - Change `specs/${task_num}_${slug}/` references to clarify padding

### Implementation Notes

The implementation should:
1. Use `printf "%03d" $task_num` or equivalent for directory path construction
2. Document that task numbers 1000+ will have 4 digits (no truncation)
3. Ensure backward compatibility comment that existing unpadded directories remain valid

## References

- `.claude/rules/artifact-formats.md` - Primary target file
- `.claude/rules/state-management.md` - Primary target file
- `.claude/CLAUDE.md` - Contains artifact paths summary (line 40-45)
- Grep results: 100+ references in 38 files across .claude/ directory

## Next Steps

1. Implement changes to artifact-formats.md
2. Implement changes to state-management.md
3. Verify placeholder table is consistent and clear
4. Coordinate with tasks 15-18 for command/skill/agent updates
