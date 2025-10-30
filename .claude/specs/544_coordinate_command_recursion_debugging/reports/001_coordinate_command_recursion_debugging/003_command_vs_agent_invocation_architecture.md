# Command vs Agent Invocation Architecture

## Metadata
- **Date**: 2025-10-30
- **Agent**: research-specialist
- **Topic**: Command vs Agent Invocation Architecture
- **Report Type**: Architecture Analysis
- **Context**: Understanding when to use SlashCommand vs Task tool to prevent recursion
- **Parent Report**: [Research Overview](./OVERVIEW.md)

## Executive Summary

The Claude Code architecture distinguishes between two fundamentally different invocation patterns: **SlashCommand tool** (for invoking other slash commands) and **Task tool** (for invoking agents via behavioral injection). This distinction is critical for preventing command recursion, maintaining clean separation of concerns, and enabling hierarchical multi-agent coordination. Commands like `/coordinate` should use the Task tool with behavioral injection to invoke specialized agents (research-specialist, plan-architect, etc.) rather than using SlashCommand to invoke other commands (/plan, /implement). This architectural pattern provides 90% context reduction, 100% file creation reliability, and prevents infinite command recursion loops.

## Findings

### 1. Tool Purpose and Scope

**SlashCommand Tool**:
- **Purpose**: Invoke other slash commands defined in `.claude/commands/*.md`
- **Usage**: User-facing workflows, command composition, high-level task delegation
- **Context**: Loads entire command file into execution context
- **Example**: User types `/plan create auth feature` → SlashCommand expands plan.md into execution context
- **File**: Command Architecture Standards, line 1242-1307

**Task Tool**:
- **Purpose**: Invoke specialized agents with behavioral injection
- **Usage**: Orchestrator commands delegating work to subagents
- **Context**: Injects workflow-specific context into agent behavioral guidelines
- **Example**: `/coordinate` invokes `research-specialist` agent with injected report path
- **File**: Behavioral Injection Pattern, line 18-42

### 2. Architectural Patterns

**Orchestrator Role** (uses Task tool):
```markdown
## YOUR ROLE: WORKFLOW ORCHESTRATOR

**YOU ARE THE ORCHESTRATOR** for this multi-agent workflow.

**YOUR RESPONSIBILITIES**:
1. Pre-calculate ALL artifact paths before any agent invocations
2. Determine workflow scope (research-only, research-and-plan, full-implementation)
3. Invoke specialized agents via Task tool with complete context injection
4. Verify agent outputs at mandatory checkpoints
5. Extract and aggregate metadata from agent results

**YOU MUST NEVER**:
1. Execute tasks yourself using Read/Grep/Write/Edit tools
2. Invoke other commands via SlashCommand tool (/plan, /implement, /debug)
3. Modify or create files directly (except in Phase 0 setup)
```
*Source: /home/benjamin/.config/.claude/commands/coordinate.md, lines 33-50*

**Executor Role** (invoked via Task tool):
```markdown
**STEP 1 (REQUIRED BEFORE STEP 2) - Receive and Verify Report Path**

The invoking command MUST provide you with an absolute report path. Verify you have received it:

**CHECKPOINT**: YOU MUST have an absolute path before proceeding to Step 2.

**STEP 2 (REQUIRED BEFORE STEP 3) - Create Report File FIRST**

**EXECUTE NOW - Create Report File**

**ABSOLUTE REQUIREMENT**: YOU MUST create the report file NOW using the Write tool.
```
*Source: /home/benjamin/.config/.claude/agents/research-specialist.md, lines 24-78*

### 3. Anti-Pattern: Command Chaining via SlashCommand

**Problem Pattern**:
```markdown
❌ INCORRECT - Command chaining causes recursion and context bloat:

## Phase 2: Planning

I'll create an implementation plan for the researched topics.

SlashCommand tool invocation:
{
  "command": "/plan Implement OAuth 2.0 authentication"
}
```
*Source: Behavioral Injection Pattern, lines 618-631*

