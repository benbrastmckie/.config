# Standards Compliance Research Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Standards compliance for debug/fix implementation plans
- **Report Type**: codebase analysis
- **Context**: Improving implementation plan for coordinate workflow classifier debugging

## Executive Summary

The existing debug strategy plan (001_debug_strategy.md) demonstrates strong technical analysis but lacks compliance with several critical .claude/docs/ standards. Key gaps include: missing phase dependencies for wave-based execution, non-compliant phase structure (nested Implementation Phases instead of flat numbered phases), absence of metadata sections required by adaptive planning, missing testing protocols integration, and incomplete development workflow patterns. The plan provides detailed technical solutions but does not follow the structural and metadata requirements that enable automation, parallelization, and proper artifact management.

## Findings

### 1. Plan Structure Standards (Directory Protocols)

**Standard Location**: `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` (lines 796-880)

**Requirements for Implementation Plans**:
- Plans use progressive organization (Level 0 → Level 1 → Level 2)
- Level 0 starts as single file with flat phase structure
- Phases use format: `### Phase N: [Name]`
- Metadata includes: Dependencies, Risk, Estimated Time
- Phase dependencies enable wave-based parallel execution
- Plans created in topic-based structure: `specs/{NNN_topic}/plans/`

**Current Plan Compliance**:
- ✗ Uses nested "Implementation Phases" under "Phase 1/2/3" instead of flat phase numbering
- ✗ Missing phase dependency declarations (Dependencies: [])
- ✗ Missing Risk and Estimated Time metadata for each phase
- ✓ Correctly located in topic directory structure
- ✗ Does not follow Level 0 single-file format (uses subsections instead of phases)

**Gap Analysis**:
The plan treats P0/P1/P2 priority levels as "Implementation Phases" with nested sub-phases, instead of using flat numbered phases (Phase 1, Phase 2, Phase 3...). This prevents:
- Automatic wave calculation for parallel execution
- Complexity scoring by the adaptive planning system
- Phase expansion via `/expand-phase` command
- Checkbox propagation through plan hierarchy

### 2. Phase Dependencies for Wave-Based Execution

**Standard Location**: `/home/benjamin/.config/.claude/docs/reference/phase_dependencies.md`
**Referenced In**: `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` (lines 829-880)

**Requirements**:
- Each phase must declare dependencies: `**Dependencies**: []` or `[1, 2]`
- Empty array `[]` means independent (can run in parallel)
- Non-empty array lists phase numbers that must complete first
- Enables 40-60% time savings through wave-based parallel execution
- Uses Kahn's algorithm for topological sorting

**Current Plan Compliance**:
- ✗ Zero phase dependency declarations
- ✗ No wave-based execution planning
- ✗ Sequential timeline assumes no parallelization
- ✗ Missing opportunity for 40-60% time savings

**Example of Missing Pattern** (from directory-protocols.md:862-874):
```markdown
### Phase 1: Foundation Setup
**Dependencies**: []  # No dependencies - Wave 1

### Phase 2: Database Schema
**Dependencies**: [1]  # Depends on Phase 1 - Wave 2

### Phase 3: API Endpoints
**Dependencies**: [1]  # Depends on Phase 1 - Wave 2 (parallel with Phase 2)
```

**Impact**:
Without dependency declarations, the `/implement` command cannot calculate execution waves and must run all phases sequentially, even when they could run in parallel.

### 3. Adaptive Planning Metadata

**Standard Location**: `/home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md` (lines 46-135)
**Referenced In**: CLAUDE.md adaptive_planning section

**Requirements for Plan Metadata**:
- Complexity score calculation: `(tasks × 1.0) + (phases × 5.0) + (hours × 0.5) + (dependencies × 2.0)`
- Tier classification (Tier 1/2/3) based on complexity threshold
- Estimated hours per phase
- Task count per phase
- Phase structure level (L0/L1/L2)

**Current Plan Compliance**:
- ✗ No complexity score metadata
- ✗ No tier classification
- ✓ Has effort estimates ("15 minutes", "30 minutes") but not standardized
- ✗ No task counts per phase
- ✗ No structure level declaration

