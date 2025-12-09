# Three-Tier Agent Pattern Improvements Analysis

## Metadata
- **Date**: 2025-12-08
- **Agent**: research-specialist
- **Topic**: three-tier-agent-improvements
- **Report Type**: codebase analysis

## Executive Summary

This analysis synthesizes recommendations from spec 015 research report into actionable implementation tasks for extending the three-tier agent pattern (orchestrator → coordinator → specialist) across the .claude/ system. The research identified 4 existing coordinators (research, implementer, lean, conversion), but only research workflows currently use the full three-tier pattern. Key gaps include missing coordinators for testing/debug/repair workflows, lack of centralized three-tier pattern documentation, and minimal skills catalog (only 1 skill exists). Implementation is prioritized into 4 phases: Foundation (3 items, 5-8 hours), Coordinator Expansion (3 items, 12-18 hours), Skills Expansion (3 items, 20-26 hours), and Advanced Capabilities (3 items, 26-34 hours).

## Findings

### Finding 1: Coordinator Pattern Limited to Research Workflows
- **Description**: Only research-coordinator implements full supervisor-based parallel orchestration with metadata-only passing (95% context reduction). Testing, debug, and repair workflows still use direct agent invocation without coordinator intermediaries.
- **Location**:
  - /home/benjamin/.config/.claude/agents/research-coordinator.md (lines 1-635, exemplary pattern)
  - /home/benjamin/.config/.claude/agents/implementer-coordinator.md (lines 1-975, wave-based pattern exists)
  - /home/benjamin/.config/.claude/commands/test.md (lines 1-150, direct test-executor invocation)
  - /home/benjamin/.config/.claude/commands/debug.md (lines 1-150, direct debug-analyst invocation)
  - /home/benjamin/.config/.claude/commands/repair.md (lines 1-150, direct repair-analyst invocation)
- **Evidence**: Research-coordinator demonstrates supervisor pattern:
  - Topic decomposition (2-5 topics based on complexity)
  - Path pre-calculation (hard barrier pattern)
  - Parallel specialist invocation via Task tool
  - Artifact validation (fail-fast on missing reports)
  - Metadata extraction (110 tokens per report vs 2,500 tokens full content)
  - Two invocation modes: automated decomposition and manual pre-decomposition
- **Impact**: High. Test, debug, and repair workflows miss 40-60% time savings from parallelization and 95% context reduction from metadata aggregation. Extending coordinator pattern to these workflows would provide consistent orchestration architecture.

### Finding 2: Missing Three-Tier Pattern Guide and Coordinator Template
- **Description**: No centralized documentation exists describing when to use three-tier vs two-tier vs single-tier agent patterns. Only sub-supervisor-template.md exists, but no coordinator-specific template based on research-coordinator structure.
- **Location**:
  - /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-*.md (7 files, comprehensive but no three-tier decision guide)
  - /home/benjamin/.config/.claude/agents/templates/sub-supervisor-template.md (lines 1-100, sub-supervisor only)
  - No file found: .claude/docs/concepts/three-tier-agent-pattern.md
  - No file found: .claude/agents/templates/coordinator-template.md
- **Evidence**: Hierarchical agent documentation covers patterns, examples, coordination, communication, and troubleshooting, but lacks:
  - Decision matrix for tier selection (when to use 1-tier, 2-tier, 3-tier)
  - Migration guide from existing two-tier patterns to three-tier
  - Reusable coordinator template based on research-coordinator (path pre-calc, hard barrier, metadata extraction)
  - Implementation checklist for new coordinators
- **Impact**: Medium-High. Without centralized guidance, developers must reverse-engineer research-coordinator for each new coordinator implementation. Template would reduce coordinator development time from 4-6 hours to 2-3 hours.

### Finding 3: Minimal Skills Catalog with High Extraction Potential
- **Description**: Only 1 skill exists (document-converter) despite 5 high-priority candidates identified in spec 015 research: research-specialist, plan-generator, test-orchestrator, doc-analyzer, code-reviewer.
- **Location**:
  - /home/benjamin/.config/.claude/skills/document-converter/ (only existing skill)
  - /home/benjamin/.config/.claude/skills/README.md (skills architecture documentation)
  - No skills found for: research, planning, testing, documentation analysis, code review
