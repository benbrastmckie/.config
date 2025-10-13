---
allowed-tools: Task, TodoWrite, Read, Write, Bash, Grep, Glob
argument-hint: <workflow-description> [--parallel] [--sequential] [--create-pr]
description: Coordinate subagents through end-to-end development workflows
command-type: primary
dependent-commands: report, plan, implement, debug, test, document, github-specialist
---

# Multi-Agent Workflow Orchestration

I'll coordinate multiple specialized subagents through a complete development workflow, from research to documentation, while preserving context and enabling intelligent parallelization.

## Workflow Analysis

Let me first analyze your workflow description to identify the natural phases and requirements.

## Shared Utilities Integration

This command uses shared utility libraries for consistent workflow management:
- **Checkpoint Management**: Uses `.claude/lib/checkpoint-utils.sh` for saving/restoring workflow state
- **Error Handling**: Uses `.claude/lib/error-utils.sh` for agent error recovery and fallback strategies

These utilities ensure workflow state is preserved across interruptions and agent failures are handled gracefully.

### Step 1: Parse Workflow Description

I'll extract:
- **Core Feature/Task**: What needs to be accomplished
- **Workflow Type**: Feature development, refactoring, debugging, or investigation
- **Complexity Indicators**: Keywords suggesting scope and approach
- **Parallelization Hints**: Tasks that can run concurrently

### Step 2: Identify Workflow Phases

Based on the description, I'll determine which phases are needed:

**Standard Development Workflow**:
1. **Research Phase** (Parallel): Investigate patterns, best practices, alternatives
2. **Planning Phase** (Sequential): Synthesize findings into structured plan
3. **Implementation Phase** (Adaptive): Execute plan with testing
4. **Debugging Loop** (Conditional): Fix failures if tests don't pass
5. **Documentation Phase** (Sequential): Update docs and generate summary

**Simplified Workflows** (for straightforward tasks):
- Skip research if task is well-understood
- Direct to implementation for simple fixes
- Minimal documentation for internal changes

### Step 3: Initialize Workflow State

I'll create minimal orchestrator state:

```yaml
workflow_state:
  workflow_description: "[User's request]"
  workflow_type: "feature|refactor|debug|investigation"
  current_phase: "research|planning|implementation|debugging|documentation"
  completed_phases: []
  project_name: ""  # Auto-generated from workflow description

checkpoints:
  research_complete: null
  plan_ready: null
  implementation_complete: null
  tests_passing: null
  workflow_complete: null

context_preservation:
  research_reports: []  # Paths to created report files
  plan_path: ""
  implementation_status:
    tests_passing: false
    files_modified: []
  debug_reports: []  # Paths to created debug report files
  documentation_paths: []

error_history: []
performance_metrics:
  phase_times: {}
  parallel_effectiveness: 0
```

## Phase Coordination

### Research Phase (Parallel Execution)

#### Step 1: Identify Research Topics

ANALYZE the workflow description to extract 2-4 focused research topics.

**EXECUTE NOW**:

1. READ the user's workflow description from the /orchestrate invocation
2. IDENTIFY key areas requiring investigation:
   - Existing implementations in codebase
   - Industry best practices and standards
   - Alternative approaches and trade-offs
   - Technical constraints and requirements
3. EXTRACT 2-4 specific topics based on workflow complexity
4. GENERATE topic titles for each research area

**Topic Categories** (use as guidance):
- **existing_patterns**: Current codebase implementations and patterns
- **best_practices**: Industry standards for the technology/approach
- **alternatives**: Alternative implementations and their trade-offs
- **constraints**: Technical limitations, requirements, security considerations

**Complexity-Based Research Strategy**:
```yaml
Simple Workflows (skip research):
  - Keywords: "fix", "update", "small change"
  - Action: Skip directly to planning phase
  - Thinking Mode: None (standard processing)

Medium Workflows (focused research):
  - Keywords: "add", "improve", "refactor"
  - Topics: 2-3 focused areas
  - Example: existing patterns + best practices
  - Thinking Mode: "think" (moderate complexity)

Complex Workflows (comprehensive research):
  - Keywords: "implement", "redesign", "architecture"
  - Topics: 3-4 comprehensive areas
  - Example: patterns + practices + alternatives + constraints
  - Thinking Mode: "think hard" (high complexity)

Critical Workflows (system-wide impact):
  - Keywords: "security", "breaking change", "core refactor"
  - Topics: 4+ comprehensive areas
  - Thinking Mode: "think harder" (critical decisions)
```

#### Step 1.5: Determine Thinking Mode

CALCULATE workflow complexity score to determine thinking mode for all agents in this workflow.

**EXECUTE NOW**:

1. ANALYZE workflow description for complexity indicators
2. CALCULATE complexity score using this algorithm:

   ```
   score = 0
   score += count_keywords(["implement", "architecture", "redesign"]) × 3
   score += count_keywords(["add", "improve", "refactor"]) × 2
   score += count_keywords(["security", "breaking", "core"]) × 4
   score += estimated_file_count / 5
   score += (research_topics_needed - 1) × 2
   ```

3. MAP complexity score to thinking mode:
   - score 0-3: No special thinking mode (standard processing)
   - score 4-6: "think" (moderate complexity, careful reasoning)
   - score 7-9: "think hard" (high complexity, deep analysis)
   - score 10+: "think harder" (critical decisions, security implications)

4. STORE thinking_mode in workflow_state for use in all agent prompts

**Examples**:

"Add hello world function"
→ Keywords: "add" (×1) = 2 points, files: ~1 = 0 points, topics: 0 = 0 points
→ Total: 2 (Simple, no thinking mode)

"Implement user authentication system"
→ Keywords: "implement" (×1) = 3 points, "authentication" suggests security context
→ Files: ~8-10 = 2 points, topics: 3 = 4 points
→ Total: 9 (Complex, thinking mode: "think hard")

"Refactor core security module with breaking changes"
→ Keywords: "refactor" (×1) = 2, "security" (×1) = 4, "breaking" (×1) = 4, "core" (×1) = 4
→ Files: ~15 = 3 points, topics: 4 = 6 points
→ Total: 23 (Critical, thinking mode: "think harder")

This thinking mode will be prepended to ALL agent prompts in subsequent phases.

#### Step 2: Launch Parallel Research Agents

**EXECUTE NOW**: USE the Task tool to invoke research-specialist agents in parallel.

For EACH research topic identified in Step 1:

INVOKE a research-specialist agent using the Task tool with these exact parameters:

```json
{
  "subagent_type": "general-purpose",
  "description": "Research [TOPIC_NAME] using research-specialist protocol",
  "prompt": "Read and follow the behavioral guidelines from:\n/home/benjamin/.config/.claude/agents/research-specialist.md\n\nYou are acting as a Research Specialist Agent with the tools and constraints defined in that file.\n\n[COMPLETE PROMPT FROM STEP 3 - SEE BELOW]"
}
```

**CRITICAL**: Send ALL research Task invocations in a SINGLE MESSAGE.

This enables parallel execution. Do NOT send Task invocations sequentially - they must all be in one response to execute concurrently.

**Example Parallel Invocation** (3 research topics):

```
Here are three research tasks to execute in parallel:

[Task tool invocation #1 for existing_patterns]
[Task tool invocation #2 for security_practices]
[Task tool invocation #3 for framework_implementations]
```

**WAIT** for all research agents to complete before proceeding to Step 3.5.

**Monitoring**:
- Watch for PROGRESS: markers from each agent
- Collect REPORT_PATH: outputs as agents complete
- Verify all agents complete successfully before moving to Step 4

#### Step 3: Complete Research Agent Prompt Template

The following template is used for EACH research-specialist agent invocation in Step 2.

**SUBSTITUTE** these placeholders before invoking:
- [THINKING_MODE]: Value from Step 1.5 (think, think hard, think harder, or empty)
- [TOPIC_TITLE]: Research topic title (e.g., "Authentication Patterns in Codebase")
- [USER_WORKFLOW]: Original user workflow description (1 line)
- [PROJECT_NAME]: Generated in Step 3.5
- [TOPIC_SLUG]: Generated in Step 3.5
- [SPECS_DIR]: Path to specs directory (from SPECS.md or auto-detected)
- [COMPLEXITY_LEVEL]: Simple|Medium|Complex|Critical (from Step 1.5)
- [SPECIFIC_REQUIREMENTS]: What this agent should investigate

**Complete Prompt Template**:

```markdown
**Thinking Mode**: [THINKING_MODE]

# Research Task: [TOPIC_TITLE]

## Context
- **Workflow**: [USER_WORKFLOW]
- **Project Name**: [PROJECT_NAME]
- **Topic Slug**: [TOPIC_SLUG]
- **Research Focus**: [SPECIFIC_REQUIREMENTS]
- **Project Standards**: /home/benjamin/.config/CLAUDE.md
- **Complexity Level**: [COMPLEXITY_LEVEL]

## Objective
Investigate [SPECIFIC_REQUIREMENTS] to inform planning and implementation phases.

## Specs Directory Context
- **Specs Directory Detection**:
  1. Check .claude/SPECS.md for registered specs directories
  2. If no SPECS.md, use Glob to find existing specs/ directories
  3. Default to project root specs/ if none found
- **Report Location**: Create report in [SPECS_DIR]/reports/[TOPIC_SLUG]/NNN_report_name.md
- **Include in Metadata**: Add "Specs Directory" field to report metadata

## Research Requirements

[SPECIFIC_REQUIREMENTS - Agent should investigate these areas:]

### For "existing_patterns" Topics:
- Search codebase for related implementations using Grep/Glob
- Read relevant source files to understand current patterns
- Identify architectural decisions and design patterns used
- Document file locations with line number references
- Note any inconsistencies or technical debt

### For "best_practices" Topics:
- Use WebSearch to find 2025-current best practices
- Focus on authoritative sources (official docs, security guides)
- Compare industry standards with current implementation
- Identify gaps between best practices and current state
- Recommend specific improvements

### For "alternatives" Topics:
- Research 2-3 alternative implementation approaches
- Document pros/cons of each alternative
- Consider trade-offs (performance, complexity, maintainability)
- Recommend which alternative best fits this project
- Provide concrete examples from similar projects

### For "constraints" Topics:
- Identify technical limitations (platform, dependencies, performance)
- Document security considerations and requirements
- Note compatibility requirements (backwards compatibility, API contracts)
- Consider resource constraints (time, team expertise, infrastructure)
- Flag high-risk areas requiring careful design

## Report File Creation

You MUST create a research report file using the Write tool. Do NOT return only a summary.

**Report File Path Determination**:

1. USE Glob to find existing reports in topic directory:
   ```
   Glob pattern: "[SPECS_DIR]/reports/[TOPIC_SLUG]/[0-9][0-9][0-9]_*.md"
   ```

2. DETERMINE next report number:
   - Parse highest existing number in topic directory
   - Increment by 1
   - Format as 3-digit (001, 002, 003...)

3. CONSTRUCT report filename:
   - Format: NNN_descriptive_name.md
   - Example: 001_auth_patterns_analysis.md
   - Use lowercase with underscores

4. CREATE report file path:
   - Full path: [SPECS_DIR]/reports/[TOPIC_SLUG]/NNN_descriptive_name.md

**Report Structure** (use this exact template):

```markdown
# [Report Title]

## Metadata
- **Date**: YYYY-MM-DD
- **Specs Directory**: [SPECS_DIR]
- **Report Number**: NNN (within topic subdirectory)
- **Topic**: [TOPIC_SLUG]
- **Created By**: /orchestrate (research phase)
- **Workflow**: [USER_WORKFLOW]

## Implementation Status
- **Status**: Research Complete
- **Plan**: (will be added by plan-architect)
- **Implementation**: (will be added after implementation)
- **Date**: YYYY-MM-DD

## Research Focus
[Description of what this research investigated]

## Findings

### Current State Analysis
[Detailed findings from codebase analysis - include file references with line numbers]

### Industry Best Practices
[Findings from web research - include authoritative sources]

### Key Insights
[Important discoveries, patterns identified, issues found]

## Recommendations

### Primary Recommendation: [Approach Name]
**Description**: [What this approach entails]
**Pros**:
- [Advantage 1]
- [Advantage 2]
**Cons**:
- [Limitation 1]
**Suitability**: [Why this fits the project]

### Alternative Approach: [Approach Name]
[Secondary recommendation if applicable]

## Potential Challenges
- [Challenge 1 and mitigation strategy]
- [Challenge 2 and mitigation strategy]

