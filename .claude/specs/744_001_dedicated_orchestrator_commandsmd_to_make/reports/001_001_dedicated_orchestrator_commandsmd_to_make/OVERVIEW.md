# Research Overview: Plan Standards Compliance and Integration Analysis for 001_dedicated_orchestrator_commands.md

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-synthesizer
- **Topic Number**: 744
- **Individual Reports**: 4 reports synthesized
- **Reports Directory**: /home/benjamin/.config/.claude/specs/744_001_dedicated_orchestrator_commandsmd_to_make/reports/001_001_dedicated_orchestrator_commandsmd_to_make/

## Executive Summary

The plan to create 5 dedicated orchestrator commands (/research, /research-plan, /research-revise, /build, /fix) from /coordinate exhibits critical non-compliance with established standards and faces significant integration risks. The proposed "template-based approach" using a 600-800 line template file with substitution markers violates documented library-based reuse patterns and misunderstands the purpose of template-integration.sh (designed for plan templates, not command generation). While the plan achieves 81% alignment with Command Architecture Standards (13/16), it has 3 notable gaps: missing imperative agent invocation enforcement (Standard 11), lacking executable/documentation separation validation (Standard 14), and insufficient bash block size management. State machine library compatibility is strong, but 8 critical feature preservation failure modes threaten adaptive planning integration, hierarchical supervision consistency, and workflow-classifier bypass implications. The plan requires substantial revision to align with documented patterns: abandon template file approach in favor of direct command creation, mandate Standard 11/0.5 enforcement, implement checkpoint migration strategy, and address edge case testing gaps.

## Related Artifacts

**Plan**: [Dedicated Orchestrator Commands Implementation Plan](../../../743_coordinate_command_working_reasonably_well_more/plans/001_dedicated_orchestrator_commands.md)

## Research Structure

1. **[Template System Integration Compliance](./001_template_system_integration_compliance.md)** - Analysis of plan's template-based approach against documented template standards, library API patterns, and structural vs behavioral content distinction
2. **[Command Architecture Standards Alignment](./002_command_architecture_standards_alignment.md)** - Verification of plan compliance with 16 Command Architecture Standards including YAML frontmatter, Phase 0 patterns, imperative invocation, and library sourcing order
3. **[State Machine Library Compatibility](./003_state_machine_library_compatibility.md)** - Assessment of plan's integration with workflow-state-machine.sh, state-persistence.sh, and 6 dependent libraries including sourcing order and API compatibility
4. **[Feature Preservation Failure Modes](./004_feature_preservation_failure_modes.md)** - Risk analysis identifying 8 critical failure modes across adaptive planning, hierarchical supervision, workflow classification bypass, and edge case handling

## Cross-Report Findings

### Critical Standards Violations (Template System)

All four reports identify fundamental misalignment between the plan's "template-based approach" and documented standards:

**Template Architecture Mismatch**: As detailed in [Template System Integration Compliance](./001_template_system_integration_compliance.md) (Finding 1), the plan proposes creating `.claude/templates/state-based-orchestrator-template.md` with manual substitution markers ({{WORKFLOW_TYPE}}), but template-integration.sh is designed for **plan template management** (YAML files in `.claude/commands/templates/`), not command generation. The library provides `list_available_templates()`, `validate_generated_plan()`, and `link_template_to_plan()` - none of which support command file substitution.

**Terminology Confusion**: The plan conflates three distinct concepts (Template System Compliance, Finding 2):
1. **Structural templates** (inline execution patterns like Task blocks) - documented standard for commands
2. **Template files** (YAML plan templates) - managed by template-integration.sh
3. **Command template files** (proposed 600-800 line .md file) - undocumented, conflicts with standards

This confusion appears in [Command Architecture Standards Alignment](./002_command_architecture_standards_alignment.md) where the plan correctly adopts Phase 0 orchestrator patterns (Standard 0) and behavioral injection (Standard 12) but then proposes a template file system inconsistent with library-based reuse strategy documented in library-api.md.

**Recommended Approach**: [Template System Integration Compliance](./001_template_system_integration_compliance.md) Recommendation 1 proposes abandoning the template file approach entirely. Commands should be created directly with 150-200 lines of focused implementation, sharing common logic via library functions (workflow-state-machine.sh, state-persistence.sh). This aligns with how /coordinate, /plan, and /implement are already structured.

### Command Architecture Standards Gaps (3 Critical Areas)

[Command Architecture Standards Alignment](./002_command_architecture_standards_alignment.md) provides comprehensive compliance analysis showing 81% alignment (13/16 standards) with 3 significant gaps:

