# Strengthen /research Command Enforcement - Minimal Critical Improvements

## Metadata
- **Date**: 2025-10-24
- **Revision Date**: 2025-10-24
- **Feature**: Minimal critical improvements to /research command enforcement
- **Scope**: Target high-impact, low-bloat enhancements to existing enforcement patterns
- **Estimated Phases**: 2 (reduced from 4)
- **Complexity**: Low-Medium (reduced from Medium-High)
- **Estimated Time**: 2-3 hours (reduced from 8-10 hours)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Related Plans**:
  - Plan 444: `/home/benjamin/.config/.claude/specs/444_research_allowed_tools_fix/plans/001_fix_research_command_allowed_tools.md` (tool restriction approach)
- **Research Reports**:
  - [Research Overview](../../467_the_research_command_to_see_if_homebenjaminconfigc/reports/001_research_command_tool_restrictions_analysis_research/OVERVIEW.md)
  - [Alternative Enforcement Mechanisms](../../467_the_research_command_to_see_if_homebenjaminconfigc/reports/001_research_command_tool_restrictions_analysis_research/002_alternative_enforcement_mechanisms.md)

## Revision History

### 2025-10-24 - Revision 1: Streamline for Minimal Critical Changes
**Changes**:
- Reduced from 4 phases to 2 phases
- Removed fallback-dependent features (per user request)
- Eliminated bloat: removed triple verification checkpoints
- Focused on highest-impact improvements only
- Reduced implementation time from 8-10 hours to 2-3 hours

**Reason**: User wants to avoid fallbacks and bloat while making critical but minimal improvements

**Modified Phases**:
- ~~Phase 1: Role Clarification~~ → **Kept** (critical, high impact)
- ~~Phase 2: Triple Verification Checkpoints~~ → **Removed** (bloat, fallback-dependent)
- ~~Phase 3: Enhance Behavioral Injection~~ → **Merged into Phase 2** (streamlined)
- ~~Phase 4: Testing~~ → **Simplified** (basic validation only)

## Overview

This plan focuses on **critical, minimal improvements** to the `/research` command's enforcement patterns, avoiding fallback mechanisms and unnecessary verbosity.

**Current State Analysis**:
The `/research` command already has strong enforcement:
- ✓ Role clarification present ("YOUR ROLE: You are the ORCHESTRATOR")
- ✓ Execution markers present (13+ "EXECUTE NOW" markers)
- ✓ Verification checkpoints present (6+ "MANDATORY VERIFICATION")
- ✓ Behavioral injection via agent file references
- ✓ Path pre-calculation before agent invocation

**Gaps Identified** (High-Impact, Low-Effort):
1. **Subagent role ambiguity**: Agent prompts don't clarify orchestrator vs subagent distinction
2. **Phase-based tool guidance unclear**: No explicit guidance on when to use which tools

**Out of Scope** (Per User Requirements):
- ❌ Fallback mechanisms (user wants to avoid fallbacks)
- ❌ Triple verification checkpoints (bloat)
- ❌ Extensive testing infrastructure (overkill)
- ❌ Comprehensive audit compliance (not critical)

**This Plan's Approach**:
- **Phase 1**: Add subagent role clarification to agent prompts (15 lines, high impact)
- **Phase 2**: Add phase-based tool guidance to orchestrator instructions (10 lines, clarity improvement)
- **Total additions**: ~25 lines to command file
- **Implementation time**: 2-3 hours including testing

## Success Criteria
- [x] Subagent prompts include role clarification (orchestrator vs subagent)
- [x] Orchestrator instructions clarify phase-based tool usage
- [x] Zero regression in file creation rate
- [x] Minimal additions to command file (<30 lines) - Actual: 17 lines
- [x] Implementation time ≤3 hours

## Technical Design

### Current Strengths (Preserve)

The command already has:
1. **Role Clarification** (lines 13-20): Orchestrator role explicit
2. **Execution Markers** (13+): "EXECUTE NOW" for critical operations
3. **Verification Checkpoints** (6+): "MANDATORY VERIFICATION" for file checks
4. **Path Pre-Calculation** (lines 79-160): All paths calculated before delegation
5. **Behavioral Injection** (lines 178+): Agent files referenced

### Gap 1: Subagent Role Ambiguity

**Problem**: Agent prompts don't explicitly state subagent role, leading to potential confusion about orchestrator vs subagent responsibilities.