## References
- [File: path/to/file.ext, lines X-Y - description]
- [URL: https://... - authoritative source]
- [Related code: path/to/related.ext]
```

## Expected Output

**Primary Output**: Report file path in this exact format:
```
REPORT_PATH: [SPECS_DIR]/reports/[TOPIC_SLUG]/NNN_descriptive_name.md
```

**Secondary Output**: Brief summary (1-2 sentences):
- What was researched
- Key finding or primary recommendation

**Example Output**:
```
REPORT_PATH: specs/reports/existing_patterns/001_auth_patterns.md

Research investigated current authentication implementations in the codebase. Found
session-based auth using Redis with 30-minute TTL. Primary recommendation: Extend
existing session pattern rather than implementing OAuth from scratch.
```

## Success Criteria
- Report file created at correct path with correct number
- Report includes all required metadata fields
- Findings include specific file references with line numbers
- Recommendations are actionable and project-specific
- Report path returned in parseable format (REPORT_PATH: ...)
```

End of prompt template.

#### Step 3.5: Generate Project Name and Topic Slugs

**EXECUTE NOW**: Generate project name and topic slugs BEFORE invoking research agents (Step 2).

**Project Name Generation Algorithm**:

1. EXTRACT key terms from workflow description
2. REMOVE common words: [the, a, an, implement, add, create, build, develop, refactor, update, fix]
3. JOIN remaining words with underscores
4. CONVERT to lowercase
5. LIMIT to 3-4 words maximum
6. STORE in workflow_state.project_name

**Examples**:

"Implement user authentication system"
→ Extract: [Implement, user, authentication, system]
→ Remove: [Implement] (common word)
→ Remaining: [user, authentication, system]
→ Result: "user_authentication_system" (3 words)

"Add payment processing flow"
→ Extract: [Add, payment, processing, flow]
→ Remove: [Add] (common word)
→ Remaining: [payment, processing, flow]
→ Result: "payment_processing_flow" (3 words)

"Refactor session management"
→ Extract: [Refactor, session, management]
→ Remove: [Refactor] (common word)
→ Remaining: [session, management]
→ Result: "session_management" (2 words)

**Topic Slug Generation Algorithm** (for EACH research topic):

1. EXTRACT key terms from research topic description
2. REMOVE common words: [the, a, an, in, for, with, how, what, patterns, approaches]
3. JOIN remaining words with underscores
4. CONVERT to lowercase
5. KEEP concise (2-3 words maximum)
6. STORE in workflow_state.topic_slugs array (same order as research_topics)

**Examples**:

"Existing auth patterns in codebase"
→ Extract: [Existing, auth, patterns, in, codebase]
→ Remove: [in] (common word)
→ Keep: [existing, patterns] (concise)
→ Result: "existing_patterns"

"Security best practices for authentication (2025)"
→ Extract: [Security, best, practices, for, authentication]
→ Remove: [for] (common word)
→ Keep: [security, practices]
→ Result: "security_practices"

"Framework-specific authentication implementations"
→ Extract: [Framework, specific, authentication, implementations]
→ Keep: [framework, implementations] (concise)
→ Result: "framework_implementations"

**Common Topic Slugs** (use as guidance for consistency):
- existing_patterns
- best_practices
- security_practices
- alternatives
- framework_implementations
- performance_considerations
- migration_strategy
- integration_approaches

**VERIFY** before proceeding:
- workflow_state.project_name is set (will be used in specs path)
- workflow_state.topic_slugs array matches number of research_topics
- All slugs are lowercase with underscores only (no spaces, hyphens)

These values are used in Step 2 when constructing research agent prompts and report file paths.

#### Step 3a: Monitor Research Agent Execution

After invoking all research agents in Step 2, MONITOR their progress and execution.

**EXECUTE NOW**:

1. WATCH for PROGRESS: markers from each agent:
   - "PROGRESS: Starting research on [topic]..."
   - "PROGRESS: Searching codebase..."
   - "PROGRESS: Analyzing findings..."
   - "PROGRESS: Creating report file..."
   - "PROGRESS: Research complete."

2. DISPLAY progress to user in real-time:
   ```
   [Agent 1: existing_patterns] Searching codebase...
   [Agent 2: security_practices] Searching for best practices...
   [Agent 3: framework_implementations] Analyzing alternatives...
   ```

3. WAIT for ALL agents to complete before proceeding to Step 4

4. CHECK for agent errors or failures:
   - If agent fails: Note error, continue with other agents
   - If all agents fail: Escalate to user
   - If partial success: Proceed with available reports

**Expected Agent Completion Time**:
- Simple research: 1-2 minutes per agent
- Medium research: 2-4 minutes per agent
- Complex research: 4-6 minutes per agent

**Parallel Execution Benefit**:
- Sequential (one after another): 3 agents × 3 minutes = 9 minutes
- Parallel (all at once): max(3 minutes) = 3 minutes
- Time saved: ~66% for 3 agents

Proceed to Step 4 only after all agents complete or fail definitively.

#### Step 4: Collect Report Paths from Agent Output

EXTRACT report file paths from completed research agent outputs.

**EXECUTE NOW**:

For EACH completed research agent:

1. PARSE agent output for report path line:
   - Expected format: "REPORT_PATH: [path]"
   - Example: "REPORT_PATH: specs/reports/existing_patterns/001_auth_patterns.md"

2. EXTRACT the file path:
   - Remove "REPORT_PATH: " prefix
   - Trim whitespace
   - Validate path format (must contain specs/reports/{topic}/)

3. VALIDATE report file exists:
   ```bash
   # Use Read tool or Bash to verify
   if [ -f "$REPORT_PATH" ]; then
     echo "✓ Report exists: $REPORT_PATH"
   else
     echo "✗ Report missing: $REPORT_PATH"
     # Flag for retry or manual intervention
   fi
   ```

4. STORE valid report path in workflow_state.research_reports array:
   ```yaml
   workflow_state.research_reports: [
     "specs/reports/existing_patterns/001_auth_patterns.md",
     "specs/reports/security_practices/001_best_practices.md",
     "specs/reports/framework_implementations/001_lua_auth.md"
   ]
   ```

**Path Extraction Examples**:

Agent Output:
```
I've completed research on authentication patterns in the codebase.

REPORT_PATH: specs/reports/existing_patterns/001_auth_patterns.md

Summary: Found session-based auth using Redis with 30-minute TTL...
```

Extracted: `specs/reports/existing_patterns/001_auth_patterns.md`

**Context Reduction Achieved**:
- **Before**: Pass 200+ words of research summary to planning phase
- **After**: Pass 1 file path (~50 characters) to planning phase
- **Reduction**: 97% context savings per report
- **With 3 reports**: 600 words → 150 characters (99.75% savings)

**VERIFICATION CHECKLIST**:
- [ ] All research agents completed (or failed definitively)
- [ ] Report path extracted from each successful agent
- [ ] Report files exist and are readable
- [ ] Report paths stored in workflow_state.research_reports array
- [ ] Number of reports matches number of successful agents

If any report is missing or invalid:
- Retry agent invocation (max 1 retry per agent)
- If retry fails: Proceed with available reports, note missing reports
- If all reports missing: Escalate to user

Proceed to Step 5 only after all validations pass.

#### Step 5: Save Research Checkpoint

SAVE workflow checkpoint after research phase completion.

**EXECUTE NOW**:

USE the checkpoint utility to save research phase state:

```bash
# Source checkpoint utilities
source .claude/lib/checkpoint-utils.sh

# Prepare checkpoint data
CHECKPOINT_DATA=$(cat <<EOF
{
  "workflow_type": "orchestrate",
  "project_name": "${PROJECT_NAME}",
  "workflow_description": "${USER_WORKFLOW_DESCRIPTION}",
  "status": "research_complete",
  "current_phase": "research",
  "completed_phases": ["research"],
  "workflow_state": {
    "research_topics": ${RESEARCH_TOPICS_JSON},
    "research_reports": ${RESEARCH_REPORTS_JSON},
    "project_name": "${PROJECT_NAME}",
    "topic_slugs": ${TOPIC_SLUGS_JSON},
    "thinking_mode": "${THINKING_MODE}",
    "complexity_score": ${COMPLEXITY_SCORE}
  },
  "performance_metrics": {
    "research_start_time": "${RESEARCH_START_TIME}",
    "research_end_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "parallel_agents_used": ${NUM_RESEARCH_AGENTS},
    "reports_created": ${NUM_REPORTS_CREATED}
  },
  "next_phase": "planning"
}
EOF
)

# Save checkpoint
CHECKPOINT_PATH=$(save_checkpoint "orchestrate" "${PROJECT_NAME}" "$CHECKPOINT_DATA")
echo "Checkpoint saved: $CHECKPOINT_PATH"
```

**Checkpoint Fields Explanation**:

- **workflow_type**: Always "orchestrate" for this command
- **project_name**: Generated in Step 3.5, used for checkpoint filename
- **workflow_description**: Original user request
- **status**: "research_complete" indicates research phase finished
- **current_phase**: "research" (phase just completed)
- **completed_phases**: Array of all completed phases (["research"] so far)
- **workflow_state**: Complete state including reports, topics, complexity
- **performance_metrics**: Timing data for performance analysis
- **next_phase**: "planning" (where to resume if interrupted)

**Benefits**:
- **Resumability**: Workflow can be resumed if interrupted
- **State Preservation**: All research outputs preserved
- **Performance Tracking**: Metrics for optimization analysis
- **Error Recovery**: Can rollback to pre-planning state if needed

Proceed to Step 6 only after checkpoint successfully saved.

#### Step 6: Research Phase Execution Verification

VERIFY all research phase execution requirements before proceeding to planning phase.

**EXECUTE NOW**: Check each requirement explicitly.

**VERIFICATION CHECKLIST**:

1. **Agent Invocation Verified**:
   - [ ] Task tool invoked for each research topic
   - [ ] All Task invocations sent in SINGLE message (parallel execution)
   - [ ] All agents completed successfully OR failed with clear error message
   - Verification: Review agent invocation message, count Task tool calls

2. **Report Files Created**:
   - [ ] Each successful agent created a report file
   - [ ] Report files exist at expected paths: specs/reports/{topic_slug}/NNN_*.md
   - [ ] Report numbering follows NNN format (001, 002, 003...)
   - Verification: Use Read tool to verify each report file exists and is readable

3. **Report Paths Collected**:
   - [ ] REPORT_PATH extracted from each agent output
   - [ ] Report paths stored in workflow_state.research_reports array
   - [ ] Number of paths matches number of successful agents
   - Verification: Print workflow_state.research_reports array contents

4. **Report Metadata Complete**:
   - [ ] Each report includes all required metadata fields
   - [ ] Specs Directory field present in each report
   - [ ] Topic field matches topic_slug from Step 3.5
   - Verification: Read first 20 lines of each report, check for metadata section

5. **Checkpoint Saved**:
   - [ ] Research checkpoint saved successfully
   - [ ] Checkpoint file exists at expected path
   - [ ] Checkpoint includes all research_reports paths
   - Verification: Use bash to verify checkpoint file exists

**Verification Commands**:

```bash
# Verify report files exist
for REPORT in "${RESEARCH_REPORTS[@]}"; do
  if [ -f "$REPORT" ]; then
    echo "✓ Report exists: $REPORT"
  else
    echo "✗ MISSING: $REPORT"
    VALIDATION_FAILED=true
  fi
done

# Verify checkpoint saved
CHECKPOINT_FILE=".claude/checkpoints/orchestrate_${PROJECT_NAME}_*.json"
if ls $CHECKPOINT_FILE 1>/dev/null 2>&1; then
  echo "✓ Checkpoint saved"
else
  echo "✗ Checkpoint missing"
  VALIDATION_FAILED=true
fi

# If validation failed
if [ "$VALIDATION_FAILED" = true ]; then
  echo "ERROR: Research phase validation failed"
  echo "Review errors above and retry failed steps"
  exit 1
fi
```

**If Validation Fails**:

- **Missing Report Files**:
  - Retry agent invocation for missing reports (max 1 retry)
  - If retry fails: Proceed with available reports, document missing reports

- **Invalid Metadata**:
  - Use Edit tool to correct metadata in report file
  - Ensure all required fields present

- **Checkpoint Save Failed**:
  - Retry checkpoint save operation
  - If persistent: Continue without checkpoint (note resumption not possible)

**DO NOT PROCEED** to planning phase until all validation checks pass (or failures are explicitly handled).

**Success Output**:

```
✓ Research Phase Complete

Research Topics Investigated: 3
- existing_patterns
- security_practices
- framework_implementations

Reports Created: 3
- specs/reports/existing_patterns/001_auth_patterns.md
- specs/reports/security_practices/001_best_practices.md
- specs/reports/framework_implementations/001_lua_auth.md

Checkpoint Saved: .claude/checkpoints/orchestrate_user_authentication_20251012_143022.json

Performance:
- Total Time: 3m 24s
- Parallel Agents: 3
- Time Saved vs Sequential: ~68%

Next Phase: Planning
```

#### Step 7: Complete Research Phase Execution Example

**Full Workflow Example**: "Add user authentication with email and password"

**Step 1: Identify Research Topics**
```
Workflow: "Add user authentication with email and password"
Complexity Analysis: "add" (×1) + "authentication" (security) + ~8 files estimated
Complexity Score: 8 (Complex)

Research Topics Identified:
1. existing_patterns - Current authentication implementations in codebase
2. security_practices - Password hashing and session management (2025 standards)
3. framework_implementations - Lua-specific authentication libraries and patterns
```

**Step 1.5: Determine Thinking Mode**
```
Complexity Score: 8
Thinking Mode: "think hard" (score 7-9 = high complexity)
```

**Step 3.5: Generate Project Name and Topic Slugs**
```
Project Name: "user_authentication" (from "user authentication")

Topic Slugs:
1. "existing_patterns" (from "Current authentication implementations")
2. "security_practices" (from "Password hashing and session management")
3. "framework_implementations" (from "Lua-specific authentication libraries")
```

**Step 2: Launch Parallel Research Agents**
```
Invoking 3 research-specialist agents in parallel (single message):

Task {
  subagent_type: "general-purpose",
  description: "Research existing authentication patterns using research-specialist",
  prompt: "Read and follow: .claude/agents/research-specialist.md\n\n**Thinking Mode**: think hard\n\n# Research Task: Current Authentication Implementations\n\n[Full prompt with all placeholders substituted...]"
}

Task {
  subagent_type: "general-purpose",
  description: "Research security best practices using research-specialist",
  prompt: "Read and follow: .claude/agents/research-specialist.md\n\n**Thinking Mode**: think hard\n\n# Research Task: Password Hashing and Session Management Best Practices\n\n[Full prompt...]"
}

Task {
  subagent_type: "general-purpose",
  description: "Research Lua authentication libraries using research-specialist",
  prompt: "Read and follow: .claude/agents/research-specialist.md\n\n**Thinking Mode**: think hard\n\n# Research Task: Lua-Specific Authentication Libraries\n\n[Full prompt...]"
}
```

**Step 3a: Monitor Execution**
```
[Agent 1: existing_patterns] PROGRESS: Searching codebase for auth implementations...
[Agent 2: security_practices] PROGRESS: Searching for 2025 password hashing standards...
[Agent 3: framework_implementations] PROGRESS: Researching Lua auth libraries...
[Agent 1: existing_patterns] PROGRESS: Found 12 files, analyzing patterns...
[Agent 2: security_practices] PROGRESS: Analyzing Argon2 vs bcrypt recommendations...
[Agent 3: framework_implementations] PROGRESS: Comparing lua-resty-session vs custom...
[Agent 1: existing_patterns] PROGRESS: Creating report file...
[Agent 2: security_practices] PROGRESS: Creating report file...
[Agent 3: framework_implementations] PROGRESS: Creating report file...
[Agent 1: existing_patterns] PROGRESS: Research complete.
[Agent 2: security_practices] PROGRESS: Research complete.
[Agent 3: framework_implementations] PROGRESS: Research complete.

All agents completed in 3m 24s (sequential would be ~9m 30s)
```

**Step 4: Collect Report Paths**
```
Agent 1 Output: "REPORT_PATH: specs/reports/existing_patterns/001_auth_patterns.md"
Agent 2 Output: "REPORT_PATH: specs/reports/security_practices/001_best_practices.md"
Agent 3 Output: "REPORT_PATH: specs/reports/framework_implementations/001_lua_auth.md"

Workflow State Updated:
{
  "research_reports": [
    "specs/reports/existing_patterns/001_auth_patterns.md",
    "specs/reports/security_practices/001_best_practices.md",
    "specs/reports/framework_implementations/001_lua_auth.md"
  ]
}
```

**Step 5: Save Checkpoint**
```
Checkpoint saved: .claude/checkpoints/orchestrate_user_authentication_20251012_143022.json

Checkpoint contents:
{
  "workflow_type": "orchestrate",
  "project_name": "user_authentication",
  "status": "research_complete",
  "current_phase": "research",
  "workflow_state": {
    "research_reports": [...],
    "thinking_mode": "think hard",
    "complexity_score": 8
  },
  "next_phase": "planning"
}
```

**Step 6: Validation**
```
✓ 3 Task tool invocations sent in single message
✓ All 3 agents completed successfully
✓ 3 report files created and validated
✓ 3 report paths collected in workflow_state
✓ Checkpoint saved successfully

Research Phase Complete - Ready for Planning Phase
```

This example demonstrates the complete execution flow from user request to validated research reports.

### Planning Phase (Sequential Execution)

#### Step 1: Prepare Planning Context

EXTRACT necessary context from completed workflow phases for the planning agent.

**EXECUTE NOW**:

1. READ workflow_state to identify completed phases and available artifacts
2. EXTRACT research report paths from workflow_state.research_reports array (if research phase completed)
3. EXTRACT user's original workflow description
4. EXTRACT project_name and thinking_mode from workflow_state
5. VERIFY all referenced files exist before passing to planning agent

**Context Sources**:

**From Research Phase** (if research completed):
```yaml
research_context:
  report_paths: workflow_state.research_reports  # Array of file paths only
  topics: workflow_state.topic_slugs  # Topics investigated
  # DO NOT read report content - agent will use Read tool selectively
```

**Example**:
```yaml
research_context:
  report_paths: [
    "specs/reports/existing_patterns/001_auth_patterns.md",
    "specs/reports/security_practices/001_best_practices.md",
    "specs/reports/framework_implementations/001_lua_auth.md"
  ]
  topics: ["existing_patterns", "security_practices", "framework_implementations"]
```

**From User Request**:
```yaml
user_context:
  workflow_description: workflow_state.workflow_description  # Original user request
  project_name: workflow_state.project_name  # Generated in research phase
  workflow_type: workflow_state.workflow_type  # feature|refactor|debug|investigation
  thinking_mode: workflow_state.thinking_mode  # Determined in research phase Step 1.5
```

**From Project Standards**:
```yaml
standards_reference:
  claude_md_path: "/home/benjamin/.config/CLAUDE.md"
  # Agent will read this file for project-specific standards
```

**Context Injection Strategy**:
- Provide report file paths ONLY (not full summaries) - agent uses Read tool to access content selectively
- Include user's original request for full context understanding
- Reference CLAUDE.md path for project standards
- Include thinking_mode from research phase for consistency
- NO orchestration details or phase routing logic passed to agent

**Context Validation Checklist**:
- [ ] Research report paths exist (if research phase completed)
- [ ] User workflow description is clear and complete
- [ ] Project name is set correctly
- [ ] Thinking mode is specified (if applicable)
- [ ] CLAUDE.md path is valid

#### Step 2: Generate Planning Agent Prompt

GENERATE the complete prompt for the plan-architect agent using the template below.

**EXECUTE NOW**:

1. SUBSTITUTE all placeholders in the template with actual values from Step 1
2. VERIFY all research report paths are included (if research phase completed)
3. VERIFY thinking_mode is prepended if applicable
4. CONSTRUCT complete prompt string for Task tool invocation

**Placeholders to Substitute**:
- [THINKING_MODE]: Value from workflow_state.thinking_mode (e.g., "think hard") or empty if not set
- [FEATURE_NAME]: Extracted from workflow_description or project_name
- [USER_WORKFLOW_DESCRIPTION]: Original user request from workflow_state
- [REPORT_PATHS]: Array of research report paths with descriptions
- [PROJECT_STANDARDS_PATH]: Path to CLAUDE.md

**Complete Prompt Template**:

```markdown
[THINKING_MODE_LINE]

# Planning Task: Create Implementation Plan for [FEATURE_NAME]

## Context

### User Request
[Original workflow description]

### Research Reports
[If research phase completed, provide report paths:]

Available Research Reports:
1. **Existing Patterns**
   - Path: specs/reports/existing_patterns/001_auth_patterns.md
   - Topic: Current implementation analysis
   - Use Read tool to access full findings

2. **Security Practices**
   - Path: specs/reports/security_practices/001_best_practices.md
   - Topic: Industry standards (2025)
   - Use Read tool to access recommendations

3. **Framework Implementations**
   - Path: specs/reports/framework_implementations/001_lua_auth.md
   - Topic: Implementation options and trade-offs
   - Use Read tool to access detailed comparisons

**Instructions**: Read relevant reports selectively based on planning needs. All reports should be referenced in the plan metadata's "Research Reports" section.

[If no research: "Direct implementation - no prior research reports"]

### Project Standards
Reference standards at: /home/benjamin/.config/CLAUDE.md

## Objective
Create a comprehensive, phased implementation plan for [feature/task] that:
- Synthesizes research findings into actionable steps
- Defines clear implementation phases with tasks
- Establishes testing strategy for each phase
- Follows project coding standards and conventions

## Requirements

### Plan Structure
Use the /plan command to generate a structured implementation plan:

```bash
/plan [feature description] [research-report-path-if-exists]
```

The plan should include:
- Metadata (date, feature, scope, standards file, research reports)
- Overview and success criteria
- Technical design decisions
- Implementation phases with specific tasks
- Testing strategy
- Documentation requirements
- Risk assessment

### Task Specificity
Each task should:
- Reference specific files to create/modify
- Include line number ranges where applicable
- Specify testing requirements
- Define validation criteria

### Context from Research
[If research completed]
Incorporate these key findings:
- [Insight 1]
- [Insight 2]
- [Insight 3]

Recommended approach: [From research synthesis]

## Expected Output

**Primary Output**: Path to generated implementation plan
- Format: `specs/plans/NNN_feature_name.md`
- Location: Most appropriate directory in project structure
- **Note**: The /plan command will automatically:
  - Read specs directory from research reports (if provided)
  - Check/register in `.claude/SPECS.md`
  - Include "Specs Directory" in plan metadata

**Secondary Output**: Brief summary of plan
- Number of phases
- Estimated complexity
- Key technical decisions

## Success Criteria
- Plan follows project standards (CLAUDE.md)
- Phases are well-defined and testable
- Tasks are specific and actionable
- Testing strategy is comprehensive
- Plan integrates research recommendations

## Error Handling
- If /plan command fails: Report error and provide manual planning guidance
- If standards unclear: Make reasonable assumptions following best practices
- If research conflicts: Document trade-offs and chosen approach
```

End of prompt template.

**Prompt Verification Checklist**:
- [ ] Thinking mode prepended if applicable (check workflow_state.thinking_mode)
- [ ] Feature name substituted correctly
- [ ] User workflow description included
- [ ] Research report paths listed (if research phase completed) or "no prior research" noted
- [ ] Project standards path (/home/benjamin/.config/CLAUDE.md) included
- [ ] Expected output format specified (plan file path + summary)
- [ ] Success criteria clearly defined

#### Step 3: Invoke Planning Agent

**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

SEND this Task tool invocation NOW with these exact parameters:

```json
{
  "subagent_type": "general-purpose",
  "description": "Create implementation plan for [FEATURE_NAME] using plan-architect protocol",
  "prompt": "Read and follow the behavioral guidelines from:\n/home/benjamin/.config/.claude/agents/plan-architect.md\n\nYou are acting as a Plan Architect with the tools and constraints defined in that file.\n\n[COMPLETE_PROMPT_FROM_STEP_2]"
}
```

**Substitutions**:
- [FEATURE_NAME]: Feature name from workflow_state.project_name
- [COMPLETE_PROMPT_FROM_STEP_2]: Full prompt string generated in Step 2 (with all placeholders already substituted)

**Execution Details**:
- This is a SINGLE agent invocation (sequential execution, not parallel)
- Agent has full access to project files for analysis
- Agent can invoke /plan slash command
- Agent will return plan file path and summary

**WAIT** for planning agent to complete before proceeding to Step 4.

**Monitoring**:
- **Progress Streaming**: WATCH for `PROGRESS: <message>` markers in agent output
  - Examples: `PROGRESS: Analyzing requirements...`, `PROGRESS: Designing 4 phases...`
  - DISPLAY progress updates to user in real-time
- Track planning progress through agent updates
- Watch for plan file creation notification

#### Step 4: Extract Plan Path and Validation

EXTRACT plan file path from planning agent output and VALIDATE plan quality.

**EXECUTE NOW**:

1. PARSE agent output to extract plan file path
2. EXTRACT plan metadata (number, phases, complexity)
3. VALIDATE plan file exists and is well-formed
4. VERIFY plan meets quality requirements

**Path Extraction Algorithm**:

From planning agent output:

```
Step 1: SEARCH for plan path pattern
- Pattern: "specs/plans/NNN_*.md" or "PLAN_PATH: specs/plans/..."
- Extract: Full file path

Step 2: PARSE plan metadata
- Plan number: NNN (from filename)
- Read file metadata section
- Extract: phase_count, complexity, research_reports

Step 3: CONSTRUCT plan data structure
plan_data = {
  path: "specs/plans/NNN_feature_name.md",
  number: NNN,
  phase_count: N,
  complexity: "Low|Medium|High"
}

Step 4: STORE in workflow_state
workflow_state.plan_path = plan_data.path
workflow_state.plan_number = plan_data.number
```

**Validation Bash Commands**:

```bash
# Verify plan file exists
PLAN_PATH="specs/plans/NNN_feature_name.md"
if [ -f "$PLAN_PATH" ]; then
  echo "✓ Plan file exists: $PLAN_PATH"
else
  echo "✗ Plan file missing: $PLAN_PATH"
  exit 1
fi

# Verify plan has required sections
REQUIRED_SECTIONS=("## Metadata" "## Overview" "## Implementation Phases" "## Testing Strategy")
for SECTION in "${REQUIRED_SECTIONS[@]}"; do
  if grep -q "$SECTION" "$PLAN_PATH"; then
    echo "✓ Section found: $SECTION"
  else
    echo "✗ Missing section: $SECTION"
    VALIDATION_FAILED=true
  fi
done

# Verify plan references research reports (if research phase completed)
if [ ${#RESEARCH_REPORTS[@]} -gt 0 ]; then
  if grep -q "Research Reports:" "$PLAN_PATH"; then
    echo "✓ Plan references research reports"
  else
    echo "⚠ Warning: Plan doesn't reference research reports"
  fi
fi
```

**Validation Checklist**:
- [ ] Plan file exists at expected path
- [ ] Plan file is readable (not empty, not corrupted)
- [ ] Plan includes required metadata fields (Date, Feature, Scope, Standards File)
- [ ] Plan has Implementation Phases section with numbered phases
- [ ] Plan includes Testing Strategy section
- [ ] Plan tasks reference specific files (not just abstract descriptions)
- [ ] Plan references research reports in metadata (if research phase completed)

**If Validation Fails**:
- **Missing File**: Check agent output for errors, retry planning agent invocation (max 1 retry)
- **Incomplete Plan**: Invoke planning agent again with clarification about missing sections
- **No File References**: Accept plan but note tasks may be less specific than desired
- **If Retry Fails**: Escalate to user with error details and partial plan (if exists)

#### Step 5: Save Planning Checkpoint

SAVE workflow checkpoint after planning phase completion.

**EXECUTE NOW**:

USE the checkpoint utility to save planning phase state:

```bash
# Source checkpoint utilities
source .claude/lib/checkpoint-utils.sh

# Prepare checkpoint data
CHECKPOINT_DATA=$(cat <<EOF
{
  "workflow_type": "orchestrate",
  "project_name": "${PROJECT_NAME}",
  "workflow_description": "${USER_WORKFLOW_DESCRIPTION}",
  "status": "plan_ready",
  "current_phase": "planning",
  "completed_phases": ["research", "planning"],
  "workflow_state": {
    "research_reports": ${RESEARCH_REPORTS_JSON},
    "plan_path": "${PLAN_PATH}",
    "plan_number": ${PLAN_NUMBER},
    "phase_count": ${PHASE_COUNT},
    "complexity": "${COMPLEXITY}",
    "thinking_mode": "${THINKING_MODE}"
  },
  "performance_metrics": {
    "research_time": "${RESEARCH_DURATION}",
    "planning_start_time": "${PLANNING_START_TIME}",
    "planning_end_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "planning_duration": "${PLANNING_DURATION}"
  },
  "next_phase": "implementation"
}
EOF
)

# Save checkpoint
CHECKPOINT_PATH=$(save_checkpoint "orchestrate" "${PROJECT_NAME}" "$CHECKPOINT_DATA")
echo "Checkpoint saved: $CHECKPOINT_PATH"
```

**Checkpoint Fields Explanation**:

- **workflow_type**: Always "orchestrate" for this command
- **project_name**: Generated in research phase Step 3.5
- **workflow_description**: Original user request
- **status**: "plan_ready" indicates planning phase complete
- **current_phase**: "planning" (phase just completed)
- **completed_phases**: Array of all completed phases (["research", "planning"] or just ["planning"] if research skipped)
- **workflow_state.plan_path**: Plan file path for implementation phase
- **workflow_state.plan_number**: Plan number (NNN) for reference
- **workflow_state.phase_count**: Number of implementation phases
- **workflow_state.complexity**: Plan complexity (Low|Medium|High)
- **performance_metrics**: Timing data for performance analysis
- **next_phase**: "implementation" (where to resume if interrupted)

**Context Update**:
- Store ONLY plan path in workflow_state, not plan content (agent will read file when needed)
- Mark planning phase as completed in completed_phases array
- Prepare workflow_state for implementation phase

**Benefits**:
- **Resumability**: Can resume from implementation phase if interrupted
- **State Preservation**: Plan path and metadata preserved
- **Performance Tracking**: Planning duration recorded for metrics
- **Error Recovery**: Can rollback to pre-implementation state if needed

Proceed to Step 6 only after checkpoint successfully saved.

#### Step 6: Planning Phase Completion

OUTPUT completion status to user with comprehensive details.

**EXECUTE NOW**:

1. VERIFY all planning phase success criteria met
2. FORMAT completion message with plan details
3. DISPLAY status to user
4. CONFIRM transition to implementation phase

**Success Criteria Verification**:
- [ ] Plan file created successfully
- [ ] Plan includes all required sections (Metadata, Phases, Testing)
- [ ] Plan metadata complete (Date, Scope, Standards)
- [ ] Plan references research reports (if research phase completed)
- [ ] Checkpoint saved successfully
- [ ] workflow_state updated with plan_path

**Completion Message Format**:

```markdown
✓ Planning Phase Complete

**Plan Created**: specs/plans/NNN_feature_name.md

**Plan Details**:
- Plan Number: NNN
- Implementation Phases: N
- Complexity: Medium
- Estimated Hours: X-Y

[If research phase completed]
**Incorporating Research From**:
- specs/reports/existing_patterns/001_auth_patterns.md
- specs/reports/security_practices/001_best_practices.md
- specs/reports/framework_implementations/001_lua_auth.md

**Performance**:
- Planning Time: X minutes Y seconds

**Checkpoint Saved**: .claude/checkpoints/orchestrate_[project_name]_[timestamp].json

**Next Phase**: Implementation
```

**Transition Confirmation**:

After displaying completion message, confirm workflow will proceed to implementation phase:
```
→ Proceeding to Implementation Phase
```

Proceed immediately to Implementation Phase Step 1 (Prepare Implementation Context).

#### Step 7: Complete Planning Phase Execution Example

**Full Workflow Example**: "Add user authentication with email and password" (continuing from completed Research Phase)

**Context from Research Phase**:
```
Research Phase Completed:
- 3 research reports created
- Project name: "user_authentication"
- Thinking mode: "think hard"
- Complexity score: 8
```

**Step 1: Prepare Planning Context**
```
EXTRACT context from workflow_state:

research_context:
  report_paths: [
    "specs/reports/existing_patterns/001_auth_patterns.md",
    "specs/reports/security_practices/001_best_practices.md",
    "specs/reports/framework_implementations/001_lua_auth.md"
  ]
  topics: ["existing_patterns", "security_practices", "framework_implementations"]

user_context:
  workflow_description: "Add user authentication with email and password"
  project_name: "user_authentication"
  workflow_type: "feature"
  thinking_mode: "think hard"

standards_reference:
  claude_md_path: "/home/benjamin/.config/CLAUDE.md"

Context validation:
✓ 3 research report paths exist
✓ User workflow description clear
✓ Project name set: user_authentication
✓ Thinking mode specified: think hard
✓ CLAUDE.md path valid
```

**Step 2: Generate Planning Agent Prompt**
```
SUBSTITUTE placeholders in template:

- [THINKING_MODE]: "**Thinking Mode**: think hard"
- [FEATURE_NAME]: "User Authentication"
- [USER_WORKFLOW_DESCRIPTION]: "Add user authentication with email and password"
- [REPORT_PATHS]:
  1. specs/reports/existing_patterns/001_auth_patterns.md - Current auth patterns
  2. specs/reports/security_practices/001_best_practices.md - Security standards (2025)
  3. specs/reports/framework_implementations/001_lua_auth.md - Lua auth libraries
- [PROJECT_STANDARDS_PATH]: /home/benjamin/.config/CLAUDE.md

Prompt verification:
✓ Thinking mode prepended
✓ Feature name substituted
✓ User workflow description included
✓ All 3 research reports listed
✓ Project standards path included
✓ Expected output format specified
```

**Step 3: Invoke Planning Agent**
```
Task tool invocation sent:

{
  "subagent_type": "general-purpose",
  "description": "Create implementation plan for User Authentication using plan-architect protocol",
  "prompt": "Read and follow: .claude/agents/plan-architect.md\n\n**Thinking Mode**: think hard\n\n# Planning Task: Create Implementation Plan for User Authentication\n\n[Complete prompt with all substitutions...]"
}

Agent execution:
PROGRESS: Reading research reports...
PROGRESS: Analyzing security requirements from reports...
PROGRESS: Designing 4 implementation phases...
PROGRESS: Creating plan file...
PROGRESS: Planning complete.

Agent completed in 2m 45s
```

**Step 4: Extract Plan Path and Validation**
```
Agent output:
"I've created a comprehensive implementation plan at specs/plans/013_user_authentication.md.
The plan includes 4 phases with approximately 12-15 hours of implementation work..."

Extracted plan data:
{
  path: "specs/plans/013_user_authentication.md",
  number: "013",
  phase_count: 4,
  complexity: "Medium"
}

Validation commands executed:
✓ Plan file exists: specs/plans/013_user_authentication.md
✓ Section found: ## Metadata
✓ Section found: ## Overview
✓ Section found: ## Implementation Phases
✓ Section found: ## Testing Strategy
✓ Plan references research reports

All validations passed
```

**Step 5: Save Planning Checkpoint**
```
Checkpoint saved: .claude/checkpoints/orchestrate_user_authentication_20251012_145810.json

Checkpoint contents:
{
  "workflow_type": "orchestrate",
  "project_name": "user_authentication",
  "status": "plan_ready",
  "current_phase": "planning",
  "completed_phases": ["research", "planning"],
  "workflow_state": {
    "research_reports": [
      "specs/reports/existing_patterns/001_auth_patterns.md",
      "specs/reports/security_practices/001_best_practices.md",
      "specs/reports/framework_implementations/001_lua_auth.md"
    ],
    "plan_path": "specs/plans/013_user_authentication.md",
    "plan_number": "013",
    "phase_count": 4,
    "complexity": "Medium",
    "thinking_mode": "think hard"
  },
  "performance_metrics": {
    "research_time": "3m 24s",
    "planning_duration": "2m 45s"
  },
  "next_phase": "implementation"
}
```

**Step 6: Planning Phase Completion**
```
✓ Planning Phase Complete

**Plan Created**: specs/plans/013_user_authentication.md

**Plan Details**:
- Plan Number: 013
- Implementation Phases: 4
- Complexity: Medium
- Estimated Hours: 12-15

**Incorporating Research From**:
- specs/reports/existing_patterns/001_auth_patterns.md
- specs/reports/security_practices/001_best_practices.md
- specs/reports/framework_implementations/001_lua_auth.md

**Performance**:
- Planning Time: 2 minutes 45 seconds

**Checkpoint Saved**: .claude/checkpoints/orchestrate_user_authentication_20251012_145810.json

**Next Phase**: Implementation

→ Proceeding to Implementation Phase
```

This example demonstrates the complete planning phase execution flow from research output to validated implementation plan.

### Implementation Phase (Adaptive Execution)

#### Step 1: Extract Implementation Context

EXTRACT plan path and metadata from planning phase output to prepare for implementation agent invocation.

**EXECUTE NOW: Extract Context from Planning Phase**

From the planning phase checkpoint (saved in Step 5 of Planning Phase), EXTRACT:

1. **Plan File Path**:
   - Variable: plan_path
   - Example: "specs/plans/042_user_authentication.md"
   - Source: planning_phase_checkpoint.outputs.plan_path

2. **Plan Metadata**:
   - Plan number: Extract from filename (NNN prefix)
   - Phase count: Read from plan file metadata
   - Complexity level: Read from plan metadata or estimate

3. **Store in workflow_state**:
   ```yaml
   workflow_state.implementation_context:
     plan_path: "[extracted_path]"
     plan_number: "[NNN]"
     phase_count: "[N]"
     complexity: "[Low|Medium|High]"
   ```

**Context Extraction Commands**:
```bash
# Extract plan path from checkpoint
PLAN_PATH=$(jq -r '.outputs.plan_path' < checkpoint_plan_ready.json)

# Extract plan number from filename
PLAN_NUMBER=$(basename "$PLAN_PATH" | grep -oP '^\d+')

# Read phase count from plan file
PHASE_COUNT=$(grep -c "^### Phase" "$PLAN_PATH")

# Read complexity from metadata
COMPLEXITY=$(grep "^- \*\*Complexity\*\*:" "$PLAN_PATH" | cut -d: -f2 | tr -d ' ')
```

**Validation**:
- Verify plan file exists: Use Read tool to check plan_path
- Verify plan is complete: Check for all required sections (phases, tasks, testing)
- If validation fails: Report error and halt workflow

**Verification Checklist**:
- [ ] Plan path extracted and validated (file exists)
- [ ] Plan number parsed correctly (3-digit format)
- [ ] Phase count matches plan structure
- [ ] Complexity level identified or defaulted

#### Step 2: Build Implementation Agent Prompt

**EXECUTE NOW: Construct Code-Writer Prompt**

BUILD the complete prompt for the code-writer agent using this template:

**Prompt Template** (use verbatim, substituting bracketed variables):

```
Read and follow the behavioral guidelines from:
/home/benjamin/.config/.claude/agents/code-writer.md

You are acting as a Code Writer Agent with the tools and constraints
defined in that file.

# Implementation Task: Execute Implementation Plan

## Context

### Implementation Plan
Plan file: [plan_path]
Plan number: [plan_number]
Total phases: [phase_count]
Complexity: [complexity]

Read the complete plan to understand:
- All implementation phases
- Specific tasks for each phase
- Testing requirements per phase
- Success criteria

### Project Standards
Reference standards at: /home/benjamin/.config/CLAUDE.md

Apply these standards during code generation:
- Indentation: 2 spaces, expandtab
- Naming: snake_case for variables/functions
- Error handling: Use pcall for Lua, try-catch for others
- Line length: ~100 characters soft limit
- Documentation: Comment non-obvious logic

## Objective

Execute the implementation plan phase by phase using the /implement command.

## Requirements

### Execution Approach

Use the /implement command to execute the plan:

```bash
/implement [plan_path]
```

The /implement command will:
- Parse plan and identify all phases with dependencies
- Execute phases in dependency order (parallel where possible)
- Run tests after each phase
- Create git commit for each completed phase
- Handle errors with automatic retry (max 3 attempts)
- Update plan with completion markers

### Phase-by-Phase Execution

For each phase, /implement will:
1. Display phase name and tasks
2. Implement all tasks in phase following project standards
3. Run phase-specific tests
4. Validate all tests pass
5. Create structured git commit
6. Save checkpoint before next phase

### Testing Requirements

**CRITICAL**: Tests must run after EACH phase, not just at the end.

- Run tests after completing each phase
- Tests must pass before proceeding to next phase
- If tests fail: STOP and report (do not continue to next phase)
- Test commands: Use commands specified in plan or project CLAUDE.md

### Error Handling

- Automatic retry for transient errors (max 3 attempts per operation)
- If tests fail: DO NOT proceed to next phase
- Report test failures with detailed error messages and file locations
- Preserve all completed work even if later phase fails
- Save checkpoint at failure point for debugging

## Expected Output

**SUCCESS CASE** - All Phases Complete:
```
TESTS_PASSING: true
PHASES_COMPLETED: [N]/[N]
FILES_MODIFIED: [file1.ext, file2.ext, ...]
GIT_COMMITS: [hash1, hash2, ...]
IMPLEMENTATION_STATUS: success
```

**FAILURE CASE** - Tests Failed:
```
TESTS_PASSING: false
PHASES_COMPLETED: [M]/[N]
FAILED_PHASE: [N]
ERROR_MESSAGE: [Test failure details with file locations]
FILES_MODIFIED: [files changed before failure]
IMPLEMENTATION_STATUS: failed
```

## Output Format Requirements

**REQUIRED**: Structure your final output to include these exact markers so the orchestrator can parse results:

1. Test status line: `TESTS_PASSING: true` or `TESTS_PASSING: false`
2. Phases completed line: `PHASES_COMPLETED: M/N`
3. If failed, include: `FAILED_PHASE: N` and `ERROR_MESSAGE: [details]`
4. File changes line: `FILES_MODIFIED: [array of file paths]`
5. Git commits line: `GIT_COMMITS: [array of commit hashes]`

## Success Criteria

- All plan phases executed successfully (N/N)
- All tests passing after final phase
- Code follows project standards (verified before each commit)
- Git commits created for each phase with structured messages
- No merge conflicts or build errors
- Implementation status clearly indicated

## Error Handling

- **Timeout errors**: Retry with extended timeout (up to 600000ms)
- **Test failures**: STOP immediately, report phase and error details
- **Tool access errors**: Retry with available tools (Read/Write/Edit fallback)
- **Persistent errors**: Report for debugging (do not skip or ignore)
```

**Variable Substitution**:
Replace these variables from workflow_state:
- [plan_path]: workflow_state.implementation_context.plan_path
- [plan_number]: workflow_state.implementation_context.plan_number
- [phase_count]: workflow_state.implementation_context.phase_count
- [complexity]: workflow_state.implementation_context.complexity

**Store Prompt**:
```yaml
workflow_state.implementation_prompt: "[generated_prompt]"
```

#### Step 3: Invoke Code-Writer Agent for Implementation

**EXECUTE NOW: USE Task Tool to Invoke Code-Writer Agent**

Invoke the code-writer agent NOW using the Task tool with these exact parameters:

**Task Tool Invocation** (execute this call):

```json
{
  "subagent_type": "general-purpose",
  "description": "Execute implementation plan [plan_number] using code-writer protocol",
  "timeout": 600000,
  "prompt": "[workflow_state.implementation_prompt from Step 2]"
}
```

**Timeout Justification**: 600000ms (10 minutes) allows for:
- Multi-phase implementation (4-8 phases typical)
- Test execution after each phase
- Git commit creation per phase
- Automatic error retry (up to 3 attempts)
- Complex implementations with many files

**Invocation Instructions**:
1. USE the Task tool (not SlashCommand or Bash)
2. SET subagent_type to "general-purpose"
3. SET timeout to 600000 (not default 120000)
4. PASS complete prompt from Step 2 verbatim
5. WAIT for agent completion (do not proceed to Step 4 until done)

**While Waiting for Agent**:

Monitor agent output for PROGRESS markers:
- `PROGRESS: Implementing Phase N: [phase name]...`
- `PROGRESS: Running tests for Phase N...`
- `PROGRESS: Creating git commit for Phase N...`
- `PROGRESS: All tests passing, proceeding to Phase N+1...`

Display progress updates to user in real-time for transparency.

**After Agent Completes**:
Store complete agent output for parsing in Step 4:
```yaml
workflow_state.implementation_output: "[agent_output]"
```

**Verification Checklist**:
- [ ] Task tool invoked (not just described)
- [ ] Timeout set to 600000ms (extended for complex implementations)
- [ ] Agent type set to "general-purpose"
- [ ] Complete prompt passed to agent
- [ ] Agent output captured for status extraction

#### Step 4: Parse Implementation Results and Test Status

**EXECUTE NOW: Extract Status from Agent Output**

PARSE the agent output (workflow_state.implementation_output) to extract implementation results.

**Status Extraction Algorithm**:

```python
# Pseudo-code for status extraction

# 1. Extract test status
if "TESTS_PASSING: true" in agent_output:
    tests_passing = True
elif "TESTS_PASSING: false" in agent_output:
    tests_passing = False
else:
    # Fallback: search for test result indicators
    if "all tests pass" in agent_output.lower() or "✓ all passing" in agent_output.lower():
        tests_passing = True
    else:
        tests_passing = False

# 2. Extract phases completed
match = re.search(r'PHASES_COMPLETED: (\d+)/(\d+)', agent_output)
if match:
    completed = int(match.group(1))
    total = int(match.group(2))
else:
    # Fallback: count completed phase markers
    completed = agent_output.count('[COMPLETED]')
    total = workflow_state.implementation_context.phase_count

# 3. Extract file changes
match = re.search(r'FILES_MODIFIED: \[(.*?)\]', agent_output)
if match:
    files_modified = match.group(1).split(', ')
else:
    # Fallback: empty list
    files_modified = []

# 4. Extract git commits
match = re.search(r'GIT_COMMITS: \[(.*?)\]', agent_output)
if match:
    git_commits = match.group(1).split(', ')
else:
    git_commits = []

# 5. If tests failed, extract failure details
if not tests_passing:
    match = re.search(r'FAILED_PHASE: (\d+)', agent_output)
    failed_phase = int(match.group(1)) if match else None

    match = re.search(r'ERROR_MESSAGE: (.*?)(?:\n|$)', agent_output)
    error_message = match.group(1) if match else "Unknown error"
```

**Concrete Extraction Commands**:

```bash
# Extract test status
TESTS_PASSING=$(echo "$AGENT_OUTPUT" | grep -oP 'TESTS_PASSING: \K(true|false)' || echo "false")

# Extract phases completed
PHASES_COMPLETED=$(echo "$AGENT_OUTPUT" | grep -oP 'PHASES_COMPLETED: \K\d+/\d+' || echo "0/0")

# Extract modified files
FILES_MODIFIED=$(echo "$AGENT_OUTPUT" | grep -oP 'FILES_MODIFIED: \[\K[^\]]+' || echo "")

# Extract git commits
GIT_COMMITS=$(echo "$AGENT_OUTPUT" | grep -oP 'GIT_COMMITS: \[\K[^\]]+' || echo "")

# If tests failed, extract failure details
if [ "$TESTS_PASSING" = "false" ]; then
    FAILED_PHASE=$(echo "$AGENT_OUTPUT" | grep -oP 'FAILED_PHASE: \K\d+' || echo "unknown")
    ERROR_MESSAGE=$(echo "$AGENT_OUTPUT" | grep -oP 'ERROR_MESSAGE: \K.*' || echo "Unknown error")
fi
```

**Store Results in Workflow State**:

```yaml
workflow_state.implementation_status:
  tests_passing: [true|false]
  phases_completed: "[M]/[N]"
  files_modified: [array]
  git_commits: [array]
  status: "success|failed"

# If failed:
workflow_state.implementation_failure:
  failed_phase: [N]
  error_message: "[details]"
  partial_completion: true
```

**Validation Checklist**:
- [ ] Test status clearly extracted (true or false, not ambiguous)
- [ ] Phase completion count matches plan structure
- [ ] If tests passing: files_modified and git_commits present
- [ ] If tests failing: failed_phase and error_message present
- [ ] Status stored for use in Step 5 conditional branching

**Error Handling**:
If status extraction fails (cannot determine test status):
- Log warning: "Could not parse implementation status from agent output"
- Default to: tests_passing = false (safe default, triggers debugging)
- Continue to Step 5 with failure status

#### Step 5: Evaluate Test Status and Determine Next Phase

**EXECUTE NOW: Branch Workflow Based on Test Results**

EVALUATE the test status extracted in Step 4 and ROUTE the workflow accordingly.

**Branching Decision Tree**:

```
READ workflow_state.implementation_status.tests_passing

IF tests_passing == true:
    ├─→ ROUTE: Documentation Phase (Phase 6)
    ├─→ CHECKPOINT: implementation_complete
    ├─→ STATUS: Implementation successful, all tests passing
    └─→ PROCEED to Step 6 (Save Success Checkpoint)

ELSE (tests_passing == false):
    ├─→ ROUTE: Debugging Loop (Phase 5)
    ├─→ CHECKPOINT: implementation_incomplete
    ├─→ STATUS: Implementation failed, debugging required
    ├─→ PREPARE: Debug context with error details
    └─→ PROCEED to Step 6 (Save Failure Checkpoint)
```

**Decision Implementation**:

```python
# Execute this branching logic

if workflow_state.implementation_status.tests_passing == True:
    # SUCCESS PATH
    next_phase = "documentation"
    checkpoint_type = "implementation_complete"
    workflow_status = "Tests passing, implementation successful"

    # Prepare documentation context
    documentation_context = {
        "plan_path": workflow_state.implementation_context.plan_path,
        "files_modified": workflow_state.implementation_status.files_modified,
        "git_commits": workflow_state.implementation_status.git_commits,
        "test_status": "all passing"
    }

else:
    # FAILURE PATH
    next_phase = "debugging"
    checkpoint_type = "implementation_incomplete"
    workflow_status = "Tests failing, debugging required"

    # Prepare debugging context
    debug_context = {
        "plan_path": workflow_state.implementation_context.plan_path,
        "failed_phase": workflow_state.implementation_failure.failed_phase,
        "error_message": workflow_state.implementation_failure.error_message,
        "files_modified": workflow_state.implementation_status.files_modified,
        "phases_completed": workflow_state.implementation_status.phases_completed
    }
```

**Context Preparation**:

**FOR SUCCESS PATH** (tests passing):
```yaml
workflow_state.next_phase: "documentation"
workflow_state.documentation_context:
  plan_path: "[path]"
  implementation_complete: true
  files_modified: [array]
  git_commits: [array]
  test_results: "all passing"
```

**FOR FAILURE PATH** (tests failing):
```yaml
workflow_state.next_phase: "debugging"
workflow_state.debug_context:
  plan_path: "[path]"
  failed_phase: [N]
  error_message: "[details]"
  files_modified: [array]
  phases_completed: "[M]/[N]"
  iteration: 0
```

**Store Branch Decision**:
```yaml
workflow_state.implementation_branch:
  decision: "success|failure"
  next_phase: "documentation|debugging"
  timestamp: "[ISO 8601 timestamp]"
  reason: "[Test status explanation]"
```

**Verification Checklist**:
- [ ] Test status evaluated (not skipped)
- [ ] Branch decision made (success or failure path chosen)
- [ ] Context prepared for next phase
- [ ] Workflow state updated with next_phase
- [ ] If failure: debug_context includes all error details

#### Step 6: Save Checkpoint for Implementation Phase

**EXECUTE NOW: Save Checkpoint Based on Branch Decision**

SAVE checkpoint using checkpoint-utils.sh based on the branch decision from Step 5.

**Checkpoint Creation**:

**IF SUCCESS PATH** (tests passing):

```bash
# Create success checkpoint
CHECKPOINT_DATA=$(cat <<EOF
{
  "workflow": "orchestrate",
  "phase_name": "implementation",
  "completion_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "outputs": {
    "tests_passing": true,
    "phases_completed": "${PHASES_COMPLETED}",
    "files_modified": [${FILES_MODIFIED}],
    "git_commits": [${GIT_COMMITS}],
    "status": "success"
  },
  "next_phase": "documentation",
  "branch_decision": "success",
  "performance": {
    "implementation_time": "${DURATION_SECONDS}s",
    "phases_executed": ${PHASE_COUNT}
  },
  "context_for_next_phase": {
    "plan_path": "${PLAN_PATH}",
    "files_modified": [${FILES_MODIFIED}],
    "git_commits": [${GIT_COMMITS}]
  }
}
EOF
)

# Save checkpoint
.claude/lib/save-checkpoint.sh orchestrate "implementation_complete" "$CHECKPOINT_DATA"
```

**IF FAILURE PATH** (tests failing):

```bash
# Create failure checkpoint
CHECKPOINT_DATA=$(cat <<EOF
{
  "workflow": "orchestrate",
  "phase_name": "implementation",
  "completion_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "outputs": {
    "tests_passing": false,
    "phases_completed": "${PHASES_COMPLETED}",
    "failed_phase": ${FAILED_PHASE},
    "error_message": "${ERROR_MESSAGE}",
    "files_modified": [${FILES_MODIFIED}],
    "status": "failed"
  },
  "next_phase": "debugging",
  "branch_decision": "failure",
  "debug_context": {
    "plan_path": "${PLAN_PATH}",
    "failed_phase": ${FAILED_PHASE},
    "error_message": "${ERROR_MESSAGE}",
    "files_modified": [${FILES_MODIFIED}],
    "phases_completed": "${PHASES_COMPLETED}",
    "iteration": 0
  }
}
EOF
)

# Save checkpoint
.claude/lib/save-checkpoint.sh orchestrate "implementation_incomplete" "$CHECKPOINT_DATA"
```

**Checkpoint File Locations**:
- Success: `.claude/data/checkpoints/orchestrate_implementation_complete_[timestamp].json`
- Failure: `.claude/data/checkpoints/orchestrate_implementation_incomplete_[timestamp].json`

**Verification Checklist**:
- [ ] Checkpoint file created in .claude/data/checkpoints/
- [ ] Checkpoint contains all required fields (outputs, next_phase, context)
- [ ] If success: includes files_modified and git_commits
- [ ] If failure: includes failed_phase and error_message
- [ ] Checkpoint enables workflow resumption from this point

#### Step 7: Output Implementation Phase Status

**EXECUTE NOW: Display Status Message to User**

DISPLAY appropriate completion message based on branch decision from Step 5.

**IF SUCCESS PATH** (tests passing):

```markdown
OUTPUT to user:

✓ Implementation Phase Complete

**Summary**:
- All phases executed: [N]/[N]
- Tests passing: ✓
- Files modified: [M] files
- Git commits: [N] commits

**Modified Files**:
[List each file from workflow_state.implementation_status.files_modified]

**Git Commits**:
[List each commit hash from workflow_state.implementation_status.git_commits]

**Next Phase**: Documentation (Phase 6)

The implementation succeeded. Proceeding to documentation phase to update
project documentation and generate workflow summary.
```

**IF FAILURE PATH** (tests failing):

```markdown
OUTPUT to user:

⚠ Implementation Phase Incomplete

**Summary**:
- Phases completed: [M]/[N]
- Failed at: Phase [N]
- Tests passing: ✗

**Failure Details**:
Phase [N] failed with error:
[error_message from workflow_state.implementation_failure.error_message]

**Partial Progress**:
Files modified before failure:
[List each file from workflow_state.implementation_status.files_modified]

**Next Phase**: Debugging Loop (Phase 5)

The implementation encountered test failures. Entering debugging loop to
investigate and fix issues. Maximum 3 debugging iterations before escalation.
```

**Implementation Instructions**:

```python
# Display message based on branch decision

if workflow_state.implementation_branch.decision == "success":
    print(f"""
✓ Implementation Phase Complete

**Summary**:
- All phases executed: {workflow_state.implementation_status.phases_completed}
- Tests passing: ✓
- Files modified: {len(workflow_state.implementation_status.files_modified)} files
- Git commits: {len(workflow_state.implementation_status.git_commits)} commits

**Modified Files**:
{format_file_list(workflow_state.implementation_status.files_modified)}

**Git Commits**:
{format_commit_list(workflow_state.implementation_status.git_commits)}

**Next Phase**: Documentation (Phase 6)
    """)

else:  # failure path
    print(f"""
⚠ Implementation Phase Incomplete

**Summary**:
- Phases completed: {workflow_state.implementation_status.phases_completed}
- Failed at: Phase {workflow_state.implementation_failure.failed_phase}
- Tests passing: ✗

**Failure Details**:
Phase {workflow_state.implementation_failure.failed_phase} failed with error:
{workflow_state.implementation_failure.error_message}

**Partial Progress**:
Files modified before failure:
{format_file_list(workflow_state.implementation_status.files_modified)}

**Next Phase**: Debugging Loop (Phase 5)
    """)
```

**Verification Checklist**:
- [ ] Appropriate message displayed (success or failure)
- [ ] Message includes all relevant details (files, commits, errors)
- [ ] Next phase clearly indicated
- [ ] User understands what happened and what comes next

### Debugging Loop (Conditional - Only if Tests Fail)

**ENTRY CONDITIONS**:
```yaml
if workflow_state.implementation_status.tests_passing == false:
  ENTER debugging loop
else:
  SKIP to Phase 6 (Documentation)
```

**EXECUTE NOW: Initialize Debugging State**

Before first iteration, initialize debugging state:

```yaml
workflow_state.debug_iteration = 0
workflow_state.debug_topic_slug = ""      # Generated in Step 1
workflow_state.debug_reports = []         # Populated each iteration
workflow_state.debug_history = []         # Tracks all attempts
```

**Iteration Limit**: Maximum 3 debugging iterations. After 3 failures, escalate to user with actionable options.

**Loop Strategy**: Each iteration follows this sequence:
1. Generate debug topic slug (iteration 1 only)
2. Invoke debug-specialist → create report file
3. Extract report path and recommendations
4. Invoke code-writer → apply fix from report
5. Run tests again
6. Evaluate results → continue, succeed, or escalate

---

#### Step 1: Generate Debug Topic Slug (First Iteration Only)

**EXECUTE NOW: Generate Topic Slug**

IF debug_iteration == 1 AND debug_topic_slug is empty:

ANALYZE the test failure error messages to categorize the issue type.

**Topic Slug Algorithm**:

1. **Phase-Based** (default): Use failed phase number from implementation
   - Format: `phase{N}_failures`
   - Example: Phase 1 failed → `phase1_failures`

2. **Error-Type-Based** (preferred if pattern clear):
   - Integration failures → `integration_issues`
   - Timeout errors → `test_timeout`
   - Configuration errors → `config_errors`
   - Missing dependencies → `dependency_missing`
   - Syntax/compilation → `syntax_errors`

3. **Slug Rules**:
   - Lowercase with underscores
   - Concise (2-3 words max)
   - Descriptive of root issue type

**EXECUTE: Create Slug**

```bash
# Example slug generation logic
if error_message contains "timeout":
  debug_topic_slug = "test_timeout"
elif error_message contains "config":
  debug_topic_slug = "config_errors"
elif error_message contains "integration":
  debug_topic_slug = "integration_issues"
elif error_message contains "dependency" or "module not found":
  debug_topic_slug = "dependency_missing"
else:
  # Default: use failed phase number
  debug_topic_slug = "phase{failed_phase_number}_failures"
```

**Store in workflow_state**:
```yaml
workflow_state.debug_topic_slug = "[generated_slug]"
```

**Examples**:
- Integration test failure → `integration_issues`
- Phase 1 config loading error → `phase1_failures` or `config_errors`
- Test timeout in Phase 3 → `test_timeout`

---

#### Step 2: Invoke Debug Specialist Agent with File Creation

**EXECUTE NOW: USE the Task tool to invoke debug-specialist agent**

This agent will:
- Investigate test failure root cause
- Analyze error messages and code context
- Create persistent debug report file
- Propose 2-3 solution options
- Recommend best fix approach

**Task Tool Invocation** (execute this now):

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create debug report for test failures using debug-specialist protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/debug-specialist.md

    You are acting as a Debug Specialist Agent with the tools and constraints
    defined in that file.

    Create Debug Report File for Implementation Test Failures:

    ## Context
    - **Workflow**: "[workflow_state.workflow_description]"
    - **Project**: [project_name]
    - **Failed Phase**: Phase [failed_phase_number] - [phase_name]
    - **Topic Slug**: [workflow_state.debug_topic_slug]
    - **Iteration**: [workflow_state.debug_iteration] of 3

    ## Test Failures
    [workflow_state.implementation_status.test_output]

    ## Error Details
    - **Error messages**:
      [workflow_state.implementation_status.error_messages]

    - **Modified files**:
      [workflow_state.implementation_status.files_modified]

    - **Plan reference**: [workflow_state.plan_path]

    [IF debug_iteration > 1:]
    ## Previous Debug Attempts
    [FOR each attempt in workflow_state.debug_history:]
    ### Iteration [attempt.iteration]
    - **Report**: [attempt.report_path]
    - **Fix attempted**: [attempt.fix_attempted]
    - **Result**: [attempt.result]
    - **New errors**: [attempt.new_errors]

    ## Investigation Requirements
    - Analyze test failure patterns and root cause
    - Review relevant code and configurations
    - Consider previous debug attempts (if iteration > 1)
    - Identify why previous fixes didn't work (if applicable)
    - Propose 2-3 solutions with tradeoffs
    - Recommend the most likely solution to succeed

    ## Debug Report Creation Instructions
    1. USE Glob to find existing reports: `debug/[debug_topic_slug]/[0-9][0-9][0-9]_*.md`
    2. DETERMINE next report number (NNN format, incremental)
    3. CREATE report file using Write tool:
       Path: `debug/[debug_topic_slug]/NNN_[descriptive_name].md`
    4. INCLUDE all required metadata fields (see agent file, lines 256-346)
    5. RETURN file path in parseable format

    ## Expected Output Format

    **Primary Output** (required):
    ```
    DEBUG_REPORT_PATH: debug/[topic]/NNN_descriptive_name.md
    ```

    **Secondary Output** (required):
    Brief summary (1-2 sentences):
    - Root cause: [What is causing the failure]
    - Recommended fix: Option [N] - [Brief description]

    Example:
    ```
    DEBUG_REPORT_PATH: debug/phase1_failures/001_config_initialization.md

    Root cause: Config file not initialized before first test runs.
    Recommended fix: Option 2 - Add config initialization in test setup hook
    ```
}
```

**WAIT for agent completion before proceeding.**

---

#### Step 3: Extract Debug Report Path and Recommendations

**EXECUTE NOW: Parse Debug Specialist Output**

From the debug-specialist agent output, EXTRACT the following information:

**Required Extraction**:

1. **Debug Report Path**:
   - Pattern: `DEBUG_REPORT_PATH: debug/{topic}/NNN_*.md`
   - Example: `DEBUG_REPORT_PATH: debug/phase1_failures/001_config_initialization.md`
   - Store in: `debug_report_path` variable

2. **Root Cause Summary**:
   - Pattern: After "Root cause:" line
   - Extract: Brief 1-2 sentence description
   - Store in: `root_cause` variable

3. **Recommended Fix**:
   - Pattern: After "Recommended fix:" line
   - Extract: Which option number and brief description
   - Store in: `recommended_fix` variable

**EXECUTE: Validation Checklist**

Before proceeding, verify:
- [ ] Debug report file exists at extracted path
- [ ] File contains all required metadata sections
- [ ] Root cause clearly identified
- [ ] 2-3 solution options proposed with tradeoffs
- [ ] Recommended solution explicitly specified
- [ ] File follows debug report structure (see debug-specialist.md lines 256-346)

**IF validation fails**:
- RETRY debug-specialist invocation with clarifying instructions
- Maximum 2 retries before escalating to user

**EXECUTE: Store in Workflow State**

```yaml
workflow_state.debug_reports.append(debug_report_path)

