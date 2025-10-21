# Phase 8: Agent Migration - Wave 3 & 4 + System Validation

## Metadata
- **Phase Number**: 8
- **Phase Name**: Agent Migration - Wave 3 & 4 + System Validation
- **Parent Plan**: 077_execution_enforcement_migration.md
- **Duration**: 22 hours (Week 6-7)
- **Complexity**: High (8/10)
- **Expansion Date**: 2025-10-20

## Objective

Complete the final wave of agent migrations (Wave 3 & 4) and perform comprehensive system-wide validation to ensure:
1. All 10 agents achieve ≥95/100 audit scores
2. All agents demonstrate 100% file creation rates (10/10 tests)
3. Zero regressions in existing functionality
4. Performance targets met (100% file creation, <30% context usage)
5. Documentation updated to reflect enforcement patterns

This phase marks the completion of the execution enforcement migration, transitioning from variable file creation rates (60-80%) to systematic enforcement achieving 100% reliability.

## Prerequisites

### Required Completions
- [ ] Phase 2: Agent Migration Wave 1 (doc-writer, debug-specialist, test-specialist)
- [ ] Phase 3: Agent Migration Wave 2 (expansion-specialist, collapse-specialist, spec-updater)
- [ ] Phase 4-7: All 12 commands migrated with Phase 0 role clarification
- [ ] Migration tracking spreadsheet initialized and maintained
- [ ] Test harness infrastructure functional

### Required Files
- `.claude/lib/audit-execution-enforcement.sh` - Audit scoring tool
- `.claude/tests/test_migration_file_creation.sh` - File creation rate test harness
- `.claude/lib/track-file-creation-rate.sh` - Rate tracking utility
- `.claude/specs/plans/077_migration_tracking.csv` - Progress tracking spreadsheet
- Reference agents (research-specialist.md, plan-architect.md, code-writer.md) - Compliance models

### Required Knowledge
- Standard 0.5 agent enforcement patterns (5-phase transformation)
- Migration guide reference patterns
- Agent invocation testing procedures
- System-wide test suite execution

## Stage 1: Agent Migration - Wave 3 & 4 (10 hours)

### Overview
Migrate the final 4 agents to Standard 0.5 compliance using the proven 5-phase transformation process. These agents are less frequently invoked than Wave 1-2 but are critical for specific workflows.

### Stage 1.1: Migrate code-reviewer.md (3 hours)

**Agent Context**:
- **Invoked by**: `/refactor` command
- **Purpose**: Analyze code for refactoring opportunities based on project standards
- **Current State**: Baseline audit score unknown, passive voice present
- **Target State**: ≥95/100 audit score, 100% report creation rate

**Phase 1: Transform Role Declaration (30 minutes)**

Tasks:
- [ ] Read current code-reviewer.md to identify role statements
  ```bash
  grep -E "^(I am|This agent|My role)" .claude/agents/code-reviewer.md
  ```
- [ ] Replace "I am a code review specialist" with "**YOU MUST perform code review analysis**"
- [ ] Add "**PRIMARY OBLIGATION**: Creating refactoring report is MANDATORY"
- [ ] Add "**NON-NEGOTIABLE**: File creation is not optional - you WILL create the report file"
- [ ] Remove all passive "I am", "I can", "I will" statements
- [ ] Verify zero first-person role statements remain

**Phase 2: Add Sequential Step Dependencies (60 minutes)**

Tasks:
- [ ] Identify current workflow sections (likely: codebase analysis, pattern detection, recommendations)
- [ ] Restructure to STEP format with REQUIRED BEFORE markers:
  ```markdown
  ## STEP 1 (REQUIRED BEFORE STEP 2) - Analyze Codebase
  ## STEP 2 (REQUIRED BEFORE STEP 3) - Detect Refactoring Patterns
  ## STEP 3 (REQUIRED BEFORE STEP 4) - Generate Recommendations
  ## STEP 4 (ABSOLUTE REQUIREMENT) - Create Refactoring Report
  ```
- [ ] Add "**EXECUTE NOW**" markers before critical operations:
  - [ ] Before code analysis bash blocks
  - [ ] Before pattern detection grep operations
  - [ ] Before report file creation
- [ ] Add "**VERIFICATION**" blocks after report creation:
  ```markdown
  **MANDATORY VERIFICATION**:
  ```bash
  if [ ! -f "$REPORT_PATH" ]; then
    echo "ERROR: Report file not created"
    exit 1
  fi
  echo "✓ Verified: Report created at $REPORT_PATH"
  ```
  ```

**Phase 3: Eliminate Passive Voice (15 minutes)**

Tasks:
- [ ] Search and replace passive verbs:
  - `should` → `MUST`
  - `may` → `WILL`
  - `can` → `SHALL`
  - `could` → `MUST`
  - `consider` → `EXECUTE`
  - `try to` → `EXECUTE`
- [ ] Verify zero instances of passive language remain:
  ```bash
  grep -iE "(should|may|can|could|consider|try to)" .claude/agents/code-reviewer.md
  ```
- [ ] Ensure all instructions use imperative mood

**Phase 4: Add Template Enforcement (30 minutes)**

Tasks:
- [ ] Identify report output format section
- [ ] Add "**THIS EXACT TEMPLATE (No modifications)**" marker before format specification
- [ ] Add REQUIRED markers to all report sections:
  ```markdown
  ## REFACTORING REPORT FORMAT - THIS EXACT TEMPLATE (No modifications)

  ### REQUIRED SECTIONS (ALL MANDATORY):
  1. **Codebase Analysis** (REQUIRED)
  2. **Refactoring Patterns Detected** (REQUIRED - minimum 3)
  3. **Recommendations** (REQUIRED - minimum 5)
  4. **Priority Assessment** (REQUIRED)
  5. **Implementation Roadmap** (REQUIRED)
  ```
