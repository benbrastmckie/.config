# Stage 2: Extract Command Documentation

## Metadata
- **Stage Number**: 2
- **Parent Phase**: phase_7_directory_modularization
- **Phase Number**: 7
- **Objective**: Extract documentation from 4 large commands to 13 shared files
- **Complexity**: High
- **Status**: PENDING
- **Estimated Time**: 8-12 hours

## Overview

This stage performs all command documentation extractions, reducing 4 large command files by ~3,000 lines total through creation of 13 shared documentation files. The extractions follow the proven pattern from agents/shared/ which achieved 28% file size reduction.

**File Reductions**:
- orchestrate.md: 2,720 → <1,200 lines (56% reduction, ~1,500 lines extracted)
- implement.md: 987 → <500 lines (49% reduction, ~490 lines extracted)
- setup.md: 911 → <400 lines (56% reduction, ~510 lines extracted)
- revise.md: 878 → <400 lines (54% reduction, ~480 lines extracted)

**Shared Files Created**: 13 total (5 from orchestrate, 3 from implement, 3 from setup, 2 from revise)

The challenge is surgical precision: each section must be extracted with its complete context, then replaced in the source file with a concise summary (50-100 words) and a reference link. This maintains command usability while dramatically reducing file sizes and enabling documentation reuse.

## Detailed Tasks

### Task 1: Extract Workflow Phases Documentation (800 lines)

**Objective**: Extract the detailed 5-phase workflow documentation from orchestrate.md to a dedicated shared file.

**Implementation Steps**:

1. **Locate the workflow phases section** using grep:
```bash
cd /home/benjamin/.config/.claude/commands
grep -n "^### Research Phase\|^### Planning Phase\|^### Implementation Phase\|^### Debugging\|^### Documentation Phase" orchestrate.md
```

Expected output:
```
417:### Research Phase (Parallel Execution)
542:### Planning Phase (Sequential Execution)
658:### Implementation Phase (Adaptive Execution)
871:### Documentation Phase (Sequential Execution)
```

2. **Calculate exact line ranges** for each phase:
```bash
# Research Phase: lines 417-541 (125 lines)
sed -n '417,541p' orchestrate.md | wc -l

# Planning Phase: lines 542-657 (116 lines)
sed -n '542,657p' orchestrate.md | wc -l

# Implementation Phase: lines 658-870 (213 lines)
sed -n '658,870p' orchestrate.md | wc -l

# Documentation Phase: lines 871-1557 (687 lines)
sed -n '871,1557p' orchestrate.md | wc -l

# Total: ~1,141 lines actual (we'll extract ~800 core content)
```

3. **Extract content to new shared file**:
```bash
cat > shared/workflow-phases.md << 'EOF'
# Workflow Phases Documentation

**Part of**: `/orchestrate` command
**Purpose**: Detailed phase-by-phase execution procedures for multi-agent workflow orchestration
**Usage**: Referenced by `/orchestrate` for phase coordination patterns

## Overview

This document contains the complete workflow phase documentation for the `/orchestrate` command. Each phase includes detailed execution procedures, agent invocation patterns, checkpoint management, and error recovery strategies.

## Research Phase (Parallel Execution)

[Copy lines 417-541 from orchestrate.md, removing the heading since it's already here]

## Planning Phase (Sequential Execution)

[Copy lines 542-657 from orchestrate.md]

## Implementation Phase (Adaptive Execution)

[Copy lines 658-870 from orchestrate.md]

## Documentation Phase (Sequential Execution)

[Copy lines 871-1557 from orchestrate.md]

---

*This is a shared documentation file. For the main orchestrate command, see: `orchestrate.md`*
EOF
```

4. **Create concise summary for orchestrate.md**:
Create a 75-word replacement text:
```markdown
### Workflow Phases

The `/orchestrate` command executes 5 distinct phases with specialized coordination patterns:

1. **Research Phase (Parallel)**: 2-4 research-specialist agents investigate patterns, practices, alternatives (5-10 min)
2. **Planning Phase (Sequential)**: plan-architect synthesizes research into structured plan (3-5 min)
3. **Implementation Phase (Adaptive)**: code-writer executes plan with phase-by-phase testing (15-60 min)
4. **Debugging Loop (Conditional)**: debug-specialist investigates failures, max 3 iterations (0-15 min)
5. **Documentation Phase (Sequential)**: doc-writer updates docs and generates workflow summary (3-5 min)

**See detailed phase procedures**: [Workflow Phases](shared/workflow-phases.md)
```

5. **Replace content in orchestrate.md**:
```bash
# Use Edit tool to replace lines 417-1557 with the summary above
# This reduces ~1,141 lines to ~15 lines (1,126 lines saved)
```

6. **Verify extraction**:
```bash
# Check new file exists and has expected content
test -f shared/workflow-phases.md && wc -l shared/workflow-phases.md
# Should show ~800-850 lines

# Check orchestrate.md was updated
grep -A5 "### Workflow Phases" orchestrate.md
# Should show the summary text

# Verify file sizes
wc -l orchestrate.md shared/workflow-phases.md
# orchestrate.md should be ~1,579 lines (2,720 - 1,141)
```

**Expected Result**:
- `shared/workflow-phases.md` created with ~800 lines of detailed phase documentation
- `orchestrate.md` reduced by ~1,126 lines
- Summary with reference link added to orchestrate.md

**Error Handling**:
- If line numbers don't match (file modified), re-run grep to find current line numbers
- If extraction creates broken markdown, verify heading levels are preserved
- If reference link breaks, test with Read tool to verify shared file is accessible

### Task 2: Extract Error Recovery Patterns (400 lines)

**Objective**: Extract error handling, recovery strategies, and debugging patterns to a dedicated shared file.

**Implementation Steps**:

1. **Locate error recovery sections**:
```bash
grep -n "Error Handling Strategy\|Error Recovery\|Recovery Pattern\|Error Classification" orchestrate.md
```

