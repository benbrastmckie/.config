# Plan Command Refactor Implementation Plan

## Metadata
- **Date**: 2025-11-16
- **Feature**: Refactor /plan command with robust architecture patterns
- **Scope**: Transform pseudocode template to production-grade executable command
- **Estimated Phases**: 8
- **Estimated Hours**: 17-21
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

**Standards Compliance Requirements** (from .claude/docs/):

5. **Command Architecture Standards**: Commands MUST use imperative language (YOU MUST, EXECUTE NOW, MANDATORY) for critical operations. Standard 14 requires executable/documentation separation: executable target <250 lines (simple commands), comprehensive guide unlimited. Standard 11 requires imperative agent invocation with explicit execution markers.

6. **Behavioral Injection Pattern**: Path pre-calculation BEFORE agent invocation, context injection via file content (not SlashCommand), metadata-only passing (95% context reduction). NO command-to-command invocation via SlashCommand. Standard 12 requires structural/behavioral content separation.

7. **Library Sourcing Order** (Standard 15): Source state machine foundation FIRST, then error handling BEFORE verification checkpoints. Source guards enable safe re-sourcing. Specific order: workflow-state-machine.sh → state-persistence.sh → error-handling.sh → verification-helpers.sh.

8. **Testing Protocols**: Test location `.claude/tests/`, pattern `test_*.sh`, coverage ≥80% for modified code. Test isolation using `CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"` override. Cleanup traps mandatory.

**Recommended Approach**:
- Follow optimize-claude's fail-fast verification pattern, NOT coordinate's complexity
- Apply Standard 14: Separate executable (<250 lines) from comprehensive guide
- Use imperative language (EXECUTE NOW, YOU MUST) for all critical operations (Standard 0)
- Implement behavioral injection with mandatory file creation protocol (Standard 11)
- Leverage existing libraries with correct sourcing order (Standard 15)
- Add comprehensive validation with validate-plan.sh
- Maintain absolute path discipline with CLAUDE_PROJECT_DIR detection (Standard 13)
- Apply metadata-only passing for 95% context reduction
- Support progressive expansion (all plans start Level 0, expand on-demand)

## Success Criteria

- [ ] Plan command executes from pseudocode template to working implementation
- [ ] **Standard 14 Compliance**: Executable command <250 lines, comprehensive guide exists separately
- [ ] **Standard 0 Compliance**: Imperative language (EXECUTE NOW, YOU MUST) for all critical operations
- [ ] **Standard 11 Compliance**: Imperative agent invocation with explicit execution markers, no code-fenced examples
- [ ] **Standard 12 Compliance**: Structural templates inline, behavioral content referenced from agent files
- [ ] **Standard 13 Compliance**: Use CLAUDE_PROJECT_DIR for project detection, never BASH_SOURCE[0]
- [ ] **Standard 15 Compliance**: Library sourcing order enforced (state machine → persistence → error handling)
- [ ] **Standard 16 Compliance**: All critical function return codes verified with `if ! function; then` checks
- [ ] Feature description analysis uses LLM classification (haiku-4 model) or heuristic fallback
- [ ] Research delegation triggers automatically for complexity ≥7 or architecture keywords
- [ ] Plan-architect agent creates plans with mandatory verification checkpoints
- [ ] All operations use absolute paths (verified at entry point)
- [ ] Validation confirms plans meet CLAUDE.md standards compliance
- [ ] Test suite covers agent structure, completion signals, behavioral compliance (≥80% coverage)
- [ ] Test isolation using CLAUDE_SPECS_ROOT override, cleanup traps mandatory
- [ ] Idempotent operations allow safe re-runs
- [ ] Error messages include context (agent name, expected artifact, diagnostic hints)
- [ ] Plans include rollback procedures
- [ ] Documentation guide updated with usage examples and troubleshooting
- [ ] Automated validation passes: validate_executable_doc_separation.sh
- [ ] No anti-patterns: documentation-only YAML blocks, command-to-command invocation, inline duplication

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
  ├─ Phase 6: Plan Validation
  │   ├─ Source validate-plan.sh (NEW LIBRARY)
  │   ├─ Validate metadata completeness
  │   ├─ Validate standards compliance
  │   ├─ Validate test phases present
  │   ├─ Validate phase dependencies valid
  │   └─ Generate validation report
  │
  └─ Phase 7: Expansion Evaluation (Conditional)
      ├─ Invoke complexity-estimator agent to analyze all phases
      ├─ Determine if any phases meet expansion threshold (complexity ≥8)
      ├─ If no expansion needed: present plan outline and complete
      └─ If expansion needed: invoke plan-structure-manager agents in parallel
          ├─ Use single-message invocation for parallelism
          ├─ Verify expanded phase files created
          └─ Update plan metadata (Level 0→1, Expanded Phases list)
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

