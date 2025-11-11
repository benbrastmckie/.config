# .claude/ Infrastructure and Standards Research Report

## Metadata
- **Date**: 2025-11-11
- **Agent**: research-specialist
- **Topic**: .claude/ infrastructure and standards for agent delegation and performance optimization
- **Report Type**: codebase analysis | architecture documentation | best practices synthesis
- **Complexity Level**: 2
- **Research Scope**: Infrastructure libraries, agent delegation patterns, performance optimization, state management

## Executive Summary

The .claude/ infrastructure provides a comprehensive orchestration system built on state-based architecture, achieving 48.9% code reduction (3,420 → 1,748 lines) with 95.6% context reduction and 67% state operation performance improvements. The system implements explicit state machines, selective file-based persistence, hierarchical supervisor coordination, and behavioral injection patterns for reliable agent delegation. Key performance metrics include 100% file creation reliability, 53% time savings via parallel execution, and <30% context usage throughout workflows.

Three production-ready orchestration commands leverage this infrastructure (/coordinate, /orchestrate, /supervise) with /coordinate recommended for production workflows due to mature wave-based parallel execution and fail-fast error handling. The architecture follows Standard 11 (Imperative Agent Invocation) achieving >90% agent delegation rates by eliminating documentation-only YAML blocks and using explicit Task tool invocations with behavioral injection.

## Findings

### 1. State-Based Orchestration Architecture

**Location**: `.claude/lib/workflow-state-machine.sh` (513 lines), `.claude/docs/architecture/state-based-orchestration-overview.md` (2,000+ lines)

**Architecture Overview** (lines 1-8, state-based-orchestration-overview.md):
- 8 explicit states replacing implicit phase numbers: initialize, research, plan, implement, test, debug, document, complete
- State transition table validates allowed transitions (prevents invalid state changes)
- Atomic two-phase commit for state transitions with checkpoint coordination
- Workflow scope integration maps scope to terminal state

**Key Benefits Documented** (lines 30-46):
- **Code Reduction**: 48.9% (exceeded 39% target by 9.9%) across /coordinate, /orchestrate, /supervise
- **Performance**: 67% faster state operations (6ms → 2ms CLAUDE_PROJECT_DIR detection)
- **Context Reduction**: 95.6% via hierarchical supervisors (10,000 → 440 tokens)
- **Parallel Execution**: 53% time savings through wave-based implementation
- **Reliability**: 100% file creation rate maintained

**State Machine Components** (workflow-state-machine.sh:33-43):
```bash
readonly STATE_INITIALIZE="initialize"       # Phase 0
readonly STATE_RESEARCH="research"           # Phase 1
readonly STATE_PLAN="plan"                   # Phase 2
readonly STATE_IMPLEMENT="implement"         # Phase 3
readonly STATE_TEST="test"                   # Phase 4
readonly STATE_DEBUG="debug"                 # Phase 5
readonly STATE_DOCUMENT="document"           # Phase 6
readonly STATE_COMPLETE="complete"           # Phase 7
```

**Transition Validation** (workflow-state-machine.sh:50-59):
- Transition table defines valid state changes (comma-separated allowed next states)
- sm_transition() validates transitions before execution
- Fail-fast error detection prevents workflow corruption
- Terminal state varies by workflow scope (research-only, research-and-plan, full-implementation, debug-only)

**Decision Criteria for State-Based Architecture** (state-based-orchestration-overview.md:73-87):
- Use when: Multiple conditional transitions, 4+ parallel workers, checkpoint resume required
- Use simpler approaches when: Linear workflow, single-purpose command, <3 phases
- State overhead justified when context reduction and resumability outweigh complexity

### 2. Performance Optimization Libraries

**2.1 Metadata Extraction** (`.claude/lib/metadata-extraction.sh`, 541 lines)

**Functions Implemented** (lines 13-541):
- `extract_report_metadata()`: Title, 50-word summary, file paths, recommendations (lines 13-87)
- `extract_plan_metadata()`: Title, phases, complexity, time estimate, success criteria (lines 89-166)
- `extract_summary_metadata()`: Workflow type, artifacts count, test status, performance (lines 168-242)
- `load_metadata_on_demand()`: Generic metadata loader with caching (lines 244-293)