- **Evidence**: Skills infrastructure supports autonomous invocation, progressive disclosure, and agent auto-loading, but catalog is underdeveloped:
  - Spec 015 identified research-specialist as high-priority skill candidate (currently agent-only)
  - Test discovery/execution logic embedded in /test command (lines 1-150) could be extracted
  - Plan creation logic embedded in plan-architect agent could be extracted
  - No skills exist for autonomous code quality enforcement or documentation validation
- **Impact**: Medium. Skills enable autonomous composition and broader applicability beyond explicit command invocation. Extracting research-specialist to skill would enable auto-triggered research in any workflow, not just /research command. However, current agent-based approach is functional, making this optimization rather than critical.

### Finding 4: Implementer-Coordinator Already Exists with Wave-Based Pattern
- **Description**: Spec 015 recommendations suggested creating implementation-coordinator, but implementer-coordinator.md already exists and implements wave-based parallel execution with dependency analysis.
- **Location**: /home/benjamin/.config/.claude/agents/implementer-coordinator.md (lines 1-975, complete coordinator implementation)
- **Evidence**: Implementer-coordinator implements:
  - Dependency analysis via dependency-analyzer utility (STEP 2, lines 87-127)
  - Wave orchestration with parallel executor invocation (STEP 4, lines 248-447)
  - Iteration management with context estimation (STEP 3, lines 128-246)
  - Progress monitoring and result aggregation (lines 332-447)
  - Structured metadata return with brief summaries (lines 510-708)
  - Multi-iteration execution support (lines 812-896)
- **Impact**: Low. Recommendation to create implementation-coordinator is already complete. However, naming inconsistency exists (implementer-coordinator vs implementation-coordinator suggested name). No action needed beyond noting the existing implementation.

### Finding 5: Sub-Supervisor Template Exists but Not Coordinator-Specific
- **Description**: Agent template directory contains sub-supervisor-template.md but lacks coordinator-specific template based on research-coordinator hard barrier pattern.
- **Location**:
  - /home/benjamin/.config/.claude/agents/templates/sub-supervisor-template.md (lines 1-100, generic supervisor pattern)
  - /home/benjamin/.config/.claude/agents/templates/README.md (template directory index)
  - No file found: coordinator-template.md
- **Evidence**: Sub-supervisor template provides:
  - Generic parallel worker coordination pattern
  - Metadata aggregation approach (95% context reduction)
  - Template variables for customization ({{SUPERVISOR_TYPE}}, {{WORKER_TYPE}}, etc.)
  - BUT lacks hard barrier pattern specifics (path pre-calculation, artifact validation, fail-fast)
  - Does not include two-mode support (automated vs manual pre-decomposition)
- **Impact**: Medium. Sub-supervisor template is useful but insufficient for coordinator agents requiring hard barrier pattern. Research-coordinator has 635 lines of coordinator-specific logic (topic decomposition, path pre-calc, validation) that should be templated for reuse in testing/debug/repair coordinators.

### Finding 6: Testing, Debug, and Repair Commands Use Direct Agent Invocation
- **Description**: Test, debug, and repair commands invoke specialist agents directly without coordinator intermediaries, missing parallelization and context reduction opportunities.
- **Location**:
  - /home/benjamin/.config/.claude/commands/test.md (lines 1-150, direct test-executor invocation in Block 1)
  - /home/benjamin/.config/.claude/commands/debug.md (lines 1-150, direct debug-analyst invocation in Block 1)
  - /home/benjamin/.config/.claude/commands/repair.md (lines 1-150, direct repair-analyst invocation in Block 1)
- **Evidence**: Command patterns show two-tier architecture:
  - /test: orchestrator → test-executor (no testing-coordinator)
  - /debug: orchestrator → debug-analyst (no debug-coordinator)
  - /repair: orchestrator → repair-analyst (no repair-coordinator)
  - All three commands use sequential single-agent execution instead of parallel multi-specialist pattern
- **Impact**: High. Test suites with multiple categories (unit, integration, e2e) could run in parallel via testing-coordinator. Debug investigations could parallelize across vectors (logs, code, dependencies) via debug-coordinator. Error pattern analysis could parallelize across error types or timeframes via repair-coordinator. Estimated time savings: 40-60% for typical workflows.

