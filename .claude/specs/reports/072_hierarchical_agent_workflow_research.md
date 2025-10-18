# Hierarchical Agent Workflow Research Report

## Executive Summary

This report documents the hierarchical agent workflow system used in Claude Code for orchestrating subagents, managing artifacts, and preserving context throughout multi-phase development workflows. The system achieves 92-97% context reduction through metadata-only passing, enables 40-80% time savings with parallel execution, and supports recursive supervision for complex workflows with 10+ research topics.

**Key Findings**:
- **Context Preservation**: Metadata-only passing reduces context from 5000 tokens to 250 tokens per artifact (95% reduction)
- **Parallel Execution**: Wave-based execution with phase dependencies enables 40-60% time savings vs sequential
- **Agent Coordination**: Commands use behavioral injection pattern with general-purpose agents
- **Artifact Organization**: Topic-based directory structure co-locates all artifacts for a feature
- **Plan Hierarchy**: Progressive expansion (Level 0 → Level 1 → Level 2) based on complexity

---

## Table of Contents

1. [Command-Agent Architecture](#command-agent-architecture)
2. [Artifact Organization](#artifact-organization)
3. [Context Preservation Patterns](#context-preservation-patterns)
4. [Phase and Stage Execution](#phase-and-stage-execution)
5. [Agent Workflow Chains](#agent-workflow-chains)
6. [Plan Expansion Process](#plan-expansion-process)
7. [Metadata Extraction Utilities](#metadata-extraction-utilities)
8. [Implementation Patterns](#implementation-patterns)

---

## Command-Agent Architecture

### Agent Invocation Pattern

All commands use **behavioral injection** with the **general-purpose agent type**:

```yaml
Task {
  subagent_type: "general-purpose"  # Only valid agent type
  description: "[task] using [agent-name] protocol"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/[agent-name].md

    You are acting as a [Agent Name].

    [Task-specific instructions]
}
```

**Available Specialized Behaviors** (via behavioral injection):
- `research-specialist` - Read-only codebase analysis
- `plan-architect` - Phased implementation plan generation
- `code-writer` - Code generation following project standards
- `test-specialist` - Test execution and failure analysis
- `debug-specialist` - Root cause analysis and diagnostics
- `doc-writer` - Documentation creation and maintenance
- `code-reviewer` - Standards compliance review
- `metrics-specialist` - Performance analysis
- `github-specialist` - GitHub operations (PRs, issues)
- `complexity-estimator` - Context-aware complexity analysis
- `implementation-researcher` - Codebase exploration before implementation
- `debug-analyst` - Parallel hypothesis investigation

### Layered Context Architecture

Agent invocations use five context layers to minimize token consumption:

**1. Meta-Context (Behavioral Injection)**: ~0 tokens
- Agent behavior read from file, not passed inline
- Pattern: `Read and follow: .claude/agents/[agent-name].md`

**2. Operational Context (Task Instructions)**: 200-500 tokens
- Specific task description and objectives
- Step-by-step execution requirements
- Success criteria and validation

**3. Domain Context (Project Standards)**: 50-100 tokens
- Reference to CLAUDE.md + key constraints
- Not full content, just highlights

**4. Historical Context (Prior Phase Results)**: 250 tokens per artifact
- Metadata only (path + 50-word summary)
- NOT full content (5000 tokens each)
- 95% context reduction

**5. Environmental Context (Workflow State)**: 100-200 tokens
- Current phase in workflow
- Checkpoint data
- Progress tracking

**Total Context**: ~700 tokens (vs 11,500 tokens without layering)

---

## Artifact Organization

### Topic-Based Directory Structure

All artifacts for a feature co-located in numbered topic directories:

```
specs/{NNN_topic}/
├── {NNN_topic}.md              # Main plan (Level 0)
├── reports/                     # Research reports (gitignored)
│   └── NNN_*.md
├── plans/                       # Sub-plans (gitignored, rare)
│   └── NNN_*.md
├── summaries/                   # Implementation summaries (gitignored)
│   └── NNN_*.md
├── debug/                       # Debug reports (COMMITTED)
│   └── NNN_*.md
├── scripts/                     # Investigation scripts (gitignored, temp)
│   └── *.sh
├── outputs/                     # Test outputs (gitignored, temp)
│   └── *.log
├── artifacts/                   # Operation artifacts (gitignored)
│   └── *.md
└── backups/                     # Backups (gitignored)
    └── *.tar.gz
```

### Artifact Lifecycle

| Artifact Type | Gitignored | Lifetime | Cleanup |
|---------------|------------|----------|---------|
| `reports/` | YES | Indefinite | Never |
| `plans/` | YES | Indefinite | Never |
| `summaries/` | YES | Indefinite | Never |
| `debug/` | **NO** (committed) | Permanent | Never |
| `scripts/` | YES | Temporary | After workflow |
| `outputs/` | YES | Temporary | After verification |
| `artifacts/` | YES | Optional | 30 days |
| `backups/` | YES | Optional | 30 days |

**Key Exception**: Debug reports are committed to git for issue tracking and project history.

### Cross-Reference Patterns

Bidirectional cross-references maintained between artifacts:

**Plan → Report** (Forward, metadata-only):
```markdown
Research Reports:
- [JWT Patterns](reports/001_jwt_patterns.md): 50-word summary...
```

**Report → Plan** (Backward, full link):
```markdown
## Metadata
- **Main Plan**: ../042_auth.md
```

**Debug → Plan** (Backward):
```markdown
## Metadata
- **Plan**: ../../042_auth.md
- **Phase**: Phase 2
```

---

## Context Preservation Patterns

### Pattern 1: Metadata-Only Passing

**Anti-Pattern** (massive context):
```bash
# Passes 5000 tokens per report (15,000 total)
for report in reports/*.md; do
  CONTENT=$(cat "$report")
  REPORTS_FULL+=("$CONTENT")
done

Task { prompt: "Research Reports: ${REPORTS_FULL[@]}" }
# Context usage: 15,000 tokens
```

**Correct Pattern** (metadata only):
```bash
# Passes 250 tokens per report (750 total)
for report in reports/*.md; do
  METADATA=$(extract_report_metadata "$report")
  REPORT_METADATA+=("$METADATA")
done

Task {
  prompt: "Research Reports (metadata): ${REPORT_METADATA[@]}
           Use Read tool to access full content selectively if needed."
}
# Context usage: 750 tokens (95% reduction)
```

### Pattern 2: Forward Message Pattern

**Problem**: Primary agents re-summarize subagent outputs, adding 200-300 token overhead.

**Solution**: Pass subagent responses directly without paraphrasing:

```bash
# Subagent completes task
subagent_output="Research complete. Created report at specs/042_auth/reports/001_patterns.md.
Summary: JWT vs sessions analysis..."

# Extract handoff context
handoff=$(forward_message "$subagent_output")
artifact_path=$(echo "$handoff" | jq -r '.artifacts[0].path')
summary=$(echo "$handoff" | jq -r '.summary')  # ≤100 words

# Pass to next phase (metadata only, not full output)
# Original output logged to .claude/data/logs/subagent-outputs.log
```

**Context Savings**: 80-90% per subagent invocation

### Pattern 3: Context Pruning

**Aggressive Pruning** (orchestration workflows, target <20%):
```bash
# After each phase completes
prune_subagent_output "$subagent_id"  # Remove full output, keep metadata
prune_phase_metadata "$phase_name"     # Remove phase data after transition

# Before checkpoint save
apply_pruning_policy --mode aggressive --workflow orchestrate
```

**Moderate Pruning** (implementation workflows, target 20-30%):
```bash
# After major milestones
prune_subagent_output "$agent_id"
prune_phase_metadata "$phase_id"

# Retains recent phase metadata (last 2 phases)
apply_pruning_policy --mode moderate --workflow implement
```

**Minimal Pruning** (single-agent workflows, target 30-50%):
```bash
# Only explicitly marked temporary data
apply_pruning_policy --mode minimal --workflow document
```

---

## Phase and Stage Execution

### Plan Structure Levels

Plans use progressive organization that grows based on complexity:

**Level 0: Single File** (All plans start here)
- Format: `NNN_plan_name.md`
- All phases inline in single file
- Threshold: < 10 tasks, < 4 phases, < 20 hours

**Level 1: Phase Expansion** (Created via `/expand phase`)
- Format: `NNN_plan_name/` directory with phase files
- Created when phase complexity ≥8 or >10 tasks
- Structure:
  - `NNN_plan_name.md` (main plan with summaries)
  - `phase_N_name.md` (expanded phase details)
- Threshold: 10-50 tasks, 4-10 phases, 20-100 hours

**Level 2: Stage Expansion** (Created via `/expand stage`)
- Format: Phase directories with stage files
- Created when phases have complex multi-stage workflows
- Structure:
  - `NNN_plan_name/phase_N_name/` (phase directory)
    - `phase_N_overview.md`
    - `stage_M_name.md` (stage details)
- Threshold: > 50 tasks, > 10 phases, > 100 hours

### Phase Dependencies and Wave-Based Execution

Plans support dependency declarations for parallel execution:

**Dependency Syntax**:
```markdown
### Phase N: [Phase Name]

**Dependencies**: [] or [1, 2, 3]
**Risk**: Low|Medium|High
**Estimated Time**: X-Y hours
```

**Example Plan**:
```markdown
### Phase 1: Database Setup
**Dependencies**: []

### Phase 2: API Layer
**Dependencies**: [1]

### Phase 3: Frontend Components
**Dependencies**: [1]

### Phase 4: Integration Tests
**Dependencies**: [2, 3]
```

**Calculated Waves** (Kahn's algorithm):
```json
[
  [1],       // Wave 1: Phase 1
  [2, 3],    // Wave 2: Phases 2, 3 (parallel)
  [4]        // Wave 3: Phase 4
]
```

**Performance**: 40-60% time savings with parallel execution of independent phases

---

## Agent Workflow Chains

### /plan Command Workflow

**Chain**: Research (optional) → Planning → Complexity Evaluation

```
1. If feature ambiguous:
   └─ Invoke 2-3 research-specialist agents in parallel
      ├─ Topic 1: Patterns research
      ├─ Topic 2: Best practices
      └─ Topic 3: Alternatives
      └─ Returns: Metadata only (title + 50-word summary per report)

2. Plan Creation:
   └─ Invoke plan-architect agent
      ├─ Input: Research metadata (not full content)
      ├─ Task: Synthesize implementation plan
      └─ Output: specs/{topic}/{topic}.md

3. Complexity Evaluation (automatic):
   └─ Calculate complexity score
      ├─ Determine structure level (L0/L1/L2)
      └─ Recommend expansion if needed
```

**Context Saved**: 92% (3 reports × 1500 tokens → 3 × 250 tokens)

### /implement Command Workflow

**Chain**: Phase-by-phase execution → Test → Debug (if needed) → Commit → Update

```
For each phase:
  1. Pre-Implementation Research (if complex):
     └─ If complexity ≥8 or tasks >10:
        └─ Invoke implementation-researcher agent
           ├─ Analyzes codebase for patterns, utilities
           └─ Returns: {path, 50-word summary, key_findings[]}
           └─ Context saved: 95% (5000 tokens → 250 tokens)

  2. Implementation:
     └─ Invoke code-writer agent per phase
        ├─ Input: Phase tasks + research findings (metadata)
        ├─ Task: Implement code following standards
        └─ Output: Code changes

  3. Testing:
     └─ Invoke test-specialist agent
        ├─ Run tests for phase
        └─ Return: Pass/fail status

  4. Debugging Loop (if tests fail, max 3 iterations):
     └─ Invoke debug-specialist agent
        ├─ Analyze failure
        ├─ Propose fixes
        └─ Output: Debug report (committed to debug/)
     └─ Apply fix (code-writer)
     └─ Re-test (test-specialist)

  5. Commit:
     └─ Git commit with phase completion message

  6. Update Plan Hierarchy:
     └─ Invoke spec-updater agent
        ├─ Update checkboxes across plan levels
        └─ Propagate completion status
```

### /orchestrate Command Workflow

**Chain**: Research (parallel) → Planning → Implementation (waves) → Testing → Debugging → Documentation

```
Phase 1: Research (parallel, 2-4 agents)
  └─ Invoke research-specialist agents in parallel
     ├─ Agent 1: Topic 1
     ├─ Agent 2: Topic 2
     ├─ Agent 3: Topic 3
     └─ Returns: Metadata per report
     └─ Prune full outputs immediately
     └─ Context: 750 tokens (vs 15,000 without pruning)

Phase 2: Planning
  └─ Invoke plan-architect agent
     ├─ Input: Research metadata (not full reports)
     ├─ Task: Create implementation plan
     └─ Output: specs/{topic}/{topic}.md
     └─ Prune research metadata after planning

Phase 3: Implementation (wave-based)
  └─ Calculate execution waves from dependencies
     └─ For each wave:
        └─ Execute phases in parallel
           ├─ Invoke code-writer per phase
           └─ Prune phase data after completion

Phase 4: Testing
  └─ Invoke test-specialist agent
     └─ Run complete test suite

Phase 5: Debugging (conditional, max 3 iterations)
  └─ If tests fail:
     └─ Invoke debug-specialist agent
        └─ Create debug report (committed)

Phase 6: Documentation
  └─ Invoke doc-writer agent
     ├─ Update README files
     └─ Create implementation summary

Phase 7: GitHub PR (optional)
  └─ Invoke github-specialist agent
     └─ Create PR with metadata
```

**Performance**: <30% context usage throughout, 40-80% time savings vs sequential

### /debug Command Workflow

**Chain**: Parallel hypothesis investigation → Synthesis → Report creation

```
1. Complex Bug Investigation:
   └─ If >2 potential root causes:
      └─ Invoke debug-analyst agents in parallel (1 per hypothesis)
         ├─ Agent 1: Hypothesis A investigation
         ├─ Agent 2: Hypothesis B investigation
         └─ Agent 3: Hypothesis C investigation
         └─ Returns: {path, 50-word summary, root_cause, proposed_fix}

2. Synthesis:
   └─ Synthesize findings from all investigations
      └─ Identify most likely root cause
      └─ Propose unified fix

3. Report Creation:
   └─ Invoke spec-updater agent
      └─ Create debug report in debug/
      └─ Link to plan and phase
```

**Context Saved**: 80% (3 × 1000 tokens → 750 tokens)

### /report Command Workflow

**Chain**: Research → Metadata extraction → Report creation

```
1. Research:
   └─ Invoke research-specialist agent
      ├─ Search codebase
      ├─ Search web (optional)
      └─ Gather findings

2. Report Creation:
   └─ Create report in specs/{topic}/reports/
      └─ Include metadata section

3. Metadata Extraction:
   └─ Extract metadata for future use
      ├─ Title
      ├─ 50-word summary
      ├─ Key findings
      └─ File references
```

### /document Command Workflow

**Chain**: Code analysis → Documentation updates → Summary

```
1. Documentation Updates:
   └─ Invoke doc-writer agent
      ├─ Analyze recent code changes
      ├─ Update README files
      └─ Maintain cross-references

2. Summary Creation:
   └─ Invoke spec-updater agent
      └─ Create implementation summary in summaries/
      └─ Link to plan and reports
```

---

## Plan Expansion Process

### Automatic Expansion Triggers

Plans automatically expand when complexity thresholds exceeded:

**Phase Expansion** (L0 → L1):
- Complexity score ≥8
- Task count >10
- File references >10

**Stage Expansion** (L1 → L2):
- Phase has complex multi-stage workflows
- Phase complexity remains ≥8 after L1 expansion

### Expansion Workflow

```
1. Complexity Evaluation:
   └─ Calculate phase complexity score
      └─ score = (tasks × 1.0) + (files × 0.3) + (integration_points × 2.0)

2. Decision:
   └─ If score ≥8:
      └─ Trigger expansion

3. Expansion Execution:
   └─ Extract phase content to separate file
      ├─ Create: specs/{plan}/phase_N_name.md
      ├─ Update main plan with summary
      └─ Maintain cross-references

4. Hierarchy Update:
   └─ Update Structure Level metadata
      └─ Update Expanded Phases list
```

### Manual Expansion

Users can manually expand phases/stages:

```bash
# Expand specific phase
/expand phase specs/plans/042_auth.md 3

# Expand specific stage
/expand stage specs/plans/042_auth/phase_3_implementation.md 2

# Auto-analysis mode (complexity-based recommendations)
/expand specs/plans/042_auth.md --auto-analysis
```

**Auto-Analysis Mode**:
1. Invoke complexity-estimator agent
2. Analyze all phases in single pass
3. Return recommendations with complexity scores
4. User approves expansion
5. Execute expansions in parallel

### Collapse Workflow

Plans can be collapsed to simplify structure:

```bash
# Collapse specific phase
/collapse phase specs/plans/042_auth/ 3

# Collapse specific stage
/collapse stage specs/plans/042_auth/phase_3_implementation/ 2

# Auto-analysis mode
/collapse specs/plans/042_auth/ --auto-analysis
```

---

## Metadata Extraction Utilities

### extract_report_metadata()

**Location**: `.claude/lib/artifact-operations.sh:1906-1984`

**Purpose**: Extract concise metadata from research reports

**Usage**:
```bash
metadata=$(extract_report_metadata "specs/042_auth/reports/001_patterns.md")
title=$(echo "$metadata" | jq -r '.title')
summary=$(echo "$metadata" | jq -r '.summary')  # ≤50 words
```

**Extraction Logic**:
1. **Title**: First `# Heading` in file
2. **Summary**: Extract from `## Executive Summary`, truncate to 50 words
3. **File Paths**: Parse `## Findings` for referenced paths
4. **Recommendations**: Extract 3-5 top recommendations

**Output** (JSON):
```json
{
  "title": "Authentication Patterns Research",
  "summary": "JWT vs sessions comparison. JWT recommended for APIs...",
  "file_paths": ["lib/auth/jwt.lua", "lib/auth/sessions.lua"],
  "recommendations": ["Use JWT for API auth", "Use sessions for web app"],
  "path": "specs/042_auth/reports/001_patterns.md",
  "size": 4235
}
```

**Size**: ~250 chars vs 5000 chars for full content (95% reduction)

### extract_plan_metadata()

**Location**: `.claude/lib/artifact-operations.sh:1986-2067`

**Purpose**: Extract implementation plan metadata for complexity assessment

**Usage**:
```bash
metadata=$(extract_plan_metadata "specs/042_auth/plans/001_implementation.md")
complexity=$(echo "$metadata" | jq -r '.complexity')
phases=$(echo "$metadata" | jq -r '.phases')
```

**Extraction Logic**:
1. **Complexity**: Parse `## Metadata` → `**Complexity**: Medium`
2. **Phases**: Count `### Phase N:` headings
3. **Success Criteria**: Count unchecked items
4. **Time Estimate**: Parse `**Time Estimate**: 6-8 hours`

**Output** (JSON):
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

### load_metadata_on_demand()

**Location**: `.claude/lib/artifact-operations.sh:2149-2202`

**Purpose**: Generic metadata loader with automatic type detection and caching

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
- Cache hit rate: ~80%
- Performance: 100x faster for cached metadata

### forward_message()

**Location**: `.claude/lib/artifact-operations.sh:2244-2340`

**Purpose**: Extract handoff context from subagent output without re-summarization

**Usage**:
```bash
subagent_output="Research complete. Created report at specs/042_auth/reports/001_patterns.md.
Summary: JWT vs sessions analysis..."

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
Original output logged to .claude/data/logs/subagent-outputs.log
```

**Context Savings**: 80-90% per subagent invocation

---

## Implementation Patterns

### Pattern 1: Parallel Research with Pruning

```bash
#!/usr/bin/env bash
source .claude/lib/artifact-operations.sh
source .claude/lib/context-pruning.sh

# Launch 3 research agents in parallel
Task { research-specialist: Topic 1 } &
Task { research-specialist: Topic 2 } &
Task { research-specialist: Topic 3 } &

# As each completes, extract metadata and prune immediately
for report_path in "${RESEARCH_OUTPUTS[@]}"; do
  # Extract metadata (path + 50-word summary)
  metadata=$(extract_report_metadata "$report_path")

  # Prune full output immediately
  prune_subagent_output "$report_path" "$metadata"
done

# After all agents complete, prune research phase
prune_phase_metadata "research"

# Context usage: <30% (750 tokens metadata vs 15,000 tokens full content)
```

### Pattern 2: Wave-Based Implementation

```bash
# Calculate execution waves from plan dependencies
WAVES_JSON=$(calculate_execution_waves "$PLAN_PATH")
WAVE_COUNT=$(echo "$WAVES_JSON" | jq 'length')

# Execute phases in waves
for ((wave=0; wave<$WAVE_COUNT; wave++)); do
  # Get phases in current wave
  WAVE_PHASES=$(echo "$WAVES_JSON" | jq -r ".[$wave][]")

  # Execute phases in parallel
  for phase in $WAVE_PHASES; do
    # Invoke code-writer for phase
    Task { code-writer: Phase $phase } &
  done

  # Wait for wave to complete
  wait

  # Prune completed wave
  prune_phase_metadata "wave_$wave"
done
```

### Pattern 3: Metadata-Only Cross-Referencing

```bash
# Create bidirectional cross-references with metadata
REPORT_PATH="specs/042_auth/reports/001_jwt_patterns.md"
PLAN_PATH="specs/042_auth/042_auth.md"

# Extract metadata from report
REPORT_METADATA=$(extract_report_metadata "$REPORT_PATH")

# Update plan with metadata reference (not full content)
update_parent_references "$PLAN_PATH" "$REPORT_METADATA"

# Add parent link to report
add_parent_link "$REPORT_PATH" "../042_auth.md"

# Verify bidirectional links
verify_cross_references "specs/042_auth"
```

### Pattern 4: Checkpoint-Based Recovery

```bash
# Save checkpoint before complex operation
checkpoint_file=$(save_parallel_operation_checkpoint \
  "$plan_path" \
  "expansion" \
  '[{"item_id":"phase_3","complexity":8}]')

# Execute operation
if ! execute_expansion_operation "phase_3"; then
  # Restore on failure
  restore_from_checkpoint "$checkpoint_file"
fi
```

### Pattern 5: Spec Updater Integration

```bash
# Invoke spec-updater agent using behavioral injection
Task {
  subagent_type: "general-purpose"
  description: "Create debug report using spec-updater protocol"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/spec-updater.md

    You are acting as a Spec Updater Agent.

    Create debug report for Phase 2 test failure.

    Topic: specs/009_orchestration_enhancement
    Phase: Phase 2
    Iteration: 1

    Issue: Bundle compatibility test failing
    Root Cause: Function signature mismatch
    Fix Proposals:
    1. Update function call sites (confidence: HIGH)
    2. Add compatibility wrapper (confidence: MEDIUM)

    Create debug report:
    - In specs/009_orchestration_enhancement/debug/
    - Number: Find highest, use next (001, 002, etc.)
    - Include all required metadata
    - Link back to main plan

    After creating report:
    - Verify it's in debug/ subdirectory
    - Check git status (should show as untracked, will be committed)
}
```

---

## Performance Metrics

### Context Reduction

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
- **Target**: <30% context usage

### Parallel Execution

**Sequential**:
- 6 phases × 45 minutes = 270 minutes

**Parallel (3 waves)**:
- Wave 1: 45 minutes
- Wave 2: 45 minutes (3 phases parallel)
- Wave 3: 45 minutes (2 phases parallel)
- Total: 135 minutes
- **Savings**: 50% (135 minutes vs 270 minutes)

### Scalability

**Single-Level Supervision**:
- Max agents: 4-5 (context exhaustion)

**Hierarchical Supervision** (recursive):
- Max agents: 10+
- Supervisors can delegate to sub-supervisors
- Each sub-supervisor manages 2-3 specialized agents
- **Scalability**: 2.5x increase

---

## Key Utilities and Tools

### Artifact Management

**Location**: `.claude/lib/artifact-operations.sh`

```bash
# Create artifact with automatic numbering
create_topic_artifact <topic-dir> <type> <name> <content>

# Cleanup temporary artifacts
cleanup_topic_artifacts <topic-dir> <type> [age-days]
cleanup_all_temp_artifacts <topic-dir>

# Metadata extraction
extract_report_metadata <report-path>
extract_plan_metadata <plan-path>
load_metadata_on_demand <artifact-path>

# Cross-referencing
create_bidirectional_link <parent-artifact> <child-artifact>
update_parent_references <parent-path> <child-metadata>
validate_cross_references <topic-directory>
```

### Context Pruning

**Location**: `.claude/lib/context-pruning.sh`

```bash
# Prune specific subagent output
prune_subagent_output <artifact_path> <metadata_json>

# Prune completed phase
prune_phase_metadata <phase_id> <phase_data_json>

# Apply policy-based pruning
apply_pruning_policy --mode [aggressive|moderate|minimal] --workflow <type>

# Measure context usage
calculate_context_usage
log_context_metrics <command> <reduction_percent>
```

### Dependency Analysis

**Location**: `.claude/lib/dependency-analysis.sh`

```bash
# Parse dependencies from phase
parse_dependencies <plan_file> <phase_number>

# Calculate execution waves
calculate_execution_waves <plan_file>

# Validate dependencies
validate_dependencies <plan_file>

# Detect circular dependencies
detect_circular_dependencies <plan_file>
```

### Checkpoint Management

**Location**: `.claude/lib/checkpoint-utils.sh`

```bash
# Save checkpoint before operation
save_parallel_operation_checkpoint <plan-path> <operation> <items-json>

# Restore on failure
restore_from_checkpoint <checkpoint-file>

# Validate checkpoint integrity
validate_checkpoint_integrity <checkpoint-file>
```

---

## Recommendations

### For Command Development

1. **Always use behavioral injection** with general-purpose agent type
2. **Extract metadata first, prune immediately** after subagent completion
3. **Use layered context architecture** to minimize token consumption
4. **Apply appropriate pruning policy** based on workflow type
5. **Validate dependencies** before wave-based execution

### For Plan Creation

1. **Start with Level 0** (single file) for all plans
2. **Declare phase dependencies** explicitly for parallel execution
3. **Let complexity drive expansion** (automatic triggers)
4. **Use metadata-only references** in cross-links
5. **Commit debug reports** for project history

### For Artifact Organization

1. **Use topic-based directories** for co-location
2. **Follow gitignore compliance** (debug/ committed, others ignored)
3. **Maintain bidirectional cross-references** between artifacts
4. **Clean temporary artifacts** after workflow completion
5. **Extract metadata on-demand** with caching

### For Context Management

1. **Target <30% context usage** throughout workflows
2. **Use aggressive pruning** for orchestration (>5 phases)
3. **Use moderate pruning** for implementation (3-5 phases)
4. **Monitor context metrics** in `.claude/data/logs/context-metrics.log`
5. **Cache metadata** for repeated access (80% hit rate)

---

## Related Documentation

- **Hierarchical Agents Guide**: `.claude/docs/concepts/hierarchical_agents.md`
- **Orchestration Guide**: `.claude/docs/workflows/orchestration-guide.md`
- **Adaptive Planning Guide**: `.claude/docs/workflows/adaptive-planning-guide.md`
- **Spec Updater Guide**: `.claude/docs/workflows/spec_updater_guide.md`
- **Directory Protocols**: `.claude/docs/concepts/directory-protocols.md`
- **Development Workflow**: `.claude/docs/concepts/development-workflow.md`
- **Using Agents**: `.claude/docs/guides/using-agents.md`
- **Phase Dependencies**: `.claude/docs/reference/phase_dependencies.md`
- **Command Reference**: `.claude/docs/reference/command-reference.md`
- **Command Architecture Standards**: `.claude/docs/reference/command_architecture_standards.md`

---

## Conclusion

The hierarchical agent workflow system provides a robust, scalable architecture for multi-agent coordination with exceptional context efficiency. Through metadata-only passing, forward message patterns, aggressive context pruning, and wave-based parallel execution, the system achieves 84-96% context reduction while enabling 40-80% time savings compared to sequential workflows.

Key success factors:
- **Behavioral injection** pattern for agent invocation
- **Layered context architecture** for minimal token consumption
- **Topic-based artifact organization** for co-location and cross-referencing
- **Progressive plan expansion** based on actual complexity
- **Phase dependencies** for wave-based parallel execution
- **Metadata extraction utilities** for 95%+ context reduction
- **Context pruning policies** for <30% usage target

The system supports workflows from simple single-file plans to complex hierarchical structures with 10+ parallel agents, making it suitable for projects of any scale.

---

**Report Created**: 2025-10-18
**Author**: Claude Code Research Analysis
**Version**: 1.0
