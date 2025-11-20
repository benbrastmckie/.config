# /optimize-claude Signal Documentation Format Revision Research Report

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Change /optimize-claude signal documentation from 'Multiple REPORT_CREATED + PLAN_CREATED' to just 'PLAN_CREATED' to match uniform command format like /plan
- **Report Type**: documentation consistency analysis + format standardization
- **Workflow**: revise
- **Complexity**: 2

## Executive Summary

Research conducted to analyze whether `/optimize-claude` signal documentation should be changed from `Multiple REPORT_CREATED + PLAN_CREATED` to just `PLAN_CREATED` to match the uniform format used by other multi-artifact commands like `/plan`, `/repair`, and `/revise`.

**Conclusion**: The documentation should be standardized to show only the **primary completion signal** (PLAN_CREATED) for all multi-artifact commands. The current format for `/optimize-claude` is an inconsistency that should be corrected. All multi-artifact commands create intermediate research reports, but the Completion Signal Protocol section should document only the final, primary signal that represents the command's main output artifact.

## Problem Statement

**User Request**: "Change /optimize-claude signal documentation from 'Multiple REPORT_CREATED + PLAN_CREATED' to just 'PLAN_CREATED' to match uniform command format like /plan"

**Current Documentation State** (lines 35-42 of plan):
```markdown
2. **Completion Signal Protocol**: All workflow agents return standardized completion signals as final output:
   - `/plan` → `PLAN_CREATED: /path/to/plan.md`
   - `/research` → `REPORT_CREATED: /path/to/report.md`
   - `/build` → `SUMMARY_CREATED: /path/to/summary.md`
   - `/debug` → `DEBUG_REPORT_CREATED: /path/to/report.md`
   - `/repair` → `PLAN_CREATED: /path/to/plan.md`
   - `/revise` → `PLAN_REVISED: /path/to/plan.md`
   - `/optimize-claude` → Multiple `REPORT_CREATED` + `PLAN_CREATED`
```

**Inconsistency Identified**: `/optimize-claude` is the only command showing "Multiple signals" while other multi-artifact commands show only their primary signal.

## Findings

### 1. Multi-Artifact Command Comparison

**Commands That Create Research Reports THEN Plans**:

| Command | Research Reports Created | Plan Created | Current Documentation Format |
|---------|-------------------------|--------------|------------------------------|
| `/plan` | 1-4 reports | Yes (001_*_plan.md) | `PLAN_CREATED: /path/to/plan.md` ✓ |
| `/repair` | 1 error analysis | Yes (001_*_plan.md) | `PLAN_CREATED: /path/to/plan.md` ✓ |
| `/revise` | 0-N revision insights | Yes (revised plan) | `PLAN_REVISED: /path/to/plan.md` ✓ |
| `/optimize-claude` | 4 analysis reports | Yes (001_*_plan.md) | `Multiple REPORT_CREATED + PLAN_CREATED` ❌ |

**Analysis**: All four commands create research reports before creating a plan, but only `/optimize-claude` documents "Multiple signals" instead of showing just the primary signal type.

### 2. Actual Signal Emission Patterns

**What Actually Gets Emitted** (terminal output):

**/plan command execution**:
```
REPORT_CREATED: /path/reports/001_research_topic_1.md
REPORT_CREATED: /path/reports/002_research_topic_2.md
REPORT_CREATED: /path/reports/003_research_topic_3.md
PLAN_CREATED: /path/plans/001_implementation_plan.md
```

**/repair command execution**:
```
REPORT_CREATED: /path/reports/001_error_analysis.md
PLAN_CREATED: /path/plans/001_repair_plan.md
```

**/revise command execution**:
```
REPORT_CREATED: /path/reports/001_revision_insights.md
PLAN_REVISED: /path/plans/001_updated_plan.md
```

**/optimize-claude command execution**:
```
REPORT_CREATED: /path/reports/001_claude_md_analysis.md
REPORT_CREATED: /path/reports/002_docs_structure_analysis.md
REPORT_CREATED: /path/reports/003_bloat_analysis.md
REPORT_CREATED: /path/reports/004_accuracy_analysis.md
PLAN_CREATED: /path/plans/001_optimization_plan.md
```

