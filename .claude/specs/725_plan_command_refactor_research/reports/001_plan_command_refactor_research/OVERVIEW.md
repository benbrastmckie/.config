# Research Overview: Plan Command Refactor Research

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-synthesizer
- **Topic Number**: 725
- **Individual Reports**: 4 reports synthesized
- **Reports Directory**: /home/benjamin/.config/.claude/specs/725_plan_command_refactor_research/reports/001_plan_command_refactor_research

## Executive Summary

This research synthesizes findings from analysis of the coordinate, optimize-claude, and plan commands to inform refactoring of the /plan command. The coordinate command demonstrates architectural fragility through 2,466 lines of deeply nested state management fighting subprocess isolation constraints, requiring 13 specification iterations and 1,485 lines of documentation to address fundamental execution model conflicts. In contrast, optimize-claude exhibits exceptional robustness through fail-fast verification, agent behavioral injection with mandatory file creation, library integration for proven algorithms, and comprehensive test coverage. The current /plan command remains a pseudocode template with missing core functions, presenting an opportunity to implement an executable command using robustness patterns from optimize-claude while avoiding complexity pitfalls from coordinate.

## Research Structure

This overview synthesizes findings from 4 specialized research reports:

1. **[Coordinate Command Architecture and Fragility Analysis](001_coordinate_command_architecture_and_fragility_analysis.md)** - Analysis of coordinate command's extreme complexity, subprocess isolation constraints, and 13-iteration evolution revealing architectural fragility patterns to avoid
2. **[Optimize-Claude Command Robustness Patterns](002_optimize_claude_command_robustness_patterns.md)** - Five-layer architectural pattern analysis showing fail-fast verification, agent behavioral injection, library integration, lazy directory creation, and comprehensive test coverage
3. **[Current Plan Command Implementation Review](003_current_plan_command_implementation_review.md)** - Current /plan command implementation analysis revealing pseudocode template status, missing core functions, and implementation opportunities
4. **[Context Preservation and Metadata Passing Strategies](004_context_preservation_and_metadata_passing_strategies.md)** - Sophisticated context preservation mechanisms using file-based state persistence, metadata extraction, and 95% context reduction strategies

## Cross-Report Findings

### Pattern: Architectural Complexity Drivers

Three distinct complexity drivers emerge across commands:

**subprocess isolation constraints** ([Coordinate Analysis](./001_coordinate_command_architecture_and_fragility_analysis.md)): Each bash block executes in separate subprocess with no state persistence, forcing stateless recalculation patterns duplicated across 6+ blocks. This fundamental constraint drove 13 specification iterations and 1,485 lines of state management documentation.

**Fail-fast verification proliferation** ([Coordinate Analysis](./001_coordinate_command_architecture_and_fragility_analysis.md), [Optimize-Claude Patterns](./002_optimize_claude_command_robustness_patterns.md)): Coordinate has 50+ verification checkpoints creating defensive programming at extreme levels, while optimize-claude uses verification strategically between phases only. The difference: coordinate verifies state persistence mechanics, optimize-claude verifies deliverable artifacts.

**Template vs. implementation gap** ([Plan Implementation Review](./003_current_plan_command_implementation_review.md)): Plan command exists as 230-line pseudocode template with comprehensive documentation but no executable implementation, contrasting sharply with coordinate's over-implementation.

### Pattern: State Persistence Strategies

Two fundamentally different approaches to state management:

**File-based state persistence** ([Context Preservation Strategies](./004_context_preservation_and_metadata_passing_strategies.md), [Coordinate Analysis](./001_coordinate_command_architecture_and_fragility_analysis.md)): Coordinate uses GitHub Actions-style state files (state-persistence.sh, 392 lines) to persist variables across subprocess boundaries, achieving 70% performance improvement (50ms → 15ms for CLAUDE_PROJECT_DIR detection) vs. re-detection but requiring extensive verification infrastructure.