**Gap 1: Standard 11 Imperative Agent Invocation** (Finding 4, lines 107-122): Plan mentions "behavioral injection pattern" but does NOT explicitly require imperative language enforcement:
- Missing: "EXECUTE NOW: USE the Task tool" prefix
- Missing: No code block wrapper prohibition (```yaml blocks cause 0% delegation rate)
- Missing: Completion signal requirements
- Impact: Without enforcement, template could produce documentation-only YAML blocks, losing 100% file creation reliability (Feature 5)

This gap is echoed in [Feature Preservation Failure Modes](./004_feature_preservation_failure_modes.md) Finding 1.1, which shows the /implement command's sophisticated imperative patterns that risk being lost without explicit template enforcement.

**Gap 2: Standard 14 Executable/Documentation Separation** (Finding 8, lines 189-212): Plan specifies 600-800 line template without guide file creation:
- Template size exceeds simple command target (<250 lines) but is within orchestrator maximum (1,200 lines)
- No specification for creating corresponding guide files (`.claude/docs/guides/command-name-command-guide.md`)
- No validation of size limits post-generation
- Existing infrastructure shows variance: /coordinate (2,466 lines - exceeds maximum), /plan (966 lines), /implement (244 lines)

**Gap 3: Standard 0.5 Subagent Prompt Enforcement** (Finding 5, lines 123-146): Plan does not address agent behavioral file enforcement patterns:
- Missing: "YOU MUST" imperative language requirement
- Missing: Sequential step dependencies ("STEP 1 REQUIRED BEFORE STEP 2")
- Missing: File creation as primary obligation
- Risk: Agents invoked by new commands may not enforce compliance, reducing reliability below 100% target

[Command Architecture Standards Alignment](./002_command_architecture_standards_alignment.md) Recommendation 2 provides the exact template pattern required to mandate Standard 11 and Standard 0.5 enforcement.

### State Machine Library Compatibility (Strong Alignment with 3 Caveats)

[State Machine Library Compatibility](./003_state_machine_library_compatibility.md) demonstrates the plan's strong technical foundation while identifying 3 integration considerations:

**Verified Compatibility** (Findings 1-6): All 6 referenced libraries exist and align with plan architecture:
- workflow-state-machine.sh: 8 core states, STATE_TRANSITIONS table, atomic transitions
- state-persistence.sh: GitHub Actions pattern, 70% performance improvement
- dependency-analyzer.sh, metadata-extraction.sh, verification-helpers.sh, error-handling.sh: All present in .claude/lib/

**sm_init Signature Consistency** (Finding 7, Conflict 1): Plan references sm_init() but doesn't document the 5-parameter refactored signature (commit ce1d29a1):
```bash
sm_init "$WORKFLOW_DESCRIPTION" "$COMMAND_NAME" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "$RESEARCH_TOPICS_JSON"
```
Without explicit signature documentation, template implementers might use old 2-parameter signature. Recommendation 1 provides the required documentation block.

**COMPLETED_STATES Array Persistence** (Finding 7, Conflict 2): Spec 672 Phase 2 added `save_completed_states_to_state()` for cross-bash-block persistence. The plan doesn't specify calling this function after each `sm_transition()`, risking state history loss. Recommendation 2 mandates the persistence pattern.

**Library Version Locking** (Finding 7, Conflict 3): Plan mentions "library compatibility verification script" but libraries lack version numbers. If workflow-state-machine.sh changes sm_init() signature (adds 6th parameter), all 5 new commands break simultaneously. Recommendation 3 proposes semantic versioning with compatibility matrix.

This library dependency coupling is amplified in [Feature Preservation Failure Modes](./004_feature_preservation_failure_modes.md) Finding 4, which identifies breaking changes requiring coordinated migration across all dependent commands.

### Feature Preservation Failure Modes (8 Critical Risks)

[Feature Preservation Failure Modes](./004_feature_preservation_failure_modes.md) provides the most comprehensive risk analysis, identifying failure modes that threaten the plan's core premise of preserving all 6 essential /coordinate features:

**Failure Mode 1: Adaptive Planning Integration Loss** (Finding 1): The /implement command's sophisticated adaptive planning capabilities risk being lost:
- **Auto-Resume** (1.1): Two-tier strategy (checkpoint → most-recent-plan) not fully specified. Plan mentions "auto-resume" but doesn't clarify: safe resume conditions, checkpoint precedence over user-provided plan path, cross-command checkpoint compatibility (/coordinate checkpoint → /build resume?)
- **Checkpoint Recovery Validation** (1.2): Safety checks (checkpoint age <7 days, git clean state, phase boundary consistency) not specified. Missing: which checks apply to /build, how to handle /coordinate checkpoint for research-and-plan workflow
- **Progressive Plan Structure Detection** (1.3): Plans support 3 structure levels (L0/L1/L2). Plan doesn't specify: handling plans mid-migration, whether /build supports all tiers, expanded phase file handling

**Failure Mode 2: Hierarchical Supervision Threshold Inconsistency** (Finding 2): Plan specifies two different thresholds:
- Research phase: Complexity ≥4 topics triggers hierarchical supervision (research-sub-supervisor)
- Implementation phase: Complexity score ≥8 OR task count >10 triggers hierarchical coordination (implementation-researcher)
- Inconsistency creates ambiguity: What happens when research complexity=3 but implementation complexity=9? Which threshold applies to /build command?

Recommendation 2 proposes unified complexity scoring algorithm with threshold ≥8 across all phases.

**Failure Mode 3: Workflow Classifier Bypass Implications** (Finding 3): Eliminating workflow-classifier to save 5-10s latency loses semantic analysis capabilities:
- **Research Topic Generation Loss** (3.1): Classifier performs LLM semantic analysis to generate structured topics (short_name, detailed_description, filename_slug, research_focus). Without classifier, users must manually specify topics for complexity >1, losing semantic decomposition (workflow description → structured research topics).
- **Complexity Override Without Validation** (3.2): Users can override complexity but no validation that workflow description suits requested complexity. Example: "/research 'fix typo in README.md' --complexity 4" (invalid - trivial task with high complexity). Workflow classifier validation rules (reject complexity 4 for single-topic workflows) now lost.

Recommendation 1 proposes heuristic-based topic generation fallback to replace semantic analysis.

**Failure Mode 4: State Machine Library Dependency Coupling** (Finding 4): Breaking changes to libraries require coordinated migration:
- **API Stability** (4.1): If sm_init() signature changes (adds 6th parameter), all 5 commands break simultaneously. No version locking or compatibility layer specified.
- **State Persistence Format Changes** (4.2): If state-persistence.sh migrates from GitHub Actions format to JSON file format, checkpoints become unreadable. No state format versioning (state file has no version field).

Cross-references [State Machine Library Compatibility](./003_state_machine_library_compatibility.md) Recommendation 3 for version locking implementation.

**Failure Mode 5: Backward Compatibility Maintenance Gaps** (Finding 5): Phase 7 backward compatibility specification insufficient:
- **Deprecation Timeline Not Specified** (5.1): Is /coordinate immediately deprecated or soft-deprecated? Timeline for removal? What happens to existing checkpoints?
- **Checkpoint Migration Strategy Missing** (5.2): Can /build resume from /coordinate checkpoint with workflow_type="full-implementation"? Cross-command checkpoint compatibility not addressed.
- **Feature Parity Validation Gap** (5.3): Phase 7 says "verify /coordinate still functional" but doesn't require A/B testing against /coordinate baseline (performance parity, user experience parity).

Recommendation 4 proposes comprehensive checkpoint migration utility with compatibility matrix.

**Failure Modes 6-8**: Additional edge case risks include workflow scope detection pattern incompatibility (Finding 6: /revise auto-mode integration), phase conditional execution complexity (Finding 7: debug loop prevention, partial test failures, document phase skipping), and test suite integration gaps (Finding 8: multiple test frameworks, parametrized commands, non-standard patterns).

Recommendation 5 proposes 15-test edge case suite (5 branching + 4 checkpoint + 6 test discovery).

### Contradictions Between Documentation and Implementation

**Template System Purpose**: [Template System Integration Compliance](./001_template_system_integration_compliance.md) Finding 1 shows template-integration.sh provides `list_available_templates()`, `validate_generated_plan()`, `link_template_to_plan()` for **plan template management**, but plan proposes command template file with manual substitution markers. This fundamental mismatch suggests plan author wasn't aware of library's actual capabilities.

**Library Reuse vs Template Generation**: [Command Architecture Standards Alignment](./002_command_architecture_standards_alignment.md) Finding 5 (lines 174-219) identifies hybrid approach: plan CORRECTLY uses library-based reuse for state machine functionality at runtime, but proposes TEMPLATE-BASED approach for command generation at development time. This creates maintenance burden: 5 nearly-identical 600-800 line command files that all break when library APIs change.

Better approach documented in library-api.md: Create commands by hand-coding small differences (workflow_type, terminal_state, phase conditions) and sharing everything else via libraries. This is how /coordinate, /supervise, /orchestrate are already structured.

### Synergies Between Reports for Integrated Solution

**Synergy 1: Direct Command Creation + Standards Enforcement**
- [Template System Integration Compliance](./001_template_system_integration_compliance.md) Recommendation 1: Abandon template file, create commands directly (150-200 lines vs 600-800)
- [Command Architecture Standards Alignment](./002_command_architecture_standards_alignment.md) Recommendation 2: Mandate Standard 11/0.5 enforcement in command structure
- **Integrated Approach**: Create focused command files with explicit imperative patterns, no template substitution overhead

**Synergy 2: Library Versioning + Checkpoint Migration**
- [State Machine Library Compatibility](./003_state_machine_library_compatibility.md) Recommendation 3: Implement library semantic versioning with compatibility matrix
- [Feature Preservation Failure Modes](./004_feature_preservation_failure_modes.md) Recommendation 4: Design checkpoint migration utility with format versioning
- **Integrated Approach**: Unified versioning strategy (library versions + state format versions + checkpoint versions) enables gradual migration and rollback

**Synergy 3: Standards Validation + Edge Case Testing**
- [Command Architecture Standards Alignment](./002_command_architecture_standards_alignment.md) Recommendation 4: Add standards compliance validation to Phase 6 (16/16 standards)
- [Feature Preservation Failure Modes](./004_feature_preservation_failure_modes.md) Recommendation 5: Extend Phase 6 with 15-test edge case suite
- **Integrated Approach**: Comprehensive validation framework (standards compliance + edge case testing + feature parity validation) ensures robustness

## Detailed Findings by Topic

### 1. Template System Integration Compliance

The plan's template-based approach exhibits CRITICAL non-compliance with documented standards. Key findings:

**Finding 1.1 - Template Architecture Mismatch**: Plan proposes `.claude/templates/state-based-orchestrator-template.md` with manual substitution markers ({{WORKFLOW_TYPE}}), but template-integration.sh library is designed for plan template management (YAML files in `.claude/commands/templates/`), not command generation. Library functions (`list_available_templates()`, `validate_generated_plan()`, `link_template_to_plan()`) have NO support for command file substitution.

**Finding 1.2 - Terminology Confusion**: Plan conflates "structural templates" (inline execution patterns like Task blocks), "template files" (YAML plan templates), and "command template files" (proposed 600-800 line .md file). This creates confusion between documented template system (plan templates) and proposed undocumented system (command templates).

**Finding 1.3 - Missing Library Integration**: Plan proposes custom substitution mechanism ({{WORKFLOW_TYPE}}, {{TERMINAL_STATE}}, etc.) with no connection to template-integration.sh. Library provides NO functions for command file substitution, marker replacement, or workflow type parameterization.

**Finding 1.4 - Version Management Overhead**: Plan introduces template versioning (v1.0.0, CHANGELOG.md, compatibility matrix) without aligning to existing template standards. Template-integration.sh has NO versioning system for templates, adds significant maintenance burden tracking library versions and migration paths.

**Finding 1.5 - Command Generation Strategy Misalignment**: Plan's "copy template and substitute markers" approach contradicts library-based reuse strategy. Standard approach is library reuse at runtime (source shared functions), not template copy-paste at development time.

**Finding 1.6 - Validation Failure Modes**: Plan relies on manual validation ("verify all markers resolved") without tooling support. Potential failures: partial substitution (developer forgets marker), invalid values (wrong workflow type), conditional logic errors (removes wrong phase sections), version drift (template/library mismatch).

**Recommendations**: Abandon template file approach entirely, create commands directly (150-200 lines), document command development pattern (not template system), use /coordinate as living reference, remove template versioning.

[Full Report](./001_template_system_integration_compliance.md)

### 2. Command Architecture Standards Alignment

The plan demonstrates 81% compliance (13/16 standards) with 3 notable gaps. Key findings:

**Finding 2.1 - Command Naming Conflicts**: Plan proposes /report, /research-plan, /research-revise, /build, /fix but overlapping commands already exist (/research, /plan, /revise, /implement, /debug). Creates namespace conflicts and command proliferation (20 → 25 commands vs 20 → 20 enhanced commands).

**Finding 2.2 - YAML Frontmatter Compliance**: Plan correctly specifies YAML frontmatter (allowed-tools, argument-hint, description, command-type, dependent-agents) matching existing standards. Full compliance with Standard metadata requirements.

**Finding 2.3 - Phase 0 Orchestrator Pattern**: Plan explicitly includes Phase 0 initialization pattern (pre-calculate artifact paths, determine topic directory, export for subagent injection), matching Standard 0 requirement. Adopts proven two-step pattern from /coordinate.

**Finding 2.4 - Standard 11 Gap (CRITICAL)**: Plan does NOT explicitly require imperative language in Task invocations ("EXECUTE NOW", "USE the Task tool", no YAML code block wrappers). Without imperative enforcement, template could produce 0% delegation rate (the exact problem Standard 11 prevents).

**Finding 2.5 - Standard 0.5 Gap (CRITICAL)**: Plan does NOT address agent behavioral file enforcement patterns ("YOU MUST", "STEP 1 REQUIRED BEFORE STEP 2", file creation as primary obligation). Risk: agents may not have strong enforcement, reducing file creation reliability.

**Finding 2.6 - Structural/Behavioral Separation**: Plan correctly separates orchestrator logic (inline in commands) from agent behavior (referenced via behavioral injection). Compliance with Standard 12.

**Finding 2.7 - Project Directory Detection**: Plan explicitly includes Standard 13 CLAUDE_PROJECT_DIR detection inline, matching existing command pattern.

**Finding 2.8 - Standard 14 Gap (SIGNIFICANT)**: Plan specifies 600-800 line template without guide file creation or size validation. Missing: corresponding guide files, cross-reference requirements, bash block sectioning strategy (no block >300 lines).

**Finding 2.9 - Library Sourcing Order**: Plan correctly references state machine initialization (requires workflow-state-machine.sh sourced first), includes "library compatibility verification script" suggesting awareness of sourcing dependencies.

**Finding 2.10 - Standard 16 Gap (PARTIAL)**: Plan mentions "verification checkpoints" but does NOT explicitly require return code checking for critical functions like sm_init(). Missing "if ! sm_init" pattern that prevents silent failures.

**Compliance Matrix**: 5/8 major standards fully compliant (62.5%), 3 significant gaps (Standards 0.5, 11, 14).

**Recommendations**: Align command naming with existing infrastructure (enhance existing 5 commands vs create 5 new), mandate Standard 11/0.5 enforcement in template, enforce Standard 14 executable/doc separation, add standards compliance validation to Phase 6, clarify bash block size management, enhance metadata specification for command dependencies.

[Full Report](./002_command_architecture_standards_alignment.md)

### 3. State Machine Library Compatibility

The plan demonstrates strong compatibility with existing state machine libraries while requiring 3 integration considerations. Key findings:

**Finding 3.1 - State Machine Architecture Verification**: All 6 referenced libraries exist and conform to standards (workflow-state-machine.sh: 400+ lines with 8 core states, state-persistence.sh: GitHub Actions pattern with 70% performance improvement, dependency-analyzer.sh, metadata-extraction.sh, verification-helpers.sh, error-handling.sh).

**Finding 3.2 - Library Sourcing Order**: Plan correctly identifies sourcing order requirement (state machine libraries BEFORE load_workflow_state). No circular dependencies detected. Recommended pattern: state-persistence.sh first, then workflow-state-machine.sh (matches /coordinate pattern).

**Finding 3.3 - State Machine Integration Patterns**: Plan proposes hardcoding WORKFLOW_TYPE and TERMINAL_STATE per command. sm_init refactored signature (5 parameters: description, command_name, workflow_type, research_complexity, research_topics_json from commit ce1d29a1) supports this approach. Dedicated commands can skip workflow-classifier by providing hardcoded WORKFLOW_TYPE.

**Finding 3.4 - State Persistence Compatibility**: All 6 essential /coordinate features rely on state-persistence.sh. GitHub Actions pattern provides selective persistence (7 critical items), graceful degradation (fallback to recalculation), atomic writes (JSON checkpoint with temp file + mv). COMPLETED_STATES array persistence critical (Spec 672 Phase 2 implementation).

**Finding 3.5 - Directory Organization Compliance**: All 6 referenced libraries exist in correct location (.claude/lib/), follow source guard pattern, use kebab-case naming convention. No monolithic utils.sh anti-pattern.

**Finding 3.6 - State-Based Orchestration Integration**: Plan aligns with 8 explicit states, validated transitions (STATE_TRANSITIONS table), selective state persistence (GitHub Actions pattern), hierarchical supervisor coordination (95.6% context reduction). Hardcoded workflow types (research-only, research-and-plan, research-and-revise, full-implementation, debug-only) all compatible with existing transition table.

**Finding 3.7 - Compatibility Considerations**: Three conflicts require attention:
- **sm_init Signature**: Plan doesn't explicitly document 5-parameter refactored signature, risking old 2-parameter usage
- **COMPLETED_STATES Persistence**: Plan doesn't specify calling save_completed_states_to_state() after sm_transition(), risking state history loss
- **Library Version Locking**: No version locking mechanism specified, breaking changes could break all 5 commands simultaneously

**Recommendations**: Explicit sm_init signature documentation (5 parameters with descriptions), COMPLETED_STATES persistence pattern (after every transition), library version locking with semantic versioning, two-stage verification pattern preservation, library sourcing order enforcement, hierarchical supervision threshold documentation, state machine transition validation tests.

[Full Report](./003_state_machine_library_compatibility.md)

### 4. Feature Preservation Failure Modes

Eight critical failure modes threaten feature preservation across integration risks, backward compatibility, and edge cases. Key findings:

**Finding 4.1 - Adaptive Planning Integration Risks**: /implement command's sophisticated adaptive planning capabilities risk being lost or inconsistently implemented:
- Auto-resume two-tier strategy (checkpoint → most-recent-plan) not fully specified
- Checkpoint recovery validation (age <7 days, git clean state, phase boundaries) missing specifications
- Progressive plan structure detection (L0/L1/L2 tiers) handling not addressed

**Finding 4.2 - Hierarchical Supervision Threshold Inconsistency**: Plan specifies conflicting thresholds (research: ≥4 topics, implementation: ≥8 complexity score OR >10 tasks), creating user-facing inconsistency and ambiguous behavior when research complexity=3 but implementation complexity=9.

**Finding 4.3 - Workflow Classifier Bypass Implications**: Eliminating workflow-classifier loses semantic analysis capabilities:
- Research topic generation (LLM semantic decomposition: workflow description → structured topics with short_name, detailed_description, filename_slug, research_focus)
- Complexity override validation (reject complexity 4 for single-topic workflows, ensure topic count matches complexity)

**Finding 4.4 - State Machine Library Dependency Coupling**: Breaking changes require coordinated migration:
- API stability: sm_init() signature change breaks all 5 commands simultaneously
- State persistence format changes: migration from GitHub Actions to JSON format makes checkpoints unreadable
- No version locking, compatibility layer, or migration guide specified

**Finding 4.5 - Backward Compatibility Maintenance Gaps**: Phase 7 specification insufficient:
- Deprecation timeline not specified (immediate vs soft-deprecated, removal timeline, checkpoint handling)
- Checkpoint migration strategy missing (can /build resume from /coordinate checkpoint?)
- Feature parity validation gap (no A/B testing against /coordinate baseline)

**Finding 4.6 - Workflow Scope Detection Pattern Incompatibility**: New commands hardcode workflow type but /revise expects dynamic scope detection. How does /revise know which plan to revise, whether to update structure, what workflow context to use when invoked by /build in auto-mode?

**Finding 4.7 - Phase Conditional Execution Complexity**: Edge cases not covered:
- Debug loop prevention (max 2 attempts - how tracked across bash blocks?)
- Partial test failures (50% pass rate - continue to document or debug?)
- Document phase skipping (no changes needed - auto-skip or error?)
- Resume from mid-phase interruption (checkpoint between debug attempt 1 and 2?)

**Finding 4.8 - Test Suite Integration Gaps**: Test execution patterns vary but plan assumes standardization:
- Multiple test frameworks (npm test + pytest + e2e_tests.sh - which runs?)
- Parametrized test commands (pytest -k test_auth - full command or just pytest?)
- Non-standard test patterns (make test, cargo test - silently skipped?)
- Test environment setup (DB_URL required - who provides?)

**Recommendations**: Implement research topic auto-generation fallback (heuristic-based decomposition), specify hierarchical supervision threshold unification (unified complexity scoring ≥8), add library version locking with compatibility matrix, design cross-command checkpoint migration utility, add comprehensive edge case test suite (15 tests: 5 branching + 4 checkpoint + 6 test discovery).

[Full Report](./004_feature_preservation_failure_modes.md)

## Recommended Approach

Based on synthesis of all four reports, the following integrated approach addresses identified gaps while preserving plan's core strengths:

### 1. Abandon Template File Approach, Use Direct Command Creation

**Rationale**: Template file approach (600-800 lines with substitution markers) adds complexity without benefit, violates documented library-based reuse patterns.

**Implementation**:
1. Create each command file directly in `.claude/commands/[name].md` (150-200 lines)
2. Write unique parts explicitly (workflow_type, terminal_state, phase conditions)
3. Share common logic via library functions (already in plan)
4. Use /coordinate as reference implementation, not template source

**Evidence**: [Template System Integration Compliance](./001_template_system_integration_compliance.md) Finding 1 shows template-integration.sh designed for plan templates, not command generation. [Command Architecture Standards Alignment](./002_command_architecture_standards_alignment.md) Finding 5 identifies library reuse (runtime) vs template generation (development time) hybrid as unnecessary complexity.

### 2. Mandate Standard 11 and Standard 0.5 Enforcement in Command Structure

**Rationale**: Without imperative enforcement, commands risk 0% delegation rate and <100% file creation reliability.

**Implementation**:
1. Every Task invocation preceded by "EXECUTE NOW: USE the Task tool"
2. No YAML code block wrappers (```yaml prohibited)
3. Agent behavioral file reference mandatory ("Read and follow: .claude/agents/[name].md")
4. Completion signal required ("Return: REPORT_CREATED: ${REPORT_PATH}")
5. Apply Standard 0.5 patterns in agent files ("YOU MUST", "STEP N REQUIRED BEFORE STEP N+1")

