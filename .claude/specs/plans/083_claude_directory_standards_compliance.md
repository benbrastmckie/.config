# .claude/ Directory Standards Compliance Refactor

## Metadata
- **Date**: 2025-10-23
- **Feature**: Comprehensive standards compliance refactor for .claude/ directory
- **Scope**: Commands, libraries, documentation, templates - 8 distinct compliance improvements
- **Estimated Phases**: 8
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: None (audit findings from parallel research agents)

## Overview

This plan addresses eight categories of standards compliance issues discovered through comprehensive audit of the .claude/ directory structure:

1. **Command Language Compliance**: Transform weak imperative language (should/may/can) to strong imperatives (MUST/WILL/SHALL) across 21 command files, raising compliance from 70% to 90%+ target
2. **Phase 0 Role Clarification**: Add explicit orchestrator/executor role framing to commands lacking this critical pattern
3. **Library Error Handling**: Standardize bash strict mode (`set -euo pipefail`) across 14 library scripts currently lacking consistent error handling
4. **Documentation Cross-References**: Fix 19 broken links referencing non-existent files (creating-commands.md → command-development-guide.md)
5. **Legacy File Cleanup**: Remove 85KB+ of unused legacy/tmp files
6. **Documentation Gaps**: Add missing troubleshooting/README.md
7. **CLAUDE.md Accuracy**: Correct template category count (11 → 8) and remove shared/ directory references
8. **Agent Template Completeness**: Ensure all Task invocations include complete prompts rather than external references

## Success Criteria
- [ ] Imperative language ratio ≥90% across all command files
- [ ] All orchestrator commands have Phase 0 role clarification
- [ ] All library scripts use strict error handling (`set -euo pipefail`)
- [ ] Zero broken cross-references in documentation
- [ ] Legacy/tmp files removed, disk space recovered
- [ ] All documentation directories have README.md files
- [ ] CLAUDE.md accurately reflects actual directory structure
- [ ] All Task invocations include complete, executable prompts
- [ ] All tests pass after refactoring
- [ ] No functionality regressions

## Technical Design

### Architecture Decisions

**Incremental Approach**: Each phase targets a specific compliance category, allowing for:
- Independent testing of each improvement
- Easy rollback if issues arise
- Gradual validation of changes
- Atomic git commits per category

**Automated Detection**: Use existing audit utilities where available:
- `.claude/lib/tmp/detect_weak_language.sh` for imperative language detection
- Bash syntax validation for error handling verification
- Link checker for cross-reference validation

**Standards Enforcement**: Follow established patterns from:
- `.claude/docs/reference/command_architecture_standards.md` (Standards 0-5)
- `.claude/docs/guides/imperative-language-guide.md` (transformation rules)
- `.claude/docs/concepts/writing-standards.md` (documentation guidelines)

### Risk Mitigation

**Testing Strategy**: Run comprehensive test suite after each phase:
```bash
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh
```

**Backup Strategy**: Git commits after each phase enable easy rollback

**Validation Checkpoints**: Each phase includes verification step before proceeding

## Implementation Phases

### Phase 1: Command Imperative Language Transformation
**Objective**: Transform weak imperative language (should/may/can) to strong imperatives (MUST/WILL/SHALL) in command files, raising compliance from 70% to 90%+
**Complexity**: Medium
**Files Modified**: 21 command files in .claude/commands/

**Priority Files** (highest weak language counts):
- orchestrate.md (11 instances)
- setup.md (9 instances)
- debug.md (8 instances)
- plan.md (8 instances)

Tasks:
- [ ] Run audit script to generate baseline metrics: `.claude/lib/tmp/detect_weak_language.sh .claude/commands/`
- [ ] Read imperative language transformation guide: `.claude/docs/guides/imperative-language-guide.md`
- [ ] Transform setup.md (9 should/may/can → MUST/WILL/SHALL)
- [ ] Transform debug.md (8 instances)
- [ ] Transform plan.md (8 instances)
- [ ] Transform orchestrate.md (11 instances)
- [ ] Transform remaining commands with <8 instances (17 files)
- [ ] Verify transformation preserves command functionality (spot check 5 commands)
- [ ] Run audit script to verify ≥90% imperative ratio
- [ ] Run test suite: `.claude/tests/run_all_tests.sh`

