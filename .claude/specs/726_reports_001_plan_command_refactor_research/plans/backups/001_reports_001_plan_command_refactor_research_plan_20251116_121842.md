# Plan Command Refactor Implementation Plan

## Metadata
- **Date**: 2025-11-16
- **Feature**: Refactor /plan command with robust architecture patterns
- **Scope**: Transform pseudocode template to production-grade executable command
- **Estimated Phases**: 6
- **Estimated Hours**: 18-22
- **Structure Level**: 0
- **Complexity Score**: 127.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Coordinate Command Architecture and Fragility Analysis](/home/benjamin/.config/.claude/specs/725_plan_command_refactor_research/reports/001_plan_command_refactor_research/001_coordinate_command_architecture_and_fragility_analysis.md)
  - [Optimize-Claude Command Robustness Patterns](/home/benjamin/.config/.claude/specs/725_plan_command_refactor_research/reports/001_plan_command_refactor_research/002_optimize_claude_command_robustness_patterns.md)
  - [Current Plan Command Implementation Review](/home/benjamin/.config/.claude/specs/725_plan_command_refactor_research/reports/001_plan_command_refactor_research/003_current_plan_command_implementation_review.md)
  - [Context Preservation and Metadata Passing Strategies](/home/benjamin/.config/.claude/specs/725_plan_command_refactor_research/reports/001_plan_command_refactor_research/004_context_preservation_and_metadata_passing_strategies.md)

## Overview

The /plan command currently exists as a 230-line pseudocode template with comprehensive documentation but no executable implementation. This refactor will transform it into a production-grade command following proven robustness patterns from optimize-claude while avoiding the complexity pitfalls identified in coordinate.

The refactored command will:
1. Execute feature description analysis using LLM classification pattern
2. Conditionally delegate research for complex features (complexity ≥7 or architecture keywords)
3. Generate implementation plans using plan-architect agent with behavioral injection
4. Validate plans against project standards
5. Provide fail-fast verification at every stage
6. Maintain absolute path discipline and idempotent operations

## Research Summary

**Key Findings from Research Reports**:

1. **Coordinate Fragility** (Report 001): 2,466-line command evolved through 13 failed refactor attempts (Nov 4-6, 2025), suffers from subprocess isolation constraints requiring stateless recalculation across 6+ bash blocks, 50+ verification checkpoints, and 400-line code transformation bugs. Complexity stems from fighting Claude Code Bash tool execution model.

2. **Optimize-Claude Robustness** (Report 002): Five-layer architectural pattern achieves near-perfect reliability: (1) fail-fast verification after every stage, (2) agent behavioral injection with 28+ completion criteria, (3) library integration for proven algorithms, (4) lazy directory creation, (5) comprehensive test coverage. "Create file FIRST, analyze LATER" pattern ensures deliverables exist even if errors occur.

3. **Current Plan Implementation** (Report 003): Command is pseudocode documentation, not executable code. Missing core functions: analyze_feature_description(), extract_requirements(), validate-plan.sh, extract-standards.sh. Libraries exist (plan-core-bundle.sh, complexity-utils.sh) but orchestration is incomplete.

4. **Context Preservation** (Report 004): State-persistence.sh (GitHub Actions pattern) achieves 70% performance improvement (50ms → 15ms), metadata-extraction.sh provides 50-word summaries, context-pruning.sh achieves 95% reduction. Pre-calculated artifact paths eliminate subagent overhead.

**Recommended Approach**:
- Follow optimize-claude's fail-fast verification pattern, NOT coordinate's complexity
- Use single bash script execution (not multi-block coordination)
- Implement LLM-based feature analysis for intelligent pre-planning
- Apply behavioral injection with mandatory file creation protocol
- Leverage existing libraries (plan-core-bundle.sh, complexity-utils.sh)
- Add comprehensive validation with validate-plan.sh
- Maintain absolute path discipline throughout

## Success Criteria

