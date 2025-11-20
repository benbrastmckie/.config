# Buffer Opening Revision Research Report

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Plan revision insights for /optimize-claude buffer opening behavior
- **Report Type**: codebase analysis + requirement clarification
- **Workflow**: revise

## Executive Summary

Research conducted to inform plan revision for two key requirements: (1) /optimize-claude should only open the final plan when finished, not intermediate research reports, and (2) documentation should explicitly state that at most one file opens per command execution. Analysis reveals the existing plan already implements priority logic (lines 133-148) that opens only the primary artifact (plan) and ignores intermediate reports, which satisfies requirement 1. However, the plan lacks explicit documentation of the "one file per command" constraint in user-facing sections (Phase 6 documentation), requiring clarification in multiple locations.

## Findings

### 1. Current State of Priority Logic

**Location**: /home/benjamin/.config/.claude/specs/851_001_buffer_opening_integration_planmd_the_claude/plans/001_001_buffer_opening_integration_planmd_th_plan.md

**Existing Priority Table** (lines 133-148):
The plan already defines completion signal priority levels:

| Priority | Signal Type | Commands | Purpose |
|----------|-------------|----------|---------|
| 1 (Highest) | PLAN_CREATED | /plan, /repair, /optimize-claude | Implementation plans |
| 1 (Highest) | PLAN_REVISED | /revise | Revised implementation plans |
| 2 | SUMMARY_CREATED | /build | Implementation summaries |
| 3 | DEBUG_REPORT_CREATED | /debug | Debug analysis reports |
| 4 (Lowest) | REPORT_CREATED | /research, /plan, /repair, /revise, /optimize-claude | Research reports (intermediate) |

**Multi-Artifact Commands Documentation** (lines 144-148):
The plan explicitly states:
- `/plan`: Creates 1-4 research reports, then 1 implementation plan → Opens **plan only**
- `/optimize-claude`: Creates 4 research reports, then 1 optimization plan → Opens **plan only**
- `/revise`: Creates 0-N research reports, then 1 revised plan → Opens **revised plan only**
- `/repair`: Creates 1 error analysis report, then 1 repair plan → Opens **repair plan only**

**Conclusion**: The technical design already satisfies the requirement that /optimize-claude only opens the final plan. The priority logic ensures PLAN_CREATED signals take precedence over REPORT_CREATED signals.

### 2. /optimize-claude Command Analysis

**Location**: /home/benjamin/.config/.claude/commands/optimize-claude.md

**Workflow Stages** (lines 14-17):
1. Stage 1: Parallel research (2 agents) → 2 REPORT_CREATED signals
2. Stage 2: Parallel analysis (2 agents) → 2 REPORT_CREATED signals
3. Stage 3: Sequential planning (1 agent) → 1 PLAN_CREATED signal
4. Stage 4: Display results

**Expected Terminal Output Pattern**:
```
=== /optimize-claude: CLAUDE.md Optimization Workflow ===
[Agent output...]
REPORT_CREATED: /path/001_claude_md_analysis.md
REPORT_CREATED: /path/002_docs_structure_analysis.md
REPORT_CREATED: /path/003_bloat_analysis.md
REPORT_CREATED: /path/004_accuracy_analysis.md
PLAN_CREATED: /path/001_optimization_plan.md
[Results display...]
```

**Hook Behavior with Priority Logic**:
When the Stop hook fires and parses terminal output:
1. Hook extracts all completion signals (4x REPORT_CREATED, 1x PLAN_CREATED)
2. Hook applies priority logic: PLAN_CREATED (priority 1) > REPORT_CREATED (priority 4)
3. Hook opens ONLY the plan at `/path/001_optimization_plan.md`
4. Research reports remain accessible via command picker but do not auto-open

**Verification**: This behavior matches the user's requirement exactly.

### 3. Documentation Gap Analysis

**Problem**: While the technical design correctly implements "one file per command" behavior, this constraint is not explicitly documented in user-facing sections.

**Current Documentation Locations**:

**Phase 6: Documentation Tasks** (lines 421-438):
```markdown
- [ ] Add "Automatic Artifact Opening" section to README
- [ ] Document how hook-based opening works
- [ ] Document behavior in different contexts
- [ ] Document primary artifact selection logic  # ← Implicit, needs explicit one-file constraint
- [ ] Add configuration reference
- [ ] Add troubleshooting section
- [ ] Document differences from file watcher approach
```

**User Documentation Requirements** (lines 555-567):
```markdown
Required sections:
- **Feature Overview**: How automatic artifact opening works  # ← Should state one-file constraint
- **Setup**: Hook registration process
- **Behavior**: What happens after each command type  # ← Should state one-file-per-command
- **Primary Artifact Selection**: Why plans open instead of reports  # ← Exists but not explicit enough
- **Configuration**: How to enable/disable feature
- **Troubleshooting**: Common issues and solutions
- **Limitations**: Requires running inside Neovim terminal
```

**Developer Documentation** (lines 569-594):
Hook script comments document the architecture but do not explicitly state the one-file constraint.

**Hook Documentation** (lines 596-626):
`.claude/hooks/README.md` entry describes the hook's purpose but lacks the one-file guarantee.

**Gap Summary**:
- Technical implementation is correct (priority logic ensures one file)
- User-facing documentation needs explicit "at most one file per command" statement
- Multiple locations need clarification: Feature Overview, Behavior section, Primary Artifact Selection

### 4. Testing Coverage Analysis

**Phase 4: Terminal Output Access Refinement** (lines 308-353):
Testing includes /optimize-claude workflow:
```bash
# Test /optimize-claude command (multiple reports + plan)
# Run: /optimize-claude
# Verify only optimization plan opens (not 4 research reports)
```

**Phase 5: Integration Testing** (lines 359-412):
Includes /optimize-claude testing:
```bash
# Test /optimize-claude workflow (multi-artifact)
# Expected: Only 001_optimization_plan.md opens (not 4 research reports)
# Verify: vsplit shows plan, terminal buffer remains visible
```

**Verification**: Testing already validates the one-file behavior for /optimize-claude. No additional tests needed.

### 5. Implementation Details for Priority Logic

**Phase 4 Tasks** (lines 314-322):
```markdown
- [ ] Implement completion signal regex patterns for all workflow commands (including PLAN_REVISED)
- [ ] Implement priority extraction (plans/plan_revised > summaries > reports)
- [ ] Add handling for multiple completion signals in same output
- [ ] Test with various command outputs (/plan, /research, /build, /debug, /repair, /revise, /optimize-claude)
```

**Expected Implementation** (referenced in report 002, lines 376-386):
```bash
# Extract all signals
ALL_SIGNALS=$(echo "$OUTPUT" | grep -oP '(PLAN_CREATED|PLAN_REVISED|SUMMARY_CREATED|DEBUG_REPORT_CREATED|REPORT_CREATED):\s*\K.*')

# Apply priority (first match wins)
PRIMARY_ARTIFACT=$(echo "$ALL_SIGNALS" | grep -P 'PLAN_(CREATED|REVISED):' | head -1)
[ -z "$PRIMARY_ARTIFACT" ] && PRIMARY_ARTIFACT=$(echo "$ALL_SIGNALS" | grep 'SUMMARY_CREATED:' | head -1)
[ -z "$PRIMARY_ARTIFACT" ] && PRIMARY_ARTIFACT=$(echo "$ALL_SIGNALS" | grep 'DEBUG_REPORT_CREATED:' | head -1)
[ -z "$PRIMARY_ARTIFACT" ] && PRIMARY_ARTIFACT=$(echo "$ALL_SIGNALS" | grep 'REPORT_CREATED:' | head -1)
```

**Verification**: The `head -1` ensures only ONE file path is selected, even if multiple PLAN_CREATED signals exist (edge case protection).

## Recommendations

### Recommendation 1: Add Explicit One-File Constraint to User Documentation (CRITICAL)

**Priority**: CRITICAL