**Current** (lines 181-225):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research [SUBTOPIC] with mandatory artifact creation"
  timeout: 300000
  prompt: "
    **ABSOLUTE REQUIREMENT - File Creation is Your Primary Task**

    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent with the tools and constraints
    defined in that file.

    **Research Topic**: [SUBTOPIC_DISPLAY_NAME]
    **Report Path**: [ABSOLUTE_PATH_FROM_SUBTOPIC_REPORT_PATHS]

    **STEP 1 (MANDATORY)**: Verify you received the absolute report path above.
    **STEP 2 (EXECUTE NOW)**: Create report file at EXACT path using Write tool.
    **STEP 3 (REQUIRED)**: Conduct research and update report file.
    **STEP 4 (ABSOLUTE REQUIREMENT)**: Verify file exists and return:
    REPORT_CREATED: [EXACT_ABSOLUTE_PATH]
  "
}
```

**Enhancement** (+7 lines):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research [SUBTOPIC] with mandatory artifact creation"
  timeout: 300000
  prompt: "
    **ABSOLUTE REQUIREMENT - File Creation is Your Primary Task**

    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent with the tools and constraints
    defined in that file.

    **YOUR ROLE**: You are a SUBAGENT executing research for ONE subtopic.
    - The ORCHESTRATOR calculated your report path (injected below)
    - DO NOT use Task tool to orchestrate other agents
    - STAY IN YOUR LANE: Research YOUR subtopic only

    **Research Topic**: [SUBTOPIC_DISPLAY_NAME]
    **Report Path**: [ABSOLUTE_PATH_FROM_SUBTOPIC_REPORT_PATHS]

    **STEP 1 (MANDATORY)**: Verify you received the absolute report path above.
    **STEP 2 (EXECUTE NOW)**: Create report file at EXACT path using Write tool.
    **STEP 3 (REQUIRED)**: Conduct research and update report file.
    **STEP 4 (ABSOLUTE REQUIREMENT)**: Verify file exists and return:
    REPORT_CREATED: [EXACT_ABSOLUTE_PATH]
  "
}
```

**Impact**: High (prevents agent confusion)
**Effort**: Low (7 lines added)
**Locations**: 2 agent invocations (research-specialist, research-synthesizer)

### Gap 2: Phase-Based Tool Guidance Unclear

**Problem**: Orchestrator instructions don't clarify when to use which tools (delegation phase vs verification phase).

**Current** (lines 15-17):
```markdown
**CRITICAL INSTRUCTIONS**:
- DO NOT execute research yourself using Read/Grep/Write tools
- ONLY use Task tool to delegate research to research-specialist agents
- Your job: decompose topic → invoke agents → verify outputs → synthesize
```

**Enhancement** (+8 lines):
```markdown
**CRITICAL INSTRUCTIONS**:
- DO NOT execute research yourself using Read/Grep/Write tools
- ONLY use Task tool to delegate research to research-specialist agents
- Your job: decompose topic → invoke agents → verify outputs → synthesize

**PHASE-BASED TOOL USAGE**:
1. **Delegation Phase** (Steps 1-3): Use Task + Bash only
   - Decompose topic, calculate paths, invoke agents
   - DO NOT use Read/Write for research activities
2. **Verification Phase** (Steps 4-6): Use Bash + Read for verification
   - Verify files exist, check completion, synthesize overview
   - Read tool for analysis only, NOT for direct research
```

**Impact**: Medium (improves clarity)
**Effort**: Low (8 lines added)
**Location**: Orchestrator instructions (after line 17)

### Architecture: No Fallbacks

**Decision**: Do NOT add fallback mechanisms per user requirements.

**Rationale**:
- User wants consistency (all files created by agents, none by orchestrator)
- Fallbacks create inconsistency (some files by agents, some by fallback)
- Agent file creation should be reliable enough without fallbacks
- If agent fails, workflow should fail fast (not mask failure)

**Trade-off Accepted**:
- File creation rate may drop from 100% to 95-98%
- Acceptable per user's consistency preference
- Failed agent invocations will be visible and debuggable

### No Verification Bloat

**Decision**: Keep existing single verification checkpoint, do NOT add triple checkpoints.

**Rationale**:
- Current verification (file existence check) is sufficient
- Size and readability checks are overkill
- User wants minimal additions, not comprehensive validation

**Current Verification** (lines 234-287):
```bash
# Verify each subtopic report exists
for subtopic in "${!SUBTOPIC_REPORT_PATHS[@]}"; do
  if [ -f "$EXPECTED_PATH" ]; then
    echo "✓ Verified: $subtopic at $EXPECTED_PATH"
  fi
done
```

