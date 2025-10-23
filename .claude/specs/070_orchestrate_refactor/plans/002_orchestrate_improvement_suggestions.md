# /orchestrate Simplification Plan - Improvement Suggestions (DRAFT FOR REVISION)

## Metadata
- **Date**: 2025-10-22
- **Type**: Improvement Plan (Draft)
- **Base Plan**: 001_orchestrate_simplification.md
- **Status**: DRAFT - Needs revision to integrate with .claude/docs/ vision and current implementation
- **Research Sources**:
  - Plan 001 analysis
  - Current orchestrate.md implementation (6,304 lines)
  - .claude/docs/ standards and patterns
- **Plan Number**: 070-002

## Purpose

This document provides **suggestions for improving Plan 001** based on comprehensive research of:
- The current implementation state (including Plan 071 completed work)
- Documentation standards in .claude/docs/
- Critical gaps and technical debt identified in Plan 001

**IMPORTANT**: This is a DRAFT for discussion. It needs careful revision to:
1. Integrate with the architectural vision in .claude/docs/
2. Align with Plan 001's original simplification objectives
3. Account for the current implementation state after Plan 071
4. Be reviewed for feasibility and scope appropriateness

## Research Summary

### Current State (As of 2025-10-22)

**orchestrate.md Implementation**:
- File size: 6,304 lines, 219KB
- Target size: 3,600-4,200 lines (30-40% reduction)
- Current bloat: ~40-50% oversized vs goal
- Phase structure: 8 phases with non-sequential numbering (0,1,2,2.5,4,5,6,7,8)

**Recent Completions**:
- ✅ Plan 071: Fallback removal, auto-retry, template escalation completed
- ✅ Auto-recovery architecture documented
- ✅ Strict subagent-only operation enforced

**Recent Issues Identified**:
- ⚠️ Workflow summary reporting creates unnecessary artifact - planning agent should return brief summary and plan reference instead of creating separate summary file

**Still Pending (Plan 070)**:
- ❌ Phase 2.5 removal (~347 lines)
- ❌ Phase 4 removal (~470 lines)
- ❌ Phase renumbering (make sequential)
- ❌ Content extraction to shared/ files
- ❌ User control restoration (vs automatic expansion)

### Critical Gaps Identified in Plan 001

1. **Phase 8 Handling Unresolved**
   - Plan states: "Phase 8: Documentation → [MERGE into Phase 3 completion or keep as Phase 6]"
   - Decision never documented in Technical Design
   - Affects renumbering map and implementation approach
   - **Impact**: Medium - blocks implementation until resolved

2. **Content Extraction Matrix Undefined**
   - Plan targets 5 shared/ files but doesn't specify which content goes where
   - Risk of overlap or gaps in extraction
   - No validation that all content is covered
   - **Impact**: Medium - could lead to incomplete/redundant extraction

3. **Expansion Depth Limits Not Specified**
   - /expand enhancement mentions "recursive expansion capability"
   - No depth limits defined (could loop infinitely)
   - No termination conditions documented
   - **Impact**: Low - but could cause infinite recursion

4. **/collapse Integration Missing**
   - Plan removes Phase 2.5/4 but doesn't address already-expanded plans
   - What happens to existing Level 1/2 expanded plans?
   - Should /collapse be enhanced to handle them?
   - **Impact**: Low - existing plans can remain expanded, but worth considering

### Standards Alignment Issues

Based on .claude/docs/ review:

1. **Missing Standard 0 Enforcement Markers**
   - Few "EXECUTE NOW", "MANDATORY VERIFICATION" blocks
   - Should follow Execution Enforcement Guide patterns
   - Expected score: 60-75/100 (audit tool would flag)

2. **~~Weak Fallback Mechanisms~~** (REMOVED - Not wanted)
   - User prefers predictable behavior and simplicity
   - Auto-retry with escalation templates provides sufficient reliability
   - Fallback mechanisms add complexity without clear benefit

3. **No Aggressive Context Pruning Policy**
   - Orchestration workflows should target <20% context usage
   - No explicit pruning calls after research/planning phases
   - Context Management Pattern not fully applied