**Transformation Examples**:
- "should verify" → "MUST verify"
- "may need to" → "WILL need to"
- "can be used" → "SHALL be used" (for requirements)
- "you should" → "you MUST"

Testing:
```bash
# Verify transformation
cd /home/benjamin/.config/.claude
./lib/tmp/detect_weak_language.sh commands/ > phase1_metrics.txt

# Expected: ≥90% imperative ratio
# Run full test suite
cd tests && ./run_all_tests.sh
```

### Phase 2: Add Phase 0 Role Clarification to Orchestrator Commands
**Objective**: Add explicit "YOU are the ORCHESTRATOR/EXECUTOR" framing to commands lacking Phase 0 role clarification
**Complexity**: Low
**Files Modified**: 5-7 command files lacking role clarification

Tasks:
- [ ] Identify commands lacking Phase 0 role clarification (orchestrator commands without explicit role framing)
- [ ] Review exemplar implementations: orchestrate.md:40-43, implement.md:11-69, report.md:13-18
- [ ] Create reusable Phase 0 template based on standards
- [ ] Add Phase 0 block to plan.md
- [ ] Add Phase 0 block to debug.md
- [ ] Add Phase 0 block to document.md
- [ ] Add Phase 0 block to test-all.md
- [ ] Add Phase 0 block to setup.md (if applicable)
- [ ] Verify role framing clarity (manual review)
- [ ] Run test suite to ensure no regressions

**Phase 0 Template Structure**:
```markdown
## Role Clarification

YOU are the [ORCHESTRATOR|EXECUTOR|SPECIALIST] for this command.

Your responsibilities:
- [Primary responsibility 1]
- [Primary responsibility 2]
- [Delegation authority if applicable]

You MUST NOT:
- [Anti-pattern 1]
- [Anti-pattern 2]
```

Testing:
```bash
# Verify Phase 0 blocks present
grep -l "Role Clarification" .claude/commands/*.md | wc -l
# Expected: 10+ files

cd /home/benjamin/.config/.claude/tests && ./run_all_tests.sh
```

### Phase 3: Standardize Library Error Handling
**Objective**: Add strict bash mode (`set -euo pipefail`) to 14 library scripts lacking consistent error handling
**Complexity**: Medium
**Files Modified**: 14 library scripts in .claude/lib/

Tasks:
- [ ] Identify 14 library scripts lacking strict mode (3 use `set -e` only, 11 use neither)
- [ ] Read error handling standards: `.claude/docs/reference/command_architecture_standards.md`
- [ ] Review exemplar implementation: `.claude/lib/error-handling.sh`
- [ ] Add `set -euo pipefail` to scripts using `set -e` only (3 files)
- [ ] Add `set -euo pipefail` to scripts using neither (11 files)
- [ ] Verify no undefined variables exist in updated scripts (pipefail will catch)
- [ ] Test each modified script individually
- [ ] Run full test suite (50 test files)
- [ ] Verify no test failures due to stricter error handling

**Target Scripts** (identified during audit):
- Files in `.claude/lib/` without `set -euo pipefail` at top
- Exclude scripts that intentionally need looser error handling (document exceptions)

**Error Handling Template**:
```bash
#!/usr/bin/env bash
set -euo pipefail

# [Script description]
# [Usage information]
```

Testing:
```bash
# Verify strict mode added
grep -l "set -euo pipefail" .claude/lib/*.sh | wc -l
# Expected: 61+ files (47 existing + 14 new)

# Run comprehensive test suite
cd /home/benjamin/.config/.claude/tests && ./run_all_tests.sh
```

### Phase 4: Fix Documentation Cross-References
**Objective**: Fix 19 broken links referencing non-existent creating-commands.md and creating-agents.md files
**Complexity**: Low
**Files Modified**: 19 documentation files

