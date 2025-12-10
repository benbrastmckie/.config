# Implementation Plan: Enhance /lean-plan for Wave-Based Parallel Execution

## Metadata

- **Date**: 2025-12-09 (Revised)
- **Feature**: Enhance /lean-plan to generate dependency-aware plans optimized for parallel wave execution
- **Scope**: Improve lean-plan-architect agent to analyze theorem dependencies and generate optimal phase dependency structures that enable /lean-implement to execute independent phases in parallel waves, achieving 40-60% time savings. Maintain efficiency through metadata completeness and standards compliance.
- **Status**: [IN PROGRESS]
- **Estimated Hours**: 10-14 hours (revised from 8-12 to reflect Phase 0 addition)
- **Complexity Score**: 58.0
- **Structure Level**: 0
- **Estimated Phases**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Current /lean-plan Command Architecture](../reports/001-lean-plan-command-analysis.md)
  - [Wave-Based Parallel Planning Dependencies](../reports/002-wave-parallel-planning-dependencies.md)
  - [Efficiency and Standards Compliance](../reports/003-efficiency-standards-infrastructure.md)
  - [Delegation and Standards Fix Analysis](../reports/4-lean_plan_delegation_standards_fix.md)

## Overview

The /lean-plan command currently generates Lean implementation plans with theorem-level granularity but does not optimize phase dependency structures for parallel wave execution. Research shows that proper dependency analysis can enable 40-60% time savings during /lean-implement execution by allowing independent phases to run in parallel.

This plan enhances lean-plan-architect to:
1. Analyze theorem dependencies during plan creation
2. Generate optimized phase dependency arrays that reflect actual theorem relationships
3. Add metadata completeness (Complexity Score, Structure Level) for standards compliance
4. Provide wave structure preview for user feedback

The existing wave execution infrastructure (dependency-analyzer.sh, lean-coordinator wave orchestration) requires no changes - we only need to improve the quality of dependency metadata in generated plans.

## Research Summary

**Key Findings from Research Reports**:

1. **Current Architecture** (Report 001):
   - /lean-plan uses dual-coordinator architecture (research-coordinator + lean-plan-architect)
   - Already optimized: 95% context reduction via metadata-only passing, bulk state persistence, hard barrier pattern
   - Plans include required fields (implementer, lean_file, dependencies) but dependencies often sequential
   - Infrastructure exists for wave execution but is underutilized due to sequential dependency patterns

2. **Wave Optimization Opportunity** (Report 002):
   - Gap identified: lean-plan-architect performs theorem dependency analysis but doesn't translate results into phase dependencies
   - Current output: Sequential dependencies (Phase N depends on Phase N-1) → single-threaded execution
   - Optimal output: Parallel-friendly dependencies (independent phases have dependencies: []) → wave-based execution
   - Target: 40-60% time savings through proper wave structure

3. **Standards Compliance** (Report 003):
   - Strong compliance with plan metadata standard, output formatting, error handling
   - Metadata completeness gap: Complexity Score and Structure Level sometimes omitted
   - Recommendation: Automate calculation and insertion for full standards alignment

**Implementation Strategy**:
- Enhance lean-plan-architect STEP 1 to build theorem-to-phase dependency mapping
- Generate phase dependency arrays based on theorem relationships
- Add metadata validation and completion
- Provide wave structure preview for user visibility

## Success Criteria

- [ ] lean-plan-architect analyzes theorem dependencies and maps them to phase dependencies
- [ ] Generated plans have accurate dependency arrays enabling wave-based parallel execution
- [ ] Plans include Complexity Score calculation using standardized formula
- [ ] Plans include Structure Level: 0 (enforced for all Lean plans)
- [ ] Wave structure preview displayed during plan creation showing parallelization opportunities
- [ ] All metadata fields comply with Plan Metadata Standard validation
- [ ] Existing /lean-plan efficiency patterns preserved (95% context reduction, bulk state persistence)
- [ ] Integration tests confirm plans work with /lean-implement wave execution
- [ ] Documentation updated to reflect enhanced dependency generation

## Technical Design

### Architecture Components

**1. Theorem Dependency Analysis (lean-plan-architect STEP 1 Enhancement)**

Location: `.claude/agents/lean-plan-architect.md` STEP 1 (Lean Planning Process)

Current state: Agent performs theorem dependency analysis (lines 98-108) but doesn't translate to phase dependencies

