# Implementation Gaps in Plan Phases

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: Implementation Gaps Analysis - Plan Phases vs Research Recommendations
- **Report Type**: gap analysis
- **Overview Report**: [OVERVIEW.md](OVERVIEW.md)
- **Related Reports**:
  - [Missing Recommendations from Overview](001_missing_recommendations_from_overview.md)
  - [Standards Inconsistencies in Behavioral Injection](003_standards_inconsistencies_in_behavioral_injection.md)
  - [Documentation Tension Between Robustness Patterns](004_documentation_tension_between_robustness_patterns.md)

## Executive Summary

The implementation plan for the /plan command refactor contains 7 phases with 127.5 complexity score, but critical gaps exist between research report recommendations and planned implementation tasks. Major gaps include: (1) missing subprocess architecture decision despite coordinate fragility findings recommending standalone script extraction, (2) incomplete error handling strategy missing defensive defaults recommendation, (3) missing template selection system despite feature type analysis recommendations, (4) no hierarchical supervision pattern for research delegation despite 4+ topic coordination findings, (5) incomplete validation library scope missing phase dependency validation via Kahn's algorithm, and (6) missing context pruning implementation despite 95% reduction recommendations.

## Findings

### Gap 1: Subprocess Architecture Strategy Not Addressed

**Research Finding** (Report 001 - Coordinate Fragility, Recommendation 1):
> Extract Stateful Orchestration Logic to Standalone Script: Move core orchestration to `.claude/scripts/coordinate-orchestrator.sh` executable script. Execute via single `bash coordinate-orchestrator.sh "$WORKFLOW_DESCRIPTION"` call. Eliminates subprocess boundaries - single process retains all state. Reduces maintenance burden by 70%.

**Plan Implementation** (Phase 1: Core Command Structure):
- Tasks focus on bash blocks within plan.md command file (lines 226-243)
- Uses workflow-state-machine.sh and state-persistence.sh libraries (Standard 15 sourcing)
- Initializes workflow state using init_workflow_state("plan_$$")
- NO decision documented on whether to use multi-bash-block pattern or standalone script

**Gap Analysis**:
1. Plan does NOT address fundamental architectural decision: inline bash blocks vs standalone script
2. If using bash blocks, plan inherits coordinate's subprocess isolation constraints
3. If using standalone script, state-persistence.sh becomes unnecessary (single process)
4. Research explicitly recommends standalone script for 70% maintenance reduction
5. Plan tasks assume bash blocks pattern without justification

**Impact**: High - affects all subsequent phases. Multi-bash-block approach requires state persistence overhead (12ms per workflow), verification checkpoints (50+ locations), and stateless recalculation patterns. Standalone script eliminates these requirements.

**Recommendation**: Add Phase 0.5 "Architectural Decision" to evaluate:
- Standalone script (.claude/scripts/plan-orchestrator.sh) vs bash blocks
- State persistence requirements if bash blocks chosen
- Tradeoffs: simplicity (standalone) vs SlashCommand integration (bash blocks)

### Gap 2: Error Handling Strategy Incomplete

**Research Finding** (Report 001 - Coordinate Fragility, Recommendation 5):
> Replace Fail-Fast Checkpoints with Defensive Defaults: Use `CLASSIFICATION_JSON="${CLASSIFICATION_JSON:-$(generate_default_classification "$WORKFLOW_DESC")}"` pattern. Reserve fail-fast for truly unrecoverable conditions (file permissions, missing dependencies). Reduces verification code by 60%.

**Plan Implementation** (Phase 1: Core Command Structure):
- Line 235: "Add error context enrichment (agent name, expected artifact, diagnostic hints)"
- Line 237: "Add comprehensive inline comments explaining patterns and standards compliance"
- Uses fail-fast verification pattern from optimize-claude (Phase 3, 5, 6 verification checkpoints)

**Gap Analysis**:
1. Plan adopts optimize-claude's fail-fast pattern (MANDATORY VERIFICATION after critical operations)
2. Does NOT implement defensive defaults recommendation from coordinate fragility analysis
3. Research shows 90% of checkpoints verify variables exist (could use sensible defaults)
4. Plan creates verification overhead without evaluating defensive default alternative
5. No decision matrix: when to fail-fast vs when to use defensive defaults

**Impact**: Medium - affects code complexity and user experience. Fail-fast approach requires perfect state setup (harder testing), while defensive defaults enable graceful degradation.