Tasks:
- [ ] Identify all 19 files with broken references using grep
- [ ] Verify correct target filenames: command-development-guide.md, agent-development-guide.md
- [ ] Search and replace: creating-commands.md → command-development-guide.md (all files)
- [ ] Search and replace: creating-agents.md → agent-development-guide.md (all files)
- [ ] Verify all links now resolve correctly (spot check 5 random files)
- [ ] Check for any other broken links using link checker
- [ ] Update any relative path issues if found
- [ ] Run documentation validation

**Search Pattern**:
```bash
# Find broken references
grep -r "creating-commands.md" .claude/docs/
grep -r "creating-agents.md" .claude/docs/
```

**Replacement**:
- `creating-commands.md` → `command-development-guide.md`
- `creating-agents.md` → `agent-development-guide.md`

Testing:
```bash
# Verify no broken references remain
cd /home/benjamin/.config/.claude/docs
! grep -r "creating-commands.md" .
! grep -r "creating-agents.md" .

# Verify correct references exist
grep -r "command-development-guide.md" . | wc -l  # Expected: 19+
grep -r "agent-development-guide.md" . | wc -l    # Expected: 19+
```

### Phase 5: Clean Up Legacy and Temporary Files
**Objective**: Remove 85KB+ of unused legacy/tmp files to clean up repository
**Complexity**: Low
**Files Removed**: artifact-operations-legacy.sh, selective tmp/ directory contents

Tasks:
- [ ] Verify artifact-operations-legacy.sh is truly unused (grep for references)
- [ ] Verify tmp/ utilities are temporary and not referenced in commands
- [ ] Remove artifact-operations-legacy.sh (85KB)
- [ ] Review tmp/ directory contents (2 utility scripts + 4 test directories)
- [ ] Determine which tmp/ files are safe to remove (mark permanent utilities)
- [ ] Remove temporary scripts from tmp/ (keep detect_weak_language.sh if needed)
- [ ] Remove temporary test directories from tmp/
- [ ] Update .claude/lib/README.md to reflect removals
- [ ] Verify no broken references after removal
- [ ] Measure disk space recovered

**Files to Review**:
```
.claude/lib/artifact-operations-legacy.sh (85KB)
.claude/lib/tmp/detect_weak_language.sh (utility - keep?)
.claude/lib/tmp/ (test directories - remove if obsolete)
```

**Safety Check**:
```bash
# Check for references to legacy file
grep -r "artifact-operations-legacy" /home/benjamin/.config/.claude/

# Check for references to tmp utilities
grep -r "tmp/detect_weak_language" /home/benjamin/.config/.claude/
```

Testing:
```bash
# Verify files removed
! test -f /home/benjamin/.config/.claude/lib/artifact-operations-legacy.sh

# Verify no broken references
cd /home/benjamin/.config/.claude
grep -r "artifact-operations-legacy" . || echo "No references found (good)"

# Run test suite
cd tests && ./run_all_tests.sh
```

### Phase 6: Add Missing Documentation READMEs
**Objective**: Add README.md to troubleshooting/ directory (only directory missing README)
**Complexity**: Low
**Files Created**: 1 README file

Tasks:
- [ ] Review existing troubleshooting guides in .claude/docs/troubleshooting/
- [ ] Check exemplar README structure from other docs directories
- [ ] Create troubleshooting/README.md following documentation standards
- [ ] Include: purpose, guide index, navigation links
- [ ] Follow CommonMark specification
- [ ] Use present-focused language (no historical markers)
- [ ] Link from main docs README.md
- [ ] Verify all 8 documentation directories now have READMEs

**README.md Template**:
```markdown
# Troubleshooting Guides

This directory contains troubleshooting guides for common issues in the .claude/ workflow system.

## Purpose
Provide step-by-step solutions for errors, misconfigurations, and unexpected behaviors.

## Available Guides
- [Guide 1](guide1.md) - Description
- [Guide 2](guide2.md) - Description

## Navigation
- [Back to Documentation Index](../README.md)
```

Testing:
```bash
# Verify all directories have READMEs
cd /home/benjamin/.config/.claude/docs
for dir in */; do
  if [[ ! -f "$dir/README.md" ]]; then
    echo "Missing README in $dir"
  fi
done
# Expected: No output (all READMEs present)
```

