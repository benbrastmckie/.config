# Plan Revision Insights: Uniform LLM Naming with Fallback

## Metadata
- **Date**: 2025-11-21
- **Agent**: research-specialist
- **Topic**: Uniform LLM naming across all commands with clean-break approach
- **Report Type**: codebase analysis
- **Existing Plan**: /home/benjamin/.config/.claude/specs/918_topic_naming_standards_kebab_case/plans/001_topic_naming_standards_kebab_case_plan.md

## Executive Summary

The existing plan focuses on **file naming** (kebab-case migration for filenames within snake_case directories), but the revision request asks for a broader scope: **uniform LLM naming via topic-naming-agent across ALL directory-creating commands** with clean-break approach. This research identifies: (1) 3 commands currently NOT using LLM naming that should (/errors, /setup, /repair), (2) exact code locations requiring modification to add LLM naming, (3) backward compatibility code that can be removed in clean-break approach, and (4) the simplest path to uniform LLM naming with fallback sanitization.

**Key Findings**:
- 4 commands already use topic-naming-agent: /research, /plan, /debug, /optimize-claude
- 3 commands use fallback-only slug generation: /errors, /setup, /repair
- Adding LLM naming to the 3 missing commands requires ~150 lines per command (Task invocation + validation)
- Clean-break approach removes: dual-format patterns, legacy file detection, backward compatibility comments
- Fallback sanitization already exists in `workflow-initialization.sh` (`validate_topic_directory_slug()`)

## Findings

### 1. Commands Currently Using LLM Naming (4 commands)

These commands invoke `topic-naming-agent` via Task tool:

| Command | LLM Invocation Location | Validation Location | Fallback Handling |
|---------|------------------------|---------------------|-------------------|
| `/research` | lines 229-254 | lines 319-373 | Falls back to "no_name" (line 360) |
| `/plan` | lines 257-282 | lines 337-352, 442-501 | Falls back to "no_name" with retry (line 343) |
| `/debug` | lines 310-335 | lines 443-509 | Falls back to "no_name" (line 484) |
| `/optimize-claude` | lines 197-222 | lines 268-322 | Falls back to "no_name" (line 309) |

**Common Pattern** (from `/home/benjamin/.config/.claude/commands/plan.md:257-282`):
```
Task {
  description: "Generate semantic topic directory name"
  prompt: "Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-naming-agent.md

    **User Prompt**: [description]
    **Output File**: ${HOME}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt

    Return completion signal: TOPIC_NAME_GENERATED: <generated_name>"
}
```

### 2. Commands NOT Using LLM Naming (3 commands)

These commands bypass topic-naming-agent and use fallback slug generation:

#### 2.1 `/errors` Command
**File**: `/home/benjamin/.config/.claude/commands/errors.md`
**Current behavior** (lines 261-289):
- Creates description: `ERROR_DESCRIPTION="error analysis"` with optional filter suffix
- Calls `initialize_workflow_paths "$ERROR_DESCRIPTION" "research-only" "2" ""`
- Empty 4th argument means NO classification result, triggering fallback
- Results in directories like `919_error_analysis/` or `919_state_error_errors_repair/`

**Missing**: LLM naming invocation block (approximately lines 230-260 in /plan)

#### 2.2 `/setup` Command
**File**: `/home/benjamin/.config/.claude/commands/setup.md`
**Current behavior** (lines 229-231 in analyze mode):
- Hardcoded description: `"CLAUDE.md standards analysis"`
- Calls `initialize_workflow_paths "CLAUDE.md standards analysis" "research" "2" ""`
- Empty 4th argument triggers fallback
- Results in directories like `920_claudemd_standards_analysis/`

**Missing**: LLM naming invocation block (setup has simpler use case - may not need semantic naming)

#### 2.3 `/repair` Command
**File**: `/home/benjamin/.config/.claude/commands/repair.md`
**Current behavior** (lines 242-257):
- Creates description from filters: `ERROR_DESCRIPTION="error analysis and repair"`
- Calls `initialize_workflow_paths "$ERROR_DESCRIPTION" "research-and-plan" "$RESEARCH_COMPLEXITY" ""`
- Empty 4th argument triggers fallback
- Results in directories like `921_error_analysis_and_repair/`

**Missing**: LLM naming invocation block

### 3. Fallback Mechanism Analysis

The fallback is implemented in `workflow-initialization.sh` via `validate_topic_directory_slug()`:

**File**: `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh`
**Function**: `validate_topic_directory_slug()` (lines 270-333)

**Fallback flow** (lines 318-323):
```bash
# Tier 2: Basic sanitization fallback
if [ -z "$topic_slug" ]; then
  topic_slug=$(echo "$workflow_description" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' |
               sed 's/[^a-z0-9_]//g' | sed 's/__*/_/g' | sed 's/^_*//;s/_*$//' | cut -c1-40)
  strategy="sanitize"
fi
```

This fallback:
1. Converts to lowercase
2. Replaces spaces with underscores
3. Removes non-alphanumeric characters (except underscores)
4. Collapses multiple underscores
5. Trims leading/trailing underscores
6. Truncates to 40 characters

### 4. Backward Compatibility Code to Remove (Clean-Break)

The following patterns can be removed for clean-break approach:

#### 4.1 Dual-Format Path Patterns
**File**: `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh`
- Line 95: Path regex `/specs/[0-9]{3}_[^/]+/plans/[0-9]{3}_[^.]+\.md$`
- **Clean-break**: Change to single format (underscore OR hyphen, not both)

#### 4.2 Legacy State File Detection
**File**: `/home/benjamin/.config/.claude/lib/core/state-persistence.sh`
- Lines 143-151: Legacy state file warnings for `.claude/data/workflows/*.state`
- **Clean-break**: Remove warning code entirely