**Key Finding**: All four commands emit BOTH `REPORT_CREATED` and plan signals. The only difference is `/optimize-claude` creates 4 research reports instead of 1-4 variable reports. This is a quantitative difference, not a qualitative difference.

### 3. Completion Signal Protocol: Purpose and Scope

**Two Possible Interpretations**:

**Interpretation A: Document All Signals Emitted**
- Show every signal type a command outputs
- `/plan` would be: `Multiple REPORT_CREATED + PLAN_CREATED`
- `/repair` would be: `REPORT_CREATED + PLAN_CREATED`
- `/revise` would be: `Multiple REPORT_CREATED + PLAN_REVISED`
- `/optimize-claude` would be: `Multiple REPORT_CREATED + PLAN_CREATED` ✓

**Interpretation B: Document Primary Completion Signal Only** ⭐
- Show only the final, primary artifact signal
- `/plan` → `PLAN_CREATED` ✓ (current)
- `/repair` → `PLAN_CREATED` ✓ (current)
- `/revise` → `PLAN_REVISED` ✓ (current)
- `/optimize-claude` → `PLAN_CREATED` ✗ (not current)

**Current State**: Documentation uses Interpretation B for 6 commands, Interpretation A for 1 command (`/optimize-claude`).

### 4. Documentation Pattern Analysis

**Pattern Used in Plan Documentation**:

**Section 1: Completion Signal Protocol** (lines 35-42)
- Purpose: Show the primary completion signal for each command
- Format: Command → Primary Signal Type
- Usage: Quick reference for "what signal should I look for from this command?"

**Section 2: Multi-Artifact Commands** (lines 149-152)
- Purpose: Explain hook behavior for commands that create multiple files
- Format: Detailed explanation of what artifacts are created and which opens
- Usage: Understanding hook priority logic

**Finding**: The Completion Signal Protocol section follows a "one signal per command" pattern for all commands except `/optimize-claude`. The detailed multi-artifact behavior is documented separately in the Multi-Artifact Commands section.

### 5. User Experience Impact

**Current Documentation Reading Experience**:

When a user reads the Completion Signal Protocol section:
1. Sees clean, consistent format: command → signal
2. Reaches `/optimize-claude`: "Multiple REPORT_CREATED + PLAN_CREATED"
3. **Confusion point**: "Why is this command different? Does it behave differently?"
4. Must read further to understand this is not a behavioral difference

**Proposed Documentation Reading Experience**:

When a user reads with uniform format:
1. Sees consistent format: command → signal
2. All planning commands show PLAN_CREATED (or PLAN_REVISED)
3. No confusion about different behavior
4. Multi-Artifact Commands section explains intermediate artifacts for ALL planning commands

**Analysis**: Uniform format reduces cognitive load and avoids implying `/optimize-claude` is fundamentally different from `/plan` or `/repair`.

### 6. Technical Accuracy Verification

**Question**: Is it technically accurate to say `/optimize-claude → PLAN_CREATED`?

**Answer**: YES

**Reasoning**:
1. **Primary Signal**: The command's primary completion signal IS `PLAN_CREATED`
2. **Last Output**: `PLAN_CREATED` is the final signal emitted (line 287 of optimize-claude.md)
3. **Hook Behavior**: Hook looks for `PLAN_CREATED` as the primary artifact
4. **Purpose Alignment**: Command's purpose is to create an optimization **plan**, not research reports
5. **Consistent with Peers**: `/plan` also creates research reports but documents only `PLAN_CREATED`

**Verification from Code**:
```markdown
# From /home/benjamin/.config/.claude/commands/optimize-claude.md:287
- Completion signal: PLAN_CREATED: [exact absolute path]
```

The command explicitly defines `PLAN_CREATED` as its primary completion signal.

### 7. Historical Context: Why "Multiple" Was Added

**Investigation**: Check when/why "Multiple" format was introduced

**Evidence from Research Reports**:
- Report 001 (hook-based opening): Lists `/optimize-claude` but doesn't document it
- Report 002 (optimize-claude integration): First mentions "Multiple REPORT_CREATED + PLAN_CREATED"
- Report 004 (clarification): Added note about emission vs opening

**Pattern**: The "Multiple" format was likely added to emphasize that `/optimize-claude` creates 4 reports, anticipating user questions about "which file opens?". However, this created an inconsistency with other commands.