### Phase 7: Update CLAUDE.md for Accuracy
**Objective**: Correct template category count (11 → 8) and remove shared/ directory references
**Complexity**: Low
**Files Modified**: /home/benjamin/.config/CLAUDE.md

Tasks:
- [ ] Read current CLAUDE.md project_commands section
- [ ] Locate "11 categories" claim for templates
- [ ] Verify actual template categories: backend, debugging, documentation, feature, migration, refactoring, research, testing (8 total)
- [ ] Update "11 categories" → "8 categories" with actual list
- [ ] Search for any references to shared/ directory
- [ ] Remove or correct shared/ directory references (directory does not exist)
- [ ] Verify no other inaccuracies in CLAUDE.md
- [ ] Test that CLAUDE.md still renders correctly
- [ ] Verify cross-references to other files still valid

**Changes Required**:
- Template categories: 11 → 8
- List actual categories: backend, debugging, documentation, feature, migration, refactoring, research, testing
- Remove references to non-existent shared/ directory

Testing:
```bash
# Verify changes made
grep -c "8 categories" /home/benjamin/.config/CLAUDE.md  # Expected: 1+
! grep "11 categories" /home/benjamin/.config/CLAUDE.md
! grep "shared/" /home/benjamin/.config/CLAUDE.md || echo "Check if references are appropriate"
```

### Phase 8: Ensure Complete Agent Templates in Commands
**Objective**: Ensure all Task invocations in command files include complete, executable prompts rather than external references
**Complexity**: Medium
**Files Modified**: Commands with incomplete agent templates (5 instances in orchestrate.md identified)

Tasks:
- [ ] Search all command files for Task tool invocations (grep pattern: `subagent_type:`)
- [ ] Identify Task invocations with external references ("see [file]" pattern)
- [ ] Review Command Architecture Standards Standard 4 (Template Completeness)
- [ ] For each incomplete Task invocation:
  - [ ] Read referenced external file
  - [ ] Inline complete prompt into command file
  - [ ] Preserve original external file (keep as reference)
  - [ ] Verify prompt is executable and self-contained
- [ ] Review orchestrate.md Task invocations (44 total, 5 with external refs)
- [ ] Update orchestrate.md incomplete templates
- [ ] Review other commands for incomplete templates
- [ ] Verify all Task invocations now have complete prompts
- [ ] Test commands with updated templates

**Detection Pattern**:
```bash
# Find Task invocations
grep -n "subagent_type:" .claude/commands/*.md

# Find external references in prompts
grep -B5 -A5 "see \[.*\]" .claude/commands/*.md | grep -A5 "subagent_type:"
```

**Standard Requirement** (from Standard 4):
- Agent prompts MUST be complete and copy-paste ready
- NO "see [file]" references that require external lookups
- Templates MUST include all context needed for execution

Testing:
```bash
# Verify no external references in Task prompts
cd /home/benjamin/.config/.claude/commands
! grep -A10 "subagent_type:" *.md | grep "see \[.*\.md\]"

# Run test suite
cd /home/benjamin/.config/.claude/tests && ./run_all_tests.sh
```

## Testing Strategy

### Per-Phase Testing
Each phase includes specific testing steps:
1. Syntax validation (bash -n for scripts, markdown linting for docs)
2. Functional testing (spot checks for modified files)
3. Comprehensive test suite run (.claude/tests/run_all_tests.sh)
4. No regression validation

### Final Integration Testing
After all phases complete:
```bash
# Full test suite
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh

# Metrics verification
cd /home/benjamin/.config/.claude

# 1. Imperative language ratio
./lib/tmp/detect_weak_language.sh commands/ | tail -5

# 2. Error handling compliance
grep -l "set -euo pipefail" lib/*.sh | wc -l  # Expected: 61+

# 3. Documentation cross-references
! grep -r "creating-commands.md" docs/
! grep -r "creating-agents.md" docs/

# 4. README coverage
for dir in docs/*/; do [[ -f "$dir/README.md" ]] || echo "Missing: $dir"; done

# 5. CLAUDE.md accuracy
grep -q "8 categories" /home/benjamin/.config/CLAUDE.md
! grep "11 categories" /home/benjamin/.config/CLAUDE.md

# 6. Template completeness
! grep -A10 "subagent_type:" commands/*.md | grep "see \[.*\.md\]"
```

