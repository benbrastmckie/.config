# Opus Subagent Design Pattern Research Report

## Metadata
- **Date**: 2025-11-14
- **Agent**: research-specialist
- **Topic**: Opus Subagent Design Pattern
- **Report Type**: Codebase analysis

## Executive Summary

The .claude/agents/ directory implements specialized AI agents using a behavioral injection pattern where agents are defined through markdown files with YAML frontmatter. Opus-tier agents (3 of 31 total agents) are reserved for high-stakes architectural decisions requiring advanced reasoning: plan-architect (42 completion criteria), debug-specialist (38 criteria), and plan-structure-manager. All agents follow strict completion criteria frameworks (28-42 requirements), shared protocol standards (progress streaming, error handling), and model selection based on task complexity rather than agent importance.

## Findings

### 1. Agent Architecture Overview

**Location**: `/home/benjamin/.config/.claude/agents/`

**Current Agent Count**: 31 specialized agents across 6 categories
- Research: research-specialist, implementation-researcher, research-synthesizer
- Planning: plan-architect, plan-structure-manager, revision-specialist
- Implementation: code-writer, implementation-executor, implementer-coordinator
- Debugging: debug-specialist, debug-analyst
- Documentation: doc-writer, doc-converter, spec-updater
- Analysis: complexity-estimator, metrics-specialist, code-reviewer

**Source**: `.claude/agents/README.md:1-21`

### 2. Agent Definition Structure

**Behavioral Files Format**:
```markdown
---
allowed-tools: Read, Write, Grep, Glob, WebSearch, Bash
description: Brief description of agent purpose
model: opus-4.1
model-justification: Rationale for model tier selection
fallback-model: sonnet-4.5
---

# Agent Name

[Behavioral guidelines and protocols]
```

**Key Components**:
- **Frontmatter Metadata**: YAML section defining tools, model, description
- **Behavioral Guidelines**: Step-by-step execution instructions with imperative language
- **Completion Criteria**: 28-42 explicit requirements (all must be met)
- **Shared Protocols**: References to progress streaming and error handling standards

**Source**: `.claude/agents/research-specialist.md:1-7`, `.claude/agents/README.md:349-378`

### 3. Opus Model Selection Pattern

**Three Opus-Tier Agents** (out of 31 total):

**1. plan-architect** (`plan-architect.md:4-6`):
- **Model**: opus-4.1
- **Justification**: "42 completion criteria, complexity calculation, multi-phase planning, architectural decisions justify premium model"
- **Fallback**: sonnet-4.5
- **Task Complexity**: Architectural planning with tier selection (Tier 1/2/3), complexity scoring algorithm, research integration
- **Invocation Frequency**: Medium (~8/week)

**2. debug-specialist** (`debug-specialist.md:4-6`):
- **Model**: opus-4.1
- **Justification**: "Complex causal reasoning and multi-hypothesis debugging for critical production issues, high-stakes root cause identification with 38 completion criteria"
- **Fallback**: sonnet-4.5
- **Task Complexity**: Multi-hypothesis root cause analysis, evidence-based debugging, production issue resolution
- **Invocation Frequency**: Low (specialized use for critical failures)

**3. plan-structure-manager** (`plan-structure-manager.md:4-6`):
- **Model**: opus-4.1
- **Justification**: "Architectural decisions, structure analysis, impact assessment, bidirectional operations require advanced planning"
- **Fallback**: sonnet-4.5
- **Task Complexity**: Bidirectional plan transformation (expand/collapse), structure impact analysis
- **Invocation Frequency**: Medium (~5/week)

**Model Selection Criteria** (from `model-selection-guide.md:59-78`):
- **Opus 4.1**: System architecture design, critical debugging, multi-hypothesis analysis, complex structure management, strategic technical decisions
- **Cost**: 5x Sonnet, 25x Haiku ($0.075/1K tokens)
- **Quality**: 15-25% improvement over Sonnet for complex tasks
- **Use When**: High-stakes correctness, deep reasoning, multiple competing constraints, system-wide impact