Enhancement:
```markdown
**Theorem Dependency Analysis** (CRITICAL):

For each theorem to prove:
1. Identify Prerequisites: Which other theorems must be proven first?
2. Check Mathlib Availability: Can prerequisites use existing Mathlib theorems?
3. Build Dependency Graph: Create edges from theorem → dependencies
4. Validate Acyclicity: Ensure no circular dependencies
5. **NEW**: Map Theorem Dependencies to Phase Dependencies
   - If Phase N contains theorem_X, Phase M contains theorem_Y
   - And theorem_X depends on theorem_Y
   - Then Phase N dependencies: [..., M, ...]
6. **NEW**: Optimize for Parallelization
   - Group independent theorems into separate phases (dependencies: [])
   - Minimize sequential chains (max wave concurrency)
   - Balance phase complexity (avoid wave bottlenecks)
```

**2. Phase Dependency Array Generation**

Location: `.claude/agents/lean-plan-architect.md` STEP 2 (Plan File Creation)

Current format:
```markdown
### Phase N: Name [NOT STARTED]
implementer: lean
lean_file: /path/file.lean
dependencies: [N-1]  # Sequential by default
```

Enhanced format:
```markdown
### Phase N: Name [NOT STARTED]
implementer: lean
lean_file: /path/file.lean
dependencies: []  # Independent phases get empty array
# OR
dependencies: [1, 3]  # Dependent phases reference actual prerequisites
```

Algorithm:
1. Build theorem-to-phase map during STEP 1 analysis
2. For each phase, extract theorem dependencies from theorem graph
3. Convert theorem dependencies to phase number references
4. Validate: No forward references, no cycles, no self-dependencies
5. Output dependency array in phase metadata

**3. Metadata Completion**

Location: `.claude/agents/lean-plan-architect.md` STEP 2 (Metadata Section)

Add automated calculation:

**Complexity Score** (standardized formula from lean-plan-architect.md lines 220-230):
```
Base (formalization type):
- New formalization: 15
- Extend existing: 10
- Refactor proofs: 7

+ (Theorems × 3)
+ (Files × 2)
+ (Complex Proofs × 5)
```

**Structure Level**: Always 0 for Lean plans (single-file format, no Level 1 expansion support)

**4. Wave Structure Preview**

Location: `.claude/agents/lean-plan-architect.md` STEP 2 (after plan creation)

Add wave calculation preview using dependency-analyzer.sh logic:
1. Parse phase dependency arrays from generated plan
2. Apply Kahn's algorithm (topological sort) to calculate waves
3. Display wave structure in plan creation output:
```
Wave Structure Preview:
Wave 1: Phases 1, 2, 3 (parallel - 3 phases)
Wave 2: Phases 4, 5 (parallel - 2 phases)
Wave 3: Phase 6 (sequential - 1 phase)

Parallelization Metrics:
- Sequential Time: 18 hours
- Parallel Time: 9 hours
- Time Savings: 50%
```

4. Include wave structure as markdown comment in plan for reference

### Integration Points

**No Changes Required**:
- `/lean-plan` command orchestration (already provides correct inputs)
- `research-coordinator` integration (metadata-only passing preserved)
- `dependency-analyzer.sh` library (already parses dependencies: [] format)
- `lean-coordinator` wave execution (already builds waves from dependency arrays)
- `/lean-implement` dual coordinator routing (already uses plan-based mode)

**Changes Required**:
- `lean-plan-architect.md` STEP 1: Enhanced theorem dependency mapping
- `lean-plan-architect.md` STEP 2: Dependency array generation, metadata completion, wave preview

### Standards Alignment

**Plan Metadata Standard Compliance**:
- All required fields enforced (Date, Feature, Status, Estimated Hours, Standards File, Research Reports)
- Lean-specific fields enforced (Lean File, Lean Project)
- Optional fields completed (Complexity Score, Structure Level)
- Validation via validate-plan-metadata.sh in plan-architect STEP 3

**Output Formatting Standards**:
- Wave preview uses console summary format (emoji markers, 4-section structure)
- Comments describe WHAT (not WHY) in theorem dependency logic
- Suppression patterns preserved in any bash execution

**Error Logging Standards**:
- Dependency validation errors logged via log_command_error
- Circular dependency detection triggers validation_error type
- Agent error parsing preserved for lean-plan-architect failures

## Implementation Phases