**Context Reduction Pattern** (lines 26-39):
```bash
# Extract title (first # heading)
local title=$(head -100 "$report_path" | grep -m1 '^# ' | sed 's/^# //')

# Extract 50-word summary from Executive Summary section
local summary=$(get_report_section "$report_path" "Executive Summary" | \
  grep -v '^#' | head -5 | tr '\n' ' ' | awk '{for(i=1;i<=50;i++) printf "%s ", $i}')
```

**Performance Impact**:
- 95% context reduction achieved (5000 tokens → 250 tokens per artifact)
- Enables 4+ parallel agents without context overflow
- Metadata caching prevents redundant extraction operations

**2.2 Context Pruning** (`.claude/lib/context-pruning.sh`, 454 lines)

**Pruning Functions** (lines 1-453):
- `prune_subagent_output()`: Clear full output, retain metadata only (lines 45-110)
- `prune_phase_metadata()`: Remove phase data after completion (lines 142-167)
- `prune_workflow_metadata()`: Remove workflow metadata after completion (lines 235-271)
- `apply_pruning_policy()`: Workflow-specific pruning policies (lines 388-436)

**Pruning Policies by Workflow Type** (lines 400-433):
- **plan_creation**: Prune research metadata after planning completes
- **orchestrate**: Prune research/planning metadata after implementation
- **implement**: Prune previous phase research after each phase

**Context Size Reporting** (lines 347-378):
```bash
report_context_savings() {
  local reduction=$(( (before - after) * 100 / before ))
  # Target: <30% context usage
  # Status: $([ "$reduction" -ge 70 ] && echo "✓ Target met")
}
```

**2.3 Dependency Analyzer** (`.claude/lib/dependency-analyzer.sh`, 639 lines)

**Wave-Based Execution** (lines 7-15):
- Parses phase/stage dependency metadata from plan files
- Builds dependency graphs with topological sorting (Kahn's algorithm)
- Identifies execution waves (groups of independent phases for parallel execution)
- Calculates parallelization metrics and time savings estimates

**Dependency Parsing Formats** (lines 77-102):
```bash
# Format 1: **Dependencies**: depends_on: [phase_1]
# Format 2: - depends_on: [phase_1, phase_2]
# Format 3: Dependencies: depends_on: [phase_1]
```

**Wave Identification Algorithm** (lines 296-392):
- Kahn's algorithm for topological sort
- In-degree calculation for each phase
- Wave grouping of phases with in-degree 0 (no unsatisfied dependencies)
- Cycle detection using DFS (lines 401-474)

**Performance Calculations** (lines 504-527):
```bash
# Estimate time (assume 3 hours per phase average)
local sequential_time=$((total_phases * avg_phase_time))
local parallel_time=$((wave_count * avg_phase_time))
local time_savings=$(( (sequential_time - parallel_time) * 100 / sequential_time ))
```

**Typical Results**: 40-60% time savings for plans with moderate dependencies

### 3. State Persistence Strategy

**Location**: `.claude/lib/state-persistence.sh` (341 lines)

**GitHub Actions-Style Pattern** (lines 1-75):
- init_workflow_state(): Create state file with initial variables (lines 115-142)
- load_workflow_state(): Source state file to restore variables (lines 168-182)
- append_workflow_state(): Append key-value pairs ($GITHUB_OUTPUT pattern, lines 207-217)
- save_json_checkpoint(): Atomic write for structured data (lines 240-258)

**Performance Optimization** (lines 20-35):
- CLAUDE_PROJECT_DIR detection: 50ms (git rev-parse) → 15ms (file read) = 70% improvement
- Cached in state file after first detection
- Subsequent blocks read cached value

**Selective State Persistence Decision Criteria** (lines 61-69):
- **File-based when**: State accumulates across subprocess boundaries, expensive to recalculate (>30ms), non-deterministic
- **Stateless when**: Fast to recalculate (<10ms), deterministic, ephemeral
- **7 critical items** using file-based persistence identified via analysis

**Example Critical Items** (lines 47-55):
1. Supervisor metadata (95% context reduction, non-deterministic research findings)
2. Benchmark dataset (accumulation across 10 subprocess invocations)
3. Implementation supervisor state (parallel execution tracking)
4. Testing supervisor state (lifecycle coordination)
5. Migration progress (resumable multi-hour migrations)

**Graceful Degradation** (lines 172-181):
```bash
if [ -f "$state_file" ]; then
  source "$state_file"  # Load cached state
  return 0
else
  init_workflow_state "$workflow_id" >/dev/null  # Fallback: recalculate
  return 1
fi
```

### 4. Agent Delegation Standards

**Location**: `.claude/docs/reference/command_architecture_standards.md` (2,325 lines)

**Standard 11: Imperative Agent Invocation Pattern** (lines 1173-1353)

**Required Elements** (lines 1181-1205):
1. **Imperative Instruction**: `**EXECUTE NOW**: USE the Task tool to invoke...`
2. **Agent Behavioral File Reference**: `Read and follow: .claude/agents/[agent-name].md`
3. **No Code Block Wrappers**: Task invocations must NOT be fenced with ` ```yaml `
4. **No "Example" Prefixes**: Remove documentation context markers
5. **Completion Signal Requirement**: `Return: REPORT_CREATED: ${REPORT_PATH}`

**Anti-Pattern: Documentation-Only YAML Blocks** (lines 1229-1245):
```markdown
❌ INCORRECT - This will never execute:

Example agent invocation:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "Read .claude/agents/research-specialist.md..."
}
```

The code block wrapper prevents execution.
```

