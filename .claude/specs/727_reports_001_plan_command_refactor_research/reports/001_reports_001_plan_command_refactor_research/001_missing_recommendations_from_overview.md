# Missing Recommendations from Overview - Research Report

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: Missing Recommendations from Overview Analysis
- **Report Type**: gap analysis
- **Overview Report**: [OVERVIEW.md](OVERVIEW.md)
- **Related Reports**:
  - [Implementation Gaps in Plan Phases](002_implementation_gaps_in_plan_phases.md)
  - [Standards Inconsistencies in Behavioral Injection](003_standards_inconsistencies_in_behavioral_injection.md)
  - [Documentation Tension Between Robustness Patterns](004_documentation_tension_between_robustness_patterns.md)

## Executive Summary

This report analyzes the OVERVIEW.md from research topic 725 against the implementation plan 726/001 to identify recommendations and findings that were not incorporated into the plan. The analysis reveals 18 specific recommendations from the overview that are missing or insufficiently addressed in the implementation plan, falling into six categories: architectural patterns (6 items), context management (4 items), agent behavioral protocols (3 items), validation infrastructure (2 items), library integration (2 items), and error handling (1 item). The plan captures core functionality but omits critical robustness patterns including hierarchical supervision for 4+ research topics, context pruning policies, template selection system, interactive refinement, and graceful degradation strategies that were explicitly recommended in the overview.

## Findings

### Research Context

The overview document synthesizes findings from 4 research reports analyzing coordinate command architecture, optimize-claude robustness patterns, current plan command implementation, and context preservation strategies. It provides detailed recommendations organized into 4 implementation phases spanning 21-30 hours.

The implementation plan (726/001) was created to refactor the /plan command following these research findings, structured as 7 phases spanning 16-20 hours.

### Gap Analysis Methodology

This analysis compares:
1. All recommendations explicitly stated in OVERVIEW.md sections: "Recommended Approach", "Cross-Report Findings", and individual report "Key Recommendations"
2. Implementation tasks, success criteria, and technical design in plan 726/001

Items are marked "missing" if:
- No corresponding task exists in any phase
- Success criteria don't verify the recommendation
- Technical design doesn't incorporate the pattern

### Category 1: Architectural Patterns (6 Missing Items)

**Missing 1: Hierarchical Supervision for 4+ Research Topics**

- **Overview Source**: Phase 2 recommendation (lines 196-226), Cross-Report Findings pattern (lines 45-53), Constraint 5 mitigation (lines 359-375)
- **Overview Text**: "Use hierarchical supervision for 4+ topics (complexity ≥7, complex features), Implement supervisor pattern from coordinate (95% context reduction), Supervisor aggregates metadata, returns summaries only"
- **Plan Status**: Phase 3 implements "parallel agent invocation (1-4 agents based on RESEARCH_COMPLEXITY)" but NO supervisor pattern for N>4 topics
- **Impact**: Plan limited to 4 research topics maximum, cannot handle highly complex features requiring 5+ research areas
- **Recommendation Location**: OVERVIEW.md line 371-374

**Missing 2: Template Selection System**

- **Overview Source**: Phase 3 complete section (lines 229-258), Current Plan Implementation Review recommendation (lines 131-133)
- **Overview Text**: "Create template library (feature, bugfix, refactor, architecture, database templates), Implement template selection logic in analyze_feature_description(), Add template variable substitution"
- **Plan Status**: No template library mentioned in any phase, no template selection logic in Phase 2 feature analysis
- **Impact**: All plans use uniform structure regardless of feature type, increases boilerplate for simple features like bugfixes
- **Recommendation Location**: OVERVIEW.md lines 229-258

**Missing 3: Interactive Refinement**

- **Overview Source**: Current Plan Implementation Review recommendation #5 (lines 133-134)
- **Overview Text**: "Add interactive plan review, display summary to user, use AskUserQuestion for adjustments, regenerate with changes, confirm before writing"
- **Plan Status**: No interactive review in any phase, plan-architect creates plan without user confirmation
- **Impact**: Users cannot adjust plan before creation, reduces flexibility for non-standard requirements
- **Recommendation Location**: OVERVIEW.md lines 133-134

