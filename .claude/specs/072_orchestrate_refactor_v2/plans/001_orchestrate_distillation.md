# Implementation Plan: Orchestrate Command Distillation

## Metadata
- **Plan Number**: 072-001
- **Date**: 2025-10-23
- **Feature**: Distill /orchestrate to single working workflow with strict standards enforcement
- **Scope**: .claude/commands/orchestrate.md refactoring
- **Structure Level**: Level 0 (single-file plan)
- **Estimated Total Time**: 12-16 hours

## Overview

**Goal**: Distill /orchestrate to a single working workflow that strictly adheres to .claude/docs/ standards by removing ALL fallback mechanisms, implementing workflow scope detection, and strengthening enforcement patterns.

**Current State**: orchestrate.md is 5,478 lines with:
- Multiple fallback mechanisms that undermine standards
- Weak enforcement allowing behavioral drift
- No workflow scope detection (runs all phases regardless of request)
- Redundant templates and retry infrastructure

**Target State**: orchestrate.md at ~3,300 lines (40% reduction) with:
- Zero fallback mechanisms
- Strong step-by-step enforcement (EXECUTE NOW, MANDATORY VERIFICATION)
- Workflow scope detection algorithm
- Single template per agent type
- 100% file creation rate on first attempt

## Success Criteria

### Deficiency Resolution

**From Debug Report: 001_orchestrate_workflow_deficiencies.md**

- ✓ **Deficiency #1** (orchestrate.md:608-1110): Research agents not creating report files
  - Root Cause: Weak enforcement ("FILE CREATION REQUIRED" is descriptive, not prescriptive)
  - Solution: Phase 2 strengthens enforcement with STEP 1/2/3 pattern
  - Locations: Lines 900-914 (STANDARD), 938-952 (STRONG), 986-1000 (MAXIMUM)

- ✓ **Deficiency #2** (orchestrate.md:10-36, 1500-1856): SlashCommand used for planning
  - Root Cause: HTML comment prohibition not enforced, fallback allows SlashCommand usage
  - Solution: Phase 2 moves prohibition to active block, Phase 3 removes SlashCommand fallbacks
  - Locations: Lines 10-36 (prohibition), 1500-1856 (Phase 2 planning)

- ✓ **Deficiency #3** (orchestrate.md:3309-3933): Workflow summary created inappropriately
  - Root Cause: Phase 6 executes unconditionally for all workflows
  - Solution: Phase 1 adds conditional Phase 6 execution (skip if no implementation)
  - Location: Lines 3309-3933 (Phase 6 documentation)

- ✓ **Deficiency #4** (orchestrate.md:338-352): Missing workflow scope detection
  - Root Cause: Descriptive guidance instead of executable scope detection algorithm
  - Solution: Phase 1 implements detect_workflow_scope() with 4 pattern types
  - Location: Lines 338-352 (workflow phase identification)

### Quantitative Targets
- File size: ≤3,300 lines (40% reduction from 5,478)
- Template count: 1 per agent type (remove STANDARD/STRONG/RETRY variants)
- Fallback mechanisms: 0
- File creation success rate: 100% on first attempt
- Standards compliance score: ≥95/100 on enforcement rubric

### Functional Requirements
- Workflow scope detection correctly identifies 4 patterns:
  - Research-only (Phase 0-1 only)
  - Research-and-plan (Phase 0-2 only)
  - Full-implementation (Phase 0-5 only)
  - Debug-only (Phase 0, 1, 4, 5 only)
- Conditional Phase 6 execution (summary only when implementation occurred)
- Zero degradation in successful workflow completion rate

### Root Cause Resolution

**Primary Root Cause**: Missing workflow scope detection algorithm
- **Deficiencies Caused**: #3 (unnecessary summaries), #4 (all phases execute)
- **Solution**: Phase 1 implements detect_workflow_scope() algorithm
- **Impact**: 2 deficiencies fixed by single solution

**Secondary Root Causes**:
1. Weak enforcement patterns → Phase 2 strengthens to STEP 1/2/3
   - **Deficiency Caused**: #1 (agents return inline summaries)
   - **Impact**: 100% file creation rate on first attempt