4. **Passive Language Present**
   - Uses "should" instead of "MUST" in places
   - Doesn't follow imperative language standards
   - Execution Enforcement Guide requires mandatory directives

5. **No Phase 0 Orchestrator Role Clarification**
   - Missing explicit "YOU ARE THE ORCHESTRATOR, not the executor"
   - Behavioral Injection Pattern doc recommends clear role declaration
   - Helps prevent orchestrator attempting direct execution

### Technical Debt Identified

1. **Redundant Retry Templates**
   - 6 templates total (3 research + 3 planning) for escalation
   - Could consolidate into parameterized generator function
   - Estimated savings: ~150-200 lines

2. **Duplicate File Verification Code**
   - Pattern `[ -f "$path" ] && [ -s "$path" ]` repeated ~20+ times
   - Could extract to utility function: `verify_file_exists_with_content()`
   - Estimated savings: ~50-100 lines (including utility creation)

3. **Missing Retry Logic Abstraction**
   - Research retry and planning retry use similar but separate code
   - Could unify into generic `retry_agent_with_templates(agent_type, topic, path)`
   - Estimated savings: ~100-150 lines

4. **Scattered Checkpoint Code**
   - Checkpoint creation logic repeated for each phase
   - Could extract to utility: `save_phase_checkpoint(phase_name, outputs, next_phase)`
   - Estimated savings: ~75-100 lines

## Improvement Recommendations

### Recommendation 1: Add Pre-Simplification Preparation Phase

**What**: Insert new Phase 0 before current Phase 0 (location)

**Why**: Addresses critical gaps before starting simplification

**Tasks**:
1. **~~Create checkpoint migration utility~~** (REMOVED - Not needed)
   - Old checkpoints can be discarded (breaking change acceptable)
   - Simplifies implementation by avoiding migration complexity
   - Users must complete or abandon in-progress workflows before upgrade

2. Resolve Phase 8 ambiguity
   - **Decision needed**: Merge documentation into Phase 3 completion OR keep as Phase 6?
   - **Recommendation**: Keep as Phase 6 (clearer separation of concerns)
   - Document decision in Technical Design section
   - Update renumbering map accordingly

3. Create content extraction matrix
   - Table mapping orchestrate.md sections → target shared/ files
   - Ensures complete coverage without overlap
   - Example format:
     ```
     | Section (Line Range) | Target File | Content Type |
     |---------------------|-------------|--------------|
     | Lines 100-250 | research-phase-patterns.md | Research coordination |
     | Lines 800-1100 | debugging-loop-patterns.md | Debug workflow |
     ```

4. Define expansion depth limits
   - Maximum 2 levels: Level 0 (inline) → Level 1 (phases/) → Level 2 (stages/)
   - Termination condition: complexity score drops OR max depth reached
   - Document in /expand command specification

5. Decide /collapse integration approach
   - **Option A**: Enhance /collapse to handle existing expanded plans
   - **Option B**: Leave existing plans as-is, remove expansion going forward
   - **Recommendation**: Option B (simpler, existing plans not broken)

**Impact**: Resolves critical gaps before starting simplification (checkpoint migration removed for simplicity)

### Recommendation 2: Strengthen Standards Enforcement Throughout Plan 001

**What**: Add enforcement markers and patterns from .claude/docs/ standards

**Why**: Improves reliability and aligns with documented best practices

**Changes to Apply**:

1. Add Standard 0 markers (per Command Architecture Standards)
   - **Target**: Minimum 12 "EXECUTE NOW" markers for critical operations
   - **Target**: Minimum 8 "MANDATORY VERIFICATION" blocks for file operations
   - **Target**: Minimum 6 "CHECKPOINT REQUIREMENT" blocks at phase boundaries
   - Replace "Calculate paths" → "**EXECUTE NOW - Calculate Paths**"
   - Replace "Verify files" → "**MANDATORY VERIFICATION - Report Files Exist**"
   - Add "**CHECKPOINT REQUIREMENT - Report Phase Completion**" at phase boundaries
   - Use "**CRITICAL INSTRUCTION**", "**ABSOLUTE REQUIREMENT**" for key steps
   - Follow Pattern 1 (Direct Execution Blocks) from Execution Enforcement Guide

