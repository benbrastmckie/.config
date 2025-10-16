# Phase 2: Research Phase Refactor

## Metadata
- **Phase Number**: 2
- **Parent Plan**: 042_orchestrate_command_execution_refactor.md
- **Dependencies**: Phase 1 (completed)
- **Complexity**: High (9/10)
- **Estimated Hours**: 6-8
- **Status**: COMPLETED (100% - 9 of 9 steps done)
- **Target Lines**: 85-878 of orchestrate.md (expanded significantly)
- **Last Updated**: 2025-10-12

## Implementation Progress

### All Steps Completed (9/9)

- ✓ **Step 1**: "Identify Research Topics" transformation (lines 87-131)
  - Transformed passive voice to imperative commands (ANALYZE, IDENTIFY, EXTRACT, GENERATE)
  - Added EXECUTE NOW block with 4 numbered steps
  - Added complexity-based research strategy with 4 workflow tiers
  - Added 2 concrete examples showing input → output
  - Status: COMPLETED

- ✓ **Step 1.5**: "Determine Thinking Mode" transformation (lines 133-175)
  - Added complete scoring algorithm with explicit calculations
  - Added 3 worked examples (simple, complex, critical workflows)
  - Clarified thinking mode applies to ALL agents in workflow
  - Status: COMPLETED

- ✓ **Step 2**: "Launch Parallel Research Agents" transformation (lines 177-212)
  - Removed external reference to command-patterns.md
  - Added explicit Task tool invocation JSON structure
  - Emphasized SINGLE MESSAGE requirement for parallelism (CRITICAL marker)
  - Added concrete parallel invocation example
  - Added monitoring instructions
  - Status: COMPLETED

- ✓ **Step 3**: "Research Agent Prompt Template" transformation (lines 214-395)
  - Removed external reference to command-patterns.md
  - Inlined complete 150+ line research-specialist prompt template
  - Added explicit placeholder substitution instructions (8 placeholders documented)
  - Included all 4 topic type variations (existing_patterns, best_practices, alternatives, constraints)
  - Added complete report structure template with all metadata fields
  - Specified exact expected output format with examples
  - Status: COMPLETED (181 lines added)

- ✓ **Step 3.5**: "Generate Project Name and Topic Slugs" (lines 397-473)
  - Added EXECUTE NOW emphasis
  - Added complete worked examples (3 for project name, 3 for topic slugs)
  - Added common topic slug list for consistency
  - Added verification checklist
  - Clarified execution order (happens BEFORE Step 2)
  - Status: COMPLETED (76 lines added)

- ✓ **Step 3a**: "Monitor Research Agent Execution" (lines 475-512) - NEW STEP
  - Added new monitoring section with EXECUTE NOW block
  - Added progress marker examples (5 types)
  - Added real-time display format
  - Added expected completion times by complexity
  - Added parallel execution benefit calculation (66% time savings)
  - Status: COMPLETED (38 lines added)

- ✓ **Step 4**: "Collect Report Paths from Agent Output" (lines 514-582)
  - Transformed with explicit 4-step path extraction algorithm
  - Added validation bash snippet
  - Added concrete agent output examples
  - Added context reduction metrics (99.75% savings with 3 reports)
  - Added comprehensive verification checklist (5 items)
  - Added retry and error handling logic
  - Status: COMPLETED (69 lines added)

- ✓ **Step 5**: "Save Research Checkpoint" (lines 584-647)
  - Removed external reference to command-patterns.md
  - Added complete bash script for checkpoint utility usage
  - Inlined checkpoint data structure with field-by-field explanations
  - Added benefits section (resumability, state preservation, performance tracking, error recovery)
  - Status: COMPLETED (64 lines added)

- ✓ **Step 6**: "Research Phase Execution Verification" (lines 649-756)
  - Expanded simple checklist into comprehensive 5-point verification system
  - Added explicit EXECUTE NOW block
  - Added verification commands (bash snippets for each check)
  - Added error handling for 3 failure scenarios
  - Added DO NOT PROCEED warning
  - Added success output format example
  - Status: COMPLETED (108 lines added)

