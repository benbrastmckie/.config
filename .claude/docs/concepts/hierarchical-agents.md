# Hierarchical Agent Architecture Guide

**Document Status**: SPLIT - This document has been split for maintainability
**Last Updated**: 2025-11-17

---

## This Document Has Been Split

For better maintainability, this large document (2217 lines) has been split into focused files under 400 lines each.

**Please refer to the new split files**:

| Topic | Document | Description |
|-------|----------|-------------|
| Overview | [hierarchical-agents-overview.md](hierarchical-agents-overview.md) | Architecture fundamentals and core principles |
| Coordination | [hierarchical-agents-coordination.md](hierarchical-agents-coordination.md) | Multi-agent coordination patterns |
| Communication | [hierarchical-agents-communication.md](hierarchical-agents-communication.md) | Agent communication protocols |
| Patterns | [hierarchical-agents-patterns.md](hierarchical-agents-patterns.md) | Design patterns and best practices |
| Examples | [hierarchical-agents-examples.md](hierarchical-agents-examples.md) | Reference implementations |
| Troubleshooting | [hierarchical-agents-troubleshooting.md](hierarchical-agents-troubleshooting.md) | Common issues and solutions |

**Start here**: [Hierarchical Agents Overview](hierarchical-agents-overview.md)

---

## Legacy Content Below

The content below is preserved for reference but should be accessed via the split files above.

---

## Overview

The hierarchical agent architecture enables multi-level agent coordination that minimizes context window consumption through metadata-based context passing and recursive supervision.

**Related Documentation**:
- [Using Agents](../guides/development/agent-development/agent-development-fundamentals.md) - Agent invocation patterns and behavioral injection
- [Command Architecture Standards](../reference/architecture/overview.md) - Standards 1, 6-8

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

**Location**: `.claude/lib/workflow/metadata-extraction.sh`

**Purpose**: Extract concise metadata from research reports.

**Usage**:
```bash
source .claude/lib/workflow/metadata-extraction.sh

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

**Location**: `.claude/lib/workflow/metadata-extraction.sh`

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

**Location**: `.claude/lib/workflow/metadata-extraction.sh`

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

**Location**: `.claude/lib/workflow/metadata-extraction.sh:2204-2238`

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

**Location**: `.claude/lib/workflow/metadata-extraction.sh:2244-2340`

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

**Location**: `.claude/lib/workflow/metadata-extraction.sh:2342-2390`

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

**Location**: `.claude/lib/workflow/metadata-extraction.sh:2322-2338`

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

### Sub-Supervisor Pattern

The sub-supervisor pattern enables managing 10+ parallel agents by delegating coordination to specialized supervisors within specific domains.

**Key Characteristics**:
- Each sub-supervisor manages 2-3 specialized agents
- Sub-supervisors aggregate metadata before returning to parent
- Parent orchestrator receives only domain-level summaries (not individual agent outputs)
- Enables 3-level hierarchy: Orchestrator → Sub-Supervisors → Specialized Agents

**Example from Plan 080**:

```yaml
Phase 1: Research Phase (10 topics)
  ↓
Location Specialist calculates topic directory
  ↓
Research Coordinator invokes 3 sub-supervisors:
  ├─ Security Research Supervisor
  │   ├─ Authentication Patterns Agent
  │   ├─ Authorization Patterns Agent
  │   └─ Encryption Standards Agent
  ├─ Architecture Research Supervisor
  │   ├─ Database Design Agent
  │   ├─ API Design Agent
  │   ├─ Service Architecture Agent
  │   └─ Integration Patterns Agent
  └─ Implementation Research Supervisor
      ├─ Testing Strategy Agent
      ├─ Deployment Patterns Agent
      └─ Performance Optimization Agent