2. **~~Strengthen fallback mechanisms~~** (REMOVED - Not wanted)
   - User prefers predictable behavior over fallback complexity
   - Auto-retry with escalation templates provides sufficient reliability
   - Fallbacks add unpredictable behavior (orchestrator might create files vs pure coordination)

3. Add aggressive context pruning policy
   - After research phase: `apply_pruning_policy --mode aggressive --phase research`
   - After planning phase: `apply_pruning_policy --mode aggressive --phase planning`
   - Target <20% context usage (monitor at checkpoints)
   - Use metadata extraction + pruning for 92-97% reduction

4. Eliminate passive language (per Imperative Language Guide)
   - **Target**: Imperative ratio ≥90% (validated using `.claude/lib/audit-imperative-language.sh`)
   - Replace "should verify" → "YOU MUST verify"
   - Replace "can use" → "YOU WILL use"
   - Replace "may include" → "YOU SHALL include"
   - Replace "consider adding" → "YOU MUST add"
   - Replace "try to" → "YOU WILL"
   - Use only MUST/WILL/SHALL (eliminate should/may/can/consider/try)
   - Follow transformation table from Imperative Language Guide (Pattern 10)

5. Add Phase 0 orchestrator role clarification (per Standard 0, Phase 0 Requirement)
   - **Requirement**: ALL orchestrator commands MUST include Phase 0 before invoking subagents
   - Insert at opening: "**YOUR ROLE**: You are the ORCHESTRATOR, not the executor"
   - Add "**CRITICAL INSTRUCTIONS**" section:
     - "DO NOT execute research yourself using Read/Grep/Write tools"
     - "DO NOT create files directly"
     - "DO NOT invoke slash commands (use Task tool for agents)"
   - Add "**ONLY**" directives:
     - "ONLY use Task tool to delegate to specialized agents"
     - "ONLY coordinate subagents"
     - "ONLY verify artifact paths (agents create files)"
   - Add "You will NOT see [results] directly" explanation
   - Follow Execution Enforcement Guide Phase 0 pattern (Migration Process section)
   - Follow Behavioral Injection Pattern for agent coordination

**Impact**: Raises audit score (excluding fallback mechanisms, focusing on enforcement and clarity)

### Recommendation 3: Simplify Planning Agent Output (Remove Summary Artifact Creation)

**What**: Replace workflow summary reporting with simpler agent response pattern

**Why**: Currently, the orchestrate command creates a separate workflow summary artifact after planning completes. This is unnecessary overhead - the planning agent can simply return a brief summary and plan reference in its response.

**Current Behavior (Undesirable)**:
```bash
# After planning phase completes
echo "✓ Planning phase complete"

# Display workflow summary
echo ""
echo "============================================"
echo "    /orchestrate WORKFLOW SUMMARY"
echo "============================================"
echo ""
echo "Research Phase:"
echo "  ✓ Successful: ${#SUCCESSFUL_REPORTS[@]} topics"
# ... creates separate summary artifact file
```

**Proposed Behavior**:
```bash
# Planning agent returns in its response:
# - Brief summary (50-100 words)
# - Plan file path reference
# - Key metadata (phase count, complexity)

# Orchestrator receives this and:
# - Displays to user (if terminal workflow)
# - Passes to implementer agent (if continuing to implementation)
# - No separate file created
```

**Tasks**:

1. Remove workflow summary creation logic
   - Delete summary display code from planning phase completion
   - Remove artifact creation for summary files
   - Estimated reduction: ~40-50 lines

2. Update planning agent template
   - Agent returns: plan path, brief summary (50-100 words), metadata
   - Format: `PLAN_CREATED: <path>\nSUMMARY: <brief-summary>\nMETADATA: phases=N, complexity=<level>`
   - No separate summary artifact