- [ ] Add explicit minimums for content (e.g., "minimum 5 recommendations")
- [ ] Specify explicit file path format: `specs/{NNN_topic}/reports/{NNN}_refactoring_analysis.md`

**Phase 5: Add Completion Criteria (45 minutes)**

Tasks:
- [ ] Add "## COMPLETION CRITERIA - ALL REQUIRED" section at end of agent file
- [ ] Convert success criteria to checkbox format:
  ```markdown
  ## COMPLETION CRITERIA - ALL REQUIRED

  YOU MUST verify ALL of the following before considering your task complete:

  - [ ] Report file created at pre-calculated path
  - [ ] Report contains all REQUIRED sections
  - [ ] Minimum content requirements met (5+ recommendations)
  - [ ] File is valid markdown and parseable
  - [ ] File size >1KB (indicates substantive content)
  - [ ] Verification checkpoint executed and passed

  **NON-COMPLIANCE**: Failure to meet any criterion is UNACCEPTABLE.
  ```
- [ ] Add explicit output format requirement:
  ```markdown
  **FINAL OUTPUT**: You MUST output the absolute file path and confirmation:
  ```
  Report created: /absolute/path/to/report.md
  ✓ All completion criteria met
  ```
  ```

**Testing (30 minutes)**:
- [ ] Run baseline audit before migration:
  ```bash
  .claude/lib/audit-execution-enforcement.sh .claude/agents/code-reviewer.md > /tmp/code-reviewer-before.txt
  ```
- [ ] Run 10 invocations via /refactor command:
  ```bash
  for i in {1..10}; do
    echo "Test run $i..."
    /refactor .claude/lib/context-pruning.sh "Analyze for performance improvements"
    # Verify report created
    ls -la .claude/specs/*/reports/*refactoring*.md | tail -1
  done
  ```
- [ ] Verify 10/10 file creation successes
- [ ] Check verification checkpoint execution (grep output for "✓ Verified")
- [ ] Re-audit post-migration:
  ```bash
  .claude/lib/audit-execution-enforcement.sh .claude/agents/code-reviewer.md
  # Expected: Score ≥95/100
  ```
- [ ] Update tracking spreadsheet with results

**Deliverable**:
- [ ] code-reviewer.md migrated to Standard 0.5 compliance
- [ ] Audit score ≥95/100
- [ ] File creation rate 100% (10/10)
- [ ] Tracking spreadsheet updated

---

### Stage 1.2: Migrate complexity-estimator.md (2 hours)

**Agent Context**:
- **Invoked by**: `/expand`, `/collapse`, adaptive planning in `/implement`
- **Purpose**: Calculate complexity scores for phases/stages (1-10 scale)
- **Current State**: Already has some structure, needs strengthening
- **Target State**: ≥95/100 audit score, 100% reliable scoring output

**Streamlined Migration (already has enforcement foundation)**

**Phase 1-3: Role, Steps, Voice (45 minutes)**
- [ ] Transform role: "YOU MUST calculate complexity scores"
- [ ] Add PRIMARY OBLIGATION for score output
- [ ] Restructure to STEP format:
  ```markdown
  ## STEP 1 (REQUIRED BEFORE STEP 2) - Analyze Task Count
  ## STEP 2 (REQUIRED BEFORE STEP 3) - Analyze File References
  ## STEP 3 (REQUIRED BEFORE STEP 4) - Analyze Dependencies
  ## STEP 4 (ABSOLUTE REQUIREMENT) - Calculate Final Score
  ```
- [ ] Eliminate any remaining should/may/can/consider

**Phase 4: Template Enforcement (30 minutes)**
- [ ] Add THIS EXACT TEMPLATE to score output format:
  ```markdown
  ## COMPLEXITY SCORE OUTPUT - THIS EXACT TEMPLATE (No modifications)

  **REQUIRED FORMAT**:
  ```
  Complexity Score: {N}/10
  Reasoning: {explanation}
  Expansion Recommended: {yes/no}
  ```
  ```
- [ ] Specify scoring criteria explicitly (task count weight, file reference weight, etc.)

**Phase 5: Completion Criteria (30 minutes)**
- [ ] Add COMPLETION CRITERIA section:
  ```markdown
  ## COMPLETION CRITERIA - ALL REQUIRED

  - [ ] Complexity score calculated (integer 1-10)
  - [ ] Reasoning provided (minimum 50 words)
  - [ ] Expansion recommendation provided (yes/no)
  - [ ] Score output in exact template format
  - [ ] All scoring factors analyzed
  ```

**Testing (15 minutes)**:
- [ ] Run 10 invocations via /expand (complexity calculation):
  ```bash
  for i in {1..10}; do
    /expand .claude/specs/plans/077_execution_enforcement_migration.md phase_7
    # Verify complexity score in output
  done
  ```
- [ ] Verify 10/10 score outputs
- [ ] Re-audit: verify ≥95/100
- [ ] Update tracking spreadsheet

**Deliverable**:
- [ ] complexity-estimator.md migrated
- [ ] Audit score ≥95/100
- [ ] Tracking spreadsheet updated

---

### Stage 1.3: Migrate plan-expander.md (2 hours)

**Agent Context**:
- **Invoked by**: `/orchestrate` for complexity evaluation phase
- **Purpose**: Analyze whether phases should be expanded to separate files
- **Current State**: Has workflow structure, needs imperative strengthening
- **Target State**: ≥95/100 audit score, reliable expansion recommendations

**Full 5-Phase Migration (similar to complexity-estimator)**

**Phase 1-3: Role, Steps, Voice (45 minutes)**
- [ ] Transform role: "YOU MUST analyze phase complexity and recommend expansions"
- [ ] Add PRIMARY OBLIGATION for recommendation output
- [ ] Restructure workflow to STEP N (REQUIRED BEFORE STEP N+1) format
- [ ] Eliminate passive voice throughout