- ✓ **Step 7**: "Complete Research Phase Execution Example" (lines 758-877)
  - Created comprehensive end-to-end example
  - Showed all 7 steps with intermediate data structures
  - Included actual timing data (3m 24s parallel vs 9m 30s sequential)
  - Demonstrated parallel vs sequential comparison (66% savings)
  - Showed checkpoint contents in detail
  - Showed validation checklist completion
  - Status: COMPLETED (120 lines added)

## Objective

Transform the research phase from passive documentation into an execution-driven workflow that explicitly invokes parallel research-specialist agents using the Task tool. This phase converts all descriptive text ("I'll analyze...", "For each topic, I'll create...") into imperative commands with concrete EXECUTE NOW blocks that contain actual Task tool invocations for creating research report files in the specs/reports/{topic}/ directory structure.

## Context and Background

### Why This Phase Is Critical

The research phase is the foundation of the entire /orchestrate workflow. It determines:
1. **Workflow Complexity**: Scoring algorithm decides thinking mode for all subsequent agents
2. **Parallelization Strategy**: Multiple research-specialist agents execute concurrently
3. **Report File Creation**: Permanent documentation artifacts that inform planning
4. **Context Minimization**: File paths replace verbose summaries in later phases

**Current State Problem**: Lines 85-368 of orchestrate.md describe the research workflow beautifully but never instruct Claude to actually invoke research-specialist agents. The text says "I'll launch parallel research agents" but doesn't say "USE the Task tool NOW to launch these agents."

### Architectural Significance

Research phase sets the pattern for all subsequent phases:
- **Parallel Agent Invocation**: First use of Task tool with multiple simultaneous subagents
- **Report File Creation**: Establishes specs/reports/{topic}/NNN_*.md directory structure
- **Path-Based Context**: Demonstrates context minimization by passing file paths instead of content
- **Execution Verification**: Introduces checklist pattern to ensure agents actually invoked

### Risk Factors

1. **Parallel Execution Complexity**: Multiple Task invocations in single message requires careful instruction
2. **Report File Validation**: Must verify agents create files, not just return summaries
3. **Topic Slug Generation**: Project name and topic slugs must be computed before agent invocation
4. **Context Preservation**: Report paths must be captured from agent output for planning phase

## Detailed Implementation Steps

### Step 1: Refactor "Identify Research Topics" (Lines 85-120)

**Current Documentation Pattern** (BEFORE):
```markdown
#### Step 1: Identify Research Topics

I'll analyze the workflow description to extract 2-4 focused research topics:

**Topic Extraction Logic**:
- **Existing Patterns**: "How is [feature/component] currently implemented?"
- **Best Practices**: "What are industry standards for [technology/approach]?"
```

**Target Execution Pattern** (AFTER):
```markdown
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

Simple Workflows (0-3 complexity score) → SKIP research, go directly to planning
Medium Workflows (4-6 complexity score) → 2-3 focused topics
Complex Workflows (7-9 complexity score) → 3-4 comprehensive topics
Critical Workflows (10+ complexity score) → 4+ comprehensive topics with security focus

**Examples**:

User Request: "Add user authentication with email and password"
Topics Identified:
1. existing_patterns - Authentication patterns currently in codebase
2. security_practices - Password hashing and session management best practices (2025)
3. framework_implementations - Framework-specific auth implementations

User Request: "Refactor session management"
Topics Identified:
1. existing_patterns - Current session store implementation
2. alternatives - Alternative session storage approaches
3. best_practices - Session security and performance best practices

**STORE** extracted topics in workflow_state.research_topics array for use in Step 2.
```

**Implementation Details**:
- Remove all "I'll" language
- Convert bullet points to imperative commands (IDENTIFY, EXTRACT, GENERATE)
- Add explicit EXECUTE NOW block with numbered steps
- Include concrete examples showing input → output
- Add storage instruction for workflow state

