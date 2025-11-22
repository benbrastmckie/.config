# Plan Revision Insights: Directory vs File Naming Convention Clarification

## Metadata
- **Date**: 2025-11-21
- **Agent**: research-specialist
- **Topic**: Plan revision for directory vs file naming convention clarification
- **Report Type**: codebase analysis
- **Original Plan**: /home/benjamin/.config/.claude/specs/918_topic_naming_standards_kebab_case/plans/001_topic_naming_standards_kebab_case_plan.md

## Executive Summary

The original plan incorrectly proposes migrating DIRECTORY naming from snake_case to kebab-case. However, the user's clarification specifies the OPPOSITE: directories should remain snake_case while FILES should use kebab-case. This report analyzes the current state, identifies what needs to change (file naming only), and provides specific revision guidance for the plan.

**Key Clarification**:
- **Directories**: Keep snake_case (current format) - e.g., `jwt_token_expiration_fix/`
- **Files**: Change to kebab-case (new requirement) - e.g., `jwt-token-expiration-fix-plan.md`

**Impact Assessment**:
- The original plan's scope INCREASES significantly for file naming
- The original plan's scope DECREASES significantly for directory naming (no changes needed)
- Changes affect plan files, report files, summary files, and debug files

## Findings

### 1. Current Naming Conventions Analysis

#### 1.1 Directory Naming (KEEP AS-IS)

Current format uses snake_case with numeric prefix. This should be PRESERVED per user request.

**Current Directory Examples** (from `/home/benjamin/.config/.claude/specs/`):
```
787_state_machine_persistence_bug/
788_commands_readme_update/
789_docs_standards_in_order_to_create_a_plan_to_fix/
882_no_name/
918_topic_naming_standards_kebab_case/
```

**Source of Directory Naming**:
- Topic-naming-agent generates directory names (lines 70-74 of topic-naming-agent.md)
- Validation regex: `^[a-z0-9_]{5,40}$` (line 104 of topic-naming-agent.md)
- NO CHANGES NEEDED for directory naming

#### 1.2 File Naming (NEEDS CHANGE TO KEBAB-CASE)

Current file format uses snake_case. User wants kebab-case for files.

**Current File Examples**:
```
# Plans (current snake_case)
001_state_machine_persistence_fix_plan.md
001_commands_readme_update_plan.md
001_skills_documentation_standards_update_plan.md

# Reports (current snake_case)
001_state_persistence_analysis.md
001_commands_directory_analysis.md
001_topic_naming_kebab_case_standards.md

# Summaries (current snake_case)
001_implementation_summary.md
```

**Target File Format (kebab-case)**:
```
# Plans (target kebab-case)
001-state-machine-persistence-fix-plan.md
001-commands-readme-update-plan.md
001-skills-documentation-standards-update-plan.md

# Reports (target kebab-case)
001-state-persistence-analysis.md
001-commands-directory-analysis.md
001-topic-naming-kebab-case-standards.md

# Summaries (target kebab-case)
001-implementation-summary.md
```

### 2. Files Affected by File Naming Change

#### 2.1 Plan File Generation

**Source**: `/home/benjamin/.config/.claude/commands/plan.md` (line 814)
```bash
PLAN_FILENAME="${PLAN_NUMBER}_$(echo "$TOPIC_NAME" | cut -c1-40)_plan.md"
```

**Required Change**:
```bash
# Convert underscores to hyphens for filename (keep TOPIC_NAME unchanged for directory)
PLAN_FILENAME="${PLAN_NUMBER}-$(echo "$TOPIC_NAME" | tr '_' '-' | cut -c1-40)-plan.md"
```

**Source**: `/home/benjamin/.config/.claude/commands/repair.md` (line 524)
```bash
PLAN_FILENAME="${PLAN_NUMBER}_$(echo "$TOPIC_NAME" | cut -c1-40)_plan.md"
```

**Required Change**:
```bash
PLAN_FILENAME="${PLAN_NUMBER}-$(echo "$TOPIC_NAME" | tr '_' '-' | cut -c1-40)-plan.md"
```

**Source**: `/home/benjamin/.config/.claude/commands/debug.md` (line 947-948)
```bash
PLAN_FILENAME="${PLAN_NUMBER}_debug_strategy.md"
```

**Required Change**:
```bash
PLAN_FILENAME="${PLAN_NUMBER}-debug-strategy.md"
```

#### 2.2 Report File Generation

**Source**: `/home/benjamin/.config/.claude/agents/research-specialist.md` (line 480)
```bash
REPORT_PATH="$TOPIC_DIR/${NEXT_NUM}_${report_name}.md"
```

**Required Change**:
```bash
REPORT_PATH="$TOPIC_DIR/${NEXT_NUM}-$(echo "$report_name" | tr '_' '-').md"
```

**Source**: `/home/benjamin/.config/.claude/agents/errors-analyst.md` (line 32)
```
# Example: REPORT_PATH="/home/user/.claude/specs/067_error_analysis/reports/001_error_report.md"
```