**Phase 4: Template Enforcement (30 minutes)**
- [ ] Add THIS EXACT TEMPLATE to recommendation format:
  ```markdown
  ## EXPANSION RECOMMENDATION FORMAT - THIS EXACT TEMPLATE

  **REQUIRED OUTPUT**:
  For each phase analyzed:
  - Phase {N}: {name} - Complexity: {score}/10 - Expand: {yes/no}
  ```
- [ ] Add REQUIRED analysis criteria

**Phase 5: Completion Criteria (30 minutes)**
- [ ] Add COMPLETION CRITERIA with checkboxes
- [ ] Add NON-COMPLIANCE warnings
- [ ] Specify minimum content requirements

**Testing (15 minutes)**:
- [ ] Run 10 invocations via /orchestrate complexity evaluation
- [ ] Verify recommendation output format
- [ ] Re-audit: ≥95/100
- [ ] Update tracking spreadsheet

**Deliverable**:
- [ ] plan-expander.md migrated
- [ ] Audit score ≥95/100
- [ ] Tracking spreadsheet updated

---

### Stage 1.4: Migrate metrics-specialist.md (3 hours)

**Agent Context**:
- **Invoked by**: `/refactor` for metrics analysis
- **Purpose**: Analyze code metrics, cyclomatic complexity, maintainability
- **Current State**: Likely similar to code-reviewer, needs full transformation
- **Target State**: ≥95/100 audit score, 100% report creation rate

**Full 5-Phase Migration (same pattern as code-reviewer)**

**Phase 1: Transform Role Declaration (30 minutes)**
- [ ] Replace passive role statements with "YOU MUST analyze code metrics"
- [ ] Add PRIMARY OBLIGATION for metrics report creation
- [ ] Remove all first-person language

**Phase 2: Add Sequential Step Dependencies (60 minutes)**
- [ ] Restructure to STEP format:
  ```markdown
  ## STEP 1 (REQUIRED BEFORE STEP 2) - Collect Code Metrics
  ## STEP 2 (REQUIRED BEFORE STEP 3) - Analyze Complexity
  ## STEP 3 (REQUIRED BEFORE STEP 4) - Calculate Maintainability Scores
  ## STEP 4 (ABSOLUTE REQUIREMENT) - Create Metrics Report
  ```
- [ ] Add EXECUTE NOW markers before analysis blocks
- [ ] Add MANDATORY VERIFICATION after report creation

**Phase 3: Eliminate Passive Voice (15 minutes)**
- [ ] Search and replace should/may/can/could/consider
- [ ] Verify zero passive instances remain

**Phase 4: Add Template Enforcement (30 minutes)**
- [ ] Add THIS EXACT TEMPLATE to metrics report format:
  ```markdown
  ## METRICS REPORT FORMAT - THIS EXACT TEMPLATE (No modifications)

  ### REQUIRED SECTIONS (ALL MANDATORY):
  1. **Code Metrics Summary** (REQUIRED)
     - Lines of code
     - Cyclomatic complexity average
     - Function count
  2. **Complexity Hotspots** (REQUIRED - minimum 5)
  3. **Maintainability Scores** (REQUIRED)
  4. **Technical Debt Assessment** (REQUIRED)
  5. **Recommendations** (REQUIRED - minimum 3)
  ```
- [ ] Specify explicit minimums for content

**Phase 5: Add Completion Criteria (45 minutes)**
- [ ] Add COMPLETION CRITERIA section with checkboxes
- [ ] Add NON-COMPLIANCE warnings
- [ ] Add explicit output format requirement

**Testing (30 minutes)**:
- [ ] Run 10 invocations via /refactor with metrics flag
- [ ] Verify 10/10 report creation
- [ ] Check verification checkpoints execute
- [ ] Re-audit: ≥95/100
- [ ] Update tracking spreadsheet

**Deliverable**:
- [ ] metrics-specialist.md migrated to Standard 0.5 compliance
- [ ] Audit score ≥95/100
- [ ] File creation rate 100% (10/10)
- [ ] Tracking spreadsheet updated

---

### Stage 1 Summary
**Duration**: 10 hours
**Deliverables**:
- [ ] 4 agents migrated (code-reviewer, complexity-estimator, plan-expander, metrics-specialist)
- [ ] All 4 agents score ≥95/100 on audit
- [ ] All 4 agents demonstrate 100% file creation/output reliability
- [ ] Migration tracking spreadsheet updated with Wave 3 & 4 results
- [ ] **Milestone**: All 10 agents now compliant (100% agent migration complete)

---

## Stage 2: System-Wide Integration Testing (4 hours)

### Overview
Perform comprehensive end-to-end testing to verify all migrations work together correctly and no regressions have been introduced.

### Stage 2.1: Full Test Suite Execution (1 hour)

**Objective**: Verify all existing automated tests pass with zero failures

Tasks:
- [ ] Execute complete test suite:
  ```bash
  cd .claude/tests
  ./run_all_tests.sh 2>&1 | tee /tmp/migration-test-results.txt
  ```
- [ ] Analyze test results:
  ```bash
  grep -E "(PASS|FAIL)" /tmp/migration-test-results.txt | sort | uniq -c
  ```
- [ ] Expected: Zero failures across all test files:
  - test_parsing_utilities.sh (22 tests)
  - test_command_integration.sh (15 tests)
  - test_progressive_*.sh (18 tests total)
  - test_state_management.sh (12 tests)
  - test_shared_utilities.sh (25 tests)
  - test_adaptive_planning.sh (16 tests)
  - test_revise_automode.sh (18 tests)
  - All other test files in .claude/tests/
- [ ] If any failures: investigate immediately, rollback if needed
- [ ] Document test results in migration tracking spreadsheet

---

### Stage 2.2: Hierarchical Pattern Testing (1 hour)

**Objective**: Verify hierarchical multi-agent patterns execute correctly with Phase 0 enforcement

**Test 1: /report Hierarchical Execution**