**Evidence**: [Command Architecture Standards Alignment](./002_command_architecture_standards_alignment.md) Findings 4-5 identify Standard 11/0.5 gaps. [Feature Preservation Failure Modes](./004_feature_preservation_failure_modes.md) Finding 1.1 shows /implement's imperative patterns at risk without explicit enforcement.

### 3. Implement Library Version Locking and Checkpoint Migration Strategy

**Rationale**: Prevents breaking changes from impacting commands simultaneously, enables seamless user transition from /coordinate.

**Implementation**:
1. Add semantic versioning to all libraries (workflow-state-machine.sh ≥ v2.0.0)
2. Include compatibility matrix in command metadata (template-version → library versions)
3. Create checkpoint migration utility (.claude/lib/checkpoint-migration.sh)
4. Implement checkpoint format versioning (checkpoint_version: "2.0.0")
5. Support cross-command resume (/coordinate checkpoint → /build resume)

**Evidence**: [State Machine Library Compatibility](./003_state_machine_library_compatibility.md) Conflict 3 identifies version locking gap. [Feature Preservation Failure Modes](./004_feature_preservation_failure_modes.md) Finding 5 details backward compatibility maintenance gaps requiring migration strategy.

### 4. Unify Hierarchical Supervision Threshold and Replace Workflow Classifier

