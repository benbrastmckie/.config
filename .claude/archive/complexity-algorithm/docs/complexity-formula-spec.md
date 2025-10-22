# Complexity Formula Specification

## Overview

The complexity evaluation formula provides a quantitative assessment of implementation plan phase complexity, enabling automated decisions about when phases should be expanded into detailed sub-plans. This specification defines the mathematical formula, measurement methodology, normalization strategy, and validation approach.

## Formula Components

The complexity score is a weighted linear combination of five factors:

### 1. Task Count (Weight: 0.30)

**Rationale**: Task volume is the primary driver of implementation complexity. More tasks mean more work, more coordination, and higher risk of overlooking details.

**Measurement**:
```bash
# Count unchecked checkbox items in phase
task_count=$(grep -c "^- \[ \]" phase_content.md)
```

**Weighting**: `task_contribution = task_count * 0.30`

**Typical Range**: 0-30 tasks
- Low (0-5): Simple phases with minimal work
- Medium (6-12): Standard phases with moderate work
- High (13-20): Complex phases requiring careful management
- Very High (21+): Phases that should likely be subdivided

### 2. File References (Weight: 0.20)

**Rationale**: The number of unique files referenced in a phase indicates integration complexity. More files mean more cross-file dependencies, more potential for conflicts, and higher coordination overhead.

**Measurement**:
```bash
# Extract unique file paths (excludes directories)
file_count=$(grep -oE '([a-zA-Z0-9_.-]+/)+[a-zA-Z0-9_.-]+\.[a-zA-Z0-9]+' phase_content.md | sort -u | wc -l)
```

**Weighting**: `file_contribution = file_count * 0.20`

**Typical Range**: 0-30 files
- Low (0-3): Isolated changes to few files
- Medium (4-8): Standard multi-file changes
- High (9-15): Broad changes across many files
- Very High (16+): System-wide changes requiring careful coordination

### 3. Dependency Depth (Weight: 0.20)

**Rationale**: Complex dependency chains increase coordination overhead. Phases that depend on multiple prior phases (or have deep transitive dependencies) are harder to schedule and execute.

**Measurement**:
```bash
# Parse dependency metadata and build dependency graph
# Calculate maximum chain length from root phases

# Example dependency metadata:
# depends_on: [phase_1, phase_2]

# Algorithm:
# 1. Build dependency graph: phase → [dependencies]
# 2. For each phase, recursively traverse dependencies
# 3. Find maximum chain length (number of phases in longest dependency path)
# 4. depth = max_chain_length
```

**Weighting**: `dependency_contribution = depth * 0.20`

**Typical Range**: 0-5 levels
- Low (0-1): Independent or direct dependencies
- Medium (2-3): Multi-level dependencies
- High (4-5): Deep dependency chains requiring careful sequencing

### 4. Test Scope (Weight: 0.15)

**Rationale**: Comprehensive testing adds complexity. Phases with extensive test requirements (unit tests, integration tests, coverage goals, test data setup) require more time and careful validation.

**Measurement**:
```bash
# Count test-related keywords in phase
test_count=$(grep -ic "test\|spec\|coverage\|testing\|validation\|verify" phase_content.md)
```

**Weighting**: `test_contribution = test_count * 0.15`

**Typical Range**: 0-10 test mentions
- Low (0-2): Minimal testing required
- Medium (3-5): Standard test coverage
- High (6-8): Comprehensive testing required
- Very High (9+): Extensive test infrastructure needed

### 5. Risk Factors (Weight: 0.15)

**Rationale**: High-risk operations (security changes, database migrations, breaking API changes) require extra care, review, and defensive implementation. Risk increases complexity beyond just task count.

**Measurement**:
```bash
# Count high-risk keywords in phase
risk_count=$(grep -ic "security\|migration\|breaking\|API change\|schema\|authentication\|authorization\|data loss\|irreversible" phase_content.md)
```

**Weighting**: `risk_contribution = risk_count * 0.15`

**Typical Range**: 0-5 risk factors
- Low (0): No high-risk operations
- Medium (1-2): Some risk considerations
- High (3-4): Multiple high-risk operations
- Very High (5+): Critical high-risk phase requiring extreme care