Tasks:
- [ ] Execute complex research topic requiring subtopic decomposition:
  ```bash
  /report "Comprehensive analysis of microservices architecture patterns with focus on event-driven design, CQRS, and service mesh implementations"
  ```
- [ ] Verify Task tool invocations visible in output (not direct Read/Grep usage):
  ```bash
  # In output, should see lines like:
  # Invoking research-specialist for subtopic: Event-Driven Design...
  # Invoking research-specialist for subtopic: CQRS Patterns...
  # etc.
  ```
- [ ] Verify multiple subtopic reports created:
  ```bash
  # Expected structure:
  ls -la .claude/specs/*/reports/
  # Should show:
  # 001_event_driven_design.md
  # 002_cqrs_patterns.md
  # 003_service_mesh.md
  # 004_integration_strategies.md
  # 000_overview.md (created by supervisor)
  ```
- [ ] Verify reports contain substantive content (>1KB each)
- [ ] Verify supervisor creates overview report synthesizing findings
- [ ] Verify zero direct tool usage by orchestrator (only Task tool delegation)

**Test 2: /report Simple Topic (Direct Execution)**

Tasks:
- [ ] Execute simple topic that doesn't warrant decomposition:
  ```bash
  /report "How to configure vim-surround plugin"
  ```
- [ ] Verify single report created (no subtopic decomposition)
- [ ] Verify research-specialist still invoked (Phase 0 enforcement)
- [ ] Expected: specs/{NNN_topic}/reports/001_vim_surround_config.md

**Test 3: Recursive Supervision Pattern**

Tasks:
- [ ] Execute extremely complex topic requiring sub-supervisors:
  ```bash
  /report "Complete analysis of cloud-native architecture including 12-factor apps, Kubernetes patterns, service mesh comparisons, observability strategies, security best practices, cost optimization, CI/CD pipelines, GitOps workflows, disaster recovery, multi-cloud strategies, edge computing integration, and serverless architecture patterns"
  ```
- [ ] Verify hierarchical structure (supervisor → sub-supervisors → researchers)
- [ ] Verify 10+ subtopic reports created
- [ ] Verify overview synthesizes all findings
- [ ] Verify context usage remains <30% for supervisor

**Deliverable**:
- [ ] Hierarchical pattern verified working correctly
- [ ] Phase 0 enforcement prevents direct execution by orchestrators
- [ ] Task tool delegation functioning as expected

---

### Stage 2.3: Conditional Orchestration Testing (1 hour)

**Objective**: Verify conditional logic correctly switches between direct execution and agent orchestration

**Test 1: /plan Simple Feature (Direct Execution)**

Tasks:
- [ ] Execute simple planning task:
  ```bash
  /plan "Add a new keybinding to close all buffers at once"
  ```
- [ ] Verify NO Task tool invocations (direct plan creation)
- [ ] Verify plan file created successfully
- [ ] Verify no research delegation occurred (feature too simple)

**Test 2: /plan Complex Feature (Research Orchestration)**

Tasks:
- [ ] Execute complex planning task:
  ```bash
  /plan "Implement distributed tracing system with OpenTelemetry integration, custom exporters for multiple backends, performance monitoring dashboard, and automated alerting based on trace analysis"
  ```
- [ ] Verify Task tool invocations for research-specialist agents
- [ ] Verify research reports created before plan
- [ ] Verify plan references research findings
- [ ] Verify conditional logic triggered correctly (complexity threshold met)

**Test 3: /implement Simple Plan (Direct Execution)**

Tasks:
- [ ] Create simple test plan:
  ```bash
  cat > .claude/specs/plans/test_simple_implementation.md <<'EOF'
  # Simple Keybinding Implementation

  ## Phase 1: Add Keybinding
  **Complexity**: 2/10
  **Tasks**:
  - [ ] Add keybinding to keymaps.lua
  - [ ] Test keybinding works
  EOF
  ```
- [ ] Execute implementation:
  ```bash
  /implement .claude/specs/plans/test_simple_implementation.md
  ```
- [ ] Verify direct implementation (no agent delegation)
- [ ] Verify implementation completes successfully

**Test 4: /implement Complex Plan (Agent Orchestration)**

Tasks:
- [ ] Create complex test plan with Phase 3 complexity ≥8:
  ```bash
  cat > .claude/specs/plans/test_complex_implementation.md <<'EOF'
  # Complex System Implementation

  ## Phase 3: Database Integration Layer
  **Complexity**: 9/10
  **Tasks**:
  - [ ] Implement connection pooling (15 configuration parameters)
  - [ ] Add retry logic with exponential backoff
  - [ ] Implement circuit breaker pattern
  - [ ] Add distributed tracing integration
  - [ ] Implement query caching layer
  - [ ] Add read replica routing
  - [ ] Implement transaction management
  - [ ] Add database migration system
  - [ ] Configure connection health monitoring
  - [ ] Implement automatic failover
  EOF
  ```
- [ ] Execute implementation:
  ```bash
  /implement .claude/specs/plans/test_complex_implementation.md 3
  ```
- [ ] Verify Task tool invocation for implementation-researcher or code-writer
- [ ] Verify conditional orchestration triggered (complexity ≥8)
- [ ] Verify implementation completes with agent assistance

**Deliverable**:
- [ ] Conditional orchestration verified working correctly
- [ ] Simple tasks → direct execution
- [ ] Complex tasks → agent orchestration
- [ ] Thresholds correctly calibrated

---

### Stage 2.4: Parallel Execution Testing (30 minutes)

**Objective**: Verify parallel agent execution still functions correctly

**Test 1: /report Parallel Research**

Tasks:
- [ ] Execute /report with topic requiring 4+ parallel research agents
- [ ] Monitor for parallel Task invocations:
  ```bash
  /report "Authentication best practices" 2>&1 | grep -E "Invoking research-specialist" | wc -l
  # Expected: 2-4 parallel invocations
  ```