**Rationale**: Consistent user experience, maintains semantic decomposition capability lost by classifier removal.

**Implementation**:
1. Implement unified complexity scoring algorithm (threshold ≥8 across all phases)
2. Create heuristic-based topic generation fallback (extract nouns, split on conjunctions, match complexity count)
3. Support user override syntax (--topics flag for explicit specification)
4. Validate topic count matches complexity (fail-fast with helpful error)

**Evidence**: [Feature Preservation Failure Modes](./004_feature_preservation_failure_modes.md) Findings 2-3 identify threshold inconsistency and classifier bypass implications. Unified approach resolves both issues.

### 5. Add Comprehensive Validation Framework to Phase 6

**Rationale**: Proactive issue discovery, regression prevention, clear behavior specification.

**Implementation**:
1. Standards compliance validation (16/16 standards via existing validation scripts)
2. Edge case test suite (15 tests: 5 branching + 4 checkpoint + 6 test discovery)
3. Feature parity validation (A/B testing vs /coordinate baseline)
4. Library compatibility verification (version checks, API signature validation)
5. Checkpoint migration testing (cross-command resume scenarios)

**Evidence**: [Command Architecture Standards Alignment](./002_command_architecture_standards_alignment.md) Finding 16 identifies validation gap. [Feature Preservation Failure Modes](./004_feature_preservation_failure_modes.md) Finding 5.3 highlights feature parity validation need.

