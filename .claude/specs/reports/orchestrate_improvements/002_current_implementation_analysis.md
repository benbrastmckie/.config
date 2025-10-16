# Current /orchestrate Research Phase Implementation Analysis

## Metadata
- **Date**: 2025-10-13
- **Specs Directory**: /home/benjamin/.config/specs
- **Report Number**: 001
- **Topic**: orchestrate_improvements
- **Created By**: Research Agent
- **Research Focus**: Current implementation analysis
- **Related Command**: /orchestrate

## Summary

The /orchestrate command currently implements a centralized research aggregation model where the orchestrator agent collects report paths from parallel research-specialist agents and passes them to the planning phase. Research agents create individual report files using the Write tool, but the orchestrator is responsible for parsing REPORT_PATH outputs, validating files, and managing state. This creates coupling between the orchestrator and research outputs, with potential brittleness in path extraction and validation.

## Current Research Phase Workflow

### Phase Overview

The research phase executes in 7 distinct steps:

1. **Step 1**: Identify Research Topics (2-4 topics based on complexity)
2. **Step 1.5**: Determine Thinking Mode (complexity scoring algorithm)
3. **Step 3.5**: Generate Project Name and Topic Slugs (executed BEFORE agent invocation)
4. **Step 2**: Launch Parallel Research Agents (all in single message)
5. **Step 3a**: Monitor Research Agent Execution (PROGRESS markers)
6. **Step 4**: Collect Report Paths from Agent Output
7. **Step 5**: Save Research Checkpoint
8. **Step 6**: Research Phase Execution Verification

### Agent Invocation Pattern

**Parallel Execution via Task Tool**

Research agents are invoked in parallel using multiple Task tool calls in a single message:

```json
{
  "subagent_type": "general-purpose",
  "description": "Research [TOPIC_NAME] using research-specialist protocol",
  "prompt": "Read and follow: .claude/agents/research-specialist.md\n\n[COMPLETE PROMPT]"
}
```

**Critical Implementation Details**:

- **Parallelization**: All Task invocations MUST be sent in SINGLE message for concurrent execution
- **Agent Protocol**: Each agent reads `/home/benjamin/.config/.claude/agents/research-specialist.md` for behavioral guidelines
- **Prompt Structure**: Orchestrator constructs complete prompts with substituted placeholders
- **Agent Count**: 2-4 agents based on workflow complexity

**Prompt Template Substitution**:

The orchestrator generates project name and topic slugs BEFORE agent invocation (Step 3.5) and substitutes these placeholders in each agent prompt:

- `[THINKING_MODE]`: Complexity-based thinking mode ("think", "think hard", "think harder", or empty)
- `[TOPIC_TITLE]`: Human-readable research topic title
- `[USER_WORKFLOW]`: Original user workflow description
- `[PROJECT_NAME]`: Generated slug (e.g., "user_authentication")
- `[TOPIC_SLUG]`: Topic directory name (e.g., "existing_patterns", "security_practices")
- `[SPECS_DIR]`: Path to specs directory (auto-detected or from SPECS.md)
- `[COMPLEXITY_LEVEL]`: Simple|Medium|Complex|Critical
- `[SPECIFIC_REQUIREMENTS]`: Research focus for this agent

### Result Aggregation

**Current Centralized Model**:

1. **Report File Creation**: Each research-specialist agent:
   - Uses Glob to find existing reports in topic directory
   - Calculates next report number (001, 002, 003...)
   - Creates report file using Write tool at: `specs/reports/{topic_slug}/NNN_report_name.md`
   - Returns structured output: `REPORT_PATH: {path}`

2. **Path Extraction** (orchestrator.md lines 1072-1135):
   - Orchestrator parses agent output for "REPORT_PATH: [path]" line
   - Validates path format (must contain "specs/reports/{topic}/")
   - Validates file exists using Read tool or Bash
   - Stores valid paths in `workflow_state.research_reports` array

3. **Validation** (orchestrator.md lines 1206-1288):
   - Verifies all Task invocations sent in single message
   - Verifies all agents completed successfully
   - Verifies report files exist at expected paths
   - Verifies report numbering follows NNN format
   - Verifies report metadata complete
   - Retry logic: Max 1 retry per missing report

**Path Collection Code Pattern**:

```bash
# Parse agent output for report path line
REPORT_PATH=$(echo "$AGENT_OUTPUT" | grep "^REPORT_PATH:" | sed 's/REPORT_PATH:\s*//')

# Validate report file exists
if [ -f "$REPORT_PATH" ]; then
  echo "✓ Report exists: $REPORT_PATH"
  RESEARCH_REPORTS+=("$REPORT_PATH")
else
  echo "✗ Report missing: $REPORT_PATH"
  # Retry agent invocation (max 1 retry)
fi
```

**Context Savings**:

The current implementation achieves 97% context savings per report by storing only paths:

- **Full report content**: ~200 words = 1000 tokens
- **Path reference**: 50 characters = 25 tokens
- **Savings**: 97% per report, 99.75% for 3 reports (600 words → 150 characters)

### Report Generation

**Location: Research Agents (NOT Orchestrator)**

Report files are created by individual research-specialist agents, not by the orchestrator:

**Agent Responsibilities** (research-specialist.md lines 166-243):

1. **Determine Report Number**:
   - Use Glob: `{specs_dir}/reports/{topic}/[0-9][0-9][0-9]_*.md`
   - Parse highest number, increment by 1
   - Format as 3-digit: 001, 002, 003...

2. **Conduct Research**:
   - Codebase analysis (Grep, Glob, Read)
   - Best practices research (WebSearch, WebFetch)
   - Pattern identification

3. **Format Report**:
   - Complete metadata section (Date, Specs Directory, Report Number, Topic, Created By, Workflow)
   - Implementation Status section (Status, Plan, Implementation, Date)
   - Research Focus description
   - Findings (Current State Analysis, Industry Best Practices, Key Insights)
   - Recommendations (Primary Recommendation, Alternative Approach, pros/cons)
   - Potential Challenges with mitigation strategies
   - References (file paths with line numbers, URLs, related code)

4. **Write Report File**:
   - Use Write tool to create: `{specs_dir}/reports/{topic}/NNN_report_name.md`

5. **Return Path**:
   - Output: `REPORT_PATH: {path}`
   - Brief summary (1-2 sentences)

**Report Structure Template** (orchestrator.md lines 869-922):

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

### Planning Handoff

**Context Extraction Phase** (orchestrator.md lines 1476-1539):

The orchestrator extracts minimal context for the planning agent:

**From Research Phase**:
```yaml
research_context:
  report_paths: workflow_state.research_reports  # Array of file paths only
  topics: workflow_state.topic_slugs  # Topics investigated
  # DO NOT read report content - agent will use Read tool selectively
```

**Planning Agent Prompt Includes**:

1. **Research Report Paths** (if research completed):
   ```markdown
   Available Research Reports:
   1. **Existing Patterns**
      - Path: specs/reports/existing_patterns/001_auth_patterns.md
      - Topic: Current implementation analysis

   2. **Security Practices**
      - Path: specs/reports/security_practices/001_best_practices.md
      - Topic: Security standards (2025)
   ```

2. **User Request**: Original workflow description
3. **Project Standards Path**: `/home/benjamin/.config/CLAUDE.md`
4. **Thinking Mode**: Carried forward from research phase for consistency
5. **Project Name**: Generated slug for plan naming

**Key Strategy**:

- **Paths Only**: Orchestrator provides file paths, NOT full report content
- **Agent Reads Selectively**: plan-architect uses Read tool to access report sections as needed
- **Context Optimization**: Avoids bloating prompt with full report content (97% savings)

**Handoff Verification** (orchestrator.md lines 1533-1539):

```yaml
Context Validation Checklist:
- [ ] Research report paths exist (if research phase completed)
- [ ] User workflow description is clear and complete
- [ ] Project name is set correctly
- [ ] Thinking mode is specified (if applicable)
- [ ] CLAUDE.md path is valid
```

## Key Files and Components

### Primary Implementation Files

1. **Orchestrate Command**:
   - Path: `/home/benjamin/.config/.claude/commands/orchestrate.md`
   - Size: 47,695 tokens (too large to read at once)
   - Research Phase: Lines 610-1472
   - Planning Handoff: Lines 1476-2097

2. **Research Specialist Agent**:
   - Path: `/home/benjamin/.config/.claude/agents/research-specialist.md`
   - Size: 419 lines
   - Report Creation Protocol: Lines 166-243
   - Behavioral Guidelines: Lines 45-101
   - Progress Streaming: Lines 62-101