### Phase Routing Summary
| Phase | Type | Implementer Agent |
|-------|------|-------------------|
| 0 | software | implementer-coordinator |
| 1 | software | implementer-coordinator |
| 2 | software | implementer-coordinator |
| 3 | software | implementer-coordinator |
| 4 | software | implementer-coordinator |
| 5 | software | implementer-coordinator |

### Phase 0: Enforce lean-plan-architect Delegation Pattern [COMPLETE]
implementer: software
dependencies: []

**Objective**: Fix the /lean-plan command to enforce mandatory lean-plan-architect agent delegation and prevent primary agent from creating plans directly

**Complexity**: Medium

**Background**: Research in Report 4 identified that the primary orchestrator sometimes bypasses the lean-plan-architect Task invocation and creates plans directly using Write tool. This bypasses theorem dependency analysis, phase metadata generation, and standards validation.

**Tasks**:
- [x] Add explicit verification in Block 2c that plan was created by lean-plan-architect (not primary agent)
  - [x] Parse agent return for `PLAN_CREATED:` signal
  - [x] Verify signal path matches pre-calculated PLAN_PATH
  - [x] Add error if signal missing or path mismatch
- [x] Enhance Block 2b-exec Task invocation instructions
  - [x] Add explicit `DO NOT use Write tool directly` warning
  - [x] Emphasize mandatory Task invocation with hard barrier verification
  - [x] Add examples of correct vs incorrect patterns
- [x] Add delegation bypass detection in validation
  - [x] Check for Write tool usage in primary agent context
  - [x] Log warning if direct Write detected before Task invocation
- [x] Document delegation pattern in lean-plan-command-guide.md
  - [x] Explain why delegation is mandatory
  - [x] Show architecture diagram with Task tool flow
  - [x] Reference hierarchical-agents-examples.md patterns

**Testing**:
```bash
# Test that /lean-plan creates plan via agent delegation
/lean-plan "test delegation enforcement" --complexity 2 --project ~/test-lean-project

# Verify PLAN_CREATED signal in output
grep "PLAN_CREATED:" ~/.claude/output/lean-plan-output.md

# Verify plan has proper phase metadata (proves agent created it)
PLAN_FILE=$(ls -t .claude/specs/*/plans/*.md | head -1)
grep -c "^implementer:" "$PLAN_FILE"  # Should be ≥1

# Verify Phase Routing Summary exists
grep "### Phase Routing Summary" "$PLAN_FILE"
```

**Expected Duration**: 2 hours

---

### Phase 1: Enhance Theorem Dependency Mapping in lean-plan-architect [IN PROGRESS]
implementer: software
dependencies: [0]

**Objective**: Modify lean-plan-architect STEP 1 to build explicit theorem-to-phase dependency mapping from theorem dependency analysis

**Complexity**: Medium

**Tasks**:
- [ ] Read current lean-plan-architect.md STEP 1 Lean Planning Process section (lines 90-155)
- [ ] Add theorem dependency graph data structure to STEP 1 analysis
  - [ ] Define theorem_dependencies map: { theorem_name: [prerequisite_theorem1, prerequisite_theorem2] }
  - [ ] Define theorem_to_phase map: { theorem_name: phase_number }
- [ ] Enhance theorem dependency analysis to populate dependency graph
  - [ ] For each theorem in plan, extract prerequisites from research reports and proof strategies
  - [ ] Check if prerequisites exist in Mathlib (external) vs in plan (internal)
  - [ ] Record internal dependencies in theorem_dependencies map
  - [ ] Validate acyclicity using topological sort algorithm
- [ ] Create phase dependency conversion function
  - [ ] Input: theorem_dependencies map, theorem_to_phase map
  - [ ] Output: phase_dependencies map: { phase_N: [prerequisite_phase1, prerequisite_phase2] }
  - [ ] Algorithm: For each phase, lookup theorems in phase, lookup theorem dependencies, convert to phase numbers
- [ ] Add validation rules
  - [ ] No forward references (phase N cannot depend on phase M where M > N)
  - [ ] No self-dependencies (phase N cannot depend on phase N)
  - [ ] No circular dependencies (detect cycles in phase dependency graph)
- [ ] Document data structures and algorithm in lean-plan-architect.md with examples