**Rationale**: User's requirement explicitly states documentation should include "at most one file is to be opened in a buffer when automatic artifact opening is used."

**Implementation**:
Add explicit one-file constraint to Phase 6 documentation tasks (lines 421-438):

```markdown
**Tasks**:
- [ ] Add "Automatic Artifact Opening" section to README
- [ ] Document one-file-per-command constraint explicitly in Feature Overview
- [ ] Document how hook-based opening works
- [ ] Document behavior in different contexts (Neovim terminal vs external)
- [ ] Document primary artifact selection logic with one-file guarantee
- [ ] Add configuration reference (enabling/disabling feature)
- [ ] Add troubleshooting section:
  - Artifacts not opening automatically
  - Wrong file opens (should never be more than one)
  - Hook execution errors
  - Performance issues
```

**Specific Documentation Text to Add**:

**Feature Overview section**:
```markdown
## Automatic Artifact Opening

When running Claude Code workflow commands (/plan, /build, /optimize-claude, etc.) inside
a Neovim terminal, the hook-based buffer opener automatically opens the primary artifact
after command completion.

**Key Guarantee**: At most one file opens per command execution. For commands that create
multiple artifacts (/optimize-claude creates 4 research reports + 1 plan), the hook uses
priority logic to select only the primary artifact (the plan).
```

**Behavior section**:
```markdown
## Behavior by Command Type

| Command | Artifacts Created | File Opened (One Only) |
|---------|-------------------|------------------------|
| /plan | 1-4 research reports + 1 plan | Plan only |
| /optimize-claude | 4 research reports + 1 plan | Plan only |
| /build | 1 summary | Summary |
| /revise | 0-N research reports + 1 plan | Revised plan only |
| /research | 1 research report | Research report |
| /debug | 1 debug report | Debug report |
| /repair | 1 error analysis + 1 plan | Plan only |

**One-File Guarantee**: The hook ensures exactly one buffer opens, even for multi-artifact
commands. Intermediate artifacts (research reports) remain accessible via command picker.
```

**Primary Artifact Selection section**:
```markdown
## Primary Artifact Selection

The hook uses priority logic to ensure only one file opens:

1. **Plans** (PLAN_CREATED, PLAN_REVISED) - Highest priority
2. **Summaries** (SUMMARY_CREATED) - Second priority
3. **Debug Reports** (DEBUG_REPORT_CREATED) - Third priority
4. **Research Reports** (REPORT_CREATED) - Lowest priority (usually intermediate)

This guarantees at most one file opens per command execution, with the most valuable
artifact selected automatically.
```

### Recommendation 2: Clarify Hook Script Comments (HIGH)

**Priority**: HIGH

**Rationale**: Developer documentation should also state the one-file constraint for maintainability.

**Implementation**:
Update Phase 6 developer documentation (lines 573-594) to include:

```bash
#!/usr/bin/env bash
# Post-Buffer-Opener Hook
# Purpose: Automatically open primary workflow artifacts in Neovim after command completion
#
# One-File Guarantee: Hook ensures at most one buffer opens per command execution
#
# Architecture:
#   1. Claude Code Stop hook triggers after command completes
#   2. Parse JSON input to get command name and status
#   3. Access terminal buffer output via Neovim RPC
#   4. Extract ALL completion signals from output
#   5. Apply priority logic to select PRIMARY artifact only (one file)
#   6. Open selected artifact in Neovim via RPC (if available)
#
# Priority Logic:
#   PLAN_CREATED/PLAN_REVISED (priority 1) > SUMMARY_CREATED (priority 2) >
#   DEBUG_REPORT_CREATED (priority 3) > REPORT_CREATED (priority 4)
#
#   Example: /optimize-claude creates 4 REPORT_CREATED + 1 PLAN_CREATED
#            → Hook opens ONLY the plan (priority 1 wins)
```

### Recommendation 3: Add One-File Constraint to Hook README Entry (MEDIUM)

**Priority**: MEDIUM

**Rationale**: `.claude/hooks/README.md` should document the guarantee for users browsing hook directory.