### Step 2: Refactor "Determine Thinking Mode" (Lines 122-148)

**Current Documentation Pattern** (BEFORE):
```markdown
#### Step 1.5: Determine Thinking Mode

Analyze workflow complexity to set appropriate thinking mode for agents:

**Complexity Indicators**:
- **Simple** (score 0-3): Direct implementation, well-known patterns
```

**Target Execution Pattern** (AFTER):
```markdown
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
```

**Implementation Details**:
- Add concrete scoring algorithm with examples
- Show calculation steps explicitly
- Provide 3 worked examples covering different complexity levels
- Emphasize that this thinking mode applies to all agents in workflow

### Step 3: Refactor "Launch Parallel Research Agents" (Lines 150-162)

**Current Documentation Pattern** (BEFORE):
```markdown
#### Step 2: Launch Parallel Research Agents

For each identified research topic, I'll create a focused research task and invoke agents in parallel.

See [Parallel Agent Invocation](../docs/command-patterns.md#pattern-parallel-agent-invocation) for detailed parallel execution patterns.
```

**Target Execution Pattern** (AFTER):
```markdown
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
```

**Implementation Details**:
- Remove external reference to command-patterns.md
- Add explicit Task tool invocation structure
- Emphasize single-message requirement for parallelism
- Show concrete example of parallel invocation syntax
- Add waiting instruction to prevent premature continuation

### Step 3: Inline Complete Research Agent Prompt Template (Lines 163-247)

**Current Documentation Pattern** (BEFORE):
```markdown
#### Step 3: Research Agent Prompt Template

For agent prompt structure, see [Single Agent with Behavioral Injection](../docs/command-patterns.md#pattern-single-agent-with-behavioral-injection).

**Orchestrate-specific research template**:

```markdown
**Thinking Mode**: [think|think hard|think harder] (based on workflow complexity from Step 1.5)

# Research Task: [Specific Topic]
```

**Target Execution Pattern** (AFTER):
```markdown
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
```

**Implementation Details**:
- Remove external reference to command-patterns.md
- Inline COMPLETE prompt template (all 150+ lines)
- Add explicit placeholder substitution instructions
- Include all 4 topic type variations (existing_patterns, best_practices, alternatives, constraints)
- Show concrete report structure example
- Specify exact expected output format

### Step 4: Refactor "Generate Project Name and Topic Slugs" (Lines 249-284)

**Current Documentation Pattern** (BEFORE):
```markdown
#### Step 3.5: Generate Project Name and Topic Slugs

Before launching research agents, generate a project name and topic slugs for report organization:

**Project Name Generation**:
```
1. Extract key terms from workflow description
```

**Target Execution Pattern** (AFTER):
```markdown
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
```

**Implementation Details**:
- Convert passive description to imperative algorithm
- Add EXECUTE NOW emphasis
- Show complete worked examples (3 for project name, 3 for topic slugs)
- Add common topic slug list for consistency
- Add verification checklist
- Clarify that this step happens BEFORE Step 2 (agent invocation)

### Step 5: Add "Research Agent Monitoring" (New Step After Step 3)

**Target Execution Pattern** (NEW CONTENT):
```markdown
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
```

**Implementation Details**:
- Add new step for monitoring (previously missing)
- Show progress marker examples
- Add user-facing progress display
- Include completion time estimates
- Demonstrate parallelization benefit

### Step 6: Refactor "Collect Report Paths from Agent Output" (Lines 290-307)

**Current Documentation Pattern** (BEFORE):
```markdown
#### Step 4: Collect Report Paths from Agent Output

After each research agent completes, extract the report file path from its output.

**Report Path Extraction**:
- Parse agent output for report file path
```

**Target Execution Pattern** (AFTER):
```markdown
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
```

**Implementation Details**:
- Add explicit parsing instructions
- Show concrete example of extraction from agent output
- Add validation step using Read or Bash tool
- Show workflow_state structure clearly
- Add context reduction calculation (demonstrates value)
- Add verification checklist
- Include retry and error handling logic