**Required Change** (example format):
```
# Example: REPORT_PATH="/home/user/.claude/specs/067_error_analysis/reports/001-error-report.md"
```

#### 2.3 Summary File Generation

Summary files follow similar patterns and need conversion from:
- `001_implementation_summary.md` to `001-implementation-summary.md`

#### 2.4 Debug File Generation

Debug report files need conversion from:
- `001_debug_report.md` to `001-debug-report.md`

### 3. Impact on Existing Infrastructure

#### 3.1 Path Extraction Functions

**Source**: `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` (lines 78-123)

The `extract_topic_from_plan_path()` function uses pattern:
```bash
# Expected: /path/to/specs/NNN_topic/plans/NNN_plan.md
```

**Required Update**: Support both old underscore and new hyphen file formats:
```bash
# Expected: /path/to/specs/NNN_topic/plans/NNN[-_]plan.md
```

#### 3.2 Plan File Construction

**Source**: `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` (line 680)
```bash
local plan_path="${topic_path}/plans/001_${topic_name}_plan.md"
```

**Required Change**:
```bash
# Convert topic_name underscores to hyphens for filename
local plan_filename=$(echo "${topic_name}" | tr '_' '-')
local plan_path="${topic_path}/plans/001-${plan_filename}-plan.md"
```

#### 3.3 Glob Patterns in Test Files

Test files using glob patterns like `*/plans/*_plan.md` will need updates to `*/plans/*-plan.md`.

### 4. What Does NOT Need to Change

Based on the user's clarification, these components should remain UNCHANGED:

| Component | Current Format | Action |
|-----------|---------------|--------|
| Topic directory names | `snake_case` | KEEP AS-IS |
| topic-naming-agent.md validation regex | `^[a-z0-9_]{5,40}$` | KEEP AS-IS |
| `validate_topic_name_format()` in topic-utils.sh | `^[a-z0-9_]{5,40}$` | KEEP AS-IS |
| Sanitization in workflow-initialization.sh | `tr ' ' '_'` | KEEP AS-IS |
| Directory protocol documentation | snake_case references | KEEP AS-IS |

### 5. Comparison: Original Plan vs Revised Scope

| Aspect | Original Plan Scope | Revised Scope |
|--------|---------------------|---------------|
| Directory naming | Change to kebab-case | NO CHANGE (keep snake_case) |
| File naming | Not addressed | CHANGE to kebab-case |
| topic-naming-agent.md | Update format to hyphens | NO CHANGE |
| topic-utils.sh validation | Update regex to hyphens | NO CHANGE |
| workflow-initialization.sh sanitization | Update to hyphens | NO CHANGE |
| Plan file generation (commands) | Not addressed | UPDATE filename construction |
| Report file generation (agents) | Not addressed | UPDATE filename construction |
| Path extraction patterns | Update to support both | UPDATE to support both file formats |

### 6. Files Requiring Modification

#### 6.1 Command Files (File Naming Updates)

| File | Line(s) | Change Required |
|------|---------|-----------------|
| `/home/benjamin/.config/.claude/commands/plan.md` | 814 | Change `_plan.md` to `-plan.md`, add underscore-to-hyphen conversion |
| `/home/benjamin/.config/.claude/commands/repair.md` | 524 | Change `_plan.md` to `-plan.md`, add underscore-to-hyphen conversion |
| `/home/benjamin/.config/.claude/commands/debug.md` | 947-948 | Change `_debug_strategy.md` to `-debug-strategy.md` |
| `/home/benjamin/.config/.claude/commands/research.md` | Report path construction | Update to kebab-case file format |

#### 6.2 Agent Files (File Naming Updates)

| File | Line(s) | Change Required |
|------|---------|-----------------|
| `/home/benjamin/.config/.claude/agents/research-specialist.md` | 480 | Update `${NEXT_NUM}_${report_name}.md` to kebab-case |
| `/home/benjamin/.config/.claude/agents/errors-analyst.md` | 32, 317, 347, 366, 372, 387 | Update examples to use kebab-case filenames |
| `/home/benjamin/.config/.claude/agents/repair-analyst.md` | 32 | Update examples to use kebab-case filenames |
| `/home/benjamin/.config/.claude/agents/plan-architect.md` | Plan file examples | Update to kebab-case filenames |
| `/home/benjamin/.config/.claude/agents/spec-updater.md` | 357 | Update `001_report.md` to `001-report.md` |

#### 6.3 Library Files (Path Pattern Updates)

| File | Line(s) | Change Required |
|------|---------|-----------------|
| `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` | 94, 98, 103, 524, 680, 690, 720 | Update plan file path patterns to support `-` separator |

#### 6.4 Documentation Files (Example Updates)

| File | Change Required |
|------|-----------------|
| `/home/benjamin/.config/.claude/docs/guides/development/topic-naming-with-llm.md` | Update file naming examples |
| `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` | Add clarification: directories=snake_case, files=kebab-case |
| CLAUDE.md | Update any file naming examples |