**Gap Impact**:
- `/expand` command cannot determine when to auto-expand phases
- `/collapse` command lacks metadata for intelligent merging
- Complexity evaluator cannot assess if plan scope has grown
- No automatic triggers for plan restructuring

### 4. Testing Protocols Integration

**Standard Location**: `/home/benjamin/.config/.claude/docs/reference/testing-protocols.md`
**Referenced In**: CLAUDE.md testing_protocols section

**Requirements for Debug/Fix Plans**:
- Test isolation standards (lines 200-236): Use `CLAUDE_SPECS_ROOT` override for test directories
- Agent behavioral compliance testing (lines 39-199): Validate agent file creation, completion signals, STEP structure
- Coverage requirements (lines 33-38): >80% for modified code
- Test discovery patterns (lines 4-31): Location in `.claude/tests/`, pattern `test_*.sh`

**Current Plan Compliance**:
- ✓ Includes comprehensive testing strategy section (lines 539-738)
- ✓ Unit tests for state-persistence.sh validation
- ✓ Integration tests for classification
- ✗ Missing test isolation standards (no CLAUDE_SPECS_ROOT override)
- ✗ Missing agent behavioral compliance tests for workflow-classifier agent
- ✗ No verification of imperative language in agent file
- ✗ No STEP structure validation tests

**Specific Gap** (testing-protocols.md:39-199):
The plan should include tests to validate that workflow-classifier.md follows behavioral compliance:
- File creation compliance (agent creates expected files)
- Completion signal format (returns structured output)
- STEP structure validation (sequential numbered steps)
- Imperative language usage (MUST/WILL/SHALL vs should/may/can)
- Verification checkpoints (self-verification before returning)

### 5. Code Standards Compliance

**Standard Location**: `/home/benjamin/.config/.claude/docs/reference/code-standards.md`

**Requirements**:
- Command architecture standards (lines 17-46): Commands are executable instructions, not documentation
- Imperative language (line 25): All required actions use MUST/WILL/SHALL
- Behavioral injection pattern (line 26): Commands invoke agents via Task tool with context injection
- Verification and fallback pattern (line 27): All file creation operations require MANDATORY VERIFICATION checkpoints
- Robustness patterns (line 28): Apply systematic robustness patterns

**Current Plan Compliance**:
- ✓ Plan identifies architectural mismatch (agent with allowed-tools: None cannot execute bash)
- ✓ Solution moves state persistence to parent command context
- ✗ Implementation details don't explicitly reference imperative language requirements
- ✗ No mention of behavioral injection pattern when updating coordinate.md
- ✗ Verification checkpoints proposed but not linked to Standard 0: Execution Enforcement

**Gap**:
The plan should explicitly reference that coordinate.md updates must follow Standard 0 (Execution Enforcement) with:
- "EXECUTE NOW" markers for bash blocks
- "MANDATORY VERIFICATION" checkpoints after agent invocation
- Imperative language (MUST/WILL) not descriptive language (should/may)

### 6. Development Workflow Standards

**Standard Location**: `/home/benjamin/.config/.claude/docs/concepts/development-workflow.md`

**Requirements**:
- Spec updater integration (lines 11-38): Manages artifacts in topic-based structure
- Artifact lifecycle (lines 40-75): Different retention policies for different artifact types
- Plan hierarchy updates (lines 91-102): Checkbox propagation after phase completion
- Git workflow (lines 104-109): Feature branches, atomic commits, test before committing

**Current Plan Compliance**:
- ✗ No mention of spec updater agent role
- ✗ No artifact lifecycle management
- ✗ No discussion of checkbox propagation through plan hierarchy
- ✓ Has rollback plan (lines 739-810) but not framed as git workflow
- ✗ Missing integration with development workflow pattern

**Specific Gap**:
The plan should specify that after implementation:
- Spec updater agent creates implementation summary in `specs/752_topic/summaries/`
- Debug reports in `specs/752_topic/debug/` are committed (not gitignored)
- Checkbox updates propagate through plan hierarchy if plan is expanded to L1/L2