#### 4.3 Legacy Argument File Fallback
**File**: `/home/benjamin/.config/.claude/lib/workflow/argument-capture.sh`
- Lines 131-145: Fallback to legacy fixed filename `${command_name}_arg.txt`
- Lines 188-202: Cleanup of legacy temp files
- **Clean-break**: Remove legacy file handling

#### 4.4 Backward Compatibility Comments
Multiple files contain "backward compat" comments that reference removed patterns:
- `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh:468,473`
- `/home/benjamin/.config/.claude/lib/workflow/workflow-llm-classifier.sh:242,415`

### 5. Simplest Path to Add LLM Naming

For each of the 3 commands missing LLM naming, the simplest approach is to:

1. **Copy the LLM naming block** from `/plan` command (lines 245-282)
2. **Copy the validation block** from `/plan` command (lines 337-352, 442-501)
3. **Modify only**:
   - `WORKFLOW_ID` reference
   - Error description variable name
   - Task tool prompt context

**Estimated code additions per command**:
- Topic naming Task block: ~25 lines
- Input file preparation: ~10 lines
- Output validation with retry: ~60 lines
- Fallback handling: ~50 lines
- **Total**: ~145 lines per command

### 6. Files Requiring Modification for Uniform LLM Naming

#### 6.1 Commands to Add LLM Naming (HIGH PRIORITY)

| File | Modification | Lines to Add |
|------|--------------|--------------|
| `/home/benjamin/.config/.claude/commands/errors.md` | Add topic-naming-agent Task block before Block 1 line 231 | ~145 |
| `/home/benjamin/.config/.claude/commands/repair.md` | Add topic-naming-agent Task block before Block 1 line 189 | ~145 |
| `/home/benjamin/.config/.claude/commands/setup.md` | Add topic-naming-agent Task block before Block 2 line 109 (analyze mode only) | ~145 |

#### 6.2 Library Updates (MEDIUM PRIORITY)

| File | Modification | Rationale |
|------|--------------|-----------|
| `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh:318-323` | Keep fallback sanitization but remove "backward compatible" comments | Clean-break |
| `/home/benjamin/.config/.claude/lib/workflow/argument-capture.sh:131-202` | Remove legacy file fallback code | Clean-break |
| `/home/benjamin/.config/.claude/lib/core/state-persistence.sh:143-151` | Remove legacy state file warnings | Clean-break |

#### 6.3 Documentation Updates (LOW PRIORITY)

| File | Modification |
|------|--------------|
| `/home/benjamin/.config/.claude/docs/guides/development/topic-naming-with-llm.md` | Add /errors, /repair, /setup to list of commands using LLM naming |
| `/home/benjamin/.config/CLAUDE.md` | Update directory protocols section if needed |

## Recommendations

### 1. Revise Plan Structure to Include LLM Naming Integration

The existing plan focuses on kebab-case file naming. Revise to add a **Phase 0** (or prepend to Phase 1):

**New Phase: Add LLM Naming to Missing Commands**
- Task 1: Add topic-naming-agent integration to `/errors` command
- Task 2: Add topic-naming-agent integration to `/repair` command
- Task 3: Add topic-naming-agent integration to `/setup` command (analyze mode)

### 2. Use Existing LLM Naming Pattern as Template

Copy the proven pattern from `/plan` command:
1. Topic naming input file preparation (5 lines)
2. Task tool invocation with agent guidelines (25 lines)
3. Output file validation with retry logic (60 lines)
4. Fallback handling with error logging (50 lines)

### 3. Remove Backward Compatibility Code (Clean-Break)

In a dedicated phase:
- Remove `argument-capture.sh` legacy file handling (lines 131-202)
- Remove `state-persistence.sh` legacy warnings (lines 143-151)
- Remove dual-format pattern support in `workflow-initialization.sh`
- Remove "backward compat" comments throughout

### 4. Keep Fallback Sanitization as Safety Net

Even with LLM naming on all commands, keep the `validate_topic_directory_slug()` fallback:
- Handles LLM failures gracefully
- Provides predictable behavior in offline scenarios
- Already implemented and tested

### 5. Update Documentation to Reflect Uniform Standard

After implementation:
- Update `topic-naming-with-llm.md` to list all 7 commands
- Document clean-break removal of backward compatibility
- Update command reference with new behavior

## References

### Commands with LLM Naming (Template Sources)
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 245-501) - Most comprehensive implementation
- `/home/benjamin/.config/.claude/commands/research.md` (lines 220-410) - Research-focused variant
- `/home/benjamin/.config/.claude/commands/debug.md` (lines 310-509) - Debug workflow variant
- `/home/benjamin/.config/.claude/commands/optimize-claude.md` (lines 144-322) - Optimization variant

### Commands Requiring LLM Naming Addition
- `/home/benjamin/.config/.claude/commands/errors.md` (lines 231-290) - Current fallback-only
- `/home/benjamin/.config/.claude/commands/repair.md` (lines 189-277) - Current fallback-only
- `/home/benjamin/.config/.claude/commands/setup.md` (lines 109-230) - Current fallback-only (analyze mode)

### Libraries with Backward Compatibility to Remove
- `/home/benjamin/.config/.claude/lib/workflow/argument-capture.sh` (lines 131-202) - Legacy file handling
- `/home/benjamin/.config/.claude/lib/core/state-persistence.sh` (lines 143-151) - Legacy warnings
- `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` (lines 468-474) - BC comments

### Agent Reference
- `/home/benjamin/.config/.claude/agents/topic-naming-agent.md` (lines 1-500) - Topic naming behavioral guidelines

### Documentation to Update
- `/home/benjamin/.config/.claude/docs/guides/development/topic-naming-with-llm.md` - Command list expansion