Expected matches around lines 298-328 (Error Handling Strategy section).

2. **Extract error recovery content**:
```bash
# Identify all error-related content blocks
grep -n -B2 -A10 "error\|recovery\|retry\|escalat" orchestrate.md | less
# Review to find complete error handling sections
```

3. **Create shared/error-recovery.md**:
```bash
cat > shared/error-recovery.md << 'EOF'
# Error Recovery Patterns

**Part of**: `/orchestrate`, `/implement` commands
**Purpose**: Standardized error handling, recovery strategies, and escalation patterns
**Usage**: Referenced for automatic retry logic, debugging workflows, and user escalation

## Overview

This document defines the error recovery patterns used across multi-agent workflows. It covers error classification, automatic retry strategies, debugging iteration limits, checkpoint-based recovery, and user escalation formats.

## Error Classification

### Error Types

1. **Transient Errors**:
   - Timeout errors (agent execution exceeds limits)
   - Network errors (API rate limits, connectivity)
   - Resource contention (file locks, busy states)
   - **Recovery**: Automatic retry with exponential backoff

2. **Tool Access Errors**:
   - Permission denied
   - Tool not available
   - Tool invocation failure
   - **Recovery**: Retry with reduced toolset, fallback to alternative tools

3. **Validation Failures**:
   - Output doesn't meet criteria
   - Missing required sections
   - Malformed data structures
   - **Recovery**: Retry with clarified instructions, stricter validation prompts

4. **Integration Errors**:
   - Command invocation failures
   - File path mismatches
   - Report not found
   - **Recovery**: Path correction, automatic file search, retry with absolute paths

5. **Context Overflow**:
   - Orchestrator context approaches limits
   - Agent context too large
   - **Recovery**: Context compression, aggressive summarization, scope reduction

6. **Critical Failures**:
   - Data loss
   - Security issues
   - **Recovery**: Immediate escalation, no automatic retry

## Automatic Retry Strategies

### Exponential Backoff Pattern

Used by `error-utils.sh:retry_with_backoff()`:

```bash
attempt=1
max_attempts=3
base_delay=2

while [ $attempt -le $max_attempts ]; do
  # Try operation
  if operation_succeeds; then
    break
  fi

  # Calculate backoff delay
  delay=$((base_delay ** attempt))
  echo "Retry $attempt/$max_attempts after ${delay}s..."
  sleep $delay

  attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
  escalate_to_user
fi
```

### Retry Limits by Error Type

| Error Type | Max Retries | Backoff | Notes |
|------------|-------------|---------|-------|
| Transient | 3 | Exponential (2s, 4s, 8s) | Extended timeout on retry |
| Tool Access | 2 | Linear (5s, 10s) | Reduced toolset on retry |
| Validation | 2 | Linear (3s, 6s) | Clarified instructions |
| Integration | 3 | Linear (2s, 4s, 6s) | Path correction |
| Context Overflow | 1 | N/A | Compress and retry once |
| Critical | 0 | N/A | Immediate escalation |

## Debugging Iteration Limits

### Three-Iteration Rule

Debugging loops (in `/orchestrate` and `/implement`) are limited to 3 iterations:

**Iteration 1**: Initial debug-specialist analysis → code-writer fix → test
**Iteration 2**: Deeper debug-specialist analysis → code-writer fix → test
**Iteration 3**: Expert-level debug analysis → code-writer fix → test

If tests still fail after 3 iterations, escalate to user with:
- All 3 debug reports (show investigation progression)
- Error pattern summary
- Recommended next steps
- Checkpoint saved for manual intervention

**Rationale**: Prevents infinite loops, forces human judgment on complex issues, preserves context for manual debugging.

### Debugging Checkpoint Structure

```yaml
debugging_checkpoint:
  status: "debugging_iteration_N"
  debug_iteration: N  # 1-3
  debug_topic: "error_category"
  debug_reports: [
    "debug/error_category/001_first_attempt.md",
    "debug/error_category/002_second_attempt.md"
  ]
  tests_passing: false
  failed_phase: N
  error_history: [
    {iteration: 1, error: "...", fix_applied: "..."},
    {iteration: 2, error: "...", fix_applied: "..."}
  ]
  next_action: "retry" # or "escalate" if limit reached
```

## Checkpoint-Based Recovery

### Recovery Workflow

1. **Detect failure** during phase execution
2. **Save checkpoint** with failure context (error message, phase, iteration count)
3. **Classify error** using `error-utils.sh:detect_error_type()`
4. **Determine retry eligibility** based on error type and retry count
5. **Execute recovery strategy** (retry, fallback, or escalate)
6. **Update checkpoint** with recovery attempt
7. **Resume workflow** from checkpoint if recovery succeeds

### Rollback Pattern

```bash
# After failed phase execution
if phase_fails; then
  # Save failure checkpoint
  save_checkpoint "failed" "$PHASE_NUMBER" "$ERROR_CONTEXT"

  # Determine recovery action
  if should_retry "$ERROR_TYPE" "$RETRY_COUNT"; then
    apply_recovery_strategy "$ERROR_TYPE"
    retry_phase "$PHASE_NUMBER"
  elif should_rollback "$ERROR_SEVERITY"; then
    rollback_to_checkpoint "$PREVIOUS_SUCCESSFUL_PHASE"
  else
    escalate_to_user "$FAILURE_REPORT"
  fi
fi
```

## User Escalation Format

### Standard Escalation Message

```markdown
⚠️ Workflow Interrupted - Manual Intervention Required

**Phase**: [phase_name]
**Status**: [failed|blocked|escalated]
**Attempts**: [N retries exhausted]

**Error Summary**:
[Concise description of what went wrong]

**Error Details**:
- Type: [error_type]
- Location: [file:line or phase:task]
- Message: [error message]

