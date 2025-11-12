# Agent Invocation vs Slash Command Patterns in Orchestration

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: Correct patterns for invoking agents vs slash commands in orchestration workflows
- **Report Type**: Architectural pattern analysis with anti-pattern identification

## Executive Summary

Orchestration commands MUST use the Task tool with behavioral injection to invoke specialized agents, NOT the SlashCommand tool to invoke other commands. The /coordinate command currently violates this pattern in 4 locations (planning, implementation, debug, document phases) by invoking `/plan`, `/implement`, `/debug`, and `/document` as slash commands instead of invoking their underlying agents (plan-architect, implementer, debug-analyst, doc-writer) directly. This anti-pattern causes context bloat, breaks metadata extraction, prevents path pre-calculation, and violates Standard 11 (Imperative Agent Invocation Pattern). The correct pattern requires: (1) orchestrator pre-calculates all artifact paths, (2) orchestrator invokes agents via Task tool with injected context, (3) agents receive paths and behavioral guidelines from their definition files, (4) orchestrator verifies artifacts and extracts metadata only.

## Current State Analysis

### Anti-Pattern Violations in /coordinate

**Location**: `.claude/commands/coordinate.md`

**Violation 1 - Planning Phase (Line 669-683)**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan guided by research reports"
  timeout: 300000
  prompt: "
    Execute the /plan slash command with the following arguments:

    /plan \"$WORKFLOW_DESCRIPTION\" $REPORT_ARGS

    This will create an implementation plan guided by the research reports.
    The plan will be saved to: $TOPIC_PATH/plans/

    Return: PLAN_CREATED: [absolute path to plan file]
  "
}
```

**Why This Violates Standards**:
1. Uses SlashCommand invocation pattern ("Execute the /plan slash command")
2. Loses orchestrator control over plan path (cannot pre-calculate)
3. Nests full /plan command prompt inside /coordinate (context bloat)
4. Breaks metadata extraction (full plan content loaded, not summary)
5. Violates Standard 11 (Imperative Agent Invocation Pattern)

**Violation 2 - Implementation Phase (Line 878-894)**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with automated testing and commits"
  timeout: 600000
  prompt: "
    Execute the /implement slash command with the following arguments:

    /implement \"$PLAN_PATH\"

    This will execute the implementation plan phase-by-phase with:
    - Automated testing after each phase
    - Git commits for completed phases
    - Progress tracking and checkpoints

    Return: IMPLEMENTATION_COMPLETE: [summary or status]
  "
}
```

**Why This Violates Standards**:
1. Delegates to /implement command instead of implementer agent
2. Loses wave-based execution control
3. Cannot inject custom checkpoint handling
4. Prevents hierarchical supervision pattern

**Violation 3 - Debug Phase (Line 1105-1118)**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Analyze and debug test failures"
  timeout: 300000
  prompt: "
    Execute the /debug slash command with the following context:

    /debug \"Analyze test failures from implementation of: $WORKFLOW_DESCRIPTION\"

    This will create a debug report with root cause analysis and proposed fixes.

    Return: DEBUG_REPORT_CREATED: [absolute path to debug report]
  "
}
```

**Violation 4 - Documentation Phase (Line 1262-1275)**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Update documentation based on implementation changes"
  timeout: 300000
  prompt: "
    Execute the /document slash command with the following context:

    /document \"Update docs for: $WORKFLOW_DESCRIPTION\"

    This will update all relevant documentation files based on the implementation changes.

    Return: DOCUMENTATION_UPDATED: [list of updated files]
  "
}
```

### Correct Pattern in /coordinate (Research Phase)