**Testing**:
```bash
# Create test plan with known theorem dependencies
/lean-plan "formalize ring properties: prove commutativity (independent), associativity (independent), distributivity (depends on both)" --complexity 2 --project ~/test-lean-project

# Verify generated plan has correct dependencies
grep -A 2 "Phase 1:" plan.md | grep "dependencies: \[\]"  # Commutativity independent
grep -A 2 "Phase 2:" plan.md | grep "dependencies: \[\]"  # Associativity independent
grep -A 2 "Phase 3:" plan.md | grep "dependencies: \[1, 2\]"  # Distributivity depends on both

# Verify no circular dependencies in complex scenarios
/lean-plan "formalize 5 interconnected theorems with complex prerequisites" --complexity 3 --project ~/test-lean-project
bash .claude/lib/util/dependency-analyzer.sh --validate-only plan.md
```

**Expected Duration**: 3-4 hours

---

### Phase 2: Implement Phase Dependency Array Generation [NOT STARTED]
implementer: software
dependencies: [1]

**Objective**: Modify lean-plan-architect STEP 2 to generate accurate phase dependency arrays based on theorem dependency mapping from Phase 1

**Complexity**: Medium

**Tasks**:
- [ ] Read current lean-plan-architect.md STEP 2 Plan File Creation section (lines 195-360)
- [ ] Identify where phase metadata is written (dependencies: [] field generation)
- [ ] Replace sequential dependency pattern with computed dependencies
  - [ ] Current pattern: dependencies: [N-1] for all phases except Phase 1
  - [ ] New pattern: dependencies: phase_dependencies[N] from Phase 1 analysis
- [ ] Implement dependency array formatting
  - [ ] Empty array for independent phases: dependencies: []
  - [ ] Single dependency: dependencies: [M]
  - [ ] Multiple dependencies: dependencies: [M1, M2, M3] (sorted order)
- [ ] Add phase granularity optimization
  - [ ] Default: One theorem per phase (maximize parallelization)
  - [ ] Group only when theorems tightly coupled (theorem + helper lemma)
  - [ ] Document grouping criteria in agent instructions
- [ ] Add dependency validation checkpoint
  - [ ] After generating all phase dependencies, validate graph
  - [ ] Check no forward references, no cycles, no orphaned phases
  - [ ] Log validation errors via log_command_error if issues detected
- [ ] Update phase heading generation to maintain [NOT STARTED] markers

**Testing**:
```bash
# Test independent phases (fan-out pattern)
/lean-plan "prove 4 independent basic theorems" --complexity 2
# Expect: All phases have dependencies: []

# Test sequential phases (linear pipeline)
/lean-plan "prove theorem chain A→B→C→D" --complexity 2
# Expect: Phase 1: [], Phase 2: [1], Phase 3: [2], Phase 4: [3]

# Test mixed pattern (diamond)
/lean-plan "prove foundation theorem, then 2 independent theorems using it, then final theorem using both" --complexity 3
# Expect: Phase 1: [], Phase 2: [1], Phase 3: [1], Phase 4: [2,3]

# Verify /implement can parse generated dependencies
/lean-implement plan.md --dry-run
# Should show wave structure correctly
```

**Expected Duration**: 3-4 hours

---

### Phase 3: Add Metadata Completion and Validation [COMPLETE]
implementer: software
dependencies: [0]

**Objective**: Ensure all generated plans include complete metadata (Complexity Score, Structure Level) and pass Plan Metadata Standard validation

**Complexity**: Low

**Tasks**:
- [x] Add Complexity Score calculation function to lean-plan-architect STEP 2
  - [x] Implement formula: Base + (Theorems × 3) + (Files × 2) + (Complex Proofs × 5)
  - [x] Extract values from STEP 1 analysis (theorem count, file count, complexity categories)
  - [x] Format as numeric value: **Complexity Score**: 51.0
- [x] Add Structure Level enforcement
  - [x] Always set to 0 for Lean plans (no Level 1 expansion support)
  - [x] Add comment explaining Lean plans use single-file structure
  - [x] Format: **Structure Level**: 0
- [x] Add Estimated Phases field
  - [x] Count phases generated in STEP 2
  - [x] Format: **Estimated Phases**: 6
- [x] Integrate validate-plan-metadata.sh in lean-plan-architect STEP 3
  - [x] Run validation after plan file creation
  - [x] Parse validation output for ERROR-level issues
  - [x] Exit with error if required fields missing or malformed
  - [x] Log validation failures via log_command_error
