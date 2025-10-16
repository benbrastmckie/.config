# Refactor Progressive Planning Commands Following /expand-phase Pattern

## Metadata
- **Date**: 2025-01-07
- **Feature**: Refactor /expand-stage, /collapse-phase, and /collapse-stage commands
- **Scope**: Apply expand-phase architectural patterns (complexity detection, agent integration, synthesis) to remaining progressive planning commands
- **Estimated Phases**: 5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: Research conducted via /orchestrate workflow

## Overview

The `/expand-phase` command was successfully refactored in Plan 030 to include:
- Complexity detection algorithm with quantitative thresholds
- Agent integration using general-purpose + behavioral injection pattern
- 5-step synthesis process transforming 200-250 word research into 300-500+ line specs
- Quality checklists and validation standards
- Comprehensive error handling and fallback patterns

This plan extends these patterns to the three remaining progressive planning commands:
1. **`/expand-stage`**: Level 1 → Level 2 (phase → stage expansion)
2. **`/collapse-phase`**: Level 1 → Level 0 (phase → plan collapse)
3. **`/collapse-stage`**: Level 2 → Level 1 (stage → phase collapse)

**Current State**: These commands are documentation-only markdown files (230-235 lines) describing manual processes, lacking the sophistication and automation of the refactored `/expand-phase` (1113 lines with agents, synthesis, quality controls).

## Success Criteria

- [ ] All three commands have executable metadata (command-type: workflow, allowed-tools)
- [ ] `/expand-stage` implements complexity detection adapted for stage-level operations
- [ ] `/expand-stage` integrates agents for complex stage research and synthesis
- [ ] `/collapse-phase` and `/collapse-stage` extract shared logic into reusable patterns
- [ ] All commands include quality checklists and validation
- [ ] Comprehensive testing covers all refactored commands
- [ ] Documentation updated with agent usage patterns
- [ ] Backward compatibility maintained with existing progressive plans

## Technical Design

### Architectural Patterns from /expand-phase

#### 1. Complexity Detection Pattern
```bash
# Adapted for different structural levels
calculate_complexity_score() {
  local content="$1"
  local entity_type="$2"  # "phase" or "stage"

  # Quantitative metrics
  task_count=$(count_tasks "$content")
  file_refs=$(count_file_references "$content")
  unique_dirs=$(count_unique_directories "$content")

  # Keyword matching
  has_complex_keywords=$(check_keywords "$content" "consolidate|refactor|migrate|integrate")

  # Threshold comparison
  if [[ $task_count -gt 5 ]] || [[ $file_refs -ge 10 ]] || [[ $unique_dirs -gt 2 ]] || [[ $has_complex_keywords -gt 0 ]]; then
    echo "complex"
  else
    echo "simple"
  fi
}
```

#### 2. Agent Integration Pattern
```markdown
# General-purpose agent + behavioral injection
Task tool:
  subagent_type: general-purpose
  prompt: |
    Read and follow: /path/to/.claude/agents/research-specialist.md

    You are acting as a Research Specialist...
    [Agent-specific instructions]

    Output Format:
    ## Current State
    ## Patterns Found
    ## Recommendations
    ## Challenges

    Word limit: 250 words
```

#### 3. Synthesis Pattern
```
Research (250 words) → 5-step synthesis → Detailed Spec (300-500+ lines)

Steps:
1. Extract key findings (file:line refs, patterns, recommendations)
2. Map findings to tasks
3. Generate concrete examples based on patterns
4. Create testing strategy
5. Write implementation steps
```

#### 4. Quality Standards Pattern
```markdown
Quality Checklist:
- [ ] All file:line references from research incorporated
- [ ] Code examples use actual patterns (not generic)
- [ ] File paths specific (not placeholders)
- [ ] Testing strategy covers transitions
- [ ] Challenges addressed with mitigation
- [ ] Specification length: 300-500+ lines (or appropriate for operation)
```

### Adaptations for Each Command