### Step 7: Refactor "Save Research Checkpoint" (Lines 306-323)

**Current Documentation Pattern** (BEFORE):
```markdown
#### Step 5: Save Research Checkpoint

See [Save Checkpoint After Phase](../docs/command-patterns.md#pattern-save-checkpoint-after-phase) for checkpoint management.

**Orchestrate-specific checkpoint data**:
```yaml
checkpoint_research_complete:
```

**Target Execution Pattern** (AFTER):
```markdown
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
```

**Implementation Details**:
- Remove external reference to command-patterns.md
- Inline complete checkpoint utility usage
- Show actual bash script invocation (not just YAML)
- Explain all checkpoint fields with inline comments
- Add benefits section to justify checkpoint overhead

### Step 8: Add "Report File Validation" (Lines 325-335, Refactor into Explicit Checklist)

**Current Documentation Pattern** (BEFORE):
```markdown
#### Step 6: Report File Validation

Before proceeding to planning, validate:
- [ ] All research reports saved to `specs/reports/{topic}/`
```

**Target Execution Pattern** (AFTER):
```markdown
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
```

**Implementation Details**:
- Expand validation section into comprehensive checklist
- Add explicit verification commands (bash snippets)
- Show success output format
- Add error handling for each failure scenario
- Make it impossible to skip validation

### Step 9: Add "Research Phase Execution Example" (New Step)

**Target Execution Pattern** (NEW COMPREHENSIVE EXAMPLE):
```markdown
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
```

**Implementation Details**:
- Add comprehensive end-to-end example
- Show all intermediate data structures
- Include actual timing data
- Demonstrate parallel vs sequential comparison
- Show checkpoint contents
- Show validation checklist completion

## Code Examples

### Transformation Pattern: Passive to Active

**BEFORE** (Lines 85-90):
```markdown
#### Step 1: Identify Research Topics

I'll analyze the workflow description to extract 2-4 focused research topics:
```

**AFTER**:
```markdown
#### Step 1: Identify Research Topics

ANALYZE the workflow description to extract 2-4 focused research topics.

**EXECUTE NOW**:
1. READ the user's workflow description
2. IDENTIFY key areas requiring investigation
3. EXTRACT 2-4 specific topics
4. STORE extracted topics in workflow_state
```

### Transformation Pattern: Reference to Inline

**BEFORE** (Lines 150-154):
```markdown
#### Step 2: Launch Parallel Research Agents

For each identified research topic, I'll create a focused research task and invoke agents in parallel.

See [Parallel Agent Invocation](../docs/command-patterns.md) for detailed patterns.
```

**AFTER**:
```markdown
#### Step 2: Launch Parallel Research Agents

**EXECUTE NOW**: USE the Task tool to invoke research-specialist agents in parallel.

For EACH research topic identified in Step 1:

INVOKE using Task tool with these exact parameters:
```json
{
  "subagent_type": "general-purpose",
  "description": "Research [TOPIC] using research-specialist protocol",
  "prompt": "[COMPLETE INLINE PROMPT - 150 lines]"
}
```

Send ALL Task invocations in SINGLE MESSAGE for parallel execution.
```

## Testing Specifications

### Test Case 1: Simple Workflow (Skip Research)

**Input**: `/orchestrate "Add hello world function"`

**Expected Behavior**:
- Complexity score: 2 (Simple)
- Research phase: SKIPPED
- Direct to planning phase
- No research reports created

**Verification**:
```bash
# Verify no research reports created
[ -d "specs/reports/" ] && echo "ERROR: Reports dir should not exist" || echo "✓ No research performed"
```

### Test Case 2: Medium Workflow (2-3 Research Topics)

**Input**: `/orchestrate "Add configuration validation module"`

**Expected Behavior**:
- Complexity score: 5 (Medium)
- Research topics: 2-3 topics identified
- Task tool invoked 2-3 times in SINGLE message
- 2-3 research-specialist agents execute in parallel
- 2-3 report files created in specs/reports/{topic}/
- Report paths collected in workflow_state

**Verification**:
```bash
# Count Task tool invocations in agent message
TASK_COUNT=$(grep -c "subagent_type.*general-purpose" agent_output.log)
[ "$TASK_COUNT" -ge 2 ] && [ "$TASK_COUNT" -le 3 ] || echo "ERROR: Expected 2-3 agents"