**Missing 4: Modular Script Extraction (Standalone Orchestrator)**

- **Overview Source**: Coordinate Analysis recommendation #1 (lines 93-94), Constraint 1 mitigation (lines 302), Constraint 2 mitigation (lines 316-318)
- **Overview Text**: "Extract orchestration to standalone `.claude/scripts/coordinate-orchestrator.sh` executable to eliminate subprocess boundaries, Keep markdown bash blocks minimal (<200 lines)"
- **Plan Status**: Plan uses inline bash blocks in command file, no standalone script extraction
- **Impact**: Risks subprocess isolation issues if command grows, harder to debug vs standalone script
- **Recommendation Location**: OVERVIEW.md lines 93-94, 302, 316-318

**Missing 5: Data-Driven Agent Invocation (jq Loops)**

- **Overview Source**: Coordinate Analysis recommendation #3 (lines 95-96)
- **Overview Text**: "Replace conditional agent invocation with data-driven approach using jq loops"
- **Plan Status**: Phase 3 uses conditional logic for agent invocation, no data-driven approach
- **Impact**: Harder to extend beyond 4 research topics, requires code changes to add topics
- **Recommendation Location**: OVERVIEW.md line 96

**Missing 6: Defensive Defaults to Reduce Verification Code**

- **Overview Source**: Coordinate Analysis recommendation #5 (lines 97-98)
- **Overview Text**: "Replace fail-fast checkpoints with defensive defaults (reduce verification code by 60%)"
- **Plan Status**: Plan uses fail-fast verification extensively (inherited from optimize-claude pattern), no defensive defaults
- **Impact**: More verification code than necessary, potential maintenance burden
- **Recommendation Location**: OVERVIEW.md line 98

### Category 2: Context Management (4 Missing Items)

**Missing 7: Context Pruning Policies**

- **Overview Source**: Context Preservation Strategies recommendation #3 (lines 147-148), Cross-Report Findings pattern (lines 45-53)
- **Overview Text**: "Apply context pruning policies (define workflow-specific rules, prune phase metadata after completion, maintain <30% context usage)"
- **Plan Status**: No context pruning mentioned in any phase, no workflow-specific pruning rules
- **Impact**: Risk exceeding context limits on complex features with extensive research, no cleanup between phases
- **Recommendation Location**: OVERVIEW.md lines 147-148

**Missing 8: Context Usage Monitoring**

- **Overview Source**: Constraint 3 mitigation (lines 335-337)
- **Overview Text**: "Target <30% context usage throughout workflow"
- **Plan Status**: No context monitoring tasks, no usage targets defined
- **Impact**: Cannot detect approaching context limits until failure occurs
- **Recommendation Location**: OVERVIEW.md line 337

**Missing 9: Aggressive Context Reduction Target (95%)**

- **Overview Source**: Cross-Report Findings pattern (lines 45-53), Context Preservation Strategies recommendation (line 147)
- **Overview Text**: "Implement metadata extraction (extract 50-word summaries + key recommendations before passing to subagents, achieve 95% context reduction)"
- **Plan Status**: Phase 3 mentions "95% context reduction" but no explicit 95% target verification or monitoring
- **Impact**: Context reduction may be insufficient without explicit measurement
- **Recommendation Location**: OVERVIEW.md lines 50-51, 147

**Missing 10: Variable Overwriting Protection**

- **Overview Source**: Context Preservation Strategies common pitfalls (line 152)
- **Overview Text**: "Avoid common pitfalls (save variables before sourcing libraries, disable history expansion with set +H, use fail-fast validation mode)"
- **Plan Status**: Phase 1 includes "set +H" but no variable saving before library sourcing
- **Impact**: Risk of variable overwriting when sourcing multiple libraries
- **Recommendation Location**: OVERVIEW.md line 152

### Category 3: Agent Behavioral Protocols (3 Missing Items)

**Missing 11: Agent Test Coverage Enforcement (28 Completion Criteria)**