### 4. Behavioral Injection Pattern

**Core Mechanism** (`.claude/docs/concepts/patterns/behavioral-injection.md:41-65`):

Commands orchestrate agents by:
1. **Role Clarification**: Explicit "YOU ARE THE ORCHESTRATOR" declarations prevent direct execution
2. **Path Pre-Calculation**: Orchestrator calculates all artifact paths before agent invocation
3. **Context Injection**: Structured data passed in agent prompt (paths, constraints, specifications)
4. **Agent Reads Behavioral File**: Agent loads guidelines from `.claude/agents/{agent-name}.md`
5. **Agent Executes**: Uses injected context + behavioral rules to complete task

**Invocation Template**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Task description"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/{agent-name}.md

    INPUTS:
    - Artifact Path: ${PRE_CALCULATED_PATH}
    - Task Context: ${SPECIFIC_REQUIREMENTS}

    REQUIRED OUTPUT:
    {COMPLETION_SIGNAL}: /absolute/path
}
```

**Source**: `.claude/docs/concepts/patterns/behavioral-injection.md:104-177`

### 5. Completion Criteria Framework

**All Agents Require Explicit Completion Criteria** (28-42 requirements):

**research-specialist** (28 criteria, `research-specialist.md:322-411`):
- File Creation (4 requirements): Absolute paths, Write tool usage, >500 bytes
- Content Completeness (7 requirements): Executive summary, findings, recommendations, references with line numbers
- Research Quality (5 requirements): ≥3 sources, evidence-based conclusions, actionable recommendations
- Process Compliance (6 requirements): All steps executed, progress markers emitted
- Return Format (4 requirements): Exact path confirmation, no summary text

**plan-architect** (42 criteria, `plan-architect.md:4`):
- Requirements analysis, complexity calculation, tier selection
- Research integration, dependency mapping
- Phase breakdown with task injection
- Testing protocols, git workflow integration

**debug-specialist** (38 criteria, `debug-specialist.md:5`):
- Evidence gathering (logs, traces, code context, recent changes)
- Multi-hypothesis formation (2-3 hypotheses minimum)
- Root cause identification with supporting evidence
- Solution proposals (quick fix, proper fix, long-term fix)

**Pattern**: Completion criteria ensure 100% file creation rate and standardized output quality.

### 6. Shared Protocol Standards

**Progress Streaming Protocol** (`agents/shared/progress-streaming-protocol.md`):
- **Format**: `PROGRESS: <brief-message>` (5-10 words, <60 chars)
- **Required Milestones**: Starting, Reading Context, Analyzing, Planning, Executing, Testing, Verifying, Completing
- **Example**: `PROGRESS: Creating report file at specs/reports/001_auth.md`
- **Benefits**: Real-time visibility, bottleneck detection, multi-agent coordination

**Error Handling Guidelines** (`agents/shared/error-handling-guidelines.md`):
- **Error Classification**: Transient (retryable), Permanent (fix then retry), Fatal (abort)
- **Retry Strategies**: Exponential backoff (500ms, 1s, 2s), max 3-4 attempts
- **Fallback Patterns**: Complex edit → simpler edit → full write, unknown test → language defaults
- **Graceful Degradation**: Partial implementation, reduced functionality, conservative approach

**Source**: Saved 200 LOC through duplication removal while standardizing behavior

### 7. Agent Registry and Tracking

**Registry Schema** (`.claude/agents/agent-registry.json`):
```json
{
  "schema_version": "1.0.0",
  "agents": {
    "agent-name": {
      "type": "specialized|hierarchical",
      "category": "research|planning|implementation|debugging|documentation|analysis",
      "description": "Brief description",
      "tools": ["Read", "Write", "Edit", "Bash", ...],
      "metrics": {
        "total_invocations": 0,
        "successful_invocations": 0,
        "failed_invocations": 0,
        "average_duration_seconds": 0.0
      },
      "dependencies": [],
      "behavioral_file": ".claude/agents/agent-name.md"
    }
  }
}
```

**Categories** (`agent-registry-schema.json:33`):
- research, planning, implementation, debugging, documentation, analysis, coordination

**Type Classification** (`agent-registry-schema.json:28-29`):
- **specialized**: Single-purpose worker agents
- **hierarchical**: Agents that coordinate subagents (supervisors)

**Metrics Tracking**: Total/successful/failed invocations, average duration, last invocation timestamp

### 8. Hierarchical Supervisor Pattern

**Sub-Supervisor Template** (`.claude/agents/templates/sub-supervisor-template.md`):

**Purpose**: Coordinate 4+ workers in parallel achieving 95% context reduction through metadata aggregation

**Template Variables**:
- `{{SUPERVISOR_TYPE}}`: research, implementation, testing
- `{{WORKER_TYPE}}`: Specific agent type to coordinate
- `{{WORKER_COUNT}}`: Number of parallel workers (typically 4)
- `{{OUTPUT_TYPE}}`: reports, code_changes, tests
- `{{METADATA_FIELDS}}`: key_findings, files_modified, test_results

**8-Step Execution Protocol** (`sub-supervisor-template.md:87-482`):
1. Load workflow state from persistence layer
2. Parse supervisor inputs (tasks, output directory, supervisor ID)
3. Invoke workers in parallel (single message, multiple Task invocations)
4. Extract worker metadata (title, summary, key findings)
5. Aggregate metadata (combine summaries, merge findings, calculate totals)
6. Save supervisor checkpoint for resume capability
7. Handle partial failures (≥50% success threshold)
8. Return aggregated metadata ONLY (not full worker outputs)

**Performance Characteristics**:
- **Context Reduction**: 95% (10,000 tokens → 500 tokens)
- **Time Savings**: 73% through parallel execution (45s → 12s for 4 workers)
- **Threshold**: Use when ≥4 workers, >2,000 tokens per worker output

**Examples**:
- research-sub-supervisor: Coordinates 4 research-specialist agents
- implementation-sub-supervisor: Coordinates parallel implementation tracks
- testing-sub-supervisor: Coordinates sequential test lifecycle stages

### 9. Agent Consolidation History

**Recent Consolidation** (2025-10-27, `.claude/agents/README.md:9-22`):

**Agents Consolidated**:
- expansion-specialist + collapse-specialist → plan-structure-manager (95% overlap eliminated, 506 lines saved)
- plan-expander → Archived (pure coordination wrapper, 562 lines saved)
- git-commit-helper → Refactored to `.claude/lib/git-commit-utils.sh` (100 lines saved, zero agent invocation overhead)

**Impact**:
- Agents: 22 → 19 (14% reduction)
- Code reduction: 1,168 lines saved
- Performance: Zero invocation overhead for deterministic operations
- Architecture: Unified operation parameter pattern

**Pattern**: Deterministic logic moves to utility libraries, behavioral logic stays in agents

### 10. Command Architecture Standards Integration

**Standard 0: Execution Enforcement** (`.claude/docs/reference/command_architecture_standards.md:50-199`):

**Imperative Language Requirements**:
- **Critical Operations**: "CRITICAL:", "ABSOLUTE REQUIREMENT" (file creation, data integrity)
- **Mandatory Steps**: "YOU MUST", "REQUIRED", "EXECUTE NOW" (essential steps)
- **Verification Checkpoints**: "MANDATORY VERIFICATION" blocks after file operations

**Pattern Examples**:
```markdown
**EXECUTE NOW - Calculate Report Paths**
[bash code block]
**Verification**: Confirm paths calculated before continuing.

