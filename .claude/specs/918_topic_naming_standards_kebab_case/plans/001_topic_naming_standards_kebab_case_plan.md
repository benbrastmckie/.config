# Topic Naming Standards: Uniform LLM Naming with Kebab-Case Files

## Metadata
- **Date**: 2025-11-21
- **Feature**: Uniform LLM Topic Naming and Kebab-Case File Naming
- **Scope**: Add topic-naming-agent to all directory-creating commands, migrate file naming to kebab-case, remove backward compatibility
- **Estimated Phases**: 4
- **Estimated Hours**: 12
- **Complexity Score**: 95 (refactor=5 + 25 tasks/2 + 15 files*3 + 7 integrations*5)
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Research Reports**:
  - [Topic Naming Kebab-Case Standards Research](../reports/001_topic_naming_kebab_case_standards.md)
  - [Plan Revision Insights: Directory vs File Naming](../reports/001_plan_revision_insights.md)
  - [Plan Revision Insights: Uniform LLM Naming](../reports/002_plan_revision_insights.md)
  - [Plan Revision Insights: NNN_no_name_error/ Fallback](../reports/003_plan_revision_llm_failure_fallback.md)

## Overview

This plan implements two key standardizations with a clean-break approach (no backward compatibility):

1. **Uniform LLM Naming**: All 7 directory-creating commands use topic-naming-agent
   - Already integrated: /research, /plan, /debug, /optimize-claude (4 commands)
   - Needs integration: /errors, /setup, /repair (3 commands)

2. **Kebab-Case File Naming**: Files use hyphens, directories use underscores
   - Directories: `918_topic_naming_standards/` (snake_case - UNCHANGED)
   - Files: `001-topic-naming-plan.md` (kebab-case - NEW)

**Simplified Fallback Approach**:
- When LLM fails to generate a valid topic name, use format: `NNN_no_name_error/`
- NO complex sanitization logic - just a static fallback string
- Clear failure signaling - directory name clearly indicates LLM failure
- Scripts exist to detect and rename `*_no_name_error` directories post-hoc

**Clean-Break Approach**:
- NO dual-format pattern support (e.g., no `[-_]` patterns)
- NO legacy file detection or migration
- NO backward compatibility comments
- Simple, single format going forward

## Research Summary

**From 001_topic_naming_kebab_case_standards.md**:
- 4 commands already use topic-naming-agent with fallback to "no_name"
- 3 commands use fallback-only slug generation (bypass LLM)
- Fallback sanitization exists in `validate_topic_directory_slug()` but is being replaced with simpler approach

**From 001_plan_revision_insights.md**:
- User clarification: Directories=snake_case (keep), Files=kebab-case (change)
- File naming construction in: plan.md (line 814), repair.md (line 524), debug.md (line 947)
- Report filename in: research-specialist.md (line 480)

**From 002_plan_revision_insights.md**:
- /errors, /setup, /repair need LLM naming integration (~145 lines each)
- Template pattern available from /plan command (lines 245-501)
- Backward compatibility code to remove in: argument-capture.sh, state-persistence.sh, workflow-initialization.sh

**From 003_plan_revision_llm_failure_fallback.md**:
- Current "no_name" fallback locations in 4 commands: plan.md:443, research.md:320, debug.md:444, optimize-claude.md:269
- Change from `"no_name"` to `"no_name_error"` clearly communicates failure state
- Simplification removes conditional fallback logic - no sanitization needed
- Update scripts: check_no_name_directories.sh and rename_no_name_directory.sh patterns

## Success Criteria

- [ ] All 7 directory-creating commands invoke topic-naming-agent for semantic naming
- [ ] /errors command uses LLM naming with `no_name_error` fallback
- [ ] /setup command uses LLM naming with `no_name_error` fallback (analyze mode)
- [ ] /repair command uses LLM naming with `no_name_error` fallback
- [ ] All existing commands use `no_name_error` fallback instead of `no_name`
- [ ] All new plan files use kebab-case format: `NNN-topic-name-plan.md`
- [ ] All new report files use kebab-case format: `NNN-report-name.md`
- [ ] All new debug files use kebab-case format: `NNN-debug-strategy.md`
- [ ] Directory naming unchanged (snake_case with underscores)
- [ ] No dual-format patterns exist in codebase (clean-break)
- [ ] No legacy file handling code exists (clean-break)
- [ ] No sanitization fallback logic exists (simplified approach)
- [ ] Detection scripts updated to match `*_no_name_error` pattern
- [ ] Documentation updated with uniform LLM naming list

