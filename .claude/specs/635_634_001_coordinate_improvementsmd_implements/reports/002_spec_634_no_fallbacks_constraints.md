# Spec 634 No-Fallbacks Implementation Constraints for Spec 633 Completion

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: Analyze Spec 634 no-fallbacks implementation to understand constraints for completing Spec 633
- **Report Type**: codebase analysis
- **Source Files**:
  - `/home/benjamin/.config/.claude/specs/634_001_coordinate_improvementsmd_implements/plans/001_remove_fallback_enhance_failfast.md`
  - `/home/benjamin/.config/.claude/specs/633_infrastructure_and_standards_in_claude_docs_in/plans/001_coordinate_improvements.md`
  - `/home/benjamin/.config/.claude/commands/coordinate.md` (current state: 1,297 lines)

## Executive Summary

Spec 634 fundamentally changed the coordinate command's error handling philosophy by removing all FALLBACK MECHANISM blocks (299 lines, 18.7% reduction) that created placeholder files when agents failed. The command now implements pure fail-fast error handling where verification checkpoints immediately terminate workflows on agent failures with diagnostic output. This creates significant constraints for completing Spec 633's remaining tasks:

**Key Findings**:
1. **MANDATORY VERIFICATION checkpoints remain** (4 locations) but now trigger immediate workflow termination (not fallback creation)
2. **CHECKPOINT REQUIREMENT reporting remains** (2 locations: research + planning) and should be extended to remaining phases
3. **Documentation phase verification** was intentionally skipped (updates files vs creates files) and remains a valid incomplete task
4. **REPORT_PATHS consolidation** was deferred as optional and aligns with fail-fast philosophy (simpler code)

**Philosophical Alignment**: Spec 634 removed "silent fallbacks and graceful degradation" that violated CLAUDE.md lines 182-185. Completing Spec 633 must respect this fail-fast philosophy by avoiding any fallback-based error recovery.

## Findings

### 1. What Spec 634 Implemented

**Objective**: Remove fallback mechanisms from coordinate.md and enhance fail-fast policy documentation

**Status**: ✅ COMPLETE (commit 7ebc0463, 2025-11-10)

**What Was Removed** (299 lines total):

1. **Four FALLBACK MECHANISM blocks** (~359 lines planned, 299 actually removed):
   - Hierarchical research fallback (lines 457-540, ~83 lines)
   - Flat research fallback (lines 583-680, ~98 lines)
   - Planning phase fallback (lines 888-978, ~90 lines)
   - Debug phase fallback (lines 1371-1474, ~88 lines)

2. **Fallback-related state tracking**:
   - Removed: `FALLBACK_USED`, `FALLBACK_COUNT`, `FALLBACK_FAILURES` variables
   - Kept: `VERIFICATION_FAILURES` (detection metric, not recovery metric)

3. **Fallback status reporting in checkpoints**:
   - Removed: "Fallback mechanism used: [true/false]" from checkpoint reports
   - Kept: "Verification Status: [✓/✗]" (detection observability)

**What Was Kept** (critical for fail-fast compliance):

1. **MANDATORY VERIFICATION checkpoints** (4 locations):
   - Lines 424-474: Hierarchical research verification
   - Lines 485-538: Flat research verification
   - Lines 718-753: Planning phase verification
   - Lines 1127-1161: Debug phase verification

2. **Fail-fast error handling pattern**:
   ```bash
   if [ $VERIFICATION_FAILURES -gt 0 ]; then
     echo "❌ CRITICAL: Research artifact verification failed"
     echo "   $VERIFICATION_FAILURES reports not created at expected paths"
     echo ""
     for FAILED_PATH in "${FAILED_REPORT_PATHS[@]}"; do
       echo "   Missing: $FAILED_PATH"
     done
     echo "TROUBLESHOOTING:"
     echo "1. Review agent behavioral file"
     echo "2. Check agent invocation parameters"
     echo "3. Verify file path calculation logic"
     echo "4. Re-run workflow after fixing agent or invocation"
     handle_state_error "Agent failed to create expected artifacts" 1
   fi
   ```

3. **CHECKPOINT REQUIREMENT reporting** (2 locations):
   - Lines 543-573: Research phase checkpoint (reports verification status, next action)
   - Lines 755-787: Planning phase checkpoint (reports plan creation, verification status)

**File Size Impact**:
- Before: 1,596 lines
- After: 1,297 lines
- Reduction: 299 lines (18.7%)

