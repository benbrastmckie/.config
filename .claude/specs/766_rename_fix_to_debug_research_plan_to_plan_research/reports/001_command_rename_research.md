# Command Rename Research Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Rename /fix to /debug, /research-plan to /plan, /research-report to /research, /research-revise to /revise
- **Report Type**: codebase analysis

## Executive Summary

This research identifies 4 command definition files requiring renaming, with extensive cross-references across 20+ documentation files, 6 test files, and 100+ spec artifacts. Critical finding: archived legacy commands already exist with target names (/debug, /plan, /research, /revise in `/home/benjamin/.config/.claude/archive/legacy-workflow-commands/commands/`), requiring careful handling to avoid confusion. The clean-break approach is appropriate - old names should not redirect to new names, and archived commands should remain clearly archived with updated documentation noting the current active commands.

## Findings

### 1. Command Definition Files to Rename

Primary files in `/home/benjamin/.config/.claude/commands/`:

| Current File | Target File | Lines |
|-------------|-------------|-------|
| `fix.md` | `debug.md` | ~608 |
| `research-plan.md` | `plan.md` | ~497 |
| `research-report.md` | `research.md` | ~362 |
| `research-revise.md` | `revise.md` | ~491 |

### 2. Critical Conflict: Archived Legacy Commands

**IMPORTANT**: The target names already exist as archived commands:
- `/home/benjamin/.config/.claude/archive/legacy-workflow-commands/commands/debug.md` (11,660 bytes)
- `/home/benjamin/.config/.claude/archive/legacy-workflow-commands/commands/plan.md` (32,737 bytes)
- `/home/benjamin/.config/.claude/archive/legacy-workflow-commands/commands/research.md` (34,963 bytes)
- `/home/benjamin/.config/.claude/archive/legacy-workflow-commands/commands/revise.md` (22,324 bytes)

The archive README (`/home/benjamin/.config/.claude/archive/legacy-workflow-commands/README.md:51-53`) explicitly states:
- `/research-plan` replaces research + plan workflow
- `/research-revise` replaces research + revise workflow
- `/research-report` replaces research-only workflow

### 3. Documentation Files Requiring Updates

**Command Reference** (`/home/benjamin/.config/.claude/docs/reference/command-reference.md`):
- Lines 28, 36-38, 187, 255-272, 309, 391-450, 455-470, 556-569, 605-611
- Contains section headings like `### /fix`, `### /research-plan`, etc.
- ARCHIVED status notes pointing to old names must be updated

**Guide Files** in `/home/benjamin/.config/.claude/docs/guides/`:
- `research-plan-command-guide.md` - 429 lines, rename to `plan-command-guide.md`
- `research-report-command-guide.md` - 391 lines, rename to `research-command-guide.md`
- `research-revise-command-guide.md` - extensive references throughout
- `fix-command-guide.md` - rename to `debug-command-guide.md`

**Directory Protocols** (`/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md:130-132`):
- `/research-plan` - Creates research+plan topic
- `/fix` - Creates debug topic
- `/research-report` - Creates research-only topic

**Command Authoring Standards** (`/home/benjamin/.config/.claude/docs/reference/command-authoring-standards.md:456`):
- Reference commands list includes `/research-report`, `/research-plan`, `/research-revise`

### 4. Agent Files with Command References

**Workflow Classifier** (`/home/benjamin/.config/.claude/agents/workflow-classifier.md:82`):
- Reference to "debug/fix" pattern in workflow type classification

**Research Specialist** (`/home/benjamin/.config/.claude/agents/research-specialist.md`):
- Examples reference `/report` command but primary references are in command files

### 5. Test Files Requiring Updates

| Test File | Lines | Impact |
|-----------|-------|--------|
| `test_compliance_remediation_phase7.sh` | 20-23 | Command file paths array |
| `test_subprocess_isolation_research_plan.sh` | 3, 36 | Filename and echo statements |
| `test_command_topic_allocation.sh` | 53-150 | Multiple arrays with command filenames |

### 6. Commands README Updates

`/home/benjamin/.config/.claude/commands/README.md`:
- Line 80: Integration with /research-plan command
- Line 350: Command category lists
- Lines 354, 358: Cross-references
- Lines 397, 400: Command descriptions
- Lines 456, 469: [Used by:] metadata
- Lines 647-698: Usage examples

### 7. Spec Artifacts (Read-only, Historical)

Over 100 references in `/home/benjamin/.config/.claude/specs/` directories. These are historical records and should NOT be modified. They document the state of the system at the time of creation.

Key specs with extensive references:
- `specs/26_*/` - Debug strategy and fixes for research-plan
- `specs/746_*/` - Command compliance assessment
- `specs/753_*/` - Unified specs directory numbering
- `specs/21_*/` - Compliance remediation implementation

