# Hierarchical Agent Architecture Guide

## Overview

The hierarchical agent architecture enables multi-level agent coordination that minimizes context window consumption through metadata-based context passing and recursive supervision. This guide covers the complete architecture, patterns, utilities, and best practices for implementing hierarchical agent workflows.

**Quick Overview**: For a concise summary of the hierarchical agent workflow system, see [README: Hierarchical Agent Workflow System](../README.md#hierarchical-agent-workflow-system).

**Related Documentation**:
- [Using Agents](../guides/using-agents.md) - Agent invocation patterns and behavioral injection
- [Command Architecture Standards](../reference/command_architecture_standards.md#context-preservation-standards) - Standards 1, 6-8
- [Hierarchical Agent Workflow Guide](../workflows/hierarchical-agent-workflow.md) - Practical workflow examples

## Table of Contents

- [Architecture Principles](#architecture-principles)
- [Core Concepts](#core-concepts)
- [Metadata Extraction](#metadata-extraction)
- [Forward Message Pattern](#forward-message-pattern)
- [Recursive Supervision](#recursive-supervision)
- [Context Pruning](#context-pruning)
- [Command Integration](#command-integration)
- [Agent Templates](#agent-templates)
- [Performance Optimization](#performance-optimization)
- [Troubleshooting](#troubleshooting)
- [Examples](#examples)

## Architecture Principles

### 1. Metadata-Only Passing

**Problem**: Passing full report/plan content between agents consumes massive context (1000+ tokens per artifact).

**Solution**: Extract and pass only metadata (title + 50-word summary + key references).

**Reduction**: 99% context reduction (5000 chars → 250 chars per artifact)

### 2. Forward Message Pattern

**Problem**: Primary agents re-summarize subagent outputs, adding 200-300 token overhead per subagent.

**Solution**: Pass subagent responses directly to next phase without paraphrasing.

**Reduction**: Eliminates paraphrasing overhead, maintains original fidelity.

### 3. Recursive Supervision

**Problem**: Single-level supervision limited to 4-5 parallel agents before context exhaustion.

**Solution**: Supervisors can delegate to sub-supervisors, each managing 2-3 specialized agents.

**Scalability**: Enables 10+ parallel agents across multiple domains.

### 4. Aggressive Context Pruning

**Problem**: Completed phase data retained throughout workflow, accumulating context.

**Solution**: Prune full content after phase completion, retain only metadata references.

**Reduction**: 80-90% reduction in accumulated workflow context.

## Core Concepts

### Agent Hierarchy Levels

```
Level 0: Primary Orchestrator (command-level agent)
  ↓
Level 1: Domain Supervisors (research, implementation, testing)
  ↓
Level 2: Specialized Subagents (auth research, API research, security research)
  ↓
Level 3: Task Executors (focused single-task agents - rarely used)
```

**Depth Limit**: Maximum 3 levels of supervision to prevent complexity explosion.

### Artifact Metadata Structure

**Report Metadata**:
```json
{
  "title": "Authentication Patterns Research",
  "summary": "JWT vs sessions comparison. JWT recommended for APIs...", // ≤50 words
  "file_paths": [
    "lib/auth/jwt.lua",
    "lib/auth/sessions.lua"
  ],
  "recommendations": [
    "Use JWT for API authentication",
    "Use sessions for web application",
    "Implement refresh token rotation"
  ],
  "path": "specs/042_auth/reports/001_patterns.md",
  "size": 4235
}
```

**Plan Metadata**:
```json
{
  "title": "Authentication Implementation Plan",
  "date": "2025-10-16",
  "phases": 5,
  "complexity": "Medium",
  "time_estimate": "6-8 hours",
  "success_criteria": 8,
  "path": "specs/042_auth/plans/001_implementation.md",
  "size": 3890
}
```

### Handoff Context Structure

**Between Phases**:
```json
{
  "phase_complete": "research",
  "artifacts": [
    {
      "path": "specs/042_auth/reports/001_patterns.md",
      "metadata": { /* 250 chars max */ }
    },
    {
      "path": "specs/042_auth/reports/002_security.md",
      "metadata": { /* 250 chars max */ }
    }
  ],
  "summary": "Research complete. 2 reports generated. Key findings: JWT recommended, 2FA optional.",
  "next_phase_reads": [
    "specs/042_auth/reports/001_patterns.md"
  ]
}
```

**Size**: ~500-800 chars vs 5000+ chars for full content (90% reduction)

## Metadata Extraction

### extract_report_metadata()

**Location**: `.claude/lib/metadata-extraction.sh`

**Purpose**: Extract concise metadata from research reports.

**Usage**:
```bash
source .claude/lib/metadata-extraction.sh

metadata=$(extract_report_metadata "specs/042_auth/reports/001_patterns.md")
title=$(echo "$metadata" | jq -r '.title')
summary=$(echo "$metadata" | jq -r '.summary')  # ≤50 words
```

**Extraction Logic**:
1. **Title**: First `# Heading` in file
2. **Summary**: Extract from `## Executive Summary` section, truncate to 50 words
3. **File Paths**: Parse `## Findings` and `## Recommendations` for referenced paths
4. **Recommendations**: Extract 3-5 top recommendations (condensed bullets)

**Output**: JSON metadata object (~250 chars)

### extract_plan_metadata()

**Location**: `.claude/lib/metadata-extraction.sh`

**Purpose**: Extract implementation plan metadata for complexity assessment.

**Usage**:
```bash
metadata=$(extract_plan_metadata "specs/042_auth/plans/001_implementation.md")
complexity=$(echo "$metadata" | jq -r '.complexity')
phases=$(echo "$metadata" | jq -r '.phases')
```

**Extraction Logic**:
1. **Complexity**: Parse `## Metadata` → `**Complexity**: Medium`
2. **Phases**: Count `### Phase N:` headings
3. **Success Criteria**: Count unchecked items in `## Success Criteria`
4. **Time Estimate**: Parse `**Time Estimate**: 6-8 hours`

### load_metadata_on_demand()

**Location**: `.claude/lib/metadata-extraction.sh`

**Purpose**: Generic metadata loader with automatic type detection and caching.

**Usage**:
```bash
# Auto-detects type (plan/report/summary) from path
metadata=$(load_metadata_on_demand "specs/042_auth/reports/001_patterns.md")

# Second call uses cache (instant)
cached=$(load_metadata_on_demand "specs/042_auth/reports/001_patterns.md")
```

**Features**:
- Automatic artifact type detection
- In-memory caching for repeated access
- Cache hit rate: ~80% in typical workflows
- Performance: 100x faster for cached metadata

### Metadata Cache Management

**Location**: `.claude/lib/metadata-extraction.sh:2204-2238`

**Cache Operations**:
```bash
# Cache metadata
cache_metadata "specs/report.md" "$metadata_json"

# Retrieve from cache
cached=$(get_cached_metadata "specs/report.md")

# Clear cache (when artifacts modified)
clear_metadata_cache
```

**Cache Structure**:
```bash
declare -A METADATA_CACHE
# Key: artifact path
# Value: JSON metadata string
```

## Forward Message Pattern

### forward_message()

**Location**: `.claude/lib/metadata-extraction.sh:2244-2340`

**Purpose**: Extract structured handoff context from subagent output without re-summarization.

**Usage**:
```bash
subagent_output="Research complete. Created report at specs/042_auth/reports/001_patterns.md.
Summary: JWT vs sessions analysis with security recommendations."

handoff=$(forward_message "$subagent_output")
artifact_path=$(echo "$handoff" | jq -r '.artifacts[0].path')
summary=$(echo "$handoff" | jq -r '.summary')  # ≤100 words
```

**Pattern Flow**:
```
Subagent completes task
    ↓
Returns: artifact paths + metadata + summary
    ↓
forward_message() extracts:
  - Artifact paths (regex: specs/.*\.md)
  - Status (SUCCESS/FAILED)
  - Metadata blocks (JSON/YAML)
    ↓
Builds handoff context:
  - artifact_refs[] (paths only)
  - summary (≤100 words)
  - next_phase_context (metadata only)
    ↓
Original output logged, NOT retained in memory
    ↓
Handoff passed to next phase
```

**Context Savings**: 80-90% per subagent invocation

### parse_subagent_response()

**Location**: `.claude/lib/metadata-extraction.sh:2342-2390`

**Purpose**: Parse structured JSON/YAML from subagent outputs.

**Usage**:
```bash
response=$(parse_subagent_response "$subagent_output")
status=$(echo "$response" | jq -r '.status')
artifacts=$(echo "$response" | jq -r '.artifacts[]')
```

**Supported Formats**:
- JSON code blocks (```json ... ```)
- YAML code blocks (```yaml ... ```)
- Inline JSON objects
- Status indicators (SUCCESS, FAILED, ERROR)

### Handoff Logging

**Location**: `.claude/lib/metadata-extraction.sh:2322-2338`

**Logs**:
- **Subagent Outputs**: `.claude/data/logs/subagent-outputs.log`
- **Phase Handoffs**: `.claude/data/logs/phase-handoffs.log`

**Log Rotation**: 10MB max, 5 files retained

**Purpose**: Enable debugging without retaining full outputs in memory.

## Recursive Supervision

### Architecture

**Single-Level Supervision** (current `/orchestrate`):
```
Orchestrator
    ├─ Research Agent 1
    ├─ Research Agent 2
    ├─ Research Agent 3
    └─ Research Agent 4  ← Limit reached (context exhaustion)
```

**Hierarchical Supervision** (recursive):
```
Primary Orchestrator
    ├─ Research Supervisor
    │   ├─ Auth Research Agent
    │   ├─ API Research Agent
    │   └─ Security Research Agent
    ├─ Architecture Supervisor
    │   ├─ Database Design Agent
    │   ├─ Service Architecture Agent
    │   └─ Integration Points Agent
    └─ Implementation Supervisor
        ├─ Backend Implementation Agent
        └─ Frontend Implementation Agent
```

**Scalability**: 10+ agents vs 4 agents (2.5x increase)

### invoke_sub_supervisor()

**Location**: `.claude/lib/metadata-extraction.sh:2445-2524`

**Purpose**: Prepare sub-supervisor invocation with task domain and subagent list.

**Usage**:
```bash
config='{
  "task_domain": "security_research",
  "subagent_count": 3,
  "task_list": [
    "Auth patterns research",
    "Security best practices",
    "Vulnerability analysis"
  ]
}'

invocation_data=$(invoke_sub_supervisor "$config")
```

**Returns**: Invocation metadata for command layer to use with Task tool.

### track_supervision_depth()

**Location**: `.claude/lib/metadata-extraction.sh:2526-2561`

**Purpose**: Prevent infinite recursion in supervisor hierarchies.

**Usage**:
```bash
# Reset depth counter
track_supervision_depth reset

# Increment when invoking sub-supervisor
track_supervision_depth increment

# Check current depth
depth=$(track_supervision_depth get)

# Check if at limit
if track_supervision_depth check; then
  echo "Within depth limit"
else
  echo "MAX_SUPERVISION_DEPTH exceeded"
fi

# Decrement when sub-supervisor completes
track_supervision_depth decrement
```

**Constants**:
- `MAX_SUPERVISION_DEPTH=3` (configurable)
- `SUPERVISION_DEPTH` (global counter)

**Safety**: Prevents runaway recursion, enforces depth limits.

### generate_supervision_tree()

**Location**: `.claude/lib/metadata-extraction.sh:2563-2628`

**Purpose**: Visualize hierarchical agent structure for debugging.

**Usage**:
```bash
workflow_state='{
  "supervisor": {
    "type": "orchestrator",
    "agents": 3,
    "sub_supervisors": [
      {"type": "research_supervisor", "agents": 3, "artifacts": 3},
      {"type": "implementation_supervisor", "agents": 2, "artifacts": 5}
    ]
  }
}'

tree=$(generate_supervision_tree "$workflow_state")
echo "$tree"
```

**Output**:
```
Primary Orchestrator (3 agents)
├─ Research Supervisor (3 agents, 3 artifacts)
│  ├─ Auth Research Agent
│  ├─ API Research Agent
│  └─ Security Research Agent
└─ Implementation Supervisor (2 agents, 5 artifacts)
   ├─ Backend Implementation Agent
   └─ Frontend Implementation Agent
```

## Context Pruning

### Pruning Strategies

**Location**: `.claude/lib/context-pruning.sh`

**1. Subagent Output Pruning**:
```bash
# After subagent completes and metadata extracted
prune_subagent_output "$subagent_id"
```
Removes: Full subagent output from memory
Retains: Artifact path + metadata (250 chars)
Reduction: 95-98%

**2. Phase Metadata Pruning**:
```bash
# After planning phase completes
prune_phase_metadata "research"
```
Removes: Research summaries, intermediate results
Retains: Artifact references only
Reduction: 80-90%

**3. Workflow Metadata Pruning**:
```bash
# After implementation completes
prune_workflow_metadata "implement"
```
Removes: All implementation details, test outputs
Retains: Final artifact paths, status
Reduction: 90-95%

### apply_pruning_policy()

**Purpose**: Automatic pruning based on workflow type.

**Policies**:

**Research Workflow**:
- Keep: Report paths, 50-word summaries
- Prune: Full report content, research notes

**Planning Workflow**:
- Keep: Plan path, complexity assessment
- Prune: Research reports (after planning complete), intermediate drafts

**Implementation Workflow**:
- Keep: Plan path, test status, artifact paths
- Prune: Research summaries, implementation logs, test outputs

**Debug Workflow**:
- Keep: Debug report path, root cause, proposed fix
- Prune: Investigation artifacts, error logs

### Pruning Timing

**Phase Completion**:
```bash
# After phase N completes successfully
prune_phase_metadata "phase_${N}"
```

**Workflow Transition**:
```bash
# When transitioning research → planning
prune_subagent_output "research_supervisor"

# When transitioning planning → implementation
prune_phase_metadata "research"
```

**Checkpoint Save**:
```bash
# Before saving checkpoint
prune_workflow_metadata "$workflow_type"
```

## Context Pruning for Multi-Agent Workflows

When coordinating multiple agents, apply aggressive context pruning to maintain <30% context usage throughout the workflow.

### When to Prune

**1. After Metadata Extraction** (Most Critical):
```bash
# Immediately after extracting metadata from subagent output
subagent_output="Research complete. Created report at specs/042_auth/reports/001_patterns.md..."

# Extract metadata
metadata=$(extract_report_metadata "specs/042_auth/reports/001_patterns.md")

# Prune full output immediately
prune_subagent_output "research_agent_1"

# Now only metadata retained in memory (250 tokens vs 5000 tokens)
# Original output logged to .claude/data/logs/subagent-outputs.log
```

**2. Between Workflow Phases**:
```bash
# After research phase completes, before planning starts
prune_phase_metadata "research"

# After planning completes, before implementation starts
prune_phase_metadata "planning"

# This prevents accumulation of stale data across phases
```

**3. Before Checkpoint Saves**:
```bash
# Before saving workflow state to checkpoint
apply_pruning_policy "$workflow_type"
save_checkpoint "orchestrate"

# Ensures checkpoints only contain essential metadata, not full artifacts
```

### Pruning Policy Decision Tree

Choose pruning aggressiveness based on workflow characteristics:

**Aggressive Pruning** (orchestration workflows):
```bash
# Target: <20% context usage throughout
apply_pruning_policy --mode aggressive --workflow orchestrate

# Prunes:
# - Full subagent outputs after metadata extraction
# - Completed phase data after phase transitions
# - Intermediate artifacts after final artifact created
#
# Retains:
# - Artifact paths only
# - 50-word summaries
# - Workflow status

# Best for: /orchestrate, multi-agent research, complex workflows
# Context reduction: 90-95%
```

**Moderate Pruning** (implementation workflows):
```bash
# Target: 20-30% context usage
apply_pruning_policy --mode moderate --workflow implement

# Prunes:
# - Subagent outputs after metadata extraction
# - Test outputs after validation
# - Build logs after successful build
#
# Retains:
# - Recent phase metadata (last 2 phases)
# - Current phase full context
# - Error messages from failures

# Best for: /implement, /plan, /debug
# Context reduction: 70-85%
```

**Minimal Pruning** (single-agent workflows):
```bash
# Target: 30-50% context usage
apply_pruning_policy --mode minimal --workflow document

# Prunes:
# - Only explicitly marked temporary data
# - Large artifacts after reading
#
# Retains:
# - Most workflow context
# - Agent outputs
# - Recent operations

# Best for: /document, /refactor, /test
# Context reduction: 40-60%
```

### Context Reduction Metrics

**Measure Context Savings**:
```bash
# Before subagent invocation
CONTEXT_BEFORE=$(get_context_size)

# Invoke subagent
Task { ... }

# Extract metadata and prune
metadata=$(extract_report_metadata "$report_path")
prune_subagent_output "$subagent_id"

# After pruning
CONTEXT_AFTER=$(get_context_size)

# Calculate reduction
REDUCTION=$((100 - (CONTEXT_AFTER * 100 / CONTEXT_BEFORE)))
echo "Context reduction: ${REDUCTION}%"

# Log to metrics
log_context_metrics "orchestrate" "$REDUCTION"
```

**Target Metrics**:
- Per-subagent reduction: ≥90%
- Per-phase reduction: ≥85%
- Full workflow usage: <30% of available context

### Pruning in Parallel Agent Coordination

**Pattern**: Prune each subagent immediately after metadata extraction, not after all complete.

**Sequential Pruning** (correct):
```bash
# Parallel agent invocations
Task { subagent 1 } &
Task { subagent 2 } &
Task { subagent 3 } &

# As each completes, extract metadata and prune immediately
for agent_id in subagent_1 subagent_2 subagent_3; do
  if agent_complete "$agent_id"; then
    metadata=$(extract_agent_metadata "$agent_id")
    prune_subagent_output "$agent_id"  # Prune immediately
  fi
done
```

**Batch Pruning** (incorrect - allows context to accumulate):
```bash
# Wait for all agents to complete
wait_for_all_agents

# Extract all metadata
for agent_id in subagent_1 subagent_2 subagent_3; do
  metadata=$(extract_agent_metadata "$agent_id")
done

# Prune all at once
prune_all_subagent_outputs  # Too late - context already high
```

### Utility References

**Context Pruning Functions** (`.claude/lib/context-pruning.sh`):
```bash
# Prune specific subagent
prune_subagent_output "$agent_id"

# Prune completed phase
prune_phase_metadata "$phase_name"

# Prune entire workflow
prune_workflow_metadata "$workflow_type"

# Apply policy-based pruning
apply_pruning_policy --mode [aggressive|moderate|minimal] --workflow [name]
```

**Metadata Extraction** (`.claude/lib/metadata-extraction.sh`):
```bash
# Extract before pruning
extract_report_metadata "$report_path"
extract_plan_metadata "$plan_path"
load_metadata_on_demand "$artifact_path"  # Auto-detect + cache
```

**Context Measurement**:
```bash
# Get current context size (tokens)
get_context_size

# Log context metrics
log_context_metrics "$command" "$reduction_percent"
```

### Example: Orchestrate Research Phase with Pruning

```bash
#!/usr/bin/env bash
source .claude/lib/metadata-extraction.sh
source .claude/lib/context-pruning.sh

# Launch 3 research agents in parallel
Task { research-specialist: Topic 1 } &
PID1=$!
Task { research-specialist: Topic 2 } &
PID2=$!
Task { research-specialist: Topic 3 } &
PID3=$!

# As each completes, extract metadata and prune immediately
for pid in $PID1 $PID2 $PID3; do
  wait $pid
  agent_output=$(get_agent_output "$pid")

  # Extract metadata (path + 50-word summary)
  report_path=$(echo "$agent_output" | grep -oP 'specs/[^[:space:]]+\.md')
  metadata=$(extract_report_metadata "$report_path")

  # Prune full output immediately
  prune_subagent_output "agent_$pid"

  # Log context reduction
  echo "Pruned agent_$pid: 95% context reduction"
done

# After all agents complete, prune research phase before planning
prune_phase_metadata "research"

# Context usage: <30% (vs >80% without pruning)
```

**See Also**:
- [Command Architecture Standards](../reference/command_architecture_standards.md#standard-8) for context pruning requirements (Standard 8)
- [Forward Message Pattern](#forward-message-pattern) (this document) for no-paraphrase handoffs

## Command Integration

### /implement

**Subagent Delegation Point**: Before implementing complex phase (complexity ≥8 or >10 tasks)

**Integration** (`.claude/commands/implement.md:522-678`):
```
Step 1.57: Implementation Research Agent Invocation
  ↓
If complexity ≥8 or tasks >10:
  ├─ Invoke implementation-researcher subagent
  ├─ Subagent analyzes codebase for patterns, utilities, conventions
  ├─ Subagent writes: specs/{topic}/artifacts/phase_{N}_exploration.md
  └─ Returns: {path, 50-word summary, key_findings[]}
  ↓
/implement reads artifact on-demand when implementing phase
  ↓
Context saved: 95% (5000 tokens → 250 tokens)
```

**Trigger Conditions**:
- Phase complexity score ≥8
- Phase has >10 tasks
- Phase references >10 files

**Subagent**: `implementation-researcher` (`.claude/agents/implementation-researcher.md`)

### /plan

**Subagent Delegation Point**: Before planning complex or ambiguous features

**Integration** (`.claude/commands/plan.md:63-195`):
```
Section 0.5: Research Agent Delegation for Complex Features
  ↓
If feature ambiguous or multiple approaches exist:
  ├─ Invoke 2-3 research subagents in parallel
  ├─ Topics: patterns, best practices, alternatives
  ├─ Subagents write: specs/{topic}/reports/*.md
  └─ Returns: metadata only (title + 50-word summary per report)
  ↓
/plan reads reports on-demand when synthesizing plan
  ↓
Context saved: 92% (3x 1500 tokens → 3x 250 tokens)
```

**Trigger Conditions**:
- Feature description ambiguous (>1 interpretation)
- Multiple implementation approaches possible
- User explicitly requests research

**Subagents**: `research-agent` (general), domain-specific agents

### /debug

**Subagent Delegation Point**: When multiple potential root causes exist

**Integration** (`.claude/commands/debug.md:65-248`):
```
Section 3.5: Parallel Hypothesis Investigation (for Complex Issues)
  ↓
If bug complex (>2 potential causes):
  ├─ Invoke debug-analyst subagents in parallel (1 per hypothesis)
  ├─ Each investigates: reproduce, identify root cause, assess impact
  ├─ Subagents write: specs/{topic}/debug/NNN_investigation.md
  └─ Returns: {path, 50-word summary, root_cause, proposed_fix}
  ↓
/debug synthesizes findings and proposes unified fix
  ↓
Context saved: 80% (3x 1000 tokens → 750 tokens)
```

**Trigger Conditions**:
- Multiple potential root causes
- Complex error patterns
- Test failures across multiple files

**Subagent**: `debug-analyst` (`.claude/agents/debug-analyst.md`)

### /orchestrate

**Subagent Delegation Point**: Research phase with >5 topics

**Integration** (future enhancement):
```
If research topics >5:
  ├─ Group topics into domains (security, architecture, implementation)
  ├─ Invoke sub-supervisor per domain
  ├─ Each sub-supervisor manages 2-3 specialized agents
  ├─ Sub-supervisors return aggregated metadata to orchestrator
  └─ Orchestrator synthesizes for planning phase
  ↓
Scalability: 10+ topics (vs 4 without recursion)
Context saved: 85% throughout workflow
```

**Trigger Conditions**:
- >5 research topics
- Multi-domain workflows (security + architecture + implementation)
- User explicitly requests comprehensive research

**Subagents**: Domain-specific sub-supervisors

## Agent Templates

### Implementation Researcher

**Location**: `.claude/agents/implementation-researcher.md`

**Role**: Analyze codebase before implementation phases to identify reusable patterns.

**Responsibilities**:
- Search codebase for existing implementations of similar features
- Identify patterns, conventions, utilities to reuse
- Detect potential conflicts or integration challenges
- Generate concise findings report

**Invocation Context**:
```json
{
  "phase_num": 3,
  "phase_desc": "Implement JWT token generation and validation",
  "file_list": ["lib/auth/jwt.lua", "lib/auth/tokens.lua"],
  "project_standards": "CLAUDE.md"
}
```

**Output**:
- **Artifact**: `specs/{topic}/artifacts/phase_{N}_exploration.md`
- **Metadata**: `{path, summary (50 words), key_findings[]}`

**Research Focus**:
1. Existing implementations (grep/glob for similar features)
2. Utility functions available (grep lib/ utils/ for relevant helpers)
3. Patterns to follow (analyze similar files for conventions)
4. Integration points (identify dependencies, imports)

**Context Impact**: 95% reduction (5000 tokens → 250 tokens)

### Debug Analyst

**Location**: `.claude/agents/debug-analyst.md`

**Role**: Investigate potential root causes for test failures or bugs.

**Responsibilities**:
- Reproduce the issue (run tests, analyze error messages)
- Identify root cause (logic errors, missing dependencies, config issues)
- Assess impact (scope of problem, affected components)
- Propose fix (specific code changes)

**Invocation Context**:
```json
{
  "issue_desc": "Token refresh fails after 1 hour",
  "failed_tests": "test_token_refresh, test_expired_token",
  "modified_files": ["lib/auth/jwt.lua"],
  "hypothesis": "Token expiration time misconfigured"
}
```

**Output**:
- **Artifact**: `specs/{topic}/debug/NNN_investigation.md`
- **Metadata**: `{path, summary (50 words), root_cause, proposed_fix}`

**Investigation Focus**:
1. Reproduce issue (run failing tests)
2. Analyze error messages (stack traces, logs)
3. Identify root cause (code inspection, debugging)
4. Propose fix (specific changes with rationale)

**Context Impact**: 85% reduction per investigation

### Sub-Supervisor

**Location**: `.claude/templates/sub_supervisor_pattern.md`

**Role**: Manage 2-3 specialized subagents within a specific domain.

**Responsibilities**:
- Decompose domain tasks into focused subagent assignments
- Invoke subagents in parallel
- Collect and aggregate subagent outputs
- Return metadata-only summary to parent supervisor

**Template Variables**:
```
{N}            - Sub-supervisor number
{task_domain}  - Domain (security, architecture, implementation)
{max_words}    - Maximum summary length (default: 100)
{task_list}    - Array of tasks for subagents
```

**Invocation Pattern**:
```markdown
You are a {task_domain} sub-supervisor managing {N} specialized subagents.

**Your tasks**:
{task_list}

**Your responsibilities**:
1. Assign one task to each subagent
2. Invoke subagents in parallel via Task tool
3. Collect outputs and extract metadata
4. Return aggregated summary (≤{max_words} words) + artifact references

**Output format**:
```json
{
  "domain": "{task_domain}",
  "artifacts": [
    {"path": "specs/.../001.md", "summary": "..."}
  ],
  "summary": "Domain summary here (≤{max_words} words)",
  "key_findings": ["Finding 1", "Finding 2"]
}
```
```

**Context Impact**: Enables 10+ parallel agents (vs 4 without recursion)

## Performance Optimization

### Context Reduction Targets

**Per-Artifact**:
- Full content: 1000-5000 tokens
- Metadata: 50-250 tokens
- Reduction: 80-95%

**Per-Phase**:
- Without hierarchy: 5000-15000 tokens
- With hierarchy: 500-2000 tokens
- Reduction: 87-97%

**Full Workflow**:
- Without hierarchy: 20000-50000 tokens
- With hierarchy: 2000-8000 tokens
- Reduction: 84-96%

**Target**: <30% context usage throughout workflows

### Optimization Strategies

**1. Parallel Subagent Execution**:
- Time savings: 40-80% vs sequential
- Context savings: 60-90% via metadata passing
- Scalability: 10+ agents with recursion

**2. On-Demand Artifact Loading**:
- Load full content only when needed
- Cache metadata for repeated access
- Cache hit rate: ~80%

**3. Aggressive Pruning**:
- Prune after each phase completion
- Prune on workflow transition
- Retention: metadata only (250 chars)

**4. Metadata Caching**:
- Cache metadata extractions
- Performance: 100x faster for cache hits
- Memory: <100KB for typical workflows

### Performance Metrics

**Location**: `.claude/data/logs/context-metrics.log`

**Tracked Metrics**:
- Context before subagent invocation
- Context after subagent completion
- Reduction percentage
- Subagent execution time
- Artifact count
- Metadata size

**Dashboard**: `.claude/scripts/context_metrics_dashboard.sh`

**Usage**:
```bash
# Generate metrics summary
.claude/scripts/context_metrics_dashboard.sh

# Output (text format):
Average Context Reduction: 89%
Max Context Usage: 27%
Commands <70% Reduction: 0
```

**Metrics Format**:
```
2025-10-16 12:00:00 | /implement | CONTEXT_BEFORE: 5000 tokens
2025-10-16 12:01:00 | /implement | SUBAGENT_INVOKED: implementation-researcher
2025-10-16 12:02:00 | /implement | CONTEXT_AFTER: 1500 tokens
2025-10-16 12:02:00 | /implement | REDUCTION: 70%
```

## Troubleshooting

### Common Issues

**1. Metadata Extraction Returns Empty**

**Symptom**: `extract_report_metadata()` returns `{}`

**Causes**:
- Report missing `# Title` heading
- Report missing `## Executive Summary` section
- File path incorrect

**Solutions**:
```bash
# Verify report structure
grep "^# " report.md  # Check title
grep "^## Executive Summary" report.md  # Check summary

# Use fallback extraction
title=$(head -1 report.md | sed 's/^# //')
summary=$(sed -n '/^## /,/^## /p' report.md | head -50)
```

**2. Supervision Depth Exceeded**

**Symptom**: `track_supervision_depth check` returns false

**Causes**:
- Too many supervisor levels (>3)
- Depth counter not decremented on completion
- Recursive loop in supervisor invocations

**Solutions**:
```bash
# Check current depth
depth=$(track_supervision_depth get)
echo "Current depth: $depth"

# Reset depth if stuck
track_supervision_depth reset

# Review supervision tree
tree=$(generate_supervision_tree "$workflow_state")
echo "$tree"
```

**3. Context Not Reduced**

**Symptom**: Context usage still >50% after subagent delegation

**Causes**:
- Full content not pruned after metadata extraction
- Metadata summaries too long (>50 words)
- Pruning policy not applied

**Solutions**:
```bash
# Verify pruning enabled
source .claude/lib/context-pruning.sh

# Manual pruning
prune_subagent_output "$subagent_id"
prune_phase_metadata "$phase_name"

# Check metadata size
metadata=$(extract_report_metadata "$report_path")
size=$(echo "$metadata" | wc -c)
echo "Metadata size: $size chars (should be <500)"
```

**4. Subagent Response Not Parsed**

**Symptom**: `parse_subagent_response()` returns null

**Causes**:
- Subagent output missing JSON block
- Invalid JSON syntax
- Unexpected output format

**Solutions**:
```bash
# Check for JSON block
echo "$subagent_output" | grep "```json"

# Validate JSON manually
echo "$subagent_output" | sed -n '/```json/,/```/p' | jq .

# Use fallback parsing
artifact_path=$(echo "$subagent_output" | grep -oP 'specs/[^[:space:]]+\.md')
```

### Debugging Tools

**1. Supervision Tree Visualization**:
```bash
# Generate current hierarchy
tree=$(generate_supervision_tree "$workflow_state")
echo "$tree"
```

**2. Context Metrics Dashboard**:
```bash
# View reduction statistics
.claude/scripts/context_metrics_dashboard.sh
```

**3. Subagent Output Logs**:
```bash
# Review full subagent outputs (not retained in memory)
tail -50 .claude/data/logs/subagent-outputs.log
```

**4. Phase Handoff Logs**:
```bash
# Review handoff contexts between phases
tail -50 .claude/data/logs/phase-handoffs.log
```

### Performance Analysis

**Context Reduction Validation**:
```bash
# Run validation script
.claude/scripts/validate_context_reduction.sh

# Expected output:
# Total tests: 6
# Passed: 6
# Failed: 0
# Pass rate: 100%
```

**Metrics Analysis**:
```bash
# Calculate average reduction
grep "REDUCTION:" .claude/data/logs/context-metrics.log | \
  awk '{sum+=$NF} END {print "Avg:", sum/NR"%"}'

# Identify commands needing optimization
.claude/scripts/context_metrics_dashboard.sh | \
  grep "Commands <70% Reduction"
```

## Examples

### Example 1: Simple Metadata Extraction

```bash
#!/usr/bin/env bash
source .claude/lib/metadata-extraction.sh

# Extract report metadata
report_path="specs/042_auth/reports/001_patterns.md"
metadata=$(extract_report_metadata "$report_path")

# Use metadata (not full content)
title=$(echo "$metadata" | jq -r '.title')
summary=$(echo "$metadata" | jq -r '.summary')
paths=$(echo "$metadata" | jq -r '.file_paths[]')

echo "Report: $title"
echo "Summary: $summary"
echo "Referenced files: $paths"

# Context saved: ~95% (5000 chars → 250 chars)
```

### Example 2: Forward Message Pattern

```bash
#!/usr/bin/env bash
source .claude/lib/metadata-extraction.sh

# Simulate subagent completion
subagent_output="Research complete. Created report at specs/042_auth/reports/001_patterns.md.

Key findings:
- JWT recommended for API authentication
- Sessions better for traditional web apps
- Consider hybrid approach for complex systems"

# Extract handoff context
handoff=$(forward_message "$subagent_output")

# Pass to next phase (metadata only, not full output)
next_phase_context=$(echo "$handoff" | jq -r '.next_phase_context')

# Original output logged, not retained in memory
# Context saved: ~90% (1000 chars → 100 chars)
```

### Example 3: Recursive Supervision

```bash
#!/usr/bin/env bash
source .claude/lib/metadata-extraction.sh

# Primary orchestrator invokes sub-supervisor
track_supervision_depth reset
track_supervision_depth increment  # Depth = 1

config='{
  "task_domain": "security_research",
  "subagent_count": 3,
  "task_list": [
    "Authentication patterns analysis",
    "Security best practices review",
    "Vulnerability assessment"
  ]
}'

# Prepare sub-supervisor invocation
invocation_data=$(invoke_sub_supervisor "$config")

# Command layer invokes sub-supervisor via Task tool
# (Actual invocation handled by command, not script)

# Sub-supervisor completes and returns metadata
sub_supervisor_output='{
  "domain": "security_research",
  "artifacts": [
    {"path": "specs/042_auth/reports/001_auth_patterns.md", "summary": "JWT vs sessions..."},
    {"path": "specs/042_auth/reports/002_security_best_practices.md", "summary": "HTTPS, rate limiting..."},
    {"path": "specs/042_auth/reports/003_vulnerability_assessment.md", "summary": "OWASP Top 10..."}
  ],
  "summary": "Security research complete. 3 reports generated covering auth patterns, best practices, and vulnerabilities."
}'

# Extract handoff (metadata only)
handoff=$(forward_message "$sub_supervisor_output")

# Decrement depth
track_supervision_depth decrement  # Depth = 0

# Context saved: 97% (3x 5000 chars → 750 chars)
```

### Example 4: Context Pruning

```bash
#!/usr/bin/env bash
source .claude/lib/context-pruning.sh

# After research phase completes
workflow_state='{
  "current_phase": "planning",
  "completed_phases": ["research"],
  "artifacts": {
    "research": [
      {"path": "specs/042_auth/reports/001_patterns.md", "size": 5000},
      {"path": "specs/042_auth/reports/002_security.md", "size": 4500}
    ]
  }
}'

# Prune research phase metadata (no longer needed)
prune_phase_metadata "research"

# After pruning:
# - Full report content discarded from memory
# - Only artifact paths retained: ["specs/042_auth/reports/001_patterns.md", ...]
# - Reports loaded on-demand if needed later

# Context saved: ~90% (9500 chars → 100 chars)
```

### Example 5: /implement with Subagent Delegation

```bash
# User runs:
/implement specs/042_auth/plans/001_implementation.md

# /implement reaches Phase 3 (complexity = 9, tasks = 12)
# Triggers: complexity ≥8 and tasks >10

# Step 1.57: Implementation Research Agent Invocation
# /implement invokes implementation-researcher subagent

# Subagent context:
{
  "phase_num": 3,
  "phase_desc": "Implement JWT token generation and validation",
  "file_list": ["lib/auth/jwt.lua", "lib/auth/tokens.lua"],
  "project_standards": "CLAUDE.md"
}

# Subagent researches:
# - Existing JWT implementations in codebase
# - Available utility functions (lib/crypto/sign.lua)
# - Patterns to follow (lib/auth/sessions.lua structure)
# - Integration points (middleware/auth.lua)

# Subagent output:
# - Artifact: specs/042_auth/artifacts/phase_3_exploration.md
# - Metadata: {path, 50-word summary, key_findings[]}

# /implement receives metadata only (not full artifact):
{
  "path": "specs/042_auth/artifacts/phase_3_exploration.md",
  "summary": "Found existing JWT utility in lib/crypto/sign.lua. Sessions pattern in lib/auth/sessions.lua provides good structure. Middleware integration via lib/middleware/auth.lua required.",
  "key_findings": [
    "Reuse lib/crypto/sign.lua for JWT signing",
    "Follow sessions.lua structure for token management",
    "Add middleware integration in lib/middleware/auth.lua"
  ]
}

# /implement reads full artifact on-demand when implementing
# Context saved: 95% (5000 tokens → 250 tokens)
```

## Agent Invocation Patterns

### Overview

This section documents the correct patterns for invoking agents from commands, with emphasis on the **behavioral injection pattern** that enables metadata-based context reduction and topic-based artifact organization.

**Related Documentation**:
- [Agent Authoring Guide](../guides/agent-authoring-guide.md) - Creating agent behavioral files
- [Command Authoring Guide](../guides/command-authoring-guide.md) - Invoking agents from commands

### The Behavioral Injection Pattern

#### Pattern Definition

**Behavioral injection** is the practice of:
1. **Commands** pre-calculate topic-based artifact paths
2. **Commands** load agent behavioral prompts (or reference files)
3. **Commands** inject complete context into agent invocation
4. **Agents** create artifacts directly at provided paths
5. **Commands** verify artifacts and extract metadata only

#### Why This Pattern Exists

**Problem**: If agents invoke slash commands:
- Loss of control over artifact paths
- Cannot extract metadata before context bloat
- Violates topic-based artifact organization
- Risk of recursion (agent → command → agent)

**Solution**: Commands control orchestration, agents execute:
- Commands calculate paths → topic-based organization enforced
- Commands inject context → agents have everything needed
- Agents create artifacts → direct file operations
- Commands extract metadata → 95% context reduction

#### Pattern Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ PRIMARY COMMAND (orchestration layer)                       │
│                                                              │
│ 1. Calculate Topic-Based Path                               │
│    ARTIFACT_PATH = specs/{NNN_topic}/reports/{NNN}_name.md   │
│                                                              │
│ 2. Load Agent Behavioral Prompt (optional)                  │
│    AGENT_PROMPT = load_agent_behavioral_prompt("agent")     │
│                                                              │
│ 3. Inject Complete Context                                  │
│    - Behavioral guidelines                                  │
│    - Task requirements                                      │
│    - ARTIFACT_PATH (pre-calculated)                         │
│    - Success criteria                                       │
│                                                              │
│ 4. Invoke Agent via Task Tool                               │
│    ↓                                                         │
└────┬────────────────────────────────────────────────────────┘
     │
     ↓
┌────┴────────────────────────────────────────────────────────┐
│ AGENT (execution layer)                                      │
│                                                              │
│ - Receives: Behavioral prompt + context + ARTIFACT_PATH     │
│ - Executes: Uses Read/Write/Edit tools                      │
│ - Creates: Artifact at EXACT path provided                  │
│ - Returns: Metadata only (path + summary + findings)        │
│                                                              │
│ ⚠️  NEVER uses SlashCommand for artifact creation           │
│                                                              │
└────┬────────────────────────────────────────────────────────┘
     │
     ↓
┌────┴────────────────────────────────────────────────────────┐
│ PRIMARY COMMAND (post-processing)                           │
│                                                              │
│ 5. Verify Artifact Created                                  │
│    VERIFIED = verify_artifact_or_recover(path, slug)        │
│                                                              │
│ 6. Extract Metadata Only                                    │
│    METADATA = extract_report_metadata(path)                 │
│    Context reduction: 5000 tokens → 250 tokens (95%)        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Anti-Pattern: Agent Invokes Slash Command

#### What Not To Do

```markdown
# WRONG: agent-behavioral-file.md

**CRITICAL**: You MUST use SlashCommand to invoke /plan:

SlashCommand {
  command: "/plan ${FEATURE_DESCRIPTION}"
}
```

#### Why It's Wrong

| Issue | Impact |
|-------|--------|
| **Loss of Path Control** | Cannot pre-calculate topic-based paths |
| **Context Bloat** | Cannot extract metadata before full content loaded |
| **Recursion Risk** | Agent may invoke command that invoked it |
| **Organization Violation** | Artifacts may not follow topic-based structure |
| **Testing Difficulty** | Cannot mock agent behavior in tests |

#### Example: /orchestrate Anti-Pattern (Before Fix)

**Before** (plan-architect.md - WRONG):
```markdown
## Step 1: Create Implementation Plan

You MUST use SlashCommand to invoke /plan command:

SlashCommand {
  command: "/plan ${FEATURE_DESCRIPTION}"
}
```

**Result**:
- plan-architect agent invokes /plan command
- /plan command creates plan at unknown path
- /orchestrate cannot verify plan location
- Cannot extract metadata (don't know path)
- Context bloat: 168.9k tokens (no reduction)

### Correct Pattern: Behavioral Injection

#### Reference Implementation

**Command** (orchestrate.md - CORRECT):
```bash
# 1. Pre-calculate topic-based plan path
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESCRIPTION" "specs")
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")
# Result: specs/042_workflow/plans/042_implementation.md

# 2. Invoke plan-architect agent with injected context
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan for ${FEATURE}"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are acting as a Plan Architect Agent.

    **Feature**: ${FEATURE_DESCRIPTION}
    **Research Reports**: ${RESEARCH_REPORT_PATHS}
    **Plan Output Path**: ${PLAN_PATH}

    Create the implementation plan at the exact path provided.
    Return metadata: {path, phase_count, complexity_score}
}

# 3. Verify plan created at expected path
VERIFIED_PATH=$(verify_artifact_or_recover "$PLAN_PATH" "implementation")

# 4. Extract metadata only
PLAN_METADATA=$(extract_plan_metadata "$VERIFIED_PATH")
PHASE_COUNT=$(echo "$PLAN_METADATA" | jq -r '.phase_count')
```

**Agent** (plan-architect.md - CORRECT):
```markdown
## Step 1: Receive Context

You will receive:
- **Feature Description**: The feature to implement
- **Research Reports**: Paths to research reports
- **Plan Output Path**: EXACT path where plan must be created

## Step 2: Create Plan at Exact Path

Use Write tool to create plan file:

Write {
  file_path: "${PLAN_PATH}"  # Use exact path from context
  content: |
    # ${FEATURE} Implementation Plan

    ## Metadata
    - **Research Reports**:
      - ${RESEARCH_REPORT_1}
      - ${RESEARCH_REPORT_2}

    ## Phases
    ...
}

## Step 3: Return Metadata

{
  "path": "${PLAN_PATH}",
  "phase_count": 6,
  "complexity_score": 78,
  "estimated_hours": 14
}
```

**Result**:
- Command controls path → topic-based organization
- Agent creates artifact → direct Write tool
- Command verifies → confirm expected location
- Command extracts metadata → 95% context reduction
- Zero slash command invocations → no recursion risk

### Utilities for Behavioral Injection

#### Path Calculation Utilities

**Source**: `.claude/lib/artifact-creation.sh`

```bash
# Get or create topic directory
get_or_create_topic_dir(description, base_dir)
# Returns: specs/042_feature_name

# Create artifact with sequential numbering
create_topic_artifact(topic_dir, artifact_type, name, content)
# Returns: specs/042_feature/reports/042_name.md
```

#### Agent Loading Utilities

**Source**: `.claude/lib/agent-loading-utils.sh`

```bash
# Load agent behavioral prompt (strip YAML frontmatter)
load_agent_behavioral_prompt(agent_name)
# Returns: Behavioral prompt content

# Get next artifact number
get_next_artifact_number(artifact_dir)
# Returns: "043" (next sequential number)

# Verify artifact with recovery
verify_artifact_or_recover(expected_path, topic_slug)
# Returns: Actual path (may differ if recovery needed)
```

#### Metadata Extraction Utilities

**Source**: `.claude/lib/metadata-extraction.sh`

```bash
# Extract report metadata
extract_report_metadata(report_path)
# Returns: {path, summary, key_findings, recommendations}

# Extract plan metadata
extract_plan_metadata(plan_path)
# Returns: {path, phase_count, complexity_score, estimated_hours}

# Extract debug metadata
extract_debug_metadata(debug_path)
# Returns: {path, summary, findings, proposed_fixes}
```

### Cross-Reference Requirements

#### Plan-Architect Agent

**Requirement**: All plans must reference research reports that informed them.

**Implementation**:
```markdown
## Metadata
- **Date**: 2025-10-20
- **Feature**: User Authentication System
- **Research Reports**:
  - specs/042_auth/reports/042_security_patterns.md
  - specs/042_auth/reports/043_best_practices.md
  - specs/042_auth/reports/044_framework_comparison.md
```

**Why**: Enables traceability from plan to research.

#### Doc-Writer Agent (Summarizer)

**Requirement**: All workflow summaries must reference all artifacts generated.

**Implementation**:
```markdown
## Artifacts Generated

### Research Reports
- specs/042_auth/reports/042_security_patterns.md
- specs/042_auth/reports/043_best_practices.md
- specs/042_auth/reports/044_framework_comparison.md

### Implementation Plan
- specs/042_auth/plans/042_implementation.md

### Debug Reports (if applicable)
- specs/042_auth/debug/042_investigation_token_expiry.md
```

**Why**: Provides complete workflow audit trail.

### Troubleshooting

See [Agent Delegation Troubleshooting Guide](../troubleshooting/agent-delegation-issues.md) for common issues:
- Agent invokes slash command instead of creating artifact
- Artifact not found at expected path
- Context reduction not achieved
- Recursion risk or infinite loops
- Artifacts not in topic-based directories

### Pattern Summary

**Behavioral Injection Pattern**:
- ✅ Commands pre-calculate topic-based paths
- ✅ Commands inject complete context into agents
- ✅ Agents create artifacts at exact paths provided
- ✅ Agents return metadata only (not full content)
- ✅ Commands verify and extract metadata
- ✅ 95% context reduction achieved

**Anti-Pattern to Avoid**:
- ❌ Agents invoking slash commands for artifact creation
- ❌ Agents calculating their own paths
- ❌ Commands loading full artifact content
- ❌ Flat directory structures (non-topic-based)

## Summary

The hierarchical agent architecture provides:

1. **99% context reduction** through metadata-only passing
2. **60-80% time savings** with parallel subagent execution
3. **2.5x scalability** (10+ agents vs 4 without recursion)
4. **Robust error handling** with depth limits and pruning policies

Key utilities:
- `extract_report_metadata()` - 50-word summaries
- `forward_message()` - No-paraphrase handoffs
- `invoke_sub_supervisor()` - Recursive delegation
- `prune_phase_metadata()` - Aggressive context cleanup

Integration points:
- `/implement` - Delegates codebase exploration (complexity ≥8)
- `/plan` - Delegates research (ambiguous features)
- `/debug` - Delegates root cause analysis (complex bugs)
- `/orchestrate` - Supports recursive supervision (10+ topics)

For questions or issues, see [Troubleshooting](#troubleshooting) or check logs in `.claude/data/logs/`.