### 2. Philosophical Shift: Silent Fallbacks → Fail-Fast

**CLAUDE.md Fail-Fast Policy** (lines 182-185):
```
**Fail Fast**:
- Missing files produce immediate, obvious bash errors
- Tests pass or fail immediately (no monitoring periods)
- Breaking changes break loudly with clear error messages
- No silent fallbacks or graceful degradation
```

**Spec 633 Implementation** (VIOLATED fail-fast):
- Agent fails → Verification detects → **Fallback creates placeholder** → Workflow continues
- Silent: User receives template files, deferred work required
- Graceful degradation: Workflow completes with degraded data

**Spec 634 Implementation** (COMPLIES with fail-fast):
- Agent fails → Verification detects → **Immediate error with diagnostics** → Workflow terminates
- Loud: Clear error message listing missing files and troubleshooting steps
- No degradation: Workflow stops at first failure, forces root cause fix

**Critical Distinction** (Spec 057, Report 001):

Spec 634's analysis clarified three fallback types:

1. **Bootstrap fallbacks** (PROHIBITED): Hide configuration errors
   - Example: Silent function definitions when libraries missing
   - Spec 057 removed 32 lines of these from /supervise

2. **Verification fallbacks** (WAS REQUIRED, NOW REMOVED): Create placeholder files when agents fail
   - Example: Fallback file creation in Spec 633 coordinate.md
   - **Spec 634 determination**: These mask agent failures (orchestrator responsibility creep)
   - **New approach**: Agents own file creation, orchestrator verifies and fails fast

3. **Optimization fallbacks** (ACCEPTABLE): Performance cache degradation
   - Example: State persistence graceful degradation (recalculate if cache missing)
   - Rationale: Cache is optimization, not requirement

**Key Insight**: Spec 634 reclassified Spec 633's "verification fallbacks" from REQUIRED to PROHIBITED because they implement silent degradation (orchestrator creating files on behalf of failed agents) rather than error detection (exposing agent failures immediately).

### 3. Spec 633 Incomplete Tasks Analysis

**From Report 001** (Spec 635 research):

#### Phase 3: Add Checkpoint Reporting to All Phases

**Status**: Partial completion (2 of 6 phases)

**Completed**:
- ✓ Research phase checkpoint reporting (line 543)
- ✓ Planning phase checkpoint reporting (line 755)

**Incomplete** (deferred to Phase 4):
- [ ] Implementation phase checkpoint reporting (intended line ~770)
- [ ] Testing phase checkpoint reporting (intended line ~860)
- [ ] Debug phase checkpoint reporting (intended line ~980)
- [ ] Documentation phase checkpoint reporting (intended line ~1100)

**Constraint from Spec 634**:
- **COMPATIBLE** - Checkpoint reporting is observability (not fallback creation)
- Template already proven in research/planning phases
- Must NOT include "Fallback used" metrics (removed by Spec 634)
- Must include verification status (detection metric, acceptable)

**Recommendation**: ✅ **COMPLETE THIS TASK** (1 hour effort)
- Apply existing checkpoint template from lines 543-573 to 4 remaining phases
- Remove any fallback-related metrics from template
- Focus on verification status, artifact counts, next action

#### Phase 4: Extend Verification and Fallback to Remaining Phases

**Status**: Partial completion (verification done, fallback removed)

**Completed**:
- ✓ Planning phase verification (line 718)
- ✓ Debug phase verification (line 1127)
- ✓ Research phase verification (lines 424, 485)

**Incomplete**:
1. **Documentation phase verification** (intentionally skipped)
   - **Status**: Lines 351 in Spec 633 plan: "Skipped (see notes)"
   - **Reason**: "/document doesn't create files (updates existing), different verification logic"
   - **Intended verification**: File modifications (not file creation)

2. **Complete checkpoint reporting for all phases**
   - **Status**: Combined with Phase 3's deferred task (same work)

**Constraint from Spec 634**:
- **PARTIALLY COMPATIBLE** - Verification is acceptable (detection), fallback is NOT
- Original task included "Apply Phase 2 fallback pattern" → This violates Spec 634
- **Must modify approach**: Verification only, NO fallback creation

**Documentation Phase Verification Options**:

**Option A: Verify File Modifications** (COMPATIBLE with fail-fast):
```bash
# After /document invocation
echo "Verifying documentation updates..."
MODIFIED_FILES=$(git diff --name-only HEAD)
if [ -z "$MODIFIED_FILES" ]; then
  echo "❌ CRITICAL: No documentation files modified"
  echo "Expected: At least one .md file updated"
  echo "TROUBLESHOOTING:"
  echo "1. Review /document command output"
  echo "2. Check if documentation scope was empty"
  echo "3. Verify git status shows changes"
  handle_state_error "Documentation phase produced no changes" 1
fi
echo "✓ Verified: Documentation files modified"
echo "$MODIFIED_FILES" | while read file; do
  echo "  - $file"
done
```

**Option B: Skip Documentation Verification** (COMPATIBLE with fail-fast):
- Rationale: /document is supplementary (not core workflow)
- User can validate changes via git status manually
- Avoids complex verification logic for file updates

**Recommendation**: ⚠️ **OPTION B - SKIP DOCUMENTATION VERIFICATION** (0 effort)
- Documentation phase is least critical (research/plan/implement are core)
- File modification verification adds complexity (git status, modification times)
- Fail-fast principle: Simple error paths, avoid defensive code
- User can manually verify: `git diff` after workflow completion

#### Phase 5: Documentation and Cleanup

**Status**: Mostly complete (1 optional task deferred)

**Completed**:
- ✓ Created bash-block-execution-model.md (581 lines)
- ✓ Documented subprocess isolation patterns
- ✓ Added cross-references to guides
- ✓ Ran validation scripts

**Incomplete**:
- [ ] Optional: Consolidate REPORT_PATHS reconstruction (3 locations → 1 function)
  - **Status**: Lines 441 in Spec 633 plan: "Deferred (not needed for reliability goals)"
  - **Reason**: "Conservative approach, only obvious simplifications"
  - **Scope**: Extract from lines 296, 530, 680 in coordinate.md to workflow-initialization.sh

**Constraint from Spec 634**:
- **FULLY COMPATIBLE** - Code consolidation aligns with fail-fast philosophy
- Simpler code = clearer error paths = better fail-fast compliance
- No fallback mechanisms involved (pure refactoring)

**Recommendation**: ✅ **COMPLETE THIS TASK** (optional, 1 hour effort)
- Consolidation reduces defensive duplication (Spec 629 identified 70%)
- Aligns with Spec 634 philosophy: lean executable files
- Minimal risk (proven pattern, no functional change)
- Can be deferred if time-constrained (not critical)

### 4. Tasks That Violate Spec 634 Philosophy

**PROHIBITED TASKS** (from original Spec 633):

1. **"Apply Phase 2 fallback pattern to planning phase"** (Phase 4, line 348)
   - ❌ VIOLATES fail-fast: Would create placeholder plan when /plan fails
   - Spec 634 explicitly removed planning phase fallback (lines 888-978)

2. **"Apply Phase 2 fallback pattern to debug phase"** (Phase 4, line 350)
   - ❌ VIOLATES fail-fast: Would create placeholder debug report when /debug fails
   - Spec 634 explicitly removed debug phase fallback (lines 1371-1474)

3. **"Create phase-specific fallback templates"** (Phase 4, line 352)
   - ❌ VIOLATES fail-fast: Fallback templates enable silent degradation
   - Spec 634 removed all fallback templates from coordinate.md

4. **Any checkpoint reporting of "Fallback used" metrics** (Phase 3, Phase 4)
   - ❌ VIOLATES fail-fast: No fallback mechanisms should exist to report on
   - Spec 634 removed fallback status from checkpoint reports

**MODIFICATION REQUIRED** (tasks that need revised approach):

1. **"Update checkpoint reporting to include verification metrics for all phases"** (Phase 4, line 355)
   - ⚠️ PARTIAL VIOLATION: Original task included fallback metrics
   - ✅ COMPATIBLE VERSION: Include verification status only (not fallback usage)
   - Modified task: "Add checkpoint reporting with verification status (no fallback metrics)"

### 5. Recommended Approach for Completing Spec 633

**Valid Remaining Tasks** (align with Spec 634):

1. **Extend checkpoint reporting to phases 4-6** (Phase 3 deferred task)
   - Implementation: Apply template from lines 543-573 to implementation/test/debug/document phases
   - Effort: 1 hour
   - Risk: Low (proven pattern)
   - Value: High (consistent observability)

2. **Optional: Consolidate REPORT_PATHS reconstruction** (Phase 5 deferred task)
   - Implementation: Extract to workflow-initialization.sh function
   - Effort: 1 hour
   - Risk: Low (refactoring only)
   - Value: Medium (code cleanliness, aligns with fail-fast simplicity)

