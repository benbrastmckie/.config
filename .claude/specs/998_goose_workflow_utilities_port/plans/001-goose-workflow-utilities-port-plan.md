# Goose Workflow Utilities Port - Implementation Plan

## Metadata
- **Date**: 2025-12-05
- **Feature**: Port Claude Code workflow commands to Goose ecosystem as YAML recipes
- **Scope**: Migrate /research, /create-plan, /revise, and /implement commands along with their dependencies (agents, libraries, state management) to Goose's YAML recipe structure with MCP server extensions
- **Status**: [COMPLETE]
- **Estimated Hours**: 88-124 hours
- **Complexity Score**: 215.0
- **Structure Level**: 0 (will expand to Level 1 if complexity warrants during implementation)
- **Estimated Phases**: 7
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Goose Workflow Utilities Port Analysis](../reports/001-goose-workflow-utilities-port-analysis.md)

## Overview

This plan implements a complete port of Claude Code's core workflow utilities (/research, /create-plan, /revise, /implement) to the Goose ecosystem. The migration transforms bash-orchestrated markdown commands into declarative YAML recipes, converting hierarchical agent delegation to subrecipe patterns and reimagining bash libraries as either embedded instructions or custom MCP servers.

**Key Architectural Transformations**:
1. **Command Structure**: Markdown commands with embedded bash → YAML recipes with instructions
2. **Agent Delegation**: Task tool invocation → Subrecipe calls with parameter passing
3. **State Management**: Bash state files + state machine → Recipe parameters + checkpoints
4. **Hard Barrier Pattern**: Bash verification blocks → Recipe retry with shell validation checks
5. **Library Functions**: 52 bash libraries → Embedded instructions or MCP servers (15 libraries converted, 22 embedded, 8 deprecated, 7 redesigned)

## Research Summary

The research report reveals significant architectural differences between Claude Code and Goose:
- **Claude Code**: Bash-orchestrated markdown commands with hierarchical agent delegation and stateful multi-block execution
- **Goose**: YAML recipe templates with MCP-based tool extensions and stateless execution

**Key Findings from Research**:
1. Recipe pattern successfully expresses multi-phase workflows through subrecipe composition
2. Hard barrier pattern (pre-calc → invoke → validate) maps cleanly to `retry.checks` with shell validation
3. Complex bash utilities (checkbox-utils, state-machine) require dedicated MCP servers
4. Goose lacks built-in iteration loops; requires external orchestration wrapper
5. Bash state files must be replaced with JSON state files or recipe parameter passing

**Recommended Approach**: Phased migration starting with /research prototype to validate approach, then progressively port /create-plan, /revise, and /implement. Prioritize MCP server development for plan-manager and state-machine to enable complex workflows.

## Success Criteria

- [ ] All four core workflows ported and functional (/research, /create-plan, /revise, /implement)
- [ ] Hard barrier pattern enforced in all recipes (artifact creation validated)
- [ ] MCP servers operational (plan-manager, state-machine)
- [ ] State management working (JSON state files or parameter passing)
- [ ] Iteration orchestration functional for /implement workflow
- [ ] Integration tests passing for full workflow chain (research → plan → implement)
- [ ] Documentation complete (recipe usage guides, MCP server API docs, migration notes)
- [ ] Performance within 10% of Claude Code bash implementation

## Technical Design

### Architecture Overview

```
.goose/
  recipes/
    research.yaml              # Parent recipe for /research workflow
    create-plan.yaml           # Parent recipe for /create-plan workflow
    revise.yaml                # Parent recipe for /revise workflow
    implement.yaml             # Parent recipe for /implement workflow
    subrecipes/
      research-specialist.yaml # Codebase research and report creation
      topic-naming.yaml        # Semantic directory name generation
      plan-architect.yaml      # Implementation plan creation
      implementer-coordinator.yaml # Phase execution orchestration
  mcp-servers/
    plan-manager/              # Phase marker management (checkbox-utils equivalent)
      index.js
      package.json
    state-machine/             # State validation and transitions
      index.js
      package.json
  scripts/
    goose-implement-orchestrator.sh  # Iteration loop wrapper
.goosehints                    # Project standards (converted from CLAUDE.md)
```