- [x] Update lean-plan-architect.md documentation
  - [x] Document required metadata fields in instructions
  - [x] Add self-validation checklist for metadata completeness
  - [x] Include examples of properly formatted metadata section

**Testing**:
```bash
# Generate plan and validate metadata
/lean-plan "test metadata completeness" --complexity 2 --project ~/test-lean-project
PLAN_FILE=$(ls -t .claude/specs/*/plans/*.md | head -1)

# Run metadata validation
bash .claude/scripts/lint/validate-plan-metadata.sh "$PLAN_FILE"
# Expect: Exit 0, all required fields present

# Verify Complexity Score present and numeric
grep "Complexity Score:" "$PLAN_FILE" | grep -E "[0-9]+\.[0-9]"

# Verify Structure Level: 0
grep "Structure Level: 0" "$PLAN_FILE"

# Verify Estimated Phases matches actual phase count
ESTIMATED=$(grep "Estimated Phases:" "$PLAN_FILE" | grep -oE "[0-9]+")
ACTUAL=$(grep -c "^### Phase [0-9]" "$PLAN_FILE")
[ "$ESTIMATED" -eq "$ACTUAL" ] && echo "✓ Phase count matches"
```

**Expected Duration**: 2 hours

---

### Phase 4: Implement Wave Structure Preview [NOT STARTED]
implementer: software
dependencies: [2]

**Objective**: Add wave calculation and visualization to lean-plan-architect output, showing users the parallelization benefits of generated dependency structure

**Complexity**: Medium

**Tasks**:
- [ ] Add wave calculation logic to lean-plan-architect STEP 2 (after plan creation)
  - [ ] Extract phase dependencies from generated plan content
  - [ ] Implement simplified Kahn's algorithm for wave assignment
    - [ ] Build in-degree map from dependencies
    - [ ] Assign phases with in-degree 0 to Wave 1
    - [ ] Remove Wave 1 phases, decrement in-degrees, repeat
  - [ ] Calculate parallelization metrics
    - [ ] Sum phase durations for sequential time
    - [ ] Sum max duration per wave for parallel time
    - [ ] Calculate time savings percentage
- [ ] Format wave structure preview
  - [ ] Use console summary format with emoji markers
  - [ ] Display waves with phase numbers and parallelism
  - [ ] Show metrics (sequential time, parallel time, savings)
  - [ ] Example format from design section above
- [ ] Add wave structure as markdown comment in plan file
  - [ ] Insert after Implementation Phases section
  - [ ] Format as HTML comment for reference without cluttering display
  - [ ] Include wave assignments and metrics
- [ ] Handle edge cases
  - [ ] Single phase plan: No wave preview (trivial case)
  - [ ] All sequential: Show warning about no parallelization
  - [ ] Circular dependencies: Already caught in Phase 2 validation
- [ ] Update lean-plan-architect return signal to include wave count
  - [ ] Add to metadata: Waves: N

**Testing**:
```bash
# Test wave preview display for parallel plan
/lean-plan "prove 6 theorems with mixed dependencies" --complexity 3 --project ~/test-lean-project
# Expect: Console output shows wave structure with multiple waves

# Test wave preview for sequential plan
/lean-plan "prove theorem chain with all sequential dependencies" --complexity 2 --project ~/test-lean-project
# Expect: Console output shows warning about sequential execution

# Verify wave preview matches dependency-analyzer.sh output
PLAN_FILE=$(ls -t .claude/specs/*/plans/*.md | head -1)
bash .claude/lib/util/dependency-analyzer.sh "$PLAN_FILE" --display-waves > /tmp/analyzer_waves.txt
# Compare with wave preview in plan file (should match)

# Test metrics calculation accuracy
# Manual calculation: 3 phases @ 2h each in Wave 1 = 2h parallel, 6h sequential
# Verify preview shows correct values
```

**Expected Duration**: 3-4 hours

---

### Phase 5: Integration Testing and Documentation [NOT STARTED]
implementer: software
dependencies: [0, 1, 2, 3, 4]

**Objective**: Validate enhanced /lean-plan works end-to-end with /lean-implement wave execution and update all relevant documentation

**Complexity**: Medium

**Tasks**:
- [ ] Create integration test suite for wave-optimized plans
  - [ ] Test 1: Independent phases (fan-out) → verify parallel execution
  - [ ] Test 2: Sequential phases (linear) → verify sequential execution
  - [ ] Test 3: Mixed dependencies (diamond) → verify wave grouping
  - [ ] Test 4: Complex multi-file plan → verify dependency propagation