**Positive Example - Research Phase (Line 363-378)**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research [topic name] with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [actual topic name]
    - Report Path: [REPORT_PATHS[$i-1] for topic $i]
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: [RESEARCH_COMPLEXITY value]

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [EXACT_ABSOLUTE_PATH]
  "
}
```

**Why This Is Correct**:
1. References agent behavioral file directly (`.claude/agents/research-specialist.md`)
2. Injects workflow-specific context (paths, standards, complexity)
3. No slash command invocation ("Execute the /research command")
4. Pre-calculated paths passed to agent
5. Follows Standard 11 (Imperative Agent Invocation Pattern)

## Research Findings

### When to Use Task Tool (Agent Invocation)

**Use Task tool when**:
1. Orchestrating multi-phase workflows (Phase 0 pattern required)
2. Need to pre-calculate artifact paths for agents
3. Want to extract metadata from agent outputs (95% context reduction)
4. Enabling hierarchical supervision (supervisors managing subagents)
5. Implementing parallel execution with wave-based dependencies
6. Maintaining strict control over file creation locations

**Pattern Requirements**:
- Orchestrator pre-calculates ALL artifact paths in Phase 0
- Orchestrator invokes agents via Task tool with behavioral injection
- Agent prompt references `.claude/agents/[agent-name].md`
- Agent receives absolute paths and context injection
- Agent returns completion signal only (not full content)
- Orchestrator verifies file creation with MANDATORY VERIFICATION
- Orchestrator extracts metadata from created artifacts (metadata-extraction.sh)

**Evidence from Behavioral Injection Pattern** (`.claude/docs/concepts/patterns/behavioral-injection.md`):

> Commands inject context into agents via file reads instead of SlashCommand tool invocations, enabling hierarchical multi-agent patterns and preventing direct execution.

> The pattern separates:
> - **Command role**: Orchestrator that calculates paths, manages state, delegates work
> - **Agent role**: Executor that receives context via file reads and produces artifacts

### When to Use SlashCommand Tool (Command Invocation)

**Use SlashCommand tool when**:
1. User explicitly requests a specific command by name
2. Interactive workflows where command output should be shown to user
3. Utility operations that don't require orchestration (e.g., `/list-plans`)
4. Testing/debugging individual commands
5. Simple delegation where full context sharing is acceptable

**Use Cases**:
- User asks: "run the tests" → Use SlashCommand to invoke `/test`
- User asks: "show me implementation plans" → Use SlashCommand to invoke `/list-plans`
- User asks: "create a research report on X" → Use SlashCommand to invoke `/research`

**CRITICAL DISTINCTION**: These are USER-initiated commands, not orchestrator-delegated subtasks.

### Standard 11: Imperative Agent Invocation Pattern

**From Command Architecture Standards** (`.claude/docs/reference/command_architecture_standards.md`, lines 1173-1353):

**Required Elements for ALL Task Invocations**:

1. **Imperative Instruction**: Use explicit execution markers
   - `**EXECUTE NOW**: USE the Task tool to invoke...`
   - `**INVOKE AGENT**: Use the Task tool with...`
   - `**CRITICAL**: Immediately invoke...`

2. **Agent Behavioral File Reference**: Direct reference to agent guidelines
   - Pattern: `Read and follow: .claude/agents/[agent-name].md`
   - Examples: `.claude/agents/research-specialist.md`, `.claude/agents/plan-architect.md`

3. **No Code Block Wrappers**: Task invocations must NOT be fenced
   - ❌ WRONG: ` ```yaml` ... `Task {` ... `}` ... ` ``` `
   - ✅ CORRECT: `Task {` ... `}` (no fence)

4. **No "Example" Prefixes**: Remove documentation context
   - ❌ WRONG: "Example agent invocation:" or "The following shows..."
   - ✅ CORRECT: "**EXECUTE NOW**: USE the Task tool..."

5. **Completion Signal Requirement**: Agent must return explicit confirmation
   - Pattern: `Return: REPORT_CREATED: ${REPORT_PATH}`
   - Purpose: Enables command-level verification of agent compliance

**Anti-Pattern: Command-to-Command Invocation** (lines 618-638):

```markdown
❌ BAD - /orchestrate calling /plan command:

## Phase 2: Planning

I'll create an implementation plan for the researched topics.

SlashCommand tool invocation:
{
  "command": "/plan Implement OAuth 2.0 authentication"
}
```

**Why This Fails**:
1. Nests full /plan command prompt inside /orchestrate prompt (context bloat)
2. /plan command executes directly instead of delegating to planner-specialist
3. Breaks metadata-based context reduction (full plan content returned, not summary)
4. Prevents hierarchical patterns (flat command chaining)

### Phase 0: Orchestrator vs Executor Role Clarification

**From Standard 0** (Command Architecture Standards, lines 308-418):

**Problem**: Multi-agent commands that invoke other slash commands create architectural violations:
- Commands calling other commands (e.g., `/orchestrate` calling `/plan`, `/implement`)
- Loss of artifact path control (cannot pre-calculate topic-based paths)
- Context bloat (cannot extract metadata before full content loaded)
- Recursion risk (command → command → command loops)

**Solution**: Distinguish between orchestrator and executor roles:

**Orchestrator Role** (coordinates workflow):
- Pre-calculates all artifact paths (topic-based organization)
- Invokes specialized subagents via Task tool (NOT SlashCommand)
- Injects complete context into subagents (behavioral injection pattern)
- Verifies artifacts created at expected locations
- Extracts metadata only (95% context reduction)
- Examples: `/orchestrate`, `/coordinate`, `/supervise`

**Executor Role** (performs atomic operations):
- Receives pre-calculated paths from orchestrator
- Executes specific task using Read/Write/Edit/Bash tools
- Creates artifacts at exact paths provided
- Returns metadata only (not full content)
- Examples: research-specialist agent, plan-architect agent, implementation-executor agent

**Phase 0 Requirement for Orchestrators**:

Every orchestrator command MUST include Phase 0 (before invoking any subagents):

```markdown
## Phase 0: Pre-Calculate Artifact Paths and Topic Directory

