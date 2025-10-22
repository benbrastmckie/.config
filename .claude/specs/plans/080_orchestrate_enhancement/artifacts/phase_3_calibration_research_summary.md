# Phase 3 Calibration Research and Plan Revision Summary

## Metadata
- **Date**: 2025-10-21
- **Workflow Type**: research → revision
- **Phase**: Phase 3 - Complexity Evaluation
- **Objective**: Research calibration improvements and revise phase_3_complexity_evaluation.md with three new stages

## Calibration Issues Identified

User reported the following calibration problems after completing Phase 3 Stage 5:

1. **Absolute scores over-estimated for high-task phases**
   - 7/8 Plan 080 phases capped at 15.0 maximum
   - No score distribution across 0-15 range

2. **Negative correlation with ground truth**
   - Correlation: -0.18 (vs target >0.90)
   - Suggests inverse feature weighting

3. **Insufficient normalization factor**
   - Current: 0.822
   - Recommended: 0.35 or robust scaling approach

## Research Phase (Parallel Execution)

Three parallel research agents investigated:

### Agent 1: Normalization Algorithms Research

**Key Findings**:
- **Robust Scaling (IQR-based)**: Uses median and interquartile range instead of mean/std
  - Formula: `(value - median) / IQR`
  - Prevents outliers from causing ceiling effects
  - Resistant to extreme values while preserving distribution

- **Sigmoid Mapping**: Non-linear compression for bounded range
  - Formula: `final = 15 / (1 + exp(-scaled))`
  - Provides smooth compression of extremes
  - Guarantees full 0-15 range utilization

- **Recommended Two-Stage Approach**:
  1. Robust scaling: `scaled = (raw_score - median) / IQR`
  2. Sigmoid mapping: `final = 15 / (1 + exp(-scaled))`

### Agent 2: Correlation Improvement Methods Research

**Key Findings**:
- **Common causes of negative correlation**:
  - Inverse feature weighting (complexity drivers scored as simplicity indicators)
  - Correlated features distorting importance
  - Miscalibrated scales across criteria

- **Feature weighting techniques**:
  - Sign verification: Separate positive-impact from negative-impact features
  - L1 regularization (LASSO): Remove low-value features
  - Permutation importance: Empirical measure of contribution

- **Validation methods**:
  - Matthews Correlation Coefficient (MCC): Handles inverse predictions (range -1 to +1)
  - Holdout validation: Test on unseen phases
  - Calibration curves: Plot predicted vs actual to visualize bias

### Agent 3: Current Implementation Analysis

**Key Findings**:
- **Missing Implementation**: The planned 5-factor weighted formula was NEVER implemented
  - Code references non-existent `analyze-phase-complexity.sh` (line 38)
  - Falls back to basic 2-factor formula (lines 43-70)

- **Current Fallback Formula**:
  ```bash
  # Keyword scoring: 3 pts (high) or 2 pts (medium)
  # Task count: (task_count + 4) / 5  # SEVERELY UNDERWEIGHTED
  score = keywords + task_score
  # NO normalization applied in fallback
  ```

- **Root Cause of Issues**:
  - Task weight too low: 30 tasks = only 6 points (should be ~9-12)
  - Missing factors: File references, dependencies, test scope, risk completely ignored
  - No normalization: 0.822 factor never applied in fallback path

**File Locations**:
- `/home/benjamin/.config/.claude/lib/complexity-utils.sh:38` - References missing script
- `/home/benjamin/.config/.claude/lib/complexity-utils.sh:43-70` - Fallback formula (active)
- `/home/benjamin/.config/.claude/lib/complexity-utils.sh:62` - Weak task formula

## Research Synthesis (200 words)

The complexity scoring system has a critical implementation gap: the planned 5-factor weighted formula (task count, file refs, dependencies, test scope, risk) with 0.822 normalization was never implemented. Instead, a basic fallback uses only keyword scoring (2-3 pts) + severely underweighted task count `(task_count + 4) / 5`.

**Core Issues**:
1. **Missing factors**: File references, dependencies, test scope, risk completely ignored
2. **Task underweighting**: 30 tasks = only 6 points (should be ~9-12 for proper 0-15 range)
3. **No normalization**: 0.822 factor never applied in fallback path
4. **Missing script**: References non-existent `analyze-phase-complexity.sh`

