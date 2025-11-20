# /optimize-claude and /revise Integration Research Report

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Integration requirements for /optimize-claude and /revise commands with hook-based buffer opening
- **Report Type**: codebase analysis
- **Workflow**: research-and-revise

## Implementation Status
- **Status**: Integrated into plan
- **Plan**: [../plans/001_001_buffer_opening_integration_planmd_th_plan.md](../plans/001_001_buffer_opening_integration_planmd_th_plan.md)
- **Date**: 2025-11-20

## Executive Summary

The /optimize-claude and /revise commands both create workflow artifacts (plans and reports) that should trigger automatic buffer opening in Neovim. This research analyzes both commands to determine integration requirements with the hook-based buffer opening system planned in spec 851. Both commands already use standardized completion signals (PLAN_CREATED, REPORT_CREATED) and would benefit from automatic artifact opening without requiring code modifications.

## Findings

### 1. /optimize-claude Command Analysis

**Location**: /home/benjamin/.config/.claude/commands/optimize-claude.md

**Architecture**: Multi-stage agent workflow (4 stages, 5 agents total)

**Workflow Stages**:
1. Stage 1: Parallel research (2 agents analyze CLAUDE.md and .claude/docs/)
2. Stage 2: Parallel analysis (2 agents perform bloat and accuracy analysis)
3. Stage 3: Sequential planning (1 agent generates optimization plan)
4. Stage 4: Display results

**Artifact Creation**:
- **Research Reports** (4 total):
  - `001_claude_md_analysis.md` (CLAUDE.md structure analysis)
  - `002_docs_structure_analysis.md` (docs directory analysis)
  - `003_bloat_analysis.md` (bloat prevention analysis)
  - `004_accuracy_analysis.md` (documentation accuracy analysis)
- **Implementation Plan** (1):
  - `001_optimization_plan.md` (final optimization plan)

**Completion Signals**:
- Research agents: `REPORT_CREATED: [exact absolute path]` (lines 119, 139, 196, 222)
- Planning agent: `PLAN_CREATED: [exact absolute path]` (line 288)

**Current Display Behavior** (lines 312-336):
- Shows all artifact paths in terminal output
- Suggests next step: `/implement $PLAN_PATH`
- Does NOT automatically open any artifacts

**Integration Impact**:
- Hook will receive multiple REPORT_CREATED signals followed by PLAN_CREATED
- Priority logic needed: Should open PLAN (primary artifact), not intermediate reports
- Expected behavior: Open optimization plan at completion (not each research report)

**Relevant Code References**:
- Agent invocation: Lines 106-141 (research), 176-224 (analysis), 257-289 (planning)
- Verification blocks: Lines 147-167 (research verify), 230-250 (analysis verify), 294-306 (plan verify)
- Results display: Lines 312-336

### 2. /revise Command Analysis

**Location**: /home/benjamin/.config/.claude/commands/revise.md

**Architecture**: Research-and-revise workflow (2 phases)

**Workflow Phases**:
1. Phase 1: Research (creates new research reports for revision insights)
2. Phase 2: Plan revision (modifies existing plan based on research)

**Artifact Creation**:
- **Research Reports** (variable count):
  - Created in `{specs_dir}/reports/` directory
  - Numbered sequentially (001, 002, etc.)
  - Agent returns: `REPORT_CREATED: [path to created report]` (line 358)
- **Revised Plan** (1):
  - Modifies existing plan in-place
  - Creates backup in `plans/backups/` directory
  - Agent returns: `PLAN_REVISED: ${EXISTING_PLAN_PATH}` (line 497)

**Completion Signals**:
- Research phase: `REPORT_CREATED: [path to created report]` (line 358)
- Plan revision phase: `PLAN_REVISED: ${EXISTING_PLAN_PATH}` (line 497)

**NOTE**: PLAN_REVISED is a unique completion signal not handled in current plan

**Current Display Behavior** (lines 591-603):
- Shows specs directory, report count, revised plan path, backup path
- Suggests next steps: review revised plan, compare with backup, implement
- Does NOT automatically open revised plan