**EXECUTE NOW - Topic Directory Determination**

Before invoking ANY subagents, calculate all artifact paths:

```bash
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

**VERIFICATION**: All paths must be calculated BEFORE any Task invocations.
```

**When Phase 0 Required**:
- ✅ `/orchestrate` (coordinates research → plan → implement workflow)
- ✅ `/coordinate` (multi-agent state machine orchestration)
- ✅ `/supervise` (sequential lifecycle coordination)
- ✅ `/plan` (if coordinating research agents)
- ❌ `/list-plans` (read-only, no artifact creation)
- ❌ `/test` (executor role, not orchestrator)

### Agent Behavioral Files

Agents have their own behavioral definition files that contain ALL execution guidelines:

**research-specialist.md** (`.claude/agents/research-specialist.md`):
- 4-step sequential process (verify path → ensure directory → create file → conduct research)
- File creation as PRIMARY OBLIGATION (STEP 2)
- Mandatory verification checkpoints at each step
- Progress streaming requirements (7 progress markers)
- 28 completion criteria (100% compliance required)
- Returns: `REPORT_CREATED: [absolute-path]`

**plan-architect.md** (inferred from pattern):
- Receives research reports as context
- Creates implementation plan with phases and dependencies
- Saves to pre-calculated plan path
- Returns: `PLAN_CREATED: [absolute-path]`

**implementer agent** (inferred from pattern):
- Receives plan path and executes phase-by-phase
- Runs tests after each phase
- Creates git commits for completed work
- Updates checkpoints with progress
- Returns: `IMPLEMENTATION_COMPLETE: [status]`

**debug-analyst agent** (inferred from pattern):
- Analyzes test failures and error messages
- Conducts root cause analysis
- Creates debug report with proposed fixes
- Returns: `DEBUG_REPORT_CREATED: [absolute-path]`

**doc-writer agent** (inferred from pattern):
- Updates documentation based on implementation changes
- Ensures consistency across all doc files
- Returns: `DOCUMENTATION_UPDATED: [list-of-files]`

### Historical Context and Case Studies

**Spec 495** (2025-10-27): `/coordinate` and `/research` Agent Delegation Failures
- Problem: 9 agent invocations using documentation-only YAML pattern
- Evidence: Zero files in correct locations, all output to TODO1.md files
- Result: 0% → >90% delegation rate after fixing anti-patterns
- Duration: 2.5 hours for /coordinate (9 invocations)

**Spec 438** (2025-10-24): `/supervise` Agent Delegation Fix
- Problem: 7 YAML blocks wrapped in markdown code fences
- Result: 0% delegation rate before fix, >90% after
- Pattern established: /supervise became reference for other orchestration commands

**Spec 057** (2025-10-27): `/supervise` Robustness Improvements
- Problem: Bootstrap fallback mechanisms hiding configuration errors
- Result: Fail-fast error handling with diagnostic messages
- Principle: Verification fallbacks DETECT errors; bootstrap fallbacks HIDE errors

**Unified Plan** (Spec 497): Consolidated Improvements
- Created validation script: `.claude/lib/validate-agent-invocation-pattern.sh`
- Created unified test suite: `.claude/tests/test_orchestration_commands.sh`
- Updated documentation: Command Architecture Standards, Behavioral Injection Pattern
- Result: All orchestration commands validated and consistent

### Performance Impact of Correct Pattern

**File Creation Rate**:
- Before: 60-80% (commands creating files in wrong locations)
- After: 100% (explicit path injection ensures correct locations)

