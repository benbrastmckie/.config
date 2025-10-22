# Complexity Algorithm Archive

This directory contains the deprecated 5-factor algorithmic complexity scoring system implemented during Phase 3 Stages 6-7 (OLD). Archived on 2025-10-22 during Phase 3.4.

## Why Archived

The algorithm achieved 0.7515 correlation with ground truth, but was superseded by pure agent-based assessment achieving 1.0000 perfect correlation.

**Performance Comparison**:
- Algorithm correlation: 0.7515
- Agent correlation: 1.0000 (perfect)
- Algorithm development time: ~8 hours (research, formula, calibration)
- Agent development time: ~4 hours (few-shot examples, validation)

**Technical Limitations**:
- Ceiling effects (3/8 phases maxed at 15.0)
- Factor caps prevented accurate high-complexity scoring
- Task dominance (80% weight) overshadowed semantic complexity
- Collapsed phase handling required special-casing

**Agent Advantages**:
- Semantic understanding ("auth migration" > "15 doc tasks")
- Natural edge case handling (collapsed phases, context-dependent risk)
- No formula tuning needed (few-shot calibration sufficient)
- Transparent reasoning (natural language explanations)

## Contents

### lib/
Algorithm implementation utilities:
- `analyze-phase-complexity.sh`: Main complexity scoring script (5-factor formula)
- `complexity-utils.sh`: Utility functions for complexity calculation
- `robust-scaling.sh`: IQR-based outlier-resistant scaling functions

### docs/
Formula specification and calibration reports:
- `complexity-formula-spec.md`: Complete 5-factor formula specification
- `complexity-calibration-report.md`: Grid search calibration results and analysis

### tests/
Algorithm validation tests:
- `test_complexity_basic.sh`: Basic formula implementation tests
- `test_complexity_baseline.sh`: Baseline correlation tests
- `test_complexity_calibration.py`: Calibration script (grid search)
- `test_complexity_calibration_v2.py`: Enhanced calibration with robust scaling
- `test_hybrid_complexity.sh`: Hybrid algorithm/agent approach tests

## Historical Value

This research informed the few-shot calibration examples used in complexity-estimator.md. The ground truth dataset and calibration insights remain valuable for future work.

**Retained Artifacts**:
- Ground truth dataset: `.claude/tests/fixtures/complexity/plan_080_ground_truth.yaml`
- Agent specification: `.claude/agents/complexity-estimator.md`
- Agent validation: `.claude/specs/plans/080_orchestrate_enhancement/phase_3_stage_7_agent_validation.md`

## Migration Path

If you need to reference the algorithm:

1. **For formula details**: See `docs/complexity-formula-spec.md`
2. **For calibration insights**: See `docs/complexity-calibration-report.md`
3. **For ground truth data**: See `.claude/tests/fixtures/complexity/plan_080_ground_truth.yaml`
4. **For active system**: Use `.claude/agents/complexity-estimator.md` (pure agent approach)

## Statistics

- **Total lines archived**: ~3,900 lines (code, tests, documentation)
- **Files archived**: 8 files (~790KB)
- **Development time**: ~8 hours (2025-10-21)
- **Superseded**: 2025-10-21 (same day, architectural pivot)
- **Archive date**: 2025-10-22 (Phase 3.4 Stage 3)

## References

- [Phase 3 Agent-Based Research](../../specs/plans/080_orchestrate_enhancement/artifacts/phase_3_agent_based_research.md)
- [Phase 3 Stage 7 Agent Validation](../../specs/plans/080_orchestrate_enhancement/phase_3_stage_7_agent_validation.md)
- [Complexity Estimator Agent](../../agents/complexity-estimator.md)
- [Adaptive Planning Configuration (CLAUDE.md)](../../CLAUDE.md#adaptive_planning_config)
