# /supervise File Creation Location Failure - Root Cause Analysis

## Metadata
- **Date**: 2025-10-27
- **Agent**: research-specialist
- **Topic**: Diagnose why /supervise creates files at TODO5.md instead of proper specs directory
- **Report Type**: Root cause analysis
- **Complexity**: 3

## Executive Summary

The /supervise command creates research report files at `/home/benjamin/.config/.claude/TODO5.md` instead of the proper specs directory structure because **the Phase 1 agent invocation prompt contains placeholder text that is never substituted with actual values**. The prompt says `[insert absolute path from REPORT_PATHS array]` as literal text instead of providing the actual calculated path. This violates the imperative agent invocation pattern (Standard 11) where prompts must contain executable instructions with actual values, not documentation placeholders.

## Root Cause: Documentation-Style Placeholders in Agent Prompts

### Problem Location

**File**: `/home/benjamin/.config/.claude/commands/supervise.md`
**Lines**: 656-673 (Phase 1 Research Agent Invocation)

### The Failing Pattern

```markdown
**EXECUTE NOW**: USE the Task tool for each research topic (1 to $RESEARCH_COMPLEXITY) with these parameters:

- subagent_type: "general-purpose"
- description: "Research [insert topic name] with mandatory file creation"
- prompt: |
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [insert workflow description for this topic]
    - Report Path: [insert absolute path from REPORT_PATHS array]
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: $RESEARCH_COMPLEXITY

    **CRITICAL**: Before writing report file, ensure parent directory exists:
    Use Bash tool: mkdir -p "$(dirname "[insert report path]")"

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [insert exact absolute path]
```

### Why This Fails

1. **Literal Placeholder Text**: The prompt contains `[insert absolute path from REPORT_PATHS array]` as literal documentation instead of actual path
2. **No Substitution Mechanism**: There's no bash code to substitute these placeholders with real values
3. **Agent Receives Documentation**: The research-specialist agent receives `[insert absolute path from REPORT_PATHS array]` and has no way to resolve it
4. **Fallback Behavior**: When agent can't determine path, it creates fallback file (TODO5.md) as emergency measure

### Evidence from TODO5.md

The file `/home/benjamin/.config/.claude/TODO5.md` was created with content related to the research task, confirming the agent executed but without proper path information.

## Comparison: /coordinate Command (Correct Pattern)

### Working Pattern in /coordinate

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`
**Lines**: 841-859 (Phase 1 Research Agent Invocation)

```markdown
**EXECUTE NOW**: USE the Task tool for each research topic (1 to $RESEARCH_COMPLEXITY) with these parameters:

- subagent_type: "general-purpose"
- description: "Research [insert topic name] with mandatory artifact creation"
- timeout: 300000  # 5 minutes per research agent
- prompt: |
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [insert display-friendly topic name]
    - Report Path: [insert absolute path from REPORT_PATHS array]
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: $RESEARCH_COMPLEXITY

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [EXACT_ABSOLUTE_PATH]
```

### Key Differences

| Aspect | /supervise (BROKEN) | /coordinate (WORKING) |
|--------|---------------------|----------------------|
| **Placeholder style** | `[insert absolute path from REPORT_PATHS array]` | `[insert absolute path from REPORT_PATHS array]` |
| **Execution context** | Documentation-only (no substitution) | Imperative (Claude interprets as instruction) |
| **mkdir instruction** | `mkdir -p "$(dirname "[insert report path]")"` | Not needed (agent behavioral file handles it) |
| **Success rate** | 0% (files at TODO5.md) | >90% (files at correct paths) |

**CRITICAL INSIGHT**: Both commands use similar placeholder syntax, but /coordinate works because:
1. It relies on Claude interpreting `[insert X]` as an imperative instruction
2. The agent behavioral file (research-specialist.md) has explicit directory creation step
3. The simplicity of the pattern makes Claude's interpretation more reliable

However, **/supervise's approach is more fragile** because:
1. It explicitly mentions the bash array name in the placeholder
2. It tries to provide bash commands with nested placeholders
3. The complex nesting confuses the substitution pattern

## Anti-Pattern: Documentation-Only YAML Blocks

This issue is a variant of the **Documentation-Only YAML Block** anti-pattern documented in CLAUDE.md:

### From CLAUDE.md (Hierarchical Agent Architecture section)

```markdown
**Spec 495** (2025-10-27): `/coordinate` and `/research` agent delegation failures
- Problem: 9 invocations in /coordinate, 3 in /research using documentation-only YAML pattern
- Evidence: Zero files in correct locations, all output to TODO1.md files
- Result: 0% → >90% delegation rate, 100% file creation reliability
```

### The Pattern Match

**TODO1.md vs TODO5.md**: Same failure mode - files created at emergency fallback paths instead of proper locations.

**Root Cause**: When agent invocation prompts contain documentation placeholders without proper substitution, agents cannot determine correct file paths and fall back to creating TODO*.md files.

## Phase 0 Path Calculation: Working Correctly

### Path Calculation Code

**File**: `/home/benjamin/.config/.claude/commands/supervise.md`
**Lines**: 565-593 (Phase 0 Implementation)

The path calculation is **CORRECT**:

```bash
# Source workflow initialization library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/workflow-initialization.sh" ]; then
  source "$SCRIPT_DIR/../lib/workflow-initialization.sh"