**Context Reduction**:
- Before: 80-100% context usage (nested command prompts)
- After: <30% context usage (metadata-only passing between agents)

**Parallelization**:
- Before: Impossible (sequential command chaining)
- After: 40-60% time savings (independent agents run in parallel)

**Hierarchical Coordination**:
- Before: Flat command chaining (max 4 agents)
- After: Recursive supervision (10+ agents across 3 levels)

## Recommendations

### Recommendation 1: Fix /coordinate Planning Phase (CRITICAL)

**Current Code** (Lines 669-683):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan guided by research reports"
  timeout: 300000
  prompt: "
    Execute the /plan slash command with the following arguments:

    /plan \"$WORKFLOW_DESCRIPTION\" $REPORT_ARGS
    ...
  "
}
```

**Corrected Code** (Behavioral Injection Pattern):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan guided by research reports"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Feature Description: $WORKFLOW_DESCRIPTION
    - Plan Output Path: $PLAN_PATH (absolute, pre-calculated)
    - Research Reports: [list of $REPORT_PATHS]
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Topic Directory: $TOPIC_PATH

    **Specific Investigation Areas** (inject from orchestrator):
    1. Review research findings in provided reports
    2. Identify dependencies and phase boundaries
    3. Create implementation plan following project standards
    4. Save plan to EXACT path provided above

    Execute planning following all guidelines in behavioral file.
    Return: PLAN_CREATED: $PLAN_PATH
  "
}
```

**Key Changes**:
1. Remove "Execute the /plan slash command" language
2. Add agent behavioral file reference (`.claude/agents/plan-architect.md`)
3. Inject pre-calculated PLAN_PATH (not let /plan calculate it)
4. Provide research report paths as context
5. Add imperative instruction prefix

**Impact**:
- Enables path pre-calculation (orchestrator control)
- Reduces context usage (metadata extraction possible)
- Prevents command nesting (flat agent coordination)
- 100% file creation reliability

### Recommendation 2: Fix /coordinate Implementation Phase

**Current Code** (Lines 878-894):
```markdown
Task {
  prompt: "
    Execute the /implement slash command with the following arguments:
    /implement \"$PLAN_PATH\"
    ...
  "
}
```

**Corrected Code**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the implementer agent.

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallel execution"
  timeout: 600000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/implementer.md

    **Workflow-Specific Context**:
    - Plan Path: $PLAN_PATH (absolute)
    - Topic Directory: $TOPIC_PATH
    - Checkpoint File: $STATE_FILE
    - Test Command: [from CLAUDE.md testing protocols]
    - Wave Execution: Enabled (parallel phases with dependencies)

    **CRITICAL**: Execute plan phase-by-phase with:
    - Automated testing after each phase
    - Git commits for completed phases
    - Progress tracking and checkpoint updates
    - Wave-based parallel execution for independent phases

    Execute implementation following all guidelines in behavioral file.
    Return: IMPLEMENTATION_COMPLETE: [summary with checkpoint state]
  "
}
```

**Key Changes**:
1. Reference implementer agent (not /implement command)
2. Inject checkpoint file and test commands
3. Enable wave-based execution control
4. Maintain orchestrator's state management

### Recommendation 3: Fix /coordinate Debug Phase

**Current Code** (Lines 1105-1118):
```markdown
Task {
  prompt: "
    Execute the /debug slash command with the following context:
    /debug \"Analyze test failures from implementation of: $WORKFLOW_DESCRIPTION\"
    ...
  "
}
```

**Corrected Code**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the debug-analyst agent.

Task {
  subagent_type: "general-purpose"
  description: "Analyze test failures with root cause analysis"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/debug-analyst.md

    **Workflow-Specific Context**:
    - Issue Description: Analyze test failures from implementation of $WORKFLOW_DESCRIPTION
    - Test Output: [capture from previous phase]
    - Implementation Plan: $PLAN_PATH
    - Debug Report Path: $TOPIC_PATH/debug/001_test_failures.md (pre-calculated)
    - Project Standards: /home/benjamin/.config/CLAUDE.md

    **Specific Investigation Areas**:
    1. Analyze test failure messages and stack traces
    2. Identify root causes (not just symptoms)
    3. Propose specific fixes with file references
    4. Create comprehensive debug report

    Execute debug analysis following all guidelines in behavioral file.
    Return: DEBUG_REPORT_CREATED: $TOPIC_PATH/debug/001_test_failures.md
  "
}
```