**Investigation Reports**:
[If debugging occurred:]
1. [debug_report_1_path] - [brief finding]
2. [debug_report_2_path] - [brief finding]
3. [debug_report_3_path] - [brief finding]

**Checkpoint Saved**: [checkpoint_path]

**Recommended Actions**:
1. [Action 1: most likely solution]
2. [Action 2: alternative approach]
3. [Action 3: if underlying issue suspected]

**Resume Options**:
- `(r)esume`: Fix issue and continue from checkpoint
- `(s)kip`: Skip failed phase and continue (not recommended if tests failing)
- `(a)bort`: Exit workflow gracefully
- `(d)ebug`: Enter manual debugging mode

Your choice [r/s/a/d]:
```

### Escalation Triggers

Automatic escalation occurs when:
1. Max retry limit exceeded (3 attempts)
2. Critical failure detected (data loss, security)
3. Debugging iteration limit reached (3 iterations)
4. Context overflow cannot be resolved
5. User input required (architectural decisions, API keys)

## Error Logging

### Log Format

All errors logged to `.claude/logs/orchestrate.log` (or command-specific log):

```
[2025-10-13 14:32:15] ERROR: [orchestrate] Phase: implementation | Error: timeout | Attempt: 2/3 | Recovery: retry_with_extended_timeout
[2025-10-13 14:35:20] WARNING: [orchestrate] Phase: implementation | Context usage: 85% | Action: compress_summaries
[2025-10-13 14:40:10] ESCALATION: [orchestrate] Phase: debugging | Iteration: 3/3 | Status: tests_still_failing | Action: user_escalation
```

### Utility Integration

Error recovery patterns integrate with shared utilities:

- `error-utils.sh:detect_error_type()`: Classify error from output
- `error-utils.sh:suggest_recovery()`: Generate recovery suggestions
- `error-utils.sh:format_error_report()`: Structure error details
- `error-utils.sh:retry_with_backoff()`: Execute retry with backoff
- `checkpoint-utils.sh:save_checkpoint()`: Persist failure state
- `checkpoint-utils.sh:load_checkpoint()`: Restore for retry
- `adaptive-planning-logger.sh:log_error()`: Record error history

---

*This is a shared documentation file. Referenced by: `orchestrate.md`, `implement.md`, `debug.md`*
EOF
```

4. **Update orchestrate.md with summary**:
```markdown
## Error Handling Strategy

The `/orchestrate` command implements multi-level error recovery with automatic retry, debugging iteration limits, and graceful escalation:

**Error Types**: Transient (3 retries), Tool Access (2 retries), Validation (2 retries), Integration (3 retries), Context Overflow (1 retry), Critical (immediate escalation)

**Debugging Limits**: Max 3 iterations per workflow before user escalation. Each iteration: debug-specialist analysis → code-writer fix → test.

**Recovery Patterns**: Exponential backoff, checkpoint-based rollback, reduced toolset fallback, context compression.

**See detailed error recovery procedures**: [Error Recovery Patterns](shared/error-recovery.md)
```

5. **Verify extraction**:
```bash
wc -l shared/error-recovery.md  # Should be ~400 lines
grep -A3 "Error Handling Strategy" orchestrate.md  # Should show summary
```

**Expected Result**:
- `shared/error-recovery.md` created with ~400 lines
- orchestrate.md Error Handling Strategy section replaced with summary
- Cross-reference link functional

**Error Handling**:
- If error patterns are scattered, consolidate during extraction
- Ensure all retry limits are consistently documented
- Verify checkpoint examples match actual implementation

### Task 3: Extract Context Management Documentation (300 lines)

**Objective**: Extract context optimization strategies, token reduction techniques, and artifact reference patterns.

**Implementation Steps**:

1. **Locate context management content**:
```bash
grep -n "Context Management\|Context Preservation\|Context Reduction\|Token\|Artifact" orchestrate.md
```

2. **Create shared/context-management.md**:
```bash
cat > shared/context-management.md << 'EOF'
# Context Management for Multi-Agent Workflows

**Part of**: `/orchestrate`, `/implement` commands
**Purpose**: Context optimization strategies to maintain orchestrator context <30% usage
**Usage**: Referenced for context reduction techniques, artifact referencing, lazy loading patterns

## Overview

Multi-agent workflows must carefully manage context to avoid token limits while preserving necessary information for coordination. This document defines the context management strategies used across orchestration commands.

## Context Preservation Strategy

### Orchestrator Context (Minimal - <30% usage)

The orchestrator maintains only:

**Workflow State** (~500 tokens):
- Current phase identifier
- Completion status per phase (boolean array)
- Phase transition timestamps
- Next phase to execute

**Checkpoint Data** (~300 tokens):
- Success/failure status per phase
- Retry counts per phase
- Critical error flags
- Resume point identifier

**File Path References** (~200 tokens):
- Research report paths (array of strings, NOT content)
- Implementation plan path (string, NOT content)
- Debug report paths (array of strings, NOT content)
- Modified files list (array of strings, NOT content)

**High-Level Summaries** (~500 tokens max per phase):
- Research findings: 200 words max
- Planning summary: 150 words max
- Implementation status: 100 words max
- Debugging notes: 150 words max

**Error History** (~300 tokens):
- Error type (classified enum)
- Recovery action taken (enum)
- Success/failure of recovery (boolean)
- Iteration count (integer)

**Performance Metrics** (~200 tokens):
- Phase start/end times (timestamps)
- Agent invocation count (integers)
- Files created/modified counts (integers)
- Parallel effectiveness percentage (float)

**Total Orchestrator Context**: ~2,000 tokens (~30% of typical 8K context window)

### Subagent Context (Comprehensive)

Each subagent receives complete context for its task:

**Research-Specialist Agent** (~3,000 tokens):
- Research topic (detailed description)
- Workflow description (full user request)
- Codebase context (relevant file paths)
- Report format requirements
- Success criteria

**Plan-Architect Agent** (~4,000 tokens):
- Research report PATHS (reads files as needed)
- Workflow description
- Standards file path (CLAUDE.md)
- Plan template reference
- Success criteria

**Code-Writer Agent** (~3,500 tokens):
- Plan file PATH (reads file)
- Phase specifications (current phase only)
- Standards file path
- Test requirements
- Commit message format

**Debug-Specialist Agent** (~3,000 tokens):
- Error output (full text)
- Failed phase context
- Implementation plan phase PATH
- Debug report template
- Analysis requirements

**Doc-Writer Agent** (~4,000 tokens):
- Workflow summary data structure
- Artifact paths (research, plan, summary)
- Documentation standards
- Cross-reference requirements
- Template inline in prompt

## Context Reduction Techniques

### Technique 1: File Path References (Not Content)

**Before** (passing content):
```yaml
research_reports:
  - path: "specs/reports/auth_patterns/001_report.md"
    content: |
      # Authentication Patterns Analysis

      ## Executive Summary
      ... (1,500 words = ~2,000 tokens)