**5. Expansion Evaluation (Post-Validation)**
- Invoke complexity-estimator agent to analyze all phases in created plan
- Agent evaluates each phase using context-aware analysis (not just task count)
- Complexity threshold: ≥8 triggers expansion recommendation
- Decision logic:
  - **No phases ≥8**: Present basic plan outline (phase names, objectives, paths) and complete
  - **One or more phases ≥8**: Invoke plan-structure-manager agents in parallel
- Parallel expansion: Use single-message invocation for 60-80% time savings
- Verify expanded phase files created at pre-calculated paths (fail-fast)
- Update plan metadata: Structure Level 0→1, Expanded Phases list
- Follows /expand command patterns (see .claude/commands/expand.md)

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

### Phase 0: Orchestrator Initialization and Path Pre-Calculation
dependencies: []

**Objective**: Establish orchestrator role, detect project directory, source libraries in correct order, pre-calculate all artifact paths before any agent invocations

**Complexity**: Low

**Tasks**:
- [x] **Standard 13**: YOU MUST detect project directory using CLAUDE_PROJECT_DIR environment variable (git-based detection, never BASH_SOURCE[0])
- [x] **Standard 15**: YOU MUST source libraries in dependency order: workflow-state-machine.sh → state-persistence.sh → error-handling.sh → verification-helpers.sh
- [x] **Standard 16**: YOU MUST verify library sourcing with return code checks: `if ! source lib 2>&1; then handle_error; fi`
- [x] **EXECUTE NOW**: Initialize workflow state using init_workflow_state("plan_$$")
- [x] **EXECUTE NOW**: Pre-calculate topic directory path using get_or_create_topic_dir()
- [x] **EXECUTE NOW**: Pre-calculate plan output path before any agent invocations (behavioral injection requirement)
- [x] **EXECUTE NOW**: Pre-calculate potential report paths array (used if research delegation required)
- [x] **Standard 0**: YOU MUST export all pre-calculated paths to workflow state for use in subsequent phases
- [x] **Standard 0**: MANDATORY VERIFICATION - verify all paths are absolute using absolute path validation

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test path pre-calculation
/plan "test feature" # Should calculate paths in Phase 0
# Verify: All paths are absolute
# Verify: Workflow state initialized
# Verify: Libraries sourced correctly
```

**Expected Duration**: 30-45 minutes

**Phase 0 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] All pre-calculated paths are absolute
- [x] Workflow state initialized successfully
- [x] Git commit created: `feat(726): complete Phase 0 - Orchestrator Initialization`
- [x] Update this plan file with phase completion status

### Phase 1: Core Command Structure
dependencies: [0]

**Objective**: Create executable command framework with argument parsing and validation

**Complexity**: Medium

**Tasks**:
- [x] **EXECUTE NOW**: CREATE file `/home/benjamin/.config/.claude/commands/plan.md` with executable bash blocks targeting <250 lines (Standard 14)
- [x] **Standard 14 Monitoring**: YOU MUST track line count throughout implementation, extract documentation to guide file if approaching 200 lines
- [x] **YOU MUST**: Implement argument parsing with quoted multi-word support (lines 17-39)
- [x] **YOU MUST**: Add absolute path validation for all input paths at entry point (fail-fast if relative paths detected)
- [x] **YOU MUST**: Add help text display for --help flag (concise inline, comprehensive in guide file)
- [x] **Standard 0**: YOU MUST use imperative language for error handling with MANDATORY VERIFICATION after every critical operation
- [x] **EXECUTE NOW**: Add set +H to disable history expansion (prevent bad substitution errors)
- [x] **EXECUTE NOW**: Implement error context enrichment providing agent name, expected artifact, diagnostic hints in all error messages
- [x] **YOU MUST**: Add comprehensive inline comments explaining patterns with explicit Standard N references for design rationale

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
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
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(726): complete Phase 1 - Core Command Structure`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 2: Feature Analysis (LLM Classification)
dependencies: [0, 1]