```

Each sub-supervisor:
1. Receives domain-specific task list from parent
2. Assigns tasks to specialized agents (parallel invocation)
3. Collects agent outputs and extracts metadata
4. Aggregates into domain summary (100-word limit)
5. Returns to parent: `{domain, artifacts[], summary, key_findings[]}`

**Context Reduction**:
- Without sub-supervisors: 10 agents × 250 tokens = 2,500 tokens
- With sub-supervisors: 3 domains × 150 tokens = 450 tokens
- Reduction: 82%

**Template Location**: `.claude/templates/sub_supervisor_pattern.md`

### invoke_sub_supervisor()

**Location**: `.claude/lib/workflow/metadata-extraction.sh:2445-2524`

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

**Location**: `.claude/lib/workflow/metadata-extraction.sh:2526-2561`

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

**Location**: `.claude/lib/workflow/metadata-extraction.sh:2563-2628`

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

**Location**: `.claude/lib/workflow/context-pruning.sh`

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

**Context Pruning Functions** (`.claude/lib/workflow/context-pruning.sh`):
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

**Metadata Extraction** (`.claude/lib/workflow/metadata-extraction.sh`):
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
source .claude/lib/workflow/metadata-extraction.sh
# Context pruning library not yet implemented

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
- [Command Architecture Standards](../reference/architecture/overview.md#standard-8) for context pruning requirements (Standard 8)
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

**Plan 080 Metrics** (10-agent research phase):
- Without sub-supervisors: 10 reports × 500 tokens = 5,000 tokens (25% context)
- With sub-supervisors: 3 domains × 150 tokens = 450 tokens (2.25% context)
- Reduction: 91%
- Scalability improvement: Enables 40+ agents before hitting 30% threshold (vs 12 agents without)

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
# Context pruning library not yet implemented

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

**2. Subagent Output Logs**:
```bash
# Review full subagent outputs (not retained in memory)
tail -50 .claude/data/logs/subagent-outputs.log
```

**3. Phase Handoff Logs**:
```bash
# Review handoff contexts between phases
tail -50 .claude/data/logs/phase-handoffs.log
```

### Performance Analysis

**Context Reduction Validation**:
```bash
# Run validation script
.claude/lib/# validate-context-reduction.sh (removed)

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
```

## Examples

### Example 1: Simple Metadata Extraction

```bash
#!/usr/bin/env bash
source .claude/lib/workflow/metadata-extraction.sh

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
source .claude/lib/workflow/metadata-extraction.sh

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
source .claude/lib/workflow/metadata-extraction.sh

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
# Context pruning library not yet implemented

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

### Example 6: /research Command with Hierarchical Research

```bash
# User runs:
/research "authentication patterns and security best practices"

# /research automatically decomposes topic into 2-4 subtopics:
SUBTOPICS=(
  "jwt_implementation_patterns"
  "oauth2_flows_and_providers"
  "security_best_practices"
)

# Pre-calculates hierarchical paths:
RESEARCH_SUBDIR="specs/074_auth_patterns/reports/001_research/"
SUBTOPIC_PATHS=(
  "$RESEARCH_SUBDIR/001_jwt_implementation_patterns.md"
  "$RESEARCH_SUBDIR/002_oauth2_flows_and_providers.md"
  "$RESEARCH_SUBDIR/003_security_best_practices.md"
)
OVERVIEW_PATH="$RESEARCH_SUBDIR/OVERVIEW.md"  # ALL CAPS, not numbered

# Invokes 3 research-specialist agents in parallel:
# - Each agent receives pre-calculated absolute path
# - Agents create reports independently
# - 40-60% time savings vs sequential

# After all subtopic reports created:
# - Invokes research-synthesizer agent
# - Creates OVERVIEW.md synthesis report
# - Invokes spec-updater for cross-references

# Final structure:
# specs/074_auth_patterns/reports/001_research/
#   ├── 001_jwt_implementation_patterns.md
#   ├── 002_oauth2_flows_and_providers.md
#   ├── 003_security_best_practices.md
#   └── OVERVIEW.md  # Final synthesis (ALL CAPS)

# Context reduction: 95% (3x 5000 chars → 750 chars)
```

**OVERVIEW.md Convention**: The overview file is always named `OVERVIEW.md` (ALL CAPS, not numbered) to distinguish it as the final synthesis report rather than another numbered subtopic report. This makes it easy to identify the entry point for understanding all research in a hierarchical research directory.

## Agent Invocation Patterns

### Overview

This section documents the correct patterns for invoking agents from commands, with emphasis on the **behavioral injection pattern** that enables metadata-based context reduction and topic-based artifact organization.

**Related Documentation**:
- [Agent Authoring Guide](../guides/development/agent-development/agent-development-fundamentals.md) - Creating agent behavioral files
- [Command Authoring Guide](../guides/development/command-development/command-development-fundamentals.md) - Invoking agents from commands

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
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact/artifact-creation.sh"
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

**Source**: `.claude/lib/artifact/artifact-creation.sh`

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

**Source**: `.claude/lib/workflow/metadata-extraction.sh`

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

See [Agent Delegation Troubleshooting Guide](../troubleshooting/agent-delegation-troubleshooting.md) for common issues:
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