# Example state after extraction:
workflow_state:
  debug_reports: [
    "debug/phase1_failures/001_config_initialization.md"
  ]
```

**Example Parsed Output**:
```
debug_report_path = "debug/phase1_failures/001_config_initialization.md"
root_cause = "Config file not initialized before first test runs"
recommended_fix = "Option 2 - Add config initialization in test setup hook"
```

---

#### Step 4: Apply Recommended Fix Using Code Writer Agent

**EXECUTE NOW: USE the Task tool to invoke code-writer agent**

This agent will:
- Read the debug report created in Step 3
- Understand the root cause and proposed solutions
- Implement the recommended solution
- Apply changes to affected files
- Prepare code for testing (but NOT run tests yet)

**Task Tool Invocation** (execute this now):

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Apply debug fixes from report using code-writer protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/code-writer.md

    You are acting as a Code Writer Agent with the tools and constraints
    defined in that file.

    Apply fixes from debug report:

    ## Debug Report
    **Path**: [debug_report_path from Step 3]

    READ the report using the Read tool to understand:
    - Root cause of test failures (Analysis section)
    - Proposed solutions (Options 1-3 in Proposed Solutions section)
    - Recommended solution (Recommendation section)
    - Implementation steps (within recommended solution option)

    ## Task
    IMPLEMENT the recommended solution from the debug report.

    ## Requirements
    - Follow implementation steps from recommended solution option
    - Apply changes to affected files using Edit or Write tools
    - Follow project coding standards (reference: /home/benjamin/.config/CLAUDE.md)
    - Add comments explaining the fix where appropriate
    - DO NOT run tests yet (orchestrator will run tests in Step 5)

    ## Context for Implementation
    - **Iteration**: [workflow_state.debug_iteration] of 3
    - **Previous attempts**: [IF iteration > 1: summary of previous fixes]
    - **Files to modify**: [From debug report's recommended solution]

    ## Expected Output
    Provide a brief summary:
    - **Files modified**: [list of files changed]
    - **Changes made**: [brief description of what was fixed]
    - **Ready for testing**: true

    Example:
    ```
    Files modified:
    - tests/setup.lua
    - config/init.lua

    Changes made:
    - Added config initialization in test setup hook
    - Ensured config loads before first test runs

    Ready for testing: true
    ```
}
```