**Correct Pattern** (lines 1209-1227):
```markdown
✅ CORRECT:

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: OAuth 2.0 authentication for Node.js APIs
    - Output Path: /path/to/report.md

    Return: REPORT_CREATED: /path/to/report.md
  "
}
```

**Performance Metrics** (lines 1340-1347):
- Agent delegation rate: >90% (all invocations execute)
- File creation rate: 100% (agents create artifacts at expected paths)
- Context reduction: 90% per invocation (behavioral injection vs inline duplication)
- Parallel execution: Enabled for independent operations

**Standard 12: Structural vs Behavioral Content Separation** (lines 1356-1453)

**Structural Templates (MUST Be Inline)** (lines 1360-1384):
1. Task invocation syntax: `Task { subagent_type, description, prompt }`
2. Bash execution blocks: `**EXECUTE NOW**: bash commands`
3. JSON schemas: Data structure definitions
4. Verification checkpoints: `**MANDATORY VERIFICATION**: file checks`
5. Critical warnings: `**CRITICAL**: error conditions`

**Behavioral Content (MUST NOT Be Duplicated)** (lines 1386-1407):
1. Agent STEP sequences: `STEP 1/2/3` procedural instructions
2. File creation workflows: `PRIMARY OBLIGATION` blocks
3. Agent verification steps: Agent-internal quality checks
4. Output format specifications: Templates for agent responses

**Benefits of Separation** (lines 1409-1423):
- 90% code reduction per agent invocation (150 lines → 15 lines)
- Single source of truth for agent behavioral guidelines
- Elimination of synchronization burden
- <30% context window usage throughout workflows

### 5. Behavioral Injection Pattern

**Location**: `.claude/docs/concepts/patterns/behavioral-injection.md` (1,162 lines)

**Pattern Definition** (lines 10-21):
- Commands inject execution context via file reads instead of SlashCommand invocations
- Transforms agents from autonomous executors into orchestrated workers
- Separates command role (orchestrator) from agent role (executor)

**Why This Pattern Matters** (lines 23-39):
- Prevents role ambiguity (orchestrator vs executor)
- Avoids context bloat (command-to-command invocations nest full prompts)
- Enables hierarchical multi-agent patterns
- Achieves 100% file creation rate through explicit path injection

