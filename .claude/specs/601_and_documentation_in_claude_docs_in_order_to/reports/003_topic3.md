# Research Report: Failure Pattern Analysis for /coordinate and Orchestrator Commands

**Date**: 2025-11-07
**Topic**: Common failure patterns and issues with orchestrator commands (/coordinate, /orchestrate, /supervise)
**Research Specialist**: Claude (Sonnet 4.5)
**Complexity Level**: 4/10

---

## Executive Summary

This report analyzes failure patterns in orchestrator commands based on 13+ refactor attempts (specs 578-598), architectural documentation, troubleshooting guides, and known limitations. The analysis reveals five primary failure categories: **subprocess isolation issues**, **agent delegation failures**, **file creation problems**, **context bloat**, and **coordination complexity**.

**Key Findings**:

1. **Subprocess Isolation** (GitHub #334, #2508): Bash tool creates isolated processes, not persistent sessions. Exports don't persist between bash blocks. 13 refactor attempts before accepting this constraint.

2. **Agent Delegation Failures**: 0% delegation rate from documentation-only YAML blocks (anti-pattern). Fixed by imperative invocation pattern with >90% delegation rate achieved.

3. **File Creation Reliability**: 70% success rate without verification, 100% with mandatory verification checkpoints and fallback mechanisms.

4. **Context Bloat**: Without management, workflows overflow at Phase 2. With metadata extraction and pruning, <30% context usage across 7 phases (92-97% reduction).

5. **Coordination Complexity**: /coordinate: 2,500 lines, /orchestrate: 5,438 lines (experimental), /supervise: 1,779 lines (minimal). Complexity correlates with maintainability issues.

**Critical Pattern**: Most failures result from **fighting tool constraints** (subprocess isolation, agent invocation model) rather than **accepting and designing around them**.

---

## Table of Contents

1. [Subprocess Isolation Issues](#subprocess-isolation-issues)
2. [Agent Delegation Failures](#agent-delegation-failures)
3. [File Creation Problems](#file-creation-problems)
4. [Context Bloat and Token Usage](#context-bloat-and-token-usage)
5. [Coordination Complexity and Maintainability](#coordination-complexity-and-maintainability)
6. [Known GitHub Issues](#known-github-issues)
7. [Failure Pattern Timeline](#failure-pattern-timeline)
8. [Anti-Patterns and Solutions](#anti-patterns-and-solutions)
9. [Recommendations](#recommendations)

---

## 1. Subprocess Isolation Issues

### Overview

The Bash tool creates **separate subprocesses** for each bash block, not subshells or persistent sessions. This is the #1 root cause of /coordinate failures across 13 refactor attempts (specs 582-594).

**GitHub Issues**: #334 (March 2025), #2508 (June 2025) - Confirmed limitation, not a bug.

### Technical Explanation

**What Developers Expect** (per documentation):
```bash
# Block 1
export VAR="value"
export CLAUDE_PROJECT_DIR="/path/to/project"

# Block 2 (same session)
echo "$VAR"  # Should print "value"
```

**What Actually Happens**:
```bash
# Block 1 (subprocess PID 1234)
export VAR="value"
export CLAUDE_PROJECT_DIR="/path/to/project"

# Block 2 (subprocess PID 5678 - DIFFERENT PROCESS)
echo "$VAR"  # Empty! Export didn't persist
echo "$CLAUDE_PROJECT_DIR"  # Empty! Export didn't persist
```

**Why**: Each Bash tool invocation creates a **new process** (not fork/subshell). Separate process spaces = separate environment tables. Exports only persist within same process and child processes. Sequential bash blocks are **sibling processes**, not parent-child.

### Impact on /coordinate

**Affected Variables** (from spec 597-598):
- `CLAUDE_PROJECT_DIR` - Project root path
- `WORKFLOW_SCOPE` - Workflow type (research-only, full-implementation, etc.)
- `PHASES_TO_EXECUTE` - Comma-separated phase list
- `TOPIC_PATH` - Current topic directory
- All library functions sourced via `source` command

**Symptoms**:
```
.claude/lib/workflow-initialization.sh: line 182: PHASES_TO_EXECUTE: unbound variable
ERROR: workflow-initialization.sh not found (CLAUDE_PROJECT_DIR empty)
Topic path mismatch: Agent creates 591, verification checks 592
```

### Historical Evolution (13 Attempts)

**Spec 582-584: Fighting the Constraint** (FAILED)
- **Attempt 1**: Add more export statements → Didn't work
- **Attempt 2**: Use `export -f` for functions → Didn't work
- **Attempt 3**: Try BASH_SOURCE relative paths → Empty in SlashCommand context
- **Lesson**: "Don't fight the tool's execution model"

**Spec 585: Research Phase** (VALIDATION)
- Evaluated file-based state (30ms I/O overhead, 30x slower than recalculation)
- Validated stateless recalculation (<1ms overhead per variable)
- **Recommendation**: Accept duplication, use stateless recalculation

**Spec 597-598: Accepting the Constraint** (SUCCESS)
- Stateless recalculation: Each block independently recalculates all variables
- Accept 50-100 lines of duplicated code
- Performance: <2ms overhead per block, ~12ms total for 6 blocks
- **Result**: 16/16 tests passing, all workflows functional

### Stateless Recalculation Pattern

**Standard Implementation** (appears in 6+ locations in coordinate.md):

```bash
# Standard 13 - CLAUDE_PROJECT_DIR detection for SlashCommand context
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Source library using recalculated path
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

# Recalculate workflow state
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

# Recalculate derived variables
case "$WORKFLOW_SCOPE" in
  research-only)
    PHASES_TO_EXECUTE="0,1"
    ;;
  research-and-plan)
    PHASES_TO_EXECUTE="0,1,2"
    ;;
  full-implementation)
    PHASES_TO_EXECUTE="0,1,2,3,4,6"
    ;;
  debug-only)
    PHASES_TO_EXECUTE="0,1,5"
    ;;
esac
```

**Performance Metrics**:
- CLAUDE_PROJECT_DIR detection: <1ms (git command cached)
- Scope detection: <1ms (string pattern matching)
- PHASES_TO_EXECUTE mapping: <0.1ms (case statement)
- **Total per-block overhead**: ~2ms
- **Total workflow overhead**: ~12ms for 6 blocks

### Large Bash Block Transformation (400-Line Threshold)

**Discovered**: Spec 582 - Claude AI transforms bash code when extracting blocks >400 lines from markdown.

**Symptom**:
```bash
# Source code in coordinate.md:
result="${!var_name}"  # Indirect variable reference

# After transformation (400+ line blocks):
result="${\!var_name}"  # Backslash added → syntax error

# Error:
bash: ${\\!varname}: bad substitution
```

**Root Cause**: Claude's markdown processing pipeline escapes special characters (including `!`) in large bash blocks during extraction. Transformation happens **before** execution, so `set +H` doesn't help.

**Solution** (Spec 582):
- Split 403-line block → 3 blocks (176, 168, 77 lines)
- Keep blocks <300 lines (100-line safety margin)
- **Trade-off**: More blocks = more state passing issues
- **Consequence**: Exposed export persistence limitation (led to specs 583-598)

### Decision Matrix for State Management

From coordinate-state-management.md:

```
START
  │
  ├─ Is computation cost >1 second?
  │    YES → File-based State (Pattern 3)
  │    NO  ↓
  │
  ├─ Is workflow multi-phase with pause/resume?
  │    YES → Checkpoint Files (Pattern 2)
  │    NO  ↓
  │
  ├─ Is command <300 lines total with no subagents?
  │    YES → Single Large Block (Pattern 4)
  │    NO  ↓
  │
  └─ Use Stateless Recalculation (Pattern 1) ← /coordinate uses this
```

**Pattern Comparison**:

| Pattern | Performance | Complexity | Failure Modes | Status |
|---------|-------------|------------|---------------|---------|
| Export persistence | N/A (doesn't work) | Low | Subprocess isolation | Rejected |
| File-based state | 30ms overhead | High | I/O, permissions, cleanup | Rejected |
| Single large block | 0ms (no subprocess) | Medium | Code transformation >400 lines | Limited use |
| **Stateless recalc** | **<1ms** | **Low** | **None** | **✓ ACCEPTED** |

---

## 2. Agent Delegation Failures

### Overview

0% delegation rate when commands use documentation-only YAML blocks (anti-pattern). Fixed by imperative invocation pattern achieving >90% delegation rate.

### Root Cause: Documentation-Only YAML Blocks

**Anti-Pattern** (causes 0% delegation):
```markdown
Research phase invokes agents:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC}"
  prompt: "..."
}
```
```

**Why It Fails**: YAML block wrapped in code fence appears as documentation, not executable instruction. Template variables like `${TOPIC}` never evaluated. Agent never invoked.

**Symptoms**:
- No PROGRESS: markers visible during execution
- No reports created in `.claude/specs/NNN_topic/`
- Output written to `TODO1.md` or `TODO2.md` files
- Command appears to complete but no agent output

### Correct Pattern: Imperative Invocation

**Working Pattern** (achieves >90% delegation):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-specialist agent.

- subagent_type: "general-purpose"
- description: "Research authentication patterns for REST APIs"
- prompt: |
    Read and follow: .claude/agents/research-specialist.md

    Research topic: Authentication patterns for REST APIs
    Output file: [insert $report_path from previous step]

    Return: REPORT_CREATED: $report_path
```

**Key Differences**:
1. `**EXECUTE NOW**: USE the Task tool` - Imperative directive
2. Bullet-point format (not YAML block wrapped in code fence)
3. Concrete examples (not template variables)
4. Completion signal: `Return: REPORT_CREATED: $path`
5. No disclaimers after imperative directive

### Path Pre-Calculation Requirement

**Problem**: Template variables not substituted in agent prompts.

**Solution**: Pre-calculate all paths before agent invocation:

```bash
**EXECUTE NOW**: USE the Bash tool to calculate paths:

```bash
topic_dir=$(create_topic_structure "authentication")
report_path="$topic_dir/reports/001_oauth_patterns.md"
echo "REPORT_PATH: $report_path"
```

**EXECUTE NOW**: USE the Task tool with calculated path:

- description: "Research OAuth patterns with mandatory artifact creation"
- prompt: |
    Output file: [insert $report_path from above]
    # ^^^ Insert actual calculated path, not template variable
```

### Undermining Disclaimers (Anti-Pattern)

**Problem**: Disclaimers after imperative directives reduce delegation rate to 0%.

**Anti-Pattern**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME}"
  prompt: "..."
}

**Note**: The actual implementation will generate N Task calls based on complexity.
```

**Why It Fails**: Disclaimer ("Note: actual implementation will generate...") signals that the Task invocation above is an **example**, not a real instruction. AI interprets as documentation.

**Correct Pattern** (no disclaimers):
```markdown
**EXECUTE NOW**: USE the Task tool for each research topic (1 to $RESEARCH_COMPLEXITY) with these parameters:

- subagent_type: "general-purpose"
- description: "Research [insert topic name] with mandatory artifact creation"
- prompt: |
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [insert display-friendly topic name]
    - Report Path: [insert absolute path from REPORT_PATHS array]

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [EXACT_ABSOLUTE_PATH]
```

### Validation Tools

**Detect Anti-Patterns**:
```bash
# Validate command against Standard 11 (Imperative Agent Invocation)
./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md

# Expected output if compliant:
# ✓ No anti-patterns detected
# ✓ All agent invocations use imperative pattern
# ✓ No template variables in prompts

# Run delegation rate test
./.claude/tests/test_orchestration_commands.sh
```

**Troubleshooting**:
```bash
# Check for YAML blocks in command file
grep -n '```yaml' .claude/commands/command-name.md

# Check for TODO files (indicates delegation failure)
ls -la .claude/TODO*.md

# Check for PROGRESS markers (indicates successful delegation)
/command-name "test" 2>&1 | grep "PROGRESS:"
```

### Reliability Metrics

**Without Verification** (from orchestration-troubleshooting.md):
- Agent delegation rate: Variable (0-90%)
- File creation reliability: 70%

**With Verification** (from verification-fallback pattern):
- Agent delegation rate: >90% (all orchestration commands verified)
- File creation reliability: 100% (mandatory verification checkpoints)
- Bootstrap reliability: 100% (fail-fast exposes configuration errors)

---

## 3. File Creation Problems

### Overview

Agents fail to create files in correct locations 30% of the time without verification. Mandatory verification pattern achieves 100% reliability.

### Common Failure Modes

**1. Files Created in Wrong Location**:
```bash
# Expected: .claude/specs/042_topic/reports/001_report.md
# Actual: .claude/TODO1.md

# Root cause: Paths not pre-calculated and injected into agent prompts
```

**2. Files Not Created At All**:
```bash
# Agent returns success: "REPORT_CREATED: /path/to/report.md"
# File check: ls -la /path/to/report.md → No such file or directory

# Root cause: Write tool transient failure not detected
```

**3. Directory Structure Missing**:
```bash
# Agent fails: cannot create file, parent directory doesn't exist
# Expected: .claude/specs/NNN_topic/{reports,plans,summaries,debug}

# Root cause: Agents not creating directory structure as expected
```

### Mandatory Verification Pattern

**Implementation** (from verification-fallback.md):

```markdown
**MANDATORY VERIFICATION - File Creation** (REQUIRED AFTER AGENT EXECUTION):

**EXECUTE NOW** (DO NOT SKIP):

1. Verify file exists:
   ```bash
   ls -la "$report_path"
   [ -f "$report_path" ] || echo "ERROR: File missing at $report_path"
   ```

2. Verify file size > 500 bytes:
   ```bash
   file_size=$(wc -c < "$report_path")
   [ "$file_size" -ge 500 ] || echo "WARNING: File too small ($file_size bytes)"
   ```

3. Results:
   - IF VERIFICATION PASSES: ✓ Proceed to next phase
   - IF VERIFICATION FAILS: ⚡ Execute FALLBACK MECHANISM

**FALLBACK MECHANISM** (IF VERIFICATION FAILED):

1. Extract content from agent response
2. Create file using Write tool directly
3. Re-verify:
   ```bash
   ls -la "$report_path"
   [ -f "$report_path" ] || { echo "CRITICAL: Fallback failed"; exit 1; }
   ```
```

**Performance Impact**:
- Without verification: 70% file creation reliability
- With verification: 100% file creation reliability
- Time cost: +2-3 seconds per file creation
- **Trade-off**: 3 seconds for 30% reliability improvement is worthwhile

### Pre-Create Directory Structure

**Option 1**: Pre-create before agent invocation:
```bash
**EXECUTE NOW**: Create topic directory structure:

```bash
source .claude/lib/unified-location-detection.sh
topic_dir=$(create_topic_structure "feature_name")
echo "TOPIC_DIR: $topic_dir"

# Verify structure
ls -la "$topic_dir"
```
```

**Option 2**: Verify after agent execution, fail-fast if missing:
```bash
**MANDATORY VERIFICATION**: After agent execution, verify directories:

```bash
if [ ! -d "$topic_dir/reports" ]; then
  echo "ERROR: Agent failed to create reports directory"
  echo "EXPECTED: $topic_dir/reports"
  echo "DIAGNOSTIC: ls -la $topic_dir"
  exit 1
fi
```
```

**DO NOT** manually create directories after agent failure (masks delegation problem).

### Diagnostic Procedures

**Check where files were created**:
```bash
# Check recent files (last 10 minutes)
find . -name "*.md" -mmin -10 -ls

# Check for TODO files (delegation failure indicator)
ls -la .claude/TODO*.md

# Check specs directory
ls -la .claude/specs/*/reports/
```

**Check if agent was invoked**:
```bash
# Look for PROGRESS markers
grep "PROGRESS:" [command output]

# Look for completion signals
grep "REPORT_CREATED:" [command output]

# Verify file existence
ls -la [expected path]
```

---

## 4. Context Bloat and Token Usage

### Overview

Without context management, multi-agent workflows overflow at Phase 2 (34,000 tokens = 136% of 25,000 baseline). With management, complete 7-phase workflows at <30% context usage (5,250 tokens = 21%).

### The Context Budget Problem

**Naive Approach** (without management):
```
Phase 0 (Location Detection):
  Agent output: 2,000 tokens
  Retained: 2,000 tokens

Phase 1 (Research - 3 agents):
  Agent 1 output: 5,000 tokens (full OAuth report)
  Agent 2 output: 5,000 tokens (full JWT report)
  Agent 3 output: 4,500 tokens (full security report)
  Retained: 14,500 tokens

Cumulative after Phase 1: 16,500 tokens (66% of budget)

Phase 2 (Planning):
  Plan creation: 3,000 tokens
  Research context passed: 14,500 tokens (full reports)
  Retained: 17,500 tokens

Cumulative after Phase 2: 34,000 tokens (136%) → OVERFLOW ✗
```

**Result**: Workflow cannot proceed beyond Phase 2.

### Layered Context Architecture

**Managed Approach** (with context management):

**Layer 1: Permanent Context** (500-1,000 tokens, 4%)
- Command prompt skeleton (200 tokens)
- Project standards metadata (150 tokens)
- Workflow scope and description (100 tokens)
- Library function registry (150 tokens)
- **Retention**: Keep throughout entire workflow

**Layer 2: Phase-Scoped Context** (2,000-4,000 tokens, 12%)
- Current phase execution state (500 tokens)
- Wave tracking for parallel execution (300 tokens per wave)
- Active artifact paths (200 tokens)
- Current phase instructions (1,000-2,000 tokens)
- **Retention**: Prune when phase completes or wave finishes

**Layer 3: Metadata** (200-300 tokens per artifact, 6% total)
- Report metadata (title, 50-word summary, key findings)
- Plan metadata (complexity score, phase count, time estimate)
- Implementation metadata (files changed, tests status)
- **Retention**: Keep only metadata, prune full content immediately

**Layer 4: Transient** (0 tokens after pruning)
- Full agent responses (5,000-10,000 tokens per agent) - PRUNED
- Intermediate calculations (1,000-2,000 tokens) - PRUNED
- Verbose diagnostic logs (500-1,000 tokens) - PRUNED
- **Retention**: Prune immediately after extracting metadata

### Metadata Extraction (92-97% Reduction)

**Example** (from metadata-extraction.md):

```bash
# Full report context (before extraction)
FULL_REPORT=$(cat specs/027_auth/reports/027_research.md)
FULL_TOKENS=5000  # 20,000 bytes / 4

# Metadata-only context (after extraction)
METADATA=$(extract_report_metadata specs/027_auth/reports/027_research.md)
# Returns: {
#   "title": "OAuth 2.0 Authentication Patterns",
#   "summary": "50-word summary...",
#   "key_findings": ["finding 1", "finding 2", "finding 3"],
#   "file_path": "/absolute/path/to/report.md"
# }
METADATA_TOKENS=150  # ~600 bytes / 4

# Reduction
REDUCTION=$((100 - (150 * 100 / 5000)))  # 97%
```

**Multi-Report Context**:
```
4 research reports × 5,000 tokens = 20,000 tokens (full)
4 research reports × 150 tokens = 600 tokens (metadata)
Reduction: 97% (20,000 → 600)
```

### Pruning Policies

**Aggressive Pruning** (orchestration commands):
- Prune full agent responses immediately after metadata extraction
- Prune completed wave context before starting next wave
- Prune phase-scoped context when phase completes
- **Token Savings**: 95-97% per artifact

**Moderate Pruning** (linear workflows):
- Keep full agent responses until phase completes
- Prune full content when next phase starts
- Retain metadata + phase summary (500-800 tokens)
- **Token Savings**: 85-90% per artifact

**Minimal Pruning** (debugging workflows):
- Keep full agent responses throughout workflow
- Only prune after workflow completion
- Retain all diagnostic logs
- **Token Savings**: 20-30% (minimal pruning)

### Context Usage Throughout Workflow

**Managed Workflow** (with pruning):

```
Phase 0 (Location Detection):
  Agent output: 2,000 tokens
  Metadata extracted: 500 tokens
  Pruned: 1,500 tokens ✂️
  Retained: 500 tokens ✓

Phase 1 (Research - 3 agents):
  Agent 1 full: 5,000 tokens → metadata: 250 tokens ✂️
  Agent 2 full: 5,000 tokens → metadata: 250 tokens ✂️
  Agent 3 full: 4,500 tokens → metadata: 250 tokens ✂️
  Pruned: 13,750 tokens ✂️
  Retained: 750 tokens ✓
  Cumulative: 1,250 tokens (5% of budget)

Phase 2 (Planning):
  Plan creation: 3,000 tokens
  Research metadata passed: 750 tokens (NOT full reports)
  Plan metadata extracted: 800 tokens
  Pruned: 2,200 tokens ✂️
  Retained: 800 tokens ✓
  Cumulative: 2,050 tokens (8.2% of budget)

Phases 3-7: Continue pattern...

Final cumulative: 5,250 tokens (21% of budget) ✓✓
```

### Performance Metrics

**Context Reduction** (from performance-optimization.md):

| Workflow | Without Management | With Management | Reduction |
|----------|-------------------|-----------------|-----------|
| 4-agent research | 20,000 tokens (80%) | 1,000 tokens (4%) | 95% |
| 7-phase /orchestrate | 40,000 tokens (160% overflow) | 7,000 tokens (28%) | 82% |
| Hierarchical (3 levels) | 60,000 tokens (240% overflow) | 4,000 tokens (16%) | 93% |

**Scalability Improvements**:
- Phases supported: 2-3 → 7-10
- Agents coordinated: 2-4 → 10-30
- Workflow completion rate: 40% → 100% (no context overflows)

---

## 5. Coordination Complexity and Maintainability

### Overview

Orchestrator command complexity correlates with maintainability issues. /coordinate (2,500 lines) is production-ready, /orchestrate (5,438 lines) has experimental features with inconsistent behavior, /supervise (1,779 lines) is minimal reference being stabilized.

### Command Comparison

| Command | Lines | Status | Features | Maturity |
|---------|-------|--------|----------|----------|
| /coordinate | 2,500-3,000 | **Production** | Wave-based parallel, fail-fast | Stable |
| /orchestrate | 5,438 | **Experimental** | Full-featured, PR automation, dashboard | Inconsistent |
| /supervise | 1,779 | **In Development** | Sequential, proven architecture | Stabilizing |

**Recommendation**: Use /coordinate for production workflows.

### Complexity Factors

**1. State Management** (from coordinate-state-management.md):
- Number of bash blocks: More blocks = more state passing issues
- Variables to track: CLAUDE_PROJECT_DIR, WORKFLOW_SCOPE, PHASES_TO_EXECUTE, TOPIC_PATH
- Recalculation frequency: 6+ locations in coordinate.md
- **Anti-Pattern**: Fighting subprocess isolation with exports
- **Pattern**: Stateless recalculation in each block

**2. Agent Coordination**:
- Number of agent invocation sites: 3-5 per command
- Path pre-calculation logic: 50-100 lines per phase
- Verification checkpoints: 5-10 per workflow
- **Anti-Pattern**: Documentation-only YAML blocks
- **Pattern**: Imperative invocation with verification

**3. Error Handling**:
- Bootstrap failures: Library sourcing, function verification, SCRIPT_DIR validation
- Agent delegation issues: 0% delegation rate detection
- File creation problems: Mandatory verification with fallback
- **Anti-Pattern**: Silent fallbacks hiding errors
- **Pattern**: Fail-fast with diagnostic commands

**4. Context Management**:
- Metadata extraction: Extract after each agent
- Pruning policies: Aggressive (orchestration), moderate (linear), minimal (debugging)
- Layered architecture: Permanent, phase-scoped, metadata, transient
- **Anti-Pattern**: Retaining full content, excessive re-summarization
- **Pattern**: Metadata-only passing, forward message pattern

### Maintainability Issues

**Issue 1: Code Duplication** (from spec 597-598)
- 50-100 lines duplicated across 6+ bash blocks
- CLAUDE_PROJECT_DIR detection: 6 locations
- WORKFLOW_SCOPE calculation: 3 locations
- PHASES_TO_EXECUTE mapping: 3 locations
- **Trade-off**: Duplication vs. complexity (duplication is simpler)

**Issue 2: Synchronization Risk**
- Changes to scope detection must be synchronized across blocks
- Missing synchronization: Unbound variable errors, wrong phase lists
- **Mitigation**: Synchronization tests (Phase 3 of refactor plan)

**Issue 3: 400-Line Block Threshold**
- Large blocks (>400 lines) trigger code transformation
- Transformation breaks `${!var}` indirect references
- **Solution**: Split blocks <300 lines (safety margin)
- **Trade-off**: More blocks = more state passing issues

### Reduction Strategies

**1. Library Extraction** (implemented in spec 600 Phase 1):
- Move scope detection logic to `.claude/lib/workflow-scope-detection.sh`
- Eliminates 48-line duplication (24 lines × 2 blocks)
- Single source of truth for scope detection
- Still requires library sourcing in each block (subprocess isolation)

**2. Block Consolidation** (spec 581):
- Merge Phase 0 blocks 1-3 into single block
- Saved 250-400ms (eliminated 2 subprocess boundaries)
- Reduced blocks from 3 → 1 = eliminated 2 state passing points
- **Limit**: 400-line threshold prevents excessive consolidation

**3. Standardize Initialization** (recommendation from spec 593):
- Create `init_bash_block()` library function
- Reduces boilerplate by 400-800 lines
- Easier maintenance (single function vs. 6+ copies)
- **Trade-off**: Still requires sourcing in each block

---

## 6. Known GitHub Issues

### Issue #334: Environment Variables Not Persisting (March 2025)

**Title**: "Environment Variables and Shell Functions Not Persisting"

**Description**: When sourcing scripts that set environment variables or define shell functions in Claude Code's Bash tool, these changes don't persist between command invocations.

**Status**: Known limitation, not fixed as of 2025-11-07

**Impact**: All /coordinate refactors (specs 582-594) hit this limitation.

**Workaround**: Stateless recalculation pattern (spec 597-598).

### Issue #2508: Documentation Inconsistency (June 2025)

**Title**: "[DOCS] Environment variables don't persist between bash commands - documentation inconsistency"

**Description**: Documentation claims Bash tool maintains "persistent shell session", but exports don't actually persist between invocations.

**Status**: Documentation bug, behavior is intentional (subprocess isolation for security).

**Impact**: Developer expectations misaligned with actual behavior.

**Fix**: Update documentation to reflect subprocess model, not persistent session model.

---

## 7. Failure Pattern Timeline

### Historical Evolution

**Spec 578 (Nov 4, 2025)**: Foundation
- **Problem**: `${BASH_SOURCE[0]}` undefined in SlashCommand context
- **Solution**: Replace with `CLAUDE_PROJECT_DIR` detection
- **Status**: Complete (8-line fix, 1.5 hours)
- **Impact**: Established Standard 13 as foundation

**Spec 581 (Nov 4, 2025)**: Performance Optimization
- **Problem**: Redundant library sourcing
- **Solution**: Consolidate bash blocks, conditional library loading
- **Status**: Complete (4 hours)
- **Innovation**: Merged 3 Phase 0 blocks → 1 block (saved 250-400ms)
- **Unintended Consequence**: Created 403-line single block (exceeded transformation threshold)

**Spec 582 (Nov 4, 2025)**: Code Transformation Discovery
- **Problem**: Bash code transformation in large (403-line) blocks
- **Solution**: Split large block → 3 smaller blocks
- **Status**: Complete (1-2 hours)
- **Critical Discovery**: 400-line threshold for Claude AI transformation
- **Unintended Consequence**: Splitting blocks exposed export persistence limitation

**Spec 583 (Nov 4, 2025)**: BASH_SOURCE Limitation
- **Problem**: BASH_SOURCE empty after block split
- **Solution**: Use CLAUDE_PROJECT_DIR from Block 1
- **Status**: Complete (10 minutes)
- **Assumption**: Exports from Block 1 persist to Block 2 (INCORRECT)
- **Actual Result**: Exposed deeper issue - exports don't persist

**Spec 584 (Nov 4, 2025)**: Export Persistence Failure
- **Problem**: Exports from Block 1 don't reach Block 2-3
- **Status**: Complete (confirmed limitation, no workaround)
- **Root Cause**: Bash tool subprocess isolation (GitHub #334, #2508)
- **Impact**: Forced acceptance of subprocess isolation as architectural constraint

**Spec 585 (Nov 4, 2025)**: Pattern Validation
- **Problem**: Evaluate state management alternatives
- **Research**: File-based state (30x slower), single large block (transformation risk), stateless recalculation (<1ms overhead)
- **Recommendation**: Use stateless recalculation for /coordinate
- **Impact**: Validated stateless recalculation as correct approach

**Specs 586-594 (Nov 4-5, 2025)**: Incremental Refinements
- **Activities**: Library organization, error handling improvements, documentation
- **Contribution**: Refined understanding of subprocess isolation, Standard 13 application

**Spec 597 (Nov 5, 2025)**: Stateless Recalculation Breakthrough
- **Problem**: Unbound variable errors in Block 3
- **Solution**: Apply stateless recalculation pattern
- **Status**: Complete (~15 minutes)
- **Test Results**: 16/16 tests passing
- **Performance**: <1ms overhead per recalculation
- **Impact**: First successful implementation of stateless recalculation

**Spec 598 (Nov 5, 2025)**: Extend to Derived Variables
- **Problem**: PHASES_TO_EXECUTE not recalculated
- **Solution**: Extend stateless recalculation to all derived variables
- **Status**: Complete (30-45 minutes)
- **Issues Fixed**: 3 critical issues (library sourcing, PHASES_TO_EXECUTE, phase list)
- **Impact**: Completed stateless recalculation pattern

**Spec 599 (Nov 5, 2025)**: Comprehensive Refactor Analysis
- **Problem**: Identify remaining improvement opportunities
- **Analysis**: 7 potential refactor phases identified
- **Impact**: Identified high-value improvements while accepting core stateless pattern

**Spec 600 (Nov 5-6, 2025)**: High-Value Refactoring
- **Problem**: Execute highest-value improvements from spec 599
- **Phases**: Extract scope detection to library, add synchronization tests, document architecture
- **Status**: Phase 4 in progress (architecture documentation)
- **Impact**: Reduces duplication while maintaining stateless recalculation foundation

### Summary Timeline

```
Spec 578 (Nov 4) → Standard 13 foundation
         ↓
Spec 581 (Nov 4) → Block consolidation (exposed issues)
         ↓
Spec 582 (Nov 4) → 400-line transformation discovery
         ↓
Spec 583 (Nov 4) → BASH_SOURCE limitation
         ↓
Spec 584 (Nov 4) → Export persistence failure (root cause)
         ↓
Spec 585 (Nov 4) → Pattern validation (stateless recommended)
         ↓
Specs 586-594    → Incremental refinements
         ↓
Spec 597 (Nov 5) → ✅ Stateless recalculation success
         ↓
Spec 598 (Nov 5) → ✅ Pattern completion (derived variables)
         ↓
Spec 599 (Nov 5) → Refactor opportunity analysis
         ↓
Spec 600 (Nov 6) → High-value improvements (current)
```

### Key Lessons

1. **Tool Constraints Are Architectural**: Don't fight subprocess isolation, design around it
2. **Fail-Fast Over Complexity**: Immediate errors better than hidden bugs
3. **Performance Measurement**: 1ms recalculation vs 30ms file I/O (30x difference)
4. **Code Duplication Can Be Correct**: 50 lines duplication < file I/O complexity
5. **Validation Through Testing**: 16 tests prove pattern works in production
6. **Incremental Discovery**: 13 attempts over time led to correct solution

---

## 8. Anti-Patterns and Solutions

### Anti-Pattern 1: Fighting Tool Constraints

**Problem**: Attempting to make exports persist between bash blocks through increasingly complex workarounds.

**Attempts** (specs 582-584):
- More export statements → Didn't work
- Different export syntax → Didn't work
- `export -f` for functions → Didn't work
- File-based state passing → Too complex (30ms overhead)

**Solution**: Accept subprocess isolation, use stateless recalculation.

**Example**:
```bash
# Anti-Pattern: Fighting the tool
export WORKFLOW_SCOPE="full-implementation"
# Block 2: expect $WORKFLOW_SCOPE available (FAILS)

# Correct Pattern: Work with the tool
# Block 1: Calculate
WORKFLOW_SCOPE="full-implementation"

# Block 2: Recalculate
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
```

### Anti-Pattern 2: Documentation-Only YAML Blocks

**Problem**: Agent invocations wrapped in code fences appear as documentation, not executable instructions.

**Example**:
```markdown
Research phase invokes agents:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC}"
}
```
```

**Solution**: Use imperative invocation pattern with bullet points.

**Correct Pattern**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-specialist agent.

- subagent_type: "general-purpose"
- description: "Research authentication patterns"
- prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Output file: [insert $report_path from previous step]
    Return: REPORT_CREATED: $report_path
```

### Anti-Pattern 3: No File Creation Verification

**Problem**: Write tool transient failures not detected, 30% file creation failure rate.

**Solution**: Mandatory verification with fallback mechanism.

**Example**:
```bash
# Anti-Pattern: Assume file created
# Agent returns REPORT_CREATED
# Continue to next phase (file may not exist!)

# Correct Pattern: Verify and fallback
ls -la "$report_path"
[ -f "$report_path" ] || {
  echo "ERROR: File missing, executing fallback"
  # Extract content from agent response
  # Create file using Write tool directly
}
```

### Anti-Pattern 4: Retaining Full Content

**Problem**: Full agent responses retained in context, causing overflow at Phase 2.

**Solution**: Metadata extraction with aggressive pruning.

**Example**:
```bash
# Anti-Pattern: Retain full report
FULL_REPORT=$(cat report.md)  # 5,000 tokens
# Pass full report to next phase
# Context: 20,000 tokens after 4 reports → OVERFLOW

# Correct Pattern: Extract metadata
METADATA=$(extract_report_metadata report.md)  # 150 tokens
# Pass metadata to next phase
# Context: 600 tokens after 4 reports ✓
```

### Anti-Pattern 5: Excessive Re-Summarization

**Problem**: Re-summarizing metadata adds 500 tokens per summarization without benefit.

**Solution**: Forward message pattern (0 additional tokens).

**Example**:
```markdown
❌ BAD - Re-summarization:
Based on the research findings, the key points are...
[500 tokens paraphrasing metadata unnecessarily]

✓ GOOD - Direct forwarding:
FORWARDING RESEARCH RESULTS:
{metadata from agent}

Proceeding to planning phase.
```

### Anti-Pattern 6: Silent Fallbacks

**Problem**: Bootstrap failures hidden by fallback mechanisms, masks configuration errors.

**Solution**: Fail-fast with diagnostic commands.

**Example**:
```bash
# Anti-Pattern: Silent fallback
if ! source .claude/lib/library.sh; then
  # Fallback: define function inline
  function_name() { echo "default"; }
fi

# Correct Pattern: Fail-fast
if ! source .claude/lib/library.sh; then
  echo "ERROR: Failed to source library.sh"
  echo "EXPECTED PATH: $SCRIPT_DIR/.claude/lib/library.sh"
  echo "DIAGNOSTIC: ls -la $SCRIPT_DIR/.claude/lib/library.sh"
  echo "ACTION: Verify library file exists and is readable"
  exit 1
fi
```

---

## 9. Recommendations

### For /coordinate Command

**1. Accept Stateless Recalculation** (COMPLETED - spec 597-598)
- Each bash block independently recalculates all variables
- Accept 50-100 lines of duplicated code
- Performance: <2ms overhead per block
- **Status**: Implemented and validated

**2. Library Extraction** (COMPLETED - spec 600 Phase 1)
- Extract scope detection to `.claude/lib/workflow-scope-detection.sh`
- Reduces duplication from 48 lines → 8 lines
- Single source of truth
- **Status**: Implemented

**3. Synchronization Tests** (RECOMMENDED - spec 600 Phase 3)
- Automated detection of drift between blocks
- Verify library usage consistency
- Catch synchronization bugs early
- **Status**: Planned

**4. Document Architecture** (IN PROGRESS - spec 600 Phase 4)
- Document subprocess isolation constraint
- Document stateless recalculation pattern
- Document decision matrix for state management
- **Status**: This document (coordinate-state-management.md)

### For Orchestration Commands Generally

**1. Use Imperative Invocation Pattern**
- Never use YAML blocks wrapped in code fences
- Always pre-calculate paths before agent invocation
- Always verify file creation with fallback
- **Validation**: `.claude/lib/validate-agent-invocation-pattern.sh`

**2. Implement Context Management**
- Extract metadata immediately after agent completion
- Prune full responses after metadata extraction
- Use layered context architecture
- Target: <30% context usage across 7 phases

**3. Apply Fail-Fast Error Handling**
- No silent fallbacks for bootstrap failures
- 5-component error messages (what, expected, diagnostic, context, action)
- Mandatory verification for file creation
- Checkpoint preservation for resumability

**4. Choose Appropriate Orchestrator**
- **Production workflows**: Use /coordinate (stable, 2,500 lines)
- **Experimental features**: Use /orchestrate (experimental, 5,438 lines)
- **Minimal reference**: Use /supervise (in development, 1,779 lines)

### For Future Refactors

**1. Measure First, Optimize Second**
- Establish baseline performance before changes
- Run benchmarks with multiple iterations (3-5)
- Track both time and token usage
- Validate end-to-end workflow performance

**2. Don't Fight Tool Constraints**
- Subprocess isolation is intentional (security)
- 400-line transformation threshold is AI processing limitation
- Accept constraints, design around them
- Fail-fast when workarounds don't work

**3. Systematic State Analysis**
- List ALL variables set in Block 1
- Identify source vs. derived variables
- Map dependency graph
- Ensure recalculation includes all dependencies

**4. Defensive Validation**
- Add validation after every recalculation
- Check for unbound variables
- Verify format (e.g., PHASES_TO_EXECUTE = "0,1,2,3,4,6")
- Fail-fast with clear error messages

---

## Appendix A: Diagnostic Commands Reference

### Check Library Definitions
```bash
grep -r "function_name()" .claude/lib/
```

### Find Variable Assignments
```bash
grep -n "VARIABLE_NAME=" .claude/commands/coordinate.md
```

### Measure Bash Block Size
```bash
awk '/^```bash$/,/^```$/ {count++} /^```$/ && count>0 {print "Block "block": "count" lines"; count=0; block++}' file.md
```

### Verify Library Sourcing
```bash
grep "REQUIRED_LIBS=" .claude/commands/coordinate.md -A20
```

### Check Phase Execution List
```bash
grep "PHASES_TO_EXECUTE=" .claude/commands/coordinate.md
```

### Validate Agent Invocation Pattern
```bash
./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/command-name.md
```

### Run Delegation Rate Test
```bash
./.claude/tests/test_orchestration_commands.sh
```

### Check Context Usage
```bash
# Approximate token count (1 token ≈ 4 characters)
REPORT_SIZE=$(wc -c < specs/027_auth/reports/027_research.md)
TOKENS=$((REPORT_SIZE / 4))
echo "Approximate tokens: $TOKENS"
```

---

## Appendix B: Performance Metrics Summary

### Context Reduction Metrics

| Workflow | Without Management | With Management | Reduction |
|----------|-------------------|-----------------|-----------|
| 4-agent research | 20,000 tokens (80%) | 1,000 tokens (4%) | 95% |
| 7-phase /orchestrate | 40,000 tokens (160% overflow) | 7,000 tokens (28%) | 82% |
| Hierarchical (3 levels) | 60,000 tokens (240% overflow) | 4,000 tokens (16%) | 93% |

### Time Savings Metrics

| Scenario | Sequential | Parallel | Savings |
|----------|------------|----------|---------|
| 4 research reports | 800s (13.3min) | 320s (5.3min) | 60% |
| 3-wave implementation | 1,500s (25min) | 900s (15min) | 40% |
| 6-phase with dependencies | 1,180s (19.7min) | 810s (13.5min) | 31% |

### File Creation Reliability

| Approach | Reliability | Time Cost |
|----------|-------------|-----------|
| No verification | 70% | 0s |
| Verification + fallback | 100% | +2-3s per file |

### Agent Delegation Rate

| Pattern | Delegation Rate | Validation |
|---------|----------------|------------|
| Documentation-only YAML | 0% | Anti-pattern |
| Imperative invocation | >90% | Validated |
| With verification checkpoints | 100% | Best practice |

---

## Appendix C: References

### Documentation
- [Coordinate State Management](.claude/docs/architecture/coordinate-state-management.md) - Complete subprocess isolation documentation
- [Orchestration Troubleshooting Guide](.claude/docs/guides/orchestration-troubleshooting.md) - Diagnostic procedures
- [Bash Tool Limitations](.claude/docs/troubleshooting/bash-tool-limitations.md) - Known limitations and workarounds
- [Context Management Pattern](.claude/docs/concepts/patterns/context-management.md) - Context reduction techniques
- [Metadata Extraction Pattern](.claude/docs/concepts/patterns/metadata-extraction.md) - 95% reduction per artifact
- [Verification and Fallback Pattern](.claude/docs/concepts/patterns/verification-fallback.md) - File creation reliability
- [Behavioral Injection Pattern](.claude/docs/concepts/patterns/behavioral-injection.md) - Agent invocation patterns

### Specifications
- Spec 578: Fix Library Sourcing Error (BASH_SOURCE limitation)
- Spec 581: Performance Optimization (block consolidation)
- Spec 582: Code Transformation Discovery (400-line threshold)
- Spec 583: BASH_SOURCE Limitation (SlashCommand context)
- Spec 584: Export Persistence Failure (root cause identification)
- Spec 585: Pattern Validation (stateless recommended)
- Specs 586-594: Incremental refinements
- Spec 597: Stateless Recalculation Breakthrough (first success)
- Spec 598: Extend to Derived Variables (pattern completion)
- Spec 599: Comprehensive Refactor Analysis (7 opportunities)
- Spec 600: High-Value Refactoring (current implementation)

### GitHub Issues
- [#334](https://github.com/anthropics/claude-code/issues/334) - Environment Variables Not Persisting (March 2025)
- [#2508](https://github.com/anthropics/claude-code/issues/2508) - Documentation Inconsistency (June 2025)

---

**Report Completion**: 2025-11-07
**Research Depth**: Comprehensive (13+ specs, 10+ documentation files, 2 GitHub issues)
**Pattern Confidence**: High (validated across 16+ tests, multiple implementations)
**Recommendation Strength**: Strong (proven patterns, validated performance, clear metrics)

REPORT_CREATED: /home/benjamin/.config/.claude/specs/601_and_documentation_in_claude_docs_in_order_to/reports/003_topic3.md