## Recommendations

Implementation is prioritized into 4 phases based on spec 015 priority matrix (impact vs effort). All recommendations are actionable and reference specific findings above.

### Phase 1: Foundation (High Priority, Low Effort - 5-8 hours total)

1. **Create Three-Tier Pattern Guide** (Finding 2, 2-3 hours):
   - **Location**: /home/benjamin/.config/.claude/docs/concepts/three-tier-agent-pattern.md
   - **Content**:
     - Pattern definition: orchestrator → coordinator → specialist with metadata aggregation
     - Benefits: 40-60% time savings (parallelization), 95% context reduction (metadata-only passing)
     - Decision matrix: When to use 1-tier (simple), 2-tier (single specialist), 3-tier (multiple specialists)
     - Implementation checklist for new three-tier workflows
     - Migration guide from two-tier to three-tier patterns
   - **Cross-reference**: Link from CLAUDE.md hierarchical agent section, command authoring standards
   - **Rationale**: Establishes clear target architecture for all future command development, reduces reverse-engineering time from 2-3 hours to 15-30 minutes per coordinator

2. **Create Coordinator Template** (Finding 2, Finding 5, 2-3 hours):
   - **Location**: /home/benjamin/.config/.claude/agents/templates/coordinator-template.md
   - **Base**: Research-coordinator.md structure (635 lines)
   - **Sections**:
     - Input contract specification (topics, report_dir, context)
     - Two-mode support (automated decomposition vs manual pre-decomposition)
     - Topic decomposition logic template with complexity mapping
     - Path pre-calculation pattern (hard barrier enforcement)
     - Parallel specialist invocation template via Task tool
     - Hard barrier validation (fail-fast on missing artifacts)
     - Metadata extraction utilities (title, counts, aggregation)
     - Error return protocol (validation_error, agent_error, file_error)
   - **Template Variables**: {{COORDINATOR_TYPE}}, {{SPECIALIST_TYPE}}, {{ARTIFACT_TYPE}}, {{METADATA_FIELDS}}
   - **Rationale**: Reduces coordinator development time from 4-6 hours (reverse-engineer research-coordinator) to 2-3 hours (customize template). Ensures consistency across testing/debug/repair coordinators.