#### /expand-stage Adaptations

**Complexity Metrics** (stage-level):
- Stage count (instead of task count): >3 stages = complex
- Implementation file references: ≥8 files = complex
- Directory depth: >1 subdirectory = complex
- Keywords: "parallel", "concurrent", "distributed", "integration"

**Agent Behaviors**:
- **research-specialist**: Analyze codebase for stage-level patterns
- **code-reviewer**: For refactoring stages
- **plan-architect**: Structure analysis for very complex stages

**Synthesis Output**: 200-400 line stage specifications (smaller than phase specs)

#### /collapse-phase and /collapse-stage Adaptations

**No Agent Integration Needed**: Collapse operations are deterministic merges, not requiring codebase research

**Shared Logic Extraction**:
- **Last-item detection**: Both commands check if collapsing the last expanded entity
- **Directory cleanup**: Both remove directories when last item collapsed
- **Content merging**: Similar algorithms for merging markdown content
- **Metadata updates**: Consistent pattern for Structure Level and expansion tracking

**Quality Standards**:
- [ ] Content preservation validated (no loss during merge)
- [ ] Metadata correctly updated (Structure Level, Expanded lists)
- [ ] Directory cleanup only when last item
- [ ] Atomic operations with temp files
- [ ] Rollback capability on errors

### File Structure

```
.claude/
├── commands/
│   ├── expand-phase.md (1113 lines - refactored in Plan 030)
│   ├── expand-stage.md (refactored to ~800-1000 lines)
│   ├── collapse-phase.md (refactored to ~400-500 lines with shared utils)
│   └── collapse-stage.md (refactored to ~400-500 lines with shared utils)
│
├── lib/
│   └── progressive-planning-utils.sh (new - shared logic)
│       ├── last_item_detection()
│       ├── merge_content_sections()
│       ├── update_structure_metadata()
│       └── atomic_file_operation()
│
├── tests/
│   ├── test_progressive_expansion.sh (existing - expand coverage)
│   ├── test_expand_stage.sh (new)
│   ├── test_collapse_phase.sh (new)
│   └── test_collapse_stage.sh (new)
│
└── docs/
    └── progressive-planning-guide.md (updated with refactored patterns)
```

### Integration Points

**With parse-adaptive-plan.sh**:
- `detect_structure_level()` - Used by all commands
- `extract_phase_content()` - expand-phase, collapse-phase
- `extract_stage_content()` - expand-stage, collapse-stage
- `add_phase_metadata()` - expand-phase
- `update_structure_level()` - All commands

**With agent system**:
- expand-stage uses behavioral injection (like expand-phase)
- collapse commands don't invoke agents (deterministic operations)

**With testing infrastructure**:
- test_progressive_expansion.sh covers detection and expansion
- New tests for stage expansion and both collapse operations
- Coverage target: ≥80% for refactored code

## Implementation Phases

### Phase 1: Shared Utilities Extraction [COMPLETED]

**Objective**: Extract common logic from collapse-phase and collapse-stage into reusable utility library

**Complexity**: Medium

**Scope**: Create `.claude/lib/progressive-planning-utils.sh` with shared functions

Tasks:
- [x] Create `.claude/lib/progressive-planning-utils.sh`
  - Location: New file in lib/ directory
  - Purpose: Centralize shared progressive planning operations

- [x] Implement `detect_last_item()` function
  - Logic: Check if collapsing last expanded phase/stage
  - Input: Plan/phase file path, entity type (phase/stage)
  - Output: Boolean (true if last item)
  - Algorithm: Parse metadata, count expanded items, compare with current

- [x] Implement `merge_markdown_sections()` function
  - Logic: Intelligently merge expanded content back to parent
  - Input: Source file path, target file path, section marker
  - Output: Merged content string
  - Algorithm: Extract sections, preserve formatting, handle conflicts

