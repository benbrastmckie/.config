# Plan Revision Research: Clean-Break Approach for /setup Command

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Clean-break approach analysis for /setup command plan revision
- **Report Type**: codebase analysis and standards compliance
- **Workflow**: research-and-revise

## Executive Summary

The plan violates clean-break philosophy by creating a migration guide (Phase 7, lines 513-622) when writing standards prohibit migration documentation in functional docs. The plan correctly identifies mode consolidation (6→3) and command separation improvements but undermines these with backward-compatibility focus and migration sections. Key violations: (1) Migration guide creation explicitly banned by writing-standards.md lines 52-57, (2) Backward compatibility emphasis contradicts clean-break priority (writing-standards.md lines 25-26), (3) Documentation should describe current state, not transitions (lines 49-54). The plan should eliminate Phase 7 migration guide subsection, replace with direct command documentation updates only, and remove all migration/compatibility references.

## Findings

### Finding 1: Clean-Break Philosophy vs Migration Guide Creation

**Location**: /home/benjamin/.config/.claude/docs/concepts/writing-standards.md:52-57

**Standard**: "No migration guides: Do not create migration guides or compatibility documentation for refactors"

**Plan Violation**: Phase 7 (lines 513-622) creates Section 6.3.1 "Migration Guide: Deprecated Flags" with old→new command mappings, benefits summary, and migration workflows.

**Evidence**:
```markdown
# Plan lines 543-622
**Migration Guide Content**:
### 6.3.1 Migration Guide: /setup v2.0 Changes

**Summary**: /setup v2.0 consolidates from 6 modes to 3 modes...

#### Deprecated Flags
**--cleanup** (removed):
# Old: /setup --cleanup
# New: /optimize-claude

**--enhance-with-docs** (removed):
# Old: /setup --enhance-with-docs
# New: /optimize-claude
```

**Why It's Wrong**: Writing standards explicitly state migration guides belong in CHANGELOG.md or separate migration documents, NOT in functional documentation. The setup-command-guide.md should describe current state only.

**Reference**: writing-standards.md:309-347 shows migration guides should be separate documents, not subsections of command guides.

### Finding 2: Backward Compatibility Emphasis Contradicts Core Values

**Location**: /home/benjamin/.config/.claude/docs/concepts/writing-standards.md:25-26, 45

**Standard**: "Prioritize coherence over compatibility: Clean, well-designed refactors are preferred over maintaining backward compatibility"

**Plan Statement**: Lines 686, 739 emphasize "backward compatibility where applicable" and "maintains backward compatibility"

**Evidence**:
```markdown
# Plan lines 686, 739
- Verify backward compatibility where applicable
- /setup standard mode (no flags) maintains backward compatibility
```

**Contradiction**: Clean-break philosophy states backward compatibility is SECONDARY to clarity, quality, coherence, and maintainability. The plan should focus on current implementation quality, not preserving old patterns.

**Correct Approach**: Document current command behavior without referencing old flags or comparing to previous versions.

### Finding 3: Standard Command Pattern Analysis - Flag Usage Consistency

**Research**: Analyzed /plan, /debug, /repair commands for flag patterns

**Findings**:
- **--file flag**: Universal pattern across /plan, /debug, /repair, /research, /revise for long prompts
  - /plan.md:71-90, /debug.md:53-75, /research.md:70-88, /revise.md:107-138
  - Consistent syntax: `--file <path>` with relative→absolute path conversion
  - Archive pattern: Move original file to {TOPIC_PATH}/prompts/ directory

- **--complexity flag**: Standard across research-based workflows
  - /plan (default: 3), /debug (default: 2), /repair (default: 2)
  - Syntax: `--complexity 1-4` parsed with regex `--complexity[[:space:]]+([1-4])`

- **Mode-specific flags**: /setup is UNIQUE in having mode flags (--cleanup, --validate, --analyze)
  - Other commands use subcommands or different command entirely (/build vs /plan vs /debug)
  - /setup's 6-mode design is non-standard compared to single-purpose command pattern

**Implication**: The plan's consolidation to 3 modes aligns with standard command patterns where each command has ONE clear purpose.