**Pre-calculated path injection** ([Optimize-Claude Patterns](./002_optimize_claude_command_robustness_patterns.md), [Context Preservation Strategies](./004_context_preservation_and_metadata_passing_strategies.md)): Optimize-claude calculates all artifact paths upfront in orchestrator, passes absolute paths to subagents via structured prompts. Eliminates state persistence needs entirely, reduces agents to <400 lines, enables lazy directory creation.

**Key Insight**: State persistence complexity correlates with subprocess boundary count. Optimize-claude minimizes boundaries through standalone agent execution, coordinate maximizes boundaries through inline bash blocks.

### Pattern: Context Reduction Mechanisms

Both commands implement aggressive context reduction but with different strategies:

**Hierarchical supervision with metadata aggregation** ([Context Preservation Strategies](./004_context_preservation_and_metadata_passing_strategies.md), [Coordinate Analysis](./001_coordinate_command_architecture_and_fragility_analysis.md)): Coordinate achieves 95% context reduction for 4+ parallel subagents through research-sub-supervisor pattern that aggregates metadata, returns 50-word summaries instead of full outputs.

**Metadata extraction at artifact boundaries** ([Optimize-Claude Patterns](./002_optimize_claude_command_robustness_patterns.md), [Context Preservation Strategies](./004_context_preservation_and_metadata_passing_strategies.md)): Optimize-claude uses metadata-extraction.sh to extract title, 50-word summary, and 3-5 recommendations from artifacts, passing minimal metadata to next phase instead of full reports.

**Convergence**: Both commands target <30% context usage through 95% reduction, but optimize-claude achieves this through simpler sequential phase boundaries while coordinate requires hierarchical supervision.

### Pattern: Agent Behavioral Enforcement

Critical divergence in how commands ensure agents complete their work:

**Create file FIRST pattern** ([Optimize-Claude Patterns](./002_optimize_claude_command_robustness_patterns.md)): All optimize-claude agents follow strict STEP 2 protocol: "Create report file FIRST (with placeholders) BEFORE conducting any analysis." Guarantees artifact creation even if agent crashes mid-execution. Enforced through 28 completion criteria per agent and dedicated test suite.

**Completion signal protocol** ([Optimize-Claude Patterns](./002_optimize_claude_command_robustness_patterns.md), [Context Preservation Strategies](./004_context_preservation_and_metadata_passing_strategies.md)): Agents return ONLY structured confirmation ("REPORT_CREATED: [path]"), no summary text. Orchestrator reads files directly, enabling 99% context reduction and using file artifacts as source of truth.

**Missing in coordinate** ([Coordinate Analysis](./001_coordinate_command_architecture_and_fragility_analysis.md)): Coordinate verifies state persistence mechanics but not artifact quality. Verification checks if variables exist, not if reports are complete. Allows partial failures to cascade.

### Contradiction: Library Integration Philosophy

**Coordinate maximalism** ([Coordinate Analysis](./001_coordinate_command_architecture_and_fragility_analysis.md)): Requires 13+ library dependencies loaded conditionally based on workflow scope, with circular dependency chains (workflow-state-machine.sh depends on workflow-scope-detection.sh OR workflow-detection.sh). Creates 40 potential execution paths (5 scopes × 2 research modes × 4 complexity levels).

**Optimize-claude minimalism** ([Optimize-Claude Patterns](./002_optimize_claude_command_robustness_patterns.md)): Agents source exactly 2 libraries (unified-location-detection.sh for directory creation, optimize-claude-md.sh for analysis functions). Zero circular dependencies, single execution path per agent.

**Resolution**: Library integration should be pull-based (agents source what they need) not push-based (orchestrator pre-loads all possible dependencies). Coordinate's conditional library loading optimizes for wrong metric (orchestrator code size) at expense of complexity.

### Synergy: Absolute Path Requirements

Universal pattern across all commands for robustness:

**Entry point validation** ([Optimize-Claude Patterns](./002_optimize_claude_command_robustness_patterns.md), [Coordinate Analysis](./001_coordinate_command_architecture_and_fragility_analysis.md)): All agents validate paths are absolute before proceeding using `[[ ! "$PATH" =~ ^/ ]]` pattern. Fail immediately with clear error messages rather than mid-execution.

**Orchestrator responsibility** ([Context Preservation Strategies](./004_context_preservation_and_metadata_passing_strategies.md)): Orchestrator calculates all artifact paths upfront using unified-location-detection.sh, passes exact paths to subagents. Eliminates path calculation overhead in subagents, ensures consistent naming.

**Benefit**: Zero cwd-dependent bugs, clear error messages, enables lazy directory creation (agents create parent dirs as needed).

## Detailed Findings by Topic

### Coordinate Command Architecture and Fragility

The coordinate command evolved through 13 specification iterations (specs 578, 581-600) over 2-3 days to address fundamental subprocess isolation constraints. Current architecture spans 3,763 lines across coordinate.md (2,466 lines), workflow-state-machine.sh (905 lines), and state-persistence.sh (392 lines). The command exhibits four primary fragility factors: (1) Extreme complexity with 50+ verification checkpoints, (2) Fighting subprocess isolation through stateless recalculation patterns duplicated across 6+ bash blocks, (3) Code transformation bugs requiring block size limits <300 lines (100-line safety margin from 400-line hard limit), and (4) Conditional execution path explosion creating 40 potential paths.