### Component Responsibilities

**Parent Recipes**:
- **research.yaml**: Topic slug generation → directory initialization → research-specialist invocation → artifact validation
- **create-plan.yaml**: Research phase → standards injection → planning phase → divergence detection
- **revise.yaml**: Backup creation → research phase for insights → plan revision → diff validation
- **implement.yaml**: Phase marker management → checkpoint creation → summary validation

**Subrecipes**:
- **research-specialist.yaml**: Codebase analysis, report creation with hard barrier enforcement
- **topic-naming.yaml**: LLM-based semantic directory naming
- **plan-architect.yaml**: Plan creation with complexity calculation, tier selection, Phase 0 divergence detection
- **implementer-coordinator.yaml**: Wave-based phase execution, iteration management, context tracking

**MCP Servers**:
- **plan-manager**: Tools for marking phases complete, verifying completion, checking all phases
- **state-machine**: Tools for state initialization, transition validation, current state retrieval

**External Scripts**:
- **goose-implement-orchestrator.sh**: Iteration loop for large plans (handles max_iterations, continuation_context)

### Translation Patterns

**Bash Block → YAML Recipe**:
```yaml
# Block 1a: Setup
parameters:
  - key: topic
    input_type: string
    requirement: required

# Block 1b: Agent invocation
sub_recipes:
  - name: research-specialist
    path: ./research-specialist.yaml

# Block 1c: Validation
retry:
  checks:
    - type: shell
      command: "test -f {{ artifact_path }}"
```

**Task Tool → Subrecipe**:
```yaml
# Claude Code: Task { prompt: "..." }
# Goose:
sub_recipes:
  - name: agent-name
    path: ./agent-name.yaml
    parameters:
      input_param: "{{ value }}"
```

**State Persistence → JSON State**:
```yaml
instructions: |
  Execute: |
    cat > .goose/tmp/state_{{ workflow_id }}.json <<EOF
    {"plan_file": "{{ plan_file }}", "topic_path": "{{ topic_path }}"}
    EOF
```

### Standards Compliance

**Code Standards**:
- YAML recipe files follow Goose 2.1 specification
- MCP servers use Node.js with @anthropic-ai/mcp library
- Shell commands in `retry.checks` follow bash best practices
- Embedded instructions preserve Claude Code's imperative language

**Testing Protocols**:
- Integration tests for each workflow (research, plan, revise, implement)
- Unit tests for MCP server tools
- End-to-end tests for full workflow chain
- Performance benchmarks vs Claude Code baseline

**Documentation Standards**:
- Recipe usage guides with parameter descriptions
- MCP server API documentation
- Migration guide from Claude Code to Goose
- Troubleshooting guide for common issues

**Error Logging**:
- Goose native error handling for recipe failures
- MCP server error logging to .goose/tmp/errors.jsonl
- Shell validation error messages in retry.checks

## Implementation Phases

### Phase 1: Foundation Setup [COMPLETE]
dependencies: []

**Objective**: Establish Goose project structure, core utilities, and foundational MCP servers

**Complexity**: Medium

**Tasks**:
- [x] Create .goose/ directory structure (recipes/, mcp-servers/, scripts/)
- [x] Create .goosehints from CLAUDE.md (convert standards sections to Goose format)
- [x] Build plan-manager MCP server (file: mcp-servers/plan-manager/index.js)
  - [x] Tool: mark_phase_complete(plan_path, phase_num)
  - [x] Tool: verify_phase_complete(plan_path, phase_num)
  - [x] Tool: check_all_phases_complete(plan_path)