```

**After** (passing paths):
```yaml
research_reports:
  - "specs/reports/auth_patterns/001_report.md"  # 50 chars = <1 token
```

**Savings**: 1,999 tokens per report × 3 reports = 5,997 tokens saved

**Implementation**:
- Store only absolute file paths in workflow_state
- Agents use Read tool to access files when needed
- Orchestrator never reads file content into memory

### Technique 2: Aggressive Summarization

**Phase Completion Summary Format**:
```yaml
research_phase:
  status: "complete"
  reports_generated: 3
  topics: ["auth_patterns", "security_practices", "token_strategies"]
  key_findings: "JWT with refresh tokens recommended. bcrypt for passwords. OWASP standards followed."
  # Summary: 100 words max (~130 tokens)
```

**NO LONGER STORED**:
- Full report text (1,500 words × 3 = 4,500 words)
- Detailed findings (500 words per report)
- Code examples from reports (200 words per report)
- Research methodology (100 words per report)

**Savings**: ~6,000 tokens per phase

### Technique 3: Lazy Loading Pattern

Agents receive minimal context upfront, load additional context on-demand:

```yaml
# Agent receives initially
context:
  plan_path: "specs/plans/013_auth.md"
  current_phase: 2
  # NO phase details provided

# Agent's first action
Read tool: "specs/plans/013_auth.md" offset: 150, limit: 50
# Reads only Phase 2 section (~50 lines)

# If agent needs more context
Read tool: "specs/plans/013_auth.md" offset: 1, limit: 20
# Reads plan metadata

# If agent needs research
Read tool: "specs/reports/auth_patterns/001_report.md"
# Agent decides what to read based on task
```

**Benefits**:
- Orchestrator never loads full plan/reports
- Agent loads only sections it needs
- Reduces initial context by 70-80%

### Technique 4: Structured Handoffs

Each phase handoff uses minimal data structure:

```yaml
research_to_planning_handoff:
  research_reports: [array of 2-4 paths]
  thinking_mode: "think hard"
  complexity_score: 9
  project_name: "user_authentication"
  # Total: <100 tokens
```

**NOT passed**:
- Research report content
- Interim analysis
- Codebase snapshots
- Detailed findings

**Result**: Phase transitions use <100 tokens each

### Technique 5: Enum-Based State Tracking

Use enums instead of strings to reduce token usage:

```yaml
# Before (string-based)
workflow_state:
  current_phase: "research_phase_parallel_execution"  # 5 tokens
  status: "in_progress_awaiting_agent_completion"     # 6 tokens

# After (enum-based)
workflow_state:
  current_phase: "research"   # 1 token
  status: "in_progress"       # 2 tokens
```

**Savings**: 8 tokens per state field × 20 fields = 160 tokens

## Artifact Reference Patterns

### Pattern: Path-Only Storage

```yaml
# Workflow state structure
workflow_state:
  artifacts:
    research_reports: [
      "specs/reports/topic1/001_report.md",
      "specs/reports/topic2/001_report.md"
    ]
    plan: "specs/plans/013_feature.md"
    summary: "specs/summaries/013_summary.md"
    debug_reports: [
      "debug/phase2/001_issue.md"
    ]

  # NO content stored, only paths
```

### Pattern: Agent File Reading

Agents read files as needed:

```yaml
# Agent prompt includes
prompt: |
  Your research reports are located at:
  - $REPORT_1_PATH
  - $REPORT_2_PATH

  Use the Read tool to access reports as needed for plan creation.
  Read selectively - only sections relevant to your current task.
```

### Pattern: Cross-Reference Links

Documentation files reference other artifacts:

```markdown
## Research Phase

This workflow incorporated findings from:
- [Authentication Patterns](../../reports/auth_patterns/001_report.md)
- [Security Practices](../../reports/security/001_practices.md)

See implementation plan: [User Authentication Plan](../plans/013_auth.md)
```

**Benefit**: Human-readable, no orchestrator token usage, enables navigation

## Token Budget Allocation

### Orchestrator Budget (8K context window)

| Category | Token Budget | Purpose |
|----------|--------------|---------|
| Workflow State | 500 | Current phase, status flags |
| Checkpoint Data | 300 | Recovery information |
| File Paths | 200 | Artifact references |
| Phase Summaries | 1,500 | 300 tokens × 5 phases |
| Error History | 300 | Recovery tracking |
| Performance Metrics | 200 | Timing, counts |
| **TOTAL USED** | **3,000** | **37.5% of context** |
| Reserved | 5,000 | Agent coordination, prompts |

### Agent Budget (Varies by Model)

| Agent | Context Window | Content Budget | Reserved |
|-------|----------------|----------------|----------|
| research-specialist | 200K | 150K | 50K (tools, prompts) |
| plan-architect | 200K | 150K | 50K (tools, prompts) |
| code-writer | 200K | 150K | 50K (tools, prompts) |
| debug-specialist | 200K | 150K | 50K (tools, prompts) |
| doc-writer | 200K | 150K | 50K (tools, prompts) |

**Note**: Agents have large context windows and can read full files as needed.

## Context Overflow Prevention

### Early Warning System

Monitor orchestrator context usage:

```bash
# Calculate current context usage
CURRENT_TOKENS=$(echo "$WORKFLOW_STATE" | wc -w)
CONTEXT_LIMIT=8000
USAGE_PERCENT=$((CURRENT_TOKENS * 100 / CONTEXT_LIMIT))