- [x] Implement `update_expansion_metadata()` function
  - Logic: Update Structure Level and Expanded lists in plan metadata
  - Input: Plan file path, operation (expand/collapse), entity type, entity id
  - Output: Updated metadata section
  - Algorithm: Parse metadata, modify relevant fields, write back

- [x] Implement `atomic_operation()` function
  - Logic: Perform file operations with rollback capability
  - Input: Operation function, target files, rollback function
  - Output: Success/failure with rollback on error
  - Algorithm: Create temp backups, execute, verify, cleanup or rollback

- [x] Add comprehensive function documentation
  - Format: ShellDoc style with usage examples
  - Include: Purpose, parameters, return values, error cases
  - Examples: Provide realistic usage for each function

Testing:
```bash
# Test shared utilities
.claude/tests/test_shared_utilities.sh

# Verify functions work correctly
# Test last-item detection with various scenarios
# Test merge algorithm with complex content
# Test metadata updates
# Test atomic operations with simulated failures
```

Expected Outcome:
- Reusable utility library reduces code duplication
- Collapse commands share 80%+ of implementation
- Well-tested, documented shared functions
- Foundation for both collapse command refactors

---

### Phase 2: Refactor /collapse-phase Command [COMPLETED]

**Objective**: Refactor collapse-phase to use shared utilities and follow expand-phase structural patterns

**Complexity**: Medium

**Scope**: Update `.claude/commands/collapse-phase.md` with executable metadata, shared utilities integration, quality standards

Tasks:
- [x] Add command metadata to collapse-phase.md
  - Location: Top of file (lines 1-6)
  - Metadata:
    ```yaml
    ---
    allowed-tools: Read, Write, Edit, Bash
    argument-hint: <plan-path> <phase-num>
    description: Collapse an expanded phase back into the main plan (Level 1 → Level 0)
    command-type: workflow
    ---
    ```

- [x] Restructure document with clear process steps
  - Section 1: Analyze Current Structure (detect Level 1)
  - Section 2: Validate Collapse Operation (check dependencies, verify phase exists)
  - Section 3: Extract Phase Content (read phase file completely)
  - Section 4: Detect Last Item (use shared utility)
  - Section 5: Merge Content (use shared utility)
  - Section 6: Update Metadata (use shared utility)
  - Section 7: Directory Cleanup (if last item)
  - Section 8: Validation (verify content preservation)

- [x] Integrate shared utilities from Phase 1
  - Replace inline last-item detection with `detect_last_item()`
  - Replace inline merge logic with `merge_markdown_sections()`
  - Replace metadata updates with `update_expansion_metadata()`
  - Wrap file operations with `atomic_operation()`

- [x] Add quality checklist section
  - Checklist items:
    - [ ] Phase content fully extracted and preserved
    - [ ] Metadata updated correctly (Structure Level, Expanded Phases)
    - [ ] Directory removed only if last phase
    - [ ] Plan file integrity validated
    - [ ] No content loss during merge
    - [ ] All references to phase file updated

- [x] Add error handling section
  - Scenario: Phase file not found
    - Recovery: Verify path, check Structure Level, report error
  - Scenario: Merge conflict (duplicate sections)
    - Recovery: Manual intervention required, preserve both versions
  - Scenario: Metadata parsing failure
    - Recovery: Rollback operation, report issue
  - Scenario: Directory removal failure
    - Recovery: Leave directory, warn user, provide cleanup command

- [x] Add validation examples
  - Example 1: Simple collapse (single phase expanded)
  - Example 2: Multiple phases expanded (not last item)
  - Example 3: Last phase collapse with directory removal
  - Show before/after structure for each

Testing:
```bash
# Test collapse-phase command
.claude/tests/test_collapse_phase.sh

# Test cases:
# - Collapse single expanded phase
# - Collapse with multiple phases (not last)
# - Collapse last phase (directory cleanup)
# - Error handling (missing files, metadata issues)
# - Content preservation validation
# - Rollback on failure
```