## Tutorial Walkthrough

This section provides step-by-step walkthroughs of hierarchical agent workflows for each major command, demonstrating how the architecture principles translate into practice.

### Tutorial: /orchestrate Workflow

**Scenario**: Implement an authentication system end-to-end

**Steps**:

```
User runs: /orchestrate "implement authentication system"

Primary Orchestrator initializes workflow state:
  - Creates master plan (todo list)
  - Determines topic directory: specs/027_authentication/
  - Sets context target: <30% usage

PHASE 1: Research (Parallel)
  ↓
Orchestrator invokes 3 research specialists in parallel:
  Task { research-specialist: "authentication patterns" }
  Task { research-specialist: "security best practices" }
  Task { research-specialist: "framework comparison" }

Each specialist completes and returns metadata:
  {
    "report_path": "specs/027_auth/reports/027_patterns.md",
    "summary": "JWT vs sessions analysis. JWT recommended for APIs...",
    "key_findings": [...],
    "recommendations": [...]
  }

Orchestrator receives 3 metadata summaries (250 tokens each = 750 tokens)
  - Does NOT read full reports (would be 15,000 tokens)
  - Stores: report paths + summaries only
  - Context usage: 3.75% (750/20,000)

PHASE 2: Planning (Sequential)
  ↓
Orchestrator calculates plan path:
  - PLAN_PATH = "specs/027_auth/plans/027_implementation.md"

Orchestrator invokes plan-architect agent:
  Task {
    description: "Create implementation plan"
    prompt: |
      Feature: Authentication system
      Research Reports:
        - specs/027_auth/reports/027_patterns.md
        - specs/027_auth/reports/027_security.md
        - specs/027_auth/reports/027_frameworks.md
      Plan Output Path: ${PLAN_PATH}

      Create plan at exact path provided.
      Return metadata only.
  }

Plan-architect completes:
  - Uses Write tool to create plan at PLAN_PATH
  - Returns metadata:
    {
      "path": "specs/027_auth/plans/027_implementation.md",
      "phases": 6,
      "complexity_score": 78,
      "estimated_hours": 14,
      "expanded_phases": [2, 4]
    }

Orchestrator receives plan metadata (350 tokens)
  - Does NOT read full plan (would be 8,000 tokens)
  - Stores: plan path + metadata only
  - Context usage: 5.5% (1,100/20,000)

PHASE 3: Complexity Evaluation (Conditional)
  ↓
Orchestrator checks complexity score (78 > 70 threshold)
  - Decision: Proceed with plan as-is (complexity acceptable)
  - Alternative: If score >90, would invoke /expand

PHASE 4: Implementation (Wave-Based)
  ↓
Orchestrator invokes /implement:
  - SlashCommand { command: "/implement ${PLAN_PATH}" }

/implement executes phases in waves:
  Wave 1: Phase 1 (database setup)
  Wave 2: Phase 2, 3 in parallel (backend, frontend)
  Wave 3: Phase 4 (integration)
  Wave 4: Phase 5, 6 sequential (testing, docs)

After each phase completion, /implement prunes context:
  - Clears implementation details
  - Keeps: phase summary (100 words) + files modified
  - Context reduction: 5,000 tokens → 150 tokens (97%)

/implement completes and returns:
  {
    "implementation_complete": true,
    "phases_completed": "6/6",
    "tests_passing": true,
    "summary_path": "specs/027_auth/summaries/027_implementation.md",
    "summary": "[200-word summary]"
  }

Orchestrator receives implementation summary (200 tokens)
  - Does NOT read full summary file
  - Stores: summary text + summary path
  - Context usage: 7% (1,400/20,000)

PHASE 5: Documentation (Sequential)
  ↓
Orchestrator invokes /document:
  - SlashCommand { command: "/document 'authentication system'" }

/document completes:
  {
    "files_modified": ["README.md", "USER_GUIDE.md"],
    "summary": "[100-word summary]"
  }

Orchestrator receives doc summary (100 tokens)
  - Context usage: 7.5% (1,500/20,000)

PHASE 6: Workflow Summary (Final)
  ↓
Orchestrator invokes spec-updater agent:
  Task {
    description: "Create workflow summary"
    prompt: |
      Create summary at: specs/027_auth/summaries/027_workflow.md

      Artifacts:
        Reports: [paths]
        Plan: ${PLAN_PATH}
        Implementation summary: [path]

      Return: summary_path + metadata
  }

Spec-updater creates workflow summary:
  - Aggregates all artifact references
  - Updates cross-references
  - Returns metadata (150 tokens)

FINAL STATE:
  Total context usage: 8.25% (1,650/20,000)
  Target achieved: <30%
  Time elapsed: 45 minutes
  Artifacts created:
    - 3 research reports
    - 1 implementation plan (Level 1 expanded)
    - 1 implementation summary
    - 1 workflow summary
  Performance: 60% time savings vs sequential execution
```