2. HTML comment prohibition → Phase 2 moves to active block
   - **Deficiency Caused**: #2 (SlashCommand usage enabled)
   - **Impact**: Zero SlashCommand usage, behavioral injection enforced

### Performance Metrics

- Context usage: <25% throughout workflow (down from ~30%)
- Time savings: 15-25% for non-implementation workflows
- File creation rate: 100% on first attempt (zero retries needed)
- Standards compliance: ≥95/100 on enforcement rubric
- Workflow completion rate: 100% (zero degradation from current)
- Phase execution accuracy: 100% (correct phases run for each scope type)

## Technical Design

### Workflow Scope Detection Algorithm

```bash
# After Phase 0, analyze workflow description to determine scope
detect_workflow_scope() {
  local workflow_desc="$1"

  # Pattern 1: Research-only
  if echo "$workflow_desc" | grep -Eiq "(research|analyze|investigate|explore).*(only|just)"; then
    echo "research-only"
    return
  fi

  # Pattern 2: Research-and-plan (most common)
  if echo "$workflow_desc" | grep -Eiq "(plan|design|architect)" && \
     ! echo "$workflow_desc" | grep -Eiq "(implement|code|build)"; then
    echo "research-and-plan"
    return
  fi

  # Pattern 3: Debug-only
  if echo "$workflow_desc" | grep -Eiq "(debug|fix|troubleshoot|diagnose)"; then
    echo "debug-only"
    return
  fi

  # Pattern 4: Full-implementation (default)
  echo "full-implementation"
}
```

### Conditional Phase Execution Pattern

```bash
# Store scope in workflow state
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

# Before each phase, check if it should run
should_run_phase() {
  local phase_num="$1"

  case "$WORKFLOW_SCOPE" in
    research-only)
      [[ $phase_num -le 2 ]] ;;
    research-and-plan)
      [[ $phase_num -le 3 ]] ;;
    debug-only)
      [[ $phase_num -eq 1 || $phase_num -eq 4 || $phase_num -eq 6 ]] ;;
    full-implementation)
      [[ $phase_num -le 5 || ($phase_num -eq 6 && $IMPLEMENTATION_OCCURRED == "true") ]] ;;
  esac
}
```

### Enforcement Strengthening Pattern

**Old (Weak)**:
```markdown
Research agents should create report files using the Write tool.
```

**New (Strong)**:
```markdown
**EXECUTE NOW - MANDATORY FILE CREATION**

STEP 1: Use Write tool IMMEDIATELY to create this file:
{report_path}

STEP 2: Research the topic comprehensively.

STEP 3: Use Edit tool to add research findings to file.

**MANDATORY VERIFICATION**: Orchestrator will verify file exists.
If file does not exist, workflow will fail.
```

### Fallback Removal Strategy

1. **Remove Auto-Retry Infrastructure** (~800 lines)
   - Delete `invoke_research_agent_with_retry()`
   - Delete retry attempt tracking
   - Delete STANDARD/STRONG/RETRY template variants
   - Keep only STRONGEST template per agent

2. **Remove Fallback File Creation** (~250 lines)
   - Delete Phase 1 SlashCommand fallback
   - Delete Phase 2 fallback check
   - Delete path correction logic
   - Replace with MANDATORY VERIFICATION failures

3. **Remove Redundant Templates** (~400 lines)
   - Keep ENHANCED_RESEARCH_AGENT (3,200 chars)
   - Remove STANDARD_RESEARCH_AGENT (1,800 chars)
   - Remove RESEARCH_AGENT_STRONG (2,100 chars)
   - Remove RESEARCH_AGENT_WITH_RETRY (2,400 chars)
   - Apply same to planning agent templates

## Implementation Phases

### Phase 0: Pre-Implementation Analysis
**Status**: PENDING
**Complexity**: 2/10
**Estimated Time**: 30 minutes

**Objective**: Analyze orchestrate.md structure and prepare workspace for distillation.