### 7. Debug Report Structure Standards

**Standard Location**: `/home/benjamin/.config/.claude/docs/reference/debug-structure.md`

**Context**: This plan itself is for creating a debug fix, so should follow debug report structure guidance

**Requirements for Debug Plans**:
- Standard structure (lines 19-186): Metadata, Problem Statement, Investigation Process, Findings, Proposed Solutions, etc.
- Root cause analysis (lines 70-90): Primary cause, explanation, location with file:line references
- Evidence sections (lines 92-109): Code evidence, log evidence, state evidence
- Proposed solutions with effort/risk (lines 112-142): Multiple options with pros/cons
- Git tracking (lines 377-405): Debug reports are COMMITTED, not gitignored

**Current Plan Compliance**:
- ✓ Has Executive Summary (line 3-9)
- ✓ Has Root Cause Summary (lines 959-971)
- ✓ Includes proposed solutions with effort/risk (lines 11-72)
- ✓ Has rollback plan (lines 739-810)
- ✗ Missing formal "Problem Statement" section
- ✗ Missing "Investigation Process" section
- ✗ Root cause not in standard location/format
- ✗ No explicit confirmation this debug report will be committed to git

**Note**: While the plan is comprehensive, it doesn't follow the exact structure template from debug-structure.md. This is acceptable for a strategic plan but should be noted for consistency.

### 8. Writing Standards Compliance

**Standard Location**: `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md`

**Requirements**:
- Present-focused writing (lines 47-67): Document current state, not historical changes
- Ban temporal markers (lines 78-106): No "(New)", "(Old)", "(Updated)" labels
- Ban temporal phrases (lines 108-138): Avoid "previously", "recently", "now supports"
- Timeless writing principles (lines 66-76): Describe what the system does, not how it changed

**Current Plan Compliance**:
- ✓ No temporal markers found
- ✓ No banned temporal phrases
- ✓ Focuses on current problem and solutions
- ✓ No version references
- ✓ Excellent compliance with writing standards

**Analysis**: The plan demonstrates excellent adherence to timeless writing principles.

## Compliance Summary Matrix

| Standard Area | Compliance Level | Critical Gaps |
|---------------|------------------|---------------|
| Plan Structure | Low | Nested phases instead of flat numbered phases |
| Phase Dependencies | None | Zero dependency declarations, no wave execution |
| Adaptive Planning Metadata | Low | No complexity score, tier, or structure level |
| Testing Protocols | Medium | Missing isolation standards and agent compliance tests |
| Code Standards | Medium | Missing explicit references to imperative language |
| Development Workflow | Low | No spec updater integration, artifact lifecycle |
| Debug Report Structure | Medium | Deviates from template (acceptable for strategy plan) |
| Writing Standards | High | Excellent compliance, no temporal language |

**Overall Compliance Score**: 45% (4/8 standards with high/full compliance)

## Recommendations

### 1. Restructure Plan to Use Flat Numbered Phases

**Priority**: CRITICAL
**Impact**: Enables automated tooling, wave-based execution, complexity scoring

**Action**:
Convert the current nested structure to flat numbered phases:

**Current (Non-Compliant)**:
```markdown
## Implementation Phases

### Phase 1: Critical Fixes (P0)
**Objective**: ...
**Steps**:
1. Fix 1.1: Remove state persistence from agent
2. Fix 1.2: Move state persistence to command
```

**Recommended (Compliant)**:
```markdown
### Phase 1: Remove State Persistence from Workflow Classifier Agent

**Dependencies**: []
**Risk**: Low
**Estimated Time**: 15 minutes
**Priority**: P0 (Critical)

**Tasks**:
- [ ] Delete lines 530-587 from workflow-classifier.md
- [ ] Update agent description to clarify classification-only role
- [ ] Verify agent file no longer contains bash execution instructions

**Files Modified**:
- `/home/benjamin/.config/.claude/agents/workflow-classifier.md`

**Success Criteria**:
- Agent file has no bash execution instructions
- Agent description updated
```