### 7. Backward Compatibility Strategy

#### 7.1 Dual-Format File Pattern Support

Path extraction and glob patterns should support both formats during transition:

**Before** (current):
```bash
/specs/[0-9]{3}_[^/]+/plans/[0-9]{3}_.*_plan\.md
```

**After** (dual support):
```bash
/specs/[0-9]{3}_[^/]+/plans/[0-9]{3}[-_].*[-_]plan\.md
```

#### 7.2 No Forced Migration

- Existing files with `_` separators remain functional
- New files created with `-` separators
- Mixed format during transition period
- Optional migration script for manual conversion

## Recommendations

### 1. Revise Plan to Focus on FILE Naming Only

The plan should be revised to:
- **Remove**: All directory naming changes (Phase 1 updates to topic-naming-agent, topic-utils.sh validation, workflow-initialization.sh sanitization)
- **Add**: File naming changes for plans, reports, summaries, and debug files
- **Update**: Path extraction patterns to support both old and new file formats

### 2. Update Phase Structure

**Revised Phase 1**: File Naming Updates in Commands
- Update plan.md filename construction
- Update repair.md filename construction
- Update debug.md filename construction
- Update research.md report path construction

**Revised Phase 2**: File Naming Updates in Agents
- Update research-specialist.md report paths
- Update errors-analyst.md examples
- Update repair-analyst.md examples
- Update spec-updater.md examples

**Revised Phase 3**: Library Path Pattern Updates
- Update workflow-initialization.sh to support both file formats
- Update path extraction regex patterns

**Revised Phase 4**: Documentation Updates
- Update file naming examples in all relevant docs
- Add clarification: directories=snake_case, files=kebab-case

### 3. Specific File Change Summary

**High Priority Changes**:
1. `plan.md`: line 814 - filename construction
2. `repair.md`: line 524 - filename construction
3. `debug.md`: lines 947-948 - filename construction
4. `workflow-initialization.sh`: lines 680, 94-123 - path patterns

**Medium Priority Changes**:
1. Agent files with examples (research-specialist, errors-analyst, repair-analyst, spec-updater)
2. Documentation files with file naming examples

**Low Priority Changes**:
1. Test files with glob patterns
2. Legacy example updates

### 4. No Changes Required

The following should be explicitly EXCLUDED from the revised plan:
- topic-naming-agent.md (generates directory names, not file names)
- topic-utils.sh validate_topic_name_format() (validates directory names)
- workflow-initialization.sh sanitization (produces directory names)
- CLAUDE.md directory protocols section (describes directory naming)

## References

### Command Files Analyzed
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 814-815) - Plan filename construction
- `/home/benjamin/.config/.claude/commands/repair.md` (lines 524-525) - Plan filename construction
- `/home/benjamin/.config/.claude/commands/debug.md` (lines 947-948) - Debug plan filename construction

### Agent Files Analyzed
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (line 480) - Report path construction
- `/home/benjamin/.config/.claude/agents/errors-analyst.md` (lines 32, 317, 347, 366, 372, 387) - Report path examples
- `/home/benjamin/.config/.claude/agents/repair-analyst.md` (line 32) - Report path examples
- `/home/benjamin/.config/.claude/agents/spec-updater.md` (line 357) - Report path example
- `/home/benjamin/.config/.claude/agents/topic-naming-agent.md` (lines 70-74, 104) - Directory naming (NO CHANGE)

### Library Files Analyzed
- `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` (lines 53, 72, 94, 98, 103, 524, 680, 690, 720) - Path patterns and filename construction
- `/home/benjamin/.config/.claude/lib/plan/topic-utils.sh` (line 94) - Directory validation (NO CHANGE)

### Existing Directory Examples
- `/home/benjamin/.config/.claude/specs/787_state_machine_persistence_bug/` - Current snake_case format
- `/home/benjamin/.config/.claude/specs/882_no_name/` - Current snake_case format
- `/home/benjamin/.config/.claude/specs/918_topic_naming_standards_kebab_case/` - Current snake_case format

### Existing File Examples
- `/home/benjamin/.config/.claude/specs/787_state_machine_persistence_bug/plans/001_state_machine_persistence_fix_plan.md` - Current snake_case format
- `/home/benjamin/.config/.claude/specs/788_commands_readme_update/reports/001_commands_directory_analysis.md` - Current snake_case format

### Original Research Report
- `/home/benjamin/.config/.claude/specs/918_topic_naming_standards_kebab_case/reports/001_topic_naming_kebab_case_standards.md` - Original kebab-case migration research (directory-focused, needs revision)

## Implementation Status
- **Status**: Research Complete - Plan Revision Required
- **Original Plan**: Needs significant revision to change scope from directories to files
- **Key Insight**: User wants directories=snake_case (keep), files=kebab-case (change)
- **Date**: 2025-11-21
