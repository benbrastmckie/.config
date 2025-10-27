# Workflow Phases Documentation

This document provides comprehensive documentation for all workflow phases in the /orchestrate command, including detailed execution procedures, agent invocation patterns, and checkpoint management.

**Referenced by**: [orchestrate.md](../orchestrate.md)

**Contents**:
- Research Phase (Parallel Execution)
- Planning Phase (Sequential Execution)
- Implementation Phase (Adaptive Execution)
- Documentation Phase (Sequential Execution)

---

## Phase Coordination

### Research Phase (Parallel Execution)

The research phase coordinates multiple specialized agents to investigate different aspects of the workflow in parallel, then verifies all research outputs before proceeding.

**When to Use Research Phase**:
- **Complex workflows** requiring investigation of existing patterns, best practices, alternatives, or constraints
- **Medium+ complexity** (keywords: "implement", "add with research", "redesign", "architecture")
- **Skip for simple tasks** (keywords: "fix", "update single file", "small change")

**Quick Overview**:
1. Analyze workflow complexity and determine thinking mode
2. Identify 2-4 research topics based on complexity
3. Launch research-specialist agents in parallel (single message, multiple Task calls)
4. Monitor agent execution and collect report paths
5. Verify reports exist at expected paths (with automatic path mismatch recovery)
6. Save checkpoint with research outputs