3. Update orchestrator to display agent summary
   - Parse agent response for summary
   - Display summary to user (if needed)
   - Pass summary + plan path to next phase (implementation)

4. Remove summary cross-referencing
   - Plans no longer need summary back-references
   - Reports no longer need summary links
   - Simplifies artifact lifecycle

**Benefits**:
- Fewer artifacts to manage (no summary files)
- Simpler workflow (plan creation returns everything needed)
- Less disk I/O (no summary file writes)
- Clearer responsibility (planning agent owns summary content)
- Easier to pass context to implementation (summary in agent response)

**Impact**:
- File size reduction: ~40-50 lines
- Artifact reduction: Eliminates summary files entirely
- Improved agent response pattern (self-contained)
- Maintains all necessary information (summary still available, just not as file)

### Recommendation 4: Add Technical Debt Reduction Phase

**What**: New phase after content extraction to consolidate redundant code

**Why**: Achieves additional 5-10% file size reduction beyond content extraction

**Tasks**:

1. Consolidate retry templates
   - Create parameterized template generator function
   - Function signature: `generate_retry_template(agent_type, enforcement_level, topic, path)`
   - Replace 6 explicit templates with generator calls
   - Estimated reduction: ~150-200 lines

2. Extract verification utilities
   - Create `.claude/lib/agent-operations.sh`
   - Functions:
     - `verify_file_exists_with_content(path)` - returns 0 if file exists and non-empty
     - `retry_agent_with_templates(agent_type, topic, path, max_attempts)` - generic retry wrapper
     - `save_phase_checkpoint(phase_name, outputs, next_phase)` - checkpoint creation utility
   - Update orchestrate.md to use these utilities
   - Estimated reduction: ~100-150 lines

3. Unify retry logic
   - Extract common retry pattern from research and planning phases
   - Create single generic implementation
   - Reduces code duplication
   - Estimated reduction: ~100-150 lines

4. Consolidate checkpoint code
   - Use extracted checkpoint utility throughout
   - Remove repeated checkpoint creation blocks
   - Estimated reduction: ~75-100 lines

**Impact**: Additional 425-600 line reduction (7-10% beyond Plan 001 target)

### Recommendation 5: Enhance Testing Strategy

**What**: Expand Phase 6 testing to cover new elements

**Why**: Ensures migration, standards, and debt reduction work correctly

**Additional Tests**:

1. **~~Checkpoint migration testing~~** (REMOVED - no migration utility)
   - Old checkpoints discarded, no migration needed
   - Breaking change acceptable per user preference

2. Content extraction independence test (automated)
   - Script: `.claude/tests/test_shared_independence.sh`
   - Temporarily moves `shared/` directory
   - Attempts to parse orchestrate.md
   - Verifies no broken references or missing critical content
   - Restores `shared/` directory
   - **Automated** (not manual as in Plan 001)

3. Standards enforcement validation (per Execution Enforcement Guide)
   - **Primary Validation**: Run `.claude/lib/audit-execution-enforcement.sh .claude/commands/orchestrate.md`
   - **Target Score**: ≥95/100 (per Standard 0 compliance requirements)
   - **Secondary Validation**: Run `.claude/lib/audit-imperative-language.sh .claude/commands/orchestrate.md`
   - **Target Imperative Ratio**: ≥90% (per Imperative Language Guide)
   - Check for minimum pattern counts:
     - EXECUTE NOW markers: ≥12
     - MANDATORY VERIFICATION blocks: ≥8
     - CHECKPOINT REQUIREMENT blocks: ≥6
     - Task invocation templates: ≥5
   - Validate zero weak language (should/may/can/consider/try to)
   - Test file creation rate: 10/10 trials (100% target per Verification-Fallback Pattern)

4. Retry template generator testing
   - Unit test for `generate_retry_template()` function
   - Verify all 6 template variations can be generated
   - Compare generated templates to original hand-written versions
   - Ensure enforcement language preserved

5. Utility function testing
   - Test `verify_file_exists_with_content()` with various file states
   - Test `retry_agent_with_templates()` with mock agent failures
   - Test `save_phase_checkpoint()` with various phase configurations