if [ $USAGE_PERCENT -gt 70 ]; then
  echo "WARNING: Context usage at ${USAGE_PERCENT}%"
  trigger_context_compression
fi
```

### Compression Strategies

1. **Aggressive summarization**: Reduce phase summaries from 300 to 100 words
2. **Drop old phase data**: Keep only last 2 completed phases in detail
3. **Consolidate error history**: Keep only last 5 errors
4. **Archive to checkpoint**: Move completed phase data to checkpoint file
5. **Reduce workflow scope**: Split into sub-workflows if necessary

### Compression Implementation

```bash
compress_workflow_state() {
  # Reduce phase summaries
  for phase in "${COMPLETED_PHASES[@]}"; do
    SUMMARY=$(get_phase_summary "$phase")
    COMPRESSED=$(echo "$SUMMARY" | head -c 500)  # First 500 chars only
    update_phase_summary "$phase" "$COMPRESSED"
  done

  # Archive old phase data to checkpoint
  ARCHIVED_PHASES=$(list_phases_older_than 2)
  for phase in $ARCHIVED_PHASES; do
    archive_phase_to_checkpoint "$phase"
    remove_phase_from_state "$phase"
  done

  # Truncate error history
  RECENT_ERRORS=$(get_error_history | tail -5)
  update_error_history "$RECENT_ERRORS"
}
```

---

*This is a shared documentation file. Referenced by: `orchestrate.md`, `implement.md`*
EOF
```

3. **Replace in orchestrate.md** with summary:
```markdown
## Context Management Strategy

The `/orchestrate` command maintains minimal orchestrator context (<30% usage) while providing comprehensive context to subagents:

**Orchestrator Context** (~3,000 tokens): Workflow state, checkpoints, file paths (NOT content), 200-word summaries, error history, metrics

**Context Reduction Techniques**:
1. **File Path References**: Store paths, not content (saves ~6,000 tokens per workflow)
2. **Aggressive Summarization**: 200-word max per phase (saves ~6,000 tokens)
3. **Lazy Loading**: Agents read files on-demand (saves ~10,000 tokens)
4. **Structured Handoffs**: <100 tokens per phase transition
5. **Enum-Based State**: Reduces state tracking tokens by 50%

**Context Overflow Prevention**: 70% warning threshold, compression strategies, checkpoint archiving

**See detailed context management procedures**: [Context Management](shared/context-management.md)
```

4. **Verify**:
```bash
wc -l shared/context-management.md  # ~300 lines
grep "Context Management Strategy" -A10 orchestrate.md
```

**Expected Result**: Context management documentation extracted, orchestrate.md summary added.

### Task 4: Extract Agent Coordination Patterns (250 lines)

**Objective**: Extract parallel invocation patterns, sequential execution, state management, and agent behavioral injection documentation.

**Implementation Steps**:

1. **Locate agent coordination content** scattered throughout orchestrate.md:
```bash
grep -n "Agent\|Parallel\|Sequential\|Task tool\|Behavioral\|Invocation" orchestrate.md | head -30
```

2. **Create shared/agent-coordination.md** consolidating patterns:
```bash
cat > shared/agent-coordination.md << 'EOF'
# Agent Coordination Patterns

**Part of**: `/orchestrate`, `/implement`, `/debug` commands
**Purpose**: Standardized agent invocation, parallel execution, and behavioral injection patterns
**Usage**: Referenced for multi-agent coordination and Task tool invocation

## Overview

This document defines the agent coordination patterns used across commands that invoke subagents. It covers parallel vs sequential invocation, behavioral injection, progress monitoring, and result aggregation.

## Parallel Agent Invocation

### When to Use Parallel Execution

**Research Phase**: 2-4 research-specialist agents investigating different topics simultaneously

**Benefits**:
- Time savings: 60-75% faster than sequential (3 agents: 5min parallel vs 15min sequential)
- Independent execution: Agents don't block each other
- Resource utilization: Leverages concurrent API capacity

**Requirements**:
- Tasks must be independent (no shared state)
- No sequential dependencies between agents
- Max 4 concurrent agents (resource limit)

### Parallel Invocation Pattern

**CRITICAL**: All Task tool invocations must be in a SINGLE message.

```yaml
# CORRECT: Single message with multiple Task invocations
Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns using research-specialist protocol"
  prompt: "Read: .claude/agents/research-specialist.md\n\n[task details for topic 1]"
}

Task {
  subagent_type: "general-purpose"
  description: "Research security practices using research-specialist protocol"
  prompt: "Read: .claude/agents/research-specialist.md\n\n[task details for topic 2]"
}

Task {
  subagent_type: "general-purpose"
  description: "Research token strategies using research-specialist protocol"
  prompt: "Read: .claude/agents/research-specialist.md\n\n[task details for topic 3]"
}

# All three agents execute concurrently
# Wait for all to complete before proceeding
```

**INCORRECT** (sequential execution despite intent):
```yaml
# Message 1
Task { ... agent 1 ... }
# Wait for agent 1 to complete

# Message 2
Task { ... agent 2 ... }
# Wait for agent 2 to complete

# Message 3
Task { ... agent 3 ... }
# Result: Sequential execution (3x slower)
```

### Progress Monitoring for Parallel Agents

**Emit progress markers** for each agent:

```
PROGRESS: Starting Research Phase (3 agents, parallel execution)
PROGRESS: [Agent 1/3: auth_patterns] Analyzing codebase for authentication patterns...
PROGRESS: [Agent 2/3: security_practices] Searching 2025 security best practices...
PROGRESS: [Agent 3/3: token_strategies] Comparing JWT vs session-based approaches...