### Finding 4: --analyze Flag Should Be Default Behavior, Not Explicit Flag

**Location**: Plan lines 221, existing plan lines 416-421

**Current Plan**: Keeps `--analyze` flag and maps `--validate` to it

**Standards Analysis**:
- /plan, /debug, /repair have NO mode flags - they execute their purpose automatically
- /setup is unique in requiring explicit `--analyze` when CLAUDE.md exists

**Recommendation from Research Report**: Lines 56, 221 note "automatic mode switching when CLAUDE.md exists" and "auto-switching to prevent accidental overwrites"

**Optimal Design**:
```bash
# Automatic behavior (no flags needed)
/setup              # CLAUDE.md missing → create it (standard mode)
/setup              # CLAUDE.md exists → analyze it (auto-switch to analysis mode)
/setup --force      # CLAUDE.md exists → overwrite it (explicit override)
```

**Why**: Matches /plan, /debug, /repair pattern where command behavior adapts to context without mode flags.

### Finding 5: Analysis Mode Should Use Research Command Infrastructure

**Location**: Plan line 232, setup.md:232-266

**Current Implementation**: Flat reports/ directory with manual numbering
```bash
# setup.md:234-239
REPORTS_DIR="${PROJECT_DIR}/.claude/specs/reports"
mkdir -p "$REPORTS_DIR"
NUM=$(ls -1 "$REPORTS_DIR" 2>/dev/null | grep -E "^[0-9]+_" | sed 's/_.*//' | sort -n | tail -1)
NUM=$(printf "%03d" $((NUM + 1)))
REPORT="${REPORTS_DIR}/${NUM}_standards_analysis.md"
```

**Standard Pattern**: /plan, /debug, /repair use unified-location-detection.sh for topic-based organization
```bash
# plan.md:119-127, 220-232
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" || exit 1
initialize_workflow_paths "$FEATURE_DESCRIPTION" "research-and-plan" "$RESEARCH_COMPLEXITY" ""
SPECS_DIR="$TOPIC_PATH"
RESEARCH_DIR="${TOPIC_PATH}/reports"
PLANS_DIR="${TOPIC_PATH}/plans"
```

**Plan Recognition**: Lines 232, 44 note "Analysis infrastructure must follow /research command patterns using unified-location-detection.sh for topic-based organization"

**Conformance**: Phase 4 (lines 281-336) implements this correctly, adopting research patterns.

### Finding 6: Completion Messages Should Focus on Current State, Not Future Integration

**Location**: Plan Phase 6 (lines 422-510), completion message examples

**Plan Approach**: Shows "planned /optimize-claude integration" messages
```markdown
# Plan lines 464-467
(Planned) Direct integration with analysis:
   /optimize-claude --file $REPORT_PATH
Note: --file flag to be implemented in separate plan
```

**Clean-Break Principle**: Documentation describes current state, not future plans (writing-standards.md:56)

**Issue**: Completion messages are runtime output, not documentation, but principle still applies - describe what IS, not what WILL BE.

**Better Approach**:
```markdown
# Current state only
Next Steps:
  1. Review the analysis report:
     cat $REPORT_PATH

  2. Run optimization workflow:
     /optimize-claude
```

Note about future --file support belongs in ROADMAP.md or GitHub issues, not runtime messages.

### Finding 7: Documentation Standards Violations Throughout Plan

**Location**: Multiple sections showing temporal language

**Violations Found**:

1. **Line 547**: "v2.0 consolidates from 6 modes to 3 modes" - version reference banned (writing-standards.md:169-177)

2. **Lines 551-580**: "Deprecated Flags" section with "Old:" and "New:" comparisons - migration language banned (writing-standards.md:141-151)

3. **Lines 615-621**: "Benefits of v2.0" section - version-based benefits list violates timeless writing

**Standards Compliant Approach**:
```markdown
# Instead of "v2.0 Changes" and "Old/New"
## /setup Command Reference

**Modes**:
- Standard mode: Generate CLAUDE.md
- Analysis mode: Diagnose existing CLAUDE.md
- Force mode: Overwrite existing CLAUDE.md

**Removed Flags**:
Use /optimize-claude for cleanup, enhancement, and repair operations.
```