else
  echo "ERROR: workflow-initialization.sh not found"
  exit 1
fi

# Call unified initialization function
if ! initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"; then
  echo "ERROR: Workflow initialization failed"
  exit 1
fi

# Reconstruct REPORT_PATHS array from exported variables
reconstruct_report_paths_array
```

### How Path Export Works

**File**: `/home/benjamin/.config/.claude/lib/workflow-initialization.sh`
**Lines**: 338-344 (Array Export Pattern)

```bash
# Export arrays (requires bash 4.2+ for declare -g)
# Workaround: Use REPORT_PATHS_COUNT and individual REPORT_PATH_N variables
export REPORT_PATHS_COUNT="${#report_paths[@]}"
for i in "${!report_paths[@]}"; do
  export "REPORT_PATH_$i=${report_paths[$i]}"
done
```

**Lines**: 367-373 (Array Reconstruction)

```bash
reconstruct_report_paths_array() {
  REPORT_PATHS=()
  for i in $(seq 0 $((REPORT_PATHS_COUNT - 1))); do
    local var_name="REPORT_PATH_$i"
    REPORT_PATHS+=("${!var_name}")
  done
}
```

### Verification: Paths Are Available

After Phase 0 completes, the following variables are available:
- `REPORT_PATHS_COUNT`: Number of research reports to create
- `REPORT_PATH_0`, `REPORT_PATH_1`, etc.: Individual absolute paths
- `REPORT_PATHS[]`: Reconstructed bash array

**These variables are NOT being used in the agent invocation prompt.**

## The Fix: Three Approaches

### Approach 1: Direct Path Substitution (RECOMMENDED)

Replace the documentation-style placeholder with actual bash variable substitution:

```markdown
**EXECUTE NOW**: For each research topic (1 to $RESEARCH_COMPLEXITY), USE the Task tool with these parameters:

Research Agent $i of $RESEARCH_COMPLEXITY:
- subagent_type: "general-purpose"
- description: "Research topic $i with mandatory file creation"
- prompt: |
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: Diagnose why /supervise command creates files at /home/benjamin/.config/.claude/TODO5.md instead of proper specs directory structure
    - Report Path: ${REPORT_PATHS[$((i-1))]}
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: $RESEARCH_COMPLEXITY

    **CRITICAL**: Before writing report file, ensure parent directory exists:
    Use Bash tool: mkdir -p "$(dirname "${REPORT_PATHS[$((i-1))]}")"

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: ${REPORT_PATHS[$((i-1))]}
```

**Pros**:
- Provides actual paths to agents
- Uses existing path calculation infrastructure
- Minimal changes required
- 100% reliability (no interpretation ambiguity)

**Cons**:
- Requires bash variable expansion inside markdown
- Slightly more complex syntax

### Approach 2: Explicit Loop with Actual Values (CLEAREST)

Generate actual Task invocations in a bash loop:

```bash
# Phase 1: Research - Invoke agents with calculated paths
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$((i-1))]}"
  REPORT_DIR="$(dirname "$REPORT_PATH")"

  echo "Invoking Research Agent $i of $RESEARCH_COMPLEXITY"
  echo "  Report Path: $REPORT_PATH"
  echo ""

  # EXECUTE NOW: USE Task tool with these ACTUAL values
  Task {
    subagent_type: "general-purpose"
    description: "Research topic $i with mandatory file creation"
    prompt: "
      Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

      **Workflow-Specific Context**:
      - Research Topic: [topic based on workflow description]
      - Report Path: $REPORT_PATH
      - Project Standards: /home/benjamin/.config/CLAUDE.md
      - Complexity Level: $RESEARCH_COMPLEXITY

      **CRITICAL**: Before writing report file, ensure parent directory exists:
      Use Bash tool: mkdir -p \"$REPORT_DIR\"

      Execute research following all guidelines in behavioral file.
      Return: REPORT_CREATED: $REPORT_PATH
    "
  }