**Implementation**:
Update Phase 6 hook documentation (lines 600-626) to include:

```markdown
### post-buffer-opener.sh
**Purpose**: Automatically open workflow artifacts in Neovim after command completion

**Triggered By**: Stop event

**One-File Guarantee**: Opens at most one file per command execution, selecting the primary
artifact via priority logic (plans > summaries > debug reports > research reports).

**Input** (via JSON stdin):
- `hook_event_name`: "Stop"
- `command`: Command that was executed
- `status`: "success" or "error"
- `cwd`: Working directory

**Actions**:
1. Check if running inside Neovim terminal ($NVIM)
2. Access terminal buffer output via RPC
3. Extract ALL completion signals (may be multiple)
4. Select PRIMARY artifact only (one file) using priority logic
5. Open selected artifact in Neovim with context-aware behavior

**Example**: When /optimize-claude creates 4 research reports + 1 plan, hook opens only the plan.
```

### Recommendation 4: Add Success Criterion for One-File Constraint (LOW)

**Priority**: LOW (quality improvement)

**Rationale**: Success criteria should explicitly verify the one-file constraint.

**Implementation**:
Add success criterion to lines 61-73:

```markdown
- [ ] Hook opens at most one file per command execution (verified with /optimize-claude)
- [ ] Priority logic correctly selects primary artifact from multiple signals
- [ ] Intermediate artifacts (research reports) do not auto-open for multi-artifact commands
```

### Recommendation 5: No Code Changes Required (INFORMATIONAL)

**Priority**: N/A (informational)

**Rationale**: The existing implementation already satisfies the user's functional requirements.

**Verification**:
- Priority logic (lines 133-148): Ensures one file selection ✓
- Multi-artifact handling (lines 144-148): Documents /optimize-claude opens plan only ✓
- Testing coverage (Phase 4, Phase 5): Validates /optimize-claude behavior ✓
- Implementation plan (Phase 4, lines 318-319): Includes priority extraction logic ✓

**Conclusion**: Only documentation needs updating, not code implementation.

## References

### Files Analyzed

1. **/home/benjamin/.config/.claude/specs/851_001_buffer_opening_integration_planmd_the_claude/plans/001_001_buffer_opening_integration_planmd_th_plan.md**
   - Lines 133-148: Completion signal priority logic (technical design)
   - Lines 205: Priority extraction implementation task
   - Lines 318-322: Completion signal regex pattern tasks
   - Lines 327-353: /optimize-claude testing in Phase 4
   - Lines 370-377: /optimize-claude testing in Phase 5
   - Lines 421-438: Phase 6 documentation tasks (needs one-file constraint)
   - Lines 555-567: User documentation requirements (needs explicit constraint)
   - Lines 569-594: Developer documentation template (needs one-file constraint)
   - Lines 596-626: Hook README entry (needs one-file constraint)

2. **/home/benjamin/.config/.claude/specs/851_001_buffer_opening_integration_planmd_the_claude/reports/002_optimize_revise_integration_research.md**
   - Lines 21-60: /optimize-claude command analysis
   - Lines 51-54: Integration impact (priority logic needed)
   - Lines 149-163: Expected terminal output pattern
   - Lines 189-199: User experience with automatic opening
   - Lines 224-246: Recommendation 1 (PLAN_REVISED support)
   - Lines 248-269: Recommendation 2 (multi-artifact documentation)
   - Lines 376-393: Appendix with priority logic implementation example

3. **/home/benjamin/.config/.claude/commands/optimize-claude.md**
   - Lines 1-99: Command implementation overview
   - Lines 14-17: Four-stage workflow (creates 4 reports + 1 plan)
   - Lines 106-289: Agent execution with completion signals

### External References

- User requirement: "/optimize-claude to only open the plan when finished"
- User requirement: "documentation should include that at most one file is to be opened in a buffer when automatic artifact opening is used"
- Priority logic pattern: First-match-wins with signal type ordering
- Claude Code hooks: Stop event fires after command completion with JSON input