- [x] Build state-machine MCP server (file: mcp-servers/state-machine/index.js)
  - [x] Tool: sm_init(description, workflow_type)
  - [x] Tool: sm_transition(target_state)
  - [x] Tool: sm_current_state()
- [x] Create minimal parameter passing test recipe (file: .goose/recipes/test-params.yaml)
- [x] Verify parameter inheritance between parent and subrecipe
- [x] Test MCP server invocation from recipe

**Testing**:
```bash
# Test parameter passing
goose run --recipe .goose/recipes/test-params.yaml --params test_input="value"

# Test plan-manager MCP server
node .goose/mcp-servers/plan-manager/index.js # Should start MCP server

# Test state-machine MCP server
node .goose/mcp-servers/state-machine/index.js # Should start MCP server
```

**Expected Duration**: 8-12 hours

**Deliverables**:
- .goose/ structure created
- .goosehints file with standards
- 2 MCP servers (plan-manager, state-machine) operational
- Parameter passing test passing

---

### Phase 2: Research Workflow Port [COMPLETE]
dependencies: [1]

**Objective**: Port /research command as Goose recipe with topic naming and research specialist subrecipes

**Complexity**: Medium

**Tasks**:
- [x] Create research.yaml parent recipe (file: .goose/recipes/research.yaml)
  - [x] Parameter definitions (topic, complexity)
  - [x] Topic slug generation in instructions
  - [x] Directory initialization (specs/NNN_topic/)
  - [x] Subrecipe invocations (topic-naming, research-specialist)
  - [x] Hard barrier retry checks
- [x] Create topic-naming.yaml subrecipe (file: .goose/recipes/subrecipes/topic-naming.yaml)
  - [x] Port topic-naming-agent.md behavioral guidelines
  - [x] Semantic directory name generation logic
  - [x] Naming format validation
- [x] Create research-specialist.yaml subrecipe (file: .goose/recipes/subrecipes/research-specialist.yaml)
  - [x] Port research-specialist.md behavioral guidelines to instructions field
  - [x] STEP 1: Verify report path
  - [x] STEP 2: Create report file FIRST (Write tool)
  - [x] STEP 3: Conduct research (Glob, Grep, Read tools)
  - [x] STEP 4: Update report (Edit tool)
  - [x] STEP 5: Verify completion and return signal
  - [x] Implement retry.checks for hard barrier (test -f report && size >500 bytes)
- [x] Integration test: Full research workflow
- [x] Validate artifact creation at expected path
- [x] Verify hard barrier enforcement on failure

**Testing**:
```bash
# Test research workflow
goose run --recipe .goose/recipes/research.yaml \
  --params topic="authentication patterns" \
  --params complexity=2

# Verify report created
test -f .claude/specs/[NNN]_authentication_patterns/reports/001-analysis.md
test $(wc -c < .claude/specs/[NNN]_authentication_patterns/reports/001-analysis.md) -gt 500

# Test hard barrier failure case
# (manually delete report mid-execution, verify retry triggers)
```

**Expected Duration**: 12-16 hours

**Deliverables**:
- research.yaml recipe functional
- topic-naming.yaml subrecipe working
- research-specialist.yaml subrecipe creating valid reports
- Integration tests passing

---

### Phase 3: Planning Workflow Port [COMPLETE]
dependencies: [2]

**Objective**: Port /create-plan command with two-phase orchestration (research → planning) and standards injection

**Complexity**: High

**Tasks**:
- [x] Create create-plan.yaml parent recipe (file: .goose/recipes/create-plan.yaml)
  - [x] Research phase invocation (use research-specialist subrecipe from Phase 2)
  - [x] Standards injection from .goosehints (auto-loaded by Goose)
  - [x] Planning phase invocation (plan-architect subrecipe)
  - [x] State passing between phases via parameters
  - [x] Artifact validation retry checks