**WAIT for agent completion before proceeding to testing.**

**EXECUTE: Capture Fix Summary**

From code-writer output, extract:
- `files_modified`: List of files changed
- `fix_description`: Brief summary of changes
- Store for debug history in Step 7

---

#### Step 5: Run Tests Again

**EXECUTE NOW: Run Tests to Validate Fix**

After code-writer applies the fix, run tests to determine if issue is resolved.

**Test Command Determination**:

1. **From Plan** (preferred): Check `workflow_state.plan_path` for test command
2. **From CLAUDE.md** (fallback): Check Testing Protocols section
3. **Default**: Use project-standard test command

**EXECUTE: Run Test Command**

```bash
# Execute test command via Bash tool
# Example commands (use appropriate for project):

# Claude Code project:
bash .claude/tests/run_all_tests.sh

# Python project:
pytest tests/

# JavaScript project:
npm test

# General:
[test_command from plan or CLAUDE.md]
```

**EXECUTE: Capture Test Results**

Parse test output to extract:

1. **Test Status**:
   ```yaml
   tests_passing: true | false
   ```

2. **Test Output** (if failing):
   ```yaml
   test_output: "[Full test output for next iteration context]"
   error_messages: [
     "Error 1 from output",
     "Error 2 from output"
   ]
   ```