**Better Solution**: Document all multi-artifact commands uniformly, explain multi-artifact behavior in dedicated section (already exists in plan).

### 8. Impact on Other Documentation Sections

**Sections That Reference Completion Signal Protocol**:

1. **Research Summary** (lines 35-42): Primary change location
2. **Multi-Artifact Commands** (lines 149-152): Already documents 4 reports + plan behavior
3. **Phase 4 Testing** (lines 332-356): Test comments reference multiple signals
4. **User Documentation Template** (lines 565-577): References signal emission

**Changes Required**:
- Line 42: Change format to match other commands
- Line 44: Update clarification note to be generic (not `/optimize-claude`-specific)
- Test comments: Keep detailed (tests should be explicit)
- User docs: Already explains multi-artifact behavior correctly

### 9. Proposed Changes

**Change 1: Standardize Signal Format** (CRITICAL)

**Current**:
```markdown
   - `/optimize-claude` → Multiple `REPORT_CREATED` + `PLAN_CREATED`
```

**Proposed**:
```markdown
   - `/optimize-claude` → `PLAN_CREATED: /path/to/plan.md`
```

**Rationale**: Matches format of `/plan`, `/repair`, `/revise` (all multi-artifact commands)

**Change 2: Update Clarification Note** (HIGH)

**Current** (lines 44):
```markdown
**Clarification**: This protocol documents what signals agents **emit** to terminal output. Commands like `/optimize-claude` emit multiple signals (4 research reports + 1 plan), but the hook only **opens** one file using priority logic (see Multi-Artifact Commands section).
```

**Proposed**:
```markdown
**Clarification**: This protocol documents the **primary completion signal** for each command. Multi-artifact commands (like `/plan`, `/repair`, `/revise`, `/optimize-claude`) emit additional `REPORT_CREATED` signals for intermediate research reports, but the primary signal indicates the command's main output artifact. The hook opens only the primary artifact using priority logic (see Multi-Artifact Commands section).
```

**Rationale**:
- Generalizes explanation to all multi-artifact commands
- Clarifies "primary signal" concept
- Removes `/optimize-claude`-specific callout (no longer needed)
- Maintains clarity about emission vs opening

**Change 3: Verify Multi-Artifact Commands Section** (LOW)

**Current** (lines 149-152):
```markdown
**Multi-Artifact Commands**:
- `/plan`: Creates 1-4 research reports, then 1 implementation plan → Opens **plan only**
- `/optimize-claude`: Creates 4 research reports, then 1 optimization plan → Opens **plan only**
- `/revise`: Creates 0-N research reports, then 1 revised plan → Opens **revised plan only**
- `/repair`: Creates 1 error analysis report, then 1 repair plan → Opens **repair plan only**
```

**Status**: Already correct, no changes needed. This section properly documents that all four commands create research reports + plan.

### 10. Alternative: Enhanced Detail Format

**Alternative Consideration**: Should ALL multi-artifact commands show detailed signal lists?

**Option**: Change `/plan`, `/repair`, `/revise` to match `/optimize-claude`'s current format:
```markdown
   - `/plan` → Multiple `REPORT_CREATED` + `PLAN_CREATED`
   - `/repair` → `REPORT_CREATED` + `PLAN_CREATED`
   - `/revise` → Multiple `REPORT_CREATED` + `PLAN_REVISED`
   - `/optimize-claude` → Multiple `REPORT_CREATED` + `PLAN_CREATED`
```

**Evaluation**:
- **Pros**: Explicit about intermediate artifacts
- **Cons**:
  - Violates "primary signal" documentation pattern
  - Adds complexity to quick reference section
  - Redundant with Multi-Artifact Commands section
  - "Multiple" is vague (1-4 for `/plan`, exactly 4 for `/optimize-claude`)

**Recommendation**: REJECT this alternative. The "primary signal only" pattern is cleaner and more maintainable.

## Recommendations

### Recommendation 1: Standardize Signal Format (CRITICAL)

**Priority**: CRITICAL

**Action**: Change line 42 from:
```markdown
   - `/optimize-claude` → Multiple `REPORT_CREATED` + `PLAN_CREATED`
```

To:
```markdown
   - `/optimize-claude` → `PLAN_CREATED: /path/to/plan.md`
```

**Rationale**: Creates uniform documentation format matching all other multi-artifact commands