**Tasks to Skip** (violate Spec 634):

3. **Documentation phase verification** (Phase 4 incomplete)
   - Reason: Complex verification logic for file updates, low value
   - Alternative: Manual verification via git status
   - Effort saved: 1-2 hours

4. **All fallback mechanism implementation** (Phase 4 original scope)
   - Reason: Directly contradicts Spec 634 removals
   - Spec 634 determined: Fallbacks mask agent failures (wrong ownership model)

**Total Remaining Effort**: 1-2 hours (checkpoint reporting only, consolidation optional)

### 6. Philosophical Alignment Guide

**Fail-Fast Principles** (from Spec 634 implementation):

1. **Agents own file creation** (not orchestrator)
   - Agent behavioral files define artifact creation responsibility
   - Orchestrator verifies and fails fast if agent doesn't deliver
   - No orchestrator fallback creation (wrong separation of concerns)

2. **Loud failures over silent degradation**
   - Verification failures terminate workflow immediately
   - Diagnostic output includes troubleshooting steps (not placeholder files)
   - User fixes root cause (agent or invocation) before re-running

3. **Observability through detection, not recovery**
   - Track verification failures (detection metric)
   - Do NOT track fallback usage (no recovery mechanisms)
   - Checkpoint reporting shows what succeeded/failed (not what was recovered)

4. **Simplicity over defensive complexity**
   - 299 lines removed = clearer code paths
   - Less code = easier to debug = faster to fail-fast
   - Defensive duplication (Spec 629: 70%) should be eliminated, not added

**Decision Matrix for Spec 633 Tasks**:

| Task | Adds Fallback? | Adds Observability? | Simplifies Code? | Verdict |
|------|----------------|---------------------|------------------|---------|
| Extend checkpoint reporting | No | ✓ Yes | Neutral | ✅ COMPLETE |
| Documentation phase verification | No | Minor | Adds complexity | ⚠️ SKIP |
| Consolidate REPORT_PATHS | No | No | ✓ Yes | ✅ OPTIONAL |
| Apply fallback patterns | ✓ Yes (PROHIBITED) | No | No (adds 359 lines) | ❌ REJECT |

## Recommendations

### Recommendation 1: Complete Checkpoint Reporting Extension (High Priority)

**Task**: Extend CHECKPOINT REQUIREMENT blocks to implementation, test, debug, and document phases

**Effort**: 1 hour

**Compatibility**: ✅ FULLY COMPATIBLE with Spec 634
- Observability mechanism (not recovery mechanism)
- Proven template from research/planning phases (lines 543-573)
- Must remove any fallback-related metrics from template

**Implementation**:
1. Copy checkpoint template from lines 543-573 (research phase)
2. Adapt metrics for each phase:
   - **Implementation**: Phases completed, test status, git commits created
   - **Testing**: Test exit code, pass/fail counts, next action (document or debug)
   - **Debug**: Debug report path, analysis complete, user intervention required
   - **Documentation**: Files modified count, documentation scope, workflow complete
3. Insert after state transitions in each phase handler
4. Test checkpoint output format consistency

**Template** (adapted from research phase):
```bash
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: [Phase] Phase Complete"
echo "═══════════════════════════════════════════════════════"
echo "[Phase]-specific status before transitioning to next state:"
echo ""
echo "  Artifacts Created:"
echo "    - [Phase-specific artifact list]"
echo ""
echo "  Verification Status:"
echo "    - All files verified: [✓/✗]"
echo ""
echo "  Next Action:"
echo "    - Proceeding to: [Next State]"
echo "═══════════════════════════════════════════════════════"
echo ""
```

**Value**: Consistent observability across all workflow phases, aids debugging

### Recommendation 2: Skip Documentation Phase Verification (Low Priority)

**Task**: Add verification checkpoint after /document invocation (Spec 633 Phase 4)

**Effort**: 1-2 hours (if pursued)

**Compatibility**: ⚠️ PARTIAL COMPATIBILITY with Spec 634
- File modification verification is complex (git status, modification times)
- Documentation phase is supplementary (not core workflow)
- Fail-fast principle: Avoid defensive complexity

**Rationale for Skipping**:
1. **Different verification pattern**: Updates files vs creates files (requires custom logic)
2. **Low criticality**: Research/plan/implement are core, documentation is supplementary
3. **Manual verification available**: User can run `git status` or `git diff` post-workflow
4. **Complexity vs value trade-off**: 1-2 hours implementation for minor observability gain

