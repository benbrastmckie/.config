# Slash Command Execution Loop Detection Research Report

## Metadata
- **Date**: 2025-10-30
- **Agent**: research-specialist
- **Topic**: Slash Command Execution Loop Detection
- **Report Type**: codebase analysis
- **Parent Report**: [Research Overview](./OVERVIEW.md)

## Executive Summary

Claude Code's SlashCommand tool has NO built-in loop detection mechanisms at the tool level. Instead, the codebase implements recursion prevention through three architectural patterns: (1) allowed-tools frontmatter restrictions that exclude SlashCommand from most commands, (2) explicit prohibitions in command files stating "MUST NEVER invoke other commands via SlashCommand tool", and (3) validation tests that detect anti-patterns. Commands use the Task tool with behavioral injection instead of SlashCommand invocations to achieve hierarchical multi-agent coordination.

## Findings

### SlashCommand Tool Architecture

**Tool Capabilities** (based on web search and codebase analysis):

The SlashCommand tool enables Claude to programmatically invoke custom slash commands during execution. Key characteristics:

1. **Character Budget**: 15,000 characters (default) limits command descriptions in context
2. **Proactive Invocation**: Claude can invoke commands automatically if they have descriptions
3. **No Built-in Loop Detection**: The tool itself has NO safeguards against recursive invocations
4. **Command-Message Pattern**: Shows `<command-message>{name} is running...</command-message>` when command executes

**Evidence from Web Search**:
- GitHub Issue #4277 proposes a Loop Detection Service to monitor repetitive tool calls, indicating this is NOT currently implemented
- The `--max-turns` flag prevents infinite conversations but doesn't catch tight loops within a few turns
- Current design relies on behavioral constraints, not technical enforcement

**Evidence from Codebase**:
- CLAUDE.md line 124: "Commands invoke agents via Task tool with context injection (not SlashCommand)"
- No grep matches for built-in loop detection code or patterns like "command that is already running" warnings
- No system-level recursion tracking found in `.claude/lib/` utilities

### Built-in Loop Detection Mechanisms

**Finding: NO built-in loop detection exists in Claude Code's SlashCommand tool.**

**Evidence**:

1. **Web Search Results**:
   - GitHub Issue #4277 (Feature Request): "Implement Agentic Loop Detection Service to Prevent Repetitive Actions" - this is a FEATURE REQUEST, not an existing capability
   - Issue describes loops as "calling the same tool with identical arguments repeatedly"
   - Proposes monitoring agent behavior to halt loops early - NOT currently implemented

2. **Codebase Searches**:
   - Zero matches for: "Do not invoke a command that is already running"
   - Zero matches for: "command-message" loop detection logic
   - No state tracking for active command executions
   - No recursion counters or command stack validation

3. **Architectural Approach**:
   - Loop prevention is BEHAVIORAL, not TECHNICAL
   - Commands declare "MUST NEVER invoke other commands" (manual constraint)
   - Validation tests detect violations after-the-fact
   - No runtime enforcement layer exists

**Implication**: Commands can theoretically invoke themselves or create circular dependencies if behavioral guidelines are ignored or violated.

### Anti-Recursion Patterns in Existing Commands

The codebase implements three distinct anti-recursion patterns to prevent infinite loops:

#### Pattern 1: Frontmatter Tool Restrictions

**Mechanism**: Exclude SlashCommand from allowed-tools list in command frontmatter.

**Evidence**:
- `/coordinate` (line 2): `allowed-tools: Task, TodoWrite, Bash, Read` - NO SlashCommand
- `/supervise` (line 2): `allowed-tools: Task, TodoWrite, Bash, Read` - NO SlashCommand
- All agent files: ZERO agents have SlashCommand in allowed-tools

**Commands WITH SlashCommand access** (only 3 found):
1. `/setup` (line 2): `allowed-tools: Read, Write, Edit, MultiEdit, Bash, Grep, Glob, SlashCommand`
2. `/implement` (line 2): `allowed-tools: Read, Edit, MultiEdit, Write, Bash, Grep, Glob, TodoWrite, Task, SlashCommand`
3. `/revise` (line 6): `allowed-tools: Read, Write, Edit, Glob, Grep, Task, MultiEdit, TodoWrite, SlashCommand`

**Rationale**: These commands need SlashCommand for specific use cases (setup validation, adaptive replanning), but they have explicit constraints documented inline.

#### Pattern 2: Explicit Prohibition Sections

**Mechanism**: Dedicated "Architectural Prohibition: No Command Chaining" sections in orchestrator commands.

**Evidence from `/coordinate` (lines 68-132)**:

```markdown
## Architectural Prohibition: No Command Chaining

**CRITICAL PROHIBITION**: This command MUST NEVER invoke other commands via the SlashCommand tool.

### Why This Matters

**Wrong Pattern - Command Chaining** (causes context bloat and broken behavioral injection):

❌ INCORRECT - Do NOT do this:
SlashCommand with command: "/plan create auth feature"

**Problems with command chaining**:
1. **Context Bloat**: Entire /plan command prompt injected into your context (~2000 lines)
2. **Broken Behavioral Injection**: /plan's behavior not customizable via prompt
3. **Lost Control**: Cannot inject specific instructions or constraints
4. **No Metadata**: Get full output, not structured data for aggregation

**Correct Pattern - Direct Agent Invocation** (lean context, behavioral control):

✅ CORRECT - Do this instead
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Plan Path: ${PLAN_PATH} (absolute path, pre-calculated)
    ...
  "
}
```

**Key Points**:
- Lines 45-50: "YOU MUST NEVER: ... 2. Invoke other commands via SlashCommand tool"
- Lines 64-66: "TOOLS PROHIBITED: SlashCommand: NEVER invoke /plan, /implement, /debug, or any command"
- Lines 122-132: Enforcement instructions with STOP/IDENTIFY/DELEGATE workflow

**Also found in**:
- `/supervise` (lines 42-47): Identical prohibition structure
- All `/coordinate.md.backup-*` files: Pattern consistently maintained across refactors

#### Pattern 3: Validation Testing

**Mechanism**: Automated test scripts detect anti-patterns and enforce architectural compliance.

**Evidence from `/home/benjamin/.config/.claude/tests/validate_no_agent_slash_commands.sh`**:

```bash
# Lines 44-62: Detects artifact-creation slash commands in agent files
ARTIFACT_SLASH_COMMANDS=("/plan" "/report" "/debug" "/implement" "/orchestrate")

for cmd in "${ARTIFACT_SLASH_COMMANDS[@]}"; do
  # Match patterns: "invoke /plan", "use /plan", "call /plan", "run /plan"
  if grep -qiE "(invoke|use|call|run|execute)\s+${cmd}" "$agent_file" 2>/dev/null; then
    # ... report VIOLATION ...
  fi
done
```

**Purpose** (lines 82-86):
1. Remove SlashCommand tool invocations from agent files
2. Update agents to create artifacts directly using Write/Edit tools
3. Ensure commands pre-calculate paths and inject them into agent prompts
4. Reference: `.claude/docs/guides/agent-authoring-guide.md`

**Enforcement**:
- Runs as part of test suite (`.claude/tests/`)
- Detects violations in agent behavioral files
- Prevents agents from delegating work via slash commands
- Enforces direct artifact creation pattern

#### Pattern 4: Behavioral Injection Architecture

**Mechanism**: Commands orchestrate agents via Task tool + behavioral file reads, NOT SlashCommand invocations.

**Evidence from `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md`**:

Lines 21-30:
```markdown
Commands that invoke other commands using the SlashCommand tool create two critical problems:

1. **Role Ambiguity**: When a command says "I'll research the topic", Claude interprets
   this as "I should execute research directly using Read/Grep/Write tools" instead of
   "I should orchestrate agents to research". This prevents hierarchical multi-agent patterns.

2. **Context Bloat**: Command-to-command invocations nest full command prompts within
   parent prompts, causing exponential context growth and breaking metadata-based context reduction.

Behavioral Injection solves both problems by:
- Making the orchestrator role explicit: "YOU ARE THE ORCHESTRATOR. DO NOT execute yourself."
- Injecting all necessary context into agent files: paths, constraints, specifications
- Enabling agents to read context and self-configure without tool invocations
```

**Key Architectural Decisions**:
- Lines 47-62: Every orchestrator has "YOUR ROLE" section declaring "DO NOT execute implementation work yourself"
- Lines 64-81: Pre-calculate ALL paths before agent invocation (Phase 0 pattern)
- Lines 84-102: Inject context via structured data in Task prompts, NOT via SlashCommand
- Lines 104-147: Real implementation example from Plan 080

**Benefits** (line 34-37):
- 100% file creation rate through explicit path injection
- <30% context usage by avoiding nested command prompts
- Hierarchical multi-agent coordination through clear role separation
- Parallel execution through independent context injection per agent

### Architectural Principles Summary

**How Recursion is Prevented**:

1. **Tool Access Control**: Only 3 commands have SlashCommand access, and they have explicit use-case documentation
2. **Behavioral Constraints**: Orchestrator commands explicitly prohibit self-invocation with side-by-side wrong/correct examples
3. **Automated Validation**: Tests scan for anti-patterns and enforce architectural compliance
4. **Alternative Pattern**: Task tool + behavioral injection replaces SlashCommand for agent coordination