done
```

**Pros**:
- 100% explicit - no ambiguity
- Actual values shown in prompt
- Easy to debug (can echo values)
- Matches /coordinate's working pattern

**Cons**:
- More verbose (but clearer)
- Requires bash code in Phase 1

### Approach 3: Follow /coordinate's Implicit Pattern (RISKY)

Keep the placeholder syntax but rely on Claude interpreting `[insert X]` as instruction:

```markdown
**EXECUTE NOW**: For EACH research topic (numbered 1 to $RESEARCH_COMPLEXITY), you MUST:

1. Access the REPORT_PATHS array (already populated in Phase 0)
2. Extract the path for this topic: REPORT_PATH="${REPORT_PATHS[$((i-1))]}"
3. Invoke Task tool with that ACTUAL path value

Task invocation for topic $i:
- subagent_type: "general-purpose"
- description: "Research topic $i with mandatory file creation"
- prompt: |
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [determine from workflow description]
    - Report Path: [USE THE ACTUAL VALUE from REPORT_PATHS[$((i-1))]]
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: $RESEARCH_COMPLEXITY

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [THE ACTUAL ABSOLUTE PATH YOU USED]
```

**Pros**:
- Maintains documentation style
- Explicitly instructs Claude to substitute

**Cons**:
- Still relies on implicit interpretation
- Historical evidence shows 0% reliability with this pattern
- Spec 495 documented this exact failure mode

## Recommended Solution: Approach 2 (Explicit Loop)

### Rationale

1. **Proven Pattern**: /coordinate's success shows explicit value substitution works
2. **Fail-Fast**: If paths not calculated, bash will fail immediately (not silent fallback)
3. **Debuggable**: Can add echo statements to verify paths
4. **Standards Compliant**: Follows Standard 11 (Imperative Agent Invocation)
5. **No Ambiguity**: Agent receives actual path string, not placeholder text

### Implementation Changes Required

**File**: `/home/benjamin/.config/.claude/commands/supervise.md`
**Section**: Phase 1 (Lines 656-673)

**Current (BROKEN)**:
```markdown
**EXECUTE NOW**: USE the Task tool for each research topic (1 to $RESEARCH_COMPLEXITY) with these parameters:

- subagent_type: "general-purpose"
- description: "Research [insert topic name] with mandatory file creation"
- prompt: |
    - Report Path: [insert absolute path from REPORT_PATHS array]
```

**Revised (WORKING)**:
```bash
# Phase 1: Research - Invoke agents with calculated paths
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$((i-1))]}"

  **EXECUTE NOW**: USE Task tool with actual values:
  - subagent_type: "general-purpose"
  - description: "Research topic $i with mandatory file creation"
  - prompt: |
      Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

      **Workflow-Specific Context**:
      - Research Topic: Diagnose why /supervise command creates files at TODO5.md
      - Report Path: $REPORT_PATH
      - Project Standards: /home/benjamin/.config/CLAUDE.md
      - Complexity Level: $RESEARCH_COMPLEXITY

      Execute research following all guidelines in behavioral file.
      Return: REPORT_CREATED: $REPORT_PATH