- [ ] Plan command executes from pseudocode template to working implementation
- [ ] Feature description analysis uses LLM classification (haiku-4 model)
- [ ] Research delegation triggers automatically for complexity ≥7 or architecture keywords
- [ ] Plan-architect agent creates plans with mandatory verification checkpoints
- [ ] All operations use absolute paths (verified at entry point)
- [ ] Validation confirms plans meet CLAUDE.md standards compliance
- [ ] Test suite covers agent structure, completion signals, and behavioral compliance
- [ ] Command stays under 400 lines (no code transformation bugs)
- [ ] Idempotent operations allow safe re-runs
- [ ] Error messages include context (agent name, expected artifact, diagnostic hints)
- [ ] Plans include rollback procedures
- [ ] Documentation updated with usage examples and troubleshooting

## Technical Design

### Architecture Overview

```
/plan <feature-description> [report-path1] [report-path2] ...
  │
  ├─ Phase 1: Argument Parsing & Validation
  │   ├─ Verify absolute paths
  │   ├─ Parse feature description (quoted/multi-word support)
  │   └─ Extract optional report paths
  │
  ├─ Phase 2: Feature Analysis (LLM Classification)
  │   ├─ Invoke haiku-4 for complexity/scope/template analysis
  │   ├─ Return JSON: {complexity, suggested_phases, template, keywords}
  │   └─ Determine if research delegation required
  │
  ├─ Phase 3: Research Delegation (Conditional)
  │   ├─ Trigger if: complexity ≥7 OR keywords match
  │   ├─ Generate research topics from feature description
  │   ├─ Invoke research-specialist agents with behavioral injection
  │   ├─ Extract metadata (50-word summaries)
  │   └─ Verify reports created (fail-fast)
  │
  ├─ Phase 4: Standards Discovery
  │   ├─ Source unified-location-detection.sh
  │   ├─ Discover CLAUDE.md via upward search
  │   ├─ Extract code standards, testing protocols, documentation policy
  │   └─ Cache standards for plan-architect
  │
  ├─ Phase 5: Plan Creation
  │   ├─ Pre-calculate absolute plan path (topic-based organization)
  │   ├─ Ensure parent directory exists (lazy creation)
  │   ├─ Invoke plan-architect agent with behavioral injection
  │   ├─ Pass: feature, research reports, standards, output path
  │   ├─ Verify plan created at exact path (fail-fast)
  │   └─ Verify file size ≥2000 bytes, phase count ≥3
  │
  └─ Phase 6: Plan Validation
      ├─ Source validate-plan.sh (NEW LIBRARY)
      ├─ Validate metadata completeness
      ├─ Validate standards compliance
      ├─ Validate test phases present
      ├─ Validate phase dependencies valid
      └─ Generate validation report
```

### Component Design

**1. Feature Analysis (LLM Classification)**
- Use Task tool with haiku-4 model for fast classification (<5 seconds)
- Analysis criteria: complexity keywords, scope indicators, technical depth
- Return structured JSON for deterministic downstream logic
- Cache results to avoid re-analysis on retries

**2. Research Delegation**
- Triggers: complexity ≥7 OR keywords (integrate, migrate, refactor, architecture)
- Generate 1-4 research topics from feature description
- Use research-specialist agent with behavioral injection
- Pre-calculate report paths using topic-based numbering
- Extract metadata (50-word summaries) for plan context
- Verify reports created with fail-fast checkpoints

**3. Plan-Architect Agent Invocation**
- Source plan-architect.md behavioral file
- Pass workflow-specific context: feature, reports, standards, path
- Behavioral protocol enforces: create plan file FIRST, analyze LATER
- Verify 42 completion criteria before return
- Return structured signal: PLAN_CREATED: [absolute-path]

**4. Validation Library (validate-plan.sh)**
- Check metadata completeness (8 required fields)
- Validate standards references (CLAUDE.md path, code standards, testing protocols)
- Verify test phases present (if Testing Protocols defined in CLAUDE.md)
- Verify documentation tasks exist (if Documentation Policy defined)
- Validate phase dependencies (no circular deps)
- Generate validation report with warnings/errors

### Error Handling Strategy