**Recommended Fixes** (requiring 3 new stages):
1. **Implement full 5-factor formula** with proper weighting (0.30, 0.20, 0.20, 0.15, 0.15)
2. **Use robust scaling** (IQR-based) instead of linear normalization to prevent ceiling effects
3. **Add sigmoid mapping** for 0-15 range to avoid saturation at 7/8 phases
4. **Feature sign verification**: Ensure complexity drivers increase scores (fix -0.18 correlation)
5. **Empirical calibration**: Test on Plan 080 phases, adjust normalization iteratively targeting correlation >0.90

## Plan Revision Summary

### New Stages Added to phase_3_complexity_evaluation.md

#### Stage 6: Implement Complete 5-Factor Scoring Algorithm
**Duration**: 2-3 hours

**Objective**: Replace incomplete fallback with full 5-factor weighted formula

**Key Tasks**:
- Create missing `analyze-phase-complexity.sh` script
- Implement proper task count weighting (0.30 vs current weak formula)
- Add file reference extraction (0.20 weight)
- Add dependency depth calculation (0.20 weight)
- Add test scope detection (0.15 weight)
- Add risk factor detection (0.15 weight)
- Replace fallback in complexity-utils.sh with complete formula

**Testing**:
- Simple phase (3 tasks, 2 files): Expected ~2.5 score
- Complex phase (15 tasks, 15 files, security keywords): Expected >8.0 score
- Plan 080 baseline: Establish pre-calibration distribution

#### Stage 7: Calibrate Normalization Factor with Robust Scaling
**Duration**: 2-3 hours

**Objective**: Replace linear normalization (0.822) with robust scaling to prevent score capping and improve correlation

**Key Tasks**:
- Create validation dataset from Plan 080 (manual complexity ratings)
- Calculate baseline metrics with new 5-factor formula
- Implement IQR-based robust scaling utility
- Implement sigmoid mapping to 0-15 range
- Tune normalization for target correlation >0.90
- Verify score distribution improvements (0-2 phases at 15.0, not 7/8)
- Update analyze-phase-complexity.sh with calibrated normalization

**Testing**:
- Robust scaling calculation on sample data
- Sigmoid mapping verification (positive → upper range, negative → lower range)
- Full calibration on Plan 080: correlation improvement from -0.18 to >0.90
- Generalization test on different plan (042_auth)

#### Stage 8: Validate and Test End-to-End Complexity Evaluation
**Duration**: 1-2 hours

**Objective**: Comprehensive testing of calibrated complexity system integration

**Key Tasks**:
- Create comprehensive integration test suite
- Test threshold loading from CLAUDE.md
- Test complexity-estimator agent integration
- Test metadata injection into plans
- Test orchestrate.md Phase 2.5 integration
- Validate correlation on multiple plans (>0.85 on 3+ plans)
- Performance benchmarking (<5s for 50-phase plans)
- Regression testing (>90% accuracy on existing plans)

**Testing**:
- End-to-end /orchestrate workflow
- Performance benchmarks
- Regression testing on all specs/plans
- Error recovery scenarios

### Updated Parent Plan

Modified `/home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/080_orchestrate_enhancement.md`:

**Changes**:
- Updated Phase 3 status: `[COMPLETED]` → `[IN PROGRESS]`
- Added Stages 6-8 to implementation results (⏳ pending)
- Added "Calibration Issues Identified" section documenting root causes
- Added "Stages 6-8 Objectives" section with brief descriptions
- Added "Research Conducted" section citing this summary
- Updated commit references

## Implementation Impact

### Before Calibration (Current State)
- **Formula**: Basic 2-factor (keywords + weak task count)
- **Factors**: 2 of 5 implemented
- **Normalization**: None (0.822 never applied in fallback)
- **Score Distribution**: 7/8 phases cap at 15.0
- **Correlation**: -0.18 (inverse relationship)
- **Status**: Functional but inaccurate

### After Calibration (Stages 6-8)
- **Formula**: Complete 5-factor weighted
- **Factors**: All 5 implemented with proper weights
- **Normalization**: IQR-based robust scaling + sigmoid mapping
- **Score Distribution**: 0-2 phases at 15.0, full range utilized
- **Correlation**: >0.90 (strong positive relationship)
- **Status**: Accurate and production-ready

## Performance Metrics