3. **Artifact Utilities**:
   - Path: `/home/benjamin/.config/.claude/lib/artifact-utils.sh`
   - Size: 879 lines
   - Report Metadata Extraction: Lines 310-362 (`get_report_metadata`)
   - Report Section Extraction: Lines 439-474 (`get_report_section`)

### Workflow State Management

**State Structure** (orchestrator.md lines 184-195):

```yaml
context_preservation:
  research_reports: []  # Paths to created report files
  plan_path: ""         # Path to implementation plan
  implementation_status:
    tests_passing: false
    files_modified: []
  debug_reports: []     # Paths to debug report files
  documentation_paths: [] # Paths to generated documentation
```

**Research Phase Updates** (orchestrator.md lines 1317-1327):

```yaml
workflow_state.current_phase = "planning"
workflow_state.execution_tracking.phase_start_times["research"] = [timestamp]
workflow_state.execution_tracking.phase_end_times["research"] = [timestamp]
workflow_state.execution_tracking.agents_invoked += [number of research agents]
workflow_state.execution_tracking.files_created += [number of reports]
workflow_state.completed_phases.append("research")
workflow_state.context_preservation.research_reports = [array of report paths]
```

### Checkpoint System

**Checkpoint Creation** (orchestrator.md lines 1150-1204):

```bash
# Checkpoint data structure
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
```

**Checkpoint File**:
- Location: `.claude/checkpoints/orchestrate_{project_name}_{timestamp}.json`
- Purpose: Enable workflow resumption if interrupted

## Current Limitations

### 1. Centralized Path Extraction Brittleness

**Issue**: Orchestrator must parse unstructured agent output for "REPORT_PATH: [path]" pattern

**Risks**:
- Agent output format changes break extraction
- Extra whitespace or formatting variations cause failures
- No typed interface between agents and orchestrator

**Evidence** (orchestrator.md lines 1079-1087):

```bash
# Fragile string parsing
REPORT_PATH=$(echo "$AGENT_OUTPUT" | grep "^REPORT_PATH:" | sed 's/REPORT_PATH:\s*//')

# Manual validation required
if [ -f "$REPORT_PATH" ]; then
  echo "✓ Report exists: $REPORT_PATH"
else
  echo "✗ Report missing: $REPORT_PATH"
fi
```

### 2. Manual Validation Overhead

**Issue**: Orchestrator must explicitly verify each report file exists and has correct metadata

**Overhead**:
- Read first 20 lines of each report to check metadata (orchestrator.md line 1236)
- Verify report numbering follows NNN format (orchestrator.md line 1223)
- Verify topic field matches topic_slug (orchestrator.md line 1235)
- Manual retry logic for missing reports (max 1 retry, orchestrator.md line 1277)

**Validation Checklist** (orchestrator.md lines 1212-1242):

```yaml
1. Agent Invocation Verified:
   - [ ] Task tool invoked for each research topic
   - [ ] All Task invocations sent in SINGLE message
   - [ ] All agents completed successfully

2. Report Files Created:
   - [ ] Each successful agent created a report file
   - [ ] Report files exist at expected paths
   - [ ] Report numbering follows NNN format

3. Report Paths Collected:
   - [ ] REPORT_PATH extracted from each agent output
   - [ ] Report paths stored in workflow_state.research_reports array
   - [ ] Number of paths matches number of successful agents

4. Report Metadata Complete:
   - [ ] Each report includes all required metadata fields
   - [ ] Specs Directory field present in each report
   - [ ] Topic field matches topic_slug

5. Checkpoint Saved:
   - [ ] Research checkpoint saved successfully
   - [ ] Checkpoint includes all research_reports paths
```

### 3. Tight Coupling Between Orchestrator and Research Agents

**Issue**: Orchestrator generates topic slugs, project names, and complete prompts for research agents

**Coupling Points**:

1. **Topic Slug Generation** (orchestrator.md lines 987-1028):
   - Orchestrator runs slug generation algorithm
   - Slugs must match exactly with report directory structure
   - Changes to slug algorithm break existing reports

2. **Prompt Template Management** (orchestrator.md lines 785-950):
   - Orchestrator maintains 165-line prompt template
   - 8 placeholder substitutions required per agent
   - Changes to research protocol require orchestrator updates