**Integration Impact**:
- Hook will receive REPORT_CREATED signals then PLAN_REVISED
- New completion signal type: PLAN_REVISED (not currently in plan)
- Expected behavior: Open revised plan at completion (not research reports)
- Consider: Should both original plan backup AND revised plan open?

**Relevant Code References**:
- Research agent invocation: Lines 340-359
- Plan revision agent invocation: Lines 478-499
- Backup creation: Lines 448-470
- Verification logic: Lines 505-546
- Completion display: Lines 591-603

### 3. Completion Signal Protocol Analysis

**Current Plan Coverage** (from spec 851, lines 35-39):
- `/plan` → `PLAN_CREATED: /path/to/plan.md` ✓
- `/research` → `REPORT_CREATED: /path/to/report.md` ✓
- `/build` → `SUMMARY_CREATED: /path/to/summary.md` ✓
- `/debug` → `DEBUG_REPORT_CREATED: /path/to/report.md` ✓
- `/repair` → `PLAN_CREATED: /path/to/plan.md` ✓

**Missing from Current Plan**:
- `/optimize-claude` → Multiple REPORT_CREATED + PLAN_CREATED ❌ (workflow, not documented)
- `/revise` → REPORT_CREATED + **PLAN_REVISED** ❌ (unique signal type)

**Required Updates**:
1. Add PLAN_REVISED to completion signal regex patterns (Phase 4, line 287)
2. Document /optimize-claude in command list (line 59)
3. Document /revise and PLAN_REVISED signal in completion protocol

### 4. Hook Execution Context

**Multi-Artifact Command Handling**:

Both commands create multiple artifacts during execution:

**Challenge**: How should hook handle multiple completion signals?
- /optimize-claude: 4x REPORT_CREATED, then 1x PLAN_CREATED
- /revise: Nx REPORT_CREATED, then 1x PLAN_REVISED

**Current Plan Solution** (lines 172-174, 287-289):
- Terminal output access via `nvim --remote-expr 'getbufline(...)'`
- Completion signal extraction with priority logic
- Priority: PLAN_CREATED > SUMMARY_CREATED > DEBUG_REPORT_CREATED > REPORT_CREATED

**Required Enhancement**:
- Add PLAN_REVISED to priority list (same priority as PLAN_CREATED)
- Updated priority: (PLAN_CREATED | PLAN_REVISED) > SUMMARY_CREATED > DEBUG_REPORT_CREATED > REPORT_CREATED

### 5. Terminal Output Parsing Requirements

**Hook Trigger Timing**:
- Stop hook fires AFTER command completes (all agents finished)
- Terminal buffer contains ALL agent outputs (research + planning)
- Hook must parse entire output to find primary artifact

**Expected Terminal Output Pattern** (/optimize-claude):
```
=== /optimize-claude: CLAUDE.md Optimization Workflow ===
[Agent 1 output]
REPORT_CREATED: /path/to/001_claude_md_analysis.md
[Agent 2 output]
REPORT_CREATED: /path/to/002_docs_structure_analysis.md
[Agent 3 output]
REPORT_CREATED: /path/to/003_bloat_analysis.md
[Agent 4 output]
REPORT_CREATED: /path/to/004_accuracy_analysis.md
[Agent 5 output]
PLAN_CREATED: /path/to/001_optimization_plan.md
[Results display]
```

**Expected Terminal Output Pattern** (/revise):
```
=== Research-and-Revise Workflow ===
[Research agent output]
REPORT_CREATED: /path/to/001_revision_insights.md
[Plan revision agent output]
PLAN_REVISED: /path/to/001_existing_plan.md
[Completion display]
```

**Parsing Strategy**:
1. Read last 100 lines of terminal buffer (optimization, line 285)
2. Extract ALL completion signals via regex
3. Apply priority logic to select primary artifact
4. Validate file exists before opening

### 6. User Experience Considerations

**Current Manual Workflow**:
1. User runs `/optimize-claude` or `/revise` in Neovim terminal
2. Command completes, shows artifact paths
3. User manually opens plan: `:e /path/to/plan.md`
4. User switches between terminal and plan buffer

**With Automatic Opening**:
1. User runs `/optimize-claude` or `/revise` in Neovim terminal
2. Command completes
3. **Hook automatically opens plan in vsplit** (terminal context)
4. User can immediately review plan alongside terminal