**Objective**: Implement intelligent feature analysis using LLM classification pattern

**Complexity**: High

**Tasks**:
- [ ] **EXECUTE NOW**: CREATE analyze_feature_description() function using Task tool (file: .claude/commands/plan.md, lines 40-85)
- [ ] **Standard 11**: YOU MUST use imperative agent invocation with explicit execution marker: "EXECUTE NOW: USE the Task tool"
- [ ] **Standard 11**: YOU MUST NOT include code-fenced Task examples in command file (prevents priming effect blocking actual execution)
- [ ] **YOU MUST**: Use haiku-4 model for fast classification (<5 seconds)
- [ ] **EXECUTE NOW**: Design classification prompt extracting complexity, scope, keywords, suggested template
- [ ] **YOU MUST**: Return structured JSON: {estimated_complexity, suggested_phases, template_type, keywords, requires_research}
- [ ] **EXECUTE NOW**: Implement complexity trigger logic: ≥7 OR keywords (integrate, migrate, refactor, architecture)
- [ ] **Standard 16**: YOU MUST verify Task tool return code: `if ! result=$(analyze_feature 2>&1); then fallback_heuristic; fi`
- [ ] **EXECUTE NOW**: Implement fallback heuristic algorithm: (1) Keyword scoring (architecture/refactor/migrate=8, implement/create=5, fix/adjust=3), (2) Length scoring (<10 words=0, 10-20=1, 20-40=2, >40=3), (3) Combined score triggers research if ≥7
- [ ] **YOU MUST**: Cache analysis results to state file (avoid re-analysis on retries)
- [ ] **Standard 16**: YOU MUST verify cache write return code before proceeding
- [ ] **YOU MUST**: Verify JSON schema matches downstream expectations using jq validation
- [ ] **EXECUTE NOW**: Add logging with emit_progress "Analyzing feature complexity..."
- [ ] **YOU MUST**: Document classification criteria in inline comments with explicit Standard N references

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
dependencies: [0, 2]

**Objective**: Implement conditional research delegation for complex features

**Complexity**: High

**Tasks**:
- [ ] **EXECUTE NOW**: IMPLEMENT research delegation trigger logic (file: .claude/commands/plan.md, lines 86-145)
- [ ] **YOU MUST**: Generate 1-4 research topics from feature description (based on complexity analysis from Phase 2)
- [ ] **Behavioral Injection - CRITICAL**: YOU MUST pre-calculate ALL report paths in Phase 0 or this phase BEFORE any agent invocation (agents receive paths, never calculate them)
- [ ] **Standard 16**: YOU MUST verify path pre-calculation return code before proceeding
- [ ] **EXECUTE NOW**: Ensure report directories exist using ensure_artifact_directory() (lazy creation, 80% reduction in mkdir calls)
- [ ] **Standard 12 - NO DUPLICATION**: YOU MUST reference agent behavioral file ONLY, never duplicate procedures. Use exact pattern: "Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md"
- [ ] **Standard 12 Compliance Example**: Task prompt format MUST be: "Read and follow: .claude/agents/research-specialist.md\n\n**Workflow-Specific Context**:\n- Research Topic: $TOPIC\n- Report Path: $REPORT_PATH (pre-calculated)\n- Standards: $STANDARDS_PATH\n- Complexity: $LEVEL\n\nExecute per behavioral guidelines. Return: REPORT_CREATED: $REPORT_PATH"
- [ ] **Standard 11**: YOU MUST use imperative invocation marker: "EXECUTE NOW: USE the Task tool with subagent_type=general-purpose"
- [ ] **Standard 11**: YOU MUST NOT include code-fenced Task examples in command file (creates priming effect preventing execution)
- [ ] **EXECUTE NOW**: Implement parallel agent invocation (1-4 agents based on RESEARCH_COMPLEXITY, 40-60% time savings via single-message multi-Task pattern)
- [ ] **Standard 0 - MANDATORY**: YOU MUST verify after EACH agent completes: `if [ ! -f "$REPORT_PATH" ]; then echo "CRITICAL: Agent research-specialist failed to create: $REPORT_PATH"; exit 1; fi`
- [ ] **Design Decision - Fail-Fast**: Verification FAILS IMMEDIATELY on missing files, NO placeholder creation by orchestrator (Standard 0 clarification: orchestrators never create agent artifacts)
- [ ] **Standard 16**: YOU MUST verify extract_report_metadata() return code: `if ! metadata=$(extract_report_metadata "$REPORT_PATH" 2>&1); then warn_and_continue; fi`
- [ ] **EXECUTE NOW**: Extract metadata from reports using extract_report_metadata() (250-token summaries, 95% context reduction)
- [ ] **YOU MUST**: Cache metadata to state file for plan-architect context injection
- [ ] **Standard 16**: YOU MUST verify state file write return code
- [ ] **EXECUTE NOW**: Add timeout handling (5-minute default per agent, configurable)
- [ ] **YOU MUST**: Document graceful degradation strategy: if agent fails verification, log error with full context (agent name, expected path, diagnostic), continue with partial research, warn user at completion

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
dependencies: [0, 1]