**Why This Fails**:
1. **Context Bloat**: Entire `/plan` command prompt (~2000 lines) injected into orchestrator context
2. **Broken Behavioral Injection**: /plan's behavior not customizable via prompt
3. **Lost Control**: Cannot inject specific instructions or constraints
4. **No Metadata**: Get full output, not structured data for aggregation
5. **Recursion Risk**: If /plan also uses SlashCommand to invoke /implement, creates infinite loop
*Source: Behavioral Injection Pattern, lines 18-29; coordinate.md lines 74-84*

**Concrete Example from /coordinate**:
```markdown
**CRITICAL PROHIBITION**: This command MUST NEVER invoke other commands via the SlashCommand tool.

**Wrong Pattern - Command Chaining** (causes context bloat and broken behavioral injection):

❌ INCORRECT - Do NOT do this:
SlashCommand with command: "/plan create auth feature"

**Problems with command chaining**:
1. **Context Bloat**: Entire /plan command prompt injected into your context (~2000 lines)
2. **Broken Behavioral Injection**: /plan's behavior not customizable via prompt
3. **Lost Control**: Cannot inject specific instructions or constraints
4. **No Metadata**: Get full output, not structured data for aggregation
```
*Source: /home/benjamin/.config/.claude/commands/coordinate.md, lines 68-84*

### 4. Correct Pattern: Direct Agent Invocation via Task Tool

**Solution Pattern**:
```markdown
✅ CORRECT - Direct agent invocation with behavioral injection:

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Plan Path: ${PLAN_PATH} (absolute path, pre-calculated)
    - Research Reports: [list of paths]
    - Project Standards: [path to CLAUDE.md]

    Execute planning following all guidelines in behavioral file.
    Return: PLAN_CREATED: ${PLAN_PATH}
  "
}
```
*Source: /home/benjamin/.config/.claude/commands/coordinate.md, lines 86-100*

**Benefits**:
1. **90% Context Reduction**: 150 lines of context injection vs 2000 lines of full command prompt
2. **Single Source of Truth**: Agent behavioral file is authoritative
3. **No Synchronization Needed**: Updates to behavioral file automatically apply
4. **Cleaner Commands**: Focus on orchestration, not behavioral details
5. **100% File Creation**: Pre-calculated paths ensure artifacts created at correct locations
*Source: Behavioral Injection Pattern, lines 294-323*

### 5. Phase 0 Requirement: Path Pre-Calculation

**Why Phase 0 Matters**:

Every orchestrator command MUST include Phase 0 (before invoking any subagents) to pre-calculate artifact paths:

```bash
## Phase 0: Pre-Calculate Artifact Paths and Topic Directory

**EXECUTE NOW - Topic Directory Determination**

source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"

# Determine topic directory
WORKFLOW_DESC="$1"  # From user input
TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESC" ".claude/specs")
# Result: .claude/specs/042_workflow_description/

# Create subdirectories
mkdir -p "$TOPIC_DIR"/{reports,plans,summaries,debug,scripts,outputs}

# Pre-calculate artifact paths
RESEARCH_REPORT_BASE="$TOPIC_DIR/reports"
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")
SUMMARY_PATH=$(create_topic_artifact "$TOPIC_DIR" "summaries" "workflow_summary" "")

# Export for subagent injection
export TOPIC_DIR RESEARCH_REPORT_BASE PLAN_PATH SUMMARY_PATH

echo "✓ Topic directory: $TOPIC_DIR"
echo "✓ Artifact paths calculated"
```
*Source: Command Architecture Standards, lines 334-369*

**Without Phase 0**:
- Agents calculate their own paths → Orchestrator loses control
- No predictable artifact locations → Cannot verify file creation
- Cannot extract metadata before full content loaded → Context bloat
- Recursion risk if agents invoke other commands