## Technical Design

### Naming Convention Architecture

| Component | Format | Example |
|-----------|--------|---------|
| Topic Directory (LLM success) | snake_case | `918_topic_naming_standards/` |
| Topic Directory (LLM failure) | static fallback | `919_no_name_error/` |
| Plan File | kebab-case | `001-topic-naming-plan.md` |
| Report File | kebab-case | `001-research-analysis.md` |
| Summary File | kebab-case | `001-implementation-summary.md` |
| Debug File | kebab-case | `001-debug-strategy.md` |

### LLM Naming Pattern (Template from /plan)

All 7 commands follow this pattern:
```
1. Prepare input file with user prompt
2. Invoke topic-naming-agent via Task tool
3. Validate output (5-40 chars, snake_case)
4. On failure: use "no_name_error" static fallback (NOT sanitization)
5. Continue with validated topic name
```

### Simplified Fallback Approach (Replaces Sanitization)

When LLM fails, use static `"no_name_error"` string:
```bash
# BEFORE (complex sanitization - REMOVED):
# topic_slug=$(echo "$workflow_description" | tr '[:upper:]' '[:lower:]' |
#              tr ' ' '_' | sed 's/[^a-z0-9_]//g' | cut -c1-40)

# AFTER (simple static fallback):
TOPIC_NAME="no_name_error"
```

This produces directories like `920_no_name_error/` that clearly signal LLM failure.

### File Naming Conversion

When constructing filenames from snake_case topic names:
```bash
# Topic name: jwt_token_fix (snake_case for directory)
# File slug: jwt-token-fix (kebab-case for filename)
FILE_SLUG=$(echo "$TOPIC_NAME" | tr '_' '-')
PLAN_FILENAME="${PLAN_NUMBER}-${FILE_SLUG}-plan.md"
```

## Implementation Phases

### Phase 1: Add LLM Naming to Missing Commands [COMPLETE]
dependencies: []

**Objective**: Integrate topic-naming-agent into /errors, /setup, /repair commands with `no_name_error` fallback
**Complexity**: Medium
**Risk**: Low (proven pattern from existing commands)

Tasks:
- [x] Add topic-naming-agent integration to `/errors` command (file: .claude/commands/errors.md)
  - Insert Task block before current line 231
  - Copy pattern from /plan command lines 245-282
  - Add output validation with retry logic
  - Use `"no_name_error"` as fallback (NOT sanitization)
- [x] Add topic-naming-agent integration to `/repair` command (file: .claude/commands/repair.md)
  - Insert Task block before current line 189
  - Copy pattern from /plan command lines 245-282
  - Add output validation with retry logic
  - Use `"no_name_error"` as fallback (NOT sanitization)
- [x] Add topic-naming-agent integration to `/setup` command (file: .claude/commands/setup.md)
  - Insert Task block in analyze mode section (before line 109)
  - Only invoke for analyze mode, not initialization mode
  - Copy pattern from /plan command lines 245-282
  - Add output validation with retry logic
  - Use `"no_name_error"` as fallback (NOT sanitization)

Testing:
```bash
# Test /errors with LLM naming
/errors --since 1h --type validation_error
# Verify: Creates directory like 920_validation_error_analysis/ (LLM success)
# or 920_no_name_error/ (LLM failure - clear failure signaling)

# Test /repair with LLM naming
/repair --command /build --complexity 2
# Verify: Creates directory with semantic name from user description

# Test /setup analyze mode
/setup --force
# Verify: Creates directory with semantic name for analysis
```

**Expected Duration**: 4 hours

### Phase 2: Update Existing Commands to Use no_name_error Fallback [COMPLETE]
dependencies: [1]

**Objective**: Replace all "no_name" fallbacks with "no_name_error" in existing commands and update helper scripts
**Complexity**: Low
**Risk**: Low (string replacement)

Tasks:
- [x] Update `/plan` command fallback (file: .claude/commands/plan.md)
  - Line 343, 345, 443, 454, 471: Change `"no_name"` to `"no_name_error"`
  - Update any log messages to reference "no_name_error"
- [x] Update `/research` command fallback (file: .claude/commands/research.md)
  - Line 320, 331, 348, 359, 360: Change `"no_name"` to `"no_name_error"`
  - Update any log messages to reference "no_name_error"
- [x] Update `/debug` command fallback (file: .claude/commands/debug.md)
  - Line 444, 455, 472, 483, 484: Change `"no_name"` to `"no_name_error"`
  - Update any log messages to reference "no_name_error"