### Recommendation 4: Fix /coordinate Documentation Phase

**Current Code** (Lines 1262-1275):
```markdown
Task {
  prompt: "
    Execute the /document slash command with the following context:
    /document \"Update docs for: $WORKFLOW_DESCRIPTION\"
    ...
  "
}
```

**Corrected Code**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the doc-writer agent.

Task {
  subagent_type: "general-purpose"
  description: "Update documentation based on implementation changes"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/doc-writer.md

    **Workflow-Specific Context**:
    - Change Description: Update docs for: $WORKFLOW_DESCRIPTION
    - Implementation Plan: $PLAN_PATH
    - Files Modified: [list from implementation phase]
    - Test Status: [passed/failed from previous phase]
    - Summary Path: $TOPIC_PATH/summaries/001_workflow_summary.md (pre-calculated)
    - Project Standards: /home/benjamin/.config/CLAUDE.md

    **Documentation Requirements**:
    1. Update all affected README.md files
    2. Add usage examples for new features
    3. Update CHANGELOG.md with changes
    4. Create workflow summary with complete artifact cross-references

    Execute documentation updates following all guidelines in behavioral file.
    Return: DOCUMENTATION_UPDATED: [list-of-updated-files]
  "
}
```

### Recommendation 5: Add Phase 0 Path Pre-Calculation (If Missing)

**Verification**: Check if /coordinate pre-calculates these paths:
- `$PLAN_PATH` - Must be calculated BEFORE planning phase
- `$DEBUG_REPORT_PATH` - Must be calculated BEFORE debug phase (if needed)
- `$SUMMARY_PATH` - Must be calculated BEFORE documentation phase

**If missing**, add to Phase 0 initialization:
```bash
# Pre-calculate planning artifact path
PLAN_PATH=$(create_topic_artifact "$TOPIC_PATH" "plans" "001_implementation" ".md")
export PLAN_PATH

# Pre-calculate debug path (conditional based on test results)
DEBUG_REPORT_PATH="$TOPIC_PATH/debug/001_test_failures.md"
export DEBUG_REPORT_PATH

# Pre-calculate summary path
SUMMARY_PATH=$(create_topic_artifact "$TOPIC_PATH" "summaries" "001_workflow_summary" ".md")
export SUMMARY_PATH