- [ ] Measure execution time vs sequential:
  ```bash
  time /report "Complex topic with 4 subtopics requiring parallel research"
  # Expected: Significantly faster than 4 sequential operations
  # Typical: 40-60% time savings
  ```

**Test 2: /debug Parallel Hypothesis Investigation**

Tasks:
- [ ] Execute /debug with complex issue:
  ```bash
  /debug "Intermittent test failures in adaptive planning integration tests, only occurring on certain phases, suspected race condition or state pollution"
  ```
- [ ] Verify parallel debug-analyst invocations (3+ hypotheses)
- [ ] Verify debug reports created for each hypothesis
- [ ] Verify parallelization reduces total investigation time

**Test 3: /orchestrate Parallel Research Phase**

Tasks:
- [ ] Execute full /orchestrate workflow:
  ```bash
  /orchestrate "Implement user authentication system from research to documentation"
  ```
- [ ] Verify research phase uses parallel agents (2-4 researchers)
- [ ] Verify other phases also parallelize where applicable
- [ ] Verify workflow completion time reflects parallel execution benefits

**Deliverable**:
- [ ] Parallel execution verified functional
- [ ] Time savings measured (40-60% typical)
- [ ] No race conditions or conflicts detected

---

### Stage 2.5: Context Window Usage Testing (30 minutes)

**Objective**: Verify context window usage remains <30% for orchestrators

**Test: /orchestrate Full Workflow Context Monitoring**

Tasks:
- [ ] Execute complete orchestration workflow:
  ```bash
  /orchestrate "Complete feature development: research authentication patterns, create implementation plan, implement OAuth2 integration, debug any issues, document the system"
  ```
- [ ] Monitor context usage throughout workflow (if tooling available)
- [ ] Verify metadata-based passing (not full content):
  - [ ] Research reports passed as metadata (title + summary + path)
  - [ ] Plan passed as metadata (complexity + phases + path)
  - [ ] Implementation artifacts passed as metadata (files modified + path)
- [ ] Expected context usage metrics:
  - Research phase: <20% (metadata-only passing to planner)
  - Planning phase: <25% (metadata from research + plan structure)
  - Implementation phase: <30% (metadata from plan + code context)
  - Debugging phase: <25% (metadata from implementation + error logs)
  - Documentation phase: <20% (metadata from implementation)
- [ ] Verify aggressive context pruning between phases
- [ ] Verify no full report content in orchestrator context (only metadata)

**Validation**:
- [ ] Review orchestrator logs for context size warnings
- [ ] Verify metadata extraction functions used (`extract_report_metadata`, etc.)
- [ ] Verify no evidence of full content passing

**Deliverable**:
- [ ] Context usage verified <30% throughout workflows
- [ ] Metadata-based passing confirmed functional
- [ ] Context reduction metrics documented

---

### Stage 2 Summary
**Duration**: 4 hours
**Deliverables**:
- [ ] Full test suite passing (zero regressions)
- [ ] Hierarchical patterns verified (Task delegation, no direct execution)
- [ ] Conditional orchestration verified (simple → direct, complex → agents)
- [ ] Parallel execution verified (40-60% time savings)
- [ ] Context window usage verified (<30% for orchestrators)
- [ ] System-wide integration confirmed stable

---

## Stage 3: Regression Testing (3 hours)

### Overview
Verify all existing functionality remains intact and no breaking changes introduced.

### Stage 3.1: Existing Test Suite Verification (1 hour)

**Objective**: Re-run all test suites with detailed analysis

Tasks:
- [ ] Execute each test file individually:
  ```bash
  for test_file in .claude/tests/test_*.sh; do
    echo "Running $test_file..."
    bash "$test_file" 2>&1 | tee "/tmp/$(basename $test_file).log"
  done
  ```
- [ ] Analyze results for each suite:
  - [ ] test_parsing_utilities.sh - Expected: 22/22 passing
  - [ ] test_command_integration.sh - Expected: 15/15 passing
  - [ ] test_progressive_expansion.sh - Expected: 8/8 passing
  - [ ] test_progressive_collapse.sh - Expected: 10/10 passing
  - [ ] test_state_management.sh - Expected: 12/12 passing
  - [ ] test_shared_utilities.sh - Expected: 25/25 passing
  - [ ] test_adaptive_planning.sh - Expected: 16/16 passing
  - [ ] test_revise_automode.sh - Expected: 18/18 passing
- [ ] Document any failures with detailed context
- [ ] If failures detected:
  - [ ] Investigate root cause
  - [ ] Determine if related to migration
  - [ ] Rollback affected components if necessary
  - [ ] Re-test after fixes

---

### Stage 3.2: Backward Compatibility Verification (1 hour)

**Objective**: Ensure all commands work with existing usage patterns

**Test: Command Interface Stability**

Tasks:
- [ ] Test /report with various input formats:
  ```bash
  /report "Simple topic"
  /report "Complex topic requiring research and analysis of multiple aspects"
  ```
- [ ] Verify both produce expected outputs (reports created)
- [ ] Test /plan with different feature descriptions:
  ```bash
  /plan "Simple feature"
  /plan "Complex system with multiple integration points and dependencies"
  ```
- [ ] Verify both create valid plans
- [ ] Test /implement with different plan complexities:
  ```bash
  /implement specs/plans/simple_plan.md
  /implement specs/plans/complex_plan.md
  ```
- [ ] Verify both execute successfully
- [ ] Test all 12 migrated commands with typical usage:
  - [ ] /orchestrate "typical workflow"
  - [ ] /debug "common issue"
  - [ ] /refactor "standard file"
  - [ ] /expand "plan with complex phase"
  - [ ] /collapse "expanded plan"
  - [ ] /convert-docs "input" "output"
  - [ ] All others from command list

**Test: Agent Output Compatibility**