- [x] Update `/optimize-claude` command fallback (file: .claude/commands/optimize-claude.md)
  - Line 269, 280, 297, 308, 309: Change `"no_name"` to `"no_name_error"`
  - Update any log messages to reference "no_name_error"
- [x] Update check_no_name_directories.sh (file: .claude/scripts/check_no_name_directories.sh)
  - Line 89: Change pattern from `*_no_name` to `*_no_name_error`
- [x] Update rename_no_name_directory.sh (file: .claude/scripts/rename_no_name_directory.sh)
  - Line 70: Change `_no_name$` regex to `_no_name_error$`
  - Line 94: Change `sed 's/_no_name$//'` to `sed 's/_no_name_error$//'`
  - Update all messages referencing "no_name" to "no_name_error"

Testing:
```bash
# Verify no "no_name" literals remain (except documentation)
grep -rn '"no_name"' .claude/commands/ | grep -v "no_name_error"
# Should return empty (all changed to no_name_error)

# Verify scripts use new pattern
grep -n "no_name_error" .claude/scripts/check_no_name_directories.sh
grep -n "no_name_error" .claude/scripts/rename_no_name_directory.sh
# Should show updated patterns
```

**Expected Duration**: 2 hours

### Phase 3: Update File Naming to Kebab-Case and Remove Sanitization [COMPLETE]
dependencies: [1, 2]

**Objective**: Migrate file naming from snake_case to kebab-case and remove sanitization fallback logic
**Complexity**: Medium
**Risk**: Medium (ensure no regressions from removal)

Tasks:
- [x] Update `/plan` command filename construction (file: .claude/commands/plan.md, line 814)
  - Change: `PLAN_FILENAME="${PLAN_NUMBER}_$(echo "$TOPIC_NAME" | cut -c1-40)_plan.md"`
  - To: `PLAN_FILENAME="${PLAN_NUMBER}-$(echo "$TOPIC_NAME" | tr '_' '-' | cut -c1-40)-plan.md"`
- [x] Update `/repair` command filename construction (file: .claude/commands/repair.md, line 524)
  - Change: `PLAN_FILENAME="${PLAN_NUMBER}_$(echo "$TOPIC_NAME" | cut -c1-40)_plan.md"`
  - To: `PLAN_FILENAME="${PLAN_NUMBER}-$(echo "$TOPIC_NAME" | tr '_' '-' | cut -c1-40)-plan.md"`
- [x] Update `/debug` command filename construction (file: .claude/commands/debug.md, line 947)
  - Change: `PLAN_FILENAME="${PLAN_NUMBER}_debug_strategy.md"`
  - To: `PLAN_FILENAME="${PLAN_NUMBER}-debug-strategy.md"`
- [x] Update research-specialist.md report filename construction (file: .claude/agents/research-specialist.md, line 480)
  - Change: `REPORT_PATH="$TOPIC_DIR/${NEXT_NUM}_${report_name}.md"`
  - To: `REPORT_PATH="$TOPIC_DIR/${NEXT_NUM}-$(echo "$report_name" | tr '_' '-').md"`
- [x] Update plan path construction in workflow-initialization.sh (file: .claude/lib/workflow/workflow-initialization.sh, line 680)
  - Change: `local plan_path="${topic_path}/plans/001_${topic_name}_plan.md"`
  - To: `local plan_path="${topic_path}/plans/001-$(echo "${topic_name}" | tr '_' '-')-plan.md"`
- [x] Remove sanitization fallback logic in workflow-initialization.sh (file: .claude/lib/workflow/workflow-initialization.sh, lines 318-323)
  - Remove or simplify `validate_topic_directory_slug()` Tier 2 fallback
  - Commands now handle fallback with static "no_name_error" string
- [x] Remove dual-format path patterns in workflow-initialization.sh (file: .claude/lib/workflow/workflow-initialization.sh)
  - Line 95: Update path regex to single hyphen format for files
  - Lines 468-474: Remove backward compatibility comments
- [x] Update glob pattern in research-specialist.md (file: .claude/agents/research-specialist.md, line 476)
  - Change: `ls "$TOPIC_DIR"/[0-9][0-9][0-9]_*.md`
  - To: `ls "$TOPIC_DIR"/[0-9][0-9][0-9]-*.md` (single format, no dual support)