**Fail-Fast Verification Pattern** (from optimize-claude):
```bash
# After every critical operation
if [ ! -f "$ARTIFACT_PATH" ]; then
  echo "ERROR: Agent N (agent-name) failed to create artifact: $ARTIFACT_PATH"
  echo "This is a critical failure. Check agent logs above."
  exit 1
fi
```

**Absolute Path Validation** (at entry point):
```bash
if [[ ! "$REPORT_PATH" =~ ^/ ]]; then
  echo "ERROR: REPORT_PATH must be absolute: $REPORT_PATH"
  exit 1
fi
```

**Idempotent Operations**:
```bash
# Lazy directory creation (safe to run multiple times)
ensure_artifact_directory "$PLAN_PATH" || exit 1

# Atomic state persistence
append_workflow_state "PLAN_PATH" "$PLAN_PATH"
verify_state_variable "PLAN_PATH" || exit 1
```

## Implementation Phases

### Phase 1: Core Command Structure
dependencies: []

**Objective**: Create executable command framework with argument parsing and validation

**Complexity**: Medium

**Tasks**:
- [ ] Create `/home/benjamin/.config/.claude/commands/plan.md` with executable bash blocks (file: .claude/commands/plan.md)
- [ ] Implement argument parsing with quoted multi-word support (lines 17-39)
- [ ] Add absolute path validation for all input paths (entry point verification)
- [ ] Source required libraries: unified-location-detection.sh, state-persistence.sh
- [ ] Initialize workflow state using init_workflow_state("plan_$$")
- [ ] Add help text display for --help flag
- [ ] Implement error handling with context enrichment pattern
- [ ] Add set +H to disable history expansion (prevent bad substitution errors)
- [ ] Verify CLAUDE_PROJECT_DIR detection succeeds (fail-fast if missing)
- [ ] Add comprehensive inline comments explaining patterns

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test argument parsing
/plan "Add user authentication" /path/to/report.md
/plan "Multi word feature description" report1.md report2.md

# Test validation
/plan "" # Should error: empty description
/plan "feature" relative/path.md # Should error: relative path

# Test help
/plan --help # Should display usage
```

**Expected Duration**: 3-4 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(726): complete Phase 1 - Core Command Structure`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Feature Analysis (LLM Classification)
dependencies: [1]

**Objective**: Implement intelligent feature analysis using LLM classification pattern

**Complexity**: High

**Tasks**:
- [ ] Create analyze_feature_description() function using Task tool (file: .claude/commands/plan.md, lines 40-85)
- [ ] Use haiku-4 model for fast classification (<5 seconds)
- [ ] Design classification prompt: extract complexity, scope, keywords, suggested template
- [ ] Return structured JSON: {estimated_complexity, suggested_phases, template_type, keywords, requires_research}
- [ ] Implement complexity trigger logic: ≥7 OR keywords (integrate, migrate, refactor, architecture)
- [ ] Cache analysis results to state file (avoid re-analysis on retries)
- [ ] Add error handling for Task tool failures (fallback to heuristic analysis)
- [ ] Verify JSON schema matches downstream expectations
- [ ] Add logging: emit_progress "Analyzing feature complexity..."
- [ ] Document classification criteria in inline comments

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test complexity detection
analyze_feature_description "Add user login form" # Should return: complexity=4, requires_research=false
analyze_feature_description "Migrate authentication to OAuth2" # Should return: complexity=8, requires_research=true
analyze_feature_description "Refactor plugin architecture" # Should return: complexity=9, requires_research=true

# Test error handling
# Simulate Task tool failure, verify fallback works
```

**Expected Duration**: 4-5 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(726): complete Phase 2 - Feature Analysis (LLM Classification)`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Research Delegation
dependencies: [2]

**Objective**: Implement conditional research delegation for complex features

**Complexity**: High