**MANDATORY VERIFICATION - Report File Existence**
[bash verification code]
**REQUIREMENT**: This verification is NOT optional.
```

**Benefits**: 100% file creation rate through explicit enforcement, prevents Claude from skipping steps

### 11. Model Selection Guide

**Decision Framework** (`.claude/docs/guides/model-selection-guide.md:14-78`):

**Haiku 4.5 ($0.003/1K tokens)**: Deterministic tasks
- Template-based generation, mechanical file operations
- External tool orchestration, rule-based analysis
- State tracking, data parsing
- Examples: spec-updater, doc-converter, implementer-coordinator

**Sonnet 4.5 ($0.015/1K tokens)**: Complex reasoning
- Code generation, research synthesis
- Test design, documentation writing
- Error diagnosis, integration analysis
- Examples: research-specialist, code-writer, test-specialist

**Opus 4.1 ($0.075/1K tokens)**: Architectural decisions
- System architecture design, critical debugging
- Multi-hypothesis root cause analysis
- Complex structure management, strategic decisions
- Examples: plan-architect, debug-specialist, plan-structure-manager

**Selection Criteria**: Match model capability to task complexity, not agent importance

## Recommendations

### 1. Use Opus Tier for High-Stakes Architectural Decisions Only

**Rationale**: Opus costs 5x Sonnet and 25x Haiku, justified only when architectural correctness is critical.

**Guidelines**:
- **Use Opus When**: Multi-hypothesis debugging, system architecture planning, complex structural transformations, trade-off analysis with system-wide impact
- **Use Sonnet When**: Complex reasoning but not architectural (research synthesis, code generation, test design)
- **Use Haiku When**: Deterministic operations with explicit algorithms (state tracking, file operations, tool orchestration)

**Cost Impact**: Proper tier selection achieves 80% cost reduction for deterministic tasks while maintaining quality

**Reference**: Model Selection Guide (`.claude/docs/guides/model-selection-guide.md:14-150`)

### 2. Implement Strict Completion Criteria for All New Agents

**Rationale**: 28-42 explicit completion criteria ensure 100% file creation rate and standardized output quality.

**Required Sections**:
- **File Creation** (4-5 criteria): Absolute paths, Write tool usage, size verification, existence checks
- **Content Completeness** (5-7 criteria): All sections filled (not placeholders), structured markdown, metadata complete
- **Quality Standards** (3-5 criteria): Evidence-based findings, actionable recommendations, file references with line numbers
- **Process Compliance** (4-6 criteria): All steps executed in order, progress markers emitted, verification checkpoints passed
- **Return Format** (2-4 criteria): Exact signal format, path confirmation, no summary text substitution

**Template**: Use research-specialist completion criteria (322-411) as reference implementation

**Reference**: Research Specialist Agent (`.claude/agents/research-specialist.md:322-411`)

### 3. Leverage Behavioral Injection for Complex Multi-Agent Workflows

**Rationale**: Behavioral injection achieves 100% file creation through explicit path pre-calculation and role separation.

**Implementation Pattern**:
1. **Orchestrator Pre-Calculates Paths**: Use `create_topic_artifact()` utility before agent invocation
2. **Inject Complete Context**: Pass absolute paths, constraints, success criteria in agent prompt
3. **Agent Reads Behavioral File**: `Read and follow: .claude/agents/{agent-name}.md`
4. **Enforce Completion Signal**: Require exact format (e.g., `REPORT_CREATED: /path`)
5. **Mandatory Verification**: Check file existence, execute fallback creation if missing

**Benefits**:
- 100% file creation rate (vs variable rates without enforcement)
- <30% context usage through metadata-only passing
- Hierarchical multi-agent coordination (supervisors + workers)
- Parallel execution capability (40-60% time savings)

**Reference**: Behavioral Injection Pattern (`.claude/docs/concepts/patterns/behavioral-injection.md:41-177`)

### 4. Use Hierarchical Supervisors for 4+ Parallel Workers

**Rationale**: Sub-supervisors achieve 95% context reduction and 73% time savings when coordinating 4+ workers.

**When to Apply**:
- **Worker Count**: ≥4 parallel workers (context reduction justifies overhead)
- **Worker Output Size**: >2,000 tokens each (significant context savings)
- **Independence**: Workers can execute in parallel without dependencies

**Template**: Use sub-supervisor-template.md with variable substitution

**Performance**:
- Context: 10,000 tokens (4 workers × 2,500) → 500 tokens (aggregated metadata) = 95% reduction
- Time: 45s (sequential) → 12s (parallel) = 73% savings

**Reference**: Sub-Supervisor Template (`.claude/agents/templates/sub-supervisor-template.md:6-597`)

### 5. Standardize Progress Streaming and Error Handling

**Rationale**: Shared protocols saved 200 LOC while standardizing behavior across all agents.

**Progress Streaming**:
- **Format**: `PROGRESS: <brief-message>` (5-10 words, <60 chars)
- **Required Milestones**: Starting, Reading, Analyzing, Executing, Verifying, Completing
- **Frequency**: Before long operations (>2s), between major steps, not too frequently

**Error Handling**:
- **Classification**: Transient (retry with backoff), Permanent (fix then retry), Fatal (abort)
- **Retry Strategy**: Exponential backoff (500ms, 1s, 2s), max 3-4 attempts
- **Fallback**: Complex → simpler → alternative approach

**Reference**:
- Progress Protocol (`.claude/agents/shared/progress-streaming-protocol.md`)
- Error Guidelines (`.claude/agents/shared/error-handling-guidelines.md`)

### 6. Follow Agent Consolidation Pattern for Overlapping Functionality

**Rationale**: 95% overlap elimination saved 1,168 lines and improved maintainability.

**Decision Matrix**:
- **Consolidate When**: >80% overlap in behavioral logic, unified operation parameter possible
- **Refactor to Library When**: Deterministic algorithm (complexity scoring, git commits), no AI reasoning required
- **Keep Separate When**: <50% overlap, different tool access requirements, different model tiers

**Pattern**: Unified agent with operation parameter (expand/collapse) vs separate specialized agents

**Example**: expansion-specialist + collapse-specialist → plan-structure-manager with `operation: "expand"|"collapse"` parameter

**Reference**: Agent Consolidation History (`.claude/agents/README.md:9-48`)

## References

### Primary Agent Files
- `/home/benjamin/.config/.claude/agents/README.md` (lines 1-686) - Complete agent directory overview
- `/home/benjamin/.config/.claude/agents/plan-architect.md` (lines 1-150) - Opus-tier planning agent with 42 completion criteria
- `/home/benjamin/.config/.claude/agents/debug-specialist.md` (lines 1-150) - Opus-tier debugging agent with 38 completion criteria
- `/home/benjamin/.config/.claude/agents/plan-structure-manager.md` (lines 1-150) - Opus-tier structure management agent
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (lines 1-671) - Sonnet-tier research agent with 28 completion criteria
- `/home/benjamin/.config/.claude/agents/templates/sub-supervisor-template.md` (lines 1-597) - Hierarchical supervisor template

### Agent Infrastructure
- `/home/benjamin/.config/.claude/agents/agent-registry.json` (lines 1-385) - Agent metadata and metrics tracking
- `/home/benjamin/.config/.claude/agents/agent-registry-schema.json` (lines 1-99) - JSON schema for agent registry
- `/home/benjamin/.config/.claude/agents/shared/progress-streaming-protocol.md` (lines 1-253) - Standard progress reporting
- `/home/benjamin/.config/.claude/agents/shared/error-handling-guidelines.md` (lines 1-414) - Standard error handling patterns

### Documentation
- `/home/benjamin/.config/.claude/docs/guides/agent-development-guide.md` (lines 1-200) - Comprehensive agent development guide
- `/home/benjamin/.config/.claude/docs/guides/model-selection-guide.md` (lines 1-150) - Model tier selection framework
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` (lines 1-200) - Behavioral injection pattern documentation
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (lines 1-200) - Command and agent architecture standards

### Model Distribution Analysis
- Opus-tier agents: 3 of 31 (plan-architect, debug-specialist, plan-structure-manager)
- Sonnet-tier agents: 19 of 31 (research-specialist, code-writer, test-specialist, etc.)
- Haiku-tier agents: 9 of 31 (spec-updater, doc-converter, implementer-coordinator, etc.)