REPORT_CREATED: specs/reports/auth_patterns/001_analysis.md
REPORT_CREATED: specs/reports/security_practices/001_practices.md
REPORT_CREATED: specs/reports/token_strategies/001_strategies.md

PROGRESS: Research Phase complete - 3/3 reports verified (0 retries, 5m 32s)
```

### Result Aggregation

After parallel execution completes:

```bash
# Collect all report paths
RESEARCH_REPORTS=()
for agent_num in 1 2 3; do
  REPORT_PATH=$(extract_report_path_from_agent_output "$agent_num")

  # Verify file exists
  if [ -f "$REPORT_PATH" ]; then
    RESEARCH_REPORTS+=("$REPORT_PATH")
  else
    echo "WARNING: Agent $agent_num report not found at $REPORT_PATH"
    # Trigger recovery (see error-recovery.md)
  fi
done

# Store aggregated results
echo "Research Phase: ${#RESEARCH_REPORTS[@]}/3 reports created"
update_checkpoint "research_complete" "${RESEARCH_REPORTS[@]}"
```

## Sequential Agent Invocation

### When to Use Sequential Execution

**Planning Phase**: Single plan-architect agent synthesizes research
**Implementation Phase**: Single code-writer agent executes plan
**Documentation Phase**: Single doc-writer agent generates summary

**Benefits**:
- Maintains state continuity
- Enables checkpoint-based resume
- Simpler error recovery

### Sequential Invocation Pattern

```yaml
# Phase 1: Planning
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan using plan-architect protocol"
  prompt: |
    Read and follow: .claude/agents/plan-architect.md

    Research reports available:
    - $REPORT_1_PATH
    - $REPORT_2_PATH

    [detailed planning instructions]
}

# Wait for planning to complete, extract plan path, save checkpoint

# Phase 2: Implementation (only after planning succeeds)
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan using code-writer protocol"
  timeout: 600000  # 10 minutes for multi-phase plans
  prompt: |
    Read and follow: .claude/agents/code-writer.md

    Execute plan: $PLAN_PATH

    [implementation instructions]
}
```

## Behavioral Injection Pattern

### Purpose

Agents receive behavioral guidelines through file references rather than inline prompts, enabling:
- Consistent agent behavior across invocations
- Centralized behavior updates
- Tool restriction enforcement
- Role clarity

### Behavioral Injection Structure

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Execute task using [agent-name] protocol"

  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/[agent-name].md

    You are acting as a [Agent Role] with the tools and constraints
    defined in that file.

    ## Task: [Task Name]

    [Task-specific context and requirements]

    ### Context
    [Provide minimal necessary context]

    ### Requirements
    [Explicit success criteria]

    ### Output Format
    [Expected output structure]
}
```

### Available Agent Protocols

Located in `.claude/agents/`:

- `research-specialist.md` - Codebase analysis, best practices research
- `plan-architect.md` - Implementation plan generation
- `code-writer.md` - Code implementation and testing
- `debug-specialist.md` - Root cause analysis and diagnostics
- `doc-writer.md` - Documentation updates and summaries
- `github-specialist.md` - Pull request creation and management

Each protocol defines:
- Agent role and purpose
- Allowed tools (tool restrictions)
- Behavioral guidelines
- Output format requirements
- Success criteria

## State Management Across Agents

### Checkpoint Pattern

**After each major phase**, save checkpoint with aggregated results:

```bash
# After research phase
save_checkpoint "orchestrate" "research_complete" '{
  "research_reports": ["path1", "path2", "path3"],
  "thinking_mode": "think hard",
  "complexity_score": 9,
  "next_phase": "planning"
}'

# After planning phase
save_checkpoint "orchestrate" "planning_complete" '{
  "plan_path": "specs/plans/013_feature.md",
  "plan_number": "013",
  "phase_count": 4,
  "next_phase": "implementation"
}'
```

### Progress Markers

Emit standardized progress markers for state tracking:

```
PROGRESS: [phase_name] - [action_description]

Examples:
PROGRESS: research - Launching 3 parallel agents
PROGRESS: research - Agent 1/3 completed (auth_patterns)
PROGRESS: research - All agents complete, verifying reports
PROGRESS: planning - Synthesizing research into implementation plan
PROGRESS: implementation - Executing Phase 2 of 4
PROGRESS: implementation - Tests passing, creating git commit
PROGRESS: debugging - Iteration 1: Analyzing test failure
PROGRESS: documentation - Generating workflow summary
```

**Benefits**:
- Real-time visibility into workflow progress
- Structured logging for metrics
- Checkpoint granularity for resume
- User feedback during long operations

## Error Handling in Agent Coordination

### Agent Failure Recovery

**Scenario 1: Single agent fails in parallel execution**

```bash
# 3 agents invoked, agent 2 fails
if [ ${#RESEARCH_REPORTS[@]} -eq 2 ]; then
  echo "WARNING: Only 2/3 research agents succeeded"

  # Check if threshold met (50% success)
  if [ ${#RESEARCH_REPORTS[@]} -ge 2 ]; then
    echo "Threshold met (≥50%), proceeding with 2 reports"
    continue_to_planning
  else
    echo "Threshold not met, retrying failed agent"
    retry_single_agent "$FAILED_AGENT_NUM"
  fi
fi
```

**Scenario 2: Sequential agent fails**

```bash
# Planning agent fails
if planning_agent_fails; then
  # Classify error
  ERROR_TYPE=$(detect_error_type "$AGENT_OUTPUT")

  if [ "$ERROR_TYPE" = "timeout" ]; then
    retry_with_extended_timeout
  elif [ "$ERROR_TYPE" = "validation" ]; then
    retry_with_clarified_instructions
  else
    escalate_to_user "Planning agent failed" "$AGENT_OUTPUT"
  fi
fi
```