Expected Outcome:
- collapse-phase follows expand-phase structural pattern
- Uses shared utilities for consistency
- Comprehensive error handling and validation
- Clear documentation with examples
- All tests passing

---

### Phase 3: Refactor /collapse-stage Command [COMPLETED]

**Objective**: Refactor collapse-stage to use shared utilities and follow expand-phase structural patterns

**Complexity**: Medium

**Scope**: Update `.claude/commands/collapse-stage.md` with executable metadata, shared utilities integration, quality standards

Tasks:
- [ ] Add command metadata to collapse-stage.md
  - Location: Top of file (lines 1-6)
  - Metadata:
    ```yaml
    ---
    allowed-tools: Read, Write, Edit, Bash
    argument-hint: <phase-path> <stage-num>
    description: Collapse an expanded stage back into the phase file (Level 2 → Level 1)
    command-type: workflow
    ---
    ```

- [ ] Restructure document with clear process steps
  - Section 1: Analyze Current Structure (detect Level 2)
  - Section 2: Validate Collapse Operation (check dependencies, verify stage exists)
  - Section 3: Extract Stage Content (read stage file completely)
  - Section 4: Detect Last Item (use shared utility, adapted for stages)
  - Section 5: Merge Content (use shared utility)
  - Section 6: Update Metadata (both phase and main plan)
  - Section 7: Directory Cleanup (if last stage in phase)
  - Section 8: Validation (verify content preservation)

- [ ] Integrate shared utilities from Phase 1
  - Adapt `detect_last_item()` for stage-level detection
  - Use `merge_markdown_sections()` for stage content merge
  - Use `update_expansion_metadata()` for both phase and plan metadata
  - Wrap operations with `atomic_operation()`

- [ ] Add three-way metadata synchronization
  - Update phase file metadata (Expanded Stages list)
  - Update main plan metadata (Expanded Stages dict: phase → stages)
  - Ensure consistency across all three levels
  - Algorithm:
    1. Read stage file and identify stage number
    2. Update phase file: Remove stage from Expanded Stages list
    3. Update main plan: Update phase entry in Expanded Stages dict
    4. If last stage: Remove phase directory, update Structure Level

- [ ] Add quality checklist section
  - Checklist items:
    - [ ] Stage content fully extracted and preserved
    - [ ] Phase metadata updated (Expanded Stages list)
    - [ ] Main plan metadata updated (Expanded Stages dict)
    - [ ] Directory removed only if last stage
    - [ ] Phase file integrity validated
    - [ ] Main plan integrity validated
    - [ ] No content loss during merge

- [ ] Add error handling section
  - Scenario: Stage file not found
    - Recovery: Verify path, check Structure Level, report error
  - Scenario: Three-way metadata inconsistency
    - Recovery: Validate all three files, repair if possible, escalate if not
  - Scenario: Phase directory removal failure
    - Recovery: Leave directory, warn user, provide manual cleanup steps
  - Scenario: Parent phase file not found
    - Recovery: Recreate from stage overview, warn about potential data loss

- [ ] Add validation examples
  - Example 1: Collapse single stage from multi-stage phase
  - Example 2: Collapse last stage (phase directory cleanup)
  - Example 3: Collapse with three-way metadata update
  - Show before/after structure for each

Testing:
```bash
# Test collapse-stage command
.claude/tests/test_collapse_stage.sh

# Test cases:
# - Collapse single stage (not last)
# - Collapse last stage (directory cleanup, L2→L1 transition)
# - Three-way metadata synchronization
# - Error handling (missing files, metadata inconsistencies)
# - Content preservation validation
# - Rollback on failure
```

Expected Outcome:
- collapse-stage follows expand-phase structural pattern
- Uses shared utilities with stage-level adaptations
- Three-way metadata synchronization working correctly
- Comprehensive error handling and validation
- All tests passing

---

### Phase 4: Refactor /expand-stage with Agent Integration [COMPLETED]

**Objective**: Refactor expand-stage to include complexity detection, agent integration, and synthesis process following expand-phase pattern