### 6. Align Command Naming with Existing Infrastructure

**Rationale**: Reduces command proliferation, maintains namespace clarity, leverages existing discovery.

**Implementation**:
1. Enhance existing 5 commands instead of creating 5 new:
   - /research with optional --plan flag (research-and-plan workflow)
   - /plan with optional --implement flag (full-implementation workflow)
   - /implement with auto-detect starting phase (resume from plan)
   - /revise with workflow detection (plan vs report revision)
   - /debug with optional --plan flag (debug-with-plan workflow)
2. Alternative: Rename proposed commands to avoid conflicts

**Evidence**: [Command Architecture Standards Alignment](./002_command_architecture_standards_alignment.md) Finding 1 identifies namespace conflicts. Recommendation 1 proposes enhancement approach (20 → 20 commands vs 20 → 25).

### 7. Document Command Development Pattern Instead of Template System

**Rationale**: Teaches pattern without prescribing exact implementation, easier to maintain.

**Implementation**:
1. Create `.claude/docs/guides/creating-orchestrator-commands.md`
2. Document 5 essential sections (workflow capture, state machine init, phase implementations, verification checkpoints, terminal state handling)
3. Provide code snippets for each section (not full template)
4. Reference existing commands as examples (/coordinate, /plan, /implement)

**Evidence**: [Template System Integration Compliance](./001_template_system_integration_compliance.md) Recommendation 2 proposes guide-based documentation. Aligns with existing guide-based documentation pattern.