Tasks:
- [ ] Verify agent outputs still parseable by consuming commands:
  - [ ] research-specialist reports still parsed by /report supervisor
  - [ ] plan-architect plans still parsed by /implement
  - [ ] debug-specialist reports still parsed by /debug supervisor
  - [ ] doc-writer outputs still valid markdown
  - [ ] spec-updater metadata updates still valid
- [ ] Verify no format changes broke downstream consumers
- [ ] Verify checkpoint files still compatible with checkpoint-utils.sh

---

### Stage 3.3: Breaking Changes Audit (1 hour)

**Objective**: Identify and document any breaking changes

**Review Process**:

Tasks:
- [ ] Review all command modifications for API changes:
  ```bash
  for cmd in .claude/commands/*.md; do
    git diff main -- "$cmd" | grep -E "^(\+|-).*\#\#" | head -20
  done
  ```
- [ ] Verify no command signatures changed (argument order, flags)
- [ ] Verify no output formats changed (unless intentional improvements)
- [ ] Document any intentional breaking changes:
  - [ ] List change description
  - [ ] List reason for change
  - [ ] List migration path for users
- [ ] Verify CHANGELOG.md updated with breaking changes (if any)
- [ ] Review agent modifications for output format changes:
  ```bash
  for agent in .claude/agents/*.md; do
    git diff main -- "$agent" | grep -E "^(\+|-).*\#\# OUTPUT" -A 10
  done
  ```
- [ ] Verify agent output formats backward compatible or improved
- [ ] Create migration notes if any user-facing changes exist

**Deliverable**:
- [ ] Breaking changes audit complete
- [ ] No unintended API changes detected
- [ ] Intentional changes documented
- [ ] Migration guide updated if needed

---

### Stage 3 Summary
**Duration**: 3 hours
**Deliverables**:
- [ ] All test suites verified passing
- [ ] Backward compatibility confirmed
- [ ] Breaking changes audited and documented
- [ ] Zero unexpected regressions

---

## Stage 4: Performance Verification (2 hours)

### Overview
Measure and verify performance targets achieved across all migrations.

### Stage 4.1: File Creation Rate Measurement (1 hour)

**Objective**: Verify 100% file creation rates for all commands and agents

**Commands File Creation Testing**:

Tasks:
- [ ] Test all 12 migrated commands (10 runs each):
  ```bash
  # Create comprehensive test script
  cat > /tmp/test_all_command_file_creation.sh <<'EOF'
  #!/bin/bash

  COMMANDS=(
    "/report 'Test topic'"
    "/plan 'Test feature'"
    "/implement 'specs/plans/test.md'"
    "/orchestrate 'Test workflow'"
    "/debug 'Test issue'"
    "/refactor '.claude/lib/test.sh'"
    "/expand 'specs/plans/test.md' 'phase_1'"
    "/collapse 'specs/plans/test/phase_1.md'"
    "/convert-docs 'test.md' 'test.pdf'"
    # Add others as needed
  )

  for cmd in "${COMMANDS[@]}"; do
    SUCCESS=0
    for i in {1..10}; do
      eval "$cmd" &>/dev/null && SUCCESS=$((SUCCESS + 1))
    done
    echo "$cmd: $SUCCESS/10"
  done
  EOF

  bash /tmp/test_all_command_file_creation.sh
  ```
- [ ] Expected: All commands show 10/10 (100% success rate)
- [ ] Document results in tracking spreadsheet
- [ ] Investigate any commands showing <10/10

**Agents File Creation Testing (via Commands)**:

Tasks:
- [ ] Test all 10 migrated agents (10 runs each via invoking commands):
  ```bash
  # research-specialist via /report
  for i in {1..10}; do /report "Test topic $i"; done

  # doc-writer via /document
  for i in {1..10}; do /document "Update README with test content $i"; done

  # debug-specialist via /debug
  for i in {1..10}; do /debug "Test issue $i"; done

  # test-specialist via /test
  for i in {1..10}; do /test "test_file_$i.sh"; done

  # expansion-specialist via /expand
  for i in {1..10}; do /expand "specs/plans/test.md" "phase_$((i % 5 + 1))"; done

  # collapse-specialist via /collapse
  for i in {1..10}; do /collapse "specs/plans/test/phase_$((i % 5 + 1)).md"; done

  # spec-updater via /implement (plan updates)
  for i in {1..10}; do /implement "specs/plans/test_$i.md"; done

  # code-reviewer via /refactor
  for i in {1..10}; do /refactor ".claude/lib/test_$i.sh"; done

  # complexity-estimator via /expand
  # (already tested with expansion-specialist)

  # plan-expander via /orchestrate
  for i in {1..10}; do /orchestrate "Test workflow $i"; done

  # metrics-specialist via /refactor
  # (already tested with code-reviewer)
  ```
- [ ] Verify 10/10 file creation for each agent
- [ ] Document results in tracking spreadsheet

**Deliverable**:
- [ ] All commands achieve 100% file creation rate (10/10)
- [ ] All agents achieve 100% file creation rate (10/10)
- [ ] Results documented in tracking spreadsheet

---

### Stage 4.2: Parallel Execution Performance (30 minutes)

**Objective**: Verify parallel execution provides expected time savings

**Parallel vs Sequential Timing**:

Tasks:
- [ ] Test /report parallel execution:
  ```bash
  # Parallel (4 subtopics)
  time /report "Comprehensive analysis of microservices, CQRS, event sourcing, and service mesh patterns"
  # Record time: ____ seconds

  # Estimate sequential time: 4 x (single subtopic time)
  # Calculate time savings: ((sequential - parallel) / sequential) * 100
  # Expected: 40-60% time savings
  ```
- [ ] Test /debug parallel execution:
  ```bash
  # Parallel (3 hypotheses)
  time /debug "Complex issue with multiple potential root causes"
  # Record time: ____ seconds

  # Expected: 40-50% time savings vs sequential investigation
  ```