- **Overview Source**: Optimize-Claude Patterns finding (lines 102-106), recommendation #4 (line 113)
- **Overview Text**: "Mandate comprehensive test coverage (verify agent structure, completion signals, file size limits), enforced through 28 completion criteria per agent"
- **Plan Status**: Testing Requirements section exists but no 28-criteria enforcement for agents
- **Impact**: Agent behavioral compliance may be incomplete without structured criteria
- **Recommendation Location**: OVERVIEW.md lines 113

**Missing 12: Rollback Procedures in Plans**

- **Overview Source**: Optimize-Claude Patterns recommendation #8 (line 118)
- **Overview Text**: "Include rollback procedures in plans (clear recovery path if implementation fails)"
- **Plan Status**: Risk Management section includes rollback for command development, but no requirement for plan-architect to include rollback in generated plans
- **Impact**: Plans created by plan-architect may lack recovery procedures
- **Recommendation Location**: OVERVIEW.md line 118

**Missing 13: Timeout Handling for Research Agents**

- **Overview Source**: Phase 3 task detail (line 338)
- **Overview Text**: "Add timeout handling (5-minute default per agent)"
- **Plan Status**: Phase 3 mentions timeout but Plan Phase 5 says "Set timeout to 10 minutes" for plan-architect only, no explicit 5-min timeout for research agents
- **Impact**: Research agents could hang indefinitely
- **Recommendation Location**: OVERVIEW.md line 338

### Category 4: Validation Infrastructure (2 Missing Items)

**Missing 14: Template Inheritance for Validation**

- **Overview Source**: Risk 4 mitigation (line 449)
- **Overview Text**: "Use template inheritance (base template + type-specific sections)"
- **Plan Status**: No template system implemented, so no inheritance mechanism
- **Impact**: If templates added later, may duplicate validation logic
- **Recommendation Location**: OVERVIEW.md line 449

**Missing 15: Standards Discovery Graceful Degradation**

- **Overview Source**: Risk 6 mitigation (lines 473-478)
- **Overview Text**: "Implement graceful degradation (use sensible defaults if CLAUDE.md missing), Support multiple section formats, Validate standards content before applying, Log standards discovery results, Suggest /setup command if CLAUDE.md incomplete"
- **Plan Status**: Phase 4 implements standards discovery but no explicit graceful degradation, fallback defaults, or multi-format support
- **Impact**: Command may fail if CLAUDE.md missing or malformed instead of using defaults
- **Recommendation Location**: OVERVIEW.md lines 473-478

### Category 5: Library Integration (2 Missing Items)

**Missing 16: Auto-Discovery Library Sourcing**

- **Overview Source**: Coordinate Analysis recommendation #6 (line 99)
- **Overview Text**: "Standardize library sourcing with auto-discovery based on functions called"
- **Plan Status**: Plan uses explicit library sourcing with Standard 15 ordering, no auto-discovery
- **Impact**: Manual library management, requires updating sourcing code when adding functions
- **Recommendation Location**: OVERVIEW.md line 99

**Missing 17: Simplified State Machine (50 Lines)**

- **Overview Source**: Coordinate Analysis recommendation #2 (line 95)
- **Overview Text**: "Simplify state machine from 905-line library to ~50-line phase counter"
- **Plan Status**: Plan sources workflow-state-machine.sh without simplification
- **Impact**: Inherits full complexity of 905-line state machine for simpler workflow
- **Recommendation Location**: OVERVIEW.md line 95

### Category 6: Error Handling (1 Missing Item)

**Missing 18: Graceful Degradation on Research Failures**

- **Overview Source**: Phase 2 task (line 339)
- **Overview Text**: "Implement graceful degradation if agent fails (continue with partial research, warn user)"
- **Plan Status**: Risk 5 mentions fallback but Phase 3 tasks don't include graceful degradation implementation
- **Impact**: Single research agent failure could halt entire plan creation instead of degrading gracefully
- **Recommendation Location**: OVERVIEW.md line 339

### Items Successfully Incorporated

The plan successfully incorporates these major recommendations:

1. **Fail-Fast Verification** (Optimize-Claude pattern): Phases 1-7 include verification checkpoints after critical operations
2. **Absolute Path Requirements** (Cross-Report synergy): Phase 1 validates paths at entry point
3. **Pre-Calculated Artifact Paths** (Context Preservation pattern): Phases 3, 5, 7 pre-calculate paths before agent invocation
4. **Create File FIRST Pattern** (Optimize-Claude pattern): Phase 5 plan-architect agent uses mandatory file creation protocol
5. **Lazy Directory Creation** (Optimize-Claude pattern): Phases 3, 5, 7 use ensure_artifact_directory()
6. **Library Integration** (Optimize-Claude pattern): Phases use existing libraries (plan-core-bundle.sh, complexity-utils.sh, metadata-extraction.sh)
7. **LLM Classification** (Plan Implementation recommendation #1): Phase 2 implements analyze_feature_description() with haiku-4
8. **Research Delegation** (Plan Implementation recommendation #2): Phase 3 implements conditional research based on complexity
9. **Standards Validation** (Plan Implementation recommendation #4): Phase 4 creates validate-plan.sh library
10. **Metadata Extraction** (Context Preservation pattern): Phases 3, 5 extract metadata for context reduction
11. **Error Context Enrichment** (Optimize-Claude pattern): Phases include agent name, artifact path in error messages
12. **Idempotent Operations** (Optimize-Claude pattern): Directory creation, state persistence designed for safe re-runs

### Prioritization of Missing Items

**HIGH PRIORITY (Should be added to plan)**:

1. **Missing 2: Template Selection System** - Core functionality mentioned in overview Phase 3, significant UX improvement
2. **Missing 7: Context Pruning Policies** - Critical for complex features, prevents context limit errors
3. **Missing 1: Hierarchical Supervision for 4+ Topics** - Scalability constraint, limits command to 4 research topics
4. **Missing 13: Timeout Handling for Research Agents** - Prevents hangs, improves reliability
5. **Missing 15: Standards Discovery Graceful Degradation** - Robustness improvement, prevents failures on missing CLAUDE.md

**MEDIUM PRIORITY (Consider adding if time permits)**:

6. **Missing 3: Interactive Refinement** - UX improvement, marked as LOW priority in overview
7. **Missing 8: Context Usage Monitoring** - Debugging aid, helps prevent limit errors
8. **Missing 12: Rollback Procedures in Plans** - Plan quality improvement
9. **Missing 18: Graceful Degradation on Research Failures** - Robustness improvement

**LOW PRIORITY (Defer to future iterations)**:

10. **Missing 4: Modular Script Extraction** - Optimization, only needed if command grows large
11. **Missing 5: Data-Driven Agent Invocation** - Code quality improvement, current conditional approach sufficient
12. **Missing 6: Defensive Defaults** - Conflicts with chosen fail-fast strategy
13. **Missing 9: Aggressive Context Reduction Target** - Already partially implemented, just needs explicit verification
14. **Missing 10: Variable Overwriting Protection** - Edge case, only matters with many library sourcings
15. **Missing 11: Agent Test Coverage (28 Criteria)** - Test quality improvement, comprehensive testing already planned
16. **Missing 14: Template Inheritance** - Only relevant if template system added
17. **Missing 16: Auto-Discovery Library Sourcing** - Code quality improvement, explicit sourcing is clear
18. **Missing 17: Simplified State Machine** - Optimization, existing library works

## Recommendations

### Recommendation 1: Add Template Selection System (HIGH PRIORITY)

**Action**: Add new phase between current Phase 2 (Feature Analysis) and Phase 3 (Research Delegation)

**New Phase 2.5: Template Selection and Preparation**

Tasks:
- Create template library directory: `.claude/templates/plan/`
- Create 5 core templates: feature.md, bugfix.md, refactor.md, architecture.md, database.md
- Enhance analyze_feature_description() to detect feature type from keywords
- Implement template selection logic based on detected type
- Add template variable substitution for {{FEATURE_NAME}}, {{COMPLEXITY}}, {{ESTIMATED_DURATION}}
- Document template catalog in templates/README.md

**Rationale**: Explicitly recommended in overview Phase 3 (lines 229-258) as 4-6 hour task, marked MEDIUM priority. Tailored templates reduce boilerplate significantly, especially for bugfixes and database migrations. This is core functionality that improves plan quality.

**Estimated Time**: 4-6 hours (per overview)

**Integration**: Phase 5 (Plan-Architect Agent) would receive selected template as context

### Recommendation 2: Implement Context Pruning Policies (HIGH PRIORITY)

**Action**: Add tasks to Phase 3 (Research Delegation) and Phase 5 (Plan Creation)

**Phase 3 Additional Tasks**:
- Source context-pruning.sh library
- Define workflow-specific pruning policy: prune research metadata after plan creation
- After metadata extraction: prune full research report content, keep metadata only
- Verify context usage <30% after pruning

**Phase 5 Additional Tasks**:
- Before plan creation: verify current context usage
- After plan creation: prune research phase metadata
- Emit context usage metrics to user

**Rationale**: Recommended in overview lines 147-148 and constraint mitigation lines 335-337. Critical for complex features with 4+ research topics to prevent context limit errors. The library already exists (context-pruning.sh, 454 lines), just needs integration.

**Estimated Time**: 1-2 hours (library sourcing and integration)

**Impact**: Reduces risk of context overflow on complex features

### Recommendation 3: Add Hierarchical Supervision for 4+ Topics (HIGH PRIORITY)

**Action**: Modify Phase 3 (Research Delegation) with conditional supervision logic

**Phase 3 Additional Tasks**:
- Detect if research topic count >4
- If ≤4 topics: use current flat parallel invocation
- If >4 topics: invoke research-sub-supervisor agent
  - Supervisor receives all research topics
  - Supervisor delegates to research-specialist agents
  - Supervisor aggregates metadata
  - Supervisor returns 50-word summary only (95% reduction)
- Add supervisor pattern from coordinate (reference .claude/commands/coordinate.md lines for pattern)

**Rationale**: Explicitly recommended in overview lines 196-226 and 371-374. Current plan limited to 4 topics maximum. Highly complex features (e.g., "migrate to microservices") could require 5-8 research areas. Supervisor pattern proven in coordinate command.

**Estimated Time**: 2-3 hours (conditional logic + supervisor invocation)

**Impact**: Removes scalability constraint, enables truly complex feature planning

### Recommendation 4: Add Timeout Handling for Research Agents (HIGH PRIORITY)

**Action**: Modify Phase 3 (Research Delegation) task invocations

**Phase 3 Task Updates**:
- Add explicit timeout parameter to research-specialist Task invocations: `timeout: 300` (5 minutes)
- Implement timeout error handling: detect timeout vs. other failures
- On timeout: log warning, continue with partial research (graceful degradation)
- Update error context: distinguish "Agent timed out after 5min" from "Agent failed"

**Rationale**: Recommended in overview line 338. Research agents could hang on complex web searches or large codebase analysis. 5-minute timeout prevents indefinite hangs while allowing thorough research.

**Estimated Time**: 30 minutes (add timeout parameters + error handling)

**Impact**: Improves command reliability, prevents indefinite hangs

### Recommendation 5: Implement Standards Discovery Graceful Degradation (HIGH PRIORITY)

**Action**: Enhance Phase 4 (Standards Discovery) with fallback logic

**Phase 4 Additional Tasks**:
- Wrap CLAUDE.md discovery in conditional: `if [ -f "$CLAUDE_MD_PATH" ]; then ... else fallback; fi`
- Define sensible defaults if CLAUDE.md missing:
  - Default test coverage: 80%
  - Default documentation: README.md required
  - Default code style: language-specific defaults
- Support multiple section formats: `<!--SECTION:name-->` and `## Section Name`
- Validate extracted standards content (check for required fields before using)
- Log standards discovery results to user: "Using CLAUDE.md at X" or "Using defaults (CLAUDE.md not found)"
- If CLAUDE.md incomplete: suggest running `/setup` command

**Rationale**: Recommended in overview risk mitigation lines 473-478. Current implementation may fail if CLAUDE.md missing or malformed. Graceful degradation makes command robust across different project setups.

**Estimated Time**: 1-2 hours (fallback logic + validation)

**Impact**: Command works reliably even in projects without CLAUDE.md

### Recommendation 6: Add Interactive Refinement (MEDIUM PRIORITY)

**Action**: Add new phase after Phase 5 (Plan Creation), before Phase 6 (Validation)

**New Phase 5.5: Interactive Plan Review**

Tasks:
- Extract plan summary using extract_plan_metadata()
- Display plan overview to user: feature, phases, estimated hours, complexity
- Use AskUserQuestion tool: "Accept plan as-is, Request adjustments, or Cancel?"
- If adjustments requested: collect user feedback, regenerate plan with changes via plan-architect
- If accepted: proceed to validation
- If cancelled: exit gracefully

**Rationale**: Recommended in overview lines 133-134 as LOW priority enhancement. Improves UX by allowing user input before finalizing plan. Especially valuable for non-standard requirements or when user has specific constraints.

**Estimated Time**: 2-3 hours (per overview)

**Impact**: Better user control, reduces need for manual plan edits

### Recommendation 7: Monitor and Report Context Usage (MEDIUM PRIORITY)

**Action**: Add context monitoring to Phases 3, 5, 7

**Implementation**:
- After each major phase (research, plan creation, expansion): calculate approximate context usage
- Formula: `(current_output_tokens / max_context_tokens) * 100`
- Emit progress: "Context usage: 18% (under 30% target)"
- Warn if approaching limit: "WARNING: Context usage 25%, approaching 30% threshold"
- Consider pruning earlier if usage >25%

**Rationale**: Recommended in overview constraint mitigation line 337. Helps detect context issues before failure. Debugging aid for complex workflows.

**Estimated Time**: 1 hour (add calculations + progress emissions)

**Impact**: Better visibility into context consumption, earlier warning of issues

### Recommendation 8: Add Graceful Degradation on Research Failures (MEDIUM PRIORITY)

**Action**: Enhance Phase 3 (Research Delegation) error handling

**Phase 3 Task Updates**:
- Wrap research agent invocations in error handling
- On agent failure: check if file created (even partial)
- If file exists: extract any available metadata, log warning, continue
- If file missing: log error, continue with remaining research agents
- After all agents: check if ANY research completed
- If zero research completed: warn user, proceed to plan creation with feature description only
- If partial research completed: inform user which topics succeeded/failed

**Rationale**: Recommended in overview line 339 and Risk 5 mitigation. Single research agent failure shouldn't halt entire workflow. Partial research better than no research.

**Estimated Time**: 1-2 hours (error handling + partial result logic)

**Impact**: More resilient to individual agent failures, better user experience

## References

- **/home/benjamin/.config/.claude/specs/725_plan_command_refactor_research/reports/001_plan_command_refactor_research/OVERVIEW.md**: Source of all recommendations (complete synthesis of 4 research reports)
  - Lines 93-99: Coordinate Analysis recommendations
  - Lines 109-119: Optimize-Claude Patterns recommendations
  - Lines 127-134: Current Plan Implementation Review recommendations
  - Lines 144-152: Context Preservation Strategies recommendations
  - Lines 154-226: Recommended Approach (4 phases with detailed tasks)
  - Lines 228-479: Constraints, trade-offs, risk mitigations

- **/home/benjamin/.config/.claude/specs/726_reports_001_plan_command_refactor_research/plans/001_reports_001_plan_command_refactor_research_plan.md**: Implementation plan analyzed for gaps
  - Lines 1-85: Metadata, success criteria (Standards 0, 11-16 compliance)
  - Lines 86-140: Technical design and architecture
  - Lines 217-555: Phase implementations (Phases 1-7)
  - Lines 671-703: Risk management and rollback procedures

- **/home/benjamin/.config/.claude/specs/725_plan_command_refactor_research/reports/001_plan_command_refactor_research/001_coordinate_command_architecture_and_fragility_analysis.md**: Source of architectural complexity analysis
- **/home/benjamin/.config/.claude/specs/725_plan_command_refactor_research/reports/001_plan_command_refactor_research/002_optimize_claude_command_robustness_patterns.md**: Source of robustness patterns
- **/home/benjamin/.config/.claude/specs/725_plan_command_refactor_research/reports/001_plan_command_refactor_research/003_current_plan_command_implementation_review.md**: Source of implementation gap findings
- **/home/benjamin/.config/.claude/specs/725_plan_command_refactor_research/reports/001_plan_command_refactor_research/004_context_preservation_and_metadata_passing_strategies.md**: Source of context management patterns