**Tasks**:
- [ ] Implement research delegation trigger logic (file: .claude/commands/plan.md, lines 86-145)
- [ ] Generate 1-4 research topics from feature description (based on complexity)
- [ ] Pre-calculate report paths using topic-based organization (create_topic_artifact pattern)
- [ ] Ensure report directories exist using ensure_artifact_directory()
- [ ] Invoke research-specialist agents with behavioral injection (source research-specialist.md)
- [ ] Pass workflow-specific context: topic, report_path, standards, complexity
- [ ] Implement parallel agent invocation (1-4 agents based on RESEARCH_COMPLEXITY)
- [ ] Add fail-fast verification after each agent (verify report exists)
- [ ] Extract metadata from reports using extract_report_metadata() (50-word summaries)
- [ ] Cache metadata to state file for plan-architect context
- [ ] Add timeout handling (5-minute default per agent)
- [ ] Implement graceful degradation if agent fails (continue with partial research)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test research delegation
/plan "Migrate to microservices architecture" # Should invoke 3-4 research agents
/plan "Add button to UI" # Should skip research (low complexity)

# Test verification
# Simulate agent failure, verify fail-fast triggers
# Verify metadata extraction produces 50-word summaries
```

**Expected Duration**: 5-6 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(726): complete Phase 3 - Research Delegation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Standards Discovery and Validation Library
dependencies: [1]

**Objective**: Implement standards discovery and create validate-plan.sh library

**Complexity**: Medium

**Tasks**:
- [ ] Implement standards discovery in command (file: .claude/commands/plan.md, lines 146-175)
- [ ] Source unified-location-detection.sh for upward CLAUDE.md search
- [ ] Extract code standards from CLAUDE.md (indentation, naming, language-specific)
- [ ] Extract testing protocols (test commands, coverage requirements)
- [ ] Extract documentation policy (README requirements, format standards)
- [ ] Cache extracted standards to state file (avoid re-extraction)
- [ ] Create validate-plan.sh library (file: .claude/lib/validate-plan.sh, NEW)
- [ ] Implement validate_metadata() - check 8 required fields present
- [ ] Implement validate_standards_compliance() - verify standards referenced
- [ ] Implement validate_test_phases() - check test phases exist if Testing Protocols defined
- [ ] Implement validate_documentation_tasks() - check docs tasks exist if Documentation Policy defined
- [ ] Implement validate_phase_dependencies() - check no circular dependencies
- [ ] Add generate_validation_report() - return JSON with warnings/errors
- [ ] Add comprehensive error messages for each validation failure
- [ ] Document library functions with usage examples

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test standards discovery
source .claude/lib/unified-location-detection.sh
STANDARDS=$(discover_claude_md) # Should find /home/benjamin/.config/CLAUDE.md

# Test validation library
source .claude/lib/validate-plan.sh
validate_plan "$PLAN_PATH" "$STANDARDS_FILE" # Should return validation report

# Test validation checks
# Create plan with missing metadata → should error
# Create plan without test phases → should warn
# Create plan with circular dependencies → should error
```

**Expected Duration**: 3-4 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(726): complete Phase 4 - Standards Discovery and Validation Library`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Plan-Architect Agent Invocation
dependencies: [2, 3, 4]

**Objective**: Implement plan creation via plan-architect agent with behavioral injection

**Complexity**: Medium

**Tasks**:
- [ ] Pre-calculate plan path using topic-based organization (file: .claude/commands/plan.md, lines 176-230)
- [ ] Ensure plan parent directory exists using ensure_artifact_directory()
- [ ] Source plan-architect.md behavioral file (verify file exists)
- [ ] Build workflow-specific context prompt (feature, research reports, standards, output path)
- [ ] Include ALL research report paths in agent prompt metadata
- [ ] Pass complexity score and suggested phases from feature analysis
- [ ] Invoke plan-architect using Task tool with general-purpose subagent
- [ ] Set timeout to 10 minutes (comprehensive planning)
- [ ] Parse agent return signal: PLAN_CREATED: [absolute-path]
- [ ] Verify plan file created at exact path (fail-fast)
- [ ] Verify file size ≥2000 bytes (comprehensive plan check)
- [ ] Verify phase count ≥3 (minimum phases check)
- [ ] Verify checkbox count ≥10 (/implement compatibility check)
- [ ] Extract plan metadata using extract_plan_metadata()
- [ ] Cache plan metadata to state file
- [ ] Add error context enrichment (agent name, expected artifact, diagnostic hints)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test plan creation
/plan "Add user authentication" # Should invoke plan-architect
# Verify: plan created at correct path
# Verify: file size ≥2000 bytes
# Verify: ≥3 phases present
# Verify: ≥10 checkboxes present

# Test verification checkpoints
# Simulate plan-architect failure → should fail-fast with error
# Simulate undersized plan → should error
# Simulate insufficient phases → should error
```