**Implementation Steps**:

1. **EXECUTE NOW**: Read current orchestrate.md file
   ```bash
   Read /home/benjamin/.config/.claude/commands/orchestrate.md
   ```

2. **EXECUTE NOW**: Count current metrics
   - Line count: `wc -l orchestrate.md`
   - Template variants: `grep -c "RESEARCH_AGENT" orchestrate.md`
   - Fallback locations: `grep -n "SlashCommand" orchestrate.md`

3. **EXECUTE NOW**: Create backup
   ```bash
   cp orchestrate.md orchestrate.md.backup.$(date +%Y%m%d_%H%M%S)
   ```

**Testing Strategy**:
- Verify backup file exists
- Verify line count matches expected ~5,478

**Git Commit**: `refactor(072): Phase 0 - create orchestrate.md backup and analyze current state`

---

### Phase 1: Implement Workflow Scope Detection
**Status**: PENDING
**Complexity**: 4/10
**Estimated Time**: 2 hours

**Objective**: Add workflow scope detection algorithm and conditional phase execution checks to orchestrate.md.

**Implementation Steps**:

1. **EXECUTE NOW**: Locate Phase 0 completion in orchestrate.md
   - Search for "Phase 0" section
   - Find end of standards validation logic

2. **EXECUTE NOW**: Add scope detection function after Phase 0
   - Insert `detect_workflow_scope()` function (35 lines)
   - Add 4 pattern detection rules (research-only, research-and-plan, debug-only, full-implementation)
   - Store result in `WORKFLOW_SCOPE` variable

3. **EXECUTE NOW**: Add conservative default for ambiguous workflows
   - If no pattern matches, default to "research-and-plan" (most common, safest)
   - Log warning: "Could not definitively determine workflow scope"
   - Display detected scope with rationale
   - Allow user override with explicit flags (future enhancement)

4. **EXECUTE NOW**: Add conditional phase execution function
   - Insert `should_run_phase()` function (20 lines)
   - Implement scope-based phase filtering
   - Add debug logging for skipped phases

5. **EXECUTE NOW**: Update phase execution loop
   - Wrap each phase (1-6) with `should_run_phase()` check
   - Add skip messages: "Skipping Phase {N} (scope: {WORKFLOW_SCOPE})"
   - Preserve phase numbering in output

6. **EXECUTE NOW**: Add Phase 6 conditional logic
   - Check `$IMPLEMENTATION_OCCURRED` flag
   - Skip Phase 6 if no implementation phases ran
   - Add explicit message: "Skipping Phase 6 (no implementation to summarize)"

**Testing Strategy**:
- Test research-only workflow: "Research authentication best practices"
- Verify Phases 3-6 skipped
- Test research-and-plan workflow: "Plan a new feature"
- Verify Phases 4-6 skipped
- Test full-implementation workflow: "Implement user authentication"
- Verify all phases 1-5 run, Phase 6 runs

**Git Commit**: `feat(072): Phase 1 - add workflow scope detection and conditional phase execution`

---

### Phase 2: Strengthen Enforcement Patterns
**Status**: PENDING
**Complexity**: 6/10
**Estimated Time**: 3 hours

**Implementation Steps**:

1. **EXECUTE NOW**: Update ENHANCED_RESEARCH_AGENT template (3 locations)
   - Replace "should create" with "EXECUTE NOW - MANDATORY FILE CREATION"
   - Add STEP 1/2/3 numbered instructions
   - Add MANDATORY VERIFICATION block at end
   - Update in: Phase 1.1, Phase 1.2, Phase 1.3

2. **EXECUTE NOW**: Update ENHANCED_PLANNING_AGENT template
   - Replace weak enforcement with step-by-step pattern
   - Add EXECUTE NOW block for file creation
   - Add MANDATORY VERIFICATION for plan file existence
   - Specify exact file path in STEP 1

3. **EXECUTE NOW**: Update implementation phase template
   - Add step-by-step instructions for /implement invocation
   - Add MANDATORY VERIFICATION for checkpoint files
   - Specify expected output format

