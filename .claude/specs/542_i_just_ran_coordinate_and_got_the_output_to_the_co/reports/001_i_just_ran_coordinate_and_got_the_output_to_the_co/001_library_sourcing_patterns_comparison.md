# Library Sourcing Patterns Comparison Research Report

## Metadata
- **Date**: 2025-10-30
- **Agent**: research-specialist
- **Topic**: Library sourcing patterns comparison between spec_org and master branches
- **Report Type**: codebase analysis
- **Overview Report**: [/coordinate Command Failure Root Cause Analysis](./OVERVIEW.md)
- **Related Reports**:
  - [Coordinate Command Structure Diff](./002_coordinate_command_structure_diff.md)
  - [Bash Script Execution Environment](./003_bash_script_execution_environment.md)
  - [Phase Zero Library Initialization](./004_phase_zero_library_initialization.md)

## Executive Summary

The spec_org branch **broke** the working /coordinate command from the master branch. The breakage was caused by adding two "EXECUTE NOW" directives (lines 522 and 751) that force literal inline execution of bash code blocks. When bash code is executed inline (not as a script file), `BASH_SOURCE[0]` is empty, causing `SCRIPT_DIR` to resolve incorrectly. This results in library sourcing failures because the code looks for libraries at the wrong path (`/home/benjamin/.config/../lib/` instead of `/home/benjamin/.config/.claude/lib/`). **Master branch works correctly** by treating bash blocks as guidance rather than forcing literal execution.

## Findings

### 1. Breaking Change: "EXECUTE NOW" Directives Added in spec_org

**Location**: `.claude/commands/coordinate.md`

**Diff Analysis**:
```diff
@@ -519,6 +519,8 @@ emit_progress "2" "Planning phase started"

 ### Implementation

+**EXECUTE NOW**: USE the Bash tool to execute the following Phase 0 setup:
+
 STEP 0: Source Required Libraries (MUST BE FIRST)
```

**Impact**:
- **Master branch (line 520)**: No "EXECUTE NOW" directive - bash blocks treated as guidance - **WORKS** ✓
- **spec_org branch (line 522)**: Added "EXECUTE NOW" directive - forces literal inline execution - **BROKEN** ✗
- Similar breaking change at line 751 for helper function definitions

**Root Cause**: The "EXECUTE NOW" directives force Claude to execute bash code inline, where `BASH_SOURCE[0]` is empty. This causes `SCRIPT_DIR` calculation to fail:
```bash
# In inline execution context:
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# BASH_SOURCE[0] is empty, so this resolves to PWD (/home/benjamin/.config)
# Instead of /home/benjamin/.config/.claude/commands
```

### 2. Library Sourcing Code is Identical

**File**: `.claude/lib/library-sourcing.sh`

**Analysis**:
- Both branches have identical library-sourcing.sh (110 lines)
- Both branches have identical source_required_libraries function call:
  ```bash
  if ! source_required_libraries "dependency-analyzer.sh" "context-pruning.sh" "checkpoint-utils.sh" "unified-location-detection.sh" "workflow-detection.sh" "unified-logger.sh" "error-handling.sh"; then
    exit 1
  fi
  ```

**Location in coordinate.md**:
- Master branch: line 538-542
- Spec_org branch: line 541-543 (shifted by 2 lines due to added directive)

### 3. Architectural Pattern Compliance

**Command Design** (`.claude/commands/coordinate.md:34-50`):

The command explicitly defines its role as ORCHESTRATOR, not EXECUTOR:

```markdown
**YOUR RESPONSIBILITIES**:
1. Pre-calculate ALL artifact paths before any agent invocations
2. Determine workflow scope (research-only, research-and-plan, full-implementation, debug-only)
3. Invoke specialized agents via Task tool with complete context injection
4. Verify agent outputs at mandatory checkpoints
5. Extract and aggregate metadata from agent results (forward message pattern)
6. Report final workflow status and artifact locations

**YOU MUST NEVER**:
1. Execute tasks yourself using Read/Grep/Write/Edit tools
2. Invoke other commands via SlashCommand tool (/plan, /implement, /debug, /document)
3. Modify or create files directly (except in Phase 0 setup)
4. Skip mandatory verification checkpoints
5. Continue workflow after verification failure
```

