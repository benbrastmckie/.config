# Dedicated Orchestrator Commands Implementation Plan

## Metadata
- **Date**: 2025-11-16
- **Feature**: Dedicated Orchestrator Commands for Each Workflow Type
- **Scope**: Extract 5 workflow types from /coordinate into standalone commands while preserving all essential features
- **Estimated Phases**: 7
- **Estimated Hours**: 28
- **Structure Level**: 1
- **Expanded Phases**: [1, 3, 4, 6]
- **Complexity Score**: 147.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Current Coordinate Command Architecture](../reports/001_coordinate_command_architecture.md)
  - [Distinct Workflows in Coordinate](../reports/002_distinct_workflows_in_coordinate.md)
  - [Feature Preservation Patterns](../reports/003_feature_preservation_patterns.md)
- **Compliance Analysis**: [Research Overview](../../744_001_dedicated_orchestrator_commandsmd_to_make/reports/001_001_dedicated_orchestrator_commandsmd_to_make/OVERVIEW.md)

## Overview

The /coordinate command currently handles 5 distinct workflow types through initial AI-based classification, which adds 5-10 seconds latency and unnecessary complexity for users who know their exact workflow type. This plan extracts each workflow type into dedicated orchestrator commands (/report, /research-plan, /research-revise, /build, /fix) that skip classification while preserving all 6 essential coordinate features: wave-based parallel execution (40-60% time savings), state machine architecture (48.9% code reduction), context reduction (95.6% via hierarchical supervisors), metadata extraction (95% token reduction), behavioral injection (100% file creation reliability), and verification checkpoints (fail-fast error handling).

## Research Summary

**Key Findings from Research Reports**:

1. **From Current Coordinate Command Architecture Report**:
   - Workflow classification adds 5-10s latency via workflow-classifier agent
   - State machine uses 8 explicit states with validated transitions
   - Cross-bash-block coordination requires file-based state persistence (GitHub Actions pattern)
   - Library sourcing order is critical (state machine libraries BEFORE load_workflow_state)
   - Hierarchical supervision threshold: complexity ≥4 topics

2. **From Distinct Workflows in Coordinate Report**:
   - 5 workflow types with distinct inputs, outputs, and state transitions
   - research-only: initialize → research → complete (no plan/implementation)
   - research-and-plan: initialize → research → plan → complete
   - research-and-revise: initialize → research → plan → complete (with existing plan path)
   - full-implementation: initialize → research → plan → implement → test → debug/document → complete
   - debug-only: initialize → research → plan → debug → complete
   - Each workflow has specific termination conditions and output artifact requirements

3. **From Feature Preservation Patterns Report**:
   - 6 essential features form integrated system (cannot cherry-pick features)
   - Wave-based execution requires pre-calculated artifact paths to prevent conflicts
   - Behavioral injection provides 100% file creation reliability vs 60-80% without
   - Metadata extraction enables 10+ agents vs 2-3 without context reduction
   - Fail-fast validation philosophy (no retries, clear diagnostics)
   - Library reuse strategy preserves features through stable APIs

**Recommended Approach Based on Research**:
- Use library reuse strategy (workflow-state-machine.sh, state-persistence.sh) for feature preservation
- Skip workflow-classifier agent invocation (workflow type hardcoded per command)
- Preserve two-step initialization pattern to avoid positional parameter issues
- Maintain hierarchical supervision threshold (≥4 topics) from coordinate
- Implement all 6 essential features through architectural template approach
- Use fail-fast verification checkpoints after all agent invocations

## Success Criteria
- [ ] All 5 dedicated orchestrator commands created and functional
- [ ] Workflow classification phase removed (5-10s latency reduction)
- [ ] All 6 essential coordinate features preserved in each command
- [ ] State machine library integration maintained
- [ ] Test suite validates delegation rate >90%, file creation 100%
- [ ] Documentation updated with workflow type selection guide
- [ ] Backward compatibility maintained (/coordinate still functional)

## Technical Design

### Architecture Decision: Shared State Machine + Per-Workflow Command Files

**Core Components**:

1. **Shared Libraries** (preserved from /coordinate):
   - `workflow-state-machine.sh` - 8-state lifecycle management
   - `state-persistence.sh` - GitHub Actions pattern for cross-bash-block coordination
   - `dependency-analyzer.sh` - Wave-based parallel execution (Kahn's algorithm)
   - `metadata-extraction.sh` - 95% context reduction utilities
   - `verification-helpers.sh` - Fail-fast checkpoint validation
   - `error-handling.sh` - Diagnostic error messages

2. **New Command Files** (5 dedicated orchestrators):
   - `/report` - Research-only workflow (no plan/implementation)
   - `/research-plan` - Research + new plan creation
   - `/research-revise` - Research + existing plan revision
   - `/build` - Build from existing plan (implement-test-debug-document workflow, takes plan path + optional start phase)
   - `/fix` - Debug-focused workflow

3. **Command File Structure** (template-based approach):
   ```markdown
   ---
   allowed-tools: Task, TodoWrite, Bash, Read
   argument-hint: <workflow-description>
   description: [Workflow-specific description]
   command-type: primary
   dependent-agents: [Workflow-specific agents]
   ---

   # Part 1: Capture Workflow Description (identical across all commands)
   # Part 2: State Machine Initialization (hardcoded workflow_type)
   # Phase 1: Research (identical across all commands)
   # Phase 2: Planning (conditional: new plan vs revision vs skip)
   # Phase 3: Implementation (conditional: build only)
   # Phase 4: Testing (conditional: build only)
   # Phase 5: Debug (conditional: debug/build only)
   # Phase 6: Documentation (conditional: build only)
   # Completion & Cleanup (workflow-specific terminal state)
   ```

### State Machine Integration

**Workflow Type Hardcoding** (replaces classification):
```bash
# /research command
WORKFLOW_TYPE="research-only"
TERMINAL_STATE="research"

# /research-plan command
WORKFLOW_TYPE="research-and-plan"
TERMINAL_STATE="plan"

# /research-revise command
WORKFLOW_TYPE="research-and-revise"
TERMINAL_STATE="plan"

# /build command
WORKFLOW_TYPE="full-implementation"
TERMINAL_STATE="complete"

# /debug command
WORKFLOW_TYPE="debug-only"
TERMINAL_STATE="debug"
```

**sm_init() Invocation Pattern**:
```bash
# All commands use same initialization pattern
sm_init \
  "$WORKFLOW_DESCRIPTION" \
  "$COMMAND_NAME" \
  "$WORKFLOW_TYPE" \
  "$RESEARCH_COMPLEXITY" \
  "$RESEARCH_TOPICS_JSON"
```

### Research Complexity Handling

**Default Complexity per Workflow Type**:
- `/report`: Default complexity 2 (overridable via --complexity flag)
- `/research-plan`: Default complexity 3 (comprehensive research before planning)
- `/research-revise`: Default complexity 2 (focused research for revision)
- `/build`: N/A (takes existing plan path as argument, no research phase)
- `/fix`: Default complexity 2 (focused debugging research)

**Complexity Override Implementation** (Phase 1, included in template):
```bash
# Parse --complexity flag from workflow description
RESEARCH_COMPLEXITY="${DEFAULT_COMPLEXITY}"  # Command-specific default

# Support both embedded and explicit flag formats:
# - Embedded: /research "auth patterns --complexity 4"
# - Explicit: /research --complexity 4 "auth patterns"
if [[ "$WORKFLOW_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  # Strip flag from workflow description
  WORKFLOW_DESCRIPTION=$(echo "$WORKFLOW_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//')
fi

# Validation: reject invalid complexity values
if ! echo "$RESEARCH_COMPLEXITY" | grep -Eq "^[1-4]$"; then
  handle_state_error "Invalid research complexity: $RESEARCH_COMPLEXITY (must be 1-4)" 1
fi
```

### Phase Conditional Execution

**Conditional Phase Logic per Command**:

1. **/report**: Execute research phase only, skip to complete
2. **/research-plan**: Execute research → plan → complete
3. **/research-revise**: Execute research → plan (revision mode) → complete
4. **/build**: Execute implement → test → debug/document → complete (takes existing plan path as argument, optional start phase)
5. **/fix**: Execute research → plan (debug strategy) → debug → complete

**Implementation Pattern**:
```bash
# After research phase
case "$COMMAND_NAME" in
  research)
    sm_transition "$STATE_COMPLETE"
    display_brief_summary
    exit 0
    ;;
  research-plan|research-revise)
    sm_transition "$STATE_PLAN"
    ;;
  build)
    sm_transition "$STATE_PLAN"
    ;;
  debug)
    sm_transition "$STATE_PLAN"
    ;;
esac
```

### Feature Preservation Strategy

**All 6 Essential Features Maintained**:

1. **Wave-Based Parallel Execution** (40-60% time savings):
   - Preserved in /build command via implementer-coordinator agent
   - Uses dependency-analyzer.sh library (unchanged)
   - Pre-calculated artifact paths prevent parallel execution conflicts

2. **State Machine Architecture** (48.9% code reduction):
   - All commands use workflow-state-machine.sh library
   - Hardcoded workflow_type replaces LLM classification
   - State transitions validated against transition table

3. **Context Reduction** (95.6% via hierarchical supervisors):
   - Hierarchical threshold (≥4 topics) preserved in all commands
   - research-sub-supervisor agent used for complexity ≥4
   - Flat coordination for complexity <4

4. **Metadata Extraction** (95% token reduction):
   - All agents return metadata-only responses (200-300 tokens vs 5,000-10,000)
   - Behavioral injection pattern preserved
   - Verification checkpoints validate artifact creation

5. **Behavioral Injection** (100% file creation reliability):
   - Path pre-calculation before agent invocations
   - Context injection into agent prompts
   - Imperative instructions (EXECUTE NOW, USE Task tool)

6. **Verification Checkpoints** (fail-fast error handling):
   - Mandatory verification after each agent invocation
   - File existence checks with diagnostic messages
   - Fail-fast for research/planning/implementation/testing phases (no retries)
   - Limited retry for debug phase only (max 2 attempts to prevent infinite loops)

## Implementation Phases

### Phase 1: Foundation - Create Command Template and Shared Utilities (High Complexity)
dependencies: []

**Objective**: Create reusable template with all 6 essential features for command generation

**Status**: PENDING

**Complexity**: High (7/10)

**Summary**: Create comprehensive 600-800 line template with version 1.0.0, library compatibility verification script, and CHANGELOG. Template includes workflow description capture, state machine initialization with substitution markers, hierarchical/flat research coordination, complexity override parsing, and 5 conditional phase sections. Compatibility script validates library versions and feature presence.

**Key Deliverables**:
- Template file with 10 major sections and substitution markers
- Compatibility verification script (200+ lines)
- Template CHANGELOG v1.0.0
- 25+ acceptance criteria checkpoints

For detailed implementation specification, see [Phase 1 Expansion](../artifacts/expansion_phase_1.md)

**Expected Duration**: 4 hours

### Phase 2: Research-Only Command - Create /research
dependencies: [1]

**Objective**: Create simplest workflow command (research-only) as proof-of-concept

**Complexity**: Low

**Tasks**:
- [ ] Copy template to `.claude/commands/research.md`
- [ ] Substitute `{{WORKFLOW_TYPE}}` → `"research-only"`
- [ ] Substitute `{{TERMINAL_STATE}}` → `"research"`
- [ ] Substitute `{{COMMAND_NAME}}` → `"research"`
- [ ] Substitute `{{DEFAULT_COMPLEXITY}}` → `2`
- [ ] Remove conditional phase sections (planning, implementation, testing, debug, documentation)
- [ ] Add research-only completion logic: `sm_transition "$STATE_COMPLETE"` after research phase
- [ ] Update YAML frontmatter: `description: "Research workflow without plan/implementation"`
- [ ] Add verification checkpoint after research phase
- [ ] Test command with example workflow: `/research "authentication patterns in codebase"`

**Testing**:
```bash
# Test /research command execution
cd "$CLAUDE_PROJECT_DIR"
/research "authentication patterns in codebase"

# Verify outputs
test -d .claude/specs/*/reports/  # Research reports created
test ! -f .claude/specs/*/plans/*.md  # No plan file created (expected)

# Verify state machine
grep "TERMINAL_STATE=research" ~/.claude/tmp/workflow_*.sh
grep "WORKFLOW_TYPE=research-only" ~/.claude/tmp/workflow_*.sh
```

**Expected Duration**: 3 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(743): complete Phase 2 - Research-Only Command - Create /research`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Research-and-Plan Commands - Create /research-plan and /research-revise (Medium Complexity)
dependencies: [2]

**Objective**: Create planning-focused workflows (new plan creation and plan revision)

**Status**: PENDING

**Complexity**: Medium (6/10)

**Summary**: Create two commands from template with distinct plan-architect invocation modes. /research-plan uses new plan creation mode (Write tool) while /research-revise uses revision mode (Edit tool + preserve completed phases). Includes backup creation logic with timestamp and size verification, natural language path extraction with regex validation, and state machine integration with proper terminal states.

**Key Deliverables**:
- Two command files with complete YAML frontmatter and bash code
- Plan-architect agent invocation patterns for both modes
- Backup creation and verification logic (30+ lines)
- Path extraction with comprehensive validation
- 15+ test cases (unit, integration, feature preservation)

For detailed implementation specification, see [Phase 3 Expansion](../artifacts/expansion_phase_3.md)

**Expected Duration**: 5 hours

### Phase 4: Build Command - Create /build (Very High Complexity)
dependencies: [3]

**Objective**: Create build-from-plan workflow that takes existing plan and implements it

**Status**: PENDING

**Complexity**: Very High (9/10)

**Summary**: Most complex command with 19 tasks covering argument parsing (/implement pattern), auto-resume with two-tier strategy (checkpoint validation → fallback), wave-based parallel execution (40-60% time savings), conditional branching (test success → document, test failure → debug), and debug retry logic (max 2 attempts). Includes implementer-coordinator integration, dependency-analyzer.sh for wave execution, and comprehensive checkpoint verification for safe resume.

**Key Deliverables**:
- Complete /build command with argument parsing and auto-resume
- Wave-based parallelization with dependency analysis
- Conditional phase branching with state transitions
- Debug retry strategy with escalation
- 5 Architecture Decision Records (ADRs)
- 10+ unit tests, 3+ integration tests
- Performance benchmarks (40-60% time savings validation)

For detailed implementation specification (1,591 lines), see [Phase 4 Expansion](../artifacts/expansion_phase_4.md)

**Expected Duration**: 6 hours

### Phase 5: Debug-Focused Command - Create /debug
dependencies: [4]

**Objective**: Create debug-focused workflow for root cause analysis and bug fixing

**Complexity**: Medium

**Tasks**:
- [ ] Create `/fix` command from template
- [ ] Substitute workflow_type → `"debug-only"`, terminal_state → `"debug"`, default_complexity → `2`
- [ ] Add Phase 2: Planning (debug strategy plan creation)
- [ ] Add Phase 3: Debug with debug-analyst agent invocation
- [ ] Add root cause analysis logic
- [ ] Add fix verification with optional test execution
- [ ] Add completion logic: `sm_transition "$STATE_COMPLETE"` after debug phase
- [ ] Test `/fix` with example: `/fix "investigate authentication timeout errors in production logs"`

**Testing**:
```bash
# Test /fix command
/fix "investigate authentication timeout errors in production logs"

# Verify outputs
test -d .claude/specs/*/reports/  # Debug research reports
test -f .claude/specs/*/plans/*.md  # Debug strategy plan
test -f .claude/specs/*/debug/*.log  # Debug artifacts

# Verify state transitions
grep "sm_transition.*debug" .claude/commands/fix.md
grep "sm_transition.*complete" .claude/commands/fix.md
```

**Expected Duration**: 4 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(743): complete Phase 5 - Debug-Focused Command - Create /debug`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Feature Preservation Validation (High Complexity)
dependencies: [2, 3, 4, 5]

**Objective**: Verify all 6 essential coordinate features preserved in new commands

**Status**: PENDING

**Complexity**: High (8/10)

**Summary**: Comprehensive validation of 6 essential features (delegation rate >90%, context usage <300 tokens, state machine, verification checkpoints, wave execution, hierarchical supervision) across all 5 new commands. Includes validation script with modular design, 5 edge case test categories (concurrent execution, invalid paths, mid-phase interruption, library incompatibility, malformed input), and performance benchmarking with 10-run statistical analysis. Target: 30/30 feature checks passed (6 features × 5 commands).

**Key Deliverables**:
- Complete validation script with 6 feature validation functions
- 11 edge case tests with comprehensive coverage
- Performance baseline measurement framework
- Two documentation templates (feature preservation results, performance baseline)
- Latency budgets: /research <5s, /research-plan <15s, /research-revise <10s, /build <60s, /fix <10s

For detailed implementation specification, see [Phase 6 Expansion](../artifacts/expansion_phase_6.md)

**Expected Duration**: 4 hours

### Phase 7: Documentation and Backward Compatibility
dependencies: [6]

**Objective**: Update documentation and maintain /coordinate backward compatibility

**Complexity**: Low

**Tasks**:
- [ ] Create workflow type selection guide: `.claude/docs/guides/workflow-type-selection-guide.md`
- [ ] Add decision matrix: user intent → command mapping
- [ ] Add examples for each workflow type
- [ ] Add comparison table: /coordinate vs dedicated commands
- [ ] Update `.claude/docs/quick-reference/command-reference.md` with new commands
- [ ] Add deprecation notice to /coordinate command (recommend dedicated commands)
- [ ] Update CLAUDE.md PROJECT_COMMANDS section with new commands
- [ ] Test /coordinate still functional (backward compatibility verification)
- [ ] Add migration guide from /coordinate to dedicated commands

**Testing**:
```bash
# Verify documentation completeness
test -f .claude/docs/guides/workflow-type-selection-guide.md
grep -q "research-only" .claude/docs/guides/workflow-type-selection-guide.md
grep -q "research-and-plan" .claude/docs/guides/workflow-type-selection-guide.md

# Verify /coordinate backward compatibility
/coordinate "research authentication patterns"  # Should still work
grep "DEPRECATED" .claude/commands/coordinate.md  # Deprecation notice present

# Verify command reference updated
grep -q "/research" .claude/docs/quick-reference/command-reference.md
grep -q "/build" .claude/docs/quick-reference/command-reference.md
```

**Expected Duration**: 2 hours

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(743): complete Phase 7 - Documentation and Backward Compatibility`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing (Per Phase)
- Template validation: Verify all substitution markers present
- Command syntax validation: YAML frontmatter parsing
- State machine integration: sm_init and sm_transition usage
- Library sourcing order: state machine libraries before load_workflow_state

### Integration Testing (Phase 6)
- End-to-end workflow execution for each command
- Agent invocation verification (behavioral injection)
- File creation verification (verification checkpoints)
- State persistence verification (cross-bash-block coordination)

### Performance Testing
- Latency reduction measurement: /coordinate vs dedicated commands (target: 5-10s reduction)
- Wave execution performance: /build parallel vs sequential (target: 40-60% time savings)
- Context usage measurement: metadata extraction validation (target: <300 tokens per agent)

### Feature Preservation Testing
- Delegation rate validation (target: >90%)
- Context reduction validation (target: 95%+)
- File creation reliability (target: 100%)
- State machine transition validation (all transitions valid)
- Wave execution validation (/build only)
- Hierarchical supervision validation (complexity ≥4)

### Regression Testing
- Verify /coordinate still functional after changes
- Verify existing agent behavioral files compatible
- Verify existing library APIs unchanged

## Documentation Requirements

### User-Facing Documentation
- Workflow type selection guide (decision matrix)
- Command reference updates (5 new commands)
- Migration guide from /coordinate to dedicated commands
- Examples for each workflow type

### Developer Documentation
- Template customization guide
- Feature preservation checklist
- Library API stability guarantees
- Anti-pattern warnings

### Architecture Documentation
- State machine integration patterns
- Conditional phase execution logic
- Workflow type to terminal state mapping
- Hierarchical supervision threshold configuration

## Dependencies

### External Dependencies
- Existing library files (workflow-state-machine.sh, state-persistence.sh, etc.)
- Existing agent behavioral files (research-specialist, plan-architect, implementer-coordinator, debug-analyst)
- Testing infrastructure (.claude/tests/)

### Prerequisite Tasks
- None (self-contained implementation)

### Blocking Issues
- None identified

## Revision History

### Revision 1 - 2025-11-16
- **Date**: 2025-11-16
- **Type**: research-informed
- **Research Reports Used**:
  - `/home/benjamin/.config/.claude/specs/743_coordinate_command_working_reasonably_well_more/reports/001_topic1.md` - Claude Infrastructure Analysis
  - `/home/benjamin/.config/.claude/specs/743_coordinate_command_working_reasonably_well_more/reports/002_topic2.md` - Documentation Standards Review
  - `/home/benjamin/.config/.claude/specs/743_coordinate_command_working_reasonably_well_more/reports/003_topic3.md` - Dedicated Orchestrator Plan Analysis
- **Key Changes**:
  - **Phase 1**: Added template versioning (v1.0.0) with library compatibility matrix and CHANGELOG.md
  - **Phase 1**: Moved complexity override from "future enhancement" to MVP (template includes --complexity flag parsing with validation)
  - **Phase 4**: Standardized /build argument pattern with /implement (auto-resume, phase validation, --dashboard, --dry-run flags)
  - **Phase 4**: Clarified error recovery policy (fail-fast for all phases except debug, max 2 debug retry attempts)
  - **Phase 6**: Added edge case testing (concurrent execution, invalid inputs, mid-phase interruption, library incompatibility)
  - **Phase 6**: Added performance baseline measurement and latency budget validation (<5s /research, <15s /research-plan, <10s /research-revise, <10s /fix)
  - **Technical Design**: Updated Research Complexity Handling section with implementation details (embedded and explicit flag formats)
  - **Feature Preservation**: Clarified retry policy distinguishes fail-fast (research/plan/implement/test) from limited retry (debug only)
- **Rationale**:
  - Research report 003 identified 5 gaps: incomplete argument handling, unclear error recovery, missing template versioning, incomplete testing, and deferred complexity override
  - /implement command provides proven argument pattern (auto-resume, optional phase, flags) that should be replicated for consistency
  - Template versioning prevents maintenance burden and enables compatibility verification (semantic versioning with library dependencies)
  - Complexity override provides immediate value for power users, including in MVP avoids breaking changes later
  - Edge case testing and performance baseline ensure production readiness and prevent regression
- **Backup**: `/home/benjamin/.config/.claude/specs/743_coordinate_command_working_reasonably_well_more/plans/backups/001_dedicated_orchestrator_commands_20251116_231638.md`

## Risk Management

### Technical Risks

**Risk 1: Library API Changes**
- **Likelihood**: Low
- **Impact**: High (breaks all commands)
- **Mitigation**: Use library compatibility verification script, lock library versions

**Risk 2: Feature Loss During Template Customization**
- **Likelihood**: Medium
- **Impact**: High (defeats purpose of dedicated commands)
- **Mitigation**: Automated feature preservation validation in Phase 6

**Risk 3: State Machine Transition Errors**
- **Likelihood**: Low
- **Impact**: Medium (workflow stuck in invalid state)
- **Mitigation**: sm_transition() validates transitions against table, fail-fast on invalid transitions

### Process Risks

**Risk 1: Template Maintenance Burden**
- **Likelihood**: Medium
- **Impact**: Low (template updates needed when patterns evolve)
- **Mitigation**: Version template with changelog, provide migration guides

**Risk 2: Test Coverage Gaps**
- **Likelihood**: Medium
- **Impact**: Medium (undetected feature violations)
- **Mitigation**: Comprehensive test suite in Phase 6, CI/CD integration

### Rollback Strategy
- Keep /coordinate functional (backward compatibility)
- Mark new commands as experimental initially
- Gradual migration with deprecation period
- Git revert available for each phase (atomic commits)