**Why No Technical Enforcement**:
- Claude Code trusts LLM to follow documented behavioral constraints
- Frontmatter `allowed-tools` provides permission boundary
- Validation tests catch violations during development
- Architectural patterns guide correct usage

**Current Gap**:
- NO runtime loop detection at SlashCommand tool level
- Relies on LLM adherence to "MUST NEVER" instructions
- If LLM ignores prohibitions, infinite loops are possible (current /coordinate bug is evidence)

## Recommendations

### Recommendation 1: Implement Runtime Command Stack Tracking

**Problem**: SlashCommand tool has no built-in recursion detection. If behavioral constraints are violated, infinite loops occur.

**Solution**: Add command execution stack tracking to detect re-entrant invocations.

**Implementation Approach**:
```bash
# In .claude/lib/command-stack.sh
declare -g COMMAND_STACK=()

function enter_command() {
  local cmd_name="$1"

  # Check if command already in stack
  for active_cmd in "${COMMAND_STACK[@]}"; do
    if [[ "$active_cmd" == "$cmd_name" ]]; then
      echo "ERROR: Recursive invocation detected: $cmd_name is already running" >&2
      echo "Command stack: ${COMMAND_STACK[*]}" >&2
      exit 1
    fi
  done

  # Add to stack
  COMMAND_STACK+=("$cmd_name")
}

function exit_command() {
  # Remove last item from stack
  unset 'COMMAND_STACK[-1]'
}
```

**Integration Points**:
- Source in commands with SlashCommand access (/setup, /implement, /revise)
- Call `enter_command "coordinate"` at start of execution
- Call `exit_command` before final return
- Add to Phase 0 execution blocks

**Priority**: HIGH - Prevents infinite loops at runtime, not just via behavioral constraints

### Recommendation 2: Strengthen Frontmatter Enforcement

**Problem**: `allowed-tools` frontmatter is documentation, not technical enforcement. Claude can ignore it.

**Solution**: Add explicit verification step to Phase 0 of all orchestrator commands.

**Implementation**:
```markdown
## Phase 0: Self-Verification

**EXECUTE NOW - Verify Tool Access**:

```bash
# Verify this command does NOT have SlashCommand access
FRONTMATTER=$(head -10 "$0" 2>/dev/null || echo "")
if echo "$FRONTMATTER" | grep -q "allowed-tools:.*SlashCommand"; then
  echo "CRITICAL ERROR: This command has SlashCommand access but should NOT"
  echo "Remove SlashCommand from allowed-tools frontmatter"
  exit 1
fi

echo "✓ Verified: No SlashCommand access (recursion prevention active)"
```

**Why This Helps**:
- Fail-fast if frontmatter is incorrectly modified
- Makes tool restrictions executable, not just documentation
- Provides clear error message if violation occurs

**Priority**: MEDIUM - Defense-in-depth layer

### Recommendation 3: Enhance Validation Test Coverage

**Problem**: Current validation tests only scan agent files, not command files.

**Solution**: Extend `validate_no_agent_slash_commands.sh` to also validate orchestrator commands.

**Implementation**:
```bash
# Add to validate_no_agent_slash_commands.sh after agent scanning

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Orchestrator Commands: Self-Invocation Detection"
echo "════════════════════════════════════════════════════════════"

ORCHESTRATOR_COMMANDS=("coordinate" "orchestrate" "supervise")

for cmd in "${ORCHESTRATOR_COMMANDS[@]}"; do
  cmd_file="${PROJECT_ROOT}/.claude/commands/${cmd}.md"

  if [ ! -f "$cmd_file" ]; then
    continue
  fi

  # Check for SlashCommand invocations of orchestration commands
  for target_cmd in "${ORCHESTRATOR_COMMANDS[@]}"; do
    if grep -qE "SlashCommand.*['\"]/${target_cmd}" "$cmd_file" 2>/dev/null; then
      echo -e "${RED}✗ ${cmd}.md invokes /${target_cmd} via SlashCommand${NC}"
      VIOLATIONS=$((VIOLATIONS + 1))
    fi
  done
done
```

**Priority**: MEDIUM - Catches accidental self-invocations during development

### Recommendation 4: Add Execution Tracing for Debugging

**Problem**: When loops occur, there's no execution history to diagnose the root cause.

**Solution**: Add lightweight execution tracing to orchestrator commands.

**Implementation**:
```bash
# In .claude/lib/execution-trace.sh
TRACE_LOG=".claude/data/logs/execution-trace.log"

function log_command_entry() {
  local cmd_name="$1"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] ENTER: $cmd_name (stack depth: ${#COMMAND_STACK[@]})" >> "$TRACE_LOG"
}

function log_command_exit() {
  local cmd_name="$1"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] EXIT: $cmd_name" >> "$TRACE_LOG"
}
```

**Usage in commands**:
```bash
source .claude/lib/execution-trace.sh
log_command_entry "coordinate"