### Agent Timeout Handling

**Default timeouts** by agent type:

| Agent | Default Timeout | Extended Timeout | Use Case |
|-------|----------------|------------------|----------|
| research-specialist | 120s (2 min) | 300s (5 min) | Complex codebase analysis |
| plan-architect | 120s (2 min) | 180s (3 min) | Large plan generation |
| code-writer | 300s (5 min) | 600s (10 min) | Multi-phase implementation |
| debug-specialist | 180s (3 min) | 300s (5 min) | Deep root cause analysis |
| doc-writer | 120s (2 min) | 180s (3 min) | Extensive documentation |

**Extended timeout usage**:
```yaml
Task {
  subagent_type: "general-purpose"
  timeout: 600000  # 10 minutes in milliseconds
  description: "Execute complex implementation with extended timeout"
  prompt: ...
}
```

---

*This is a shared documentation file. Referenced by: `orchestrate.md`, `implement.md`, `debug.md`*
EOF
```

3. **Replace scattered content in orchestrate.md** with summary:
```markdown
## Agent Coordination

The `/orchestrate` command uses specialized coordination patterns for efficient multi-agent execution:

**Parallel Execution** (Research Phase): 2-4 agents in single message invocation, 60-75% time savings, progress monitoring per agent

**Sequential Execution** (Planning, Implementation, Documentation): Single-agent phases with checkpoint-based state preservation

**Behavioral Injection**: Agents receive role definitions from `.claude/agents/[agent-name].md` files, ensuring consistent behavior and tool restrictions

**State Management**: Checkpoint saves after each phase, aggregated result collection, standardized PROGRESS markers

**See detailed coordination patterns**: [Agent Coordination](shared/agent-coordination.md)
```

**Expected Result**: Agent coordination patterns consolidated in shared file, orchestrate.md updated with summary.

### Task 5: Extract Workflow Examples and Use Cases (200 lines)

**Objective**: Extract the extensive usage examples and workflow scenarios to a dedicated examples file.

**Implementation Steps**:

1. **Locate examples section** (usually near end of file):
```bash
grep -n "^## Usage Examples\|^### Example" orchestrate.md
```

2. **Extract examples** (typically lines 2035-2235):
```bash
sed -n '2035,2235p' orchestrate.md > /tmp/orchestrate_examples.txt
wc -l /tmp/orchestrate_examples.txt  # Verify ~200 lines
```

3. **Create shared/orchestrate-examples.md**:
```bash
cat > shared/orchestrate-examples.md << 'EOF'
# Orchestrate Command Examples

**Part of**: `/orchestrate` command
**Purpose**: Real-world usage examples and workflow scenarios
**Usage**: Referenced for workflow patterns, timing estimates, and artifact examples

## Overview

This document provides concrete examples of `/orchestrate` command usage across different workflow complexities, from simple features to complex implementations with debugging iterations.

[Paste extracted examples from orchestrate.md lines 2035-2235]

---

*This is a shared documentation file. For main orchestrate documentation, see: `orchestrate.md`*
EOF
```

4. **Replace in orchestrate.md**:
```markdown
## Usage Examples

The `/orchestrate` command supports workflows of varying complexity:

**Simple Features** (~5 min): No research, direct planning and implementation
**Medium Features** (~15 min): 2-3 parallel research agents, comprehensive planning
**Complex Features** (~30-45 min): Multiple research topics, adaptive implementation, debugging iterations
**Escalation Scenarios** (~20 min): Debugging limit reached, user intervention required