**Objective**: Implement standards discovery and create validate-plan.sh library

**Complexity**: Medium

**Tasks**:
- [ ] **EXECUTE NOW**: IMPLEMENT standards discovery in command (file: .claude/commands/plan.md, lines 146-175)
- [ ] **Standard 15**: YOU MUST source unified-location-detection.sh (if not already sourced in Phase 0, verify sourcing order)
- [ ] **Standard 16**: YOU MUST verify library sourcing: `if ! source unified-location-detection.sh 2>&1; then fail_fast; fi`
- [ ] **Standard 13**: YOU MUST use CLAUDE_PROJECT_DIR for upward CLAUDE.md search in ALL path operations (never BASH_SOURCE[0])
- [ ] **EXECUTE NOW**: Extract code standards from CLAUDE.md (indentation, naming, language-specific conventions)
- [ ] **EXECUTE NOW**: Extract testing protocols (test commands, coverage requirements ≥80%, test isolation standards)
- [ ] **EXECUTE NOW**: Extract documentation policy (README requirements, timeless writing standards, format compliance)
- [ ] **YOU MUST**: Cache extracted standards to state file (avoid re-extraction on retries)
- [ ] **Standard 16**: YOU MUST verify cache write return code
- [ ] **EXECUTE NOW**: CREATE validate-plan.sh library (file: .claude/lib/validate-plan.sh, NEW)
- [ ] **Standard 16**: YOU MUST design ALL validation functions to return exit codes: 0=success, 1=failure, never silent failures
- [ ] **EXECUTE NOW**: IMPLEMENT validate_metadata() - check 8 required fields present (Date, Feature, Scope, Phases, Hours, Structure Level, Complexity, Standards)
- [ ] **EXECUTE NOW**: IMPLEMENT validate_standards_compliance() - verify CLAUDE.md path referenced, standards sections present, Standard N references included
- [ ] **EXECUTE NOW**: IMPLEMENT validate_test_phases() - check test phases exist if Testing Protocols defined (≥80% coverage requirement)
- [ ] **EXECUTE NOW**: IMPLEMENT validate_documentation_tasks() - check docs tasks exist if Documentation Policy defined
- [ ] **EXECUTE NOW**: IMPLEMENT validate_phase_dependencies() - check no circular dependencies using Kahn's algorithm, no forward references, no self-dependencies
- [ ] **EXECUTE NOW**: ADD generate_validation_report() - return JSON with categorized warnings/errors, severity levels, fix suggestions
- [ ] **Standard 0**: YOU MUST add comprehensive error messages with full context (field name, expected value, actual value, fix suggestion, related standard)
- [ ] **YOU MUST**: Document library functions with usage examples, return code contracts, standards compliance notes

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
dependencies: [0, 2, 3, 4]