4. **EXECUTE NOW**: Move architectural prohibition to active block
   - Locate HTML comment: `<!-- CRITICAL: Never use SlashCommand -->`
   - Move to visible markdown blockquote
   - Add to Phase 0 standards validation
   - Make failure condition explicit

5. **EXECUTE NOW**: Add verification checkpoints
   - After Phase 1: Verify all report files exist
   - After Phase 2: Verify all report files exist (no gaps from Phase 1)
   - After Phase 3: Verify plan file exists
   - Add explicit failure messages for missing files

**Testing Strategy**:
- Run research phase and verify EXECUTE NOW appears in agent context
- Run planning phase and verify step-by-step instructions present
- Verify HTML prohibition moved to active block (visible in markdown)
- Test verification checkpoint failures (manually delete file after creation)

**Git Commit**: `refactor(072): Phase 2 - strengthen enforcement patterns with step-by-step instructions`

---

### Phase 3: Remove Fallback Mechanisms
**Status**: PENDING
**Complexity**: 7/10
**Estimated Time**: 3-4 hours

**Objective**: Remove all fallback mechanisms (~1,100 lines) that undermine standards enforcement.

**Implementation Steps**:

1. **EXECUTE NOW**: Remove auto-retry infrastructure
   - Delete `invoke_research_agent_with_retry()` function (~120 lines)
   - Delete retry attempt tracking variables
   - Delete retry loop logic in Phase 1
   - Delete success rate calculation code
   - **Estimated deletion**: ~800 lines