3. **Success Indicators**:
   - All tests pass: `tests_passing = true`
   - Same errors: `tests_passing = false, errors unchanged`
   - New errors: `tests_passing = false, errors different`
   - Fewer errors: `tests_passing = false, progress = true`

**EXECUTE: Update Workflow State**

```yaml
workflow_state.implementation_status.tests_passing = [true|false]
workflow_state.implementation_status.test_output = "[latest output]"
workflow_state.implementation_status.error_messages = [extracted errors]
```

**Example Result**:
```yaml
# Success case:
tests_passing: true
test_output: "All 47 tests passed in 12.3s"

# Failure case:
tests_passing: false
test_output: "[Full output showing 3 failing tests]"
error_messages: [
  "test_auth: JWT decode error",
  "test_session: Token validation failed",
  "test_middleware: nil config.secret"
]
```

---

#### Step 6: Iteration Control and Decision Logic

**EXECUTE NOW: Evaluate Test Results and Determine Next Action**

Based on test results from Step 5, execute the appropriate branch:

```python
# Increment iteration counter (always at loop start)
# NOTE: Counter incremented at START of iteration, not end
workflow_state.debug_iteration += 1

# Decision tree (evaluate in this order):

IF tests_passing == true:
  # SUCCESS PATH
  EXECUTE: Branch 1 - Tests Passing (Success)

ELIF debug_iteration >= 3:
  # ESCALATION PATH (limit reached)
  EXECUTE: Branch 2 - Escalation to User

ELSE:
  # CONTINUE PATH (try again)
  EXECUTE: Branch 3 - Continue Debugging Loop
```