# ... command execution ...

log_command_exit "coordinate"
```

**Debugging Value**:
- Provides audit trail of command invocations
- Shows stack depth at each invocation (detects growing depth)
- Enables post-mortem analysis of infinite loops
- Low overhead (append-only file writes)

**Priority**: LOW - Diagnostic aid, not prevention mechanism

### Recommendation 5: Document Loop Detection Limitations in CLAUDE.md

**Problem**: Users and LLM may assume loop detection exists when it doesn't.

**Solution**: Add explicit section to CLAUDE.md explaining recursion prevention approach.

**Proposed Content**:
```markdown
## Recursion Prevention and Loop Detection

### Current Approach

Claude Code prevents command recursion through BEHAVIORAL constraints, not technical enforcement:

1. **Frontmatter Restrictions**: Orchestrator commands exclude SlashCommand from allowed-tools
2. **Explicit Prohibitions**: "MUST NEVER invoke other commands via SlashCommand tool" sections
3. **Validation Tests**: Automated scanning detects anti-patterns in agent and command files
4. **Architectural Pattern**: Task tool + behavioral injection replaces SlashCommand for delegation

### Limitations

**NO runtime loop detection exists**:
- SlashCommand tool has no built-in recursion tracking
- If LLM ignores behavioral constraints, infinite loops are possible
- Detection happens via validation tests (development) or user observation (runtime)

### If a Loop Occurs

1. **Interrupt execution**: Stop the command manually
2. **Check trace logs**: Review `.claude/data/logs/execution-trace.log` (if implemented)
3. **Verify frontmatter**: Ensure orchestrator commands exclude SlashCommand
4. **Review command file**: Check for accidental SlashCommand invocations
5. **Report issue**: File bug report with execution context
```

**Priority**: HIGH - Sets correct expectations and provides troubleshooting guidance

## References

### Codebase Files Analyzed

1. `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 2, 45-50, 64-132)
   - Frontmatter tool restrictions (line 2)
   - Explicit prohibition of SlashCommand usage (lines 68-132)
   - YOUR ROLE orchestrator pattern (lines 45-50)

2. `/home/benjamin/.config/.claude/commands/supervise.md` (lines 42-47)
   - Identical architectural prohibition section
   - Orchestrator role declaration

3. `/home/benjamin/.config/.claude/commands/setup.md` (line 2)
   - One of three commands with SlashCommand access
   - Used for validation and setup workflows

4. `/home/benjamin/.config/.claude/commands/implement.md` (line 2)
   - SlashCommand access for adaptive replanning (/revise --auto-mode)

5. `/home/benjamin/.config/.claude/commands/revise.md` (line 6)
   - SlashCommand access for plan revision workflows

6. `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` (lines 1-200)
   - Complete architectural pattern documentation
   - Role separation principles (lines 14-16)
   - Problems with SlashCommand invocations (lines 21-30)
   - Benefits of Task tool + behavioral injection (lines 34-37)

7. `/home/benjamin/.config/.claude/tests/validate_no_agent_slash_commands.sh` (lines 1-95)
   - Validation test for anti-pattern detection
   - Scans agent files for slash command invocations (lines 44-62)
   - Fix instructions (lines 82-86)

8. `/home/benjamin/.config/.claude/agents/*.md` (all 17 agent files)
   - ZERO agents have SlashCommand in allowed-tools frontmatter
   - All agents use Read/Write/Edit/Grep/Glob/Bash only

9. `/home/benjamin/.config/CLAUDE.md` (line 124)
   - High-level architectural principle documentation

10. `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (lines 1-100)
    - Standard 0: Execution Enforcement principles
    - Imperative vs descriptive language patterns

### Web Search Sources

1. GitHub Issue #4277: "Feature Request: Implement Agentic Loop Detection Service to Prevent Repetitive Actions"
   - URL: https://github.com/anthropics/claude-code/issues/4277
   - Status: Feature request (NOT implemented)
   - Proposes monitoring agent behavior to halt repetitive loops

2. Claude Code Best Practices (Anthropic Engineering Blog)
   - URL: https://www.anthropic.com/engineering/claude-code-best-practices
   - SlashCommand tool character budget (15,000 chars default)
   - Proactive command invocation capabilities

3. Claude Docs - Slash Commands
   - URL: https://docs.claude.com/en/docs/claude-code/slash-commands
   - SlashCommand tool functionality and limitations
   - Command-message pattern documentation

### Pattern Documentation

1. Behavioral Injection Pattern: `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md`
2. Command Architecture Standards: `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md`
3. Agent Development Guide: `/home/benjamin/.config/.claude/docs/guides/agent-development-guide.md`
4. Command Development Guide: `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md`