**Problem**: Without the "EXECUTE NOW" directive, Claude interprets the bash code blocks as documentation/examples rather than executable instructions, causing it to skip Phase 0 and violate its architectural constraints by attempting direct tool execution.

### 4. Root Cause Analysis

**Why Master Branch Works** ✓:

1. **Bash Blocks as Guidance**: Without "EXECUTE NOW" directives, Claude treats bash blocks as documentation/guidance
2. **Intelligent Interpretation**: Claude understands the workflow intent and executes appropriately
3. **No BASH_SOURCE Issues**: Since bash code isn't executed literally inline, `BASH_SOURCE[0]` problem never occurs
4. **Proper Workflow Execution**: Command completes successfully without library sourcing failures

**Why spec_org Branch is Broken** ✗:

1. **Forced Inline Execution**: "EXECUTE NOW" directives force literal bash code execution
2. **Empty BASH_SOURCE[0]**: In inline execution context, `BASH_SOURCE[0]` is empty (not a script file path)
3. **Wrong SCRIPT_DIR Resolution**:
   ```bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   # Resolves to: /home/benjamin/.config (PWD)
   # Should be: /home/benjamin/.config/.claude/commands
   ```
4. **Library Path Calculation Fails**:
   ```bash
   # Looks for: /home/benjamin/.config/../lib/library-sourcing.sh
   # Which is: /home/benjamin/lib/library-sourcing.sh (DOESN'T EXIST)
   # Should be: /home/benjamin/.config/.claude/lib/library-sourcing.sh
   ```
5. **Cascading Failure**: Library sourcing fails → Phase 0 incomplete → workflow broken

### 5. Refactor Context

**User Context** (from `.claude/research_output.md:3-5`):
```
Note that this may be due to the recent refactor which removed the shims and
compatibility layers to reduce cruft and improve code quality.
```

**Analysis**: The refactor removed compatibility shims that may have previously ensured Phase 0 execution. The spec_org fix addresses this by making execution directives explicit and mandatory rather than relying on implicit behavior or compatibility code.

### 6. Verification of Fix

**Files Changed**: 1 file
**Lines Added**: 4 lines (2 directives × 2 instances)
**Total Diff**: 22 lines (including context and blank lines)

**Verification Commands**:
```bash
# Count EXECUTE NOW directives
$ grep -c "EXECUTE NOW" .claude/commands/coordinate.md
# Master: 7 instances
# Spec_org: 9 instances (+2)

# Verify Phase 0 directive location
$ grep -n "EXECUTE NOW.*Phase 0" .claude/commands/coordinate.md
# Master: (no results)
# Spec_org: 522:**EXECUTE NOW**: USE the Bash tool to execute the following Phase 0 setup:
```

## Recommendations

### 1. Revert spec_org Branch Changes (HIGH PRIORITY)

**Action**: Remove the "EXECUTE NOW" directives that break the /coordinate command.

**Rationale**:
- Master branch works correctly without these directives
- The directives cause `BASH_SOURCE[0]` resolution failures
- Library sourcing fails due to incorrect path calculation
- Simpler code (fewer directives) that actually works is preferable

**Options**:
```bash
# Option A: Revert to master
git checkout master

# Option B: Fix BASH_SOURCE issue in spec_org
# Add fallback for inline execution context (see recommendation #2)
```

### 2. Fix BASH_SOURCE Resolution if Keeping Directives (ALTERNATIVE)

**Action**: If "EXECUTE NOW" directives must be kept, add fallback for inline execution:

```bash
# Handle both script file and inline execution contexts
if [ -n "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  # Fallback for inline execution (BASH_SOURCE[0] is empty)
  SCRIPT_DIR="$(pwd)/.claude/commands"
fi
```

**Rationale**:
- Handles both script file execution and inline execution
- Library sourcing will work in both contexts
- More robust but adds complexity

### 3. Audit Other Commands for Similar Issues (MEDIUM PRIORITY)

**Action**: Check if other orchestration commands have similar "EXECUTE NOW" directives that might cause problems.

**Files to Check**:
- `.claude/commands/orchestrate.md`
- `.claude/commands/supervise.md`
- `.claude/commands/implement.md`

**Note**: Only check if these commands are also broken. If they work without the directives, leave them alone.

### 3. Document the "EXECUTE NOW" Pattern (MEDIUM PRIORITY)

**Action**: Add explicit guidance to Command Architecture Standards about when "EXECUTE NOW" directives are required.

**Location**: `.claude/docs/reference/command_architecture_standards.md`

**Content to Add**:
```markdown
### Standard N: Explicit Execution Directives

**Requirement**: All bash code blocks that MUST be executed (not just documented) require an "EXECUTE NOW" directive immediately before the code block.

**Format**:
\`\`\`markdown
**EXECUTE NOW**: USE the Bash tool to execute the following [description]:

\`\`\`bash
# executable bash code
\`\`\`
\`\`\`

**Rationale**: Without explicit directives, Claude may interpret code blocks as documentation/examples rather than executable instructions, causing command bootstrap failures.
```

### 4. Add Bootstrap Verification Tests (LOW PRIORITY)

**Action**: Create test cases that verify Phase 0 execution for all orchestration commands.

**Test Cases**:
```bash
# Test 1: Verify library sourcing occurs
test_coordinate_phase_0_execution() {
  output=$(/coordinate "test workflow" 2>&1)
  assert_contains "$output" "✓ All libraries loaded successfully"
}

# Test 2: Verify no prohibited tool usage
test_coordinate_tool_constraints() {
  output=$(/coordinate "test workflow" 2>&1)
  assert_not_contains "$output" "Search("
  assert_not_contains "$output" "Grep("
}
```

**Location**: `.claude/tests/test_orchestration_commands.sh`

## References

### Primary Files Analyzed

1. `/home/benjamin/.config/.claude/commands/coordinate.md:522` - Spec_org EXECUTE NOW directive for Phase 0
2. `/home/benjamin/.config/.claude/commands/coordinate.md:751` - Spec_org EXECUTE NOW directive for helper functions
3. `/home/benjamin/.config/.claude/lib/library-sourcing.sh:1-110` - Library sourcing implementation (identical both branches)
4. `/home/benjamin/.config/.claude/research_output.md:73-79` - Root cause analysis from /research command output
5. `/home/benjamin/.config/.claude/coordinate_output.md:1-91` - Failed /coordinate execution showing tool constraint violations

### Git References

```bash
# View complete diff
git diff master spec_org -- .claude/commands/coordinate.md

# Show added lines only
git diff master spec_org -- .claude/commands/coordinate.md | grep "^+" | grep -v "^+++"
# Result: +**EXECUTE NOW**: USE the Bash tool to execute the following Phase 0 setup:
# Result: +**EXECUTE NOW**: USE the Bash tool to define the following helper functions:

# Verify library file unchanged
git diff master spec_org -- .claude/lib/library-sourcing.sh
# Result: (no output - files identical)
```

### Command Architecture Standards

- `.claude/docs/reference/command_architecture_standards.md` - Standard 11: Imperative Agent Invocation Pattern
- `.claude/docs/concepts/patterns/behavioral-injection.md` - Behavioral Injection Pattern documentation
- `.claude/docs/concepts/patterns/verification-fallback.md` - Verification and Fallback Pattern documentation