**Objective**: Implement plan creation via plan-architect agent with behavioral injection

**Complexity**: Medium

**Tasks**:
- [ ] **Behavioral Injection - CRITICAL**: Plan path MUST be pre-calculated in Phase 0 (file: .claude/commands/plan.md, lines 176-230)
- [ ] **Standard 16**: YOU MUST verify Phase 0 path pre-calculation before proceeding: `if [ -z "$PLAN_PATH" ]; then fail_fast; fi`
- [ ] **EXECUTE NOW**: Ensure plan parent directory exists using ensure_artifact_directory() (lazy creation pattern)
- [ ] **Standard 12 - NO DUPLICATION**: YOU MUST reference agent behavioral file ONLY: "Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md"
- [ ] **Standard 12 Compliance Example**: Task prompt MUST be: "Read and follow: .claude/agents/plan-architect.md\n\n**Workflow-Specific Context**:\n- Feature Description: $FEATURE\n- Report Paths: ${REPORT_PATHS[@]} (metadata extracted in Phase 3)\n- Standards Path: $STANDARDS_PATH\n- Output Path: $PLAN_PATH (pre-calculated)\n- Complexity: $COMPLEXITY\n- Suggested Phases: $SUGGESTED_PHASES\n\nExecute per behavioral guidelines. Return: PLAN_CREATED: $PLAN_PATH"
- [ ] **YOU MUST**: Include ALL research report paths in metadata (NOT full content - use cached metadata from Phase 3 for 95% context reduction)
- [ ] **YOU MUST**: Pass complexity score and suggested phases from Phase 2 feature analysis
- [ ] **Standard 11**: YOU MUST use imperative invocation marker: "EXECUTE NOW: USE the Task tool with subagent_type=general-purpose"
- [ ] **Standard 11**: YOU MUST NOT include code-fenced Task examples in command file (prevents priming effect blocking execution)
- [ ] **EXECUTE NOW**: Set timeout to 10 minutes (comprehensive planning with research integration)
- [ ] **YOU MUST**: Parse agent return signal with exact format: PLAN_CREATED: [absolute-path]
- [ ] **Standard 0 - MANDATORY**: YOU MUST verify immediately: `if [ ! -f "$PLAN_PATH" ]; then echo "CRITICAL: Agent plan-architect failed to create: $PLAN_PATH. Check agent output above for errors."; exit 1; fi`
- [ ] **EXECUTE NOW**: Verify file size ≥2000 bytes (comprehensive plan structural check)
- [ ] **EXECUTE NOW**: Verify phase count ≥3 using: `PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH"); if [ "$PHASE_COUNT" -lt 3 ]; then fail_fast; fi`
- [ ] **EXECUTE NOW**: Verify checkbox count ≥10 for /implement compatibility: `CHECKBOX_COUNT=$(grep -c "\[ \]" "$PLAN_PATH"); if [ "$CHECKBOX_COUNT" -lt 10 ]; then warn; fi`
- [ ] **Standard 16**: YOU MUST verify metadata extraction: `if ! metadata=$(extract_plan_metadata "$PLAN_PATH" 2>&1); then echo "WARNING: Metadata extraction failed, continuing..."; fi`
- [ ] **EXECUTE NOW**: Extract plan metadata using extract_plan_metadata()
- [ ] **YOU MUST**: Cache plan metadata to state file
- [ ] **Standard 16**: YOU MUST verify cache write return code
- [ ] **Standard 0**: YOU MUST add error context enrichment to ALL failure paths (agent name: plan-architect, expected artifact: $PLAN_PATH, diagnostic: "Check agent output above for STEP failures")

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

### Phase 6: Plan Validation
dependencies: [0, 5]

**Objective**: Validate created plan against project standards and completeness requirements

**Complexity**: Low