**Impact**: Comprehensive validation of all changes, prevents regressions

### Recommendation 6: Consider Phased Implementation Approach

**What**: Split Plan 001 execution into multiple smaller, testable increments

**Why**: Reduces risk, allows validation at each step, easier rollback if issues

**Suggested Phasing**:

**Increment 1: Preparation (Recommendation 1)**
- **~~Checkpoint migration utility~~** (REMOVED - not needed)
- Phase 8 resolution
- Content extraction matrix
- Expansion limits definition
- **Deliverable**: Decisions documented (no migration tools)
- **Validation**: **~~Migration utility tested~~** (N/A - no migration)

**Increment 2: Phase Removal (Plan 001 Phases 2-3)**
- Remove Phase 2.5
- Remove Phase 4
- **Deliverable**: ~800 lines removed, phases still non-sequential
- **Validation**: Orchestrate workflow still functional, no expansion occurs

**Increment 3: Phase Renumbering (Plan 001 Phase 4)**
- Sequential numbering 0-6
- Update all cross-references
- **Deliverable**: Clean phase sequence
- **Validation**: All internal references correct, no broken links

**Increment 4: Content Extraction (Plan 001 Phase 5)**
- Extract to 5 shared/ files per matrix
- Update references
- **Deliverable**: ~30-40% total reduction achieved
- **Validation**: Independence test passes

**Increment 5: Standards Enforcement (Recommendation 2)**
- Add enforcement markers
- **~~Strengthen fallbacks~~** (REMOVED - not wanted)
- Add pruning policy
- Eliminate passive language
- **Deliverable**: Standards-compliant command (predictable behavior focus)
- **Validation**: Audit score improvement (excluding fallback criteria)

**Increment 6: Technical Debt Reduction (Recommendation 3)**
- Template consolidation
- Utility extraction
- Retry unification
- **Deliverable**: Additional 5-10% reduction
- **Validation**: All tests pass, utilities work

**Increment 7: Comprehensive Testing (Recommendation 4)**
- All validation tests
- Integration testing
- Performance benchmarking
- **Deliverable**: Fully validated simplified orchestrate
- **Validation**: All success criteria met

**Impact**: Lower risk, better validation, easier troubleshooting

## Revised Success Criteria

**Original Plan 001 Criteria** (maintained):
- [ ] File size reduced from 6,304 lines to 3,600-4,200 lines (30-40%)
- [ ] Phase numbering sequential (0-6, not 0,1,2,2.5,4,5,6,7,8)
- [ ] Phase 2.5 (Complexity Evaluation) removed
- [ ] Phase 4 (Plan Expansion) removed
- [ ] User prompted for expansion after Phase 2 (using AskUserQuestion)
- [ ] Content extracted to 5 shared/ reference files
- [ ] /expand command enhanced to handle complexity evaluation
- [ ] All cross-references updated
- [ ] All tests passing

**Additional Criteria** (from recommendations):
- [ ] **~~Checkpoint migration utility created and tested~~** (REMOVED - old checkpoints discarded)
- [ ] Phase 8 ambiguity resolved and documented
- [ ] Content extraction matrix defined and followed
- [ ] Expansion depth limits specified (max 2 levels)
- [ ] /collapse integration decision documented
- [ ] Standard 0 enforcement markers added throughout (≥12 EXECUTE NOW, ≥8 MANDATORY VERIFICATION, ≥6 CHECKPOINT)
- [ ] **~~Fallback mechanisms strengthened per Verification pattern~~** (REMOVED - predictable behavior preferred)
- [ ] Aggressive context pruning policy implemented (<20% context usage target)
- [ ] All passive language eliminated (≥90% imperative ratio verified via audit script)
- [ ] Phase 0 orchestrator role clarification added (per Standard 0 Phase 0 Requirement)
- [ ] Audit score ≥95/100 (validated via `.claude/lib/audit-execution-enforcement.sh`)
- [ ] Imperative ratio ≥90% (validated via `.claude/lib/audit-imperative-language.sh`)
- [ ] File creation rate 100% (10/10 test trials)
- [ ] Retry templates consolidated into parameterized generator
- [ ] Verification utilities extracted to agent-operations.sh
- [ ] Retry logic unified across research and planning
- [ ] Checkpoint code consolidated using utility
- [ ] Additional testing: **~~migration~~**, independence, standards, utilities
- [ ] Standards compliance validated:
  - [ ] Audit score ≥95/100 (execution enforcement)
  - [ ] Imperative ratio ≥90% (language strength)
  - [ ] File creation rate 100% (reliability)
  - [ ] Pattern counts meet minimums (12 EXECUTE NOW, 8 MANDATORY, 6 CHECKPOINT)