### Test Coverage Requirements
- All existing tests MUST pass (50 test files in .claude/tests/)
- No new test failures introduced
- Spot checks for 5-7 modified files per phase
- Validation scripts run successfully

## Documentation Requirements

### Updated Documentation
- [ ] .claude/lib/README.md - Reflect library file removals
- [ ] .claude/docs/troubleshooting/README.md - Create new
- [ ] .claude/templates/README.md - Verify category list accuracy
- [ ] CLAUDE.md - Update template category count and remove shared/ references

### Audit Report
Create compliance audit report documenting:
- Initial compliance state (70% imperative, 14 scripts without strict mode, etc.)
- Changes made per phase
- Final compliance state (90%+ imperative, all scripts with strict mode, etc.)
- Testing results
- Disk space recovered

**Report Location**: `.claude/specs/reports/083_standards_compliance_audit.md`

## Dependencies

### Prerequisites
- Bash 4.0+ for library scripts
- Test suite access (.claude/tests/run_all_tests.sh)
- Audit utilities (.claude/lib/tmp/detect_weak_language.sh)

### External Dependencies
- ShellCheck (for bash validation) - NOT INSTALLED (Phase 3 can proceed without it, but recommended for future)
- Markdown linter (optional, for docs validation)

## Risk Assessment

### Low Risk
- Phases 4, 5, 6, 7: Documentation and cleanup changes
- Easily reversible via git
- No functional impact on commands/libraries

### Medium Risk
- Phases 1, 2, 8: Command file modifications
- Risk: Changing command logic unintentionally
- Mitigation: Careful manual review, comprehensive testing

- Phase 3: Library error handling
- Risk: Strict mode may expose existing bugs
- Mitigation: Test each script individually, fix issues found

### Rollback Strategy
Each phase creates atomic git commit:
```bash
# If issue found in Phase N
git revert HEAD  # Revert last phase
# Or
git reset --hard <commit-before-phase-N>
```

## Notes

### Estimated Effort
- Phase 1 (Imperative Language): 2-3 hours (21 files, ~92 transformations)
- Phase 2 (Role Clarification): 30-45 minutes (5-7 files, template-based)
- Phase 3 (Error Handling): 1-2 hours (14 files, testing critical)
- Phase 4 (Cross-References): 15-20 minutes (search/replace)
- Phase 5 (Cleanup): 20-30 minutes (verification + removal)
- Phase 6 (README): 15-20 minutes (single file creation)
- Phase 7 (CLAUDE.md): 10-15 minutes (simple corrections)
- Phase 8 (Agent Templates): 1-2 hours (5+ templates to inline)

**Total Estimated Effort**: 6-10 hours

### Standards References
- [Command Architecture Standards](.claude/docs/reference/command_architecture_standards.md)
- [Imperative Language Guide](.claude/docs/guides/imperative-language-guide.md)
- [Writing Standards](.claude/docs/concepts/writing-standards.md)
- [Command Development Guide](.claude/docs/guides/command-development-guide.md)

### Success Metrics
- Imperative language ratio: 70% → 90%+
- Error handling coverage: 47/61 files → 61/61 files
- Documentation cross-reference integrity: 19 broken → 0 broken
- Disk space recovered: 85KB+ from legacy files
- README coverage: 7/8 directories → 8/8 directories
- CLAUDE.md accuracy: 100% (category count, directory references)
- Agent template completeness: 100% (no external references in Task invocations)

### Prioritization
If time constrained, execute phases in this order:
1. **Phase 3** (Error Handling) - Functional robustness
2. **Phase 1** (Imperative Language) - Standards enforcement
3. **Phase 4** (Cross-References) - Documentation integrity
4. **Phase 8** (Agent Templates) - Command reliability
5. **Phase 2** (Role Clarification) - Command clarity
6. **Phase 5** (Cleanup) - Repository hygiene
7. **Phase 7** (CLAUDE.md) - Documentation accuracy
8. **Phase 6** (README) - Documentation completeness