- [ ] Test /orchestrate parallel research:
  ```bash
  # Full workflow with parallel research phase
  time /orchestrate "Complete feature development workflow"
  # Measure research phase time specifically
  # Expected: 50-60% savings in research phase vs sequential
  ```
- [ ] Document time savings in tracking spreadsheet
- [ ] Verify parallelization benefits realized

**Deliverable**:
- [ ] Parallel execution time savings measured
- [ ] Expected 40-60% savings confirmed
- [ ] Results documented

---

### Stage 4.3: Context Window Usage Verification (30 minutes)

**Objective**: Verify context usage remains <30% for orchestrators

**Context Usage Measurement**:

Tasks:
- [ ] Execute /orchestrate full workflow and monitor context:
  ```bash
  /orchestrate "Research authentication → Plan implementation → Implement OAuth2 → Document system" 2>&1 | tee /tmp/orchestrate-context-log.txt
  ```
- [ ] Analyze log for context usage indicators:
  ```bash
  grep -E "(context|metadata|extract_|prune_)" /tmp/orchestrate-context-log.txt
  ```
- [ ] Verify metadata extraction functions used:
  - [ ] `extract_report_metadata` called for research reports
  - [ ] `extract_plan_metadata` called for plans
  - [ ] `prune_subagent_output` called after agent completion
- [ ] Verify no full content passing (only metadata):
  ```bash
  # Should NOT see full report content in orchestrator context
  # SHOULD see: {title, summary, path, key_findings[]}
  ```
- [ ] Execute /report hierarchical pattern and verify context usage:
  ```bash
  /report "Complex topic" 2>&1 | grep -E "metadata" | wc -l
  # Should show multiple metadata extractions
  ```
- [ ] Document context usage patterns
- [ ] Verify <30% usage maintained throughout workflows

**Deliverable**:
- [ ] Context usage verified <30% for orchestrators
- [ ] Metadata-based passing confirmed
- [ ] Context reduction metrics documented

---

### Stage 4 Summary
**Duration**: 2 hours
**Deliverables**:
- [ ] 100% file creation rate verified for all 12 commands
- [ ] 100% file creation rate verified for all 10 agents
- [ ] Parallel execution time savings measured (40-60%)
- [ ] Context window usage verified (<30% for orchestrators)
- [ ] All performance targets met

---

## Stage 5: Documentation Updates (3 hours)

### Overview
Update all relevant documentation to reflect enforcement patterns and migration completion.

### Stage 5.1: Command Documentation Updates (1 hour)

**Objective**: Update command documentation with enforcement patterns

**Tasks**:

- [ ] Update .claude/commands/README.md:
  - [ ] Add "Execution Enforcement Patterns" section
  - [ ] Document Phase 0 role clarification pattern:
    ```markdown
    ## Phase 0: Role Clarification Pattern

    All commands that invoke agents include Phase 0 opening that clarifies:
    - YOUR ROLE: You are the ORCHESTRATOR (not the executor)
    - DO NOT execute yourself using [tools]
    - ONLY use Task tool to delegate to specialized agents
    - Explanation of what orchestration means

    Example: /report command orchestrates research-specialist agents instead of performing research directly.
    ```
  - [ ] Add orchestration vs direct execution distinction:
    ```markdown
    ## Orchestration vs Direct Execution

    Commands use conditional logic to determine execution mode:
    - **Direct Execution**: Simple tasks, direct tool usage
    - **Orchestration**: Complex tasks, Task tool delegation to agents

    Examples:
    - /plan: Simple feature → direct, complex feature → research delegation
    - /implement: Simple phase → direct, complex phase → agent delegation
    ```
  - [ ] Add enforcement pattern reference table:
    ```markdown
    | Pattern | Description | Commands Using |
    |---------|-------------|----------------|
    | Phase 0 | Role clarification | All 12 migrated |
    | Pattern 1 | Path pre-calculation | /report, /plan, /implement, /debug |
    | Pattern 2 | Verification checkpoints | All commands |
    | Pattern 3 | Fallback mechanisms | /report, /plan, /implement |
    | Pattern 4 | Checkpoint reporting | /report, /plan, /implement |
    ```
  - [ ] Add examples showing Phase 0 usage from /report, /plan, /implement

- [ ] Review and verify accuracy of all sections
- [ ] Commit changes with descriptive message

---

### Stage 5.2: Agent Documentation Updates (1 hour)

**Objective**: Update agent documentation with Standard 0.5 compliance examples

**Tasks**:

- [ ] Update .claude/agents/README.md:
  - [ ] Add "Standard 0.5 Compliance" section
  - [ ] Document 5-phase transformation process:
    ```markdown
    ## Standard 0.5: Agent Execution Enforcement

    All agents follow 5-phase transformation for reliable execution:

    ### Phase 1: Role Declaration
    - Transform "I am" to "YOU MUST"
    - Add "PRIMARY OBLIGATION" for file creation
    - Remove all passive language

    ### Phase 2: Sequential Step Dependencies
    - Restructure to "STEP N (REQUIRED BEFORE STEP N+1)" format
    - Add "EXECUTE NOW" markers before critical operations
    - Add "VERIFICATION" blocks after file creation

    ### Phase 3: Passive Voice Elimination
    - Replace should/may/can/could → MUST/WILL/SHALL
    - Ensure all imperatives are strong

    ### Phase 4: Template Enforcement
    - Add "THIS EXACT TEMPLATE (No modifications)" markers
    - Add REQUIRED/MANDATORY markers to sections
    - Specify explicit minimums

    ### Phase 5: Completion Criteria
    - Add "COMPLETION CRITERIA - ALL REQUIRED" section
    - Add checkboxes for verification
    - Add "NON-COMPLIANCE" warnings
    ```
  - [ ] Reference compliant agents with scores:
    ```markdown
    ## Reference Agents (Compliant Models)

    The following agents demonstrate full Standard 0.5 compliance:
    - research-specialist.md (95/100) - Research and reporting
    - plan-architect.md (95/100) - Plan creation
    - code-writer.md (95/100) - Code implementation
    - doc-writer.md (95/100) - Documentation creation
    - debug-specialist.md (95/100) - Bug investigation
    - All Wave 1-4 agents (95-98/100) - Various specializations
    ```
  - [ ] Add "Creating New Agents" section with enforcement checklist