**Recommendation**: Add Phase 1 task:
- "Implement hybrid error handling: defensive defaults for recoverable conditions (missing metadata → generate from heuristics), fail-fast for unrecoverable conditions (missing dependencies, file permissions)"
- Document decision matrix in inline comments

### Gap 3: Template Selection System Missing

**Research Finding** (Report 003 - Current Plan Implementation, Opportunity 3):
> Template Selection System: Create template library (.claude/commands/templates/feature.md, bugfix.md, refactor.md, architecture.md, database.md). Selection logic analyzes feature description (type, domain, complexity) to match template. Plans tailored to feature type, reducing boilerplate.

**Plan Implementation** (Phase 2: Feature Analysis):
- Lines 276-286: analyze_feature_description() returns JSON with estimated_complexity, suggested_phases, template_type, keywords
- NO implementation of template selection system in any phase
- Phase 5 (Plan-Architect Agent Invocation) uses single uniform template

**Gap Analysis**:
1. Feature analysis IDENTIFIES template_type but plan does NOT use it
2. Research recommends 5 specialized templates (feature, bugfix, refactor, architecture, database)
3. Plan-architect agent invoked with single template for all feature types
4. Template_type field in JSON becomes dead data
5. Opportunity for 40-60% boilerplate reduction lost

**Impact**: Medium - affects plan quality and user productivity. Specialized templates improve plan relevance and reduce manual editing.

**Recommendation**: Add Phase 5.5 "Template Selection and Application":
- Create `.claude/commands/templates/` directory structure
- Implement template selection logic based on analyze_feature_description() output
- Pass selected template path to plan-architect agent
- Update plan-architect behavioral file to support template variable substitution

### Gap 4: Hierarchical Supervision Pattern Not Implemented

**Research Finding** (Report 004 - Context Preservation, Recommendation 6):
> Implement Hierarchical Supervision: For 4+ parallel subagents, use supervisor pattern. Invoke research-sub-supervisor agent to coordinate workers. 95% context reduction (metadata aggregation instead of full outputs). Scalable to N subagents without context explosion.

**Plan Implementation** (Phase 3: Research Delegation):
- Lines 334-335: "Implement parallel agent invocation (1-4 agents based on RESEARCH_COMPLEXITY, 40-60% time savings)"
- NO mention of hierarchical supervision pattern
- NO research-sub-supervisor agent invocation
- Direct invocation of 1-4 research-specialist agents

**Gap Analysis**:
1. Plan implements flat parallel invocation (1-4 research agents)
2. Does NOT implement hierarchical supervision for RESEARCH_COMPLEXITY ≥4
3. Research shows supervisor pattern achieves 95% context reduction for 4+ agents
4. Coordinate command uses research-sub-supervisor at complexity ≥4 (lines 702-718)
5. Plan will accumulate full agent outputs instead of aggregated metadata (context explosion risk)

**Impact**: High for complex features - context limit errors likely for 4+ research topics. Supervisor pattern prevents this.

**Recommendation**: Add Phase 3 task:
- "Implement hierarchical supervision: if RESEARCH_COMPLEXITY ≥4, invoke research-sub-supervisor agent instead of direct parallel invocation"
- "Load aggregated metadata from supervisor checkpoint (95% context reduction)"
- Reference: coordinate.md:702-718, research-sub-supervisor.md behavioral file

### Gap 5: Validation Library Scope Incomplete

**Research Finding** (Report 002 - Optimize-Claude Robustness, Recommendation 9):
> Include Rollback Procedures in Plans: Generate rollback sections in all implementation plans with specific failure conditions and restoration commands.