echo "✓ All artifact paths pre-calculated:"
echo "  - Plan: $PLAN_PATH"
echo "  - Debug: $DEBUG_REPORT_PATH"
echo "  - Summary: $SUMMARY_PATH"
```

### Recommendation 6: Create Missing Agent Behavioral Files

**Required Agent Files** (if they don't exist):

1. **`.claude/agents/plan-architect.md`**
   - Role: Create implementation plans guided by research reports
   - Inputs: Feature description, research report paths, project standards
   - Output: Implementation plan with phases, tasks, dependencies
   - Return format: `PLAN_CREATED: [absolute-path]`

2. **`.claude/agents/implementer.md`**
   - Role: Execute implementation plans phase-by-phase
   - Inputs: Plan path, checkpoint file, test commands
   - Capabilities: Wave-based parallel execution, automated testing, git commits
   - Return format: `IMPLEMENTATION_COMPLETE: [status-summary]`

3. **`.claude/agents/debug-analyst.md`**
   - Role: Analyze test failures and conduct root cause analysis
   - Inputs: Test output, implementation plan, issue description
   - Output: Debug report with root causes and proposed fixes
   - Return format: `DEBUG_REPORT_CREATED: [absolute-path]`

4. **`.claude/agents/doc-writer.md`**
   - Role: Update documentation based on implementation changes
   - Inputs: Change description, modified files, test status
   - Output: Updated documentation files and workflow summary
   - Return format: `DOCUMENTATION_UPDATED: [list-of-files]`

**Template**: Use `.claude/agents/research-specialist.md` as pattern for:
- Imperative language (YOU MUST, EXECUTE NOW)
- Sequential steps with dependencies (STEP 1 REQUIRED BEFORE STEP 2)
- File creation as PRIMARY OBLIGATION
- Mandatory verification checkpoints
- Completion criteria (ALL REQUIRED)
- Progress streaming requirements

### Recommendation 7: Update Command Architecture Compliance

After fixes, ensure /coordinate scores 90+/100 on enforcement rubric:

**Validation Checklist**:
- [ ] All Task invocations reference agent behavioral files (not slash commands)
- [ ] All agent prompts include "Read and follow: .claude/agents/[name].md"
- [ ] All artifact paths pre-calculated in Phase 0 (before agent invocations)
- [ ] All Task invocations use imperative prefixes ("**EXECUTE NOW**: USE the Task tool")
- [ ] Zero SlashCommand invocations to other orchestration commands
- [ ] All completion signals follow standard format ("REPORT_CREATED:", "PLAN_CREATED:", etc.)
- [ ] Mandatory verification checkpoints after all file creation operations

**Validation Script**:
```bash
.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md
```

Expected result: PASS (0 violations)

### Recommendation 8: Document Pattern in Coordinate Command Guide

**Update**: `.claude/docs/guides/coordinate-command-guide.md`

Add section explaining:
1. Why Task tool is used (not SlashCommand)
2. Behavioral injection pattern benefits
3. Path pre-calculation requirements
4. Agent behavioral file references
5. Comparison with anti-pattern (command-to-command invocation)

**Cross-Reference**: Link to Behavioral Injection Pattern documentation for complete rationale.

## Implementation Guidance

### Step-by-Step Fix Process

**Phase 1: Audit Current State**
1. Run validation script: `.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md`
2. Count SlashCommand invocations: `grep -c "Execute the /" .claude/commands/coordinate.md`
3. Identify all violations (expected: 4 as documented above)

**Phase 2: Create Agent Behavioral Files** (if missing)
1. Check for existing agents: `ls -la .claude/agents/plan-architect.md` (etc.)
2. Create missing agents using research-specialist.md as template
3. Define 4-step process, PRIMARY OBLIGATION, verification checkpoints
4. Test agent invocation independently before integration

**Phase 3: Fix Planning Phase**
1. Backup current coordinate.md: `cp coordinate.md coordinate.md.backup-$(date +%Y%m%d)`
2. Apply Recommendation 1 fix (lines 669-683)
3. Verify PLAN_PATH pre-calculated in Phase 0
4. Test planning phase independently

**Phase 4: Fix Implementation Phase**
1. Apply Recommendation 2 fix (lines 878-894)
2. Ensure checkpoint file path passed to implementer agent
3. Test implementation phase with simple plan

**Phase 5: Fix Debug Phase**
1. Apply Recommendation 3 fix (lines 1105-1118)
2. Add debug report path pre-calculation
3. Test with intentional test failure

**Phase 6: Fix Documentation Phase**
1. Apply Recommendation 4 fix (lines 1262-1275)
2. Add summary path pre-calculation
3. Test documentation updates

**Phase 7: Validation**
1. Re-run validation script (expect 0 violations)
2. Test complete workflow end-to-end
3. Verify all artifacts created at expected locations
4. Confirm metadata extraction working (95% context reduction)
5. Check delegation rate (expect >90%)

### Testing Strategy

**Unit Tests** (per phase):
- Test research phase: Verify reports created at pre-calculated paths
- Test planning phase: Verify plan created with agent (not /plan command)
- Test implementation phase: Verify wave-based execution enabled
- Test debug phase: Verify debug report created
- Test documentation phase: Verify summary and docs updated

**Integration Test**:
```bash
# Full workflow test
/coordinate "implement simple test feature with authentication"