**Benefits**:
- Eliminates manual path copying from terminal output
- Immediate access to primary artifact (plan)
- Preserves terminal for reference
- Consistent with expected behavior for /plan, /build, /debug, /repair

### 7. Edge Cases and Considerations

**Edge Case 1**: Agent fails to create plan
- /optimize-claude verification blocks (lines 295-306) will catch missing plan
- Command exits with error before hook fires
- No buffer opening attempted (correct behavior)

**Edge Case 2**: Multiple rapid /optimize-claude executions
- Each execution creates new topic directory (via unified-location-detection)
- Each Stop event is independent
- No collision risk (each has unique artifact paths)

**Edge Case 3**: /revise modifying plan while user has it open
- Backup created before modification (line 455)
- Neovim detects file change, prompts to reload
- Hook opens same path that's already open
- Neovim handles gracefully (reloads buffer)

**Edge Case 4**: User disables buffer opener after /optimize-claude starts
- Hook checks BUFFER_OPENER_ENABLED at execution time (after command completes)
- If disabled mid-execution, hook respects setting
- No automatic opening occurs

## Recommendations

### Recommendation 1: Add PLAN_REVISED Completion Signal Support

**Priority**: CRITICAL

**Rationale**: /revise command uses PLAN_REVISED signal not covered in current plan

**Implementation**:
- Add PLAN_REVISED to completion signal regex patterns (Phase 4, line 287)
- Update priority logic to treat PLAN_REVISED same as PLAN_CREATED
- Test with /revise workflow

**Location**: Phase 4 completion signal extraction logic

**Code Change**:
```bash
# Current (line 287):
PRIMARY_ARTIFACT=$(echo "$OUTPUT" | grep -oP '(PLAN_CREATED|SUMMARY_CREATED|DEBUG_REPORT_CREATED|REPORT_CREATED):\s*\K.*')

# Updated:
PRIMARY_ARTIFACT=$(echo "$OUTPUT" | grep -oP '(PLAN_CREATED|PLAN_REVISED|SUMMARY_CREATED|DEBUG_REPORT_CREATED|REPORT_CREATED):\s*\K.*')
```

### Recommendation 2: Document Multi-Artifact Command Behavior

**Priority**: HIGH

**Rationale**: /optimize-claude creates 5 artifacts but should only open primary (plan)

**Implementation**:
- Add /optimize-claude to eligible commands list (line 59)
- Document priority logic for multi-artifact commands
- Add example in Phase 4 testing (lines 296-313)

**Location**: Success Criteria section, Testing Strategy section

**Documentation Addition**:
```markdown
## Multi-Artifact Command Handling

Commands that create multiple artifacts (/optimize-claude, /plan) benefit from priority logic:
1. Research reports created first (REPORT_CREATED signals)
2. Implementation plan created last (PLAN_CREATED signal)
3. Hook opens only primary artifact (plan), not intermediate reports
```

### Recommendation 3: Test with /optimize-claude Workflow

**Priority**: HIGH

**Rationale**: Ensure hook correctly handles 4 research reports + 1 plan

**Implementation**:
- Add /optimize-claude to Phase 5 integration testing (lines 326-340)
- Verify only optimization plan opens (not 4 research reports)
- Test terminal buffer parsing with multi-agent output

**Test Case**:
```bash
# Test /optimize-claude workflow (multi-artifact)
cd /home/benjamin/.config
nvim -c "ClaudeCode"
# Run: /optimize-claude
# Expected: Only 001_optimization_plan.md opens (not 4 research reports)
# Verify: vsplit shows plan, terminal buffer remains visible
```

### Recommendation 4: Test with /revise Workflow

**Priority**: HIGH

**Rationale**: Validate PLAN_REVISED signal handling and backup interaction

**Implementation**:
- Add /revise to Phase 5 integration testing
- Test revised plan opening (not research reports)
- Verify behavior when plan already open (reload prompt)

**Test Case**:
```bash
# Test /revise workflow (plan revision)
cd /home/benjamin/.config
nvim -c "ClaudeCode"
# First open existing plan: :e .claude/specs/123_topic/plans/001_plan.md
# Run: /revise "revise plan at .claude/specs/123_topic/plans/001_plan.md based on new requirements"
# Expected: Neovim prompts to reload buffer, hook opens same plan
# Verify: Buffer reloaded with revisions
```