Repeat for all P0, P1, P2 fixes as separate phases (estimated 10-12 phases total).

### 2. Add Phase Dependency Declarations

**Priority**: HIGH
**Impact**: Enables 40-60% time savings through parallel execution

**Action**:
For each phase, add dependency metadata:

```markdown
### Phase 1: Remove State Persistence from Agent
**Dependencies**: []  # Independent, can run first
**Risk**: Low
**Estimated Time**: 15 minutes

### Phase 2: Update Coordinate Command State Extraction
**Dependencies**: [1]  # Depends on Phase 1 completing
**Risk**: Low
**Estimated Time**: 30 minutes

### Phase 3: Add Variable Validation to State Persistence Library
**Dependencies**: []  # Independent from Phase 1-2
**Risk**: Low
**Estimated Time**: 20 minutes

### Phase 4: Update Coordinate to Use Validation
**Dependencies**: [3]  # Depends on Phase 3 validation function
**Risk**: Low
**Estimated Time**: 10 minutes
```

**Wave Calculation Result**:
- Wave 1: Phase 1, Phase 3 (parallel execution)
- Wave 2: Phase 2, Phase 4 (parallel execution after dependencies met)

### 3. Add Adaptive Planning Metadata

**Priority**: MEDIUM
**Impact**: Enables automatic expansion, collapse, and complexity tracking

**Action**:
Add metadata section to plan frontmatter or Executive Summary:

```markdown
## Plan Metadata

**Complexity Analysis**:
- Tasks: 22 (across all phases)
- Phases: 12 (after restructure)
- Estimated Hours: 3.3 hours
- Dependencies: 8
- Complexity Score: (22 × 1.0) + (12 × 5.0) + (3.3 × 0.5) + (8 × 2.0) = 100.65
- Tier: Tier 2 (50 ≤ score < 200)
- Structure Level: L0 (single file)

**Expansion Triggers**:
- No phases exceed complexity threshold (8.0)
- No automatic expansion needed
- Manual expansion available via `/expand phase 001_debug_strategy.md N`
```

### 4. Integrate Testing Protocols Standards

**Priority**: MEDIUM
**Impact**: Ensures test quality, prevents production directory pollution

**Action**:
Add testing protocol compliance section:

```markdown
### Phase N: Testing Protocol Compliance

**Dependencies**: [all implementation phases]
**Risk**: Low
**Estimated Time**: 30 minutes

**Tasks**:
- [ ] Add test isolation to all test scripts (CLAUDE_SPECS_ROOT override)
- [ ] Create agent behavioral compliance test for workflow-classifier.md
- [ ] Validate imperative language usage in workflow-classifier.md
- [ ] Verify STEP structure in agent behavioral file
- [ ] Add coverage requirement validation (≥80% for modified code)

**Test Scripts to Create**:
- `.claude/tests/test_workflow_classifier_compliance.sh` (behavioral validation)
- Update existing tests to use `CLAUDE_SPECS_ROOT` override

**Success Criteria**:
- All tests use isolation patterns
- Agent compliance tests pass
- No production directory pollution during test runs
```

### 5. Add Development Workflow Integration

**Priority**: LOW
**Impact**: Ensures proper artifact management and cross-referencing

**Action**:
Add phase for spec updater integration:

```markdown
### Phase N: Spec Updater and Artifact Management

**Dependencies**: [all implementation phases]
**Risk**: Low
**Estimated Time**: 15 minutes

**Tasks**:
- [ ] Verify debug report location: `specs/752_topic/debug/001_coordinate_classifier.md`
- [ ] Confirm debug report is NOT gitignored (committed for issue tracking)
- [ ] Create implementation summary in `specs/752_topic/summaries/001_fix_summary.md`
- [ ] Add cross-references between debug report and coordinate.md
- [ ] Update plan hierarchy checkboxes if expanded to L1/L2

**Spec Updater Actions**:
- Create summary linking this plan to modified files
- Verify gitignore compliance (debug/ committed, others ignored)
- Update cross-references in topic directory

**Success Criteria**:
- Debug report committed to git
- Implementation summary created
- Cross-references valid
```