**Principle**: Describe current command capabilities without comparing to past versions.

## Recommendations

### Recommendation 1: Eliminate Phase 7 Migration Guide Subsection

**Action**: Remove lines 531-622 (migration guide content) from Phase 7

**Replace With**: Direct documentation updates describing current command behavior

**Justification**:
- Writing standards prohibit migration guides in functional documentation (writing-standards.md:52-57)
- Setup-command-guide.md should describe current /setup v2.0 capabilities, not transition from v1
- Migration information belongs in CHANGELOG.md (writing-standards.md:311-329)

**Implementation**:
```markdown
# Phase 7: Documentation Updates [NOT Migration Guide Creation]

**Objective**: Update setup-command-guide.md to reflect current 3-mode design

**Tasks**:
- [ ] Update Section 1.2 "Command Modes" from 6 modes to 3 modes
- [ ] Remove Mode 2, 5, 6 documentation (cleanup, apply-report, enhancement)
- [ ] Merge Mode 3 into Mode 4 (validation → analysis)
- [ ] Update Mode 1 with auto-switching behavior
- [ ] Update Section 2.1 workflows for current command patterns
- [ ] Update command-reference.md with current syntax
- [ ] Remove all "old" vs "new" comparisons
- [ ] Document current capabilities only
```

### Recommendation 2: Revise Backward Compatibility Language

**Action**: Remove lines 686, 739 emphasizing backward compatibility

**Replace With**: Focus on current implementation quality

**Justification**: Clean-break philosophy prioritizes coherence over compatibility (writing-standards.md:25-26)

**Implementation**:
```markdown
# Testing section - revised
**Regression Testing**:
- Verify standard mode CLAUDE.md generation works correctly
- Ensure testing framework detection produces accurate results
- Confirm error logging integration functions properly
- Validate all current command modes execute successfully
```

### Recommendation 3: Simplify Mode Flags to Match Standard Command Patterns

**Action**: Keep auto-switching approach but remove --analyze flag requirement

**Current Plan**: `--analyze` required for explicit analysis mode
**Better Approach**: Auto-detect based on CLAUDE.md existence

**Justification**: /plan, /debug, /repair have NO mode flags - they infer behavior from context

**Implementation**:
```bash
# Auto-switching logic (Phase 3)
if [ "$MODE" = "standard" ] && [ -f "${PROJECT_DIR}/CLAUDE.md" ]; then
  if [ "$FORCE" != true ]; then
    echo "CLAUDE.md exists, switching to analysis mode"
    echo "To overwrite: /setup --force"
    MODE="analyze"
  fi
fi
```

Users never need `--analyze` flag - command behavior adapts automatically.

### Recommendation 4: Update Completion Messages to Current-State Only

**Action**: Remove "planned integration" notes from Phase 6 completion messages (lines 464-467)

**Replace With**: Current capabilities only

**Justification**: Runtime messages should describe current state, not future plans (clean-break principle applied to output)

**Implementation**:
```markdown
# Analysis Completion Message (revised)
echo "Next Steps:"
echo "  1. Review analysis report:"
echo "     cat $REPORT_PATH"
echo ""
echo "  2. Run optimization:"
echo "     /optimize-claude"
```

Future --file integration documented in ROADMAP.md or GitHub issues, not runtime output.

### Recommendation 5: Adopt Consistent Error Message Pattern

**Action**: For removed flags, provide clear current-state guidance without migration language

**Current Plan**: "ERROR: --cleanup removed. Use /optimize-claude instead."
**Better Approach**: Direct to current command without "removed" language

**Justification**: Error messages are runtime output describing current system state

**Implementation**:
```bash
# Flag parsing (Phase 1)
--cleanup)
  echo "ERROR: Cleanup mode not supported in /setup"
  echo "Use: /optimize-claude"
  exit 1 ;;

--enhance-with-docs)
  echo "ERROR: Enhancement mode not supported in /setup"
  echo "Use: /optimize-claude"
  exit 1 ;;
```