**Tasks**:
- [ ] **Standard 15**: YOU MUST source validate-plan.sh library (if not sourced in Phase 0, verify dependency order)
- [ ] **Standard 16**: YOU MUST verify library sourcing: `if ! source .claude/lib/validate-plan.sh 2>&1; then fail_fast "validate-plan.sh library not found"; fi`
- [ ] **EXECUTE NOW**: Invoke validate_plan() on created plan (file: .claude/commands/plan.md, lines 231-250)
- [ ] **Standard 16**: YOU MUST verify validation return code: `if ! report=$(validate_plan "$PLAN_PATH" "$STANDARDS_FILE" 2>&1); then echo "CRITICAL: Plan validation failed"; exit 1; fi`
- [ ] **EXECUTE NOW**: Parse validation report JSON using jq: `WARNINGS=$(echo "$report" | jq -r '.warnings | length'); ERRORS=$(echo "$report" | jq -r '.errors | length')`
- [ ] **YOU MUST**: Display validation warnings to user (non-blocking, informational with severity levels)
- [ ] **Standard 0 - MANDATORY**: YOU MUST fail-fast on validation errors: `if [ "$ERROR_COUNT" -gt 0 ]; then echo "Plan validation found $ERROR_COUNT critical errors. Fix before proceeding."; exit 1; fi`
- [ ] **EXECUTE NOW**: Verify metadata completeness (8 required fields: Date, Feature, Scope, Phases, Hours, Structure Level, Complexity, Standards)
- [ ] **EXECUTE NOW**: Verify standards references (CLAUDE.md path present, Standard N references included, code standards section exists, testing protocols referenced)
- [ ] **EXECUTE NOW**: Verify test phases present if Testing Protocols defined in CLAUDE.md (coverage target ≥80% documented)
- [ ] **EXECUTE NOW**: Verify documentation tasks exist if Documentation Policy defined (timeless writing compliance, README requirements)
- [ ] **EXECUTE NOW**: Validate phase dependencies using Kahn's algorithm (no circular deps, no forward refs, no self-deps)
- [ ] **Standard 14 - CRITICAL**: YOU MUST check executable file size: `LINES=$(wc -l < .claude/commands/plan.md); if [ "$LINES" -gt 250 ]; then echo "WARNING: Executable exceeds 250-line target ($LINES lines). Extract documentation to guide file."; fi`
- [ ] **EXECUTE NOW**: Generate validation report summary for user displaying warning count, error count, specific field issues with fix suggestions

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Expected Duration**: 30-45 minutes

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Validation report generated
- [ ] Git commit created: `feat(726): complete Phase 6 - Plan Validation`
- [ ] Update this plan file with phase completion status

### Phase 7: Expansion Evaluation (Conditional)
dependencies: [0, 6]

**Objective**: Evaluate if plan requires phase expansion and execute parallel expansion if needed

**Complexity**: Medium

**Tasks**:
- [ ] **Standard 12 - NO DUPLICATION**: YOU MUST reference agent behavioral file ONLY: "Read and follow ALL behavioral guidelines from: .claude/agents/complexity-estimator.md"
- [ ] **Standard 11**: YOU MUST use imperative invocation: "EXECUTE NOW: USE the Task tool with subagent_type=general-purpose"
- [ ] **Standard 12 Compliance**: Task prompt MUST be: "Read and follow: .claude/agents/complexity-estimator.md\n\n**Workflow-Specific Context**:\n- Plan Path: $PLAN_PATH\n\nExecute per behavioral guidelines. Return: COMPLEXITY_ANALYSIS: {results}"
- [ ] **EXECUTE NOW**: Invoke complexity-estimator agent to analyze all phases in created plan (file: .claude/commands/plan.md, NEW section)
- [ ] **YOU MUST**: Agent evaluates each phase using context-aware analysis (task count, dependency complexity, technical depth, NOT just line count)
- [ ] **EXECUTE NOW**: Determine if any phases meet expansion threshold (complexity ≥8 per Adaptive Planning Configuration standards)
- [ ] **Conditional Logic**: If no phases ≥8, present basic plan outline (phase names, objectives, file path) and complete command
- [ ] **Behavioral Injection - CRITICAL**: If expansion needed, YOU MUST pre-calculate ALL expanded phase file paths BEFORE invoking plan-structure-manager agents
- [ ] **Standard 16**: YOU MUST verify path pre-calculation return codes
- [ ] **Standard 12 - NO DUPLICATION**: YOU MUST reference plan-structure-manager agent file ONLY: "Read and follow ALL behavioral guidelines from: .claude/agents/plan-structure-manager.md"
- [ ] **Standard 12 Compliance**: Task prompt format: "Read and follow: .claude/agents/plan-structure-manager.md\n\n**Workflow-Specific Context**:\n- Plan Path: $PLAN_PATH\n- Phase Number: $PHASE_NUM\n- Expanded Phase File: $PHASE_FILE (pre-calculated)\n\nExecute per behavioral guidelines. Return: PHASE_EXPANDED: $PHASE_FILE"
- [ ] **EXECUTE NOW**: Invoke plan-structure-manager agents in parallel for flagged phases using single-message multi-Task pattern (40-60% time savings)
- [ ] **Standard 0 - MANDATORY**: YOU MUST verify EACH expanded phase: `if [ ! -f "$PHASE_FILE" ]; then echo "CRITICAL: Agent plan-structure-manager failed to create: $PHASE_FILE"; exit 1; fi`
- [ ] **EXECUTE NOW**: Update plan metadata section with Structure Level (0→1) and Expanded Phases list
- [ ] **YOU MUST**: Follow /expand command patterns for consistency (reference .claude/commands/expand.md for structural templates)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Expected Duration**: 10-30 minutes (conditional on complexity analysis)

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Complexity analysis complete
- [ ] Expansion decision made and executed (if needed)
- [ ] Git commit created: `feat(726): complete Phase 7 - Expansion Evaluation`
- [ ] Update this plan file with phase completion status