---

### Branch 1: Tests Passing (Success)

**Condition**: `tests_passing == true`

**EXECUTE: Success Actions**

1. **Mark debugging successful**:
   ```yaml
   workflow_state.debug_status = "resolved"
   workflow_state.debug_iterations_needed = debug_iteration
   ```

2. **Add resolution to debug history**:
   ```yaml
   workflow_state.debug_history.append({
     iteration: debug_iteration,
     report_path: debug_report_path,
     fix_attempted: fix_description,
     result: "Tests passing",
     resolution: "Success"
   })
   ```

3. **Update error history** (for tracking):
   ```yaml
   workflow_state.error_history.append({
     phase: "implementation",
     issue: root_cause,
     debug_reports: workflow_state.debug_reports,
     resolution: "Fixed in iteration {debug_iteration}",
     fix_applied: fix_description
   })
   ```

4. **SAVE checkpoint**:
   ```bash
   # Create checkpoint file with success status
   cat > .claude/checkpoints/checkpoint_tests_passing.yaml << 'EOF'
   phase_name: "debugging"
   completion_time: $(date -Iseconds)
   outputs:
     tests_passing: true
     debug_iterations: ${debug_iteration}
     debug_reports: ${workflow_state.debug_reports[@]}
     issues_resolved: ["${root_cause}"]
     status: "success"
   next_phase: "documentation"
   performance:
     debugging_time: "${duration}"
     iterations_needed: ${debug_iteration}
   EOF
   ```

5. **OUTPUT to user**:
   ```markdown
   ✓ Debugging Phase Complete

   Tests passing: ✓
   Debug iterations: {debug_iteration}
   Issues resolved: {issues_count}
   Debug reports: {report_paths}

   Next: Documentation Phase
   ```

**EXIT debugging loop → PROCEED to Phase 6 (Documentation)**

---

### Branch 2: Escalation to User

**Condition**: `debug_iteration >= 3 AND tests_passing == false`

**EXECUTE: Escalation Actions**

1. **Mark debugging as escalated**:
   ```yaml
   workflow_state.debug_status = "escalated"
   workflow_state.debug_iterations_needed = 3
   ```

2. **Add final attempt to debug history**:
   ```yaml
   workflow_state.debug_history.append({
     iteration: 3,
     report_path: debug_report_path,
     fix_attempted: fix_description,
     result: "Still failing after 3 iterations",
     escalation_reason: "Maximum debugging iterations reached"
   })
   ```

3. **SAVE escalation checkpoint**:
   ```bash
   # Create escalation checkpoint
   cat > .claude/checkpoints/checkpoint_escalation.yaml << 'EOF'
   phase_name: "debugging"
   completion_time: $(date -Iseconds)
   outputs:
     tests_passing: false
     debug_iterations: 3
     debug_reports: ${workflow_state.debug_reports[@]}
     unresolved_issues: ${workflow_state.implementation_status.error_messages[@]}
     status: "escalated"
   next_phase: "manual_intervention"
   user_options: ["continue", "retry", "rollback", "terminate"]
   debug_summary: |
     Attempted 3 debugging iterations. Tests still failing.

     Issues remaining:
     ${workflow_state.implementation_status.error_messages[@]}

     Debug reports created:
     ${workflow_state.debug_reports[@]}
   EOF
   ```

4. **PRESENT escalation message to user**:

```markdown
⚠️ **Debugging Loop: Maximum Iterations Reached**

**Status**: Escalation required after 3 debugging iterations

---

## Issue Summary

**Original Problem**:
[Root cause from first debug report: workflow_state.debug_history[0].root_cause]

**Tests Status**: Still failing after 3 fix attempts

**Unresolved Errors**:
[FOR each error in workflow_state.implementation_status.error_messages:]
- {error}

---

## Debugging Attempts

### Iteration 1
- **Debug Report**: {workflow_state.debug_reports[0]}
- **Fix Attempted**: {workflow_state.debug_history[0].fix_attempted}
- **Result**: {workflow_state.debug_history[0].result}
- **New Errors**: {workflow_state.debug_history[0].new_errors}

### Iteration 2
- **Debug Report**: {workflow_state.debug_reports[1]}
- **Fix Attempted**: {workflow_state.debug_history[1].fix_attempted}
- **Result**: {workflow_state.debug_history[1].result}
- **New Errors**: {workflow_state.debug_history[1].new_errors}

### Iteration 3
- **Debug Report**: {workflow_state.debug_reports[2]}
- **Fix Attempted**: {workflow_state.debug_history[2].fix_attempted}
- **Result**: {workflow_state.debug_history[2].result}
- **New Errors**: {workflow_state.debug_history[2].new_errors}

---

## Your Options

I've reached the maximum automated debugging iterations (3). Here are your options:

**Option 1: Manual Investigation**
- Review the 3 debug reports created:
  - {workflow_state.debug_reports[0]}
  - {workflow_state.debug_reports[1]}
  - {workflow_state.debug_reports[2]}
- Manually investigate and fix the issue
- Resume workflow after fixing: Use checkpoint_escalation to resume

**Option 2: Retry with Guidance**
- Provide additional context or hints about the issue
- I'll retry debugging with your guidance
- Command: `/orchestrate resume --with-context "your guidance"`

**Option 3: Alternative Approach**
- Rollback to last successful phase (Phase 4: Implementation complete)
- Try a different implementation approach
- Command: `/orchestrate rollback phase4`

**Option 4: Skip Debugging**
- Proceed to documentation phase despite failing tests
- Mark tests as "known issues" in documentation
- Command: `/orchestrate continue --skip-tests`

**Option 5: Terminate Workflow**
- End workflow here, preserve all work completed
- Checkpoints saved: research, planning, implementation, debugging attempts
- Command: `/orchestrate terminate`

---

## Checkpoint Saved

A checkpoint has been saved at:
- **Checkpoint ID**: `checkpoint_escalation`
- **Phase**: debugging (incomplete)
- **Resume Command**: `/orchestrate resume`

All debug reports, implementation work, and history are preserved.

---

## Recommended Next Steps

1. **Investigate manually**: Start with the most recent debug report ({workflow_state.debug_reports[2]})
2. **Check for patterns**: Do all 3 attempts share a common issue?
3. **Review test configuration**: Are tests themselves correct?
4. **Consider scope**: Is this issue within original workflow scope?

**What would you like to do?** [Respond with option number or custom action]
```