## Constraints and Trade-offs

### Primary Constraint: Template System Violation vs Development Velocity

**Constraint**: Plan's template-based approach violates documented standards but offers faster initial development (copy-paste 5 commands in 2 hours vs hand-craft in 8 hours).

**Trade-off Analysis**:
- **Short-term**: Template approach faster initially (2h vs 8h Phase 2-5)
- **Long-term**: Direct creation reduces maintenance burden (1 command file to update vs 5 identical files + 1 template)
- **Standards alignment**: Direct creation aligns with documented patterns, template approach requires new documentation

**Recommendation**: Accept short-term development time increase (8h) for long-term maintainability and standards alignment. Template approach's 6h savings in Phase 2-5 negated by Phase 1 template development time (4h), resulting in net 2h savings vs 8h technical debt.

### Secondary Constraint: Workflow Classifier Removal vs User Experience

**Constraint**: Removing workflow-classifier saves 5-10s latency but loses semantic topic generation, requiring users to manually specify topics.

**Trade-off Analysis**:
- **Performance**: 5-10s latency reduction per workflow (immediate user benefit)
- **Usability**: Manual topic specification increases cognitive load (long-term user cost)
- **Quality**: Heuristic generation less accurate than LLM semantic analysis (reduced topic quality)

**Mitigation**: Implement heuristic-based topic generation fallback (Recommendation 1 from [Feature Preservation Failure Modes](./004_feature_preservation_failure_modes.md)). Provides automatic decomposition (reduces cognitive load) while maintaining latency benefit. Users can override with --topics flag for precision.

