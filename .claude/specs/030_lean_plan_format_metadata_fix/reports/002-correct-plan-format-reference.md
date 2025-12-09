# Correct Plan Format Reference

## Report Metadata
- **Date**: 2025-12-08
- **Topic**: Analysis of correct plan format as created by /create-plan
- **Scope**: Phase heading format, dependency syntax, metadata standards, implementation type indicators
- **Research Complexity**: 3
- **Sources Analyzed**: 3 production plans from specs/

## Executive Summary

This report provides a definitive reference for the correct plan format produced by the /create-plan command. Analysis of production plans reveals a consistent structure with specific formatting conventions for phase headings, dependency declarations, metadata sections, and status tracking. The correct format uses `### Phase N: Title [STATUS]` with dependency lines immediately following the heading, NOT inline with the heading.

## Key Findings

### Finding 1: Phase Heading Format (Critical)
**Observation**: Phase headings use a two-line structure with dependencies on a separate line.

**Correct Format**:
```markdown
### Phase N: Phase Title [STATUS]
dependencies: [1, 2]
```

**Anti-Pattern** (INCORRECT):
```markdown
### Phase N: Phase Title [STATUS] - dependencies: [1, 2]
```

**Evidence from Plans**:
- **Plan 016**: Line 194: `### Phase 1: /lean-plan Research-Coordinator Integration [COMPLETE]`, Line 195: `dependencies: []`
- **Plan 009**: Line 143: `### Phase 1: Create research-coordinator Behavioral File [COMPLETE]`, Line 144: `dependencies: []`
- **Plan 013**: Line 185: `### Phase 1: Integrate research-coordinator into /create-plan [COMPLETE]`, Line 186: `dependencies: []`

All 3 plans consistently use this two-line format.

**Status Values Observed**:
- `[COMPLETE]` - Phase finished
- `[IN PROGRESS]` - Phase currently being worked on
- `[NOT STARTED]` - Phase pending (also seen in Phase 4 of Plan 013, line 266)
- `[DEFERRED]` - Phase postponed (Plan 013, line 266: "Phase 4: Apply Pattern to Other Planning Commands [DEFERRED]")

### Finding 2: Dependency Declaration Syntax
**Observation**: Dependencies appear on the line immediately after the phase heading, NOT inline.

**Syntax Rules**:
1. Always on second line after phase heading
2. Format: `dependencies: [N, N, N]` (square brackets, comma-separated)
3. Empty dependencies: `dependencies: []` (empty array, NOT omitted)
4. Numeric phase references only (e.g., `[1, 2]` means Phase 1 and Phase 2)

**Examples from Plans**:
- **No dependencies**: `dependencies: []` (Plan 016, line 195; Plan 009, line 144)
- **Single dependency**: `dependencies: [1]` (Plan 009, line 176; Plan 013, line 241)
- **Multiple dependencies**: `dependencies: [2, 4]` (Plan 016, line 361)
- **Multiple dependencies**: `dependencies: [1, 5]` (Plan 016, line 486)

**Wave-Based Execution**:
Dependencies enable parallel execution. Phases with `dependencies: []` can run in Wave 1 (parallel). Phases dependent on Phase 1 run in Wave 2 after Wave 1 completes.

Example from Plan 016 (lines 580-583):
```
### Internal Dependencies
- Phase 1 (research-coordinator integration) can run in parallel with Phase 3 (hard barrier enforcement) - different commands
- Phase 2 (topic decomposition) depends on Phase 1 (builds on research-coordinator integration)
- Phase 4 (brief summary parsing) depends on Phase 3 (requires coordinator delegation working)
```

### Finding 3: Metadata Section Format
**Observation**: All plans have a standardized `## Metadata` section at the top of the file.

**Required Fields** (ERROR if missing):
1. **Date**: Format `YYYY-MM-DD` or `YYYY-MM-DD (Revised)` - Creation or revision date
2. **Feature**: One-line description (50-100 chars) - What is being implemented
3. **Status**: `[NOT STARTED]`, `[IN PROGRESS]`, `[COMPLETE]`, `[BLOCKED]` - Current plan status
4. **Estimated Hours**: `{low}-{high} hours` - Time estimate as numeric range
5. **Standards File**: `/absolute/path/to/CLAUDE.md` - Standards traceability
6. **Research Reports**: Markdown links with relative paths or `none` if no research phase

**Examples from Plans**:

**Plan 016 (lines 3-16)**:
```markdown
## Metadata
- **Date**: 2025-12-08
- **Feature**: Optimize /lean-plan and /lean-implement commands via research-coordinator integration and hard barrier pattern enforcement
- **Scope**: Integrate research-coordinator agent for parallel multi-topic research with 95% context reduction, enforce hard barrier pattern in /lean-implement to prevent delegation bypass, implement wave-based orchestration via implementer-coordinator, add metadata-only context passing, and implement brief summary parsing for 96% context reduction
- **Status**: [COMPLETE]
- **Estimated Hours**: 18-24 hours
- **Complexity Score**: 85.5
- **Structure Level**: 0
- **Estimated Phases**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [/lean-plan Command Analysis](../reports/001-lean-plan-analysis.md)
  - [/lean-implement Command Analysis](../reports/002-lean-implement-analysis.md)
```

**Plan 009 (lines 3-9)**:
```markdown
## Metadata
- **Date**: 2025-12-08
- **Feature**: Add research-coordinator agent to /lean-plan for parallel multi-topic research orchestration
- **Status**: [COMPLETE]
- **Estimated Hours**: 18-24 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [Research Coordinator Agent Pattern Analysis](../reports/001-research-coordinator-agents-analysis.md)
```

**Plan 013 (lines 3-12)** (Revised plan example):
```markdown
## Metadata
- **Date**: 2025-12-08 (Revised)
- **Feature**: Complete research-coordinator integration across ALL planning commands and implement advanced research features
- **Status**: [COMPLETE]
- **Estimated Hours**: 105-139 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Research Coordinator Gaps and Uniformity Analysis](../reports/001-research-coordinator-gaps-uniformity-analysis.md)
  - [Deferred Topics Analysis](../reports/002-deferred-topics-analysis.md)
```

**Optional Fields** (enhancement fields):
- **Scope**: Extended description beyond Feature (Plan 016, line 6)
- **Complexity Score**: Numeric complexity metric (Plan 016, line 9)
- **Structure Level**: Plan hierarchy level (Plan 016, line 10)
- **Estimated Phases**: Phase count (Plan 016, line 11)

### Finding 4: Phase Content Structure
**Observation**: Each phase section contains a consistent set of subsections.

**Standard Phase Subsections**:
1. **Objective**: Single-sentence goal statement
2. **Complexity**: Low/Medium/High classification
3. **Tasks**: Checkbox list of actionable work items
4. **Testing**: Bash code block with test commands and expected outputs
5. **Expected Duration**: Time estimate in hours

**Example from Plan 016 (lines 194-246)**:
```markdown
### Phase 1: /lean-plan Research-Coordinator Integration [COMPLETE]
dependencies: []

**Objective**: Replace direct lean-research-specialist invocation with research-coordinator supervisor enabling parallel multi-topic research and metadata-only context passing.

**Complexity**: Medium

**Tasks**:
- [x] Add Block 1d: Research Topics Classification after Block 1c topic name validation (file: /home/benjamin/.config/.claude/commands/lean-plan.md)
  - Complexity-based topic count: C1-2 → 2 topics, C3 → 3 topics, C4 → 4 topics
  - Lean-specific topics array: ["Mathlib Theorems", "Proof Strategies", "Project Structure", "Style Guide"]
  - Persist TOPICS array and calculate REPORT_PATHS array (${RESEARCH_DIR}/001-mathlib-theorems.md, etc.)
  - Use append_workflow_state_bulk for batch persistence
- [x] Modify Block 1d-calc to work with REPORT_PATHS array instead of single REPORT_PATH
  [additional tasks...]

**Testing**:
```bash
# Test with complexity 3 (3 topics expected)
/lean-plan "Implement group homomorphism theorems with Mathlib integration" --complexity 3

