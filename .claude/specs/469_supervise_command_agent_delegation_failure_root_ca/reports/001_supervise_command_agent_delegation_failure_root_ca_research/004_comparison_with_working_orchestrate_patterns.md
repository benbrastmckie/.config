# Comparison with Working Orchestrate Patterns

## Metadata
- **Date**: 2025-10-24
- **Agent**: research-specialist
- **Topic**: Comparison of /orchestrate (working) vs /supervise (failing) agent delegation patterns
- **Report Type**: Pattern comparison and root cause identification

## Executive Summary

The /orchestrate command successfully delegates to agents with a 100% delegation rate, while /supervise has a 0% delegation rate. Analysis reveals critical structural differences in how Task invocations are presented: orchestrate uses unwrapped YAML blocks with imperative instructions ("**EXECUTE NOW**"), while supervise wraps all Task invocations in markdown code fences (` ```yaml`), causing Claude to interpret them as documentation examples rather than executable instructions.

## Findings

### 1. Task Invocation Structure Differences

#### /orchestrate Pattern (Working - 100% Delegation Rate)

**Location**: Lines 754-804, 865-937, 1085-1095, 1553-1627 in orchestrate.md

**Structure Characteristics**:
- Task blocks are NOT wrapped in markdown code fences
- Direct imperative instructions precede Task invocations
- Uses "**EXECUTE NOW**" markers
- Clear instruction: "USE the Task tool to invoke..."

**Example from orchestrate.md** (Line 754):
```
**EXACT AGENT PROMPT TEMPLATE** (Copy verbatim for EACH research agent):

Task {
  subagent_type: "general-purpose"
  description: "Research [TOPIC] with mandatory artifact creation"
  timeout: 300000
  prompt: "
    **ABSOLUTE REQUIREMENT - File Creation is Your Primary Task**
    ...
  "
}
```

**Key Pattern Elements**:
1. No ` ```yaml` wrapper around Task block
2. Imperative header: "**EXACT AGENT PROMPT TEMPLATE**"
3. Explicit instruction to copy verbatim
4. Task block appears as executable instruction, not documentation

#### /supervise Pattern (Failing - 0% Delegation Rate)

**Location**: Lines 62-79, 741-756, 1010-1026, 1207-1223, 1328-1346, 1444-1537, 1561-1646, 1658-1682, 1760-1776 in supervise.md

**Structure Characteristics**:
- Task blocks wrapped in ` ```yaml` markdown code fences
- Imperative instructions present but follow code fence
- Uses "**EXECUTE NOW**" markers
- Clear instruction: "USE the Task tool to invoke..."

**Example from supervise.md** (Line 62-79):
```
**Correct Pattern - Direct Agent Invocation** (lean context, behavioral control):
```yaml
# ✅ CORRECT - Do this instead
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md
    ...
  "
}
```
```

**Key Pattern Differences**:
1. ` ```yaml` wrapper around Task block
2. Imperative header present but separated by code fence
3. Task block appears as documentation example, not executable instruction
4. Code fence creates visual barrier between instruction and Task invocation

### 2. Imperative Instruction Placement

#### /orchestrate (Working)

**Pattern**: Imperative instructions IMMEDIATELY precede unwrapped Task blocks

**Examples**:

1. **Line 736-752**:
   ```
   **EXACT AGENT PROMPT TEMPLATE** (Copy verbatim for EACH research agent):

   Task {
     subagent_type: "general-purpose"
     ...
   }
   ```

2. **Line 1082-1090**:
   ```
   **EXECUTE NOW - Invoke research-synthesizer Agent**:

   Task {
     subagent_type: "general-purpose"
     ...
   }
   ```

**Observation**: No code fences create separation between instruction and Task invocation. Imperative language ("**EXECUTE NOW**") directly connects to Task block.

#### /supervise (Failing)

**Pattern**: Imperative instructions precede code-fenced Task blocks

**Examples**:

1. **Line 739-756**:
   ```
   **EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

   Task {
     subagent_type: "general-purpose"
     ...
   }
   ```
   Note: This appears as unwrapped in the command file, BUT...

2. **Line 62-79**:
   ```
   **Correct Pattern - Direct Agent Invocation** (lean context, behavioral control):
   ```yaml
   # ✅ CORRECT - Do this instead
   Task {
     subagent_type: "general-purpose"
     ...
   }
   ```
   ```

**Observation**: The example sections (Lines 62-79) show "correct pattern" with code fences, potentially establishing a documentation-only interpretation pattern. When actual Task invocations appear (Lines 741, 1010, 1207, etc.), they are UNWRAPPED but Claude may have already been primed to interpret them as examples.

### 3. Behavioral File Reference Format

#### Both Commands (Identical)

**Format**: `.claude/agents/[agent-name].md`

**Examples**:
- orchestrate.md Line 1090: `.claude/agents/research-specialist.md`
- supervise.md Line 745: `.claude/agents/research-specialist.md`

**Observation**: No difference in behavioral file reference format. This is NOT the failure point.

### 4. Library Sourcing Patterns

#### /orchestrate (Working)

**Location**: Lines 239-269

**Pattern**:
```bash
# Source Required Utilities
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"

# Verify utilities exist
[ -f "$UTILS_DIR/error-handling.sh" ] || { echo "ERROR: error-handling.sh not found"; exit 1; }
[ -f "$UTILS_DIR/checkpoint-utils.sh" ] || { echo "ERROR: checkpoint-utils.sh not found"; exit 1; }

# Source utilities
source "$UTILS_DIR/error-handling.sh"
source "$UTILS_DIR/checkpoint-utils.sh"
```

**Characteristics**:
- Not wrapped in code fences (markdown code block)
- Direct bash commands
- Presented as executable instructions

#### /supervise (Failing)

**Location**: Lines 217-277

**Pattern**:
```
```bash
# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source workflow detection utilities
if [ -f "$SCRIPT_DIR/../lib/workflow-detection.sh" ]; then
  source "$SCRIPT_DIR/../lib/workflow-detection.sh"
else
  echo "ERROR: workflow-detection.sh not found"
  exit 1
fi
```
```

**Characteristics**:
- Wrapped in ` ```bash` markdown code fences
- All library sourcing wrapped as documentation
- Presented as examples, not executable instructions

**Observation**: Library sourcing wrapped in code fences in supervise, unwrapped in orchestrate.

### 5. Code Fence Usage Analysis

#### /orchestrate Pattern

**Wrapped in Code Fences**:
- Examples showing WRONG patterns (Lines 10-35: HTML comments showing anti-patterns)
- Checkpoint structure examples (documentation sections)
- Example outputs (logging pattern examples)

**NOT Wrapped in Code Fences**:
- **Task invocation blocks** (Lines 754, 865, 883, 907, 1085, 1553, 1586, 1627)
- Library sourcing commands (Lines 239-259)
- Bash execution blocks for path calculation

**Pattern**: Executable instructions unwrapped, documentation examples wrapped.

#### /supervise Pattern

**Wrapped in Code Fences**:
- Library sourcing (Lines 217-277) - **SHOULD BE UNWRAPPED**
- Task invocation examples (Lines 62-79) - Showing "correct pattern"
- Verification bash blocks (Lines 790-859, 1036-1109)
- All phase execution bash code

**NOT Wrapped in Code Fences**:
- Task invocations (Lines 741-756, 1010-1026, etc.) - **BUT PRIMED AS DOCUMENTATION**

**Pattern Inconsistency**: Mixed wrapping creates ambiguity. Example sections use code fences for Task blocks, establishing documentation-only interpretation.

### 6. Root Cause Hypothesis

**PRIMARY ROOT CAUSE**: Code fence usage establishes documentation vs. execution context

**Evidence**:

1. **Priming Effect** (Lines 62-79 in supervise.md):
   - Shows "Correct Pattern - Direct Agent Invocation" wrapped in ` ```yaml`
   - Labeled with "# ✅ CORRECT - Do this instead"
   - Claude interprets this as documentation example, not instruction
   - When actual Task blocks appear later (unwrapped), Claude has been primed to treat them as examples

2. **Contrast with orchestrate.md**:
   - orchestrate uses HTML comments for anti-pattern documentation (Lines 10-36)
   - Never shows Task invocations wrapped in code fences
   - All Task blocks appear as direct imperative instructions
   - No priming effect establishes Task blocks as documentation

3. **Library Sourcing Parallel** (Lines 217-277 in supervise.md):
   - All bash library sourcing wrapped in ` ```bash` fences
   - Presented as "how to do it" examples, not "do it now" instructions
   - Creates consistent documentation interpretation pattern

### 7. Pattern Comparison Table

| Aspect | /orchestrate (Working) | /supervise (Failing) | Impact |
|--------|----------------------|---------------------|--------|
| Task Invocation Wrapping | Unwrapped | Unwrapped (but primed as docs) | **CRITICAL** |
| Example Sections | No Task examples with code fences | Task examples wrapped in ` ```yaml` | **CRITICAL** |
| Library Sourcing | Unwrapped bash | Wrapped in ` ```bash` | High |
| Imperative Instructions | Directly before Task blocks | Directly before Task blocks | Same |
| Behavioral File Format | `.claude/agents/*.md` | `.claude/agents/*.md` | Same |
| "EXECUTE NOW" Usage | Present | Present | Same |
| Code Fence Philosophy | Examples only | Mixed (creates ambiguity) | **CRITICAL** |

### 8. Documentation Pattern Analysis

#### /orchestrate Documentation Strategy

**Pattern**: External reference files for supplemental content

**Examples**:
- Line 76-98: References `.claude/templates/orchestration-patterns.md`
- Line 273: "**See comprehensive patterns in**: `.claude/templates/orchestration-patterns.md#error-recovery-patterns`"
- Line 302: "**See comprehensive patterns in**: `.claude/docs/logging-patterns.md#progress-markers`"

**Philosophy**: Keep command file lean with executable instructions, move documentation to external files.

#### /supervise Documentation Strategy

**Pattern**: Inline examples with code fences

**Examples**:
- Line 62-79: Inline "Correct Pattern" example wrapped in ` ```yaml`
- Line 217-277: Inline library sourcing example wrapped in ` ```bash`
- Line 342-404: Inline workflow scope detection example wrapped in ` ```bash`

**Philosophy**: Show examples inline within command file for educational purposes.

**Observation**: Inline documentation creates ambiguity between "example" and "instruction" when using code fences.

## Recommendations

### 1. REMOVE Code Fences from All Task Invocation Examples (CRITICAL)

**Action**: Remove ` ```yaml` wrappers from Task invocation examples in supervise.md

**Affected Lines**:
- Lines 62-79: Example showing "Correct Pattern - Direct Agent Invocation"
- Any other Task examples used for documentation purposes

**Rationale**: Code fences establish "documentation example" interpretation pattern. Removing them ensures Task blocks are always interpreted as executable instructions.

**Alternative**: If documentation examples are needed, use HTML comments (like orchestrate.md Lines 10-36) or move to external reference files.

### 2. UNWRAP Library Sourcing Bash Blocks (HIGH PRIORITY)

**Action**: Remove ` ```bash` wrappers from all library sourcing code (Lines 217-277)

**Rationale**: Wrapped bash creates consistent documentation interpretation. Unwrapping signals "execute this now" vs "this is how to do it."

### 3. Adopt External Reference Pattern for Documentation (MEDIUM PRIORITY)

**Action**: Move inline examples to external reference files (`.claude/docs/supervise-patterns.md`)

**Benefits**:
- Clear separation between executable instructions and documentation
- Reduced command file size (currently 1,938 lines)
- Consistent with orchestrate pattern (5,443 lines but more complex workflow)
- Eliminates ambiguity between examples and instructions

### 4. Use HTML Comments for Anti-Pattern Documentation (LOW PRIORITY)

**Action**: If inline anti-pattern examples needed, use HTML comment blocks like orchestrate.md (Lines 10-36)

**Rationale**: HTML comments are invisible to Claude during execution but visible to human readers of the markdown source.

## Related Reports

- [Overview Report](./OVERVIEW.md) - Comprehensive synthesis of all root cause analysis findings

## References

### Files Analyzed
- `/home/benjamin/.config/.claude/commands/orchestrate.md` (5,443 lines)
- `/home/benjamin/.config/.claude/commands/supervise.md` (1,938 lines)
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (671 lines)

### Key Line References

**orchestrate.md**:
- Lines 754-804: Unwrapped Task invocation template
- Lines 865-937: Auto-retry with unwrapped Task blocks
- Lines 1085-1095: Research synthesizer Task invocation
- Lines 239-269: Unwrapped library sourcing
- Lines 10-36: HTML comment anti-pattern documentation

**supervise.md**:
- Lines 62-79: Code-fenced Task example (PROBLEMATIC)
- Lines 217-277: Code-fenced library sourcing (PROBLEMATIC)
- Lines 741-756: Unwrapped Task invocation (primed as documentation)
- Lines 1010-1026: Unwrapped Task invocation (primed as documentation)
- Lines 1207-1223: Unwrapped Task invocation (primed as documentation)

### Pattern Documentation
- `.claude/templates/orchestration-patterns.md` (referenced by orchestrate)
- `.claude/docs/concepts/patterns/behavioral-injection.md` (behavioral injection pattern)
- `.claude/docs/reference/command_architecture_standards.md` (Standard 11: Imperative Agent Invocation)