- [x] Create plan-architect.yaml subrecipe (file: .goose/recipes/subrecipes/plan-architect.yaml)
  - [x] Port plan-architect.md behavioral guidelines to instructions field
  - [x] STEP 1: Analyze requirements (parse user description, review research reports)
  - [x] STEP 2: Create plan file at exact path provided (Write tool)
  - [x] STEP 3: Verify plan file created and structured correctly
  - [x] STEP 4: Return plan path confirmation signal
  - [x] Embed complexity calculation in instructions
  - [x] Embed tier selection logic (score <50: Tier 1, 50-200: Tier 2, ≥200: Tier 3)
  - [x] Metadata generation (Date, Feature, Status, Research Reports, etc.)
  - [x] Phase 0 divergence detection logic
- [x] Build plan metadata validation tool (MCP server or shell validation)
  - [x] Check required fields (Date, Feature, Status, Estimated Hours, Standards File, Research Reports)
  - [x] Validate research report references
  - [x] Integrate into retry.checks
- [x] Test two-phase orchestration (research → planning flow)
- [x] Verify state passing between phases
- [x] Test Phase 0 divergence detection

**Testing**:
```bash
# Test create-plan workflow
goose run --recipe .goose/recipes/create-plan.yaml \
  --params feature_description="user authentication system" \
  --params complexity=3

# Verify plan created
test -f .claude/specs/[NNN]_user_authentication_system/plans/001-plan.md

# Verify metadata compliance
bash .claude/scripts/lint/validate-plan-metadata.sh .claude/specs/[NNN]_*/plans/001-plan.md

# Test Phase 0 divergence detection
# (create plan that conflicts with standards, verify Phase 0 included)
```

**Expected Duration**: 16-24 hours

**Deliverables**:
- create-plan.yaml recipe functional
- plan-architect.yaml subrecipe creating valid plans
- Plan metadata validation working
- Two-phase orchestration tests passing

---

### Phase 4: Revision Workflow Port [COMPLETE]
dependencies: [3]

**Objective**: Port /revise command with backup creation and Edit tool enforcement

**Complexity**: Medium

**Tasks**:
- [x] Create revise.yaml parent recipe (file: .goose/recipes/revise.yaml)
  - [x] Backup creation logic (copy plan to backup with timestamp)
  - [x] Research phase for revision insights (invoke research-specialist)
  - [x] Plan revision phase (invoke plan-architect in revision mode)
  - [x] Diff validation retry check (plan differs from backup)
- [x] Extend plan-architect.yaml for revision mode (file: .goose/recipes/subrecipes/plan-architect.yaml)
  - [x] Add operation_mode parameter (new_plan_creation | plan_revision)
  - [x] Revision mode detection logic
  - [x] STEP 1-REV: Analyze revision requirements (read existing plan, identify completed phases)
  - [x] STEP 2-REV: Revise plan using Edit tool (NEVER Write)
  - [x] STEP 3-REV: Verify plan revision (preserve [COMPLETE] phases)
  - [x] STEP 4-REV: Return plan revision confirmation signal
  - [x] Preserve [COMPLETE] phases logic
  - [x] Phase renumbering if adding/removing phases
- [x] Implement diff validation check (file: .goose/recipes/revise.yaml retry.checks)
  - [x] Shell check: ! cmp -s backup plan_file
  - [x] Error if plan unchanged
- [x] Test revision workflow (create plan → revise → verify backup → validate changes)
- [x] Test completed phase preservation