Testing:
```bash
# Verify plan.md changes
grep -n "PLAN_FILENAME" .claude/commands/plan.md
# Should show hyphen separators

# Verify no sanitization fallback remains
grep -n "tr '[:upper:]' '[:lower:]'" .claude/lib/workflow/workflow-initialization.sh
# Should return empty or only in other functions

# Verify no dual-format patterns remain
grep -r '\[-_\]' .claude/lib/ .claude/commands/ .claude/agents/
# Should return empty (no dual patterns)

# Run validation scripts
bash .claude/scripts/validate-all-standards.sh --all
```

**Expected Duration**: 3 hours

### Phase 4: Documentation and Cleanup [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Update documentation to reflect uniform LLM naming, no_name_error fallback, and kebab-case files
**Complexity**: Low
**Risk**: Low (documentation only)

Tasks:
- [x] Update topic-naming-with-llm.md to list all 7 commands (file: .claude/docs/guides/development/topic-naming-with-llm.md)
  - Add /errors, /setup, /repair to the list of commands using topic-naming-agent
  - Update command count from "4" to "7"
  - Document `no_name_error` fallback approach (replaces sanitization)
  - Add examples for new commands
- [x] Update directory-protocols.md to clarify naming (file: .claude/docs/concepts/directory-protocols.md)
  - Add section: "Directory vs File Naming Conventions"
  - Document: directories=snake_case, files=kebab-case
  - Document: LLM failure produces `NNN_no_name_error/` directories
  - Remove any references to sanitization fallback
- [x] Update CLAUDE.md directory protocols section (file: CLAUDE.md)
  - Update any file naming examples from `NNN_name.md` to `NNN-name.md`
  - Mention uniform LLM naming across 7 commands
  - Document `no_name_error` fallback behavior
- [x] Update topic-naming-agent.md fallback documentation (file: .claude/agents/topic-naming-agent.md, line 176)
  - Change: "fall back to 'no_name'" to "fall back to 'no_name_error'"
- [x] Update topic-utils.sh header comment (file: .claude/lib/plan/topic-utils.sh, line 16)
  - Change: "fall back to 'no_name'" to "fall back to 'no_name_error'"
- [x] Update agent examples in errors-analyst.md (file: .claude/agents/errors-analyst.md)
  - Change example: `001_error_report.md` to `001-error-report.md`
- [x] Update spec-updater.md filename examples (file: .claude/agents/spec-updater.md, line 357)
  - Change example: `001_report.md` to `001-report.md`
- [x] Update plan-architect.md plan file examples (file: .claude/agents/plan-architect.md)
  - Change examples to use kebab-case filenames
- [x] Remove legacy argument file fallback (file: .claude/lib/workflow/argument-capture.sh)
  - Lines 131-145: Remove fallback to `${command_name}_arg.txt`
  - Lines 188-202: Remove cleanup of legacy temp files
- [x] Remove legacy state file warnings (file: .claude/lib/core/state-persistence.sh)
  - Lines 143-151: Remove warnings for `.claude/data/workflows/*.state`

Testing:
```bash
# Verify no snake_case file examples in docs
grep -rn "NNN_.*\.md" .claude/docs/ | grep -v "directory"
# Should return empty (no snake_case file examples)

# Verify all 7 commands mentioned in topic-naming docs
grep -c "/errors\|/setup\|/repair" .claude/docs/guides/development/topic-naming-with-llm.md
# Should be > 0 (all three mentioned)

# Verify kebab-case examples in place
grep -rn "NNN-.*\.md" .claude/docs/ | head -5
# Should show kebab-case file examples

# Verify no_name_error documented
grep -rn "no_name_error" .claude/docs/ .claude/agents/
# Should show updated documentation

# Verify no legacy file handling
grep -rn "backward compat" .claude/lib/
# Should return empty
```

**Expected Duration**: 3 hours

## Testing Strategy

### Unit Tests
- Test topic-naming-agent invocation in /errors, /setup, /repair
- Test `no_name_error` fallback produces clear failure directories
- Test kebab-case filename construction
- Test path patterns match only new format (no dual patterns)

### Integration Tests
- Run /errors and verify semantic topic directory created (or no_name_error on failure)
- Run /repair and verify semantic topic directory created (or no_name_error on failure)
- Run /setup --force and verify semantic topic directory created (or no_name_error on failure)
- Run /plan and verify kebab-case filename produced
- Run /debug and verify kebab-case filename produced
- Verify /build can operate on new kebab-case plan files

### Clean-Break Verification
- Confirm no `[-_]` dual patterns exist
- Confirm no sanitization fallback logic exists (replaced by static no_name_error)
- Confirm no legacy file handling code exists
- Confirm no backward compatibility comments exist