### Recommendation 5: Add Configuration for Primary Artifact Selection

**Priority**: LOW (future enhancement)

**Rationale**: Some users might want research reports to open instead of plans

**Implementation** (not in current scope):
- Add BUFFER_OPENER_PRIORITY environment variable
- Default: "plan" (current behavior)
- Alternative: "all" (open all artifacts), "latest" (last signal only)

**Example**:
```bash
export BUFFER_OPENER_PRIORITY="all"  # Opens all artifacts in order
export BUFFER_OPENER_PRIORITY="plan" # Opens only plans/summaries (default)
```

## References

### Files Analyzed

1. **/home/benjamin/.config/.claude/commands/optimize-claude.md**
   - Lines 1-348: Complete command implementation
   - Lines 106-141: Research agent invocations
   - Lines 176-224: Analysis agent invocations
   - Lines 257-289: Planning agent invocation
   - Lines 312-336: Results display

2. **/home/benjamin/.config/.claude/commands/revise.md**
   - Lines 1-620: Complete command implementation
   - Lines 340-359: Research agent invocation (REPORT_CREATED)
   - Lines 478-499: Plan revision agent invocation (PLAN_REVISED)
   - Lines 448-470: Backup creation logic
   - Lines 591-603: Completion display

3. **/home/benjamin/.config/.claude/specs/851_001_buffer_opening_integration_planmd_the_claude/plans/001_001_buffer_opening_integration_planmd_th_plan.md**
   - Lines 35-39: Documented completion signal protocol (missing PLAN_REVISED)
   - Lines 172-174: Terminal output access implementation
   - Lines 287-289: Completion signal extraction with priority
   - Lines 296-313: Testing section (needs /optimize-claude and /revise)

### External References

- Claude Code Stop Hook Documentation: Hook fires after command completion
- Agent Completion Signal Protocol: Standardized output format for all workflow agents
- Neovim Remote API: `nvim --remote-expr` for terminal buffer access

### Related Specifications

- Spec 848: File watcher approach (superseded by hook-based approach)
- Error Handling Pattern: /home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md
- Agent Reference: /home/benjamin/.config/.claude/docs/reference/standards/agent-reference.md

## Appendix: Completion Signal Priority Logic

**Priority Order** (highest to lowest):
1. **PLAN_CREATED** - Primary artifact from /plan, /optimize-claude, /repair
2. **PLAN_REVISED** - Primary artifact from /revise (MISSING IN CURRENT PLAN)
3. **SUMMARY_CREATED** - Primary artifact from /build
4. **DEBUG_REPORT_CREATED** - Primary artifact from /debug
5. **REPORT_CREATED** - Intermediate artifact from research phases

**Implementation Pattern**:
```bash
# Extract all signals
ALL_SIGNALS=$(echo "$OUTPUT" | grep -oP '(PLAN_CREATED|PLAN_REVISED|SUMMARY_CREATED|DEBUG_REPORT_CREATED|REPORT_CREATED):\s*\K.*')

# Apply priority (first match wins)
PRIMARY_ARTIFACT=$(echo "$ALL_SIGNALS" | grep -P 'PLAN_(CREATED|REVISED):' | head -1)
[ -z "$PRIMARY_ARTIFACT" ] && PRIMARY_ARTIFACT=$(echo "$ALL_SIGNALS" | grep 'SUMMARY_CREATED:' | head -1)
[ -z "$PRIMARY_ARTIFACT" ] && PRIMARY_ARTIFACT=$(echo "$ALL_SIGNALS" | grep 'DEBUG_REPORT_CREATED:' | head -1)
[ -z "$PRIMARY_ARTIFACT" ] && PRIMARY_ARTIFACT=$(echo "$ALL_SIGNALS" | grep 'REPORT_CREATED:' | head -1)
```

**Rationale**:
- Plans are implementation-ready, most valuable to user
- Summaries are implementation results, second most valuable
- Debug reports are diagnostic, third priority
- Research reports are intermediate, lowest priority (user can access via command picker)