**Alternative**: Document expected manual verification in coordinate-command-guide.md
```markdown
## Documentation Phase

The /coordinate workflow invokes /document to update relevant documentation.
Verification: Run `git status` after workflow completion to review documentation changes.
No automated verification checkpoint (updates existing files, not creates new artifacts).
```

**Value**: Minimal - user can manually verify, avoids complexity

### Recommendation 3: Optional Code Consolidation (Medium Priority)

**Task**: Consolidate REPORT_PATHS reconstruction to workflow-initialization.sh

**Effort**: 1 hour (optional)

**Compatibility**: ✅ FULLY COMPATIBLE with Spec 634
- Simplification aligns with fail-fast philosophy (simpler code = clearer failures)
- No fallback mechanisms involved (pure refactoring)
- Reduces defensive duplication identified in Spec 629 (70%)

**Implementation**:
1. Add to `.claude/lib/workflow-initialization.sh`:
   ```bash
   # Reconstruct REPORT_PATHS array from workflow state
   # Used in research, planning, and implementation phases
   reconstruct_report_paths_array() {
     local report_paths_count="${REPORT_PATHS_COUNT:-0}"
     REPORT_PATHS=()
     for ((i=0; i<report_paths_count; i++)); do
       local var_name="REPORT_PATH_$i"
       REPORT_PATHS+=("${!var_name}")
     done
   }
   ```

2. Replace inline code in coordinate.md (3 locations):
   - Line 296: Research phase handler
   - Line 530: Planning phase handler (approx, verify current line)
   - Line 680: Implementation phase handler (approx, verify current line)

3. Test state persistence across bash block boundaries

**Value**: Code cleanliness, aligns with fail-fast simplicity, reduces duplication

**Deferral Justification**: Spec 633 originally deferred as "not needed for reliability goals"
- Still true after Spec 634 (no reliability impact)
- Now has additional value: Aligns with Spec 634 code simplification philosophy

### Recommendation 4: Reject All Fallback-Related Tasks (Critical)

**Tasks to Reject**:
- Apply fallback pattern to planning phase (Spec 633 Phase 4, line 348)
- Apply fallback pattern to debug phase (Spec 633 Phase 4, line 350)
- Create phase-specific fallback templates (Spec 633 Phase 4, line 352)
- Report fallback usage metrics in checkpoints (Spec 633 Phase 3/4)

**Rationale**: Spec 634 established that coordinate.md fallbacks violate fail-fast philosophy
- Fallbacks create placeholder files (silent degradation)
- Orchestrator should not own file creation (agent responsibility)
- 299 lines removed = simpler, clearer code paths
- Fail-fast: Expose agent failures immediately, force root cause fixes

**Impact**: Spec 633 reliability goals (100% file creation) redefined
- Original approach: Verification + fallback = 100% orchestrator-created files
- Spec 634 approach: Verification + fail-fast = 100% agent-created files (or workflow termination)
- New definition of reliability: Agents succeed or workflow fails fast with clear diagnostics

## Implementation Plan for Completing Spec 633

**Phase 1: Extend Checkpoint Reporting** (1 hour, high priority)

Tasks:
1. Read research phase checkpoint template (coordinate.md:543-573)
2. Adapt template for implementation phase metrics
3. Insert after line ~817 (implementation → test transition)
4. Adapt template for testing phase metrics
5. Insert after line ~1019 (test → debug/document transition)
6. Adapt template for debug phase metrics
7. Insert after line ~1166 (debug → complete transition)
8. Adapt template for documentation phase metrics
9. Insert after line ~1288 (document → complete transition)
10. Test checkpoint output in full workflow execution

Validation:
```bash
# Execute full workflow
/coordinate "Research, plan, and implement feature X"

# Verify checkpoint output after each phase
# Expected: CHECKPOINT output at end of implementation, test, debug, document phases
# Format matches research/planning checkpoint structure
# No fallback metrics present (only verification status)
```

**Phase 2 (Optional): Consolidate REPORT_PATHS** (1 hour, medium priority)

Tasks:
1. Add `reconstruct_report_paths_array()` to workflow-initialization.sh
2. Update coordinate.md line ~315 (research phase): Call function instead of inline code
3. Update coordinate.md line ~654 (planning phase): Call function instead of inline code
4. Update coordinate.md line ~unused? (verify if implementation phase actually uses it)
5. Test state persistence across bash block boundaries
6. Run all automated tests to verify no regressions