**With Phase 0**:
- Orchestrator controls all paths → 100% file creation reliability
- Predictable locations → Verification checkpoints work
- Metadata extraction possible → 95% context reduction
- Clear role separation → No recursion

### 6. Recursion Prevention Through Role Separation

**Recursion Anti-Pattern**:
```
/coordinate → SlashCommand("/plan") → SlashCommand("/implement") → SlashCommand("/test") → ...
```

**Problems**:
1. Each command loads full prompt into context
2. No clear termination condition
3. Stack overflow if circular dependencies exist
4. Lost control over execution flow

**Correct Pattern (Role Separation)**:
```
/coordinate (Orchestrator)
  ├─> Task(research-specialist) → Creates report.md
  ├─> Task(plan-architect) → Creates plan.md
  ├─> Task(implementation-executor) → Modifies code files
  ├─> Task(test-runner) → Executes tests
  └─> Task(doc-writer) → Updates documentation
```

**Benefits**:
1. Each agent has single responsibility
2. Clear termination: agent returns metadata, orchestrator continues
3. No circular dependencies: agents don't invoke other agents
4. Full control: orchestrator dictates execution order
*Source: CLAUDE.md, lines 263-318; Behavioral Injection Pattern, lines 618-675*

### 7. Case Studies: Real-World Violations and Fixes

**Spec 495: /coordinate Agent Delegation Failures**

**Problem**: 0% agent delegation rate despite correct Task tool syntax
**Root Cause**: Documentation-only YAML blocks wrapped in markdown code fences

**Before** (broken):
```markdown
The research phase invokes research-specialist agents:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME}"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
}
```
```

**After** (fixed):
```markdown
**EXECUTE NOW**: USE the Task tool NOW with these parameters:

- subagent_type: "general-purpose"
- description: "Research authentication patterns for REST APIs"
- prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    Research topic: Authentication patterns for REST APIs
    Output file: [insert $report_path from above]
```

**Results**:
- Delegation rate: 0% → >90%
- File creation: 0 files → 100% in correct locations
- Context reduction: N/A → 90% per invocation
*Source: Behavioral Injection Pattern, lines 676-823*

**Spec 057: /supervise Bootstrap Robustness**

**Problem**: Bootstrap failures hidden by fallback mechanisms
**Root Cause**: Silent fallback functions masking configuration errors

**Before** (broken):
```bash
if ! source .claude/lib/workflow-detection.sh; then
  # Fallback function - HIDES THE ERROR
  detect_workflow_scope() { echo "research-only"; }
fi
```

**After** (fixed):
```bash
if ! source .claude/lib/workflow-detection.sh; then
  echo "ERROR: Failed to source workflow-detection.sh"
  echo "EXPECTED PATH: $SCRIPT_DIR/.claude/lib/workflow-detection.sh"
  echo "DIAGNOSTIC: ls -la $SCRIPT_DIR/.claude/lib/workflow-detection.sh"
  echo "CONTEXT: Library required for workflow scope detection"
  echo "ACTION: Verify library file exists and is readable"
  exit 1
fi
```

**Results**:
- Error visibility: Silent failures → Explicit diagnostic messages
- Fallback removal: 32 lines removed
- Bootstrap reliability: 100% (fail-fast exposes errors immediately)
*Source: Behavioral Injection Pattern, lines 841-1030*

## Recommendations

### 1. Use Task Tool for All Workflow Orchestration

**When to use Task tool**:
- Coordinating multi-step workflows (research → plan → implement)
- Delegating specialized tasks to agents (research, planning, implementation)
- Creating artifacts at specific paths
- Building hierarchical agent structures (supervisor → sub-supervisors → workers)

**Pattern**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke [agent-name] agent.

Task {
  subagent_type: "general-purpose"
  description: "[Task description with mandatory file creation]"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/[agent-name].md

    **Workflow-Specific Context**:
    - [Parameter 1]: [Value from Phase 0]
    - [Parameter 2]: [Value from Phase 0]

    Execute [task] following all guidelines in behavioral file.
    Return: [COMPLETION_SIGNAL]: [ARTIFACT_PATH]
  "
}
```
*Recommendation synthesized from Command Architecture Standards, lines 1127-1307; Behavioral Injection Pattern, lines 39-174*