## Testing Requirements (Per Testing Protocols)

### Test Location and Naming
- **Test file**: `/home/benjamin/.config/.claude/tests/test_plan_command.sh`
- **Pattern**: Follow `test_*.sh` convention
- **Coverage target**: ≥80% for all modified code

### Test Isolation
- Use `CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"` environment variable override
- Cleanup trap: `trap cleanup EXIT` to remove test artifacts
- Pre-test validation: Verify empty directory before tests
- Post-test validation: Verify no production pollution

### Test Cases Required
1. **Argument Parsing Tests**:
   - Single-word feature description
   - Multi-word quoted feature description
   - Absolute path validation (reject relative paths)
   - Help flag display

2. **Feature Analysis Tests**:
   - Low complexity (≤6): no research delegation
   - High complexity (≥7): research delegation triggered
   - Architecture keywords: research delegation triggered
   - Task tool failure: fallback to heuristic analysis

3. **Standards Compliance Tests**:
   - Library sourcing order verification
   - CLAUDE_PROJECT_DIR detection (not BASH_SOURCE)
   - Return code verification for critical functions
   - Imperative language pattern validation

4. **Agent Invocation Tests**:
   - Research agents: verify report files created
   - Plan-architect: verify plan file created
   - Complexity-estimator: verify phase analysis
   - Parallel invocation: verify time savings

5. **Validation Tests**:
   - Metadata completeness (8 required fields)
   - Standards compliance (CLAUDE.md referenced)
   - Phase dependency validation (no circular deps)

6. **Integration Tests**:
   - End-to-end: feature description → plan created
   - With research reports: verify metadata extracted
   - Expansion evaluation: verify conditional expansion

### Automated Validation Scripts
- Run `validate_executable_doc_separation.sh` to verify:
  - Executable file size <250 lines (Standard 14)
  - Guide file exists and is comprehensive
  - Cross-references bidirectional

- Run `.claude/lib/validate-agent-invocation-pattern.sh` to verify:
  - Imperative patterns present (EXECUTE NOW, YOU MUST)
  - No YAML/JSON wrappers around Task invocations
  - No code-fenced Task examples

## Documentation Requirements

### Command Guide Updates (Standard 14)
- Comprehensive guide exists: `/home/benjamin/.config/.claude/docs/guides/plan-command-guide.md`
- Update with:
  - Usage examples (simple features, complex features, with research reports)
  - Feature analysis criteria (complexity triggers, keyword matching)
  - Research delegation workflow
  - Plan validation process
  - Standards compliance requirements
  - Troubleshooting section
- Bidirectional cross-reference: executable → guide, guide → executable