**Expected Duration**: 3-4 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(726): complete Phase 5 - Plan-Architect Agent Invocation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Validation, Testing, and Documentation
dependencies: [5]

**Objective**: Validate plans, create test suite, and update documentation

**Complexity**: Medium

**Tasks**:
- [ ] Invoke validate-plan.sh on created plan (file: .claude/commands/plan.md, lines 231-250)
- [ ] Parse validation report (JSON with warnings/errors)
- [ ] Display validation warnings to user (non-blocking)
- [ ] Fail-fast on validation errors (blocking)
- [ ] Create test suite (file: .claude/tests/test_plan_command.sh, NEW)
- [ ] Test argument parsing (quoted descriptions, multiple reports)
- [ ] Test absolute path validation (reject relative paths)
- [ ] Test feature analysis (complexity detection, keyword matching)
- [ ] Test research delegation (triggers, agent invocation, verification)
- [ ] Test standards discovery (CLAUDE.md detection, extraction)
- [ ] Test plan creation (verify file exists, size, phases, checkboxes)
- [ ] Test validation (metadata, standards, test phases, dependencies)
- [ ] Test error handling (missing files, agent failures, invalid inputs)
- [ ] Update plan-command-guide.md with usage examples (file: .claude/docs/guides/plan-command-guide.md)
- [ ] Add troubleshooting section (common errors, diagnostic steps)
- [ ] Update CLAUDE.md with command reference (file: CLAUDE.md)
- [ ] Add rollback procedure to implementation plans (template update)
- [ ] Run full test suite and verify all tests pass
- [ ] Verify command stays under 400 lines (no code transformation risk)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Run full test suite
.claude/tests/test_plan_command.sh

# Verify all test groups pass:
# - Argument parsing tests
# - Path validation tests
# - Feature analysis tests
# - Research delegation tests
# - Standards discovery tests
# - Plan creation tests
# - Validation tests
# - Error handling tests