### Tertiary Constraint: Library Version Locking vs Upgrade Flexibility

**Constraint**: Locking commands to specific library versions prevents breaking changes but delays library upgrades.

**Trade-off Analysis**:
- **Stability**: Version locking prevents silent breakage (high value for production workflows)
- **Flexibility**: Locked versions delay adopting library improvements (moderate cost)
- **Complexity**: Version management adds 50-100 lines of semver comparison logic (one-time cost)

**Recommendation**: Implement version locking with broad compatibility ranges (>=2.0.0,<3.0.0). Allows minor version upgrades (bug fixes, features) while preventing major version breaking changes. Gradual migration supported (old commands use v2.x, new commands use v3.x during transition).

### Quaternary Constraint: Command Proliferation vs Workflow Specificity

**Constraint**: Creating 5 dedicated commands (plan approach) vs enhancing 5 existing commands (alternative).

**Trade-off Analysis**:
- **Plan Approach** (5 new commands):
  - Pros: Workflow specificity (each command optimized for one workflow), latency reduction (no classification)
  - Cons: Command proliferation (20 → 25 commands), namespace conflicts, user confusion (when to use /research vs /research-plan?)

- **Alternative Approach** (enhance existing 5):
  - Pros: Namespace clarity (20 commands maintained), user familiarity (existing command names), gradual migration (flag-based enhancement)
  - Cons: Command complexity (flags increase cognitive load), potential behavioral changes (existing users impacted)