## Total Weight Verification

```
Total weight = 0.30 + 0.20 + 0.20 + 0.15 + 0.15 = 1.00 ✓
```

The weights sum to exactly 1.00, ensuring the formula is properly normalized.

## Raw Score Calculation

```
raw_score = (task_count * 0.30) +
            (file_references * 0.20) +
            (dependency_depth * 0.20) +
            (test_scope * 0.15) +
            (risk_factors * 0.15)
```

## Normalization Strategy

### Expected Maximum Raw Score

To prevent score inflation and ensure scores remain interpretable, we normalize to a 0.0-15.0 scale.

**Expected maximum raw score calculation**:
```
Max expected values (based on typical extreme cases):
- task_count: 30 tasks
- file_references: 30 files
- dependency_depth: 5 levels
- test_scope: 10 test mentions
- risk_factors: 5 risk keywords

expected_max_raw = (30 * 0.30) + (30 * 0.20) + (5 * 0.20) + (10 * 0.15) + (5 * 0.15)
                 = 9.0 + 6.0 + 1.0 + 1.5 + 0.75
                 = 18.25
```

### Normalization Factor

```
normalization_factor = 15.0 / expected_max_raw
                     = 15.0 / 18.25
                     = 0.8219 (rounded to 0.822)
```

### Normalized Score Formula

```
normalized_score = min(15.0, raw_score * 0.822)
```

The `min(15.0, ...)` cap ensures that extreme outliers (e.g., 50 tasks) don't produce scores above 15.0.

### Final Score

```
complexity_score = round(normalized_score, 1)  # Round to 1 decimal place
```

## Complexity Level Classification

Based on the normalized complexity score:

| Score Range | Level | Description | Expansion Recommendation |
|------------|-------|-------------|--------------------------|
| 0.0 - 3.0 | Low | Simple phase, minimal coordination | No expansion needed |
| 3.1 - 6.0 | Medium | Standard phase, moderate complexity | No expansion needed |
| 6.1 - 8.0 | Medium-High | Complex phase, careful management needed | Consider expansion if >10 tasks |
| 8.1 - 12.0 | High | Very complex phase, should be expanded | **Expansion recommended** |
| 12.1 - 15.0 | Very High | Extremely complex, must be subdivided | **Expansion mandatory** |

## Worked Examples

### Example 1: Low Complexity Phase

**Phase**: "Setup project configuration"

**Factor Measurements**:
- task_count: 3 (setup config file, create directory, update README)
- file_references: 2 (config.json, README.md)
- dependency_depth: 0 (no dependencies)
- test_scope: 1 (verify configuration loads)
- risk_factors: 0 (no high-risk operations)

**Calculation**:
```
raw_score = (3 * 0.30) + (2 * 0.20) + (0 * 0.20) + (1 * 0.15) + (0 * 0.15)
          = 0.9 + 0.4 + 0.0 + 0.15 + 0.0
          = 1.45

normalized = 1.45 * 0.822 = 1.19

complexity_score = 1.2 (rounded to 1 decimal)
complexity_level = "Low"
expansion_recommended = false
```

### Example 2: Medium Complexity Phase

**Phase**: "Implement user authentication API"

**Factor Measurements**:
- task_count: 8 (create endpoints, add validation, implement JWT, tests, docs)
- file_references: 5 (auth.ts, user.model.ts, jwt.util.ts, auth.spec.ts, auth.md)
- dependency_depth: 1 (depends on database setup phase)
- test_scope: 3 (unit tests, integration tests, coverage target)
- risk_factors: 1 (security - authentication)

**Calculation**:
```
raw_score = (8 * 0.30) + (5 * 0.20) + (1 * 0.20) + (3 * 0.15) + (1 * 0.15)
          = 2.4 + 1.0 + 0.2 + 0.45 + 0.15
          = 4.2

normalized = 4.2 * 0.822 = 3.45

complexity_score = 3.5 (rounded)
complexity_level = "Medium"
expansion_recommended = false
```

### Example 3: High Complexity Phase (Expansion Recommended)