**Research Finding** (Report 003 - Current Plan Implementation, Opportunity 5):
> Standards Validation: validate_plan() checks metadata completeness, standards references, test phases, documentation tasks, phase dependencies (no circular deps using Kahn's algorithm).

**Plan Implementation** (Phase 4: Standards Discovery and Validation Library):
- Lines 388-391: Validation functions listed (validate_metadata, validate_standards_compliance, validate_test_phases, validate_documentation_tasks, validate_phase_dependencies)
- Line 389: "Implement validate_phase_dependencies() - check no circular dependencies (Kahn's algorithm)"
- NO implementation of rollback procedure generation in validate-plan.sh or plan-architect agent

**Gap Analysis**:
1. Validation library checks phase dependencies but does NOT generate rollback procedures
2. Research recommends ALL plans include rollback sections (optimize-claude pattern)
3. Plan-architect agent (Phase 5) may or may not generate rollback sections (behavioral file not updated)
4. Validation library could verify rollback section presence but plan does not specify this
5. Kahn's algorithm validation mentioned but no test coverage requirement

**Impact**: Medium - affects plan reliability and user confidence. Rollback procedures enable safe failure recovery.

**Recommendation**: Update Phase 4 tasks:
- "Add validate_rollback_section() - verify rollback procedure present with restoration commands and failure conditions"
- Update Phase 5 (plan-architect invocation) to enforce rollback generation in behavioral file
- Add test case for Kahn's algorithm circular dependency detection

### Gap 6: Context Pruning Not Implemented

**Research Finding** (Report 004 - Context Preservation, Recommendation 3):
> Apply Context Pruning Policies: Define workflow-specific pruning policies. After planning completes, prune research metadata (no longer needed). Maintains <30% context usage throughout workflow.

**Plan Implementation**:
- NO phase implements context pruning
- NO usage of context-pruning.sh library
- Research metadata accumulated but never pruned
- Plan metadata accumulated but never pruned

**Gap Analysis**:
1. Research shows coordinate achieves 95% context reduction through pruning (context-pruning.sh)
2. Plan command will accumulate research reports, analysis JSON, plan metadata without pruning
3. For complex features with 4+ research reports, context usage could exceed 70%
4. No pruning policy defined for plan workflow
5. context-pruning.sh library exists but plan does not use it

**Impact**: Low for simple features, High for complex features - context limit errors likely after research phase completes.

**Recommendation**: Add Phase 3.5 "Context Pruning After Research":
- Source context-pruning.sh library
- After research delegation completes: prune_phase_metadata("research") - retain only report paths and 50-word summaries
- Add pruning policy: after plan creation, prune analysis JSON (no longer needed)
- Target: <30% context usage after research phase

### Gap 7: Library Sourcing Auto-Discovery Missing

**Research Finding** (Report 001 - Coordinate Fragility, Recommendation 6):
> Standardize Library Sourcing with Auto-Discovery: Auto-discover libraries needed based on functions called. Use dependency declarations in library files (e.g., `LIBRARY_REQUIRES="state-persistence.sh"`). Eliminates manual REQUIRED_LIBS maintenance. Prevents "command not found" errors from missing libraries.

**Plan Implementation** (Phase 1: Core Command Structure):
- Line 228: "**Standard 15**: Source libraries in correct order: workflow-state-machine.sh → state-persistence.sh → error-handling.sh → verification-helpers.sh"
- Manual sourcing order enforced
- NO auto-discovery mechanism

**Gap Analysis**:
1. Plan uses manual library sourcing with explicit order (Standard 15 compliance)
2. Research recommends auto-discovery based on function calls or dependency declarations
3. Manual approach requires maintaining REQUIRED_LIBS for each command
4. Auto-discovery would reduce configuration from 20 lines to 5 lines
5. Risk: missing library causes "command not found" error (hard to debug)

**Impact**: Low - affects maintainability more than functionality. Manual sourcing works but requires ongoing maintenance.

**Recommendation**: Add Phase 1 task (low priority):
- "Consider implementing library auto-discovery: source_libraries_for_functions() pattern"
- "Document library dependencies in frontmatter (LIBRARY_REQUIRES field)"
- "If manual sourcing chosen, add verification: check critical functions available before use"

### Gap 8: Idempotent Operations Not Fully Specified

**Research Finding** (Report 002 - Optimize-Claude Robustness, Pattern 8):
> Idempotent Operations: All directory creation and file operations safe to run multiple times. Use conditional creation patterns: `[ -d "$TARGET_DIR" ] || mkdir -p "$TARGET_DIR"`.

**Plan Implementation** (Phase 1: Core Command Structure):
- Line 231: "Initialize workflow state using init_workflow_state("plan_$$")"
- Phase 3: Line 328: "Ensure report directories exist using ensure_artifact_directory() (lazy creation, 80% reduction in mkdir calls)"
- Phase 5: Line 434: "Ensure plan parent directory exists using ensure_artifact_directory() (lazy creation pattern)"

**Gap Analysis**:
1. Plan uses ensure_artifact_directory() for lazy creation (idempotent)
2. Does NOT specify idempotency for workflow state initialization
3. init_workflow_state() may fail if called multiple times (state file already exists)
4. No specification for backup file creation (should use timestamp to avoid overwriting)
5. No guidance on re-running command after interruption

**Impact**: Low - affects user experience when re-running command. Idempotent operations enable safe retries.

**Recommendation**: Add Phase 1 task:
- "Ensure init_workflow_state() is idempotent: skip initialization if state file already exists for workflow_id"
- Add documentation: "Command can be safely re-run if interrupted (all operations idempotent)"

### Gap 9: Expansion Evaluation Agent Behavioral Files Missing

**Research Finding** (Report 002 - Optimize-Claude Robustness, Pattern 2):
> Standardize "Create File FIRST" Agent Pattern: Enforce STEP 2 creates artifact file before any analysis. Guarantees artifact creation even if agent crashes mid-analysis.

**Plan Implementation** (Phase 7: Expansion Evaluation):
- Line 527: "**Standard 11**: Reference agent behavioral file: 'Read and follow: .claude/agents/complexity-estimator.md'"
- Line 535: "**Standard 11**: Reference agent file: 'Read and follow: .claude/agents/plan-structure-manager.md'"
- NO mention of creating these agent behavioral files
- NO verification that agents follow "Create File FIRST" pattern

**Gap Analysis**:
1. Plan references complexity-estimator.md and plan-structure-manager.md behavioral files
2. Does NOT include task to create these files (if they don't exist)
3. Does NOT verify agent files follow 28 completion criteria pattern from research-specialist.md
4. Risk: agents referenced but behavioral files missing (command fails at Phase 7)
5. Risk: agents exist but don't follow "Create File FIRST" pattern (partial failures)

**Impact**: High - Phase 7 will fail if agent files don't exist. Creates blocking dependency.

**Recommendation**: Add Phase 6.5 "Agent Behavioral Files Verification":
- "Verify complexity-estimator.md exists, create from template if missing"
- "Verify plan-structure-manager.md exists, create from template if missing"
- "Ensure both agents follow STEP 2 'Create File FIRST' pattern (28 completion criteria)"
- "Add test coverage for agent file structure (frontmatter, steps, verification checkpoints)"

### Gap 10: LLM Classification Fallback Incomplete

**Research Finding** (Report 003 - Current Plan Implementation, Opportunity 2):
> LLM-Based Feature Analysis: Use Task tool with small model (haiku-4) for classification. Analyze: complexity keywords, scope indicators, technical depth. Return JSON: estimated_complexity, suggested_phases, matching_templates. Reference: llm-classification-pattern.md.

**Plan Implementation** (Phase 2: Feature Analysis):
- Line 278: "Use haiku-4 model for fast classification (<5 seconds)"
- Line 284: "Add error handling for Task tool failures (fallback to heuristic analysis - keyword matching + length-based complexity)"

**Gap Analysis**:
1. Plan specifies LLM classification with heuristic fallback
2. Does NOT specify fallback heuristic algorithm details
3. Heuristic mentioned: "keyword matching + length-based complexity" but no implementation guide
4. Risk: fallback produces wildly different results than LLM (inconsistent user experience)
5. No test coverage requirement for fallback scenario

**Impact**: Medium - affects reliability when Task tool unavailable. Poor fallback creates user confusion.

**Recommendation**: Add Phase 2 task:
- "Implement heuristic fallback: complexity = (word_count / 10) + (keyword_match_count × 2), max 10"
- "Keywords: integrate=+2, migrate=+3, refactor=+2, architecture=+3, microservices=+3"
- "Ensure fallback produces results within ±2 of LLM classification (validation test)"
- Document fallback algorithm in inline comments

## Recommendations

### Priority 1: Address Subprocess Architecture (CRITICAL)

**Action**: Add Phase 0.5 to plan - "Architectural Decision: Bash Blocks vs Standalone Script"

**Rationale**: Fundamental decision affects all subsequent phases. Research strongly recommends standalone script (70% maintenance reduction, eliminates state persistence overhead).

**Tasks**:
- Evaluate tradeoffs: SlashCommand integration vs simplicity
- If bash blocks chosen: document justification and accept state persistence overhead
- If standalone script chosen: remove state-persistence.sh sourcing, simplify to single bash process
- Update Phases 1-7 tasks based on decision

**Estimated Effort**: 2-3 hours (decision + plan updates)

### Priority 2: Implement Hierarchical Supervision (HIGH)

**Action**: Update Phase 3 to include hierarchical supervision for RESEARCH_COMPLEXITY ≥4

**Rationale**: Research shows supervisor pattern prevents context explosion (95% reduction). Critical for complex features.

**Tasks**:
- Add conditional logic: if RESEARCH_COMPLEXITY ≥4, invoke research-sub-supervisor
- Create research-sub-supervisor.md behavioral file (if missing)
- Load aggregated metadata from supervisor checkpoint
- Update test coverage to include supervisor invocation scenario

**Estimated Effort**: 3-4 hours

### Priority 3: Add Template Selection System (MEDIUM)

**Action**: Add Phase 5.5 "Template Selection and Application"

**Rationale**: Feature analysis already identifies template_type. Using it improves plan quality (40-60% boilerplate reduction).

**Tasks**:
- Create 5 template files (.claude/commands/templates/)
- Implement template selection logic based on JSON output
- Update plan-architect to accept template path parameter
- Add template variable substitution support

**Estimated Effort**: 4-5 hours

### Priority 4: Implement Context Pruning (MEDIUM)

**Action**: Add Phase 3.5 "Context Pruning After Research"

**Rationale**: Complex features (4+ reports) will exceed context limits without pruning. Maintain <30% usage target.

**Tasks**:
- Source context-pruning.sh library
- After research: prune_phase_metadata("research") - retain paths + summaries only
- After planning: prune analysis JSON
- Add context usage metrics to command output

**Estimated Effort**: 2-3 hours

### Priority 5: Create Missing Agent Behavioral Files (HIGH)

**Action**: Add Phase 6.5 "Agent Behavioral Files Verification"

**Rationale**: Phase 7 references agents that may not exist. Blocking dependency for expansion evaluation.

**Tasks**:
- Create complexity-estimator.md from template
- Create plan-structure-manager.md from template
- Ensure both follow 28 completion criteria pattern
- Add test coverage for agent file structure

**Estimated Effort**: 3-4 hours

### Priority 6: Enhance Validation Library (MEDIUM)

**Action**: Update Phase 4 tasks to include rollback procedure validation

**Rationale**: Research shows all robust plans include rollback sections. Validation should enforce this.

**Tasks**:
- Implement validate_rollback_section() in validate-plan.sh
- Update plan-architect behavioral file to require rollback generation
- Add test case for Kahn's algorithm circular dependency detection
- Document validation criteria in library comments

**Estimated Effort**: 2-3 hours

### Priority 7: Implement Hybrid Error Handling (LOW)

**Action**: Update Phase 1 to include defensive defaults for recoverable conditions

**Rationale**: Reduces verification code by 60% while maintaining fail-fast for critical errors.

**Tasks**:
- Define decision matrix: fail-fast vs defensive defaults
- Implement defensive defaults for missing metadata (generate from heuristics)
- Maintain fail-fast for unrecoverable conditions (permissions, missing deps)
- Document pattern in inline comments

**Estimated Effort**: 2-3 hours

## References

### Plan File
- `/home/benjamin/.config/.claude/specs/726_reports_001_plan_command_refactor_research/plans/001_reports_001_plan_command_refactor_research_plan.md:1-755` - Implementation plan under analysis

### Research Reports
- `/home/benjamin/.config/.claude/specs/725_plan_command_refactor_research/reports/001_plan_command_refactor_research/001_coordinate_command_architecture_and_fragility_analysis.md:1-442` - Coordinate fragility findings
- `/home/benjamin/.config/.claude/specs/725_plan_command_refactor_research/reports/001_plan_command_refactor_research/002_optimize_claude_command_robustness_patterns.md:1-496` - Robustness patterns
- `/home/benjamin/.config/.claude/specs/725_plan_command_refactor_research/reports/001_plan_command_refactor_research/003_current_plan_command_implementation_review.md:1-419` - Current implementation analysis
- `/home/benjamin/.config/.claude/specs/725_plan_command_refactor_research/reports/001_plan_command_refactor_research/004_context_preservation_and_metadata_passing_strategies.md:1-512` - Context preservation strategies

### Supporting Files
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` - State persistence library
- `/home/benjamin/.config/.claude/lib/context-pruning.sh` - Context reduction library
- `/home/benjamin/.config/.claude/lib/metadata-extraction.sh` - Metadata extraction utilities
- `/home/benjamin/.config/.claude/agents/research-specialist.md` - Research agent behavioral file (28 completion criteria)
- `/home/benjamin/.config/.claude/commands/coordinate.md` - Coordinate command reference implementation
- `/home/benjamin/.config/.claude/commands/optimize-claude.md` - Optimize-claude command reference implementation