**Example Workflows**: [Orchestrate Examples](shared/orchestrate-examples.md)
```

**Expected Result**: Examples extracted, orchestrate.md links to dedicated examples file.

### Task 6: Update orchestrate.md and Verify File Sizes

**Objective**: Finalize all extractions, verify target file sizes achieved, test command functionality.

**Implementation Steps**:

1. **Calculate final file sizes**:
```bash
wc -l orchestrate.md shared/*.md

# Expected output:
# 1200 orchestrate.md (target: ~1,200, reduced from 2,720)
#  800 shared/workflow-phases.md
#  400 shared/error-recovery.md
#  300 shared/context-management.md
#  250 shared/agent-coordination.md
#  200 shared/orchestrate-examples.md
# 3150 total
```

2. **Verify reduction**:
```bash
ORIGINAL_SIZE=2720
FINAL_SIZE=$(wc -l < orchestrate.md)
REDUCTION=$((ORIGINAL_SIZE - FINAL_SIZE))
PERCENTAGE=$((REDUCTION * 100 / ORIGINAL_SIZE))

echo "orchestrate.md: $ORIGINAL_SIZE → $FINAL_SIZE lines ($PERCENTAGE% reduction)"
# Expected: "orchestrate.md: 2720 → 1200 lines (56% reduction)"
```

3. **Test reference links**:
```bash
# Verify all reference links in orchestrate.md are valid
grep -o '\[.*\](shared/.*\.md)' orchestrate.md | while read link; do
  FILE=$(echo "$link" | grep -o 'shared/.*\.md')
  if [ ! -f "$FILE" ]; then
    echo "ERROR: Broken link to $FILE"
  else
    echo "OK: $FILE exists"
  fi
done
```

4. **Test command functionality** (basic smoke test):
```bash
# Test that orchestrate.md is still valid markdown
# (Claude will read it and follow reference links automatically)
head -50 orchestrate.md
# Should show metadata, overview, and reference links
```

5. **Update shared/README.md** with extraction results:
```bash
# Update the cross-reference index in shared/README.md
# Add entries for the 5 new files with line counts and referencing commands
```

**Expected Result**:
- orchestrate.md reduced to ~1,200 lines (56% reduction, 1,520 lines saved)
- 5 new shared documentation files created (~1,950 lines total)
- All reference links functional
- Command behavior preserved (reads shared files automatically)

**Error Handling**:
- If file size exceeds target, identify additional sections for extraction
- If tests fail, verify markdown syntax in extracted files
- If links break, check relative path from orchestrate.md to shared/

## Testing Strategy

### Unit Tests

**Test shared file readability**:
```bash
# Verify Claude can read shared files via reference links
cd /home/benjamin/.config/.claude/commands
grep "shared/workflow-phases.md" orchestrate.md
# Confirm link format is correct for Read tool
```

**Test markdown validity**:
```bash
# Check for common markdown errors
for file in shared/*.md; do
  echo "Checking $file..."
  # Look for unclosed code blocks
  grep -c '```' "$file" | awk '{if($1 % 2 != 0) print "ERROR: Unclosed code block in '$file'"}'

  # Look for broken heading levels
  grep '^#' "$file" | awk '{
    level = gsub(/#/, "&")
    if(level > prev_level + 1) print "WARNING: Heading jump in '$file' line " NR
    prev_level = level
  }'
done
```

### Integration Tests

**Test orchestrate command with shared references**:
```bash
# Run orchestrate in dry-run mode to verify it reads shared files correctly
# (dry-run mode should follow reference links when analyzing phases)
/orchestrate "Test workflow" --dry-run
```

**Test cross-command referencing**:
```bash
# Verify implement.md can also reference shared files
grep "shared/error-recovery.md" /home/benjamin/.config/.claude/commands/implement.md
# If implement.md will reference error-recovery.md in future stages
```

### Verification Commands

```bash
# File size targets met
wc -l orchestrate.md | awk '{if($1 > 1300) print "FAIL: orchestrate.md too large"; else print "PASS: orchestrate.md size OK"}'

# All shared files created
for file in workflow-phases.md error-recovery.md context-management.md agent-coordination.md orchestrate-examples.md; do
  [ -f "shared/$file" ] && echo "PASS: $file exists" || echo "FAIL: $file missing"
done

# No broken links
BROKEN_LINKS=$(grep -o 'shared/[^)]*\.md' orchestrate.md | while read f; do [ ! -f "$f" ] && echo "$f"; done)
[ -z "$BROKEN_LINKS" ] && echo "PASS: No broken links" || echo "FAIL: Broken links: $BROKEN_LINKS"
```

## Success Criteria

Stage 2 is complete when:

**From orchestrate.md** (2,720 → <1,200 lines):
- [ ] `shared/workflow-phases.md` created (~400 lines)
- [ ] `shared/error-recovery.md` created (~300 lines)
- [ ] `shared/context-management.md` created (~200 lines)
- [ ] `shared/agent-coordination.md` created (~300 lines)
- [ ] `shared/orchestrate-examples.md` created (~300 lines)

**From setup.md** (911 → <400 lines):
- [ ] `shared/setup-modes.md` created (~300 lines)
- [ ] `shared/bloat-detection.md` created (~150 lines)
- [ ] `shared/extraction-strategies.md` created (~100 lines)

**From revise.md** (878 → <400 lines):
- [ ] `shared/revise-auto-mode.md` created (~250 lines)
- [ ] `shared/revision-types.md` created (~250 lines)

**From implement.md** (987 → <500 lines):
- [ ] `shared/adaptive-planning.md` created (~200 lines)
- [ ] `shared/progressive-structure.md` created (~150 lines)
- [ ] `shared/phase-execution.md` created (~180 lines)

**General**:
- [ ] All 13 shared files created with proper structure
- [ ] All 4 command files reduced to targets
- [ ] Reference links added with 50-100 word summaries
- [ ] No broken markdown (headings, code blocks, links)
- [ ] Command functionality preserved

## Dependencies

### Prerequisites
- Stage 1 complete (shared/ directory and README.md exist, extraction plan created)
- Command files at current baselines: orchestrate (2,720), implement (987), setup (911), revise (878)
- Edit tool functional for file updates

### Enables
- Stage 3 (Utility consolidation can proceed with stable command files)
- Commands can now cross-reference shared documentation
- Future commands can reference shared workflow patterns

## Risk Mitigation

### High Risk Items
- **Broken markdown syntax**: Extract complete sections with all code blocks closed
- **Context loss**: Ensure summaries in orchestrate.md capture key concepts
- **Path mismatches**: Use relative paths consistently (shared/ from commands/ directory)

### Mitigation Strategies
- **Git safety**: Commit after each file extraction (atomic commits)
- **Backup**: Copy orchestrate.md to orchestrate.md.backup before editing
- **Incremental testing**: Test command after each extraction, not at the end
- **Rollback plan**: If extraction breaks command, restore from backup and retry

### Edge Cases
- **Nested sections**: Preserve heading hierarchy when extracting
- **Cross-references within extracted content**: Update internal links if sections split
- **Code examples**: Ensure bash/yaml examples remain properly fenced

## Notes

### Design Decisions

**Why extract in this order?**
Workflow phases first (largest extraction, highest impact), error recovery next (referenced by other sections), context management third (foundational for other optimizations), coordination patterns fourth (references error recovery), examples last (standalone, no dependencies).

**Why 50-100 word summaries?**
Balance between maintaining orchestrate.md usability and achieving size reduction. Users can read summary and decide if they need full details from shared file.

**Why not extract more?**
Target is 56% reduction (~1,200 lines). Over-extraction risks losing orchestrate.md coherence. Remaining content is essential command logic and unique orchestration patterns.

### Efficiency Tips

- Use sed for large block extractions (faster than line-by-line reads)
- Test markdown validity after each extraction (prevents cascading errors)
- Commit after each shared file creation (enables easy rollback)
- Update shared/README.md last (tracks all extractions in one place)

### Future Considerations

After Stage 2 completion, implement.md can reference shared/error-recovery.md and shared/context-management.md, enabling further consolidation in Stage 3.