**Phase**: "Implement multi-tenant data isolation with row-level security"

**Factor Measurements**:
- task_count: 15 (multiple tasks for schema, policies, migrations, tests, rollback)
- file_references: 12 (migrations, models, policies, tests, docs across multiple modules)
- dependency_depth: 2 (depends on auth phase, which depends on database phase)
- test_scope: 5 (unit tests, integration tests, security tests, performance tests, coverage)
- risk_factors: 3 (security, database migration, breaking changes)

**Calculation**:
```
raw_score = (15 * 0.30) + (12 * 0.20) + (2 * 0.20) + (5 * 0.15) + (3 * 0.15)
          = 4.5 + 2.4 + 0.4 + 0.75 + 0.45
          = 8.5

normalized = 8.5 * 0.822 = 6.99

complexity_score = 7.0 (rounded)
complexity_level = "Medium-High"

# However, task_count = 15 exceeds task_count_threshold = 10
expansion_recommended = true
expansion_reason = "Task count (15) exceeds threshold (10)"
```

### Example 4: Very High Complexity Phase (Mandatory Expansion)

**Phase**: "Migrate authentication system to OAuth 2.0 with SSO support"

**Factor Measurements**:
- task_count: 25 (extensive implementation, migration, testing, rollback)
- file_references: 20 (touching many authentication-related files)
- dependency_depth: 3 (complex dependency chain)
- test_scope: 8 (comprehensive testing required)
- risk_factors: 5 (security, migration, breaking API changes, authentication, authorization)

**Calculation**:
```
raw_score = (25 * 0.30) + (20 * 0.20) + (3 * 0.20) + (8 * 0.15) + (5 * 0.15)
          = 7.5 + 4.0 + 0.6 + 1.2 + 0.75
          = 14.05

normalized = 14.05 * 0.822 = 11.55

complexity_score = 11.6 (rounded)
complexity_level = "High"
expansion_recommended = true
expansion_reason = "Complexity score 11.6 far exceeds threshold 8.0 (25 tasks, 20 files, security risks)"
```

### Example 5: Extreme Outlier (Capped at 15.0)

**Phase**: "Complete system rewrite with breaking changes"

**Factor Measurements**:
- task_count: 50
- file_references: 40
- dependency_depth: 5
- test_scope: 15
- risk_factors: 8

**Calculation**:
```
raw_score = (50 * 0.30) + (40 * 0.20) + (5 * 0.20) + (15 * 0.15) + (8 * 0.15)
          = 15.0 + 8.0 + 1.0 + 2.25 + 1.2
          = 27.45

normalized = 27.45 * 0.822 = 22.56
capped = min(15.0, 22.56) = 15.0

complexity_score = 15.0
complexity_level = "Very High"
expansion_recommended = true
expansion_reason = "Extreme complexity (50 tasks, 40 files) - mandatory subdivision required"
```

## Threshold Configuration

Complexity thresholds are configured in CLAUDE.md under the `adaptive_planning_config` section:

```markdown
<!-- SECTION: adaptive_planning_config -->
## Adaptive Planning Configuration

### Complexity Thresholds

- **Expansion Threshold**: 8.0 (phases above this score → Level 1 expansion)
- **Task Count Threshold**: 10 (phases with >N tasks → expand regardless of score)
- **File Reference Threshold**: 10 (phases with >N files → increased complexity weight)
- **Replan Limit**: 2 (max auto-replans during /implement)
<!-- END_SECTION: adaptive_planning_config -->
```

### Threshold Priority (Discovery Order)

1. **Subdirectory-specific CLAUDE.md**: Check for CLAUDE.md in the plan's directory
2. **Root CLAUDE.md**: Use project-level defaults
3. **Hardcoded Defaults**: Fallback if no CLAUDE.md found
   - expansion_threshold: 8.0
   - task_count_threshold: 10
   - file_reference_threshold: 10
   - replan_limit: 2

### Expansion Decision Logic

A phase should be expanded if **ANY** of the following conditions are true:

1. **Complexity Score Exceeds Threshold**:
   ```
   complexity_score > expansion_threshold
   ```