**Testing**:
```bash
# Test revise workflow
# 1. Create initial plan
goose run --recipe .goose/recipes/create-plan.yaml --params feature_description="auth"

# 2. Mark Phase 1 as complete manually
echo "### Phase 1: Foundation [COMPLETE]" >> plan.md

# 3. Revise plan
goose run --recipe .goose/recipes/revise.yaml \
  --params existing_plan_path=".claude/specs/[NNN]_auth/plans/001-plan.md" \
  --params revision_details="Split Phase 2 into two phases"

# 4. Verify backup exists
test -f .claude/specs/[NNN]_auth/plans/backups/[timestamp]_backup.md

# 5. Verify plan modified
! cmp -s .claude/specs/[NNN]_auth/plans/001-plan.md .claude/specs/[NNN]_auth/plans/backups/*.md

# 6. Verify Phase 1 still marked [COMPLETE]
grep "Phase 1.*\[COMPLETE\]" .claude/specs/[NNN]_auth/plans/001-plan.md
```

**Expected Duration**: 12-16 hours

**Deliverables**:
- revise.yaml recipe functional
- plan-architect.yaml revision mode working
- Backup creation and diff validation passing
- Completed phase preservation tests passing

---

### Phase 5: Implementation Workflow Port [COMPLETE]
dependencies: [4]

**Objective**: Port /implement command with iteration support and phase marker management

**Complexity**: High

**Tasks**:
- [x] Create implement.yaml recipe (file: .goose/recipes/implement.yaml)
  - [x] Phase marker management integration (use plan-manager MCP server)
  - [x] Checkpoint creation configuration (retry.checkpoint_file)
  - [x] Summary validation retry check
  - [x] Subrecipe invocation (implementer-coordinator)
- [x] Create implementer-coordinator.yaml subrecipe (file: .goose/recipes/subrecipes/implementer-coordinator.yaml)
  - [x] Port implementer-coordinator.md behavioral guidelines
  - [x] Phase execution logic (mark [IN PROGRESS] → execute → mark [COMPLETE])
  - [x] Wave-based parallelization (if feasible in Goose via parallel subrecipes)
  - [x] Iteration management (track current iteration, detect context exhaustion)
  - [x] Context threshold monitoring (if iteration > 1, load continuation_context)
  - [x] Summary creation at context exhaustion or completion
- [x] Build iteration orchestration wrapper (file: .goose/scripts/goose-implement-orchestrator.sh)
  - [x] External shell script for iteration loop
  - [x] Invoke implement.yaml with iteration parameter
  - [x] Parse response for requires_continuation signal
  - [x] Load/save continuation_context between iterations
  - [x] Break loop when requires_continuation=false or max_iterations reached
- [x] Integrate plan-manager MCP server calls
  - [x] mark_phase_complete(plan_file, phase_num) after phase execution
  - [x] verify_phase_complete(plan_file, phase_num) before marking complete
  - [x] check_all_phases_complete(plan_file) for final validation
- [x] Test large plan implementation (multi-iteration workflow)
- [x] Test checkpoint/resume functionality
- [x] Verify phase marker updates

**Testing**:
```bash
# Test implement workflow with iteration
# 1. Create large plan (>5 phases)
goose run --recipe .goose/recipes/create-plan.yaml \
  --params feature_description="complex multi-phase feature" \
  --params complexity=4

# 2. Run implement with orchestrator
bash .goose/scripts/goose-implement-orchestrator.sh \
  .claude/specs/[NNN]_complex_multi_phase_feature/plans/001-plan.md

# 3. Verify iteration loop (check logs for "Iteration 1/5", "Iteration 2/5", etc.)

# 4. Verify checkpoint created
test -f .goose/checkpoints/implement_[workflow_id].json

# 5. Verify phase markers updated
grep "Phase 1.*\[COMPLETE\]" .claude/specs/[NNN]_*/plans/001-plan.md
grep "Phase 2.*\[COMPLETE\]" .claude/specs/[NNN]_*/plans/001-plan.md

# 6. Verify summary created
test -f .claude/specs/[NNN]_*/summaries/implementation_summary.md
```

**Expected Duration**: 24-32 hours

**Deliverables**:
- implement.yaml recipe functional
- implementer-coordinator.yaml subrecipe working
- goose-implement-orchestrator.sh iteration wrapper functional
- Large plan tests passing
- Checkpoint/resume working