**Complexity**: High

**Scope**: Transform expand-stage from documentation-only to full workflow command with agent support

Tasks:
- [ ] Add command metadata to expand-stage.md
  - Location: Top of file (lines 1-6)
  - Metadata:
    ```yaml
    ---
    allowed-tools: Read, Write, Edit, Bash, Glob
    argument-hint: <phase-path> <stage-num>
    description: Expand a stage into a detailed implementation specification with concrete specifications
    command-type: workflow
    ---
    ```

- [ ] Add complexity detection section (adapted for stages)
  - Location: After "Extract Stage Content" step
  - Metrics:
    ```bash
    # Stage-level complexity indicators
    implementation_count=$(count_implementation_steps "$stage_content")
    file_refs=$(count_file_references "$stage_content")
    unique_dirs=$(count_unique_directories "$stage_content")

    # Stage-specific keywords
    has_complex_keywords=$(check_keywords "$stage_content" "parallel|concurrent|distributed|integration")

    # Thresholds (adapted for stage level)
    is_complex=false
    if [[ $implementation_count -gt 3 ]] || \
       [[ $file_refs -ge 8 ]] || \
       [[ $unique_dirs -gt 1 ]] || \
       [[ $has_complex_keywords -gt 0 ]]; then
      is_complex=true
    fi
    ```
  - Decision tree: Simple stages → Direct expansion, Complex stages → Agent-assisted

- [ ] Add agent selection logic
  - research-specialist: Default for codebase analysis (most complex stages)
  - code-reviewer: For refactoring or consolidation stages
  - plan-architect: For stages needing sub-stage breakdown (rare)
  - Selection algorithm:
    ```bash
    if [[ "$stage_content" =~ "refactor|consolidate" ]]; then
      agent_behavior="code-reviewer"
    elif [[ $implementation_count -gt 5 ]] && [[ $unique_dirs -gt 2 ]]; then
      agent_behavior="plan-architect"
    else
      agent_behavior="research-specialist"
    fi
    ```

- [ ] Document agent invocation pattern (Section 4a)
  - General-purpose + behavioral injection (same as expand-phase)
  - Prompt template for stage-level research:
    ```markdown
    Task tool:
      subagent_type: general-purpose
      prompt: |
        Read and follow: .claude/agents/research-specialist.md

        You are acting as a Research Specialist...

        Research Task: Analyze stage-level implementation for [Stage Objective]

        Stage Implementation Steps:
        [List implementation steps from stage]

        Requirements:
        1. Search codebase for files mentioned in steps
        2. Identify implementation patterns for this stage type
        3. Find integration points with other stages
        4. Assess current state vs target state

        Output Format:
        ## Current State
        - [File:line references specific to this stage]

        ## Patterns Found
        - [Implementation patterns relevant to stage]

        ## Recommendations
        - [Specific approach for this stage]

        ## Challenges
        - [Stage-specific constraints or issues]

        Word limit: 200 words
    ```
  - Timeout: 3 minutes (shorter than phase research)
  - Error handling: Fallback to direct expansion if agent fails

- [ ] Add synthesis section (Section 4b)
  - Adapted synthesis process for stages (smaller scope than phases):
    1. Extract key findings (file:line refs, patterns, recommendations)
    2. Map findings to implementation steps
    3. Generate concrete code examples
    4. Create testing strategy
    5. Write detailed implementation guide
  - Target output: 200-400 lines (smaller than 300-500 for phases)
  - Synthesis example: Show 200-word research → 300-line stage spec

- [ ] Add quality checklist
  - [ ] All file:line references from research incorporated
  - [ ] Code examples use actual patterns (not generic)
  - [ ] File paths specific (not placeholders)
  - [ ] Testing strategy covers stage implementation
  - [ ] Challenges addressed with mitigation
  - [ ] Specification length: 200-400 lines for complex stages
  - [ ] Integration with other stages documented