**Impact**: -1 line, improved consistency

### Recommendation 2: Generalize Clarification Note (HIGH)

**Priority**: HIGH

**Action**: Update clarification note (lines 44) to explain primary signal concept generically

**Proposed Text**:
```markdown
**Clarification**: This protocol documents the **primary completion signal** for each command. Multi-artifact commands (like `/plan`, `/repair`, `/revise`, `/optimize-claude`) emit additional `REPORT_CREATED` signals for intermediate research reports, but the primary signal indicates the command's main output artifact. The hook opens only the primary artifact using priority logic (see Multi-Artifact Commands section).
```

**Rationale**:
- Removes `/optimize-claude`-specific callout
- Explains pattern for all multi-artifact commands
- Clarifies "primary signal" concept

**Impact**: ~2 lines modified, improved clarity

### Recommendation 3: Add Cross-Reference Note (MEDIUM)

**Priority**: MEDIUM

**Action**: Add brief note after Completion Signal Protocol list

**Proposed Text**:
```markdown
**Note**: Commands may emit multiple signals during execution. See "Multi-Artifact Commands" section for detailed artifact creation patterns.
```

**Rationale**: Guides users to detailed section without cluttering quick reference

**Impact**: +2 lines

### Recommendation 4: Update User Documentation Template (MEDIUM)

**Priority**: MEDIUM

**Action**: Update Phase 6 user documentation template (lines 565-577) to use consistent terminology

**Proposed Text**:
```markdown
### How It Works

Claude Code workflow commands emit **completion signals** to indicate artifact creation. Multi-artifact commands like `/plan`, `/repair`, `/revise`, and `/optimize-claude` create multiple artifacts (research reports + plan), emitting multiple signals, but the **primary completion signal** indicates the main output artifact.

The hook monitors terminal output and automatically opens only the **primary artifact** (at most one file) based on priority rules:
- Plans (PLAN_CREATED, PLAN_REVISED) - highest priority
- Summaries (SUMMARY_CREATED) - medium priority
- Debug reports (DEBUG_REPORT_CREATED) - medium-low priority
- Research reports (REPORT_CREATED) - lowest priority (typically intermediate)

Intermediate artifacts remain accessible via the command picker (`<leader>ac`) but do not auto-open.
```

**Rationale**: Consistent with standardized Completion Signal Protocol format

**Impact**: ~10 lines modified

### Recommendation 5: No Code Changes Required (INFORMATIONAL)

**Priority**: N/A

**Verification**: Implementation is unaffected by documentation format changes
- Hook already uses priority logic (plans > reports) ✓
- `/optimize-claude` command already emits correct signals ✓
- Testing validates correct behavior ✓

**Conclusion**: Pure documentation revision, no code changes

## Implementation Impact Assessment

### Changes Required

**File**: `/home/benjamin/.config/.claude/specs/851_001_buffer_opening_integration_planmd_the_claude/plans/001_001_buffer_opening_integration_planmd_th_plan.md`

**High Priority Changes**:
1. Line 42: Change signal format from "Multiple REPORT_CREATED + PLAN_CREATED" to "PLAN_CREATED: /path/to/plan.md" (Recommendation 1)
2. Line 44: Generalize clarification note to explain primary signal concept (Recommendation 2)

**Medium Priority Changes**:
3. After line 42: Add cross-reference note about Multi-Artifact Commands section (Recommendation 3)
4. Lines 565-577: Update user documentation template with consistent terminology (Recommendation 4)

### Total Impact

- **Lines changed**: ~15 lines
- **Lines added**: ~2 lines
- **Lines removed**: ~1 line
- **Net change**: ~16 lines modified

### Risk Assessment

**Risk Level**: VERY LOW

**Reasoning**:
- Documentation-only changes
- No code modifications required
- No testing changes required
- Improves consistency and clarity
- Aligns with existing pattern used by other commands

### Benefits

1. **Consistency**: All multi-artifact commands documented uniformly
2. **Clarity**: Primary signal concept explicitly defined
3. **Maintainability**: Future commands know which format to follow
4. **User Experience**: Reduces confusion about command differences
5. **Accuracy**: Still technically correct (PLAN_CREATED IS the primary signal)

## References

### Files Analyzed