### 6. Add Explicit Standard References

**Priority**: LOW
**Impact**: Improves traceability and compliance verification

**Action**:
Add references to specific standards in phase descriptions:

**Example**:
```markdown
### Phase 2: Update Coordinate Command (Standard 0: Execution Enforcement)

**Tasks**:
- [ ] Add bash block with "EXECUTE NOW" marker (per Code Standards line 25)
- [ ] Include "MANDATORY VERIFICATION" checkpoint (per Standard 0 pattern 2)
- [ ] Use imperative language (MUST/WILL) not descriptive (should/may)

**Standards Compliance**:
- Code Standards: Imperative language (line 25)
- Command Architecture Standards: Standard 0 - Execution Enforcement
- Behavioral Injection Pattern: Task tool invocation with context injection

**References**:
- `/home/benjamin/.config/.claude/docs/reference/code-standards.md:25`
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md:51-300`
```

### 7. Document Plan Structure Decision

**Priority**: LOW
**Impact**: Clarifies why L0 structure chosen

**Action**:
Add structure justification to Plan Metadata:

```markdown
**Structure Decision**:
- Tier 2 complexity (score 100.65) suggests L1 structure
- However, using L0 (single file) because:
  - Short implementation duration (3.3 hours)
  - Tight coupling between phases (sequential dependencies)
  - Debugging context benefits from seeing full strategy
  - No phases exceed expansion threshold

- L0 structure appropriate for this debug fix despite Tier 2 score
```

## Implementation Priority

**Critical (Must Fix)**:
1. Restructure to flat numbered phases
2. Add phase dependency declarations

**High (Should Fix)**:
3. Add adaptive planning metadata
4. Integrate testing protocols standards

**Medium (Nice to Have)**:
5. Add development workflow integration
6. Add explicit standard references
7. Document structure decision

## References

### Standards Documentation
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` (lines 1-1045)
  - Plan structure standards (lines 796-880)
  - Topic-based organization (lines 38-275)
  - Artifact lifecycle (lines 445-535)

- `/home/benjamin/.config/.claude/docs/reference/phase_dependencies.md`
  - Dependency syntax and wave-based execution
  - Referenced by directory-protocols.md:829-880

- `/home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md` (lines 1-200)
  - Plan structure levels L0/L1/L2 (lines 46-135)
  - Complexity scoring (lines 136-172)

- `/home/benjamin/.config/.claude/docs/reference/testing-protocols.md` (lines 1-236)
  - Test isolation standards (lines 200-236)
  - Agent behavioral compliance (lines 39-199)
  - Coverage requirements (lines 33-38)

- `/home/benjamin/.config/.claude/docs/reference/code-standards.md` (lines 1-84)
  - Command architecture standards (lines 17-46)
  - Imperative language (line 25)
  - Behavioral injection pattern (line 26)

- `/home/benjamin/.config/.claude/docs/concepts/development-workflow.md` (lines 1-109)
  - Spec updater integration (lines 11-38)
  - Artifact lifecycle (lines 40-75)
  - Plan hierarchy updates (lines 91-102)

- `/home/benjamin/.config/.claude/docs/reference/debug-structure.md` (lines 1-435)
  - Standard debug report structure (lines 19-186)
  - Git tracking requirements (lines 377-405)

- `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md` (lines 1-558)
  - Timeless writing principles (lines 66-76)
  - Banned patterns (lines 78-169)

- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (lines 1-300)
  - Standard 0: Execution Enforcement (lines 51-300)
  - Imperative language patterns (lines 62-188)

### Existing Plan
- `/home/benjamin/.config/.claude/specs/752_debug_coordinate_workflow_classifier/plans/001_debug_strategy.md` (lines 1-1000)
  - Executive Summary (lines 3-9)
  - Priority Fixes (lines 11-72)
  - Implementation Phases (lines 73-538)
  - Testing Strategy (lines 539-738)