2. **Task Count Exceeds Threshold**:
   ```
   task_count > task_count_threshold
   ```

3. **Both Moderate Complexity AND High File Count**:
   ```
   (complexity_score > 6.0) AND (file_references > file_reference_threshold)
   ```

## Validation and Tuning

### Correlation Testing

To validate the formula's accuracy:

1. **Create Ground Truth Dataset**:
   - Manually assess 10-20 existing plan phases
   - Rate each phase 0-15 based on human expert judgment
   - Document assessments in `.claude/tests/fixtures/complexity/ground_truth.yaml`

2. **Calculate Correlation**:
   ```
   Pearson correlation coefficient between:
   - Algorithm scores (automated complexity_score)
   - Human ratings (ground truth)

   Target: r > 0.90 (strong correlation)
   ```

3. **Interpret Results**:
   - r > 0.95: Excellent correlation, formula validated
   - r = 0.90-0.95: Good correlation, minor tuning may help
   - r < 0.90: Poor correlation, weights need adjustment

### Weight Adjustment Procedure

If correlation < 0.90:

1. **Analyze Discrepancies**:
   - Identify phases where algorithm score differs significantly from human rating
   - Categorize discrepancies by factor (e.g., "algorithm underweights testing")

2. **Adjust Weights Iteratively**:
   - Increase weight for undervalued factors
   - Decrease weight for overvalued factors
   - Maintain total weight = 1.00
   - Re-run correlation test

3. **Re-validate**:
   - Test on holdout set (phases not used for tuning)
   - Ensure no overfitting to training data

### Continuous Improvement

- **Collect Usage Data**: Track expansion decisions and outcomes
- **User Feedback**: Allow manual complexity overrides and track when users disagree
- **Periodic Re-tuning**: Quarterly review of formula performance
- **Domain-Specific Adjustments**: Different projects may need different weights

## Edge Cases and Error Handling

### Zero Tasks
```
If task_count = 0:
  → complexity_score = 0.0
  → complexity_level = "Low"
  → expansion_recommended = false
  → Warning: "Phase has no tasks - may be placeholder or metadata-only"
```

### Malformed Dependency Metadata
```
If dependency parsing fails:
  → dependency_depth = 0 (assume no dependencies)
  → Log warning: "Could not parse dependency metadata"
  → Continue with other factors
```

### Missing Phase Content
```
If phase content is empty or unreadable:
  → Return error: "Cannot calculate complexity for empty phase"
  → Do not proceed with expansion decision
```

### Negative Values (Should Never Occur)
```
If any factor < 0:
  → Clamp to 0
  → Log error: "Negative factor value detected (algorithm bug)"
```

### Infinity or NaN
```
If normalized_score is infinity or NaN:
  → Return error: "Complexity calculation failed (invalid formula)"
  → Do not make expansion decision
```

## Implementation Notes

### Performance Considerations

- **Target**: <5 seconds for plans up to 50 phases
- **Optimization**: Use grep/awk for factor extraction (faster than parsing in high-level languages)
- **Caching**: Not required (calculations are fast and not repeated frequently)

### Precision

- **Calculation Precision**: Use floating-point arithmetic (double precision sufficient)
- **Output Precision**: Round final score to 1 decimal place for human readability
- **Threshold Comparison**: Use > (not >=) to avoid boundary ambiguity

### Extensibility

Future formula enhancements may include:

1. **Code Churn Factor**: Lines of code changed (requires git integration)
2. **Review Complexity**: Estimated review time based on change scope
3. **Domain-Specific Factors**: Database-heavy vs API-heavy vs UI-heavy phases
4. **Historical Difficulty**: Learn from past phases that required revision

## References

- [Adaptive Planning Configuration (CLAUDE.md)](../../CLAUDE.md#adaptive_planning_config)
- [Plan Expansion Pattern](../concepts/patterns/plan-expansion.md)
- [complexity-estimator Agent](../../agents/complexity-estimator.md)
- [Complexity Utilities Library](../../lib/complexity-utils.sh)

## Version History

- **v1.0** (2025-10-21): Initial formula specification with 5 factors and 0.0-15.0 normalization