- [ ] Phased implementation approach validated at each increment

## Integration Considerations

### Alignment with .claude/docs/ Vision

**Key Documents to Integrate**:
1. **Command Development Guide** - Ensure simplified orchestrate follows all patterns
2. **Execution Enforcement Guide** - Apply Standards 0 & 0.5 throughout
3. **Verification and Fallback Pattern** - Strengthen reliability
4. **Context Management Pattern** - Apply aggressive pruning for orchestration
5. **Behavioral Injection Pattern** - Maintain pure orchestrator role

**Potential Conflicts**:
- **~~Fallback removal (Plan 071) vs Fallback strengthening (Recommendation 2)~~** (RESOLVED)
  - **Resolution**: Fallback strengthening REMOVED from plan per user preference
  - User prefers predictable behavior and simplicity
  - Auto-retry with escalation templates provides sufficient reliability

- Simplification goal vs Standards enforcement additions
  - **Resolution**: Standards add enforcement *language*, not substantial code
  - Net impact: ~50-100 lines added for enforcement, but ~800+ removed from Phase 2.5/4
  - Overall still achieves 30-40% reduction target

### Alignment with Plan 001 Original Vision

**Plan 001 Core Objectives** (preserve these):
1. Remove automatic complexity evaluation (Phase 2.5)
2. Remove automatic plan expansion (Phase 4)
3. Restore user agency (prompt for expansion decision)
4. Achieve 30-40% file size reduction
5. Sequential phase numbering

**This Improvement Plan**:
- ✅ Preserves all 5 core objectives
- ✅ Adds preparation to prevent breaking changes
- ✅ Strengthens reliability through standards
- ✅ Reduces technical debt for additional savings
- ✅ Enhances testing for validation

**No Conflicts** - Recommendations are additive, not replacing

### Integration with Current Implementation

**Current State After Plan 071**:
- Auto-retry mechanism implemented
- Fallback mechanisms removed (orchestrator-level)
- Template escalation working
- ⚠️ Workflow summary reporting creates unnecessary artifacts (should be simplified)

**This Plan's Impact**:
- **~~Checkpoint migration~~** (REMOVED - old checkpoints discarded, breaking change acceptable)
- Standards enforcement complements Plan 071 work
- Technical debt reduction includes Plan 071 retry templates
- Summary artifact creation removed (Recommendation 3)
- No breaking changes to Plan 071 completed work

**Integration Strategy**:
1. Plan 071 work is **orthogonal** to Plan 070/002
2. **~~Checkpoint migration preserves Plan 071 functionality~~** (REMOVED - not preserving old checkpoints)
3. Template consolidation improves Plan 071 maintainability
4. Standards enforcement strengthens Plan 071 reliability patterns

## Open Questions for Revision

These questions should be resolved before finalizing this improvement plan:

1. **Phase 8 Resolution**: Merge into Phase 3 or keep as Phase 6?
   - Recommendation: Keep as Phase 6 (clearer)
   - Needs: User/maintainer decision

2. **~~Fallback Philosophy~~**: **RESOLVED** - No fallbacks wanted
   - User prefers predictable behavior and simplicity
   - Auto-retry with escalation templates provides sufficient reliability