### 2. Reserve SlashCommand Tool for User-Facing Workflows

**When to use SlashCommand tool**:
- User explicitly requests a command by name (`/plan`, `/implement`, `/debug`)
- Top-level command composition (NOT within orchestration commands)
- Interactive workflows where user makes decisions between steps
- One-off utilities that don't require coordination

**Anti-pattern to avoid**:
```markdown
❌ NEVER use SlashCommand within orchestration commands:

# BAD - Do NOT do this in /coordinate, /orchestrate, or /supervise
SlashCommand { command: "/plan create auth feature" }
SlashCommand { command: "/implement specs/027_auth/plans/001_implementation.md" }
```

**Rationale**: SlashCommand creates nested command contexts, breaks behavioral injection, prevents metadata extraction, and enables recursion loops.
*Recommendation synthesized from coordinate.md lines 68-84; Behavioral Injection Pattern lines 618-675*

### 3. Always Include Phase 0 in Orchestration Commands

**Mandatory Phase 0 structure**:
```markdown
## Phase 0: Pre-Calculate Artifact Paths and Topic Directory

**EXECUTE NOW - Topic Directory Determination**

Before invoking ANY subagents, calculate all artifact paths:

bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"

# 1. Determine topic directory
TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESC" ".claude/specs")

# 2. Create subdirectories
mkdir -p "$TOPIC_DIR"/{reports,plans,summaries,debug}

# 3. Pre-calculate artifact paths
REPORT_PATH_1=$(create_topic_artifact "$TOPIC_DIR" "reports" "topic_1" "")
REPORT_PATH_2=$(create_topic_artifact "$TOPIC_DIR" "reports" "topic_2" "")
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")

# 4. Export for subagent injection
export TOPIC_DIR REPORT_PATH_1 REPORT_PATH_2 PLAN_PATH

**VERIFICATION**: All paths must be calculated BEFORE any Task invocations.
```

**Benefits**:
- 100% file creation reliability (predictable paths)
- 85% token reduction (pre-calculation vs agent-based detection)
- 25x speedup vs agent-based path detection
- No recursion risk (orchestrator maintains control)
*Recommendation synthesized from Command Architecture Standards, lines 334-418; CLAUDE.md lines 274-279*

### 4. Implement Fail-Fast Error Handling

**Remove bootstrap fallbacks** that hide configuration errors:
```bash
❌ BAD - Silent fallback hides error:
if ! source .claude/lib/required-library.sh; then
  fallback_function() { echo "default"; }
fi

✅ GOOD - Explicit error with diagnostics:
if ! source .claude/lib/required-library.sh; then
  echo "ERROR: Failed to source required-library.sh"
  echo "EXPECTED PATH: $SCRIPT_DIR/.claude/lib/required-library.sh"
  echo "DIAGNOSTIC: ls -la $SCRIPT_DIR/.claude/lib/required-library.sh"
  exit 1
fi
```

**Preserve file creation verification fallbacks** that detect tool failures:
```bash
✅ CORRECT - Verification fallback detects errors:
if [ ! -f "$REPORT_PATH" ]; then
  echo "ERROR: Agent succeeded but file not created"
  echo "EXPECTED: $REPORT_PATH"
  echo "DIAGNOSTIC: Possible Write tool failure"

  # Fallback: Create from agent output
  cat > "$REPORT_PATH" <<EOF
$AGENT_OUTPUT
EOF

  # Re-verify
  [ -f "$REPORT_PATH" ] || exit 1
fi
```

**Rationale**: Bootstrap fallbacks hide configuration errors. File creation verification fallbacks detect transient Write tool failures. Only the latter should exist.
*Recommendation synthesized from Behavioral Injection Pattern, lines 841-1030; coordinate.md lines 33-67*