**Pattern Details**: See [Orchestration Patterns - Research Phase](../templates/orchestration-patterns.md#research-phase-parallel-execution) for:
- Complete step-by-step execution procedure (7 detailed steps)
- Complexity score calculation algorithm
- Thinking mode determination matrix
- Absolute path calculation requirements
- Parallel agent invocation patterns
- Progress monitoring and PROGRESS: marker standards
- Report verification and error recovery procedures
- Checkpoint creation and state management
- Full workflow example with timing metrics

**Key Execution Requirements**:

1. **Complexity Analysis** (Step 1.5):
   ```
   score = keywords("implement"/"architecture") × 3
         + keywords("add"/"improve") × 2
         + keywords("security"/"breaking") × 4
         + estimated_files / 5
         + (research_topics - 1) × 2

   Thinking Mode:
   - 0-3: standard (no special mode)
   - 4-6: "think" (moderate)
   - 7-9: "think hard" (complex)
   - 10+: "think harder" (critical)
   ```

2. **Parallel Agent Invocation** (Step 2.5):
   - **CRITICAL**: Send ALL Task tool invocations in SINGLE message
   - Use general-purpose subagent_type
   - Reference research-specialist.md behavioral guidelines
   - Include thinking mode in each agent prompt
   - Provide ABSOLUTE report paths (not relative)

3. **Report Verification** (Steps 4.5-4.6):
   - Verify files exist at expected ABSOLUTE paths
   - Detect path mismatches (file created at different location)
   - Automatic recovery: move files to correct location OR retry agent
   - Max 1 retry per agent (loop prevention)
   - Proceed if ≥50% reports verified

4. **Checkpoint and State Management** (Step 5):
   - Save checkpoint after all reports verified
   - Store: research_reports (array of paths), thinking_mode, complexity_score, project_name
   - Update workflow_state.current_phase = "planning"
   - Update TodoWrite to mark research complete

**Context Reduction Benefit**:
- **Before**: Pass 200+ words × N reports = 600+ words for 3 reports
- **After**: Pass N file paths × 50 chars = 150 chars for 3 reports
- **Savings**: 99.75% context reduction (600 words → 150 chars)

**Performance Metrics**:
- **Simple research**: 1-2 min/agent in parallel (vs 3-6 min sequential)
- **Complex research**: 4-6 min/agent in parallel (vs 12-18 min sequential)
- **Time savings**: ~66% for 3 agents, ~75% for 4 agents

**Error Recovery** (Step 4.6):
```yaml
Error Types and Recovery:
  path_mismatch:
    recovery: Move file to expected path OR retry with emphasized path
    retryable: true
  file_not_found:
    recovery: Retry agent with emphasized file creation requirement
    retryable: true
  invalid_metadata:
    recovery: Fix metadata with Edit tool OR retry agent
    retryable: true
  permission_denied:
    recovery: Escalate to user (infrastructure issue)
    retryable: false
```

**Quick Example**:

```bash
# Step 1: Analyze workflow
WORKFLOW="Implement user authentication with sessions"
COMPLEXITY_SCORE=9  # "implement" + "authentication" (security) + ~10 files
THINKING_MODE="think hard"  # Score 7-9

# Step 1: Identify topics
TOPICS=("existing_patterns" "security_practices" "framework_implementations")

# Step 2: Launch agents (PARALLEL - single message)
# Task 1: Research existing auth patterns
# Task 2: Research 2025 security best practices
# Task 3: Research Lua authentication libraries
# [All three Task invocations in ONE message]

# Step 3a: Monitor execution
PROGRESS: Starting Research Phase (3 agents, parallel execution)
PROGRESS: [Agent 1/3: existing_patterns] Analyzing codebase...
PROGRESS: [Agent 2/3: security_practices] Searching best practices...
PROGRESS: [Agent 3/3: framework_implementations] Comparing libraries...
REPORT_CREATED: /home/user/.claude/specs/reports/existing_patterns/001_analysis.md
REPORT_CREATED: /home/user/.claude/specs/reports/security_practices/001_practices.md
REPORT_CREATED: /home/user/.claude/specs/reports/framework_implementations/001_libraries.md
PROGRESS: Research Phase complete - 3/3 reports verified (0 retries)

# Step 5: Save checkpoint
CHECKPOINT=".claude/checkpoints/orchestrate_user_authentication_20251013.json"
```

**Proceed to Planning Phase** after research checkpoint saved and all reports verified.

### Planning Phase (Sequential Execution)

The planning phase synthesizes research findings into a structured implementation plan with clear phases, tasks, and testing requirements.

**When to Use Planning Phase**:
- **All workflows** require a plan (simple plans for simple tasks, detailed plans for complex features)
- Follows research phase (if research was performed) OR starts directly from user request
- Single plan-architect agent execution (not parallel)

**Quick Overview**:
1. Prepare planning context (research reports, user request, thinking mode, standards path)
2. Generate plan-architect agent prompt with all context
3. Invoke plan-architect agent (references plan-architect.md protocol)
4. Extract plan path from agent output and validate plan file
5. Save checkpoint with plan path and metadata
6. Display completion status and proceed to implementation

**Pattern Details**: See [Orchestration Patterns - Planning Phase](../templates/orchestration-patterns.md#planning-phase-sequential-execution) for:
- Complete context extraction procedure
- Planning agent prompt template with all placeholders
- Plan validation checklist and bash verification commands
- Checkpoint creation with plan metadata
- State management and TodoWrite updates
- Full workflow example with timing

**Key Execution Requirements**:

1. **Context Preparation** (Step 1):
   ```yaml
   Planning Context:
     research_reports: [array of paths] OR null  # From research phase
     workflow_description: "[original user request]"
     project_name: "[generated in research or from request]"
     thinking_mode: "[from research phase]" OR null
     claude_md_path: "/path/to/CLAUDE.md"

   Context Injection:
     - Provide report PATHS only (not summaries)
     - Agent uses Read tool to access reports selectively
     - Include thinking mode for consistency
     - No orchestration logic passed to agent
   ```

2. **Path Pre-Calculation** (Step 2):
   ```bash
   # Calculate topic-based plan path BEFORE agent invocation
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
   PLAN_PATH=$(create_topic_artifact "$WORKFLOW_TOPIC_DIR" "plans" "implementation" "")
   # Result: specs/{NNN_workflow}/plans/{NNN}_implementation.md
   ```

3. **Agent Invocation** (Step 3):
   - **SINGLE** Task tool invocation (sequential, not parallel)
   - Subagent type: general-purpose
   - Reference: plan-architect.md behavioral guidelines
   - **Behavioral Injection**: Pass pre-calculated PLAN_PATH to agent
   - **Cross-References**: Pass all research report paths for metadata inclusion
   - Agent creates plan using Write tool (NOT SlashCommand)
   - Agent returns PLAN_CREATED with metadata (phases, complexity, hours)
   - Wait for agent completion before proceeding

3. **Plan Validation** (Step 4):
   ```bash
   Required Sections:
     - ## Metadata (Date, Feature, Scope, Standards, Research Reports)
     - ## Overview (Success criteria)
     - ## Implementation Phases (Numbered phases with tasks)
     - ## Testing Strategy

   Validation:
     - Plan file exists at extracted path
     - All required sections present
     - Tasks reference specific files
     - Research reports referenced (if research performed)
     - Max 1 retry if validation fails
   ```

4. **Checkpoint and State** (Step 5):
   - Save checkpoint with: plan_path, plan_number, phase_count, complexity
   - Store ONLY plan path (not content) - agent reads file when needed
   - Update workflow_state.current_phase = "implementation"
   - Mark planning complete in completed_phases array

**Context Reduction**:
- **Research reports**: Pass paths (~50 chars each) instead of full content (~1000+ chars)
- **Plan output**: Store path (~50 chars) instead of full plan (~5000+ chars)
- **Total savings**: ~95-98% context reduction for subsequent phases

**Performance Metrics**:
- **Simple planning**: 1-2 minutes (direct implementation)
- **Medium planning**: 2-4 minutes (with research integration)
- **Complex planning**: 4-6 minutes (synthesis of multiple reports)

**Quick Example**:

```bash
# Step 1: Prepare context
RESEARCH_REPORTS=( \
  "specs/reports/existing_patterns/001_analysis.md" \
  "specs/reports/security_practices/001_practices.md" \
)
WORKFLOW_DESC="Add user authentication with email and password"
THINKING_MODE="think hard"

# Step 2: Pre-calculate plan path
PLAN_PATH=$(create_topic_artifact "$WORKFLOW_TOPIC_DIR" "plans" "implementation" "")
# Result: specs/027_auth/plans/027_implementation.md

# Step 3: Invoke planning agent with behavioral injection
# Task tool invocation with plan-architect.md reference
# Agent receives PLAN_PATH, creates plan using Write tool
# Agent includes research reports in plan metadata

# Step 4: Extract and validate
# Verify plan created at PLAN_PATH with required sections
# Verify plan includes research reports in metadata (cross-references)
# Extract metadata (phases, complexity, hours) for context reduction

# Step 5: Save checkpoint
CHECKPOINT=".claude/checkpoints/orchestrate_user_authentication_20251013.json"
# Store: plan_path, plan_number=013, phase_count=4, complexity=Medium

# Step 6: Display completion
✓ Planning Phase Complete
Plan Created: specs/plans/013_user_authentication.md
Phases: 4, Complexity: Medium, Est. Hours: 12-15
Incorporating Research From: 2 reports
Planning Time: 2m 45s
→ Proceeding to Implementation Phase
```

**Proceed to Implementation Phase** after planning checkpoint saved and plan validated.

### Implementation Phase (Adaptive Execution)

The implementation phase executes the plan using /implement command, runs tests after each phase, and conditionally enters debugging loop if tests fail.

**When to Use Implementation Phase**:
- **All workflows** that have a validated plan file
- Follows planning phase completion
- Single code-writer agent execution with /implement command
- Conditional debugging loop (max 3 iterations) if tests fail

**Quick Overview**:
1. Extract plan path and metadata from planning checkpoint
2. Build code-writer agent prompt with plan context
3. Invoke code-writer agent with /implement command (extended timeout)
4. Parse implementation results (test status, phases completed, files modified)
5. Evaluate test status → Success: proceed to docs OR Failure: enter debugging loop
6. Save checkpoint with implementation status
7. Display implementation status and transition decision

**Conditional Debugging Loop** (if tests fail):
1. Generate debug topic slug (first iteration only)
2. Invoke debug-specialist agent → creates report in debug/{topic}/NNN_report.md
3. Extract report path and recommended fixes
4. Apply fixes using code-writer agent
5. Run tests again → Pass: exit loop OR Fail: continue
6. Iteration control → Iteration < 3: retry OR Iteration ≥ 3: escalate to user

**Pattern Details**: See [Orchestration Patterns - Implementation Phase](../templates/orchestration-patterns.md#implementation-phase-adaptive-execution) for:
- Complete 7-step implementation execution procedure
- Complete 7-step debugging loop procedure
- Code-writer agent prompt template
- Debug-specialist agent prompt template
- Result parsing algorithms (regex patterns for status extraction)
- Checkpoint creation for implementation and debugging states
- Debugging iteration control and escalation logic
- Full workflow examples with debugging scenarios

**Key Execution Requirements**:

1. **Context Extraction** (Step 1):
   ```bash
   # Extract from planning checkpoint
   PLAN_PATH=$(jq -r '.workflow_state.plan_path' < checkpoint.json)
   PLAN_NUMBER=$(basename "$PLAN_PATH" | grep -oP '^\d+')
   PHASE_COUNT=$(grep -c "^### Phase" "$PLAN_PATH")
   COMPLEXITY=$(grep "^- \*\*Complexity\*\*:" "$PLAN_PATH" | cut -d: -f2 | tr -d ' ')
   ```

2. **Agent Invocation** (Step 3):
   ```json
   {
     "subagent_type": "general-purpose",
     "description": "Execute implementation plan NNN using code-writer",
     "timeout": 600000,  // CRITICAL: 10min for multi-phase execution
     "prompt": "Read: .claude/agents/code-writer.md\n\n/implement [plan_path]"
   }
   ```

3. **Result Parsing** (Step 4):
   ```python
   # Extract from agent output using regex
   tests_passing = bool(re.search(r'TESTS_PASSING: true', output))
   phases = re.search(r'PHASES_COMPLETED: (\d+)/(\d+)', output)
   files = re.search(r'FILES_MODIFIED: \[(.*?)\]', output)
   commits = re.search(r'GIT_COMMITS: \[(.*?)\]', output)
   failed_phase = re.search(r'FAILED_PHASE: (\d+)', output)
   error_msg = re.search(r'ERROR_MESSAGE: (.+)', output)
   ```

4. **Decision Logic** (Step 5):
   ```yaml
   Evaluation Tree:
     tests_passing == true:
       → Proceed to Documentation Phase (Success Path)
     tests_passing == false:
       → Enter Debugging Loop (Failure Path)
         Loop Conditions:
           - Max 3 debugging iterations
           - Each iteration: debug report → fix → test
           - Exit on: tests pass OR max iterations reached
           - Escalate to user if max iterations exceeded
   ```

5. **Debugging Loop Requirements** (Conditional):
   - **Debug Topic Slug** (first iter only): Extract from error type (e.g., "test_timeout", "null_pointer")
   - **Debug Agent**: Invokes debug-specialist.md protocol
   - **Report Creation**: debug/{topic}/NNN_report.md (gitignored for issue tracking)
   - **Fix Application**: Code-writer applies recommended fixes
   - **Iteration Tracking**: workflow_state.debug_iteration (0-3)
   - **Escalation**: Present 3 debug reports to user, pause workflow

6. **Checkpoint Creation** (Step 6):
   ```yaml
   Implementation Success Checkpoint:
     status: "implementation_complete"
     tests_passing: true
     phases_completed: "N/N"
     files_modified: [array]
     git_commits: [array]
     next_phase: "documentation"

   Debugging Checkpoint (each iteration):
     status: "debugging_iteration_M"
     debug_iteration: M
     debug_topic: "{topic}"
     debug_reports: [array of M reports]
     tests_passing: false
     next_action: "retry" OR "escalate"
   ```

**Context Reduction**:
- **Plan reference**: Pass path (~50 chars) instead of full plan (~5000+ chars)
- **Implementation output**: Store status markers (~200 chars) instead of full output (~3000+ chars)
- **Debug reports**: Pass paths (~60 chars each) instead of full reports (~1500+ chars each)

**Performance Metrics**:
- **Implementation time**: 3-10 minutes per phase (depends on complexity)
- **Total implementation**: 15-60 minutes (4-8 phases typical)
- **Debug iteration**: 2-5 minutes per iteration
- **Max debugging time**: 15 minutes (3 iterations × 5 min)

**Quick Example - Success Path**:

```bash
# Step 1: Extract context
PLAN_PATH="specs/plans/013_user_authentication.md"
PHASE_COUNT=4
COMPLEXITY="Medium"

# Step 3: Invoke code-writer (timeout 600000ms)
# Agent executes: /implement specs/plans/013_user_authentication.md
# Output after 25 minutes:
PROGRESS: Implementing Phase 1: Database schema...
PROGRESS: Running tests for Phase 1... ✓ All passing
PROGRESS: Creating git commit for Phase 1... ✓ e8f3a21
PROGRESS: Implementing Phase 2: Authentication API...
PROGRESS: Running tests for Phase 2... ✓ All passing
...
PROGRESS: All phases complete - 4/4 phases

# Step 4: Parse results
TESTS_PASSING: true
PHASES_COMPLETED: 4/4
FILES_MODIFIED: [users.lua, auth.lua, session.lua, tests/auth_spec.lua]
GIT_COMMITS: [e8f3a21, a3f9b10, c7e2d43, f1a8c91]
IMPLEMENTATION_STATUS: success

# Step 5: Evaluate → tests_passing == true
→ Proceed to Documentation Phase

# Step 6: Save checkpoint (implementation_complete)
```

**Quick Example - Debugging Path**:

```bash
# Step 1-3: Same as success path
# Step 4: Parse results after Phase 2
TESTS_PASSING: false
PHASES_COMPLETED: 2/4
FAILED_PHASE: 2
ERROR_MESSAGE: auth_spec.lua:42 - Expected 200, got 401

# Step 5: Evaluate → tests_passing == false
→ Enter Debugging Loop

# Debugging Iteration 1:
#   Step 1: Generate topic slug = "auth_status_code"
#   Step 2: Invoke debug-specialist
#   Output: debug/auth_status_code/001_session_cookie.md
#   Step 3: Extract: "Check session cookie initialization"
#   Step 4: Apply fix (code-writer modifies session.lua)
#   Step 5: Run tests → TESTS_PASSING: true
#   Step 6: Iteration control → tests pass, exit loop

# Step 6: Save checkpoint (debugging_resolved, iteration_count=1)
# Step 7: Display success with debugging note
→ Proceed to Documentation Phase (resolved after 1 debug iteration)
```

**Quick Example - Escalation Path**:

```bash
# Debugging Iteration 1: Tests still fail
# Debugging Iteration 2: Tests still fail
# Debugging Iteration 3: Tests still fail

# Step 6: Iteration control → debug_iteration=3 AND tests_passing=false
→ Escalate to user

# Display:
⚠️ Implementation Blocked - Manual Intervention Required

Debugging Attempts: 3 iterations
Debug Reports Created:
  1. debug/coroutine_state/001_async_hang.md
  2. debug/coroutine_state/002_promise_deadlock.md
  3. debug/coroutine_state/003_event_loop.md

Last Error: tests/async_spec.lua:15 - coroutine in wrong state

Checkpoint Saved: .claude/checkpoints/orchestrate_..._escalation.json

Options:
  1. Review debug reports and provide guidance
  2. Adjust plan complexity and retry
  3. Continue to documentation with known test failures (not recommended)

Workflow paused - awaiting user input.
```

**Proceed to Documentation Phase** after implementation succeeds OR user resolves escalation.

### Documentation Phase (Sequential Execution)

This phase completes the workflow by updating project documentation, generating a comprehensive workflow summary with performance metrics, establishing bidirectional cross-references between all artifacts, and optionally creating a pull request.

#### Step 1: Prepare Documentation Context

GATHER workflow artifacts and build documentation context structure for the doc-writer agent.

**EXECUTE NOW: Gather Workflow Artifacts**

EXTRACT the following from workflow_state and prior phase checkpoints:

1. **Research report paths** (from research phase checkpoint, if completed)
2. **Implementation plan path** (from planning phase checkpoint)
3. **Implementation status** (from implementation phase checkpoint)
4. **Debug report paths** (from debugging phase checkpoint, if occurred)
5. **Modified files list** (from implementation agent output)
6. **Test results** (passing or fixed_after_debugging)

BUILD the documentation context structure:

```yaml
documentation_context:
  # From workflow initialization
  workflow_description: "[Original user request]"
  workflow_type: "feature|refactor|debug|investigation"
  project_name: "[generated project name]"

  # From research phase (if completed)
  research_reports: [
    "specs/reports/existing_patterns/001_report.md",
    "specs/reports/security_practices/001_report.md"
  ]
  research_topics: ["existing_patterns", "security_practices"]

  # From planning phase
  plan_path: "specs/plans/NNN_feature_name.md"
  plan_number: NNN
  phase_count: N

  # From implementation phase
  implementation_status:
    tests_passing: true
    phases_completed: "N/N"
    files_modified: [
      "file1.ext",
      "file2.ext"
    ]
    git_commits: [
      "hash1",
      "hash2"
    ]

  # From debugging phase (if occurred)
  debug_reports: [
    "debug/phase1_failures/001_config_init.md"
  ]
  debug_iterations: N
  issues_resolved: [
    "Issue 1 description",
    "Issue 2 description"
  ]

  # Current phase
  current_phase: "documentation"
```

**VERIFICATION CHECKLIST**:
- [ ] workflow_description extracted from state
- [ ] All phase outputs collected (research, planning, implementation, debugging)
- [ ] File paths verified (all referenced files exist)
- [ ] Context structure complete

#### Step 2: Calculate Performance Metrics

CALCULATE workflow timing and performance metrics explicitly.

**EXECUTE NOW: Calculate Performance Metrics**

COMPUTE workflow performance using these explicit algorithms:

1. **Total Workflow Time**:
   ```
   total_time = current_timestamp - workflow_start_timestamp
   total_minutes = total_time / 60
   total_hours = total_minutes / 60
   formatted_duration = sprintf("%02d:%02d:%02d", hours, minutes, seconds)
   ```

2. **Phase Breakdown**:
   For each completed phase, calculate:
   ```
   phase_duration = phase_end_timestamp - phase_start_timestamp
   phase_minutes = phase_duration / 60
   ```

3. **Parallelization Metrics** (if research phase completed):
   ```
   parallel_agents = count(research_reports)
   estimated_sequential_time = parallel_agents × average_research_time
   actual_parallel_time = research_phase_duration
   time_saved = estimated_sequential_time - actual_parallel_time
   time_saved_percentage = (time_saved / estimated_sequential_time) × 100
   ```

4. **Error Recovery Metrics** (if debugging occurred):
   ```
   total_errors = count(debug_reports)
   auto_recovered = total_errors (if tests eventually passed)
   manual_interventions = 0 (if no user escalation)
   recovery_success_rate = (auto_recovered / total_errors) × 100
   ```

BUILD the performance data structure:

```yaml
performance_summary:
  # Time metrics
  total_workflow_time: "[HH:MM:SS format]"
  total_minutes: N

  # Phase breakdown
  phase_times:
    research: "[HH:MM:SS or 'Skipped']"
    planning: "[HH:MM:SS]"
    implementation: "[HH:MM:SS]"
    debugging: "[HH:MM:SS or 'Not needed']"
    documentation: "[current phase]"

  # Parallel execution metrics (if research completed)
  parallelization_metrics:
    parallel_research_agents: N
    estimated_sequential_time: "[minutes]"
    actual_parallel_time: "[minutes]"
    time_saved_estimate: "[N% saved vs sequential]"

  # Error recovery metrics (if debugging occurred)
  error_recovery:
    total_errors: N
    auto_recovered: N
    manual_interventions: N
    recovery_success_rate: "[N%]"
```

**VERIFICATION CHECKLIST**:
- [ ] All timestamps extracted from checkpoints
- [ ] Duration calculations correct (no negative times)
- [ ] Parallelization metrics calculated (if applicable)
- [ ] Error recovery metrics calculated (if debugging occurred)

#### Step 3: Invoke Doc-Writer Agent

INVOKE the doc-writer agent with complete inline prompt including workflow summary template and cross-reference instructions.

**EXECUTE NOW: Invoke Doc-Writer Agent**

USE the Task tool to invoke the doc-writer agent NOW.

Task tool invocation:

```yaml
subagent_type: general-purpose

description: "Update documentation and generate workflow summary using doc-writer protocol"

prompt: |
  Read and follow the behavioral guidelines from:
  /home/benjamin/.config/.claude/agents/doc-writer.md

  You are acting as a Documentation Writer Agent with the tools and constraints
  defined in that file.

  ## Documentation Task: Complete Workflow Documentation

  ### Workflow Context
  - **Original Request**: [workflow_description]
  - **Workflow Type**: [workflow_type]
  - **Project Name**: [project_name]
  - **Completion Date**: [current_date YYYY-MM-DD]

  ### Artifacts Generated

  **Research Reports** (if research phase completed):
  [For each report in research_reports:]
  - [report_path] - [topic]

  **Implementation Plan**:
  - Path: [plan_path]
  - Number: [plan_number]
  - Phases: [phase_count]

  **Implementation Status**:
  - Tests: [passing/fixed_after_debugging]
  - Phases Completed: [N/N]
  - Files Modified: [count] files
  - Git Commits: [count] commits

  **Debug Reports** (if debugging occurred):
  [For each report in debug_reports:]
  - [debug_report_path] - [issue resolved]
  - Iterations: [debug_iterations]

  ### Performance Metrics
  - Total Duration: [total_workflow_time HH:MM:SS]
  - Research Time: [research_phase_time or "Skipped"]
  - Planning Time: [planning_phase_time]
  - Implementation Time: [implementation_phase_time]
  - Debugging Time: [debugging_phase_time or "Not needed"]
  - Parallelization Savings: [time_saved_percentage% or "N/A"]
  - Error Recovery Rate: [recovery_success_rate% or "100% (no errors)"]

  ### Documentation Requirements

  1. **Update Project Documentation**:
     - Review files modified during implementation
     - Update relevant README files
     - Add usage examples where appropriate
     - Ensure documentation follows CLAUDE.md standards

  2. **Create Workflow Summary**:
     Create a comprehensive workflow summary file at:
     `[plan_directory]/specs/summaries/[plan_number]_workflow_summary.md`

     Use this exact template:

     ```markdown
     # Workflow Summary: [Feature/Task Name]

     ## Metadata
     - **Date Completed**: [YYYY-MM-DD]
     - **Specs Directory**: [specs_directory_path]
     - **Summary Number**: [NNN] (matches plan number)
     - **Workflow Type**: [feature|refactor|debug|investigation]
     - **Original Request**: [workflow_description]
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
     [If research phase completed, list each report:]
     - [Report 1: path - brief description]
     - [Report 2: path - brief description]

     [If no research: "(No research phase - direct implementation)"]

     **Implementation Plan**:
     - Path: [plan_path]
     - Phases: [phase_count]
     - Complexity: [Low|Medium|High]
     - Link: [relative link to plan file]

     **Debug Reports**:
     [If debugging occurred, list each report:]
     - [Debug report 1: path - issue addressed]

     [If no debugging: "(No debugging needed - tests passed on first run)"]

     ## Implementation Overview

     ### Key Changes
     **Files Created**:
     [For each new file:]
     - [new_file.ext] - [brief purpose]

     **Files Modified**:
     [For each modified file:]
     - [modified_file.ext] - [changes made]

     **Files Deleted**:
     [For each deleted file:]
     - [deleted_file.ext] - [reason for deletion]

     ### Technical Decisions
     [Key architectural or technical decisions made during workflow]
     - Decision 1: [what and why]
     - Decision 2: [what and why]

     ## Test Results

     **Final Status**: ✓ All tests passing

     [If debugging occurred:]
     **Debugging Summary**:
     - Iterations required: [debug_iterations]
     - Issues resolved:
       1. [Issue 1 and fix]
       2. [Issue 2 and fix]

     ## Performance Metrics

     ### Workflow Efficiency
     - Total workflow time: [HH:MM:SS]
     - Estimated manual time: [HH:MM:SS calculated estimate]
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
     [If research completed:]
     - Research agents used: [N]
     - Parallel vs sequential time: [N% faster]

     [If no research: "No parallel execution in this workflow"]

     ### Error Recovery
     [If debugging occurred:]
     - Total errors encountered: [N]
     - Automatically recovered: [N]
     - Manual interventions: [0 or N]
     - Recovery success rate: [N%]

     [If no errors: "Zero errors - clean implementation"]

     ## Cross-References

     ### Research Phase
     [If applicable:]
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
     - [Success 1 - what went smoothly]
     - [Success 2 - effective strategies]

     ### Challenges Encountered
     - [Challenge 1 and how it was resolved]
     - [Challenge 2 and resolution approach]

     ### Recommendations for Future
     - [Recommendation 1 for similar workflows]
     - [Recommendation 2 for improvements]

     ## Notes

     [Any additional context, caveats, or important information about this workflow]

     ---

     *Workflow orchestrated using /orchestrate command*
     *For questions or issues, refer to the implementation plan and research reports linked above.*
     ```

  3. **Create Cross-References**:

     a. **Update Implementation Plan** ([plan_path]):
        Add at bottom of plan file:
        ```markdown
        ## Implementation Summary
        This plan was executed on [YYYY-MM-DD]. See workflow summary:
        - [Summary path link]

        Status: ✅ COMPLETE
        - Duration: [HH:MM:SS]
        - Tests: All passing
        - Files modified: [N]
        ```

     b. **Update Research Reports** (if any):
        For each report in research_reports, add:
        ```markdown
        ## Implementation Reference
        Findings from this report were incorporated into:
        - [Plan path] - Implementation plan
        - [Summary path] - Workflow execution summary
        - Date: [YYYY-MM-DD]
        ```

     c. **Update Debug Reports** (if any):
        For each report in debug_reports, add:
        ```markdown
        ## Resolution Summary
        This issue was resolved during:
        - Workflow: [workflow_description]
        - Iteration: [N]
        - Summary: [Summary path link]
        ```

  ### Output Requirements

  Return results in this format:

  ```
  PROGRESS: Updating project documentation...
  PROGRESS: Updating [file1.ext]...
  PROGRESS: Updating [file2.ext]...
  PROGRESS: Creating workflow summary...
  PROGRESS: Adding cross-references...

  DOCUMENTATION_RESULTS:
  - updated_files: [list of documentation files modified]
  - readme_updates: [list of README files updated]
  - workflow_summary_created: [summary file path]
  - cross_references_added: [count]
  - documentation_complete: true
  ```

  ### Quality Checklist
  - [ ] Purpose clearly stated in updated docs
  - [ ] Usage examples included where appropriate
  - [ ] Cross-references added bidirectionally
  - [ ] Unicode box-drawing used (not ASCII art)
  - [ ] No emojis in content
  - [ ] Code examples have syntax highlighting
  - [ ] Navigation links updated
  - [ ] CommonMark compliant
  - [ ] Workflow summary follows template exactly
  - [ ] All cross-references validated (files exist)
```

**Monitoring During Agent Execution**:
- Watch for `PROGRESS: <message>` markers in agent output
- Display progress updates to user in real-time
- Verify summary file creation
- Validate cross-reference updates

**VERIFICATION CHECKLIST**:
- [ ] Task tool invoked with doc-writer protocol
- [ ] Complete prompt provided inline (not referenced)
- [ ] Workflow summary template inlined in prompt
- [ ] Cross-reference instructions explicit
- [ ] Agent execution monitored (progress markers)

#### Step 4: Extract Documentation Results

PARSE the doc-writer agent output to extract and validate documentation results.

**EXECUTE NOW: Extract and Validate Documentation Results**

1. **Locate Results Block**:
   Search agent output for "DOCUMENTATION_RESULTS:" marker

2. **Extract Results Data**:
   ```yaml
   documentation_results:
     updated_files: [
       "file1.ext",
       "file2.ext"
     ]
     readme_updates: [
       "dir1/README.md",
       "dir2/README.md"
     ]
     workflow_summary_created: "specs/summaries/NNN_workflow_summary.md"
     cross_references_added: N
     documentation_complete: true
   ```

3. **Validate Results**:
   - At least one documentation file updated (updated_files not empty)
   - Workflow summary file created and exists
   - Cross-references count > 0 (at least plan → summary link)
   - documentation_complete is true

4. **Store in Workflow State**:
   ```yaml
   workflow_state.documentation_paths: [
     "specs/summaries/NNN_workflow_summary.md",
     ...updated_files,
     ...readme_updates
   ]
   ```

**Validation Checklist**:
- [ ] At least one documentation file updated
- [ ] Workflow summary file exists at expected path
- [ ] Summary file follows template structure (verify key sections present)
- [ ] Cross-references include all workflow artifacts
- [ ] Plan file updated with "Implementation Summary" section
- [ ] Research reports updated with "Implementation Reference" (if applicable)
- [ ] Debug reports updated with "Resolution Summary" (if applicable)
- [ ] No broken links (all referenced paths valid)
- [ ] Documentation follows project standards (CLAUDE.md compliance)

**Error Handling**:
```yaml
if documentation_complete == false:
  ERROR: "Documentation phase incomplete"
  → Check agent output for error messages
  → Verify doc-writer has Write and Edit tool access
  → Retry with clarified instructions if recoverable
  → Escalate to user if persistent failure

if workflow_summary_created == null:
  ERROR: "Workflow summary not created"
  → Check specs/summaries/ directory exists
  → Verify plan_number extracted correctly
  → Retry summary creation explicitly

if cross_references_added == 0:
  WARNING: "No cross-references created"
  → Cross-reference step may have failed
  → Manually update files if needed
  → Note in workflow completion message
```

**VERIFICATION CHECKLIST**:
- [ ] Results extracted from agent output
- [ ] All expected fields present
- [ ] Validation checklist completed
- [ ] Error handling triggered if issues detected

#### Step 5: Verify Cross-References

VALIDATE that bidirectional cross-references were created correctly by the doc-writer agent.

**EXECUTE NOW: Verify Bidirectional Cross-References**

1. **Read Implementation Plan** ([plan_path]):
   ```
   USE Read tool to open plan file
   SEARCH for "## Implementation Summary" section
   VERIFY section exists and includes:
   - Summary path link
   - Completion date
   - Status (COMPLETE)
   ```

2. **Read Workflow Summary** ([summary_path]):
   ```
   USE Read tool to open summary file
   SEARCH for "## Cross-References" section
   VERIFY section includes:
   - Research reports (if applicable)
   - Implementation plan
   - Related documentation
   ```

3. **Read Research Reports** (if any):
   ```
   FOR each report in research_reports:
     USE Read tool to open report file
     SEARCH for "## Implementation Reference" section
     VERIFY section exists and includes:
     - Plan path link
     - Summary path link
     - Completion date
   ```

4. **Read Debug Reports** (if any):
   ```
   FOR each report in debug_reports:
     USE Read tool to open debug report file
     SEARCH for "## Resolution Summary" section
     VERIFY section includes:
     - Workflow description
     - Summary path link
   ```

**Cross-Reference Validation Matrix**:

| From | To | Link Type | Verified |
|------|-----|-----------|----------|
| Plan | Summary | Implementation Summary section | [ ] |
| Summary | Plan | Cross-References section | [ ] |
| Summary | Reports | Cross-References section | [ ] |
| Reports | Plan | Implementation Reference section | [ ] |
| Reports | Summary | Implementation Reference section | [ ] |
| Debug | Summary | Resolution Summary section | [ ] |

**If Validation Fails**:
```yaml
if any_validation_fails:
  WARNING: "Cross-reference validation failed"
  → Report which links are missing
  → Attempt manual cross-reference creation
  → Use Edit tool to add missing sections
  → Re-validate after manual fixes
```

**VERIFICATION CHECKLIST**:
- [ ] All plan → summary links verified
- [ ] All summary → plan links verified
- [ ] All summary → report links verified (if applicable)
- [ ] All report → plan/summary links verified (if applicable)
- [ ] All debug → summary links verified (if applicable)
- [ ] Cross-reference matrix complete

#### Step 6: Save Final Checkpoint

CREATE final checkpoint with complete workflow metrics.

**EXECUTE NOW: Save Final Workflow Checkpoint**

USE checkpoint utility:
```bash
.claude/lib/save-checkpoint.sh orchestrate "$PROJECT_NAME" "$CHECKPOINT_DATA"
```

Where CHECKPOINT_DATA is:
```yaml
checkpoint_workflow_complete:
  # Phase identification
  phase_name: "documentation"
  completion_time: [current_timestamp]

  # Documentation outputs
  outputs:
    documentation_updated: [list of updated files]
    workflow_summary_created: "[summary_path]"
    cross_references_added: N
    status: "success"

  # Workflow completion
  next_phase: "complete"
  workflow_status: "success"

  # Complete workflow metrics
  final_metrics:
    # Time metrics
    total_workflow_time: "[HH:MM:SS]"
    total_minutes: N

    # Phase completion
    phases_completed: [
      "research",    # or "skipped"
      "planning",
      "implementation",
      "debugging",   # or "not_needed"
      "documentation"
    ]

    # Artifact counts
    artifacts_generated:
      research_reports: N
      implementation_plan: 1
      workflow_summary: 1
      debug_reports: N
      documentation_updates: N

    # File changes
    files_modified: N
    files_created: N
    files_deleted: N
    git_commits: N

    # Performance
    parallelization_savings: "[N% or 'N/A']"
    error_recovery_success: "[N% or '100% (no errors)']"

  # Complete workflow summary
  workflow_summary:
    research_reports: [list of paths]
    implementation_plan: "[plan_path]"
    workflow_summary: "[summary_path]"
    debug_reports: [list of paths]
    tests_passing: true
    documentation_complete: true
```

**Checkpoint File Location**:
```
.claude/data/checkpoints/orchestrate_${PROJECT_NAME}_${TIMESTAMP}.json
```

**VERIFICATION CHECKLIST**:
- [ ] Checkpoint saved successfully
- [ ] All workflow metrics included
- [ ] Artifact paths recorded
- [ ] Status set to "complete"

#### Step 7: Conditional PR Creation

EVALUATE whether to create a pull request and invoke github-specialist agent if required.

**EXECUTE NOW: Check for PR Creation Flag**

1. **Check for --create-pr Flag**:
   ```
   if "--create-pr" in original_command_arguments:
     pr_creation_required = true
   else:
     pr_creation_required = false
   ```

2. **Prerequisites Check** (if pr_creation_required):
   ```bash
   # Check if gh CLI is available and authenticated
   if ! command -v gh &>/dev/null; then
     echo "Note: gh CLI not installed. Skipping PR creation."
     echo "Install: brew install gh (or equivalent)"
     pr_creation_required = false
   fi

   if ! gh auth status &>/dev/null; then
     echo "Note: gh CLI not authenticated. Skipping PR creation."
     echo "Run: gh auth login"
     pr_creation_required = false
   fi
   ```

3. **Invoke github-specialist Agent** (if pr_creation_required):

   **EXECUTE NOW: Invoke GitHub Specialist Agent**

   USE the Task tool to invoke github-specialist agent NOW.

   Task tool invocation:
   ```yaml
   subagent_type: general-purpose

   description: "Create PR for completed workflow using github-specialist protocol"

   prompt: |
     Read and follow the behavioral guidelines from:
     /home/benjamin/.config/.claude/agents/github-specialist.md

     You are acting as a GitHub Specialist Agent with the tools and constraints
     defined in that file.

     ## PR Creation Task: Workflow Completion Pull Request

     ### Workflow Context
     - **Plan**: [absolute path to implementation plan]
     - **Branch**: [current branch name from git]
     - **Base**: main (or master, detect from repo)
     - **Summary**: [absolute path to workflow summary]
     - **Original Request**: [workflow_description]

     ### PR Description Content

     Create a comprehensive PR description following this structure:

     ```markdown
     # [Feature/Task Name]

     ## Summary
     [Brief 1-2 sentence summary of what was implemented]

     ## Workflow Overview
     This PR was created through a complete /orchestrate workflow:

     **Research Phase**: [N reports generated or "Skipped"]
     [If research completed:]
     - [Report 1 title and key finding]
     - [Report 2 title and key finding]

     **Planning Phase**: [Phase count]-phase implementation plan
     - Complexity: [Low|Medium|High]
     - See: [plan path]

     **Implementation Phase**: All [N] phases completed successfully
     - Tests: [All passing or Fixed after M debug iterations]
     - Files modified: [N]
     - Commits: [N]

     **Debugging Phase**: [N iterations or "Not needed"]
     [If debugging occurred:]
     - Issues resolved: [M]
     - See debug reports: [debug report paths]

     **Documentation Phase**: [N] files updated
     - Documentation: [list updated files]
     - Workflow summary: [summary path]

     ## Performance Metrics
     - **Total Duration**: [HH:MM:SS]
     - **Parallelization Savings**: [N% or "N/A"]
     - **Error Recovery**: [success rate or "100% (no errors)"]

     ## File Changes
     [Use git diff --stat to show change summary]

     **Files Created**: [N]
     **Files Modified**: [N]
     **Files Deleted**: [N]

     ## Cross-References

     **Implementation Plan**: [plan path]
     **Workflow Summary**: [summary path]
     [If research:]
     **Research Reports**:
     - [report 1 path]
     - [report 2 path]
     [If debugging:]
     **Debug Reports**:
     - [debug report 1 path]

     ## Test Results
     ✓ All tests passing

     [If debugging occurred:]
     Fixed issues:
     1. [Issue 1 description]
     2. [Issue 2 description]

     ## Checklist
     - [x] All implementation phases completed
     - [x] Tests passing
     - [x] Documentation updated
     - [x] Code follows project standards
     - [ ] Ready for review
     ```

     ### Output Required

     Return PR details in this format:
     ```
     PR_CREATED:
     - url: [PR URL]
     - number: [PR number]
     - branch: [feature branch]
     - base: [base branch]
     ```
   ```

4. **Capture PR URL** (if created):
   ```
   PARSE github-specialist output for PR_CREATED block
   EXTRACT pr_url and pr_number

   STORE in workflow_state:
   workflow_state.pr_url = pr_url
   workflow_state.pr_number = pr_number
   ```

5. **Update Workflow Summary with PR Link** (if created):
   ```
   USE Edit tool to update workflow summary file
   ADD section at bottom:

   ## Pull Request
   - **PR**: [pr_url]
   - **Number**: #[pr_number]
   - **Created**: [YYYY-MM-DD]
   - **Status**: Open
   ```

6. **Graceful Degradation** (if PR creation fails):
   ```yaml
   if pr_creation_fails:
     LOG error message from github-specialist

     DISPLAY manual PR creation command:
     ```
     To create PR manually:

     gh pr create \
       --title "feat: [feature name]" \
       --body-file [pr_description_file] \
       --base main
     ```

     CONTINUE workflow (don't block on PR failure)
   ```

**VERIFICATION CHECKLIST**:
- [ ] --create-pr flag checked
- [ ] Prerequisites validated (gh CLI, auth)
- [ ] github-specialist agent invoked (if required)
- [ ] PR URL captured and stored
- [ ] Workflow summary updated with PR link
- [ ] Error handled gracefully (if PR creation fails)

**State Management**:

UPDATE workflow_state after documentation phase completes:

```yaml
workflow_state.current_phase = "complete"
workflow_state.execution_tracking.phase_start_times["documentation"] = [doc start timestamp]
workflow_state.execution_tracking.phase_end_times["documentation"] = [current timestamp]
workflow_state.execution_tracking.agents_invoked += 1  # doc-writer agent
workflow_state.execution_tracking.agents_invoked += 1  # github-specialist (if PR created)
workflow_state.execution_tracking.files_created += 1  # workflow summary
workflow_state.completed_phases.append("documentation")
workflow_state.context_preservation.documentation_paths = [summary_path, updated_doc_paths...]

# Calculate total duration
workflow_state.performance_metrics.total_duration_seconds =
  workflow_state.execution_tracking.phase_end_times["documentation"] -
  workflow_state.execution_tracking.phase_start_times["analysis"]
```

UPDATE TodoWrite to mark all tasks complete:

```json
{
  "todos": [
    {
      "content": "Analyze workflow and identify research topics",
      "status": "completed",
      "activeForm": "Analyzing workflow and identifying research topics"
    },
    {
      "content": "Execute parallel research phase",
      "status": "completed",
      "activeForm": "Executing parallel research phase"
    },
    {
      "content": "Create implementation plan",
      "status": "completed",
      "activeForm": "Creating implementation plan"
    },
    {
      "content": "Implement features with testing",
      "status": "completed",
      "activeForm": "Implementing features with testing"
    },
    {
      "content": "Debug and fix test failures (if needed)",
      "status": "completed",
      "activeForm": "Debugging and fixing test failures"
    },
    {
      "content": "Generate documentation and workflow summary",
      "status": "completed",
      "activeForm": "Generating documentation and workflow summary"
    }
  ]
}
```

#### Step 8: Workflow Completion Message

OUTPUT final workflow summary to user with comprehensive details.

**EXECUTE NOW: Display Workflow Completion Message**

USE this exact format:

```markdown
┌─────────────────────────────────────────────────────────────┐
│                     WORKFLOW COMPLETE                       │
└─────────────────────────────────────────────────────────────┘

**Duration**: [HH:MM:SS]

**Phases Executed**:
[If research completed:]
✓ Research (parallel) - [duration]
  - Topics: [N]
  - Reports: [report paths]

✓ Planning (sequential) - [duration]
  - Plan: [plan_path]
  - Phases: [N]

✓ Implementation (adaptive) - [duration]
  - Phases completed: [N/N]
  - Files modified: [N]
  - Git commits: [N]

[If debugging occurred:]
✓ Debugging ([N] iterations) - [duration]
  - Issues resolved: [M]
  - Debug reports: [debug report paths]

✓ Documentation (sequential) - [duration]
  - Documentation updates: [N] files
  - Workflow summary: [summary_path]
  - Cross-references: [N] links

**Implementation Results**:
- Files created: [N]
- Files modified: [N]
- Files deleted: [N]
- Tests: ✓ All passing

**Performance Metrics**:
[If parallelization used:]
- Time saved via parallelization: [N%]
[If error recovery occurred:]
- Error recovery: [N/M errors auto-recovered]
[Else:]
- Error-free execution: 100%

**Artifacts Generated**:
[If research:]
- Research reports: [N] reports in [M] topics
[Always:]
- Implementation plan: [plan_path]
- Workflow summary: [summary_path]
[If debugging:]
- Debug reports: [N] reports

[If PR created:]
**Pull Request**:
- PR #[pr_number]: [pr_url]
- Status: Open for review

**Next Steps**:
[If PR created:]
1. Review PR at [pr_url]
2. Request reviews from team members
3. Merge when approved

[Else:]
1. Review workflow summary: [summary_path]
2. Review implementation plan: [plan_path]
3. Consider creating PR with: gh pr create

**Summary**: [summary_path]
Review the workflow summary for complete details, cross-references, and lessons learned.

┌─────────────────────────────────────────────────────────────┐
│  All workflow artifacts saved and cross-referenced.         │
│  Thank you for using /orchestrate!                          │
└─────────────────────────────────────────────────────────────┘
```

**Completion Data to Display**:

Extract from workflow_state and performance_summary:
- Total duration (formatted HH:MM:SS)
- All phase durations (or "Skipped"/"Not needed")
- Artifact counts and paths
- File modification counts
- Test status
- Performance metrics (parallelization, error recovery)
- PR information (if created)

**VERIFICATION CHECKLIST**:
- [ ] Completion message displayed to user
- [ ] All key metrics included
- [ ] Artifact paths provided
- [ ] Next steps suggested
- [ ] Message formatted clearly (Unicode box-drawing)

#### Step 9: Cleanup Final Checkpoint

REMOVE checkpoint file after successful workflow completion.

**EXECUTE NOW: Cleanup Completed Workflow Checkpoint**

```bash
# Delete checkpoint file (workflow complete, no resume needed)
rm -f .claude/data/checkpoints/orchestrate_${PROJECT_NAME}_*.json

# Log completion
echo "[$(date)] Workflow ${PROJECT_NAME} completed successfully" >> .claude/logs/orchestrate.log
```

**Checkpoint Cleanup Logic**:
```yaml
if workflow_status == "success":
  → Delete checkpoint file (no longer needed)
  → Log completion to orchestrate.log

elif workflow_status == "escalated":
  → Keep checkpoint file (user may resume)
  → Move to .claude/data/checkpoints/failed/ for investigation

elif workflow_status == "error":
  → Keep checkpoint file (debugging needed)
  → Archive to .claude/data/checkpoints/failed/
```

**VERIFICATION CHECKLIST**:
- [ ] Checkpoint file removed (if success)
- [ ] Completion logged
- [ ] Failed checkpoints archived (if applicable)

#### Workflow Summary Template (Reference)

The complete workflow summary template is inlined in Step 3 (doc-writer agent prompt) above. This reference section is provided for documentation purposes only.

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