3. **Validate and Fix Cross-References** (Finding 2, 1-2 hours):
   - **Tool**: /home/benjamin/.config/.claude/scripts/validate-links-quick.sh
   - **Actions**:
     - Run link validator on all command files (.claude/commands/*.md)
     - Run link validator on all agent files (.claude/agents/*.md)
     - Identify outdated documentation paths (references to old doc structure)
     - Update broken links to current doc locations
     - Verify three-tier pattern guide links from CLAUDE.md after creation
   - **Rationale**: Improves documentation accuracy and discoverability. Prevents confusion from outdated references. Part of spec 015 "Documentation Uniformity" gap.

### Phase 2: Coordinator Expansion (High Priority, Medium Effort - 12-18 hours total)

4. **Implement testing-coordinator** (Finding 1, Finding 6, 4-6 hours):
   - **Location**: /home/benjamin/.config/.claude/agents/testing-coordinator.md
   - **Pattern**: Parallel test-specialist invocation (similar to research-coordinator)
   - **Delegation**: test-specialist agents per test category (unit, integration, e2e)
   - **Metadata**: pass/fail counts, coverage percentages, execution time per category
   - **Integration**: /test command (replace direct test-executor invocation)
   - **Benefits**:
     - Parallel test execution across categories (40-60% time savings for multi-category test suites)
     - Metadata aggregation: 110 tokens per test category vs 2,500 tokens full test output (95% reduction)
     - Partial success mode: Continue with other categories if one fails
   - **Rationale**: Test suites with 3+ categories (unit, integration, e2e) see immediate time savings. High impact for projects with comprehensive test coverage.

5. **Implement debug-coordinator** (Finding 1, Finding 6, 4-6 hours):
   - **Location**: /home/benjamin/.config/.claude/agents/debug-coordinator.md
   - **Pattern**: Parallel debug-specialist invocation per investigation vector
   - **Delegation**: debug-specialist agents per vector (logs, code analysis, dependency chain, environment)
   - **Metadata**: findings, root cause candidates, confidence scores per vector
   - **Integration**: /debug command (replace direct debug-analyst invocation)
   - **Benefits**:
     - Parallel investigation across multiple debugging angles (40-60% faster root cause identification)
     - Comprehensive coverage: Logs, code, dependencies, environment investigated simultaneously
     - Metadata aggregation: 110 tokens per investigation vector vs 2,500 tokens full analysis
   - **Rationale**: Complex bugs often require multi-angle investigation. Parallel approach identifies root cause faster than sequential investigation.

6. **Implement repair-coordinator** (Finding 1, Finding 6, 4-6 hours):
   - **Location**: /home/benjamin/.config/.claude/agents/repair-coordinator.md
   - **Pattern**: Parallel repair-analyst invocation per error dimension
   - **Delegation**: repair-analyst agents per dimension (error type, timeframe, command, severity)
   - **Metadata**: error patterns, fix recommendations, affected components per dimension
   - **Integration**: /repair command (replace direct repair-analyst invocation)
   - **Benefits**:
     - Parallel error pattern analysis across dimensions (error type, timeframe, command)
     - Comprehensive analysis: Multiple error dimensions analyzed simultaneously
     - Metadata aggregation: 110 tokens per dimension vs 2,500 tokens full error logs
   - **Rationale**: Error logs often have multiple patterns (by type, by command, by time). Parallel analysis provides comprehensive view faster.

### Phase 3: Skills Expansion (Medium Priority, Medium-High Effort - 20-26 hours total)

7. **Extract research-specialist skill** (Finding 3, 6-8 hours):
   - **Location**: /home/benjamin/.config/.claude/skills/research-specialist/SKILL.md
   - **Scope**: Research protocol from research-specialist.md agent
   - **Changes**:
     - Convert agent to autonomous skill (model-invoked when research needs detected)
     - Maintain Task invocation path for coordinators (backward compatibility)
     - Add skills: research-specialist to agent frontmatter for auto-loading
   - **Integration**: Commands, agents, and user conversations benefit without explicit delegation
   - **Benefit**: Auto-triggers research when Claude detects research needs, broader applicability beyond /research command
   - **Rationale**: Research is frequently needed capability across workflows. Autonomous skill provides seamless research without explicit command invocation.

8. **Extract plan-generator skill** (Finding 3, 6-8 hours):
   - **Location**: /home/benjamin/.config/.claude/skills/plan-generator/SKILL.md
   - **Scope**: Plan creation logic from plan-architect agent (metadata, phases, success criteria)
   - **Integration**: /create-plan, /repair, /debug workflows (reusable planning across commands)
   - **Changes**:
     - Extract plan generation algorithm (metadata validation, phase structure, dependency syntax)
     - Skill invokes plan-architect agent for complex logic (delegation pattern)
     - Commands delegate to skill, skill invokes agent if needed
   - **Benefit**: Reusable planning logic across multiple workflows, reduces duplication
   - **Rationale**: Plan creation pattern repeats across /create-plan, /repair, /debug. Extracting to skill enables consistent plan quality across workflows.

9. **Create test-orchestrator skill** (Finding 3, 8-10 hours):
   - **Location**: /home/benjamin/.config/.claude/skills/test-orchestrator/SKILL.md
   - **Scope**: Test discovery, execution, coverage analysis from /test command
   - **Integration**:
     - Auto-triggers after implementation phases (autonomous testing enforcement)
     - Explicit invocation via /test command
   - **Changes**:
     - Extract test discovery logic (glob patterns, test file identification)
     - Extract test execution logic (framework detection, test running)
     - Extract coverage analysis logic (threshold checking, report generation)
   - **Benefit**: Autonomous test invocation during development, quality enforcement without explicit command
   - **Rationale**: Testing should be automatic after implementation. Skill enables autonomous test execution without developer remembering to invoke /test.

### Phase 4: Advanced Capabilities (Lower Priority, High Effort - 26-34 hours total)

10. **Create doc-analyzer skill** (Finding 3, 8-10 hours):
    - **Location**: /home/benjamin/.config/.claude/skills/doc-analyzer/SKILL.md
    - **Scope**: Documentation structure analysis, gap identification, cross-reference validation
    - **Integration**: Auto-trigger on doc changes, explicit via /doc-check command (new)
    - **Changes**:
      - Implement README structure validation (per documentation-standards.md)
      - Implement cross-reference validation (link checking)
      - Implement documentation gap detection (missing sections, outdated content)
    - **Benefit**: Maintains documentation quality automatically, prevents doc drift
    - **Rationale**: Documentation quality degrades over time without active maintenance. Autonomous skill prevents drift.

11. **Create code-reviewer skill** (Finding 3, 8-10 hours):
    - **Location**: /home/benjamin/.config/.claude/skills/code-reviewer/SKILL.md
    - **Scope**: Linting, complexity bounds, security checks (from industry best practices - spec 015 lines 147-150)
    - **Integration**: Auto-trigger after implementation, explicit via /review command (new)
    - **Changes**:
      - Implement linting integration (language-specific linters)
      - Implement complexity analysis (cyclomatic complexity, function length)
      - Implement security checks (pattern detection for common vulnerabilities)
    - **Benefit**: Enforces code quality automatically without manual review invocation
    - **Rationale**: Industry best practice (Builder.io Blog, 2025) for test-driven agent workflows includes code-review subagent. Autonomous skill provides this capability.

12. **Standardize Checkpoint Format v3.0** (Finding 4 indirect, 10-12 hours):
    - **Location**: Update /home/benjamin/.config/.claude/lib/workflow/checkpoint-utils.sh
    - **Issue**: Different commands use different checkpoint schemas (inconsistent state recovery)
    - **Solution**: Define standardized checkpoint schema v3.0 with mandatory fields
    - **Mandatory Fields**: version, timestamp, command_name, workflow_id, state_file, continuation_context, iteration, max_iterations
    - **Benefits**: Resume across command boundaries, better state recovery, consistent checkpoint handling
    - **Migration**: Update /implement, /test, /debug, /repair commands to use v3.0 schema
    - **Rationale**: Checkpoint format inconsistency prevents cross-command resumption. Standardized schema enables workflow continuity across different commands.

## References

### Primary Source
- /home/benjamin/.config/.claude/specs/015_claude_config_agent_optimization/reports/001-research-my-claudecommands-and-suppor.md (lines 1-427, complete research report with recommendations)

### Coordinator Agents Analyzed
- /home/benjamin/.config/.claude/agents/research-coordinator.md (lines 1-635, exemplary coordinator pattern)
- /home/benjamin/.config/.claude/agents/implementer-coordinator.md (lines 1-975, wave-based execution pattern)
- /home/benjamin/.config/.claude/agents/lean-coordinator.md (existing coordinator)
- /home/benjamin/.config/.claude/agents/conversion-coordinator.md (existing coordinator)

### Commands Analyzed
- /home/benjamin/.config/.claude/commands/test.md (lines 1-150, direct agent invocation pattern)
- /home/benjamin/.config/.claude/commands/debug.md (lines 1-150, direct agent invocation pattern)
- /home/benjamin/.config/.claude/commands/repair.md (lines 1-150, direct agent invocation pattern)

### Templates and Documentation
- /home/benjamin/.config/.claude/agents/templates/sub-supervisor-template.md (lines 1-100, generic supervisor template)
- /home/benjamin/.config/.claude/agents/templates/README.md (template directory index)
- /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md (hierarchical agent architecture)
- /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-coordination.md (coordination patterns)
- /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-communication.md (communication protocols)
- /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-patterns.md (design patterns)
- /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md (practical examples)
- /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-troubleshooting.md (troubleshooting guide)

### Skills Infrastructure
- /home/benjamin/.config/.claude/skills/document-converter/SKILL.md (only existing skill)
- /home/benjamin/.config/.claude/skills/README.md (skills architecture documentation)

### Standards and Guidelines
- /home/benjamin/.config/CLAUDE.md (project configuration index with hierarchical agent section)
- /home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md (command development patterns)
- /home/benjamin/.config/.claude/docs/reference/standards/documentation-standards.md (README requirements)

### Validation Tools
- /home/benjamin/.config/.claude/scripts/validate-links-quick.sh (cross-reference validation utility)