**PAUSE workflow and WAIT for user input.**

**EXIT debugging loop → Wait for user decision**

---

### Branch 3: Continue Debugging Loop

**Condition**: `debug_iteration < 3 AND tests_passing == false`

**EXECUTE: Prepare for Next Iteration**

1. **Add current attempt to debug history**:
   ```yaml
   workflow_state.debug_history.append({
     iteration: debug_iteration,
     report_path: debug_report_path,
     fix_attempted: fix_description,
     result: "Still failing",
     new_errors: workflow_state.implementation_status.error_messages
   })
   ```

2. **Prepare context for next iteration**:
   - Keep `workflow_state.debug_topic_slug` (don't regenerate)
   - Keep `workflow_state.debug_reports` (accumulate)
   - Keep `workflow_state.debug_history` (accumulate)
   - Update `error_messages` with latest failures

3. **OUTPUT to user**:
   ```markdown
   Debugging iteration {debug_iteration} complete.
   Tests still failing. Attempting iteration {debug_iteration + 1}...
   ```

4. **RETURN to Step 2** (Invoke Debug Specialist) with enriched context:
   - Next invocation will include debug_history
   - debug-specialist will see previous attempts
   - code-writer will know what was already tried

**CONTINUE debugging loop → RETURN to Step 2 (iteration {debug_iteration + 1})**

---

**Summary of Decision Logic**:

| Condition | Action | Next Phase |
|-----------|--------|------------|
| Tests passing | Save success checkpoint | Phase 6 (Documentation) |
| Iteration >= 3, tests failing | Save escalation checkpoint, present options | User Decision |
| Iteration < 3, tests failing | Add to history, continue loop | Step 2 (next iteration) |

---

#### Step 7: Update Workflow State (All Branches)

**EXECUTE: Update workflow_state (performed in all branches)**

Update workflow state based on debugging outcome:

```yaml
# State updated in Branch 1 (Success):
workflow_state.context_preservation.debug_reports: [
  {
    topic: "[debug_topic_slug]",
    path: "debug/{topic}/NNN_*.md",
    number: "NNN",
    iteration: N,
    resolved: true
  }
]

# State updated in Branch 2 (Escalation):
workflow_state.context_preservation.debug_reports: [
  {topic: "...", path: "...", resolved: false},
  {topic: "...", path: "...", resolved: false},
  {topic: "...", path: "...", resolved: false}
]

# State updated in Branch 3 (Continue):
workflow_state.debug_history: [
  {iteration: 1, result: "Still failing", ...},
  {iteration: 2, result: "Still failing", ...}
]
```

---

#### Debugging Loop Code Examples

**Example 1: Single Iteration Success**

```yaml
# Scenario: Fix works on first try

Iteration 1:
  debug_iteration: 1
  debug_topic_slug: "phase1_failures"

  Step 2: debug-specialist creates:
    - Report: debug/phase1_failures/001_config_initialization.md
    - Root cause: "Config not initialized before tests"
    - Recommended: "Option 2 - Add init in test setup"

  Step 3: Extract:
    - debug_report_path = "debug/phase1_failures/001_config_initialization.md"

  Step 4: code-writer applies:
    - Modified: tests/setup.lua
    - Added: config.init() call in setup function

  Step 5: Run tests:
    - Result: All 47 tests pass
    - tests_passing = true

  Step 6: Branch 1 (Success):
    - Save checkpoint(success)
    - debug_iterations_needed = 1
    - EXIT loop → Phase 6 (Documentation)

Outcome: ✓ Success in 1 iteration
```

**Example 2: Two Iteration Success**

```yaml
# Scenario: First fix incomplete, second fix succeeds

Iteration 1:
  debug_iteration: 1
  debug_topic_slug: "integration_issues"

  Step 2: debug-specialist creates:
    - Report: debug/integration_issues/001_auth_token_missing.md
    - Root cause: "Auth token not passed to middleware"
    - Recommended: "Option 1 - Add token to request context"

  Step 4: code-writer applies:
    - Modified: middleware/auth.lua
    - Added: token extraction from headers

  Step 5: Run tests:
    - Result: 2 tests still failing
    - Error: "config.secret is nil"
    - tests_passing = false

  Step 6: Branch 3 (Continue):
    - Add to debug_history[0]
    - CONTINUE to Iteration 2

Iteration 2:
  debug_iteration: 2
  debug_topic_slug: "integration_issues" (reuse)

  Step 2: debug-specialist creates (with history):
    - Report: debug/integration_issues/002_secret_initialization.md
    - Context: "Previous fix addressed token extraction, but config.secret still nil"
    - Root cause: "Secret not loaded in test environment"
    - Recommended: "Option 2 - Mock secret in test config"

  Step 4: code-writer applies:
    - Modified: tests/config_mock.lua
    - Added: config.secret = "test-secret-key"

  Step 5: Run tests:
    - Result: All tests pass
    - tests_passing = true

  Step 6: Branch 1 (Success):
    - Save checkpoint(success)
    - debug_iterations_needed = 2
    - EXIT loop → Phase 6 (Documentation)

Outcome: ✓ Success in 2 iterations
```

**Example 3: Three Iteration Escalation**

```yaml
# Scenario: Issue proves too complex for automated debugging

Iteration 1:
  debug_topic_slug: "test_timeout"
  Report: debug/test_timeout/001_async_hang.md
  Fix: Added timeout wrapper
  Result: Still hangs (different line)

Iteration 2:
  Report: debug/test_timeout/002_promise_deadlock.md
  Fix: Fixed promise resolution order
  Result: New error - "coroutine error"

Iteration 3:
  debug_iteration: 3
  Report: debug/test_timeout/003_coroutine_state.md
  Fix: Added coroutine state cleanup
  Result: Still failing - "coroutine in wrong state"
  tests_passing = false

Step 6: Branch 2 (Escalation):
  debug_iteration >= 3 AND tests_passing == false
  SAVE checkpoint(escalation)
  PRESENT escalation message with 3 reports
  PAUSE workflow
  WAIT for user decision

Outcome: ⚠️ Escalated to user after 3 iterations
```

### Documentation Phase (Sequential Execution)

This phase updates all relevant documentation and generates a comprehensive workflow summary.

#### Step 1: Prepare Documentation Context

**Gather All Workflow Artifacts**:
```yaml
documentation_context:
  files_modified: [list from implementation]
  plan_path: "specs/plans/NNN_*.md"
  research_reports: [list if research phase completed]
  debug_reports: [list if debugging occurred]
  test_results: "passing|fixed_after_debugging"
  workflow_description: "[Original user request]"
```

**Calculate Performance Metrics**:
```yaml
performance_summary:
  total_workflow_time: "[duration in minutes]"
  phase_breakdown:
    research: "[duration or 'skipped']"
    planning: "[duration]"
    implementation: "[duration]"
    debugging: "[duration or 'not_needed']"
    documentation: "[current phase]"

  parallelization_metrics:
    parallel_research_agents: N
    time_saved_estimate: "[% saved vs sequential]"

  error_recovery:
    total_errors: N
    auto_recovered: N
    manual_interventions: N
    recovery_success_rate: "N%"
```

#### Step 2-4: Documentation Agent Invocation and Validation

**Orchestrate-specific documentation workflow**:

**Agent Prompt Structure**:
- Workflow context: Original request, workflow type, artifacts generated
- Implementation plan path with specs directory extraction
- Files modified list and test results
- Cross-referencing requirements for bidirectional linking
- Invoke `/document` command for documentation updates

**Cross-Referencing Strategy** (orchestrate-specific):
- Add "Implementation Summary" section to plan file
- Add "Implementation Status" section to research reports
- Verify bidirectional links using Read tool
- Handle edge cases (duplicate sections, multiple summaries)

**Validation Requirements**:
- At least one documentation file updated
- Cross-references include all workflow artifacts
- No broken links
- Follows project documentation standards

#### Step 3: Invoke Documentation Agent

**Task Tool Invocation**:
```yaml
subagent_type: general-purpose
description: "Update documentation for workflow using doc-writer protocol"
prompt: "Read and follow the behavioral guidelines from:
         /home/benjamin/.config/.claude/agents/doc-writer.md

         You are acting as a Doc Writer with the tools and constraints
         defined in that file.

         [Generated documentation prompt from Step 2]"
```

**Monitoring**:
- **Progress Streaming**: Watch for `PROGRESS: <message>` markers in agent output
  - Display progress updates to user in real-time
  - Examples: `PROGRESS: Updating README.md...`, `PROGRESS: Adding cross-references...`
- Track documentation updates
- Verify cross-referencing
- Watch for completion signal

#### Step 4: Extract Documentation Results

**Results Extraction**:
```markdown
From documentation agent output, extract:
- updated_files: [list of documentation files modified]
- readme_updates: [list of README files updated]
- spec_updates: [list of spec files updated]
- cross_references_added: N
- documentation_complete: true|false
```

**Validation**:
- [ ] At least one documentation file updated
- [ ] Cross-references include all workflow artifacts
- [ ] Documentation follows project standards
- [ ] No broken links or invalid references

#### Step 5: Generate Workflow Summary

**Summary File Creation**:

**Location Determination**:
```yaml
summary_location:
  directory: "same as plan (specs/summaries/)"
  filename: "NNN_workflow_summary.md"
  number: "matches plan number"
```

**Summary Template**:
```markdown
# Workflow Summary: [Feature/Task Name]

## Metadata
- **Date Completed**: [YYYY-MM-DD]
- **Specs Directory**: [path/to/specs/] (from plan metadata)
- **Summary Number**: [NNN] (matches plan number)
- **Workflow Type**: [feature|refactor|debug|investigation]
- **Original Request**: [User's workflow description]
- **Total Duration**: [HH:MM:SS]

## Workflow Execution

### Phases Completed
- [x] Research (parallel) - [duration or "Skipped"]
- [x] Planning (sequential) - [duration]
- [x] Implementation (adaptive) - [duration]
- [x] Debugging (conditional) - [duration or "Not needed"]
- [x] Documentation (sequential) - [duration]

### Artifacts Generated

**Research Reports**:
[If research phase completed]
- [Report 1: path - brief description]
- [Report 2: path - brief description]

**Implementation Plan**:
- Path: [plan_path]
- Phases: N
- Complexity: [Low|Medium|High]
- Link: [relative link to plan file]

**Debug Reports**:
[If debugging occurred]
- [Debug report 1: path - issue addressed]

## Implementation Overview

### Key Changes
**Files Created**:
- [new_file_1.ext] - [brief purpose]
- [new_file_2.ext] - [brief purpose]

**Files Modified**:
- [modified_file_1.ext] - [changes made]
- [modified_file_2.ext] - [changes made]

**Files Deleted**:
- [deleted_file.ext] - [reason for deletion]

### Technical Decisions
[Key architectural or technical decisions made during workflow]
- Decision 1: [what and why]
- Decision 2: [what and why]

## Test Results

**Final Status**: ✓ All tests passing

[If debugging occurred]
**Debugging Summary**:
- Iterations required: N
- Issues resolved:
  1. [Issue 1 and fix]
  2. [Issue 2 and fix]

## Performance Metrics

### Workflow Efficiency
- Total workflow time: [HH:MM:SS]
- Estimated manual time: [HH:MM:SS]
- Time saved: [N%]

### Phase Breakdown
| Phase | Duration | Status |
|-------|----------|--------|
| Research | [time] | [Completed/Skipped] |
| Planning | [time] | Completed |
| Implementation | [time] | Completed |
| Debugging | [time] | [Completed/Not needed] |
| Documentation | [time] | Completed |

### Parallelization Effectiveness
- Research agents used: N
- Parallel vs sequential time: [N% faster]

### Error Recovery
- Total errors encountered: N
- Automatically recovered: N
- Manual interventions: N
- Recovery success rate: [N%]

## Cross-References

### Research Phase
[If applicable]
This workflow incorporated findings from:
- [Report 1 path and title]
- [Report 2 path and title]

### Planning Phase
Implementation followed the plan at:
- [Plan path and title]

### Related Documentation
Documentation updated includes:
- [Doc 1 path]
- [Doc 2 path]

## Lessons Learned

### What Worked Well
- [Success 1]
- [Success 2]

### Challenges Encountered
- [Challenge 1 and how it was resolved]
- [Challenge 2 and how it was resolved]

### Recommendations for Future
- [Recommendation 1]
- [Recommendation 2]

## Notes

[Any additional context, caveats, or important information about this workflow]

---

*Workflow orchestrated using /orchestrate command*
*For questions or issues, refer to the implementation plan and research reports linked above.*
```

#### Step 6: Create Summary File

**File Creation**:
```yaml
action: create_summary_file
location: "[plan_directory]/specs/summaries/NNN_workflow_summary.md"
content: "[Generated from template above]"
cross_references:
  - update_plan: add_summary_reference
  - update_reports: add_summary_reference
```

**Cross-Reference Updates**:
```markdown
Update related files to link back to summary:

In Implementation Plan (specs/plans/NNN_*.md):
Add at bottom:
## Implementation Summary
This plan was executed on [date]. See workflow summary:
- [Summary path and link]

In Research Reports (if any):
Add in relevant section:
### Implementation Reference
Findings from this report were incorporated into:
- [Plan path] - Implementation plan
- [Summary path] - Workflow execution summary
```

#### Step 7: Save Final Checkpoint

**Workflow Complete Checkpoint**:
```yaml
checkpoint_workflow_complete:
  phase_name: "documentation"
  completion_time: [timestamp]
  outputs:
    documentation_updated: [list of files]
    summary_created: "specs/summaries/NNN_*.md"
    cross_references: [count]
    status: "success"
  next_phase: "complete"

  final_metrics:
    total_workflow_time: "[duration]"
    phases_completed: [list]
    artifacts_generated: [count]
    files_modified: [count]
    error_recovery_success: "[%]"

  workflow_summary:
    research_reports: [list]
    implementation_plan: "[path]"
    workflow_summary: "[path]"
    tests_passing: true
```

#### Step 8: Create Pull Request (Optional)

**When to Create PR:**
- If `--create-pr` flag is provided, OR
- If project CLAUDE.md has GitHub Integration configured with auto-PR for branch pattern

**Prerequisites Check:**
Before invoking github-specialist agent:
```bash
# Check if gh CLI is available and authenticated
if ! command -v gh &>/dev/null; then
  echo "Note: gh CLI not installed. Skipping PR creation."
  echo "Install: brew install gh (or equivalent)"
  exit 0
fi

if ! gh auth status &>/dev/null; then
  echo "Note: gh CLI not authenticated. Skipping PR creation."
  echo "Run: gh auth login"
  exit 0
fi
```

**Invoke github-specialist Agent:**

Use Task tool with behavioral injection:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create PR for completed workflow using github-specialist protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/github-specialist.md

    You are acting as a GitHub Specialist Agent with the tools and constraints
    defined in that file.

    Create Pull Request for Workflow:
    - Plan: [absolute path to implementation plan]
    - Branch: [current branch name from git]
    - Base: main (or master, detect from repo)
    - Summary: [absolute path to workflow summary]

    PR Description Should Include:
    - Workflow overview from summary file
    - Research phase: N reports generated with key findings
    - Implementation: All N phases completed successfully
    - Test results: All passing (or fixed after M debug iterations)
    - Documentation: N files updated
    - Performance metrics: Time saved via parallelization
    - File changes summary from git diff --stat

    Follow comprehensive PR template structure from github-specialist agent.
    This is a workflow PR, so include cross-references to all artifacts:
    - Research reports (if any)
    - Implementation plan
    - Workflow summary
    - Debug reports (if debugging occurred)

    Output: PR URL and number for user
}
```

**Capture PR URL:**
After agent completes:
- Extract PR URL from agent output
- Update workflow summary with PR link
- Update plan file Implementation Summary section with PR link

**Example Update to Summary:**
```markdown
## Pull Request
- **PR**: https://github.com/user/repo/pull/123
- **Created**: [YYYY-MM-DD]
- **Status**: Open
```

**Graceful Degradation:**
If PR creation fails:
- Log the error from agent
- Provide manual gh pr create command
- Continue without blocking (workflow is complete)
- Summary file still valid without PR link

**Example Manual Command:**
```bash
gh pr create \
  --title "feat: [feature name from workflow]" \
  --body "$(cat pr_description.txt)" \
  --base main