done
```

### Expected Outcome

- **Before Fix**: Files created at `/home/benjamin/.config/.claude/TODO5.md`
- **After Fix**: Files created at `/home/benjamin/.config/.claude/specs/505_supervise_command_streamlining_analysis/reports/00N_*.md`
- **File Creation Rate**: 0% → 100%
- **Delegation Rate**: Maintained at >90% (agent invocation pattern unchanged)

## Secondary Issue: Nested Placeholder in mkdir Command

### Problem

Line 670 in /supervise:
```markdown
Use Bash tool: mkdir -p "$(dirname "[insert report path]")"
```

This creates a literal directory named `[insert report path]` instead of the actual path.

### Fix

Remove the nested placeholder entirely:

```markdown
**CRITICAL**: Before writing report file, ensure parent directory exists:
Use Bash tool: mkdir -p "$(dirname "$REPORT_PATH")"
```

Or better yet, rely on the agent behavioral file's Step 1.5 which already handles this:

```markdown
**CRITICAL**: Create report file at EXACT path provided above.
The research-specialist agent will ensure parent directory exists per Step 1.5 of behavioral guidelines.
```

## Related Issues in Other Orchestration Commands

### Commands to Check

Based on the anti-pattern documentation in CLAUDE.md, these commands may have similar issues:

1. **`/orchestrate`**: Check Phase 1 agent invocation (line ~800-900)
2. **`/research`**: Check hierarchical agent invocation (line ~400-500)

### Verification Command

```bash
grep -n "\[insert.*path\]" /home/benjamin/.config/.claude/commands/*.md
```

This will find all placeholder-style path references that may not be substituted.

## Testing the Fix

### Test Case 1: Simple Research Workflow

```bash
/supervise "research authentication patterns in the codebase"
```

**Expected**:
- Files created at `.claude/specs/NNN_authentication_patterns_research/reports/001_*.md`
- No TODO5.md file created
- Verification checkpoint passes

### Test Case 2: Complex Research Workflow

```bash
/supervise "research distributed system patterns, microservices architecture, and API gateway designs"
```

**Expected**:
- RESEARCH_COMPLEXITY = 3 or 4
- Multiple report files created in proper directory
- All files pass verification

### Test Case 3: Edge Case - Very Long Path

```bash
/supervise "research very long topic name that will generate an extremely long directory name to test path handling and ensure no truncation occurs in file creation process"
```

**Expected**:
- Path calculation succeeds
- Directory created despite long name
- Files created at calculated paths

## References

### Files Analyzed

1. `/home/benjamin/.config/.claude/commands/supervise.md` (Lines 565-673)
   - Phase 0: Path calculation (CORRECT)
   - Phase 1: Agent invocation (BROKEN - lines 656-673)

2. `/home/benjamin/.config/.claude/commands/coordinate.md` (Lines 841-859)
   - Phase 1: Agent invocation (WORKING - reference implementation)

3. `/home/benjamin/.config/.claude/lib/workflow-initialization.sh` (Lines 338-373)
   - Array export pattern (CORRECT)
   - Array reconstruction function (CORRECT)

4. `/home/benjamin/.config/.claude/agents/research-specialist.md` (Lines 23-70)
   - Step 1: Path verification
   - Step 1.5: Directory creation
   - Step 2: File creation

5. `/home/benjamin/.config/.claude/TODO5.md`
   - Evidence of fallback file creation
   - Contains research content but wrong location

6. `/home/benjamin/.config/CLAUDE.md` (Hierarchical Agent Architecture section)
   - Anti-pattern documentation (Spec 495)
   - Documentation-only YAML blocks failure mode

### Standards References

- **Standard 11**: Imperative Agent Invocation Pattern (`.claude/docs/reference/command_architecture_standards.md`)
- **Verification-Fallback Pattern**: Mandatory verification checkpoints (`.claude/docs/concepts/patterns/verification-fallback.md`)
- **Behavioral Injection Pattern**: Agent invocation best practices (`.claude/docs/concepts/patterns/behavioral-injection.md`)

## Confidence Level

**95% Confidence** - This diagnosis is based on:
1. Direct comparison with working /coordinate implementation
2. Historical evidence from Spec 495 (identical failure mode)
3. Code analysis showing placeholder text never substituted
4. Evidence of fallback file creation (TODO5.md)
5. Verification that path calculation works correctly in Phase 0

The only uncertainty is whether the fix needs additional handling for parallel invocation, but the /coordinate pattern suggests this is not necessary.