- [ ] Add section templates
  - Stage Implementation Template (uses research findings)
  - Testing Strategy Template (stage-level tests)
  - Integration Points Template (with other stages)

- [ ] Add "Available Agent Types" reference section
  - List: general-purpose, statusline-setup, output-style-setup
  - Explain behavioral injection pattern
  - Warn against non-existent agent types

Testing:
```bash
# Test expand-stage command
.claude/tests/test_expand_stage.sh

# Test cases:
# - Simple stage expansion (no agent)
# - Complex stage expansion (with research-specialist)
# - Agent invocation and synthesis process
# - Quality checklist validation
# - Error handling (agent timeout, incomplete research)
# - Fallback to direct expansion
```

Expected Outcome:
- expand-stage follows expand-phase pattern comprehensively
- Complexity detection working for stage-level metrics
- Agent integration with behavioral injection
- Synthesis producing 200-400 line detailed stage specs
- Quality standards enforced
- All tests passing

---

### Phase 5: Testing and Documentation

**Objective**: Comprehensive testing of all refactored commands and documentation updates

**Complexity**: Medium

**Scope**: End-to-end testing, integration validation, documentation completion

Tasks:
- [ ] Create comprehensive test suite for expand-stage
  - File: `.claude/tests/test_expand_stage.sh`
  - Test complexity detection (simple vs complex stages)
  - Test agent invocation (with mock research results)
  - Test synthesis process (research → detailed spec)
  - Test quality validation
  - Test error handling and fallback
  - Coverage: ≥80% of expand-stage logic

- [ ] Create test suite for collapse-phase
  - File: `.claude/tests/test_collapse_phase.sh`
  - Test simple collapse (not last item)
  - Test last-item collapse with directory cleanup
  - Test content preservation
  - Test metadata updates
  - Test error scenarios and rollback
  - Coverage: ≥80% of collapse-phase logic

- [ ] Create test suite for collapse-stage
  - File: `.claude/tests/test_collapse_stage.sh`
  - Test stage collapse (not last)
  - Test last-stage collapse (directory cleanup, L2→L1 transition)
  - Test three-way metadata synchronization
  - Test content preservation
  - Test error scenarios and rollback
  - Coverage: ≥80% of collapse-stage logic

- [ ] Expand existing test_progressive_expansion.sh
  - Add expand-stage test coverage
  - Add collapse operation test coverage
  - Test complete workflows: expand-phase → expand-stage → collapse-stage → collapse-phase
  - Test partial workflows
  - Test Structure Level detection at all levels (0, 1, 2)

- [ ] Integration testing with real plans
  - Use existing Plan 028 or Plan 030 as test case
  - Test expand-stage on an actual complex phase
  - Test collapse operations on expanded structure
  - Verify no data loss through full cycle
  - Validate metadata consistency

- [ ] Update documentation
  - `.claude/docs/progressive-planning-guide.md`: Add refactored command patterns
  - `.claude/agents/README.md`: Document expand-stage integration
  - `.claude/docs/agent-integration-guide.md`: Add expand-stage section
  - `CLAUDE.md`: Update progressive planning section if needed

- [ ] Create usage examples for common scenarios
  - Example 1: Expand complex stage with research-specialist
  - Example 2: Collapse stage (not last)
  - Example 3: Collapse last stage (directory cleanup)
  - Example 4: Collapse phase after all stages collapsed
  - Example 5: Full workflow (expand → work → collapse)

- [ ] Performance benchmarking
  - Measure expand-stage times (simple vs complex)
  - Measure collapse operation times
  - Compare with expand-phase performance
  - Document expected durations

- [ ] Backward compatibility validation
  - Test with existing Level 1 and Level 2 plans
  - Ensure old metadata formats still work
  - Verify no breaking changes to progressive planning workflow
  - Document any necessary migrations