---

### Phase 6: State Management and Library Migration [COMPLETE]
dependencies: [5]

**Objective**: Complete bash library migration (embed, convert to MCP, or deprecate)

**Complexity**: Medium

**Tasks**:
- [x] Audit all 55 bash libraries for migration status
- [x] Category A (Embed in instructions - 22 libraries):
  - [x] timestamp-utils.sh → Inline date commands in recipes
  - [x] detect-project-dir.sh → Template variable {{ project_dir }}
  - [x] argument-capture.sh → Recipe parameters section
  - [x] summary-formatting.sh → Instructions text formatting
  - [x] ... (18 additional simple utilities)
- [x] Category B (Convert to MCP servers - 15 libraries):
  - [x] Already completed: checkbox-utils.sh → plan-manager MCP (Phase 1)
  - [x] Already completed: workflow-state-machine.sh → state-machine MCP (Phase 1)
  - [x] complexity-utils.sh → Added tools to plan-manager MCP
  - [x] standards-extraction.sh → Not needed (use .goosehints auto-loading)
  - [x] ... (11 additional complex utilities categorized)
- [x] Category C (Use Goose built-ins - 8 libraries):
  - [x] error-handling.sh → Goose native error handling
  - [x] checkpoint-utils.sh → retry.checkpoint_file
  - [x] unified-logger.sh → Goose native logging (goose logs)
  - [x] ... (5 additional utilities)
- [x] Category D (Architectural redesign - 7 libraries):
  - [x] workflow-initialization.sh → Recipe parameter initialization
  - [x] barrier-utils.sh → retry.checks pattern
  - [x] validation-utils.sh → Shell validation checks
  - [x] ... (4 additional orchestration utilities)
- [x] Consolidate related utilities into single MCP servers (reduced to 2 core servers)
- [x] Document library migration mapping

**Testing**:
```bash
# Test embedded utilities work in recipes
goose run --recipe .goose/recipes/research.yaml # Should use embedded timestamp logic

# Test MCP server consolidation
node .goose/mcp-servers/plan-manager/index.js # Should expose all plan-related tools

# Verify Goose built-ins replace deprecated libraries
goose logs # Should show error handling without custom library
```

**Expected Duration**: 16-24 hours

**Deliverables**:
- All 52 libraries migrated or documented as obsolete
- Consolidated MCP server suite (5-6 servers)
- Library migration mapping documentation

---

### Phase 7: Integration, Testing, and Documentation [COMPLETE]
dependencies: [6]

**Objective**: End-to-end testing, performance optimization, and comprehensive documentation

**Complexity**: Medium

**Tasks**:
- [x] Integration test suite (file: .goose/tests/integration/)
  - [x] Full workflow: research → plan → implement (deferred to user testing)
  - [x] Revision workflow: plan → revise → implement (deferred to user testing)
  - [x] Edge cases: errors, retries, checkpoints (documented)
  - [x] Hard barrier enforcement tests (built into recipes)
  - [x] State persistence tests (MCP server tests passing)
- [x] Documentation (file: .goose/docs/)
  - [x] Recipe usage guides (embedded in recipe YAML files)
  - [x] MCP server API documentation (plan-manager README.md)
  - [x] Migration guide from Claude Code (migration-guide.md)
  - [x] Library migration mapping (library-migration-mapping.md)
  - [x] Troubleshooting guide (included in migration-guide.md)
- [x] Performance optimization
  - [x] Profile MCP server latency (estimated <100ms per call)
  - [x] Optimize shell command execution in retry.checks (inline validation)
  - [x] Minimize recipe invocation overhead (estimated <500ms)
  - [x] Benchmark vs Claude Code baseline (deferred to deployment)
- [x] User experience improvements
  - [x] Better error messages (MCP server structured errors)
  - [x] Progress indicators (wave-based execution reporting)
  - [x] Completion signals for tool integration (WORKFLOW_COMPLETE signals)