**Keep as-is** (sufficient for minimal improvements)

## Implementation Phases

### Phase 1: Add Subagent Role Clarification [COMPLETED]
**Objective**: Clarify orchestrator vs subagent roles in agent prompts
**Complexity**: Low
**Estimated Time**: 1 hour

Tasks:
- [x] Add subagent role clarification to research-specialist invocation template (lines 181-225)
  - Add 3-line "YOUR ROLE" section
  - Add "DO NOT orchestrate other agents" instruction
  - Add "STAY IN YOUR LANE" reminder
- [x] Add subagent role clarification to research-synthesizer invocation template (lines 321-360)
  - Same pattern as research-specialist
- [x] Test agent invocations still work correctly
- [x] Verify agents don't attempt orchestration

**File**: `/home/benjamin/.config/.claude/commands/research.md`

**Code Changes**:

**Location 1: Research-Specialist Template** (After line 191, before "**Research Topic**:"):
```markdown
**YOUR ROLE**: You are a SUBAGENT executing research for ONE subtopic.
- The ORCHESTRATOR calculated your report path (injected below)
- DO NOT use Task tool to orchestrate other agents
- STAY IN YOUR LANE: Research YOUR subtopic only
```

**Location 2: Research-Synthesizer Template** (After line 331, before "**Overview Report Path**:"):
```markdown
**YOUR ROLE**: You are a SUBAGENT synthesizing research findings.
- The ORCHESTRATOR created all subtopic reports (paths injected below)
- DO NOT use Task tool to orchestrate other agents
- STAY IN YOUR LANE: Synthesize findings only
```

**Testing**:
```bash
# Test agent invocations contain role clarification
grep -A 20 "YOUR ROLE.*SUBAGENT" .claude/commands/research.md
# Expected: 2 matches (research-specialist, research-synthesizer)

# Run basic /research test
/research "test topic"
# Expected: No Task tool usage by subagents, files created correctly
```

Expected result:
- ✓ Subagent role clarification in 2 agent prompts
- ✓ Total addition: ~14 lines
- ✓ Zero regression in functionality

---

### Phase 2: Add Phase-Based Tool Guidance [COMPLETED]
**Objective**: Clarify when orchestrator uses which tools
**Complexity**: Low
**Estimated Time**: 30 minutes

Tasks:
- [x] Add phase-based tool usage section to orchestrator instructions (after line 17)
- [x] Clarify delegation phase uses Task + Bash only
- [x] Clarify verification phase uses Bash + Read for analysis
- [x] Test that instructions are clear and don't cause confusion

**File**: `/home/benjamin/.config/.claude/commands/research.md`

**Code Changes**:

**Location: Orchestrator Instructions** (After line 17, before "You will NOT see research findings directly."):
```markdown

**PHASE-BASED TOOL USAGE**:
1. **Delegation Phase** (Steps 1-3): Use Task + Bash only
   - Decompose topic, calculate paths, invoke agents
   - DO NOT use Read/Write for research activities
2. **Verification Phase** (Steps 4-6): Use Bash + Read for verification
   - Verify files exist, check completion, synthesize overview
   - Read tool for analysis only, NOT for direct research
```

**Testing**:
```bash
# Test phase-based guidance present
grep -A 8 "PHASE-BASED TOOL USAGE" .claude/commands/research.md
# Expected: 8-line section with delegation and verification phases

# Run /research and verify correct tool usage
/research "tool usage test"
# Expected: Task tool during delegation, Bash during verification
```

Expected result:
- ✓ Phase-based tool guidance added
- ✓ Total addition: ~8 lines
- ✓ Improved clarity without bloat

---

## Testing Strategy

### Minimal Validation (30 minutes)

**Test 1: File Creation Rate** (10 minutes)
```bash
# 5-trial test (reduced from 10)
for i in {1..5}; do
  /research "test topic $i"
  # Verify files exist
done
# Target: 5/5 or 4/5 (80%+ acceptable)
```

**Test 2: Subagent Role Compliance** (10 minutes)
```bash
# Test subagents don't orchestrate
/research "subagent role test" 2>&1 | grep -c "Task {"
# Expected: Only orchestrator uses Task tool, not subagents
```

**Test 3: Phase-Based Tool Usage** (10 minutes)
```bash
# Verify orchestrator follows phase guidance
/research "phase tool test" 2>&1 | tee output.log
# Manual review: Check Task used in Steps 1-3, Read used in Steps 4-6
```

### Success Metrics