**Core Mechanism** (lines 40-88):
```markdown
Phase 0: Role Clarification
## YOUR ROLE
You are the ORCHESTRATOR for this workflow. Your responsibilities:
1. Calculate artifact paths and workspace structure
2. Invoke specialized subagents via Task tool
3. DO NOT execute implementation work yourself

Path Pre-Calculation
EXECUTE NOW - Calculate Paths:
1. Determine project root
2. Find deepest directory encompassing workflow scope
3. Calculate next topic number: specs/NNN_topic/
4. Create topic directory structure
5. Assign artifact paths

Context Injection via File Content
Task {
  prompt: "
    Read and follow: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: OAuth 2.0 authentication patterns
    - Output Path: ${REPORT_PATH} (absolute path, pre-calculated)

    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

**Anti-Pattern Case Study: Spec 495** (lines 678-823)

**Problem Details** (lines 686-725):
- File: `.claude/commands/coordinate.md`
- Affected Lines: 9 agent invocations across all phases
- Root Cause: YAML blocks wrapped in markdown code fences
- Result: 0% agent delegation rate despite correct Task tool syntax

**Solution Applied** (lines 726-769):
```markdown
Before (Documentation-only YAML):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME}"
  prompt: "Read .claude/agents/research-specialist.md..."
}
```

After (Imperative bullet-point):
**EXECUTE NOW**: USE the Task tool NOW with these parameters:

- subagent_type: "general-purpose"
- description: "Research authentication patterns for REST APIs"
- prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    Research topic: Authentication patterns for REST APIs
    Output file: [insert $report_path from above]

**WAIT FOR**: Agent to return REPORT_CREATED: $report_path
```

**Results** (lines 772-786):
- Delegation Rate: 0% → >90% (9 of 9 invocations)
- File Creation: 0% → 100% (all artifacts in correct locations)
- Performance Impact: No overhead from proper delegation

### 6. Command Guide Architecture

**Location**: `.claude/docs/guides/coordinate-command-guide.md` (1,127 lines)

**Workflow Types Supported** (lines 234-358):
1. **Research-Only**: Phases 0-1 only (research without plan/implement)
2. **Research-and-Plan**: Phases 0-2 only (MOST COMMON)
3. **Full-Implementation**: Phases 0-4, 6 (Phase 5 conditional on test failures)
4. **Debug-Only**: Phases 0, 1, 5 only (bug fixing without new implementation)

**Wave-Based Parallel Execution** (lines 361-423):
```markdown
How It Works:
1. Dependency Analysis: Parse implementation plan, extract phase dependencies
2. Wave Calculation: Group phases using Kahn's algorithm
3. Parallel Execution: Execute all phases within wave simultaneously
4. Wave Checkpointing: Save state after each wave completes

Example:
Plan with 8 phases:
  Wave 1: [Phase 1, Phase 2]          ← 2 phases in parallel
  Wave 2: [Phase 3, Phase 4, Phase 5] ← 3 phases in parallel
  Wave 3: [Phase 6, Phase 7]          ← 2 phases in parallel
  Wave 4: [Phase 8]                   ← 1 phase

Time Savings:
  Sequential: 8 phases × avg_time = 8T
  Wave-based: 4 waves × avg_time = 4T
  Savings: 50%
```

**Performance Impact** (lines 416-419):
- Best case: 60% time savings (many independent phases)
- Typical case: 40-50% time savings (moderate dependencies)
- Worst case: 0% savings (fully sequential dependencies)

**Error Handling Philosophy** (lines 562-613):
- **Principle**: "One clear execution path, fail fast with full context"
- NO retries: Single execution attempt per operation
- NO fallbacks: If operation fails, report why and exit
- Clear diagnostics: Every error shows exactly what failed and why
- Partial research success: Continue if ≥50% of parallel agents succeed (Phase 1 only)

**Library Dependencies** (lines 616-676):
1. workflow-detection.sh: Workflow scope detection
2. error-handling.sh: Error classification and diagnostics
3. checkpoint-utils.sh: Workflow resume capability
4. unified-logger.sh: Progress tracking
5. unified-location-detection.sh: Topic directory creation
6. metadata-extraction.sh: Context reduction
7. context-pruning.sh: Context optimization
8. dependency-analyzer.sh: Wave-based execution

### 7. Available Library Functions

**Performance-Critical Libraries**:

**7.1 Unified Location Detection** (`.claude/lib/unified-location-detection.sh`)
- Purpose: 85% token reduction, 25x speedup vs agent-based detection
- Functions: get_or_create_topic_dir(), create_topic_artifact()
- Integration: All workflow commands use standardized location detection

**7.2 Complexity Utils** (`.claude/lib/complexity-utils.sh`)
- Purpose: Automated complexity scoring for adaptive planning
- Functions: calculate_complexity_score(), determine_thinking_mode()
- Thresholds: 0-3 standard, 4-6 think, 7-9 think hard, 10+ think harder