### 8. CLAUDE.md Project Configuration

The root `/home/benjamin/.config/CLAUDE.md` does NOT contain direct references to these commands - references are in linked documentation.

### 9. Library Files

No direct command references found in `/home/benjamin/.config/.claude/lib/` - these files contain shared functions but don't hardcode command names.

## Recommendations

### 1. Phased Rename Approach (Priority Order)

**Phase 1: Command Files (Critical)**
1. Rename command definition files in `/home/benjamin/.config/.claude/commands/`:
   - `fix.md` -> `debug.md`
   - `research-plan.md` -> `plan.md`
   - `research-report.md` -> `research.md`
   - `research-revise.md` -> `revise.md`
2. Update internal command headers (e.g., `# /research-plan` -> `# /plan`)
3. Update frontmatter documentation references

**Phase 2: Guide File Renames**
1. `research-plan-command-guide.md` -> `plan-command-guide.md`
2. `research-report-command-guide.md` -> `research-command-guide.md`
3. `fix-command-guide.md` -> `debug-command-guide.md`
4. `research-revise-command-guide.md` -> `revise-command-guide.md`

**Phase 3: Documentation Updates**
1. Update `command-reference.md` with new names and fix ARCHIVED notes
2. Update `directory-protocols.md` command listings
3. Update `command-authoring-standards.md` reference commands
4. Update `commands/README.md` examples and cross-references

**Phase 4: Test File Updates**
1. Update test file arrays and assertions
2. Rename test files if named after commands (e.g., `test_subprocess_isolation_research_plan.sh`)

### 2. Handle Archive Conflicts

**DO NOT delete or modify archived commands.** Instead:
1. Update `/home/benjamin/.config/.claude/archive/legacy-workflow-commands/README.md` to clarify:
   - Archived commands are superseded by the renamed active commands
   - Add date and reason for the naming change
   - Update migration guidance

### 3. Clean-Break Implementation

Following the project's clean-break approach:
- No backward compatibility aliases
- No redirects from old names to new names
- Clear documentation of the change
- Historical spec artifacts remain unchanged

### 4. Verification Steps

After implementation:
1. Run `grep -r "/fix\b\|/research-plan\b\|/research-report\b\|/research-revise\b" .claude/` to find remaining references
2. Exclude `specs/` and `archive/` from grep (historical records)
3. Run all test files to verify functionality
4. Test each command with actual invocation

### 5. Documentation Update Pattern

For each documentation file:
- Search and replace command names
- Update any section headings
- Update cross-reference links
- Verify markdown link targets still resolve

## References

### Primary Command Files
- `/home/benjamin/.config/.claude/commands/fix.md` (~608 lines)
- `/home/benjamin/.config/.claude/commands/research-plan.md` (~497 lines)
- `/home/benjamin/.config/.claude/commands/research-report.md` (~362 lines)
- `/home/benjamin/.config/.claude/commands/research-revise.md` (~491 lines)

### Documentation Files
- `/home/benjamin/.config/.claude/docs/reference/command-reference.md:28-611`
- `/home/benjamin/.config/.claude/docs/guides/research-plan-command-guide.md:1-429`
- `/home/benjamin/.config/.claude/docs/guides/research-report-command-guide.md:1-391`
- `/home/benjamin/.config/.claude/docs/guides/research-revise-command-guide.md:1-400+`
- `/home/benjamin/.config/.claude/docs/guides/fix-command-guide.md:38`
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md:130-132`
- `/home/benjamin/.config/.claude/docs/reference/command-authoring-standards.md:456`
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:403`

### Test Files
- `/home/benjamin/.config/.claude/tests/test_compliance_remediation_phase7.sh:20-23`
- `/home/benjamin/.config/.claude/tests/test_subprocess_isolation_research_plan.sh:3,36`
- `/home/benjamin/.config/.claude/tests/test_command_topic_allocation.sh:53-150`

### Archive Files (Read-only)
- `/home/benjamin/.config/.claude/archive/legacy-workflow-commands/README.md:13-74`
- `/home/benjamin/.config/.claude/archive/legacy-workflow-commands/commands/debug.md`
- `/home/benjamin/.config/.claude/archive/legacy-workflow-commands/commands/plan.md`
- `/home/benjamin/.config/.claude/archive/legacy-workflow-commands/commands/research.md`
- `/home/benjamin/.config/.claude/archive/legacy-workflow-commands/commands/revise.md`

### Commands README
- `/home/benjamin/.config/.claude/commands/README.md:80,350,354,358,397,400,456,469,647-698`

### Agent Files
- `/home/benjamin/.config/.claude/agents/workflow-classifier.md:82`

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001_rename_fix_to_debug_research_plan_to_pla_plan.md](../plans/001_rename_fix_to_debug_research_plan_to_pla_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-17