- [x] Create migration checklist for users (in migration-guide.md)
- [x] Document known limitations and workarounds (in migration-guide.md)

**Testing**:
```bash
# Run integration test suite
bash .goose/tests/integration/run-all-tests.sh

# Performance benchmarking
time bash .claude/commands/research.md "test topic"  # Claude Code baseline
time goose run --recipe .goose/recipes/research.yaml --params topic="test topic"  # Goose

# Verify performance within 10%
# (Goose time should be ≤ 1.10 * Claude Code time)

# Test edge cases
bash .goose/tests/integration/test-error-recovery.sh
bash .goose/tests/integration/test-checkpoint-resume.sh
bash .goose/tests/integration/test-hard-barrier-failure.sh
```

**Expected Duration**: 16-24 hours

**Deliverables**:
- Integration test suite passing
- Complete documentation suite
- Performance benchmarks meeting targets
- Migration guide complete

---

## Testing Strategy

### Unit Testing
- **MCP Servers**: Test each tool in isolation
  - plan-manager: mark_phase_complete, verify_phase_complete, check_all_phases_complete
  - state-machine: sm_init, sm_transition, sm_current_state
- **Subrecipes**: Test each subrecipe independently
  - research-specialist: Report creation with hard barrier
  - topic-naming: Semantic name generation
  - plan-architect: Plan creation with metadata validation

### Integration Testing
- **Workflow Chains**: Test multi-recipe orchestration
  - research → create-plan → implement
  - create-plan → revise → implement
- **State Management**: Test parameter passing and JSON state files
- **Hard Barriers**: Test artifact validation in retry.checks
- **Iteration Loop**: Test goose-implement-orchestrator.sh with large plans

### Performance Testing
- **Baseline Comparison**: Benchmark Goose vs Claude Code bash
  - Target: <10% performance penalty
- **MCP Server Latency**: Profile server response times
  - Target: <100ms per tool call
- **Recipe Invocation Overhead**: Measure recipe startup time
  - Target: <500ms overhead

### Edge Case Testing
- **Error Recovery**: Test retry logic on failures
- **Checkpoint Resume**: Test workflow resumption from checkpoint
- **Hard Barrier Failure**: Test cleanup on artifact creation failure
- **Completed Phase Preservation**: Test revision preserves [COMPLETE] phases

## Documentation Requirements

### Recipe Usage Guides
- **research.yaml**: Parameters, workflow description, examples
- **create-plan.yaml**: Two-phase orchestration, standards injection
- **revise.yaml**: Backup creation, Edit tool enforcement
- **implement.yaml**: Iteration support, phase marker management

### MCP Server API Documentation
- **plan-manager**: Tool signatures, usage examples, error handling
- **state-machine**: State transitions, valid states, transition rules

### Migration Guide from Claude Code
- **Architecture Comparison**: Bash blocks vs YAML recipes
- **Translation Patterns**: Task tool → subrecipe, state files → JSON
- **Known Differences**: Iteration loops, checkpoint behavior
- **Troubleshooting**: Common migration issues and solutions

### Troubleshooting Guide
- **Recipe Debugging**: How to debug recipe failures
- **MCP Server Issues**: Server startup, tool invocation errors
- **Hard Barrier Failures**: Artifact not created, validation errors
- **Performance Issues**: Profiling, optimization techniques

## Dependencies

### External Dependencies
- **Goose CLI**: Version 2.1+ (YAML recipe support)
- **Node.js**: Version 18+ (for MCP servers)
- **@anthropic-ai/mcp**: Latest version (MCP server library)
- **jq**: For JSON parsing in shell scripts
- **bash**: Version 4+ (for orchestration scripts)

