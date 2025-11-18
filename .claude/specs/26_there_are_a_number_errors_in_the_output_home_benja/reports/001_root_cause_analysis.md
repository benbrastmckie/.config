# Root Cause Analysis: Bash Syntax Errors in /research-plan Command

## Metadata
- **Date**: 2025-11-17
- **Severity**: CRITICAL
- **Commands Affected**: /research-plan (potentially /research-report, /research-revise)
- **Issue Type**: Bash block execution model violation
- **Discovery Method**: User execution of /research-plan with multi-line feature description
- **Error File**: /home/benjamin/.config/.claude/research_plan_output.md

## Executive Summary

The /research-plan command fails with bash syntax errors when Claude Code attempts to execute markdown bash blocks. The root cause is a **fundamental misunderstanding of how bash code blocks work in Claude Code slash commands**. The command file treats bash blocks as documentation that Claude will execute via explicit Bash tool calls, but Claude is instead attempting to execute the raw bash code directly, causing catastrophic failures.

**Primary Error Pattern**:
```
/run/current-system/sw/bin/bash: eval: line 1: syntax error near unexpected token `then'
```

**Impact**: CRITICAL
- Command completely non-functional for its intended purpose
- All multi-line feature descriptions fail
- Variable escaping issues corrupt bash code
- Silent architectural misalignment between implementation and execution

**Root Cause**: Claude Code is treating bash blocks in the markdown as **executable bash code** rather than **documentation**, attempting to execute multi-line bash scripts as single `eval` statements with catastrophic variable substitution and escaping issues.

## Technical Analysis

### The Architectural Mismatch

The /research-plan command uses a **two-tier execution model**:

1. **Bash blocks** (lines 26-59, 63-174, etc.) - Intended as documentation showing what bash code should run
2. **Task blocks** (lines 176-193, 277-295) - Intended to invoke subagents

**What Claude Code Actually Does**:
- Reads the markdown command file
- Attempts to execute bash blocks as literal bash commands via `eval`
- Substitutes variables like `$FEATURE_DESCRIPTION` into the bash code
- Escapes special characters, creating malformed bash syntax

### Evidence from Error Output

**Error 1** (lines 31-77 in research_plan_output.md):

```
Bash(FEATURE_DESCRIPTION="Research the definitions in
      /home/benjamin/Documents/Philosophy/Projects/Logos/docs/glossary/semantic-concepts.md which aim to synthesize t…)
  ⎿  Error: Exit code 2
     /run/current-system/sw/bin/bash: eval: line 1: syntax error near unexpected token `then'
     /run/current-system/sw/bin/bash: eval: line 1:
     `FEATURE_DESCRIPTION='Research the definitions in
     /home/benjamin/Documents/Philosophy/Projects/Logos/docs/glossary/semantic-concepts.md which aim to synthesize
     the definitions from /home/benjamin/Documents/Philosophy/Papers/PossibleWorlds/JPL/possible_worlds.tex which
     provides an intensional theory (world-states are primitive) with an improved theory of time which uses a
     parameterized task relation, and /home/benjamin/Documents/Philosophy/Papers/Counterfactuals/JPL/counterfactual_worlds.tex which provides a
     hyperintensional theory (world-states are defined in terms of the task relation). Research these definitions
     in order to create an appropriate synthesis which includes the advantages of each (the improved theory of
     time with the hyperintensional definition of world-histories). Note that the definition of
     world-histories given in line 1473 in /home/benjamin/Documents/Philosophy/Papers/Counterfactuals/JPL/counterfactual_worlds.tex is to be preferred.
     Create a plan to revise /home/benjamin/Documents/Philosophy/Projects/Logos/docs/glossary/semantic-concepts.md
     accordingly.' if \[ -z '' \] ; then echo 'ERROR: Feature description required' exit 1 fi DEFAULT_COMPLEXITY\=3
     RESEARCH_COMPLEXITY\= if \[\[ '' \=~ --complexity\[\[\:space:\]\]+ ( \[1-4\] ) \]\] ; then
     RESEARCH_COMPLEXITY\= FEATURE_DESCRIPTION\=\$ ( echo '' < /dev/null | sed
     s/--complexity\[\[\:space:\]\]\*\[1-4\]// | xargs ) fi if \\! echo '' | grep -Eq \^\[1-4\]\$ ; then echo
     'ERROR: Invalid research complexity:  (must be 1-4)' >&2 exit 1 fi echo '=== Research-and-Plan Workflow ==='
     echo 'Feature: ' echo 'Research Complexity: ' echo '''
```

**Analysis**:
1. Claude substituted the entire bash block (lines 26-59 from research-plan.md) as a single command
2. The multi-line feature description was inserted into `FEATURE_DESCRIPTION='...'`
3. Special bash characters (`[`, `$`, `!`, etc.) were escaped with backslashes
4. The result: a single-line eval statement with malformed syntax
5. All variable references became empty strings (note `if [ -z '' ]` instead of `if [ -z "$FEATURE_DESCRIPTION" ]`)

**Error 2** (lines 90-113 in research_plan_output.md):

```
Bash(if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
      CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"…)
  ⎿  Error: Exit code 2
     /run/current-system/sw/bin/bash: eval: line 1: syntax error near unexpected token `do'
     /run/current-system/sw/bin/bash: eval: line 1: `if command -v git & > /dev/null && git rev-parse --git-dir
     > /dev/null 2>&1 ; then 'CLAUDE_PROJECT_DIR=$(git rev-parse --show-toplevel)' else current_dir\=\$\(pwd\)
     while \[ '' \\!\= / \] ; do if \[ -d /.claude \] ; then CLAUDE_PROJECT_DIR\= break fi 'current_dir=$(dirname )'
     done fi echo CLAUDE_PROJECT_DIR\= TOPIC_SLUG\=research_semantic_concepts_synthesis
     TOPIC_NUMBER\=\$ ( find /.claude/specs -maxdepth 1 -type d -name \[0-9\]\*_\* 2>/dev/null < /dev/null | wc -l | xargs )
     TOPIC_NUMBER\=\$ ( ( TOPIC_NUMBER + 1 ) ) SPECS_DIR\=/.claude/specs/_ RESEARCH_DIR\=/reports
     PLANS_DIR\=/plans mkdir -p '' mkdir -p '' echo SPECS_DIR\= echo RESEARCH_DIR\= echo PLANS_DIR\='
```

**Analysis**:
1. Bash block from lines 63-174 (Part 2: State Machine Initialization)
2. Multi-line control structures (`while`, `if`, `done`) collapsed into single line
3. Variable substitutions became empty or malformed
4. Command substitutions like `$(dirname "$current_dir")` became `$(dirname )`
5. Result: syntax error on `do` token due to malformed loop structure

### Comparison with Working Commands

**Working Pattern: /fix command** (lines 159-164):

```
Task {
  subagent_type: "research-specialist"
  description: "Research root cause for $ISSUE_DESCRIPTION"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md
```

**Working Pattern: /build command** (lines 209-214):

```
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallelization"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md
```

**Key Differences**:
1. Working commands use **minimal bash blocks** for argument parsing and validation
2. Working commands use **Task blocks** for all complex workflow logic
3. Working commands **do not embed multi-line control flow** in bash blocks
4. Working commands **pass variables to agents via prompt interpolation**

### The Task Block Pattern

**What /research-plan SHOULD be doing** (lines 176-193):

```
Task {
  subagent_type: "research-specialist"
  description: "Research $FEATURE_DESCRIPTION"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are conducting research for: research-plan workflow

    Input:
    - Research Topic: $FEATURE_DESCRIPTION
    - Research Complexity: $RESEARCH_COMPLEXITY
    - Output Directory: $RESEARCH_DIR
    - Workflow Type: research-and-plan

    Execute research according to behavioral guidelines and return completion signal:
    REPORT_CREATED: ${REPORT_PATH}
}
```

**Problem**: The bash blocks BEFORE the Task block are attempting to:
- Set up variables (`RESEARCH_DIR`, `PLANS_DIR`, etc.)
- Initialize state machine
- Create directory structure

**Reality**: Claude Code cannot execute these bash blocks reliably because:
1. Multi-line bash code in markdown is treated as documentation, not executable code
2. When Claude attempts to execute it, variable escaping fails
3. The execution model assumes single-line commands or explicit Bash tool calls

## Root Cause Summary

The /research-plan command is based on a **fundamentally flawed execution model**:

1. **Assumption**: Claude will read bash blocks as documentation and execute them via Bash tool calls
2. **Reality**: Claude attempts to execute bash blocks directly via `eval`, causing syntax errors
3. **Consequence**: Multi-line bash code with complex control flow cannot execute

**Why This Affects /research-plan Specifically**:

1. **Complex bash blocks**: Lines 26-59 (Part 1), 63-174 (Part 2), 134-174 (Part 3)
2. **Multi-line feature descriptions**: User input contains newlines, paths, special characters
3. **Variable substitution**: `$FEATURE_DESCRIPTION` expands to multi-line text
4. **Escaping cascade**: Special characters get escaped, creating malformed bash syntax

**Why Other Commands Work**:

1. **Simple bash blocks**: Minimal argument parsing only
2. **Task delegation**: Complex logic delegated to subagents via Task blocks
3. **No multi-line variables**: Simple strings only, no complex user input
4. **Limited control flow**: No while loops, complex if statements in bash blocks

## Verification Evidence

### Direct Evidence from Error Output

**Line 64 in research_plan_output.md**:
```
if \[ -z '' \] ; then echo 'ERROR: Feature description required' exit 1 fi
```

**Expected bash code** (line 29 in research-plan.md):
```bash
if [ -z "$FEATURE_DESCRIPTION" ]; then
  echo "ERROR: Feature description required"
  exit 1
fi
```

**What happened**:
1. `$FEATURE_DESCRIPTION` substituted to empty string (variable not set in eval context)
2. Square brackets escaped: `\[` instead of `[`
3. Multi-line code collapsed to single line
4. Result: malformed bash that can't execute

### Web Research Findings

From GitHub issue #7387 (Shell script occasionally fails due to crazy escaping):
- Users report similar escaping issues with bash commands in Claude Code
- Problem occurs when bash code is executed via `eval` with variable substitution
- Apostrophes, brackets, and special characters get escaped incorrectly

From Claude Code documentation (Slash commands):
- Markdown code blocks are treated as **documentation**
- Actual execution requires **explicit tool calls** (Bash tool, Task tool, etc.)
- Commands should use Task blocks for complex logic, not bash blocks

## Impact Assessment

### Functional Impact

**Current State**: CRITICAL FAILURE
- Command completely non-functional
- All executions with multi-line descriptions fail
- No research reports generated
- No implementation plans created

**User Experience**:
- Confusing error messages (bash syntax errors instead of clear failure)
- No obvious workaround (command design prevents simple fixes)
- Loss of trust in workflow system

### Architectural Impact

**Design Debt**:
- Command based on incorrect execution model
- Inconsistent with other working commands (/fix, /build, /research-report)
- Violates Claude Code documentation patterns

**Maintenance Risk**:
- Similar issues likely in /research-report, /research-revise
- Pattern may have been copied to other commands
- Fixing one command requires auditing all workflow commands

## Recommended Solution

### Immediate Fix (High Priority)

**Refactor /research-plan to use Task-based execution model**:

1. **Minimal bash block for argument parsing** (Part 1):
   ```bash
   FEATURE_DESCRIPTION="$1"
   if [ -z "$FEATURE_DESCRIPTION" ]; then
     echo "ERROR: Feature description required"
     exit 1
   fi

   # Parse complexity flag
   RESEARCH_COMPLEXITY="${2:-3}"

   # Export for Task block access
   export FEATURE_DESCRIPTION
   export RESEARCH_COMPLEXITY
   ```

2. **Task block for state machine initialization**:
   ```
   Task {
     subagent_type: "general-purpose"
     description: "Initialize research-plan workflow"
     prompt: |
       Initialize state machine for research-plan workflow.

       Variables available:
       - FEATURE_DESCRIPTION: $FEATURE_DESCRIPTION
       - RESEARCH_COMPLEXITY: $RESEARCH_COMPLEXITY

       Tasks:
       1. Detect CLAUDE_PROJECT_DIR
       2. Source required libraries
       3. Initialize state machine
       4. Create specs directories
       5. Return: SPECS_DIR, RESEARCH_DIR, PLANS_DIR
   }
   ```

3. **Task block for research phase**:
   ```
   Task {
     subagent_type: "research-specialist"
     description: "Research $FEATURE_DESCRIPTION"
     prompt: |
       [Existing prompt from lines 180-192]
   }
   ```

4. **Task block for planning phase**:
   ```
   Task {
     subagent_type: "plan-architect"
     description: "Create implementation plan"
     prompt: |
       [Existing prompt from lines 281-294]
   }
   ```

### Alternative Solution (Lower Risk)

**Use explicit Bash tool calls instead of bash blocks**:

Instead of:
```bash
FEATURE_DESCRIPTION="$1"
if [ -z "$FEATURE_DESCRIPTION" ]; then
  echo "ERROR: Feature description required"
  exit 1
fi
```

Use:
```
Bash {
  command: |
    FEATURE_DESCRIPTION="$1"
    if [ -z "$FEATURE_DESCRIPTION" ]; then
      echo "ERROR: Feature description required"
      exit 1
    fi
}
```

**Problem with this approach**:
- Still fighting against the execution model
- Requires careful variable escaping
- Doesn't align with working command patterns

### Long-term Fix (Recommended)

**Audit and refactor all workflow commands**:

1. **/research-plan**: Refactor to Task-based model (HIGH priority)
2. **/research-report**: Check for similar issues (MEDIUM priority)
3. **/research-revise**: Check for similar issues (MEDIUM priority)
4. **/fix**: Verify compliance with best practices (LOW priority - appears correct)
5. **/build**: Verify compliance with best practices (LOW priority - appears correct)

**Establish command design standards**:

1. **Bash blocks**: Argument parsing and validation ONLY
2. **Task blocks**: All workflow logic, state management, complex operations
3. **Variable passing**: Via environment exports or Task prompt interpolation
4. **Documentation**: Update command guide with execution model details

## Comparison with Similar Issues

### Related Bug Report: Bash Block Variable Scope Violations

**File**: /home/benjamin/.config/.claude/specs/15_research_the_compliance_of_build_fix_research_repo/debug/001_bash_block_variable_scope_violations.md

**Issue**: Variables don't persist across bash blocks (subprocess isolation)

**Similarity**: Both issues relate to misunderstanding bash block execution model

**Difference**:
- Scope issue: Variables lost between blocks (subprocess isolation)
- This issue: Bash blocks can't execute at all (syntax errors from eval)

**Root cause relationship**:
- Both stem from incorrect assumptions about bash block execution
- Scope issue: Assumes variables persist (they don't)
- This issue: Assumes complex bash executes (it doesn't)

## Testing Recommendations

### Minimal Reproduction Test

Create test command `/test-bash-eval.md`:

```bash
FEATURE="test with
multiple lines
and special chars: []{}"
echo "$FEATURE"
```

**Expected result**: Bash syntax error (same as /research-plan)

### Validation Test After Fix

1. Execute `/research-plan "simple feature description"`
2. Execute `/research-plan "multi-line feature
   description with special chars: []{}
   and paths: /home/user/test"`
3. Verify both succeed without bash syntax errors
4. Verify research reports created
5. Verify implementation plan created

## Conclusion

The /research-plan command is fundamentally broken due to a misalignment between its implementation and Claude Code's execution model. The command attempts to execute complex multi-line bash code via markdown bash blocks, which Claude Code cannot reliably execute.

**Immediate Action Required**:
1. Refactor /research-plan to use Task-based execution model
2. Remove complex bash blocks (lines 63-174, 134-174, 195-239, 244-263)
3. Replace with Task blocks that delegate to subagents
4. Keep only minimal bash block for argument parsing (lines 26-59)

**Priority**: CRITICAL - Command is completely non-functional

**Estimated Effort**: 4-6 hours for refactor + testing

**Risk**: LOW - Refactor aligns with proven patterns from /fix and /build commands