# Expected artifacts:
# - .claude/specs/NNN_test_feature/reports/001_*.md (research)
# - .claude/specs/NNN_test_feature/plans/001_implementation.md (planning)
# - .claude/specs/NNN_test_feature/summaries/001_workflow_summary.md (documentation)
# - Git commits for implementation phases
```

**Validation Metrics**:
- Delegation rate: >90% (all agent invocations execute)
- File creation rate: 100% (all artifacts at expected paths)
- Context usage: <30% (metadata extraction working)
- Parallel execution: Enabled for independent phases

### Common Migration Issues

**Issue 1: Agent Behavioral File Missing**
- Symptom: Task invocation fails with "file not found"
- Solution: Create agent behavioral file following template pattern
- Validation: Ensure file exists at `.claude/agents/[name].md`

**Issue 2: Path Not Pre-Calculated**
- Symptom: Agent receives empty or undefined path variable
- Solution: Add path calculation to Phase 0 before first agent invocation
- Validation: Echo all paths after Phase 0 calculation

**Issue 3: SlashCommand Invocation Still Present**
- Symptom: Validation script reports violations
- Solution: Remove "Execute the /command" language, replace with agent reference
- Validation: Run `grep -n "Execute the /" coordinate.md` (expect 0 results)

**Issue 4: Missing Imperative Prefix**
- Symptom: Task invocation ignored or interpreted as documentation
- Solution: Add `**EXECUTE NOW**: USE the Task tool to invoke...` before Task block
- Validation: Check for imperative language within 5 lines of Task invocation

## References

### Documentation Files Analyzed

1. **`.claude/docs/concepts/patterns/behavioral-injection.md`** (1,162 lines)
   - Lines 1-62: Pattern definition and rationale
   - Lines 39-102: Core mechanism (Phase 0, path pre-calculation, context injection)
   - Lines 104-174: Code examples from Plan 080
   - Lines 260-415: Anti-Pattern: Inline Template Duplication
   - Lines 324-617: Anti-Pattern: Documentation-Only YAML Blocks
   - Lines 676-840: Case Study: Spec 495 (/coordinate and /research delegation failures)

2. **`.claude/docs/reference/command_architecture_standards.md`** (2,325 lines)
   - Lines 1-18: Purpose and fundamental understanding
   - Lines 49-463: Standard 0 (Execution Enforcement with Phase 0)
   - Lines 976-1170: Standard 1-5 (Inline content requirements)
   - Lines 1173-1353: Standard 11 (Imperative Agent Invocation Pattern)
   - Lines 1355-1453: Standard 12 (Structural vs Behavioral Separation)

3. **`.claude/agents/research-specialist.md`** (671 lines)
   - Lines 1-22: Agent metadata and critical instructions
   - Lines 23-178: 4-step sequential process (path verification, directory creation, file creation, research)
   - Lines 200-237: Progress streaming (7 required markers)
   - Lines 322-413: 28 completion criteria (100% compliance required)

4. **`.claude/commands/coordinate.md`** (analyzed sections)
   - Lines 337-378: Research phase (CORRECT PATTERN - behavioral injection)
   - Lines 669-683: Planning phase (VIOLATION - slash command invocation)
   - Lines 878-894: Implementation phase (VIOLATION - slash command invocation)
   - Lines 1105-1118: Debug phase (VIOLATION - slash command invocation)
   - Lines 1262-1275: Documentation phase (VIOLATION - slash command invocation)

### External Specifications Referenced

- **Spec 495** (2025-10-27): /coordinate and /research agent delegation failures
- **Spec 438** (2025-10-24): /supervise agent delegation fix (0% → >90%)
- **Spec 057** (2025-10-27): /supervise robustness improvements (fail-fast error handling)
- **Spec 497**: Unified orchestration improvements (validation scripts and test suites)
- **Plan 080**: /orchestrate Phase 0 implementation (orchestrator vs executor roles)

### Performance Benchmarks

- **File Creation Rate**: 60-80% (before) → 100% (after pattern compliance)
- **Context Reduction**: 80-100% usage (before) → <30% usage (after metadata extraction)
- **Parallelization**: Impossible (sequential commands) → 40-60% time savings (parallel agents)
- **Delegation Rate**: 0% (anti-pattern) → >90% (correct pattern)

### Related Patterns

- [Metadata Extraction Pattern](../concepts/patterns/metadata-extraction.md) - 99% context reduction via summaries
- [Hierarchical Supervision Pattern](../concepts/patterns/hierarchical-supervision.md) - Recursive agent coordination
- [Verification and Fallback Pattern](../concepts/patterns/verification-fallback.md) - MANDATORY VERIFICATION checkpoints
- [Parallel Execution Pattern](../concepts/patterns/parallel-execution.md) - Wave-based dependencies

### Validation Tools

- `.claude/lib/validate-agent-invocation-pattern.sh` - Detect anti-patterns in command files
- `.claude/tests/test_orchestration_commands.sh` - Comprehensive orchestration testing
- `.claude/tests/validate_executable_doc_separation.sh` - File size and cross-reference validation

## Metadata

- **Research Date**: 2025-11-10
- **Files Analyzed**: 4 primary documentation files, 1 agent file, 1 command file
- **Anti-Patterns Identified**: 4 (planning, implementation, debug, documentation phases in /coordinate)
- **Correct Patterns Identified**: 1 (research phase in /coordinate using behavioral injection)
- **External Sources**: 6 specifications (495, 438, 057, 497, Plan 080)
- **Validation Tools**: 3 scripts available for pattern compliance checking