Messages focus on current command capabilities, not what was "removed".

### Recommendation 6: Document Current Command in Guide (Not Transition)

**Action**: Rewrite Phase 7 guide updates to describe /setup as if 3-mode design always existed

**Current Plan**: Compares old 6-mode to new 3-mode throughout
**Better Approach**: Describe 3-mode design without historical context

**Justification**: Functional documentation should read as if current implementation always existed (writing-standards.md:49-54)

**Example**:
```markdown
# Guide Section 1.2 - Current State Only

### Command Modes

The /setup command operates in 3 modes:

**Standard Mode** (default):
Generates CLAUDE.md with auto-detected standards.
Usage: /setup [directory]
Behavior: Auto-switches to analysis mode if CLAUDE.md exists.

**Analysis Mode** (automatic):
Diagnoses existing CLAUDE.md and creates analysis report.
Triggered: Automatically when CLAUDE.md exists (unless --force used).

**Force Mode** (explicit override):
Overwrites existing CLAUDE.md without auto-switching.
Usage: /setup --force

### Related Commands

For CLAUDE.md optimization and repair, use /optimize-claude.
```

No mention of "previously had 6 modes" or "consolidated from".

## References

### Core Standards Documentation
- /home/benjamin/.config/.claude/docs/concepts/writing-standards.md:1-558
  - Lines 23-46: Development philosophy (clean-break refactors)
  - Lines 49-66: Documentation standards (present-focused writing)
  - Lines 79-98: Banned patterns (temporal markers)
  - Lines 109-138: Temporal phrases to avoid
  - Lines 141-166: Migration language prohibition
  - Lines 309-347: Where historical information belongs (CHANGELOG, not docs)

### Plan Under Review
- /home/benjamin/.config/.claude/specs/854_001_setup_command_comprehensive_analysismd_in/plans/001_001_setup_command_comprehensive_analysis_plan.md:1-825
  - Lines 513-622: Phase 7 migration guide creation (VIOLATES standards)
  - Lines 543-580: Migration guide content with old→new mappings (PROHIBITED)
  - Lines 615-621: Version-based benefits section (TEMPORAL REFERENCE)
  - Lines 686, 739: Backward compatibility emphasis (CONTRADICTS clean-break)

### Command Pattern Examples
- /home/benjamin/.config/.claude/commands/plan.md:1-704
  - Lines 69-90: Standard --file flag implementation
  - Lines 119-127: unified-location-detection.sh sourcing
  - Lines 220-232: initialize_workflow_paths usage
  - Single-purpose design (no mode flags)

- /home/benjamin/.config/.claude/commands/debug.md:1-878
  - Lines 53-75: Standard --file flag pattern
  - Lines 115-122: unified-location-detection.sh integration
  - Lines 333-338: initialize_workflow_paths pattern
  - Context-adaptive behavior without mode flags

- /home/benjamin/.config/.claude/commands/repair.md:1-200
  - Lines 48-75: Filter flags (--since, --type, --command, --severity)
  - Lines 68-75: Standard --complexity flag
  - Lines 119-131: unified-location-detection.sh sourcing
  - Research-and-plan workflow pattern

### Setup Command Current State
- /home/benjamin/.config/.claude/commands/setup.md:1-442
  - Lines 46-50: Current flag parsing (6 mode flags)
  - Lines 232-266: Analysis mode with flat reports/ structure
  - Lines 285-383: Enhancement mode using SlashCommand (deprecated pattern)
  - Non-standard multi-mode design (unique among commands)

### Research Report Referenced
- /home/benjamin/.config/.claude/specs/853_explain_exactly_what_command_how_used_what_better/reports/001_setup_command_comprehensive_analysis.md:1-300
  - Lines 16: NOTE on /setup vs /optimize-claude separation
  - Lines 56: NOTE on auto-switching to prevent overwrites
  - Lines 221: NOTE on default to project root and --analyze flag
  - Lines 232: NOTE on following /research command patterns
  - Lines 253: NOTE on /optimize-claude --file flag integration