- [ ] Review and verify accuracy
- [ ] Commit changes

---

### Stage 5.3: CHANGELOG and Migration Guide Updates (1 hour)

**Objective**: Document migration completion and lessons learned

**Tasks**:

- [ ] Update CHANGELOG.md:
  - [ ] Add new version entry with migration notes:
    ```markdown
    ## [Version X.Y.Z] - 2025-10-20

    ### Added
    - Execution enforcement patterns for all 12 commands
    - Standard 0.5 compliance for all 10 agents
    - Phase 0 role clarification pattern for orchestration
    - Comprehensive verification checkpoints
    - Fallback mechanisms for file creation

    ### Changed
    - All commands now achieve 100% file creation rates (up from 60-80%)
    - All agents now demonstrate reliable execution
    - Hierarchical patterns now enforce Task delegation
    - Conditional orchestration clarified in /plan and /implement

    ### Performance
    - File creation reliability: 60-80% → 100%
    - Command audit scores: baseline → 95-98/100
    - Agent audit scores: baseline → 95-98/100
    - Context usage: maintained <30% for orchestrators
    - Parallel execution: 40-60% time savings verified

    ### Migration Notes
    - All existing command usage patterns remain backward compatible
    - Agent output formats unchanged (backward compatible)
    - Zero breaking changes introduced
    ```
  - [ ] Document any intentional improvements
  - [ ] Note deprecated patterns (if any)

- [ ] Update .claude/docs/guides/execution-enforcement-migration-guide.md:
  - [ ] Add "Lessons Learned" section:
    ```markdown
    ## Lessons Learned from 077 Migration

    ### Success Factors
    1. **Phase 0 is Critical**: Role clarification addresses root cause
    2. **Test After Each Migration**: Catch issues early
    3. **Use Reference Models**: Consistent pattern application
    4. **Agents Before Commands**: Ensures enforcement foundation
    5. **Track Progress**: Spreadsheet maintained throughout

    ### Common Pitfalls Encountered
    1. Incomplete passive voice elimination (hidden in examples)
    2. Missing verification blocks (file operations without checks)
    3. Template markers not explicit enough
    4. Testing batched instead of per-migration

    ### Recommendations for Future Migrations
    1. Start with audit baseline for all files
    2. Create reference pattern templates first
    3. Test immediately after each migration
    4. Document deviations and reasons
    5. Maintain tracking spreadsheet in real-time
    ```
  - [ ] Update success metrics with actual results from this migration
  - [ ] Document any new patterns discovered during migration
  - [ ] Add troubleshooting tips based on issues encountered

- [ ] Review and verify accuracy
- [ ] Commit changes

---

### Stage 5 Summary
**Duration**: 3 hours
**Deliverables**:
- [ ] .claude/commands/README.md updated with enforcement patterns
- [ ] .claude/agents/README.md updated with Standard 0.5 examples
- [ ] CHANGELOG.md updated with migration notes
- [ ] Migration guide updated with lessons learned
- [ ] All documentation committed and reviewed

---

## Final Deliverables

### Migration Artifacts
- [ ] 4 agents migrated to Standard 0.5 compliance (Wave 3 & 4)
- [ ] All 10 agents scoring ≥95/100 on audit (100% completion)
- [ ] Migration tracking spreadsheet finalized with all results
- [ ] Final migration report created

### Test Results
- [ ] Full test suite passing (zero regressions)
- [ ] Hierarchical patterns verified working
- [ ] Conditional orchestration verified
- [ ] Parallel execution verified (40-60% time savings)
- [ ] Context usage verified (<30%)

### Performance Metrics
- [ ] 100% file creation rate for all 12 commands (10/10 tests each)
- [ ] 100% file creation rate for all 10 agents (10/10 tests each)
- [ ] Parallel execution time savings measured and documented
- [ ] Context window usage validated

### Documentation
- [ ] Command documentation updated
- [ ] Agent documentation updated
- [ ] CHANGELOG updated
- [ ] Migration guide updated with lessons learned

## Success Criteria Verification

- [ ] ✓ All 10 agents migrated with 5-phase transformation
- [ ] ✓ All 10 agents score ≥95/100 on audit script
- [ ] ✓ 100% file creation rate for all agents (10/10 tests)
- [ ] ✓ All existing test suites pass (zero regressions)
- [ ] ✓ System-wide integration tests pass
- [ ] ✓ Hierarchical pattern verified working
- [ ] ✓ Conditional orchestration verified
- [ ] ✓ Performance metrics verified (100% file creation, <30% context)
- [ ] ✓ Documentation updated with new patterns
- [ ] ✓ Migration complete - All 12 commands and 10 agents now compliant

## Notes

### Critical Success Factors
1. **Systematic Testing**: Each agent tested immediately after migration (10 runs each)
2. **Reference Models**: Used compliant agents as templates for transformations
3. **Comprehensive Validation**: System-wide tests ensure no regressions
4. **Performance Verification**: Measured and confirmed 100% file creation rates

### Post-Phase Activities
After Phase 8 completion:
- Monitor file creation rates in production usage
- Track any new enforcement pattern needs
- Consider automated enforcement validation in CI/CD
- Create final migration report for project records

### Migration Timeline
- Week 6: Agent migrations (10 hours)
- Week 6-7: System validation (4 hours) + Regression testing (3 hours)
- Week 7: Performance verification (2 hours) + Documentation (3 hours)
- Total: 22 hours

**Phase 8 marks the completion of the execution enforcement migration, transitioning the entire system from variable file creation rates (60-80%) to systematic enforcement achieving 100% reliability.**