```

#### Step 9: Workflow Completion Message

**Final Output to User**:
```markdown
✅ Workflow Complete

**Duration**: [HH:MM:SS]

**Artifacts Generated**:
[If research]
- Research reports: N ([paths])
- Implementation plan: [path]
- Workflow summary: [path]
- Documentation updates: N files
[If PR created]
- Pull Request: [PR URL]

**Implementation Results**:
- Files modified: N
- Tests: ✓ All passing
[If debugging occurred]
- Issues resolved: N (after M debug iterations)

**Performance**:
- Time saved via parallelization: [N%]
- Error recovery: [N/M errors auto-recovered]

**Summary**: [summary_path]

Review the workflow summary for complete details, cross-references, and lessons learned.
```

#### Documentation Phase Example

```markdown
User Request: "Add user authentication with email and password"

Workflow Phases Completed:
✓ Research (3 parallel agents, 5min)
✓ Planning (created specs/plans/013_auth_implementation.md, 3min)
✓ Implementation (4 phases, all tests passing, 25min)
✓ Documentation (updated 3 files, created summary, 4min)

Total Duration: 37 minutes

Documentation Updated:
- nvim/README.md (added auth section)
- nvim/docs/ARCHITECTURE.md (added auth module diagram)
- nvim/lua/neotex/auth/README.md (created)

Workflow Summary Created:
- specs/summaries/013_auth_workflow_summary.md
- Cross-referenced: 2 research reports, 1 plan, 3 updated docs

Performance Metrics:
- Parallel research saved ~8 minutes (estimated)
- Zero errors, no debugging needed
- All cross-references verified

Checkpoint Saved: workflow_complete
Status: ✅ Success
```

## Context Management Strategy

### Orchestrator Context (Minimal - <30% usage)

I maintain only:
- Current workflow state (phase, completion status)
- Checkpoint data (success/failure per phase)
- High-level summaries (research: 200 words max)
- File paths (not content): plan path, modified files, doc paths
- Error history: what failed, what recovery action taken
- Performance metrics: phase times, parallel effectiveness

### Subagent Context (Comprehensive)

Each subagent receives:
- Complete task description with clear objective
- Necessary context from prior phases (summaries only)
- Project standards reference (CLAUDE.md)
- Explicit success criteria
- Expected output format
- Error handling guidance

**No routing logic or orchestration details passed to subagents.**

### Context Passing Protocol

```markdown
For each subagent invocation:
1. Extract minimal necessary context from prior phases
2. Structure as focused task description
3. Remove all orchestration routing logic
4. Include explicit success criteria
5. Specify exact output format
```

## Error Recovery Mechanism

### Error Classification

**Error Types**:
1. **Timeout Errors**: Agent execution exceeds time limits
2. **Tool Access Errors**: Permission or availability issues
3. **Validation Failures**: Output doesn't meet criteria
4. **Test Failures**: Code tests fail (handled by Debugging Loop)
5. **Integration Errors**: Command invocation failures
6. **Context Overflow**: Orchestrator context approaches limits

### Automatic Recovery Strategies

See [Error Recovery Patterns](../docs/command-patterns.md#error-recovery-patterns) for detailed recovery strategies including:
- Automatic Retry with Backoff
- Error Classification and Routing (timeout, tool access, validation, integration)
- User Escalation Format

**Orchestrate-specific recovery**:
- Context Overflow Prevention: Compress context, summarize aggressively, reduce workflow scope
- Checkpoint-based recovery: Rollback to last successful phase
- Error history tracking: Learn from failures to improve future workflows

### Checkpoint Recovery System

See [Checkpoint Management Patterns](../docs/command-patterns.md#checkpoint-management-patterns) for checkpoint creation and restoration.

**Orchestrate-specific checkpoints**:
- Stored in orchestrator memory (minimal, ephemeral)
- Used for in-session recovery only
- Enable rollback to previous successful phase
- Preserve partial work on failures

### Manual Intervention Points

#### When to Escalate

**Automatic Escalation Triggers**:
1. **Max retries exceeded** (3 attempts for most error types)
2. **Critical failures** (data loss, security issues)
3. **Debugging loop limit** (3 debugging iterations)
4. **Context overflow** (cannot compress further)
5. **Architectural decisions** (user input required)

#### Escalation Format

See [User Escalation Format](../docs/command-patterns.md#pattern-user-escalation-format) for standard escalation message structure.

**User Options**:
- `continue`: Resume with manual fixes
- `retry [phase]`: Retry specific phase
- `rollback [phase]`: Return to checkpoint
- `terminate`: End workflow gracefully
- `debug`: Enter manual debugging mode

## Performance Monitoring

### Metrics Collection

Track throughout workflow:
- **Phase Execution Times**: Time per phase
- **Parallelization Effectiveness**: Actual vs potential time savings
- **Error Rates**: Failures per phase
- **Context Window Utilization**: Orchestrator context usage
- **Recovery Success**: Automatic vs manual interventions

### Optimization Recommendations

After workflow completion, suggest:
- Which phases could benefit from parallelization
- Bottleneck phases for optimization
- Checkpoint placement improvements
- Context management refinements

## Execution Flow

### Initial Workflow Processing

When invoked with `<workflow-description>`:

1. **Parse and Classify**:
   - Extract feature/task description
   - Determine workflow type
   - Identify complexity level
   - Check for parallel/sequential flags

2. **Initialize TodoWrite**:
   ```markdown
   Create todo list with identified phases:
   - [ ] Research phase (if needed)
   - [ ] Planning phase
   - [ ] Implementation phase
   - [ ] Debugging loop (conditional)
   - [ ] Documentation phase
   ```

3. **Execute Phases Sequentially**:
   - Research (parallel subagents) → synthesize
   - Planning (single subagent) → extract plan path
   - Implementation (single subagent) → check tests
   - Debugging (conditional loop) → ensure tests pass
   - Documentation (single subagent) → generate summary

4. **Update TodoWrite** after each phase completion

5. **Generate Final Summary**:
   - Workflow completion report
   - Performance metrics
   - Cross-references to all generated documents

## Usage Examples

### Example 1: Feature Development
```
/orchestrate Add user authentication with email and password
```
Expected flow:
- Research: auth patterns, security best practices
- Planning: structured multi-phase plan
- Implementation: backend + frontend + tests
- Documentation: API docs, user guide

### Example 2: Bug Investigation and Fix
```
/orchestrate Fix the command picker synchronization issue
```
Expected flow:
- Research: analyze current implementation, find issue
- Planning: fix strategy with validation
- Implementation: apply fix
- Debugging: ensure tests pass
- Documentation: issue report and fix notes

### Example 3: Refactoring
```
/orchestrate Refactor the specs directory structure for better organization
```
Expected flow:
- Research: current structure, best practices
- Planning: incremental refactoring approach
- Implementation: gradual restructuring with tests
- Documentation: architectural updates

## Notes

### Architecture Principles

**Supervisor Pattern** (LangChain 2025):
- Centralized coordination with minimal state
- Specialized subagents with focused tasks
- Context isolation prevents cross-contamination
- Forward message pattern avoids paraphrasing errors

**Context Preservation**:
- Orchestrator: <30% context usage (state, checkpoints, summaries only)
- Subagents: Comprehensive context for their specific task
- No routing logic passed to workers
- Structured handoffs with explicit success criteria

**Error Recovery**:
- Multi-level detection (timeout, tool access, validation)
- Automatic retry with adjusted parameters
- Checkpoint-based rollback and resume
- Graceful degradation to sequential execution

### When to Use /orchestrate

**Use /orchestrate for**:
- Complex multi-phase workflows (≥3 phases)
- Features requiring research + planning + implementation
- Tasks benefiting from parallel execution
- Workflows needing systematic error recovery

**Use individual commands for**:
- Simple single-phase tasks
- Direct implementation without planning
- Quick documentation updates
- Straightforward bug fixes

### Implementation Status

**Full implementation complete!** All phases have been implemented:

- [x] Phase 1: Foundation and Command Structure
- [x] Phase 2: Research Phase Coordination
- [x] Phase 3: Planning and Implementation Phase Integration
- [x] Phase 4: Error Recovery and Debugging Loop
- [x] Phase 5: Documentation Phase and Workflow Completion

The /orchestrate command provides comprehensive multi-agent workflow coordination with:
- Parallel research execution with context minimization
- Seamless integration with /plan, /implement, /debug, /document commands
- Robust error recovery with automatic retry strategies
- Intelligent debugging loop with 3-iteration limit
- Complete documentation generation with cross-referencing
- Checkpoint-based recovery system
- Performance metrics tracking

Ready to orchestrate end-to-end development workflows!

## Agent Usage

This command uses specialized agents for each workflow phase:

### Research Phase
- **Agent**: `research-specialist` (multiple instances in parallel)
- **Purpose**: Codebase analysis, best practices research, alternative approaches
- **Tools**: Read, Grep, Glob, WebSearch, WebFetch
- **Invocation**: 2-4 parallel agents depending on workflow complexity

### Planning Phase
- **Agent**: `plan-architect`
- **Purpose**: Generate structured implementation plans from research findings
- **Tools**: Read, Write, Grep, Glob, WebSearch
- **Invocation**: Single agent, sequential execution

### Implementation Phase
- **Agent**: `code-writer`
- **Purpose**: Execute implementation plans phase by phase with testing
- **Tools**: Read, Write, Edit, Bash, TodoWrite
- **Invocation**: Single agent with extended timeout for complex implementations

### Debugging Loop (Conditional)
- **Investigation**: `debug-specialist`
  - Purpose: Root cause analysis and diagnostic reporting
  - Tools: Read, Bash, Grep, Glob, WebSearch
- **Fix Application**: `code-writer`
  - Purpose: Apply proposed fixes from debug reports
  - Tools: Read, Write, Edit, Bash, TodoWrite
- **Invocation**: Up to 3 debugging iterations before escalation

### Documentation Phase
- **Agent**: `doc-writer`
- **Purpose**: Update documentation and generate workflow summaries
- **Tools**: Read, Write, Edit, Grep, Glob
- **Invocation**: Single agent, sequential execution

### Agent Integration Benefits
- **Specialized Expertise**: Each agent optimized for its specific task
- **Tool Restrictions**: Security through limited tool access per agent
- **Parallel Execution**: Research-specialist agents run concurrently
- **Context Isolation**: Agents receive only relevant context for their phase
- **Clear Responsibilities**: No ambiguity about which agent handles what

## Checkpoint Detection and Resume

Before starting the workflow, I'll check for existing checkpoints that might indicate an interrupted workflow.

### Step 1: Check for Existing Checkpoint

```bash
# Load most recent orchestrate checkpoint
CHECKPOINT=$(.claude/lib/load-checkpoint.sh orchestrate 2>/dev/null || echo "")
```

### Step 2: Interactive Resume Prompt (if checkpoint found)

If a checkpoint exists, I'll present interactive options:

```
Found existing checkpoint for orchestrate workflow
Project: [project_name]
Created: [created_at] ([age] ago)
Progress: Phase [current_phase] of [total_phases] completed
Status: [status]

Options:
  (r)esume - Continue from Phase [current_phase + 1]
  (s)tart fresh - Delete checkpoint and restart workflow
  (v)iew details - Show checkpoint contents
  (d)elete - Remove checkpoint without starting

Choice [r/s/v/d]:
```

### Step 3: Resume Workflow State (if user chooses resume)

If user selects resume:
1. Load `workflow_state` from checkpoint
2. Restore `project_name`, `research_reports`, `completed_phases`
3. Skip to next incomplete phase
4. Continue workflow from that point

### Step 4: Save Checkpoints at Key Milestones

Throughout workflow execution, save checkpoints after each major phase:

```bash
# After research phase
.claude/lib/save-checkpoint.sh orchestrate "$PROJECT_NAME" "$WORKFLOW_STATE_JSON"

# After planning phase
.claude/lib/save-checkpoint.sh orchestrate "$PROJECT_NAME" "$UPDATED_STATE_JSON"

# After implementation phase
.claude/lib/save-checkpoint.sh orchestrate "$PROJECT_NAME" "$UPDATED_STATE_JSON"

# After debugging (if needed)
.claude/lib/save-checkpoint.sh orchestrate "$PROJECT_NAME" "$UPDATED_STATE_JSON"
```

### Step 5: Cleanup on Completion

On successful workflow completion:
```bash
# Delete checkpoint file
rm .claude/data/checkpoints/orchestrate_${PROJECT_NAME}_*.json
```

On workflow failure:
```bash
# Archive checkpoint to failed/ directory
mv .claude/data/checkpoints/orchestrate_${PROJECT_NAME}_*.json .claude/data/checkpoints/failed/
```

Let me begin orchestrating your workflow based on the description provided.