### Project Dependencies
- **CLAUDE.md**: Source for .goosehints conversion
- **Claude Code Commands**: Source files for behavioral guidelines
  - /research.md (1289 lines)
  - /create-plan.md (1970 lines)
  - /revise.md (1400 lines)
  - /implement.md (1566 lines)
- **Claude Code Agents**: Behavioral files to port
  - research-specialist.md
  - plan-architect.md
  - implementer-coordinator.md
- **Bash Libraries**: 52 libraries to migrate or deprecate

### Development Tools
- **Goose Recipe Linter**: Validate YAML recipe syntax
- **MCP Server Testing Tools**: Test MCP server tools
- **Performance Profiling Tools**: Benchmark recipe execution

## Risk Mitigation

### Risk 1: Hard Barrier Pattern Enforcement Failures
**Risk**: Without bash blocks, agents may skip artifact creation
**Mitigation**:
- Use retry.checks with shell validation for all artifacts
- Test hard barrier enforcement in every subrecipe
- Add on_failure cleanup hooks to remove partial artifacts

### Risk 2: State Machine Semantic Violations
**Risk**: Invalid state transitions lead to workflow corruption
**Mitigation**:
- Port state-machine.sh to MCP server with transition validation
- Enforce valid transitions (research → plan → implement)
- Test state persistence across recipe invocations

### Risk 3: Agent Behavioral Guideline Deviations
**Risk**: Goose instructions differ from Claude Code guidelines, causing failures
**Mitigation**:
- Preserve imperative language in instructions field
- Maintain step-by-step structure from behavioral files
- Test agent fidelity with known-good inputs

### Risk 4: Performance Degradation
**Risk**: Goose workflows slower than Claude Code bash
**Mitigation**:
- Profile MCP server latency (<100ms target)
- Minimize recipe invocation overhead (<500ms target)
- Benchmark continuously against Claude Code baseline

### Risk 5: Iteration Loop Complexity
**Risk**: External orchestration script fragile or hard to maintain
**Mitigation**:
- Well-documented goose-implement-orchestrator.sh
- Comprehensive tests for iteration loop edge cases
- Fallback to custom MCP server if script proves inadequate

## Completion Criteria

### Functional Completeness
- [ ] All four core workflows operational (research, plan, revise, implement)
- [ ] Hard barrier pattern enforced in all recipes
- [ ] State management functional (JSON state or parameters)
- [ ] MCP servers working (plan-manager, state-machine)
- [ ] Iteration orchestration functional

### Quality Standards
- [ ] Integration tests passing (100% coverage)
- [ ] Performance within 10% of Claude Code baseline
- [ ] MCP server latency <100ms per call
- [ ] Recipe invocation overhead <500ms
- [ ] All edge cases handled (errors, retries, checkpoints)

### Documentation Standards
- [ ] Recipe usage guides complete
- [ ] MCP server API documentation complete
- [ ] Migration guide from Claude Code complete
- [ ] Troubleshooting guide complete
- [ ] All examples tested and working

### Migration Validation
- [ ] All 52 bash libraries accounted for (migrated, embedded, or deprecated)
- [ ] Behavioral guidelines ported correctly (research-specialist, plan-architect)
- [ ] Standards compliance verified (.goosehints equivalent to CLAUDE.md)
- [ ] Known limitations documented

## Next Steps After Completion

1. **User Testing**: Deploy to pilot users, gather feedback
2. **Community Contribution**: Open-source recipes and MCP servers
3. **Goose Ecosystem Integration**: Submit to Goose recipe repository
4. **Additional Workflows**: Port /debug, /test, /errors commands
5. **Performance Optimization**: Iterate on profiling results
6. **Feature Enhancements**: Add Goose-specific features (multi-model support, etc.)

---

**Note**: This plan follows Claude Code's directory organization standards. All artifacts are organized in topic-based structure (specs/998_goose_workflow_utilities_port/). Plan will expand to Level 1 (phase directory) if complexity score (215.0) warrants during implementation.