**7.3 Checkpoint Utils** (`.claude/lib/checkpoint-utils.sh`)
- Purpose: Workflow resume capability, state management
- Functions: save_checkpoint(), restore_checkpoint(), checkpoint_get_field()
- Schema: V2.0 with state machine as first-class citizen

**7.4 Error Handling** (`.claude/lib/error-handling.sh`)
- Purpose: Error classification and diagnostic message generation
- Functions: classify_error(), suggest_recovery(), detect_error_type()
- Integration: Fail-fast error detection with clear troubleshooting guidance

**7.5 Unified Logger** (`.claude/lib/unified-logger.sh`)
- Purpose: Progress tracking and event logging
- Functions: emit_progress(), log_event()
- Format: PROGRESS: [Phase N] - [action]

### 8. Production Orchestration Commands

**Command Comparison** (from CLAUDE.md lines 1720-1770):

**8.1 /coordinate** (Production-Ready):
- Size: 1,084 lines (54% reduction from 2,334)
- Features: Wave-based parallel execution, fail-fast error handling
- Status: Recommended default for production workflows
- Performance: 40-60% time savings via wave-based implementation

**8.2 /orchestrate** (In Development):
- Size: 557 lines (90% reduction from 5,439)
- Features: Full-featured with PR automation, dashboard tracking
- Status: Experimental features may have inconsistent behavior
- Note: 5,438 total lines (557 executable + 4,882 guide)

**8.3 /supervise** (In Development):
- Size: 1,779 lines (minimal reference being stabilized)
- Features: Sequential orchestration, proven architectural compliance
- Status: Being refined for stability
- Guide: See `.claude/docs/guides/supervise-guide.md`

**Unified Capabilities** (all orchestration commands):
- 7-phase workflow (initialize, research, plan, implement, test, debug, document)
- Parallel research (2-4 agents)
- Automated complexity evaluation
- Conditional debugging (only if tests fail)
- Performance: <30% context usage throughout

## Recommendations

### 1. Use /coordinate for Production Workflows

**Rationale**: /coordinate provides mature wave-based parallel execution with fail-fast error handling, achieving 40-60% time savings while maintaining 100% file creation reliability.

**Implementation**:
- Primary command for research-and-plan workflows (most common use case)
- Proven track record with comprehensive error handling
- Wave-based implementation reduces execution time significantly
- Fail-fast philosophy provides clear diagnostics on failures

**Example**:
```bash
/coordinate "research authentication patterns to create OAuth2 implementation plan"
```

### 2. Leverage State-Based Architecture for Custom Orchestrators

**Rationale**: State machine library provides 48.9% code reduction while improving performance by 67% for state operations.

**Implementation**:
- Source `workflow-state-machine.sh` for state lifecycle management
- Use `sm_init()`, `sm_transition()`, `sm_execute()` pattern
- Define state handlers: `execute_research_phase()`, `execute_plan_phase()`, etc.
- Checkpoint coordination via `sm_save()` and `sm_load()`

**Benefits**:
- Explicit over implicit: Named states replace phase numbers
- Validated transitions: State machine enforces valid state changes
- Centralized logic: Single library owns all state operations
- 50 comprehensive tests ensure reliability

### 3. Apply Selective State Persistence Strategy

**Rationale**: File-based state when justified (67% performance improvement), stateless recalculation otherwise.

**Decision Criteria**:
- **Use file-based state** when:
  - Expensive to recalculate (>30ms)
  - Non-deterministic (user surveys, research findings)
  - Accumulates across subprocess boundaries
  - Phase dependencies require prior phase outputs

- **Use stateless recalculation** when:
  - Fast to recalculate (<10ms)
  - Deterministic (pattern matching, path calculations)
  - Ephemeral (temporary variables)

**Implementation**:
```bash
# Initialize state file (Block 1)
STATE_FILE=$(init_workflow_state "workflow_$$")
trap "rm -f '$STATE_FILE'" EXIT

# Load state (Blocks 2+)
load_workflow_state "workflow_$$"

# Append state
append_workflow_state "RESEARCH_COMPLETE" "true"

# Save JSON checkpoint
save_json_checkpoint "supervisor_metadata" "$METADATA_JSON"
```

### 4. Follow Standard 11 for Agent Delegation

**Rationale**: Achieves >90% agent delegation rate by eliminating documentation-only YAML blocks.