**Key Observations**:
- Metadata-only passing maintained context <10% throughout
- Parallel research saved 66% time (3 agents × 5min = 15min → 5min)
- Wave-based implementation saved 40% time
- Full artifacts never loaded into orchestrator context

### Tutorial: /implement with Subagent Delegation

**Scenario**: Complex phase triggers implementation-researcher subagent

**Steps**:

```
User runs: /implement specs/027_auth/plans/027_implementation.md

/implement parses plan:
  - 6 phases total
  - Phase 3 complexity: 9.2 (high)
  - Phase 3 tasks: 12 (exceeds 10 threshold)

/implement reaches Phase 3:
  Phase 3: Implement JWT token generation and validation
    Complexity: 9.2
    Tasks: 12
    Files: lib/auth/jwt.lua, lib/auth/tokens.lua, lib/crypto/sign.lua

Trigger: complexity ≥8 AND tasks >10
  ↓
/implement invokes implementation-researcher subagent:
  Task {
    description: "Explore codebase for Phase 3"
    prompt: |
      Phase: 3
      Description: Implement JWT token generation and validation
      Files: lib/auth/jwt.lua, lib/auth/tokens.lua, lib/crypto/sign.lua

      Research:
        1. Existing JWT/crypto implementations
        2. Available utility functions
        3. Patterns to follow
        4. Integration points

      Create exploration report at:
        specs/027_auth/artifacts/phase_3_exploration.md

      Return metadata: {path, summary, key_findings}
  }

Implementation-researcher explores codebase:
  - Greps for "jwt", "crypto", "sign" across codebase
  - Reads lib/crypto/sign.lua (finds signing utility)
  - Reads lib/auth/sessions.lua (finds similar pattern)
  - Identifies middleware/auth.lua as integration point

Implementation-researcher creates artifact:
  - Writes: specs/027_auth/artifacts/phase_3_exploration.md (5,000 tokens)
  - Returns metadata:
    {
      "path": "specs/027_auth/artifacts/phase_3_exploration.md",
      "summary": "Found existing JWT utility in lib/crypto/sign.lua. Sessions pattern in lib/auth/sessions.lua provides good structure. Middleware integration via lib/middleware/auth.lua required.",
      "key_findings": [
        "Reuse lib/crypto/sign.lua for JWT signing",
        "Follow sessions.lua structure for token management",
        "Add middleware integration in lib/middleware/auth.lua"
      ]
    }

/implement receives metadata (250 tokens, not 5,000):
  - Context reduction: 95%
  - Stores: metadata only

/implement proceeds with Phase 3 implementation:
  - Reads exploration artifact on-demand for context
  - Follows identified patterns
  - Reuses crypto/sign.lua utility
  - Completes Phase 3 successfully

/implement prunes exploration artifact:
  - Clears full artifact content from memory
  - Retains: artifact path + metadata (250 tokens)
  - Ready for Phase 4 with <25% context usage
```

**Key Observations**:
- Subagent delegation triggered automatically by complexity/tasks
- Context saved: 95% (5,000 tokens → 250 tokens)
- On-demand reading: Full artifact loaded only when implementing
- Aggressive pruning: Full content cleared after phase completion

### Tutorial: /plan with Research Integration

**Scenario**: Ambiguous feature requires research before planning

**Steps**:

```
User runs: /plan "add caching layer"

/plan analyzes feature description:
  - Ambiguity detected: "caching layer" could mean:
    1. In-memory caching (Redis, Memcached)
    2. HTTP caching (Varnish, CDN)
    3. Database query caching
    4. Application-level caching

Decision: Invoke research agents to clarify approaches
  ↓
/plan invokes 3 research agents in parallel:
  Task { research-specialist: "in-memory caching patterns" }
  Task { research-specialist: "HTTP caching best practices" }
  Task { research-specialist: "database query caching strategies" }

Each agent completes in 4-6 minutes (parallel execution)
  - Total time: 6 minutes (vs 18 minutes sequential)
  - Time savings: 66%

Each agent returns metadata:
  {
    "report_path": "specs/028_caching/reports/028_inmemory.md",
    "summary": "Redis recommended for session data, Memcached for simple key-value...",
    "key_findings": [...],
    "recommendations": [...]
  }

/plan receives 3 metadata summaries (750 tokens total)
  - Does NOT read full reports yet
  - Context usage: 3.75%

/plan synthesizes research findings:
  - Determines: Application-level + in-memory caching (Redis)
  - Creates plan incorporating research recommendations

/plan invokes plan-architect agent:
  Task {
    prompt: |
      Feature: Caching layer (Redis-based)
      Research Reports:
        - specs/028_caching/reports/028_inmemory.md
        - specs/028_caching/reports/028_http.md
        - specs/028_caching/reports/028_database.md

      Create plan at: specs/028_caching/plans/028_implementation.md

      Plan should:
        - Follow Redis recommendations from research
        - Include cache invalidation strategy
        - Address concerns from research reports
  }

Plan-architect completes:
  - Reads research reports for detailed recommendations
  - Creates plan with 5 phases
  - Cross-references research reports in plan metadata
  - Returns metadata:
    {
      "path": "specs/028_caching/plans/028_implementation.md",
      "phases": 5,
      "complexity_score": 65,
      "research_reports": [
        "specs/028_caching/reports/028_inmemory.md",
        "specs/028_caching/reports/028_http.md",
        "specs/028_caching/reports/028_database.md"
      ]
    }

/plan completes:
  - Total time: 12 minutes (6 research + 6 planning)
  - Context usage: 5% (1,000 tokens)
  - Artifacts: 3 reports + 1 plan with cross-references
```

**Key Observations**:
- Research delegation triggered by ambiguous feature description
- Parallel research saved 66% time
- Metadata-only passing until planning phase needed details
- Cross-references establish traceability from plan to research

### Tutorial: Checkpoint Recovery

**Scenario**: Implementation interrupted, resume from last checkpoint

**Steps**:

```
User runs: /implement specs/027_auth/plans/027_implementation.md

/implement begins:
  Phase 1: Database setup (COMPLETE)
  Phase 2: Backend API (COMPLETE)
  Phase 3: Frontend components (IN PROGRESS - interrupted)
    Task 1: Create login form ✓
    Task 2: Create session management ✗ (interrupted here)
    Task 3: Add error handling ✗

System interruption occurs (user closes terminal, timeout, etc.)

Checkpoint system automatically saved state:
  Location: .claude/data/checkpoints/027_auth_implementation.json
  Content:
    {
      "plan_path": "specs/027_auth/plans/027_implementation.md",
      "current_phase": 3,
      "completed_phases": [1, 2],
      "phase_3_progress": {
        "completed_tasks": [1],
        "pending_tasks": [2, 3],
        "files_modified": ["components/LoginForm.vue"]
      },
      "context_summary": {
        "phase_1": "Database schema created, migrations run",
        "phase_2": "API endpoints implemented, tests passing"
      }
    }

---

User resumes: /implement specs/027_auth/plans/027_implementation.md

/implement detects checkpoint:
  - Reads checkpoint file
  - Restores workflow state
  - Context restoration: 500 tokens (not full 10,000 tokens)

/implement resumes from Phase 3, Task 2:
  - Loads phase 3 context from checkpoint
  - Reviews completed work (Task 1)
  - Continues with Task 2

Phase 3 completes successfully

/implement updates checkpoint:
  - current_phase: 4
  - completed_phases: [1, 2, 3]
  - Removes phase_3_progress (no longer needed)

/implement continues to Phase 4...
```

**Key Observations**:
- Checkpoint saved automatically after each phase
- Recovery restores state without re-reading all artifacts
- Context restoration: 500 tokens (metadata) vs 10,000+ tokens (full artifacts)
- Work not lost: Resumed exactly where interrupted

### Best Practices from Tutorials

**For Command Developers**:
1. Always trigger subagents before high-complexity phases (≥8 score)
2. Use metadata-only passing throughout workflow
3. Implement checkpointing for long-running workflows
4. Prune context aggressively after each phase completion

**For Workflow Orchestrators**:
1. Maintain master plan as primary context anchor
2. Read full artifacts only when absolutely necessary
3. Monitor context usage, target <30% throughout
4. Use parallel execution for independent phases

**For Integration**:
1. Cross-reference artifacts in metadata for traceability
2. Update plan hierarchy checkboxes automatically
3. Create summaries when context usage exceeds 25%
4. Verify gitignore compliance for all artifacts

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