3. **Report Structure Requirements**:
   - Orchestrator specifies exact markdown template (lines 869-922)
   - Changes to report format require orchestrator changes
   - No versioning for report format evolution

### 4. Limited Error Recovery

**Issue**: Simple retry logic (max 1 retry per agent) with no adaptive strategies

**Limitations**:
- Single retry attempt before failure (orchestrator.md line 1277)
- No diagnosis of WHY agent failed
- No alternative strategies if report creation fails
- User escalation after 1 failed retry

**Retry Logic** (orchestrator.md lines 1274-1287):

```yaml
If Validation Fails:

- Missing Report Files:
  - Retry agent invocation for missing reports (max 1 retry)
  - If retry fails: Proceed with available reports, document missing reports

- Invalid Metadata:
  - Use Edit tool to correct metadata in report file
  - Ensure all required fields present

- Checkpoint Save Failed:
  - Retry checkpoint save operation
  - If persistent: Continue without checkpoint
```

### 5. No Incremental Progress Tracking

**Issue**: PROGRESS markers are emitted but not formally tracked in workflow state

**Evidence** (orchestrator.md lines 766-769):

```yaml
Monitoring:
- Watch for PROGRESS: markers from each agent
- Collect REPORT_PATH: outputs as agents complete
- Verify all agents complete successfully before moving to Step 4
```

**Gap**:
- Progress markers are informal (research-specialist.md lines 62-101)
- No structured progress state in workflow_state
- No way to query "which agents are complete?" from state
- Manual monitoring required during parallel execution

### 6. Context Optimization Trade-offs

**Issue**: 97% context savings achieved by storing paths only, but introduces indirection

**Trade-offs**:

1. **Benefits**:
   - Massive context savings (600 words → 150 chars for 3 reports)
   - Enables passing multiple reports to planning agent
   - Avoids bloating prompts with full report content

2. **Costs**:
   - Planning agent must Read reports selectively
   - No guarantee planning agent reads relevant sections
   - Additional tool calls during planning phase
   - Risk of missing critical research findings

**Strategy** (orchestrator.md lines 1492-1497):

```yaml
research_context:
  report_paths: workflow_state.research_reports  # Array of file paths only
  topics: workflow_state.topic_slugs  # Topics investigated
  # DO NOT read report content - agent will use Read tool selectively
```

## Technical Details

### Parallel Execution Mechanism

**Critical Implementation Detail** (orchestrator.md lines 750-762):

```markdown
**CRITICAL**: Send ALL research Task invocations in a SINGLE MESSAGE.

This enables parallel execution. Do NOT send Task invocations sequentially -
they must all be in one response to execute concurrently.

**Example Parallel Invocation** (3 research topics):

```
Here are three research tasks to execute in parallel:

[Task tool invocation #1 for existing_patterns]
[Task tool invocation #2 for security_practices]
[Task tool invocation #3 for framework_implementations]
```
```

**Performance Impact** (orchestrator.md lines 1062-1068):

```yaml
Parallel Execution Time Calculation:
- Sequential (one after another): sum(individual times) = 3 + 4 + 2 = 9 minutes
- Parallel (all at once): max(3 minutes) = 3 minutes
- Time saved: ~66% for 3 agents
```

### Complexity Scoring Algorithm

**Thinking Mode Determination** (orchestrator.md lines 660-700):

```python
# Complexity score calculation
score = 0
score += count_keywords(["implement", "architecture", "redesign"]) × 3
score += count_keywords(["add", "improve", "refactor"]) × 2
score += count_keywords(["security", "breaking", "core"]) × 4
score += estimated_file_count / 5
score += (research_topics_needed - 1) × 2

# Map to thinking mode
if score <= 3:
    thinking_mode = ""  # Standard processing
elif score <= 6:
    thinking_mode = "think"  # Moderate complexity
elif score <= 9:
    thinking_mode = "think hard"  # High complexity
else:
    thinking_mode = "think harder"  # Critical decisions
```

**Examples**:

1. "Add hello world function"
   - Keywords: "add" (×1) = 2 points
   - Files: ~1 = 0 points
   - Topics: 0 = 0 points
   - **Total: 2 (Simple, no thinking mode)**

2. "Implement user authentication system"
   - Keywords: "implement" (×1) = 3 points
   - Files: ~8-10 = 2 points
   - Topics: 3 = 4 points
   - **Total: 9 (Complex, "think hard")**

3. "Refactor core security module with breaking changes"
   - Keywords: "refactor" (×1) = 2, "security" (×1) = 4, "breaking" (×1) = 4, "core" (×1) = 4
   - Files: ~15 = 3 points
   - Topics: 4 = 6 points
   - **Total: 23 (Critical, "think harder")**

### Report Numbering Logic

**Incremental Numbering Within Topic** (research-specialist.md lines 224-236):

```bash
# Determine next report number
TOPIC_DIR="{specs_dir}/reports/{topic}"
mkdir -p "$TOPIC_DIR"

# Find existing reports
EXISTING=$(ls "$TOPIC_DIR"/[0-9][0-9][0-9]_*.md 2>/dev/null | wc -l)
NEXT_NUM=$(printf "%03d" $((EXISTING + 1)))

# Create report path
REPORT_PATH="$TOPIC_DIR/${NEXT_NUM}_${report_name}.md"
```

**Directory Structure**:

```
specs/
├── reports/
│   ├── existing_patterns/
│   │   ├── 001_auth_patterns.md
│   │   └── 002_session_patterns.md
│   ├── security_practices/
│   │   └── 001_best_practices.md
│   └── alternatives/
│       └── 001_implementation_options.md
```

**Benefits**:
- Each topic has independent numbering sequence starting from 001
- Topics are determined during research phase (flexible, not pre-defined)
- Easy to find reports by topic (organized subdirectories)

### Artifact Utilities Integration

**Metadata Extraction Function** (artifact-utils.sh lines 310-362):

```bash
get_report_metadata() {
  local report_path="${1:-}"

  # Read only first 100 lines (metadata + exec summary section)
  local metadata_lines=$(head -100 "$report_path")

  # Extract title (first # heading)
  local title=$(echo "$metadata_lines" | grep -m1 '^# ' | sed 's/^# //')

  # Extract date from metadata
  local date=$(echo "$metadata_lines" | grep -m1 '^\s*-\s*\*\*Date\*\*:' | sed 's/.*Date\*\*:\s*//')

  # Extract research question count
  local question_count=$(echo "$metadata_lines" | grep -c '^\s*[0-9]\+\.\s' || echo "0")

  # Build JSON
  jq -n \
    --arg title "${title:-Unknown Report}" \
    --arg date "${date:-Unknown}" \
    --arg questions "$question_count" \
    --arg path "$report_path" \
    '{
      title: $title,
      date: $date,
      research_questions: ($questions | tonumber),
      path: $path
    }'
}
```

**Usage**:
- Enables metadata-only reads without full file content
- Supports `/list reports` command efficiency
- Provides structured JSON for tooling integration

## Recommendations for Transition

### 1. Maintain Parallel Execution Pattern

**Keep What Works**:
- Single-message Task invocations for parallel execution
- Complexity-based thinking mode calculation
- Project name and topic slug generation algorithm
- Checkpoint system for workflow resumption

**Rationale**: These patterns are well-tested and provide proven performance benefits (66% time savings for 3 agents).

### 2. Decouple Report Path Management

**Current Problem**: Orchestrator parses unstructured "REPORT_PATH: [path]" output

**Proposed Solution**:
- Move path construction logic entirely into research-specialist agents
- Agents determine report paths, create files, and manage state internally
- Orchestrator receives structured path data (not via string parsing)
- Agents could register reports in artifact registry (artifact-utils.sh lines 24-79)

**Benefits**:
- Eliminates fragile string parsing
- Removes validation overhead from orchestrator
- Enables agent-level error recovery
- Allows independent agent evolution

### 3. Simplify Orchestrator Responsibilities

**Current Responsibilities** (should be reduced):
- Topic slug generation → Keep (needed for directory structure)
- Project name generation → Keep (needed for checkpoints)
- Prompt template construction → Simplify or delegate
- Report path extraction → Remove (agents provide directly)
- Report file validation → Remove (agents self-validate)
- Retry logic → Move to agents (agents retry internally)

**New Orchestrator Responsibilities**:
- Launch parallel agents with minimal context
- Collect completed report paths from agent responses
- Save checkpoint with research_reports array
- Pass report paths to planning phase

### 4. Enhance Error Recovery

**Current Gap**: Single retry, no diagnostics

**Proposed Improvements**:
- Agents implement internal retry with exponential backoff (research-specialist.md lines 103-162)
- Agents provide structured error information if all retries fail
- Orchestrator logs errors but doesn't block workflow
- Proceed with available reports if some agents fail (partial success model)

**Evidence of Existing Pattern** (research-specialist.md lines 106-143):

Research-specialist already defines retry strategies:
- Network Errors: 3 retries with exponential backoff (1s, 2s, 4s)
- File Access Errors: 2 retries with 500ms delay
- Search Timeouts: 1 retry with modified search

### 5. Formalize Progress Tracking

**Current Gap**: Informal PROGRESS markers, no state tracking

**Proposed Solution**:
- Define progress state in workflow_state:
  ```yaml
  research_progress:
    total_agents: 3
    completed_agents: 1
    failed_agents: 0
    agent_status:
      - {topic: "existing_patterns", status: "completed", report_path: "..."}
      - {topic: "security_practices", status: "in_progress", report_path: null}
      - {topic: "alternatives", status: "pending", report_path: null}
  ```
- Agents emit structured progress updates
- Orchestrator updates progress state incrementally

**Benefits**:
- Enables real-time progress querying
- Supports resumption from partial completion
- Provides better user feedback

### 6. Consider Report Format Versioning

**Current Gap**: No versioning for report structure changes

**Proposed Solution**:
- Add version field to report metadata:
  ```markdown
  ## Metadata
  - **Format Version**: 1.0
  - **Date**: YYYY-MM-DD
  ...
  ```
- Agents check version compatibility
- Planning agents handle multiple report formats
- Enables gradual migration during format evolution

**Rationale**: As system evolves, report structure will change. Versioning enables backward compatibility.

### 7. Preserve Context Optimization Strategy

**Keep What Works**:
- Store only report paths in workflow_state (97% context savings)
- Planning agents read reports selectively using Read tool
- Avoid bloating orchestrator prompts with full report content

**Potential Enhancement**:
- Use artifact-utils.sh `get_report_metadata()` (lines 310-362) to provide lightweight metadata to planning agent
- Planning agent gets title, date, topic without reading full file
- Enables better report selection for selective reading

## Implementation Strategy Notes

### Phase 1: Minimal Changes

**Goal**: Improve reliability without major refactoring

**Changes**:
1. Add structured error reporting to research-specialist agents
2. Implement agent-level retry logic (already defined, not enforced)
3. Add report metadata version field
4. Enhance checkpoint to include partial progress state

**Non-Goals**: Don't change orchestrator/agent interface yet

### Phase 2: Interface Improvement

**Goal**: Reduce coupling, improve error recovery

**Changes**:
1. Agents register reports in artifact registry (artifact-utils.sh)
2. Orchestrator queries registry instead of parsing output
3. Move validation responsibility to agents
4. Implement graceful degradation (proceed with available reports)

**Benefits**: Cleaner interface, better error handling

### Phase 3: Advanced Features

**Goal**: Enable sophisticated workflows

**Changes**:
1. Real-time progress tracking state
2. Agent-level parallelization optimization
3. Report format versioning and migration
4. Adaptive topic selection based on findings

**Prerequisites**: Phase 1 and Phase 2 complete, stable

## Conclusion

The current /orchestrate research phase implementation uses a centralized aggregation model with parallel agent execution. While the parallel execution pattern is efficient (66% time savings), the orchestrator bears significant responsibility for path extraction, validation, and error handling. The system achieves excellent context optimization (97% savings) but introduces brittleness through string-based parsing and tight coupling.

The transition to individual subagent report creation should preserve:
- Parallel execution via single-message Task invocations
- Context optimization via path-only storage
- Complexity-based thinking mode calculation
- Checkpoint-based workflow resumption

The transition should eliminate:
- Fragile REPORT_PATH string parsing
- Manual report file validation by orchestrator
- Centralized retry logic
- Tight coupling through prompt template management

Key technical patterns to leverage:
- Artifact registry system (artifact-utils.sh)
- Metadata extraction functions (get_report_metadata)
- Existing retry strategies in research-specialist.md
- Progress marker protocol (already defined)

The redesign should focus on moving responsibility from orchestrator to agents, enabling independent evolution while maintaining proven performance characteristics.