**Required Pattern**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the [agent-name] agent.

Task {
  subagent_type: "general-purpose"
  description: "Research [topic] with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/[agent-name].md

    **Workflow-Specific Context**:
    - Research Topic: [specific topic]
    - Output Path: [absolute path, pre-calculated]

    Return: [COMPLETION_SIGNAL]: [expected path]
  "
}
```

**Avoid Anti-Patterns**:
- No code block wrappers (` ```yaml `)
- No "Example" prefixes
- No documentation context markers
- No undermining disclaimers after imperative instructions

### 5. Implement Hierarchical Context Reduction

**Rationale**: Enables 4+ parallel workers without context overflow, achieving 95.6% context reduction.

**Pattern**:
```
4 Workers (10,000 tokens full output)
    ↓
Supervisor extracts metadata (110 tokens/worker)
    ↓
Orchestrator receives aggregated metadata (440 tokens)
    ↓
95.6% context reduction achieved
```

**Implementation**:
- Use `extract_report_metadata()` for title + 50-word summary extraction
- Apply `prune_subagent_output()` after metadata extraction
- Store metadata in checkpoint via `save_json_checkpoint()`
- Supervisor aggregates metadata before returning to orchestrator

**Libraries**:
- `.claude/lib/metadata-extraction.sh`: Extract metadata from artifacts
- `.claude/lib/context-pruning.sh`: Prune full content after extraction

### 6. Utilize Wave-Based Execution for Time Savings

**Rationale**: Achieves 40-60% time savings through parallel execution of independent phases.

**Implementation**:
1. Add dependency metadata to plan phases:
   ```markdown
   ### Phase 3: Database Schema Migration
   **Dependencies**: depends_on: [phase_1, phase_2]
   ```

2. Invoke dependency analyzer:
   ```bash
   source .claude/lib/dependency-analyzer.sh
   ANALYSIS=$(analyze_dependencies "$PLAN_PATH")
   WAVES=$(echo "$ANALYSIS" | jq -r '.waves')
   ```

3. Execute waves in parallel:
   ```bash
   for wave in $(echo "$WAVES" | jq -c '.[]'); do
     PHASES=$(echo "$wave" | jq -r '.phases[]')
     # Launch all phases in wave simultaneously
     for phase in $PHASES; do
       execute_phase_async "$phase" &
     done
     wait  # Wait for wave completion
   done
   ```

### 7. Adopt Fail-Fast Error Handling

**Rationale**: Clear, immediate failures are better than hidden complexity masking problems.

**Principles**:
- NO retries: Single execution attempt per operation
- NO fallbacks: If operation fails, report why and exit
- Clear diagnostics: Every error shows what failed, why, and troubleshooting steps
- Enhanced error messages: Include diagnostic commands

**Example**:
```bash
if [ ! -f "$EXPECTED_PATH" ]; then
  echo "❌ ERROR: Agent failed to create expected file"
  echo "   Expected: $EXPECTED_PATH"
  echo "   Found: File does not exist"
  echo ""
  echo "DIAGNOSTIC INFORMATION:"
  echo "  - Agent output: $AGENT_OUTPUT"
  echo "  - Working directory: $(pwd)"
  echo ""
  echo "What to check next:"
  echo "  1. Verify agent behavioral file exists"
  echo "  2. Check topic directory permissions"
  echo "  3. Review agent output for error messages"
  exit 1
fi
```

### 8. Use Behavioral Injection for Agent Coordination

**Rationale**: Enables 100% file creation rate through explicit path injection and role separation.

**Pattern**:
```markdown
## Phase 0: Pre-Calculate Artifact Paths

**EXECUTE NOW**: Calculate all paths before invoking agents:

```bash
source .claude/lib/unified-location-detection.sh
TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESC" ".claude/specs")
REPORT_PATH="$TOPIC_DIR/reports/001_research.md"
PLAN_PATH="$TOPIC_DIR/plans/001_implementation.md"
```

## Phase 1: Invoke Agent with Injected Context

**EXECUTE NOW**: USE the Task tool to invoke research-specialist:

Task {
  prompt: "
    Read and follow: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Report Path: $REPORT_PATH (orchestrator controls path)

    Return: REPORT_CREATED: $REPORT_PATH
  "
}
```