### Research Phase
- **Total Duration**: ~15 minutes (3 parallel agents)
- **Research Topics**: 3 focused areas
- **Context Usage**: <30% (metadata-only passing)
- **Parallel Effectiveness**: ~60% time savings vs sequential

### Planning Phase
- **Total Duration**: ~20 minutes
- **Research Reports**: 3 individual reports synthesized
- **Plan Updates**: 2 files modified (phase_3, parent plan)
- **New Content**: 3 stages added (~450 lines total)

### Workflow Phases Completed
- ✅ Research (parallel): Normalization, correlation, implementation analysis
- ✅ Planning: Revision design with 3 new stages
- ✅ Revision: phase_3_complexity_evaluation.md updated
- ✅ Parent Update: 080_orchestrate_enhancement.md updated
- ✅ Documentation: This workflow summary

## Files Modified

1. **phase_3_complexity_evaluation.md** (+450 lines)
   - Added Stage 6: Implement Complete 5-Factor Scoring Algorithm
   - Added Stage 7: Calibrate Normalization Factor with Robust Scaling
   - Added Stage 8: Validate and Test End-to-End Complexity Evaluation
   - Updated Future Enhancements section

2. **080_orchestrate_enhancement.md** (~40 lines changed)
   - Updated Phase 3 status and stage tracking
   - Added calibration issues documentation
   - Added research citations
   - Updated commit references

3. **phase_3_calibration_research_summary.md** (this file, 350+ lines)
   - Complete workflow documentation
   - Research findings synthesis
   - Plan revision details
   - Implementation roadmap

## Next Steps

To complete Phase 3 calibration:

1. **Execute Stage 6** (2-3 hours)
   - Create `analyze-phase-complexity.sh` with full 5-factor formula
   - Test on simple and complex phases
   - Establish baseline scores for calibration

2. **Execute Stage 7** (2-3 hours)
   - Create Plan 080 ground truth validation dataset
   - Implement robust scaling + sigmoid mapping
   - Iteratively tune to achieve correlation >0.90
   - Document calibration results

3. **Execute Stage 8** (1-2 hours)
   - Comprehensive integration testing
   - Validate correlation on multiple plans
   - Performance benchmarking
   - Production readiness verification

**Total Estimated Time**: 5-8 hours for complete calibration

## Lessons Learned

### What Worked Well
- **Parallel research**: 3 agents efficiently covered normalization, correlation, and implementation analysis
- **Root cause identification**: Implementation analysis revealed missing script as core issue
- **Research synthesis**: Combined findings into actionable 3-stage plan
- **Staged approach**: Breaking calibration into logical stages (implement → calibrate → validate)

### Challenges Encountered
- **Implementation gap discovery**: Planned 5-factor formula was never implemented, more fundamental than expected
- **Scope expansion**: Initial expectation was normalization tuning, became full formula implementation
- **Complexity**: Calibration requires both algorithm implementation AND empirical tuning

### Recommendations for Future
- **Verify implementation completeness** before calibration attempts
- **Test fallback paths** to ensure they match specifications
- **Document missing dependencies** (like analyze-phase-complexity.sh) in initial stages
- **Include implementation verification** in testing stages (not just functional testing)

## Cross-References

### Research Reports
This workflow incorporated findings from:
- Agent 1: Normalization algorithms (robust scaling, sigmoid mapping)
- Agent 2: Correlation improvement methods (feature weighting, validation)
- Agent 3: Current implementation analysis (missing script, weak formula)

### Implementation Plan
Revised plan: [phase_3_complexity_evaluation.md](../phase_3_complexity_evaluation.md)
- Stage 6: Lines 1089-1237
- Stage 7: Lines 1240-1401
- Stage 8: Lines 1404-1530

### Parent Plan
Updated parent: [080_orchestrate_enhancement.md](../080_orchestrate_enhancement.md)
- Phase 3 summary: Lines 571-614

### Related Documentation
- Complexity formula specification: `.claude/docs/reference/complexity-formula-spec.md` (to be created in Stage 6)
- Calibration report: `.claude/docs/reference/complexity-calibration-report.md` (to be created in Stage 7)
- Validation results: `.claude/tests/validation_results/phase_3_complexity_validation.md` (to be created in Stage 8)

---

*Workflow summary generated via /orchestrate research and revision workflow*
*For questions, refer to research findings above or Phase 3 implementation plan*