### 5. Validate Orchestration Commands Against Standard 11

**Standard 11: Imperative Agent Invocation Pattern**

All Task invocations MUST include:
1. **Imperative Instruction**: `**EXECUTE NOW**: USE the Task tool...`
2. **Agent Behavioral File Reference**: `Read and follow: .claude/agents/[name].md`
3. **No Code Block Wrappers**: Task invocations must NOT be fenced with ` ```yaml `
4. **No "Example" Prefixes**: Remove documentation context
5. **Completion Signal Requirement**: `Return: REPORT_CREATED: ${PATH}`

**Validation script**:
```bash
bash /home/benjamin/.config/.claude/lib/validate-agent-invocation-pattern.sh [command-file]
```

**Expected output**:
- Zero documentation-only YAML blocks
- All Task invocations preceded by imperative instruction
- All agents reference behavioral files
- All invocations require completion signals
*Recommendation from Command Architecture Standards, lines 1127-1307*

### 6. Document Orchestrator vs Executor Roles Explicitly

**In orchestration command files** (coordinate.md, orchestrate.md, supervise.md):
```markdown
## YOUR ROLE: WORKFLOW ORCHESTRATOR

**YOU ARE THE ORCHESTRATOR** for this multi-agent workflow.

**YOUR RESPONSIBILITIES**:
1. Pre-calculate ALL artifact paths
2. Invoke specialized agents via Task tool
3. Verify agent outputs
4. Extract and aggregate metadata
5. Report final status

**YOU MUST NEVER**:
1. Execute tasks yourself using Read/Grep/Write/Edit
2. Invoke other commands via SlashCommand
3. Modify files directly (except Phase 0 setup)
```

**In agent behavioral files** (research-specialist.md, plan-architect.md):
```markdown
## Research Specialist Agent

**YOU MUST perform these exact steps in sequence:**

**STEP 1 (REQUIRED BEFORE STEP 2)**: Receive and Verify Report Path
**STEP 2 (REQUIRED BEFORE STEP 3)**: Create Report File FIRST
**STEP 3 (REQUIRED BEFORE STEP 4)**: Conduct Research
**STEP 4 (ABSOLUTE REQUIREMENT)**: Verify and Return Confirmation
```

**Rationale**: Explicit role declarations prevent role ambiguity, which is the root cause of recursion and context bloat.
*Recommendation synthesized from coordinate.md lines 33-67; research-specialist.md lines 11-198*

## References

### Primary Documents
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (lines 1-2031)
  - Standard 0: Execution Enforcement (lines 53-418)
  - Standard 11: Imperative Agent Invocation Pattern (lines 1127-1307)
  - Standard 12: Structural vs Behavioral Content Separation (lines 1310-1397)

- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` (lines 1-1162)
  - Definition and Rationale (lines 9-77)
  - Anti-Pattern: Documentation-Only YAML Blocks (lines 324-414)
  - Case Studies: Spec 495, Spec 057 (lines 676-1030)

- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 1-100)
  - YOUR ROLE: WORKFLOW ORCHESTRATOR (lines 33-67)
  - Architectural Prohibition: No Command Chaining (lines 68-100)

- `/home/benjamin/.config/.claude/agents/research-specialist.md` (lines 1-671)
  - STEP-based execution process (lines 24-198)
  - Completion criteria (lines 322-413)

### Supporting Documentation
- `/home/benjamin/.config/CLAUDE.md` (lines 263-318)
  - Hierarchical Agent Architecture overview
  - Command Integration patterns

- `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md`
  - Avoiding documentation-only patterns

- `/home/benjamin/.config/.claude/docs/guides/orchestration-troubleshooting.md`
  - Bootstrap failures and delegation issues

### Validation Tools
- `/home/benjamin/.config/.claude/lib/validate-agent-invocation-pattern.sh`
  - Detects anti-patterns in command files