### 9. Monitor Performance Metrics

**Key Metrics to Track**:
- **Agent delegation rate**: Target >90%
- **File creation rate**: Target 100%
- **Context usage**: Target <30% throughout workflow
- **Time savings**: Track wave-based vs sequential execution
- **State operation performance**: Monitor CLAUDE_PROJECT_DIR detection time

**Measurement Tools**:
- `.claude/lib/context-metrics.sh`: Track context window usage
- `.claude/lib/dependency-analyzer.sh`: Calculate parallelization metrics
- `.claude/tests/test_orchestration_commands.sh`: Validate delegation rates

### 10. Follow Documentation Separation Pattern

**Rationale**: Eliminates meta-confusion loops (75% → 0% incident rate) through lean executable files.

**Pattern**:
1. **Executable File**: `.claude/commands/command-name.md` (<250 lines simple, <1,200 lines orchestrators)
   - Bash blocks, phase markers, minimal inline comments (WHAT not WHY)
   - Single-line reference to guide file

2. **Command Guide**: `.claude/docs/guides/command-name-command-guide.md` (unlimited length)
   - Architecture, examples, troubleshooting, design decisions
   - Task-focused documentation for human developers

**Benefits**:
- 70% average reduction in executable file size
- Zero meta-confusion incidents post-migration
- Independent documentation growth
- Fail-fast execution

**Templates**:
- Executable: `.claude/docs/guides/_template-executable-command.md`
- Guide: `.claude/docs/guides/_template-command-guide.md`

## References

### Core Libraries
- `.claude/lib/workflow-state-machine.sh` (513 lines): State machine implementation
- `.claude/lib/state-persistence.sh` (341 lines): GitHub Actions-style state persistence
- `.claude/lib/metadata-extraction.sh` (541 lines): Context reduction via metadata extraction
- `.claude/lib/context-pruning.sh` (454 lines): Aggressive context pruning
- `.claude/lib/dependency-analyzer.sh` (639 lines): Wave-based execution and dependency graphs
- `.claude/lib/unified-location-detection.sh`: Topic directory management
- `.claude/lib/checkpoint-utils.sh`: Workflow resume capability
- `.claude/lib/error-handling.sh`: Error classification and diagnostics

### Architecture Documentation
- `.claude/docs/architecture/state-based-orchestration-overview.md` (2,000+ lines): Complete architecture reference
- `.claude/docs/architecture/workflow-state-machine.md`: State machine design and API
- `.claude/docs/architecture/hierarchical-supervisor-coordination.md`: Supervisor patterns
- `.claude/docs/architecture/coordinate-state-management.md`: Subprocess isolation patterns

### Standards and Patterns
- `.claude/docs/reference/command_architecture_standards.md` (2,325 lines):
  - Standard 11: Imperative Agent Invocation Pattern (lines 1173-1353)
  - Standard 12: Structural vs Behavioral Content Separation (lines 1356-1453)
  - Standard 14: Executable/Documentation File Separation (lines 1535-1689)
- `.claude/docs/concepts/patterns/behavioral-injection.md` (1,162 lines): Agent delegation patterns
- `.claude/docs/guides/coordinate-command-guide.md` (1,127 lines): Complete /coordinate usage

### Command Guides
- `.claude/docs/guides/implement-command-guide.md`: /implement usage, adaptive planning
- `.claude/docs/guides/plan-command-guide.md`: /plan usage, research delegation
- `.claude/docs/guides/debug-command-guide.md`: /debug usage, parallel hypothesis testing
- `.claude/docs/guides/test-command-guide.md`: /test usage, multi-framework testing
- `.claude/docs/guides/document-command-guide.md`: /document usage, standards compliance

### Performance Reports
- `.claude/specs/602_601_and_documentation_in_claude_docs_in_order_to/reports/004_performance_validation_report.md`: Performance metrics validation
- `.claude/specs/634_001_coordinate_improvementsmd_implements/reports/001_fail_fast_policy_analysis.md`: Fail-fast policy taxonomy

### Agent Behavioral Files
- `.claude/agents/research-specialist.md` (671 lines): Research agent behavioral guidelines
- `.claude/agents/plan-architect.md`: Planning agent behavioral guidelines
- `.claude/agents/implementation-executor.md`: Implementation agent behavioral guidelines