# Verify reports created
REPORT_COUNT=$(find specs/reports -name "001_*.md" | wc -l)
[ "$REPORT_COUNT" -eq "$TASK_COUNT" ] || echo "ERROR: Report count mismatch"

# Verify report paths in workflow_state
grep -q "research_reports.*specs/reports" workflow_state.json || echo "ERROR: Report paths not stored"
```

### Test Case 3: Complex Workflow (3-4 Research Topics)

**Input**: `/orchestrate "Implement user authentication system"`

**Expected Behavior**:
- Complexity score: 8-9 (Complex)
- Thinking mode: "think hard"
- Research topics: 3-4 topics identified
- Task tool invoked 3-4 times in SINGLE message
- 3-4 agents execute in parallel
- 3-4 report files created with proper numbering
- Report metadata includes "Thinking Mode: think hard"
- Checkpoint saved with all report paths

**Verification**:
```bash
# Verify thinking mode in agent prompts
grep -c "Thinking Mode: think hard" agent_prompts.log
[ $? -eq 0 ] || echo "ERROR: Thinking mode not set"

# Verify parallel execution (all agents in single message)
MESSAGE_COUNT=$(grep -c "^Task {" agent_message.log)
[ "$MESSAGE_COUNT" -eq 1 ] || echo "ERROR: Not single message (not parallel)"

# Count agents in single message
AGENT_COUNT=$(grep -c "subagent_type.*general-purpose" agent_message.log)
[ "$AGENT_COUNT" -ge 3 ] && [ "$AGENT_COUNT" -le 4 ] || echo "ERROR: Expected 3-4 agents"