3. **Scope**: Is this plan too large? Should it be split?
   - Current: 7 increments covering preparation + simplification + standards + debt
   - Alternative: Focus only on Plan 001 core, defer standards/debt to separate plan
   - Needs: Scope decision based on urgency and resources

4. **~~Migration Timing~~**: **RESOLVED** - No migration
   - Old checkpoints discarded (breaking change acceptable)
   - Users must complete or abandon in-progress workflows before upgrade

5. **Content Extraction Matrix**: Should this be created before or during Phase 5?
   - Recommendation: Create during preparation (before Phase 5)
   - Needs: Confirm approach acceptable

6. **Utility Extraction Scope**: Create agent-operations.sh or use existing libs?
   - Recommendation: New file for orchestrate-specific utilities
   - Alternative: Add to existing `.claude/lib/` utilities
   - Needs: Architecture decision

## Next Steps

1. **Review this draft** with project maintainer/user
2. **Resolve open questions** (especially Phase 8, scope, fallback philosophy)
3. **Create content extraction matrix** during preparation phase
4. **Revise Plan 001** to incorporate accepted recommendations
5. **OR Create Plan 002** as separate plan if scope too large for Plan 001
6. **Begin implementation** using phased approach (Increment 1 → 7)

## Summary

This improvement plan addresses **critical gaps** identified in Plan 001 research:
- **~~Migration path for checkpoints~~** (REMOVED - old checkpoints discarded)
- ✅ Phase 8 ambiguity resolution
- ✅ Content extraction matrix
- ✅ Expansion depth limits
- ✅ /collapse integration decision

It also strengthens **standards alignment**:
- ✅ Standard 0 enforcement markers
- **~~Fallback mechanisms~~** (REMOVED - predictable behavior preferred)
- ✅ Context pruning policy
- ✅ Imperative language
- ✅ Orchestrator role clarification

And reduces **technical debt**:
- ✅ Template consolidation
- ✅ Utility extraction
- ✅ Retry unification
- ✅ Checkpoint consolidation
- ✅ Summary artifact removal (agent response pattern instead)

**Total Expected Impact**:
- File size: 6,304 → 3,160-3,760 lines (41-50% reduction vs 30-40% original target)
  - Phase 2.5/4 removal: ~817 lines
  - Technical debt reduction: ~425-600 lines
  - Summary removal: ~40-50 lines
  - Content extraction: ~800-1000 lines
  - Standards additions: +50-100 lines
- Artifact reduction: Eliminates workflow summary files
- Standards compliance (validated via audit tools):
  - Audit score: Target ≥95/100 (currently estimated 60-75/100)
  - Imperative ratio: Target ≥90% (strong enforcement language)
  - Pattern minimums: 12 EXECUTE NOW, 8 MANDATORY VERIFICATION, 6 CHECKPOINT
  - File creation rate: Target 100% (10/10 test trials)
  - Zero weak language (should/may/can/consider/try eliminated)
- Maintainability: Improved through utilities and consolidation
- Reliability: Enhanced through auto-retry with escalation (predictable behavior)
- Agent response clarity: Planning agent returns self-contained summary
- Predictability: Simplified by removing fallback complexity and checkpoint migration
- Phase 0 compliance: Explicit orchestrator role clarification per Standard 0

**This is a DRAFT** - needs revision to integrate with project vision and current state.

## Revision History

### 2025-10-23 - Revision 3
**Changes**:
- Enhanced Standard 0 marker requirements with specific minimum counts (≥12 EXECUTE NOW, ≥8 MANDATORY VERIFICATION, ≥6 CHECKPOINT)
- Added Phase 0 orchestrator role clarification requirement (per Standard 0, Phase 0 Requirement section)
- Specified validation tools: `.claude/lib/audit-execution-enforcement.sh` and `.claude/lib/audit-imperative-language.sh`
- Added specific compliance targets:
  - Audit score: ≥95/100
  - Imperative ratio: ≥90%
  - File creation rate: 100% (10/10 trials)
  - Pattern minimum counts validated