# Manual integration tests
/plan "Add user authentication" # Full workflow
/plan "Migrate to microservices" report1.md report2.md # With research
/plan "Fix login bug" # Simple workflow (no research)
```

**Expected Duration**: 2-3 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(726): complete Phase 6 - Validation, Testing, and Documentation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- Test each function in isolation (argument parsing, feature analysis, standards discovery)
- Mock external dependencies (Task tool, file I/O)
- Verify error handling paths

### Integration Testing
- Test full command workflow end-to-end
- Verify agent invocation and verification checkpoints
- Test with real feature descriptions (10+ diverse examples)

### Regression Testing
- Test suite prevents behavioral regressions
- Verify agent structure compliance
- Check completion signal format
- Validate file size limits (<400 lines per agent)

### Test Suite Structure
```
.claude/tests/test_plan_command.sh
├─ Test Group 1: Argument Parsing
├─ Test Group 2: Path Validation
├─ Test Group 3: Feature Analysis
├─ Test Group 4: Research Delegation
├─ Test Group 5: Standards Discovery
├─ Test Group 6: Plan Creation
├─ Test Group 7: Validation
└─ Test Group 8: Error Handling
```

### Coverage Requirements
- 100% of critical paths (argument parsing, agent invocation, verification)
- 80% of error handling paths (missing files, invalid inputs)
- All agent behavioral requirements (from plan-architect.md)

## Documentation Requirements

### Command Guide Updates
- Update `/home/benjamin/.config/.claude/docs/guides/plan-command-guide.md` with:
  - Usage examples (simple features, complex features, with research reports)
  - Feature analysis criteria (complexity triggers, keyword matching)
  - Research delegation workflow
  - Plan validation process
  - Troubleshooting section

### CLAUDE.md Updates
- Add /plan command reference to command catalog
- Document research delegation triggers
- Document validation requirements

### Inline Documentation
- Comprehensive comments explaining patterns
- References to research reports for design rationale
- Examples of correct usage

### Template Updates
- Add rollback procedures to plan templates
- Document validation requirements
- Include behavioral injection examples

## Dependencies

### External Dependencies
- Claude AI API (Task tool, haiku-4 model)
- jq (JSON parsing)
- bash 4.0+ (associative arrays)

### Internal Dependencies
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` - Directory discovery
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` - State management
- `/home/benjamin/.config/.claude/lib/metadata-extraction.sh` - Report metadata
- `/home/benjamin/.config/.claude/lib/context-pruning.sh` - Context reduction
- `/home/benjamin/.config/.claude/lib/plan-core-bundle.sh` - Plan manipulation
- `/home/benjamin/.config/.claude/lib/complexity-utils.sh` - Complexity calculation
- `/home/benjamin/.config/.claude/agents/plan-architect.md` - Plan creation behavioral file
- `/home/benjamin/.config/.claude/agents/research-specialist.md` - Research behavioral file

### New Files to Create
- `/home/benjamin/.config/.claude/lib/validate-plan.sh` - Plan validation library
- `/home/benjamin/.config/.claude/tests/test_plan_command.sh` - Test suite

## Risk Management

### Technical Risks

**Risk 1: LLM Classification Unreliable**
- Mitigation: Implement fallback heuristic analysis if Task tool fails
- Fallback: Keyword matching + length-based complexity estimation

**Risk 2: Agent Failures**
- Mitigation: Fail-fast verification after every agent invocation
- Recovery: Clear error messages with diagnostic hints

**Risk 3: Code Transformation Bugs (400-line limit)**
- Mitigation: Keep command under 300 lines (100-line safety margin)
- Detection: Add file size check to test suite

**Risk 4: Subprocess Isolation Issues**
- Mitigation: Use single bash script execution (not multi-block coordination)
- Avoidance: Don't follow coordinate's multi-block pattern

**Risk 5: Path Calculation Errors**
- Mitigation: Pre-calculate all paths in command, verify absolute
- Validation: Entry point path validation (fail immediately)

### Process Risks

**Risk 1: Scope Creep**
- Mitigation: Follow research recommendations strictly
- Boundary: No multi-block coordination, no hierarchical supervision

**Risk 2: Integration Failures**
- Mitigation: Comprehensive integration testing with real feature descriptions
- Detection: Test suite runs full workflow end-to-end

### Rollback Procedure

If any phase fails or validation errors occur:

```bash
# Restore from backup (if changes were committed)
git log --oneline -10  # Find last good commit
git revert <commit-hash>

# Or reset to last stable state
git reset --hard <last-stable-commit>

# Verify restoration
git status
/plan --help  # Should display help text
```

**When to Rollback**:
- Validation fails in Phase N+1
- Tests fail after implementation
- Command exceeds 400 lines (code transformation risk)
- Agent invocation patterns break

## Notes

**Complexity Calculation Details**:
```
Score = (tasks × 1.0) + (phases × 5.0) + (hours × 0.5) + (dependencies × 2.0)
Score = (52 × 1.0) + (6 × 5.0) + (20 × 0.5) + (4 × 2.0)
Score = 52 + 30 + 10 + 8 = 100

Adjusted for research integration complexity: 100 × 1.275 = 127.5
```

**Why Level 0 Structure**:
- Complexity score 127.5 suggests Level 1 (threshold: 50-200)
- Starting with Level 0 per progressive planning best practice
- Can expand to Level 1 if implementation reveals need

**Expansion Hint**:
If implementation complexity increases during execution, consider using `/expand` to break phases into separate files for better organization.

**Design Rationale**:
This plan avoids coordinate's complexity (2,466 lines, 13 failed refactors, subprocess isolation constraints) and follows optimize-claude's robustness patterns (fail-fast verification, behavioral injection, library integration, lazy directory creation, comprehensive testing).