# Verify report files
for REPORT_DIR in specs/reports/*/; do
  [ -f "${REPORT_DIR}001_*.md" ] || echo "ERROR: Missing report in $REPORT_DIR"
done

# Verify checkpoint
CHECKPOINT_FILE=".claude/checkpoints/orchestrate_user_authentication_*.json"
[ -f $CHECKPOINT_FILE ] || echo "ERROR: Checkpoint not saved"

# Verify checkpoint contains all report paths
jq '.workflow_state.research_reports | length' $CHECKPOINT_FILE
```

### Test Case 4: Critical Workflow (4+ Topics, Security Focus)

**Input**: `/orchestrate "Refactor core authentication with OAuth2 and security hardening"`

**Expected Behavior**:
- Complexity score: 15+ (Critical)
- Thinking mode: "think harder"
- Research topics: 4+ topics (including security-focused)
- All agents use "think harder" mode
- Reports include security considerations sections
- Checkpoint includes security flags

**Verification**:
```bash
# Verify thinking mode escalation
grep -q "Thinking Mode: think harder" agent_prompts.log || echo "ERROR: Should use 'think harder'"

# Verify security topic included
find specs/reports -type d -name "*security*" || echo "ERROR: No security research topic"

# Verify 4+ agents invoked
AGENT_COUNT=$(grep -c "subagent_type.*general-purpose" agent_message.log)
[ "$AGENT_COUNT" -ge 4 ] || echo "ERROR: Expected 4+ agents for critical workflow"
```

### Performance Test: Parallel Execution Timing

**Objective**: Verify parallel execution is actually faster than sequential

**Test**:
```bash
# Simulate sequential execution (for comparison)
START_SEQ=$(date +%s)
# Run agents one at a time (mock)
sleep 3; sleep 3; sleep 3  # 3 agents × 3 seconds each
END_SEQ=$(date +%s)
SEQUENTIAL_TIME=$((END_SEQ - START_SEQ))

# Actual parallel execution
START_PAR=$(date +%s)
# Run agents in parallel (actual /orchestrate invocation)
/orchestrate "Add config validation"
END_PAR=$(date +%s)
PARALLEL_TIME=$((END_PAR - START_PAR))

# Verify parallel is faster
[ "$PARALLEL_TIME" -lt "$SEQUENTIAL_TIME" ] || echo "ERROR: Parallel not faster than sequential"

# Calculate savings
SAVINGS=$(( (SEQUENTIAL_TIME - PARALLEL_TIME) * 100 / SEQUENTIAL_TIME ))
echo "Time saved: ${SAVINGS}%"
[ "$SAVINGS" -ge 50 ] || echo "WARNING: Expected ≥50% time savings"
```

## Error Handling

### Error Type 1: Agent Invocation Failure

**Scenario**: Task tool invocation fails (invalid syntax, tool unavailable)

**Detection**:
```
Error: Task tool not found
Error: Invalid subagent_type parameter
```

**Recovery Strategy**:
1. VERIFY Task tool is available in allowed-tools list
2. VALIDATE invocation syntax matches working examples
3. RETRY with corrected syntax (max 1 retry)
4. If persistent: ESCALATE to user with error details

**Example Recovery**:
```markdown
ERROR: Task tool invocation failed

Attempted invocation:
{
  "subagent_type": "research-specialist",  # WRONG - must be "general-purpose"
  ...
}

Corrected invocation:
{
  "subagent_type": "general-purpose",
  "description": "Research using research-specialist protocol",
  ...
}

Retrying with corrected syntax...
```

### Error Type 2: Agent Execution Failure

**Scenario**: Research-specialist agent fails during execution (crash, timeout, tool access error)

**Detection**:
```
Agent output: "ERROR: WebSearch timeout"
Agent output: "ERROR: Grep pattern too complex"
```

**Recovery Strategy**:
1. CHECK agent error message for root cause
2. If timeout: NOT retryable (agent already used max time)
3. If tool access: SUGGEST fallback approach
4. CONTINUE with successful agents
5. NOTE missing report in workflow state

**Example Recovery**:
```markdown
WARNING: Research agent failed

Agent: security_practices
Error: WebSearch timeout after 120s
Cause: Network connectivity issue

Recovery:
- Continue with other 2 agents (existing_patterns, framework_implementations)
- Note missing report: security_practices (web research unavailable)
- Suggest manual research or retry later
- Proceed to planning with partial research results

Workflow state updated:
{
  "research_reports": [
    "specs/reports/existing_patterns/001_patterns.md",
    "specs/reports/framework_implementations/001_frameworks.md"
  ],
  "missing_reports": ["security_practices"],
  "research_warnings": ["Web research unavailable, proceed with caution"]
}
```

### Error Type 3: Report File Not Created

**Scenario**: Agent completes but no report file exists at expected path

**Detection**:
```bash
Agent output: "REPORT_PATH: specs/reports/existing_patterns/001_patterns.md"
Validation: ls specs/reports/existing_patterns/001_patterns.md
Result: No such file or directory
```

**Recovery Strategy**:
1. VERIFY agent actually returned REPORT_PATH
2. CHECK if agent returned summary instead of creating file
3. IF summary returned: Create report file manually using agent's summary
4. RETRY agent invocation with explicit "You MUST use Write tool" instruction
5. If retry fails: ESCALATE to user

**Example Recovery**:
```markdown
ERROR: Agent returned REPORT_PATH but file does not exist

Agent: existing_patterns
Claimed path: specs/reports/existing_patterns/001_patterns.md
File exists: NO

Analysis: Agent returned summary in response instead of creating file

Recovery:
1. Extract summary from agent response
2. Use Write tool to create report file manually:

   Write {
     file_path: "specs/reports/existing_patterns/001_patterns.md",
     content: "[Generated report from agent summary]"
   }

3. Validate file now exists
4. Continue with workflow

Outcome: Report file created, path validated, proceeding to next step
```

### Error Type 4: Parallel Execution Not Happening

**Scenario**: Agents invoked sequentially instead of in parallel (multiple messages)

**Detection**:
```
Message 1: Task {...} for agent 1
[Agent 1 completes]
Message 2: Task {...} for agent 2
[Agent 2 completes]
```

**Expected Behavior**:
```
Message 1: Task {...} for agent 1, Task {...} for agent 2, Task {...} for agent 3
[All agents complete concurrently]
```

**Recovery Strategy**:
1. DETECT sequential execution (timing analysis)
2. IF already sequential: Cannot retroactively parallelize
3. NOTE for next workflow: Emphasize SINGLE MESSAGE requirement
4. CONTINUE with workflow (correctness not affected, only performance)

**Example Detection**:
```markdown
NOTICE: Agents executed sequentially (not in parallel)

Expected: 3 agents in single message, ~3 minutes total
Actual: 3 separate messages, 9 minutes total

Impact: Workflow correct but 66% slower than optimal

Root cause: Task tool invocations sent in separate messages

Prevention for next workflow:
Review Step 2 instructions: "Send ALL Task invocations in SINGLE MESSAGE"
```

### Error Type 5: Invalid Report Numbering

**Scenario**: Agent creates report with wrong number (001 when 002 expected)

**Detection**:
```bash
Existing: specs/reports/existing_patterns/001_first_report.md
Agent creates: specs/reports/existing_patterns/001_second_report.md  # WRONG - should be 002
```

**Recovery Strategy**:
1. DETECT duplicate numbering via Glob
2. RENAME incorrectly numbered report to correct number
3. UPDATE REPORT_PATH in workflow state
4. VERIFY no conflicts after rename

**Example Recovery**:
```bash
ERROR: Duplicate report number detected

Existing reports:
- specs/reports/existing_patterns/001_first_report.md

New report (INVALID):
- specs/reports/existing_patterns/001_second_report.md

Correction:
mv specs/reports/existing_patterns/001_second_report.md \
   specs/reports/existing_patterns/002_second_report.md

Updated REPORT_PATH: specs/reports/existing_patterns/002_second_report.md

Verification: No duplicate numbers remain
```

## Success Criteria

### Primary Criteria (Must Pass All)

1. **Agent Invocation Verified**:
   - [ ] Task tool explicitly invoked for each research topic
   - [ ] All invocations use correct syntax (subagent_type: general-purpose)
   - [ ] All invocations sent in SINGLE message (parallel execution)

2. **Report Files Created**:
   - [ ] Report file exists for each successful agent
   - [ ] Files located at specs/reports/{topic_slug}/NNN_*.md
   - [ ] Report numbering sequential within each topic directory (001, 002, 003...)

3. **Report Paths Collected**:
   - [ ] REPORT_PATH extracted from each agent output
   - [ ] Paths stored in workflow_state.research_reports array
   - [ ] All stored paths are valid and readable

4. **Execution Checklist Present**:
   - [ ] Verification checklist added after Step 6
   - [ ] Checklist prevents proceeding without validation
   - [ ] All checklist items can be objectively verified

5. **Transformation Complete**:
   - [ ] All passive voice removed ("I'll" → "ANALYZE", "EXTRACT", etc.)
   - [ ] All external references inlined (no links to command-patterns.md)
   - [ ] All EXECUTE NOW blocks added with concrete instructions
   - [ ] Complete prompt template inlined (150+ lines from Step 3)

### Secondary Criteria (Should Pass Most)

6. **Examples and Guidance**:
   - [ ] 3+ worked examples for project name generation
   - [ ] 3+ worked examples for topic slug generation
   - [ ] Complete end-to-end example showing all steps
   - [ ] Common topic slugs list provided

7. **Error Handling**:
   - [ ] 5+ error scenarios documented
   - [ ] Recovery strategy for each error type
   - [ ] Detection method for each error type
   - [ ] Example recovery shown for each error

8. **Performance**:
   - [ ] Parallel execution demonstrably faster than sequential
   - [ ] Time savings ≥50% with 3 agents
   - [ ] Context reduction ≥90% (report paths vs full summaries)

### Testing Criteria

9. **Test Coverage**:
   - [ ] Test case for simple workflow (skip research)
   - [ ] Test case for medium workflow (2-3 agents)
   - [ ] Test case for complex workflow (3-4 agents)
   - [ ] Test case for critical workflow (4+ agents, security)
   - [ ] Performance test verifying parallel execution

10. **Validation**:
    - [ ] All test cases pass
    - [ ] Agent invocations visible in test output
    - [ ] Report files created in all tests
    - [ ] No test can proceed without validation passing

## Notes

### Implementation Tips

1. **Order of Steps**: Note that Step 3.5 (Generate Project Name and Topic Slugs) must execute BEFORE Step 2 (Launch Parallel Research Agents) because agents need project_name and topic_slugs in their prompts. The current numbering (3.5 after Step 2) is documentation order, not execution order.

2. **Single Message Emphasis**: The most critical instruction is "Send ALL Task invocations in SINGLE MESSAGE". This must be emphasized multiple times because it's the key to parallel execution. Consider adding visual emphasis:
   ```
   **CRITICAL**: Send ALL research Task invocations in a SINGLE MESSAGE.
   ```

3. **Prompt Template Length**: The complete research agent prompt template (Step 3) is ~150 lines. This is intentionally verbose to eliminate ambiguity. Do not try to shorten it - completeness is more important than brevity here.

4. **Verification Checklist Placement**: The verification checklist (Step 6) should be impossible to skip. Consider adding:
   ```
   STOP: Do not proceed to planning phase until ALL items in checklist are verified.
   ```

### Gotchas

1. **Topic Slug Collisions**: If multiple workflows use the same topic slugs (e.g., "existing_patterns"), reports will be numbered sequentially in same directory. This is intended behavior - related research accumulates in topic directories.

2. **Thinking Mode Propagation**: The thinking mode determined in Step 1.5 must be included in ALL subsequent agent prompts (research, planning, implementation, debugging, documentation). Add reminder in Step 1.5:
   ```
   This thinking mode will be prepended to ALL agent prompts in this workflow.
   ```

3. **Checkpoint Resume**: If workflow is interrupted during research phase (e.g., some agents complete, others fail), checkpoint enables resuming. However, resuming parallel agent invocation is complex. Consider adding guidance:
   ```
   On resume: Check workflow_state.research_reports, re-invoke only missing agents.
   ```

4. **Report Path Format**: Report paths must be RELATIVE (not absolute) because they'll be passed to plan-architect agent which may run in different working directory. Always use:
   ```
   specs/reports/topic/001_report.md  (CORRECT)
   /home/user/.config/specs/reports/topic/001_report.md  (WRONG)
   ```

### Performance Considerations

1. **Parallel Overhead**: Invoking 4 agents in parallel vs 3 agents doesn't necessarily reduce total time (agents still wait for shared resources like file system). Optimal parallelization: 2-4 agents.

2. **Context Window**: With 3 research agents × 150-line prompts = 450 lines of prompt text in single message. This is acceptable (well under context limits). If scaling to 5+ agents, consider prompt compression.

3. **Report File Size**: Research reports typically 100-300 lines. With 4 reports × 200 lines = 800 lines total. Planning agent receives ONLY file paths, not content, so this doesn't impact planning phase context.

### Future Enhancements

After Phase 2 is complete and tested:

1. **Dynamic Topic Detection**: Could use Claude to analyze workflow and suggest research topics interactively before invoking agents.

2. **Report Templates**: Could provide topic-specific templates (security_practices template emphasizes CVEs, best_practices template emphasizes authoritative sources).

3. **Incremental Research**: Could support resuming research phase with additional topics without re-running completed agents.

4. **Research Quality Metrics**: Could add scoring system for report quality (completeness, file references, actionability) and flag low-quality reports for revision.