- [ ] Test /lean-plan to /lean-implement workflow
  - [ ] Generate plan with /lean-plan (enhanced dependency generation)
  - [ ] Execute with /lean-implement --dry-run (verify wave structure recognized)
  - [ ] Execute actual implementation (verify parallel execution and time savings)
  - [ ] Verify brief summary return pattern (96% context reduction)
- [ ] Validate metadata completeness across test plans
  - [ ] Run validate-plan-metadata.sh on all generated test plans
  - [ ] Verify Complexity Score, Structure Level, Estimated Phases present
  - [ ] Verify dependency arrays properly formatted
- [ ] Update documentation
  - [ ] Update lean-plan-command-guide.md with dependency generation details
  - [ ] Add wave optimization section explaining theorem dependency analysis
  - [ ] Update lean-plan-architect.md agent documentation with enhanced STEP 1 and STEP 2
  - [ ] Add examples of dependency patterns (independent, sequential, mixed)
  - [ ] Update CLAUDE.md hierarchical_agent_architecture section if needed
- [ ] Update related documentation
  - [ ] Verify phase-dependencies.md still accurate (should be compatible)
  - [ ] Update lean-implement-command-guide.md if integration details changed
  - [ ] Add reference to this optimization in plan-metadata-standard.md
- [ ] Run validation suite
  - [ ] bash .claude/scripts/validate-all-standards.sh --plans
  - [ ] Verify no regressions in standards compliance

**Testing**:
```bash
# Full workflow integration test
cd ~/test-lean-project

# Generate wave-optimized plan
/lean-plan "formalize commutative ring properties with 8 theorems" --complexity 3

# Verify plan structure
PLAN_FILE=$(ls -t ~/.config/.claude/specs/*/plans/*.md | head -1)
bash .claude/scripts/lint/validate-plan-metadata.sh "$PLAN_FILE"
bash .claude/lib/util/dependency-analyzer.sh "$PLAN_FILE" --display-waves

# Execute plan (dry run)
/lean-implement "$PLAN_FILE" --dry-run
# Verify: Shows wave structure, routes phases to lean-coordinator

# Execute plan (actual)
/lean-implement "$PLAN_FILE"
# Verify: Parallel wave execution, time savings achieved, all phases complete

# Measure time savings
SEQUENTIAL_TIME=$(grep "Sequential Time:" output.log | grep -oE "[0-9]+")
PARALLEL_TIME=$(grep "Parallel Time:" output.log | grep -oE "[0-9]+")
SAVINGS=$(( (SEQUENTIAL_TIME - PARALLEL_TIME) * 100 / SEQUENTIAL_TIME ))
[ "$SAVINGS" -ge 40 ] && echo "✓ Time savings ≥40% target achieved"

# Documentation validation
markdown-link-check .claude/docs/guides/commands/lean-plan-command-guide.md
markdown-link-check .claude/agents/lean-plan-architect.md
```

**Expected Duration**: 2-3 hours

---

## Testing Strategy

### Unit Testing

**Theorem Dependency Mapping** (Phase 1):
- Test theorem dependency extraction from research reports
- Test theorem-to-phase mapping with various grouping strategies
- Test dependency graph validation (cycle detection, forward reference detection)
- Test edge cases (single theorem, no dependencies, complex interdependencies)

**Dependency Array Generation** (Phase 2):
- Test independent phases generate dependencies: []
- Test sequential phases generate dependencies: [N-1]
- Test mixed dependencies generate dependencies: [N1, N2, ...]
- Test dependency array formatting and validation

**Metadata Completion** (Phase 3):
- Test Complexity Score calculation with various theorem counts
- Test Structure Level always set to 0
- Test Estimated Phases matches actual phase count
- Test metadata validation integration

**Wave Preview** (Phase 4):
- Test Kahn's algorithm implementation for wave calculation
- Test parallelization metrics calculation
- Test wave preview formatting and display
- Test edge cases (single phase, all sequential, all parallel)

### Integration Testing

**End-to-End Workflow** (Phase 5):
- Test /lean-plan → /lean-implement with wave-optimized plans
- Test parallel execution achieves target time savings (40-60%)
- Test brief summary return pattern preserves context efficiency
- Test plans work with existing infrastructure (dependency-analyzer.sh, lean-coordinator)