**Recommendation**: [Command Architecture Standards Alignment](./002_command_architecture_standards_alignment.md) Recommendation 1 proposes alternative approach. Evaluate user feedback on command proliferation vs flag complexity before committing to plan approach.

## Integration Points and Dependencies

### Critical Path Dependencies

1. **Library Versioning → Command Development**: Library semantic versioning (Recommendation 3) must complete before Phase 2-5 command creation to enable version locking in command metadata.

2. **Standards Enforcement → Template Design**: If plan retains template approach despite recommendations, Standard 11/0.5 enforcement (Recommendation 2) must integrate into template structure before Phase 1 completion.

3. **Checkpoint Migration → Backward Compatibility**: Checkpoint migration utility (Recommendation 4) must complete before Phase 7 backward compatibility testing to validate cross-command resume scenarios.

### Non-Critical Dependencies

1. **Topic Generation → Classifier Removal**: Heuristic topic generation (Recommendation 1) optional if workflow-classifier retained. Classifier provides superior semantic analysis at 5-10s latency cost.

2. **Edge Case Testing → Feature Validation**: Edge case test suite (Recommendation 5) enhances but doesn't block feature validation. Core feature preservation testable without edge case coverage.

3. **Command Naming → Infrastructure**: Command naming alignment (Recommendation 6) independent of other recommendations. Can evaluate naming approach (5 new vs enhance 5 existing) separately from implementation approach.

### External Dependencies

1. **template-integration.sh Library**: Current implementation supports plan templates only. If plan requires command template support, library must be extended (breaking change requiring documentation update).

2. **workflow-state-machine.sh Stability**: Plan assumes state machine API stability (sm_init signature, STATE_TRANSITIONS table). Breaking changes require coordinated migration across all 5+ commands.

3. **Existing Command Infrastructure**: /coordinate, /plan, /implement, /revise, /debug serve as reference implementations. Changes to these commands may impact plan's pattern references.

## References

### Individual Research Reports

- [001_template_system_integration_compliance.md](./001_template_system_integration_compliance.md) - 396 lines, 6 findings, 5 recommendations
- [002_command_architecture_standards_alignment.md](./002_command_architecture_standards_alignment.md) - 609 lines, 16 findings, 6 recommendations, Standards Compliance Matrix
- [003_state_machine_library_compatibility.md](./003_state_machine_library_compatibility.md) - 336 lines, 7 findings, 7 recommendations
- [004_feature_preservation_failure_modes.md](./004_feature_preservation_failure_modes.md) - 1,105 lines, 8 findings, 5 recommendations

### Key Standards Documentation

- `/home/benjamin/.config/.claude/docs/reference/template-vs-behavioral-distinction.md` - Structural templates definition
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` - 16 Command Architecture Standards (2,572 lines)
- `/home/benjamin/.config/.claude/docs/reference/library-api.md` - Library function reference (1,330 lines)
- `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md` - Complete state machine architecture (1,747 lines)

### Library Files

- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` - 8 core states, STATE_TRANSITIONS table, 400+ lines
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` - GitHub Actions pattern, 200+ lines
- `/home/benjamin/.config/.claude/lib/template-integration.sh` - Plan template management (370 lines)
- `/home/benjamin/.config/.claude/lib/dependency-analyzer.sh`, `metadata-extraction.sh`, `verification-helpers.sh`, `error-handling.sh`

### Existing Commands

- `/home/benjamin/.config/.claude/commands/coordinate.md` - Reference implementation (2,466 lines)
- `/home/benjamin/.config/.claude/commands/plan.md` - Planning workflow (966 lines)
- `/home/benjamin/.config/.claude/commands/implement.md` - Implementation workflow with adaptive planning (244 lines)
- `/home/benjamin/.config/.claude/commands/revise.md` - Revision workflow with auto-mode
- `/home/benjamin/.config/.claude/commands/research.md` - Research-only workflow (997 lines)

### Plan Under Review

- `/home/benjamin/.config/.claude/specs/743_coordinate_command_working_reasonably_well_more/plans/001_dedicated_orchestrator_commands.md` - 585 lines, 7 phases, proposes 5 dedicated commands

### Cross-References

- [Adaptive Planning Guide](.claude/docs/workflows/adaptive-planning-guide.md) - Checkpoint recovery, progressive plan structure (477 lines)
- [Directory Organization](.claude/docs/concepts/directory-organization.md) - Library placement standards (276 lines)
- [Command Reference](.claude/docs/reference/command-reference.md) - Catalog of 20 active commands (582 lines)