- Enhanced imperative language section with transformation table reference (Pattern 10)
- Updated testing strategy with specific audit script validation steps
- Added standards compliance sub-criteria to success criteria
- Updated total expected impact to include Phase 0 compliance

**Reason**:
User requested full compliance with `.claude/docs/` standards. The plan now specifies:
1. Exact pattern counts per Command Architecture Standards (Standard 0)
2. Phase 0 requirement for orchestrator commands (from Execution Enforcement Guide)
3. Validation using documented audit tools
4. Specific compliance targets (≥95/100 audit score, ≥90% imperative ratio)
5. File creation reliability testing (100% target per Verification-Fallback Pattern)

**Modified Sections**:
- Recommendation 2 → Task 1: Added minimum pattern counts and Pattern 1 reference
- Recommendation 2 → Task 4: Added transformation table, audit tool validation, imperative ratio target
- Recommendation 2 → Task 5: Expanded Phase 0 requirement with complete pattern from Execution Enforcement Guide
- Recommendation 5 → Test 3: Added audit script usage, specific score targets, pattern count validation
- Revised Success Criteria: Added specific compliance metrics with audit tool validation
- Summary → Total Expected Impact: Added standards compliance metrics with current baseline and targets

**Documentation References Added**:
- Command Architecture Standards (Standard 0, Phase 0 Requirement)
- Imperative Language Guide (Pattern 10, transformation table)
- Execution Enforcement Guide (Phase 0 pattern, Migration Process section)
- Behavioral Injection Pattern (agent coordination)
- Verification-Fallback Pattern (100% file creation guarantee)

### 2025-10-22 - Revision 2
**Changes**:
- Removed checkpoint migration utility (Recommendation 1, Task 1)
- Removed fallback mechanism strengthening (Recommendation 2, Task 2)
- Removed "No Migration Path for Existing Checkpoints" from Critical Gaps
- Removed "Weak Fallback Mechanisms" from Standards Alignment Issues
- Updated success criteria to mark migration and fallback items as removed
- Updated Open Questions: Resolved fallback philosophy and migration timing questions
- Updated phased implementation to remove migration-related deliverables
- Updated testing strategy to remove checkpoint migration tests
- Updated summary to reflect simplified approach
- Updated integration considerations to note conflict resolution

**Reason**:
User prefers predictable behavior and simplicity over fallback complexity and checkpoint migration:
1. Old checkpoints can be discarded (breaking change acceptable) - users must complete or abandon in-progress workflows before upgrade
2. Fallbacks add unpredictable behavior - auto-retry with escalation templates provides sufficient reliability
3. Simplification is the priority - removing these features reduces complexity and improves maintainability

**Modified Sections**:
- Critical Gaps Identified in Plan 001 (removed checkpoint gap)
- Standards Alignment Issues (marked fallback issue as removed)
- Recommendation 1 (removed checkpoint migration task)
- Recommendation 2 (removed fallback strengthening task)
- Recommendation 5 (removed checkpoint migration testing)
- Revised Success Criteria (marked migration and fallback criteria as removed)
- Integration Considerations (resolved fallback conflict)
- Open Questions for Revision (resolved fallback and migration questions)
- Suggested Phasing (removed migration deliverables)
- Summary (updated impact analysis)

### 2025-10-22 - Revision 1
**Changes**:
- Moved "Workflow summary reporting implemented" from Recent Completions to Recent Issues
- Added Recommendation 3: "Simplify Planning Agent Output (Remove Summary Artifact Creation)"
- Renumbered subsequent recommendations (3→4, 4→5, 5→6)
- Updated integration section to note summary artifact removal
- Updated total expected impact calculations to include summary removal savings (~40-50 lines)

**Reason**:
Workflow summary reporting creates unnecessary artifacts. When a plan is returned, a separate summary file is not needed. Instead, the planning agent should return a brief summary and plan reference in its response, which the orchestrator can display or pass to an implementer agent.

**Modified Sections**:
- Research Summary → Current State → Recent Completions/Issues
- Improvement Recommendations → Added new Recommendation 3
- Integration Considerations → Integration with Current Implementation
- Summary → Total Expected Impact