2. **EXECUTE NOW**: Remove fallback file creation (Deficiency #1)
   - Search for all `SlashCommand` tool invocations
   - Delete Phase 1 `/report` fallback (~80 lines)
   - Delete Phase 2 existence check + fallback (~60 lines)
   - Delete Phase 3 `/plan` fallback (~50 lines)
   - Delete all "if file doesn't exist" recovery blocks
   - **Estimated deletion**: ~250 lines

3. **EXECUTE NOW**: Remove path correction logic
   - Delete path validation functions
   - Delete path correction attempts
   - Delete "try alternative paths" blocks
   - **Estimated deletion**: ~50 lines

4. **EXECUTE NOW**: Replace fallbacks with mandatory verification
   - Add explicit failure messages
   - Add workflow termination on missing files
   - Add clear error reporting to user

5. **EXECUTE NOW**: Update error handling
   - Replace "retry" with "fail fast"
   - Add actionable error messages
   - Remove success rate reporting (expect 100%)

**Testing Strategy**:
- Verify all `grep -n "SlashCommand" orchestrate.md` returns 0 results
- Verify all `grep -n "retry" orchestrate.md` only shows variable names (not logic)
- Test workflow failure when agent fails to create file
- Verify clear error message displayed to user
- Test that workflow terminates immediately (no retries)

**Git Commit**: `refactor(072): Phase 3 - remove all fallback mechanisms and auto-retry infrastructure`

---

### Phase 4: Consolidate Templates
**Status**: PENDING
**Complexity**: 5/10
**Estimated Time**: 2 hours

**Objective**: Reduce template variants from 4 per agent type to 1, keeping only the strongest version.

**Implementation Steps**:

1. **EXECUTE NOW**: Identify all template variants
   - Count RESEARCH_AGENT variants: `grep -c "RESEARCH_AGENT" orchestrate.md`
   - Count PLANNING_AGENT variants: `grep -c "PLANNING_AGENT" orchestrate.md`
   - List variant names and character counts

2. **EXECUTE NOW**: Keep only ENHANCED_RESEARCH_AGENT
   - Verify ENHANCED_RESEARCH_AGENT has strongest enforcement (from Phase 2)
   - Delete STANDARD_RESEARCH_AGENT definition (~100 lines)
   - Delete RESEARCH_AGENT_STRONG definition (~120 lines)
   - Delete RESEARCH_AGENT_WITH_RETRY definition (~130 lines)
   - Update all references to use ENHANCED_RESEARCH_AGENT

3. **EXECUTE NOW**: Keep only ENHANCED_PLANNING_AGENT
   - Verify ENHANCED_PLANNING_AGENT has step-by-step enforcement
   - Delete STANDARD_PLANNING_AGENT definition (~80 lines)
   - Delete PLANNING_AGENT_STRONG definition (~90 lines)
   - Update all references to use ENHANCED_PLANNING_AGENT

4. **EXECUTE NOW**: Remove template selection logic
   - Delete retry attempt conditionals (~30 lines)
   - Delete template variant selection code
   - Simplify to single template invocation

5. **EXECUTE NOW**: Verify single template usage
   - Count remaining templates: should be 1 research, 1 planning
   - Verify no dead code references to deleted templates

**Testing Strategy**:
- Verify `grep -c "RESEARCH_AGENT" orchestrate.md` returns 1
- Verify `grep -c "PLANNING_AGENT" orchestrate.md` returns 1
- Run research phase and verify ENHANCED template used
- Run planning phase and verify ENHANCED template used
- Check file size reduction: expect ~400 lines removed

**Git Commit**: `refactor(072): Phase 4 - consolidate to single template per agent type`

---

### Phase 5: Distill Phase Descriptions
**Status**: PENDING
**Complexity**: 8/10
**Estimated Time**: 4-5 hours

**Objective**: Condense each phase description to 100-150 lines by removing enforcement rationale comments and converting guidance to executable code.

**Implementation Steps**:

1. **EXECUTE NOW**: Analyze current phase verbosity
   - Measure each phase section length
   - Identify rationale comments (lines starting with `#` explaining why)
   - Identify guidance blocks (markdown explaining how to do something)
   - Target: Phase 0: 150 lines, Phase 1: 120 lines, Phase 2: 100 lines, Phase 3: 120 lines, Phase 4: 100 lines, Phase 5: 80 lines, Phase 6: 80 lines

2. **EXECUTE NOW**: Distill Phase 0 (Standards Validation)
   - Remove enforcement rationale comments (~40 lines)
   - Convert guidance to inline code comments (~20 lines)
   - Consolidate standards checking into single function
   - Remove redundant explanations
   - Target: 150 lines (from ~250)

3. **EXECUTE NOW**: Distill Phase 1 (Parallel Research)
   - Remove retry infrastructure explanations (~60 lines)
   - Remove template variant rationale (~40 lines)
   - Condense subagent invocation to essential steps
   - Remove success rate calculation comments
   - Target: 120 lines (from ~400)

4. **EXECUTE NOW**: Distill Phase 2 (Research Validation)
   - Remove existence checking rationale (~30 lines)
   - Remove fallback explanation (~20 lines)
   - Condense to: read files, verify content, report status
   - Target: 100 lines (from ~200)

5. **EXECUTE NOW**: Distill Phase 3 (Planning)
   - Remove complexity calculation rationale (~40 lines)
   - Remove template selection logic (~30 lines)
   - Condense to: invoke planner, verify file, extract metadata
   - Target: 120 lines (from ~250)

6. **EXECUTE NOW**: Distill Phase 4 (Implementation)
   - Remove checkpoint recovery explanations (~50 lines)
   - Remove adaptive planning rationale (~40 lines)
   - Condense to: invoke /implement, monitor progress, handle errors
   - Target: 100 lines (from ~250)

7. **EXECUTE NOW**: Distill Phase 5 (Quality Validation)
   - Remove testing protocol rationale (~30 lines)
   - Condense to: run tests, verify pass, report coverage
   - Target: 80 lines (from ~150)

8. **EXECUTE NOW**: Distill Phase 6 (Documentation)
   - Remove summary generation rationale (~30 lines)
   - Condense to: collect artifacts, generate summary, verify creation
   - Target: 80 lines (from ~150)

9. **EXECUTE NOW**: Remove global rationale sections
   - Delete "Why This Works" sections (~80 lines)
   - Delete "Common Pitfalls" sections (~60 lines)
   - Delete "Design Rationale" blocks (~70 lines)
   - Move essential info to .claude/docs/guides/orchestrate-guide.md

**Testing Strategy**:
- Verify total file size: `wc -l orchestrate.md` ≤ 3,300 lines
- Verify each phase within target range
- Run full workflow and verify no functional changes
- Verify all enforcement patterns still present
- Check that code comments are clear without rationale

**Git Commit**: `refactor(072): Phase 5 - distill phase descriptions to essential executable content`

---

### Phase 6: Validation and Testing
**Status**: PENDING
**Complexity**: 6/10
**Estimated Time**: 2-3 hours

**Objective**: Validate all changes through comprehensive testing and verify all success criteria met.

**Implementation Steps**:

1. **EXECUTE NOW**: Test research-only workflow
   ```bash
   /orchestrate "Research best practices for error handling in Lua"
   ```
   - Verify Phases 1-2 execute
   - Verify Phases 3-6 skipped with clear messages
   - Verify 2-4 research reports created
   - Verify zero SlashCommand usage
   - Verify EXECUTE NOW blocks present in agent context

2. **EXECUTE NOW**: Test research-and-plan workflow (MOST COMMON)
   ```bash
   /orchestrate "Plan implementation of user authentication system"
   ```
   - Verify Phases 1-3 execute
   - Verify Phases 4-6 skipped
   - Verify research reports created (Phase 1)
   - Verify plan file created (Phase 3)
   - Verify 100% file creation rate (no fallbacks)
   - Verify step-by-step enforcement in planning agent

3. **EXECUTE NOW**: Test full-implementation workflow
   ```bash
   /orchestrate "Implement rate limiting for API endpoints"
   ```
   - Verify Phases 1-5 execute
   - Verify Phase 6 executes (implementation occurred)
   - Verify all artifacts created
   - Verify /implement runs successfully
   - Verify summary generated

4. **EXECUTE NOW**: Test debug-only workflow
   ```bash
   /orchestrate "Debug failing authentication tests"
   ```
   - Verify Phases 1, 4, 6 execute
   - Verify Phases 2, 3, 5 skipped
   - Verify debug reports created
   - Verify implementation attempted
   - Verify summary generated

5. **EXECUTE NOW**: Test enforcement strength with repetition (from debug report Test 5)
   ```bash
   # Run research-and-plan workflow 10 times
   for i in {1..10}; do
     /orchestrate "Plan implementation of test feature $i"
   done
   ```
   - Count total report files created: `find .claude/specs/*/reports/ -name "*.md" -type f | wc -l`
   - Expected: 40 files (4 reports × 10 workflows)
   - File creation rate: 100% (40/40)
   - Verify zero inline summaries: `grep -r "Research Summary (200 words)" .claude/data/logs/`
   - Verify zero SlashCommand: `grep -r "> /plan is running" .claude/data/logs/`
   - Average time per workflow: 12-18 minutes

6. **EXECUTE NOW**: Validate success criteria
   - ✓ File size ≤3,300 lines: `wc -l orchestrate.md`
   - ✓ Zero SlashCommand usage: `grep -c "SlashCommand" orchestrate.md` = 0
   - ✓ Single template per agent: `grep -c "RESEARCH_AGENT.*=" orchestrate.md` = 1
   - ✓ Zero retry infrastructure: `grep -c "retry" orchestrate.md` ≤ 5 (variable names only)
   - ✓ 100% file creation rate: all test workflows create expected files
   - ✓ Enforcement patterns present: `grep -c "EXECUTE NOW" orchestrate.md` ≥ 10

7. **EXECUTE NOW**: Validate deficiency resolution (corrected from debug report)
   - ✓ **Deficiency #1 Fixed**: Research agents create report files (100% rate), zero inline summaries
   - ✓ **Deficiency #2 Fixed**: Zero SlashCommand invocations detected, Task tool used for all agents
   - ✓ **Deficiency #3 Fixed**: No summaries created for research-and-plan workflows
   - ✓ **Deficiency #4 Fixed**: Workflow scope detection correctly identifies all 4 patterns

8. **EXECUTE NOW**: Document validation results
   - Create validation report: `.claude/specs/072_orchestrate_refactor_v2/debug/001_validation_results.md`
   - Record all test outcomes
   - Record metrics comparison (before/after)
   - Record any edge cases discovered

**Testing Strategy**:
- Run all 4 workflow types
- Verify zero failures
- Verify zero fallback invocations
- Verify all files created on first attempt
- Compare metrics to success criteria

**Git Commit**: `test(072): Phase 6 - validate orchestrate distillation with comprehensive workflow testing`

---

## Risk Assessment

### High-Risk Areas
1. **Scope Detection Algorithm**: May not cover all workflow patterns
   - Mitigation: Default to full-implementation for unknown patterns
   - Fallback: User can override with explicit flags

2. **Breaking Existing Workflows**: Users may rely on current behavior
   - Mitigation: Maintain backward compatibility for common patterns
   - Communication: Document changes in .claude/docs/guides/orchestrate-guide.md

3. **Enforcement Too Strong**: May cause false failures
   - Mitigation: Test extensively before deploying
   - Rollback: Keep orchestrate.md.backup for quick reversion

### Medium-Risk Areas
1. **Template Consolidation**: Removing variants may reduce flexibility
   - Mitigation: Keep strongest variant with all enforcement patterns
   - Monitoring: Track file creation success rate for 2 weeks

2. **Line Count Target**: May sacrifice clarity for brevity
   - Mitigation: Only remove rationale, keep essential code
   - Validation: Verify all enforcement patterns preserved

## Dependencies

### File Dependencies
- `.claude/docs/concepts/patterns/behavioral-injection.md` - Agent invocation pattern
- `.claude/docs/concepts/patterns/verification-fallback.md` - Verification checkpoints
- `.claude/docs/guides/imperative-language-guide.md` - Enforcement language standards
- `.claude/specs/070_orchestrate_refactor/debug/001_orchestrate_workflow_deficiencies.md` - Original deficiency report

### Command Dependencies
- None (this plan modifies orchestrate.md only)

### External Dependencies
- Agents must support EXECUTE NOW pattern (already implemented)
- Task tool must support context injection (already implemented)

## Rollback Plan

If distilled orchestrate.md causes failures:

1. **Immediate Rollback**:
   ```bash
   cp orchestrate.md.backup.YYYYMMDD_HHMMSS orchestrate.md
   ```

2. **Identify Failure Mode**:
   - Scope detection error → fix algorithm
   - Enforcement too strong → adjust verification checkpoints
   - Template issues → restore variant

3. **Incremental Re-application**:
   - Apply phases 1-2 only (scope detection + enforcement)
   - Test for 1 week
   - Apply phases 3-4 (fallback removal + consolidation)
   - Test for 1 week
   - Apply phase 5 (distillation)

## Post-Implementation Tasks

1. **Documentation Updates**:
   - Create `.claude/docs/guides/orchestrate-guide.md` with workflow scope patterns
   - Update `.claude/docs/reference/command-reference.md` with new orchestrate behavior
   - Document scope detection algorithm in concepts

2. **Monitoring**:
   - Track file creation success rate for 2 weeks
   - Monitor for user-reported workflow failures
   - Collect feedback on enforcement strength

3. **Follow-up Improvements**:
   - Add scope detection override flags (e.g., `--scope=research-only`)
   - Add verbose mode for debugging scope detection
   - Consider adding workflow templates for common patterns

## Notes

This plan distills orchestrate.md from 5,478 lines to ~3,300 lines (40% reduction) while improving standards compliance and removing all fallback mechanisms. The key innovation is workflow scope detection, which prevents unnecessary phase execution and reduces context window consumption.

The enforcement strengthening in Phase 2 is critical for achieving 100% file creation rate on first attempt. By replacing weak guidance with step-by-step EXECUTE NOW instructions, we eliminate the behavioral drift that necessitated fallback mechanisms.

The distillation in Phase 5 moves rationale and explanations to documentation, keeping orchestrate.md focused on executable instructions. This aligns with the principle that command files are "AI execution scripts, not traditional code."