### Failure Signaling Verification
- Simulate LLM failure and verify `NNN_no_name_error/` directory created
- Verify `check_no_name_directories.sh` detects `*_no_name_error` directories
- Verify `rename_no_name_directory.sh` can rename `*_no_name_error` directories

## Documentation Requirements

### Updates Required
- `docs/guides/development/topic-naming-with-llm.md`: Add all 7 commands, document no_name_error fallback
- `docs/concepts/directory-protocols.md`: Directory vs file naming section, no_name_error behavior
- CLAUDE.md: Update file naming examples
- Agent files: Update filename examples and fallback documentation

### Key Documentation Points
- All 7 directory-creating commands use topic-naming-agent
- LLM failure produces `NNN_no_name_error/` (NOT sanitized names)
- Directories: snake_case with underscores
- Files: kebab-case with hyphens
- No backward compatibility (clean-break)
- Scripts available to detect and rename `*_no_name_error` directories

## Dependencies

### Prerequisites
- Research reports reviewed and analyzed (DONE)
- User clarification obtained (DONE - no_name_error fallback, directories=snake_case, files=kebab-case, clean-break)

### External Dependencies
- None (self-contained within .claude/ system)

### Cross-Phase Dependencies
- Phase 2 depends on Phase 1 (new commands use consistent fallback pattern)
- Phase 3 depends on Phases 1-2 (file naming and cleanup after fallback pattern established)
- Phase 4 depends on Phases 1-3 (documentation reflects final implementation)

## Risk Mitigation

### Risk: LLM Naming Adds Latency to /errors, /setup, /repair
**Mitigation**: LLM naming adds ~3s but provides significant discoverability benefit; `no_name_error` fallback prevents blocking on LLM failures

### Risk: Breaking Existing Workflows (Clean-Break)
**Mitigation**: Phase 3 is explicit about what gets removed; test each removal individually

### Risk: Unclear Failure State with Sanitization
**Mitigation**: `no_name_error` fallback clearly signals LLM failure vs sanitized approximation; scripts help detect and correct

### Risk: Inconsistent Filename Format During Transition
**Mitigation**: Phase 3 removes dual-format support AFTER new format is working

## Rollback Strategy

If issues discovered post-implementation:
1. Revert LLM naming additions to /errors, /setup, /repair
2. Revert `no_name_error` fallback changes (restore `no_name`)
3. Revert kebab-case filename changes
4. Restore backward compatibility code from backup
5. Note: Clean-break means no coexistence period, so rollback requires full revert

## Implementation Notes

### Final State After Implementation

```
.claude/specs/
  920_validation_error_analysis/     # Directory: snake_case (semantic from LLM)
    reports/
      001-error-analysis-report.md   # File: kebab-case
    plans/
      001-error-fix-plan.md          # File: kebab-case

  921_no_name_error/                 # Directory: snake_case (LLM failure - CLEAR SIGNALING)
    reports/
      001-no-name-error-report.md    # File: kebab-case
    plans/
      001-no-name-error-plan.md      # File: kebab-case

All 7 commands:
  /research       - LLM naming + no_name_error fallback
  /plan           - LLM naming + no_name_error fallback
  /debug          - LLM naming + no_name_error fallback
  /optimize-claude - LLM naming + no_name_error fallback
  /errors         - LLM naming + no_name_error fallback (NEW)
  /setup          - LLM naming + no_name_error fallback (NEW)
  /repair         - LLM naming + no_name_error fallback (NEW)
```

### Key Principles

**Uniform naming** across all directory-creating commands via topic-naming-agent.

**Simple failure fallback** using static `"no_name_error"` string - no complex sanitization.

**Clear failure signaling** - directory name `NNN_no_name_error/` immediately identifies LLM failure, prompting manual intervention.

**Post-hoc correction** - scripts available to detect and rename `*_no_name_error` directories to semantic names.

**Clean-break** means no legacy patterns, no dual-format support, simple single format.

### Comparison: Sanitization vs no_name_error Fallback

| Aspect | Sanitization Fallback (OLD) | no_name_error Fallback (NEW) |
|--------|---------------------------|------------------------------|
| Clarity | Unclear if name is LLM or sanitized | Immediately identifies failure |
| Code Complexity | 15+ lines of regex transforms | 1 static string |
| Predictability | Varies based on input | Always the same format |
| Searchability | Must compare with expected LLM format | Simple pattern match |
| Error Tracking | Requires strategy field inspection | Directory name is self-documenting |
| Human Action | Unclear if rename needed | Clearly signals manual intervention needed |