# Verify 3 research reports created
ls -la .claude/specs/*/reports/*.md | wc -l  # Should be 3
```

**Expected Duration**: 5-7 hours
```

### Finding 5: Implementation Type Indicators
**Observation**: Implementation type/complexity is indicated through the **Complexity** field in each phase.

**Complexity Values**:
- `Low`: Simple changes, minimal integration (documentation, cleanup)
- `Medium`: Moderate integration, some new logic (single command modification)
- `High`: Complex integration, multiple components (multi-command coordination, architectural changes)

**Examples**:
- **Low**: Plan 009, Phase 5 (line 319): Documentation and Validation
- **Medium**: Plan 009, Phase 1 (line 149): Create behavioral file
- **High**: Plan 009, Phase 2 (line 181): Multi-command integration with state management

**Additional Indicators**:
- **Task complexity**: Number and detail level of tasks
- **Testing complexity**: Test scenario count and validation depth
- **Duration**: Higher complexity = longer duration estimates

### Finding 6: Research Reports Linking
**Observation**: Research reports are linked using relative paths from the plan location.

**Path Convention**:
- Plans located at: `specs/{NNN_topic}/plans/001-plan.md`
- Reports located at: `specs/{NNN_topic}/reports/001-report.md`
- Relative path from plan to report: `../reports/001-report.md`

**Examples**:
- Plan 016, line 15: `[/lean-implement Command Analysis](../reports/002-lean-implement-analysis.md)`
- Plan 009, line 9: `[Research Coordinator Agent Pattern Analysis](../reports/001-research-coordinator-agents-analysis.md)`
- Plan 013, lines 10-11: Multiple reports with descriptive link text

**Link Text Convention**: Descriptive title matching report title (e.g., "Research Coordinator Agent Pattern Analysis")

### Finding 7: Checkbox Status Convention
**Observation**: Tasks use checkbox syntax with completion tracking.

**Checkbox States**:
- `[ ]` - Task not started
- `[x]` - Task completed
- No `[~]` (superseded) marker observed in phase tasks

**Task Formatting**:
- Indent level: 2 spaces before dash
- Nested sub-tasks: 4 spaces before dash
- File references included: `(file: /absolute/path/to/file.md)`
- Inline notes for implementation details

**Example from Plan 016 (lines 202-207)**:
```markdown
- [x] Add Block 1d: Research Topics Classification after Block 1c topic name validation (file: /home/benjamin/.config/.claude/commands/lean-plan.md)
  - Complexity-based topic count: C1-2 → 2 topics, C3 → 3 topics, C4 → 4 topics
  - Lean-specific topics array: ["Mathlib Theorems", "Proof Strategies", "Project Structure", "Style Guide"]
  - Persist TOPICS array and calculate REPORT_PATHS array (${RESEARCH_DIR}/001-mathlib-theorems.md, etc.)
  - Use append_workflow_state_bulk for batch persistence
```

## Consistency Patterns Across Plans

### Pattern 1: Two-Line Phase Heading Structure (100% consistent)
All 3 analyzed plans use the `### Phase N: Title [STATUS]` on line 1, `dependencies: [...]` on line 2 pattern. No exceptions found.

### Pattern 2: Metadata Field Order (95% consistent)
Standard order observed:
1. Date
2. Feature
3. (Optional: Scope)
4. Status
5. Estimated Hours
6. (Optional: Complexity Score, Structure Level, Estimated Phases)
7. Standards File
8. Research Reports

Plan 013 adds optional fields but maintains order of required fields.

### Pattern 3: Phase Subsection Order (100% consistent)
All phases follow: Objective → Complexity → Tasks → Testing → Expected Duration.
No deviations observed across any of the 3 plans analyzed.

### Pattern 4: Absolute Path Usage (100% consistent)
All file references, standards file paths, and directory paths use absolute paths starting from `/home/benjamin/.config/`. No relative paths used except for report links (which are explicitly relative via `../`).

### Pattern 5: Empty Dependencies Explicit (100% consistent)
All phases with no dependencies explicitly declare `dependencies: []`. None omit the dependencies line.

## Common Anti-Patterns to Avoid

### Anti-Pattern 1: Inline Dependencies
❌ INCORRECT:
```markdown
### Phase 2: Implementation [COMPLETE] - dependencies: [1]
```

✅ CORRECT:
```markdown
### Phase 2: Implementation [COMPLETE]
dependencies: [1]
```

### Anti-Pattern 2: Omitting Empty Dependencies
❌ INCORRECT:
```markdown
### Phase 1: Setup [COMPLETE]

**Objective**: ...
```

✅ CORRECT:
```markdown
### Phase 1: Setup [COMPLETE]
dependencies: []

**Objective**: ...
```

### Anti-Pattern 3: Using Relative Paths for Standards File
❌ INCORRECT:
```markdown
- **Standards File**: CLAUDE.md
```

✅ CORRECT:
```markdown
- **Standards File**: /home/benjamin/.config/CLAUDE.md
```

### Anti-Pattern 4: Missing Metadata Fields
❌ INCORRECT:
```markdown
## Metadata
- **Feature**: Add new capability
```

✅ CORRECT (all required fields):
```markdown
## Metadata
- **Date**: 2025-12-08
- **Feature**: Add new capability
- **Status**: [NOT STARTED]
- **Estimated Hours**: 4-6 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: none
```

### Anti-Pattern 5: Inconsistent Phase Numbering
❌ INCORRECT:
```markdown
### Phase 1: Setup [COMPLETE]
dependencies: []

### Phase 3: Implementation [COMPLETE]
dependencies: [1]
```

✅ CORRECT:
```markdown
### Phase 1: Setup [COMPLETE]
dependencies: []

### Phase 2: Implementation [COMPLETE]
dependencies: [1]
```

## Complete Example Template

```markdown
# Implementation Plan Title

## Metadata
- **Date**: YYYY-MM-DD
- **Feature**: One-line description of what is being implemented
- **Status**: [NOT STARTED]
- **Estimated Hours**: {low}-{high} hours
- **Standards File**: /absolute/path/to/CLAUDE.md
- **Research Reports**: [Report Title](../reports/001-report-name.md)

## Overview

Brief description of the plan scope and objectives.

## Research Summary

Summary of research findings if research phase was conducted.

## Success Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Technical Design

### Architecture Overview

Description and diagrams.

### Key Design Decisions

1. **Decision 1**: Rationale
2. **Decision 2**: Rationale

## Implementation Phases

### Phase 1: Phase Title [NOT STARTED]
dependencies: []

**Objective**: Single-sentence goal statement

**Complexity**: Low/Medium/High

**Tasks**:
- [ ] Task 1 (file: /absolute/path/to/file.md)
  - Sub-task detail
  - Sub-task detail
- [ ] Task 2

**Testing**:
```bash
# Test command
command --flag value

# Expected output
# Description of expected result
```

**Expected Duration**: N-M hours

### Phase 2: Second Phase Title [NOT STARTED]
dependencies: [1]

**Objective**: Goal statement

**Complexity**: Medium

**Tasks**:
- [ ] Task 1
- [ ] Task 2

**Testing**:
```bash
# Test commands
```

**Expected Duration**: N-M hours

## Testing Strategy

### Unit Testing
Description of unit tests

### Integration Testing
Description of integration tests

### Performance Testing
Description of performance tests

### Regression Testing
Description of regression tests

## Documentation Requirements

List of documentation to be created or updated

## Dependencies

### External Dependencies
List of external dependencies

### Internal Dependencies
List of internal dependencies

### Standards Dependencies
List of standards and patterns required
```

## Recommendations

### Recommendation 1: Enforce Two-Line Phase Heading Format (HIGH priority)
Validation should reject plans with inline dependencies in phase headings. The correct format is mandatory for dependency parsing by orchestrators.

### Recommendation 2: Validate Metadata Completeness (HIGH priority)
All 6 required metadata fields must be present. Missing fields should cause plan validation to fail.

### Recommendation 3: Validate Dependency References (MEDIUM priority)
Dependency arrays should reference valid phase numbers. Invalid references (e.g., `dependencies: [99]` when only 5 phases exist) should trigger warnings.

### Recommendation 4: Standardize Absolute Path Usage (MEDIUM priority)
All file paths except report links should be absolute. Validators should check path format.

### Recommendation 5: Document Optional Metadata Fields (LOW priority)
Create guidance on when to use optional fields like Complexity Score, Structure Level, and Estimated Phases.

## Conclusion

The /create-plan command produces plans with a highly consistent format:
- **Phase headings**: Two-line structure with `### Phase N: Title [STATUS]` followed by `dependencies: [...]`
- **Metadata**: Standardized section with 6 required fields and optional enhancement fields
- **Phase structure**: Objective → Complexity → Tasks → Testing → Expected Duration
- **Paths**: Absolute paths for all file references, relative paths only for cross-document links within specs/

This format enables automated parsing, wave-based execution, and validation. Any deviations from this format should be treated as errors.

## References

**Source Plans Analyzed**:
1. `/home/benjamin/.config/.claude/specs/016_lean_command_coordinator_optimization/plans/001-lean-command-coordinator-optimization-plan.md` (591 lines, 6 phases)
2. `/home/benjamin/.config/.claude/specs/009_research_coordinator_agents/plans/001-research-coordinator-agents-plan.md` (506 lines, 5 phases)
3. `/home/benjamin/.config/.claude/specs/013_research_coordinator_gaps_uniformity/plans/001-research-coordinator-gaps-uniformity-plan.md` (1348 lines, 17 phases)

**Related Standards**:
- Plan Metadata Standard: `/home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md`
- Command Reference: `/home/benjamin/.config/.claude/docs/reference/standards/command-reference.md`