**Standards Compliance**:
- Test all generated plans pass validate-plan-metadata.sh
- Test all plans pass validate-all-standards.sh --plans
- Test dependency arrays compatible with dependency-analyzer.sh parsing

### Test Automation

All tests must be non-interactive and programmatically validated:
- automation_type: automated (no manual verification)
- validation_method: programmatic (exit codes, grep, diff)
- skip_allowed: false (all tests required)
- artifact_outputs: ["test-results.txt", "validation-output.txt", "wave-metrics.json"]

## Documentation Requirements

### Files to Update

1. **lean-plan-architect.md** (agent behavioral guidelines):
   - Enhanced STEP 1 theorem dependency mapping instructions
   - Enhanced STEP 2 dependency array generation instructions
   - Metadata completion requirements
   - Wave preview generation instructions
   - Examples of dependency patterns

2. **lean-plan-command-guide.md** (command documentation):
   - Wave optimization capabilities section
   - Dependency generation explanation
   - Examples of generated plans with wave structure
   - Integration with /lean-implement wave execution

3. **plan-metadata-standard.md** (standards reference):
   - Reference to Lean-specific Complexity Score formula
   - Structure Level enforcement for Lean plans
   - Dependency array format requirements

4. **phase-dependencies.md** (reference documentation):
   - Examples of Lean theorem dependency patterns
   - Integration with lean-plan-architect generation

### Documentation Standards

- Follow Documentation Policy from CLAUDE.md
- Use clear, concise language with code examples
- Include Unicode box-drawing for dependency graph diagrams
- No emojis in file content (UTF-8 encoding issues)
- Update examples to reflect enhanced dependency generation
- Remove any historical commentary when updating existing docs

## Dependencies

### External Dependencies
- None (all infrastructure exists)

### Internal Dependencies
- `dependency-analyzer.sh`: Already provides wave calculation (no changes needed)
- `lean-coordinator.md`: Already supports wave execution (no changes needed)
- `validate-plan-metadata.sh`: Already validates plan metadata (no changes needed)
- Plan Metadata Standard: Already defines required fields (no changes needed)

### Prerequisites
- Understanding of theorem proving dependencies
- Familiarity with topological sorting (Kahn's algorithm)
- Knowledge of lean-plan-architect agent architecture
- Understanding of /lean-implement wave execution patterns

## Risk Assessment

### Low Risk
- Metadata completion (additive, non-breaking)
- Wave preview display (informational only)
- Documentation updates (no code impact)

### Medium Risk
- Dependency array generation (requires careful validation to avoid circular dependencies)
- Phase granularity optimization (too fine = too many phases, too coarse = less parallelization)

### Mitigation Strategies
- Extensive validation in Phase 2 (cycle detection, forward reference check)
- Conservative phase grouping (default to one theorem per phase)
- Comprehensive integration testing in Phase 5
- Dry-run testing before actual /lean-implement execution
- Validation via existing dependency-analyzer.sh infrastructure

## Timeline

**Total Estimated Time**: 15-19 hours (revised from 13-17 to include Phase 0)

**Phase Breakdown**:
- Phase 0: Enforce delegation pattern (2 hours)
- Phase 1: Theorem dependency mapping (3-4 hours)
- Phase 2: Dependency array generation (3-4 hours)
- Phase 3: Metadata completion (2 hours)
- Phase 4: Wave preview (3-4 hours)
- Phase 5: Integration and documentation (2-3 hours)

**Parallel Opportunities**: Phase 3 (metadata) can be developed in parallel with Phase 1-2 (dependency logic) since both depend only on Phase 0.

**Critical Path**: Phase 0 → Phase 1 → Phase 2 → Phase 4 → Phase 5 (delegation pattern must be enforced first, then dependency generation before wave preview and integration)

## Success Metrics

- [ ] lean-plan-architect delegation enforced (primary agent cannot bypass with direct Write)
- [ ] All generated plans have Phase Routing Summary table
- [ ] All phases have `implementer:` field with proper value (lean or software)
- [ ] All phases have `dependencies:` field with proper array syntax
- [ ] Generated plans enable 40-60% time savings in /lean-implement execution
- [ ] 100% of generated plans pass Plan Metadata Standard validation
- [ ] Wave preview accurately reflects actual wave execution in /lean-implement
- [ ] No regressions in existing /lean-plan efficiency patterns
- [ ] Documentation complete and link validation passes
- [ ] Integration tests demonstrate end-to-end workflow success