Testing:
```bash
# Run all progressive planning tests
.claude/tests/test_progressive_expansion.sh
.claude/tests/test_expand_stage.sh
.claude/tests/test_collapse_phase.sh
.claude/tests/test_collapse_stage.sh

# Integration test: Full workflow
# 1. Start with Level 0 plan
# 2. Expand phase to Level 1
# 3. Expand stage to Level 2
# 4. Collapse stage back to Level 1
# 5. Collapse phase back to Level 0
# 6. Verify content unchanged

# Performance benchmarks
time /expand-stage [complex-phase] [stage-num]
time /collapse-stage [phase-path] [stage-num]
time /collapse-phase [plan-path] [phase-num]
```

Expected Outcome:
- Comprehensive test coverage (≥80%) for all refactored commands
- All tests passing
- Documentation complete and accurate
- Usage examples demonstrate best practices
- Performance benchmarks documented
- Backward compatibility verified
- Progressive planning workflow fully tested end-to-end

---

## Testing Strategy

### Unit Testing
- Shared utilities in progressive-planning-utils.sh
- Complexity detection algorithms
- Agent prompt generation
- Synthesis process components
- Metadata update functions

### Integration Testing
- End-to-end workflows (L0 → L1 → L2 → L1 → L0)
- Agent invocation and synthesis
- Metadata synchronization across levels
- Directory management (creation and cleanup)
- Rollback and error recovery

### Manual Testing Checklist
- [ ] Expand simple stage without agents
- [ ] Expand complex stage with research-specialist
- [ ] Collapse stage (not last item)
- [ ] Collapse last stage with directory cleanup
- [ ] Collapse phase after all stages collapsed
- [ ] Full cycle preserves content
- [ ] Error handling works correctly
- [ ] Metadata stays consistent

### Test Coverage Targets
- Shared utilities: ≥90% coverage
- expand-stage: ≥80% coverage
- collapse-phase: ≥80% coverage
- collapse-stage: ≥80% coverage
- Integration tests: All critical paths covered

### Performance Benchmarks
- Simple expand-stage: <1 minute
- Complex expand-stage (with agent): 2-4 minutes
- collapse-stage: <30 seconds
- collapse-phase: <30 seconds
- Full workflow (L0→L2→L0): <10 minutes for complex plan

## Documentation Requirements

### Primary Documentation
- `.claude/commands/expand-stage.md`: Complete refactor with agent integration
- `.claude/commands/collapse-phase.md`: Refactored with shared utilities
- `.claude/commands/collapse-stage.md`: Refactored with shared utilities
- `.claude/lib/progressive-planning-utils.sh`: Comprehensive function docs

### Secondary Documentation
- `.claude/docs/progressive-planning-guide.md`: Updated workflow guide
- `.claude/agents/README.md`: expand-stage integration section
- `.claude/docs/agent-integration-guide.md`: expand-stage patterns
- Test files: Inline documentation for test cases

### Documentation Standards
- Follow CommonMark markdown specification
- Use Unicode box-drawing for diagrams
- No emojis in file content
- Include concrete examples with actual file paths
- Cross-reference related documentation

## Dependencies

### Required Files
- `.claude/commands/expand-phase.md` - Reference implementation (Plan 030)
- `.claude/lib/parse-adaptive-plan.sh` - Parsing utilities
- `.claude/agents/research-specialist.md` - Agent behavior
- `.claude/agents/code-reviewer.md` - Agent behavior
- `.claude/agents/plan-architect.md` - Agent behavior
- `CLAUDE.md` - Project standards

### External Dependencies
- Claude Code Task tool (for agent invocation)
- general-purpose agent type availability
- Bash 4.0+ (for associative arrays in utilities)
- jq (for JSON processing if needed)

### Prerequisites
- Plan 030 (expand-phase refactor) completed
- Understanding of progressive planning levels
- Existing test infrastructure in .claude/tests/
- parse-adaptive-plan.sh utilities available

## Risk Assessment

### Risk 1: Agent Integration Complexity
**Issue**: expand-stage agent integration may be too complex for stage-level operations