Validation:
```bash
# Execute multi-phase workflow
/coordinate "Research (3 topics), plan, and implement"

# Verify REPORT_PATHS correctly reconstructed in each phase
# Check workflow state file contains REPORT_PATH_0, REPORT_PATH_1, REPORT_PATH_2
# Verify planning phase accesses all research reports
```

## Testing Requirements

**Test 1: Checkpoint Reporting Consistency**
```bash
# Execute full workflow
/coordinate "Research authentication, create plan, implement, test, document"

# Verify checkpoint output after each phase
# Assert: Consistent format across all 6 phases
# Assert: No fallback metrics present
# Assert: Verification status included
```

**Test 2: Fail-Fast Verification (No Fallback)**
```bash
# Simulate agent failure (temporarily break research-specialist.md)
# Run /coordinate with research-only workflow
# Expected: MANDATORY VERIFICATION fails with diagnostic output
# Expected: Workflow terminates immediately (exit 1)
# Expected: NO placeholder files created
# Expected: Clear troubleshooting guidance in error message
```

**Test 3: REPORT_PATHS Consolidation (if pursued)**
```bash
# Execute workflow with state persistence
/coordinate "Research (2 topics), plan"

# Verify REPORT_PATHS array correctly reconstructed in planning phase
# Check workflow state file: REPORT_PATHS_COUNT=2, REPORT_PATH_0, REPORT_PATH_1
# Verify no regressions in subprocess isolation patterns
```

**Test 4: No Regressions from Spec 634**
```bash
# Run existing test suite
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh

# Verify coordinate.md tests pass
# Verify state machine tests pass
# Verify verification-helpers tests pass
```

## Cross-References

### Spec 634 Implementation
- **Plan**: `/home/benjamin/.config/.claude/specs/634_001_coordinate_improvementsmd_implements/plans/001_remove_fallback_enhance_failfast.md`
- **Commit**: 7ebc0463 (2025-11-10)
- **File Size**: 1,596 → 1,297 lines (299 lines removed, 18.7%)

### Spec 633 Incomplete Tasks
- **Plan**: `/home/benjamin/.config/.claude/specs/633_infrastructure_and_standards_in_claude_docs_in/plans/001_coordinate_improvements.md`
- **Analysis**: `/home/benjamin/.config/.claude/specs/635_634_001_coordinate_improvementsmd_implements/reports/001_spec_633_incomplete_tasks.md`

### Fail-Fast Philosophy Documentation
- **CLAUDE.md**: Lines 182-185 (Development Philosophy → Fail Fast section)
- **Report 001**: `/home/benjamin/.config/.claude/specs/634_001_coordinate_improvementsmd_implements/reports/001_fail_fast_policy_analysis.md`
- **Spec 057**: Bootstrap vs verification fallback distinction

### Current Coordinate.md State
- **File**: `/home/benjamin/.config/.claude/commands/coordinate.md`
- **Lines**: 1,297
- **MANDATORY VERIFICATION**: 4 locations (research x2, planning, debug)
- **CHECKPOINT REQUIREMENT**: 2 locations (research, planning)
- **FALLBACK MECHANISM**: 0 locations (all removed by Spec 634)

## Summary

Spec 634 removed all fallback mechanisms from coordinate.md (299 lines) to align with fail-fast philosophy. This creates clear constraints for completing Spec 633:

**Compatible Tasks** (should be completed):
1. ✅ Extend checkpoint reporting to 4 remaining phases (1 hour)
2. ✅ Optional: Consolidate REPORT_PATHS reconstruction (1 hour)

**Incompatible Tasks** (should be rejected):
1. ❌ Apply fallback pattern to any phases (violates fail-fast)
2. ❌ Create fallback templates (enables silent degradation)
3. ❌ Report fallback metrics (no fallbacks should exist)

**Tasks to Skip** (low value, adds complexity):
1. ⚠️ Documentation phase verification (manual verification sufficient)

**Total Remaining Effort**: 1-2 hours for essential tasks (checkpoint reporting + optional consolidation)

**Philosophical Shift**: Reliability redefined from "100% orchestrator-created files" (Spec 633 goal) to "100% agent-created files or fail-fast termination" (Spec 634 implementation). Agents own file creation responsibility; orchestrator verifies and fails fast with clear diagnostics.