- `/home/benjamin/.config/.claude/tests/test_orchestration_commands.sh`
  - Comprehensive testing for all orchestration commands

### Case Study Artifacts
- Spec 495: `/home/benjamin/.config/.claude/specs/495_coordinate_and_research_delegation_failures/`
  - Reports documenting 0% → >90% delegation rate fix

- Spec 057: `/home/benjamin/.config/.claude/specs/057_supervise_robustness_improvements/`
  - Reports documenting fail-fast error handling implementation

## Implementation Guidance

### Decision Tree: SlashCommand vs Task Tool

```
START: Need to delegate work?
│
├─ Is this a user-facing top-level command?
│  YES → Use SlashCommand
│  NO  → Continue
│
├─ Are you orchestrating a multi-step workflow?
│  YES → Use Task tool with behavioral injection
│  NO  → Continue
│
├─ Do you need to customize agent behavior?
│  YES → Use Task tool (can inject context)
│  NO  → Continue
│
├─ Do you need metadata extraction after execution?
│  YES → Use Task tool (supports forward message pattern)
│  NO  → Continue
│
├─ Are you within an orchestration command?
│  YES → MUST use Task tool (SlashCommand causes recursion)
│  NO  → Use SlashCommand
│
END
```

### Migration Checklist: Command Chaining → Agent Delegation

If you find command chaining via SlashCommand in an orchestration command:

**Step 1: Identify the pattern**
```bash
grep -n "SlashCommand.*/(plan|implement|debug|document)" .claude/commands/*.md
```

**Step 2: Add Phase 0 path pre-calculation**
```markdown
## Phase 0: Pre-Calculate Artifact Paths

**EXECUTE NOW**: Calculate all paths before agent invocations

bash
source .claude/lib/artifact-creation.sh
TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESC" ".claude/specs")
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")
export TOPIC_DIR PLAN_PATH
```

**Step 3: Convert SlashCommand to Task invocation**
```markdown
# Before:
SlashCommand { command: "/plan create auth feature" }

# After:
**EXECUTE NOW**: USE the Task tool to invoke plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Plan Path: ${PLAN_PATH}
    - Feature: create auth feature

    Return: PLAN_CREATED: ${PLAN_PATH}
  "
}
```

**Step 4: Add verification checkpoint**
```markdown
**MANDATORY VERIFICATION**: After agent completes, verify plan file exists:

bash
if [ ! -f "$PLAN_PATH" ]; then
  echo "ERROR: Agent didn't create plan at $PLAN_PATH"
  exit 1
fi
echo "✓ Verified: Plan created at $PLAN_PATH"
```

**Step 5: Validate with test suite**
```bash
bash .claude/tests/test_orchestration_commands.sh [command-name]
```

### Testing Strategy

**Test 1: Delegation Rate**
```bash
# Verify agents execute (not silently skipped)
# Expected: >90% delegation rate
bash .claude/tests/test_orchestration_commands.sh | grep "delegation rate"
```

**Test 2: File Creation Locations**
```bash
# Verify artifacts created in correct topic directories
# Expected: Zero TODO*.md files, all in .claude/specs/NNN_topic/
find .claude/specs -name "*.md" -type f
```

**Test 3: No Command Recursion**
```bash
# Verify no SlashCommand invocations in orchestration commands
grep -r "SlashCommand.*/(plan|implement|debug)" .claude/commands/{coordinate,orchestrate,supervise}.md
# Expected: Zero matches
```

**Test 4: Bootstrap Reliability**
```bash
# Verify fail-fast error handling (no silent fallbacks)
# Expected: Explicit errors if libraries missing
bash -c "source .claude/commands/coordinate.md" 2>&1 | grep "ERROR:"
```

## Metadata

**Research Completion Date**: 2025-10-30
**Files Analyzed**: 6 primary documents, 3 supporting guides, 2 validation tools
**External Sources**: None (codebase research only)
**Confidence Level**: High (based on authoritative architecture standards and case study evidence)