**Mitigation**:
- Adapt complexity thresholds for stages (lower than phases)
- Allow skipping agent research for most stages
- Provide clear guidance on when to use agents vs direct expansion
- Test with real-world stage examples

**Likelihood**: Low
**Impact**: Medium (reduced quality if thresholds too high)

### Risk 2: Shared Utilities Introduce Coupling
**Issue**: Extracting shared utilities may create tight coupling between commands

**Mitigation**:
- Design utilities as pure functions with clear contracts
- Comprehensive unit testing of utilities
- Version utilities if needed for backward compatibility
- Document expected inputs/outputs clearly

**Likelihood**: Low
**Impact**: Low (well-designed utilities reduce coupling)

### Risk 3: Three-Way Metadata Synchronization Errors
**Issue**: collapse-stage updating three files (stage, phase, main plan) risks inconsistencies

**Mitigation**:
- Atomic operations with rollback capability
- Comprehensive validation after updates
- Test all edge cases (missing files, corrupted metadata)
- Provide repair tools if inconsistencies occur

**Likelihood**: Medium
**Impact**: High (metadata corruption breaks progressive planning)
**Priority**: Test thoroughly in Phase 3

### Risk 4: Breaking Changes to Existing Plans
**Issue**: Refactored commands may not work with existing Level 1/2 plans

**Mitigation**:
- Test with existing plans (Plan 028, Plan 030)
- Support old metadata formats with graceful fallback
- Document any required migrations
- Provide migration script if necessary

**Likelihood**: Low
**Impact**: High (breaks user workflows)
**Priority**: Validate in Phase 5 integration testing

### Risk 5: Performance Regression
**Issue**: Agent integration and complexity detection may slow down operations

**Mitigation**:
- Complexity detection is fast (simple regex/counting)
- Agent research only for complex cases (opt-in)
- Measure performance benchmarks and compare
- Optimize hot paths if needed

**Likelihood**: Low
**Impact**: Low (acceptable trade-off for quality)

## Notes

### Design Decisions

#### Why Extract Shared Utilities First (Phase 1)?
- Avoids duplicating collapse logic in Phases 2 and 3
- Enables parallel development of collapse commands
- Provides reusable foundation for future progressive planning commands

#### Why Refactor Collapse Commands Before expand-stage?
- Simpler scope (no agent integration)
- Validates shared utilities work correctly
- Reduces risk for more complex expand-stage refactor (Phase 4)

#### Why Agent Integration for expand-stage?
- Stages can be complex (parallel implementations, integration testing)
- Research benefits stage specification quality
- Maintains consistency with expand-phase pattern
- Provides flexibility: simple stages skip agents, complex stages use them

#### Why Lower Complexity Thresholds for Stages?
- Stages are smaller units than phases
- >3 implementation steps (vs >5 tasks for phases) indicates complexity
- Stage-level research still valuable for complex cases
- Most stages will be simple (direct expansion)

### Future Enhancements
- **Automatic complexity scoring**: ML model to predict complexity from content
- **Stage templates**: Pre-defined templates for common stage types
- **Visualization**: Graphical view of plan structure (L0, L1, L2)
- **Collaborative editing**: Support multiple users expanding same plan
- **Rollback command**: Dedicated /rollback command for failed operations

### Related Work
- Plan 030: expand-phase refactor (reference implementation)
- Plan 024: Adaptive plan structure system (foundation for progressive planning)
- Plan 025: Progressive adaptive planning (original progressive planning design)
- test_progressive_expansion.sh: Existing test coverage

### Success Metrics
- Zero "agent type not found" errors in expand-stage
- 100% content preservation through collapse operations
- ≥80% test coverage for all refactored commands
- All existing progressive plans work with refactored commands
- Performance within benchmarks (expand-stage: <4 min complex, <1 min simple)

---

**Implementation Ready**: This plan is ready for `/implement` execution with phased approach and comprehensive testing.