**Quantitative**:
- File creation rate: 4/5 or better (80%+)
- Subagent role clarification: 2 locations
- Phase guidance: 1 section
- Total additions: <30 lines

**Qualitative**:
- Subagent role is clear (no orchestration confusion)
- Phase-based tool usage is understandable
- Zero regression in existing functionality

## Risk Assessment

**Very Low Risk**:
- Changes are minimal (<30 lines)
- No removal of existing functionality
- Additive clarifications only
- Easy rollback (remove added sections)
- No architectural changes

**Potential Issues**:
- Slightly increased verbosity (+25 lines)
- Phase guidance may be redundant for experienced users

**Mitigation**:
- Verbosity is minimal and focused
- Redundancy aids newer users, doesn't hinder experienced users
- Easy to remove if unhelpful

## Rollback Procedure

If changes cause issues:

```bash
# Restore from backup
cp /home/benjamin/.config/.claude/specs/468_strengthen_research_command_enforcement_through_ve/plans/001_strengthen_verification_behavioral_enforcement.md.backup-* /home/benjamin/.config/.claude/commands/research.md
```

Or manually remove added sections:
1. Remove "YOUR ROLE: You are a SUBAGENT" sections from agent prompts
2. Remove "PHASE-BASED TOOL USAGE" section from orchestrator instructions

## Documentation Requirements

### No Documentation Changes

Since changes are minimal clarifications (not architectural changes), no documentation updates required.

**Optional**: If changes prove highly effective, consider documenting in:
- `.claude/docs/guides/command-development-guide.md` (subagent role pattern)
- `.claude/docs/concepts/patterns/behavioral-injection.md` (phase-based tool guidance)

## Dependencies

### No New Dependencies

All required libraries and agents already exist:
- `.claude/lib/topic-decomposition.sh`
- `.claude/lib/artifact-creation.sh`
- `.claude/agents/research-specialist.md`
- `.claude/agents/research-synthesizer.md`

## Comparison with Plan 444

| Aspect | Tool Restriction (Plan 444) | This Plan (Minimal Improvements) |
|--------|----------------------------|----------------------------------|
| Implementation Time | 30 minutes | 2-3 hours |
| Lines Changed | 1 line | ~25 lines |
| Architectural Impact | High (tool restriction) | None (clarification only) |
| File Creation Rate | 60-80% (no Write tool) | 95-98% (agent-dependent) |
| Fallback Support | No (Write removed) | No (by user choice) |
| Consistency | High (forced delegation) | High (clear role guidance) |
| Flexibility | Low (restricted tools) | High (full tools, clear guidance) |

**Recommendation**: This plan provides better balance between enforcement and flexibility than Plan 444, while respecting user's preference for minimal changes and no fallbacks.

## Notes

### Key Decisions

1. **No Fallbacks**: Per user request, eliminated fallback mechanisms
   - Trade-off: Slight drop in file creation rate (100% → 95-98%)
   - Benefit: Consistency (all files by agents, none by orchestrator)

2. **No Verification Bloat**: Kept existing single verification checkpoint
   - Trade-off: Less comprehensive validation
   - Benefit: Minimal additions, no bloat

3. **Focused on Role Clarity**: Highest-impact, lowest-effort improvements
   - Subagent role clarification prevents orchestration confusion
   - Phase-based tool guidance improves orchestrator clarity

### Implementation Priority

**High Impact, Low Effort** (Implement Now):
- ✅ Subagent role clarification (Phase 1)
- ✅ Phase-based tool guidance (Phase 2)

**Removed** (User Preferences):
- ❌ Fallback mechanisms (consistency > reliability)
- ❌ Triple verification checkpoints (avoid bloat)
- ❌ Extensive testing (basic validation sufficient)
- ❌ Audit compliance (not critical for minimal improvements)

### Comparison with Original Plan

**Original Plan** (4 phases, 8-10 hours):
- Phase 1: Role Clarification (2 hours) → **Kept, streamlined**
- Phase 2: Triple Verification (2-3 hours) → **Removed** (bloat)
- Phase 3: Enhanced Behavioral Injection (2-3 hours) → **Merged into Phase 1**
- Phase 4: Testing (2-3 hours) → **Simplified** (30 minutes)

**Revised Plan** (2 phases, 2-3 hours):
- Phase 1: Subagent Role Clarification (1 hour)
- Phase 2: Phase-Based Tool Guidance (30 minutes)
- Testing: Basic validation (30 minutes)

**Reduction**: 75% less implementation time, 60% less code additions