1. **/home/benjamin/.config/.claude/specs/851_001_buffer_opening_integration_planmd_the_claude/plans/001_001_buffer_opening_integration_planmd_th_plan.md**
   - Lines 35-44: Completion Signal Protocol (primary change location)
   - Lines 149-152: Multi-Artifact Commands (verification)
   - Lines 565-577: User documentation template (update location)

2. **/home/benjamin/.config/.claude/commands/optimize-claude.md**
   - Line 287: Confirms PLAN_CREATED is the completion signal
   - Lines 119, 139, 196, 222: Intermediate REPORT_CREATED signals

3. **/home/benjamin/.config/.claude/commands/plan.md**
   - Line 393: Uses PLAN_CREATED as completion signal
   - Line 238: Emits REPORT_CREATED for research reports

4. **/home/benjamin/.config/.claude/commands/repair.md**
   - Line 371: Uses PLAN_CREATED as completion signal
   - Line 220: Emits REPORT_CREATED for error analysis

5. **/home/benjamin/.config/.claude/commands/revise.md**
   - Line 397: Emits REPORT_CREATED for revision research
   - Uses PLAN_REVISED as primary signal

### Pattern Verification

**Consistent Pattern Across Multi-Artifact Commands**:
- All create research reports before creating plans
- All emit REPORT_CREATED for intermediate reports
- All emit plan-type signal (PLAN_CREATED/PLAN_REVISED) as final, primary signal
- Documentation SHOULD show only primary signal in Completion Signal Protocol section
- Documentation SHOULD explain multi-artifact behavior in dedicated section (Multi-Artifact Commands)

**Current State**:
- `/plan`: ✓ Shows only PLAN_CREATED
- `/repair`: ✓ Shows only PLAN_CREATED
- `/revise`: ✓ Shows only PLAN_REVISED
- `/optimize-claude`: ✗ Shows "Multiple REPORT_CREATED + PLAN_CREATED" (inconsistent)

**Target State**:
- All four commands: ✓ Show only primary signal (PLAN_CREATED or PLAN_REVISED)
- Multi-Artifact Commands section: Explains detailed artifact creation for all four

## Conclusion

The user's request to change `/optimize-claude` signal documentation from `Multiple REPORT_CREATED + PLAN_CREATED` to just `PLAN_CREATED` is **valid and should be implemented**.

**Justification**:
1. **Consistency**: Creates uniform format matching `/plan`, `/repair`, `/revise`
2. **Accuracy**: PLAN_CREATED IS the primary completion signal for `/optimize-claude`
3. **Technical Correctness**: All multi-artifact commands emit research reports + plan signals; `/optimize-claude` is not unique
4. **Better Design**: "Primary signal only" pattern is cleaner than mixing detailed behavior in quick reference
5. **Proper Separation**: Completion Signal Protocol shows primary signals; Multi-Artifact Commands section explains detailed behavior
6. **User Experience**: Reduces confusion, guides users to detailed section when needed

**Implementation**: Documentation-only changes, no code modifications required. The hook implementation already correctly handles priority logic regardless of documentation format.

**Recommended Format**:
```markdown
2. **Completion Signal Protocol**: All workflow agents return standardized completion signals as final output:
   - `/plan` → `PLAN_CREATED: /path/to/plan.md`
   - `/research` → `REPORT_CREATED: /path/to/report.md`
   - `/build` → `SUMMARY_CREATED: /path/to/summary.md`
   - `/debug` → `DEBUG_REPORT_CREATED: /path/to/report.md`
   - `/repair` → `PLAN_CREATED: /path/to/plan.md`
   - `/revise` → `PLAN_REVISED: /path/to/plan.md`
   - `/optimize-claude` → `PLAN_CREATED: /path/to/plan.md`

**Clarification**: This protocol documents the **primary completion signal** for each command. Multi-artifact commands (like `/plan`, `/repair`, `/revise`, `/optimize-claude`) emit additional `REPORT_CREATED` signals for intermediate research reports, but the primary signal indicates the command's main output artifact. The hook opens only the primary artifact using priority logic (see Multi-Artifact Commands section).
```

---

**REPORT_CREATED**: /home/benjamin/.config/.claude/specs/851_001_buffer_opening_integration_planmd_the_claude/reports/005_optimize_claude_signal_format_revision.md