### CLAUDE.md Updates
- Add /plan command reference to command catalog
- Document research delegation triggers
- Document validation requirements
- Reference standards compliance (Standards 0, 11, 12, 13, 14, 15, 16)

### Inline Documentation
- Comprehensive comments explaining patterns
- References to standards (Standard N) for design rationale
- References to research reports for architectural decisions
- Examples of correct usage (NOT code-fenced Task examples)

### Agent Behavioral Files
- Ensure agent files exist:
  - `.claude/agents/research-specialist.md`
  - `.claude/agents/plan-architect.md`
  - `.claude/agents/complexity-estimator.md`
  - `.claude/agents/plan-structure-manager.md`
- No inline duplication (reference files, don't duplicate procedures)

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

## Revision History

- **2025-11-16** (Revision 5): Critical standards compliance gaps addressed based on gap analysis research. Key changes: (1) Added Phase 0 for orchestrator pattern compliance - establishes orchestrator role, pre-calculates ALL artifact paths before agent invocations, sources libraries in correct order per Standard 15. (2) Transformed all task language to imperative (EXECUTE NOW, YOU MUST) per Standards 0 and 11. (3) Added explicit Standard 12 compliance examples showing behavioral injection pattern: "Read and follow: .claude/agents/[name].md" with metadata-only context, NO inline procedure duplication. (4) Added Standard 14 executable size monitoring to Phase 6 validation (<250 line target). (5) Expanded Standard 16 application to ALL critical functions, not just library sourcing. (6) Added fail-fast design decision documentation (no placeholder creation by orchestrator). (7) Added fallback heuristic algorithm specification for Phase 2 LLM classification. (8) Updated all phase dependencies to reference Phase 0. (9) Increased estimated phases 7→8, hours 16-20→17-21. This revision eliminates the most critical compliance gaps: behavioral content duplication (Gap 1), missing imperative execution markers (Gap 2), and missing Phase 0 for orchestrator pattern (Gap 7).
- **2025-11-16** (Revision 4): Standards compliance integration. Researched comprehensive .claude/docs/ standards and integrated compliance requirements throughout all phases. Key additions: (1) Research Summary expanded with 8 standards compliance requirements including Standard 14 (executable/doc separation <250 lines), Standard 0 (imperative language), Standards 11-12 (behavioral injection), Standard 15 (library sourcing order), Standard 16 (return code verification). (2) Success Criteria expanded with explicit standard compliance checkpoints and anti-pattern prevention. (3) Phase tasks updated with standard-specific implementation requirements (Standard N tags). (4) New Testing Requirements section added with test isolation, coverage targets (≥80%), and automated validation scripts. (5) Documentation Requirements expanded with Standard 14 compliance (bidirectional cross-references, no inline agent duplication). This revision ensures implementation will comply with all established architectural standards, avoiding anti-patterns like documentation-only YAML blocks, command-to-command invocation, and code-fenced Task examples.
- **2025-11-16** (Revision 3): Removed Phase 8 (Testing and Documentation). Recognized that /plan command only creates plans, not implements them. Testing and documentation are concerns for the implementation phase (when someone uses /implement), not plan creation phase. Reduced from 8 to 7 phases, estimated hours 16-20. The command now completes after Phase 7 (Expansion Evaluation), presenting either a basic plan outline or an expanded plan structure.
- **2025-11-16** (Revision 2): Restructured phases to separate concerns. Split original Phase 6 into three distinct phases: Phase 6 (Plan Validation - validates plan against standards), Phase 7 (Expansion Evaluation - conditionally expands complex phases using complexity-estimator agent), and Phase 8 (Testing and Documentation). This separation improves clarity, allows validation to complete before expansion decisions, and makes expansion truly optional based on complexity analysis. Total phases increased from 6 to 8, estimated hours 21-26.
- **2025-11-16** (Revision 1): Added expansion evaluation logic to Phase 6. After plan validation, command will invoke complexity-estimator agent to analyze all phases for expansion needs (threshold: complexity ≥8). If no expansion needed, presents basic plan outline and completes. If expansion needed, invokes plan-structure-manager agents in parallel for flagged phases. This follows patterns from /expand command to ensure complex phases receive detailed specifications.