Key architectural lessons: subprocess isolation is fundamental constraint of Claude Code Bash tool (each block different PID, exports don't persist), requiring either stateless recalculation (2ms overhead per block) or file-based state (30ms overhead, 30x slower). Coordinate chose hybrid approach, creating maintenance burden. Documentation volume (1,485 lines for state management alone) indicates architecture too complex. Recommendation: Extract stateful orchestration logic to standalone script, eliminate subprocess boundaries, reduce maintenance burden by 70%.

[Full Report](./001_coordinate_command_architecture_and_fragility_analysis.md)

**Key Recommendations**:
- Extract orchestration to standalone `.claude/scripts/coordinate-orchestrator.sh` executable to eliminate subprocess boundaries
- Simplify state machine from 905-line library to ~50-line phase counter
- Replace conditional agent invocation with data-driven approach using jq loops
- Eliminate 400-line code transformation risk via modular scripts
- Replace fail-fast checkpoints with defensive defaults (reduce verification code by 60%)
- Standardize library sourcing with auto-discovery based on functions called

### Optimize-Claude Command Robustness Patterns

The optimize-claude command demonstrates exceptional robustness through five-layer architectural pattern: (1) Fail-fast verification at every stage with verification checkpoints between ALL phases catching failures immediately, (2) Agent behavioral injection with strict "Create File FIRST, Analyze LATER" protocol enforced through 28 completion criteria, (3) Library integration sourcing proven algorithms (optimize-claude-md.sh) rather than reimplementing logic, (4) Lazy directory creation via ensure_artifact_directory() enabling atomic topic allocation with 0% collision rate, and (5) Comprehensive test coverage verifying agent structure, completion signals, and behavioral compliance.

Command achieves near-perfect reliability through systematic application of patterns. All specialized agents follow STEP 2 mandatory file creation (create with placeholders BEFORE analysis), guaranteeing artifacts exist even if agent crashes. Verification checkpoints use specific error context ("ERROR: Agent 1 (claude-md-analyzer) failed to create report: $REPORT_PATH_1 - Check agent logs above"), enabling immediate diagnosis. Idempotent operations (directory creation, backup) make command safe to re-run. Strict return format protocol (return ONLY "REPORT_CREATED: [path]", no summary) enables structured parsing and 99% context reduction.

[Full Report](./002_optimize_claude_command_robustness_patterns.md)

**Key Recommendations**:
- Standardize "Create File FIRST" agent pattern across all commands (STEP 2 creates artifact with placeholders before analysis)
- Use library integration for complex logic (extract to testable library functions, agents stay lean <400 lines)
- Implement lazy directory creation universally (ensure_artifact_directory() instead of eager mkdir -p)
- Mandate comprehensive test coverage (verify agent structure, completion signals, file size limits)
- Enforce absolute path validation at entry point (validate all input paths, clear error messages)
- Enrich error messages with context (include agent name, expected artifact, diagnostic hints)
- Design for idempotency (conditional creation patterns, safe to re-run if interrupted)
- Include rollback procedures in plans (clear recovery path if implementation fails)
- Standardize return format protocol (structured completion signal only, file artifacts as source of truth)

### Current Plan Command Implementation

The /plan command exists as 230-line pseudocode template at `/home/benjamin/.config/.claude/commands/plan.md` with comprehensive documentation but NO executable implementation. Architecture is well-designed with Phase 0 pre-analysis (estimates complexity before planning), research delegation (automatically invokes research agents for complex features), progressive structures (all plans start Level 0, expand on-demand), and standards integration (discovers and applies CLAUDE.md standards automatically). Supporting libraries exist (plan-core-bundle.sh with 1,160 lines of proven plan manipulation functions, complexity-utils.sh, complexity-thresholds.sh) but key orchestration functions referenced in template do not exist (analyze_feature_description, extract_requirements, validate-plan.sh, extract-standards.sh).

Template quality is excellent but implementation gap is critical. Command cannot execute without complete rewrite implementing missing core functions, adding argument parsing, creating research delegation logic, and building validation infrastructure. Opportunity exists to implement using robustness patterns from optimize-claude (fail-fast verification, agent behavioral injection, library integration) while avoiding complexity pitfalls from coordinate (subprocess isolation fights, conditional execution path explosion, library dependency chains).

[Full Report](./003_current_plan_command_implementation_review.md)

**Key Recommendations** (Priority Order):
1. **Implement Core Execution (CRITICAL, 8-12 hours)**: Convert plan.md from template to executable command, implement analyze_feature_description() using LLM classifier pattern, implement extract_requirements() function, create validate-plan.sh library, add comprehensive error handling, test with 10+ diverse feature descriptions
2. **Research Delegation Implementation (HIGH, 6-8 hours)**: Complete research delegation workflow, implement complexity trigger logic, create research topic generation, invoke research-specialist agents with Task tool, implement metadata extraction from reports, integrate findings into plan phases
3. **Template Selection System (MEDIUM, 4-6 hours)**: Create template library (feature, bugfix, refactor, architecture, database templates), implement template selection logic in analyze_feature_description(), add template variable substitution
4. **Standards Validation (MEDIUM, 3-4 hours)**: Create validate-plan.sh library, implement metadata validation, check standards references, validate test phases and documentation tasks, generate validation report
5. **Interactive Refinement (LOW, 2-3 hours)**: Add interactive plan review, display summary to user, use AskUserQuestion for adjustments, regenerate with changes, confirm before writing

### Context Preservation and Metadata Passing Strategies

Both coordinate and optimize-claude implement sophisticated context preservation using file-based state persistence, metadata extraction, and aggressive context pruning. Coordinate achieves 95% context reduction through hierarchical supervisor patterns (research-sub-supervisor aggregates metadata from 4+ parallel agents, returns 50-word summaries instead of full outputs). Optimize-claude uses pre-calculated artifact paths (orchestrator calculates all paths upfront, passes absolute paths to subagents via structured prompts, eliminates path calculation overhead).

State persistence uses GitHub Actions-inspired pattern (state-persistence.sh, 392 lines) with init_workflow_state() creating state file, append_workflow_state() following $GITHUB_OUTPUT pattern, and load_workflow_state() with fail-fast validation. Performance: CLAUDE_PROJECT_DIR detection 70% faster via file caching (50ms → 15ms), JSON checkpoint writes atomic at 5-10ms. Metadata extraction (metadata-extraction.sh, 655 lines) provides extract_report_metadata() extracting title, 50-word summary, 3-5 recommendations with cache pattern. Context pruning (context-pruning.sh, 454 lines) implements workflow-specific policies (prune research metadata after planning, prune research and planning after implementation) targeting <30% context usage.

Common pitfalls documented: variable overwriting (libraries pre-initialize variables, solution: save critical variables BEFORE sourcing), missing state verification (silent failures, solution: fail-fast validation with diagnostics), stale context accumulation (solution: aggressive pruning with 95% reduction target), bash history expansion errors (solution: set +H to disable).

[Full Report](./004_context_preservation_and_metadata_passing_strategies.md)

**Key Recommendations**:
- Adopt state persistence pattern for all multi-bash-block commands (use state-persistence.sh, verify after every append, fail-fast if missing)
- Implement metadata extraction (extract 50-word summaries + key recommendations before passing to subagents, achieve 95% context reduction)
- Apply context pruning policies (define workflow-specific rules, prune phase metadata after completion, maintain <30% context usage)
- Use verification checkpoints (add verification after every critical operation, fail-fast error detection, clear diagnostic messages)
- Pre-calculate artifact paths (calculate all paths upfront in orchestrator, pass absolute paths to subagents, enable lazy directory creation)
- Implement hierarchical supervision for 4+ parallel subagents (use supervisor pattern, aggregate metadata, save supervisor checkpoint)
- Avoid common pitfalls (save variables before sourcing libraries, disable history expansion with set +H, use fail-fast validation mode)

## Recommended Approach

### Phase 1: Implement Minimal Viable Plan Command (8-12 hours)

**Objective**: Create executable /plan command using optimize-claude robustness patterns

**Implementation**:
1. **Convert template to executable bash** (2-3 hours)
   - Replace pseudocode with actual execution logic
   - Implement argument parsing (feature description + optional report paths)
   - Add comprehensive error handling with context-enriched messages
   - Validate all paths as absolute at entry point

2. **Implement core analysis functions** (4-6 hours)
   - Create `analyze_feature_description()` using LLM classifier pattern (haiku-4 model for fast classification)
   - Analyze: complexity keywords, scope indicators, technical depth, feature type
   - Return JSON: estimated_complexity, suggested_phases, matching_templates, requires_research
   - Create `extract_requirements()` function for plan complexity calculation
   - Model after metadata-extraction.sh patterns (50-word summaries, key points)

3. **Create validation infrastructure** (2-3 hours)
   - Implement validate-plan.sh library following optimize-claude patterns
   - Validate: metadata complete, standards referenced, test phases present, documentation tasks exist
   - Generate validation report with warnings/errors
   - Add verification checkpoints between phases (fail-fast on missing artifacts)

**Robustness Patterns Applied**:
- Fail-fast verification at phase boundaries (verify artifacts exist before proceeding)
- Absolute path requirements (validate at entry point, clear error messages)
- Error context enrichment (include phase name, expected artifact, diagnostic hints)
- Idempotent operations (safe to re-run if interrupted)

**Success Criteria**:
- Command executes without errors for 10+ diverse feature descriptions
- Generates valid Level 0 plans conforming to project standards
- Validates plans successfully
- Returns structured plan path confirmation

### Phase 2: Add Research Delegation (6-8 hours)

**Objective**: Implement intelligent research orchestration for complex features

**Implementation**:
1. **Complexity trigger logic** (1-2 hours)
   - Check estimated_complexity ≥ 7 from analyze_feature_description()
   - Check complexity keywords: integrate, migrate, refactor, architecture
   - Set REQUIRES_RESEARCH flag

2. **Research topic generation** (2-3 hours)
   - Extract research topics from feature description using LLM analysis
   - Generate report paths using topic-based organization (specs/{NNN_topic}/reports/)
   - Use unified-location-detection.sh for atomic topic allocation (0% collision rate)

3. **Agent invocation with behavioral injection** (2-3 hours)
   - Invoke research-specialist agents with Task tool
   - Pass absolute report paths via structured prompts
   - Use forward_message pattern for metadata extraction
   - Implement verification checkpoint (verify all report files created)

4. **Findings integration** (1 hour)
   - Extract metadata using metadata-extraction.sh (50-word summaries, 3-5 recommendations)
   - Integrate findings into plan phases as reference links
   - Pass summaries to plan creation, not full reports (95% context reduction)

**Context Preservation Patterns Applied**:
- Pre-calculated artifact paths (orchestrator calculates all report paths upfront)
- Metadata extraction (extract summaries instead of passing full reports)
- Verification checkpoints (verify reports exist before proceeding to plan creation)

**Success Criteria**:
- Complex features (complexity ≥7) automatically trigger research
- Research reports created successfully
- Findings integrated into plan phases
- Context usage remains <30% throughout workflow

### Phase 3: Template Selection System (4-6 hours)

**Objective**: Tailor plans to feature type for reduced boilerplate

**Implementation**:
1. **Create template library** (2-3 hours)
   - Extract current uniform template to templates/feature.md
   - Create specialized templates:
     - templates/bugfix.md (focused on root cause, fix validation, regression prevention)
     - templates/refactor.md (focused on code quality, test preservation, rollback)
     - templates/architecture.md (focused on design patterns, migration strategy, documentation)
     - templates/database.md (focused on schema changes, migration scripts, data validation)
   - Document template catalog in templates/README.md

2. **Template selection logic** (1-2 hours)
   - Enhance analyze_feature_description() to detect feature type from description
   - Match feature type to appropriate template
   - Return matching_templates field in JSON response

3. **Variable substitution** (1 hour)
   - Implement template variable substitution ({{FEATURE_NAME}}, {{COMPLEXITY}}, {{ESTIMATED_DURATION}})
   - Apply template with calculated values
   - Validate substituted plan structure

**Success Criteria**:
- Feature type detected correctly for 10+ diverse descriptions
- Appropriate template selected and applied
- Template variables substituted correctly
- Generated plans use tailored structure

### Phase 4: Standards Validation (3-4 hours)

**Objective**: Ensure plans conform to project standards automatically

**Implementation**:
1. **Metadata validation** (1 hour)
   - Check metadata section complete (title, date, type, complexity, dependencies)
   - Validate metadata values (complexity in valid range, type from enum, dependencies exist)

2. **Standards reference checks** (1 hour)
   - Verify Testing Protocols referenced if tests required
   - Verify Documentation Standards referenced if docs required
   - Verify Code Standards referenced for implementation phases
   - Check phase dependencies valid if parallel execution supported

3. **Validation reporting** (1-2 hours)
   - Generate validation report with warnings and errors
   - Classify issues by severity (blocking errors vs. warnings)
   - Provide remediation suggestions
   - Fail-fast on blocking errors

**Success Criteria**:
- Plans validated successfully against discovered standards
- Validation report generated with clear warnings/errors
- Blocking errors prevent plan creation
- Warnings displayed but allow plan creation

## Constraints and Trade-offs

### Constraint 1: Subprocess Isolation Fundamentals

**Description**: Claude Code Bash tool executes each bash block in separate subprocess with different PID, exports don't persist between blocks ([Coordinate Analysis](./001_coordinate_command_architecture_and_fragility_analysis.md), lines 38-108).

**Impact on Plan Command**:
- Multi-bash-block approach requires state persistence infrastructure
- Stateless recalculation pattern adds 2ms overhead per block
- File-based state adds 30ms overhead (30x slower)
- Verification checkpoints proliferate to ensure state persisted

**Trade-off**: Single-block execution (standalone script) vs. multi-block execution (inline bash blocks)
- Single-block: Eliminates state persistence needs, standard bash debugging works, but concentrates all logic in one location
- Multi-block: Enables phase separation in markdown, but requires state management and increases complexity

**Recommended Mitigation**: Use single bash block calling standalone script for orchestration logic, keeping /plan command markdown minimal (<200 lines). Adopt optimize-claude pattern: orchestrator calculates paths, passes to agents, agents create artifacts.

### Constraint 2: Code Transformation at 400+ Lines

**Description**: Claude AI performs unpredictable code transformation on bash blocks ≥400 lines, transforming `grep -E "!(pattern)"` to `grep -E "1(pattern)"` ([Coordinate Analysis](./001_coordinate_command_architecture_and_fragility_analysis.md), lines 303-348).

**Impact on Plan Command**:
- Bash blocks must stay <300 lines (100-line safety margin)
- Large orchestration logic requires splitting into multiple blocks
- Block splitting introduces more subprocess boundaries

**Trade-off**: Consolidated logic vs. split blocks
- Consolidated: Easier to reason about, but risks code transformation bugs
- Split: Safer from transformation, but requires state restoration overhead

**Recommended Mitigation**: Extract large logic to standalone scripts (no line limits, standard bash execution). Keep markdown bash blocks minimal (path calculation, agent invocation only). Adopt modular script approach from recommendations.

### Constraint 3: Context Limit Enforcement

**Description**: Long workflows accumulate full subagent outputs, exceeding context limits without aggressive pruning ([Context Preservation Strategies](./004_context_preservation_and_metadata_passing_strategies.md), lines 90-129).

**Impact on Plan Command**:
- Research delegation with 4+ topics can accumulate excessive context
- Full reports passed to plan creation exceed limits
- Deep workflows (research → plan → implement) compound accumulation

**Trade-off**: Full context availability vs. context efficiency
- Full context: All information available for reference, but risks limit errors
- Aggressive pruning: Prevents limit errors, but loses information access

**Recommended Mitigation**:
- Use metadata extraction for 95% context reduction (50-word summaries + key recommendations only)
- Implement hierarchical supervision for 4+ research topics
- Define pruning policy (prune research metadata after plan creation)
- Target <30% context usage throughout workflow

### Constraint 4: Missing Core Functions

**Description**: Plan command template references functions that don't exist (analyze_feature_description, extract_requirements, validate-plan.sh, extract-standards.sh) ([Plan Implementation Review](./003_current_plan_command_implementation_review.md), lines 138-158).

**Impact on Plan Command**:
- Cannot execute without implementing missing functions
- Template provides specification but not implementation
- Function signatures documented but logic undefined

**Trade-off**: Simple heuristic implementation vs. LLM-based analysis
- Heuristics: Fast execution (1-2ms), predictable behavior, but limited accuracy
- LLM analysis: High accuracy, context-aware, but slower (1-2s) and model cost

**Recommended Mitigation**:
- Use LLM classifier pattern (haiku-4 model) for analyze_feature_description() - accuracy worth latency
- Use heuristics for extract_requirements() - simple parsing sufficient
- Implement validate-plan.sh as bash script with awk/jq parsing
- Extract standards discovery to library following existing patterns

### Constraint 5: Research Delegation Complexity

**Description**: Coordinate's research delegation uses conditional execution path explosion (40 potential paths) and hardcoded agent invocations ([Coordinate Analysis](./001_coordinate_command_architecture_and_fragility_analysis.md), lines 232-258).

**Impact on Plan Command**:
- Need to invoke variable number of research agents (1-N topics)
- Cannot use loops in markdown (Claude interprets as documentation)
- Hardcoded IF conditions don't scale beyond 4 topics

**Trade-off**: Flat invocation (hardcoded IF conditions) vs. hierarchical supervision
- Flat: Simple for 1-3 topics, but doesn't scale, hardcoded limits
- Hierarchical: Scales to N topics, but adds supervisor layer complexity

**Recommended Mitigation**:
- Use flat invocation for 1-3 topics (complexity <7, simple features)
- Use hierarchical supervision for 4+ topics (complexity ≥7, complex features)
- Implement supervisor pattern from coordinate (95% context reduction)
- Supervisor aggregates metadata, returns summaries only

### Constraint 6: Template Uniformity

**Description**: All plans use identical template regardless of feature type, complexity, or domain ([Plan Implementation Review](./003_current_plan_command_implementation_review.md), lines 195-202).

**Impact on Plan Command**:
- Bugfixes get full architecture template with unnecessary sections
- Database migrations lack migration-specific structure
- Boilerplate content increases plan size

**Trade-off**: Single uniform template vs. template library
- Uniform: Simple maintenance, predictable structure, but verbose
- Library: Tailored structure, reduced boilerplate, but maintenance overhead

**Recommended Mitigation**:
- Create template library with 4-5 core templates (feature, bugfix, refactor, architecture, database)
- Use analyze_feature_description() to detect feature type and select template
- Maintain template catalog documentation
- Allow template override via optional --template flag

## Risk Factors

### Risk 1: Implementation Scope Creep

**Description**: Recommended approach spans 21-30 hours across 4 phases with multiple patterns to adopt.

**Severity**: HIGH
**Likelihood**: MEDIUM

**Mitigation Strategies**:
- Implement phases sequentially (Phase 1 → Phase 2 → Phase 3 → Phase 4)
- Validate each phase complete before starting next
- Phase 1 is MVP (minimal viable plan command) - deliverable on its own
- Phases 2-4 are enhancements - can defer if time-constrained
- Use TodoWrite to track progress across phases

### Risk 2: Over-Engineering Like Coordinate

**Description**: Coordinate's complexity (3,763 lines, 13 iterations, 1,485 lines of docs) could be replicated if not careful.

**Severity**: HIGH
**Likelihood**: LOW (if recommendations followed)

**Mitigation Strategies**:
- Follow optimize-claude patterns (fail-fast, library integration, lazy creation)
- Reject state persistence infrastructure (use pre-calculated paths instead)
- Keep agents <400 lines through library extraction
- Limit verification checkpoints to artifact boundaries only (not state mechanics)
- If documentation exceeds 500 lines, architecture is too complex

### Risk 3: LLM Classification Latency

**Description**: Using haiku-4 model for analyze_feature_description() adds 1-2s latency vs. heuristics (1-2ms).

**Severity**: LOW
**Likelihood**: HIGH

**Mitigation Strategies**:
- Accept latency trade-off (accuracy worth 1-2s delay)
- Cache analysis results for repeated feature descriptions
- Use streaming response if available (show progress while analyzing)
- Consider hybrid approach (heuristics for simple features, LLM for complex)

### Risk 4: Template Proliferation

**Description**: Template library could grow to 10+ templates, creating maintenance burden.

**Severity**: MEDIUM
**Likelihood**: MEDIUM

**Mitigation Strategies**:
- Start with 4-5 core templates only (feature, bugfix, refactor, architecture, database)
- Document clear criteria for when new template needed
- Require 5+ use cases before creating specialized template
- Use template inheritance (base template + type-specific sections)
- Review template catalog quarterly, remove unused templates

### Risk 5: Research Delegation Failures

**Description**: Research agents could fail mid-execution, leaving incomplete reports.

**Severity**: MEDIUM
**Likelihood**: LOW (if optimize-claude patterns used)

**Mitigation Strategies**:
- Use "Create File FIRST" pattern (agents create placeholder before analysis)
- Add verification checkpoints after research phase (verify all report files exist)
- Check file size >500 bytes (detect placeholder-only files)
- Implement fallback: if research fails, proceed with plan creation using feature description only
- Log research failures for user review

### Risk 6: Standards Discovery Brittleness

**Description**: Standards discovery relies on CLAUDE.md existence and specific section structure.

**Severity**: LOW
**Likelihood**: MEDIUM

**Mitigation Strategies**:
- Implement graceful degradation (use sensible defaults if CLAUDE.md missing)
- Support multiple section formats (<!--SECTION:name--> and ## Section Name)
- Validate standards content before applying (check for required fields)
- Log standards discovery results (show what was found vs. defaults used)
- Suggest /setup command if CLAUDE.md incomplete
